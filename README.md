# dj-backpacks

ox_inventory duffle bags that keep their items after restarts. The bag itself is light to carry. Anything stored inside lives in its own stash, so that weight is **not** added to the player's inventory.

## Bags

| Item | Carry weight | Capacity | Slots |
| --- | --- | --- | --- |
| `bag_small` | 0.25 kg | 125 kg | 25 |
| `bag_medium` | 0.40 kg | 250 kg | 40 |
| `bag_large` | 0.60 kg | 500 kg | 60 |

Each bag gets a unique id when it is created. Use the item to open it. The same bag always opens the same stash, including after a server restart.

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory) 2.31+

## Install

1. Place this resource in your resources folder as **`dj-backpacks`** (the folder name must match).
2. Copy the three item definitions from `install/items.lua` into `ox_inventory/data/items.lua`.
3. Restart `ox_inventory`, then start this resource:

```cfg
ensure ox_lib
ensure ox_inventory
ensure dj-backpacks
```

4. Give a bag with the ox_inventory item commands, a shop, or:

```
/givebag [playerId] small
/givebag [playerId] medium
/givebag [playerId] large
```

`givebag` is restricted to `group.admin`.

Images are served from this resource. You do not need to copy PNGs into ox_inventory.

## Why inner weight does not count

ox_inventory **containers** add their contents to the player weight. These bags are **stashes** keyed by `metadata.bagId` instead. The player only carries the empty duffle (0.25 / 0.40 / 0.60 kg). Stash contents are saved in the ox_inventory database and reload after restarts.

## Safety

- Bags cannot be stored inside other bags
- The bag you currently have open cannot be moved, dropped, or given
- Optional carry limit (`Config.MaxBags`, default 3)
- Optional item blacklist / whitelist
- Server validates the slot before opening a stash
- Open requests are rate limited

## Config

Edit `config.lua` for capacity, slots, carry weight, max bags, and item filters.

If you change `Config.StashPrefix` after players already have bags, existing stashes will not open.

## Exports

```lua
exports['dj-backpacks']:isBagItem('bag_small')
exports['dj-backpacks']:getBagConfig('bag_medium')
exports['dj-backpacks']:stashId(bagId)
```

`Player(id).state.djBagOpen` is the open bag id, or `false` when closed.
