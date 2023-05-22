# Slack Workflow Daily Leetcode Question Bot

![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_1.jpg?raw=true)

## The Problem

[leetcode.com](https://leetcode.com/) is a website that provides programming questions to help developers hone their skills and think critically to solve coding questions. One of the most valuable tools leetcode provides is a daily programming challenge question for the website. Unfortunately, leetcode prompts users to sign-in to see the daily question. But what if you want to know what the question is and its difficulty without ever having to sign in or navigate leetcode?

## The Solution

Leetcode has [one public page that lists all the problems on the website](https://leetcode.com/problemset/all/). Fortunately, the first problem to appear in the table is always the leetcode question of the day. 

![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_2.jpg?raw=true)

Using the selenium webscraping library in python (because the elements are in javascript blocks) we can scrape the url, name, and difficulty of the question of the day and send it to slack so that we never have to leave our work messages to see what the daily problem is. 

*The web scraping capability is not limited to leetcode. — Since we use a chromium headless browser, any website could be scraped for information and be sent to any webhook.*


## Prerequisites

### Create a New IAM User

Assuming you want to create a new AWS cli profile to use this integration, you would want to first create a new IAM User in the AWS console and retrieve the AWS access key and secret access key. A reason you may want to create and use a new IAM User account is to allocate ONLY the necessary permissions needed to this account to deploy the Slack Workflow Daily Leetcode Question Bot.

Here is an example `IAM policy` that you can attach to your new account.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sts:GetCallerIdentity",
                "iam:GetPolicy",
                "iam:GetRole",
                "iam:GetPolicyVersion",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:CreateRole",
                "iam:CreatePolicy",
                "iam:AttachRolePolicy",
                "iam:PassRole",
                "logs:DescribeLogGroups",
                "logs:ListTagsLogGroup",
                "logs:CreateLogGroup",
                "logs:PutRetentionPolicy",
                "s3:ListBucket",
                "s3:GetBucketTagging",
                "s3:GetBucketPolicy",
                "s3:GetBucketAcl",
                "s3:GetBucketCors",
                "s3:GetBucketWebsite",
                "s3:GetBucketVersioning",
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketObjectLockConfiguration",
                "s3:GetBucketRequestPayment",
                "s3:GetBucketLogging",
                "s3:GetLifecycleConfiguration",
                "s3:GetReplicationConfiguration",
                "s3:GetEncryptionConfiguration",
                "s3:GetObject",
                "s3:GetObjectTagging",
                "s3:CreateBucket",
                "s3:PutObject",
                "s3:PutBucketTagging",
                "lambda:ListVersionsByFunction",
                "lambda:GetLayerVersion",
                "lambda:GetFunction",
                "lambda:GetFunctionCodeSigningConfig",
                "lambda:CreateFunction",
                "lambda:PublishLayerVersion",
                "lambda:UpdateFunctionCode",
                "scheduler:GetSchedule",
                "scheduler:CreateSchedule"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```

_Please note that this permission set only allows the creation of the resources needed to **deploy** the Slack Workflow Daily Leetcode Question Bot NOT **destroy** the resources. So you will have to add more permissions to your `IAM User` account policy, or manually destroy the resources in the IAM console with another account that has privileges to do so._


### Configure the AWS CLI profile

The AWS cli has to be configured on your local machine to be able to authenticate the terraform commands that will build this solution. The [official documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) can walk you though how to set this up in greater detail. If you do not have the AWS cli installed [here is a good starting point](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). 

There are also many ways to use AWS cli credentails with terraform, and I will be using AWS cli profiles below, but be aware you can change this to better fit your needs.

If you created a new `IAM User` above or choose to use an existing account, [create an access key and secret access key](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html). These need to be added to your local AWS credentials file.

Then you will want to open up terminal on your local machine and navigate to the AWS credentials file. Here is how you can do this on Mac:
`cd ~/.aws`

`nano credentials`

Note here that I am using the [nano editor](https://www.nano-editor.org/docs.php) to edit the AWS credentials file, but you can use your editor of choice (VIM, etc.)

With the file open, add a new AWS profile with the name you would like to use to identify the `IAM User`. Mine in this example is `terraform_test`. If you want to use the default AWS profile, make sure to leave it as `[default]`.

```
[terraform_test]
aws_access_key_id = XXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Use `Control` + `X` to exit nano, and hit `Enter` or yes to "save buffer" (Save the edits made to the AWS credentials file)


### Install Terraform

To use Terraform you will need to install it. HashiCorp distributes Terraform as a binary package. You can also install Terraform using popular package managers as stated in the [official documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli). Since I am using macOS, I will install via the [Homebrew Package Manager](https://brew.sh/).

Open up a new terminal and add the HashiCorp repository using the following command:

`brew tap hashicorp/tap`

Now, install Terraform with:

`brew install hashicorp/tap/terraform`

To verify that the installation worked properly, try listing Terraform's available subcommands:

`terraform -help`


#### Limitations 

The lambda used requires a minimum of 500mb ram available in order for the [chromium](https://www.chromium.org/Home/) headless browser to function. If you use less than 500mb ram, the lambda will timeout and will not produce an error code. This has already been configured in Terraform to 500mb ram, but if you choose to use this lambda to scrape another website, it may require more ram to properly run.


## Architecture

### Target Technology Stack

- AWS Lambda
- Amazon EventBridge
- AWS Identity and Access Management (IAM)


### Target Architecture
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_10.jpg?raw=true)

Terraform is used to deploy the lambda and the required python libraries to an S3 bucket. Then an EventBridge Scheduler task is created that will run the lambda every day at 8am and send it to a Slack Workflow. The lambda is written in python and loads a chromium headless browser to scrape the leetcode website then posts the obtained data to the Slack Workflow webhook.


## Let's Built It!

### Configure CLI profile in Terraform

Now you will need to add this new AWS credentials profile name to the terraform/provider.tf file. Also take this time to edit your AWS region if you want to deploy in any region other than `us-east-1`.

Here is what your provider.tf file should look like. Make sure to save the file as terraform will not remmeber any updates if the files are not deliberately saved.
```
provider "aws" {
  region  = "YOUR-REGION"
  profile = "YOUR-PROFILE-NAME"
}
```

To make sure your configuration is valid, open up a terminal in the project folder. 

Make sure to navigate to the terraform folder. On Mac you can do this with `cd terraform`.

Once in the terraform folder, initialize terraform with the `terraform init` command. 

*[Terraform init](https://developer.hashicorp.com/terraform/cli/commands/init) is an essential command that initializes a Terraform working directory. It configures [the backend](https://developer.hashicorp.com/terraform/language/settings/backends/configuration) and downloads the required providers and modules. This command creates a .terraform directory in the working directory, which contains [the state](https://developer.hashicorp.com/terraform/language/state), [plugins](https://developer.hashicorp.com/terraform/cli/plugins), and [modules](https://developer.hashicorp.com/terraform/language/modules).*

If it is successful, then you know that Terraform was able to find your AWS profile configured and load all the AWS modules properly. Here is an example of a successful Terraform init response
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_11.jpg?raw=true)


### Create Slack Integration Workflow

Now it is time to setup the destination Slack channel/location with it's corresponding webhook. 

Navigate to a channel and go to the Integrations tab and click `Add a Workflow`.
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_3.jpg?raw=true)

Click the `Webhook ADVANCED` option.                                               
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_4.jpg?raw=true)

Click the `Add Variable` button and click `Next`
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_5.jpg?raw=true)

