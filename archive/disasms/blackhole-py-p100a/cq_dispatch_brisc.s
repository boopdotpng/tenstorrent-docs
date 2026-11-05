
/tmp/tt-disasm-i2uv6esm/out.elf:     file format elf32-littleriscv


Disassembly of section .text:

000049d0 <_start>:
    49d0:	ff010113          	addi	sp,sp,-16
    49d4:	00112623          	sw	ra,12(sp)
    49d8:	ffb017b7          	lui	a5,0xffb01
    49dc:	ffb01737          	lui	a4,0xffb01
    49e0:	8dc78793          	addi	a5,a5,-1828 # ffb008dc <_ZL12write_offset+0xc>
    49e4:	d1870713          	addi	a4,a4,-744 # ffb00d18 <__ldm_bss_end>
    49e8:	00f76e63          	bltu	a4,a5,4a04 <.L530>

000049ec <.L531>:
    49ec:	fe07ae23          	sw	zero,-4(a5)
    49f0:	fe07ac23          	sw	zero,-8(a5)
    49f4:	fe07aa23          	sw	zero,-12(a5)
    49f8:	fe07a823          	sw	zero,-16(a5)
    49fc:	01078793          	addi	a5,a5,16
    4a00:	fef776e3          	bgeu	a4,a5,49ec <.L531>

00004a04 <.L530>:
    4a04:	ff878693          	addi	a3,a5,-8
    4a08:	10d76263          	bltu	a4,a3,4b0c <.L542>
    4a0c:	fe07aa23          	sw	zero,-12(a5)
    4a10:	fe07a823          	sw	zero,-16(a5)

00004a14 <.L532>:
    4a14:	ffc78693          	addi	a3,a5,-4
    4a18:	00d76463          	bltu	a4,a3,4a20 <.L533>
    4a1c:	fe07ac23          	sw	zero,-8(a5)

00004a20 <.L533>:
    4a20:	00007737          	lui	a4,0x7
    4a24:	ffb017b7          	lui	a5,0xffb01
    4a28:	6e470713          	addi	a4,a4,1764 # 76e4 <__kernel_data_lma>
    4a2c:	88078793          	addi	a5,a5,-1920 # ffb00880 <__ldm_data_start>
    4a30:	06f70263          	beq	a4,a5,4a94 <.L535>
    4a34:	ffb01637          	lui	a2,0xffb01
    4a38:	8cc60613          	addi	a2,a2,-1844 # ffb008cc <_ZL7cmd_ptr>
    4a3c:	40f60633          	sub	a2,a2,a5
    4a40:	00800593          	li	a1,8
    4a44:	40265693          	srai	a3,a2,0x2
    4a48:	02c5d863          	bge	a1,a2,4a78 <.L536>
    4a4c:	00200813          	li	a6,2

00004a50 <.L537>:
    4a50:	00072503          	lw	a0,0(a4)
    4a54:	00472583          	lw	a1,4(a4)
    4a58:	00872603          	lw	a2,8(a4)
    4a5c:	00c70713          	addi	a4,a4,12
    4a60:	00c78793          	addi	a5,a5,12
    4a64:	ffd68693          	addi	a3,a3,-3
    4a68:	fea7aa23          	sw	a0,-12(a5)
    4a6c:	feb7ac23          	sw	a1,-8(a5)
    4a70:	fec7ae23          	sw	a2,-4(a5)
    4a74:	fcd84ee3          	blt	a6,a3,4a50 <.L537>

00004a78 <.L536>:
    4a78:	00d05e63          	blez	a3,4a94 <.L535>
    4a7c:	00072583          	lw	a1,0(a4)
    4a80:	00200613          	li	a2,2
    4a84:	00b7a023          	sw	a1,0(a5)
    4a88:	00c69663          	bne	a3,a2,4a94 <.L535>
    4a8c:	00472703          	lw	a4,4(a4)
    4a90:	00e7a223          	sw	a4,4(a5)

00004a94 <.L535>:
    4a94:	ffb307b7          	lui	a5,0xffb30
    4a98:	2087ae83          	lw	t4,520(a5) # ffb30208 <__stack_top+0x2e208>
    4a9c:	2287a303          	lw	t1,552(a5)
    4aa0:	2047a803          	lw	a6,516(a5)
    4aa4:	2007a583          	lw	a1,512(a5)
    4aa8:	22c7a683          	lw	a3,556(a5)
    4aac:	3a002703          	lw	a4,928(zero) # 3a0 <_start-0x4630>
    4ab0:	ffb007b7          	lui	a5,0xffb00
    4ab4:	ffb00e37          	lui	t3,0xffb00
    4ab8:	ffb008b7          	lui	a7,0xffb00
    4abc:	ffb00537          	lui	a0,0xffb00
    4ac0:	ffb00637          	lui	a2,0xffb00
    4ac4:	02d7a023          	sw	a3,32(a5) # ffb00020 <noc_posted_writes_num_issued+0x4>
    4ac8:	05de2023          	sw	t4,64(t3) # ffb00040 <noc_reads_num_issued+0x4>
    4acc:	0268ac23          	sw	t1,56(a7) # ffb00038 <noc_nonposted_writes_num_issued+0x4>
    4ad0:	03052823          	sw	a6,48(a0) # ffb00030 <noc_nonposted_writes_acked+0x4>
    4ad4:	02b62423          	sw	a1,40(a2) # ffb00028 <noc_nonposted_atomics_acked+0x4>
    4ad8:	08000693          	li	a3,128
    4adc:	00271713          	slli	a4,a4,0x2
    4ae0:	37374783          	lbu	a5,883(a4)
    4ae4:	06070713          	addi	a4,a4,96
    4ae8:	00d78863          	beq	a5,a3,4af8 <.L539>

00004aec <.L540>:
    4aec:	0ff0000f          	fence
    4af0:	31374783          	lbu	a5,787(a4)
    4af4:	fed79ce3          	bne	a5,a3,4aec <.L540>

00004af8 <.L539>:
    4af8:	45c000ef          	jal	4f54 <_Z11kernel_mainv>
    4afc:	00c12083          	lw	ra,12(sp)
    4b00:	00000513          	li	a0,0
    4b04:	01010113          	addi	sp,sp,16
    4b08:	00008067          	ret

00004b0c <.L542>:
    4b0c:	00068793          	mv	a5,a3
    4b10:	f05ff06f          	j	4a14 <.L532>

00004b14 <_Z20process_write_linearm>:
    4b14:	fd010113          	addi	sp,sp,-48
    4b18:	01512c23          	sw	s5,24(sp)
    4b1c:	ffb01ab7          	lui	s5,0xffb01
    4b20:	8ccaa583          	lw	a1,-1844(s5) # ffb008cc <_ZL7cmd_ptr>
    4b24:	ffb018b7          	lui	a7,0xffb01
    4b28:	0045cf03          	lbu	t5,4(a1)
    4b2c:	0055ce83          	lbu	t4,5(a1)
    4b30:	0065c803          	lbu	a6,6(a1)
    4b34:	0075cf83          	lbu	t6,7(a1)
    4b38:	0025c303          	lbu	t1,2(a1)
    4b3c:	0085c603          	lbu	a2,8(a1)
    4b40:	0095c783          	lbu	a5,9(a1)
    4b44:	00a5c683          	lbu	a3,10(a1)
    4b48:	00879793          	slli	a5,a5,0x8
    4b4c:	00b5c703          	lbu	a4,11(a1)
    4b50:	00c7e7b3          	or	a5,a5,a2
    4b54:	00c5c283          	lbu	t0,12(a1)
    4b58:	00d5c603          	lbu	a2,13(a1)
    4b5c:	01069693          	slli	a3,a3,0x10
    4b60:	00f6e6b3          	or	a3,a3,a5
    4b64:	8d088893          	addi	a7,a7,-1840 # ffb008d0 <_ZL12write_offset>
    4b68:	01871713          	slli	a4,a4,0x18
    4b6c:	211347b3          	sh2add	a5,t1,a7
    4b70:	00861613          	slli	a2,a2,0x8
    4b74:	00e5ce03          	lbu	t3,14(a1)
    4b78:	00566633          	or	a2,a2,t0
    4b7c:	00d76733          	or	a4,a4,a3
    4b80:	00f5c683          	lbu	a3,15(a1)
    4b84:	0105c283          	lbu	t0,16(a1)
    4b88:	0115c303          	lbu	t1,17(a1)
    4b8c:	008e9e93          	slli	t4,t4,0x8
    4b90:	01eeeeb3          	or	t4,t4,t5
    4b94:	01081813          	slli	a6,a6,0x10
    4b98:	010e1e13          	slli	t3,t3,0x10
    4b9c:	00831313          	slli	t1,t1,0x8
    4ba0:	01d86f33          	or	t5,a6,t4
    4ba4:	00536333          	or	t1,t1,t0
    4ba8:	00ce6e33          	or	t3,t3,a2
    4bac:	0125c603          	lbu	a2,18(a1)
    4bb0:	0135c283          	lbu	t0,19(a1)
    4bb4:	0145c803          	lbu	a6,20(a1)
    4bb8:	0155ce83          	lbu	t4,21(a1)
    4bbc:	01869693          	slli	a3,a3,0x18
    4bc0:	0007a783          	lw	a5,0(a5)
    4bc4:	01061613          	slli	a2,a2,0x10
    4bc8:	01c6ee33          	or	t3,a3,t3
    4bcc:	008e9e93          	slli	t4,t4,0x8
    4bd0:	0165c683          	lbu	a3,22(a1)
    4bd4:	010eeeb3          	or	t4,t4,a6
    4bd8:	00666833          	or	a6,a2,t1
    4bdc:	0175c603          	lbu	a2,23(a1)
    4be0:	00e78733          	add	a4,a5,a4
    4be4:	01069693          	slli	a3,a3,0x10
    4be8:	01d6e6b3          	or	a3,a3,t4
    4bec:	018f9f93          	slli	t6,t6,0x18
    4bf0:	01861e93          	slli	t4,a2,0x18
    4bf4:	00f737b3          	sltu	a5,a4,a5
    4bf8:	01829313          	slli	t1,t0,0x18
    4bfc:	01efefb3          	or	t6,t6,t5
    4c00:	00deeeb3          	or	t4,t4,a3
    4c04:	01c78633          	add	a2,a5,t3
    4c08:	01036333          	or	t1,t1,a6
    4c0c:	00070f13          	mv	t5,a4
    4c10:	02058593          	addi	a1,a1,32
    4c14:	ffb306b7          	lui	a3,0xffb30
    4c18:	02050463          	beqz	a0,4c40 <.L2>

00004c1c <.L3>:
    4c1c:	0406a783          	lw	a5,64(a3) # ffb30040 <__stack_top+0x2e040>
    4c20:	fe079ee3          	bnez	a5,4c1c <.L3>
    4c24:	0000a7b7          	lui	a5,0xa
    4c28:	1b278793          	addi	a5,a5,434 # a1b2 <__kernel_data_lma+0x2ace>
    4c2c:	00f6ae23          	sw	a5,28(a3)
    4c30:	00e6a623          	sw	a4,12(a3)
    4c34:	00c6a823          	sw	a2,16(a3)
    4c38:	01f6aa23          	sw	t6,20(a3)
    4c3c:	0240006f          	j	4c60 <.L4>

00004c40 <.L2>:
    4c40:	0406a783          	lw	a5,64(a3)
    4c44:	fe079ee3          	bnez	a5,4c40 <.L2>
    4c48:	000027b7          	lui	a5,0x2
    4c4c:	09278793          	addi	a5,a5,146 # 2092 <_start-0x293e>
    4c50:	00f6ae23          	sw	a5,28(a3)
    4c54:	00e6a623          	sw	a4,12(a3)
    4c58:	00c6a823          	sw	a2,16(a3)
    4c5c:	01f6aa23          	sw	t6,20(a3)

00004c60 <.L4>:
    4c60:	01d367b3          	or	a5,t1,t4
    4c64:	18078863          	beqz	a5,4df4 <.L5>
    4c68:	03312023          	sw	s3,32(sp)
    4c6c:	ffb00fb7          	lui	t6,0xffb00
    4c70:	ffb002b7          	lui	t0,0xffb00
    4c74:	00004837          	lui	a6,0x4
    4c78:	ffff89b7          	lui	s3,0xffff8
    4c7c:	02812623          	sw	s0,44(sp)
    4c80:	02912423          	sw	s1,40(sp)
    4c84:	03212223          	sw	s2,36(sp)
    4c88:	01412e23          	sw	s4,28(sp)
    4c8c:	01612a23          	sw	s6,20(sp)
    4c90:	01712823          	sw	s7,16(sp)
    4c94:	00100e13          	li	t3,1
    4c98:	01812623          	sw	s8,12(sp)
    4c9c:	0bc573b3          	maxu	t2,a0,t3
    4ca0:	01912423          	sw	s9,8(sp)
    4ca4:	01a12223          	sw	s10,4(sp)
    4ca8:	01b12023          	sw	s11,0(sp)
    4cac:	034f8f93          	addi	t6,t6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    4cb0:	02c28293          	addi	t0,t0,44 # ffb0002c <noc_nonposted_writes_acked>
    4cb4:	fff80413          	addi	s0,a6,-1 # 3fff <_start-0x9d1>
    4cb8:	fff98a13          	addi	s4,s3,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    4cbc:	00300b93          	li	s7,3
    4cc0:	ffb01b37          	lui	s6,0xffb01
    4cc4:	ffb30737          	lui	a4,0xffb30
    4cc8:	ffffc937          	lui	s2,0xffffc
    4ccc:	000084b7          	lui	s1,0x8

00004cd0 <.L24>:
    4cd0:	0108a603          	lw	a2,16(a7)
    4cd4:	12b60863          	beq	a2,a1,4e04 <.L44>
    4cd8:	40b60633          	sub	a2,a2,a1
    4cdc:	180e8263          	beqz	t4,4e60 <.L45>

00004ce0 <.L17>:
    4ce0:	00060c93          	mv	s9,a2
    4ce4:	000f0513          	mv	a0,t5
    4ce8:	00058c13          	mv	s8,a1
    4cec:	08c87063          	bgeu	a6,a2,4d6c <.L23>

00004cf0 <.L20>:
    4cf0:	04072783          	lw	a5,64(a4) # ffb30040 <__stack_top+0x2e040>
    4cf4:	fe079ee3          	bnez	a5,4cf0 <.L20>
    4cf8:	00b72023          	sw	a1,0(a4)
    4cfc:	03072023          	sw	a6,32(a4)
    4d00:	01e72623          	sw	t5,12(a4)
    4d04:	010586b3          	add	a3,a1,a6
    4d08:	05c72023          	sw	t3,64(a4)
    4d0c:	41060cb3          	sub	s9,a2,a6
    4d10:	00068c13          	mv	s8,a3
    4d14:	010f0533          	add	a0,t5,a6
    4d18:	05987a63          	bgeu	a6,s9,4d6c <.L23>
    4d1c:	01460cb3          	add	s9,a2,s4
    4d20:	01250533          	add	a0,a0,s2
    4d24:	012cf7b3          	and	a5,s9,s2
    4d28:	00958c33          	add	s8,a1,s1
    4d2c:	40b50533          	sub	a0,a0,a1
    4d30:	00fc0c33          	add	s8,s8,a5

00004d34 <.L21>:
    4d34:	04072783          	lw	a5,64(a4)
    4d38:	fe079ee3          	bnez	a5,4d34 <.L21>
    4d3c:	00d72023          	sw	a3,0(a4)
    4d40:	00d507b3          	add	a5,a0,a3
    4d44:	00f72623          	sw	a5,12(a4)
    4d48:	05c72023          	sw	t3,64(a4)
    4d4c:	010686b3          	add	a3,a3,a6
    4d50:	ff8692e3          	bne	a3,s8,4d34 <.L21>
    4d54:	00ecd793          	srli	a5,s9,0xe
    4d58:	00e79693          	slli	a3,a5,0xe
    4d5c:	01360cb3          	add	s9,a2,s3
    4d60:	009f0533          	add	a0,t5,s1
    4d64:	40dc8cb3          	sub	s9,s9,a3
    4d68:	00a68533          	add	a0,a3,a0

00004d6c <.L23>:
    4d6c:	04072783          	lw	a5,64(a4)
    4d70:	fe079ee3          	bnez	a5,4d6c <.L23>
    4d74:	01872023          	sw	s8,0(a4)
    4d78:	03972023          	sw	s9,32(a4)
    4d7c:	0042ac03          	lw	s8,4(t0)
    4d80:	008607b3          	add	a5,a2,s0
    4d84:	00a72623          	sw	a0,12(a4)
    4d88:	004fa683          	lw	a3,4(t6)
    4d8c:	40c30d33          	sub	s10,t1,a2
    4d90:	00e7d793          	srli	a5,a5,0xe
    4d94:	02778db3          	mul	s11,a5,t2
    4d98:	01a33333          	sltu	t1,t1,s10
    4d9c:	406e8eb3          	sub	t4,t4,t1
    4da0:	00f687b3          	add	a5,a3,a5
    4da4:	05c72023          	sw	t3,64(a4)
    4da8:	01bc0533          	add	a0,s8,s11
    4dac:	00ffa223          	sw	a5,4(t6)
    4db0:	00a2a223          	sw	a0,4(t0)
    4db4:	01dd67b3          	or	a5,s10,t4
    4db8:	000d0313          	mv	t1,s10
    4dbc:	00c585b3          	add	a1,a1,a2
    4dc0:	00cf0f33          	add	t5,t5,a2
    4dc4:	f00796e3          	bnez	a5,4cd0 <.L24>
    4dc8:	02c12403          	lw	s0,44(sp)
    4dcc:	02812483          	lw	s1,40(sp)
    4dd0:	02412903          	lw	s2,36(sp)
    4dd4:	02012983          	lw	s3,32(sp)
    4dd8:	01c12a03          	lw	s4,28(sp)
    4ddc:	01412b03          	lw	s6,20(sp)
    4de0:	01012b83          	lw	s7,16(sp)
    4de4:	00c12c03          	lw	s8,12(sp)
    4de8:	00812c83          	lw	s9,8(sp)
    4dec:	00412d03          	lw	s10,4(sp)
    4df0:	00012d83          	lw	s11,0(sp)

00004df4 <.L5>:
    4df4:	8cbaa623          	sw	a1,-1844(s5)
    4df8:	01812a83          	lw	s5,24(sp)
    4dfc:	03010113          	addi	sp,sp,48
    4e00:	00008067          	ret

00004e04 <.L44>:
    4e04:	0248a783          	lw	a5,36(a7)
    4e08:	2117c6b3          	sh2add	a3,a5,a7
    4e0c:	0146a683          	lw	a3,20(a3)
    4e10:	08b68263          	beq	a3,a1,4e94 <.L8>
    4e14:	86cb2683          	lw	a3,-1940(s6) # ffb0086c <sem_l1_base>

00004e18 <.L9>:
    4e18:	02c8ac03          	lw	s8,44(a7)
    4e1c:	0288a783          	lw	a5,40(a7)
    4e20:	04fc0463          	beq	s8,a5,4e68 <.L16>

00004e24 <.L15>:
    4e24:	0248a683          	lw	a3,36(a7)
    4e28:	0108a503          	lw	a0,16(a7)
    4e2c:	2116c6b3          	sh2add	a3,a3,a7
    4e30:	0146a683          	lw	a3,20(a3)
    4e34:	418787b3          	sub	a5,a5,s8
    4e38:	40a686b3          	sub	a3,a3,a0
    4e3c:	00c6d693          	srli	a3,a3,0xc
    4e40:	0af6d7b3          	minu	a5,a3,a5
    4e44:	00c79613          	slli	a2,a5,0xc
    4e48:	00a60633          	add	a2,a2,a0
    4e4c:	018787b3          	add	a5,a5,s8
    4e50:	00c8a823          	sw	a2,16(a7)
    4e54:	02f8a623          	sw	a5,44(a7)
    4e58:	40b60633          	sub	a2,a2,a1
    4e5c:	e80e92e3          	bnez	t4,4ce0 <.L17>

00004e60 <.L45>:
    4e60:	0a665633          	minu	a2,a2,t1
    4e64:	e7dff06f          	j	4ce0 <.L17>

00004e68 <.L16>:
    4e68:	0ff0000f          	fence
    4e6c:	0006a783          	lw	a5,0(a3)
    4e70:	02c8ac03          	lw	s8,44(a7)
    4e74:	02f8a423          	sw	a5,40(a7)
    4e78:	fb8796e3          	bne	a5,s8,4e24 <.L15>
    4e7c:	0ff0000f          	fence
    4e80:	0006a783          	lw	a5,0(a3)
    4e84:	02c8ac03          	lw	s8,44(a7)
    4e88:	02f8a423          	sw	a5,40(a7)
    4e8c:	fd878ee3          	beq	a5,s8,4e68 <.L16>
    4e90:	f95ff06f          	j	4e24 <.L15>

00004e94 <.L8>:
    4e94:	01779663          	bne	a5,s7,4ea0 <.L10>
    4e98:	0001a5b7          	lui	a1,0x1a
    4e9c:	00b8a823          	sw	a1,16(a7)

00004ea0 <.L10>:
    4ea0:	0308c683          	lbu	a3,48(a7)
    4ea4:	08068463          	beqz	a3,4f2c <.L11>
    4ea8:	0348a603          	lw	a2,52(a7)
    4eac:	ffb306b7          	lui	a3,0xffb30

00004eb0 <.L12>:
    4eb0:	2286a783          	lw	a5,552(a3) # ffb30228 <__stack_top+0x2e228>
    4eb4:	40c787b3          	sub	a5,a5,a2
    4eb8:	fe07cce3          	bltz	a5,4eb0 <.L12>
    4ebc:	ffb017b7          	lui	a5,0xffb01
    4ec0:	86c7a683          	lw	a3,-1940(a5) # ffb0086c <sem_l1_base>
    4ec4:	ffb22637          	lui	a2,0xffb22

00004ec8 <.L13>:
    4ec8:	84062783          	lw	a5,-1984(a2) # ffb21840 <__stack_top+0x1f840>
    4ecc:	fe079ee3          	bnez	a5,4ec8 <.L13>
    4ed0:	80d62023          	sw	a3,-2048(a2)
    4ed4:	80062223          	sw	zero,-2044(a2)
    4ed8:	08e00793          	li	a5,142
    4edc:	00002537          	lui	a0,0x2
    4ee0:	80f62423          	sw	a5,-2040(a2)
    4ee4:	09150513          	addi	a0,a0,145 # 2091 <_start-0x293f>
    4ee8:	80a62e23          	sw	a0,-2020(a2)
    4eec:	0026d793          	srli	a5,a3,0x2
    4ef0:	00001537          	lui	a0,0x1
    4ef4:	07c50513          	addi	a0,a0,124 # 107c <_start-0x3954>
    4ef8:	0037f793          	andi	a5,a5,3
    4efc:	00a7e7b3          	or	a5,a5,a0
    4f00:	82f62023          	sw	a5,-2016(a2)
    4f04:	02000793          	li	a5,32
    4f08:	82f62423          	sw	a5,-2008(a2)
    4f0c:	00100793          	li	a5,1
    4f10:	84f62023          	sw	a5,-1984(a2)
    4f14:	ffb00537          	lui	a0,0xffb00
    4f18:	02452603          	lw	a2,36(a0) # ffb00024 <noc_nonposted_atomics_acked>
    4f1c:	0248a783          	lw	a5,36(a7)
    4f20:	00160613          	addi	a2,a2,1
    4f24:	02c52223          	sw	a2,36(a0)
    4f28:	0140006f          	j	4f3c <.L14>

