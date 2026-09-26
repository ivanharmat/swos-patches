.intel_syntax noprefix
.code32
.text
# Score in the top-right corner during a match (SWSENGPP.EXE).
# Replaces "call DrawSprites" in the match main loop: lets the game draw its
# own sprites first, then draws the score over them.
#
# The loader relocates the game, and new code gets no relocations of its own,
# so this works out both shifts at runtime: ebp for this code (from its own
# address) and ebx for the game's data (from an address the loader already
# fixed up inside UpdateTime). Addresses below are file addresses, reached as
# [ebp + ...] for our own code or [ebx + ...] for the game's data.
#
# The few bytes it remembers sit in the spare data the "room for added code"
# patch makes, not beside the routine: the code segment is not marked
# writable, and an emulator throws away a translated page as soon as anything
# writes to it.
#
# Per frame this only compares the score and draws; the text is rebuilt just
# when the score changes, so a slow machine is not asked to render text and
# wipe a graphic sixty times a second. The few bytes it remembers sit in the
# spare code space with the routine.

.set SPR,         SVARS + 0x20  # our own sprite, 110 bytes of zeroes and three
.set SAVEDN,      SVARS + 0x18  # fields; teamNumber stays nought, which keeps
                                # the highlight recorder out of it
                                # (the wide end-of-match banner was slow to draw)
.set INGAME,      10            # -> TeamGame
.set TEAMNUMBER,  18
.set TEAMNAME,    22
.set CACHE1,      SVARS + 0     # to - in data, never beside the code
.set CACHE2,      SVARS + 2
.set VALID,       SVARS + 4
.set WIDTH,       SVARS + 6

start:
    pushad
    pushfd
    cld
    call here
here:
    pop ebp
    sub ebp, BASE + 8                       # 8 = bytes from start to here
    mov ebx, dword ptr [ebp + A0OPERAND]
    sub ebx, A0                             # where the game's data really sits
    mov ax, word ptr [ebx + NUMSPRITES]     # put the list back exactly as it
    mov word ptr [ebx + SAVEDN], ax         # was, once the game has drawn it

    lea esi, [ebx + D0]                     # the game's scratch registers, kept
    mov ecx, 15                             # on the stack rather than in our page
save:                                       # plain forms only: DOSBox 0.74's
    mov eax, dword ptr [esi]                # dynamic core is old, and push/pop
    push eax                                # straight to memory is a known
    add esi, 4                              # weak spot
    dec ecx
    jnz save

    mov ax, word ptr [ebx + TEAM1GOALS]     # nothing to do most frames
    mov dx, word ptr [ebx + TEAM2GOALS]
    cmp word ptr [ebx + VALID], 0
    je rebuild
    cmp ax, word ptr [ebx + CACHE1]
    jne rebuild
    cmp dx, word ptr [ebx + CACHE2]
    jne rebuild
    cmp word ptr [ebx + VALID], 1           # 2 means this score was tried and
    jne done                                # would not go in: let it lie
    jmp place                                # rather than build it again, and
                                            # blank the graphic again, on every
rebuild:                                    # one of fifty frames a second
    mov word ptr [ebx + CACHE1], ax
    mov word ptr [ebx + CACHE2], dx
    mov word ptr [ebx + VALID], 2
    sub esp, 16                             # the text, built on the stack
    mov edi, esp
    mov eax, dword ptr [ebx + LEFTTEAM + INGAME]
    mov edx, dword ptr [ebx + RIGHTTEAM + INGAME]
    cmp word ptr [ebx + LEFTTEAM + TEAMNUMBER], 1   # sides swap at half time, so
    je ordered                                      # go by which one is team 1,
    xchg eax, edx                                   # the order the score is in
ordered:
    push edx                                # second team, for later
    lea esi, [eax + TEAMNAME]
    call copy3
    mov byte ptr [edi], 32
    inc edi
    movzx eax, word ptr [ebx + TEAM1GOALS]
    call putnum
    mov byte ptr [edi], 45                  # '-'
    inc edi
    movzx eax, word ptr [ebx + TEAM2GOALS]
    call putnum
    mov byte ptr [edi], 32
    inc edi
    pop esi
    add esi, TEAMNAME
    call copy3
    mov byte ptr [edi], 0

    mov esi, dword ptr [ebx + SPRITEDAT]    # blank the slot: whatever it held
    mov esi, dword ptr [esi + SLOT * 4]     # before is not ours to show, and
    movzx ecx, word ptr [esi + 12]          # colour zero draws as nothing
    movzx eax, word ptr [esi + 14]          # nlines * wquads * 8, with a cap
    imul ecx, eax                           # in case the header is not what
    shl ecx, 3                              # we think it is
    cmp ecx, 2048
    ja nowipe
    mov edi, dword ptr [esi]
    xor eax, eax
    rep stosb
