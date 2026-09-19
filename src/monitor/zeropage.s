
;*****************************************************************************
;
; This information was gleaned from the CAT Technical Reference Manual,
; and other sources about Apple II compatible BASIC's.  And then expanded
; over time.
;
; This isn't 100% compatible with the original ROM's but is enough to
; implement a new kernel monitor and BASIC from scratch.
;
; There wasn't much space left over in the old days for user programs to
; use the zero page.  This map allocates $00 - $1F and $E0 - $FF for
; general use by user programs.
;
;*****************************************************************************
;
; Free space for user programs: $00 - $1F
;
;*****************************************************************************
;
; Kernel monitor reserved variables: $20 - $4F
;
WNDLFT      .equ    $20     ; Left-most column of the text window (0-79)
WNDWTH      .equ    $21     ; Width of the text window (1-80)
WNDTOP      .equ    $22     ; Top-most line of the text window (0-22)
WNDBTM      .equ    $23     ; Bottom-most line of the text window (1-24)
CHORZ       .equ    $24     ; Horizontal offset of the cursor (0-WNDWTH-1)
CVERT       .equ    $25     ; Veritical offset of the cursor (0-WNDBTM-1)
FKEYPL      .equ    $26     ; Function key definition pointer (low)
FKEYPH      .equ    $27     ; Function key definition pointer (high)
SBASL       .equ    $28     ; Screen base address 1 (low)
SBASH       .equ    $29     ; Screen base address 1 (high)
SBAS2L      .equ    $2A     ; Screen base address 2 (low)
SBAS2H      .equ    $2B     ; Screen base address 2 (high)
SCRATCH1    .equ    $2C     ; Scratch register 1
SCRATCH2    .equ    $2D     ; Scratch register 2
CHKSUM      .equ    $2E     ; Checksum for casette tape operations
OPCODL      .equ    $2F     ; Opcode length in the kernel monitor
FKEY        .equ    $30     ; Function keycode for the KEY_FESC escape.
STOFLG      .equ    $31     ; Flag for the kernel doing a store command
INVFLG      .equ    $32     ; Normal=$FF, Inverse=$3F, Blinking=$7F
PROMPT      .equ    $33     ; Prompt character with MSB set ($DD = ']')
SAVEX       .equ    $34     ; Save location for the X register
SAVEY       .equ    $35     ; Save location for the Y register
OUTSWL      .equ    $36     ; Address of the character output routine (low)
OUTSWH      .equ    $37     ; Address of the character output routine (high)
INSWL       .equ    $38     ; Address of the character input routine (low)
INSWH       .equ    $39     ; Address of the character input routine (high)
PCL         .equ    $3A     ; Saved PC register for BREAK (low)
PCH         .equ    $3B     ; Saved PC register for BREAK (high)
REG1L       .equ    $3C     ; First address for a kernel operation (low)
REG1H       .equ    $3D     ; First address for a kernel operation (high)
REG2L       .equ    $3E     ; Second address for a kernel operation (low)
REG2H       .equ    $3F     ; Second address for a kernel operation (high)
PEEKSWL     .equ    $40     ; Address of input peek routine (low)
PEEKSWH     .equ    $41     ; Address of input peek routine (high)
REG4L       .equ    $42     ; Fourth address for a kernel operation (low)
REG4H       .equ    $43     ; Fourth address for a kernel operation (high)
; Reserved for the monitor: $44
ACCIRQ      .equ    $45     ; Saved A register for IRQBRK
REGX        .equ    $46     ; Saved X register for BREAK or monitor
REGY        .equ    $47     ; Saved Y register for BREAK or monitor
STATUS      .equ    $48     ; Saved P register for BREAK or monitor
STACKP      .equ    $49     ; Saved SP register for BREAK or monitor
REGA        .equ    $4A     ; Saved A register for BREAK or monitor
;
; Reserved for the monitor: $4B - $4D.
;
; RNDNOL/RNDNOH is incremented in polling loops for the keyboard to
; provide some unpredictability.
;
RNDNOL      .equ    $4E     ; Random number seed (low)
RNDNOH      .equ    $4F     ; Random number seed (high)
;
; Values for STOFLG.  $00 and $99 are compatible with the old monitors,
; but the other values are specific to this monitor.
;
STOCLR      .equ    $00     ; Flag is clear, no special action.
STOSET      .equ    $99     ; Setting bytes with the ":" command.
STODOT      .equ    $77     ; Previously saw a "." for an address range.
STOSTEP     .equ    $11     ; Previous command was "S".
;
;*****************************************************************************
;
; General purpose variables for BASIC: $50 - $66
;
            ; TODO
;
;*****************************************************************************
;
; BASIC memory management: $67 - $74
;
; On entry to BASIC, BSTART and BEND must be set to tell BASIC the
; available (contiguous) memory for storing programs and variables.
; The other pointers are initialized by BASIC itself.
;
BSTART      .equ    $67     ; Start of program memory (low/high)
BVAR        .equ    $69     ; End of program, start of variable space (low/high)
BARRAY      .equ    $6B     ; Start of array space (low/high)
BNUMEND     .equ    $6D     ; End of numeric storage (low/high)
BSTR        .equ    $6F     ; Start of string storage (low/high)
BPTR        .equ    $71     ; General pointer (low/high)
BEND        .equ    $73     ; End of program and variable memory (low/high)
;
;*****************************************************************************
;
; BASIC program run state: $75 - $84
;
BLINENUM    .equ    $75     ; Current line number being executed (low/high)
BSTOPLINE   .equ    $77     ; Line at which execution stopped (low/high)
BSTMTPTR    .equ    $79     ; Points to statement to execute next (low/high)
BDATALINE   .equ    $7B     ; Line number with next DATA to READ (low/high)
BDATAPTR    .equ    $7D     ; Points to the next DATA to READ (low/high)
BINPUTPTR   .equ    $7F     ; Points to INPUT source (low/high)
BVARNAME    .equ    $81     ; Last-used variable's name (2 bytes)
BVARVALUE   .equ    $83     ; Last-used variable's value (2 bytes)
;
;*****************************************************************************
;
; General purpose variables for BASIC: $85 - $9C
;
            ; TODO
