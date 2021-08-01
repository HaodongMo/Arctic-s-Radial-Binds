if SERVER then return end

BIND_CMD = 0 -- when selected, pressing the bind key will activate this one.
BIND_BIND = 1 -- when selected, pressing the bind key will use it with + and -
BIND_TOGGLE = 2 -- when selected, pressing the bind key will toggle + and -
BIND_INSTANT = 3 -- when selected, this command will trigger instantly. It will then act like CMD.
BIND_FALLINGCMD = 4 -- command triggers on falling edge
BIND_BURST = 5 -- command triggers for X seconds
BIND_DUALEDGE = 6 -- command triggers on rising and falling edge

ArcticRadialBinds_BIND_To_Text = {
    [BIND_CMD] = "Command",
    [BIND_BIND] = "Bind",
    [BIND_TOGGLE] = "Toggle",
    [BIND_INSTANT] = "Instant",
    [BIND_FALLINGCMD] = "Falling Edge",
    [BIND_BURST] = "Burst",
    [BIND_DUALEDGE] = "Dual Edge"
}

ArcticRadialBinds = {
    {
        {
            PrintName = "Stims",
            BindType = BIND_BIND,
            Command = "arc_vm_medshot",
            SegmentFade = 0,
        },
        {
            PrintName = "Night Vision",
            BindType = BIND_CMD,
            Command = "arc_vm_nvg",
            SegmentFade = 0,
        },
        {
            PrintName = "Armor",
            BindType = BIND_BIND,
            Command = "armorplate",
            SegmentFade = 0,
        }
    },
    {},
    {}
}

ArcticRadialBinds_Materials = {} -- ["mat/path/mat"] = Material("mat/path/mat")
// save and load to file

ArcticRadialBinds_SelectedMenu = 1
ArcticRadialBinds_Selection = 0

ArcticRadialBinds_Open = false
ArcticRadialBinds_Fade = 0

ArcticRadialBinds_MouseAng = 0
ArcticRadialBinds_MouseRad = 0

local fontf = "Bahnschrift"

surface.CreateFont( "arc_radial_binds_16", {
    font = fontf,
    size = ScreenScale(16),
    weight = 0,
    antialias = true,
    extended = true, -- Required for non-latin fonts
} )

surface.CreateFont( "arc_radial_binds_16_shadow", {
    font = fontf,
    size = ScreenScale(16),
    blursize = 5,
    weight = 0,
    antialias = true,
    extended = true, -- Required for non-latin fonts
} )

local function RadiusSpoke(x, y, angle, rad)
    x = x + (math.cos(angle) * rad)
    y = y + (math.sin(angle) * rad)

    return x, y
end

local mat_ring = Material("sgm/playercircle")
local segmentfadetime = 0.25
local fadetime = 0.1

hook.Add("HUDPaint", "ArcticRadialBinds_HUD", function()
    local activemenu = ArcticRadialBinds[ArcticRadialBinds_SelectedMenu]

    if !activemenu then return end

    if ArcticRadialBinds_Open then
        ArcticRadialBinds_Fade = math.Approach(ArcticRadialBinds_Fade, 1, FrameTime() / fadetime)
    else
        ArcticRadialBinds_Fade = math.Approach(ArcticRadialBinds_Fade, 0, FrameTime() / fadetime)
    end

    local a = ArcticRadialBinds_Fade * 255

    if a <= 0 then return end

    local ss = ScreenScale(1)

    local col_fg = Color(255, 255, 255, a)
    local col_fg_h = Color(25, 25, 25, a)

    local segments = table.Count(activemenu)

    local x = ScrW() / 2
    local y = ScrH() / 2

    local rad = ss * 100

    if segments > 0 then
        -- draw each segment
        local arc = 360 / segments

        for i = 1, segments do
            local angle = (i * arc) - 90

            local d = (ArcticRadialBinds_MouseAng - angle + 180 + 360) % 360 - 180
            d = math.abs(d)

            local selected = d <= arc / 2

            if ArcticRadialBinds_MouseRad == 0 then
                selected = false
            end

            if !activemenu[i] then continue end

            activemenu[i].SegmentFade = activemenu[i].SegmentFade or 0

            local size = rad * (1 + (activemenu[i].SegmentFade * 0.1))

            local inf_x, inf_y = RadiusSpoke(x, y, math.rad(angle), size)

            if selected then
                ArcticRadialBinds_Selection = i
                activemenu[i].SegmentFade = math.Approach(activemenu[i].SegmentFade, 1, FrameTime() / segmentfadetime)
            else
                activemenu[i].SegmentFade = math.Approach(activemenu[i].SegmentFade, 0, FrameTime() / segmentfadetime)
            end

            surface.SetFont("arc_radial_binds_16")
            local inf_w, inf_h = surface.GetTextSize(activemenu[i].PrintName)

            local tb_w = inf_w + (ss * 4)

            if selected then
                surface.SetDrawColor(255, 255, 255, a * 0.5)
            else
                surface.SetDrawColor(0, 0, 0, a * 0.8)
            end
            surface.DrawRect(inf_x - (tb_w / 2), inf_y - (ss * 0.5), tb_w, inf_h + (ss * 1))

            surface.SetTextColor(0, 0, 0, a)
            surface.SetFont("arc_radial_binds_16_shadow")
            surface.SetTextPos(inf_x - (inf_w / 2), inf_y)
            surface.DrawText(activemenu[i].PrintName)

            if selected then
                surface.SetTextColor(col_fg_h)
            else
                surface.SetTextColor(col_fg)
            end
            surface.SetFont("arc_radial_binds_16")
            surface.SetTextPos(inf_x - (inf_w / 2), inf_y)
            surface.DrawText(activemenu[i].PrintName)
        end
    end

    local pick_x, pick_y = RadiusSpoke(x, y, math.rad(ArcticRadialBinds_MouseAng), ArcticRadialBinds_MouseRad)
    local pick_s = ss * 8
    surface.SetMaterial(mat_ring)
    surface.SetDrawColor(255, 255, 255, a)
    surface.DrawTexturedRect(pick_x - (pick_s / 2), pick_y - (pick_s / 2), pick_s, pick_s)
end)

