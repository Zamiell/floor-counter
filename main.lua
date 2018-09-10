-- Register the mod (the second argument is the API version)
local FloorCounter = RegisterMod("Floor Counter", 1)

-- Includes
local json = require("json")

-- Constants
RoomType.ROOM_STARTING = 50

-- Global variables
local floorRooms = {}
local outputData = nil
local startingRoomDoors = {}
local reseedFrame = 0
local exploringFrame = 0
local running = false

--
-- Subroutines
--

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

local function incrementRightWays(direction)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  Isaac.DebugString("BOSS IS IN DIRECTION: " .. getDirection(direction))

  local hasLeft = false
  local hasRight = false
  local hasDown = false
  for i = 1, #startingRoomDoors do
    local door = startingRoomDoors[i]
    if door == DoorSlot.LEFT0 then -- 0
      hasLeft = true
    elseif door == DoorSlot.RIGHT0 then -- 2
      hasRight = true
    elseif door == DoorSlot.DOWN0 then -- 3
      hasDown = true
    end
  end

  local roomType
  if hasLeft and hasRight and hasDown then
    roomType = "leftRightDown"
  elseif hasLeft and hasRight then
    roomType = "leftRight"
  elseif hasLeft and hasDown then
    roomType = "leftDown"
  elseif hasRight and hasDown then
    roomType = "rightDown"
  else
    Isaac.DebugString("Error: Failed to get the room type.")
  end
  Isaac.DebugString("Found room type of: " .. roomType)
  local data = outputData[roomType]

  if direction == DoorSlot.LEFT0 then -- 0
    data.left = data.left + 1
  elseif direction == DoorSlot.RIGHT0 then -- 2
    data.right = data.right + 1
  elseif direction == DoorSlot.DOWN0 then -- 3
    data.down = data.down + 1
  end
  data.total = data.total + 1

  --[[
  if data.left then
    local leftPercent = data.left / data.total * 100
    Isaac.DebugString("Left: " .. tostring(leftPercent) .. "%")
  end
  if data.right then
    local rightPercent = data.right / data.total * 100
    Isaac.DebugString("Right: " .. tostring(rightPercent) .. "%")
  end
  if data.down then
    local downPercent = data.down / data.total * 100
    Isaac.DebugString("Down: " .. tostring(downPercent) .. "%")
  end
  Isaac.DebugString("Total floors tracked: " .. tostring(data.total))
  --]]

  Isaac.SaveModData(FloorCounter, json.encode(outputData))

  reseedFrame = gameFrameCount + 1
end

local function floorRoomGetSafeIndex(index)
  for i = 1, #floorRooms do
    for j = 1, #floorRooms[i].indexes do
      if floorRooms[i].indexes[j] == index then
        return floorRooms[i].safeIndex
      end
    end
  end
end

