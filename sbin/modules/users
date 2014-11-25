local _UID = 0
local passwd = {}
lua.include("split")

users = {}
function users.getActiveUID()
  return thread.getUID(coroutine.running())
end

function users.getUsernameByUID(uid)
  for i = 1, #passwd do
    if passwd[i].uid == uid then
      return passwd[i].name
    end
  end
  return nil
end

function users.getUIDByUsername(name)
  for i = 1, #passwd do
    if passwd[i].name == name then
      return passwd[i].uid
    end
  end
  return nil
end

function users.getShell(uid)
  for i = 1, #passwd do
    if passwd[i].uid == uid then
      return passwd[i].shell
    end
  end
  return "/bin/ush"
end

function users.getHome(uid)
  for i = 1, #passwd do
    if passwd[i].uid == uid then
      return passwd[i].home
    end
  end
  return "/bin/ush"
end

function users.login(name, pwd)
  for i = 1, #passwd do
    if (passwd[i].name == name) and
    (passwd[i].pwd == pwd) then
      return true
    end
  end
  return false
end


local function updatePasswd()
  if not fs.exists("/etc/passwd") then
    kernel.panic("/etc/passwd not found!")
  end
  passwdFile = fs.open("/etc/passwd", "r")
  local user = passwdFile.readLine()
  local tmp
  while user do
    tmp = string.split(user, ":")
    passwd[#passwd + 1] = {
      name = tmp[1],
      pwd = tmp[2],
      home = tmp[6],
      shell = tmp[7],
      uid = tonumber(tmp[3])
    }
    user = passwdFile.readLine()
  end
  passwdFile.close()
end

updatePasswd()

users = applyreadonly(users)

