--[[
TODO:
	look into doing :win without trigger that requires localization
	could maybe hook into the world state timer, but I'm not sure if there is much point to work on a code just for that
	could maybe pre warn for keg toss at least for one of the targets, but mob is not on boss frames, so a bit aids
]]--

--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Spoils of Pandaria", 953, 870)
if not mod then return end
mod:RegisterEnableMob(73152, 73720, 71512) -- Storeroom Guard ( trash guy ), Mogu Spoils, Mantid Spoils

--------------------------------------------------------------------------------
-- Locals
--

local sparkCounter = 0
local bossUnitPowers = {}

local function checkPlayerSide()
	BigWigsLoader.SetMapToCurrentZone()
	local cx, cy = GetPlayerMapPosition("player")
	if cy == 0 then return 0 end

	-- simplified cross product: above (mantid) > 0 (colinear) > below (mogu)
	return 0.04362700914 - (cx * 0.11017924547) + (cy * 0.04940152168)
end

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.start_trigger = "Hey, we recording?"
	L.win_trigger = "System resetting. Don't turn the power off, or the whole thing will probably explode."

	L.enable_zone = "Artifact Storage"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{146815, "FLASH"},
		145288, {145461, "TANK"}, {142947, "TANK"}, 142694, -- Mogu crate
		{145987, "FLASH"}, 145747, {145692, "TANK"}, 145715, {145786, "DISPEL"},-- Mantid crate
		{146217, "FLASH"}, 146222, 146257, -- Crate of Panderan Relics
		{"warmup", "EMPHASIZE"}, "berserk", "bosskill",
	}, {
		[146815] = CL.heroic,
		[145288] = -8434, -- Mogu crate
		[145987] = -8439, -- Mantid crate
		[146217] = -8366, -- Crate of Panderan Relics
		["warmup"] = "general",
	}
end

function mod:OnRegister() -- XXX check out replacing this with the chest id
	-- Kel'Thuzad v3
	local f = CreateFrame("Frame")
	local func = function()
		if not mod:IsEnabled() and GetSubZoneText() == L.enable_zone then
			mod:Enable()
		end
	end
	f:SetScript("OnEvent", func)
	f:RegisterEvent("ZONE_CHANGED_INDOORS")
	f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	func()
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")
	self:RegisterEvent("ENCOUNTER_END")

	-- Crate of Panderan Relics
	self:Log("SPELL_DAMAGE", "PathOfBlossoms", 146257)
	self:Log("SPELL_CAST_START", "BreathOfFire", 146222)
	self:Log("SPELL_AURA_APPLIED", "KegToss", 146217)
	-- Mogu crate
	self:Log("SPELL_CAST_START", "CrimsonReconstitution", 142947)
	self:Log("SPELL_PERIODIC_HEAL", "CrimsonReconstitutionHeal", 145271)
	self:Log("SPELL_CAST_START", "MoguRuneOfPower", 145461)
	self:Log("SPELL_CAST_START", "MatterScramble", 145288)
	self:Log("SPELL_CAST_SUCCESS", "SparkOfLife", 142765) -- Pulse
	self:Log("SPELL_CAST_SUCCESS", "SparkOfLifeDeath", 149277) -- Nova
	-- Mantid crate
	self:Log("SPELL_AURA_APPLIED", "Residue", 145790)
	self:Log("SPELL_CAST_START", "ResidueStart", 145786)
	self:Log("SPELL_DAMAGE", "BlazingCharge", 145715)
	self:Log("SPELL_AURA_APPLIED", "BlazingCharge", 145716)
	self:Log("SPELL_AURA_APPLIED", "WarcallerEnrage", 145692)
	self:Log("SPELL_DAMAGE", "BubblingAmber", 145748)
	self:Log("SPELL_AURA_APPLIED", "BubblingAmber", 145747)
	self:Log("SPELL_AURA_APPLIED", "SetToBlowApplied", 145987)
	self:Log("SPELL_AURA_REMOVED", "SetToBlowRemoved", 145987)

	self:Yell("Warmup", L.start_trigger)
	self:Yell("Win", L.win_trigger)
end

function mod:ENCOUNTER_END(_, id, name, diff, size, win)
	-- Sometimes there's a long delay between the last IEEU and IsEncounterInProgress being false so use this instead.
	if id == 1594 then
		if win == 1 then
			self:Win(true)
		else
			self:Wipe()
		end
	end
end

function mod:Warmup()
	self:Bar("warmup", 19, COMBAT, "achievement_boss_spoils_of_pandaria")
end

function mod:OnEngage()
	if self:Heroic() then
		self:RegisterUnitEvent("UNIT_POWER_FREQUENT", nil, "boss1", "boss2")
	end

	sparkCounter = 0
	wipe(bossUnitPowers)
	self:RegisterEvent("UPDATE_WORLD_STATES") -- berserk
	-- Sometimes there's a long delay between the last IEEU and IsEncounterInProgress being false so use this as a backup.
	self:StopWipeCheck()
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "StartWipeCheck")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "StopWipeCheck")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

-- Heroic

function mod:UNIT_POWER_FREQUENT(unit, powerType)
	local power = UnitPower(unit, 10)
	if powerType ~= "ALTERNATE" or power == 0 then return end -- == 0 might be needed when you change rooms
	local playerSide, mobId = checkPlayerSide(), self:MobId(UnitGUID(unit))
	if bossUnitPowers[mobId] == power then return end -- don't fire twice for the same value
	bossUnitPowers[mobId] = power
	if ((mobId == 71512 or mobId == 73721) and playerSide < 0) or ((mobId == 73720 or mobId == 73722) and playerSide > 0) then -- mantid spoils and you are on mogu side OR  mogu spoils and you are on mantid side
		self:Message(146815, "Important", "Alert", CL.incoming:format(self:SpellName(-8469))) -- Unstable Spark
		if self:Damager() then
			self:Flash(146815)
		end
	end
