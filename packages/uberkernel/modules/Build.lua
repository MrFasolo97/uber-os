local SRC = {"lua", "fsd", "users", "acpi"}
local PWD = shell.dir()

local argv = { ... }

if #argv == 0 then return end

local function build(source)
    shell.setDir(PWD .. "/" .. source)
    shell.run("Build.lua", "build")
    shell.run("Build.lua", "install")
    shell.setDir(PWD)
end

if argv[1] == "clean" then
    fs.delete(PWD .. "/out")
    for k, v in pairs(SRC) do
        shell.setDir(PWD .. "/" .. v)
        shell.run("Build.lua", "clean")
        shell.setDir(PWD)
    end
end

if argv[1] == "prepare" then
    fs.makeDir(PWD .. "/out")
    for k, v in pairs(SRC) do
        shell.setDir(PWD .. "/" .. v)
        shell.run("Build.lua", "prepare")
        shell.setDir(PWD)
    end
end

if argv[1] == "build" then
    for k, v in pairs(SRC) do
        build(v)
    end
end

if argv[1] == "install" then
    fs.makeDir(PWD .. "/../out/modules")
    for k, v in pairs(fs.list(PWD .. "/out")) do
        fs.copy(PWD .. "/out/" .. v, PWD .. "/../out/modules/" .. v)
    end
end

local flag = false
for k, v in pairs(SRC) do
    if argv[1] == v then flag = v end
end

if flag then build(flag) end
