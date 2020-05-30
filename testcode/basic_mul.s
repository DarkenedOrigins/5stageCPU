# mp3 sanity check code .align 4
.align 4
.section .text
.globl _start
_start:
	addi x2, x0, 2
	addi x3, x0, 3
	lw x1, %lo(NEG)(x0)
	nop
	nop
	nop
	nop
	mul x6, x2, x3
	mul x7, x2, x1
	mulh x8,x1,x1
	mulhsu x9,x1,x2
	mulhu x10,x1,x2
	nop
	nop
	nop
	nop
HALT:
	beq x0,x0,HALT
.section .rodata
.balign 256
NEG: .word 0xFFFFFFFF
