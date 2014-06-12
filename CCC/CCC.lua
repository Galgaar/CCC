-----------------------------------------------------------------------------------------------
-- Client Lua Script for CCC
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- CCC Module Definition
-----------------------------------------------------------------------------------------------
local CCC = {} 
local target
local spell
local cast
local player
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CCC:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function CCC:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, true)
end
 

-----------------------------------------------------------------------------------------------
-- CCC OnLoad
-----------------------------------------------------------------------------------------------
function CCC:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CCC.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.RegisterEventHandler("CombatLogCCState", "OnCCState", self)
	Apollo.RegisterTimerHandler("OnSpellEndTimer", "OnSET", self)
	Apollo.RegisterSlashCommand("ccc", "OnCCCOn", self)
	Apollo.RegisterSlashCommand("colorcc", "OnColorOn", self)
end

function CCC:OnSave(eType)
	local tSave =
	{
		show = self.show,
		color = self.color,
		limit = self.limit,
		focus = self.focus,
		anchor = {self.wndMain:GetAnchorOffsets()},
	}

	return tSave
end

function CCC:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	if tSavedData then
		self.show = tSavedData.show
		self.color = tSavedData.color
		self.limit = tSavedData.limit
		self.focus = tSavedData.focus
		self.anchor = tSavedData.anchor
	else
		self.show = false
		self.color = "default"
		self.limit = 10
		self.focus = false
	end
end

-----------------------------------------------------------------------------------------------
-- CCC OnDocLoaded
-----------------------------------------------------------------------------------------------
function CCC:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "CCCForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		target = self.target
		spell = self.spell
		cast = self.cast
		player = self.player
		
		if self.color == nil then
			self.color = "default"
		end
		if self.limit == nil then
			self.limit = 10
		end
		if self.focus == nil then
			self.focus = false
		end
		if self.show == nil then
			self.show = false
		end
		self.cur = nil
		self.type = "list"
		self.list = {}
		self.castingTarget = {}
		self.castTime = {}
		self.ids = {}
		self.displayChanged = true
		self.curDisplay = {}
		self.output = "p"
		ApolloColor.SetColor("default", {r=1, g=1, b=1, a=0.37})
		self:OnUpdateDisplay()
		if self.anchor ~= nil then
			self.wndMain:SetAnchorOffsets(unpack(self.anchor))
		end
		self:OnColorOn(nil, self.color)
	    self.wndMain:Show(self.show, true)
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- CCC Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function CCC:OnConfigure()
	self.wndOptions = Apollo.LoadForm(self.xmlDoc, "OptionMenu", nil, self)
	self.res = Apollo.LoadForm(self.xmlDoc, "Options", self.wndOptions:FindChild("Content"), self)
	self.wndColor = self.res:FindChild("Form"):FindChild("Window"):FindChild("Window"):FindChild("EditBox")
	self.wndLimit = self.res:FindChild("Form1"):FindChild("Window"):FindChild("Window"):FindChild("EditBox")
	self.wndFocus = self.res:FindChild("Form1"):FindChild("Window1"):FindChild("Button")
	self:SetOptionsValues()
	self.wndOptions:Show(true, true)
end

function CCC:SetOptionsValues()
	self.wndFocus:SetCheck(self.focus)
	self.wndLimit:SetText(self.limit)
end

function CCC:OnUpdateDisplay()
	local title = self.wndMain:FindChild("Title")
	local win = self.wndMain:FindChild("Window")
	if self.displayChanged then
		for k,v in pairs(self.curDisplay) do
			v:Destroy()
		end
		self.curDisplay = {}
	end
	if self.type == "list" then
		if self.displayChanged then
			title:SetText("Liste")
		end		
		for k,v in pairs(self.list) do
			if self.curDisplay[k] == nil then
				self.curDisplay[k] = Apollo.LoadForm(self.xmlDoc, "Item", win, self)
				self.curDisplay[k]:SetText(v.name)
				self.curDisplay[k]:SetData(v)
			end
		end
	elseif self.type == "target" then
		if self.displayChanged then
			title:SetText(self.cur.name)
		end
		for k,v in pairs(self.cur.spell) do
			if self.curDisplay[k] == nil then
				self.curDisplay[k] = Apollo.LoadForm(self.xmlDoc, "Item", win, self)
				self.curDisplay[k]:SetText(v.name)
				self.curDisplay[k]:SetData(v)
			end
			for k2,v2 in pairs(v.cast) do
				local key = k .. ":".. k2
				if self.curDisplay[key] == nil then
					self.curDisplay[key] = Apollo.LoadForm(self.xmlDoc, "Item", win, self)
					local text = ""
					for k3,v3 in pairs(v2.players) do
						text = text .. " " .. v3.name .. "(" .. v3.ia .. ")"
					end
					self.curDisplay[key]:SetText(text)
					self.curDisplay[key]:SetData({type = "cspell", name = v.name, text = text, status = v2.status})
					self.curDisplay[key]:FindChild("CC"):SetText(v2.status)
				end
			end					
		end
	end	
	win:ArrangeChildrenVert()
	self.displayChanged = false
