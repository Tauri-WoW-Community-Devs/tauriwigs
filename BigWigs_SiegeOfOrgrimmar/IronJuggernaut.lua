--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Iron Juggernaut", 953, 864)
if not mod then return end
mod:RegisterEnableMob(71466)

--------------------------------------------------------------------------------
-- Locals
--

local phase = 1
local pull = 1
local cutter = 1
local tar = 1
-- marking
local markableMobs = {}
local marksUsed = {}
local markTimer = nil
local mineCounter = 1
local shockPulseCounter = 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.custom_off_mine_marks = "Mine marker"
	L.custom_off_mine_marks_desc = "To help soaking assignments, mark the Crawler Mines with {rt1}{rt2}{rt3}, requires promoted or leader.\n|cFFFF0000Only 1 person in the raid should have this enabled to prevent marking conflicts.|r\n|cFFADFF2FTIP: If the raid has chosen you to turn this on, quickly mousing over all the mines is the fastest way to mark them.|r"
	L.custom_off_mine_marks_icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		-8181,
		{-8179, "FLASH"}, {144467, "TANK_HEALER"}, -- Assault mode
		144485, {-8190, "FLASH", "ICON"}, {144498, "FLASH"}, -- Siege mode
		"custom_off_mine_marks",
		"stages", -8183, "berserk", "bosskill",
	}, {
		[-8181] = "heroic",
		[-8179] = -8177,
		[144485] = -8178,
		["custom_off_mine_marks"] = L.custom_off_mine_marks,
		["stages"] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Log("SPELL_CAST_SUCCESS", "MineArming", 144718) -- Detonation Sequence
	-- Siege mode
	self:Log("SPELL_PERIODIC_DAMAGE", "ExplosiveTar", 144498)
	self:Log("SPELL_AURA_REMOVED", "CutterLaserRemoved", 146325)
	self:Log("SPELL_AURA_APPLIED", "CutterLaserApplied", 146325)
	self:Log("SPELL_CAST_START", "ShockPulse", 144485)
	-- Assault mode
	self:Log("SPELL_AURA_APPLIED", "IgniteArmor", 144467)
	self:Log("SPELL_AURA_APPLIED_DOSE", "IgniteArmor", 144467)
	self:Log("SPELL_DAMAGE", "BorerDrill", 144218)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1")
end

function mod:OnEngage()
	self:Berserk(self:Heroic() and 450 or 600)
	phase = 1
	pull = 1
	cutter = 1
	tar = 1
	if self.db.profile.custom_off_mine_marks then
		wipe(markableMobs)
		wipe(marksUsed)
		markTimer = nil
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local function setMark(unit, guid)
		for mark = 1, 3 do
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
		if not continue or not mod.db.profile.custom_off_mine_marks then
			mod:CancelTimer(markTimer)
			markTimer = nil
		end
	end

	function mod:UPDATE_MOUSEOVER_UNIT()
		local guid = UnitGUID("mouseover")
		if guid then
			if markableMobs[guid] == true then
				setMark("mouseover", guid)
			elseif not markableMobs[guid] and self:MobId(guid) == 72050 then
				markableMobs[guid] = true
				setMark("mouseover", guid)
			end
		end
	end

	function mod:MineArming(args)
		if not markableMobs[args.sourceGUID] then
			markableMobs[args.sourceGUID] = true
			if self.db.profile.custom_off_mine_marks and not markTimer then
				markTimer = self:ScheduleRepeatingTimer(markMobs, 0.1)
			end
		end
	end

	function mod:ResetMarking()
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:CancelTimer(markTimer)
		markTimer = nil
		wipe(markableMobs)
		wipe(marksUsed)
	end
end

-- Siege mode
do
	local prev = 0
	function mod:ExplosiveTar(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(144498, "Personal", "Info", CL.underyou:format(args.spellName))
			self:Flash(144498)
		end
	end
end

function mod:CutterLaserRemoved(args)
	self:PrimaryIcon(-8190)
end

function mod:CutterLaserApplied(args)
	-- way too varied timer 11-21 HIGI: 24, 23, 10
	cutter = cutter+1
	if cutter == 2 then
		self:Bar(-8190, 23)
	elseif cutter == 3 then
		self:Bar(-8190, 10)
	end

	self:TargetMessage(-8190, args.destName, "Important", "Warning")
	self:PrimaryIcon(-8190, args.destName)
	if self:Me(args.destGUID) then
		self:Flash(-8190)
	end
end

function mod:ShockPulse(args)
	self:Message(args.spellId, "Attention", "Alert", CL.count:format(args.spellName, shockPulseCounter))
	shockPulseCounter = shockPulseCounter + 1
	if shockPulseCounter < 4 then
		self:Bar(args.spellId, 17, CL.count:format(args.spellName, shockPulseCounter))
	end
end

-- Assault mode
function mod:IgniteArmor(args) -- 144464 castid
	self:StackMessage(args.spellId, args.destName, args.amount, "Attention")
	self:CDBar(args.spellId, 10.2)
end

do
	local prev = 0
	function mod:BorerDrill(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(-8179, "Personal", "Info", CL.underyou:format(args.spellName))
			self:Flash(-8179)
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(unitId, spellName, _, _, spellId)
	if spellId == 144296 then -- Borer Drill
		self:Message(-8179, "Attention")
		self:CDBar(-8179, 17.4)
	elseif spellId == 144673 then -- Crawler Mine
		self:Message(-8183, "Urgent", nil, CL.count:format(spellName, mineCounter))
		self:Bar(-8183, 17, 144718) -- 48732 = Mine Explosion?
		mineCounter = mineCounter + 1
		if phase == 1 then
			if mineCounter < 4 then -- 3 casts per P1
				if mineCounter == 2 then
					self:Bar(-8183, 31, CL.count:format(spellName, mineCounter))
				else
					self:Bar(-8183, 30, CL.count:format(spellName, mineCounter))
				end
			end
		else
			if mineCounter < 3 then -- 2 casts per P2
				if self:Heroic() then
					self:Bar(-8183, 24, CL.count:format(spellName, mineCounter))
				else
					self:Bar(-8183, 34, CL.count:format(spellName, mineCounter))
				end
			end
		end
		if self.db.profile.custom_off_mine_marks then
			self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
			self:ScheduleTimer("ResetMarking", 18) -- cast time is 15, we should be safe with 18
		end
	elseif spellId == 144492 then -- Explosive Tar
		self:Message(144498, "Attention")
		tar = tar+1
		if tar == 2 then
			self:Bar(144498, 30)
		end
	elseif spellId == 146359 then -- Regeneration (Assault mode)
		phase = 1
		self:Message("stages", "Neutral", "Long", CL.phase:format(phase), false)
		if pull == 1 then
			self:Bar("stages", 121, CL.phase:format(2), 144498)
		else
			self:Bar("stages", 117, CL.phase:format(2), 144498)
		end
		self:StopBar(CL.count:format(self:SpellName(144673), mineCounter)) -- Crawler Mine
		mineCounter = 1
		self:Bar(-8183, 30, CL.count:format(self:SpellName(144673), mineCounter)) -- Crawler Mine

		if pull == 1 then
			self:CDBar(-8179, 17.4) -- Borer Drill
			self:CDBar(144467, 9.5) -- Ignite Armor
			if self:Heroic() then
				self:CDBar(-8181, 15.2) -- Ricochet
			end
		else
			self:CDBar(144467, 8.5) -- Ignite Armor
		end
		self:StopBar(144498) -- Explosive Tar
		pull = 0
	elseif spellId == 146360 then -- Depletion (Siege mode)
		phase = 2
		self:Message("stages", "Neutral", "Long", CL.phase:format(phase), false)
		self:Bar("stages", 60.5, CL.phase:format(1), 144464)
		mineCounter = 1
		shockPulseCounter = 1
		cutter = 1
		tar = 1
		self:Bar(-8190, 24) -- Laser Cutter
		self:CDBar(-8183, 24, CL.count:format(self:SpellName(144673), mineCounter)) -- Crawler Mine
		self:Bar(144485, 15.8, CL.count:format(self:SpellName(144485), shockPulseCounter)) -- Shock Pulse, 15 - 15.8
		self:Bar(144498, 7) -- Explosive Tar
		self:StopBar(-8179) -- Borer Drill
		self:StopBar(-8181) -- Ricochet
		self:StopBar(144467) -- Ignite Armor
	elseif spellId == 144356 then -- Ricochet
		self:Message(-8181, "Attention")
		self:CDBar(-8181, 16) -- 15-20s
	end
end