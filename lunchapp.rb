require './yelpConfig.rb'
require 'sinatra'

enable :logging

configure do 
	@@client = getClient()
	#For the future this list may be replaced by the list of restaurant types located here: https://www.yelp.com/developers/documentation/v2/all_category_list
	@@food = [
			#Ethnic food types
			"Indian", "Greek", "Thai", "Chinese", "Japanese", "American", "Armenian", "Peruvian", 
			"Chilean", "Bolivian", "Ethiopian", "German", "Irish", "Brazilian", "Argentine", "Spanish", 
			"Mexican", "French", "Italian", "Korean", "Southern", "Morroccan", "Vietnamese",
			"Middle Eastern", "Lebenese", "Pakistani",
			#Specific types of foods
			"Seafood", "Pizza", "Steak", "Burgers", "BBQ", "Sushi", "Sandwhich"]
	@@search_radius = 1610 #1 mile, 1609.34 meters
end

helpers do
	def isNilOrEmpty?(x)
		if (x.nil? || x.empty?)
			return true
		end
		return false
	end

	#Trim down an array to no more than 5 elements, then join the items of the list with a comma
	def makeArraySearchable(arr)
		#Trim it down to at most five (this helps narrow down the search)
		if arr.length > 5
			searchList = arr[0, 5]
		else
			searchList = arr
		end

		return searchList.join(",")
	end

	def checkCoords?(lat, long)
		if (isNilOrEmpty?(lat) || isNilOrEmpty?(long))
			#logger.info "Something was empty, debugging"
			if lat.nil?
				#logger.info "Lat was nil"
				return false
			end
			if lat.to_s.empty?
				#logger.info "lat was empty"
				return false
			end
			if long.nil?
				#logger.info "Lon was nil"
				return false
			end
			if long.to_s.empty?
				#logger.info "long was empty"
				return false
			end
		end
		return true
	end

	def findMeFood(yelp_parms, useCoord, coords, where)
		
		if useCoord
			#logger.info "Searching by coordinates"
			yelp_parms[:radius] = @@search_radius
		
			return @@client.search_by_coordinates(coords, yelp_parms)
		else
			#logger.info "Searching by specific location: " + @where.to_s
			
			return @@client.search(@where, yelp_parms)
		end
	end

end

get '/' do
	logger.info "**** Looking for lunch... ****"
	@food = @@food

	#Where are we searching?  First choice is geocoordinates, otherwise check if they specified a location.
	#Otherwise ask them to specify a location.
	useCoord = false
	
	if (checkCoords?(params[:lat], params[:long]))
		coords = { 
			latitude: params[:lat], 
			longitude: params[:long] 
		}
		useCoord = true
	elsif (!isNilOrEmpty?(params[:where])) 
		@where = params[:where]
	else 
		logger.info "No location specified, defaulting to Chitown"
		@where = "Chicago"
	end

	#What are we searching for? We can search for a specific kind of food, a whitelist of acceptable foods, or a blacklist of unnacceptable foods.
	#Default to whatever is closest.
	@what = ""

	if params[:specificInput] == "true"
		@what = params[:specific]
	elsif params[:whiteListInput] == "true"
		if !params[:arr].nil? && params[:arr].length > 0
			#Search using only the items that were checked.  Shuffle them up for variety!
			@what = makeArraySearchable(params[:arr].shuffle!)
		else 
			#User chose to whitelist food options but then didn't specify any choices...
			#Blank input will search for anything and everything
			@what = ""
		end
	elsif params[:blackListInput] == "true"
		if !params[:arr].nil? && params[:arr].length > 0
			logger.info "Searching via blacklist"
			#Search for everything BUT what was checked.
			#Subtract what the user checked from the list of all foods to get our searchable list
			blacklist = @food - params[:arr]
			
			@what = makeArraySearchable(blacklist.shuffle!)
		else
			#User chose to blacklist but didn't check anything...So search for everything!
			@what = ""
		end
	else
		#Blank input will search for anything and everything
		@what = ""
	end

	#How will we sort? #0=Best matched (default), 1=Distance, 2=Highest Rated
	@randSort = 1 #Choose closest options first
	#@randSort = rand(3)  #Choose this to be EXTRA random!

	#Build paramters to search yelp!
	yelp_parms = {
		category_filter: 'restaurants', 
		term: @what, #add additional filters in order separated by ','
		limit: 10,
		sort: @randSort
	} 
	
	#Make the call to Yelp
	@retval = findMeFood(yelp_parms, useCoord, coords, @where)
	
	#Shuffle the list to change it up?
	#@retval.businesses.shuffle!
	
	#In case theres a flop and no results come back
	if @retval.businesses.length < 1
		#logger.info "Didn't find anything, rerouting to default"
		@error_message = "Swing and a miss!<br> We couldn't find anything in your area that matches what you wanted. :[<br> Try some of these suggestions instead?"
		yelp_parms["term"] = "" #Make sure we're just getting whatever is closest
		@retval = findMeFood(yelp_parms, useCoord, coords, @where)
	end

	logger.info "**** Lunch has been found ****"
	erb :whatsForLunch
end