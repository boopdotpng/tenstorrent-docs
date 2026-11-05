
/tmp/tt-disasm-hu35fqi6/out.elf:     file format elf32-littleriscv


Disassembly of section .text:

000049d0 <_start>:
    49d0:	fe010113          	addi	sp,sp,-32
    49d4:	00112e23          	sw	ra,28(sp)
    49d8:	00812c23          	sw	s0,24(sp)
    49dc:	00912a23          	sw	s1,20(sp)
    49e0:	01212823          	sw	s2,16(sp)
    49e4:	01312623          	sw	s3,12(sp)
    49e8:	01412423          	sw	s4,8(sp)
    49ec:	ffb017b7          	lui	a5,0xffb01
    49f0:	ffb01737          	lui	a4,0xffb01
    49f4:	92c78793          	addi	a5,a5,-1748 # ffb0092c <_ZL17ringbuffer_offset>
    49f8:	93470713          	addi	a4,a4,-1740 # ffb00934 <__ldm_bss_end>
    49fc:	00f76e63          	bltu	a4,a5,4a18 <.L1017>

00004a00 <.L1018>:
    4a00:	fe07ae23          	sw	zero,-4(a5)
    4a04:	fe07ac23          	sw	zero,-8(a5)
    4a08:	fe07aa23          	sw	zero,-12(a5)
    4a0c:	fe07a823          	sw	zero,-16(a5)
    4a10:	01078793          	addi	a5,a5,16
    4a14:	fef776e3          	bgeu	a4,a5,4a00 <.L1018>

00004a18 <.L1017>:
    4a18:	ff878693          	addi	a3,a5,-8
    4a1c:	1ad76c63          	bltu	a4,a3,4bd4 <.L1035>
    4a20:	fe07aa23          	sw	zero,-12(a5)
    4a24:	fe07a823          	sw	zero,-16(a5)

00004a28 <.L1019>:
    4a28:	ffc78693          	addi	a3,a5,-4
    4a2c:	00d76463          	bltu	a4,a3,4a34 <.L1020>
    4a30:	fe07ac23          	sw	zero,-8(a5)

00004a34 <.L1020>:
    4a34:	0000c737          	lui	a4,0xc
    4a38:	ffb017b7          	lui	a5,0xffb01
    4a3c:	8b470713          	addi	a4,a4,-1868 # b8b4 <__kernel_data_lma>
    4a40:	88078793          	addi	a5,a5,-1920 # ffb00880 <__ldm_data_start>
    4a44:	06f70263          	beq	a4,a5,4aa8 <.L1022>
    4a48:	ffb01637          	lui	a2,0xffb01
    4a4c:	91c60613          	addi	a2,a2,-1764 # ffb0091c <_ZZ16fetch_q_get_cmdsILm0EEvRmS0_S0_E17pending_read_size>
    4a50:	40f60633          	sub	a2,a2,a5
    4a54:	00800593          	li	a1,8
    4a58:	40265693          	srai	a3,a2,0x2
    4a5c:	02c5d863          	bge	a1,a2,4a8c <.L1023>
    4a60:	00200813          	li	a6,2

00004a64 <.L1024>:
    4a64:	00072503          	lw	a0,0(a4)
    4a68:	00472583          	lw	a1,4(a4)
    4a6c:	00872603          	lw	a2,8(a4)
    4a70:	00c70713          	addi	a4,a4,12
    4a74:	00c78793          	addi	a5,a5,12
    4a78:	ffd68693          	addi	a3,a3,-3
    4a7c:	fea7aa23          	sw	a0,-12(a5)
    4a80:	feb7ac23          	sw	a1,-8(a5)
    4a84:	fec7ae23          	sw	a2,-4(a5)
    4a88:	fcd84ee3          	blt	a6,a3,4a64 <.L1024>

00004a8c <.L1023>:
    4a8c:	00d05e63          	blez	a3,4aa8 <.L1022>
    4a90:	00072583          	lw	a1,0(a4)
    4a94:	00200613          	li	a2,2
    4a98:	00b7a023          	sw	a1,0(a5)
    4a9c:	00c69663          	bne	a3,a2,4aa8 <.L1022>
    4aa0:	00472703          	lw	a4,4(a4)
    4aa4:	00e7a223          	sw	a4,4(a5)

00004aa8 <.L1022>:
    4aa8:	ffb207b7          	lui	a5,0xffb20
    4aac:	2087a583          	lw	a1,520(a5) # ffb20208 <__stack_top+0x1e208>
    4ab0:	2287a603          	lw	a2,552(a5)
    4ab4:	2047a683          	lw	a3,516(a5)
    4ab8:	2007a703          	lw	a4,512(a5)
    4abc:	22c7a783          	lw	a5,556(a5)
    4ac0:	ffb00a37          	lui	s4,0xffb00
    4ac4:	ffb009b7          	lui	s3,0xffb00
    4ac8:	ffb00937          	lui	s2,0xffb00
    4acc:	ffb004b7          	lui	s1,0xffb00
    4ad0:	ffb00437          	lui	s0,0xffb00
    4ad4:	02d92623          	sw	a3,44(s2) # ffb0002c <noc_nonposted_writes_acked>
    4ad8:	02ba2e23          	sw	a1,60(s4) # ffb0003c <noc_reads_num_issued>
    4adc:	02c9aa23          	sw	a2,52(s3) # ffb00034 <noc_nonposted_writes_num_issued>
    4ae0:	02e4a223          	sw	a4,36(s1) # ffb00024 <noc_nonposted_atomics_acked>
    4ae4:	00f42e23          	sw	a5,28(s0) # ffb0001c <noc_posted_writes_num_issued>
    4ae8:	3a002703          	lw	a4,928(zero) # 3a0 <_start-0x4630>
    4aec:	08000693          	li	a3,128
    4af0:	00271713          	slli	a4,a4,0x2
    4af4:	37374783          	lbu	a5,883(a4)
    4af8:	06070713          	addi	a4,a4,96
    4afc:	00d78863          	beq	a5,a3,4b0c <.L1026>

00004b00 <.L1027>:
    4b00:	0ff0000f          	fence
    4b04:	31374783          	lbu	a5,787(a4)
    4b08:	fed79ce3          	bne	a5,a3,4b00 <.L1027>

00004b0c <.L1026>:
    4b0c:	00800313          	li	t1,8
    4b10:	7c033073          	csrc	0x7c0,t1
    4b14:	00100313          	li	t1,1
    4b18:	01831313          	slli	t1,t1,0x18
    4b1c:	0ff0000f          	fence
    4b20:	7c032073          	csrs	0x7c0,t1
    4b24:	361050ef          	jal	a684 <_Z14kernel_main_hdv>
    4b28:	ffb017b7          	lui	a5,0xffb01
    4b2c:	86c7a603          	lw	a2,-1940(a5) # ffb0086c <sem_l1_base>
    4b30:	ffb016b7          	lui	a3,0xffb01

00004b34 <.L1028>:
    4b34:	0ff0000f          	fence
    4b38:	9246a703          	lw	a4,-1756(a3) # ffb00924 <_ZN24DispatchRelayInlineState9cb_writerE>
    4b3c:	00062783          	lw	a5,0(a2)
    4b40:	00e787b3          	add	a5,a5,a4
    4b44:	0807c793          	xori	a5,a5,128
    4b48:	00179713          	slli	a4,a5,0x1
    4b4c:	fe0714e3          	bnez	a4,4b34 <.L1028>
    4b50:	0ff0000f          	fence
    4b54:	03ca2683          	lw	a3,60(s4)
    4b58:	ffb20737          	lui	a4,0xffb20

00004b5c <.L1029>:
    4b5c:	20872783          	lw	a5,520(a4) # ffb20208 <__stack_top+0x1e208>
    4b60:	fed79ee3          	bne	a5,a3,4b5c <.L1029>
    4b64:	0349a683          	lw	a3,52(s3)
    4b68:	ffb20737          	lui	a4,0xffb20

00004b6c <.L1030>:
    4b6c:	22872783          	lw	a5,552(a4) # ffb20228 <__stack_top+0x1e228>
    4b70:	fed79ee3          	bne	a5,a3,4b6c <.L1030>
    4b74:	02c92683          	lw	a3,44(s2)
    4b78:	ffb20737          	lui	a4,0xffb20

00004b7c <.L1031>:
    4b7c:	20472783          	lw	a5,516(a4) # ffb20204 <__stack_top+0x1e204>
    4b80:	fed79ee3          	bne	a5,a3,4b7c <.L1031>
    4b84:	0244a683          	lw	a3,36(s1)
    4b88:	ffb20737          	lui	a4,0xffb20

00004b8c <.L1032>:
    4b8c:	20072783          	lw	a5,512(a4) # ffb20200 <__stack_top+0x1e200>
    4b90:	fed79ee3          	bne	a5,a3,4b8c <.L1032>
    4b94:	01c42683          	lw	a3,28(s0)
    4b98:	ffb20737          	lui	a4,0xffb20

00004b9c <.L1033>:
    4b9c:	22c72783          	lw	a5,556(a4) # ffb2022c <__stack_top+0x1e22c>
    4ba0:	fed79ee3          	bne	a5,a3,4b9c <.L1033>
    4ba4:	0ff0000f          	fence
    4ba8:	00800313          	li	t1,8
    4bac:	7c032073          	csrs	0x7c0,t1
    4bb0:	01c12083          	lw	ra,28(sp)
    4bb4:	01812403          	lw	s0,24(sp)
    4bb8:	01412483          	lw	s1,20(sp)
    4bbc:	01012903          	lw	s2,16(sp)
    4bc0:	00c12983          	lw	s3,12(sp)
    4bc4:	00812a03          	lw	s4,8(sp)
    4bc8:	00000513          	li	a0,0
    4bcc:	02010113          	addi	sp,sp,32
    4bd0:	00008067          	ret

00004bd4 <.L1035>:
    4bd4:	00068793          	mv	a5,a3
    4bd8:	e51ff06f          	j	4a28 <.L1019>

00004bdc <_Z24paged_read_into_cmddat_qRmR20PrefetchExecBufState>:
    4bdc:	fd010113          	addi	sp,sp,-48
    4be0:	02812623          	sw	s0,44(sp)
    4be4:	0085a403          	lw	s0,8(a1)
    4be8:	000407b7          	lui	a5,0x40
    4bec:	01412e23          	sw	s4,28(sp)
    4bf0:	0087da33          	srl	s4,a5,s0
    4bf4:	0001a7b7          	lui	a5,0x1a
    4bf8:	008a1a33          	sll	s4,s4,s0
    4bfc:	44078793          	addi	a5,a5,1088 # 1a440 <__kernel_data_lma+0xeb8c>
    4c00:	00052703          	lw	a4,0(a0)
    4c04:	02912423          	sw	s1,40(sp)
    4c08:	01712823          	sw	s7,16(sp)
    4c0c:	00100313          	li	t1,1
    4c10:	00fa0a33          	add	s4,s4,a5
    4c14:	0005a803          	lw	a6,0(a1)
    4c18:	0045af83          	lw	t6,4(a1)
    4c1c:	00c5ab83          	lw	s7,12(a1)
    4c20:	0145a383          	lw	t2,20(a1)
    4c24:	00058493          	mv	s1,a1
    4c28:	00831333          	sll	t1,t1,s0
    4c2c:	01471463          	bne	a4,s4,4c34 <.L2>
    4c30:	00f52023          	sw	a5,0(a0)

00004c34 <.L2>:
    4c34:	fff30e13          	addi	t3,t1,-1
    4c38:	03fe6e13          	ori	t3,t3,63
    4c3c:	001e0e13          	addi	t3,t3,1
    4c40:	ffb21737          	lui	a4,0xffb21

00004c44 <.L3>:
    4c44:	84072783          	lw	a5,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    4c48:	fe079ee3          	bnez	a5,4c44 <.L3>
    4c4c:	40000793          	li	a5,1024
    4c50:	80f72c23          	sw	a5,-2024(a4)
    4c54:	ffb21737          	lui	a4,0xffb21

00004c58 <.L4>:
    4c58:	84072783          	lw	a5,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    4c5c:	fe079ee3          	bnez	a5,4c58 <.L4>
    4c60:	82672023          	sw	t1,-2016(a4)
    4c64:	0184a783          	lw	a5,24(s1)
    4c68:	ffb20737          	lui	a4,0xffb20
    4c6c:	12079663          	bnez	a5,4d98 <.L5>
    4c70:	03312023          	sw	s3,32(sp)
    4c74:	000049b7          	lui	s3,0x4
    4c78:	01a12223          	sw	s10,4(sp)
    4c7c:	0089d9b3          	srl	s3,s3,s0
    4c80:	0b79d9b3          	minu	s3,s3,s7
    4c84:	00080693          	mv	a3,a6
    4c88:	413b8bb3          	sub	s7,s7,s3
    4c8c:	00899d33          	sll	s10,s3,s0
    4c90:	2c098263          	beqz	s3,4f54 <.L6>
    4c94:	01612a23          	sw	s6,20(sp)
    4c98:	ffb20b37          	lui	s6,0xffb20
    4c9c:	244b2283          	lw	t0,580(s6) # ffb20244 <__stack_top+0x1e244>
    4ca0:	01512c23          	sw	s5,24(sp)
    4ca4:	0ff00a93          	li	s5,255
    4ca8:	03212223          	sw	s2,36(sp)
    4cac:	ffb00f37          	lui	t5,0xffb00
    4cb0:	ffb00eb7          	lui	t4,0xffb00
    4cb4:	ffb00537          	lui	a0,0xffb00
    4cb8:	924925b7          	lui	a1,0x92492
    4cbc:	405a82b3          	sub	t0,s5,t0
    4cc0:	01812623          	sw	s8,12(sp)
    4cc4:	0b32d2b3          	minu	t0,t0,s3
    4cc8:	01912423          	sw	s9,8(sp)
    4ccc:	644f0f13          	addi	t5,t5,1604 # ffb00644 <bank_to_dram_offset>
    4cd0:	448e8e93          	addi	t4,t4,1096 # ffb00448 <dram_bank_to_noc_xy>
    4cd4:	03c50513          	addi	a0,a0,60 # ffb0003c <noc_reads_num_issued>
    4cd8:	49358593          	addi	a1,a1,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    4cdc:	ffb21737          	lui	a4,0xffb21
    4ce0:	00100913          	li	s2,1
    4ce4:	405989b3          	sub	s3,s3,t0
    4ce8:	0a028263          	beqz	t0,4d8c <.L22>

00004cec <.L51>:
    4cec:	010286b3          	add	a3,t0,a6
    4cf0:	00038893          	mv	a7,t2

00004cf4 <.L9>:
    4cf4:	02b83c33          	mulhu	s8,a6,a1
    4cf8:	00052c83          	lw	s9,0(a0)
    4cfc:	002c5c13          	srli	s8,s8,0x2
    4d00:	003c1793          	slli	a5,s8,0x3
    4d04:	03cc0633          	mul	a2,s8,t3
    4d08:	418787b3          	sub	a5,a5,s8
    4d0c:	40f807b3          	sub	a5,a6,a5
    4d10:	21e7cc33          	sh2add	s8,a5,t5
    4d14:	21d7a7b3          	sh1add	a5,a5,t4
    4d18:	000c2c03          	lw	s8,0(s8)
    4d1c:	0007d783          	lhu	a5,0(a5)
    4d20:	01f60633          	add	a2,a2,t6
    4d24:	001c8c93          	addi	s9,s9,1
    4d28:	01860633          	add	a2,a2,s8
    4d2c:	01952023          	sw	s9,0(a0)
    4d30:	00479c13          	slli	s8,a5,0x4

00004d34 <.L8>:
    4d34:	84072783          	lw	a5,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    4d38:	fe079ee3          	bnez	a5,4d34 <.L8>
    4d3c:	81172623          	sw	a7,-2036(a4)
    4d40:	80c72023          	sw	a2,-2048(a4)
    4d44:	80072223          	sw	zero,-2044(a4)
    4d48:	004c5793          	srli	a5,s8,0x4
    4d4c:	80f72423          	sw	a5,-2040(a4)
    4d50:	85272023          	sw	s2,-1984(a4)
    4d54:	00180813          	addi	a6,a6,1
    4d58:	006888b3          	add	a7,a7,t1
    4d5c:	f8d81ce3          	bne	a6,a3,4cf4 <.L9>
    4d60:	fff28793          	addi	a5,t0,-1
    4d64:	008797b3          	sll	a5,a5,s0
    4d68:	007303b3          	add	t2,t1,t2
    4d6c:	007783b3          	add	t2,a5,t2
    4d70:	1c098863          	beqz	s3,4f40 <.L50>
    4d74:	00068813          	mv	a6,a3

00004d78 <.L52>:
    4d78:	244b2283          	lw	t0,580(s6)
    4d7c:	405a82b3          	sub	t0,s5,t0
    4d80:	0b32d2b3          	minu	t0,t0,s3
    4d84:	405989b3          	sub	s3,s3,t0
    4d88:	f60292e3          	bnez	t0,4cec <.L51>

00004d8c <.L22>:
    4d8c:	00080693          	mv	a3,a6
    4d90:	00068813          	mv	a6,a3
    4d94:	fe5ff06f          	j	4d78 <.L52>

00004d98 <.L5>:
    4d98:	24472783          	lw	a5,580(a4)
    4d9c:	fe079ee3          	bnez	a5,4d98 <.L5>
    4da0:	0ff0000f          	fence
    4da4:	0184a683          	lw	a3,24(s1)
    4da8:	0104a703          	lw	a4,16(s1)
    4dac:	00c4a783          	lw	a5,12(s1)
    4db0:	00d70733          	add	a4,a4,a3
    4db4:	00e4a823          	sw	a4,16(s1)
    4db8:	00080693          	mv	a3,a6
    4dbc:	0004ac23          	sw	zero,24(s1)

00004dc0 <.L12>:
    4dc0:	14078a63          	beqz	a5,4f14 <.L13>
    4dc4:	03312023          	sw	s3,32(sp)
    4dc8:	01612a23          	sw	s6,20(sp)
    4dcc:	0003c7b7          	lui	a5,0x3c
    4dd0:	1b438e63          	beq	t2,s4,4f8c <.L53>
    4dd4:	0087d7b3          	srl	a5,a5,s0
    4dd8:	0b77d9b3          	minu	s3,a5,s7
    4ddc:	00068893          	mv	a7,a3
    4de0:	413b8bb3          	sub	s7,s7,s3
    4de4:	00899b33          	sll	s6,s3,s0
    4de8:	10098a63          	beqz	s3,4efc <.L15>

00004dec <.L57>:
    4dec:	01512c23          	sw	s5,24(sp)
    4df0:	ffb20ab7          	lui	s5,0xffb20
    4df4:	244aa803          	lw	a6,580(s5) # ffb20244 <__stack_top+0x1e244>
    4df8:	0ff00a13          	li	s4,255
    4dfc:	03212223          	sw	s2,36(sp)
    4e00:	ffb00f37          	lui	t5,0xffb00
    4e04:	ffb00eb7          	lui	t4,0xffb00
    4e08:	ffb00537          	lui	a0,0xffb00
    4e0c:	924922b7          	lui	t0,0x92492
    4e10:	410a0833          	sub	a6,s4,a6
    4e14:	01812623          	sw	s8,12(sp)
    4e18:	0b385833          	minu	a6,a6,s3
    4e1c:	01912423          	sw	s9,8(sp)
    4e20:	644f0f13          	addi	t5,t5,1604 # ffb00644 <bank_to_dram_offset>
    4e24:	448e8e93          	addi	t4,t4,1096 # ffb00448 <dram_bank_to_noc_xy>
    4e28:	03c50513          	addi	a0,a0,60 # ffb0003c <noc_reads_num_issued>
    4e2c:	49328293          	addi	t0,t0,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    4e30:	ffb21737          	lui	a4,0xffb21
    4e34:	00100913          	li	s2,1
    4e38:	410989b3          	sub	s3,s3,a6
    4e3c:	0a080263          	beqz	a6,4ee0 <.L25>

00004e40 <.L55>:
    4e40:	00d808b3          	add	a7,a6,a3
    4e44:	00038593          	mv	a1,t2

00004e48 <.L18>:
    4e48:	0256bc33          	mulhu	s8,a3,t0
    4e4c:	00052c83          	lw	s9,0(a0)
    4e50:	002c5c13          	srli	s8,s8,0x2
    4e54:	003c1793          	slli	a5,s8,0x3
    4e58:	03cc0633          	mul	a2,s8,t3
    4e5c:	418787b3          	sub	a5,a5,s8
    4e60:	40f687b3          	sub	a5,a3,a5
    4e64:	21e7cc33          	sh2add	s8,a5,t5
    4e68:	21d7a7b3          	sh1add	a5,a5,t4
    4e6c:	000c2c03          	lw	s8,0(s8)
    4e70:	0007d783          	lhu	a5,0(a5) # 3c000 <__kernel_data_lma+0x3074c>
    4e74:	01f60633          	add	a2,a2,t6
    4e78:	001c8c93          	addi	s9,s9,1
    4e7c:	01860633          	add	a2,a2,s8
    4e80:	01952023          	sw	s9,0(a0)
    4e84:	00479c13          	slli	s8,a5,0x4

00004e88 <.L17>:
    4e88:	84072783          	lw	a5,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    4e8c:	fe079ee3          	bnez	a5,4e88 <.L17>
    4e90:	80b72623          	sw	a1,-2036(a4)
    4e94:	80c72023          	sw	a2,-2048(a4)
    4e98:	80072223          	sw	zero,-2044(a4)
    4e9c:	004c5793          	srli	a5,s8,0x4
    4ea0:	80f72423          	sw	a5,-2040(a4)
    4ea4:	85272023          	sw	s2,-1984(a4)
    4ea8:	00168693          	addi	a3,a3,1
    4eac:	006585b3          	add	a1,a1,t1
    4eb0:	f9169ce3          	bne	a3,a7,4e48 <.L18>
    4eb4:	fff80793          	addi	a5,a6,-1
    4eb8:	008797b3          	sll	a5,a5,s0
    4ebc:	007303b3          	add	t2,t1,t2
    4ec0:	007783b3          	add	t2,a5,t2
    4ec4:	02098463          	beqz	s3,4eec <.L54>
    4ec8:	00088693          	mv	a3,a7

00004ecc <.L56>:
    4ecc:	244aa803          	lw	a6,580(s5)
    4ed0:	410a0833          	sub	a6,s4,a6
    4ed4:	0b385833          	minu	a6,a6,s3
    4ed8:	410989b3          	sub	s3,s3,a6
    4edc:	f60812e3          	bnez	a6,4e40 <.L55>

00004ee0 <.L25>:
    4ee0:	00068893          	mv	a7,a3
    4ee4:	00088693          	mv	a3,a7
    4ee8:	fe5ff06f          	j	4ecc <.L56>

00004eec <.L54>:
    4eec:	02412903          	lw	s2,36(sp)
    4ef0:	01812a83          	lw	s5,24(sp)
    4ef4:	00c12c03          	lw	s8,12(sp)
    4ef8:	00812c83          	lw	s9,8(sp)

00004efc <.L15>:
    4efc:	0164ac23          	sw	s6,24(s1)
    4f00:	02012983          	lw	s3,32(sp)
    4f04:	01412b03          	lw	s6,20(sp)
    4f08:	0114a023          	sw	a7,0(s1)
    4f0c:	0174a623          	sw	s7,12(s1)
    4f10:	0074aa23          	sw	t2,20(s1)

00004f14 <.L13>:
    4f14:	ffb21737          	lui	a4,0xffb21

00004f18 <.L20>:
    4f18:	84072783          	lw	a5,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    4f1c:	fe079ee3          	bnez	a5,4f18 <.L20>
    4f20:	80072c23          	sw	zero,-2024(a4)
    4f24:	0ff0000f          	fence
    4f28:	02c12403          	lw	s0,44(sp)
    4f2c:	02812483          	lw	s1,40(sp)
    4f30:	01c12a03          	lw	s4,28(sp)
    4f34:	01012b83          	lw	s7,16(sp)
    4f38:	03010113          	addi	sp,sp,48
    4f3c:	00008067          	ret

00004f40 <.L50>:
    4f40:	02412903          	lw	s2,36(sp)
    4f44:	01812a83          	lw	s5,24(sp)
    4f48:	01412b03          	lw	s6,20(sp)
    4f4c:	00c12c03          	lw	s8,12(sp)
    4f50:	00812c83          	lw	s9,8(sp)

00004f54 <.L6>:
    4f54:	ffb20737          	lui	a4,0xffb20

00004f58 <.L11>:
    4f58:	24472783          	lw	a5,580(a4) # ffb20244 <__stack_top+0x1e244>
    4f5c:	fe079ee3          	bnez	a5,4f58 <.L11>
    4f60:	0ff0000f          	fence
    4f64:	0104a783          	lw	a5,16(s1)
    4f68:	02012983          	lw	s3,32(sp)
    4f6c:	01a787b3          	add	a5,a5,s10
    4f70:	00f4a823          	sw	a5,16(s1)
    4f74:	00412d03          	lw	s10,4(sp)
    4f78:	00d4a023          	sw	a3,0(s1)
    4f7c:	0174a623          	sw	s7,12(s1)
    4f80:	0074aa23          	sw	t2,20(s1)
    4f84:	000b8793          	mv	a5,s7
    4f88:	e39ff06f          	j	4dc0 <.L12>

00004f8c <.L53>:
    4f8c:	000047b7          	lui	a5,0x4
    4f90:	0001a3b7          	lui	t2,0x1a
    4f94:	0087d7b3          	srl	a5,a5,s0
    4f98:	0b77d9b3          	minu	s3,a5,s7
    4f9c:	44038393          	addi	t2,t2,1088 # 1a440 <__kernel_data_lma+0xeb8c>
    4fa0:	00068893          	mv	a7,a3
    4fa4:	413b8bb3          	sub	s7,s7,s3
    4fa8:	00899b33          	sll	s6,s3,s0
    4fac:	e40990e3          	bnez	s3,4dec <.L57>
    4fb0:	f4dff06f          	j	4efc <.L15>

00004fb4 <_Z31process_paged_to_ringbuffer_cmdmRm.constprop.0.isra.0>:
    4fb4:	ffb007b7          	lui	a5,0xffb00
    4fb8:	fc010113          	addi	sp,sp,-64
    4fbc:	0347a603          	lw	a2,52(a5) # ffb00034 <noc_nonposted_writes_num_issued>
    4fc0:	02812e23          	sw	s0,60(sp)
    4fc4:	02912c23          	sw	s1,56(sp)
    4fc8:	03212a23          	sw	s2,52(sp)
    4fcc:	03312823          	sw	s3,48(sp)
    4fd0:	03512423          	sw	s5,40(sp)
    4fd4:	00050713          	mv	a4,a0
    4fd8:	ffb206b7          	lui	a3,0xffb20

00004fdc <.L59>:
    4fdc:	2286a783          	lw	a5,552(a3) # ffb20228 <__stack_top+0x1e228>
    4fe0:	fec79ee3          	bne	a5,a2,4fdc <.L59>
    4fe4:	0ff0000f          	fence
    4fe8:	00374383          	lbu	t2,3(a4)
    4fec:	00874783          	lbu	a5,8(a4)
    4ff0:	00974803          	lbu	a6,9(a4)
    4ff4:	00a74603          	lbu	a2,10(a4)
    4ff8:	00b74983          	lbu	s3,11(a4)
    4ffc:	00274303          	lbu	t1,2(a4)
    5000:	00c74f03          	lbu	t5,12(a4)
    5004:	00d74503          	lbu	a0,13(a4)
    5008:	00e74683          	lbu	a3,14(a4)
    500c:	00f74483          	lbu	s1,15(a4)
    5010:	00174883          	lbu	a7,1(a4)
    5014:	00881813          	slli	a6,a6,0x8
    5018:	00474e83          	lbu	t4,4(a4)
    501c:	00574583          	lbu	a1,5(a4)
    5020:	00f86833          	or	a6,a6,a5
    5024:	00674783          	lbu	a5,6(a4)
    5028:	00851513          	slli	a0,a0,0x8
    502c:	00774e03          	lbu	t3,7(a4)
    5030:	00859593          	slli	a1,a1,0x8
    5034:	01061613          	slli	a2,a2,0x10
    5038:	01069713          	slli	a4,a3,0x10
    503c:	01d5e5b3          	or	a1,a1,t4
    5040:	01e56533          	or	a0,a0,t5
    5044:	01079793          	slli	a5,a5,0x10
    5048:	010666b3          	or	a3,a2,a6
    504c:	00b7e7b3          	or	a5,a5,a1
    5050:	01899993          	slli	s3,s3,0x18
    5054:	00a76733          	or	a4,a4,a0
    5058:	01849493          	slli	s1,s1,0x18
    505c:	018e1593          	slli	a1,t3,0x18
    5060:	00100413          	li	s0,1
    5064:	0018f613          	andi	a2,a7,1
    5068:	00d9e9b3          	or	s3,s3,a3
    506c:	0ff3f393          	zext.b	t2,t2
    5070:	00e4e4b3          	or	s1,s1,a4
    5074:	00f5e6b3          	or	a3,a1,a5
    5078:	0ff37a93          	zext.b	s5,t1
    507c:	00641433          	sll	s0,s0,t1
    5080:	20061663          	bnez	a2,528c <.L60>
    5084:	ffb017b7          	lui	a5,0xffb01
    5088:	9107a283          	lw	t0,-1776(a5) # ffb00910 <_ZL13ringbuffer_wp>
    508c:	fffa6737          	lui	a4,0xfffa6
    5090:	bc070713          	addi	a4,a4,-1088 # fffa5bc0 <__instrn_buffer+0x165bc0>
    5094:	00e28733          	add	a4,t0,a4

00005098 <.L61>:
    5098:	ffb01637          	lui	a2,0xffb01
    509c:	92e62623          	sw	a4,-1748(a2) # ffb0092c <_ZL17ringbuffer_offset>
    50a0:	00600713          	li	a4,6
    50a4:	0aeafab3          	maxu	s5,s5,a4
    50a8:	1a84e663          	bltu	s1,s0,5254 <.L62>
    50ac:	ffffc637          	lui	a2,0xffffc
    50b0:	fff60713          	addi	a4,a2,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    50b4:	00e40733          	add	a4,s0,a4
    50b8:	00004537          	lui	a0,0x4
    50bc:	03412623          	sw	s4,44(sp)
    50c0:	00e75a13          	srli	s4,a4,0xe
    50c4:	03612223          	sw	s6,36(sp)
    50c8:	00c77733          	and	a4,a4,a2
    50cc:	03712023          	sw	s7,32(sp)
    50d0:	00ea1613          	slli	a2,s4,0xe
    50d4:	01812e23          	sw	s8,28(sp)
    50d8:	001a0a13          	addi	s4,s4,1
    50dc:	01912c23          	sw	s9,24(sp)
    50e0:	ffb00c37          	lui	s8,0xffb00
    50e4:	40a40cb3          	sub	s9,s0,a0
    50e8:	ffb00bb7          	lui	s7,0xffb00
    50ec:	ffb00837          	lui	a6,0xffb00
    50f0:	92492b37          	lui	s6,0x92492
    50f4:	10000e37          	lui	t3,0x10000
    50f8:	01000f37          	lui	t5,0x1000
    50fc:	01a12a23          	sw	s10,20(sp)
    5100:	00a70933          	add	s2,a4,a0
    5104:	012a5d13          	srli	s10,s4,0x12
    5108:	01b12823          	sw	s11,16(sp)
    510c:	40cc8cb3          	sub	s9,s9,a2
    5110:	00ea1a13          	slli	s4,s4,0xe
    5114:	644c0c13          	addi	s8,s8,1604 # ffb00644 <bank_to_dram_offset>
    5118:	448b8b93          	addi	s7,s7,1096 # ffb00448 <dram_bank_to_noc_xy>
    511c:	03c80813          	addi	a6,a6,60 # ffb0003c <noc_reads_num_issued>
    5120:	493b0b13          	addi	s6,s6,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    5124:	00fe0e13          	addi	t3,t3,15 # 1000000f <__kernel_data_lma+0xfff475b>
    5128:	ffff0f13          	addi	t5,t5,-1 # ffffff <__kernel_data_lma+0xff474b>
    512c:	ffb21737          	lui	a4,0xffb21
    5130:	00100e93          	li	t4,1
    5134:	00d12623          	sw	a3,12(sp)

00005138 <.L67>:
    5138:	0363b6b3          	mulhu	a3,t2,s6
    513c:	0026d693          	srli	a3,a3,0x2
    5140:	00369613          	slli	a2,a3,0x3
    5144:	40d60633          	sub	a2,a2,a3
    5148:	40c38633          	sub	a2,t2,a2
    514c:	01569333          	sll	t1,a3,s5
    5150:	218646b3          	sh2add	a3,a2,s8
    5154:	21762633          	sh1add	a2,a2,s7
    5158:	0006a683          	lw	a3,0(a3)
    515c:	00065d83          	lhu	s11,0(a2)
    5160:	01330333          	add	t1,t1,s3
    5164:	00d30333          	add	t1,t1,a3
    5168:	004d9d93          	slli	s11,s11,0x4
    516c:	00030593          	mv	a1,t1
    5170:	000d8613          	mv	a2,s11
    5174:	10857663          	bgeu	a0,s0,5280 <.L73>
    5178:	00590fb3          	add	t6,s2,t0
    517c:	00030613          	mv	a2,t1
    5180:	000d8893          	mv	a7,s11
    5184:	00028593          	mv	a1,t0

00005188 <.L64>:
    5188:	84072683          	lw	a3,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    518c:	fe069ee3          	bnez	a3,5188 <.L64>
    5190:	80b72623          	sw	a1,-2036(a4)
    5194:	80c72023          	sw	a2,-2048(a4)
    5198:	01c8f6b3          	and	a3,a7,t3
    519c:	80d72223          	sw	a3,-2044(a4)
    51a0:	0048d693          	srli	a3,a7,0x4
    51a4:	01e6f6b3          	and	a3,a3,t5
    51a8:	80d72423          	sw	a3,-2040(a4)
    51ac:	82a72023          	sw	a0,-2016(a4)
    51b0:	85d72023          	sw	t4,-1984(a4)
    51b4:	00082683          	lw	a3,0(a6)
    51b8:	00a585b3          	add	a1,a1,a0
    51bc:	00168693          	addi	a3,a3,1
    51c0:	00d82023          	sw	a3,0(a6)
    51c4:	00a606b3          	add	a3,a2,a0
    51c8:	00c6b633          	sltu	a2,a3,a2
    51cc:	011608b3          	add	a7,a2,a7
    51d0:	00068613          	mv	a2,a3
    51d4:	fbf59ae3          	bne	a1,t6,5188 <.L64>
    51d8:	014306b3          	add	a3,t1,s4
    51dc:	01ad8db3          	add	s11,s11,s10
    51e0:	0066b333          	sltu	t1,a3,t1
    51e4:	01b30633          	add	a2,t1,s11
    51e8:	00068593          	mv	a1,a3
    51ec:	000c8893          	mv	a7,s9

000051f0 <.L66>:
    51f0:	84072683          	lw	a3,-1984(a4)
    51f4:	fe069ee3          	bnez	a3,51f0 <.L66>
    51f8:	81f72623          	sw	t6,-2036(a4)
    51fc:	80b72023          	sw	a1,-2048(a4)
    5200:	01c676b3          	and	a3,a2,t3
    5204:	80d72223          	sw	a3,-2044(a4)
    5208:	00465613          	srli	a2,a2,0x4
    520c:	80c72423          	sw	a2,-2040(a4)
    5210:	83172023          	sw	a7,-2016(a4)
    5214:	85d72023          	sw	t4,-1984(a4)
    5218:	00082683          	lw	a3,0(a6)
    521c:	408484b3          	sub	s1,s1,s0
    5220:	00168693          	addi	a3,a3,1
    5224:	00d82023          	sw	a3,0(a6)
    5228:	008282b3          	add	t0,t0,s0
    522c:	00138393          	addi	t2,t2,1
    5230:	f084f4e3          	bgeu	s1,s0,5138 <.L67>
    5234:	00c12683          	lw	a3,12(sp)
    5238:	02c12a03          	lw	s4,44(sp)
    523c:	02412b03          	lw	s6,36(sp)
    5240:	02012b83          	lw	s7,32(sp)
    5244:	01c12c03          	lw	s8,28(sp)
    5248:	01812c83          	lw	s9,24(sp)
    524c:	01412d03          	lw	s10,20(sp)
    5250:	01012d83          	lw	s11,16(sp)

00005254 <.L62>:
    5254:	04049863          	bnez	s1,52a4 <.L87>

00005258 <.L68>:
    5258:	9107a703          	lw	a4,-1776(a5)
    525c:	03c12403          	lw	s0,60(sp)
    5260:	00d70733          	add	a4,a4,a3
    5264:	90e7a823          	sw	a4,-1776(a5)
    5268:	03812483          	lw	s1,56(sp)
    526c:	03412903          	lw	s2,52(sp)
    5270:	03012983          	lw	s3,48(sp)
    5274:	02812a83          	lw	s5,40(sp)
    5278:	04010113          	addi	sp,sp,64
    527c:	00008067          	ret

00005280 <.L73>:
    5280:	00040893          	mv	a7,s0
    5284:	00028f93          	mv	t6,t0
    5288:	f69ff06f          	j	51f0 <.L66>

0000528c <.L60>:
    528c:	0005a2b7          	lui	t0,0x5a
    5290:	44028293          	addi	t0,t0,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    5294:	ffb017b7          	lui	a5,0xffb01
    5298:	9057a823          	sw	t0,-1776(a5) # ffb00910 <_ZL13ringbuffer_wp>
    529c:	00000713          	li	a4,0
    52a0:	df9ff06f          	j	5098 <.L61>

000052a4 <.L87>:
    52a4:	92492737          	lui	a4,0x92492
    52a8:	49370713          	addi	a4,a4,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    52ac:	02e3b733          	mulhu	a4,t2,a4
    52b0:	ffb00637          	lui	a2,0xffb00
    52b4:	00275713          	srli	a4,a4,0x2
    52b8:	00371513          	slli	a0,a4,0x3
    52bc:	40e50533          	sub	a0,a0,a4
    52c0:	ffb005b7          	lui	a1,0xffb00
    52c4:	40a383b3          	sub	t2,t2,a0
    52c8:	44858593          	addi	a1,a1,1096 # ffb00448 <dram_bank_to_noc_xy>
    52cc:	64460613          	addi	a2,a2,1604 # ffb00644 <bank_to_dram_offset>
    52d0:	01571533          	sll	a0,a4,s5
    52d4:	20c3c633          	sh2add	a2,t2,a2
    52d8:	20b3a3b3          	sh1add	t2,t2,a1
    52dc:	00062703          	lw	a4,0(a2)
    52e0:	0003df03          	lhu	t5,0(t2)
    52e4:	01350533          	add	a0,a0,s3
    52e8:	00e50533          	add	a0,a0,a4
    52ec:	004f1f13          	slli	t5,t5,0x4
    52f0:	000048b7          	lui	a7,0x4
    52f4:	00050593          	mv	a1,a0
    52f8:	000f0313          	mv	t1,t5
    52fc:	1098f063          	bgeu	a7,s1,53fc <.L74>
    5300:	ffffc637          	lui	a2,0xffffc
    5304:	fff60713          	addi	a4,a2,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    5308:	00e48e33          	add	t3,s1,a4
    530c:	00ce7633          	and	a2,t3,a2
    5310:	01128eb3          	add	t4,t0,a7
    5314:	ffb00837          	lui	a6,0xffb00
    5318:	10000437          	lui	s0,0x10000
    531c:	010003b7          	lui	t2,0x1000
    5320:	00ce8eb3          	add	t4,t4,a2
    5324:	03c80813          	addi	a6,a6,60 # ffb0003c <noc_reads_num_issued>
    5328:	00f40413          	addi	s0,s0,15 # 1000000f <__kernel_data_lma+0xfff475b>
    532c:	fff38393          	addi	t2,t2,-1 # ffffff <__kernel_data_lma+0xff474b>
    5330:	ffb21637          	lui	a2,0xffb21
    5334:	00100913          	li	s2,1

00005338 <.L70>:
    5338:	84062703          	lw	a4,-1984(a2) # ffb20840 <__stack_top+0x1e840>
    533c:	fe071ee3          	bnez	a4,5338 <.L70>
    5340:	80562623          	sw	t0,-2036(a2)
    5344:	80b62023          	sw	a1,-2048(a2)
    5348:	00837fb3          	and	t6,t1,s0
    534c:	00435713          	srli	a4,t1,0x4
    5350:	81f62223          	sw	t6,-2044(a2)
    5354:	00777733          	and	a4,a4,t2
    5358:	80e62423          	sw	a4,-2040(a2)
    535c:	83162023          	sw	a7,-2016(a2)
    5360:	85262023          	sw	s2,-1984(a2)
    5364:	00082703          	lw	a4,0(a6)
    5368:	01158fb3          	add	t6,a1,a7
    536c:	00170713          	addi	a4,a4,1
    5370:	00bfb5b3          	sltu	a1,t6,a1
    5374:	011282b3          	add	t0,t0,a7
    5378:	00e82023          	sw	a4,0(a6)
    537c:	00658333          	add	t1,a1,t1
    5380:	000f8593          	mv	a1,t6
    5384:	fbd29ae3          	bne	t0,t4,5338 <.L70>
    5388:	00ee5713          	srli	a4,t3,0xe
    538c:	00170613          	addi	a2,a4,1
    5390:	00e61593          	slli	a1,a2,0xe
    5394:	00b505b3          	add	a1,a0,a1
    5398:	01265613          	srli	a2,a2,0x12
    539c:	411488b3          	sub	a7,s1,a7
    53a0:	00e71713          	slli	a4,a4,0xe
    53a4:	00a5b533          	sltu	a0,a1,a0
    53a8:	00cf0f33          	add	t5,t5,a2
    53ac:	40e884b3          	sub	s1,a7,a4
    53b0:	01e50333          	add	t1,a0,t5

000053b4 <.L69>:
    53b4:	ffb21737          	lui	a4,0xffb21

000053b8 <.L72>:
    53b8:	84072603          	lw	a2,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    53bc:	fe061ee3          	bnez	a2,53b8 <.L72>
    53c0:	10000637          	lui	a2,0x10000
    53c4:	81d72623          	sw	t4,-2036(a4)
    53c8:	00f60613          	addi	a2,a2,15 # 1000000f <__kernel_data_lma+0xfff475b>
    53cc:	80b72023          	sw	a1,-2048(a4)
    53d0:	00c37633          	and	a2,t1,a2
    53d4:	80c72223          	sw	a2,-2044(a4)
    53d8:	00435313          	srli	t1,t1,0x4
    53dc:	80672423          	sw	t1,-2040(a4)
    53e0:	82972023          	sw	s1,-2016(a4)
    53e4:	00100613          	li	a2,1
    53e8:	84c72023          	sw	a2,-1984(a4)
    53ec:	00082703          	lw	a4,0(a6)
    53f0:	00c70733          	add	a4,a4,a2
    53f4:	00e82023          	sw	a4,0(a6)
    53f8:	e61ff06f          	j	5258 <.L68>

000053fc <.L74>:
    53fc:	ffb00837          	lui	a6,0xffb00
    5400:	00028e93          	mv	t4,t0
    5404:	03c80813          	addi	a6,a6,60 # ffb0003c <noc_reads_num_issued>
    5408:	fadff06f          	j	53b4 <.L69>

0000540c <_Z22noc_read_64bit_any_lenILb1EEvmymm>:
    540c:	ffb217b7          	lui	a5,0xffb21

00005410 <.L89>:
    5410:	8407a883          	lw	a7,-1984(a5) # ffb20840 <__stack_top+0x1e840>
    5414:	84078813          	addi	a6,a5,-1984
    5418:	fe089ce3          	bnez	a7,5410 <.L89>
    541c:	8207a023          	sw	zero,-2016(a5)
    5420:	ffb00337          	lui	t1,0xffb00
    5424:	80a7a423          	sw	a0,-2040(a5)
    5428:	00004e37          	lui	t3,0x4
    542c:	03c30313          	addi	t1,t1,60 # ffb0003c <noc_reads_num_issued>
    5430:	0aee7463          	bgeu	t3,a4,54d8 <.L90>
    5434:	83c7a023          	sw	t3,-2016(a5)
    5438:	00058513          	mv	a0,a1
    543c:	00060f13          	mv	t5,a2
    5440:	40b683b3          	sub	t2,a3,a1
    5444:	00b702b3          	add	t0,a4,a1
    5448:	ffb21eb7          	lui	t4,0xffb21
    544c:	00100f93          	li	t6,1

00005450 <.L92>:
    5450:	00032783          	lw	a5,0(t1)
    5454:	00a388b3          	add	a7,t2,a0
    5458:	00178793          	addi	a5,a5,1
    545c:	00f32023          	sw	a5,0(t1)
    5460:	811ea623          	sw	a7,-2036(t4) # ffb2080c <__stack_top+0x1e80c>
    5464:	80aea023          	sw	a0,-2048(t4)
    5468:	01c508b3          	add	a7,a0,t3
    546c:	81eea223          	sw	t5,-2044(t4)
    5470:	00a8b533          	sltu	a0,a7,a0
    5474:	01e50f33          	add	t5,a0,t5
    5478:	01f82023          	sw	t6,0(a6)
    547c:	00088513          	mv	a0,a7

00005480 <.L91>:
    5480:	00082783          	lw	a5,0(a6)
    5484:	fe079ee3          	bnez	a5,5480 <.L91>
    5488:	411288b3          	sub	a7,t0,a7
    548c:	fd1e62e3          	bltu	t3,a7,5450 <.L92>
    5490:	ffffceb7          	lui	t4,0xffffc
    5494:	fffe8793          	addi	a5,t4,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    5498:	00f707b3          	add	a5,a4,a5
    549c:	00e7d813          	srli	a6,a5,0xe
    54a0:	01c58533          	add	a0,a1,t3
    54a4:	00e81893          	slli	a7,a6,0xe
    54a8:	00b535b3          	sltu	a1,a0,a1
    54ac:	00a88533          	add	a0,a7,a0
    54b0:	01c686b3          	add	a3,a3,t3
    54b4:	01d7f7b3          	and	a5,a5,t4
    54b8:	41c70e33          	sub	t3,a4,t3
    54bc:	011538b3          	sltu	a7,a0,a7
    54c0:	00c58733          	add	a4,a1,a2
    54c4:	00e81813          	slli	a6,a6,0xe
    54c8:	00e88633          	add	a2,a7,a4
    54cc:	00d786b3          	add	a3,a5,a3
    54d0:	00050593          	mv	a1,a0
    54d4:	410e0733          	sub	a4,t3,a6

000054d8 <.L90>:
    54d8:	00032503          	lw	a0,0(t1)
    54dc:	ffb217b7          	lui	a5,0xffb21
    54e0:	00150513          	addi	a0,a0,1 # 4001 <_start-0x9cf>
    54e4:	00a32023          	sw	a0,0(t1)
    54e8:	80d7a623          	sw	a3,-2036(a5) # ffb2080c <__stack_top+0x1e80c>
    54ec:	82e7a023          	sw	a4,-2016(a5)
    54f0:	80b7a023          	sw	a1,-2048(a5)
    54f4:	80c7a223          	sw	a2,-2044(a5)
    54f8:	00100713          	li	a4,1
    54fc:	84e7a023          	sw	a4,-1984(a5)
    5500:	00008067          	ret

00005504 <_Z22noc_read_64bit_any_lenILb0EEvmymm.isra.0>:
    5504:	ffb217b7          	lui	a5,0xffb21

00005508 <.L98>:
    5508:	8407a803          	lw	a6,-1984(a5) # ffb20840 <__stack_top+0x1e840>
    550c:	84078713          	addi	a4,a5,-1984
    5510:	fe081ce3          	bnez	a6,5508 <.L98>
    5514:	ffb00337          	lui	t1,0xffb00
    5518:	00004e37          	lui	t3,0x4
    551c:	03c30313          	addi	t1,t1,60 # ffb0003c <noc_reads_num_issued>
    5520:	0ade7463          	bgeu	t3,a3,55c8 <.L99>
    5524:	83c7a023          	sw	t3,-2016(a5)
    5528:	00050813          	mv	a6,a0
    552c:	00058f13          	mv	t5,a1
    5530:	40a603b3          	sub	t2,a2,a0
    5534:	00a682b3          	add	t0,a3,a0
    5538:	ffb21eb7          	lui	t4,0xffb21
    553c:	00100f93          	li	t6,1

00005540 <.L101>:
    5540:	00032783          	lw	a5,0(t1)
    5544:	010388b3          	add	a7,t2,a6
    5548:	00178793          	addi	a5,a5,1
    554c:	00f32023          	sw	a5,0(t1)
    5550:	811ea623          	sw	a7,-2036(t4) # ffb2080c <__stack_top+0x1e80c>
    5554:	810ea023          	sw	a6,-2048(t4)
    5558:	01c808b3          	add	a7,a6,t3
    555c:	81eea223          	sw	t5,-2044(t4)
    5560:	0108b833          	sltu	a6,a7,a6
    5564:	01e80f33          	add	t5,a6,t5
    5568:	01f72023          	sw	t6,0(a4)
    556c:	00088813          	mv	a6,a7

00005570 <.L100>:
    5570:	00072783          	lw	a5,0(a4)
    5574:	fe079ee3          	bnez	a5,5570 <.L100>
    5578:	411288b3          	sub	a7,t0,a7
    557c:	fd1e62e3          	bltu	t3,a7,5540 <.L101>
    5580:	ffffceb7          	lui	t4,0xffffc
    5584:	fffe8793          	addi	a5,t4,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    5588:	00f687b3          	add	a5,a3,a5
    558c:	00e7d813          	srli	a6,a5,0xe
    5590:	01c50733          	add	a4,a0,t3
    5594:	00e81893          	slli	a7,a6,0xe
    5598:	00a73533          	sltu	a0,a4,a0
    559c:	00e88733          	add	a4,a7,a4
    55a0:	01c60633          	add	a2,a2,t3
    55a4:	01d7f7b3          	and	a5,a5,t4
    55a8:	41c68e33          	sub	t3,a3,t3
    55ac:	011738b3          	sltu	a7,a4,a7
    55b0:	00b506b3          	add	a3,a0,a1
    55b4:	00e81813          	slli	a6,a6,0xe
    55b8:	00d885b3          	add	a1,a7,a3
    55bc:	00c78633          	add	a2,a5,a2
    55c0:	00070513          	mv	a0,a4
    55c4:	410e06b3          	sub	a3,t3,a6

000055c8 <.L99>:
    55c8:	00032703          	lw	a4,0(t1)
    55cc:	ffb217b7          	lui	a5,0xffb21
    55d0:	00170713          	addi	a4,a4,1
    55d4:	00e32023          	sw	a4,0(t1)
    55d8:	80c7a623          	sw	a2,-2036(a5) # ffb2080c <__stack_top+0x1e80c>
    55dc:	82d7a023          	sw	a3,-2016(a5)
    55e0:	80a7a023          	sw	a0,-2048(a5)
    55e4:	80b7a223          	sw	a1,-2044(a5)
    55e8:	00100713          	li	a4,1
    55ec:	84e7a023          	sw	a4,-1984(a5)
    55f0:	00008067          	ret

000055f4 <_Z27process_relay_inline_commonILb0ELb1ELb1E24DispatchRelayInlineStateEmRmS1_R20PrefetchExecBufState.constprop.0>:
    55f4:	ffb017b7          	lui	a5,0xffb01
    55f8:	fb010113          	addi	sp,sp,-80
    55fc:	86c78793          	addi	a5,a5,-1940 # ffb0086c <sem_l1_base>
    5600:	00f12223          	sw	a5,4(sp)
    5604:	0007a603          	lw	a2,0(a5)
    5608:	00052783          	lw	a5,0(a0)
    560c:	03612823          	sw	s6,48(sp)
    5610:	04112623          	sw	ra,76(sp)
    5614:	04912223          	sw	s1,68(sp)
    5618:	03312e23          	sw	s3,60(sp)
    561c:	03412c23          	sw	s4,56(sp)
    5620:	03712623          	sw	s7,44(sp)
    5624:	0047c703          	lbu	a4,4(a5)
    5628:	0057c883          	lbu	a7,5(a5)
    562c:	0067c803          	lbu	a6,6(a5)
    5630:	00889893          	slli	a7,a7,0x8
    5634:	0077c983          	lbu	s3,7(a5)
    5638:	0087c303          	lbu	t1,8(a5)
    563c:	0097c683          	lbu	a3,9(a5)
    5640:	00e8e8b3          	or	a7,a7,a4
    5644:	01081813          	slli	a6,a6,0x10
    5648:	00a7c703          	lbu	a4,10(a5)
    564c:	01186833          	or	a6,a6,a7
    5650:	00b7cb83          	lbu	s7,11(a5)
    5654:	00001b37          	lui	s6,0x1
    5658:	01899993          	slli	s3,s3,0x18
    565c:	00869693          	slli	a3,a3,0x8
    5660:	0066e6b3          	or	a3,a3,t1
    5664:	01071793          	slli	a5,a4,0x10
    5668:	ffb008b7          	lui	a7,0xffb00
    566c:	0109e9b3          	or	s3,s3,a6
    5670:	fffb0b13          	addi	s6,s6,-1 # fff <_start-0x39d1>
    5674:	02488713          	addi	a4,a7,36 # ffb00024 <noc_nonposted_atomics_acked>
    5678:	00d7e7b3          	or	a5,a5,a3
    567c:	01698b33          	add	s6,s3,s6
    5680:	018b9b93          	slli	s7,s7,0x18
    5684:	00072683          	lw	a3,0(a4)
    5688:	00e12023          	sw	a4,0(sp)
    568c:	00fbebb3          	or	s7,s7,a5
    5690:	00cb5b13          	srli	s6,s6,0xc
    5694:	ffb20737          	lui	a4,0xffb20

00005698 <.L107>:
    5698:	20072783          	lw	a5,512(a4) # ffb20200 <__stack_top+0x1e200>
    569c:	fed79ee3          	bne	a5,a3,5698 <.L107>
    56a0:	0ff0000f          	fence
    56a4:	ffb016b7          	lui	a3,0xffb01

000056a8 <.L108>:
    56a8:	0ff0000f          	fence
    56ac:	9246a703          	lw	a4,-1756(a3) # ffb00924 <_ZN24DispatchRelayInlineState9cb_writerE>
    56b0:	00062783          	lw	a5,0(a2)
    56b4:	00f707b3          	add	a5,a4,a5
    56b8:	40fb07b3          	sub	a5,s6,a5
    56bc:	fef046e3          	bgtz	a5,56a8 <.L108>
    56c0:	41670733          	sub	a4,a4,s6
    56c4:	92e6a223          	sw	a4,-1756(a3)
    56c8:	42098e63          	beqz	s3,5b04 <.L109>
    56cc:	03512a23          	sw	s5,52(sp)
    56d0:	00050a93          	mv	s5,a0
    56d4:	0105a503          	lw	a0,16(a1)
    56d8:	000aae03          	lw	t3,0(s5)
    56dc:	01053813          	sltiu	a6,a0,16
    56e0:	05212023          	sw	s2,64(sp)
    56e4:	fff80813          	addi	a6,a6,-1
    56e8:	ff050793          	addi	a5,a0,-16
    56ec:	ffb004b7          	lui	s1,0xffb00
    56f0:	ffb00937          	lui	s2,0xffb00
    56f4:	04812423          	sw	s0,72(sp)
    56f8:	03812423          	sw	s8,40(sp)
    56fc:	03912223          	sw	s9,36(sp)
    5700:	03a12023          	sw	s10,32(sp)
    5704:	01b12e23          	sw	s11,28(sp)
    5708:	00058c93          	mv	s9,a1
    570c:	00f87833          	and	a6,a6,a5
    5710:	ffff8d37          	lui	s10,0xffff8
    5714:	010e0e13          	addi	t3,t3,16 # 4010 <_start-0x9c0>
    5718:	03448493          	addi	s1,s1,52 # ffb00034 <noc_nonposted_writes_num_issued>
    571c:	02c90913          	addi	s2,s2,44 # ffb0002c <noc_nonposted_writes_acked>
    5720:	ffb01a37          	lui	s4,0xffb01
    5724:	ffb20437          	lui	s0,0xffb20
    5728:	0009ac37          	lui	s8,0x9a
    572c:	0001adb7          	lui	s11,0x1a

00005730 <.L128>:
    5730:	000e0613          	mv	a2,t3
    5734:	22080e63          	beqz	a6,5970 <.L153>

00005738 <.L110>:
    5738:	0b3858b3          	minu	a7,a6,s3
    573c:	41180833          	sub	a6,a6,a7
    5740:	00c88e33          	add	t3,a7,a2
    5744:	00081c63          	bnez	a6,575c <.L112>
    5748:	000ca823          	sw	zero,16(s9)
    574c:	000aa783          	lw	a5,0(s5)
    5750:	40ab8bb3          	sub	s7,s7,a0
    5754:	00a787b3          	add	a5,a5,a0
    5758:	00faa023          	sw	a5,0(s5)

0000575c <.L112>:
    575c:	918a2683          	lw	a3,-1768(s4) # ffb00918 <_ZL19downstream_data_ptr>
    5760:	00088593          	mv	a1,a7
    5764:	40dc0eb3          	sub	t4,s8,a3
    5768:	00068313          	mv	t1,a3
    576c:	011efa63          	bgeu	t4,a7,5780 <.L114>
    5770:	23869663          	bne	a3,s8,599c <.L154>

00005774 <.L115>:
    5774:	0001a337          	lui	t1,0x1a
    5778:	91ba2c23          	sw	s11,-1768(s4)
    577c:	00030693          	mv	a3,t1

00005780 <.L114>:
    5780:	000047b7          	lui	a5,0x4
    5784:	00058f13          	mv	t5,a1
    5788:	0cb7f863          	bgeu	a5,a1,5858 <.L127>

0000578c <.L123>:
    578c:	04042783          	lw	a5,64(s0) # ffb20040 <__stack_top+0x1e040>
    5790:	fe079ee3          	bnez	a5,578c <.L123>
    5794:	00c42023          	sw	a2,0(s0)
    5798:	00004eb7          	lui	t4,0x4
    579c:	03d42023          	sw	t4,32(s0)
    57a0:	00642623          	sw	t1,12(s0)
    57a4:	0004a703          	lw	a4,0(s1)
    57a8:	00092783          	lw	a5,0(s2)
    57ac:	00170713          	addi	a4,a4,1
    57b0:	00178793          	addi	a5,a5,1 # 4001 <_start-0x9cf>
    57b4:	00e4a023          	sw	a4,0(s1)
    57b8:	00f92023          	sw	a5,0(s2)
    57bc:	00100f93          	li	t6,1
    57c0:	41d58f33          	sub	t5,a1,t4
    57c4:	05f42023          	sw	t6,64(s0)
    57c8:	01d60733          	add	a4,a2,t4
    57cc:	01d682b3          	add	t0,a3,t4
    57d0:	ffffc7b7          	lui	a5,0xffffc
    57d4:	31eefe63          	bgeu	t4,t5,5af0 <.L155>
    57d8:	ffff8337          	lui	t1,0xffff8
    57dc:	fff30313          	addi	t1,t1,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    57e0:	00658333          	add	t1,a1,t1
    57e4:	00f373b3          	and	t2,t1,a5
    57e8:	40c787b3          	sub	a5,a5,a2
    57ec:	00578f33          	add	t5,a5,t0
    57f0:	000087b7          	lui	a5,0x8
    57f4:	00f607b3          	add	a5,a2,a5
    57f8:	00f38633          	add	a2,t2,a5

000057fc <.L125>:
    57fc:	04042783          	lw	a5,64(s0)
    5800:	fe079ee3          	bnez	a5,57fc <.L125>
    5804:	00e42023          	sw	a4,0(s0)
    5808:	00ef07b3          	add	a5,t5,a4
    580c:	00f42623          	sw	a5,12(s0)
    5810:	0004a783          	lw	a5,0(s1)
    5814:	01d70733          	add	a4,a4,t4
    5818:	00178793          	addi	a5,a5,1 # 8001 <.L417+0x25>
    581c:	00f4a023          	sw	a5,0(s1)
    5820:	00092783          	lw	a5,0(s2)
    5824:	00178793          	addi	a5,a5,1
    5828:	00f92023          	sw	a5,0(s2)
    582c:	05f42023          	sw	t6,64(s0)
    5830:	fcc716e3          	bne	a4,a2,57fc <.L125>
    5834:	00e35313          	srli	t1,t1,0xe
    5838:	00e31793          	slli	a5,t1,0xe
    583c:	01a58f33          	add	t5,a1,s10
    5840:	00078313          	mv	t1,a5
    5844:	40ff0f33          	sub	t5,t5,a5
    5848:	000087b7          	lui	a5,0x8
    584c:	00f686b3          	add	a3,a3,a5
    5850:	00070613          	mv	a2,a4
    5854:	00d30333          	add	t1,t1,a3

00005858 <.L127>:
    5858:	04042783          	lw	a5,64(s0)
    585c:	fe079ee3          	bnez	a5,5858 <.L127>

00005860 <.L157>:
    5860:	00c42023          	sw	a2,0(s0)
    5864:	03e42023          	sw	t5,32(s0)
    5868:	00642623          	sw	t1,12(s0)
    586c:	0004a703          	lw	a4,0(s1)
    5870:	00092783          	lw	a5,0(s2)
    5874:	00170713          	addi	a4,a4,1
    5878:	00178793          	addi	a5,a5,1 # 8001 <.L417+0x25>
    587c:	00e4a023          	sw	a4,0(s1)
    5880:	00f92023          	sw	a5,0(s2)
    5884:	00100793          	li	a5,1
    5888:	04f42023          	sw	a5,64(s0)
    588c:	918a2783          	lw	a5,-1768(s4)
    5890:	411989b3          	sub	s3,s3,a7
    5894:	00f58733          	add	a4,a1,a5
    5898:	90ea2c23          	sw	a4,-1768(s4)
    589c:	e8099ae3          	bnez	s3,5730 <.L128>
    58a0:	04812403          	lw	s0,72(sp)
    58a4:	04012903          	lw	s2,64(sp)
    58a8:	03412a83          	lw	s5,52(sp)
    58ac:	02812c03          	lw	s8,40(sp)
    58b0:	02412c83          	lw	s9,36(sp)
    58b4:	02012d03          	lw	s10,32(sp)
    58b8:	01c12d83          	lw	s11,28(sp)

000058bc <.L129>:
    58bc:	000017b7          	lui	a5,0x1
    58c0:	fff78793          	addi	a5,a5,-1 # fff <_start-0x39d1>
    58c4:	00f70733          	add	a4,a4,a5
    58c8:	fffff7b7          	lui	a5,0xfffff
    58cc:	00f777b3          	and	a5,a4,a5
    58d0:	0004a683          	lw	a3,0(s1)
    58d4:	90fa2c23          	sw	a5,-1768(s4)
    58d8:	ffb20737          	lui	a4,0xffb20

000058dc <.L130>:
    58dc:	22872783          	lw	a5,552(a4) # ffb20228 <__stack_top+0x1e228>
    58e0:	fed79ee3          	bne	a5,a3,58dc <.L130>
    58e4:	0ff0000f          	fence
    58e8:	00412783          	lw	a5,4(sp)
    58ec:	ffb22737          	lui	a4,0xffb22
    58f0:	0007a683          	lw	a3,0(a5) # fffff000 <__instrn_buffer+0x1bf000>

000058f4 <.L131>:
    58f4:	84072783          	lw	a5,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    58f8:	fe079ee3          	bnez	a5,58f4 <.L131>
    58fc:	80d72023          	sw	a3,-2048(a4)
    5900:	80072223          	sw	zero,-2044(a4)
    5904:	0026d793          	srli	a5,a3,0x2
    5908:	00001637          	lui	a2,0x1
    590c:	0ce00593          	li	a1,206
    5910:	000026b7          	lui	a3,0x2
    5914:	80b72423          	sw	a1,-2040(a4)
    5918:	0037f793          	andi	a5,a5,3
    591c:	07c60613          	addi	a2,a2,124 # 107c <_start-0x3954>
    5920:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    5924:	80d72e23          	sw	a3,-2020(a4)
    5928:	00c7e7b3          	or	a5,a5,a2
    592c:	82f72023          	sw	a5,-2016(a4)
    5930:	83672423          	sw	s6,-2008(a4)
    5934:	00100793          	li	a5,1
    5938:	84f72023          	sw	a5,-1984(a4)
    593c:	00012703          	lw	a4,0(sp)
    5940:	04c12083          	lw	ra,76(sp)
    5944:	00072783          	lw	a5,0(a4)
    5948:	04412483          	lw	s1,68(sp)
    594c:	00178793          	addi	a5,a5,1
    5950:	00f72023          	sw	a5,0(a4)
    5954:	03c12983          	lw	s3,60(sp)
    5958:	03812a03          	lw	s4,56(sp)
    595c:	03012b03          	lw	s6,48(sp)
    5960:	000b8513          	mv	a0,s7
    5964:	02c12b83          	lw	s7,44(sp)
    5968:	05010113          	addi	sp,sp,80
    596c:	00008067          	ret

00005970 <.L153>:
    5970:	0004a703          	lw	a4,0(s1)

00005974 <.L111>:
    5974:	22842783          	lw	a5,552(s0)
    5978:	fee79ee3          	bne	a5,a4,5974 <.L111>
    597c:	0ff0000f          	fence
    5980:	000a8513          	mv	a0,s5
    5984:	000c8593          	mv	a1,s9
    5988:	a54ff0ef          	jal	4bdc <_Z24paged_read_into_cmddat_qRmR20PrefetchExecBufState>
    598c:	010ca803          	lw	a6,16(s9)
    5990:	000aa603          	lw	a2,0(s5)
    5994:	00080513          	mv	a0,a6
    5998:	da1ff06f          	j	5738 <.L110>

0000599c <.L154>:
    599c:	fff6a7b7          	lui	a5,0xfff6a
    59a0:	00f687b3          	add	a5,a3,a5
    59a4:	00004337          	lui	t1,0x4
    59a8:	00068713          	mv	a4,a3
    59ac:	000e8593          	mv	a1,t4
    59b0:	00060393          	mv	t2,a2
    59b4:	0ef37a63          	bgeu	t1,a5,5aa8 <.L121>
    59b8:	ffb20737          	lui	a4,0xffb20

000059bc <.L117>:
    59bc:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    59c0:	fe079ee3          	bnez	a5,59bc <.L117>
    59c4:	00c72023          	sw	a2,0(a4)
    59c8:	000045b7          	lui	a1,0x4
    59cc:	02b72023          	sw	a1,32(a4)
    59d0:	00d72623          	sw	a3,12(a4)
    59d4:	0004a303          	lw	t1,0(s1)
    59d8:	00092783          	lw	a5,0(s2)
    59dc:	00130313          	addi	t1,t1,1 # 4001 <_start-0x9cf>
    59e0:	00178793          	addi	a5,a5,1 # fff6a001 <__instrn_buffer+0x12a001>
    59e4:	00f92023          	sw	a5,0(s2)
    59e8:	0064a023          	sw	t1,0(s1)
    59ec:	00100f93          	li	t6,1
    59f0:	fff6e7b7          	lui	a5,0xfff6e
    59f4:	05f72023          	sw	t6,64(a4)
    59f8:	00f687b3          	add	a5,a3,a5
    59fc:	00b603b3          	add	t2,a2,a1
    5a00:	00b68733          	add	a4,a3,a1
    5a04:	10f5fa63          	bgeu	a1,a5,5b18 <.L156>
    5a08:	000927b7          	lui	a5,0x92
    5a0c:	fff78793          	addi	a5,a5,-1 # 91fff <__kernel_data_lma+0x8674b>
    5a10:	40d78733          	sub	a4,a5,a3
    5a14:	ffffc7b7          	lui	a5,0xffffc
    5a18:	00f777b3          	and	a5,a4,a5
    5a1c:	00008f37          	lui	t5,0x8
    5a20:	01e78f33          	add	t5,a5,t5
    5a24:	00e12423          	sw	a4,8(sp)
    5a28:	00f12623          	sw	a5,12(sp)
    5a2c:	00cf0f33          	add	t5,t5,a2
    5a30:	00038313          	mv	t1,t2
    5a34:	ffb20737          	lui	a4,0xffb20
    5a38:	40c682b3          	sub	t0,a3,a2

00005a3c <.L119>:
    5a3c:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    5a40:	fe079ee3          	bnez	a5,5a3c <.L119>
    5a44:	00672023          	sw	t1,0(a4)
    5a48:	006287b3          	add	a5,t0,t1
    5a4c:	00f72623          	sw	a5,12(a4)
    5a50:	0004a783          	lw	a5,0(s1)
    5a54:	00b30333          	add	t1,t1,a1
    5a58:	00178793          	addi	a5,a5,1 # ffffc001 <__instrn_buffer+0x1bc001>
    5a5c:	00f4a023          	sw	a5,0(s1)
    5a60:	00092783          	lw	a5,0(s2)
    5a64:	00178793          	addi	a5,a5,1
    5a68:	00f92023          	sw	a5,0(s2)
    5a6c:	05f72023          	sw	t6,64(a4)
    5a70:	fde316e3          	bne	t1,t5,5a3c <.L119>
    5a74:	00812783          	lw	a5,8(sp)
    5a78:	00c12703          	lw	a4,12(sp)
    5a7c:	00e7d793          	srli	a5,a5,0xe
    5a80:	00b70733          	add	a4,a4,a1
    5a84:	000925b7          	lui	a1,0x92
    5a88:	00e383b3          	add	t2,t2,a4
    5a8c:	40d585b3          	sub	a1,a1,a3
    5a90:	00e79713          	slli	a4,a5,0xe
    5a94:	00070793          	mv	a5,a4
    5a98:	40e585b3          	sub	a1,a1,a4
    5a9c:	00008737          	lui	a4,0x8
    5aa0:	00e68733          	add	a4,a3,a4
    5aa4:	00e78733          	add	a4,a5,a4

00005aa8 <.L121>:
    5aa8:	04042783          	lw	a5,64(s0)
    5aac:	fe079ee3          	bnez	a5,5aa8 <.L121>
    5ab0:	00742023          	sw	t2,0(s0)
    5ab4:	02b42023          	sw	a1,32(s0)
    5ab8:	00e42623          	sw	a4,12(s0)
    5abc:	0004a703          	lw	a4,0(s1)
    5ac0:	00092783          	lw	a5,0(s2)
    5ac4:	fff665b7          	lui	a1,0xfff66
    5ac8:	00178793          	addi	a5,a5,1
    5acc:	00170713          	addi	a4,a4,1 # 8001 <.L417+0x25>
    5ad0:	00f92023          	sw	a5,0(s2)
    5ad4:	00e4a023          	sw	a4,0(s1)
    5ad8:	00b686b3          	add	a3,a3,a1
    5adc:	00100793          	li	a5,1
    5ae0:	01d60633          	add	a2,a2,t4
    5ae4:	011685b3          	add	a1,a3,a7
    5ae8:	04f42023          	sw	a5,64(s0)
    5aec:	c89ff06f          	j	5774 <.L115>

00005af0 <.L155>:
    5af0:	04042783          	lw	a5,64(s0)
    5af4:	00028313          	mv	t1,t0
    5af8:	00070613          	mv	a2,a4
    5afc:	d4079ee3          	bnez	a5,5858 <.L127>
    5b00:	d61ff06f          	j	5860 <.L157>

00005b04 <.L109>:
    5b04:	ffb01a37          	lui	s4,0xffb01
    5b08:	ffb004b7          	lui	s1,0xffb00
    5b0c:	918a2703          	lw	a4,-1768(s4) # ffb00918 <_ZL19downstream_data_ptr>
    5b10:	03448493          	addi	s1,s1,52 # ffb00034 <noc_nonposted_writes_num_issued>
    5b14:	da9ff06f          	j	58bc <.L129>

00005b18 <.L156>:
    5b18:	000965b7          	lui	a1,0x96
    5b1c:	40d585b3          	sub	a1,a1,a3
    5b20:	f89ff06f          	j	5aa8 <.L121>

00005b24 <_Z25write_pages_to_dispatcherILl0ELb0EEmRmS0_S0_.constprop.0>:
    5b24:	ffb017b7          	lui	a5,0xffb01
    5b28:	ffb01337          	lui	t1,0xffb01
    5b2c:	86c7a803          	lw	a6,-1940(a5) # ffb0086c <sem_l1_base>
    5b30:	91832783          	lw	a5,-1768(t1) # ffb00918 <_ZL19downstream_data_ptr>
    5b34:	ff010113          	addi	sp,sp,-16
    5b38:	01479613          	slli	a2,a5,0x14
    5b3c:	0005a783          	lw	a5,0(a1) # 96000 <__kernel_data_lma+0x8a74c>
    5b40:	01465613          	srli	a2,a2,0x14
    5b44:	00f60633          	add	a2,a2,a5
    5b48:	ffb007b7          	lui	a5,0xffb00
    5b4c:	0247a683          	lw	a3,36(a5) # ffb00024 <noc_nonposted_atomics_acked>
    5b50:	00c65613          	srli	a2,a2,0xc
    5b54:	ffb20737          	lui	a4,0xffb20

00005b58 <.L159>:
    5b58:	20072783          	lw	a5,512(a4) # ffb20200 <__stack_top+0x1e200>
    5b5c:	fed79ee3          	bne	a5,a3,5b58 <.L159>
    5b60:	0ff0000f          	fence
    5b64:	ffb016b7          	lui	a3,0xffb01

00005b68 <.L160>:
    5b68:	0ff0000f          	fence
    5b6c:	9246a703          	lw	a4,-1756(a3) # ffb00924 <_ZN24DispatchRelayInlineState9cb_writerE>
    5b70:	00082783          	lw	a5,0(a6)
    5b74:	00f707b3          	add	a5,a4,a5
    5b78:	40f607b3          	sub	a5,a2,a5
    5b7c:	fef046e3          	bgtz	a5,5b68 <.L160>
    5b80:	40c70733          	sub	a4,a4,a2
    5b84:	91832e83          	lw	t4,-1768(t1)
    5b88:	92e6a223          	sw	a4,-1756(a3)
    5b8c:	0009a7b7          	lui	a5,0x9a
    5b90:	2efe8863          	beq	t4,a5,5e80 <.L189>
    5b94:	0005af83          	lw	t6,0(a1)
    5b98:	000e8293          	mv	t0,t4
    5b9c:	01fe8733          	add	a4,t4,t6
    5ba0:	000e8e13          	mv	t3,t4
    5ba4:	14e7e863          	bltu	a5,a4,5cf4 <.L187>
    5ba8:	ffb008b7          	lui	a7,0xffb00
    5bac:	ffb00837          	lui	a6,0xffb00
    5bb0:	03488893          	addi	a7,a7,52 # ffb00034 <noc_nonposted_writes_num_issued>
    5bb4:	02c80813          	addi	a6,a6,44 # ffb0002c <noc_nonposted_writes_acked>

00005bb8 <.L162>:
    5bb8:	000047b7          	lui	a5,0x4
    5bbc:	00052503          	lw	a0,0(a0)
    5bc0:	0ff7f063          	bgeu	a5,t6,5ca0 <.L169>
    5bc4:	00812623          	sw	s0,12(sp)
    5bc8:	ffb20737          	lui	a4,0xffb20

00005bcc <.L170>:
    5bcc:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    5bd0:	fe079ee3          	bnez	a5,5bcc <.L170>
    5bd4:	00a72023          	sw	a0,0(a4)
    5bd8:	00004eb7          	lui	t4,0x4
    5bdc:	03d72023          	sw	t4,32(a4)
    5be0:	01c72623          	sw	t3,12(a4)
    5be4:	0008a683          	lw	a3,0(a7)
    5be8:	00082783          	lw	a5,0(a6)
    5bec:	00168693          	addi	a3,a3,1
    5bf0:	00178793          	addi	a5,a5,1 # 4001 <_start-0x9cf>
    5bf4:	00d8a023          	sw	a3,0(a7)
    5bf8:	00f82023          	sw	a5,0(a6)
    5bfc:	00100413          	li	s0,1
    5c00:	04872023          	sw	s0,64(a4)
    5c04:	41df87b3          	sub	a5,t6,t4
    5c08:	01d506b3          	add	a3,a0,t4
    5c0c:	01d28f33          	add	t5,t0,t4
    5c10:	ffffc737          	lui	a4,0xffffc
    5c14:	2afef463          	bgeu	t4,a5,5ebc <.L190>
    5c18:	ffff87b7          	lui	a5,0xffff8
    5c1c:	fff78793          	addi	a5,a5,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    5c20:	00ff8e33          	add	t3,t6,a5
    5c24:	000087b7          	lui	a5,0x8
    5c28:	00ee73b3          	and	t2,t3,a4
    5c2c:	00f507b3          	add	a5,a0,a5
    5c30:	40a70733          	sub	a4,a4,a0
    5c34:	01e70f33          	add	t5,a4,t5
    5c38:	00f383b3          	add	t2,t2,a5
    5c3c:	ffb20737          	lui	a4,0xffb20

00005c40 <.L172>:
    5c40:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    5c44:	fe079ee3          	bnez	a5,5c40 <.L172>
    5c48:	00d72023          	sw	a3,0(a4)
    5c4c:	00df07b3          	add	a5,t5,a3
    5c50:	00f72623          	sw	a5,12(a4)
    5c54:	0008a503          	lw	a0,0(a7)
    5c58:	00082783          	lw	a5,0(a6)
    5c5c:	00150513          	addi	a0,a0,1
    5c60:	00178793          	addi	a5,a5,1 # 8001 <.L417+0x25>
    5c64:	00a8a023          	sw	a0,0(a7)
    5c68:	00f82023          	sw	a5,0(a6)
    5c6c:	01d686b3          	add	a3,a3,t4
    5c70:	04872023          	sw	s0,64(a4)
    5c74:	fc7696e3          	bne	a3,t2,5c40 <.L172>
    5c78:	00008537          	lui	a0,0x8
    5c7c:	00ee5793          	srli	a5,t3,0xe
    5c80:	ffff8737          	lui	a4,0xffff8
    5c84:	00e79e13          	slli	t3,a5,0xe
    5c88:	00a282b3          	add	t0,t0,a0
    5c8c:	00ef8733          	add	a4,t6,a4
    5c90:	00c12403          	lw	s0,12(sp)
    5c94:	41c70fb3          	sub	t6,a4,t3
    5c98:	00068513          	mv	a0,a3
    5c9c:	005e0e33          	add	t3,t3,t0

00005ca0 <.L169>:
    5ca0:	ffb20737          	lui	a4,0xffb20

00005ca4 <.L174>:
    5ca4:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    5ca8:	fe079ee3          	bnez	a5,5ca4 <.L174>
    5cac:	00a72023          	sw	a0,0(a4)
    5cb0:	03f72023          	sw	t6,32(a4)
    5cb4:	01c72623          	sw	t3,12(a4)
    5cb8:	0008a683          	lw	a3,0(a7)
    5cbc:	00082783          	lw	a5,0(a6)
    5cc0:	00168693          	addi	a3,a3,1
    5cc4:	00178793          	addi	a5,a5,1
    5cc8:	00f82023          	sw	a5,0(a6)
    5ccc:	00d8a023          	sw	a3,0(a7)
    5cd0:	00100793          	li	a5,1
    5cd4:	04f72023          	sw	a5,64(a4)
    5cd8:	0005a703          	lw	a4,0(a1)
    5cdc:	91832783          	lw	a5,-1768(t1)
    5ce0:	00060513          	mv	a0,a2
    5ce4:	00e787b3          	add	a5,a5,a4
    5ce8:	90f32c23          	sw	a5,-1768(t1)
    5cec:	01010113          	addi	sp,sp,16
    5cf0:	00008067          	ret

00005cf4 <.L187>:
    5cf4:	fff6a737          	lui	a4,0xfff6a
    5cf8:	00ee8733          	add	a4,t4,a4
    5cfc:	000046b7          	lui	a3,0x4
    5d00:	00052f83          	lw	t6,0(a0) # 8000 <.L417+0x24>
    5d04:	41d78e33          	sub	t3,a5,t4
    5d08:	18e6fe63          	bgeu	a3,a4,5ea4 <.L175>
    5d0c:	00812623          	sw	s0,12(sp)
    5d10:	00912423          	sw	s1,8(sp)
    5d14:	ffb20737          	lui	a4,0xffb20

00005d18 <.L164>:
    5d18:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    5d1c:	fe079ee3          	bnez	a5,5d18 <.L164>
    5d20:	01f72023          	sw	t6,0(a4)
    5d24:	000043b7          	lui	t2,0x4
    5d28:	02772023          	sw	t2,32(a4)
    5d2c:	ffb008b7          	lui	a7,0xffb00
    5d30:	ffb00837          	lui	a6,0xffb00
    5d34:	01d72623          	sw	t4,12(a4)
    5d38:	03488893          	addi	a7,a7,52 # ffb00034 <noc_nonposted_writes_num_issued>
    5d3c:	02c80813          	addi	a6,a6,44 # ffb0002c <noc_nonposted_writes_acked>
    5d40:	0008a683          	lw	a3,0(a7)
    5d44:	00082783          	lw	a5,0(a6)
    5d48:	00168693          	addi	a3,a3,1 # 4001 <_start-0x9cf>
    5d4c:	00178793          	addi	a5,a5,1
    5d50:	00f82023          	sw	a5,0(a6)
    5d54:	00d8a023          	sw	a3,0(a7)
    5d58:	00100413          	li	s0,1
    5d5c:	fff6e7b7          	lui	a5,0xfff6e
    5d60:	04872023          	sw	s0,64(a4)
    5d64:	00fe87b3          	add	a5,t4,a5
    5d68:	007f84b3          	add	s1,t6,t2
    5d6c:	007e82b3          	add	t0,t4,t2
    5d70:	16f3f063          	bgeu	t2,a5,5ed0 <.L191>
    5d74:	000927b7          	lui	a5,0x92
    5d78:	fff78793          	addi	a5,a5,-1 # 91fff <__kernel_data_lma+0x8674b>
    5d7c:	41d782b3          	sub	t0,a5,t4
    5d80:	ffffc7b7          	lui	a5,0xffffc
    5d84:	00f2f7b3          	and	a5,t0,a5
    5d88:	00008f37          	lui	t5,0x8
    5d8c:	01e78f33          	add	t5,a5,t5
    5d90:	01212223          	sw	s2,4(sp)
    5d94:	01ff0f33          	add	t5,t5,t6
    5d98:	00078913          	mv	s2,a5
    5d9c:	41fe8fb3          	sub	t6,t4,t6
    5da0:	00048693          	mv	a3,s1
    5da4:	ffb20737          	lui	a4,0xffb20

00005da8 <.L166>:
    5da8:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    5dac:	fe079ee3          	bnez	a5,5da8 <.L166>
    5db0:	00d72023          	sw	a3,0(a4)
    5db4:	00df87b3          	add	a5,t6,a3
    5db8:	00f72623          	sw	a5,12(a4)
    5dbc:	0008a783          	lw	a5,0(a7)
    5dc0:	007686b3          	add	a3,a3,t2
    5dc4:	00178793          	addi	a5,a5,1 # ffffc001 <__instrn_buffer+0x1bc001>
    5dc8:	00f8a023          	sw	a5,0(a7)
    5dcc:	00082783          	lw	a5,0(a6)
    5dd0:	00178793          	addi	a5,a5,1
    5dd4:	00f82023          	sw	a5,0(a6)
    5dd8:	04872023          	sw	s0,64(a4)
    5ddc:	fde696e3          	bne	a3,t5,5da8 <.L166>
    5de0:	00e2d793          	srli	a5,t0,0xe
    5de4:	00790733          	add	a4,s2,t2
    5de8:	000926b7          	lui	a3,0x92
    5dec:	000082b7          	lui	t0,0x8
    5df0:	00e79f13          	slli	t5,a5,0xe
    5df4:	41d686b3          	sub	a3,a3,t4
    5df8:	005e82b3          	add	t0,t4,t0
    5dfc:	00970fb3          	add	t6,a4,s1
    5e00:	00c12403          	lw	s0,12(sp)
    5e04:	00812483          	lw	s1,8(sp)
    5e08:	00412903          	lw	s2,4(sp)
    5e0c:	41e686b3          	sub	a3,a3,t5
    5e10:	01e282b3          	add	t0,t0,t5

00005e14 <.L163>:
    5e14:	ffb20737          	lui	a4,0xffb20

00005e18 <.L168>:
    5e18:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    5e1c:	fe079ee3          	bnez	a5,5e18 <.L168>
    5e20:	01f72023          	sw	t6,0(a4)
    5e24:	02d72023          	sw	a3,32(a4)
    5e28:	00572623          	sw	t0,12(a4)
    5e2c:	0008a683          	lw	a3,0(a7)
    5e30:	00082783          	lw	a5,0(a6)
    5e34:	00168693          	addi	a3,a3,1 # 92001 <__kernel_data_lma+0x8674d>
    5e38:	00178793          	addi	a5,a5,1
    5e3c:	00f82023          	sw	a5,0(a6)
    5e40:	00d8a023          	sw	a3,0(a7)
    5e44:	00100793          	li	a5,1
    5e48:	04f72023          	sw	a5,64(a4)
    5e4c:	0001a7b7          	lui	a5,0x1a
    5e50:	90f32c23          	sw	a5,-1768(t1)
    5e54:	00052783          	lw	a5,0(a0)
    5e58:	fff66737          	lui	a4,0xfff66
    5e5c:	01c787b3          	add	a5,a5,t3
    5e60:	00f52023          	sw	a5,0(a0)
    5e64:	0005af83          	lw	t6,0(a1)
    5e68:	00ee8eb3          	add	t4,t4,a4
    5e6c:	01fe8fb3          	add	t6,t4,t6
    5e70:	01f5a023          	sw	t6,0(a1)
    5e74:	91832283          	lw	t0,-1768(t1)
    5e78:	00028e13          	mv	t3,t0
    5e7c:	d3dff06f          	j	5bb8 <.L162>

00005e80 <.L189>:
    5e80:	0001ae37          	lui	t3,0x1a
    5e84:	91c32c23          	sw	t3,-1768(t1)
    5e88:	ffb008b7          	lui	a7,0xffb00
    5e8c:	ffb00837          	lui	a6,0xffb00
    5e90:	0005af83          	lw	t6,0(a1)
    5e94:	000e0293          	mv	t0,t3
    5e98:	03488893          	addi	a7,a7,52 # ffb00034 <noc_nonposted_writes_num_issued>
    5e9c:	02c80813          	addi	a6,a6,44 # ffb0002c <noc_nonposted_writes_acked>
    5ea0:	d19ff06f          	j	5bb8 <.L162>

00005ea4 <.L175>:
    5ea4:	ffb008b7          	lui	a7,0xffb00
    5ea8:	ffb00837          	lui	a6,0xffb00
    5eac:	03488893          	addi	a7,a7,52 # ffb00034 <noc_nonposted_writes_num_issued>
    5eb0:	02c80813          	addi	a6,a6,44 # ffb0002c <noc_nonposted_writes_acked>
    5eb4:	000e0693          	mv	a3,t3
    5eb8:	f5dff06f          	j	5e14 <.L163>

00005ebc <.L190>:
    5ebc:	00c12403          	lw	s0,12(sp)
    5ec0:	000f0e13          	mv	t3,t5
    5ec4:	00078f93          	mv	t6,a5
    5ec8:	00068513          	mv	a0,a3
    5ecc:	dd5ff06f          	j	5ca0 <.L169>

00005ed0 <.L191>:
    5ed0:	000966b7          	lui	a3,0x96
    5ed4:	00048f93          	mv	t6,s1
    5ed8:	00c12403          	lw	s0,12(sp)
    5edc:	00812483          	lw	s1,8(sp)
    5ee0:	41d686b3          	sub	a3,a3,t4
    5ee4:	f31ff06f          	j	5e14 <.L163>

00005ee8 <_Z33process_relay_ringbuffer_sub_cmdsmPm>:
    5ee8:	ffb007b7          	lui	a5,0xffb00
    5eec:	fa010113          	addi	sp,sp,-96
    5ef0:	03c7a683          	lw	a3,60(a5) # ffb0003c <noc_reads_num_issued>
    5ef4:	03812c23          	sw	s8,56(sp)
    5ef8:	04112e23          	sw	ra,92(sp)
    5efc:	04812c23          	sw	s0,88(sp)
    5f00:	04912a23          	sw	s1,84(sp)
    5f04:	05212823          	sw	s2,80(sp)
    5f08:	05512223          	sw	s5,68(sp)
    5f0c:	03a12823          	sw	s10,48(sp)
    5f10:	00058c13          	mv	s8,a1
    5f14:	ffb20737          	lui	a4,0xffb20

00005f18 <.L193>:
    5f18:	20872783          	lw	a5,520(a4) # ffb20208 <__stack_top+0x1e208>
    5f1c:	fed79ee3          	bne	a5,a3,5f18 <.L193>
    5f20:	0ff0000f          	fence
    5f24:	ffb017b7          	lui	a5,0xffb01
    5f28:	92c7a903          	lw	s2,-1748(a5) # ffb0092c <_ZL17ringbuffer_offset>
    5f2c:	0005a7b7          	lui	a5,0x5a
    5f30:	44078793          	addi	a5,a5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    5f34:	00100a93          	li	s5,1
    5f38:	00f90933          	add	s2,s2,a5
    5f3c:	4d550a63          	beq	a0,s5,6410 <.L194>
    5f40:	05312623          	sw	s3,76(sp)
    5f44:	05412423          	sw	s4,72(sp)
    5f48:	ffb014b7          	lui	s1,0xffb01
    5f4c:	ffb00d37          	lui	s10,0xffb00
    5f50:	00002a37          	lui	s4,0x2
    5f54:	000019b7          	lui	s3,0x1
    5f58:	05612023          	sw	s6,64(sp)
    5f5c:	03712e23          	sw	s7,60(sp)
    5f60:	03912a23          	sw	s9,52(sp)
    5f64:	03b12623          	sw	s11,44(sp)
    5f68:	00a12623          	sw	a0,12(sp)
    5f6c:	86c48493          	addi	s1,s1,-1940 # ffb0086c <sem_l1_base>
    5f70:	024d0d13          	addi	s10,s10,36 # ffb00024 <noc_nonposted_atomics_acked>
    5f74:	091a0a13          	addi	s4,s4,145 # 2091 <_start-0x293f>
    5f78:	07c98993          	addi	s3,s3,124 # 107c <_start-0x3954>
    5f7c:	fff50b93          	addi	s7,a0,-1
    5f80:	000c0d93          	mv	s11,s8
    5f84:	00000c93          	li	s9,0
    5f88:	ffb22437          	lui	s0,0xffb22
    5f8c:	0ce00b13          	li	s6,206

00005f90 <.L196>:
    5f90:	000da783          	lw	a5,0(s11) # 1a000 <__kernel_data_lma+0xe74c>
    5f94:	004da683          	lw	a3,4(s11)
    5f98:	01810593          	addi	a1,sp,24
    5f9c:	01c10513          	addi	a0,sp,28
    5fa0:	012787b3          	add	a5,a5,s2
    5fa4:	00d12c23          	sw	a3,24(sp)
    5fa8:	00f12e23          	sw	a5,28(sp)
    5fac:	b79ff0ef          	jal	5b24 <_Z25write_pages_to_dispatcherILl0ELb0EEmRmS0_S0_.constprop.0>
    5fb0:	0004a683          	lw	a3,0(s1)

00005fb4 <.L195>:
    5fb4:	84042783          	lw	a5,-1984(s0) # ffb21840 <__stack_top+0x1f840>
    5fb8:	fe079ee3          	bnez	a5,5fb4 <.L195>
    5fbc:	80d42023          	sw	a3,-2048(s0)
    5fc0:	80042223          	sw	zero,-2044(s0)
    5fc4:	0026d793          	srli	a5,a3,0x2
    5fc8:	81642423          	sw	s6,-2040(s0)
    5fcc:	0037f793          	andi	a5,a5,3
    5fd0:	81442e23          	sw	s4,-2020(s0)
    5fd4:	0137e7b3          	or	a5,a5,s3
    5fd8:	82f42023          	sw	a5,-2016(s0)
    5fdc:	82a42423          	sw	a0,-2008(s0)
    5fe0:	85542023          	sw	s5,-1984(s0)
    5fe4:	000d2783          	lw	a5,0(s10)
    5fe8:	001c8c93          	addi	s9,s9,1
    5fec:	00178793          	addi	a5,a5,1
    5ff0:	00fd2023          	sw	a5,0(s10)
    5ff4:	008d8d93          	addi	s11,s11,8
    5ff8:	f97c9ce3          	bne	s9,s7,5f90 <.L196>
    5ffc:	00c12703          	lw	a4,12(sp)
    6000:	04c12983          	lw	s3,76(sp)
    6004:	21876cb3          	sh3add	s9,a4,s8
    6008:	04812a03          	lw	s4,72(sp)
    600c:	ff8c8c13          	addi	s8,s9,-8
    6010:	04012b03          	lw	s6,64(sp)
    6014:	03c12b83          	lw	s7,60(sp)
    6018:	03412c83          	lw	s9,52(sp)
    601c:	02c12d83          	lw	s11,44(sp)

00006020 <.L197>:
    6020:	004c2883          	lw	a7,4(s8) # 9a004 <__kernel_data_lma+0x8e750>
    6024:	000c2e83          	lw	t4,0(s8)
    6028:	ffb01337          	lui	t1,0xffb01
    602c:	91832603          	lw	a2,-1768(t1) # ffb00918 <_ZL19downstream_data_ptr>
    6030:	ffb205b7          	lui	a1,0xffb20
    6034:	01461613          	slli	a2,a2,0x14
    6038:	01465613          	srli	a2,a2,0x14
    603c:	fff60613          	addi	a2,a2,-1
    6040:	01160633          	add	a2,a2,a7
    6044:	00c65613          	srli	a2,a2,0xc
    6048:	01d90eb3          	add	t4,s2,t4

0000604c <.L198>:
    604c:	2005a703          	lw	a4,512(a1) # ffb20200 <__stack_top+0x1e200>
    6050:	fef71ee3          	bne	a4,a5,604c <.L198>
    6054:	0ff0000f          	fence
    6058:	ffb015b7          	lui	a1,0xffb01

0000605c <.L199>:
    605c:	0ff0000f          	fence
    6060:	9245a703          	lw	a4,-1756(a1) # ffb00924 <_ZN24DispatchRelayInlineState9cb_writerE>
    6064:	0006a783          	lw	a5,0(a3) # 96000 <__kernel_data_lma+0x8a74c>
    6068:	00f707b3          	add	a5,a4,a5
    606c:	40f607b3          	sub	a5,a2,a5
    6070:	fef046e3          	bgtz	a5,605c <.L199>
    6074:	40c70733          	sub	a4,a4,a2
    6078:	91832e03          	lw	t3,-1768(t1)
    607c:	92e5a223          	sw	a4,-1756(a1)
    6080:	0009a737          	lui	a4,0x9a
    6084:	34ee0663          	beq	t3,a4,63d0 <.L234>
    6088:	01c885b3          	add	a1,a7,t3
    608c:	000e0293          	mv	t0,t3
    6090:	000e0693          	mv	a3,t3
    6094:	1cb76863          	bltu	a4,a1,6264 <.L232>
    6098:	ffb00837          	lui	a6,0xffb00
    609c:	ffb00537          	lui	a0,0xffb00
    60a0:	03480813          	addi	a6,a6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    60a4:	02c50513          	addi	a0,a0,44 # ffb0002c <noc_nonposted_writes_acked>

000060a8 <.L201>:
    60a8:	000047b7          	lui	a5,0x4
    60ac:	00088e13          	mv	t3,a7
    60b0:	0d17fc63          	bgeu	a5,a7,6188 <.L208>
    60b4:	ffb20737          	lui	a4,0xffb20

000060b8 <.L209>:
    60b8:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    60bc:	fe079ee3          	bnez	a5,60b8 <.L209>
    60c0:	01d72023          	sw	t4,0(a4)
    60c4:	00004fb7          	lui	t6,0x4
    60c8:	03f72023          	sw	t6,32(a4)
    60cc:	00d72623          	sw	a3,12(a4)
    60d0:	00082683          	lw	a3,0(a6)
    60d4:	00052783          	lw	a5,0(a0)
    60d8:	00168693          	addi	a3,a3,1
    60dc:	00178793          	addi	a5,a5,1 # 4001 <_start-0x9cf>
    60e0:	00d82023          	sw	a3,0(a6)
    60e4:	00f52023          	sw	a5,0(a0)
    60e8:	00100393          	li	t2,1
    60ec:	04772023          	sw	t2,64(a4)
    60f0:	41f88e33          	sub	t3,a7,t6
    60f4:	01fe85b3          	add	a1,t4,t6
    60f8:	01f286b3          	add	a3,t0,t6
    60fc:	ffffc737          	lui	a4,0xffffc
    6100:	33cff663          	bgeu	t6,t3,642c <.L235>
    6104:	ffff87b7          	lui	a5,0xffff8
    6108:	fff78793          	addi	a5,a5,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    610c:	00f88e33          	add	t3,a7,a5
    6110:	00ee77b3          	and	a5,t3,a4
    6114:	41d70733          	sub	a4,a4,t4
    6118:	00d70f33          	add	t5,a4,a3
    611c:	00008737          	lui	a4,0x8
    6120:	00ee8733          	add	a4,t4,a4
    6124:	00e78eb3          	add	t4,a5,a4
    6128:	ffb20737          	lui	a4,0xffb20

0000612c <.L211>:
    612c:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    6130:	fe079ee3          	bnez	a5,612c <.L211>
    6134:	00b72023          	sw	a1,0(a4)
    6138:	00bf07b3          	add	a5,t5,a1
    613c:	00f72623          	sw	a5,12(a4)
    6140:	00082683          	lw	a3,0(a6)
    6144:	00052783          	lw	a5,0(a0)
    6148:	00168693          	addi	a3,a3,1
    614c:	00178793          	addi	a5,a5,1
    6150:	00d82023          	sw	a3,0(a6)
    6154:	00f52023          	sw	a5,0(a0)
    6158:	01f585b3          	add	a1,a1,t6
    615c:	04772023          	sw	t2,64(a4)
    6160:	fdd596e3          	bne	a1,t4,612c <.L211>
    6164:	00ee5793          	srli	a5,t3,0xe
    6168:	000086b7          	lui	a3,0x8
    616c:	ffff8e37          	lui	t3,0xffff8
    6170:	00e79713          	slli	a4,a5,0xe
    6174:	01c88e33          	add	t3,a7,t3
    6178:	00d282b3          	add	t0,t0,a3
    617c:	00058e93          	mv	t4,a1
    6180:	40ee0e33          	sub	t3,t3,a4
    6184:	005706b3          	add	a3,a4,t0

00006188 <.L208>:
    6188:	ffb20737          	lui	a4,0xffb20

0000618c <.L213>:
    618c:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    6190:	fe079ee3          	bnez	a5,618c <.L213>
    6194:	01d72023          	sw	t4,0(a4)
    6198:	03c72023          	sw	t3,32(a4)
    619c:	00d72623          	sw	a3,12(a4)
    61a0:	00082583          	lw	a1,0(a6)
    61a4:	00052783          	lw	a5,0(a0)
    61a8:	00158593          	addi	a1,a1,1
    61ac:	00178793          	addi	a5,a5,1
    61b0:	0004a683          	lw	a3,0(s1)
    61b4:	00f52023          	sw	a5,0(a0)
    61b8:	00b82023          	sw	a1,0(a6)
    61bc:	00100793          	li	a5,1
    61c0:	04f72023          	sw	a5,64(a4)
    61c4:	91832783          	lw	a5,-1768(t1)
    61c8:	00001737          	lui	a4,0x1
    61cc:	fff70713          	addi	a4,a4,-1 # fff <_start-0x39d1>
    61d0:	00e787b3          	add	a5,a5,a4
    61d4:	011787b3          	add	a5,a5,a7
    61d8:	fffff737          	lui	a4,0xfffff
    61dc:	00e7f7b3          	and	a5,a5,a4
    61e0:	00160613          	addi	a2,a2,1
    61e4:	90f32c23          	sw	a5,-1768(t1)
    61e8:	ffb22737          	lui	a4,0xffb22

000061ec <.L214>:
    61ec:	84072783          	lw	a5,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    61f0:	fe079ee3          	bnez	a5,61ec <.L214>
    61f4:	80d72023          	sw	a3,-2048(a4)
    61f8:	80072223          	sw	zero,-2044(a4)
    61fc:	0026d793          	srli	a5,a3,0x2
    6200:	000015b7          	lui	a1,0x1
    6204:	0ce00513          	li	a0,206
    6208:	000026b7          	lui	a3,0x2
    620c:	80a72423          	sw	a0,-2040(a4)
    6210:	0037f793          	andi	a5,a5,3
    6214:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    6218:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    621c:	80d72e23          	sw	a3,-2020(a4)
    6220:	00b7e7b3          	or	a5,a5,a1
    6224:	82f72023          	sw	a5,-2016(a4)
    6228:	82c72423          	sw	a2,-2008(a4)
    622c:	00100793          	li	a5,1
    6230:	84f72023          	sw	a5,-1984(a4)
    6234:	000d2783          	lw	a5,0(s10)
    6238:	05c12083          	lw	ra,92(sp)
    623c:	05812403          	lw	s0,88(sp)
    6240:	00178793          	addi	a5,a5,1
    6244:	00fd2023          	sw	a5,0(s10)
    6248:	05412483          	lw	s1,84(sp)
    624c:	05012903          	lw	s2,80(sp)
    6250:	04412a83          	lw	s5,68(sp)
    6254:	03812c03          	lw	s8,56(sp)
    6258:	03012d03          	lw	s10,48(sp)
    625c:	06010113          	addi	sp,sp,96
    6260:	00008067          	ret

00006264 <.L232>:
    6264:	fff6a7b7          	lui	a5,0xfff6a
    6268:	00fe07b3          	add	a5,t3,a5
    626c:	000046b7          	lui	a3,0x4
    6270:	41c70f33          	sub	t5,a4,t3
    6274:	18f6f063          	bgeu	a3,a5,63f4 <.L215>
    6278:	ffb207b7          	lui	a5,0xffb20

0000627c <.L203>:
    627c:	0407a683          	lw	a3,64(a5) # ffb20040 <__stack_top+0x1e040>
    6280:	fe069ee3          	bnez	a3,627c <.L203>
    6284:	01d7a023          	sw	t4,0(a5)
    6288:	00004fb7          	lui	t6,0x4
    628c:	03f7a023          	sw	t6,32(a5)
    6290:	ffb00837          	lui	a6,0xffb00
    6294:	ffb00537          	lui	a0,0xffb00
    6298:	01c7a623          	sw	t3,12(a5)
    629c:	03480813          	addi	a6,a6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    62a0:	02c50513          	addi	a0,a0,44 # ffb0002c <noc_nonposted_writes_acked>
    62a4:	00082683          	lw	a3,0(a6)
    62a8:	00052703          	lw	a4,0(a0)
    62ac:	00168693          	addi	a3,a3,1 # 4001 <_start-0x9cf>
    62b0:	00170713          	addi	a4,a4,1
    62b4:	00d82023          	sw	a3,0(a6)
    62b8:	00e52023          	sw	a4,0(a0)
    62bc:	00100393          	li	t2,1
    62c0:	0477a023          	sw	t2,64(a5)
    62c4:	fff6e7b7          	lui	a5,0xfff6e
    62c8:	00fe07b3          	add	a5,t3,a5
    62cc:	01fe8433          	add	s0,t4,t6
    62d0:	01fe02b3          	add	t0,t3,t6
    62d4:	16fff063          	bgeu	t6,a5,6434 <.L236>
    62d8:	00092737          	lui	a4,0x92
    62dc:	fff70713          	addi	a4,a4,-1 # 91fff <__kernel_data_lma+0x8674b>
    62e0:	05312623          	sw	s3,76(sp)
    62e4:	05412423          	sw	s4,72(sp)
    62e8:	ffffc9b7          	lui	s3,0xffffc
    62ec:	41c70a33          	sub	s4,a4,t3
    62f0:	013a79b3          	and	s3,s4,s3
    62f4:	000082b7          	lui	t0,0x8
    62f8:	005982b3          	add	t0,s3,t0
    62fc:	01d282b3          	add	t0,t0,t4
    6300:	00040693          	mv	a3,s0
    6304:	ffb20737          	lui	a4,0xffb20
    6308:	41de0933          	sub	s2,t3,t4

0000630c <.L205>:
    630c:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    6310:	fe079ee3          	bnez	a5,630c <.L205>
    6314:	00d72023          	sw	a3,0(a4)
    6318:	00d907b3          	add	a5,s2,a3
    631c:	00f72623          	sw	a5,12(a4)
    6320:	00082583          	lw	a1,0(a6)
    6324:	01f686b3          	add	a3,a3,t6
    6328:	00158593          	addi	a1,a1,1
    632c:	00b82023          	sw	a1,0(a6)
    6330:	00052583          	lw	a1,0(a0)
    6334:	00158593          	addi	a1,a1,1
    6338:	00b52023          	sw	a1,0(a0)
    633c:	04772023          	sw	t2,64(a4)
    6340:	fc5696e3          	bne	a3,t0,630c <.L205>
    6344:	00ea5713          	srli	a4,s4,0xe
    6348:	01f989b3          	add	s3,s3,t6
    634c:	000927b7          	lui	a5,0x92
    6350:	000082b7          	lui	t0,0x8
    6354:	00e71693          	slli	a3,a4,0xe
    6358:	01340433          	add	s0,s0,s3
    635c:	41c787b3          	sub	a5,a5,t3
    6360:	005e02b3          	add	t0,t3,t0
    6364:	04c12983          	lw	s3,76(sp)
    6368:	04812a03          	lw	s4,72(sp)
    636c:	40d787b3          	sub	a5,a5,a3
    6370:	00d282b3          	add	t0,t0,a3

00006374 <.L202>:
    6374:	ffb206b7          	lui	a3,0xffb20

00006378 <.L207>:
    6378:	0406a703          	lw	a4,64(a3) # ffb20040 <__stack_top+0x1e040>
    637c:	fe071ee3          	bnez	a4,6378 <.L207>
    6380:	0086a023          	sw	s0,0(a3)
    6384:	02f6a023          	sw	a5,32(a3)
    6388:	0056a623          	sw	t0,12(a3)
    638c:	00082703          	lw	a4,0(a6)
    6390:	00052783          	lw	a5,0(a0)
    6394:	00170713          	addi	a4,a4,1
    6398:	00178793          	addi	a5,a5,1 # 92001 <__kernel_data_lma+0x8674d>
    639c:	00e82023          	sw	a4,0(a6)
    63a0:	00f52023          	sw	a5,0(a0)
    63a4:	00100793          	li	a5,1
    63a8:	04f6a023          	sw	a5,64(a3)
    63ac:	fff667b7          	lui	a5,0xfff66
    63b0:	0001a737          	lui	a4,0x1a
    63b4:	00fe07b3          	add	a5,t3,a5
    63b8:	01ee8eb3          	add	t4,t4,t5
    63bc:	00070293          	mv	t0,a4
    63c0:	90e32c23          	sw	a4,-1768(t1)
    63c4:	00070693          	mv	a3,a4
    63c8:	00f888b3          	add	a7,a7,a5
    63cc:	cddff06f          	j	60a8 <.L201>

000063d0 <.L234>:
    63d0:	0001a7b7          	lui	a5,0x1a
    63d4:	ffb00837          	lui	a6,0xffb00
    63d8:	ffb00537          	lui	a0,0xffb00
    63dc:	00078693          	mv	a3,a5
    63e0:	90f32c23          	sw	a5,-1768(t1)
    63e4:	00078293          	mv	t0,a5
    63e8:	03480813          	addi	a6,a6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    63ec:	02c50513          	addi	a0,a0,44 # ffb0002c <noc_nonposted_writes_acked>
    63f0:	cb9ff06f          	j	60a8 <.L201>

000063f4 <.L215>:
    63f4:	ffb00837          	lui	a6,0xffb00
    63f8:	ffb00537          	lui	a0,0xffb00
    63fc:	03480813          	addi	a6,a6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    6400:	02c50513          	addi	a0,a0,44 # ffb0002c <noc_nonposted_writes_acked>
    6404:	000f0793          	mv	a5,t5
    6408:	000e8413          	mv	s0,t4
    640c:	f69ff06f          	j	6374 <.L202>

00006410 <.L194>:
    6410:	ffb014b7          	lui	s1,0xffb01
    6414:	ffb00d37          	lui	s10,0xffb00
    6418:	86c48493          	addi	s1,s1,-1940 # ffb0086c <sem_l1_base>
    641c:	024d0d13          	addi	s10,s10,36 # ffb00024 <noc_nonposted_atomics_acked>
    6420:	0004a683          	lw	a3,0(s1)
    6424:	000d2783          	lw	a5,0(s10)
    6428:	bf9ff06f          	j	6020 <.L197>

0000642c <.L235>:
    642c:	00058e93          	mv	t4,a1
    6430:	d59ff06f          	j	6188 <.L208>

00006434 <.L236>:
    6434:	000967b7          	lui	a5,0x96
    6438:	41c787b3          	sub	a5,a5,t3
    643c:	f39ff06f          	j	6374 <.L202>

00006440 <_Z25write_pages_to_dispatcherILl1ELb1EEmRmS0_S0_.constprop.0>:
    6440:	ffb01e37          	lui	t3,0xffb01
    6444:	918e2683          	lw	a3,-1768(t3) # ffb00918 <_ZL19downstream_data_ptr>
    6448:	0005a783          	lw	a5,0(a1)
    644c:	01469893          	slli	a7,a3,0x14
    6450:	0148d893          	srli	a7,a7,0x14
    6454:	fff88893          	addi	a7,a7,-1
    6458:	00f888b3          	add	a7,a7,a5
    645c:	00c8d893          	srli	a7,a7,0xc
    6460:	ff010113          	addi	sp,sp,-16
    6464:	04088663          	beqz	a7,64b0 <.L238>
    6468:	ffb017b7          	lui	a5,0xffb01
    646c:	86c7a683          	lw	a3,-1940(a5) # ffb0086c <sem_l1_base>
    6470:	ffb007b7          	lui	a5,0xffb00
    6474:	0247a603          	lw	a2,36(a5) # ffb00024 <noc_nonposted_atomics_acked>
    6478:	ffb20737          	lui	a4,0xffb20

0000647c <.L239>:
    647c:	20072783          	lw	a5,512(a4) # ffb20200 <__stack_top+0x1e200>
    6480:	fec79ee3          	bne	a5,a2,647c <.L239>
    6484:	0ff0000f          	fence
    6488:	ffb01637          	lui	a2,0xffb01

0000648c <.L240>:
    648c:	0ff0000f          	fence
    6490:	92462703          	lw	a4,-1756(a2) # ffb00924 <_ZN24DispatchRelayInlineState9cb_writerE>
    6494:	0006a783          	lw	a5,0(a3)
    6498:	00f707b3          	add	a5,a4,a5
    649c:	40f887b3          	sub	a5,a7,a5
    64a0:	fef046e3          	bgtz	a5,648c <.L240>
    64a4:	41170733          	sub	a4,a4,a7
    64a8:	918e2683          	lw	a3,-1768(t3)
    64ac:	92e62223          	sw	a4,-1756(a2)

000064b0 <.L238>:
    64b0:	0009a7b7          	lui	a5,0x9a
    64b4:	2ef68263          	beq	a3,a5,6798 <.L272>
    64b8:	0005af83          	lw	t6,0(a1)
    64bc:	00068293          	mv	t0,a3
    64c0:	00df8733          	add	a4,t6,a3
    64c4:	00068313          	mv	t1,a3
    64c8:	14e7e863          	bltu	a5,a4,6618 <.L270>
    64cc:	ffb00837          	lui	a6,0xffb00
    64d0:	ffb00637          	lui	a2,0xffb00
    64d4:	03480813          	addi	a6,a6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    64d8:	02c60613          	addi	a2,a2,44 # ffb0002c <noc_nonposted_writes_acked>

000064dc <.L242>:
    64dc:	000047b7          	lui	a5,0x4
    64e0:	00052503          	lw	a0,0(a0)
    64e4:	0ff7f063          	bgeu	a5,t6,65c4 <.L249>
    64e8:	00812623          	sw	s0,12(sp)
    64ec:	ffb20737          	lui	a4,0xffb20

000064f0 <.L250>:
    64f0:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    64f4:	fe079ee3          	bnez	a5,64f0 <.L250>
    64f8:	00a72023          	sw	a0,0(a4)
    64fc:	00004eb7          	lui	t4,0x4
    6500:	03d72023          	sw	t4,32(a4)
    6504:	00672623          	sw	t1,12(a4)
    6508:	00082683          	lw	a3,0(a6)
    650c:	00062783          	lw	a5,0(a2)
    6510:	00168693          	addi	a3,a3,1
    6514:	00178793          	addi	a5,a5,1 # 4001 <_start-0x9cf>
    6518:	00d82023          	sw	a3,0(a6)
    651c:	00f62023          	sw	a5,0(a2)
    6520:	00100413          	li	s0,1
    6524:	04872023          	sw	s0,64(a4)
    6528:	41df87b3          	sub	a5,t6,t4
    652c:	01d506b3          	add	a3,a0,t4
    6530:	01d28f33          	add	t5,t0,t4
    6534:	ffffc737          	lui	a4,0xffffc
    6538:	28fefe63          	bgeu	t4,a5,67d4 <.L273>
    653c:	ffff87b7          	lui	a5,0xffff8
    6540:	fff78793          	addi	a5,a5,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    6544:	00ff8333          	add	t1,t6,a5
    6548:	000087b7          	lui	a5,0x8
    654c:	00e373b3          	and	t2,t1,a4
    6550:	00f507b3          	add	a5,a0,a5
    6554:	40a70733          	sub	a4,a4,a0
    6558:	01e70f33          	add	t5,a4,t5
    655c:	00f383b3          	add	t2,t2,a5
    6560:	ffb20737          	lui	a4,0xffb20

00006564 <.L252>:
    6564:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    6568:	fe079ee3          	bnez	a5,6564 <.L252>
    656c:	00d72023          	sw	a3,0(a4)
    6570:	00df07b3          	add	a5,t5,a3
    6574:	00f72623          	sw	a5,12(a4)
    6578:	00082503          	lw	a0,0(a6)
    657c:	00062783          	lw	a5,0(a2)
    6580:	00150513          	addi	a0,a0,1
    6584:	00178793          	addi	a5,a5,1 # 8001 <.L417+0x25>
    6588:	00a82023          	sw	a0,0(a6)
    658c:	00f62023          	sw	a5,0(a2)
    6590:	01d686b3          	add	a3,a3,t4
    6594:	04872023          	sw	s0,64(a4)
    6598:	fc7696e3          	bne	a3,t2,6564 <.L252>
    659c:	00008537          	lui	a0,0x8
    65a0:	00e35793          	srli	a5,t1,0xe
    65a4:	ffff8737          	lui	a4,0xffff8
    65a8:	00e79313          	slli	t1,a5,0xe
    65ac:	00a282b3          	add	t0,t0,a0
    65b0:	00ef8733          	add	a4,t6,a4
    65b4:	00c12403          	lw	s0,12(sp)
    65b8:	40670fb3          	sub	t6,a4,t1
    65bc:	00068513          	mv	a0,a3
    65c0:	00530333          	add	t1,t1,t0

000065c4 <.L249>:
    65c4:	ffb20737          	lui	a4,0xffb20

000065c8 <.L254>:
    65c8:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    65cc:	fe079ee3          	bnez	a5,65c8 <.L254>
    65d0:	00a72023          	sw	a0,0(a4)
    65d4:	03f72023          	sw	t6,32(a4)
    65d8:	00672623          	sw	t1,12(a4)
    65dc:	00082683          	lw	a3,0(a6)
    65e0:	00062783          	lw	a5,0(a2)
    65e4:	00168693          	addi	a3,a3,1
    65e8:	00178793          	addi	a5,a5,1
    65ec:	00f62023          	sw	a5,0(a2)
    65f0:	00d82023          	sw	a3,0(a6)
    65f4:	00100793          	li	a5,1
    65f8:	04f72023          	sw	a5,64(a4)
    65fc:	0005a703          	lw	a4,0(a1)
    6600:	918e2783          	lw	a5,-1768(t3)
    6604:	00088513          	mv	a0,a7
    6608:	00e787b3          	add	a5,a5,a4
    660c:	90fe2c23          	sw	a5,-1768(t3)
    6610:	01010113          	addi	sp,sp,16
    6614:	00008067          	ret

00006618 <.L270>:
    6618:	fff6a737          	lui	a4,0xfff6a
    661c:	00812623          	sw	s0,12(sp)
    6620:	00e68733          	add	a4,a3,a4
    6624:	00004637          	lui	a2,0x4
    6628:	00052403          	lw	s0,0(a0) # 8000 <.L417+0x24>
    662c:	40d78eb3          	sub	t4,a5,a3
    6630:	18e67663          	bgeu	a2,a4,67bc <.L255>
    6634:	ffb20737          	lui	a4,0xffb20

00006638 <.L244>:
    6638:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    663c:	fe079ee3          	bnez	a5,6638 <.L244>
    6640:	00872023          	sw	s0,0(a4)
    6644:	00004f37          	lui	t5,0x4
    6648:	03e72023          	sw	t5,32(a4)
    664c:	ffb00837          	lui	a6,0xffb00
    6650:	ffb00637          	lui	a2,0xffb00
    6654:	00d72623          	sw	a3,12(a4)
    6658:	03480813          	addi	a6,a6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    665c:	02c60613          	addi	a2,a2,44 # ffb0002c <noc_nonposted_writes_acked>
    6660:	00082303          	lw	t1,0(a6)
    6664:	00062783          	lw	a5,0(a2)
    6668:	00130313          	addi	t1,t1,1
    666c:	00178793          	addi	a5,a5,1
    6670:	00682023          	sw	t1,0(a6)
    6674:	00f62023          	sw	a5,0(a2)
    6678:	00100393          	li	t2,1
    667c:	fff6e7b7          	lui	a5,0xfff6e
    6680:	04772023          	sw	t2,64(a4)
    6684:	00f687b3          	add	a5,a3,a5
    6688:	01e40333          	add	t1,s0,t5
    668c:	01e682b3          	add	t0,a3,t5
    6690:	14ff7c63          	bgeu	t5,a5,67e8 <.L274>
    6694:	00092737          	lui	a4,0x92
    6698:	fff70713          	addi	a4,a4,-1 # 91fff <__kernel_data_lma+0x8674b>
    669c:	40d70733          	sub	a4,a4,a3
    66a0:	ffffc7b7          	lui	a5,0xffffc
    66a4:	00912423          	sw	s1,8(sp)
    66a8:	00070493          	mv	s1,a4
    66ac:	00f77733          	and	a4,a4,a5
    66b0:	408787b3          	sub	a5,a5,s0
    66b4:	00578fb3          	add	t6,a5,t0
    66b8:	000082b7          	lui	t0,0x8
    66bc:	005402b3          	add	t0,s0,t0
    66c0:	00e282b3          	add	t0,t0,a4
    66c4:	ffb20737          	lui	a4,0xffb20

000066c8 <.L246>:
    66c8:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    66cc:	fe079ee3          	bnez	a5,66c8 <.L246>
    66d0:	00672023          	sw	t1,0(a4)
    66d4:	006f87b3          	add	a5,t6,t1
    66d8:	00f72623          	sw	a5,12(a4)
    66dc:	00082783          	lw	a5,0(a6)
    66e0:	01e30333          	add	t1,t1,t5
    66e4:	00178793          	addi	a5,a5,1 # ffffc001 <__instrn_buffer+0x1bc001>
    66e8:	00f82023          	sw	a5,0(a6)
    66ec:	00062783          	lw	a5,0(a2)
    66f0:	00178793          	addi	a5,a5,1
    66f4:	00f62023          	sw	a5,0(a2)
    66f8:	04772023          	sw	t2,64(a4)
    66fc:	fc5316e3          	bne	t1,t0,66c8 <.L246>
    6700:	00e4d713          	srli	a4,s1,0xe
    6704:	000927b7          	lui	a5,0x92
    6708:	000082b7          	lui	t0,0x8
    670c:	00e71f13          	slli	t5,a4,0xe
    6710:	40d787b3          	sub	a5,a5,a3
    6714:	005682b3          	add	t0,a3,t0
    6718:	00812483          	lw	s1,8(sp)
    671c:	00030413          	mv	s0,t1
    6720:	01e282b3          	add	t0,t0,t5
    6724:	41e78333          	sub	t1,a5,t5

00006728 <.L243>:
    6728:	ffb20737          	lui	a4,0xffb20

0000672c <.L248>:
    672c:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    6730:	fe079ee3          	bnez	a5,672c <.L248>
    6734:	00872023          	sw	s0,0(a4)
    6738:	02672023          	sw	t1,32(a4)
    673c:	00572623          	sw	t0,12(a4)
    6740:	00082303          	lw	t1,0(a6)
    6744:	00062783          	lw	a5,0(a2)
    6748:	00130313          	addi	t1,t1,1
    674c:	00178793          	addi	a5,a5,1 # 92001 <__kernel_data_lma+0x8674d>
    6750:	00682023          	sw	t1,0(a6)
    6754:	00f62023          	sw	a5,0(a2)
    6758:	00100793          	li	a5,1
    675c:	04f72023          	sw	a5,64(a4)
    6760:	0001a7b7          	lui	a5,0x1a
    6764:	90fe2c23          	sw	a5,-1768(t3)
    6768:	00052783          	lw	a5,0(a0)
    676c:	fff66737          	lui	a4,0xfff66
    6770:	01d787b3          	add	a5,a5,t4
    6774:	00f52023          	sw	a5,0(a0)
    6778:	0005af83          	lw	t6,0(a1)
    677c:	00c12403          	lw	s0,12(sp)
    6780:	00ef8fb3          	add	t6,t6,a4
    6784:	00df8fb3          	add	t6,t6,a3
    6788:	01f5a023          	sw	t6,0(a1)
    678c:	918e2283          	lw	t0,-1768(t3)
    6790:	00028313          	mv	t1,t0
    6794:	d49ff06f          	j	64dc <.L242>

00006798 <.L272>:
    6798:	0001a337          	lui	t1,0x1a
    679c:	906e2c23          	sw	t1,-1768(t3)
    67a0:	ffb00837          	lui	a6,0xffb00
    67a4:	ffb00637          	lui	a2,0xffb00
    67a8:	0005af83          	lw	t6,0(a1)
    67ac:	00030293          	mv	t0,t1
    67b0:	03480813          	addi	a6,a6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    67b4:	02c60613          	addi	a2,a2,44 # ffb0002c <noc_nonposted_writes_acked>
    67b8:	d25ff06f          	j	64dc <.L242>

000067bc <.L255>:
    67bc:	ffb00837          	lui	a6,0xffb00
    67c0:	ffb00637          	lui	a2,0xffb00
    67c4:	03480813          	addi	a6,a6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    67c8:	02c60613          	addi	a2,a2,44 # ffb0002c <noc_nonposted_writes_acked>
    67cc:	000e8313          	mv	t1,t4
    67d0:	f59ff06f          	j	6728 <.L243>

000067d4 <.L273>:
    67d4:	00c12403          	lw	s0,12(sp)
    67d8:	000f0313          	mv	t1,t5
    67dc:	00078f93          	mv	t6,a5
    67e0:	00068513          	mv	a0,a3
    67e4:	de1ff06f          	j	65c4 <.L249>

000067e8 <.L274>:
    67e8:	000967b7          	lui	a5,0x96
    67ec:	00030413          	mv	s0,t1
    67f0:	40d78333          	sub	t1,a5,a3
    67f4:	f35ff06f          	j	6728 <.L243>

000067f8 <_Z35process_relay_paged_packed_sub_cmdsmPm>:
    67f8:	ffb007b7          	lui	a5,0xffb00
    67fc:	f7010113          	addi	sp,sp,-144
    6800:	03478793          	addi	a5,a5,52 # ffb00034 <noc_nonposted_writes_num_issued>
    6804:	0007a703          	lw	a4,0(a5)
    6808:	00f12423          	sw	a5,8(sp)
    680c:	08112623          	sw	ra,140(sp)
    6810:	08812423          	sw	s0,136(sp)
    6814:	09212023          	sw	s2,128(sp)
    6818:	07312e23          	sw	s3,124(sp)
    681c:	07612823          	sw	s6,112(sp)
    6820:	07712623          	sw	s7,108(sp)
    6824:	07912223          	sw	s9,100(sp)
    6828:	00058893          	mv	a7,a1
    682c:	ffb207b7          	lui	a5,0xffb20

00006830 <.L276>:
    6830:	2287a683          	lw	a3,552(a5) # ffb20228 <__stack_top+0x1e228>
    6834:	fee69ee3          	bne	a3,a4,6830 <.L276>
    6838:	0ff0000f          	fence
    683c:	0088a683          	lw	a3,8(a7)
    6840:	00010b37          	lui	s6,0x10
    6844:	00050b93          	mv	s7,a0
    6848:	0b6557b3          	minu	a5,a0,s6
    684c:	00000993          	li	s3,0
    6850:	70d7e863          	bltu	a5,a3,6f60 <.L303>
    6854:	ffb00737          	lui	a4,0xffb00
    6858:	ffb00837          	lui	a6,0xffb00
    685c:	ffb005b7          	lui	a1,0xffb00
    6860:	03c70c93          	addi	s9,a4,60 # ffb0003c <noc_reads_num_issued>
    6864:	64480713          	addi	a4,a6,1604 # ffb00644 <bank_to_dram_offset>
    6868:	92492637          	lui	a2,0x92492
    686c:	00e12623          	sw	a4,12(sp)
    6870:	44858713          	addi	a4,a1,1096 # ffb00448 <dram_bank_to_noc_xy>
    6874:	0005a937          	lui	s2,0x5a
    6878:	10000fb7          	lui	t6,0x10000
    687c:	010003b7          	lui	t2,0x1000
    6880:	00e12823          	sw	a4,16(sp)
    6884:	49360713          	addi	a4,a2,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    6888:	07812423          	sw	s8,104(sp)
    688c:	00e12a23          	sw	a4,20(sp)
    6890:	08912223          	sw	s1,132(sp)
    6894:	07412c23          	sw	s4,120(sp)
    6898:	07512a23          	sw	s5,116(sp)
    689c:	07a12023          	sw	s10,96(sp)
    68a0:	05b12e23          	sw	s11,92(sp)
    68a4:	ffffcc37          	lui	s8,0xffffc
    68a8:	44090913          	addi	s2,s2,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    68ac:	00ff8f93          	addi	t6,t6,15 # 1000000f <__kernel_data_lma+0xfff475b>
    68b0:	fff38393          	addi	t2,t2,-1 # ffffff <__kernel_data_lma+0xff474b>
    68b4:	00000f13          	li	t5,0
    68b8:	00100293          	li	t0,1
    68bc:	00004337          	lui	t1,0x4
    68c0:	ffb21737          	lui	a4,0xffb21

000068c4 <.L284>:
    68c4:	41eb0633          	sub	a2,s6,t5
    68c8:	00c88893          	addi	a7,a7,12
    68cc:	0ad65a33          	minu	s4,a2,a3
    68d0:	160a0263          	beqz	s4,6a34 <.L278>
    68d4:	ff68d683          	lhu	a3,-10(a7)
    68d8:	00600613          	li	a2,6
    68dc:	ff48db83          	lhu	s7,-12(a7)
    68e0:	ff88ad83          	lw	s11,-8(a7)
    68e4:	00d29d33          	sll	s10,t0,a3
    68e8:	0ac6f6b3          	maxu	a3,a3,a2
    68ec:	00000a93          	li	s5,0
    68f0:	00d12223          	sw	a3,4(sp)

000068f4 <.L283>:
    68f4:	01412683          	lw	a3,20(sp)
    68f8:	00412583          	lw	a1,4(sp)
    68fc:	02dbb6b3          	mulhu	a3,s7,a3
    6900:	415a0433          	sub	s0,s4,s5
    6904:	0026d693          	srli	a3,a3,0x2
    6908:	0ba45433          	minu	s0,s0,s10
    690c:	00369613          	slli	a2,a3,0x3
    6910:	00b69e33          	sll	t3,a3,a1
    6914:	40d60633          	sub	a2,a2,a3
    6918:	01012583          	lw	a1,16(sp)
    691c:	00c12683          	lw	a3,12(sp)
    6920:	40cb8633          	sub	a2,s7,a2
    6924:	20d646b3          	sh2add	a3,a2,a3
    6928:	20b62633          	sh1add	a2,a2,a1
    692c:	0006a683          	lw	a3,0(a3)
    6930:	00065483          	lhu	s1,0(a2)
    6934:	01be0e33          	add	t3,t3,s11
    6938:	00de0e33          	add	t3,t3,a3
    693c:	00449493          	slli	s1,s1,0x4
    6940:	000e0613          	mv	a2,t3
    6944:	00048593          	mv	a1,s1
    6948:	50837a63          	bgeu	t1,s0,6e5c <.L304>
    694c:	ffffc6b7          	lui	a3,0xffffc
    6950:	fff68693          	addi	a3,a3,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    6954:	00d409b3          	add	s3,s0,a3
    6958:	0189feb3          	and	t4,s3,s8
    695c:	006906b3          	add	a3,s2,t1
    6960:	00de8eb3          	add	t4,t4,a3
    6964:	00048813          	mv	a6,s1
    6968:	00090593          	mv	a1,s2

0000696c <.L280>:
    696c:	84072683          	lw	a3,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    6970:	fe069ee3          	bnez	a3,696c <.L280>
    6974:	80b72623          	sw	a1,-2036(a4)
    6978:	80c72023          	sw	a2,-2048(a4)
    697c:	01f876b3          	and	a3,a6,t6
    6980:	80d72223          	sw	a3,-2044(a4)
    6984:	00485693          	srli	a3,a6,0x4
    6988:	0076f6b3          	and	a3,a3,t2
    698c:	80d72423          	sw	a3,-2040(a4)
    6990:	82672023          	sw	t1,-2016(a4)
    6994:	84572023          	sw	t0,-1984(a4)
    6998:	000ca683          	lw	a3,0(s9)
    699c:	006585b3          	add	a1,a1,t1
    69a0:	00168693          	addi	a3,a3,1
    69a4:	00dca023          	sw	a3,0(s9)
    69a8:	006606b3          	add	a3,a2,t1
    69ac:	00c6b633          	sltu	a2,a3,a2
    69b0:	01060833          	add	a6,a2,a6
    69b4:	00068613          	mv	a2,a3
    69b8:	fbd59ae3          	bne	a1,t4,696c <.L280>
    69bc:	00e9d993          	srli	s3,s3,0xe
    69c0:	00198693          	addi	a3,s3,1 # ffffc001 <__instrn_buffer+0x1bc001>
    69c4:	00e69613          	slli	a2,a3,0xe
    69c8:	00ce0633          	add	a2,t3,a2
    69cc:	0126d693          	srli	a3,a3,0x12
    69d0:	00e99993          	slli	s3,s3,0xe
    69d4:	40640833          	sub	a6,s0,t1
    69d8:	01c63e33          	sltu	t3,a2,t3
    69dc:	00d484b3          	add	s1,s1,a3
    69e0:	41380833          	sub	a6,a6,s3
    69e4:	009e05b3          	add	a1,t3,s1

000069e8 <.L282>:
    69e8:	84072683          	lw	a3,-1984(a4)
    69ec:	fe069ee3          	bnez	a3,69e8 <.L282>
    69f0:	81d72623          	sw	t4,-2036(a4)
    69f4:	80c72023          	sw	a2,-2048(a4)
    69f8:	01f5f6b3          	and	a3,a1,t6
    69fc:	80d72223          	sw	a3,-2044(a4)
    6a00:	0045d593          	srli	a1,a1,0x4
    6a04:	80b72423          	sw	a1,-2040(a4)
    6a08:	83072023          	sw	a6,-2016(a4)
    6a0c:	84572023          	sw	t0,-1984(a4)
    6a10:	000ca683          	lw	a3,0(s9)
    6a14:	008a8ab3          	add	s5,s5,s0
    6a18:	00168693          	addi	a3,a3,1
    6a1c:	00dca023          	sw	a3,0(s9)
    6a20:	00890933          	add	s2,s2,s0
    6a24:	001b8b93          	addi	s7,s7,1
    6a28:	ed4ae6e3          	bltu	s5,s4,68f4 <.L283>
    6a2c:	015f0f33          	add	t5,t5,s5
    6a30:	415787b3          	sub	a5,a5,s5

00006a34 <.L278>:
    6a34:	0088a683          	lw	a3,8(a7)
    6a38:	e8d7f6e3          	bgeu	a5,a3,68c4 <.L284>
    6a3c:	41e507b3          	sub	a5,a0,t5
    6a40:	00f53533          	sltu	a0,a0,a5
    6a44:	08412483          	lw	s1,132(sp)
    6a48:	07812a03          	lw	s4,120(sp)
    6a4c:	07412a83          	lw	s5,116(sp)
    6a50:	06812c03          	lw	s8,104(sp)
    6a54:	06012d03          	lw	s10,96(sp)
    6a58:	05c12d83          	lw	s11,92(sp)
    6a5c:	40a009b3          	neg	s3,a0
    6a60:	00078b93          	mv	s7,a5

00006a64 <.L277>:
    6a64:	000ca703          	lw	a4,0(s9)
    6a68:	ffb207b7          	lui	a5,0xffb20

00006a6c <.L285>:
    6a6c:	2087a603          	lw	a2,520(a5) # ffb20208 <__stack_top+0x1e208>
    6a70:	fee61ee3          	bne	a2,a4,6a6c <.L285>
    6a74:	0ff0000f          	fence
    6a78:	013be433          	or	s0,s7,s3
    6a7c:	4e040a63          	beqz	s0,6f70 <.L305>
    6a80:	ffb015b7          	lui	a1,0xffb01
    6a84:	100007b7          	lui	a5,0x10000
    6a88:	90058593          	addi	a1,a1,-1792 # ffb00900 <_ZL14scratch_db_top>
    6a8c:	05b12e23          	sw	s11,92(sp)
    6a90:	ffb01737          	lui	a4,0xffb01
    6a94:	ffb00637          	lui	a2,0xffb00
    6a98:	ffffcdb7          	lui	s11,0xffffc
    6a9c:	07812423          	sw	s8,104(sp)
    6aa0:	07a12023          	sw	s10,96(sp)
    6aa4:	00b12223          	sw	a1,4(sp)
    6aa8:	00f78d13          	addi	s10,a5,15 # 1000000f <__kernel_data_lma+0xfff475b>
    6aac:	08912223          	sw	s1,132(sp)
    6ab0:	07412c23          	sw	s4,120(sp)
    6ab4:	07512a23          	sw	s5,116(sp)
    6ab8:	86c70713          	addi	a4,a4,-1940 # ffb0086c <sem_l1_base>
    6abc:	02460913          	addi	s2,a2,36 # ffb00024 <noc_nonposted_atomics_acked>
    6ac0:	fffd8c13          	addi	s8,s11,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    6ac4:	00000793          	li	a5,0
    6ac8:	04810593          	addi	a1,sp,72
    6acc:	04c10813          	addi	a6,sp,76
    6ad0:	000b8b13          	mv	s6,s7

00006ad4 <.L301>:
    6ad4:	00812603          	lw	a2,8(sp)
    6ad8:	00062503          	lw	a0,0(a2)
    6adc:	ffb20637          	lui	a2,0xffb20

00006ae0 <.L288>:
    6ae0:	22862303          	lw	t1,552(a2) # ffb20228 <__stack_top+0x1e228>
    6ae4:	fea31ee3          	bne	t1,a0,6ae0 <.L288>
    6ae8:	0ff0000f          	fence
    6aec:	00412603          	lw	a2,4(sp)
    6af0:	0017c493          	xori	s1,a5,1
    6af4:	20c7c633          	sh2add	a2,a5,a2
    6af8:	000b0793          	mv	a5,s6
    6afc:	00062283          	lw	t0,0(a2)
    6b00:	36099463          	bnez	s3,6e68 <.L290>
    6b04:	00010637          	lui	a2,0x10
    6b08:	37666063          	bltu	a2,s6,6e68 <.L290>

00006b0c <.L289>:
    6b0c:	00078613          	mv	a2,a5
    6b10:	00000f93          	li	t6,0
    6b14:	28d7e463          	bltu	a5,a3,6d9c <.L291>
    6b18:	00412783          	lw	a5,4(sp)
    6b1c:	ffb00ab7          	lui	s5,0xffb00
    6b20:	20f4c7b3          	sh2add	a5,s1,a5
    6b24:	ffb00a37          	lui	s4,0xffb00
    6b28:	0007a403          	lw	s0,0(a5)
    6b2c:	01000eb7          	lui	t4,0x1000
    6b30:	924927b7          	lui	a5,0x92492
    6b34:	49378b93          	addi	s7,a5,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    6b38:	00912623          	sw	s1,12(sp)
    6b3c:	644a8a93          	addi	s5,s5,1604 # ffb00644 <bank_to_dram_offset>
    6b40:	448a0a13          	addi	s4,s4,1096 # ffb00448 <dram_bank_to_noc_xy>
    6b44:	fffe8e93          	addi	t4,t4,-1 # ffffff <__kernel_data_lma+0xff474b>
    6b48:	00100e13          	li	t3,1
    6b4c:	00004537          	lui	a0,0x4
    6b50:	ffb217b7          	lui	a5,0xffb21
    6b54:	00512823          	sw	t0,16(sp)
    6b58:	00068493          	mv	s1,a3
    6b5c:	01e12a23          	sw	t5,20(sp)
    6b60:	01612c23          	sw	s6,24(sp)
    6b64:	01312e23          	sw	s3,28(sp)
    6b68:	03212023          	sw	s2,32(sp)
    6b6c:	02e12223          	sw	a4,36(sp)
    6b70:	02b12423          	sw	a1,40(sp)

00006b74 <.L298>:
    6b74:	00010737          	lui	a4,0x10
    6b78:	41f70733          	sub	a4,a4,t6
    6b7c:	0a9754b3          	minu	s1,a4,s1
    6b80:	00088713          	mv	a4,a7
    6b84:	00c88893          	addi	a7,a7,12
    6b88:	1a048863          	beqz	s1,6d38 <.L292>
    6b8c:	00574383          	lbu	t2,5(a4) # 10005 <__kernel_data_lma+0x4751>
    6b90:	00474283          	lbu	t0,4(a4)
    6b94:	00674903          	lbu	s2,6(a4)
    6b98:	00839393          	slli	t2,t2,0x8
    6b9c:	00374983          	lbu	s3,3(a4)
    6ba0:	0053e3b3          	or	t2,t2,t0
    6ba4:	01091293          	slli	t0,s2,0x10
    6ba8:	0072e2b3          	or	t0,t0,t2
    6bac:	00274383          	lbu	t2,2(a4)
    6bb0:	00899913          	slli	s2,s3,0x8
    6bb4:	00174683          	lbu	a3,1(a4)
    6bb8:	00796933          	or	s2,s2,t2
    6bbc:	00074383          	lbu	t2,0(a4)
    6bc0:	00774b03          	lbu	s6,7(a4)
    6bc4:	02c12623          	sw	a2,44(sp)
    6bc8:	018b1993          	slli	s3,s6,0x18
    6bcc:	0059e9b3          	or	s3,s3,t0
    6bd0:	00600293          	li	t0,6
    6bd4:	012e1b33          	sll	s6,t3,s2
    6bd8:	0a597933          	maxu	s2,s2,t0
    6bdc:	02e12823          	sw	a4,48(sp)
    6be0:	00000293          	li	t0,0
    6be4:	03f12a23          	sw	t6,52(sp)
    6be8:	00869693          	slli	a3,a3,0x8
    6bec:	03112c23          	sw	a7,56(sp)
    6bf0:	0076e3b3          	or	t2,a3,t2
    6bf4:	03012e23          	sw	a6,60(sp)

00006bf8 <.L297>:
    6bf8:	0373b733          	mulhu	a4,t2,s7
    6bfc:	40548333          	sub	t1,s1,t0
    6c00:	00275713          	srli	a4,a4,0x2
    6c04:	0b635333          	minu	t1,t1,s6
    6c08:	00371613          	slli	a2,a4,0x3
    6c0c:	40e60633          	sub	a2,a2,a4
    6c10:	40c38633          	sub	a2,t2,a2
    6c14:	215646b3          	sh2add	a3,a2,s5
    6c18:	01271733          	sll	a4,a4,s2
    6c1c:	21462633          	sh1add	a2,a2,s4
    6c20:	0006a683          	lw	a3,0(a3)
    6c24:	00065f83          	lhu	t6,0(a2) # 10000 <__kernel_data_lma+0x474c>
    6c28:	01370733          	add	a4,a4,s3
    6c2c:	00d70833          	add	a6,a4,a3
    6c30:	004f9f93          	slli	t6,t6,0x4
    6c34:	00080693          	mv	a3,a6
    6c38:	000f8713          	mv	a4,t6
    6c3c:	22657a63          	bgeu	a0,t1,6e70 <.L307>
    6c40:	01830f33          	add	t5,t1,s8
    6c44:	00a40733          	add	a4,s0,a0
    6c48:	01bf78b3          	and	a7,t5,s11
    6c4c:	00e888b3          	add	a7,a7,a4
    6c50:	000f8613          	mv	a2,t6
    6c54:	00080713          	mv	a4,a6
    6c58:	00040693          	mv	a3,s0

00006c5c <.L294>:
    6c5c:	8407a583          	lw	a1,-1984(a5) # ffb20840 <__stack_top+0x1e840>
    6c60:	fe059ee3          	bnez	a1,6c5c <.L294>
    6c64:	80d7a623          	sw	a3,-2036(a5)
    6c68:	80e7a023          	sw	a4,-2048(a5)
    6c6c:	01a675b3          	and	a1,a2,s10
    6c70:	80b7a223          	sw	a1,-2044(a5)
    6c74:	00465593          	srli	a1,a2,0x4
    6c78:	01d5f5b3          	and	a1,a1,t4
    6c7c:	80b7a423          	sw	a1,-2040(a5)
    6c80:	82a7a023          	sw	a0,-2016(a5)
    6c84:	85c7a023          	sw	t3,-1984(a5)
    6c88:	000ca583          	lw	a1,0(s9)
    6c8c:	00a686b3          	add	a3,a3,a0
    6c90:	00158593          	addi	a1,a1,1
    6c94:	00bca023          	sw	a1,0(s9)
    6c98:	00a705b3          	add	a1,a4,a0
    6c9c:	00e5b733          	sltu	a4,a1,a4
    6ca0:	00c70633          	add	a2,a4,a2
    6ca4:	00058713          	mv	a4,a1
    6ca8:	fb169ae3          	bne	a3,a7,6c5c <.L294>
    6cac:	00ef5693          	srli	a3,t5,0xe
    6cb0:	00168713          	addi	a4,a3,1
    6cb4:	40a30633          	sub	a2,t1,a0
    6cb8:	00e69693          	slli	a3,a3,0xe
    6cbc:	40d60633          	sub	a2,a2,a3
    6cc0:	00e71693          	slli	a3,a4,0xe
    6cc4:	00d806b3          	add	a3,a6,a3
    6cc8:	01275713          	srli	a4,a4,0x12
    6ccc:	0106b833          	sltu	a6,a3,a6
    6cd0:	00ef8733          	add	a4,t6,a4
    6cd4:	00e80733          	add	a4,a6,a4

00006cd8 <.L296>:
    6cd8:	8407a583          	lw	a1,-1984(a5)
    6cdc:	fe059ee3          	bnez	a1,6cd8 <.L296>
    6ce0:	8117a623          	sw	a7,-2036(a5)
    6ce4:	80d7a023          	sw	a3,-2048(a5)
    6ce8:	01a776b3          	and	a3,a4,s10
    6cec:	80d7a223          	sw	a3,-2044(a5)
    6cf0:	00475713          	srli	a4,a4,0x4
    6cf4:	80e7a423          	sw	a4,-2040(a5)
    6cf8:	82c7a023          	sw	a2,-2016(a5)
    6cfc:	85c7a023          	sw	t3,-1984(a5)
    6d00:	000ca703          	lw	a4,0(s9)
    6d04:	006282b3          	add	t0,t0,t1
    6d08:	00170713          	addi	a4,a4,1
    6d0c:	00eca023          	sw	a4,0(s9)
    6d10:	00640433          	add	s0,s0,t1
    6d14:	00138393          	addi	t2,t2,1
    6d18:	ee92e0e3          	bltu	t0,s1,6bf8 <.L297>
    6d1c:	02c12603          	lw	a2,44(sp)
    6d20:	03412f83          	lw	t6,52(sp)
    6d24:	03012703          	lw	a4,48(sp)
    6d28:	03812883          	lw	a7,56(sp)
    6d2c:	03c12803          	lw	a6,60(sp)
    6d30:	005f8fb3          	add	t6,t6,t0
    6d34:	40560633          	sub	a2,a2,t0

00006d38 <.L292>:
    6d38:	01574383          	lbu	t2,21(a4)
    6d3c:	01474283          	lbu	t0,20(a4)
    6d40:	00839393          	slli	t2,t2,0x8
    6d44:	0053e3b3          	or	t2,t2,t0
    6d48:	01674283          	lbu	t0,22(a4)
    6d4c:	01774483          	lbu	s1,23(a4)
    6d50:	01029713          	slli	a4,t0,0x10
    6d54:	00776733          	or	a4,a4,t2
    6d58:	01849493          	slli	s1,s1,0x18
    6d5c:	00e4e4b3          	or	s1,s1,a4
    6d60:	e0967ae3          	bgeu	a2,s1,6b74 <.L298>
    6d64:	01812b03          	lw	s6,24(sp)
    6d68:	01c12983          	lw	s3,28(sp)
    6d6c:	41fb07b3          	sub	a5,s6,t6
    6d70:	00fb3633          	sltu	a2,s6,a5
    6d74:	00048693          	mv	a3,s1
    6d78:	40c989b3          	sub	s3,s3,a2
    6d7c:	01012283          	lw	t0,16(sp)
    6d80:	00c12483          	lw	s1,12(sp)
    6d84:	01412f03          	lw	t5,20(sp)
    6d88:	02012903          	lw	s2,32(sp)
    6d8c:	02412703          	lw	a4,36(sp)
    6d90:	02812583          	lw	a1,40(sp)
    6d94:	00078b13          	mv	s6,a5
    6d98:	0137e433          	or	s0,a5,s3

00006d9c <.L291>:
    6d9c:	00080513          	mv	a0,a6
    6da0:	03f12023          	sw	t6,32(sp)
    6da4:	00e12e23          	sw	a4,28(sp)
    6da8:	01112c23          	sw	a7,24(sp)
    6dac:	00d12a23          	sw	a3,20(sp)
    6db0:	00b12823          	sw	a1,16(sp)
    6db4:	01012623          	sw	a6,12(sp)
    6db8:	04512623          	sw	t0,76(sp)
    6dbc:	05e12423          	sw	t5,72(sp)
    6dc0:	d65fe0ef          	jal	5b24 <_Z25write_pages_to_dispatcherILl0ELb0EEmRmS0_S0_.constprop.0>
    6dc4:	01c12703          	lw	a4,28(sp)
    6dc8:	01412683          	lw	a3,20(sp)
    6dcc:	00072603          	lw	a2,0(a4)
    6dd0:	02012f83          	lw	t6,32(sp)
    6dd4:	01812883          	lw	a7,24(sp)
    6dd8:	01012583          	lw	a1,16(sp)
    6ddc:	00c12803          	lw	a6,12(sp)
    6de0:	ffb227b7          	lui	a5,0xffb22

00006de4 <.L299>:
    6de4:	8407a303          	lw	t1,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    6de8:	fe031ee3          	bnez	t1,6de4 <.L299>
    6dec:	80c7a023          	sw	a2,-2048(a5)
    6df0:	8007a223          	sw	zero,-2044(a5)
    6df4:	00265613          	srli	a2,a2,0x2
    6df8:	00001e37          	lui	t3,0x1
    6dfc:	0ce00e93          	li	t4,206
    6e00:	00002337          	lui	t1,0x2
    6e04:	81d7a423          	sw	t4,-2040(a5)
    6e08:	00367613          	andi	a2,a2,3
    6e0c:	07ce0e13          	addi	t3,t3,124 # 107c <_start-0x3954>
    6e10:	09130313          	addi	t1,t1,145 # 2091 <_start-0x293f>
    6e14:	8067ae23          	sw	t1,-2020(a5)
    6e18:	01c66633          	or	a2,a2,t3
    6e1c:	82c7a023          	sw	a2,-2016(a5)
    6e20:	82a7a423          	sw	a0,-2008(a5)
    6e24:	00100613          	li	a2,1
    6e28:	84c7a023          	sw	a2,-1984(a5)
    6e2c:	00092783          	lw	a5,0(s2)
    6e30:	000ca603          	lw	a2,0(s9)
    6e34:	00178793          	addi	a5,a5,1
    6e38:	00f92023          	sw	a5,0(s2)
    6e3c:	ffb207b7          	lui	a5,0xffb20

00006e40 <.L300>:
    6e40:	2087a503          	lw	a0,520(a5) # ffb20208 <__stack_top+0x1e208>
    6e44:	fec51ee3          	bne	a0,a2,6e40 <.L300>
    6e48:	0ff0000f          	fence
    6e4c:	02040863          	beqz	s0,6e7c <.L332>
    6e50:	000f8f13          	mv	t5,t6
    6e54:	00048793          	mv	a5,s1
    6e58:	c7dff06f          	j	6ad4 <.L301>

00006e5c <.L304>:
    6e5c:	00040813          	mv	a6,s0
    6e60:	00090e93          	mv	t4,s2
    6e64:	b85ff06f          	j	69e8 <.L282>

00006e68 <.L290>:
    6e68:	000107b7          	lui	a5,0x10
    6e6c:	ca1ff06f          	j	6b0c <.L289>

00006e70 <.L307>:
    6e70:	00030613          	mv	a2,t1
    6e74:	00040893          	mv	a7,s0
    6e78:	e61ff06f          	j	6cd8 <.L296>

00006e7c <.L332>:
    6e7c:	00412783          	lw	a5,4(sp)
    6e80:	07812a03          	lw	s4,120(sp)
    6e84:	20f4c4b3          	sh2add	s1,s1,a5
    6e88:	07412a83          	lw	s5,116(sp)
    6e8c:	0004a783          	lw	a5,0(s1)
    6e90:	06812c03          	lw	s8,104(sp)
    6e94:	08412483          	lw	s1,132(sp)
    6e98:	06012d03          	lw	s10,96(sp)
    6e9c:	05c12d83          	lw	s11,92(sp)
    6ea0:	000f8f13          	mv	t5,t6

00006ea4 <.L286>:
    6ea4:	00080513          	mv	a0,a6
    6ea8:	00e12223          	sw	a4,4(sp)
    6eac:	04f12623          	sw	a5,76(sp)
    6eb0:	05e12423          	sw	t5,72(sp)
    6eb4:	d8cff0ef          	jal	6440 <_Z25write_pages_to_dispatcherILl1ELb1EEmRmS0_S0_.constprop.0>
    6eb8:	ffb01637          	lui	a2,0xffb01
    6ebc:	91862783          	lw	a5,-1768(a2) # ffb00918 <_ZL19downstream_data_ptr>
    6ec0:	000016b7          	lui	a3,0x1
    6ec4:	fff68693          	addi	a3,a3,-1 # fff <_start-0x39d1>
    6ec8:	00d787b3          	add	a5,a5,a3
    6ecc:	00412703          	lw	a4,4(sp)
    6ed0:	fffff6b7          	lui	a3,0xfffff
    6ed4:	00d7f7b3          	and	a5,a5,a3
    6ed8:	00072703          	lw	a4,0(a4)
    6edc:	00150693          	addi	a3,a0,1 # 4001 <_start-0x9cf>
    6ee0:	90f62c23          	sw	a5,-1768(a2)
    6ee4:	ffb227b7          	lui	a5,0xffb22

00006ee8 <.L302>:
    6ee8:	8407a603          	lw	a2,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    6eec:	fe061ee3          	bnez	a2,6ee8 <.L302>
    6ef0:	80e7a023          	sw	a4,-2048(a5)
    6ef4:	8007a223          	sw	zero,-2044(a5)
    6ef8:	00275713          	srli	a4,a4,0x2
    6efc:	000015b7          	lui	a1,0x1
    6f00:	0ce00513          	li	a0,206
    6f04:	00002637          	lui	a2,0x2
    6f08:	80a7a423          	sw	a0,-2040(a5)
    6f0c:	00377713          	andi	a4,a4,3
    6f10:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    6f14:	09160613          	addi	a2,a2,145 # 2091 <_start-0x293f>
    6f18:	80c7ae23          	sw	a2,-2020(a5)
    6f1c:	00b76733          	or	a4,a4,a1
    6f20:	82e7a023          	sw	a4,-2016(a5)
    6f24:	82d7a423          	sw	a3,-2008(a5)
    6f28:	00100713          	li	a4,1
    6f2c:	84e7a023          	sw	a4,-1984(a5)
    6f30:	00092783          	lw	a5,0(s2)
    6f34:	08c12083          	lw	ra,140(sp)
    6f38:	08812403          	lw	s0,136(sp)
    6f3c:	00e787b3          	add	a5,a5,a4
    6f40:	00f92023          	sw	a5,0(s2)
    6f44:	07c12983          	lw	s3,124(sp)
    6f48:	08012903          	lw	s2,128(sp)
    6f4c:	07012b03          	lw	s6,112(sp)
    6f50:	06c12b83          	lw	s7,108(sp)
    6f54:	06412c83          	lw	s9,100(sp)
    6f58:	09010113          	addi	sp,sp,144
    6f5c:	00008067          	ret

00006f60 <.L303>:
    6f60:	ffb00737          	lui	a4,0xffb00
    6f64:	03c70c93          	addi	s9,a4,60 # ffb0003c <noc_reads_num_issued>
    6f68:	00000f13          	li	t5,0
    6f6c:	af9ff06f          	j	6a64 <.L277>

00006f70 <.L305>:
    6f70:	0005a7b7          	lui	a5,0x5a
    6f74:	ffb01737          	lui	a4,0xffb01
    6f78:	ffb00637          	lui	a2,0xffb00
    6f7c:	44078793          	addi	a5,a5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    6f80:	86c70713          	addi	a4,a4,-1940 # ffb0086c <sem_l1_base>
    6f84:	02460913          	addi	s2,a2,36 # ffb00024 <noc_nonposted_atomics_acked>
    6f88:	04810593          	addi	a1,sp,72
    6f8c:	04c10813          	addi	a6,sp,76
    6f90:	f15ff06f          	j	6ea4 <.L286>

00006f94 <_Z24process_relay_linear_cmdmRm.constprop.0.isra.0>:
    6f94:	f8010113          	addi	sp,sp,-128
    6f98:	07612023          	sw	s6,96(sp)
    6f9c:	ffb00b37          	lui	s6,0xffb00
    6fa0:	034b0793          	addi	a5,s6,52 # ffb00034 <noc_nonposted_writes_num_issued>
    6fa4:	0007a683          	lw	a3,0(a5)
    6fa8:	06112e23          	sw	ra,124(sp)
    6fac:	06812c23          	sw	s0,120(sp)
    6fb0:	06912a23          	sw	s1,116(sp)
    6fb4:	07212823          	sw	s2,112(sp)
    6fb8:	07312623          	sw	s3,108(sp)
    6fbc:	07412423          	sw	s4,104(sp)
    6fc0:	07512223          	sw	s5,100(sp)
    6fc4:	05712e23          	sw	s7,92(sp)
    6fc8:	05812c23          	sw	s8,88(sp)
    6fcc:	05b12623          	sw	s11,76(sp)
    6fd0:	02f12023          	sw	a5,32(sp)
    6fd4:	ffb20737          	lui	a4,0xffb20

00006fd8 <.L334>:
    6fd8:	22872783          	lw	a5,552(a4) # ffb20228 <__stack_top+0x1e228>
    6fdc:	fed79ee3          	bne	a5,a3,6fd8 <.L334>
    6fe0:	0ff0000f          	fence
    6fe4:	00b54e83          	lbu	t4,11(a0)
    6fe8:	00c54583          	lbu	a1,12(a0)
    6fec:	00d54303          	lbu	t1,13(a0)
    6ff0:	00e54803          	lbu	a6,14(a0)
    6ff4:	00f54603          	lbu	a2,15(a0)
    6ff8:	01054683          	lbu	a3,16(a0)
    6ffc:	01154883          	lbu	a7,17(a0)
    7000:	01254f83          	lbu	t6,18(a0)
    7004:	01354703          	lbu	a4,19(a0)
    7008:	01454783          	lbu	a5,20(a0)
    700c:	00869693          	slli	a3,a3,0x8
    7010:	01554e03          	lbu	t3,21(a0)
    7014:	00c6e6b3          	or	a3,a3,a2
    7018:	01654903          	lbu	s2,22(a0)
    701c:	00859593          	slli	a1,a1,0x8
    7020:	00354f03          	lbu	t5,3(a0)
    7024:	00879793          	slli	a5,a5,0x8
    7028:	00454603          	lbu	a2,4(a0)
    702c:	01d5e5b3          	or	a1,a1,t4
    7030:	00e7e7b3          	or	a5,a5,a4
    7034:	00554703          	lbu	a4,5(a0)
    7038:	00654403          	lbu	s0,6(a0)
    703c:	00754e83          	lbu	t4,7(a0)
    7040:	01089893          	slli	a7,a7,0x10
    7044:	00d8e8b3          	or	a7,a7,a3
    7048:	010e1e13          	slli	t3,t3,0x10
    704c:	00854683          	lbu	a3,8(a0)
    7050:	00fe6e33          	or	t3,t3,a5
    7054:	00954783          	lbu	a5,9(a0)
    7058:	00861613          	slli	a2,a2,0x8
    705c:	00a54483          	lbu	s1,10(a0)
    7060:	00869693          	slli	a3,a3,0x8
    7064:	01e66633          	or	a2,a2,t5
    7068:	01071713          	slli	a4,a4,0x10
    706c:	01079793          	slli	a5,a5,0x10
    7070:	01d6e6b3          	or	a3,a3,t4
    7074:	01031313          	slli	t1,t1,0x10
    7078:	00c76733          	or	a4,a4,a2
    707c:	01841413          	slli	s0,s0,0x18
    7080:	00d7e7b3          	or	a5,a5,a3
    7084:	01849493          	slli	s1,s1,0x18
    7088:	00b36333          	or	t1,t1,a1
    708c:	01881813          	slli	a6,a6,0x18
    7090:	018f9593          	slli	a1,t6,0x18
    7094:	01891913          	slli	s2,s2,0x18
    7098:	00e46433          	or	s0,s0,a4
    709c:	00f4e4b3          	or	s1,s1,a5
    70a0:	00686533          	or	a0,a6,t1
    70a4:	0115ec33          	or	s8,a1,a7
    70a8:	01c96933          	or	s2,s2,t3
    70ac:	00040b93          	mv	s7,s0
    70b0:	00048a13          	mv	s4,s1
    70b4:	1e049863          	bnez	s1,72a4 <.L336>
    70b8:	000107b7          	lui	a5,0x10
    70bc:	1e87e463          	bltu	a5,s0,72a4 <.L336>

000070c0 <.L335>:
    70c0:	0005a6b7          	lui	a3,0x5a
    70c4:	44068693          	addi	a3,a3,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    70c8:	000b8713          	mv	a4,s7
    70cc:	000c0593          	mv	a1,s8
    70d0:	00090613          	mv	a2,s2
    70d4:	b38fe0ef          	jal	540c <_Z22noc_read_64bit_any_lenILb1EEvmymm>
    70d8:	ffb00ab7          	lui	s5,0xffb00
    70dc:	03ca8793          	addi	a5,s5,60 # ffb0003c <noc_reads_num_issued>
    70e0:	0007a503          	lw	a0,0(a5) # 10000 <__kernel_data_lma+0x474c>
    70e4:	000b8993          	mv	s3,s7
    70e8:	00f12e23          	sw	a5,28(sp)
    70ec:	ffb206b7          	lui	a3,0xffb20

000070f0 <.L337>:
    70f0:	2086a783          	lw	a5,520(a3) # ffb20208 <__stack_top+0x1e208>
    70f4:	fea79ee3          	bne	a5,a0,70f0 <.L337>
    70f8:	0ff0000f          	fence
    70fc:	41740333          	sub	t1,s0,s7
    7100:	414488b3          	sub	a7,s1,s4
    7104:	00643433          	sltu	s0,s0,t1
    7108:	40888b33          	sub	s6,a7,s0
    710c:	016367b3          	or	a5,t1,s6
    7110:	28078063          	beqz	a5,7390 <.L347>
    7114:	017c04b3          	add	s1,s8,s7
    7118:	014907b3          	add	a5,s2,s4
    711c:	0184b933          	sltu	s2,s1,s8
    7120:	ffb01a37          	lui	s4,0xffb01
    7124:	00002c37          	lui	s8,0x2
    7128:	00f90933          	add	s2,s2,a5
    712c:	86ca0793          	addi	a5,s4,-1940 # ffb0086c <sem_l1_base>
    7130:	00001bb7          	lui	s7,0x1
    7134:	00f12a23          	sw	a5,20(sp)
    7138:	091c0793          	addi	a5,s8,145 # 2091 <_start-0x293f>
    713c:	02f12223          	sw	a5,36(sp)
    7140:	07cb8793          	addi	a5,s7,124 # 107c <_start-0x3954>
    7144:	ffb01f37          	lui	t5,0xffb01
    7148:	ffb00eb7          	lui	t4,0xffb00
    714c:	02f12423          	sw	a5,40(sp)
    7150:	03c10593          	addi	a1,sp,60
    7154:	03810793          	addi	a5,sp,56
    7158:	05912a23          	sw	s9,84(sp)
    715c:	05a12823          	sw	s10,80(sp)
    7160:	00098413          	mv	s0,s3
    7164:	900f0c93          	addi	s9,t5,-1792 # ffb00900 <_ZL14scratch_db_top>
    7168:	024e8d93          	addi	s11,t4,36 # ffb00024 <noc_nonposted_atomics_acked>
    716c:	00000e13          	li	t3,0
    7170:	00f12823          	sw	a5,16(sp)
    7174:	ffb20bb7          	lui	s7,0xffb20
    7178:	ffb22c37          	lui	s8,0xffb22
    717c:	00030d13          	mv	s10,t1
    7180:	000b0993          	mv	s3,s6
    7184:	00b12c23          	sw	a1,24(sp)

00007188 <.L345>:
    7188:	02012783          	lw	a5,32(sp)
    718c:	0007a703          	lw	a4,0(a5)

00007190 <.L340>:
    7190:	228ba783          	lw	a5,552(s7) # ffb20228 <__stack_top+0x1e228>
    7194:	fee79ee3          	bne	a5,a4,7190 <.L340>
    7198:	0ff0000f          	fence
    719c:	219e47b3          	sh2add	a5,t3,s9
    71a0:	001e4a13          	xori	s4,t3,1
    71a4:	0007a703          	lw	a4,0(a5)
    71a8:	000d0a93          	mv	s5,s10
    71ac:	00098b13          	mv	s6,s3
    71b0:	00099663          	bnez	s3,71bc <.L342>
    71b4:	000107b7          	lui	a5,0x10
    71b8:	01a7f663          	bgeu	a5,s10,71c4 <.L341>

000071bc <.L342>:
    71bc:	00010ab7          	lui	s5,0x10
    71c0:	00000b13          	li	s6,0

000071c4 <.L341>:
    71c4:	219a47b3          	sh2add	a5,s4,s9
    71c8:	0007a603          	lw	a2,0(a5) # 10000 <__kernel_data_lma+0x474c>
    71cc:	00048513          	mv	a0,s1
    71d0:	00090593          	mv	a1,s2
    71d4:	000a8693          	mv	a3,s5
    71d8:	00e12623          	sw	a4,12(sp)
    71dc:	03512623          	sw	s5,44(sp)
    71e0:	b24fe0ef          	jal	5504 <_Z22noc_read_64bit_any_lenILb0EEvmymm.isra.0>
    71e4:	015487b3          	add	a5,s1,s5
    71e8:	00c12703          	lw	a4,12(sp)
    71ec:	01812583          	lw	a1,24(sp)
    71f0:	01012503          	lw	a0,16(sp)
    71f4:	0097b4b3          	sltu	s1,a5,s1
    71f8:	01690933          	add	s2,s2,s6
    71fc:	02e12c23          	sw	a4,56(sp)
    7200:	02812e23          	sw	s0,60(sp)
    7204:	01248933          	add	s2,s1,s2
    7208:	00078493          	mv	s1,a5
    720c:	919fe0ef          	jal	5b24 <_Z25write_pages_to_dispatcherILl0ELb0EEmRmS0_S0_.constprop.0>
    7210:	01412783          	lw	a5,20(sp)
    7214:	0007a703          	lw	a4,0(a5)

00007218 <.L343>:
    7218:	840c2783          	lw	a5,-1984(s8) # ffb21840 <__stack_top+0x1f840>
    721c:	fe079ee3          	bnez	a5,7218 <.L343>
    7220:	80ec2023          	sw	a4,-2048(s8)
    7224:	800c2223          	sw	zero,-2044(s8)
    7228:	0ce00793          	li	a5,206
    722c:	80fc2423          	sw	a5,-2040(s8)
    7230:	00275713          	srli	a4,a4,0x2
    7234:	02812783          	lw	a5,40(sp)
    7238:	00377713          	andi	a4,a4,3
    723c:	00f76733          	or	a4,a4,a5
    7240:	02412783          	lw	a5,36(sp)
    7244:	415d05b3          	sub	a1,s10,s5
    7248:	80fc2e23          	sw	a5,-2020(s8)
    724c:	82ec2023          	sw	a4,-2016(s8)
    7250:	82ac2423          	sw	a0,-2008(s8)
    7254:	00100793          	li	a5,1
    7258:	84fc2023          	sw	a5,-1984(s8)
    725c:	000da783          	lw	a5,0(s11)
    7260:	41698b33          	sub	s6,s3,s6
    7264:	00178793          	addi	a5,a5,1
    7268:	00fda023          	sw	a5,0(s11)
    726c:	01c12783          	lw	a5,28(sp)
    7270:	00bd3d33          	sltu	s10,s10,a1
    7274:	41ab0633          	sub	a2,s6,s10
    7278:	0007a703          	lw	a4,0(a5)
    727c:	00060993          	mv	s3,a2
    7280:	00058d13          	mv	s10,a1

00007284 <.L344>:
    7284:	208ba783          	lw	a5,520(s7)
    7288:	fee79ee3          	bne	a5,a4,7284 <.L344>
    728c:	0ff0000f          	fence
    7290:	00c5e5b3          	or	a1,a1,a2
    7294:	00058e63          	beqz	a1,72b0 <.L356>
    7298:	000a8413          	mv	s0,s5
    729c:	000a0e13          	mv	t3,s4
    72a0:	ee9ff06f          	j	7188 <.L345>

000072a4 <.L336>:
    72a4:	00010bb7          	lui	s7,0x10
    72a8:	00000a13          	li	s4,0
    72ac:	e15ff06f          	j	70c0 <.L335>

000072b0 <.L356>:
    72b0:	219a4e33          	sh2add	t3,s4,s9
    72b4:	02c12683          	lw	a3,44(sp)
    72b8:	01812583          	lw	a1,24(sp)
    72bc:	000e2783          	lw	a5,0(t3)
    72c0:	05412c83          	lw	s9,84(sp)
    72c4:	05012d03          	lw	s10,80(sp)

000072c8 <.L338>:
    72c8:	01012503          	lw	a0,16(sp)
    72cc:	02f12c23          	sw	a5,56(sp)
    72d0:	02d12e23          	sw	a3,60(sp)
    72d4:	96cff0ef          	jal	6440 <_Z25write_pages_to_dispatcherILl1ELb1EEmRmS0_S0_.constprop.0>
    72d8:	01412783          	lw	a5,20(sp)
    72dc:	ffb015b7          	lui	a1,0xffb01
    72e0:	0007a683          	lw	a3,0(a5)
    72e4:	00001737          	lui	a4,0x1
    72e8:	9185a783          	lw	a5,-1768(a1) # ffb00918 <_ZL19downstream_data_ptr>
    72ec:	fff70713          	addi	a4,a4,-1 # fff <_start-0x39d1>
    72f0:	00e787b3          	add	a5,a5,a4
    72f4:	fffff737          	lui	a4,0xfffff
    72f8:	00e7f7b3          	and	a5,a5,a4
    72fc:	00150613          	addi	a2,a0,1
    7300:	90f5ac23          	sw	a5,-1768(a1)
    7304:	ffb22737          	lui	a4,0xffb22

00007308 <.L346>:
    7308:	84072783          	lw	a5,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    730c:	fe079ee3          	bnez	a5,7308 <.L346>
    7310:	80d72023          	sw	a3,-2048(a4)
    7314:	80072223          	sw	zero,-2044(a4)
    7318:	0026d793          	srli	a5,a3,0x2
    731c:	000015b7          	lui	a1,0x1
    7320:	0ce00513          	li	a0,206
    7324:	000026b7          	lui	a3,0x2
    7328:	80a72423          	sw	a0,-2040(a4)
    732c:	0037f793          	andi	a5,a5,3
    7330:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    7334:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    7338:	80d72e23          	sw	a3,-2020(a4)
    733c:	00b7e7b3          	or	a5,a5,a1
    7340:	82f72023          	sw	a5,-2016(a4)
    7344:	82c72423          	sw	a2,-2008(a4)
    7348:	00100793          	li	a5,1
    734c:	84f72023          	sw	a5,-1984(a4)
    7350:	000da783          	lw	a5,0(s11)
    7354:	07c12083          	lw	ra,124(sp)
    7358:	07812403          	lw	s0,120(sp)
    735c:	00178793          	addi	a5,a5,1
    7360:	00fda023          	sw	a5,0(s11)
    7364:	07412483          	lw	s1,116(sp)
    7368:	07012903          	lw	s2,112(sp)
    736c:	06c12983          	lw	s3,108(sp)
    7370:	06812a03          	lw	s4,104(sp)
    7374:	06412a83          	lw	s5,100(sp)
    7378:	06012b03          	lw	s6,96(sp)
    737c:	05c12b83          	lw	s7,92(sp)
    7380:	05812c03          	lw	s8,88(sp)
    7384:	04c12d83          	lw	s11,76(sp)
    7388:	08010113          	addi	sp,sp,128
    738c:	00008067          	ret

00007390 <.L347>:
    7390:	ffb01a37          	lui	s4,0xffb01
    7394:	86ca0713          	addi	a4,s4,-1940 # ffb0086c <sem_l1_base>
    7398:	0005a7b7          	lui	a5,0x5a
    739c:	ffb00eb7          	lui	t4,0xffb00
    73a0:	00e12a23          	sw	a4,20(sp)
    73a4:	03810713          	addi	a4,sp,56
    73a8:	000b8693          	mv	a3,s7
    73ac:	44078793          	addi	a5,a5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    73b0:	024e8d93          	addi	s11,t4,36 # ffb00024 <noc_nonposted_atomics_acked>
    73b4:	03c10593          	addi	a1,sp,60
    73b8:	00e12823          	sw	a4,16(sp)
    73bc:	f0dff06f          	j	72c8 <.L338>

000073c0 <_Z23process_relay_paged_cmdILb1EEmmRmm.constprop.0.isra.0>:
    73c0:	ffb007b7          	lui	a5,0xffb00
    73c4:	f7010113          	addi	sp,sp,-144
    73c8:	03478793          	addi	a5,a5,52 # ffb00034 <noc_nonposted_writes_num_issued>
    73cc:	0007a603          	lw	a2,0(a5)
    73d0:	09212023          	sw	s2,128(sp)
    73d4:	02f12023          	sw	a5,32(sp)
    73d8:	08112623          	sw	ra,140(sp)
    73dc:	08812423          	sw	s0,136(sp)
    73e0:	08912223          	sw	s1,132(sp)
    73e4:	07312e23          	sw	s3,124(sp)
    73e8:	07512a23          	sw	s5,116(sp)
    73ec:	07712623          	sw	s7,108(sp)
    73f0:	07812423          	sw	s8,104(sp)
    73f4:	07a12023          	sw	s10,96(sp)
    73f8:	05b12e23          	sw	s11,92(sp)
    73fc:	00050793          	mv	a5,a0
    7400:	00058913          	mv	s2,a1
    7404:	ffb206b7          	lui	a3,0xffb20

00007408 <.L358>:
    7408:	2286a703          	lw	a4,552(a3) # ffb20228 <__stack_top+0x1e228>
    740c:	fec71ee3          	bne	a4,a2,7408 <.L358>
    7410:	0ff0000f          	fence
    7414:	0047ce83          	lbu	t4,4(a5)
    7418:	0057c603          	lbu	a2,5(a5)
    741c:	0067c503          	lbu	a0,6(a5)
    7420:	0077c303          	lbu	t1,7(a5)
    7424:	0087c703          	lbu	a4,8(a5)
    7428:	0097c683          	lbu	a3,9(a5)
    742c:	00a7c883          	lbu	a7,10(a5)
    7430:	00b7c983          	lbu	s3,11(a5)
    7434:	00c7ce03          	lbu	t3,12(a5)
    7438:	00d7c803          	lbu	a6,13(a5)
    743c:	00869693          	slli	a3,a3,0x8
    7440:	00e7c583          	lbu	a1,14(a5)
    7444:	00e6e6b3          	or	a3,a3,a4
    7448:	01089893          	slli	a7,a7,0x10
    744c:	00f7c703          	lbu	a4,15(a5)
    7450:	00881813          	slli	a6,a6,0x8
    7454:	01c86833          	or	a6,a6,t3
    7458:	00d8e8b3          	or	a7,a7,a3
    745c:	01059593          	slli	a1,a1,0x10
    7460:	01899993          	slli	s3,s3,0x18
    7464:	0027ce03          	lbu	t3,2(a5)
    7468:	0119e9b3          	or	s3,s3,a7
    746c:	0037c683          	lbu	a3,3(a5)
    7470:	01871713          	slli	a4,a4,0x18
    7474:	00861793          	slli	a5,a2,0x8
    7478:	0105e633          	or	a2,a1,a6
    747c:	01d7e7b3          	or	a5,a5,t4
    7480:	00c76733          	or	a4,a4,a2
    7484:	fff98593          	addi	a1,s3,-1
    7488:	03373633          	mulhu	a2,a4,s3
    748c:	01051513          	slli	a0,a0,0x10
    7490:	00f56533          	or	a0,a0,a5
    7494:	033707b3          	mul	a5,a4,s3
    7498:	01831313          	slli	t1,t1,0x18
    749c:	07f6f713          	andi	a4,a3,127
    74a0:	03f5e693          	ori	a3,a1,63
    74a4:	00a36eb3          	or	t4,t1,a0
    74a8:	00168813          	addi	a6,a3,1
    74ac:	00871713          	slli	a4,a4,0x8
    74b0:	000105b7          	lui	a1,0x10
    74b4:	01d12623          	sw	t4,12(sp)
    74b8:	01012823          	sw	a6,16(sp)
    74bc:	00078d93          	mv	s11,a5
    74c0:	01c76bb3          	or	s7,a4,t3
    74c4:	4b35f263          	bgeu	a1,s3,7968 <.L359>
    74c8:	92492737          	lui	a4,0x92492
    74cc:	49370713          	addi	a4,a4,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    74d0:	02e93733          	mulhu	a4,s2,a4
    74d4:	ffb00537          	lui	a0,0xffb00
    74d8:	00275713          	srli	a4,a4,0x2
    74dc:	00371693          	slli	a3,a4,0x3
    74e0:	03070333          	mul	t1,a4,a6
    74e4:	40e68733          	sub	a4,a3,a4
    74e8:	40e90733          	sub	a4,s2,a4
    74ec:	64450513          	addi	a0,a0,1604 # ffb00644 <bank_to_dram_offset>
    74f0:	ffb006b7          	lui	a3,0xffb00
    74f4:	44868693          	addi	a3,a3,1096 # ffb00448 <dram_bank_to_noc_xy>
    74f8:	41778833          	sub	a6,a5,s7
    74fc:	00a12e23          	sw	a0,28(sp)
    7500:	20a74533          	sh2add	a0,a4,a0
    7504:	20d72733          	sh1add	a4,a4,a3
    7508:	00052883          	lw	a7,0(a0)
    750c:	0107b7b3          	sltu	a5,a5,a6
    7510:	00075503          	lhu	a0,0(a4)
    7514:	00d12c23          	sw	a3,24(sp)
    7518:	40f606b3          	sub	a3,a2,a5
    751c:	011e8633          	add	a2,t4,a7
    7520:	00660633          	add	a2,a2,t1
    7524:	00451513          	slli	a0,a0,0x4
    7528:	00d12a23          	sw	a3,20(sp)
    752c:	00060893          	mv	a7,a2
    7530:	00050793          	mv	a5,a0
    7534:	00080c13          	mv	s8,a6
    7538:	5e068a63          	beqz	a3,7b2c <.L472>

0000753c <.L360>:
    753c:	ffff0bb7          	lui	s7,0xffff0
    7540:	01780bb3          	add	s7,a6,s7
    7544:	fff68693          	addi	a3,a3,-1
    7548:	010bb833          	sltu	a6,s7,a6
    754c:	00d80d33          	add	s10,a6,a3
    7550:	000105b7          	lui	a1,0x10

00007554 <.L362>:
    7554:	0005a8b7          	lui	a7,0x5a
    7558:	44088893          	addi	a7,a7,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    755c:	ffb004b7          	lui	s1,0xffb00
    7560:	10000eb7          	lui	t4,0x10000
    7564:	01000e37          	lui	t3,0x1000
    7568:	40c888b3          	sub	a7,a7,a2
    756c:	03c48493          	addi	s1,s1,60 # ffb0003c <noc_reads_num_issued>
    7570:	00fe8e93          	addi	t4,t4,15 # 1000000f <__kernel_data_lma+0xfff475b>
    7574:	fffe0e13          	addi	t3,t3,-1 # ffffff <__kernel_data_lma+0xff474b>
    7578:	00060813          	mv	a6,a2
    757c:	00050313          	mv	t1,a0
    7580:	00c58fb3          	add	t6,a1,a2
    7584:	ffb21737          	lui	a4,0xffb21
    7588:	000046b7          	lui	a3,0x4
    758c:	00100f13          	li	t5,1

00007590 <.L365>:
    7590:	010882b3          	add	t0,a7,a6

00007594 <.L364>:
    7594:	84072783          	lw	a5,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    7598:	fe079ee3          	bnez	a5,7594 <.L364>
    759c:	80572623          	sw	t0,-2036(a4)
    75a0:	81072023          	sw	a6,-2048(a4)
    75a4:	01d377b3          	and	a5,t1,t4
    75a8:	80f72223          	sw	a5,-2044(a4)
    75ac:	00435793          	srli	a5,t1,0x4
    75b0:	01c7f7b3          	and	a5,a5,t3
    75b4:	80f72423          	sw	a5,-2040(a4)
    75b8:	82d72023          	sw	a3,-2016(a4)
    75bc:	85e72023          	sw	t5,-1984(a4)
    75c0:	0004a783          	lw	a5,0(s1)
    75c4:	00d802b3          	add	t0,a6,a3
    75c8:	00178793          	addi	a5,a5,1
    75cc:	00f4a023          	sw	a5,0(s1)
    75d0:	0102b7b3          	sltu	a5,t0,a6
    75d4:	00678333          	add	t1,a5,t1
    75d8:	405f87b3          	sub	a5,t6,t0
    75dc:	00028813          	mv	a6,t0
    75e0:	faf6e8e3          	bltu	a3,a5,7590 <.L365>
    75e4:	ffffc837          	lui	a6,0xffffc
    75e8:	fff80793          	addi	a5,a6,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    75ec:	00f587b3          	add	a5,a1,a5
    75f0:	00e7d713          	srli	a4,a5,0xe
    75f4:	0107f7b3          	and	a5,a5,a6
    75f8:	0005e837          	lui	a6,0x5e
    75fc:	00e71893          	slli	a7,a4,0xe
    7600:	40d58333          	sub	t1,a1,a3
    7604:	44080813          	addi	a6,a6,1088 # 5e440 <__kernel_data_lma+0x52b8c>
    7608:	00d606b3          	add	a3,a2,a3
    760c:	00088713          	mv	a4,a7
    7610:	01078833          	add	a6,a5,a6
    7614:	011688b3          	add	a7,a3,a7
    7618:	00c6b7b3          	sltu	a5,a3,a2
    761c:	00a787b3          	add	a5,a5,a0
    7620:	00d8b6b3          	sltu	a3,a7,a3
    7624:	00058413          	mv	s0,a1
    7628:	00f687b3          	add	a5,a3,a5
    762c:	40e305b3          	sub	a1,t1,a4

00007630 <.L363>:
    7630:	ffb216b7          	lui	a3,0xffb21

00007634 <.L366>:
    7634:	8406a703          	lw	a4,-1984(a3) # ffb20840 <__stack_top+0x1e840>
    7638:	fe071ee3          	bnez	a4,7634 <.L366>
    763c:	8106a623          	sw	a6,-2036(a3)
    7640:	8116a023          	sw	a7,-2048(a3)
    7644:	00f7f613          	andi	a2,a5,15
    7648:	80c6a223          	sw	a2,-2044(a3)
    764c:	0047d793          	srli	a5,a5,0x4
    7650:	80f6a423          	sw	a5,-2040(a3)
    7654:	82b6a023          	sw	a1,-2016(a3)
    7658:	00100793          	li	a5,1
    765c:	84f6a023          	sw	a5,-1984(a3)
    7660:	0004a783          	lw	a5,0(s1)
    7664:	ffb206b7          	lui	a3,0xffb20
    7668:	00178793          	addi	a5,a5,1
    766c:	00f4a023          	sw	a5,0(s1)

00007670 <.L367>:
    7670:	2086a603          	lw	a2,520(a3) # ffb20208 <__stack_top+0x1e208>
    7674:	fef61ee3          	bne	a2,a5,7670 <.L367>
    7678:	0ff0000f          	fence
    767c:	01abe7b3          	or	a5,s7,s10
    7680:	4c0784e3          	beqz	a5,8348 <.L473>
    7684:	ffb01537          	lui	a0,0xffb01
    7688:	924927b7          	lui	a5,0x92492
    768c:	90050693          	addi	a3,a0,-1792 # ffb00900 <_ZL14scratch_db_top>
    7690:	49378793          	addi	a5,a5,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    7694:	ffb015b7          	lui	a1,0xffb01
    7698:	ffb00ab7          	lui	s5,0xffb00
    769c:	07612823          	sw	s6,112(sp)
    76a0:	07912223          	sw	s9,100(sp)
    76a4:	10000b37          	lui	s6,0x10000
    76a8:	01000cb7          	lui	s9,0x1000
    76ac:	00d12423          	sw	a3,8(sp)
    76b0:	02f12223          	sw	a5,36(sp)
    76b4:	86c58693          	addi	a3,a1,-1940 # ffb0086c <sem_l1_base>
    76b8:	04010793          	addi	a5,sp,64
    76bc:	07412c23          	sw	s4,120(sp)
    76c0:	00d12023          	sw	a3,0(sp)
    76c4:	40898a33          	sub	s4,s3,s0
    76c8:	024a8e93          	addi	t4,s5,36 # ffb00024 <noc_nonposted_atomics_acked>
    76cc:	00fb0b13          	addi	s6,s6,15 # 1000000f <__kernel_data_lma+0xfff475b>
    76d0:	00098a93          	mv	s5,s3
    76d4:	fffc8c93          	addi	s9,s9,-1 # ffffff <__kernel_data_lma+0xff474b>
    76d8:	00040d93          	mv	s11,s0
    76dc:	00000693          	li	a3,0
    76e0:	00f12223          	sw	a5,4(sp)
    76e4:	00070993          	mv	s3,a4

000076e8 <.L390>:
    76e8:	02012783          	lw	a5,32(sp)
    76ec:	ffb20737          	lui	a4,0xffb20
    76f0:	0007a603          	lw	a2,0(a5)

000076f4 <.L370>:
    76f4:	22872783          	lw	a5,552(a4) # ffb20228 <__stack_top+0x1e228>
    76f8:	fec79ee3          	bne	a5,a2,76f4 <.L370>
    76fc:	0ff0000f          	fence
    7700:	02412783          	lw	a5,36(sp)
    7704:	01012503          	lw	a0,16(sp)
    7708:	02f93733          	mulhu	a4,s2,a5
    770c:	00c12783          	lw	a5,12(sp)
    7710:	00275713          	srli	a4,a4,0x2
    7714:	00878633          	add	a2,a5,s0
    7718:	02a708b3          	mul	a7,a4,a0
    771c:	00371793          	slli	a5,a4,0x3
    7720:	40e787b3          	sub	a5,a5,a4
    7724:	00c888b3          	add	a7,a7,a2
    7728:	01c12703          	lw	a4,28(sp)
    772c:	01812603          	lw	a2,24(sp)
    7730:	40f907b3          	sub	a5,s2,a5
    7734:	20e7c733          	sh2add	a4,a5,a4
    7738:	20c7a7b3          	sh1add	a5,a5,a2
    773c:	00072703          	lw	a4,0(a4)
    7740:	0007d303          	lhu	t1,0(a5)
    7744:	00812583          	lw	a1,8(sp)
    7748:	00e888b3          	add	a7,a7,a4
    774c:	0019c993          	xori	s3,s3,1
    7750:	20b6c6b3          	sh2add	a3,a3,a1
    7754:	00431313          	slli	t1,t1,0x4
    7758:	20b9c7b3          	sh2add	a5,s3,a1
    775c:	00010737          	lui	a4,0x10
    7760:	0006a683          	lw	a3,0(a3)
    7764:	0007a783          	lw	a5,0(a5)
    7768:	00088593          	mv	a1,a7
    776c:	00030613          	mv	a2,t1
    7770:	41476063          	bltu	a4,s4,7b70 <.L371>
    7774:	00004837          	lui	a6,0x4
    7778:	31487ce3          	bgeu	a6,s4,8290 <.L423>
    777c:	00030513          	mv	a0,t1
    7780:	41178fb3          	sub	t6,a5,a7
    7784:	01488f33          	add	t5,a7,s4
    7788:	ffb21637          	lui	a2,0xffb21
    778c:	00100e13          	li	t3,1

00007790 <.L374>:
    7790:	00bf82b3          	add	t0,t6,a1

00007794 <.L373>:
    7794:	84062703          	lw	a4,-1984(a2) # ffb20840 <__stack_top+0x1e840>
    7798:	fe071ee3          	bnez	a4,7794 <.L373>
    779c:	80562623          	sw	t0,-2036(a2)
    77a0:	80b62023          	sw	a1,-2048(a2)
    77a4:	01657733          	and	a4,a0,s6
    77a8:	80e62223          	sw	a4,-2044(a2)
    77ac:	00455713          	srli	a4,a0,0x4
    77b0:	01977733          	and	a4,a4,s9
    77b4:	80e62423          	sw	a4,-2040(a2)
    77b8:	83062023          	sw	a6,-2016(a2)
    77bc:	85c62023          	sw	t3,-1984(a2)
    77c0:	0004a703          	lw	a4,0(s1)
    77c4:	010582b3          	add	t0,a1,a6
    77c8:	00170713          	addi	a4,a4,1 # 10001 <__kernel_data_lma+0x474d>
    77cc:	00e4a023          	sw	a4,0(s1)
    77d0:	00b2b733          	sltu	a4,t0,a1
    77d4:	00a70533          	add	a0,a4,a0
    77d8:	405f0733          	sub	a4,t5,t0
    77dc:	00028593          	mv	a1,t0
    77e0:	fae868e3          	bltu	a6,a4,7790 <.L374>
    77e4:	ffffc5b7          	lui	a1,0xffffc
    77e8:	fff58713          	addi	a4,a1,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    77ec:	00ea0733          	add	a4,s4,a4
    77f0:	00e75613          	srli	a2,a4,0xe
    77f4:	410a0533          	sub	a0,s4,a6
    77f8:	00b77733          	and	a4,a4,a1
    77fc:	00e61593          	slli	a1,a2,0xe
    7800:	00160613          	addi	a2,a2,1
    7804:	40b50533          	sub	a0,a0,a1
    7808:	00e61593          	slli	a1,a2,0xe
    780c:	00f70733          	add	a4,a4,a5
    7810:	01265613          	srli	a2,a2,0x12
    7814:	00b885b3          	add	a1,a7,a1
    7818:	01070733          	add	a4,a4,a6
    781c:	0115b8b3          	sltu	a7,a1,a7
    7820:	00c30833          	add	a6,t1,a2
    7824:	01088633          	add	a2,a7,a6

00007828 <.L372>:
    7828:	ffb21837          	lui	a6,0xffb21

0000782c <.L375>:
    782c:	84082403          	lw	s0,-1984(a6) # ffb20840 <__stack_top+0x1e840>
    7830:	fe041ee3          	bnez	s0,782c <.L375>
    7834:	80e82623          	sw	a4,-2036(a6)
    7838:	80b82023          	sw	a1,-2048(a6)
    783c:	01667733          	and	a4,a2,s6
    7840:	80e82223          	sw	a4,-2044(a6)
    7844:	00465613          	srli	a2,a2,0x4
    7848:	80c82423          	sw	a2,-2040(a6)
    784c:	82a82023          	sw	a0,-2016(a6)
    7850:	00100713          	li	a4,1
    7854:	84e82023          	sw	a4,-1984(a6)
    7858:	0004a703          	lw	a4,0(s1)
    785c:	00190913          	addi	s2,s2,1
    7860:	00170713          	addi	a4,a4,1
    7864:	00e4a023          	sw	a4,0(s1)
    7868:	00010737          	lui	a4,0x10
    786c:	00ea0663          	beq	s4,a4,7878 <.L470>
    7870:	480d1e63          	bnez	s10,7d0c <.L434>
    7874:	497a6c63          	bltu	s4,s7,7d0c <.L434>

00007878 <.L470>:
    7878:	000a0613          	mv	a2,s4
    787c:	000a8a13          	mv	s4,s5

00007880 <.L376>:
    7880:	01412703          	lw	a4,20(sp)
    7884:	000d8793          	mv	a5,s11
    7888:	2c071a63          	bnez	a4,7b5c <.L385>
    788c:	2dbc7863          	bgeu	s8,s11,7b5c <.L385>
    7890:	000c0d93          	mv	s11,s8
    7894:	000c0793          	mv	a5,s8
    7898:	00000b93          	li	s7,0
    789c:	00000d13          	li	s10,0

000078a0 <.L387>:
    78a0:	40fc07b3          	sub	a5,s8,a5
    78a4:	01412703          	lw	a4,20(sp)
    78a8:	00fc3c33          	sltu	s8,s8,a5
    78ac:	00412503          	lw	a0,4(sp)
    78b0:	41870733          	sub	a4,a4,s8
    78b4:	04410593          	addi	a1,sp,68
    78b8:	03d12623          	sw	t4,44(sp)
    78bc:	02c12423          	sw	a2,40(sp)
    78c0:	00e12a23          	sw	a4,20(sp)
    78c4:	04d12023          	sw	a3,64(sp)
    78c8:	00078c13          	mv	s8,a5
    78cc:	05b12223          	sw	s11,68(sp)
    78d0:	a54fe0ef          	jal	5b24 <_Z25write_pages_to_dispatcherILl0ELb0EEmRmS0_S0_.constprop.0>
    78d4:	00012783          	lw	a5,0(sp)
    78d8:	02812603          	lw	a2,40(sp)
    78dc:	0007a683          	lw	a3,0(a5)
    78e0:	02c12e83          	lw	t4,44(sp)
    78e4:	00050593          	mv	a1,a0
    78e8:	ffb22737          	lui	a4,0xffb22

000078ec <.L388>:
    78ec:	84072783          	lw	a5,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    78f0:	fe079ee3          	bnez	a5,78ec <.L388>
    78f4:	80d72023          	sw	a3,-2048(a4)
    78f8:	0026d793          	srli	a5,a3,0x2
    78fc:	000016b7          	lui	a3,0x1
    7900:	07c68693          	addi	a3,a3,124 # 107c <_start-0x3954>
    7904:	0037f793          	andi	a5,a5,3
    7908:	80072223          	sw	zero,-2044(a4)
    790c:	00d7e7b3          	or	a5,a5,a3
    7910:	0ce00693          	li	a3,206
    7914:	80d72423          	sw	a3,-2040(a4)
    7918:	000026b7          	lui	a3,0x2
    791c:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    7920:	80d72e23          	sw	a3,-2020(a4)
    7924:	82f72023          	sw	a5,-2016(a4)
    7928:	82b72423          	sw	a1,-2008(a4)
    792c:	00100793          	li	a5,1
    7930:	84f72023          	sw	a5,-1984(a4)
    7934:	000ea783          	lw	a5,0(t4)
    7938:	0004a683          	lw	a3,0(s1)
    793c:	00178793          	addi	a5,a5,1
    7940:	00fea023          	sw	a5,0(t4)
    7944:	ffb20737          	lui	a4,0xffb20

00007948 <.L389>:
    7948:	20872783          	lw	a5,520(a4) # ffb20208 <__stack_top+0x1e208>
    794c:	fed79ee3          	bne	a5,a3,7948 <.L389>
    7950:	0ff0000f          	fence
    7954:	01abe7b3          	or	a5,s7,s10
    7958:	2e078263          	beqz	a5,7c3c <.L474>
    795c:	00060d93          	mv	s11,a2
    7960:	00098693          	mv	a3,s3
    7964:	d85ff06f          	j	76e8 <.L390>

00007968 <.L359>:
    7968:	00c12703          	lw	a4,12(sp)
    796c:	07412c23          	sw	s4,120(sp)
    7970:	04e12223          	sw	a4,68(sp)
    7974:	01012703          	lw	a4,16(sp)
    7978:	07612823          	sw	s6,112(sp)
    797c:	07912223          	sw	s9,100(sp)
    7980:	04e12623          	sw	a4,76(sp)
    7984:	00078413          	mv	s0,a5
    7988:	18060c63          	beqz	a2,7b20 <.L475>
    798c:	00010437          	lui	s0,0x10

00007990 <.L396>:
    7990:	1d3468e3          	bltu	s0,s3,8360 <.L398>
    7994:	ffffc6b7          	lui	a3,0xffffc
    7998:	fff68713          	addi	a4,a3,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    799c:	00e98733          	add	a4,s3,a4
    79a0:	00e75293          	srli	t0,a4,0xe
    79a4:	000048b7          	lui	a7,0x4
    79a8:	00d77733          	and	a4,a4,a3
    79ac:	411983b3          	sub	t2,s3,a7
    79b0:	00e29693          	slli	a3,t0,0xe
    79b4:	ffb00537          	lui	a0,0xffb00
    79b8:	40d383b3          	sub	t2,t2,a3
    79bc:	01170fb3          	add	t6,a4,a7
    79c0:	ffb006b7          	lui	a3,0xffb00
    79c4:	64450713          	addi	a4,a0,1604 # ffb00644 <bank_to_dram_offset>
    79c8:	00128293          	addi	t0,t0,1 # 8001 <.L417+0x25>
    79cc:	ffb004b7          	lui	s1,0xffb00
    79d0:	0005a837          	lui	a6,0x5a
    79d4:	924925b7          	lui	a1,0x92492
    79d8:	10000337          	lui	t1,0x10000
    79dc:	01000e37          	lui	t3,0x1000
    79e0:	00e12e23          	sw	a4,28(sp)
    79e4:	00c12a83          	lw	s5,12(sp)
    79e8:	44868713          	addi	a4,a3,1096 # ffb00448 <dram_bank_to_noc_xy>
    79ec:	01012e83          	lw	t4,16(sp)
    79f0:	00e12c23          	sw	a4,24(sp)
    79f4:	0122da13          	srli	s4,t0,0x12
    79f8:	03c48493          	addi	s1,s1,60 # ffb0003c <noc_reads_num_issued>
    79fc:	44080c93          	addi	s9,a6,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    7a00:	49358d13          	addi	s10,a1,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    7a04:	00f30313          	addi	t1,t1,15 # 1000000f <__kernel_data_lma+0xfff475b>
    7a08:	fffe0e13          	addi	t3,t3,-1 # ffffff <__kernel_data_lma+0xff474b>
    7a0c:	00000693          	li	a3,0
    7a10:	ffb21737          	lui	a4,0xffb21
    7a14:	00100f13          	li	t5,1

00007a18 <.L405>:
    7a18:	03a93533          	mulhu	a0,s2,s10
    7a1c:	01968833          	add	a6,a3,s9
    7a20:	00255513          	srli	a0,a0,0x2
    7a24:	00351593          	slli	a1,a0,0x3
    7a28:	03d50b33          	mul	s6,a0,t4
    7a2c:	40a585b3          	sub	a1,a1,a0
    7a30:	01812e83          	lw	t4,24(sp)
    7a34:	01c12503          	lw	a0,28(sp)
    7a38:	40b905b3          	sub	a1,s2,a1
    7a3c:	20a5c533          	sh2add	a0,a1,a0
    7a40:	21d5a5b3          	sh1add	a1,a1,t4
    7a44:	00052503          	lw	a0,0(a0)
    7a48:	0005dc03          	lhu	s8,0(a1)
    7a4c:	015b0b33          	add	s6,s6,s5
    7a50:	00ab0b33          	add	s6,s6,a0
    7a54:	004c1c13          	slli	s8,s8,0x4
    7a58:	000b0513          	mv	a0,s6
    7a5c:	000c0e93          	mv	t4,s8
    7a60:	4538f263          	bgeu	a7,s3,7ea4 <.L428>
    7a64:	010f8ab3          	add	s5,t6,a6

00007a68 <.L400>:
    7a68:	84072583          	lw	a1,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    7a6c:	fe059ee3          	bnez	a1,7a68 <.L400>
    7a70:	81072623          	sw	a6,-2036(a4)
    7a74:	80a72023          	sw	a0,-2048(a4)
    7a78:	006ef5b3          	and	a1,t4,t1
    7a7c:	80b72223          	sw	a1,-2044(a4)
    7a80:	004ed593          	srli	a1,t4,0x4
    7a84:	01c5f5b3          	and	a1,a1,t3
    7a88:	80b72423          	sw	a1,-2040(a4)
    7a8c:	83172023          	sw	a7,-2016(a4)
    7a90:	85e72023          	sw	t5,-1984(a4)
    7a94:	0004a583          	lw	a1,0(s1)
    7a98:	01180833          	add	a6,a6,a7
    7a9c:	00158593          	addi	a1,a1,1
    7aa0:	00b4a023          	sw	a1,0(s1)
    7aa4:	011505b3          	add	a1,a0,a7
    7aa8:	00a5b533          	sltu	a0,a1,a0
    7aac:	01d50eb3          	add	t4,a0,t4
    7ab0:	00058513          	mv	a0,a1
    7ab4:	fb0a9ae3          	bne	s5,a6,7a68 <.L400>
    7ab8:	00e29513          	slli	a0,t0,0xe
    7abc:	00ab0533          	add	a0,s6,a0
    7ac0:	014c0c33          	add	s8,s8,s4
    7ac4:	01653b33          	sltu	s6,a0,s6
    7ac8:	018b0eb3          	add	t4,s6,s8
    7acc:	00038813          	mv	a6,t2

00007ad0 <.L402>:
    7ad0:	84072583          	lw	a1,-1984(a4)
    7ad4:	fe059ee3          	bnez	a1,7ad0 <.L402>
    7ad8:	81572623          	sw	s5,-2036(a4)
    7adc:	80a72023          	sw	a0,-2048(a4)
    7ae0:	006ef5b3          	and	a1,t4,t1
    7ae4:	80b72223          	sw	a1,-2044(a4)
    7ae8:	004ede93          	srli	t4,t4,0x4
    7aec:	81d72423          	sw	t4,-2040(a4)
    7af0:	83072023          	sw	a6,-2016(a4)
    7af4:	85e72023          	sw	t5,-1984(a4)
    7af8:	0004a583          	lw	a1,0(s1)
    7afc:	013686b3          	add	a3,a3,s3
    7b00:	00158593          	addi	a1,a1,1
    7b04:	00b4a023          	sw	a1,0(s1)
    7b08:	40d40533          	sub	a0,s0,a3
    7b0c:	00190913          	addi	s2,s2,1
    7b10:	3b356063          	bltu	a0,s3,7eb0 <.L476>
    7b14:	04c12e83          	lw	t4,76(sp)
    7b18:	04412a83          	lw	s5,68(sp)
    7b1c:	efdff06f          	j	7a18 <.L405>

00007b20 <.L475>:
    7b20:	e6f5f8e3          	bgeu	a1,a5,7990 <.L396>
    7b24:	00010437          	lui	s0,0x10
    7b28:	e69ff06f          	j	7990 <.L396>

00007b2c <.L472>:
    7b2c:	a105e8e3          	bltu	a1,a6,753c <.L360>
    7b30:	00004737          	lui	a4,0x4
    7b34:	00080593          	mv	a1,a6
    7b38:	00000b93          	li	s7,0
    7b3c:	00000d13          	li	s10,0
    7b40:	a1076ae3          	bltu	a4,a6,7554 <.L362>
    7b44:	0005a837          	lui	a6,0x5a
    7b48:	ffb004b7          	lui	s1,0xffb00
    7b4c:	44080813          	addi	a6,a6,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    7b50:	03c48493          	addi	s1,s1,60 # ffb0003c <noc_reads_num_issued>
    7b54:	000c0413          	mv	s0,s8
    7b58:	ad9ff06f          	j	7630 <.L363>

00007b5c <.L385>:
    7b5c:	40cb8733          	sub	a4,s7,a2
    7b60:	00ebbbb3          	sltu	s7,s7,a4
    7b64:	417d0d33          	sub	s10,s10,s7
    7b68:	00070b93          	mv	s7,a4
    7b6c:	d35ff06f          	j	78a0 <.L387>

00007b70 <.L371>:
    7b70:	0000ce37          	lui	t3,0xc
    7b74:	01c78e33          	add	t3,a5,t3
    7b78:	00030513          	mv	a0,t1
    7b7c:	ffb21637          	lui	a2,0xffb21
    7b80:	00004837          	lui	a6,0x4
    7b84:	00100f13          	li	t5,1

00007b88 <.L382>:
    7b88:	84062703          	lw	a4,-1984(a2) # ffb20840 <__stack_top+0x1e840>
    7b8c:	fe071ee3          	bnez	a4,7b88 <.L382>
    7b90:	80f62623          	sw	a5,-2036(a2)
    7b94:	80b62023          	sw	a1,-2048(a2)
    7b98:	01657733          	and	a4,a0,s6
    7b9c:	80e62223          	sw	a4,-2044(a2)
    7ba0:	00455713          	srli	a4,a0,0x4
    7ba4:	01977733          	and	a4,a4,s9
    7ba8:	80e62423          	sw	a4,-2040(a2)
    7bac:	83062023          	sw	a6,-2016(a2)
    7bb0:	85e62023          	sw	t5,-1984(a2)
    7bb4:	0004a703          	lw	a4,0(s1)
    7bb8:	010787b3          	add	a5,a5,a6
    7bbc:	00170713          	addi	a4,a4,1 # 4001 <_start-0x9cf>
    7bc0:	00e4a023          	sw	a4,0(s1)
    7bc4:	01058733          	add	a4,a1,a6
    7bc8:	00b735b3          	sltu	a1,a4,a1
    7bcc:	00a58533          	add	a0,a1,a0
    7bd0:	00070593          	mv	a1,a4
    7bd4:	fbc79ae3          	bne	a5,t3,7b88 <.L382>
    7bd8:	0000c637          	lui	a2,0xc
    7bdc:	00c88633          	add	a2,a7,a2
    7be0:	011637b3          	sltu	a5,a2,a7
    7be4:	006787b3          	add	a5,a5,t1
    7be8:	ffb21737          	lui	a4,0xffb21

00007bec <.L384>:
    7bec:	84072583          	lw	a1,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    7bf0:	fe059ee3          	bnez	a1,7bec <.L384>
    7bf4:	81c72623          	sw	t3,-2036(a4)
    7bf8:	80c72023          	sw	a2,-2048(a4)
    7bfc:	0167f633          	and	a2,a5,s6
    7c00:	80c72223          	sw	a2,-2044(a4)
    7c04:	0047d793          	srli	a5,a5,0x4
    7c08:	80f72423          	sw	a5,-2040(a4)
    7c0c:	000047b7          	lui	a5,0x4
    7c10:	82f72023          	sw	a5,-2016(a4)
    7c14:	00100793          	li	a5,1
    7c18:	84f72023          	sw	a5,-1984(a4)
    7c1c:	0004a783          	lw	a5,0(s1)
    7c20:	ffff0737          	lui	a4,0xffff0
    7c24:	00178793          	addi	a5,a5,1 # 4001 <_start-0x9cf>
    7c28:	00010637          	lui	a2,0x10
    7c2c:	00c40433          	add	s0,s0,a2
    7c30:	00f4a023          	sw	a5,0(s1)
    7c34:	00ea0a33          	add	s4,s4,a4
    7c38:	c49ff06f          	j	7880 <.L376>

00007c3c <.L474>:
    7c3c:	07812a03          	lw	s4,120(sp)
    7c40:	07012b03          	lw	s6,112(sp)
    7c44:	06412c83          	lw	s9,100(sp)
    7c48:	00098713          	mv	a4,s3
    7c4c:	000e8a93          	mv	s5,t4

00007c50 <.L368>:
    7c50:	01412783          	lw	a5,20(sp)
    7c54:	00fc67b3          	or	a5,s8,a5
    7c58:	64079263          	bnez	a5,829c <.L477>
    7c5c:	00012783          	lw	a5,0(sp)
    7c60:	ffb01637          	lui	a2,0xffb01
    7c64:	0007a703          	lw	a4,0(a5)
    7c68:	000016b7          	lui	a3,0x1
    7c6c:	91862783          	lw	a5,-1768(a2) # ffb00918 <_ZL19downstream_data_ptr>
    7c70:	fff68693          	addi	a3,a3,-1 # fff <_start-0x39d1>
    7c74:	00d787b3          	add	a5,a5,a3
    7c78:	fffff6b7          	lui	a3,0xfffff
    7c7c:	00d7f7b3          	and	a5,a5,a3
    7c80:	90f62c23          	sw	a5,-1768(a2)
    7c84:	ffb227b7          	lui	a5,0xffb22

00007c88 <.L395>:
    7c88:	8407a683          	lw	a3,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    7c8c:	fe069ee3          	bnez	a3,7c88 <.L395>
    7c90:	80e7a023          	sw	a4,-2048(a5)
    7c94:	8007a223          	sw	zero,-2044(a5)
    7c98:	00275713          	srli	a4,a4,0x2
    7c9c:	00001637          	lui	a2,0x1
    7ca0:	0ce00593          	li	a1,206
    7ca4:	000026b7          	lui	a3,0x2
    7ca8:	80b7a423          	sw	a1,-2040(a5)
    7cac:	00377713          	andi	a4,a4,3
    7cb0:	07c60613          	addi	a2,a2,124 # 107c <_start-0x3954>
    7cb4:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    7cb8:	80d7ae23          	sw	a3,-2020(a5)
    7cbc:	00c76733          	or	a4,a4,a2
    7cc0:	82e7a023          	sw	a4,-2016(a5)
    7cc4:	00100713          	li	a4,1
    7cc8:	82e7a423          	sw	a4,-2008(a5)
    7ccc:	84e7a023          	sw	a4,-1984(a5)
    7cd0:	000aa783          	lw	a5,0(s5)
    7cd4:	00e787b3          	add	a5,a5,a4
    7cd8:	00faa023          	sw	a5,0(s5)

00007cdc <.L357>:
    7cdc:	08c12083          	lw	ra,140(sp)
    7ce0:	08812403          	lw	s0,136(sp)
    7ce4:	08412483          	lw	s1,132(sp)
    7ce8:	08012903          	lw	s2,128(sp)
    7cec:	07c12983          	lw	s3,124(sp)
    7cf0:	07412a83          	lw	s5,116(sp)
    7cf4:	06c12b83          	lw	s7,108(sp)
    7cf8:	06812c03          	lw	s8,104(sp)
    7cfc:	06012d03          	lw	s10,96(sp)
    7d00:	05c12d83          	lw	s11,92(sp)
    7d04:	09010113          	addi	sp,sp,144
    7d08:	00008067          	ret

00007d0c <.L434>:
    7d0c:	92492737          	lui	a4,0x92492
    7d10:	49370713          	addi	a4,a4,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    7d14:	02e93733          	mulhu	a4,s2,a4
    7d18:	01012583          	lw	a1,16(sp)
    7d1c:	00275713          	srli	a4,a4,0x2
    7d20:	00371613          	slli	a2,a4,0x3
    7d24:	02b705b3          	mul	a1,a4,a1
    7d28:	01812503          	lw	a0,24(sp)
    7d2c:	40e60733          	sub	a4,a2,a4
    7d30:	01c12603          	lw	a2,28(sp)
    7d34:	40e90733          	sub	a4,s2,a4
    7d38:	20c74633          	sh2add	a2,a4,a2
    7d3c:	20a72733          	sh1add	a4,a4,a0
    7d40:	00075883          	lhu	a7,0(a4)
    7d44:	00c12703          	lw	a4,12(sp)
    7d48:	00062603          	lw	a2,0(a2)
    7d4c:	00e585b3          	add	a1,a1,a4
    7d50:	00010437          	lui	s0,0x10
    7d54:	ffff4537          	lui	a0,0xffff4
    7d58:	00c585b3          	add	a1,a1,a2
    7d5c:	00489893          	slli	a7,a7,0x4
    7d60:	41440433          	sub	s0,s0,s4
    7d64:	00aa0533          	add	a0,s4,a0
    7d68:	00004837          	lui	a6,0x4
    7d6c:	014787b3          	add	a5,a5,s4
    7d70:	00058313          	mv	t1,a1
    7d74:	00088713          	mv	a4,a7
    7d78:	00040613          	mv	a2,s0
    7d7c:	0ca87863          	bgeu	a6,a0,7e4c <.L378>
    7d80:	10000e37          	lui	t3,0x10000
    7d84:	01000737          	lui	a4,0x1000
    7d88:	00fe0e13          	addi	t3,t3,15 # 1000000f <__kernel_data_lma+0xfff475b>
    7d8c:	fff70713          	addi	a4,a4,-1 # ffffff <__kernel_data_lma+0xff474b>
    7d90:	00058513          	mv	a0,a1
    7d94:	00088313          	mv	t1,a7
    7d98:	40b782b3          	sub	t0,a5,a1
    7d9c:	00b40fb3          	add	t6,s0,a1
    7da0:	ffb21637          	lui	a2,0xffb21
    7da4:	00100f13          	li	t5,1
    7da8:	03512423          	sw	s5,40(sp)

00007dac <.L380>:
    7dac:	00a28ab3          	add	s5,t0,a0

00007db0 <.L379>:
    7db0:	84062383          	lw	t2,-1984(a2) # ffb20840 <__stack_top+0x1e840>
    7db4:	fe039ee3          	bnez	t2,7db0 <.L379>
    7db8:	81562623          	sw	s5,-2036(a2)
    7dbc:	80a62023          	sw	a0,-2048(a2)
    7dc0:	01c373b3          	and	t2,t1,t3
    7dc4:	80762223          	sw	t2,-2044(a2)
    7dc8:	00435393          	srli	t2,t1,0x4
    7dcc:	00e3f3b3          	and	t2,t2,a4
    7dd0:	80762423          	sw	t2,-2040(a2)
    7dd4:	83062023          	sw	a6,-2016(a2)
    7dd8:	85e62023          	sw	t5,-1984(a2)
    7ddc:	0004a383          	lw	t2,0(s1)
    7de0:	01050ab3          	add	s5,a0,a6
    7de4:	00138393          	addi	t2,t2,1
    7de8:	0074a023          	sw	t2,0(s1)
    7dec:	00aab3b3          	sltu	t2,s5,a0
    7df0:	00638333          	add	t1,t2,t1
    7df4:	415f83b3          	sub	t2,t6,s5
    7df8:	000a8513          	mv	a0,s5
    7dfc:	fa7868e3          	bltu	a6,t2,7dac <.L380>
    7e00:	0000c637          	lui	a2,0xc
    7e04:	fff60513          	addi	a0,a2,-1 # bfff <__kernel_data_lma+0x74b>
    7e08:	41450533          	sub	a0,a0,s4
    7e0c:	00e55713          	srli	a4,a0,0xe
    7e10:	00e71313          	slli	t1,a4,0xe
    7e14:	41460633          	sub	a2,a2,s4
    7e18:	00170713          	addi	a4,a4,1
    7e1c:	40660633          	sub	a2,a2,t1
    7e20:	ffffc337          	lui	t1,0xffffc
    7e24:	00657533          	and	a0,a0,t1
    7e28:	00e71313          	slli	t1,a4,0xe
    7e2c:	00658333          	add	t1,a1,t1
    7e30:	01275713          	srli	a4,a4,0x12
    7e34:	00f507b3          	add	a5,a0,a5
    7e38:	00b335b3          	sltu	a1,t1,a1
    7e3c:	00e88733          	add	a4,a7,a4
    7e40:	02812a83          	lw	s5,40(sp)
    7e44:	010787b3          	add	a5,a5,a6
    7e48:	00e58733          	add	a4,a1,a4

00007e4c <.L378>:
    7e4c:	ffb215b7          	lui	a1,0xffb21

00007e50 <.L381>:
    7e50:	8405a503          	lw	a0,-1984(a1) # ffb20840 <__stack_top+0x1e840>
    7e54:	fe051ee3          	bnez	a0,7e50 <.L381>
    7e58:	80f5a623          	sw	a5,-2036(a1)
    7e5c:	100007b7          	lui	a5,0x10000
    7e60:	00f78793          	addi	a5,a5,15 # 1000000f <__kernel_data_lma+0xfff475b>
    7e64:	8065a023          	sw	t1,-2048(a1)
    7e68:	00f777b3          	and	a5,a4,a5
    7e6c:	80f5a223          	sw	a5,-2044(a1)
    7e70:	00475713          	srli	a4,a4,0x4
    7e74:	80e5a423          	sw	a4,-2040(a1)
    7e78:	82c5a023          	sw	a2,-2016(a1)
    7e7c:	00100793          	li	a5,1
    7e80:	84f5a023          	sw	a5,-1984(a1)
    7e84:	0004a703          	lw	a4,0(s1)
    7e88:	ffff07b7          	lui	a5,0xffff0
    7e8c:	00170713          	addi	a4,a4,1
    7e90:	00fa87b3          	add	a5,s5,a5
    7e94:	00e4a023          	sw	a4,0(s1)
    7e98:	00fa0a33          	add	s4,s4,a5
    7e9c:	00010637          	lui	a2,0x10
    7ea0:	9e1ff06f          	j	7880 <.L376>

00007ea4 <.L428>:
    7ea4:	00080a93          	mv	s5,a6
    7ea8:	00098813          	mv	a6,s3
    7eac:	c25ff06f          	j	7ad0 <.L402>

00007eb0 <.L476>:
    7eb0:	40d78733          	sub	a4,a5,a3
    7eb4:	00e7b7b3          	sltu	a5,a5,a4
    7eb8:	40f60633          	sub	a2,a2,a5
    7ebc:	00070d93          	mv	s11,a4

00007ec0 <.L404>:
    7ec0:	ffb207b7          	lui	a5,0xffb20

00007ec4 <.L406>:
    7ec4:	2087a703          	lw	a4,520(a5) # ffb20208 <__stack_top+0x1e208>
    7ec8:	feb71ee3          	bne	a4,a1,7ec4 <.L406>
    7ecc:	0ff0000f          	fence
    7ed0:	00cdec33          	or	s8,s11,a2
    7ed4:	4a0c0063          	beqz	s8,8374 <.L429>
    7ed8:	ffffc7b7          	lui	a5,0xffffc
    7edc:	fff78713          	addi	a4,a5,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    7ee0:	00e98733          	add	a4,s3,a4
    7ee4:	00f777b3          	and	a5,a4,a5
    7ee8:	ffb01537          	lui	a0,0xffb01
    7eec:	00004437          	lui	s0,0x4
    7ef0:	ffb015b7          	lui	a1,0xffb01
    7ef4:	00878b33          	add	s6,a5,s0
    7ef8:	90050793          	addi	a5,a0,-1792 # ffb00900 <_ZL14scratch_db_top>
    7efc:	00f12423          	sw	a5,8(sp)
    7f00:	86c58793          	addi	a5,a1,-1940 # ffb0086c <sem_l1_base>
    7f04:	ffb00ab7          	lui	s5,0xffb00
    7f08:	00f12023          	sw	a5,0(sp)
    7f0c:	04010793          	addi	a5,sp,64
    7f10:	00f12223          	sw	a5,4(sp)
    7f14:	00e12623          	sw	a4,12(sp)
    7f18:	00000513          	li	a0,0
    7f1c:	01712823          	sw	s7,16(sp)
    7f20:	00060c93          	mv	s9,a2
    7f24:	03c10f13          	addi	t5,sp,60
    7f28:	024a8793          	addi	a5,s5,36 # ffb00024 <noc_nonposted_atomics_acked>

00007f2c <.L420>:
    7f2c:	02012703          	lw	a4,32(sp)
    7f30:	ffb20637          	lui	a2,0xffb20
    7f34:	00072583          	lw	a1,0(a4)

00007f38 <.L409>:
    7f38:	22862703          	lw	a4,552(a2) # ffb20228 <__stack_top+0x1e228>
    7f3c:	feb71ee3          	bne	a4,a1,7f38 <.L409>
    7f40:	0ff0000f          	fence
    7f44:	00812703          	lw	a4,8(sp)
    7f48:	00154893          	xori	a7,a0,1
    7f4c:	20e54733          	sh2add	a4,a0,a4
    7f50:	000d8b93          	mv	s7,s11
    7f54:	00072503          	lw	a0,0(a4)
    7f58:	240c9e63          	bnez	s9,81b4 <.L411>
    7f5c:	00010737          	lui	a4,0x10
    7f60:	25b76a63          	bltu	a4,s11,81b4 <.L411>

00007f64 <.L410>:
    7f64:	00000a13          	li	s4,0
    7f68:	193bec63          	bltu	s7,s3,8100 <.L412>
    7f6c:	00c12703          	lw	a4,12(sp)
    7f70:	40898c33          	sub	s8,s3,s0
    7f74:	00e75f93          	srli	t6,a4,0xe
    7f78:	00812703          	lw	a4,8(sp)
    7f7c:	00ef9613          	slli	a2,t6,0xe
    7f80:	20e8c733          	sh2add	a4,a7,a4
    7f84:	001f8f93          	addi	t6,t6,1
    7f88:	ffb00ab7          	lui	s5,0xffb00
    7f8c:	ffb003b7          	lui	t2,0xffb00
    7f90:	924922b7          	lui	t0,0x92492
    7f94:	10000337          	lui	t1,0x10000
    7f98:	01000eb7          	lui	t4,0x1000
    7f9c:	40cc0c33          	sub	s8,s8,a2
    7fa0:	012fdd13          	srli	s10,t6,0x12
    7fa4:	00072603          	lw	a2,0(a4) # 10000 <__kernel_data_lma+0x474c>
    7fa8:	00ef9f93          	slli	t6,t6,0xe
    7fac:	644a8a93          	addi	s5,s5,1604 # ffb00644 <bank_to_dram_offset>
    7fb0:	44838393          	addi	t2,t2,1096 # ffb00448 <dram_bank_to_noc_xy>
    7fb4:	49328293          	addi	t0,t0,1171 # 92492493 <__kernel_data_lma+0x92486bdf>
    7fb8:	00f30313          	addi	t1,t1,15 # 1000000f <__kernel_data_lma+0xfff475b>
    7fbc:	fffe8e93          	addi	t4,t4,-1 # ffffff <__kernel_data_lma+0xff474b>
    7fc0:	ffb21737          	lui	a4,0xffb21
    7fc4:	00100e13          	li	t3,1
    7fc8:	01112a23          	sw	a7,20(sp)
    7fcc:	00a12c23          	sw	a0,24(sp)
    7fd0:	00d12e23          	sw	a3,28(sp)
    7fd4:	03b12223          	sw	s11,36(sp)
    7fd8:	03912423          	sw	s9,40(sp)

00007fdc <.L417>:
    7fdc:	025936b3          	mulhu	a3,s2,t0
    7fe0:	04c12583          	lw	a1,76(sp)
    7fe4:	0026d693          	srli	a3,a3,0x2
    7fe8:	00369513          	slli	a0,a3,0x3
    7fec:	02b685b3          	mul	a1,a3,a1
    7ff0:	40d506b3          	sub	a3,a0,a3
    7ff4:	40d906b3          	sub	a3,s2,a3
    7ff8:	04412803          	lw	a6,68(sp)
    7ffc:	2156c533          	sh2add	a0,a3,s5
    8000:	2076a6b3          	sh1add	a3,a3,t2
    8004:	00052503          	lw	a0,0(a0)
    8008:	0006dd83          	lhu	s11,0(a3)
    800c:	010585b3          	add	a1,a1,a6
    8010:	00a588b3          	add	a7,a1,a0
    8014:	004d9d93          	slli	s11,s11,0x4
    8018:	00088593          	mv	a1,a7
    801c:	000d8693          	mv	a3,s11
    8020:	01460533          	add	a0,a2,s4
    8024:	19347c63          	bgeu	s0,s3,81bc <.L431>
    8028:	00ab0cb3          	add	s9,s6,a0
    802c:	000d8813          	mv	a6,s11

00008030 <.L414>:
    8030:	84072683          	lw	a3,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    8034:	fe069ee3          	bnez	a3,8030 <.L414>
    8038:	80a72623          	sw	a0,-2036(a4)
    803c:	80b72023          	sw	a1,-2048(a4)
    8040:	006876b3          	and	a3,a6,t1
    8044:	80d72223          	sw	a3,-2044(a4)
    8048:	00485693          	srli	a3,a6,0x4
    804c:	01d6f6b3          	and	a3,a3,t4
    8050:	80d72423          	sw	a3,-2040(a4)
    8054:	82872023          	sw	s0,-2016(a4)
    8058:	85c72023          	sw	t3,-1984(a4)
    805c:	0004a683          	lw	a3,0(s1)
    8060:	00850533          	add	a0,a0,s0
    8064:	00168693          	addi	a3,a3,1
    8068:	00d4a023          	sw	a3,0(s1)
    806c:	008586b3          	add	a3,a1,s0
    8070:	00b6b5b3          	sltu	a1,a3,a1
    8074:	01058833          	add	a6,a1,a6
    8078:	00068593          	mv	a1,a3
    807c:	faac9ae3          	bne	s9,a0,8030 <.L414>
    8080:	01f885b3          	add	a1,a7,t6
    8084:	01ad86b3          	add	a3,s11,s10
    8088:	0115b8b3          	sltu	a7,a1,a7
    808c:	00d886b3          	add	a3,a7,a3
    8090:	000c0813          	mv	a6,s8

00008094 <.L416>:
    8094:	84072503          	lw	a0,-1984(a4)
    8098:	fe051ee3          	bnez	a0,8094 <.L416>
    809c:	81972623          	sw	s9,-2036(a4)
    80a0:	80b72023          	sw	a1,-2048(a4)
    80a4:	0066f5b3          	and	a1,a3,t1
    80a8:	80b72223          	sw	a1,-2044(a4)
    80ac:	0046d693          	srli	a3,a3,0x4
    80b0:	80d72423          	sw	a3,-2040(a4)
    80b4:	83072023          	sw	a6,-2016(a4)
    80b8:	85c72023          	sw	t3,-1984(a4)
    80bc:	0004a683          	lw	a3,0(s1)
    80c0:	013a0a33          	add	s4,s4,s3
    80c4:	00168693          	addi	a3,a3,1
    80c8:	00d4a023          	sw	a3,0(s1)
    80cc:	414b86b3          	sub	a3,s7,s4
    80d0:	00190913          	addi	s2,s2,1
    80d4:	f136f4e3          	bgeu	a3,s3,7fdc <.L417>
    80d8:	02412d83          	lw	s11,36(sp)
    80dc:	02812c83          	lw	s9,40(sp)
    80e0:	414d8733          	sub	a4,s11,s4
    80e4:	00edbdb3          	sltu	s11,s11,a4
    80e8:	41bc8cb3          	sub	s9,s9,s11
    80ec:	01412883          	lw	a7,20(sp)
    80f0:	01812503          	lw	a0,24(sp)
    80f4:	01c12683          	lw	a3,28(sp)
    80f8:	00070d93          	mv	s11,a4
    80fc:	01976c33          	or	s8,a4,s9

00008100 <.L412>:
    8100:	00412583          	lw	a1,4(sp)
    8104:	02a12e23          	sw	a0,60(sp)
    8108:	000f0513          	mv	a0,t5
    810c:	01112e23          	sw	a7,28(sp)
    8110:	00f12c23          	sw	a5,24(sp)
    8114:	04d12023          	sw	a3,64(sp)
    8118:	01e12a23          	sw	t5,20(sp)
    811c:	a09fd0ef          	jal	5b24 <_Z25write_pages_to_dispatcherILl0ELb0EEmRmS0_S0_.constprop.0>
    8120:	00012783          	lw	a5,0(sp)
    8124:	01c12883          	lw	a7,28(sp)
    8128:	0007a603          	lw	a2,0(a5)
    812c:	01412f03          	lw	t5,20(sp)
    8130:	01812783          	lw	a5,24(sp)
    8134:	00050593          	mv	a1,a0
    8138:	ffb226b7          	lui	a3,0xffb22

0000813c <.L418>:
    813c:	8406a703          	lw	a4,-1984(a3) # ffb21840 <__stack_top+0x1f840>
    8140:	fe071ee3          	bnez	a4,813c <.L418>
    8144:	80c6a023          	sw	a2,-2048(a3)
    8148:	8006a223          	sw	zero,-2044(a3)
    814c:	00265713          	srli	a4,a2,0x2
    8150:	00001537          	lui	a0,0x1
    8154:	0ce00813          	li	a6,206
    8158:	00002637          	lui	a2,0x2
    815c:	8106a423          	sw	a6,-2040(a3)
    8160:	09160613          	addi	a2,a2,145 # 2091 <_start-0x293f>
    8164:	00377713          	andi	a4,a4,3
    8168:	07c50513          	addi	a0,a0,124 # 107c <_start-0x3954>
    816c:	80c6ae23          	sw	a2,-2020(a3)
    8170:	00a76733          	or	a4,a4,a0
    8174:	82e6a023          	sw	a4,-2016(a3)
    8178:	82b6a423          	sw	a1,-2008(a3)
    817c:	00100713          	li	a4,1
    8180:	84e6a023          	sw	a4,-1984(a3)
    8184:	0007a703          	lw	a4,0(a5)
    8188:	0004a603          	lw	a2,0(s1)
    818c:	00170713          	addi	a4,a4,1
    8190:	00e7a023          	sw	a4,0(a5)
    8194:	ffb206b7          	lui	a3,0xffb20

00008198 <.L419>:
    8198:	2086a703          	lw	a4,520(a3) # ffb20208 <__stack_top+0x1e208>
    819c:	fec71ee3          	bne	a4,a2,8198 <.L419>
    81a0:	0ff0000f          	fence
    81a4:	020c0263          	beqz	s8,81c8 <.L478>
    81a8:	000a0693          	mv	a3,s4
    81ac:	00088513          	mv	a0,a7
    81b0:	d7dff06f          	j	7f2c <.L420>

000081b4 <.L411>:
    81b4:	00010bb7          	lui	s7,0x10
    81b8:	dadff06f          	j	7f64 <.L410>

000081bc <.L431>:
    81bc:	00050c93          	mv	s9,a0
    81c0:	00098813          	mv	a6,s3
    81c4:	ed1ff06f          	j	8094 <.L416>

000081c8 <.L478>:
    81c8:	00078a93          	mv	s5,a5
    81cc:	00812783          	lw	a5,8(sp)
    81d0:	01012b83          	lw	s7,16(sp)
    81d4:	20f8ceb3          	sh2add	t4,a7,a5
    81d8:	000ea783          	lw	a5,0(t4)
    81dc:	000f0813          	mv	a6,t5
    81e0:	000a0693          	mv	a3,s4

000081e4 <.L407>:
    81e4:	00412583          	lw	a1,4(sp)
    81e8:	417686b3          	sub	a3,a3,s7
    81ec:	00080513          	mv	a0,a6
    81f0:	04d12023          	sw	a3,64(sp)
    81f4:	02f12e23          	sw	a5,60(sp)
    81f8:	a48fe0ef          	jal	6440 <_Z25write_pages_to_dispatcherILl1ELb1EEmRmS0_S0_.constprop.0>
    81fc:	00012783          	lw	a5,0(sp)
    8200:	ffb01637          	lui	a2,0xffb01
    8204:	0007a703          	lw	a4,0(a5)
    8208:	000016b7          	lui	a3,0x1
    820c:	91862783          	lw	a5,-1768(a2) # ffb00918 <_ZL19downstream_data_ptr>
    8210:	fff68693          	addi	a3,a3,-1 # fff <_start-0x39d1>
    8214:	00d787b3          	add	a5,a5,a3
    8218:	fffff6b7          	lui	a3,0xfffff
    821c:	00d7f7b3          	and	a5,a5,a3
    8220:	90f62c23          	sw	a5,-1768(a2)
    8224:	00150693          	addi	a3,a0,1
    8228:	ffb227b7          	lui	a5,0xffb22

0000822c <.L421>:
    822c:	8407a603          	lw	a2,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    8230:	fe061ee3          	bnez	a2,822c <.L421>
    8234:	80e7a023          	sw	a4,-2048(a5)
    8238:	8007a223          	sw	zero,-2044(a5)
    823c:	00275713          	srli	a4,a4,0x2
    8240:	000015b7          	lui	a1,0x1
    8244:	0ce00513          	li	a0,206
    8248:	00002637          	lui	a2,0x2
    824c:	80a7a423          	sw	a0,-2040(a5)
    8250:	00377713          	andi	a4,a4,3
    8254:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    8258:	09160613          	addi	a2,a2,145 # 2091 <_start-0x293f>
    825c:	80c7ae23          	sw	a2,-2020(a5)
    8260:	00b76733          	or	a4,a4,a1
    8264:	82e7a023          	sw	a4,-2016(a5)
    8268:	82d7a423          	sw	a3,-2008(a5)
    826c:	00100713          	li	a4,1
    8270:	84e7a023          	sw	a4,-1984(a5)
    8274:	000aa783          	lw	a5,0(s5)
    8278:	07812a03          	lw	s4,120(sp)
    827c:	00e787b3          	add	a5,a5,a4
    8280:	07012b03          	lw	s6,112(sp)
    8284:	06412c83          	lw	s9,100(sp)
    8288:	00faa023          	sw	a5,0(s5)
    828c:	a51ff06f          	j	7cdc <.L357>

00008290 <.L423>:
    8290:	000a0513          	mv	a0,s4
    8294:	00078713          	mv	a4,a5
    8298:	d90ff06f          	j	7828 <.L372>

0000829c <.L477>:
    829c:	ffb017b7          	lui	a5,0xffb01
    82a0:	90078793          	addi	a5,a5,-1792 # ffb00900 <_ZL14scratch_db_top>
    82a4:	20f74733          	sh2add	a4,a4,a5
    82a8:	00072783          	lw	a5,0(a4)
    82ac:	04410593          	addi	a1,sp,68
    82b0:	04010513          	addi	a0,sp,64
    82b4:	04f12023          	sw	a5,64(sp)
    82b8:	05812223          	sw	s8,68(sp)
    82bc:	984fe0ef          	jal	6440 <_Z25write_pages_to_dispatcherILl1ELb1EEmRmS0_S0_.constprop.0>
    82c0:	00012783          	lw	a5,0(sp)
    82c4:	ffb01637          	lui	a2,0xffb01
    82c8:	0007a703          	lw	a4,0(a5)
    82cc:	000016b7          	lui	a3,0x1
    82d0:	91862783          	lw	a5,-1768(a2) # ffb00918 <_ZL19downstream_data_ptr>
    82d4:	fff68693          	addi	a3,a3,-1 # fff <_start-0x39d1>
    82d8:	00d787b3          	add	a5,a5,a3
    82dc:	fffff6b7          	lui	a3,0xfffff
    82e0:	00d7f7b3          	and	a5,a5,a3
    82e4:	90f62c23          	sw	a5,-1768(a2)
    82e8:	00150693          	addi	a3,a0,1
    82ec:	ffb227b7          	lui	a5,0xffb22

000082f0 <.L393>:
    82f0:	8407a603          	lw	a2,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    82f4:	fe061ee3          	bnez	a2,82f0 <.L393>
    82f8:	80e7a023          	sw	a4,-2048(a5)
    82fc:	8007a223          	sw	zero,-2044(a5)
    8300:	00275713          	srli	a4,a4,0x2
    8304:	000015b7          	lui	a1,0x1
    8308:	0ce00513          	li	a0,206
    830c:	00002637          	lui	a2,0x2
    8310:	80a7a423          	sw	a0,-2040(a5)
    8314:	00377713          	andi	a4,a4,3
    8318:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    831c:	09160613          	addi	a2,a2,145 # 2091 <_start-0x293f>
    8320:	80c7ae23          	sw	a2,-2020(a5)
    8324:	00b76733          	or	a4,a4,a1
    8328:	82e7a023          	sw	a4,-2016(a5)
    832c:	82d7a423          	sw	a3,-2008(a5)
    8330:	00100713          	li	a4,1
    8334:	84e7a023          	sw	a4,-1984(a5)
    8338:	000aa783          	lw	a5,0(s5)
    833c:	00e787b3          	add	a5,a5,a4
    8340:	00faa023          	sw	a5,0(s5)
    8344:	999ff06f          	j	7cdc <.L357>

00008348 <.L473>:
    8348:	ffb017b7          	lui	a5,0xffb01
    834c:	ffb00ab7          	lui	s5,0xffb00
    8350:	86c78793          	addi	a5,a5,-1940 # ffb0086c <sem_l1_base>
    8354:	00f12023          	sw	a5,0(sp)
    8358:	024a8a93          	addi	s5,s5,36 # ffb00024 <noc_nonposted_atomics_acked>
    835c:	8f5ff06f          	j	7c50 <.L368>

00008360 <.L398>:
    8360:	ffb004b7          	lui	s1,0xffb00
    8364:	03c48493          	addi	s1,s1,60 # ffb0003c <noc_reads_num_issued>
    8368:	0004a583          	lw	a1,0(s1)
    836c:	00000693          	li	a3,0
    8370:	b51ff06f          	j	7ec0 <.L404>

00008374 <.L429>:
    8374:	ffb01737          	lui	a4,0xffb01
    8378:	86c70713          	addi	a4,a4,-1940 # ffb0086c <sem_l1_base>
    837c:	0005a7b7          	lui	a5,0x5a
    8380:	ffb00ab7          	lui	s5,0xffb00
    8384:	00e12023          	sw	a4,0(sp)
    8388:	04010713          	addi	a4,sp,64
    838c:	44078793          	addi	a5,a5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    8390:	024a8a93          	addi	s5,s5,36 # ffb00024 <noc_nonposted_atomics_acked>
    8394:	00e12223          	sw	a4,4(sp)
    8398:	03c10813          	addi	a6,sp,60
    839c:	e49ff06f          	j	81e4 <.L407>

000083a0 <_Z23process_relay_paged_cmdILb0EEmmRmm.constprop.0.isra.0>:
    83a0:	ffb007b7          	lui	a5,0xffb00
    83a4:	f7010113          	addi	sp,sp,-144
    83a8:	03478793          	addi	a5,a5,52 # ffb00034 <noc_nonposted_writes_num_issued>
    83ac:	0007a603          	lw	a2,0(a5)
    83b0:	09212023          	sw	s2,128(sp)
    83b4:	02f12023          	sw	a5,32(sp)
    83b8:	08112623          	sw	ra,140(sp)
    83bc:	08812423          	sw	s0,136(sp)
    83c0:	08912223          	sw	s1,132(sp)
    83c4:	07312e23          	sw	s3,124(sp)
    83c8:	07512a23          	sw	s5,116(sp)
    83cc:	07712623          	sw	s7,108(sp)
    83d0:	07812423          	sw	s8,104(sp)
    83d4:	07a12023          	sw	s10,96(sp)
    83d8:	05b12e23          	sw	s11,92(sp)
    83dc:	00050793          	mv	a5,a0
    83e0:	00058913          	mv	s2,a1
    83e4:	ffb206b7          	lui	a3,0xffb20

000083e8 <.L480>:
    83e8:	2286a703          	lw	a4,552(a3) # ffb20228 <__stack_top+0x1e228>
    83ec:	fec71ee3          	bne	a4,a2,83e8 <.L480>
    83f0:	0ff0000f          	fence
    83f4:	0047ce83          	lbu	t4,4(a5)
    83f8:	0057c603          	lbu	a2,5(a5)
    83fc:	0067c503          	lbu	a0,6(a5)
    8400:	0077c303          	lbu	t1,7(a5)
    8404:	0087c703          	lbu	a4,8(a5)
    8408:	0097c683          	lbu	a3,9(a5)
    840c:	00a7c883          	lbu	a7,10(a5)
    8410:	00b7c983          	lbu	s3,11(a5)
    8414:	00c7ce03          	lbu	t3,12(a5)
    8418:	00d7c803          	lbu	a6,13(a5)
    841c:	00869693          	slli	a3,a3,0x8
    8420:	00e7c583          	lbu	a1,14(a5)
    8424:	00e6e6b3          	or	a3,a3,a4
    8428:	01089893          	slli	a7,a7,0x10
    842c:	00f7c703          	lbu	a4,15(a5)
    8430:	00881813          	slli	a6,a6,0x8
    8434:	01c86833          	or	a6,a6,t3
    8438:	00d8e8b3          	or	a7,a7,a3
    843c:	01059593          	slli	a1,a1,0x10
    8440:	01899993          	slli	s3,s3,0x18
    8444:	0027ce03          	lbu	t3,2(a5)
    8448:	0119e9b3          	or	s3,s3,a7
    844c:	0037c683          	lbu	a3,3(a5)
    8450:	01871713          	slli	a4,a4,0x18
    8454:	00861793          	slli	a5,a2,0x8
    8458:	0105e633          	or	a2,a1,a6
    845c:	01d7e7b3          	or	a5,a5,t4
    8460:	00c76733          	or	a4,a4,a2
    8464:	fff98593          	addi	a1,s3,-1
    8468:	03373633          	mulhu	a2,a4,s3
    846c:	01051513          	slli	a0,a0,0x10
    8470:	00f56533          	or	a0,a0,a5
    8474:	033707b3          	mul	a5,a4,s3
    8478:	01831313          	slli	t1,t1,0x18
    847c:	07f6f713          	andi	a4,a3,127
    8480:	00f5e693          	ori	a3,a1,15
    8484:	00a36eb3          	or	t4,t1,a0
    8488:	00168813          	addi	a6,a3,1
    848c:	00871713          	slli	a4,a4,0x8
    8490:	000105b7          	lui	a1,0x10
    8494:	01d12623          	sw	t4,12(sp)
    8498:	01012823          	sw	a6,16(sp)
    849c:	00078d93          	mv	s11,a5
    84a0:	01c76bb3          	or	s7,a4,t3
    84a4:	4b35f663          	bgeu	a1,s3,8950 <.L481>
    84a8:	888896b7          	lui	a3,0x88889
    84ac:	88968693          	addi	a3,a3,-1911 # 88888889 <__kernel_data_lma+0x8887cfd5>
    84b0:	02d936b3          	mulhu	a3,s2,a3
    84b4:	ffb00537          	lui	a0,0xffb00
    84b8:	0066d693          	srli	a3,a3,0x6
    84bc:	00469713          	slli	a4,a3,0x4
    84c0:	03068333          	mul	t1,a3,a6
    84c4:	40d70733          	sub	a4,a4,a3
    84c8:	00371713          	slli	a4,a4,0x3
    84cc:	40e90733          	sub	a4,s2,a4
    84d0:	66050513          	addi	a0,a0,1632 # ffb00660 <bank_to_l1_offset>
    84d4:	ffb006b7          	lui	a3,0xffb00
    84d8:	46468693          	addi	a3,a3,1124 # ffb00464 <l1_bank_to_noc_xy>
    84dc:	41778833          	sub	a6,a5,s7
    84e0:	00a12e23          	sw	a0,28(sp)
    84e4:	20a74533          	sh2add	a0,a4,a0
    84e8:	20d72733          	sh1add	a4,a4,a3
    84ec:	00052883          	lw	a7,0(a0)
    84f0:	0107b7b3          	sltu	a5,a5,a6
    84f4:	00075503          	lhu	a0,0(a4)
    84f8:	00d12c23          	sw	a3,24(sp)
    84fc:	40f606b3          	sub	a3,a2,a5
    8500:	011e8633          	add	a2,t4,a7
    8504:	00660633          	add	a2,a2,t1
    8508:	00451513          	slli	a0,a0,0x4
    850c:	00d12a23          	sw	a3,20(sp)
    8510:	00060893          	mv	a7,a2
    8514:	00050793          	mv	a5,a0
    8518:	00080c13          	mv	s8,a6
    851c:	5e068e63          	beqz	a3,8b18 <.L594>

00008520 <.L482>:
    8520:	ffff0bb7          	lui	s7,0xffff0
    8524:	01780bb3          	add	s7,a6,s7
    8528:	fff68693          	addi	a3,a3,-1
    852c:	010bb833          	sltu	a6,s7,a6
    8530:	00d80d33          	add	s10,a6,a3
    8534:	000105b7          	lui	a1,0x10

00008538 <.L484>:
    8538:	0005a8b7          	lui	a7,0x5a
    853c:	44088893          	addi	a7,a7,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    8540:	ffb004b7          	lui	s1,0xffb00
    8544:	10000eb7          	lui	t4,0x10000
    8548:	01000e37          	lui	t3,0x1000
    854c:	40c888b3          	sub	a7,a7,a2
    8550:	03c48493          	addi	s1,s1,60 # ffb0003c <noc_reads_num_issued>
    8554:	00fe8e93          	addi	t4,t4,15 # 1000000f <__kernel_data_lma+0xfff475b>
    8558:	fffe0e13          	addi	t3,t3,-1 # ffffff <__kernel_data_lma+0xff474b>
    855c:	00060813          	mv	a6,a2
    8560:	00050313          	mv	t1,a0
    8564:	00c58fb3          	add	t6,a1,a2
    8568:	ffb21737          	lui	a4,0xffb21
    856c:	000046b7          	lui	a3,0x4
    8570:	00100f13          	li	t5,1

00008574 <.L487>:
    8574:	010882b3          	add	t0,a7,a6

00008578 <.L486>:
    8578:	84072783          	lw	a5,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    857c:	fe079ee3          	bnez	a5,8578 <.L486>
    8580:	80572623          	sw	t0,-2036(a4)
    8584:	81072023          	sw	a6,-2048(a4)
    8588:	01d377b3          	and	a5,t1,t4
    858c:	80f72223          	sw	a5,-2044(a4)
    8590:	00435793          	srli	a5,t1,0x4
    8594:	01c7f7b3          	and	a5,a5,t3
    8598:	80f72423          	sw	a5,-2040(a4)
    859c:	82d72023          	sw	a3,-2016(a4)
    85a0:	85e72023          	sw	t5,-1984(a4)
    85a4:	0004a783          	lw	a5,0(s1)
    85a8:	00d802b3          	add	t0,a6,a3
    85ac:	00178793          	addi	a5,a5,1
    85b0:	00f4a023          	sw	a5,0(s1)
    85b4:	0102b7b3          	sltu	a5,t0,a6
    85b8:	00678333          	add	t1,a5,t1
    85bc:	405f87b3          	sub	a5,t6,t0
    85c0:	00028813          	mv	a6,t0
    85c4:	faf6e8e3          	bltu	a3,a5,8574 <.L487>
    85c8:	ffffc837          	lui	a6,0xffffc
    85cc:	fff80793          	addi	a5,a6,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    85d0:	00f587b3          	add	a5,a1,a5
    85d4:	00e7d713          	srli	a4,a5,0xe
    85d8:	0107f7b3          	and	a5,a5,a6
    85dc:	0005e837          	lui	a6,0x5e
    85e0:	00e71893          	slli	a7,a4,0xe
    85e4:	40d58333          	sub	t1,a1,a3
    85e8:	44080813          	addi	a6,a6,1088 # 5e440 <__kernel_data_lma+0x52b8c>
    85ec:	00d606b3          	add	a3,a2,a3
    85f0:	00088713          	mv	a4,a7
    85f4:	01078833          	add	a6,a5,a6
    85f8:	011688b3          	add	a7,a3,a7
    85fc:	00c6b7b3          	sltu	a5,a3,a2
    8600:	00a787b3          	add	a5,a5,a0
    8604:	00d8b6b3          	sltu	a3,a7,a3
    8608:	00058413          	mv	s0,a1
    860c:	00f687b3          	add	a5,a3,a5
    8610:	40e305b3          	sub	a1,t1,a4

00008614 <.L485>:
    8614:	ffb216b7          	lui	a3,0xffb21

00008618 <.L488>:
    8618:	8406a703          	lw	a4,-1984(a3) # ffb20840 <__stack_top+0x1e840>
    861c:	fe071ee3          	bnez	a4,8618 <.L488>
    8620:	8106a623          	sw	a6,-2036(a3)
    8624:	8116a023          	sw	a7,-2048(a3)
    8628:	00f7f613          	andi	a2,a5,15
    862c:	80c6a223          	sw	a2,-2044(a3)
    8630:	0047d793          	srli	a5,a5,0x4
    8634:	80f6a423          	sw	a5,-2040(a3)
    8638:	82b6a023          	sw	a1,-2016(a3)
    863c:	00100793          	li	a5,1
    8640:	84f6a023          	sw	a5,-1984(a3)
    8644:	0004a783          	lw	a5,0(s1)
    8648:	ffb206b7          	lui	a3,0xffb20
    864c:	00178793          	addi	a5,a5,1
    8650:	00f4a023          	sw	a5,0(s1)

00008654 <.L489>:
    8654:	2086a603          	lw	a2,520(a3) # ffb20208 <__stack_top+0x1e208>
    8658:	fef61ee3          	bne	a2,a5,8654 <.L489>
    865c:	0ff0000f          	fence
    8660:	01abe7b3          	or	a5,s7,s10
    8664:	4c078ce3          	beqz	a5,933c <.L595>
    8668:	ffb01537          	lui	a0,0xffb01
    866c:	888897b7          	lui	a5,0x88889
    8670:	90050693          	addi	a3,a0,-1792 # ffb00900 <_ZL14scratch_db_top>
    8674:	88978793          	addi	a5,a5,-1911 # 88888889 <__kernel_data_lma+0x8887cfd5>
    8678:	ffb015b7          	lui	a1,0xffb01
    867c:	ffb00ab7          	lui	s5,0xffb00
    8680:	07612823          	sw	s6,112(sp)
    8684:	07912223          	sw	s9,100(sp)
    8688:	10000b37          	lui	s6,0x10000
    868c:	01000cb7          	lui	s9,0x1000
    8690:	00d12423          	sw	a3,8(sp)
    8694:	02f12223          	sw	a5,36(sp)
    8698:	86c58693          	addi	a3,a1,-1940 # ffb0086c <sem_l1_base>
    869c:	04010793          	addi	a5,sp,64
    86a0:	07412c23          	sw	s4,120(sp)
    86a4:	00d12023          	sw	a3,0(sp)
    86a8:	40898a33          	sub	s4,s3,s0
    86ac:	024a8e93          	addi	t4,s5,36 # ffb00024 <noc_nonposted_atomics_acked>
    86b0:	00fb0b13          	addi	s6,s6,15 # 1000000f <__kernel_data_lma+0xfff475b>
    86b4:	00098a93          	mv	s5,s3
    86b8:	fffc8c93          	addi	s9,s9,-1 # ffffff <__kernel_data_lma+0xff474b>
    86bc:	00040d93          	mv	s11,s0
    86c0:	00000693          	li	a3,0
    86c4:	00f12223          	sw	a5,4(sp)
    86c8:	00070993          	mv	s3,a4

000086cc <.L512>:
    86cc:	02012783          	lw	a5,32(sp)
    86d0:	ffb20737          	lui	a4,0xffb20
    86d4:	0007a603          	lw	a2,0(a5)

000086d8 <.L492>:
    86d8:	22872783          	lw	a5,552(a4) # ffb20228 <__stack_top+0x1e228>
    86dc:	fec79ee3          	bne	a5,a2,86d8 <.L492>
    86e0:	0ff0000f          	fence
    86e4:	00812583          	lw	a1,8(sp)
    86e8:	02412783          	lw	a5,36(sp)
    86ec:	00c12703          	lw	a4,12(sp)
    86f0:	01012503          	lw	a0,16(sp)
    86f4:	00870633          	add	a2,a4,s0
    86f8:	20b6c733          	sh2add	a4,a3,a1
    86fc:	02f936b3          	mulhu	a3,s2,a5
    8700:	0066d693          	srli	a3,a3,0x6
    8704:	00469793          	slli	a5,a3,0x4
    8708:	02a688b3          	mul	a7,a3,a0
    870c:	40d787b3          	sub	a5,a5,a3
    8710:	00c888b3          	add	a7,a7,a2
    8714:	01c12683          	lw	a3,28(sp)
    8718:	01812603          	lw	a2,24(sp)
    871c:	00379793          	slli	a5,a5,0x3
    8720:	40f907b3          	sub	a5,s2,a5
    8724:	20d7c6b3          	sh2add	a3,a5,a3
    8728:	20c7a7b3          	sh1add	a5,a5,a2
    872c:	0006a683          	lw	a3,0(a3)
    8730:	0007d303          	lhu	t1,0(a5)
    8734:	00d888b3          	add	a7,a7,a3
    8738:	0019c993          	xori	s3,s3,1
    873c:	00072683          	lw	a3,0(a4)
    8740:	20b9c7b3          	sh2add	a5,s3,a1
    8744:	00431313          	slli	t1,t1,0x4
    8748:	00010737          	lui	a4,0x10
    874c:	0007a783          	lw	a5,0(a5)
    8750:	00088593          	mv	a1,a7
    8754:	00030613          	mv	a2,t1
    8758:	41476263          	bltu	a4,s4,8b5c <.L493>
    875c:	00004837          	lui	a6,0x4
    8760:	334872e3          	bgeu	a6,s4,9284 <.L545>
    8764:	00030513          	mv	a0,t1
    8768:	41178fb3          	sub	t6,a5,a7
    876c:	01488f33          	add	t5,a7,s4
    8770:	ffb21637          	lui	a2,0xffb21
    8774:	00100e13          	li	t3,1

00008778 <.L496>:
    8778:	00bf82b3          	add	t0,t6,a1

0000877c <.L495>:
    877c:	84062703          	lw	a4,-1984(a2) # ffb20840 <__stack_top+0x1e840>
    8780:	fe071ee3          	bnez	a4,877c <.L495>
    8784:	80562623          	sw	t0,-2036(a2)
    8788:	80b62023          	sw	a1,-2048(a2)
    878c:	01657733          	and	a4,a0,s6
    8790:	80e62223          	sw	a4,-2044(a2)
    8794:	00455713          	srli	a4,a0,0x4
    8798:	01977733          	and	a4,a4,s9
    879c:	80e62423          	sw	a4,-2040(a2)
    87a0:	83062023          	sw	a6,-2016(a2)
    87a4:	85c62023          	sw	t3,-1984(a2)
    87a8:	0004a703          	lw	a4,0(s1)
    87ac:	010582b3          	add	t0,a1,a6
    87b0:	00170713          	addi	a4,a4,1 # 10001 <__kernel_data_lma+0x474d>
    87b4:	00e4a023          	sw	a4,0(s1)
    87b8:	00b2b733          	sltu	a4,t0,a1
    87bc:	00a70533          	add	a0,a4,a0
    87c0:	405f0733          	sub	a4,t5,t0
    87c4:	00028593          	mv	a1,t0
    87c8:	fae868e3          	bltu	a6,a4,8778 <.L496>
    87cc:	ffffc5b7          	lui	a1,0xffffc
    87d0:	fff58713          	addi	a4,a1,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    87d4:	00ea0733          	add	a4,s4,a4
    87d8:	00e75613          	srli	a2,a4,0xe
    87dc:	410a0533          	sub	a0,s4,a6
    87e0:	00b77733          	and	a4,a4,a1
    87e4:	00e61593          	slli	a1,a2,0xe
    87e8:	00160613          	addi	a2,a2,1
    87ec:	40b50533          	sub	a0,a0,a1
    87f0:	00e61593          	slli	a1,a2,0xe
    87f4:	00f70733          	add	a4,a4,a5
    87f8:	01265613          	srli	a2,a2,0x12
    87fc:	00b885b3          	add	a1,a7,a1
    8800:	01070733          	add	a4,a4,a6
    8804:	0115b8b3          	sltu	a7,a1,a7
    8808:	00c30833          	add	a6,t1,a2
    880c:	01088633          	add	a2,a7,a6

00008810 <.L494>:
    8810:	ffb21837          	lui	a6,0xffb21

00008814 <.L497>:
    8814:	84082403          	lw	s0,-1984(a6) # ffb20840 <__stack_top+0x1e840>
    8818:	fe041ee3          	bnez	s0,8814 <.L497>
    881c:	80e82623          	sw	a4,-2036(a6)
    8820:	80b82023          	sw	a1,-2048(a6)
    8824:	01667733          	and	a4,a2,s6
    8828:	80e82223          	sw	a4,-2044(a6)
    882c:	00465613          	srli	a2,a2,0x4
    8830:	80c82423          	sw	a2,-2040(a6)
    8834:	82a82023          	sw	a0,-2016(a6)
    8838:	00100713          	li	a4,1
    883c:	84e82023          	sw	a4,-1984(a6)
    8840:	0004a703          	lw	a4,0(s1)
    8844:	00190913          	addi	s2,s2,1
    8848:	00170713          	addi	a4,a4,1
    884c:	00e4a023          	sw	a4,0(s1)
    8850:	00010737          	lui	a4,0x10
    8854:	00ea0663          	beq	s4,a4,8860 <.L592>
    8858:	4a0d1063          	bnez	s10,8cf8 <.L556>
    885c:	497a6e63          	bltu	s4,s7,8cf8 <.L556>

00008860 <.L592>:
    8860:	000a0613          	mv	a2,s4
    8864:	000a8a13          	mv	s4,s5

00008868 <.L498>:
    8868:	01412703          	lw	a4,20(sp)
    886c:	000d8793          	mv	a5,s11
    8870:	2c071c63          	bnez	a4,8b48 <.L507>
    8874:	2dbc7a63          	bgeu	s8,s11,8b48 <.L507>
    8878:	000c0d93          	mv	s11,s8
    887c:	000c0793          	mv	a5,s8
    8880:	00000b93          	li	s7,0
    8884:	00000d13          	li	s10,0

00008888 <.L509>:
    8888:	40fc07b3          	sub	a5,s8,a5
    888c:	01412703          	lw	a4,20(sp)
    8890:	00fc3c33          	sltu	s8,s8,a5
    8894:	00412503          	lw	a0,4(sp)
    8898:	41870733          	sub	a4,a4,s8
    889c:	04410593          	addi	a1,sp,68
    88a0:	03d12623          	sw	t4,44(sp)
    88a4:	02c12423          	sw	a2,40(sp)
    88a8:	00e12a23          	sw	a4,20(sp)
    88ac:	04d12023          	sw	a3,64(sp)
    88b0:	00078c13          	mv	s8,a5
    88b4:	05b12223          	sw	s11,68(sp)
    88b8:	a6cfd0ef          	jal	5b24 <_Z25write_pages_to_dispatcherILl0ELb0EEmRmS0_S0_.constprop.0>
    88bc:	00012783          	lw	a5,0(sp)
    88c0:	02812603          	lw	a2,40(sp)
    88c4:	0007a683          	lw	a3,0(a5)
    88c8:	02c12e83          	lw	t4,44(sp)
    88cc:	00050593          	mv	a1,a0
    88d0:	ffb22737          	lui	a4,0xffb22

000088d4 <.L510>:
    88d4:	84072783          	lw	a5,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    88d8:	fe079ee3          	bnez	a5,88d4 <.L510>
    88dc:	80d72023          	sw	a3,-2048(a4)
    88e0:	0026d793          	srli	a5,a3,0x2
    88e4:	000016b7          	lui	a3,0x1
    88e8:	07c68693          	addi	a3,a3,124 # 107c <_start-0x3954>
    88ec:	0037f793          	andi	a5,a5,3
    88f0:	80072223          	sw	zero,-2044(a4)
    88f4:	00d7e7b3          	or	a5,a5,a3
    88f8:	0ce00693          	li	a3,206
    88fc:	80d72423          	sw	a3,-2040(a4)
    8900:	000026b7          	lui	a3,0x2
    8904:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    8908:	80d72e23          	sw	a3,-2020(a4)
    890c:	82f72023          	sw	a5,-2016(a4)
    8910:	82b72423          	sw	a1,-2008(a4)
    8914:	00100793          	li	a5,1
    8918:	84f72023          	sw	a5,-1984(a4)
    891c:	000ea783          	lw	a5,0(t4)
    8920:	0004a683          	lw	a3,0(s1)
    8924:	00178793          	addi	a5,a5,1
    8928:	00fea023          	sw	a5,0(t4)
    892c:	ffb20737          	lui	a4,0xffb20

00008930 <.L511>:
    8930:	20872783          	lw	a5,520(a4) # ffb20208 <__stack_top+0x1e208>
    8934:	fed79ee3          	bne	a5,a3,8930 <.L511>
    8938:	0ff0000f          	fence
    893c:	01abe7b3          	or	a5,s7,s10
    8940:	2e078463          	beqz	a5,8c28 <.L596>
    8944:	00060d93          	mv	s11,a2
    8948:	00098693          	mv	a3,s3
    894c:	d81ff06f          	j	86cc <.L512>

00008950 <.L481>:
    8950:	00c12703          	lw	a4,12(sp)
    8954:	07412c23          	sw	s4,120(sp)
    8958:	04e12223          	sw	a4,68(sp)
    895c:	01012703          	lw	a4,16(sp)
    8960:	07612823          	sw	s6,112(sp)
    8964:	07912223          	sw	s9,100(sp)
    8968:	04e12623          	sw	a4,76(sp)
    896c:	00078413          	mv	s0,a5
    8970:	18060e63          	beqz	a2,8b0c <.L597>
    8974:	00010437          	lui	s0,0x10

00008978 <.L518>:
    8978:	1d346ee3          	bltu	s0,s3,9354 <.L520>
    897c:	ffffc6b7          	lui	a3,0xffffc
    8980:	fff68713          	addi	a4,a3,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    8984:	00e98733          	add	a4,s3,a4
    8988:	00e75293          	srli	t0,a4,0xe
    898c:	000048b7          	lui	a7,0x4
    8990:	00d77733          	and	a4,a4,a3
    8994:	411983b3          	sub	t2,s3,a7
    8998:	00e29693          	slli	a3,t0,0xe
    899c:	ffb00537          	lui	a0,0xffb00
    89a0:	40d383b3          	sub	t2,t2,a3
    89a4:	01170fb3          	add	t6,a4,a7
    89a8:	ffb006b7          	lui	a3,0xffb00
    89ac:	66050713          	addi	a4,a0,1632 # ffb00660 <bank_to_l1_offset>
    89b0:	00128293          	addi	t0,t0,1
    89b4:	ffb004b7          	lui	s1,0xffb00
    89b8:	0005a837          	lui	a6,0x5a
    89bc:	888895b7          	lui	a1,0x88889
    89c0:	10000337          	lui	t1,0x10000
    89c4:	01000e37          	lui	t3,0x1000
    89c8:	00e12e23          	sw	a4,28(sp)
    89cc:	00c12a83          	lw	s5,12(sp)
    89d0:	46468713          	addi	a4,a3,1124 # ffb00464 <l1_bank_to_noc_xy>
    89d4:	01012e83          	lw	t4,16(sp)
    89d8:	00e12c23          	sw	a4,24(sp)
    89dc:	0122da13          	srli	s4,t0,0x12
    89e0:	03c48493          	addi	s1,s1,60 # ffb0003c <noc_reads_num_issued>
    89e4:	44080c93          	addi	s9,a6,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    89e8:	88958d13          	addi	s10,a1,-1911 # 88888889 <__kernel_data_lma+0x8887cfd5>
    89ec:	00f30313          	addi	t1,t1,15 # 1000000f <__kernel_data_lma+0xfff475b>
    89f0:	fffe0e13          	addi	t3,t3,-1 # ffffff <__kernel_data_lma+0xff474b>
    89f4:	00000693          	li	a3,0
    89f8:	ffb21737          	lui	a4,0xffb21
    89fc:	00100f13          	li	t5,1

00008a00 <.L527>:
    8a00:	03a93533          	mulhu	a0,s2,s10
    8a04:	01968833          	add	a6,a3,s9
    8a08:	00655513          	srli	a0,a0,0x6
    8a0c:	00451593          	slli	a1,a0,0x4
    8a10:	03d50b33          	mul	s6,a0,t4
    8a14:	40a585b3          	sub	a1,a1,a0
    8a18:	01812e83          	lw	t4,24(sp)
    8a1c:	01c12503          	lw	a0,28(sp)
    8a20:	00359593          	slli	a1,a1,0x3
    8a24:	40b905b3          	sub	a1,s2,a1
    8a28:	20a5c533          	sh2add	a0,a1,a0
    8a2c:	21d5a5b3          	sh1add	a1,a1,t4
    8a30:	00052503          	lw	a0,0(a0)
    8a34:	0005dc03          	lhu	s8,0(a1)
    8a38:	015b0b33          	add	s6,s6,s5
    8a3c:	00ab0b33          	add	s6,s6,a0
    8a40:	004c1c13          	slli	s8,s8,0x4
    8a44:	000b0513          	mv	a0,s6
    8a48:	000c0e93          	mv	t4,s8
    8a4c:	4538f463          	bgeu	a7,s3,8e94 <.L550>
    8a50:	010f8ab3          	add	s5,t6,a6

00008a54 <.L522>:
    8a54:	84072583          	lw	a1,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    8a58:	fe059ee3          	bnez	a1,8a54 <.L522>
    8a5c:	81072623          	sw	a6,-2036(a4)
    8a60:	80a72023          	sw	a0,-2048(a4)
    8a64:	006ef5b3          	and	a1,t4,t1
    8a68:	80b72223          	sw	a1,-2044(a4)
    8a6c:	004ed593          	srli	a1,t4,0x4
    8a70:	01c5f5b3          	and	a1,a1,t3
    8a74:	80b72423          	sw	a1,-2040(a4)
    8a78:	83172023          	sw	a7,-2016(a4)
    8a7c:	85e72023          	sw	t5,-1984(a4)
    8a80:	0004a583          	lw	a1,0(s1)
    8a84:	01180833          	add	a6,a6,a7
    8a88:	00158593          	addi	a1,a1,1
    8a8c:	00b4a023          	sw	a1,0(s1)
    8a90:	011505b3          	add	a1,a0,a7
    8a94:	00a5b533          	sltu	a0,a1,a0
    8a98:	01d50eb3          	add	t4,a0,t4
    8a9c:	00058513          	mv	a0,a1
    8aa0:	fb0a9ae3          	bne	s5,a6,8a54 <.L522>
    8aa4:	00e29513          	slli	a0,t0,0xe
    8aa8:	00ab0533          	add	a0,s6,a0
    8aac:	014c0c33          	add	s8,s8,s4
    8ab0:	01653b33          	sltu	s6,a0,s6
    8ab4:	018b0eb3          	add	t4,s6,s8
    8ab8:	00038813          	mv	a6,t2

00008abc <.L524>:
    8abc:	84072583          	lw	a1,-1984(a4)
    8ac0:	fe059ee3          	bnez	a1,8abc <.L524>
    8ac4:	81572623          	sw	s5,-2036(a4)
    8ac8:	80a72023          	sw	a0,-2048(a4)
    8acc:	006ef5b3          	and	a1,t4,t1
    8ad0:	80b72223          	sw	a1,-2044(a4)
    8ad4:	004ede93          	srli	t4,t4,0x4
    8ad8:	81d72423          	sw	t4,-2040(a4)
    8adc:	83072023          	sw	a6,-2016(a4)
    8ae0:	85e72023          	sw	t5,-1984(a4)
    8ae4:	0004a583          	lw	a1,0(s1)
    8ae8:	013686b3          	add	a3,a3,s3
    8aec:	00158593          	addi	a1,a1,1
    8af0:	00b4a023          	sw	a1,0(s1)
    8af4:	40d40533          	sub	a0,s0,a3
    8af8:	00190913          	addi	s2,s2,1
    8afc:	3b356263          	bltu	a0,s3,8ea0 <.L598>
    8b00:	04c12e83          	lw	t4,76(sp)
    8b04:	04412a83          	lw	s5,68(sp)
    8b08:	ef9ff06f          	j	8a00 <.L527>

00008b0c <.L597>:
    8b0c:	e6f5f6e3          	bgeu	a1,a5,8978 <.L518>
    8b10:	00010437          	lui	s0,0x10
    8b14:	e65ff06f          	j	8978 <.L518>

00008b18 <.L594>:
    8b18:	a105e4e3          	bltu	a1,a6,8520 <.L482>
    8b1c:	00004737          	lui	a4,0x4
    8b20:	00080593          	mv	a1,a6
    8b24:	00000b93          	li	s7,0
    8b28:	00000d13          	li	s10,0
    8b2c:	a10766e3          	bltu	a4,a6,8538 <.L484>
    8b30:	0005a837          	lui	a6,0x5a
    8b34:	ffb004b7          	lui	s1,0xffb00
    8b38:	44080813          	addi	a6,a6,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    8b3c:	03c48493          	addi	s1,s1,60 # ffb0003c <noc_reads_num_issued>
    8b40:	000c0413          	mv	s0,s8
    8b44:	ad1ff06f          	j	8614 <.L485>

00008b48 <.L507>:
    8b48:	40cb8733          	sub	a4,s7,a2
    8b4c:	00ebbbb3          	sltu	s7,s7,a4
    8b50:	417d0d33          	sub	s10,s10,s7
    8b54:	00070b93          	mv	s7,a4
    8b58:	d31ff06f          	j	8888 <.L509>

00008b5c <.L493>:
    8b5c:	0000ce37          	lui	t3,0xc
    8b60:	01c78e33          	add	t3,a5,t3
    8b64:	00030513          	mv	a0,t1
    8b68:	ffb21637          	lui	a2,0xffb21
    8b6c:	00004837          	lui	a6,0x4
    8b70:	00100f13          	li	t5,1

00008b74 <.L504>:
    8b74:	84062703          	lw	a4,-1984(a2) # ffb20840 <__stack_top+0x1e840>
    8b78:	fe071ee3          	bnez	a4,8b74 <.L504>
    8b7c:	80f62623          	sw	a5,-2036(a2)
    8b80:	80b62023          	sw	a1,-2048(a2)
    8b84:	01657733          	and	a4,a0,s6
    8b88:	80e62223          	sw	a4,-2044(a2)
    8b8c:	00455713          	srli	a4,a0,0x4
    8b90:	01977733          	and	a4,a4,s9
    8b94:	80e62423          	sw	a4,-2040(a2)
    8b98:	83062023          	sw	a6,-2016(a2)
    8b9c:	85e62023          	sw	t5,-1984(a2)
    8ba0:	0004a703          	lw	a4,0(s1)
    8ba4:	010787b3          	add	a5,a5,a6
    8ba8:	00170713          	addi	a4,a4,1 # 4001 <_start-0x9cf>
    8bac:	00e4a023          	sw	a4,0(s1)
    8bb0:	01058733          	add	a4,a1,a6
    8bb4:	00b735b3          	sltu	a1,a4,a1
    8bb8:	00a58533          	add	a0,a1,a0
    8bbc:	00070593          	mv	a1,a4
    8bc0:	fbc79ae3          	bne	a5,t3,8b74 <.L504>
    8bc4:	0000c637          	lui	a2,0xc
    8bc8:	00c88633          	add	a2,a7,a2
    8bcc:	011637b3          	sltu	a5,a2,a7
    8bd0:	006787b3          	add	a5,a5,t1
    8bd4:	ffb21737          	lui	a4,0xffb21

00008bd8 <.L506>:
    8bd8:	84072583          	lw	a1,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    8bdc:	fe059ee3          	bnez	a1,8bd8 <.L506>
    8be0:	81c72623          	sw	t3,-2036(a4)
    8be4:	80c72023          	sw	a2,-2048(a4)
    8be8:	0167f633          	and	a2,a5,s6
    8bec:	80c72223          	sw	a2,-2044(a4)
    8bf0:	0047d793          	srli	a5,a5,0x4
    8bf4:	80f72423          	sw	a5,-2040(a4)
    8bf8:	000047b7          	lui	a5,0x4
    8bfc:	82f72023          	sw	a5,-2016(a4)
    8c00:	00100793          	li	a5,1
    8c04:	84f72023          	sw	a5,-1984(a4)
    8c08:	0004a783          	lw	a5,0(s1)
    8c0c:	ffff0737          	lui	a4,0xffff0
    8c10:	00178793          	addi	a5,a5,1 # 4001 <_start-0x9cf>
    8c14:	00010637          	lui	a2,0x10
    8c18:	00c40433          	add	s0,s0,a2
    8c1c:	00f4a023          	sw	a5,0(s1)
    8c20:	00ea0a33          	add	s4,s4,a4
    8c24:	c45ff06f          	j	8868 <.L498>

00008c28 <.L596>:
    8c28:	07812a03          	lw	s4,120(sp)
    8c2c:	07012b03          	lw	s6,112(sp)
    8c30:	06412c83          	lw	s9,100(sp)
    8c34:	00098713          	mv	a4,s3
    8c38:	000e8a93          	mv	s5,t4

00008c3c <.L490>:
    8c3c:	01412783          	lw	a5,20(sp)
    8c40:	00fc67b3          	or	a5,s8,a5
    8c44:	64079663          	bnez	a5,9290 <.L599>
    8c48:	00012783          	lw	a5,0(sp)
    8c4c:	ffb01637          	lui	a2,0xffb01
    8c50:	0007a703          	lw	a4,0(a5)
    8c54:	000016b7          	lui	a3,0x1
    8c58:	91862783          	lw	a5,-1768(a2) # ffb00918 <_ZL19downstream_data_ptr>
    8c5c:	fff68693          	addi	a3,a3,-1 # fff <_start-0x39d1>
    8c60:	00d787b3          	add	a5,a5,a3
    8c64:	fffff6b7          	lui	a3,0xfffff
    8c68:	00d7f7b3          	and	a5,a5,a3
    8c6c:	90f62c23          	sw	a5,-1768(a2)
    8c70:	ffb227b7          	lui	a5,0xffb22

00008c74 <.L517>:
    8c74:	8407a683          	lw	a3,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    8c78:	fe069ee3          	bnez	a3,8c74 <.L517>
    8c7c:	80e7a023          	sw	a4,-2048(a5)
    8c80:	8007a223          	sw	zero,-2044(a5)
    8c84:	00275713          	srli	a4,a4,0x2
    8c88:	00001637          	lui	a2,0x1
    8c8c:	0ce00593          	li	a1,206
    8c90:	000026b7          	lui	a3,0x2
    8c94:	80b7a423          	sw	a1,-2040(a5)
    8c98:	00377713          	andi	a4,a4,3
    8c9c:	07c60613          	addi	a2,a2,124 # 107c <_start-0x3954>
    8ca0:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    8ca4:	80d7ae23          	sw	a3,-2020(a5)
    8ca8:	00c76733          	or	a4,a4,a2
    8cac:	82e7a023          	sw	a4,-2016(a5)
    8cb0:	00100713          	li	a4,1
    8cb4:	82e7a423          	sw	a4,-2008(a5)
    8cb8:	84e7a023          	sw	a4,-1984(a5)
    8cbc:	000aa783          	lw	a5,0(s5)
    8cc0:	00e787b3          	add	a5,a5,a4
    8cc4:	00faa023          	sw	a5,0(s5)

00008cc8 <.L479>:
    8cc8:	08c12083          	lw	ra,140(sp)
    8ccc:	08812403          	lw	s0,136(sp)
    8cd0:	08412483          	lw	s1,132(sp)
    8cd4:	08012903          	lw	s2,128(sp)
    8cd8:	07c12983          	lw	s3,124(sp)
    8cdc:	07412a83          	lw	s5,116(sp)
    8ce0:	06c12b83          	lw	s7,108(sp)
    8ce4:	06812c03          	lw	s8,104(sp)
    8ce8:	06012d03          	lw	s10,96(sp)
    8cec:	05c12d83          	lw	s11,92(sp)
    8cf0:	09010113          	addi	sp,sp,144
    8cf4:	00008067          	ret

00008cf8 <.L556>:
    8cf8:	888895b7          	lui	a1,0x88889
    8cfc:	88958593          	addi	a1,a1,-1911 # 88888889 <__kernel_data_lma+0x8887cfd5>
    8d00:	02b935b3          	mulhu	a1,s2,a1
    8d04:	01012603          	lw	a2,16(sp)
    8d08:	0065d593          	srli	a1,a1,0x6
    8d0c:	00459713          	slli	a4,a1,0x4
    8d10:	02c58633          	mul	a2,a1,a2
    8d14:	40b70733          	sub	a4,a4,a1
    8d18:	01812503          	lw	a0,24(sp)
    8d1c:	01c12583          	lw	a1,28(sp)
    8d20:	00371713          	slli	a4,a4,0x3
    8d24:	40e90733          	sub	a4,s2,a4
    8d28:	20b745b3          	sh2add	a1,a4,a1
    8d2c:	20a72733          	sh1add	a4,a4,a0
    8d30:	00075883          	lhu	a7,0(a4) # ffff0000 <__instrn_buffer+0x1b0000>
    8d34:	00c12703          	lw	a4,12(sp)
    8d38:	0005a583          	lw	a1,0(a1)
    8d3c:	00e60633          	add	a2,a2,a4
    8d40:	00010437          	lui	s0,0x10
    8d44:	ffff4537          	lui	a0,0xffff4
    8d48:	00b605b3          	add	a1,a2,a1
    8d4c:	00489893          	slli	a7,a7,0x4
    8d50:	41440433          	sub	s0,s0,s4
    8d54:	00aa0533          	add	a0,s4,a0
    8d58:	00004837          	lui	a6,0x4
    8d5c:	014787b3          	add	a5,a5,s4
    8d60:	00058313          	mv	t1,a1
    8d64:	00088713          	mv	a4,a7
    8d68:	00040613          	mv	a2,s0
    8d6c:	0ca87863          	bgeu	a6,a0,8e3c <.L500>
    8d70:	10000e37          	lui	t3,0x10000
    8d74:	01000737          	lui	a4,0x1000
    8d78:	00fe0e13          	addi	t3,t3,15 # 1000000f <__kernel_data_lma+0xfff475b>
    8d7c:	fff70713          	addi	a4,a4,-1 # ffffff <__kernel_data_lma+0xff474b>
    8d80:	00058513          	mv	a0,a1
    8d84:	00088313          	mv	t1,a7
    8d88:	40b782b3          	sub	t0,a5,a1
    8d8c:	00b40fb3          	add	t6,s0,a1
    8d90:	ffb21637          	lui	a2,0xffb21
    8d94:	00100f13          	li	t5,1
    8d98:	03512423          	sw	s5,40(sp)

00008d9c <.L502>:
    8d9c:	00a28ab3          	add	s5,t0,a0

00008da0 <.L501>:
    8da0:	84062383          	lw	t2,-1984(a2) # ffb20840 <__stack_top+0x1e840>
    8da4:	fe039ee3          	bnez	t2,8da0 <.L501>
    8da8:	81562623          	sw	s5,-2036(a2)
    8dac:	80a62023          	sw	a0,-2048(a2)
    8db0:	01c373b3          	and	t2,t1,t3
    8db4:	80762223          	sw	t2,-2044(a2)
    8db8:	00435393          	srli	t2,t1,0x4
    8dbc:	00e3f3b3          	and	t2,t2,a4
    8dc0:	80762423          	sw	t2,-2040(a2)
    8dc4:	83062023          	sw	a6,-2016(a2)
    8dc8:	85e62023          	sw	t5,-1984(a2)
    8dcc:	0004a383          	lw	t2,0(s1)
    8dd0:	01050ab3          	add	s5,a0,a6
    8dd4:	00138393          	addi	t2,t2,1
    8dd8:	0074a023          	sw	t2,0(s1)
    8ddc:	00aab3b3          	sltu	t2,s5,a0
    8de0:	00638333          	add	t1,t2,t1
    8de4:	415f83b3          	sub	t2,t6,s5
    8de8:	000a8513          	mv	a0,s5
    8dec:	fa7868e3          	bltu	a6,t2,8d9c <.L502>
    8df0:	0000c637          	lui	a2,0xc
    8df4:	fff60513          	addi	a0,a2,-1 # bfff <__kernel_data_lma+0x74b>
    8df8:	41450533          	sub	a0,a0,s4
    8dfc:	00e55713          	srli	a4,a0,0xe
    8e00:	00e71313          	slli	t1,a4,0xe
    8e04:	41460633          	sub	a2,a2,s4
    8e08:	00170713          	addi	a4,a4,1
    8e0c:	40660633          	sub	a2,a2,t1
    8e10:	ffffc337          	lui	t1,0xffffc
    8e14:	00657533          	and	a0,a0,t1
    8e18:	00e71313          	slli	t1,a4,0xe
    8e1c:	00658333          	add	t1,a1,t1
    8e20:	01275713          	srli	a4,a4,0x12
    8e24:	00f507b3          	add	a5,a0,a5
    8e28:	00b335b3          	sltu	a1,t1,a1
    8e2c:	00e88733          	add	a4,a7,a4
    8e30:	02812a83          	lw	s5,40(sp)
    8e34:	010787b3          	add	a5,a5,a6
    8e38:	00e58733          	add	a4,a1,a4

00008e3c <.L500>:
    8e3c:	ffb215b7          	lui	a1,0xffb21

00008e40 <.L503>:
    8e40:	8405a503          	lw	a0,-1984(a1) # ffb20840 <__stack_top+0x1e840>
    8e44:	fe051ee3          	bnez	a0,8e40 <.L503>
    8e48:	80f5a623          	sw	a5,-2036(a1)
    8e4c:	100007b7          	lui	a5,0x10000
    8e50:	00f78793          	addi	a5,a5,15 # 1000000f <__kernel_data_lma+0xfff475b>
    8e54:	8065a023          	sw	t1,-2048(a1)
    8e58:	00f777b3          	and	a5,a4,a5
    8e5c:	80f5a223          	sw	a5,-2044(a1)
    8e60:	00475713          	srli	a4,a4,0x4
    8e64:	80e5a423          	sw	a4,-2040(a1)
    8e68:	82c5a023          	sw	a2,-2016(a1)
    8e6c:	00100793          	li	a5,1
    8e70:	84f5a023          	sw	a5,-1984(a1)
    8e74:	0004a703          	lw	a4,0(s1)
    8e78:	ffff07b7          	lui	a5,0xffff0
    8e7c:	00170713          	addi	a4,a4,1
    8e80:	00fa87b3          	add	a5,s5,a5
    8e84:	00e4a023          	sw	a4,0(s1)
    8e88:	00fa0a33          	add	s4,s4,a5
    8e8c:	00010637          	lui	a2,0x10
    8e90:	9d9ff06f          	j	8868 <.L498>

00008e94 <.L550>:
    8e94:	00080a93          	mv	s5,a6
    8e98:	00098813          	mv	a6,s3
    8e9c:	c21ff06f          	j	8abc <.L524>

00008ea0 <.L598>:
    8ea0:	40d78733          	sub	a4,a5,a3
    8ea4:	00e7b7b3          	sltu	a5,a5,a4
    8ea8:	40f60633          	sub	a2,a2,a5
    8eac:	00070d93          	mv	s11,a4

00008eb0 <.L526>:
    8eb0:	ffb207b7          	lui	a5,0xffb20

00008eb4 <.L528>:
    8eb4:	2087a703          	lw	a4,520(a5) # ffb20208 <__stack_top+0x1e208>
    8eb8:	feb71ee3          	bne	a4,a1,8eb4 <.L528>
    8ebc:	0ff0000f          	fence
    8ec0:	00cdec33          	or	s8,s11,a2
    8ec4:	4a0c0263          	beqz	s8,9368 <.L551>
    8ec8:	ffffc7b7          	lui	a5,0xffffc
    8ecc:	fff78713          	addi	a4,a5,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    8ed0:	00e98733          	add	a4,s3,a4
    8ed4:	00f777b3          	and	a5,a4,a5
    8ed8:	ffb01537          	lui	a0,0xffb01
    8edc:	00004437          	lui	s0,0x4
    8ee0:	ffb015b7          	lui	a1,0xffb01
    8ee4:	00878b33          	add	s6,a5,s0
    8ee8:	90050793          	addi	a5,a0,-1792 # ffb00900 <_ZL14scratch_db_top>
    8eec:	00f12423          	sw	a5,8(sp)
    8ef0:	86c58793          	addi	a5,a1,-1940 # ffb0086c <sem_l1_base>
    8ef4:	ffb00ab7          	lui	s5,0xffb00
    8ef8:	00f12023          	sw	a5,0(sp)
    8efc:	04010793          	addi	a5,sp,64
    8f00:	00f12223          	sw	a5,4(sp)
    8f04:	00e12623          	sw	a4,12(sp)
    8f08:	00000513          	li	a0,0
    8f0c:	01712823          	sw	s7,16(sp)
    8f10:	00060c93          	mv	s9,a2
    8f14:	03c10f13          	addi	t5,sp,60
    8f18:	024a8793          	addi	a5,s5,36 # ffb00024 <noc_nonposted_atomics_acked>

00008f1c <.L542>:
    8f1c:	02012703          	lw	a4,32(sp)
    8f20:	ffb20637          	lui	a2,0xffb20
    8f24:	00072583          	lw	a1,0(a4)

00008f28 <.L531>:
    8f28:	22862703          	lw	a4,552(a2) # ffb20228 <__stack_top+0x1e228>
    8f2c:	feb71ee3          	bne	a4,a1,8f28 <.L531>
    8f30:	0ff0000f          	fence
    8f34:	00812703          	lw	a4,8(sp)
    8f38:	00154893          	xori	a7,a0,1
    8f3c:	20e54733          	sh2add	a4,a0,a4
    8f40:	000d8b93          	mv	s7,s11
    8f44:	00072583          	lw	a1,0(a4)
    8f48:	260c9063          	bnez	s9,91a8 <.L533>
    8f4c:	00010737          	lui	a4,0x10
    8f50:	25b76c63          	bltu	a4,s11,91a8 <.L533>

00008f54 <.L532>:
    8f54:	00000a13          	li	s4,0
    8f58:	193bee63          	bltu	s7,s3,90f4 <.L534>
    8f5c:	00c12703          	lw	a4,12(sp)
    8f60:	40898c33          	sub	s8,s3,s0
    8f64:	00e75f93          	srli	t6,a4,0xe
    8f68:	00812703          	lw	a4,8(sp)
    8f6c:	00ef9613          	slli	a2,t6,0xe
    8f70:	20e8c733          	sh2add	a4,a7,a4
    8f74:	001f8f93          	addi	t6,t6,1
    8f78:	ffb00ab7          	lui	s5,0xffb00
    8f7c:	ffb003b7          	lui	t2,0xffb00
    8f80:	888892b7          	lui	t0,0x88889
    8f84:	10000337          	lui	t1,0x10000
    8f88:	01000eb7          	lui	t4,0x1000
    8f8c:	40cc0c33          	sub	s8,s8,a2
    8f90:	012fdd13          	srli	s10,t6,0x12
    8f94:	00072603          	lw	a2,0(a4) # 10000 <__kernel_data_lma+0x474c>
    8f98:	00ef9f93          	slli	t6,t6,0xe
    8f9c:	660a8a93          	addi	s5,s5,1632 # ffb00660 <bank_to_l1_offset>
    8fa0:	46438393          	addi	t2,t2,1124 # ffb00464 <l1_bank_to_noc_xy>
    8fa4:	88928293          	addi	t0,t0,-1911 # 88888889 <__kernel_data_lma+0x8887cfd5>
    8fa8:	00f30313          	addi	t1,t1,15 # 1000000f <__kernel_data_lma+0xfff475b>
    8fac:	fffe8e93          	addi	t4,t4,-1 # ffffff <__kernel_data_lma+0xff474b>
    8fb0:	ffb21737          	lui	a4,0xffb21
    8fb4:	00100e13          	li	t3,1
    8fb8:	01112a23          	sw	a7,20(sp)
    8fbc:	00b12c23          	sw	a1,24(sp)
    8fc0:	00d12e23          	sw	a3,28(sp)
    8fc4:	03b12223          	sw	s11,36(sp)
    8fc8:	03912423          	sw	s9,40(sp)

00008fcc <.L539>:
    8fcc:	02593533          	mulhu	a0,s2,t0
    8fd0:	04c12583          	lw	a1,76(sp)
    8fd4:	00655513          	srli	a0,a0,0x6
    8fd8:	00451693          	slli	a3,a0,0x4
    8fdc:	02b505b3          	mul	a1,a0,a1
    8fe0:	40a686b3          	sub	a3,a3,a0
    8fe4:	00369693          	slli	a3,a3,0x3
    8fe8:	40d906b3          	sub	a3,s2,a3
    8fec:	04412803          	lw	a6,68(sp)
    8ff0:	2156c533          	sh2add	a0,a3,s5
    8ff4:	2076a6b3          	sh1add	a3,a3,t2
    8ff8:	00052503          	lw	a0,0(a0)
    8ffc:	0006dd83          	lhu	s11,0(a3)
    9000:	010585b3          	add	a1,a1,a6
    9004:	00a588b3          	add	a7,a1,a0
    9008:	004d9d93          	slli	s11,s11,0x4
    900c:	00088593          	mv	a1,a7
    9010:	000d8693          	mv	a3,s11
    9014:	01460533          	add	a0,a2,s4
    9018:	19347c63          	bgeu	s0,s3,91b0 <.L553>
    901c:	00ab0cb3          	add	s9,s6,a0
    9020:	000d8813          	mv	a6,s11

00009024 <.L536>:
    9024:	84072683          	lw	a3,-1984(a4) # ffb20840 <__stack_top+0x1e840>
    9028:	fe069ee3          	bnez	a3,9024 <.L536>
    902c:	80a72623          	sw	a0,-2036(a4)
    9030:	80b72023          	sw	a1,-2048(a4)
    9034:	006876b3          	and	a3,a6,t1
    9038:	80d72223          	sw	a3,-2044(a4)
    903c:	00485693          	srli	a3,a6,0x4
    9040:	01d6f6b3          	and	a3,a3,t4
    9044:	80d72423          	sw	a3,-2040(a4)
    9048:	82872023          	sw	s0,-2016(a4)
    904c:	85c72023          	sw	t3,-1984(a4)
    9050:	0004a683          	lw	a3,0(s1)
    9054:	00850533          	add	a0,a0,s0
    9058:	00168693          	addi	a3,a3,1
    905c:	00d4a023          	sw	a3,0(s1)
    9060:	008586b3          	add	a3,a1,s0
    9064:	00b6b5b3          	sltu	a1,a3,a1
    9068:	01058833          	add	a6,a1,a6
    906c:	00068593          	mv	a1,a3
    9070:	faac9ae3          	bne	s9,a0,9024 <.L536>
    9074:	01f885b3          	add	a1,a7,t6
    9078:	01ad86b3          	add	a3,s11,s10
    907c:	0115b8b3          	sltu	a7,a1,a7
    9080:	00d886b3          	add	a3,a7,a3
    9084:	000c0813          	mv	a6,s8

00009088 <.L538>:
    9088:	84072503          	lw	a0,-1984(a4)
    908c:	fe051ee3          	bnez	a0,9088 <.L538>
    9090:	81972623          	sw	s9,-2036(a4)
    9094:	80b72023          	sw	a1,-2048(a4)
    9098:	0066f5b3          	and	a1,a3,t1
    909c:	80b72223          	sw	a1,-2044(a4)
    90a0:	0046d693          	srli	a3,a3,0x4
    90a4:	80d72423          	sw	a3,-2040(a4)
    90a8:	83072023          	sw	a6,-2016(a4)
    90ac:	85c72023          	sw	t3,-1984(a4)
    90b0:	0004a683          	lw	a3,0(s1)
    90b4:	013a0a33          	add	s4,s4,s3
    90b8:	00168693          	addi	a3,a3,1
    90bc:	00d4a023          	sw	a3,0(s1)
    90c0:	414b86b3          	sub	a3,s7,s4
    90c4:	00190913          	addi	s2,s2,1
    90c8:	f136f2e3          	bgeu	a3,s3,8fcc <.L539>
    90cc:	02412d83          	lw	s11,36(sp)
    90d0:	02812c83          	lw	s9,40(sp)
    90d4:	414d8733          	sub	a4,s11,s4
    90d8:	00edbdb3          	sltu	s11,s11,a4
    90dc:	41bc8cb3          	sub	s9,s9,s11
    90e0:	01412883          	lw	a7,20(sp)
    90e4:	01812583          	lw	a1,24(sp)
    90e8:	01c12683          	lw	a3,28(sp)
    90ec:	00070d93          	mv	s11,a4
    90f0:	01976c33          	or	s8,a4,s9

000090f4 <.L534>:
    90f4:	02b12e23          	sw	a1,60(sp)
    90f8:	00412583          	lw	a1,4(sp)
    90fc:	000f0513          	mv	a0,t5
    9100:	01112e23          	sw	a7,28(sp)
    9104:	00f12c23          	sw	a5,24(sp)
    9108:	04d12023          	sw	a3,64(sp)
    910c:	01e12a23          	sw	t5,20(sp)
    9110:	a15fc0ef          	jal	5b24 <_Z25write_pages_to_dispatcherILl0ELb0EEmRmS0_S0_.constprop.0>
    9114:	00012783          	lw	a5,0(sp)
    9118:	01c12883          	lw	a7,28(sp)
    911c:	0007a603          	lw	a2,0(a5)
    9120:	01412f03          	lw	t5,20(sp)
    9124:	01812783          	lw	a5,24(sp)
    9128:	00050593          	mv	a1,a0
    912c:	ffb226b7          	lui	a3,0xffb22

00009130 <.L540>:
    9130:	8406a703          	lw	a4,-1984(a3) # ffb21840 <__stack_top+0x1f840>
    9134:	fe071ee3          	bnez	a4,9130 <.L540>
    9138:	80c6a023          	sw	a2,-2048(a3)
    913c:	8006a223          	sw	zero,-2044(a3)
    9140:	00265713          	srli	a4,a2,0x2
    9144:	00001537          	lui	a0,0x1
    9148:	0ce00813          	li	a6,206
    914c:	00002637          	lui	a2,0x2
    9150:	8106a423          	sw	a6,-2040(a3)
    9154:	09160613          	addi	a2,a2,145 # 2091 <_start-0x293f>
    9158:	00377713          	andi	a4,a4,3
    915c:	07c50513          	addi	a0,a0,124 # 107c <_start-0x3954>
    9160:	80c6ae23          	sw	a2,-2020(a3)
    9164:	00a76733          	or	a4,a4,a0
    9168:	82e6a023          	sw	a4,-2016(a3)
    916c:	82b6a423          	sw	a1,-2008(a3)
    9170:	00100713          	li	a4,1
    9174:	84e6a023          	sw	a4,-1984(a3)
    9178:	0007a703          	lw	a4,0(a5)
    917c:	0004a603          	lw	a2,0(s1)
    9180:	00170713          	addi	a4,a4,1
    9184:	00e7a023          	sw	a4,0(a5)
    9188:	ffb206b7          	lui	a3,0xffb20

0000918c <.L541>:
    918c:	2086a703          	lw	a4,520(a3) # ffb20208 <__stack_top+0x1e208>
    9190:	fec71ee3          	bne	a4,a2,918c <.L541>
    9194:	0ff0000f          	fence
    9198:	020c0263          	beqz	s8,91bc <.L600>
    919c:	000a0693          	mv	a3,s4
    91a0:	00088513          	mv	a0,a7
    91a4:	d79ff06f          	j	8f1c <.L542>

000091a8 <.L533>:
    91a8:	00010bb7          	lui	s7,0x10
    91ac:	da9ff06f          	j	8f54 <.L532>

000091b0 <.L553>:
    91b0:	00050c93          	mv	s9,a0
    91b4:	00098813          	mv	a6,s3
    91b8:	ed1ff06f          	j	9088 <.L538>

000091bc <.L600>:
    91bc:	00078a93          	mv	s5,a5
    91c0:	00812783          	lw	a5,8(sp)
    91c4:	01012b83          	lw	s7,16(sp)
    91c8:	20f8ceb3          	sh2add	t4,a7,a5
    91cc:	000ea783          	lw	a5,0(t4)
    91d0:	000f0813          	mv	a6,t5
    91d4:	000a0693          	mv	a3,s4

000091d8 <.L529>:
    91d8:	00412583          	lw	a1,4(sp)
    91dc:	417686b3          	sub	a3,a3,s7
    91e0:	00080513          	mv	a0,a6
    91e4:	04d12023          	sw	a3,64(sp)
    91e8:	02f12e23          	sw	a5,60(sp)
    91ec:	a54fd0ef          	jal	6440 <_Z25write_pages_to_dispatcherILl1ELb1EEmRmS0_S0_.constprop.0>
    91f0:	00012783          	lw	a5,0(sp)
    91f4:	ffb01637          	lui	a2,0xffb01
    91f8:	0007a703          	lw	a4,0(a5)
    91fc:	000016b7          	lui	a3,0x1
    9200:	91862783          	lw	a5,-1768(a2) # ffb00918 <_ZL19downstream_data_ptr>
    9204:	fff68693          	addi	a3,a3,-1 # fff <_start-0x39d1>
    9208:	00d787b3          	add	a5,a5,a3
    920c:	fffff6b7          	lui	a3,0xfffff
    9210:	00d7f7b3          	and	a5,a5,a3
    9214:	90f62c23          	sw	a5,-1768(a2)
    9218:	00150693          	addi	a3,a0,1
    921c:	ffb227b7          	lui	a5,0xffb22

00009220 <.L543>:
    9220:	8407a603          	lw	a2,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    9224:	fe061ee3          	bnez	a2,9220 <.L543>
    9228:	80e7a023          	sw	a4,-2048(a5)
    922c:	8007a223          	sw	zero,-2044(a5)
    9230:	00275713          	srli	a4,a4,0x2
    9234:	000015b7          	lui	a1,0x1
    9238:	0ce00513          	li	a0,206
    923c:	00002637          	lui	a2,0x2
    9240:	80a7a423          	sw	a0,-2040(a5)
    9244:	00377713          	andi	a4,a4,3
    9248:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    924c:	09160613          	addi	a2,a2,145 # 2091 <_start-0x293f>
    9250:	80c7ae23          	sw	a2,-2020(a5)
    9254:	00b76733          	or	a4,a4,a1
    9258:	82e7a023          	sw	a4,-2016(a5)
    925c:	82d7a423          	sw	a3,-2008(a5)
    9260:	00100713          	li	a4,1
    9264:	84e7a023          	sw	a4,-1984(a5)
    9268:	000aa783          	lw	a5,0(s5)
    926c:	07812a03          	lw	s4,120(sp)
    9270:	00e787b3          	add	a5,a5,a4
    9274:	07012b03          	lw	s6,112(sp)
    9278:	06412c83          	lw	s9,100(sp)
    927c:	00faa023          	sw	a5,0(s5)
    9280:	a49ff06f          	j	8cc8 <.L479>

00009284 <.L545>:
    9284:	000a0513          	mv	a0,s4
    9288:	00078713          	mv	a4,a5
    928c:	d84ff06f          	j	8810 <.L494>

00009290 <.L599>:
    9290:	ffb017b7          	lui	a5,0xffb01
    9294:	90078793          	addi	a5,a5,-1792 # ffb00900 <_ZL14scratch_db_top>
    9298:	20f74733          	sh2add	a4,a4,a5
    929c:	00072783          	lw	a5,0(a4)
    92a0:	04410593          	addi	a1,sp,68
    92a4:	04010513          	addi	a0,sp,64
    92a8:	04f12023          	sw	a5,64(sp)
    92ac:	05812223          	sw	s8,68(sp)
    92b0:	990fd0ef          	jal	6440 <_Z25write_pages_to_dispatcherILl1ELb1EEmRmS0_S0_.constprop.0>
    92b4:	00012783          	lw	a5,0(sp)
    92b8:	ffb01637          	lui	a2,0xffb01
    92bc:	0007a703          	lw	a4,0(a5)
    92c0:	000016b7          	lui	a3,0x1
    92c4:	91862783          	lw	a5,-1768(a2) # ffb00918 <_ZL19downstream_data_ptr>
    92c8:	fff68693          	addi	a3,a3,-1 # fff <_start-0x39d1>
    92cc:	00d787b3          	add	a5,a5,a3
    92d0:	fffff6b7          	lui	a3,0xfffff
    92d4:	00d7f7b3          	and	a5,a5,a3
    92d8:	90f62c23          	sw	a5,-1768(a2)
    92dc:	00150693          	addi	a3,a0,1
    92e0:	ffb227b7          	lui	a5,0xffb22

000092e4 <.L515>:
    92e4:	8407a603          	lw	a2,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    92e8:	fe061ee3          	bnez	a2,92e4 <.L515>
    92ec:	80e7a023          	sw	a4,-2048(a5)
    92f0:	8007a223          	sw	zero,-2044(a5)
    92f4:	00275713          	srli	a4,a4,0x2
    92f8:	000015b7          	lui	a1,0x1
    92fc:	0ce00513          	li	a0,206
    9300:	00002637          	lui	a2,0x2
    9304:	80a7a423          	sw	a0,-2040(a5)
    9308:	00377713          	andi	a4,a4,3
    930c:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    9310:	09160613          	addi	a2,a2,145 # 2091 <_start-0x293f>
    9314:	80c7ae23          	sw	a2,-2020(a5)
    9318:	00b76733          	or	a4,a4,a1
    931c:	82e7a023          	sw	a4,-2016(a5)
    9320:	82d7a423          	sw	a3,-2008(a5)
    9324:	00100713          	li	a4,1
    9328:	84e7a023          	sw	a4,-1984(a5)
    932c:	000aa783          	lw	a5,0(s5)
    9330:	00e787b3          	add	a5,a5,a4
    9334:	00faa023          	sw	a5,0(s5)
    9338:	991ff06f          	j	8cc8 <.L479>

0000933c <.L595>:
    933c:	ffb017b7          	lui	a5,0xffb01
    9340:	ffb00ab7          	lui	s5,0xffb00
    9344:	86c78793          	addi	a5,a5,-1940 # ffb0086c <sem_l1_base>
    9348:	00f12023          	sw	a5,0(sp)
    934c:	024a8a93          	addi	s5,s5,36 # ffb00024 <noc_nonposted_atomics_acked>
    9350:	8edff06f          	j	8c3c <.L490>

00009354 <.L520>:
    9354:	ffb004b7          	lui	s1,0xffb00
    9358:	03c48493          	addi	s1,s1,60 # ffb0003c <noc_reads_num_issued>
    935c:	0004a583          	lw	a1,0(s1)
    9360:	00000693          	li	a3,0
    9364:	b4dff06f          	j	8eb0 <.L526>

00009368 <.L551>:
    9368:	ffb01737          	lui	a4,0xffb01
    936c:	86c70713          	addi	a4,a4,-1940 # ffb0086c <sem_l1_base>
    9370:	0005a7b7          	lui	a5,0x5a
    9374:	ffb00ab7          	lui	s5,0xffb00
    9378:	00e12023          	sw	a4,0(sp)
    937c:	04010713          	addi	a4,sp,64
    9380:	44078793          	addi	a5,a5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    9384:	024a8a93          	addi	s5,s5,36 # ffb00024 <noc_nonposted_atomics_acked>
    9388:	00e12223          	sw	a4,4(sp)
    938c:	03c10813          	addi	a6,sp,60
    9390:	e49ff06f          	j	91d8 <.L529>

00009394 <_Z27process_relay_inline_commonILb0ELb0ELb1E24DispatchRelayInlineStateEmRmS1_R20PrefetchExecBufState.constprop.0>:
    9394:	ffb017b7          	lui	a5,0xffb01
    9398:	86c78793          	addi	a5,a5,-1940 # ffb0086c <sem_l1_base>
    939c:	fc010113          	addi	sp,sp,-64
    93a0:	00f12423          	sw	a5,8(sp)
    93a4:	0007a583          	lw	a1,0(a5)
    93a8:	00052783          	lw	a5,0(a0)
    93ac:	ffb00337          	lui	t1,0xffb00
    93b0:	0047c703          	lbu	a4,4(a5)
    93b4:	0057c883          	lbu	a7,5(a5)
    93b8:	0067c803          	lbu	a6,6(a5)
    93bc:	00889893          	slli	a7,a7,0x8
    93c0:	0077ce83          	lbu	t4,7(a5)
    93c4:	0087ce03          	lbu	t3,8(a5)
    93c8:	0097c683          	lbu	a3,9(a5)
    93cc:	00e8e8b3          	or	a7,a7,a4
    93d0:	01081813          	slli	a6,a6,0x10
    93d4:	00a7c703          	lbu	a4,10(a5)
    93d8:	01186833          	or	a6,a6,a7
    93dc:	00001637          	lui	a2,0x1
    93e0:	00b7c883          	lbu	a7,11(a5)
    93e4:	018e9e93          	slli	t4,t4,0x18
    93e8:	00869693          	slli	a3,a3,0x8
    93ec:	010eeeb3          	or	t4,t4,a6
    93f0:	01c6e6b3          	or	a3,a3,t3
    93f4:	02430813          	addi	a6,t1,36 # ffb00024 <noc_nonposted_atomics_acked>
    93f8:	01071793          	slli	a5,a4,0x10
    93fc:	fff60613          	addi	a2,a2,-1 # fff <_start-0x39d1>
    9400:	00d7e7b3          	or	a5,a5,a3
    9404:	01889713          	slli	a4,a7,0x18
    9408:	00ce8633          	add	a2,t4,a2
    940c:	00082683          	lw	a3,0(a6) # 4000 <_start-0x9d0>
    9410:	00f76333          	or	t1,a4,a5
    9414:	01012223          	sw	a6,4(sp)
    9418:	00c65613          	srli	a2,a2,0xc
    941c:	ffb20737          	lui	a4,0xffb20

00009420 <.L602>:
    9420:	20072783          	lw	a5,512(a4) # ffb20200 <__stack_top+0x1e200>
    9424:	fed79ee3          	bne	a5,a3,9420 <.L602>
    9428:	0ff0000f          	fence
    942c:	ffb016b7          	lui	a3,0xffb01

00009430 <.L603>:
    9430:	0ff0000f          	fence
    9434:	9246a703          	lw	a4,-1756(a3) # ffb00924 <_ZN24DispatchRelayInlineState9cb_writerE>
    9438:	0005a783          	lw	a5,0(a1)
    943c:	00f707b3          	add	a5,a4,a5
    9440:	40f607b3          	sub	a5,a2,a5
    9444:	fef046e3          	bgtz	a5,9430 <.L603>
    9448:	40c70733          	sub	a4,a4,a2
    944c:	92e6a223          	sw	a4,-1756(a3)
    9450:	ffb013b7          	lui	t2,0xffb01
    9454:	ffb00737          	lui	a4,0xffb00
    9458:	9183a583          	lw	a1,-1768(t2) # ffb00918 <_ZL19downstream_data_ptr>
    945c:	03470713          	addi	a4,a4,52 # ffb00034 <noc_nonposted_writes_num_issued>
    9460:	1a0e8c63          	beqz	t4,9618 <.L604>
    9464:	00052f83          	lw	t6,0(a0)
    9468:	0005af37          	lui	t5,0x5a
    946c:	010f8f93          	addi	t6,t6,16
    9470:	440f0f13          	addi	t5,t5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    9474:	ffb00737          	lui	a4,0xffb00
    9478:	ffb006b7          	lui	a3,0xffb00
    947c:	02912c23          	sw	s1,56(sp)
    9480:	03512423          	sw	s5,40(sp)
    9484:	03612223          	sw	s6,36(sp)
    9488:	01912c23          	sw	s9,24(sp)
    948c:	01a12a23          	sw	s10,20(sp)
    9490:	02812e23          	sw	s0,60(sp)
    9494:	03212a23          	sw	s2,52(sp)
    9498:	03312823          	sw	s3,48(sp)
    949c:	03412623          	sw	s4,44(sp)
    94a0:	03712023          	sw	s7,32(sp)
    94a4:	ffff8cb7          	lui	s9,0xffff8
    94a8:	41ff0f33          	sub	t5,t5,t6
    94ac:	03470713          	addi	a4,a4,52 # ffb00034 <noc_nonposted_writes_num_issued>
    94b0:	02c68693          	addi	a3,a3,44 # ffb0002c <noc_nonposted_writes_acked>
    94b4:	0009a4b7          	lui	s1,0x9a
    94b8:	0001ad37          	lui	s10,0x1a
    94bc:	000048b7          	lui	a7,0x4
    94c0:	ffb207b7          	lui	a5,0xffb20
    94c4:	00100e13          	li	t3,1
    94c8:	ffffcb37          	lui	s6,0xffffc
    94cc:	00008ab7          	lui	s5,0x8

000094d0 <.L620>:
    94d0:	40b489b3          	sub	s3,s1,a1
    94d4:	0bdf5433          	minu	s0,t5,t4
    94d8:	000f8813          	mv	a6,t6
    94dc:	408f0f33          	sub	t5,t5,s0
    94e0:	008f8fb3          	add	t6,t6,s0
    94e4:	1c89e863          	bltu	s3,s0,96b4 <.L605>
    94e8:	00058993          	mv	s3,a1
    94ec:	00040913          	mv	s2,s0

000094f0 <.L606>:
    94f0:	00090a13          	mv	s4,s2
    94f4:	0b28fc63          	bgeu	a7,s2,95ac <.L619>

000094f8 <.L615>:
    94f8:	0407a503          	lw	a0,64(a5) # ffb20040 <__stack_top+0x1e040>
    94fc:	fe051ee3          	bnez	a0,94f8 <.L615>
    9500:	0107a023          	sw	a6,0(a5)
    9504:	0317a023          	sw	a7,32(a5)
    9508:	0137a623          	sw	s3,12(a5)
    950c:	00072283          	lw	t0,0(a4)
    9510:	0006a503          	lw	a0,0(a3)
    9514:	00128293          	addi	t0,t0,1
    9518:	00150513          	addi	a0,a0,1
    951c:	00572023          	sw	t0,0(a4)
    9520:	00a6a023          	sw	a0,0(a3)
    9524:	05c7a023          	sw	t3,64(a5)
    9528:	41190a33          	sub	s4,s2,a7
    952c:	011802b3          	add	t0,a6,a7
    9530:	01158533          	add	a0,a1,a7
    9534:	2f48f063          	bgeu	a7,s4,9814 <.L645>
    9538:	ffff89b7          	lui	s3,0xffff8
    953c:	fff98993          	addi	s3,s3,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    9540:	013909b3          	add	s3,s2,s3
    9544:	01580bb3          	add	s7,a6,s5
    9548:	0169fa33          	and	s4,s3,s6
    954c:	410b0833          	sub	a6,s6,a6
    9550:	017a0a33          	add	s4,s4,s7
    9554:	00a80833          	add	a6,a6,a0

00009558 <.L617>:
    9558:	0407a503          	lw	a0,64(a5)
    955c:	fe051ee3          	bnez	a0,9558 <.L617>
    9560:	0057a023          	sw	t0,0(a5)
    9564:	00580533          	add	a0,a6,t0
    9568:	00a7a623          	sw	a0,12(a5)
    956c:	00072503          	lw	a0,0(a4)
    9570:	011282b3          	add	t0,t0,a7
    9574:	00150513          	addi	a0,a0,1
    9578:	00a72023          	sw	a0,0(a4)
    957c:	0006a503          	lw	a0,0(a3)
    9580:	00150513          	addi	a0,a0,1
    9584:	00a6a023          	sw	a0,0(a3)
    9588:	05c7a023          	sw	t3,64(a5)
    958c:	fd4296e3          	bne	t0,s4,9558 <.L617>
    9590:	00e9d993          	srli	s3,s3,0xe
    9594:	00e99513          	slli	a0,s3,0xe
    9598:	015585b3          	add	a1,a1,s5
    959c:	01990a33          	add	s4,s2,s9
    95a0:	00028813          	mv	a6,t0
    95a4:	00b509b3          	add	s3,a0,a1
    95a8:	40aa0a33          	sub	s4,s4,a0

000095ac <.L619>:
    95ac:	0407a583          	lw	a1,64(a5)
    95b0:	fe059ee3          	bnez	a1,95ac <.L619>

000095b4 <.L648>:
    95b4:	0107a023          	sw	a6,0(a5)
    95b8:	0347a023          	sw	s4,32(a5)
    95bc:	0137a623          	sw	s3,12(a5)
    95c0:	00072503          	lw	a0,0(a4)
    95c4:	0006a583          	lw	a1,0(a3)
    95c8:	00150513          	addi	a0,a0,1
    95cc:	00158593          	addi	a1,a1,1
    95d0:	00b6a023          	sw	a1,0(a3)
    95d4:	00a72023          	sw	a0,0(a4)
    95d8:	05c7a023          	sw	t3,64(a5)
    95dc:	9183a583          	lw	a1,-1768(t2)
    95e0:	408e8eb3          	sub	t4,t4,s0
    95e4:	00b905b3          	add	a1,s2,a1
    95e8:	90b3ac23          	sw	a1,-1768(t2)
    95ec:	ee0e92e3          	bnez	t4,94d0 <.L620>
    95f0:	03c12403          	lw	s0,60(sp)
    95f4:	03812483          	lw	s1,56(sp)
    95f8:	03412903          	lw	s2,52(sp)
    95fc:	03012983          	lw	s3,48(sp)
    9600:	02c12a03          	lw	s4,44(sp)
    9604:	02812a83          	lw	s5,40(sp)
    9608:	02412b03          	lw	s6,36(sp)
    960c:	02012b83          	lw	s7,32(sp)
    9610:	01812c83          	lw	s9,24(sp)
    9614:	01412d03          	lw	s10,20(sp)

00009618 <.L604>:
    9618:	000017b7          	lui	a5,0x1
    961c:	fff78793          	addi	a5,a5,-1 # fff <_start-0x39d1>
    9620:	00f587b3          	add	a5,a1,a5
    9624:	fffff5b7          	lui	a1,0xfffff
    9628:	00b7f7b3          	and	a5,a5,a1
    962c:	00072683          	lw	a3,0(a4)
    9630:	90f3ac23          	sw	a5,-1768(t2)
    9634:	ffb20737          	lui	a4,0xffb20

00009638 <.L621>:
    9638:	22872783          	lw	a5,552(a4) # ffb20228 <__stack_top+0x1e228>
    963c:	fed79ee3          	bne	a5,a3,9638 <.L621>
    9640:	0ff0000f          	fence
    9644:	00812783          	lw	a5,8(sp)
    9648:	ffb22737          	lui	a4,0xffb22
    964c:	0007a683          	lw	a3,0(a5)

00009650 <.L622>:
    9650:	84072783          	lw	a5,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    9654:	fe079ee3          	bnez	a5,9650 <.L622>
    9658:	80d72023          	sw	a3,-2048(a4)
    965c:	80072223          	sw	zero,-2044(a4)
    9660:	0026d793          	srli	a5,a3,0x2
    9664:	0ce00513          	li	a0,206
    9668:	000015b7          	lui	a1,0x1
    966c:	000026b7          	lui	a3,0x2
    9670:	80a72423          	sw	a0,-2040(a4)
    9674:	0037f793          	andi	a5,a5,3
    9678:	07c58593          	addi	a1,a1,124 # 107c <_start-0x3954>
    967c:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    9680:	80d72e23          	sw	a3,-2020(a4)
    9684:	00b7e7b3          	or	a5,a5,a1
    9688:	82f72023          	sw	a5,-2016(a4)
    968c:	82c72423          	sw	a2,-2008(a4)
    9690:	00100793          	li	a5,1
    9694:	84f72023          	sw	a5,-1984(a4)
    9698:	00412703          	lw	a4,4(sp)
    969c:	00030513          	mv	a0,t1
    96a0:	00072783          	lw	a5,0(a4)
    96a4:	00178793          	addi	a5,a5,1
    96a8:	00f72023          	sw	a5,0(a4)
    96ac:	04010113          	addi	sp,sp,64
    96b0:	00008067          	ret

000096b4 <.L605>:
    96b4:	00040913          	mv	s2,s0
    96b8:	00959a63          	bne	a1,s1,96cc <.L646>

000096bc <.L607>:
    96bc:	0001a9b7          	lui	s3,0x1a
    96c0:	91a3ac23          	sw	s10,-1768(t2)
    96c4:	00098593          	mv	a1,s3
    96c8:	e29ff06f          	j	94f0 <.L606>

000096cc <.L646>:
    96cc:	fff6a537          	lui	a0,0xfff6a
    96d0:	00a58533          	add	a0,a1,a0
    96d4:	00058b93          	mv	s7,a1
    96d8:	00098293          	mv	t0,s3
    96dc:	00080a13          	mv	s4,a6
    96e0:	0ea8f863          	bgeu	a7,a0,97d0 <.L613>
    96e4:	01812e23          	sw	s8,28(sp)
    96e8:	01b12823          	sw	s11,16(sp)
    96ec:	ffb202b7          	lui	t0,0xffb20

000096f0 <.L609>:
    96f0:	0402a503          	lw	a0,64(t0) # ffb20040 <__stack_top+0x1e040>
    96f4:	fe051ee3          	bnez	a0,96f0 <.L609>
    96f8:	0102a023          	sw	a6,0(t0)
    96fc:	00004c37          	lui	s8,0x4
    9700:	0382a023          	sw	s8,32(t0)
    9704:	00b2a623          	sw	a1,12(t0)
    9708:	00072903          	lw	s2,0(a4)
    970c:	0006a503          	lw	a0,0(a3)
    9710:	00190913          	addi	s2,s2,1
    9714:	00150513          	addi	a0,a0,1 # fff6a001 <__instrn_buffer+0x12a001>
    9718:	01272023          	sw	s2,0(a4)
    971c:	00a6a023          	sw	a0,0(a3)
    9720:	00100d93          	li	s11,1
    9724:	05b2a023          	sw	s11,64(t0)
    9728:	fff6e2b7          	lui	t0,0xfff6e
    972c:	005582b3          	add	t0,a1,t0
    9730:	01880933          	add	s2,a6,s8
    9734:	01858533          	add	a0,a1,s8
    9738:	0e5c7863          	bgeu	s8,t0,9828 <.L647>
    973c:	000922b7          	lui	t0,0x92
    9740:	fff28293          	addi	t0,t0,-1 # 91fff <__kernel_data_lma+0x8674b>
    9744:	40b282b3          	sub	t0,t0,a1
    9748:	ffffca37          	lui	s4,0xffffc
    974c:	00512623          	sw	t0,12(sp)
    9750:	0142f2b3          	and	t0,t0,s4
    9754:	410a0a33          	sub	s4,s4,a6
    9758:	00aa0bb3          	add	s7,s4,a0
    975c:	00008a37          	lui	s4,0x8
    9760:	01480a33          	add	s4,a6,s4
    9764:	005a0a33          	add	s4,s4,t0
    9768:	ffb202b7          	lui	t0,0xffb20

0000976c <.L611>:
    976c:	0402a503          	lw	a0,64(t0) # ffb20040 <__stack_top+0x1e040>
    9770:	fe051ee3          	bnez	a0,976c <.L611>
    9774:	0122a023          	sw	s2,0(t0)
    9778:	012b8533          	add	a0,s7,s2
    977c:	00a2a623          	sw	a0,12(t0)
    9780:	00072503          	lw	a0,0(a4)
    9784:	01890933          	add	s2,s2,s8
    9788:	00150513          	addi	a0,a0,1
    978c:	00a72023          	sw	a0,0(a4)
    9790:	0006a503          	lw	a0,0(a3)
    9794:	00150513          	addi	a0,a0,1
    9798:	00a6a023          	sw	a0,0(a3)
    979c:	05b2a023          	sw	s11,64(t0)
    97a0:	fd4916e3          	bne	s2,s4,976c <.L611>
    97a4:	00c12503          	lw	a0,12(sp)
    97a8:	000922b7          	lui	t0,0x92
    97ac:	00e55513          	srli	a0,a0,0xe
    97b0:	00008bb7          	lui	s7,0x8
    97b4:	00e51913          	slli	s2,a0,0xe
    97b8:	40b282b3          	sub	t0,t0,a1
    97bc:	01758bb3          	add	s7,a1,s7
    97c0:	01c12c03          	lw	s8,28(sp)
    97c4:	01012d83          	lw	s11,16(sp)
    97c8:	412282b3          	sub	t0,t0,s2
    97cc:	012b8bb3          	add	s7,s7,s2

000097d0 <.L613>:
    97d0:	0407a503          	lw	a0,64(a5)
    97d4:	fe051ee3          	bnez	a0,97d0 <.L613>
    97d8:	0147a023          	sw	s4,0(a5)
    97dc:	0257a023          	sw	t0,32(a5)
    97e0:	0177a623          	sw	s7,12(a5)
    97e4:	00072283          	lw	t0,0(a4)
    97e8:	0006a503          	lw	a0,0(a3)
    97ec:	00128293          	addi	t0,t0,1 # 92001 <__kernel_data_lma+0x8674d>
    97f0:	00150513          	addi	a0,a0,1
    97f4:	fff66937          	lui	s2,0xfff66
    97f8:	01258933          	add	s2,a1,s2
    97fc:	00572023          	sw	t0,0(a4)
    9800:	00a6a023          	sw	a0,0(a3)
    9804:	00890933          	add	s2,s2,s0
    9808:	01380833          	add	a6,a6,s3
    980c:	05c7a023          	sw	t3,64(a5)
    9810:	eadff06f          	j	96bc <.L607>

00009814 <.L645>:
    9814:	0407a583          	lw	a1,64(a5)
    9818:	00050993          	mv	s3,a0
    981c:	00028813          	mv	a6,t0
    9820:	d80596e3          	bnez	a1,95ac <.L619>
    9824:	d91ff06f          	j	95b4 <.L648>

00009828 <.L647>:
    9828:	000962b7          	lui	t0,0x96
    982c:	01c12c03          	lw	s8,28(sp)
    9830:	01012d83          	lw	s11,16(sp)
    9834:	00050b93          	mv	s7,a0
    9838:	00090a13          	mv	s4,s2
    983c:	40b282b3          	sub	t0,t0,a1
    9840:	f91ff06f          	j	97d0 <.L613>

00009844 <_Z25copy_sub_cmds_to_l1_cacheILb0ELb1E31CQPrefetchRelayRingbufferSubCmdEPT1_RmmPmR20PrefetchExecBufStateS3_>:
    9844:	fe010113          	addi	sp,sp,-32
    9848:	00912a23          	sw	s1,20(sp)
    984c:	00112e23          	sw	ra,28(sp)
    9850:	00060493          	mv	s1,a2
    9854:	0e058063          	beqz	a1,9934 <.L649>
    9858:	00812c23          	sw	s0,24(sp)
    985c:	00058413          	mv	s0,a1
    9860:	0106a583          	lw	a1,16(a3)
    9864:	00052783          	lw	a5,0(a0)
    9868:	0105b393          	sltiu	t2,a1,16
    986c:	01212823          	sw	s2,16(sp)
    9870:	fff38393          	addi	t2,t2,-1
    9874:	00070913          	mv	s2,a4
    9878:	ff058713          	addi	a4,a1,-16
    987c:	01312623          	sw	s3,12(sp)
    9880:	01412423          	sw	s4,8(sp)
    9884:	00068993          	mv	s3,a3
    9888:	00050a13          	mv	s4,a0
    988c:	00e3f3b3          	and	t2,t2,a4
    9890:	01078693          	addi	a3,a5,16

00009894 <.L655>:
    9894:	00068793          	mv	a5,a3
    9898:	0a038863          	beqz	t2,9948 <.L664>

0000989c <.L651>:
    989c:	0a83d733          	minu	a4,t2,s0
    98a0:	40e383b3          	sub	t2,t2,a4
    98a4:	00e786b3          	add	a3,a5,a4
    98a8:	02039063          	bnez	t2,98c8 <.L652>
    98ac:	00092603          	lw	a2,0(s2) # fff66000 <__instrn_buffer+0x126000>
    98b0:	40b60633          	sub	a2,a2,a1
    98b4:	00c92023          	sw	a2,0(s2)
    98b8:	0009a823          	sw	zero,16(s3) # 1a010 <__kernel_data_lma+0xe75c>
    98bc:	000a2603          	lw	a2,0(s4) # 8000 <.L417+0x24>
    98c0:	00b60633          	add	a2,a2,a1
    98c4:	00ca2023          	sw	a2,0(s4)

000098c8 <.L652>:
    98c8:	00275293          	srli	t0,a4,0x2
    98cc:	04028663          	beqz	t0,9918 <.L653>
    98d0:	00048613          	mv	a2,s1
    98d4:	00000813          	li	a6,0

000098d8 <.L654>:
    98d8:	0007af83          	lw	t6,0(a5)
    98dc:	0047af03          	lw	t5,4(a5)
    98e0:	0087ae83          	lw	t4,8(a5)
    98e4:	00c7ae03          	lw	t3,12(a5)
    98e8:	0107a303          	lw	t1,16(a5)
    98ec:	0147a883          	lw	a7,20(a5)
    98f0:	00680813          	addi	a6,a6,6
    98f4:	01878793          	addi	a5,a5,24
    98f8:	01860613          	addi	a2,a2,24
    98fc:	fff62423          	sw	t6,-24(a2)
    9900:	ffe62623          	sw	t5,-20(a2)
    9904:	ffd62823          	sw	t4,-16(a2)
    9908:	ffc62a23          	sw	t3,-12(a2)
    990c:	fe662c23          	sw	t1,-8(a2)
    9910:	ff162e23          	sw	a7,-4(a2)
    9914:	fc5862e3          	bltu	a6,t0,98d8 <.L654>

00009918 <.L653>:
    9918:	40e40433          	sub	s0,s0,a4
    991c:	2092c4b3          	sh2add	s1,t0,s1
    9920:	f6041ae3          	bnez	s0,9894 <.L655>
    9924:	01812403          	lw	s0,24(sp)
    9928:	01012903          	lw	s2,16(sp)
    992c:	00c12983          	lw	s3,12(sp)
    9930:	00812a03          	lw	s4,8(sp)

00009934 <.L649>:
    9934:	01c12083          	lw	ra,28(sp)
    9938:	00048513          	mv	a0,s1
    993c:	01412483          	lw	s1,20(sp)
    9940:	02010113          	addi	sp,sp,32
    9944:	00008067          	ret

00009948 <.L664>:
    9948:	00098593          	mv	a1,s3
    994c:	000a0513          	mv	a0,s4
    9950:	a8cfb0ef          	jal	4bdc <_Z24paged_read_into_cmddat_qRmR20PrefetchExecBufState>
    9954:	0109a383          	lw	t2,16(s3)
    9958:	000a2783          	lw	a5,0(s4)
    995c:	00038593          	mv	a1,t2
    9960:	f3dff06f          	j	989c <.L651>

00009964 <_Z25copy_sub_cmds_to_l1_cacheILb0ELb0E32CQPrefetchRelayPagedPackedSubCmdEPT1_RmmPmR20PrefetchExecBufStateS3_.isra.0>:
    9964:	08058063          	beqz	a1,99e4 <.L665>
    9968:	0005a3b7          	lui	t2,0x5a
    996c:	01050513          	addi	a0,a0,16
    9970:	44038393          	addi	t2,t2,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    9974:	40a383b3          	sub	t2,t2,a0

00009978 <.L669>:
    9978:	0a75d2b3          	minu	t0,a1,t2
    997c:	0022df93          	srli	t6,t0,0x2
    9980:	00050793          	mv	a5,a0
    9984:	405383b3          	sub	t2,t2,t0
    9988:	00550533          	add	a0,a0,t0
    998c:	040f8663          	beqz	t6,99d8 <.L667>
    9990:	00060713          	mv	a4,a2
    9994:	00000693          	li	a3,0

00009998 <.L668>:
    9998:	0007af03          	lw	t5,0(a5)
    999c:	0047ae83          	lw	t4,4(a5)
    99a0:	0087ae03          	lw	t3,8(a5)
    99a4:	00c7a303          	lw	t1,12(a5)
    99a8:	0107a883          	lw	a7,16(a5)
    99ac:	0147a803          	lw	a6,20(a5)
    99b0:	00668693          	addi	a3,a3,6
    99b4:	01878793          	addi	a5,a5,24
    99b8:	01870713          	addi	a4,a4,24
    99bc:	ffe72423          	sw	t5,-24(a4)
    99c0:	ffd72623          	sw	t4,-20(a4)
    99c4:	ffc72823          	sw	t3,-16(a4)
    99c8:	fe672a23          	sw	t1,-12(a4)
    99cc:	ff172c23          	sw	a7,-8(a4)
    99d0:	ff072e23          	sw	a6,-4(a4)
    99d4:	fdf6e2e3          	bltu	a3,t6,9998 <.L668>

000099d8 <.L667>:
    99d8:	405585b3          	sub	a1,a1,t0
    99dc:	20cfc633          	sh2add	a2,t6,a2
    99e0:	f8059ce3          	bnez	a1,9978 <.L669>

000099e4 <.L665>:
    99e4:	00060513          	mv	a0,a2
    99e8:	00008067          	ret

000099ec <_Z20process_exec_buf_cmdmRmPmR20PrefetchExecBufState.constprop.0>:
    99ec:	f9010113          	addi	sp,sp,-112
    99f0:	05712623          	sw	s7,76(sp)
    99f4:	03b12e23          	sw	s11,60(sp)
    99f8:	06112623          	sw	ra,108(sp)
    99fc:	06812423          	sw	s0,104(sp)
    9a00:	06912223          	sw	s1,100(sp)
    9a04:	07212023          	sw	s2,96(sp)
    9a08:	05312e23          	sw	s3,92(sp)
    9a0c:	05412c23          	sw	s4,88(sp)
    9a10:	05512a23          	sw	s5,84(sp)
    9a14:	05612823          	sw	s6,80(sp)
    9a18:	05812423          	sw	s8,72(sp)
    9a1c:	05912223          	sw	s9,68(sp)
    9a20:	05a12023          	sw	s10,64(sp)
    9a24:	00062023          	sw	zero,0(a2)
    9a28:	00454783          	lbu	a5,4(a0)
    9a2c:	00554683          	lbu	a3,5(a0)
    9a30:	00654703          	lbu	a4,6(a0)
    9a34:	00869693          	slli	a3,a3,0x8
    9a38:	00f6e6b3          	or	a3,a3,a5
    9a3c:	00754783          	lbu	a5,7(a0)
    9a40:	01071713          	slli	a4,a4,0x10
    9a44:	00d76733          	or	a4,a4,a3
    9a48:	01879793          	slli	a5,a5,0x18
    9a4c:	00e7e7b3          	or	a5,a5,a4
    9a50:	00f62223          	sw	a5,4(a2)
    9a54:	00854783          	lbu	a5,8(a0)
    9a58:	00954683          	lbu	a3,9(a0)
    9a5c:	00a54703          	lbu	a4,10(a0)
    9a60:	00869693          	slli	a3,a3,0x8
    9a64:	00f6e6b3          	or	a3,a3,a5
    9a68:	00b54783          	lbu	a5,11(a0)
    9a6c:	01071713          	slli	a4,a4,0x10
    9a70:	00d76733          	or	a4,a4,a3
    9a74:	01879793          	slli	a5,a5,0x18
    9a78:	00e7e7b3          	or	a5,a5,a4
    9a7c:	00f62423          	sw	a5,8(a2)
    9a80:	00c54783          	lbu	a5,12(a0)
    9a84:	00d54683          	lbu	a3,13(a0)
    9a88:	00e54703          	lbu	a4,14(a0)
    9a8c:	00869693          	slli	a3,a3,0x8
    9a90:	00f6e6b3          	or	a3,a3,a5
    9a94:	00f54783          	lbu	a5,15(a0)
    9a98:	01071713          	slli	a4,a4,0x10
    9a9c:	00d76733          	or	a4,a4,a3
    9aa0:	01879793          	slli	a5,a5,0x18
    9aa4:	00e7e7b3          	or	a5,a5,a4
    9aa8:	00f62623          	sw	a5,12(a2)
    9aac:	0001a7b7          	lui	a5,0x1a
    9ab0:	44078793          	addi	a5,a5,1088 # 1a440 <__kernel_data_lma+0xeb8c>
    9ab4:	ffb016b7          	lui	a3,0xffb01
    9ab8:	00b12423          	sw	a1,8(sp)
    9abc:	00062823          	sw	zero,16(a2)
    9ac0:	00062c23          	sw	zero,24(a2)
    9ac4:	0000a737          	lui	a4,0xa
    9ac8:	00f62a23          	sw	a5,20(a2)
    9acc:	02f12423          	sw	a5,40(sp)
    9ad0:	88068793          	addi	a5,a3,-1920 # ffb00880 <__ldm_data_start>
    9ad4:	00f12223          	sw	a5,4(sp)
    9ad8:	b0470b93          	addi	s7,a4,-1276 # 9b04 <.L681>
    9adc:	00060d93          	mv	s11,a2

00009ae0 <.L677>:
    9ae0:	000d8593          	mv	a1,s11
    9ae4:	02810513          	addi	a0,sp,40
    9ae8:	8f4fb0ef          	jal	4bdc <_Z24paged_read_into_cmddat_qRmR20PrefetchExecBufState>
    9aec:	010da783          	lw	a5,16(s11)
    9af0:	fe0788e3          	beqz	a5,9ae0 <.L677>
    9af4:	02812503          	lw	a0,40(sp)
    9af8:	00004c37          	lui	s8,0x4
    9afc:	00100c93          	li	s9,1
    9b00:	ffb21d37          	lui	s10,0xffb21

00009b04 <.L681>:
    9b04:	00054783          	lbu	a5,0(a0)
    9b08:	00412703          	lw	a4,4(sp)
    9b0c:	20e7c7b3          	sh2add	a5,a5,a4
    9b10:	0007a783          	lw	a5,0(a5)
    9b14:	00fb87b3          	add	a5,s7,a5
    9b18:	00078067          	jr	a5

00009b1c <.L682>:
    9b1c:	00154583          	lbu	a1,1(a0)
    9b20:	00254683          	lbu	a3,2(a0)
    9b24:	00354703          	lbu	a4,3(a0)
    9b28:	00454783          	lbu	a5,4(a0)
    9b2c:	00854603          	lbu	a2,8(a0)
    9b30:	01879793          	slli	a5,a5,0x18
    9b34:	00869693          	slli	a3,a3,0x8
    9b38:	00b6e6b3          	or	a3,a3,a1
    9b3c:	01071713          	slli	a4,a4,0x10
    9b40:	00d76733          	or	a4,a4,a3
    9b44:	00e7e7b3          	or	a5,a5,a4
    9b48:	64060863          	beqz	a2,a198 <.L744>
    9b4c:	0005a737          	lui	a4,0x5a
    9b50:	44070713          	addi	a4,a4,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    9b54:	00e787b3          	add	a5,a5,a4
    9b58:	010da603          	lw	a2,16(s11)
    9b5c:	ffb01737          	lui	a4,0xffb01
    9b60:	90f72823          	sw	a5,-1776(a4) # ffb00910 <_ZL13ringbuffer_wp>
    9b64:	04000993          	li	s3,64

00009b68 <.L693>:
    9b68:	41360633          	sub	a2,a2,s3
    9b6c:	01350533          	add	a0,a0,s3
    9b70:	00cda823          	sw	a2,16(s11)
    9b74:	02a12423          	sw	a0,40(sp)
    9b78:	f80616e3          	bnez	a2,9b04 <.L681>
    9b7c:	f65ff06f          	j	9ae0 <.L677>

00009b80 <.L683>:
    9b80:	c34fb0ef          	jal	4fb4 <_Z31process_paged_to_ringbuffer_cmdmRm.constprop.0.isra.0>

00009b84 <.L793>:
    9b84:	010da603          	lw	a2,16(s11)
    9b88:	02812503          	lw	a0,40(sp)
    9b8c:	04000993          	li	s3,64
    9b90:	fd9ff06f          	j	9b68 <.L693>

00009b94 <.L685>:
    9b94:	ffb017b7          	lui	a5,0xffb01
    9b98:	86c7a683          	lw	a3,-1940(a5) # ffb0086c <sem_l1_base>
    9b9c:	ffb01637          	lui	a2,0xffb01
    9ba0:	92062783          	lw	a5,-1760(a2) # ffb00920 <_ZZ13process_stallmE5count>
    9ba4:	00178793          	addi	a5,a5,1
    9ba8:	92f62023          	sw	a5,-1760(a2)
    9bac:	02068693          	addi	a3,a3,32

00009bb0 <.L743>:
    9bb0:	0ff0000f          	fence
    9bb4:	0006a703          	lw	a4,0(a3)
    9bb8:	92062783          	lw	a5,-1760(a2)
    9bbc:	fef71ae3          	bne	a4,a5,9bb0 <.L743>
    9bc0:	fc5ff06f          	j	9b84 <.L793>

00009bc4 <.L686>:
    9bc4:	000d8593          	mv	a1,s11
    9bc8:	02810513          	addi	a0,sp,40
    9bcc:	a29fb0ef          	jal	55f4 <_Z27process_relay_inline_commonILb0ELb1ELb1E24DispatchRelayInlineStateEmRmS1_R20PrefetchExecBufState.constprop.0>

00009bd0 <.L757>:
    9bd0:	06c12083          	lw	ra,108(sp)
    9bd4:	06812403          	lw	s0,104(sp)
    9bd8:	06412483          	lw	s1,100(sp)
    9bdc:	06012903          	lw	s2,96(sp)
    9be0:	05c12983          	lw	s3,92(sp)
    9be4:	05812a03          	lw	s4,88(sp)
    9be8:	05412a83          	lw	s5,84(sp)
    9bec:	05012b03          	lw	s6,80(sp)
    9bf0:	04c12b83          	lw	s7,76(sp)
    9bf4:	04812c03          	lw	s8,72(sp)
    9bf8:	04412c83          	lw	s9,68(sp)
    9bfc:	04012d03          	lw	s10,64(sp)
    9c00:	03c12d83          	lw	s11,60(sp)
    9c04:	04000513          	li	a0,64
    9c08:	07010113          	addi	sp,sp,112
    9c0c:	00008067          	ret

00009c10 <.L687>:
    9c10:	00812583          	lw	a1,8(sp)
    9c14:	000d8613          	mv	a2,s11
    9c18:	dd5ff0ef          	jal	99ec <_Z20process_exec_buf_cmdmRmPmR20PrefetchExecBufState.constprop.0>
    9c1c:	04000993          	li	s3,64
    9c20:	ffb017b7          	lui	a5,0xffb01
    9c24:	010da603          	lw	a2,16(s11)
    9c28:	02812503          	lw	a0,40(sp)
    9c2c:	9207a823          	sw	zero,-1744(a5) # ffb00930 <_ZL11stall_state>
    9c30:	f39ff06f          	j	9b68 <.L693>

00009c34 <.L688>:
    9c34:	00454683          	lbu	a3,4(a0)
    9c38:	ffb017b7          	lui	a5,0xffb01
    9c3c:	00554703          	lbu	a4,5(a0)
    9c40:	86c7a803          	lw	a6,-1940(a5) # ffb0086c <sem_l1_base>
    9c44:	00654783          	lbu	a5,6(a0)
    9c48:	00871713          	slli	a4,a4,0x8
    9c4c:	00754a03          	lbu	s4,7(a0)
    9c50:	00d76733          	or	a4,a4,a3
    9c54:	01079793          	slli	a5,a5,0x10
    9c58:	00854683          	lbu	a3,8(a0)
    9c5c:	00e7e7b3          	or	a5,a5,a4
    9c60:	018a1a13          	slli	s4,s4,0x18
    9c64:	00954703          	lbu	a4,9(a0)
    9c68:	00fa6a33          	or	s4,s4,a5
    9c6c:	00a54783          	lbu	a5,10(a0)
    9c70:	00871713          	slli	a4,a4,0x8
    9c74:	00b54983          	lbu	s3,11(a0)
    9c78:	00d76733          	or	a4,a4,a3
    9c7c:	01079793          	slli	a5,a5,0x10
    9c80:	00e7e7b3          	or	a5,a5,a4
    9c84:	01899993          	slli	s3,s3,0x18
    9c88:	ffb00737          	lui	a4,0xffb00
    9c8c:	02472683          	lw	a3,36(a4) # ffb00024 <noc_nonposted_atomics_acked>
    9c90:	00f9e9b3          	or	s3,s3,a5
    9c94:	ffb20737          	lui	a4,0xffb20

00009c98 <.L721>:
    9c98:	20072783          	lw	a5,512(a4) # ffb20200 <__stack_top+0x1e200>
    9c9c:	fed79ee3          	bne	a5,a3,9c98 <.L721>
    9ca0:	0ff0000f          	fence
    9ca4:	ffb01637          	lui	a2,0xffb01
    9ca8:	00100593          	li	a1,1

00009cac <.L722>:
    9cac:	0ff0000f          	fence
    9cb0:	92462703          	lw	a4,-1756(a2) # ffb00924 <_ZN24DispatchRelayInlineState9cb_writerE>
    9cb4:	00082683          	lw	a3,0(a6)
    9cb8:	40e587b3          	sub	a5,a1,a4
    9cbc:	40d787b3          	sub	a5,a5,a3
    9cc0:	fef046e3          	bgtz	a5,9cac <.L722>
    9cc4:	fff70713          	addi	a4,a4,-1
    9cc8:	ffb01ab7          	lui	s5,0xffb01
    9ccc:	92e62223          	sw	a4,-1756(a2)
    9cd0:	918aa703          	lw	a4,-1768(s5) # ffb00918 <_ZL19downstream_data_ptr>
    9cd4:	0009a7b7          	lui	a5,0x9a
    9cd8:	00f71663          	bne	a4,a5,9ce4 <.L723>
    9cdc:	0001a7b7          	lui	a5,0x1a
    9ce0:	90faac23          	sw	a5,-1768(s5)

00009ce4 <.L723>:
    9ce4:	010da603          	lw	a2,16(s11)
    9ce8:	02812503          	lw	a0,40(sp)
    9cec:	e60a0ee3          	beqz	s4,9b68 <.L693>
    9cf0:	01063813          	sltiu	a6,a2,16
    9cf4:	fff80813          	addi	a6,a6,-1
    9cf8:	ff060793          	addi	a5,a2,-16
    9cfc:	ffb004b7          	lui	s1,0xffb00
    9d00:	ffb00937          	lui	s2,0xffb00
    9d04:	01050393          	addi	t2,a0,16
    9d08:	00f87833          	and	a6,a6,a5
    9d0c:	03448493          	addi	s1,s1,52 # ffb00034 <noc_nonposted_writes_num_issued>
    9d10:	02c90913          	addi	s2,s2,44 # ffb0002c <noc_nonposted_writes_acked>
    9d14:	ffb20437          	lui	s0,0xffb20
    9d18:	0009ab37          	lui	s6,0x9a
    9d1c:	00038713          	mv	a4,t2
    9d20:	16080463          	beqz	a6,9e88 <.L795>

00009d24 <.L724>:
    9d24:	0b4858b3          	minu	a7,a6,s4
    9d28:	41180833          	sub	a6,a6,a7
    9d2c:	00e883b3          	add	t2,a7,a4
    9d30:	00081c63          	bnez	a6,9d48 <.L726>
    9d34:	02812783          	lw	a5,40(sp)
    9d38:	40c989b3          	sub	s3,s3,a2
    9d3c:	00c787b3          	add	a5,a5,a2
    9d40:	000da823          	sw	zero,16(s11)
    9d44:	02f12423          	sw	a5,40(sp)

00009d48 <.L726>:
    9d48:	918aa503          	lw	a0,-1768(s5)
    9d4c:	00088593          	mv	a1,a7
    9d50:	40ab0e33          	sub	t3,s6,a0
    9d54:	00050313          	mv	t1,a0
    9d58:	011e7a63          	bgeu	t3,a7,9d6c <.L728>
    9d5c:	2f651863          	bne	a0,s6,a04c <.L796>

00009d60 <.L729>:
    9d60:	0001a337          	lui	t1,0x1a
    9d64:	906aac23          	sw	t1,-1768(s5)
    9d68:	00030513          	mv	a0,t1

00009d6c <.L728>:
    9d6c:	00058e13          	mv	t3,a1
    9d70:	0cbc7663          	bgeu	s8,a1,9e3c <.L741>

00009d74 <.L737>:
    9d74:	04042783          	lw	a5,64(s0) # ffb20040 <__stack_top+0x1e040>
    9d78:	fe079ee3          	bnez	a5,9d74 <.L737>
    9d7c:	00e42023          	sw	a4,0(s0)
    9d80:	03842023          	sw	s8,32(s0)
    9d84:	00642623          	sw	t1,12(s0)
    9d88:	0004a683          	lw	a3,0(s1)
    9d8c:	00092783          	lw	a5,0(s2)
    9d90:	00168693          	addi	a3,a3,1
    9d94:	00178793          	addi	a5,a5,1 # 1a001 <__kernel_data_lma+0xe74d>
    9d98:	00d4a023          	sw	a3,0(s1)
    9d9c:	00f92023          	sw	a5,0(s2)
    9da0:	05942023          	sw	s9,64(s0)
    9da4:	41858e33          	sub	t3,a1,s8
    9da8:	018706b3          	add	a3,a4,s8
    9dac:	018507b3          	add	a5,a0,s8
    9db0:	07cc78e3          	bgeu	s8,t3,a620 <.L797>
    9db4:	ffff8337          	lui	t1,0xffff8
    9db8:	fff30313          	addi	t1,t1,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    9dbc:	ffffcf37          	lui	t5,0xffffc
    9dc0:	00658333          	add	t1,a1,t1
    9dc4:	00008e37          	lui	t3,0x8
    9dc8:	01c70e33          	add	t3,a4,t3
    9dcc:	01e37eb3          	and	t4,t1,t5
    9dd0:	40ef0733          	sub	a4,t5,a4
    9dd4:	01de0e33          	add	t3,t3,t4
    9dd8:	00f70733          	add	a4,a4,a5

00009ddc <.L739>:
    9ddc:	04042783          	lw	a5,64(s0)
    9de0:	fe079ee3          	bnez	a5,9ddc <.L739>
    9de4:	00d42023          	sw	a3,0(s0)
    9de8:	00d707b3          	add	a5,a4,a3
    9dec:	00f42623          	sw	a5,12(s0)
    9df0:	0004a783          	lw	a5,0(s1)
    9df4:	018686b3          	add	a3,a3,s8
    9df8:	00178793          	addi	a5,a5,1
    9dfc:	00f4a023          	sw	a5,0(s1)
    9e00:	00092783          	lw	a5,0(s2)
    9e04:	00178793          	addi	a5,a5,1
    9e08:	00f92023          	sw	a5,0(s2)
    9e0c:	05942023          	sw	s9,64(s0)
    9e10:	fdc696e3          	bne	a3,t3,9ddc <.L739>
    9e14:	00e35313          	srli	t1,t1,0xe
    9e18:	000087b7          	lui	a5,0x8
    9e1c:	00f50533          	add	a0,a0,a5
    9e20:	00e31793          	slli	a5,t1,0xe
    9e24:	00078e93          	mv	t4,a5
    9e28:	00a78333          	add	t1,a5,a0
    9e2c:	ffff87b7          	lui	a5,0xffff8
    9e30:	00f58e33          	add	t3,a1,a5
    9e34:	00068713          	mv	a4,a3
    9e38:	41de0e33          	sub	t3,t3,t4

00009e3c <.L741>:
    9e3c:	04042783          	lw	a5,64(s0)
    9e40:	fe079ee3          	bnez	a5,9e3c <.L741>

00009e44 <.L803>:
    9e44:	00e42023          	sw	a4,0(s0)
    9e48:	03c42023          	sw	t3,32(s0)
    9e4c:	00642623          	sw	t1,12(s0)
    9e50:	0004a703          	lw	a4,0(s1)
    9e54:	00092783          	lw	a5,0(s2)
    9e58:	00170713          	addi	a4,a4,1
    9e5c:	00178793          	addi	a5,a5,1 # ffff8001 <__instrn_buffer+0x1b8001>
    9e60:	00f92023          	sw	a5,0(s2)
    9e64:	00e4a023          	sw	a4,0(s1)
    9e68:	05942023          	sw	s9,64(s0)
    9e6c:	918aa783          	lw	a5,-1768(s5)
    9e70:	411a0a33          	sub	s4,s4,a7
    9e74:	00b787b3          	add	a5,a5,a1
    9e78:	90faac23          	sw	a5,-1768(s5)
    9e7c:	1c0a0263          	beqz	s4,a040 <.L792>
    9e80:	00038713          	mv	a4,t2
    9e84:	ea0810e3          	bnez	a6,9d24 <.L724>

00009e88 <.L795>:
    9e88:	0004a703          	lw	a4,0(s1)

00009e8c <.L725>:
    9e8c:	22842783          	lw	a5,552(s0)
    9e90:	fee79ee3          	bne	a5,a4,9e8c <.L725>
    9e94:	0ff0000f          	fence
    9e98:	000d8593          	mv	a1,s11
    9e9c:	02810513          	addi	a0,sp,40
    9ea0:	d3dfa0ef          	jal	4bdc <_Z24paged_read_into_cmddat_qRmR20PrefetchExecBufState>
    9ea4:	010da803          	lw	a6,16(s11)
    9ea8:	02812703          	lw	a4,40(sp)
    9eac:	00080613          	mv	a2,a6
    9eb0:	e75ff06f          	j	9d24 <.L724>

00009eb4 <.L690>:
    9eb4:	00454603          	lbu	a2,4(a0)
    9eb8:	00554703          	lbu	a4,5(a0)
    9ebc:	00654783          	lbu	a5,6(a0)
    9ec0:	00754403          	lbu	s0,7(a0)
    9ec4:	00254683          	lbu	a3,2(a0)
    9ec8:	00354583          	lbu	a1,3(a0)
    9ecc:	00871713          	slli	a4,a4,0x8
    9ed0:	00c76733          	or	a4,a4,a2
    9ed4:	01079793          	slli	a5,a5,0x10
    9ed8:	00859593          	slli	a1,a1,0x8
    9edc:	00e7e7b3          	or	a5,a5,a4
    9ee0:	00d5e5b3          	or	a1,a1,a3
    9ee4:	00854703          	lbu	a4,8(a0)
    9ee8:	20b5a5b3          	sh1add	a1,a1,a1
    9eec:	00954683          	lbu	a3,9(a0)
    9ef0:	01841413          	slli	s0,s0,0x18
    9ef4:	00869693          	slli	a3,a3,0x8
    9ef8:	00e6e6b3          	or	a3,a3,a4
    9efc:	00a54703          	lbu	a4,10(a0)
    9f00:	00f46433          	or	s0,s0,a5
    9f04:	00b54783          	lbu	a5,11(a0)
    9f08:	00812483          	lw	s1,8(sp)
    9f0c:	01071713          	slli	a4,a4,0x10
    9f10:	00d76733          	or	a4,a4,a3
    9f14:	01879793          	slli	a5,a5,0x18
    9f18:	00e7e7b3          	or	a5,a5,a4
    9f1c:	00048613          	mv	a2,s1
    9f20:	00259593          	slli	a1,a1,0x2
    9f24:	02c10713          	addi	a4,sp,44
    9f28:	000d8693          	mv	a3,s11
    9f2c:	02810513          	addi	a0,sp,40
    9f30:	02f12623          	sw	a5,44(sp)
    9f34:	911ff0ef          	jal	9844 <_Z25copy_sub_cmds_to_l1_cacheILb0ELb1E31CQPrefetchRelayRingbufferSubCmdEPT1_RmmPmR20PrefetchExecBufStateS3_>
    9f38:	00100713          	li	a4,1
    9f3c:	00050793          	mv	a5,a0
    9f40:	000784a3          	sb	zero,9(a5)
    9f44:	00040513          	mv	a0,s0
    9f48:	00078523          	sb	zero,10(a5)
    9f4c:	000785a3          	sb	zero,11(a5)
    9f50:	00e78423          	sb	a4,8(a5)
    9f54:	00048593          	mv	a1,s1
    9f58:	8a1fc0ef          	jal	67f8 <_Z35process_relay_paged_packed_sub_cmdsmPm>
    9f5c:	02c12983          	lw	s3,44(sp)
    9f60:	010da603          	lw	a2,16(s11)
    9f64:	02812503          	lw	a0,40(sp)
    9f68:	c01ff06f          	j	9b68 <.L693>

00009f6c <.L691>:
    9f6c:	00254703          	lbu	a4,2(a0)
    9f70:	00354783          	lbu	a5,3(a0)
    9f74:	00154583          	lbu	a1,1(a0)
    9f78:	00879793          	slli	a5,a5,0x8
    9f7c:	00e7e7b3          	or	a5,a5,a4
    9f80:	60579793          	sext.h	a5,a5
    9f84:	0ff5f593          	zext.b	a1,a1
    9f88:	6a07c663          	bltz	a5,a634 <.L798>
    9f8c:	c14fe0ef          	jal	83a0 <_Z23process_relay_paged_cmdILb0EEmmRmm.constprop.0.isra.0>
    9f90:	04000993          	li	s3,64
    9f94:	010da603          	lw	a2,16(s11)
    9f98:	02812503          	lw	a0,40(sp)
    9f9c:	bcdff06f          	j	9b68 <.L693>

00009fa0 <.L692>:
    9fa0:	ff5fc0ef          	jal	6f94 <_Z24process_relay_linear_cmdmRm.constprop.0.isra.0>
    9fa4:	04000993          	li	s3,64
    9fa8:	010da603          	lw	a2,16(s11)
    9fac:	02812503          	lw	a0,40(sp)
    9fb0:	bb9ff06f          	j	9b68 <.L693>

00009fb4 <.L689>:
    9fb4:	00154783          	lbu	a5,1(a0)
    9fb8:	1e079a63          	bnez	a5,a1ac <.L695>
    9fbc:	000d8593          	mv	a1,s11
    9fc0:	02810513          	addi	a0,sp,40
    9fc4:	e30fb0ef          	jal	55f4 <_Z27process_relay_inline_commonILb0ELb1ELb1E24DispatchRelayInlineStateEmRmS1_R20PrefetchExecBufState.constprop.0>
    9fc8:	00050993          	mv	s3,a0
    9fcc:	010da603          	lw	a2,16(s11)
    9fd0:	02812503          	lw	a0,40(sp)
    9fd4:	b95ff06f          	j	9b68 <.L693>

00009fd8 <.L679>:
    9fd8:	00254583          	lbu	a1,2(a0)
    9fdc:	00354783          	lbu	a5,3(a0)
    9fe0:	00454803          	lbu	a6,4(a0)
    9fe4:	00554603          	lbu	a2,5(a0)
    9fe8:	00654683          	lbu	a3,6(a0)
    9fec:	00861613          	slli	a2,a2,0x8
    9ff0:	00754703          	lbu	a4,7(a0)
    9ff4:	01066633          	or	a2,a2,a6
    9ff8:	00812483          	lw	s1,8(sp)
    9ffc:	00879793          	slli	a5,a5,0x8
    a000:	01069693          	slli	a3,a3,0x10
    a004:	00b7e433          	or	s0,a5,a1
    a008:	00c6e6b3          	or	a3,a3,a2
    a00c:	01871793          	slli	a5,a4,0x18
    a010:	00d7e7b3          	or	a5,a5,a3
    a014:	00341593          	slli	a1,s0,0x3
    a018:	02c10713          	addi	a4,sp,44
    a01c:	000d8693          	mv	a3,s11
    a020:	00048613          	mv	a2,s1
    a024:	02810513          	addi	a0,sp,40
    a028:	02f12623          	sw	a5,44(sp)
    a02c:	819ff0ef          	jal	9844 <_Z25copy_sub_cmds_to_l1_cacheILb0ELb1E31CQPrefetchRelayRingbufferSubCmdEPT1_RmmPmR20PrefetchExecBufStateS3_>
    a030:	00048593          	mv	a1,s1
    a034:	00040513          	mv	a0,s0
    a038:	eb1fb0ef          	jal	5ee8 <_Z33process_relay_ringbuffer_sub_cmdsmPm>
    a03c:	02c12983          	lw	s3,44(sp)

0000a040 <.L792>:
    a040:	010da603          	lw	a2,16(s11)
    a044:	02812503          	lw	a0,40(sp)
    a048:	b21ff06f          	j	9b68 <.L693>

0000a04c <.L796>:
    a04c:	fff6a7b7          	lui	a5,0xfff6a
    a050:	00f507b3          	add	a5,a0,a5
    a054:	00050693          	mv	a3,a0
    a058:	000e0593          	mv	a1,t3
    a05c:	00070293          	mv	t0,a4
    a060:	0efc7a63          	bgeu	s8,a5,a154 <.L735>
    a064:	ffb206b7          	lui	a3,0xffb20

0000a068 <.L731>:
    a068:	0406a783          	lw	a5,64(a3) # ffb20040 <__stack_top+0x1e040>
    a06c:	fe079ee3          	bnez	a5,a068 <.L731>
    a070:	00e6a023          	sw	a4,0(a3)
    a074:	000045b7          	lui	a1,0x4
    a078:	02b6a023          	sw	a1,32(a3)
    a07c:	00a6a623          	sw	a0,12(a3)
    a080:	0004a303          	lw	t1,0(s1)
    a084:	00092783          	lw	a5,0(s2)
    a088:	00130313          	addi	t1,t1,1
    a08c:	00178793          	addi	a5,a5,1 # fff6a001 <__instrn_buffer+0x12a001>
    a090:	00f92023          	sw	a5,0(s2)
    a094:	0064a023          	sw	t1,0(s1)
    a098:	00100f13          	li	t5,1
    a09c:	fff6e7b7          	lui	a5,0xfff6e
    a0a0:	05e6a023          	sw	t5,64(a3)
    a0a4:	00f507b3          	add	a5,a0,a5
    a0a8:	00b702b3          	add	t0,a4,a1
    a0ac:	00b506b3          	add	a3,a0,a1
    a0b0:	5cf5f063          	bgeu	a1,a5,a670 <.L799>
    a0b4:	000927b7          	lui	a5,0x92
    a0b8:	fff78793          	addi	a5,a5,-1 # 91fff <__kernel_data_lma+0x8674b>
    a0bc:	40a786b3          	sub	a3,a5,a0
    a0c0:	ffffc7b7          	lui	a5,0xffffc
    a0c4:	00f6f7b3          	and	a5,a3,a5
    a0c8:	00008eb7          	lui	t4,0x8
    a0cc:	01d78eb3          	add	t4,a5,t4
    a0d0:	00d12623          	sw	a3,12(sp)
    a0d4:	00f12823          	sw	a5,16(sp)
    a0d8:	00ee8eb3          	add	t4,t4,a4
    a0dc:	00028313          	mv	t1,t0
    a0e0:	ffb206b7          	lui	a3,0xffb20
    a0e4:	40e50fb3          	sub	t6,a0,a4

0000a0e8 <.L733>:
    a0e8:	0406a783          	lw	a5,64(a3) # ffb20040 <__stack_top+0x1e040>
    a0ec:	fe079ee3          	bnez	a5,a0e8 <.L733>
    a0f0:	0066a023          	sw	t1,0(a3)
    a0f4:	006f87b3          	add	a5,t6,t1
    a0f8:	00f6a623          	sw	a5,12(a3)
    a0fc:	0004a783          	lw	a5,0(s1)
    a100:	00b30333          	add	t1,t1,a1
    a104:	00178793          	addi	a5,a5,1 # ffffc001 <__instrn_buffer+0x1bc001>
    a108:	00f4a023          	sw	a5,0(s1)
    a10c:	00092783          	lw	a5,0(s2)
    a110:	00178793          	addi	a5,a5,1
    a114:	00f92023          	sw	a5,0(s2)
    a118:	05e6a023          	sw	t5,64(a3)
    a11c:	fdd316e3          	bne	t1,t4,a0e8 <.L733>
    a120:	00c12783          	lw	a5,12(sp)
    a124:	01012683          	lw	a3,16(sp)
    a128:	00e7d793          	srli	a5,a5,0xe
    a12c:	00b686b3          	add	a3,a3,a1
    a130:	000925b7          	lui	a1,0x92
    a134:	00d282b3          	add	t0,t0,a3
    a138:	40a585b3          	sub	a1,a1,a0
    a13c:	00e79693          	slli	a3,a5,0xe
    a140:	00068793          	mv	a5,a3
    a144:	40d585b3          	sub	a1,a1,a3
    a148:	000086b7          	lui	a3,0x8
    a14c:	00d506b3          	add	a3,a0,a3
    a150:	00f686b3          	add	a3,a3,a5

0000a154 <.L735>:
    a154:	04042783          	lw	a5,64(s0)
    a158:	fe079ee3          	bnez	a5,a154 <.L735>

0000a15c <.L805>:
    a15c:	00542023          	sw	t0,0(s0)
    a160:	02b42023          	sw	a1,32(s0)
    a164:	00d42623          	sw	a3,12(s0)
    a168:	0004a683          	lw	a3,0(s1)
    a16c:	00092783          	lw	a5,0(s2)
    a170:	fff665b7          	lui	a1,0xfff66
    a174:	00168693          	addi	a3,a3,1 # 8001 <.L417+0x25>
    a178:	00178793          	addi	a5,a5,1
    a17c:	00b50533          	add	a0,a0,a1
    a180:	00d4a023          	sw	a3,0(s1)
    a184:	00f92023          	sw	a5,0(s2)
    a188:	011505b3          	add	a1,a0,a7
    a18c:	01c70733          	add	a4,a4,t3
    a190:	05942023          	sw	s9,64(s0)
    a194:	bcdff06f          	j	9d60 <.L729>

0000a198 <.L744>:
    a198:	ffb01737          	lui	a4,0xffb01
    a19c:	010da603          	lw	a2,16(s11)
    a1a0:	92f72623          	sw	a5,-1748(a4) # ffb0092c <_ZL17ringbuffer_offset>
    a1a4:	04000993          	li	s3,64
    a1a8:	9c1ff06f          	j	9b68 <.L693>

0000a1ac <.L695>:
    a1ac:	ffb017b7          	lui	a5,0xffb01
    a1b0:	86c78793          	addi	a5,a5,-1940 # ffb0086c <sem_l1_base>
    a1b4:	0007a683          	lw	a3,0(a5)
    a1b8:	00f12a23          	sw	a5,20(sp)
    a1bc:	00454703          	lbu	a4,4(a0)
    a1c0:	00554783          	lbu	a5,5(a0)
    a1c4:	00654603          	lbu	a2,6(a0)
    a1c8:	00879793          	slli	a5,a5,0x8
    a1cc:	00754403          	lbu	s0,7(a0)
    a1d0:	00e7e7b3          	or	a5,a5,a4
    a1d4:	00854583          	lbu	a1,8(a0)
    a1d8:	01061613          	slli	a2,a2,0x10
    a1dc:	00954703          	lbu	a4,9(a0)
    a1e0:	00f66633          	or	a2,a2,a5
    a1e4:	01841413          	slli	s0,s0,0x18
    a1e8:	00a54783          	lbu	a5,10(a0)
    a1ec:	00c46433          	or	s0,s0,a2
    a1f0:	00b54983          	lbu	s3,11(a0)
    a1f4:	00871713          	slli	a4,a4,0x8
    a1f8:	ffb00637          	lui	a2,0xffb00
    a1fc:	00b76733          	or	a4,a4,a1
    a200:	02460613          	addi	a2,a2,36 # ffb00024 <noc_nonposted_atomics_acked>
    a204:	01079793          	slli	a5,a5,0x10
    a208:	00e7e7b3          	or	a5,a5,a4
    a20c:	00c12c23          	sw	a2,24(sp)
    a210:	0ff40593          	addi	a1,s0,255
    a214:	01899993          	slli	s3,s3,0x18
    a218:	00062603          	lw	a2,0(a2)
    a21c:	00f9e9b3          	or	s3,s3,a5
    a220:	0085db13          	srli	s6,a1,0x8
    a224:	01068693          	addi	a3,a3,16
    a228:	ffb20737          	lui	a4,0xffb20

0000a22c <.L696>:
    a22c:	20072783          	lw	a5,512(a4) # ffb20200 <__stack_top+0x1e200>
    a230:	fec79ee3          	bne	a5,a2,a22c <.L696>
    a234:	0ff0000f          	fence
    a238:	ffb01637          	lui	a2,0xffb01

0000a23c <.L697>:
    a23c:	0ff0000f          	fence
    a240:	0006a783          	lw	a5,0(a3)
    a244:	92862703          	lw	a4,-1752(a2) # ffb00928 <_ZN25DispatchSRelayInlineState9cb_writerE>
    a248:	00f707b3          	add	a5,a4,a5
    a24c:	40fb07b3          	sub	a5,s6,a5
    a250:	fef046e3          	bgtz	a5,a23c <.L697>
    a254:	41670733          	sub	a4,a4,s6
    a258:	92e62423          	sw	a4,-1752(a2)
    a25c:	40040063          	beqz	s0,a65c <.L698>
    a260:	010da283          	lw	t0,16(s11)
    a264:	02812303          	lw	t1,40(sp)
    a268:	0102b513          	sltiu	a0,t0,16
    a26c:	fff50513          	addi	a0,a0,-1
    a270:	ff028793          	addi	a5,t0,-16 # 95ff0 <__kernel_data_lma+0x8a73c>
    a274:	ffb004b7          	lui	s1,0xffb00
    a278:	ffb00937          	lui	s2,0xffb00
    a27c:	00f57533          	and	a0,a0,a5
    a280:	01030313          	addi	t1,t1,16
    a284:	03448493          	addi	s1,s1,52 # ffb00034 <noc_nonposted_writes_num_issued>
    a288:	02c90913          	addi	s2,s2,44 # ffb0002c <noc_nonposted_writes_acked>
    a28c:	ffb01a37          	lui	s4,0xffb01
    a290:	ffb20ab7          	lui	s5,0xffb20
    a294:	000a23b7          	lui	t2,0xa2
    a298:	01612e23          	sw	s6,28(sp)

0000a29c <.L717>:
    a29c:	00030713          	mv	a4,t1
    a2a0:	1e050a63          	beqz	a0,a494 <.L800>

0000a2a4 <.L699>:
    a2a4:	0a855833          	minu	a6,a0,s0
    a2a8:	41050533          	sub	a0,a0,a6
    a2ac:	00e80333          	add	t1,a6,a4
    a2b0:	00051c63          	bnez	a0,a2c8 <.L701>
    a2b4:	02812783          	lw	a5,40(sp)
    a2b8:	405989b3          	sub	s3,s3,t0
    a2bc:	005787b3          	add	a5,a5,t0
    a2c0:	000da823          	sw	zero,16(s11)
    a2c4:	02f12423          	sw	a5,40(sp)

0000a2c8 <.L701>:
    a2c8:	914a2603          	lw	a2,-1772(s4) # ffb00914 <_ZL21downstream_data_ptr_s>
    a2cc:	00080593          	mv	a1,a6
    a2d0:	40c38e33          	sub	t3,t2,a2
    a2d4:	00060893          	mv	a7,a2
    a2d8:	010e7a63          	bgeu	t3,a6,a2ec <.L703>
    a2dc:	1e761463          	bne	a2,t2,a4c4 <.L801>

0000a2e0 <.L704>:
    a2e0:	0009a8b7          	lui	a7,0x9a
    a2e4:	911a2a23          	sw	a7,-1772(s4)
    a2e8:	00088613          	mv	a2,a7

0000a2ec <.L703>:
    a2ec:	00058e13          	mv	t3,a1
    a2f0:	0cbc7663          	bgeu	s8,a1,a3bc <.L716>

0000a2f4 <.L712>:
    a2f4:	040d2783          	lw	a5,64(s10) # ffb21040 <__stack_top+0x1f040>
    a2f8:	fe079ee3          	bnez	a5,a2f4 <.L712>
    a2fc:	00ed2023          	sw	a4,0(s10)
    a300:	038d2023          	sw	s8,32(s10)
    a304:	011d2623          	sw	a7,12(s10)
    a308:	0004a683          	lw	a3,0(s1)
    a30c:	00092783          	lw	a5,0(s2)
    a310:	00168693          	addi	a3,a3,1
    a314:	00178793          	addi	a5,a5,1
    a318:	00d4a023          	sw	a3,0(s1)
    a31c:	00f92023          	sw	a5,0(s2)
    a320:	059d2023          	sw	s9,64(s10)
    a324:	41858e33          	sub	t3,a1,s8
    a328:	018706b3          	add	a3,a4,s8
    a32c:	018607b3          	add	a5,a2,s8
    a330:	31cc7c63          	bgeu	s8,t3,a648 <.L802>
    a334:	ffff88b7          	lui	a7,0xffff8
    a338:	fff88893          	addi	a7,a7,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    a33c:	ffffcf37          	lui	t5,0xffffc
    a340:	011588b3          	add	a7,a1,a7
    a344:	00008eb7          	lui	t4,0x8
    a348:	01d70eb3          	add	t4,a4,t4
    a34c:	01e8fe33          	and	t3,a7,t5
    a350:	40ef0733          	sub	a4,t5,a4
    a354:	01de0e33          	add	t3,t3,t4
    a358:	00f70733          	add	a4,a4,a5

0000a35c <.L714>:
    a35c:	040d2783          	lw	a5,64(s10)
    a360:	fe079ee3          	bnez	a5,a35c <.L714>
    a364:	00dd2023          	sw	a3,0(s10)
    a368:	00d707b3          	add	a5,a4,a3
    a36c:	00fd2623          	sw	a5,12(s10)
    a370:	0004a783          	lw	a5,0(s1)
    a374:	018686b3          	add	a3,a3,s8
    a378:	00178793          	addi	a5,a5,1
    a37c:	00f4a023          	sw	a5,0(s1)
    a380:	00092783          	lw	a5,0(s2)
    a384:	00178793          	addi	a5,a5,1
    a388:	00f92023          	sw	a5,0(s2)
    a38c:	059d2023          	sw	s9,64(s10)
    a390:	fdc696e3          	bne	a3,t3,a35c <.L714>
    a394:	00e8d893          	srli	a7,a7,0xe
    a398:	000087b7          	lui	a5,0x8
    a39c:	00f60633          	add	a2,a2,a5
    a3a0:	00e89793          	slli	a5,a7,0xe
    a3a4:	00078e93          	mv	t4,a5
    a3a8:	00c788b3          	add	a7,a5,a2
    a3ac:	ffff87b7          	lui	a5,0xffff8
    a3b0:	00f58e33          	add	t3,a1,a5
    a3b4:	00068713          	mv	a4,a3
    a3b8:	41de0e33          	sub	t3,t3,t4

0000a3bc <.L716>:
    a3bc:	040d2783          	lw	a5,64(s10)
    a3c0:	fe079ee3          	bnez	a5,a3bc <.L716>

0000a3c4 <.L804>:
    a3c4:	00ed2023          	sw	a4,0(s10)
    a3c8:	03cd2023          	sw	t3,32(s10)
    a3cc:	011d2623          	sw	a7,12(s10)
    a3d0:	0004a703          	lw	a4,0(s1)
    a3d4:	00092783          	lw	a5,0(s2)
    a3d8:	00170713          	addi	a4,a4,1
    a3dc:	00178793          	addi	a5,a5,1 # ffff8001 <__instrn_buffer+0x1b8001>
    a3e0:	00f92023          	sw	a5,0(s2)
    a3e4:	00e4a023          	sw	a4,0(s1)
    a3e8:	059d2023          	sw	s9,64(s10)
    a3ec:	914a2783          	lw	a5,-1772(s4)
    a3f0:	41040433          	sub	s0,s0,a6
    a3f4:	00f586b3          	add	a3,a1,a5
    a3f8:	90da2a23          	sw	a3,-1772(s4)
    a3fc:	ea0410e3          	bnez	s0,a29c <.L717>
    a400:	01c12b03          	lw	s6,28(sp)

0000a404 <.L718>:
    a404:	0ff68693          	addi	a3,a3,255
    a408:	f006f793          	andi	a5,a3,-256
    a40c:	0004a683          	lw	a3,0(s1)
    a410:	90fa2a23          	sw	a5,-1772(s4)
    a414:	ffb20737          	lui	a4,0xffb20

0000a418 <.L719>:
    a418:	22872783          	lw	a5,552(a4) # ffb20228 <__stack_top+0x1e228>
    a41c:	fed79ee3          	bne	a5,a3,a418 <.L719>
    a420:	0ff0000f          	fence
    a424:	01412783          	lw	a5,20(sp)
    a428:	ffb22737          	lui	a4,0xffb22
    a42c:	0007a683          	lw	a3,0(a5)

0000a430 <.L720>:
    a430:	84072783          	lw	a5,-1984(a4) # ffb21840 <__stack_top+0x1f840>
    a434:	fe079ee3          	bnez	a5,a430 <.L720>
    a438:	80d72023          	sw	a3,-2048(a4)
    a43c:	0026d793          	srli	a5,a3,0x2
    a440:	000016b7          	lui	a3,0x1
    a444:	07c68693          	addi	a3,a3,124 # 107c <_start-0x3954>
    a448:	0037f793          	andi	a5,a5,3
    a44c:	80072223          	sw	zero,-2044(a4)
    a450:	00d7e7b3          	or	a5,a5,a3
    a454:	0ce00693          	li	a3,206
    a458:	80d72423          	sw	a3,-2040(a4)
    a45c:	000026b7          	lui	a3,0x2
    a460:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    a464:	80d72e23          	sw	a3,-2020(a4)
    a468:	82f72023          	sw	a5,-2016(a4)
    a46c:	83672423          	sw	s6,-2008(a4)
    a470:	00100793          	li	a5,1
    a474:	84f72023          	sw	a5,-1984(a4)
    a478:	01812703          	lw	a4,24(sp)
    a47c:	010da603          	lw	a2,16(s11)
    a480:	00072783          	lw	a5,0(a4)
    a484:	02812503          	lw	a0,40(sp)
    a488:	00178793          	addi	a5,a5,1
    a48c:	00f72023          	sw	a5,0(a4)
    a490:	ed8ff06f          	j	9b68 <.L693>

0000a494 <.L800>:
    a494:	0004a703          	lw	a4,0(s1)

0000a498 <.L700>:
    a498:	228aa783          	lw	a5,552(s5) # ffb20228 <__stack_top+0x1e228>
    a49c:	fee79ee3          	bne	a5,a4,a498 <.L700>
    a4a0:	0ff0000f          	fence
    a4a4:	02810513          	addi	a0,sp,40
    a4a8:	000d8593          	mv	a1,s11
    a4ac:	f30fa0ef          	jal	4bdc <_Z24paged_read_into_cmddat_qRmR20PrefetchExecBufState>
    a4b0:	010da503          	lw	a0,16(s11)
    a4b4:	02812703          	lw	a4,40(sp)
    a4b8:	00050293          	mv	t0,a0
    a4bc:	000a23b7          	lui	t2,0xa2
    a4c0:	de5ff06f          	j	a2a4 <.L699>

0000a4c4 <.L801>:
    a4c4:	fff627b7          	lui	a5,0xfff62
    a4c8:	00f607b3          	add	a5,a2,a5
    a4cc:	000046b7          	lui	a3,0x4
    a4d0:	00060593          	mv	a1,a2
    a4d4:	000e0893          	mv	a7,t3
    a4d8:	00070b13          	mv	s6,a4
    a4dc:	0ef6fc63          	bgeu	a3,a5,a5d4 <.L705>
    a4e0:	ffb216b7          	lui	a3,0xffb21

0000a4e4 <.L706>:
    a4e4:	0406a783          	lw	a5,64(a3) # ffb21040 <__stack_top+0x1f040>
    a4e8:	fe079ee3          	bnez	a5,a4e4 <.L706>
    a4ec:	00e6a023          	sw	a4,0(a3)
    a4f0:	00004eb7          	lui	t4,0x4
    a4f4:	03d6a023          	sw	t4,32(a3)
    a4f8:	00c6a623          	sw	a2,12(a3)
    a4fc:	0004a583          	lw	a1,0(s1)
    a500:	00092783          	lw	a5,0(s2)
    a504:	00158593          	addi	a1,a1,1 # fff66001 <__instrn_buffer+0x126001>
    a508:	00178793          	addi	a5,a5,1 # fff62001 <__instrn_buffer+0x122001>
    a50c:	00b4a023          	sw	a1,0(s1)
    a510:	00f92023          	sw	a5,0(s2)
    a514:	00100f13          	li	t5,1
    a518:	fff667b7          	lui	a5,0xfff66
    a51c:	0009e8b7          	lui	a7,0x9e
    a520:	05e6a023          	sw	t5,64(a3)
    a524:	00f607b3          	add	a5,a2,a5
    a528:	01d70b33          	add	s6,a4,t4
    a52c:	01d605b3          	add	a1,a2,t4
    a530:	40c888b3          	sub	a7,a7,a2
    a534:	0afef063          	bgeu	t4,a5,a5d4 <.L705>
    a538:	0009a7b7          	lui	a5,0x9a
    a53c:	fff78793          	addi	a5,a5,-1 # 99fff <__kernel_data_lma+0x8e74b>
    a540:	40c786b3          	sub	a3,a5,a2
    a544:	ffffc7b7          	lui	a5,0xffffc
    a548:	00f6f7b3          	and	a5,a3,a5
    a54c:	000085b7          	lui	a1,0x8
    a550:	00b785b3          	add	a1,a5,a1
    a554:	00d12823          	sw	a3,16(sp)
    a558:	00f12623          	sw	a5,12(sp)
    a55c:	00e585b3          	add	a1,a1,a4
    a560:	000b0893          	mv	a7,s6
    a564:	ffb216b7          	lui	a3,0xffb21
    a568:	40e60fb3          	sub	t6,a2,a4

0000a56c <.L708>:
    a56c:	0406a783          	lw	a5,64(a3) # ffb21040 <__stack_top+0x1f040>
    a570:	fe079ee3          	bnez	a5,a56c <.L708>
    a574:	0116a023          	sw	a7,0(a3)
    a578:	011f87b3          	add	a5,t6,a7
    a57c:	00f6a623          	sw	a5,12(a3)
    a580:	0004a783          	lw	a5,0(s1)
    a584:	01d888b3          	add	a7,a7,t4
    a588:	00178793          	addi	a5,a5,1 # ffffc001 <__instrn_buffer+0x1bc001>
    a58c:	00f4a023          	sw	a5,0(s1)
    a590:	00092783          	lw	a5,0(s2)
    a594:	00178793          	addi	a5,a5,1
    a598:	00f92023          	sw	a5,0(s2)
    a59c:	05e6a023          	sw	t5,64(a3)
    a5a0:	fcb896e3          	bne	a7,a1,a56c <.L708>
    a5a4:	01012783          	lw	a5,16(sp)
    a5a8:	00c12683          	lw	a3,12(sp)
    a5ac:	00e7d793          	srli	a5,a5,0xe
    a5b0:	01d686b3          	add	a3,a3,t4
    a5b4:	0009a8b7          	lui	a7,0x9a
    a5b8:	000085b7          	lui	a1,0x8
    a5bc:	00db0b33          	add	s6,s6,a3
    a5c0:	40c888b3          	sub	a7,a7,a2
    a5c4:	00e79693          	slli	a3,a5,0xe
    a5c8:	00b605b3          	add	a1,a2,a1
    a5cc:	40d888b3          	sub	a7,a7,a3
    a5d0:	00b685b3          	add	a1,a3,a1

0000a5d4 <.L705>:
    a5d4:	ffb216b7          	lui	a3,0xffb21

0000a5d8 <.L710>:
    a5d8:	0406a783          	lw	a5,64(a3) # ffb21040 <__stack_top+0x1f040>
    a5dc:	fe079ee3          	bnez	a5,a5d8 <.L710>
    a5e0:	0166a023          	sw	s6,0(a3)
    a5e4:	0316a023          	sw	a7,32(a3)
    a5e8:	00b6a623          	sw	a1,12(a3)
    a5ec:	0004a583          	lw	a1,0(s1)
    a5f0:	00092783          	lw	a5,0(s2)
    a5f4:	00158593          	addi	a1,a1,1 # 8001 <.L417+0x25>
    a5f8:	00178793          	addi	a5,a5,1
    a5fc:	fff5e8b7          	lui	a7,0xfff5e
    a600:	00b4a023          	sw	a1,0(s1)
    a604:	00f92023          	sw	a5,0(s2)
    a608:	01160633          	add	a2,a2,a7
    a60c:	00100793          	li	a5,1
    a610:	01c70733          	add	a4,a4,t3
    a614:	010605b3          	add	a1,a2,a6
    a618:	04f6a023          	sw	a5,64(a3)
    a61c:	cc5ff06f          	j	a2e0 <.L704>

0000a620 <.L797>:
    a620:	00078313          	mv	t1,a5
    a624:	04042783          	lw	a5,64(s0)
    a628:	00068713          	mv	a4,a3
    a62c:	800798e3          	bnez	a5,9e3c <.L741>
    a630:	815ff06f          	j	9e44 <.L803>

0000a634 <.L798>:
    a634:	d8dfc0ef          	jal	73c0 <_Z23process_relay_paged_cmdILb1EEmmRmm.constprop.0.isra.0>
    a638:	04000993          	li	s3,64
    a63c:	010da603          	lw	a2,16(s11)
    a640:	02812503          	lw	a0,40(sp)
    a644:	d24ff06f          	j	9b68 <.L693>

0000a648 <.L802>:
    a648:	00078893          	mv	a7,a5
    a64c:	040d2783          	lw	a5,64(s10)
    a650:	00068713          	mv	a4,a3
    a654:	d60794e3          	bnez	a5,a3bc <.L716>
    a658:	d6dff06f          	j	a3c4 <.L804>

0000a65c <.L698>:
    a65c:	ffb01a37          	lui	s4,0xffb01
    a660:	ffb004b7          	lui	s1,0xffb00
    a664:	914a2683          	lw	a3,-1772(s4) # ffb00914 <_ZL21downstream_data_ptr_s>
    a668:	03448493          	addi	s1,s1,52 # ffb00034 <noc_nonposted_writes_num_issued>
    a66c:	d99ff06f          	j	a404 <.L718>

0000a670 <.L799>:
    a670:	04042783          	lw	a5,64(s0)
    a674:	000965b7          	lui	a1,0x96
    a678:	40a585b3          	sub	a1,a1,a0
    a67c:	ac079ce3          	bnez	a5,a154 <.L735>
    a680:	addff06f          	j	a15c <.L805>

0000a684 <_Z14kernel_main_hdv>:
    a684:	0001a7b7          	lui	a5,0x1a
    a688:	db010113          	addi	sp,sp,-592
    a68c:	44078793          	addi	a5,a5,1088 # 1a440 <__kernel_data_lma+0xeb8c>
    a690:	24112623          	sw	ra,588(sp)
    a694:	24812423          	sw	s0,584(sp)
    a698:	24912223          	sw	s1,580(sp)
    a69c:	25212023          	sw	s2,576(sp)
    a6a0:	23312e23          	sw	s3,572(sp)
    a6a4:	23412c23          	sw	s4,568(sp)
    a6a8:	23512a23          	sw	s5,564(sp)
    a6ac:	23612823          	sw	s6,560(sp)
    a6b0:	23712623          	sw	s7,556(sp)
    a6b4:	23812423          	sw	s8,552(sp)
    a6b8:	23912223          	sw	s9,548(sp)
    a6bc:	23a12023          	sw	s10,544(sp)
    a6c0:	21b12e23          	sw	s11,540(sp)
    a6c4:	02f12623          	sw	a5,44(sp)
    a6c8:	ffb20737          	lui	a4,0xffb20

0000a6cc <.L807>:
    a6cc:	04072783          	lw	a5,64(a4) # ffb20040 <__stack_top+0x1e040>
    a6d0:	fe079ee3          	bnez	a5,a6cc <.L807>
    a6d4:	000027b7          	lui	a5,0x2
    a6d8:	09278793          	addi	a5,a5,146 # 2092 <_start-0x293e>
    a6dc:	00f72e23          	sw	a5,28(a4)
    a6e0:	00072823          	sw	zero,16(a4)
    a6e4:	0ce00793          	li	a5,206
    a6e8:	00f72a23          	sw	a5,20(a4)
    a6ec:	ffb21737          	lui	a4,0xffb21

0000a6f0 <.L808>:
    a6f0:	04072783          	lw	a5,64(a4) # ffb21040 <__stack_top+0x1f040>
    a6f4:	fe079ee3          	bnez	a5,a6f0 <.L808>
    a6f8:	000027b7          	lui	a5,0x2
    a6fc:	09278793          	addi	a5,a5,146 # 2092 <_start-0x293e>
    a700:	00f72e23          	sw	a5,28(a4)
    a704:	00072823          	sw	zero,16(a4)
    a708:	0ce00793          	li	a5,206
    a70c:	00f72a23          	sw	a5,20(a4)
    a710:	ffb01737          	lui	a4,0xffb01
    a714:	8fc72703          	lw	a4,-1796(a4) # ffb008fc <.LC0+0x4>
    a718:	ffb01d37          	lui	s10,0xffb01
    a71c:	00e12c23          	sw	a4,24(sp)
    a720:	ffb01637          	lui	a2,0xffb01
    a724:	0000b6b7          	lui	a3,0xb
    a728:	40000737          	lui	a4,0x40000
    a72c:	0001a5b7          	lui	a1,0x1a
    a730:	8bc60613          	addi	a2,a2,-1860 # ffb008bc <.L855>
    a734:	95c68693          	addi	a3,a3,-1700 # a95c <.L809>
    a738:	10070713          	addi	a4,a4,256 # 40000100 <__kernel_data_lma+0x3fff484c>
    a73c:	02c12403          	lw	s0,44(sp)
    a740:	930d2783          	lw	a5,-1744(s10) # ffb00930 <_ZL11stall_state>
    a744:	44058d93          	addi	s11,a1,1088 # 1a440 <__kernel_data_lma+0xeb8c>
    a748:	00c12623          	sw	a2,12(sp)
    a74c:	00d12823          	sw	a3,16(sp)
    a750:	00e12a23          	sw	a4,20(sp)

0000a754 <.L915>:
    a754:	00100713          	li	a4,1
    a758:	20e78263          	beq	a5,a4,a95c <.L809>

0000a75c <.L912>:
    a75c:	44000c37          	lui	s8,0x44000
    a760:	100003b7          	lui	t2,0x10000
    a764:	010004b7          	lui	s1,0x1000
    a768:	fff80a37          	lui	s4,0xfff80
    a76c:	ffffccb7          	lui	s9,0xffffc
    a770:	100c0c13          	addi	s8,s8,256 # 44000100 <__kernel_data_lma+0x43ff484c>
    a774:	00f38393          	addi	t2,t2,15 # 1000000f <__kernel_data_lma+0xfff475b>
    a778:	fff48493          	addi	s1,s1,-1 # ffffff <__kernel_data_lma+0xff474b>
    a77c:	ff0a0a13          	addi	s4,s4,-16 # fff7fff0 <__instrn_buffer+0x13fff0>
    a780:	ffb01737          	lui	a4,0xffb01
    a784:	ffb01b37          	lui	s6,0xffb01

0000a788 <.L828>:
    a788:	90872f03          	lw	t5,-1784(a4) # ffb00908 <_ZZ16fetch_q_get_cmdsILm0EEvRmS0_S0_E17prefetch_q_rd_ptr>
    a78c:	000f5603          	lhu	a2,0(t5) # ffffc000 <__instrn_buffer+0x1bc000>
    a790:	168df6e3          	bgeu	s11,s0,b0fc <.L810>
    a794:	00f65e13          	srli	t3,a2,0xf
    a798:	001e1e13          	slli	t3,t3,0x1
    a79c:	00461613          	slli	a2,a2,0x4
    a7a0:	03b12623          	sw	s11,44(sp)
    a7a4:	93cd2823          	sw	t3,-1744(s10)
    a7a8:	01467633          	and	a2,a2,s4
    a7ac:	18060063          	beqz	a2,a92c <.L811>
    a7b0:	ffb01eb7          	lui	t4,0xffb01
    a7b4:	91cea783          	lw	a5,-1764(t4) # ffb0091c <_ZZ16fetch_q_get_cmdsILm0EEvRmS0_S0_E17pending_read_size>
    a7b8:	180792e3          	bnez	a5,b13c <.L917>
    a7bc:	0005a7b7          	lui	a5,0x5a
    a7c0:	44078793          	addi	a5,a5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    a7c4:	00cd86b3          	add	a3,s11,a2
    a7c8:	000d8413          	mv	s0,s11
    a7cc:	000d8993          	mv	s3,s11
    a7d0:	00d7f663          	bgeu	a5,a3,a7dc <.L813>

0000a7d4 <.L921>:
    a7d4:	0001a9b7          	lui	s3,0x1a
    a7d8:	44098993          	addi	s3,s3,1088 # 1a440 <__kernel_data_lma+0xeb8c>

0000a7dc <.L813>:
    a7dc:	90cb2a83          	lw	s5,-1780(s6) # ffb0090c <_ZL13pcie_read_ptr>
    a7e0:	00ca87b3          	add	a5,s5,a2
    a7e4:	34fc6ce3          	bltu	s8,a5,b33c <.L815>
    a7e8:	100067b7          	lui	a5,0x10006
    a7ec:	000048b7          	lui	a7,0x4
    a7f0:	000a8813          	mv	a6,s5
    a7f4:	13078b93          	addi	s7,a5,304 # 10006130 <__kernel_data_lma+0xfffa87c>
    a7f8:	34c8fee3          	bgeu	a7,a2,b354 <.L922>

0000a7fc <.L1009>:
    a7fc:	ffffc7b7          	lui	a5,0xffffc
    a800:	fff78793          	addi	a5,a5,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    a804:	00f602b3          	add	t0,a2,a5
    a808:	0192ffb3          	and	t6,t0,s9
    a80c:	011f8fb3          	add	t6,t6,a7
    a810:	ffb00337          	lui	t1,0xffb00
    a814:	013f8fb3          	add	t6,t6,s3
    a818:	03c30313          	addi	t1,t1,60 # ffb0003c <noc_reads_num_issued>
    a81c:	000a8693          	mv	a3,s5
    a820:	000b8513          	mv	a0,s7
    a824:	00098593          	mv	a1,s3
    a828:	ffb217b7          	lui	a5,0xffb21
    a82c:	00100913          	li	s2,1

0000a830 <.L818>:
    a830:	8407a803          	lw	a6,-1984(a5) # ffb20840 <__stack_top+0x1e840>
    a834:	fe081ee3          	bnez	a6,a830 <.L818>
    a838:	80b7a623          	sw	a1,-2036(a5)
    a83c:	80d7a023          	sw	a3,-2048(a5)
    a840:	00757833          	and	a6,a0,t2
    a844:	8107a223          	sw	a6,-2044(a5)
    a848:	00455813          	srli	a6,a0,0x4
    a84c:	00987833          	and	a6,a6,s1
    a850:	8107a423          	sw	a6,-2040(a5)
    a854:	8317a023          	sw	a7,-2016(a5)
    a858:	8527a023          	sw	s2,-1984(a5)
    a85c:	00032803          	lw	a6,0(t1)
    a860:	011585b3          	add	a1,a1,a7
    a864:	00180813          	addi	a6,a6,1
    a868:	01032023          	sw	a6,0(t1)
    a86c:	01168833          	add	a6,a3,a7
    a870:	00d836b3          	sltu	a3,a6,a3
    a874:	00a68533          	add	a0,a3,a0
    a878:	00080693          	mv	a3,a6
    a87c:	fbf59ae3          	bne	a1,t6,a830 <.L818>
    a880:	00e2d693          	srli	a3,t0,0xe
    a884:	00e69593          	slli	a1,a3,0xe
    a888:	411607b3          	sub	a5,a2,a7
    a88c:	00168693          	addi	a3,a3,1
    a890:	40b787b3          	sub	a5,a5,a1
    a894:	00e69593          	slli	a1,a3,0xe
    a898:	01558833          	add	a6,a1,s5
    a89c:	0126d693          	srli	a3,a3,0x12
    a8a0:	00b83533          	sltu	a0,a6,a1
    a8a4:	017686b3          	add	a3,a3,s7
    a8a8:	00d50533          	add	a0,a0,a3
    a8ac:	00757533          	and	a0,a0,t2

0000a8b0 <.L817>:
    a8b0:	ffb215b7          	lui	a1,0xffb21

0000a8b4 <.L820>:
    a8b4:	8405a683          	lw	a3,-1984(a1) # ffb20840 <__stack_top+0x1e840>
    a8b8:	fe069ee3          	bnez	a3,a8b4 <.L820>
    a8bc:	81f5a623          	sw	t6,-2036(a1)
    a8c0:	8105a023          	sw	a6,-2048(a1)
    a8c4:	80a5a223          	sw	a0,-2044(a1)
    a8c8:	61300693          	li	a3,1555
    a8cc:	80d5a423          	sw	a3,-2040(a1)
    a8d0:	82f5a023          	sw	a5,-2016(a1)
    a8d4:	00100793          	li	a5,1
    a8d8:	84f5a023          	sw	a5,-1984(a1)
    a8dc:	00032683          	lw	a3,0(t1)
    a8e0:	90cb2783          	lw	a5,-1780(s6)
    a8e4:	00168693          	addi	a3,a3,1
    a8e8:	00c787b3          	add	a5,a5,a2
    a8ec:	90fb2623          	sw	a5,-1780(s6)
    a8f0:	00d32023          	sw	a3,0(t1)
    a8f4:	000f1023          	sh	zero,0(t5)
    a8f8:	000197b7          	lui	a5,0x19
    a8fc:	6de7a023          	sw	t5,1728(a5) # 196c0 <__kernel_data_lma+0xde0c>
    a900:	90cb2683          	lw	a3,-1780(s6)
    a904:	002f0f13          	addi	t5,t5,2
    a908:	6cd7a223          	sw	a3,1732(a5)
    a90c:	0001a7b7          	lui	a5,0x1a
    a910:	91e72423          	sw	t5,-1784(a4)
    a914:	43c78793          	addi	a5,a5,1084 # 1a43c <__kernel_data_lma+0xeb88>
    a918:	06ff0063          	beq	t5,a5,a978 <.L821>
    a91c:	90ceae23          	sw	a2,-1764(t4)
    a920:	060e1663          	bnez	t3,a98c <.L824>

0000a924 <.L814>:
    a924:	79b412e3          	bne	s0,s11,b8a8 <.L916>
    a928:	00098d93          	mv	s11,s3

0000a92c <.L811>:
    a92c:	ffb01eb7          	lui	t4,0xffb01
    a930:	91cea783          	lw	a5,-1764(t4) # ffb0091c <_ZZ16fetch_q_get_cmdsILm0EEvRmS0_S0_E17pending_read_size>
    a934:	00078663          	beqz	a5,a940 <.L996>
    a938:	0110006f          	j	b148 <.L826>

0000a93c <.L827>:
    a93c:	0ff0000f          	fence

0000a940 <.L996>:
    a940:	90872783          	lw	a5,-1784(a4)
    a944:	0007d783          	lhu	a5,0(a5)
    a948:	fe078ae3          	beqz	a5,a93c <.L827>
    a94c:	930d2683          	lw	a3,-1744(s10)
    a950:	00100793          	li	a5,1
    a954:	02c12403          	lw	s0,44(sp)
    a958:	e2f698e3          	bne	a3,a5,a788 <.L828>

0000a95c <.L809>:
    a95c:	00044783          	lbu	a5,0(s0)
    a960:	00c12703          	lw	a4,12(sp)
    a964:	20e7c7b3          	sh2add	a5,a5,a4
    a968:	01012703          	lw	a4,16(sp)
    a96c:	0007a783          	lw	a5,0(a5)
    a970:	00f707b3          	add	a5,a4,a5
    a974:	00078067          	jr	a5

0000a978 <.L821>:
    a978:	0001a7b7          	lui	a5,0x1a
    a97c:	84078793          	addi	a5,a5,-1984 # 19840 <__kernel_data_lma+0xdf8c>
    a980:	90ceae23          	sw	a2,-1764(t4)
    a984:	90f72423          	sw	a5,-1784(a4)
    a988:	f80e0ee3          	beqz	t3,a924 <.L814>

0000a98c <.L824>:
    a98c:	00032703          	lw	a4,0(t1)
    a990:	ffb207b7          	lui	a5,0xffb20

0000a994 <.L823>:
    a994:	2087a683          	lw	a3,520(a5) # ffb20208 <__stack_top+0x1e208>
    a998:	fee69ee3          	bne	a3,a4,a994 <.L823>
    a99c:	0ff0000f          	fence
    a9a0:	02c12403          	lw	s0,44(sp)
    a9a4:	0089f663          	bgeu	s3,s0,a9b0 <.L825>
    a9a8:	03312623          	sw	s3,44(sp)
    a9ac:	00098413          	mv	s0,s3

0000a9b0 <.L825>:
    a9b0:	91cead83          	lw	s11,-1764(t4)
    a9b4:	00100793          	li	a5,1
    a9b8:	01b98db3          	add	s11,s3,s11
    a9bc:	900eae23          	sw	zero,-1764(t4)
    a9c0:	92fd2823          	sw	a5,-1744(s10)
    a9c4:	f99ff06f          	j	a95c <.L809>

0000a9c8 <.L861>:
    a9c8:	02c10513          	addi	a0,sp,44
    a9cc:	9c9fe0ef          	jal	9394 <_Z27process_relay_inline_commonILb0ELb0ELb1E24DispatchRelayInlineStateEmRmS1_R20PrefetchExecBufState.constprop.0>

0000a9d0 <.L806>:
    a9d0:	24c12083          	lw	ra,588(sp)
    a9d4:	24812403          	lw	s0,584(sp)
    a9d8:	24412483          	lw	s1,580(sp)
    a9dc:	24012903          	lw	s2,576(sp)
    a9e0:	23c12983          	lw	s3,572(sp)
    a9e4:	23812a03          	lw	s4,568(sp)
    a9e8:	23412a83          	lw	s5,564(sp)
    a9ec:	23012b03          	lw	s6,560(sp)
    a9f0:	22c12b83          	lw	s7,556(sp)
    a9f4:	22812c03          	lw	s8,552(sp)
    a9f8:	22412c83          	lw	s9,548(sp)
    a9fc:	22012d03          	lw	s10,544(sp)
    aa00:	21c12d83          	lw	s11,540(sp)
    aa04:	25010113          	addi	sp,sp,592
    aa08:	00008067          	ret

0000aa0c <.L860>:
    aa0c:	ffb017b7          	lui	a5,0xffb01
    aa10:	86c7a683          	lw	a3,-1940(a5) # ffb0086c <sem_l1_base>
    aa14:	ffb01637          	lui	a2,0xffb01
    aa18:	92062783          	lw	a5,-1760(a2) # ffb00920 <_ZZ13process_stallmE5count>
    aa1c:	00178793          	addi	a5,a5,1
    aa20:	92f62023          	sw	a5,-1760(a2)
    aa24:	02068693          	addi	a3,a3,32

0000aa28 <.L913>:
    aa28:	0ff0000f          	fence
    aa2c:	0006a703          	lw	a4,0(a3)
    aa30:	92062783          	lw	a5,-1760(a2)
    aa34:	fef71ae3          	bne	a4,a5,aa28 <.L913>

0000aa38 <.L998>:
    aa38:	930d2783          	lw	a5,-1744(s10)
    aa3c:	04000493          	li	s1,64

0000aa40 <.L868>:
    aa40:	00940433          	add	s0,s0,s1
    aa44:	02812623          	sw	s0,44(sp)
    aa48:	d0dff06f          	j	a754 <.L915>

0000aa4c <.L857>:
    aa4c:	00144583          	lbu	a1,1(s0)
    aa50:	00244683          	lbu	a3,2(s0)
    aa54:	00344703          	lbu	a4,3(s0)
    aa58:	00444783          	lbu	a5,4(s0)
    aa5c:	00844603          	lbu	a2,8(s0)
    aa60:	01879793          	slli	a5,a5,0x18
    aa64:	00869693          	slli	a3,a3,0x8
    aa68:	00b6e6b3          	or	a3,a3,a1
    aa6c:	01071713          	slli	a4,a4,0x10
    aa70:	00d76733          	or	a4,a4,a3
    aa74:	00e7e7b3          	or	a5,a5,a4
    aa78:	240602e3          	beqz	a2,b4bc <.L914>
    aa7c:	0005a737          	lui	a4,0x5a
    aa80:	44070713          	addi	a4,a4,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    aa84:	00e787b3          	add	a5,a5,a4
    aa88:	ffb01737          	lui	a4,0xffb01
    aa8c:	90f72823          	sw	a5,-1776(a4) # ffb00910 <_ZL13ringbuffer_wp>
    aa90:	04000493          	li	s1,64
    aa94:	930d2783          	lw	a5,-1744(s10)
    aa98:	fa9ff06f          	j	aa40 <.L868>

0000aa9c <.L858>:
    aa9c:	00040513          	mv	a0,s0
    aaa0:	d14fa0ef          	jal	4fb4 <_Z31process_paged_to_ringbuffer_cmdmRm.constprop.0.isra.0>
    aaa4:	f95ff06f          	j	aa38 <.L998>

0000aaa8 <.L862>:
    aaa8:	00040513          	mv	a0,s0
    aaac:	03010613          	addi	a2,sp,48
    aab0:	04c10593          	addi	a1,sp,76
    aab4:	04040413          	addi	s0,s0,64
    aab8:	f35fe0ef          	jal	99ec <_Z20process_exec_buf_cmdmRmPmR20PrefetchExecBufState.constprop.0>
    aabc:	02812623          	sw	s0,44(sp)
    aac0:	c9dff06f          	j	a75c <.L912>

0000aac4 <.L863>:
    aac4:	ffb017b7          	lui	a5,0xffb01
    aac8:	86c7a503          	lw	a0,-1940(a5) # ffb0086c <sem_l1_base>
    aacc:	00444783          	lbu	a5,4(s0)
    aad0:	00544603          	lbu	a2,5(s0)
    aad4:	00644703          	lbu	a4,6(s0)
    aad8:	00861613          	slli	a2,a2,0x8
    aadc:	00744e83          	lbu	t4,7(s0)
    aae0:	00844583          	lbu	a1,8(s0)
    aae4:	00944683          	lbu	a3,9(s0)
    aae8:	00f66633          	or	a2,a2,a5
    aaec:	00a44783          	lbu	a5,10(s0)
    aaf0:	00869693          	slli	a3,a3,0x8
    aaf4:	00b44483          	lbu	s1,11(s0)
    aaf8:	01071713          	slli	a4,a4,0x10
    aafc:	00c76733          	or	a4,a4,a2
    ab00:	00b6e6b3          	or	a3,a3,a1
    ab04:	01079793          	slli	a5,a5,0x10
    ab08:	ffb00637          	lui	a2,0xffb00
    ab0c:	00d7e7b3          	or	a5,a5,a3
    ab10:	018e9e93          	slli	t4,t4,0x18
    ab14:	01849493          	slli	s1,s1,0x18
    ab18:	02462683          	lw	a3,36(a2) # ffb00024 <noc_nonposted_atomics_acked>
    ab1c:	00eeeeb3          	or	t4,t4,a4
    ab20:	00f4e4b3          	or	s1,s1,a5
    ab24:	ffb20737          	lui	a4,0xffb20

0000ab28 <.L892>:
    ab28:	20072783          	lw	a5,512(a4) # ffb20200 <__stack_top+0x1e200>
    ab2c:	fed79ee3          	bne	a5,a3,ab28 <.L892>
    ab30:	0ff0000f          	fence
    ab34:	ffb01637          	lui	a2,0xffb01
    ab38:	00100593          	li	a1,1

0000ab3c <.L893>:
    ab3c:	0ff0000f          	fence
    ab40:	92462703          	lw	a4,-1756(a2) # ffb00924 <_ZN24DispatchRelayInlineState9cb_writerE>
    ab44:	00052683          	lw	a3,0(a0)
    ab48:	40e587b3          	sub	a5,a1,a4
    ab4c:	40d787b3          	sub	a5,a5,a3
    ab50:	fef046e3          	bgtz	a5,ab3c <.L893>
    ab54:	ffb013b7          	lui	t2,0xffb01
    ab58:	fff70713          	addi	a4,a4,-1
    ab5c:	9183a683          	lw	a3,-1768(t2) # ffb00918 <_ZL19downstream_data_ptr>
    ab60:	92e62223          	sw	a4,-1756(a2)
    ab64:	0009a7b7          	lui	a5,0x9a
    ab68:	16f684e3          	beq	a3,a5,b4d0 <.L999>

0000ab6c <.L894>:
    ab6c:	180e8263          	beqz	t4,acf0 <.L895>
    ab70:	02c12f83          	lw	t6,44(sp)
    ab74:	0005af37          	lui	t5,0x5a
    ab78:	010f8f93          	addi	t6,t6,16
    ab7c:	440f0f13          	addi	t5,t5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    ab80:	ffb00737          	lui	a4,0xffb00
    ab84:	ffb006b7          	lui	a3,0xffb00
    ab88:	9183a583          	lw	a1,-1768(t2)
    ab8c:	ffff8cb7          	lui	s9,0xffff8
    ab90:	41ff0f33          	sub	t5,t5,t6
    ab94:	03470713          	addi	a4,a4,52 # ffb00034 <noc_nonposted_writes_num_issued>
    ab98:	02c68693          	addi	a3,a3,44 # ffb0002c <noc_nonposted_writes_acked>
    ab9c:	0009ab37          	lui	s6,0x9a
    aba0:	00004837          	lui	a6,0x4
    aba4:	ffb207b7          	lui	a5,0xffb20
    aba8:	00100e13          	li	t3,1

0000abac <.L911>:
    abac:	40bb0933          	sub	s2,s6,a1
    abb0:	0bdf5333          	minu	t1,t5,t4
    abb4:	000f8a13          	mv	s4,t6
    abb8:	406f0f33          	sub	t5,t5,t1
    abbc:	006f8fb3          	add	t6,t6,t1
    abc0:	00058893          	mv	a7,a1
    abc4:	00058513          	mv	a0,a1
    abc8:	00030293          	mv	t0,t1
    abcc:	00697a63          	bgeu	s2,t1,abe0 <.L897>
    abd0:	7b659263          	bne	a1,s6,b374 <.L1000>

0000abd4 <.L898>:
    abd4:	0001a537          	lui	a0,0x1a
    abd8:	90a3ac23          	sw	a0,-1768(t2)
    abdc:	00050893          	mv	a7,a0

0000abe0 <.L897>:
    abe0:	00028913          	mv	s2,t0
    abe4:	0c587463          	bgeu	a6,t0,acac <.L910>

0000abe8 <.L906>:
    abe8:	0407a603          	lw	a2,64(a5) # ffb20040 <__stack_top+0x1e040>
    abec:	fe061ee3          	bnez	a2,abe8 <.L906>
    abf0:	0147a023          	sw	s4,0(a5)
    abf4:	0307a023          	sw	a6,32(a5)
    abf8:	00a7a623          	sw	a0,12(a5)
    abfc:	00072583          	lw	a1,0(a4)
    ac00:	0006a603          	lw	a2,0(a3)
    ac04:	00158593          	addi	a1,a1,1
    ac08:	00160613          	addi	a2,a2,1
    ac0c:	00b72023          	sw	a1,0(a4)
    ac10:	00c6a023          	sw	a2,0(a3)
    ac14:	05c7a023          	sw	t3,64(a5)
    ac18:	41028933          	sub	s2,t0,a6
    ac1c:	010a05b3          	add	a1,s4,a6
    ac20:	01088633          	add	a2,a7,a6
    ac24:	3d287ae3          	bgeu	a6,s2,b7f8 <.L1001>
    ac28:	ffff8537          	lui	a0,0xffff8
    ac2c:	fff50513          	addi	a0,a0,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    ac30:	00a289b3          	add	s3,t0,a0
    ac34:	00008937          	lui	s2,0x8
    ac38:	ffffc537          	lui	a0,0xffffc
    ac3c:	00a9fab3          	and	s5,s3,a0
    ac40:	012a0933          	add	s2,s4,s2
    ac44:	41450533          	sub	a0,a0,s4
    ac48:	01590933          	add	s2,s2,s5
    ac4c:	00c50533          	add	a0,a0,a2

0000ac50 <.L908>:
    ac50:	0407a603          	lw	a2,64(a5)
    ac54:	fe061ee3          	bnez	a2,ac50 <.L908>
    ac58:	00b7a023          	sw	a1,0(a5)
    ac5c:	00b50633          	add	a2,a0,a1
    ac60:	00c7a623          	sw	a2,12(a5)
    ac64:	00072603          	lw	a2,0(a4)
    ac68:	010585b3          	add	a1,a1,a6
    ac6c:	00160613          	addi	a2,a2,1
    ac70:	00c72023          	sw	a2,0(a4)
    ac74:	0006a603          	lw	a2,0(a3)
    ac78:	00160613          	addi	a2,a2,1
    ac7c:	00c6a023          	sw	a2,0(a3)
    ac80:	05c7a023          	sw	t3,64(a5)
    ac84:	fd2596e3          	bne	a1,s2,ac50 <.L908>
    ac88:	00e9d993          	srli	s3,s3,0xe
    ac8c:	00e99513          	slli	a0,s3,0xe
    ac90:	00008637          	lui	a2,0x8
    ac94:	00050993          	mv	s3,a0
    ac98:	00c888b3          	add	a7,a7,a2
    ac9c:	01928933          	add	s2,t0,s9
    aca0:	00058a13          	mv	s4,a1
    aca4:	01150533          	add	a0,a0,a7
    aca8:	41390933          	sub	s2,s2,s3

0000acac <.L910>:
    acac:	0407a603          	lw	a2,64(a5)
    acb0:	fe061ee3          	bnez	a2,acac <.L910>

0000acb4 <.L1014>:
    acb4:	0147a023          	sw	s4,0(a5)
    acb8:	0327a023          	sw	s2,32(a5)
    acbc:	00a7a623          	sw	a0,12(a5)
    acc0:	00072583          	lw	a1,0(a4)
    acc4:	0006a603          	lw	a2,0(a3)
    acc8:	00158593          	addi	a1,a1,1
    accc:	00160613          	addi	a2,a2,1 # 8001 <.L417+0x25>
    acd0:	00b72023          	sw	a1,0(a4)
    acd4:	00c6a023          	sw	a2,0(a3)
    acd8:	05c7a023          	sw	t3,64(a5)
    acdc:	9183a583          	lw	a1,-1768(t2)
    ace0:	406e8eb3          	sub	t4,t4,t1
    ace4:	00b285b3          	add	a1,t0,a1
    ace8:	90b3ac23          	sw	a1,-1768(t2)
    acec:	ec0e90e3          	bnez	t4,abac <.L911>

0000acf0 <.L895>:
    acf0:	930d2783          	lw	a5,-1744(s10)
    acf4:	d4dff06f          	j	aa40 <.L868>

0000acf8 <.L864>:
    acf8:	00144783          	lbu	a5,1(s0)
    acfc:	7a078663          	beqz	a5,b4a8 <.L1002>
    ad00:	ffb017b7          	lui	a5,0xffb01
    ad04:	86c78c13          	addi	s8,a5,-1940 # ffb0086c <sem_l1_base>
    ad08:	000c2603          	lw	a2,0(s8)
    ad0c:	00444703          	lbu	a4,4(s0)
    ad10:	00544783          	lbu	a5,5(s0)
    ad14:	00644683          	lbu	a3,6(s0)
    ad18:	00879793          	slli	a5,a5,0x8
    ad1c:	00744e03          	lbu	t3,7(s0)
    ad20:	00e7e7b3          	or	a5,a5,a4
    ad24:	00844583          	lbu	a1,8(s0)
    ad28:	01069693          	slli	a3,a3,0x10
    ad2c:	00944703          	lbu	a4,9(s0)
    ad30:	00f6e6b3          	or	a3,a3,a5
    ad34:	00a44783          	lbu	a5,10(s0)
    ad38:	018e1e13          	slli	t3,t3,0x18
    ad3c:	00b44483          	lbu	s1,11(s0)
    ad40:	00871713          	slli	a4,a4,0x8
    ad44:	ffb00ab7          	lui	s5,0xffb00
    ad48:	00b76733          	or	a4,a4,a1
    ad4c:	00de6e33          	or	t3,t3,a3
    ad50:	01079793          	slli	a5,a5,0x10
    ad54:	024a8a93          	addi	s5,s5,36 # ffb00024 <noc_nonposted_atomics_acked>
    ad58:	00e7e7b3          	or	a5,a5,a4
    ad5c:	0ffe0513          	addi	a0,t3,255 # 80ff <.L416+0x6b>
    ad60:	01849493          	slli	s1,s1,0x18
    ad64:	000aa583          	lw	a1,0(s5)
    ad68:	00f4e4b3          	or	s1,s1,a5
    ad6c:	00855513          	srli	a0,a0,0x8
    ad70:	01060693          	addi	a3,a2,16
    ad74:	ffb20737          	lui	a4,0xffb20

0000ad78 <.L871>:
    ad78:	20072783          	lw	a5,512(a4) # ffb20200 <__stack_top+0x1e200>
    ad7c:	feb79ee3          	bne	a5,a1,ad78 <.L871>
    ad80:	0ff0000f          	fence
    ad84:	ffb01637          	lui	a2,0xffb01

0000ad88 <.L872>:
    ad88:	0ff0000f          	fence
    ad8c:	0006a783          	lw	a5,0(a3)
    ad90:	92862703          	lw	a4,-1752(a2) # ffb00928 <_ZN25DispatchSRelayInlineState9cb_writerE>
    ad94:	00f707b3          	add	a5,a4,a5
    ad98:	40f507b3          	sub	a5,a0,a5
    ad9c:	fef046e3          	bgtz	a5,ad88 <.L872>
    ada0:	40a70733          	sub	a4,a4,a0
    ada4:	92e62423          	sw	a4,-1752(a2)
    ada8:	ffb013b7          	lui	t2,0xffb01
    adac:	ffb00737          	lui	a4,0xffb00
    adb0:	9143a603          	lw	a2,-1772(t2) # ffb00914 <_ZL21downstream_data_ptr_s>
    adb4:	03470713          	addi	a4,a4,52 # ffb00034 <noc_nonposted_writes_num_issued>
    adb8:	160e0e63          	beqz	t3,af34 <.L873>
    adbc:	02c12283          	lw	t0,44(sp)
    adc0:	0005afb7          	lui	t6,0x5a
    adc4:	01028293          	addi	t0,t0,16
    adc8:	440f8f93          	addi	t6,t6,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    adcc:	ffb00737          	lui	a4,0xffb00
    add0:	ffb006b7          	lui	a3,0xffb00
    add4:	405f8fb3          	sub	t6,t6,t0
    add8:	03470713          	addi	a4,a4,52 # ffb00034 <noc_nonposted_writes_num_issued>
    addc:	02c68693          	addi	a3,a3,44 # ffb0002c <noc_nonposted_writes_acked>
    ade0:	00004837          	lui	a6,0x4
    ade4:	ffb217b7          	lui	a5,0xffb21
    ade8:	00100e93          	li	t4,1

0000adec <.L889>:
    adec:	000a25b7          	lui	a1,0xa2
    adf0:	0bfe5f33          	minu	t5,t3,t6
    adf4:	40c58b33          	sub	s6,a1,a2
    adf8:	41ef8fb3          	sub	t6,t6,t5
    adfc:	00028593          	mv	a1,t0
    ae00:	00060913          	mv	s2,a2
    ae04:	01e282b3          	add	t0,t0,t5
    ae08:	000f0313          	mv	t1,t5
    ae0c:	01eb7c63          	bgeu	s6,t5,ae24 <.L875>
    ae10:	000a28b7          	lui	a7,0xa2
    ae14:	6f161c63          	bne	a2,a7,b50c <.L1003>

0000ae18 <.L876>:
    ae18:	0009a937          	lui	s2,0x9a
    ae1c:	00090613          	mv	a2,s2
    ae20:	9123aa23          	sw	s2,-1772(t2)

0000ae24 <.L875>:
    ae24:	00030993          	mv	s3,t1
    ae28:	0c687463          	bgeu	a6,t1,aef0 <.L888>

0000ae2c <.L884>:
    ae2c:	0407a883          	lw	a7,64(a5) # ffb21040 <__stack_top+0x1f040>
    ae30:	fe089ee3          	bnez	a7,ae2c <.L884>
    ae34:	00b7a023          	sw	a1,0(a5)
    ae38:	0307a023          	sw	a6,32(a5)
    ae3c:	0127a623          	sw	s2,12(a5)
    ae40:	00072903          	lw	s2,0(a4)
    ae44:	0006a883          	lw	a7,0(a3)
    ae48:	00190913          	addi	s2,s2,1 # 9a001 <__kernel_data_lma+0x8e74d>
    ae4c:	00188893          	addi	a7,a7,1 # a2001 <__kernel_data_lma+0x9674d>
    ae50:	0116a023          	sw	a7,0(a3)
    ae54:	01272023          	sw	s2,0(a4)
    ae58:	05d7a023          	sw	t4,64(a5)
    ae5c:	410309b3          	sub	s3,t1,a6
    ae60:	010588b3          	add	a7,a1,a6
    ae64:	01060b33          	add	s6,a2,a6
    ae68:	1f3874e3          	bgeu	a6,s3,b850 <.L1004>
    ae6c:	ffff8937          	lui	s2,0xffff8
    ae70:	fff90913          	addi	s2,s2,-1 # ffff7fff <__instrn_buffer+0x1b7fff>
    ae74:	ffffcbb7          	lui	s7,0xffffc
    ae78:	012309b3          	add	s3,t1,s2
    ae7c:	00008a37          	lui	s4,0x8
    ae80:	01458a33          	add	s4,a1,s4
    ae84:	0179f933          	and	s2,s3,s7
    ae88:	40bb85b3          	sub	a1,s7,a1
    ae8c:	01490933          	add	s2,s2,s4
    ae90:	01658a33          	add	s4,a1,s6

0000ae94 <.L886>:
    ae94:	0407a583          	lw	a1,64(a5)
    ae98:	fe059ee3          	bnez	a1,ae94 <.L886>
    ae9c:	0117a023          	sw	a7,0(a5)
    aea0:	011a05b3          	add	a1,s4,a7
    aea4:	00b7a623          	sw	a1,12(a5)
    aea8:	00072583          	lw	a1,0(a4)
    aeac:	010888b3          	add	a7,a7,a6
    aeb0:	00158593          	addi	a1,a1,1 # a2001 <__kernel_data_lma+0x9674d>
    aeb4:	00b72023          	sw	a1,0(a4)
    aeb8:	0006a583          	lw	a1,0(a3)
    aebc:	00158593          	addi	a1,a1,1
    aec0:	00b6a023          	sw	a1,0(a3)
    aec4:	05d7a023          	sw	t4,64(a5)
    aec8:	fd1916e3          	bne	s2,a7,ae94 <.L886>
    aecc:	00e9d993          	srli	s3,s3,0xe
    aed0:	000085b7          	lui	a1,0x8
    aed4:	00b60633          	add	a2,a2,a1
    aed8:	00e99893          	slli	a7,s3,0xe
    aedc:	00090593          	mv	a1,s2
    aee0:	00c88933          	add	s2,a7,a2
    aee4:	ffff8637          	lui	a2,0xffff8
    aee8:	00c309b3          	add	s3,t1,a2
    aeec:	411989b3          	sub	s3,s3,a7

0000aef0 <.L888>:
    aef0:	0407a603          	lw	a2,64(a5)
    aef4:	fe061ee3          	bnez	a2,aef0 <.L888>

0000aef8 <.L1015>:
    aef8:	00b7a023          	sw	a1,0(a5)
    aefc:	0337a023          	sw	s3,32(a5)
    af00:	0127a623          	sw	s2,12(a5)
    af04:	00072583          	lw	a1,0(a4)
    af08:	0006a603          	lw	a2,0(a3)
    af0c:	00158593          	addi	a1,a1,1 # 8001 <.L417+0x25>
    af10:	00160613          	addi	a2,a2,1 # ffff8001 <__instrn_buffer+0x1b8001>
    af14:	00c6a023          	sw	a2,0(a3)
    af18:	00b72023          	sw	a1,0(a4)
    af1c:	05d7a023          	sw	t4,64(a5)
    af20:	9143a603          	lw	a2,-1772(t2)
    af24:	41ee0e33          	sub	t3,t3,t5
    af28:	00c30633          	add	a2,t1,a2
    af2c:	90c3aa23          	sw	a2,-1772(t2)
    af30:	ea0e1ee3          	bnez	t3,adec <.L889>

0000af34 <.L873>:
    af34:	0ff60793          	addi	a5,a2,255
    af38:	f007f793          	andi	a5,a5,-256
    af3c:	00072683          	lw	a3,0(a4)
    af40:	90f3aa23          	sw	a5,-1772(t2)
    af44:	ffb20737          	lui	a4,0xffb20

0000af48 <.L890>:
    af48:	22872783          	lw	a5,552(a4) # ffb20228 <__stack_top+0x1e228>
    af4c:	fed79ee3          	bne	a5,a3,af48 <.L890>
    af50:	0ff0000f          	fence
    af54:	000c2703          	lw	a4,0(s8)
    af58:	ffb227b7          	lui	a5,0xffb22

0000af5c <.L891>:
    af5c:	8407a683          	lw	a3,-1984(a5) # ffb21840 <__stack_top+0x1f840>
    af60:	fe069ee3          	bnez	a3,af5c <.L891>
    af64:	80e7a023          	sw	a4,-2048(a5)
    af68:	8007a223          	sw	zero,-2044(a5)
    af6c:	0ce00693          	li	a3,206
    af70:	80d7a423          	sw	a3,-2040(a5)
    af74:	00275713          	srli	a4,a4,0x2
    af78:	00001637          	lui	a2,0x1
    af7c:	000026b7          	lui	a3,0x2
    af80:	00377713          	andi	a4,a4,3
    af84:	07c60613          	addi	a2,a2,124 # 107c <_start-0x3954>
    af88:	09168693          	addi	a3,a3,145 # 2091 <_start-0x293f>
    af8c:	80d7ae23          	sw	a3,-2020(a5)
    af90:	00c76733          	or	a4,a4,a2
    af94:	82e7a023          	sw	a4,-2016(a5)
    af98:	82a7a423          	sw	a0,-2008(a5)
    af9c:	00100713          	li	a4,1
    afa0:	84e7a023          	sw	a4,-1984(a5)
    afa4:	000aa703          	lw	a4,0(s5)
    afa8:	930d2783          	lw	a5,-1744(s10)
    afac:	00170713          	addi	a4,a4,1
    afb0:	00eaa023          	sw	a4,0(s5)
    afb4:	a8dff06f          	j	aa40 <.L868>

0000afb8 <.L865>:
    afb8:	00444683          	lbu	a3,4(s0)
    afbc:	00544603          	lbu	a2,5(s0)
    afc0:	00644703          	lbu	a4,6(s0)
    afc4:	00744903          	lbu	s2,7(s0)
    afc8:	00244783          	lbu	a5,2(s0)
    afcc:	00344583          	lbu	a1,3(s0)
    afd0:	00861613          	slli	a2,a2,0x8
    afd4:	00844503          	lbu	a0,8(s0)
    afd8:	00d66633          	or	a2,a2,a3
    afdc:	00859593          	slli	a1,a1,0x8
    afe0:	00944683          	lbu	a3,9(s0)
    afe4:	00f5e5b3          	or	a1,a1,a5
    afe8:	00a44783          	lbu	a5,10(s0)
    afec:	20b5a5b3          	sh1add	a1,a1,a1
    aff0:	00b44483          	lbu	s1,11(s0)
    aff4:	00869693          	slli	a3,a3,0x8
    aff8:	00a6e6b3          	or	a3,a3,a0
    affc:	01071713          	slli	a4,a4,0x10
    b000:	01079793          	slli	a5,a5,0x10
    b004:	00c76733          	or	a4,a4,a2
    b008:	00d7e7b3          	or	a5,a5,a3
    b00c:	00259593          	slli	a1,a1,0x2
    b010:	04c10613          	addi	a2,sp,76
    b014:	01891913          	slli	s2,s2,0x18
    b018:	01849493          	slli	s1,s1,0x18
    b01c:	00040513          	mv	a0,s0
    b020:	00e96933          	or	s2,s2,a4
    b024:	00f4e4b3          	or	s1,s1,a5
    b028:	93dfe0ef          	jal	9964 <_Z25copy_sub_cmds_to_l1_cacheILb0ELb0E32CQPrefetchRelayPagedPackedSubCmdEPT1_RmmPmR20PrefetchExecBufStateS3_.isra.0>
    b02c:	00100713          	li	a4,1
    b030:	00050793          	mv	a5,a0
    b034:	000784a3          	sb	zero,9(a5)
    b038:	00078523          	sb	zero,10(a5)
    b03c:	000785a3          	sb	zero,11(a5)
    b040:	00e78423          	sb	a4,8(a5)
    b044:	04c10593          	addi	a1,sp,76
    b048:	00090513          	mv	a0,s2
    b04c:	facfb0ef          	jal	67f8 <_Z35process_relay_paged_packed_sub_cmdsmPm>
    b050:	930d2783          	lw	a5,-1744(s10)
    b054:	9edff06f          	j	aa40 <.L868>

0000b058 <.L866>:
    b058:	00244703          	lbu	a4,2(s0)
    b05c:	00344783          	lbu	a5,3(s0)
    b060:	00144583          	lbu	a1,1(s0)
    b064:	00879793          	slli	a5,a5,0x8
    b068:	00e7e7b3          	or	a5,a5,a4
    b06c:	00040513          	mv	a0,s0
    b070:	60579793          	sext.h	a5,a5
    b074:	0ff5f593          	zext.b	a1,a1
    b078:	4807c263          	bltz	a5,b4fc <.L1005>
    b07c:	b24fd0ef          	jal	83a0 <_Z23process_relay_paged_cmdILb0EEmmRmm.constprop.0.isra.0>
    b080:	04000493          	li	s1,64
    b084:	930d2783          	lw	a5,-1744(s10)
    b088:	9b9ff06f          	j	aa40 <.L868>

0000b08c <.L867>:
    b08c:	00040513          	mv	a0,s0
    b090:	f05fb0ef          	jal	6f94 <_Z24process_relay_linear_cmdmRm.constprop.0.isra.0>
    b094:	04000493          	li	s1,64
    b098:	930d2783          	lw	a5,-1744(s10)
    b09c:	9a5ff06f          	j	aa40 <.L868>

0000b0a0 <.L854>:
    b0a0:	00244603          	lbu	a2,2(s0)
    b0a4:	00344903          	lbu	s2,3(s0)
    b0a8:	00444683          	lbu	a3,4(s0)
    b0ac:	00544703          	lbu	a4,5(s0)
    b0b0:	00644783          	lbu	a5,6(s0)
    b0b4:	00891913          	slli	s2,s2,0x8
    b0b8:	00744483          	lbu	s1,7(s0)
    b0bc:	00871713          	slli	a4,a4,0x8
    b0c0:	00c96933          	or	s2,s2,a2
    b0c4:	00d76733          	or	a4,a4,a3
    b0c8:	01079793          	slli	a5,a5,0x10
    b0cc:	00e7e7b3          	or	a5,a5,a4
    b0d0:	00391593          	slli	a1,s2,0x3
    b0d4:	04c10613          	addi	a2,sp,76
    b0d8:	01849493          	slli	s1,s1,0x18
    b0dc:	00040513          	mv	a0,s0
    b0e0:	00f4e4b3          	or	s1,s1,a5
    b0e4:	881fe0ef          	jal	9964 <_Z25copy_sub_cmds_to_l1_cacheILb0ELb0E32CQPrefetchRelayPagedPackedSubCmdEPT1_RmmPmR20PrefetchExecBufStateS3_.isra.0>
    b0e8:	04c10593          	addi	a1,sp,76
    b0ec:	00090513          	mv	a0,s2
    b0f0:	df9fa0ef          	jal	5ee8 <_Z33process_relay_ringbuffer_sub_cmdsmPm>
    b0f4:	930d2783          	lw	a5,-1744(s10)
    b0f8:	949ff06f          	j	aa40 <.L868>

0000b0fc <.L810>:
    b0fc:	00f65e13          	srli	t3,a2,0xf
    b100:	001e1e13          	slli	t3,t3,0x1
    b104:	00461613          	slli	a2,a2,0x4
    b108:	93cd2823          	sw	t3,-1744(s10)
    b10c:	01467633          	and	a2,a2,s4
    b110:	22060263          	beqz	a2,b334 <.L919>
    b114:	ffb01eb7          	lui	t4,0xffb01
    b118:	91cea783          	lw	a5,-1764(t4) # ffb0091c <_ZZ16fetch_q_get_cmdsILm0EEvRmS0_S0_E17pending_read_size>
    b11c:	02079263          	bnez	a5,b140 <.L812>
    b120:	0005a7b7          	lui	a5,0x5a
    b124:	44078793          	addi	a5,a5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    b128:	01b606b3          	add	a3,a2,s11
    b12c:	24d7f063          	bgeu	a5,a3,b36c <.L920>
    b130:	ebb40263          	beq	s0,s11,a7d4 <.L921>
    b134:	02c12403          	lw	s0,44(sp)
    b138:	825ff06f          	j	a95c <.L809>

0000b13c <.L917>:
    b13c:	000d8413          	mv	s0,s11

0000b140 <.L812>:
    b140:	000d8993          	mv	s3,s11
    b144:	768d9263          	bne	s11,s0,b8a8 <.L916>

0000b148 <.L826>:
    b148:	ffb00337          	lui	t1,0xffb00
    b14c:	03c30313          	addi	t1,t1,60 # ffb0003c <noc_reads_num_issued>
    b150:	00032603          	lw	a2,0(t1)
    b154:	ffb206b7          	lui	a3,0xffb20

0000b158 <.L829>:
    b158:	2086a783          	lw	a5,520(a3) # ffb20208 <__stack_top+0x1e208>
    b15c:	fec79ee3          	bne	a5,a2,b158 <.L829>
    b160:	0ff0000f          	fence
    b164:	02c12403          	lw	s0,44(sp)
    b168:	008df663          	bgeu	s11,s0,b174 <.L830>
    b16c:	03b12623          	sw	s11,44(sp)
    b170:	000d8413          	mv	s0,s11

0000b174 <.L830>:
    b174:	90872803          	lw	a6,-1784(a4)
    b178:	91cea603          	lw	a2,-1764(t4)
    b17c:	00085783          	lhu	a5,0(a6) # 4000 <_start-0x9d0>
    b180:	fff806b7          	lui	a3,0xfff80
    b184:	ff068693          	addi	a3,a3,-16 # fff7fff0 <__instrn_buffer+0x13fff0>
    b188:	00cd8db3          	add	s11,s11,a2
    b18c:	900eae23          	sw	zero,-1764(t4)
    b190:	00479613          	slli	a2,a5,0x4
    b194:	0807c7b3          	zext.h	a5,a5
    b198:	00d67633          	and	a2,a2,a3
    b19c:	fc060063          	beqz	a2,a95c <.L809>
    b1a0:	00f7d793          	srli	a5,a5,0xf
    b1a4:	00179793          	slli	a5,a5,0x1
    b1a8:	92fd2823          	sw	a5,-1744(s10)
    b1ac:	00200593          	li	a1,2
    b1b0:	00cd86b3          	add	a3,s11,a2
    b1b4:	48b78a63          	beq	a5,a1,b648 <.L1006>
    b1b8:	0005a7b7          	lui	a5,0x5a
    b1bc:	44078793          	addi	a5,a5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    b1c0:	00d7f863          	bgeu	a5,a3,b1d0 <.L843>
    b1c4:	648d9463          	bne	s11,s0,b80c <.L927>
    b1c8:	0001adb7          	lui	s11,0x1a
    b1cc:	440d8d93          	addi	s11,s11,1088 # 1a440 <__kernel_data_lma+0xeb8c>

0000b1d0 <.L843>:
    b1d0:	ffb01e37          	lui	t3,0xffb01
    b1d4:	90ce2483          	lw	s1,-1780(t3) # ffb0090c <_ZL13pcie_read_ptr>
    b1d8:	440007b7          	lui	a5,0x44000
    b1dc:	10006437          	lui	s0,0x10006
    b1e0:	009606b3          	add	a3,a2,s1
    b1e4:	10078793          	addi	a5,a5,256 # 44000100 <__kernel_data_lma+0x43ff484c>
    b1e8:	00048893          	mv	a7,s1
    b1ec:	13040413          	addi	s0,s0,304 # 10006130 <__kernel_data_lma+0xfffa87c>
    b1f0:	2ed7e663          	bltu	a5,a3,b4dc <.L1007>

0000b1f4 <.L846>:
    b1f4:	00004537          	lui	a0,0x4
    b1f8:	66c57663          	bgeu	a0,a2,b864 <.L928>
    b1fc:	ffffc7b7          	lui	a5,0xffffc
    b200:	fff78693          	addi	a3,a5,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    b204:	00d608b3          	add	a7,a2,a3
    b208:	00f8ff33          	and	t5,a7,a5
    b20c:	00af0f33          	add	t5,t5,a0
    b210:	100003b7          	lui	t2,0x10000
    b214:	01000937          	lui	s2,0x1000
    b218:	01bf0f33          	add	t5,t5,s11
    b21c:	00f38393          	addi	t2,t2,15 # 1000000f <__kernel_data_lma+0xfff475b>
    b220:	fff90913          	addi	s2,s2,-1 # ffffff <__kernel_data_lma+0xff474b>
    b224:	00048593          	mv	a1,s1
    b228:	00040293          	mv	t0,s0
    b22c:	000d8f93          	mv	t6,s11
    b230:	ffb216b7          	lui	a3,0xffb21
    b234:	00100993          	li	s3,1

0000b238 <.L848>:
    b238:	8406a783          	lw	a5,-1984(a3) # ffb20840 <__stack_top+0x1e840>
    b23c:	fe079ee3          	bnez	a5,b238 <.L848>
    b240:	81f6a623          	sw	t6,-2036(a3)
    b244:	80b6a023          	sw	a1,-2048(a3)
    b248:	0072f7b3          	and	a5,t0,t2
    b24c:	80f6a223          	sw	a5,-2044(a3)
    b250:	0042d793          	srli	a5,t0,0x4
    b254:	0127f7b3          	and	a5,a5,s2
    b258:	80f6a423          	sw	a5,-2040(a3)
    b25c:	82a6a023          	sw	a0,-2016(a3)
    b260:	8536a023          	sw	s3,-1984(a3)
    b264:	00032783          	lw	a5,0(t1)
    b268:	00af8fb3          	add	t6,t6,a0
    b26c:	00178793          	addi	a5,a5,1
    b270:	00f32023          	sw	a5,0(t1)
    b274:	00a587b3          	add	a5,a1,a0
    b278:	00b7b5b3          	sltu	a1,a5,a1
    b27c:	005582b3          	add	t0,a1,t0
    b280:	00078593          	mv	a1,a5
    b284:	fbef9ae3          	bne	t6,t5,b238 <.L848>
    b288:	00e8d693          	srli	a3,a7,0xe
    b28c:	00e69593          	slli	a1,a3,0xe
    b290:	40a607b3          	sub	a5,a2,a0
    b294:	00168693          	addi	a3,a3,1
    b298:	40b787b3          	sub	a5,a5,a1
    b29c:	00e69593          	slli	a1,a3,0xe
    b2a0:	009584b3          	add	s1,a1,s1
    b2a4:	0126d693          	srli	a3,a3,0x12
    b2a8:	00b4b5b3          	sltu	a1,s1,a1
    b2ac:	008686b3          	add	a3,a3,s0
    b2b0:	00d585b3          	add	a1,a1,a3
    b2b4:	0075f5b3          	and	a1,a1,t2
    b2b8:	00048893          	mv	a7,s1

0000b2bc <.L847>:
    b2bc:	ffb216b7          	lui	a3,0xffb21

0000b2c0 <.L850>:
    b2c0:	8406a503          	lw	a0,-1984(a3) # ffb20840 <__stack_top+0x1e840>
    b2c4:	fe051ee3          	bnez	a0,b2c0 <.L850>
    b2c8:	81e6a623          	sw	t5,-2036(a3)
    b2cc:	8116a023          	sw	a7,-2048(a3)
    b2d0:	80b6a223          	sw	a1,-2044(a3)
    b2d4:	61300593          	li	a1,1555
    b2d8:	80b6a423          	sw	a1,-2040(a3)
    b2dc:	82f6a023          	sw	a5,-2016(a3)
    b2e0:	00100793          	li	a5,1
    b2e4:	84f6a023          	sw	a5,-1984(a3)
    b2e8:	00032683          	lw	a3,0(t1)
    b2ec:	90ce2783          	lw	a5,-1780(t3)
    b2f0:	00168693          	addi	a3,a3,1
    b2f4:	00c787b3          	add	a5,a5,a2
    b2f8:	90fe2623          	sw	a5,-1780(t3)
    b2fc:	00d32023          	sw	a3,0(t1)
    b300:	00081023          	sh	zero,0(a6)
    b304:	000197b7          	lui	a5,0x19
    b308:	6d07a023          	sw	a6,1728(a5) # 196c0 <__kernel_data_lma+0xde0c>
    b30c:	90ce2683          	lw	a3,-1780(t3)
    b310:	00280813          	addi	a6,a6,2
    b314:	6cd7a223          	sw	a3,1732(a5)
    b318:	0001a7b7          	lui	a5,0x1a
    b31c:	91072423          	sw	a6,-1784(a4)
    b320:	43c78693          	addi	a3,a5,1084 # 1a43c <__kernel_data_lma+0xeb88>
    b324:	02c12403          	lw	s0,44(sp)
    b328:	50d80863          	beq	a6,a3,b838 <.L1008>
    b32c:	90ceae23          	sw	a2,-1764(t4)
    b330:	e2cff06f          	j	a95c <.L809>

0000b334 <.L919>:
    b334:	000d8993          	mv	s3,s11
    b338:	decff06f          	j	a924 <.L814>

0000b33c <.L815>:
    b33c:	01412a83          	lw	s5,20(sp)
    b340:	000048b7          	lui	a7,0x4
    b344:	915b2623          	sw	s5,-1780(s6) # 9990c <__kernel_data_lma+0x8e058>
    b348:	01812b83          	lw	s7,24(sp)
    b34c:	000a8813          	mv	a6,s5
    b350:	cac8e663          	bltu	a7,a2,a7fc <.L1009>

0000b354 <.L922>:
    b354:	ffb00337          	lui	t1,0xffb00
    b358:	03c30313          	addi	t1,t1,60 # ffb0003c <noc_reads_num_issued>
    b35c:	00060793          	mv	a5,a2
    b360:	00098f93          	mv	t6,s3
    b364:	10000537          	lui	a0,0x10000
    b368:	d48ff06f          	j	a8b0 <.L817>

0000b36c <.L920>:
    b36c:	000d8993          	mv	s3,s11
    b370:	c6cff06f          	j	a7dc <.L813>

0000b374 <.L1000>:
    b374:	fff6a637          	lui	a2,0xfff6a
    b378:	00c58533          	add	a0,a1,a2
    b37c:	00090893          	mv	a7,s2
    b380:	00058613          	mv	a2,a1
    b384:	000a0993          	mv	s3,s4
    b388:	0ca87e63          	bgeu	a6,a0,b464 <.L904>
    b38c:	ffb20637          	lui	a2,0xffb20

0000b390 <.L900>:
    b390:	04062503          	lw	a0,64(a2) # ffb20040 <__stack_top+0x1e040>
    b394:	fe051ee3          	bnez	a0,b390 <.L900>
    b398:	01462023          	sw	s4,0(a2)
    b39c:	00004bb7          	lui	s7,0x4
    b3a0:	03762023          	sw	s7,32(a2)
    b3a4:	00b62623          	sw	a1,12(a2)
    b3a8:	00072883          	lw	a7,0(a4)
    b3ac:	0006a503          	lw	a0,0(a3)
    b3b0:	00188893          	addi	a7,a7,1 # 4001 <_start-0x9cf>
    b3b4:	00150513          	addi	a0,a0,1 # 10000001 <__kernel_data_lma+0xfff474d>
    b3b8:	01172023          	sw	a7,0(a4)
    b3bc:	00a6a023          	sw	a0,0(a3)
    b3c0:	00100c13          	li	s8,1
    b3c4:	05862023          	sw	s8,64(a2)
    b3c8:	fff6e637          	lui	a2,0xfff6e
    b3cc:	00c58633          	add	a2,a1,a2
    b3d0:	017a02b3          	add	t0,s4,s7
    b3d4:	017589b3          	add	s3,a1,s7
    b3d8:	48cbfe63          	bgeu	s7,a2,b874 <.L1010>
    b3dc:	00092637          	lui	a2,0x92
    b3e0:	fff60613          	addi	a2,a2,-1 # 91fff <__kernel_data_lma+0x8674b>
    b3e4:	40b608b3          	sub	a7,a2,a1
    b3e8:	ffffc637          	lui	a2,0xffffc
    b3ec:	00c8f533          	and	a0,a7,a2
    b3f0:	41460633          	sub	a2,a2,s4
    b3f4:	01360ab3          	add	s5,a2,s3
    b3f8:	000089b7          	lui	s3,0x8
    b3fc:	013a09b3          	add	s3,s4,s3
    b400:	00a989b3          	add	s3,s3,a0
    b404:	ffb20537          	lui	a0,0xffb20

0000b408 <.L902>:
    b408:	04052603          	lw	a2,64(a0) # ffb20040 <__stack_top+0x1e040>
    b40c:	fe061ee3          	bnez	a2,b408 <.L902>
    b410:	00552023          	sw	t0,0(a0)
    b414:	005a8633          	add	a2,s5,t0
    b418:	00c52623          	sw	a2,12(a0)
    b41c:	00072603          	lw	a2,0(a4)
    b420:	017282b3          	add	t0,t0,s7
    b424:	00160613          	addi	a2,a2,1 # ffffc001 <__instrn_buffer+0x1bc001>
    b428:	00c72023          	sw	a2,0(a4)
    b42c:	0006a603          	lw	a2,0(a3)
    b430:	00160613          	addi	a2,a2,1
    b434:	00c6a023          	sw	a2,0(a3)
    b438:	05852023          	sw	s8,64(a0)
    b43c:	fd3296e3          	bne	t0,s3,b408 <.L902>
    b440:	00e8d613          	srli	a2,a7,0xe
    b444:	000928b7          	lui	a7,0x92
    b448:	00e61513          	slli	a0,a2,0xe
    b44c:	40b888b3          	sub	a7,a7,a1
    b450:	00050613          	mv	a2,a0
    b454:	40a888b3          	sub	a7,a7,a0
    b458:	00008537          	lui	a0,0x8
    b45c:	00a58533          	add	a0,a1,a0
    b460:	00a60633          	add	a2,a2,a0

0000b464 <.L904>:
    b464:	0407a503          	lw	a0,64(a5)
    b468:	fe051ee3          	bnez	a0,b464 <.L904>
    b46c:	0137a023          	sw	s3,0(a5)
    b470:	0317a023          	sw	a7,32(a5)
    b474:	00c7a623          	sw	a2,12(a5)
    b478:	00072503          	lw	a0,0(a4)
    b47c:	0006a603          	lw	a2,0(a3)
    b480:	00150513          	addi	a0,a0,1 # 8001 <.L417+0x25>
    b484:	00160613          	addi	a2,a2,1
    b488:	fff668b7          	lui	a7,0xfff66
    b48c:	011585b3          	add	a1,a1,a7
    b490:	00a72023          	sw	a0,0(a4)
    b494:	00c6a023          	sw	a2,0(a3)
    b498:	006582b3          	add	t0,a1,t1
    b49c:	012a0a33          	add	s4,s4,s2
    b4a0:	05c7a023          	sw	t3,64(a5)
    b4a4:	f30ff06f          	j	abd4 <.L898>

0000b4a8 <.L1002>:
    b4a8:	02c10513          	addi	a0,sp,44
    b4ac:	ee9fd0ef          	jal	9394 <_Z27process_relay_inline_commonILb0ELb0ELb1E24DispatchRelayInlineStateEmRmS1_R20PrefetchExecBufState.constprop.0>
    b4b0:	00050493          	mv	s1,a0
    b4b4:	930d2783          	lw	a5,-1744(s10)
    b4b8:	d88ff06f          	j	aa40 <.L868>

0000b4bc <.L914>:
    b4bc:	ffb01737          	lui	a4,0xffb01
    b4c0:	92f72623          	sw	a5,-1748(a4) # ffb0092c <_ZL17ringbuffer_offset>
    b4c4:	04000493          	li	s1,64
    b4c8:	930d2783          	lw	a5,-1744(s10)
    b4cc:	d74ff06f          	j	aa40 <.L868>

0000b4d0 <.L999>:
    b4d0:	0001a7b7          	lui	a5,0x1a
    b4d4:	90f3ac23          	sw	a5,-1768(t2)
    b4d8:	e94ff06f          	j	ab6c <.L894>

0000b4dc <.L1007>:
    b4dc:	400007b7          	lui	a5,0x40000
    b4e0:	10078793          	addi	a5,a5,256 # 40000100 <__kernel_data_lma+0x3fff484c>
    b4e4:	ffb016b7          	lui	a3,0xffb01
    b4e8:	8fc6a403          	lw	s0,-1796(a3) # ffb008fc <.LC0+0x4>
    b4ec:	00078893          	mv	a7,a5
    b4f0:	90fe2623          	sw	a5,-1780(t3)
    b4f4:	00078493          	mv	s1,a5
    b4f8:	cfdff06f          	j	b1f4 <.L846>

0000b4fc <.L1005>:
    b4fc:	ec5fb0ef          	jal	73c0 <_Z23process_relay_paged_cmdILb1EEmmRmm.constprop.0.isra.0>
    b500:	04000493          	li	s1,64
    b504:	930d2783          	lw	a5,-1744(s10)
    b508:	d38ff06f          	j	aa40 <.L868>

0000b50c <.L1003>:
    b50c:	fff628b7          	lui	a7,0xfff62
    b510:	01160933          	add	s2,a2,a7
    b514:	00060313          	mv	t1,a2
    b518:	000b0893          	mv	a7,s6
    b51c:	00058993          	mv	s3,a1
    b520:	0f287263          	bgeu	a6,s2,b604 <.L882>
    b524:	ffb218b7          	lui	a7,0xffb21

0000b528 <.L878>:
    b528:	0408a303          	lw	t1,64(a7) # ffb21040 <__stack_top+0x1f040>
    b52c:	fe031ee3          	bnez	t1,b528 <.L878>
    b530:	00b8a023          	sw	a1,0(a7)
    b534:	00004bb7          	lui	s7,0x4
    b538:	0378a023          	sw	s7,32(a7)
    b53c:	00c8a623          	sw	a2,12(a7)
    b540:	00072903          	lw	s2,0(a4)
    b544:	0006a303          	lw	t1,0(a3)
    b548:	00190913          	addi	s2,s2,1
    b54c:	00130313          	addi	t1,t1,1
    b550:	0066a023          	sw	t1,0(a3)
    b554:	01272023          	sw	s2,0(a4)
    b558:	00100c93          	li	s9,1
    b55c:	0598a023          	sw	s9,64(a7)
    b560:	fff668b7          	lui	a7,0xfff66
    b564:	011608b3          	add	a7,a2,a7
    b568:	01758a33          	add	s4,a1,s7
    b56c:	01760333          	add	t1,a2,s7
    b570:	331bf463          	bgeu	s7,a7,b898 <.L1011>
    b574:	0009a937          	lui	s2,0x9a
    b578:	fff90913          	addi	s2,s2,-1 # 99fff <__kernel_data_lma+0x8e74b>
    b57c:	ffffc8b7          	lui	a7,0xffffc
    b580:	40c90933          	sub	s2,s2,a2
    b584:	011979b3          	and	s3,s2,a7
    b588:	40b888b3          	sub	a7,a7,a1
    b58c:	006888b3          	add	a7,a7,t1
    b590:	01112e23          	sw	a7,28(sp)
    b594:	000088b7          	lui	a7,0x8
    b598:	011588b3          	add	a7,a1,a7
    b59c:	011989b3          	add	s3,s3,a7
    b5a0:	ffb21337          	lui	t1,0xffb21

0000b5a4 <.L880>:
    b5a4:	04032883          	lw	a7,64(t1) # ffb21040 <__stack_top+0x1f040>
    b5a8:	fe089ee3          	bnez	a7,b5a4 <.L880>
    b5ac:	01c12883          	lw	a7,28(sp)
    b5b0:	01432023          	sw	s4,0(t1)
    b5b4:	014888b3          	add	a7,a7,s4
    b5b8:	01132623          	sw	a7,12(t1)
    b5bc:	00072883          	lw	a7,0(a4)
    b5c0:	017a0a33          	add	s4,s4,s7
    b5c4:	00188893          	addi	a7,a7,1 # 8001 <.L417+0x25>
    b5c8:	01172023          	sw	a7,0(a4)
    b5cc:	0006a883          	lw	a7,0(a3)
    b5d0:	00188893          	addi	a7,a7,1
    b5d4:	0116a023          	sw	a7,0(a3)
    b5d8:	05932023          	sw	s9,64(t1)
    b5dc:	fd4994e3          	bne	s3,s4,b5a4 <.L880>
    b5e0:	00e95913          	srli	s2,s2,0xe
    b5e4:	0009a8b7          	lui	a7,0x9a
    b5e8:	00e91313          	slli	t1,s2,0xe
    b5ec:	40c888b3          	sub	a7,a7,a2
    b5f0:	00030913          	mv	s2,t1
    b5f4:	406888b3          	sub	a7,a7,t1
    b5f8:	00008337          	lui	t1,0x8
    b5fc:	00660333          	add	t1,a2,t1
    b600:	00690333          	add	t1,s2,t1

0000b604 <.L882>:
    b604:	0407a903          	lw	s2,64(a5)
    b608:	fe091ee3          	bnez	s2,b604 <.L882>
    b60c:	0137a023          	sw	s3,0(a5)
    b610:	0317a023          	sw	a7,32(a5)
    b614:	0067a623          	sw	t1,12(a5)
    b618:	00072903          	lw	s2,0(a4)
    b61c:	0006a883          	lw	a7,0(a3)
    b620:	00190913          	addi	s2,s2,1
    b624:	00188893          	addi	a7,a7,1 # 9a001 <__kernel_data_lma+0x8e74d>
    b628:	fff5e337          	lui	t1,0xfff5e
    b62c:	00660333          	add	t1,a2,t1
    b630:	01272023          	sw	s2,0(a4)
    b634:	0116a023          	sw	a7,0(a3)
    b638:	01e30333          	add	t1,t1,t5
    b63c:	016585b3          	add	a1,a1,s6
    b640:	05d7a023          	sw	t4,64(a5)
    b644:	fd4ff06f          	j	ae18 <.L876>

0000b648 <.L1006>:
    b648:	0005a7b7          	lui	a5,0x5a
    b64c:	44078793          	addi	a5,a5,1088 # 5a440 <__kernel_data_lma+0x4eb8c>
    b650:	00d7f863          	bgeu	a5,a3,b660 <.L833>
    b654:	b08d9463          	bne	s11,s0,a95c <.L809>
    b658:	0001adb7          	lui	s11,0x1a
    b65c:	440d8d93          	addi	s11,s11,1088 # 1a440 <__kernel_data_lma+0xeb8c>

0000b660 <.L833>:
    b660:	ffb01e37          	lui	t3,0xffb01
    b664:	90ce2f83          	lw	t6,-1780(t3) # ffb0090c <_ZL13pcie_read_ptr>
    b668:	440007b7          	lui	a5,0x44000
    b66c:	100064b7          	lui	s1,0x10006
    b670:	01f606b3          	add	a3,a2,t6
    b674:	10078793          	addi	a5,a5,256 # 44000100 <__kernel_data_lma+0x43ff484c>
    b678:	000f8513          	mv	a0,t6
    b67c:	13048493          	addi	s1,s1,304 # 10006130 <__kernel_data_lma+0xfffa87c>
    b680:	18d7ec63          	bltu	a5,a3,b818 <.L1012>

0000b684 <.L835>:
    b684:	000045b7          	lui	a1,0x4
    b688:	20c5f063          	bgeu	a1,a2,b888 <.L925>
    b68c:	ffffc7b7          	lui	a5,0xffffc
    b690:	fff78693          	addi	a3,a5,-1 # ffffbfff <__instrn_buffer+0x1bbfff>
    b694:	00d60533          	add	a0,a2,a3
    b698:	00f57f33          	and	t5,a0,a5
    b69c:	00bf0f33          	add	t5,t5,a1
    b6a0:	100003b7          	lui	t2,0x10000
    b6a4:	01000937          	lui	s2,0x1000
    b6a8:	01bf0f33          	add	t5,t5,s11
    b6ac:	00f38393          	addi	t2,t2,15 # 1000000f <__kernel_data_lma+0xfff475b>
    b6b0:	fff90913          	addi	s2,s2,-1 # ffffff <__kernel_data_lma+0xff474b>
    b6b4:	000f8893          	mv	a7,t6
    b6b8:	00048413          	mv	s0,s1
    b6bc:	000d8293          	mv	t0,s11
    b6c0:	ffb216b7          	lui	a3,0xffb21
    b6c4:	00100993          	li	s3,1

0000b6c8 <.L837>:
    b6c8:	8406a783          	lw	a5,-1984(a3) # ffb20840 <__stack_top+0x1e840>
    b6cc:	fe079ee3          	bnez	a5,b6c8 <.L837>
    b6d0:	8056a623          	sw	t0,-2036(a3)
    b6d4:	8116a023          	sw	a7,-2048(a3)
    b6d8:	007477b3          	and	a5,s0,t2
    b6dc:	80f6a223          	sw	a5,-2044(a3)
    b6e0:	00445793          	srli	a5,s0,0x4
    b6e4:	0127f7b3          	and	a5,a5,s2
    b6e8:	80f6a423          	sw	a5,-2040(a3)
    b6ec:	82b6a023          	sw	a1,-2016(a3)
    b6f0:	8536a023          	sw	s3,-1984(a3)
    b6f4:	00032783          	lw	a5,0(t1) # fff5e000 <__instrn_buffer+0x11e000>
    b6f8:	00b282b3          	add	t0,t0,a1
    b6fc:	00178793          	addi	a5,a5,1
    b700:	00f32023          	sw	a5,0(t1)
    b704:	00b887b3          	add	a5,a7,a1
    b708:	0117b8b3          	sltu	a7,a5,a7
    b70c:	00888433          	add	s0,a7,s0
    b710:	00078893          	mv	a7,a5
    b714:	fa5f1ae3          	bne	t5,t0,b6c8 <.L837>
    b718:	00e55693          	srli	a3,a0,0xe
    b71c:	40b607b3          	sub	a5,a2,a1
    b720:	00e69593          	slli	a1,a3,0xe
    b724:	00168693          	addi	a3,a3,1
    b728:	40b787b3          	sub	a5,a5,a1
    b72c:	00e69593          	slli	a1,a3,0xe
    b730:	01f58fb3          	add	t6,a1,t6
    b734:	0126d693          	srli	a3,a3,0x12
    b738:	00bfb5b3          	sltu	a1,t6,a1
    b73c:	009686b3          	add	a3,a3,s1
    b740:	00d586b3          	add	a3,a1,a3
    b744:	0076f6b3          	and	a3,a3,t2
    b748:	000f8513          	mv	a0,t6

0000b74c <.L836>:
    b74c:	ffb215b7          	lui	a1,0xffb21

0000b750 <.L839>:
    b750:	8405a883          	lw	a7,-1984(a1) # ffb20840 <__stack_top+0x1e840>
    b754:	fe089ee3          	bnez	a7,b750 <.L839>
    b758:	81e5a623          	sw	t5,-2036(a1)
    b75c:	80a5a023          	sw	a0,-2048(a1)
    b760:	80d5a223          	sw	a3,-2044(a1)
    b764:	61300693          	li	a3,1555
    b768:	80d5a423          	sw	a3,-2040(a1)
    b76c:	82f5a023          	sw	a5,-2016(a1)
    b770:	00100793          	li	a5,1
    b774:	84f5a023          	sw	a5,-1984(a1)
    b778:	00032683          	lw	a3,0(t1)
    b77c:	90ce2783          	lw	a5,-1780(t3)
    b780:	00168693          	addi	a3,a3,1
    b784:	00c787b3          	add	a5,a5,a2
    b788:	90fe2623          	sw	a5,-1780(t3)
    b78c:	00d32023          	sw	a3,0(t1)
    b790:	00081023          	sh	zero,0(a6)
    b794:	000196b7          	lui	a3,0x19
    b798:	6d06a023          	sw	a6,1728(a3) # 196c0 <__kernel_data_lma+0xde0c>
    b79c:	90ce2583          	lw	a1,-1780(t3)
    b7a0:	0001a7b7          	lui	a5,0x1a
    b7a4:	6cb6a223          	sw	a1,1732(a3)
    b7a8:	00280813          	addi	a6,a6,2
    b7ac:	43c78693          	addi	a3,a5,1084 # 1a43c <__kernel_data_lma+0xeb88>
    b7b0:	08d80c63          	beq	a6,a3,b848 <.L1013>

0000b7b4 <.L840>:
    b7b4:	00032683          	lw	a3,0(t1)
    b7b8:	91072423          	sw	a6,-1784(a4)
    b7bc:	90ceae23          	sw	a2,-1764(t4)
    b7c0:	ffb207b7          	lui	a5,0xffb20

0000b7c4 <.L841>:
    b7c4:	2087a703          	lw	a4,520(a5) # ffb20208 <__stack_top+0x1e208>
    b7c8:	fed71ee3          	bne	a4,a3,b7c4 <.L841>
    b7cc:	0ff0000f          	fence
    b7d0:	02c12403          	lw	s0,44(sp)
    b7d4:	008df663          	bgeu	s11,s0,b7e0 <.L842>
    b7d8:	03b12623          	sw	s11,44(sp)
    b7dc:	000d8413          	mv	s0,s11

0000b7e0 <.L842>:
    b7e0:	91cea703          	lw	a4,-1764(t4)
    b7e4:	00100793          	li	a5,1
    b7e8:	00ed8db3          	add	s11,s11,a4
    b7ec:	900eae23          	sw	zero,-1764(t4)
    b7f0:	92fd2823          	sw	a5,-1744(s10)
    b7f4:	968ff06f          	j	a95c <.L809>

0000b7f8 <.L1001>:
    b7f8:	00060513          	mv	a0,a2
    b7fc:	0407a603          	lw	a2,64(a5)
    b800:	00058a13          	mv	s4,a1
    b804:	ca061463          	bnez	a2,acac <.L910>
    b808:	cacff06f          	j	acb4 <.L1014>

0000b80c <.L927>:
    b80c:	00000613          	li	a2,0
    b810:	90ceae23          	sw	a2,-1764(t4)
    b814:	948ff06f          	j	a95c <.L809>

0000b818 <.L1012>:
    b818:	400007b7          	lui	a5,0x40000
    b81c:	10078793          	addi	a5,a5,256 # 40000100 <__kernel_data_lma+0x3fff484c>
    b820:	ffb016b7          	lui	a3,0xffb01
    b824:	8fc6a483          	lw	s1,-1796(a3) # ffb008fc <.LC0+0x4>
    b828:	00078513          	mv	a0,a5
    b82c:	90fe2623          	sw	a5,-1780(t3)
    b830:	00078f93          	mv	t6,a5
    b834:	e51ff06f          	j	b684 <.L835>

0000b838 <.L1008>:
    b838:	84078793          	addi	a5,a5,-1984
    b83c:	90f72423          	sw	a5,-1784(a4)
    b840:	90ceae23          	sw	a2,-1764(t4)
    b844:	918ff06f          	j	a95c <.L809>

0000b848 <.L1013>:
    b848:	84078813          	addi	a6,a5,-1984
    b84c:	f69ff06f          	j	b7b4 <.L840>

0000b850 <.L1004>:
    b850:	0407a603          	lw	a2,64(a5)
    b854:	000b0913          	mv	s2,s6
    b858:	00088593          	mv	a1,a7
    b85c:	e8061a63          	bnez	a2,aef0 <.L888>
    b860:	e98ff06f          	j	aef8 <.L1015>

0000b864 <.L928>:
    b864:	00060793          	mv	a5,a2
    b868:	000d8f13          	mv	t5,s11
    b86c:	100005b7          	lui	a1,0x10000
    b870:	a4dff06f          	j	b2bc <.L847>

0000b874 <.L1010>:
    b874:	000968b7          	lui	a7,0x96
    b878:	00098613          	mv	a2,s3
    b87c:	40b888b3          	sub	a7,a7,a1
    b880:	00028993          	mv	s3,t0
    b884:	be1ff06f          	j	b464 <.L904>

0000b888 <.L925>:
    b888:	00060793          	mv	a5,a2
    b88c:	000d8f13          	mv	t5,s11
    b890:	100006b7          	lui	a3,0x10000
    b894:	eb9ff06f          	j	b74c <.L836>

0000b898 <.L1011>:
    b898:	0009e8b7          	lui	a7,0x9e
    b89c:	000a0993          	mv	s3,s4
    b8a0:	40c888b3          	sub	a7,a7,a2
    b8a4:	d61ff06f          	j	b604 <.L882>

0000b8a8 <.L916>:
    b8a8:	02c12403          	lw	s0,44(sp)
    b8ac:	00098d93          	mv	s11,s3
    b8b0:	8acff06f          	j	a95c <.L809>
