--[[
    Copy the three items below into ox_inventory/data/items.lua

    Images load from this resource (nui://dj-backpacks/...).
    You do not need to copy the PNGs into ox_inventory unless you
    prefer filenames like bag_small.png in ox_inventory/web/images.
]]

return {
    ['bag_small'] = {
        label = 'Small Duffle Bag',
        description = 'A compact duffle bag with 125 kg of storage. Inner weight does not affect you.',
        weight = 250,
        stack = false,
        close = true,
        consume = 0,
        client = {
            export = 'dj-backpacks.useBag',
            image = 'nui://dj-backpacks/web/images/bag_small.png',
        },
    },

    ['bag_medium'] = {
        label = 'Medium Duffle Bag',
        description = 'A mid-size duffle bag with 250 kg of storage. Inner weight does not affect you.',
        weight = 400,
        stack = false,
        close = true,
        consume = 0,
        client = {
            export = 'dj-backpacks.useBag',
            image = 'nui://dj-backpacks/web/images/bag_medium.png',
        },
    },

    ['bag_large'] = {
        label = 'Large Duffle Bag',
        description = 'A heavy-duty travel duffle with 500 kg of storage. Inner weight does not affect you.',
        weight = 600,
        stack = false,
        close = true,
        consume = 0,
        client = {
            export = 'dj-backpacks.useBag',
            image = 'nui://dj-backpacks/web/images/bag_large.png',
        },
    },
}
