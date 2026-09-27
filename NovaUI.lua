--[[
    NovaUI
    Compact UI Library
    Rayfield-style API, original implementation.
]]

local NovaUI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

NovaUI.Version = "0.1.0"
NovaUI.Flags = {}
NovaUI.Theme = {}

local Themes = {
    Default = {
        Background = Color3.fromRGB(18, 18, 20),
        Topbar = Color3.fromRGB(24, 24, 27),
        Element = Color3.fromRGB(27, 27, 31),
        ElementHover = Color3.fromRGB(34, 34, 39),
        Secondary = Color3.fromRGB(22, 22, 25),
        Stroke = Color3.fromRGB(55, 55, 62),
        Text = Color3.fromRGB(240, 240, 245),
        SubText = Color3.fromRGB(165, 165, 175),
        Accent = Color3.fromRGB(105, 105, 255),
        AccentHover = Color3.fromRGB(125, 125, 255),
        Input = Color3.fromRGB(15, 15, 18),
        Notification = Color3.fromRGB(25, 25, 29),
    },

    Dark = {
        Background = Color3.fromRGB(12, 12, 14),
        Topbar = Color3.fromRGB(19, 19, 22),
        Element = Color3.fromRGB(23, 23, 27),
        ElementHover = Color3.fromRGB(31, 31, 36),
        Secondary = Color3.fromRGB(18, 18, 21),
        Stroke = Color3.fromRGB(48, 48, 55),
        Text = Color3.fromRGB(245, 245, 245),
        SubText = Color3.fromRGB(150, 150, 160),
        Accent = Color3.fromRGB(90, 150, 255),
        AccentHover = Color3.fromRGB(110, 170, 255),
        Input = Color3.fromRGB(12, 12, 15),
        Notification = Color3.fromRGB(22, 22, 26),
    }
}

NovaUI.Theme.Default = Themes.Default
NovaUI.Theme.Dark = Themes.Dark

local currentTheme = Themes.Default
local activeWindow
local destroyed = false

local function getParent()
    local ok, hui = pcall(function()
        if gethui then
            return gethui()
        end
    end)

    if ok and hui then
        return hui
    end

    return CoreGui
end

local function tween(instance, properties, duration)
    TweenService:Create(
        instance,
        TweenInfo.new(
            duration or 0.2,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    ):Play()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color)
    local s = Instance.new("UIStroke")
    s.Color = color or currentTheme.Stroke
    s.Thickness = 1
    s.Transparency = 0
    s.Parent = parent
    return s
end

local function makeText(parent, text, size, color, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = color or currentTheme.Text
    label.TextSize = size or 14
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function getElementParent(tab)
    return tab._content
end

local function registerFlag(settings, object)
    if settings and settings.Flag then
        NovaUI.Flags[settings.Flag] = object
    end
end

local function addHover(frame)
    local original = frame.BackgroundColor3

    frame.MouseEnter:Connect(function()
        if frame.Parent then
            tween(frame, {
                BackgroundColor3 = currentTheme.ElementHover
            }, 0.15)
        end
    end)

    frame.MouseLeave:Connect(function()
        if frame.Parent then
            tween(frame, {
                BackgroundColor3 = original
            }, 0.15)
        end
    end)
end

local function createBaseElement(tab, height)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, height or 42)
    frame.BackgroundColor3 = currentTheme.Element
    frame.BorderSizePixel = 0
    frame.Parent = getElementParent(tab)

    corner(frame, 7)
    stroke(frame)

    return frame
end

