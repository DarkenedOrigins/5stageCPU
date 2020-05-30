# test for pipelined loads/stores
.align 4
.section .text
.globl _start
_start:
	addi x1, x0, 5
	addi x2, x0, 10
	addi x3, x0, 15

	lw x4, %lo(one)(x0)
	sw x1, %lo(one)(x0)
	lw x5, %lo(two)(x0)
	sw x2, %lo(two)(x0)
	lw x6, %lo(three)(x0)
	sw x3, %lo(three)(x0)
HALT:
        beq x0, x0, HALT

.section .rodata
.balign 256
one: .word 0x00000001
two: .word 0x00000002
three: .word 0x00000003
