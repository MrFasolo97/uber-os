
local argv = { ... }
if #argv < 2 then
	print( "Usage: mv <source> <destination>" )
	return
end

fs.move(shell.resolve(argv[1]), shell.resolve(argv[2]))
