
/tmp/tt-disasm-gpv3cl8a/out.elf:     file format elf32-littleriscv


Disassembly of section .text:

00005880 <_start>:
    5880:	fc010113          	addi	sp,sp,-64
    5884:	02812e23          	sw	s0,60(sp)
    5888:	02912c23          	sw	s1,56(sp)
    588c:	03212a23          	sw	s2,52(sp)
    5890:	03312823          	sw	s3,48(sp)
    5894:	03412623          	sw	s4,44(sp)
    5898:	03512423          	sw	s5,40(sp)
    589c:	03612223          	sw	s6,36(sp)
    58a0:	03712023          	sw	s7,32(sp)
    58a4:	01812e23          	sw	s8,28(sp)
    58a8:	01912c23          	sw	s9,24(sp)
    58ac:	01a12a23          	sw	s10,20(sp)
    58b0:	01b12823          	sw	s11,16(sp)
    58b4:	ffb017b7          	lui	a5,0xffb01
    58b8:	ffb01737          	lui	a4,0xffb01
    58bc:	8ac78793          	addi	a5,a5,-1876 # ffb008ac <noc_nonposted_writes_acked>
    58c0:	cdc70713          	addi	a4,a4,-804 # ffb00cdc <__ldm_bss_end>
    58c4:	00f76e63          	bltu	a4,a5,58e0 <.L2>

000058c8 <.L3>:
    58c8:	fe07ae23          	sw	zero,-4(a5)
    58cc:	fe07ac23          	sw	zero,-8(a5)
    58d0:	fe07aa23          	sw	zero,-12(a5)
    58d4:	fe07a823          	sw	zero,-16(a5)
    58d8:	01078793          	addi	a5,a5,16
    58dc:	fef776e3          	bgeu	a4,a5,58c8 <.L3>

000058e0 <.L2>:
    58e0:	ff878693          	addi	a3,a5,-8
    58e4:	5ed76c63          	bltu	a4,a3,5edc <.L40>
    58e8:	fe07aa23          	sw	zero,-12(a5)
    58ec:	fe07a823          	sw	zero,-16(a5)

000058f0 <.L4>:
    58f0:	ffc78693          	addi	a3,a5,-4
    58f4:	00d76463          	bltu	a4,a3,58fc <.L5>
    58f8:	fe07ac23          	sw	zero,-8(a5)

000058fc <.L5>:
    58fc:	00006737          	lui	a4,0x6
    5900:	ffb017b7          	lui	a5,0xffb01
    5904:	ee470713          	addi	a4,a4,-284 # 5ee4 <__kernel_data_lma>
    5908:	87078793          	addi	a5,a5,-1936 # ffb00870 <__ldm_data_start>
    590c:	06f70e63          	beq	a4,a5,5988 <.L7>
    5910:	ffb01637          	lui	a2,0xffb01
    5914:	89c60613          	addi	a2,a2,-1892 # ffb0089c <_ZL18num_pages_acquired>
    5918:	40f60633          	sub	a2,a2,a5
    591c:	00800593          	li	a1,8
    5920:	40265693          	srai	a3,a2,0x2
    5924:	04c5d463          	bge	a1,a2,596c <.L8>
    5928:	00078613          	mv	a2,a5
    592c:	00200813          	li	a6,2
    5930:	00070793          	mv	a5,a4
    5934:	00060713          	mv	a4,a2

00005938 <.L9>:
    5938:	0007a503          	lw	a0,0(a5)
    593c:	0047a583          	lw	a1,4(a5)
    5940:	0087a603          	lw	a2,8(a5)
    5944:	00c78793          	addi	a5,a5,12
    5948:	00c70713          	addi	a4,a4,12
    594c:	ffd68693          	addi	a3,a3,-3
    5950:	fea72a23          	sw	a0,-12(a4)
    5954:	feb72c23          	sw	a1,-8(a4)
    5958:	fec72e23          	sw	a2,-4(a4)
    595c:	fcd84ee3          	blt	a6,a3,5938 <.L9>
    5960:	00070613          	mv	a2,a4
    5964:	00078713          	mv	a4,a5
    5968:	00060793          	mv	a5,a2

