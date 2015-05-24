--U Graphics Server

assert(term and window)

term.redirect(term.native())

local tw, th = term.getSize()

local e, e1, e2, e3, e4, e5

while true do
    e, e1, e2, e3, e4, e5 = os.pullEvent()
    if e == "key" and keys.getName(e1) == "f10" then
        break
    end
end
