--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Instructor Chillheart", 898, 659)
if not mod then return end
mod:RegisterEnableMob(58633, 58664) -- Chillheart, Phylactery

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "Your soul cannot withstand my power!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {{111610, "FLASH"}, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "IceWrath", 111610)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 58664)
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:IceWrath(args)
	if self:Me(args.destGUID) then
		self:Message(111610, "Personal", "Info", CL["you"]:format(args.spellName))
		self:Flash(111610)
	end
end