
local tArgs = { ... }
if #tArgs < 1 then
	print( "Usage: rm <path>" )
	return
end

local sPath = shell.resolve( tArgs[1] )
fs.delete(sPath)
