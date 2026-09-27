.intel_syntax noprefix
.code32
.text
# A SKILLS view for the squad screen (SWSENGPP.EXE).
#
# The screen already has a second view - GOALS - that hides the buttons and
# swaps the right-hand columns for numbers. This adds a third one the same
# way: a SKILLS button beside it, and the seven skill nibbles plus form drawn
# as columns, one number per player row.
#
# Nothing is added to the menu itself. The game works from a converted copy
# in g_currentMenu, so the dead tenth entry - a wide EXIT the game never
# shows - is rebuilt there, at runtime, into the new button. Two entries this
# view has no use for, the TOT heading and the last goals number, are
# borrowed as stencils: moved along the row, drawn, and put back.
#
# This routine never writes into the code segment. DOS emulators translate a
# page of code once and throw the translation away when something writes to
# that page, so a routine that kept its counters beside itself would be
# retranslated several times a frame - which is what the score-in-the-corner
# attempt died of. The per-row numbers live on the stack, and the three
# values that outlive a frame live in the spare data the "room for added
# code" patch makes.
#
# New code gets no relocations, so both shifts are worked out at runtime: ebp
# for this code, from its own address, and ebx for the game's data, from a
# pointer the loader already fixed up inside CalcMenuEntryAddress.

.macro CALLABS target
99: .byte 0xe8
    .long \target - BASE - (99b - start) - 5
.endm
.macro JMPABS target
98: .byte 0xe9
    .long \target - BASE - (98b - start) - 5
.endm


.set ENTRIES,       CURMENU + 0x16  # first entry of the converted menu



.set V_MODE,        VARS + 0        # 1 while the skills view is up
.set V_FORM,        VARS + 4        # form, spelled out (see FormText)


.set ENTSZ,         56
.set E_SHIRT,       46 * 56         # the row's own columns, in menu order
.set E_NAME,        48 * 56
.set E_NUM,         63 * 56         # last of the goals numbers - our stencil
.set E_GOALS,       8 * 56
.set E_SKILLS,      10 * 56

.set NUMX,          297             # where the two stencils sit when idle
.set NUMW,          12
.set COL0,          182             # first skill column, converted coordinates
.set COLSTEP,       15
.set COLW,          14
.set HEADY,         14
.set FIRSTROWY,     24

# the row's working set, on the stack; DrawColumns reads it past its own
# return address, so every offset there is four higher
.set F_VALS,        0               # eight words, in column order
.set F_ROWY,        16
.set F_COLX,        18
.set F_COLW,        20
.set F_COL,         22
.set F_KIND,        24              # 0 = the numbers, 1 = the letters
.set FRAME,         28

start:
# --------------------------------------------------------------------------
# ebp = this code's shift, ebx = the game's data shift, edi = first entry.
# Reloaded after every call into the game, which keeps its state in memory
# and hands no registers back.
reload:
    call rhere
rhere:
    pop ebp
    sub ebp, 5                      # rhere sits five bytes into this routine
    sub ebp, BASE
    mov ebx, dword ptr [ebp + MENUPTRSRC]
    sub ebx, CURMENU
    lea edi, [ebx + ENTRIES]
    ret

# --------------------------------------------------------------------------
# Replaces the three "call SETUP" of the squad screen. Leaving the screen and
# picking GOALS both come through here, so this is where skills mode ends.
OnSetupClear:
    pushad
    call reload
    mov word ptr [ebx + V_MODE], 0
    popad
OnSetup:
    CALLABS SETUP
    call ApplyLayout
    ret

# --------------------------------------------------------------------------
# The SKILLS button. Same shape as SelectGoals: remember the squad order so
# the bench cannot be reshuffled while the numbers are up, switch the screen
# over, and park the cursor on the invisible entry that takes any fire press
# back.
OnSelectSkills:
    call reload
    mov word ptr [ebx + SKILLDIFF2], 0xFFFF
    CALLABS SAVEPOS
    call reload
    mov word ptr [ebx + GOALSMODE], 1
    mov word ptr [ebx + V_MODE], 1
    call OnSetup
    call reload
    mov word ptr [ebx + D0], 11
    CALLABS SETCURENT
    JMPABS DRAWMENU

