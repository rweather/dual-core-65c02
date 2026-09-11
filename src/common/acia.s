;
; acia.s - 6551 Asynchronous Communications Interface Adapter definitions.
;

; I/O ports on the 6551 Asynchronous Communications Interface Adapter
; https://www.westerndesigncenter.com/wdc/documentation/w65c51n.pdf
    .ifdef ACIA_BASE
ACIA_DATA           .equ    (ACIA_BASE)
ACIA_STATUS         .equ    (ACIA_BASE+1)
ACIA_CMD            .equ    (ACIA_BASE+2)
ACIA_CTRL           .equ    (ACIA_BASE+3)
    .else
ACIA_DATA           .equ    $8410
ACIA_STATUS         .equ    $8411
ACIA_CMD            .equ    $8412
ACIA_CTRL           .equ    $8413
ACIA_RTS            .equ    $8105       ; RTS signal separate from the ACIA.
    .endif

; Bits of interest in the ACIA registers.
ACIA_IRQ            .equ    %10000000   ; ACIA_STATUS register.
ACIA_DSR            .equ    %01000000
ACIA_DCDB           .equ    %00100000
ACIA_TDRE           .equ    %00010000
ACIA_RDRF           .equ    %00001000
ACIA_OVRN           .equ    %00000100
ACIA_FE             .equ    %00000010
ACIA_PE             .equ    %00000001
ACIA_ERR            .equ    %00000111   ; Error bits.
ACIA_SBN            .equ    %10000000   ; ACIA_CTRL register.
ACIA_WL1            .equ    %01000000
ACIA_WL0            .equ    %00100000
ACIA_RCS            .equ    %00010000
ACIA_BPS_115200     .equ    %00000000
ACIA_BPS_300        .equ    %00000110
ACIA_BPS_1200       .equ    %00001000
ACIA_BPS_2400       .equ    %00001010
ACIA_BPS_9600       .equ    %00001110
ACIA_BPS_19200      .equ    %00001111
ACIA_PMC1           .equ    %10000000   ; ACIA_CMD register.
ACIA_PMC0           .equ    %01000000
ACIA_PME            .equ    %00100000
ACIA_REM            .equ    %00010000
ACIA_TIC1           .equ    %00001000
ACIA_TIC0           .equ    %00000100
ACIA_IRD            .equ    %00000010
ACIA_DTR            .equ    %00000001