end

function CCC:OnCCCOn(cmd, arg)
	if arg ~= "" then
		self.output = arg
	end
	self:OnUpdateDisplay()
	self.show = true
	self.wndMain:Show(true, false)
end

function CCC:OnColorOn(cmd, arg)
	self.wndMain:SetBGColor(ApolloColor.new(arg))
	self.wndMain:FindChild("Title"):SetTextColor(arg)
	self.wndMain:FindChild("CloseButton"):SetBGColor(arg)
	self.wndMain:FindChild("ResetButton"):SetBGColor(arg)
	self.wndMain:FindChild("SetupButton"):SetBGColor(arg)
	self.color = arg
end

function CCC:OnCCState(tEventArgs)
	if tEventArgs.eResult == 10 then -- Ignore end of CC
		return
	end
	local nTarget = tEventArgs.unitTarget
	if nTarget == nil then
		return
	end
	if self.focus and GameLib.GetPlayerUnit():GetTarget() ~= nTarget then
		return
	end
	local nTId = nTarget:GetId()
	local nCaster = tEventArgs.unitCaster
	if nCaster == nil then
		return
	end
	local nCId = nCaster:GetId()
	if not nCaster:IsThePlayer() and not nCaster:IsInYourGroup() then
		return
	end
	if self.castingTarget[nTId] ~= nil then
		local strSpell = self.castingTarget[nTId]
		local tList = self.list[nTId]
		local tSpellCur = tList.spell[strSpell]
		local tCurCast = tSpellCur.cast[tSpellCur.count]
		local tPlayers = tCurCast.players
		if tPlayers[nCId] == nil then
			tCurCast:addPlayer(player.new(nCaster))
		end
		local tCurPlayer = tPlayers[nCId]
		tCurPlayer:addCast()
		tCurPlayer:addIA(tEventArgs.nInterruptArmorHit)
		tCurCast:setStatus(tEventArgs.eResult)
	elseif nTarget:IsCasting() then
		local strSpell = nTarget:GetCastName()
		self.castingTarget[nTId] = strSpell
		local iTime = (nTarget:GetCastDuration() - nTarget:GetCastElapsed()) / 1000
		self.castTime[nTId] = {}
		self.castTime[nTId]["time"] = Time.Now()
		self.castTime[nTId]["ltime"] = iTime
		Apollo.CreateTimer("OnSpellEndTimer", iTime, false)
		if self.list[nTId] == nil then
			self.list[nTId] = target.new(nTarget)
			table.insert(self.ids, nTId)
			if table.getn(self.ids) > self.limit then
				local id = table.remove(self.ids, 1)
				if self.cur ~= nil and self.cur.type == "target" and self.cur.id == id then
					self.type = "list"
				end
				self.displayChanged = true
				self.list[id] = nil
			end		
		end
		local tList = self.list[nTId]
		if tList.spell[strSpell] == nil then
			tList.spell[strSpell] = spell.new(strSpell)
		end
		tList.spell[strSpell]:addCast(cast.new())
		local tCurCast = tList.spell[strSpell].cast[tList.spell[strSpell].count]
		if tCurCast.players[nCId] == nil then
			tCurCast:addPlayer(player.new(nCaster))
		end
		local tCurPlayer = tCurCast.players[nCId]
		tCurPlayer:addCast()
		tCurPlayer:addIA(tEventArgs.nInterruptArmorHit)
		tCurCast:setStatus(tEventArgs.eResult)
	else
		if self.list[nTId] == nil then
			self.list[nTId] = target.new(nTarget)
			table.insert(self.ids, nTId)
			if table.getn(self.ids) > self.limit then
				local id = table.remove(self.ids, 1)
				if self.cur ~= nil and self.cur.type == "target" and self.cur.id == id then
					self.type = "list"
				end
				self.displayChanged = true					
				self.list[id] = nil
			end
		end
		local tList = self.list[nTId]
		if tList.spell["None"] == nil then
			tList.spell["None"] = spell.new("None")
			tList.spell["None"]:addCast(cast.new())
		end
		if tList.spell["None"].cast[1].players[nCId] == nil then
			tList.spell["None"].cast[1]:addPlayer(player.new(nCaster))
		end
		tList.spell["None"].cast[1].players[nCId]:addIA(1)
	end
	self:OnUpdateDisplay()
