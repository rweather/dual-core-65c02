; Generated automatically from instructions.txt.

; Opcode modes (bits 0..4) and instruction lengths (bits 6..7).
OP_ill       .equ 0x40
OP_imp       .equ 0x41
OP_imm       .equ 0x82
OP_abs       .equ 0xC3
OP_abs_X     .equ 0xC4
OP_abs_Y     .equ 0xC5
OP_X_ind     .equ 0x86
OP_ind_Y     .equ 0x87
OP_zpg       .equ 0x88
OP_zpg_X     .equ 0x89
OP_zpg_Y     .equ 0x8A
OP_rel       .equ 0x8B
OP_ind       .equ 0xCC
OP_jsr       .equ 0xCD
OP_jmp       .equ 0xCE
OP_rts       .equ 0x4F
OP_rti       .equ 0x50

; Identifiers for special directives at the end of the OPNAMES table.
OP_DB        .equ 168
OP_DW        .equ 171
OP_ORG       .equ 174

    .ifndef OPMODES_ONLY

; Convert an opcode number into an index into the name table.
OPNAMEIDX
    .db   0 ; BRK
    .db   3 ; ORA X,ind
    .db 168
    .db 168
    .db 168
    .db   3 ; ORA zpg
    .db   6 ; ASL zpg
    .db 168
    .db   9 ; PHP
    .db   3 ; ORA #
    .db   6 ; ASL A
    .db 168
    .db 168
    .db   3 ; ORA abs
    .db   6 ; ASL abs
    .db 168
    .db  12 ; BPL rel
    .db   3 ; ORA ind,Y
    .db 168
    .db 168
    .db 168
    .db   3 ; ORA zpg,X
    .db   6 ; ASL zpg,X
    .db 168
    .db  15 ; CLC
    .db   3 ; ORA abs,Y
    .db 168
    .db 168
    .db 168
    .db   3 ; ORA abs,X
    .db   6 ; ASL abs,X
    .db 168
    .db  18 ; JSR jsr
    .db  21 ; AND X,ind
    .db 168
    .db 168
    .db  24 ; BIT zpg
    .db  21 ; AND zpg
    .db  27 ; ROL zpg
    .db 168
    .db  30 ; PLP
    .db  21 ; AND #
    .db  27 ; ROL A
    .db 168
    .db  24 ; BIT abs
    .db  21 ; AND abs
    .db  27 ; ROL abs
    .db 168
    .db  33 ; BMI rel
    .db  21 ; AND ind,Y
    .db 168
    .db 168
    .db 168
    .db  21 ; AND zpg,X
    .db  27 ; ROL zpg,X
    .db 168
    .db  36 ; SEC
    .db  21 ; AND abs,Y
    .db 168
    .db 168
    .db 168
    .db  21 ; AND abs,X
    .db  27 ; ROL abs,X
    .db 168
    .db  39 ; RTI rti
    .db  42 ; EOR X,ind
    .db 168
    .db 168
    .db 168
    .db  42 ; EOR zpg
    .db  45 ; LSR zpg
    .db 168
    .db  48 ; PHA
    .db  42 ; EOR #
    .db  45 ; LSR A
    .db 168
    .db  51 ; JMP jmp
    .db  42 ; EOR abs
    .db  45 ; LSR abs
    .db 168
    .db  54 ; BVC rel
    .db  42 ; EOR ind,Y
    .db 168
    .db 168
    .db 168
    .db  42 ; EOR zpg,X
    .db  45 ; LSR zpg,X
    .db 168
    .db  57 ; CLI
    .db  42 ; EOR abs,Y
    .db 168
    .db 168
    .db 168
    .db  42 ; EOR abs,X
    .db  45 ; LSR abs,X
    .db 168
    .db  60 ; RTS rts
    .db  63 ; ADC X,ind
    .db 168
    .db 168
    .db 168
    .db  63 ; ADC zpg
    .db  66 ; ROR zpg
    .db 168
    .db  69 ; PLA
    .db  63 ; ADC #
    .db  66 ; ROR A
    .db 168
    .db  51 ; JMP ind
    .db  63 ; ADC abs
    .db  66 ; ROR abs
    .db 168
    .db  72 ; BVS rel
    .db  63 ; ADC ind,Y
    .db 168
    .db 168
    .db 168
    .db  63 ; ADC zpg,X
    .db  66 ; ROR zpg,X
    .db 168
    .db  75 ; SEI
    .db  63 ; ADC abs,Y
    .db 168
    .db 168
    .db 168
    .db  63 ; ADC abs,X
    .db  66 ; ROR abs,X
    .db 168
    .db 168
    .db  78 ; STA X,ind
    .db 168
    .db 168
    .db  81 ; STY zpg
    .db  78 ; STA zpg
    .db  84 ; STX zpg
    .db 168
    .db  87 ; DEY
    .db 168
    .db  90 ; TXA
    .db 168
    .db  81 ; STY abs
    .db  78 ; STA abs
    .db  84 ; STX abs
    .db 168
    .db  93 ; BCC rel
    .db  78 ; STA ind,Y
    .db 168
    .db 168
    .db  81 ; STY zpg,X
    .db  78 ; STA zpg,X
    .db  84 ; STX zpg,Y
    .db 168
    .db  96 ; TYA
    .db  78 ; STA abs,Y
    .db  99 ; TXS
    .db 168
    .db 168
    .db  78 ; STA abs,X
    .db 168
    .db 168
    .db 102 ; LDY imm
    .db 105 ; LDA X,ind
    .db 108 ; LDX imm
    .db 168
    .db 102 ; LDY zpg
    .db 105 ; LDA zpg
    .db 108 ; LDX zpg
    .db 168
    .db 111 ; TAY
    .db 105 ; LDA imm
    .db 114 ; TAX
    .db 168
    .db 102 ; LDY abs
    .db 105 ; LDA abs
    .db 108 ; LDX abs
    .db 168
    .db 117 ; BCS rel
    .db 105 ; LDA ind,Y
    .db 168
    .db 168
    .db 102 ; LDY zpg,X
    .db 105 ; LDA zpg,X
    .db 108 ; LDX zpg,Y
    .db 168
    .db 120 ; CLV
    .db 105 ; LDA abs,Y
    .db 123 ; TSX
    .db 168
    .db 102 ; LDY abs,X
    .db 105 ; LDA abs,X
    .db 108 ; LDX abs,Y
    .db 168
    .db 126 ; CPY imm
    .db 129 ; CMP X,ind
    .db 168
    .db 168
    .db 126 ; CPY zpg
    .db 129 ; CMP zpg
    .db 132 ; DEC zpg
    .db 168
    .db 135 ; INY
    .db 129 ; CMP imm
    .db 138 ; DEX
    .db 168
    .db 126 ; CPY abs
    .db 129 ; CMP abs
    .db 132 ; DEC abs
    .db 168
    .db 141 ; BNE rel
    .db 129 ; CMP ind,Y
    .db 168
    .db 168
    .db 168
    .db 129 ; CMP zpg,X
    .db 132 ; DEC zpg,X
    .db 168
    .db 144 ; CLD
    .db 129 ; CMP abs,Y
    .db 168
    .db 168
    .db 168
    .db 129 ; CMP abs,X
    .db 132 ; DEC abs,Y
    .db 168
    .db 147 ; CPX imm
    .db 150 ; SBC X,ind
    .db 168
    .db 168
    .db 147 ; CPX zpg
    .db 150 ; SBC zpg
    .db 153 ; INC zpg
    .db 168
    .db 156 ; INX
    .db 150 ; SBC imm
    .db 159 ; NOP
    .db 168
    .db 147 ; CPX abs
    .db 150 ; SBC abs
    .db 153 ; INC abs
    .db 168
    .db 162 ; BEQ rel
    .db 150 ; SBC ind,Y
    .db 168
    .db 168
    .db 168
    .db 150 ; SBC zpg,X
    .db 153 ; INC zpg,X
    .db 168
    .db 165 ; SED
    .db 150 ; SBC abs,Y
    .db 168
    .db 168
    .db 168
    .db 150 ; SBC abs,X
    .db 153 ; INC abs,Y
    .db 168

