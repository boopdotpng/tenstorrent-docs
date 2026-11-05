# Layernorm (sharded, multicast) — All 5 cores (stripped)

######## BRISC (reader/mcast sender) — kernel=reader_mcast_sender_unary_sharded_ln ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/reader_mcast_sender_unary_sharded_ln/16564156399594138357/brisc/brisc.elf:     file format elf32-littleriscv
00004b60 <_start>:
    4b60:	addi	sp,sp,-16
    4b64:	sw	ra,12(sp)
    4b68:	lui	a5,0xffb01
    4b6c:	addi	a5,a5,-960 # ffb00c40 <__fw_export_ldm_end+0x10>
    4b70:	addi	a4,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4b74:	bltu	a4,a5,4b90 <.L51>
    4b78:	sw	zero,-4(a5)
    4b7c:	sw	zero,-8(a5)
    4b80:	sw	zero,-12(a5)
    4b84:	sw	zero,-16(a5)
    4b88:	addi	a5,a5,16
    4b8c:	bgeu	a4,a5,4b78 <.L52>
    4b90:	addi	a3,a5,-8
    4b94:	bltu	a4,a3,4c7c <.L63>
    4b98:	sw	zero,-12(a5)
    4b9c:	sw	zero,-16(a5)
    4ba0:	addi	a3,a5,-4
    4ba4:	bltu	a4,a3,4bac <.L54>
    4ba8:	sw	zero,-8(a5)
    4bac:	lui	a4,0x5
    4bb0:	addi	a4,a4,712 # 52c8 <__kernel_data_lma>
    4bb4:	addi	a5,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4bb8:	beq	a4,a5,4c18 <.L56>
    4bbc:	addi	a2,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4bc0:	sub	a2,a2,a5
    4bc4:	li	a1,8
    4bc8:	srai	a3,a2,0x2
    4bcc:	bge	a1,a2,4bfc <.L57>
    4bd0:	li	a6,2
    4bd4:	lw	a0,0(a4)
    4bd8:	lw	a1,4(a4)
    4bdc:	lw	a2,8(a4)
    4be0:	addi	a4,a4,12
    4be4:	addi	a5,a5,12
    4be8:	addi	a3,a3,-3
    4bec:	sw	a0,-12(a5)
    4bf0:	sw	a1,-8(a5)
    4bf4:	sw	a2,-4(a5)
    4bf8:	blt	a6,a3,4bd4 <.L58>
    4bfc:	blez	a3,4c18 <.L56>
    4c00:	lw	a1,0(a4)
    4c04:	li	a2,2
    4c08:	sw	a1,0(a5)
    4c0c:	bne	a3,a2,4c18 <.L56>
    4c10:	lw	a4,4(a4)
    4c14:	sw	a4,4(a5)
    4c18:	lui	a5,0xffb20
    4c1c:	lw	t3,520(a5) # ffb20208 <__fw_export_ldm_end+0x1f5d8>
    4c20:	lw	a7,552(a5)
    4c24:	lw	a0,516(a5)
    4c28:	lw	a2,512(a5)
    4c2c:	lw	a4,556(a5)
    4c30:	sw	a2,-2000(gp) # ffb00020 <noc_nonposted_atomics_acked>
    4c34:	sw	t3,-1976(gp) # ffb00038 <noc_reads_num_issued>
    4c38:	sw	a7,-1984(gp) # ffb00030 <noc_nonposted_writes_num_issued>
    4c3c:	sw	a0,-1992(gp) # ffb00028 <noc_nonposted_writes_acked>
    4c40:	sw	a4,-2008(gp) # ffb00018 <noc_posted_writes_num_issued>
    4c44:	lw	a4,1056(zero) # 420 <.LLST65+0x1>
    4c48:	li	a3,128
    4c4c:	slli	a4,a4,0x2
    4c50:	lbu	a5,1011(a4)
    4c54:	addi	a4,a4,96
    4c58:	beq	a5,a3,4c68 <.L60>
    4c5c:	fence
    4c60:	lbu	a5,915(a4)
    4c64:	bne	a5,a3,4c5c <.L61>
    4c68:	jal	4c84 <_Z11kernel_mainv>
    4c6c:	lw	ra,12(sp)
    4c70:	li	a0,0
    4c74:	addi	sp,sp,16
    4c78:	ret
    4c7c:	mv	a5,a3
    4c80:	j	4ba0 <.L53>
00004c84 <_Z11kernel_mainv>:
    4c84:	addi	sp,sp,-304
    4c88:	sw	s2,288(sp)
    4c8c:	lw	s2,-980(gp) # ffb0041c <sem_l1_base>
    4c90:	sw	s3,284(sp)
    4c94:	lw	s3,-2012(gp) # ffb00014 <rta_l1_base>
    4c98:	li	a2,256
    4c9c:	li	a1,0
    4ca0:	mv	a0,sp
    4ca4:	sw	s0,296(sp)
    4ca8:	sw	s1,292(sp)
    4cac:	sw	s4,280(sp)
    4cb0:	sw	s5,276(sp)
    4cb4:	sw	s6,272(sp)
    4cb8:	sw	s7,268(sp)
    4cbc:	sw	s8,264(sp)
    4cc0:	sw	s9,260(sp)
    4cc4:	lw	s6,0(s3)
    4cc8:	lw	s9,4(s3)
    4ccc:	lw	s8,8(s3)
    4cd0:	lw	s7,12(s3)
    4cd4:	lw	s0,16(s3)
    4cd8:	lw	s1,20(s3)
    4cdc:	sw	ra,300(sp)
    4ce0:	jal	51ec <memset>
    4ce4:	addi	s5,s2,16
    4ce8:	addi	s4,s2,32
    4cec:	li	a1,8
    4cf0:	mv	a2,sp
    4cf4:	mv	a4,sp
    4cf8:	sh2add	a3,s0,s3
    4cfc:	sh2add	a5,s1,s3
    4d00:	lw	a3,24(a3)
    4d04:	lw	a5,56(a5)
    4d08:	addi	s0,s0,1
    4d0c:	addi	a4,a4,8
    4d10:	sw	a3,-8(a4)
    4d14:	sw	a5,-4(a4)
    4d18:	bne	s0,a1,4d34 <.L2>
    4d1c:	addi	s1,s1,1
    4d20:	addi	a5,s1,-4
    4d24:	snez	a5,a5
    4d28:	neg	a5,a5
    4d2c:	and	s1,s1,a5
    4d30:	li	s0,0
    4d34:	addi	a5,sp,256
    4d38:	bne	a4,a5,4cf8 <.L3>
    4d3c:	lui	a3,0xffb4b
    4d40:	lw	a4,32(a3) # ffb4b020 <__fw_export_ldm_end+0x4a3f0>
    4d44:	zext.h	a4,a4
    4d48:	lw	a5,40(a3)
    4d4c:	zext.h	a5,a5
    4d50:	beq	a5,a4,4d48 <.L4>
    4d54:	li	a5,1
    4d58:	sw	a5,0(s2)
    4d5c:	li	a4,31
    4d60:	fence
    4d64:	lw	a5,0(s5)
    4d68:	bne	a5,a4,4d60 <.L5>
    4d6c:	slli	a0,s6,0x10
    4d70:	slli	s9,s9,0x16
    4d74:	or	a0,a0,s9
    4d78:	slli	s8,s8,0x4
    4d7c:	or	a0,a0,s8
    4d80:	slli	s7,s7,0xa
    4d84:	or	a0,a0,s7
    4d88:	sw	zero,16(s2)
    4d8c:	lui	a5,0xffb21
    4d90:	lw	t0,64(a5) # ffb21040 <__fw_export_ldm_end+0x20410>
    4d94:	bnez	t0,4d90 <.L6>
    4d98:	lui	a4,0x8
    4d9c:	addi	a4,a4,434 # 81b2 <.LASF1233+0x9>
    4da0:	sw	a4,28(a5)
    4da4:	sw	s2,0(a5)
    4da8:	lui	t4,0x10000
    4dac:	sw	s2,12(a5)
    4db0:	and	t4,a0,t4
    4db4:	slli	t1,a0,0x4
    4db8:	sw	t4,16(a5)
    4dbc:	srli	t1,t1,0x8
    4dc0:	sw	t1,20(a5)
    4dc4:	li	a4,4
    4dc8:	sw	a4,32(a5)
    4dcc:	li	a4,1
    4dd0:	sw	a4,64(a5)
    4dd4:	addi	a7,gp,-1984 # ffb00030 <noc_nonposted_writes_num_issued>
    4dd8:	addi	a6,gp,-1992 # ffb00028 <noc_nonposted_writes_acked>
    4ddc:	lw	a4,0(a7)
    4de0:	lw	a5,0(a6)
    4de4:	addi	a4,a4,1
    4de8:	addi	a5,a5,31
    4dec:	lui	a1,0xffb00
    4df0:	addi	a1,a1,1064 # ffb00428 <cb_interface>
    4df4:	sw	a4,0(a7)
    4df8:	sw	a5,0(a6)
    4dfc:	lui	a3,0xffb4d
    4e00:	lw	t2,40(a3) # ffb4d028 <__fw_export_ldm_end+0x4c3f8>
    4e04:	lw	s1,368(a1)
    4e08:	lw	t5,400(a1)
    4e0c:	srli	t3,a0,0x4
    4e10:	li	t6,7
    4e14:	fence
    4e18:	lw	a4,32(a3)
    4e1c:	lw	a5,428(a1)
    4e20:	add	a5,a5,a4
    4e24:	sub	a5,a5,t2
    4e28:	zext.h	a5,a5
    4e2c:	bgeu	t6,a5,4e14 <.L7>
    4e30:	lui	s5,0x10000
    4e34:	lui	s3,0x1000
    4e38:	mv	t2,sp
    4e3c:	addi	t6,gp,-1976 # ffb00038 <noc_reads_num_issued>
    4e40:	addi	s5,s5,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    4e44:	addi	s3,s3,-1 # ffffff <.LASF356+0xff6786>
    4e48:	lui	a4,0xffb21
    4e4c:	lui	s0,0x1
    4e50:	li	s7,1
    4e54:	lui	s6,0x8
    4e58:	lw	a3,4(t2)
    4e5c:	lw	a5,0(t2)
    4e60:	lw	s8,436(a1)
    4e64:	slli	a3,a3,0xa
    4e68:	slli	a5,a5,0x4
    4e6c:	or	a3,a3,a5
    4e70:	add	s8,t0,s8
    4e74:	lw	a5,-1984(a4) # ffb20840 <__fw_export_ldm_end+0x1fc10>
    4e78:	bnez	a5,4e74 <.L8>
    4e7c:	sw	s8,-2036(a4)
    4e80:	sw	s1,-2048(a4)
    4e84:	and	s8,a3,s5
    4e88:	srli	a3,a3,0x4
    4e8c:	sw	s8,-2044(a4)
    4e90:	and	a3,a3,s3
    4e94:	sw	a3,-2040(a4)
    4e98:	sw	s0,-2016(a4)
    4e9c:	sw	s7,-1984(a4)
    4ea0:	lw	a3,0(t6)
    4ea4:	add	t0,t0,s0
    4ea8:	addi	a3,a3,1
    4eac:	sw	a3,0(t6)
    4eb0:	addi	t2,t2,8
    4eb4:	bne	t0,s6,4e58 <.L9>
    4eb8:	lui	t0,0xffb20
    4ebc:	lw	a4,520(t0) # ffb20208 <__fw_export_ldm_end+0x1f5d8>
    4ec0:	bne	a4,a3,4ebc <.L10>
    4ec4:	fence
    4ec8:	lui	t0,0xffb4d
    4ecc:	lw	t2,436(a1)
    4ed0:	lw	a3,40(t0) # ffb4d028 <__fw_export_ldm_end+0x4c3f8>
    4ed4:	lw	a4,424(a1)
    4ed8:	addi	a3,a3,8
    4edc:	sh3add	a4,a4,t2
    4ee0:	sw	a4,436(a1)
    4ee4:	sw	a3,40(t0)
    4ee8:	lw	a3,420(a1)
    4eec:	beq	a4,a3,51dc <.L49>
    4ef0:	li	a3,3
    4ef4:	fence
    4ef8:	lw	a4,0(s4)
    4efc:	bne	a4,a3,4ef4 <.L12>
    4f00:	sw	zero,32(s2)
    4f04:	lui	t0,0xffb4d
    4f08:	lw	s0,40(t0) # ffb4d028 <__fw_export_ldm_end+0x4c3f8>
    4f0c:	li	t2,2
    4f10:	fence
    4f14:	lw	a3,32(t0)
    4f18:	lw	a4,428(a1)
    4f1c:	add	a4,a4,a3
    4f20:	sub	a4,a4,s0
    4f24:	zext.h	a4,a4
    4f28:	bgeu	t2,a4,4f10 <.L13>
    4f2c:	lui	s3,0x10000
    4f30:	lui	s1,0x1000
    4f34:	addi	s3,s3,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    4f38:	addi	s1,s1,-1 # ffffff <.LASF356+0xff6786>
    4f3c:	lui	a3,0xffb21
    4f40:	lui	s0,0x1
    4f44:	li	s5,1
    4f48:	lui	s4,0x3
    4f4c:	lw	t0,68(a2)
    4f50:	lw	a4,64(a2)
    4f54:	lw	t2,436(a1)
    4f58:	slli	t0,t0,0xa
    4f5c:	slli	a4,a4,0x4
    4f60:	or	t0,t0,a4
    4f64:	add	t2,a5,t2
    4f68:	lw	a4,-1984(a3) # ffb20840 <__fw_export_ldm_end+0x1fc10>
    4f6c:	bnez	a4,4f68 <.L14>
    4f70:	sw	t2,-2036(a3)
    4f74:	sw	t5,-2048(a3)
    4f78:	and	a4,t0,s3
    4f7c:	srli	t0,t0,0x4
    4f80:	sw	a4,-2044(a3)
    4f84:	and	t0,t0,s1
    4f88:	sw	t0,-2040(a3)
    4f8c:	sw	s0,-2016(a3)
    4f90:	sw	s5,-1984(a3)
    4f94:	lw	a4,0(t6)
    4f98:	add	a5,a5,s0
    4f9c:	addi	a4,a4,1
    4fa0:	sw	a4,0(t6)
    4fa4:	addi	a2,a2,64
    4fa8:	bne	a5,s4,4f4c <.L15>
    4fac:	lui	a3,0xffb20
    4fb0:	lw	a5,520(a3) # ffb20208 <__fw_export_ldm_end+0x1f5d8>
    4fb4:	bne	a5,a4,4fb0 <.L16>
    4fb8:	fence
    4fbc:	lui	a3,0xffb4d
    4fc0:	lw	t5,436(a1)
    4fc4:	lw	a5,424(a1)
    4fc8:	lw	a4,40(a3) # ffb4d028 <__fw_export_ldm_end+0x4c3f8>
    4fcc:	sh1add	a5,a5,a5
    4fd0:	add	a5,a5,t5
    4fd4:	lw	a2,420(a1)
    4fd8:	addi	a4,a4,3
    4fdc:	sw	a5,436(a1)
    4fe0:	sw	a4,40(a3)
    4fe4:	bne	a5,a2,4ff4 <.L17>
    4fe8:	lw	a4,416(a1)
    4fec:	sub	a5,a5,a4
    4ff0:	sw	a5,436(a1)
    4ff4:	lui	a3,0xffb54
    4ff8:	lw	a4,32(a3) # ffb54020 <__fw_export_ldm_end+0x533f0>
    4ffc:	zext.h	a4,a4
    5000:	lw	a5,40(a3)
    5004:	zext.h	a5,a5
    5008:	beq	a5,a4,5000 <.L18>
    500c:	lui	a2,0xffb4f
    5010:	lw	a3,40(a2) # ffb4f028 <__fw_export_ldm_end+0x4e3f8>
    5014:	lw	t5,656(a1)
    5018:	zext.h	a3,a3
    501c:	fence
    5020:	lw	a4,32(a2)
    5024:	lw	a5,492(a1)
    5028:	add	a5,a5,a4
    502c:	zext.h	a5,a5
    5030:	beq	a3,a5,501c <.L19>
    5034:	lw	a3,4(sp)
    5038:	lw	a5,0(sp)
    503c:	slli	a3,a3,0xa
    5040:	slli	a5,a5,0x4
    5044:	lw	a2,500(a1)
    5048:	or	a3,a3,a5
    504c:	lui	a4,0xffb21
    5050:	lw	a5,-1984(a4) # ffb20840 <__fw_export_ldm_end+0x1fc10>
    5054:	bnez	a5,5050 <.L20>
    5058:	sw	a2,-2036(a4)
    505c:	lui	a2,0x10000
    5060:	sw	t5,-2048(a4)
    5064:	and	a2,a3,a2
    5068:	slli	a5,a3,0x4
    506c:	sw	a2,-2044(a4)
    5070:	srli	a5,a5,0x8
    5074:	sw	a5,-2040(a4)
    5078:	lui	a5,0x1
    507c:	sw	a5,-2016(a4)
    5080:	li	a5,1
    5084:	sw	a5,-1984(a4)
    5088:	lw	a4,0(t6)
    508c:	lui	a3,0xffb20
    5090:	add	a4,a4,a5
    5094:	sw	a4,0(t6)
    5098:	lw	a5,520(a3) # ffb20208 <__fw_export_ldm_end+0x1f5d8>
    509c:	bne	a5,a4,5098 <.L21>
    50a0:	fence
    50a4:	lui	a3,0xffb4f
    50a8:	lw	a2,500(a1)
    50ac:	lw	a5,488(a1)
    50b0:	lw	a4,40(a3) # ffb4f028 <__fw_export_ldm_end+0x4e3f8>
    50b4:	add	a5,a5,a2
    50b8:	lw	t5,484(a1)
    50bc:	addi	a4,a4,1
    50c0:	sw	a5,500(a1)
    50c4:	sw	a4,40(a3)
    50c8:	lw	a2,496(a1)
    50cc:	bne	a5,t5,50dc <.L22>
    50d0:	lw	a4,480(a1)
    50d4:	sub	a5,a5,a4
    50d8:	sw	a5,500(a1)
    50dc:	li	a5,2
    50e0:	sw	a5,0(s2)
    50e4:	lw	a3,496(a1)
    50e8:	lui	a4,0xffb20
    50ec:	lw	a5,64(a4) # ffb20040 <__fw_export_ldm_end+0x1f410>
    50f0:	bnez	a5,50ec <.L23>
    50f4:	lui	a5,0x8
    50f8:	addi	a5,a5,498 # 81f2 <.LASF1532+0x11>
    50fc:	sw	a5,28(a4)
    5100:	sw	a3,0(a4)
    5104:	lui	a3,0x10000
    5108:	sw	a2,12(a4)
    510c:	slli	a5,t3,0x8
    5110:	and	a0,a0,a3
    5114:	sw	a0,16(a4)
    5118:	srli	a5,a5,0x8
    511c:	sw	a5,20(a4)
    5120:	lui	a5,0x1
    5124:	sw	a5,32(a4)
    5128:	li	a5,1
    512c:	sw	a5,64(a4)
    5130:	lw	a4,0(a7)
    5134:	lw	a5,0(a6)
    5138:	addi	a4,a4,1
    513c:	addi	a5,a5,31 # 101f <.LVUS318>
    5140:	sw	a4,0(a7)
    5144:	sw	a5,0(a6)
    5148:	lui	a4,0xffb21
    514c:	lw	a5,64(a4) # ffb21040 <__fw_export_ldm_end+0x20410>
    5150:	bnez	a5,514c <.L24>
    5154:	lui	a5,0x8
    5158:	addi	a5,a5,434 # 81b2 <.LASF1233+0x9>
    515c:	sw	a5,28(a4)
    5160:	sw	s2,0(a4)
    5164:	sw	s2,12(a4)
    5168:	sw	t4,16(a4)
    516c:	sw	t1,20(a4)
    5170:	li	a5,4
    5174:	sw	a5,32(a4)
    5178:	li	a5,1
    517c:	sw	a5,64(a4)
    5180:	lw	a5,0(a7)
    5184:	lw	a4,0(a6)
    5188:	addi	a5,a5,1
    518c:	addi	a4,a4,31
    5190:	sw	a5,0(a7)
    5194:	sw	a4,0(a6)
    5198:	lui	a3,0xffb20
    519c:	lw	a5,516(a3) # ffb20204 <__fw_export_ldm_end+0x1f5d4>
    51a0:	bne	a5,a4,519c <.L25>
    51a4:	fence
    51a8:	lw	ra,300(sp)
    51ac:	lw	s0,296(sp)
    51b0:	lw	s1,292(sp)
    51b4:	lw	s2,288(sp)
    51b8:	lw	s3,284(sp)
    51bc:	lw	s4,280(sp)
    51c0:	lw	s5,276(sp)
    51c4:	lw	s6,272(sp)
    51c8:	lw	s7,268(sp)
    51cc:	lw	s8,264(sp)
    51d0:	lw	s9,260(sp)
    51d4:	addi	sp,sp,304
    51d8:	ret
    51dc:	lw	a3,416(a1)
    51e0:	sub	a4,a4,a3
    51e4:	sw	a4,436(a1)
    51e8:	j	4ef0 <.L11>
