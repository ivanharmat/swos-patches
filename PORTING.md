# Carrying a code patch to the other engine

The two engines are the same game underneath. `SWSENGPP.EXE` is SWOS 96 with
SWOS++ built into it, which moves a lot of code and data about but changes
very little of it. So a routine can be found in the other engine by matching
the bytes around it, and an address by matching an instruction that refers to
it and reading the operand back.

Only `src/engine-*.inc` differs between the two. Everything else - the two
`.s` bodies and `build.py` - is shared.

## Matching

Wildcard any byte the loader relocates, since those differ between builds. The
LE fixup records say which they are. Then search the other engine's file for
what is left. A window of 40 bytes is usually enough to be unique.

That gives the routines. For a data address, take an instruction in the known
engine that refers to it, match *that*, and read the operand out of the match.

Most of the data turns out to be at the same address in both - the 68000
registers the translation kept (`D0` at `0xF146D` and so on), the camera, the
sprite tables. What moved is what SWOS++ added to or before: `g_currentMenu`,
the squad screen's variables, the in-game team records.

## Checking the answer

Matching is a guess until something confirms it. Two things do:

- **`SelectGoals` reads back.** In both engines it is the same seven
  instructions, and between them they name `SKILLDIFF2`, `SAVEPOS`,
  `GOALSMODE`, `SETUP`, `D0`, `SETCURENT` and `DRAWMENU`. If the disassembly
  at the matched address is that sequence, those seven are right:

      mov word ptr [SKILLDIFF2], 0xffff
      call SAVEPOS
      mov word ptr [GOALSMODE], 1
      call SETUP
      mov word ptr [D0], 0xb
      call SETCURENT
      jmp  DRAWMENU

- **The hook sites are unique and land where they should.** There are exactly
  three `call SETUP`, one `mov word ptr [D0], 18` followed by
  `jmp DrawMultipleItems`, and one `call DrawSprites` in the whole engine.

The squad menu is worth confirming too, since the skills patch works in terms
of entry ordinals: both engines have 64 entries at the same coordinates, the
tenth a 60-wide EXIT the game never shows, the twenty-second the TOT heading,
the sixty-fourth the last of the goals numbers.

## Spare code space

`engine-code-space` marks the unused tail of the code segment as usable and
adds a little to the data segment. How much tail there is differs:

| Engine | Code segment ends | Spare | After `unlimited-career` |
|---|---|---|---|
| `SWSENGPP.EXE` | `0xB0B79` | 1159 | 1068 |
| `SWS.EXE` | `0xB0859` | 1959 | 1868 |

`SWSENGPP.EXE` has less because SWOS++ is in there. That is why the skills
view and the score display are offered as a choice of one on 16/17 and as two
separate patches on 95/96, where both fit with 132 bytes to spare.

New code must not write into the code segment. The object is not marked
writable, and an emulator throws away a page it has translated as soon as
anything writes to it. Anything that has to be remembered goes in the spare
data instead, at `0x186800`, which the loader zero-fills.
