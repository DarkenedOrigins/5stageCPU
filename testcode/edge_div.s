# mp3 sanity check code .align 4
.align 4
.section .text
.globl _start
_start:
	addi x3, x0, 3
	lw x1, %lo(NEG)(x0)
	nop
	nop
	nop
	nop
	divu x4, x1, x3
	nop
HALT:
	beq x0,x0,HALT
.section .rodata
.balign 256
NEG: .word 0xFFFFFFFF