00004f2c <.L11>:
    4f2c:	ffb016b7          	lui	a3,0xffb01
    4f30:	00100613          	li	a2,1
    4f34:	86c6a683          	lw	a3,-1940(a3) # ffb0086c <sem_l1_base>
    4f38:	02c88823          	sb	a2,48(a7)

00004f3c <.L14>:
    4f3c:	00178793          	addi	a5,a5,1
    4f40:	0037f793          	andi	a5,a5,3
    4f44:	02f8a223          	sw	a5,36(a7)
    4f48:	004fa783          	lw	a5,4(t6)
    4f4c:	02f8aa23          	sw	a5,52(a7)
    4f50:	ec9ff06f          	j	4e18 <.L9>

00004f54 <_Z11kernel_mainv>:
    4f54:	d6010113          	addi	sp,sp,-672
    4f58:	28112e23          	sw	ra,668(sp)
    4f5c:	28812c23          	sw	s0,664(sp)
    4f60:	28912a23          	sw	s1,660(sp)
    4f64:	29212823          	sw	s2,656(sp)
    4f68:	29312623          	sw	s3,652(sp)
    4f6c:	29412423          	sw	s4,648(sp)
    4f70:	29512223          	sw	s5,644(sp)
    4f74:	29612023          	sw	s6,640(sp)
    4f78:	27712e23          	sw	s7,636(sp)
    4f7c:	27812c23          	sw	s8,632(sp)
    4f80:	27912a23          	sw	s9,628(sp)
    4f84:	27a12823          	sw	s10,624(sp)
    4f88:	27b12623          	sw	s11,620(sp)
    4f8c:	00800313          	li	t1,8
    4f90:	7c033073          	csrc	0x7c0,t1
    4f94:	00100313          	li	t1,1
    4f98:	01831313          	slli	t1,t1,0x18
    4f9c:	0ff0000f          	fence
    4fa0:	7c032073          	csrs	0x7c0,t1
    4fa4:	ffb207b7          	lui	a5,0xffb20
    4fa8:	2087a803          	lw	a6,520(a5) # ffb20208 <__stack_top+0x1e208>
    4fac:	ffb00337          	lui	t1,0xffb00
    4fb0:	2287a503          	lw	a0,552(a5)
    4fb4:	ffb008b7          	lui	a7,0xffb00
    4fb8:	2047a583          	lw	a1,516(a5)
    4fbc:	ffb006b7          	lui	a3,0xffb00
    4fc0:	2007a603          	lw	a2,512(a5)
    4fc4:	ffb00737          	lui	a4,0xffb00
    4fc8:	22c7a783          	lw	a5,556(a5)
    4fcc:	ffb00e37          	lui	t3,0xffb00
    4fd0:	03ce0e13          	addi	t3,t3,60 # ffb0003c <noc_reads_num_issued>
    4fd4:	03430a13          	addi	s4,t1,52 # ffb00034 <noc_nonposted_writes_num_issued>
    4fd8:	02c88b93          	addi	s7,a7,44 # ffb0002c <noc_nonposted_writes_acked>
    4fdc:	01c70313          	addi	t1,a4,28 # ffb0001c <noc_posted_writes_num_issued>
    4fe0:	02468893          	addi	a7,a3,36 # ffb00024 <noc_nonposted_atomics_acked>
    4fe4:	ffb70737          	lui	a4,0xffb70
    4fe8:	ffb786b7          	lui	a3,0xffb78
    4fec:	00c8a023          	sw	a2,0(a7)
    4ff0:	03c12223          	sw	t3,36(sp)
    4ff4:	01112223          	sw	a7,4(sp)
    4ff8:	02612423          	sw	t1,40(sp)
    4ffc:	010e2023          	sw	a6,0(t3)
    5000:	00aa2023          	sw	a0,0(s4)
    5004:	00bba023          	sw	a1,0(s7)
    5008:	00f32023          	sw	a5,0(t1)
    500c:	4a470713          	addi	a4,a4,1188 # ffb704a4 <__stack_top+0x6e4a4>
    5010:	4a468693          	addi	a3,a3,1188 # ffb784a4 <__stack_top+0x764a4>
    5014:	00001637          	lui	a2,0x1

00005018 <.L47>:
    5018:	00072783          	lw	a5,0(a4)
    501c:	40f007b3          	neg	a5,a5
    5020:	00679793          	slli	a5,a5,0x6
    5024:	f8f72a23          	sw	a5,-108(a4)
    5028:	00c70733          	add	a4,a4,a2
    502c:	fed716e3          	bne	a4,a3,5018 <.L47>
    5030:	ffb017b7          	lui	a5,0xffb01
    5034:	8d078a93          	addi	s5,a5,-1840 # ffb008d0 <_ZL12write_offset>
    5038:	0001a637          	lui	a2,0x1a
    503c:	ffb017b7          	lui	a5,0xffb01
    5040:	8cc7a623          	sw	a2,-1844(a5) # ffb008cc <_ZL7cmd_ptr>
    5044:	000aa023          	sw	zero,0(s5)
    5048:	000197b7          	lui	a5,0x19
    504c:	6d07a703          	lw	a4,1744(a5) # 196d0 <__kernel_data_lma+0x11fec>
    5050:	004a2783          	lw	a5,4(s4)
    5054:	00171693          	slli	a3,a4,0x1
    5058:	02faaa23          	sw	a5,52(s5)
    505c:	0003a7b7          	lui	a5,0x3a
    5060:	00faaa23          	sw	a5,20(s5)
    5064:	0005a7b7          	lui	a5,0x5a
    5068:	00faac23          	sw	a5,24(s5)
    506c:	0007a7b7          	lui	a5,0x7a
    5070:	0016d693          	srli	a3,a3,0x1
    5074:	01f75713          	srli	a4,a4,0x1f
    5078:	00faae23          	sw	a5,28(s5)
    507c:	0009a7b7          	lui	a5,0x9a
    5080:	02faa023          	sw	a5,32(s5)
    5084:	00caa823          	sw	a2,16(s5)
    5088:	00060793          	mv	a5,a2
    508c:	04daa023          	sw	a3,64(s5)
    5090:	04eaa223          	sw	a4,68(s5)
    5094:	ffb01637          	lui	a2,0xffb01
    5098:	ffb016b7          	lui	a3,0xffb01
    509c:	00005737          	lui	a4,0x5
    50a0:	86c60613          	addi	a2,a2,-1940 # ffb0086c <sem_l1_base>
    50a4:	88068693          	addi	a3,a3,-1920 # ffb00880 <__ldm_data_start>
    50a8:	0d070713          	addi	a4,a4,208 # 50d0 <.L48>
    50ac:	020aa223          	sw	zero,36(s5)
    50b0:	000aa423          	sw	zero,8(s5)
    50b4:	000aa223          	sw	zero,4(s5)
    50b8:	00078b13          	mv	s6,a5
    50bc:	00c12023          	sw	a2,0(sp)
    50c0:	00d12623          	sw	a3,12(sp)
    50c4:	00e12823          	sw	a4,16(sp)
    50c8:	000049b7          	lui	s3,0x4
    50cc:	12fb0a63          	beq	s6,a5,5200 <.L496>

000050d0 <.L48>:
    50d0:	000b4703          	lbu	a4,0(s6)
    50d4:	00c12683          	lw	a3,12(sp)
    50d8:	000b0793          	mv	a5,s6
    50dc:	20d74733          	sh2add	a4,a4,a3
    50e0:	01012683          	lw	a3,16(sp)
    50e4:	00072703          	lw	a4,0(a4)
    50e8:	00e68733          	add	a4,a3,a4
    50ec:	00070067          	jr	a4

000050f0 <.L58>:
    50f0:	004b4783          	lbu	a5,4(s6)
    50f4:	005b4683          	lbu	a3,5(s6)
    50f8:	006b4703          	lbu	a4,6(s6)
    50fc:	00869693          	slli	a3,a3,0x8
    5100:	00f6e6b3          	or	a3,a3,a5
    5104:	007b4783          	lbu	a5,7(s6)
    5108:	01071713          	slli	a4,a4,0x10
    510c:	00d76733          	or	a4,a4,a3
    5110:	01879793          	slli	a5,a5,0x18
    5114:	008b4683          	lbu	a3,8(s6)
    5118:	009b4603          	lbu	a2,9(s6)
    511c:	00e7e7b3          	or	a5,a5,a4
    5120:	00ab4703          	lbu	a4,10(s6)
    5124:	ffb125b7          	lui	a1,0xffb12
    5128:	00861613          	slli	a2,a2,0x8
    512c:	00d66633          	or	a2,a2,a3
    5130:	01071713          	slli	a4,a4,0x10
    5134:	00bb4683          	lbu	a3,11(s6)
    5138:	1f05a503          	lw	a0,496(a1) # ffb121f0 <__stack_top+0x101f0>
    513c:	00c76733          	or	a4,a4,a2
    5140:	1f85a603          	lw	a2,504(a1)
    5144:	01869693          	slli	a3,a3,0x18
    5148:	00ab2023          	sw	a0,0(s6)
    514c:	00e6e6b3          	or	a3,a3,a4
    5150:	00cb2223          	sw	a2,4(s6)
    5154:	ffb01637          	lui	a2,0xffb01
    5158:	8cc62583          	lw	a1,-1844(a2) # ffb008cc <_ZL7cmd_ptr>
    515c:	00479793          	slli	a5,a5,0x4
    5160:	ffb30737          	lui	a4,0xffb30

00005164 <.L278>:
    5164:	04072603          	lw	a2,64(a4) # ffb30040 <__stack_top+0x2e040>
    5168:	fe061ee3          	bnez	a2,5164 <.L278>
    516c:	00002637          	lui	a2,0x2
    5170:	09260613          	addi	a2,a2,146 # 2092 <_start-0x293e>
    5174:	00c72e23          	sw	a2,28(a4)
    5178:	00b72023          	sw	a1,0(a4)
    517c:	10000637          	lui	a2,0x10000
    5180:	00d72623          	sw	a3,12(a4)
    5184:	00c7f6b3          	and	a3,a5,a2
    5188:	00479793          	slli	a5,a5,0x4
    518c:	00d72823          	sw	a3,16(a4)
    5190:	0087d793          	srli	a5,a5,0x8
    5194:	00f72a23          	sw	a5,20(a4)
    5198:	004a2683          	lw	a3,4(s4)
    519c:	004ba783          	lw	a5,4(s7)
    51a0:	00800613          	li	a2,8
    51a4:	02c72023          	sw	a2,32(a4)
    51a8:	00168693          	addi	a3,a3,1
    51ac:	00178793          	addi	a5,a5,1 # 9a001 <__kernel_data_lma+0x9291d>
    51b0:	00da2223          	sw	a3,4(s4)
    51b4:	00100613          	li	a2,1
    51b8:	00fba223          	sw	a5,4(s7)
    51bc:	04c72023          	sw	a2,64(a4)
    51c0:	ffb306b7          	lui	a3,0xffb30

000051c4 <.L279>:
    51c4:	2046a703          	lw	a4,516(a3) # ffb30204 <__stack_top+0x2e204>
    51c8:	fee79ee3          	bne	a5,a4,51c4 <.L279>
    51cc:	0ff0000f          	fence

000051d0 <.L486>:
    51d0:	ffb017b7          	lui	a5,0xffb01
    51d4:	8cc7ab03          	lw	s6,-1844(a5) # ffb008cc <_ZL7cmd_ptr>

000051d8 <.L485>:
    51d8:	010b0b13          	addi	s6,s6,16

000051dc <.L74>:
    51dc:	000017b7          	lui	a5,0x1
    51e0:	fff78793          	addi	a5,a5,-1 # fff <_start-0x39d1>
    51e4:	00fb07b3          	add	a5,s6,a5
    51e8:	fffffb37          	lui	s6,0xfffff
    51ec:	0167fb33          	and	s6,a5,s6
    51f0:	ffb017b7          	lui	a5,0xffb01
    51f4:	8d67a623          	sw	s6,-1844(a5) # ffb008cc <_ZL7cmd_ptr>
    51f8:	010aa783          	lw	a5,16(s5)
    51fc:	ecfb1ae3          	bne	s6,a5,50d0 <.L48>

00005200 <.L496>:
    5200:	024aa783          	lw	a5,36(s5)
    5204:	2157c733          	sh2add	a4,a5,s5
    5208:	01472703          	lw	a4,20(a4)
    520c:	01671463          	bne	a4,s6,5214 <.L49>
    5210:	12c0106f          	j	633c <.L497>

00005214 <.L49>:
    5214:	02caa683          	lw	a3,44(s5)
    5218:	028aa783          	lw	a5,40(s5)
    521c:	00f69463          	bne	a3,a5,5224 <.L55>
    5220:	1c00106f          	j	63e0 <.L498>

00005224 <.L55>:
    5224:	024aa703          	lw	a4,36(s5)
    5228:	010aa603          	lw	a2,16(s5)
    522c:	21574733          	sh2add	a4,a4,s5
    5230:	01472703          	lw	a4,20(a4)
    5234:	40d787b3          	sub	a5,a5,a3
    5238:	40c70733          	sub	a4,a4,a2
    523c:	00c75713          	srli	a4,a4,0xc
    5240:	0af757b3          	minu	a5,a4,a5
    5244:	00c79713          	slli	a4,a5,0xc
    5248:	00c70733          	add	a4,a4,a2
    524c:	00d787b3          	add	a5,a5,a3
    5250:	ffb016b7          	lui	a3,0xffb01
    5254:	8cc6ab03          	lw	s6,-1844(a3) # ffb008cc <_ZL7cmd_ptr>
    5258:	00eaa823          	sw	a4,16(s5)
    525c:	02faa623          	sw	a5,44(s5)
    5260:	e71ff06f          	j	50d0 <.L48>

00005264 <.L72>:
    5264:	001b4503          	lbu	a0,1(s6) # fffff001 <__instrn_buffer+0x1bf001>
    5268:	8adff0ef          	jal	4b14 <_Z20process_write_linearm>
    526c:	ffb017b7          	lui	a5,0xffb01
    5270:	8cc7ab03          	lw	s6,-1844(a5) # ffb008cc <_ZL7cmd_ptr>
    5274:	f69ff06f          	j	51dc <.L74>

00005278 <.L65>:
    5278:	000017b7          	lui	a5,0x1
    527c:	00f78793          	addi	a5,a5,15 # 100f <_start-0x39c1>
    5280:	fffff737          	lui	a4,0xfffff
    5284:	00fb07b3          	add	a5,s6,a5
    5288:	00e7f7b3          	and	a5,a5,a4
    528c:	ffb016b7          	lui	a3,0xffb01
    5290:	030ac703          	lbu	a4,48(s5)
    5294:	8cf6a623          	sw	a5,-1844(a3) # ffb008cc <_ZL7cmd_ptr>
    5298:	00071463          	bnez	a4,52a0 <.L65+0x28>
    529c:	1640106f          	j	6400 <.L499>
    52a0:	034aa603          	lw	a2,52(s5)
    52a4:	ffb306b7          	lui	a3,0xffb30

000052a8 <.L286>:
    52a8:	2286a703          	lw	a4,552(a3) # ffb30228 <__stack_top+0x2e228>
    52ac:	40c70733          	sub	a4,a4,a2
    52b0:	fe074ce3          	bltz	a4,52a8 <.L286>
    52b4:	00012703          	lw	a4,0(sp)
    52b8:	00072683          	lw	a3,0(a4) # fffff000 <__instrn_buffer+0x1bf000>
    52bc:	ffb22737          	lui	a4,0xffb22

000052c0 <.L287>:
    52c0:	84072603          	lw	a2,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    52c4:	fe061ee3          	bnez	a2,52c0 <.L287>
    52c8:	80d72023          	sw	a3,-2048(a4)
    52cc:	80072223          	sw	zero,-2044(a4)
    52d0:	0026d693          	srli	a3,a3,0x2
    52d4:	000015b7          	lui	a1,0x1
    52d8:	08e00513          	li	a0,142
    52dc:	00002637          	lui	a2,0x2
    52e0:	80a72423          	sw	a0,-2040(a4)
    52e4:	0036f693          	andi	a3,a3,3
    52e8:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    52ec:	09160613          	addi	a2,a2,145 # 2091 <_start-0x293f>
    52f0:	80c72e23          	sw	a2,-2020(a4)
    52f4:	00b6e6b3          	or	a3,a3,a1
    52f8:	82d72023          	sw	a3,-2016(a4)
    52fc:	02000693          	li	a3,32
    5300:	82d72423          	sw	a3,-2008(a4)
    5304:	00100693          	li	a3,1
    5308:	84d72023          	sw	a3,-1984(a4)
    530c:	00412683          	lw	a3,4(sp)
    5310:	0006a703          	lw	a4,0(a3)
    5314:	00170713          	addi	a4,a4,1
    5318:	00e6a023          	sw	a4,0(a3)

0000531c <.L288>:
    531c:	024aa703          	lw	a4,36(s5)
    5320:	004a2683          	lw	a3,4(s4)
    5324:	21574733          	sh2add	a4,a4,s5
    5328:	01472703          	lw	a4,20(a4)
    532c:	02daaa23          	sw	a3,52(s5)
    5330:	40f707b3          	sub	a5,a4,a5
    5334:	00c7d793          	srli	a5,a5,0xc
    5338:	02000713          	li	a4,32
    533c:	06e78663          	beq	a5,a4,53a8 <.L289>
    5340:	40f70633          	sub	a2,a4,a5
    5344:	00012783          	lw	a5,0(sp)
    5348:	0007a703          	lw	a4,0(a5)
    534c:	ffb227b7          	lui	a5,0xffb22

00005350 <.L290>:
    5350:	8407a683          	lw	a3,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    5354:	fe069ee3          	bnez	a3,5350 <.L290>
    5358:	80e7a023          	sw	a4,-2048(a5)
    535c:	8007a223          	sw	zero,-2044(a5)
    5360:	00275713          	srli	a4,a4,0x2
    5364:	000015b7          	lui	a1,0x1
    5368:	08e00513          	li	a0,142
    536c:	000026b7          	lui	a3,0x2
    5370:	80a7a423          	sw	a0,-2040(a5)
    5374:	00377713          	andi	a4,a4,3
    5378:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    537c:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    5380:	80d7ae23          	sw	a3,-2020(a5)
    5384:	00b76733          	or	a4,a4,a1
    5388:	82e7a023          	sw	a4,-2016(a5)
    538c:	82c7a423          	sw	a2,-2008(a5)
    5390:	00100713          	li	a4,1
    5394:	84e7a023          	sw	a4,-1984(a5)
    5398:	00412703          	lw	a4,4(sp)
    539c:	00072783          	lw	a5,0(a4)
    53a0:	00178793          	addi	a5,a5,1
    53a4:	00f72023          	sw	a5,0(a4)

000053a8 <.L289>:
    53a8:	004ba683          	lw	a3,4(s7)
    53ac:	ffb30737          	lui	a4,0xffb30

000053b0 <.L291>:
    53b0:	20472783          	lw	a5,516(a4) # ffb30204 <__stack_top+0x2e204>
    53b4:	fed79ee3          	bne	a5,a3,53b0 <.L291>
    53b8:	0ff0000f          	fence
    53bc:	00012783          	lw	a5,0(sp)
    53c0:	028aa703          	lw	a4,40(s5)
    53c4:	0007a683          	lw	a3,0(a5)

000053c8 <.L292>:
    53c8:	0ff0000f          	fence
    53cc:	0006a783          	lw	a5,0(a3)
    53d0:	00f747b3          	xor	a5,a4,a5
    53d4:	00179613          	slli	a2,a5,0x1
    53d8:	fe0618e3          	bnez	a2,53c8 <.L292>
    53dc:	0ff0000f          	fence
    53e0:	02412783          	lw	a5,36(sp)
    53e4:	ffb30737          	lui	a4,0xffb30
    53e8:	0047a683          	lw	a3,4(a5)

000053ec <.L293>:
    53ec:	20872783          	lw	a5,520(a4) # ffb30208 <__stack_top+0x2e208>
    53f0:	fed79ee3          	bne	a5,a3,53ec <.L293>
    53f4:	004a2683          	lw	a3,4(s4)
    53f8:	ffb30737          	lui	a4,0xffb30

000053fc <.L294>:
    53fc:	22872783          	lw	a5,552(a4) # ffb30228 <__stack_top+0x2e228>
    5400:	fed79ee3          	bne	a5,a3,53fc <.L294>
    5404:	004ba683          	lw	a3,4(s7)
    5408:	ffb30737          	lui	a4,0xffb30

0000540c <.L295>:
    540c:	20472783          	lw	a5,516(a4) # ffb30204 <__stack_top+0x2e204>
    5410:	fed79ee3          	bne	a5,a3,540c <.L295>
    5414:	00412783          	lw	a5,4(sp)
    5418:	ffb30737          	lui	a4,0xffb30
    541c:	0047a683          	lw	a3,4(a5)

00005420 <.L296>:
    5420:	20072783          	lw	a5,512(a4) # ffb30200 <__stack_top+0x2e200>
    5424:	fed79ee3          	bne	a5,a3,5420 <.L296>
    5428:	02812783          	lw	a5,40(sp)
    542c:	ffb30737          	lui	a4,0xffb30
    5430:	0047a683          	lw	a3,4(a5)

00005434 <.L297>:
    5434:	22c72783          	lw	a5,556(a4) # ffb3022c <__stack_top+0x2e22c>
    5438:	fed79ee3          	bne	a5,a3,5434 <.L297>
    543c:	0ff0000f          	fence
    5440:	00800313          	li	t1,8
    5444:	7c032073          	csrs	0x7c0,t1
    5448:	29c12083          	lw	ra,668(sp)
    544c:	29812403          	lw	s0,664(sp)
    5450:	29412483          	lw	s1,660(sp)
    5454:	29012903          	lw	s2,656(sp)
    5458:	28c12983          	lw	s3,652(sp)
    545c:	28812a03          	lw	s4,648(sp)
    5460:	28412a83          	lw	s5,644(sp)
    5464:	28012b03          	lw	s6,640(sp)
    5468:	27c12b83          	lw	s7,636(sp)
    546c:	27812c03          	lw	s8,632(sp)
    5470:	27412c83          	lw	s9,628(sp)
    5474:	27012d03          	lw	s10,624(sp)
    5478:	26c12d83          	lw	s11,620(sp)
    547c:	2a010113          	addi	sp,sp,672
    5480:	00008067          	ret

00005484 <.L66>:
    5484:	001b4683          	lbu	a3,1(s6)
    5488:	01000613          	li	a2,16
    548c:	41560633          	sub	a2,a2,s5
    5490:	000a8793          	mv	a5,s5
    5494:	0ff6f713          	zext.b	a4,a3
    5498:	2156c5b3          	sh2add	a1,a3,s5
    549c:	00068e63          	beqz	a3,54b8 <.L282>

000054a0 <.L281>:
    54a0:	00fb06b3          	add	a3,s6,a5
    54a4:	00c686b3          	add	a3,a3,a2
    54a8:	0006a683          	lw	a3,0(a3)
    54ac:	00478793          	addi	a5,a5,4
    54b0:	fed7ae23          	sw	a3,-4(a5)
    54b4:	fef596e3          	bne	a1,a5,54a0 <.L281>

