-- Functions for dealing with twitter API
local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local function tweetsat()
	local channel = getchannel()
	print("checking twitter mentions...")
	local urlToGet = "https://api.twitter.com/1.1/statuses/mentions_timeline.json"
	local numtweets = 5
	local urlParams1 = "count="..numtweets
	--local urlParams2 = "screen_name="..tweeter
	
	local headerStr = "Authorization: OAuth "
	local authTab = {
	["oauth_consumer_key"] = G_OAUTH["consumerkey"],
	["oauth_nonce"] = encode64(tostring(os.time()*os.time()*3)):gsub("%W",""),	--Has to be different than the other nonce...
	--["oauth_signature"] = "",
	["oauth_signature_method"] = "HMAC-SHA1",
	["oauth_timestamp"] = os.time(),
	["oauth_token"] = G_OAUTH["accesstoken"],
	["oauth_version"] = "1.0",
	}
	
	local sigBase = "GET&"
	sigBase = sigBase..encodeURI(urlToGet)..'&'..encodeURI(urlParams1.."&")
	
	--Sort the list
	local orderedList = {}
	for k,v in pairs(authTab) do
		table.insert(orderedList,k)
	end
	table.sort(orderedList)
	for i,n in ipairs(orderedList) do 
		sigBase = sigBase..encodeURI(n..'='..authTab[n]..'&')
	end
	
	--Strip the last ampersand
	sigBase = string.sub(sigBase, 0, -4)
	
	--sigBase = sigBase..encodeURI(urlParams2)
	
	local signKey = G_OAUTH["consumersecret"]..'&'..G_OAUTH["accesstokensecret"]
	
	authTab["oauth_signature"] = encodeURI(encode64(hmacSHA1(signKey, sigBase)))	--Hash it
	
	headerStr = headerStr.."oauth_consumer_key=\""..authTab["oauth_consumer_key"].."\", oauth_nonce=\""..authTab["oauth_nonce"].."\", oauth_signature=\""..authTab["oauth_signature"].."\", oauth_signature_method=\""..authTab["oauth_signature_method"].."\", oauth_timestamp=\""..authTab["oauth_timestamp"].."\", oauth_token=\""..authTab["oauth_token"].."\", oauth_version=\""..authTab["oauth_version"].."\""
	
	--Fetch result from twitter
	local JSONScript = wget(urlToGet..'?'..urlParams1, headerStr)
	
	--print(JSONScript)
	
	--Decode into Lua-parsable table
	local twitter_table = G_JSON:decode(JSONScript)
	
	--savetable(twitter_table, "test.txt")
	
	--Format and output
	if twitter_table ~= nil then
		for i = tablelength(twitter_table), 1, -1 do	--Tweets are posted in reverse order from IRC, so spin backwards over this list to post oldest first
		    --print("str: "..twitter_table[i]["id_str"].."table: "..G_TWEETS[twitter_table[i]["id_str"]])
			if G_TWEETS[twitter_table[i]["id_str"]] == nil then	--Haven't posted this tweet yet
				G_TWEETS[twitter_table[i]["id_str"]] = 1
				local tweettext = twitter_table[i]["text"]
				say(channel, "[@"..twitter_table[i]["user"]["screen_name"].."] "..tweettext)
			end
		end
	end
end
setglobal("tweetsat", tweetsat)

