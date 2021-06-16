--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Ra-den", 930, 831)
if not mod then return end
mod:RegisterEnableMob(69473) -- Ra-den

--------------------------------------------------------------------------------
-- Locals
--

local firstadd = 0
local materialCounter = 1
local animaWarned = nil
local infusion = 10
local killOrder25hc = {
	"|cFFFFA901KILL|r", -- 1
	"|cFFFFA901KILL|r", -- 2
	"|cFFFFA901KILL|r", -- 3
	"|cFF01FFFFABSORB|r", -- 4
	"|cFFFFA901KILL|r", -- 5
	"|cFFFFA901KILL|r", -- 6
	"|cFF01FFFFABSORB|r", -- 7
	"|cFFFFA901KILL|r", -- 8
	"|cFFFFA901KILL|r", -- 9
	"|cFFFFA901KILL|r" -- 10
}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.strikes = "Strikes"
	L.strikes_desc = "Warnings related to Fatal and Murderous Strikes."
	L.strikes_icon = "spell_deathknight_darkconviction"

	L.imbued = "Imbued"
	L.imbued_desc = "Messages related to Imbued With."
	L.imbued_icon = "spell_shadow_felmending"

	L.call_essence = "Call Essence"
	L.call_essence_desc = "Messages related to the Orbs in phase 2."
	L.call_essence_icon = "spell_nature_elementalprecision_1"

	L.crackling_stalker = "Crackling Stalker"
	--L.sanguine_horror = "Sanguine Horror"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{138308, "FLASH", "SAY"}, 138339,
		{138288, "FLASH", "SAY"}, --[[138338,]] --{138336, "FLASH"},
		138321, {"strikes", "TANK_HEALER"}, "imbued", 139073, "call_essence", "bosskill",
	}, {
		[138308] = "Vita",
		[138288] = "Anima",
		[138321] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	--Vita
	self:Log("SPELL_AURA_APPLIED", "UnstableVitaApplied", 138308, 138297) --138370=thedamage, 138308=fromplayertoplayer, 138297=fromradentoplayer
	self:Log("SPELL_AURA_REMOVED", "UnstableVitaRemoved", 138308, 138297)
	self:Log("SPELL_CAST_START", "CracklingStalker", 138339)		
	--Anima
	self:Log("SPELL_AURA_APPLIED", "UnstableAnimaApplied", 138288) --138288=the debuff the boss puts on you
	self:Log("SPELL_AURA_REMOVED", "UnstableAnimaRemoved", 138288)	
	self:Log("SPELL_AURA_APPLIED", "UnstableAnimaAppliedPlayer", 138295) --138295=damage dot afflicted players puts on other players
	self:Log("SPELL_AURA_REMOVED", "MurderousStrikeRemoved", 138333)
	--self:Log("SPELL_CAST_START", "SanguineHorror", 138338)
	--self:Log("SPELL_DAMAGE", "BubblingAnima", 138336)
	--General
	self:Log("SPELL_AURA_APPLIED", "Infusion", 138331, 138332) --Anima, Vita
	self:Log("SPELL_CAST_START", "MaterialsofCreation", 138321)
	self:Log("SPELL_CAST_SUCCESS", "Strikes", 138334, 138333) -- Fatal Strike, Murderous Strike
	self:Log("SPELL_AURA_APPLIED", "Ruin", 139073)

	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "CallEssence", "boss1")

	self:Death("Win", 69473)
end

--can stack on adds as well
--"<151.5 01:20:19> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F610000F322#Ra-den#68168#2#0xF1310F610000F322#Ra-den#68168#2#138450#Lingering Energies#32#BUFF", -- [9159]
--"<184.2 01:20:51> [CLEU] SPELL_AURA_APPLIED_DOSE#false#0xF1310F610000F322#Ra-den#2632#2#0xF1310F610000F322#Ra-den#2632#2#138450#Lingering Energies#32#BUFF#2", -- [23503]