000054b8 <.L282>:
    54b8:	00470713          	addi	a4,a4,4
    54bc:	21674b33          	sh2add	s6,a4,s6
    54c0:	d1dff06f          	j	51dc <.L74>

000054c4 <.L63>:
    54c4:	001b4783          	lbu	a5,1(s6)
    54c8:	00078c63          	beqz	a5,54e0 <.L192>
    54cc:	004ba703          	lw	a4,4(s7)
    54d0:	ffb307b7          	lui	a5,0xffb30

000054d4 <.L193>:
    54d4:	2047a683          	lw	a3,516(a5) # ffb30204 <__stack_top+0x2e204>
    54d8:	fee69ee3          	bne	a3,a4,54d4 <.L193>
    54dc:	0ff0000f          	fence

000054e0 <.L192>:
    54e0:	002b4703          	lbu	a4,2(s6)
    54e4:	003b4783          	lbu	a5,3(s6)
    54e8:	00002637          	lui	a2,0x2
    54ec:	00879793          	slli	a5,a5,0x8
    54f0:	00e7e7b3          	or	a5,a5,a4
    54f4:	97160613          	addi	a2,a2,-1679 # 1971 <_start-0x305f>
    54f8:	cc078ce3          	beqz	a5,51d0 <.L486>

000054fc <.L194>:
    54fc:	60179713          	ctz	a4,a5
    5500:	00c70733          	add	a4,a4,a2
    5504:	00471713          	slli	a4,a4,0x4
    5508:	00072683          	lw	a3,0(a4)
    550c:	fff78593          	addi	a1,a5,-1
    5510:	00b7f7b3          	and	a5,a5,a1
    5514:	00168693          	addi	a3,a3,1
    5518:	00d72023          	sw	a3,0(a4)
    551c:	fe0790e3          	bnez	a5,54fc <.L194>
    5520:	cb1ff06f          	j	51d0 <.L486>

00005524 <.L64>:
    5524:	00cb4803          	lbu	a6,12(s6)
    5528:	00db4603          	lbu	a2,13(s6)
    552c:	00eb4783          	lbu	a5,14(s6)
    5530:	00fb4703          	lbu	a4,15(s6)
    5534:	001b4503          	lbu	a0,1(s6)
    5538:	002b4683          	lbu	a3,2(s6)
    553c:	003b4703          	lbu	a4,3(s6)
    5540:	00861613          	slli	a2,a2,0x8
    5544:	004b4883          	lbu	a7,4(s6)
    5548:	01066633          	or	a2,a2,a6
    554c:	007b4583          	lbu	a1,7(s6)
    5550:	005b4803          	lbu	a6,5(s6)
    5554:	01079793          	slli	a5,a5,0x10
    5558:	00c7e7b3          	or	a5,a5,a2
    555c:	ffb40637          	lui	a2,0xffb40
    5560:	4a460613          	addi	a2,a2,1188 # ffb404a4 <__stack_top+0x3e4a4>
    5564:	00c79793          	slli	a5,a5,0xc
    5568:	00869693          	slli	a3,a3,0x8
    556c:	00a6e6b3          	or	a3,a3,a0
    5570:	006b4503          	lbu	a0,6(s6)
    5574:	01071713          	slli	a4,a4,0x10
    5578:	008b4303          	lbu	t1,8(s6)
    557c:	00d76733          	or	a4,a4,a3
    5580:	00c787b3          	add	a5,a5,a2
    5584:	009b4683          	lbu	a3,9(s6)
    5588:	01889613          	slli	a2,a7,0x18
    558c:	00e66633          	or	a2,a2,a4
    5590:	00ab4703          	lbu	a4,10(s6)
    5594:	00869693          	slli	a3,a3,0x8
    5598:	00bb4883          	lbu	a7,11(s6)
    559c:	0066e6b3          	or	a3,a3,t1
    55a0:	01071713          	slli	a4,a4,0x10
    55a4:	00d76733          	or	a4,a4,a3
    55a8:	01889693          	slli	a3,a7,0x18
    55ac:	00e6e333          	or	t1,a3,a4
    55b0:	0ff00693          	li	a3,255
    55b4:	0ff57513          	zext.b	a0,a0
    55b8:	0ff87713          	zext.b	a4,a6
    55bc:	12d80063          	beq	a6,a3,56dc <.L269>
    55c0:	00377813          	andi	a6,a4,3
    55c4:	0dc70713          	addi	a4,a4,220
    55c8:	21684833          	sh2add	a6,a6,s6
    55cc:	00271693          	slli	a3,a4,0x2
    55d0:	00c82023          	sw	a2,0(a6)
    55d4:	ffb30737          	lui	a4,0xffb30

000055d8 <.L270>:
    55d8:	04072883          	lw	a7,64(a4) # ffb30040 <__stack_top+0x2e040>
    55dc:	fe089ee3          	bnez	a7,55d8 <.L270>
    55e0:	0000a8b7          	lui	a7,0xa
    55e4:	1b288893          	addi	a7,a7,434 # a1b2 <__kernel_data_lma+0x2ace>
    55e8:	01172e23          	sw	a7,28(a4)
    55ec:	01072023          	sw	a6,0(a4)
    55f0:	00400813          	li	a6,4
    55f4:	03072023          	sw	a6,32(a4)
    55f8:	004ba803          	lw	a6,4(s7)
    55fc:	00d72623          	sw	a3,12(a4)
    5600:	00072823          	sw	zero,16(a4)
    5604:	008106b7          	lui	a3,0x810
    5608:	07680813          	addi	a6,a6,118
    560c:	2ce68693          	addi	a3,a3,718 # 8102ce <__kernel_data_lma+0x808bea>
    5610:	010ba223          	sw	a6,4(s7)
    5614:	00d72a23          	sw	a3,20(a4)

00005618 <.L271>:
    5618:	0007a703          	lw	a4,0(a5)
    561c:	40670733          	sub	a4,a4,t1
    5620:	00f71693          	slli	a3,a4,0xf
    5624:	fe06cae3          	bltz	a3,5618 <.L271>
    5628:	004a2783          	lw	a5,4(s4)
    562c:	ffb30737          	lui	a4,0xffb30
    5630:	00178793          	addi	a5,a5,1
    5634:	00fa2223          	sw	a5,4(s4)
    5638:	00100793          	li	a5,1
    563c:	04f72023          	sw	a5,64(a4) # ffb30040 <__stack_top+0x2e040>

00005640 <.L272>:
    5640:	00cb2023          	sw	a2,0(s6)
    5644:	00000613          	li	a2,0
    5648:	b80504e3          	beqz	a0,51d0 <.L486>
    564c:	00002337          	lui	t1,0x2
    5650:	100008b7          	lui	a7,0x10000
    5654:	01000837          	lui	a6,0x1000
    5658:	09230313          	addi	t1,t1,146 # 2092 <_start-0x293e>
    565c:	00f88893          	addi	a7,a7,15 # 1000000f <__kernel_data_lma+0xfff892b>
    5660:	fff80813          	addi	a6,a6,-1 # ffffff <__kernel_data_lma+0xff891b>
    5664:	ffb30737          	lui	a4,0xffb30
    5668:	37000f13          	li	t5,880
    566c:	00400e93          	li	t4,4
    5670:	00100e13          	li	t3,1

00005674 <.L273>:
    5674:	00c587b3          	add	a5,a1,a2
    5678:	0ff7f793          	zext.b	a5,a5
    567c:	2157c7b3          	sh2add	a5,a5,s5
    5680:	0487a683          	lw	a3,72(a5)
    5684:	00469693          	slli	a3,a3,0x4

00005688 <.L274>:
    5688:	04072783          	lw	a5,64(a4) # ffb30040 <__stack_top+0x2e040>
    568c:	fe079ee3          	bnez	a5,5688 <.L274>
    5690:	00672e23          	sw	t1,28(a4)
    5694:	01672023          	sw	s6,0(a4)
    5698:	01e72623          	sw	t5,12(a4)
    569c:	0116ffb3          	and	t6,a3,a7
    56a0:	0046d793          	srli	a5,a3,0x4
    56a4:	01f72823          	sw	t6,16(a4)
    56a8:	0107f7b3          	and	a5,a5,a6
    56ac:	004a2683          	lw	a3,4(s4)
    56b0:	00f72a23          	sw	a5,20(a4)
    56b4:	004ba783          	lw	a5,4(s7)
    56b8:	03d72023          	sw	t4,32(a4)
    56bc:	05c72023          	sw	t3,64(a4)
    56c0:	00168693          	addi	a3,a3,1
    56c4:	00178793          	addi	a5,a5,1
    56c8:	00160613          	addi	a2,a2,1
    56cc:	00da2223          	sw	a3,4(s4)
    56d0:	00fba223          	sw	a5,4(s7)
    56d4:	fac510e3          	bne	a0,a2,5674 <.L273>
    56d8:	af9ff06f          	j	51d0 <.L486>

000056dc <.L269>:
    56dc:	0007a703          	lw	a4,0(a5)
    56e0:	40670733          	sub	a4,a4,t1
    56e4:	00f71693          	slli	a3,a4,0xf
    56e8:	f406dce3          	bgez	a3,5640 <.L272>
    56ec:	0007a703          	lw	a4,0(a5)
    56f0:	40670733          	sub	a4,a4,t1
    56f4:	00f71693          	slli	a3,a4,0xf
    56f8:	fe06c2e3          	bltz	a3,56dc <.L269>
    56fc:	f45ff06f          	j	5640 <.L272>

00005700 <.L68>:
    5700:	002b4603          	lbu	a2,2(s6)
    5704:	003b4f83          	lbu	t6,3(s6)
    5708:	004b4683          	lbu	a3,4(s6)
    570c:	005b4703          	lbu	a4,5(s6)
    5710:	006b4583          	lbu	a1,6(s6)
    5714:	007b4783          	lbu	a5,7(s6)
    5718:	008f9f93          	slli	t6,t6,0x8
    571c:	00879793          	slli	a5,a5,0x8
    5720:	00b7e7b3          	or	a5,a5,a1
    5724:	2157c7b3          	sh2add	a5,a5,s5
    5728:	0007a783          	lw	a5,0(a5)
    572c:	01fb0513          	addi	a0,s6,31
    5730:	00cfefb3          	or	t6,t6,a2
    5734:	00871713          	slli	a4,a4,0x8
    5738:	21ffa633          	sh1add	a2,t6,t6
    573c:	20a64533          	sh2add	a0,a2,a0
    5740:	00f12423          	sw	a5,8(sp)
    5744:	00d76733          	or	a4,a4,a3
    5748:	010b0b13          	addi	s6,s6,16
    574c:	08010793          	addi	a5,sp,128
    5750:	00000693          	li	a3,0
    5754:	04060263          	beqz	a2,5798 <.L200>

00005758 <.L199>:
    5758:	000b2e83          	lw	t4,0(s6)
    575c:	004b2e03          	lw	t3,4(s6)
    5760:	008b2303          	lw	t1,8(s6)
    5764:	00cb2883          	lw	a7,12(s6)
    5768:	010b2803          	lw	a6,16(s6)
    576c:	014b2583          	lw	a1,20(s6)
    5770:	00668693          	addi	a3,a3,6
    5774:	018b0b13          	addi	s6,s6,24
    5778:	01878793          	addi	a5,a5,24
    577c:	ffd7a423          	sw	t4,-24(a5)
    5780:	ffc7a623          	sw	t3,-20(a5)
    5784:	fe67a823          	sw	t1,-16(a5)
    5788:	ff17aa23          	sw	a7,-12(a5)
    578c:	ff07ac23          	sw	a6,-8(a5)
    5790:	feb7ae23          	sw	a1,-4(a5)
    5794:	fcc6e2e3          	bltu	a3,a2,5758 <.L199>

00005798 <.L200>:
    5798:	004ba783          	lw	a5,4(s7)
    579c:	fff70713          	addi	a4,a4,-1
    57a0:	00100c13          	li	s8,1
    57a4:	04012623          	sw	zero,76(sp)
    57a8:	04f12823          	sw	a5,80(sp)
    57ac:	00e12a23          	sw	a4,20(sp)
    57b0:	ff057b13          	andi	s6,a0,-16
    57b4:	000c0693          	mv	a3,s8
    57b8:	08010f13          	addi	t5,sp,128
    57bc:	240f8663          	beqz	t6,5a08 <.L198>
    57c0:	00002537          	lui	a0,0x2
    57c4:	000015b7          	lui	a1,0x1
    57c8:	10000737          	lui	a4,0x10000
    57cc:	010007b7          	lui	a5,0x1000
    57d0:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    57d4:	fff78793          	addi	a5,a5,-1 # ffffff <__kernel_data_lma+0xff891b>
    57d8:	00004637          	lui	a2,0x4
    57dc:	ffff83b7          	lui	t2,0xffff8
    57e0:	0000a837          	lui	a6,0xa
    57e4:	09150513          	addi	a0,a0,145 # 2091 <_start-0x293f>
    57e8:	00f70713          	addi	a4,a4,15 # 1000000f <__kernel_data_lma+0xfff892b>
    57ec:	00b12e23          	sw	a1,28(sp)
    57f0:	02f12623          	sw	a5,44(sp)
    57f4:	fff60e13          	addi	t3,a2,-1 # 3fff <_start-0x9d1>
    57f8:	fff38493          	addi	s1,t2,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    57fc:	1b280913          	addi	s2,a6,434 # a1b2 <__kernel_data_lma+0x2ace>
    5800:	00a12c23          	sw	a0,24(sp)
    5804:	02e12023          	sw	a4,32(sp)
    5808:	ffb307b7          	lui	a5,0xffb30
    580c:	000c0593          	mv	a1,s8
    5810:	ffffc437          	lui	s0,0xffffc
    5814:	00008eb7          	lui	t4,0x8

00005818 <.L257>:
    5818:	00af4703          	lbu	a4,10(t5)
    581c:	008f5503          	lhu	a0,8(t5)
    5820:	01412883          	lw	a7,20(sp)
    5824:	004f2803          	lw	a6,4(t5)
    5828:	04e12e23          	sw	a4,92(sp)
    582c:	00812703          	lw	a4,8(sp)
    5830:	011562b3          	or	t0,a0,a7
    5834:	40a282b3          	sub	t0,t0,a0
    5838:	00bf4c83          	lbu	s9,11(t5)
    583c:	00150513          	addi	a0,a0,1
    5840:	01070833          	add	a6,a4,a6
    5844:	00068463          	beqz	a3,584c <.L257+0x34>
    5848:	6b80106f          	j	6f00 <.L500>
    584c:	010aad03          	lw	s10,16(s5)
    5850:	00cf0f13          	addi	t5,t5,12
    5854:	3f6d04e3          	beq	s10,s6,643c <.L203>
    5858:	416d0333          	sub	t1,s10,s6
    585c:	44a36ce3          	bltu	t1,a0,64b4 <.L501>

00005860 <.L205>:
    5860:	001cf713          	andi	a4,s9,1
    5864:	00070c93          	mv	s9,a4
    5868:	00070463          	beqz	a4,5870 <.L205+0x10>
    586c:	4ac0106f          	j	6d18 <.L502>
    5870:	020c0e63          	beqz	s8,58ac <.L238>
    5874:	04c12883          	lw	a7,76(sp)
    5878:	05c12683          	lw	a3,92(sp)
    587c:	05012703          	lw	a4,80(sp)
    5880:	02d886b3          	mul	a3,a7,a3
    5884:	04012623          	sw	zero,76(sp)
    5888:	00e686b3          	add	a3,a3,a4
    588c:	004a2703          	lw	a4,4(s4)
    5890:	04d12823          	sw	a3,80(sp)
    5894:	01170733          	add	a4,a4,a7
    5898:	00dba223          	sw	a3,4(s7)
    589c:	00ea2223          	sw	a4,4(s4)

000058a0 <.L239>:
    58a0:	2047a703          	lw	a4,516(a5) # ffb30204 <__stack_top+0x2e204>
    58a4:	fee69ee3          	bne	a3,a4,58a0 <.L239>
    58a8:	0ff0000f          	fence

000058ac <.L238>:
    58ac:	00050693          	mv	a3,a0
    58b0:	000b0c13          	mv	s8,s6
    58b4:	08a67263          	bgeu	a2,a0,5938 <.L246>

000058b8 <.L242>:
    58b8:	0407a703          	lw	a4,64(a5)
    58bc:	fe071ee3          	bnez	a4,58b8 <.L242>
    58c0:	0167a023          	sw	s6,0(a5)
    58c4:	02c7a023          	sw	a2,32(a5)
    58c8:	0107a623          	sw	a6,12(a5)
    58cc:	04b7a023          	sw	a1,64(a5)
    58d0:	40c506b3          	sub	a3,a0,a2
    58d4:	00cb0c33          	add	s8,s6,a2
    58d8:	00d66463          	bltu	a2,a3,58e0 <.L242+0x28>
    58dc:	67c0106f          	j	6f58 <.L503>
    58e0:	00950d33          	add	s10,a0,s1
    58e4:	008d7db3          	and	s11,s10,s0
    58e8:	01dd8333          	add	t1,s11,t4
    58ec:	01630333          	add	t1,t1,s6
    58f0:	000c0693          	mv	a3,s8
    58f4:	416808b3          	sub	a7,a6,s6

000058f8 <.L244>:
    58f8:	0407a703          	lw	a4,64(a5)
    58fc:	fe071ee3          	bnez	a4,58f8 <.L244>
    5900:	00d7a023          	sw	a3,0(a5)
    5904:	00d88733          	add	a4,a7,a3
    5908:	00e7a623          	sw	a4,12(a5)
    590c:	04b7a023          	sw	a1,64(a5)
    5910:	00c686b3          	add	a3,a3,a2
    5914:	fe6692e3          	bne	a3,t1,58f8 <.L244>
    5918:	00ed5d13          	srli	s10,s10,0xe
    591c:	00ed1713          	slli	a4,s10,0xe
    5920:	00cd8db3          	add	s11,s11,a2
    5924:	01d80833          	add	a6,a6,t4
    5928:	007506b3          	add	a3,a0,t2
    592c:	01bc0c33          	add	s8,s8,s11
    5930:	00e80833          	add	a6,a6,a4
    5934:	40e686b3          	sub	a3,a3,a4

00005938 <.L246>:
    5938:	0407a703          	lw	a4,64(a5)
    593c:	fe071ee3          	bnez	a4,5938 <.L246>

00005940 <.L520>:
    5940:	0187a023          	sw	s8,0(a5)
    5944:	02d7a023          	sw	a3,32(a5)
    5948:	0107a623          	sw	a6,12(a5)
    594c:	04b7a023          	sw	a1,64(a5)
    5950:	00000c13          	li	s8,0

00005954 <.L236>:
    5954:	04c12683          	lw	a3,76(sp)
    5958:	01c50733          	add	a4,a0,t3
    595c:	00e75713          	srli	a4,a4,0xe
    5960:	00ab0b33          	add	s6,s6,a0
    5964:	00d70733          	add	a4,a4,a3

00005968 <.L224>:
    5968:	05c12503          	lw	a0,92(sp)
    596c:	05012683          	lw	a3,80(sp)
    5970:	02a70533          	mul	a0,a4,a0
    5974:	04012623          	sw	zero,76(sp)
    5978:	00a686b3          	add	a3,a3,a0
    597c:	04d12823          	sw	a3,80(sp)
    5980:	004a2683          	lw	a3,4(s4)
    5984:	010aa503          	lw	a0,16(s5)
    5988:	00d70733          	add	a4,a4,a3
    598c:	00ea2223          	sw	a4,4(s4)
    5990:	41650833          	sub	a6,a0,s6
    5994:	0ffcf693          	zext.b	a3,s9
    5998:	06587063          	bgeu	a6,t0,59f8 <.L247>
    599c:	024aa883          	lw	a7,36(s5)
    59a0:	2158c833          	sh2add	a6,a7,s5
    59a4:	01482803          	lw	a6,20(a6)
    59a8:	01051463          	bne	a0,a6,59b0 <.L224+0x48>
    59ac:	5c00106f          	j	6f6c <.L248>
    59b0:	00012703          	lw	a4,0(sp)
    59b4:	00072803          	lw	a6,0(a4)

000059b8 <.L249>:
    59b8:	02caa503          	lw	a0,44(s5)
    59bc:	028aa703          	lw	a4,40(s5)
    59c0:	4ee502e3          	beq	a0,a4,66a4 <.L256>

000059c4 <.L255>:
    59c4:	024aa883          	lw	a7,36(s5)
    59c8:	010aa803          	lw	a6,16(s5)
    59cc:	2158c8b3          	sh2add	a7,a7,s5
    59d0:	0148a883          	lw	a7,20(a7)
    59d4:	40a70733          	sub	a4,a4,a0
    59d8:	410888b3          	sub	a7,a7,a6
    59dc:	00c8d893          	srli	a7,a7,0xc
    59e0:	0ae8d733          	minu	a4,a7,a4
    59e4:	00c71893          	slli	a7,a4,0xc
    59e8:	00a70733          	add	a4,a4,a0
    59ec:	01088533          	add	a0,a7,a6
    59f0:	00aaa823          	sw	a0,16(s5)
    59f4:	02eaa623          	sw	a4,44(s5)

000059f8 <.L247>:
    59f8:	ffff8f93          	addi	t6,t6,-1
    59fc:	005b0b33          	add	s6,s6,t0
    5a00:	e00f9ce3          	bnez	t6,5818 <.L257>
    5a04:	05012783          	lw	a5,80(sp)

00005a08 <.L198>:
    5a08:	00fba223          	sw	a5,4(s7)
    5a0c:	fd0ff06f          	j	51dc <.L74>

00005a10 <.L67>:
    5a10:	001b4703          	lbu	a4,1(s6)
    5a14:	008b4603          	lbu	a2,8(s6)
    5a18:	009b4683          	lbu	a3,9(s6)
    5a1c:	00ab4783          	lbu	a5,10(s6)
    5a20:	00869693          	slli	a3,a3,0x8
    5a24:	00bb4803          	lbu	a6,11(s6)
    5a28:	00c6e6b3          	or	a3,a3,a2
    5a2c:	002b4583          	lbu	a1,2(s6)
    5a30:	01079793          	slli	a5,a5,0x10
    5a34:	003b4603          	lbu	a2,3(s6)
    5a38:	00d7e7b3          	or	a5,a5,a3
    5a3c:	01881813          	slli	a6,a6,0x18
    5a40:	00f86833          	or	a6,a6,a5
    5a44:	00861793          	slli	a5,a2,0x8
    5a48:	00177613          	andi	a2,a4,1
    5a4c:	00277513          	andi	a0,a4,2
    5a50:	01077893          	andi	a7,a4,16
    5a54:	00477693          	andi	a3,a4,4
    5a58:	00b7e7b3          	or	a5,a5,a1
    5a5c:	00877713          	andi	a4,a4,8
    5a60:	00060c63          	beqz	a2,5a78 <.L258>
    5a64:	004ba583          	lw	a1,4(s7)
    5a68:	ffb30637          	lui	a2,0xffb30

00005a6c <.L259>:
    5a6c:	20462303          	lw	t1,516(a2) # ffb30204 <__stack_top+0x2e204>
    5a70:	feb31ee3          	bne	t1,a1,5a6c <.L259>
    5a74:	0ff0000f          	fence

