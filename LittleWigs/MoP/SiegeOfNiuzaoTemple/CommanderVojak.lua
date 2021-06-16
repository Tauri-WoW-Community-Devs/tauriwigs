--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Commander Vo'jak", 887, 738)
if not mod then return end
mod:RegisterEnableMob(61634)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "Fools! Attacking the might of the mantid head on? Your deaths will be swift."
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {"bosskill"}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 61634)
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--