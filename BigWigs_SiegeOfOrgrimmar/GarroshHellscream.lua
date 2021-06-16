--[[
TODO:
]]--
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Garrosh Hellscream", 953, 869)
if not mod then return end
mod:RegisterEnableMob(71865)

--------------------------------------------------------------------------------
-- Locals
--

local annihilateCounter
local markableMobs = {}
local marksUsed = {}
local markTimer = nil
local markTimerTwo = nil
local canWarn = true
local timerNeedsUpdate = true
local mcCounter = 1
local iconCounter = 1
local farseerCounter = 1
local bombardmentCounter = 1
local engineerCounter = 1
local desecrateCD = 41
local desecrateCounter = 1
local phase = 1
local firstRealmEntered = nil
local function getBossByMobId(mobId)
	for i=1, 5 do
		if mod:MobId(UnitGUID("boss"..i)) == mobId then
			return "boss"..i
		end
	end
	return
end
local waveTimers = {45, 45, 40}
local waveTimer, waveCounter = nil, 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.intermission = "Intermission"
	L.mind_control = "Mind Control"

	L.chain_heal = mod:SpellName(144583)
	L.chain_heal_desc = "Heals a friendly target for 40% of their max health, chaining to nearby friendly targets."
	L.chain_heal_message = "Your focus is casting Chain Heal!"
	L.chain_heal_bar = "Focus: Chain Heal"

	L.farseer_trigger = "Farseers, mend our wounds!"

	L.ironstar_trigger1 = "Witness the power of the True Horde's arsenal!"
	L.ironstar_trigger2 = "We will cleanse this world in steel and fire!"

	L.phase4_pre_trigger = "You think you have WON?"

	L.focus_only = "|cffff0000Focus target alerts only.|r "

	L.yougotyour = "You got your %s back!"
	L.stun = "Garrosh is Stunned!"
	L.fail = "FAIL!"

	L.ironstar = "Iron Star"
	L.ironstar_desc = "After becoming activated by the Siege Engineers the Iron Star will roll across the room, slamming into the opposite wall."
	L.ironstar_icon = "ability_garrosh_siege_engine"
	L.ironstar_impact = "Iron Star Impact"

	L.personal_malice = "Malice: Personal"
	L.personal_malice_desc = "Say tick-counter and Sound warnings for the Malice debuff."
	L.personal_malice_icon = 147209

	L.bombardment = mod:SpellName(147088)
	L.bombardment_desc = "Bombarding Stormwind! Fires a Kor'kron Iron Star at clustered enemies."
	L.bombardment_icon = 147120

	L.unstableironstar = "Unstable Iron Star"
	L.unstableironstar_desc = "The Horde Fleet noticed a cluster of enemies and fires an Unstable Iron Star at the target. Unstable Iron Star will stun any target it impacts with, including Garrosh."
	L.unstableironstar_icon = 147047

	L.custom_off_mc_mark = "Touch of Y'Shaarj marker"
	L.custom_off_mc_mark_desc = "Mark people that have Touch of Y'Shaarj with {rt1}{rt2}{rt3}{rt4}{rt5}{rt6}{rt7}{rt8}, requires promoted or leader.\n|cFFFF0000Only 1 person in the raid should have this enabled to prevent marking conflicts.|r"
	L.custom_off_mc_mark_icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8"

	L.custom_off_addmarker = "Minion of Y'Shaarj marker"
	L.custom_off_addmarker_desc = "Marks Minion of Y'Shaarj, requires promoted or leader.\n|cFFFF0000Only 1 person in the raid should have this enabled to prevent marking conflicts.|r"
	L.custom_off_addmarker_icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8"
