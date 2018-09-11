local FCUseItem = {}

-- Includes
local FCGlobals = require("src/fcglobals")
local FCExplore = require("src/fcexplore")

-- ModCallbacks.MC_USE_ITEM (3)
function FCUseItem:Main()
  -- Mark that we should enter an infinite loop of floor reloading
  FCGlobals.running = true

  FCExplore:Start()
end

return FCUseItem