000051ec <memset>:
    51ec:	li	t1,15
    51f0:	mv	a4,a0
    51f4:	bgeu	t1,a2,5230 <.Ltiny>
    51f8:	andi	a5,a4,15
    51fc:	bnez	a5,529c <.Lmisaligned>
    5200:	bnez	a1,5284 <.Lwordify>
    5204:	andi	a3,a2,-16
    5208:	andi	a2,a2,15
    520c:	add	a3,a3,a4
    5210:	sw	a1,0(a4)
    5214:	sw	a1,4(a4)
    5218:	sw	a1,8(a4)
    521c:	sw	a1,12(a4)
    5220:	addi	a4,a4,16
    5224:	bltu	a4,a3,5210 <.L1^B1>
    5228:	bnez	a2,5230 <.Ltiny>
    522c:	ret
    5230:	sub	a3,t1,a2
    5234:	slli	a3,a3,0x2
    5238:	auipc	t0,0x0
    523c:	add	a3,a3,t0
    5240:	jr	12(a3)
    5244:	sb	a1,14(a4)
    5248:	sb	a1,13(a4)
    524c:	sb	a1,12(a4)
    5250:	sb	a1,11(a4)
    5254:	sb	a1,10(a4)
    5258:	sb	a1,9(a4)
    525c:	sb	a1,8(a4)
    5260:	sb	a1,7(a4)
    5264:	sb	a1,6(a4)
    5268:	sb	a1,5(a4)
    526c:	sb	a1,4(a4)
    5270:	sb	a1,3(a4)
    5274:	sb	a1,2(a4)
    5278:	sb	a1,1(a4)
    527c:	sb	a1,0(a4)
    5280:	ret
    5284:	zext.b	a1,a1
    5288:	slli	a3,a1,0x8
    528c:	or	a1,a1,a3
    5290:	slli	a3,a1,0x10
    5294:	or	a1,a1,a3
    5298:	j	5204 <.Lwordified>
    529c:	slli	a3,a5,0x2
    52a0:	auipc	t0,0x0
    52a4:	add	a3,a3,t0
    52a8:	mv	t0,ra
    52ac:	jalr	-96(a3)
    52b0:	mv	ra,t0
    52b4:	addi	a5,a5,-16
    52b8:	sub	a4,a4,a5
    52bc:	add	a2,a2,a5
    52c0:	bgeu	t1,a2,5230 <.Ltiny>
    52c4:	j	5200 <.Laligned>

######## NCRISC (reader) — kernel=reader_unary_sharded ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/reader_unary_sharded/4859178969368393331/ncrisc/ncrisc.elf:     file format elf32-littleriscv
00005f80 <_start>:
    5f80:	lui	a5,0xffb01
    5f84:	addi	a5,a5,-976 # ffb00c30 <__fw_export_ldm_end+0x10>
    5f88:	addi	a4,gp,1072 # ffb00c20 <__fw_export_ldm_end>
    5f8c:	bltu	a4,a5,5fa8 <.L2>
    5f90:	sw	zero,-4(a5)
    5f94:	sw	zero,-8(a5)
    5f98:	sw	zero,-12(a5)
    5f9c:	sw	zero,-16(a5)
    5fa0:	addi	a5,a5,16
    5fa4:	bgeu	a4,a5,5f90 <.L3>
    5fa8:	addi	a3,a5,-8
    5fac:	bltu	a4,a3,60bc <.L15>
    5fb0:	sw	zero,-12(a5)
    5fb4:	sw	zero,-16(a5)
    5fb8:	addi	a3,a5,-4
    5fbc:	bltu	a4,a3,5fc4 <.L5>
    5fc0:	sw	zero,-8(a5)
    5fc4:	lui	a4,0x6
    5fc8:	addi	a4,a4,196 # 60c4 <__kernel_data_lma>
    5fcc:	addi	a5,gp,1072 # ffb00c20 <__fw_export_ldm_end>
    5fd0:	beq	a4,a5,6030 <.L7>
    5fd4:	addi	a2,gp,1072 # ffb00c20 <__fw_export_ldm_end>
    5fd8:	sub	a2,a2,a5
    5fdc:	li	a1,8
    5fe0:	srai	a3,a2,0x2
    5fe4:	bge	a1,a2,6014 <.L8>
    5fe8:	li	a6,2
    5fec:	lw	a0,0(a4)
    5ff0:	lw	a1,4(a4)
    5ff4:	lw	a2,8(a4)
    5ff8:	addi	a4,a4,12
    5ffc:	addi	a5,a5,12
    6000:	addi	a3,a3,-3
    6004:	sw	a0,-12(a5)
    6008:	sw	a1,-8(a5)
    600c:	sw	a2,-4(a5)
    6010:	blt	a6,a3,5fec <.L9>
    6014:	blez	a3,6030 <.L7>
    6018:	lw	a1,0(a4)
    601c:	li	a2,2
    6020:	sw	a1,0(a5)
    6024:	bne	a3,a2,6030 <.L7>
    6028:	lw	a4,4(a4)
    602c:	sw	a4,4(a5)
    6030:	lui	a5,0xffb20
    6034:	lw	a4,520(a5) # ffb20208 <__fw_export_ldm_end+0x1f5e8>
    6038:	lw	a4,552(a5)
    603c:	lw	a4,516(a5)
    6040:	lw	a4,512(a5)
    6044:	lw	a5,556(a5)
    6048:	lw	a4,1056(zero) # 420 <.LASF1474+0x4>
    604c:	li	a3,128
    6050:	slli	a4,a4,0x2
    6054:	lbu	a5,1011(a4)
    6058:	addi	a4,a4,96
    605c:	beq	a5,a3,606c <.L11>
    6060:	fence
    6064:	lbu	a5,915(a4)
    6068:	bne	a5,a3,6060 <.L12>
    606c:	lw	a5,-1976(gp) # ffb00038 <rta_l1_base>
    6070:	lui	a4,0xffb00
    6074:	lw	a3,0(a5)
    6078:	addi	a4,a4,1044 # ffb00414 <cb_interface>
    607c:	lw	a5,8(a4)
    6080:	lw	a0,20(a4)
    6084:	lui	a2,0xffb40
    6088:	lw	a6,40(a2) # ffb40028 <__fw_export_ldm_end+0x3f408>
    608c:	lw	a1,4(a4)
    6090:	mul	a5,a3,a5
    6094:	add	a3,a3,a6
    6098:	add	a5,a5,a0
    609c:	sw	a5,20(a4)
    60a0:	sw	a3,40(a2)
    60a4:	bne	a5,a1,60b4 <.L13>
    60a8:	lw	a3,0(a4)
    60ac:	sub	a5,a5,a3
    60b0:	sw	a5,20(a4)
    60b4:	li	a0,0
    60b8:	ret
    60bc:	mv	a5,a3
    60c0:	j	5fb8 <.L4>

