-- local _DLLLoader = require("DLLLoader");

package.cpath = package.cpath .. ";C:\\Program Files (x86)\\Steam\\steamapps\\common\\BZ2R\\BZCC-StockExpansion\\Scripts\\AI's Library\\DLLs\\?.dll" -- note the last directory is "?.dll" to instruct lua to search for dll modules 

local _library = require("library")

Discord = {}

function Discord:Start(mode, mapTrn)
    _library.Start("1395004339231395920", mode, mapTrn)
end

function Discord:Update()
    _library.Update()
end

return Discord;