local function instant()
    local activemenu = ArcticRadialBinds[ArcticRadialBinds_SelectedMenu]
    local selection = activemenu[ArcticRadialBinds_Selection]

    if !selection then return end

    local ply = LocalPlayer()

    if selection.BindType == BIND_INSTANT then
        ply:ConCommand(selection.Command)
    end
end

concommand.Add("+arc_radial_menu", function(ply, cmd, args)
    ArcticRadialBinds_SelectedMenu = 1
    ArcticRadialBinds_Open = true
end)

concommand.Add("-arc_radial_menu", function()
    ArcticRadialBinds_Open = false
    instant()
end)

concommand.Add("+arc_radial_menu_2", function(ply, cmd, args)
    ArcticRadialBinds_SelectedMenu = 2
    ArcticRadialBinds_Open = true
end)

concommand.Add("-arc_radial_menu_2", function()
    ArcticRadialBinds_Open = false
    instant()
end)

concommand.Add("+arc_radial_menu_3", function(ply, cmd, args)
    ArcticRadialBinds_SelectedMenu = 3
    ArcticRadialBinds_Open = true
end)

concommand.Add("-arc_radial_menu_3", function()
    ArcticRadialBinds_Open = false
    instant()
end)

hook.Add("InputMouseApply", "ArcticRadialBinds_Mouse", function(cmd, x, y, ang)
    if !ArcticRadialBinds_Open then return end

    if math.abs(x) + math.abs(y) <= 0 then return end

    cmd:SetMouseX( 0 )
    cmd:SetMouseY( 0 )

    local mousex = math.cos(math.rad(ArcticRadialBinds_MouseAng)) * ArcticRadialBinds_MouseRad
    local mousey = math.sin(math.rad(ArcticRadialBinds_MouseAng)) * ArcticRadialBinds_MouseRad

    mousex = mousex + x
    mousey = mousey + y

    local newang = math.deg(math.atan2(mousey, mousex))
    local newrad = math.sqrt(math.pow(mousex, 2) + math.pow(mousey, 2))
    -- local newrad = Vector(mousex, mousey):Length()

    newrad = math.min(newrad, ScreenScale(100))

    ArcticRadialBinds_MouseRad = newrad
    ArcticRadialBinds_MouseAng = newang

    -- ArcticRadialBinds_SelectAngle = math.NormalizeAngle(ArcticRadialBinds_SelectAngle)

    return true
end)

concommand.Add("+arc_radial_bind", function()
    local activemenu = ArcticRadialBinds[ArcticRadialBinds_SelectedMenu]
    local selection = activemenu[ArcticRadialBinds_Selection]

    if !selection then return end

    local ply = LocalPlayer()

    if selection.BindType == BIND_CMD then
        ply:ConCommand(selection.Command)
    elseif selection.BindType == BIND_TOGGLE then
        selection.BindToggle = selection.BindToggle or false

        if selection.BindToggle then
            ply:ConCommand("-" .. selection.Command)
        else
            ply:ConCommand("+" .. selection.Command)
        end

        selection.BindToggle = !selection.BindToggle
    elseif selection.BindType == BIND_BIND then
        ply:ConCommand("+" .. selection.Command)
    elseif selection.BindType == BIND_DUALEDGE then
        ply:ConCommand(selection.Command)
    elseif selection.BindType == BIND_BURST then
        ply:ConCommand("+" .. selection.Command)

        timer.Simple(selection.BurstTime or 1, function()
            ply:ConCommand("-" .. selection.Command)
        end)
    end
end)

concommand.Add("-arc_radial_bind", function()
    local activemenu = ArcticRadialBinds[ArcticRadialBinds_SelectedMenu]
    local selection = activemenu[ArcticRadialBinds_Selection]

    if !selection then return end

    local ply = LocalPlayer()

    if selection.BindType == BIND_BIND then
        ply:ConCommand("-" .. selection.Command)
    elseif selection.BindType == BIND_FALLINGCMD then
        ply:ConCommand(selection.Command)
    elseif selection.BindType == BIND_DUALEDGE then
        ply:ConCommand(selection.Command)
    end
end)

concommand.Add("arc_radial_customize", function()
    ArcticRadialBinds_OpenMenu()
end)