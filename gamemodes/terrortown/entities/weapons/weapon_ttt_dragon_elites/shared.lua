--[[Author informations]]--
SWEP.Author = "Zaratusa"
SWEP.Contact = "http://steamcommunity.com/profiles/76561198032479768"

if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("639762141")
else
	LANG.AddToLanguage("english", "dragon_elites_name", "Dragon Elites")
	LANG.AddToLanguage("english", "dragon_elites_desc", "Dual Dragon Elites,\nwith one additional magazine.\n\nGet the Style.")

	SWEP.PrintName = "dragon_elites_name"
	SWEP.Slot = 1
	SWEP.Icon = "vgui/ttt/icon_dragon_elites"

	-- client side model settings
	SWEP.UseHands = true -- should the hands be displayed
	SWEP.ViewModelFlip = false -- should the weapon be hold with the left or the right hand
	SWEP.ViewModelFOV = 74

	-- equipment menu information is only needed on the client
	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "dragon_elites_desc"
	}
end

-- always derive from weapon_tttbase
SWEP.Base = "weapon_tttbase"

--[[Default GMod values]]--
SWEP.Primary.Ammo = "pistol"
SWEP.Primary.Delay = 0.1
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Cone = 0.025
SWEP.Primary.Damage = 22
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 30
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Sound = Sound("Dragon_Elite.Single")

SWEP.HeadshotMultiplier = 2.97

--[[Model settings]]--
SWEP.HoldType = "duel"
SWEP.ViewModel = Model("models/weapons/zaratusa/dragon_elites/v_dragon_elites.mdl")
SWEP.WorldModel = Model("models/weapons/zaratusa/dragon_elites/w_dragon_elites.mdl")

--[[TTT config values]]--

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_PISTOL

-- If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2,
-- then this gun can be spawned as a random weapon.
SWEP.AutoSpawnable = false

-- The AmmoEnt is the ammo entity that can be picked up when carrying this gun.
SWEP.AmmoEnt = "item_ammo_pistol_ttt"

-- CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
-- a role is in this table, those players can buy this.
SWEP.CanBuy = { ROLE_DETECTIVE, ROLE_TRAITOR }

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = true

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true

-- If IsSilent is true, victims will not scream upon death.
SWEP.IsSilent = false

-- If NoSights is true, the weapon won't have ironsights
SWEP.NoSights = true

function SWEP:Initialize()
	if (CLIENT and self:Clip1() == -1) then
		self:SetClip1(self.Primary.DefaultClip)
	elseif (SERVER) then
		self.fingerprints = {}
		self:SetIronsights(false)
		-- aditional magazine, seems to be bugged, when using DefaultClip
		timer.Simple(0.1, function() if (IsValid(self:GetOwner())) then self:GetOwner():GiveAmmo(30, "pistol", false) end end)
	end

	self:SetDeploySpeed(self.DeploySpeed)

	-- compat for gmod update
	if (self.SetHoldType) then
		self:SetHoldType(self.HoldType or "pistol")
	end

	PrecacheParticleSystem("smoke_trail")

	self.LastShot = 0
	self.AnimateRight = true
	self:SetNWInt("ShotsFired", 0)

	timer.Create("DragonElitesSmokeTrail", 0.5, 0, function()
		if (IsValid(self)) then
			local diff = CurTime() - self.LastShot
			local shotsfired = self:GetNWInt("ShotsFired")
			if (diff > 1.25 and shotsfired > math.Rand(5, 7)) then
				if (IsValid(self:GetOwner()) and self:GetOwner():GetActiveWeapon() == self) then
					local viewmodel = self:GetOwner():GetViewModel()
					ParticleEffectAttach("smoke_trail", PATTACH_POINT_FOLLOW, viewmodel, 1)
					ParticleEffectAttach("smoke_trail", PATTACH_POINT_FOLLOW, viewmodel, 2)
					self:SetNWInt("ShotsFired", 0)
				end
			elseif (diff > 5 and shotsfired < 8) then
				self:SetNWInt("ShotsFired", 0)
			end
		end
	end)
