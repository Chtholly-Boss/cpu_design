.org 0x0
.set noat
.global _start
_start:
ori $1,$0,0xffff
sll $1,$1,16
ori $1,$1,0xfffb # $1 = -5 为寄存器$1 赋初值
ori $2,$0,6 # $2 = 6 为寄存器$2 赋初值
mult $1,$2 # hi = 0xffffffff
# lo = 0xffffffe2
madd $1,$2 # hi = 0xffffffff
# lo = 0xffffffc4
maddu $1,$2 # hi = 0x5
# lo = 0xffffffa6
msub $1,$2 # hi = 0x5
# lo = 0xffffffc4
msubu $1,$2 # hi = 0xffffffff
# lo = 0xffffffe2
