.386
.model flat, stdcall
.stack 4096
ExitProcess proto, dwExitCode:dword
include Irvine32.inc

printBoard proto, boardPtr:ptr byte
printStats proto, score:dword
setBorder proto, boardPtr:ptr byte
getTileAtPosition proto, boardPtr:ptr byte, row:byte, col:byte
setTileAtPosition proto, boardPtr:ptr byte, row:byte, col:byte, value:byte
printTile proto, rawValue:byte
generateShape proto, boardPtr:ptr byte
rotateLeft proto
rotateRight proto
; Working on:
; moveLeft proto, boardPtr:ptr byte, currentRow:ptr byte, currentCol:ptr byte, currentShape:ptr Shape, orientation:byte
; moveRight proto, boardPtr:ptr byte, currentRow:ptr byte, currentCol:ptr byte, currentShape:ptr Shape, orientation:byte
; moveDown proto, boardPtr:ptr byte, currentRow:ptr byte, currentCol:ptr byte, currentShape:ptr Shape, orientation:byte
; isValidMove proto, boardPtr:ptr byte, nextRow:byte, nextCol:byte, currentShape:ptr Shape, orientation:byte

isCompleteRow proto, boardPtr:ptr byte, row:byte
isEmptyRow proto, boardPtr:ptr byte, row:byte
clearCompletedRows proto, boardPtr:ptr byte
clearRow proto, boardPtr:ptr byte, row:byte
clearBoard proto, boardPtr:ptr byte

BOARD_WIDTH = 10 + 2
BOARD_HEIGHT = 20 + 2

; Tile values
EMPTY_TILE = 00h
I_TILE = 01h
J_TILE = 02h
L_TILE = 03h
O_TILE = 04h
S_TILE = 05h
T_TILE = 06h
Z_TILE = 07h
BORDER_TILE = 0FFh
TILES_PER_SHAPE = 4
ORIENTATIONS_PER_SHAPE = 4

Shape struct
    tile byte 0
    orientations word ORIENTATIONS_PER_SHAPE dup(0)
Shape ends

.data
board byte BOARD_WIDTH * BOARD_HEIGHT dup(0)
currentOrientation byte 0
currentScore dword 0
currentShape Shape <>
currentRow byte ?
currentCol byte ?

hideCursorInfo CONSOLE_CURSOR_INFO <1, 0>
scoreLabel byte "Score: ", 0

; Define shapes
iShape Shape <I_TILE, <00F00h, 02222h, 000F0h, 04444h>>
jShape Shape <J_TILE, <044C0h, 08E00h, 06440h, 00E20h>>
lShape Shape <L_TILE, <04460h, 00E80h, 0C440h, 02E00h>>
oShape Shape <O_TILE, <0CC00h, 0CC00h, 0CC00h, 0CC00h>>
sShape Shape <S_TILE, <006C0h, 08C40h, 06C00h, 04620h>>
tShape Shape <T_TILE, <00E40h, 04C40h, 04E00h, 04640h>>
zShape Shape <Z_TILE, <00C60h, 04C80h, 0C600h, 02640h>>

.code
main proc
    invoke setBorder, offset board

l1:
    ; Hide cursor during game
    invoke GetStdhandle, STD_OUTPUT_HANDLE
    invoke SetConsoleCursorInfo, eax, offset hideCursorInfo

    ; Re-print board
    ; invoke clearBoard, offset board
    invoke generateShape, offset board
    invoke printBoard, offset board

    ; Re-print score
    call Crlf
    invoke printStats, [currentScore]

    ; Delay before next update
    mov eax, 2000
    call Delay
    loop l1
    ; Get input
    ; Move shape
    ; Check for any complete rows and set them to free spaces
    ; Move any bytes above empty spaces down
    ; Update score

    invoke printBoard, offset board

    invoke ExitProcess, 0
main endp

printBoard proc uses eax ebx ecx edx, boardPtr:ptr byte
    local rowIndex:byte, colIndex:byte
    ; Move cursor to top-left so we overwrite the previous print
    mov edx, 0
    call Gotoxy
    mov rowIndex, 0
    mov ecx, BOARD_HEIGHT
traverseRow:
    push ecx
    mov ecx, BOARD_WIDTH
    mov colIndex, 0
    ; Begin inner loop
traverseCol:
    invoke getTileAtPosition, boardPtr, rowIndex, colIndex
    invoke printTile, al
    inc colIndex
    loop traverseCol
    ; End inner loop
    call Crlf
    inc rowIndex
    pop ecx
    loop traverseRow
    ret
