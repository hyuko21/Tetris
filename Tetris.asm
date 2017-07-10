.data
score_text:	.asciiz "SCORE: "

.text	# W x H = 512 x 1024 | PIXELS x (W x H) = 4 x 4 | ADDRESS FOR DISPLAY = 0x10040000(heap)
main:
	lui  $9, 0x1004
	addi $9, $9, 2576    # vertical/horizontal start drawing pos: $9(w) = 16; $9(h) = 2560
    li   $13, 170        # max vertical drawing
    ########  Pieces  ########
    #   0xffffff  ==>  Wall	 #
   	#   0x0000ff  ==>   O	 #
    #   0xff00ff  ==>   L	 #
    #   0xff9900  ==>   J	 #
    #   0x00ff00  ==>   S	 #
    #   0x00ffff  ==>   Z	 #
    #   0xff0000  ==>   I	 #
    #   0xffff00  ==>   T	 #
    ##########################
     	
# DRAW WALL
heightTest:  
	beq  $13, 0, paramToDrawFrame
	beq  $13, 170, paramToDrawLine
	beq  $13, 1, paramToDrawLine
		
	li   $12, 2
	li   $16, 324
	li   $17, -136
	
	j drawWhite
	
paramToDrawLine:
	li   $25, 0xffffff
	li   $12, 82
	li   $16, 4
	li   $17, 184
	
drawWhite:   
	sw   $25, 0($9)
	add  $9, $9, $16
	addi $12, $12, -1
	bgt  $12, 0, drawWhite

paramToNextLine: 
	add  $9, $9, $17
    addi $13, $13, -1
    
    j heightTest

# draw the frame that shows the next piece incoming
frameHeightTest:
	beq  $13, 0, _1stPieceSelection
	beq  $13, 1, paramToDrawFrameLine
	
	li   $16, 512
	li   $17, -160
	
	j drawWhiteFramePt2
	
paramToDrawFrame:
	lui  $9, 0x1004
	addi $9, $9, 17752
    li   $13, 42

paramToDrawFrameLine:
	li   $12, 41
	li   $16, 4
	li   $17, 508
	
drawWhiteFrame:
	sw   $25, 0($9)
	add  $9, $9, $16
	addi $12, $12, -1
	bgt  $12, 0, drawWhiteFrame
	
	addi $13, $13, -1
	j newParamDrawFrame
	
drawWhiteFramePt2:
	sw   $25, 0($9)
	add  $9, $9, $16
	addi $13, $13, -1
	bgt  $13, 1, drawWhiteFramePt2
	
newParamDrawFrame:
	add  $9, $9, $17
	
	j frameHeightTest

# erase the frame if it has something drawn
paramEraseFrame:
	li   $14, 4
	li   $25, 0
	
eraseFromFrame:
	sw   $25, 0($7)
	addi $7, $7, 4
	addi $14, $14, -1
	bgt  $14, 0, eraseFromFrame
	addi $12, $12, -1
	j checkIfNeedToErase
	
# look up to the frame to check if it has something drawn
paramCheckFrame:
	lui  $7, 0x1004
	addi $7, $7, 24408
	li   $12, 10
	li   $19, 16
	j checkIfNeedToErase

newParamCheckFrame:
	addi $7, $7, 352
	li   $12, 10
	
checkIfNeedToErase:
	lw   $23, 0($7)
	sgt  $6, $23, 0
	beq  $6, 1, paramEraseFrame
	addi $7, $7, 16
	addi $12, $12, -1
	bgt  $12, 0, checkIfNeedToErase
	addi $19, $19, -1
	bgt  $19, 0, newParamCheckFrame
	
	jr   $31
	
checkForEnd:
	lw   $24, 7284($9)
	sgt  $11, $24, 0
	beq  $11, 1, paramToGameOver
	lw   $24, 7316($9)
	sgt  $11, $24, 0
	beq  $11, 1, paramToGameOver
	lw   $24, 7348($9)
	sgt  $11, $24, 0
	beq  $11, 1, paramToGameOver
	lw   $24, 7380($9)
	sgt  $11, $24, 0
	beq  $11, 1, paramToGameOver
	
	jr   $31	

_1stPieceSelection:
	li   $2, 42		# 42 syscall to random number with range
	li   $5, 4   	# $a1 is the max random number
	syscall      	# generated number will be at $a0($4)
	
	add  $17, $0, $4  # store in $17 the next piece number
	
# MOVEMENT
paramToMove:
	lui  $8, 0xffff
	lui  $9, 0x1004
	li   $22, 6		   # 6 = line that's start drawing
	jal  checkForEnd
	li   $24, 0		# key pressed
	li   $14, 0		# speed
	li   $15, 0

	add  $16, $0, $17
	beq  $16, 0, oAsPiece
	beq  $16, 1, lAsPiece
	beq  $16, 2, iAsPiece
	beq  $16, 3, tAsPiece
	
nextPieceSelection:
	li   $2, 42		# 42 syscall to random number with range
	li   $5, 4   	# $a1 is the max random number
	syscall      	# generated number will be at $a0($4)
	
	add  $17, $0, $4  # store in $17 the next piece number
	
	jal  paramCheckFrame	# go check if needs to erase the frame
	
	lui  $9, 0x1004
	beq  $17, 0, oAsFrame
	beq  $17, 1, lAsFrame
	beq  $17, 2, iAsFrame
	beq  $17, 3, tAsFrame

# TO DRAW 'O'
oAsFrame:
	addi $9, $9, 24456
	j paramToDrawO

oAsPiece:
	addi $9, $9, 3220

