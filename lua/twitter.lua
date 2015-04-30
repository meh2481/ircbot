-- Functions for dealing with twitter API




local function checktwitter(channel)
	local urlToGet = "https://api.twitter.com/1.1/statuses/user_timeline.json"
	local urlParams1 = "count=2&"
	local urlParams2 = "screen_name=infinite_ammo"	--TODO: Select different peoples
	
	--local teststr = wget(urlToGet)
	--print(teststr)
	
	--teststr = wget("https://www.example.com")
	--print(teststr)
	
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
	--print(sigBase)
	sigBase = sigBase..encodeURI(urlParams2)
	print(sigBase)
	
	local signKey = G_OAUTH["consumersecret"]..'&'..G_OAUTH["accesstokensecret"]
	
	authTab["oauth_signature"] = encodeURI(encode64(hmacSHA1(signKey, sigBase)))	--Hash it
	
	headerStr = headerStr.."oauth_consumer_key=\""..authTab["oauth_consumer_key"].."\", oauth_nonce=\""..authTab["oauth_nonce"].."\", oauth_signature=\""..authTab["oauth_signature"].."\", oauth_signature_method=\""..authTab["oauth_signature_method"].."\", oauth_timestamp=\""..authTab["oauth_timestamp"].."\", oauth_token=\""..authTab["oauth_token"].."\", oauth_version=\""..authTab["oauth_version"].."\""
	
	print(headerStr)
	
	local finalStr = wget(urlToGet..'?'..urlParams1..urlParams2, headerStr)
	print(finalStr)
	
	--savetable(authTab, "authtest.txt")
	
	
	--[=["Authorization: OAuth oauth_consumer_key="FLjh22Mqyr7rr30tlswBi9Tc2", oauth_nonce="cb748646f4e3be1244b35bedff1daf87", oauth_signature="whhEQWy64dj8PL6MIJ21CG2say0%3D", oauth_signature_method="HMAC-SHA1", oauth_timestamp="1430335537", oauth_token="325517524-qy7qQCBeaOxDcGDYWA5yxkFqDfmUt8N2fy39YMvN", oauth_version="1.0""--]=]
	
	
	
end
setglobal("checktwitter", checktwitter)