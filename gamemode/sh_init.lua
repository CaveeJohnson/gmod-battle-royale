AddCSLuaFile()

GM.Name			= "Battle Royale"
GM.Author		= "Q2F2, Liquid"
GM.Email		= "N/A"
GM.Website	= "https://github.com/caveejohnson/gmod-battle-royale/"

include("sh_config.lua")
include("sh_team.lua")

ROUND_OVER = 0
ROUND_READY = 1
ROUND_ONGOING = 2

function GM:PlayerInGreenzone(ply)
	local p = ply:GetPos()
	local zone = self.greenzoneOrigin
	local r = self.greenzoneRadius

	if p.x > zone.x + r or p.x < zone.x - r
	or p.y > zone.y + r or p.y < zone.y - r then
		return false
	end

	return true
end