paramToDrawO:
	li   $25, 0xff		# color (blue)
	li   $12, 16		# max width
	li   $19, 16		# max height -> 8 = 1 block; 16/8 = 2 blocks of height
	j firstDrawO

newParamfirstDrawO:
	addi $19, $19, -1
	li   $12, 16
	addi $9, $9, 448
	bgt  $19, 0, firstDrawO
	beq  $15, 1, getBackToTheFlow
	jal  needToDrawNextFrame
	
resetAsO:
	lui  $9, 0x1004
	addi $9, $9, 10964
	li   $25, 0xff
	li   $18, 2
	j resetO

firstDrawO:
	sw   $25, 0($9)
	addi $9, $9, 4
	addi $12, $12, -1
	bgt  $12, 0, firstDrawO
	bgt  $19, 0, newParamfirstDrawO

# TO DRAW 'L'
lAsFrame:
	addi $9, $9, 24504
	j paramToDrawL

lAsPiece:
	addi $9, $9, 3252

paramToDrawL:
	li   $25, 0xff00ff	# color (pink)
	li   $12, 8			# max 'start' width -> the first two with 8 of width and the last one with 16
	li   $19, 16		# max height -> 8 = 1 block; 16/8 = 2 blocks of height
	j firstDrawL	
	
newParamfirstDrawL:
	addi $19, $19, -1
	blt  $19, 9, _2ndParamFirstDrawL
	
_1stParamFirstDrawL:
	li   $12, 8
	addi $9, $9, 480
	bgt  $19, 0, firstDrawL
	
_2ndParamFirstDrawL:
	li   $12, 24
	addi $9, $9, 416
	bgt  $19, 0, firstDrawL
	beq  $15, 1, getBackToTheFlow
	jal  needToDrawNextFrame
	
resetAsL:
	lui  $9, 0x1004
	addi $9, $9, 10964
	li   $25, 0xff00ff
	li   $18, 2
	j resetL

firstDrawL:
	sw   $25, 0($9)
	addi $9, $9, 4
	addi $12, $12, -1
	bgt  $12, 0, firstDrawL
	bgt  $19, 0, newParamfirstDrawL

# TO DRAW 'I'
iAsFrame:
	addi $9, $9, 28520
	j paramToDrawI

iAsPiece:
	addi $9, $9, 3188

paramToDrawI:
	li   $25, 0xff0000	# color (red)
	li   $12, 32		# max width
	li   $19, 8			# max height -> 8 = 1 block; 32/8 = 4 blocks of height
	j firstDrawI
	
newParamfirstDrawI:
	addi $19, $19, -1
	li   $12, 32
	addi $9, $9, 384
	bgt  $19, 0, firstDrawI
	beq  $15, 1, getBackToTheFlow
	jal  needToDrawNextFrame
	
resetAsI:
	lui  $9, 0x1004
	addi $9, $9, 6900
	li   $25, 0xff0000
	li   $18, 1
	j resetI
	
firstDrawI:
	sw   $25, 0($9)
	addi $9, $9, 4
	addi $12, $12, -1
	bgt  $12, 0, firstDrawI
	bgt  $19, 0, newParamfirstDrawI

# TO DRAW 'T'
tAsFrame:
	addi $9, $9, 24472
	j paramToDrawT

tAsPiece:
	addi $9, $9, 3220
	
paramToDrawT:	
	li   $25, 0xffff00	# color (yellow)
	li   $12, 8			# max 'start' width -> the first one with 8 of width and the last one with 24
	li   $19, 16		# max height -> 8 = 1 block; 16/8 = 2 blocks of height
	j firstDrawT

newParamfirstDrawT:
	addi $19, $19, -1
	beq  $19, 8, fixOffsetOneTime
	blt  $19, 9, _2ndParamFirstDrawT

_1stParamFirstDrawT:
	li   $12, 8
	addi $9, $9, 480
	bgt  $19, 0, firstDrawT
	
fixOffsetOneTime:
	li   $12, 24
	addi $9, $9, 448
	j firstDrawT

_2ndParamFirstDrawT:
	li   $12, 24
	addi $9, $9, 416
	bgt  $19, 0, firstDrawT
	beq  $15, 1, getBackToTheFlow
	jal  needToDrawNextFrame
	
resetAsT:
	lui  $9, 0x1004
	addi $9, $9, 10964
	li   $25, 0xffff00
	li   $18, 2
	j resetT
	
firstDrawT:
	sw   $25, 0($9)
	addi $9, $9, 4
	addi $12, $12, -1
	bgt  $12, 0, firstDrawT
	bgt  $19, 0, newParamfirstDrawT
	
needToDrawNextFrame:
	li   $15, 1
	add  $20, $0, $31
	j nextPieceSelection

getBackToTheFlow:
	add  $31, $0, $20
	jr   $31

# SPEED UP
paramSpeedUp:
	li   $14, 10
	beq  $16, 0, resetO
	beq  $16, 1, resetL
	beq  $16, 2, resetI
	beq  $16, 3, resetT
	
paramMaxSpeed:
	li   $14, 150
	beq  $16, 0, resetO
	beq  $16, 1, resetL
	beq  $16, 2, resetI
	beq  $16, 3, resetT
	
speedUp:
	addi $14, $14, -1
	beq  $16, 0, resetO
	beq  $16, 1, resetL
	beq  $16, 2, resetI
	beq  $16, 3, resetT
	
# MOVEMENT - TO THE BOTTOM
resetO:
	li   $12, 16
	addi $9, $9, -7744
	j eraseTopO

resetL:
	li   $12, 24
	addi $9, $9, -7712
	j eraseTopL

resetI:
	li   $12, 32
	addi $9, $9, -3712
	j eraseTopI

