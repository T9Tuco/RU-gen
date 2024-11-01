--[[
    Made by TucoT9
]]

-- GUI-Erstellung für NeonScripting
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local TextLabel = Instance.new("TextLabel")

-- GUI dem Spieler-Fenster hinzufügen
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Eigenschaften des Rahmens
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.5
Frame.Position = UDim2.new(0.5, -100, 0.1, 0)
Frame.Size = UDim2.new(0, 200, 0, 50)
Frame.AnchorPoint = Vector2.new(0.5, 0)

-- Eigenschaften des TextLabels
TextLabel.Parent = Frame
TextLabel.Text = "Skript von NeonScripting"
TextLabel.Font = Enum.Font.SourceSansBold
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 18
TextLabel.Size = UDim2.new(1, 0, 1, 0)
TextLabel.TextScaled = true
TextLabel.BackgroundTransparency = 1

-- Ursprüngliches Skript unten

-- Größe der Trefferbox, Transparenz und Benachrichtigungsstatus festlegen
local size = Vector3.new(25, 25, 25)
local trans = 1
local notifications = false

-- Startzeitpunkt des Skripts speichern
local start = os.clock()

-- Benachrichtigung senden, dass das Skript geladen wird
game.StarterGui:SetCore("SendNotification", {
   Title = "NeonScripting Skript",
   Text = "Skript wird geladen...",
   Icon = "",
   Duration = 5
})

-- ESP-Bibliothek laden und aktivieren
local esp = loadstring(game:HttpGet("https://raw.githubusercontent.com/T9Tuco/RU-gen/main/.required/esp.lua"))()
esp:Toggle(true)

-- ESP-Einstellungen konfigurieren
esp.Boxes = true
esp.Names = false
esp.Tracers = false
esp.Players = false

-- Objektüberwachung im Arbeitsbereich hinzufügen, um feindliche Modelle zu erkennen
esp:AddObjectListener(workspace, {
   Name = "soldier_model",
   Type = "Model",
   Color = Color3.fromRGB(255, 0, 4),

   -- Primäres Teil des Modells als HumanoidRootPart festlegen
   PrimaryPart = function(obj)
       local root
       repeat
           root = obj:FindFirstChild("HumanoidRootPart")
           task.wait()
       until root
       return root
   end,

   -- Validierungsfunktion zur Prüfung, dass Modelle kein "friendly_marker"-Kind haben
   Validator = function(obj)
       task.wait(1)
       if obj:FindFirstChild("friendly_marker") then
           return false
       end
       return true
   end,

   -- Einen benutzerdefinierten Namen für feindliche Modelle festlegen
   CustomName = "?",

   -- ESP für feindliche Modelle aktivieren
   IsEnabled = "enemy"
})

-- ESP für feindliche Modelle aktivieren
esp.enemy = true

-- Warten, bis das Spiel vollständig geladen ist, bevor Trefferboxen angewendet werden
task.wait(1)

-- Trefferboxen auf alle existierenden feindlichen Modelle im Arbeitsbereich anwenden
for _, v in pairs(workspace:GetDescendants()) do
   if v.Name == "soldier_model" and v:IsA("Model") and not v:FindFirstChild("friendly_marker") then
       local pos = v:FindFirstChild("HumanoidRootPart").Position
       for _, bp in pairs(workspace:GetChildren()) do
           if bp:IsA("BasePart") then
               local distance = (bp.Position - pos).Magnitude
               if distance <= 5 then
                   bp.Transparency = trans
                   bp.Size = size
               end
           end
       end
   end
end

-- Funktion zur Verarbeitung neuer Nachkommen, die dem Arbeitsbereich hinzugefügt werden
local function handleDescendantAdded(descendant)
   task.wait(1)

   -- Wenn der neue Nachkomme ein feindliches Modell ist und Benachrichtigungen aktiviert sind, sende eine Benachrichtigung
   if descendant.Name == "soldier_model" and descendant:IsA("Model") and not descendant:FindFirstChild("friendly_marker") then
       if notifications then
           game.StarterGui:SetCore("SendNotification", {
               Title = "NeonScripting Skript",
               Text = "[Warnung] Neuer Feind gespawnt! Trefferboxen angewendet.",
               Icon = "",
               Duration = 3
           })
       end

       -- Trefferboxen auf das neue feindliche Modell anwenden
       local pos = descendant:FindFirstChild("HumanoidRootPart").Position
       for _, bp in pairs(workspace:GetChildren()) do
           if bp:IsA("BasePart") then
               local distance = (bp.Position - pos).Magnitude
               if distance <= 5 then
                   bp.Transparency = trans
                   bp.Size = size
               end
           end
       end
   end
end

-- Funktion handleDescendantAdded mit dem Ereignis DescendantAdded des Arbeitsbereichs verbinden
task.spawn(function()
   game.Workspace.DescendantAdded:Connect(handleDescendantAdded)
end)

-- Endzeitpunkt des Skripts speichern
local finish = os.clock()

-- Berechnen, wie lange das Skript benötigt hat, und eine Bewertung für die Ladegeschwindigkeit bestimmen
local time = finish - start
local rating
if time < 3 then
   rating = "schnell"
elseif time < 5 then
   rating = "akzeptabel"
else
   rating = "langsam"
end

-- Benachrichtigung senden, die zeigt, wie lange das Skript benötigt hat und die Ladebewertung anzeigt
game.StarterGui:SetCore("SendNotification", {
   Title = "NeonScripting Skript",
   Text = string.format("Skript in %.2f Sekunden geladen (%s Ladezeit)", time, rating),
   Icon = "",
   Duration = 5
})
