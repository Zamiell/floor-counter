local FCPostNewLevel = {}

-- Includes
local FCGlobals = require("src/fcglobals")
local FCExplore = require("src/fcexplore")

-- ModCallbacks.MC_POST_NEW_LEVEL (18)
function FCPostNewLevel:Main()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  Isaac.DebugString("MC_POST_NEW_LEVEL - " .. tostring(stage) .. "." .. tostring(stageType))

  -- Check for duplicate rooms
  -- (this should exactly emulate what Racing+ does)
  if FCPostNewLevel:CheckDupeRooms() then
    return
  end

  if FCGlobals.running then
    FCExplore:Start()
  end
end

function FCPostNewLevel:CheckDupeRooms()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local rooms = level:GetRooms()

  local roomIDs = {}
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomData = rooms:Get(i).Data
    if roomData.Type == RoomType.ROOM_DEFAULT and -- 1
       roomData.Variant ~= 2 and -- This is the starting room
       roomData.Variant ~= 0 then -- This is the starting room on The Chest / Dark Room

      -- Normalize the room ID (to account for flipped rooms)
      local roomID = roomData.Variant
      while roomID > 10000 do
        -- The 3 flipped versions of room #1 would be #10001, #20001, and #30001
        roomID = roomID - 10000
      end

      -- Check to see if this room ID appears multiple times on this floor
      for j = 1, #roomIDs do
        if roomID == roomIDs[j] then
          Isaac.DebugString("Duplicate room " .. tostring(roomID) .. " found (on same floor) - reseeding.")
          Isaac.ExecuteCommand("reseed")
          return true
        end
      end

      -- Keep track of this room ID
      roomIDs[#roomIDs + 1] = roomID
    end
  end
end

return FCPostNewLevel
