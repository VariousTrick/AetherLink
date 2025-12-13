-- scripts/gui.lua
-- 【归魂碑 - 界面模块】
-- 最终修复版 v10：基于 V9 结构修正。修复图标报错，实现右侧纯监控布局。

local Config = require("scripts.config")
local State = require("scripts.state")

local GUI = {}

-- 标记需要刷新的玩家
local players_to_refresh = {}

-- 常量定义
local NAMES = {
    frame = Config.Names.main_frame,
    titlebar = "soullink_titlebar",
    close_btn = "soullink_close_btn",

    -- [新增] 标题栏新按钮
    pin_btn = "soullink_pin_btn",
    search_btn = "soullink_search_btn",
    search_textfield = "soullink_search_text",

    -- 容器
    left_scroll = "soullink_left_scroll",
    right_pane = "soullink_right_pane",
    camera = "soullink_detail_camera",
    -- info_flow 已删除，不再需要

    -- 改名窗口
    rename_frame = "soullink_rename_frame",
    rename_textfield = "soullink_rename_text",
    rename_confirm = "soullink_rename_confirm",

    -- 动态前缀
    btn_expand = "soullink_expand_",
    btn_fav = "soullink_fav_",
    btn_select = "soullink_sel_",
    btn_edit = "soullink_edit_",
    btn_teleport = "soullink_tp_",
}

-- ============================================================================
-- 辅助工具
-- ============================================================================

--- 递归查找 GUI 元素 (最稳健的查找方式)
local function find_element_by_name(parent, name)
    if parent.name == name then
        return parent
    end
    if parent.children then
        for _, child in pairs(parent.children) do
            local found = find_element_by_name(child, name)
            if found then
                return found
            end
        end
    end
    return nil
end

--- 智能排序 (字符串 vs 本地化表)
local function sort_anchors(a, b)
    local ta, tb = type(a.name), type(b.name)
    if ta ~= tb then
        return ta == "string"
    end
    if ta == "string" then
        return a.name < b.name
    end
    return a.name[2] < b.name[2]
end

-- ============================================================================
-- 界面构建与更新
-- ============================================================================

--- [右侧] 更新详情面板 (纯监控，无额外信息)
local function update_detail_pane(frame, anchor_id)
    local anchor = State.get_by_id(anchor_id)
    if not anchor then
        return
    end

    -- 使用递归查找确保找到 camera
    local camera = find_element_by_name(frame, NAMES.camera)

    if camera then
        camera.position = anchor.position
        camera.surface_index = anchor.surface_index
        camera.zoom = 0.2
    end
end

