--[[
TODO:
	maybe do target scanning on new waves, to start some short initial bars for add abilities?
	rethink proximity for different difficulties
]]--

--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("General Nazgrim", 953, 850)
if not mod then return end
mod:RegisterEnableMob(71515, 71715, 71516, 71517, 71518, 71519) -- General Nazgrim, Orgrimmar Faithful, Kor'kron Ironblade, Kor'kron Arcweaver, Kor'kron Assassin, Kor'kron Warshaman
mod.engageId = 1603

--------------------------------------------------------------------------------
-- Locals
--

local marksUsed = {}
local addWaveCounter = 1
local addWaveHc = {
	"|cFFfff569Assassin|r, |cFFc79c6eIronblade|r, |cFF69ccf0Arcweaver|r", -- [1]
	"|cFF0070deShaman|r, |cFFabd373Sniper|r, |cFFfff569Assassin|r", -- [2]
	"|cFF0070deShaman|r, |cFFc79c6eIronblade|r, |cFF69ccf0Arcweaver|r", -- [3]
	"|cFFabd373Sniper|r, |cFFfff569Assassin|r, |cFF69ccf0Arcweaver|r", -- [4]
	"|cFF0070deShaman|r, |cFFc79c6eIronblade|r, |cFFfff569Assassin|r", -- [5]
	"|cFF0070deShaman|r, |cFFabd373Sniper|r, |cFF69ccf0Arcweaver|r", -- [6]
	"|cFFabd373Sniper|r, |cFFc79c6eIronblade|r, |cFFfff569Assassin|r", -- [7]
	"|cFF0070deShaman|r, |cFFfff569Assassin|r, |cFF69ccf0Arcweaver|r", -- [8]
	"|cFF0070deShaman|r, |cFFc79c6eIronblade|r, |cFFabd373Sniper|r", -- [9]
	"|cFFabd373Sniper|r, |cFFc79c6eIronblade|r, |cFF69ccf0Arcweaver|r" -- [10]
}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.custom_off_bonecracker_marks = "Bonecracker marker"
	L.custom_off_bonecracker_marks_desc = "To help healing assignments, mark the people who have Bonecracker on them with {rt1}{rt2}{rt3}{rt4}{rt5}, requires promoted or leader.\n|cFFFF0000Only 1 person in the raid should have this enabled to prevent marking conflicts.|r"
	L.custom_off_bonecracker_marks_icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1"

	L.stance_bar = "%s (NOW: %s)"
	-- shorten stances so they fit on the bars
	L.battle = "Battle"
	L.berserker = "Berserker"
	L.defensive = "Defensive"

	L.adds_trigger1 = "Defend the gate!"
	L.adds_trigger2 = "Rally the forces!"
	L.adds_trigger3 = "Next squad, to the front!"
	L.adds_trigger4 = "Warriors, on the double!"
	L.adds_trigger5 = "Kor'kron, at my side!"
	L.adds_trigger_extra_wave = "All Kor'kron... under my command... kill them... NOW!"
	L.adds_trigger_extra_wave_demonic = "Kar AzgAlada revos xi amanare maev raka ZAR"
	L.extra_adds = "Extra adds [All Types]"
	L.final_wave = "Final Wave"

	L.chain_heal, L.chain_heal_desc = EJ_GetSectionInfo(7935)
	L.chain_heal_icon = 1064
	L.chain_heal_message = "Your focus is casting Chain Heal!"

	L.arcane_shock, L.arcane_shock_desc = EJ_GetSectionInfo(7928)
	L.arcane_shock_icon = 114003
	L.arcane_shock_message = "Your focus is casting Arcane Shock!"
end
L = mod:GetLocale()
L.chain_heal_desc = CL.focus_only..L.chain_heal_desc
L.arcane_shock_desc = CL.focus_only..L.arcane_shock_desc