end

function CCC:OnSET()
	for k,v in pairs(self.castTime) do
		if v["ltime"] < Time.SecondsElapsed(v["time"]) then
			self.castingTarget[k] = nil
			self.castTime[k] = nil
		end
	end
end

-----------------------------------------------------------------------------------------------
-- CCCForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function CCC:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function CCC:OnCancel()
	self.show = false
	self.wndMain:Close() -- hide the window
end


function CCC:OnResetPressed( wndHandler, wndControl, eMouseButton )
	self.cur = nil
	self.type = "list"
	self.list = {}
	self.castingTarget = {}
	self.castTime = {}
	self.ids = {}
	self.displayChanged = true
	self:OnUpdateDisplay()
end

function CCC:OnShowMenu( wndHandler, wndControl, eMouseButton )
	if self.wndOptions then
		self:SetOptionsValues()
		self.wndOptions:Show(true, true)
	else
		self:OnConfigure()
	end
end

---------------------------------------------------------------------------------------------------
-- Item Functions
---------------------------------------------------------------------------------------------------

function CCC:SetDisplay( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if GameLib.CodeEnumInputMouse.Left == eMouseButton then
		local data = wndHandler:GetData()
		if data.type == "target" then
			self.type = data.type
			self.displayChanged = true
			self.cur = data
			self:OnUpdateDisplay()
		elseif data.type == "cspell" then
			local stat = (data.status == 0) and "Stopped" or "Casted"
			ChatSystemLib.Command("/" .. self.output .. " " .. data.name .. "(" .. stat .. "):" .. data.text)
		elseif data.type == "spell" then
			ChatSystemLib.Command("/" .. self.output .. " " .. data.name .. " : ")
			for k,v in pairs(data.cast) do
				local stat = (v.status == 0) and "Stopped" or "Casted"
				local text = ""
				for k2,v2 in pairs(v.players) do
					text = text .. " " .. v2.name .. "(" .. v2.ia .. ")"
				end
				ChatSystemLib.Command("/" .. self.output .. " " .. k .. ": " ..  stat .. " - " .. text)
			end
		end
	elseif GameLib.CodeEnumInputMouse.Right == eMouseButton then
		self.type = "list"
		self.displayChanged = true
		self.cur = nil
		self:OnUpdateDisplay()
	end

---------------------------------------------------------------------------------------------------
-- OptionMenu Functions
---------------------------------------------------------------------------------------------------
end
function CCC:OnOkButton( wndHandler, wndControl, eMouseButton )
	local color = self.res:FindChild("Form"):FindChild("Window"):FindChild("Window"):FindChild("EditBox"):GetText()
	local limit = self.res:FindChild("Form1"):FindChild("Window"):FindChild("Window"):FindChild("EditBox"):GetText()
	limit = tonumber(limit)
	self.focus = self.res:FindChild("Form1"):FindChild("Window1"):FindChild("Button"):IsChecked()
	if limit == nil or limit == "" then
		limit = 10
	end
	self.limit = limit
	if color ~= nil and color ~= "" then
		self:OnColorOn(nil, color)
	end
	self.wndOptions:Close()
end

-----------------------------------------------------------------------------------------------
-- CCC Instance
-----------------------------------------------------------------------------------------------
local CCCInst = CCC:new()
CCCInst:Init()
