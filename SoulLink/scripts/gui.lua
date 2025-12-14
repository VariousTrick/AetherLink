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
    btn_gps = "soullink_gps_", -- [新增] GPS 按钮
    btn_teleport = "soullink_tp_",
    btn_fold = "soullink_fold_", -- [新增] 折叠按钮
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

-- [重写] 添加表格行 (原生工具栏风格: 20px)
local function add_table_row(table_elem, anchor, player_data)
    local ROW_SIZE = 28

    -- 图标按钮样式：使用原生 frame_action_button，它是专门为 20px 设计的
    local icon_style = "frame_action_button"
    local icon_mods = { width = ROW_SIZE, height = ROW_SIZE, padding = 0, margin = 0 }

    -- 名字栏样式：保持深色背景，但压扁高度
    local name_mods = { height = ROW_SIZE, top_padding = 0, bottom_padding = 0, margin = 0 }

    -- 1. 第一列：收藏按钮 (Star)
    local is_fav = player_data.favorites and player_data.favorites[anchor.id]
    local fav_sprite = is_fav and "soullink-icon-star" or "soullink-icon-notstar"

    table_elem.add({
        type = "sprite-button",
        name = NAMES.btn_fav .. anchor.id,
        sprite = fav_sprite,
        style = icon_style, -- [修改] 使用原生小按钮样式
        style_mods = icon_mods,
        tags = { anchor_id = anchor.id },
        tooltip = is_fav and { "gui.soullink-unfavorite" } or { "gui.soullink-favorite" },
    })

    -- 2. 第二列：名字 (Name)
    local is_editing = player_data.editing_anchor_id == anchor.id

    if is_editing then
        -- 编辑框
        local current_text = (type(anchor.name) == "string") and anchor.name or ""
        local textfield = table_elem.add({
            type = "textfield",
            name = NAMES.rename_textfield .. anchor.id,
            text = current_text,
            icon_selector = true,
            tags = { anchor_id = anchor.id },
        })
        textfield.style.horizontally_stretchable = true
        textfield.style.height = ROW_SIZE
        textfield.style.margin = 0
        textfield.focus()
    else
        -- 名字按钮 (统一为原生工具栏按钮样式)
        local name_btn = table_elem.add({
            type = "button",
            name = NAMES.btn_select .. anchor.id,
            caption = anchor.name,
            style = "list_box_item",
            tags = { anchor_id = anchor.id },
            mouse_button_filter = { "left" },
        })
        name_btn.style.horizontally_stretchable = true
        name_btn.style.horizontal_align = "left" -- 保持左对齐
        name_btn.style.font_color = { 1, 1, 1 }

        -- 应用高度修正
        for k, v in pairs(name_mods) do
            name_btn.style[k] = v
        end

        -- [新增] 增加一点左内边距，让文字不要紧贴边缘
        name_btn.style.left_padding = 4
    end

    -- 3. 第三列：改名/确认
    if is_editing then
        table_elem.add({
            type = "sprite-button",
            name = NAMES.rename_confirm .. anchor.id,
            sprite = "utility/check_mark",
            style = icon_style, -- [修改] 原生小按钮
            style_mods = icon_mods,
            tags = { anchor_id = anchor.id },
            tooltip = "确认改名",
        })
    else
        table_elem.add({
            type = "sprite-button",
            name = NAMES.btn_edit .. anchor.id,
            sprite = "soullink-icon-rename",
            style = icon_style, -- [修改] 原生小按钮
            style_mods = icon_mods,
            tags = { anchor_id = anchor.id },
            tooltip = { "gui.soullink-rename" },
        })
    end

    -- 4. 第四列：GPS
    local surface_name = "Unknown"
    if game.surfaces[anchor.surface_index] then
        surface_name = game.surfaces[anchor.surface_index].name
    end
    local gps_tag = string.format("[gps=%d,%d,%s]", anchor.position.x, anchor.position.y, surface_name)

    table_elem.add({
        type = "sprite-button",
        name = NAMES.btn_gps .. anchor.id,
        sprite = "utility/center",
        style = icon_style, -- [修改] 原生小按钮
        style_mods = icon_mods,
        tags = { gps_string = gps_tag },
        tooltip = "发送位置",
    })

    -- 5. 第五列：传送
    table_elem.add({
        type = "sprite-button",
        name = NAMES.btn_teleport .. anchor.id,
        sprite = "soullink-icon-teleport",
        style = icon_style, -- [修改] 原生小按钮
        style_mods = icon_mods,
        tags = { anchor_id = anchor.id },
        tooltip = { "gui.soullink-teleport" },
    })