local stances = {
	[143589] = L.battle,
	[143594] = L.berserker,
	[143593] = L.defensive,
}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{143502, "TANK_HEALER", "FLASH"}, {-7947, "FLASH", "ICON"},
		143484, {143716, "FLASH"}, 143536, {143872, "FLASH", "SAY"}, 143503,
		"custom_off_bonecracker_marks",
		-7920, {-7933, "FLASH"}, {143475, "FLASH", "ICON"}, "chain_heal", "arcane_shock", 143474,
		{143494, "TANK_HEALER"}, {143638, "HEALER"}, -7915, "berserk", "bosskill",
	}, {
		[143502] = "heroic",
		[143484] = -7909,
		["custom_off_bonecracker_marks"] = L.custom_off_bonecracker_marks,
		[-7920] = -7920,
		[143494] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	-- heroic
	self:Log("SPELL_AURA_APPLIED", "HuntersMark", 143882)
	self:Log("SPELL_CAST_START", "Execute", 143502)
	-- Adds
	self:Log("SPELL_CAST_START", "ArcaneShock", 143432)
	self:Log("SPELL_CAST_SUCCESS", "HealingTideTotem", 143474)
	self:Log("SPELL_CAST_START", "ChainHeal", 143473)
	self:Log("SPELL_CAST_SUCCESS", "EarthShield", 143475)
	self:Log("SPELL_AURA_APPLIED", "Fixate", 143480)
	self:Yell("Adds", L.adds_trigger1, L.adds_trigger2, L.adds_trigger3, L.adds_trigger4, L.adds_trigger5)
	self:Yell("ExtraAdds", L.adds_trigger_extra_wave, L.adds_trigger_extra_wave_demonic)
	-- Boss
	self:Log("SPELL_CAST_START", "WarSong", 143503)
	self:Log("SPELL_CAST_SUCCESS", "Ravager", 143872) -- _START has no destName but boss has target, so that could be better, but since this can target pets, and it takes 2 sec before any damage is done after _SUCCESS I guess we can live with using _SUCCESS over _START here
	self:Log("SPELL_SUMMON", "Banner", 143501)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "HeroicShockwave", "boss1") -- faster than _SUCCESS
	self:Log("SPELL_AURA_APPLIED", "CoolingOff", 143484)
	self:Log("SPELL_AURA_APPLIED", "Stances", 143589, 143594, 143593) -- Battle, Berserker, Defensive
	self:Log("SPELL_AURA_APPLIED", "BoneCrackerApplied", 143638)
	self:Log("SPELL_AURA_REMOVED", "BoneCrackerRemoved", 143638)
	self:Log("SPELL_CAST_START", "BoneCracker", 143638)
	self:Log("SPELL_AURA_APPLIED", "SunderingBlow", 143494)
	self:Log("SPELL_AURA_APPLIED_DOSE", "SunderingBlow", 143494)
end

function mod:OnEngage()
	self:Berserk(600)
	wipe(marksUsed)
	self:CDBar(143494, 10) -- Sundering Blow
	self:Bar(143638, 15.5) -- Bonecracker
	addWaveCounter = 1
	if self:Heroic() then
		self:Bar(-7920, 46, ("[%d] %s"):format(addWaveCounter, addWaveHc[addWaveCounter]), "achievement_guildperk_everybodysfriend") -- adds
	else
		self:Bar(-7920, 46, CL.count:format(CL.adds, addWaveCounter), "achievement_guildperk_everybodysfriend") -- adds
	end
	if not self:LFR() then
		self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", nil, "boss1")
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

-- heroic
function mod:HuntersMark(args)
	self:PrimaryIcon(-7947, args.destName)
	if self:Me(args.destGUID) then
		self:Flash(-7947)
	end
	self:TargetMessage(-7947, args.destName, "Attention", "Alarm")
end

function mod:Execute(args)
	self:Message(args.spellId, "Important", "Warning", CL.casting:format(args.spellName)) -- XXX need feedback if this sound works fine with the other sounds
	self:CDBar(args.spellId, 18) -- varies a bit due to ability casts
	if UnitIsUnit("player", "boss1target") then -- poor mans target check
		self:Flash(args.spellId)
	end
end

-- Adds
function mod:ArcaneShock(args)
	if UnitGUID("focus") == args.sourceGUID then
		self:Message("arcane_shock", "Personal", "Alert", L.arcane_shock_message, args.spellId)
	end
end

function mod:HealingTideTotem(args)
	self:Message(args.spellId, "Attention")
end

function mod:ChainHeal(args)
	if UnitGUID("focus") == args.sourceGUID then
		self:Message("chain_heal", "Personal", "Alert", L.chain_heal_message, args.spellId)
	end
end

