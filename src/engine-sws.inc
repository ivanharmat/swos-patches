# SWS.EXE - SWOS 95/96, the original.
# Every address here was carried across from the 16/17 build by matching the
# bytes around it; see PORTING.md.

.set CURMENU,       0x117A66    # g_currentMenu
.set MENUPTRSRC,    0x188AF     # the relocated g_currentMenu inside
                                # CalcMenuEntryAddress, which is how new code
                                # finds out where the loader put the data
.set D0,            0xF146D     # the 68000 registers the translation kept
.set D1,            0xF1471
.set D2,            0xF1475
.set D4,            0xF147D
.set D7,            0xF1489
.set A0,            0xF148D
.set A1,            0xF1491
.set A5,            0xF14A1
.set A0OPERAND,     0x188AB     # a relocated pointer to A0, in CalcMenuEntryAddress

.set GOALSMODE,     0x1748E4    # 0 = squad, 1 = goals (and now skills)
.set DRAWNPLAYER,   0x1748E6    # player the row being drawn belongs to
.set SKILLDIFF2,    0x1748F4
.set SQUADTEAM,     0x1748EE    # the club whose squad is on screen

.set TEAM1GOALS,    0x114C5E
.set TEAM2GOALS,    0x114C60
.set CAMERAX,       0x110538
.set CAMERAY,       0x11053C
.set SMALLCHARS,    0x110352
.set SPRITEDAT,     0x11034E    # table of sprite graphics
.set NUMSPRITES,    0x11032C    # how many of sortedSprites the game will draw
.set SORTED,        0x113130    # the list DrawSprites walks, 79 long
.set LEFTTEAM,      0x17DAE6    # TeamGeneralInfo of each side of the pitch
.set RIGHTTEAM,     0x17DB77

.set SETUP,         0x360EC     # lays the squad screen out for the current view
.set DRAWMULTI,     0x19010     # DrawMultipleItems(A5, D0)
.set DRAWITEM,      0x19069     # DrawMenuItem(A5)
.set SETCURENT,     0x184AA
.set DRAWMENU,      0x1892E
.set SAVEPOS,       0x3820A     # SquadMenuSavePlayerPositions
.set DRAWSPRITES,   0x72020
.set TEXT2SPRITE,   0x16989
.set GETTEXTSIZE,   0x1A17D

.set SLOT,          325         # a spare text graphic: 120 pixels by 7
.set VARS,          0x186800    # the spare data "Room for added code" makes
.set SVARS,         0x186820