printBoard endp

printStats proc uses eax edx, score:dword
    ; Print label
    mov edx, offset scoreLabel
    call WriteString
    ; Print score value
    mov eax, [score]
    call WriteDec
    ret
printStats endp

setBorder proc uses ecx, boardPtr:ptr byte
    local index:byte
    ; Print left and right border
    mov index, 0
    mov ecx, BOARD_HEIGHT
traverseRow:
    invoke setTileAtPosition, boardPtr, index, 0, BORDER_TILE
    invoke setTileAtPosition, boardPtr, index, BOARD_WIDTH - 1, BORDER_TILE
    inc index
    loop traverseRow
    ; Print bottom border
    mov index, 0
    mov ecx, BOARD_WIDTH
traverseBottomRow:
    invoke setTileAtPosition, boardPtr, BOARD_HEIGHT - 1, index, BORDER_TILE
    inc index
    loop traverseBottomRow
    ret
setBorder endp

getTileAtPosition proc uses ebx esi,
    boardPtr:ptr byte,
    row:byte,
    col:byte
    ; (row * BOARD_WIDTH) + col
    mov eax, BOARD_WIDTH
    mul row
    add eax, boardPtr
    movzx esi, [col]
    mov ebx, [eax + esi]
    mov eax, ebx
    ret
getTileAtPosition endp

setTileAtPosition proc uses eax ebx esi,
    boardPtr:ptr byte,
    row:byte,
    col:byte,
    value:byte
    ; (row * BOARD_WIDTH) + col
    mov eax, BOARD_WIDTH
    mul row
    add eax, boardPtr
    movzx esi, [col]
    mov bl, [value]
    mov [eax + esi], bl
    ret
setTileAtPosition endp

printTile proc uses eax, rawValue:byte
    mov eax, 0
    .if rawValue == EMPTY_TILE
        or al, black
    .elseif rawValue == I_TILE
        or al, cyan
    .elseif rawValue == J_TILE
        or al, blue
    .elseif rawValue == L_TILE
        or al, brown
    .elseif rawValue == O_TILE
        or al, yellow
    .elseif rawValue == S_TILE
        or al, lightGreen
    .elseif rawValue == T_TILE
        or al, magenta
    .elseif rawValue == Z_TILE
        or al, red
    .elseif rawValue == BORDER_TILE
        or al, gray
    .endif
    ; Set block color
    call SetTextColor
    ; 219 is the ASCII code for █ (block character)
    mov al, 219
    ; Print two rectangles to make a square
    call WriteChar
    call WriteChar
    ret
printTile endp

generateShape proc uses eax, boardPtr:ptr byte
    ; Random number between 1–7
    mov eax, 7
    call RandomRange
    inc eax

    ; Print shape depending on number drawn
    BOARD_CENTER_COL = BOARD_WIDTH / 2
    .if al == I_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL, I_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL, I_TILE
        invoke setTileAtPosition, boardPtr, 2, BOARD_CENTER_COL, I_TILE
        invoke setTileAtPosition, boardPtr, 3, BOARD_CENTER_COL, I_TILE
    .elseif al == J_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL, J_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL, J_TILE
        invoke setTileAtPosition, boardPtr, 2, BOARD_CENTER_COL, J_TILE
        invoke setTileAtPosition, boardPtr, 2, BOARD_CENTER_COL - 1, J_TILE
    .elseif al == L_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL, L_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL, L_TILE
        invoke setTileAtPosition, boardPtr, 2, BOARD_CENTER_COL, L_TILE
        invoke setTileAtPosition, boardPtr, 2, BOARD_CENTER_COL + 1, L_TILE
    .elseif al == O_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL, O_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL, O_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL + 1, O_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL + 1, O_TILE
    .elseif al == S_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL + 1, S_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL, S_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL, S_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL - 1, S_TILE
    .elseif al == T_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL, T_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL - 1, T_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL, T_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL + 1, T_TILE
    .elseif al == Z_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL - 1, Z_TILE
        invoke setTileAtPosition, boardPtr, 0, BOARD_CENTER_COL, Z_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL, Z_TILE
        invoke setTileAtPosition, boardPtr, 1, BOARD_CENTER_COL + 1, Z_TILE
    .endif
    ret
generateShape endp

