--Add new user

local argv = { ... }

if #argv < 1 then
    print("Usage: groupdel <name>")
    return
end

if thread.getUID(coroutine.running()) ~= 0 then printError("Access denied") return end

users.deleteGroup(users.getGIDByName(argv[1]))