0000596c <.L8>:
    596c:	00d05e63          	blez	a3,5988 <.L7>
    5970:	00072583          	lw	a1,0(a4)
    5974:	00200613          	li	a2,2
    5978:	00b7a023          	sw	a1,0(a5)
    597c:	00c69663          	bne	a3,a2,5988 <.L7>
    5980:	00472703          	lw	a4,4(a4)
    5984:	00e7a223          	sw	a4,4(a5)

00005988 <.L7>:
    5988:	ffb307b7          	lui	a5,0xffb30
    598c:	2087a703          	lw	a4,520(a5) # ffb30208 <__stack_top+0x2e208>
    5990:	2287a803          	lw	a6,552(a5)
    5994:	2047a503          	lw	a0,516(a5)
    5998:	2007a683          	lw	a3,512(a5)
    599c:	22c7a783          	lw	a5,556(a5)
    59a0:	3a002703          	lw	a4,928(zero) # 3a0 <_start-0x54e0>
    59a4:	ffb015b7          	lui	a1,0xffb01
    59a8:	ffb01637          	lui	a2,0xffb01
    59ac:	ffb01e37          	lui	t3,0xffb01
    59b0:	8b458593          	addi	a1,a1,-1868 # ffb008b4 <noc_nonposted_writes_num_issued>
    59b4:	8ac60613          	addi	a2,a2,-1876 # ffb008ac <noc_nonposted_writes_acked>
    59b8:	8a4e0e13          	addi	t3,t3,-1884 # ffb008a4 <noc_nonposted_atomics_acked>
    59bc:	00de2223          	sw	a3,4(t3)
    59c0:	0105a223          	sw	a6,4(a1)
    59c4:	00a62223          	sw	a0,4(a2)
    59c8:	08000693          	li	a3,128
    59cc:	00271713          	slli	a4,a4,0x2
    59d0:	37374783          	lbu	a5,883(a4)
    59d4:	06070713          	addi	a4,a4,96
    59d8:	00d78863          	beq	a5,a3,59e8 <.L13>

000059dc <.L11>:
    59dc:	0ff0000f          	fence
    59e0:	31374783          	lbu	a5,787(a4)
    59e4:	fed79ce3          	bne	a5,a3,59dc <.L11>

