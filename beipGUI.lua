-- Ваш собственный GUI библиотека
local MyGUI = {}

-- Загрузка шрифтов и других ресурсов (пример)
local function loadResources()
    -- Здесь может быть загрузка шрифтов, иконок и т.д.
end

-- Основное окно
function MyGUI:CreateWindow(options)
    options = options or {}
    local title = options.Title or "MyGUI Window"
    local subtitle = options.Subtitle or ""
    
    -- Создание основного экземпляра окна
    local WindowInstance = {
        Tabs = {}
    }
    
    -- Внутренние функции
    local function createBaseWindow()
        -- Здесь создается базовое окно
        -- Это примерный код, в реальности нужно использовать Roblox UI элементы
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MyGUI_"..tostring(math.random(1, 10000))
        screenGui.Parent = game:GetService("CoreGui")
        
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, 500, 0, 400)
        mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        mainFrame.Parent = screenGui
        
        -- Заголовок окна
        local titleFrame = Instance.new("Frame")
        titleFrame.Name = "TitleFrame"
        titleFrame.Size = UDim2.new(1, 0, 0, 40)
        titleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        titleFrame.Parent = mainFrame
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "TitleLabel"
        titleLabel.Text = title
        titleLabel.Size = UDim2.new(1, -20, 1, 0)
        titleLabel.Position = UDim2.new(0, 10, 0, 0)
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 18
        titleLabel.BackgroundTransparency = 1
        titleLabel.Parent = titleFrame
        
        if subtitle ~= "" then
            local subtitleLabel = Instance.new("TextLabel")
            subtitleLabel.Name = "SubtitleLabel"
            subtitleLabel.Text = subtitle
            subtitleLabel.Size = UDim2.new(1, -20, 0, 14)
            subtitleLabel.Position = UDim2.new(0, 10, 0, 22)
            subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            subtitleLabel.Font = Enum.Font.Gotham
            subtitleLabel.TextSize = 12
            subtitleLabel.BackgroundTransparency = 1
            subtitleLabel.Parent = titleFrame
        end
        
        -- Тело окна
        local bodyFrame = Instance.new("Frame")
        bodyFrame.Name = "BodyFrame"
        bodyFrame.Size = UDim2.new(1, 0, 1, -40)
        bodyFrame.Position = UDim2.new(0, 0, 0, 40)
        bodyFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        bodyFrame.Parent = mainFrame
        
        -- Табы
        local tabButtonsFrame = Instance.new("Frame")
        tabButtonsFrame.Name = "TabButtonsFrame"
        tabButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
        tabButtonsFrame.BackgroundTransparency = 1
        tabButtonsFrame.Parent = bodyFrame
        
        local tabContentFrame = Instance.new("Frame")
        tabContentFrame.Name = "TabContentFrame"
        tabContentFrame.Size = UDim2.new(1, 0, 1, -30)
        tabContentFrame.Position = UDim2.new(0, 0, 0, 30)
        tabContentFrame.BackgroundTransparency = 1
        tabContentFrame.ClipsDescendants = true
        tabContentFrame.Parent = bodyFrame
        
        WindowInstance.ScreenGui = screenGui
        WindowInstance.MainFrame = mainFrame
        WindowInstance.TabButtonsFrame = tabButtonsFrame
        WindowInstance.TabContentFrame = tabContentFrame
        
        return WindowInstance
    end
    
    -- Инициализация окна
    createBaseWindow()
    
    -- Методы для работы с окном
    function WindowInstance:CreateTab(options)
        options = options or {}
        local tabName = options.Name or "New Tab"
        
        local TabInstance = {
            Name = tabName,
            Elements = {}
        }
        
        -- Создание кнопки таба
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName.."TabButton"
        tabButton.Text = tabName
        tabButton.Size = UDim2.new(0, 100, 1, 0)
        tabButton.Position = UDim2.new(0, #WindowInstance.Tabs * 100, 0, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.Font = Enum.Font.Gotham
        tabButton.TextSize = 14
        tabButton.Parent = WindowInstance.TabButtonsFrame
        
        -- Создание контента таба
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tabName.."TabContent"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.Position = UDim2.new(0, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = #WindowInstance.Tabs == 0 -- Показывать только первый таб
        tabContent.ScrollingDirection = Enum.ScrollingDirection.Y
        tabContent.ScrollBarThickness = 5
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabContent.Parent = WindowInstance.TabContentFrame
        
        local tabContentLayout = Instance.new("UIListLayout")
        tabContentLayout.Name = "Layout"
        tabContentLayout.Padding = UDim.new(0, 5)
        tabContentLayout.Parent = tabContent
        
        TabInstance.Button = tabButton
        TabInstance.Content = tabContent
        
        -- Обработчик клика по кнопке таба
        tabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(WindowInstance.Tabs) do
                tab.Content.Visible = false
                tab.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            end
            tabContent.Visible = true
            tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        end)
        
        -- Активируем первый таб
        if #WindowInstance.Tabs == 0 then
            tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        end
        
        table.insert(WindowInstance.Tabs, TabInstance)
        
        -- Методы для работы с табом
        function TabInstance:CreateButton(options)
            options = options or {}
            local buttonName = options.Name or "New Button"
            local callback = options.Callback or function() end
            
            local button = Instance.new("TextButton")
            button.Name = buttonName.."Button"
            button.Text = buttonName
            button.Size = UDim2.new(1, -20, 0, 30)
            button.Position = UDim2.new(0, 10, 0, #self.Elements * 35 + 10)
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.Gotham
            button.TextSize = 14
            button.Parent = self.Content
            
            button.MouseButton1Click:Connect(callback)
            
            table.insert(self.Elements, button)
            
            return {
                SetText = function(text)
                    button.Text = text
                end,
                SetCallback = function(newCallback)
                    callback = newCallback
                end
            }
        end
        
        function TabInstance:CreateToggle(options)
            options = options or {}
            local toggleName = options.Name or "New Toggle"
            local defaultValue = options.Default or false
            local callback = options.Callback or function() end
            
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Name = toggleName.."Toggle"
            toggleFrame.Size = UDim2.new(1, -20, 0, 30)
            toggleFrame.Position = UDim2.new(0, 10, 0, #self.Elements * 35 + 10)
            toggleFrame.BackgroundTransparency = 1
            toggleFrame.Parent = self.Content
            
            local toggleText = Instance.new("TextLabel")
            toggleText.Name = "Text"
            toggleText.Text = toggleName
            toggleText.Size = UDim2.new(0.7, 0, 1, 0)
            toggleText.Position = UDim2.new(0, 0, 0, 0)
            toggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggleText.Font = Enum.Font.Gotham
            toggleText.TextSize = 14
            toggleText.TextXAlignment = Enum.TextXAlignment.Left
            toggleText.BackgroundTransparency = 1
            toggleText.Parent = toggleFrame
            
            local toggleButton = Instance.new("TextButton")
            toggleButton.Name = "ToggleButton"
            toggleButton.Size = UDim2.new(0, 50, 0, 25)
            toggleButton.Position = UDim2.new(1, -50, 0.5, -12.5)
            toggleButton.Text = ""
            toggleButton.BackgroundColor3 = defaultValue and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(70, 70, 70)
            toggleButton.Parent = toggleFrame
            
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 12)
            toggleCorner.Parent = toggleButton
            
            local toggleState = defaultValue
            
            toggleButton.MouseButton1Click:Connect(function()
                toggleState = not toggleState
                toggleButton.BackgroundColor3 = toggleState and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(70, 70, 70)
                callback(toggleState)
            end)
            
            table.insert(self.Elements, toggleFrame)
            
            return {
                SetValue = function(value)
                    toggleState = value
                    toggleButton.BackgroundColor3 = toggleState and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(70, 70, 70)
                end,
                GetValue = function()
                    return toggleState
                end
            }
        end
        
        return TabInstance
    end
    
    function WindowInstance:Destroy()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
        end
    end
    
    return WindowInstance
end