######## TRISC0 (unpack) — kernel=layernorm_sharded ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/layernorm_sharded/11767331005058292109/trisc0/trisc0.elf:     file format elf32-littleriscv
00006930 <_start>:
    6930:	addi	sp,sp,-64
    6934:	sw	s0,60(sp)
    6938:	sw	s1,56(sp)
    693c:	sw	s2,52(sp)
    6940:	lui	a5,0xffb01
    6944:	lui	a4,0xffb01
    6948:	addi	a5,a5,-2000 # ffb00830 <__stack_base>
    694c:	addi	a4,a4,-2012 # ffb00824 <__ldm_bss_end>
    6950:	bltu	a4,a5,696c <.L2>
    6954:	sw	zero,-4(a5)
    6958:	sw	zero,-8(a5)
    695c:	sw	zero,-12(a5)
    6960:	sw	zero,-16(a5)
    6964:	addi	a5,a5,16
    6968:	bgeu	a4,a5,6954 <.L3>
    696c:	addi	a3,a5,-8
    6970:	bltu	a4,a3,77c0 <.L89>
    6974:	sw	zero,-12(a5)
    6978:	sw	zero,-16(a5)
    697c:	addi	a3,a5,-4
    6980:	bltu	a4,a3,6988 <.L5>
    6984:	sw	zero,-8(a5)
    6988:	lui	a4,0x7
    698c:	addi	a4,a4,1992 # 77c8 <__kernel_data_lma>
    6990:	addi	a5,gp,48 # ffb00820 <unp_cfg_context>
    6994:	beq	a4,a5,69f4 <.L7>
    6998:	addi	a2,gp,48 # ffb00820 <unp_cfg_context>
    699c:	sub	a2,a2,a5
    69a0:	li	a1,8
    69a4:	srai	a3,a2,0x2
    69a8:	bge	a1,a2,69d8 <.L8>
    69ac:	li	a6,2
    69b0:	lw	a0,0(a4)
    69b4:	lw	a1,4(a4)
    69b8:	lw	a2,8(a4)
    69bc:	addi	a4,a4,12
    69c0:	addi	a5,a5,12
    69c4:	addi	a3,a3,-3
    69c8:	sw	a0,-12(a5)
    69cc:	sw	a1,-8(a5)
    69d0:	sw	a2,-4(a5)
    69d4:	blt	a6,a3,69b0 <.L9>
    69d8:	blez	a3,69f4 <.L7>
    69dc:	lw	a1,0(a4)
    69e0:	li	a2,2
    69e4:	sw	a1,0(a5)
    69e8:	bne	a3,a2,69f4 <.L7>
    69ec:	lw	a4,4(a4)
    69f0:	sw	a4,4(a5)
    69f4:	lui	a5,0xffb12
    69f8:	sw	zero,104(a5) # ffb12068 <__stack_base+0x11838>
    69fc:	lw	a4,1056(zero) # 420 <.LLRL602+0x4>
    6a00:	li	a3,128
    6a04:	slli	a4,a4,0x2
    6a08:	lbu	a5,1011(a4)
    6a0c:	addi	a4,a4,96
    6a10:	beq	a5,a3,6a20 <.L14>
    6a14:	fence
    6a18:	lbu	a5,915(a4)
    6a1c:	bne	a5,a3,6a14 <.L11>
    6a20:	ttzerosrc	0,0,1,3
    6a24:	lw	a5,-2012(gp) # ffb00014 <rta_l1_base>
    6a28:	li	s1,1
    6a2c:	lw	a4,12(a5)
    6a30:	sw	s1,4(sp)
    6a34:	li	a3,2
    6a38:	sw	a3,8(sp)
    6a3c:	lw	a0,0(a5)
    6a40:	lw	t0,4(a5)
    6a44:	beq	a4,s1,77a8 <.L155>
    6a48:	lw	s0,8(a5)
    6a4c:	li	t5,8
    6a50:	bne	s0,s1,77b8 <.L92>
    6a54:	li	s1,0
    6a58:	lui	a2,0xffb00
    6a5c:	addi	a2,a2,32 # ffb00020 <cb_interface>
    6a60:	lw	a3,8(a2)
    6a64:	lui	a4,0xffe80
    6a68:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    6a6c:	zext.b	a5,a5
    6a70:	bnez	a5,6a68 <.L15>
    6a74:	ttsetadcxy	3,0,0,0,0,11
    6a78:	ttsetadczw	3,0,0,0,0,15
    6a7c:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6a80:	lui	a5,0xffef0
    6a84:	beqz	a4,6a8c <.L16>
    6a88:	addi	a5,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    6a8c:	li	a4,512
    6a90:	sw	a4,228(a5)
    6a94:	sw	a4,236(a5)
    6a98:	ttatgetm	0
    6a9c:	lui	a6,0xffe40
    6aa0:	mv	a6,a6
    6aa4:	lui	a4,0xb3ff0
    6aa8:	sw	a4,0(a6) # ffe40000 <__instrn_buffer>
    6aac:	lui	a4,0xb47f0
    6ab0:	sw	a4,0(a6)
    6ab4:	lui	a4,0xb3070
    6ab8:	addi	a4,a4,1 # b3070001 <__device_print_strings_info_end+0xacb70001>
    6abc:	sw	a4,0(a6)
    6ac0:	lui	a4,0xb4800
    6ac4:	addi	a4,a4,1 # b4800001 <__device_print_strings_info_end+0xae300001>
    6ac8:	sw	a4,0(a6)
    6acc:	lui	a4,0xb5010
    6ad0:	addi	a4,a4,1 # b5010001 <__device_print_strings_info_end+0xaeb10001>
    6ad4:	sw	a4,0(a6)
    6ad8:	lui	a4,0xb3010
    6adc:	addi	a4,a4,2 # b3010002 <__device_print_strings_info_end+0xacb10002>
    6ae0:	sw	a4,0(a6)
    6ae4:	lui	a4,0xb5400
    6ae8:	addi	a1,a4,71 # b5400047 <__device_print_strings_info_end+0xaef00047>
    6aec:	sw	a1,0(a6)
    6af0:	addi	a4,a4,119
    6af4:	sw	a4,0(a6)
    6af8:	ttatrelm	0
    6afc:	li	a4,21
    6b00:	sw	a4,256(a5)
    6b04:	lui	a4,0x40
    6b08:	addi	a4,a4,1 # 40001 <.LASF142+0x3431f>
    6b0c:	lui	a1,0x1000
    6b10:	sw	a4,260(a5)
    6b14:	addi	a7,a1,21 # 1000015 <.LASF142+0xff4333>
    6b18:	sw	a7,448(a5)
    6b1c:	sw	a4,452(a5)
    6b20:	li	a7,37
    6b24:	lui	a4,0xf0
    6b28:	sw	a7,288(a5)
    6b2c:	addi	a4,a4,15 # f000f <.LASF142+0xe432d>
    6b30:	sw	a4,292(a5)
    6b34:	sw	a7,480(a5)
    6b38:	sw	a4,484(a5)
    6b3c:	lui	a4,0x5e240
    6b40:	addi	a4,a4,-1024 # 5e23fc00 <__device_print_strings_info_end+0x57d3fc00>
    6b44:	sw	a4,0(a6)
    6b48:	lui	a4,0x5e440
    6b4c:	addi	a4,a4,-1024 # 5e43fc00 <__device_print_strings_info_end+0x57f3fc00>
    6b50:	lui	a7,0x400
    6b54:	sw	a4,0(a6)
    6b58:	addi	a7,a7,64 # 400040 <.LASF142+0x3f435e>
    6b5c:	sw	a7,336(a5)
    6b60:	addi	t1,a1,256
    6b64:	sw	t1,344(a5)
    6b68:	lui	a4,0xffe00
    6b6c:	sw	t1,160(a4) # ffe000a0 <__stack_base+0x2ff870>
    6b70:	lui	t1,0x800
    6b74:	addi	t1,t1,128 # 800080 <.LASF142+0x7f439e>
    6b78:	sw	t1,164(a4)
    6b7c:	sw	a7,168(a4)
    6b80:	lui	a7,0x200
    6b84:	addi	a7,a7,32 # 200020 <.LASF142+0x1f433e>
    6b88:	sw	a7,172(a4)
    6b8c:	lui	a7,0x100
    6b90:	addi	a7,a7,16 # 100010 <.LASF142+0xf432e>
    6b94:	sw	a7,176(a4)
    6b98:	sw	zero,12(sp)
    6b9c:	lw	a4,176(a4)
    6ba0:	sw	a4,12(sp)
    6ba4:	ttsetc16	5,4
    6ba8:	li	a4,256
    6bac:	sw	a4,200(a5)
    6bb0:	sw	zero,48(gp) # ffb00820 <unp_cfg_context>
    6bb4:	ttsetc16	41,0
    6bb8:	lui	a4,0x45000
    6bbc:	slli	a5,a3,0x8
    6bc0:	addi	a1,a1,-256
    6bc4:	and	a5,a5,a1
    6bc8:	addi	a3,a4,72 # 45000048 <__device_print_strings_info_end+0x3eb00048>
    6bcc:	add	a3,a5,a3
    6bd0:	addi	a4,a4,74
    6bd4:	sw	a3,0(a6)
    6bd8:	add	a5,a5,a4
    6bdc:	lui	s2,0xb4010
    6be0:	sw	a5,0(a6)
    6be4:	addi	s2,s2,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    6be8:	sw	s2,0(a6)
    6bec:	ttsetadcxx	3,255,0
    6bf0:	li	a1,0
    6bf4:	lui	t4,0xffe80
    6bf8:	addi	t4,t4,8 # ffe80008 <__instrn_buffer+0x40008>
    6bfc:	mv	a5,a1
    6c00:	sw	a5,0(t4)
    6c04:	lw	a5,0(t4)
    6c08:	and	zero,zero,a5
    6c0c:	lui	a5,0xffb80
    6c10:	li	t3,2
    6c14:	sw	t3,0(a5) # ffb80000 <__stack_base+0x7f7d0>
    6c18:	sw	t3,4(a5)
    6c1c:	lui	a3,0x2000
    6c20:	sw	a3,8(a5)
    6c24:	sw	a3,12(a5)
    6c28:	lui	t1,0x42008
    6c2c:	sw	a3,16(a5)
    6c30:	addi	t1,t1,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    6c34:	lui	a4,0x42808
    6c38:	sw	t1,20(a5)
    6c3c:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    6c40:	sw	a4,24(a5)
    6c44:	sw	a4,28(a5)
    6c48:	sw	a4,32(a5)
    6c4c:	lw	t6,8(sp)
    6c50:	sw	s2,0(a6)
    6c54:	ttsetadcxx	3,255,0
    6c58:	sw	a1,0(t4)
    6c5c:	lw	a1,0(t4)
    6c60:	and	zero,zero,a1
    6c64:	sw	t3,0(a5)
    6c68:	sw	t3,4(a5)
    6c6c:	sw	a3,8(a5)
    6c70:	sw	a3,12(a5)
    6c74:	sw	a3,16(a5)
    6c78:	sw	t1,20(a5)
    6c7c:	sw	a4,24(a5)
    6c80:	sw	a4,28(a5)
    6c84:	sw	a4,32(a5)
    6c88:	beqz	t6,6cfc <.L17>
    6c8c:	lw	a3,16(a2)
    6c90:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6c94:	lui	a5,0xffef0
    6c98:	lw	t4,8(a2)
    6c9c:	addi	a3,a3,-1 # 1ffffff <.LASF142+0x1ff431d>
    6ca0:	addi	t3,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    6ca4:	beqz	a4,7764 <.L156>
    6ca8:	lw	t1,48(gp) # ffb00820 <unp_cfg_context>
    6cac:	li	a1,0
    6cb0:	lui	a4,0xffe80
    6cb4:	li	s2,1
    6cb8:	ttsetadczw	3,0,0,0,0,15
    6cbc:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    6cc0:	andi	a5,a5,254
    6cc4:	bnez	a5,6cbc <.L20>
    6cc8:	bnez	t1,75e0 <.L21>
    6ccc:	sw	a3,304(t3)
    6cd0:	sw	a3,496(t3)
    6cd4:	sw	zero,52(a4)
    6cd8:	ttstallwait	8,1024
    6cdc:	ttmop	1,0,0
    6ce0:	ttsemget	32
    6ce4:	li	t1,1
    6ce8:	ttsetc16	41,257
    6cec:	addi	a1,a1,1
    6cf0:	add	a3,a3,t4
    6cf4:	bne	t6,a1,6cb8 <.L25>
    6cf8:	sw	t1,48(gp) # ffb00820 <unp_cfg_context>
    6cfc:	lw	a5,776(a2)
    6d00:	ttstallwait	128,2
    6d04:	lui	a4,0xb30f0
    6d08:	addi	a1,a4,64 # b30f0040 <__device_print_strings_info_end+0xacbf0040>
    6d0c:	lui	a3,0x1000
    6d10:	sw	a1,0(a6)
    6d14:	addi	a3,a3,-256 # ffff00 <.LASF142+0xff421e>
    6d18:	slli	a5,a5,0x8
    6d1c:	lui	a1,0xb5400
    6d20:	addi	a1,a1,71 # b5400047 <__device_print_strings_info_end+0xaef00047>
    6d24:	and	a5,a5,a3
    6d28:	lui	a3,0x45000
    6d2c:	sw	a1,0(a6)
    6d30:	addi	a3,a3,72 # 45000048 <__device_print_strings_info_end+0x3eb00048>
    6d34:	addi	a4,a4,1096
    6d38:	sw	a4,0(a6)
    6d3c:	add	a5,a5,a3
    6d40:	sw	a5,0(a6)
    6d44:	lhu	a1,792(a2)
    6d48:	lui	a3,0xffb58
    6d4c:	li	a4,1
    6d50:	lw	a5,40(a3) # ffb58028 <__stack_base+0x577f8>
    6d54:	sub	a5,a5,a1
    6d58:	zext.h	a5,a5
    6d5c:	bgeu	a4,a5,6d50 <.L26>
    6d60:	lhu	a3,88(a2)
    6d64:	lui	a4,0xffb42
    6d68:	lw	a5,40(a4) # ffb42028 <__stack_base+0x417f8>
    6d6c:	zext.h	a5,a5
    6d70:	beq	a5,a3,6d68 <.L27>
    6d74:	lui	a5,0x1
    6d78:	addi	a5,a5,-2048 # 800 <.LVUS109>
    6d7c:	lui	a4,0xffb12
    6d80:	sw	a5,104(a4) # ffb12068 <__stack_base+0x11838>
    6d84:	lui	a5,0xb3010
    6d88:	addi	a5,a5,258 # b3010102 <__device_print_strings_info_end+0xacb10102>
    6d8c:	sw	a5,0(a6)
    6d90:	lui	a5,0xb4010
    6d94:	addi	a5,a5,328 # b4010148 <__device_print_strings_info_end+0xadb10148>
    6d98:	sw	a5,0(a6)
    6d9c:	ttsetadcxx	1,255,0
    6da0:	ttsetadcxx	2,15,0
    6da4:	ttreplay	0,2,0,1
    6da8:	ttunpacr	0,1,0,0,0,1,1,0,0,0,0,0,1
    6dac:	ttunpacr	1,1,0,0,0,1,1,0,0,0,0,0,1
    6db0:	lui	a4,0xffe80
    6db4:	li	a5,0
    6db8:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    6dbc:	sw	a5,0(a4)
    6dc0:	lw	a5,0(a4)
    6dc4:	and	zero,zero,a5
    6dc8:	lui	a5,0xffb80
    6dcc:	li	a4,1
    6dd0:	sw	a4,0(a5) # ffb80000 <__stack_base+0x7f7d0>
    6dd4:	li	a4,4
    6dd8:	sw	a4,4(a5)
    6ddc:	lui	a3,0x2000
    6de0:	sw	a3,8(a5)
    6de4:	sw	a3,12(a5)
    6de8:	lui	a4,0x4000
    6dec:	sw	a3,16(a5)
    6df0:	addi	a4,a4,32 # 4000020 <.LASF142+0x3ff433e>
    6df4:	sw	a4,20(a5)
    6df8:	sw	a3,24(a5)
    6dfc:	sw	a4,28(a5)
    6e00:	sw	a4,32(a5)
    6e04:	beqz	a0,6e84 <.L28>
    6e08:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6e0c:	lui	a5,0xffef0
    6e10:	addi	t4,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    6e14:	beqz	a4,775c <.L157>
    6e18:	lw	t3,48(gp) # ffb00820 <unp_cfg_context>
    6e1c:	li	a1,0
    6e20:	lui	a4,0xffe80
    6e24:	li	s2,1
    6e28:	lw	a5,784(a2)
    6e2c:	lw	a3,776(a2)
    6e30:	lw	t1,80(a2)
    6e34:	addi	a5,a5,-1
    6e38:	mul	a3,a1,a3
    6e3c:	add	a3,a5,a3
    6e40:	addi	t1,t1,-1
    6e44:	ttsetadczw	3,0,0,0,0,15
    6e48:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    6e4c:	andi	a5,a5,254
    6e50:	bnez	a5,6e48 <.L31>
    6e54:	bnez	t3,7608 <.L158>
    6e58:	sw	a3,304(t4)
    6e5c:	sw	t1,496(t4)
    6e60:	sw	zero,52(a4)
    6e64:	ttstallwait	8,1024
    6e68:	ttmop	1,0,0
    6e6c:	ttsemget	32
    6e70:	li	t3,1
    6e74:	ttsetc16	41,257
    6e78:	addi	a1,a1,1
    6e7c:	bne	a0,a1,6e28 <.L34>
    6e80:	sw	t3,48(gp) # ffb00820 <unp_cfg_context>
    6e84:	lhu	a5,792(a2)
    6e88:	lui	a3,0x45000
    6e8c:	addi	a5,a5,2
    6e90:	zext.h	a5,a5
    6e94:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    6e98:	slli	a4,a5,0x8
    6e9c:	sh	a5,792(a2)
    6ea0:	add	a4,a4,a3
    6ea4:	sw	a4,0(a6)
    6ea8:	lw	a5,776(a2)
    6eac:	ttstallwait	32,6
    6eb0:	lui	a4,0x67116
    6eb4:	lw	a1,784(a2)
    6eb8:	addi	a4,a4,8 # 67116008 <__device_print_strings_info_end+0x60c16008>
    6ebc:	lw	a3,772(a2)
    6ec0:	sh1add	a5,a5,a1
    6ec4:	sw	a4,0(a6)
    6ec8:	sw	a5,784(a2)
    6ecc:	bltu	a5,a3,6edc <.L40>
    6ed0:	lw	a4,768(a2)
    6ed4:	sub	a5,a5,a4
    6ed8:	sw	a5,784(a2)
    6edc:	lui	a5,0x1
    6ee0:	addi	a5,a5,-2048 # 800 <.LVUS109>
    6ee4:	lui	a4,0xffb12
    6ee8:	sw	a5,104(a4) # ffb12068 <__stack_base+0x11838>
    6eec:	lui	a5,0xb3010
    6ef0:	addi	a5,a5,258 # b3010102 <__device_print_strings_info_end+0xacb10102>
    6ef4:	sw	a5,0(a6)
    6ef8:	lui	a5,0xb4010
    6efc:	addi	a5,a5,328 # b4010148 <__device_print_strings_info_end+0xadb10148>
    6f00:	sw	a5,0(a6)
    6f04:	ttsetadcxx	1,255,0
    6f08:	ttsetadcxx	2,15,0
    6f0c:	ttreplay	0,2,0,1
    6f10:	ttunpacr	0,1,0,0,0,1,1,0,0,0,0,0,1
    6f14:	ttunpacr	1,1,0,0,0,1,1,0,0,0,0,0,1
    6f18:	lui	a4,0xffe80
    6f1c:	li	a5,0
    6f20:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    6f24:	sw	a5,0(a4)
    6f28:	lw	a5,0(a4)
    6f2c:	and	zero,zero,a5
    6f30:	lui	a5,0xffb80
    6f34:	li	a4,1
    6f38:	sw	a4,0(a5) # ffb80000 <__stack_base+0x7f7d0>
    6f3c:	li	a4,4
    6f40:	sw	a4,4(a5)
    6f44:	lui	a3,0x2000
    6f48:	sw	a3,8(a5)
    6f4c:	sw	a3,12(a5)
    6f50:	lui	a4,0x4000
    6f54:	sw	a3,16(a5)
    6f58:	addi	a4,a4,32 # 4000020 <.LASF142+0x3ff433e>
    6f5c:	sw	a4,20(a5)
    6f60:	sw	a3,24(a5)
    6f64:	sw	a4,28(a5)
    6f68:	sw	a4,32(a5)
    6f6c:	beqz	t0,70b4 <.L56>
    6f70:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6f74:	lui	a5,0xffef0
    6f78:	sw	s3,48(sp)
    6f7c:	sw	s4,44(sp)
    6f80:	sw	s5,40(sp)
    6f84:	sw	s6,36(sp)
    6f88:	sw	s7,32(sp)
    6f8c:	sw	s8,28(sp)
    6f90:	sw	s9,24(sp)
    6f94:	sw	s10,20(sp)
    6f98:	addi	t1,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    6f9c:	beqz	a4,7754 <.L159>
    6fa0:	lui	s3,0x45000
    6fa4:	lui	s2,0x67113
    6fa8:	lhu	a4,440(a2)
    6fac:	lw	a1,432(a2)
    6fb0:	addi	s3,s3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    6fb4:	addi	s2,s2,1032 # 67113408 <__device_print_strings_info_end+0x60c13408>
    6fb8:	li	s4,0
    6fbc:	lui	t4,0xffb44
    6fc0:	lui	a0,0xffb4d
    6fc4:	lui	a3,0xffe80
    6fc8:	li	t3,1
    6fcc:	li	s5,2
    6fd0:	lhu	s6,152(a2)
    6fd4:	lw	a5,40(t4) # ffb44028 <__stack_base+0x437f8>
    6fd8:	zext.h	a5,a5
    6fdc:	beq	a5,s6,6fd4 <.L45>
    6fe0:	li	s6,0
    6fe4:	lw	a5,40(a0) # ffb4d028 <__stack_base+0x4c7f8>
    6fe8:	zext.h	a5,a5
    6fec:	beq	a5,a4,6fe4 <.L46>
    6ff0:	lw	a4,144(a2)
    6ff4:	addi	a1,a1,-1
    6ff8:	addi	a4,a4,-1
    6ffc:	ttsetadczw	3,0,0,0,0,15
    7000:	lw	a5,52(a3) # ffe80034 <__instrn_buffer+0x40034>
    7004:	andi	a5,a5,254
    7008:	bnez	a5,7000 <.L47>
    700c:	lw	s7,48(gp) # ffb00820 <unp_cfg_context>
    7010:	bnez	s7,7564 <.L48>
    7014:	sw	a1,304(t1)
    7018:	sw	a4,496(t1)
    701c:	sw	zero,52(a3)
    7020:	ttstallwait	8,1024
    7024:	ttmop	1,0,0
    7028:	ttsemget	32
    702c:	sw	t3,48(gp) # ffb00820 <unp_cfg_context>
    7030:	ttsetc16	41,257
    7034:	lhu	s8,440(a2)
    7038:	lw	s7,424(a2)
    703c:	addi	a4,s8,1
    7040:	zext.h	a4,a4
    7044:	slli	a1,a4,0x8
    7048:	add	a1,a1,s3
    704c:	sw	a1,0(a6)
    7050:	sh	a4,440(a2)
    7054:	ttstallwait	32,6
    7058:	lw	a1,432(a2)
    705c:	lw	s9,420(a2)
    7060:	add	a1,s7,a1
    7064:	sw	s2,0(a6)
    7068:	sw	a1,432(a2)
    706c:	bltu	a1,s9,707c <.L51>
    7070:	lw	s10,416(a2)
    7074:	sub	a1,a1,s10
    7078:	sw	a1,432(a2)
    707c:	addi	s6,s6,1
    7080:	bne	s6,t5,6fe4 <.L46>
    7084:	bnez	s0,7514 <.L54>
    7088:	addi	s4,s4,1
    708c:	bne	t0,s4,6fd0 <.L55>
    7090:	bnez	s1,7660 <.L160>
    7094:	lw	s3,48(sp)
    7098:	lw	s4,44(sp)
    709c:	lw	s5,40(sp)
    70a0:	lw	s6,36(sp)
    70a4:	lw	s7,32(sp)
    70a8:	lw	s8,28(sp)
    70ac:	lw	s9,24(sp)
    70b0:	lw	s10,20(sp)
    70b4:	lw	a5,8(a2)
    70b8:	ttstallwait	128,2
    70bc:	lui	a4,0xb30f0
    70c0:	addi	a3,a4,1344 # b30f0540 <__device_print_strings_info_end+0xacbf0540>
    70c4:	lui	a1,0xb5400
    70c8:	sw	a3,0(a6)
    70cc:	lui	a0,0x1000
    70d0:	addi	a3,a1,71 # b5400047 <__device_print_strings_info_end+0xaef00047>
    70d4:	sw	a3,0(a6)
    70d8:	addi	a0,a0,-256 # ffff00 <.LASF142+0xff421e>
    70dc:	lui	a3,0x45000
    70e0:	slli	a5,a5,0x8
    70e4:	addi	t3,a4,1352
    70e8:	and	a5,a5,a0
    70ec:	addi	t1,a3,72 # 45000048 <__device_print_strings_info_end+0x3eb00048>
    70f0:	sw	t3,0(a6)
    70f4:	add	a5,a5,t1
    70f8:	sw	a5,0(a6)
    70fc:	lw	a5,488(a2)
    7100:	ttstallwait	128,4
    7104:	addi	t1,a4,112
    7108:	sw	t1,0(a6)
    710c:	addi	a1,a1,119
    7110:	slli	a5,a5,0x8
    7114:	sw	a1,0(a6)
    7118:	and	a5,a5,a0
    711c:	addi	a3,a3,74
    7120:	addi	a4,a4,1144
    7124:	add	a5,a5,a3
    7128:	sw	a4,0(a6)
    712c:	sw	a5,0(a6)
    7130:	lui	a5,0xb4010
    7134:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    7138:	sw	a5,0(a6)
    713c:	ttsetadcxx	3,255,0
    7140:	lui	a4,0xffe80
    7144:	li	a5,0
    7148:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    714c:	sw	a5,0(a4)
    7150:	lw	a5,0(a4)
    7154:	and	zero,zero,a5
    7158:	lui	a5,0xffb80
    715c:	li	a4,2
    7160:	sw	a4,0(a5) # ffb80000 <__stack_base+0x7f7d0>
    7164:	sw	a4,4(a5)
    7168:	lui	a4,0x42808
    716c:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    7170:	sw	a4,8(a5)
    7174:	lui	a4,0x54400
    7178:	addi	a4,a4,129 # 54400081 <__device_print_strings_info_end+0x4df00081>
    717c:	sw	a4,12(a5)
    7180:	lui	a3,0x42008
    7184:	lui	a4,0x2000
    7188:	sw	a4,16(a5)
    718c:	addi	a3,a3,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    7190:	sw	a3,20(a5)
    7194:	sw	a4,24(a5)
    7198:	sw	a3,28(a5)
    719c:	lhu	a4,504(a2)
    71a0:	sw	a3,32(a5)
    71a4:	lui	a3,0xffb4f
    71a8:	lw	a5,40(a3) # ffb4f028 <__stack_base+0x4e7f8>
    71ac:	zext.h	a5,a5
    71b0:	beq	a4,a5,71a8 <.L42>
    71b4:	lw	t4,8(a2)
    71b8:	lw	t0,16(a2)
    71bc:	beqz	t6,7234 <.L64>
    71c0:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    71c4:	lui	a5,0xffef0
    71c8:	addi	t3,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    71cc:	addi	a0,t0,-1
    71d0:	beqz	a4,7658 <.L161>
    71d4:	lw	t1,48(gp) # ffb00820 <unp_cfg_context>
    71d8:	li	a1,0
    71dc:	lui	a4,0xffe80
    71e0:	li	t5,1
    71e4:	lw	a5,496(a2)
    71e8:	addi	a3,a5,-1
    71ec:	ttsetadczw	3,0,0,0,0,15
    71f0:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    71f4:	andi	a5,a5,254
    71f8:	bnez	a5,71f0 <.L67>
    71fc:	bnez	t1,75b8 <.L68>
    7200:	sw	a0,304(t3)
    7204:	sw	a3,496(t3)
    7208:	sw	zero,52(a4)
    720c:	ttstallwait	8,1024
    7210:	ttmop	1,0,0
    7214:	ttsemget	32
    7218:	li	t1,1
    721c:	ttsetc16	41,257
    7220:	addi	a1,a1,1
    7224:	add	a0,a0,t4
    7228:	bne	t6,a1,71e4 <.L72>
    722c:	lhu	a4,504(a2)
    7230:	sw	t1,48(gp) # ffb00820 <unp_cfg_context>
    7234:	addi	a5,a4,1
    7238:	lui	a3,0x45000
    723c:	zext.h	a5,a5
    7240:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    7244:	slli	a4,a5,0x8
    7248:	sh	a5,504(a2)
    724c:	add	a4,a4,a3
    7250:	sw	a4,0(a6)
    7254:	lw	a5,488(a2)
    7258:	ttstallwait	32,6
    725c:	lw	a3,496(a2)
    7260:	lui	a4,0x67114
    7264:	add	a5,a5,a3
    7268:	addi	a4,a4,-1016 # 67113c08 <__device_print_strings_info_end+0x60c13c08>
    726c:	lw	a3,484(a2)
    7270:	sw	a5,496(a2)
    7274:	sw	a4,0(a6)
    7278:	bltu	a5,a3,7288 <.L73>
    727c:	lw	a4,480(a2)
    7280:	sub	a5,a5,a4
    7284:	sw	a5,496(a2)
    7288:	lhu	a5,24(a2)
    728c:	lui	a3,0x45000
    7290:	addi	a5,a5,2
    7294:	zext.h	a5,a5
    7298:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    729c:	slli	a4,a5,0x8
    72a0:	add	a4,a4,a3
    72a4:	sh	a5,24(a2)
    72a8:	sw	a4,0(a6)
    72ac:	ttstallwait	32,6
    72b0:	lui	a5,0x67110
    72b4:	sh1add	t4,t4,t0
    72b8:	lw	a4,4(a2)
    72bc:	addi	a5,a5,8 # 67110008 <__device_print_strings_info_end+0x60c10008>
    72c0:	sw	t4,16(a2)
    72c4:	sw	a5,0(a6)
    72c8:	bltu	t4,a4,72d8 <.L74>
    72cc:	lw	a5,0(a2)
    72d0:	sub	t4,t4,a5
    72d4:	sw	t4,16(a2)
    72d8:	lhu	a1,792(a2)
    72dc:	lui	a3,0xffb58
    72e0:	li	a4,1
    72e4:	lw	a5,40(a3) # ffb58028 <__stack_base+0x577f8>
    72e8:	sub	a5,a5,a1
    72ec:	zext.h	a5,a5
    72f0:	bgeu	a4,a5,72e4 <.L75>
    72f4:	lw	a5,776(a2)
    72f8:	ttstallwait	128,2
    72fc:	lui	a4,0xb30f0
    7300:	addi	a3,a4,64 # b30f0040 <__device_print_strings_info_end+0xacbf0040>
    7304:	lui	a1,0xb5400
    7308:	sw	a3,0(a6)
    730c:	lui	a0,0x1000
    7310:	addi	a3,a1,71 # b5400047 <__device_print_strings_info_end+0xaef00047>
    7314:	sw	a3,0(a6)
    7318:	addi	a0,a0,-256 # ffff00 <.LASF142+0xff421e>
    731c:	lui	a3,0x45000
    7320:	slli	a5,a5,0x8
    7324:	addi	t3,a4,1096
    7328:	and	a5,a5,a0
    732c:	addi	t1,a3,72 # 45000048 <__device_print_strings_info_end+0x3eb00048>
    7330:	sw	t3,0(a6)
    7334:	add	a5,a5,t1
    7338:	sw	a5,0(a6)
    733c:	lw	a5,168(a2)
    7340:	ttstallwait	128,4
    7344:	addi	t1,a4,1392
    7348:	sw	t1,0(a6)
    734c:	addi	a1,a1,119
    7350:	slli	a5,a5,0x8
    7354:	sw	a1,0(a6)
    7358:	and	a5,a5,a0
    735c:	addi	a3,a3,74
    7360:	addi	a4,a4,1400
    7364:	add	a5,a5,a3
    7368:	sw	a4,0(a6)
    736c:	sw	a5,0(a6)
    7370:	lui	a5,0xb4010
    7374:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    7378:	sw	a5,0(a6)
    737c:	ttsetadcxx	3,255,0
    7380:	lui	a4,0xffe80
    7384:	li	a5,0
    7388:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    738c:	sw	a5,0(a4)
    7390:	lw	a5,0(a4)
    7394:	and	zero,zero,a5
    7398:	lui	a5,0xffb80
    739c:	li	a4,2
    73a0:	sw	a4,0(a5) # ffb80000 <__stack_base+0x7f7d0>
    73a4:	sw	a4,4(a5)
    73a8:	lui	a1,0x2000
    73ac:	lui	a4,0x54400
    73b0:	sw	a1,8(a5)
    73b4:	addi	a4,a4,1 # 54400001 <__device_print_strings_info_end+0x4df00001>
    73b8:	sw	a4,12(a5)
    73bc:	lui	a3,0x42808
    73c0:	sw	a1,16(a5)
    73c4:	addi	a3,a3,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    73c8:	lui	a4,0x42008
    73cc:	sw	a3,20(a5)
    73d0:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    73d4:	sw	a4,24(a5)
    73d8:	lhu	a1,184(a2)
    73dc:	sw	a4,28(a5)
    73e0:	sw	a4,32(a5)
    73e4:	lui	a3,0xffb45
    73e8:	li	a4,1
    73ec:	lw	a5,40(a3) # ffb45028 <__stack_base+0x447f8>
    73f0:	sub	a5,a5,a1
    73f4:	zext.h	a5,a5
    73f8:	bgeu	a4,a5,73ec <.L76>
    73fc:	beqz	t6,7488 <.L77>
    7400:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    7404:	lui	a5,0xffef0
    7408:	addi	t4,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    740c:	beqz	a4,7650 <.L162>
    7410:	lw	t3,48(gp) # ffb00820 <unp_cfg_context>
    7414:	li	a0,0
    7418:	lui	a4,0xffe80
    741c:	li	t5,1
    7420:	lw	a3,776(a2)
    7424:	lw	a1,784(a2)
    7428:	lw	a5,168(a2)
    742c:	mul	a3,a0,a3
    7430:	lw	t1,176(a2)
    7434:	mul	a5,a0,a5
    7438:	addi	a1,a1,-1 # 1ffffff <.LASF142+0x1ff431d>
    743c:	addi	t1,t1,-1
    7440:	add	a1,a3,a1
    7444:	add	a3,a5,t1
    7448:	ttsetadczw	3,0,0,0,0,15
    744c:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    7450:	andi	a5,a5,254
    7454:	bnez	a5,744c <.L80>
    7458:	bnez	t3,7590 <.L81>
    745c:	sw	a1,304(t4)
    7460:	sw	a3,496(t4)
    7464:	sw	zero,52(a4)
    7468:	ttstallwait	8,1024
    746c:	ttmop	1,0,0
    7470:	ttsemget	32
    7474:	li	t3,1
    7478:	ttsetc16	41,257
    747c:	addi	a0,a0,1
    7480:	bne	t6,a0,7420 <.L85>
    7484:	sw	t3,48(gp) # ffb00820 <unp_cfg_context>
    7488:	lhu	a5,792(a2)
    748c:	lui	a3,0x45000
    7490:	addi	a5,a5,2
    7494:	zext.h	a5,a5
    7498:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    749c:	slli	a4,a5,0x8
    74a0:	sh	a5,792(a2)
    74a4:	add	a4,a4,a3
    74a8:	sw	a4,0(a6)
    74ac:	lw	a5,776(a2)
    74b0:	ttstallwait	32,6
    74b4:	lui	a4,0x67116
    74b8:	lw	a1,784(a2)
    74bc:	addi	a4,a4,8 # 67116008 <__device_print_strings_info_end+0x60c16008>
    74c0:	lw	a3,772(a2)
    74c4:	sh1add	a5,a5,a1
    74c8:	sw	a4,0(a6)
    74cc:	sw	a5,784(a2)
    74d0:	bltu	a5,a3,74e0 <.L86>
    74d4:	lw	a4,768(a2)
    74d8:	sub	a5,a5,a4
    74dc:	sw	a5,784(a2)
    74e0:	lhu	a2,536(a2)
    74e4:	lui	a3,0xffb50
    74e8:	li	a4,1
    74ec:	lw	a5,40(a3) # ffb50028 <__stack_base+0x4f7f8>
    74f0:	sub	a5,a5,a2
    74f4:	zext.h	a5,a5
    74f8:	bgeu	a4,a5,74ec <.L87>
    74fc:	lw	s0,60(sp)
    7500:	lw	s1,56(sp)
    7504:	lw	s2,52(sp)
    7508:	li	a0,0
    750c:	addi	sp,sp,64
    7510:	ret
    7514:	lw	s6,40(a0)
    7518:	sub	s6,s6,a4
    751c:	zext.h	s6,s6
    7520:	bgeu	s5,s6,7514 <.L54>
    7524:	addi	s8,s8,4
    7528:	zext.h	a4,s8
    752c:	slli	s6,a4,0x8
    7530:	add	s6,s6,s3
    7534:	sh	a4,440(a2)
    7538:	sw	s6,0(a6)
    753c:	ttstallwait	32,6
    7540:	sh1add	s7,s7,s7
    7544:	add	a1,a1,s7
    7548:	sw	a1,432(a2)
    754c:	sw	s2,0(a6)
    7550:	bltu	a1,s9,7088 <.L53>
    7554:	lw	s6,416(a2)
    7558:	sub	a1,a1,s6
    755c:	sw	a1,432(a2)
    7560:	j	7088 <.L53>
    7564:	sw	a1,308(t1)
    7568:	sw	a4,500(t1)
    756c:	sw	zero,52(a3)
    7570:	ttstallwait	8,1024
    7574:	ttmop	1,0,0
    7578:	ttsemget	32
    757c:	sub	a4,t3,s7
    7580:	sw	a4,48(gp) # ffb00820 <unp_cfg_context>
    7584:	bne	s7,t3,7030 <.L49>
    7588:	ttsetc16	41,0
    758c:	j	7034 <.L50>
    7590:	sw	a1,308(t4)
    7594:	sw	a3,500(t4)
    7598:	sw	zero,52(a4)
    759c:	ttstallwait	8,1024
    75a0:	ttmop	1,0,0
    75a4:	ttsemget	32
    75a8:	bne	t3,t5,7630 <.L83>
    75ac:	ttsetc16	41,0
    75b0:	li	t3,0
    75b4:	j	747c <.L84>
    75b8:	sw	a0,308(t3)
    75bc:	sw	a3,500(t3)
    75c0:	sw	zero,52(a4)
    75c4:	ttstallwait	8,1024
    75c8:	ttmop	1,0,0
    75cc:	ttsemget	32
    75d0:	bne	t1,t5,7640 <.L70>
    75d4:	ttsetc16	41,0
    75d8:	li	t1,0
    75dc:	j	7220 <.L71>
    75e0:	sw	a3,308(t3)
    75e4:	sw	a3,500(t3)
    75e8:	sw	zero,52(a4)
    75ec:	ttstallwait	8,1024
    75f0:	ttmop	1,0,0
    75f4:	ttsemget	32
    75f8:	bne	t1,s2,7648 <.L23>
    75fc:	ttsetc16	41,0
    7600:	li	t1,0
    7604:	j	6cec <.L24>
    7608:	sw	a3,308(t4)
    760c:	sw	t1,500(t4)
    7610:	sw	zero,52(a4)
    7614:	ttstallwait	8,1024
    7618:	ttmop	1,0,0
    761c:	ttsemget	32
    7620:	bne	t3,s2,7638 <.L163>
    7624:	ttsetc16	41,0
    7628:	li	t3,0
    762c:	j	6e78 <.L36>
    7630:	sub	t3,t5,t3
    7634:	j	7478 <.L82>
    7638:	sub	t3,s2,t3
    763c:	j	6e74 <.L39>
    7640:	sub	t1,t5,t1
    7644:	j	721c <.L69>
    7648:	sub	t1,s2,t1
    764c:	j	6ce8 <.L22>
    7650:	mv	t4,a5
    7654:	j	7410 <.L79>
    7658:	mv	t3,a5
    765c:	j	71d4 <.L66>
    7660:	lui	s2,0xb4010
    7664:	lui	a3,0xffe80
    7668:	lui	s1,0x42008
    766c:	lui	t3,0x42808
    7670:	addi	s2,s2,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    7674:	addi	s3,a3,8 # ffe80008 <__instrn_buffer+0x40008>
    7678:	addi	s1,s1,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    767c:	addi	t3,t3,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    7680:	lui	a0,0xffb4c
    7684:	lui	t1,0xffb80
    7688:	li	t5,2
    768c:	lui	t4,0x2000
    7690:	lui	s4,0xffef0
    7694:	li	s0,1
    7698:	lhu	a1,408(a2)
    769c:	lw	a4,40(a0) # ffb4c028 <__stack_base+0x4b7f8>
    76a0:	zext.h	a4,a4
    76a4:	beq	a4,a1,769c <.L57>
    76a8:	sw	s2,0(a6)
    76ac:	ttsetadcxx	3,255,0
    76b0:	li	a4,0
    76b4:	sw	a4,0(s3)
    76b8:	lw	a4,0(s3)
    76bc:	and	zero,zero,a4
    76c0:	sw	t5,0(t1) # ffb80000 <__stack_base+0x7f7d0>
    76c4:	sw	t5,4(t1)
    76c8:	sw	t4,8(t1)
    76cc:	sw	t4,12(t1)
    76d0:	sw	t4,16(t1)
    76d4:	sw	s1,20(t1)
    76d8:	lw	a1,400(a2)
    76dc:	lw	a4,392(a2)
    76e0:	sw	t3,24(t1)
    76e4:	lw	s5,112(a2)
    76e8:	mul	a4,a5,a4
    76ec:	sw	t3,28(t1)
    76f0:	addi	a1,a1,-1
    76f4:	add	a1,a1,a4
    76f8:	sw	t3,32(t1)
    76fc:	addi	s5,s5,-1
    7700:	ttsetadczw	3,0,0,0,0,15
    7704:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    7708:	lui	s6,0xffef0
    770c:	beqz	a4,7714 <.L59>
    7710:	addi	s6,s4,896 # ffef0380 <__instrn_buffer+0xb0380>
    7714:	lw	a4,52(a3)
    7718:	andi	a4,a4,254
    771c:	bnez	a4,7714 <.L59>
    7720:	lw	a4,48(gp) # ffb00820 <unp_cfg_context>
    7724:	bnez	a4,777c <.L60>
    7728:	sw	a1,304(s6) # ffef0130 <__instrn_buffer+0xb0130>
    772c:	sw	s5,496(s6)
    7730:	sw	zero,52(a3)
    7734:	ttstallwait	8,1024
    7738:	ttmop	1,0,0
    773c:	ttsemget	32
    7740:	sw	s0,48(gp) # ffb00820 <unp_cfg_context>
    7744:	ttsetc16	41,257
    7748:	addi	a5,a5,1
    774c:	bne	t0,a5,7698 <.L63>
    7750:	j	7094 <.L153>
    7754:	mv	t1,a5
    7758:	j	6fa0 <.L44>
    775c:	mv	t4,a5
    7760:	j	6e18 <.L30>
    7764:	lw	t1,48(gp) # ffb00820 <unp_cfg_context>
    7768:	mv	t3,a5
    776c:	li	a1,0
    7770:	lui	a4,0xffe80
    7774:	li	s2,1
    7778:	j	6cb8 <.L25>
    777c:	sw	a1,308(s6)
    7780:	sw	s5,500(s6)
    7784:	sw	zero,52(a3)
    7788:	ttstallwait	8,1024
    778c:	ttmop	1,0,0
    7790:	ttsemget	32
    7794:	sub	a1,s0,a4
    7798:	sw	a1,48(gp) # ffb00820 <unp_cfg_context>
    779c:	bne	a4,s0,7744 <.L61>
    77a0:	ttsetc16	41,0
    77a4:	j	7748 <.L62>
    77a8:	mv	s1,a4
    77ac:	li	t5,11
    77b0:	li	s0,0
    77b4:	j	6a58 <.L12>
    77b8:	li	s0,0
    77bc:	j	6a58 <.L12>
    77c0:	mv	a5,a3
    77c4:	j	697c <.L4>

