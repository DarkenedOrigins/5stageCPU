# mp3 sanity check code .align 4
.align 4
.section .text
.globl _start
_start:
	addi x2,x0,2
	addi x3,x0,3
	# mul x30=x2*x3
	jal x1, MUL
	add x6,x30,x0

	addi x2,x0,512
	addi x3,x0,2
	# x30 = x2/x3
	jal x1, DIV
	add x2,x30,x0
	add x1,x0,x0
HALT:
	beq x0,x0,HALT
MUL:
	add x30,x0,x0
	addi x29,x0,1
mloop: 
	add x30,x30,x2 # x30 += x2
	sub x3,x3,x29 # x3--
	bne x3, x0, mloop # branch greater than 0
	ret
DIV:
	addi x30,x0,0 # clear x30
dloop:
	sub x2,x2,x3 # x2 -= x3
	addi x30,x30,1 # inc x30
	bge x2,x3, dloop
	ret

.section .rodata
.balign 256
NEG: .word 0xFFFFFFFF
