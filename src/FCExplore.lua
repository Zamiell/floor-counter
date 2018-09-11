local FCExplore = {}

-- Includes
local json = require("json")
require("src/astar")
require("src/tiledmaphandler")
local FCGlobals = require("src/fcglobals")
local FCShapes  = require("src/fcshapes")

-- Constants
FCExplore.roomGridValue = 0
FCExplore.nullGridValue = 1

-- The main exploring function
function FCExplore:Start()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local startingRoomIndex = level:GetStartingRoomIndex()
  local rooms = level:GetRooms()
  local x, y

  -- Make an empty 13x13 grid and initialize all elements to the value that represents an obstacle
  -- The game uses a 0-indexed grid, but the library wants a 1-indexed grid
  FCGlobals.grid = {}
  for i = 1, 13 do
    FCGlobals.grid[i] = {}
    for j = 1, 13 do
      FCGlobals.grid[i][j] = FCExplore.nullGridValue
    end
  end

  -- Save the coordinates of the starting room
  x, y = FCExplore:GetXYFromGridIndex(startingRoomIndex)
  FCGlobals.startingRoom = {
    x = x,
    y = y,
  }

  -- Make an entry for each room on the floor
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomDesc = rooms:Get(i)
    local roomIndex = roomDesc.SafeGridIndex -- This is always the top-left index
    local roomData = roomDesc.Data
    local roomType = roomData.Type

    -- There will never be any special rooms in our main path (besides the boss room),
    -- so just ignore them to save CPU cycles
    -- Furthermore, we don't want to account for the Secret Room / moon strats
    if roomType == RoomType.ROOM_DEFAULT or -- 1
       roomType == RoomType.ROOM_BOSS then -- 5

      local roomVariant = roomData.Variant
      local floorString = "F11_1" -- Hard coded for now
      local roomShape = FCShapes[floorString][roomVariant]
      x, y = FCExplore:GetXYFromGridIndex(roomIndex)

      --[[
      local debugString = "Filling room: " .. tostring(roomIndex) .. " (" .. tostring(x) .. ", " .. tostring(y) .. ")"
      if roomIndex == startingRoomIndex then
        debugString = debugString .. " (START)"
      elseif roomType == RoomType.ROOM_BOSS then -- 5
        debugString = debugString .. " (BOSS)"
      end
      Isaac.DebugString(debugString)
      --]]

      -- Fill in the grid with values corresponding to a room (the opposite of an obstacle)
      FCGlobals.grid[y][x] = FCExplore.roomGridValue
      if roomShape == RoomShape.ROOMSHAPE_1x2 or -- 4 (1 wide x 2 tall)
         roomShape == RoomShape.ROOMSHAPE_IIV then -- 5 (1 wide x 2 tall, narrow)

        FCGlobals.grid[y + 1][x] = FCExplore.roomGridValue -- The square below

      elseif roomShape == RoomShape.ROOMSHAPE_2x1 or -- 6 (2 wide x 1 tall)
             roomShape == RoomShape.ROOMSHAPE_IIH then -- 7 (2 wide x 1 tall, narrow)

        FCGlobals.grid[y][x + 1] = FCExplore.roomGridValue -- The square to the right

      elseif roomShape == RoomShape.ROOMSHAPE_2x2 then -- 8 (2 wide x 2 tall)
        FCGlobals.grid[y][x + 1] = FCExplore.roomGridValue -- The square to the right
        FCGlobals.grid[y + 1][x] = FCExplore.roomGridValue -- The square below
        FCGlobals.grid[y + 1][x + 1] = FCExplore.roomGridValue -- The square to the bottom-right

      elseif roomShape == RoomShape.ROOMSHAPE_LTL then -- 9 (L room, top-left is missing)
        FCGlobals.grid[y + 1][x] = FCExplore.roomGridValue -- The square below
        FCGlobals.grid[y + 1][x - 1] = FCExplore.roomGridValue -- The square to the bottom-left

      elseif roomShape == RoomShape.ROOMSHAPE_LTR then -- 10 (L room, top-right is missing)
        FCGlobals.grid[y + 1][x] = FCExplore.roomGridValue -- The square below
        FCGlobals.grid[y + 1][x + 1] = FCExplore.roomGridValue -- The square to the bottom-right

      elseif roomShape == RoomShape.ROOMSHAPE_LBL then -- 11 (L room, bottom-left is missing)
        FCGlobals.grid[y][x + 1] = FCExplore.roomGridValue -- The square to the right
        FCGlobals.grid[y + 1][x + 1] = FCExplore.roomGridValue -- The square to the bottom-right

      elseif roomShape == RoomShape.ROOMSHAPE_LBR then -- 12 (L room, bottom-right is missing)
        FCGlobals.grid[y][x + 1] = FCExplore.roomGridValue -- The square to the right
        FCGlobals.grid[y + 1][x] = FCExplore.roomGridValue -- The square below
      end

      -- Save the coordinates of the boss room
      -- (note that the code only supports 1x1 boss rooms currently)
      if roomType == RoomType.ROOM_BOSS then -- 5
        FCGlobals.bossRoom = {
          x = x,
          y = y,
        }
      end
    end
  end

  --FCExplore:PrintGrid()

  local maphandler = TiledMapHandler(FCGlobals.grid)
  local astar_instance = AStar(maphandler)
  local path = astar_instance:findPath(FCGlobals.startingRoom, FCGlobals.bossRoom)
  local nodes = path:getNodes()

  --[[
  Isaac.DebugString("Path:")
  for i = 1, #nodes do
    local loc = nodes[i].location
    Isaac.DebugString(tostring(i) .. ": " .. " (" .. tostring(loc.x) .. ", " .. tostring(loc.y) .. ")")
  end
  --]]

  -- Find the direction from the starting room
  local firstRoom = nodes[1].location -- The first node will be the first room to go to next to the starting room
  local direction
  if firstRoom.x < FCGlobals.startingRoom.x and
     firstRoom.y == FCGlobals.startingRoom.y then

    direction = "left"

  elseif firstRoom.x > FCGlobals.startingRoom.x and
         firstRoom.y == FCGlobals.startingRoom.y then

    direction = "right"

  elseif firstRoom.x == FCGlobals.startingRoom.x and
         firstRoom.y > FCGlobals.startingRoom.y then

    direction = "down"

  else
    Isaac.DebugString("Error: Was not able to find the direction of the boss from the starting room.")
    return
  end
  --Isaac.DebugString("Boss is in direction: " .. tostring(direction))
  FCExplore:IncrementRightWays(direction)

  -- Reseed the floor and do it all again
  FCGlobals.reseedFrame = gameFrameCount + 1
