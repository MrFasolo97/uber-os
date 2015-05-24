--chown

local argv = { ... }

local x = 2
local recurs = false
local verbose = false
if argv[1]:match("^%-") then
    if argv[1]:match("R") then recurs = true end
    if argv[1]:match("v") then verbose = true end
    x = 3 
end

if #argv < x then
    print("Usage: chown [-Rv] <user> <file1> [file2] ...")
    return
end

local user = argv[x - 1]

local uid = users.getUIDByUsername(user)
if not uid then
    printError("No such user")
    return
end

local arguments = {}
for k, v in pairs(argv) do
    local w = fs.find(shell.resolve(v))
    for K, V in pairs(w) do
        table.insert(arguments, V)
    end
end

for k, v in pairs(arguments) do
    if not recurs then
        fsd.setNode(fsd.normalizePath(v), uid)
        if verbose then print("Ownership of " .. v .. " changed to " .. user) end
    else
        for K, V in pairs(fsd.recursList(v, nil, true)) do
            fsd.setNode(V, uid)
            if verbose then print("Ownership of " .. V .. " changed to " .. user) end
        end
    end
end
