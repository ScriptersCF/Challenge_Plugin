-- ScriptersCF Challenges; written by JoshRBX

local Version = "1.0A"

local Toolbar = plugin:CreateToolbar("ScriptersCF Challenges")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local UI = script.Parent.ChallengesUI
local Info = UI.Info
local List = UI.List
local Description = Info.Contents.Description
local TestCases = Info.Contents.TestCases
local TestButton = Info.Contents.tTitle.TestButton

local Widget
local Data

local Letters = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}

local dColours = {
	Easy = Color3.fromRGB(0, 200, 0),
	Medium = Color3.fromRGB(255, 170, 0),
	Hard = Color3.fromRGB(255, 0, 0)
}

local Difficulties = {
	Easy = 1,
	Medium = 2,
	Hard = 3
}

local FilterValues = {
	ShowCompleted = true,
	ShowEasy = true,
	ShowMedium = true,
	ShowHard = true
}

local Button = Toolbar:CreateButton(
	"Open",
	"View and attempt challenges set by members of the ScriptersCF community.",
	"rbxassetid://3246262407"
)

local function GetData()
	Data = HttpService:JSONDecode(HttpService:GetAsync("https://joshl.io/api/scf/challenges.json"))
	if Data.Version ~= Version then
		List.Notification.Visible = true
	end
end

local function CheckIfMatchesFilter(Challenge)
	local Matches = true
	for i, v in pairs(FilterValues) do
		if not v then
			if i == "ShowCompleted" then
				if Challenge.Complete.Visible then
					Matches = false
				end
			else
				if Data.Challenges[Challenge.Title.Text].Difficulty == i:sub(5) then
					Matches = false
				end
			end
		end
	end
	return Matches
end

local function GenerateScript(ID, Challenge)
	local Env = Instance.new("ModuleScript")
	Env.Source = "-- Challenge submitted by " .. Challenge.Author .. "\n\nreturn function(Input)\n\t\n\t\n\treturn Input\nend"
	local _, Count = Challenge.Tests[1].Input:gsub(",", "")
	if Count >= 1 and Challenge.Type ~= "Table" then
		local Table = {}
		for i = 1, Count + 1 do
			Table[i] = Letters[i]
		end
		Env.Source = Env.Source:gsub("Input", table.concat(Table, ", "))
	end
	Env.Name = ID
	Env.Parent = HttpService
	plugin:OpenScript(Env)
end

local function SetupEnvironment(ID)
	local Challenge = Data.Challenges[ID]
	Info.Title.Text = ID
	Description.Text = Challenge.Description
	local Length = TextService:GetTextSize(Challenge.Description, 16, Enum.Font.Gotham, Vector2.new(Description.AbsoluteSize.X, 10000))
	Description.Size = UDim2.new(1, -12, 0, Length.Y)
	
	Info.Contents.tTitle.Position = UDim2.new(0, 0, 0, 60 + Description.AbsoluteSize.Y)
	TestCases.Position = UDim2.new(0, 10, 0, 40 + Info.Contents.tTitle.Position.Y.Offset)
	
	for i, v in pairs(Challenge.Tests) do
		local Box = TestCases["TestCase" .. i]
		Box.Input.Value.Text = v.Input
		Box.Output.Value.Text = v.Output
		Box.Input.CanvasSize = UDim2.new(0, TextService:GetTextSize(v.Input, 16, Enum.Font.Code, Vector2.new(10000, 100)).X, 0, 0)
		Box.Output.CanvasSize = UDim2.new(0, TextService:GetTextSize(v.Output, 16, Enum.Font.Code, Vector2.new(10000, 100)).X, 0, 0)
	end
	
	Info.Contents.CanvasSize = UDim2.new(0, 0, 0, TestCases.AbsoluteSize.Y + TestCases.Position.Y.Offset)
	
	if ID == "Tutorial" then
		if HttpService:FindFirstChild("Tutorial") then
			plugin:OpenScript(HttpService.Tutorial)
		else
			local Env = script.Tutorial:Clone()
			Env.Parent = HttpService
			plugin:OpenScript(Env)
		end
	else
		if HttpService:FindFirstChild(ID) then
			plugin:OpenScript(game.HttpService[ID])
		else
			GenerateScript(ID, Challenge)
		end
	end
end

