;
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
; If "HIGH_ASCII" is defined, then use the "High ASCII" of the Apple II
; where bit 7 is set.  Otherwise use standard ASCII.
;

    .ifndef HIGH_ASCII
CHAR_NUL    .equ    $00         ; NUL
CHAR_SOH    .equ    $01         ; CTRL-A - Start of heading
CHAR_STX    .equ    $02         ; CTRL-B - Start of text
CHAR_ETX    .equ    $03         ; CTRL-C - End of text
CHAR_EOT    .equ    $04         ; CTRL-D - End of transmission
CHAR_ENQ    .equ    $05         ; CTRL-E - Enquiry
CHAR_ACK    .equ    $06         ; CTRL-F - Acknowledge
CHAR_BEL    .equ    $07         ; CTRL-G - Terminal bell
CHAR_BS     .equ    $08         ; CTRL-H - Backspace
CHAR_HT     .equ    $09         ; CTRL-I - Horizontal tab
CHAR_LF     .equ    $0A         ; CTRL-J - Line feed
CHAR_VT     .equ    $0B         ; CTRL-K - Vertical tab
CHAR_FF     .equ    $0C         ; CTRL-L - Clear screen
CHAR_CR     .equ    $0D         ; CTRL-M - Carriage return
CHAR_SO     .equ    $0E         ; CTRL-N - Shift out
CHAR_SI     .equ    $0F         ; CTRL-O - Shift in
CHAR_DLE    .equ    $10         ; CTRL-P - Data link escape
CHAR_DC1    .equ    $11         ; CTRL-Q - Device control 1
CHAR_DC2    .equ    $12         ; CTRL-R - Device control 2
CHAR_DC3    .equ    $13         ; CTRL-S - Device control 3
CHAR_DC4    .equ    $14         ; CTRL-T - Device control 4
CHAR_NAK    .equ    $15         ; CTRL-U - Negative acknowledge
CHAR_SYN    .equ    $16         ; CTRL-V - Synchronous idle
CHAR_ETB    .equ    $17         ; CTRL-W - End of transmission block
CHAR_CAN    .equ    $18         ; CTRL-X - Cancel
CHAR_EM     .equ    $19         ; CTRL-Y - End of medium
CHAR_SUB    .equ    $1A         ; CTRL-Z - Substitute
CHAR_ESC    .equ    $1B         ; CTRL-[ - Escape
CHAR_FS     .equ    $1C         ; CTRL-\ - File separator
CHAR_GS     .equ    $1D         ; CTRL-] - Group separator
CHAR_RS     .equ    $1E         ; CTRL-^ - Record separator
CHAR_US     .equ    $1F         ; CTRL-_ - Unit separator
CHAR_SP     .equ    $20         ; Space
CHAR_EXC    .equ    $21         ; Exclamation mark
CHAR_QUOTE  .equ    $22         ; Double quote
CHAR_HASH   .equ    $23         ; Hash sign
CHAR_DOL    .equ    $24         ; Dollar sign
CHAR_PCT    .equ    $25         ; Percentage sign
CHAR_AMP    .equ    $26         ; Ampersand
CHAR_SQUOTE .equ    $27         ; Single quote
CHAR_LPAR   .equ    $28         ; Left parenthesis
CHAR_RPAR   .equ    $29         ; Right parenthesis
CHAR_STAR   .equ    $2A         ; Asterisk / multiplication
CHAR_PLUS   .equ    $2B         ; Plus sign
CHAR_COMMA  .equ    $2C         ; Comma
CHAR_MINUS  .equ    $2D         ; Minus sign
CHAR_PERIOD .equ    $2E         ; Period
CHAR_SLASH  .equ    $2F         ; Forward slash
CHAR_0      .equ    $30         ; Digit 0
CHAR_1      .equ    $31         ; Digit 1
CHAR_2      .equ    $32         ; Digit 2
CHAR_3      .equ    $33         ; Digit 3
CHAR_4      .equ    $34         ; Digit 4
CHAR_5      .equ    $35         ; Digit 5
CHAR_6      .equ    $36         ; Digit 6
CHAR_7      .equ    $37         ; Digit 7
CHAR_8      .equ    $38         ; Digit 8
CHAR_9      .equ    $39         ; Digit 9
CHAR_COLON  .equ    $3A         ; Colon
CHAR_SEMI   .equ    $3B         ; Semi-colon
CHAR_LT     .equ    $3C         ; Less than
CHAR_EQ     .equ    $3D         ; Equal
CHAR_GT     .equ    $3E         ; Greater than
CHAR_QUEST  .equ    $3F         ; Question mark
CHAR_AT     .equ    $40         ; "@"
CHAR_A      .equ    $41         ; "A"
CHAR_B      .equ    $42         ; "B"
CHAR_C      .equ    $43         ; "C"
CHAR_D      .equ    $44         ; "D"
CHAR_E      .equ    $45         ; "E"
CHAR_F      .equ    $46         ; "F"
CHAR_G      .equ    $47         ; "G"
CHAR_H      .equ    $48         ; "H"
CHAR_I      .equ    $49         ; "I"
CHAR_J      .equ    $4A         ; "J"
CHAR_K      .equ    $4B         ; "K"
CHAR_L      .equ    $4C         ; "L"
CHAR_M      .equ    $4D         ; "M"
CHAR_N      .equ    $4E         ; "N"
CHAR_O      .equ    $4F         ; "O"
CHAR_P      .equ    $50         ; "P"
CHAR_Q      .equ    $51         ; "Q"
CHAR_R      .equ    $52         ; "R"
CHAR_S      .equ    $53         ; "S"
CHAR_T      .equ    $54         ; "T"
CHAR_U      .equ    $55         ; "U"
CHAR_V      .equ    $56         ; "V"
CHAR_W      .equ    $57         ; "W"
CHAR_X      .equ    $58         ; "X"
CHAR_Y      .equ    $59         ; "Y"
CHAR_Z      .equ    $5A         ; "Z"
CHAR_LSQ    .equ    $5B         ; "["
CHAR_BSLASH .equ    $5C         ; Back slash
CHAR_RSQ    .equ    $5D         ; "]"
CHAR_CARET  .equ    $5E         ; Caret
CHAR_UNDER  .equ    $5F         ; Underscore
CHAR_BQUOTE .equ    $60         ; Back quote
CHAR_A_L    .equ    $61         ; "a"
CHAR_B_L    .equ    $62         ; "b"
CHAR_C_L    .equ    $63         ; "c"
CHAR_D_L    .equ    $64         ; "d"
CHAR_E_L    .equ    $65         ; "e"
CHAR_F_L    .equ    $66         ; "f"
CHAR_G_L    .equ    $67         ; "g"
CHAR_H_L    .equ    $68         ; "h"
CHAR_I_L    .equ    $69         ; "i"
CHAR_J_L    .equ    $6A         ; "j"
CHAR_K_L    .equ    $6B         ; "k"
CHAR_L_L    .equ    $6C         ; "l"
CHAR_M_L    .equ    $6D         ; "m"
CHAR_N_L    .equ    $6E         ; "n"
CHAR_O_L    .equ    $6F         ; "o"
CHAR_P_L    .equ    $70         ; "p"
CHAR_Q_L    .equ    $71         ; "q"
CHAR_R_L    .equ    $72         ; "r"
CHAR_S_L    .equ    $73         ; "s"
CHAR_T_L    .equ    $74         ; "t"
CHAR_U_L    .equ    $75         ; "u"
CHAR_V_L    .equ    $76         ; "v"
CHAR_W_L    .equ    $77         ; "w"
CHAR_X_L    .equ    $78         ; "x"
CHAR_Y_L    .equ    $79         ; "y"
CHAR_Z_L    .equ    $7A         ; "z"
CHAR_LCURLY .equ    $7B         ; "{"
CHAR_BAR    .equ    $7C         ; Vertical bar
CHAR_RCURLY .equ    $7D         ; "}"
CHAR_TILDE  .equ    $7E         ; Tilde
CHAR_DEL    .equ    $7F         ; DEL
    .else
