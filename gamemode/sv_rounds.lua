if not GM.roundState then
	GM.roundState = ROUND_READY
	GM.nextRoundState = GM.Config.RoundReadyTime * 5

	GM.greenzoneOrigin = Vector(0, 0, 0)
	GM.greenzoneRadius = 2000
	GM.nextGreenZoneReduce = 0

	GM.prevVictor = game.GetWorld()
end

function GM:ReduceGreenzoneRadius(radius, delay)
	self.greenzoneRadius = math.max(self.greenzoneRadius - radius, 100)
	self.nextGreenZoneReduce = CurTime() + delay

	net.Start("br_greenZone")
		net.WriteUInt(self.greenzoneRadius, 16)
		net.WriteUInt(self.nextGreenZoneReduce, 32)
	net.Broadcast()
end

function GM:RoundTick()
	if self.roundState == ROUND_ONGOING then
		if self.nextGreenZoneReduce < CurTime() then
			self:ReduceGreenzoneRadius(self.Config.ReduceGreenzone, self.Config.ReduceGreenzoneTime)
		end
	return end

	if self.nextRoundState > CurTime() then return end

	local part = self:GetParticipatingPlayers()
	local count = #part
	if count < self.Config.MinimumPlayers then return end

	if self.roundState == ROUND_OVER then
		self:SetRoundState(ROUND_READY)
		self:MakeEveryoneParticipate()
	elseif self.roundState == ROUND_READY then
		self:SetRoundState(ROUND_ONGOING)
		self.greenzoneRadius = self.Config.DefaultGZRadius

		for k, v in ipairs(part) do
			v:SetTeam(TEAM_ALIVE)

			self:PositionPlayer(v)
		end
	end
end

function GM:PositionPlayer(ply)
	-- TODO
	ply:Spawn()
end

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

function GM:SendRoundInfoToPlayer(ply)
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
	if time then self.nextRoundState = CurTime() + time end

	net.Start("br_roundState")
		net.WriteUInt(state, 4)
		net.WriteUInt(self.nextRoundState, 32)
		net.WriteVector(self.greenzoneOrigin)
	net.Broadcast()

	self.roundState = state
end

function GM:StartRound()
	self:SetRoundState(ROUND_READY, self.Config.RoundReadyTime)
end

function GM:EndRound(victor)
	print("ended!")
	self:SetRoundState(ROUND_OVER, self.Config.RoundOverTime)

	for k, v in ipairs(player.GetAll()) do
		if v:Team() ~= TEAM_LOBBY then
			v:SetTeam(TEAM_LOBBY)
			v:Spawn()
		end
	end

	self.prevVictor = victor or game.GetWorld()

	net.Start("br_victor")
		net.WriteEntity(self.prevVictor)
	net.Broadcast()
end

-- Used to check if the round is ready to end.
function GM:CheckForRoundEnd()
	local alivePlayers = team.GetPlayers(TEAM_ALIVE)

	if #alivePlayers <= 1 then
		self:EndRound(alivePlayers[1])
	end
end
