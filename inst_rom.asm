
inst_rom.om:     file format elf32-tradbigmips


Disassembly of section .text:

00000000 <_start>:
   0:	3401000f 	li	at,0xf
   4:	40815800 	mtc0	at,c0_compare
   8:	3c011000 	lui	at,0x1000
   c:	34210401 	ori	at,at,0x401
  10:	40816000 	mtc0	at,c0_status
  14:	40026000 	mfc0	v0,c0_status

00000018 <_loop>:
  18:	08000006 	j	18 <_loop>
  1c:	00000000 	nop

Disassembly of section .reginfo:

00000020 <.reginfo>:
  20:	00000006 	srlv	zero,zero,zero
	...

Disassembly of section .MIPS.abiflags:

00000038 <.MIPS.abiflags>:
  38:	00002001 	movf	a0,zero,$fcc0
  3c:	01010001 	movt	zero,t0,$fcc0
	...
  48:	00000001 	movf	zero,zero,$fcc0
  4c:	00000000 	nop

Disassembly of section .gnu.attributes:

00000000 <.gnu.attributes>:
   0:	41000000 	0x41000000
   4:	0f676e75 	jal	d9db9d4 <_loop+0xd9db9bc>
   8:	00010000 	sll	zero,at,0x0
   c:	00070401 	0x70401
