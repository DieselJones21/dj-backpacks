local ox_inventory = exports.ox_inventory
local resourceName = GetCurrentResourceName()

---@type table<string, true>
local registeredStashes = {}

---@type table<number, { bagId: string, slot: number, name: string }>
local openBags = {}

---@type table<number, number>
local lastOpen = {}

---@type table<number, true>
local opening = {}

local hooksReady = false

lib.locale()

if not lib.checkDependency('ox_lib', '3.0.0', true) then return end
if not lib.checkDependency('ox_inventory', '2.31.0', true) then return end

local function notify(source, description, notifyType)
    if source == 0 then
        print(('[dj-backpacks] %s'):format(description))
        return
    end

    TriggerClientEvent('ox_lib:notify', source, {
        title = locale('notify_title'),
        description = description,
        type = notifyType or 'error',
        icon = 'bag-shopping',
    })
end

---@return string
local function generateBagId()
    return ('%s%s'):format(os.time(), lib.string.random('A1A1A1A1A1A1'))
end

---@param source number
---@return boolean
local function isInventoryOpen(source)
    local state = Player(source).state
    return state.invOpen == true
end

---@param source number
---@return number
local function countPlayerBags(source)
    local count = 0

    for name in pairs(Config.Bags) do
        count = count + (ox_inventory:GetItemCount(source, name) or 0)
    end

    return count
end

---@param source number
---@param slot number
---@param bag table
---@param metadata table
---@param bagId string
local function persistBagMetadata(source, slot, bag, metadata, bagId)
    metadata.bagId = bagId
    metadata.description = Bags.Description(bag, bagId)
    ox_inventory:SetMetadata(source, slot, metadata)
end

---@param bagId string
---@param bag table
---@return boolean
local function ensureStash(bagId, bag)
    local stashId = Bags.StashId(bagId)

    if registeredStashes[stashId] then
        return true
    end

    local ok, err = pcall(function()
        ox_inventory:RegisterStash(stashId, bag.label, bag.slots, bag.weight, false)
    end)

    if not ok then
        print(('[dj-backpacks] Failed to register stash %s: %s'):format(stashId, err))
        return false
    end

    registeredStashes[stashId] = true
    return true
end

---@param payload table
---@return boolean
local function isMovingBagOntoPlayer(payload)
    if payload.toType ~= 'player' then
        return false
    end

    if payload.action == 'give' then
        return true
    end

    return payload.fromType ~= 'player'
end

---@param payload table
---@return number|nil
local function receivingPlayer(payload)
    if payload.action == 'give' then
        local target = tonumber(Bags.InventoryId(payload.toInventory) or payload.toInventory)
        return target
    end

    if payload.toType == 'player' then
        return payload.source
    end
end

local function registerHooks()
    if GetResourceState('ox_inventory') ~= 'started' then
        return
    end

    if hooksReady then
        ox_inventory:removeHooks()
        hooksReady = false
    end

    ox_inventory:registerHook('createItem', function(payload)
        local bag = Bags.Get(payload.item and payload.item.name)
        if not bag then
            return
        end

        local metadata = Bags.Metadata(payload.metadata)
        local bagId = metadata.bagId

        if type(bagId) ~= 'string' or bagId == '' then
            bagId = generateBagId()
            metadata.bagId = bagId
        end

        metadata.description = Bags.Description(bag, bagId)
        Bags.Debug('createItem %s id=%s', payload.item.name, bagId)
        return metadata
    end, {
        itemFilter = Bags.ItemFilter,
    })

    ox_inventory:registerHook('swapItems', function(payload)
        if not Bags.IsStash(payload.toInventory) then
            return
        end

        local fromName = type(payload.fromSlot) == 'table' and payload.fromSlot.name or nil

        if Config.PreventBagInBag and (Bags.IsItem(fromName) or Bags.IsStash(payload.fromInventory)) then
            notify(payload.source, locale('bag_in_bag'))
            return false
        end

        if fromName and Config.Blacklist[fromName] then
            notify(payload.source, locale('blacklisted'))
            return false
        end

        if next(Config.Whitelist) and fromName and not Config.Whitelist[fromName] then
            notify(payload.source, locale('not_allowed'))
            return false
        end
    end, {
        inventoryFilter = { ('^%s'):format(Config.StashPrefix) },
    })

    ox_inventory:registerHook('swapItems', function(payload)
        local fromSlot = payload.fromSlot
        local fromName = type(fromSlot) == 'table' and fromSlot.name or nil

        if not Bags.IsItem(fromName) then
            return
        end

        if Config.LockOpenBag then
            local metadata = Bags.Metadata(fromSlot.metadata)
            local open = openBags[payload.source]

            if open and open.bagId == metadata.bagId then
                if isInventoryOpen(payload.source) then
                    notify(payload.source, locale('bag_locked'))
                    return false
                end

                openBags[payload.source] = nil
            end
        end

        local maxBags = tonumber(Config.MaxBags) or 0

        if maxBags > 0 and isMovingBagOntoPlayer(payload) then
            local target = receivingPlayer(payload)

            if target and countPlayerBags(target) >= maxBags then
                notify(payload.source, locale('max_bags'))
                return false
            end
        end
    end, {
        itemFilter = Bags.ItemFilter,
    })

    ox_inventory:registerHook('buyItem', function(payload)
        local maxBags = tonumber(Config.MaxBags) or 0

        if maxBags > 0 and Bags.IsItem(payload.itemName) and countPlayerBags(payload.source) >= maxBags then
            notify(payload.source, locale('max_bags'))
            return false
        end
    end, {
        itemFilter = Bags.ItemFilter,
    })

    hooksReady = true
    Bags.Debug('inventory hooks registered')
