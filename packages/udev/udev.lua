--Uber Device Manager
thread.registerSignal("INT", function() end)
udev = {}

kernel.log("[udev] Starting udev")

local devices = {}
devices["hdd"] = "HDD"
devices["null"] = "NULL"

local deviceMnemonics = {
    ["modem"] = "net",
    ["computer"] = "cmp",
    ["turtle"] = "cmp",
    ["drive"] = "fdd",
    ["monitor"] = "trm",
    ["printer"] = "prn"
}

function udev.getMnemonics()
    local result = {}
    for k, v in pairs(devices) do
        table.insert(result, k)
    end
    return result
end

function udev.readDevice(dev)
    local side=devices[dev]
    if dev == "hdd" then
        return textutils.serialize({
            type = "DISK",
            mounted = "/"
        })
    elseif dev == "null" then return ""
    elseif string.sub(dev,1,3) == "fdd" then
        return textutils.serialize({
        type = "DISK",
        mounted = disk.getMountPath(side),
        side = side})
    elseif string.sub(dev,1,3) == "cmp" then 
        return textutils.serialize({
        side = side,
        id = peripheral.call(side,"getID")
    })
    elseif string.sub(dev,1,3) == "net" then
        return textutils.serialize({
        side = side,
        isWireless = peripheral.call(side,"isWireless")
    })
    elseif string.sub(dev,1,3) == "trm" then
        local cX, cY = peripheral.call(side,"getCursorPos")
        local sX, sY = peripheral.call(side,"getSize")
        return textutils.serialize({
        side = side,
        cursorPosX = cX,
        cursorPosY = cY,
        isColor = peripheral.call(side,"isColor"),
        sizeX = sX,
        sizeY = sY
    })
    elseif string.sub(dev,1,3) == "prn" then
        local cX, cY = peripheral.call(side,"getCursorPos")
        local pX, pY = peripheral.call(side,"getPageSize")
        return textutils.serialize({
        side = side,
        cursorPosX = cX,
        cursorPosY = cY,
        pageWidth = pX,
        pageHeight = pY,
        paperLevel = peripheral.call(side,"paperLevel"),
        inkLevel = peripheral.call(side,"inkLevel")})
    else
        return textutils.serialize({side = side})
    end
end

function udev.onWrite(dev, str)
    local side = devices[dev]
    if dev ~= "hdd" and dev ~= "null" then
        local args = string.split(str,"\n")
        for i = 2, #args do
            if args[i]:sub(1, 1) == "n" then
                args[i] = tonumber(args[i]:sub(2))
            elseif args[i]:sub(1, 1) == "t" then 
                args[i] = textutils.unserialize(args[i]:sub(2))
            elseif args[i]:sub(1,1) == "s" then
                args[i] = args[i]:sub(2)
            elseif args[i]:sub(1,1) == "b" then
                args[i] = args[i]:sub(2) == "true"
            end
        end
    return peripheral.call(side,unpack(args))
    end
end


local function updatePeripherals()
    kernel.log("[udev] Updating peripherals")
    devices = {}
    devices["hdd"] = "HDD"
    devices["null"] = "NULL"
    local peripherals = peripheral.getNames()
    for k, v in pairs(peripherals) do
        local i = 0
        local ptype = peripheral.getType(v)
        while devices[deviceMnemonics[ptype] .. tostring(i)] do
            i = i + 1
        end
        devices[deviceMnemonics[ptype] .. tostring(i)] = v
    end
end

udev = applyreadonly(udev) _G["udev"] = udev

if not fsd.getMounts()["/dev"] then
    kernel.log("[udev] Mounting devfs")
    fsd.mount("devfs", "devfs", "/dev")
end

updatePeripherals()
while true do
    local e = os.pullEvent()
    if e:sub(1, 10) == "peripheral" then
        updatePeripherals()
    end
end