--- [左侧] 创建列表的一行
local function create_list_row(parent, anchor, player_data, is_header, indent)
    local is_fav = player_data.favorites and player_data.favorites[anchor.id]
    local s_idx = anchor.surface_index
    local is_expanded = player_data.expanded_surfaces and player_data.expanded_surfaces[s_idx]

    -- [视觉优化] 容器选择
    -- 标题行(Header)使用带背景的 frame，子行使用透明 flow
    local row
    if is_header then
        -- 使用 subheader_frame 创建明显的分割条效果 (深色背景)
        row = parent.add({
            type = "frame",
            style = "subheader_frame",
            direction = "horizontal",
        })
        row.style.horizontally_stretchable = true
        row.style.padding = 2
        row.style.bottom_margin = 2
    else
        -- 普通行保持透明
        row = parent.add({
            type = "flow",
            direction = "horizontal",
            style_mods = { vertical_align = "center", bottom_margin = 0 },
        })
        row.style.horizontally_stretchable = true
    end

    -- 1. 折叠箭头 (使用本地化 Tooltip)
    if is_header then
        local sprite = is_expanded and "utility/dropdown" or "utility/play"
        local tooltip = is_expanded and { "gui.soullink-collapse" } or { "gui.soullink-expand" }
        row.add({
            type = "sprite-button",
            name = NAMES.btn_expand .. s_idx,
            sprite = sprite,
            style = "frame_action_button",
            tags = { surface_index = s_idx },
            tooltip = tooltip,
        })
    else
        row.add({ type = "empty-widget", style_mods = { width = 28 } })
    end

    if indent then
        row.add({ type = "label", caption = "└", style_mods = { font_color = { 0.5, 0.5, 0.5 }, right_margin = 4 } })
    end

    -- 2. 收藏按钮 (修改：使用星星和非星星图标)
    local fav_sprite = is_fav and "soullink-icon-star" or "soullink-icon-notstar" -- [修改]
    local fav_tooltip = is_fav and { "gui.soullink-unfavorite" } or { "gui.soullink-favorite" }
    row.add({
        type = "sprite-button",
        name = NAMES.btn_fav,
        sprite = fav_sprite, -- [修改] 引用变量
        style = "frame_action_button",
        tags = { anchor_id = anchor.id },
        tooltip = fav_tooltip,
        -- toggled = is_fav, -- [删除] 不再需要 toggled 样式，直接换图
    })

    -- [修复] 检查当前行是否处于编辑模式
    local is_editing = player_data.editing_anchor_id == anchor.id

    if is_editing then
        -- === 编辑模式：显示输入框和确认钩子 ===

        -- 准备初始文本 (如果是默认名字的 table，则显示为空，如果是自定义名字 string，则显示原名)
        local current_text = (type(anchor.name) == "string") and anchor.name or ""

        -- 输入框
        local textfield = row.add({
            type = "textfield",
            name = NAMES.rename_textfield,
            text = current_text,
            tags = { anchor_id = anchor.id }, -- 方便回车事件获取 ID
        })
        textfield.style.horizontally_stretchable = true
        textfield.style.minimal_width = 100
        textfield.focus() -- 自动聚焦

        -- 确认按钮 (打钩)
        row.add({
            type = "sprite-button",
            name = NAMES.rename_confirm,
            sprite = "utility/check_mark", -- 使用原版打钩图标
            style = "frame_action_button",
            tags = { anchor_id = anchor.id },
            tooltip = "确认改名",
        })
    else
        -- === 正常模式：显示名字按钮和铅笔 ===

        -- 3. 名字按钮 (原代码)
        local name_btn = row.add({
            type = "button",
            name = NAMES.btn_select,
            caption = anchor.name,
            style = "list_box_item",
            tags = { anchor_id = anchor.id },
            mouse_button_filter = { "left" },
        })
        name_btn.style.horizontally_stretchable = true
        name_btn.style.horizontal_align = "left"
        if is_header then
            name_btn.style.font = "default-bold"
        end

        -- 4. 改名按钮 (原代码，图标已替换)
        row.add({
            type = "sprite-button",
            name = NAMES.btn_edit,
            sprite = "soullink-icon-rename", -- 确保这里用的是新图标
            style = "frame_action_button",
            tags = { anchor_id = anchor.id },
            tooltip = { "gui.soullink-rename" },
        })
    end

    -- 5. 传送小按钮
    row.add({
        type = "sprite-button",
        name = NAMES.btn_teleport,
        sprite = "soullink-icon-teleport", -- [修改] 替换图标
        style = "frame_action_button",
        tags = { anchor_id = anchor.id },
        tooltip = { "gui.soullink-teleport" },
    })
end

