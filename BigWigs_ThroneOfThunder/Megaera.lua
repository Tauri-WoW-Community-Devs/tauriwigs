--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Megaera", 930, 821)
if not mod then return end
mod:RegisterEnableMob(70248, 70212, 70235, 70247, 68065) -- Arcane Head, Flaming Head, Frozen Head, Venomous Head, Megaera

--------------------------------------------------------------------------------
-- Locals
--

local breathCounter = 0
local headCounter = 0
local bossMarkerWarned = false
local killOrder25hc = {
	"|cFF0080FFFrost|r",
	"|cFFFF0404Fire|r",
	"|cFF9932CDArcane|r",
	"|cFF0080FFFrost|r",
	"|cFFFF0404Fire|r",
	"|cFF9932CDArcane|r",
	"|cFF0080FFFrost|r"
}
local gatherOrder25hc = {
	"|cFFFF0404Cross|r",
	"|cFF9932CDDiamond|r",
	"|cFF0080FFSquare|r",
	"|cFFFF0404Cross|r",
	"|cFF9932CDDiamond|r",
	"|cFF0080FFSquare|r"
}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.breaths = "Breaths"
	L.breaths_desc = "Warnings related to all the different types of breaths."
	L.breaths_icon = 105050

	L.killorder = "Kill Order"
	L.killorder_desc = "Worldmarkers, from left to right: %s%s%s"
	L.killorder_icon = "achievement_doublerainbow"

	L.arcane_adds = "Arcane adds"
	L.gather = "Gather"
	L.nextgather = "Next Gather"
	L.kill = "Kill"
end
L = mod:GetLocale()

L.killorder_desc = L.killorder_desc:format(
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_3.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_7.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_6.blp:15\124t"
)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		140138,
		{139822, "FLASH", "DISPEL", "SAY"}, {137731, "HEALER"},
		{139866, "FLASH", "SAY"}, {139909, "FLASH"}, {139843, "TANK"}, 
		{139840, "HEALER"},
		"killorder", 139458, {"breaths", "FLASH"}, --[["berserk",]] "bosskill",
	}, {
		[140138] = ("%s (%s)"):format(mod:SpellName(-7005), CL["heroic"]), -- Arcane Head
		[139822] = -6998, -- Fire Head
		[139866] = -7002, -- Frost Head
		[139840] = -7004, -- Poison Head
		["killorder"] = "general",
	}
end

function mod:OnBossEnable()
	local _, _, difficultyIndex = GetInstanceInfo()
	if not bossMarkerWarned and difficultyIndex == 6 then
		BigWigs:Print(L.killorder_desc)
		bossMarkerWarned = true
	end

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	-- Arcane
	self:Log("SPELL_CAST_SUCCESS", "NetherTear", 140138)
	-- Frost
	self:Log("SPELL_PERIODIC_DAMAGE", "IcyGround", 139909)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ArcticFreeze", 139843)
	-- Fire
	self:Log("SPELL_DAMAGE", "Cinders", 139836)
	self:Log("SPELL_AURA_APPLIED", "CindersApplied", 139822)
	self:Log("SPELL_AURA_REMOVED", "CindersRemoved", 139822)
	-- General
	self:Log("SPELL_DAMAGE", "BreathDamage", 137730, 139842, 139839, 139992)
	self:Log("SPELL_CAST_START", "Breaths", 137729, 139841, 139838, 139991)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "Rampage", "boss1")
	self:Log("SPELL_AURA_APPLIED", "TankDebuffApplied", 137731, 139840) -- Fire, Poison, should probably add Diffusion
	self:Log("SPELL_AURA_APPLIED_DOSE", "TankDebuffApplied", 137731, 139840)
	self:Log("SPELL_AURA_REMOVED", "TankDebuffRemoved", 137731, 139840)

	self:Death("Deaths", 70248, 70212, 70235, 70247) -- Arcane Head, Flaming Head, Frozen Head, Venomous Head
	self:Death("Win", 68065) -- Megaera
end

function mod:OnEngage()
	breathCounter = 0
	headCounter = 0
	self:Bar("breaths", 5, L["breaths"], L.breaths_icon)
	self:Message("breaths", "Attention", nil, CL["custom_start_s"]:format(self.displayName, L["breaths"], 5), false)
	self:RegisterEvent("UNIT_AURA")
	if self:Heroic() then
		self:Message("killorder", "Urgent", nil, ("%s: %s - %s: %s"):format(L["kill"], killOrder25hc[1], L["gather"], gatherOrder25hc[1]), L.killorder_icon)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

--------------------------------------------------------------------------------
-- General
--

function mod:TankDebuffApplied(args)
	--local tank = self:Tank(args.destName)
	--for i=1, 4 do
	--	local boss = ("boss%d"):format(i)
	--	if UnitDetailedThreatSituation(args.destName, boss) then
	--		tank = true
	--		break
	--	end
	--end
	--if tank then
	--	self:TargetBar(args.spellId, 45, args.destName)
	--end