000059e8 <.L13>:
    59e8:	00800313          	li	t1,8
    59ec:	7c033073          	csrc	0x7c0,t1
    59f0:	00100313          	li	t1,1
    59f4:	01831313          	slli	t1,t1,0x18
    59f8:	0ff0000f          	fence
    59fc:	7c032073          	csrs	0x7c0,t1
    5a00:	ffb317b7          	lui	a5,0xffb31
    5a04:	0ce00713          	li	a4,206
    5a08:	80e7a423          	sw	a4,-2040(a5) # ffb30808 <__stack_top+0x2e808>
    5a0c:	00400693          	li	a3,4
    5a10:	00d7a623          	sw	a3,12(a5)
    5a14:	00e7aa23          	sw	a4,20(a5)
    5a18:	ffb01537          	lui	a0,0xffb01
    5a1c:	0009a7b7          	lui	a5,0x9a
    5a20:	ffb00937          	lui	s2,0xffb00
    5a24:	8af52023          	sw	a5,-1888(a0) # ffb008a0 <_ZL7cmd_ptr>
    5a28:	ffb407b7          	lui	a5,0xffb40
    5a2c:	0000a837          	lui	a6,0xa
    5a30:	02878793          	addi	a5,a5,40 # ffb40028 <__stack_top+0x3e028>
    5a34:	45890913          	addi	s2,s2,1112 # ffb00458 <sem_l1_base>
    5a38:	00092e83          	lw	t4,0(s2)
    5a3c:	008106b7          	lui	a3,0x810
    5a40:	00f12223          	sw	a5,4(sp)
    5a44:	1b280793          	addi	a5,a6,434 # a1b2 <__kernel_data_lma+0x42ce>
    5a48:	ffb01ab7          	lui	s5,0xffb01
    5a4c:	00006a37          	lui	s4,0x6
    5a50:	ffb013b7          	lui	t2,0xffb01
    5a54:	ffb01f37          	lui	t5,0xffb01
    5a58:	100002b7          	lui	t0,0x10000
    5a5c:	01000fb7          	lui	t6,0x1000
    5a60:	00001737          	lui	a4,0x1
    5a64:	00f12423          	sw	a5,8(sp)
    5a68:	2ce68793          	addi	a5,a3,718 # 8102ce <__kernel_data_lma+0x80a3ea>
    5a6c:	00f12623          	sw	a5,12(sp)
    5a70:	000029b7          	lui	s3,0x2
    5a74:	870a8a93          	addi	s5,s5,-1936 # ffb00870 <__ldm_data_start>
    5a78:	abca0a13          	addi	s4,s4,-1348 # 5abc <.L19>
    5a7c:	8dc38393          	addi	t2,t2,-1828 # ffb008dc <_ZL18go_signal_noc_data>
    5a80:	8bcf0f13          	addi	t5,t5,-1860 # ffb008bc <_ZL15num_mcasts_sent>
    5a84:	00f28293          	addi	t0,t0,15 # 1000000f <__kernel_data_lma+0xfffa12b>
    5a88:	ffff8f93          	addi	t6,t6,-1 # ffffff <__kernel_data_lma+0xffa11b>
    5a8c:	07c70d93          	addi	s11,a4,124 # 107c <_start-0x4804>
    5a90:	00000313          	li	t1,0
    5a94:	ffb016b7          	lui	a3,0xffb01
    5a98:	00100813          	li	a6,1
    5a9c:	ffb307b7          	lui	a5,0xffb30
    5aa0:	0080006f          	j	5aa8 <.L12>

00005aa4 <.L74>:
    5aa4:	0ff0000f          	fence

00005aa8 <.L12>:
    5aa8:	89c6a703          	lw	a4,-1892(a3) # ffb0089c <_ZL18num_pages_acquired>
    5aac:	000ea883          	lw	a7,0(t4)
    5ab0:	00170713          	addi	a4,a4,1
    5ab4:	411708b3          	sub	a7,a4,a7
    5ab8:	ff1046e3          	bgtz	a7,5aa4 <.L74>

00005abc <.L19>:
    5abc:	88e6ae23          	sw	a4,-1892(a3)
    5ac0:	8a052703          	lw	a4,-1888(a0)
    5ac4:	00074e83          	lbu	t4,0(a4)
    5ac8:	00070893          	mv	a7,a4
    5acc:	ff9e8e93          	addi	t4,t4,-7
    5ad0:	0ffefe93          	zext.b	t4,t4
    5ad4:	215eceb3          	sh2add	t4,t4,s5
    5ad8:	000eae83          	lw	t4,0(t4)
    5adc:	01da0eb3          	add	t4,s4,t4
    5ae0:	000e8067          	jr	t4

00005ae4 <.L20>:
    5ae4:	00474883          	lbu	a7,4(a4)
    5ae8:	00574883          	lbu	a7,5(a4)
    5aec:	00674883          	lbu	a7,6(a4)
    5af0:	00774883          	lbu	a7,7(a4)
    5af4:	00000493          	li	s1,0
    5af8:	01070713          	addi	a4,a4,16

00005afc <.L22>:
    5afc:	00092e83          	lw	t4,0(s2)
    5b00:	0ff70713          	addi	a4,a4,255
    5b04:	f0077713          	andi	a4,a4,-256
    5b08:	8ae52023          	sw	a4,-1888(a0)
    5b0c:	ffb318b7          	lui	a7,0xffb31
    5b10:	010e8413          	addi	s0,t4,16

