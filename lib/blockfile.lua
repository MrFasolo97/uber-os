--Block file library
--It allows to split file in blocks, add meta data and seek through file

bf = {}
bf.bs = 512 --Block size

function bf.open(path)
  if string.sub(path, 1, 1) ~= "/" then
    path = "/" .. path
  end
  if string.sub(path, #path, #path) == "/" then
    path = string.sub(path, 1, #path - 1)
  end
  if not fs.exists(path) then
    fs.makeDir(path)
  end
  return {
    ["path"] = path,
    ["mode"] = mode,
    slice = function(self, start, stop, value)
      --Load blocks into memory
      local bstart = math.floor(start / bf.bs) + 1
      local bstop = math.floor(stop / bf.bs) + 1
      local blocks = {}
      for i = bstart, bstop do
        local block = fs.open(self.path .. "/B" .. tostring(i), "rb")
        blocks[i] = {}
        for j = 1, bf.bs do
          blocks[i][j] = block.read()
        end
        block.close()
      end
      if value then
        --Write
        for i = bstart, bstop do
          local block = fs.open(self.path .. "/B" .. tostring(i), "wb")
          for j = 1, bf.bs do
            if ((i - 1) * bf.bs + j < start) or ((i - 1) * bf.bs + j > stop) then
              block.write(blocks[i][j])
            else
              block.write(value[(i - 1) * bf.bs + j - start + 1])
            end
          end
          block.close()
        end
      else
        --Read
        local result = {}
        for i = bstart, bstop do
          for j = 1, bf.bs do
            if ((i - 1) * bf.bs + j >= start) and ((i - 1) * bf.bs + j <= stop) then
              result[#result + 1] = blocks[i][j]
            end
          end
        end
        return result
      end
    end,
    write = function(self, value)
      local blocks = math.floor(#value / bf.bs) + 1
      for i = 1, blocks do
        local f = fs.open(self.path .. "/B" .. tostring(i), "wb")
        for j = 1, bf.bs do
          if (i - 1)* bf.bs + j <= #value then
            f.write(value[(i - 1)* bf.bs + j])
          end
        end
        f.close()
      end
    end,
    getSize = function(self)
      local totalBlocks = 0
      local totalBytes = 0
      while true do
        if not fs.exists(self.path .. "/B" .. totalBlocks + 1) then
          break
        end
        totalBlocks = totalBlocks + 1
        totalBytes = totalBytes + fs.getSize(self.path .. "/B" .. totalBlocks)
      end
      return totalBlocks, totalBytes
    end
  }
end

bf = applyreadonly(bf)