local function GenerateList()
	for i, v in pairs(List.Contents:GetChildren()) do
		if v.Name ~= "ButtonTemplate" and v.Name ~= "UIListLayout" then
			v:Destroy()
		end
	end
	for i, v in pairs(Data.Challenges) do
		local Button = List.Contents.ButtonTemplate:Clone()
		if plugin:GetSetting("Progress")[i] then
			Button.Complete.Visible = true
		end
		Button.Title.TextColor3 = dColours[v.Difficulty]
		Button.Title.Text = i
		Button.Author.Text = "Submitted by " .. v.Author
		Button.Visible = true
		Button.Name = Difficulties[v.Difficulty] .. i
		
		Button.TryButton.MouseButton1Click:Connect(function()
			SetupEnvironment(i)
			List:TweenPosition(UDim2.new(-1, 0, 0, 0), "Out", "Linear", 0.3)
			Info.Position = UDim2.new(1, 0, 0, 0)
			Info.Visible = true
			Info:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.3)
			wait(1)
			if List.Position == UDim2.new(-1, 0, 0, 0) then
				List.Visible = false
			end
		end)
		
		Button.Parent = List.Contents
	end
	List.SearchBar.Text = " "
	List.SearchBar.Text = ""
end

local function SetupSidebar(IsTutorial)
	GetData()
	for i, v in pairs(game.PluginGuiService:GetChildren()) do
		if v:IsA("DockWidgetPluginGui") then
			if v.Title == "Challenges" then
				v.Enabled = false
			end
		end
	end
	local WidgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Left, true, true)
	Widget = plugin:CreateDockWidgetPluginGui(HttpService:GenerateGUID(), WidgetInfo)
	Widget.Title = "Challenges"
	Info.Parent = Widget
	List.Parent = Widget
	Info.Visible = IsTutorial
	GenerateList()
	List.Visible = not IsTutorial
end

local function PrepareInput(Value, Type)
	if Type == "Table" then
		return HttpService:JSONDecode(Value)
	elseif Type == "String" then
		return unpack(Value:split(", "))
	elseif Type == "Number" then
		local Table = Value:split(", ")
		for i, v in pairs(Table) do
			if tonumber(v) then
				Table[i] = tonumber(v)
			end
		end
		return unpack(Table)
	end
end

local function CheckResult(Result, Solution)
	if typeof(Result) == "table" then
		return HttpService:JSONDecode(Solution) == Result
	elseif typeof(Result) == "number" or typeof(Result) == "boolean" then
		return tostring(Result) == Solution
	end
	return tostring(Solution) == tostring(Result)
end

local function CloseEnv()
	local Script = HttpService:FindFirstChild(Info.Title.Text)
	Script:Clone().Parent = HttpService
	Script:Destroy()
	
	Info:TweenPosition(UDim2.new(1, 0, 0, 0), "Out", "Linear", 0.3)
	List.Position = UDim2.new(-1, 0, 0, 0)
	List.Visible = true
	List:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.3)
	wait(1)
	if Info.Position == UDim2.new(1, 0, 0, 0) then
		Info.Visible = false
	end
end

local function GetElementOfList(Name)
	for i, v in pairs(List.Contents:GetChildren()) do
		if v.Name:sub(2) == Name then
			return v
		end
	end
end

local function ValidateSolution(Name, Challenge, Script)
	local Correct = 0
	print("Validating...")
	local NewModule = Script:Clone()
	NewModule.Source = "function print() end function warn() end function error() end " .. NewModule.Source
	local Function = require(NewModule)
	for i, v in pairs(Challenge.Validators) do
		local Result = CheckResult(Function(PrepareInput(v.Input, Challenge.Type)), v.Output)
		if Result then
			Correct = Correct + 1
		end
	end
	NewModule:Destroy()
	if Correct == 4 then
		print("Passed all validators!")
		local Progress = plugin:GetSetting("Progress")
		Progress[Name] = true
		plugin:SetSetting("Progress", Progress)
		GetElementOfList(Name).Complete.Visible = true
		CloseEnv()
	else
		warn("Failed " .. 4 - Correct .. " validators. Is your solution hard-coded?")
	end
end

List.SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
	local Size = 0
	local Query = List.SearchBar.Text:gsub("%W+", ""):lower()
	for i, v in pairs(List.Contents:GetChildren()) do
		if v.Name ~= "ButtonTemplate" and v.Name ~= "UIListLayout" then
			v.Visible = false
			if (v.Title.Text:lower():gsub("%W+", ""):find(Query) or v.Author.Text:lower():gsub("%W+", ""):find(Query)) and CheckIfMatchesFilter(v) then
				v.Visible = true
				Size = Size + 70
			end
		end
	end
	List.Contents.CanvasSize = UDim2.new(0, 0, 0, Size)
