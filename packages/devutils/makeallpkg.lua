--Make all packages, available in /usr/src

local x = fs.list("/usr/src")
for k, v in pairs(x) do
  shell.run("makepkg " .. v)
end