--vita
--138324 = Summon Essence of Vita (has death event) id=69870
--138339 = Summon Crackling Stalker (has death event) id=69872
--anima
--138323 = Summon Essence of Anima (has death event)
--138338 = Summon Sanguine Horror (has death event) id=69871

--Sanguine Horror respawns from their death pool unless you kill a crackling stalker on top if it to neutralize it, no cleu event
--"<56.1 22:00:42> [CLEU] SPELL_CAST_SUCCESS#false#0xF13110F00000C06E#Crackling Stalker#2632#0##nil#-2147483648#-2147483648#138337#Cauterizing Flare#8", -- [25183]
--"<56.4 22:00:42> [CLEU] SPELL_DAMAGE#false#0xF13110F00000C06E#Crackling Stalker#2632#0#0x0380000004946C82#Aladya#1300#0#138337#Cauterizing Flare#8#144303#-1#8#nil#nil#112018#nil#nil#nil#nil", -- [25357]

--spell_cast_start
--[21:13:19.218] Ra-den begins to cast Ruin Bolt

--"<354.8 21:58:46> 92 Hostile (Not specified) - Corrupted Anima # 0xF131114500011596 # 69957", -- [14]
--when this dies ppl need to be within 10y of it to soak.

--"<368.7 21:59:00> 92 Hostile (Not specified) - Corrupted Vita # 0xF1311146000115E3 # 69958", -- [16]

function mod:OnEngage()
	--self:Bar(138321, 10.1) -- Materials of Creation
	materialCounter = 1
	animaWarned = nil
	infusion = 10
	firstadd = 0
	self:Bar(138321, 10.1, ("[%d] %s (%s)"):format(materialCounter, self:SpellName(138321), (killOrder25hc[materialCounter] or "-"))) -- Materials of Creation	
end

--------------------------------------------------------------------------------
-- Event Handlers
--

--"<302.9 23:29:54> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F6100017060#Ra-den#2632#1#0xF1310F6100017060#Ra-den#2632#1#139073#Ruin#1#BUFF", -- [92571]
--"<318.7 23:30:09> [UNIT_SPELLCAST_SUCCEEDED] Ra-den [[boss1:Call Essence::0:139040]]", -- [98958]

function mod:Ruin(args)
	self:StopBar(138334) -- Fatal Strike
	self:StopBar(138333) -- Murderous Strike
	self:StopBar(L["crackling_stalker"])
	--self:StopBar(L["sanguine_horror"])
	--self:StopBar(("[%d] %s"):format(materialCounter, self:SpellName(138321))) --won't work now with the KILL/ABSORB
	self:StopBar(("[%d] %s (%s)"):format(materialCounter, self:SpellName(138321), "|cFFFFA901KILL|r"))
	self:Message(args.spellId, "Positive", "Long", CL["phase"]:format(2))
	materialCounter = 1	
	self:Bar("call_essence", 15.4, ("[%d] %s"):format(materialCounter, self:SpellName(139040)), 138321) -- Call Essence
end

--"<318.7 23:30:09> [UNIT_SPELLCAST_SUCCEEDED] Ra-den [[boss1:Call Essence::0:139040]]", -- [98958]
--"<334.9 23:30:26> [UNIT_SPELLCAST_SUCCEEDED] Ra-den [[boss1:Call Essence::0:139040]]", -- [105380]
--"<350.6 23:30:41> [UNIT_SPELLCAST_SUCCEEDED] Ra-den [[boss1:Call Essence::0:139040]]", -- [114615]

function mod:CallEssence(_, spellName, _, _, spellId)
	if spellId == 139040 then -- Call Essence
		self:Message("call_essence", "Important", "Warning", ("[%d] %s"):format(materialCounter, spellName), 138321)
		materialCounter = materialCounter + 1
		self:Bar("call_essence", 15.7, ("[%d] %s"):format(materialCounter, spellName), 138321)
	end
end	

--"<171.1 21:54:24> [CLEU] SPELL_MISSED#true##nil#2632#0#0xF140CA3DA40003DC#Skurikshok#4372#0#138336#Bubbling Anima#32#ABSORB#nil#975", -- [70079]