end)

List.SearchBar.Filter.MouseButton1Click:Connect(function()
	List.Filter.Visible = not List.Filter.Visible
end)

for i, v in pairs(List.Filter:GetChildren()) do
	v.TickBox.MouseButton1Click:Connect(function()
		if v.TickBox.Image ~= "" then
			v.TickBox.Image = ""
			FilterValues[v.Name] = false
		else
			v.TickBox.Image = "rbxassetid://54653911"
			FilterValues[v.Name] = true
		end
		local Original = List.SearchBar.Text
		if Original:sub(1, 1) == " " then
			List.SearchBar.Text = Original:sub(2)
		else
			List.SearchBar.Text = " " .. Original
		end
	end)
end

List.Notification.MouseEnter:Connect(function()
	List.Notification.Notice.Visible = true
end)

List.Notification.MouseLeave:Connect(function()
	List.Notification.Notice.Visible = false
end)

TestButton.MouseButton1Click:Connect(function()
	local NewModule
	local TestCount = 0
	local Success, Error = pcall(function()
		local Module = HttpService:FindFirstChild(Info.Title.Text)
		NewModule = Module:Clone()
		if Data.Challenges[Info.Title.Text].HttpDisabled then
			local Source = NewModule.Source
			if Source:find("HttpService") or Source:find(":GetAsync") or Source:find(":RequestAsync") then
				error("Using HttpService is not permitted in this challenge.")
			end
		end
		local Function = require(NewModule)
		local Correct = 0
		print("\nResults:")
		for i, v in pairs(Data.Challenges[Info.Title.Text].Tests) do
			TestCount = TestCount + 1
			local Result = Function(PrepareInput(v.Input, Data.Challenges[Info.Title.Text].Type))
			local IsCorrect = CheckResult(Result, v.Output)
			if IsCorrect then
				print("Test Case " .. tostring(i) .. ": " .. tostring(Result) .. " [CORRECT]")
				Correct = Correct + 1
			else
				print("Test Case " .. tostring(i) .. ": " .. tostring(Result) .. " [INCORRECT]")
			end
		end
		if Correct == 4 then
			ValidateSolution(Info.Title.Text, Data.Challenges[Info.Title.Text], NewModule)
		else
			warn("You need to satisfy " .. 4 - Correct .. " more test cases to continue.")
		end
	end)
	if not Success then
--		local LineNo = Error:match("%:%d+%:"):sub(2, -2)
--		local Message = Error:gsub(".+:", ""):sub(2)
		warn("Error in Test Case " .. TestCount .. ": " .. Error)
	end
	if NewModule then
		NewModule:Destroy()
	end
end)

Button.Click:Connect(function()
	if plugin:GetSetting("Progress") then
		SetupSidebar()
	else
		plugin:SetSetting("Progress", {})
		UI.Welcome.Visible = true
	end
end)

UI.Welcome.NextButton.MouseButton1Click:Connect(function()
	if UI.Welcome.NextButton.Text ~= "Next" then return end
	
	UI.Welcome.NextButton.Style = Enum.ButtonStyle.RobloxRoundButton
	UI.Welcome.NextButton.Text = ""
	local Loading = UI.Welcome.NextButton.Loading
	local Success
	
	spawn(function()
		Loading.Visible = true
		while Success == nil and wait() do
			Loading.Rotation = Loading.Rotation + 5
		end
	end)
	
	Success = pcall(function()
		HttpService:GetAsync("https://joshl.io/api/scf/connected.txt")
	end)
	
	if Success then
		UI.Welcome:TweenPosition(UDim2.new(1.5, 0, 0.5, 0))
		SetupSidebar(true)
		SetupEnvironment("Tutorial")
	else
		UI.Welcome.NextButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
		UI.Welcome.NextButton.Text = "Next"
	end
end)

Info.BackButton.MouseButton1Click:Connect(CloseEnv)

if game.CoreGui:FindFirstChild("ChallengesUI") then
	game.CoreGui.ChallengesUI:Destroy()
end

UI.Parent = game.CoreGui

if HttpService:FindFirstChild("Tutorial") then
	SetupSidebar()
end
