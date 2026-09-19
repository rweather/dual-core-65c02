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
OP_ind_zpg   .equ 0x91
OP_ind_abs_X .equ 0xD2
OP_bit_zpg   .equ 0x93
OP_zpg_rel   .equ 0xD4

; Identifiers for special directives at the end of the OPNAMES table.
OP_DB        .equ 210
OP_DW        .equ 213
OP_ORG       .equ 216

    .ifndef OPMODES_ONLY

; Convert an opcode number into an index into the name table.
OPNAMEIDX
    .db   0 ; BRK
    .db   3 ; ORA X,ind
    .db 210
    .db 210
    .db   6 ; TSB zpg
    .db   3 ; ORA zpg
    .db   9 ; ASL zpg
    .db  12 ; RMB bit,zpg
    .db  15 ; PHP
    .db   3 ; ORA #
    .db   9 ; ASL A
    .db 210
    .db   6 ; TSB abs
    .db   3 ; ORA abs
    .db   9 ; ASL abs
    .db  18 ; BBR zpg,rel
    .db  21 ; BPL rel
    .db   3 ; ORA ind,Y
    .db   3 ; ORA ind,zpg
    .db 210
    .db  24 ; TRB zpg
    .db   3 ; ORA zpg,X
    .db   9 ; ASL zpg,X
    .db  12 ; RMB bit,zpg
    .db  27 ; CLC
    .db   3 ; ORA abs,Y
    .db  30 ; INC A
    .db 210
    .db  24 ; TRB abs
    .db   3 ; ORA abs,X
    .db   9 ; ASL abs,X
    .db  18 ; BBR zpg,rel
    .db  33 ; JSR jsr
    .db  36 ; AND X,ind
    .db 210
    .db 210
    .db  39 ; BIT zpg
    .db  36 ; AND zpg
    .db  42 ; ROL zpg
    .db  12 ; RMB bit,zpg
    .db  45 ; PLP
    .db  36 ; AND #
    .db  42 ; ROL A
    .db 210
    .db  39 ; BIT abs
    .db  36 ; AND abs
    .db  42 ; ROL abs
    .db  18 ; BBR zpg,rel
    .db  48 ; BMI rel
    .db  36 ; AND ind,Y
    .db  36 ; AND ind,zpg
    .db 210
    .db  39 ; BIT zpg,X
    .db  36 ; AND zpg,X
    .db  42 ; ROL zpg,X
    .db  12 ; RMB bit,zpg
    .db  51 ; SEC
    .db  36 ; AND abs,Y
    .db  54 ; DEC A
    .db 210
    .db  39 ; BIT abs,X
    .db  36 ; AND abs,X
    .db  42 ; ROL abs,X
    .db  18 ; BBR zpg,rel
    .db  57 ; RTI rti
    .db  60 ; EOR X,ind
    .db 210
    .db 210
    .db 210
    .db  60 ; EOR zpg
    .db  63 ; LSR zpg
    .db  12 ; RMB bit,zpg
    .db  66 ; PHA
    .db  60 ; EOR #
    .db  63 ; LSR A
    .db 210
    .db  69 ; JMP jmp
    .db  60 ; EOR abs
    .db  63 ; LSR abs
    .db  18 ; BBR zpg,rel
    .db  72 ; BVC rel
    .db  60 ; EOR ind,Y
    .db  60 ; EOR ind,zpg
    .db 210
    .db 210
    .db  60 ; EOR zpg,X
    .db  63 ; LSR zpg,X
    .db  12 ; RMB bit,zpg
    .db  75 ; CLI
    .db  60 ; EOR abs,Y
    .db  78 ; PHY
    .db 210
    .db 210
    .db  60 ; EOR abs,X
    .db  63 ; LSR abs,X
    .db  18 ; BBR zpg,rel
    .db  81 ; RTS rts
    .db  84 ; ADC X,ind
    .db 210
    .db 210
    .db  87 ; STZ zpg
    .db  84 ; ADC zpg
    .db  90 ; ROR zpg
    .db  12 ; RMB bit,zpg
    .db  93 ; PLA
    .db  84 ; ADC #
    .db  90 ; ROR A
    .db 210
    .db  69 ; JMP ind
    .db  84 ; ADC abs
    .db  90 ; ROR abs
    .db  18 ; BBR zpg,rel
    .db  96 ; BVS rel
    .db  84 ; ADC ind,Y
    .db  84 ; ADC ind,zpg
    .db 210
    .db  87 ; STZ zpg,X
    .db  84 ; ADC zpg,X
    .db  90 ; ROR zpg,X
    .db  12 ; RMB bit,zpg
    .db  99 ; SEI
    .db  84 ; ADC abs,Y
    .db 102 ; PLY
    .db 210
    .db  69 ; JMP ind,abs,X
    .db  84 ; ADC abs,X
    .db  90 ; ROR abs,X
    .db  18 ; BBR zpg,rel
    .db 105 ; BRA rel
    .db 108 ; STA X,ind
    .db 210
    .db 210
    .db 111 ; STY zpg
    .db 108 ; STA zpg
    .db 114 ; STX zpg
    .db 117 ; SMB bit,zpg
    .db 120 ; DEY
    .db  39 ; BIT imm
    .db 123 ; TXA
    .db 210
    .db 111 ; STY abs
    .db 108 ; STA abs
    .db 114 ; STX abs
    .db 126 ; BBS zpg,rel
    .db 129 ; BCC rel
    .db 108 ; STA ind,Y
    .db 108 ; STA ind,zpg
    .db 210
    .db 111 ; STY zpg,X
    .db 108 ; STA zpg,X
    .db 114 ; STX zpg,Y
    .db 117 ; SMB bit,zpg
    .db 132 ; TYA
    .db 108 ; STA abs,Y
    .db 135 ; TXS
    .db 210
    .db  87 ; STZ abs
    .db 108 ; STA abs,X
    .db  87 ; STZ abs,X
    .db 126 ; BBS zpg,rel
    .db 138 ; LDY imm
    .db 141 ; LDA X,ind
    .db 144 ; LDX imm
    .db 210
    .db 138 ; LDY zpg
    .db 141 ; LDA zpg
    .db 144 ; LDX zpg
    .db 117 ; SMB bit,zpg
    .db 147 ; TAY
    .db 141 ; LDA imm
    .db 150 ; TAX
    .db 210
    .db 138 ; LDY abs
    .db 141 ; LDA abs
    .db 144 ; LDX abs
    .db 126 ; BBS zpg,rel
    .db 153 ; BCS rel
    .db 141 ; LDA ind,Y
    .db 141 ; LDA ind,zpg
    .db 210
    .db 138 ; LDY zpg,X
    .db 141 ; LDA zpg,X
    .db 144 ; LDX zpg,Y
    .db 117 ; SMB bit,zpg
    .db 156 ; CLV
    .db 141 ; LDA abs,Y
    .db 159 ; TSX
    .db 210
    .db 138 ; LDY abs,X
    .db 141 ; LDA abs,X
    .db 144 ; LDX abs,Y
    .db 126 ; BBS zpg,rel
    .db 162 ; CPY imm
    .db 165 ; CMP X,ind
    .db 210
    .db 210
    .db 162 ; CPY zpg
    .db 165 ; CMP zpg
    .db  54 ; DEC zpg
    .db 117 ; SMB bit,zpg
    .db 168 ; INY
    .db 165 ; CMP imm
    .db 171 ; DEX
    .db 174 ; WAI
    .db 162 ; CPY abs
    .db 165 ; CMP abs
    .db  54 ; DEC abs
    .db 126 ; BBS zpg,rel
    .db 177 ; BNE rel
    .db 165 ; CMP ind,Y
    .db 165 ; CMP ind,zpg
    .db 210
    .db 210
    .db 165 ; CMP zpg,X
    .db  54 ; DEC zpg,X
    .db 117 ; SMB bit,zpg
    .db 180 ; CLD
    .db 165 ; CMP abs,Y
    .db 183 ; PHX
    .db 186 ; STP
    .db 210
    .db 165 ; CMP abs,X
    .db  54 ; DEC abs,Y
    .db 126 ; BBS zpg,rel
    .db 189 ; CPX imm
    .db 192 ; SBC X,ind
    .db 210
    .db 210
    .db 189 ; CPX zpg
    .db 192 ; SBC zpg
    .db  30 ; INC zpg
    .db 117 ; SMB bit,zpg
    .db 195 ; INX
    .db 192 ; SBC imm
    .db 198 ; NOP
    .db 210
    .db 189 ; CPX abs
    .db 192 ; SBC abs
    .db  30 ; INC abs
    .db 126 ; BBS zpg,rel
    .db 201 ; BEQ rel
    .db 192 ; SBC ind,Y
    .db 192 ; SBC ind,zpg
    .db 210
    .db 210
    .db 192 ; SBC zpg,X
    .db  30 ; INC zpg,X
    .db 117 ; SMB bit,zpg
    .db 204 ; SED
    .db 192 ; SBC abs,Y
    .db 207 ; PLX
    .db 210
    .db 210
    .db 192 ; SBC abs,X
    .db  30 ; INC abs,Y
    .db 126 ; BBS zpg,rel

