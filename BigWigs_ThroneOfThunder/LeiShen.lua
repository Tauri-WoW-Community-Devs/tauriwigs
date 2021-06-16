--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Lei Shen", 930, 832)
if not mod then return end
mod:RegisterEnableMob(68397, 68398, 68696, 68697, 68698) -- Lei Shen, Static Shock Conduit, Diffusion Chain Conduit, Overcharge Conduit, Bouncing Bolt Conduit

--------------------------------------------------------------------------------
-- Locals
--

local phase = 1
local function isConduitAlive(mobId)
	for i=1, 5 do
		local boss = ("boss%d"):format(i)
		if mobId == mod:MobId(UnitGUID(boss)) then
			return boss
		end
	end
	return false
end
local cprev = 0
local firstcast = 0
local firstcast2 = 0
local helmsdone = 0
local diffusiondone = 0
local overchargeddone = 0
local bouncingdone = 0
local staticdone = 0
local bossstring = "boss1"

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.conduit_abilities = "Conduit Abilities"
	L.conduit_abilities_desc = "Approximate cooldown bars for the conduit specific abilities."
	L.conduit_abilities_icon = 139271
	L.conduit_abilities_message = "Next Conduit Ability"

	L.intermission = "Intermission"
	L.ball_lightning = mod:SpellName(136620) -- Ball Lightning
	L.shock = "Shock"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{139011, "FLASH", "SAY"},
		{134912, "TANK", "FLASH"}, 135095, {135150, "FLASH"},
		{136478, "TANK"}, 136543, 136850, {136853, "FLASH"},
		{136914, "TANK"}, 136889,
		"stages", {135695, "FLASH", "SAY"}, 135991, {136295, "FLASH", "SAY"}, -7242, "conduit_abilities", 138070,
		"proximity", --[["berserk",]] "bosskill",
	}, {
		[139011] = "heroic",
		[134912] = -7178,
		[136478] = -7192,
		[136914] = -7209,
		["stages"] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")
	-- Stage 3
	self:Log("SPELL_AURA_APPLIED_DOSE", "ElectricalShock", 136914)
	-- Stage 2
	self:Log("SPELL_CAST_START", "LightningWhip", 136850)
	self:Log("SPELL_PERIODIC_DAMAGE", "LightningWhipDamage", 136853)
	self:Log("SPELL_CAST_SUCCESS", "SummonBallLightning", 136543)
	self:Log("SPELL_CAST_START", "FusionSlash", 136478)
	-- Intermission
	self:Emote("OverloadedCircuits", "137176")
	self:Log("SPELL_CAST_START", "Intermission", 137045)
	self:Log("SPELL_AURA_APPLIED", "HelmofCommand", 139011)
	-- Stage 1
	self:Log("SPELL_DAMAGE", "CrashingTimer", 135150)
	self:Log("SPELL_PERIODIC_DAMAGE", "CrashingThunder", 135153)
	self:Log("SPELL_CAST_START", "Thunderstruck", 135095)
	self:Log("SPELL_AURA_APPLIED", "Decapitate", 134912)
	-- Conduits
	self:Log("SPELL_CAST_SUCCESS", "DischargedEnergy", 134820) -- discharged energy cast start
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "Boss5Succeeded", "boss5", "boss4", "boss3", "boss2", "boss1")
	self:Log("SPELL_CAST_SUCCESS", "DiffusionChain", 135991)
	--self:Log("SPELL_DAMAGE", "DiffusionChainDamage", 135991) -- damage = add spawn
	self:Log("SPELL_AURA_APPLIED", "Overcharged", 136295)
	self:Log("SPELL_AURA_APPLIED", "StaticShockApplied", 135695)
	self:Log("SPELL_AURA_APPLIED", "Pillars", 135680, 135683, 135681, 135682) --static shock, bouncing bolt, diffusion chain, overcharge
	-- Misc
	self:Log("SPELL_AURA_APPLIED", "Amplifier", 138070)	
	
	self:Death("Deaths", 68397, 69133) -- Boss, Unharnessed Power
end

--"<0.0 20:42:27> [INSTANCE_ENCOUNTER_ENGAGE_UNIT] Fake Args:#1#1#Lei Shen#0xF1310B2D0000B2EC#elite#989856974#1#1#Diffusion Chain Conduit#0xF1510C580000B2E8#normal#843184#nil#nil#nil#nil#normal#0#nil#nil#nil#nil#normal#0#nil#nil#nil#nil#normal#0#Real Args:", -- [4]
--"<10.3 20:42:37> [UNIT_SPELLCAST_SUCCEEDED] Lei Shen [[boss1:Bouncing Bolt::0:136395]]", -- [3643]
--"<26.7 20:42:53> [UNIT_SPELLCAST_START] Lei Shen - ability_thunderking_thunderstruck - 4sec [[boss1:Thunderstruck::0:135095]]", -- [10594]
--"<40.8 20:43:07> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#68168#0#0x0380000004947837#Treckie#1300#0#134912#Decapitate#1#DEBUFF", -- [15514]
--"<92.8 20:43:59> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#68168#0#0x0380000004937A7F#Justtwo#1300#0#134912#Decapitate#1#DEBUFF", -- [28765]

function mod:OnEngage()
	--[[if self:Heroic() then
		self:Berserk(720)
	elseif self:LFR() then
		self:Berserk(900)
	end]]-- there is no berserk...
	self:Bar(135150, 6) -- Crashing Thunder
	self:CDBar(134912, 40) -- Decapitate
	self:Bar(135095, 25) -- Thunderstruck
	--self:CDBar("conduit_abilities", 14, L["conduit_abilities_message"], L.conduit_abilities_icon) -- need to rework this once I'm 100% sure how the abilities work, for now assume, they share CD
	phase = 1
	cprev = 0
	firstcast = 0
	firstcast2 = 0
	helmsdone = 0
	diffusiondone = 0
	overchargeddone = 0
	bouncingdone = 0
	staticdone = 0
	bossstring = "boss1"
	local diff = self:Difficulty()
	print(diff)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

--"<185.0 20:45:32> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0xF1310B2D0000B2EC#Lei Shen#2632#0#135680#Static Shock#1#BUFF", -- [42556] -- [XKPSEC]
--"<0.6 20:42:27> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#68168#0#0xF1310B2D0000B2EC#Lei Shen#68168#0#135683#Bouncing Bolt#1#BUFF", -- [132]
--"<90.3 20:43:57> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#68168#0#0xF1310B2D0000B2EC#Lei Shen#68168#0#135681#Diffusion Chain#1#BUFF", -- [28226]
--"<362.4 20:48:29> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0xF1310B2D0000B2EC#Lei Shen#2632#0#135682#Overcharge#1#BUFF", -- [97337]

function mod:DischargedEnergy(args)

	if self:Heroic() then
		if phase == 2 then
			if isConduitAlive(68696) then -- diffusion chain
				self:CloseProximity("proximity") -- close proximity on hc when moving if diffusion chain is alive
			end
			if not isConduitAlive(68696) then -- diffusion chain
				self:StopBar(135695) -- Static Shock
				self:StopBar(136395) -- Bouncing Bolt
				self:StopBar(136295) -- Overcharged
			end
			if not isConduitAlive(68697) then -- Overcharged
				self:StopBar(135991) -- Diffusion Chain
				self:StopBar(135695) -- Static Shock
				self:StopBar(136395) -- Bouncing Bolt
			end
			if not isConduitAlive(68698) then -- Bouncing Bolt
				self:StopBar(135991) -- Diffusion Chain
				self:StopBar(135695) -- Static Shock
				self:StopBar(136295) -- Overcharged
			end
			if not isConduitAlive(68398) then -- Static Shock
				self:StopBar(135991) -- Diffusion Chain
				self:StopBar(136395) -- Bouncing Bolt
				self:StopBar(136295) -- Overcharged
			end
		else
			self:CloseProximity("proximity")
			self:StopBar(135991) -- Diffusion Chain
			self:StopBar(135695) -- Static Shock
			self:StopBar(136395) -- Bouncing Bolt
			self:StopBar(136295) -- Overcharged
		end

	else
		self:CloseProximity("proximity")
		self:StopBar(135991) -- Diffusion Chain
		self:StopBar(135695) -- Static Shock
		self:StopBar(136395) -- Bouncing Bolt
		self:StopBar(136295) -- Overcharged
	end
end

do
	local prev = 0
	function mod:Pillars(args)
		--if not args.destGUID == UnitGUID("boss1") then return end
		local t = GetTime()
		if t-prev > 3 then
			prev = t
			self:Message("stages", "Neutral", nil, ("@%s"):format(args.spellName), args.spellId) -- notify of new pillar
			if phase == 1 then
				if args.spellId == 135681 then -- Diffusion Chain
					self:OpenProximity("proximity", 8)
					self:StopBar(135695) -- Static Shock
					self:StopBar(136395) -- Bouncing Bolt
					self:StopBar(136295) -- Overcharged
					if firstcast == 0 then
						firstcast = 1
						self:Bar(135991, 10) -- first cast when you move into hali pillar on boss pull
					end
				elseif args.spellId == 135683 then -- Bouncing Bolt
					self:StopBar(135695) -- Static Shock
					self:StopBar(135991) -- Diffusion Chain
					self:StopBar(136295) -- Overcharged
					if firstcast == 0 then
						firstcast = 1
						--self:Bar(136395, 14) -- first cast when you move into hali pillar on boss pull
						self:Bar(-7242, 10, 136395, "SPELL_SHAMAN_MEASUREDINSIGHT")
					end
				elseif args.spellId == 135680 then -- Static Shock
					self:StopBar(135991) -- Diffusion Chain
					self:StopBar(136395) -- Bouncing Bolt
					self:StopBar(136295) -- Overcharged		
					if firstcast == 0 then
						firstcast = 1
						self:Bar(135695, 10) -- first cast when you move into hali pillar on boss pull
					end
				elseif args.spellId == 135682 then -- Overcharge
					self:StopBar(135695) -- Static Shock
					self:StopBar(136395) -- Bouncing Bolt
					self:StopBar(135991) -- Diffusion Chain
					if firstcast == 0 then
						firstcast = 1
						self:Bar(136295, 10) -- first cast when you move into hali pillar on boss pull
					end
				end
			else
				firstcast2 = firstcast2 + 1
				if args.spellId == 135681 then -- Diffusion Chain
					self:OpenProximity("proximity", 8)
					if not isConduitAlive(68697) then -- Overcharged
						self:StopBar(135695) -- Static Shock
						self:StopBar(136395) -- Bouncing Bolt
					elseif not isConduitAlive(68698) then -- Bouncing Bolt
						self:StopBar(136295) -- Overcharged
						self:StopBar(135695) -- Static Shock
					elseif not isConduitAlive(68398) then -- Static Shock
						self:StopBar(136395) -- Bouncing Bolt
						self:StopBar(136295) -- Overcharged
					end
				elseif args.spellId == 135683 then -- Bouncing Bolt
					if not isConduitAlive(68697) then -- Overcharged
						self:StopBar(135695) -- Static Shock
						self:StopBar(135991) -- Diffusion Chain
					elseif not isConduitAlive(68398) then -- Static Shock
						self:StopBar(136295) -- Overcharged
						self:StopBar(135991) -- Diffusion Chain
					elseif not isConduitAlive(68696) then -- Diffusion Chain
						self:StopBar(135695) -- Static Shock
						self:StopBar(136295) -- Overcharged
					end
				elseif args.spellId == 135680 then -- Static Shock
					if not isConduitAlive(68697) then -- Overcharged
						self:StopBar(135991) -- Diffusion Chain
						self:StopBar(136395) -- Bouncing Bolt
					elseif not isConduitAlive(68698) then -- Bouncing Bolt
						self:StopBar(136295) -- Overcharged
						self:StopBar(135991) -- Diffusion Chain
					elseif not isConduitAlive(68696) then -- Diffusion Chain
						self:StopBar(136295) -- Overcharged
						self:StopBar(136395) -- Bouncing Bolt
					end
				elseif args.spellId == 135682 then -- Overcharge
					if not isConduitAlive(68698) then -- Bouncing Bolt
						self:StopBar(135695) -- Static Shock
						self:StopBar(135991) -- Diffusion Chain
					elseif not isConduitAlive(68398) then -- Static Shock
						self:StopBar(135991) -- Diffusion Chain
						self:StopBar(136395) -- Bouncing Bolt
					elseif not isConduitAlive(68696) then -- Diffusion Chain
						self:StopBar(135695) -- Static Shock
						self:StopBar(136395) -- Bouncing Bolt
					end
				end
			end
		end
	end
end

--"<127.0 16:29:29> [CLEU] SPELL_AURA_APPLIED#false#0xF1310E0D000015E0#Unharnessed Power#2632#1#0xF1310E0D000015E0#Unharnessed Power#2632#1#138070#Amplifier#8#BUFF", -- [37582]
--"<147.6 16:29:50> [CLEU] SPELL_AURA_APPLIED#false#0xF1310E0D000015E0#Unharnessed Power#2632#1#0xF1310E0D000015E0#Unharnessed Power#2632#1#138070#Amplifier#8#BUFF", -- [43515]
--"<168.1 16:30:10> [CLEU] SPELL_AURA_APPLIED#false#0xF1310E0D000015E0#Unharnessed Power#2632#1#0xF1310E0D000015E0#Unharnessed Power#2632#1#138070#Amplifier#8#BUFF", -- [48984]

--"<119.7 16:29:22> [CLEU] SPELL_AURA_APPLIED#false#0xF1310E0D000015DE#Unharnessed Power#2632#0#0xF1310E0D000015DE#Unharnessed Power#2632#0#138070#Amplifier#8#BUFF", -- [35789]
--"<140.3 16:29:43> [CLEU] SPELL_AURA_APPLIED#false#0xF1310E0D000015DE#Unharnessed Power#2632#0#0xF1310E0D000015DE#Unharnessed Power#2632#0#138070#Amplifier#8#BUFF", -- [41307]
--"<160.9 16:30:03> [CLEU] SPELL_AURA_APPLIED#false#0xF1310E0D000015DE#Unharnessed Power#2632#0#0xF1310E0D000015DE#Unharnessed Power#2632#0#138070#Amplifier#8#BUFF", -- [47453]

function mod:Amplifier(args)
	if UnitGUID("focus") == args.destGUID then
		if not UnitIsPlayer(args.destName) then
			self:Message(args.spellId, "Personal", "Info", args.spellName, args.spellId)
			self:Bar(args.spellId, 20.5)
		end
	end
end

--"<266.1 16:31:48> [CLEU] UNIT_DIED#true##nil#-2147483648#-2147483648#0xF1310E0D0000160C#Unharnessed Power#2632#1", -- [68213]

function mod:Deaths(args)
	if args.mobId == 68397 then -- Boss
		self:Win()
	elseif args.mobId == 69133 then -- Unharnessed Power
		if args.destGUID == UnitGUID("focus") then
			self:StopBar(138070) -- Amplifier
		end
	end
end

----------------------------------------
-- Stage 3
--

function mod:ElectricalShock(args)
	if args.amount % 3 == 0 and args.amount > 8 then 
		self:StackMessage(args.spellId, args.destName, args.amount, "Important", "Warning", L["shock"])
	end
end

--------------------------------------------------------------------------------
-- Stage 2
--

--"<539.4 20:31:11> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310B2D00002D6C#Lei Shen#68168#0##nil#-2147483648#-2147483648#136850#Lightning Whip#8", -- [146384]
--"<569.7 20:31:41> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310B2D00002D6C#Lei Shen#68168#0##nil#-2147483648#-2147483648#136850#Lightning Whip#8", -- [155528]
--"<600.0 20:32:12> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310B2D00002D6C#Lei Shen#68168#0##nil#-2147483648#-2147483648#136850#Lightning Whip#8", -- [163094]

function mod:LightningWhip(args)
	self:Bar(args.spellId, (phase == 3) and 30.3 or 45.1)
	self:Message(args.spellId, "Attention", "Alert")
end

--"<268.5 20:26:40> [CLEU] SPELL_PERIODIC_DAMAGE#true##nil#1300#0#0x03800000049495AD#Strydem#1300#0#136853#Lightning Bolt#8#25000#-1#8#nil#nil#nil#nil#nil#nil#nil", -- [71572]

