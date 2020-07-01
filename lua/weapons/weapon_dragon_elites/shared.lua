--- Author informations ---
SWEP.Author = "Zaratusa"
SWEP.Contact = "http://steamcommunity.com/profiles/76561198032479768"

if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("639762141")
else
	SWEP.PrintName = "Dragon Elites"
	SWEP.Slot = 1
end

--- Default GMod values ---
SWEP.Base = "weapon_base"
SWEP.Category = "Counter-Strike: Source"
SWEP.Purpose = "A nice Dual Elite modification."
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.Primary.Ammo = "pistol"
SWEP.Primary.Delay = 0.1
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Cone = 0.025
SWEP.Primary.Damage = 22
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 30
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 60
SWEP.Primary.Sound = Sound("Dragon_Elite.Single")

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1

SWEP.DeploySpeed = 1.4
SWEP.HeadshotMultiplier = 2.97

--- Model settings ---
SWEP.HoldType = "duel"

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 74
SWEP.ViewModel = Model("models/weapons/zaratusa/dragon_elites/v_dragon_elites.mdl")
SWEP.WorldModel = Model("models/weapons/zaratusa/dragon_elites/w_dragon_elites.mdl")

function SWEP:Initialize()
	self:SetDeploySpeed(self.DeploySpeed)

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
			sound.Play(self.Primary.Sound, self:GetPos())
		end

		self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self.Primary.Cone)
		self:SetNWInt("ShotsFired", self:GetNWInt("ShotsFired") + 1)
		self.LastShot = CurTime()
		self:TakePrimaryAmmo(1)

		if (IsValid(owner) and !owner:IsNPC() and owner.ViewPunch) then
			owner:ViewPunch(Angle(math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) * self.Primary.Recoil, 0))
		end
	end
end

function SWEP:SecondaryAttack()
end

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