00005a78 <.L258>:
    5a78:	02068e63          	beqz	a3,5ab4 <.L264>
    5a7c:	004b4683          	lbu	a3,4(s6)
    5a80:	005b4583          	lbu	a1,5(s6)
    5a84:	006b4603          	lbu	a2,6(s6)
    5a88:	00859593          	slli	a1,a1,0x8
    5a8c:	00d5e5b3          	or	a1,a1,a3
    5a90:	007b4683          	lbu	a3,7(s6)
    5a94:	01061613          	slli	a2,a2,0x10
    5a98:	00b66633          	or	a2,a2,a1
    5a9c:	01869693          	slli	a3,a3,0x18
    5aa0:	00c6e6b3          	or	a3,a3,a2

00005aa4 <.L263>:
    5aa4:	0ff0000f          	fence
    5aa8:	0006a603          	lw	a2,0(a3)
    5aac:	41060633          	sub	a2,a2,a6
    5ab0:	fe064ae3          	bltz	a2,5aa4 <.L263>

00005ab4 <.L264>:
    5ab4:	02070263          	beqz	a4,5ad8 <.L262>
    5ab8:	ffb406b7          	lui	a3,0xffb40
    5abc:	4a468693          	addi	a3,a3,1188 # ffb404a4 <__stack_top+0x3e4a4>
    5ac0:	00c79713          	slli	a4,a5,0xc
    5ac4:	00d70733          	add	a4,a4,a3

00005ac8 <.L265>:
    5ac8:	00072683          	lw	a3,0(a4)
    5acc:	410686b3          	sub	a3,a3,a6
    5ad0:	00f69613          	slli	a2,a3,0xf
    5ad4:	fe064ae3          	bltz	a2,5ac8 <.L265>

00005ad8 <.L262>:
    5ad8:	02088663          	beqz	a7,5b04 <.L266>
    5adc:	ffb406b7          	lui	a3,0xffb40
    5ae0:	00c79793          	slli	a5,a5,0xc
    5ae4:	4a468713          	addi	a4,a3,1188 # ffb404a4 <__stack_top+0x3e4a4>
    5ae8:	00e78733          	add	a4,a5,a4
    5aec:	00072703          	lw	a4,0(a4)
    5af0:	43868693          	addi	a3,a3,1080
    5af4:	40e00733          	neg	a4,a4
    5af8:	00671713          	slli	a4,a4,0x6
    5afc:	00d787b3          	add	a5,a5,a3
    5b00:	00e7a023          	sw	a4,0(a5)

00005b04 <.L266>:
    5b04:	ec050663          	beqz	a0,51d0 <.L486>
    5b08:	00012783          	lw	a5,0(sp)
    5b0c:	ffb22737          	lui	a4,0xffb22
    5b10:	0007a783          	lw	a5,0(a5)
    5b14:	02078793          	addi	a5,a5,32

00005b18 <.L268>:
    5b18:	84072683          	lw	a3,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    5b1c:	fe069ee3          	bnez	a3,5b18 <.L268>
    5b20:	80f72023          	sw	a5,-2048(a4)
    5b24:	000016b7          	lui	a3,0x1
    5b28:	0027d793          	srli	a5,a5,0x2
    5b2c:	07c68693          	addi	a3,a3,124 # 107c <_start-0x3954>
    5b30:	0037f793          	andi	a5,a5,3
    5b34:	80072223          	sw	zero,-2044(a4)
    5b38:	00d7e7b3          	or	a5,a5,a3
    5b3c:	08e00693          	li	a3,142
    5b40:	80d72423          	sw	a3,-2040(a4)
    5b44:	000026b7          	lui	a3,0x2
    5b48:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    5b4c:	80d72e23          	sw	a3,-2020(a4)
    5b50:	82f72023          	sw	a5,-2016(a4)
    5b54:	00100793          	li	a5,1
    5b58:	82f72423          	sw	a5,-2008(a4)
    5b5c:	84f72023          	sw	a5,-1984(a4)
    5b60:	00412703          	lw	a4,4(sp)
    5b64:	00072783          	lw	a5,0(a4)
    5b68:	00178793          	addi	a5,a5,1
    5b6c:	00f72023          	sw	a5,0(a4)
    5b70:	e60ff06f          	j	51d0 <.L486>

00005b74 <.L70>:
    5b74:	001b4703          	lbu	a4,1(s6)
    5b78:	0027c583          	lbu	a1,2(a5)
    5b7c:	0037c603          	lbu	a2,3(a5)
    5b80:	0047c503          	lbu	a0,4(a5)
    5b84:	0057c683          	lbu	a3,5(a5)
    5b88:	010b0b13          	addi	s6,s6,16
    5b8c:	58070ee3          	beqz	a4,6928 <.L110>
    5b90:	0067c703          	lbu	a4,6(a5)
    5b94:	00869693          	slli	a3,a3,0x8
    5b98:	0077c303          	lbu	t1,7(a5)
    5b9c:	00a6e6b3          	or	a3,a3,a0
    5ba0:	01071713          	slli	a4,a4,0x10
    5ba4:	00861613          	slli	a2,a2,0x8
    5ba8:	00d76733          	or	a4,a4,a3
    5bac:	00b66633          	or	a2,a2,a1
    5bb0:	01831313          	slli	t1,t1,0x18
    5bb4:	0087c583          	lbu	a1,8(a5)
    5bb8:	0097c683          	lbu	a3,9(a5)
    5bbc:	00e36333          	or	t1,t1,a4
    5bc0:	00a7c703          	lbu	a4,10(a5)
    5bc4:	00869693          	slli	a3,a3,0x8
    5bc8:	00b7c503          	lbu	a0,11(a5)
    5bcc:	00b6e6b3          	or	a3,a3,a1
    5bd0:	01071713          	slli	a4,a4,0x10
    5bd4:	00c7c583          	lbu	a1,12(a5)
    5bd8:	00d76733          	or	a4,a4,a3
    5bdc:	00d7c683          	lbu	a3,13(a5)
    5be0:	01851513          	slli	a0,a0,0x18
    5be4:	00e56533          	or	a0,a0,a4
    5be8:	00869693          	slli	a3,a3,0x8
    5bec:	00e7c703          	lbu	a4,14(a5)
    5bf0:	00b6e6b3          	or	a3,a3,a1
    5bf4:	00f7c583          	lbu	a1,15(a5)
    5bf8:	01071793          	slli	a5,a4,0x10
    5bfc:	00d7e7b3          	or	a5,a5,a3
    5c00:	01859593          	slli	a1,a1,0x18
    5c04:	00f5e5b3          	or	a1,a1,a5
    5c08:	02b505b3          	mul	a1,a0,a1
    5c0c:	dc058863          	beqz	a1,51dc <.L74>
    5c10:	fff50893          	addi	a7,a0,-1
    5c14:	010aa683          	lw	a3,16(s5)
    5c18:	03f8e893          	ori	a7,a7,63
    5c1c:	ffb00fb7          	lui	t6,0xffb00
    5c20:	ffb00f37          	lui	t5,0xffb00
    5c24:	92492eb7          	lui	t4,0x92492
    5c28:	00002e37          	lui	t3,0x2
    5c2c:	00188893          	addi	a7,a7,1
    5c30:	644f8f93          	addi	t6,t6,1604 # ffb00644 <bank_to_dram_offset>
    5c34:	448f0f13          	addi	t5,t5,1096 # ffb00448 <dram_bank_to_noc_xy>
    5c38:	493e8e93          	addi	t4,t4,1171 # 92492493 <__kernel_data_lma+0x9248adaf>
    5c3c:	092e0e13          	addi	t3,t3,146 # 2092 <_start-0x293e>
    5c40:	00000813          	li	a6,0
    5c44:	00300413          	li	s0,3
    5c48:	000043b7          	lui	t2,0x4
    5c4c:	ffb30737          	lui	a4,0xffb30
    5c50:	00100293          	li	t0,1
    5c54:	0b668863          	beq	a3,s6,5d04 <.L504>

00005c58 <.L112>:
    5c58:	03d63c33          	mulhu	s8,a2,t4
    5c5c:	010307b3          	add	a5,t1,a6
    5c60:	002c5c13          	srli	s8,s8,0x2
    5c64:	03888933          	mul	s2,a7,s8
    5c68:	410504b3          	sub	s1,a0,a6
    5c6c:	00f90933          	add	s2,s2,a5
    5c70:	0a74d7b3          	minu	a5,s1,t2
    5c74:	416686b3          	sub	a3,a3,s6
    5c78:	0af6d6b3          	minu	a3,a3,a5
    5c7c:	003c1793          	slli	a5,s8,0x3
    5c80:	418787b3          	sub	a5,a5,s8
    5c84:	40f607b3          	sub	a5,a2,a5
    5c88:	21f7cc33          	sh2add	s8,a5,t6
    5c8c:	21e7a7b3          	sh1add	a5,a5,t5
    5c90:	000c2c03          	lw	s8,0(s8)
    5c94:	00e7d783          	lhu	a5,14(a5)
    5c98:	01890933          	add	s2,s2,s8
    5c9c:	00479c13          	slli	s8,a5,0x4

00005ca0 <.L122>:
    5ca0:	04072783          	lw	a5,64(a4) # ffb30040 <__stack_top+0x2e040>
    5ca4:	fe079ee3          	bnez	a5,5ca0 <.L122>
    5ca8:	01c72e23          	sw	t3,28(a4)
    5cac:	01672023          	sw	s6,0(a4)
    5cb0:	01272623          	sw	s2,12(a4)
    5cb4:	00072823          	sw	zero,16(a4)
    5cb8:	004c5793          	srli	a5,s8,0x4
    5cbc:	004a2903          	lw	s2,4(s4)
    5cc0:	00f72a23          	sw	a5,20(a4)
    5cc4:	004ba783          	lw	a5,4(s7)
    5cc8:	02d72023          	sw	a3,32(a4)
    5ccc:	04572023          	sw	t0,64(a4)
    5cd0:	00190913          	addi	s2,s2,1 # ffffc001 <__instrn_buffer+0x1bc001>
    5cd4:	00178793          	addi	a5,a5,1
    5cd8:	012a2223          	sw	s2,4(s4)
    5cdc:	00fba223          	sw	a5,4(s7)
    5ce0:	00d80833          	add	a6,a6,a3
    5ce4:	0096e663          	bltu	a3,s1,5cf0 <.L124>
    5ce8:	00160613          	addi	a2,a2,1
    5cec:	00000813          	li	a6,0

00005cf0 <.L124>:
    5cf0:	40d585b3          	sub	a1,a1,a3
    5cf4:	00db0b33          	add	s6,s6,a3
    5cf8:	ce058263          	beqz	a1,51dc <.L74>
    5cfc:	010aa683          	lw	a3,16(s5)
    5d00:	f5669ce3          	bne	a3,s6,5c58 <.L112>

00005d04 <.L504>:
    5d04:	024aa783          	lw	a5,36(s5)
    5d08:	2157c6b3          	sh2add	a3,a5,s5
    5d0c:	0146a683          	lw	a3,20(a3)
    5d10:	01669463          	bne	a3,s6,5d18 <.L504+0x14>
    5d14:	6380106f          	j	734c <.L113>
    5d18:	00012783          	lw	a5,0(sp)
    5d1c:	0007a483          	lw	s1,0(a5)

00005d20 <.L114>:
    5d20:	02caa903          	lw	s2,44(s5)
    5d24:	028aa683          	lw	a3,40(s5)
    5d28:	00d91463          	bne	s2,a3,5d30 <.L120>
    5d2c:	2fc0106f          	j	7028 <.L121>

00005d30 <.L120>:
    5d30:	024aa783          	lw	a5,36(s5)
    5d34:	010aa483          	lw	s1,16(s5)
    5d38:	2157c7b3          	sh2add	a5,a5,s5
    5d3c:	0147a783          	lw	a5,20(a5)
    5d40:	412686b3          	sub	a3,a3,s2
    5d44:	409787b3          	sub	a5,a5,s1
    5d48:	00c7d793          	srli	a5,a5,0xc
    5d4c:	0ad7d7b3          	minu	a5,a5,a3
    5d50:	00c79693          	slli	a3,a5,0xc
    5d54:	009686b3          	add	a3,a3,s1
    5d58:	012787b3          	add	a5,a5,s2
    5d5c:	00daa823          	sw	a3,16(s5)
    5d60:	02faa623          	sw	a5,44(s5)
    5d64:	ef5ff06f          	j	5c58 <.L112>

00005d68 <.L61>:
    5d68:	004b4683          	lbu	a3,4(s6)
    5d6c:	005b4783          	lbu	a5,5(s6)
    5d70:	006b4703          	lbu	a4,6(s6)
    5d74:	00879793          	slli	a5,a5,0x8
    5d78:	00d7e7b3          	or	a5,a5,a3
    5d7c:	007b4683          	lbu	a3,7(s6)
    5d80:	01071713          	slli	a4,a4,0x10
    5d84:	00f76733          	or	a4,a4,a5
    5d88:	01869693          	slli	a3,a3,0x18
    5d8c:	00e6e6b3          	or	a3,a3,a4
    5d90:	010b0793          	addi	a5,s6,16
    5d94:	02068863          	beqz	a3,5dc4 <.L276>
    5d98:	ffb01637          	lui	a2,0xffb01
    5d9c:	20f6c533          	sh2add	a0,a3,a5
    5da0:	91860613          	addi	a2,a2,-1768 # ffb00918 <_ZL18go_signal_noc_data>

00005da4 <.L277>:
    5da4:	0007a583          	lw	a1,0(a5)
    5da8:	41678733          	sub	a4,a5,s6
    5dac:	00e60733          	add	a4,a2,a4
    5db0:	00478793          	addi	a5,a5,4
    5db4:	feb72823          	sw	a1,-16(a4)
    5db8:	fea796e3          	bne	a5,a0,5da4 <.L277>
    5dbc:	2166c6b3          	sh2add	a3,a3,s6
    5dc0:	01068793          	addi	a5,a3,16

00005dc4 <.L276>:
    5dc4:	00f78793          	addi	a5,a5,15
    5dc8:	ff07fb13          	andi	s6,a5,-16
    5dcc:	c10ff06f          	j	51dc <.L74>

00005dd0 <.L69>:
    5dd0:	001b4583          	lbu	a1,1(s6)
    5dd4:	002b4603          	lbu	a2,2(s6)
    5dd8:	010b0693          	addi	a3,s6,16
    5ddc:	0015f713          	andi	a4,a1,1
    5de0:	0e0708e3          	beqz	a4,66d0 <.L141>
    5de4:	003b4703          	lbu	a4,3(s6)
    5de8:	00871713          	slli	a4,a4,0x8
    5dec:	00c76733          	or	a4,a4,a2
    5df0:	00371513          	slli	a0,a4,0x3
    5df4:	00171893          	slli	a7,a4,0x1
    5df8:	04070a63          	beqz	a4,5e4c <.L142>
    5dfc:	08010613          	addi	a2,sp,128
    5e00:	00000813          	li	a6,0

00005e04 <.L143>:
    5e04:	0006a283          	lw	t0,0(a3)
    5e08:	0046af83          	lw	t6,4(a3)
    5e0c:	0086af03          	lw	t5,8(a3)
    5e10:	00c6ae83          	lw	t4,12(a3)
    5e14:	0106ae03          	lw	t3,16(a3)
    5e18:	0146a303          	lw	t1,20(a3)
    5e1c:	00680813          	addi	a6,a6,6
    5e20:	01868693          	addi	a3,a3,24
    5e24:	01860613          	addi	a2,a2,24
    5e28:	fe562423          	sw	t0,-24(a2)
    5e2c:	fff62623          	sw	t6,-20(a2)
    5e30:	ffe62823          	sw	t5,-16(a2)
    5e34:	ffd62a23          	sw	t4,-12(a2)
    5e38:	ffc62c23          	sw	t3,-8(a2)
    5e3c:	fe662e23          	sw	t1,-4(a2)
    5e40:	fd1862e3          	bltu	a6,a7,5e04 <.L143>
    5e44:	ffb016b7          	lui	a3,0xffb01
    5e48:	8cc6ab03          	lw	s6,-1844(a3) # ffb008cc <_ZL7cmd_ptr>

00005e4c <.L142>:
    5e4c:	0067ce03          	lbu	t3,6(a5)
    5e50:	0077c803          	lbu	a6,7(a5)
    5e54:	0047c883          	lbu	a7,4(a5)
    5e58:	0057c683          	lbu	a3,5(a5)
    5e5c:	01f50613          	addi	a2,a0,31
    5e60:	00869693          	slli	a3,a3,0x8
    5e64:	01660633          	add	a2,a2,s6
    5e68:	0116e6b3          	or	a3,a3,a7
    5e6c:	0087c303          	lbu	t1,8(a5)
    5e70:	2156c6b3          	sh2add	a3,a3,s5
    5e74:	ff067b13          	andi	s6,a2,-16
    5e78:	0097c603          	lbu	a2,9(a5)
    5e7c:	0006a883          	lw	a7,0(a3)
    5e80:	00a7c683          	lbu	a3,10(a5)
    5e84:	00881513          	slli	a0,a6,0x8
    5e88:	00861613          	slli	a2,a2,0x8
    5e8c:	00b7c803          	lbu	a6,11(a5)
    5e90:	00666633          	or	a2,a2,t1
    5e94:	01069793          	slli	a5,a3,0x10
    5e98:	00c7e7b3          	or	a5,a5,a2
    5e9c:	01881813          	slli	a6,a6,0x18
    5ea0:	00f86833          	or	a6,a6,a5
    5ea4:	0025f593          	andi	a1,a1,2
    5ea8:	01c56533          	or	a0,a0,t3
    5eac:	01180833          	add	a6,a6,a7
    5eb0:	00000313          	li	t1,0
    5eb4:	00059463          	bnez	a1,5ebc <.L144>
    5eb8:	7340106f          	j	75ec <.L505>

00005ebc <.L144>:
    5ebc:	ffb307b7          	lui	a5,0xffb30

00005ec0 <.L145>:
    5ec0:	0407a683          	lw	a3,64(a5) # ffb30040 <__stack_top+0x2e040>
    5ec4:	fe069ee3          	bnez	a3,5ec0 <.L145>
    5ec8:	0000a6b7          	lui	a3,0xa
    5ecc:	1b268693          	addi	a3,a3,434 # a1b2 <__kernel_data_lma+0x2ace>
    5ed0:	00d7ae23          	sw	a3,28(a5)
    5ed4:	02a7a023          	sw	a0,32(a5)
    5ed8:	0107a623          	sw	a6,12(a5)
    5edc:	04c10693          	addi	a3,sp,76
    5ee0:	05010793          	addi	a5,sp,80
    5ee4:	04012623          	sw	zero,76(sp)
    5ee8:	04012823          	sw	zero,80(sp)
    5eec:	04d12e23          	sw	a3,92(sp)
    5ef0:	06f12023          	sw	a5,96(sp)
    5ef4:	00000893          	li	a7,0
    5ef8:	00071463          	bnez	a4,5f00 <.L145+0x40>
    5efc:	3a40106f          	j	72a0 <.L146>
    5f00:	10000f37          	lui	t5,0x10000
    5f04:	01000eb7          	lui	t4,0x1000
    5f08:	fff70713          	addi	a4,a4,-1
    5f0c:	00ff0f13          	addi	t5,t5,15 # 1000000f <__kernel_data_lma+0xfff892b>
    5f10:	fffe8e93          	addi	t4,t4,-1 # ffffff <__kernel_data_lma+0xff891b>
    5f14:	08010e13          	addi	t3,sp,128
    5f18:	ffb307b7          	lui	a5,0xffb30
    5f1c:	00100f93          	li	t6,1
    5f20:	05c10393          	addi	t2,sp,92
    5f24:	00300293          	li	t0,3

00005f28 <.L167>:
    5f28:	010aa903          	lw	s2,16(s5)
    5f2c:	000e2583          	lw	a1,0(t3)
    5f30:	416904b3          	sub	s1,s2,s6
    5f34:	004e2403          	lw	s0,4(t3)
    5f38:	00459593          	slli	a1,a1,0x4
    5f3c:	008e0e13          	addi	t3,t3,8
    5f40:	06a4f863          	bgeu	s1,a0,5fb0 <.L147>
    5f44:	024aa883          	lw	a7,36(s5)
    5f48:	06712623          	sw	t2,108(sp)
    5f4c:	2158c6b3          	sh2add	a3,a7,s5
    5f50:	0146a683          	lw	a3,20(a3)
    5f54:	00d91463          	bne	s2,a3,5f5c <.L167+0x34>
    5f58:	1f40106f          	j	714c <.L148>
    5f5c:	00012683          	lw	a3,0(sp)
    5f60:	00000493          	li	s1,0
    5f64:	0006a883          	lw	a7,0(a3)

00005f68 <.L149>:
    5f68:	02caa603          	lw	a2,44(s5)
    5f6c:	028aa683          	lw	a3,40(s5)
    5f70:	3ad60ae3          	beq	a2,a3,6b24 <.L160>

00005f74 <.L159>:
    5f74:	024aa883          	lw	a7,36(s5)
    5f78:	010aa903          	lw	s2,16(s5)
    5f7c:	2158c8b3          	sh2add	a7,a7,s5
    5f80:	0148a883          	lw	a7,20(a7)
    5f84:	40c686b3          	sub	a3,a3,a2
    5f88:	412888b3          	sub	a7,a7,s2
    5f8c:	00c8d893          	srli	a7,a7,0xc
    5f90:	0ad8d6b3          	minu	a3,a7,a3
    5f94:	00c69893          	slli	a7,a3,0xc
    5f98:	00c686b3          	add	a3,a3,a2
    5f9c:	01288633          	add	a2,a7,s2
    5fa0:	00caa823          	sw	a2,16(s5)
    5fa4:	02daa623          	sw	a3,44(s5)
    5fa8:	00048463          	beqz	s1,5fb0 <.L147>
    5fac:	2580106f          	j	7204 <.L506>

00005fb0 <.L147>:
    5fb0:	05c12883          	lw	a7,92(sp)
    5fb4:	004a2683          	lw	a3,4(s4)
    5fb8:	0008a483          	lw	s1,0(a7)
    5fbc:	06012603          	lw	a2,96(sp)
    5fc0:	009686b3          	add	a3,a3,s1
    5fc4:	00da2223          	sw	a3,4(s4)
    5fc8:	00062483          	lw	s1,0(a2)
    5fcc:	004ba683          	lw	a3,4(s7)
    5fd0:	009686b3          	add	a3,a3,s1
    5fd4:	00dba223          	sw	a3,4(s7)
    5fd8:	0008a023          	sw	zero,0(a7)
    5fdc:	00062023          	sw	zero,0(a2)
    5fe0:	004ba603          	lw	a2,4(s7)

00005fe4 <.L165>:
    5fe4:	2047a683          	lw	a3,516(a5) # ffb30204 <__stack_top+0x2e204>
    5fe8:	fec69ee3          	bne	a3,a2,5fe4 <.L165>
    5fec:	0ff0000f          	fence

