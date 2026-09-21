;
; Copyright (C) 2026 Rhys Weatherley
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

;*****************************************************************************
;
; Zero page locations for user programs compatible with llvm-mos:
;       $10-$1F, $E0-$EF
; https://llvm-mos.org/wiki/C_calling_convention
;
;*****************************************************************************

__rs0       .equ    $10     ; llvm-mos stack pointer
__rc0       .equ    $10
__rc1       .equ    $11
;
__rs1       .equ    $12     ; argument/return register, caller saved.
__rc2       .equ    $12
__rc3       .equ    $13
;
__rs2       .equ    $14     ; argument/return register, caller saved.
__rc4       .equ    $14
__rc5       .equ    $15
;
__rs3       .equ    $16     ; argument/return register, caller saved.
__rc6       .equ    $16
__rc7       .equ    $17
;
__rs4       .equ    $18     ; argument/return register, caller saved.
__rc8       .equ    $18
__rc9       .equ    $19
;
__rs5       .equ    $1A     ; argument/return register, caller saved.
__rc10      .equ    $1A
__rc11      .equ    $1B
;
__rs6       .equ    $1C     ; argument/return register, caller saved.
__rc12      .equ    $1C
__rc13      .equ    $1D
;
__rs7       .equ    $1E     ; argument/return register, caller saved.
__rc14      .equ    $1E
__rc15      .equ    $1F
;
__rs8       .equ    $E0     ; temporary register, caller saved.
__rc16      .equ    $E0
__rc17      .equ    $E1
;
__rs9       .equ    $E2     ; temporary register, caller saved.
__rc18      .equ    $E2
__rc19      .equ    $E3
;
__rs10      .equ    $E4     ; callee-saved register.
__rc20      .equ    $E4
__rc21      .equ    $E5
;
__rs11      .equ    $E6     ; callee-saved register.
__rc22      .equ    $E6
__rc23      .equ    $E7
;
__rs12      .equ    $E8     ; callee-saved register.
__rc24      .equ    $E8
__rc25      .equ    $E9
;
__rs13      .equ    $EA     ; callee-saved register.
__rc26      .equ    $EA
__rc27      .equ    $EB
;
__rs14      .equ    $EC     ; callee-saved register.
__rc28      .equ    $EC
__rc29      .equ    $ED
;
__rs15      .equ    $EE     ; callee-saved register.
__rc30      .equ    $EE
__rc31      .equ    $EF
