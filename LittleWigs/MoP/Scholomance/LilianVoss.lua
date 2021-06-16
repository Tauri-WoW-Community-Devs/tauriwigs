--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Lilian Voss", 898, 666)
if not mod then return end
mod:RegisterEnableMob(58722)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "I can't...fight him..."
	L.dead_trigger = "What?!" -- Darkmaster Gandling yells: What?!
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {{115350, "FLASH"}, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "FixateAnger", 115350)
	self:Yell("EncounterWin", L["dead_trigger"])

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FixateAnger(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Important", "Alert", CL["you"]:format(args.spellName))
		self:Flash(args.spellId)
	end
end

function mod:EncounterWin(args)
	self:Win()
end