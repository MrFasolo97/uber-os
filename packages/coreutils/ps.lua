local t = thread.getRunningThreads()
local x = {}

for k, v in pairs(t) do
  table.insert(x, {
    math.floor(v.pid), v.desc, users.getUsernameByUID(v.uid)
  })
end

textutils.tabulate({"PID", "CMD", "USER"}, unpack(x))
