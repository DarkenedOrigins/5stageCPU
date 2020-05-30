.align 4
.section .text
.globl _start
_start:
	li	sp,0x84000000
	addi	sp,sp,-704
	sw	ra,700(sp)
	sw	s0,696(sp)
	sw	s1,692(sp)
	sw	s2,688(sp)
	sw	s3,684(sp)
	sw	s4,680(sp)
	sw	s5,676(sp)
	addi	a1,sp,256
	li	a2,0
	li	a0,13
.L7:
	mv	a5,a2
	addi	a3,a2,-8
	mv	a4,a1
.L8:
	sw	a5,0(a4)
	addi	a5,a5,-1
	addi	a4,a4,4
	bne	a5,a3,.L8
	addi	a2,a2,1
	addi	a1,a1,32
	bne	a2,a0,.L7
	addi	a4,sp,160
	li	a5,0
	li	a2,8
.L9:
	sw	a5,0(a4)
	addi	a3,a5,1
	sw	a3,4(a4)
	addi	a5,a5,2
	sw	a5,8(a4)
	mv	a5,a3
	addi	a4,a4,12
	bne	a3,a2,.L9
	addi	s3,sp,4
	addi	s2,sp,256
	addi	s5,sp,160
	j	.L12
.L22:
	addi	s3,s3,12
	addi	s2,s2,32
	beq	s3,s5,.L21
.L12:
	addi	s4,s3,12
	addi	s1,sp,160
	mv	s0,s3
.L11:
	addi	s0,s0,4
	li	a3,3
	li	a2,8
	mv	a1,s1
	mv	a0,s2
	call	foo
	sw	a0,-4(s0)
	addi	s1,s1,4
	bne	s4,s0,.L11
	j	.L22
.L21:
.L13:
	j	.L13

foo:
	mv	a6,a0
	addi	a4,a2,-1
	beqz	a2,.L4
	slli	a3,a3,2
	li	a0,0
	li	a7,-1
.L3:
	addi	a6,a6,4
	lw	a5,-4(a6)
	lw	a2,0(a1)
	mul	a5,a5,a2
	add	a0,a0,a5
	add	a1,a1,a3
	addi	a4,a4,-1
	bne	a4,a7,.L3
	ret
.L4:
	mv	a0,a2
	ret

__mulsi3:
	mv	a5,a0
	beqz	a0,.L27
	li	a0,0
	j	.L26
.L25:
	srli	a5,a5,1
	slli	a1,a1,1
	beqz	a5,.L29
.L26:
	andi	a4,a5,1
	beqz	a4,.L25
	add	a0,a0,a1
	j	.L25
.L29:
	ret
.L27:
	ret
