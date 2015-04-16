-- Change Directory

local tArgs = { ... }

local sNewDir = nil

if #tArgs == 0 then
  -- go home
  sNewDir = users.getHome( users.getActiveUID() )
else
  -- go to the first directory listed
  sNewDir = shell.resolve( tArgs[1] )
end

if fs.isDir( sNewDir ) then
  shell.setDir( sNewDir )
else
  print( "Not a directory" )
end
