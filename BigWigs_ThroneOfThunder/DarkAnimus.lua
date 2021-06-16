--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Dark Animus", 930, 824)
if not mod then return end
mod:RegisterEnableMob(69701, 69700, 69699, 69427) -- Anima Golem, Large Anima Golem, Massive Anima Golem, Dark Animus

--------------------------------------------------------------------------------
-- Locals
--

--local swapMarker = true
local animaCounter = 1
local joltCounter = 1
local matterSwapTargets = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_trigger = "The orb explodes!"

	L.matterswap = GetSpellInfo(139919)
	L.matterswap_desc = "A player with Matter Swap is far away from you. You will swap places with them if they are dispelled."
	L.matterswap_message = "You are furthest for Matter Swap!"
	L.matterswap_icon = 138618

	L.slam_message = "Slam"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{138485, "FLASH", "SAY"},
		{138609, "FLASH", "DISPEL", "SAY",}, "matterswap", {-7770, "TANK"},
		138644, {136954, "TANK"}, --[[138691,]] 138707, 138780, {138763, "FLASH"}, {138729, "FLASH"},
		"berserk", "bosskill",
	}, {
		[138485] = -7759, -- Large Anima Golem
		[138609] = -7760, -- Massive Anima Golem
		[138644] = -7762, -- Dark Animus
		["berserk"] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "BossEngage") -- use it to detect when the actual boss enters the fight
	self:Emote("Engage", L["engage_trigger"])	

	-- Dark Animus
	self:Log("SPELL_CAST_START", "FullPower", 138729)
	self:Log("SPELL_CAST_START", "InterruptingJolt", 138763, 139867, 139869)
	self:Log("SPELL_CAST_SUCCESS", "Empower", 138780) -- Empower Golem
	--self:Log("SPELL_AURA_APPLIED", "AnimaFont", 138691)
	self:Log("SPELL_DAMAGE", "NoobAlert", 138707)
	self:Log("SPELL_CAST_START", "AnimaRing", 136954) -- this is 1 sec faster than SUCCESS but has no destName
	self:Log("SPELL_CAST_SUCCESS", "SiphonAnima", 138644)
	-- Massive Anima Golem
	self:Log("SPELL_AURA_APPLIED_DOSE", "ExplosiveSlam", 138569)
	self:Log("SPELL_AURA_APPLIED", "ExplosiveSlam", 138569)
	self:Log("SPELL_AURA_REMOVED", "MatterSwapRemoved", 138609)
	self:Log("SPELL_AURA_APPLIED", "MatterSwapApplied", 138609)
	-- Large Anima Golem
	--self:Log("SPELL_DAMAGE", "CrimsonWake", 138485)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_WHISPER") -- looks like this is forever emote

	self:Death("Win", 69427)
end

function mod:OnEngage()
	if not self:Heroic() then
		-- this is needed mainly for normal, when you wipe before boss is engaged
		self:StopWipeCheck()
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "StartWipeCheck")
		self:RegisterEvent("PLAYER_REGEN_DISABLED", "StopWipeCheck")
		if self:LFR() then
			self:Berserk(600)
		end
	else
		self:Berserk(410, nil, nil, 138729)
	end
	self:CDBar(136954, 24)
	joltCounter = 1
	animaCounter = 1
	wipe(matterSwapTargets)
	--swapMarker = true
end

--------------------------------------------------------------------------------
-- Event Handlers
--

--------------------------------------------------------------------------------
-- Dark Animus
--

function mod:FullPower(args)
	self:StopBar(138780) -- Empower
	self:StopBar(("[%d] %s"):format(animaCounter, self:SpellName(138644))) -- Siphon Anima
	self:StopBar(("[%d] %s"):format(joltCounter, self:SpellName(138763))) -- Interrupting Jolt
	self:Message(args.spellId, "Important", "Long")
	self:Flash(args.spellId)
end

function mod:InterruptingJolt(args)
	self:Message(args.spellId, "Important", "Long", ("[%d] %s"):format(joltCounter, args.spellName))
	joltCounter = joltCounter + 1
	self:Bar(args.spellId, 21.8, ("[%d] %s"):format(joltCounter, args.spellName)) --16.9 (old value)
	self:Flash(args.spellId)
	if self:Heroic() then
		--self:Bar(args.spellId, 1.4, CL["cast"]:format(args.spellName))
	elseif self:LFR() then
		--self:Bar(args.spellId, 3.8, CL["cast"]:format(args.spellName))
	else
		--self:Bar(args.spellId, 2.2, CL["cast"]:format(args.spellName))
	end
end

function mod:Empower(args)
	self:Message(args.spellId, "Attention")
	self:CDBar(args.spellId, 15.5)
end

