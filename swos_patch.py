#!/usr/bin/env python3
"""Apply or remove Sensible World of Soccer engine patches.

Works on SWSENGPP.EXE (SWOS 2016/17 and 2024/25) and SWS.EXE (SWOS 95/96
European Championship Edition); the engine is recognised by its size.
Each patch in patches/<engine>/*.json lists byte runs with their original and
patched values. A patch is only written over bytes that still hold one of
the two, so a game changed some other way is refused rather than broken.

    python3 swos_patch.py SWSENGPP.EXE                 # show each patch's state (or SWS.EXE)
    python3 swos_patch.py SWSENGPP.EXE --apply KEY...  # apply patches
    python3 swos_patch.py SWSENGPP.EXE --remove KEY... # take patches out

The file is changed in place after a backup is written next to it.
"""

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path

ENGINES = {
    'swsengpp': {'label': 'SWOS 2016/17 and 2024/25 (SWSENGPP.EXE)', 'size': 2135087,
                 'sha256': 'd0ea0e7c53b408967ed788105aa9570a228fbd8761b40053b16fddc55d4d21d7'},
    'sws': {'label': 'SWOS 95/96 European Championship Edition (SWS.EXE)', 'size': 2133791,
            'sha256': 'e69db66ffeb94b6251356f2bb0d918b3dd197614b17108d3dfbebf16e02b251f'},
}
PATCHES = Path(__file__).resolve().parent / 'patches'


def load_patches(engine):
    files = sorted((PATCHES / engine).glob('*.json'))
    return {p['key']: p for p in (json.loads(f.read_text()) for f in files)}


def state(game, patch):
    original = patched = True
    for change in patch['changes']:
        size = len(change['original']) // 2
        current = bytes(game[change['offset']:change['offset'] + size])
        original = original and current == bytes.fromhex(change['original'])
        patched = patched and current == bytes.fromhex(change['patched'])
    return 'applied' if patched else 'available' if original else 'blocked'


def write(game, patch, source, target):
    for change in patch['changes']:
        size = len(change[source]) // 2
        if bytes(game[change['offset']:change['offset'] + size]) == bytes.fromhex(change[source]):
            game[change['offset']:change['offset'] + size] = bytes.fromhex(change[target])


def main():
    parser = argparse.ArgumentParser(description='Patch SWSENGPP.EXE or SWS.EXE')
    parser.add_argument('game', type=Path)
    parser.add_argument('--apply', nargs='+', default=[], metavar='KEY')
    parser.add_argument('--remove', nargs='+', default=[], metavar='KEY')
    args = parser.parse_args()

    game = bytearray(args.game.read_bytes())
    engine = next((k for k, e in ENGINES.items() if len(game) == e['size'] and game[:2] == b'MZ'), None)
    if engine is None:
        sys.exit(f'{args.game} is not SWSENGPP.EXE or SWS.EXE.')
    patches = load_patches(engine)

    unknown = [k for k in args.apply + args.remove if k not in patches]
    if unknown:
        sys.exit('Unknown patch: ' + ', '.join(unknown))

    if not args.apply and not args.remove:
        clean = bytearray(game)
        for patch in patches.values():
            write(clean, patch, 'patched', 'original')
        recognised = hashlib.sha256(clean).hexdigest() == ENGINES[engine]['sha256']
        print('Engine:', ENGINES[engine]['label'])
        print('Game:', 'recognised' if recognised else 'has changes not covered by these patches')
        for key, patch in patches.items():
            print(f'  [{state(game, patch):9}] {key:28} {patch["name"]}')
        return

    for key in args.apply + args.remove:
        if state(game, patches[key]) == 'blocked':
            sys.exit(f'"{patches[key]["name"]}" cannot be changed: this game has different bytes where it goes.')

    backup = args.game.with_name(args.game.name + '.bak')
    if not backup.exists():
        shutil.copyfile(args.game, backup)
        print('Backup:', backup)

    for key in args.remove:
        write(game, patches[key], 'patched', 'original')
    for key in args.apply:
        write(game, patches[key], 'original', 'patched')
    args.game.write_bytes(game)

    for key in args.apply:
        print('Applied:', patches[key]['name'])
    for key in args.remove:
        print('Removed:', patches[key]['name'])


if __name__ == '__main__':
    main()
