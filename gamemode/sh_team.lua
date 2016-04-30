AddCSLuaFile()

TEAM_ALIVE = 10
TEAM_LOBBY = 11

-- Maybe don't use teams?
team.SetUp(TEAM_ALIVE, "Alive", Color(255, 0, 0))
team.SetUp(TEAM_LOBBY, "Lobby", Color(0, 0, 255))

function GM:PlayerRequestTeam(ply, team)
	-- Do some sort of debug message here
	if not ply:IsAdmin() or not ply:IsSuperAdmin() then return false end

	return true -- Allow admins to change their team
end
