-- control.lua
-- 【归魂碑 - 主入口】
-- 设计：极简架构，不包含具体逻辑，仅负责模块加载。

local Config = require("scripts.config")

-- 加载核心逻辑 (main.lua 会自动注册所有必要的事件监听器)
require("scripts.main")

-- 可以在这里打印一条日志确认加载成功
Config.log("AetherLink 模组加载完毕 (Control Stage)。")
