# Slack Workflow Daily Leetcode Question Bot


## Summary

[leetcode.com](https://leetcode.com/) is a website that provides programming questions to help developers hone their skills and think critically to solve coding questions. One of the most valuable tools leetcode.com provides is a daily programming challenge question for the website. Unfortunately, leetcode prompts users to sign-in to see the daily question.

I wanted to post the daily leetcode.com question into a Slack channel with my coworkers, but got tired of the tedious routine of logging into my leetcode.com account, finding the Leetcode question of the day, and pasting the URL into the Slack channel. I wonder if we could automate this through Python Web Scraping via Selenium and a Slack Workflow!

![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_1.jpg?raw=true)


## The Problem

To automate the process of finding the Leetcode question of the day and posting it to Slack we need to: 
1. Successfully load in a headless version of Chromium and the ChromeDriver to Lambda at runtime.

2. Get the Leetcode question of the day without logging in to leetcode.com.

3. Send the Leetcode question of the day URL to a Slack channel.

[Selenium](https://www.selenium.dev/documentation/) is a popular Python library that provides extensions to emulate user interaction with browsers. In other words, web-scraping. At the core of Selenium is WebDriver, an interface to write instruction sets that can be run interchangeably in many browsers. WebDriver is an open source tool. [ChromeDriver](https://chromedriver.chromium.org/) is a standalone server that implements the W3C WebDriver standard and is built into Chromium. Chromium is the open source base of the popular [Chrome](https://www.google.com/chrome/) browser many use today. 

In Lambda, the Python runtime uses Amazon Linux 2, which is a stripped version of the operating system with the minimal amount of libraries. Hence, __the runtime lacks some of the libraries and tools required to run a headless version of Chromium and the ChromeDriver.__ This means it can be a complicated mess trying to get Selenium to run in a Python Lambda Script.

## The Solution

1. Using the preconfigured Selenium Lambda Layer created by [@diegoparrilla](https://github.com/diegoparrilla/headless-chrome-aws-lambda-layer), we can properly reference a headless version of Chromium and ChromeDriver to successfully Web Scrape the Leetcode website.

2. Leetcode has [one public page that lists all the problems on the website](https://leetcode.com/problemset/all/). Fortunately, the first problem to appear in the table is always the leetcode question of the day. 

![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_2.jpg?raw=true)

Using Selenium (because the elements are in javascript blocks) we can scrape the url, name, and difficulty of the question of the day and send it to Slack so that we never have to leave our work messages to see what the daily problem is.

3. We can use [Slack Workflow Builder](https://slack.com/features/workflow-automation) to post a Slack message in a channel via webhook that will include the URL of the Leetcode question of the day.

__*The web scraping capability is not limited to leetcode. — Since we use a chromium headless browser, any website could be scraped for information and be sent to any webhook.*__


## Prerequisites

### Access to an AWS Account

An AWS account is needed to deploy this stack. The AWS account used will also need permission to create IAM Users, and an access key for the IAM User.

### Install AWS CLI

To use deploy AWS resources via Terraform, you will need to install the AWS CLI. Installation instructions vary per operating system, so check out the latest documentation [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to install for your specific operating system.

### Install Terraform

To use Terraform you will need to install it. HashiCorp distributes Terraform as a binary package. You can also install Terraform using popular package managers or executables as stated in the official documentation. Please refer to the [official documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) for install instructions specific to your operating system. Since I am using macOS, I will install via the [Homebrew Package Manager](https://brew.sh/).

Open up a new terminal and add the HashiCorp repository using the following command:

`brew tap hashicorp/tap`

Now, install Terraform with:

`brew install hashicorp/tap/terraform`

To verify that the installation worked properly, try listing Terraform's available subcommands:

`terraform -help`

## Architecture

### Target Technology Stack

- [AWS Lambda](https://aws.amazon.com/lambda/)
- [Amazon Eventbridge](https://aws.amazon.com/eventbridge/)
- [AWS Idnetity and Access Management (IAM)](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)

### Target Architecture

- pic

An EventBridge scheduled event named `dailyLeetcodeUrlPush` triggers a Lambda called `dailyLeetcodeUrlPush` . The Lambda uses zipped [Lambda layers](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html) housed in the `lambda-layers` S3 bucket at runtime. The `bs4.zip` Lambda layer is comprised of the [Beautiful Soup](https://beautiful-soup-4.readthedocs.io/en/latest/) Python library and its required dependencies. The `layer-headless_chrome-v0_2-beta.zip` Lambda layer is comprised of the Selenium Python library and its required dependencies, as well as a headless version of Chromium and the [ChromeDriver](https://chromedriver.chromium.org/).

This code repository includes the zipped Lambda layers `bs4.zip` and `layer-headless_chrome-v0_2-beta.zip`. It also includes the main Python file `getDaiyLeetcodeUrlLambda.py` that is ran in Lambda as `dailyLeetcodeUrlPush`. In the terraform folder, `main.tf` is ran to deploy the above resources into the target AWS Account.

## Tools

### AWS Service
- [Amazon EventBridge](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html) is a serverless event bus service that helps you connect your applications with real-time data from a variety of sources. For example, Lambda functions, HTTP invocation endpoints using API destinations, or event buses in other AWS accounts. *Amazon EventBridge is used to run the Lambda script on a schedule.*
- [AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) is a compute service that helps you run code without needing to provision or manage servers. It runs your code only when needed and scales automatically, so you pay only for the compute time that you use. *AWS Lambda is used to Web Scrape leetcode.com and then post info to Slack Workflow webhook URL.*
- [AWS Identity and Access Management (IAM)](https://aws.amazon.com/iam/) specifies who or what can access services and resources in AWS, centrally manages fine-grained permissions, and analyzes access to refine permissions across AWS. An AWS IAM User account and access key are used to deploy the AWS services above via Terraform.

### Terraform by HashiCorp
- [Terraform](https://www.terraform.io/) is an infrastructure as code tool that lets you build, change, and version cloud and on-prem resources safely and efficiently. It is comparable to [AWS Cloud Development Kit](https://aws.amazon.com/cdk/). *Terraform is used to easily deploy all the required AWS services for this integration.*
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) can source credentials and other settings from the shared configuration and credentials files. *The Terraform AWS Provider is needed to interact with any AWS service.*


## Configure the AWS CLI profile

### Create a New IAM User

Assuming you want to create a new AWS cli profile to use this integration, you would want to first create a new IAM User in the AWS console and retrieve the AWS access key and secret access key. A reason you may want to create and use a new `IAM User` account is to allocate ONLY the necessary permissions needed to this account to deploy the Slack Workflow Daily Leetcode Question Bot.

Here is an example `IAM policy` that you can attach to your new account.


```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TerraformExecutionRole",
            "Action": [
                "sts:GetCallerIdentity",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:GetRole",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:CreateRole",
                "iam:CreatePolicy",
                "iam:AttachRolePolicy",
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
                "scheduler:GetSchedule",
                "scheduler:CreateSchedule"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Sid": "LambdaGetDailyLeetcodeUrlPassExecutionRole",
            "Effect": "Allow",
            "Action": [
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:PassRole"
            ],
            "Resource": "arn:aws:iam::*:role/getDailyLeetcodeUrl_lambda_execution_role"
        },
        {
            "Sid": "EventBridgeGetDailyLeetcodeUrlPassExecutionRole",
            "Effect": "Allow",
            "Action": [
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:PassRole"
            ],
            "Resource": "arn:aws:iam::*:role/event_bridge_getDailyLeetcodeUrl_role"
        }
    ]
}
```

_Please note that this permission set only allows the creation of the resources needed to **deploy** the Slack Workflow Daily Leetcode Question Bot NOT **destroy** the resources. So you will have to add more permissions to your `IAM User` account policy, or manually destroy the resources in the IAM console with another account that has privileges to do so._


### Configure the AWS CLI profile

The AWS cli has to be configured on your local machine to be able to authenticate the Terraform commands that will build this solution. The [official documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) can walk you though how to set this up in greater detail. If you do not have the AWS cli installed [here is a good starting point](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

There are also many ways to use AWS cli credentails with Terraform, and I will be using aws cli profiles below, but be aware you can change this to better fit your needs.

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

Add the new AWS profile to the terraform/provider.tf file

### Install Terraform

To use Terraform you will need to install it. HashiCorp distributes Terraform as a binary package. You can also install Terraform using popular package managers as stated in the [official documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli). Since I am using macOS, I will install via the [Homebrew Package Manager](https://brew.sh/).

### Open up a new terminal and add the HashiCorp repository using the following command:

Now you will need to add this new AWS credentials profile name to the terraform/provider.tf file. Also take this time to edit your AWS region if you want to deploy in any region other than `us-east-1`.

Here is what your provider.tf file should look like. Make sure to save the file as Terraform will not remember any updates if the files are not deliberately saved.

```
provider "aws" {
  region  = "YOUR-REGION"
  profile = "YOUR-PROFILE-NAME"
}
```

### Verify the AWS cli configuration

Open up a terminal in the project folder.

Make sure to navigate to the Terraform folder. On Mac you can do this with cd terraform.

Once in the Terraform folder, initialize terraform with the terraform init command. 

*[Terraform init](https://developer.hashicorp.com/terraform/cli/commands/init) is an essential command that initializes a Terraform working directory. It configures [the backend](https://developer.hashicorp.com/terraform/language/settings/backends/configuration) and downloads the required providers and modules. This command creates a .terraform directory in the working directory, which contains [the state](https://developer.hashicorp.com/terraform/language/state), [plugins](https://developer.hashicorp.com/terraform/cli/plugins), and [modules](https://developer.hashicorp.com/terraform/language/modules).*

If it is successful, then you know that Terraform was able to find your AWS profile configured and load all the AWS modules properly. Here is an example of a successful Terraform init response:

![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_11.jpg?raw=true)


## Create Slack Integration Workflow

Now it is time to setup the destination Slack channel/location with it's corresponding webhook. 

Navigate to a channel and go to the Integrations tab and click `Add a Workflow`.
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_3.jpg?raw=true)

Click the `Webhook ADVANCED` option.                                               
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_4.jpg?raw=true)

Click the `Add Variable` button and click `Next`
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_5.jpg?raw=true)

The variables we want to add are variables that will be passed from our lambda as a payload to the Slack webhook. The three variables are called `questionName`, `questionUrl`, and `questionDifficulty`. Make sure to set them as Data type `text` and click `Done` and `Save`.
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_6.jpg?raw=true)

The next page is where we can customize the message body that will be displayed when the new leetcode question is sent. You can customize the message as you like, but for simplicity I have given them defitions Name, Link, and Difficulty. When finished editing, click `Save`.
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

Run `terraform apply -auto-approve` terraform command to deploy the resources needed to start sending a daily leetcode problem to Slack!

If all the infrastructure deploys successfully, you will see the `Apply complete!` message followed by the count of resources deployed in the terminal.
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_12.jpg?raw=true)

## How Do I Know It Is Working?

The lambda will run according to the chrone pattern specified earlier. If it was left default, you would have to wait until 8 AM on week days to see if the lambda will work properly and push to Slack. To test this manually now, login to the AWS console GUI, and navigate to the `Dailyleetcodeurlpush`  page.

Press the `Test` button to manually trigger `Dailyleetcodeurlpush`
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_13.jpg?raw=true)

Click `Create new event` and add any value to `Event name`  - It is a mandatory field
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_14.jpg?raw=true)

Then click `Save` and click `Test` again to start the test. The window below will start to show the execution logs. You will see the lambda running in real time. In less than two minutes you should get a ping in the Slack channel you created with the Leetcode question of the day!
![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_1.jpg?raw=true)

## Troubleshooting

### `Error: configuring Terraform AWS Provider: validating provider credentials` when trying to run `terrafrom apply`

Make sure the `aws_access_key_id` and the `aws_secret_access_key` provided in the `~/.aws/credentials` local file are correct.

### The lambda runs for the max duration and end with a timeout error

The lambda used requires a minimum of 500mb ram available in order for the chromium headless browser to function. If you use less than 500mb ram, the lambda will timeout and will not produce an error code. This has already been configured in Terraform to 500mb ram, but if you choose to use this lambda to scrape another website, it may require more ram to properly run.

### `Error: deleting Amazon EventBridge Scheduler Schedule (default/getDailyLeetcodeUrl): operation error Scheduler: DeleteSchedule, https response error StatusCode: 403` or `Error: removing policy arn:aws:iam::XXXXXXXXXXXX:policy/event_bridge_getDailyLeetcodeUrl_policy from IAM Role event_bridge_getDailyLeetcodeUrl_role: AccessDenied` are example errors that will occur if you try to delete the deployed terraform via the `terraform destroy -auto-approve` command.

The IAM role permission set only allows the creation of the resources needed to deploy the Slack Workflow Daily Leetcode Question Bot NOT destroy the resources. To successfully delete all the resources, temporarily add IAM Role permissions that allow actions such as `delete` or `remove`. An easy way to do this is edit your `IAM User` by clicking the `Add permissions` button on the `Permissions policies` box. Click `Add permissions`, then `Attach policy directly`. Attach the policy `AdministratorAccess`, then click `Next` then `Add permissions`. You will now be able to delete all the infrastructure created by terraform. *Remember to remove the `IAM User` completly afterwards, or at the very least remove the `AdministratorAccess` policy.*

## Related resources

- [Slack - Guide to Workflow Builder](https://slack.com/help/articles/360035692513-Guide-to-Workflow-Builder)
    - [Create more advanced workflows using webhooks](https://slack.com/help/articles/360041352714-Create-more-advanced-workflows-using-webhooks)

- [Python - Selenium Documentation](https://www.selenium.dev/documentation/)
    - [Selenium Browser Option Flags](https://www.selenium.dev/documentation/webdriver/drivers/options/)
    - [ChromeDriver](https://chromedriver.chromium.org/downloads)
    - [ChromeDriver Version Selection Guide](https://sites.google.com/a/chromium.org/chromedriver/downloads/version-selection)

- [Python - Headless Chrome Lambda Layer](https://github.com/diegoparrilla/headless-chrome-aws-lambda-layer)
    - [Getting Started with Headless Chrome](https://developer.chrome.com/blog/headless-chrome/)

- [Amazon EventBridge - Scheduled Events](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html)