00005ff0 <.L166>:
    5ff0:	0407a683          	lw	a3,64(a5)
    5ff4:	fe069ee3          	bnez	a3,5ff0 <.L166>
    5ff8:	0167a023          	sw	s6,0(a5)
    5ffc:	01e5f633          	and	a2,a1,t5
    6000:	0045d693          	srli	a3,a1,0x4
    6004:	00c7a823          	sw	a2,16(a5)
    6008:	01d6f6b3          	and	a3,a3,t4
    600c:	00d7aa23          	sw	a3,20(a5)
    6010:	05f7a023          	sw	t6,64(a5)
    6014:	04c12683          	lw	a3,76(sp)
    6018:	05012603          	lw	a2,80(sp)
    601c:	00168693          	addi	a3,a3,1
    6020:	00c408b3          	add	a7,s0,a2
    6024:	04d12623          	sw	a3,76(sp)
    6028:	05112823          	sw	a7,80(sp)
    602c:	006b0b33          	add	s6,s6,t1
    6030:	00071463          	bnez	a4,6038 <.L304>
    6034:	2680106f          	j	729c <.L507>

00006038 <.L304>:
    6038:	fff70713          	addi	a4,a4,-1
    603c:	eedff06f          	j	5f28 <.L167>

00006040 <.L71>:
    6040:	008b4683          	lbu	a3,8(s6)
    6044:	009b4703          	lbu	a4,9(s6)
    6048:	00ab4783          	lbu	a5,10(s6)
    604c:	00871713          	slli	a4,a4,0x8
    6050:	00d76733          	or	a4,a4,a3
    6054:	00bb4683          	lbu	a3,11(s6)
    6058:	01079793          	slli	a5,a5,0x10
    605c:	00cb4603          	lbu	a2,12(s6)
    6060:	00e7e7b3          	or	a5,a5,a4
    6064:	01869713          	slli	a4,a3,0x18
    6068:	00db4683          	lbu	a3,13(s6)
    606c:	00f76733          	or	a4,a4,a5
    6070:	00eb4783          	lbu	a5,14(s6)
    6074:	00869693          	slli	a3,a3,0x8
    6078:	00c6e6b3          	or	a3,a3,a2
    607c:	01079793          	slli	a5,a5,0x10
    6080:	00d7e7b3          	or	a5,a5,a3
    6084:	00fb4683          	lbu	a3,15(s6)
    6088:	001b4603          	lbu	a2,1(s6)
    608c:	01869693          	slli	a3,a3,0x18
    6090:	00f6ef33          	or	t5,a3,a5
    6094:	ffb307b7          	lui	a5,0xffb30

00006098 <.L75>:
    6098:	0407a683          	lw	a3,64(a5) # ffb30040 <__stack_top+0x2e040>
    609c:	fe069ee3          	bnez	a3,6098 <.L75>
    60a0:	000026b7          	lui	a3,0x2
    60a4:	09268693          	addi	a3,a3,146 # 2092 <_start-0x293e>
    60a8:	00d7ae23          	sw	a3,28(a5)
    60ac:	100006b7          	lui	a3,0x10000
    60b0:	00d7a823          	sw	a3,16(a5)
    60b4:	61300693          	li	a3,1555
    60b8:	00d7aa23          	sw	a3,20(a5)
    60bc:	01e767b3          	or	a5,a4,t5
    60c0:	90078e63          	beqz	a5,51dc <.L74>
    60c4:	ba008637          	lui	a2,0xba008
    60c8:	ba0007b7          	lui	a5,0xba000
    60cc:	80000537          	lui	a0,0x80000
    60d0:	ba0045b7          	lui	a1,0xba004
    60d4:	460046b7          	lui	a3,0x46004
    60d8:	00001837          	lui	a6,0x1
    60dc:	f0060613          	addi	a2,a2,-256 # ba007f00 <__kernel_data_lma+0xba00081c>
    60e0:	f0078793          	addi	a5,a5,-256 # b9ffff00 <__kernel_data_lma+0xb9ff881c>
    60e4:	fff80413          	addi	s0,a6,-1 # fff <_start-0x39d1>
    60e8:	fff50513          	addi	a0,a0,-1 # 7fffffff <__kernel_data_lma+0x7fff891b>
    60ec:	f0058d13          	addi	s10,a1,-256 # ba003f00 <__kernel_data_lma+0xb9ffc81c>
    60f0:	02c12023          	sw	a2,32(sp)
    60f4:	0ff68d93          	addi	s11,a3,255 # 460040ff <__kernel_data_lma+0x45ffca1b>
    60f8:	00f12423          	sw	a5,8(sp)
    60fc:	00200337          	lui	t1,0x200
    6100:	44000c37          	lui	s8,0x44000

00006104 <.L109>:
    6104:	00070e13          	mv	t3,a4
    6108:	000f0793          	mv	a5,t5
    610c:	000f1663          	bnez	t5,6118 <.L79>
    6110:	fffff6b7          	lui	a3,0xfffff
    6114:	00e6f663          	bgeu	a3,a4,6120 <.L78>

00006118 <.L79>:
    6118:	fffffe37          	lui	t3,0xfffff
    611c:	00000793          	li	a5,0

00006120 <.L78>:
    6120:	41c706b3          	sub	a3,a4,t3
    6124:	40ff07b3          	sub	a5,t5,a5
    6128:	00d73733          	sltu	a4,a4,a3
    612c:	40e78833          	sub	a6,a5,a4
    6130:	46000fb7          	lui	t6,0x46000
    6134:	100f8f93          	addi	t6,t6,256 # 46000100 <__kernel_data_lma+0x45ff8a1c>
    6138:	01012a23          	sw	a6,20(sp)
    613c:	00d12c23          	sw	a3,24(sp)
    6140:	01012e23          	sw	a6,28(sp)

00006144 <.L108>:
    6144:	010aa583          	lw	a1,16(s5)
    6148:	216584e3          	beq	a1,s6,6b50 <.L508>

0000614c <.L80>:
    614c:	416585b3          	sub	a1,a1,s6
    6150:	0bc5d5b3          	minu	a1,a1,t3
    6154:	00858633          	add	a2,a1,s0
    6158:	00c65613          	srli	a2,a2,0xc
    615c:	00861613          	slli	a2,a2,0x8
    6160:	00019eb7          	lui	t4,0x19

00006164 <.L91>:
    6164:	0ff0000f          	fence
    6168:	6e0ea703          	lw	a4,1760(t4) # 196e0 <__kernel_data_lma+0x11ffc>
    616c:	040aa783          	lw	a5,64(s5)
    6170:	044aa883          	lw	a7,68(s5)
    6174:	00a77833          	and	a6,a4,a0
    6178:	01f75713          	srli	a4,a4,0x1f
    617c:	40f80833          	sub	a6,a6,a5
    6180:	2b170663          	beq	a4,a7,642c <.L509>
    6184:	fec860e3          	bltu	a6,a2,6164 <.L91>

00006188 <.L512>:
    6188:	00479793          	slli	a5,a5,0x4
    618c:	00f58733          	add	a4,a1,a5
    6190:	00078f13          	mv	t5,a5
    6194:	24efe2e3          	bltu	t6,a4,6bd8 <.L510>

00006198 <.L92>:
    6198:	00058e93          	mv	t4,a1
    619c:	000b0893          	mv	a7,s6
    61a0:	0ab9f263          	bgeu	s3,a1,6244 <.L99>
    61a4:	ffb30837          	lui	a6,0xffb30

000061a8 <.L100>:
    61a8:	04082703          	lw	a4,64(a6) # ffb30040 <__stack_top+0x2e040>
    61ac:	fe071ee3          	bnez	a4,61a8 <.L100>
    61b0:	01682023          	sw	s6,0(a6)
    61b4:	03382023          	sw	s3,32(a6)
    61b8:	00f82623          	sw	a5,12(a6)
    61bc:	00100293          	li	t0,1
    61c0:	04582023          	sw	t0,64(a6)
    61c4:	41358eb3          	sub	t4,a1,s3
    61c8:	013b0733          	add	a4,s6,s3
    61cc:	013f0833          	add	a6,t5,s3
    61d0:	ffffc7b7          	lui	a5,0xffffc
    61d4:	51d9f8e3          	bgeu	s3,t4,6ee4 <.L511>
    61d8:	ffff88b7          	lui	a7,0xffff8
    61dc:	fff88893          	addi	a7,a7,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    61e0:	011583b3          	add	t2,a1,a7
    61e4:	000088b7          	lui	a7,0x8
    61e8:	00f3f4b3          	and	s1,t2,a5
    61ec:	011b08b3          	add	a7,s6,a7
    61f0:	416787b3          	sub	a5,a5,s6
    61f4:	01078eb3          	add	t4,a5,a6
    61f8:	009888b3          	add	a7,a7,s1
    61fc:	ffb307b7          	lui	a5,0xffb30

00006200 <.L102>:
    6200:	0407a803          	lw	a6,64(a5) # ffb30040 <__stack_top+0x2e040>
    6204:	fe081ee3          	bnez	a6,6200 <.L102>
    6208:	00e7a023          	sw	a4,0(a5)
    620c:	00ee8833          	add	a6,t4,a4
    6210:	0107a623          	sw	a6,12(a5)
    6214:	0457a023          	sw	t0,64(a5)
    6218:	01370733          	add	a4,a4,s3
    621c:	ff1712e3          	bne	a4,a7,6200 <.L102>
    6220:	00e3d393          	srli	t2,t2,0xe
    6224:	ffff8737          	lui	a4,0xffff8
    6228:	00e39793          	slli	a5,t2,0xe
    622c:	00e58eb3          	add	t4,a1,a4
    6230:	00078393          	mv	t2,a5
    6234:	40fe8eb3          	sub	t4,t4,a5
    6238:	000087b7          	lui	a5,0x8
    623c:	00ff0f33          	add	t5,t5,a5
    6240:	007f07b3          	add	a5,t5,t2

00006244 <.L99>:
    6244:	ffb30837          	lui	a6,0xffb30

00006248 <.L104>:
    6248:	04082703          	lw	a4,64(a6) # ffb30040 <__stack_top+0x2e040>
    624c:	fe071ee3          	bnez	a4,6248 <.L104>
    6250:	01182023          	sw	a7,0(a6)
    6254:	00004737          	lui	a4,0x4
    6258:	03d82023          	sw	t4,32(a6)
    625c:	fff70713          	addi	a4,a4,-1 # 3fff <_start-0x9d1>
    6260:	004a2883          	lw	a7,4(s4)
    6264:	00e58733          	add	a4,a1,a4
    6268:	00f82623          	sw	a5,12(a6)
    626c:	004ba783          	lw	a5,4(s7)
    6270:	00e75713          	srli	a4,a4,0xe
    6274:	00170713          	addi	a4,a4,1
    6278:	00e888b3          	add	a7,a7,a4
    627c:	00e787b3          	add	a5,a5,a4
    6280:	040aa703          	lw	a4,64(s5)
    6284:	011a2223          	sw	a7,4(s4)
    6288:	00e60633          	add	a2,a2,a4
    628c:	00fba223          	sw	a5,4(s7)
    6290:	00100893          	li	a7,1
    6294:	04600737          	lui	a4,0x4600
    6298:	04caa023          	sw	a2,64(s5)
    629c:	05182023          	sw	a7,64(a6)
    62a0:	00f70713          	addi	a4,a4,15 # 460000f <__kernel_data_lma+0x45f892b>
    62a4:	044aa783          	lw	a5,68(s5)
    62a8:	00c77c63          	bgeu	a4,a2,62c0 <.L105>
    62ac:	ffe00737          	lui	a4,0xffe00
    62b0:	0017b793          	seqz	a5,a5
    62b4:	00e60633          	add	a2,a2,a4
    62b8:	04faa223          	sw	a5,68(s5)
    62bc:	04caa023          	sw	a2,64(s5)

000062c0 <.L105>:
    62c0:	01f79793          	slli	a5,a5,0x1f
    62c4:	00019737          	lui	a4,0x19
    62c8:	00c7e7b3          	or	a5,a5,a2
    62cc:	6cf72823          	sw	a5,1744(a4) # 196d0 <__kernel_data_lma+0x11fec>
    62d0:	ffb30737          	lui	a4,0xffb30

000062d4 <.L106>:
    62d4:	04072783          	lw	a5,64(a4) # ffb30040 <__stack_top+0x2e040>
    62d8:	fe079ee3          	bnez	a5,62d4 <.L106>
    62dc:	000197b7          	lui	a5,0x19
    62e0:	6d078793          	addi	a5,a5,1744 # 196d0 <__kernel_data_lma+0x11fec>
    62e4:	00f72023          	sw	a5,0(a4)
    62e8:	00400793          	li	a5,4
    62ec:	02f72023          	sw	a5,32(a4)
    62f0:	400007b7          	lui	a5,0x40000
    62f4:	08078793          	addi	a5,a5,128 # 40000080 <__kernel_data_lma+0x3fff899c>
    62f8:	00f72623          	sw	a5,12(a4)
    62fc:	00100793          	li	a5,1
    6300:	04f72023          	sw	a5,64(a4)
    6304:	004a2603          	lw	a2,4(s4)
    6308:	40be0e33          	sub	t3,t3,a1
    630c:	00bb0b33          	add	s6,s6,a1
    6310:	ffb30737          	lui	a4,0xffb30

00006314 <.L107>:
    6314:	22872783          	lw	a5,552(a4) # ffb30228 <__stack_top+0x2e228>
    6318:	fec79ee3          	bne	a5,a2,6314 <.L107>
    631c:	0ff0000f          	fence
    6320:	e20e12e3          	bnez	t3,6144 <.L108>
    6324:	01412803          	lw	a6,20(sp)
    6328:	01812703          	lw	a4,24(sp)
    632c:	0106e6b3          	or	a3,a3,a6
    6330:	01c12f03          	lw	t5,28(sp)
    6334:	dc0698e3          	bnez	a3,6104 <.L109>
    6338:	ea5fe06f          	j	51dc <.L74>

0000633c <.L497>:
    633c:	00300713          	li	a4,3
    6340:	00e79a63          	bne	a5,a4,6354 <.L50>
    6344:	0001a737          	lui	a4,0x1a
    6348:	ffb016b7          	lui	a3,0xffb01
    634c:	8ce6a623          	sw	a4,-1844(a3) # ffb008cc <_ZL7cmd_ptr>
    6350:	00eaa823          	sw	a4,16(s5)

00006354 <.L50>:
    6354:	030ac703          	lbu	a4,48(s5)
    6358:	0a070a63          	beqz	a4,640c <.L51>
    635c:	034aa683          	lw	a3,52(s5)
    6360:	ffb30737          	lui	a4,0xffb30

00006364 <.L52>:
    6364:	22872783          	lw	a5,552(a4) # ffb30228 <__stack_top+0x2e228>
    6368:	40d787b3          	sub	a5,a5,a3
    636c:	fe07cce3          	bltz	a5,6364 <.L52>
    6370:	00012783          	lw	a5,0(sp)
    6374:	0007a703          	lw	a4,0(a5)
    6378:	ffb227b7          	lui	a5,0xffb22

0000637c <.L53>:
    637c:	8407a683          	lw	a3,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    6380:	fe069ee3          	bnez	a3,637c <.L53>
    6384:	80e7a023          	sw	a4,-2048(a5)
    6388:	000016b7          	lui	a3,0x1
    638c:	00275713          	srli	a4,a4,0x2
    6390:	07c68693          	addi	a3,a3,124 # 107c <_start-0x3954>
    6394:	00377713          	andi	a4,a4,3
    6398:	8007a223          	sw	zero,-2044(a5)
    639c:	00d76733          	or	a4,a4,a3
    63a0:	08e00693          	li	a3,142
    63a4:	80d7a423          	sw	a3,-2040(a5)
    63a8:	000026b7          	lui	a3,0x2
    63ac:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    63b0:	80d7ae23          	sw	a3,-2020(a5)
    63b4:	82e7a023          	sw	a4,-2016(a5)
    63b8:	02000713          	li	a4,32
    63bc:	82e7a423          	sw	a4,-2008(a5)
    63c0:	00412683          	lw	a3,4(sp)
    63c4:	00100713          	li	a4,1
    63c8:	84e7a023          	sw	a4,-1984(a5)
    63cc:	0006a703          	lw	a4,0(a3)
    63d0:	024aa783          	lw	a5,36(s5)
    63d4:	00170713          	addi	a4,a4,1
    63d8:	00e6a023          	sw	a4,0(a3)
    63dc:	0380006f          	j	6414 <.L54>

000063e0 <.L498>:
    63e0:	00012783          	lw	a5,0(sp)
    63e4:	0007a703          	lw	a4,0(a5)

000063e8 <.L56>:
    63e8:	0ff0000f          	fence
    63ec:	00072783          	lw	a5,0(a4)
    63f0:	02caa683          	lw	a3,44(s5)
    63f4:	02faa423          	sw	a5,40(s5)
    63f8:	fed788e3          	beq	a5,a3,63e8 <.L56>
    63fc:	e29fe06f          	j	5224 <.L55>

00006400 <.L499>:
    6400:	00100713          	li	a4,1
    6404:	02ea8823          	sb	a4,48(s5)
    6408:	f15fe06f          	j	531c <.L288>

0000640c <.L51>:
    640c:	00100713          	li	a4,1
    6410:	02ea8823          	sb	a4,48(s5)

00006414 <.L54>:
    6414:	00178793          	addi	a5,a5,1
    6418:	0037f793          	andi	a5,a5,3
    641c:	02faa223          	sw	a5,36(s5)
    6420:	004a2783          	lw	a5,4(s4)
    6424:	02faaa23          	sw	a5,52(s5)
    6428:	dedfe06f          	j	5214 <.L49>

0000642c <.L509>:
    642c:	00680833          	add	a6,a6,t1
    6430:	d2c86ae3          	bltu	a6,a2,6164 <.L91>
    6434:	d55ff06f          	j	6188 <.L512>

00006438 <.L308>:
    6438:	00068c13          	mv	s8,a3

0000643c <.L203>:
    643c:	024aa703          	lw	a4,36(s5)
    6440:	05010893          	addi	a7,sp,80
    6444:	04c10313          	addi	t1,sp,76
    6448:	215746b3          	sh2add	a3,a4,s5
    644c:	07112423          	sw	a7,104(sp)
    6450:	0146a683          	lw	a3,20(a3)
    6454:	05c10893          	addi	a7,sp,92
    6458:	06612223          	sw	t1,100(sp)
    645c:	07112623          	sw	a7,108(sp)
    6460:	1b6684e3          	beq	a3,s6,6e08 <.L207>
    6464:	00012703          	lw	a4,0(sp)
    6468:	00072683          	lw	a3,0(a4)

0000646c <.L208>:
    646c:	02caa883          	lw	a7,44(s5)
    6470:	028aa703          	lw	a4,40(s5)
    6474:	20e88263          	beq	a7,a4,6678 <.L215>

00006478 <.L214>:
    6478:	024aa683          	lw	a3,36(s5)
    647c:	010aa303          	lw	t1,16(s5)
    6480:	2156c6b3          	sh2add	a3,a3,s5
    6484:	0146a683          	lw	a3,20(a3)
    6488:	41170733          	sub	a4,a4,a7
    648c:	406686b3          	sub	a3,a3,t1
    6490:	00c6d693          	srli	a3,a3,0xc
    6494:	0ae6d733          	minu	a4,a3,a4
    6498:	00c71d13          	slli	s10,a4,0xc
    649c:	006d0d33          	add	s10,s10,t1
    64a0:	01170733          	add	a4,a4,a7
    64a4:	01aaa823          	sw	s10,16(s5)
    64a8:	02eaa623          	sw	a4,44(s5)
    64ac:	416d0333          	sub	t1,s10,s6
    64b0:	baa37863          	bgeu	t1,a0,5860 <.L205>

000064b4 <.L501>:
    64b4:	3e0c02e3          	beqz	s8,7098 <.L309>

000064b8 <.L204>:
    64b8:	04c12883          	lw	a7,76(sp)
    64bc:	05c12683          	lw	a3,92(sp)
    64c0:	05012703          	lw	a4,80(sp)
    64c4:	02d886b3          	mul	a3,a7,a3
    64c8:	04012623          	sw	zero,76(sp)
    64cc:	00e686b3          	add	a3,a3,a4
    64d0:	004a2703          	lw	a4,4(s4)
    64d4:	04d12823          	sw	a3,80(sp)
    64d8:	01170733          	add	a4,a4,a7
    64dc:	00dba223          	sw	a3,4(s7)
    64e0:	00ea2223          	sw	a4,4(s4)

000064e4 <.L217>:
    64e4:	2047a703          	lw	a4,516(a5)
    64e8:	fee69ee3          	bne	a3,a4,64e4 <.L217>
    64ec:	0ff0000f          	fence
    64f0:	000b0893          	mv	a7,s6
    64f4:	000d0b13          	mv	s6,s10

000064f8 <.L225>:
    64f8:	00080d13          	mv	s10,a6
    64fc:	00030713          	mv	a4,t1
    6500:	00088c13          	mv	s8,a7
    6504:	06667a63          	bgeu	a2,t1,6578 <.L223>

00006508 <.L219>:
    6508:	0407a703          	lw	a4,64(a5)
    650c:	fe071ee3          	bnez	a4,6508 <.L219>
    6510:	0117a023          	sw	a7,0(a5)
    6514:	02c7a023          	sw	a2,32(a5)
    6518:	00930db3          	add	s11,t1,s1
    651c:	008df733          	and	a4,s11,s0
    6520:	0107a623          	sw	a6,12(a5)
    6524:	01d88c33          	add	s8,a7,t4
    6528:	00ec0c33          	add	s8,s8,a4
    652c:	04b7a023          	sw	a1,64(a5)
    6530:	40c30733          	sub	a4,t1,a2
    6534:	00c886b3          	add	a3,a7,a2
    6538:	41180d33          	sub	s10,a6,a7
    653c:	34e674e3          	bgeu	a2,a4,7084 <.L513>

00006540 <.L221>:
    6540:	0407a703          	lw	a4,64(a5)
    6544:	fe071ee3          	bnez	a4,6540 <.L221>
    6548:	00d7a023          	sw	a3,0(a5)
    654c:	00dd0733          	add	a4,s10,a3
    6550:	00e7a623          	sw	a4,12(a5)
    6554:	04b7a023          	sw	a1,64(a5)
    6558:	00c686b3          	add	a3,a3,a2
    655c:	ff8692e3          	bne	a3,s8,6540 <.L221>
    6560:	00eddd93          	srli	s11,s11,0xe
    6564:	00ed9693          	slli	a3,s11,0xe
    6568:	00730733          	add	a4,t1,t2
    656c:	01d80d33          	add	s10,a6,t4
    6570:	40d70733          	sub	a4,a4,a3
    6574:	00dd0d33          	add	s10,s10,a3

00006578 <.L223>:
    6578:	0407a683          	lw	a3,64(a5)
    657c:	fe069ee3          	bnez	a3,6578 <.L223>

00006580 <.L521>:
    6580:	0187a023          	sw	s8,0(a5)
    6584:	02e7a023          	sw	a4,32(a5)
    6588:	01a7a623          	sw	s10,12(a5)
    658c:	04b7a023          	sw	a1,64(a5)
    6590:	04c12683          	lw	a3,76(sp)
    6594:	01c30733          	add	a4,t1,t3
    6598:	00e75713          	srli	a4,a4,0xe
    659c:	00d70733          	add	a4,a4,a3
    65a0:	011508b3          	add	a7,a0,a7
    65a4:	04e12623          	sw	a4,76(sp)
    65a8:	00680833          	add	a6,a6,t1
    65ac:	41688533          	sub	a0,a7,s6
    65b0:	01689463          	bne	a7,s6,65b8 <.L521+0x38>
    65b4:	1240106f          	j	76d8 <.L311>
    65b8:	010aa703          	lw	a4,16(s5)
    65bc:	00000c13          	li	s8,0
    65c0:	e6eb0ee3          	beq	s6,a4,643c <.L203>
    65c4:	41670333          	sub	t1,a4,s6
    65c8:	74a36263          	bltu	t1,a0,6d0c <.L514>
    65cc:	001cf713          	andi	a4,s9,1
    65d0:	00070c93          	mv	s9,a4
    65d4:	ac070c63          	beqz	a4,58ac <.L238>

