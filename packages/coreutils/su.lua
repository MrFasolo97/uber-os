--Substitude user

local argv = { ... }

local username = argv[1] or users.getUsernameByUID(0)
local uid = users.getUIDByUsername(username)

if uid == nil then
  printError("That user does not exist")
  return
end

local sh = argv[2] or users.getShell(uid)

local pwd

if thread.getUID(coroutine.running()) ~= 0 then
  write("Password for " .. username .. ": ")
  pwd = read(" ")
end
os.queueEvent("resume_event")
thread.setUID(nil, uid, pwd)

thread.runFile(sh, nil, true, uid)
