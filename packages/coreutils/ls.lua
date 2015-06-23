local argv = { ... }
local outf = thread.status(thread.getPID(coroutine.running())).stdout
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
local files
dir = fs.normalizePath(dir)
files = fs.list(dir)
if not files then return end
local maxlen = 0
local tmp
for i = 1, #files do
    tmp = string.len(files[i])
    if tmp > maxlen then
        maxlen = tmp
    end
end
local isDir = "-"
local isLink = ""
local flag = false
if not more then
    local tFiles = {}
    local tDirs = {}
    local tLinks = {}

    for n, sItem in pairs(files) do
        if string.sub(sItem, 1, 1) ~= "." or allFiles then
            local sPath = fs.combine(dir, sItem)
            if fs.getInfo(sPath).linkto then
                table.insert(tLinks, sItem)
            else
                if fs.isDir(sPath) then
                    table.insert(tDirs, sItem)
                else
                    table.insert(tFiles, sItem)
                end
            end
        end
    end
    table.sort(tDirs)
    table.sort(tFiles)
    table.sort(tLinks)

    if term.isColour() then
        textutils.pagedTabulate(colors.blue, tDirs, colors.white, tFiles, colors.cyan, tLinks)
        term.setTextColor(colors.white)
    else
        textutils.pagedTabulate(tDirs, tFiles, tLinks)
    end
else
    for i = 1, #files do
        local size = " " .. fs.getSize(dir .. "/" .. files[i]) .. " "
        if (files[i]:sub(1, 1) ~= ".") or allFiles then
            flag = true
            if fs.isDir(dir .. "/" .. files[i]) then
                if term.isColor() and outf.isStdout then
                    term.setTextColor(colors.blue)
                end
                isDir = "d"
                size = ""
            end
            if fs.getInfo(dir .. "/" .. files[i]).linkto then
                if term.isColor() and outf.isStdout then
                    term.setTextColor(colors.cyan)
                end
            end
            write(files[i])
            for j = string.len(files[i]), maxlen do
                write(" ")
            end
            if fs.getInfo(dir .. "/" .. files[i]).linkto then
                isLink = " -> " .. fs.getInfo(dir .. "/" .. files[i]).linkto
                isDir = "l"
            else
                isLink = ""
            end
            print(isDir, table.concat(fsd.normalizePerms(fsd.getInfo(dir .. "/" .. files[i]).perms), ""), " ", 
            users.getUsernameByUID(fsd.getInfo(dir .. "/" .. files[i]).owner), " ", users.getNameByGID(fsd.getInfo("/" .. files[i]).gid), size, isLink)
            if term.isColor() and outf.isStdout then
                term.setTextColor(colors.white)
            end
            isDir = "-"
            isLink = ""
        end
    end
end
