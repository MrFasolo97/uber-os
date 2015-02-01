--Change user password

local argv = { ... }

local uid = thread.getUID(coroutine.running())

if argv[1] then uid = users.getUIDByUsername(argv[1]) end

write("Current password: ") local password = read()

if not users.login(users.getUsernameByUID(uid), password) then error("Password incorrect!") return end

write("New Password: ")
local pwd = read(" ")
write("Confirm password: ")
local cpwd = read(" ")

if pwd ~= cpwd then error("Password do not match!") return end
if #pwd < 6 then error("UNIX password must contain at least 6 symbols") return end

users.modifyUser(uid, nil, pwd, nil, nil)