resetT:
	li   $12, 24
	addi $9, $9, -7744
	j eraseTopT

delay:
	bgt  $14, 0, speedUp
	li   $4, 35
	li   $2, 32
	syscall
	
	beq  $16, 0, resetO
	beq  $16, 1, resetL
	beq  $16, 2, resetI
	beq  $16, 3, resetT

erase:
	li   $23, 0
	sw   $23, 0($9)
	addi $9, $9, 4
	addi $12, $12, -1
	jr   $31
	
draw:
	sw   $25, 0($9)
	addi $9, $9, 4
	addi $12, $12, -1
	jr   $31

# SIMULATE MOVE: ERASE FUNCTIONS
eraseTopO:
	jal  erase
	bgt  $12, 0, eraseTopO
	addi $22, $22, 1	
	j drawBottomO
		
_2ndErasePtL:
	addi $9, $9, 4000
	
eraseTopL:
	jal  erase
	beq  $12, 16, _2ndErasePtL
	bgt  $12, 0, eraseTopL
	addi $22, $22, 1
	j drawBottomL

eraseTopI:
	jal  erase
	bgt  $12, 0, eraseTopI
	addi $22, $22, 1
	j drawBottomI
	
_2ndErasePtT:
	addi $9, $9, 4032
	j eraseTopT
	
_3rdErasePtT:
	addi $9, $9, 32
	
eraseTopT:
	jal  erase
	beq  $12, 16, _2ndErasePtT
	beq  $12, 8, _3rdErasePtT
	bgt  $12, 0, eraseTopT
	addi $22, $22, 1
	j drawBottomT
	
# SIMULATE MOVE: DRAW FUNCTIONS
drawBottomO:
	li   $12, 16
	addi $9, $9, 8128
	j drawBottom
	
drawBottomL:
	li   $12, 24
	addi $9, $9, 4032
	j drawBottom

drawBottomI:
	li   $12, 32
	addi $9, $9, 3968
	j drawBottom

drawBottomT:
	li   $12, 24
	addi $9, $9, 4000
	
#################################
#   Keyboard Input Parameters	#
#################################
drawBottom:
	jal  draw
	bgt  $12, 0, drawBottom
	jal  checkLimitAtBottom
	lw   $24, 0($8)
	beq  $24, 0, delay
	lw   $24, 4($8)
	beq  $24, 97, paramToMoveLeft
	beq  $24, 100, paramToMoveRight
	beq  $24, 115, paramSpeedUp
	beq  $24, 119, paramMaxSpeed
	j delay
#################################
#   Keyboard Input Parameters	#
#################################	
	
# MOVEMENT - TO THE RIGHT
paramToMoveRight:
	jal  checkLimitAtRight	# JUMP TO THE CHECKER STATEMENT
	li   $12, 16
	beq  $16, 0, MoveOTRight
	beq  $16, 1, MoveLRight
	beq  $16, 2, MoveIRight
	beq  $16, 3, MoveOTRight
	
MoveOTRight:
	addi $9, $9, -7744
	li   $19, 16
	j eraseRight
	
MoveLRight:
	addi $9, $9, -7712
	li   $19, 16
	j eraseRight
	
MoveIRight:
	addi $9, $9, -3712
	li   $19, 8
	j eraseRight
	
newParamMoveRight:
	beq  $16, 0, newParamForO
	beq  $16, 1, newParamForL
	beq  $16, 2, newParamForI
	beq  $16, 3, newParamForT
	
newParamForO:
	li   $12, 16
	addi $9, $9, -96
	j eraseRight
	
newParamForL_2ndPt:
	addi $9, $9, -128
	j eraseRight
	
newParamForL:
	li   $12, 16
	blt  $19, 9, newParamForL_2ndPt
	addi $9, $9, -64
	j eraseRight
	
newParamForI:
	li   $12, 16
	addi $9, $9, -160
	j eraseRight	
	
newParamForT_1stPt:
	addi $9, $9, -96
	j eraseRight
				
newParamForT_2ndPt:
	addi $9, $9, -128
	j eraseRight	
	
newParamForT:
	li   $12, 16
	beq  $19, 8, newParamForT_1stPt
	blt  $19, 8, newParamForT_2ndPt
	addi $9, $9, -64
	j eraseRight
	
eraseRight:
	jal erase
	bgt  $12, 8, eraseRight  	
	beq  $16, 0, fixOffsetORight
	beq  $16, 1, fixOffsetLRight
	beq  $16, 2, fixOffsetIRight
	beq  $16, 3, fixOffsetTRight

fixOffsetORight:	
	addi $9, $9, 32
	j drawRight
	
fixOffsetLRight_2ndPt:
	addi $9, $9, 64
	j drawRight
	
fixOffsetLRight:
	blt  $19, 9, fixOffsetLRight_2ndPt
	j drawRight
	
fixOffsetIRight:
	addi $9, $9, 96
	j drawRight
		
fixOffsetTRight_2ndPt:
	addi $9, $9, 64
	j drawRight
	
fixOffsetTRight:	
	blt  $19, 9, fixOffsetTRight_2ndPt
	
drawRight:
	jal draw
	bgt  $12, 0, drawRight
	addi $9, $9, 512
	addi $19, $19, -1
	bgt  $19, 0, newParamMoveRight
	addi $9, $9, -512
	j delay

# MOVEMENT - TO THE LEFT
paramToMoveLeft:
	jal  checkLimitAtLeft	# JUMP TO THE CHECKER STATEMENT
	li   $12, 16
	beq  $16, 0, MoveOLLeft
	beq  $16, 1, MoveOLLeft
	beq  $16, 2, MoveILeft
	beq  $16, 3, MoveTLeft
	
