include("sh_init.lua")

if GM.nextRoundState then
	GM.nextRoundState = 0

	GM.nextGreenZoneReduce = 0
	GM.greenzoneOrigin = Vector(0, 0, 0)
	GM.greenzoneRadius = 100

	GM.lastVictor = game.GetWorld()

	GM.currentlyParticipating = {}
end

GM.Materials = GM.Materials or {Replaced = {}}
local function materialReplace(from, to)
	local GM = _G.GM or GAMEMODE
	local mat = Material(from)

	if not mat:IsError() then
		local typ = type(to)
		local tex

		if (typ == "string") then
			tex = Material(to):GetTexture("$basetexture")
		elseif (typ == "ITexture") then
			tex = to
		elseif (typ == "Material") then
			tex = to:GetTexture("$basetexture")
		else
			return
		end

		GM.Materials.Replaced[from] = GM.Materials.Replaced[path] or {}
		GM.Materials.Replaced[from].OldTexture = GM.Materials.Replaced[from].OldTexture or mat:GetTexture("$basetexture")
		GM.Materials.Replaced[from].NewTexture = tex

		mat:SetTexture("$basetexture", tex)
	end
end

local replace = {
	["IMS/BANNER"] = "METAL/METALFLOOR003A",
}

function GM:InitPostEntity()
	for k, v in pairs(replace) do
		materialReplace(k, v)
	end
end

for k, v in pairs(replace) do
	materialReplace(k, v)
end

net.Receive("br_roundState", function()
	GAMEMODE.roundState = net.ReadUInt(4)
	GAMEMODE.nextRoundState = net.ReadUInt(32)

	GAMEMODE.greenzoneOrigin = net.ReadVector()
end)

net.Receive("br_greenZone", function()
	GAMEMODE.greenzoneRadius = net.ReadUInt(16)
	GAMEMODE.nextGreenZoneReduce = net.ReadUInt(32)
end)

net.Receive("br_victor", function()
	GAMEMODE.lastVictor = net.ReadEntity()
end)

net.Receive("br_participating", function()
	GAMEMODE.currentlyParticipating = net.ReadTable()
end)

function GM:PlayersLeft()
	local t = table.Copy(self.currentlyParticipating)
	for k, v in ipairs(t) do
		if not v:Alive() or v:Team() ~= TEAM_ALIVE then
			table.remove(t, k)
		end
	end

	return #t
end

surface.CreateFont("br_cssIcons", {
	font = "csd",
	size = 20,
})

function GM:GetWeaponIcon(wep)
	local c = wep:GetClass()
	if c == "weapon_pistol" then
		return "-" , "HL2MPTypeDeath"
	end

	-- At this point we assume it has a CSS weapon icon
	return wep.IconLetter, "br_cssIcons"
end

local hudFont = "br_hud"
surface.CreateFont(hudFont, {
	font = "Tahoma",
	size = 32,
})

surface.CreateFont(hudFont .. "_small", {
	font = "Tahoma",
	size = 28,
})

surface.CreateFont(hudFont .. "_vsmall", {
	font = "Tahoma",
	size = 21,
})

function GM:HUDShouldDraw(name)
	if name == "CHudHealth" or name == "CHudBattery" or name == "CHudSuitPower" or  name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
		return false
	end

	-- Call the base class function.
	return self.BaseClass:HUDShouldDraw(name)
end

local color_tblack = Color(0, 0, 0, 180)
local color_tgrey = Color(40, 40, 40, 80)
local color_green = Color(100, 200, 100, 255)
local color_red = Color(200, 100, 100, 255)
local color_red2 = Color(200, 40, 40, 255)
local color_blue = Color(60, 60, 200, 255)

local startForm = "A new round will start %s, press %s to toggle entrance."
local endForm = "The round has ended, %s."

local state_in = "You are currently set to participate in this round."
local state_out = "You are currently set to not participate in this round."

