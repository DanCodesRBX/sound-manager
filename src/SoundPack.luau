--!strict

--[=[
@class SoundPack
]=]
local SoundPack = {}
SoundPack.__index = SoundPack

export type SoundPack = typeof(setmetatable(
	{} :: {
		_sounds: {Sound},
		_soundCount: number,
	},
	SoundPack
))

--[=[
Creates a new `SoundPack`
]=]
function SoundPack.new(sounds: {Sound}): SoundPack
	local self = setmetatable({
		_sounds = sounds,
		_soundCount = #sounds
	}, SoundPack)
	
	return self
end

--[=[
@within SoundPack
@method Pick

Returns a random sound from inside the `SoundPack`
]=]
function SoundPack.Pick(self: SoundPack): Sound
	return self._sounds[math.random(1, self._soundCount)]
end

return table.freeze({
	new = SoundPack.new
})