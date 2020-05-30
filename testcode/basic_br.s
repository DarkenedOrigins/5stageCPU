.align 4
.section .text
.globl _start
_start:
	addi x1,x0,1
	addi x2,x0,16
	and x5, x0, x0
<<<<<<< HEAD
   and x3, x0, x0
	nop
=======
<<<<<<< HEAD
        and x3, x0, x0
	nop
=======
	#and x3, x3, x0
>>>>>>> master
>>>>>>> jake
	nop
	nop
	nop
loop:
	addi x5,x5,1
	sub x2,x2,x1 #x2=x2-x1
#	nop
#	nop
#	nop
#	nop
	bne x2,x0,loop
	addi x3,x3,1
<<<<<<< HEAD
=======
<<<<<<< HEAD
        nop
halt:
        beq x0, x0, halt
=======
>>>>>>> jake
	addi x7,x7,1
	addi x8,x8,1

HALT:
	beq x0, x0, HALT
<<<<<<< HEAD

=======
>>>>>>> master
>>>>>>> jake
