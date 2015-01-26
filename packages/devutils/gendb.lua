--Generate database

local x = fs.list("/usr/src")

local f = fs.open(shell.resolve("repo.db"), "w")
for k, v in pairs(x) do
  f.writeLine(v)
end
f.close()
