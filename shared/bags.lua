Bags = {}

local function toSet(tbl)
    if type(tbl) ~= 'table' then
        return {}
    end

    if tbl[1] ~= nil then
        local set = {}

        for i = 1, #tbl do
            local key = tbl[i]
            if type(key) == 'string' then
                set[key] = true
            end
        end

        return set
    end

    return tbl
end

Config.Blacklist = toSet(Config.Blacklist)
Config.Whitelist = toSet(Config.Whitelist)

local prefix = Config.StashPrefix
local prefixLen = #prefix
local bagItems = Config.Bags

---@type table<string, true>
Bags.ItemFilter = {}

for name, bag in pairs(bagItems) do
    if type(name) ~= 'string' or type(bag) ~= 'table' then
        error(('[dj-backpacks] invalid bag entry %s'):format(tostring(name)))
    end

    if type(bag.label) ~= 'string' or bag.label == '' then
        error(('[dj-backpacks] %s is missing a label'):format(name))
    end

    if type(bag.slots) ~= 'number' or bag.slots < 1 then
        error(('[dj-backpacks] %s slots must be a positive number'):format(name))
    end

    if type(bag.weight) ~= 'number' or bag.weight < 1 then
        error(('[dj-backpacks] %s weight must be a positive number of grams'):format(name))
    end

    if type(bag.capacityKg) ~= 'number' or bag.capacityKg < 1 then
        error(('[dj-backpacks] %s capacityKg must be a positive number'):format(name))
    end

    if type(bag.carryWeight) ~= 'number' or bag.carryWeight < 0 then
        error(('[dj-backpacks] %s carryWeight must be a number of grams'):format(name))
    end

    Bags.ItemFilter[name] = true
end

---@param name string|nil
---@return boolean
function Bags.IsItem(name)
    return name ~= nil and bagItems[name] ~= nil
end

---@param name string
---@return table|nil
function Bags.Get(name)
    return bagItems[name]
end

---@param bagId string
---@return string
function Bags.StashId(bagId)
    return prefix .. bagId
end

---@param value any
---@return string|nil
function Bags.InventoryId(value)
    local valueType = type(value)

    if valueType == 'string' then
        return value
    end

    if valueType == 'table' then
        local id = value.id or value.name
        if type(id) == 'string' then
            return id
        end
    end
end

---@param value any
---@return boolean
function Bags.IsStash(value)
    local id = Bags.InventoryId(value)
    return type(id) == 'string' and id:sub(1, prefixLen) == prefix
end

---@param metadata any
---@return table
function Bags.Metadata(metadata)
    if type(metadata) ~= 'table' or metadata[1] ~= nil then
        return {}
    end

    return metadata
end

---@param bag table
---@param bagId string
---@return string
function Bags.Description(bag, bagId)
    return ('%s kg capacity  ·  #%s'):format(bag.capacityKg, bagId:sub(1, 8))
end

---@param message string
---@param ... any
function Bags.Debug(message, ...)
    if not Config.Debug then
        return
    end

    if select('#', ...) > 0 then
        message = message:format(...)
    end

    print(('[dj-backpacks] %s'):format(message))
end
