local FCPostGameStarted = {}

-- Includes
local json      = require("json")
local FCGlobals = require("src/fcglobals")


-- ModCallbacks.MC_POST_GAME_STARTED (15)
function FCPostGameStarted:Main(saveState)
  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()
  local player = game:GetPlayer(0)

  -- Don't do anything if we are quitting and continuing
  if saveState then
    return
  end

  -- Load the data from the "save1.dat" file
  local function loadJSON()
    FCGlobals.saveData = json.decode(Isaac.LoadModData(FCGlobals.FloorCounter))
  end
  if pcall(loadJSON) == false then
    Isaac.DebugString("Error: Failed to load FloorCounter data.")
    FCGlobals.saveData = {
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
  Isaac.ExecuteCommand("debug 8") -- Unlimited item charges
  Isaac.ExecuteCommand("debug 10") -- Kill everything
  player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
  player:AddCollectible(CollectibleType.COLLECTIBLE_MIND, 0, false) -- 333
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
  Isaac.ExecuteCommand("stage 11a") -- Go to The Chest
end

return FCPostGameStarted