MoveOLLeft:
	addi $9, $9, -7712
	li   $19, 16
	j eraseLeft
	
MoveILeft:
	addi $9, $9, -3616
	li   $19, 8	
	j eraseLeft
	
MoveTLeft:
	addi $9, $9, -7744
	li   $19, 16
	j eraseLeft

newParamMoveOLeft:
	li   $12, 16
	addi $9, $9, 32
	j eraseLeft
	
newParamMoveLLeft_2ndPt:
	addi $9, $9, 64	
	j eraseLeft
	
newParamMoveLLeft:
	li   $12, 16
	blt  $19, 8, newParamMoveLLeft_2ndPt
	j eraseLeft
	
newParamMoveILeft:
	li   $12, 16
	addi $9, $9, 96
	j eraseLeft
	
newParamMoveTLeft_1stPt:
	addi $9, $9, 32
	j eraseLeft

newParamMoveTLeft_2ndPt:
	addi $9, $9, 64
	j eraseLeft

newParamMoveTLeft:
	li   $12, 16
	beq  $19, 8, newParamMoveTLeft_1stPt
	blt  $19, 8, newParamMoveTLeft_2ndPt
	
eraseLeft:
	jal erase
	bgt  $12, 8, eraseLeft
	beq  $16, 0, fixOffsetOLeft
	beq  $16, 1, fixOffsetLTLeft
	beq  $16, 2, fixOffsetILeft
	beq  $16, 3, fixOffsetLTLeft
	
# TO MOVE 'O' LEFT
fixOffsetOLeft:
	addi $9, $9, -96

drawOLeft:
	jal draw
	bgt  $12, 0, drawOLeft
	addi $9, $9, 512
	addi $19, $19, -1
	bgt  $19, 0, newParamMoveOLeft
	addi $9, $9, -480
	j delay
	
# TO SET 'L' / 'T' PARAMETERS
fixOffsetLTLeft_1stPt:
	addi $9, $9, -64
	beq  $16, 1, drawLLeft
	beq  $16, 3, drawTLeft
	
fixOffsetLTLeft:
	bgt  $19, 8, fixOffsetLTLeft_1stPt
	addi $9, $9, -128
	beq  $16, 1, drawLLeft
	beq  $16, 3, drawTLeft
	
# TO MOVE 'L' LEFT
drawLLeft:
	jal draw
	bgt  $12, 0, drawLLeft
	addi $9, $9, 512
	addi $19, $19, -1
	bgt  $19, 0, newParamMoveLLeft
	addi $9, $9, -448
	j delay

# TO MOVE 'I' LEFT
fixOffsetILeft:
	addi $9, $9, -160

drawILeft:
	jal draw
	bgt  $12, 0, drawILeft
	addi $9, $9, 512
	addi $19, $19, -1
	bgt  $19, 0, newParamMoveILeft
	addi $9, $9, -416
	j delay

# TO MOVE 'T' LEFT
drawTLeft:
	jal draw
	bgt  $12, 0, drawTLeft
	addi $9, $9, 512
	addi $19, $19, -1
	bgt  $19, 0, newParamMoveTLeft
	addi $9, $9, -448
	j delay
	
# WALL LIMITS / PIECES 'COLISIONS
checkLimitAtBottom:
	add  $5, $0, $9			
	beq  $16, 0, checkForOBottom
	beq  $16, 1, checkForLTBottom
	beq  $16, 2, checkForIBottom
	beq  $16, 3, checkForLTBottom
	
checkForOBottom:
	addi $5, $5, 448		# $5 += 448  ->  ADDS TO GO TO THE FIRST ADDRESS AT THE NEXT LINE
	li   $12, 16			# $12 = $18(currentPiece.Width)
	j horzCheck
	
checkForLTBottom:
	addi $5, $5, 416
	li   $12, 24
	j horzCheck
			
checkForIBottom:	
	addi $5, $5, 384
	li   $12, 32
	
horzCheck:
	lw   $23, 0($5)			# $23 = 0($5).storedValue();
	addi $5, $5, 4			# $5 += 4  ->  CHECKING (IN ALL IT WIDTH) WHAT'S BELOW THE CURRENT PIECE 
	addi $12, $12, -1		# columnsToCheck--;
	sgt  $7, $23, 0			# storedValue > 0 ? 
	beq  $7, 1, checkLines  #checkLines	# storedValue > 0 ? true  ->  LOOK FOR 'COMPLETE LINES'
	bgt  $12, 0, horzCheck  # columnsToCheck > 0 ? true  ->  REDO
	jr   $31				# columnsToCheck > 0 ? false ->  GET OUT THE CHECKER STATEMENT

checkLimitAtRight:
	add  $5, $0, $9
	beq  $16, 0, checkForOLRight
	beq  $16, 1, checkForOLRight
	beq  $16, 2, checkForIRight
	beq  $16, 3, checkForTRight

checkForOLRight:
	addi $5, $5, -8192		
	li   $12, 16			# current piece height
	j vertCheck
	
checkForIRight:
	addi $5, $5, -4096		
	li   $12, 8				# current piece height
	j vertCheck
	
checkForTRight:
	addi $5, $5, -8224		
	li   $12, 16			# current piece height
	j vertCheckForTRight
	
newParamCheckTRight:
	addi $5, $5, 32	

vertCheckForTRight:
	lw   $23, 0($5)
	addi $5, $5, 512
	addi $12, $12, -1
	sgt  $7, $23, 0	
	beq  $7, 1, delay
	beq  $12, 8, newParamCheckTRight
	bgt  $12, 0, vertCheckForTRight
	jr   $31
	
