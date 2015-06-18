local argv = {...}

if #argv < 1 then
    print("Usage: grep [file] <pattern>")
    return
end

local pattern = argv[1]

local f = thread.status(thread.getPID(coroutine.running())).stdin
if #argv > 1 then
    f = fs.open(shell.resolve(argv[1]), "r")
    pattern = argv[2]
end

local s = string.split(f.readAll(), "\n")

for k, v in pairs(s) do
    if v:match(pattern) then
        write(v .. "\n")
    end
end
