--CCute, material design graphics library

local ccute = {}


ccute.Widget = {}
ccute.Widget.__index = ccute.Widget

setmetatable(ccute.Widget, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function ccute.Widget._init(self)
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
