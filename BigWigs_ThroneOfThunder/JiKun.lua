--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Ji-Kun", 930, 828)
if not mod then return end
mod:RegisterEnableMob(69712) -- Ji-Kun

--------------------------------------------------------------------------------
-- Locals
--

local bossMarkerWarned = false
local nestCounter = 1
local quillCounter = 0
local nests25hc = {
	"|cFFFFFF01Down|r", --yellow
	"|cFF0080FFDown|r[#]", --blue
	"|cFFFF0404Down|r", --red
	"|cFF9932CDDown|r - |cFFFFFF01Up|r", --purple, yellow
	"|cFF088A08Down|r[#] - |cFF0080FFUp|r", --green, blue
	"|cFF9932CDUp|r", --purple
	"|cFFFFFF01Down|r - |cFFFF0404Up|r", --yellow, red
	"|cFF0080FFDown|r - |cFF088A08Up|r[#]", --blue, green
	"|cFFFF0404Down|r", --red
	"|cFF9932CDDown|r - |cFFFFFF01Up|r", --purple, yellow
	"|cFF088A08Down|r - |cFF0080FFUp|r[#]", --green, blue
	"|cFFFFFF01Down|r - |cFF9932CDUp|r", --yellow, purple
	"|cFF0080FFDown|r - |cFFFF0404Up|r", --blue, red
	"|cFFFF0404Down|r[#] - |cFF088A08Up|r - |cFFFFFF01Up|r", --red, green, yellow
	"|cFF9932CDDown|r - |cFF0080FFUp|r", --purple, blue
	"|cFF088A08Down|r - |cFFFFFF01Down|r - |cFF9932CDUp|r", --green, yellow, purple
	"|cFF0080FFDown|r - |cFFFF0404Up|r", --blue, red [should be an add on this wave]
	"|cFFFF0404Down|r - |cFF088A08Up|r - |cFFFFFF01Up|r" --red, green, yellow
}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.lower_hatch_trigger = "The eggs in one of the lower nests begin to hatch!"
	L.upper_hatch_trigger = "The eggs in one of the upper nests begin to hatch!"

	L.nests = "Nests"
	L.nests_desc = "Worldmarkers, clockwise starting from northeast (1st): %s%s%s%s%s"

	L.flight_over = "Flight over in %d sec!"
	L.upper_nest = "|cff008000Upper|r nest"
	L.lower_nest = "|cffff0000Lower|r nest"
	L.up = "|cff008000UP|r"
	L.down = "|cffff0000DOWN|r"
	L.add = "Add"
	L.big_add_message = "Big add at %s"
end
L = mod:GetLocale()

L.nests_desc = L.nests_desc:format(
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_6.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_7.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_3.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_4.blp:15\124t"
)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"nests",
		{-7360, "FLASH"}, {140741, "FLASH"}, 137528,
		{134366, "TANK_HEALER"}, {134380, "FLASH"}, 134370, 138923,
		--[["berserk",]] "bosskill",
	}, {
		["nests"] = -7348,
		[134366] = "general",
	}
end

function mod:OnBossEnable()
	local _, _, difficultyIndex = GetInstanceInfo()
	if not bossMarkerWarned and difficultyIndex == 6 then
		BigWigs:Print(L.nests_desc)
		bossMarkerWarned = true
	end

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Log("SPELL_AURA_APPLIED", "FeedYoung", 137528)
	self:Log("SPELL_AURA_APPLIED", "PrimalNutriment", 140741)
	self:Log("SPELL_AURA_APPLIED", "Flight", 133755)
	self:Log("SPELL_CAST_START", "Caw", 138923)
	self:Log("SPELL_CAST_START", "DownDraft", 134370)
	self:Log("SPELL_CAST_START", "Quills", 134380)
	self:Log("SPELL_AURA_APPLIED", "TalonRake", 134366)
	self:Log("SPELL_AURA_APPLIED_DOSE", "TalonRake", 134366)
	
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")

	self:Death("Win", 69712)
end

function mod:OnEngage(diff)
	--self:Berserk(600) -- XXX assumed
	self:Bar(134380, (diff == 4 or diff == 6) and 42.3 or 60) -- Quills	
	self:Bar(134370, 91) -- Down Draft
	self:CDBar(138923, 18) -- Caw
	self:CDBar(134366, 24.2) -- Talon Rake
	nestCounter = 1
	quillCounter = 0
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FeedYoung(args)
	self:Message(args.spellId, "Positive", "Info")
	if diff == 6 or diff == 4 then
		self:CDBar(args.spellId, 30)
	else
		self:CDBar(args.spellId, 40)
	end
end

function mod:Caw(args)
	self:Message(args.spellId, "Attention", nil, CL["incoming"]:format(args.spellName)) -- no z-axis info for range check to ignore for nest people :\
	self:CDBar(args.spellId, 18) -- 18-30s
end

do
	local prev = 0
	function mod:CHAT_MSG_MONSTER_EMOTE(_, msg)
		if not msg:find(L["upper_hatch_trigger"], nil, true) and not msg:find(L["lower_hatch_trigger"], nil, true) then return end

		local diff = self:Difficulty()
		if diff == 6 then -- 25 H
			local t = GetTime()
			if t-prev > 2 then
				prev = t
				self:Message("nests", "Urgent", "Alert", ("[%d] %s"):format(nestCounter, (nests25hc[nestCounter] or "Nests")), "ability_eyeoftheowl")
				nestCounter = nestCounter + 1
				if nestCounter == 2 then
					self:Bar("nests", 27, ("[%d] %s"):format(nestCounter, (nests25hc[nestCounter] or "Nests")), "ability_eyeoftheowl")
				else
					self:Bar("nests", 60, ("[%d] %s"):format(nestCounter, (nests25hc[nestCounter] or "Nests")), "ability_eyeoftheowl")
				end
			end
		else
			local color, text, icon
			if msg:find(L["upper_hatch_trigger"]) then
				color = "Attention"
				text = CL["count"]:format(L["upper_nest"], nestCounter)
				icon = "misc_arrowlup"
			else
				color = "Urgent"
				text = CL["count"]:format(L["lower_nest"], nestCounter)
				icon = "misc_arrowdown"
			end

			-- one message for 10h nests with a guardian
			if diff == 5 and (nestCounter == 2 or nestCounter == 4 or nestCounter == 8 or nestCounter == 12) then
				text = L["big_add_message"]:format(text)
			end
			self:Message("nests", color, "Alert", text, icon) -- XXX keep this here till all the nest rotations are 100% figured out

			local nextNest = nestCounter + 1
			if diff == 7 then -- LFR
				-- first 3 lower, second 3 upper
				if nestCounter % 6 > 2 then
					self:Bar("nests", 40, ("(%d) %s"):format(nextNest, L["upper_nest"]), "misc_arrowlup")
				else
					self:Bar("nests", 40, ("(%d) %s"):format(nextNest, L["lower_nest"]), "misc_arrowdown")
				end
			elseif diff == 3 then -- 10 N
				-- first 3 lower, second 3 upper with 9/10 and 15/16 happening at the same time
				if nestCounter == 8 or nestCounter == 14 then -- up and down at same time
					self:Bar("nests", 40, ("(%d) %s + (%d) %s"):format(nextNest, L["up"], nextNest+1, L["down"]), 134347)
				elseif nestCounter == 9 or nestCounter == 15 then
					-- no bar for second of double nests
				elseif nestCounter % 6 > 2 then
						self:Bar("nests", 40, ("(%d) %s"):format(nextNest, L["upper_nest"]), "misc_arrowlup")
				else
					self:Bar("nests", 40, ("(%d) %s"):format(nextNest, L["lower_nest"]), "misc_arrowdown")
				end
			elseif diff == 5 then -- 10 H
				-- first 3 lower, second 3 upper with 9/10 and 15/16 happening at the same time
				-- big adds at 2, 4, 12
				if nestCounter == 2 or nestCounter == 6 or nestCounter == 12 or nestCounter == 13 then
					self:Bar("nests", 40, ("(%d) %s"):format(nextNest, L["lower_nest"]), "misc_arrowdown")
				elseif nestCounter == 4 or nestCounter == 5 or nestCounter == 10 or nestCounter == 16 or nestCounter == 17 then
					self:Bar("nests", 40, ("(%d) %s"):format(nextNest, L["upper_nest"]), "misc_arrowlup")
				elseif nestCounter == 8 or nestCounter == 14 then -- up and down at same time 
					self:Bar("nests", 40, ("(%d) %s + (%d) %s"):format(nextNest, L["up"], nextNest+1, L["down"]), 134347)		
				elseif nestCounter == 1 or nestCounter == 7 then
					self:Bar("nests", 40, ("(%d) %s (%s)"):format(nextNest, L["lower_nest"], L["add"]), "misc_arrowdown")
				elseif nestCounter == 3 or nestCounter == 11 then
					self:Bar("nests", 40, ("(%d) %s (%s)"):format(nextNest, L["upper_nest"], L["add"]), "misc_arrowlup")
				end
			elseif diff == 4 then -- 25 N
				-- 1 lower, 2 lower, 3 lower, 4 lower, 5 {lower, 6 upper}, 7 upper, 8 upper, 9 {lower, 10 upper}, 11 {lower, 12 upper}, 13 lower, 14 lower, 15 {lower, 16 upper},
				-- 17 upper, 18 {lower, 19 upper}, 20 {lower, 21 upper}, 22 {lower, 23 upper}, 24 lower, 25 {lower, 26 upper}, 27 {lower, 28 upper}
				if nestCounter % 28 < 4 or nestCounter % 28 == 12 or nestCounter % 28 == 13 or nestCounter % 28 == 23 then
					self:Bar("nests", 30, ("(%d) %s"):format(nextNest, L["lower_nest"]), "misc_arrowdown")
				elseif nestCounter % 28 == 4 or nestCounter % 28 == 8 or nestCounter % 28 == 10 or nestCounter % 28 == 14 or nestCounter % 28 == 17 or nestCounter % 28 == 19 or nestCounter % 28 == 21 or nestCounter % 28 == 24 or nestCounter % 28 == 26 then -- up and down at same time
					self:Bar("nests", 30, ("(%d)%s+(%d)%s"):format(nextNest, L["down"], nextNest+1, L["up"]), 134347)
				elseif nestCounter % 28 == 6 or nestCounter % 28 == 7 or nestCounter % 28 == 16 then
					self:Bar("nests", 30, ("(%d) %s"):format(nextNest, L["upper_nest"]), "misc_arrowlup")
				end
			end
			nestCounter = nestCounter + 1
		end
	end