00005b14 <.L36>:
    5b14:	0408a703          	lw	a4,64(a7) # ffb31040 <__stack_top+0x2f040>
    5b18:	fe071ee3          	bnez	a4,5b14 <.L36>
    5b1c:	0088a023          	sw	s0,0(a7)
    5b20:	0008a223          	sw	zero,4(a7)
    5b24:	08e00713          	li	a4,142
    5b28:	00245413          	srli	s0,s0,0x2
    5b2c:	00e8a423          	sw	a4,8(a7)
    5b30:	00347413          	andi	s0,s0,3
    5b34:	09198713          	addi	a4,s3,145 # 2091 <_start-0x37ef>
    5b38:	00e8ae23          	sw	a4,28(a7)
    5b3c:	01b46433          	or	s0,s0,s11
    5b40:	0288a023          	sw	s0,32(a7)
    5b44:	0308a423          	sw	a6,40(a7)
    5b48:	0508a023          	sw	a6,64(a7)
    5b4c:	004e2703          	lw	a4,4(t3)
    5b50:	8a052883          	lw	a7,-1888(a0)
    5b54:	00170713          	addi	a4,a4,1
    5b58:	00ee2223          	sw	a4,4(t3)
    5b5c:	000a2737          	lui	a4,0xa2
    5b60:	00e89663          	bne	a7,a4,5b6c <.L37>
    5b64:	0009a737          	lui	a4,0x9a
    5b68:	8ae52023          	sw	a4,-1888(a0)

00005b6c <.L37>:
    5b6c:	00130313          	addi	t1,t1,1
    5b70:	f2048ce3          	beqz	s1,5aa8 <.L12>

00005b74 <.L38>:
    5b74:	0ff0000f          	fence
    5b78:	000ea783          	lw	a5,0(t4)
    5b7c:	00f347b3          	xor	a5,t1,a5
    5b80:	00179713          	slli	a4,a5,0x1
    5b84:	fe0718e3          	bnez	a4,5b74 <.L38>
    5b88:	0ff0000f          	fence
    5b8c:	00800313          	li	t1,8
    5b90:	7c032073          	csrs	0x7c0,t1
    5b94:	03c12403          	lw	s0,60(sp)
    5b98:	03812483          	lw	s1,56(sp)
    5b9c:	03412903          	lw	s2,52(sp)
    5ba0:	03012983          	lw	s3,48(sp)
    5ba4:	02c12a03          	lw	s4,44(sp)
    5ba8:	02812a83          	lw	s5,40(sp)
    5bac:	02412b03          	lw	s6,36(sp)
    5bb0:	02012b83          	lw	s7,32(sp)
    5bb4:	01c12c03          	lw	s8,28(sp)
    5bb8:	01812c83          	lw	s9,24(sp)
    5bbc:	01412d03          	lw	s10,20(sp)
    5bc0:	01012d83          	lw	s11,16(sp)
    5bc4:	00000513          	li	a0,0
    5bc8:	04010113          	addi	sp,sp,64
    5bcc:	00008067          	ret

00005bd0 <.L21>:
    5bd0:	00c74483          	lbu	s1,12(a4) # 9a00c <__kernel_data_lma+0x94128>
    5bd4:	00d74403          	lbu	s0,13(a4)
    5bd8:	00e74e83          	lbu	t4,14(a4)
    5bdc:	00841413          	slli	s0,s0,0x8
    5be0:	00946433          	or	s0,s0,s1
    5be4:	00f74483          	lbu	s1,15(a4)
    5be8:	010e9e93          	slli	t4,t4,0x10
    5bec:	008eeeb3          	or	t4,t4,s0
    5bf0:	01849493          	slli	s1,s1,0x18
    5bf4:	01d4e4b3          	or	s1,s1,t4
    5bf8:	00002eb7          	lui	t4,0x2
    5bfc:	941e8e93          	addi	t4,t4,-1727 # 1941 <_start-0x3f3f>
    5c00:	01d48433          	add	s0,s1,t4
    5c04:	00441413          	slli	s0,s0,0x4
    5c08:	00042b83          	lw	s7,0(s0)
    5c0c:	fd048493          	addi	s1,s1,-48
    5c10:	21e4cb33          	sh2add	s6,s1,t5
    5c14:	000b2e83          	lw	t4,0(s6)
    5c18:	417e8bb3          	sub	s7,t4,s7
    5c1c:	000bce63          	bltz	s7,5c38 <.L24>

