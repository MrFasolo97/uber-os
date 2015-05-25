--Add new user

local argv = { ... }

if #argv < 4 then
    print("Usage: useradd <name> <group> <home> <shell>")
    return
end

if thread.getUID(coroutine.running()) ~= 0 then printError("Access denied") return end

write("Password: ")
local pwd = read(" ")
write("Confirm password: ")
local cpwd = read(" ")

if pwd ~= cpwd then printError("Password do not match!") return end
if #pwd < 6 then printError("UNIX password must contain at least 6 symbols") return end

users.newUser(argv[1], users.getGIDByName(argv[2]), pwd, argv[3], argv[4])
