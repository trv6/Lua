--[[
To Do:
    Finish default handling.
    Finish calling custom events.
    Normalize events across modules.
    Add groups.
    Add grids.
    Find bugs (There Will Be Bugs).
--]]
widgets = {
    saved_widgets = {
        buttons = setmetatable({}, {__newindex = function(t, k, v)
            -- t :: widgets.saved_widgets.buttons, k :: n, v :: widget object
            local events = setmetatable(v:get_events(), {__newindex = function(u, l, w)
                --u :: meta[t].events, l :: event string, w :: function list
                event_registrar[v] = u
                table.insert(event_object_list[l], t)
                rawset(u, l, w)
            end})
            events.left_click = {n = 0}         -- Adds widget classes to event_object_list even if no custom event
            events.left_click_release = {n = 0} -- is registered. Allows class-specific events to be created in the mouse event.
        end}),
        scroll_texts = setmetatable({}, {__newindex = function(t, k, v)
            local events = setmetatable(v:get_events(), {__newindex = function(u, l, w)
                event_registrar[v] = u
                table.insert(event_object_list[l], t)
                rawset(u, l, w)
            end})
            events.scroll = {n = 0}
        end}),
        scroll_menus = setmetatable({}, {__newindex = function(t, k, v)
            local events = setmetatable(v:get_events(), {__newindex = function(u, l, w)
                event_registrar[v] = u
                table.insert(event_object_list[l], t)
                rawset(u, l, w)
            end})
            events.left_click = {n = 0}
            events.scroll = {n = 0}
        end}),
        sliders = setmetatable({}, {__newindex = function(t, k, v)
            local events = setmetatable(v:get_events(), {__newindex = function(u, l, w)
                event_registrar[v] = u
                table.insert(event_object_list[l], t)
                rawset(u, l, w)
            end})
            events.left_click = {n = 0}
            events.left_click_release = {n = 0}
        end}),
    }
}

_libs = _libs or {}
_libs.widgets = widgets
prims = _libs.prims or require('widgets/prims')
texts = _libs.texts or require('texts')
buttons = _libs.buttons or require('widgets/button')
sliders = _libs.slider or require('widgets/slider')
scroll_text = _libs.scrolling_text or require('widgets/scroll_text')
scroll_menu = _libs.scrolling_text_menu or require('widgets/scroll_menu')

function class(o)
    local mt = getmetatable(o)

    return mt and mt.__class or type(o)
end

do

local events = {
    left_click = true,
    right_click = true,
    middle_click = true,
    scroll = true,
    scroll = true,
    hover = true,
    hover_begin = true,
    hover_end = true,
    drag = true,
    right_drag = true,
    button_press = true, --button
    button_release = true, --button
    slide = true, --slider
    menu_selection = true, --scroll_menu
}

local type_to_event = {
    'left_click',
    'right_click',
    nil,
    'left_click_release',
    'right_click_release',
    'middle_click',
    'middle_click_release',
    nil,
    nil,
    'scroll',
    'x_click',
    'x_click_release',
}

local basic_array = {__newindex = function(t, k, v)
    local n = rawget(t, 'n')
    if k > n then
        rawset(t, 'n', n + 1)
    end
    rawset(t, k, v)
end}

local event_registrar ={}

local event_object_list = {}
for k, v in pairs(events) do
    event_object_list[k] = setmetatable({n = 0}, basic_array)
end

local default_behavior = {
    Slider = {
        [1] = function (t, type, x, y, delta, blocked)
        
        end,
        [4] = function (t, type, x, y, delta, blocked)
        
        end,
    },
    ScrollTextMenu = {
        [1] = function (t, type, x, y, delta, blocked)
        
        end,
        [10] = function (t, type, x, y, delta, blocked)
        
        end,
    },
    ScrollText = {
        [10] = function (t, type, x, y, delta, blocked)
        
        end,
    },
    Button = {
        [1] = function (t, type, x, y, delta, blocked)
        
        end,
        [4] = function (t, type, x, y, delta, blocked)
        
        end,
    }
}

windower.register_event('mouse', function(type, x, y, delta, blocked)
    if type == 0 then
    
    else
        local hover
        local event = type_to_event[type]
        local list = event_object_list[event]
        
        for i = 1, list.n do
            if list[i] then -- incase someone destroys an object
                hover = list[i]:hover(x, y) and list[i]
                if hover then
                    local class = class(hover)
                    if default_behavior[class] and default_behavior[class][type] then
                        default_behavior[class][type](hover, x, y, delta, blocked)
                    end
                    local event_registry = event_registrar[hover] and event_registrar[hover][event]
                    if event_registry then
                        for j = 1, event_registry.n do
                            event_registry[j](x, y, delta, blocked)
                        end
                        break
                    end
                end
            else
                table.remove(list, i)
                list.n = list.n - 1
            end
        end
    end
end)

    -- for each event pass as arguments: object, parameters (other than mouse type)0
function widgets.handle_object_events(...) -- Use for prims or custom objects not handled by the widgets library
    local list_of_objects = {...}
    for i = 1, #list_of_objects do
        local object = list_of_objects[i]
        local events = object:get_events()
        
        event_registrar[object] = events
        
        for event, function_table in pairs(events) do
            local obj_list = event_object_list[event]
            local n
            for i = 1, obj_list.n do
                if not obj_list[i] then
                    n = i
                    break
                end
            end
            if n then
                obj_list[n] = object
            else
                table.insert(obj_list, object)
            end
        end
    end
end

end