vertCheck:
	lw   $23, 0($5)			# $23 = 0($5).storedValue();
	addi $5, $5, 512		# $5 += 512  ->  TO GO TO NEXT LINE
	addi $12, $12, -1		# linesToCheck--;
	sgt  $7, $23, 0			# storedValue > 0 ? 
	beq  $7, 1, delay		# storedValue > 0 ? true  ->  STATEMENT BREAK CASE
	bgt  $12, 0, vertCheck  # linesToCheck > 0 ? true  ->  REDO
	jr   $31				# linesToCheck > 0 ? false -> GO BACK TO THE DRAW FUNCTION
		
checkLimitAtLeft:
	add  $5, $0, $9
	beq  $16, 0, checkForOLeft
	beq  $16, 1, checkForLLeft
	beq  $16, 2, checkForILeft
	beq  $16, 3, checkForTLeft
	
newParamCheckLLeft:
	addi $5, $5, -64	

vertCheckForLLeft:
	lw   $23, 0($5)
	addi $5, $5, 512
	addi $12, $12, -1
	sgt  $7, $23, 0	
	beq  $7, 1, delay
	beq  $12, 8, newParamCheckLLeft
	bgt  $12, 0, vertCheckForLLeft
	jr   $31
	
newParamCheckTLeft:
	addi $5, $5, -32	

vertCheckForTLeft:
	lw   $23, 0($5)
	addi $5, $5, 512
	addi $12, $12, -1
	sgt  $7, $23, 0	
	beq  $7, 1, delay
	beq  $12, 8, newParamCheckTLeft
	bgt  $12, 0, vertCheckForTLeft
	jr   $31
	
checkForOLeft:
	addi $5, $5, -8260
	li   $12, 16			# current piece height
	j vertCheck
	
checkForLLeft:
	addi $5, $5, -8228
	li   $12, 16			# current piece height
	j vertCheckForLLeft
	
checkForILeft:
	addi $5, $5, -4228
	li   $12, 8				# current piece height
	j vertCheck
	
checkForTLeft:
	addi $5, $5, -8260
	li   $12, 16			# current piece height
	j vertCheckForTLeft

# TRYING CHANGE COLOR
changeColor:
	addi $9, $9, -7744
	li   $12, 16
	li   $19, 16
	li   $25, 0x50ff
	j secondDraw
	
newParamSecondDraw:
	addi $19, $19, -1
	li   $12, 16
	addi $9, $9, 448
	bne  $19, 0, secondDraw
	j checkLines
	
secondDraw:
	sw   $25, 0($9)
	addi $9, $9, 4
	addi $12, $12, -1
	bgt  $12, 0, secondDraw
	bgt  $19, 0, newParamSecondDraw

# LOOKING FOR LINE DONE
checkLines:
	mul  $21, $22, 512	# $21 = $22 * 512; $22 = lastEraseLine + 1;
	addi $21, $21, 20	# $21 += 20; 20 = edge of the begin + wall pixels
	lui  $5, 0x1004		# $5 = 0x10040000; reset the register value
	add  $5, $5, $21	# $5 += $21; to go to the top of the current piece when it stops
	li   $19, 10		# $19 = 10; max amount of block that fills a line
	j lookForLinesDone
	
newParamLookForLinesDone:
	addi $18, $18, -1
	beq  $18, 0, paramToMove	
	li   $19, 10		# max blocks per line (the same to all the pieces)
	lui  $5, 0x1004
	add  $5, $5, $21
	addi $5, $5, 4096
	
lookForLinesDone:
	beq  $19, 0, paramDeleteLineBlock
	lw   $23, 0($5)
	addi $5, $5, 32
	sgt  $7, $23, 0
	addi $19, $19, -1
	beq  $7, 1, lookForLinesDone
	beq  $7, 0, newParamLookForLinesDone
	
paramDeleteLineBlock:
	li   $15, 8				# $18 = 8; max line height to delete
	li   $12, 80
	addi $5, $5, -320
	add  $9, $0, $5			# $9 += $21; increment the register that's used in the 'erase' function
	j deleteLineBlock
	
newParamDeleteLineBlock:
	li   $12, 80			# max line width (the same to all the pieces)
	addi $9, $9, 192		# to go to the begin of the next line
	
deleteLineBlock:
	jal erase
	bgt  $12, 0, deleteLineBlock
	addi $15, $15, -1
	bgt  $15, 0, newParamDeleteLineBlock
	addi $13, $13, 100
	jal  showScore
	jal  paramCheckForAnyColor
	j newParamLookForLinesDone
	
# BRING THE FIRST BLOCK UPPER DOWN
paramCheckForAnyColor:
	addi $5, $5, -512
	li   $19, 10
	li   $16, 0
	
	j checkForAnyColor
	
newParamCheckForAnyColor:
	beq  $16, 10, return
	li   $19, 10
	li   $16, 0
	addi $5, $5, -832

checkForAnyColor:
	beq  $19, 0, newParamCheckForAnyColor
	lw   $23, 0($5)
	sgt  $7, $23, 0
	beq  $7, 1, paramBringUpperDown
	addi $5, $5, 32
	addi $19, $19, -1
	addi $16, $16, 1
	j checkForAnyColor
	
paramBringUpperDown:
	li   $12, 8

bringUpperDown:
	lw   $23, 0($5)
	sw   $23, 4096($5)
	li   $23, 0
	sw   $23, 0($5)
	addi $5, $5, 4
	addi $12, $12, -1
	bgt  $12, 0, bringUpperDown
	addi $19, $19, -1
	j checkForAnyColor
		
return:
	jr   $31
	
