
include("shared.lua")

SWEP.PrintName = "Seizing SWEP"
SWEP.Slot = 2
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

local IsHookRunning = false

function SWEP:PrimaryAttack()
	return true
end

function SWEP:SecondaryAttack()
	return true
end

function SWEP:Think()

	if !IsHookRunning then return true end
	
    if !self.NextDotsTime or (self.NextDotsTime and CurTime() >= self.NextDotsTime) then
        self.NextDotsTime = CurTime() + 0.5
        LocalPlayer().Dots_ItemStore_Wep = LocalPlayer().Dots_ItemStore_Wep or ""
        local len = string.len(LocalPlayer().Dots_ItemStore_Wep)
        local dots = {
            [0] = ".",
            [1] = "..",
            [2] = "...",
            [3] = ""
        }
        LocalPlayer().Dots_ItemStore_Wep = dots[len]
    end

	return true
end

net.Receive("Itemstore_Police_Checker_Timer", function()
	local time = net.ReadFloat()+3
	IsHookRunning = true
	
	hook.Add("HUDPaint", "HUDPaint_Itemstore_PoliceChecker", function()
		local curtime = CurTime()
		local pl = LocalPlayer():GetEyeTrace().Entity
		
		if time > curtime and IsValid(pl) and LocalPlayer():Alive() and (pl:GetPos():DistToSqr(LocalPlayer():GetPos()) < 10000) and LocalPlayer():GetActiveWeapon():GetClass() == "itemstore_police_checker" then
	
			LocalPlayer().Dots_ItemStore_Wep = LocalPlayer().Dots_ItemStore_Wep or ""
			local w = ScrW()
			local h = ScrH()
			local x, y, width, height = w / 2 - w / 10, h / 2, w / 5, h / 15
			local status = 1-Lerp((time-curtime)/3, 0, 1)
			local BarWidth = status * (width - 16)
			local cornerRadius = math.Min(8, BarWidth / 3 * 2 - BarWidth / 3 * 2 % 2)

			draw.RoundedBox(8, x, y, width, height, Color(10, 10, 10, 120))
			draw.RoundedBox(cornerRadius, x + 8, y + 8, BarWidth, height - 16, Color(0, 0 + (status * 255), 255 - (status * 255), 255))
			draw.DrawNonParsedSimpleText("Checking Inventory" .. LocalPlayer().Dots_ItemStore_Wep, "Trebuchet24", w / 2, y + height / 2, Color(255, 255, 255, 255), 1, 1)
		
		else
		
			IsHookRunning = false
			hook.Remove("HUDPaint", "HUDPaint_Itemstore_PoliceChecker")
		end
	end)
end)