; rotateLeft proc uses eax
;     mov al, [currentOrientation]
;     .if al == 0
;         mov al, ORIENTATIONS_PER_SHAPE - 1
;     .else
;         dec al
;     .endif
;     mov [currentOrientation], al
;     ret
; rotateLeft endp

; rotateRight proc uses eax
;     mov al, [currentOrientation]
;     .if al == ORIENTATIONS_PER_SHAPE - 1
;         mov al, 0
;     .else
;         inc al
;     .endif
;     mov [currentOrientation], al
;     ret
; rotateRight endp

; moveLeft proc uses eax,
;     boardPtr:ptr byte,
;     currentRow:ptr byte,
;     currentCol:ptr byte,
;     currentShape:ptr Shape,
;     orientation:byte

;     invoke isValidMove, boardPtr, [currentRow] - 1, [currentCol], currentShape, orientation
;     .if al == 1
;         dec currentCol
;     .endif
;     ret
; moveLeft endp

; moveRight proc uses eax,
;     boardPtr:ptr byte,
;     currentRow:ptr byte,
;     currentCol:ptr byte,
;     currentShape: ptr Shape,
;     orientation:byte

;     invoke isValidMove, boardPtr, [currentRow], [currentCol] + 1, currentShape, orientation
;     .if al == 1
;         inc currentCol
;     .endif
;     ret
; moveRight endp

; moveDown proc uses eax,
;     boardPtr:ptr byte,
;     currentRow:ptr byte,
;     currentCol:ptr byte,
;     currentShape:ptr Shape,
;     orientation:byte

;     invoke isValidMove, boardPtr, [currentRow] + 1, [currentCol], currentShape, orientation
;     .if al == 1
;         inc currentRow
;     .endif
;     ret
; moveDown endp

; isValidMove proc,
;     boardPtr:ptr byte,
;     nextRow:byte,
;     nextCol:byte,
;     currentShape:ptr Shape,
;     orientation:byte



;     ret
; isValidMove endp

isCompleteRow proc uses ecx esi, boardPtr:ptr byte, row:byte
    ; Exclude borders and start from inside the board
    mov ecx, BOARD_WIDTH - 2
    mov esi, 1
traverseCol:
    invoke getTileAtPosition, boardPtr, [row], byte ptr [esi]
    ; If the tile is empty, the row isn't complete. We can stop checking and return.
    .if al == EMPTY_TILE
        mov eax, 0
        ret
    .endif
    ; Increment index
    inc esi
    loop traverseCol
    ; If we've made it here, the row is complete
    mov eax, 1
    ret
isCompleteRow endp

isEmptyRow proc uses ecx esi, boardPtr:ptr byte, row:byte
    ; Exclude borders and start from inside the board
    mov ecx, BOARD_WIDTH - 2
    mov esi, 1
traverseCol:
    invoke getTileAtPosition, boardPtr, [row], byte ptr [esi]
    ; If the tile isn't empty, the row isn't empty. We can stop checking and return.
    .if al != EMPTY_TILE
        mov eax, 0
        ret
    .endif
    ; Increment index
    inc esi
    loop traverseCol
    ; If we've made it here, the row is empty
    mov eax, 1
    ret
isEmptyRow endp

clearCompletedRows proc uses ecx esi, boardPtr:ptr byte
    local linesCleared:byte
    mov linesCleared, 0
    ; Exclude bottom border
    mov ecx, BOARD_HEIGHT - 1
    mov esi, 0
traverseRow:
    ; If the current row is complete, clear it
    invoke isCompleteRow, boardPtr, byte ptr [esi]
    .if eax == 1
        invoke clearRow, boardPtr, byte ptr [esi]
        inc linesCleared
    .endif
    inc esi
    loop traverseRow
    ; Return number of lines cleared
    movzx eax, [linesCleared]
    ret
clearCompletedRows endp

clearRow proc uses ecx esi, boardPtr:ptr byte, row:byte
    mov ecx, BOARD_WIDTH - 2
    mov esi, 1
traverseRow:
    invoke setTileAtPosition, boardPtr, [row], byte ptr [esi], EMPTY_TILE
    inc esi
    loop traverseRow
    ret
clearRow endp

clearBoard proc uses ecx esi, boardPtr:ptr byte
    mov ecx, BOARD_HEIGHT - 1
    mov esi, 0
traverseRow:
    invoke clearRow, boardPtr, byte ptr [esi]
    inc esi
    loop traverseRow
    ret
clearBoard endp
end main
