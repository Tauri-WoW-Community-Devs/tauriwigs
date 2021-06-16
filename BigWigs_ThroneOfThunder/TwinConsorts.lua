--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Twin Consorts", 930, 829)
if not mod then return end
mod:RegisterEnableMob(68905, 68904) -- Lu'lin, Suen

--------------------------------------------------------------------------------
-- Locals
--

local deadBosses = 0
local inferno = nil
local barrageCounter = 1
local phase = 1
local comets = 1
local infernos = 1
local beastcount = 1
local tearscount = 1
local fancount = 1
local chargecount = 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.last_phase_yell_trigger = "Just this once..." -- "<490.4 01:24:30> CHAT_MSG_MONSTER_YELL#Just this once...#Lu'lin###Suen##0#0##0#3273#nil#0#false#false", -- [6]

	L.barrage_fired = "Barrage fired!"
	
	L.casting_barrage = "Casting Barrages"
	L.casting_barrage_desc = "Shows a special bar/warning for Cosmic Barrage."
	L.casting_barrage_icon = "ability_druid_starfall"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		-- Lu'lin
		-7631, "casting_barrage", {-7634, "TANK_HEALER"}, -- phase 1
		-7649, {137440, "FLASH"}, 138823,-- phase 2
		{137531, "FLASH"}, --Phase 3
		-- Suen
		-7643, -- phase 1
		{137408, "TANK_HEALER"}, {-7638, "FLASH"}, {137491, "FLASH"}, -- phase 2
		-- Celestial Aid
		138300, 138318, 138306, 138855, 115948,
		"proximity", "stages", "berserk", "bosskill",
	}, {
		[-7631] = -7629,
		[-7643] = -7642,
		[138300] = -7651,
		["proximity"] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	-- Celestial Aid
	self:Log("SPELL_AURA_APPLIED", "CelestialAid", 138855, 138306, 138300) -- Tiger, Serpent, Ox
	self:Log("SPELL_DAMAGE", "Crane", 138318)
	self:Log("SPELL_AURA_APPLIED", "Invoke", 138264, 138267, 138254, 138189) -- tiger serpent ox crane

	-- Suen
		-- phase 2
	self:Log("SPELL_CAST_START", "NuclearInferno", 137491)
	self:Log("SPELL_PERIODIC_DAMAGE", "FlamesOfPassion", 137417)
	self:Log("SPELL_CAST_SUCCESS", "FlamesOfPassionCharge", 137414)
	self:Log("SPELL_AURA_APPLIED_DOSE", "FanOfFlames", 137408)
	self:Log("SPELL_AURA_APPLIED", "FanOfFlames", 137408)
		-- phase 1
	self:Log("SPELL_AURA_REMOVED", "TearsOfTheSunRemoved", 137404)
	self:Log("SPELL_AURA_APPLIED", "TearsOfTheSunApplied", 137404)

	-- Lu'lin
		-- phase 3
	self:Log("SPELL_CAST_START", "TidalForce", 137531)
		-- phase 2
	self:Log("SPELL_AURA_APPLIED", "IcyShadows", 137440)
	self:Log("SPELL_SUMMON", "IceComet", 137419)
		-- phase 1
	self:Log("SPELL_AURA_APPLIED", "CosmicBarrage", 136752)
	self:Log("SPELL_CAST_SUCCESS", "BeastOfNightmares", 137375)

	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "Phase2", "boss1", "boss2")
	self:Yell("LastPhase", L["last_phase_yell_trigger"])

	self:AddSyncListener("Phase2")
	self:AddSyncListener("Phase3")
	self:AddSyncListener("TidalForce")

	self:Death("Deaths", 68905, 68904)
end

function mod:OnEngage()
	self:Berserk(600) -- 25 N PTR Confirmed
	self:Bar("stages", 183, CL["phase"]:format(2), 137440)
	deadBosses = 0
	self:OpenProximity("proximity", 10) --barrage is 8 but you want some playroom
	self:CDBar(-7631, 16.8, ("[%d] %s"):format(barrageCounter, self:SpellName(136752))) -- Cosmic Barrage
	self:CDBar(-7643, 29, ("[%d] %s"):format(tearscount, self:SpellName(137404))) -- Tears of the Sun
	self:CDBar(-7634, 50, ("[%d] %s"):format(beastcount, self:SpellName(137375))) -- Beast of Nightmares
	inferno = nil
	barrageCounter = 1
	phase = 1
	comets = 1
	infernos = 1
	tearscount = 1
	beastcount = 1
	fancount = 1
	chargecount = 1