local function search(index, comingFromIndex, visitedRooms)
  -- Find this room in the list
  local room = nil
  for i = 1, #floorRooms do
    for j = 1, #floorRooms[i].indexes do
      if floorRooms[i].indexes[j] == index then
        room = floorRooms[i]
        break
      end
      if room ~= nil then
        break
      end
    end
  end
  if room == nil then
    Isaac.DebugString("Error: Could not find a room with an index of: " .. tostring(index))
    return false
  end

  visitedRooms[#visitedRooms + 1] = room.safeIndex

  -- Base case
  if room.type == RoomType.ROOM_STARTING then -- 50
    -- We found the starting room, so count the doors
    startingRoomDoors = {}
    for i = 0, 7 do
      if room.doors[i] ~= nil then
        -- Add it to the list
        startingRoomDoors[#startingRoomDoors + 1] = i
      end
    end

    -- Find the direction that we came from and print it out
    for i = 0, 7 do
      if room.doors[i] ~= nil then
        --Isaac.DebugString("Checking door " .. tostring(i) .. ": " .. tostring(room.doors[i]))
        if floorRoomGetSafeIndex(room.doors[i]) == floorRoomGetSafeIndex(comingFromIndex) then
          incrementRightWays(i)
          return true
        end
      end
    end
    Isaac.DebugString("Error: Found starting room but could not find the direction.")
    return true
  end

  -- Check all the doors that we have not been to yet
  Isaac.DebugString("We are on room: " .. tostring(room.safeIndex) .. " (" .. tostring(room.variant) .. ")")
  Isaac.DebugString("Visited rooms are:")
  for i = 1, #visitedRooms do
    Isaac.DebugString(" " .. tostring(i) .. ": " .. tostring(visitedRooms[i]))
  end
  for i = 0, 7 do
    if room.doors[i] ~= nil then
      local safeIndex = floorRoomGetSafeIndex(room.doors[i])
      local alreadyVisited = false
      for j = 1, #visitedRooms do
        if visitedRooms[j] == safeIndex then
          alreadyVisited = true
          break
        end
      end
      if alreadyVisited == false then
        --[[
        Isaac.DebugString("Searching through room unsafe " .. tostring(index) ..
                          " / safe " .. tostring(room.safeIndex) ..
                          " (" .. tostring(room.variant) .. "), " ..
                          "door " .. tostring(i) .. " to room index: " .. tostring(room.doors[i]))
        --]]
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
  local startingIndex = level:GetStartingRoomIndex()

  -- Make an entry for each room on the floor
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomDesc = rooms:Get(i)
    local roomIndex = roomDesc.SafeGridIndex
    local roomData = roomDesc.Data
    local roomType = roomData.Type
    local roomVariant = roomData.Variant
    if roomIndex == startingIndex then
      -- Manually change the type for the starting room so that we can easily identify it later
      roomType = RoomType.ROOM_STARTING -- 50
    end
    floorRooms[#floorRooms + 1] = {
      safeIndex = roomIndex,
      indexes   = {roomIndex},
      -- A room can have more than one index; the rest will be filled in later
      type      = roomType,
      variant   = roomVariant,
      doors     = nil, -- This will be filled in when we get to the room
    }
  end

  -- Fill in the doors for each room
  -- (this requires actually going to each room)
  Isaac.DebugString("Beginning to explore.")
  for i = 1, #floorRooms do
    local floorRoom = floorRooms[i]
    level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
    Isaac.DebugString("Exploring room: " .. tostring(floorRoom.safeIndex))
    level:ChangeRoom(floorRoom.safeIndex)
  end

  Isaac.DebugString("Exploring complete (1/2). Rooms on this floor:")
  for i = 1, #floorRooms do
    local floorRoom = floorRooms[i]
    Isaac.DebugString("  #" .. tostring(i) ..
                      " (safeIndex " .. tostring(floorRoom.safeIndex) .. ", " ..
                      "type " .. tostring(floorRoom.type) .. ", " ..
                      "variant " .. tostring(floorRoom.variant) .. "):")
    for j = 0, 7 do
      if floorRoom.doors[j] ~= nil then
        Isaac.DebugString("    Door " .. tostring(j) .. " --> " .. tostring(floorRoom.doors[j]))
      end
    end
  end

  Isaac.DebugString("Filling in missing indexes.")
  for i = 1, #floorRooms do
    local floorRoom = floorRooms[i]
    Isaac.DebugString("i: " .. tostring(i) .. ", safeIndex: " .. tostring(floorRoom.safeIndex) ..
                      ", variant: " .. tostring(floorRoom.variant))
    for j = 0, 7 do
      if floorRoom.doors[j] ~= nil then
        -- Check to see if there is a corresponding entry in the floorRooms table for this door location
        local foundMatchingRoom = false
        for k = 1, #floorRooms do
          local room2 = floorRooms[k]
          for l = 1, #room2.indexes do
            if room2.indexes[l] == floorRoom.doors[j] then
              foundMatchingRoom = true
              break
            end
          end
          if foundMatchingRoom then
            break
          end
        end
        if foundMatchingRoom == false then
          -- We need to manually travel to this room to find out what its safe index is
          --Isaac.DebugString("  Filling in index: " .. tostring(floorRoom.doors[j]))
          level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
          level:ChangeRoom(floorRoom.doors[j])
        end
      end
    end
  end

  Isaac.DebugString("Exploring complete (2/2). Rooms on this floor:")
  for i = 1, #floorRooms do
    local floorRoom = floorRooms[i]
    Isaac.DebugString("  #" .. tostring(i) ..
                      " (safeIndex " .. tostring(floorRoom.safeIndex) .. ", " ..
                      "type " .. tostring(floorRoom.type) .. ", " ..
                      "variant " .. tostring(floorRoom.variant) .. "):")
    for j = 0, 7 do
      if floorRoom.doors[j] ~= nil then
        Isaac.DebugString("    Door " .. tostring(j) .. " --> " .. tostring(floorRoom.doors[j]))
      end
    end
  end

  -- Find the index of the boss room
  local bossIndex
  for i = 1, #floorRooms do
    if floorRooms[i].type == RoomType.ROOM_BOSS then -- 5
      bossIndex = floorRooms[i].safeIndex
      break
    end
  end

  -- Find the shortest path between the boss and the starting room
  search(bossIndex, nil, {})

  -- Go back to the starting room
  --level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  --level:ChangeRoom(startingIndex)
end

--
-- Callback functions
--

function FloorCounter:PostUpdate()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  if reseedFrame ~= 0 and
     gameFrameCount >= reseedFrame then

    reseedFrame = 0
    Isaac.ExecuteCommand("reseed")
    return
  end

  if exploringFrame ~= 0 and
     gameFrameCount >= exploringFrame then

    exploringFrame = 0
    startExploring()
  end
end

function FloorCounter:UseItem()
  running = true
  startExploring()
end

function FloorCounter:PostGameStarted()
  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()
  local player = game:GetPlayer(0)

  -- Load the data from the "save1.dat" file
  local function loadJSON()
    outputData = json.decode(Isaac.LoadModData(FloorCounter))
  end
  if pcall(loadJSON) == false then
    Isaac.DebugString("Error: Failed to load FloorCounter data.")
    outputData = {
      leftRight = {
        left = 0,
        right = 0,
        total = 0,
      },
      leftDown = {
        left = 0,
        down = 0,
        total = 0,
      },
      rightDown = {
        right = 0,
        down = 0,
        total = 0,
      },
      leftRightDown = {
        left = 0,
        right = 0,
        down = 0,
        total = 0,
      },
    }
  end

  -- Make sure that the "Total Curse Immunity" easter egg is on (the "BLCK CNDL" seed)
  if seeds:HasSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES) == false and -- 70
     Isaac.GetChallenge() == 0 then
     -- If we don't check for challenges, this can cause an infinite loop when entering Challenge #1, for example

    seeds:AddSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES) -- 70
    Isaac.DebugString("Added the \"Total Curse Immunity\" easter egg.")
  end

  Isaac.ExecuteCommand("debug 3") -- Invincibility
  Isaac.ExecuteCommand("debug 5") -- Show room info
  Isaac.ExecuteCommand("debug 10") -- Kill everything
  player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
  player:AddCollectible(CollectibleType.COLLECTIBLE_MIND, 0, false) -- 333
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  Isaac.ExecuteCommand("stage 11a") -- Go to The Chest
end

