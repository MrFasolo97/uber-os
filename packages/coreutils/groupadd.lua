--Add new user

local argv = { ... }

if #argv < 1 then
    print("Usage: groupadd <name>")
    return
end

if thread.getUID(coroutine.running()) ~= 0 then printError("Access denied") return end

print("GID=" .. tostring(users.newGroup(argv[1])))

