
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Siegecrafter Blackfuse", 953, 865)
if not mod then return end
mod:RegisterEnableMob(71504)

--------------------------------------------------------------------------------
-- Locals
--

local overloadCounter = 1
local assemblyLineCounter = 1
local assemblyLineKillOrder25hc = {
	"|cFFFF801AMissile|r", -- [1]
	"|cFF808080Mines|r", -- [2]
	"|cFFFF801AMissile|r", -- [3]
	"|cFF808080Mines|r", -- [4]
	"|cFF3366FFMagnet|r", -- [5]
	"|cFFFF0000Laser|r", -- [6]
	"|cFF808080Mines|r", -- [7]
	"|cFF808080Mines|r", -- [8]
	"|cFFFF0000Laser|r", -- [9]
	"|cFF808080Mines|r", -- [10]
	"|cFFFF801AMissile|r", -- [11]
	"|cFF808080Mines|r" -- [12]
}
local sawbladeTarget

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.overcharged_crawler_mine = "Overcharged Crawler Mine" -- sadly this is needed since they have same mobId
	L.disabled = "Disabled"
	L.shredder_engage_trigger = "An Automated Shredder draws near!"

	L.assembly_line_trigger = "Unfinished weapons begin to roll out on the assembly line."
	L.belt = "Belt"		
	L.kill = "Kill"
	L.boss = "Blackfuse"
	L.item_missile = "Missile"
	L.item_mines = "Mines"
	L.item_laser = "Laser"
	L.item_magnet = "Magnet"
	L.item_deathdealer = "Deathdealer"

	L.shockwave_missile_trigger = "Presenting... the beautiful new ST-03 Shockwave missile turret!"

	L.belt_odd = "Odd Belt Group"
	L.belt_odd_desc = "Show warnings for the odd belt groups. (1,3,5...)"
	--L.belt_odd_icon = "Inv_crate_03"
	L.belt_even = "Even Belt Group"
	L.belt_even_desc = "Show warnings for the even belt groups. (2,4,6...)"
	--L.belt_even_icon = "Inv_crate_03"
end
L = mod:GetLocale()

