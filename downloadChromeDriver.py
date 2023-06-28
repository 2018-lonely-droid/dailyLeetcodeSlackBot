import urllib.request

# Chrome headless - https://github.com/diegoparrilla/headless-chrome-aws-lambda-layer
urllib.request.urlretrieve("https://github.com/diegoparrilla/headless-chrome-aws-lambda-layer/releases/download/v0.2-beta.0/layer-headless_chrome-v0.2-beta.0.zip", "layer-headless_chrome-v0_2-beta.zip")