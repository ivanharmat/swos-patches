# SWOS engine patches

Byte patches for the Sensible World of Soccer game engine, `SWSENGPP.EXE`.
The 2016/17 and 2024/25 editions ship the same engine, so every patch works
for both.

The game itself is not here - only the patches. Each one lists the exact
bytes it replaces, so it is only applied to an unmodified copy of those
bytes and can always be taken out again.

## Patches

| Key | What it does |
|---|---|
| `uefa-cup-slovakia` | Slovakia gets 3 UEFA Cup places when you manage there and averages 2 otherwise. |
| `champions-league-slovakia` | The Slovak champion always plays in the Champions League (European Cup). |
| `cup-winners-cup-slovakia` | The Slovak cup winner always plays in the Cup Winners' Cup. |
| `unlimited-transfers` | The chairman no longer stops you signing players. From the next season or job. |
| `unlimited-career` | Careers carry on past 20 seasons; the management record keeps the latest 20. |

## Installing

Keep a copy of your original `SWSENGPP.EXE` first.

**On the web:** upload your game on the Game Patches page of
[swos1617.com](https://swos1617.com/patches), tick the patches you want and
download the patched file.

**With Python 3** (no extra packages needed):

```bash
python3 swos_patch.py path/to/SWSENGPP.EXE
python3 swos_patch.py path/to/SWSENGPP.EXE --apply unlimited-career unlimited-transfers
python3 swos_patch.py path/to/SWSENGPP.EXE --remove unlimited-transfers
```

The first command shows which patches the game carries. Applying writes a
`SWSENGPP.EXE.bak` backup next to the game the first time.

## Patch format

`patches/<key>.json`:

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

Offsets are file offsets in `SWSENGPP.EXE` (2,135,087 bytes, SHA-256
`d0ea0e7c53b408967ed788105aa9570a228fbd8761b40053b16fddc55d4d21d7`).

## Licence

MIT - see [LICENSE](LICENSE). Sensible World of Soccer itself is not covered and is not included.
