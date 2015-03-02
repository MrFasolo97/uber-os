local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw
local function boot(str)
  local path = ""
  for i = 1, #str do
    if string.sub(str, i, i) ~= " " then
      path = path .. string.sub(str, i, i)
    else
      break
    end
  end
  if not fs.exists(path) or fs.isDir(path) then
    print("Path invalid!")
    return false
  end
  term.clear()
  term.setCursorPos(1, 1)
  os.pullEvent = oldPullEvent
  shell.run(str)
  return true
end

term.clear()
term.setCursorPos(1, 1)
print("Uber Bootloader v0.1")
ROOT_DIR = fs.getDir(shell.getRunningProgram())
print("Root directory: /" .. ROOT_DIR)
local s = ROOT_DIR .. "/boot/uberkernel mlua musers mfsd macpi log root=" .. ROOT_DIR
if s:sub(1, 1) ~= "/" then s = "/" .. s end
print("Default = " .. s)
print("")
local tmp = ""
local history = {s}
while true do
  write("boot: ")
  tmp = read(nil, history)
  table.insert(history, tmp)
  if tmp == "" then
    print("Booting default ...")
    if boot(s) then return end
  else
    if boot(tmp) then return end
  end
end