000065d8 <.L228>:
    65d8:	000b0693          	mv	a3,s6
    65dc:	00050713          	mv	a4,a0
    65e0:	06a67c63          	bgeu	a2,a0,6658 <.L235>

000065e4 <.L231>:
    65e4:	0407a703          	lw	a4,64(a5)
    65e8:	fe071ee3          	bnez	a4,65e4 <.L231>
    65ec:	0167a023          	sw	s6,0(a5)
    65f0:	02c7a023          	sw	a2,32(a5)
    65f4:	00950d33          	add	s10,a0,s1
    65f8:	0107a623          	sw	a6,12(a5)
    65fc:	008d7333          	and	t1,s10,s0
    6600:	01d30333          	add	t1,t1,t4
    6604:	04b7a023          	sw	a1,64(a5)
    6608:	40c50733          	sub	a4,a0,a2
    660c:	01630333          	add	t1,t1,s6
    6610:	00cb06b3          	add	a3,s6,a2
    6614:	416808b3          	sub	a7,a6,s6
    6618:	30e678e3          	bgeu	a2,a4,7128 <.L515>

0000661c <.L233>:
    661c:	0407a703          	lw	a4,64(a5)
    6620:	fe071ee3          	bnez	a4,661c <.L233>
    6624:	00d7a023          	sw	a3,0(a5)
    6628:	00d88733          	add	a4,a7,a3
    662c:	00e7a623          	sw	a4,12(a5)
    6630:	04b7a023          	sw	a1,64(a5)
    6634:	00c686b3          	add	a3,a3,a2
    6638:	fe6692e3          	bne	a3,t1,661c <.L233>
    663c:	00ed5693          	srli	a3,s10,0xe
    6640:	00e69693          	slli	a3,a3,0xe
    6644:	00750733          	add	a4,a0,t2
    6648:	40d70733          	sub	a4,a4,a3
    664c:	40e506b3          	sub	a3,a0,a4
    6650:	00d80833          	add	a6,a6,a3
    6654:	00db06b3          	add	a3,s6,a3

00006658 <.L235>:
    6658:	0407a883          	lw	a7,64(a5)
    665c:	fe089ee3          	bnez	a7,6658 <.L235>

00006660 <.L522>:
    6660:	0127ae23          	sw	s2,28(a5)
    6664:	00d7a023          	sw	a3,0(a5)
    6668:	02e7a023          	sw	a4,32(a5)
    666c:	0107a623          	sw	a6,12(a5)
    6670:	04b7a023          	sw	a1,64(a5)
    6674:	ae0ff06f          	j	5954 <.L236>

00006678 <.L215>:
    6678:	0ff0000f          	fence
    667c:	0006a703          	lw	a4,0(a3)
    6680:	02caa883          	lw	a7,44(s5)
    6684:	02eaa423          	sw	a4,40(s5)
    6688:	df1718e3          	bne	a4,a7,6478 <.L214>
    668c:	0ff0000f          	fence
    6690:	0006a703          	lw	a4,0(a3)
    6694:	02caa883          	lw	a7,44(s5)
    6698:	02eaa423          	sw	a4,40(s5)
    669c:	fd170ee3          	beq	a4,a7,6678 <.L215>
    66a0:	dd9ff06f          	j	6478 <.L214>

000066a4 <.L256>:
    66a4:	0ff0000f          	fence
    66a8:	00082703          	lw	a4,0(a6)
    66ac:	02caa503          	lw	a0,44(s5)
    66b0:	02eaa423          	sw	a4,40(s5)
    66b4:	b0a71863          	bne	a4,a0,59c4 <.L255>
    66b8:	0ff0000f          	fence
    66bc:	00082703          	lw	a4,0(a6)
    66c0:	02caa503          	lw	a0,44(s5)
    66c4:	02eaa423          	sw	a4,40(s5)
    66c8:	fca70ee3          	beq	a4,a0,66a4 <.L256>
    66cc:	af8ff06f          	j	59c4 <.L255>

000066d0 <.L141>:
    66d0:	003b4703          	lbu	a4,3(s6)
    66d4:	00871713          	slli	a4,a4,0x8
    66d8:	00c76733          	or	a4,a4,a2
    66dc:	04070a63          	beqz	a4,6730 <.L168>
    66e0:	08010613          	addi	a2,sp,128
    66e4:	00000513          	li	a0,0

000066e8 <.L169>:
    66e8:	0006af03          	lw	t5,0(a3)
    66ec:	0046ae83          	lw	t4,4(a3)
    66f0:	0086ae03          	lw	t3,8(a3)
    66f4:	00c6a303          	lw	t1,12(a3)
    66f8:	0106a883          	lw	a7,16(a3)
    66fc:	0146a803          	lw	a6,20(a3)
    6700:	00650513          	addi	a0,a0,6
    6704:	01868693          	addi	a3,a3,24
    6708:	01860613          	addi	a2,a2,24
    670c:	ffe62423          	sw	t5,-24(a2)
    6710:	ffd62623          	sw	t4,-20(a2)
    6714:	ffc62823          	sw	t3,-16(a2)
    6718:	fe662a23          	sw	t1,-12(a2)
    671c:	ff162c23          	sw	a7,-8(a2)
    6720:	ff062e23          	sw	a6,-4(a2)
    6724:	fce562e3          	bltu	a0,a4,66e8 <.L169>
    6728:	ffb016b7          	lui	a3,0xffb01
    672c:	8cc6ab03          	lw	s6,-1844(a3) # ffb008cc <_ZL7cmd_ptr>

00006730 <.L168>:
    6730:	0067c503          	lbu	a0,6(a5)
    6734:	21674833          	sh2add	a6,a4,s6
    6738:	0077c603          	lbu	a2,7(a5)
    673c:	0047c883          	lbu	a7,4(a5)
    6740:	0057c683          	lbu	a3,5(a5)
    6744:	00861613          	slli	a2,a2,0x8
    6748:	00869693          	slli	a3,a3,0x8
    674c:	0087ce03          	lbu	t3,8(a5)
    6750:	0116e6b3          	or	a3,a3,a7
    6754:	0097c883          	lbu	a7,9(a5)
    6758:	2156c6b3          	sh2add	a3,a3,s5
    675c:	00a66633          	or	a2,a2,a0
    6760:	00a7c503          	lbu	a0,10(a5)
    6764:	0006a303          	lw	t1,0(a3)
    6768:	00889893          	slli	a7,a7,0x8
    676c:	00b7c683          	lbu	a3,11(a5)
    6770:	01c8e8b3          	or	a7,a7,t3
    6774:	01f80813          	addi	a6,a6,31
    6778:	01051793          	slli	a5,a0,0x10
    677c:	0117e7b3          	or	a5,a5,a7
    6780:	ff087813          	andi	a6,a6,-16
    6784:	01869693          	slli	a3,a3,0x18
    6788:	00f6e6b3          	or	a3,a3,a5
    678c:	0025f593          	andi	a1,a1,2
    6790:	03012e23          	sw	a6,60(sp)
    6794:	006686b3          	add	a3,a3,t1
    6798:	00000893          	li	a7,0
    679c:	640582e3          	beqz	a1,75e0 <.L516>

000067a0 <.L170>:
    67a0:	ffb307b7          	lui	a5,0xffb30

000067a4 <.L171>:
    67a4:	0407a583          	lw	a1,64(a5) # ffb30040 <__stack_top+0x2e040>
    67a8:	fe059ee3          	bnez	a1,67a4 <.L171>
    67ac:	000025b7          	lui	a1,0x2
    67b0:	09258593          	addi	a1,a1,146 # 2092 <_start-0x293e>
    67b4:	00b7ae23          	sw	a1,28(a5)
    67b8:	02c7a023          	sw	a2,32(a5)
    67bc:	00d7a623          	sw	a3,12(a5)
    67c0:	04010393          	addi	t2,sp,64
    67c4:	04410413          	addi	s0,sp,68
    67c8:	04012023          	sw	zero,64(sp)
    67cc:	04012223          	sw	zero,68(sp)
    67d0:	04712e23          	sw	t2,92(sp)
    67d4:	06812023          	sw	s0,96(sp)
    67d8:	03c12b03          	lw	s6,60(sp)
    67dc:	00000593          	li	a1,0
    67e0:	120706e3          	beqz	a4,710c <.L172>
    67e4:	01000f37          	lui	t5,0x1000
    67e8:	ffff0793          	addi	a5,t5,-1 # ffffff <__kernel_data_lma+0xff891b>
    67ec:	10000fb7          	lui	t6,0x10000
    67f0:	00f12423          	sw	a5,8(sp)
    67f4:	fff70713          	addi	a4,a4,-1
    67f8:	00ff8f93          	addi	t6,t6,15 # 1000000f <__kernel_data_lma+0xfff892b>
    67fc:	08010e93          	addi	t4,sp,128
    6800:	00100e13          	li	t3,1
    6804:	ffb307b7          	lui	a5,0xffb30
    6808:	04c10d13          	addi	s10,sp,76
    680c:	03c10c93          	addi	s9,sp,60
    6810:	05c10c13          	addi	s8,sp,92
    6814:	05010913          	addi	s2,sp,80

00006818 <.L191>:
    6818:	000ea583          	lw	a1,0(t4)
    681c:	010aa283          	lw	t0,16(s5)
    6820:	00459593          	slli	a1,a1,0x4
    6824:	05c12423          	sw	t3,72(sp)
    6828:	04d12823          	sw	a3,80(sp)
    682c:	04b12a23          	sw	a1,84(sp)
    6830:	416284b3          	sub	s1,t0,s6
    6834:	00058813          	mv	a6,a1
    6838:	004e8e93          	addi	t4,t4,4
    683c:	00068313          	mv	t1,a3
    6840:	08c4f663          	bgeu	s1,a2,68cc <.L190>
    6844:	024aa503          	lw	a0,36(s5)
    6848:	04810f13          	addi	t5,sp,72
    684c:	21554db3          	sh2add	s11,a0,s5
    6850:	014dad83          	lw	s11,20(s11)
    6854:	04012623          	sw	zero,76(sp)
    6858:	07a12223          	sw	s10,100(sp)
    685c:	07912423          	sw	s9,104(sp)
    6860:	07812623          	sw	s8,108(sp)
    6864:	07212823          	sw	s2,112(sp)
    6868:	07e12a23          	sw	t5,116(sp)
    686c:	06712c23          	sw	t2,120(sp)
    6870:	06812e23          	sw	s0,124(sp)
    6874:	37b284e3          	beq	t0,s11,73dc <.L174>
    6878:	00012583          	lw	a1,0(sp)
    687c:	0005a503          	lw	a0,0(a1)

00006880 <.L175>:
    6880:	02caa483          	lw	s1,44(s5)
    6884:	028aa583          	lw	a1,40(s5)
    6888:	26b48e63          	beq	s1,a1,6b04 <.L185>

0000688c <.L184>:
    688c:	024aa503          	lw	a0,36(s5)
    6890:	010aa283          	lw	t0,16(s5)
    6894:	21554533          	sh2add	a0,a0,s5
    6898:	01452503          	lw	a0,20(a0)
    689c:	409585b3          	sub	a1,a1,s1
    68a0:	40550533          	sub	a0,a0,t0
    68a4:	00c55513          	srli	a0,a0,0xc
    68a8:	0ab555b3          	minu	a1,a0,a1
    68ac:	00c59513          	slli	a0,a1,0xc
    68b0:	005502b3          	add	t0,a0,t0
    68b4:	009585b3          	add	a1,a1,s1
    68b8:	04c12503          	lw	a0,76(sp)
    68bc:	005aa823          	sw	t0,16(s5)
    68c0:	02baa623          	sw	a1,44(s5)
    68c4:	03c12b03          	lw	s6,60(sp)
    68c8:	7c051e63          	bnez	a0,70a4 <.L517>

000068cc <.L190>:
    68cc:	0407a583          	lw	a1,64(a5) # ffb30040 <__stack_top+0x2e040>
    68d0:	fe059ee3          	bnez	a1,68cc <.L190>
    68d4:	0167a023          	sw	s6,0(a5)
    68d8:	00812503          	lw	a0,8(sp)
    68dc:	01f875b3          	and	a1,a6,t6
    68e0:	00b7a823          	sw	a1,16(a5)
    68e4:	00485593          	srli	a1,a6,0x4
    68e8:	00a5f5b3          	and	a1,a1,a0
    68ec:	00b7aa23          	sw	a1,20(a5)
    68f0:	05c7a023          	sw	t3,64(a5)
    68f4:	04012503          	lw	a0,64(sp)
    68f8:	04412583          	lw	a1,68(sp)
    68fc:	03c12b03          	lw	s6,60(sp)
    6900:	04812803          	lw	a6,72(sp)
    6904:	00150513          	addi	a0,a0,1
    6908:	010585b3          	add	a1,a1,a6
    690c:	01688b33          	add	s6,a7,s6
    6910:	04a12023          	sw	a0,64(sp)
    6914:	04b12223          	sw	a1,68(sp)
    6918:	03612e23          	sw	s6,60(sp)
    691c:	7e070663          	beqz	a4,7108 <.L518>

00006920 <.L307>:
    6920:	fff70713          	addi	a4,a4,-1
    6924:	ef5ff06f          	j	6818 <.L191>

00006928 <.L110>:
    6928:	0067c703          	lbu	a4,6(a5)
    692c:	00869693          	slli	a3,a3,0x8
    6930:	0077c883          	lbu	a7,7(a5)
    6934:	00a6e6b3          	or	a3,a3,a0
    6938:	00861613          	slli	a2,a2,0x8
    693c:	01071713          	slli	a4,a4,0x10
    6940:	00d76733          	or	a4,a4,a3
    6944:	01889893          	slli	a7,a7,0x18
    6948:	00b666b3          	or	a3,a2,a1
    694c:	0087c583          	lbu	a1,8(a5)
    6950:	0097c603          	lbu	a2,9(a5)
    6954:	00e8e8b3          	or	a7,a7,a4
    6958:	00a7c703          	lbu	a4,10(a5)
    695c:	00861613          	slli	a2,a2,0x8
    6960:	00b66633          	or	a2,a2,a1
    6964:	01071713          	slli	a4,a4,0x10
    6968:	00b7c583          	lbu	a1,11(a5)
    696c:	00c76733          	or	a4,a4,a2
    6970:	00c7c603          	lbu	a2,12(a5)
    6974:	00d7c503          	lbu	a0,13(a5)
    6978:	01859593          	slli	a1,a1,0x18
    697c:	00e5e5b3          	or	a1,a1,a4
    6980:	00851513          	slli	a0,a0,0x8
    6984:	00e7c703          	lbu	a4,14(a5)
    6988:	00c56533          	or	a0,a0,a2
    698c:	00f7c603          	lbu	a2,15(a5)
    6990:	01071793          	slli	a5,a4,0x10
    6994:	00a7e7b3          	or	a5,a5,a0
    6998:	01861613          	slli	a2,a2,0x18
    699c:	00f66633          	or	a2,a2,a5
    69a0:	02c58633          	mul	a2,a1,a2
    69a4:	00061463          	bnez	a2,69ac <.L110+0x84>
    69a8:	835fe06f          	j	51dc <.L74>
    69ac:	fff58813          	addi	a6,a1,-1
    69b0:	010aa403          	lw	s0,16(s5)
    69b4:	00f86813          	ori	a6,a6,15
    69b8:	ffb00f37          	lui	t5,0xffb00
    69bc:	ffb00eb7          	lui	t4,0xffb00
    69c0:	88889e37          	lui	t3,0x88889
    69c4:	00002337          	lui	t1,0x2
    69c8:	00180813          	addi	a6,a6,1
    69cc:	660f0f13          	addi	t5,t5,1632 # ffb00660 <bank_to_l1_offset>
    69d0:	464e8e93          	addi	t4,t4,1124 # ffb00464 <l1_bank_to_noc_xy>
    69d4:	889e0e13          	addi	t3,t3,-1911 # 88888889 <__kernel_data_lma+0x888811a5>
    69d8:	09230313          	addi	t1,t1,146 # 2092 <_start-0x293e>
    69dc:	00000513          	li	a0,0
    69e0:	00300393          	li	t2,3
    69e4:	000042b7          	lui	t0,0x4
    69e8:	ffb30737          	lui	a4,0xffb30
    69ec:	00100f93          	li	t6,1
    69f0:	0b640c63          	beq	s0,s6,6aa8 <.L519>

000069f4 <.L127>:
    69f4:	03c6bc33          	mulhu	s8,a3,t3
    69f8:	00a887b3          	add	a5,a7,a0
    69fc:	006c5c13          	srli	s8,s8,0x6
    6a00:	03880933          	mul	s2,a6,s8
    6a04:	40a584b3          	sub	s1,a1,a0
    6a08:	00f90933          	add	s2,s2,a5
    6a0c:	0a54d7b3          	minu	a5,s1,t0
    6a10:	41640433          	sub	s0,s0,s6
    6a14:	0af45433          	minu	s0,s0,a5
    6a18:	004c1793          	slli	a5,s8,0x4
    6a1c:	418787b3          	sub	a5,a5,s8
    6a20:	00379793          	slli	a5,a5,0x3
    6a24:	40f687b3          	sub	a5,a3,a5
    6a28:	21e7cc33          	sh2add	s8,a5,t5
    6a2c:	21d7a7b3          	sh1add	a5,a5,t4
    6a30:	000c2c03          	lw	s8,0(s8) # 44000000 <__kernel_data_lma+0x43ff891c>
    6a34:	0f07d783          	lhu	a5,240(a5)
    6a38:	01890933          	add	s2,s2,s8
    6a3c:	00479c13          	slli	s8,a5,0x4

00006a40 <.L137>:
    6a40:	04072783          	lw	a5,64(a4) # ffb30040 <__stack_top+0x2e040>
    6a44:	fe079ee3          	bnez	a5,6a40 <.L137>
    6a48:	00672e23          	sw	t1,28(a4)
    6a4c:	01672023          	sw	s6,0(a4)
    6a50:	01272623          	sw	s2,12(a4)
    6a54:	00072823          	sw	zero,16(a4)
    6a58:	004c5793          	srli	a5,s8,0x4
    6a5c:	004a2903          	lw	s2,4(s4)
    6a60:	00f72a23          	sw	a5,20(a4)
    6a64:	004ba783          	lw	a5,4(s7)
    6a68:	02872023          	sw	s0,32(a4)
    6a6c:	05f72023          	sw	t6,64(a4)
    6a70:	00190913          	addi	s2,s2,1
    6a74:	00178793          	addi	a5,a5,1
    6a78:	012a2223          	sw	s2,4(s4)
    6a7c:	00fba223          	sw	a5,4(s7)
    6a80:	00850533          	add	a0,a0,s0
    6a84:	00946663          	bltu	s0,s1,6a90 <.L139>
    6a88:	00168693          	addi	a3,a3,1
    6a8c:	00000513          	li	a0,0

00006a90 <.L139>:
    6a90:	40860633          	sub	a2,a2,s0
    6a94:	008b0b33          	add	s6,s6,s0
    6a98:	00061463          	bnez	a2,6aa0 <.L139+0x10>
    6a9c:	f40fe06f          	j	51dc <.L74>
    6aa0:	010aa403          	lw	s0,16(s5)
    6aa4:	f56418e3          	bne	s0,s6,69f4 <.L127>

00006aa8 <.L519>:
    6aa8:	024aa783          	lw	a5,36(s5)
    6aac:	2157c433          	sh2add	s0,a5,s5
    6ab0:	01442403          	lw	s0,20(s0) # ffffc014 <__instrn_buffer+0x1bc014>
    6ab4:	016404e3          	beq	s0,s6,72bc <.L128>
    6ab8:	00012783          	lw	a5,0(sp)
    6abc:	0007a483          	lw	s1,0(a5)

00006ac0 <.L129>:
    6ac0:	02caa903          	lw	s2,44(s5)
    6ac4:	028aa403          	lw	s0,40(s5)
    6ac8:	58890863          	beq	s2,s0,7058 <.L136>

00006acc <.L135>:
    6acc:	024aa783          	lw	a5,36(s5)
    6ad0:	010aa483          	lw	s1,16(s5)
    6ad4:	2157c7b3          	sh2add	a5,a5,s5
    6ad8:	0147a783          	lw	a5,20(a5)
    6adc:	41240433          	sub	s0,s0,s2
    6ae0:	409787b3          	sub	a5,a5,s1
    6ae4:	00c7d793          	srli	a5,a5,0xc
    6ae8:	0a87d7b3          	minu	a5,a5,s0
    6aec:	00c79413          	slli	s0,a5,0xc
    6af0:	00940433          	add	s0,s0,s1
    6af4:	012787b3          	add	a5,a5,s2
    6af8:	008aa823          	sw	s0,16(s5)
    6afc:	02faa623          	sw	a5,44(s5)
    6b00:	ef5ff06f          	j	69f4 <.L127>

00006b04 <.L185>:
    6b04:	0ff0000f          	fence
    6b08:	00052583          	lw	a1,0(a0)
    6b0c:	02caa483          	lw	s1,44(s5)
    6b10:	02baa423          	sw	a1,40(s5)
    6b14:	fe9588e3          	beq	a1,s1,6b04 <.L185>
    6b18:	05012303          	lw	t1,80(sp)
    6b1c:	05412803          	lw	a6,84(sp)
    6b20:	d6dff06f          	j	688c <.L184>

00006b24 <.L160>:
    6b24:	0ff0000f          	fence
    6b28:	0008a683          	lw	a3,0(a7) # 8000 <__kernel_data_lma+0x91c>
    6b2c:	02caa603          	lw	a2,44(s5)
    6b30:	02daa423          	sw	a3,40(s5)
    6b34:	c4c69063          	bne	a3,a2,5f74 <.L159>
    6b38:	0ff0000f          	fence
    6b3c:	0008a683          	lw	a3,0(a7)
    6b40:	02caa603          	lw	a2,44(s5)
    6b44:	02daa423          	sw	a3,40(s5)
    6b48:	fcc68ee3          	beq	a3,a2,6b24 <.L160>
    6b4c:	c28ff06f          	j	5f74 <.L159>

00006b50 <.L508>:
    6b50:	024aa783          	lw	a5,36(s5)
    6b54:	2157c733          	sh2add	a4,a5,s5
    6b58:	01472703          	lw	a4,20(a4)
    6b5c:	1f670e63          	beq	a4,s6,6d58 <.L81>
    6b60:	00012783          	lw	a5,0(sp)
    6b64:	0007a703          	lw	a4,0(a5)

00006b68 <.L82>:
    6b68:	02caa603          	lw	a2,44(s5)
    6b6c:	028aa783          	lw	a5,40(s5)
    6b70:	02f60e63          	beq	a2,a5,6bac <.L89>

00006b74 <.L88>:
    6b74:	024aa703          	lw	a4,36(s5)
    6b78:	010aa803          	lw	a6,16(s5)
    6b7c:	21574733          	sh2add	a4,a4,s5
    6b80:	01472703          	lw	a4,20(a4)
    6b84:	40c787b3          	sub	a5,a5,a2
    6b88:	41070733          	sub	a4,a4,a6
    6b8c:	00c75713          	srli	a4,a4,0xc
    6b90:	0af757b3          	minu	a5,a4,a5
    6b94:	00c79593          	slli	a1,a5,0xc
    6b98:	010585b3          	add	a1,a1,a6
    6b9c:	00c787b3          	add	a5,a5,a2
    6ba0:	00baa823          	sw	a1,16(s5)
    6ba4:	02faa623          	sw	a5,44(s5)
    6ba8:	da4ff06f          	j	614c <.L80>

00006bac <.L89>:
    6bac:	0ff0000f          	fence
    6bb0:	00072783          	lw	a5,0(a4)
    6bb4:	02caa603          	lw	a2,44(s5)
    6bb8:	02faa423          	sw	a5,40(s5)
    6bbc:	fac79ce3          	bne	a5,a2,6b74 <.L88>
    6bc0:	0ff0000f          	fence
    6bc4:	00072783          	lw	a5,0(a4)
    6bc8:	02caa603          	lw	a2,44(s5)
    6bcc:	02faa423          	sw	a5,40(s5)
    6bd0:	fcc78ee3          	beq	a5,a2,6bac <.L89>
    6bd4:	fa1ff06f          	j	6b74 <.L88>

00006bd8 <.L510>:
    6bd8:	40ff8cb3          	sub	s9,t6,a5
    6bdc:	01a78733          	add	a4,a5,s10
    6be0:	000c8e93          	mv	t4,s9
    6be4:	00078893          	mv	a7,a5
    6be8:	000b0493          	mv	s1,s6
    6bec:	0ce9f063          	bgeu	s3,a4,6cac <.L93>
    6bf0:	ffb30837          	lui	a6,0xffb30

00006bf4 <.L94>:
    6bf4:	04082703          	lw	a4,64(a6) # ffb30040 <__stack_top+0x2e040>
    6bf8:	fe071ee3          	bnez	a4,6bf4 <.L94>
    6bfc:	01682023          	sw	s6,0(a6)
    6c00:	03382023          	sw	s3,32(a6)
    6c04:	02012703          	lw	a4,32(sp)
    6c08:	00f82623          	sw	a5,12(a6)
    6c0c:	00100293          	li	t0,1
    6c10:	45ffceb7          	lui	t4,0x45ffc
    6c14:	100e8e93          	addi	t4,t4,256 # 45ffc100 <__kernel_data_lma+0x45ff4a1c>
    6c18:	04582023          	sw	t0,64(a6)
    6c1c:	00e78733          	add	a4,a5,a4
    6c20:	013b04b3          	add	s1,s6,s3
    6c24:	40fe8eb3          	sub	t4,t4,a5
    6c28:	013788b3          	add	a7,a5,s3
    6c2c:	08e9f063          	bgeu	s3,a4,6cac <.L93>
    6c30:	45ff8737          	lui	a4,0x45ff8
    6c34:	0ff70713          	addi	a4,a4,255 # 45ff80ff <__kernel_data_lma+0x45ff0a1b>
    6c38:	40f70f33          	sub	t5,a4,a5
    6c3c:	ffffc937          	lui	s2,0xffffc
    6c40:	012f7933          	and	s2,t5,s2
    6c44:	00008eb7          	lui	t4,0x8
    6c48:	01d90eb3          	add	t4,s2,t4
    6c4c:	016e8eb3          	add	t4,t4,s6
    6c50:	00048893          	mv	a7,s1
    6c54:	416783b3          	sub	t2,a5,s6
    6c58:	ffb30837          	lui	a6,0xffb30

00006c5c <.L96>:
    6c5c:	04082703          	lw	a4,64(a6) # ffb30040 <__stack_top+0x2e040>
    6c60:	fe071ee3          	bnez	a4,6c5c <.L96>
    6c64:	01182023          	sw	a7,0(a6)
    6c68:	01138733          	add	a4,t2,a7
    6c6c:	00e82623          	sw	a4,12(a6)
    6c70:	04582023          	sw	t0,64(a6)
    6c74:	013888b3          	add	a7,a7,s3
    6c78:	ffd892e3          	bne	a7,t4,6c5c <.L96>
    6c7c:	45ff8737          	lui	a4,0x45ff8
    6c80:	00ef5f13          	srli	t5,t5,0xe
    6c84:	10070e93          	addi	t4,a4,256 # 45ff8100 <__kernel_data_lma+0x45ff0a1c>
    6c88:	40fe8eb3          	sub	t4,t4,a5
    6c8c:	00ef1713          	slli	a4,t5,0xe
    6c90:	00070f13          	mv	t5,a4
    6c94:	40ee8eb3          	sub	t4,t4,a4
    6c98:	00008737          	lui	a4,0x8
    6c9c:	01390933          	add	s2,s2,s3
    6ca0:	00e78733          	add	a4,a5,a4
    6ca4:	012484b3          	add	s1,s1,s2
    6ca8:	00ef08b3          	add	a7,t5,a4

00006cac <.L93>:
    6cac:	ffb30837          	lui	a6,0xffb30

00006cb0 <.L98>:
    6cb0:	04082703          	lw	a4,64(a6) # ffb30040 <__stack_top+0x2e040>
    6cb4:	fe071ee3          	bnez	a4,6cb0 <.L98>
    6cb8:	00982023          	sw	s1,0(a6)
    6cbc:	03d82023          	sw	t4,32(a6)
    6cc0:	004a2e83          	lw	t4,4(s4)
    6cc4:	01182623          	sw	a7,12(a6)
    6cc8:	004ba883          	lw	a7,4(s7)
    6ccc:	00812f03          	lw	t5,8(sp)
    6cd0:	40fd8733          	sub	a4,s11,a5
    6cd4:	00e75713          	srli	a4,a4,0xe
    6cd8:	01e787b3          	add	a5,a5,t5
    6cdc:	00ee8eb3          	add	t4,t4,a4
    6ce0:	00e88733          	add	a4,a7,a4
    6ce4:	00fe0e33          	add	t3,t3,a5
    6ce8:	00100893          	li	a7,1
    6cec:	00f585b3          	add	a1,a1,a5
    6cf0:	01da2223          	sw	t4,4(s4)
    6cf4:	00eba223          	sw	a4,4(s7)
    6cf8:	100c0793          	addi	a5,s8,256
    6cfc:	019b0b33          	add	s6,s6,s9
    6d00:	05182023          	sw	a7,64(a6)
    6d04:	00078f13          	mv	t5,a5
    6d08:	c90ff06f          	j	6198 <.L92>

00006d0c <.L514>:
    6d0c:	000b0893          	mv	a7,s6
    6d10:	00070b13          	mv	s6,a4
    6d14:	fe4ff06f          	j	64f8 <.L225>

00006d18 <.L502>:
    6d18:	8c0c00e3          	beqz	s8,65d8 <.L228>
    6d1c:	04c12883          	lw	a7,76(sp)
    6d20:	05c12683          	lw	a3,92(sp)
    6d24:	05012703          	lw	a4,80(sp)
    6d28:	02d886b3          	mul	a3,a7,a3
    6d2c:	04012623          	sw	zero,76(sp)
    6d30:	00e686b3          	add	a3,a3,a4
    6d34:	004a2703          	lw	a4,4(s4)
    6d38:	04d12823          	sw	a3,80(sp)
    6d3c:	01170733          	add	a4,a4,a7
    6d40:	00dba223          	sw	a3,4(s7)
    6d44:	00ea2223          	sw	a4,4(s4)

00006d48 <.L229>:
    6d48:	2047a703          	lw	a4,516(a5)
    6d4c:	fee69ee3          	bne	a3,a4,6d48 <.L229>
    6d50:	0ff0000f          	fence
    6d54:	885ff06f          	j	65d8 <.L228>

00006d58 <.L81>:
    6d58:	00300713          	li	a4,3
    6d5c:	00e79663          	bne	a5,a4,6d68 <.L83>
    6d60:	0001ab37          	lui	s6,0x1a
    6d64:	016aa823          	sw	s6,16(s5)

00006d68 <.L83>:
    6d68:	030ac703          	lbu	a4,48(s5)
    6d6c:	16070263          	beqz	a4,6ed0 <.L84>
    6d70:	034aa603          	lw	a2,52(s5)
    6d74:	ffb30737          	lui	a4,0xffb30

00006d78 <.L85>:
    6d78:	22872783          	lw	a5,552(a4) # ffb30228 <__stack_top+0x2e228>
    6d7c:	40c787b3          	sub	a5,a5,a2
    6d80:	fe07cce3          	bltz	a5,6d78 <.L85>
    6d84:	00012783          	lw	a5,0(sp)
    6d88:	ffb22637          	lui	a2,0xffb22
    6d8c:	0007a703          	lw	a4,0(a5)

00006d90 <.L86>:
    6d90:	84062783          	lw	a5,-1984(a2) # ffb21840 <__stack_top+0x1f840>
    6d94:	fe079ee3          	bnez	a5,6d90 <.L86>
    6d98:	80e62023          	sw	a4,-2048(a2)
    6d9c:	80062223          	sw	zero,-2044(a2)
    6da0:	08e00793          	li	a5,142
    6da4:	000025b7          	lui	a1,0x2
    6da8:	80f62423          	sw	a5,-2040(a2)
    6dac:	09158593          	addi	a1,a1,145 # 2091 <_start-0x293f>
    6db0:	80b62e23          	sw	a1,-2020(a2)
    6db4:	00275793          	srli	a5,a4,0x2
    6db8:	000015b7          	lui	a1,0x1
    6dbc:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    6dc0:	0037f793          	andi	a5,a5,3
    6dc4:	00b7e7b3          	or	a5,a5,a1
    6dc8:	82f62023          	sw	a5,-2016(a2)
    6dcc:	02000793          	li	a5,32
    6dd0:	82f62423          	sw	a5,-2008(a2)
    6dd4:	00412583          	lw	a1,4(sp)
    6dd8:	00100793          	li	a5,1
    6ddc:	84f62023          	sw	a5,-1984(a2)
    6de0:	0005a603          	lw	a2,0(a1)
    6de4:	024aa783          	lw	a5,36(s5)
    6de8:	00160613          	addi	a2,a2,1
    6dec:	00c5a023          	sw	a2,0(a1)

00006df0 <.L87>:
    6df0:	00178793          	addi	a5,a5,1
    6df4:	0037f793          	andi	a5,a5,3
    6df8:	02faa223          	sw	a5,36(s5)
    6dfc:	004a2783          	lw	a5,4(s4)
    6e00:	02faaa23          	sw	a5,52(s5)
    6e04:	d65ff06f          	j	6b68 <.L82>

00006e08 <.L207>:
    6e08:	04c12883          	lw	a7,76(sp)
    6e0c:	05c12303          	lw	t1,92(sp)
    6e10:	05012683          	lw	a3,80(sp)
    6e14:	02688333          	mul	t1,a7,t1
    6e18:	04012623          	sw	zero,76(sp)
    6e1c:	006686b3          	add	a3,a3,t1
    6e20:	004a2303          	lw	t1,4(s4)
    6e24:	04d12823          	sw	a3,80(sp)
    6e28:	006888b3          	add	a7,a7,t1
    6e2c:	011a2223          	sw	a7,4(s4)
    6e30:	00300693          	li	a3,3
    6e34:	00d71663          	bne	a4,a3,6e40 <.L209>
    6e38:	0001ab37          	lui	s6,0x1a
    6e3c:	016aa823          	sw	s6,16(s5)

00006e40 <.L209>:
    6e40:	030ac683          	lbu	a3,48(s5)
    6e44:	0a068663          	beqz	a3,6ef0 <.L210>
    6e48:	034aa683          	lw	a3,52(s5)

00006e4c <.L211>:
    6e4c:	2287a703          	lw	a4,552(a5)
    6e50:	40d70733          	sub	a4,a4,a3
    6e54:	fe074ce3          	bltz	a4,6e4c <.L211>
    6e58:	00012703          	lw	a4,0(sp)
    6e5c:	00072683          	lw	a3,0(a4)
    6e60:	ffb22737          	lui	a4,0xffb22

00006e64 <.L212>:
    6e64:	84072883          	lw	a7,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    6e68:	fe089ee3          	bnez	a7,6e64 <.L212>
    6e6c:	80d72023          	sw	a3,-2048(a4)
    6e70:	80072223          	sw	zero,-2044(a4)
    6e74:	01812303          	lw	t1,24(sp)
    6e78:	08e00893          	li	a7,142
    6e7c:	81172423          	sw	a7,-2040(a4)
    6e80:	80672e23          	sw	t1,-2020(a4)
    6e84:	0026d893          	srli	a7,a3,0x2
    6e88:	01c12303          	lw	t1,28(sp)
    6e8c:	0038f893          	andi	a7,a7,3
    6e90:	0068e8b3          	or	a7,a7,t1
    6e94:	83172023          	sw	a7,-2016(a4)
    6e98:	02000893          	li	a7,32
    6e9c:	83172423          	sw	a7,-2008(a4)
    6ea0:	00412303          	lw	t1,4(sp)
    6ea4:	84b72023          	sw	a1,-1984(a4)
    6ea8:	00032703          	lw	a4,0(t1)
    6eac:	004a2883          	lw	a7,4(s4)
    6eb0:	00170713          	addi	a4,a4,1
    6eb4:	00e32023          	sw	a4,0(t1)
    6eb8:	024aa703          	lw	a4,36(s5)

00006ebc <.L213>:
    6ebc:	00170713          	addi	a4,a4,1
    6ec0:	00377713          	andi	a4,a4,3
    6ec4:	02eaa223          	sw	a4,36(s5)
    6ec8:	031aaa23          	sw	a7,52(s5)
    6ecc:	da0ff06f          	j	646c <.L208>

00006ed0 <.L84>:
    6ed0:	00100713          	li	a4,1
    6ed4:	02ea8823          	sb	a4,48(s5)
    6ed8:	00012703          	lw	a4,0(sp)
    6edc:	00072703          	lw	a4,0(a4)
    6ee0:	f11ff06f          	j	6df0 <.L87>

00006ee4 <.L511>:
    6ee4:	00080793          	mv	a5,a6
    6ee8:	00070893          	mv	a7,a4
    6eec:	b58ff06f          	j	6244 <.L99>

00006ef0 <.L210>:
    6ef0:	00012683          	lw	a3,0(sp)
    6ef4:	0006a683          	lw	a3,0(a3)
    6ef8:	02ba8823          	sb	a1,48(s5)
    6efc:	fc1ff06f          	j	6ebc <.L213>

00006f00 <.L500>:
    6f00:	000f2883          	lw	a7,0(t5)
    6f04:	00489893          	slli	a7,a7,0x4

00006f08 <.L202>:
    6f08:	0407a703          	lw	a4,64(a5)
    6f0c:	fe071ee3          	bnez	a4,6f08 <.L202>
    6f10:	0000a737          	lui	a4,0xa
    6f14:	1f270713          	addi	a4,a4,498 # a1f2 <__kernel_data_lma+0x2b0e>
    6f18:	00e7ae23          	sw	a4,28(a5)
    6f1c:	02012703          	lw	a4,32(sp)
    6f20:	00cf0f13          	addi	t5,t5,12
    6f24:	00e8f333          	and	t1,a7,a4
    6f28:	0048d713          	srli	a4,a7,0x4
    6f2c:	02c12883          	lw	a7,44(sp)
    6f30:	0067a823          	sw	t1,16(a5)
    6f34:	010aad03          	lw	s10,16(s5)
    6f38:	01177733          	and	a4,a4,a7
    6f3c:	00e7aa23          	sw	a4,20(a5)
    6f40:	cfab0c63          	beq	s6,s10,6438 <.L308>
    6f44:	416d0333          	sub	t1,s10,s6
    6f48:	00068c13          	mv	s8,a3
    6f4c:	00a36463          	bltu	t1,a0,6f54 <.L202+0x4c>
    6f50:	911fe06f          	j	5860 <.L205>
    6f54:	d64ff06f          	j	64b8 <.L204>

00006f58 <.L503>:
    6f58:	0407a703          	lw	a4,64(a5)
    6f5c:	00c80833          	add	a6,a6,a2
    6f60:	00070463          	beqz	a4,6f68 <.L503+0x10>
    6f64:	9d5fe06f          	j	5938 <.L246>
    6f68:	9d9fe06f          	j	5940 <.L520>

00006f6c <.L248>:
    6f6c:	00300813          	li	a6,3
    6f70:	01089c63          	bne	a7,a6,6f88 <.L250>
    6f74:	0001a837          	lui	a6,0x1a
    6f78:	40a28533          	sub	a0,t0,a0
    6f7c:	016502b3          	add	t0,a0,s6
    6f80:	010aa823          	sw	a6,16(s5)
    6f84:	00080b13          	mv	s6,a6

00006f88 <.L250>:
    6f88:	030ac503          	lbu	a0,48(s5)
    6f8c:	1a050663          	beqz	a0,7138 <.L251>
    6f90:	034aa803          	lw	a6,52(s5)
    6f94:	ffb30537          	lui	a0,0xffb30

00006f98 <.L252>:
    6f98:	22852703          	lw	a4,552(a0) # ffb30228 <__stack_top+0x2e228>
    6f9c:	41070733          	sub	a4,a4,a6
    6fa0:	fe074ce3          	bltz	a4,6f98 <.L252>
    6fa4:	00012703          	lw	a4,0(sp)
    6fa8:	00072803          	lw	a6,0(a4)
    6fac:	ffb22737          	lui	a4,0xffb22

00006fb0 <.L253>:
    6fb0:	84072503          	lw	a0,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    6fb4:	fe051ee3          	bnez	a0,6fb0 <.L253>
    6fb8:	81072023          	sw	a6,-2048(a4)
    6fbc:	80072223          	sw	zero,-2044(a4)
    6fc0:	08e00513          	li	a0,142
    6fc4:	000028b7          	lui	a7,0x2
    6fc8:	80a72423          	sw	a0,-2040(a4)
    6fcc:	09188893          	addi	a7,a7,145 # 2091 <_start-0x293f>
    6fd0:	81172e23          	sw	a7,-2020(a4)
    6fd4:	00285513          	srli	a0,a6,0x2
    6fd8:	000018b7          	lui	a7,0x1
    6fdc:	07c88893          	addi	a7,a7,124 # 107c <_start-0x3954>
    6fe0:	00357513          	andi	a0,a0,3
    6fe4:	01156533          	or	a0,a0,a7
    6fe8:	82a72023          	sw	a0,-2016(a4)
    6fec:	02000513          	li	a0,32
    6ff0:	82a72423          	sw	a0,-2008(a4)
    6ff4:	00412883          	lw	a7,4(sp)
    6ff8:	00100513          	li	a0,1
    6ffc:	84a72023          	sw	a0,-1984(a4)
    7000:	0008a503          	lw	a0,0(a7)
    7004:	004a2703          	lw	a4,4(s4)
    7008:	00150513          	addi	a0,a0,1
    700c:	00a8a023          	sw	a0,0(a7)
    7010:	024aa883          	lw	a7,36(s5)

00007014 <.L254>:
    7014:	00188513          	addi	a0,a7,1
    7018:	00357513          	andi	a0,a0,3
    701c:	02aaa223          	sw	a0,36(s5)
    7020:	02eaaa23          	sw	a4,52(s5)
    7024:	995fe06f          	j	59b8 <.L249>

00007028 <.L121>:
    7028:	0ff0000f          	fence
    702c:	0004a683          	lw	a3,0(s1) # 8000 <__kernel_data_lma+0x91c>
    7030:	02caa903          	lw	s2,44(s5)
    7034:	02daa423          	sw	a3,40(s5)
    7038:	01268463          	beq	a3,s2,7040 <.L121+0x18>
    703c:	cf5fe06f          	j	5d30 <.L120>
    7040:	0ff0000f          	fence
    7044:	0004a683          	lw	a3,0(s1)
    7048:	02caa903          	lw	s2,44(s5)
    704c:	02daa423          	sw	a3,40(s5)
    7050:	fd268ce3          	beq	a3,s2,7028 <.L121>
    7054:	cddfe06f          	j	5d30 <.L120>

00007058 <.L136>:
    7058:	0ff0000f          	fence
    705c:	0004a403          	lw	s0,0(s1)
    7060:	02caa903          	lw	s2,44(s5)
    7064:	028aa423          	sw	s0,40(s5)
    7068:	a72412e3          	bne	s0,s2,6acc <.L135>
    706c:	0ff0000f          	fence
    7070:	0004a403          	lw	s0,0(s1)
    7074:	02caa903          	lw	s2,44(s5)
    7078:	028aa423          	sw	s0,40(s5)
    707c:	fd240ee3          	beq	s0,s2,7058 <.L136>
    7080:	a4dff06f          	j	6acc <.L135>

00007084 <.L513>:
    7084:	00068c13          	mv	s8,a3
    7088:	0407a683          	lw	a3,64(a5)
    708c:	00c80d33          	add	s10,a6,a2
    7090:	ce069463          	bnez	a3,6578 <.L223>
    7094:	cecff06f          	j	6580 <.L521>

00007098 <.L309>:
    7098:	000b0893          	mv	a7,s6
    709c:	000d0b13          	mv	s6,s10
    70a0:	c58ff06f          	j	64f8 <.L225>

000070a4 <.L517>:
    70a4:	40a60833          	sub	a6,a2,a0
    70a8:	00a68533          	add	a0,a3,a0

000070ac <.L187>:
    70ac:	0407a583          	lw	a1,64(a5)
    70b0:	fe059ee3          	bnez	a1,70ac <.L187>
    70b4:	0167a023          	sw	s6,0(a5)
    70b8:	0307a023          	sw	a6,32(a5)
    70bc:	00a7a623          	sw	a0,12(a5)
    70c0:	05c7a023          	sw	t3,64(a5)

000070c4 <.L188>:
    70c4:	0407a583          	lw	a1,64(a5)
    70c8:	fe059ee3          	bnez	a1,70c4 <.L188>
    70cc:	02c7a023          	sw	a2,32(a5)
    70d0:	0067a623          	sw	t1,12(a5)
    70d4:	03c12b03          	lw	s6,60(sp)
    70d8:	04c12583          	lw	a1,76(sp)
    70dc:	04012503          	lw	a0,64(sp)
    70e0:	40bb0b33          	sub	s6,s6,a1
    70e4:	04812803          	lw	a6,72(sp)
    70e8:	04412583          	lw	a1,68(sp)
    70ec:	011b0b33          	add	s6,s6,a7
    70f0:	00150513          	addi	a0,a0,1
    70f4:	010585b3          	add	a1,a1,a6
    70f8:	03612e23          	sw	s6,60(sp)
    70fc:	04a12023          	sw	a0,64(sp)
    7100:	04b12223          	sw	a1,68(sp)
    7104:	80071ee3          	bnez	a4,6920 <.L307>

00007108 <.L518>:
    7108:	00050713          	mv	a4,a0

