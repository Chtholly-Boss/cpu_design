
inst_rom.om:     file format elf32-tradbigmips


Disassembly of section .text:

00000000 <_start>:
   0:	3c020404 	lui	v0,0x404
   4:	34420404 	ori	v0,v0,0x404
   8:	34070007 	li	a3,0x7
   c:	34050005 	li	a1,0x5
  10:	34080008 	li	t0,0x8
  14:	0000000f 	sync
  18:	00021200 	sll	v0,v0,0x8
  1c:	00e21004 	sllv	v0,v0,a3
  20:	00021202 	srl	v0,v0,0x8
  24:	00a21006 	srlv	v0,v0,a1
  28:	00000000 	nop
  2c:	000214c0 	sll	v0,v0,0x13
  30:	00000040 	ssnop
  34:	00021403 	sra	v0,v0,0x10
  38:	01021007 	srav	v0,v0,t0
  3c:	00000000 	nop

Disassembly of section .reginfo:

00000040 <.reginfo>:
  40:	000001a4 	0x1a4
	...

Disassembly of section .MIPS.abiflags:

00000058 <.MIPS.abiflags>:
  58:	00002001 	movf	a0,zero,$fcc0
  5c:	01010001 	movt	zero,t0,$fcc0
	...
  68:	00000001 	movf	zero,zero,$fcc0
  6c:	00000000 	nop

Disassembly of section .gnu.attributes:

00000000 <.gnu.attributes>:
   0:	41000000 	0x41000000
   4:	0f676e75 	jal	d9db9d4 <_start+0xd9db9d4>
   8:	00010000 	sll	zero,at,0x0
   c:	00070401 	0x70401
