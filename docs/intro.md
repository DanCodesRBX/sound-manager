---
sidebar_position: 1
---

# Getting Started

This module can be obtained using [Pesde](https://pesde.dev), a package manager for Roblox, or the [Roblox Marketplace](https://create.roblox.com/store/asset/10547212432/Rain-System).

## Pesde Configuration
Once Pesde is installed, run `pesde init` on your project directory, and then add this module by using `pesde add dancodesrbx/soundpack --alias SoundPack`

To install, run `pesde install` within your project. Pesde will create a roblox_packages folder in your directory with the dependency.

## Rojo Configuration
The roblox_packages folder created by Pesde should be synced into Roblox Studio through your Rojo configuration. For instance, a Rojo configuration might have the following entry to sync the roblox_packages folder into ReplicatedStorage:
```json
{
	"name": "sound-manager-example",
	"tree": {
		"$className": "DataModel",
		"ReplicatedStorage": {
			"$className": "ReplicatedStorage",
			"Packages": {
				"$path": "roblox_packages"
			}
		}
	}
}
```

## Usage Examples

### Client

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require SoundManager
local SoundManager = require(ReplicatedStorage.Packages.SoundManager)

-- Locate sounds
local Sounds = ReplicatedStorage.Packages.Sounds

-- Play sounds
SoundManager.Play(Sounds.Pop)
SoundManager.PlayAt(Sounds.Whack, Vector3.zero)
```

### Server

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
-- Require SoundManager
local SoundManager = require(ReplicatedStorage.Packages.SoundManager)

-- Locate sounds
local Sounds = ReplicatedStorage.Packages.Sounds

-- An optional player list
local playersToSendTo = {Players.wastbo}

-- Play sounds
SoundManager.Play(Sounds.Pop, playersToSendTo)
SoundManager.PlayAt(Sounds.Whack, Vector3.zero, playersToSendTo)
```

# Optimization

SoundManager uses buffers alongside a caching system to deliver optimal network usage.
Using an `UnreliableRemoteEvent` ensures that sounds won't have a heavy impact on ping.