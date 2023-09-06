if engine.ActiveGamemode() ~= "terrortown" then return end

-- Resource handeling
if SERVER then
    AddCSLuaFile()
end

-- Setting the parameters for the Item
SWEP.PrintName = "Camera Flasher"
SWEP.Author = "James"
SWEP.Contact = "Steam"
SWEP.Instructions = "Flash anyone in front of you with Leftclick, rightclick to zoom/roll"
SWEP.Purpose = "Basically a flashbang in your very hands"
SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.Icon = "vgui/gmod_camera"
SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP1
SWEP.ViewModel = Model( "models/weapons/c_arms_animations.mdl" )
SWEP.WorldModel = Model( "models/MaxOfS2D/camera.mdl" )

SWEP.ShootSound = Sound( "NPC_CScanner.TakePhoto" )

SWEP.CanBuy = {ROLE_TRAITOR, ROLE_JACKAL}

SWEP.InLoadoutFor = nil
SWEP.LimitedStock = true

-- Changing what it says in the Equipmenu
SWEP.EquipMenuData = {
    type = "item_weapon",
    name = "Camera Flash",
    desc = "Flash anyone in front of you with Leftclick, rightclick to zoom/roll"
}

SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.AutoSpawnable = true
SWEP.HoldType = "camera"
SWEP.Primary.ClipSize = 3
SWEP.Primary.DefaultClip = 3
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
--SWEP.Weight = 7
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = false

-- Spamprotection
local primaryCooldown = 2 -- in sec

--
-- Network/Data Tables
--
function SWEP:SetupDataTables()

	self:NetworkVar( "Float", 0, "Zoom" )
	self:NetworkVar( "Float", 1, "Roll" )

	if ( SERVER ) then
		self:SetZoom( 70 )
		self:SetRoll( 0 )
	end

end

function SWEP:Reload()

	local owner = self:GetOwner()

	if ( !owner:KeyDown( IN_ATTACK2 ) ) then self:SetZoom( owner:IsBot() && 75 || owner:GetInfoNum( "fov_desired", 75 ) ) end
	self:SetRoll( 0 )

end

function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
	self:DoShootEffect()


    local size = 100
	local dir = ply:GetAimVector()
	local angle = math.cos( math.rad( 45 ) ) -- 15 degrees
	local startPos = ply:EyePos()

	local entities = ents.FindInCone( startPos, dir, size, angle )

	-- draw the lines
	for id, traceEnt in ipairs( entities ) do
        if traceEnt:IsValid() 
            and traceEnt:IsPlayer()
            -- Because spectators are apparently entities too
            and traceEnt:GetObserverMode() == OBS_MODE_NONE
        then
            traceEnt:ScreenFade(SCREENFADE.IN, color_white, .3, 1 )
        end
	end

	-- If we're multiplayer this can be done totally clientside
	if ( !game.SinglePlayer() && SERVER ) then return end
	if ( CLIENT && !IsFirstTimePredicted() ) then return end

    -- Do a screenshot :)
	self:GetOwner():ConCommand( "jpeg" )

end

--
-- SecondaryAttack - Nothing. See Tick for zooming.
--
function SWEP:SecondaryAttack()
end

--
-- The effect when a weapon is fired successfully
--
function SWEP:DoShootEffect()

	local owner = self:GetOwner()

	self:EmitSound( self.ShootSound )
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	owner:SetAnimation( PLAYER_ATTACK1 )

	if ( SERVER && !game.SinglePlayer() ) then

		--
		-- Note that the flash effect is only
		-- shown to other players!
		--

		local vPos = owner:GetShootPos()
		local vForward = owner:GetAimVector()

		local trace = {}
		trace.start = vPos
		trace.endpos = vPos + vForward * 256
		trace.filter = owner

		local tr = util.TraceLine( trace )

		local effectdata = EffectData()
		effectdata:SetOrigin( tr.HitPos )
		util.Effect( "camera_flash", effectdata, true )

	end

end