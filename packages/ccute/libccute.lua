--Ccute GUI Framework
--Written by TsarN

local ccute
ccute = {}

ccute.ToggleAnimation = {}
ccute.ToggleAnimation.__index = ccute.ToggleAnimation

setmetatable(ccute.ToggleAnimation, {
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function ccute.ToggleAnimation._init(self)
    self.totalTime = 0
    self.timePassed = 0
    self.show = true
    self.over = false
end

function ccute.ToggleAnimation.mask(self, x, y)
    return show
end

function ccute.ToggleAnimation.tick(self, time)
    if self.timePassed < self.totalTime then
        self.timePassed = self.timePassed + (time or 0.05)
    else
        self.over = true
    end
end


ccute.RoundToggleAnimation = {}
ccute.RoundToggleAnimation.__index = ccute.RoundToggleAnimation

setmetatable(ccute.RoundToggleAnimation, {
    __index = ccute.ToggleAnimation,
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function ccute.RoundToggleAnimation._init(self)
    ccute.ToggleAnimation._init(self)
    self.xstart = 1
    self.ystart = 1
    self.speed = 10
end

function ccute.RoundToggleAnimation.mask(self, x, y)
    if self.timePassed >= self.totalTime then
        return self.show
    end
    if self.show then
        return math.sqrt(math.pow((x - self.xstart) * 2 / 3, 2) + math.pow(y - self.ystart, 2)) <= self.speed * self.timePassed
    else
        return math.sqrt(math.pow((x - self.xstart) * 2 / 3, 2) + math.pow(y - self.ystart, 2)) > self.speed * self.timePassed
    end
end

ccute.Surface = {}
ccute.Surface.__index = ccute.Surface

setmetatable(ccute.Surface, {
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function ccute.Surface._init(self, width, height)
    self.width = width or 1
    self.height = height or 1
    self:createSurface()
end

function ccute.Surface.resize(self, width, height)
    self.width = width or self.width
    self.height = height or self.height
    self:resizeSurface()
end

function ccute.Surface.createSurface(self)
    self.surface = {}
    for i = 1, self.width do
        self.surface[i] = {}
        for j = 1, self.height do
            self.surface[i][j] = {textColor = colors.gray, backgroundColor = colors.gray, text = ""}
        end
    end
end

function ccute.Surface.resizeSurface(self)
    self.surface = self.surface or {}
    self.lastSurface = nil
    for i = 1, self.width do
        self.surface[i] = self.surface[i] or {}
        for j = 1, self.height do
            self.surface[i][j] = self.surface[i][j] or {textColor = colors.gray, backgroundColor = colors.gray, text = ""}
        end
    end
    for i = self.width + 1, #self.surface do
        table.remove(self.surface)
    end
end

function ccute.Surface.drawPixel(self, x, y, textColor, backgroundColor, text)
    self.surface[x][y] = {
        textColor = textColor or self.surface[x][y].textColor,
        backgroundColor = backgroundColor or self.surface[x][y].backgroundColor,
        text = text or self.surface[x][y].color
    }
end

local function compareTables(a, b)
    for k, v in pairs(a) do
        if v ~= b[k] then 
            return false
        end
    end
    return true
end

function ccute.Surface.drawAtXY(self, x, y)
    if self.lastSurface and self.lastSurface.offsetX == x and self.lastSurface.offsetY == y then
        for i = 1, self.width do
            for j = 1, self.height do
                if not compareTables(self.surface[i][j], self.lastSurface[i][j]) then
                    term.setCursorPos(i + x - 1, j + y - 1)
                    term.setTextColor(self.surface[i][j].textColor)
                    term.setBackgroundColor(self.surface[i][j].backgroundColor)
                    term.write(self.surface[i][j].text)
                end
            end
        end
    else
        for i = 1, self.width do
            for j = 1, self.height do
                term.setCursorPos(i + x - 1, j + y - 1)
                term.setTextColor(self.surface[i][j].textColor)
                term.setBackgroundColor(self.surface[i][j].backgroundColor)
                term.write(self.surface[i][j].text)
            end
        end
    end
    self.lastSurface = deepcopy(self.surface)
    self.lastSurface.offsetX = x
    self.lastSurface.offsetY = y
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
end


ccute.Widget = {}
ccute.Widget.__index = ccute.Widget

setmetatable(ccute.Widget, {
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function ccute.Widget._init(self, renderTarget)
    if renderTarget.coreWidget then
        self.renderTarget = renderTarget.renderer
    else
        self.renderTarget = renderTarget
    end
    self:resize(self.renderTarget.width, self.renderTarget.height)
    self.x = 1
    self.y = 1
    self.width = 0
    self.height = 0
    self.children = {}
    self.parent = nil
    self.color = colors.gray
    self.visible = true
    self.animation = nil
    self.animationTimer = nil
end

function ccute.Widget.show(self, animation)
    self.visible = true
    if animation then
        animation.show = true
        self.animation = animation
        self.animationTimer = os.startTimer(0.05)
        for k, v in pairs(self.children) do
            v:show(animation)
        end
    end
end

function ccute.Widget.hide(self, animation)
    if animation then
        animation.show = false
        self.animation = animation
        self.animationTimer = os.startTimer(0.05)
        for k, v in pairs(self.children) do
            v:hide(animation)
        end
    else
        self.visible = false
    end
end

function ccute.Widget.move(self, x, y)
    self.x = x or self.x
    self.y = y or self.y
end

function ccute.Widget.resize(self, width, height)
    self.width = width or self.width
    self.height = height or self.height
end

function ccute.Widget.getRealWH(self)
    local nw, nh
    nw = self.width
    nh = self.height
    for k, v in pairs(self.children) do
        nw = math.max(nw, v.x + v.width - 1)
        nh = math.max(nh, v.y + v.height - 1)
    end
    return nw, nh
end

function ccute.Widget.getRealXY(self)
    if not self.parent then
        return self.x, self.y
    end
    local x, y
    x, y = self.parent:getRealXY()
    return self.x + x - 1, self.y + y - 1
end

function ccute.Widget.processEvent(self, event, e1, e2, e3, e4, e5)
    for k, v in pairs(self.children) do
        v:processEvent(event, e1, e2, e3, e4, e5)
    end
    if event == "timer" and e1 == self.animationTimer then
        if self.animation then
            self.animation:tick(0.05)
            if self.animation.over then
                self.visible = self.animation.show
                self.animation = nil
            else
                self.animationTimer = os.startTimer(0.05)
            end
        end
    end
end

function ccute.Widget.addChild(self, child)
    table.insert(self.children, child)
    child.parent = self
    if child.width == 0 then child.width = self.width end
    if child.height == 0 then child.height = self.height end
end

function ccute.Widget.draw(self)
    local x, y
    x, y = self:getRealXY()
    for i = x, x + self.width - 1 do
        for j = y, y + self.height - 1 do
            if not self.animation or self.animation:mask(i, j) then 
                self.renderTarget:drawPixel(i, j, self.color, self.color, " ")
            end
        end
    end
    for k, v in pairs(self.children) do
        if v.visible then v:draw() end
    end
end

ccute.Button = {}
ccute.Button.__index = ccute.Button

setmetatable(ccute.Button, {
    __index = ccute.Widget, 
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function ccute.Button._init(self, renderTarget)
    ccute.Widget._init(self, renderTarget)
    self.pressedColor = colors.lightGray
    self.releaseTimer = nil
    self.pressed = false
    self.pressAnimation = nil
    self.pressAnimationTimer = nil
end


function ccute.Button.processEvent(self, event, e1, e2, e3, e4, e5)
    for k, v in pairs(self.children) do
        v:processEvent(event, e1, e2, e3, e4, e5)
    end
    if event == "timer" and e1 == self.animationTimer then
        if self.animation then
            self.animation:tick(0.05)
            if self.animation.over then
                self.visible = self.animation.show
                self.animation = nil
            else
                self.animationTimer = os.startTimer(0.05)
            end
        end
    end
    if event == "timer" and e1 == self.pressAnimationTimer then
        if self.pressAnimation then
            self.pressAnimation:tick(0.05)
            if self.pressAnimation.over then
                self.pressAnimation = nil
            else
                self.pressAnimationTimer = os.startTimer(0.05)
            end
        end
    end
    if event == "mouse_click" then
        local x, y
        x, y = self:getRealXY()
        if  e2 >= x and e2 <= x + self.width - 1 and
            e3 >= y and e3 <= y + self.height - 1 then
            self.releaseTimer = os.startTimer(1)
            self.pressed = true
            local animation = ccute.RoundToggleAnimation()
            animation.speed = 40
            animation.totalTime = 10
            animation.xstart = e2
            animation.ystart = e3
            self.pressAnimation = animation
            self.pressAnimationTimer = os.startTimer(0.05)
            if self.onclick then self:onclick() end
        end
    end
    if event == "timer" and e1 == self.releaseTimer then
        self.releaseTimer = nil
        self.pressed = false
        local animation = ccute.RoundToggleAnimation()
        animation.speed = 50
        animation.totalTime = 2
        animation.xstart = self.pressAnimation.xstart
        animation.ystart = self.pressAnimation.ystart
        self.pressAnimation = animation
        self.pressAnimationTimer = os.startTimer(0.05)
    end

end

function ccute.Button.draw(self)
    local x, y
    x, y = self:getRealXY()
    for i = x, x + self.width - 1 do
        for j = y, y + self.height - 1 do
            if not self.animation or self.animation:mask(i, j) then 
                if not self.pressAnimation or self.pressAnimation:mask(i, j) then
                    if self.pressed then
                        self.renderTarget:drawPixel(i, j, self.color, self.color, " ")
                    else
                        self.renderTarget:drawPixel(i, j, self.pressedColor, self.pressedColor, " ")
                    end
                else
                    if self.pressed then
                        self.renderTarget:drawPixel(i, j, self.pressedColor, self.pressedColor, " ")
                    else
                        self.renderTarget:drawPixel(i, j, self.color, self.color, " ")
                    end

                end
            end
        end
    end
    for k, v in pairs(self.children) do
        if v.visible then v:draw() end
    end
end

ccute.Label = {}
ccute.Label.__index = ccute.Label

setmetatable(ccute.Label, {
    __index = ccute.Widget, 
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function ccute.Label._init(self, renderTarget, text)
    ccute.Widget._init(self, renderTarget)
    self.text = text or ""
    self.color = colors.black
    self.backgroundColor = nil
end

function ccute.Label.draw(self)
    local x, y
    x, y = self:getRealXY()
    local l = string.split(self.text, "\n")
    local lines = {}
    for k, v in pairs(l) do
        for i = 1, math.floor(#v / self.width) + 1 do
            table.insert(lines, string.sub(v, self.width * (i - 1) + 1, self.width * i))
            if #lines >= self.height then
                break
            end
        end
        if #lines >= self.height then
            break
        end
    end
    for i = 1, #lines do
        for j = 1, #lines[i] do
            if not self.animation or self.animation:mask(j + x - 1, i + y - 1) then 
                self.renderTarget:drawPixel(j + x - 1, i + y - 1, self.color, self.backgroundColor, string.sub(lines[i], j, j))
            end
        end
    end
end

ccute.Input = {}
ccute.Input.__index = ccute.Input

setmetatable(ccute.Input, {
    __index = ccute.Widget,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function ccute.Input._init(self, renderTarget)
    ccute.Widget._init(self, renderTarget)
    self.focused = false
    self.textColor = colors.white
    self.backgroundColor = colors.blue
    self.backgroundColorFocused = colors.lightBlue
    self.textColorCursor = colors.lightGray
    self.text = ""
    self.cursorPos = 1
    self.leftBorder = 1
    self.mask = nil
end

function ccute.Input.processEvent(self, event, e1, e2, e3, e4, e5)
    for k, v in pairs(self.children) do
        v:processEvent(event, e1, e2, e3, e4, e5)
    end
    if event == "timer" and e1 == self.animationTimer then
        if self.animation then
            self.animation:tick(0.05)
            if self.animation.over then
                self.visible = self.animation.show
                self.animation = nil
            else
                self.animationTimer = os.startTimer(0.05)
            end
        end
    end
    if event == "mouse_click" then
        local x, y
        x, y = self:getRealXY()
        if  e2 >= x and e2 <= x + self.width - 1 and
            e3 >= y and e3 <= y + self.height - 1 then
            self.focused = true
            if self.onclick then self:onclick() end
            if self.onfocus then self:onfocus() end
        else
            self.focused = false
            if self.ondefocus then self:ondefocus() end
        end
    end
    if self.focused then
        if event == "char" then
            self.text = string.sub(self.text, 1, math.max(self.cursorPos - 1, 0)) .. e1 .. string.sub(self.text, self.cursorPos, #self.text)
            self.cursorPos = self.cursorPos + 1
            if self.onchange then self:onchange() end
        end
        if event == "key" then
            if e1 == 14 then
                if #self.text > 0 then
                    self.text = string.sub(self.text, 1, math.max(self.cursorPos - 2, 0)) .. string.sub(self.text, self.cursorPos, #self.text)
                    self.cursorPos = self.cursorPos - 1
                    if self.onchange then self:onchange() end
                end
            end
            if e1 == 211 then
                if #self.text > 0 then
                    self.text = string.sub(self.text, 1, math.max(self.cursorPos - 1, 0)) .. string.sub(self.text, self.cursorPos + 1, #self.text)
                    if self.onchange then self:onchange() end
                end
            end
            if e1 == 199 then
                self.cursorPos = 1
                self.leftBorder = 1
            end
            if e1 == 207 then
                self.cursorPos = #self.text + 1
            end
            if e1 == 203 then
                if self.cursorPos > 1 then
                    self.cursorPos = self.cursorPos - 1
                end
            end
            if e1 == 205 then
                if self.cursorPos <= #self.text then
                    self.cursorPos = self.cursorPos + 1
                end
            end
        end
        if self.cursorPos >= self.width then
            self.leftBorder = self.cursorPos - self.width + 1
        elseif self.cursorPos < self.leftBorder then
            self.leftBorder = self.cursorPos
        elseif self.leftBorder + self.width - 1 > #self.text and #self.text > self.width then
            self.leftBorder = #self.text - self.width + 1
        end
    end
end

function ccute.Input.draw(self)
    local x, y
    local bc
    bc = self.backgroundColor
    if self.focused then
        bc = self.backgroundColorFocused
    end
    x, y = self:getRealXY()
    local t
    t = self.text
    if self.mask then
        t = t:gsub(".", self.mask)
    end
    if self.cursorPos > #self.text and self.focused then
        t = t .. " "
    end
    for i = 1, self.width do
        local ch
        ch = " "
        if i <= #t then
            ch = string.sub(t, i + self.leftBorder - 1, i + self.leftBorder - 1)
        end
        local tc
        tc = self.textColor
        if i + self.leftBorder - 1 == self.cursorPos then
            tc = self.textColorCursor
            if ch == " " and self.focused then
                ch = "_"
            end
        end
        if not self.animation or self.animation:mask(i + x - 1, y) then 
            self.renderTarget:drawPixel(i + x - 1, y, tc, bc, ch)
        end
    end
end


ccute.ProgressBar = {}
ccute.ProgressBar.__index = ccute.ProgressBar

setmetatable(ccute.ProgressBar, {
    __index = ccute.Widget,
    __call = function (cls, ...)
        self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function ccute.ProgressBar._init(self, renderTarget)
    ccute.Widget._init(self, renderTarget)
    self.minValue = 0
    self.maxValue = 100
    self.currentValue = 0
    self.showNumber = true
    self.fillColor = colors.green
    self.backgroundColor = colors.lightGray
    self.textColor = colors.white
    self.horizontal = true
end

function ccute.ProgressBar.draw(self)
    local x, y
    x, y = self:getRealXY()
    if self.horizontal then
        local filled
        filled = (self.currentValue - self.minValue) / self.maxValue * self.width
        for j = y, y + self.height - 1 do
            for i = 1, self.width - 1 do
                if not self.animation or self.animation:mask(i + x - 1, j) then 
                    if i <= filled then
                        self.renderTarget:drawPixel(i + x - 1, j, self.fillColor, self.fillColor, " ")
                    else
                        self.renderTarget:drawPixel(i + x - 1, j, self.backgroundColor, self.backgroundColor, " ")
                    end
                end
            end
        end
    else
        local filled
        filled = (self.currentValue - self.minValue) / self.maxValue * self.height
        for j = x, x + self.width - 1 do
            for i = 1, self.height - 1 do
                if not self.animation or self.animation:mask(j, i + y - 1) then 
                    if i <= filled then
                        self.renderTarget:drawPixel(j, i + y - 1, self.fillColor, self.fillColor, " ")
                    else
                        self.renderTarget:drawPixel(j, i + y - 1, self.backgroundColor, self.backgroundColor, " ")
                    end
                end
            end
        end
    end
    if self.showNumber then
        local percent = tostring(math.floor((self.currentValue - self.minValue) / self.maxValue * 100)) .. "%"
        local length = string.len(percent)
        local mx, my
        mx = math.floor((x + x + self.width - 1 - length) / 2)
        my = math.floor((y + y + self.height - 1) / 2)
        for i = 1, #percent do
            if not self.animation or self.animation:mask(mx + i - 1, my) then 
                self.renderTarget:drawPixel(mx + i - 1, my, self.textColor, nil, percent:sub(i, i))
            end
        end
    end
end

ccute.Layout = {}
ccute.Layout.__index = ccute.Layout

setmetatable(ccute.Layout, {
    __index = ccute.Widget,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function ccute.Layout._init(self, renderTarget)
    ccute.Widget._init(self, renderTarget)
end

function ccute.Layout.processEvent(self, event, e1, e2, e3, e4, e5)
    for k, v in pairs(self.children) do
        v:processEvent(event, e1, e2, e3, e4, e5)
    end
    if event == "timer" and e1 == self.animationTimer then
        if self.animation then
            self.animation:tick(0.05)
            if self.animation.over then
                self.visible = self.animation.show
                self.animation = nil
            else
                self.animationTimer = os.startTimer(0.05)
            end
        end
    end
    self:recalculate()
end

function ccute.Layout.recalculate(self)
end

function ccute.Layout.addChild(self, child)
    table.insert(self.children, child)
    child.parent = self
    child.layoutWeight = child.layoutWeight or 1
end


ccute.HorizontalLayout = {}
ccute.HorizontalLayout.__index = ccute.HorizontalLayout

setmetatable(ccute.HorizontalLayout, {
    __index = ccute.Layout,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function ccute.HorizontalLayout._init(self, renderTarget)
    ccute.Layout._init(self, renderTarget)
    self.margin = 1
    self.leftMargin = 0
    self.rightMargin = 0
    self.topMargin = 0
    self.bottomMargin = 0
end

function ccute.HorizontalLayout.recalculate(self)
    local totalWeight
    totalWeight = 0
    for k, v in pairs(self.children) do
        totalWeight = totalWeight + v.layoutWeight
    end
    local i
    i = self.leftMargin
    for k, v in pairs(self.children) do
        local nw, nh
        nw = math.floor((self.width - self.leftMargin - self.rightMargin) / totalWeight * v.layoutWeight) - 1
        nh = self.height - self.topMargin - self.bottomMargin
        if v.maxWidth then nw = math.min(nw, v.maxWidth) end
        if v.maxHeight then nh = math.min(nh, v.maxHeight) end
        v:resize(nw, nh)
        v:move(i + 1, self.topMargin + 1)
        i = i + nw + self.margin
    end
end


ccute.VerticalLayout = {}
ccute.VerticalLayout.__index = ccute.VerticalLayout

setmetatable(ccute.VerticalLayout, {
    __index = ccute.Layout,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function ccute.VerticalLayout._init(self, renderTarget)
    ccute.Layout._init(self, renderTarget)
    self.margin = 1
    self.leftMargin = 0
    self.rightMargin = 0
    self.topMargin = 0
    self.bottomMargin = 0
end

function ccute.VerticalLayout.recalculate(self)
    local totalWeight
    totalWeight = 0
    for k, v in pairs(self.children) do
        totalWeight = totalWeight + v.layoutWeight
    end
    local i
    i = self.leftMargin
    for k, v in pairs(self.children) do
        local nw, nh
        nw = self.width - self.leftMargin - self.rightMargin
        nh = math.floor((self.height - self.topMargin - self.bottomMargin) / totalWeight * v.layoutWeight) - 1
        v:resize(nw, nh)
        if v.maxWidth then nw = math.min(nw, v.maxWidth) end
        if v.maxHeight then nh = math.min(nh, v.maxHeight) end
        v:move(self.leftMargin + 1, i + 1)
        i = i + nh + self.margin
    end
end


ccute.ScrollBar = {}
ccute.ScrollBar.__index = ccute.ScrollBar

setmetatable(ccute.ScrollBar, {
    __index = ccute.Widget,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function ccute.ScrollBar._init(self, renderTarget)
    ccute.Widget._init(self, renderTarget)
    self.fillColor = colors.blue
    self.backgroundColor = colors.lightGray
    self.totalLines = 100
    self.linesPerPage = 30
    self.leftLine = 1
    self.lastClickedX = nil
    self.lastClickedY = nil
    self.horizontal = true
end

function ccute.ScrollBar.processEvent(self, event, e1, e2, e3, e4, e5)
    for k, v in pairs(self.children) do
        v:processEvent(event, e1, e2, e3, e4, e5)
    end
    if event == "timer" and e1 == self.animationTimer then
        if self.animation then
            self.animation:tick(0.05)
            if self.animation.over then
                self.visible = self.animation.show
                self.animation = nil
            else
                self.animationTimer = os.startTimer(0.05)
            end
        end
    end
    local fillStart, fillEnd
    if self.horizontal then
        fillStart = math.floor(self.leftLine / self.totalLines * self.width)
        fillEnd = fillStart + math.floor(self.linesPerPage / self.totalLines * self.width)

        local x, y
        x, y = self:getRealXY()
        if event == "mouse_click" then
            if e3 >= y and e3 <= y + self.height - 1 and e2 - x + 1 >= fillStart and e2 - x + 1 <= fillEnd then
                self.lastClickedX = e2
                self.lastClickedY = e3
            else
                self.lastClickedX = nil
                self.lastClickedY = nil
            end
            if e2 == x and e3 >= y and e3 <= y + self.height - 1 then --Scroll 1 line left
                if self.leftLine > 1 then
                    self.leftLine = self.leftLine - 1
                end
            end
            if e2 == x + self.width - 1 and e3 >= y and e3 <= y + self.height - 1 then --Scroll 1 line right
                if self.leftLine < self.totalLines - self.linesPerPage + 1 then
                    self.leftLine = self.leftLine + 1
                end
            end
        end
        if event == "mouse_drag" then
            self.lastClickedX = self.lastClickedX or e2
            self.lastClickedY = self.lastClickedY or e3
            if e3 >= y and e3 <= y + self.height - 1 and e2 - x + 1 >= fillStart and e2 - x + 1 <= fillEnd then
                self.leftLine = math.floor((e2 - x - (self.lastClickedX - x) / 2) / self.width * self.totalLines)
            end

            if self.leftLine < 1 then
                self.leftLine = 1
            end
            if self.leftLine > self.totalLines - self.linesPerPage + 1 then
                self.leftLine = self.totalLines - self.linesPerPage + 1
            end
        end
    else
        fillStart = math.floor(self.leftLine / self.totalLines * self.height)
        fillEnd = fillStart + math.floor(self.linesPerPage / self.totalLines * self.height)

        local x, y
        x, y = self:getRealXY()
        if event == "mouse_click" then
            if e2 >= x and e2 <= x + self.width - 1 and e3 - y + 1 >= fillStart and e3 - y + 1 <= fillEnd then
                self.lastClickedX = e2
                self.lastClickedY = e3
            else
                self.lastClickedX = nil
                self.lastClickedY = nil
            end
            if e3 == y and e2 >= x and e2 <= x + self.width - 1 then --Scroll 1 line up
                if self.leftLine > 1 then
                    self.leftLine = self.leftLine - 1
                end
            end
            if e3 == y + self.height - 1 and e2 >= x and e2 <= x + self.width - 1 then --Scroll 1 line down
                if self.leftLine < self.totalLines - self.linesPerPage + 1 then
                    self.leftLine = self.leftLine + 1
                end
            end
        end
        if event == "mouse_drag" then
            self.lastClickedX = self.lastClickedX or e2
            self.lastClickedY = self.lastClickedY or e3
            if e2 >= x and e2 <= x + self.width - 1 and e3 - y + 1 >= fillStart and e3 - y + 1 <= fillEnd then
                self.leftLine = math.floor((e3 - y - (self.lastClickedY - y) / 2) / self.height * self.totalLines)
            end

            if self.leftLine < 2 then
                self.leftLine = 2
            end
            if self.leftLine > self.totalLines - self.linesPerPage + 2 then
                self.leftLine = self.totalLines - self.linesPerPage + 2
            end
        end
    end
end

function ccute.ScrollBar.draw(self)
    local fillStart, fillEnd
    if self.horizontal then
        fillStart = math.floor(self.leftLine / self.totalLines * self.width)
        fillEnd = fillStart + math.floor(self.linesPerPage / self.totalLines * self.width)

        local x, y
        x, y = self:getRealXY()
        for i = x, x + self.width - 1 do
            for j = y, y + self.height - 1 do
                if not self.animation or self.animation:mask(i, j) then 
                    if i - x + 1 >= fillStart and i - x + 1 <= fillEnd then
                        self.renderTarget:drawPixel(i, j, self.fillColor, self.fillColor, " ")
                    else
                        self.renderTarget:drawPixel(i, j, self.backgroundColor, self.backgroundColor, " ")
                    end
                end
            end
        end
        if not self.animation or self.animation:mask(x, math.floor((y + y + self.height) / 2)) then 
            self.renderTarget:drawPixel(x, math.floor((y + y + self.height) / 2), colors.white, nil, "<")
        end
        if not self.animation or self.animation:mask(x + self.width - 1, math.floor((y + y + self.height) / 2)) then 
            self.renderTarget:drawPixel(x + self.width - 1, math.floor((y + y + self.height) / 2), colors.white, nil, ">")
        end
    else
        fillStart = math.floor(self.leftLine / self.totalLines * self.height)
        fillEnd = fillStart + math.floor(self.linesPerPage / self.totalLines * self.height)

        local x, y
        x, y = self:getRealXY()
        for i = x, x + self.width - 1 do
            for j = y, y + self.height - 1 do
                if not self.animation or self.animation:mask(i, j) then 
                    if j - y + 1 >= fillStart and j - y + 1 <= fillEnd then
                        self.renderTarget:drawPixel(i, j, self.fillColor, self.fillColor, " ")
                    else
                        self.renderTarget:drawPixel(i, j, self.backgroundColor, self.backgroundColor, " ")
                    end
                end
            end
        end 
        if not self.animation or self.animation:mask(math.floor((x + x + self.width) / 2), y) then 
            self.renderTarget:drawPixel(math.floor((x + x + self.width) / 2), y, colors.white, nil, "^")
        end
        if not self.animation or self.animation:mask(math.floor((x + x + self.width) / 2), y + self.height - 1) then 
            self.renderTarget:drawPixel(math.floor((x + x + self.width) / 2), y + self.height - 1, colors.white, nil, "v")
        end
    end
    for k, v in pairs(self.children) do
        v:draw()
    end
end


ccute.Application = {}
ccute.Application.__index = ccute.Application

setmetatable(ccute.Application, {
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

function ccute.Application._init(self)
    local tw, th
    tw, th = term.getSize()
    self.renderer = ccute.Surface(tw, th)
    self.coreWidget = ccute.Widget(self.renderer)
    self.coreWidget:resize(tw, th)
    self.coreWidget:move(1, 1)
end

function ccute.Application.attachWidget(self, widget)
    self.coreWidget:addChild(widget)
end

function ccute.Application.run(self, noesc)
    while true do 
        term.setCursorBlink(false)
        local event, e1, e2, e3, e4, e5
        event, e1, e2, e3, e4, e5 = os.pullEvent()
        if self.finished then
            break 
        end
        if event == "key" and e1 == 1 and not noesc then
            break
        end
        self.coreWidget:processEvent(event, e1, e2, e3, e4, e5)
        self.coreWidget:draw()
        self.renderer:drawAtXY(1, 1)
    end
    term.setCursorBlink(true)
end

function ccute.Application.exit(self)
    self.finished = true
    os.queueEvent("ccute_app_exit")
end

return ccute
