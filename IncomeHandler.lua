--!strict

--//CONSTRUCTOR
local IncomeHandler = {}
IncomeHandler.__index = IncomeHandler

export type IncomeData = {
	Income: number,
	Multiplier: number,
	PetsMultiplier: number,
}

local STARTER_DATA: IncomeData = {
	Income = 0.05,
	Multiplier = 1,
	PetsMultiplier = 1,
}

function IncomeHandler.new(UserId: number)
	local self = setmetatable({}, IncomeHandler)
	
	self.UserId = UserId
	self.Data = table.clone(STARTER_DATA) :: IncomeData
	
	self.Dirty = false
	self.CurrentState = "None" --//None, Loading, Loaded, Saving, Saved, AutoSaving, Error
	
	return self
end

--//DataStoreService
local DataName = "IncomeDataV0.01"

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataStore = DataStoreService:GetDataStore(DataName)

function IncomeHandler:LoadData()
	local Key = self.UserId
	
	if self.CurrentState == "Loading" then return true, "Already loading" end
	self.CurrentState = "Loading"
	
	for i = 1, 2 do
		
		local Succes, data = pcall(function()
			return DataStore:GetAsync(Key)
		end)
		
		if not Succes then
			warn("Error while loading data for UserId: " .. Key)
			self.CurrentState = "Error"
		end
		
		if Succes and not data then
			data = self.Data
			break
		end
		
		if Succes and data then
			self.Data = table.clone(data)
			break
		end
		
		task.wait(0.5)
	end
	
	if self.CurrentState == "Error" then
		return false, "Kick Player"
	end
	
	self.CurrentState = "Loaded"
	
	return true, "Loaded"
end

function IncomeHandler:SaveData()
	local Key = self.UserId
	
	if self.CurrentState == "Saving" then return false, "Already saving" end
	self.CurrentState = "Saving"
	
	local succes, err = pcall(function()
		DataStore:UpdateAsync(Key, function(oldData)
			oldData = oldData or {}
			
			local newData = table.clone(oldData)
			
			for i, v in pairs(self.Data) do
				newData[i] = v
			end
			
			return newData
		end)
	end)
	
	if not succes then
		warn("Error while saving data for UserId: " .. Key)
		self.CurrentState = "Error"
		return false, "Error"
	end
	
	if self.CurrentState == "Error" then
		self.Data = table.clone(STARTER_DATA) 
		return false, "Kick Player"
	end
	
	self.CurrentState = "Saved"
	self.Dirty = false
	
	return true, "Saved"
end

function IncomeHandler:AutoSave()
	if self.CurrentState == "AutoSaving" then return "Already saving" end
	self.CurrentState = "AutoSaving"
	
	local Player = Players:GetPlayerByUserId(self.UserId)
	
	while Player and Player.Parent do
		
		if self.Dirty then
			self:SaveData()
		end
		
		task.wait(30)
		
	end
	
	return "Player Left"
end

--//INCOME

function IncomeHandler:AddIncome(IncomeName : string, IncomeAmount: number)
	if not IncomeName or typeof(IncomeName) ~= "string" then return false, "Invalid IncomeName" end
	if not self.Data[IncomeName] then return false, "IncomeName not found" end
	
	if not IncomeAmount or typeof(IncomeAmount) ~= "number" then return false, "Invalid IncomeAmount" end
	IncomeAmount = math.clamp(IncomeAmount, 0, 1000)
	
	local CurrentIncome : number = self.Data[IncomeName]
	CurrentIncome = math.clamp(CurrentIncome, 0, 1000)
	
	self.Data[IncomeName] = CurrentIncome + IncomeAmount
	
	self.Dirty = true
	
	return true, "IncomeName found and IncomeAmount added succesfully"
end

function IncomeHandler:SubtractIncome(IncomeName : string, IncomeAmount: number)
	if not IncomeName or typeof(IncomeName) ~= "string" then return false, "Invalid IncomeName" end
	if not self.Data[IncomeName] then return false, "IncomeName not found" end
	
	if not IncomeAmount or typeof(IncomeAmount) ~= "number" then return false, "Invalid IncomeAmount" end
	IncomeAmount = math.clamp(IncomeAmount, 0, 1000)
	
	local CurrentIncome : number = self.Data[IncomeName]
	CurrentIncome = math.clamp(CurrentIncome, 0, 1000)
	
	self.Data[IncomeName] = CurrentIncome - IncomeAmount
	
	self.Dirty = true
	
	return true, "IncomeName found and IncomeAmount subtracted succesfully"
end

--//GETINCOME

function IncomeHandler:GetIncome()
	local Income : number = self.Data.Income
	local Multiplier : number = self.Data.Multiplier
	local PetsMultiplier : number = self.Data.PetsMultiplier

	return Income * Multiplier * PetsMultiplier
end

--//INIT

function IncomeHandler:Init()
	self:AutoSave()
end

--//RETURN

return IncomeHandler