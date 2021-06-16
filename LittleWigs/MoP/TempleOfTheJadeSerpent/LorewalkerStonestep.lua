--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Lorewalker Stonestep", 867, 664)
if not mod then return end
mod:RegisterEnableMob(59051, 59726, 58826) --Strife, Peril, Zao Sunseeker

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.dead_trigger = "For you see, strife feeds on conflict. When you have peace in your heart, strife will find somewhere else to roam." -- Lorewalker Stonestep yells
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {"bosskill"}
end

function mod:OnBossEnable()
	self:Yell("EncounterWin", L["dead_trigger"])

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 58826)
end

function mod:OnEngage()

end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:EncounterWin(args)
	self:Win()
end