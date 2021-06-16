--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Darkmaster Gandling", 898, 684)
if not mod then return end
mod:RegisterEnableMob(59080)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "School is in session!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--port 16s

function mod:GetOptions()
	return {124003, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_FAILED", "HarshLesson", 124003)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 59080)
end

function mod:OnEngage()
	self:CDBar(124003, 16)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:HarshLesson(args)
	self:CDBar(124003, 30)
end