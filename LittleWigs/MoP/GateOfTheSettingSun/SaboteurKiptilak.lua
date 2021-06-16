--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Saboteur Kip'tilak", 875, 655)
if not mod then return end
mod:RegisterEnableMob(56906)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "Gate?! I'm going to bring this whole wall down!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {{107268, "FLASH"}, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Sabotage", 107268)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 56906)
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Sabotage(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Important", "Alert", CL["you"]:format(args.spellName))
		self:Flash(args.spellId)
	end
end