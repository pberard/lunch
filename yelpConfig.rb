require 'yelp' # https://github.com/Yelp/yelp-rubyyelpConfig

#Get your api access set up here: https://www.yelp.com/developers/manage_api_keys
@client = Yelp::Client.new({
	  consumer_key: "CONSUMER KEY GOES HERE",
	  consumer_secret: "CONSUMER SECRET GOES HERE",
	  token: "TOKEN GOES HERE",
	  token_secret: "TOKEN SECRET GOES HERE"
	})

def getClient()
	return @client
end