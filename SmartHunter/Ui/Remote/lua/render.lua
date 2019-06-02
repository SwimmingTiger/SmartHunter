LogLine("---------- Loading SmartHunter Widget ----------")

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

function FileExists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

-- load fonts
if (FileExists(FONT_FILE)) then
	ig.GetIO().Fonts:Clear()
	FONT = ig.GetIO().Fonts:AddFontFromFileTTF(FONT_FILE, 18, nil, ig.GetIO().Fonts:GetGlyphRangesChineseFull())
	if (FONT ~= nil) then
		UpdateFontCache()
	else
		LogLine("Cannot load font "..FONT_FILE)
	end
else
	LogLine("Missing font "..FONT_FILE)
end

COLOR_HEALTH = RGBA(255, 0, 0, 0.6)
COLOR_EFFECT = RGBA(0, 255, 255, 0.6)
COLOR_WINDOW_BG = RGBA(0, 0, 0, 0)

MONSTER_WINDOW_FLAG = imgui.ImGuiWindowFlags_AlwaysAutoResize + imgui.ImGuiWindowFlags_NoBackground + imgui.ImGuiWindowFlags_NoTitleBar
PLAYER_EFFECTS_WINDOW_FLAG = MONSTER_WINDOW_FLAG

--ig.GetStyle().WindowTitleAlign = ig.ImVec2(0.5, 1.5)
SetWindowBGColor(COLOR_WINDOW_BG)

MONSTER_LINE_WIDTH = 250

------------------------- Utils --------------------------

function TextWidth(text)
	return ig.CalcTextSize(text).x
end

function StrDecentralizedAlign(leftStr, rightStr, lineSize)
	local spaceWidth = TextWidth(' ')
	local spaceNum = (lineSize - TextWidth(leftStr) - TextWidth(rightStr)) / spaceWidth
	return leftStr..string.rep(' ', spaceNum)..rightStr
end

function StrCenterAlign(str, lineSize)
	local spaceWidth = TextWidth(' ')
	local pad = string.rep(' ', (lineSize - TextWidth(str)) / 2 / spaceWidth)
	return pad..str..pad
end

function TextDecentralizedAlign(leftStr, rightStr, lineSize)
	ig.Text(leftStr)
	ig.SameLine()
	ig.SetCursorPosX(lineSize - TextWidth(rightStr) + 5)
	ig.Text(rightStr)
end

function TextCenterAlign(str, lineSize)
	ig.SetCursorPosX((lineSize - TextWidth(str)) / 2)
	ig.Text(str)
end

---------------------- Data Updates ----------------------

------------ Monsters ------------

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
	if (MONSTERS[address] ~= nil) then
		LogLine("remove monster: "..MONSTERS[address].Name)
		MONSTERS[address] = nil
	end
end

function RemoveAllMonster()
	MONSTERS = {}
	LogLine("all monsters removed")
end

------------ Player Effects ------------

PLAYER_EFFECTS = {}

function UpdatePlayerEffect(index, data)
	local effect = json.decode(data)
	if (PLAYER_EFFECTS[index] == nil) then
		if not (effect.IsVisible) then
			return
		end
		LogLine("add player effect: "..effect.Name)
	elseif not (effect.IsVisible) then
		return RemovePlayerEffect(index)
	end
	PLAYER_EFFECTS[index] = effect
end

AddPlayerEffect = UpdatePlayerEffect

function RemovePlayerEffect(index)
	if (PLAYER_EFFECTS[index] ~= nil) then
		LogLine("remove player effect: "..PLAYER_EFFECTS[index].Name)
		PLAYER_EFFECTS[index] = nil
	end
end

function RemoveAllPlayerEffect()
	PLAYER_EFFECTS = {}
	LogLine("all player effects removed")
end

------------------------- Render -------------------------

function Render()
	ig.SetNextWindowPos(ig.ImVec2(2300, 0))
	ig.Begin('Time', nil, PLAYER_EFFECTS_WINDOW_FLAG)
	ig.Text(os.date('%c'))
	ig.End()

	local currPosition = 600
	for _, monster in pairs(MONSTERS) do
		if (monster.IsVisible) then
			MonsterWindow(monster, currPosition)
			currPosition = currPosition + 300
		end
	end

	PlayerEffectWindow()
end

function MonsterWindow(monster, currPosition)
	ig.SetNextWindowPos(ig.ImVec2(currPosition, 10))
	local name = monster.Name
	if (monster.Crown > 0) then
		name = name..' ('..CROWN_NAME[monster.Crown]..')'
	end
	ig.Begin('Monster '..monster.Address, nil, MONSTER_WINDOW_FLAG)
	TextCenterAlign(name, MONSTER_LINE_WIDTH)
	MonsterDetail(monster)
	ig.End()
end

function MonsterDetail(monster)
	local percent = monster.Health.Fraction
	local percentString = StrCenterAlign(tostring(math.ceil(monster.Health.Current))..'/'..tostring(math.ceil(monster.Health.Max)), MONSTER_LINE_WIDTH)
	SetProgressBarColor(COLOR_HEALTH)
	ig.ProgressBar(percent, ig.ImVec2(MONSTER_LINE_WIDTH, 19), percentString)

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
	TextDecentralizedAlign(name, tostring(math.ceil(part.Health.Current)) .. '/' .. tostring(math.ceil(part.Health.Max)), MONSTER_LINE_WIDTH)

	local percent = part.Health.Fraction
	SetProgressBarColor(COLOR_HEALTH)
	ig.ProgressBar(percent, ig.ImVec2(MONSTER_LINE_WIDTH, 3), "")
end

function StatusEffect(effect)
	local name = effect.Name
	if (effect.TimesActivatedCount > 0) then
		name = name .. ' x' .. tostring(effect.TimesActivatedCount)
	end
	TextDecentralizedAlign(name, tostring(math.ceil(effect.Buildup.Current)) .. '/' .. tostring(math.ceil(effect.Buildup.Max)), MONSTER_LINE_WIDTH)

	local percent = effect.Buildup.Fraction
	SetProgressBarColor(COLOR_EFFECT)
	ig.ProgressBar(percent, ig.ImVec2(MONSTER_LINE_WIDTH, 3), "")
end

function PlayerEffectWindow()
	ig.SetNextWindowPos(ig.ImVec2(0, 10))
	ig.Begin("Player Effects", nil, PLAYER_EFFECTS_WINDOW_FLAG)

	for _, effect in pairs(PLAYER_EFFECTS) do
		if (effect.IsVisible) then
			PlayerEffectDetail(effect)
		end
	end

	ig.End()
end

function PlayerEffectDetail(effect)
	local text = effect.Name
	if (effect.EndTime > 0) then
		local timeRemaining = effect.EndTime - os.time()
		if (timeRemaining < 0) then
			RemovePlayerEffect(effect.Index)
			return
		end
		text = text..' ('..tostring(math.ceil(timeRemaining))..')'
	end
	ig.Text(text)
end

LogLine("---------- SmartHunter Widget Loaded ----------")