end

--------------------------------------------------------------------------------
-- Event Handlers
--

--"<189.5 18:09:10> [BigWigs_Message] BigWigs_Message#BigWigs_Bosses_Twin Consorts#stages#Phase 2#Positive#Long#Interface\\Icons\\paladin_holy", -- [52052]
--"<211.7 18:09:33> [CLEU] SPELL_SUMMON#false#0xF1310D290000650F#Lu'lin#2632#0#0xF1310FDC0000679C#Ice Comet#2600#0#137419#Ice Comet#16", -- [61394]
--"<234.0 18:09:55> [CLEU] SPELL_SUMMON#false#0xF1310D290000650F#Lu'lin#2632#0#0xF1310FDC000067A9#Ice Comet#2600#0#137419#Ice Comet#16", -- [70524]
--"<237.7 18:09:59> [CLEU] SPELL_CAST_START#false#0xF1310D280000650E#Suen#68168#0##nil#-2147483648#-2147483648#137491#Nuclear Inferno#4", -- [71352]
--"<257.0 18:10:18> [CLEU] SPELL_SUMMON#false#0xF1310D290000650F#Lu'lin#2632#0#0xF1310FDC000067C8#Ice Comet#2600#0#137419#Ice Comet#16", -- [76302]
--"<289.8 18:10:51> [CLEU] SPELL_CAST_START#false#0xF1310D280000650E#Suen#68168#0##nil#-2147483648#-2147483648#137491#Nuclear Inferno#4", -- [83025]

function mod:OnSync(sync)
	if sync == "Phase2" then
		phase = 2
		self:Bar("stages", 177, CL["phase"]:format(3), 138688)
		self:Message("stages", "Positive", "Long", CL["phase"]:format(2), 137401)
		self:StopBar(137404) -- Tears of the Sun
		self:StopBar(-7634) -- Beast of Nightmares
		self:StopBar(("[%d] %s"):format(barrageCounter, self:SpellName(136752))) -- Cosmic Barrage
		self:CDBar(-7649, 18) -- Ice Comet
		self:CDBar(-7638, 20.3) -- Flames of Passion
		self:CDBar(137408, 10) -- Fan of Flames
		if self:Heroic() then
			self:CDBar(137491, 45.1, ("[%d] %s"):format(infernos, self:SpellName(137491))) -- Nuclear Inferno
		end
	elseif sync == "Phase3" then
		if phase == 2 then
			phase = 3
			self:Message("stages", "Positive", "Long", CL["phase"]:format(3), 137401)
			--self:StopBar(-7638) -- Flames of Passion
			self:StopBar(137408) -- Fan of Flames
			self:StopBar(137491) -- Nuclear Inferno
			self:Bar(137531, self:Heroic() and 19 or 19) -- Tidal Force
			--self:CDBar(-7638, 18) -- Flames of Passion
			--if self:Heroic() then
				self:CDBar(-7631, 47, ("[%d] %s"):format(barrageCounter, self:SpellName(136752))) -- Cosmic Barrage
			--end
		end
	elseif sync == "TidalForce" then
		self:Message(137531, "Urgent", "Alarm")
		self:Bar(137531, 18, CL["cast"]:format(self:SpellName(137531))) -- Tidal Force
		self:CDBar(137531, 71)
		self:Flash(137531)
	end
end

--------------------------------------------------------------------------------
-- Celestial Aid
--

do
	local prev = 0
	function mod:CelestialAid(args)
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Positive")
			self:Bar(args.spellId, args.spellId == 138855 and 20 or 30) -- Xuen lasts 20s
		end
	end
end

do
	local prev = 0
	function mod:Crane(args)
		local t = GetTime()
		if t-prev > 30 then
			self:Message(args.spellId, "Positive")
			prev = t
		end
	end
end

function mod:Invoke(args)
	self:Bar(115948, 40.5) -- shrines ready to click again
end


--------------------------------------------------------------------------------
-- Suen
--

-- Phase 2

