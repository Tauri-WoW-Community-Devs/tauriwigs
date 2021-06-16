--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Yan-Zhu the Uncasked", 876, 670)
if not mod then return end
mod:RegisterEnableMob(59479)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = ""
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {114386, 106546, 106851, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Carbonation", 114386)
	self:Log("SPELL_AURA_APPLIED", "Bloat", 106546)
	self:Log("SPELL_AURA_APPLIED", "BlackoutBrew", 106851)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 59479)
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Carbonation(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Personal", "Info", CL["you"]:format(args.spellName))
		self:Flash(args.spellId)
	end
end

function mod:Bloat(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Personal", "Info", CL["you"]:format(args.spellName))
		self:Flash(args.spellId)
	end
end

function mod:BlackoutBrew(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Personal", "Info", CL["you"]:format(args.spellName))
		self:Flash(args.spellId)
	end
end