function FloorCounter:PostNewLevel()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  Isaac.DebugString("MC_POST_NEW_LEVEL - " .. tostring(stage) .. "." .. tostring(stageType))

  floorRooms = {}
  if FloorCounter:CheckDupeRooms() then
    return
  end

  if running then
    -- Mark to start exploring one frame from now
    exploringFrame = gameFrameCount + 1
  end
end

function FloorCounter:PostNewRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomIndex()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomIndexSafe = roomDesc.SafeGridIndex
  local room = game:GetRoom()

  Isaac.DebugString("MC_POST_NEW_ROOM - " .. tostring(stage) .. "." .. tostring(stageType) ..
                    " (index " .. tostring(roomIndex) .. ")")

  -- Find this room in the list
  if floorRooms == nil or
     #floorRooms == 0 then

    return
  end
  local floorRoom = nil
  for i = 1, #floorRooms do
    if floorRooms[i].safeIndex == roomIndexSafe then
      floorRoom = floorRooms[i]
      break
    end
  end
  if floorRoom == nil then
    Isaac.DebugString("Error: Could not find a room with roomIndexSafe: " .. tostring(roomIndexSafe))
    return
  end

  -- Add the unsafe index to the indexes list, if necessary
  -- (rooms can have many indexes depending on which entrance you arrive at)
  local foundIndex = false
  for i = 1, #floorRoom.indexes do
    if floorRoom.indexes[i] == roomIndex then
      foundIndex = true
      break
    end
  end
  if foundIndex == false then
    floorRoom.indexes[#floorRoom.indexes + 1] = roomIndex
    --[[
    Isaac.DebugString("Filled in index " .. tostring(roomIndex) ..
                      " to safeIndex room: " .. tostring(floorRoom.safeIndex))
    --]]
  end

  -- Fill in the door locations for this room
  if floorRoom.doors ~= nil then
    -- We have already been to this room and the doors are already filled in
    return
  end
  floorRoom.doors = {}
  for i = 0, 7 do
    local door = room:GetDoor(i)
    if door ~= nil and
       door.TargetRoomType == RoomType.ROOM_DEFAULT then -- 1

      floorRoom.doors[i] = door.TargetRoomIndex
      --Isaac.DebugString("Added destination " .. tostring(door.TargetRoomIndex) ..
      --                  "to door " .. tostring(i) .. " to floorRooms #" .. tostring(#floorRooms))
    end
  end
end

function FloorCounter:ExecuteCmd(cmd, params)
  Isaac.DebugString("MC_EXECUTE_CMD - " .. tostring(cmd) .. " " .. tostring(params))

  for i = 1, #params do
    Isaac.DebugString("  " .. tostring(i) .. " - " .. params[i])
  end

  if cmd == "go" then
    FloorCounter:UseItem()
  end
end

function FloorCounter:CheckDupeRooms()
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

FloorCounter:AddCallback(ModCallbacks.MC_POST_UPDATE, FloorCounter.PostUpdate) -- 1
FloorCounter:AddCallback(ModCallbacks.MC_USE_ITEM, FloorCounter.UseItem, CollectibleType.COLLECTIBLE_D6) -- 3
FloorCounter:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, FloorCounter.PostGameStarted) -- 15
FloorCounter:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, FloorCounter.PostNewLevel) -- 18
FloorCounter:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, FloorCounter.PostNewRoom) -- 19
FloorCounter:AddCallback(ModCallbacks.MC_EXECUTE_CMD, FloorCounter.ExecuteCmd) -- 22