--- 刷新左侧列表 (V9版逻辑保持不变)
local function update_list_view(frame, player)
    local scroll = find_element_by_name(frame, NAMES.left_scroll)
    if not scroll then
        Config.log("GUI 错误: 未找到滚动列表容器。")
        return
    end

    scroll.clear()

    local player_data = State.get_player_data(player.index)
    local all_anchors = State.get_all()

    -- [新增] 1. 获取搜索框文本
    local search_text = ""
    -- 先尝试找到标题栏，再找里面的输入框
    local titlebar = find_element_by_name(frame, NAMES.titlebar)
    if titlebar and titlebar[NAMES.search_textfield] then
        search_text = titlebar[NAMES.search_textfield].text
        -- 转为小写，实现不区分大小写的搜索
        search_text = string.lower(search_text)
    end

    -- 数据分组
    local favorites = {}
    local surface_map = {}

    for _, data in pairs(all_anchors) do
        -- [新增] 2. 搜索匹配判断
        local match = true

        -- 只有当搜索框有内容时才进行过滤
        if search_text ~= "" then
            match = false -- 默认为不匹配

            if type(data.name) == "string" then
                -- 如果名字是字符串（改过名的），检查是否包含搜索词
                if string.find(string.lower(data.name), search_text, 1, true) then
                    match = true
                end
            elseif type(data.name) == "table" and data.id then
                -- 如果名字是默认的本地化表（如 {"name", id}），则搜索 ID
                if string.find(tostring(data.id), search_text, 1, true) then
                    match = true
                end
            end
        end

        -- [新增] 3. 只有匹配成功才加入列表
        if match then
            -- --- 下面是原来的分组逻辑 (被包裹在 if match then 里) ---

            if player_data.favorites and player_data.favorites[data.id] then
                table.insert(favorites, data)
            end

            local s = data.surface_index
            if not surface_map[s] then
                surface_map[s] = { pylons = {} }
            end

            if data.type == Config.Names.obelisk then
                surface_map[s].obelisk = data
            else
                table.insert(surface_map[s].pylons, data)
            end

            -- --- 原有逻辑结束 ---
        end
    end

    -- 渲染收藏夹
    if #favorites > 0 then
        scroll.add({ type = "label", caption = "★ 特别关注", style = "caption_label" })
        table.sort(favorites, sort_anchors)
        for _, anchor in ipairs(favorites) do
            create_list_row(scroll, anchor, player_data, false, false)
        end
        scroll.add({ type = "line", style_mods = { top_margin = 5, bottom_margin = 5 } })
    end

    -- 渲染地表树
    local s_idxs = {}
    for k in pairs(surface_map) do
        table.insert(s_idxs, k)
    end
    table.sort(s_idxs)

    for _, s in ipairs(s_idxs) do
        local group = surface_map[s]
        if group.obelisk then
            create_list_row(scroll, group.obelisk, player_data, true, false)

            if player_data.expanded_surfaces and player_data.expanded_surfaces[s] then
                table.sort(group.pylons, sort_anchors)
                if #group.pylons > 0 then
                    local sub_flow = scroll.add({ type = "flow", direction = "vertical", style_mods = { left_margin = 0 } })
                    sub_flow.style.horizontally_stretchable = true
                    for _, pylon in ipairs(group.pylons) do
                        create_list_row(sub_flow, pylon, player_data, false, true)
                    end
                else
                    scroll.add({ type = "label", caption = "(无中继节点)", style_mods = { font_color = { 0.5, 0.5, 0.5 }, left_margin = 40 } })
                end
            end
        end
    end

    -- 默认选中逻辑
    local current_group = surface_map[player.surface.index]
    if current_group and current_group.obelisk then
        -- 仅当首次打开且没有操作时，更新右侧 (这里简化为总是尝试更新默认)
        -- 注意：如果玩家正在看别的，这里可能会强制切回，但对于 V9 逻辑这是可接受的默认行为
        update_detail_pane(frame, current_group.obelisk.id)
    end
end

-- ============================================================================
-- 公开接口与事件处理
-- ============================================================================

