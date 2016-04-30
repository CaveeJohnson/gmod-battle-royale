AddCSLuaFile()

TEAM_ALIVE = 10
TEAM_LOBBY = 11

-- Maybe don't use teams?
team.SetUp(TEAM_ALIVE, "Alive", Color(255, 0, 0))
team.SetUp(TEAM_LOBBY, "Lobby", Color(0, 0, 255))

function GM:TogglePlayerParticipating(ply)
	self:SetPlayerParticipating(ply, not ply.br_participating)
end

function GM:SetPlayerParticipating(ply, bool)
	ply.br_participating = bool
	ply:SetNW2Bool("br_participating", ply.br_participating)
end

function GM:MakeEveryoneParticipate()
	for k, v in ipairs(player.GetAll()) do
		self:SetPlayerParticipating(v, true)
	end
end

function GM:GetParticipatingPlayers()
	local t = {}
	for k, v in ipairs(player.GetAll()) do
		if v.br_participating then t[#t+1] = v end
	end

	return t
end

function GM:PlayerRequestTeam(ply, team)
	-- Do some sort of debug message here
	if not ply:IsAdmin() or not ply:IsSuperAdmin() then return false end

	return true -- Allow admins to change their team
end
