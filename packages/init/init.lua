--UberOS init

lua.include("split")

function usage()
  print("Usage: init [runlevel]")
end

function run(level)
  kernel.log("New runlevel: " .. level)
  local f = fs.open("/etc/rc.d/rc" .. level, "r")
  local lst = string.split(f.readAll(), "\n")
  f.close()
  table.sort(lst, function(a, b)
    return tonumber(string.sub(a, 2, 3)) < tonumber(string.sub(b, 2, 3))
  end)
  for k, v in pairs(lst) do
    if string.sub(v, 1, 1) == "R" then
      shell.run("/etc/init.d/" .. string.sub(v, 4, #v) .. " start")
    end
    if string.sub(v, 1, 1) == "S" then
      shell.run("/etc/init.d/" .. string.sub(v, 4, #v) .. " stop")
    end
    if string.sub(v, 1, 1) == "K" then
      shell.run("/etc/init.d/" .. string.sub(v, 4, #v) .. "restart")
    end
  end
  while true do
    kernel.pullEvent()
  end
end

local argv = { ... }
if #argv == 0 then
  run(1)
  kernel.panic("Init done. Running init 0")
  run(0)
  return
elseif argv[1] == "--help" then
  usage()
  kernel.log("Stopping init")
  return
else
  run(argv[1])
end
