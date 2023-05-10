import json
import time
import urllib3
import logging
from headless_chrome import create_driver
from bs4 import BeautifulSoup


logger = logging.getLogger()
logger.setLevel(logging.INFO)


# Chrome options & driver
driver_params = [
    '--headless',
    '--incognito',
    '--single-process',
    '--ignore-certificate-errors'
]
chrome_driver = create_driver(driver_params)


def scrapePage():
    # Open leetcode problems page
    chrome_driver.get('https://leetcode.com/problemset/all/')
    logger.info('Opened leetcode problem page')

    # Wait 10 secs (in the future nice to check this w/ driver like commented below)
    time.sleep(10)
    # element = WebDriverWait(chrome_driver, 20).until(EC.invisibility_of_element_located((By.ID, "initial-loading")))
    logger.info('Page finished loading')

    # Parse through HTML
    soup = BeautifulSoup(chrome_driver.page_source, 'html.parser')
    questionBlock = soup.find('div', role='rowgroup')
    questionList = questionBlock.find_all('div', role='row')

    # Iterate through rows of problems -- the top row is the daily problem (all we need)
    for question in questionList:
        row = question.find_all('div', role='cell')
        questionName = row[1].find('a').text
        questionUrl = 'https://leetcode.com' + row[1].find('a')['href']
        questionDifficulty = row[4].find('span').text
        break
    
    logger.info('HTML parsed')

    return questionName, questionUrl, questionDifficulty


def lambda_handler(event, context):
    questionName, questionUrl, questionDifficulty = scrapePage()

    # Webhook Info
    webhookUrl = 'https://hooks.slack.com/workflows/XXXXXXXXXXX/XXXXXXXXXXX/XXXXXXXXXXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXX'    
    slackData = {
        "questionName": questionName,
        "questionUrl": questionUrl,
        "questionDifficulty": questionDifficulty
    }

    # Send Webhook
    try:
        http = urllib3.PoolManager()
        response = http.request("POST", webhookUrl, body=json.dumps(slackData), headers={"Content-Type": "application/json"})
    except urllib3.exceptions.HTTPError as errh:
        print ('Http Error:', errh.reason)
    except urllib3.exceptions.ConnectionError as errc:
        print ('Error Connecting:', errc.reason)
    except urllib3.exceptions.ConnectTimeoutError as errt:
        print ('Timeout Error:', errt.reason)
    except urllib3.exceptions.RequestError as err:
        print ('Oops: Something Else', err.reason)
        
    logger.info('Successfully sent webhook')