CHAR_NUL    .equ    $80         ; NUL
CHAR_SOH    .equ    $81         ; CTRL-A - Start of heading
CHAR_STX    .equ    $82         ; CTRL-B - Start of text
CHAR_ETX    .equ    $83         ; CTRL-C - End of text
CHAR_EOT    .equ    $84         ; CTRL-D - End of transmission
CHAR_ENQ    .equ    $85         ; CTRL-E - Enquiry
CHAR_ACK    .equ    $86         ; CTRL-F - Acknowledge
CHAR_BEL    .equ    $87         ; CTRL-G - Terminal bell
CHAR_BS     .equ    $88         ; CTRL-H - Backspace
CHAR_HT     .equ    $89         ; CTRL-I - Horizontal tab
CHAR_LF     .equ    $8A         ; CTRL-J - Line feed
CHAR_VT     .equ    $8B         ; CTRL-K - Vertical tab
CHAR_FF     .equ    $8C         ; CTRL-L - Clear screen
CHAR_CR     .equ    $8D         ; CTRL-M - Carriage return
CHAR_SO     .equ    $8E         ; CTRL-N - Shift out
CHAR_SI     .equ    $8F         ; CTRL-O - Shift in
CHAR_DLE    .equ    $90         ; CTRL-P - Data link escape
CHAR_DC1    .equ    $91         ; CTRL-Q - Device control 1
CHAR_DC2    .equ    $92         ; CTRL-R - Device control 2
CHAR_DC3    .equ    $93         ; CTRL-S - Device control 3
CHAR_DC4    .equ    $94         ; CTRL-T - Device control 4
CHAR_NAK    .equ    $95         ; CTRL-U - Negative acknowledge
CHAR_SYN    .equ    $96         ; CTRL-V - Synchronous idle
CHAR_ETB    .equ    $97         ; CTRL-W - End of transmission block
CHAR_CAN    .equ    $98         ; CTRL-X - Cancel
CHAR_EM     .equ    $99         ; CTRL-Y - End of medium
CHAR_SUB    .equ    $9A         ; CTRL-Z - Substitute
CHAR_ESC    .equ    $9B         ; CTRL-[ - Escape
CHAR_FS     .equ    $9C         ; CTRL-\ - File separator
CHAR_GS     .equ    $9D         ; CTRL-] - Group separator
CHAR_RS     .equ    $9E         ; CTRL-^ - Record separator
CHAR_US     .equ    $9F         ; CTRL-_ - Unit separator
CHAR_SP     .equ    $A0         ; Space
CHAR_EXC    .equ    $A1         ; Exclamation mark
CHAR_QUOTE  .equ    $A2         ; Double quote
CHAR_HASH   .equ    $A3         ; Hash sign
CHAR_DOL    .equ    $A4         ; Dollar sign
CHAR_PCT    .equ    $A5         ; Percentage sign
CHAR_AMP    .equ    $A6         ; Ampersand
CHAR_SQUOTE .equ    $A7         ; Single quote
CHAR_LPAR   .equ    $A8         ; Left parenthesis
CHAR_RPAR   .equ    $A9         ; Right parenthesis
CHAR_STAR   .equ    $AA         ; Asterisk / multiplication
CHAR_PLUS   .equ    $AB         ; Plus sign
CHAR_COMMA  .equ    $AC         ; Comma
CHAR_MINUS  .equ    $AD         ; Minus sign
CHAR_PERIOD .equ    $AE         ; Period
CHAR_SLASH  .equ    $AF         ; Forward slash
CHAR_0      .equ    $B0         ; Digit 0
CHAR_1      .equ    $B1         ; Digit 1
CHAR_2      .equ    $B2         ; Digit 2
CHAR_3      .equ    $B3         ; Digit 3
CHAR_4      .equ    $B4         ; Digit 4
CHAR_5      .equ    $B5         ; Digit 5
CHAR_6      .equ    $B6         ; Digit 6
CHAR_7      .equ    $B7         ; Digit 7
CHAR_8      .equ    $B8         ; Digit 8
CHAR_9      .equ    $B9         ; Digit 9
CHAR_COLON  .equ    $BA         ; Colon
CHAR_SEMI   .equ    $BB         ; Semi-colon
CHAR_LT     .equ    $BC         ; Less than
CHAR_EQ     .equ    $BD         ; Equal
CHAR_GT     .equ    $BE         ; Greater than
CHAR_QUEST  .equ    $BF         ; Question mark
CHAR_AT     .equ    $C0         ; "@"
CHAR_A      .equ    $C1         ; "A"
CHAR_B      .equ    $C2         ; "B"
CHAR_C      .equ    $C3         ; "C"
CHAR_D      .equ    $C4         ; "D"
CHAR_E      .equ    $C5         ; "E"
CHAR_F      .equ    $C6         ; "F"
CHAR_G      .equ    $C7         ; "G"
CHAR_H      .equ    $C8         ; "H"
CHAR_I      .equ    $C9         ; "I"
CHAR_J      .equ    $CA         ; "J"
CHAR_K      .equ    $CB         ; "K"
CHAR_L      .equ    $CC         ; "L"
CHAR_M      .equ    $CD         ; "M"
CHAR_N      .equ    $CE         ; "N"
CHAR_O      .equ    $CF         ; "O"
CHAR_P      .equ    $D0         ; "P"
CHAR_Q      .equ    $D1         ; "Q"
CHAR_R      .equ    $D2         ; "R"
CHAR_S      .equ    $D3         ; "S"
CHAR_T      .equ    $D4         ; "T"
CHAR_U      .equ    $D5         ; "U"
CHAR_V      .equ    $D6         ; "V"
CHAR_W      .equ    $D7         ; "W"
CHAR_X      .equ    $D8         ; "X"
CHAR_Y      .equ    $D9         ; "Y"
CHAR_Z      .equ    $DA         ; "Z"
CHAR_LSQ    .equ    $DB         ; "["
CHAR_BSLASH .equ    $DC         ; Back slash
CHAR_RSQ    .equ    $DD         ; "]"
CHAR_CARET  .equ    $DE         ; Caret
CHAR_UNDER  .equ    $DF         ; Underscore
CHAR_BQUOTE .equ    $E0         ; Back quote
CHAR_A_L    .equ    $E1         ; "a"
CHAR_B_L    .equ    $E2         ; "b"
CHAR_C_L    .equ    $E3         ; "c"
CHAR_D_L    .equ    $E4         ; "d"
CHAR_E_L    .equ    $E5         ; "e"
CHAR_F_L    .equ    $E6         ; "f"
CHAR_G_L    .equ    $E7         ; "g"
CHAR_H_L    .equ    $E8         ; "h"
CHAR_I_L    .equ    $E9         ; "i"
CHAR_J_L    .equ    $EA         ; "j"
CHAR_K_L    .equ    $EB         ; "k"
CHAR_L_L    .equ    $EC         ; "l"
CHAR_M_L    .equ    $ED         ; "m"
CHAR_N_L    .equ    $EE         ; "n"
CHAR_O_L    .equ    $EF         ; "o"
CHAR_P_L    .equ    $F0         ; "p"
CHAR_Q_L    .equ    $F1         ; "q"
CHAR_R_L    .equ    $F2         ; "r"
CHAR_S_L    .equ    $F3         ; "s"
CHAR_T_L    .equ    $F4         ; "t"
CHAR_U_L    .equ    $F5         ; "u"
CHAR_V_L    .equ    $F6         ; "v"
CHAR_W_L    .equ    $F7         ; "w"
CHAR_X_L    .equ    $F8         ; "x"
CHAR_Y_L    .equ    $F9         ; "y"
CHAR_Z_L    .equ    $FA         ; "z"
CHAR_LCURLY .equ    $FB         ; "{"
CHAR_BAR    .equ    $FC         ; Vertical bar
CHAR_RCURLY .equ    $FD         ; "}"
CHAR_TILDE  .equ    $FE         ; Tilde
CHAR_DEL    .equ    $FF         ; DEL
    .endif

