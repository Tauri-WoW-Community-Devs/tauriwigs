--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Rattlegore", 898, 665)
if not mod then return end
mod:RegisterEnableMob(59153)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.engage_yell = "RATTLEGORE!"

	L.no_bone_armor = "NO Bone Armor!"
end
L = mod:GetLocale()

local function warnBoneArmor(spellName)
	if UnitDebuff("player", spellName) or not UnitAffectingCombat("player") then
		mod:CancelTimer(armorTimer)
		armorTimer = nil
	else
		mod:Message(113996, "Personal", "Info", L["no_bone_armor"])
	end
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {{113996, "FLASH"}, 114009, "bosskill"}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_REMOVED", "BoneArmorRemoved", 113996)
	self:Log("SPELL_DAMAGE", "Soulflame", 114009)

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	self:Death("Win", 59153)
end

function mod:OnEngage()
	armorTimer = self:ScheduleRepeatingTimer(warnBoneArmor, 3, self:SpellName(113996))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BoneArmorRemoved(args)
	self:Flash(args.spellId)
	armorTimer = self:ScheduleRepeatingTimer(warnBoneArmor, 3, args.spellName)
end

do
	local prev = 0
	function mod:Soulflame(args)
		if not self:Me(args.destGUID) then return end
		local t = GetTime()
		if t-prev > 1 then
			prev = t
			self:Message(114009, "Personal", "Info", CL["underyou"]:format(args.spellName))
			self:Flash(114009)
		end
	end
end