local t = thread.getRunningThreads()
local x = {}

for k, v in pairs(t) do
    if v.pid == 1 then
        table.insert(x, {
            tostring(math.floor(v.pid)), v.desc, users.getUsernameByUID(v.uid), "-"
        })
    else
        table.insert(x, {
            tostring(math.floor(v.pid)), v.desc, users.getUsernameByUID(v.uid), tostring(math.floor(v.ppid))
        })
    end
end

textutils.tabulate({"PID", "CMD", "USER", "PPID"}, unpack(x))
