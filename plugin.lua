local shared = odh_shared_plugins

local BombJump = shared.CreateTab("Bomb Jump+", "/aux0on/BJPIcon/refs/heads/main/Untitled163_20260918201001")

local aboutSection = BombJump:AddSection("About", "Information")
aboutSection:AddParagraph("Bomb Jump+", "Plugin Made by @lzzzx")

local section = BombJump:AddSection("Bomb Jump+", "Main")
section:AddToggle("Test Toggle", function(bool) end)

pcall(function() shared.Notify("Bomb Jump+ Loaded", 2) end)