00005c20 <.L25>:
    5c20:	0ff0000f          	fence
    5c24:	00042703          	lw	a4,0(s0)
    5c28:	000b2e83          	lw	t4,0(s6)
    5c2c:	40ee8733          	sub	a4,t4,a4
    5c30:	fe0758e3          	bgez	a4,5c20 <.L25>
    5c34:	8a052703          	lw	a4,-1888(a0)

00005c38 <.L24>:
    5c38:	001e8e93          	addi	t4,t4,1
    5c3c:	21e4c4b3          	sh2add	s1,s1,t5
    5c40:	0018cd03          	lbu	s10,1(a7)
    5c44:	01d4a023          	sw	t4,0(s1)
    5c48:	0028cb03          	lbu	s6,2(a7)
    5c4c:	0038c403          	lbu	s0,3(a7)
    5c50:	0048cb83          	lbu	s7,4(a7)
    5c54:	0078ce83          	lbu	t4,7(a7)
    5c58:	0058cc03          	lbu	s8,5(a7)
    5c5c:	0068c483          	lbu	s1,6(a7)
    5c60:	018b9b93          	slli	s7,s7,0x18
    5c64:	008b1b13          	slli	s6,s6,0x8
    5c68:	01ab6b33          	or	s6,s6,s10
    5c6c:	01041413          	slli	s0,s0,0x10
    5c70:	01646433          	or	s0,s0,s6
    5c74:	008be433          	or	s0,s7,s0
    5c78:	00912023          	sw	s1,0(sp)
    5c7c:	0088cc83          	lbu	s9,8(a7)
    5c80:	0098c483          	lbu	s1,9(a7)
    5c84:	00a8cb83          	lbu	s7,10(a7)
    5c88:	00849493          	slli	s1,s1,0x8
    5c8c:	00b8cb03          	lbu	s6,11(a7)
    5c90:	0194e4b3          	or	s1,s1,s9
    5c94:	010b9b93          	slli	s7,s7,0x10
    5c98:	00c8cc83          	lbu	s9,12(a7)
    5c9c:	009bebb3          	or	s7,s7,s1
    5ca0:	00d8cd03          	lbu	s10,13(a7)
    5ca4:	018b1493          	slli	s1,s6,0x18
    5ca8:	0174e4b3          	or	s1,s1,s7
    5cac:	00e8cb83          	lbu	s7,14(a7)
    5cb0:	00f8c883          	lbu	a7,15(a7)
    5cb4:	008d1893          	slli	a7,s10,0x8
    5cb8:	0198e8b3          	or	a7,a7,s9
    5cbc:	010b9b93          	slli	s7,s7,0x10
    5cc0:	011bebb3          	or	s7,s7,a7
    5cc4:	ffb408b7          	lui	a7,0xffb40
    5cc8:	4a488893          	addi	a7,a7,1188 # ffb404a4 <__stack_top+0x3e4a4>
    5ccc:	00cb9b93          	slli	s7,s7,0xc
    5cd0:	0ff00c93          	li	s9,255
    5cd4:	011b8bb3          	add	s7,s7,a7
    5cd8:	00014b03          	lbu	s6,0(sp)
    5cdc:	0ffc7893          	zext.b	a7,s8
    5ce0:	1d9c0c63          	beq	s8,s9,5eb8 <.L26>
    5ce4:	0038fc93          	andi	s9,a7,3
    5ce8:	0dc88893          	addi	a7,a7,220
    5cec:	20ecccb3          	sh2add	s9,s9,a4
    5cf0:	00289c13          	slli	s8,a7,0x2
    5cf4:	008ca023          	sw	s0,0(s9)

