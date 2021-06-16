--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Iron Qon", 930, 817)
if not mod then return end
mod:RegisterEnableMob(68078, 68079, 68080, 68081) -- Iron Qon, Ro'shak, Quet'zal, Dam'ren

--------------------------------------------------------------------------------
-- Locals
--
local UnitDebuff = UnitDebuff
local arcingLightning = {}
local openedForMe = nil
local phaseno = 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.molten_energy = "Molten Energy"
	L.molten_energy_desc = EJ_GetSectionInfo(6973)
	L.molten_energy_icon = 137221

	L.overload_casting = "Molten Overload casting"
	L.overload_casting_desc = "Warning for when Molten Overload is casting"
	L.overload_casting_icon = 137221

	L.arcing_lightning_cleared = "Raid is clear of Arcing Lightning"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		-6914, 136520, 139180, 135145,
		-6877, {137669, "FLASH"}, {136192, "ICON", "PROXIMITY", "SAY"}, 77333,
		137221, "overload_casting", {-6870, "PROXIMITY"}, -6871, {137668, "FLASH"},
		134926, {134691, "TANK_HEALER"}, "molten_energy", {-6917, "FLASH"}, "berserk", "bosskill",
	}, {
		[-6914] = -6867, -- Dam'ren
		[-6877] = -6866, -- Quet'zal
		[137221] = -6865, -- Ro'shak
		[134926] = "general",
	}
end

function mod:OnBossEnable()
	-- Dam'ren
	self:Log("SPELL_AURA_APPLIED", "Freeze", 135145)
	self:Log("SPELL_DAMAGE", "FrozenBlood", 136520)
	self:Log("SPELL_CAST_SUCCESS", "DeadZone", 137226, 137227, 137228, 137229, 137230, 137231) -- figure out why it has so many spellIds
	-- Quet'zal
	self:Log("SPELL_AURA_REMOVED", "ArcingLightningRemoved", 136193)
	self:Log("SPELL_AURA_APPLIED", "ArcingLightningApplied", 136193)
	self:Log("SPELL_AURA_APPLIED", "LightningStormApplied", 136192)
	self:Log("SPELL_AURA_REMOVED", "LightningStormRemoved", 136192)
	self:Log("SPELL_DAMAGE", "StormCloud", 137669)
	self:Log("SPELL_AURA_APPLIED", "Windstorm", 136577)
	-- Ro'shak
	self:Log("SPELL_DAMAGE", "BurningCinders", 137668)
	self:Log("SPELL_AURA_APPLIED", "Scorched", 134647)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Scorched", 134647)
	self:Log("SPELL_AURA_APPLIED", "MoltenOverloadApplied", 137221)
	self:Log("SPELL_AURA_REMOVED", "MoltenOverloadRemoved", 137221)
	-- General
	self:Log("SPELL_SUMMON", "ThrowSpear", 134926)
	self:Log("SPELL_AURA_APPLIED", "Impale", 134691)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Impale", 134691)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1", "boss2", "boss3", "boss4")

	self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", nil, "boss1", "boss2", "boss3", "boss4") -- spam to detect phase switch

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Deaths", 68078, 68079, 68080, 68081)
end

--"<0.7 13:15:54> [INSTANCE_ENCOUNTER_ENGAGE_UNIT] Fake Args:#nil#1#Unknown#0xF15109EE000020F5#worldboss#467102720#1#1#Ro'shak#0xF15109EF000020F4#elite#490538878#nil#nil#nil#nil#normal#0#nil#nil#nil#nil#normal#0#nil#nil#nil#nil#normal#0#Real Args:", -- [61]
--"<18.1 13:16:11> [BigWigs_Message] BigWigs_Message#BigWigs_Bosses_Iron Qon#77333#Whirling Winds#Attention#nil#Interface\\Icons\\Spell_Nature_Cyclone", -- [6282]
--"<21.8 13:16:15> [UNIT_SPELLCAST_SUCCEEDED] Ro'shak [[boss2:Arcing Lightning::0:139106]]", -- [7917]
--"<32.2 13:16:25> [CLEU] SPELL_SUMMON#false#0xF15109EE000020F5#Iron Qon#2632#0#0xF1310B800000224F#Iron Qon's Spear#2600#0#134926#Throw Spear#1", -- [11951]
--"<52.1 13:16:45> [UNIT_SPELLCAST_SUCCEEDED] Ro'shak [[boss2:Whirling Winds::0:139172]]", -- [18389]

