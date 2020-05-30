import random

seed = random.randrange(100)
# seed = 1
numreg = 10
random.seed(seed);
print("# seed:", seed)

print(".align 4\n.section .text\n.globl _start\n_start:\n")

ops = ["div", "divu", "rem", "remu"]
abvals = []

f = open("reg.txt", "w")
s = """// memory data file (do not edit the following line - required for mem load use)
// instance=/mp3_tb/itf/registers
// format=mti addressradix=d dataradix=h version=1.0 wordsperline=1
"""
f.write(s)

for i in range(3,numreg):
	a = random.randint(1, 2147483647)
	b = random.randint(1, 2147483647)
	sel = random.randint(0,3)
	ans = a//b if sel < 2 else a%b;
	hexans = hex(ans)
	abvals.append([a,b,ans])
	print("# test %d x%d = %s"%(i-2, i, hexans) )
	print("lw x1, %%lo(A%d)(x0)"%(i))
	print("lw x2, %%lo(B%d)(x0)"%(i))
	for j in range(4):
		print("nop")
	print("%s x%d, x1,x2"%(ops[sel], i))
	for j in range(4):
		print("nop")
print("HALT:\nbeq x0,x0,HALT")
for j in range(4):
	print("nop")
print("\n.section .rodata\n.balign 256")
for i in range(3,numreg):
	print("A%d: .word %s\nB%d: .word %s"%(i, hex(abvals[i-3][0]), i, hex(abvals[i-3][1]) ) )

f.write(" 0: 00000000\n")
f.write( " 1: %s\n"%( "{0:0{1}x}".format(a,8) ) )
f.write( " 2: %s\n"%( "{0:0{1}x}".format(b,8) ) )
for i in range(3, numreg):
	if i < 10:
		f.write(" %d: %s\n"%(i,"{0:0{1}x}".format(abvals[i-3][2],8) ) )
	else:
		f.write("%d: %s\n"%(i,"{0:0{1}x}".format(abvals[i-3][2],8) ) )
for i in range(numreg, 32):
	if i < 10:
		f.write(" %d: 00000000\n"%(i))
	else:
		f.write("%d: 00000000\n"%(i))