# SHOW SCORE IN THE 'RUN/IO' TABLE
showScore:
	li   $10, 10
	li   $4, 10
	
jumpLines:
	li   $2, 11
	syscall
	addi $10, $10, -1
	bne  $10, 0, jumpLines
	
	la   $4, score_text
	li   $2, 4
	syscall

	add  $4, $0, $13
	li   $2, 1
	syscall

	jr   $31

paramToGameOver:
	lui  $9, 0x1004
	addi $9, $9, 28176
	li   $12, 82
	li   $13, 42
	li   $20, 0
	li   $21, 2
	li   $22, 0
	li   $25, 0xff00

goBlockHorzLine:
	jal draw
	bgt  $12, 0, goBlockHorzLine
	addi $13, $13, -1
	
goBlockHeightTest:
	ble  $13, 36, setCondrawords
continue1:
	li   $12, 82
	addi $9, $9, 184
	beq  $13, 41, goBlockHorzLine
	beq  $13, 2, goBlockHorzLine
	beq  $13, 1, goBlockHorzLine
	beq  $13, 0, fim
		
	jal draw
	jal draw
	
drawGameOverBlock:
	jal erase
	ble  $12, 61, checkIfCanDrawWords
continue2:
	bgt  $12, 2, drawGameOverBlock
	jal draw
	jal draw
	addi $13, $13, -1
	bgt  $13, 0, goBlockHeightTest

checkIfCanDrawWords:
	bne  $20, 1, continue2
	bne  $21, 0, whereToDraw
	addi $22, $22, 1
	li   $21, 2

whereToDraw:
	beq  $22, 0, GAME_1_1
	beq  $22, 1, GAME_2_1
	beq  $22, 2, GAME_3_1
	beq  $22, 3, GAME_4_1
	beq  $22, 4, GAME_5_1
	beq  $22, 5, GAME_6_1
	
	beq  $22, 6, OVER_1_1
	beq  $22, 7, OVER_2_1
	beq  $22, 8, OVER_3_1
	beq  $22, 9, OVER_4_1
	beq  $22, 10, OVER_5_1
	beq  $22, 11, OVER_6_1
	
####   GAME 1   ####
GAME_1_1:
	jal erase
	bgt  $12, 59, GAME_1_1
	beq  $12, 59, GAME_1_2
	bgt  $12, 49, GAME_1_1
	beq  $12, 49, GAME_1_2
	bgt  $12, 41, GAME_1_1
	beq  $12, 41, GAME_1_2
	bgt  $12, 33, GAME_1_1
	beq  $12, 33, GAME_1_2
	bgt  $12, 29, GAME_1_1
			
GAME_1_2:
	jal draw
	bgt  $12, 53, GAME_1_2
	beq  $12, 53, GAME_1_1
	bgt  $12, 45, GAME_1_2
	beq  $12, 45, GAME_1_1
	bgt  $12, 39, GAME_1_2
	beq  $12, 39, GAME_1_1
	bgt  $12, 31, GAME_1_2
	beq  $12, 31, GAME_1_1
	bgt  $12, 21, GAME_1_2
	
	j wordrawingController

####   GAME 2   ####
GAME_2_1:
	jal draw
	bgt  $12, 59, GAME_2_1
	beq  $12, 59, GAME_2_2
	bgt  $12, 49, GAME_2_1
	beq  $12, 49, GAME_2_2
	bgt  $12, 43, GAME_2_1
	beq  $12, 43, GAME_2_2
	bgt  $12, 37, GAME_2_1
	beq  $12, 37, GAME_2_2
	bgt  $12, 31, GAME_2_1
	beq  $12, 31, GAME_2_2
	bgt  $12, 27, GAME_2_1
	beq  $12, 27, GAME_2_2
			
GAME_2_2:
	jal erase
	bgt  $12, 51, GAME_2_2
	beq  $12, 51, GAME_2_1
	bgt  $12, 45, GAME_2_2
	beq  $12, 45, GAME_2_1
	bgt  $12, 41, GAME_2_2
	beq  $12, 41, GAME_2_1
	bgt  $12, 35, GAME_2_2
	beq  $12, 35, GAME_2_1
	bgt  $12, 29, GAME_2_2
	beq  $12, 29, GAME_2_1
	bgt  $12, 21, GAME_2_2
	
	j wordrawingController

####   GAME 3   ####	
GAME_3_1:
	jal draw
	bgt  $12, 59, GAME_3_1
	beq  $12, 59, GAME_3_2
	bgt  $12, 53, GAME_3_1
	beq  $12, 53, GAME_3_2
	bgt  $12, 49, GAME_3_1
	beq  $12, 49, GAME_3_2
	bgt  $12, 43, GAME_3_1
	beq  $12, 43, GAME_3_2
	bgt  $12, 39, GAME_3_1
	beq  $12, 39, GAME_3_2
	bgt  $12, 35, GAME_3_1
	beq  $12, 35, GAME_3_2
	bgt  $12, 31, GAME_3_1
	beq  $12, 31, GAME_3_2
	bgt  $12, 21, GAME_3_1
	
	j wordrawingController
	
GAME_3_2:
	jal erase
	bgt  $12, 57, GAME_3_2
	beq  $12, 57, GAME_3_1
	bgt  $12, 51, GAME_3_2
	beq  $12, 51, GAME_3_1
	bgt  $12, 45, GAME_3_2
	beq  $12, 45, GAME_3_1
	bgt  $12, 41, GAME_3_2
	beq  $12, 41, GAME_3_1
	bgt  $12, 37, GAME_3_2
	beq  $12, 37, GAME_3_1
	bgt  $12, 33, GAME_3_2
	beq  $12, 33, GAME_3_1
	bgt  $12, 29, GAME_3_2
	beq  $12, 29, GAME_3_1

