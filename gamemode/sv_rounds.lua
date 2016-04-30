function GM:RoundTick()
	if self.roundState == ROUND_ONGOING then return end
	if not (self.nextRoundState and self.nextRoundState <= CurTime()) then return end

	if self.roundState == ROUND_OVER then
		self:SetRoundState(ROUND_READY)
	elseif self.roundState == ROUND_READY then
		self:SetRoundState(ROUND_ONGOING)
	end
end

function GM:SetRoundState(state, time)
	net.Start("br_roundState")
		net.WriteUInt(state, 4)
		net.WriteUInt(time, 16)
	net.Broadcast()

	self.roundState = state
	self.nextRoundState = CurTime() + time
end

function GM:StartRound()
	self:SetRoundState(ROUND_READY, self.Config.RoundReadyTime)
end

function GM:EndRound(victor)
	self:SetRoundState(ROUND_OVER, self.Config.RoundOverTime)

	net.Start("br_victor")
		net.WriteEntity(victor or game.GetWorld())
	net.Broadcast()
end

-- Used to check if the round is ready to end.
function GM:CheckForRoundEnd()
	local alivePlayers = team.GetPlayers(TEAM_ALIVE)

	if #alivePlayers <= 1 then
		self:EndRound(alivePlayers[1])
	end
end