end

function SWEP:PrimaryAttack()
	if (self:CanPrimaryAttack()) then
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
		self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

		local owner = self:GetOwner()
		owner:GetViewModel():StopParticles()

		if SERVER then
			sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
		end

		self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())
		self:SetNWInt("ShotsFired", self:GetNWInt("ShotsFired") + 1)
		self.LastShot = CurTime()
		self:TakePrimaryAmmo(1)

		if (IsValid(owner) and !owner:IsNPC() and owner.ViewPunch) then
			owner:ViewPunch(Angle(math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) * self.Primary.Recoil, 0))
		end
	end
end

-- just a slightly modified version of the weapon_tttbase
local sparkle = CLIENT and CreateConVar("ttt_crazy_sparks", "0", FCVAR_ARCHIVE)
function SWEP:ShootBullet(dmg, recoil, numbul, cone)
	self:ShootEffects()

	if (IsFirstTimePredicted()) then
		local sights = self:GetIronsights()

		numbul = numbul or 1
		cone = cone or 0.01

		local bullet = {}
		bullet.Num = numbul
		bullet.Src = self:GetOwner():GetShootPos()
		bullet.Dir = self:GetOwner():GetAimVector()
		bullet.Spread = Vector( cone, cone, 0 )
		bullet.Tracer = 4
		bullet.TracerName = self.Tracer or "Tracer"
		bullet.Force = 10
		bullet.Damage = dmg
		if CLIENT and sparkle:GetBool() then
			bullet.Callback = Sparklies
		end

		self:GetOwner():FireBullets(bullet)

		-- owner can die after firebullets
		if (IsValid(self:GetOwner()) and self:GetOwner():Alive() and (!self:GetOwner():IsNPC())
			and ((game.SinglePlayer() and SERVER)
				or ((!game.SinglePlayer()) and CLIENT and IsFirstTimePredicted()))) then
			-- reduce recoil if ironsighting
			recoil = sights and (recoil * 0.6) or recoil

			local eyeang = self:GetOwner():EyeAngles()
			eyeang.pitch = eyeang.pitch - recoil
			self:GetOwner():SetEyeAngles(eyeang)
		end
	end
end

-- just a slightly modified version of the weapon_tttbase
function SWEP:ShootEffects()
	local sequence
	if self.AnimateRight then
		if (CurTime() - self.LastShot > 0.3) then
			sequence = "shoot_right1"
		else
			sequence = "shoot_right2"
		end
	else
		if (CurTime() - self.LastShot > 0.3) then
			sequence = "shoot_left1"
		else
			sequence = "shoot_left2"
		end
	end

	local viewModel = self:GetOwner():GetViewModel()
	viewModel:ResetSequence(viewModel:LookupSequence(sequence))
	self.AnimateRight = !self.AnimateRight

	self:GetOwner():MuzzleFlash()
	self:GetOwner():SetAnimation(PLAYER_ATTACK1)
end

function SWEP:Reload()
	if (self:Clip1() < self.Primary.ClipSize and self:GetOwner():GetAmmoCount(self.Primary.Ammo) > 0) then
		self:DefaultReload(ACT_VM_RELOAD)
		timer.Simple(0.2, function() if (IsValid(self) and IsValid(self:GetOwner())) then self:GetOwner():GetViewModel():StopParticles() end end)
	end
end

function SWEP:Deploy()
	self:SetNWInt("ShotsFired", 0)
	return true
end

function SWEP:Holster()
	if (IsValid(self:GetOwner())) then
		local vm = self:GetOwner():GetViewModel()
		if (IsValid(vm)) then
			vm:StopParticles()
		end
	end
	return true
end

function SWEP:OnRemove()
	timer.Remove("DragonElitesSmokeTrail")
end