end

-- Get the grid coordinates on a 13x13 grid
function FCExplore:GetXYFromGridIndex(idx)
  -- 0 --> (0, 0)
  -- 1 --> (1, 0)
  -- 13 --> (0, 1)
  -- 14 --> (1, 1)
  -- etc.
  local y = math.floor(idx / 13)
  local x = idx - (y * 13)

  -- Now, we add 1 to each x and y because the game uses a 0-indexed grid and
  -- the pathing library expects a 1-indexed grid
  return x + 1, y + 1
end

function FCExplore:PrintGrid()
  -- Print out a graphic representing the grid
  Isaac.DebugString("Grid:")
  for i = 1, #FCGlobals.grid do
    local rowString = "  " .. tostring(i) .. ": "
    if i < 10 then
      rowString = rowString .. " "
    end
    for j = 1, #FCGlobals.grid[i] do
      if FCGlobals.grid[i][j] == 1 then
        rowString = rowString .. " "
      else
        if i == FCGlobals.startingRoom.y and
           j == FCGlobals.startingRoom.x then

          rowString = rowString .. "!"

        elseif i == FCGlobals.bossRoom.y and
               j == FCGlobals.bossRoom.x then

          rowString = rowString .. "@"

        else
          rowString = rowString .. "X"
        end
      end
      rowString = rowString .. " "
    end
    Isaac.DebugString(rowString)
  end

  Isaac.DebugString("Starting room: " ..
                    "(" .. tostring(FCGlobals.startingRoom.x) .. ", " .. tostring(FCGlobals.startingRoom.y) .. ")")
  Isaac.DebugString("Boss room: " ..
                    "(" .. tostring(FCGlobals.bossRoom.x) .. ", " .. tostring(FCGlobals.bossRoom.y) .. ")")
end

function FCExplore:IncrementRightWays(direction)
  -- Find the number of exits in the starting room
  local minGridIndex = 0
  local maxGridIndex = 12
  local hasLeft = false
  if FCGlobals.startingRoom.x ~= minGridIndex and
     FCGlobals.grid[FCGlobals.startingRoom.y][FCGlobals.startingRoom.x - 1] == FCExplore.roomGridValue then

    hasLeft = true
  end
  local hasRight = false
  if FCGlobals.startingRoom.x ~= maxGridIndex and
     FCGlobals.grid[FCGlobals.startingRoom.y][FCGlobals.startingRoom.x + 1] == FCExplore.roomGridValue then

    hasRight = true
  end
  local hasDown = false
  if FCGlobals.startingRoom.y ~= maxGridIndex and
     FCGlobals.grid[FCGlobals.startingRoom.y + 1][FCGlobals.startingRoom.x] == FCExplore.roomGridValue then

    hasDown = true
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
    Isaac.DebugString("Error: Failed to get the room type for the starting room.")
    return
  end
  --Isaac.DebugString("Starting room is type: " .. roomType)

  local data = FCGlobals.saveData[roomType]
  data[direction] = data[direction] + 1
  data.total = data.total + 1
  Isaac.SaveModData(FCGlobals.FloorCounter, json.encode(FCGlobals.saveData))
end

return FCExplore
