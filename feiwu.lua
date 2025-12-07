local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 创建主窗口
local Window = Rayfield:CreateWindow({
    Name = "飞舞hub",
    LoadingTitle = "加载中...",
    LoadingSubtitle = "飞舞hub",
    ConfigurationSaving = {
        Enabled = false,
    },
})

-- 创建标签页
local Tab1 = Window:CreateTab("人物")
local Tab2 = Window:CreateTab("标签页2")
local Tab3 = Window:CreateTab("标签页3")

-- 1. 切换开关(Toggle)示例
local ToggleExample = Tab1:CreateToggle({
    Name = "无线跳跃",
    CurrentValue = false,
    Flag = "ToggleExample",
    Callback = function(Value)
        if Value then
            -- Note: infinite jump logic needs valid undefined variables (addcmd, UserInputService, speaker)
            print("Infinite Jump Toggled: ", Value)
        else
            print("Infinite Jump Toggled: ", Value)
        end
    end,

-- 2. 下拉菜单(Dropdown)示例
local DropdownExample = Tab1:CreateDropdown({
    Name = "下拉菜单示例",
    Options = {"选项1", "选项2", "选项3"},
    CurrentOption = "选项1",
    MultipleOptions = false,
    Flag = "DropdownExample",
    Callback = function(Option)
        print("选择的选项:", Option)
    end,
})

-- 3. 多选下拉菜单示例
local MultiDropdownExample = Tab1:CreateDropdown({
    Name = "多选下拉菜单示例",
    Options = {"苹果", "香蕉", "橙子", "葡萄"},
    CurrentOption = {"苹果", "香蕉"},
    MultipleOptions = true,
    Flag = "MultiDropdownExample",
    Callback = function(Options)
        print("选择的多个选项:", table.concat(Options, ", "))
    end,
})

-- 4. 滑块(Slider)示例
local SliderExample = Tab1:CreateSlider({
    Name = "滑块示例",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 50,
    Flag = "SliderExample",
    Callback = function(Value)
        print("滑块值:", Value)
    end,
})

-- 5. 颜色选择器(ColorPicker)示例
local ColorPickerExample = Tab2:CreateColorPicker({
    Name = "颜色选择器示例",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Color)
        print("选择的颜色:", Color)
    end
})

-- 6. 按钮(Button)示例
local ButtonExample = Tab2:CreateButton({
    Name = "按钮示例",
    Callback = function()
        print("按钮被点击了!")
    end,
})

-- 7. 输入框(TextBox)示例
local TextBoxExample = Tab2:CreateInput({
    Name = "输入框示例",
    PlaceholderText = "输入一些文字...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        print("输入的文本:", Text)
    end,
})

-- 8. 键位绑定(Keybind)示例
local KeybindExample = Tab3:CreateKeybind({
    Name = "键位绑定示例",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Flag = "KeybindExample", 
    Callback = function(Keybind)
        print("按下的键:", Keybind)
    end,
})

-- 9. 标签(Label)示例
local LabelExample = Tab3:CreateLabel({
    Name = "标签示例",
    Content = "这是一个静态文本标签",
})

-- 10. 段落(Paragraph)示例
local ParagraphExample = Tab3:CreateParagraph({
    Title = "段落标题",
    Content = "这是一个多行文本段落，可以显示更长的说明性文本。\n这是第二行内容。"
})

-- 11. 通知(Notify)示例
local NotifyButton = Tab3:CreateButton({
    Name = "显示通知示例",
    Callback = function()
        Rayfield:Notify({
            Title = "通知示例",
            Content = "这是一个通知消息!",
            Duration = 5,
            Image = 4483362458,
            Actions = {
                Ignore = {
                    Name = "忽略",
                    Callback = function()
                        print("用户点击了忽略")
                    end
                },
            },
        })
    end,
})

-- 12. 部分(Section)示例
local SectionExample = Tab3:CreateSection("部分标题示例")

-- 在部分中添加元素
local SectionToggle = Tab3:CreateToggle({
    Name = "部分中的切换开关",
    CurrentValue = true,
    Flag = "SectionToggle",
    Callback = function(Value)
        print("部分中的开关:", Value)
    end
})
