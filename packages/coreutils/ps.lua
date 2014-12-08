local t = thread.getRunningThreads()
local toout = {}
local maxlen = {0, 0, 0}
for i = 1, #t do
  toout[#toout + 1] = {tostring(t[i].pid), t[i].desc, users.getUsernameByUID(t[i].uid)}
  if string.len(tostring(t[i].pid)) > maxlen[1] then
    maxlen[1] = string.len(tostring(t[i].pid))
  end
  if string.len(t[i].desc) > maxlen[2] then
    maxlen[2] = string.len(t[i].desc)
  end
  if string.len(users.getUsernameByUID(t[i].uid)) > maxlen[3] then
    maxlen[3] = string.len(users.getUsernameByUID(t[i].uid))
  end
end

for i = 1, math.floor((maxlen[1] - 3) / 2) do
  write(" ")
end
write("PID")
for i = 1, math.ceil((maxlen[1] - 1) / 2) + math.floor((maxlen[2] - 2) / 2) do
  write(" ")
end
write("DESC")
for i = 1, math.ceil((maxlen[2] - 2) / 2) + math.floor((maxlen[3] - 2) / 2) do
  write(" ")
end
write("USER\n")
for i = 1, maxlen[1] + maxlen[2] + maxlen[3] + 4 do
  write("-")
end
write("\n")


for i = 1, #toout do
  write(toout[i][1])
  for j = string.len(toout[i][1]), maxlen[1] do
    write(" ")
  end
  write(" ")
  write(toout[i][2])
  for j = string.len(toout[i][2]), maxlen[2] do
    write(" ")
  end
  write(" ")
  write(toout[i][3])
  print("")
end
