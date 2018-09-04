-- Register the mod (the second argument is the API version)
local FloorCounter = RegisterMod("Floor Counter", 1)

-- Global variables
local black = nil
local floorRooms = {}
local floorRoomsCurrentIndex = nil

--
-- Callback functions
--

local function PostRender()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

  if black ~= nil then
    local pos = Isaac.WorldToRenderPosition(room:GetCenterPos(), false)
    black:RenderLayer(0, pos)
  end
end

local function PostGameStarted()
  -- Local variables
  --local game = Game()
  --local seeds = game:GetSeeds()

  Isaac.DebugString("MC_POST_GAME_STARTED")

  -- Turn the screen black
  black = Sprite()
  black:Load("gfx/black.anm2", true)
  black:SetFrame("Default", 0)

  -- Remove the UI
  --[[
  if seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) == false then -- 10
    seeds:AddSeedEffect(SeedEffect.SEED_NO_HUD) -- 10
  end
  --]]
end

local function PostNewLevel()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  Isaac.DebugString("MC_POST_NEW_LEVEL - " .. tostring(stage) .. "." .. tostring(stageType))

  floorRooms = {}
  floorRoomsCurrentIndex = nil
end

local function PostNewRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomIndex = roomDesc.SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()

  Isaac.DebugString("MC_POST_NEW_ROOM - " .. tostring(stage) .. "." .. tostring(stageType) ..
                    " (index " .. tostring(roomIndex) .. ")")

  if floorRoomsCurrentIndex ~= nil then
    for i = 0, 7 do
      local door = room:GetDoor(i)
      if door ~= nil then
        floorRooms[floorRoomsCurrentIndex].doors[i] = door.TargetRoomIndex
        --Isaac.DebugString("Added destination " .. tostring(door.TargetRoomIndex) ..
        --                  "to door " .. tostring(i) .. " to floorRooms #" .. tostring(#floorRooms))
      end
    end
  end
end

local function getDirection(i)
  if i == -1 then
    return "NO_DOOR_SLOT"
  elseif i == 0 then
    return "LEFT0"
  elseif i == 1 then
    return "UP0"
  elseif i == 2 then
    return "RIGHT0"
  elseif i == 3 then
    return "DOWN0"
  elseif i == 4 then
    return "LEFT1"
  elseif i == 5 then
    return "UP1"
  elseif i == 6 then
    return "RIGHT1"
  elseif i == 7 then
    return "DOWN1"
  end
end

local function search(index, comingFromIndex, visitedRooms)
  -- Find this room in the list
  local room = nil
  for i = 1, #floorRooms do
    if floorRooms[i].index == index then
      room = floorRooms[i]
      break
    end
  end
  if room == nil then
    Isaac.DebugString("Error: Could not find a room with index: " .. tostring(index))
  end

  visitedRooms[#visitedRooms] = index

  -- Base case
  if room.type == 50 then
    -- We found the starting room
    -- Find the direction that we came from and print it out
    for i = 0, 7 do
      if room.doors[i] ~= nil then
        if room.doors[i] == comingFromIndex then
          Isaac.DebugString("BOSS IS IN DIRECTION: " .. getDirection(i))
          return true
        end
      end
    end
    Isaac.DebugString("Error: Found starting room but could not find the direction.")
  end

  -- Check all the doors that we have not been to yet
  for i = 0, 7 do
    if room.doors[i] ~= nil then
      local alreadyVisited = false
      for j = 1, #visitedRooms do
        if visitedRooms[j] == room.doors[i] then
          alreadyVisited = true
          break
        end
      end
      if alreadyVisited == false then
        if search(room.doors[i], index, visitedRooms) then
          return true
        end
      end
    end
  end

  return false
end

local function startExploring()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local rooms = level:GetRooms()

  -- Make an entry for each room on the floor
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local room = rooms:Get(i)
    local roomData = room.Data
    local roomType = roomData.Type
    local roomVariant = roomData.Variant
    if roomType ~= RoomType.ROOM_SECRET and -- 7
       roomType ~= RoomType.ROOM_SUPERSECRET then -- 8

      if roomVariant == 2 then
        -- Manually change the type for the starting room so that we can easily identify it later
        roomType = 50
      end
      floorRooms[#floorRooms + 1] = {
        index = room.SafeGridIndex,
        type = roomType,
        variant = roomVariant,
        doors = {},
      }
    end
  end

  -- Fill in the doors for each room
  -- (this requires actually going to each room)
  for i = 1, #floorRooms do
    floorRoomsCurrentIndex = i
    level:ChangeRoom(floorRooms[i].index)
  end
  floorRoomsCurrentIndex = nil

  Isaac.DebugString("Exploring complete.")

  Isaac.DebugString("Rooms on this floor:")
  for i = 1, #floorRooms do
    local room = floorRooms[i]
    Isaac.DebugString("  #" .. tostring(i) ..
                      " (index " .. tostring(room.index) .. ", " ..
                      "type " .. tostring(room.type) .. ", " ..
                      "variant " .. tostring(room.variant) .. "):")
    for j = 0, 7 do
      if room.doors[j] ~= nil then
        Isaac.DebugString("    Door " .. tostring(j) .. " --> " .. tostring(room.doors[j]))
      end
    end
  end

  -- Find the index of the boss room
  local bossIndex
  for i = 1, #floorRooms do
    if floorRooms[i].type == RoomType.ROOM_BOSS then -- 5
      bossIndex = floorRooms[i].index
      break
    end
  end

  -- Find the shortest path between the boss and the starting room
  search(bossIndex, nil, {})
end

local function ExecuteCmd(params, cmd) -- Bugged on macOS?
  Isaac.DebugString("MC_EXECUTE_CMD - " .. tostring(cmd) .. " " .. tostring(params))

  for i = 1, #params do
    Isaac.DebugString("  " .. tostring(i) .. " - " .. params[i])
  end

  if cmd == "go" then
    startExploring()
  elseif cmd == "zo" then
    print("Going to room:")
  end
end

FloorCounter:AddCallback(ModCallbacks.MC_POST_RENDER, PostRender) -- 2
FloorCounter:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, PostGameStarted) -- 15
FloorCounter:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, PostNewLevel) -- 18
FloorCounter:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, PostNewRoom) -- 19
FloorCounter:AddCallback(ModCallbacks.MC_EXECUTE_CMD, ExecuteCmd) -- 22

--[[

enum  	RoomType {
  ROOM_NULL = 0, ROOM_DEFAULT = 1, ROOM_SHOP = 2, ROOM_ERROR = 3,
  ROOM_TREASURE = 4, ROOM_BOSS = 5, ROOM_MINIBOSS = 6, ROOM_SECRET = 7,
  ROOM_SUPERSECRET = 8, ROOM_ARCADE = 9, ROOM_CURSE = 10, ROOM_CHALLENGE = 11,
  ROOM_LIBRARY = 12, ROOM_SACRIFICE = 13, ROOM_DEVIL = 14, ROOM_ANGEL = 15,
  ROOM_DUNGEON = 16, ROOM_BOSSRUSH = 17, ROOM_ISAACS = 18, ROOM_BARREN = 19,
  ROOM_CHEST = 20, ROOM_DICE = 21, ROOM_BLACK_MARKET = 22, ROOM_GREED_EXIT = 23,

seed with L room probably:
RQ21 KCRB

--]]