nowipe:

    mov dword ptr [ebx + A0], esp           # how wide the text comes out, so
    lea eax, [ebx + SMALLCHARS]             # it can be put against the slot's
    mov dword ptr [ebx + A1], eax           # right edge rather than its left
    push ebp
    push ebx
    .byte 0xe8
    .long GETTEXTSIZE - (BASE + (. - start) + 4)
    pop ebx
    pop ebp
    mov esi, dword ptr [ebx + SPRITEDAT]
    mov esi, dword ptr [esi + SLOT * 4]
    movzx eax, word ptr [esi + 10]          # the slot keeps its own width -
    movzx edx, word ptr [ebx + D7]          # Text2Sprite refuses to resize it
    sub eax, edx
    jb nofit

    mov dword ptr [ebx + D1], eax
    mov dword ptr [ebx + D2], 0
    mov dword ptr [ebx + D4], SLOT
    mov dword ptr [ebx + A0], esp           # the text we just built
    lea eax, [ebx + SMALLCHARS]
    mov dword ptr [ebx + A1], eax
    push ebp
    push ebx
    .byte 0xe8
    .long TEXT2SPRITE - (BASE + (. - start) + 4)
    pop ebx
    pop ebp
    add esp, 16
    cmp word ptr [ebx + D0], 0
    jne done                                # text did not fit: draw nothing
    mov word ptr [ebx + VALID], 1
    jmp place
nofit:
    add esp, 16
    jmp done

place:
    mov esi, dword ptr [ebx + SPRITEDAT]    # the game works out the screen
    mov esi, dword ptr [esi + SLOT * 4]     # position itself, taking off the
    movzx eax, word ptr [esi + 14]          # graphic's centre and the camera,
    shl eax, 4                              # and it checks both edges before
    cmp eax, 312                            # drawing - which is the whole
    ja done                                 # point of going through it
    lea edi, [ebx + SPR]
    mov word ptr [edi + 70], SLOT           # pictureIndex
    mov dx, word ptr [ebx + CAMERAX]
    add dx, 316                             # screen is 320 wide, a small margin
    sub dx, ax                              # right-aligned
    add dx, word ptr [esi + 16]             # centerX, which it takes off again
    mov word ptr [edi + 32], dx             # x, whole part of the fixed point
    mov ax, word ptr [ebx + CAMERAY]
    add ax, 4                               # clear of the top edge
    add ax, word ptr [esi + 18]             # centerY
    mov word ptr [edi + 36], ax             # y, likewise

    movzx ecx, word ptr [ebx + NUMSPRITES]  # join the list for this one frame
    cmp ecx, 79                             # rather than take a place in
    jae done                                # allSpritesArray, which has one
    lea eax, [ebx + SORTED]                 # slot left and needs it for the
    mov dword ptr [eax + ecx * 4], edi      # terminator
    inc ecx
    mov word ptr [ebx + NUMSPRITES], cx

done:
    lea esi, [ebx + D0 + 56]                # put the scratch registers back
    mov ecx, 15
restore:
    pop eax
    mov dword ptr [esi], eax
    sub esi, 4
    dec ecx
    jnz restore
    push ebx                                # and now the game draws the lot,
    .byte 0xe8                              # ours among them
    .long DRAWSPRITES - (BASE + (. - start) + 4)
    pop ebx

    lea edx, [ebx + SORTED]                 # take ourselves back out. The sort
    lea edi, [ebx + SPR]                    # orders on y and we sit at the top
    movzx ecx, word ptr [ebx + NUMSPRITES]  # of the screen, so it will have
    xor eax, eax                            # moved us to the front and pushed
scan:                                       # everything down one - shortening
    cmp eax, ecx                            # the list again would drop whoever
    jae putback                             # ended up last, every frame, and
    cmp dword ptr [edx + eax * 4], edi      # leave us in it to be added a
    je shift                                # second time on the next
    inc eax
    jmp scan
shift:
    inc eax
shloop:
    cmp eax, ecx
    jae putback
    mov esi, dword ptr [edx + eax * 4]
    mov dword ptr [edx + eax * 4 - 4], esi
    inc eax
    jmp shloop
putback:
    mov ax, word ptr [ebx + SAVEDN]         # then the list is the game's again,
    mov word ptr [ebx + NUMSPRITES], ax     # entry for entry
    popfd
    popad
    ret

# 3 letters of a club name at [esi] into [edi], padded with spaces
copy3:
    mov ecx, 3
c3loop:
    mov al, byte ptr [esi]
    test al, al
    jnz c3ok
    mov al, 32
    jmp c3store
c3ok:
    inc esi
c3store:
    mov byte ptr [edi], al
    inc edi
    dec ecx
    jnz c3loop
    ret

# eax (0-99) as digits at [edi]
putnum:
    cmp eax, 99
    jbe putnum_ok
    mov eax, 99
putnum_ok:
    cmp eax, 10
    jb ones
    xor ecx, ecx
tens:
    cmp eax, 10
    jb tensdone
    sub eax, 10
    inc ecx
    jmp tens
tensdone:
    push eax
    lea eax, [ecx + 48]
    mov byte ptr [edi], al
    inc edi
    pop eax
ones:
    add al, 48
    mov byte ptr [edi], al
    inc edi
    ret
end:
