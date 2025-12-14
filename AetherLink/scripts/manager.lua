-- scripts/manager.lua
-- 【归魂碑 - 实体管理器】
-- 功能：监听实体的建造与拆除，维护 State 中的数据。

local Config = require("scripts.config")
local State = require("scripts/state")

local Manager = {}

-- ============================================================================
-- 事件处理函数
-- ============================================================================

--- 实体建造完成
function Manager.on_built(event)
    local entity = event.entity or event.created_entity
    if not (entity and entity.valid) then
        return
    end

    local name = entity.name
    if name == Config.Names.obelisk or name == Config.Names.pylon then
        State.add_anchor(entity, name)

        -- [恢复] 只有玩家手放时才发消息
        if event.player_index then
            local player = game.get_player(event.player_index)
            if player then
                local anchor = State.get_by_id(entity.unit_number)
                if anchor then
                    -- 使用本地化字符串，更规范
                    player.print({ "Created [entity=" .. name .. "] ", anchor.name, " at " .. string.format("X:%.0f, Y:%.0f", anchor.position.x, anchor.position.y) })
                end
            end
        end

        -- [自动刷新]
        local GUI = package.loaded["scripts.gui"]
        if GUI and GUI.refresh_all then
            GUI.refresh_all()
        end
    end
end

--- 实体被拆除/破坏
function Manager.on_mined(event)
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end

    local name = entity.name
    if name == Config.Names.obelisk or name == Config.Names.pylon then
        State.remove_anchor(entity.unit_number)

        -- [自动刷新]
        local GUI = package.loaded["scripts.gui"]
        if GUI and GUI.refresh_all then
            GUI.refresh_all()
        end
    end
end

return Manager
