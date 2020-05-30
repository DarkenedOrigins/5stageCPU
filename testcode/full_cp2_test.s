# mp3-cp2 comprehensive testcode
.align 4
.section .text
.globl _start
_start:
	lb x1, %lo(FIRST)(x0)
	lb x2, %lo(SECOND)(x0)
	addi x6, x0, %lo(RES1)	# X6 <= address of RES1
	addi x7, x0, %lo(RES2) # X7 <= address of RES2
	nop
	nop
	nop
	nop
	
	sb x1, 1(x6) # 2nd byte of RES1 <= x1
	sb x2, 0(x6) # 1st byte of RES1 <= x2
	nop
	nop
	nop
	nop
	lw x3, %lo(RES1)(x0) # X3 <= lowest halfword of RES1, should be [x1, x2]
	jal x20, FUNC # jump to FUNC, store return in X20

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

HALT:
	beq x0, x0, HALT
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	

.section .rodata
.balign 256
FIRST: .word 0xFFFFFF12
SECOND: .word 0xFFFFFF34
RES1: .word 0x00000000
RES2: .word 0xDEADBEEF
.section .text
.align 4
FUNC:
	add x3, x3, x1	# X3 <= X3 + X1, should be 0x1246
	sh x3, 0(x7)	# RES2 <= X3
	lh x4, 0(x7)	# X4 <= lower half of RES2, should be 0x1246
	lhu x5, 2(x7)	# X5 <= upper half of RES2, should be 0xDEAD
	lbu x8, %lo(FIRST)+1(x0)	# X8 <= second byte of FIRST, should be 0xFF
	lb x9, %lo(SECOND)+1(x0)	# X9 <= second byte of SECOND, should be -1
	nop
	nop

	jalr x21, x20, 0	# return to instruction past first JAL, store return in X21
	nop
	nop
	nop
	nop
	nop
	nop
	nop
