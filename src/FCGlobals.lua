local FCGlobals = {}

-- Constants
RoomType.ROOM_STARTING = 50

-- Global variables
FCGlobals.saveData = nil
FCGlobals.reseedFrame = 0 -- The mod uses this to reseed on the next frame
FCGlobals.running = false -- Whether or not the mod is in a state of generating new floors over and over

-- Exploring variables
FCGlobals.grid = nil -- A 13x13 grid where nil represents empty space and a 0 represents a room
FCGlobals.startingRoom = nil -- The X and Y coordinates of the starting room
FCGlobals.bossRoom = nil -- The X and Y coordinates of the boss room

-- From: http://lua-users.org/wiki/SimpleRound
function FCGlobals:Round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

return FCGlobals
