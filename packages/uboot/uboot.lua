if not shell.getRunningProgram():match("/") then
    ROOT_DIR = ""
else
    ROOT_DIR = shell.getRunningProgram():match("^/?(.*)/.+$")
end
local bootDirectory = ROOT_DIR .. "/boot"
if bootDirectory:sub(1, 1) ~= "/" then bootDirectory = "/" .. bootDirectory end

local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw
local function boot(str)
    str = fs.combine("", str)
    if str:sub(1, 1) ~= "/" then str = "/" .. str end
    if str:sub(1, #bootDirectory) ~= bootDirectory then
        print("This path is not whitelisted!")
        return false
    end
    local path = ""
    for i = 1, #str do
        if string.sub(str, i, i) ~= " " then
            path = path .. string.sub(str, i, i)
        else
            break
        end
    end
    if not fs.exists(path) or fs.isDir(path) then
        print("Path invalid!")
        return false
    end
    term.clear()
    term.setCursorPos(1, 1)
    os.pullEvent = oldPullEvent
    shell.run(str)
    return true
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print("Uber Bootloader v0.1")
print("Root directory: /" .. ROOT_DIR)
local s = ROOT_DIR .. "/boot/uberkernel mlua musers mfsd macpi log root=" .. ROOT_DIR
if s:sub(1, 1) ~= "/" then s = "/" .. s end
print("Default = " .. s)
print("")
local tmp = ""
local history = {s}
while true do
    write("boot: ")
    tmp = read(nil, history)
    table.insert(history, tmp)
    if tmp == "" then
        print("Booting default ...")
        if boot(s) then return end
    else
        if boot(tmp) then return end
    end
end
