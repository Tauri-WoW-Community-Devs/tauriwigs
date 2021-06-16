--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Jandice Barov", 898, 663)
if not mod then return end
mod:RegisterEnableMob(59184)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "Ooh, it takes some real stones to challenge the Mistress of Illusion. Well? Show me what you've got!"
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

	self:Death("Win", 59184)
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--