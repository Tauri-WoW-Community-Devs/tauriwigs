--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Liu Flameheart", 867, 658)
if not mod then return end
mod:RegisterEnableMob(56732)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "The heart of the Great Serpent will not fall into your hands!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {{107110, "FLASH"}, "stages", "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_DAMAGE", "JadeFire", 107110)
	self:Log("SPELL_CAST_START", "JadePhase", 106797)
	self:Log("SPELL_AURA_REMOVED", "YulonPhase", 106797)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")
	self:Death("Win", 56732)
end

function mod:OnEngage()
	self:Message("stages", "Positive", "Info", (CL["phase"]:format(1))..": Serpent Dance", 106797)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:JadeFire(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 1 then
			prev = t
			self:Message(107110, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(107110)
		end
	end
end

function mod:JadePhase(args)
	self:Message("stages", "Positive", "Info", (CL["phase"]:format(2))..": Jade Serpent Dance", 106797)
end

function mod:YulonPhase(args)
	self:Message("stages", "Positive", "Info", (CL["phase"]:format(3))..": The Jade Serpent", 106797)
end