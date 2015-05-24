--Utar, archiver

local argv = { ... }

local archive = lua.include("libarchive")

if #argv < 1 then
    print("Usage: utar pack|unpack")
    return
end

if argv[1] == "pack" then
    if #argv < 3 then
        print("Usage: utar pack <SOURCE> <ARCHIVE NAME>")
        return
    end
    archive.pack(shell.resolve(argv[1]), shell.resolve(argv[2]))
end

if argv[1] == "unpack" then
    if #argv < 3 then
        print("Usage: utar unpack <ARCHIVE NAME> <DESTINATION>")
        return
    end
    archive.unpack(shell.resolve(argv[1]), shell.resolve(argv[2]))
end