local function checktwitter(nopost)
	tweetsat()
	local channel = getchannel()
	print("checking the twitterverse...")
	local urlToGet = "https://api.twitter.com/1.1/statuses/home_timeline.json"
	local numtweets = 5
	local urlParams1 = "count="..numtweets--.."&"
	
	local headerStr = "Authorization: OAuth "
	local authTab = {
	["oauth_consumer_key"] = G_OAUTH["consumerkey"],
	["oauth_nonce"] = encode64(tostring(os.time()*os.time())):gsub("%W",""),	--Don't care too much about randomness here, so get 24-ish bytes of junk from time
	--["oauth_signature"] = "",
	["oauth_signature_method"] = "HMAC-SHA1",
	["oauth_timestamp"] = os.time(),
	["oauth_token"] = G_OAUTH["accesstoken"],
	["oauth_version"] = "1.0",
	}
	
	local sigBase = "GET&"
	sigBase = sigBase..encodeURI(urlToGet)..'&'..encodeURI(urlParams1.."&")
	
	--Sort the list
	local orderedList = {}
	for k,v in pairs(authTab) do
		table.insert(orderedList,k)
	end
	table.sort(orderedList)
	for i,n in ipairs(orderedList) do 
		sigBase = sigBase..encodeURI(n..'='..authTab[n]..'&')
	end
	
	--Strip the last ampersand
	sigBase = string.sub(sigBase, 0, -4)
	
	--sigBase = sigBase..encodeURI(urlParams2)
	
	local signKey = G_OAUTH["consumersecret"]..'&'..G_OAUTH["accesstokensecret"]
	
	authTab["oauth_signature"] = encodeURI(encode64(hmacSHA1(signKey, sigBase)))	--Hash it
	
	headerStr = headerStr.."oauth_consumer_key=\""..authTab["oauth_consumer_key"].."\", oauth_nonce=\""..authTab["oauth_nonce"].."\", oauth_signature=\""..authTab["oauth_signature"].."\", oauth_signature_method=\""..authTab["oauth_signature_method"].."\", oauth_timestamp=\""..authTab["oauth_timestamp"].."\", oauth_token=\""..authTab["oauth_token"].."\", oauth_version=\""..authTab["oauth_version"].."\""
	
	--Fetch result from twitter
	local JSONScript = wget(urlToGet..'?'..urlParams1, headerStr)
	
	--Decode into Lua-parsable table
	local twitter_table = G_JSON:decode(JSONScript)
	
	local rtfiltertab = {
		"nitw",
		"night in the woods",
		"nightinthewoods",
		"aquaria"
	}
	
	--Format and output
	if twitter_table ~= nil then
		for i = tablelength(twitter_table), 1, -1 do	--Tweets are posted in reverse order from IRC, so spin backwards over this list to post oldest first
			if G_TWEETS[twitter_table[i]["id_str"]] == nil then	--Haven't posted this tweet yet
				G_TWEETS[twitter_table[i]["id_str"]] = 1
				if nopost == nil then
					local tweettext = twitter_table[i]["text"]
					local totweet = true
					
					--if it's a RT, regex it so that aquaria, NITW, etc is okay
					--if not an RT, post it and see what happens
					
					if tweettext:sub(1,2) == "RT" or tweettext:sub(1,1) == "@" then
						totweet = false
						
						for k,v in pairs(rtfiltertab) do
							if tweettext:lower():find(v) ~= nil then
								totweet = true
								break
							end
						end
					else
						totweet = true
					end
					
					if twitter_table[i]["user"]["screen_name"] == "immabot_beep" then totweet = false end	--Don't tweet my tweets!
					
					if totweet == true then
						say(channel, "[@"..twitter_table[i]["user"]["screen_name"].."] "..tweettext)
					end
				end
			end
		end
	end
end
setglobal("checktwitter", checktwitter)

local function tweet(str)
	--TODO: truncate length

	local channel = getchannel()
	print("tweeting: "..str)
	local urlToGet = "https://api.twitter.com/1.1/statuses/update.json"
	local urlParams1 = "status="..encodeURI(str)
	
	local headerStr = "Authorization: OAuth "
	local authTab = {
	["oauth_consumer_key"] = G_OAUTH["consumerkey"],
	["oauth_nonce"] = encode64(tostring(os.time()*os.time()*os.time())):gsub("%W",""),	--Don't care too much about randomness here, so get 24-ish bytes of junk from time
	--["oauth_signature"] = "",
	["oauth_signature_method"] = "HMAC-SHA1",
	["oauth_timestamp"] = os.time(),
	["oauth_token"] = G_OAUTH["accesstoken"],
	["oauth_version"] = "1.0",
	}
	
	local sigBase = "POST&"
	sigBase = sigBase..encodeURI(urlToGet)..'&'--..'&'..encodeURI(urlParams1)
	
	--Sort the list
	local orderedList = {}
	for k,v in pairs(authTab) do
		table.insert(orderedList,k)
	end
	table.sort(orderedList)
	for i,n in ipairs(orderedList) do 
		sigBase = sigBase..encodeURI(n..'='..authTab[n]..'&')
	end
	
	--Strip the last ampersand
	--sigBase = string.sub(sigBase, 0, -4)
	sigBase = sigBase..encodeURI(urlParams1)
	print(sigBase)
	
	local signKey = G_OAUTH["consumersecret"]..'&'..G_OAUTH["accesstokensecret"]
	
	authTab["oauth_signature"] = encodeURI(encode64(hmacSHA1(signKey, sigBase)))	--Hash it
	
	headerStr = headerStr.."oauth_consumer_key=\""..authTab["oauth_consumer_key"].."\", oauth_nonce=\""..authTab["oauth_nonce"].."\", oauth_signature=\""..authTab["oauth_signature"].."\", oauth_signature_method=\""..authTab["oauth_signature_method"].."\", oauth_timestamp=\""..authTab["oauth_timestamp"].."\", oauth_token=\""..authTab["oauth_token"].."\", oauth_version=\""..authTab["oauth_version"].."\""
	
	--Fetch result from twitter
	--local JSONScript = wget(urlToGet..'?'..urlParams1, headerStr)
	local JSONScript = post(urlToGet, headerStr, "status", str)
	
	local twitter_table = G_JSON:decode(JSONScript)
	--savetable(twitter_table, "twitterresult.txt")
	
	--Check and make sure this went through
	if twitter_table ~= nil then
		local tweet_err = twitter_table["errors"]
		if tweet_err ~= nil then
			local err_msg = tweet_err[1]["message"]
			if err_msg ~= nil then
				say(getchannel(), err_msg)
			end
		end
	end
	
	print(JSONScript)
end
setglobal("tweet", tweet)