function mod:OnEngage()
	openedForMe = nil
	self:Berserk(720)
	self:RegisterUnitEvent("UNIT_POWER_FREQUENT", "PowerWarn", "boss2")
	self:CDBar(134926, 31) -- Throw spear
	wipe(arcingLightning)
	if self:Heroic() then
		self:Bar(77333, 19) -- Whirling Winds
		self:Bar(136192, 24) -- Arcing Lightning
	end
	self:Bar(134691, 20) -- Impale
	phaseno = 1
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function closeLightningStormProximity()
	for i=1, GetNumGroupMembers() do
		local name = GetRaidRosterInfo(i)
		if UnitDebuff(name, mod:SpellName(136193)) then -- don't close the proximity if someone can spread the debuff
			return
		end
	end
	mod:CloseProximity(136192)
	mod:Message(136192, "Positive", nil, L["arcing_lightning_cleared"])
end

-- Dam'ren

function mod:Freeze(args)
	local _, _, _, _, _, duration = UnitDebuff(args.destName, args.spellName)
	self:Bar(args.spellId, duration) -- so people can use personal cooldowns for when the damage happens
end

do
	local prev = 0
	function mod:FrozenBlood(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(args.spellId)
		end
	end
end

function mod:DeadZone(args)
	self:Message(-6914, "Attention")
	self:Bar(-6914, 16)
end

-- Quet'zal

function mod:ArcingLightningRemoved(args)
	for i, v in next, arcingLightning do
		if v == args.destName then
			tremove(arcingLightning, i)
			break
		end
	end
	if self:Me(args.destGUID) then
		openedForMe = nil
	end
	if not openedForMe then
		self:OpenProximity(136192, 12, arcingLightning)
	end
	closeLightningStormProximity()
end

function mod:ArcingLightningApplied(args)
	if self:Me(args.destGUID) then
		openedForMe = true
		self:OpenProximity(136192, 12)
	else
		arcingLightning[#arcingLightning+1] = args.destName
		if not openedForMe then
			self:OpenProximity(136192, 12, arcingLightning)
		end
	end
end

function mod:LightningStormApplied(args)
	self:PrimaryIcon(args.spellId, args.destName)
	self:TargetMessage(args.spellId, args.destName, "Urgent") -- no point for sound since the guy stunned can't do anything
	if phaseno == 1 then -- Ro'shak is there aka Heroic p1 then 40 (47 hali) else 20
		self:Bar(args.spellId, 47) 
	else
		if self:Heroic() then
			self:Bar(args.spellId, 20)
		else
			self:Bar(args.spellId, 40)
		end
	end
	if self:Me(args.destGUID) then
		self:Say(args.spellId)
	end
end

function mod:LightningStormRemoved(args)
	self:PrimaryIcon(args.spellId)
end

do
	local prev = 0
	function mod:StormCloud(args)
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
	local prev = 0
	function mod:Windstorm(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 20 then
			prev = t
			self:Message(-6877, "Attention") -- lets leave it here to warn people who fail and step back into the windstorm
			self:Bar(-6877, 20, CL["cast"]:format(args.spellName))
			self:StopBar(136192) -- stop lightning storm
			self:StopBar(134926) -- stop throw
			self:StopBar(134691) -- stop impale
			self:StopBar(139180) -- stop frost spike
		end
	end
end

-- Ro'shak

do
	local prev = 0
	function mod:BurningCinders(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 2 then
			prev = t
			self:Message(args.spellId, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(args.spellId)
		end
	end
end

function mod:Scorched(args)
	if self:Me(args.destGUID) then
		self:Message(-6871, "Important", nil, CL["count"]:format(args.spellName, args.amount or 1))
	end
	if self:Heroic() and self:MobId(UnitGUID("boss4")) == 68081 then -- Dam'ren is active and heroic
		self:Bar(-6870, 33) -- Unleashed Flame
	else
		self:CDBar(-6870, 6) -- this is good so people know how much time they have to gather/spread
	end
end

do
	local prevPower = 0
	function mod:MoltenOverloadRemoved()
		prevPower = 0
		self:RegisterUnitEvent("UNIT_POWER_FREQUENT", "PowerWarn", "boss2")
	end
	function mod:PowerWarn(unitId)
		local power = UnitPower(unitId)
		if power > 64 and prevPower == 0 then
			prevPower = 65
			self:Message("molten_energy", "Attention", nil, ("%s (%d%%)"):format(L["molten_energy"], power), L.molten_energy_icon)
		elseif power > 74 and prevPower == 65 then
			prevPower = 75
			self:Message("molten_energy", "Urgent", nil, ("%s (%d%%)"):format(L["molten_energy"], power), L.molten_energy_icon)
		elseif power > 84 and prevPower == 75 then
			prevPower = 85
			self:Message("molten_energy", "Important", nil, ("%s (%d%%)"):format(L["molten_energy"], power), L.molten_energy_icon)
		elseif power > 94 and prevPower == 85 then
			prevPower = 95
			self:Message("molten_energy", "Important", nil, ("%s (%d%%)"):format(L["molten_energy"], power), L.molten_energy_icon)
		end
	end
end

function mod:MoltenOverloadApplied(args)
	self:Message("overload_casting", "Important", "Alert", args.spellId)
	self:Bar("overload_casting", 10, CL["cast"]:format(args.spellName), args.spellId) -- XXX don't think there is any point to this, maybe coordinating raid cooldowns?
	self:UnregisterUnitEvent("UNIT_POWER_FREQUENT", "boss2")
end

-- General

function mod:UNIT_SPELLCAST_SUCCEEDED(unit, spellName, _, _, spellId)
	if spellId == 139172 then -- Whirling Wind
		self:Message(77333, "Attention")
		self:Bar(77333, 30.3)
	elseif spellId == 139181 then -- Frost Spike
		self:Message(139180, "Attention")
		self:CDBar(139180, 15)
	elseif spellId == 137656 then -- Rushing Winds - start Wind Storm bar here, should be more accurate then unitaura on player
		self:Message(-6877, "Positive", nil, CL["over"]:format(self:SpellName(136577)), 136577) -- Wind Storm -- XXX This fires when Quet'zal dies, should maybe try prevent that, sadly this happens before UNIT_DIED or ENGAGE with nil
		self:Bar(-6877, 70) -- Wind Storm

		self:Bar(134926, 15) -- start spear throw ?????? nice scripting guys
		self:Bar(136192, 15) -- start lightning storm
		self:Bar(134691, 14) -- start impale
	elseif spellId == 50630 then -- Eject All Passangers aka heroic phase change
		if unit == "boss2" then -- Ro'shak
			self:UnregisterUnitEvent("UNIT_POWER_FREQUENT", "boss2")
			self:StopBar(137221) -- Molten Overload
			self:StopBar(134628) -- Unleashed Flame
			self:Bar(-6877, 50) -- Windstorm
			self:Bar(136192, 17) -- Arcing Lightning -- XXX not sure if it has to be restarted here for heroic
			self:OpenProximity(136192, 12) -- Lightning Storm -- assume 10 (use 12 to be safe)
			self:StopBar(77333) -- Whirling Wind
		elseif unit == "boss3" then
			self:StopBar(-6877) -- Windstorm
			self:StopBar(136192) -- Arcing Lightning
			closeLightningStormProximity()
			self:Bar(-6914, 7) -- Dead Zone
			self:StopBar(139180) -- Frost Spike
			self:CDBar(-6870, 17)
		elseif unit == "boss3" then
			--last phase heroic
			self:StopBar(134628) -- Unleashed Flame
			self:StopBar(-6914) -- Dead zone
			self:OpenProximity(136192, 12) -- Lightning Storm -- assume 10 (use 12 to be safe)
			self:Bar(-6917, 30) -- Fist Smash
		end
	--elseif spellId == 136147 then -- Fist Smash (146 is real id...)
		--self:Message(-6917, "Urgent", "Alarm")
		--self:Bar(-6917, 7.5, CL["cast"]:format(spellName))
		--self:Flash(-6917)
		--if self:Heroic() then
			--self:Bar(-6917, 28.8)
		--else
			--self:Bar(-6917, 20)
		--end
	end
end

--"<456.8 15:46:11> [UNIT_SPELLCAST_SUCCEEDED] Dam'ren [[boss4:Eject All Passengers::0:50630]]", -- [105871]
--

--"<520.3 15:47:15> [UNIT_SPELLCAST_SUCCEEDED] Iron Qon [[boss1:Fist Smash::0:136146]]", -- [127358]
--"<549.1 15:47:43> [UNIT_SPELLCAST_SUCCEEDED] Iron Qon [[boss1:Fist Smash::0:136146]]", -- [136364]
--"<578.2 15:48:12> [UNIT_SPELLCAST_SUCCEEDED] Iron Qon [[boss1:Fist Smash::0:136146]]", -- [140844]

function mod:Impale(args)
	self:StackMessage(args.spellId, args.destName, args.amount, "Positive")
	self:CDBar(args.spellId, 20)
end

function mod:ThrowSpear(args)
	--if not UnitExists("boss1") then -- don't warn in last phase
		if phaseno == 4 or phaseno == 5 then
			self:Message(-6917, "Urgent", "Alarm")
			self:Bar(-6917, 11, CL["cast"]:format("Fist Smash"))
			self:Flash(-6917)
			if self:Heroic() then
				self:Bar(-6917, 24)
			else
				self:Bar(-6917, 20)
			end
		else
			self:CDBar(args.spellId, 31)
			self:Message(args.spellId, "Urgent")
		end
	--end
end

function mod:UNIT_HEALTH_FREQUENT(unitId)
	if self:Heroic() then
		local hp = UnitHealth(unitId) / UnitHealthMax(unitId) * 100
		--SendChatMessage("HP Update: "..hp.." PHASE: "..phaseno, "RAID")
		if phaseno == 1 and unitId == "boss3" and hp > 90 then -- detect quetzal high hp
			--SendChatMessage("QUETZAL ACTIVE", "RAID")
			phaseno = 2
			self:StopBar(77333) --no more whirling wind
			self:Bar(-6877, 52.5) -- Windstorm
			self:StopBar(136192) -- cancel potential lightning storm
			self:Bar(136192, 17.5) -- restart lightning storm
			self:CDBar(139180, 15) -- frost spike start
		end
		if phaseno == 2 and unitId == "boss4" and hp > 90 then -- detect damren high hp
			--SendChatMessage("DAMREN ACTIVE", "RAID")
			phaseno = 3
			self:StopBar(-6877) -- stop Windstorm if present
			self:StopBar(136192) -- cancel lightning storm
			self:Bar(-6870, 18) -- Unleashed Flame first
			self:Bar(-6914, 15) -- Dead Zone first
			self:StopBar(139180) -- stop potential frost spike
			self:CDBar(139180, 15) -- frost spike start
		end
		if phaseno == 3 and unitId == "boss4" and hp <= 25 then -- detect damren 25%or less - P4: DAMREN GOES TO BOSS1, ROSHAK GOES TO BOSS3 - LITERALLY WHY
			--SendChatMessage("ALL DOGGIES", "RAID")
			phaseno = 4
			self:StopBar(-6870) -- cancel unleashed flame
			self:StopBar(134926) -- cancel throw spear
			self:Bar(136192, 24) -- restart Lightning Storm
			self:StopBar(137221) -- Molten Overload
			self:UnregisterUnitEvent("UNIT_POWER_FREQUENT", "boss2")
			self:Bar(-6917, 63) -- Fist Smash seems to start 1min after p4 start
		end
	end
end

function mod:Deaths(args)
	if phaseno == 4 then
		--SendChatMessage("doggie did a died", "RAID")
		phaseno = 5
	end
	if args.mobId == 68079 and not self:Heroic() then -- Ro'shak
		phaseno = 2
		self:UnregisterUnitEvent("UNIT_POWER_FREQUENT", "boss2")
		self:StopBar(137221) -- Molten Overload
		self:StopBar(134628) -- Unleashed Flame
		self:Bar(-6877, 54) -- Windstorm
		self:Bar(136192, 18.5) -- Arcing Lightning
		self:OpenProximity(136192, 12) -- Lightning Storm -- assume 10 (use 12 to be safe)
	elseif args.mobId == 68080 then -- Quet'zal
		if not self:Heroic() then
			phaseno = 3
			self:StopBar(-6877) -- Windstorm
			self:StopBar(136192) -- Arcing Lightning
			self:Bar(-6914, 17) -- Dead Zone
		else
			self:StopBar(136192) -- Arcing Lightning
		end
		closeLightningStormProximity()
	elseif args.mobId == 68081 then -- Dam'ren
		self:StopBar(-6914) -- Dead zone
		self:StopBar(134926) -- spear throw
		if not self:Heroic() then
			phaseno = 4
			self:Bar(-6917, 23) -- Fist Smash
		end
	elseif args.mobId == 68078 then -- Iron Qon
		self:Win()
	end
end

