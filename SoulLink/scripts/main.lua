-- scripts/main.lua
-- 【归魂碑 - 核心逻辑】
-- 最终修复版 v8：移除 flib，恢复原生事件监听，包含 on_gui_closed 修复。

local Config = require("scripts.config")
local GUI = require("scripts.gui")
local Manager = require("scripts.manager")
local State = require("scripts.state")

-- ============================================================================
-- 初始化
-- ============================================================================
script.on_init(State.init)
script.on_configuration_changed(State.init)
script.on_load(State.init)

-- ============================================================================
-- 过滤器定义
-- ============================================================================
local entity_filters = {
    { filter = "name", name = Config.Names.obelisk },
    { filter = "name", name = Config.Names.pylon },
}

-- ============================================================================
-- 事件监听注册
-- ============================================================================

-- 1. 界面交互

-- [快捷键] 打开/关闭主窗口
script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == Config.Names.shortcut then
        GUI.toggle_main_window(game.get_player(event.player_index))
    end
end)

-- [GUI 点击] 转发给 GUI 模块处理
script.on_event(defines.events.on_gui_click, GUI.handle_click)

-- [新增] 监听文本输入 (用于实时搜索)
script.on_event(defines.events.on_gui_text_changed, GUI.handle_search)

-- [GUI 确认] (输入框回车) 转发给 GUI 模块处理
script.on_event(defines.events.on_gui_confirmed, GUI.handle_confirm)

-- [GUI 关闭] 监听 E 键或 ESC 关闭
script.on_event(defines.events.on_gui_closed, function(event)
    -- [修复] 必须先检查 element 是否存在且有效
    if not (event.element and event.element.valid) then
        return
    end

    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    if event.element.name == Config.Names.main_frame then
        GUI.close_window(player)
    end
end)

-- 2. 逻辑循环

-- [Tick] 处理界面刷新
script.on_event(defines.events.on_tick, GUI.on_tick)

-- 3. 实体管理 (应用过滤器)

-- 建造事件
script.on_event(defines.events.on_built_entity, Manager.on_built, entity_filters)
script.on_event(defines.events.on_robot_built_entity, Manager.on_built, entity_filters)
script.on_event({ defines.events.script_raised_built, defines.events.script_raised_revive }, Manager.on_built)

-- 拆除/死亡事件
script.on_event(defines.events.on_player_mined_entity, Manager.on_mined, entity_filters)
script.on_event(defines.events.on_robot_mined_entity, Manager.on_mined, entity_filters)
script.on_event(defines.events.on_entity_died, Manager.on_mined, entity_filters)
script.on_event(defines.events.script_raised_destroy, Manager.on_mined)
