local buttons = {}
local meta = {}

widgets = widgets or {}
widgets.saved_widgets = widgets.saved_widgets or {}
widgets.saved_widgets.buttons = widgets.saved_widgets.buttons or {}

_libs = _libs or {}
_libs.buttons = buttons

_libs.texts = _libs.texts or require 'texts'
_libs.prims = _libs.prims or require 'prims'

local texts = _libs.texts
local prims = _libs.prims

_meta = _meta or {}
_meta.Button = _meta.Button or {}
_meta.Button.__class = 'Button'
_meta.Button.__index = function(t, k) return buttons[k] or prims[k] end

function class(o)
    local mt = getmetatable(o)

    return mt and mt.__class or type(o)
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
    w = 70,
    h = 30,
    color = {192, 100, 100, 100},
    visible = false,
    labels = {}
}

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
    button_press = true, --button
    button_release = true, --button
}


function buttons.new(settings)
    local t
    
    local class = class(settings)
    if settings and (class == 'Prim' or class == 'Text') then
        t = settings
    else
        settings = amend(settings or {}, default_settings)
        t = prims.new(settings)
    end

    meta[t] = {
        state = false,
        events = {}
    }
    
    t.labels = {
        n = #settings.labels
    }
    
    meta[t].labels = settings.labels or {}
    
    for i = 1, t.labels.n do
        t.labels[i] = texts.new(settings.labels[i].text or '', amend(settings.labels[i].settings or {},
            {
                flags = {draggable = false},
                bg = {visible = false},
                pos = {x = (x_offset or 0) + t:pos_x(), y = (y_offset or 0) + t:pos_y()}
            })
        )
        if (class == 'Prim' or class == 'Text') and t:visible() or settings.visible then
            t.labels[i]:show()
        end
    end
    
    table.insert(widgets.saved_widgets.buttons, t)
    return setmetatable(t, _meta.Button)
end

function buttons.up(t)
    meta[t].state = false
end

function buttons.down(t)
    meta[t].state = true
end

function buttons.press(t, down)
    meta[t].state = down
end

function buttons.show(t)
    for i = 1, t.labels.n do
        t.labels[i]:show()
    end

    prims.show(t)
end

function buttons.hide(t)
    for i = 1, t.labels.n do
        t.labels[i]:hide()
    end
    
    prims.hide(t)
end

function buttons.visible(t, visible)
    if visible == nil then return prims.visible(t) end

    for i = 1, t.labels.n do
        t.labels[i]:visible(visible)
    end
    
    prims.visible(t, visible)
end

function buttons.pos(t, x, y)
    if not y then return prims.pos(t) end
    
    for i = 1, t.labels.n do
        local label = t.labels[i]
        label:pos(x + label:pos_x() - prims.pos_x(t), y + label:pos_y() - prims.pos_y(t))
    end
    
    prims.pos(t, x, y)
end

function buttons.pos_x(t, x)
    if not x then return prims.pos_x(t) end

    for i = 1, t.labels.n do
        local label = t.labels[i]
        label:pos_x(x + label:pos_x() - prims.pos_x(t))
    end
    
    prims.pos_x(t, x)
end

function buttons.pos_y(t, y)
    if not y then return prims.pos_y(t) end

    for i = 1, t.labels.n do
        local label = t.labels[i]
        label:pos_y(y + label:pos_y() - prims.pos_y(t))
    end
    
    prims.pos_y(t, y)
end

function buttons.append_label(t, text, x_offset, y_offset)
    local n = t.labels.n + 1
    
    t.labels.n = n
    t.labels[n] = class(text) == 'Text' and text or texts.new(
        text or '',
        {
            flags = {draggable = false},
            bg = {visible = false},
            pos = {x = (x_offset or 0) + t:pos_x(), y = (y_offset or 0) + t:pos_y()}
        }
    )
    if t:visible() then
        t.labels[n]:show()
    end
end

function buttons.remove_label(t, n)
    t.labels.n = t.labels.n - 1
    t.labels[n]:destroy()
    table.remove(t.labels, n)
end

function buttons.label(t, n)
    return t.labels[n]
end

function buttons.get_events(t)
    return meta[t].events
end

function buttons.register_event(t, event, fn)
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
 
function buttons.unregister_event(t, event, n)
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


return buttons