function NovaUI:CreateWindow(settings)
    assert(
        type(settings) == "table",
        "NovaUI:CreateWindow expects a table"
    )

    if activeWindow then
        activeWindow:Destroy()
    end

    destroyed = false

    local gui = Instance.new("ScreenGui")
    gui.Name = settings.Name or "NovaUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = getParent()

    local main = Instance.new("Frame")
    main.Name = "Main"

    main.Size = UDim2.fromOffset(
        settings.Width or 520,
        settings.Height or 370
    )

    main.Position = UDim2.new(
        0.5,
        -(settings.Width or 520) / 2,
        0.5,
        -(settings.Height or 370) / 2
    )

    main.BackgroundColor3 = currentTheme.Background
    main.BorderSizePixel = 0
    main.Parent = gui

    corner(main, 10)
    stroke(main)

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 44)
    topbar.BackgroundColor3 = currentTheme.Topbar
    topbar.BorderSizePixel = 0
    topbar.Parent = main

    corner(topbar, 10)

    local title = makeText(
        topbar,
        settings.Name or "NovaUI",
        15,
        currentTheme.Text,
        true
    )

    title.Position = UDim2.fromOffset(14, 0)
    title.Size = UDim2.new(1, -125, 1, 0)

    local subtitle = makeText(
        topbar,
        settings.Subtitle or "",
        11,
        currentTheme.SubText,
        false
    )

    subtitle.Position = UDim2.fromOffset(14, 27)
    subtitle.Size = UDim2.new(1, -125, 0, 14)
    subtitle.Visible = settings.Subtitle ~= nil

    local minimize = Instance.new("TextButton")
    minimize.Name = "Minimize"
    minimize.Text = "−"
    minimize.TextSize = 20
    minimize.Font = Enum.Font.GothamBold
    minimize.TextColor3 = currentTheme.Text
    minimize.BackgroundTransparency = 1
    minimize.Size = UDim2.fromOffset(38, 38)
    minimize.Position = UDim2.new(1, -82, 0, 3)
    minimize.Parent = topbar

    local close = Instance.new("TextButton")
    close.Name = "Destroy"
    close.Text = "×"
    close.TextSize = 20
    close.Font = Enum.Font.GothamBold
    close.TextColor3 = currentTheme.Text
    close.BackgroundTransparency = 1
    close.Size = UDim2.fromOffset(38, 38)
    close.Position = UDim2.new(1, -42, 0, 3)
    close.Parent = topbar

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(8, 52)
    body.Size = UDim2.new(1, -16, 1, -60)
    body.Parent = main

    local tabs = Instance.new("ScrollingFrame")
    tabs.Name = "Tabs"
    tabs.Size = UDim2.new(0, 108, 1, 0)
    tabs.BackgroundTransparency = 1
    tabs.BorderSizePixel = 0
    tabs.ScrollBarThickness = 2
    tabs.CanvasSize = UDim2.new()
    tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabs.Parent = body

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.Padding = UDim.new(0, 5)
    tabsLayout.Parent = tabs

    local pages = Instance.new("Frame")
    pages.Name = "Pages"
    pages.Position = UDim2.new(0, 116, 0, 0)
    pages.Size = UDim2.new(1, -116, 1, 0)
    pages.BackgroundTransparency = 1
    pages.Parent = body

    local window = {
        GUI = gui,
        Main = main,
        _body = body,
        _tabs = tabs,
        _pages = pages,
        _tabsList = {},
        _minimized = false,
        _destroyed = false,
        _fullSize = main.Size,
        _fullPosition = main.Position,
    }

    activeWindow = window

    -- Dragging
    do
        local dragging = false
        local dragStart
        local startPos

        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                dragging = true
                dragStart = input.Position
                startPos = main.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then

                local delta = input.Position - dragStart

                main.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                dragging = false
            end
        end)
    end

    function window:SetVisibility(value)
        gui.Enabled = value
    end

    function window:IsVisible()
        return gui.Enabled
    end

    function window:Minimize()
        if window._minimized then
            return
        end

        window._minimized = true
        body.Visible = false

        tween(
            main,
            {
                Size = UDim2.fromOffset(
                    main.AbsoluteSize.X,
                    44
                )
            },
            0.25
        )

        minimize.Text = "+"
    end

    function window:Maximize()
        if not window._minimized then
            return
        end

        window._minimized = false

        tween(
            main,
            {
                Size = window._fullSize
            },
            0.25
        )

        task.delay(0.18, function()
            if not window._destroyed then
                body.Visible = true
            end
        end)

        minimize.Text = "−"
    end

    function window:ToggleMinimize()
        if window._minimized then
            window:Maximize()
        else
            window:Minimize()
        end
    end

    function window:Destroy()
        if window._destroyed then
            return
        end

        window._destroyed = true

        if gui then
            gui:Destroy()
        end

        if activeWindow == window then
            activeWindow = nil
        end
    end

    function window:ModifyTheme(theme)
        local newTheme

        if type(theme) == "string" then
            newTheme = Themes[theme]
        elseif type(theme) == "table" then
            newTheme = theme
        end

        if not newTheme then
            warn("NovaUI: theme not found")
            return
        end

        for key, value in pairs(newTheme) do
            currentTheme[key] = value
        end

        main.BackgroundColor3 = currentTheme.Background
        topbar.BackgroundColor3 = currentTheme.Topbar

        for _, tab in ipairs(window._tabsList) do
            tab.Button.BackgroundColor3 = currentTheme.Secondary
        end
    end

    minimize.MouseButton1Click:Connect(function()
        window:ToggleMinimize()
    end)

    close.MouseButton1Click:Connect(function()
        window:Destroy()
    end)

    function window:CreateTab(name, image, external)
        local tab = {
            Name = name,
            Image = image,
            _elements = {},
        }

        local button = Instance.new("TextButton")
        button.Name = name
        button.Text = name
        button.TextSize = 12
        button.Font = Enum.Font.GothamMedium
        button.TextColor3 = currentTheme.SubText
        button.BackgroundColor3 = currentTheme.Secondary
        button.BorderSizePixel = 0
        button.Size = UDim2.new(1, -4, 0, 32)
        button.AutoButtonColor = false
        button.Parent = tabs

        corner(button, 7)
        stroke(button)

        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize = UDim2.new()
        page.Visible = false
        page.Parent = pages

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.Parent = page

        local padding = Instance.new("UIPadding")
        padding.PaddingBottom = UDim.new(0, 8)
        padding.Parent = page

        tab.Button = button
        tab._content = page
        tab._window = window

        function tab:Select()
            for _, other in ipairs(window._tabsList) do
                other._content.Visible = false
                other.Button.BackgroundColor3 = currentTheme.Secondary
                other.Button.TextColor3 = currentTheme.SubText
            end

            page.Visible = true
            button.BackgroundColor3 = currentTheme.Accent
            button.TextColor3 = currentTheme.Text
        end

        function tab:CreateSection(text)
            local value = {}

            local section = Instance.new("TextLabel")
            section.Size = UDim2.new(1, -8, 0, 24)
            section.BackgroundTransparency = 1
            section.Text = text or "Section"
            section.TextColor3 = currentTheme.SubText
            section.TextSize = 12
            section.Font = Enum.Font.GothamBold
            section.TextXAlignment = Enum.TextXAlignment.Left
            section.Parent = page

            function value:Set(newText)
                section.Text = tostring(newText)
            end

            return value
        end

        function tab:CreateDivider()
            local value = {}

            local divider = Instance.new("Frame")
            divider.Size = UDim2.new(1, -8, 0, 1)
            divider.BackgroundColor3 = currentTheme.Stroke
            divider.BorderSizePixel = 0
            divider.Parent = page

            function value:Set(visible)
                divider.Visible = visible
            end

            return value
        end

        function tab:CreateButton(config)
            config = config or {}

            local value = {}
            local frame = createBaseElement(tab, 40)

            local buttonText = Instance.new("TextButton")
            buttonText.Size = UDim2.fromScale(1, 1)
            buttonText.BackgroundTransparency = 1
            buttonText.Text = config.Name or "Button"
            buttonText.TextColor3 = currentTheme.Text
            buttonText.TextSize = 13
            buttonText.Font = Enum.Font.GothamMedium
            buttonText.Parent = frame

            addHover(frame)

            buttonText.MouseButton1Click:Connect(function()
                if config.Callback then
                    task.spawn(config.Callback)
                end
            end)

            function value:SetText(text)
                buttonText.Text = tostring(text)
            end

            registerFlag(config, value)

            return value
        end

        function tab:CreateToggle(config)
            config = config or {}

            local value = {
                CurrentValue = config.CurrentValue == true
            }

            local frame = createBaseElement(tab, 42)

            local label = makeText(
                frame,
                config.Name or "Toggle",
                13,
                currentTheme.Text,
                false
            )

            label.Position = UDim2.fromOffset(12, 0)
            label.Size = UDim2.new(1, -70, 1, 0)

            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.fromOffset(42, 22)
            toggle.Position = UDim2.new(1, -54, 0.5, -11)
            toggle.Text = ""
            toggle.BackgroundColor3 =
                value.CurrentValue
                and currentTheme.Accent
                or currentTheme.Input

            toggle.Parent = frame

            corner(toggle, 11)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(16, 16)

            knob.Position =
                value.CurrentValue
                and UDim2.new(1, -19, 0.5, -8)
                or UDim2.new(0, 3, 0.5, -8)

            knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            knob.BorderSizePixel = 0
            knob.Parent = toggle

            corner(knob, 9)

            local function setToggle(state, fire)
                value.CurrentValue = state == true

                tween(toggle, {
                    BackgroundColor3 =
                        value.CurrentValue
                        and currentTheme.Accent
                        or currentTheme.Input
                }, 0.15)

                tween(knob, {
                    Position =
                        value.CurrentValue
                        and UDim2.new(1, -19, 0.5, -8)
                        or UDim2.new(0, 3, 0.5, -8)
                }, 0.15)

                if fire and config.Callback then
                    task.spawn(
                        config.Callback,
                        value.CurrentValue
                    )
                end
            end

            toggle.MouseButton1Click:Connect(function()
                setToggle(
                    not value.CurrentValue,
                    true
                )
            end)

            function value:Set(state)
                setToggle(state, true)
            end

            registerFlag(config, value)

            return value
        end

        function tab:CreateSlider(config)
            config = config or {}

            local range = config.Range or {0, 100}
            local min, max = range[1], range[2]
            local increment = config.Increment or 1
            local current = math.clamp(
                config.CurrentValue or min,
                min,
                max
            )

            local value = {
                CurrentValue = current
            }

            local frame = createBaseElement(tab, 58)

            local label = makeText(
                frame,
                config.Name or "Slider",
                13,
                currentTheme.Text,
                false
            )

            label.Position = UDim2.fromOffset(12, 5)
            label.Size = UDim2.new(1, -24, 0, 20)

            local valueText = makeText(
                frame,
                "",
                11,
                currentTheme.SubText,
                false
            )

            valueText.AnchorPoint = Vector2.new(1, 0)
            valueText.Position = UDim2.new(1, -12, 0, 6)
            valueText.Size = UDim2.fromOffset(100, 20)
            valueText.TextXAlignment = Enum.TextXAlignment.Right

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -24, 0, 5)
            bar.Position = UDim2.new(0, 12, 1, -13)
            bar.BackgroundColor3 = currentTheme.Input
            bar.BorderSizePixel = 0
            bar.Parent = frame

            corner(bar, 4)

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = currentTheme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = bar

            corner(fill, 4)

            local dragging = false

            local function updateFromX(x, fire)
                local percent = math.clamp(
                    (x - bar.AbsolutePosition.X)
                    / bar.AbsoluteSize.X,
                    0,
                    1
                )

                local raw =
                    min + (max - min) * percent

                local stepped =
                    math.floor(
                        (raw - min) / increment + 0.5
                    ) * increment + min

                stepped = math.clamp(
                    stepped,
                    min,
                    max
                )

                value.CurrentValue = stepped

                local p =
                    (stepped - min)
                    / (max - min)
                  function tab:CreateDropdown(config)
            config = config or {}

            local value = {
                CurrentOption = config.CurrentOption
                    or (config.Options and config.Options[1])
            }

            local frame = createBaseElement(tab, 42)

            local label = makeText(
                frame,
                config.Name or "Dropdown",
                13,
                currentTheme.Text,
                false
            )

            label.Position = UDim2.fromOffset(12, 0)
            label.Size = UDim2.new(0.5, 0, 1, 0)

            local selected = Instance.new("TextButton")
            selected.Size = UDim2.new(0.5, -12, 0, 28)
            selected.Position = UDim2.new(0.5, 0, 0.5, -14)
            selected.BackgroundColor3 = currentTheme.Input
            selected.BorderSizePixel = 0
            selected.TextColor3 = currentTheme.Text
            selected.TextSize = 11
            selected.Font = Enum.Font.Gotham
            selected.Text = tostring(value.CurrentOption or "Select")
            selected.Parent = frame

            corner(selected, 6)

            local list = Instance.new("Frame")
            list.Visible = false
            list.Size = UDim2.new(0.5, -12, 0, 0)
            list.Position = UDim2.new(0.5, 0, 1, 4)
            list.BackgroundColor3 = currentTheme.Input
            list.BorderSizePixel = 0
            list.ZIndex = 20
            list.Parent = frame

            corner(list, 6)
            stroke(list)

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 2)
            listLayout.Parent = list

            local function refresh()
                for _, child in ipairs(list:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                local options = config.Options or {}

                for _, option in ipairs(options) do
                    local optionButton = Instance.new("TextButton")

                    optionButton.Size = UDim2.new(1, -6, 0, 28)
                    optionButton.BackgroundColor3 = currentTheme.Secondary
                    optionButton.BorderSizePixel = 0
                    optionButton.Text = tostring(option)
                    optionButton.TextColor3 = currentTheme.Text
                    optionButton.TextSize = 11
                    optionButton.Font = Enum.Font.Gotham
                    optionButton.AutoButtonColor = false
                    optionButton.ZIndex = 21
                    optionButton.Parent = list

                    corner(optionButton, 5)

                    optionButton.MouseButton1Click:Connect(function()
                        value.CurrentOption = option
                        selected.Text = tostring(option)
                        list.Visible = false

                        if config.Callback then
                            task.spawn(
                                config.Callback,
                                option
                            )
                        end
                    end)
                end

                list.Size = UDim2.new(
                    0.5,
                    -12,
                    0,
                    math.min(#options * 30 + 6, 150)
                )
            end

            selected.MouseButton1Click:Connect(function()
                list.Visible = not list.Visible

                if list.Visible then
                    refresh()
                end
            end)

            function value:Set(option)
                value.CurrentOption = option
                selected.Text = tostring(option)

                if config.Callback then
                    task.spawn(
                        config.Callback,
                        option
                    )
                end
            end

            function value:Refresh(options)
                config.Options = options or {}
                refresh()
            end

            registerFlag(config, value)

            return value
        end

        function tab:CreateInput(config)
            config = config or {}

            local value = {
                CurrentValue = config.CurrentValue or ""
            }

            local frame = createBaseElement(tab, 50)

            local label = makeText(
                frame,
                config.Name or "Input",
                12,
                currentTheme.Text,
                false
            )

            label.Position = UDim2.fromOffset(12, 3)
            label.Size = UDim2.new(1, -24, 0, 18)

            local box = Instance.new("TextBox")

            box.Size = UDim2.new(1, -24, 0, 24)
            box.Position = UDim2.fromOffset(12, 23)

            box.BackgroundColor3 = currentTheme.Input
            box.BorderSizePixel = 0

            box.TextColor3 = currentTheme.Text
            box.PlaceholderColor3 = currentTheme.SubText

            box.TextSize = 11
            box.Font = Enum.Font.Gotham

            box.ClearTextOnFocus = false
            box.Text = tostring(value.CurrentValue)

            box.PlaceholderText =
                config.PlaceholderText or "Enter text..."

            box.Parent = frame

            corner(box, 5)

            box.FocusLost:Connect(function()
                value.CurrentValue = box.Text

                if config.Callback then
                    task.spawn(
                        config.Callback,
                        box.Text
                    )
                end
            end)

            function value:Set(text)
                value.CurrentValue = tostring(text)
                box.Text = value.CurrentValue

                if config.Callback then
                    task.spawn(
                        config.Callback,
                        value.CurrentValue
                    )
                end
            end

            registerFlag(config, value)

            return value
        end

        function tab:CreateKeybind(config)
            config = config or {}

            local value = {
                CurrentKeybind =
                    config.CurrentKeybind
                    or config.CurrentKey
                    or Enum.KeyCode.RightShift
            }

            local frame = createBaseElement(tab, 42)

            local label = makeText(
                frame,
                config.Name or "Keybind",
                13,
                currentTheme.Text,
                false
            )

            label.Position = UDim2.fromOffset(12, 0)
            label.Size = UDim2.new(0.55, 0, 1, 0)

            local bind = Instance.new("TextButton")

            bind.Size = UDim2.new(0.45, -12, 0, 28)
            bind.Position = UDim2.new(0.55, 0, 0.5, -14)

            bind.BackgroundColor3 = currentTheme.Input
            bind.BorderSizePixel = 0

            bind.TextColor3 = currentTheme.Text
            bind.TextSize = 11
            bind.Font = Enum.Font.Gotham

            bind.Text = value.CurrentKeybind.Name
            bind.Parent = frame

            corner(bind, 6)

            local listening = false

            bind.MouseButton1Click:Connect(function()
                if listening then
                    return
                end

                listening = true
                bind.Text = "Press key..."

                local connection

                connection = UserInputService.InputBegan:Connect(
                    function(input, processed)
                        if processed then
                            return
                        end

                        if input.UserInputType
                            == Enum.UserInputType.Keyboard then

                            value.CurrentKeybind = input.KeyCode
                            bind.Text = input.KeyCode.Name
                            listening = false

                            connection:Disconnect()

                            if config.Callback then
                                task.spawn(
                                    config.Callback,
                                    input.KeyCode
                                )
                            end
                        end
                    end
                )
            end)

            UserInputService.InputBegan:Connect(
                function(input, processed)
                    if processed or listening then
                        return
                    end

                    if input.KeyCode == value.CurrentKeybind then
                        if config.Callback then
                            task.spawn(
                                config.Callback,
                                input.KeyCode
                            )
                        end
                    end
                end
            )

            function value:Set(key)
                if typeof(key) == "EnumItem" then
                    value.CurrentKeybind = key
                    bind.Text = key.Name
                end
            end

            registerFlag(config, value)

            return value
        end

        function tab:CreateColorPicker(config)
            config = config or {}

            local value = {
                Color = config.Color
                    or config.CurrentColor
                    or Color3.fromRGB(255, 255, 255)
            }

            local frame = createBaseElement(tab, 42)

            local label = makeText(
                frame,
                config.Name or "Color",
                13,
                currentTheme.Text,
                false
            )

            label.Position = UDim2.fromOffset(12, 0)
            label.Size = UDim2.new(1, -70, 1, 0)

            local preview = Instance.new("TextButton")

            preview.Size = UDim2.fromOffset(36, 24)
            preview.Position = UDim2.new(1, -48, 0.5, -12)

            preview.BackgroundColor3 = value.Color
            preview.BorderSizePixel = 0
            preview.Text = ""

            preview.Parent = frame

            corner(preview, 6)
            stroke(preview)

            local popup = Instance.new("Frame")

            popup.Visible = false
            popup.Size = UDim2.fromOffset(220, 150)
            popup.Position = UDim2.new(1, -220, 1, 5)

            popup.BackgroundColor3 = currentTheme.Element
            popup.BorderSizePixel = 0
            popup.ZIndex = 50
            popup.Parent = frame

            corner(popup, 8)
            stroke(popup)

            local red = Instance.new("TextBox")
            local green = Instance.new("TextBox")
            local blue = Instance.new("TextBox")

            local boxes = {
                {red, "R"},
                {green, "G"},
                {blue, "B"},
            }

            for i, info in ipairs(boxes) do
                local box = info[1]

                box.Size = UDim2.new(
                    1,
                    -24,
                    0,
                    30
                )

                box.Position = UDim2.fromOffset(
                    12,
                    8 + (i - 1) * 36
                )

                box.BackgroundColor3 =
                    currentTheme.Input

                box.BorderSizePixel = 0

                box.TextColor3 =
                    currentTheme.Text

                box.PlaceholderText =
                    info[2]

                box.TextSize = 12
                box.Font = Enum.Font.Gotham

                box.ClearTextOnFocus = false

                box.Parent = popup

                corner(box, 5)
            end

            local function updateColor()
                local r = math.clamp(
                    tonumber(red.Text) or 255,
                    0,
                    255
                )

                local g = math.clamp(
                    tonumber(green.Text) or 255,
                    0,
                    255
                )

                local b = math.clamp(
                    tonumber(blue.Text) or 255,
                    0,
                    255
                )

                value.Color = Color3.fromRGB(
                    r,
                    g,
                    b
                )

                preview.BackgroundColor3 =
                    value.Color

                if config.Callback then
                    task.spawn(
                        config.Callback,
                        value.Color
                    )
                end
            end

            local initialR,
                initialG,
                initialB =
                value.Color.R * 255,
                value.Color.G * 255,
                value.Color.B * 255

            red.Text = tostring(
                math.floor(initialR + 0.5)
            )

            green.Text = tostring(
                math.floor(initialG + 0.5)
            )

            blue.Text = tostring(
                math.floor(initialB + 0.5)
            )

            red.FocusLost:Connect(updateColor)
            green.FocusLost:Connect(updateColor)
            blue.FocusLost:Connect(updateColor)

            preview.MouseButton1Click:Connect(function()
                popup.Visible = not popup.Visible
            end)

            function value:Set(color)
                if typeof(color) ~= "Color3" then
                    return
                end

                value.Color = color
                preview.BackgroundColor3 = color

                red.Text = tostring(
                    math.floor(color.R * 255 + 0.5)
                )

                green.Text = tostring(
                    math.floor(color.G * 255 + 0.5)
                )

                blue.Text = tostring(
                    math.floor(color.B * 255 + 0.5)
                )

                if config.Callback then
                    task.spawn(
                        config.Callback,
                        color
                    )
                end
            end

            registerFlag(config, value)

            return value
        end

        function tab:CreateLabel(text)
            local value = {}

            local label = makeText(
                page,
                tostring(text or ""),
                13,
                currentTheme.Text,
                false
            )

            label.Size = UDim2.new(
                1,
                -8,
                0,
                30
            )

            label.BackgroundColor3 =
                currentTheme.Element

            label.BackgroundTransparency = 0

            corner(label, 7)
            stroke(label)

            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 12)
            padding.Parent = label

            function value:Set(newText)
                label.Text = tostring(newText)
            end

            return value
        end

        function tab:CreateParagraph(config)
            config = config or {}

            local value = {}

            local frame = createBaseElement(
                tab,
                config.Content and 65 or 42
            )

            local title = makeText(
                frame,
                config.Title or "Paragraph",
                13,
                currentTheme.Text,
                true
            )

            title.Position =
                UDim2.fromOffset(12, 7)

            title.Size =
                UDim2.new(1, -24, 0, 20)

            local content = makeText(
                frame,
                config.Content or "",
                11,
                currentTheme.SubText,
                false
            )

            content.Position =
                UDim2.fromOffset(12, 28)

            content.Size =
                UDim2.new(1, -24, 0, 30)

            content.TextWrapped = true

            function value:Set(newConfig)
                if type(newConfig) == "table" then
                    if newConfig.Title then
                        title.Text =
                            tostring(newConfig.Title)
                    end

                    if newConfig.Content then
                        content.Text =
                            tostring(newConfig.Content)
                    end
                else
                    content.Text =
                        tostring(newConfig)
                end
            end

            return value
        end

        table.insert(
            window._tabsList,
            tab
        )

        button.MouseButton1Click:Connect(
            function()
                tab:Select()
            end
        )

        if #window._tabsList == 1 then
            tab:Select()
        end

        return tab
    end

    return window
        end
                
