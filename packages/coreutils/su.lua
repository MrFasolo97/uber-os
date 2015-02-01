--Substitude user

local argv = { ... }

local username = argv[1] or users.getUsernameByUID(0)
local uid = users.getUIDByUsername(username)

local sh = argv[2] or users.getShell(uid)

write("Password for " .. username .. ": ")
local pwd = read(" ")
thread.setUID(nil, uid, pwd)

thread.runFile(sh, nil, true, uid)
