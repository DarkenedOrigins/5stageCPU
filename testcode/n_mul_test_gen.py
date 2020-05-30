import random

def shex(x):
	if x >= 0:
		return "{0:0{1}x}".format(x,8)
	else:
		return hex((1 << 32) + x).replace("L","").replace("-","")[2:]
def shex64(x):
	if x >= 0:
		return "{0:0{1}x}".format(x,16)
	else:
		return hex((1 << 64) + x).replace("L","").replace("-","")[2:]

seed = random.randrange(100)
seed = 1
numreg = 32
random.seed(seed);
print("# seed:", seed)

print(".align 4\n.section .text\n.globl _start\n_start:\n")

ops = ["mul", "mulh", "mulhu", "mulhsu"]
abvals = []


for i in range(3,numreg):
	sel = random.randint(0,3)
	if(sel <= 1):
		a = random.randint(-2147483648, 2147483647)
		b = random.randint(-2147483648, 2147483647)
	elif(sel == 2):
		a = random.randint(0, 4294967295)
		b = random.randint(0, 4294967295)
	else:
		a = random.randint(-2147483648, 2147483647)
		b = random.randint(0, 4294967295)
	ans = a*b
	# ans = a//b if sel < 2 else a%b;
	hexans = shex64(ans)[8:] if sel == 0 else shex64(ans)[:8] # upper or lower half
	# print("dec ans:",ans, "64bit hex:", shex64(ans), "final hex:", hexans )	
	abvals.append([a,b,hexans])
	print("# test %d %d*%d = x%d = %s"%(i-2,a,b, i, hexans) )
	print("lw x1, %%lo(A%d)(x0)"%(i))
	print("lw x2, %%lo(B%d)(x0)"%(i))
	print("%s x%d, x1,x2"%(ops[sel], i))
print("HALT:\nbeq x0,x0,HALT")
print("\n.section .rodata\n.balign 256")
for i in range(3,numreg):
	print("A%d: .word 0x%s\nB%d: .word 0x%s"%(i, shex(abvals[i-3][0]), i, shex(abvals[i-3][1]) ) )

f = open("mreg.txt", "w")
s = """// memory data file (do not edit the following line - required for mem load use)
// instance=/mp3_tb/itf/registers
// format=mti addressradix=d dataradix=h version=1.0 wordsperline=1
"""
f.write(s)
f.write(" 0: 00000000\n")
f.write( " 1: %s\n"%( shex(a) ) )
f.write( " 2: %s\n"%( shex(b) ) ) 
for i in range(3, numreg):
	if i < 10:
		f.write(" %d: %s\n"%(i,abvals[i-3][2]) )
	else:
		f.write("%d: %s\n"%(i,abvals[i-3][2]) )
for i in range(numreg, 32):
	if i < 10:
		f.write(" %d: 00000000\n"%(i))
	else:
		f.write("%d: 00000000\n"%(i))
f.close()
