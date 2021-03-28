#include "effects.lua"
#include "utils.lua"

-- Globals
drawCallQueue = {}
timeScale = 1 -- This one is required to keep chaos time flowing normally.

local testThisEffect = "vehicleKickflip" -- Leave empty to let RNG grab effects.
local lastEffectKey = ""
local currentTime = 0
local currentEffects = {}

function init()
	saveFileInit()
	
	removeDisabledEffectKeys()
	
	chaosSFXInit()
end

function getRandomEffect()
	local key = testThisEffect -- Debug effect, if this is empty replaced by RNG.
	
	if #chaosEffects.effectKeys <= 0 then
		return deepcopy(chaosEffects.noEffectsEffect)
	end
	
	if key == "" then
		local index = math.random(1, #chaosEffects.effectKeys)
		key = chaosEffects.effectKeys[index]
	end
	
	if key == lastEffectKey and testThisEffect == "" and #chaosEffects.effectKeys > 1 then
		return getRandomEffect()
	end
	
	local effectInstance = deepcopy(chaosEffects.effects[key])
	
	return effectInstance
end

function triggerChaos()
	table.insert(chaosEffects.activeEffects, 1, getRandomEffect())
	
	local effect = chaosEffects.activeEffects[1]

	effect.onEffectStart(effect)
end

function removeChaosLogOverflow()
	if #chaosEffects.activeEffects > chaosEffects.maxEffectsLogged then
		for i = #chaosEffects.activeEffects, 1, -1 do
			local curr = chaosEffects.activeEffects[i]
			if curr.effectDuration <= 0 then
				table.remove(chaosEffects.activeEffects, i)
				if #chaosEffects.activeEffects <= chaosEffects.maxEffectsLogged then
					break
				end
			end
		end
	end
end

function chaosEffectTimersTick(dt)
	for key, value in ipairs(chaosEffects.activeEffects) do
		if value.effectDuration > 0 then
			value.effectLifetime = value.effectLifetime + dt
			value.onEffectTick(value)
			if value.effectLifetime > value.effectDuration then
				value.onEffectEnd(value)
				table.remove(chaosEffects.activeEffects, key)
			end
		end
	end
end

function debugFunc()
	if InputPressed("p") then
		for i=1, 20 do
		DebugPrint(" ")
		end
		
		DebugPrint(chaosEffects.testVar == nil)
		
		for key, value in pairs(chaosEffects.effects["myGlasses"]) do
			if type(value) ~= "table" and type(value) ~= "function"then
				DebugPrint(key .. ": " .. value)
			else
				DebugPrint(key .. ": " .. type(value)) 
			end
		end
	end
end

function GetChaosTimeStep()
	if timeScale < 1 then
		return GetTimeStep() * (timeScale + 1)
	else
		return GetTimeStep()
	end
end

function tick(dt)
	--debugFunc()
	
	if(timeScale < 1) then
		dt = dt * (timeScale + 1)
	end
	
	currentTime = currentTime + dt
	
	if currentTime > chaosTimer then
		currentTime = 0
		triggerChaos()
		removeChaosLogOverflow()
	end
	
	chaosEffectTimersTick(dt)
	
	if timeScale ~= 1 then
		SetTimeScale(timeScale)
		timeScale = 1
	end
end

function drawTimer()
local currentTimePercenage = 100 / chaosTimer * currentTime / 100

UiAlign("center middle")

UiPush()
	UiColor(0.1, 0.1, 0.1, 0.5)
	UiTranslate(UiCenter(), 0)
	
	UiRect(UiWidth() + 10, UiHeight() * 0.05)
UiPop()

UiPush()
	UiColor(0.25, 0.25, 1)
	UiTranslate(UiCenter() * currentTimePercenage, 0)
	UiRect(UiWidth() * currentTimePercenage, UiHeight() * 0.05)
UiPop()
end

function drawEffectLog()
UiPush()
	UiColor(1, 1, 1)
	UiTranslate(UiWidth() * 0.9, UiHeight() * 0.1)
	UiAlign("right middle")
	UiTextShadow(0, 0, 0, 0.5, 2.0)
	UiFont("regular.ttf", 26)
	
	for key, value in ipairs(chaosEffects.activeEffects) do
		UiText(value.name)
		
		if value.effectDuration > 0 then
			local effectDurationPercentage = 1 - (100 / value.effectDuration * value.effectLifetime / 100)
		
			UiColor(0.2, 0.2, 0.2, 0.2)
			UiTranslate(100, 0)
			UiRect(75, 20)
			
			UiAlign("center middle")
			
			UiColor(0.7, 0.7, 0.7, 0.5)
			
			UiTranslate(-75 / 2 , 0)
			
			UiRect(75 * effectDurationPercentage, 20)
			
			UiTranslate(75 / 2)
			
			UiColor(1, 1, 1, 1)
			
			UiAlign("right middle")
			
			UiTranslate(-100, 0)
		end
		UiTranslate(0, 40)
	end
	
UiPop()

end

function debugTableToText(inputTable)
	local returnString = "{ "
	for key, value in pairs(inputTable) do
		if type(value) == "string" or type(value) == "number" then
			returnString = returnString .. key .." = " .. value .. ", "
		elseif type(value) == "table" then
			returnString = returnString .. key .. " = " .. debugTableToText(value) .. ", "
		else
			returnString = returnString .. key .. " = " .. type(value) .. ", "
		end
	end
	returnString = returnString .. "}"
	
	return returnString
end

function drawDebugText()
	UiPush()
		UiAlign("top left")
		UiTranslate(UiWidth() * 0.025, UiHeight() * 0.05)
		UiTextShadow(0, 0, 0, 0.5, 2.0)
		UiFont("bold.ttf", 26)
		UiColor(1, 0.25, 0.25, 1)
		UiText("CHAOS MOD DEBUG MODE ACTIVE")
		UiTranslate(0, UiHeight() * 0.025)
		UiText("Testing effect: " .. testThisEffect)
		
		local effect = chaosEffects.effects[testThisEffect]
		
		for index, key in ipairs(chaosEffects.debugPrintOrder) do
			local effectProperty = effect[key]
		
			UiTranslate(0, UiHeight() * 0.025)
			if type(effectProperty) == "string" or type(effectProperty) == "number" then
				UiText(key .." = " .. effectProperty)
			elseif type(effectProperty) == "table" then
				UiText(key .." = " .. debugTableToText(effectProperty))
			else
				UiText(key .. " = " .. type(effectProperty))
			end
		end
	UiPop()
end

function processDrawCallQueue()
	for key, value in ipairs(drawCallQueue) do
		value()
	end
	
	drawCallQueue = {}
end

function draw()
	if testThisEffect ~= "" then
		drawDebugText()
	end
	
	processDrawCallQueue()
	drawTimer()
	drawEffectLog()
end
