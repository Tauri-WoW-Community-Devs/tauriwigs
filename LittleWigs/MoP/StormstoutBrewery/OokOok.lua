--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Ook-Ook", 876, 668)
if not mod then return end
mod:RegisterEnableMob(56637)

local ookdmg = 0
local t = 0
local now = 0
local bananas = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "Me gonna ook you in the dooker!"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {106784, 106651, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_DAMAGE", "BarrelDmg", 106784)
	self:Log("SPELL_AURA_APPLIED", "Bananas", 106651)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Bananas", 106651)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 56637)
end

function mod:OnEngage()
	ookdmg = 0
	t = 0
	now = 0
	bananas = 0
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BarrelDmg(args)
	if(args.destGUID == UnitGUID("boss1")) then
		now = GetTime()
		if now-t > 30 then
			ookdmg = 10
		else
			ookdmg = ookdmg+10
		end
		t = now
		self:Message(106784, "Positive", "Info", "Barrel Hit: +"..ookdmg.."% damage")
	end
end

function mod:Bananas(args)
	bananas = bananas+1
	self:Message(106651, "Positive", "Info", "Going Bananas x"..bananas)
end