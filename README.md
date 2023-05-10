# Slack Workflow Daily Leetcode Question Bot

![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_1.jpg?raw=true)

## The Problem

[leetcode.com](https://leetcode.com/) is a website that provides programming questions to help developers hone their skills and think critically to solve coding questions. One of the most valuable tools leetcode provides is a daily programming challenge question for the website. Unfortunately, leetcode prompts users to sign-in to see the daily question. But what if you want to know what the question is and its difficulty without ever having to sign in or navigate leetcode?

## The Solution

Leetcode has [one public page that lists all the problems on the website](https://leetcode.com/problemset/all/). Fortunately, the first problem to appear in the table is always the leetcode question of the day. 

![alt text](https://github.com/2018-lonely-droid/dailyLeetcodeSlackBot/blob/main/images/img_2.jpg?raw=true)

Using the selenium webscraping library in python (because the elements are in javascript blocks) we can scrape the url, name, and difficulty of the question of the day and send it to slack so that we never have to leave our work messages to see what the daily problem is. 

## Let's Build It!

### Configure the aws CLI profile

The aws cli has to be configured on your local machine to be able to authenticate the terraform commands that will build this solution. The [official documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) can walk you though how to set this up in greater detail. There are also many ways to use aws cli credentails with terraform, and I will be using aws cli profiles below, but be aware you can change this to better fit your needs.

Assuming you want to create a new aws cli profile to use this integration, you would want to first create a new `IAM User` in the aws console and retrieve the aws access key and secret access key.

Then you will want to open up terminal on your local machine and navigate to the aws credentials file. Here is how you can do this on Mac:
`cd ~/.aws`
`nano credentials`

Note here that I am using the [nano editor](https://www.nano-editor.org/docs.php) to edit the aws credentials file, but you can use your editor of choice (VIM, etc.)

With the file open, add a new aws profile with the name you would like to use to identify the `IAM User`. Mine in this example is `terraform_test`. If you want to use the default aws profile, make sure to leave it as `[default]`.

```
[terraform_test]
aws_access_key_id = XXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Use `Control` + `X` to exit nano, and hit `Enter` or yes to "save buffer" (Save the edits made to the aws credentials file)

Now you will need to add this new aws credentials profile name to the terraform/provider.tf file. Also take this time to edit your aws region if you want to deploy in any region other than `us-east-1`.

Here is what your provider.tf file should look like. Make sure to save the file as terraform will not remmeber any updates if the files are not deliberately saved.
```
provider "aws" {
  region  = "YOUR-REGION"
  profile = "YOUR-PROFILE-NAME"
}
```

To make sure your configuration is valid, open up a terminal in the project folder. 

Make sure to navigate to the terraform folder. On Mac you can do this with `cd terraform`.

Once in the terraform folder, initialize terraform with the `run terraform init` command. If it is successful, then you know that terraform was able to find your aws profile configured and load all the aws modules properly.

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

NOTE: If you want to change the schedule of the daily leetcode message sent to slack, you can do that within the `terraform/main.tf` file, specifically in the resource block `"aws_scheduler_schedule"` named `"weekdaysAt8AM"`. You can modify the time zone by changing the location string of the `schedule_expression_timezone` variable. You can change the frequency by modifying the cron string `schedule_expression`. 

PRO TIP: Inside the AWS Console, under the `EventBridge` section you can create a dummy `schdeule` to get access to a helpful UI for creating a correct and functioning cron string like `0 8 ? * MON-FRI *`.

If you made any edits to the `terraform/main.tf` file, make sure to save them.

Lastly, zip up the python file and rename is to `getDailyLeetcodeUrlLambda.zip`! The file needs to be zipped as that is what AWS and Terraform as expecting the zip file to be named for deployment. Keep the zip file in the same root directory as `getDailyLeetcodeUrlLambda.py`.

### Deploy Terraform Code

Now all that is left is to deploy the resources to your aws account! Open terminal again and navigate to the root of the `terraform` folder. (Where you ran `terraform init`).

You can run `terraform plan` to see all the resources that will be deployed for this Slackbot to be set up. You can also peruse the `terraform/main.tf` file where all the resources are declared.

Running `terraform apply -auto-approve` terraform command will deploy the resources needed to start sending a daily leetcode problem to Slack!


