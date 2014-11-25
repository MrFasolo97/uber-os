argv = { ... }
if #argv == 0 then
  print("Usage: kill <PID> [TERM|KILL]")
  return
end

local x, y

if #argv == 1 then
  y = "KILL"
else
  y = argv[2]
end

if y == "KILL" then
  x = 2
end
if y == "TERM" then
  x = 1
end

thread.kill(tonumber(argv[1]), x)
