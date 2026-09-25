Config = {}

--- Prefix used for every bag stash id. Do not change after players already have bags.
Config.StashPrefix = 'djbag_'

--- Minimum time between bag opens per player, in milliseconds.
Config.OpenCooldown = 500

--- How many bag items a player can carry at once. Set to false or 0 for no limit.
Config.MaxBags = 3

--- Block storing any bag item inside another bag stash.
Config.PreventBagInBag = true

--- Stop the open bag item from being moved, dropped, or given until the inventory closes.
Config.LockOpenBag = true

--- Item names that cannot be placed inside any bag.
Config.Blacklist = {
    -- money = true,
}

--- Optional item names that are the only things allowed inside bags.
--- Leave empty to allow everything except blacklisted / bag items.
Config.Whitelist = {
    -- water = true,
}

--- Debug prints for bag open / hook rejects.
Config.Debug = false

--- Bag definitions.
--- weight is the stash capacity in grams (ox_inventory unit). 1000 = 1 kg.
--- carryWeight is the item weight while the bag is in the player's inventory.
--- Inner stash weight is never added to the player because bags are stashes, not containers.
Config.Bags = {
    bag_small = {
        label = 'Small Duffle Bag',
        slots = 25,
        weight = 125000,
        capacityKg = 125,
        carryWeight = 250,
        image = 'nui://dj-backpacks/web/images/bag_small.png',
    },
    bag_medium = {
        label = 'Medium Duffle Bag',
        slots = 40,
        weight = 250000,
        capacityKg = 250,
        carryWeight = 400,
        image = 'nui://dj-backpacks/web/images/bag_medium.png',
    },
    bag_large = {
        label = 'Large Duffle Bag',
        slots = 60,
        weight = 500000,
        capacityKg = 500,
        carryWeight = 600,
        image = 'nui://dj-backpacks/web/images/bag_large.png',
    },
}
