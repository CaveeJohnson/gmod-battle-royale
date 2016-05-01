include("sh_init.lua")
include("sv_rounds.lua")

-- Enable realistic fall damage for this gamemode.
game.ConsoleCommand("mp_falldamage 1\n")
game.ConsoleCommand("sbox_godmode 0\n")

-- Enable local chat for this gamemode.
game.ConsoleCommand("sv_voiceenable 1\n")

-- Net Messages, seems like a lot since they also replace umsgs (umsg is deprecated)
do
	util.AddNetworkString("br_roundState")
	util.AddNetworkString("br_greenZone")

	util.AddNetworkString("br_playerDeath")
	util.AddNetworkString("br_victor")
end

-- Called when the server initializes.
function GM:Initialize()
	ErrorNoHalt("----------------------\n")
	ErrorNoHalt(os.date() .. " - Server starting up\n")
	ErrorNoHalt("----------------------\n")

	-- Call the base class function.
	return self.BaseClass:Initialize()
end

-- Called when all of the map entities have been initialized.
function GM:InitPostEntity()
	timer.Simple(0, function() hook.Run("LoadData") end)
	self.initSuccess = true

	-- Call the base class function.
	return self.BaseClass:InitPostEntity()
end

-- Called to check if a player can use voice.
local radius = GM.Config.VoiceRadius ^ 2
function GM:PlayerCanHearPlayersVoice(listener, player)
	if not (player:IsValid() and listener:IsValid()) then return end

	if player:Team() ~= listener:Team() then return false end
	if player:Team() == TEAM_LOBBY then return true end

	local distToSqr = player:GetPos():DistToSqr(listener:GetPos())

	-- Can hear if alive, close to us, and conscious.
	if player:Alive() and distToSqr <= radius then
		return true
	end

	-- Cant hear.
	return false
end

-- Called every tick
function GM:Think()
	self:RoundTick()
end

function GM:PlayerShouldTakeDamage(ply, attacker)
	if ply:Team() == TEAM_LOBBY then return false end
	if attacker:IsPlayer() and attacker:Team() ~= ply:Team() then return false end

	return true
end

-- Called when a player spawns for the first time
function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_LOBBY)
	ply.playerModel = table.Random(self.Config.Playermodels)

	self:SendRoundInfoToPlayer(ply)
end

local spawnClasses = {
	["info_player_deathmatch"] = true,
	["info_player_rebel"] = true,
	["gmod_player_start"] = true,
	["info_player_start"] = true,
	["info_player_allies"] = true,
	["info_player_axis"] = true,
	["info_player_counterterrorist"] = true,
	["info_player_terrorist"] = true,
}

function GM:InitPostEntity()
	local spawns = self.Config.LobbySpawns[game.GetMap()]
	if spawns then
		for k, v in ipairs(ents.GetAll()) do
			if spawnClasses[v:GetClass()] then
				v:Remove()
			end
		end

		for k, v in ipairs(spawns) do
			local s = ents.Create("info_player_start")
				s:SetPos(v)
				s:SetMoveType(MOVETYPE_NONE)
			s:Spawn()
			s:Activate()
		end
	end
end

-- Called when a player spawns
function GM:PlayerSpawn(ply)
	ply:SetModel(ply.playerModel)
	ply:SetCanZoom(ply:Team() == TEAM_LOBBY)

	return self.BaseClass:PlayerSpawn(ply)
end

-- Called when a player has died.
function GM:PostPlayerDeath(ply)
	if ply:Team() ~= TEAM_ALIVE then return end
	self:CheckForRoundEnd()

	net.Start("br_playerDeath")
		net.WriteEntity(ply)
	net.Broadcast()

	ply:SetTeam(TEAM_LOBBY)
	self:SetPlayerParticipating(ply, false)
end

function GM:ShowTeam(ply)
	if ply:Team() == TEAM_LOBBY and self.roundState == ROUND_READY then
		self:TogglePlayerParticipating(ply)
	end
end

function GM:CheckPassword(steamID64, ipAddress, svPassword, clPassword, name)
	if self.Config.AntiRetard and clPassword:lower() ~= "iamnotretarded" then
		return false, "This is a TEST server, if you know what you are doing type\n    'password iamnotretarded'\ninto your console."
	end
end