end

lib.callback.register(resourceName .. ':openBag', function(source, slot)
    if opening[source] then
        return false, locale('cannot_open')
    end

    slot = tonumber(slot)

    if not slot or slot < 1 or slot ~= math.floor(slot) then
        return false, locale('invalid_bag')
    end

    local now = GetGameTimer()
    local cooldown = lastOpen[source]

    if cooldown and (now - cooldown) < Config.OpenCooldown then
        return false, locale('cooldown')
    end

    local state = Player(source).state

    if state.dead or state.isDead or state.downed then
        return false, locale('cannot_open')
    end

    opening[source] = true
    lastOpen[source] = now

    local slotData = ox_inventory:GetSlot(source, slot)

    if type(slotData) ~= 'table' or not Bags.IsItem(slotData.name) then
        opening[source] = nil
        return false, locale('invalid_bag')
    end

    local bag = Bags.Get(slotData.name)
    local metadata = Bags.Metadata(slotData.metadata)
    local bagId = metadata.bagId

    if type(bagId) ~= 'string' or bagId == '' then
        bagId = generateBagId()
        persistBagMetadata(source, slot, bag, metadata, bagId)
    elseif metadata.description ~= Bags.Description(bag, bagId) then
        persistBagMetadata(source, slot, bag, metadata, bagId)
    end

    if type(bagId) ~= 'string' or not bagId:match('^[%w]+$') then
        opening[source] = nil
        return false, locale('invalid_bag')
    end

    if not ensureStash(bagId, bag) then
        opening[source] = nil
        return false, locale('cannot_open')
    end

    local stashId = Bags.StashId(bagId)

    openBags[source] = {
        bagId = bagId,
        slot = slot,
        name = slotData.name,
        openedAt = now,
    }

    Player(source).state:set('djBagOpen', bagId, true)

    local opened = pcall(function()
        ox_inventory:forceOpenInventory(source, 'stash', stashId)
    end)

    opening[source] = nil

    if not opened then
        openBags[source] = nil
        Player(source).state:set('djBagOpen', false, true)
        return false, locale('cannot_open')
    end

    Bags.Debug('player %s opened %s (%s)', source, slotData.name, stashId)
    return true
end)

RegisterNetEvent(resourceName .. ':closed', function()
    local source = source
    local open = openBags[source]

    if not open then
        return
    end

    -- forceOpenInventory can emit a close during the switch; ignore that first pulse.
    if open.openedAt and (GetGameTimer() - open.openedAt) < 400 then
        return
    end

    openBags[source] = nil
    Player(source).state:set('djBagOpen', false, true)
end)

AddEventHandler('playerDropped', function()
    local source = source
    openBags[source] = nil
    lastOpen[source] = nil
    opening[source] = nil
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource == 'ox_inventory' or resource == resourceName then
        registeredStashes = {}
        registerHooks()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= resourceName then
        return
    end

    if hooksReady and GetResourceState('ox_inventory') == 'started' then
        ox_inventory:removeHooks()
    end

    for playerId in pairs(openBags) do
        Player(playerId).state:set('djBagOpen', false, true)
    end
end)

CreateThread(function()
    local timeoutAt = GetGameTimer() + 15000

    while GetResourceState('ox_inventory') ~= 'started' and GetGameTimer() < timeoutAt do
        Wait(200)
    end

    registerHooks()

    Wait(1000)

    for name in pairs(Config.Bags) do
        if not ox_inventory:Items(name) then
            print(('[dj-backpacks] ^1%s^0'):format(locale('missing_item', name)))
        end
    end
end)

lib.addCommand('givebag', {
    help = 'Give a duffle bag to a player',
    params = {
        { name = 'target', type = 'playerId', help = 'Player server id' },
        { name = 'size', type = 'string', help = 'small, medium, or large' },
    },
    restricted = 'group.admin',
}, function(source, args)
    local size = args.size and args.size:lower() or 'small'
    local itemName = Bags.IsItem(size) and size or ('bag_' .. size)
    local bag = Bags.Get(itemName)

    if not bag then
        notify(source, locale('invalid_bag'))
        return
    end

    local success = ox_inventory:AddItem(args.target, itemName, 1)

    if success then
        notify(source, locale('gave_bag', bag.label, args.target), 'success')
        return
    end

    notify(source, locale('give_failed'))
end)

exports('isBagItem', Bags.IsItem)
exports('getBagConfig', Bags.Get)
exports('stashId', Bags.StashId)
