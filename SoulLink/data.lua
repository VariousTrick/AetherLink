-- data.lua
-- 【归魂碑 - 数据阶段】
-- 功能：定义快捷按钮、实体、物品、配方及科技。

-- 1. 名称定义
local NAME_SHORTCUT = "soullink-shortcut"
local NAME_OBELISK = "soullink-obelisk"
local NAME_PYLON = "soullink-pylon"
local NAME_TECH = "soullink-technology"

-- 2. 快捷栏按钮
local shortcut = {
    type = "shortcut",
    name = NAME_SHORTCUT,
    order = "a[soullink]",
    action = "lua",
    icon = "__SoulLink__/graphics/icon/shortcut.png",
    icon_size = 64,
    small_icon = "__SoulLink__/graphics/icon/shortcut.png",
    small_icon_size = 64,
}

-- 3. 实体定义
-- 3.1 方尖碑 (Obelisk) - 10x10
local obelisk = table.deepcopy(data.raw["simple-entity-with-owner"]["simple-entity-with-owner"])
obelisk.name = NAME_OBELISK
obelisk.icon = "__base__/graphics/icons/rocket-silo.png"
obelisk.icon_size = 64
obelisk.flags = { "placeable-neutral", "placeable-player", "player-creation", "not-rotatable" }
obelisk.minable = { mining_time = 5, result = NAME_OBELISK }
obelisk.max_health = 5000
obelisk.collision_box = { { -4.9, -4.9 }, { 4.9, 4.9 } }
obelisk.selection_box = { { -5, -5 }, { 5, 5 } }
obelisk.picture = {
    filename = "__base__/graphics/entity/rocket-silo/06-rocket-silo.png",
    width = 300,
    height = 300,
    scale = 1,
}

-- 3.2 中继塔 (Pylon) - 4x4
local pylon = table.deepcopy(data.raw["simple-entity-with-owner"]["simple-entity-with-owner"])
pylon.name = NAME_PYLON
pylon.icon = "__base__/graphics/icons/roboport.png"
pylon.icon_size = 64
pylon.flags = { "placeable-neutral", "placeable-player", "player-creation" }
pylon.minable = { mining_time = 1, result = NAME_PYLON }
pylon.max_health = 500
pylon.collision_box = { { -1.9, -1.9 }, { 1.9, 1.9 } }
pylon.selection_box = { { -2, -2 }, { 2, 2 } }
pylon.picture = data.raw["roboport"]["roboport"].base

-- 4. 物品定义
local item_obelisk = {
    type = "item",
    name = NAME_OBELISK,
    icon = obelisk.icon,
    icon_size = 64,
    subgroup = "transport",
    order = "z[soullink]-a",
    place_result = NAME_OBELISK,
    stack_size = 1,
}

local item_pylon = {
    type = "item",
    name = NAME_PYLON,
    icon = pylon.icon,
    icon_size = 64,
    subgroup = "transport",
    order = "z[soullink]-b",
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
    icon = "__SoulLink__/graphics/icon/shortcut.png",
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
    { type = "sprite", name = "soullink-icon-pin", filename = "__SoulLink__/graphics/icon/pin.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "soullink-icon-search", filename = "__SoulLink__/graphics/icon/search.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "soullink-icon-teleport", filename = "__SoulLink__/graphics/icon/teleport.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "soullink-icon-star", filename = "__SoulLink__/graphics/icon/star.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "soullink-icon-notstar", filename = "__SoulLink__/graphics/icon/notstar.png", width = 200, height = 200, scale = 0.16 },
    { type = "sprite", name = "soullink-icon-rename", filename = "__SoulLink__/graphics/icon/rename.png", width = 200, height = 200, scale = 0.16 },
})
