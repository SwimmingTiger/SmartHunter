LogLine("---------- Loading SmartHunter Widget ----------")

------------------------ Themes --------------------------

-- load fonts
--ig.GetIO().Fonts:AddFontFromFileTTF('C:\\Windows\\Fonts\\msyh.ttc', 16, nil, ig.GetIO().Fonts:GetGlyphRangesChineseFull())
--UpdateFontCache()

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

ig.GetStyle().WindowTitleAlign = ig.ImVec2(0.5, 1.5)
SetWindowBGColor(COLOR_WINDOW_BG)

LINE_WIDTH = 250
LINE_SIZE = 27

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

function UpdateMonster(address, data)
	local monster = json.decode(data)
	if (MONSTERS[address] == nil) then
		LogLine("add monster: "..monster.Name)
	end
	MONSTERS[address] = monster
end

AddMonster = UpdateMonster

function RemoveMonster(address)
	LogLine("remove monster: "..MONSTERS[address].Name)
	MONSTERS[address] = nil
end

function RemoveAllMonster()
	MONSTERS = {}
end

------------------------- Render -------------------------

function Render()
	local currPosition = 600
	for _, monster in pairs(MONSTERS) do
		if (monster.IsVisible) then
			MonsterWindow(monster, currPosition)
			currPosition = currPosition + 300
		end
	end
end

function MonsterWindow(monster, currPosition)
	ig.SetNextWindowPos(ig.ImVec2(currPosition, 10))
	local name = monster.Name
	if (monster.Crown > 0) then
		name = name..' ('..CROWN_NAME[monster.Crown]..')'
	end
	ig.Begin(name, nil, WINDOW_FLAG)
	MonsterDetail(monster)
	ig.End()
end

function MonsterDetail(monster)
	local percent = monster.Health.Current / monster.Health.Max
	local percentString = CenterAlignment(tostring(math.ceil(monster.Health.Current))..'/'..tostring(math.ceil(monster.Health.Max)), LINE_SIZE)
	SetProgressBarColor(COLOR_HEALTH)
	ig.ProgressBar(percent, ig.ImVec2(LINE_WIDTH, 19), percentString)

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
	local name = part.Name
	if (part.TimesBrokenCount > 0) then
		name = name .. ' x' .. tostring(part.TimesBrokenCount)
	end
	local percentString = DecentralizedAlignment(name, tostring(math.ceil(part.Health.Current)) .. '/' .. tostring(math.ceil(part.Health.Max)), LINE_SIZE)
	ig.Text(percentString)

	local percent = part.Health.Current / part.Health.Max
	SetProgressBarColor(COLOR_HEALTH)
	ig.ProgressBar(percent, ig.ImVec2(LINE_WIDTH, 3), "")
end

function StatusEffect(effect)
	local name = effect.Name
	if (effect.TimesActivatedCount > 0) then
		name = name .. ' x' .. tostring(effect.TimesActivatedCount)
	end
	local percentString = DecentralizedAlignment(name, tostring(math.ceil(effect.Buildup.Current)) .. '/' .. tostring(math.ceil(effect.Buildup.Max)), LINE_SIZE)
	ig.Text(percentString)

	local percent = effect.Buildup.Current / effect.Buildup.Max
	SetProgressBarColor(COLOR_EFFECT)
	ig.ProgressBar(percent, ig.ImVec2(LINE_WIDTH, 3), "")
end

LogLine("---------- SmartHunter Widget Loaded ----------")
