--Uber Device Manager

udev = {}

local devices = {}
devices["hdd"] = "HDD"

local deviceMnemonics = {
  ["modem"] = "net",
  ["computer"] = "cmp",
  ["turtle"] = "trt",
  ["drive"] = "fdd",
  ["monitor"] = "disp",
  ["printer"] = "prn"}

function udev.getMnemonics()
  local result = {}
  for k, v in pairs(devices) do
    table.insert(result, k)
  end
  return result
end

function udev.readDevice(dev)
  local tmp = devices[dev]
  if dev == "hdd" then
    return textutils.serialize({type = "DISK", mounted = "/"})
  end
  if string.sub(dev, 1, 3) == "fdd" then
    return textutils.serialize({type = "DISK",
      mounted = disk.getMountPath(tmp)
    })
  end
end

local function updatePeripherals()
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

udev = applyreadonly(udev)

updatePeripherals()
while true do
  local e = os.pullEvent()
  if e:sub(1, 10) == "peripheral" then
    updatePeripherals()
  end
end
