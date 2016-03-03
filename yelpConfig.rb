require 'yelp' # https://github.com/Yelp/yelp-rubyyelpConfig

#Get your api access set up here: https://www.yelp.com/developers/manage_api_keys
@client = Yelp::Client.new({
    consumer_key: "Nmnh3QptiqSUmuynvZw2Wg",
    consumer_secret: "gt742ogHxdElRljicnlPYn8pCVU",
    token: "8K6LsEQ0LZIbqgr9NO8t5ODCYZoLLo79",
    token_secret: "VQ2hHuVKRK88sRA26rfDXvHKmig"
})
def getClient()
	return @client
end