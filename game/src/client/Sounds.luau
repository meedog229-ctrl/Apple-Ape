--!strict
-- Tiny local sound player. Each play clones a template so sounds can overlap and pitch-shift.

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Sounds = {}

local folder = Instance.new("Folder")
folder.Name = "AppleApeSounds"
folder.Parent = SoundService

local templates: { [string]: Sound } = {}
for name, id in Config.Sounds do
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = 0.5
	s.Parent = folder
	templates[name] = s
end

function Sounds.play(name: string, pitch: number?, volume: number?)
	local template = templates[name]
	if not template then
		return
	end
	local s = template:Clone()
	s.PlaybackSpeed = pitch or 1
	if volume then
		s.Volume = volume
	end
	s.Parent = folder
	s:Play()
	Debris:AddItem(s, 3)
end

return Sounds
