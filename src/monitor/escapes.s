;
; Copyright (C) 2024 Rhys Weatherley
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
; Special key handling for platforms with ANSI escape sequences.
;
    .ifdef ANSI_ESCAPES
ansi_escape:
        pha
        lda     #0
        sta     FKEY
        sta     SCRATCH2
        pla
        cmp     #CHAR_LSQ           ; "ESC [" sequence?
        beq     ansi_escape_sq
        cmp     #CHAR_O             ; "ESC O" sequence?
        beq     ansi_escape_o
ansi_escape_unknown:
        lda     #KEY_UNKNOWN        ; Don't know what function key this is.
ansi_escape_done:
        sta     FKEY
        lda     #KEY_FESC
        rts
ansi_escape_o:                      ; Handle "ESC O" key sequences.
        jsr     wait_escape
        bcc     ansi_escape_unknown
        cmp     #CHAR_2             ; "ESC O 2" for shifted function keys.
        bne     ansi_escape_alpha
        jsr     wait_escape         ; Get the letter after the "2".
        bcc     ansi_escape_unknown
        ora     #$80                ; Add the high bit to the letter.
ansi_escape_alpha:
        stx     SCRATCH2            ; Save X for the caller.
        ldx     FKEY
        cpx     #12                 ; Shift modifier?
        beq     ansi_escape_alpha_shift
        cpx     #15                 ; Ctrl modifier?
        bne     ansi_escape_alpha_find
        ora     #$20
        bne     ansi_escape_alpha_find
ansi_escape_alpha_shift:
        and     #$1F
ansi_escape_alpha_find:
        ldx     #key_defs_alpha_end-key_defs_alpha-2
assi_escape_find_alpha:
        cmp     key_defs_alpha,x
        beq     ansi_escape_found_alpha
        dex
        dex
        bpl     assi_escape_find_alpha
        ldx     SCRATCH2
        jmp     ansi_escape_unknown
ansi_escape_found_alpha:
        lda     key_defs_alpha+1,x
        bpl     ansi_escape_plain   ; High bit is 0 to return a plain character.
        ldx     SCRATCH2
        jmp     ansi_escape_done
ansi_escape_plain:
        ldx     SCRATCH2
        rts
ansi_escape_sq:                     ; Handle "ESC [" key sequences.
        jsr     wait_escape
        bcc     ansi_escape_unknown
        cmp     #CHAR_SEMI
        beq     ansi_escape_semi
        cmp     #CHAR_0             ; Non-digits end the sequence.
        bcc     ansi_escape_sq_end
        cmp     #CHAR_9+1
        bcs     ansi_escape_sq_end
        and     #$0F                ; FKEY = FKEY * 10 + A.
        sta     SCRATCH1
        lda     FKEY
        asl     a
        sta     FKEY
        asl     a
        asl     a
        clc
        adc     FKEY
        clc
        adc     SCRATCH1
        sta     FKEY
        jmp     ansi_escape_sq
ansi_escape_semi:
        inc     SCRATCH2            ; Record the ";" and then ignore it.
        jmp     ansi_escape_sq
ansi_escape_sq_end:
        cmp     #CHAR_TILDE         ; Does the sequence end with a "~"?
        bne     ansi_escape_alpha   ; If not, this is a letter-based key.
        lda     SCRATCH2            ; Did we have a semi-colon?
        bne     ansi_escape_do_semi
        lda     FKEY                ; Get the keycode to resolve.
        stx     FKEY                ; Save X for the caller.
        ldx     #key_defs_numeric_end-key_defs_numeric-2
assi_escape_find_numeric:
        cmp     key_defs_numeric,x
        beq     ansi_escape_found_numeric
        dex
        dex
        bpl     assi_escape_find_numeric
        ldx     FKEY
        jmp     ansi_escape_unknown
ansi_escape_found_numeric:
        lda     key_defs_numeric+1,x
        ldx     FKEY
        jmp     ansi_escape_done
