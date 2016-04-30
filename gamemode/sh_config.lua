AddCSLuaFile()
GM.Config = {}

-- Voice range
GM.Config.VoiceRadius = 300

GM.Config.RoundReadyTime = 20
GM.Config.RoundOverTime = 30

GM.Config.Playermodels = {
	"models/player/group01/male_01.mdl",
	"models/player/group01/male_02.mdl",
	"models/player/group01/male_03.mdl",
	"models/player/group01/male_04.mdl",
	"models/player/group01/male_05.mdl",
	"models/player/group01/male_06.mdl",
	"models/player/group01/male_07.mdl",
	"models/player/group01/male_08.mdl",
	"models/player/group01/male_09.mdl",

	"models/player/group01/female_01.mdl",
	"models/player/group01/female_02.mdl",
	"models/player/group01/female_04.mdl",
	"models/player/group01/female_05.mdl",
	"models/player/group01/female_06.mdl",
}

GM.Config.MinimumPlayers = 2

GM.Config.ReduceGreenzone = 250
GM.Config.ReduceGreenzoneTime = 90
GM.Config.DefaultGZRadius = 1500

GM.Config.LobbySpawns = {
	["rp_stalker_v2"] = {
		-- Computer generated locations.
		[ 1] = Vector ( 8724.048828125 , -4168.7802734375, -2495.96875     ),
		[ 2] = Vector ( 8696.302734375 , -3774.880859375 , -2559.96875     ),
		[ 3] = Vector ( 8947.7509765625, -3788.6499023438, -2559.96875     ),
		[ 4] = Vector ( 8474.8408203125, -3762.7541503906, -2559.96875     ),
		[ 5] = Vector ( 8486.783203125 , -3544.8403320313, -2559.96875     ),
		[ 6] = Vector ( 8679.5439453125, -3555.3957519531, -2559.96875     ),
		[ 7] = Vector ( 8911.54296875  , -3568.1000976563, -2559.96875     ),
		[ 8] = Vector ( 8337.083984375 , -4150.7436523438, -2495.96875     ),
		[ 9] = Vector ( 7980.8754882813, -4155.9995117188, -2495.96875     ),
		[10] = Vector ( 7976.3872070313, -3851.9877929688, -2495.96875     ),
		[11] = Vector ( 7971.4213867188, -3515.5749511719, -2495.96875     ),
		[12] = Vector ( 7966.2265625   , -3163.5637207031, -2495.96875     ),
		[13] = Vector ( 8263.4833984375, -3200.3784179688, -2495.96875     ),
		[14] = Vector ( 8621.0341796875, -3209.18359375  , -2495.96875     ),
		[15] = Vector ( 8948.4873046875, -3204.3527832031, -2495.96875     ),
		[16] = Vector ( 9208.1171875   , -3200.5227050781, -2495.96875     ),
		[17] = Vector ( 9289.0849609375, -3583.6142578125, -2495.96875     ),
		[18] = Vector ( 9293.943359375 , -3911.0275878906, -2495.96875     ),
		[19] = Vector ( 9297.732421875 , -4166.4453125   , -2495.96875     ),
		[20] = Vector ( 8927.9921875   , -4171.900390625 , -2495.96875     )
	},
}
