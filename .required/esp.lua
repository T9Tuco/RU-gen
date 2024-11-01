-- Einstellungen --
local ESP = {
    Enabled = false,
    Boxes = true,
    BoxShift = CFrame.new(0, -1.5, 0),
    BoxSize = Vector3.new(4, 6, 0),
    Color = Color3.fromRGB(255, 170, 0),
    FaceCamera = false,
    Names = true,
    TeamColor = true,
    Thickness = 2,
    AttachShift = 1,
    TeamMates = true,
    Players = true,
    
    Objects = setmetatable({}, {__mode="kv"}),
    Overrides = {}
}

-- Deklarationen --
local cam
local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()

local V3new = Vector3.new

-- Funktionen --
local function Draw(obj, props)
    local new = Drawing.new(obj)
    
    props = props or {}
    for i, v in pairs(props) do
        new[i] = v
    end
    return new
end

-- Funktion zur Ermittlung des Teams eines Spielers --
function ESP:GetTeam(p)
    local ov = self.Overrides.GetTeam
    if ov then
        return ov(p)
    end
    
    return p and p.Team
end

-- Prüfen, ob ein Spieler ein Teamkamerad ist --
function ESP:IsTeamMate(p)
    local ov = self.Overrides.IsTeamMate
    if ov then
        return ov(p)
    end
    
    return self:GetTeam(p) == self:GetTeam(plr)
end

-- Ermittelt die Farbe für das ESP-Objekt --
function ESP:GetColor(obj)
    local ov = self.Overrides.GetColor
    if ov then
        return ov(obj)
    end
    local p = self:GetPlrFromChar(obj)
    return p and self.TeamColor and p.Team and p.Team.TeamColor.Color or self.Color
end

-- Funktion, um den Spieler aus einem Charaktermodell zu ermitteln --
function ESP:GetPlrFromChar(char)
    local ov = self.Overrides.GetPlrFromChar
    if ov then
        return ov(char)
    end
    
    return plrs:GetPlayerFromCharacter(char)
end

-- Aktiviert oder deaktiviert das ESP --
function ESP:Toggle(bool)
    self.Enabled = bool
    if not bool then
        for i, v in pairs(self.Objects) do
            if v.Type == "Box" then
                if v.Temporary then
                    v:Remove()
                else
                    for i, v in pairs(v.Components) do
                        v.Visible = false
                    end
                end
            end
        end
    end
end

-- Gibt die Box-Komponente für das Objekt zurück --
function ESP:GetBox(obj)
    return self.Objects[obj]
end

-- Fügt einen Objekt-Listener hinzu, um neue Objekte zu erkennen und zu markieren --
function ESP:AddObjectListener(parent, options)
    local function NewListener(c)
        if type(options.Type) == "string" and c:IsA(options.Type) or options.Type == nil then
            if type(options.Name) == "string" and c.Name == options.Name or options.Name == nil then
                if not options.Validator or options.Validator(c) then
                    local box = ESP:Add(c, {
                        PrimaryPart = type(options.PrimaryPart) == "string" and c:WaitForChild(options.PrimaryPart) or type(options.PrimaryPart) == "function" and options.PrimaryPart(c),
                        Color = type(options.Color) == "function" and options.Color(c) or options.Color,
                        ColorDynamic = options.ColorDynamic,
                        Name = type(options.CustomName) == "function" and options.CustomName(c) or options.CustomName,
                        IsEnabled = options.IsEnabled,
                        RenderInNil = options.RenderInNil
                    })
                    -- Zusätzliche Einstellungen für das Hinzufügen von Optionen --
                    if options.OnAdded then
                        coroutine.wrap(options.OnAdded)(box)
                    end
                end
            end
        end
    end

    -- Verbindungen hinzufügen, um bei Änderungen neue Objekte zu erkennen --
    if options.Recursive then
        parent.DescendantAdded:Connect(NewListener)
        for i, v in pairs(parent:GetDescendants()) do
            coroutine.wrap(NewListener)(v)
        end
    else
        parent.ChildAdded:Connect(NewListener)
        for i, v in pairs(parent:GetChildren()) do
            coroutine.wrap(NewListener)(v)
        end
    end
end

-- Basisklasse für Box-Komponenten --
local boxBase = {}
boxBase.__index = boxBase

-- Entfernt eine Box-Komponente --
function boxBase:Remove()
    ESP.Objects[self.Object] = nil
    for i, v in pairs(self.Components) do
        v.Visible = false
        v:Remove()
        self.Components[i] = nil
    end
end

