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

local function loadPasswd()
  if not fs.exists(ROOT_DIR .. "/etc/passwd") and not fs.exists("/etc/passwd") then
    kernel.panic("/etc/passwd not found!")
  end
  local root
  if fs.exists("/etc/passwd") then root = "" else root = ROOT_DIR end
  local passwdFile = fs.open(root .. "/etc/passwd", "r")
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

local function writePasswd()
  local root
  if thread then root = "" else root = ROOT_DIR end
  local passwdFile = fs.open(root .. "/etc/passwd", "w")
  for k, v in pairs(passwd) do
    passwdFile.writeLine(v.name .. ":" .. v.pwd .. ":" .. tostring(v.uid) .. ":::" .. v.home .. ":" .. v.shell)
  end
  passwdFile.close()
end

function users.newUser(name, pwd, home, shell)
  if thread.getUID(coroutine.running()) ~= 0 then
    printError("Only root can create users!")
    return 
  end
  local uid = 1000
  for k, v in pairs(passwd) do
    if uid <= v.uid then uid = v.uid + 1 end
  end
  passwd[#passwd + 1] = {
    name = name,
    pwd = pwd,
    uid = uid,
    home = home,
    shell = shell
  }
  writePasswd()
end

function users.modifyUser(uid, _name, _pwd, _home, _shell)
  if thread.getUID(coroutine.running()) ~= 0 and
    thread.getUID(coroutine.running()) ~= uid then
    printError("Only root or target user can modify users!")
    return
  end
  for k, v in pairs(passwd) do
    if v.uid == uid then
      v.name = _name or v.name
      v.pwd = _pwd or v.pwd
      v.home = _home or v.home
      v.shell = _shell or v.shell
      break
    end
  end
  writePasswd()
end

function users.deleteUser(uid)
  if thread.getUID(coroutine.running()) ~= 0 then
    printError("Only root can delete users!")
    return
  end
  for k, v in pairs(passwd) do
    if v.uid == uid then
      table.remove(passwd, k)
      break
    end
  end
  writePasswd()
end

loadPasswd()

users = applyreadonly(users) _G["users"] = users

