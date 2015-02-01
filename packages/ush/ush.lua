--UberSHell
s = ""
local history = {}
local background = false
local x = users.getHome(thread.getUID(coroutine.running()))
shell.setDir(string.sub(x, 2, string.len(x)))
local user = users.getUsernameByUID(thread.getUID(coroutine.running()))
local uid = thread.getUID(coroutine.running())
while s ~= "exit" do
  if s ~= "" then
    s = s:gsub("^%s*(.-)%s*$", "%1")
    if string.match(s, "^:") then --Lua command
      loadstring(string.sub(s, 2, #s))()
    else
      background = false
      if string.match(s, "&$") then
        background = true
        s = string.sub(1, #s - 1)
        s = s:gsub("^%s*(.-)%s*$", "%1")
      end
      local S = string.split(s, "&&")
      for k, v in pairs(S) do
        thread.runFile(v:gsub("^%s*(.-)%s*$", "%1"), nil, not background)
      end
    end
  end
  if uid == 0 then
    write(user .. ":/" .. shell.dir() .. "# ")
  else
    write(user .. ":/" .. shell.dir() .. "$ ")
  end
  s = read(nil, history)
  table.insert(history, s)
end