;
; Special key values.
;
    .ifdef HIGH_ASCII
KEY_UP      .equ    $9F         ; Up arrow
KEY_DOWN    .equ    $8A         ; Down arrow
KEY_LEFT    .equ    $88         ; Left arrow
KEY_RIGHT   .equ    $95         ; Right arrow
KEY_TAB     .equ    $89         ; TAB key
KEY_FESC    .equ    $7F         ; Function key escape.
    .else
KEY_UP      .equ    $1F         ; Up arrow
KEY_DOWN    .equ    $0A         ; Down arrow
KEY_LEFT    .equ    $08         ; Left arrow
KEY_RIGHT   .equ    $15         ; Right arrow
KEY_TAB     .equ    $09         ; TAB key
KEY_FESC    .equ    $FF         ; Function key escape.
    .endif

;
; Function key codes that will be in "FKEY" when KEY_FESC is returned.
;
KEY_F1      .equ    $A1         ; F1 key
KEY_F2      .equ    $A2         ; F2 key
KEY_F3      .equ    $A3         ; F3 key
KEY_F4      .equ    $A4         ; F4 key
KEY_F5      .equ    $A5         ; F5 key
KEY_F6      .equ    $A6         ; F6 key
KEY_F7      .equ    $A7         ; F7 key
KEY_F8      .equ    $A8         ; F8 key
KEY_F9      .equ    $A9         ; F9 key
KEY_F10     .equ    $AA         ; F10 key
KEY_F11     .equ    $AB         ; F11 key
KEY_F12     .equ    $AC         ; F12 key
KEY_F13     .equ    $AD         ; F13 key
KEY_F14     .equ    $AE         ; F14 key
KEY_F15     .equ    $AF         ; F15 key
KEY_F16     .equ    $B0         ; F16 key
KEY_F17     .equ    $B1         ; F17 key
KEY_F18     .equ    $B2         ; F18 key
KEY_F19     .equ    $B3         ; F19 key
KEY_F20     .equ    $B4         ; F20 key
KEY_F21     .equ    $B5         ; F21 key
KEY_F22     .equ    $B6         ; F22 key
KEY_F23     .equ    $B7         ; F23 key
KEY_F24     .equ    $B8         ; F24 key
KEY_INSERT  .equ    $B9         ; Insert key
KEY_DELETE  .equ    $BA         ; Delete key
KEY_HOME    .equ    $BB         ; Home key
KEY_END     .equ    $BC         ; End key
KEY_PGUP    .equ    $BD         ; Page up key
KEY_PGDN    .equ    $BE         ; Page down key
KEY_BACKTAB .equ    $BF         ; Back tab key
KEY_MIDDLE  .equ    $C0         ; Middle key on the numeric keypad (5)
KEY_S_UP    .equ    $C1         ; Shift+Up arrow
KEY_S_DOWN  .equ    $C2         ; Shift+Down arrow
KEY_S_LEFT  .equ    $C3         ; Shift+Left arrow
KEY_S_RIGHT .equ    $C4         ; Shift+Right arrow
KEY_S_INSERT .equ   $C9         ; Shift+Insert key
KEY_S_DELETE .equ   $CA         ; Shift+Delete key
KEY_S_HOME  .equ    $CB         ; Shift+Home key
KEY_S_END   .equ    $CC         ; Shift+End key
KEY_S_PGUP  .equ    $CD         ; Shift+Page up key
KEY_S_PGDN  .equ    $CE         ; Shift+Page down key
KEY_C_UP    .equ    $D1         ; Ctrl+Up arrow
KEY_C_DOWN  .equ    $D2         ; Ctrl+Down arrow
KEY_C_LEFT  .equ    $D3         ; Ctrl+Left arrow
KEY_C_RIGHT .equ    $D4         ; Ctrl+Right arrow
KEY_C_INSERT .equ   $D9         ; Ctrl+Insert key
KEY_C_DELETE .equ   $DA         ; Ctrl+Delete key
KEY_C_HOME  .equ    $DB         ; Ctrl+Home key
KEY_C_END   .equ    $DC         ; Ctrl+End key
KEY_C_PGUP  .equ    $DD         ; Ctrl+Page up key
KEY_C_PGDN  .equ    $DE         ; Ctrl+Page down key
KEY_UNKNOWN .equ    $FF         ; Unrecognised function key

    .ifdef HIGH_ASCII
    .macro EMITCRLF
        .db     $8D
    .endm
    .else
    .macro EMITCRLF
        .db     $0D, $0A
    .endm
    .endif