######## TRISC1 (math) — kernel=layernorm_sharded ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/layernorm_sharded/11767331005058292109/trisc1/trisc1.elf:     file format elf32-littleriscv
00007110 <_start>:
    7110:	addi	sp,sp,-32
    7114:	lui	a5,0xffb00
    7118:	addi	a5,a5,48 # ffb00030 <__fw_export_ldm_end+0x10>
    711c:	addi	a4,gp,-2000 # ffb00020 <__fw_export_ldm_end>
    7120:	bltu	a4,a5,713c <.L4>
    7124:	sw	zero,-4(a5)
    7128:	sw	zero,-8(a5)
    712c:	sw	zero,-12(a5)
    7130:	sw	zero,-16(a5)
    7134:	addi	a5,a5,16
    7138:	bgeu	a4,a5,7124 <.L5>
    713c:	addi	a3,a5,-8
    7140:	bltu	a4,a3,7b30 <.L39>
    7144:	sw	zero,-12(a5)
    7148:	sw	zero,-16(a5)
    714c:	addi	a3,a5,-4
    7150:	bltu	a4,a3,7158 <.L7>
    7154:	sw	zero,-8(a5)
    7158:	lui	a4,0x8
    715c:	addi	a4,a4,-1068 # 7bd4 <__kernel_data_lma>
    7160:	addi	a5,gp,-2000 # ffb00020 <__fw_export_ldm_end>
    7164:	beq	a4,a5,71c4 <.L9>
    7168:	addi	a2,gp,-2000 # ffb00020 <__fw_export_ldm_end>
    716c:	sub	a2,a2,a5
    7170:	li	a1,8
    7174:	srai	a3,a2,0x2
    7178:	bge	a1,a2,71a8 <.L10>
    717c:	li	a6,2
    7180:	lw	a0,0(a4)
    7184:	lw	a1,4(a4)
    7188:	lw	a2,8(a4)
    718c:	addi	a4,a4,12
    7190:	addi	a5,a5,12
    7194:	addi	a3,a3,-3
    7198:	sw	a0,-12(a5)
    719c:	sw	a1,-8(a5)
    71a0:	sw	a2,-4(a5)
    71a4:	blt	a6,a3,7180 <.L11>
    71a8:	blez	a3,71c4 <.L9>
    71ac:	lw	a1,0(a4)
    71b0:	li	a2,2
    71b4:	sw	a1,0(a5)
    71b8:	bne	a3,a2,71c4 <.L9>
    71bc:	lw	a4,4(a4)
    71c0:	sw	a4,4(a5)
    71c4:	lw	a4,1056(zero) # 420 <.LLST78>
    71c8:	li	a3,128
    71cc:	slli	a4,a4,0x2
    71d0:	lbu	a5,1011(a4)
    71d4:	addi	a4,a4,96
    71d8:	beq	a5,a3,71e8 <.L16>
    71dc:	fence
    71e0:	lbu	a5,915(a4)
    71e4:	bne	a5,a3,71dc <.L13>
    71e8:	ttsetc16	13,0
    71ec:	ttsetc16	29,0
    71f0:	ttsetc16	48,0
    71f4:	ttzeroacc	3,0,0,1,0
    71f8:	lw	a5,-2016(gp) # ffb00010 <rta_l1_base>
    71fc:	li	a4,1
    7200:	lw	t4,12(a5)
    7204:	sw	a4,8(sp)
    7208:	li	a3,2
    720c:	sw	a3,12(sp)
    7210:	lw	t5,0(a5)
    7214:	lw	t3,4(a5)
    7218:	li	a6,11
    721c:	beq	t4,a4,7230 <.L14>
    7220:	lw	t4,8(a5)
    7224:	li	a6,8
    7228:	addi	t4,t4,-1
    722c:	snez	t4,t4
    7230:	lui	a3,0xffe80
    7234:	li	a5,0
    7238:	addi	a4,a3,4 # ffe80004 <__instrn_buffer+0x40004>
    723c:	sw	a5,0(a4)
    7240:	lw	a5,0(a4)
    7244:	and	zero,zero,a5
    7248:	lw	a4,36(a3)
    724c:	zext.b	a4,a4
    7250:	bnez	a4,7248 <.L17>
    7254:	ttseminit	2,0,2
    7258:	sw	zero,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    725c:	ttsetc16	1,0
    7260:	lui	a5,0xffe40
    7264:	lui	a2,0xb3080
    7268:	mv	a5,a5
    726c:	addi	a2,a2,220 # b30800dc <__device_print_strings_info_end+0xacb800dc>
    7270:	sw	a2,0(a5) # ffe40000 <__instrn_buffer>
    7274:	ttstallwait	128,16
    7278:	lui	a2,0xb6800
    727c:	addi	a2,a2,1 # b6800001 <__device_print_strings_info_end+0xb0300001>
    7280:	sw	a2,0(a5)
    7284:	lui	a2,0xb6202
    7288:	addi	a2,a2,1 # b6202001 <__device_print_strings_info_end+0xafd02001>
    728c:	sw	a2,0(a5)
    7290:	lui	a2,0xb6404
    7294:	addi	a2,a2,1 # b6404001 <__device_print_strings_info_end+0xaff04001>
    7298:	sw	a2,0(a5)
    729c:	lw	a7,12(sp)
    72a0:	ttsetc16	12,2056
    72a4:	ttsetc16	28,8
    72a8:	ttsetc16	47,0
    72ac:	ttsetc16	13,0
    72b0:	ttsetc16	29,0
    72b4:	ttsetc16	48,0
    72b8:	ttsetc16	14,32896
    72bc:	ttsetc16	30,9216
    72c0:	ttsetc16	49,0
    72c4:	ttsetc16	15,32896
    72c8:	ttsetc16	31,36872
    72cc:	ttsetc16	50,0
    72d0:	addi	a3,a3,8
    72d4:	sw	a4,0(a3)
    72d8:	lw	a4,0(a3)
    72dc:	and	zero,zero,a4
    72e0:	lui	a4,0xffb80
    72e4:	li	a3,2
    72e8:	sw	a3,0(a4) # ffb80000 <__global_pointer$+0x7f810>
    72ec:	sw	a3,4(a4)
    72f0:	lui	a3,0x2000
    72f4:	sw	a3,8(a4)
    72f8:	sw	a3,12(a4)
    72fc:	sw	a3,16(a4)
    7300:	lui	a2,0x27000
    7304:	sw	a2,20(a4)
    7308:	sw	a3,24(a4)
    730c:	lui	a3,0x27c0c
    7310:	sw	a3,28(a4)
    7314:	lui	a3,0x27008
    7318:	sw	a3,32(a4)
    731c:	ttsetc16	7,0
    7320:	ttsetrwc	0,0,0,0,0,15
    7324:	ttsemwait	322,2,2
    7328:	lw	a1,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    732c:	lui	a4,0xb2010
    7330:	snez	a3,a1
    7334:	slli	a3,a3,0x9
    7338:	add	a3,a3,a4
    733c:	li	a2,0
    7340:	beqz	a7,7368 <.L23>
    7344:	sw	a3,0(a5)
    7348:	li	a4,4
    734c:	ttmop	1,0,0
    7350:	addi	a4,a4,-1 # b200ffff <__device_print_strings_info_end+0xabb0ffff>
    7354:	bnez	a4,734c <.L21>
    7358:	ttsetrwc	0,0,0,0,0,4
    735c:	addi	a2,a2,1 # 27000001 <__device_print_strings_info_end+0x20b00001>
    7360:	addi	a3,a3,64 # 27008040 <__device_print_strings_info_end+0x20b08040>
    7364:	bne	a7,a2,7344 <.L22>
    7368:	ttstallwait	2,2064
    736c:	ttsempost	2
    7370:	li	a0,1
    7374:	sub	a4,a0,a1
    7378:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    737c:	ttstallwait	128,2064
    7380:	addi	a4,a1,-1
    7384:	snez	a4,a4
    7388:	lui	t6,0xb2010
    738c:	slli	a4,a4,0x9
    7390:	add	a4,a4,t6
    7394:	sw	a4,0(a5)
    7398:	ttsetc16	12,0
    739c:	ttsetc16	28,32768
    73a0:	ttsetc16	47,0
    73a4:	ttsetc16	13,256
    73a8:	ttsetc16	29,1
    73ac:	ttsetc16	48,0
    73b0:	ttsetc16	14,2048
    73b4:	ttsetc16	30,8
    73b8:	ttsetc16	49,0
    73bc:	ttsetc16	15,0
    73c0:	ttsetc16	31,8192
    73c4:	ttsetc16	50,0
    73c8:	lui	a2,0xffe80
    73cc:	addi	a1,a2,8 # ffe80008 <__instrn_buffer+0x40008>
    73d0:	li	a4,0
    73d4:	sw	a4,0(a1)
    73d8:	lw	a4,0(a1)
    73dc:	and	zero,zero,a4
    73e0:	lui	a4,0xffb80
    73e4:	sw	a0,0(a4) # ffb80000 <__global_pointer$+0x7f810>
    73e8:	li	a1,2
    73ec:	sw	a1,4(a4)
    73f0:	lui	a1,0x2000
    73f4:	sw	a1,8(a4)
    73f8:	sw	a1,12(a4)
    73fc:	sw	a1,16(a4)
    7400:	lui	a0,0x34098
    7404:	sw	a0,20(a4)
    7408:	sw	a1,24(a4)
    740c:	lui	a1,0x34080
    7410:	sw	a1,28(a4)
    7414:	sw	a1,32(a4)
    7418:	ttsetc16	7,0
    741c:	ttsetrwc	0,0,0,0,0,15
    7420:	li	a4,0
    7424:	addi	a2,a2,4
    7428:	sw	a4,0(a2)
    742c:	lw	a4,0(a2)
    7430:	and	zero,zero,a4
    7434:	lui	a4,0x1
    7438:	addi	a4,a4,-2048 # 800 <.LLST158+0x6>
    743c:	lui	a3,0xffb12
    7440:	sw	a4,104(a3) # ffb12068 <__global_pointer$+0x11878>
    7444:	ttsemwait	322,2,2
    7448:	lw	a0,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    744c:	lui	a2,0xb6200
    7450:	snez	a1,a0
    7454:	slli	a1,a1,0x9
    7458:	lui	a3,0xb6202
    745c:	add	a1,a1,t6
    7460:	addi	a2,a2,1 # b6200001 <__device_print_strings_info_end+0xafd00001>
    7464:	addi	a3,a3,1 # b6202001 <__device_print_strings_info_end+0xafd02001>
    7468:	li	a4,0
    746c:	beqz	t5,7528 <.L20>
    7470:	sw	a1,0(a5)
    7474:	ttmop	1,0,0
    7478:	ttcleardvalid	3,0
    747c:	ttmop	1,0,0
    7480:	sw	a2,0(a5)
    7484:	ttmovd2b	0,16,0,0,0
    7488:	tttrnspsrcb
    748c:	ttmovd2b	0,16,0,0,0
    7490:	ttmovb2d	0,16,0,4,0
    7494:	ttmovb2d	0,20,0,4,4
    7498:	ttmovb2d	0,24,0,4,8
    749c:	ttmovb2d	0,28,0,4,12
    74a0:	ttmovd2b	1,16,0,0,0
    74a4:	tttrnspsrcb
    74a8:	ttmovd2b	1,16,0,0,0
    74ac:	ttmovb2d	1,16,0,4,0
    74b0:	ttmovb2d	1,20,0,4,4
    74b4:	ttmovb2d	1,24,0,4,8
    74b8:	ttmovb2d	1,28,0,4,12
    74bc:	sw	a3,0(a5)
    74c0:	ttsetrwc	0,4,8,0,0,4
    74c4:	ttsetrwc	0,4,8,0,0,4
    74c8:	ttsetrwc	0,4,8,0,0,4
    74cc:	ttsetrwc	3,4,8,0,0,6
    74d0:	ttmop	1,0,0
    74d4:	ttcleardvalid	3,0
    74d8:	ttmop	1,0,0
    74dc:	sw	a2,0(a5)
    74e0:	ttmovd2b	0,16,0,0,0
    74e4:	tttrnspsrcb
    74e8:	ttmovd2b	0,16,0,0,0
    74ec:	ttmovb2d	0,16,0,4,0
    74f0:	ttmovb2d	0,20,0,4,4
    74f4:	ttmovb2d	0,24,0,4,8
    74f8:	ttmovb2d	0,28,0,4,12
    74fc:	ttmovd2b	1,16,0,0,0
    7500:	tttrnspsrcb
    7504:	ttmovd2b	1,16,0,0,0
    7508:	ttmovb2d	1,16,0,4,0
    750c:	ttmovb2d	1,20,0,4,4
    7510:	ttmovb2d	1,24,0,4,8
    7514:	ttmovb2d	1,28,0,4,12
    7518:	sw	a3,0(a5)
    751c:	ttsetrwc	3,0,0,0,0,6
    7520:	addi	a4,a4,1
    7524:	bne	t5,a4,7470 <.L26>
    7528:	ttstallwait	2,2064
    752c:	ttsempost	2
    7530:	li	t0,1
    7534:	sub	a4,t0,a0
    7538:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    753c:	ttstallwait	128,2064
    7540:	addi	a4,a0,-1 # 34097fff <__device_print_strings_info_end+0x2db97fff>
    7544:	snez	a4,a4
    7548:	lui	t6,0xb2010
    754c:	slli	a4,a4,0x9
    7550:	add	a4,a4,t6
    7554:	sw	a4,0(a5)
    7558:	ttsetc16	12,0
    755c:	ttsetc16	28,32768
    7560:	ttsetc16	47,0
    7564:	ttsetc16	13,256
    7568:	ttsetc16	29,1
    756c:	ttsetc16	48,0
    7570:	ttsetc16	14,2048
    7574:	ttsetc16	30,8
    7578:	ttsetc16	49,0
    757c:	ttsetc16	15,0
    7580:	ttsetc16	31,8192
    7584:	ttsetc16	50,0
    7588:	lui	a2,0xffe80
    758c:	addi	a1,a2,8 # ffe80008 <__instrn_buffer+0x40008>
    7590:	li	a4,0
    7594:	sw	a4,0(a1) # 34080000 <__device_print_strings_info_end+0x2db80000>
    7598:	lw	a4,0(a1)
    759c:	and	zero,zero,a4
    75a0:	lui	a4,0xffb80
    75a4:	sw	t0,0(a4) # ffb80000 <__global_pointer$+0x7f810>
    75a8:	li	a1,2
    75ac:	sw	a1,4(a4)
    75b0:	lui	a1,0x2000
    75b4:	sw	a1,8(a4)
    75b8:	sw	a1,12(a4)
    75bc:	sw	a1,16(a4)
    75c0:	lui	a0,0x34098
    75c4:	sw	a0,20(a4)
    75c8:	sw	a1,24(a4)
    75cc:	lui	a1,0x34080
    75d0:	sw	a1,28(a4)
    75d4:	sw	a1,32(a4)
    75d8:	ttsetc16	7,0
    75dc:	ttsetrwc	0,0,0,0,0,15
    75e0:	li	a4,0
    75e4:	addi	a2,a2,4
    75e8:	sw	a4,0(a2)
    75ec:	lw	a4,0(a2)
    75f0:	and	zero,zero,a4
    75f4:	lui	a4,0x1
    75f8:	addi	a4,a4,-2048 # 800 <.LLST158+0x6>
    75fc:	lui	a3,0xffb12
    7600:	sw	a4,104(a3) # ffb12068 <__global_pointer$+0x11878>
    7604:	beqz	t3,7728 <.L25>
    7608:	lui	a2,0xb6200
    760c:	lui	a3,0xb6202
    7610:	lw	a0,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7614:	addi	a2,a2,1 # b6200001 <__device_print_strings_info_end+0xafd00001>
    7618:	addi	a3,a3,1 # b6202001 <__device_print_strings_info_end+0xafd02001>
    761c:	li	t5,0
    7620:	ttsemwait	322,2,2
    7624:	snez	a1,a0
    7628:	slli	a1,a1,0x9
    762c:	add	a1,a1,t6
    7630:	li	a4,0
    7634:	sw	a1,0(a5)
    7638:	ttmop	1,0,0
    763c:	ttcleardvalid	3,0
    7640:	ttmop	1,0,0
    7644:	sw	a2,0(a5)
    7648:	ttmovd2b	0,16,0,0,0
    764c:	tttrnspsrcb
    7650:	ttmovd2b	0,16,0,0,0
    7654:	ttmovb2d	0,16,0,4,0
    7658:	ttmovb2d	0,20,0,4,4
    765c:	ttmovb2d	0,24,0,4,8
    7660:	ttmovb2d	0,28,0,4,12
    7664:	ttmovd2b	1,16,0,0,0
    7668:	tttrnspsrcb
    766c:	ttmovd2b	1,16,0,0,0
    7670:	ttmovb2d	1,16,0,4,0
    7674:	ttmovb2d	1,20,0,4,4
    7678:	ttmovb2d	1,24,0,4,8
    767c:	ttmovb2d	1,28,0,4,12
    7680:	sw	a3,0(a5)
    7684:	ttsetrwc	0,4,8,0,0,4
    7688:	ttsetrwc	0,4,8,0,0,4
    768c:	ttsetrwc	0,4,8,0,0,4
    7690:	ttsetrwc	3,4,8,0,0,6
    7694:	ttmop	1,0,0
    7698:	ttcleardvalid	3,0
    769c:	ttmop	1,0,0
    76a0:	sw	a2,0(a5)
    76a4:	ttmovd2b	0,16,0,0,0
    76a8:	tttrnspsrcb
    76ac:	ttmovd2b	0,16,0,0,0
    76b0:	ttmovb2d	0,16,0,4,0
    76b4:	ttmovb2d	0,20,0,4,4
    76b8:	ttmovb2d	0,24,0,4,8
    76bc:	ttmovb2d	0,28,0,4,12
    76c0:	ttmovd2b	1,16,0,0,0
    76c4:	tttrnspsrcb
    76c8:	ttmovd2b	1,16,0,0,0
    76cc:	ttmovb2d	1,16,0,4,0
    76d0:	ttmovb2d	1,20,0,4,4
    76d4:	ttmovb2d	1,24,0,4,8
    76d8:	ttmovb2d	1,28,0,4,12
    76dc:	sw	a3,0(a5)
    76e0:	ttsetrwc	3,0,0,0,0,6
    76e4:	addi	a4,a4,1
    76e8:	bne	a4,a6,7634 <.L29>
    76ec:	ttstallwait	2,2064
    76f0:	ttsempost	2
    76f4:	sub	a1,t0,a0
    76f8:	ttstallwait	128,2064
    76fc:	addi	a4,a0,-1 # 34097fff <__device_print_strings_info_end+0x2db97fff>
    7700:	snez	a4,a4
    7704:	slli	a4,a4,0x9
    7708:	add	a4,a4,t6
    770c:	sw	a4,0(a5)
    7710:	addi	t5,t5,1
    7714:	beq	t3,t5,7720 <.L67>
    7718:	mv	a0,a1
    771c:	j	7620 <.L30>
    7720:	sw	a1,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7724:	bnez	t4,7938 <.L68>
    7728:	ttsetc16	12,2056
    772c:	ttsetc16	28,8
    7730:	ttsetc16	47,0
    7734:	ttsetc16	13,0
    7738:	ttsetc16	29,0
    773c:	ttsetc16	48,0
    7740:	ttsetc16	14,32896
    7744:	ttsetc16	30,9216
    7748:	ttsetc16	49,0
    774c:	ttsetc16	15,32896
    7750:	ttsetc16	31,36872
    7754:	ttsetc16	50,0
    7758:	lui	a3,0xffe80
    775c:	li	a4,0
    7760:	addi	a3,a3,8 # ffe80008 <__instrn_buffer+0x40008>
    7764:	sw	a4,0(a3)
    7768:	lw	a4,0(a3)
    776c:	and	zero,zero,a4
    7770:	lui	a4,0xffb80
    7774:	li	a3,2
    7778:	sw	a3,0(a4) # ffb80000 <__global_pointer$+0x7f810>
    777c:	sw	a3,4(a4)
    7780:	lui	a3,0x2000
    7784:	sw	a3,8(a4)
    7788:	sw	a3,12(a4)
    778c:	sw	a3,16(a4)
    7790:	lui	a2,0x27080
    7794:	sw	a2,20(a4)
    7798:	sw	a3,24(a4)
    779c:	lui	a3,0x2748c
    77a0:	sw	a3,28(a4)
    77a4:	lui	a3,0x27088
    77a8:	sw	a3,32(a4)
    77ac:	ttsetc16	7,0
    77b0:	ttsetrwc	0,0,0,0,0,15
    77b4:	ttsemwait	322,2,2
    77b8:	lw	a2,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    77bc:	lui	a3,0xb2010
    77c0:	snez	a4,a2
    77c4:	slli	a4,a4,0x9
    77c8:	add	a4,a4,a3
    77cc:	li	a3,0
    77d0:	beqz	a7,7800 <.L28>
    77d4:	sw	a4,0(a5)
    77d8:	ttmop	1,0,0
    77dc:	ttmop	1,0,0
    77e0:	ttsetrwc	2,0,0,0,0,0
    77e4:	ttmop	1,0,0
    77e8:	ttmop	1,0,0
    77ec:	ttsetrwc	2,0,0,0,0,0
    77f0:	ttsetrwc	0,0,0,0,0,4
    77f4:	addi	a3,a3,1 # b2010001 <__device_print_strings_info_end+0xabb10001>
    77f8:	addi	a4,a4,64
    77fc:	bne	a7,a3,77d4 <.L33>
    7800:	ttstallwait	2,2064
    7804:	ttsempost	2
    7808:	li	a4,1
    780c:	sub	a4,a4,a2
    7810:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7814:	ttstallwait	128,2064
    7818:	addi	a4,a2,-1 # 2707ffff <__device_print_strings_info_end+0x20b7ffff>
    781c:	snez	a4,a4
    7820:	lui	a0,0xb2010
    7824:	slli	a4,a4,0x9
    7828:	add	a4,a4,a0
    782c:	sw	a4,0(a5)
    7830:	ttsetc16	12,8
    7834:	ttsetc16	28,8
    7838:	ttsetc16	47,0
    783c:	ttsetc16	13,0
    7840:	ttsetc16	29,0
    7844:	ttsetc16	48,0
    7848:	ttsetc16	14,32896
    784c:	ttsetc16	30,9216
    7850:	ttsetc16	49,0
    7854:	ttsetc16	15,32896
    7858:	ttsetc16	31,36872
    785c:	ttsetc16	50,0
    7860:	lui	a3,0xffe80
    7864:	li	a4,0
    7868:	addi	a3,a3,8 # ffe80008 <__instrn_buffer+0x40008>
    786c:	sw	a4,0(a3)
    7870:	lw	a4,0(a3)
    7874:	and	zero,zero,a4
    7878:	lui	a4,0xffb80
    787c:	li	a3,2
    7880:	sw	a3,0(a4) # ffb80000 <__global_pointer$+0x7f810>
    7884:	sw	a3,4(a4)
    7888:	lui	a3,0x2000
    788c:	sw	a3,8(a4)
    7890:	sw	a3,12(a4)
    7894:	sw	a3,16(a4)
    7898:	lui	a2,0x27100
    789c:	sw	a2,20(a4)
    78a0:	sw	a3,24(a4)
    78a4:	lui	a3,0x27d0c
    78a8:	sw	a3,28(a4)
    78ac:	lui	a3,0x27108
    78b0:	sw	a3,32(a4)
    78b4:	ttsetc16	7,0
    78b8:	ttsetrwc	0,0,0,0,0,15
    78bc:	ttsemwait	322,2,2
    78c0:	lw	a1,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    78c4:	li	a2,0
    78c8:	snez	a3,a1
    78cc:	slli	a3,a3,0x9
    78d0:	add	a3,a3,a0
    78d4:	beqz	a7,78fc <.L37>
    78d8:	sw	a3,0(a5)
    78dc:	li	a4,4
    78e0:	ttmop	1,0,0
    78e4:	addi	a4,a4,-1
    78e8:	bnez	a4,78e0 <.L35>
    78ec:	ttsetrwc	0,0,0,0,0,4
    78f0:	addi	a2,a2,1 # 27100001 <__device_print_strings_info_end+0x20c00001>
    78f4:	addi	a3,a3,64 # 27108040 <__device_print_strings_info_end+0x20c08040>
    78f8:	bne	a7,a2,78d8 <.L36>
    78fc:	ttstallwait	2,2064
    7900:	ttsempost	2
    7904:	li	a4,1
    7908:	sub	a4,a4,a1
    790c:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7910:	ttstallwait	128,2064
    7914:	addi	a4,a1,-1 # 3407ffff <__device_print_strings_info_end+0x2db7ffff>
    7918:	snez	a4,a4
    791c:	slli	a4,a4,0x9
    7920:	lui	a3,0xb2010
    7924:	add	a4,a4,a3
    7928:	sw	a4,0(a5)
    792c:	li	a0,0
    7930:	addi	sp,sp,32
    7934:	ret
    7938:	lui	t5,0xffe80
    793c:	lui	a3,0xffb80
    7940:	lui	t4,0x37cc0
    7944:	sw	s0,28(sp)
    7948:	sw	s1,24(sp)
    794c:	addi	t5,t5,8 # ffe80008 <__instrn_buffer+0x40008>
    7950:	addi	s0,a3,12 # ffb8000c <__global_pointer$+0x7f81c>
    7954:	addi	t4,t4,3 # 37cc0003 <__device_print_strings_info_end+0x317c0003>
    7958:	li	a0,0
    795c:	li	t2,4
    7960:	li	t0,2
    7964:	lui	a1,0x2000
    7968:	lui	a2,0x28000
    796c:	lui	a6,0xb2010
    7970:	li	t6,1
    7974:	ttsemwait	322,2,2
    7978:	ttsetc16	12,2056
    797c:	ttsetc16	28,8
    7980:	ttsetc16	47,0
    7984:	ttsetc16	13,0
    7988:	ttsetc16	29,0
    798c:	ttsetc16	48,0
    7990:	ttsetc16	14,32896
    7994:	ttsetc16	30,1024
    7998:	ttsetc16	49,0
    799c:	ttsetc16	15,32896
    79a0:	ttsetc16	31,36872
    79a4:	ttsetc16	50,0
    79a8:	li	a4,0
    79ac:	sw	a4,0(t5)
    79b0:	lw	a4,0(t5)
    79b4:	and	zero,zero,a4
    79b8:	sw	t2,0(a3)
    79bc:	sw	t0,4(a3)
    79c0:	sw	a1,8(a3)
    79c4:	sw	t4,0(s0)
    79c8:	sw	a1,16(a3)
    79cc:	sw	a2,20(a3)
    79d0:	sw	a1,24(a3)
    79d4:	sw	a2,28(a3)
    79d8:	sw	a2,32(a3)
    79dc:	ttsetc16	7,0
    79e0:	ttsetrwc	0,0,0,0,0,15
    79e4:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    79e8:	snez	a4,a4
    79ec:	slli	a4,a4,0x9
    79f0:	add	a4,a4,a6
    79f4:	sw	a4,0(a5)
    79f8:	ttmop	1,0,0
    79fc:	ttsetrwc	0,0,0,0,0,4
    7a00:	sfpconfig	15,0,1
    7a04:	ttsetc16	19,0
    7a08:	ttsetc16	35,0
    7a0c:	ttsetc16	54,0
    7a10:	ttsetrwc	0,0,0,0,0,15
    7a14:	sfploadi	L0,24337,8
    7a18:	sfploadi	L0,4256,10
    7a1c:	sfpconfig	12,0,0
    7a20:	sfploadi	L0,16402,8
    7a24:	sfploadi	L0,5321,10
    7a28:	sfpconfig	13,0,0
    7a2c:	sfploadi	L0,16400,8
    7a30:	sfploadi	L0,13862,10
    7a34:	sfpconfig	14,0,0
    7a38:	sw	a4,0(a5)
    7a3c:	ttstallwait	256,16
    7a40:	li	a4,4
    7a44:	ttreplay	0,30,1,1
    7a48:	sfpload	L1,0,0,7
    7a4c:	sfpshft	L0,L1,0xFFF,5
    7a50:	sfpiadd	L0,L12,0x000,6
    7a54:	sfpmul	L2,L1,L0,L9,0
    7a58:	sfpnop
    7a5c:	sfpmul	L2,L0,L2,L9,1
    7a60:	sfploadi	L3,32640,0
    7a64:	sfpadd	L4,L10,L14,L2,0
    7a68:	sfpnop
    7a6c:	sfpmad	L2,L2,L4,L13,0
    7a70:	sfpnop
    7a74:	sfpmul	L0,L0,L2,L9,0
    7a78:	sfpnop
    7a7c:	sfpmul	L2,L1,L0,L9,0
    7a80:	sfpnop
    7a84:	sfpmad	L2,L0,L2,L10,1
    7a88:	sfpdivp2	L5,L0,0xFFF,1
    7a8c:	sfpmov	L4,L1,2
    7a90:	sfpiadd	L4,L3,0x000,6
    7a94:	sfpsetcc	L4,0x000,2
    7a98:	sfpsetcc	L1,0x000,2
    7a9c:	sfpmad	L0,L2,L5,L0,0
    7aa0:	sfpcompc
    7aa4:	sfpmov	L0,L4,0
    7aa8:	sfpencc	0x003,10
    7aac:	sfpsetcc	L1,0x000,0
    7ab0:	sfploadi	L0,32704,0
    7ab4:	sfpencc	0x003,10
    7ab8:	sfpstore	L0,0,0,7
    7abc:	ttincrwc	0,2,0,0
    7ac0:	ttreplay	0,30,0,0
    7ac4:	ttreplay	0,30,0,0
    7ac8:	ttreplay	0,30,0,0
    7acc:	ttreplay	0,30,0,0
    7ad0:	ttreplay	0,30,0,0
    7ad4:	ttreplay	0,30,0,0
    7ad8:	ttreplay	0,30,0,0
    7adc:	ttsetrwc	0,4,8,0,0,4
    7ae0:	ttsetrwc	0,4,8,0,0,4
    7ae4:	addi	a4,a4,-1
    7ae8:	bnez	a4,7a44 <.L31>
    7aec:	ttsetrwc	0,0,0,0,0,4
    7af0:	ttstallwait	2,2064
    7af4:	ttsempost	2
    7af8:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7afc:	sub	s1,t6,a4
    7b00:	sw	s1,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7b04:	ttstallwait	128,2064
    7b08:	addi	a4,a4,-1
    7b0c:	snez	a4,a4
    7b10:	slli	a4,a4,0x9
    7b14:	add	a4,a4,a6
    7b18:	sw	a4,0(a5)
    7b1c:	addi	a0,a0,1 # b2010001 <__device_print_strings_info_end+0xabb10001>
    7b20:	bne	t3,a0,7974 <.L32>
    7b24:	lw	s0,28(sp)
    7b28:	lw	s1,24(sp)
    7b2c:	j	7728 <.L25>
    7b30:	mv	a5,a3
    7b34:	j	714c <.L6>
