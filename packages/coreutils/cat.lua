local argv = {...}

local f = thread.status(thread.getPID(coroutine.running())).stdin
for k, v in pairs(argv) do
    f = fs.open(shell.resolve(argv[1]), "r")
    write(f.readAll())
end

if #argv == 0 then
    write(f.readAll())
end
