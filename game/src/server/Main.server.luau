-- Apple Ape server entry point. Order matters: world first, then systems that use it.

local World = require(script.Parent.World)
local PlayerState = require(script.Parent.PlayerState)
local Apples = require(script.Parent.Apples)
local Trees = require(script.Parent.Trees)
local Economy = require(script.Parent.Economy)
local AppleDrop = require(script.Parent.AppleDrop)

local map = World.build()
Apples.init()
Trees.init(map.trees)
Economy.init(map.sellPad)
AppleDrop.init()
PlayerState.init() -- last: starts loading players once every system is listening

print("[Apple Ape] server ready")