local itemNames = {
	[71606] = L.item_missile, -- Deactivated Missile Turret
	[71790] = L.item_mines, -- Disassembled Crawler Mines
	[71751] = L.item_laser, -- Deactivated Laser Turret
	[71694] = L.item_magnet, -- Deactivated Electromagnet
	[72904] = L.item_deathdealer, -- Deactivated Deathdealer Turret
	[71638] = L.item_missile, -- Activated Missile Turret
	[71795] = L.item_mines, -- Activated Crawler Mine Vehicle
	[71752] = L.item_laser, -- Activated Laser Turret
	[71696] = L.item_magnet, -- Activated Electromagnet
	[72905] = L.item_deathdealer, -- Activated Deathdealer Turret
}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		-8408,
		{-8195, "FLASH", "SAY", "ICON"}, {145365, "TANK_HEALER"}, {143385, "TANK"}, -- Siegecrafter Blackfuse
		-8199, 144208, 145444, -- Automated Shredders
		-8202, -8207, 143639, {-8208, "FLASH", "SAY"}, 143856, 144466, {-8212, "FLASH"}, "belt_odd", "belt_even",
		"berserk", "bosskill",
	}, {
		[-8408] = "heroic",
		[-8195] = -8194, -- Siegecrafter Blackfuse
		[-8199] = -8199, -- Automated Shredders
		[-8202] = -8202, -- The Assembly Line
		["berserk"] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	-- heroic
	self:Log("SPELL_CAST_SUCCESS", "Overcharge", 145774)
	-- The Assembly Line
	self:Emote("AssemblyLine", L.assembly_line_trigger)
	--self:Log("SPELL_AURA_APPLIED", "CrawlerMine", 145269)
	self:Log("SPELL_AURA_APPLIED", "MagneticCrush", 144466)
	self:Log("SPELL_AURA_APPLIED", "Superheated", 143856)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Superheated", 143856)
	self:RegisterEvent("RAID_BOSS_WHISPER")
	self:Yell("ShockwaveMissile", L.shockwave_missile_trigger)
	self:Log("SPELL_AURA_APPLIED", "ShockwaveMissileOver", 143639)
	self:Log("SPELL_AURA_APPLIED", "PatternRecognitionApplied", 144236)
	self:Log("SPELL_AURA_REMOVED", "PatternRecognitionRemoved", 144236)
	-- Automated Shredders
	self:Emote("ShredderEngage", L.shredder_engage_trigger)
	self:Log("SPELL_CAST_START", "DeathFromAbove", 144208)
	self:Log("SPELL_CAST_START", "DeathFromAboveApplied", 144210)
	self:Log("SPELL_CAST_SUCCESS", "Overload", 145444)
	-- Siegecrafter Blackfuse
	self:Log("SPELL_CAST_SUCCESS", "ElectrostaticCharge", 143385)
	self:Log("SPELL_AURA_APPLIED", "ElectrostaticChargeApplied", 143385)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ElectrostaticChargeApplied", 143385)
	self:Log("SPELL_AURA_APPLIED", "ProtectiveFrenzy", 145365)
	self:Log("SPELL_CAST_START", "Sawblade", 143265)
	self:Log("SPELL_CAST_SUCCESS", "SawbladeFallback", 143265)

	self:Death("ShredderDied", 71591)
	self:Death("Win", 71504)
end

function mod:OnEngage()
	self:Berserk(self:Heroic() and 540 or 600)
	assemblyLineCounter = 1
	overloadCounter = 1
	self:Bar(-8199, 35, nil, "INV_MISC_ARMORKIT_27") -- Shredder Engage
	self:CDBar(-8195, 9) -- Sawblade
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Overcharge(args)
	local mobId = self:MobId(args.destGUID)
	self:Message(-8408, "Important", nil, CL.other:format(args.spellName, itemNames[mobId]), false)

end
-- The Assembly Line

function mod:AssemblyLine()
	if assemblyLineCounter % 2 == 0 then
		self:Message("belt_even", "Neutral", "Warning", ("[%d] %s - %s: %s"):format(assemblyLineCounter, L["belt"], L["kill"], assemblyLineKillOrder25hc[assemblyLineCounter] or L["boss"]), "Inv_crate_03")
		self:Bar("belt_odd", 39.8, ("[%d] %s - %s: %s"):format(assemblyLineCounter+1, L.belt, L.kill, assemblyLineKillOrder25hc[assemblyLineCounter+1] or L.boss), "Inv_crate_03")
	else
		self:Message("belt_odd", "Neutral", "Warning", ("[%d] %s - %s: %s"):format(assemblyLineCounter, L["belt"], L["kill"], assemblyLineKillOrder25hc[assemblyLineCounter] or L["boss"]), "Inv_crate_03")
		self:Bar("belt_even", 39.8, ("[%d] %s - %s: %s"):format(assemblyLineCounter+1, L.belt, L.kill, assemblyLineKillOrder25hc[assemblyLineCounter+1] or L.boss), "Inv_crate_03")
	end
	assemblyLineCounter = assemblyLineCounter + 1
end

--[[function mod:AssemblyLine()
	self:Message(-8202, "Neutral", "Warning", ("[%d] %s - %s: %s"):format(assemblyLineCounter, L["belt"], L["kill"], assemblyLineKillOrder25hc[assemblyLineCounter] or L["boss"]), "Inv_crate_03")
	assemblyLineCounter = assemblyLineCounter + 1
	self:Bar(-8202, 39.8, ("[%d] %s - %s: %s"):format(assemblyLineCounter, L.belt, L.kill, assemblyLineKillOrder25hc[assemblyLineCounter] or L.boss), "Inv_crate_03")
end]]

--[[do
	local prev = 0
	function mod:CrawlerMine(args)
		local t = GetTime()
		if t-prev > 5 then
			prev = t
			self:Message(-8212, "Urgent", nil, -8212, 77976)
		end
	end
end]]

do
	local prev = 0
	function mod:MagneticCrush(args)
		local t = GetTime()
		if t-prev > 15 then
			prev = t
			self:Message(args.spellId, "Important", "Long")
		end
	end
end

function mod:Superheated(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Personal", "Info", CL.underyou:format(args.spellName))
	end
end

function mod:RAID_BOSS_WHISPER(_, msg, sender)
	if msg:find("Ability_Siege_Engineer_Superheated") then -- laser fixate
		-- might wanna do syncing to get range message working
		self:Message(-8208, "Personal", "Info", CL.you:format(EJ_GetSectionInfo(8208)), 144040)
		self:Flash(-8208)
		self:Say(-8208)
	elseif msg:find("Ability_Siege_Engineer_Detonate") then -- mine fixate
		self:Message(-8212, "Personal", "Info", CL.you:format(sender))
		self:Flash(-8212)
	elseif msg:find("143266") then -- Sawblade
		-- this is faster than target scanning, hence why we do it
		sawbladeTarget = UnitGUID("player")
		self:Message(-8195, "Positive", "Info", CL.you:format(self:SpellName(143266)))
		self:PrimaryIcon(-8195, "player")
		self:Flash(-8195)
		self:Say(-8195)
	end
end

function mod:ShockwaveMissile()
	self:Message(143639, "Urgent")
end

function mod:ShockwaveMissileOver(args)
	self:Message(args.spellId, "Urgent", nil, CL.over:format(args.spellName))
end

function mod:PatternRecognitionApplied(args)
	if self:Me(args.destGUID) then
		self:Bar(-8207, 60)
	end
end

function mod:PatternRecognitionRemoved(args)
	if self:Me(args.destGUID) then
		self:Message(-8207, "Positive", CL.over:format(args.spellName))
	end
end

-- Automated Shredders

function mod:ShredderEngage()
	self:Message(-8199, "Attention", self:Tank() and "Long", nil, "INV_MISC_ARMORKIT_27")
	self:Bar(-8199, 60, nil, "INV_MISC_ARMORKIT_27")
	self:Bar(144208, 16) -- Death from Above
	self:CDBar(145444, 7, ("[%d] %s"):format(overloadCounter, self:SpellName(145444))) -- Overload
end

function mod:DeathFromAboveApplied(args)
	self:Message(args.spellId, "Attention", "Alert")
end

function mod:DeathFromAbove(args)
	self:Message(args.spellId, "Attention", nil, CL.casting:format(args.spellName))
	self:Bar(args.spellId, 41)
end

function mod:Overload(args)
	self:Message(args.spellId, "Positive", nil, ("[%d] %s"):format(overloadCounter, args.spellName))
	overloadCounter = overloadCounter + 1
	self:CDBar(args.spellId, 10.8, ("[%d] %s"):format(overloadCounter, args.spellName))
end

function mod:ShredderDied()
	self:StopBar(144208) -- Death from Above
	self:StopBar(("[%d] %s"):format(overloadCounter, self:SpellName(145444))) --overload
	overloadCounter = 1
end

-- Siegecrafter Blackfuse

function mod:ElectrostaticCharge(args)
	self:CDBar(args.spellId, 17)
end

function mod:ElectrostaticChargeApplied(args)
	if UnitIsPlayer(args.destName) then -- Shows up for pets, etc.
		self:StackMessage(args.spellId, args.destName, args.amount, "Attention", "Info")
	end
end

function mod:ProtectiveFrenzy(args)
	self:Message(args.spellId, "Attention", "Long")
	for i=1, 5 do
		local boss = "boss"..i
		if UnitExists(boss) and UnitIsDead(boss) then
			local mobId = self:MobId(UnitGUID(boss))
			self:Message(-8202, "Positive", nil, CL.other:format(L.disabled, itemNames[mobId]), false)
		end
	end
end

do
	-- rather do this than syncing
	local timer = nil
	local function warnSawblade(self, target, guid)
		sawbladeTarget = guid
		self:PrimaryIcon(-8195, target)
		if not self:Me(guid) then -- we warn for ourself from the BOSS_WHISPER
			self:TargetMessage(-8195, target, "Positive", "Info")
		end
	end
	function mod:Sawblade(args)
		self:CDBar(-8195, 11)
		sawbladeTarget = nil
		self:GetBossTarget(warnSawblade, 0.4, args.sourceGUID)
	end
	function mod:SawbladeFallback(args)
		 -- don't do anything if we warned for the target already
		if args.destGUID ~= sawbladeTarget then
			warnSawblade(self, args.destName, args.destGUID)
		end
	end
end

