argv = { ... }
if #argv == 0 then
  print("Usage: kill <PID> [SIG]")
  return
end
local y
if #argv == 1 then
  y = "TERM"
else
  y = argv[2]
end

thread.kill(tonumber(argv[1]), y)
