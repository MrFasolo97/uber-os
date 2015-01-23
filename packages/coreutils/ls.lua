local argv = { ... }
local dir = shell.dir()
local args = {}
if #argv > 0 then
  if argv[1]:sub(1,1) == "-" then
    args = argv[1]
  else
    dir = argv[1]
  end
  if #argv == 2 then
    dir = argv[2]
  end
end
local allFiles = false
local more = false
for i = 2, #args do
  if args:sub(i, i) == "a" then
    allFiles = true
  end
  if args:sub(i, i) == "l" then
    more = true
  end
end
dir = fs.normalizePath(dir)
print("Listing of dir=" .. dir)
files = fs.list(dir)
local maxlen = 0
local tmp
for i = 1, #files do
  tmp = string.len(files[i])
  if tmp > maxlen then
    maxlen = tmp
  end
end
local isDir = "-"
for i = 1, #files do
  if (files[i]:sub(1, 1) ~= ".") or allFiles then
    if fs.isDir(dir .. "/" .. files[i]) then
      if term.isColor() then
        term.setTextColor(colors.green)
      end
      isDir = "d"
    end
    if more then
      write(files[i])
      for j = string.len(files[i]), maxlen do
        write(" ")
      end
      print(" ", isDir, table.concat(fsd.normalizePerms(fsd.getInfo(dir .. "/" .. files[i]).perms), ""), " ", 
          users.getUsernameByUID(fsd.getInfo(dir .. "/" .. files[i]).owner))
    else
      write(files[i] .. " ")
    end
    if term.isColor() then
      term.setTextColor(colors.white)
      isDir = "-"
    end
  end
end
if not more then
  print()
end
