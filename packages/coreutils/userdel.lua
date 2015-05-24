--Delete user

local argv = { ... }

if #argv < 1 then
    print("Usage: userdel <name>")
    return
end

users.deleteUser(users.getUIDByUsername(argv[1]))