;
;*****************************************************************************
;
; Floating point calculations for BASIC: $9D - $AA
;
; Each floating-point accumulator has the following layout:
;
;   byte 0      Exponent + 128
;   byte 1-4    32-bit mantissa in big-endian byte order
;   byte 5      Sign: $00 for positive, $FF for negative
;
; If the value is converted into a 16-bit integer, it will end up in
; bytes 3 and 4 of the accumulator, MSB first.
;
; Zero is represented by setting the exponent to 0, with the mantissa
; set to arbitrary bits.
;
; When a floating-point value is stored to a variable, the sign is
; placed into the MSB of the first mantissa byte, leading to a
; 5-byte representation for the variable's value.
;
; MSTACK points to the top of the "math stack" which can be used to
; push or pop intermediate values when they aren't in the accumulators.
; The math stack grows down in memory.  This is not Applesoft compatible.
;
FACCUM1     .equ    $9D     ; First floating point accumulator (6 bytes)
MSTACK      .equ    $A3     ; 8-bit offset into the math stack
FSPARE      .equ    $A4     ; Temporary variable for use by math routines
FACCUM2     .equ    $A5     ; Second floating point accumulator (6 bytes)
;
; Aliases for integer values in the floating-point accumulators (big-endian)
;
I8_ACC1     .equ    $A1     ; 8-bit integer in FACCUM1.
I8_ACC2     .equ    $A9     ; 8-bit integer in FACCUM2.
I16_ACC1    .equ    $A0     ; 16-bit integer in FACCUM1.
I16_ACC2    .equ    $A8     ; 16-bit integer in FACCUM2.
I32_ACC1    .equ    $9E     ; 32-bit integer in FACCUM1.
I32_ACC2    .equ    $A6     ; 32-bit integer in FACCUM2.
;
; General purpose variables for BASIC: $AC - $C4
;
            ; TODO
;
;*****************************************************************************
;
; Memory bank configuration that is active in SBANK I/O registers - $C5 - C8
; These are populated by the kernel monitor.
;
PBANK1      .equ    $C5     ; Page that is selected for memory bank 1 (0-15)
PBANK2      .equ    $C6     ; Page that is selected for memory bank 2 (0-15)
PBANK3      .equ    $C7     ; Page that is selected for memory bank 3 (0-15)
PBANK4      .equ    $C8     ; Page that is selected for memory bank 4 (0-15)
;
;*****************************************************************************
;
; General purpose variables for BASIC: $C9 - $DF
;
RANDSEED    .equ    $C9     ; Random number seed (5 bytes)
            ; TODO
;
;*****************************************************************************
;
; Reserved space for user programs compatible with llvm-mos: $E0 - $FF
; https://llvm-mos.org/wiki/C_calling_convention
;
;*****************************************************************************

__rs0       .equ    $E0     ; llvm-mos stack pointer
__rc0       .equ    $E0
__rc1       .equ    $E1
;
__rs1       .equ    $E2     ; argument/return register, caller saved.
__rc2       .equ    $E2
__rc3       .equ    $E3
;
__rs2       .equ    $E4     ; argument/return register, caller saved.
__rc4       .equ    $E4
__rc5       .equ    $E5
;
__rs3       .equ    $E6     ; argument/return register, caller saved.
__rc6       .equ    $E6
__rc7       .equ    $E7
;
__rs4       .equ    $E8     ; argument/return register, caller saved.
__rc8       .equ    $E8
__rc9       .equ    $E9
;
__rs5       .equ    $EA     ; argument/return register, caller saved.
__rc10      .equ    $EA
__rc11      .equ    $EB
;
__rs6       .equ    $EC     ; argument/return register, caller saved.
__rc12      .equ    $EC
__rc13      .equ    $ED
;
__rs7       .equ    $EE     ; argument/return register, caller saved.
__rc14      .equ    $EE
__rc15      .equ    $EF
;
__rs8       .equ    $F0     ; temporary register, caller saved.
__rc16      .equ    $F0
__rc17      .equ    $F1
;
__rs9       .equ    $F2     ; temporary register, caller saved.
__rc18      .equ    $F2
__rc19      .equ    $F3
;
__rs10      .equ    $F4     ; callee-saved register.
__rc20      .equ    $F4
__rc21      .equ    $F5
;
__rs11      .equ    $F6     ; callee-saved register.
__rc22      .equ    $F6
__rc23      .equ    $F7
;
__rs12      .equ    $F8     ; callee-saved register.
__rc24      .equ    $F8
__rc25      .equ    $F9
;
__rs13      .equ    $FA     ; callee-saved register.
__rc26      .equ    $FA
__rc27      .equ    $FB
;
__rs14      .equ    $FC     ; callee-saved register.
__rc28      .equ    $FC
__rc29      .equ    $FD
;
__rs15      .equ    $FE     ; callee-saved register.
__rc30      .equ    $FE
__rc31      .equ    $FF
