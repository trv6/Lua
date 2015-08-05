local scrolling_text_menu = {}
local meta = {}

widgets = widgets or {}
widgets.saved_widgets = widgets.saved_widgets or {}
widgets.saved_widgets.scroll_menu = widgets.saved_widgets.scroll_menu or {}

    _libs = _libs or {}
_libs.scrolling_text_menu = scrolling_text_menu

_libs.scrolling_text = _libs.scrolling_text or  require('widgets/scroll_text')
local scroll_text = _libs.scrolling_text

_meta = _meta or {}
_meta.scrolling_text_menu = _meta.scrolling_text_menu or {}
_meta.scrolling_text_menu.__class = 'ScrollTextMenu'
_meta.scrolling_text_menu.__index = function(t, k) return scrolling_text_menu[k] or scroll_text[k] end

local prims = _libs.prims

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

local default_settings = {
    color = {
        bar = {192, 128, 128, 128},
        bg = {192, 0, 0, 0},
        highlight = {192, 84, 84, 84},
    },
    text = {
        font = 'Consolas',
        size = 10,
        lines = {},
        color_formatting = {},
        lines_to_display = 12
    },
    pos = {0, 0},
    w = 150,
    fit = {x = false, y = false},
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
    menu_selection = true,
}

function scrolling_text_menu.new(settings)    
    local m = settings or {}
    
    m = amend(m, default_settings)
    
    m.selected = 0
    m.state = false
    m.events = {}

    local t = scroll_text.new(settings)
    
    t.highlight = prims.new({
        pos = m.pos,
        w = m.w,
        color = {unpack(m.color.highlight)},
        visible = m.visible,
        })

    m.color = nil

    meta[t] = m
    table.insert(widgets.saved_widgets.scroll_menu, t)
    return setmetatable(t, _meta.scrolling_text_menu)
end

function scrolling_text_menu.show(t)
    scroll_text.show(t)
    t.highlight:show()
    
    meta[t].visible = true
end

function scrolling_text_menu.hide(t)
    t.highlight:hide()
    scroll_text.hide(t)
    
    meta[t].visible = false
end

function scrolling_text_menu.open(t, n)
    local m = meta[t]
    
    scroll_text.open(t, n)
    local l = scroll_text.line_height(t)
    t.highlight:height(l)
    t.highlight:pos_y(m.pos[2] + (m.selected <= scroll_text.range(t) and m.selected or 0) * l)

    m.state = true
end

function scrolling_text_menu.close(t)
    scroll_text.close(t)
    t.highlight:hide()

    local m = meta[t]
    m.selected = 0
    m.state = false
end

function scrolling_text_menu.visible(t, visible)
    if visible == nil then
        return meta[t].visible
    end
    
    t.highlight:visible(visible)
    scroll_text.visible(t, visible)
    
    meta[t].visible = visible
end

function scrolling_text_menu.width(t, width)
    if not width then return scroll_text.width(t) end
    
    scroll_text.width(t, width)
    t.highlight:width(width)
end

function scrolling_text_menu.is_open(t)
    return meta[t].state
end

function scrolling_text_menu.selected(t, n)
    if not n then return meta[t].selected + 1 end
    
    local m = meta[t]
    m.selected = (n - 1) % scroll_text.range(t)
    
    t.highlight:pos_y(m.pos[2] + m.selected * t.highlight:height())
end

function scrolling_text_menu.pos(t, x, y)
    if not y then
        return unpack(meta[t].pos)
    end

    local m = meta[t]
    
    scroll_text.pos(t, x, y)
    t.highlight:pos(x, y + m.selected * t.highlight:height())
    
    m.pos[1], m.pos[2] = x, y
end

function scrolling_text_menu.pos_x(t, x)
    if not x then
        return meta[t].pos[1]
    end
    
    scroll_text.pos_x(t, x)
    t.highlight:pos_x(x)
    
    meta[t].pos[1] = x
end

function scrolling_text_menu.pos_y(t, y)
    if not y then
        return meta[t].pos[2]
    end
    
    t:pos(meta[t].pos[1], y)
end

function scrolling_text_menu.get_events(t)
    return meta[t].events
end

function scrolling_text_menu.register_event(t, event, fn)
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
 
function scrolling_text_menu.unregister_event(t, event, n)
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

return scrolling_text_menu
