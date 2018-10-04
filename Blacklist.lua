﻿local debug = 0

local function debugOutput(identifier, output)
	if debug == 1 then
		print(identifier .. ': "'.. output .. '"')
	end
end

local function getFullUnitName(unit)
	local name, realm = nil

	if UnitPlayerControlled(unit) then
		name, realm = UnitName(unit)

		-- realm name is nil is they are from the same realm as
		-- as the local palyer, so we need to get the name of the
		-- realm we're on for the lookup table
		if realm == nil then
			realm = GetRealmName()
		end
	end

	return name, realm
end

local onEvent = function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blacklist" then
        -- Our saved variables, if they exist, have been loaded at this point.
        if blacklistLookup == nil then
            -- This is the first time this addon is loaded; set SVs to default values
			blacklistLookup = {}
			
			debugOutput('First login', 'blacklistLookup initialized.')
		end
	else
		if event == "PLAYER_LOGOUT" then
			-- nothing to do, remove later
		end
    end
end

local function printTable(table)
	for index, value in pairs(table) do
		if type(value) == "table" then
			print(index)
			printTable(value)
		else
			print(index, value)
		end
	end
end

Blacklist = CreateFrame("Frame")
Blacklist:SetScript("OnEvent", onEvent)
Blacklist:RegisterEvent("ADDON_LOADED")
Blacklist:RegisterEvent("PLAYER_LOGOUT")

classColorsLookup = {
	"C79C6E", -- [1] Warrior
	"F58CBA", -- [2] Paladin
	"ABD473", -- [3] Hunter
	"FFF569", -- [4] Rogue
	"FFFFFF", -- [5] Priest
	"C41F3B", -- [6] Death Knight
	"0070DE", -- [7] Shaman
	"40C7EB", -- [8] Mage
	"8787ED", -- [9] Warlock
	"00FF96", -- [10] Monk
	"FF7D0A", -- [11] Druid
	"A330C9", -- [12] Demon Hunter
}

local function colorize(color, text)
	local colorHelper = {
		'|cff', color, text, '|r'
	}

	return table.concat(colorHelper, "")
end

local function colorizeFullUnitName(name, realm, classIndex)
	local color = classColorsLookup[classIndex]

	output = colorize(color, name) .. '-' .. realm

	return output
end

function splitString(original, delimiter)
	result = {};
	
    for match in (original .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match);
	end
	
    return result;
end

SLASH_BLACKLIST1 = "/blacklist"
SLASH_BLACKLIST2 = "/bl"
function SlashCmdList.BLACKLIST(msg)	
	debugOutput('All arguments', msg)

	splitArgs = splitString(msg, ' ')
	command = splitArgs[1]

	debugOutput('command', command)

	table.remove(splitArgs, 1)
	remainingArgs = table.concat(splitArgs, " ")

	debugOutput('remainingArgs', remainingArgs)

	if command == '' then
		if blacklistLookup ~= nil then

			playersBlacklisted = 0

			for _ in pairs(blacklistLookup) do 
				playersBlacklisted = playersBlacklisted + 1
			 end

			if playersBlacklisted == 0 then
				print('Your blacklist is currently empty.')
			else		
				print('Blacklisted Player(s):')		
				for index, value in pairs(blacklistLookup) do
					nameRealmSplit = splitString(index, '-')
				
					name = nameRealmSplit[1]
					realm = nameRealmSplit[2]
		
					colorizedUnitName = colorizeFullUnitName(name, realm, value['CLASS'])
		
					output = colorizedUnitName .. ' blacklist reason: ' .. value['REASON']
					print(output)
				end
			end
		end
	end

	if command == 'target' then
		local name, realm = getFullUnitName('target')

		if name ~= nil and realm ~= nil then

			reason = remainingArgs

			if reason == nil or reason == '' then
				reason = 'None reason provided.'
			end

			debugOutput('reason', reason)

			local newEntry = {}
			local localizedClass, englishClass, classIndex = UnitClass("target");
		
			newEntry['REASON'] = reason
			newEntry['CLASS'] = classIndex
	
			fullName = name .. '-' .. realm

			blacklistLookup[fullName] = newEntry
			
			print('Blacklisting: '.. colorizeFullUnitName(name, realm, classIndex) .. ', Reason: ' .. reason)
		end
	end

	if command == 'clear' then
		blacklistLookup = {}
		print("Your blacklist has been cleared.")
	end
end