The variables we want to add are variables that will be passed from our lambda as a payload to the Slack webhook. The three variables are called `questionName`, `questionUrl`, and `questionDifficulty`. Make sure to set them as Data type `text` and click `Done` and `Save`.
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_6.jpg?raw=true)

The next page is where we can customize the message body that will be doisplayed when the new leetcode question is sent. You can customize the message as you like, but for simplicity I have given them defitions Name, Link, and Difficulty. When finished editing, click `Save`.
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_7.jpg?raw=true)

You now are given the webhook URL for your specific workflow. This will need to be added to the `getDailyLeetcodeUrlLambda.py` python file. Here we can also see the example HTTP body that Slack is anticipating will come from the lambda function. Once you have copied the webhook URL to a safe place, click `Close`.
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_8.jpg?raw=true)

Congrats! You have now setup the Slack portion of the workflow! Yay!
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_9.jpg?raw=true)

Now open the `getDailyLeetcodeUrlLambda.py` file that I mentioned earlier. Navigate to the `lambda_handler` function and replace the `webhookUrl` string with your webhook URL just created. Your code should look like the example below:

```
def lambda_handler(event, context):
    questionName, questionUrl, questionDifficulty = scrapePage()

    # Webhook Info
    webhookUrl = 'https://hooks.slack.com/workflows/XXXXXXXXXXX/XXXXXXXXXXX/XXXXXXXXXXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXX'    
    slackData = {
        "questionName": questionName,
        "questionUrl": questionUrl,
        "questionDifficulty": questionDifficulty
    }
```

Make sure to save the `getDailyLeetcodeUrlLambda.py` file after making the URL edit. 

*If you want to change the schedule of the daily leetcode message sent to slack, you can do that within the `terraform/main.tf` file, specifically in the resource block `"aws_scheduler_schedule"` named `"weekdaysAt8AM"`. You can modify the time zone by changing the location string of the `schedule_expression_timezone` variable. You can change the frequency by modifying the cron string `schedule_expression`. The current cron string is to run the lambda every week day at 8 AM.*

PRO TIP: Inside the AWS Console, under the `EventBridge` section you can create a dummy `schedule` to get access to a helpful UI for creating a correct and functioning cron string like `0 8 ? * MON-FRI *`. Here is more [documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#CronExpressions) on what a Cron expression is.

If you made any edits to the resource block `"aws_scheduler_schedule"`  called `"weekdaysAt8AM"`, make sure to save the `terraform/main.tf` file to store changes.


### Deploy Terraform Code

Now all that is left is to deploy the resources to your AWS account! Open terminal again and navigate to the root of the `terraform` folder. (Where you ran `terraform init`).

You can run `terraform plan` to see all the resources that will be deployed for this Slackbot to be set up. You can also peruse the `terraform/main.tf` file where all the resources are declared.

Running `terraform apply -auto-approve` terraform command will deploy the resources needed to start sending a daily leetcode problem to Slack!


## How Do I Know It Is Working?

If all the infrastructure deploys successfully after running the `terraform apply -auto-approve` command, you will see this message in your terminal:
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_12.jpg?raw=true)

The lambda will run according to the chrone pattern specified earlier. If it was left default, you would have to wait until 8 AM on week days to see if the lambda will work properly and push to Slack. To test this manually now, login to the AWS console GUI, and navigate to the `Dailyleetcodeurlpush` page. Press the `Test` button to manually trigger `Dailyleetcodeurlpush`.
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_13.jpg?raw=true)

Click `Create new event` and add any value to `Event name`  - It is a mandatory field
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_14.jpg?raw=true)

Then click `Save` and click `Test` again to start the test. The window below will start to show the execution logs. You will see the lambda running in real time. In less than two minutes you should get a ping in the Slack channel you created with the Leetcode question of the day!
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_1.jpg?raw=true)