# --------------------------------------------------------------------------
# Runs after the game has laid the screen out, every time the view changes.
ApplyLayout:
    pushad
    cld
    call reload
    mov esi, dword ptr [ebx + SQUADTEAM]    # on another club's squad the game
    cmp byte ptr [esi + 4], 1               # shows the tenth entry itself, as
    je 4f                                   # one wide EXIT - so leave the
                                            # screen entirely alone there
    lea esi, [edi + 9 * ENTSZ]              # four buttons where there were
    mov word ptr [esi + 20], 171            # three: EXIT
    mov word ptr [esi + 24], 33
    lea esi, [edi + E_GOALS]                # GOALS
    mov word ptr [esi + 20], 207
    mov word ptr [esi + 24], 33
    mov byte ptr [esi + 9], 10
    mov byte ptr [esi + 17], 10
    lea esi, [edi + 6 * ENTSZ]              # TRAINING, shortened: eight
    mov word ptr [esi + 20], 279            # letters are wider than a
    mov word ptr [esi + 24], 33             # quarter of the row
    lea eax, [ebp + BASE + strTrain]
    mov dword ptr [esi + 38], eax
    mov byte ptr [esi + 8], 10
    mov byte ptr [esi + 16], 10

    push edi                                # the entry rebuilt as a button
    lea esi, [ebp + BASE + tSkillsButton]
    lea edi, [edi + E_SKILLS + 4]
    mov ecx, 9
    rep movsd
    pop edi
    lea esi, [edi + E_SKILLS]
    lea eax, [ebp + BASE + HideWithGoals]   # shown exactly when GOALS is,
    mov dword ptr [esi + 48], eax           # decided afresh on every frame
    lea eax, [ebp + BASE + strSkills]
    mov dword ptr [esi + 38], eax
    lea eax, [ebp + BASE + OnSelectSkills]
    mov dword ptr [esi + 42], eax

    cmp word ptr [ebx + V_MODE], 0
    je 3f
    mov ecx, 13                             # the goals headings and totals
2:                                          # have no place in this view:
    cmp ecx, 16                             # entries 13 to 27, bar the title
    je 6f                                   # and the black bar
    cmp ecx, 23
    je 6f
    mov eax, ecx
    imul eax, eax, ENTSZ
    mov word ptr [edi + eax + 4], 1
6:
    inc ecx
    cmp ecx, 28
    jne 2b
5:
    lea esi, [edi + E_SKILLS]               # no buttons in this view, so the
    mov byte ptr [esi + 20], 2              # one we built carries the key to
    mov byte ptr [esi + 22], 183            # the columns along the bottom,
    mov word ptr [esi + 24], 302            # a line above where it sat
    mov byte ptr [esi + 26], 8
    mov byte ptr [esi + 28], 0              # no frame behind it
    mov byte ptr [esi + 37], 0x40           # left aligned
    lea eax, [ebp + BASE + strLegend]
    mov dword ptr [esi + 38], eax
    mov dword ptr [esi + 48], 0             # and it stays out of the way GOALS
    jmp 4f                                  # goes, by its own means now
3:
    xor eax, eax                            # the game re-hides what it wants
    call Vis5063                            # to; what it never re-shows would
    call RestStencil                        # stay hidden for good otherwise
4:
    popad
    ret

# --------------------------------------------------------------------------
# The button keeps company with GOALS: the game hides that one in several
# places, and the copy is only ever taken while the button is being drawn.
HideWithGoals:
    pushad
    call reload
    mov ax, word ptr [edi + E_GOALS + 4]
    mov esi, dword ptr [ebx + A5]
    mov word ptr [esi + 4], ax
    popad
    ret

# --------------------------------------------------------------------------
# Replaces the tail of the row draw, which normally draws all eighteen column
# entries. In skills mode only the first four - shirt, number, name, position
# - are the game's; the rest of the row is ours.
RowDraw:
    pushad
    call reload
    cmp word ptr [ebx + V_MODE], 0
    jne 1f
    mov word ptr [ebx + D0], 18
    popad
    JMPABS DRAWMULTI
1:
    mov word ptr [ebx + D0], 4
    CALLABS DRAWMULTI
    call reload
    cmp word ptr [edi + E_NAME + 4], 0
    jne 3f                                  # no name, no player on this row

    sub esp, FRAME
    mov esi, dword ptr [ebx + DRAWNPLAYER]  # where its skills are packed:
    xor ecx, ecx                            # four bytes, seven nibbles, in a
1:                                          # different order from the columns
    movzx edx, byte ptr [ebp + ecx + BASE + tPick]
    mov eax, edx
    and eax, 3
    movzx eax, byte ptr [esi + eax + 0x68]
    test dl, 0x80
    je 2f
    shr eax, 4
2:
    and eax, 7
    mov word ptr [esp + ecx * 2 + F_VALS], ax
    inc ecx
    cmp ecx, 7
    jne 1b

    movsx eax, byte ptr [esi + 0x71]
    mov word ptr [esp + F_VALS + 14], ax    # form

    mov ax, word ptr [edi + E_SHIRT + 22]   # the line this row sits on
    mov word ptr [esp + F_ROWY], ax
    mov dword ptr [esp + F_KIND], 0
    call DrawColumns
    cmp word ptr [esp + F_ROWY], FIRSTROWY  # the letters, once, above them
    jne 2f
    mov dword ptr [esp + F_KIND], 1
    call DrawColumns
2:
    add esp, FRAME
3:
    call reload
    push 1                                  # nothing else of the row's own
    pop eax
    call Vis5063
    popad
    ret

# --------------------------------------------------------------------------
# Entries 50 to 63, hidden or shown together, by the word in ax. The game sets
# some of them on every row it draws and never touches others, so what this
# view hides it has to put back itself.
Vis5063:
    lea esi, [edi + 50 * ENTSZ]
    mov ecx, 14
