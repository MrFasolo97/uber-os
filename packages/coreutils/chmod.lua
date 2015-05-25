--Chmod

local argv = { ... }

if #argv < 1 then
    print("Usage: chmod [-Rv] <mode> <file1> [file2] ...")
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
    print("Usage: chmod [-Rv] <mode> <file1> [file2] ...")
    return
end

local mode = argv[x - 1]

if not mode:match("^[0-7][0-7][0-7]$") then
    printError("Invalid mode")
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
        fsd.setNode(fsd.normalizePath(v), nil, mode)
        if verbose then print("Set mode of " .. v .. " to " .. fsd.normalizePerms(mode) .. "(" .. mode .. ")") end
    else
        for K, V in pairs(fsd.recursList(v, nil, true)) do
            fsd.setNode(V, nil, mode)
            if verbose then print("Set mode of " .. V .. " to " .. fsd.normalizePerms(mode) .. "(" .. mode .. ")") end
        end
    end
end