--"<189.5 18:09:10> [BigWigs_Message] BigWigs_Message#BigWigs_Bosses_Twin Consorts#stages#Phase 2#Positive#Long#Interface\\Icons\\paladin_holy", -- [52052]
--"<212.6 18:09:34> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#68168#0##nil#-2147483648#-2147483648#137414#Flames of Passion#4", -- [61809]
--"<250.6 18:10:12> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#68168#0##nil#-2147483648#-2147483648#137414#Flames of Passion#4", -- [74924]
--"<284.5 18:10:46> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#68168#0##nil#-2147483648#-2147483648#137414#Flames of Passion#4", -- [81784]
--"<317.2 18:11:18> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#68168#0##nil#-2147483648#-2147483648#137414#Flames of Passion#4", -- [89902]
--"<352.3 18:11:53> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#2632#0##nil#-2147483648#-2147483648#137414#Flames of Passion#4", -- [95032]
--38.0, 33.9, 32.7, 35.1

function mod:FlamesOfPassionCharge(args)
	chargecount = chargecount + 1
	self:Message(-7638, "Urgent")
	if self:Heroic() then
		if chargecount == 2 or chargecount == 5 or chargecount == 8 or chargecount == 11 then
			self:CDBar(-7638, 38)
		else
			self:CDBar(-7638, 29)
		end
	else
		self:CDBar(-7638, 30)
	end
end

