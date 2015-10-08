local slider = {}
local meta = {}

widgets = widgets or {}
widgets.saved_widgets = widgets.sliders or {}
widgets.saved_widgets.sliders = widgets.saved_widgets.sliders or {}

_libs = _libs or {}
_libs.slider = slider

_libs.prims = _libs.prims or require 'widgets/prims'
local prims = _libs.prims

_meta = _meta or {}
_meta.slider = _meta.slider or {}
_meta.slider.__class = 'Slider'
_meta.slider.__index = slider

local amend
amend = function(settings, defaults)
    for key, val in pairs(defaults) do
        if type(val) == 'table' then
            settings[key] = amend(settings[key] or {}, val)
        elseif settings[key] == nil then
            settings[key] = val
        end
    end

    return settings
end
--[[
    settings = {
        pos = {x,y},
        w = number,
        color = {a,r,g,b},
        h = number,
        visible = boolean,
        image = boolean,
        texture = string,
        fit = boolean,
        tile = {x_rep,y_rep}
    }
--]]

local default_settings = {
    handle = {
        w = 16,
        color = {192, 100, 100, 100},
        h = 30,
    },
    track = {
        w = 140,
        color = {192, 0, 0, 0},
        h = 8,
    },
    pos = {0,0},
    visible = false,
}

local events = {
    left_click = true,
    right_click = true,
    middle_click = true,
    scroll_up = true,
    scroll_down = true,
    hover = true,
    hover_begin = true,
    hover_end = true,
    drag = true,
    right_drag = true,
    slide = true,
}

function slider.new(settings)
    local t = {}
    
    settings = amend(settings or {}, default_settings)
    
    settings.handle.pos = {settings.pos[1] - settings.handle.w / 2, settings.pos[2] - (settings.handle.w - settings.track.h) / 2}
    settings.track.pos = settings.pos
    
    t.track = prims.new(settings.track)
    t.handle = prims.new(settings.handle)
    
    local m = {}
    meta[t] = m
    
    m.slider_pos = 0
    m.events = {}
    
    table.insert(widgets.saved_widgets.sliders, t)
    return setmetatable(t, _meta.slider)
end

function slider.hover(t, x, y)
    return t.handle:hover(x, y) or t.track:hover(x, y)
end

function slider.slide(t, percent)    
    percent = percent * t.track:width() - t.handle:width() / 2

    t.handle:pos_x(t:pos_x() + percent)
    meta[t].slider_pos = percent
end

function slider.handle_position(t, x)
    if not x then return meta[t].slider_pos end
    
    local _x = t:pos_x()
    local _w = t.track:width()
    
    x = (x < _x and _x or x > _x + _w and _x + _w or x) - t.handle:width() / 2
    t.handle:pos_x(x)
    meta[t].slider_pos = x - _x
end

function slider.extents(t)
    return t.track:extents()
end

function slider.show(t)
    t.handle:show()
    t.track:show()
end

function slider.hide(t)
    t.handle:hide()
    t.track:hide()
end

function slider.visible(t, visible)
    if visible == nil then return t.handle:visible() end
    
    t.handle:visible(visible)
    t.track:visible(visible)
end

function slider.pos(t, x, y)
    if not y then return t.track:pos() end
    
    t.handle:pos(x + meta[t].slider_pos - t.handle:width() / 2, y - (t.handle:height() - t.track:height()) / 2)
    t.track:pos(x, y)
end

function slider.pos_x(t)
    if not x then return t.track:pos_x() end
    
    t.handle:pos_x(x + meta[t].slider_pos - t.handle:width() / 2)
    t.track:pos_x(x)
end

function slider.pos_y(t)
    if not y then return t.track:pos_y() end
    
    t.handle:pos_y(y - (t.handle:height() - t.track:height()) / 2)
    t.track:pos_y(y)
end

function slider.get_events(t)
    return meta[t].events
end

function slider.register_event(t, event, fn)
    if not events[event] then
        error('The event ' .. event .. ' is not available to the ' .. class(t) .. ' class.')
        return
    end
    
    local m = meta[t].events

    m[event] = m[event] or {n = 0}
    local n
    for i = 1, m[event].n do
        if not m[event][i] then
            n = i
            break
        end
    end
    if not n then
        n = m[event].n + 1
        m[event].n = n
    end
    m[event][n] = fn

    return n
end
 
function slider.unregister_event(t, event, n)
    if not (events[event] and meta[t].events[event]) then
        return
    end

    if type(n) == 'number' then
        meta[t].events[event][n] = nil
    else
        for i = 1, meta[t].events[event].n do
            if meta[t].events[event][i] == n then
                meta[t].events[event][i] = nil
                return
            end
        end
    end
end

return slider
