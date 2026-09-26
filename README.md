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

Offsets are file offsets in the unmodified engine:

- `SWSENGPP.EXE`: 2,135,087 bytes, SHA-256 `d0ea0e7c53b408967ed788105aa9570a228fbd8761b40053b16fddc55d4d21d7`
- `SWS.EXE`: 2,133,791 bytes, SHA-256 `e69db66ffeb94b6251356f2bb0d918b3dd197614b17108d3dfbebf16e02b251f`

## Licence

MIT - see [LICENSE](LICENSE). Sensible World of Soccer itself is not covered and is not included.
