--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Trial of the King", 885, 708)
if not mod then return end
-- Xin the Weaponmaster, Haiyan the Unstoppable, Ming the Cunning, Kuai the Brute
mod:RegisterEnableMob(61884, 61445, 61444, 61442)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.scout = "Glintrok Scout"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
	119922, {-6017, "ICON"},
	119981, 120100,
	{-6024, "ICON"}, {-6025, "ICON", "SAY", "FLASH"}, {123655, "HEALER"},
	"bosskill",
	}, {
	[119922] = -6015, --Kuai
	[119981] = -6019, --Ming
	[-6024] = -6023, --Haiyan
	bosskill = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")

	self:Log("SPELL_AURA_APPLIED", "TraumaticBlow", 123655)

	self:Log("SPELL_AURA_APPLIED", "Ravage", 119946)
	self:Log("SPELL_AURA_REMOVED", "RavageOver", 119946)

	self:Log("SPELL_AURA_APPLIED", "Conflag", 120160)
	self:Log("SPELL_AURA_REMOVED", "ConflagOver", 120160)

	self:Log("SPELL_CAST_START", "Shockwave", 119922)

	self:Log("SPELL_CAST_START", "WhirlingDervish", 119981)
	self:Log("SPELL_CAST_START", "MagneticField", 120100)
	self:Log("SPELL_CAST_START", "Meteor", 120195)

	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "MeteorFinished", "boss1")

	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
	local mobId = self:MobId(UnitGUID("boss1"))
	if mobId == 61445 then -- Haiyan the Unstoppable
		self:CDBar(-6025, 55, 120195)
		self:CDBar(-6024, 22)
	elseif mobId == 61444 then -- Ming the Cunning
		self:CDBar(119981, 20)
		self:CDBar(120100, 42.5)
	elseif mobId == 61442 then -- Kuai the Brute
		self:CDBar(119922, 18)
		self:CDBar(-6017, 26)
	end
	self:CheckBossStatus()
end

function mod:TraumaticBlow(args)
	self:TargetMessage(args.spellId, args.destName, "Positive")
	self:TargetBar(args.spellId, 5, args.destName)
end

function mod:Ravage(args)
	self:TargetMessage(-6017, args.destName, "Attention", nil, args.spellId)
	self:TargetBar(-6017, 9, args.destName, args.spellId)
	self:PrimaryIcon(-6017, args.destName)
	self:CDBar(-6017, 19)
end

function mod:RavageOver()
	self:PrimaryIcon(-6017)
end

function mod:Conflag(args)
	self:TargetMessage(-6024, args.destName, "Attention", nil, args.spellId)
	self:TargetBar(-6024, 5, args.destName, args.spellId)
	self:SecondaryIcon(-6024, args.destName)
	self:CDBar(-6024, 42)
end

function mod:ConflagOver()
	self:SecondaryIcon(-6024)
end

function mod:Shockwave(args)
	self:Message(args.spellId, "Urgent", "Alert", CL.casting:format(args.spellName), args.spellId)
	self:Bar(args.spellId, 2, CL.cast:format(args.spellName), args.spellId)
	self:CDBar(args.spellId, 15)
end

function mod:WhirlingDervish(args)
	self:CDBar(119981, 45)
end

function mod:MagneticField(args)
	self:CDBar(120100, 45)
end

function mod:Meteor(args)
	self:CDBar(120195, 42)
end

function mod:MeteorFinished(_, _, _, _, spellId)
	if spellId == 120195 then
		self:PrimaryIcon(-6025)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg, unit, _, _, player)
	if unit == L.scout then
		self:Win()
	elseif msg:find("meteorstorm", nil, true) then -- |TInterface\\Icons\\spell_fire_meteorstorm.blp:20|tHaiyan the Unstoppable targets |cFFFF0000PLAYER|r with a |cFFFF0000|Hspell:120195|h[Meteor]|h|r!
		self:TargetMessage(-6025, player, "Important", "Alarm", 120195)
		self:TargetBar(-6025, 5, player, 120195)
		self:PrimaryIcon(-6025, player)
		if UnitIsUnit(player, "player") then
			self:Flash(-6025)
			self:Say(-6025, 120195)
		end
	end
end