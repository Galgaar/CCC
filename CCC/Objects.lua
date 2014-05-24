local Test = Apollo.GetAddon("CCC")
local inspect = Apollo.GetPackage("drafto_inspect-1.1").tPackage
local Target = {}
Target.__index = Target

Test.target = Target

function Target.new(tUnit)
	local self = setmetatable({}, Target)
	self.name = tUnit:GetName()
	self.id = tUnit:GetId()
	self.spell = {}
	self.type = "target"
	return self
end

function Target:addSpell(tSpell)
	self.spell[tSpell.name] = tSpell
end

local Spell = {}
Spell.__index = Spell
Test.spell = Spell

function Spell.new(strSpell)
	local self = setmetatable({} , Spell)
	self.name = strSpell
	self.type = "spell"
	self.cast = {}
	self.count = 0
	return self
end

function Spell:addCast(tCast)
	table.insert(self.cast, tCast)
	self.count = self.count + 1
end

local Cast = {}
Cast.__index = Cast
Test.cast = Cast

function Cast.new()
	local self = setmetatable({}, Cast)
	self.status = 10
	self.type = "cast"
	self.players = {}
	return self
end

function Cast:addPlayer(tPlayer)
	self.players[tPlayer.id] = tPlayer
end

function Cast:setStatus(nStatus)
	if self.status ~= 0 then
		self.status = nStatus
	end
end

local Player = {}
Player.__index = Player
Test.player = Player

function Player.new(tUnit)
	local self = setmetatable({} , Player)
	self.id = tUnit:GetId()
	self.name = tUnit:GetName()
	self.type = "player"
	self.cast = 0
	self.ia = 0
	return self
end

function Player:addCast()
	self.cast = self.cast + 1
end

function Player:addIA(nIA)
	self.ia = self.ia + nIA
end