local argv = { ... }
local f = fs.open("/etc/issue", "r")
local issue = f.readAll()
f.close()
f = fs.open("/etc/motd", "r")
local motd = f.readAll()
f.close()
while true do
  write(issue)
  write("Username: ")
  local username = read()
  write("Password: ")
  local password = read("")
  if users.login(username, password) then
    kernel.log("Logging in as " .. username)
    write(motd)
    thread.runFile(users.getShell(users.getUIDByUsername(username)),
        nil, true, users.getUIDByUsername(username))
  else
    print("Invalid login\n")
    sleep(3)
  end
  term.clear()
  term.setCursorPos(1, 1)
end
