local uuid = {}

--- Генерирует UUID v4
---@return UUID_V4
function uuid.new()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    ---@type UUID_V4
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
        return string.format('%x', v)
    end)
end

return uuid