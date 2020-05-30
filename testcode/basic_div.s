# mp3 sanity check code .align 4
.align 4
.section .text
.globl _start
_start:
	addi x2, x0, 2
	addi x3, x0, 3
	addi x4, x0, 4
	addi x6, x0, 6
	lw x1, %lo(NEG)(x0)
	nop
	nop
	nop
	nop
	div x7, x6, x2
	divu x8, x1, x3
	div x9, x6, x1
	mul x4, x4, x1
	nop
	nop
	nop
	nop
	rem x10, x6, x4
	nop
	nop
	nop
	nop
HALT:
	beq x0,x0,HALT
.section .rodata
.balign 256
NEG: .word 0xFFFFFFFF
