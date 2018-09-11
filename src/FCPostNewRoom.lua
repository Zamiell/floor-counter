local FCPostNewRoom = {}

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function FCPostNewRoom:Main()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomIndex()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomIndexSafe = roomDesc.SafeGridIndex

  Isaac.DebugString("MC_POST_NEW_ROOM - " .. tostring(stage) .. "." .. tostring(stageType) ..
                    " (index " .. tostring(roomIndex) .. " / " .. tostring(roomIndexSafe) .. ")")
end

return FCPostNewRoom
