-- data.lua
-- 【归魂碑 - 数据阶段】
-- 功能：定义快捷按钮、实体、物品、配方及科技。

-- 1. 名称定义
local NAME_SHORTCUT = "aetherlink-shortcut"
local NAME_OBELISK = "aetherlink-obelisk"
local NAME_PYLON = "aetherlink-pylon"
local NAME_TECH = "aetherlink-technology"

-- 2. 快捷栏按钮
local shortcut = {
    type = "shortcut",
    name = NAME_SHORTCUT,
    order = "a[aetherlink]",
    action = "lua",
    icon = "__AetherLink__/graphics/icon/shortcut.png",
    icon_size = 64,
    small_icon = "__AetherLink__/graphics/icon/shortcut.png",
    small_icon_size = 64,
}

-- 3. 实体定义
-- 3.1 方尖碑 (Obelisk) - 10x10
local obelisk = table.deepcopy(data.raw["simple-entity-with-owner"]["simple-entity-with-owner"])
obelisk.name = NAME_OBELISK
obelisk.icon = "__AetherLink__/graphics/entity/icon/111.png" -- 后面记得换成你的 icon
obelisk.icon_size = 64
obelisk.flags = { "placeable-neutral", "placeable-player", "player-creation", "not-rotatable" }
obelisk.minable = { mining_time = 5, result = NAME_OBELISK }
obelisk.max_health = 5000

-- [核心设定 1] 碰撞箱 (Collision Box)
-- 设得很小 (4x4)，只挡住中间的水晶根部，让玩家可以走上基座
obelisk.collision_box = { { -1.9, -1.9 }, { 1.9, 1.9 } }

-- [核心设定 2] 选择箱 (Selection Box)
-- 设为完整大小 (10x10)，保证玩家鼠标指着基座边缘也能选中它
obelisk.selection_box = { { -5, -5 }, { 5, 5 } }

-- [核心设定 3] 贴图 (Picture)
obelisk.picture = {
    filename = "__AetherLink__/graphics/entity/11.png", -- 确保文件名正确
    width = 1024,
    height = 2048,

    -- [计算结果] 缩放比例：让 1024px 刚好填满 10格
    scale = 0.3125,

    -- [计算结果] 垂直偏移：把图片向上提 5格，让基座中心对准实体中心
    -- 负数代表向上移
    shift = { 0, -5 },
}
-- 建议加上 render_layer 保证它很高的时候不会被前面的电线杆错误遮挡（可选）
obelisk.render_layer = "object"

-- 3.2 中继塔 (Pylon) - 4x4
local pylon = table.deepcopy(data.raw["simple-entity-with-owner"]["simple-entity-with-owner"])
pylon.name = NAME_PYLON
pylon.icon = "__AetherLink__/graphics/entity/icon/22.png" -- 也可以暂时用实体图做图标，或者你有专门的icon
pylon.icon_size = 64 -- 注意：如果直接用大图做icon可能需要改这里，建议还是用专门的icon文件
pylon.flags = { "placeable-neutral", "placeable-player", "player-creation" }
pylon.minable = { mining_time = 1, result = NAME_PYLON }
pylon.max_health = 500

-- [碰撞/选择箱] 设定为标准的 4x4
pylon.collision_box = { { -1.9, -1.9 }, { 1.9, 1.9 } }
pylon.selection_box = { { -2, -2 }, { 2, 2 } }

-- [关键] 贴图定义 (包含本体和阴影)
pylon.picture = {
    layers = {
        -- 层1：本体
        {
            filename = "__AetherLink__/graphics/entity/22.png",
            width = 1344,
            height = 768,
            scale = 0.25, -- [计算结果] 1/4 缩放
            shift = { -0.05, -0.89 }, -- [计算结果] 基于基座中心对齐
        },
        -- 层2：阴影
        {
            filename = "__AetherLink__/graphics/entity/22shadow.png",
            width = 1344,
            height = 768,
            scale = 0.25,
            shift = { -0.05, -0.89 }, -- 阴影通常和本体使用相同的偏移，除非原图阴影位置很偏
            draw_as_shadow = true, -- [关键] 标记为阴影，半透明渲染
            opacity = 0.7, -- 可以微调阴影浓度
        },
    },
}

-- 4. 物品定义
local item_obelisk = {
    type = "item",
    name = NAME_OBELISK,
    icon = obelisk.icon,
    icon_size = 64,
    subgroup = "transport",
    order = "z[aetherlink]-a",
    place_result = NAME_OBELISK,
    stack_size = 1,
}

local item_pylon = {
    type = "item",
    name = NAME_PYLON,
    icon = pylon.icon,
    icon_size = 64,
    subgroup = "transport",
    order = "z[aetherlink]-b",
    place_result = NAME_PYLON,
    stack_size = 10,
}

-- 5. 配方定义 (注意：enabled 设为 false，由科技解锁)
local recipe_obelisk = {
    type = "recipe",
    name = NAME_OBELISK,
    enabled = false,
    energy_required = 15,
    ingredients = {
        { type = "item", name = "refined-concrete", amount = 100 },
        { type = "item", name = "processing-unit", amount = 20 },
        { type = "item", name = "steel-plate", amount = 50 },
    },
    results = { { type = "item", name = NAME_OBELISK, amount = 1 } },
}

local recipe_pylon = {
    type = "recipe",
    name = NAME_PYLON,
    enabled = false,
    energy_required = 5,
    ingredients = {
        { type = "item", name = "concrete", amount = 20 },
        { type = "item", name = "advanced-circuit", amount = 5 },
        { type = "item", name = "copper-cable", amount = 20 },
    },
    results = { { type = "item", name = NAME_PYLON, amount = 1 } },
}

-- 6. 科技定义
local technology = {
    type = "technology",
    name = NAME_TECH,
    icon_size = 256,
    icon = "__AetherLink__/graphics/icon/shortcut.png",
    effects = {
        { type = "unlock-recipe", recipe = NAME_OBELISK },
        { type = "unlock-recipe", recipe = NAME_PYLON },
    },
    unit = {
        count = 100,
        ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack", 1 },
        },
        time = 15,
    },
    -- [修改] 改为最基础的电子学，防止报错
    prerequisites = { "electronics" },
    order = "z-a",
}

-- 7. 扩展数据
data:extend({
    shortcut,
    obelisk,
    pylon,
    item_obelisk,
    item_pylon,
    recipe_obelisk,
    recipe_pylon,
    technology,

    -- [关键] 确保这些 Sprite 定义在这里
    { type = "sprite", name = "aetherlink-icon-pin", filename = "__AetherLink__/graphics/icon/pin.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "aetherlink-icon-search", filename = "__AetherLink__/graphics/icon/search.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "aetherlink-icon-teleport", filename = "__AetherLink__/graphics/icon/teleport.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "aetherlink-icon-star", filename = "__AetherLink__/graphics/icon/star.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "aetherlink-icon-notstar", filename = "__AetherLink__/graphics/icon/notstar.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "aetherlink-icon-rename", filename = "__AetherLink__/graphics/icon/rename.png", width = 200, height = 200, scale = 0.16 },

    -- [新增] 快捷键定义
    {
        type = "custom-input",
        name = "aetherlink-toggle-gui", -- 内部事件名
        key_sequence = "ALT + W", -- 默认键位
        consuming = "none", -- 允许按键穿透，这是合法值
    },
})
