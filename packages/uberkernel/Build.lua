--Build this package from inside UberOS
local minify = lua.include("min")
local SRC = {"uberkernel"}
local SRC_MODULES = {"fsd", "lua", "users", "acpi"}
local SRC_DRIVERS_FS = {"ccfs", "devfs", "romfs", "ufs", "tmpfs"}
local PWD = shell.dir()
local argv = { ... }

local function clean()
    fs.delete(PWD .. "/out")
    shell.setDir(PWD .. "/modules")
    shell.run("Build.lua", "clean")
    shell.setDir(PWD)
    shell.setDir(PWD .. "/drivers/fs")
    shell.run("Build.lua", "clean")
    shell.setDir(PWD)
end

local function prepare()
    fs.makeDir(PWD .. "/out")
    for k, v in pairs(SRC_MODULES) do
        shell.setDir(PWD .. "/modules/" .. v)
        shell.run("Build.lua", "prepare")
        shell.setDir(PWD)
    end
    for k, v in pairs(SRC_DRIVERS_FS) do
        shell.setDir(PWD .. "/drivers/fs/" .. v)
        shell.run("Build.lua", "prepare")
        shell.setDir(PWD)
    end
end

local function build(source, t)
    if not source then 
        for k, v in pairs(SRC) do build(v, "regular") end
        for k, v in pairs(SRC_MODULES) do build(v, "module") end
        for k, v in pairs(SRC_DRIVERS_FS) do build(v, "driver_fs") end
        shell.setDir(PWD .. "/modules")
        shell.run("Build.lua", "install")
        shell.setDir(PWD .. "/drivers/fs")
        shell.run("Build.lua", "install")
        shell.setDir(PWD)
        return 
    end
    local f
    if t == "regular" then 
        print("Building " .. source)
        local minify = lua.include("min")
        local f = fs.open(PWD .. "/" .. source .. ".lua", "r")
        local t = minify(f.readAll())
        f.close()
        f = fs.open(PWD .. "/out/" .. source, "w")
        f.write(t)
        f.close()
    else
        if t == "module" then
            print("Building module " .. source)
            shell.setDir(shell.resolve("modules"))
        end
        if t == "driver_fs" then
            print("Building FS driver " .. source)
            shell.setDir(shell.resolve("drivers/fs"))
        end
        shell.run("Build.lua", source)
    end
    shell.setDir(PWD)
end

local function install(root)
    root = root or ""
    print("Installing into /" .. root)
    pcall(fs.copy, PWD .. "/out/uberkernel_img", root .. "/boot/uberkernel")
end

local function genimg()
    print("Generating kernel image")
    local modules = fs.list(PWD .. "/out/modules")
    local drivers_fs = fs.list(PWD .. "/out/drivers/fs")
    local img = fs.open(PWD .. "/out/uberkernel_img", "w")
    local f
    for k, v in pairs(modules) do
        print("Injecting module " .. v)
        img.write('_G["loadmodule_' .. v .. '"]=function()\n')
            f = fs.open(PWD .. "/out/modules/" .. v, "r")
            img.write(f.readAll())
            f.close()
            img.write("\nend\n")
        end
        for k, v in pairs(drivers_fs) do
            print("Injecting FS driver " .. v)
            img.write('_G["loadfsdriver_' .. v .. '"]=function(oldfs,drivers)\n')
                f = fs.open(PWD .. "/out/drivers/fs/" .. v, "r")
                img.write(f.readAll())
                f.close()
                img.write("\nend\n")
            end
            print("Injecting main kernel code")
            f = fs.open(PWD .. "/out/uberkernel", "r")
            img.write(f.readAll())
            f.close()
            img.close()
            print("Generating done")
        end

        if #argv == 0 then clean() prepare() build() return end

        if argv[1] == "clean" then clean() return end
        if argv[1] == "prepare" then prepare() return end
        if argv[1] == "build" then build(argv[2]) return end
        if argv[1] == "install" then genimg() install(argv[2]) return end
        if argv[1] == "genimg" then genimg() return end