local reducing = "Green Zone Reducing:"

function GM:DrawRect(x, y, w, h)
	surface.SetDrawColor(color_tblack)
	surface.DrawRect(x - 1, y - 1, w + 2, h + 2)

	surface.SetDrawColor(color_tgrey)
	surface.DrawRect(x + 2, y + 2, w - 4, h - 4)
end

local rounding = 2
function GM:DrawRect2(x, y, w, h, c)
	draw.RoundedBox(rounding, x - 1, y - 1, w + 2, h + 2, color_black)

	draw.RoundedBox(rounding, x, y, w, h, c)
end

local ammoCount = {}
local __w = 300
local ___w = (__w / 2) - 10

function GM:HUDPaint()
	local ply = LocalPlayer()
	local w, h, x, y, tw, th

	if ply:Team() == TEAM_ALIVE then
		if self.greenzoneRadius > 64 then

			x, y = ScrW() - 10, ScrH() - 8

			local wep = ply:GetActiveWeapon()

			if wep and IsValid(wep) then
				local ico, fon = self:GetWeaponIcon(wep)

				w, h = ___w, 60

				self:DrawRect(x - w - 4, y - h, w + 8, h)

				local ammo

				local class = wep:GetClass()
				local clipOne = wep:Clip1()

				if not ammoCount[class] then
					ammoCount[class] = clipOne
				end

				-- Check if the weapon's first clip is bigger than the amount we have stored for clip one.
				if clipOne > ammoCount[class] then
					ammoCount[class] = clipOne
				end

				local clipMaximum = ammoCount[class]
				local clipAmount = ply:GetAmmoCount(wep:GetPrimaryAmmoType())

				ammo = clipOne .. " / " .. clipMaximum
				tw, th = surface.GetTextSize(ammo)

				draw.SimpleTextOutlined(ammo, hudFont, x - w + w / 2, y -  h / 2 - (h / 6), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

				ammo = clipAmount
				tw, th = surface.GetTextSize(ammo)

				draw.SimpleTextOutlined(ammo, hudFont .. "_vsmall", x - w + w / 2, y - h + h / 2 + th / 2 + (h / 5), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)

				self:DrawRect(x - w * 2, y - h, w - 8, h)

				if ico and fon then
					tw, th = surface.GetTextSize(ico)

					draw.SimpleTextOutlined(ico, fon, x - w * 2 + w / 2 - 2, y - h + h / 2 + th / 2 + 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
				end

				y = y - h - 4
			end

			w, h = __w, 20
			local d = w / 30

			local r

			self:DrawRect(x - w - 4, y - h, w + 8, h)

			r = math.Clamp(ply:Armor() * 0.3, 0, 100)

			for i = 0, r - 1 do
				self:DrawRect2(x - w + math.floor(d * i) + 1, y - h + 2, d - 3, h - 4, color_blue)
			end

			y = y - h - 2
			h = h * 1.42

			self:DrawRect(x - w - 4, y - h, w + 8, h)

			r = math.Clamp(ply:Health() * 0.3, 0, 100)

			for i = 0, r - 1 do
				self:DrawRect2(x - w + math.floor(d * i) + 1, y - h + 2, d - 3, h - 4, color_red2)
			end

			y = y - h - 2

			local reducing_time = string.ToMinutesSeconds(math.max(self.nextGreenZoneReduce - CurTime(), 0))
			reducing_time = reducing .. "  " .. reducing_time

			surface.SetFont(hudFont .. "_vsmall")
			w, h = surface.GetTextSize(reducing_time)

			y = y - h - 2

			--self:DrawRect(x - ___w * 2 - 4, y, ___w * 2 + 8, h, color_tblack)
			draw.SimpleTextOutlined(reducing_time, hudFont .. "_vsmall", x - ___w - 2, y + h / 2 - 1, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

			if not self:PlayerInGreenzone(ply) then
				local text = "RETURN TO THE GREEN ZONE IMMEDIATELY!"

				surface.SetFont(hudFont)
				local w, h = surface.GetTextSize(text)
				local x, y = ScrW() / 2, ScrH() / 2

				self:DrawRect(x - w / 2 - 4, y - h / 2, w + 8, h + 4, color_tblack)

				draw.SimpleTextOutlined(text, hudFont, x, y, color_red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			end
		else
			if not self:PlayerInGreenzone(ply) then
				local text = "THE GREEN ZONE HAS EXPIRED! KILL EVERYONE FAST!"

				surface.SetFont(hudFont)
				local w, h = surface.GetTextSize(text)
				local x, y = ScrW() / 2, 200

				self:DrawRect(x - w / 2 - 4, y - h / 2, w + 8, h + 4, color_tblack)

				draw.SimpleTextOutlined(text, hudFont, x, y, color_red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			end
		end
	return end

	local x, y = ScrW() / 2, 40
	local state = "404 state not found"
	if self.roundState == ROUND_ONGOING then
		state = "The round is currently ongoing."
	elseif self.roundState == ROUND_READY then
		local sub = ""
		local time = self.nextRoundState - CurTime()

		if time > 0 then
			sub = "in " .. string.ToMinutesSeconds(time)
		else
			sub = "soon"
		end
		state = startForm:format(sub, "F2")
	elseif self.roundState == ROUND_OVER then
		local sub = ""
		local vic = self.lastVictor

		if not (vic and vic:IsValid() and vic:IsPlayer()) then
			sub = "there was no victor"
		else
			sub = "the victor was " .. vic:Name()
		end

		state = endForm:format(sub)
	end

	surface.SetFont(hudFont)
	local w, h = surface.GetTextSize(state)

	surface.SetDrawColor(color_tblack)
	surface.DrawRect(x - w/2 - 4, y - h/2, w + 8, h + 2)

	draw.SimpleTextOutlined(state, hudFont, x, y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

	if self.roundState == ROUND_READY then
		y = y + h + 3

		surface.SetDrawColor(color_tblack)
		surface.DrawRect(x - w/2 - 4, y - h/2, w + 8, h + 2)

		local participating = ply:GetNW2Bool("br_participating", false)
		state = participating and state_in or state_out

		draw.SimpleTextOutlined(state, hudFont .. "_small", x, y, participating and color_green or color_red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	end
end

local greenMat = Material("gm_construct/color_room", "smooth noclamp")
local ang, col = Angle(0, 0, 0), Color(50, 180, 50, 255)

function GM:PostDrawTranslucentRenderables()
	local ply = LocalPlayer()

	if ply:Team() == TEAM_ALIVE then
		greenMat:SetFloat("$alpha", 0.2)

		cam.Start3D()
			render.SetMaterial(greenMat)

			local r = self.greenzoneRadius
			render.DrawBox(self.greenzoneOrigin, ang, Vector(r, r, 9999), Vector(-r, -r, -9999), col, true)
		cam.End3D()
	end
end

local matColor = Material("pp/colour")
function GM:RenderScreenspaceEffects()
	render.UpdateScreenEffectTexture()

	matColor:SetTexture("$fbtexture", render.GetScreenEffectTexture())
		matColor:SetFloat("$pp_colour_addr", 0)
		matColor:SetFloat("$pp_colour_addg", 0.025)
		matColor:SetFloat("$pp_colour_addb", 0)
		matColor:SetFloat("$pp_colour_mulr", 0)
		matColor:SetFloat("$pp_colour_mulg", 0)
		matColor:SetFloat("$pp_colour_mulb", 0)
		matColor:SetFloat("$pp_colour_brightness", 0)
		matColor:SetFloat("$pp_colour_contrast", 0.62)
		matColor:SetFloat("$pp_colour_colour", 0.4)
	render.SetMaterial(matColor)

	render.DrawScreenQuad()
end
