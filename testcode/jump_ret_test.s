.align 4
.section .text
.globl _start
_start:
	and x3, x3, x0
	and x2, x2, x0
	addi x3, x0, 10
	addi x2, x2, 1
loop:
	addi x4, x4, 1
	la x20, func
	jalr x1, x20
	bne x3, x0, loop
	addi x7, x7, 1
halt:
	beq x0, x0, halt

func:
	addi x5, x5, 2
	sub x3, x3, x2
	#jalr x20, x20, 0
	ret
	addi x9, x9, 1
	addi x10, x10, 1
