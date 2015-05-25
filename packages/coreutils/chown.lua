--chown

local argv = { ... }

if #argv < 1 then
    print("Usage: chown [-Rv] [<user>][:[<group>]] <file1> [file2] ...")
    return
end

local x = 2
local recurs = false
local verbose = false
if argv[1]:match("^%-") then
    if argv[1]:match("R") then recurs = true end
    if argv[1]:match("v") then verbose = true end
    x = 3 
end

if #argv < x then
    print("Usage: chown [-Rv] [<user>][:[<group>]] <file1> [file2] ...")
    return
end

local user = ""
local group = ""

if string.find(argv[x - 1], ":") then
    local tmp = string.split(argv[x - 1], ":")
    user = tmp[1]
    group = tmp[2]
else
    user = argv[x - 1]
end

local uid = users.getUIDByUsername(user)
local gid = users.getGIDByName(group)

local arguments = {}
for k, v in pairs(argv) do
    local w = fs.find(shell.resolve(v))
    for K, V in pairs(w) do
        table.insert(arguments, V)
    end
end

for k, v in pairs(arguments) do
    if not recurs then
        if user ~= "" then
            fsd.setNode(fsd.normalizePath(v), uid)
        end
        if group ~= "" then
            fsd.setNode(fsd.normalizePath(v), nil, nil, nil, gid)
        end
        if verbose then print("Ownership of " .. v .. " changed to " .. argv[x - 1]) end
    else
        for K, V in pairs(fsd.recursList(v, nil, true)) do
            if user ~= "" then
                fsd.setNode(V, uid)
            end
            if group ~= "" then
                fsd.setNode(V, nil, nil, nil, gid)
            end
            if verbose then print("Ownership of " .. V .. " changed to " .. argv[x - 1]) end
        end
    end
end