00005cf8 <.L27>:
    5cf8:	0407a883          	lw	a7,64(a5) # ffb30040 <__stack_top+0x2e040>
    5cfc:	fe089ee3          	bnez	a7,5cf8 <.L27>
    5d00:	00812883          	lw	a7,8(sp)
    5d04:	0117ae23          	sw	a7,28(a5)
    5d08:	0197a023          	sw	s9,0(a5)
    5d0c:	00400893          	li	a7,4
    5d10:	0317a023          	sw	a7,32(a5)
    5d14:	00462883          	lw	a7,4(a2)
    5d18:	0187a623          	sw	s8,12(a5)
    5d1c:	00c12c03          	lw	s8,12(sp)
    5d20:	0007a823          	sw	zero,16(a5)
    5d24:	07688893          	addi	a7,a7,118
    5d28:	0187aa23          	sw	s8,20(a5)
    5d2c:	01162223          	sw	a7,4(a2)

00005d30 <.L28>:
    5d30:	000ba883          	lw	a7,0(s7)
    5d34:	411488b3          	sub	a7,s1,a7
    5d38:	00f89893          	slli	a7,a7,0xf
    5d3c:	ff104ae3          	bgtz	a7,5d30 <.L28>
    5d40:	0045a883          	lw	a7,4(a1)
    5d44:	0507a023          	sw	a6,64(a5)
    5d48:	00188893          	addi	a7,a7,1
    5d4c:	0115a223          	sw	a7,4(a1)

00005d50 <.L29>:
    5d50:	00872023          	sw	s0,0(a4)
    5d54:	00000493          	li	s1,0
    5d58:	09298c93          	addi	s9,s3,146
    5d5c:	37000c13          	li	s8,880
    5d60:	00400b93          	li	s7,4
    5d64:	060b0463          	beqz	s6,5dcc <.L32>

00005d68 <.L30>:
    5d68:	009e88b3          	add	a7,t4,s1
    5d6c:	0ff8f893          	zext.b	a7,a7
    5d70:	21e8c8b3          	sh2add	a7,a7,t5
    5d74:	0208a403          	lw	s0,32(a7)
    5d78:	00441413          	slli	s0,s0,0x4

00005d7c <.L31>:
    5d7c:	0407a883          	lw	a7,64(a5)
    5d80:	fe089ee3          	bnez	a7,5d7c <.L31>
    5d84:	0197ae23          	sw	s9,28(a5)
    5d88:	00e7a023          	sw	a4,0(a5)
    5d8c:	0187a623          	sw	s8,12(a5)
    5d90:	005478b3          	and	a7,s0,t0
    5d94:	00445413          	srli	s0,s0,0x4
    5d98:	0117a823          	sw	a7,16(a5)
    5d9c:	01f47433          	and	s0,s0,t6
    5da0:	0045ad03          	lw	s10,4(a1)
    5da4:	0087aa23          	sw	s0,20(a5)
    5da8:	00462883          	lw	a7,4(a2)
    5dac:	0377a023          	sw	s7,32(a5)
    5db0:	0507a023          	sw	a6,64(a5)
    5db4:	001d0413          	addi	s0,s10,1
    5db8:	00188893          	addi	a7,a7,1
    5dbc:	00148493          	addi	s1,s1,1
    5dc0:	0085a223          	sw	s0,4(a1)
    5dc4:	01162223          	sw	a7,4(a2)
    5dc8:	fa9b10e3          	bne	s6,s1,5d68 <.L30>

00005dcc <.L32>:
    5dcc:	8a052703          	lw	a4,-1888(a0)
    5dd0:	00000493          	li	s1,0
    5dd4:	01070713          	addi	a4,a4,16
    5dd8:	d25ff06f          	j	5afc <.L22>