1:
    mov word ptr [esi + 4], ax
    add esi, ENTSZ
    dec ecx
    jnz 1b
    ret

# --------------------------------------------------------------------------
# Eight columns: the seven skills and form, or the letters above them. The
# row's working set is on the stack, just past this routine's return address.
DrawColumns:
    call reload
    mov word ptr [esp + 4 + F_COLX], COL0
    mov word ptr [esp + 4 + F_COLW], COLW
    mov word ptr [esp + 4 + F_COL], 0
1:
    call reload
    movzx edx, word ptr [esp + 4 + F_COL]
    cmp dword ptr [esp + 4 + F_KIND], 0
    jne 2f
    lea esi, [edi + E_NUM]
    mov ax, word ptr [esp + 4 + F_ROWY]
    mov word ptr [esi + 22], ax
    cmp edx, 7
    je 5f
    mov word ptr [esi + 34], 6              # a number
    mov ax, word ptr [esp + edx * 2 + 4 + F_VALS]
    mov word ptr [esi + 38], ax
    jmp 3f
5:
    movsx eax, word ptr [esp + 4 + F_VALS + 14]     # form can be either side
    push esi                                        # of zero, and the game's
    call FormText                                   # own printer divides by
    pop esi                                         # 1000 on a sign-extended
    call reload                                     # word - so it spells out
    lea eax, [ebx + V_FORM]                         # anything negative into a
    mov word ptr [esi + 34], 2                      # divide error
    mov dword ptr [esi + 38], eax
    jmp 3f
2:
    lea esi, [edi + E_NUM]
    mov word ptr [esi + 22], HEADY
    mov word ptr [esi + 34], 2
    lea eax, [edx + edx * 2]
    lea eax, [ebp + eax + BASE + strHeads]
    mov dword ptr [esi + 38], eax
3:
    mov word ptr [esi + 4], 0
    mov ax, word ptr [esp + 4 + F_COLX]
    mov word ptr [esi + 20], ax
    mov ax, word ptr [esp + 4 + F_COLW]
    mov word ptr [esi + 24], ax
    mov dword ptr [ebx + A5], esi
    CALLABS DRAWITEM
    call reload
    mov ax, word ptr [esp + 4 + F_COLX]
    add ax, COLSTEP
    mov word ptr [esp + 4 + F_COLX], ax
    inc word ptr [esp + 4 + F_COL]
    cmp word ptr [esp + 4 + F_COL], 8
    jne 1b
RestStencil:
    lea esi, [edi + E_NUM]
    mov word ptr [esi + 34], 6
    mov word ptr [esi + 4], 1
    mov word ptr [esi + 20], NUMX
    mov word ptr [esi + 24], NUMW
    ret

# --------------------------------------------------------------------------
# eax, between -128 and 127, into V_FORM. Clobbers eax, ecx, edx and edi.
FormText:
    lea edi, [ebx + V_FORM]
    test eax, eax
    jns 1f
    mov byte ptr [edi], 0x2D
    inc edi
    neg eax
1:
    xor ecx, ecx
2:
    cmp eax, 100
    jb 3f
    sub eax, 100
    inc ecx
    jmp 2b
3:
    xor edx, edx
4:
    cmp eax, 10
    jb 5f
    sub eax, 10
    inc edx
    jmp 4b
5:
    test ecx, ecx
    jz 6f
    add cl, 0x30
    mov byte ptr [edi], cl
    inc edi
    jmp 7f
6:
    test edx, edx
    jz 8f
7:
    add dl, 0x30
    mov byte ptr [edi], dl
    inc edi
8:
    add al, 0x30
    mov byte ptr [edi], al
    mov byte ptr [edi + 1], 0
    ret

# --------------------------------------------------------------------------
strSkills:
    .asciz "SKILLS"
strTrain:
    .asciz "TRAIN."
strHeads:
    .byte 'P', 0, 0, 'H', 0, 0, 'V', 0, 0, 'T', 0, 0
    .byte 'C', 0, 0, 'S', 0, 0, 'F', 0, 0, 'F', 'M', 0
tPick:                                          # low two bits: which byte of
    .byte 0x00, 0x01, 0x81, 0x82, 0x02, 0x83, 0x03   # the four; top bit: the
                                                     # high nibble of it

.align 4
tSkillsButton:                                  # menu entry fields 4 to 39
    .word 0, 0                                  # shown, enabled
    .byte 8, 6, 44, 255                         # left, right, up, down
    .byte 0, 1, 2, 3                            # where a skip carries on
    .byte 8, 6, 44, 255
    .word 243, 185, 33, 15                      # x, y, width, height
    .word 2                                     # a framed entry
    .long 0x0E                                  # green, like GOALS beside it
    .word 2, 0                                  # with a string on it, centred
    .word 0, 0                                  # (the text follows at runtime)
strLegend:
    .asciz "PASS HEAD SHOT TACK CTRL SPD FIN FORM"
end:
