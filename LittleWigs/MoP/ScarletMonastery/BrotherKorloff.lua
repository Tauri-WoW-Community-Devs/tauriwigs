--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Brother Korloff", 874, 671)
if not mod then return end
mod:RegisterEnableMob(59223)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "I will break you."

	L.fists, L.fists_desc = EJ_GetSectionInfo(5601)
	L.fists_icon = 114807

	L.firestorm, L.firestorm_desc = EJ_GetSectionInfo(5602)
	L.firestorm_icon = 113764
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {"fists", 114460, "firestorm", "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "BlazingFists", 114807)
	self:Log("SPELL_CAST_SUCCESS", "FirestormKick", 113764)

	self:Log("SPELL_DAMAGE", "ScorchedEarthYou", 114465)
	self:Log("SPELL_MISSED", "ScorchedEarthYou", 114465)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 59223)
end

function mod:OnEngage()
	self:Bar("firestorm", 10, L["firestorm"], 113764)
	self:Bar("fists", 20, L["fists"], 114807)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BlazingFists(args)
	self:Message("fists", "Urgent", "Alert", args.spellId)
	self:Bar("fists", 6, CL["cast"]:format(args.spellName), args.spellId)
	self:Bar("fists", 30, args.spellId)
end

function mod:ScorchedEarthYou(args)
	if self:Me(args.destGUID) then
		self:Message(114460, "Personal", "Alarm", CL["underyou"]:format(args.spellName))
		self:Flash(114460)
	end
end

function mod:FirestormKick(args)
	self:Message("firestorm", "Attention", nil, args.spellId)
	self:Bar("firestorm", 6, CL["cast"]:format(args.spellName), args.spellId)
	self:Bar("firestorm", 25.2, args.spellId)
end