end

function mod:TankDebuffRemoved(args)
	self:StopBar(args.spellId, args.destName)
end

do
	local prev = 0
	function mod:Breaths(args)
		local t = GetTime()
		if t-prev > 6 then
			prev = t
			breathCounter = breathCounter + 1
			self:Message("breaths", "Attention", nil, CL["count"]:format(L["breaths"], breathCounter), L.breaths_icon) -- neutral breath icon
			self:Bar("breaths", 16.5, L["breaths"], L.breaths_icon)
		end
	end
end

do
	local prev = 0
	function mod:BreathDamage(args)
		if not self:Me(args.destGUID) or self:Tank() then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message("breaths", "Personal", "Info", CL["you"]:format(args.spellName), args.spellId)
			self:Flash("breaths", args.spellId)
		end
	end
end

do
	local function rampageOver(spellId, spellName)
		mod:Message(spellId, "Positive", nil, CL["over"]:format(spellName))
		if mod:Heroic() then
			if headCounter < 6 then
				mod:Message("killorder", "Urgent", "Info", ("%s: %s"):format(L["nextgather"], gatherOrder25hc[headCounter+1]), L.killorder_icon)
			end
		end
	end
	function mod:Rampage(unit, spellName, _, _, spellId)
		if spellId == 139458 then
			self:Bar("breaths", 30, L["breaths"], L.breaths_icon)
			self:Message(spellId, "Important", "Long", CL["count"]:format(spellName, headCounter))
			self:Bar(spellId, 23, CL["count"]:format(spellName, headCounter))
			self:ScheduleTimer(rampageOver, 23, spellId, spellName)
			breathCounter = 0
		end
	end
end

function mod:Deaths(args)
	headCounter = headCounter + 1
	self:StopBar(L["breaths"])
	self:Message(139458, "Attention", nil, CL["soon"]:format(CL["count"]:format(self:SpellName(139458), headCounter))) -- Rampage
	self:Bar(139458, 8, CL["incoming"]:format(self:SpellName(139458)))
	if self:Heroic() then
		self:Message("killorder", "Urgent", "Info", ("%s: %s - %s: %s"):format(L["kill"], killOrder25hc[headCounter+1], L["gather"], gatherOrder25hc[headCounter]), L.killorder_icon)
	end
end

--------------------------------------------------------------------------------
-- Arcane Head
--

function mod:NetherTear(args)
	self:Message(args.spellId, "Urgent", "Alarm", L["arcane_adds"])
	self:Bar(args.spellId, 6, CL["cast"]:format(L["arcane_adds"])) -- this is to help so you know when all the adds have spawned
end

--------------------------------------------------------------------------------
-- Frost Head
--

do
	local prev = 0
	function mod:IcyGround(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(args.spellId)
		end
	end
end

do
	local iceTorrent, torrentList = mod:SpellName(139857), {}
	local UnitDebuff = UnitDebuff
	local function torrentOver(expires)
		torrentList[expires] = nil
	end
	function mod:UNIT_AURA(_, unit)
		local _, _, _, _, _, _, expires = UnitDebuff(unit, iceTorrent)
		if expires and not torrentList[expires] then
			local player, server = UnitName(unit)
			if server then player = player.."-"..server end
			if UnitIsUnit(unit, "player") then
				self:TargetMessage(139866, player, "Urgent", "Info")
				self:TargetBar(139866, 11 , player)
				self:Flash(139866)
				self:Say(139866)
			else
				self:TargetMessage(139866, player, "Urgent")
			end
			self:ScheduleTimer(torrentOver, 12, expires)
			torrentList[expires] = true
		end
	end
end

function mod:ArcticFreeze(args)
	if args.amount > 3 then
		self:StackMessage(args.spellId, args.destName, args.amount, "Urgent", "Warning")
	end
end

--------------------------------------------------------------------------------
-- Fire Head
--

do
	local prev = 0
	function mod:Cinders(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(139822, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(139822)
		end
	end
end

function mod:CindersApplied(args)
	if GetRaidTargetIndex(args.destName) ~= 2 then
		SetRaidTarget(args.destName, 2)
	end
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Personal", "Info", CL["you"]:format(args.spellName))
		self:TargetBar(args.spellId, 30, args.destName)
		self:Flash(args.spellId)
		self:Say(args.spellId)
	elseif self:Dispeller("magic", nil, args.spellId) then
		self:TargetMessage(args.spellId, args.destName, "Important", "Alarm", nil, nil, true)
		self:TargetBar(args.spellId, 30, args.destName)
	end
end

function mod:CindersRemoved(args)
	self:StopBar(args.spellId, args.destName)
	if GetRaidTargetIndex(args.destName) then
		SetRaidTarget(args.destName, 0)
	end
end

