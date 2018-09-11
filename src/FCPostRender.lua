local FCPostRender = {}

-- Includes
local FCGlobals = require("src/fcglobals")

-- ModCallbacks.MC_POST_RENDER (2)
function FCPostRender:Main()
  if FCGlobals.saveData == nil then
    return
  end

  local roomTypes = {
    "leftRightDown",
    "leftRight",
    "leftDown",
    "rightDown",
  }
  local x = 75
  local column = 175
  local y = 35
  local line = 15
  y = y - line
  for i = 1, #roomTypes do
    local roomType = roomTypes[i]
    local data = FCGlobals.saveData[roomType]
    local text

    y = y + line
    text = "Room type: " .. roomType
    Isaac.RenderText(text, x, y, 1, 1, 1, 1)

    if data.left then
      local leftPercent = FCGlobals:Round(data.left / data.total * 100, 1)
      text = "Left: " .. tostring(leftPercent) .. "% (" .. tostring(data.left) .. ")"
      Isaac.RenderText(text, x + column, y, 1, 1, 1, 1)
      y = y + line
    end

    if data.right then
      local rightPercent = FCGlobals:Round(data.right / data.total * 100, 1)
      text = "Right: " .. tostring(rightPercent) .. "% (" .. tostring(data.right) .. ")"
      Isaac.RenderText(text, x + column, y, 1, 1, 1, 1)
      y = y + line
    end

    if data.down then
      local downPercent = FCGlobals:Round(data.down / data.total * 100, 1)
      text = "Down: " .. tostring(downPercent) .. "% (" .. tostring(data.down) .. ")"
      Isaac.RenderText(text, x + column, y, 1, 1, 1, 1)
      y = y + line
    end

    text = "Total: " .. tostring(data.total)
    Isaac.RenderText(text, x + column, y, 1, 1, 1, 1)
    y = y + line
  end
end

return FCPostRender
