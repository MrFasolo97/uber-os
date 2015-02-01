--Delete user

local argv = { ... }

if #argv < 1 then
  error("Usage: userdel <name>")
  return
end

users.deleteUser(users.getUIDByUsername(argv[1]))