function mod:EarthShield(args)
	local isPlayerEvent = bit.band(args.destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
	if isPlayerEvent then return end -- spell steal
	local offensiveDispeller = self:Dispeller("magic", true)
	local target = self:GetUnitIdByGUID(args.destGUID)
	if UnitExists(target) then
		self:SecondaryIcon(args.spellId, target) -- try to mark earth shield target, not really trying too hard tho
	end
	self:TargetMessage(args.spellId, args.destName, "Positive", offensiveDispeller and "Warning")
	if offensiveDispeller then
		self:Flash(args.spellId) -- for pulse (best would be pulse only no flash :S)
	end
end

function mod:Fixate(args)
	self:TargetMessage(-7933, args.destName, "Attention", "Info")
	if self:Me(args.destGUID) then
		self:Flash(-7933)
	end
end

function mod:UNIT_HEALTH_FREQUENT(unit)
	local hp = UnitHealth(unit) / UnitHealthMax(unit) * 100
	if hp < 17 then
		self:Message(-7920, "Neutral", "Info", CL.soon:format(L.extra_adds))
		self:UnregisterUnitEvent("UNIT_HEALTH_FREQUENT", unit)
	end
end

function mod:ExtraAdds()
	self:Message(-7920, "Neutral", "Long", "10% - ".. L.extra_adds)
end

function mod:Adds()
	if self:Heroic() then
		if addWaveCounter == 10 then
			self:Message(-7920, "Neutral", "Long", ("[%d] %s"):format(addWaveCounter, addWaveHc[addWaveCounter]) .. " - " .. L.final_wave)
		else
			self:Message(-7920, "Neutral", "Long", ("[%d] %s"):format(addWaveCounter, addWaveHc[addWaveCounter]))
		end
		if (addWaveCounter == 2 or addWaveCounter == 3 or addWaveCounter == 5 or addWaveCounter == 6 or addWaveCounter == 8 or addWaveCounter == 9) then
			self:Bar(143474, 11.5, self:SpellName(143474), 143474) -- Healing Tide Totem
		end
		addWaveCounter = addWaveCounter + 1
		if addWaveCounter < 11 then
			self:Bar(-7920, 46, ("[%d] %s"):format(addWaveCounter, addWaveHc[addWaveCounter]), "achievement_guildperk_everybodysfriend")
		end
	else
		if addWaveCounter == 10 then
			self:Message(-7920, "Neutral", "Long", CL.count:format(CL.adds, addWaveCounter) .. " - " .. L.final_wave)
		else
			self:Message(-7920, "Neutral", "Long", CL.count:format(CL.adds, addWaveCounter))
		end
		addWaveCounter = addWaveCounter + 1
		if addWaveCounter < 11 then
			self:Bar(-7920, 46, CL.count:format(CL.adds, addWaveCounter), "achievement_guildperk_everybodysfriend")
		end
	end
end

-- Boss

function mod:WarSong(args)
	self:Bar(args.spellId, 3, CL.cast:format(args.spellName))
	self:Message(args.spellId, "Important", "Warning")
end

function mod:Ravager(args)
	if self:Me(args.destGUID) then
		self:Flash(args.spellId)
		self:Say(args.spellId)
	end
	if self:Range(args.destName) < 6 then
		self:RangeMessage(args.spellId)
		self:Flash(args.spellId)
	else
		self:TargetMessage(args.spellId, args.destName, "Urgent", "Alarm")
	end
end

function mod:Banner(args)
	self:Message(143536, "Attention", "Alert")
end

do
	local function warnShockwave(self, player, guid)
		if self:Me(guid) then
			self:Flash(143716)
		elseif self:Range(player) < 8 then
			self:RangeMessage(143716, "Personal", "Alarm")
			self:Flash(143716)
			return
		end
		self:TargetMessage(143716, player, "Urgent", "Alarm")
	end
	function mod:HeroicShockwave(unit, _, _, _, spellId)
		if spellId == 143500 then -- Heroic Shockwave
			self:GetBossTarget(warnShockwave, 0.2, UnitGUID(unit))
		end
	end
end

function mod:CoolingOff(args)
	self:Bar(args.spellId, 15)
end

function mod:Stances(args)
	self:Message(-7915, "Positive", args.spellId == 143593 and "Alert", args.spellName, args.spellId) -- Play sound if he switches to defensive -- this might conflich with War Song
	local nextStance
	if args.spellId == 143589 then -- battle
		nextStance = 143594 -- berserker
	elseif args.spellId == 143594 then -- berserker
		nextStance = 143593 -- defensive
		self:DelayedMessage(-7915, 55, "Positive", CL.custom_sec:format(self:SpellName(nextStance), 5), nextStance, "Alert")
		self:DelayedMessage(-7915, 57, "Positive", CL.custom_sec:format(self:SpellName(nextStance), 3), nextStance, "Alert")
		self:DelayedMessage(-7915, 59, "Positive", CL.custom_sec:format(self:SpellName(nextStance), 1), nextStance, "Alert")
	elseif args.spellId == 143593 then -- defensive
		nextStance = 143589 -- battle
	end
	self:Bar(-7915, 60, L.stance_bar:format(stances[nextStance], stances[args.spellId]), nextStance)
end

do
	function mod:BoneCrackerRemoved(args)
		if self.db.profile.custom_off_bonecracker_marks then
			for i = 1, 7 do
				if marksUsed[i] == args.destName then
					marksUsed[i] = false
					SetRaidTarget(args.destName, 0)
				end
			end
		end
	end

	local function markBonecrackers(destName)
		for i = 1, 7 do
			if not marksUsed[i] then
				SetRaidTarget(destName, i)
				marksUsed[i] = destName
				return
			end
		end
	end
	function mod:BoneCrackerApplied(args)
		if self:Me(args.destGUID) then
			self:TargetMessage(args.spellId, args.destName, "Personal", "Info") -- so you know to be extra careful since your max hp is halved
		end
		if self.db.profile.custom_off_bonecracker_marks then
			markBonecrackers(args.destName)
		end
	end
end

function mod:BoneCracker(args)
	self:Message(args.spellId, "Urgent")
	self:Bar(args.spellId, 32)
end

function mod:SunderingBlow(args)
	self:StackMessage(args.spellId, args.destName, args.amount, "Attention", "Info")
	self:CDBar(args.spellId, 8)
end