-- Aktualisiert die Box-Komponente --
function boxBase:Update()
    if not self.PrimaryPart then
        return self:Remove()
    end

    local color
    if ESP.Highlighted == self.Object then
        color = ESP.HighlightColor
    else
        color = self.Color or self.ColorDynamic and self:ColorDynamic() or ESP:GetColor(self.Object) or ESP.Color
    end

    local allow = true
    if ESP.Overrides.UpdateAllow and not ESP.Overrides.UpdateAllow(self) then
        allow = false
    end
    if self.Player and not ESP.TeamMates and ESP:IsTeamMate(self.Player) then
        allow = false
    end
    if self.Player and not ESP.Players then
        allow = false
    end
    if self.IsEnabled and (type(self.IsEnabled) == "string" and not ESP[self.IsEnabled] or type(self.IsEnabled) == "function" and not self:IsEnabled()) then
        allow = false
    end
    if not workspace:IsAncestorOf(self.PrimaryPart) and not self.RenderInNil then
        allow = false
    end

    -- Sichtbarkeit und Position der Boxen berechnen und festlegen --
    if ESP.Highlighted == self.Object then
        color = ESP.HighlightColor
    end

    local cf = self.PrimaryPart.CFrame
    if ESP.FaceCamera then
        cf = CFrame.new(cf.p, cam.CFrame.p)
    end
    local size = self.Size
    local locs = {
        TopLeft = cf * ESP.BoxShift * CFrame.new(size.X/2, size.Y/2, 0),
        TopRight = cf * ESP.BoxShift * CFrame.new(-size.X/2, size.Y/2, 0),
        BottomLeft = cf * ESP.BoxShift * CFrame.new(size.X/2, -size.Y/2, 0),
        BottomRight = cf * ESP.BoxShift * CFrame.new(-size.X/2, -size.Y/2, 0),
        TagPos = cf * ESP.BoxShift * CFrame.new(0, size.Y/2, 0),
        Torso = cf * ESP.BoxShift
    }

    -- Boxen erstellen, wenn aktiv --
    if ESP.Boxes then
        local TopLeft, Vis1 = cam:WorldToViewportPoint(locs.TopLeft.p)
        local TopRight, Vis2 = cam:WorldToViewportPoint(locs.TopRight.p)
        local BottomLeft, Vis3 = cam:WorldToViewportPoint(locs.BottomLeft.p)
        local BottomRight, Vis4 = cam:WorldToViewportPoint(locs.BottomRight.p)

        if self.Components.Quad then
            if Vis1 or Vis2 or Vis3 or Vis4 then
                self.Components.Quad.Visible = true
                self.Components.Quad.PointA = Vector2.new(TopRight.X, TopRight.Y)
                self.Components.Quad.PointB = Vector2.new(TopLeft.X, TopLeft.Y)
                self.Components.Quad.PointC = Vector2.new(BottomLeft.X, BottomLeft.Y)
                self.Components.Quad.PointD = Vector2.new(BottomRight.X, BottomRight.Y)
                self.Components.Quad.Color = color
            else
                self.Components.Quad.Visible = false
            end
        end
    else
        self.Components.Quad.Visible = false
    end

    -- Namen und Abstände anzeigen, wenn aktiviert --
    if ESP.Names then
        local TagPos, Vis5 = cam:WorldToViewportPoint(locs.TagPos.p)
        
        if Vis5 then
            self.Components.Name.Visible = true
            self.Components.Name.Position = Vector2.new(TagPos.X, TagPos.Y)
            self.Components.Name.Text = self.Name
            self.Components.Name.Color = color
            
            self.Components.Distance.Visible = true
            self.Components.Distance.Position = Vector2.new(TagPos.X, TagPos.Y + 14)
            self.Components.Distance.Text = math.floor((cam.CFrame.p - cf.p).magnitude) .."m entfernt"
            self.Components.Distance.Color = color
        else
            self.Components.Name.Visible = false
            self.Components.Distance.Visible = false
        end
    else
        self.Components.Name.Visible = false
        self.Components.Distance.Visible = false
    end
    
    -- Tracer anzeigen, wenn aktiviert --
    if ESP.Tracers then
        local TorsoPos, Vis6 = cam:WorldToViewportPoint(locs.Torso.p)

        if Vis6 then
            self.Components.Tracer.Visible = true
            self.Components.Tracer.From = Vector2.new(TorsoPos.X, TorsoPos.Y)
            self.Components.Tracer.To = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/ESP.AttachShift)
            self.Components.Tracer.Color = color
        else
            self.Components.Tracer.Visible = false
        end
    else
        self.Components.Tracer.Visible = false
    end
end

-- Hinzufügen neuer ESP-Komponenten --
function ESP:Add(obj, options)
    if not options.PrimaryPart then
        return warn(obj, "hat keine PrimaryPart!")
    end

    local box = setmetatable({
        Name = options.Name or obj.Name,
        Type = "Box",
        Color = options.Color,
        Size = options.Size or self.BoxSize,
        Object = obj,
        Player = self:GetPlrFromChar(obj),
        PrimaryPart = options.PrimaryPart,
        Components = {},
        IsEnabled = options.IsEnabled,
        ColorDynamic = options.ColorDynamic,
        RenderInNil = options.RenderInNil
    }, boxBase)

    -- Box-Komponenten erstellen und initialisieren --
    box.Components["Quad"] = Draw("Quad", {
        Thickness = self.Thickness,
        Color = color,
        Transparency = 1,
        Filled = false,
        Visible = self.Enabled
    })

    -- Weitere Komponentenerstellung abhängig von den Einstellungen --
    if self.Names then
        box.Components["Name"] = Draw("Text", {
            Text = box.Name,
            Color = color,
            Center = true,
            Outline = true,
            Size = 19,
            Visible = self.Enabled
        })
        box.Components["Distance"] = Draw("Text", {
            Color = color,
            Center = true,
            Outline = true,
            Size = 19,
            Visible = self.Enabled
        })
    end

    if self.Tracers then
        box.Components["Tracer"] = Draw("Line", {
            Thickness = self.Thickness,
            Color = color,
            Transparency = 1,
            Visible = self.Enabled
        })
    end

    self.Objects[obj] = box
    obj.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            box:Remove()
        end
    end)
    obj:GetPropertyChangedSignal("Parent"):Connect(function()
        if obj.Parent == nil then
            box:Remove()
        end
    end)

    return box
end

-- Anlaufpunkt, um die ESP zu aktivieren und zu verwalten --
game:GetService("RunService").RenderStepped:Connect(function()
    cam = workspace.CurrentCamera
    for i, v in (ESP.Enabled and pairs or ipairs)(ESP.Objects) do
        if v.Update then
            v:Update()
        end
    end
end)
