--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("High Inquisitor Whitemane", 874, 674)
if not mod then return end
mod:RegisterEnableMob(3977, 60040) -- Whitemane, Durand

local deaths = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "My legend begins NOW!"

	L.steel, L.steel_desc = EJ_GetSectionInfo(5636)
	L.steel_icon = 115629
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {113134, "steel", "stages", "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "MassRes", 113134)
	self:Log("SPELL_CAST_SUCCESS", "Sleep", 9256)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "Steel", "boss1", "boss2")

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Deaths", 3977, 60040)
end

function mod:OnEngage()
	deaths = 0
	self:Message("stages", "Positive", nil, CL["phase"]:format(1).. ": "..EJ_GetSectionInfo(5635), false)
	self:Bar("steel", 9, 115629)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:MassRes(args)
	self:Message(args.spellId, "Urgent", "Alarm")
end

function mod:Sleep(args)
	self:Message("stages", "Positive", nil, CL["phase"]:format(3), args.spellId)
	self:Bar("stages", 10, args.spellId)
end

function mod:Steel(_, spellName, _, _, spellId)
	if spellId == 115629 then
		self:CDBar("steel", 25, 115629) -- 26.x - 27.x
	end
end

function mod:Deaths()
	deaths = deaths + 1
	if deaths == 1 then
		self:Message("stages", "Positive", nil, CL["phase"]:format(2).. ": "..EJ_GetSectionInfo(5638), false)
		self:StopBar(115629)
	elseif deaths == 3 then
		self:Win()
	end
end