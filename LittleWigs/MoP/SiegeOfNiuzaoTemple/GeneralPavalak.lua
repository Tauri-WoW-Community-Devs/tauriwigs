--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("General Pa'valak", 887, 692)
if not mod then return end
mod:RegisterEnableMob(61485)

local dmg = 0
local t = 0
local now = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "The temple will fall! You cannot stop my forces!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {-5946, 119395, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "CallReinforcements", 119476)
	self:Log("SPELL_AURA_APPLIED", "Detonate", 119395)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Detonate", 119395)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 61485)
end

function mod:OnEngage()
	dmg = 0
	t = 0
	now = 0
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CallReinforcements(args)
	self:Message(-5946, "Positive", "Info", "Call Reinforcements")
end

function mod:Detonate(args)
	if(args.destGUID == UnitGUID("boss1")) then
		now = GetTime()
		if now-t > 90 then
			dmg = 5
		else
			dmg = dmg+5
		end
		t = now
		self:Message(119395, "Positive", "Info", "Bomb Hit: +"..dmg.."% damage")
	end
end