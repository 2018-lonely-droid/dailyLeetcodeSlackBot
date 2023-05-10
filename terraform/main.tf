############################
# Lambda Layers
############################

# Create random lambda-layer bucket name
resource "random_string" "random_id" {
  length  = 10
  special = false
  upper   = false
}

# Create bucket for lambda layers
resource "aws_s3_bucket" "lambda-layers" {
  bucket = "lambda-layers-${random_string.random_id.result}"

  tags = {
    Name = "lambda-layers"
  }
}

# Upload lambda layers to s3 bucket as zips
resource "aws_s3_object" "s3_lambda-layers_bs4" {
  bucket = aws_s3_bucket.lambda-layers.id
  key    = "bs4.zip"
  source = "../bs4.zip"
}

resource "aws_s3_object" "s3_lambda-layers_selenium" {
  bucket = aws_s3_bucket.lambda-layers.id
  key    = "layer-headless_chrome-v0.2-beta.0.zip"
  source = "../layer-headless_chrome-v0_2-beta.zip"
}

# Add lambda layers that have been uploaded to s3
resource "aws_lambda_layer_version" "lambda_layer_bs4" {
  s3_bucket           = aws_s3_bucket.lambda-layers.id
  s3_key              = aws_s3_object.s3_lambda-layers_bs4.id
  layer_name          = "bs4"
  description         = "https://beautiful-soup-4.readthedocs.io/en/latest/"
  compatible_runtimes = ["python3.8"]
}

# This layer is larger than 50mb, hence it is required to be uploaded to S3
resource "aws_lambda_layer_version" "lambda_layer_selenium" {
  s3_bucket           = aws_s3_bucket.lambda-layers.id
  s3_key              = aws_s3_object.s3_lambda-layers_selenium.id
  layer_name          = "selenium-chrome-driver"
  description         = "https://github.com/diegoparrilla/headless-chrome-aws-lambda-layer"
  compatible_runtimes = ["python3.8"]
}

############################
# Lambda
############################

data "aws_iam_policy_document" "lambda_assume_role_policy_doc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_getDailyLeetcodeUrl_execution_role" {
  name               = "getDailyLeetcodeUrl_lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_doc.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../getDailyLeetcodeUrlLambda.zip"
  output_path = "getDailyLeetcodeUrlLambda.zip"
}

resource "aws_lambda_function" "getDailyLeetcodeUrl" {
  filename         = "../getDailyLeetcodeUrlLambda.zip"
  function_name    = "dailyLeetcodeUrlPush"
  role             = aws_iam_role.lambda_getDailyLeetcodeUrl_execution_role.arn
  handler          = "getDailyLeetcodeUrlLambda.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.8"
  timeout          = 120
  memory_size      = 500
  layers = [
    aws_lambda_layer_version.lambda_layer_bs4.arn,
    aws_lambda_layer_version.lambda_layer_selenium.arn
  ]
  depends_on = [
    aws_iam_role_policy_attachment.getDailyLeetcodeUrl_logs,
    aws_cloudwatch_log_group.getDailyLeetcodeUrl_log_group,
  ]
}

############################
# EventBridge Scheduler
############################

# Get the account id from the profile being used to deploy the terraform
data "aws_caller_identity" "current" {}

# Get current region from the profile being used to deploy terraform
data "aws_region" "current" {}

data "aws_iam_policy_document" "scheduler_assume_role_policy_doc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:scheduler:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:schedule/default/getDailyLeetcodeUrl"]
    }
  }
}

resource "aws_iam_role" "event_bridge_getDailyLeetcodeUrl_role" {
  name = "event_bridge_getDailyLeetcodeUrl_role"

  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role_policy_doc.json
}

data "aws_iam_policy_document" "event_bridge_getDailyLeetcodeUrl_policy_doc" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      "${aws_lambda_function.getDailyLeetcodeUrl.arn}:*",
      "${aws_lambda_function.getDailyLeetcodeUrl.arn}"
    ]
  }
}

resource "aws_iam_policy" "event_bridge_getDailyLeetcodeUrl_policy" {
  name        = "event_bridge_getDailyLeetcodeUrl_policy"
  description = "Policy allowing event bridge schedule to invoke lambda"
  policy      = data.aws_iam_policy_document.event_bridge_getDailyLeetcodeUrl_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.event_bridge_getDailyLeetcodeUrl_role.name
  policy_arn = aws_iam_policy.event_bridge_getDailyLeetcodeUrl_policy.arn
}

resource "aws_scheduler_schedule" "weekdaysAt8AM" {
  name                         = "getDailyLeetcodeUrl"
  group_name                   = "default"
  schedule_expression_timezone = "America/New_York"
  description                  = "A scheduler that triggers the getDailyLeetcodeUrl lambda function"

  flexible_time_window {
    mode = "OFF"
  }

  # Post the new leetcode question to slack week days at 8 am
  # schedule_expression = "cron(0/1 * * * ? *)"
  schedule_expression = "cron(0 8 ? * MON-FRI *)"

  target {
    arn      = aws_lambda_function.getDailyLeetcodeUrl.arn
    role_arn = aws_iam_role.event_bridge_getDailyLeetcodeUrl_role.arn
  }
}

############################
# Lambda Logging
############################
resource "aws_cloudwatch_log_group" "getDailyLeetcodeUrl_log_group" {
  name              = "/aws/lambda/dailyLeetcodeUrlPush"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
data "aws_iam_policy_document" "getDailyLeetcodeUrl_logging_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.getDailyLeetcodeUrl_log_group.name}:*"]
  }
}

resource "aws_iam_policy" "getDailyLeetcodeUrl_logging_policy" {
  name        = "getDailyLeetcodeUrl_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.getDailyLeetcodeUrl_logging_policy_document.json
}

resource "aws_iam_role_policy_attachment" "getDailyLeetcodeUrl_logs" {
  role       = aws_iam_role.lambda_getDailyLeetcodeUrl_execution_role.name
  policy_arn = aws_iam_policy.getDailyLeetcodeUrl_logging_policy.arn
}