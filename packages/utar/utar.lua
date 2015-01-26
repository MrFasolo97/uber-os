--Utar, archiver

local argv = { ... }

lua.include("libarchive")

if #argv < 1 then
  error("Usage: utar pack|unpack")
end

if argv[1] == "pack" then
  if #argv < 3 then
    error("Usage: utar pack <SOURCE> <ARCHIVE NAME>")
  end
  archive.pack(shell.resolve(argv[1]), shell.resolve(argv[2]))
end

if argv[1] == "unpack" then
  if #argv < 3 then
    error("Usage: utar unpack <ARCHIVE NAME> <DESTINATION>")
  end
  archive.unpack(shell.resolve(argv[1]), shell.resolve(argv[2]))
end
