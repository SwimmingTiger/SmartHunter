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

MONSTER_WINDOW_FLAG = imgui.ImGuiWindowFlags_AlwaysAutoResize + imgui.ImGuiWindowFlags_NoBackground + imgui.ImGuiWindowFlags_NoCollapse
PLAYER_EFFECTS_WINDOW_FLAG = MONSTER_WINDOW_FLAG + imgui.ImGuiWindowFlags_NoTitleBar

ig.GetStyle().WindowTitleAlign = ig.ImVec2(0.5, 1.5)
SetWindowBGColor(COLOR_WINDOW_BG)

MONSTER_LINE_WIDTH = 250
MONSTER_LINE_SIZE = 27

------------------------- Utils --------------------------

function DecentralizedAlignment(leftStr, rightStr, lineSize)
	return leftStr..string.rep(' ', lineSize-string.len(leftStr)-string.len(rightStr))..rightStr
end

function CenterAlignment(str, lineSize)
	local pad = string.rep(' ', (lineSize-string.len(str))/2)
	return pad..str..pad
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
		LogLine("add player effect: "..effect.Name)
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
	ig.Begin(name, nil, MONSTER_WINDOW_FLAG)
	MonsterDetail(monster)
	ig.End()
end

function MonsterDetail(monster)
	local percent = monster.Health.Fraction
	local percentString = CenterAlignment(tostring(math.ceil(monster.Health.Current))..'/'..tostring(math.ceil(monster.Health.Max)), MONSTER_LINE_SIZE)
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
	local percentString = DecentralizedAlignment(name, tostring(math.ceil(part.Health.Current)) .. '/' .. tostring(math.ceil(part.Health.Max)), MONSTER_LINE_SIZE)
	ig.Text(percentString)

	local percent = part.Health.Fraction
	SetProgressBarColor(COLOR_HEALTH)
	ig.ProgressBar(percent, ig.ImVec2(MONSTER_LINE_WIDTH, 3), "")
end

function StatusEffect(effect)
	local name = effect.Name
	if (effect.TimesActivatedCount > 0) then
		name = name .. ' x' .. tostring(effect.TimesActivatedCount)
	end
	local percentString = DecentralizedAlignment(name, tostring(math.ceil(effect.Buildup.Current)) .. '/' .. tostring(math.ceil(effect.Buildup.Max)), MONSTER_LINE_SIZE)
	ig.Text(percentString)

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
	local timeRemaining = effect.EndTime - os.time()
	if (timeRemaining < 0) then
		RemovePlayerEffect(effect.Index)
		return
	end

	local text = effect.Name..' ('..tostring(math.ceil(timeRemaining))..')'
	ig.Text(text)
end

LogLine("---------- SmartHunter Widget Loaded ----------")
