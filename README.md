# Slack Workflow Daily Leetcode Question Bot

img_1
![alt text](https://github.com/2018-lonely-droid/financialReplatformAWS/blob/main/images/img_1.jpeg?raw=true)

## The Problem

leetcode.com is a website that provides programming questions to help developers hone their skills and think critically to solve coding questions. One of the most valuable tools leetcode provides is a daily programming challenge question for the website. Unfortunately, leetcode prompts users to sign-in to see the daily question. But what if you want to know what the question is and its difficulty without ever having to sign in or navigate leetcode?

## The Solution

Leetcode has one public page that lists all the problems on the website. Fortunately, the first problem to appear in the table is always the leetcode question of the day. 

img_2

Using the selenium webscraping library in python (because the elements are in javascript blocks) we can scrape the url, name, and difficulty of the question of the day and send it to slack so that we never have to leave our work messages to see what the daily problem is. 

## Let's Build It!

### Configure the aws CLI profile

-- cd ~/.aws
-- nano credentials

[terraform_test]
aws_access_key_id = XXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

-- control X, and yes to safe buffer, hit enter

- add profile name to provider.tf, change aws region as needed

### Create Slack Integration Workflow

img_3

img_4

img_5

img_6

img_7

img_8

img_9

- create slack integration workflow that is triggered by webhook. On creation a webhook will be provided

- add webhook url to `getDailyLeetcodeUrlLambda.py` and zip it up

### Deploy Terraform Code

`cd terraform`

`run terraform init`

`run terraform apply -auto-approve`


