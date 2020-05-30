# mp3 sanity check code
.align 4
.section .text
.globl _start
_start:
	addi x2, x0, 6
	addi x1, x0, 1
	and x4, x4, x0
	and x3, x3, x0
loop:
	addi x3, x3, 1
	sub x2, x2, x1
	bne x2, x0, loop
	addi x4, x4, 1
	#addi x0, x0, 1
loop2:
	addi x5, x5, 1
	sub x3, x3, x1
	bne x3, x0, loop2
	addi x4, x4, 1
HALT:
	beq x0,x0,HALT
	nop
	nop
	nop
	nop