00007b38 <_ZN7ckernel4sfpu15calculate_rsqrtILb0ELi8ELb1ELb0ELb0EEEvv>:
    7b38:	ttreplay	0,30,1,1
    7b3c:	sfpload	L1,0,0,7
    7b40:	sfpshft	L0,L1,0xFFF,5
    7b44:	sfpiadd	L0,L12,0x000,6
    7b48:	sfpmul	L2,L1,L0,L9,0
    7b4c:	sfpnop
    7b50:	sfpmul	L2,L0,L2,L9,1
    7b54:	sfploadi	L3,32640,0
    7b58:	sfpadd	L4,L10,L14,L2,0
    7b5c:	sfpnop
    7b60:	sfpmad	L2,L2,L4,L13,0
    7b64:	sfpnop
    7b68:	sfpmul	L0,L0,L2,L9,0
    7b6c:	sfpnop
    7b70:	sfpmul	L2,L1,L0,L9,0
    7b74:	sfpnop
    7b78:	sfpmad	L2,L0,L2,L10,1
    7b7c:	sfpdivp2	L5,L0,0xFFF,1
    7b80:	sfpmov	L4,L1,2
    7b84:	sfpiadd	L4,L3,0x000,6
    7b88:	sfpsetcc	L4,0x000,2
    7b8c:	sfpsetcc	L1,0x000,2
    7b90:	sfpmad	L0,L2,L5,L0,0
    7b94:	sfpcompc
    7b98:	sfpmov	L0,L4,0
    7b9c:	sfpencc	0x003,10
    7ba0:	sfpsetcc	L1,0x000,0
    7ba4:	sfploadi	L0,32704,0
    7ba8:	sfpencc	0x003,10
    7bac:	sfpstore	L0,0,0,7
    7bb0:	ttincrwc	0,2,0,0
    7bb4:	ttreplay	0,30,0,0
    7bb8:	ttreplay	0,30,0,0
    7bbc:	ttreplay	0,30,0,0
    7bc0:	ttreplay	0,30,0,0
    7bc4:	ttreplay	0,30,0,0
    7bc8:	ttreplay	0,30,0,0
    7bcc:	ttreplay	0,30,0,0
    7bd0:	ret

