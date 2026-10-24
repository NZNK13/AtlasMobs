# AtlasMobs

AtlasMobs is a World of Warcraft Forever addon that displays numbered mob locations on the world map. Marker colors show mob difficulty relative to a manually selected player level.

## Features

- Numbered spawn markers on the world map
- Difficulty colors based on the mob's average level
- Type, reaction, level, and rank filters
- Per-mob visibility controls with enabled-only and select-all options
- Adjustable marker size, opacity, and window scale
- Optional layout with the maximized world map docked to the left
- Silverpine Forest, The Barrens, Tirisfal Glades, and Thousand Needles data

## Installation

1. Download or clone the repository.
2. Copy the `AtlasMobs` folder into `World of Warcraft/_classic_beta_/Interface/AddOns`.
3. Start the game or run `/reload` if it is already open.

The addon targets interface version `16001`.

## Adding a zone

Create a file under `Data`, call `AtlasMobs:RegisterZone(...)`, then list the file in `AtlasMobs.toc` after `Core.lua`.

Each mob record contains its marker number, NPC ID, English name, level range, creature type, reaction, elite flag, and normalized map coordinates.

## License

AtlasMobs is available under the [MIT License](LICENSE).