function GUI.toggle_main_window(player)
    local frame = player.gui.screen[NAMES.frame]
    if frame then
        GUI.close_window(player)
    else
        -- 创建新窗口 (V9 逻辑：直接在这里创建)
        frame = player.gui.screen.add({ type = "frame", name = NAMES.frame, direction = "vertical" })

        -- 标题栏
        local titlebar = frame.add({ type = "flow", name = NAMES.titlebar, direction = "horizontal", style = "flib_titlebar_flow" })
        titlebar.drag_target = frame
        titlebar.add({ type = "label", style = "frame_title", caption = { "gui-title.soullink-main" }, ignored_by_interaction = true })
        titlebar.add({ type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true })

        -- [新增] 获取状态
        local p_data = State.get_player_data(player.index)

        -- [新增] 搜索框 (位置：搜索按钮左侧)
        local search_visible = p_data.show_search == true
        local search_field = titlebar.add({
            type = "textfield",
            name = NAMES.search_textfield,
            visible = search_visible, -- 根据状态显示
            style_mods = { width = 100, top_margin = -2 }, -- 微调样式对齐
        })

        -- [新增] 搜索按钮
        titlebar.add({
            type = "sprite-button",
            name = NAMES.search_btn,
            style = "frame_action_button", -- 保持一致风格
            sprite = "soullink-icon-search",
            tooltip = "搜索", -- 建议加上本地化 key
        })

        -- [新增] 固定按钮
        local pin_style = p_data.is_pinned and "flib_selected_frame_action_button" or "frame_action_button"
        titlebar.add({
            type = "sprite-button",
            name = NAMES.pin_btn,
            style = pin_style,
            sprite = "soullink-icon-pin",
            tooltip = "固定窗口",
        })

        -- 原有的关闭按钮

        titlebar.add({ type = "sprite-button", name = NAMES.close_btn, style = "frame_action_button", sprite = "utility/close" })

        -- 主体
        local body = frame.add({ type = "flow", direction = "horizontal" })

        -- 左侧
        local left = body.add({ type = "frame", style = "inside_deep_frame", direction = "vertical", style_mods = { padding = 4 } })
        local scroll = left.add({
            type = "scroll-pane",
            name = NAMES.left_scroll,
            style = "flib_naked_scroll_pane",
            horizontal_scroll_policy = "never",
        })
        scroll.style.minimal_width = 350
        scroll.style.minimal_height = 400
        scroll.style.maximal_height = 800

        -- 右侧 (修正：纯监控布局)
        -- 去掉 style_mods，手动设置样式
        local right = body.add({ type = "frame", style = "inside_deep_frame", direction = "vertical" })
        right.style.padding = 0
        right.style.left_margin = 5

        -- 摄像头
        local camera = right.add({
            type = "camera",
            name = NAMES.camera,
            position = { 0, 0 },
            surface_index = 1,
            zoom = 0.2,
        })

        -- [关键修复] 手动设置样式属性，确保摄像头有大小且能拉伸
        camera.style.minimal_width = 300
        camera.style.minimal_height = 200
        camera.style.vertically_stretchable = true
        camera.style.horizontally_stretchable = true

        -- [已删除] 移除了 info_flow 的创建

        -- [修复] 启用持续自动居中属性
        -- 这样当列表展开/折叠导致窗口高度变化时，它会始终保持在屏幕中间
        frame.auto_center = true

        player.opened = frame

        local p_data = State.get_player_data(player.index)
        p_data.is_gui_open = true

        update_list_view(frame, player)
    end
end

function GUI.close_window(player)
    local frame = player.gui.screen[NAMES.frame]
    if frame then
        frame.destroy()
    end

    local rename = player.gui.screen[NAMES.rename_frame]
    if rename then
        rename.destroy()
    end

    local p_data = State.get_player_data(player.index)
    p_data.is_gui_open = false
end

