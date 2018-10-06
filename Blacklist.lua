-- Variables
local debug = 0

local enabled = false
local timeLoggedIn = 0
local loginDelay = 7

local sessionBlacklistedPlayersReported = nil

local classColorsLookup = {
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

-- Utility functions
local function debugOutput(identifier, output)
	if debug == 1 then
		print(identifier .. ': "'.. output .. '"')
	end
end

local function debugOutput(output)
	if debug == 1 then
		print(output)
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

local function tableHasValue (table, inputValue)
    for index, value in pairs(table) do
		if value == inputValue then
            return true
        end
    end

    return false
end

local function tableHasIndex (table, inputIndex)
	for index, value in pairs(table) do
		if index == inputIndex then
            return true
        end
    end

    return false
end

local function splitString(original, delimiter)
	result = {};
	
    for match in (original .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match);
	end
	
    return result;
end

-- Setup
local function onUpdate(self,elapsed)
	Blacklist:LoginDelay(elapsed)
  end

local onEvent = function(self, event, ...)
	if event ~= "" and event ~= nil then
		self[event](self, event, ...)	
	end
end

Blacklist = CreateFrame("Frame")
Blacklist:SetScript("OnEvent", onEvent)
Blacklist:SetScript("OnUpdate", onUpdate)
Blacklist:RegisterEvent("ADDON_LOADED")
Blacklist:RegisterEvent("GROUP_ROSTER_UPDATE")

-- Addon specific functions
function Blacklist:getFullUnitName(unit)
	local name, realm = nil

	if UnitPlayerControlled(unit) then
		name, realm = UnitName(unit)

		-- realm name is nil is they are from the same realm as
		-- as the local palyer, so we need to append the name of the
		-- current realm to be consistent in the lookup table
		if realm == nil then
			realm = GetRealmName()
		end
	end

	return name, realm
end

function Blacklist:colorizeFullUnitName(name, realm, classIndex)
	local color = classColorsLookup[classIndex]

	local colorHelper = {
		'|cff', color, name, '|r'
	}

	coloredName = table.concat(colorHelper, "")

	output = coloredName .. '-' .. realm

	return output
end

function Blacklist:getRealmSuffixedGroupMemberNames()
	local group = GetHomePartyInfo()
	for index, groupMember in pairs(group) do

		foundDash = string.find(groupMember, "-")

		if foundDash == nil then
			groupMember = groupMember .. "-" .. GetRealmName()
			group[index] = groupMember
		end
	end

	return group
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
				print('<Blacklist> Your blacklist is currently empty.')
			else		
				print('<Blacklist> Blacklisted Player(s):')		
				for index, value in pairs(blacklistLookup) do
					nameRealmSplit = splitString(index, '-')
				
					name = nameRealmSplit[1]
					realm = nameRealmSplit[2]
		
					colorizedUnitName = Blacklist:colorizeFullUnitName(name, realm, value['CLASS'])
		
					output = '<Blacklist> ' .. colorizedUnitName .. ' blacklist reason: ' .. value['REASON']
					print(output)
				end
			end
		end
	end

	if command == 'target' then
		local name, realm = Blacklist:getFullUnitName('target')

		if name ~= nil and realm ~= nil then
			reason = remainingArgs

			if reason == nil or reason == '' then
				reason = 'No reason provided.'
			end

			debugOutput('reason', reason)

			local newEntry = {}
			local localizedClass, englishClass, classIndex = UnitClass("target");
		
			newEntry['REASON'] = reason
			newEntry['CLASS'] = classIndex
	
			fullName = name .. '-' .. realm

			blacklistLookup[fullName] = newEntry
			
			print('<Blacklist> Added '.. Blacklist:colorizeFullUnitName(name, realm, classIndex) .. ', Reason: ' .. reason)
		end
	end

	if command == 'clear' then
		blacklistLookup = {}
		print("<Blacklist> Your blacklist has been cleared.")
	end
end

function Blacklist:checkBlacklist()
	if enabled then
		if sessionBlacklistedPlayersReported == nil then
			sessionBlacklistedPlayersReported = {}
		end

		if IsInGroup() then
			groupMembers = Blacklist:getRealmSuffixedGroupMemberNames()

			for index, groupMember in pairs(groupMembers) do
				if tableHasIndex(blacklistLookup, groupMember) then
					if tableHasIndex(sessionBlacklistedPlayersReported, groupMember) then
						debugOutput("Matched player (" .. groupMember .. ") already reported. Skipping")
						-- Do nothing, don't report the same player twice
					else
						sessionBlacklistedPlayersReported[groupMember] = true

						entry = blacklistLookup[groupMember]

						class = entry['CLASS']
						reason = entry['REASON']
	
						output = '<Blacklist>  ' .. groupMember .. ' is blacklisted for: ' .. reason

						SendChatMessage(output, "party" , nil , "channel")
					end
				end
			end
		end
	end
end

 function Blacklist:LoginDelay(elapsed)
	if enabled == false then
		timeLoggedIn = timeLoggedIn + elapsed

		if timeLoggedIn > loginDelay then
			enabled = true
			debugOutput("Enabled = true")

			Blacklist:checkBlacklist()
		end
	end
end

-- Event Handlers
function Blacklist:ADDON_LOADED(self, player)
    -- Our saved variables, if they exist, have been loaded at this point.
    if blacklistLookup == nil then
        -- This is the first time this addon is loaded; set SVs to default values
		blacklistLookup = {}
	end
end

function Blacklist:GROUP_ROSTER_UPDATE()
	Blacklist:checkBlacklist()
end