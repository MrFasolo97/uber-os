--Uber Graphics User Interface Library

ugui = {}
local widgets = {}
local wtypes = {}
local pixels = {}

ugui.init = function()
  local w, h = term.getSize()
  for i = 1, w do
    pixels[i] = {}
    for j = 1, h do
      pixels[i][j] = {symb = " ", front = colors.black, back = colors.black}
    end
  end
end

wtypes.Button = {
  ondraw = function(self)
  end
}

local genRandomId = function()
  local id = 1
  while widgets[id] do id = math.random(1, 65536) end
  return id
end

local getAbsolutePos = function(wid)
  local x, y
  local w, h
  w = wid.w
  h = wid.h
  x = 1
  y = 1
  while widgets[wid].parent do
    x = x + wid.x - 1
    y = y + wid.y - 1
    wid = widgets[wid].parent
  end
  return x, y, w, h
end

ugui.putPixel = function(x, y, symb, front, back)
  pixels[x][y].symb = symb or pixels[x][y].symb
  pixels[x][y].front = front or pixels[x][y].front
  pixels[x][y].back = back or pixels[x][y].back
end

ugui.Widget = function(t)
  local id = genRandomId()
  widgets[id] = {
    x = 1, y = 1,
    w = 1, h = 1,
    parent = nil,
    children = {},
    pid = thread.getPID(coroutine.running()),
    wtype = t
  }
  return {
    id = id,
    onclick = function(self) end,
    ondraw = function(self) end,
    ondrag = function(self) end,
    getPosition = function(self) return widgets[self.id].x, widgets[self.id].y, widgets[self.id].w, widgets[self.id].h end,
    setPosition = function(self, x, y) widgets[self.id].x = x widgets[self.id].y = y end,
    getAbsolutePosition = function(self)
      return getAbsolutePos(self) 
    end
  }
end

ugui.Button = function()
  local w = ugui.Widget("Button")
  w.isPressed = false
  w.color = colors.lightGray
  w.colorPressed = colors.gray
end

ugui = applyreadonly(ugui)
