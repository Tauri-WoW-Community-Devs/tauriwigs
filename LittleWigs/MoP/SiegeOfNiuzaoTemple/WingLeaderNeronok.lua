--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Wing Leader Ner'onok", 887, 727)
if not mod then return end
mod:RegisterEnableMob(62205)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "You may have come this far. You may have carved a path through my army, but I... will kill you, and I will build the bridge."
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--caustic pitch dmg, quick-dry resin debuff, 

function mod:GetOptions()
	return {{121443, "FLASH"}, 121447, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_PERIODIC_DAMAGE", "CausticPitch", 121443)
	self:Log("SPELL_AURA_APPLIED", "QuickDryResin", 121447)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 62205)
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:CausticPitch(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(121443, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(121443)
		end
	end
end

function mod:QuickDryResin(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Important", "Alert", CL["you"]:format(args.spellName))
	end
end