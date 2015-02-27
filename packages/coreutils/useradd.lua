--Add new user

local argv = { ... }

if #argv < 3 then
  print("Usage: useradd <name> <home> <shell>")
  return
end

if thread.getUID(coroutine.running()) ~= 0 then error("Access denied!") return end

write("Password: ")
local pwd = read(" ")
write("Confirm password: ")
local cpwd = read(" ")

if pwd ~= cpwd then error("Password do not match!") return end
if #pwd < 6 then error("UNIX password must contain at least 6 symbols") return end

users.newUser(argv[1], pwd, argv[2], argv[3])
