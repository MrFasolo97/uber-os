--Generate database

local x = fs.list("/usr/src")

local f = fs.open(shell.resolve("repo.db"), "w")
for k, v in pairs(x) do
  shell.run("/usr/src/" .. v .. "/PKGINFO.lua")
  f.writeLine(v .. " " .. table.concat(VERSION, ".") .. " " .. table.concat(DEPENDS, "."))
end
f.close()
