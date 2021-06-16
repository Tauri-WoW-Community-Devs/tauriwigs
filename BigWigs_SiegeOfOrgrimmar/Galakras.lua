
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Galakras", 953, 868)
if not mod then return end
mod:RegisterEnableMob(
	72249, 72358, -- Galakras, Kor'kron Cannon
	72560, 72561, 73909, -- Horde: Lor'themar Theron, Lady Sylvanas Windrunner, Archmage Aethas Sunreaver
	72311, 72302, 73910 -- Alliance: King Varian Wrynn, Lady Jaina Proudmoore, Vereesa Windrunner
)
mod.engageId = 1622

--------------------------------------------------------------------------------
-- Locals
--

local towerAddTimer = nil
local addsCounter = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.start_trigger_horde = "I see the Dragonmaw have thrown in their lot with Garrosh."

	L.demolisher, L.demolisher_desc = EJ_GetSectionInfo(8533)
	L.demolisher_message = "Demolisher"
	L.demolisher_icon = 125914

	L.towers = "Towers"
	L.towers_desc = "Warnings for when the towers are breached."
	L.towers_icon = "achievement_bg_winsoa"
	L.south_tower_trigger = "The door barring the South Tower has been breached!"
	L.south_tower = "South Tower"
	L.north_tower_trigger = "The door barring the North Tower has been breached!"
	L.north_tower = "North Tower"
	L.tower_defender = "Tower defender"

	L.adds = CL.adds
	L.adds_desc = "Timers for when a new set of adds enter the fight."
	L.adds_icon = "achievement_character_orc_female" -- female since Zaela is calling them (and to be not the same as tower add icon)
	L.warlord_zaela = "Warlord Zaela"

	L.drakes = "Proto-Drakes"
	L.drakes_desc = select(2, EJ_GetSectionInfo(8586))
	L.drakes_icon = "ability_mount_drake_proto"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"towers", 146848, 146849, 147705, 146868, 147711, -- Ranking Officials
		"adds", "drakes", "demolisher", 147328, 146765, 146757, 146753, 146899, -- Foot Soldiers
		{147068, "ICON", "FLASH", "SAY"}, 147042, -- Galakras
		"stages", {"warmup", "EMPHASIZE"}, "bosskill",
	}, {
		["towers"] = -8421, -- Ranking Officials
		["adds"] = -8427, -- Foot Soldiers
		[147068] = -8418, -- Galakras
		["stages"] = "general",
	}
end

function mod:OnBossEnable()
	if self.lastKill and (GetTime() - self.lastKill) < 120 then -- Temp for outdated users enabling us
		self:ScheduleTimer("Disable", 5)
		return
	end

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")
	self:RegisterEvent("CHAT_MSG_MONSTER_SAY", "Warmup")
	-- Foot Soldiers
	self:Log("SPELL_CAST_START", "ChainHeal", 146757, 146728)
	self:Log("SPELL_CAST_SUCCESS", "HealingTotem", 146753, 146722)
	self:Log("SPELL_PERIODIC_DAMAGE", "FlameArrows", 146765)
	self:Log("SPELL_DAMAGE", "FlameArrows", 146764)
	self:Log("SPELL_AURA_APPLIED", "FlameArrows", 146765)
	self:Log("SPELL_AURA_APPLIED", "Warbanner", 147328)
	self:Log("SPELL_AURA_APPLIED", "Fracture", 146899, 147200)
	self:Emote("Demolisher", "116040")
	-- Ranking Officials
	self:Log("SPELL_AURA_APPLIED", "CurseofVenom", 147711)
	self:Log("SPELL_PERIODIC_DAMAGE", "PoisonCloud", 147705)
	self:Log("SPELL_AURA_APPLIED", "PoisonCloud", 147705)
	self:Log("SPELL_CAST_START", "SkullCracker", 146848)
	self:Log("SPELL_CAST_START", "ShadowAssault", 146868)
	self:Log("SPELL_CAST_SUCCESS", "ShatteringCleave", 146849)
	self:Emote("SouthTower", L.south_tower_trigger)
	self:Emote("NorthTower", L.north_tower_trigger)
	-- Galakras
	self:Log("SPELL_AURA_APPLIED_DOSE", "FlamesOfGalakrondStacking", 147029)
	self:Log("SPELL_AURA_APPLIED", "FlamesOfGalakrondApplied", 147068)
	self:Log("SPELL_AURA_REMOVED", "FlamesOfGalakrondRemoved", 147068)
	self:Log("SPELL_AURA_APPLIED", "PulsingFlamesApplied", 147042)
	self:Log("SPELL_AURA_REMOVED", "PulsingFlamesRemoved", 147042)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "LastPhase", "boss1", "boss2", "boss3", "boss4")

	self:Death("Deaths", 72355) -- High Enforcer Thranok
	self:Death("Win", 72249) -- Galakras
