
inst_rom.om:     file format elf32-tradbigmips


Disassembly of section .text:

00000000 <_start>:
   0:	3403eeff 	li	v1,0xeeff
   4:	a0030003 	sb	v1,3(zero)
   8:	00031a02 	srl	v1,v1,0x8
   c:	a0030002 	sb	v1,2(zero)
  10:	3403ccdd 	li	v1,0xccdd
  14:	a0030001 	sb	v1,1(zero)
  18:	00031a02 	srl	v1,v1,0x8
  1c:	a0030000 	sb	v1,0(zero)
  20:	80010003 	lb	at,3(zero)
  24:	90010002 	lbu	at,2(zero)
  28:	3403aabb 	li	v1,0xaabb
  2c:	a4030004 	sh	v1,4(zero)
  30:	94010004 	lhu	at,4(zero)
  34:	84010004 	lh	at,4(zero)
  38:	34038899 	li	v1,0x8899
  3c:	a4030006 	sh	v1,6(zero)
  40:	84010006 	lh	at,6(zero)
  44:	94010006 	lhu	at,6(zero)
  48:	34034455 	li	v1,0x4455
  4c:	00031c00 	sll	v1,v1,0x10
  50:	34636677 	ori	v1,v1,0x6677
  54:	ac030008 	sw	v1,8(zero)
  58:	8c010008 	lw	at,8(zero)
  5c:	88010005 	lwl	at,5(zero)
  60:	98010008 	lwr	at,8(zero)
  64:	00000000 	nop
  68:	b8010002 	swr	at,2(zero)
  6c:	a8010007 	swl	at,7(zero)
  70:	8c010000 	lw	at,0(zero)
  74:	8c010004 	lw	at,4(zero)

00000078 <_loop>:
  78:	0800001e 	j	78 <_loop>
  7c:	00000000 	nop

Disassembly of section .reginfo:

00000080 <.reginfo>:
  80:	0000000a 	movz	zero,zero,zero
	...

Disassembly of section .MIPS.abiflags:

00000098 <.MIPS.abiflags>:
  98:	00002001 	movf	a0,zero,$fcc0
  9c:	01010001 	movt	zero,t0,$fcc0
	...
  a8:	00000001 	movf	zero,zero,$fcc0
  ac:	00000000 	nop

Disassembly of section .gnu.attributes:

00000000 <.gnu.attributes>:
   0:	41000000 	0x41000000
   4:	0f676e75 	jal	d9db9d4 <_loop+0xd9db95c>
   8:	00010000 	sll	zero,at,0x0
   c:	00070401 	0x70401
