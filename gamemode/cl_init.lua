include("sh_init.lua")

if GM.nextRoundState then
	GM.nextRoundState = 0

	GM.nextGreenZoneReduce = 0
	GM.greenzoneOrigin = Vector(0, 0, 0)
	GM.greenzoneRadius = 100

	GM.lastVictor = game.GetWorld()
end

GM.Materials = GM.Materials or {Replaced = {}}
local function materialReplace(from, to)
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

function GM:InitPostEntity()
	materialReplace("IMS/BANNER","METAL/METALFLOOR003A")
end

materialReplace("IMS/BANNER","METAL/METALFLOOR003A")

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
	print("victor!!!! = ", GAMEMODE.lastVictor)
end)

local hudFont = "br_hud"
surface.CreateFont(hudFont, {
	font = "Tahoma",
	size = 32,
})

surface.CreateFont(hudFont .. "_small", {
	font = "Tahoma",
	size = 28,
})

function GM:HUDShouldDraw(name)
	if name == "CHudHealth" or name == "CHudBattery" or name == "CHudSuitPower" or  name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
		return false
	end

	-- Call the base class function.
	return self.BaseClass:HUDShouldDraw(name)
end

local color_tblack = Color(0, 0, 0, 120)
local color_green = Color(100, 200, 100, 255)
local color_red = Color(200, 100, 100, 255)

local startForm = "A new round will start %s, press %s to toggle entrance."
local endForm = "The round has ended, %s."

local state_in = "You are currently set to participate in this round."
local state_out = "You are currently set to not participate in this round."

local reducing = "Green Zone Reducing:"

function GM:HUDPaint()
	local ply = LocalPlayer()

	if ply:Team() == TEAM_ALIVE then
		local x, y = 10, ScrH() - 10

		surface.SetFont(hudFont .. "_small")
		local w, h = surface.GetTextSize(reducing)

		surface.SetDrawColor(color_tblack)
		surface.DrawRect(x - 4, y - h * 2 + 2, w + 8, h * 2 + 2)

		draw.SimpleTextOutlined(reducing, hudFont .. "_small", x, y - 22, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, color_black)
		draw.SimpleTextOutlined(string.ToMinutesSeconds(self.nextGreenZoneReduce - CurTime()), hudFont .. "_small", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, color_black)
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
greenMat:SetFloat("$alpha", 0.2)

local ang, col = Angle(0, 0, 0), Color(50, 180, 50, 255)
function GM:PostDrawTranslucentRenderables()
	local ply = LocalPlayer()

	if ply:Team() == TEAM_ALIVE then
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
		matColor:SetFloat("$pp_colour_contrast", 0.65)
		matColor:SetFloat("$pp_colour_colour", 0.45)
	render.SetMaterial(matColor)

	render.DrawScreenQuad()
end
