--!strict

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local SoundPack = require(script.SoundPack)
local getReplicationRemote = require(script.getReplicationRemote)
local getOrCreatePitchShift = require(script.getOrCreatePitchShift)
local jitter = require(script.jitter)

local IS_SERVER = RunService:IsServer()
local PLAY_AT_SIZE = 13

local terrain = workspace:WaitForChild("Terrain")

--[=[
@class SoundManager

The SoundManager class allows for the playing and replication of sounds.
]=]
local SoundManager = {}
local callbacks: {[Sound]: (Sound) -> ()} = {}

--[=[
@within SoundManager
@type Disconnect () -> ()
]=]
type Disconnect = () -> ()

--[=[
@client
@server

Plays a one-shot sound.
Players to replicate to can be specified on the server.
]=]--
function SoundManager.Play(sound: Sound, players: {Player}?)
	callbacks[sound](sound)

	SoundService:PlayLocalSound(sound)
end

--[=[
@client
@server

Plays a one-shot sound at a position in the world.
Players to replicate to can be specified on server
]=]--
function SoundManager.PlayAt(sound: Sound, at: Vector3, players: {Player}?)
	callbacks[sound](sound)

	local newSound = sound:Clone()
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = at
	newSound.Parent = attachment
	attachment.Parent = terrain

	newSound.Ended:Once(function()
		attachment:Destroy()
	end)

	newSound:Play()
end

--[=[
@client

Fires before the specified sound plays
Can be used to add the modulate effect or similar

:::warning

You should not yield inside the callback.

:::
]=]--
function SoundManager.BeforePlayed(sound: Sound, callback: (sound: Sound) -> ()): Disconnect
	if callbacks[sound] then
		warn("There is already a callback bound to this sound. Overriding...")
	end
	
	callbacks[sound] = callback

	return function()
		if callbacks[sound] == callback then
			callbacks[sound] = nil
		end
	end
end

--[=[
@param soundPack SoundPack

Same as `BeforePlayed` but sets the same callback for every sound in a `SoundPack`.

:::warning

You should not yield inside the callback.

:::
]=]
function SoundManager.BeforePackPlayed(soundPack: SoundPack.SoundPack, callback: (sound: Sound) -> ())
	for _, sound in soundPack._sounds do
		SoundManager.BeforePlayed(sound, callback)
	end
end

--[=[
@client

Modulates the specified sound's pitch using a pitch shift effect
]=]--
function SoundManager.Modulate(sound: Sound, spread: number?)
	local pitchShift, originalPitch = getOrCreatePitchShift(sound)
	pitchShift.Octave = jitter(originalPitch, spread)
end

--[=[
@within SoundManager
@function newPack
@param sounds {Sound}
@return SoundPack

Creates a new `SoundPack` object.
]=]
SoundManager.newPack = SoundPack.new

getReplicationRemote(
	IS_SERVER,

	-- Client callback
	function(remote)
		remote.OnClientEvent:Connect(function(sounds: {Sound}, play: buffer?, playAt: buffer?)
			if play then
				for offset = 0, buffer.len(play) - 1 do
					SoundManager.Play(sounds[buffer.readu8(play, offset)])
				end
			end

			if playAt then
				for offset = 0, buffer.len(playAt) - PLAY_AT_SIZE, PLAY_AT_SIZE do
					local sound = sounds[buffer.readu8(playAt, offset)]
					local position = Vector3.new(
						buffer.readf32(playAt, offset + 1),
						buffer.readf32(playAt, offset + 5),
						buffer.readf32(playAt, offset + 9)
					)

					SoundManager.PlayAt(sound, position)
				end
			end
		end)
	end,

	-- Server callback
	function(remote)
		local cache: {[Player]: {any}} = {}

		local function getPlayerCache(player: Player): {}
			local playerCache = cache[player]

			if not playerCache then
				playerCache = {{}}
				cache[player] = playerCache
			end

			return playerCache
		end

		local function addSound(soundArray: {Sound}, sound: Sound): number
			local hasSound = table.find(soundArray, sound)

			if hasSound then
				return hasSound
			else
				table.insert(soundArray, sound)
				return #soundArray
			end
		end

		local function resizeBuffer(buf: buffer, by: number): (buffer, number)
			local oldSize = buffer.len(buf)
			local newBuffer = buffer.create(oldSize + by)

			buffer.copy(newBuffer, 0, buf)

			return newBuffer, oldSize
		end

		local function getBuffer(size: number, buf: buffer?)
			if buf then
				return resizeBuffer(buf, size)
			else
				return buffer.create(size), 0
			end
		end

		local function forEachPlayer(players: {Player}?, callback: (Player) -> ())
            local playersToIterate: {Player} = players or Players:GetPlayers()

			for _, player in playersToIterate do
				callback(player)
			end
		end

		local function replicateSound(sound: Sound, players: {Player}?)
			forEachPlayer(players, function(player)				
				local playerCache = getPlayerCache(player)
				local soundIndex = addSound(playerCache[1], sound)
				local dataBuffer, offset = getBuffer(1, playerCache[2])

				buffer.writeu8(dataBuffer, offset, soundIndex)

				playerCache[2] = dataBuffer
			end)
		end

		local function replicateSoundPosition(sound: Sound, at: Vector3, players: {Player}?)
			local positionBuffer = buffer.create(12)
			buffer.writef32(positionBuffer, 0, at.X)
			buffer.writef32(positionBuffer, 4, at.Y)
			buffer.writef32(positionBuffer, 8, at.Z)

			forEachPlayer(players, function(player)
				local playerCache = getPlayerCache(player)
				local soundIndex = addSound(playerCache[1], sound)
				local dataBuffer, offset = getBuffer(PLAY_AT_SIZE, playerCache[3])

				buffer.writeu8(dataBuffer, offset, soundIndex)	
				buffer.copy(dataBuffer, offset, positionBuffer)

				playerCache[3] = dataBuffer
			end)
		end

		SoundManager.Play = replicateSound
		SoundManager.PlayAt = replicateSoundPosition

		task.spawn(function()
			while true do RunService.PostSimulation:Wait()
				for player, playerCache in cache do
					remote:FireClient(player, playerCache[1], playerCache[2], playerCache[3])
				end

				table.clear(cache)
			end
		end)

	end
)

return SoundManager