# mp3 sanity check code .align 4
.section .text
.globl _start
_start:
#	addi x1, x0, 1	#x1=0+1=1
#	addi x2, x1, 1
#	add x3, x2, x1
#	addi x4, x2, 2
#	addi x5, x1, 4
#	add x6, x5, x1
#	add x7, x6, x1
#	add x8, x1,x1
#	addi x8,x8,6
	la x1, line1
	lw x2, 0(x1)
	addi x3, x2, 1
	addi x4, x0, 1
	addi x5, x0, 1
	addi x6, x0, 1
HALT:
	beq x0,x0,HALT
	nop
	nop
	nop
	nop

.section .rodata
.balign 256
line1 : .word 0x00000005
