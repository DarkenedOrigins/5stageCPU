.align 4
.section .text
.globl _start
_start:
	and x3, x3, x0
	and x2, x2, x0
	addi x3, x0, 10
	addi x2, x2, 2
	addi x1, x0, 1
	addi x12, x0, 2
	addi x5, x0, 5
#	div x5, x3, x2
	mul x11, x5, x1
	la x8, RES1
loop:
	addi x4, x4, 1
	jal x1, func
	bne x3, x0, loop
	lh x7, -2(x8)
halt:
	beq x0, x0, halt

func:
	mul x11, x11, x12
	sub x3, x3, x2
	jal x5, load
	ret
	addi x9, x9, 1
	addi x10, x10, 1
load:
	sh x11, 0(x8)
	addi x8, x8, 2
	jalr x0, x5, 0
	addi x9, x9, 1

.section .rodata
.balign 256
RES1: .word 0x00000000
RES2: .word 0x00000000
RES3: .word 0x00000000
RES4: .word 0x00000000
RES5: .word 0x00000000