; List of all opcode names.
OPNAMES
    .db $62, $72, $6B ; "brk"
    .db $6F, $72, $61 ; "ora"
    .db $74, $73, $62 ; "tsb"
    .db $61, $73, $6C ; "asl"
    .db $72, $6D, $62 ; "rmb"
    .db $70, $68, $70 ; "php"
    .db $62, $62, $72 ; "bbr"
    .db $62, $70, $6C ; "bpl"
    .db $74, $72, $62 ; "trb"
    .db $63, $6C, $63 ; "clc"
    .db $69, $6E, $63 ; "inc"
    .db $6A, $73, $72 ; "jsr"
    .db $61, $6E, $64 ; "and"
    .db $62, $69, $74 ; "bit"
    .db $72, $6F, $6C ; "rol"
    .db $70, $6C, $70 ; "plp"
    .db $62, $6D, $69 ; "bmi"
    .db $73, $65, $63 ; "sec"
    .db $64, $65, $63 ; "dec"
    .db $72, $74, $69 ; "rti"
    .db $65, $6F, $72 ; "eor"
    .db $6C, $73, $72 ; "lsr"
    .db $70, $68, $61 ; "pha"
    .db $6A, $6D, $70 ; "jmp"
    .db $62, $76, $63 ; "bvc"
    .db $63, $6C, $69 ; "cli"
    .db $70, $68, $79 ; "phy"
    .db $72, $74, $73 ; "rts"
    .db $61, $64, $63 ; "adc"
    .db $73, $74, $7A ; "stz"
    .db $72, $6F, $72 ; "ror"
    .db $70, $6C, $61 ; "pla"
    .db $62, $76, $73 ; "bvs"
    .db $73, $65, $69 ; "sei"
    .db $70, $6C, $79 ; "ply"
    .db $62, $72, $61 ; "bra"
    .db $73, $74, $61 ; "sta"
    .db $73, $74, $79 ; "sty"
    .db $73, $74, $78 ; "stx"
    .db $73, $6D, $62 ; "smb"
    .db $64, $65, $79 ; "dey"
    .db $74, $78, $61 ; "txa"
    .db $62, $62, $73 ; "bbs"
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
    .db $69, $6E, $79 ; "iny"
    .db $64, $65, $78 ; "dex"
    .db $77, $61, $69 ; "wai"
    .db $62, $6E, $65 ; "bne"
    .db $63, $6C, $64 ; "cld"
    .db $70, $68, $78 ; "phx"
    .db $73, $74, $70 ; "stp"
    .db $63, $70, $78 ; "cpx"
    .db $73, $62, $63 ; "sbc"
    .db $69, $6E, $78 ; "inx"
    .db $6E, $6F, $70 ; "nop"
    .db $62, $65, $71 ; "beq"
    .db $73, $65, $64 ; "sed"
    .db $70, $6C, $78 ; "plx"
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
    .db OP_zpg   ; TSB zpg
    .db OP_zpg   ; ORA zpg
    .db OP_zpg   ; ASL zpg
    .db OP_bit_zpg ; RMB bit,zpg
    .db OP_imp   ; PHP
    .db OP_imm   ; ORA #
    .db OP_imp   ; ASL A
    .db OP_ill
    .db OP_abs   ; TSB abs
    .db OP_abs   ; ORA abs
    .db OP_abs   ; ASL abs
    .db OP_zpg_rel ; BBR zpg,rel
    .db OP_rel   ; BPL rel
    .db OP_ind_Y ; ORA ind,Y
    .db OP_ind_zpg ; ORA ind,zpg
    .db OP_ill
    .db OP_zpg   ; TRB zpg
    .db OP_zpg_X ; ORA zpg,X
    .db OP_zpg_X ; ASL zpg,X
    .db OP_bit_zpg ; RMB bit,zpg
    .db OP_imp   ; CLC
    .db OP_abs_Y ; ORA abs,Y
    .db OP_imp   ; INC A
    .db OP_ill
    .db OP_abs   ; TRB abs
    .db OP_abs_X ; ORA abs,X
    .db OP_abs_X ; ASL abs,X
    .db OP_zpg_rel ; BBR zpg,rel
    .db OP_jsr   ; JSR jsr
    .db OP_X_ind ; AND X,ind
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; BIT zpg
    .db OP_zpg   ; AND zpg
    .db OP_zpg   ; ROL zpg
    .db OP_bit_zpg ; RMB bit,zpg
    .db OP_imp   ; PLP
    .db OP_imm   ; AND #
    .db OP_imp   ; ROL A
    .db OP_ill
    .db OP_abs   ; BIT abs
    .db OP_abs   ; AND abs
    .db OP_abs   ; ROL abs
    .db OP_zpg_rel ; BBR zpg,rel
    .db OP_rel   ; BMI rel
    .db OP_ind_Y ; AND ind,Y
    .db OP_ind_zpg ; AND ind,zpg
    .db OP_ill
    .db OP_zpg_X ; BIT zpg,X
    .db OP_zpg_X ; AND zpg,X
    .db OP_zpg_X ; ROL zpg,X
    .db OP_bit_zpg ; RMB bit,zpg
    .db OP_imp   ; SEC
    .db OP_abs_Y ; AND abs,Y
    .db OP_imp   ; DEC A
    .db OP_ill
    .db OP_abs_X ; BIT abs,X
    .db OP_abs_X ; AND abs,X
    .db OP_abs_X ; ROL abs,X
    .db OP_zpg_rel ; BBR zpg,rel
    .db OP_rti   ; RTI rti
    .db OP_X_ind ; EOR X,ind
    .db OP_ill
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; EOR zpg
    .db OP_zpg   ; LSR zpg
    .db OP_bit_zpg ; RMB bit,zpg
    .db OP_imp   ; PHA
    .db OP_imm   ; EOR #
    .db OP_imp   ; LSR A
    .db OP_ill
    .db OP_jmp   ; JMP jmp
    .db OP_abs   ; EOR abs
    .db OP_abs   ; LSR abs
    .db OP_zpg_rel ; BBR zpg,rel
    .db OP_rel   ; BVC rel
    .db OP_ind_Y ; EOR ind,Y
    .db OP_ind_zpg ; EOR ind,zpg
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; EOR zpg,X
    .db OP_zpg_X ; LSR zpg,X
    .db OP_bit_zpg ; RMB bit,zpg
    .db OP_imp   ; CLI
    .db OP_abs_Y ; EOR abs,Y
    .db OP_imp   ; PHY
    .db OP_ill
    .db OP_ill
    .db OP_abs_X ; EOR abs,X
    .db OP_abs_X ; LSR abs,X
    .db OP_zpg_rel ; BBR zpg,rel
    .db OP_rts   ; RTS rts
    .db OP_X_ind ; ADC X,ind
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; STZ zpg
    .db OP_zpg   ; ADC zpg
    .db OP_zpg   ; ROR zpg
    .db OP_bit_zpg ; RMB bit,zpg
    .db OP_imp   ; PLA
    .db OP_imm   ; ADC #
    .db OP_imp   ; ROR A
    .db OP_ill
    .db OP_ind   ; JMP ind
    .db OP_abs   ; ADC abs
    .db OP_abs   ; ROR abs
    .db OP_zpg_rel ; BBR zpg,rel
    .db OP_rel   ; BVS rel
    .db OP_ind_Y ; ADC ind,Y
    .db OP_ind_zpg ; ADC ind,zpg
    .db OP_ill
    .db OP_zpg_X ; STZ zpg,X
    .db OP_zpg_X ; ADC zpg,X
    .db OP_zpg_X ; ROR zpg,X
    .db OP_bit_zpg ; RMB bit,zpg
    .db OP_imp   ; SEI
    .db OP_abs_Y ; ADC abs,Y
    .db OP_imp   ; PLY
    .db OP_ill
    .db OP_ind_abs_X ; JMP ind,abs,X
    .db OP_abs_X ; ADC abs,X
    .db OP_abs_X ; ROR abs,X
    .db OP_zpg_rel ; BBR zpg,rel
    .db OP_rel   ; BRA rel
    .db OP_X_ind ; STA X,ind
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; STY zpg
    .db OP_zpg   ; STA zpg
    .db OP_zpg   ; STX zpg
    .db OP_bit_zpg ; SMB bit,zpg
    .db OP_imp   ; DEY
    .db OP_imm   ; BIT imm
    .db OP_imp   ; TXA
    .db OP_ill
    .db OP_abs   ; STY abs
    .db OP_abs   ; STA abs
    .db OP_abs   ; STX abs
    .db OP_zpg_rel ; BBS zpg,rel
    .db OP_rel   ; BCC rel
    .db OP_ind_Y ; STA ind,Y
    .db OP_ind_zpg ; STA ind,zpg
    .db OP_ill
    .db OP_zpg_X ; STY zpg,X
    .db OP_zpg_X ; STA zpg,X
    .db OP_zpg_Y ; STX zpg,Y
    .db OP_bit_zpg ; SMB bit,zpg
    .db OP_imp   ; TYA
    .db OP_abs_Y ; STA abs,Y
    .db OP_imp   ; TXS
    .db OP_ill
    .db OP_abs   ; STZ abs
    .db OP_abs_X ; STA abs,X
    .db OP_abs_X ; STZ abs,X
    .db OP_zpg_rel ; BBS zpg,rel
    .db OP_imm   ; LDY imm
    .db OP_X_ind ; LDA X,ind
    .db OP_imm   ; LDX imm
    .db OP_ill
    .db OP_zpg   ; LDY zpg
    .db OP_zpg   ; LDA zpg
    .db OP_zpg   ; LDX zpg
    .db OP_bit_zpg ; SMB bit,zpg
    .db OP_imp   ; TAY
    .db OP_imm   ; LDA imm
    .db OP_imp   ; TAX
    .db OP_ill
    .db OP_abs   ; LDY abs
    .db OP_abs   ; LDA abs
    .db OP_abs   ; LDX abs
    .db OP_zpg_rel ; BBS zpg,rel
    .db OP_rel   ; BCS rel
    .db OP_ind_Y ; LDA ind,Y
    .db OP_ind_zpg ; LDA ind,zpg
    .db OP_ill
    .db OP_zpg_X ; LDY zpg,X
    .db OP_zpg_X ; LDA zpg,X
    .db OP_zpg_Y ; LDX zpg,Y
    .db OP_bit_zpg ; SMB bit,zpg
    .db OP_imp   ; CLV
    .db OP_abs_Y ; LDA abs,Y
    .db OP_imp   ; TSX
    .db OP_ill
    .db OP_abs_X ; LDY abs,X
    .db OP_abs_X ; LDA abs,X
    .db OP_abs_Y ; LDX abs,Y
    .db OP_zpg_rel ; BBS zpg,rel
    .db OP_imm   ; CPY imm
    .db OP_X_ind ; CMP X,ind
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; CPY zpg
    .db OP_zpg   ; CMP zpg
    .db OP_zpg   ; DEC zpg
    .db OP_bit_zpg ; SMB bit,zpg
    .db OP_imp   ; INY
    .db OP_imm   ; CMP imm
    .db OP_imp   ; DEX
    .db OP_imp   ; WAI
    .db OP_abs   ; CPY abs
    .db OP_abs   ; CMP abs
    .db OP_abs   ; DEC abs
    .db OP_zpg_rel ; BBS zpg,rel
    .db OP_rel   ; BNE rel
    .db OP_ind_Y ; CMP ind,Y
    .db OP_ind_zpg ; CMP ind,zpg
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; CMP zpg,X
    .db OP_zpg_X ; DEC zpg,X
    .db OP_bit_zpg ; SMB bit,zpg
    .db OP_imp   ; CLD
    .db OP_abs_Y ; CMP abs,Y
    .db OP_imp   ; PHX
    .db OP_imp   ; STP
    .db OP_ill
    .db OP_abs_X ; CMP abs,X
    .db OP_abs_Y ; DEC abs,Y
    .db OP_zpg_rel ; BBS zpg,rel
    .db OP_imm   ; CPX imm
    .db OP_X_ind ; SBC X,ind
    .db OP_ill
    .db OP_ill
    .db OP_zpg   ; CPX zpg
    .db OP_zpg   ; SBC zpg
    .db OP_zpg   ; INC zpg
    .db OP_bit_zpg ; SMB bit,zpg
    .db OP_imp   ; INX
    .db OP_imm   ; SBC imm
    .db OP_imp   ; NOP
    .db OP_ill
    .db OP_abs   ; CPX abs
    .db OP_abs   ; SBC abs
    .db OP_abs   ; INC abs
    .db OP_zpg_rel ; BBS zpg,rel
    .db OP_rel   ; BEQ rel
    .db OP_ind_Y ; SBC ind,Y
    .db OP_ind_zpg ; SBC ind,zpg
    .db OP_ill
    .db OP_ill
    .db OP_zpg_X ; SBC zpg,X
    .db OP_zpg_X ; INC zpg,X
    .db OP_bit_zpg ; SMB bit,zpg
    .db OP_imp   ; SED
    .db OP_abs_Y ; SBC abs,Y
    .db OP_imp   ; PLX
    .db OP_ill
    .db OP_ill
    .db OP_abs_X ; SBC abs,X
    .db OP_abs_Y ; INC abs,Y
    .db OP_zpg_rel ; BBS zpg,rel
