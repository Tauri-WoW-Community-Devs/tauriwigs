--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Commander Ri'mok", 875, 676)
if not mod then return end
mod:RegisterEnableMob(56636)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "There will be no escaping me."
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {107120, {107122, "FLASH"}, {106874, "FLASH"}, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FrenziedAssault", 107120)
	self:Log("SPELL_AURA_APPLIED", "ViscousFluid", 107122)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ViscousFluid", 107122)
	self:Log("SPELL_DAMAGE", "FireBomb", 106874)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 56636)
end

function mod:OnEngage()
	self:CDBar(107120, 7.5)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FrenziedAssault(args)
	self:CDBar(107120, 17)
end

function mod:ViscousFluid(args)
	if self:Me(args.destGUID) then
		self:Message(107122, "Personal", "Info", CL["underyou"]:format(args.spellName))
		self:Flash(107122)
	end
end

do
	local prev = 0
	function mod:FireBomb(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(106874, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(106874)
		end
	end
end