LogLine("---------- Loading Monster Widget ----------")

MONSTERS = {}

function Update(address, data)
	MONSTERS[address] = json.decode(data)
	LogLine("add monster: "..MONSTERS[address].Name)
end

Add = Update

function Remove(address)
	LogLine("remove monster: "..MONSTERS[address].Name)
	MONSTERS[address] = nil
end

function RemoveAll()
	MONSTERS = {}
end

function Render()
	local currPosition = 300
	for _, monster in pairs(MONSTERS) do
		if (monster.IsVisible) then
			MonsterWindow(monster, currPosition)
			currPosition = currPosition + 300
		end
	end
end

function MonsterWindow(monster, currPosition)
	ig.SetNextWindowPos(ig.ImVec2(currPosition, 10))
	ig.Begin(monster.Name, nil, imgui.ImGuiWindowFlags_AlwaysAutoResize)
	MonsterDetail(monster)
	ig.End()
end

function MonsterDetail(monster)
	local percent = monster.Health.Current / monster.Health.Max
	ig.ProgressBar(percent, ig.ImVec2(0, 0), tostring(math.ceil(monster.Health.Current))..' / '..tostring(math.ceil(monster.Health.Max)))

	for _, part in ipairs(monster.Parts) do
		if (part.IsVisible) then
			MonsterPart(part)
		end
	end

	for _, effect in ipairs(monster.StatusEffects) do
		if (effect.IsVisible) then
			StatusEffect(effect)
		end
	end
end

function MonsterPart(part)
	local percentString = part.Name .. ': ' .. tostring(math.ceil(part.Health.Current)) .. ' / ' .. tostring(math.ceil(part.Health.Max))
	ig.Text(percentString)

	local percent = part.Health.Current / part.Health.Max
	ig.ProgressBar(percent, ig.ImVec2(0, 1), "")
end

function StatusEffect(effect)
	local percentString = effect.Name .. ': ' .. tostring(math.ceil(effect.Duration.Current)) .. ' / ' .. tostring(math.ceil(effect.Duration.Max))
	ig.Text(percentString)

	local percent = effect.Duration.Current / effect.Duration.Max
	ig.ProgressBar(percent, ig.ImVec2(0, 1), "")
end

LogLine("---------- Monster Widget Loaded ----------")
