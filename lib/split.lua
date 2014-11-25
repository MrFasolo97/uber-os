function split(s,re)
	local i1 = 1
	local ls = {}
	local append = table.insert
	if not re then re = '%s+' end
		if re == '' then return {s} end
		while true do
			local i2,i3 = s:find(re,i1)
			if not i2 then
				local last = s:sub(i1)
				if last ~= '' then append(ls,last) end
				if #ls == 1 and ls[1] == '' then
					return {}
				else
					return ls
				end
			end
			append(ls,s:sub(i1,i2-1))
			i1 = i3+1
		end
end
-- better split
function string:split(delimiter)
    if type( delimiter ) == "string" then
        local result = { }
        local from = 1
        local delim_from, delim_to = string.find( self, delimiter, from )
        while delim_from do
            table.insert( result, string.sub( self, from , delim_from-1 ) )
            from = delim_to + 1
            delim_from, delim_to = string.find( self, delimiter, from )
        end
        table.insert( result, string.sub( self, from ) )
        return result
    elseif type( delimiter ) == "number" then
        return self:gmatch( (".?"):rep( delimiter ) )
    end
end
