
; ascii.s - Useful defintions for ASCII characters.
;
; Copyright (C) 2024 Rhys Weatherley.
;
; Permission is hereby granted, free of charge, to any person obtaining a
; copy of this software and associated documentation files (the "Software"),
; to deal in the Software without restriction, including without limitation
; the rights to use, copy, modify, merge, publish, distribute, sublicense,
; and/or sell copies of the Software, and to permit persons to whom the
; Software is furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included
; in all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
; OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
; DEALINGS IN THE SOFTWARE.
;

;
; TTY operations that can be performed with $FFF7 in the monitor.
; Set X to the operation to be performed.
;
TTY_OP_RESET_COLORS     .equ    0   ; Reset colors to the defaults.
TTY_OP_CLEAR_SCREEN     .equ    1   ; Clear the screen.
TTY_OP_CLREOS           .equ    2   ; Clear to the end of the screen.
TTY_OP_CLREOL           .equ    3   ; Clear to the end of the line.
TTY_OP_HOME             .equ    4   ; Move the cursor to X = 0, Y = 0.
TTY_OP_MOVE_LEFT        .equ    5   ; Move one position to the left.
TTY_OP_MOVE_RIGHT       .equ    6   ; Move one position to the right.
TTY_OP_MOVE_UP          .equ    7   ; Move one line up, no scrolling.
TTY_OP_MOVE_DOWN        .equ    8   ; Move one line down, no scrolling.
TTY_OP_DELETE_CHAR      .equ    9   ; Delete the character under the cursor.
TTY_OP_INSERT_CHAR      .equ    10  ; Insert a space under the cursor.
TTY_OP_DELETE_LINE      .equ    11  ; Delete the current line.
TTY_OP_INSERT_LINE      .equ    12  ; Insert a new line.
TTY_OP_COUNT            .equ    TTY_OP_INSERT_LINE+1
