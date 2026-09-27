#!/usr/bin/env python3
"""Assemble the two code patches and write their definitions.

One body per patch in src/, one constants file per engine. Nothing here knows
an address: they all live in src/engine-*.inc, and PORTING.md says how the
95/96 ones were arrived at.

Needs clang (any version that can target i386) and an untouched copy of each
engine to read the replaced bytes out of:

    python3 build.py --swsengpp path/to/SWSENGPP.EXE --sws path/to/SWS.EXE
    python3 build.py --swsengpp path/to/SWSENGPP.EXE --check   # report only

Either engine may be left out; only the ones given are built.
"""
import json, os, struct, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SRC  = os.path.join(HERE, 'src')

ENGINES = {
    'swsengpp': dict(
        exe   = None,
        sha256= 'd0ea0e7c53b408967ed788105aa9570a228fbd8761b40053b16fddc55d4d21d7',
        cave  = 0xB0BD4,                      # after the career patch
        limit = 0xB1000,
        setup_calls = (0x112CF, 0x11436, 0x11457),
        row_jmp     = 0x13776,
        sprites_call= 0x15F08,
        exclusive   = True,                   # only one of the two fits
    ),
    'sws': dict(
        exe   = None,
        sha256= 'e69db66ffeb94b6251356f2bb0d918b3dd197614b17108d3dfbebf16e02b251f',
        cave  = 0xB08B4,
        limit = 0xB1000,
        setup_calls = (0x35CD3, 0x35E3A, 0x35E5B),
        row_jmp     = 0x3817B,
        sprites_call= 0x10D51,
        exclusive   = False,                  # its code segment ends earlier,
    ),                                        # leaving room for both
}

GROUP = dict(group='extra-feature',
             groupName='One extra feature (the engine has room for one)',
             groupDescription=(
                 'Two additions to choose between. Both put new code into the game, and this engine '
                 'has room for one of them - the 95/96 edition has room for both, and offers them '
                 'separately.'))

META = {
    'squad-skills': dict(
        variant='Skills on the squad screen',
        name='Skills on the squad screen',
        description=(
            "Adds a SKILLS button beside GOALS on the squad screen. It shows each player's "
            "seven skills - passing, heading, velocity, tackling, control, shooting and "
            "finishing - and his form, as numbered columns, the way GOALS shows his goals, "
            "with the column letters spelled out along the bottom. Press fire to go back."),
    ),
    'score-on-screen': dict(
        variant='Score always on screen',
        name='Score always on screen',
        description=(
            "Keeps the score in the top right corner for the whole match, home team first, "
            "three letters a side - so you never have to wait for the clock to come round. "
            "It writes the score into one of the spare text graphics and hands it to the game "
            "to draw, in the same list and by the same route as the clock and the players, so "
            "the game places it, clips it and puts it in order itself."),
    ),
}


# ---------------------------------------------------------------- assembling

def assemble(engine, patch, base):
    """The patch's machine code, placed at `base`, and where its entry points
    landed - read out of the object rather than written down here, so moving a
    routine about cannot quietly point a hook at the wrong place."""
    parts = ['.set BASE, 0x%X\n' % base,
             open(os.path.join(SRC, 'engine-%s.inc' % engine)).read(),
             open(os.path.join(SRC, '%s.s' % patch)).read()]
    with tempfile.TemporaryDirectory() as tmp:
        s = os.path.join(tmp, 'a.s'); o = os.path.join(tmp, 'a.o')
        open(s, 'w').write('\n'.join(parts))
        subprocess.run(['clang', '-target', 'i386-unknown-linux-gnu', '-c', '-o', o, s],
                       check=True)
        obj = open(o, 'rb').read()
        return text_of(obj), symbols(obj)


def symbols(obj):
    shoff = struct.unpack_from('<I', obj, 0x20)[0]
    entsz, num, strndx = struct.unpack_from('<HHH', obj, 0x2e)
    sh   = lambda i: struct.unpack_from('<10I', obj, shoff + i * entsz)
    st   = sh(strndx); names = obj[st[4]:st[4] + st[5]]
    name = lambda i: names[sh(i)[0]:names.find(b'\0', sh(i)[0])].decode()
    symtab = strtab = None
    for i in range(num):
        if name(i) == '.symtab': symtab = sh(i)
        if name(i) == '.strtab': strtab = sh(i)
    ss = obj[strtab[4]:strtab[4] + strtab[5]]
    out = {}
    for off in range(symtab[4], symtab[4] + symtab[5], 16):
        n, v, _, _, _, _ = struct.unpack_from('<IIIBBH', obj, off)
        nm = ss[n:ss.find(b'\0', n)].decode()
        if nm: out[nm] = v
    return out