00005ddc <.L23>:
    5ddc:	00274e83          	lbu	t4,2(a4)
    5de0:	00374483          	lbu	s1,3(a4)
    5de4:	00874883          	lbu	a7,8(a4)
    5de8:	00974403          	lbu	s0,9(a4)
    5dec:	00849493          	slli	s1,s1,0x8
    5df0:	00841413          	slli	s0,s0,0x8
    5df4:	01146433          	or	s0,s0,a7
    5df8:	00a74883          	lbu	a7,10(a4)
    5dfc:	01d4e4b3          	or	s1,s1,t4
    5e00:	00b74e83          	lbu	t4,11(a4)
    5e04:	01089893          	slli	a7,a7,0x10
    5e08:	0088e8b3          	or	a7,a7,s0
    5e0c:	018e9e93          	slli	t4,t4,0x18
    5e10:	011eeeb3          	or	t4,t4,a7
    5e14:	ffb408b7          	lui	a7,0xffb40
    5e18:	00c49493          	slli	s1,s1,0xc
    5e1c:	4a488893          	addi	a7,a7,1188 # ffb404a4 <__stack_top+0x3e4a4>
    5e20:	01148433          	add	s0,s1,a7

00005e24 <.L35>:
    5e24:	00042883          	lw	a7,0(s0)
    5e28:	411e88b3          	sub	a7,t4,a7
    5e2c:	00f89893          	slli	a7,a7,0xf
    5e30:	ff104ae3          	bgtz	a7,5e24 <.L35>
    5e34:	00412883          	lw	a7,4(sp)
    5e38:	01070713          	addi	a4,a4,16
    5e3c:	011484b3          	add	s1,s1,a7
    5e40:	0004a023          	sw	zero,0(s1)
    5e44:	00000493          	li	s1,0
    5e48:	cb5ff06f          	j	5afc <.L22>

00005e4c <.L17>:
    5e4c:	00474403          	lbu	s0,4(a4)
    5e50:	00574883          	lbu	a7,5(a4)
    5e54:	00674e83          	lbu	t4,6(a4)
    5e58:	00889893          	slli	a7,a7,0x8
    5e5c:	0088e8b3          	or	a7,a7,s0
    5e60:	00774403          	lbu	s0,7(a4)
    5e64:	010e9e93          	slli	t4,t4,0x10
    5e68:	011eeeb3          	or	t4,t4,a7
    5e6c:	01841413          	slli	s0,s0,0x18
    5e70:	01d46433          	or	s0,s0,t4
    5e74:	01070893          	addi	a7,a4,16
    5e78:	02040463          	beqz	s0,5ea0 <.L33>
    5e7c:	211444b3          	sh2add	s1,s0,a7

00005e80 <.L34>:
    5e80:	0008ab03          	lw	s6,0(a7)
    5e84:	40e88eb3          	sub	t4,a7,a4
    5e88:	01d38eb3          	add	t4,t2,t4
    5e8c:	00488893          	addi	a7,a7,4
    5e90:	ff6ea823          	sw	s6,-16(t4)
    5e94:	fe9896e3          	bne	a7,s1,5e80 <.L34>
    5e98:	20e44433          	sh2add	s0,s0,a4
    5e9c:	01040893          	addi	a7,s0,16

00005ea0 <.L33>:
    5ea0:	00f88893          	addi	a7,a7,15
    5ea4:	ff08f713          	andi	a4,a7,-16
    5ea8:	00000493          	li	s1,0
    5eac:	c51ff06f          	j	5afc <.L22>

00005eb0 <.L42>:
    5eb0:	00100493          	li	s1,1
    5eb4:	c49ff06f          	j	5afc <.L22>

00005eb8 <.L26>:
    5eb8:	000ba883          	lw	a7,0(s7)
    5ebc:	411488b3          	sub	a7,s1,a7
    5ec0:	00f89893          	slli	a7,a7,0xf
    5ec4:	e91056e3          	blez	a7,5d50 <.L29>
    5ec8:	000ba883          	lw	a7,0(s7)
    5ecc:	411488b3          	sub	a7,s1,a7
    5ed0:	00f89893          	slli	a7,a7,0xf
    5ed4:	ff1042e3          	bgtz	a7,5eb8 <.L26>
    5ed8:	e79ff06f          	j	5d50 <.L29>

00005edc <.L40>:
    5edc:	00068793          	mv	a5,a3
    5ee0:	a11ff06f          	j	58f0 <.L4>
