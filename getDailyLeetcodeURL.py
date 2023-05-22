import json
import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options


# Chrome options & driver
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument('--incognito')
chrome_driver = webdriver.Chrome(options=chrome_options)

# Open the amazon photos login page
chrome_driver.get('https://leetcode.com/problemset/all/')

# Wait 20 secs or until div with id initial-loading disappears
element = WebDriverWait(chrome_driver, 20).until(EC.invisibility_of_element_located((By.ID, "initial-loading")))

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

    # Send webhook to slack
    webhookUrl = 'https://hooks.slack.com/workflows/XXXXXXXXXXX/XXXXXXXXXXX/XXXXXXXXXXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXX'     
    slackData = {
        "questionName": questionName,
        "questionUrl": questionUrl,
        "questionDifficulty": questionDifficulty
    }

    try:
        response = requests.post(webhookUrl, data=json.dumps(slackData), headers={'Content-Type': 'application/json'})
        response.raise_for_status()
    except requests.exceptions.HTTPError as errh:
        print ('Http Error:', errh)
    except requests.exceptions.ConnectionError as errc:
        print ('Error Connecting:', errc)
    except requests.exceptions.Timeout as errt:
        print ('Timeout Error:', errt)
    except requests.exceptions.RequestException as err:
        print ('OOps: Something Else', err)

    break

