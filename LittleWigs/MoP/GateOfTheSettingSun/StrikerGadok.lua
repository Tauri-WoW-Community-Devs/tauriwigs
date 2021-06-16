--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Striker Ga'dok", 875, 675)
if not mod then return end
mod:RegisterEnableMob(56589)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "I'll hurl your corpses from this tower."
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {{115458, "FLASH"}, {116297, "FLASH"}, 106933, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_DAMAGE", "AcidBomb", 115458)
	self:Log("SPELL_DAMAGE", "StrafingRun", 116297)
	self:Log("SPELL_AURA_APPLIED", "PreyTime", 106933)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 56589)
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:AcidBomb(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(115458, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(115458)
		end
	end
end

do
	local prev = 0
	function mod:StrafingRun(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(116297, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(116297)
		end
	end
end

function mod:PreyTime(args)
	if self:Me(args.destGUID) then
		self:Message(106933, "Personal", "Info", CL["you"]:format(args.spellName))
	end
	self:Bar(106933, 5, CL["cast"]:format(args.spellName))
end