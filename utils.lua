moddataPrefix = "savegame.mod.chaosMod"

function saveFileInit()
	saveVersion = GetInt(moddataPrefix .. "Version")
	chaosTimer = GetInt(moddataPrefix .. "ChaosTimer")
	chaosEffects.disabledEffects = DeserializeTable(GetString(moddataPrefix.. "DisabledEffects"))
	
	if saveVersion < 1 then
		SetInt(moddataPrefix .. "Version", 1)
		
		chaosTimer = 10
		SetInt(moddataPrefix .. "ChaosTimer", chaosTimer)
	end
	
	if saveVersion < 2 then
		SetInt(moddataPrefix .. "Version", 2)
		
		chaosEffects.disabledEffects = {}
		SetString(moddataPrefix.. "DisabledEffects", "")
	end
end

function SerializeTable(a) -- Currently only works for key value string tables! (Ignores values)
	local serializedTable = ""
	
	if a == nil then
		return serializedTable
	end
	
	local i = 1
	local tableSize = 0
	
	for key, value in pairs(a) do
		tableSize = tableSize + 1
	end
	
	for key, value in pairs(a) do
		serializedTable = serializedTable .. key
		
		if i < tableSize then
			serializedTable = serializedTable .. ","
		end
		
		i = i + 1
	end
	
	return serializedTable
end

function DeserializeTable(a) -- Currently only works for serialized string tables! (Ignores values)
	if a == nil or a == "" then
		return {}
	end
	
	local deserializedTable = {}
	
	for str in string.gmatch(a, "([^"..",".."]+)") do
		deserializedTable[str] = "disabled"
	end
	
	return deserializedTable
end

function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)	
end

function dirVec(a, b)
	return VecNormalize(VecSub(b, a))
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end