######## TRISC2 (pack) — kernel=layernorm_sharded ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/layernorm_sharded/11767331005058292109/trisc2/trisc2.elf:     file format elf32-littleriscv
00007d10 <_start>:
    7d10:	addi	sp,sp,-80
    7d14:	sw	s0,76(sp)
    7d18:	sw	s1,72(sp)
    7d1c:	sw	s2,68(sp)
    7d20:	sw	s3,64(sp)
    7d24:	sw	s4,60(sp)
    7d28:	sw	s5,56(sp)
    7d2c:	sw	s6,52(sp)
    7d30:	sw	s7,48(sp)
    7d34:	sw	s8,44(sp)
    7d38:	sw	s9,40(sp)
    7d3c:	sw	s10,36(sp)
    7d40:	sw	s11,32(sp)
    7d44:	lui	a5,0xffb01
    7d48:	addi	a5,a5,-2000 # ffb00830 <__fw_export_ldm_end+0x10>
    7d4c:	addi	a4,gp,48 # ffb00820 <__fw_export_ldm_end>
    7d50:	bltu	a4,a5,7d6c <.L2>
    7d54:	sw	zero,-4(a5)
    7d58:	sw	zero,-8(a5)
    7d5c:	sw	zero,-12(a5)
    7d60:	sw	zero,-16(a5)
    7d64:	addi	a5,a5,16
    7d68:	bgeu	a4,a5,7d54 <.L3>
    7d6c:	addi	a3,a5,-8
    7d70:	bltu	a4,a3,895c <.L41>
    7d74:	sw	zero,-12(a5)
    7d78:	sw	zero,-16(a5)
    7d7c:	addi	a3,a5,-4
    7d80:	bltu	a4,a3,7d88 <.L5>
    7d84:	sw	zero,-8(a5)
    7d88:	lui	a4,0x9
    7d8c:	addi	a4,a4,-1692 # 8964 <__kernel_data_lma>
    7d90:	addi	a5,gp,48 # ffb00820 <__fw_export_ldm_end>
    7d94:	beq	a4,a5,7df4 <.L7>
    7d98:	addi	a2,gp,48 # ffb00820 <__fw_export_ldm_end>
    7d9c:	sub	a2,a2,a5
    7da0:	li	a1,8
    7da4:	srai	a3,a2,0x2
    7da8:	bge	a1,a2,7dd8 <.L8>
    7dac:	li	a6,2
    7db0:	lw	a0,0(a4)
    7db4:	lw	a1,4(a4)
    7db8:	lw	a2,8(a4)
    7dbc:	addi	a4,a4,12
    7dc0:	addi	a5,a5,12
    7dc4:	addi	a3,a3,-3
    7dc8:	sw	a0,-12(a5)
    7dcc:	sw	a1,-8(a5)
    7dd0:	sw	a2,-4(a5)
    7dd4:	blt	a6,a3,7db0 <.L9>
    7dd8:	blez	a3,7df4 <.L7>
    7ddc:	lw	a1,0(a4)
    7de0:	li	a2,2
    7de4:	sw	a1,0(a5)
    7de8:	bne	a3,a2,7df4 <.L7>
    7dec:	lw	a4,4(a4)
    7df0:	sw	a4,4(a5)
    7df4:	lw	a4,1056(zero) # 420 <.LVUS90+0x2>
    7df8:	li	a3,128
    7dfc:	slli	a4,a4,0x2
    7e00:	lbu	a5,1011(a4)
    7e04:	addi	a4,a4,96
    7e08:	beq	a5,a3,7e18 <.L13>
    7e0c:	fence
    7e10:	lbu	a5,915(a4)
    7e14:	bne	a5,a3,7e0c <.L11>
    7e18:	lw	a3,-2012(gp) # ffb00014 <rta_l1_base>
    7e1c:	li	a5,1
    7e20:	lw	a2,8(a3)
    7e24:	sw	a5,16(sp)
    7e28:	lw	a5,12(a3)
    7e2c:	lui	a4,0xffb00
    7e30:	li	a0,2
    7e34:	lw	a1,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    7e38:	addi	a4,a4,32 # ffb00020 <cb_interface>
    7e3c:	sw	a0,20(sp)
    7e40:	lw	t1,4(a3)
    7e44:	lw	t5,776(a4)
    7e48:	lui	a3,0xffef0
    7e4c:	addi	a2,a2,-1
    7e50:	seqz	a2,a2
    7e54:	addi	a5,a5,-1
    7e58:	snez	a5,a5
    7e5c:	and	a5,a2,a5
    7e60:	sw	a5,4(sp)
    7e64:	beqz	a1,7e6c <.L12>
    7e68:	addi	a3,a3,896 # ffef0380 <__instrn_buffer+0xb0380>
    7e6c:	lui	a5,0xffe40
    7e70:	lui	t4,0x45000
    7e74:	mv	a5,a5
    7e78:	addi	t4,t4,56 # 45000038 <__device_print_strings_info_end+0x3eb00038>
    7e7c:	lui	t3,0x45004
    7e80:	sw	t4,0(a5) # ffe40000 <__instrn_buffer>
    7e84:	addi	t3,t3,57 # 45004039 <__device_print_strings_info_end+0x3eb04039>
    7e88:	lui	a7,0x45040
    7e8c:	sw	t3,0(a5)
    7e90:	addi	a7,a7,58 # 4504003a <__device_print_strings_info_end+0x3eb4003a>
    7e94:	lui	a6,0x45100
    7e98:	sw	a7,0(a5)
    7e9c:	addi	a6,a6,59 # 4510003b <__device_print_strings_info_end+0x3ec0003b>
    7ea0:	sw	a6,0(a5)
    7ea4:	ttstallwait	128,1
    7ea8:	ttwrcfg	28,0,12
    7eac:	ttwrcfg	29,0,13
    7eb0:	ttnop
    7eb4:	ttnop
    7eb8:	ttatgetm	0
    7ebc:	lui	a2,0xb5800
    7ec0:	addi	a2,a2,71 # b5800047 <__device_print_strings_info_end+0xaf300047>
    7ec4:	sw	a2,0(a5)
    7ec8:	lui	a2,0xb61e0
    7ecc:	addi	a2,a2,1 # b61e0001 <__device_print_strings_info_end+0xafce0001>
    7ed0:	sw	a2,0(a5)
    7ed4:	lui	a2,0xb3fc0
    7ed8:	addi	a2,a2,2 # b3fc0002 <__device_print_strings_info_end+0xadac0002>
    7edc:	sw	a2,0(a5)
    7ee0:	lui	a2,0xb4ff0
    7ee4:	addi	a2,a2,2 # b4ff0002 <__device_print_strings_info_end+0xaeaf0002>
    7ee8:	sw	a2,0(a5)
    7eec:	lui	a2,0xb53f0
    7ef0:	addi	a2,a2,2 # b53f0002 <__device_print_strings_info_end+0xaeef0002>
    7ef4:	sw	a2,0(a5)
    7ef8:	ttatrelm	0
    7efc:	lui	a2,0xb5100
    7f00:	addi	a2,a2,71 # b5100047 <__device_print_strings_info_end+0xaec00047>
    7f04:	sw	a2,0(a5)
    7f08:	lui	a2,0xb6ff0
    7f0c:	addi	a2,a2,71 # b6ff0047 <__device_print_strings_info_end+0xb0af0047>
    7f10:	sw	a2,0(a5)
    7f14:	lui	a0,0x40
    7f18:	sw	a0,272(a3)
    7f1c:	li	a2,1
    7f20:	sw	a2,280(a3)
    7f24:	ttstallwait	128,8
    7f28:	lui	a1,0xb3040
    7f2c:	addi	a1,a1,70 # b3040046 <__device_print_strings_info_end+0xacb40046>
    7f30:	sw	a1,0(a5)
    7f34:	lui	a1,0xb5080
    7f38:	addi	a1,a1,71 # b5080047 <__device_print_strings_info_end+0xaeb80047>
    7f3c:	sw	a1,0(a5)
    7f40:	sw	a2,72(a3)
    7f44:	lui	a1,0xffe00
    7f48:	sw	a0,208(a1) # ffe000d0 <__fw_export_ldm_end+0x2ff8b0>
    7f4c:	sw	zero,28(sp)
    7f50:	lw	t0,208(a1)
    7f54:	lui	t6,0x1
    7f58:	lui	a0,0x10
    7f5c:	addi	a0,a0,-1 # ffff <.LASF142+0x48f6>
    7f60:	sw	t0,28(sp)
    7f64:	sw	t6,112(a3)
    7f68:	sw	a0,96(a3)
    7f6c:	sw	zero,80(a3)
    7f70:	sw	t5,64(a1)
    7f74:	sw	zero,68(a1)
    7f78:	sw	zero,72(a1)
    7f7c:	sw	zero,76(a1)
    7f80:	sw	zero,24(sp)
    7f84:	lw	a3,76(a1)
    7f88:	sw	a3,24(sp)
    7f8c:	ttsetadcxx	4,15,0
    7f90:	ttsetc16	37,260
    7f94:	ttsetc16	38,10272
    7f98:	ttsetc16	39,4384
    7f9c:	lui	a0,0xffe80
    7fa0:	addi	t5,a0,8 # ffe80008 <__instrn_buffer+0x40008>
    7fa4:	li	a3,0
    7fa8:	sw	a3,0(t5)
    7fac:	lw	a3,0(t5)
    7fb0:	and	zero,zero,a3
    7fb4:	lui	a3,0xffb80
    7fb8:	li	t5,4
    7fbc:	sw	t5,0(a3) # ffb80000 <__fw_export_ldm_end+0x7f7e0>
    7fc0:	sw	t5,4(a3)
    7fc4:	lui	t5,0x2000
    7fc8:	sw	t5,8(a3)
    7fcc:	sw	t5,12(a3)
    7fd0:	sw	t5,16(a3)
    7fd4:	lui	t6,0x41000
    7fd8:	sw	t6,20(a3)
    7fdc:	lui	t6,0x41008
    7fe0:	sw	t5,24(a3)
    7fe4:	add	t5,t6,a2
    7fe8:	sw	t5,28(a3)
    7fec:	lui	t5,0x41010
    7ff0:	sw	t5,32(a3)
    7ff4:	sw	t4,0(a5)
    7ff8:	sw	t3,0(a5)
    7ffc:	sw	a7,0(a5)
    8000:	sw	a6,0(a5)
    8004:	ttstallwait	128,1
    8008:	ttwrcfg	28,0,12
    800c:	ttwrcfg	29,0,13
    8010:	ttnop
    8014:	ttnop
    8018:	ttsetadcxx	4,15,0
    801c:	li	a3,0
    8020:	addi	a0,a0,4
    8024:	sw	a3,0(a0)
    8028:	lw	a3,0(a0)
    802c:	and	zero,zero,a3
    8030:	sw	zero,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8034:	ttstallwait	33,8
    8038:	ttsetdmareg	0,0,0,8
    803c:	ttsetdmareg	0,512,0,16
    8040:	ttstallwait	128,1
    8044:	lui	a3,0xb0048
    8048:	addi	a3,a3,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    804c:	sw	a3,0(a5)
    8050:	ttdmanop
    8054:	ttdmanop
    8058:	ttsetadcxy	4,0,0,0,0,11
    805c:	ttsetadczw	4,0,0,0,0,15
    8060:	lw	t2,20(sp)
    8064:	lhu	t6,794(a4)
    8068:	lw	t5,780(a4)
    806c:	lui	a1,0xffb58
    8070:	lw	a3,32(a1) # ffb58020 <__fw_export_ldm_end+0x57800>
    8074:	add	a3,t5,a3
    8078:	sub	a3,a3,t6
    807c:	zext.h	a3,a3
    8080:	bgeu	a2,a3,8070 <.L14>
    8084:	ttsemwait	1,2,1
    8088:	lw	s3,788(a4)
    808c:	lw	t4,776(a4)
    8090:	beqz	t2,8110 <.L15>
    8094:	lw	a1,796(a4)
    8098:	lui	a7,0x45000
    809c:	lui	a0,0x508c0
    80a0:	add	a1,s3,a1
    80a4:	lui	t3,0x1000
    80a8:	addi	s1,a7,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    80ac:	addi	a1,a1,-1
    80b0:	add	s0,t2,a0
    80b4:	addi	t3,t3,-256 # ffff00 <.LASF142+0xff47f7>
    80b8:	addi	a7,a7,25
    80bc:	lui	t0,0x800
    80c0:	slli	a2,a1,0x8
    80c4:	srli	a3,a1,0x10
    80c8:	and	a2,a2,t3
    80cc:	slli	a3,a3,0x8
    80d0:	sw	a0,0(a5)
    80d4:	add	a2,a2,s1
    80d8:	or	a6,a3,t0
    80dc:	sw	a2,0(a5)
    80e0:	add	a2,a6,a7
    80e4:	sw	a2,0(a5)
    80e8:	ttstallwait	128,1
    80ec:	ttwrcfg	12,0,69
    80f0:	add	a3,a3,a7
    80f4:	sw	a3,0(a5)
    80f8:	ttdmanop
    80fc:	ttmop	1,0,0
    8100:	ttsetadczw	4,0,0,0,0,5
    8104:	addi	a0,a0,1 # 508c0001 <__device_print_strings_info_end+0x4a3c0001>
    8108:	add	a1,a1,t4
    810c:	bne	s0,a0,80c0 <.L16>
    8110:	ttstallwait	64,8
    8114:	lui	a3,0x10144
    8118:	sw	a3,0(a5)
    811c:	ttsemget	2
    8120:	li	a2,1
    8124:	lui	a3,0xb0088
    8128:	addi	a3,a3,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    812c:	sw	a2,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8130:	sw	a3,0(a5)
    8134:	ttdmanop
    8138:	ttdmanop
    813c:	lw	a3,772(a4)
    8140:	sh1add	s3,t4,s3
    8144:	sw	zero,796(a4)
    8148:	sw	a3,12(sp)
    814c:	sw	s3,788(a4)
    8150:	bltu	s3,a3,8160 <.L17>
    8154:	lw	a3,768(a4)
    8158:	sub	s3,s3,a3
    815c:	sw	s3,788(a4)
    8160:	addi	t0,t6,2 # 41008002 <__device_print_strings_info_end+0x3ab08002>
    8164:	lui	a2,0x45000
    8168:	zext.h	t0,t0
    816c:	addi	a2,a2,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    8170:	slli	a3,t0,0x8
    8174:	add	a3,a3,a2
    8178:	sw	a3,0(a5)
    817c:	sh	t0,794(a4)
    8180:	ttstallwait	32,8
    8184:	lui	a3,0x67616
    8188:	addi	a3,a3,10 # 6761600a <__device_print_strings_info_end+0x6111600a>
    818c:	sw	a3,0(a5)
    8190:	lhu	a2,378(a4)
    8194:	lw	a0,364(a4)
    8198:	lui	a1,0xffb4b
    819c:	lw	a3,32(a1) # ffb4b020 <__fw_export_ldm_end+0x4a800>
    81a0:	add	a3,a0,a3
    81a4:	zext.h	a3,a3
    81a8:	beq	a2,a3,819c <.L18>
    81ac:	ttsetdmareg	0,0,0,56
    81b0:	ttsetdmareg	0,170,0,57
    81b4:	ttsetdmareg	0,1,0,60
    81b8:	ttsetdmareg	1,5461,0,58
    81bc:	ttsetdmareg	1,5461,0,59
    81c0:	ttstallwait	128,8
    81c4:	ttwrcfg	28,0,24
    81c8:	ttwrcfg	30,0,25
    81cc:	ttwrcfg	29,0,21
    81d0:	ttnop
    81d4:	ttnop
    81d8:	ttsemwait	1,2,1
    81dc:	lw	a7,372(a4)
    81e0:	lw	a3,380(a4)
    81e4:	lui	a0,0x508c0
    81e8:	add	a3,a7,a3
    81ec:	addi	a3,a3,-1
    81f0:	lui	a1,0x1000
    81f4:	sw	a0,0(a5)
    81f8:	slli	a6,a3,0x8
    81fc:	addi	a1,a1,-256 # ffff00 <.LASF142+0xff47f7>
    8200:	lui	a0,0x45000
    8204:	and	a6,a6,a1
    8208:	srli	a3,a3,0x10
    820c:	addi	a1,a0,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    8210:	add	a6,a6,a1
    8214:	slli	a3,a3,0x8
    8218:	lui	a1,0x800
    821c:	addi	a0,a0,25
    8220:	or	a1,a3,a1
    8224:	sw	a6,0(a5)
    8228:	add	a1,a1,a0
    822c:	sw	a1,0(a5)
    8230:	lw	a1,360(a4)
    8234:	ttstallwait	128,1
    8238:	ttwrcfg	12,0,69
    823c:	add	a3,a3,a0
    8240:	sw	a3,0(a5)
    8244:	ttdmanop
    8248:	ttmop	1,0,0
    824c:	ttsetadczw	4,0,0,0,0,5
    8250:	ttstallwait	64,8
    8254:	lui	a3,0x10144
    8258:	addi	a3,a3,1 # 10144001 <__device_print_strings_info_end+0x9c44001>
    825c:	sw	a3,0(a5)
    8260:	ttsemget	2
    8264:	lui	a3,0xb0048
    8268:	addi	a3,a3,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    826c:	sw	zero,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8270:	sw	a3,0(a5)
    8274:	ttdmanop
    8278:	ttdmanop
    827c:	ttsetdmareg	3,16383,0,56
    8280:	ttsetdmareg	0,0,0,57
    8284:	ttstallwait	128,8
    8288:	ttwrcfg	28,0,24
    828c:	ttwrcfg	28,0,25
    8290:	ttwrcfg	0,0,20
    8294:	ttwrcfg	0,0,21
    8298:	ttnop
    829c:	ttnop
    82a0:	add	a3,a1,a7
    82a4:	lw	a1,356(a4)
    82a8:	sw	a3,372(a4)
    82ac:	sw	zero,380(a4)
    82b0:	bltu	a3,a1,82c0 <.L19>
    82b4:	lw	a1,352(a4)
    82b8:	sub	a3,a3,a1
    82bc:	sw	a3,372(a4)
    82c0:	addi	a2,a2,1
    82c4:	lui	a1,0x45000
    82c8:	zext.h	a2,a2
    82cc:	addi	a1,a1,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    82d0:	slli	a3,a2,0x8
    82d4:	add	a3,a3,a1
    82d8:	sh	a2,378(a4)
    82dc:	sw	a3,0(a5)
    82e0:	ttstallwait	32,8
    82e4:	lui	a3,0x67613
    82e8:	addi	a3,a3,-1014 # 67612c0a <__device_print_strings_info_end+0x61112c0a>
    82ec:	sw	a3,0(a5)
    82f0:	ttsetdmareg	0,0,0,56
    82f4:	ttsetdmareg	0,170,0,57
    82f8:	ttsetdmareg	0,1,0,60
    82fc:	ttsetdmareg	1,5461,0,58
    8300:	ttsetdmareg	1,5461,0,59
    8304:	ttstallwait	128,8
    8308:	ttwrcfg	28,0,24
    830c:	ttwrcfg	30,0,25
    8310:	ttwrcfg	29,0,21
    8314:	ttnop
    8318:	ttnop
    831c:	lhu	a6,410(a4)
    8320:	lw	a1,396(a4)
    8324:	lui	a2,0xffb4c
    8328:	lw	a3,32(a2) # ffb4c020 <__fw_export_ldm_end+0x4b800>
    832c:	add	a3,a1,a3
    8330:	sub	a3,a3,a6
    8334:	zext.h	a3,a3
    8338:	blt	a3,t1,8328 <.L20>
    833c:	lw	a2,404(a4)
    8340:	lw	s1,392(a4)
    8344:	sw	a2,8(sp)
    8348:	beqz	t1,8948 <.L44>
    834c:	lw	a3,412(a4)
    8350:	lui	a7,0x45000
    8354:	add	a3,a2,a3
    8358:	lui	s4,0x1000
    835c:	addi	s10,a7,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    8360:	addi	a3,a3,-1
    8364:	addi	s4,s4,-256 # ffff00 <.LASF142+0xff47f7>
    8368:	addi	a7,a7,25
    836c:	li	a1,0
    8370:	li	a2,0
    8374:	lui	s9,0x508c0
    8378:	lui	s8,0x800
    837c:	lui	s7,0x10144
    8380:	li	s6,1
    8384:	lui	s5,0xb0048
    8388:	lui	s11,0xb0088
    838c:	ttsemwait	1,2,1
    8390:	slli	t3,a3,0x8
    8394:	srli	a0,a3,0x10
    8398:	and	t3,t3,s4
    839c:	sw	s9,0(a5)
    83a0:	add	t3,t3,s10
    83a4:	slli	a0,a0,0x8
    83a8:	sw	t3,0(a5)
    83ac:	or	t3,a0,s8
    83b0:	add	t3,t3,a7
    83b4:	sw	t3,0(a5)
    83b8:	ttstallwait	128,1
    83bc:	ttwrcfg	12,0,69
    83c0:	add	a0,a0,a7
    83c4:	sw	a0,0(a5)
    83c8:	ttdmanop
    83cc:	ttmop	1,0,0
    83d0:	ttsetadczw	4,0,0,0,0,5
    83d4:	ttstallwait	64,8
    83d8:	add	t3,a1,s7
    83dc:	sw	t3,0(a5)
    83e0:	ttsemget	2
    83e4:	mv	s0,a1
    83e8:	addi	a0,s5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    83ec:	xori	a1,a1,1
    83f0:	beq	s0,s6,83f8 <.L22>
    83f4:	addi	a0,s11,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    83f8:	sw	a0,0(a5)
    83fc:	ttdmanop
    8400:	ttdmanop
    8404:	addi	a2,a2,1
    8408:	add	a3,a3,s1
    840c:	bne	t1,a2,838c <.L23>
    8410:	lui	a2,0x10144
    8414:	sw	a1,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8418:	add	a2,a1,a2
    841c:	ttsetdmareg	3,16383,0,56
    8420:	ttsetdmareg	0,0,0,57
    8424:	ttstallwait	128,8
    8428:	ttwrcfg	28,0,24
    842c:	ttwrcfg	28,0,25
    8430:	ttwrcfg	0,0,20
    8434:	ttwrcfg	0,0,21
    8438:	ttnop
    843c:	ttnop
    8440:	lw	a3,8(sp)
    8444:	mul	s1,t1,s1
    8448:	sw	zero,412(a4)
    844c:	add	s1,s1,a3
    8450:	lw	a3,388(a4)
    8454:	sw	s1,404(a4)
    8458:	bltu	s1,a3,8468 <.L24>
    845c:	lw	a3,384(a4)
    8460:	sub	s1,s1,a3
    8464:	sw	s1,404(a4)
    8468:	add	a6,a6,t1
    846c:	lui	s1,0x45000
    8470:	zext.h	a6,a6
    8474:	addi	s5,s1,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    8478:	sh	a6,410(a4)
    847c:	slli	a6,a6,0x8
    8480:	add	a6,a6,s5
    8484:	sw	a6,0(a5)
    8488:	ttstallwait	32,8
    848c:	lui	a3,0x67613
    8490:	addi	a3,a3,10 # 6761300a <__device_print_strings_info_end+0x6111300a>
    8494:	sw	a3,0(a5)
    8498:	lw	a3,4(sp)
    849c:	bnez	a3,85f8 <.L25>
    84a0:	beqz	t1,85f8 <.L25>
    84a4:	lui	s6,0x67615
    84a8:	addi	a3,s6,10 # 6761500a <__device_print_strings_info_end+0x6111500a>
    84ac:	sw	a3,4(sp)
    84b0:	lw	a3,640(a4)
    84b4:	lui	s7,0x1000
    84b8:	sw	a3,8(sp)
    84bc:	lw	a6,652(a4)
    84c0:	lw	s11,648(a4)
    84c4:	lw	s10,644(a4)
    84c8:	lhu	a3,666(a4)
    84cc:	lw	a2,668(a4)
    84d0:	lw	a7,660(a4)
    84d4:	addi	s7,s7,-256 # ffff00 <.LASF142+0xff47f7>
    84d8:	li	s0,0
    84dc:	lui	a0,0xffb54
    84e0:	lui	s9,0x508c0
    84e4:	addi	s8,s1,24
    84e8:	addi	s4,s1,25
    84ec:	lw	t3,32(a0) # ffb54020 <__fw_export_ldm_end+0x53800>
    84f0:	add	t3,a6,t3
    84f4:	zext.h	t3,t3
    84f8:	beq	t3,a3,84ec <.L26>
    84fc:	ttsemwait	1,2,1
    8500:	ttsemwait	1,2,1
    8504:	add	a2,a2,a7
    8508:	addi	a2,a2,-1 # 10143fff <__device_print_strings_info_end+0x9c43fff>
    850c:	slli	t3,a2,0x8
    8510:	and	t3,t3,s7
    8514:	sw	s9,0(a5)
    8518:	add	t3,t3,s8
    851c:	srli	a2,a2,0x10
    8520:	sw	t3,0(a5)
    8524:	slli	a2,a2,0x8
    8528:	lui	t3,0x800
    852c:	or	t3,a2,t3
    8530:	add	t3,t3,s4
    8534:	sw	t3,0(a5)
    8538:	ttstallwait	128,1
    853c:	ttwrcfg	12,0,69
    8540:	add	a2,a2,s4
    8544:	sw	a2,0(a5)
    8548:	ttdmanop
    854c:	ttmop	1,0,0
    8550:	ttsetadczw	4,0,0,0,0,5
    8554:	addi	a3,a3,1
    8558:	add	a7,a7,s11
    855c:	zext.h	a3,a3
    8560:	sw	a7,660(a4)
    8564:	slli	a2,a3,0x8
    8568:	sw	zero,668(a4)
    856c:	add	a2,a2,s5
    8570:	bltu	a7,s10,8580 <.L27>
    8574:	lw	t3,8(sp)
    8578:	sub	a7,a7,t3
    857c:	sw	a7,660(a4)
    8580:	sw	a2,0(a5)
    8584:	sh	a3,666(a4)
    8588:	ttstallwait	32,8
    858c:	lw	a2,4(sp)
    8590:	sw	a2,0(a5)
    8594:	ttstallwait	64,8
    8598:	lui	a2,0x10144
    859c:	add	t3,a1,a2
    85a0:	sw	t3,0(a5)
    85a4:	ttsemget	2
    85a8:	xori	s1,a1,1
    85ac:	lui	a2,0xb0048
    85b0:	sw	s1,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    85b4:	li	s6,1
    85b8:	addi	a2,a2,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    85bc:	beq	a1,s6,85c8 <.L28>
    85c0:	lui	a2,0xb0088
    85c4:	addi	a2,a2,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    85c8:	sw	a2,0(a5)
    85cc:	ttdmanop
    85d0:	ttdmanop
    85d4:	addi	s0,s0,1
    85d8:	li	a2,0
    85dc:	beq	t1,s0,85e8 <.L80>
    85e0:	mv	a1,s1
    85e4:	j	84ec <.L26>
    85e8:	lui	a2,0x10144
    85ec:	mv	s0,a1
    85f0:	add	a2,s1,a2
    85f4:	mv	a1,s1
    85f8:	lui	a6,0xffb58
    85fc:	li	a0,1
    8600:	lw	a3,32(a6) # ffb58020 <__fw_export_ldm_end+0x57800>
    8604:	add	a3,t5,a3
    8608:	sub	a3,a3,t0
    860c:	zext.h	a3,a3
    8610:	bgeu	a0,a3,8600 <.L30>
    8614:	ttsemwait	1,2,1
    8618:	beqz	t2,8690 <.L31>
    861c:	lui	t5,0x45000
    8620:	lui	a6,0x508c0
    8624:	lui	t0,0x1000
    8628:	addi	s1,t5,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    862c:	add	s4,t2,a6
    8630:	addi	t0,t0,-256 # ffff00 <.LASF142+0xff47f7>
    8634:	addi	t5,t5,25
    8638:	addi	a7,s3,-1
    863c:	lui	s5,0x800
    8640:	slli	a0,a7,0x8
    8644:	srli	a3,a7,0x10
    8648:	and	a0,a0,t0
    864c:	slli	a3,a3,0x8
    8650:	sw	a6,0(a5)
    8654:	add	a0,a0,s1
    8658:	or	t1,a3,s5
    865c:	sw	a0,0(a5)
    8660:	add	a0,t1,t5
    8664:	sw	a0,0(a5)
    8668:	ttstallwait	128,1
    866c:	ttwrcfg	12,0,69
    8670:	add	a3,a3,t5
    8674:	sw	a3,0(a5)
    8678:	ttdmanop
    867c:	ttmop	1,0,0
    8680:	ttsetadczw	4,0,0,0,0,5
    8684:	addi	a6,a6,1 # 508c0001 <__device_print_strings_info_end+0x4a3c0001>
    8688:	add	a7,a7,t4
    868c:	bne	s4,a6,8640 <.L32>
    8690:	ttstallwait	64,8
    8694:	sw	a2,0(a5)
    8698:	ttsemget	2
    869c:	lui	a3,0xb0048
    86a0:	sw	s0,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    86a4:	li	a2,1
    86a8:	addi	a3,a3,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    86ac:	beq	a1,a2,86b8 <.L33>
    86b0:	lui	a3,0xb0088
    86b4:	addi	a3,a3,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    86b8:	sw	a3,0(a5)
    86bc:	ttdmanop
    86c0:	ttdmanop
    86c4:	lw	a3,12(sp)
    86c8:	sh1add	t4,t4,s3
    86cc:	sw	t4,788(a4)
    86d0:	bltu	t4,a3,86e0 <.L34>
    86d4:	lw	a3,768(a4)
    86d8:	sub	t4,t4,a3
    86dc:	sw	t4,788(a4)
    86e0:	lui	a3,0x45000
    86e4:	addi	t6,t6,4
    86e8:	zext.h	t6,t6
    86ec:	addi	a0,a3,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    86f0:	slli	a2,t6,0x8
    86f4:	add	a2,a2,a0
    86f8:	sh	t6,794(a4)
    86fc:	sw	a2,0(a5)
    8700:	ttstallwait	32,8
    8704:	lui	a2,0x67616
    8708:	addi	a2,a2,10 # 6761600a <__device_print_strings_info_end+0x6111600a>
    870c:	sw	a2,0(a5)
    8710:	lui	a2,0x45055
    8714:	addi	a2,a2,316 # 4505513c <__device_print_strings_info_end+0x3eb5513c>
    8718:	sw	a2,0(a5)
    871c:	lw	t5,520(a4)
    8720:	ttstallwait	128,9
    8724:	ttwrcfg	30,0,70
    8728:	lui	a2,0x45100
    872c:	addi	a2,a2,56 # 45100038 <__device_print_strings_info_end+0x3ec00038>
    8730:	sw	a2,0(a5)
    8734:	addi	a2,a3,57
    8738:	sw	a2,0(a5)
    873c:	lui	a2,0xb01c0
    8740:	addi	a2,a2,28 # b01c001c <__device_print_strings_info_end+0xa9cc001c>
    8744:	sw	a2,0(a5)
    8748:	lui	a2,0xb30b0
    874c:	addi	a2,a2,274 # b30b0112 <__device_print_strings_info_end+0xacbb0112>
    8750:	lui	a6,0x1000
    8754:	lui	a0,0xb5800
    8758:	sw	a2,0(a5)
    875c:	addi	a6,a6,-256 # ffff00 <.LASF142+0xff47f7>
    8760:	slli	a2,t5,0x8
    8764:	addi	a0,a0,71 # b5800047 <__device_print_strings_info_end+0xaf300047>
    8768:	sw	a0,0(a5)
    876c:	and	a2,a2,a6
    8770:	addi	a0,a3,32
    8774:	add	a2,a2,a0
    8778:	sw	a2,0(a5)
    877c:	lui	a2,0xb5100
    8780:	addi	a2,a2,71 # b5100047 <__device_print_strings_info_end+0xaec00047>
    8784:	sw	a2,0(a5)
    8788:	lui	a2,0xb6ff0
    878c:	addi	a2,a2,71 # b6ff0047 <__device_print_strings_info_end+0xb0af0047>
    8790:	sw	a2,0(a5)
    8794:	lui	a2,0xb61e1
    8798:	addi	a2,a2,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    879c:	sw	a2,0(a5)
    87a0:	addi	a3,a3,56
    87a4:	sw	a3,0(a5)
    87a8:	lui	a3,0x45002
    87ac:	addi	a3,a3,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    87b0:	sw	a3,0(a5)
    87b4:	lui	a3,0x45020
    87b8:	addi	a3,a3,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    87bc:	sw	a3,0(a5)
    87c0:	lui	a3,0x45080
    87c4:	addi	a3,a3,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    87c8:	sw	a3,0(a5)
    87cc:	ttstallwait	128,1
    87d0:	ttwrcfg	28,0,12
    87d4:	ttwrcfg	29,0,13
    87d8:	ttnop
    87dc:	ttnop
    87e0:	lhu	t4,538(a4)
    87e4:	lw	a6,524(a4)
    87e8:	lui	a0,0xffb50
    87ec:	li	a2,1
    87f0:	lw	a3,32(a0) # ffb50020 <__fw_export_ldm_end+0x4f800>
    87f4:	add	a3,a6,a3
    87f8:	sub	a3,a3,t4
    87fc:	zext.h	a3,a3
    8800:	bgeu	a2,a3,87f0 <.L35>
    8804:	ttsemwait	1,2,1
    8808:	lw	t0,532(a4)
    880c:	beqz	t2,888c <.L36>
    8810:	lw	a0,540(a4)
    8814:	lui	t1,0x45000
    8818:	lui	a6,0x508c0
    881c:	add	a0,t0,a0
    8820:	lui	t6,0x1000
    8824:	addi	s1,t1,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    8828:	addi	a0,a0,-1
    882c:	add	t2,t2,a6
    8830:	addi	t6,t6,-256 # ffff00 <.LASF142+0xff47f7>
    8834:	addi	t1,t1,25
    8838:	lui	s0,0x800
    883c:	slli	a2,a0,0x8
    8840:	srli	a3,a0,0x10
    8844:	and	a2,a2,t6
    8848:	slli	a3,a3,0x8
    884c:	sw	a6,0(a5)
    8850:	add	a2,a2,s1
    8854:	or	a7,a3,s0
    8858:	sw	a2,0(a5)
    885c:	add	a2,a7,t1
    8860:	sw	a2,0(a5)
    8864:	ttstallwait	128,1
    8868:	ttwrcfg	12,0,69
    886c:	add	a3,a3,t1
    8870:	sw	a3,0(a5)
    8874:	ttdmanop
    8878:	ttmop	1,0,0
    887c:	ttsetadczw	4,0,0,0,0,5
    8880:	addi	a6,a6,1 # 508c0001 <__device_print_strings_info_end+0x4a3c0001>
    8884:	add	a0,a0,t5
    8888:	bne	t2,a6,883c <.L37>
    888c:	ttstallwait	64,8
    8890:	sw	t3,0(a5)
    8894:	ttsemget	2
    8898:	lui	a3,0xb0048
    889c:	sw	a1,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    88a0:	addi	a3,a3,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    88a4:	beqz	a1,88b0 <.L38>
    88a8:	lui	a3,0xb0088
    88ac:	addi	a3,a3,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    88b0:	sw	a3,0(a5)
    88b4:	ttdmanop
    88b8:	ttdmanop
    88bc:	lw	a3,516(a4)
    88c0:	sh1add	t5,t5,t0
    88c4:	sw	zero,540(a4)
    88c8:	sw	t5,532(a4)
    88cc:	bltu	t5,a3,88dc <.L39>
    88d0:	lw	a3,512(a4)
    88d4:	sub	t5,t5,a3
    88d8:	sw	t5,532(a4)
    88dc:	addi	t4,t4,2
    88e0:	lui	a2,0x45000
    88e4:	zext.h	t4,t4
    88e8:	addi	a2,a2,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    88ec:	slli	a3,t4,0x8
    88f0:	add	a3,a3,a2
    88f4:	sh	t4,538(a4)
    88f8:	sw	a3,0(a5)
    88fc:	ttstallwait	32,8
    8900:	lui	a4,0x67614
    8904:	lw	s0,76(sp)
    8908:	addi	a4,a4,10 # 6761400a <__device_print_strings_info_end+0x6111400a>
    890c:	sw	a4,0(a5)
    8910:	lw	s1,72(sp)
    8914:	lw	s2,68(sp)
    8918:	lw	s3,64(sp)
    891c:	lw	s4,60(sp)
    8920:	lw	s5,56(sp)
    8924:	lw	s6,52(sp)
    8928:	lw	s7,48(sp)
    892c:	lw	s8,44(sp)
    8930:	lw	s9,40(sp)
    8934:	lw	s10,36(sp)
    8938:	lw	s11,32(sp)
    893c:	li	a0,0
    8940:	addi	sp,sp,80
    8944:	ret
    8948:	lui	a2,0x10144
    894c:	addi	t3,a2,1 # 10144001 <__device_print_strings_info_end+0x9c44001>
    8950:	li	a1,0
    8954:	li	s0,1
    8958:	j	841c <.L21>
    895c:	mv	a5,a3
    8960:	j	7d7c <.L4>
