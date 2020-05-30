# mp3 sanity check code .align 4
.align 4
.section .text
.globl _start
_start:
	addi x2,x0,2
	addi x3,x0,3
	mul x6,x2,x3
	addi x6,x0,512
	div x2,x6,x2
HALT:
	beq x0,x0,HALT
.section .rodata
.balign 256
NEG: .word 0xFFFFFFFF
