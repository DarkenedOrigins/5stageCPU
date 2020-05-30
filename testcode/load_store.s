# test for pipelined loads/stores
.align 4
.section .text
.globl _start
_start:
	auipc x1, 0x0
	addi x4, x0, 4
	addi x5, x0, 5
	addi x6, x0, 6
	nop
	addi x1, x1, 160
	auipc x2, 0x0
	nop
	nop
	nop
	nop
	addi x2, x2, 156
	auipc x3, 0x0
	nop
	nop
	nop
	nop
	addi x3, x3, 152
	nop
	nop
	nop
	nop
	sw x4, %lo(one)(x0)
	sw x5, %lo(two)(x0)
	sw x6, %lo(three)(x0)
	nop
	nop
	nop
	nop
	lw x7, %lo(one)(x0)
	lw x8, %lo(two)(x0)
	lw x9, %lo(three)(x0)
        nop
        nop
HALT:
        beq x0, x0, HALT

.section .rodata
.balign 256
one: .word 0x00000001
two: .word 0x00000002
three: .word 0x00000003