####   GAME 4   ####
GAME_4_1:
	jal draw
	bgt  $12, 59, GAME_4_1
	beq  $12, 59, GAME_4_2
	bgt  $12, 53, GAME_4_1
	beq  $12, 53, GAME_4_2
	bgt  $12, 43, GAME_4_1
	beq  $12, 43, GAME_4_2
	bgt  $12, 39, GAME_4_1
	beq  $12, 39, GAME_4_2
	bgt  $12, 31, GAME_4_1
	beq  $12, 31, GAME_4_2
	bgt  $12, 27, GAME_4_1
			
GAME_4_2:
	jal erase
	bgt  $12, 55, GAME_4_2
	beq  $12, 55, GAME_4_1
	bgt  $12, 51, GAME_4_2
	beq  $12, 51, GAME_4_1
	bgt  $12, 41, GAME_4_2
	beq  $12, 41, GAME_4_1
	bgt  $12, 33, GAME_4_2
	beq  $12, 33, GAME_4_1
	bgt  $12, 29, GAME_4_2
	beq  $12, 29, GAME_4_1
	bgt  $12, 21, GAME_4_2
	
	j wordrawingController
	
####   GAME 5   ####
GAME_5_1:
	jal draw
	bgt  $12, 59, GAME_5_1
	beq  $12, 59, GAME_5_2
	bgt  $12, 53, GAME_5_1
	beq  $12, 53, GAME_5_2
	bgt  $12, 49, GAME_5_1
	beq  $12, 49, GAME_5_2
	bgt  $12, 43, GAME_5_1
	beq  $12, 43, GAME_5_2
	bgt  $12, 39, GAME_5_1
	beq  $12, 39, GAME_5_2
	bgt  $12, 31, GAME_5_1
	beq  $12, 31, GAME_5_2
	bgt  $12, 27, GAME_5_1
			
GAME_5_2:
	jal erase
	bgt  $12, 55, GAME_5_2
	beq  $12, 55, GAME_5_1
	bgt  $12, 51, GAME_5_2
	beq  $12, 51, GAME_5_1
	bgt  $12, 45, GAME_5_2
	beq  $12, 45, GAME_5_1
	bgt  $12, 41, GAME_5_2
	beq  $12, 41, GAME_5_1
	bgt  $12, 33, GAME_5_2
	beq  $12, 33, GAME_5_1
	bgt  $12, 29, GAME_5_2
	beq  $12, 29, GAME_5_1
	bgt  $12, 21, GAME_5_2
	
	j wordrawingController

####   GAME 6   ####
GAME_6_1:
	jal erase
	bgt  $12, 59, GAME_6_1
	beq  $12, 59, GAME_6_2
	bgt  $12, 51, GAME_6_1
	beq  $12, 51, GAME_6_2
	bgt  $12, 45, GAME_6_1
	beq  $12, 45, GAME_6_2
	bgt  $12, 41, GAME_6_1
	beq  $12, 41, GAME_6_2
	bgt  $12, 33, GAME_6_1
	beq  $12, 33, GAME_6_2
	bgt  $12, 29, GAME_6_1
			
GAME_6_2:
	jal draw
	bgt  $12, 55, GAME_6_2
	beq  $12, 55, GAME_6_1
	bgt  $12, 49, GAME_6_2
	beq  $12, 49, GAME_6_1
	bgt  $12, 43, GAME_6_2
	beq  $12, 43, GAME_6_1
	bgt  $12, 39, GAME_6_2
	beq  $12, 39, GAME_6_1
	bgt  $12, 31, GAME_6_2
	beq  $12, 31, GAME_6_1
	bgt  $12, 21, GAME_6_2
	
	j wordrawingController
	
####   OVER 1   ####
OVER_1_1:
	jal erase
	bgt  $12, 59, OVER_1_1
	beq  $12, 59, OVER_1_2
	bgt  $12, 51, OVER_1_1
	beq  $12, 51, OVER_1_2
	bgt  $12, 43, OVER_1_1
	beq  $12, 43, OVER_1_2
	bgt  $12, 39, OVER_1_1
	beq  $12, 39, OVER_1_2
	bgt  $12, 29, OVER_1_1
	beq  $12, 29, OVER_1_2
	bgt  $12, 21, OVER_1_1
	
	j wordrawingController
	
OVER_1_2:
	jal draw
	bgt  $12, 55, OVER_1_2
	beq  $12, 55, OVER_1_1
	bgt  $12, 49, OVER_1_2
	beq  $12, 49, OVER_1_1
	bgt  $12, 41, OVER_1_2
	beq  $12, 41, OVER_1_1
	bgt  $12, 31, OVER_1_2
	beq  $12, 31, OVER_1_1
	bgt  $12, 23, OVER_1_2
	beq  $12, 23, OVER_1_1
	
####   OVER 2   ####
OVER_2_1:
	jal draw
	bgt  $12, 59, OVER_2_1
	beq  $12, 59, OVER_2_2
	bgt  $12, 53, OVER_2_1
	beq  $12, 53, OVER_2_2
	bgt  $12, 49, OVER_2_1
	beq  $12, 49, OVER_2_2
	bgt  $12, 41, OVER_2_1
	beq  $12, 41, OVER_2_2
	bgt  $12, 37, OVER_2_1
	beq  $12, 37, OVER_2_2
	bgt  $12, 27, OVER_2_1
	beq  $12, 27, OVER_2_2
	bgt  $12, 21, OVER_2_1
	
	j wordrawingController
	
