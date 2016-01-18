--U Graphics Server

assert(term and window)

local ccute = lua.include("libccute") 

local app = ccute.Application()

local appListLayout = ccute.HorizontalLayout(app)

appListLayout.height = 1
appListLayout.margin =0 

for i = 1, 3 do
    local g = ccute.HorizontalLayout(app)
    g.margin = 0
    g.height = 1
    local x = ccute.Button(app, "x")
    x.color = colors.lightGray
    x.pressedColor = colors.red
    x.textColor = colors.red
    x.pressedTextColor = colors.black
    g:addChild(x)
    local b = ccute.Button(app, "App #" .. i)
    b.color = colors.lightGray
    b.pressedColor = colors.gray
    b.layoutWeight = 100
    g:addChild(b)
    appListLayout:addChild(g)
end

app:attachWidget(appListLayout)

app:run()
