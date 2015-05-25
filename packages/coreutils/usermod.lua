--Modify user

local argv = { ... }

if #argv < 3 then
    print("Usage: usermod <username> name|home|shell|group|addgroup|delgroup <value>")
    return
end

local uid = users.getUIDByUsername(argv[1])

if argv[2] == "name" then users.modifyUser(uid, argv[3], nil, nil, nil, nil) end
if argv[2] == "home" then users.modifyUser(uid, nil, nil, nil, argv[3], nil) end
if argv[2] == "shell" then users.modifyUser(uid, nil, nil, nil, nil, argv[3]) end
if argv[2] == "group" then users.modifyUser(uid, nil, users.getGIDByName(argv[3]), nil, nil, nil) end
if argv[2] == "addgroup" then users.addToGroup(uid, users.getGIDByName(argv[3])) end
if argv[2] == "delgroup" then users.removeFromGroup(uid, users.getGIDByName(argv[3])) end