OVER_2_2:
	jal erase
	bgt  $12, 55, OVER_2_2
	beq  $12, 55, OVER_2_1
	bgt  $12, 51, OVER_2_2
	beq  $12, 51, OVER_2_1
	bgt  $12, 43, OVER_2_2
	beq  $12, 43, OVER_2_1
	bgt  $12, 39, OVER_2_2
	beq  $12, 39, OVER_2_1
	bgt  $12, 29, OVER_2_2
	beq  $12, 29, OVER_2_1
	bgt  $12, 23, OVER_2_2
	beq  $12, 23, OVER_2_1
	
####   OVER 3   ####
OVER_3_1:
	jal draw
	bgt  $12, 59, OVER_3_1
	beq  $12, 59, OVER_3_2
	bgt  $12, 53, OVER_3_1
	beq  $12, 53, OVER_3_2
	bgt  $12, 49, OVER_3_1
	beq  $12, 49, OVER_3_2
	bgt  $12, 41, OVER_3_1
	beq  $12, 41, OVER_3_2
	bgt  $12, 31, OVER_3_1
	beq  $12, 31, OVER_3_2
	bgt  $12, 23, OVER_3_1
	beq  $12, 23, OVER_3_2
	
OVER_3_2:
	jal erase
	bgt  $12, 55, OVER_3_2
	beq  $12, 55, OVER_3_1
	bgt  $12, 51, OVER_3_2
	beq  $12, 51, OVER_3_1
	bgt  $12, 43, OVER_3_2
	beq  $12, 43, OVER_3_1
	bgt  $12, 39, OVER_3_2
	beq  $12, 39, OVER_3_1
	bgt  $12, 29, OVER_3_2
	beq  $12, 29, OVER_3_1
	bgt  $12, 21, OVER_3_2
	
	j wordrawingController
	
####   OVER 4   ####
OVER_4_1:
	jal draw
	bgt  $12, 59, OVER_4_1
	beq  $12, 59, OVER_4_2
	bgt  $12, 53, OVER_4_1
	beq  $12, 53, OVER_4_2
	bgt  $12, 49, OVER_4_1
	beq  $12, 49, OVER_4_2
	bgt  $12, 41, OVER_4_1
	beq  $12, 41, OVER_4_2
	bgt  $12, 37, OVER_4_1
	beq  $12, 37, OVER_4_2
	bgt  $12, 27, OVER_4_1
	beq  $12, 27, OVER_4_2
	bgt  $12, 21, OVER_4_1

	j wordrawingController	
	
OVER_4_2:
	jal erase
	bgt  $12, 55, OVER_4_2
	beq  $12, 55, OVER_4_1
	bgt  $12, 51, OVER_4_2
	beq  $12, 51, OVER_4_1
	bgt  $12, 43, OVER_4_2
	beq  $12, 43, OVER_4_1
	bgt  $12, 39, OVER_4_2
	beq  $12, 39, OVER_4_1
	bgt  $12, 29, OVER_4_2
	beq  $12, 29, OVER_4_1
	bgt  $12, 23, OVER_4_2
	beq  $12, 23, OVER_4_1
	
####   OVER 5   ####
OVER_5_1:
	jal draw
	bgt  $12, 59, OVER_5_1
	beq  $12, 59, OVER_5_2
	bgt  $12, 53, OVER_5_1
	beq  $12, 53, OVER_5_2
	bgt  $12, 47, OVER_5_1
	beq  $12, 47, OVER_5_2
	bgt  $12, 43, OVER_5_1
	beq  $12, 43, OVER_5_2
	bgt  $12, 37, OVER_5_1
	beq  $12, 37, OVER_5_2
	bgt  $12, 27, OVER_5_1
	beq  $12, 27, OVER_5_2
	bgt  $12, 21, OVER_5_1

	j wordrawingController	
	
OVER_5_2:
	jal erase
	bgt  $12, 55, OVER_5_2
	beq  $12, 55, OVER_5_1
	bgt  $12, 49, OVER_5_2
	beq  $12, 49, OVER_5_1
	bgt  $12, 45, OVER_5_2
	beq  $12, 45, OVER_5_1
	bgt  $12, 39, OVER_5_2
	beq  $12, 39, OVER_5_1
	bgt  $12, 29, OVER_5_2
	beq  $12, 29, OVER_5_1
	bgt  $12, 23, OVER_5_2
	beq  $12, 23, OVER_5_1
	
####   OVER 6   ####
OVER_6_1:
	jal erase
	bgt  $12, 59, OVER_6_1
	beq  $12, 59, OVER_6_2
	bgt  $12, 47, OVER_6_1
	beq  $12, 47, OVER_6_2
	bgt  $12, 39, OVER_6_1
	beq  $12, 39, OVER_6_2
	bgt  $12, 29, OVER_6_1
	beq  $12, 29, OVER_6_2
	bgt  $12, 23, OVER_6_1
	
OVER_6_2:
	jal draw
	bgt  $12, 55, OVER_6_2
	beq  $12, 55, OVER_6_1
	bgt  $12, 45, OVER_6_2
	beq  $12, 45, OVER_6_1
	bgt  $12, 31, OVER_6_2
	beq  $12, 31, OVER_6_1
	bgt  $12, 27, OVER_6_2
	beq  $12, 27, OVER_6_1
	bgt  $12, 21, OVER_6_2
	
wordrawingController:
	addi $21, $21, -1
	li   $20, 0
	j drawGameOverBlock

setCondrawords:
	sgt  $20, $13, 24
	beq  $20, 1, continue1
	sle  $20, $13, 20
	beq  $20, 0, continue1
	sgt  $20, $13, 8
	j continue1
	
fim:
	addi $2, $0, 10
	syscall
