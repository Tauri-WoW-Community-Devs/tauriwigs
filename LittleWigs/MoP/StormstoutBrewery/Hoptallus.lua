--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Hoptallus", 876, 669)
if not mod then return end
mod:RegisterEnableMob(56717)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "Gonna spins around!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {112992, 112944, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Furlwind", 112992)
	self:Log("SPELL_CAST_START", "CarrotBreath", 112944)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 56717)
end

function mod:OnEngage()
	self:CDBar(112992, 15)
	self:CDBar(112944, 33)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Furlwind(args)
	self:CDBar(112992, 43)
end

function mod:CarrotBreath(args)
	self:CDBar(112944, 43)
end