--[[function mod:AnimaFont(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Personal", nil, CL["you"]:format(args.spellName))
		self:Bar(args.spellId, 30, CL["you"]:format(args.spellName)) -- this is duration, cooldowns seems to be 33-46
	end
end]]

function mod:AnimaRing(args)
	self:Message(args.spellId, "Important", "Alert")
	self:CDBar(args.spellId, 24)
end

function mod:SiphonAnima(args)
	self:Message(args.spellId, "Attention", nil, ("[%d] %s"):format(animaCounter, args.spellName))	
	animaCounter = animaCounter + 1
	if self:Heroic() then
		self:Bar(args.spellId, self:Heroic() and 20.5 or 6, ("[%d] %s"):format(animaCounter, args.spellName))
	end
end

function mod:BossEngage()
	self:CheckBossStatus()
	if self:MobId(UnitGUID("boss1")) == 69427 then
		if self:Heroic() then
			self:Bar(138644, self:Heroic() and 120 or 30, ("[%d] %s"):format(animaCounter, self:SpellName(138644))) -- Siphon Anima
		end
		if self:Heroic() then
			self:CDBar(138780, 5.1) -- Empower Golem
		end
	end
end

function mod:NoobAlert(args)
	if UnitIsGroupLeader("player") then
		if self:Heroic() then
			SendChatMessage(args.destName.." hit by "..GetSpellLink(args.spellId), "RAID")
		end
	end
end

--------------------------------------------------------------------------------
-- Massive Anima Golem
--

do
	local scheduled = {}
	local function warnSlam(destName, spellName)
		local _, _, _, amount = UnitDebuff(destName, spellName)
		if amount then
			mod:StackMessage(-7770, destName, amount, "Urgent", "Info", L["slam_message"])
		end
		scheduled[destName] = nil
	end
	function mod:ExplosiveSlam(args)
		local golem = self:GetUnitIdByGUID(args.sourceGUID)
		if (golem and UnitGUID(golem.."target") == args.destGUID) or (args.destName and self:Tank(args.destName)) then -- don't care about non-tanks gaining stacks
			if not scheduled[args.destName] then
				scheduled[args.destName] = self:ScheduleTimer(warnSlam, 1, args.destName, args.spellName)
			end
		end
	end
end

--[[function mod:MatterSwapRemoved(args)
	if GetRaidTargetIndex(args.destName) then
		SetRaidTarget(args.destName, 0)
	end
	self:StopBar(args.spellName, args.destName)
end

function mod:MatterSwapApplied(args)
	if swapMarker then
		swapMarker = nil
		self:PrimaryIcon(args.spellId, args.destName)
	else
		swapMarker = true
		self:SecondaryIcon(args.spellId, args.destName)
	end
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Personal", "Info", CL["you"]:format(args.spellName))
		self:Flash(args.spellId)
		self:Say(args.spellId)
	end
	if self:Dispeller("magic") then
		self:TargetMessage(args.spellId, args.destName, "Important", "Alarm", nil, nil, true)
		self:TargetBar(args.spellId, 12, args.destName)
	end
end]]

do
	local SetMapToCurrentZone = BigWigsLoader.SetMapToCurrentZone
	local function getDistance(unit1, unit2)
		local tx, ty = GetPlayerMapPosition(unit1)
		local px, py = GetPlayerMapPosition(unit2)

		local dx, dy = (tx - px), (ty - py)
		local distance = (dx * dx + dy * dy) ^ 0.5

		return distance
	end

	local timer, last = nil, nil
	local function warnSwapTarget()
		local player = matterSwapTargets[1]
		if not player then
			mod:CancelTimer(timer)
			timer = nil
			return
		end

		SetMapToCurrentZone()
		local furthest, highestDistance = nil, 0
		for i=1, GetNumGroupMembers() do
			local unit = ("raid%d"):format(i)
			if UnitAffectingCombat(unit) and not UnitIsUnit(unit, player) then -- filter dead people and outside groups
				local distance = getDistance(unit, player)
				if distance > highestDistance then
					highestDistance = distance
					furthest = unit
				end
			end
		end

		if furthest and furthest ~= last then
			if GetRaidTargetIndex(furthest) ~= 2 then
				SetRaidTarget(furthest, 2)
			end
			if UnitIsUnit(furthest, "player") then
				mod:Message("matterswap", "Personal", "Info", L["matterswap_message"], L.matterswap_icon)
			end
			last = furthest
		end
	end

	function mod:MatterSwapApplied(args)
		if self:Me(args.destGUID) then
			self:Message(args.spellId, "Personal", "Info", CL["you"]:format(args.spellName))
			self:TargetBar(args.spellId, 12, args.destName)
			self:Flash(args.spellId)
			self:Say(args.spellId)
		elseif self:Dispeller("magic", nil, 138609) then
			self:TargetMessage(args.spellId, args.destName, "Important", "Alarm", nil, nil, true)
			self:TargetBar(args.spellId, 12, args.destName)
		end

		matterSwapTargets[#matterSwapTargets+1] = args.destName
		if GetRaidTargetIndex(matterSwapTargets[1]) ~= 6 then
			SetRaidTarget(matterSwapTargets[1], 6)
		end		

		last = nil
		if not timer and not self:LFR() and self.db.profile.matterswap > 0 then -- pretty wasteful to do the scanning if the option isn't on
			timer = self:ScheduleRepeatingTimer(warnSwapTarget, 0.5)
		end
	end

	function mod:MatterSwapRemoved(args)
		self:StopBar(args.spellId, args.destName)
		if GetRaidTargetIndex(args.destName) then
			SetRaidTarget(args.destName, 0)
		end		
		if args.destName == matterSwapTargets[1] then
			tremove(matterSwapTargets, 1)
			--[[if GetRaidTargetIndex(matterSwapTargets[1]) ~= 6 then -- mark next (if set)
				SetRaidTarget(matterSwapTargets[1], 6)
			end]]
		else -- dispeller ignored marks! (should only be two)
			tremove(matterSwapTargets, 2)
		end
	end
end

--------------------------------------------------------------------------------
-- Large Anima Golem
--

--[[do
	local prev = 0
	function mod:CrimsonWake(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(args.spellId)
		end
	end
end]]

function mod:CHAT_MSG_RAID_BOSS_WHISPER(_, msg, sender)
	if sender == self:SpellName(138485) then -- Crimson Wake
		self:Say(138485)
		self:Bar(138485, 30, CL["you"]:format(sender))
		self:DelayedMessage(138485, 30, "Positive", CL["over"]:format(sender))
		self:Message(138485, "Urgent", "Alarm", CL["you"]:format(sender))
		self:Flash(138485)
	end
end

