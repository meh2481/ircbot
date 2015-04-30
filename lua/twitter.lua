-- Functions for dealing with twitter API



local function checktwitter(nopost)
	local channel = getchannel()
	print("checking the twitterverse...")
	local urlToGet = "https://api.twitter.com/1.1/statuses/user_timeline.json"
	local numtweets = 4
	local tweeter = "infinite_ammo"	--TODO: Select different peoples
	local urlParams1 = "count="..numtweets.."&"
	local urlParams2 = "screen_name="..tweeter
	
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
	sigBase = sigBase..encodeURI(urlToGet)..'&'..encodeURI(urlParams1)
	
	--Sort the list
	local orderedList = {}
	for k,v in pairs(authTab) do
		table.insert(orderedList,k)
	end
	table.sort(orderedList)
	for i,n in ipairs(orderedList) do 
		sigBase = sigBase..encodeURI(n..'='..authTab[n]..'&')
	end
	
	sigBase = sigBase..encodeURI(urlParams2)
	
	local signKey = G_OAUTH["consumersecret"]..'&'..G_OAUTH["accesstokensecret"]
	
	authTab["oauth_signature"] = encodeURI(encode64(hmacSHA1(signKey, sigBase)))	--Hash it
	
	headerStr = headerStr.."oauth_consumer_key=\""..authTab["oauth_consumer_key"].."\", oauth_nonce=\""..authTab["oauth_nonce"].."\", oauth_signature=\""..authTab["oauth_signature"].."\", oauth_signature_method=\""..authTab["oauth_signature_method"].."\", oauth_timestamp=\""..authTab["oauth_timestamp"].."\", oauth_token=\""..authTab["oauth_token"].."\", oauth_version=\""..authTab["oauth_version"].."\""
	
	--Fetch result from twitter
	local JSONScript = wget(urlToGet..'?'..urlParams1..urlParams2, headerStr)
	
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
		for i = numtweets, 1, -1 do	--Tweets are posted in reverse order from IRC, so spin backwards over this list to post oldest first
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
					
					if totweet == true then
						say(channel, "[@"..tweeter.."] "..tweettext.." (https://twitter.com/"..tweeter.."/status/"..twitter_table[i]["id_str"]..')')
					end
				end
			end
		end
	end
end
setglobal("checktwitter", checktwitter)