0000710c <.L172>:
    710c:	004a2683          	lw	a3,4(s4)
    7110:	004ba783          	lw	a5,4(s7)
    7114:	00e68733          	add	a4,a3,a4
    7118:	00b787b3          	add	a5,a5,a1
    711c:	00ea2223          	sw	a4,4(s4)
    7120:	00fba223          	sw	a5,4(s7)
    7124:	8b8fe06f          	j	51dc <.L74>

00007128 <.L515>:
    7128:	0407a883          	lw	a7,64(a5)
    712c:	00c80833          	add	a6,a6,a2
    7130:	d2089463          	bnez	a7,6658 <.L235>
    7134:	d2cff06f          	j	6660 <.L522>

00007138 <.L251>:
    7138:	00100513          	li	a0,1
    713c:	02aa8823          	sb	a0,48(s5)
    7140:	00012503          	lw	a0,0(sp)
    7144:	00052803          	lw	a6,0(a0)
    7148:	ecdff06f          	j	7014 <.L254>

0000714c <.L148>:
    714c:	004a2d03          	lw	s10,4(s4)
    7150:	004bac03          	lw	s8,4(s7)
    7154:	4c049a63          	bnez	s1,7628 <.L523>
    7158:	04c12603          	lw	a2,76(sp)
    715c:	05012683          	lw	a3,80(sp)
    7160:	01a60633          	add	a2,a2,s10
    7164:	018686b3          	add	a3,a3,s8
    7168:	04012623          	sw	zero,76(sp)
    716c:	00ca2223          	sw	a2,4(s4)
    7170:	00dba223          	sw	a3,4(s7)
    7174:	04012823          	sw	zero,80(sp)
    7178:	44588a63          	beq	a7,t0,75cc <.L298>

0000717c <.L154>:
    717c:	030ac683          	lbu	a3,48(s5)
    7180:	42068063          	beqz	a3,75a0 <.L155>

00007184 <.L527>:
    7184:	034aa883          	lw	a7,52(s5)
    7188:	ffb30637          	lui	a2,0xffb30

0000718c <.L156>:
    718c:	22862683          	lw	a3,552(a2) # ffb30228 <__stack_top+0x2e228>
    7190:	411686b3          	sub	a3,a3,a7
    7194:	fe06cce3          	bltz	a3,718c <.L156>
    7198:	00012683          	lw	a3,0(sp)
    719c:	0006a883          	lw	a7,0(a3)
    71a0:	ffb226b7          	lui	a3,0xffb22

000071a4 <.L157>:
    71a4:	8406a603          	lw	a2,-1984(a3) # ffb21840 <__stack_top+0x1f840>
    71a8:	fe061ee3          	bnez	a2,71a4 <.L157>
    71ac:	8116a023          	sw	a7,-2048(a3)
    71b0:	8006a223          	sw	zero,-2044(a3)
    71b4:	08e00613          	li	a2,142
    71b8:	00002937          	lui	s2,0x2
    71bc:	80c6a423          	sw	a2,-2040(a3)
    71c0:	09190913          	addi	s2,s2,145 # 2091 <_start-0x293f>
    71c4:	8126ae23          	sw	s2,-2020(a3)
    71c8:	0028d613          	srli	a2,a7,0x2
    71cc:	00001937          	lui	s2,0x1
    71d0:	00367613          	andi	a2,a2,3
    71d4:	07c90913          	addi	s2,s2,124 # 107c <_start-0x3954>
    71d8:	01266633          	or	a2,a2,s2
    71dc:	82c6a023          	sw	a2,-2016(a3)
    71e0:	02000613          	li	a2,32
    71e4:	82c6a423          	sw	a2,-2008(a3)
    71e8:	00100613          	li	a2,1
    71ec:	84c6a023          	sw	a2,-1984(a3)
    71f0:	00412603          	lw	a2,4(sp)
    71f4:	00062683          	lw	a3,0(a2)
    71f8:	00168693          	addi	a3,a3,1
    71fc:	00d62023          	sw	a3,0(a2)
    7200:	3b00006f          	j	75b0 <.L158>

00007204 <.L506>:
    7204:	05c12583          	lw	a1,92(sp)
    7208:	004a2683          	lw	a3,4(s4)
    720c:	0005a883          	lw	a7,0(a1)
    7210:	06012603          	lw	a2,96(sp)
    7214:	011686b3          	add	a3,a3,a7
    7218:	00da2223          	sw	a3,4(s4)
    721c:	00062683          	lw	a3,0(a2)
    7220:	004ba903          	lw	s2,4(s7)
    7224:	409508b3          	sub	a7,a0,s1
    7228:	012686b3          	add	a3,a3,s2
    722c:	00dba223          	sw	a3,4(s7)
    7230:	0005a023          	sw	zero,0(a1)
    7234:	00062023          	sw	zero,0(a2)
    7238:	004ba603          	lw	a2,4(s7)
    723c:	009805b3          	add	a1,a6,s1

00007240 <.L161>:
    7240:	2047a683          	lw	a3,516(a5)
    7244:	fec69ee3          	bne	a3,a2,7240 <.L161>
    7248:	0ff0000f          	fence

0000724c <.L162>:
    724c:	0407a683          	lw	a3,64(a5)
    7250:	fe069ee3          	bnez	a3,724c <.L162>
    7254:	0167a023          	sw	s6,0(a5)
    7258:	0317a023          	sw	a7,32(a5)
    725c:	00b7a623          	sw	a1,12(a5)
    7260:	05f7a023          	sw	t6,64(a5)

00007264 <.L163>:
    7264:	0407a683          	lw	a3,64(a5)
    7268:	fe069ee3          	bnez	a3,7264 <.L163>
    726c:	02a7a023          	sw	a0,32(a5)
    7270:	0107a623          	sw	a6,12(a5)
    7274:	04c12683          	lw	a3,76(sp)
    7278:	05012603          	lw	a2,80(sp)
    727c:	00168693          	addi	a3,a3,1
    7280:	00c408b3          	add	a7,s0,a2
    7284:	01630b33          	add	s6,t1,s6
    7288:	04d12623          	sw	a3,76(sp)
    728c:	05112823          	sw	a7,80(sp)
    7290:	409b0b33          	sub	s6,s6,s1
    7294:	00070463          	beqz	a4,729c <.L507>
    7298:	da1fe06f          	j	6038 <.L304>

0000729c <.L507>:
    729c:	00068713          	mv	a4,a3

000072a0 <.L146>:
    72a0:	004a2683          	lw	a3,4(s4)
    72a4:	004ba783          	lw	a5,4(s7)
    72a8:	00e68733          	add	a4,a3,a4
    72ac:	011787b3          	add	a5,a5,a7
    72b0:	00ea2223          	sw	a4,4(s4)
    72b4:	00fba223          	sw	a5,4(s7)
    72b8:	f25fd06f          	j	51dc <.L74>

000072bc <.L128>:
    72bc:	2c778c63          	beq	a5,t2,7594 <.L524>

000072c0 <.L130>:
    72c0:	030ac403          	lbu	s0,48(s5)
    72c4:	2a040463          	beqz	s0,756c <.L131>
    72c8:	034aa483          	lw	s1,52(s5)
    72cc:	ffb30437          	lui	s0,0xffb30

000072d0 <.L132>:
    72d0:	22842783          	lw	a5,552(s0) # ffb30228 <__stack_top+0x2e228>
    72d4:	409787b3          	sub	a5,a5,s1
    72d8:	fe07cce3          	bltz	a5,72d0 <.L132>
    72dc:	00012783          	lw	a5,0(sp)
    72e0:	0007a483          	lw	s1,0(a5)
    72e4:	ffb227b7          	lui	a5,0xffb22

000072e8 <.L133>:
    72e8:	8407a403          	lw	s0,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    72ec:	fe041ee3          	bnez	s0,72e8 <.L133>
    72f0:	8097a023          	sw	s1,-2048(a5)
    72f4:	8007a223          	sw	zero,-2044(a5)
    72f8:	08e00413          	li	s0,142
    72fc:	00002937          	lui	s2,0x2
    7300:	8087a423          	sw	s0,-2040(a5)
    7304:	09190913          	addi	s2,s2,145 # 2091 <_start-0x293f>
    7308:	8127ae23          	sw	s2,-2020(a5)
    730c:	0024d413          	srli	s0,s1,0x2
    7310:	00001937          	lui	s2,0x1
    7314:	07c90913          	addi	s2,s2,124 # 107c <_start-0x3954>
    7318:	00347413          	andi	s0,s0,3
    731c:	01246433          	or	s0,s0,s2
    7320:	8287a023          	sw	s0,-2016(a5)
    7324:	02000413          	li	s0,32
    7328:	8287a423          	sw	s0,-2008(a5)
    732c:	00412903          	lw	s2,4(sp)
    7330:	00100413          	li	s0,1
    7334:	8487a023          	sw	s0,-1984(a5)
    7338:	00092403          	lw	s0,0(s2)
    733c:	024aa783          	lw	a5,36(s5)
    7340:	00140413          	addi	s0,s0,1
    7344:	00892023          	sw	s0,0(s2)
    7348:	2340006f          	j	757c <.L134>

0000734c <.L113>:
    734c:	20878a63          	beq	a5,s0,7560 <.L525>

00007350 <.L115>:
    7350:	030ac683          	lbu	a3,48(s5)
    7354:	1e068263          	beqz	a3,7538 <.L116>
    7358:	034aa483          	lw	s1,52(s5)
    735c:	ffb306b7          	lui	a3,0xffb30

00007360 <.L117>:
    7360:	2286a783          	lw	a5,552(a3) # ffb30228 <__stack_top+0x2e228>
    7364:	409787b3          	sub	a5,a5,s1
    7368:	fe07cce3          	bltz	a5,7360 <.L117>
    736c:	00012783          	lw	a5,0(sp)
    7370:	0007a483          	lw	s1,0(a5)
    7374:	ffb227b7          	lui	a5,0xffb22

00007378 <.L118>:
    7378:	8407a683          	lw	a3,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    737c:	fe069ee3          	bnez	a3,7378 <.L118>
    7380:	8097a023          	sw	s1,-2048(a5)
    7384:	8007a223          	sw	zero,-2044(a5)
    7388:	08e00693          	li	a3,142
    738c:	00002937          	lui	s2,0x2
    7390:	80d7a423          	sw	a3,-2040(a5)
    7394:	09190913          	addi	s2,s2,145 # 2091 <_start-0x293f>
    7398:	8127ae23          	sw	s2,-2020(a5)
    739c:	0024d693          	srli	a3,s1,0x2
    73a0:	00001937          	lui	s2,0x1
    73a4:	07c90913          	addi	s2,s2,124 # 107c <_start-0x3954>
    73a8:	0036f693          	andi	a3,a3,3
    73ac:	0126e6b3          	or	a3,a3,s2
    73b0:	82d7a023          	sw	a3,-2016(a5)
    73b4:	02000693          	li	a3,32
    73b8:	82d7a423          	sw	a3,-2008(a5)
    73bc:	00412903          	lw	s2,4(sp)
    73c0:	00100693          	li	a3,1
    73c4:	84d7a023          	sw	a3,-1984(a5)
    73c8:	00092683          	lw	a3,0(s2)
    73cc:	024aa783          	lw	a5,36(s5)
    73d0:	00168693          	addi	a3,a3,1
    73d4:	00d92023          	sw	a3,0(s2)
    73d8:	1700006f          	j	7548 <.L119>

000073dc <.L174>:
    73dc:	04912623          	sw	s1,76(sp)
    73e0:	0c049a63          	bnez	s1,74b4 <.L526>
    73e4:	04012283          	lw	t0,64(sp)
    73e8:	004a2583          	lw	a1,4(s4)
    73ec:	04012023          	sw	zero,64(sp)
    73f0:	005585b3          	add	a1,a1,t0
    73f4:	00ba2223          	sw	a1,4(s4)
    73f8:	04412283          	lw	t0,68(sp)
    73fc:	004ba583          	lw	a1,4(s7)
    7400:	04012223          	sw	zero,68(sp)
    7404:	005585b3          	add	a1,a1,t0
    7408:	00bba223          	sw	a1,4(s7)
    740c:	00300593          	li	a1,3
    7410:	1eb50863          	beq	a0,a1,7600 <.L299>

00007414 <.L179>:
    7414:	030ac583          	lbu	a1,48(s5)
    7418:	1e058e63          	beqz	a1,7614 <.L180>

0000741c <.L528>:
    741c:	034aa283          	lw	t0,52(s5)
    7420:	ffb30537          	lui	a0,0xffb30

00007424 <.L181>:
    7424:	22852583          	lw	a1,552(a0) # ffb30228 <__stack_top+0x2e228>
    7428:	405585b3          	sub	a1,a1,t0
    742c:	fe05cce3          	bltz	a1,7424 <.L181>
    7430:	00012583          	lw	a1,0(sp)
    7434:	ffb222b7          	lui	t0,0xffb22
    7438:	0005a503          	lw	a0,0(a1)

0000743c <.L182>:
    743c:	8402a583          	lw	a1,-1984(t0) # ffb21840 <__stack_top+0x1f840>
    7440:	fe059ee3          	bnez	a1,743c <.L182>
    7444:	80a2a023          	sw	a0,-2048(t0)
    7448:	8002a223          	sw	zero,-2044(t0)
    744c:	08e00593          	li	a1,142
    7450:	000024b7          	lui	s1,0x2
    7454:	80b2a423          	sw	a1,-2040(t0)
    7458:	09148493          	addi	s1,s1,145 # 2091 <_start-0x293f>
    745c:	8092ae23          	sw	s1,-2020(t0)
    7460:	00255593          	srli	a1,a0,0x2
    7464:	000014b7          	lui	s1,0x1
    7468:	0035f593          	andi	a1,a1,3
    746c:	07c48493          	addi	s1,s1,124 # 107c <_start-0x3954>
    7470:	0095e5b3          	or	a1,a1,s1
    7474:	82b2a023          	sw	a1,-2016(t0)
    7478:	02000593          	li	a1,32
    747c:	82b2a423          	sw	a1,-2008(t0)
    7480:	00100593          	li	a1,1
    7484:	84b2a023          	sw	a1,-1984(t0)
    7488:	00412283          	lw	t0,4(sp)
    748c:	0002a583          	lw	a1,0(t0)
    7490:	00158593          	addi	a1,a1,1
    7494:	00b2a023          	sw	a1,0(t0)

00007498 <.L183>:
    7498:	024aa583          	lw	a1,36(s5)
    749c:	004a2283          	lw	t0,4(s4)
    74a0:	00158593          	addi	a1,a1,1
    74a4:	0035f593          	andi	a1,a1,3
    74a8:	025aaa23          	sw	t0,52(s5)
    74ac:	02baa223          	sw	a1,36(s5)
    74b0:	bd0ff06f          	j	6880 <.L175>

000074b4 <.L526>:
    74b4:	ffb302b7          	lui	t0,0xffb30

000074b8 <.L177>:
    74b8:	0402ad83          	lw	s11,64(t0) # ffb30040 <__stack_top+0x2e040>
    74bc:	fe0d9ee3          	bnez	s11,74b8 <.L177>
    74c0:	0162a023          	sw	s6,0(t0)
    74c4:	10000b37          	lui	s6,0x10000
    74c8:	0292a023          	sw	s1,32(t0)
    74cc:	0165f4b3          	and	s1,a1,s6
    74d0:	00459593          	slli	a1,a1,0x4
    74d4:	0092a823          	sw	s1,16(t0)
    74d8:	0085d593          	srli	a1,a1,0x8
    74dc:	00b2aa23          	sw	a1,20(t0)
    74e0:	00100593          	li	a1,1
    74e4:	04b2a023          	sw	a1,64(t0)
    74e8:	04812b03          	lw	s6,72(sp)
    74ec:	04412283          	lw	t0,68(sp)
    74f0:	004a2483          	lw	s1,4(s4)
    74f4:	04012583          	lw	a1,64(sp)
    74f8:	016282b3          	add	t0,t0,s6
    74fc:	004bab03          	lw	s6,4(s7)
    7500:	009585b3          	add	a1,a1,s1
    7504:	016282b3          	add	t0,t0,s6
    7508:	00158593          	addi	a1,a1,1
    750c:	00300493          	li	s1,3
    7510:	00ba2223          	sw	a1,4(s4)
    7514:	005ba223          	sw	t0,4(s7)
    7518:	0e950063          	beq	a0,s1,75f8 <.L178>
    751c:	03c12583          	lw	a1,60(sp)
    7520:	04c12503          	lw	a0,76(sp)
    7524:	04012023          	sw	zero,64(sp)
    7528:	00a585b3          	add	a1,a1,a0
    752c:	04012223          	sw	zero,68(sp)
    7530:	02b12e23          	sw	a1,60(sp)
    7534:	ee1ff06f          	j	7414 <.L179>

00007538 <.L116>:
    7538:	00100693          	li	a3,1
    753c:	02da8823          	sb	a3,48(s5)
    7540:	00012683          	lw	a3,0(sp)
    7544:	0006a483          	lw	s1,0(a3)

00007548 <.L119>:
    7548:	00178793          	addi	a5,a5,1
    754c:	0037f793          	andi	a5,a5,3
    7550:	02faa223          	sw	a5,36(s5)
    7554:	004a2783          	lw	a5,4(s4)
    7558:	02faaa23          	sw	a5,52(s5)
    755c:	fc4fe06f          	j	5d20 <.L114>

00007560 <.L525>:
    7560:	0001ab37          	lui	s6,0x1a
    7564:	016aa823          	sw	s6,16(s5)
    7568:	de9ff06f          	j	7350 <.L115>

0000756c <.L131>:
    756c:	00100413          	li	s0,1
    7570:	028a8823          	sb	s0,48(s5)
    7574:	00012403          	lw	s0,0(sp)
    7578:	00042483          	lw	s1,0(s0)

0000757c <.L134>:
    757c:	00178793          	addi	a5,a5,1
    7580:	0037f793          	andi	a5,a5,3
    7584:	02faa223          	sw	a5,36(s5)
    7588:	004a2783          	lw	a5,4(s4)
    758c:	02faaa23          	sw	a5,52(s5)
    7590:	d30ff06f          	j	6ac0 <.L129>

00007594 <.L524>:
    7594:	0001ab37          	lui	s6,0x1a
    7598:	016aa823          	sw	s6,16(s5)
    759c:	d25ff06f          	j	72c0 <.L130>

000075a0 <.L155>:
    75a0:	00100693          	li	a3,1
    75a4:	02da8823          	sb	a3,48(s5)
    75a8:	00012683          	lw	a3,0(sp)
    75ac:	0006a883          	lw	a7,0(a3)

000075b0 <.L158>:
    75b0:	024aa683          	lw	a3,36(s5)
    75b4:	004a2603          	lw	a2,4(s4)
    75b8:	00168693          	addi	a3,a3,1
    75bc:	0036f693          	andi	a3,a3,3
    75c0:	02caaa23          	sw	a2,52(s5)
    75c4:	02daa223          	sw	a3,36(s5)
    75c8:	9a1fe06f          	j	5f68 <.L149>

000075cc <.L298>:
    75cc:	0001ab37          	lui	s6,0x1a
    75d0:	030ac683          	lbu	a3,48(s5)
    75d4:	016aa823          	sw	s6,16(s5)
    75d8:	fc0684e3          	beqz	a3,75a0 <.L155>
    75dc:	ba9ff06f          	j	7184 <.L527>

000075e0 <.L516>:
    75e0:	00f60893          	addi	a7,a2,15
    75e4:	ff08f893          	andi	a7,a7,-16
    75e8:	9b8ff06f          	j	67a0 <.L170>

000075ec <.L505>:
    75ec:	00f50313          	addi	t1,a0,15
    75f0:	ff037313          	andi	t1,t1,-16
    75f4:	8c9fe06f          	j	5ebc <.L144>

000075f8 <.L178>:
    75f8:	04012023          	sw	zero,64(sp)
    75fc:	04012223          	sw	zero,68(sp)

00007600 <.L299>:
    7600:	0001a5b7          	lui	a1,0x1a
    7604:	02b12e23          	sw	a1,60(sp)
    7608:	00baa823          	sw	a1,16(s5)
    760c:	030ac583          	lbu	a1,48(s5)
    7610:	e00596e3          	bnez	a1,741c <.L528>

00007614 <.L180>:
    7614:	00100593          	li	a1,1
    7618:	02ba8823          	sb	a1,48(s5)
    761c:	00012583          	lw	a1,0(sp)
    7620:	0005a503          	lw	a0,0(a1) # 1a000 <__kernel_data_lma+0x1291c>
    7624:	e75ff06f          	j	7498 <.L183>

00007628 <.L523>:
    7628:	05c12c83          	lw	s9,92(sp)
    762c:	06012603          	lw	a2,96(sp)
    7630:	000ca683          	lw	a3,0(s9)
    7634:	01a686b3          	add	a3,a3,s10
    7638:	00da2223          	sw	a3,4(s4)
    763c:	00062683          	lw	a3,0(a2)
    7640:	ffb30d37          	lui	s10,0xffb30
    7644:	018686b3          	add	a3,a3,s8
    7648:	00dba223          	sw	a3,4(s7)
    764c:	000ca023          	sw	zero,0(s9)
    7650:	00062023          	sw	zero,0(a2)
    7654:	004ba683          	lw	a3,4(s7)

00007658 <.L151>:
    7658:	204d2603          	lw	a2,516(s10) # ffb30204 <__stack_top+0x2e204>
    765c:	fed61ee3          	bne	a2,a3,7658 <.L151>
    7660:	0ff0000f          	fence
    7664:	ffb306b7          	lui	a3,0xffb30

00007668 <.L152>:
    7668:	0406a603          	lw	a2,64(a3) # ffb30040 <__stack_top+0x2e040>
    766c:	fe061ee3          	bnez	a2,7668 <.L152>
    7670:	0166a023          	sw	s6,0(a3)
    7674:	10000637          	lui	a2,0x10000
    7678:	0296a023          	sw	s1,32(a3)
    767c:	00c5f633          	and	a2,a1,a2
    7680:	00c6a823          	sw	a2,16(a3)
    7684:	00459613          	slli	a2,a1,0x4
    7688:	00865613          	srli	a2,a2,0x8
    768c:	00c6aa23          	sw	a2,20(a3)
    7690:	00100613          	li	a2,1
    7694:	04c6a023          	sw	a2,64(a3)
    7698:	004bab03          	lw	s6,4(s7)
    769c:	05012683          	lw	a3,80(sp)
    76a0:	04c12603          	lw	a2,76(sp)
    76a4:	016686b3          	add	a3,a3,s6
    76a8:	004a2b03          	lw	s6,4(s4)
    76ac:	008686b3          	add	a3,a3,s0
    76b0:	01660633          	add	a2,a2,s6
    76b4:	00160613          	addi	a2,a2,1 # 10000001 <__kernel_data_lma+0xfff891d>
    76b8:	00300b13          	li	s6,3
    76bc:	00ca2223          	sw	a2,4(s4)
    76c0:	00dba223          	sw	a3,4(s7)
    76c4:	04012623          	sw	zero,76(sp)
    76c8:	04012823          	sw	zero,80(sp)
    76cc:	f16880e3          	beq	a7,s6,75cc <.L298>
    76d0:	00090b13          	mv	s6,s2
    76d4:	aa9ff06f          	j	717c <.L154>

000076d8 <.L311>:
    76d8:	001cfc93          	andi	s9,s9,1
    76dc:	00000c13          	li	s8,0
    76e0:	a88fe06f          	j	5968 <.L224>
