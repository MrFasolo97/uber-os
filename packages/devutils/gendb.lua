--Generate database

local x = fs.list("/usr/src")

local f = fs.open(shell.resolve("repo.db"), "w")
for k, v in pairs(x) do
  shell.run("/usr/src/" .. v .. "/PKGINFO.lua")
  f.writeLine(v .. " " .. VERSION .. " " .. table.concat(DEPENDS, ";"))
end
f.writeLine("//DIRLIST")
for k, v in pairs(fsd.recursList("/usr/src")) do
  if fs.isDir(v) then
    f.write("D")
  else
    f.write("F")
  end
  f.writeLine(fsd.stripPath("/usr/src", v))
end
f.close()
