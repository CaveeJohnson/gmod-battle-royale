include("sh_init.lua")
include("sv_rounds.lua")

-- Enable realistic fall damage for this gamemode.
game.ConsoleCommand("mp_falldamage 1\n")
game.ConsoleCommand("sbox_godmode 0\n")

-- Enable local chat for this gamemode.
game.ConsoleCommand("sv_voiceenable 1\n")
game.ConsoleCommand("sv_alltalk 1\n")

-- Net Messages, seems like a lot since they also replace umsgs (umsg is deprecated)
do
	util.AddNetworkString("br_roundTime")
	util.AddNetworkString("br_greenZone")
	util.AddNetworkString("br_playerDeath")
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

	local distToSqr = player:GetPos():DistToSqr(listener:GetPos())

	-- Can hear if alive, close to us, and conscious.
	if player:Alive() and distToSqr <= radius then
		return true
	end

	-- Cant hear.
	return false
end