; List of all opcode names.
OPNAMES
    .db $62, $72, $6B ; "brk"
    .db $6F, $72, $61 ; "ora"
    .db $61, $73, $6C ; "asl"
    .db $70, $68, $70 ; "php"
    .db $62, $70, $6C ; "bpl"
    .db $63, $6C, $63 ; "clc"
    .db $6A, $73, $72 ; "jsr"
    .db $61, $6E, $64 ; "and"
    .db $62, $69, $74 ; "bit"
    .db $72, $6F, $6C ; "rol"
    .db $70, $6C, $70 ; "plp"
    .db $62, $6D, $69 ; "bmi"
    .db $73, $65, $63 ; "sec"
    .db $72, $74, $69 ; "rti"
    .db $65, $6F, $72 ; "eor"
    .db $6C, $73, $72 ; "lsr"
    .db $70, $68, $61 ; "pha"
    .db $6A, $6D, $70 ; "jmp"
    .db $62, $76, $63 ; "bvc"
    .db $63, $6C, $69 ; "cli"
    .db $72, $74, $73 ; "rts"
    .db $61, $64, $63 ; "adc"
    .db $72, $6F, $72 ; "ror"
    .db $70, $6C, $61 ; "pla"
    .db $62, $76, $73 ; "bvs"
    .db $73, $65, $69 ; "sei"
    .db $73, $74, $61 ; "sta"
    .db $73, $74, $79 ; "sty"
    .db $73, $74, $78 ; "stx"
    .db $64, $65, $79 ; "dey"
    .db $74, $78, $61 ; "txa"
    .db $62, $63, $63 ; "bcc"
    .db $74, $79, $61 ; "tya"
    .db $74, $78, $73 ; "txs"
    .db $6C, $64, $79 ; "ldy"
    .db $6C, $64, $61 ; "lda"
    .db $6C, $64, $78 ; "ldx"
    .db $74, $61, $79 ; "tay"
    .db $74, $61, $78 ; "tax"
    .db $62, $63, $73 ; "bcs"
    .db $63, $6C, $76 ; "clv"
    .db $74, $73, $78 ; "tsx"
    .db $63, $70, $79 ; "cpy"
    .db $63, $6D, $70 ; "cmp"
    .db $64, $65, $63 ; "dec"
    .db $69, $6E, $79 ; "iny"
    .db $64, $65, $78 ; "dex"
    .db $62, $6E, $65 ; "bne"
    .db $63, $6C, $64 ; "cld"
    .db $63, $70, $78 ; "cpx"
    .db $73, $62, $63 ; "sbc"
    .db $69, $6E, $63 ; "inc"
    .db $69, $6E, $78 ; "inx"
    .db $6E, $6F, $70 ; "nop"
    .db $62, $65, $71 ; "beq"
    .db $73, $65, $64 ; "sed"
    .db $64, $62, $20 ; "db "
    .db $64, $77, $20 ; "dw "
    .db $6F, $72, $67 ; "org"

    .endif

