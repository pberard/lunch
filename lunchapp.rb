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

helpers do
	def isNilOrEmpty?(x)
		if (x.nil? || x.empty?)
			return true
		end
		return false
	end

	def checkCoords?(lat, long)
		logger.info "Lat/long: " + lat.to_s + ", " + long.to_s
		if (isNilOrEmpty?(lat) || isNilOrEmpty?(long))
			#return false
			logger.info "Something was empty, debugging"
			if lat.nil?
				logger.info "Lat was nil"
				return false
			end
			if lat.to_s.empty?
				logger.info "lat was empty"
				return false
			end
			if long.nil?
				logger.info "Lon was nil"
				return false
			end
			if long.to_s.empty?
				logger.info "long was empty"
				return false
			end
		end
		return true
	end

end

get '/' do
	logger.info "**** Looking for lunch... ****"
	logger.info params
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
	
	if (checkCoords?(params[:lat], params[:long]))
		logger.info "Using Coordinates"
		coords = { 
			latitude: params[:lat], 
			longitude: params[:long] 
		}
		useCoord = true
	elsif (!isNilOrEmpty?(params[:where])) 
		logger.info "Using specific location"
		@where = params[:where] 
	else 
		logger.info "Using Default location"
		@where = "Chicago" 
	end

	#What are we searching for? We can search for a specific kind of food, a whitelist of acceptable foods, or a blacklist of unnacceptable foods.
	#Default to Italian Beef as a specific search.
	@what = ""

	if params[:specificInput] == "true"
		logger.info "Searching for a specific item"
		@what = params[:specific]
	elsif params[:whiteListInput] == "true"
		if !params[:arr].nil? && params[:arr].length > 0
			logger.info "Searching via whitelist"
			#Search using only the items that were checked
			params[:arr].shuffle!

			#Trim it down to five
			if params[:arr].length > 5
				whitelist = params[:arr][0, 5]
			else
				whitelist = params[:arr]
			end

			#for i in 0..whitelist.length
			#	if !whitelist[i].nil? 
			#		@what += whitelist[i].to_s + ',' 
			#	end
			#end
			#remove the last comma
			#@what.chomp!(',')
			@what = whitelist.join(",")
		else 
			logger.info "Whitelist length was 0, searching for Italian beef"
			@what = "Italian Beef"
		end
	elsif params[:blackListInput] == "true"
		if !params[:arr].nil? && params[:arr].length > 0
			logger.info "Searching via blacklist"
			#Search for everything BUT what was checked.
			#Subtract the array so we don't search for what the use doesn't want.
			paintItBlack = @food - params[:arr]
			paintItBlack.shuffle!
			if paintItBlack.length > 5
				paintItBlack = paintItBlack[0, 5]
			end

			#for i in 0..paintItBlack.length
			#	if !paintItBlack[i].nil? 
			#		@what += paintItBlack[i].to_s + ',' 
			#	end
			#end
			#@what.chomp!(',')
			@what = paintItBlack.join(",")
		else
			logger.info "Blacklist length was 0, searching for Italian beef"
			@what = "Italian Beef"
		end
	else
		logger.info "Using default food"
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
	logger.info parms
	#Make the call to Yelp
	if useCoord
		logger.info "Searching by coordinates"
		logger.info coords 
		parms[:radius] = 1610 #1 mile, 1609.34 meters
	
		@retval = @@client.search_by_coordinates(coords, parms)
	else
		logger.info "Searching by specific location: " + @where
		
		@retval = @@client.search(@where, parms)
	end
	@retval.businesses.shuffle!
	
	#In case theres a flop and no results come back, just do the default thing.  Italian beef it is!
	if @retval.businesses.length < 1
		logger.info "Didn't find anything, rerouting to default"
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