function GUI.handle_click(event)
    local element = event.element
    if not (element and element.valid) then
        return
    end

    local name = element.name
    local player = game.get_player(event.player_index)
    local frame = player.gui.screen[NAMES.frame]

    -- [关键修复] 把这一行提到这里！
    -- 这样下面的所有按钮逻辑（搜索、固定、关闭等）都能使用 p_data
    local p_data = State.get_player_data(player.index)

    -- 全局关闭
    if name == NAMES.close_btn then
        GUI.close_window(player)
        return
    end

    -- [新增] 固定按钮逻辑
    if name == NAMES.pin_btn then
        if not p_data.is_pinned then
            p_data.is_pinned = false
        end
        p_data.is_pinned = not p_data.is_pinned

        element.style = p_data.is_pinned and "flib_selected_frame_action_button" or "frame_action_button"
        return
    end

    -- [新增] 搜索按钮逻辑
    if name == NAMES.search_btn then
        -- 切换状态
        if p_data.show_search == nil then
            p_data.show_search = false
        end -- 增加一个初始化保护
        p_data.show_search = not p_data.show_search

        -- 切换输入框可见性
        -- element.parent 就是 titlebar
        local titlebar = element.parent
        if titlebar[NAMES.search_textfield] then
            titlebar[NAMES.search_textfield].visible = p_data.show_search

            -- 如果是关闭搜索，清空内容并刷新
            if not p_data.show_search then
                titlebar[NAMES.search_textfield].text = ""
                update_list_view(frame, player)
            end
        end
        return
    end
    --[[     local p_data = State.get_player_data(player.index) -- 获取玩家数据 ]]

    -- [修改] 改名确认 (点击钩子)
    if name == NAMES.rename_confirm then
        -- 找到旁边的文本框
        -- 结构: row -> [..., textfield, confirm_btn, ...]
        -- textfield 是 confirm_btn 的前一个兄弟元素
        local textfield = element.parent[NAMES.rename_textfield]
        if textfield and element.tags.anchor_id then
            State.set_anchor_name(element.tags.anchor_id, textfield.text)
            p_data.editing_anchor_id = nil -- [关键] 退出编辑模式
            if frame then
                update_list_view(frame, player)
            end
        end
        return
    end

    -- 以下操作需要主窗口存在
    if not frame then
        return
    end

    -- 修改传送逻辑 (检查固定状态)
    if name == NAMES.btn_teleport then
        local anchor = State.get_by_id(element.tags.anchor_id)
        if anchor then
            player.teleport(anchor.position, anchor.surface_index)
            -- [修改] 如果没有固定，才关闭
            if not p_data.is_pinned then
                GUI.close_window(player)
            end
        end
        return
    end

    -- 选中预览
    if string.find(name, NAMES.btn_select) then
        update_detail_pane(frame, element.tags.anchor_id)
        return
    end

    -- 折叠/展开
    if string.find(name, NAMES.btn_expand) then
        local s_idx = element.tags.surface_index
        local p_data = State.get_player_data(player.index)
        if not p_data.expanded_surfaces then
            p_data.expanded_surfaces = {}
        end
        p_data.expanded_surfaces[s_idx] = not p_data.expanded_surfaces[s_idx]
        update_list_view(frame, player)
        return
    end

    -- 收藏
    if string.find(name, NAMES.btn_fav) then
        local id = element.tags.anchor_id
        local p_data = State.get_player_data(player.index)
        if not p_data.favorites then
            p_data.favorites = {}
        end
        p_data.favorites[id] = not p_data.favorites[id]
        update_list_view(frame, player)
        return
    end

    -- [修改] 打开改名 (点击铅笔)
    if string.find(name, NAMES.btn_edit) then
        -- 设置当前正在编辑的 ID
        p_data.editing_anchor_id = element.tags.anchor_id
        -- 刷新列表，该行会自动变成输入框
        update_list_view(frame, player)
        return
    end
end

-- 确认事件 (改名框回车)
function GUI.handle_confirm(event)
    if event.element.name == NAMES.rename_textfield then
        local player = game.get_player(event.player_index)
        local frame = player.gui.screen[Config.Names.main_frame]
        local anchor_id = event.element.tags.anchor_id

        if anchor_id then
            State.set_anchor_name(anchor_id, event.element.text)

            local p_data = State.get_player_data(player.index)
            p_data.editing_anchor_id = nil -- [关键] 退出编辑模式

            if frame then
                update_list_view(frame, player)
            end
        end
    end
end

-- 自动刷新逻辑
function GUI.refresh_all()
    for _, p in pairs(game.connected_players) do
        local f = p.gui.screen[Config.Names.main_frame]
        if f and f.valid then
            update_list_view(f, p)
        end
    end
end

-- [新增] 处理搜索文本变更
function GUI.handle_search(event)
    if event.element.name == NAMES.search_textfield then
        local player = game.get_player(event.player_index)
        local frame = player.gui.screen[NAMES.frame]
        if frame then
            update_list_view(frame, player)
        end
    end
end

return GUI