; Modes and instruction lengths for all opcodes.
OPMODES
    .db OP_imp   ; BRK
    .db OP_X_ind ; ORA X,ind
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; ORA zpg
    .db OP_zpg   ; ASL zpg
    .db OP_ill
    .db OP_imp   ; PHP
    .db OP_imm   ; ORA #
    .db OP_imp   ; ASL A
    .db OP_ill
    .db OP_ill
    .db OP_abs   ; ORA abs
    .db OP_abs   ; ASL abs
    .db OP_ill
    .db OP_rel   ; BPL rel
    .db OP_ind_Y ; ORA ind,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; ORA zpg,X
    .db OP_zpg_X ; ASL zpg,X
    .db OP_ill
    .db OP_imp   ; CLC
    .db OP_abs_Y ; ORA abs,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_abs_X ; ORA abs,X
    .db OP_abs_X ; ASL abs,X
    .db OP_ill
    .db OP_jsr   ; JSR jsr
    .db OP_X_ind ; AND X,ind
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; BIT zpg
    .db OP_zpg   ; AND zpg
    .db OP_zpg   ; ROL zpg
    .db OP_ill
    .db OP_imp   ; PLP
    .db OP_imm   ; AND #
    .db OP_imp   ; ROL A
    .db OP_ill
    .db OP_abs   ; BIT abs
    .db OP_abs   ; AND abs
    .db OP_abs   ; ROL abs
    .db OP_ill
    .db OP_rel   ; BMI rel
    .db OP_ind_Y ; AND ind,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; AND zpg,X
    .db OP_zpg_X ; ROL zpg,X
    .db OP_ill
    .db OP_imp   ; SEC
    .db OP_abs_Y ; AND abs,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_abs_X ; AND abs,X
    .db OP_abs_X ; ROL abs,X
    .db OP_ill
    .db OP_rti   ; RTI rti
    .db OP_X_ind ; EOR X,ind
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; EOR zpg
    .db OP_zpg   ; LSR zpg
    .db OP_ill
    .db OP_imp   ; PHA
    .db OP_imm   ; EOR #
    .db OP_imp   ; LSR A
    .db OP_ill
    .db OP_jmp   ; JMP jmp
    .db OP_abs   ; EOR abs
    .db OP_abs   ; LSR abs
    .db OP_ill
    .db OP_rel   ; BVC rel
    .db OP_ind_Y ; EOR ind,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; EOR zpg,X
    .db OP_zpg_X ; LSR zpg,X
    .db OP_ill
    .db OP_imp   ; CLI
    .db OP_abs_Y ; EOR abs,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_abs_X ; EOR abs,X
    .db OP_abs_X ; LSR abs,X
    .db OP_ill
    .db OP_rts   ; RTS rts
    .db OP_X_ind ; ADC X,ind
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; ADC zpg
    .db OP_zpg   ; ROR zpg
    .db OP_ill
    .db OP_imp   ; PLA
    .db OP_imm   ; ADC #
    .db OP_imp   ; ROR A
    .db OP_ill
    .db OP_ind   ; JMP ind
    .db OP_abs   ; ADC abs
    .db OP_abs   ; ROR abs
    .db OP_ill
    .db OP_rel   ; BVS rel
    .db OP_ind_Y ; ADC ind,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; ADC zpg,X
    .db OP_zpg_X ; ROR zpg,X
    .db OP_ill
    .db OP_imp   ; SEI
    .db OP_abs_Y ; ADC abs,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_abs_X ; ADC abs,X
    .db OP_abs_X ; ROR abs,X
    .db OP_ill
    .db OP_ill
    .db OP_X_ind ; STA X,ind
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; STY zpg
    .db OP_zpg   ; STA zpg
    .db OP_zpg   ; STX zpg
    .db OP_ill
    .db OP_imp   ; DEY
    .db OP_ill
    .db OP_imp   ; TXA
    .db OP_ill
    .db OP_abs   ; STY abs
    .db OP_abs   ; STA abs
    .db OP_abs   ; STX abs
    .db OP_ill
    .db OP_rel   ; BCC rel
    .db OP_ind_Y ; STA ind,Y
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; STY zpg,X
    .db OP_zpg_X ; STA zpg,X
    .db OP_zpg_Y ; STX zpg,Y
    .db OP_ill
    .db OP_imp   ; TYA
    .db OP_abs_Y ; STA abs,Y
    .db OP_imp   ; TXS
    .db OP_ill
    .db OP_ill
    .db OP_abs_X ; STA abs,X
    .db OP_ill
    .db OP_ill
    .db OP_imm   ; LDY imm
    .db OP_X_ind ; LDA X,ind
    .db OP_imm   ; LDX imm
    .db OP_ill
    .db OP_zpg   ; LDY zpg
    .db OP_zpg   ; LDA zpg
    .db OP_zpg   ; LDX zpg
    .db OP_ill
    .db OP_imp   ; TAY
    .db OP_imm   ; LDA imm
    .db OP_imp   ; TAX
    .db OP_ill
    .db OP_abs   ; LDY abs
    .db OP_abs   ; LDA abs
    .db OP_abs   ; LDX abs
    .db OP_ill
    .db OP_rel   ; BCS rel
    .db OP_ind_Y ; LDA ind,Y
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; LDY zpg,X
    .db OP_zpg_X ; LDA zpg,X
    .db OP_zpg_Y ; LDX zpg,Y
    .db OP_ill
    .db OP_imp   ; CLV
    .db OP_abs_Y ; LDA abs,Y
    .db OP_imp   ; TSX
    .db OP_ill
    .db OP_abs_X ; LDY abs,X
    .db OP_abs_X ; LDA abs,X
    .db OP_abs_Y ; LDX abs,Y
    .db OP_ill
    .db OP_imm   ; CPY imm
    .db OP_X_ind ; CMP X,ind
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; CPY zpg
    .db OP_zpg   ; CMP zpg
    .db OP_zpg   ; DEC zpg
    .db OP_ill
    .db OP_imp   ; INY
    .db OP_imm   ; CMP imm
    .db OP_imp   ; DEX
    .db OP_ill
    .db OP_abs   ; CPY abs
    .db OP_abs   ; CMP abs
    .db OP_abs   ; DEC abs
    .db OP_ill
    .db OP_rel   ; BNE rel
    .db OP_ind_Y ; CMP ind,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; CMP zpg,X
    .db OP_zpg_X ; DEC zpg,X
    .db OP_ill
    .db OP_imp   ; CLD
    .db OP_abs_Y ; CMP abs,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_abs_X ; CMP abs,X
    .db OP_abs_Y ; DEC abs,Y
    .db OP_ill
    .db OP_imm   ; CPX imm
    .db OP_X_ind ; SBC X,ind
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; CPX zpg
    .db OP_zpg   ; SBC zpg
    .db OP_zpg   ; INC zpg
    .db OP_ill
    .db OP_imp   ; INX
    .db OP_imm   ; SBC imm
    .db OP_imp   ; NOP
    .db OP_ill
    .db OP_abs   ; CPX abs
    .db OP_abs   ; SBC abs
    .db OP_abs   ; INC abs
    .db OP_ill
    .db OP_rel   ; BEQ rel
    .db OP_ind_Y ; SBC ind,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; SBC zpg,X
    .db OP_zpg_X ; INC zpg,X
    .db OP_ill
    .db OP_imp   ; SED
    .db OP_abs_Y ; SBC abs,Y
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_abs_X ; SBC abs,X
    .db OP_abs_Y ; INC abs,Y
    .db OP_ill
