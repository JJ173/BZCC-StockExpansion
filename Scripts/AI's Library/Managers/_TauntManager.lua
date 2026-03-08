-- Required helper functions.
require("_HelperFunctions")

-- Constants.
local TAUNTS_MAX = 16

TauntManager = {}

local TauntList = {}    -- List of tauns.
local TauntHeaders = {} -- Max length is 16.
local TauntHeaderCount = 0

function TauntManager.SetupTaunts()
    -- Get the current map terrain file name.
    local mapTrnFile = GetMapTRNFilename()

    -- Check to see if we can open the map terrain file.
    if (LoadFile(mapTrnFile) == nil) then
        return -- No file found. Bail.
    end

    -- Grab the taunt file name from the map terrain filename. Default to "Taunts" if it doesn't exist.
    local TauntODFName = GetODFString(mapTrnFile, "DLL", "TauntODFFile", "Taunts")
    local FullTauntODFName = TauntODFName .. ".odf"

    if (LoadFile(FullTauntODFName) == nil) then
        return -- No file found. Bail.
    end

    -- Run through the maximum amount of taunts we can, and store them if we have them.
    for i = 1, TAUNTS_MAX do
        local CategoryName = "Category" .. (i - 1)

        -- Check to see if the ODF string exists.
        TauntHeaders[i] = GetODFString(FullTauntODFName, "TauntCategories", CategoryName)

        if (TauntHeaders[i] == nil) then
            break -- Bail here if nothing found.
        end

        PrintConsoleMessage("[TM]: TauntHeader at index: " ..
        i .. " registered with value: " .. TauntHeaders[i])

        -- Process the category.
        TauntHeaderCount = TauntHeaderCount + 1
    end

    PrintConsoleMessage("[TM]: Found " .. TauntHeaderCount .. " TauntHeaders.")

    -- Run through the headers that have been found.
    for TauntType = 1, TauntHeaderCount do
        -- This should craft a taunt name from the types and load it. E.G. "Taunts_start.otf"
        local TauntFileName = TauntODFName .. TauntHeaders[TauntType] .. ".otf"
        PrintConsoleMessage("[TM]: Attempting to load " .. TauntFileName .. ".")
        local File = LoadFile(TauntFileName)

        -- Check to see if the file exists.
        if (File ~= nil) then
            -- Store the lines based on line breaks.
            local lines = {}

            -- This adds each line to a table.
            for s in File:gmatch("[^\r\n]+") do
                lines[#lines + 1] = s
            end

            -- Create a fresh table entry.
            TauntList[TauntType] = {}

            for i = 1, #lines do
                if (i > 1) then
                    local length = #TauntList[TauntType]
                    TauntList[TauntType][length + 1] = lines[i]
                end
            end
        end
    end
end

---@param tauntType integer
function TauntManager.GetRandomTauntOfType(tauntType)
    -- The database variables are indexed at 0 from C++, so correct here for Lua.
    local resolvedTauntType = tauntType + 1

    -- Just for debug.
    PrintConsoleMessage("[TM]: Requesting Taunt From .. " .. TauntHeaders[resolvedTauntType])

    -- Grab the length of the table.
    local length = #TauntList[resolvedTauntType]

    -- Return a random taunt from the requested list.
    return TauntList[resolvedTauntType][GetRandomInt(1, length)]
end

return TauntManager
