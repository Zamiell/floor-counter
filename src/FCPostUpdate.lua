local FCPostUpdate = {}

-- Includes
local FCGlobals = require("src/fcglobals")

-- ModCallbacks.MC_POST_UPDATE (1)
function FCPostUpdate:Main()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  -- Check to see if we need to reseed the floor
  if FCGlobals.reseedFrame ~= 0 and
     gameFrameCount >= FCGlobals.reseedFrame then

    FCGlobals.reseedFrame = 0
    Isaac.ExecuteCommand("reseed")
    return
  end
end

return FCPostUpdate
