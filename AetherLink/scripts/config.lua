-- scripts/config.lua
-- 【归魂碑 - 配置模块】
-- 功能：定义全局常量、名称索引和调试开关。

local Config = {}

-- ============================================================================
-- 全局设置
-- ============================================================================

-- 调试模式开关 (true: 开启打印 / false: 关闭)
-- 建议发布时改为 false，开发时为 true
Config.DEBUG = true

-- ============================================================================
-- 核心名称定义 (Prototype Names & GUI Names)
-- ============================================================================

Config.Names = {
	-- 快捷栏按钮 (Shortcut) 的名称，必须与 data.lua 中定义的一致
	shortcut = "aetherlink-shortcut",

	-- 主窗口 GUI 的名称 (用于唯一标识窗口)
	main_frame = "aetherlink_main_frame",

	-- 两个核心实体的名称 (预留)
	obelisk = "aetherlink-obelisk", -- 主建筑：方尖碑
	pylon = "aetherlink-pylon", -- 次建筑：中继塔
}

-- ============================================================================
-- 调试工具函数
-- ============================================================================

-- 统一的日志输出函数
-- 在 control.lua 加载时，我们会把它注入到全局环境或传递给其他模块
function Config.log(msg)
	if Config.DEBUG then
		-- 格式化输出：[AetherLink] <消息>
		local formatted_msg = "[AetherLink] " .. tostring(msg)
		log(formatted_msg)
		if game then
			game.print(formatted_msg)
		end
	end
end

return Config
