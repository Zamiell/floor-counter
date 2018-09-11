-- Register the mod (the second argument is the API version)
local FloorCounter = RegisterMod("Floor Counter", 1)

-- The Lua code is split up into separate files for organizational purposes
local FCGlobals         = require("src/fcglobals") -- Global variables
local FCPostUpdate      = require("src/fcpostupdate") -- The PostUpdate callback (1)
local FCPostRender      = require("src/fcpostrender") -- The PostRender callback (2)
local FCUseItem         = require("src/fcuseitem") -- The UseItem callback (3)
local FCPostGameStarted = require("src/fcpostgamestarted") -- The PostGameStarted callback (15)
local FCPostNewLevel    = require("src/fcpostnewlevel") -- The PostNewLevel callback (18)
--local FCPostNewRoom     = require("src/fcpostnewroom") -- The PostNewRoom callback (19)

-- Make a copy of this object so that we can use it elsewhere
FCGlobals.FloorCounter = FloorCounter -- (this is needed for loading the "save.dat" file)

-- Define miscellaneous callbacks
FloorCounter:AddCallback(ModCallbacks.MC_POST_UPDATE, FCPostUpdate.Main) -- 1
FloorCounter:AddCallback(ModCallbacks.MC_POST_RENDER, FCPostRender.Main) -- 2
FloorCounter:AddCallback(ModCallbacks.MC_USE_ITEM, FCUseItem.Main) -- 3
FloorCounter:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, FCPostGameStarted.Main) -- 15
FloorCounter:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, FCPostNewLevel.Main) -- 18
--FloorCounter:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, FCPostNewRoom.Main) -- 19

--[[

Notes:
- The grid indexes correspond to a 13x13 grid, with the top left hand corner being index 0,
  and the first element of the second row being 13, and so forth:

  0  - 0, 12
  1  - 13, 25
  2  - 26, 38
  3  - 39, 51
  4  - 52, 64
  5  - 65, 77
  6  - 78, 90
  7  - 91, 103
  8  - 104, 116
  9  - 117, 129
  10 - 130, 142
  11 - 143, 155
  12 - 156, 168

--]]
