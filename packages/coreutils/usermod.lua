--Modify user

local argv = { ... }

if #argv < 3 then
  error("Usage: usermod <name> name|home|shell <value>")
  return
end

local uid = users.getUIDByUsername(argv[1])

if argv[2] == "name" then users.modifyUser(uid, argv[3], nil, nil, nil) end
if argv[2] == "home" then users.modifyUser(uid, nil, nil, argv[3], nil) end
if argv[2] == "shell" then users.modifyUser(uid, nil, nil, nil, argv[3]) end
