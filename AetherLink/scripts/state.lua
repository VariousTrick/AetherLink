-- scripts/state.lua
-- 【归魂碑 - 状态管理模块】
-- 最终修复版 v2：同时解决 on_load 冲突和循环依赖问题。

-- [重要] 移除了对 config.lua 的引用，以彻底切断循环依赖链。
-- local Config = require("scripts.config")

local State = {}

-- ============================================================================
-- 初始化
-- ============================================================================

--- [安全/可写] 初始化函数
-- 功能：只负责创建与“锚点”相关的表。玩家数据将延迟初始化。
function State.init()
    if not storage.anchors then
        storage.anchors = {}
        -- Config.log("State: 创建了 'anchors' 主数据表。") -- 移除日志，因为它依赖 Config
    end
    if not storage.anchors_by_surface then
        storage.anchors_by_surface = {}
        -- Config.log("State: 创建了 'anchors_by_surface' 地表索引表。")
    end
end

-- ============================================================================
-- 写入操作 (增/删)
-- ============================================================================

--- 注册一个新的传送锚点
-- @param entity LuaEntity: 实体对象
-- @param type_name string: 实体的名称
function State.add_anchor(entity, type_name)
    if not (entity and entity.valid) then
        return
    end

    local id = entity.unit_number
    local surface_index = entity.surface.index

    -- [修改] 不再依赖 Config，直接使用硬编码的字符串进行比较
    local default_name
    if type_name == "aetherlink-obelisk" then
        default_name = entity.surface.name
    else
        default_name = { "aetherlink-name.default-pylon", id }
    end

    local data = {
        id = id,
        entity = entity,
        unit_number = id,
        type = type_name,
        name = default_name,
        surface_index = surface_index,
        position = entity.position,
    }

    storage.anchors[id] = data

    if not storage.anchors_by_surface[surface_index] then
        storage.anchors_by_surface[surface_index] = {}
    end
    storage.anchors_by_surface[surface_index][id] = true
end

--- 移除一个传送锚点
function State.remove_anchor(unit_number)
    local data = storage.anchors[unit_number]
    if not data then
        return
    end

    local s_idx = data.surface_index
    if storage.anchors_by_surface[s_idx] then
        storage.anchors_by_surface[s_idx][unit_number] = nil
        if next(storage.anchors_by_surface[s_idx]) == nil then
            storage.anchors_by_surface[s_idx] = nil
        end
    end

    storage.anchors[unit_number] = nil
end

--- 更新锚点名称
function State.set_anchor_name(unit_number, new_name)
    if storage.anchors[unit_number] then
        storage.anchors[unit_number].name = new_name
    end
end

-- ============================================================================
-- 读取操作 (查)
-- ============================================================================

function State.get_all()
    return storage.anchors
end
function State.get_by_id(unit_number)
    return storage.anchors[unit_number]
end

function State.get_list_by_surface(surface_index)
    local list = {}
    local index_map = storage.anchors_by_surface[surface_index]
    if index_map then
        for id, _ in pairs(index_map) do
            if storage.anchors[id] then
                table.insert(list, storage.anchors[id])
            end
        end
    end
    return list
end

function State.get_active_surfaces()
    return storage.anchors_by_surface
end

--- 获取并确保指定玩家的数据表存在 (修复版：首次访问时初始化)
function State.get_player_data(player_index)
    -- [关键修复] 检查并创建根级别的 players 表
    if not storage.players then
        storage.players = {}
    end

    if not storage.players[player_index] then
        storage.players[player_index] = {}
    end
    return storage.players[player_index]
end

return State
