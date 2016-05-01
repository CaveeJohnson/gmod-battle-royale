if not GM.roundState then
	GM.roundState = ROUND_READY
	GM.nextRoundState = GM.Config.RoundReadyTime * 5

	GM.greenzoneOrigin = Vector(0, 0, 0)
	GM.greenzoneRadius = 2000
	GM.nextGreenZoneReduce = 0
	GM.greenzoneReduce = GM.Config.ReduceGreenzone

	GM.prevVictor = game.GetWorld()
end

local spawnbox = GM.Config.BattleSpawnBox[game.GetMap()]
function GM:GenerateGreenzoneOrigin()
	self.greenzoneRadius = self.Config.DefaultGZRadius
	self.greenzoneOrigin = Vector(0, 0, 0)
	self.greenzoneReduce = self.Config.ReduceGreenzone

	if not spawnbox then return end

	local mi = spawnbox.min
	local ma = spawnbox.max

	local x, y, z = math.floor(mi.x + ma.x) / 2, math.floor(mi.y + ma.y) / 2
	local w, h = math.max(mi.x, ma.x) - math.min(mi.x, ma.x), math.max(mi.y, ma.y) - math.min(mi.y, ma.y)

	self.greenzoneOrigin = Vector(x, y, 0)

	local rad = math.max(w, h)

	self.greenzoneRadius = rad
	self.greenzoneReduce = rad / (self.Config.RoundTargetTime + 1)
end

function GM:GetRandomLocationInSpawnbox(ply)
	if not spawnbox then return end

	local mi = spawnbox.min
	local ma = spawnbox.max

	local success, loc

	-- This very strange loop structure tries to reduce the chances of someone spawning inside someone else.
	for i = 1, 10 do
		success = true

		local x, y, z = math.random(mi.x, ma.x), math.random(mi.y, ma.y), math.min(mi.z, ma.z)
		loc = Vector(x, y, z)

		for k, v in ipairs(player.GetAll()) do
			if v == ply or v:Team() ~= TEAM_ALIVE then continue end

			local p = v:GetPos()

			if p:IsEqualTol(loc, 32) then
				success = false

				break
			end
		end

		if success then
			break
		end
	end

	return loc
end

function GM:ReduceGreenzoneRadius(radius, delay)
	self.greenzoneRadius = math.max(self.greenzoneRadius - radius, 0)
	self.nextGreenZoneReduce = CurTime() + delay

	net.Start("br_greenZone")
		net.WriteUInt(self.greenzoneRadius, 16)
		net.WriteUInt(self.nextGreenZoneReduce, 32)
	net.Broadcast()
end

function GM:RoundTick()
	if self.roundState == ROUND_ONGOING then
		if self.nextGreenZoneReduce < CurTime() then
			print("reduce greenzone")

			self:ReduceGreenzoneRadius(self.greenzoneReduce, self.Config.ReduceGreenzoneTime)
		end
	return end

	if self.nextRoundState > CurTime() then return end

	if self.roundState == ROUND_OVER then
		self:StartRound()
		self:MakeEveryoneParticipate()
	elseif self.roundState == ROUND_READY then
		local part = self:GetParticipatingPlayers()
		local count = #part
		if count < self.Config.MinimumPlayers then return end

		print("state is ready, ACTUALLY STARTING")

		self.nextGreenZoneReduce = CurTime() + self.Config.ReduceGreenzoneTime

		self:GenerateGreenzoneOrigin()
		self:SetRoundState(ROUND_ONGOING)

		for k, v in ipairs(part) do
			v:KillSilent()
			v:Spawn()

			v:SetTeam(TEAM_ALIVE)
			self:PositionPlayer(v)
		end
	end
end

function GM:PositionPlayer(ply)
	print("setup player")

	local loc = self:GetRandomLocationInSpawnbox(ply)
	if loc then
		ply:SetPos(loc)
		ply:GodEnable()

		timer.Simple(10, function() if IsValid(ply) then ply:GodDisable() end end)
	end

	-- TODO
	ply:Give("weapon_pistol")
end

function GM:SendRoundInfoToPlayer(ply)
	print("transmit info")

	net.Start("br_roundState")
		net.WriteUInt(self.roundState, 4)
		net.WriteUInt(self.nextRoundState, 32)
		net.WriteVector(self.greenzoneOrigin)
	net.Send(ply)

	net.Start("br_greenZone")
		net.WriteUInt(self.greenzoneRadius, 16)
		net.WriteUInt(self.nextGreenZoneReduce, 32)
	net.Send(ply)

	net.Start("br_victor")
		net.WriteEntity(self.prevVictor)
	net.Send(ply)
end

function GM:SetRoundState(state, time)
	print("set round state")

	if time then self.nextRoundState = CurTime() + time end

	net.Start("br_roundState")
		net.WriteUInt(state, 4)
		net.WriteUInt(self.nextRoundState, 32)
		net.WriteVector(self.greenzoneOrigin)
	net.Broadcast()

	net.Start("br_greenZone")
		net.WriteUInt(self.greenzoneRadius, 16)
		net.WriteUInt(self.nextGreenZoneReduce, 32)
	net.Broadcast()

	self.roundState = state
end

function GM:StartRound()
	print("round restarting")
	self:SetRoundState(ROUND_READY, self.Config.RoundReadyTime)
end

function GM:EndRound(victor)
	print("ended!")
	self:SetRoundState(ROUND_OVER, self.Config.RoundOverTime)

	for k, v in ipairs(player.GetAll()) do
		if v:Team() ~= TEAM_LOBBY then
			v:SetTeam(TEAM_LOBBY)
			v:KillSilent()
			v:Spawn()
		end
	end

	self.prevVictor = (victor and victor:IsValid() and victor) or game.GetWorld()

	net.Start("br_victor")
		net.WriteEntity(self.prevVictor)
	net.Broadcast()
end

-- Used to check if the round is ready to end.
function GM:CheckForRoundEnd()
	if self.roundState ~= ROUND_ONGOING then return end

	local alivePlayers = team.GetPlayers(TEAM_ALIVE)

	for k, v in ipairs(alivePlayers) do
		if not v:Alive() then
			table.remove(alivePlayers, k)
		end
	end

	if #alivePlayers <= 1 then
		self:EndRound(alivePlayers[1])
	end
end

function GM:PlayerDisconnected()
	timer.Simple(0.1, function() self:CheckForRoundEnd() end)
end

timer.Create("br_round_fallback", 5, 0, function()
	GAMEMODE:CheckForRoundEnd()
end)