end
L = mod:GetLocale()
L.chain_heal_desc = L.focus_only..L.chain_heal_desc

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		-8298, -8292, 144821, "ironstar", -- phase 1
		-8294, "chain_heal", -- Farseer
		-8305, {144945, "FLASH"}, 144969, 144954, -- Intermissions
		145065, {144985, "FLASH"}, {145183, "TANK"}, -- phase 2
		-8325, -- phase 3
		{147209, "FLASH", "SAY"}, {"personal_malice", "EMPHASIZE", "SAY"}, "bombardment", 147011, {"unstableironstar", "FLASH", "SAY"}, 148440,-- phase 4
		"custom_off_mc_mark",
		"custom_off_addmarker",
		{144758, "SAY", "FLASH"},
		"stages", --[["berserk",]] "bosskill",
	}, {
		[-8298] = -8288, -- phase 1
		[-8294] = -8294, -- Farseer
		[-8305] = -8305, -- Intermissions
		[145065] = -8307, -- phase 2
		[-8325] = -8319, -- phase 3
		[147209] = "Stage Four: Realm of Garrosh", -- phase 4
		["custom_off_mc_mark"] = L.custom_off_mc_mark,
		["custom_off_addmarker"] = L.custom_off_addmarker,
		[144758] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1", "boss2", "boss3")

	-- phase 4
	self:Yell("Phase4soon", L["phase4_pre_trigger"])
	self:Log("SPELL_CAST_START", "CallBombardment", 147120)
	self:Log("SPELL_CAST_START", "ManifestRage", 147011)
	self:Log("SPELL_CAST_SUCCESS", "IronStarFixate", 147665)
	self:Log("SPELL_ENERGIZE", "MaliceFail", 147236)
	self:Log("SPELL_AURA_APPLIED", "Malice", 147209)
	self:Log("SPELL_AURA_APPLIED", "IronStarStun", 147177)
	self:Log("SPELL_AURA_APPLIED", "WeakMinded", 148440)
	self:Emote("UnstableIronStar", "147047")
	-- phase 2
	self:Log("SPELL_CAST_SUCCESS", "MindControlSuccess", 145065, 145171)
	self:Log("SPELL_AURA_APPLIED", "MindControlApplied", 145065, 145171, 145071, 145175) --145071, 145175 are the player casts on other players
	self:Log("SPELL_AURA_REMOVED", "MindControlRemoved", 145065, 145171, 145071, 145175)
	self:Log("SPELL_AURA_APPLIED_DOSE", "GrippingDespair", 145183, 145195)
	self:Log("SPELL_AURA_APPLIED", "GrippingDespair", 145183, 145195)
	self:Log("SPELL_CAST_START", "WhirlingCorruption", 144985, 145037)
	self:Log("SPELL_SUMMON", "AddMarkedMob", 145033)
	-- Intermissions
	self:Log("SPELL_CAST_START", "Annihilate", 144969)
	self:Log("SPELL_AURA_REMOVED", "YShaarjsProtection", 144945)
	self:Log("SPELL_AURA_APPLIED", "InsideReduction", 149004, 148983, 148994) -- Hope, Courage, Faith
	-- phase 1
	self:Log("SPELL_CAST_START", "ChainHeal", 144583)
	self:Log("SPELL_CAST_START", "HellscreamsWarsong", 144821)
	self:Yell("Farseer", L["farseer_trigger"])
	self:Yell("IronStar", L["ironstar_trigger1"], L["ironstar_trigger2"])
	self:Emote("SiegeEngineer", "144616")
	self:Log("SPELL_CAST_SUCCESS", "DesecratedWeapon", 144748, 144749)
	self:Log("SPELL_PERIODIC_DAMAGE", "DesecrateDamage", 144762, 144817)
	self:Log("SPELL_PERIODIC_MISSED", "DesecrateDamage", 144762, 144817)
	self:Death("Deaths", 71865, 71983) -- Garrosh Hellscream, Farseer Wolf Rider
end

--"<0.2 23:15:40> [CHAT_MSG_MONSTER_YELL] CHAT_MSG_MONSTER_YELL#I, Garrosh, son of Grom, will show you what it means to be called Hellscream!#Garrosh Hellscream###Viklund##0#0##0#2527#nil#0#false#false", -- [6]

--"<130.7 23:17:51> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#0#0x0380000004DA4FA9#Sonie#1300#0#149004#Hope#2#DEBUFF", -- [59253]
--"<321.6 23:21:02> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#0#0x0380000004ABE1B3#Pottm#1300#0#148983#Courage#2#DEBUFF", -- [123821]
--"<336.6 22:57:09> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#0#0x03800000048BF754#Blattardos#1300#0#148994#Faith#2#DEBUFF", -- [130467]

function mod:OnEngage(diff)
	waveCounter = 1
	waveTimer = self:ScheduleTimer("NewWave", waveTimers[waveCounter])
	self:Bar(-8292, waveTimers[waveCounter], nil, 144582)
	--self:Berserk(900, nil, nil, "Berserk (assumed)") -- XXX assumed
	annihilateCounter = 1
	self:Bar(144758, 10.8) -- DesecratedWeapon
	self:Bar(144821, 20) -- Hellscream's Warsong
	self:Bar(-8298, 20, EJ_GetSectionInfo(8298), 144616) -- Siege Engineer
	self:Bar(-8294, 30, nil, 144584) -- Farseer
	iconCounter = 1
	farseerCounter = 1
	bombardmentCounter = 1
	engineerCounter = 1
	desecrateCD = 41
	phase = 1
	firstRealmEntered = nil
	wipe(markableMobs)
	wipe(marksUsed)
	markTimer = nil
	markTimerTwo = nil
	canWarn = true
	timerNeedsUpdate = true
	if self.db.profile.custom_off_addmarker then
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

-- phase 4

--"<701.5 21:55:14> [CHAT_MSG_MONSTER_YELL] CHAT_MSG_MONSTER_YELL#You think you have WON?  You are BLIND.  I WILL FORCE YOUR EYES OPEN.#Garrosh Hellscream#####0#0##0#2780#nil#0#false#false", -- [217037]
--"<720.7 21:55:33> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Enter Realm of Garrosh::0:146984]]", -- [221814]
--"<685.4 19:39:44> [CHAT_MSG_MONSTER_YELL] CHAT_MSG_MONSTER_YELL#You think you have WON?  You are BLIND.  I WILL FORCE YOUR EYES OPEN.#Garrosh Hellscream#####0#0##0#1227#nil#0#false#false", -- [217124]
--"<704.7 19:40:04> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Enter Realm of Garrosh::0:146984]]", -- [221771]
--19.2, 19.3

function mod:Phase4soon()
	self:Message("stages", "Neutral", nil, CL["soon"]:format(CL["phase"]:format(phase+1)), false)
	self:Bar("stages", 19.2, CL["phase"]:format(phase+1), 147011)
	self:StopBar(145037) -- Empowered Whirling Corruption
	self:StopBar(144758) -- Desecrated Weapon
	self:StopBar(L["mind_control"]) -- Mind Control
	self:StopBar(L["intermission"])	-- Intermission
end

--"<721.9 21:55:35> [CLEU] SPELL_AURA_APPLIED#false#0x0380000004940808#Infeh#1297#16#0x0380000004940808#Infeh#1297#16#148440#Weak Minded#32#DEBUFF", -- [221985]
--"<737.0 21:55:50> [CLEU] SPELL_AURA_REMOVED#false#0x0380000004940808#Infeh#1297#16#0x0380000004940808#Infeh#1297#16#148440#Weak Minded#32#DEBUFF", -- [222342]

function mod:WeakMinded(args)
	if self:Me(args.destGUID) then
		self:Bar(args.spellId, 15)
	end
end

--"<776.8 19:41:16> [CHAT_MSG_RAID_BOSS_EMOTE] CHAT_MSG_RAID_BOSS_EMOTE#|TInterface\\Icons\\ability_garrosh_siege_engine.blp:20|t The Fleet Captain detected a cluster! Firing |cFFFF0000|Hspell:147047|h[Unstable Iron Star]|h|r!#Clump###Leeds##0#0##0#1267#nil#0#false#false", -- [236615]
--"<780.5 19:41:19> [CHAT_MSG_RAID_BOSS_EMOTE] CHAT_MSG_RAID_BOSS_EMOTE#|TInterface\\Icons\\ability_garrosh_siege_engine.blp:20|t The Fleet Captain detected a cluster! Firing |cFFFF0000|Hspell:147047|h[Unstable Iron Star]|h|r!#Clump###Vál##0#0##0#1268#nil#0#false#false", -- [237671]

function mod:UnstableIronStar()
	self:Message("unstableironstar", "Important", "Warning", L["unstableironstar"], L.unstableironstar_icon)
	self:Flash("unstableironstar")
end

--"<841.1 21:57:34> [CLEU] SPELL_AURA_APPLIED#false#0xF1311D630001686D#Ko'kron Iron Star#2632#0#0xF15118B900014D82#Garrosh Hellscream#68168#0#147177#Unstable Iron Star#4#BUFF", -- [245619]

function mod:IronStarStun(args)
	self:Message("unstableironstar", "Positive", nil, L["stun"], 147177)
end

--"<784.3 19:41:23> [CLEU] SPELL_CAST_SUCCESS#false#0xF1311D6300007CB8#Ko'kron Iron Star#2632#0#0x038000000505AD5B#Smootie#1300#0#147665#Fixate#1", -- [238358]
--"<784.4 19:41:23> [CLEU] SPELL_AURA_APPLIED#false#0xF1311D6300007CB8#Ko'kron Iron Star#2632#0#0x038000000505AD5B#Smootie#1300#0#147665#Fixate#1#DEBUFF", -- [238384]

function mod:IronStarFixate(args)
	if self:Me(args.destGUID) then
		self:Message("unstableironstar", "Personal", "Info", CL["you"]:format(L["unstableironstar"]), L.unstableironstar_icon)
		self:Flash("unstableironstar")
		self:Say("unstableironstar", L["unstableironstar"])
	else
		self:TargetMessage("unstableironstar", args.destName, "Important", nil, L["ironstar"], L.unstableironstar_icon)
	end
	self:TargetBar("unstableironstar", 12, args.destName, L["ironstar"], L.unstableironstar_icon)
end

--"<738.7 00:38:06> [CLEU] SPELL_AURA_APPLIED#false#0xF15118B900018311#Garrosh Hellscream#68168#2#0x038000000505AD5B#Smootie#1300#0#147209#Malice#32#DEBUFF", -- [233962]
--"<740.9 00:38:08> [CLEU] SPELL_DAMAGE#true##nil#1300#0#0x0380000004940808#Infeh#1297#16#147235#Malicious Blast#32#354872#-1#32#nil#nil#nil#nil#nil#nil#nil", -- [234509]
--"<740.9 00:38:08> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#0#0x0380000004940808#Infeh#1297#16#147235#Malicious Blast#32#DEBUFF", -- [234510]

--"<743.0 00:38:10> [CLEU] SPELL_DAMAGE#true##nil#1300#0#0x0380000004D6A55B#Ashvael#1300#0#147235#Malicious Blast#32#342382#-1#32#nil#nil#nil#nil#nil#nil#nil", -- [235037]
--"<743.0 00:38:10> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#0#0x0380000004D6A55B#Ashvael#1300#0#147235#Malicious Blast#32#DEBUFF", -- [235038]

--"<745.0 00:38:12> [CLEU] SPELL_DAMAGE#true##nil#1300#0#0x0380000004945DDF#Sco#1298#0#147235#Malicious Blast#32#111243#-1#32#nil#nil#150128#nil#nil#nil#nil", -- [235539]
--"<745.0 00:38:12> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#0#0x0380000004945DDF#Sco#1298#0#147235#Malicious Blast#32#DEBUFF", -- [235540]

--"<746.9 00:38:14> [CLEU] SPELL_DAMAGE#true##nil#1300#0#0x0380000004945DDF#Sco#1298#0#147235#Malicious Blast#32#386364#-1#32#nil#nil#68863#nil#nil#nil#nil", -- [235990]
--"<746.9 00:38:14> [CLEU] SPELL_AURA_APPLIED_DOSE#true##nil#1300#0#0x0380000004945DDF#Sco#1298#0#147235#Malicious Blast#32#DEBUFF#2", -- [235991]

--"<748.9 00:38:16> [CLEU] SPELL_DAMAGE#true##nil#1300#0#0x03800000049465A6#Perfecto#1300#0#147235#Malicious Blast#32#203902#-1#32#nil#nil#150656#nil#nil#nil#nil", -- [236497]
--"<748.9 00:38:16> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#0#0x03800000049465A6#Perfecto#1300#0#147235#Malicious Blast#32#DEBUFF", -- [236498]

--"<750.8 00:38:18> [CLEU] SPELL_MISSED#true##nil#1300#0#0x0380000004945DDF#Sco#1298#0#147235#Malicious Blast#32#ABSORB#nil#257364", -- [237012]
--"<750.8 00:38:18> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#0#0x0380000004945DDF#Sco#1298#0#147235#Malicious Blast#32#DEBUFF", -- [237013]

--"<752.8 00:38:20> [CLEU] SPELL_AURA_REMOVED#false#0xF15118B900018311#Garrosh Hellscream#2632#2#0x038000000505AD5B#Smootie#1300#0#147209#Malice#32#DEBUFF", -- [237561]

--7ticks
do
	local function maliceMessage(remainingTicks)
		mod:Message("personal_malice", "Personal", "Info", ("%d"):format(remainingTicks), L.malice_icon)
		mod:Say("personal_malice", ("%d"):format(remainingTicks), true)
	end
	function mod:Malice(args)
		if self:Me(args.destGUID) then
			self:Message(args.spellId, "Personal", "Info", CL["you"]:format(args.spellName))
			self:Flash(args.spellId)
			self:Say(args.spellId)
			self:ScheduleTimer(maliceMessage, 2, 6)
			self:ScheduleTimer(maliceMessage, 4, 5)
			self:ScheduleTimer(maliceMessage, 6, 4)
			self:ScheduleTimer(maliceMessage, 8, 3)
			self:ScheduleTimer(maliceMessage, 10, 2)
			self:ScheduleTimer(maliceMessage, 12, 1)
		else
			self:TargetBar(args.spellId, 14, args.destName)
			self:TargetMessage(args.spellId, args.destName, "Attention")
		end
		self:Bar(args.spellId, 30.2)
	end
end

--"<738.7 00:38:06> [CLEU] SPELL_AURA_APPLIED#false#0xF15118B900018311#Garrosh Hellscream#68168#2#0x038000000505AD5B#Smootie#1300#0#147209#Malice#32#DEBUFF", -- [233962]
--"<751.1 00:38:18> [CLEU] SPELL_MISSED#false#0xF15118B900018311#Garrosh Hellscream#2632#2#0x038000000505AD5B#Smootie#1300#0#147733#Malicious Energy Explosion#32#MISS#nil", -- [237096]
--"<752.8 00:38:20> [CLEU] SPELL_AURA_REMOVED#false#0xF15118B900018311#Garrosh Hellscream#2632#2#0x038000000505AD5B#Smootie#1300#0#147209#Malice#32#DEBUFF", -- [237561]

--"<809.5 00:39:16> [CLEU] SPELL_DAMAGE#false#0xF15118B900018311#Garrosh Hellscream#68168#2#0x0380000004D6A55B#Ashvael#1300#0#147733#Malicious Energy Explosion#32#176065#-1#32#nil#nil#nil#nil#nil#nil#nil", -- [250904]

--"<829.0 19:42:08> [CLEU] SPELL_CAST_START#false#0xF15118B9000064BB#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#147120#Call Bombardment#1", -- [243293]

--"<774.0 19:41:13> [CLEU] SPELL_CAST_START#false#0xF15118B9000064BB#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#147120#Call Bombardment#1", -- [235752]
--"<829.0 19:42:08> [CLEU] SPELL_CAST_START#false#0xF15118B9000064BB#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#147120#Call Bombardment#1", -- [243293]

do
	local bombardmentTimers = {55, 40, 40, 25} -- need more data
	function mod:CallBombardment(args)
		self:Message("bombardment", "Urgent", "Alert", self:SpellName(147088), L.bombardment_icon)
		self:Bar("bombardment", 13, CL["cast"]:format(self:SpellName(147088)), L.bombardment_icon)
		self:Bar("bombardment", bombardmentTimers[bombardmentCounter] or 25, self:SpellName(147088), L.bombardment_icon)
		bombardmentCounter = bombardmentCounter + 1
	end	
end

--"<801.4 00:39:08> [CLEU] SPELL_CAST_START#false#0xF15118B900018311#Garrosh Hellscream#68168#2##nil#-2147483648#-2147483648#147011#Manifest Rage#32", -- [248719]

function mod:ManifestRage(args)
	timerNeedsUpdate = true -- so the timer can restart again at 1e
	self:Message(args.spellId, "Neutral", "Alarm")
	self:StopBar(147011)
end	

--"<770.2 19:41:09> [UNIT_POWER] ENERGY#3#50#100#0#0", -- [234707]
--"<779.5 19:41:18> [UNIT_POWER] ENERGY#3#60#100#0#0", -- [237409]

--"<797.2 19:41:36> [UNIT_POWER] ENERGY#3#80#100#0#0", -- [241124]
--"<806.5 19:41:45> [UNIT_POWER] ENERGY#3#90#100#0#0", -- [241804]
--9.3, 9.2

--"<815.7 19:41:55> [CLEU] SPELL_CAST_START#false#0xF15118B9000064BB#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#147011#Manifest Rage#32", -- [242437]

--"<720.7 21:55:33> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Enter Realm of Garrosh::0:146984]]", -- [221814]
--"<727.1 21:55:40> [UNIT_POWER] ENERGY#3#0#100#0#0", -- [222057]
--"<741.2 21:55:54> [UNIT_POWER] ENERGY#3#1#100#0#0", -- [222713]
--"<749.2 21:56:02> [UNIT_POWER] ENERGY#3#10#100#0#0", -- [224280]
--"<758.1 21:56:11> [UNIT_POWER] ENERGY#3#20#100#0#0", -- [226683]
--"<767.4 21:56:20> [UNIT_POWER] ENERGY#3#30#100#0#0", -- [229311]
--"<776.2 21:56:29> [UNIT_POWER] ENERGY#3#40#100#0#0", -- [231655]
--"<785.1 21:56:38> [UNIT_POWER] ENERGY#3#50#100#0#0", -- [233782]
--"<794.4 21:56:47> [UNIT_POWER] ENERGY#3#60#100#0#0", -- [236131]
--"<803.2 21:56:56> [UNIT_POWER] ENERGY#3#70#100#0#0", -- [237901]
--"<812.0 21:57:05> [UNIT_POWER] ENERGY#3#80#100#0#0", -- [239508]
--"<821.3 21:57:14> [UNIT_POWER] ENERGY#3#90#100#0#0", -- [241568]
--"<830.2 21:57:23> [UNIT_POWER] ENERGY#3#100#100#0#0", -- [243669]
--"<830.6 21:57:23> [CLEU] SPELL_CAST_START#false#0xF15118B900014D82#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#147011#Manifest Rage#32", -- [243762]
--22.1, 8.9, 9.3, 8.8, 8.9, 9.3, 8.8, 8.8, 9.3, 8.9 (counting from 0)
--103.1, 89
--9.0 average

--"<704.7 19:40:04> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Enter Realm of Garrosh::0:146984]]", -- [221771]
--"<720.4 19:40:19> [UNIT_POWER] ENERGY#3#0#100#0#0", -- [221940]
--"<726.1 19:40:25> [UNIT_POWER] ENERGY#3#1#100#0#0", -- [222770]
--"<734.4 19:40:33> [UNIT_POWER] ENERGY#3#10#100#0#0", -- [224639]
--"<743.3 19:40:42> [UNIT_POWER] ENERGY#3#20#100#0#0", -- [227028]
--"<752.5 19:40:51> [UNIT_POWER] ENERGY#3#30#100#0#0", -- [229656]
--"<761.4 19:41:00> [UNIT_POWER] ENERGY#3#40#100#0#0", -- [232377]
--"<770.2 19:41:09> [UNIT_POWER] ENERGY#3#50#100#0#0", -- [234707]
--"<779.5 19:41:18> [UNIT_POWER] ENERGY#3#60#100#0#0", -- [237409]
--"<788.4 19:41:27> [UNIT_POWER] ENERGY#3#70#100#0#0", -- [239029]
--"<797.2 19:41:36> [UNIT_POWER] ENERGY#3#80#100#0#0", -- [241124]
--"<806.5 19:41:45> [UNIT_POWER] ENERGY#3#90#100#0#0", -- [241804]
--"<815.3 19:41:54> [UNIT_POWER] ENERGY#3#100#100#0#0", -- [242395]
--"<815.7 19:41:55> [CLEU] SPELL_CAST_START#false#0xF15118B9000064BB#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#147011#Manifest Rage#32", -- [242437]
--14.0, 8.9, 9.2, 8.9, 8.8, 9.3, 8.9, 8.8, 9.3, 8.8
--94.9, 89.2
--8.98 average

--first malice at 10e
--second malice at 44e
--third malice at 77e
--fourth malice at 11e
--fifth malice at 45e
--sixth malice at 79e

--first check at 30e, after 1st malice
--second check at 60e, after 2nd malice

--"<842.6 21:57:35> [UNIT_POWER] ENERGY#3#14#100#0#0", -- [245976]
--"<815.7 19:41:55> [CLEU] SPELL_CAST_START#false#0xF15118B9000064BB#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#147011#Manifest Rage#32", -- [242437]
--"<843.5 21:57:36> [CLEU] SPELL_ENERGIZE#true##nil#1300#0#0xF15118B900014D82#Garrosh Hellscream#68168#0#147236#Malicious Energy#32#5#3#nil", -- [246184]
--"<843.8 21:57:37> [UNIT_POWER] ENERGY#3#20#100#0#0", -- [246233]
--"<843.9 21:57:37> [CLEU] SPELL_MISSED#false#0xF15118B900014D82#Garrosh Hellscream#68168#0#0x0380000004ABE1B3#Pottm#1300#4#147733#Malicious Energy Explosion#32#DEFLECT#nil", -- [246255]

function mod:MaliceFail(args)
	self:Message(147209, "Important", nil, ("%s %s"):format(self:SpellName(147209), L["fail"]))
	timerNeedsUpdate = true
end

function mod:UNIT_POWER_FREQUENT(unit)
	local power = UnitPower(unit)
	if power == 1 and timerNeedsUpdate then
		timerNeedsUpdate = nil
		self:Bar(147011, 89.2, self:SpellName(147011), 147011)
	elseif power == 50 and timerNeedsUpdate then
		timerNeedsUpdate = nil
		self:Bar(147011, 45.1, self:SpellName(147011), 147011)
	elseif power == 60 and timerNeedsUpdate then
		timerNeedsUpdate = nil
		self:Bar(147011, 35.8, self:SpellName(147011), 147011)
	elseif power == 70 and timerNeedsUpdate then
		timerNeedsUpdate = nil
		self:Bar(147011, 26.9, self:SpellName(147011), 147011)
	elseif power == 80 and timerNeedsUpdate then
		timerNeedsUpdate = nil
		self:Bar(147011, 18.1, self:SpellName(147011), 147011)
	elseif power == 90 and timerNeedsUpdate then
		timerNeedsUpdate = nil
		self:Bar(147011, 8.8, self:SpellName(147011), 147011)
	end
end

--"<689.0 00:37:16> [CHAT_MSG_MONSTER_YELL] CHAT_MSG_MONSTER_YELL#You think you have WON?  You are BLIND.  I WILL FORCE YOUR EYES OPEN.#Garrosh Hellscream#####0#0##0#2196#nil#0#false#false", -- [225151]
--"<708.4 00:37:35> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Enter Realm of Garrosh::0:146984]]", -- [230670]

--"<738.6 00:38:06> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B900018311#Garrosh Hellscream#68168#2##nil#-2147483648#-2147483648#147209#Malice#32", -- [233928]
--"<738.7 00:38:06> [CLEU] SPELL_AURA_APPLIED#false#0xF15118B900018311#Garrosh Hellscream#68168#2#0x038000000505AD5B#Smootie#1300#0#147209#Malice#32#DEBUFF", -- [233962]
--"<752.8 00:38:20> [CLEU] SPELL_AURA_REMOVED#false#0xF15118B900018311#Garrosh Hellscream#2632#2#0x038000000505AD5B#Smootie#1300#0#147209#Malice#32#DEBUFF", -- [237561]

--"<768.8 00:38:36> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B900018311#Garrosh Hellscream#68168#2##nil#-2147483648#-2147483648#147209#Malice#32", -- [241686]
--"<768.8 00:38:36> [CLEU] SPELL_AURA_APPLIED#false#0xF15118B900018311#Garrosh Hellscream#68168#2#0x0380000004946C82#Aladya#1300#0#147209#Malice#32#DEBUFF", -- [241735]
--"<782.9 00:38:50> [CLEU] SPELL_AURA_REMOVED#false#0xF15118B900018311#Garrosh Hellscream#68168#2#0x0380000004946C82#Aladya#1300#0#147209#Malice#32#DEBUFF", -- [244989]

--"<799.0 00:39:06> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B900018311#Garrosh Hellscream#68168#2##nil#-2147483648#-2147483648#147209#Malice#32", -- [248243]
--"<799.1 00:39:06> [CLEU] SPELL_AURA_APPLIED#false#0xF15118B900018311#Garrosh Hellscream#68168#2#0x0380000004946C82#Aladya#1300#0#147209#Malice#32#DEBUFF", -- [248283]
--"<813.1 00:39:20> [CLEU] SPELL_AURA_REMOVED#false#0xF15118B900018311#Garrosh Hellscream#68168#2#0x0380000004946C82#Aladya#1300#0#147209#Malice#32#DEBUFF", -- [251644]

--"<728.9 00:37:56> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Bombardment::0:147088]]", -- [231756]
--"<778.9 00:38:46> [UNIT_SPELLCAST_START] Garrosh Hellscream - achievement_dungeon_hordeairship - 2sec [[boss1:Call Bombardment::0:147120]]", -- [244119]
--"<778.9 00:38:46> [CLEU] SPELL_CAST_START#false#0xF15118B900018311#Garrosh Hellscream#68168#2##nil#-2147483648#-2147483648#147120#Call Bombardment#1", -- [244121]

-- phase 2

--"<575.9 23:43:06> [CLEU] SPELL_AURA_APPLIED#false#0xF15118B9000144F1#Garrosh Hellscream#68168#0#0x0380000004947837#Treckie#1300#64#145195#Empowered Gripping Despair#32#DEBUFF", -- [190658]
--"<579.6 23:43:09> [CLEU] SPELL_AURA_APPLIED_DOSE#false#0xF15118B9000144F1#Garrosh Hellscream#68168#0#0x0380000004947837#Treckie#1300#64#145195#Empowered Gripping Despair#32#DEBUFF#2", -- [191563]
--"<583.2 23:43:13> [CLEU] SPELL_AURA_APPLIED#false#0xF15118B9000144F1#Garrosh Hellscream#68168#0#0x0380000004945DDF#Sco#1300#0#145195#Empowered Gripping Despair#32#DEBUFF", -- [192484]
--"<586.8 23:43:17> [CLEU] SPELL_AURA_APPLIED_DOSE#false#0xF15118B9000144F1#Garrosh Hellscream#68120#0#0x0380000004945DDF#Sco#1352#0#145195#Empowered Gripping Despair#32#DEBUFF#2", -- [193617]
--"<589.9 23:43:20> [CLEU] SPELL_AURA_REMOVED#false#0xF15118B9000144F1#Garrosh Hellscream#68168#0#0x0380000004947837#Treckie#1300#64#145195#Empowered Gripping Despair#32#DEBUFF", -- [194807]
--"<589.9 23:43:20> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#64#0x0380000004947837#Treckie#1300#64#145213#Explosive Despair#32#DEBUFF", -- [194808]

--10s duration

function mod:GrippingDespair(args)
	local amount = args.amount or 1
	self:StackMessage(145183, args.destName, amount, "Attention", amount > 2 and not self:Me(args.destGUID) and "Warning")
	if args.spellId == 145195 then -- Empowered (Explosive Despair)
		self:StopBar(("[%d] %s: %s"):format((amount-1), self:SpellName(145213), args.destName))
		self:TargetBar(-8325, 10, args.destName, ("[%d] %s"):format(amount, self:SpellName(145213)), 145195)		
	end
end

--"<426.0 23:22:46> 92 Hostile (elite Elemental) - Minion of Y'Shaarj # 0xF1511A5000016A97 # 72272", -- [16]

do
	local function cancelMark()
		mod:CancelTimer(markTimerTwo)
		markTimerTwo = nil
	end

	local function markUp()
		for i=1, GetNumGroupMembers() do
			local unitId = "raid"..i.."target"
			local guid = UnitGUID(unitId)
			if markableMobs[guid] == true then
				for mark = 8, 1, -1 do
					if not marksUsed[mark] then
						SetRaidTarget(unitId, mark)
						markableMobs[guid] = "marked"
						marksUsed[mark] = guid
					end
				end
			end
		end
	end

	local function setMark(unit, guid)
		for mark = 8, 1, -1 do
			if not marksUsed[mark] then
				SetRaidTarget(unit, mark)
				markableMobs[guid] = "marked"
				marksUsed[mark] = guid
				return
			end
		end
	end

	local function markMobs()
		local continue
		for guid in next, markableMobs do
			if markableMobs[guid] == true then
				local unit = mod:GetUnitIdByGUID(guid)
				if unit then
					setMark(unit, guid)
				else
					continue = true
				end
			end
		end
		if not continue or not mod.db.profile.custom_off_addmarker then
			mod:CancelTimer(markTimer)
			markTimer = nil
		end
	end

	function mod:UPDATE_MOUSEOVER_UNIT()
		local guid = UnitGUID("mouseover")
		if guid and markableMobs[guid] == true then
			setMark("mouseover", guid)
		end
	end

	function mod:AddMarkedMob(args)
		if not markableMobs[args.destGUID] then
			markableMobs[args.destGUID] = true
			if self.db.profile.custom_off_addmarker and not markTimer then
				markTimer = self:ScheduleRepeatingTimer(markMobs, 0.1)
			end
			if self.db.profile.custom_off_addmarker and not markTimerTwo then
				markTimerTwo = self:ScheduleRepeatingTimer(markUp, 0.1)
			end
		end
	end
	
	function mod:WhirlingCorruption(args)
		wipe(markableMobs)
		wipe(marksUsed)
		self:Message(144985, "Important", "Long", args.spellName)
		self:Bar(144985, 50.7, args.spellName) --50.7 or 50.8
		self:Flash(144985)
		if self.db.profile.custom_off_addmarker then
			self:ScheduleTimer(cancelMark, 20)
		end
	end	
end

--"<221.8 18:07:09> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Jump To Ground::0:144956]]", -- [85295]
--"<237.4 18:07:25> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000EF51#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145065#Touch of Y'Shaarj#32", -- [89253]
--"<283.3 18:08:11> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000EF51#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145065#Touch of Y'Shaarj#32", -- [104642]
--"<329.2 18:08:57> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000EF51#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145065#Touch of Y'Shaarj#32", -- [118887]
--intermission, 15.6, 45.9, 45.9

--"<431.2 18:10:39> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Jump To Ground::0:144956]]", -- [154950]
--"<446.3 18:10:54> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000EF51#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145065#Touch of Y'Shaarj#32", -- [158924]
--"<492.2 18:11:40> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000EF51#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145065#Touch of Y'Shaarj#32", -- [172685]
--"<538.1 18:12:26> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000EF51#Garrosh Hellscream#2632#0##nil#-2147483648#-2147483648#145065#Touch of Y'Shaarj#32", -- [185866]
--intermission, 15.1, 45.9, 45.9

--"<556.2 18:12:44> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Realm of Y'Shaarj::0:145647]]", -- [190190]
--"<586.5 18:13:14> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000EF51#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145171#Empowered Touch of Y'Shaarj#32", -- [196962]
--"<621.5 18:13:49> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000EF51#Garrosh Hellscream#2632#0##nil#-2147483648#-2147483648#145171#Empowered Touch of Y'Shaarj#32", -- [207726]
--"<663.8 18:14:31> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000EF51#Garrosh Hellscream#2632#0##nil#-2147483648#-2147483648#145171#Empowered Touch of Y'Shaarj#32", -- [215216]
--phase3, 30.3, 35, 42.3

--*

--"<215.4 15:58:29> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Jump To Ground::0:144956]]", -- [83915]
--"<231.0 15:58:44> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000A2C5#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145065#Touch of Y'Shaarj#32", -- [88196]
--"<278.1 15:59:31> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000A2C5#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145065#Touch of Y'Shaarj#32", -- [104502]
--"<325.3 16:00:18> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000A2C5#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145065#Touch of Y'Shaarj#32", -- [118749]
--intermission, 15.6, 47.1, 47.2

--"<425.7 16:01:59> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Jump To Ground::0:144956]]", -- [151769]
--"<441.2 16:02:14> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000A2C5#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145171#Empowered Touch of Y'Shaarj#32", -- [155301]
--"<486.4 16:03:00> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000A2C5#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145171#Empowered Touch of Y'Shaarj#32", -- [167468]
--"<531.8 16:03:45> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000A2C5#Garrosh Hellscream#2632#0##nil#-2147483648#-2147483648#145171#Empowered Touch of Y'Shaarj#32", -- [179598]
--intermission, 15.5, 45.2, 45.4

--"<566.9 16:04:20> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Realm of Y'Shaarj::0:145647]]", -- [189189]
--"<597.1 16:04:50> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B90000A2C5#Garrosh Hellscream#2632#0##nil#-2147483648#-2147483648#145171#Empowered Touch of Y'Shaarj#32", -- [195555]
--phase3, 30.2

do
	function mod:MindControlRemoved(args)
		if self.db.profile.custom_off_mc_mark then
			SetRaidTarget(args.destName, 0)
		end
	end

	function mod:MindControlApplied(args)
		if self:Me(args.destGUID) then
			self:Message(145065, "Personal", "Info", CL["you"]:format(args.spellName))
			self:Flash(145065)
		end
		if self.db.profile.custom_off_mc_mark then
			SetRaidTarget(args.destName, iconCounter)
			iconCounter = iconCounter + 1
		end
	end

	function mod:MindControlSuccess(args)
		iconCounter = 1
		self:Message(145065, "Urgent", "Alert", CL["casting"]:format(L["mind_control"]))
		if phase == 3 then
			self:Bar(145065, (mcCounter == 1) and 35 or 42.3, L["mind_control"])
			mcCounter = mcCounter + 1
		else
			self:Bar(145065, 45.2, L["mind_control"])
		end
	end
end

-- Phase 1
function mod:NewWave()
	self:Message(-8292, "Attention", CL["count"]:format(EJ_GetSectionInfo(8292), waveCounter), nil, 144582) -- XXX the count message is only in for debugging
	waveCounter = waveCounter + 1
	self:Bar(-8292, waveTimers[waveCounter] or 40, nil, 144582)
	waveTimer = self:ScheduleTimer("NewWave", waveTimers[waveCounter] or 40)
end

--"<44.3 23:16:25> [CLEU] SPELL_CAST_START#false#0xF131192F00016400#Farseer Wolf Rider#2632#0##nil#-2147483648#-2147483648#144583#Ancestral Chain Heal#8", -- [24320]
--"<54.0 23:16:34> [CLEU] SPELL_CAST_START#false#0xF131192F00016400#Farseer Wolf Rider#2632#0##nil#-2147483648#-2147483648#144583#Ancestral Chain Heal#8", -- [28419]
--"<63.7 23:16:44> [CLEU] SPELL_CAST_START#false#0xF131192F00016400#Farseer Wolf Rider#2632#0##nil#-2147483648#-2147483648#144583#Ancestral Chain Heal#8", -- [33395]
--9.7

do
	local prev = 0
	function mod:ChainHeal(args)
		local t = GetTime()
		if t-prev > 3 and UnitGUID("focus") == args.sourceGUID then -- don't spam
			prev = t
			self:Message("chain_heal", "Personal", "Alert", L["chain_heal_message"], args.spellId)
			self:Bar("chain_heal", 9.7, L["chain_heal_bar"], args.spellId)
		end
	end
end


function mod:HellscreamsWarsong(args)
	self:Message(args.spellId, "Urgent", self:Tank() and "Long")
	self:Bar(args.spellId, 42)
end

do
	local farseerTimers = {50, 50, 40}
	--  cat Transcriptor.lua | sed "s/\t//g" | cut -d ' ' -f 2-300 | grep -E "(YELL].*Farseers)|(DED.*144489)|(DED.*144866)"
	function mod:Farseer()
		self:Message(-8294, "Urgent", self:Damager() and "Alert", nil, 144584)
		self:Bar(-8294, farseerTimers[farseerCounter] or 40, nil, 144584) -- chain lightning icon cuz that is some shaman spell
		farseerCounter = farseerCounter + 1
	end
end

--"<20.0 23:16:00> [CHAT_MSG_RAID_BOSS_EMOTE] CHAT_MSG_RAID_BOSS_EMOTE#|TInterface\\Icons\\ability_mage_firestarter.blp:20|t|cFFFF0000Siege Engineers|r appear in the wings and begin to cast |cFFFF0000|Hspell:144616|h[Power Iron Star]|h|r!#Garrosh Hellscream###Garrosh Hellscream##0#0##0#2543#nil#0#false#false", -- [12026]
--"<22.4 23:16:03> [UNIT_SPELLCAST_CHANNEL_START] Siege Engineer - Ability_Mage_FireStarter - 15sec [[boss2:Power Iron Star::0:144616]]", -- [14143]
--"<22.4 23:16:03> [CLEU] SPELL_CAST_SUCCESS#false#0xF1311930000163CD#Siege Engineer#2632#0##nil#-2147483648#-2147483648#144616#Power Iron Star#4", -- [14145]
--"<37.7 23:16:18> [CLEU] SPELL_AURA_REMOVED#false#0xF1311930000163CD#Siege Engineer#2632#0#0xF151193100016175#Ko'kron Iron Star#2632#0#144616#Power Iron Star#4#BUFF", -- [21874]
--"<37.9 23:16:18> [UNIT_SPELLCAST_CHANNEL_STOP] Siege Engineer [[boss2:Power Iron Star::0:144616]]", -- [21972]
--"<38.4 23:16:19> [CHAT_MSG_MONSTER_YELL] CHAT_MSG_MONSTER_YELL#Witness the power of the True Horde's arsenal!#Garrosh Hellscream###Ko'kron Iron Star##0#0##0#2549#nil#0#false#false", -- [22157]
--"<46.3 23:16:27> [CLEU] SPELL_CAST_SUCCESS#false#0xF151193100016175#Ko'kron Iron Star#2632#0##nil#-2147483648#-2147483648#144798#Exploding Iron Star#4", -- [25060]
--"<46.3 23:16:27> [CLEU] UNIT_DIED#true##nil#-2147483648#-2147483648#0xF151193100016175#Ko'kron Iron Star#2632#0#0", -- [25063]

--"<65.1 23:16:45> [CHAT_MSG_RAID_BOSS_EMOTE] CHAT_MSG_RAID_BOSS_EMOTE#|TInterface\\Icons\\ability_mage_firestarter.blp:20|t|cFFFF0000Siege Engineers|r appear in the wings and begin to cast |cFFFF0000|Hspell:144616|h[Power Iron Star]|h|r!#Garrosh Hellscream###Garrosh Hellscream##0#0##0#2556#nil#0#false#false", -- [34372]
--"<82.8 23:17:03> [UNIT_SPELLCAST_CHANNEL_STOP] Siege Engineer [[boss2:Power Iron Star::0:144616]]", -- [43648]
--"<91.2 23:17:11> [CLEU] UNIT_DIED#true##nil#-2147483648#-2147483648#0xF151193100016450#Ko'kron Iron Star#2632#0#0", -- [47852]
--26.1, 26.3

--"<20.2 22:51:53> [CHAT_MSG_RAID_BOSS_EMOTE] CHAT_MSG_RAID_BOSS_EMOTE#|TInterface\\Icons\\ability_mage_firestarter.blp:20|t|cFFFF0000Siege Engineers|r appear in the wings and begin to cast |cFFFF0000|Hspell:144616|h[Power Iron Star]|h|r!#Garrosh Hellscream###Garrosh Hellscream##0#0##0#2252#nil#0#false#false", -- [11050]
--"<38.4 22:52:11> [CHAT_MSG_MONSTER_YELL] CHAT_MSG_MONSTER_YELL#We will cleanse this world in steel and fire!#Garrosh Hellscream###Ko'kron Iron Star##0#0##0#2255#nil#0#false#false", -- [21420]
--"<46.3 22:52:19> [CLEU] SPELL_CAST_SUCCESS#false#0xF151193100013DCC#Ko'kron Iron Star#2632#0##nil#-2147483648#-2147483648#144798#Exploding Iron Star#4", -- [24224]

--"<65.0 22:52:38> [CHAT_MSG_RAID_BOSS_EMOTE] CHAT_MSG_RAID_BOSS_EMOTE#|TInterface\\Icons\\ability_mage_firestarter.blp:20|t|cFFFF0000Siege Engineers|r appear in the wings and begin to cast |cFFFF0000|Hspell:144616|h[Power Iron Star]|h|r!#Garrosh Hellscream###Garrosh Hellscream##0#0##0#2258#nil#0#false#false", -- [33542]
--"<83.3 22:52:56> [CHAT_MSG_MONSTER_YELL] CHAT_MSG_MONSTER_YELL#Witness the power of the True Horde's arsenal!#Garrosh Hellscream###Ko'kron Iron Star##0#0##0#2261#nil#0#false#false", -- [44810]
--"<91.9 22:53:05> [CLEU] SPELL_CAST_SUCCESS#false#0xF1511931000148E6#Ko'kron Iron Star#2632#0##nil#-2147483648#-2147483648#144798#Exploding Iron Star#4", -- [48884]

--144798 icon for explosion
--"ability_garrosh_siege_engine" good ironstar moving icon

--"<20.0 00:28:26> [CHAT_MSG_RAID_BOSS_EMOTE] CHAT_MSG_RAID_BOSS_EMOTE#|TInterface\\Icons\\ability_mage_firestarter.blp:20|t|cFFFF0000Siege Engineers|r appear in the wings and begin to cast |cFFFF0000|Hspell:144616|h[Power Iron Star]|h|r!#Garrosh Hellscream###Garrosh Hellscream##0#0##0#730#nil#0#false#false", -- [8971]
--"<33.6 00:28:39> [CHAT_MSG_MONSTER_YELL] CHAT_MSG_MONSTER_YELL#We will cleanse this world in steel and fire!#Garrosh Hellscream###Ko'kron Iron Star##0#0##0#735#nil#0#false#false", -- [17866]
--"<42.5 00:28:48> [CLEU] SPELL_CAST_SUCCESS#false#0xF15119310001F13F#Ko'kron Iron Star#2632#0##nil#-2147483648#-2147483648#144798#Exploding Iron Star#4", -- [22654]

function mod:IronStar()
	self:Message("ironstar", "Important", "Info", L["ironstar"], L.ironstar_icon)
	self:CDBar("ironstar", 8.2, L["ironstar_impact"], 144798)
end

function mod:SiegeEngineer()
	self:Message(-8298, "Attention", self:Damager() and "Long", EJ_GetSectionInfo(8298), 144616)
	self:Bar(-8298, engineerCounter == 1 and 45 or 40, EJ_GetSectionInfo(8298), 144616)
	engineerCounter = engineerCounter + 1
	-- Iron star stuff
	if self:Heroic() then
		self:Bar("ironstar", 13.4, L["ironstar"], L.ironstar_icon)
	else
		self:Bar("ironstar", 18.2, L["ironstar"], L.ironstar_icon)
	end
end

-- Intermission
function mod:Annihilate(args)
	self:Message(args.spellId, "Attention", nil, CL["casting"]:format(CL["count"]:format(args.spellName, annihilateCounter)))
	annihilateCounter = annihilateCounter + 1
end

function mod:InsideReduction(args)
	if self:Me(args.destGUID) then
		self:Message(144945, "Neutral", "Info", L["yougotyour"]:format(args.spellName))
		self:Flash(144945)
	end
end

do
	local hopeList = mod:NewTargetList()
	local function warnHopelist(spellId)
		local diff = mod:Difficulty()
		for i=1, GetNumGroupMembers() do
			local name, _, subgroup, _, _, _, _, online, isDead = GetRaidRosterInfo(i)
			-- 149004 hope
			-- 148983 courage
			-- 148994 faith
			local debuffed = UnitDebuff(name, mod:SpellName(149004)) or UnitDebuff(name, mod:SpellName(148983)) or UnitDebuff(name, mod:SpellName(148994))
			if not debuffed and online and not isDead then
				if diff == 3 or diff == 5 then -- 10 man
					if subgroup < 3 then
						hopeList[#hopeList+1] = name
					end
				else
					if subgroup < 6 then
						hopeList[#hopeList+1] = name
					end
				end
			end
		end
		if #hopeList > 0 then
			mod:TargetMessage(spellId, hopeList, "Attention", "Warning", ("[%d] %s"):format(#hopeList, mod:SpellName(29125)), 149004) -- maybe add it's own option key? 29125 spell called "Hopeless"
		end	
	end
	function mod:YShaarjsProtection(args)
		if self:MobId(args.destGUID) ~= 71865 then return end
		wipe(hopeList)
		annihilateCounter = 1
		self:Message(args.spellId, "Positive", "Long", CL["over"]:format(args.spellName))
		self:ScheduleTimer(warnHopelist, 4, args.spellId)
	end
end

--"<449.3 23:23:10> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Realm of Y'Shaarj::0:145647]]", -- [167122]

--"<469.8 23:23:30> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B9000161DA#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#144749#Empowered Desecrate#32", -- [172370]
--"<506.0 23:24:06> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B9000161DA#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#144749#Empowered Desecrate#32", -- [182067]
--"<531.5 23:24:32> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B9000161DA#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#144749#Empowered Desecrate#32", -- [188167]

--"<483.1 23:23:43> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B9000161DA#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145171#Empowered Touch of Y'Shaarj#32", -- [175663]
--"<518.1 23:24:18> [CLEU] SPELL_CAST_SUCCESS#false#0xF15118B9000161DA#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145171#Empowered Touch of Y'Shaarj#32", -- [184921]

--"<495.1 23:23:55> [CLEU] SPELL_CAST_START#false#0xF15118B9000161DA#Garrosh Hellscream#68168#0##nil#-2147483648#-2147483648#145037#Empowered Whirling Corruption#32", -- [178745]
--"<546.0 23:24:46> [CLEU] SPELL_CAST_START#false#0xF15118B9000161DA#Garrosh Hellscream#68120#0##nil#-2147483648#-2147483648#145037#Empowered Whirling Corruption#32", -- [190847]

--"<158.5 22:48:47> [BigWigs_StartBar] BigWigs_StartBar#BigWigs_Bosses_Garrosh Hellscream#-8305#Intermission#210#Interface\\Icons\\SPELL_HOLY_PRAYEROFSHADOWPROTECTION", -- [66684]
--"<222.9 22:49:51> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Jump To Ground::0:144956]]", -- [87113]
--"<368.8 22:52:17> [BigWigs_StartBar] BigWigs_StartBar#BigWigs_Bosses_Garrosh Hellscream#-8305#Intermission#210#Interface\\Icons\\SPELL_HOLY_PRAYEROFSHADOWPROTECTION", -- [131698]
--"<432.8 22:53:21> [UNIT_SPELLCAST_SUCCEEDED] Garrosh Hellscream [[boss1:Jump To Ground::0:144956]]", -- [153066]
--"<578.5 22:55:47> [BigWigs_StartBar] BigWigs_StartBar#BigWigs_Bosses_Garrosh Hellscream#-8305#Intermission#210#Interface\\Icons\\SPELL_HOLY_PRAYEROFSHADOWPROTECTION", -- [189224]

function mod:UNIT_SPELLCAST_SUCCEEDED(unitId, spellName, _, _, spellId)
	if spellId == 145235 then -- throw axe at heart , transition into first intermission
		if phase ~= 3 then -- this fires once right after phase 3 starts
			self:Bar(-8305, 25, L["intermission"], "SPELL_HOLY_PRAYEROFSHADOWPROTECTION")
			phase = 2
			self:CancelTimer(waveTimer)
			waveTimer = nil
			self:Message("stages", "Neutral", nil, CL["phase"]:format(phase), false)
			self:StopBar(-8292) -- Kor'kron Warbringer aka add waves
			self:StopBar(-8298) -- Siege Engineer
			self:StopBar(-8294) -- Farseer
			self:StopBar(144821) -- Hellscream's Warsong
			self:StopBar(144758) -- Desecrated Weapon
		end
	elseif spellId == 144866 then -- Enter Realm of Y'Shaarj -- actually being pulled
		firstRealmEntered = true
		self:StopBar(144758) -- Desecrated Weapon
		self:StopBar(L["mind_control"]) -- Mind Control
		self:StopBar(144985) -- Whirling Corruption
		self:Message(-8305, "Neutral", nil, L["intermission"], "SPELL_HOLY_PRAYEROFSHADOWPROTECTION")
		self:Bar(144954, 63, self:SpellName(144954), 144954) -- Realm of Y'Shaarj
	elseif spellId == 144956 then -- Jump To Ground -- exiting intermission
		if firstRealmEntered then
			desecrateCounter = 1
			self:Bar(144758, 10.3) -- Desecrated Weapon
			self:Bar(145065, 15, L["mind_control"]) -- Mind Control
			self:Bar(144985, 30) -- Whirling Corruption
			self:Bar(-8305, 145.7, L["intermission"], "SPELL_HOLY_PRAYEROFSHADOWPROTECTION")
		end
	elseif spellId == 145647 then -- Realm of Y'Shaarj -- phase 3
		phase = 3
		mcCounter = 1
		desecrateCounter = 1
		self:Message("stages", "Neutral", nil, CL["phase"]:format(phase), false)
		self:StopBar(L["intermission"])
		self:StopBar(144985) -- stop Whirling Corruption bar in case it was not empowered already
		self:Bar(144985, 45.8, 145037) -- Empowered Whirling Corruption
		self:Bar(145065, 30.2, L["mind_control"]) -- Empowered Mind Control
		self:Bar(144758, 20.5) -- Empowered Desecrated Weapon
	elseif spellId == 146984 then -- Realm of Garrosh -- phase 4
		phase = 4
		self:Message("stages", "Neutral", nil, CL["phase"]:format(phase), false)
		self:Bar(147209, 30.2) -- Malice
		self:Bar("bombardment", 69.3, self:SpellName(147088), L.bombardment_icon) -- Call Bombardment
		self:RegisterUnitEvent("UNIT_POWER_FREQUENT", nil, "boss1")
	end
end

-- General
do
	local timer, fired = nil, 0
	local phase2DesecreteCDs = {36, 45, 36}	
	local UnitDetailedThreatSituation, UnitExists, UnitIsUnit, UnitIsPlayer = UnitDetailedThreatSituation, UnitExists, UnitIsUnit, UnitIsPlayer
	local function weaponWarn()
		fired = fired + 1
		local boss = getBossByMobId(71865)
		if not boss then return end
		local target = boss.."target"
		if UnitExists(target) and UnitIsPlayer(target) and not mod:Tank(target) and not UnitDetailedThreatSituation(target, boss) then
			local name = mod:UnitName(target)
			if UnitIsUnit("player", target) then
				mod:TargetMessage(144758, name, "Urgent", "Alarm")
				mod:Flash(144758)
				mod:Say(144758)
			elseif mod:Range(name) < 15 then
				mod:Flash(144758)
				mod:RangeMessage(144758, "Urgent", "Alarm")
			else
				mod:TargetMessage(144758, name, "Urgent", "Alarm")
			end
			mod:CancelTimer(timer)
			timer = nil
		end
		-- 19 == 0.95sec
		-- Safety check if the unit doesn't exist
		if fired > 18 then
			mod:CancelTimer(timer)
			timer = nil
		end
	end
	function mod:DesecratedWeapon(args)
		if phase == 2 then
			local diff = self:Difficulty()
			if diff == 3 or diff == 5 then -- 10 man
				desecrateCD = phase2DesecreteCDs[desecrateCounter] or 45
			else
				desecrateCD = 35 --35 or 35.1
			end
		elseif phase == 3 then
			local diff = self:Difficulty()
			if diff == 3 or diff == 5 then -- 10 man
				desecrateCD = (desecrateCounter == 1) and 30 or 25
			else
				desecrateCD = (desecrateCounter == 1) and 35 or 25
			end
		end
		self:Bar(144758, desecrateCD)
		desecrateCounter = desecrateCounter + 1
		fired = 0
		if not timer then
			timer = self:ScheduleRepeatingTimer(weaponWarn, 0.05)
		end
	end
end

--"<265.5 15:59:19> [CLEU] SPELL_PERIODIC_MISSED#false#0xF13119DA0000AAE0#Desecrated Weapon#2632#0#0x038000000493F030#Pacteh#1300#0#144762#Desecrated#32#ABSORB#nil#202508", -- [100895]
--"<311.5 16:00:05> [CLEU] SPELL_PERIODIC_DAMAGE#false#0xF13119DA0000AB5A#Desecrated Weapon#2632#0#0x038000000494792D#Rogerbrown#1298#8#144762#Desecrated#32#182427#-1#32#nil#nil#nil#nil#nil#nil#nil", -- [114558]
--"<587.2 18:13:15> [CLEU] SPELL_PERIODIC_DAMAGE#false#0xF1311A060000F45F#Empowered Desecrated Weapon#2584#0#0x0380000004946ED6#Owld#1352#0#144817#Desecrated#32#192560#-1#32#nil#nil#3553#nil#nil#nil#nil", -- [197274]

do
	local prev = 0
	function mod:DesecrateDamage(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(144758, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(144758)
		end
	end
end

--"<67.1 23:16:47> [CLEU] UNIT_DIED#true##nil#-2147483648#-2147483648#0xF131192F00016400#Farseer Wolf Rider#2632#0#0", -- [35636]

function mod:Deaths(args)
	if args.mobId == 71865 then
		self:Win()
	elseif args.mobId == 71983 then
		self:StopBar(L["chain_heal_bar"])
	end
end

--[[local function a()
	BigWigs.bossCore:EnableModule("Garrosh Hellscream")
	print("Enabled: Garrosh Hellscream (Debug)")
end

BigWigs:ScheduleTimer(a, 2)]]