end

-- Crate of Panderan Relics

do
	local prev = 0
	function mod:PathOfBlossoms(args)
		local t = GetTime()
		if t-prev > 2 and self:Me(args.destGUID) then -- don't spam
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL.underyou:format(args.spellName))
		end
	end
end

function mod:BreathOfFire(args) -- XXX no position check, could use :GetUnitIdByGUID, strip "target" and do a range check?
	local debuffed = UnitDebuff("player", self:SpellName(146217)) -- Keg Toss
	self:Message(args.spellId, "Attention", debuffed and "Long")
	if debuffed then
		self:Flash(146217) -- flash again
	end
end

function mod:KegToss(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Personal", "Info")
		self:Flash(args.spellId)
	end
end

-- Mogu crate
function mod:CrimsonReconstitution(args)
	if checkPlayerSide() < 0 then
		self:Message(args.spellId, "Urgent", "Warning", CL.casting:format(args.spellName))
	end
end

do
	local prev = 0
	function mod:CrimsonReconstitutionHeal()
		local t = GetTime()
		if t-prev > 2 and checkPlayerSide() < 0 then
			prev = t
			self:Message(145271, "Urgent", "Alarm")
		end
	end
end

function mod:MoguRuneOfPower(args)
	if checkPlayerSide() < 0 then
		self:Message(args.spellId, "Urgent", "Alarm")
	end
end

function mod:MatterScramble(args)
	if checkPlayerSide() < 0 then
		self:Message(args.spellId, "Important", "Alert", ("%s - %s"):format(args.spellName, CL.incoming:format(self:SpellName(125619))))
		self:Bar(args.spellId, 8, 125619) -- 125619 = Explosion
	end
end

function mod:SparkOfLife()
	if checkPlayerSide() < 0 then
		sparkCounter = sparkCounter + 1
		self:Message(142694, "Attention", nil, CL.count:format(self:SpellName(-8380), sparkCounter))
	end
end

function mod:SparkOfLifeDeath()
	if checkPlayerSide() < 0 and sparkCounter > 0 then -- counting after side check to prevent straggling kills messing with counts on room transition
		sparkCounter = sparkCounter - 1
	end
end

-- Mantid crate
do
	local prev = 0
	function mod:Residue(args)
		local t = GetTime()
		if t-prev > 2 and checkPlayerSide() > 0 and self:Dispeller("magic", true, 145786) then
			prev = t
			self:Message(145786, "Urgent", "Alarm")
		end
	end
end

function mod:ResidueStart(args)
	if checkPlayerSide() > 0 and self:Dispeller("magic", true, args.spellId) then
		self:Message(args.spellId, "Attention", nil, CL.casting:format(args.spellName))
	end
end

function mod:WarcallerEnrage(args)
	if checkPlayerSide() > 0 then
		self:TargetMessage(args.spellId, args.destName, "Urgent", "Alarm")
	end
end

do
	local prev = 0
	function mod:BlazingCharge(args)
		local t = GetTime()
		if t-prev > 2 and self:Me(args.destGUID) then -- don't spam
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL.underyou:format(args.spellName))
		end
	end
end

do
	local prev = 0
	function mod:BubblingAmber(args)
		local t = GetTime()
		if t-prev > 2 and self:Me(args.destGUID) then -- don't spam
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL.underyou:format(args.spellName))
		end
	end
end

function mod:SetToBlowRemoved(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Positive", nil, CL.over:format(args.spellName))
		self:StopBar(args.spellId, args.destName)
	end
end

function mod:SetToBlowApplied(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Important", "Warning", CL.you:format(args.spellName))
		self:TargetBar(args.spellId, 30, args.destName)
		self:Flash(args.spellId)
	end
end

function mod:UPDATE_WORLD_STATES()
	-- NEW MISSION! I want you to blow up... THE OCEAN!
	-- If it wasn't clear from this code, I don't trust this API at all.
	-- Hardcoding the values and firing :Berserk on engage/room change seemed to end up with timers going out of sync.
	-- Doing this without timer refreshing every 60 seconds also ended up with sync issues.
	-- Repeatedly running through LFR to test various methods was also a delightful experience.
	-- Pretty much, I hate it. The only positive from this is that we don't need to schedule the messages.
	-- If this ever breaks in a future patch, $#!+.
	local _, _, _, enrage = GetWorldStateUIInfo(5)
	if enrage then
		local remaining = enrage:match("%d+")
		if remaining then
			local timeRemaining = tonumber(remaining)
			if timeRemaining and timeRemaining > 0 then
				if timeRemaining > prevEnrage or timeRemaining % 60 == 0 then
					self:Bar("berserk", timeRemaining+1, 26662) -- +1s to compensate for timer rounding.
				end
				-- It shouldn't fire the same value twice, but throttle for safety.
				if timeRemaining ~= prevEnrage and (timeRemaining == 60 or timeRemaining == 30 or timeRemaining == 10 or timeRemaining == 5) then
					self:Message("berserk", "Positive", nil, format(CL.custom_sec, self:SpellName(26662), timeRemaining), 26662)
				end
				prevEnrage = timeRemaining
			end
		end
	end
end
