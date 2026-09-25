local resourceName = GetCurrentResourceName()
local opening = false

lib.locale()

local function notify(description, notifyType)
    lib.notify({
        title = locale('notify_title'),
        description = description,
        type = notifyType or 'error',
        icon = 'bag-shopping',
    })
end

local function canUseBag()
    local state = LocalPlayer.state

    if state.dead or state.isDead or state.downed or state.laststand then
        return false
    end

    if state.invBusy and not state.invOpen then
        return false
    end

    return true
end

---@param data table
exports('useBag', function(data)
    if opening or type(data) ~= 'table' or type(data.slot) ~= 'number' then
        return
    end

    if not data.name then
        local slot = exports.ox_inventory:GetSlot(data.slot)
        data.name = slot and slot.name
    end

    if not Bags.IsItem(data.name) then
        return
    end

    if not canUseBag() then
        notify(locale('cannot_open'))
        return
    end

    opening = true

    CreateThread(function()
        local timeoutAt = GetGameTimer() + 2000

        while LocalPlayer.state.invOpen and GetGameTimer() < timeoutAt do
            Wait(50)
        end

        if not canUseBag() then
            opening = false
            notify(locale('cannot_open'))
            return
        end

        local ok, err = lib.callback.await(resourceName .. ':openBag', false, data.slot)

        opening = false

        if ok == false and type(err) == 'string' then
            notify(err)
        end
    end)
end)

AddEventHandler('ox_inventory:closeInventory', function()
    TriggerServerEvent(resourceName .. ':closed')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == resourceName then
        opening = false
    end
end)
