--Uber GUI

ugui = {}
local MainWidget = nil
local pixelCache = {}

function ugui.init()
  local tw, th = term.getSize()
  MainWidget = {
  x = 1, y = 1,
  w = tw, h = th,
  focusable = true,
  enabled = true,
  children = {},
  parent = nil,
  onclick = nil,
  ondrag = nil,
  onkey = nil,
  onchar = nil,
  wtype = "Main"
  }
  for i = 1, tw do
    pixelCache[i] = {}
    for j = 1, th do
      pixelCache[i][j] = {" ", colors.black, colors.white}
    end
  end
  term.setCursorBlink(false)
end

function ugui.redraw()
  term.setCursorPos(1, 1)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)

  for i = 1, #pixelCache do
    for j = 1, #pixelCache[i] do
      term.setCursorPos(i, j)
      term.setBackgroundColor(pixelCache[i][j][3])
      term.setTextColor(pixelCache[i][j][2])
      term.write(pixelCache[i][j][1])
    end
  end

  term.setCursorPos(1, 1)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
end

function clearCache()
  for i = 1, #pixelCache do
    for j = 1, #pixelCache[i] do
      pixelCache[i][j] = {" ", colors.black, colors.white}
    end
  end
end

function putPixel(text, back, front, x, y)
  pixelCache[x][y] = {text, front, back}
end

function ugui.resolveCoordinates(x, y, widget)
  local function isOnWidget(x, y, widget)
    return (x >= widget.x) and (x <= widget.x + widget.w) and
           (y >= widget.x) and (y <= widget.y + widget.h)
  end
  widget = widget or MainWidget
  for i = 1, #widget.children do
    local tmp = ugui.resolveCoordinates(x, y, widget.children[i])
    if tmp then
      return tmp
    elseif isOnWidget(x, y, widget.children[i]) then
      return widget.children[i]
    end
  end
  return false
end

function ugui.addWidget(x, y, w, h, wtype, parent, ...)
  parent = parent or MainWidget
  local widget = {
    x = x, y = y,
    w = w, h = h,
    focusable = true,
    enabled = true,
    children = {},
    parent = parent,
    onclick = nil,
    ondrag = nil,
    onkey = nil,
    onchar = nil,
    wtype = wtype
  }
  ugui.widgets[wtype].oncreate(widget, unpack(arg))
  table.insert(parent.children, widget)
  return widget
end

function ugui.draw(widget)
  widget = widget or MainWidget
  ugui.widgets[widget.wtype].ondraw(widget)
  for i = 1, #widget.children do
    ugui.draw(widget.children[i])
  end
end

function ugui.pullEvent(event, e1, e2, e3, e4, e5)
  if event == "mouse_click" then
    if e1 == 1 then
      local widget = ugui.resolveCoordinates(e2, e3)
      if widget then
        if ugui.widgets[widget.wtype].onclick then
          ugui.widgets[widget.wtype].onclick(widget)
        end
        if widget.onclick then
          widget.onclick(widget)
        end
        ugui.redraw(widget)
      end
    end
  end
end

ugui.widgets = {
  Main = {
    color = function() return colors.white end,
    ondraw = function(self)
      for i = self.x, self.x + self.w do
        for j = self.y, self.y + self.h do
          ugui.putPixel
        end
      end
    end
  },
  Button = {
    color = function(self)
      if self.state == "normal" then
        return ugui.widgets.Button.normalColor
      else
        return ugui.widgets.Button.activeColor
      end
    end,
    normalColor = colors.lightGray,
    activeColor = colors.gray,
    textColor   = colors.black,
    oncreate = function(self, text)
      self.text = text or "Button"
      self.state = "normal"
    end,
    onclick = function(self)
      if self.state == "normal" then
        self.state = "pressed"
      else
        self.state = "normal"
      end
    end,
    ondraw = function(self)
      for i = self.x, self.x + self.w do
        for j = self.y, self.y + self.h do
          term.setCursorPos(i, j)
          if self.state == "normal" then
            term.setBackgroundColor(ugui.widgets.Button.color(self))
          else
            term.setBackgroundColor(ugui.widgets.Button.color(self))
          end
          term.write(" ")
        end
      end
      term.setCursorPos(math.floor(self.x + self.w / 2 - #self.text / 2), math.floor(self.y + self.h / 2))
      term.setTextColor(ugui.widgets.Button.textColor)
      term.write(self.text)
    end
  },
  Checkbox = {
    color = function() return colors.lightGray end,
    textColor = colors.black,
    oncreate = function(self, checked, text)
      self.checked = checked or false
      self.text = text or ""
    end,
    onclick = function(self)
      self.checked = not self.checked
    end,
    ondraw = function(self)
      term.setCursorPos(self.x, self.y)
      term.setBackgroundColor(ugui.widgets.Checkbox.color())
      term.setTextColor(ugui.widgets.Checkbox.textColor)
      if self.checked then
        term.write("X")
      else
        term.write(" ")
      end
      if #self.text > 0 then
        term.setBackgroundColor(ugui.widgets[self.parent.wtype]:color())
        term.write(" " .. self.text)
      end
    end
  },
  Label = {
    color = function() return nil end,
    textColor = colors.black,
    oncreate = function(self, text)
      self.text = text or "Label"
    end,
    ondraw = function(self)
      term.setCursorPos(self.x, self.y)
      term.setTextColor(ugui.widgets.Label.textColor)
      term.setBackgroundColor(ugui.widgets[self.parent.wtype]:color())
      term.write(self.text)
    end
  }
}

ugui.widgets = applyreadonly(ugui.widgets)
ugui = applyreadonly(ugui)