ansi_escape_do_semi:
        lda     FKEY                ; Get the keycode to resolve.
        stx     FKEY                ; Save X for the caller.
        ldx     #key_defs_semi_end-key_defs_semi-2
assi_escape_find_semi:
        cmp     key_defs_semi,x
        beq     ansi_escape_found_semi
        dex
        dex
        bpl     assi_escape_find_semi
        ldx     FKEY
        jmp     ansi_escape_unknown
ansi_escape_found_semi:
        lda     key_defs_semi+1,x
        ldx     FKEY
        jmp     ansi_escape_done
;
; Key defintions for number-based escape sequences.
;
key_defs_numeric:
        .db     1,KEY_HOME          ; ESC [ 1 ~
        .db     2,KEY_INSERT        ; ESC [ 2 ~
        .db     3,KEY_DELETE        ; ESC [ 3 ~
        .db     4,KEY_END           ; ESC [ 4 ~
        .db     5,KEY_PGUP          ; ESC [ 5 ~
        .db     6,KEY_PGDN          ; ESC [ 6 ~
        .db     11,KEY_F1           ; ESC [ 11 ~
        .db     12,KEY_F2           ; ESC [ 12 ~
        .db     13,KEY_F3           ; ESC [ 13 ~
        .db     14,KEY_F4           ; ESC [ 14 ~
        .db     15,KEY_F5           ; ESC [ 15 ~
        .db     16,KEY_F5           ; ESC [ 16 ~ (alternate F5)
        .db     17,KEY_F6           ; ESC [ 17 ~
        .db     18,KEY_F7           ; ESC [ 18 ~
        .db     19,KEY_F8           ; ESC [ 19 ~
        .db     20,KEY_F9           ; ESC [ 20 ~
        .db     21,KEY_F10          ; ESC [ 21 ~
        .db     23,KEY_F11          ; ESC [ 23 ~
        .db     24,KEY_F12          ; ESC [ 24 ~
        .db     25,KEY_F13          ; ESC [ 25 ~
        .db     26,KEY_F14          ; ESC [ 26 ~
        .db     28,KEY_F15          ; ESC [ 28 ~
        .db     29,KEY_F16          ; ESC [ 29 ~
        .db     31,KEY_F17          ; ESC [ 31 ~
        .db     32,KEY_F18          ; ESC [ 32 ~
        .db     33,KEY_F19          ; ESC [ 33 ~
        .db     34,KEY_F20          ; ESC [ 34 ~
key_defs_numeric_end:
;
; Key definitions for numeric escape sequences that include a semi-colon.
;
key_defs_semi:
        .db     12,KEY_S_HOME       ; ESC [ 1 ; 2 ~
        .db     15,KEY_C_HOME       ; ESC [ 1 ; 5 ~
        .db     22,KEY_S_INSERT     ; ESC [ 2 ; 2 ~
        .db     25,KEY_C_INSERT     ; ESC [ 2 ; 5 ~
        .db     32,KEY_S_DELETE     ; ESC [ 3 ; 2 ~
        .db     35,KEY_C_DELETE     ; ESC [ 3 ; 5 ~
        .db     42,KEY_S_END        ; ESC [ 4 ; 2 ~
        .db     45,KEY_C_END        ; ESC [ 4 ; 5 ~
        .db     52,KEY_S_PGUP       ; ESC [ 5 ; 2 ~
        .db     55,KEY_C_PGUP       ; ESC [ 5 ; 5 ~
        .db     62,KEY_S_PGDN       ; ESC [ 6 ; 2 ~
        .db     65,KEY_C_PGDN       ; ESC [ 6 ; 5 ~
        .db     152,KEY_F17         ; Shift-F5:  ESC [ 15 ; 2 ~
        .db     172,KEY_F18         ; Shift-F6:  ESC [ 17 ; 2 ~
        .db     182,KEY_F19         ; Shift-F7:  ESC [ 18 ; 2 ~
        .db     192,KEY_F20         ; Shift-F8:  ESC [ 19 ; 2 ~
        .db     202,KEY_F21         ; Shift-F9:  ESC [ 20 ; 2 ~
        .db     212,KEY_F22         ; Shift-F10: ESC [ 21 ; 2 ~
        .db     232,KEY_F23         ; Shift-F11: ESC [ 23 ; 2 ~
        .db     242,KEY_F24         ; Shift-F12: ESC [ 24 ; 2 ~
key_defs_semi_end:
;
; Key definitions for letter-based escape sequences.
;
key_defs_alpha:
        .db     $41,KEY_UP          ; ESC [ A
        .db     $42,KEY_DOWN        ; ESC [ B
        .db     $43,KEY_RIGHT       ; ESC [ C
        .db     $44,KEY_LEFT        ; ESC [ D
        .db     $45,KEY_MIDDLE      ; ESC [ E
        .db     $46,KEY_END         ; ESC [ F
        .db     $48,KEY_HOME        ; ESC [ H
        .db     $50,KEY_F1          ; ESC [ P or ESC O P
        .db     $51,KEY_F2          ; ESC [ Q or ESC O Q
        .db     $52,KEY_F3          ; ESC [ R or ESC O R
        .db     $53,KEY_F4          ; ESC [ S or ESC O S
        .db     $5A,KEY_BACKTAB     ; ESC [ Z
        .db     $D0,KEY_F13         ; Shift-F1: ESC O 2 P
        .db     $D1,KEY_F14         ; Shift-F2: ESC O 2 Q
        .db     $D2,KEY_F15         ; Shift-F3: ESC O 2 R
        .db     $D3,KEY_F16         ; Shift-F4: ESC O 2 S
        .db     $01,KEY_S_UP        ; ESC [ 1 ; 2 A
        .db     $02,KEY_S_DOWN      ; ESC [ 1 ; 2 B
        .db     $03,KEY_S_RIGHT     ; ESC [ 1 ; 2 C
        .db     $04,KEY_S_LEFT      ; ESC [ 1 ; 2 D
        .db     $06,KEY_S_END       ; ESC [ 1 ; 2 F
        .db     $08,KEY_S_HOME      ; ESC [ 1 ; 2 H
        .db     $61,KEY_C_UP        ; ESC [ 1 ; 5 A
        .db     $62,KEY_C_DOWN      ; ESC [ 1 ; 5 B
        .db     $63,KEY_C_RIGHT     ; ESC [ 1 ; 5 C
        .db     $64,KEY_C_LEFT      ; ESC [ 1 ; 5 D
        .db     $66,KEY_C_END       ; ESC [ 1 ; 5 F
        .db     $68,KEY_C_HOME      ; ESC [ 1 ; 5 H
key_defs_alpha_end:

;
; Output a decimal number 0..255 for an ASCII escape sequence.
;
ansi_out_decimal:
        cmp     #200
        bcc     ansi_out_100
        pha
        lda     #CHAR_2
        jsr     MCOUT1
        pla
        sec
        sbc     #200
        jmp     ansi_out_tens
ansi_out_100:
        cmp     #100
        bcc     ansi_out_tens
        pha
        lda     #CHAR_1
        jsr     MCOUT1
        pla
        sec
        sbc     #100
ansi_out_tens:
        cmp     #10
        bcc     ansi_out_ones
        pha
        lda     #CHAR_0
        sta     SCRATCH1
        pla
ansi_out_tens_loop:
        inc     SCRATCH1
        sec
        sbc     #10
        cmp     #10
        bcs     ansi_out_tens_loop
        pha
        lda     SCRATCH1
        jsr     MCOUT1
        pla
ansi_out_ones:
        ora     #CHAR_0
        jmp     MCOUT1
;
; Move the cursor using an ANSI escape sequence.  Preserves A, X, and Y.
;
ansi_move_cursor:
        pha
        lda     #CHAR_ESC
        jsr     MCOUT1
        lda     #CHAR_LSQ
        jsr     MCOUT1
        lda     CVERT               ; A = CVERT + WNDTOP + 1
        sec
        adc     WNDTOP
        jsr     ansi_out_decimal
        lda     #CHAR_SEMI
        jsr     MCOUT1
        lda     CHORZ               ; A = CHORZ + WNDLFT + 1
        sec
        adc     WNDLFT
        jsr     ansi_out_decimal
        lda     #CHAR_H
        jsr     MCOUT1
        pla
        rts
;
; Perform the TTY operation in X.  Preserves Y.  Destroys A, P, and X.
;
        .include tty.s
tty_operation:
        cpx     #TTY_OP_COUNT
        bcs     tty_operation_end
        lda     tty_operations,x
        tax
        lda     #CHAR_ESC
        jsr     MCOUT1
        lda     #CHAR_LSQ
        jsr     MCOUT1
tty_operation_out:
        lda     tty_operation_escapes,x
        beq     tty_operation_end
        jsr     MCOUT1
        inx
        bne     tty_operation_out
tty_operation_end:
        rts
tty_operation_escapes:
tty_op_reset_colors:
        .db     CHAR_M_L, 0
tty_op_clear_screen:
        .db     CHAR_H, CHAR_ESC, CHAR_LSQ
tty_op_clear_eos:
        .db     CHAR_J, 0
tty_op_clear_eol:
        .db     CHAR_K, 0
tty_op_home:
        .db     CHAR_H, 0
tty_op_move_left:
        .db     CHAR_D, 0
tty_op_move_right:
        .db     CHAR_C, 0
tty_op_move_up:
        .db     CHAR_A, 0
tty_op_move_down:
        .db     CHAR_B, 0
tty_op_delete_char:
        .db     CHAR_P, 0
tty_op_insert_char:
        .db     CHAR_AT, 0
tty_op_delete_line:
        .db     CHAR_M, 0
tty_op_insert_line:
        .db     CHAR_L, 0
tty_operations:
        .db     tty_op_reset_colors-tty_operation_escapes
        .db     tty_op_clear_screen-tty_operation_escapes
        .db     tty_op_clear_eos-tty_operation_escapes
        .db     tty_op_clear_eol-tty_operation_escapes
        .db     tty_op_home-tty_operation_escapes
        .db     tty_op_move_left-tty_operation_escapes
        .db     tty_op_move_right-tty_operation_escapes
        .db     tty_op_move_up-tty_operation_escapes
        .db     tty_op_move_down-tty_operation_escapes
        .db     tty_op_delete_char-tty_operation_escapes
        .db     tty_op_insert_char-tty_operation_escapes
        .db     tty_op_delete_line-tty_operation_escapes
        .db     tty_op_insert_line-tty_operation_escapes

    .endif ; ANSI_ESCAPES

    .ifdef EATER
    .if SYSCLK > 1000
;
; Serial output delay for clock speeds above 1MHz.
;
serial_tx_wait:
    .if SYSCLK > 15000
        nop
        nop
        nop
    .endif
    .if SYSCLK > 14000
        nop
        nop
    .endif
    .if SYSCLK > 13000
        nop
        nop
        nop
    .endif
    .if SYSCLK > 12000
        nop
        nop
    .endif
    .if SYSCLK > 11000
        nop
        nop
        nop
    .endif
    .if SYSCLK > 10000
        nop
        nop
    .endif
    .if SYSCLK > 9000
        nop
        nop
        nop
    .endif
    .if SYSCLK > 8000
        nop
        nop
    .endif
    .if SYSCLK > 7000
        nop
        nop
        nop
    .endif
    .if SYSCLK > 6000
        nop
        nop
    .endif
    .if SYSCLK > 5000
        nop
        nop
        nop
    .endif
    .if SYSCLK > 4000
        nop
        nop
    .endif
    .if SYSCLK > 3000
        nop
        nop
        nop
    .endif
    .if SYSCLK > 2000
        nop
        nop
    .endif
        nop
        nop
        nop
        dex
        bne     serial_tx_wait
        rts

    .endif ; SYSCLK > 1000
    .endif ; EATER