end

local function warnTowerAdds()
	mod:Message("towers", "Attention", nil, L.tower_defender, 85214)
	mod:Bar("towers", 60, L.tower_defender, 85214) -- random orc icon
end

local function firstTowerAdd()
	warnTowerAdds()
	if not towerAddTimer then
		towerAddTimer = mod:ScheduleRepeatingTimer(warnTowerAdds, 60)
	end
end

--"<9.6 19:50:12> [CHAT_MSG_MONSTER_SAY] CHAT_MSG_MONSTER_SAY#I see the Dragonmaw have thrown in their lot with Garrosh.#Lady Sylvanas Windrunner###Lor'themar Theron##0#0##0#2284#nil#0#false#false", -- [84]
--"<36.3 19:50:39> [INSTANCE_ENCOUNTER_ENGAGE_UNIT] Fake Args:#1#1#Lady Sylvanas Windrunner#0xF1311B71000014D3#elite#87227400#nil#nil#nil#nil#nil#normal#0#nil#nil#nil#nil#nil#normal#0#nil#nil#nil#nil#nil#normal#0#nil#nil#nil#nil#nil#normal#0#nil#Real Args:", -- [354]
--"<37.1 19:50:39> [PLAYER_REGEN_DISABLED]  ++ > Regen Disabled : Entering combat! ++ > ", -- [363]

function mod:Warmup(_, msg)
	if msg == L.start_trigger_horde then
		self:Bar("warmup", 26.7, COMBAT, "achievement_boss_galakras")
	end
end

function mod:OnEngage()
	if self:Heroic() then
		self:Bar("towers", 6, L.tower_defender, 85214) -- random orc icon
		self:ScheduleTimer(firstTowerAdd, 6)
	else
		self:Bar("towers", 116, L.south_tower, L.towers_icon)
	end

	addsCounter = 0
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Adds")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

--Galakras
function mod:FlamesOfGalakrondStacking(args)
	if args.amount > 2 then
		if self:Me(args.destGUID) or (self:Tank() and self:Tank(args.destName)) then
			self:StackMessage(147068, args.destName, args.amount, "Attention", nil, 71393, args.spellId) -- 71393 = "Flames"
		end
	end
end

function mod:FlamesOfGalakrondRemoved(args)
	self:PrimaryIcon(args.spellId)
end

function mod:FlamesOfGalakrondApplied(args)
	self:PrimaryIcon(args.spellId, args.destName)
	if self:Me(args.destGUID) then
		self:Flash(args.spellId)
		self:Message(args.spellId, "Personal", "Warning", CL.you:format(args.spellName))
		self:Say(args.spellId)
	end
	self:Bar(args.spellId, 6.1)
end

function mod:PulsingFlamesApplied(args)
	self:Message(args.spellId, "Urgent", "Alert")
	self:Bar(args.spellId, 7, CL.cast:format(args.spellName))
end

function mod:PulsingFlamesRemoved(args)
	self:CDBar(args.spellId, 17)
end

