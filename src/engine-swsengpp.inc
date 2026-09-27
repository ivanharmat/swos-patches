# SWSENGPP.EXE - SWOS 2016/17, which is SWOS 96 with SWOS++ built in.
# Every address here was read out of that executable; see PORTING.md.

.set CURMENU,       0x117A8E    # g_currentMenu
.set MENUPTRSRC,    0x1DB87     # the relocated g_currentMenu inside
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
.set A0OPERAND,     0x6FF4B     # a relocated pointer to A0, inside UpdateTime

.set GOALSMODE,     0x16F47C    # 0 = squad, 1 = goals (and now skills)
.set DRAWNPLAYER,   0x16F47E    # player the row being drawn belongs to
.set SKILLDIFF2,    0x16F48C
.set SQUADTEAM,     0x16F486    # the club whose squad is on screen

.set TEAM1GOALS,    0x114C86
.set TEAM2GOALS,    0x114C88
.set CAMERAX,       0x110538
.set CAMERAY,       0x11053C
.set SMALLCHARS,    0x110352
.set SPRITEDAT,     0x11034E    # table of sprite graphics
.set NUMSPRITES,    0x11032C    # how many of sortedSprites the game will draw
.set SORTED,        0x113130    # the list DrawSprites walks, 79 long
.set LEFTTEAM,      0x17DBFE    # TeamGeneralInfo of each side of the pitch
.set RIGHTTEAM,     0x17DC8F

.set SETUP,         0x116E8     # lays the squad screen out for the current view
.set DRAWMULTI,     0x1E2E8     # DrawMultipleItems(A5, D0)
.set DRAWITEM,      0x1E341     # DrawMenuItem(A5)
.set SETCURENT,     0x1D782
.set DRAWMENU,      0x1DC06
.set SAVEPOS,       0x13805     # SquadMenuSavePlayerPositions
.set DRAWSPRITES,   0x72270
.set TEXT2SPRITE,   0x1BC61
.set GETTEXTSIZE,   0x1F455

.set SLOT,          325         # a spare text graphic: 120 pixels by 7
.set VARS,          0x186800    # the spare data "Room for added code" makes
.set SVARS,         0x186820