do
	local prev = 0
	function mod:LightningWhipDamage(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(args.spellId)
		end
	end
end

--"<464.9 20:29:56> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310B2D00002D6C#Lei Shen#68168#0##nil#-2147483648#-2147483648#136543#Summon Ball Lightning#8", -- [122773]
--"<495.0 20:30:27> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310B2D00002D6C#Lei Shen#68168#0##nil#-2147483648#-2147483648#136543#Summon Ball Lightning#8", -- [132072]
--"<525.2 20:30:57> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310B2D00002D6C#Lei Shen#68168#0##nil#-2147483648#-2147483648#136543#Summon Ball Lightning#8", -- [141003]

do
	local prev = 0
	function mod:SummonBallLightning(args)
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Bar(args.spellId, (phase == 3) and 45 or 45, L["ball_lightning"])
			self:Message(args.spellId, "Attention", nil, L["ball_lightning"])
		end
	end
end

function mod:FusionSlash(args)
	self:CDBar(args.spellId, 42.4)
	self:Message(args.spellId, "Urgent", "Warning")	
end

--------------------------------------------------------------------------------
-- Intermissions
--

--"<207.4 03:20:11> [BigWigs_Message] BigWigs_Message#BigWigs_Bosses_Lei Shen#stages#Intermission#Positive#Info#Interface\\Icons\\archaeology_5_0_thunderkinginsignia", -- [55556]
--"<221.2 03:20:25> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310B2D00012098#Lei Shen#2632#0##nil#-2147483648#-2147483648#139011#Helm of Command#8", -- [56623]
--"<221.5 03:20:25> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D00012098#Lei Shen#2632#0#0x038000000493F030#Pacteh#1300#0#139011#Helm of Command#8#DEBUFF", -- [56630]
--"<221.5 03:20:25> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D00012098#Lei Shen#2632#0#0x0380000004D6A55B#Ashvael#1300#0#139011#Helm of Command#8#DEBUFF", -- [56631]
--"<221.5 03:20:25> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D00012098#Lei Shen#2632#0#0x03800000049405B1#Kazterson#1300#0#139011#Helm of Command#8#DEBUFF", -- [56632]
--"<251.5 03:20:55> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D00012098#Lei Shen#2632#0#0x0380000004946C82#Aladya#1300#0#139011#Helm of Command#8#DEBUFF", -- [59095]
--"<251.5 03:20:55> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D00012098#Lei Shen#2632#0#0x038000000493C2E8#Xabok#1300#0#139011#Helm of Command#8#DEBUFF", -- [59096]

do
	local helmofCommandList, scheduled = mod:NewTargetList(), nil
	local function warnHelmofCommand(spellId)
		mod:TargetMessage(spellId, helmofCommandList, "Important")
		scheduled = nil
	end
	function mod:HelmofCommand(args)
		helmofCommandList[#helmofCommandList+1] = args.destName
		if not scheduled then
			scheduled = self:ScheduleTimer(warnHelmofCommand, 0.1, args.spellId)
			if helmsdone == 0 then
				helmsdone = 1
				self:Bar(args.spellId, 24.5)
			end
		end	
		if self:Me(args.destGUID) then 
			self:Bar(args.spellId, 8, CL["you"]:format(args.spellName))
			self:Flash(args.spellId)
			self:Say(args.spellId)
		end
	end
end

--"<171.3 20:45:18> [BigWigs_Message] BigWigs_Message#BigWigs_Bosses_Lei Shen#stages#Phase 2#Positive#Info#Interface\\Icons\\Spell_Nature_UnrelentingStorm", -- [40373]
--"<215.7 20:46:02> [CLEU] SPELL_CAST_START#false#0xF1310B2D0000B2EC#Lei Shen#68168#0##nil#-2147483648#-2147483648#136478#Fusion Slash#8", -- [53642]
--"<258.1 20:46:45> [CLEU] SPELL_CAST_START#false#0xF1310B2D0000B2EC#Lei Shen#68168#0##nil#-2147483648#-2147483648#136478#Fusion Slash#8", -- [66398]
--"<300.8 20:47:27> [CLEU] SPELL_CAST_START#false#0xF1310B2D0000B2EC#Lei Shen#68168#0##nil#-2147483648#-2147483648#136478#Fusion Slash#8", -- [80336]

--"<409.7 20:49:16> [BigWigs_Message] BigWigs_Message#BigWigs_Bosses_Lei Shen#stages#Phase 3#Positive#Info#Interface\\Icons\\Spell_Nature_UnrelentingStorm", -- [101961]
--"<429.3 20:49:36> [UNIT_SPELLCAST_SUCCEEDED] Lei Shen [[boss1:Violent Gale Winds::0:136869]]", -- [104429]
--"<430.9 20:49:37> [CLEU] SPELL_CAST_START#false#0xF1310B2D0000B2EC#Lei Shen#68168#0##nil#-2147483648#-2147483648#136850#Lightning Whip#8", -- [104688]
--"<445.4 20:49:52> [CLEU] SPELL_CAST_START#false#0xF1310B2D0000B2EC#Lei Shen#68168#0##nil#-2147483648#-2147483648#135095#Thunderstruck#8", -- [106415]
--"<451.0 20:49:58> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310B2D0000B2EC#Lei Shen#2632#0##nil#-2147483648#-2147483648#136543#Summon Ball Lightning#8", -- [106892]

function mod:OverloadedCircuits()
	helmsdone = 0
	staticdone = 0
	diffusiondone = 0
	overchargeddone = 0
	bouncingdone = 0
	self:Message("stages", "Positive", "Info", CL["phase"]:format(phase), 137176)
	self:CancelAllTimers()
	--self:StopBar(136395) -- Bouncing Bolt
	--self:StopBar(136295) -- Overcharged
	--self:StopBar(135695) -- Static Shock
	--self:StopBar(135991) -- Diffusion Chain
	--if self:Heroic() then
		--self:StopBar(139011) -- Helm of Command
	--end
	if phase == 2 then
		self:CloseProximity("proximity")
		bossstring = "boss1"
		self:CDBar(136478, 42) -- Fusion Slash
		self:CDBar("conduit_abilities", 16.3, L["conduit_abilities_message"], L.conduit_abilities_icon)
		if self:Heroic() then
			if not isConduitAlive(68696) then
				self:OpenProximity("proximity", 8)
				self:CDBar(135991, 14) -- Diffusion Chain
			end
			if not isConduitAlive(68697) then
				self:CDBar(136295, 14) -- Overcharged
			end
			if not isConduitAlive(68698) then
				self:CDBar(-7242, 14, 136395, "SPELL_SHAMAN_MEASUREDINSIGHT") -- Bouncing Bolt	
			end	
			if not isConduitAlive(68398) then
				self:CDBar(135695, 14) -- Static Shock
			end
		end
		if not self:Heroic() then
			if not isConduitAlive(68696) then
				self:CloseProximity("proximity")
			end
		end
		self:CDBar("conduit_abilities", 16.3, L["conduit_abilities_message"], L.conduit_abilities_icon)
	elseif phase == 3 then
		bossstring = "boss1"
		self:Bar(135095, 35) -- Thunderstruck
		self:Bar(136889, 20) -- Violent Gale Winds
		if self:Heroic() then
			self:CDBar("conduit_abilities", 28, L["conduit_abilities_message"], L.conduit_abilities_icon)
		end
	end
	self:Bar(136850, (phase == 2) and 29 or 21) -- Lightning Whip
	self:Bar(136543, (phase == 2) and 13 or 40, L["ball_lightning"]) -- Summon Ball Lightning
end

--"<178.2 20:25:10> [BigWigs_Message] BigWigs_Message#BigWigs_Bosses_Lei Shen#stages#Phase 2#Positive#Info#Interface\\Icons\\Spell_Nature_UnrelentingStorm", -- [43915]
--"<194.4 20:25:26> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D00002D6C#Lei Shen#68168#0#0x0380000004AE315D#Vykishot#1298#0#135695#Static Shock#1#DEBUFF", -- [47371]

--"<171.3 20:45:18> [BigWigs_Message] BigWigs_Message#BigWigs_Bosses_Lei Shen#stages#Phase 2#Positive#Info#Interface\\Icons\\Spell_Nature_UnrelentingStorm", -- [40373]
--"<185.9 20:45:33> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#68168#0#0x0380000004DE993A#L�rgok#1300#0#135695#Static Shock#1#DEBUFF", -- [42803]

--"<123.5 20:44:30> [CLEU] SPELL_CAST_START#false#0xF1310B2D0000B2EC#Lei Shen#2632#0##nil#-2147483648#-2147483648#137045#Supercharge Conduits#8", -- [36317]
--"<129.4 20:44:36> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x03800000048BF754#Blattardos#1300#0#136295#Overcharged#8#DEBUFF", -- [37047]
--"<129.4 20:44:36> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x038000000498D68E#Imsupersdw#1300#0#136295#Overcharged#8#DEBUFF", -- [37048]
--"<137.1 20:44:44> [BigWigs_StartBar] BigWigs_StartBar#BigWigs_Bosses_Lei Shen#-7242#Bouncing Bolt#25#Interface\\Icons\\SPELL_SHAMAN_MEASUREDINSIGHT", -- [37821]
--"<142.4 20:44:49> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x03800000048BF754#Blattardos#1300#0#135695#Static Shock#1#DEBUFF", -- [38276]
--"<142.4 20:44:49> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x0380000004946C82#Aladya#1300#0#135695#Static Shock#1#DEBUFF", -- [38277]
--"<161.2 20:45:08> [BigWigs_StartBar] BigWigs_StartBar#BigWigs_Bosses_Lei Shen#-7242#Bouncing Bolt#25#Interface\\Icons\\SPELL_SHAMAN_MEASUREDINSIGHT", -- [39487]

--intermission2
--"<362.4 20:48:29> [BigWigs_Message] BigWigs_Message#BigWigs_Bosses_Lei Shen#stages#Intermission#Positive#Info#Interface\\Icons\\archaeology_5_0_thunderkinginsignia", -- [97320]
--"<368.2 20:48:35> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x0380000004DA4FA9#Sonie#1300#0#136295#Overcharged#8#DEBUFF", -- [97850]
--"<368.2 20:48:35> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x0380000004D6A55B#Ashvael#1300#0#136295#Overcharged#8#DEBUFF", -- [97851]
--"<381.0 20:48:48> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x03800000048BF754#Blattardos#1300#0#135695#Static Shock#1#DEBUFF", -- [99298]
--"<381.0 20:48:48> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x03800000049465C7#Deac#1298#0#135695#Static Shock#1#DEBUFF", -- [99299]
--"<381.0 20:48:48> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x0380000004941D2F#Faerko#1300#0#135695#Static Shock#1#DEBUFF", -- [99300]
--"<391.4 20:48:58> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x03800000049495AD#Strydem#1300#0#136295#Overcharged#8#DEBUFF", -- [99901]
--"<391.4 20:48:58> [CLEU] SPELL_AURA_APPLIED#false#0xF1310B2D0000B2EC#Lei Shen#2632#0#0x038000000493CCD3#Kuznam#1300#0#136295#Overcharged#8#DEBUFF", -- [99902]

function mod:Intermission(args)
	phase = phase + 1
	self:CancelAllTimers()

	self:StopBar(135991) -- Diffusion Chain
	self:StopBar(136395) -- Bouncing Bolt
	self:StopBar(136295) -- Overcharged		
	self:StopBar(135695) -- Static Shock

	self:StopBar(L["conduit_abilities_message"])
	self:StopBar(135150) -- Crashing Thunder
	self:StopBar(134912) -- Decapitate
	self:StopBar(135095) -- Thunderstruck
	self:StopBar(136850) -- Lightning Whip
	self:StopBar(L["ball_lightning"]) -- Summon Ball Lightning
	self:StopBar(136478) -- Fusion Slash
	self:Message("stages", "Positive", "Info", L["intermission"], args.spellId)
	self:Bar("stages", 47.4, L["intermission"], args.spellId)
	local diff = self:Difficulty()
	--if diff == 3 or diff == 5 or diff == 7 then -- 10 mans and assume LFR too
		--if isConduitAlive(68398) then self:CDBar(135695, 18) end -- Static Shock
		--if isConduitAlive(68697) then self:CDBar(136295, 7) end -- Overcharged
		--if isConduitAlive(68698) then self:CDBar(-7242, 20, 136395, "SPELL_SHAMAN_MEASUREDINSIGHT") end -- Bouncing Bolt
		--if isConduitAlive(68696) then self:CDBar(135991, 7) end
	--else -- 25 man
		if self:Heroic() then
			self:OpenProximity("proximity", 8)
			self:CDBar(135991, 5.9)
			self:CDBar(136295, 5.9)
			self:CDBar(-7242, 13.8, 136395, "SPELL_SHAMAN_MEASUREDINSIGHT")
			self:CDBar(135695, 18.9)
		else
			if isConduitAlive(68696) then self:OpenProximity("proximity", 8) end
			if isConduitAlive(68696) then self:CDBar(135991, 5.9) end -- Diffusion Chain
			if isConduitAlive(68697) then self:CDBar(136295, 5.9) end -- Overcharged
			if isConduitAlive(68698) then self:CDBar(-7242, 13.8, 136395, "SPELL_SHAMAN_MEASUREDINSIGHT") end -- Bouncing Bolt
			if isConduitAlive(68398) then self:CDBar(135695, 18.9) end -- Static Shock
		end
	--end
	if self:Heroic() then
		self:Bar(139011, 13.8) -- Helm of Command
	end	
end

--------------------------------------------------------------------------------
-- Stage 1
--

--"<6.5 16:27:29> [CLEU] SPELL_DAMAGE#false#0xF1310B2D00001521#Lei Shen#68168#1#0x0380000004BD7035#Justmonk#1300#0#135150#Crashing Thunder#8#79617#-1#8#nil#nil#30921#nil#nil#nil#nil", -- [2085]
--"<6.5 16:27:29> [CLEU] SPELL_AURA_APPLIED#true##nil#1300#0#0x0380000004BD7035#Justmonk#1300#0#135153#Crashing Thunder#8#DEBUFF", -- [2089]
--"<7.6 16:27:30> [CLEU] SPELL_PERIODIC_DAMAGE#true##nil#1300#0#0x0380000004BD7035#Justmonk#1300#0#135153#Crashing Thunder#8#100179#-1#8#nil#nil#nil#nil#nil#nil#nil", -- [2537]

function mod:CrashingTimer(args)
	local ctime = GetTime()
	if ctime-cprev > 20 then -- if last cast was over 20s
		cprev = ctime
		self:Bar(args.spellId, 30)
	end
end

do
	local prev = 0
	function mod:CrashingThunder(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 1 then
			prev = t
			self:Message(135150, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(135150)
		end
	end
end

function mod:Thunderstruck(args)
	self:Message(args.spellId, "Attention", "Alert")
	self:Bar(args.spellId, (phase == 3) and 30 or 45.8)
end

function mod:Decapitate(args)
	self:CDBar(args.spellId, 50)
	self:TargetMessage(args.spellId, args.destName, "Personal", "Info")
	if self:Me(args.destGUID) then
		self:Flash(args.spellId)
	end
end

--------------------------------------------------------------------------------
-- Conduits
--

--"<372.1 16:33:34> [UNIT_SPELLCAST_SUCCEEDED] Lei Shen [[boss1:Bouncing Bolt::0:136395]]", -- [98610]
--"<412.1 16:34:14> [UNIT_SPELLCAST_SUCCEEDED] Lei Shen [[boss1:Bouncing Bolt::0:136395]]", -- [111544]
--"<455.6 16:34:58> [UNIT_SPELLCAST_SUCCEEDED] Lei Shen [[boss1:Bouncing Bolt::0:136395]]", -- [125536]
--"<499.1 16:35:41> [UNIT_SPELLCAST_SUCCEEDED] Lei Shen [[boss1:Bouncing Bolt::0:136395]]", -- [137082]

local prevbounce = 0
function mod:Boss5Succeeded(unitId, spellName, _, _, spellId)
	if spellId == 136361 then -- Bouncing Bolt 136395 retail
		if not UnitExists(bossstring) then
			if bouncingdone == 0 then
				bouncingdone = 1
				self:Bar(-7242, 24.5, 136395, "SPELL_SHAMAN_MEASUREDINSIGHT")
			end
		else
			self:CDBar(-7242, 40, 136395, "SPELL_SHAMAN_MEASUREDINSIGHT")
		end

		t = GetTime()
		if(t-prevbounce > 3) then
			prevbounce = t
			self:Message(-7242, "Important", "Long", 136395, "SPELL_SHAMAN_MEASUREDINSIGHT") -- dont spam warnings
		end
	elseif spellId == 136869 then -- Violent Gale Winds
		self:Message(136889, "Important", "Long")
		self:Bar(136889, 30)
	end
end

--[[do
	local diffusionList = mod:NewTargetList()
	function mod:DiffusionChainDamage(args)
		for i, player in next, diffusionList do
			if player:find(args.destName, nil, true) then
				return
			end
		end
		diffusionList[#diffusionList+1] = args.destName
	end

	local function warnDiffusionAdds(spellName)
		if #diffusionList > 0 then
			mod:TargetMessage(135991, diffusionList, "Important", "Info", spellName, nil, true)
			wipe(diffusionList)
		else
			mod:Message(135991, "Important")
		end
	end

	function mod:DiffusionChain(args)
		if not UnitExists("boss1") then
			self:Bar(args.spellId, 25)
		else
			self:CDBar(args.spellId, 40)
		end
		self:ScheduleTimer(warnDiffusionAdds, 0.2, args.spellName)
	end
end]]

function mod:DiffusionChain(args)
	self:Message(args.spellId, "Important")
	if not UnitExists(bossstring) then
		if diffusiondone == 0 then
			diffusiondone = 1
			self:Bar(args.spellId, 25)
		end
	else
		self:CDBar(args.spellId, 40)
	end
end

do
	local overchargedList, scheduled = mod:NewTargetList(), nil
	local function warnOvercharged(spellId)
		if not UnitExists(bossstring) then
			if overchargeddone == 0 then
				overchargeddone = 1
				mod:Bar(spellId, 23)
			end
		else
			mod:CDBar(spellId, 40)
		end
		mod:TargetMessage(spellId, overchargedList, "Urgent", "Alarm")
		scheduled = nil
	end
	function mod:Overcharged(args)
		overchargedList[#overchargedList+1] = args.destName
		if not scheduled then
			scheduled = self:ScheduleTimer(warnOvercharged, 0.2, args.spellId)
		end
		if self:Me(args.destGUID) then
			self:Flash(args.spellId)
			self:Say(args.spellId)
		end
	end
end

do
	local staticShockList, scheduled = mod:NewTargetList(), nil
	local function warnStaticShock(spellId)
		if not UnitExists(bossstring) then
			if staticdone == 0 then
				staticdone = 1
				mod:Bar(spellId, 20)
			end
		else
			if phase == 3 then
				mod:CDBar(spellId, 42)
			else
				mod:CDBar(spellId, 40)
			end
		end
		mod:TargetMessage(spellId, staticShockList, "Urgent", "Alarm")
		scheduled = nil
	end
	local function staticShockMessage(remainingTime)
		mod:Say(135695, ("%d"):format(remainingTime), true)
	end
	function mod:StaticShockApplied(args)
		staticShockList[#staticShockList+1] = args.destName
		if not scheduled then
			scheduled = self:ScheduleTimer(warnStaticShock, 0.2, args.spellId)
		end	
		if self:Me(args.destGUID) then
			self:Flash(args.spellId)
			self:Say(args.spellId)
			self:ScheduleTimer(staticShockMessage, 2, 6)
			self:ScheduleTimer(staticShockMessage, 3, 5)
			self:ScheduleTimer(staticShockMessage, 4, 4)
			self:ScheduleTimer(staticShockMessage, 5, 3)
			self:ScheduleTimer(staticShockMessage, 6, 2)
			self:ScheduleTimer(staticShockMessage, 7, 1)
		end
	end
end