def text_of(obj):
    """The .text of an ELF object - refusing anything left unresolved.

    A relocation against .text is fine: the section sits at zero, so the bytes
    already hold what they should. One against an undefined symbol means a
    label never resolved and a jump would land on the addend, which is how an
    invalid opcode once got into a released patch.
    """
    shoff = struct.unpack_from('<I', obj, 0x20)[0]
    entsz, num, strndx = struct.unpack_from('<HHH', obj, 0x2e)
    sh   = lambda i: struct.unpack_from('<10I', obj, shoff + i * entsz)
    st   = sh(strndx); names = obj[st[4]:st[4] + st[5]]
    name = lambda i: names[sh(i)[0]:names.find(b'\0', sh(i)[0])].decode()

    symtab = strtab = None
    for i in range(num):
        if name(i) == '.symtab': symtab = sh(i)
        if name(i) == '.strtab': strtab = sh(i)
    for i in range(num):
        if name(i).startswith('.rel') and symtab:
            s, ss = sh(i), obj[strtab[4]:strtab[4] + strtab[5]]
            for off in range(s[4], s[4] + s[5], 8):
                _, info = struct.unpack_from('<II', obj, off)
                n, _, _, _, _, shndx = struct.unpack_from('<IIIBBH', obj, symtab[4] + (info >> 8) * 16)
                if shndx == 0:
                    raise SystemExit('%s is undefined - a label did not resolve'
                                     % ss[n:ss.find(b'\0', n)].decode())
    for i in range(num):
        if name(i) == '.text':
            s = sh(i); return obj[s[4]:s[4] + s[5]]
    raise SystemExit('no .text')


# ------------------------------------------------------------------ the file

def image(engine):
    import hashlib
    d = open(ENGINES[engine]['exe'], 'rb').read()
    got = hashlib.sha256(d).hexdigest()
    if got != ENGINES[engine]['sha256']:
        raise SystemExit('%s is not the untouched engine (%s)' % (engine, got[:16]))
    return d


def le(d):
    """Enough of the LE header to turn an address into a file offset."""
    le = struct.unpack_from('<I', d, 0x3c)[0]
    u32 = lambda o: struct.unpack_from('<I', d, o)[0]
    pagesize, objtab, objcnt = u32(le + 0x28), le + u32(le + 0x40), u32(le + 0x44)
    datapages = u32(le + 0x80)
    objs = [struct.unpack_from('<6I', d, objtab + i * 24) for i in range(objcnt)]
    def fileoff(addr):
        for vsize, base, flags, pidx, pcnt, _ in objs:
            if base <= addr < base + pcnt * pagesize:
                rel = addr - base
                return datapages + (pidx - 1 + rel // pagesize) * pagesize + rel % pagesize
        raise SystemExit('%x is not in the file' % addr)
    return fileoff


def build(engine, write=True):
    cfg = ENGINES[engine]; d = image(engine); fileoff = le(d)
    out, base = {}, cfg['cave']

    for patch in ('squad-skills', 'score-on-screen'):
        code, sym = assemble(engine, 'skills' if patch == 'squad-skills' else 'score', base)
        changes = []

        def add(addr, new, note):
            f = fileoff(addr); old = d[f:f + len(new)]
            assert old != new, hex(addr)
            changes.append(dict(offset=f, original=old.hex(), patched=new.hex(), note=note))

        rel = lambda op, at, to: bytes([op]) + struct.pack('<i', to - (at + 5))
        if patch == 'squad-skills':
            for site in cfg['setup_calls']:
                add(site, rel(0xE8, site, base + sym['OnSetupClear']),
                    'Squad screen setup goes through the new code')
            add(cfg['row_jmp'], rel(0xE9, cfg['row_jmp'], base + sym['RowDraw']),
                'Squad row drawing goes through the new code')
            add(base, code, 'The SKILLS view')
        else:
            add(cfg['sprites_call'], rel(0xE8, cfg['sprites_call'], base),
                'The match loop draws its sprites through the new code')
            add(base, code, 'The score display')

        defn = dict(key=patch)
        if cfg['exclusive']:
            defn.update(GROUP); defn['variant'] = META[patch]['variant']
        defn['name'] = META[patch]['name']
        defn['description'] = META[patch]['description']
        defn['requires'] = ['engine-code-space']
        defn['changes'] = changes
        out[patch] = defn

        end = base + len(code)
        print('  %-16s %4d bytes at %06x..%06x' % (patch, len(code), base, end))
        if not cfg['exclusive']:
            base = (end + 3) & ~3                       # they sit side by side
        if end > cfg['limit']:
            raise SystemExit('%s overruns the spare code space by %d bytes'
                             % (patch, end - cfg['limit']))

    if write:
        for patch, defn in out.items():
            p = os.path.join(HERE, 'patches', engine, patch + '.json')
            json.dump(defn, open(p, 'w'), indent=4); open(p, 'a').write('\n')
    return out


if __name__ == '__main__':
    args = sys.argv[1:]
    write = '--check' not in args
    asked = False
    for engine in ENGINES:
        if '--' + engine in args:
            ENGINES[engine]['exe'] = args[args.index('--' + engine) + 1]
            asked = True
    if not asked:
        raise SystemExit(__doc__)
    for engine, cfg in ENGINES.items():
        if not cfg['exe']:
            continue
        print(engine + ':')
        build(engine, write)
