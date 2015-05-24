--Make a package

local argv = { ... }

if #argv < 1 then
    error("Usage: makepkg <PACKAGE>")
end

local oldDir = shell.dir()
shell.setDir("/usr/src/" .. argv[1])
print("Building...")
shell.run("Build.lua")
fs.makeDir("/tmp/" .. argv[1])
print("Packaging...")
shell.run("Build.lua install /tmp/" .. argv[1])
fs.copy("/usr/src/" .. argv[1] .. "/PKGINFO.lua", "/tmp/" .. argv[1] .."/PKGINFO.lua")
shell.setDir(oldDir)
local archive = lua.include("libarchive")
archive.pack("/tmp/" .. argv[1], shell.resolve(argv[1]) .. ".utar")
fs.delete("/tmp/" .. argv[1])
print("Done!")
