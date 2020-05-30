import random

seed = random.randrange(100)
seed = 1
numreg = 10
random.seed(seed);
print("# seed:", seed)

print(".align 4\n.section .text\n.globl _start\n_start:\n")

ops = ["mul", "mulh", "mulhu", "mulhsu"]
abvals = []
for i in range(3,numreg):
	a = random.randint(1, 2147483647)
	b = random.randint(1, 2147483647)
	# a = random.randint(1,11)
	# b = random.randint(1,11)
	ans = a*b;
	# ans = ans if a>0 and b>0 or a<0 and b<0 else -ans
	up_ans = hex(ans)[0:len(hex(ans))-8 ] if len(hex(ans))>10 else "0x0"
	low_ans = hex(ans&int("0xFFFFFFFF",16))
	abvals.append([a,b])
	print("# test %d x%d = (%d*%d) upper:%s lower:%s"%(i-2, i, a,b, up_ans, low_ans) )
	print("lw x1, %%lo(A%d)(x0)"%(i))
	print("lw x2, %%lo(B%d)(x0)"%(i))
	for j in range(4):
		print("nop")
	print("%s x%d, x1,x2"%(random.choice(ops), i))
	for j in range(4):
		print("nop")
print("HALT:\nbeq x0,x0,HALT")
for j in range(4):
	print("nop")
print("\n.section .rodata\n.balign 256")
for i in range(3,numreg):
	print("A%d: .word %s\nB%d: .word %s"%(i, hex(abvals[i-3][0]), i, hex(abvals[i-3][1]) ) )