end

function mod:PrimalNutriment(args)
	if not self:Me(args.destGUID) then return end
	self:Flash(args.spellId)
	self:Message(args.spellId, "Positive")
	self:Bar(args.spellId, 30, CL["you"]:format(args.spellName))
end

do
	local function flightMessage(remainingTime)
		mod:Message(-7360, "Personal", remainingTime < 5 and "Info", L["flight_over"]:format(remainingTime), 133755)
	end
	function mod:Flight(args)
		if not self:Me(args.destGUID) then return end
		self:ScheduleTimer(flightMessage, 5, 5)
		self:ScheduleTimer(flightMessage, 8, 2)
		self:ScheduleTimer(flightMessage, 9, 1) -- A bit of spam, but it is necessary!
		self:ScheduleTimer("Flash", 8, -7360)
		self:Bar(-7360, 10)
	end
end

function mod:DownDraft(args)
	self:Message(args.spellId, "Important", "Long")
	self:Bar(args.spellId, 10, CL["cast"]:format(args.spellName))
	self:Bar(args.spellId, 91)
end

function mod:Quills(args)
	self:Message(args.spellId, "Important", "Warning")
	self:Bar(args.spellId, 10, CL["cast"]:format(args.spellName))
	self:Flash(args.spellId)
	local diff = self:Difficulty()
	quillCounter = quillCounter + 1
	if diff == 4 or diff == 6 then -- 25 N/H
		self:Bar(args.spellId, 63)
	else -- 10 N/H + LFR
		if quillCounter == 4 then
			self:Bar(args.spellId, 91)
		elseif quillCounter > 6 then
			self:Bar(args.spellId, 44) -- soft enrage it looks like
		else
			self:Bar(args.spellId, 81)
		end
	end
end

function mod:TalonRake(args)
	self:StackMessage(args.spellId, args.destName, args.amount, "Urgent", "Info")
	self:CDBar(args.spellId, 20.9)
end

