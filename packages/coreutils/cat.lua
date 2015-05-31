local argv = {...}

local f = stdin
for k, v in pairs(argv) do
    f = fs.open(shell.resolve(argv[1]), "r")
    write(f.readAll())
end

if #argv == 0 then
    write(stdin.readAll())
end
