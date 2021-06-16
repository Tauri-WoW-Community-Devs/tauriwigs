--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Raigonn", 875, 649)
if not mod then return end
mod:RegisterEnableMob(56877, 56895) -- Raigonn, Weak Spot

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
	return {{107275, "FLASH"}, 111600, {111644, "FLASH"}, 111723, 107118, "stages", "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_DAMAGE", "EngulfingWinds", 107279)
	self:Log("SPELL_AURA_APPLIED", "ScreechingSwarm", 111600)
	self:Log("SPELL_DAMAGE", "ScreechingSwarmDmg", 111644)
	self:Log("SPELL_AURA_APPLIED", "Fixate", 111723)
	self:Log("SPELL_AURA_REMOVED", "Phase2", 107118)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 56877)
end

function mod:OnEngage()
	self:Message("stages", "Positive", "Info", (CL["phase"]:format(1))..": Man the Cannons!", 107118)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:EngulfingWinds(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(107279, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(107279)
		end
	end
end

function mod:ScreechingSwarm(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Important", "Alert", CL["you"]:format(args.spellName))
	end
end

do
	local prev = 0
	function mod:ScreechingSwarmDmg(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(111644, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(111644)
		end
	end
end

function mod:ViscousFluid(args)
	if self:Me(args.destGUID) then
		self:Message(107122, "Personal", "Info", CL["underyou"]:format(args.spellName))
		self:Flash(107122)
	end
end

function mod:Fixate(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Important", "Alert", CL["you"]:format(args.spellName))
	end
end

function mod:Phase2(args)
	self:Message("stages", "Positive", "Info", (CL["phase"]:format(2))..": Broken Carapace!", 111723)
end