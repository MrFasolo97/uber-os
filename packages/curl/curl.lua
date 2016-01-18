local tArgs = { ... }
if #tArgs < 1 then
    print("Usage: curl <url>")
    return
end

local url = tArgs[1]
local r = http.get(url)
if not r then
    printError("Cannot get file!")
    return
end

write(r.readAll())
r.close()
