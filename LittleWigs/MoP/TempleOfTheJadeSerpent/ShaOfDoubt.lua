--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Sha of Doubt", 867, 335)
if not mod then return end
mod:RegisterEnableMob(56439)

local canEnable = true

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "Die or surrender. You cannot defeat me."
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {117665, 106113, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_REMOVED", "AddsOver", 117665)
	self:Log("SPELL_AURA_APPLIED", "TouchOfNothingness", 106113)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 56439)
end

function mod:OnEngage()
	self:CDBar(117665, 28)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:AddsOver(args)
	self:CDBar(117665, 35)
end

function mod:TouchOfNothingness(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Important", "Alert", CL["you"]:format(args.spellName))
	end
end