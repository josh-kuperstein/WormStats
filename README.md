<!-- TODO: banner image goes here, e.g. ![Worm Stats](docs/banner.png) -->

# Worm Stats

A World of Warcraft addon that shows your character's stats on a single line of text you can put anywhere on screen. You choose which stats appear and in what order, and each character keeps its own setup.

```
BUFFS 12   HIT 3%   CRIT 7.42%   SP 412   HASTE 2.10%
```

The line updates by itself when your gear, buffs or talents change.

## Installing

1. Download the latest `WormStats-vX.Y.Z.zip` from the [Releases](../../releases) page.
2. Extract it into your client's AddOns folder, so you end up with `World of Warcraft/<client folder>/Interface/AddOns/WormStats/`.
3. Restart the game or type `/reload`.

## Using it

Type `/ws` to open the options window. Tick a stat to show it on the line, and use the arrow buttons to move it left or right. Untick **Lock position** to drag the line where you want it, then tick it again.

| Command | What it does |
|---|---|
| `/ws` or `/ws config` | Open or close the options window |
| `/ws lock` / `/ws unlock` | Lock the line in place, or unlock it to drag |
| `/ws scale <n>` | Scale the line, from 0.5 to 3 |
| `/ws font <n>` | Set the font size, from 8 to 40 |
| `/ws reset` | Restore this character's default settings |

`/wormstats` works as well as `/ws`.

## Available stats

New characters start with buff count, spell hit, spell crit, spell power and haste turned on. Everything else is off until you tick it.

| Label | Stat |
|---|---|
| BUFFS | Number of buffs on you |
| HIT | Spell hit, or melee hit |
| CRIT | Spell crit (best school), or melee crit |
| SP | Spell power (best school) |
| SHADOW / FIRE / FROST / HOLY / NATURE / ARCANE | Spell power for a single school |
| HEAL | Healing power |
| HASTE | Haste |
| MP5 | Mana regen while casting, per 5 seconds |
| AP | Melee attack power |
| DMG | Physical damage modifier |
| RAP | Ranged attack power |
| RCRIT | Ranged crit |
| ARMOR | Armor |
| DODGE / PARRY / BLOCK | Dodge, parry and block chance |
| STR / AGI / STA / INT / SPI | Primary stats |

## If something shows "?"

A stat shows `?` when the game couldn't give the addon a value for it. The first time that happens to a stat in a session, Worm Stats prints the reason in chat, starting with `Worm Stats: <stat> failed:`. If you report a problem, please include that line.

When a game update removes an event the addon listens for, you'll see `Worm Stats: could not register <event>` when you log in. Stats that depend on that event may stop updating until the addon is fixed.

## Compatibility

Worm Stats is built for the Forever client (versions 1.60.x), which uses the modern 12.x addon API. The interface numbers in `WormStats.toc` follow the client version. To check yours, type:

```
/dump select(4, GetBuildInfo())
```

## Releasing

Releases are built by GitHub Actions. To publish one, set `## Version:` in `WormStats.toc` to the new version, commit, then push a matching tag, such as `v0.1.1`. The workflow checks that the tag matches the TOC version, zips the addon and creates the GitHub release.
