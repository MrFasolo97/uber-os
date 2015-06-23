
local argv = { ... }
local x = 1
if argv[1] == "-v" then x = 2 end
if #argv < x then
    print( "Usage: rm [-v] <target>" )
    return
end

for k, v in pairs(fs.find(shell.resolve(argv[x]), true)) do
    fs.delete(fs.resolveLinks(v, true))
    if x == 2 then
        print("Removed " .. v)
    end
end
