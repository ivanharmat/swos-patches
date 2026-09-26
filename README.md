# SWOS engine patches

Byte patches for the Sensible World of Soccer game engines:

| Engine | Editions | Patches |
|---|---|---|
| `SWSENGPP.EXE` | 2016/17 and 2024/25 (same engine) | `patches/swsengpp/` |
| `SWS.EXE` | 95/96 European Championship Edition | `patches/sws/` |

Every patch exists for both engines. The script and the website recognise
which engine you have by its size.

The game itself is not here - only the patches. Each one lists the exact
bytes it replaces, so it is only applied to an unmodified copy of those
bytes and can always be taken out again.

## Patches

| Key | What it does |
|---|---|
| `european-places-<league>` | One league of your choice gets far more European places: its champion always plays in the Champions League, its cup winner always in the Cup Winners' Cup, and it gets three UEFA Cup places when you manage there (about two otherwise). The first season is drawn from fixed line-ups inside the game, so the league's strongest clubs are put into those as well. One league at a time; any European league outside the top group (Germany, Italy, Spain, England) can be picked, for example `european-places-slovakia`. |
| `unlimited-transfers` | The chairman no longer stops you signing players. From the next season or job. |
| `unlimited-career` | Careers carry on past 20 seasons; the management record keeps the latest 20. |
| `squad-skills` | A SKILLS button on the squad screen, beside GOALS. Shows every player's seven skills and his form as numbered columns, with the column letters spelled out along the bottom. Fire goes back. |
| `score-on-screen` | The score stays in the top right corner for the whole match, home team first, three letters a side. |

`squad-skills` and `score-on-screen` add code, and the engine has only so much
spare room for that. On `SWSENGPP.EXE` there is room for one of the two, so
they are offered as a choice; on `SWS.EXE` there is room for both.

## Installing

Keep a copy of your original `SWSENGPP.EXE` first.

**On the web:** upload `SWSENGPP.EXE` or `SWS.EXE` on the Game Patches page of
[swos1617.com](https://swos1617.com/patches), tick the patches you want and
download the patched file.

**With Python 3** (no extra packages needed):

```bash
python3 swos_patch.py path/to/SWSENGPP.EXE
python3 swos_patch.py path/to/SWSENGPP.EXE --apply unlimited-career unlimited-transfers
python3 swos_patch.py path/to/SWSENGPP.EXE --remove unlimited-transfers
```

The same commands work with `SWS.EXE`. The first command shows which
patches the game carries. Applying writes a `.bak` backup next to the game
the first time.

## Building the code patches

Most patches here are a handful of replaced bytes and are written by hand.
`squad-skills` and `score-on-screen` are compiled: their source is in `src/`,
one body per patch and one file of addresses per engine.

```bash
python3 build.py --swsengpp path/to/SWSENGPP.EXE --sws path/to/SWS.EXE
```

Needs `clang` and an **untouched** copy of each engine, which it checks by
SHA-256 - it reads the replaced bytes out of it. `--check` builds and reports
without writing. [PORTING.md](PORTING.md) explains how the addresses for the
second engine were arrived at and how they were checked.

## Patch format

`patches/<engine>/<key>.json`:

```json
{
    "key": "unlimited-transfers",
    "name": "No chairman transfer limit",
    "description": "...",
    "changes": [
        { "offset": 1185468, "original": "6001", "patched": "ff7f", "note": "..." }
    ]
}
```

A patch may also carry `requires`, naming another patch it needs, and
`group` with `variant`, marking it one of a set only one of which can be
applied at a time.

Offsets are file offsets in the unmodified engine:

- `SWSENGPP.EXE`: 2,135,087 bytes, SHA-256 `d0ea0e7c53b408967ed788105aa9570a228fbd8761b40053b16fddc55d4d21d7`
- `SWS.EXE`: 2,133,791 bytes, SHA-256 `e69db66ffeb94b6251356f2bb0d918b3dd197614b17108d3dfbebf16e02b251f`

## Licence

MIT - see [LICENSE](LICENSE). Sensible World of Soccer itself is not covered and is not included.
