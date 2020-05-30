# complete test for the inst: LUI, AUIPC, LW, SW, ADDI, XORI, ORI, ANDI,
# SLLI, SRLI, ADD, SLL, XOR, SRL, OR, BEQ, BNE, BLT, BGE, BLTU, BGEU, AND

.align 4
.section .text
.globl _start
_start:
	# here we test the branches
	nop
	nop
	nop
	nop
	beq x0,x0,basic_ops
	nop
	nop
	nop
	nop

basic_ops:
	addi x1, x0, 1	#x1=0+1=1
	ori x2, x0, 1 	#x2=0|1=1
	xori x3, x0, 1	#x3=0^1=1
	andi x4, x0, 1	#x4=0&1=0
	lui x16,1
	auipc x17, 0
	add x5,x0,x1	#x5=1
	sub x6,x0,x1 	#x6=-1
	srli x7,x1,1	#x7=0
	srai x8,x1,1	#x8=0/1000fffffff
	slli x9,x1,1	#x9=2
	srl x10,x1,x1	#x7=0
	sra x11,x1,x1	#x8=0/1000fffffff
	sll x12,x1,x1	#x9=2
	or	x13,x0,x1 	#x11=1
	xor	x14,x0,x1 	#x12=1
	and	x15,x1,x1 	#x13=1
	#load stores after this
	lw x18, %lo(babe)(x0)
	nop
	nop
	nop
	nop
	sw x18, %lo(dead)(x0)
	lw x19, %lo(dead)(x0)
	bne x0,x1,branch_tests
	nop
	nop
	nop
	nop
branch_tests:
	blt x0,x1,a
	nop
	nop
	nop
	nop
	lw x31,%lo(bad)(x0)
	beq x0,x0,halt
	nop
	nop
	nop
	nop
a:	bge x1,x0,b
	nop
	nop
	nop
	nop
	lw x31,%lo(bad)(x0)
	beq x0,x0,halt
	nop
	nop
	nop
	nop
b:	bltu x0,x1,c
	nop
	nop
	nop
	nop
	lw x31,%lo(bad)(x0)
	beq x0,x0,halt
	nop
	nop
	nop
	nop
c:	bgeu x1,x0,d
	nop
	nop
	nop
	nop
	lw x31,%lo(bad)(x0)
	beq x0,x0,halt
	nop
	nop
	nop
	nop
d:	slt x20,x0,x1
	sltu x21,x0,x1
	lw x31,%lo(good)(x0)
	nop
	nop
	nop
	nop
halt: beq x0,x0,halt
	nop
	nop
	nop
	nop
	lw x22,%lo(bad)(x0)
	beq x0,x0,halt
	nop
	nop
	nop
	nop

.section .rodata
.balign 256
bad:	.word 0xBADDBADD
good:	.word 0x600d600d 
babe:	.word 0xCAFEBABE
dead:	.word 0xdeadbeef
