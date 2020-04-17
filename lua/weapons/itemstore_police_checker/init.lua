
local delay = 0.3 --How often it'll 'Think' to improve performance
local sounddelay = 0.6 --Do what you want +0.3 due to how the code works
local PrimaryAttackCooldown = 2

local Finish_Sounds = {
	[1] = "npc/combine_soldier/zipline_clip1.wav",
	[2] = "npc/combine_soldier/zipline_clip2.wav",
	[3] = "npc/combine_soldier/zipline_clothing1.wav",
	[4] = "npc/combine_soldier/zipline_clothing2.wav",
}

local Blacklisted_Jobs = {
//["Citizen"] = true,
}

local Forced_Allowed_Jobs = {
//["Admin"] = true,
}

local Should_Blacklist_Police_Jobs = true

local Only_Police_Can_Use = false

/////////////////////////////////
//DO NOT ADJUST BELOW THIS LINE//
/////////////////////////////////

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("Itemstore_Police_Checker_Timer")

function SWEP:PrimaryAttack()

	local ply = self.Owner
	local pl = ply:GetEyeTrace().Entity
	
	if !ply or !ply:IsValid() then return end
	
	if !pl or !pl:IsValid() or (pl:GetPos():DistToSqr(ply:GetPos()) > 10000) then ply:ChatPrint("Player is out of reach!") self:SetNextPrimaryFire( CurTime() + PrimaryAttackCooldown ) return end
	
	if ((Should_Blacklist_Police_Jobs and GAMEMODE.CivilProtection[pl:Team()]) or (next(Blacklisted_Jobs) and Blacklisted_Jobs[team.GetName(pl:Team())]) or (Only_Police_Can_Use and !GAMEMODE.CivilProtection[ply:Team()])) and !Forced_Allowed_Jobs[team.GetName(ply:Team())] then ply:ChatPrint("You may not use this SWEP!") self:SetNextPrimaryFire( CurTime() + PrimaryAttackCooldown ) return end
	
	if !self.ShouldThink_Itemstore then
		self.ShouldThink_Itemstore = true
	else
		self.ShouldThink_Itemstore = false
	end
	
	self:SetNextPrimaryFire( CurTime() + PrimaryAttackCooldown )
	
end

function SWEP:Think() //Reason it is in a think function is so if the player walks away it'd stop

	if !self.ShouldThink_Itemstore then return true end
	
	self.ThinkCooldown = self.ThinkCooldown or 0
	local timeElapsed = CurTime() - self.ThinkCooldown
	if timeElapsed > delay then

		local ply = self.Owner
		
		if !ply or !ply:IsValid() then return end
		
		local trace = ply:GetEyeTrace()
		local pl = trace.Entity
		
		if pl and IsValid(pl) and (pl:GetPos():DistToSqr(ply:GetPos()) < 10000) and ply:GetActiveWeapon() == self then
		
			if not pl.Inventory then
			
				timer.Remove(self:EntIndex().."_ItemStore_Checker")
				
				ply:ChatPrint("Player is out of reach!")
				self:SetNextPrimaryFire( CurTime() + PrimaryAttackCooldown )
				self.ShouldThink_Itemstore = false
			end
			
			self.SoundCooldown = self.SoundCooldown or 0
			local timeElapsed2 = CurTime() - self.SoundCooldown
			if timeElapsed2 > sounddelay then
				ply:EmitSound("npc/combine_soldier/gear"..math.random(1,6)..".wav", 50, math.random(95,115), 1)
				self.SoundCooldown = CurTime()
			end
			
			if !timer.Exists(self:EntIndex().."_ItemStore_Checker") then 
			
				net.Start("Itemstore_Police_Checker_Timer")
					net.WriteFloat(CurTime())
				net.Send(ply)
			
				timer.Create(self:EntIndex().."_ItemStore_Checker", 3, 1, function()
				
					if !ply or !ply:IsValid() or !IsValid(pl) or pl != trace.Entity then return end
					
					pl.Inventory:SetPermissions( ply, true, true )
					pl.Inventory:Sync( ply )
					ply:OpenContainer( pl.Inventory:GetID(), itemstore.Translate( "players_inventory", pl:Name() ) )
					
					ply:EmitSound(Finish_Sounds[math.random(1,#Finish_Sounds)], 50, math.random(95,115), 1)
					
					self:SetNextPrimaryFire( CurTime() + PrimaryAttackCooldown )
					self.ShouldThink_Itemstore = false
				
				end)
			end
			
		else

			timer.Remove(self:EntIndex().."_ItemStore_Checker")
			
			ply:ChatPrint("Player is out of reach!")
			self:SetNextPrimaryFire( CurTime() + PrimaryAttackCooldown )
			self.ShouldThink_Itemstore = false
			
		end
		
		self.ThinkCooldown = CurTime() 
	end

	return true
end

function SWEP:Holster()
	timer.Remove(self:EntIndex().."_ItemStore_Checker")
	return true
end

function SWEP:SecondaryAttack()
	return true
end