end
local function update_list_view(frame, player)
    local scroll = find_element_by_name(frame, NAMES.left_scroll)
    if not scroll then
        return
    end
    scroll.clear()

    local player_data = State.get_player_data(player.index)
    local all_anchors = State.get_all()

    -- 搜索逻辑 (不变)
    local search_text = ""
    local titlebar = find_element_by_name(frame, NAMES.titlebar)
    if titlebar and titlebar[NAMES.search_textfield] then
        search_text = string.lower(titlebar[NAMES.search_textfield].text)
    end

    local favorites_list = {}
    local grouped_data = {}
    local has_any = false

    for _, anchor in pairs(all_anchors) do
        local match = true
        if search_text ~= "" then
            match = false
            if type(anchor.name) == "string" and string.find(string.lower(anchor.name), search_text, 1, true) then
                match = true
            end
            if type(anchor.name) == "table" and string.find(tostring(anchor.id), search_text, 1, true) then
                match = true
            end
        end

        if match then
            has_any = true
            if player_data.favorites and player_data.favorites[anchor.id] then
                table.insert(favorites_list, anchor)
            end
            local s_idx = anchor.surface_index
            if not grouped_data[s_idx] then
                local s_name = game.surfaces[s_idx] and game.surfaces[s_idx].name or ("Surface #" .. s_idx)
                grouped_data[s_idx] = { name = s_name, anchors = {} }
            end
            table.insert(grouped_data[s_idx].anchors, anchor)
        end
    end

    if not has_any then
        scroll.add({ type = "label", caption = { "gui.soullink-no-anchors" }, style_mods = { font_color = { 0.5, 0.5, 0.5 } } })
        return
    end

    -- 渲染 A：特别关注
    if #favorites_list > 0 then
        local fav_frame = scroll.add({
            type = "frame",
            style = "inside_shallow_frame",
            direction = "vertical",
        })
        fav_frame.style.horizontally_stretchable = true
        fav_frame.style.bottom_margin = 8

        local header = fav_frame.add({ type = "flow", direction = "horizontal" })
        header.style.vertical_align = "center"
        header.style.bottom_margin = 4
        header.add({ type = "sprite", sprite = "soullink-icon-star", style_mods = { width = 20, height = 20, stretch_image_to_widget_size = true } })
        header.add({ type = "label", caption = { "gui.soullink-favorites" }, style = "caption_label" })

        local fav_table = fav_frame.add({
            type = "table",
            column_count = 5,
            style = "table", -- [重要] 改用基础表格样式，消除缝隙
        })
        fav_table.style.horizontally_stretchable = true
        fav_table.style.horizontal_spacing = 0
        fav_table.style.vertical_spacing = 0 -- 消除行间距，如果不喜欢连太紧，可以改回 1
        fav_table.style.column_alignments[2] = "left"

        table.sort(favorites_list, function(a, b)
            return a.id < b.id
        end)
        for _, anchor in ipairs(favorites_list) do
            add_table_row(fav_table, anchor, player_data)
        end
    end

    -- 渲染 B：地表分组
    local s_idxs = {}
    for k in pairs(grouped_data) do
        table.insert(s_idxs, k)
    end
    table.sort(s_idxs)

    for _, s_idx in ipairs(s_idxs) do
        local group = grouped_data[s_idx]

        local group_frame = scroll.add({
            type = "frame",
            style = "inside_shallow_frame",
            direction = "vertical",
        })
        group_frame.style.horizontally_stretchable = true
        group_frame.style.bottom_margin = 8

        local header = group_frame.add({ type = "flow", direction = "horizontal" })
        header.style.vertical_align = "center"
        header.style.bottom_margin = 4

        local is_collapsed = player_data.collapsed_surfaces and player_data.collapsed_surfaces[s_idx]
        if search_text ~= "" then
            is_collapsed = false
        end

        local sprite = is_collapsed and "utility/play" or "utility/dropdown"
        header.add({
            type = "sprite-button",
            name = NAMES.btn_fold,
            sprite = sprite,
            style = "frame_action_button", -- 这个样式和下面列表里的按钮一致了
            style_mods = { width = 20, height = 20, padding = 0 },
            tags = { surface_index = s_idx },
            tooltip = is_collapsed and "展开" or "折叠",
        })

        header.add({
            type = "label",
            caption = group.name,
            style = "caption_label",
        }).style.font = "default-bold"

        if not is_collapsed then
            local group_table = group_frame.add({
                type = "table",
                column_count = 5,
                style = "table", -- [重要] 改用基础表格样式
            })
            group_table.style.horizontally_stretchable = true
            group_table.style.horizontal_spacing = 0
            group_table.style.vertical_spacing = 0
            group_table.style.column_alignments[2] = "left"

            table.sort(group.anchors, function(a, b)
                return a.id < b.id
            end)

            for _, anchor in ipairs(group.anchors) do
                add_table_row(group_table, anchor, player_data)
            end
        end
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

    -- [新增] 折叠/展开地表
    if name == NAMES.btn_fold then
        local s_idx = element.tags.surface_index
        if not p_data.collapsed_surfaces then
            p_data.collapsed_surfaces = {}
        end

        -- 切换状态
        p_data.collapsed_surfaces[s_idx] = not p_data.collapsed_surfaces[s_idx]

        -- 刷新
        update_list_view(frame, player)
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

    -- [修改] 改名确认：使用 string.find
    if string.find(name, NAMES.rename_confirm) then
        -- 注意：因为现在 textfield 的名字也带ID了，所以获取兄弟元素要小心
        -- 既然我们已经在 tags 里存了 ID，我们可以直接去 Table 里找
        -- 但最简单的方法是：触发 handle_confirm，我们稍后处理回车逻辑
        -- 这里我们利用 textfield 的名字规律
        local anchor_id = element.tags.anchor_id
        -- 找到那个特定的 textfield
        local textfield_name = NAMES.rename_textfield .. anchor_id

        -- element.parent 是那个 flow，textfield 在 element.parent.parent (table) 里
        -- 这样找太麻烦。我们直接利用 element.tags.anchor_id
        -- 更好的办法是：遍历 parent.parent.children 找到那个名字。

        -- 但是，实际上 Factorio 的 textfield 改动不需要点击确认，回车就行。
        -- 如果非要点钩子，我们需要找到那个输入框的文本。
        -- 简单方案：从 element.parent (flow) 往上找 table，再找 textfield
        local table_elem = element.parent.parent
        if table_elem[textfield_name] then
            State.set_anchor_name(anchor_id, table_elem[textfield_name].text)
            p_data.editing_anchor_id = nil
            update_list_view(frame, player)
        end
        return
    end

    -- 以下操作需要主窗口存在
    if not frame then
        return
    end

    -- [修改] GPS 按钮：使用 string.find
    if string.find(name, NAMES.btn_gps) then
        if element.tags.gps_string then
            player.print(element.tags.gps_string)
        end
        return
    end

    -- [修改] 传送按钮：使用 string.find
    if string.find(name, NAMES.btn_teleport) then
        local anchor = State.get_by_id(element.tags.anchor_id)
        if anchor then
            player.teleport(anchor.position, anchor.surface_index)
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

    -- [修改] 收藏按钮：使用 string.find
    if string.find(name, NAMES.btn_fav) then
        local id = element.tags.anchor_id
        if not p_data.favorites then
            p_data.favorites = {}
        end
        p_data.favorites[id] = not p_data.favorites[id]
        update_list_view(frame, player)
        return
    end

    -- [修改] 改名按钮：使用 string.find
    if string.find(name, NAMES.btn_edit) then
        p_data.editing_anchor_id = element.tags.anchor_id
        update_list_view(frame, player)
        return
    end
end

-- 确认事件 (改名框回车)
function GUI.handle_confirm(event)
    -- [修改] 使用 string.find 匹配输入框名字
    if string.find(event.element.name, NAMES.rename_textfield) then
        local player = game.get_player(event.player_index)
        local frame = player.gui.screen[Config.Names.main_frame]
        local anchor_id = event.element.tags.anchor_id

        if anchor_id then
            State.set_anchor_name(anchor_id, event.element.text)

            local p_data = State.get_player_data(player.index)
            p_data.editing_anchor_id = nil -- 退出编辑模式

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
