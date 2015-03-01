--UberSHell
local parentShell = shell
local parentTerm = term.current()

local bExit = false
local sDir = (parentShell and parentShell.dir()) or ""
local sPath = (parentShell and parentShell.path()) or ".:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
local tAliases = (parentShell and parentShell.aliases()) or {}
local tProgramStack = {}

local shell = {}
local tEnv = {
	[ "shell" ] = shell
}

-- Colours
local textColour, bgColour
if term.isColour() then
	textColour = colours.white
	bgColour = colours.black
else
	textColour = colours.white
	bgColour = colours.black
end

local function run( _sCommand, ... )
	local sPath = shell.resolveProgram( _sCommand )
	if sPath ~= nil then
		tProgramStack[#tProgramStack + 1] = sPath
    local result = os.run( tEnv, sPath, ... )
		tProgramStack[#tProgramStack] = nil
		return result
   	else
    	printError( "No such program" )
    	return false
    end
end

local function tokenise( ... )
    local sLine = table.concat( { ... }, " " )
	local tWords = {}
    local bQuoted = false
    for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
        if bQuoted then
            table.insert( tWords, match )
        else
            for m in string.gmatch( match, "[^ \t]+" ) do
                table.insert( tWords, m )
            end
        end
        bQuoted = not bQuoted
    end
    return tWords
end

-- Install shell API
function shell.run( ... )
	local tWords = tokenise( ... )
	local sCommand = tWords[1]
	if sCommand then
		return run( sCommand, unpack( tWords, 2 ) )
	end
	return false
end

function shell.exit()
    bExit = true
end

function shell.dir()
	return sDir
end

function shell.setDir( _sDir )
	sDir = _sDir
end

function shell.path()
	return sPath
end

function shell.setPath( _sPath )
	sPath = _sPath
end

function shell.resolve( _sPath )
	local sStartChar = string.sub( _sPath, 1, 1 )
	if sStartChar == "/" or sStartChar == "\\" then
		return fs.combine( "", _sPath )
	else
		return fs.combine( sDir, _sPath )
	end
end

function shell.resolveProgram( _sCommand )
	-- Substitute aliases firsts
	if tAliases[ _sCommand ] ~= nil then
		_sCommand = tAliases[ _sCommand ]
	end

    -- If the path is a global path, use it directly
    local sStartChar = string.sub( _sCommand, 1, 1 )
    if sStartChar == "/" or sStartChar == "\\" then
    	local sPath = fs.combine( "", _sCommand )
    	if fs.exists( sPath ) and not fs.isDir( sPath ) then
			return sPath
    	end
		return nil
    end
    
 	-- Otherwise, look on the path variable
    for sPath in string.gmatch(sPath, "[^:]+") do
    	sPath = fs.combine( shell.resolve( sPath ), _sCommand )
    	if fs.exists( sPath ) and not fs.isDir( sPath ) then
			return sPath
    	end
    end
	
	-- Not found
	return nil
end

function shell.programs( _bIncludeHidden )
	local tItems = {}
	
	-- Add programs from the path
    for sPath in string.gmatch(sPath, "[^:]+") do
    	sPath = shell.resolve( sPath )
		if fs.isDir( sPath ) then
			local tList = fs.list( sPath )
			for n,sFile in pairs( tList ) do
				if not fs.isDir( fs.combine( sPath, sFile ) ) and
				   (_bIncludeHidden or string.sub( sFile, 1, 1 ) ~= ".") then
					tItems[ sFile ] = true
				end
			end
		end
    end	

	-- Sort and return
	local tItemList = {}
	for sItem, b in pairs( tItems ) do
		table.insert( tItemList, sItem )
	end
	table.sort( tItemList )
	return tItemList
end

function shell.getRunningProgram()
	if #tProgramStack > 0 then
		return tProgramStack[#tProgramStack]
	end
	return nil
end

function shell.setAlias( _sCommand, _sProgram )
	tAliases[ _sCommand ] = _sProgram
end

function shell.clearAlias( _sCommand )
	tAliases[ _sCommand ] = nil
end

function shell.aliases()
	-- Add aliases
	local tCopy = {}
	for sAlias, sCommand in pairs( tAliases ) do
		tCopy[sAlias] = sCommand
	end
	return tCopy
end

term.setBackgroundColor( bgColour )
term.setTextColour( textColour )

local uid = thread.getUID(coroutine.running())
local user = users.getUsernameByUID(uid)

shell.setDir(users.getHome(uid))

local promptSymbol = "$"

if uid == 0 then promptSymbol = "#" end

-- Read commands and execute them
local tCommandHistory = {}
while not bExit do
    term.redirect( parentTerm )
    term.setBackgroundColor( bgColour )
    write(user .. ":" .. fsd.normalizePath(shell.dir()) .. promptSymbol .. " ")
    term.setTextColour( textColour )

    local sLine = read( nil, tCommandHistory )
    if #sLine > 0 then
      table.insert( tCommandHistory, sLine )
    end
    shell.run( sLine )
end