--[[do
	local prev = 0
	function mod:BubblingAnima(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(args.spellId)
		end
	end
end]]

--"<20.5 00:03:52> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F610000F8C8#Ra-den#68168#1#0xF1310F610000F8C8#Ra-den#68168#1#138332#Imbued with Vita#32#BUFF", -- [10004]
--"<29.2 00:04:01> [CLEU] SPELL_CAST_START#false#0xF1310F610000F8C8#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [14970]
--"<70.5 00:04:42> [CLEU] SPELL_CAST_START#false#0xF1310F610000F8C8#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [33171]
--"<90.8 00:05:02> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F610000F8C8#Ra-den#68168#1#0xF1310F610000F8C8#Ra-den#68168#1#138331#Imbued with Anima#32#BUFF", -- [43315]
--"<99.5 00:05:11> [CLEU] SPELL_CAST_START#false#0xF1310F610000F8C8#Ra-den#68168#1##nil#-2147483648#-2147483648#138338#Summon Sanguine Horror#1", -- [47484]
--"<122.2 00:05:34> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F610000F8C8#Ra-den#68168#1#0xF1310F610000F8C8#Ra-den#68168#1#138332#Imbued with Vita#32#BUFF", -- [60140]
--"<122.5 00:05:34> [CLEU] SPELL_CAST_START#false#0xF1310F610000F8C8#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [60253]
--"<122.8 00:05:34> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F610000F8C8#Ra-den#68168#1#0xF1310F610000F8C8#Ra-den#68168#1#138331#Imbued with Anima#32#BUFF", -- [60697]

local function restartStrike()
	local power, powerMax = UnitPower("boss1"), UnitPowerMax("boss1")
	local duration
	if power >= 0 then -- Compensates for the fact that the boss sometimes starts with -100 energy
		duration = ceil((powerMax-power)/infusion)+0.5
	else
		duration = ceil(powerMax/infusion)+0.5
	end
	if infusion > 3 then
		mod:CDBar("strikes", duration, 138334, 138334) -- Fatal Strike
	else
		mod:CDBar("strikes", duration, 138333, 138333) -- Murderous Strike
	end
end

--is it maybe him casting unstable vita/anima that restarts the add spawntimers? and if you swap fast enough they don't happen.
--"<20.6 23:25:11> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F6100017060#Ra-den#68168#1#0x038000000504A2A4#Viklund#1300#0#138297#Unstable Vita#8#DEBUFF", -- [9023]
--"<28.4 23:25:19> [CLEU] SPELL_CAST_START#false#0xF1310F6100017060#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [13289]
--"<69.7 23:26:00> [CLEU] SPELL_CAST_START#false#0xF1310F6100017060#Ra-den#68168#0##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [26871]
--"<111.8 23:26:42> [CLEU] SPELL_CAST_START#false#0xF1310F6100017060#Ra-den#2632#0##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [39269]
--"<120.8 23:26:51> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F6100017060#Ra-den#2632#0#0xF1310F6100017060#Ra-den#2632#0#138331#Imbued with Anima#32#BUFF", -- [41362]
--"<121.2 23:26:52> [CLEU] SPELL_AURA_REMOVED#false#0xF1310F6100017060#Ra-den#2632#0#0xF1310F6100017060#Ra-den#2632#0#138331#Imbued with Anima#32#BUFF", -- [41504]
--"<121.6 23:26:52> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F6100017060#Ra-den#2632#0#0x0380000004941D2F#Faerko#1300#0#138297#Unstable Vita#8#DEBUFF", -- [41763]
--"<153.3 23:27:24> [CLEU] SPELL_CAST_START#false#0xF1310F6100017060#Ra-den#2632#0##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [50856]
--"<194.7 23:28:05> [CLEU] SPELL_CAST_START#false#0xF1310F6100017060#Ra-den#2632#0##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [62373]
--"<218.3 23:28:29> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F6100017060#Ra-den#2632#0#0xF1310F6100017060#Ra-den#2632#0#138331#Imbued with Anima#32#BUFF", -- [70050]
--"<219.1 23:28:30> [CLEU] SPELL_AURA_REMOVED#false#0xF1310F6100017060#Ra-den#2632#0#0xF1310F6100017060#Ra-den#2632#0#138331#Imbued with Anima#32#BUFF", -- [70276]
--"<219.4 23:28:30> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F6100017060#Ra-den#2632#0#0x0380000004946C82#Aladya#1300#0#138297#Unstable Vita#8#DEBUFF", -- [70454]
--"<236.3 23:28:47> [CLEU] SPELL_CAST_START#false#0xF1310F6100017060#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [74992]
--"<277.5 23:29:28> [CLEU] SPELL_CAST_START#false#0xF1310F6100017060#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [85830]
--41.3, 42.1, 41.5, 41.4, 41.6, 41.2
--7.8

function mod:Infusion(args)
	if not args.destGUID == UnitGUID("boss1") then return end
	self:Message("imbued", "Neutral", nil, args.spellName, args.spellId)
	--self:StopBar(L["crackling_stalker"])
	--self:StopBar(L["sanguine_horror"])
	if args.spellId == 138331 then -- Anima
		infusion = 3
		animaWarned = nil
		self:StopBar(138334) -- Fatal Strike
		--self:Bar(138338, 8.2, L["sanguine_horror"])
	elseif args.spellId == 138332 then -- Vita
		infusion = 10
		self:StopBar(138333) -- Murderous Strike
		if firstadd == 0 then
			firstadd = firstadd+1
			self:Bar(138339, 9, L["crackling_stalker"])
		end
	end
	restartStrike()
end

--"<151.6 01:11:54> [CLEU] SPELL_CAST_START#false#0xF1310F610000F2D2#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [12737]
--"<152.6 01:11:55> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310F610000F2D2#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [12877]
--"<152.6 01:11:55> [CLEU] SPELL_SUMMON#false#0xF1310F610000F2D2#Ra-den#68168#1#0xF13110F00000F31D#Crackling Stalker#2600#0#138339#Summon Crackling Stalker#1", -- [12878]

--"<29.8 22:40:14> [CLEU] SPELL_CAST_START#false#0xF1310F6100008F9C#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [14662]
--"<71.0 22:40:55> [CLEU] SPELL_CAST_START#false#0xF1310F6100008F9C#Ra-den#68168#1##nil#-2147483648#-2147483648#138339#Summon Crackling Stalker#1", -- [31761]

function mod:CracklingStalker(args)
	self:Message(args.spellId, "Attention", nil, L["crackling_stalker"])
	self:Bar(args.spellId, 41.1, L["crackling_stalker"])
end

--"<160.7 01:20:28> [CLEU] SPELL_CAST_START#false#0xF1310F610000F322#Ra-den#68168#2##nil#-2147483648#-2147483648#138338#Summon Sanguine Horror#1", -- [12917]
--"<161.8 01:20:29> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310F610000F322#Ra-den#68168#2##nil#-2147483648#-2147483648#138338#Summon Sanguine Horror#1", -- [13405]
--"<161.8 01:20:29> [CLEU] SPELL_SUMMON#false#0xF1310F610000F322#Ra-den#68168#2#0xF13110EF0000F373#Sanguine Horror#2600#0#138338#Summon Sanguine Horror#1", -- [13406]

--[[function mod:SanguineHorror(args)
	self:Message(args.spellId, "Attention", self:Tank() and "Info", L["sanguine_horror"])
	self:Bar(args.spellId, 41.1, L["sanguine_horror"])
end]]

--"<89.0 23:08:03> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F610000E111#Ra-den#68168#1#0x03800000048BF754#Blattardos#1300#0#138288#Unstable Anima#32#DEBUFF", -- [41773]
--"<104.5 23:08:19> [CLEU] SPELL_DAMAGE#false#0x03800000048BF754#Blattardos#1300#0#0x0380000004BD6FA2#Apku#1298#0#138295#Unstable Anima#32#250000#-1#32#nil#nil#nil#nil#nil#nil#nil", -- [49323]
--"<104.5 23:08:19> [CLEU] SPELL_AURA_APPLIED#false#0x03800000048BF754#Blattardos#1300#0#0x0380000004BD6FA2#Apku#1298#0#138295#Unstable Anima#32#DEBUFF", -- [49324]

--"<91.1 00:05:03> [CLEU] SPELL_AURA_APPLIED#false#0xF1310F610000F8C8#Ra-den#68168#1#0x038000000493C2E8#Xabok#1300#0#138288#Unstable Anima#32#DEBUFF", -- [43491]
--"<106.5 00:05:18> [CLEU] SPELL_AURA_APPLIED#false#0x038000000493C2E8#Xabok#1300#2#0x0380000004BD6FA2#Apku#1298#0#138295#Unstable Anima#32#DEBUFF", -- [51600]
--"<121.4 00:05:33> [CLEU] SPELL_AURA_APPLIED#false#0x038000000493C2E8#Xabok#1300#2#0x03800000049476C8#V�l#1300#0#138295#Unstable Anima#32#DEBUFF", -- [59733]

do
	local function unstableAnimaMessage(remainingTime)
		mod:Say(138288, ("%d"):format(remainingTime), true)
	end

	function mod:UnstableAnimaAppliedPlayer(args)
		if not animaWarned then
			animaWarned = true
			self:TargetBar(138288, 14.5, args.sourceName)
			if self:Me(args.sourceGUID) then
				self:ScheduleTimer(unstableAnimaMessage, 9.5, 5)
				self:ScheduleTimer(unstableAnimaMessage, 10.5, 4)
				self:ScheduleTimer(unstableAnimaMessage, 11.5, 3)
				self:ScheduleTimer(unstableAnimaMessage, 12.5, 2)
				self:ScheduleTimer(unstableAnimaMessage, 13.5, 1)
			end
		end
	end

	function mod:UnstableAnimaApplied(args)
		self:TargetMessage(args.spellId, args.destName, "Urgent", "Alert")
		self:TargetBar(args.spellId, 15, args.destName)
		if self:Me(args.destGUID) then
			self:Flash(args.spellId)
			self:Say(args.spellId)
			self:ScheduleTimer(unstableAnimaMessage, 10, 5)
			self:ScheduleTimer(unstableAnimaMessage, 11, 4)
			self:ScheduleTimer(unstableAnimaMessage, 12, 3)
			self:ScheduleTimer(unstableAnimaMessage, 13, 2)
			self:ScheduleTimer(unstableAnimaMessage, 14, 1)
		end
		if GetRaidTargetIndex(args.destName) ~= 7 then
			SetRaidTarget(args.destName, 7)
		end
	end
end

--"<122.8 00:05:34> [CLEU] SPELL_AURA_REMOVED#false#0xF1310F610000F8C8#Ra-den#68168#1#0x038000000493C2E8#Xabok#1300#2#138288#Unstable Anima#32#DEBUFF", -- [60600]

function mod:UnstableAnimaRemoved(args)
	self:StopBar(CL["other"]:format(args.spellName, args.destName)) -- Incase you die or whatever
	if GetRaidTargetIndex(args.destName) then
		SetRaidTarget(args.destName, 0)
	end
	if self:Me(args.destGUID) then
		self:CancelAllTimers() -- If you get ressed you will still do the /say stuff, even if you lost the debuff
	end
end

function mod:UnstableVitaApplied(args)
	self:TargetMessage(138308, args.destName, "Urgent", "Alert")
	self:TargetBar(138308, 4.9, args.destName)
	if self:Me(args.destGUID) then
		self:Flash(138308)
		self:Say(138308)
	end	
	if GetRaidTargetIndex(args.destName) ~= 8 then
		SetRaidTarget(args.destName, 8)
	end
end

function mod:UnstableVitaRemoved(args)
	self:StopBar(CL["other"]:format(args.spellName, args.destName)) -- Incase you die or whatever
	if GetRaidTargetIndex(args.destName) then
		SetRaidTarget(args.destName, 0)
	end
end

--"<140.3 01:20:07> [CLEU] SPELL_CAST_START#false#0xF1310F610000F322#Ra-den#68168#2##nil#-2147483648#-2147483648#138321#Materials of Creation#1", -- [4811]

function mod:MaterialsofCreation(args)
	--self:Message(args.spellId, "Important", "Warning", ("[%d] %s"):format(materialCounter, args.spellName))	
	--materialCounter = materialCounter + 1
	--self:Bar(args.spellId, 32.1, ("[%d] %s"):format(materialCounter, args.spellName))
	self:Message(args.spellId, "Important", "Warning", ("[%d] %s (%s)"):format(materialCounter, args.spellName, (killOrder25hc[materialCounter] or "-")))
	materialCounter = materialCounter + 1
	self:Bar(args.spellId, 32.1, ("[%d] %s (%s)"):format(materialCounter, args.spellName, (killOrder25hc[materialCounter] or "-")))
end

--"<154.1 01:11:56> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310F610000F2D2#Ra-den#68168#1#0x0380000004945DDF#Sco#1298#0#138334#Fatal Strike#1", -- [13006]

--"<113.4 20:35:26> [CLEU] SPELL_DAMAGE#false#0xF1310F6100007637#Ra-den#68168#1#0x0380000004947837#Treckie#1300#0#138333#Murderous Strike#32#1045747#-1#32#nil#nil#512469#nil#nil#nil#nil", -- [51895]
--"<115.5 20:35:28> [CLEU] SPELL_PERIODIC_DAMAGE#false#0xF1310F6100007637#Ra-den#68168#1#0x0380000004947837#Treckie#1300#0#138333#Murderous Strike#32#463291#-1#32#nil#nil#190792#nil#nil#nil#nil", -- [52750]
--"<117.7 20:35:30> [CLEU] SPELL_PERIODIC_DAMAGE#false#0xF1310F6100007637#Ra-den#68168#1#0x0380000004947837#Treckie#1300#0#138333#Murderous Strike#32#1946966#177664#32#nil#nil#804#nil#nil#nil#nil", -- [53782]

do
	--local prefix = nil
	function mod:Strikes(args)
		if args.spellId == 138334 then -- Fatal Strike
			self:TargetMessage("strikes", args.destName, "Important", "Alarm", args.spellName, args.spellId)
			self:CDBar("strikes", 9.6, args.spellName, args.spellId)
		elseif args.spellId == 138333 then -- Murderous Strike		
			--[[local murderHPStart = UnitHealth(args.destName)
			if strlen(murderHPStart) >= 7 then
				murderHPStart = string.sub(murderHPStart, 1, -7)
				prefix = "M"
			elseif strlen(murderHPStart) >= 4 then
				murderHPStart = string.sub(murderHPStart, 1, -4)
				prefix = "K"
			end
			self:Message("strikes", "Important", "Alarm", ("%s: %s [%d%s]"):format(args.spellName, args.destName, murderHPStart, prefix), args.spellId)]]
			self:TargetMessage("strikes", args.destName, "Important", "Alarm", args.spellName, args.spellId)
			
			--local murderHPStart = floor(((UnitHealth(args.destName) / UnitHealthMax(args.destName)) * 100))
			--self:Message("strikes", "Important", "Alarm", ("%s: %s [%d%%]"):format(args.spellName, args.destName, murderHPStart))
			
			self:TargetBar("strikes", 10, args.destName, args.spellName, args.spellId)
			--self:Bar("strikes", 10, ("%s: %s [%dK]"):format(args.spellName, args.destName, murderHPStart), args.spellId)
		end
	end
end

--"<135.7 22:02:02> [CLEU] SPELL_AURA_REMOVED#false#0xF1310F610000BD6A#Ra-den#68168#1#0x0380000004947837#Treckie#1300#0#138333#Murderous Strike#32#DEBUFF", -- [52651]

function mod:MurderousStrikeRemoved(args)
	self:StopBar(CL["other"]:format(args.spellName, args.destName)) -- Incase the tank dies or whatever
end

