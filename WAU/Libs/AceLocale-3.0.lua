--[[-----------------------------------------------------------------------------
AceLocale-3.0
A localization library with gettext-like environment support
Author: Ace3 Team
License: Public Domain
-----------------------------------------------------------------------------]]--

local MAJOR, MINOR = "AceLocale-3.0", 6
local AceLocale, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceLocale then return end -- no upgrade needed

local assert, tostring, error = assert, tostring, error
local rawset, rawget, setmetatable = rawset, rawget, setmetatable

-- GLOBALS: geterrorhandler, _G

AceLocale.apps = AceLocale.apps or {}          -- localization tables
AceLocale.appnames = AceLocale.appnames or {}  -- reverse lookup: locale table -> app name

-- This metatable does not __index itself
local readmeta = {
	__index = function(self, key)
		if key == nil then return end
		rawset(self, key, key)
		return key
	end
}

-- This metatable proxies unknown keys to the input locale table
local writeproxy = {}

local writemeta = {
	__index = function(self, key)
		return writeproxy[key] or key
	end,
	__newindex = function(self, key, value)
		if writeproxy[key] ~= nil then
			error("Attempt to override existing localization for key '"..tostring(key).."'.", 2)
		end
		rawset(self, key, value)
		writeproxy[key] = value
	end
}

function AceLocale:NewLocale(appName, locale, isDefault, silent)
	assert(appName, "Usage: NewLocale(appName, locale[, isDefault[, silent]])")

	local app = AceLocale.apps[appName]

	if not app then
		app = {}
		AceLocale.apps[appName] = app
		AceLocale.appnames[app] = appName
	end

	if not isDefault and locale ~= GetLocale() then
		return nil -- ignore non-matching locales
	end

	if isDefault and app.defaultLocale then
		error("NewLocale(appName, locale, isDefault): more than one default locale specified for '"..tostring(appName).."'.", 2)
	end

	local t = {}
	setmetatable(t, isDefault and writemeta or readmeta)

	app.defaultLocale = app.defaultLocale or (isDefault and locale)

	app[locale] = t
	return t
end

function AceLocale:GetLocale(appName, silent)
	assert(appName, "Usage: GetLocale(appName[, silent])")

	local app = AceLocale.apps[appName]
	if not app then
		if not silent then
			error("GetLocale: No locales registered for '"..tostring(appName).."'.", 2)
		end
		return nil
	end

	local locale = GetLocale()

	if app[locale] then
		return app[locale]
	elseif app.defaultLocale then
		return app[app.defaultLocale]
	elseif not silent then
		error("GetLocale: No locale defined for '"..tostring(appName).."'.", 2)
	end
end