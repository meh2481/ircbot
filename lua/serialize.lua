
--local DD = modlib_include("lib/datadumper.lua")

local strmatch = string.match
local tins = table.insert
local type = type
local pairs = pairs
local tostring = tostring
local strfmt = string.format

local isSafeTableKey

do
	local lua_reserved_keywords = {
		'and',	'break',  'do',
		'else',   'elseif', 'end',
		'false',  'for',	'function',
		'if',	 'in',	 'local',
		'nil',	'not',	'or',
		'repeat', 'return', 'then',
		'true',   'until',  'while',
	}

	local keywords = {}
	for _, w in pairs(lua_reserved_keywords) do
		keywords[w] = true
	end

	isSafeTableKey = function(s)
		return type(s) == "string" and not (keywords[s] or strmatch(s, "[^a-zA-Z]"))
	end
end

local dump_simple_i

local function dump_simple_table(t, buf)
	tins(buf, "{")
	for key, val in pairs(t) do
		if isSafeTableKey(key) then
			tins(buf, key .. "=")
		else
			tins(buf, "[")
			dump_simple_i(key, buf)
			tins(buf, "]=")
		end
		dump_simple_i(val, buf)
		tins(buf, ",")
	end
	return tins(buf, "}")
end

local function dump_simple_string(t, buf)
	return tins(buf, strfmt("%q", t))
end

local function dump_simple_value(t, buf)
	return tins(buf, tostring(t))
end

local function dump_ignore()
end

local dumpfunc = {
	table = dump_simple_table,
	string = dump_simple_string,
	number = dump_simple_value,
	boolean = dump_simple_value,
	userdata = dump_ignore,
}
local function dump_error(t, buf)
	error("serialize: Cannot dump type " .. type(t) .. " (\"" .. tostring(t) .. "\")")
end
setmetatable(dumpfunc, {
	__index = function(t, k)
		return dump_error
	end
})

dump_simple_i = function(t, buf)
	return dumpfunc[type(t)](t, buf)
end


local function dump_simple(t)
	local buf = { "return " }
	local f = function()
		return dump_simple_i(t, buf)
	end
	f()
	return table.concat(buf)
end

local function restore(s)
	return loadstring(s)()
end

local function serialize_save(tab, full)
	if full then
		--errorLog("FIXME: datadumper.lua is problematic to include because of string.dump()")
		--return tostring(DD.dump(tab, true))
	else
		return tostring(dump_simple(tab))
	end
end

local function serialize_restore(s)
	local r
	local ok, ret = pcall(restore, s)
	if not ok then
		return nil, ret
	end
	return ret
end

setglobal("serialize_save", serialize_save)
setglobal("serialize_restore", serialize_restore)