function mod:LastPhase(unitId, _, _, _, spellId)
	if spellId == 50630 then -- Eject All Passengers
		self:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
		self:Message("stages", "Neutral", "Warning", CL.incoming:format(UnitName(unitId)), "ability_mount_drake_proto")
		self:CDBar(147042, 38)
		self:CDBar(147068, 13.6)
		self:StopBar(L.adds)
		self:StopBar(L.drakes)
		self:CancelDelayedMessage(CL.incoming:format(L.drakes))
	end
end

-- Ranking Officials
do
	local prev = 0
	function mod:PoisonCloud(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL.underyou:format(args.spellName))
		end
	end
end

function mod:CurseofVenom(args)
	self:Message(args.spellId, "Attention")
end

do
	local prev = 0
	function mod:ShadowAssault(args)
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Urgent", "Alert")
		end
	end
end

function mod:SkullCracker(args)
	self:Bar(args.spellId, 30.4)
	self:Bar(args.spellId, 2, CL.cast:format(args.spellName))
	self:Message(args.spellId, "Urgent", "Alert")
end

function mod:ShatteringCleave(args)
	self:Bar(args.spellId, 7)
end

function mod:Demolisher()
	self:Message("demolisher", "Attention", nil, L.demolisher_message, L.demolisher_icon)
end

function mod:SouthTower()
	self:StopBar(L.south_tower)
	self:Message("towers", "Neutral", "Long", L.south_tower, L.towers_icon)
	self:Bar("demolisher", 20, L.demolisher_message, L.demolisher_icon)

	if self:Heroic() then
		self:CancelTimer(towerAddTimer)
		towerAddTimer = nil
		self:Bar("towers", 35, L.tower_defender, 85214) -- random orc icon
		self:ScheduleTimer(firstTowerAdd, 35)
	else
		self:Bar("towers", 150, L.north_tower, L.towers_icon) -- XXX verify
	end
end

function mod:NorthTower()
	self:StopBar(L.north_tower)
	self:Message("towers", "Neutral", "Long", L.north_tower, L.towers_icon)
	self:Bar("demolisher", 20, L.demolisher_message, L.demolisher_icon)

	if self:Heroic() then
		self:CancelTimer(towerAddTimer)
		towerAddTimer = nil
		self:StopBar(L.tower_defender)
	end
end

-- Foot Soldiers
function mod:ChainHeal(args)
	self:Message(146757, "Important", "Warning")
end

function mod:HealingTotem(args)
	self:Message(146753, "Important", "Warning", args.spellName, 143474) -- Better totem icon
end

do
	local prev = 0
	function mod:FlameArrows(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Personal", nil, CL.underyou:format(args.spellName))
		end
	end
end

function mod:Warbanner(args)
	self:Message(args.spellId, "Urgent")
end

function mod:Fracture(args)
	self:TargetMessage(146899, args.destName, "Urgent", "Alert", nil, nil, true)
end

function mod:Adds(_, _, unit, _, _, target)
	if unit == L.warlord_zaela then
		if addsCounter == 0 then
			self:Bar("adds", 59, L.adds, L.adds_icon)
			self:Bar("drakes", 168, L.drakes, L.drakes_icon)
			addsCounter = 1
		elseif UnitIsPlayer(target) then
			self:Message("adds", "Attention", "Info", CL.incoming:format(L.adds), L.adds_icon)
			addsCounter = addsCounter + 1
			if (addsCounter + 1) % 4  == 0 then
				self:DelayedMessage("drakes", 55, "Attention", CL.incoming:format(L.drakes), L.drakes_icon, "Info")
				self:Bar("adds", 110, L.adds, L.adds_icon)
			else
				if addsCounter % 4 == 0 then -- start the drakes timer on the wave after drakes
					self:Bar("drakes", 220, L.drakes, L.drakes_icon)
				end
				self:Bar("adds", 55, L.adds, L.adds_icon)
			end
		end
	end
end

function mod:Deaths(args)
	if args.mobId == 72355 then -- High Enforcer Thranok
		self:StopBar(self:SpellName(146848)) -- Skull Cracker
		self:StopBar(self:SpellName(146849)) -- Shattering Cleave
	end
end