do
	local prev = 0
	function mod:FlamesOfPassion(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(-7638, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(-7638)
		end
	end
end

do
	local function infernoOver(spellId)
		inferno = nil
		mod:Message(spellId, "Positive", nil, CL["over"]:format(mod:SpellName(spellId)))
	end
	function mod:NuclearInferno(args)
		self:Message(args.spellId, "Important", "Alert", ("[%d] %s"):format(infernos, args.spellName))
		infernos = infernos + 1
		inferno = true
		self:Flash(args.spellId)
		if infernos ~= 4 then -- dont trigger 4th timer, retrigger in p3 for now
			--if phase == 3 then
			--	self:CDBar(args.spellId, 75.2, ("[%d] %s"):format(infernos, args.spellName))
			--else
				self:CDBar(args.spellId, 49.5, ("[%d] %s"):format(infernos, args.spellName))
			--end
		else
			self:CDBar(args.spellId, 100, ("[%d] %s"):format(infernos, args.spellName)) -- Nuclear Inferno
		end
		self:Bar(args.spellId, 12, CL["cast"]:format(args.spellName))
		self:ScheduleTimer(infernoOver, 12, args.spellId)
	end
end

--"<203.9 18:09:25> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#68168#0#0x0380000004947837#Treckie#1300#0#137408#Fan of Flames#4", -- [56795]
--"<215.5 18:09:36> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#68168#0#0x0380000004947837#Treckie#1300#0#137408#Fan of Flames#4", -- [63213]
--"<229.2 18:09:50> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#68168#0#0x0380000004945DDF#Sco#1300#0#137408#Fan of Flames#4", -- [68828]
--4:19
function mod:FanOfFlames(args)
	fancount = fancount + 1
	self:StackMessage(args.spellId, args.destName, args.amount, "Urgent", "Info")
	if self:Heroic() then
		if fancount == 4 then
			self:CDBar(args.spellId, 22.6)
		elseif fancount == 8 or fancount == 12 then
			self:CDBar(args.spellId, 12.6)
		elseif fancount == 14 then
			-- only 13 fans so stop making timers
		else
			self:CDBar(args.spellId, 11.6)
		end
	else
		self:CDBar(args.spellId, 12)
	end
end

-- Phase 1

--"<29.5 18:06:31> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#2632#0##nil#-2147483648#-2147483648#137404#Tears of the Sun#4", -- [10187]
--"<69.3 18:07:10> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#2632#0##nil#-2147483648#-2147483648#137404#Tears of the Sun#4", -- [22321]
--"<113.1 18:07:54> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#2632#0##nil#-2147483648#-2147483648#137404#Tears of the Sun#4", -- [33203]
--"<154.2 18:08:35> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D280000650E#Suen#2632#0##nil#-2147483648#-2147483648#137404#Tears of the Sun#4", -- [43859]

--"<29.5 18:06:31> [CLEU] SPELL_AURA_APPLIED#false#0xF1310D280000650E#Suen#2632#0#0xF1310D280000650E#Suen#2632#0#137404#Tears of the Sun#4#BUFF", -- [10186]
--"<39.3 18:06:40> [CLEU] SPELL_AURA_REMOVED#false#0xF1310D280000650E#Suen#2632#0#0xF1310D280000650E#Suen#2632#0#137404#Tears of the Sun#4#BUFF", -- [13867]
--"<113.1 18:07:54> [CLEU] SPELL_AURA_APPLIED#false#0xF1310D280000650E#Suen#2632#0#0xF1310D280000650E#Suen#2632#0#137404#Tears of the Sun#4#BUFF", -- [33202]
--"<123.0 18:08:04> [CLEU] SPELL_AURA_REMOVED#false#0xF1310D280000650E#Suen#2632#0#0xF1310D280000650E#Suen#2632#0#137404#Tears of the Sun#4#BUFF", -- [36010]

function mod:TearsOfTheSunRemoved(args)
	self:Message(-7643, "Positive", nil, CL["over"]:format(args.spellName))
end

function mod:TearsOfTheSunApplied(args)
	tearscount = tearscount + 1
	self:Message(-7643, "Attention", ("[%d] %s"):format(tearscount, args.spellName))
	self:Bar(-7643, 9.8, CL["cast"]:format(args.spellName))	
	if tearscount ~= 5 then
		self:CDBar(-7643, 39.8, ("[%d] %s"):format(tearscount, args.spellName))
	end
end

--------------------------------------------------------------------------------
-- Lu'lin
--

-- Phase 3

function mod:TidalForce(args)
	self:Sync("TidalForce")
end

-- Phase 2

function mod:IcyShadows(args)
	if self:Me(args.destGUID) and not inferno and not self:Tank() then
		self:Message(args.spellId, "Personal", "Info", CL["underyou"]:format(args.spellName))
	end
end

function mod:IceComet(args)
	comets = comets + 1
	self:Message(-7649, "Positive")
	if self:Heroic() then
		if phase == 2 then
			if comets == 2 or comets == 4 or comets == 6 then
				self:CDBar(-7649, 20.2)
			elseif comets == 3 then
				self:CDBar(-7649, 23.2)
			elseif comets == 5 then
				self:CDBar(-7649, 28.2)
			elseif comets == 7 then
				self:CDBar(-7649, 28.2)
			elseif comets == 8 then
				self:CDBar(-7649, 26) -- for 1st of p3
			end
		else
			if comets == 9 or comets == 11 then
				self:CDBar(-7649, 30.2)
			elseif comets == 10 or comets == 12 then
				self:CDBar(-7649, 36.2)
			end
		end
	else
		if phase == 2 then
			if comets == 9 then
				self:CDBar(-7649, 26) -- for 1st of p3
			else
				self:CDBar(-7649, 20.2)
			end
		else
			if comets == 10 or comets == 12 then
				self:CDBar(-7649, 30.2)
			elseif comets == 11 or comets == 13 then
				self:CDBar(-7649, 36.2)
			end
		end
	end
end

-- Phase 1

--"<18.2 18:06:19> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D290000650F#Lu'lin#68168#0##nil#-2147483648#-2147483648#136752#Cosmic Barrage#64", -- [6090]
--"<41.5 18:06:43> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D290000650F#Lu'lin#68168#0##nil#-2147483648#-2147483648#136752#Cosmic Barrage#64", -- [14475]
--"<65.7 18:07:07> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D290000650F#Lu'lin#68168#0##nil#-2147483648#-2147483648#136752#Cosmic Barrage#64", -- [21469]
--"<87.5 18:07:29> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D290000650F#Lu'lin#68168#0##nil#-2147483648#-2147483648#136752#Cosmic Barrage#64", -- [27031]
--"<113.1 18:07:54> [CLEU] SPELL_CAST_SUCCESS#false#0xF1310D290000650F#Lu'lin#68168#0##nil#-2147483648#-2147483648#136752#Cosmic Barrage#64", -- [33212]

function mod:CosmicBarrage(args)
	self:Message(-7631, "Urgent", "Alarm", ("[%d] %s"):format(barrageCounter, args.spellName))

	barrageCounter = barrageCounter + 1
	if phase == 1 then
		if barrageCounter ~= 9 then
			self:CDBar(-7631, 20.6, ("[%d] %s"):format(barrageCounter, args.spellName))
		end
	elseif phase == 3 then
		if barrageCounter == 10 then
			self:CDBar(-7631, 29, ("[%d] %s"):format(barrageCounter, args.spellName))
		elseif barrageCounter == 11 then
			self:CDBar(-7631, 32.6, ("[%d] %s"):format(barrageCounter, args.spellName))
		else
			self:CDBar(-7631, 18.6, ("[%d] %s"):format(barrageCounter, args.spellName))
		end
	else -- p4
			self:CDBar(-7631, 20.6, ("[%d] %s"):format(barrageCounter, args.spellName))
	end
	self:ScheduleTimer("Message", 5.4, "casting_barrage", "Urgent", "Alarm", L["barrage_fired"], L["casting_barrage_icon"]) -- This is when the little orbs start to move
	self:Bar("casting_barrage", 5.5, CL["cast"]:format(args.spellName), L["casting_barrage_icon"])
end

function mod:BeastOfNightmares(args)
	beastcount = beastcount + 1
	self:TargetMessage(-7634, args.destName, "Attention", "Info", nil, nil, true)
	if beastcount ~= 4 then
		self:Bar(-7634, 51, ("[%d] %s"):format(beastcount, args.spellName))
	end
end

--------------------------------------------------------------------------------
-- General
--

--"<200.3 18:09:21> [UNIT_SPELLCAST_SUCCEEDED] Suen [[boss1:Light of Day::0:138823]]", -- [54913]
--"<217.9 18:09:39> [UNIT_SPELLCAST_SUCCEEDED] Suen [[boss1:Light of Day::0:138823]]", -- [64529]
--"<228.0 18:09:49> [UNIT_SPELLCAST_SUCCEEDED] Suen [[boss1:Light of Day::0:138823]]", -- [68463]
--"<260.7 18:10:22> [UNIT_SPELLCAST_SUCCEEDED] Suen [[boss1:Light of Day::0:138823]]", -- [77113]
--"<271.6 18:10:33> [UNIT_SPELLCAST_SUCCEEDED] Suen [[boss1:Light of Day::0:138823]]", -- [79292]
--"<311.6 18:11:13> [UNIT_SPELLCAST_SUCCEEDED] Suen [[boss1:Light of Day::0:138823]]", -- [88741]
--17.6, 10.1, 32.7, 10.9, 40

function mod:Phase2(_, _, _, _, spellId)
	if spellId == 137187 then -- Lu'lin Dissipate
		self:Sync("Phase2")
	elseif spellId == 138823 then -- Light of Day
		self:Message(138823, "Attention")
	end
end

function mod:LastPhase()
	self:Sync("Phase3")
end

function mod:Deaths(args)
	if args.mobId == 68905 then -- Lu'lin
		self:StopBar(("[%d] %s"):format(barrageCounter, self:SpellName(136752))) -- Cosmic Barrage
		self:StopBar(137531) -- Tidal Force
	elseif args.mobId == 68904 then -- Suen
		self:StopBar(-7638) -- Flames of Passion
		self:StopBar(137491) -- Nuclear Inferno
		self:StopBar(("[%d] %s"):format(infernos, self:SpellName(137491))) -- Nuclear Inferno with count
		self:StopBar(("[%d] %s"):format(barrageCounter, self:SpellName(136752))) -- stop to reset Cosmic Barrage
		self:CDBar(-7631, 16.8, ("[%d] %s"):format(barrageCounter, self:SpellName(136752))) -- Cosmic Barrage start

		self:StopBar(-7649) -- Ice Comet
		if self:Tank() or self:Healer() then
			self:CDBar(-7634, 64, ("[%d] %s"):format(beastcount, self:SpellName(137375))) -- Beast of Nightmares
		end
		self:StopBar(137531) -- Tidal Force --in phase 4 she stops doing this and goes back to p1 rotations.
	end
	if deadBosses == 0 then
		self:Message("stages", "Positive", "Long", CL["phase"]:format(4), 137401)
		phase = 4
		--barrageCounter = 1
	end	
	deadBosses = deadBosses + 1
	if deadBosses == 2 then
		self:Win()
	end
end

