LogLine("---------- Loading Monster Widget ----------")

------------------------ Themes --------------------------

function RGBA(r, g, b, a)
	return ig.ImVec4(r/255, g/255, b/255, a)
end

function SetColor(item, color)
	ig.GetStyle().Colors[item] = color
end

function SetProgressBarColor(color)
	SetColor(imgui.ImGuiCol_PlotHistogram, color)
end

function SetWindowBGColor(color)
	SetColor(imgui.ImGuiCol_WindowBg, color)
	SetColor(imgui.ImGuiCol_TitleBg, color)
	SetColor(imgui.ImGuiCol_TitleBgCollapsed, color)
	SetColor(imgui.ImGuiCol_TitleBgActive, color)
end

COLOR_HEALTH = RGBA(255, 0, 0, 0.6)
COLOR_EFFECT = RGBA(0, 255, 255, 0.6)
COLOR_WINDOW_BG = RGBA(0, 0, 0, 0)

WINDOW_FLAG = imgui.ImGuiWindowFlags_NoCollapse + imgui.ImGuiWindowFlags_AlwaysAutoResize + imgui.ImGuiWindowFlags_NoBackground

function SetWindowStyle()
	ig.PushStyleVarVec2(imgui.ImGuiStyleVar_WindowTitleAlign, ig.ImVec2(0.5, 1.5))
end

------------------------- Utils --------------------------

function DecentralizedAlignment(leftStr, rightStr, lineSize)
	return leftStr..string.rep(' ', lineSize-string.len(leftStr)-string.len(rightStr))..rightStr
end

function CenterAlignment(str, lineSize)
	local pad = string.rep(' ', (lineSize-string.len(str))/2)
	return pad..str..pad
end

---------------------- Data Updates ----------------------

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

------------------------- Render -------------------------

function Render()
	SetWindowStyle()
	local currPosition = 600
	for _, monster in pairs(MONSTERS) do
		if (monster.IsVisible) then
			MonsterWindow(monster, currPosition)
			currPosition = currPosition + 250
		end
	end
end

function MonsterWindow(monster, currPosition)
	ig.SetNextWindowPos(ig.ImVec2(currPosition, 10))
	ig.Begin(monster.Name, nil, WINDOW_FLAG)
	MonsterDetail(monster)
	ig.End()
end

function MonsterDetail(monster)
	local percent = monster.Health.Current / monster.Health.Max
	local percentString = CenterAlignment(tostring(math.ceil(monster.Health.Current))..' / '..tostring(math.ceil(monster.Health.Max)), 30)
	SetProgressBarColor(COLOR_HEALTH)
	ig.ProgressBar(percent, ig.ImVec2(0, 15), percentString)

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
	local percentString = DecentralizedAlignment(part.Name, tostring(math.ceil(part.Health.Current)) .. ' / ' .. tostring(math.ceil(part.Health.Max)), 30)
	ig.Text(percentString)

	local percent = part.Health.Current / part.Health.Max
	SetProgressBarColor(COLOR_HEALTH)
	ig.ProgressBar(percent, ig.ImVec2(0, 3), "")
end

function StatusEffect(effect)
	local percentString = DecentralizedAlignment(effect.Name, tostring(math.ceil(effect.Buildup.Current)) .. ' / ' .. tostring(math.ceil(effect.Buildup.Max)), 30)
	ig.Text(percentString)

	local percent = effect.Buildup.Current / effect.Buildup.Max
	SetProgressBarColor(COLOR_EFFECT)
	ig.ProgressBar(percent, ig.ImVec2(0, 3), "")
end

LogLine("---------- Monster Widget Loaded ----------")
