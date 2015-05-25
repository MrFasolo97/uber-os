local _UID = 0
local passwd = {}
local groups = {}

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

function users.getUserGroup(uid)
    for k, v in pairs(passwd) do
        if v.uid == uid then
            return v.gid or -1
        end
    end
    return -1
end

function users.getUserGroups(uid)
    local r = {}
    for k, v in pairs(groups) do
        for i, j in pairs(v.uids) do
            if j == uid then
                table.insert(r, v.gid)
            end
        end
    end
    return r
end

function users.isUserInGroup(uid, gid)
    if users.getUserGroup(uid) == gid then
        return true
    end
    local ug = users.getUserGroups(uid)
    for k, v in pairs(ug) do
        if v == gid then
            return true
        end
    end
    return false
end

function users.getGIDByName(name)
    for k, v in pairs(groups) do
        if v.name == name then
            return v.gid
        end
    end
    return -1
end

function users.getNameByGID(gid)
    for k, v in pairs(groups) do
        if v.gid == gid then
            return v.name
        end
    end
    return "nobody"
end

local function loadPasswd()
    if not fs.exists(ROOT_DIR .. "/etc/passwd") and not fs.exists("/etc/passwd") then
        kernel.panic("/etc/passwd not found!")
        return
    end
    if not fs.exists(ROOT_DIR .. "/etc/group") and not fs.exists("/etc/group") then
        kernel.panic("/etc/group not found!")
        return
    end
    local root
    if fs.exists("/etc/passwd") then root = "" else root = ROOT_DIR end
    local passwdFile = fs.open(root .. "/etc/passwd", "r")
    local user = passwdFile.readLine()
    local tmp
    passwd = {}
    while user do
        tmp = string.split(user, ":")
        passwd[#passwd + 1] = {
            name = tmp[1],
            pwd = tmp[2],
            home = tmp[6],
            shell = tmp[7],
            uid = tonumber(tmp[3]),
            gid = tonumber(tmp[4])
        }
        user = passwdFile.readLine()
    end
    passwdFile.close()
    groups = {}
    local groupFile = fs.open(root .. "/etc/group", "r")
    local group = groupFile.readLine()
    while group do
        tmp = string.split(group, ":")
        groups[#groups + 1] = {
            name = tmp[1],
            gid = tonumber(tmp[3]),
            userNames = tmp[4],
            uids = {}
        }
        tmp = string.split(groups[#groups].userNames, ",")
        for k, v in pairs(tmp) do
            table.insert(groups[#groups].uids, users.getUIDByUsername(v))
        end
        group = groupFile.readLine()
    end
    groupFile.close()
end

local function writePasswd()
    local root
    if thread then root = "" else root = ROOT_DIR end
    local passwdFile = fs.open(root .. "/etc/passwd", "w")
    for k, v in pairs(passwd) do
        passwdFile.writeLine(v.name .. ":" .. v.pwd .. ":" .. tostring(v.uid) .. ":" .. tostring(v.gid) .. "::" .. v.home .. ":" .. v.shell)
    end
    passwdFile.close()

    local groupFile = fs.open(root .. "/etc/group", "w")
    for k, v in pairs(groups) do
        groupFile.writeLine(v.name .. ":x:" .. tostring(v.gid) .. ":" .. v.userNames)
    end
    groupFile.close()
end

function users.newUser(name, gid, pwd, home, shell)
    if thread and thread.getUID(coroutine.running()) ~= 0 then
        printError("Only root can create users!")
        return false
    end
    if not(name and gid and pwd and home and shell) then
        return false
    end
    local uid = 1000
    for k, v in pairs(passwd) do
        if uid <= v.uid then uid = v.uid + 1 end
    end
    passwd[#passwd + 1] = {
        name = name,
        pwd = pwd,
        uid = uid,
        gid = gid,
        home = home,
        shell = shell
    }
    writePasswd()
    return uid
end

function users.newGroup(name)
    if thread and thread.getUID(coroutine.running()) ~= 0 then
        printError("Only root can create users!")
        return false
    end
    if not name then
        return false
    end
    local gid = 100
    for k, v in pairs(groups) do
        if gid <= v.gid then gid = v.gid + 1 end
    end
    table.insert(groups, {
        name = name,
        gid = gid,
        uids = {},
        userNames = ""
    })
    writePasswd()
    return gid
end

function users.deleteGroup(gid)
    if thread and thread.getUID(coroutine.running()) ~= 0 then
        printError("Only root can delete groups!")
        return false
    end
    if not gid then
        return false
    end
    for k, v in pairs(groups) do
        if gid == v.gid then
            table.remove(groups, k)
            return true
        end
    end
    writePasswd()
    return false
end

function users.modifyUser(uid, _name, _gid,  _pwd, _home, _shell)
    if thread and thread.getUID(coroutine.running()) ~= 0 and
        thread.getUID(coroutine.running()) ~= uid then
        printError("Only root or target user can modify users!")
        return false
    end
    for k, v in pairs(passwd) do
        if v.uid == uid then
            v.name = _name or v.name
            v.pwd = _pwd or v.pwd
            v.home = _home or v.home
            v.shell = _shell or v.shell
            v.gid = _gid or v.gid
            break
        end
    end
    writePasswd()
    return true
end

function users.addToGroup(uid, gid)
    for k, v in pairs(groups) do
        if v.gid == gid then
            table.insert(v.uids, uid)
            v.userNames = ""
            for i, j in pairs(v.uids) do
                if v.userNames ~= "" then
                    v.userNames = v.userNames .. ","
                end
                v.userNames = v.userNames .. users.getUsernameByUID(j)
            end
        end
    end
    writePasswd()
end

function users.removeFromGroup(uid, gid)
    for k, v in pairs(groups) do
        if v.gid == gid then
            for i, j in pairs(v.uids) do
                if j == uid then
                    table.remove(v.uids, i)
                end
                break
            end
            v.userNames = ""
            for i, j in pairs(v.uids) do
                if v.userNames ~= "" then
                    v.userNames = v.userNames .. ","
                end
                v.userNames = v.userNames .. users.getUsernameByUID(j)
            end
        end
    end
    writePasswd()
end

function users.deleteUser(uid)
    if thread and thread.getUID(coroutine.running()) ~= 0 then
        printError("Only root can delete users!")
        return false
    end
    for k, v in pairs(passwd) do
        if v.uid == uid then
            table.remove(passwd, k)
            break
        end
    end
    writePasswd()
    return true
end

loadPasswd()

users = applyreadonly(users) _G["users"] = users

