--!strict

local function getOrCreatePitchShift(sound: Sound): (PitchShiftSoundEffect, number)
	local pitchShift = sound:FindFirstChildOfClass("PitchShiftSoundEffect")
	
	if not pitchShift then
		local newShift = Instance.new("PitchShiftSoundEffect")
		newShift.Octave = 1
		newShift:SetAttribute("OriginalPitch", 1)
		newShift.Parent = sound
		
		return newShift, 1
	else
		local originalPitch = pitchShift:GetAttribute("OriginalPitch") :: number

		if not originalPitch then
			originalPitch = pitchShift.Octave
			pitchShift:SetAttribute("OriginalPitch", originalPitch)
		end

		return pitchShift, originalPitch
	end
end

return getOrCreatePitchShift