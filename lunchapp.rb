require 'yelp' # https://github.com/Yelp/yelp-ruby
require 'sinatra'

enable :logging

configure do 
	@@client = Yelp::Client.new({
	  consumer_key: "Nmnh3QptiqSUmuynvZw2Wg",
	  consumer_secret: "gt742ogHxdElRljicnlPYn8pCVU",
	  token: "ikDWHAGhx76OQHBkO7f5JE5uk5IO7HJR",
	  token_secret: "2p50aw86_UCB19xyC1LPxwQekj4"
	})
end

get '/' do
	logger.info "**** Looking for lunch... ****"
	#For the future this list may be replaced by the list of restaurant types located here: https://www.yelp.com/developers/documentation/v2/all_category_list
	@food = [
			#Ethnic food types
			"Indian", "Greek", "Thai", "Chinese", "Japanese", "American", "Armenian", "Peruvian", 
			"Chilean", "Bolivian", "Ethiopian", "German", "Irish", "Brazilian", "Argentine", "Spanish", 
			"Mexican", "French", "Italian", "Korean", "Southern", "Morroccan", "Vietnamese",
			"Middle Eastern", "Lebenese", "Pakistani",
			#Specific types of foods
			"Seafood", "Pizza", "Steak", "Burgers", "BBQ", "Sushi", "Sandwhich"]
	#Where are we searching?  Try using lat/long first, otherwise check if they specified a location.
	#Default to Chicago if nothing was entered.
	useCoord = false
	if !params[:lat].nil? && !params[:long].nil? then 
		logger.info "Using Coordinates"
		coords = { 
			latitude: params[:lat], 
			longitude: params[:long] 
		}
		useCoord = true
	elsif !params[:where].nil? then 
		logger.info "Using specific location"
		@where = params[:where] 
	else 
		logger.info "Using Default value"
		@where = "Chicago" 
	end

	#What are we searching for? We can search for a specific kind of food, a whitelist of acceptable foods, or a blacklist of unnacceptable foods.
	#Default to Italian Beef as a specific search.
	@what = ""

	if params[:specificInput] == "true"
		logger.info "Searching for a specific item"
		@what = params[:specific]
	elsif params[:whiteListInput] == "true"
		if params[:arr].length > 0
			logger.info "Searching via whitelist"
			#Search using only the items that were checked
			params[:arr].shuffle!

			if params[:arr].length > 5
				whitelist = params[:arr][0, 5]
			else
				whitelist = params[:arr]
			end

			for i in 0..whitelist.length
				if !whitelist[i].nil? 
					@what += whitelist[i].to_s + ',' 
				end
			end
			@what.chomp!(',')
		else 
			@what = "Italian Beef"
		end
	elsif params[:blackListInput] == "true"
		if params[:arr].length > 0
			logger.info "Searching via blacklist"
			#Search for everything BUT what was checked.
			#Subtract the array so we don't search for what the use doesn't want.
			paintItBlack = @food - params[:arr]
			paintItBlack.shuffle!
			if paintItBlack.length > 5
				paintItBlack = paintItBlack[0, 5]
			end

			for i in 0..paintItBlack.length
				if !paintItBlack[i].nil? 
					@what += paintItBlack[i].to_s + ',' 
				end
			end
			@what.chomp!(',')
		else
			@what = "Italian Beef"
		end
	else
		@what = "Italian Beef"
	end

	#How will we sort? #0=Best matched (default), 1=Distance, 2=Highest Rated
	@randSort = 1
	#@randSort = rand(3)  #Choose this to be EXTRA random!

	logger.info "Building query parameters"
	logger.info "Searching for " + @what 
	parms = {
		category_filter: 'restaurants', 
		term: @what, #add additional filters in order separated by ','
		limit: 10,
		sort: @randSort
	} 

	#Make the call to Yelp
	if useCoord
		logger.info "Searching by coordinates"
		parms[:radius] = 1610 #1 mile, 1609.34 meters
		@retval = @@client.search_by_coordinates(coords, parms)
	else
		logger.info "Searching by specific location"
		@retval = @@client.search(@where, parms)
	end
	@retval.businesses.shuffle!
	
	#In case theres a flop and no results come back, just do the default thing.  Italian beef it is!
	if @retval.businesses.length < 1
		redirect to('/')
	end
	## Just for Debugging	
		#@retval.businesses.each do |biz| 
		#	puts biz.name
		#	puts biz.location.address
		#	puts "--------------------------------------------"
		#end 
	logger.info "**** Lunch has been found ****"
	erb :whatsForLunch
end