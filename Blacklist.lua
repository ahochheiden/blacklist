local debug = 1

local function debugOutput(message)
	if debug == 1 then
		print(message)
	end
end

local function getFullUnitName(unit)
	local output = nil

	if UnitPlayerControlled(unit) then
		local name, realm = UnitName(unit)

		-- realm name is nil is they are from the same realm as
		-- as the local palyer, so we need to get the name of the
		-- realm we're on for the lookup table
		if realm == nil then
			realm = GetRealmName()
		end
		
		output = name .. '-' .. realm
	end

	return output
end

local onEvent = function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blacklist" then
        -- Our saved variables, if they exist, have been loaded at this point.
        if LookupTable == nil then
            -- This is the first time this addon is loaded; set SVs to default values
			LookupTable = {}
			
			debugOutput('First login, LookupTable initialized.')
		end

	else
		if event == "PLAYER_LOGOUT" then

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

SLASH_BLACKLIST1 = "/blacklist"
function SlashCmdList.BLACKLIST(msg)	
	--printTable(LookupTable)

	local name, realm = UnitName('player')

	if realm == nil then
		realm = GetRealmName()
	end

	for i = 1, 12 do
		print(name .. realm)
	end
end

SLASH_BL1 = "/bl"
function SlashCmdList.BL(msg)
	local fullName = getFullUnitName('target')

	if fullName ~= nil then
		local newEntry = {}


		newEntry['REASON'] = 'a very bad man'

		LookupTable[fullName] = newEntry
	end
end