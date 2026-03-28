local migrator           = {}

-- Private state
local _pending           = false -- true while waiting for the JS async op
local _callback          = nil -- function(data_table_or_nil, error_string_or_nil)

-- Discover state
local _discover_pending  = false
local _discover_callback = nil

--- Escape single-quotes and backslashes so the strings are safe inside a
--- JS single-quoted string literal (used with html5.run).
local function js_escape(s)
	s = s:gsub("\\", "\\\\")
	s = s:gsub("'", "\\'")
	return s
end

--- Start an async fetch of `key_name` from Unity's IndexedDB block for
--- `unity_hash`.  `callback(data, err)` is called on the next update()
--- tick after the result is ready.
---
--- @param unity_hash  string  MD5 hex of "<CompanyName><ProductName>"
--- @param key_name    string  PlayerPrefs key whose value is a JSON string
--- @param callback    function  called as callback(table_or_nil, err_or_nil)
function migrator.fetch(unity_hash, key_name, callback)
	assert(type(unity_hash) == "string", "unity_hash must be a string")
	assert(type(key_name) == "string", "key_name must be a string")
	assert(type(callback) == "function", "callback must be a function")

	if not html5 then
		callback(nil, "not an HTML5 build")
		return
	end

	_callback = callback
	_pending  = true

	local cmd = string.format(
		"window.UnityMigrator.fetch('%s','%s')",
		js_escape(unity_hash),
		js_escape(key_name)
	)
	html5.run(cmd)
end

--- Scan the /idbfs IndexedDB for any Unity PlayerPrefs files and return
--- the discovered hash(es) via callback(hashes_table, err).
--- hashes_table is an array of MD5 hex strings (usually just one entry).
--- Must call migrator.update() every frame until the callback fires.
---
--- @param callback  function  called as callback(hashes_or_nil, err_or_nil)
function migrator.discover(callback)
	assert(type(callback) == "function", "callback must be a function")

	if not html5 then
		callback(nil, "not an HTML5 build")
		return
	end

	_discover_callback = callback
	_discover_pending  = true
	html5.run("window.UnityMigrator.discoverHashes()")
end

--- Poll the JS bridge for a result.  Must be called every frame from the
--- script's update() while a fetch is in flight.
function migrator.update()
	if not html5 then return end

	-- Poll discover
	if _discover_pending then
		local ready = html5.run("window.UnityMigrator.isDiscoverReady()")
		if ready == "true" then
			local err_str      = html5.run("window.UnityMigrator.getDiscoverError()")
			local cb           = _discover_callback
			_discover_callback = nil
			_discover_pending  = false
			if err_str ~= "null" and err_str ~= "" and err_str ~= nil then
				cb(nil, err_str)
			else
				local json_str = html5.run("window.UnityMigrator.getDiscoveredHashes()")
				local ok, hashes = pcall(json.decode, json_str)
				if ok then
					cb(hashes, nil)
				else
					cb(nil, "JSON decode error: " .. tostring(hashes))
				end
			end
		end
		return -- don't poll fetch while discover is in flight
	end

	if not _pending then return end

	local ready = html5.run("window.UnityMigrator.isReady()")
	if ready ~= "true" then return end

	-- Consume error first, then the result
	local err_str = html5.run("window.UnityMigrator.getError()")
	if err_str ~= "null" and err_str ~= "" and err_str ~= nil then
		_pending = false
		local cb = _callback
		_callback = nil
		cb(nil, err_str)
		return
	end

	local json_str = html5.run("window.UnityMigrator.getResult()")
	_pending       = false
	local cb       = _callback
	_callback      = nil

	if json_str == "null" or json_str == nil or json_str == "" then
		-- Key was not found in Unity's prefs file
		cb(nil, nil)
		return
	end

	local ok, result = pcall(json.decode, json_str)
	if ok then
		cb(result, nil)
	else
		cb(nil, "JSON decode error: " .. tostring(result))
	end
end

--- Returns true while a fetch is still in flight.
function migrator.is_pending()
	return _pending
end

return migrator
