local SRC = "acpi"
local PWD = shell.dir()

local argv = { ... }

if #argv == 0 then return end

if argv[1] == "clean" then pcall(fs.delete, PWD .. "/out") end
if argv[1] == "prepare" then pcall(fs.makeDir, PWD .. "/out") end
if argv[1] == "build" then
    local minify = lua.include("min")
    local f = fs.open(PWD .. "/" .. SRC .. ".lua", "r")
    local t = minify(f.readAll())
    f.close()
    f = fs.open(PWD .. "/out/" .. SRC, "w")
    f.write(t)
    f.close()
end
if argv[1] == "install" then
    fs.copy(PWD .. "/out/" .. SRC, shell.resolve("../out") .. "/" .. SRC)
end
