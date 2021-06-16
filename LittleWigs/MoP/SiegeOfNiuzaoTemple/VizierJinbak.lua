--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Vizier Jin'bak", 887, 693)
if not mod then return end
mod:RegisterEnableMob(61567)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "Allow me to show you the power of amber alchemy..."
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

	self:Death("Win", 61567)
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--