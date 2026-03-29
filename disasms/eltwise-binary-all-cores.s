# Eltwise Binary No Bcast — All 5 cores (stripped)
# reader=reader_interleaved_no_bcast, compute=eltwise_binary_no_bcast, writer=writer_interleaved_no_bcast

######## NCRISC (reader) — kernel=reader_interleaved_no_bcast ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/reader_interleaved_no_bcast/5530780227384885511/ncrisc/ncrisc.elf:     file format elf32-littleriscv
00005f80 <_start>:
    5f80:	addi	sp,sp,-144
    5f84:	sw	s0,140(sp)
    5f88:	sw	s1,136(sp)
    5f8c:	sw	s2,132(sp)
    5f90:	sw	s3,128(sp)
    5f94:	sw	s4,124(sp)
    5f98:	sw	s5,120(sp)
    5f9c:	sw	s6,116(sp)
    5fa0:	sw	s7,112(sp)
    5fa4:	sw	s8,108(sp)
    5fa8:	sw	s9,104(sp)
    5fac:	sw	s11,96(sp)
    5fb0:	lui	a5,0xffb01
    5fb4:	lui	a4,0xffb01
    5fb8:	addi	a5,a5,-976 # ffb00c30 <__stack_base>
    5fbc:	addi	a4,a4,-984 # ffb00c28 <__ldm_bss_end>
    5fc0:	bltu	a4,a5,5fdc <.L2>
    5fc4:	sw	zero,-4(a5)
    5fc8:	sw	zero,-8(a5)
    5fcc:	sw	zero,-12(a5)
    5fd0:	sw	zero,-16(a5)
    5fd4:	addi	a5,a5,16
    5fd8:	bgeu	a4,a5,5fc4 <.L3>
    5fdc:	addi	a3,a5,-8
    5fe0:	bltu	a4,a3,5ff0 <.L4>
    5fe4:	sw	zero,-12(a5)
    5fe8:	sw	zero,-16(a5)
    5fec:	mv	a3,a5
    5ff0:	addi	a5,a3,-4
    5ff4:	bltu	a4,a5,5ffc <.L5>
    5ff8:	sw	zero,-8(a3)
    5ffc:	lui	a4,0x6
    6000:	addi	a4,a4,1476 # 65c4 <__kernel_data_lma>
    6004:	addi	a5,gp,1072 # ffb00c20 <noc_reads_num_issued>
    6008:	beq	a4,a5,6078 <.L7>
    600c:	addi	a2,gp,1072 # ffb00c20 <noc_reads_num_issued>
    6010:	sub	a2,a2,a5
    6014:	li	a1,8
    6018:	srai	a3,a2,0x2
    601c:	bge	a1,a2,605c <.L8>
    6020:	li	a2,2
    6024:	lw	a7,0(a4)
    6028:	lw	a6,4(a4)
    602c:	lw	a0,8(a4)
    6030:	mv	a1,a5
    6034:	mv	a5,a4
    6038:	addi	a5,a5,12
    603c:	addi	a1,a1,12
    6040:	addi	a3,a3,-3
    6044:	mv	a4,a5
    6048:	mv	a5,a1
    604c:	sw	a7,-12(a1)
    6050:	sw	a6,-8(a1)
    6054:	sw	a0,-4(a1)
    6058:	blt	a2,a3,6024 <.L9>
    605c:	blez	a3,6078 <.L7>
    6060:	lw	a1,0(a4)
    6064:	li	a2,2
    6068:	sw	a1,0(a5)
    606c:	bne	a3,a2,6078 <.L7>
    6070:	lw	a4,4(a4)
    6074:	sw	a4,4(a5)
    6078:	lui	a5,0xffb20
    607c:	lw	a4,520(a5) # ffb20208 <__stack_base+0x1f5d8>
    6080:	lw	a3,552(a5)
    6084:	lw	a3,516(a5)
    6088:	addi	t5,gp,1072 # ffb00c20 <noc_reads_num_issued>
    608c:	lw	a3,512(a5)
    6090:	lw	a5,556(a5)
    6094:	sw	a4,0(t5)
    6098:	lw	a5,1056(zero) # 420 <.LASF212>
    609c:	li	a4,128
    60a0:	slli	a5,a5,0x2
    60a4:	lbu	a3,1011(a5)
    60a8:	addi	a5,a5,96
    60ac:	beq	a3,a4,60bc <.L14>
    60b0:	fence
    60b4:	lbu	a3,915(a5)
    60b8:	bne	a3,a4,60b0 <.L11>
    60bc:	lw	a5,-1976(gp) # ffb00038 <rta_l1_base>
    60c0:	lui	a4,0x1
    60c4:	lw	s9,48(a5)
    60c8:	lw	t3,52(a5)
    60cc:	lw	a6,44(a5)
    60d0:	lw	a1,40(a5)
    60d4:	lw	s4,36(a5)
    60d8:	lw	a0,4(a5)
    60dc:	lw	s1,56(a5)
    60e0:	lw	t6,12(a5)
    60e4:	lw	t4,60(a5)
    60e8:	lw	t0,0(a5)
    60ec:	lw	s7,20(a5)
    60f0:	addi	a4,a4,-2048 # 800 <.LASF123+0x5>
    60f4:	sw	a4,72(sp)
    60f8:	mul	a4,s9,t3
    60fc:	li	a3,1088
    6100:	mul	a2,a6,a4
    6104:	sw	a3,88(sp)
    6108:	mul	a7,a1,a2
    610c:	lw	s5,24(a5)
    6110:	mul	t1,s4,a7
    6114:	lw	s6,28(a5)
    6118:	divu	t2,a0,t1
    611c:	lw	s3,32(a5)
    6120:	sltu	s0,t2,s1
    6124:	snez	a3,t6
    6128:	and	a3,a3,s0
    612c:	sw	t4,80(sp)
    6130:	sw	t0,64(sp)
    6134:	lw	s8,64(a5)
    6138:	lw	t4,68(a5)
    613c:	lw	s0,72(a5)
    6140:	lw	s2,76(a5)
    6144:	mv	s11,s7
    6148:	beqz	a3,658c <.L12>
    614c:	remu	a0,a0,t1
    6150:	sw	s8,12(sp)
    6154:	remu	t1,a0,a7
    6158:	sw	s10,100(sp)
    615c:	divu	a0,a0,a7
    6160:	lui	a3,0xffb00
    6164:	remu	a7,t1,a2
    6168:	addi	a3,a3,1044 # ffb00414 <cb_interface>
    616c:	divu	t1,t1,a2
    6170:	sw	s9,20(sp)
    6174:	mul	a2,s5,a0
    6178:	mul	a5,s7,t2
    617c:	mul	t0,t4,a0
    6180:	add	a5,a5,a2
    6184:	mul	a2,s8,t2
    6188:	mul	s7,s6,t1
    618c:	add	a2,a2,t0
    6190:	remu	s8,a7,a4
    6194:	divu	a7,a7,a4
    6198:	addi	t0,gp,-1500 # ffb00214 <bank_to_dram_offset>
    619c:	mul	s10,s0,t1
    61a0:	add	a5,a5,s7
    61a4:	mul	s7,s3,a7
    61a8:	add	a2,a2,s10
    61ac:	add	a5,a5,s7
    61b0:	mul	s7,s2,a7
    61b4:	sw	t0,16(sp)
    61b8:	divu	t0,s8,t3
    61bc:	mul	s10,t3,t0
    61c0:	add	a2,a2,s7
    61c4:	add	a5,a5,s10
    61c8:	mul	s7,s3,a6
    61cc:	add	a2,a2,s10
    61d0:	mul	s10,s6,a1
    61d4:	sub	s7,s6,s7
    61d8:	mul	s6,s5,s4
    61dc:	sub	s10,s5,s10
    61e0:	mul	s5,a6,s2
    61e4:	sub	s3,s3,a4
    61e8:	remu	s8,s8,t3
    61ec:	sub	a4,s2,a4
    61f0:	sub	s6,s11,s6
    61f4:	mul	s11,a1,s0
    61f8:	sub	s0,s0,s5
    61fc:	sw	a4,28(sp)
    6200:	mul	a4,s4,t4
    6204:	sw	s0,32(sp)
    6208:	sub	s0,t4,s11
    620c:	lw	t4,12(sp)
    6210:	sw	s3,24(sp)
    6214:	sub	s5,t4,a4
    6218:	lui	a4,0x92492
    621c:	addi	a4,a4,1171 # 92492493 <__device_print_strings_info_end+0x8bf92493>
    6220:	sw	a4,12(sp)
    6224:	sw	s0,36(sp)
    6228:	addi	s11,gp,-1968 # ffb00040 <dram_bank_to_noc_xy>
    622c:	li	a4,0
    6230:	sltu	s2,a4,t6
    6234:	sltu	s0,a0,s4
    6238:	and	s0,s2,s0
    623c:	mv	t4,s2
    6240:	lui	s9,0xffb40
    6244:	beqz	s0,656c <.L29>
    6248:	mv	s3,t2
    624c:	mv	t2,s7
    6250:	mv	s7,s1
    6254:	lui	s1,0x1
    6258:	sltu	s0,t1,a1
    625c:	addi	s1,s1,-2048 # 800 <.LASF123+0x5>
    6260:	and	s0,s2,s0
    6264:	sw	s1,52(sp)
    6268:	mv	t4,s2
    626c:	beqz	s0,6538 <.L27>
    6270:	sltu	s0,a7,a6
    6274:	and	s0,s2,s0
    6278:	mv	t4,s2
    627c:	lui	s1,0xffb41
    6280:	beqz	s0,6510 <.L25>
    6284:	sw	s4,56(sp)
    6288:	mv	s0,a1
    628c:	sw	a0,60(sp)
    6290:	lw	a1,20(sp)
    6294:	mv	t4,s2
    6298:	sltu	s4,t0,a1
    629c:	and	s4,s2,s4
    62a0:	lui	a1,0xffb21
    62a4:	li	a0,1
    62a8:	beqz	s4,64d8 <.L23>
    62ac:	mv	t4,s2
    62b0:	sltu	s2,s8,t3
    62b4:	and	s2,t4,s2
    62b8:	beqz	s2,64b0 <.L24>
    62bc:	add	t4,a5,s8
    62c0:	sub	s2,s8,a4
    62c4:	sub	t4,t4,a4
    62c8:	add	s8,a2,s8
    62cc:	sw	t4,40(sp)
    62d0:	sub	t4,s8,a4
    62d4:	sw	s2,48(sp)
    62d8:	sw	t4,44(sp)
    62dc:	lw	s2,40(s9) # ffb40028 <__stack_base+0x3f3f8>
    62e0:	zext.h	s2,s2
    62e4:	fence
    62e8:	lw	s4,32(s9)
    62ec:	lw	t4,12(a3)
    62f0:	add	t4,t4,s4
    62f4:	zext.h	t4,t4
    62f8:	beq	t4,s2,62e4 <.L15>
    62fc:	lw	t4,40(sp)
    6300:	add	s2,t4,a4
    6304:	lw	t4,12(sp)
    6308:	mulhu	s4,s2,t4
    630c:	lw	t4,72(sp)
    6310:	srli	s4,s4,0x2
    6314:	slli	s8,s4,0x3
    6318:	mul	t4,s4,t4
    631c:	sub	s4,s8,s4
    6320:	lw	s8,16(sp)
    6324:	sub	s2,s2,s4
    6328:	lw	s4,64(sp)
    632c:	sh2add	s8,s2,s8
    6330:	sh1add	s2,s2,s11
    6334:	lw	s8,0(s8)
    6338:	add	s4,t4,s4
    633c:	lhu	t4,0(s2)
    6340:	add	s2,s4,s8
    6344:	lw	s4,20(a3)
    6348:	slli	t4,t4,0x4
    634c:	lw	s8,-1984(a1) # ffb20840 <__stack_base+0x1fc10>
    6350:	bnez	s8,634c <.L16>
    6354:	sw	s4,-2036(a1)
    6358:	sw	s2,-2048(a1)
    635c:	sw	zero,-2044(a1)
    6360:	srli	t4,t4,0x4
    6364:	sw	t4,-2040(a1)
    6368:	lw	t4,52(sp)
    636c:	sw	t4,-2016(a1)
    6370:	sw	a0,-1984(a1)
    6374:	lw	t4,0(t5)
    6378:	addi	t4,t4,1
    637c:	sw	t4,0(t5)
    6380:	lw	s2,40(s1) # ffb41028 <__stack_base+0x403f8>
    6384:	zext.h	s2,s2
    6388:	fence
    638c:	lw	s4,32(s1)
    6390:	lw	t4,44(a3)
    6394:	add	t4,t4,s4
    6398:	zext.h	t4,t4
    639c:	beq	t4,s2,6388 <.L17>
    63a0:	lw	t4,44(sp)
    63a4:	lw	s2,12(sp)
    63a8:	add	t4,t4,a4
    63ac:	mulhu	s4,t4,s2
    63b0:	lw	s2,88(sp)
    63b4:	srli	s4,s4,0x2
    63b8:	slli	s8,s4,0x3
    63bc:	mul	s2,s4,s2
    63c0:	sub	s4,s8,s4
    63c4:	sub	t4,t4,s4
    63c8:	lw	s4,16(sp)
    63cc:	lw	s8,80(sp)
    63d0:	sh2add	s4,t4,s4
    63d4:	lw	s4,0(s4)
    63d8:	sh1add	t4,t4,s11
    63dc:	add	s2,s2,s8
    63e0:	lhu	t4,0(t4)
    63e4:	add	s2,s2,s4
    63e8:	lw	s4,52(a3)
    63ec:	slli	t4,t4,0x4
    63f0:	lw	s8,-1984(a1)
    63f4:	bnez	s8,63f0 <.L18>
    63f8:	sw	s4,-2036(a1)
    63fc:	sw	s2,-2048(a1)
    6400:	sw	zero,-2044(a1)
    6404:	srli	t4,t4,0x4
    6408:	sw	t4,-2040(a1)
    640c:	li	t4,1088
    6410:	sw	t4,-2016(a1)
    6414:	sw	a0,-1984(a1)
    6418:	lw	t4,0(t5)
    641c:	addi	t4,t4,1
    6420:	sw	t4,0(t5)
    6424:	lui	s2,0xffb20
    6428:	lw	s2,520(s2) # ffb20208 <__stack_base+0x1f5d8>
    642c:	bne	s2,t4,6424 <.L19>
    6430:	fence
    6434:	lw	s2,40(s9)
    6438:	lw	t4,8(a3)
    643c:	addi	s2,s2,1
    6440:	sw	s2,40(s9)
    6444:	lw	s4,20(a3)
    6448:	lw	s2,4(a3)
    644c:	add	t4,t4,s4
    6450:	sw	t4,20(a3)
    6454:	bne	t4,s2,6464 <.L20>
    6458:	lw	s2,0(a3)
    645c:	sub	t4,t4,s2
    6460:	sw	t4,20(a3)
    6464:	lw	s4,52(a3)
    6468:	lw	t4,40(a3)
    646c:	lw	s2,40(s1)
    6470:	add	t4,t4,s4
    6474:	addi	s2,s2,1
    6478:	sw	t4,52(a3)
    647c:	sw	s2,40(s1)
    6480:	lw	s2,36(a3)
    6484:	bne	t4,s2,6494 <.L21>
    6488:	lw	s2,32(a3)
    648c:	sub	t4,t4,s2
    6490:	sw	t4,52(a3)
    6494:	lw	t4,48(sp)
    6498:	addi	a4,a4,1
    649c:	add	s2,t4,a4
    64a0:	sltu	s2,s2,t3
    64a4:	sltu	t4,a4,t6
    64a8:	and	s2,t4,s2
    64ac:	bnez	s2,62dc <.L22>
    64b0:	lw	s2,20(sp)
    64b4:	addi	t0,t0,1
    64b8:	sltu	s2,t0,s2
    64bc:	and	s2,t4,s2
    64c0:	add	a5,a5,t3
    64c4:	add	a2,a2,t3
    64c8:	li	s8,0
    64cc:	beqz	s2,64d8 <.L23>
    64d0:	sltu	s2,a4,t6
    64d4:	j	62ac <.L26>
    64d8:	lw	a0,24(sp)
    64dc:	addi	a7,a7,1
    64e0:	sltu	a1,a7,a6
    64e4:	add	a5,a5,a0
    64e8:	lw	a0,28(sp)
    64ec:	and	a1,t4,a1
    64f0:	add	a2,a2,a0
    64f4:	li	t0,0
    64f8:	beqz	a1,6504 <.L73>
    64fc:	sltu	s2,a4,t6
    6500:	j	6290 <.L28>
    6504:	lw	s4,56(sp)
    6508:	lw	a0,60(sp)
    650c:	mv	a1,s0
    6510:	addi	t1,t1,1
    6514:	lw	a7,32(sp)
    6518:	sltu	s0,t1,a1
    651c:	and	s0,t4,s0
    6520:	add	a2,a2,a7
    6524:	add	a5,a5,t2
    6528:	li	a7,0
    652c:	beqz	s0,6538 <.L27>
    6530:	sltu	s2,a4,t6
    6534:	j	6270 <.L30>
    6538:	addi	a0,a0,1
    653c:	lw	t1,36(sp)
    6540:	sltu	s0,a0,s4
    6544:	and	s0,t4,s0
    6548:	add	a2,a2,t1
    654c:	add	a5,a5,s10
    6550:	li	t1,0
    6554:	beqz	s0,6560 <.L77>
    6558:	sltu	s2,a4,t6
    655c:	j	6254 <.L31>
    6560:	mv	s1,s7
    6564:	mv	s7,t2
    6568:	mv	t2,s3
    656c:	addi	t2,t2,1
    6570:	sltu	a0,t2,s1
    6574:	and	t4,t4,a0
    6578:	add	a5,a5,s6
    657c:	add	a2,a2,s5
    6580:	li	a0,0
    6584:	bnez	t4,6230 <.L13>
    6588:	lw	s10,100(sp)
    658c:	lw	s0,140(sp)
    6590:	lw	s1,136(sp)
    6594:	lw	s2,132(sp)
    6598:	lw	s3,128(sp)
    659c:	lw	s4,124(sp)
    65a0:	lw	s5,120(sp)
    65a4:	lw	s6,116(sp)
    65a8:	lw	s7,112(sp)
    65ac:	lw	s8,108(sp)
    65b0:	lw	s9,104(sp)
    65b4:	lw	s11,96(sp)
    65b8:	li	a0,0
    65bc:	addi	sp,sp,144
    65c0:	ret

######## TRISC0 (unpack) — kernel=eltwise_binary_no_bcast ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/eltwise_binary_no_bcast/762602881991838469/trisc0/trisc0.elf:     file format elf32-littleriscv
00006930 <_start>:
    6930:	addi	sp,sp,-64
    6934:	sw	s0,60(sp)
    6938:	lui	a5,0xffb01
    693c:	lui	a4,0xffb01
    6940:	addi	a5,a5,-2000 # ffb00830 <__stack_base>
    6944:	addi	a4,a4,-2012 # ffb00824 <__ldm_bss_end>
    6948:	bltu	a4,a5,6964 <.L2>
    694c:	sw	zero,-4(a5)
    6950:	sw	zero,-8(a5)
    6954:	sw	zero,-12(a5)
    6958:	sw	zero,-16(a5)
    695c:	addi	a5,a5,16
    6960:	bgeu	a4,a5,694c <.L3>
    6964:	addi	a3,a5,-8
    6968:	bltu	a4,a3,6e14 <.L29>
    696c:	sw	zero,-12(a5)
    6970:	sw	zero,-16(a5)
    6974:	addi	a3,a5,-4
    6978:	bltu	a4,a3,6980 <.L5>
    697c:	sw	zero,-8(a5)
    6980:	lui	a4,0x7
    6984:	addi	a4,a4,-484 # 6e1c <__kernel_data_lma>
    6988:	addi	a5,gp,48 # ffb00820 <unp_cfg_context>
    698c:	beq	a4,a5,69ec <.L7>
    6990:	addi	a2,gp,48 # ffb00820 <unp_cfg_context>
    6994:	sub	a2,a2,a5
    6998:	li	a1,8
    699c:	srai	a3,a2,0x2
    69a0:	bge	a1,a2,69d0 <.L8>
    69a4:	li	a6,2
    69a8:	lw	a0,0(a4)
    69ac:	lw	a1,4(a4)
    69b0:	lw	a2,8(a4)
    69b4:	addi	a4,a4,12
    69b8:	addi	a5,a5,12
    69bc:	addi	a3,a3,-3
    69c0:	sw	a0,-12(a5)
    69c4:	sw	a1,-8(a5)
    69c8:	sw	a2,-4(a5)
    69cc:	blt	a6,a3,69a8 <.L9>
    69d0:	blez	a3,69ec <.L7>
    69d4:	lw	a1,0(a4)
    69d8:	li	a2,2
    69dc:	sw	a1,0(a5)
    69e0:	bne	a3,a2,69ec <.L7>
    69e4:	lw	a4,4(a4)
    69e8:	sw	a4,4(a5)
    69ec:	lui	a5,0xffb12
    69f0:	sw	zero,104(a5) # ffb12068 <__stack_base+0x11838>
    69f4:	lw	a4,1056(zero) # 420 <.LASF1061+0x1>
    69f8:	li	a3,128
    69fc:	slli	a4,a4,0x2
    6a00:	lbu	a5,1011(a4)
    6a04:	addi	a4,a4,96
    6a08:	beq	a5,a3,6a18 <.L13>
    6a0c:	fence
    6a10:	lbu	a5,915(a4)
    6a14:	bne	a5,a3,6a0c <.L11>
    6a18:	ttzerosrc	0,0,1,3
    6a1c:	lw	a5,-2012(gp) # ffb00014 <rta_l1_base>
    6a20:	lui	a0,0xffb00
    6a24:	lw	s0,0(a5)
    6a28:	addi	a0,a0,32 # ffb00020 <cb_interface>
    6a2c:	lw	a2,8(a0)
    6a30:	lw	a3,40(a0)
    6a34:	lui	a4,0xffe80
    6a38:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    6a3c:	zext.b	a5,a5
    6a40:	bnez	a5,6a38 <.L12>
    6a44:	ttsetadcxy	3,0,0,0,0,11
    6a48:	ttsetadczw	3,0,0,0,0,15
    6a4c:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6a50:	lui	a5,0xffef0
    6a54:	beqz	a4,6a5c <.L14>
    6a58:	addi	a5,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    6a5c:	li	a4,512
    6a60:	sw	a4,228(a5)
    6a64:	li	t4,256
    6a68:	sw	t4,236(a5)
    6a6c:	ttatgetm	0
    6a70:	lui	t1,0xffe40
    6a74:	mv	t1,t1
    6a78:	lui	a4,0xb3ff0
    6a7c:	sw	a4,0(t1) # ffe40000 <__instrn_buffer>
    6a80:	lui	a4,0xb47f0
    6a84:	sw	a4,0(t1)
    6a88:	lui	a4,0xb3070
    6a8c:	addi	a4,a4,1 # b3070001 <__device_print_strings_info_end+0xacb70001>
    6a90:	sw	a4,0(t1)
    6a94:	lui	a4,0xb4800
    6a98:	addi	a4,a4,1 # b4800001 <__device_print_strings_info_end+0xae300001>
    6a9c:	sw	a4,0(t1)
    6aa0:	lui	a4,0xb5010
    6aa4:	addi	a4,a4,1 # b5010001 <__device_print_strings_info_end+0xaeb10001>
    6aa8:	sw	a4,0(t1)
    6aac:	lui	a4,0xb3010
    6ab0:	addi	a4,a4,2 # b3010002 <__device_print_strings_info_end+0xacb10002>
    6ab4:	sw	a4,0(t1)
    6ab8:	lui	a4,0xb5400
    6abc:	addi	a1,a4,71 # b5400047 <__device_print_strings_info_end+0xaef00047>
    6ac0:	sw	a1,0(t1)
    6ac4:	addi	a4,a4,119
    6ac8:	sw	a4,0(t1)
    6acc:	ttatrelm	0
    6ad0:	li	a4,21
    6ad4:	sw	a4,256(a5)
    6ad8:	lui	a4,0x40
    6adc:	addi	a4,a4,1 # 40001 <.LASF1615+0x37a5d>
    6ae0:	lui	a1,0x1000
    6ae4:	sw	a4,260(a5)
    6ae8:	addi	a6,a1,22 # 1000016 <.LASF1615+0xff7a72>
    6aec:	sw	a6,448(a5)
    6af0:	sw	a4,452(a5)
    6af4:	li	a4,37
    6af8:	sw	a4,288(a5)
    6afc:	lui	a4,0xf0
    6b00:	addi	a4,a4,15 # f000f <.LASF1615+0xe7a6b>
    6b04:	sw	a4,292(a5)
    6b08:	li	a6,38
    6b0c:	sw	a6,480(a5)
    6b10:	sw	a4,484(a5)
    6b14:	lui	a4,0x5e240
    6b18:	addi	a4,a4,-1024 # 5e23fc00 <__device_print_strings_info_end+0x57d3fc00>
    6b1c:	sw	a4,0(t1)
    6b20:	lui	a4,0x5e440
    6b24:	addi	a4,a4,-1024 # 5e43fc00 <__device_print_strings_info_end+0x57f3fc00>
    6b28:	lui	a6,0x400
    6b2c:	sw	a4,0(t1)
    6b30:	addi	a6,a6,64 # 400040 <.LASF1615+0x3f7a9c>
    6b34:	sw	a6,336(a5)
    6b38:	add	a7,a1,t4
    6b3c:	sw	a7,344(a5)
    6b40:	lui	a4,0xffe00
    6b44:	sw	a7,160(a4) # ffe000a0 <__stack_base+0x2ff870>
    6b48:	lui	a7,0x800
    6b4c:	addi	a7,a7,128 # 800080 <.LASF1615+0x7f7adc>
    6b50:	sw	a7,164(a4)
    6b54:	sw	a6,168(a4)
    6b58:	lui	a6,0x200
    6b5c:	addi	a6,a6,32 # 200020 <.LASF1615+0x1f7a7c>
    6b60:	sw	a6,172(a4)
    6b64:	lui	a6,0x100
    6b68:	addi	a6,a6,16 # 100010 <.LASF1615+0xf7a6c>
    6b6c:	sw	a6,176(a4)
    6b70:	sw	zero,12(sp)
    6b74:	lw	a4,176(a4)
    6b78:	sw	a4,12(sp)
    6b7c:	ttsetc16	5,4
    6b80:	sw	t4,200(a5)
    6b84:	sw	zero,48(gp) # ffb00820 <unp_cfg_context>
    6b88:	ttsetc16	41,0
    6b8c:	lui	a6,0x45000
    6b90:	addi	a1,a1,-256
    6b94:	slli	a4,a2,0x8
    6b98:	and	a4,a4,a1
    6b9c:	slli	a5,a3,0x8
    6ba0:	addi	a3,a6,72 # 45000048 <__device_print_strings_info_end+0x3eb00048>
    6ba4:	and	a5,a5,a1
    6ba8:	add	a4,a4,a3
    6bac:	addi	a6,a6,74
    6bb0:	sw	a4,0(t1)
    6bb4:	add	a5,a5,a6
    6bb8:	lui	t4,0xb4010
    6bbc:	sw	a5,0(t1)
    6bc0:	addi	t4,t4,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    6bc4:	sw	t4,0(t1)
    6bc8:	ttsetadcxx	3,255,0
    6bcc:	li	a2,0
    6bd0:	lui	a7,0xffe80
    6bd4:	addi	a7,a7,8 # ffe80008 <__instrn_buffer+0x40008>
    6bd8:	mv	a5,a2
    6bdc:	sw	a5,0(a7)
    6be0:	lw	a5,0(a7)
    6be4:	and	zero,zero,a5
    6be8:	lui	a5,0xffb80
    6bec:	li	a6,2
    6bf0:	sw	a6,0(a5) # ffb80000 <__stack_base+0x7f7d0>
    6bf4:	sw	a6,4(a5)
    6bf8:	lui	a3,0x2000
    6bfc:	sw	a3,8(a5)
    6c00:	sw	a3,12(a5)
    6c04:	lui	a1,0x42008
    6c08:	sw	a3,16(a5)
    6c0c:	addi	a1,a1,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    6c10:	lui	a4,0x42808
    6c14:	sw	a1,20(a5)
    6c18:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    6c1c:	sw	a4,24(a5)
    6c20:	sw	a4,28(a5)
    6c24:	sw	a4,32(a5)
    6c28:	sw	t4,0(t1)
    6c2c:	ttsetadcxx	3,255,0
    6c30:	sw	a2,0(a7)
    6c34:	lw	a2,0(a7)
    6c38:	and	zero,zero,a2
    6c3c:	sw	a6,0(a5)
    6c40:	sw	a6,4(a5)
    6c44:	sw	a3,8(a5)
    6c48:	sw	a3,12(a5)
    6c4c:	sw	a3,16(a5)
    6c50:	sw	a1,20(a5)
    6c54:	sw	a4,24(a5)
    6c58:	sw	a4,28(a5)
    6c5c:	sw	a4,32(a5)
    6c60:	beqz	s0,6dd0 <.L45>
    6c64:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6c68:	lui	a5,0xffef0
    6c6c:	sw	s1,56(sp)
    6c70:	sw	s2,52(sp)
    6c74:	sw	s3,48(sp)
    6c78:	sw	s4,44(sp)
    6c7c:	sw	s5,40(sp)
    6c80:	sw	s6,36(sp)
    6c84:	sw	s7,32(sp)
    6c88:	sw	s8,28(sp)
    6c8c:	sw	s9,24(sp)
    6c90:	addi	t6,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    6c94:	beqz	a4,6e0c <.L48>
    6c98:	lui	t2,0x67110
    6c9c:	lui	t4,0x45000
    6ca0:	lw	s5,8(a0)
    6ca4:	lw	s4,4(a0)
    6ca8:	lw	s7,0(a0)
    6cac:	lw	s3,40(a0)
    6cb0:	lw	s2,36(a0)
    6cb4:	lw	s6,32(a0)
    6cb8:	lhu	a4,24(a0)
    6cbc:	lhu	s8,56(a0)
    6cc0:	lw	a7,16(a0)
    6cc4:	lw	a6,48(a0)
    6cc8:	addi	s1,t2,8 # 67110008 <__device_print_strings_info_end+0x60c10008>
    6ccc:	addi	t4,t4,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    6cd0:	addi	t2,t2,1032
    6cd4:	li	t3,0
    6cd8:	lui	a1,0xffb40
    6cdc:	lui	a2,0xffb41
    6ce0:	lui	a3,0xffe80
    6ce4:	li	t0,1
    6ce8:	lw	a5,40(a1) # ffb40028 <__stack_base+0x3f7f8>
    6cec:	zext.h	a5,a5
    6cf0:	beq	a5,a4,6ce8 <.L18>
    6cf4:	lw	a5,40(a2) # ffb41028 <__stack_base+0x407f8>
    6cf8:	zext.h	a5,a5
    6cfc:	beq	a5,s8,6cf4 <.L19>
    6d00:	addi	s9,a7,-1
    6d04:	addi	s8,a6,-1
    6d08:	ttsetadczw	3,0,0,0,0,15
    6d0c:	lw	a5,52(a3) # ffe80034 <__instrn_buffer+0x40034>
    6d10:	andi	a5,a5,254
    6d14:	bnez	a5,6d0c <.L20>
    6d18:	lw	a5,48(gp) # ffb00820 <unp_cfg_context>
    6d1c:	bnez	a5,6de0 <.L21>
    6d20:	sw	s9,304(t6)
    6d24:	sw	s8,496(t6)
    6d28:	sw	zero,52(a3)
    6d2c:	ttstallwait	8,1024
    6d30:	ttmop	1,0,0
    6d34:	ttsemget	32
    6d38:	sw	t0,48(gp) # ffb00820 <unp_cfg_context>
    6d3c:	ttsetc16	41,257
    6d40:	addi	a4,a4,1
    6d44:	zext.h	a4,a4
    6d48:	slli	a5,a4,0x8
    6d4c:	add	a5,a5,t4
    6d50:	sh	a4,24(a0)
    6d54:	sw	a5,0(t1)
    6d58:	ttstallwait	32,6
    6d5c:	sw	s1,0(t1)
    6d60:	add	a7,a7,s5
    6d64:	bltu	a7,s4,6d6c <.L24>
    6d68:	sub	a7,a7,s7
    6d6c:	lhu	s8,56(a0)
    6d70:	sw	a7,16(a0)
    6d74:	addi	s8,s8,1
    6d78:	zext.h	s8,s8
    6d7c:	slli	a5,s8,0x8
    6d80:	add	a5,a5,t4
    6d84:	sh	s8,56(a0)
    6d88:	sw	a5,0(t1)
    6d8c:	ttstallwait	32,6
    6d90:	sw	t2,0(t1)
    6d94:	add	a6,a6,s3
    6d98:	bltu	a6,s2,6da0 <.L25>
    6d9c:	sub	a6,a6,s6
    6da0:	sw	a6,48(a0)
    6da4:	addi	t3,t3,1
    6da8:	bne	s0,t3,6ce8 <.L18>
    6dac:	lw	s1,56(sp)
    6db0:	lw	s2,52(sp)
    6db4:	lw	s3,48(sp)
    6db8:	lw	s4,44(sp)
    6dbc:	lw	s5,40(sp)
    6dc0:	lw	s6,36(sp)
    6dc4:	lw	s7,32(sp)
    6dc8:	lw	s8,28(sp)
    6dcc:	lw	s9,24(sp)
    6dd0:	lw	s0,60(sp)
    6dd4:	li	a0,0
    6dd8:	addi	sp,sp,64
    6ddc:	ret
    6de0:	sw	s9,308(t6)
    6de4:	sw	s8,500(t6)
    6de8:	sw	zero,52(a3)
    6dec:	ttstallwait	8,1024
    6df0:	ttmop	1,0,0
    6df4:	ttsemget	32
    6df8:	sub	s8,t0,a5
    6dfc:	sw	s8,48(gp) # ffb00820 <unp_cfg_context>
    6e00:	bne	a5,t0,6d3c <.L22>
    6e04:	ttsetc16	41,0
    6e08:	j	6d40 <.L23>
    6e0c:	mv	t6,a5
    6e10:	j	6c98 <.L17>
    6e14:	mv	a5,a3
    6e18:	j	6974 <.L4>

######## TRISC1 (math) — kernel=eltwise_binary_no_bcast ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/eltwise_binary_no_bcast/762602881991838469/trisc1/trisc1.elf:     file format elf32-littleriscv
00007110 <_start>:
    7110:	lui	a5,0xffb00
    7114:	addi	a5,a5,48 # ffb00030 <__fw_export_ldm_end+0x10>
    7118:	addi	a4,gp,-2000 # ffb00020 <__fw_export_ldm_end>
    711c:	bltu	a4,a5,7138 <.L2>
    7120:	sw	zero,-4(a5)
    7124:	sw	zero,-8(a5)
    7128:	sw	zero,-12(a5)
    712c:	sw	zero,-16(a5)
    7130:	addi	a5,a5,16
    7134:	bgeu	a4,a5,7120 <.L3>
    7138:	addi	a3,a5,-8
    713c:	bltu	a4,a3,7358 <.L17>
    7140:	sw	zero,-12(a5)
    7144:	sw	zero,-16(a5)
    7148:	addi	a3,a5,-4
    714c:	bltu	a4,a3,7154 <.L5>
    7150:	sw	zero,-8(a5)
    7154:	lui	a4,0x7
    7158:	addi	a4,a4,864 # 7360 <__kernel_data_lma>
    715c:	addi	a5,gp,-2000 # ffb00020 <__fw_export_ldm_end>
    7160:	beq	a4,a5,71c0 <.L7>
    7164:	addi	a2,gp,-2000 # ffb00020 <__fw_export_ldm_end>
    7168:	sub	a2,a2,a5
    716c:	li	a1,8
    7170:	srai	a3,a2,0x2
    7174:	bge	a1,a2,71a4 <.L8>
    7178:	li	a6,2
    717c:	lw	a0,0(a4)
    7180:	lw	a1,4(a4)
    7184:	lw	a2,8(a4)
    7188:	addi	a4,a4,12
    718c:	addi	a5,a5,12
    7190:	addi	a3,a3,-3
    7194:	sw	a0,-12(a5)
    7198:	sw	a1,-8(a5)
    719c:	sw	a2,-4(a5)
    71a0:	blt	a6,a3,717c <.L9>
    71a4:	blez	a3,71c0 <.L7>
    71a8:	lw	a1,0(a4)
    71ac:	li	a2,2
    71b0:	sw	a1,0(a5)
    71b4:	bne	a3,a2,71c0 <.L7>
    71b8:	lw	a4,4(a4)
    71bc:	sw	a4,4(a5)
    71c0:	lw	a4,1056(zero) # 420 <.LASF2151+0x7>
    71c4:	li	a3,128
    71c8:	slli	a4,a4,0x2
    71cc:	lbu	a5,1011(a4)
    71d0:	addi	a4,a4,96
    71d4:	beq	a5,a3,71e4 <.L13>
    71d8:	fence
    71dc:	lbu	a5,915(a4)
    71e0:	bne	a5,a3,71d8 <.L11>
    71e4:	ttsetc16	13,0
    71e8:	ttsetc16	29,0
    71ec:	ttsetc16	48,0
    71f0:	ttzeroacc	3,0,0,1,0
    71f4:	lw	a3,-2016(gp) # ffb00010 <rta_l1_base>
    71f8:	lui	a4,0xffe80
    71fc:	lw	a0,0(a3)
    7200:	li	a5,0
    7204:	addi	a3,a4,4 # ffe80004 <__instrn_buffer+0x40004>
    7208:	sw	a5,0(a3)
    720c:	lw	a5,0(a3)
    7210:	and	zero,zero,a5
    7214:	lw	a5,36(a4)
    7218:	zext.b	a5,a5
    721c:	bnez	a5,7214 <.L12>
    7220:	ttseminit	2,0,2
    7224:	sw	zero,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7228:	ttsetc16	1,0
    722c:	lui	a2,0xffe40
    7230:	lui	a3,0xb3080
    7234:	mv	a2,a2
    7238:	addi	a3,a3,220 # b30800dc <__device_print_strings_info_end+0xacb800dc>
    723c:	sw	a3,0(a2) # ffe40000 <__instrn_buffer>
    7240:	ttstallwait	128,16
    7244:	lui	a3,0xb6800
    7248:	addi	a3,a3,1 # b6800001 <__device_print_strings_info_end+0xb0300001>
    724c:	lui	a1,0xb6200
    7250:	sw	a3,0(a2)
    7254:	addi	a1,a1,1 # b6200001 <__device_print_strings_info_end+0xafd00001>
    7258:	lui	a3,0xb6400
    725c:	sw	a1,0(a2)
    7260:	addi	a3,a3,1 # b6400001 <__device_print_strings_info_end+0xaff00001>
    7264:	sw	a3,0(a2)
    7268:	ttsetc16	12,2056
    726c:	ttsetc16	28,8
    7270:	ttsetc16	47,0
    7274:	ttsetc16	13,0
    7278:	ttsetc16	29,0
    727c:	ttsetc16	48,0
    7280:	ttsetc16	14,32896
    7284:	ttsetc16	30,1024
    7288:	ttsetc16	49,0
    728c:	ttsetc16	15,32896
    7290:	ttsetc16	31,36872
    7294:	ttsetc16	50,0
    7298:	addi	a4,a4,8
    729c:	sw	a5,0(a4)
    72a0:	lw	a5,0(a4)
    72a4:	and	zero,zero,a5
    72a8:	lui	a5,0xffb80
    72ac:	li	a4,4
    72b0:	sw	a4,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    72b4:	li	a4,2
    72b8:	sw	a4,4(a5)
    72bc:	lui	a3,0x2000
    72c0:	lui	a4,0x37cc0
    72c4:	sw	a3,8(a5)
    72c8:	addi	a4,a4,3 # 37cc0003 <__device_print_strings_info_end+0x317c0003>
    72cc:	sw	a4,12(a5)
    72d0:	sw	a3,16(a5)
    72d4:	lui	a4,0x28000
    72d8:	sw	a4,20(a5)
    72dc:	sw	a3,24(a5)
    72e0:	sw	a4,28(a5)
    72e4:	sw	a4,32(a5)
    72e8:	ttsetc16	7,0
    72ec:	ttsetrwc	0,0,0,0,0,15
    72f0:	beqz	a0,7350 <.L14>
    72f4:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    72f8:	li	a3,0
    72fc:	lui	a1,0xb2010
    7300:	li	a6,1
    7304:	ttsemwait	322,2,2
    7308:	snez	a5,a4
    730c:	slli	a5,a5,0x9
    7310:	add	a5,a5,a1
    7314:	sw	a5,0(a2)
    7318:	ttmop	1,0,0
    731c:	ttsetrwc	0,0,0,0,0,4
    7320:	ttstallwait	2,2064
    7324:	ttsempost	2
    7328:	addi	a5,a4,-1 # 27ffffff <__device_print_strings_info_end+0x21afffff>
    732c:	sub	a4,a6,a4
    7330:	ttstallwait	128,2064
    7334:	snez	a5,a5
    7338:	slli	a5,a5,0x9
    733c:	add	a5,a5,a1
    7340:	sw	a5,0(a2)
    7344:	addi	a3,a3,1 # 2000001 <.LASF1511+0x1ff4f7b>
    7348:	bne	a0,a3,7304 <.L15>
    734c:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7350:	li	a0,0
    7354:	ret
    7358:	mv	a5,a3
    735c:	j	7148 <.L4>

######## TRISC2 (pack) — kernel=eltwise_binary_no_bcast ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/eltwise_binary_no_bcast/762602881991838469/trisc2/trisc2.elf:     file format elf32-littleriscv
00007d10 <_start>:
    7d10:	addi	sp,sp,-64
    7d14:	sw	s0,60(sp)
    7d18:	sw	s1,56(sp)
    7d1c:	lui	a5,0xffb01
    7d20:	addi	a5,a5,-2000 # ffb00830 <__fw_export_ldm_end+0x10>
    7d24:	addi	a4,gp,48 # ffb00820 <__fw_export_ldm_end>
    7d28:	bltu	a4,a5,7d44 <.L2>
    7d2c:	sw	zero,-4(a5)
    7d30:	sw	zero,-8(a5)
    7d34:	sw	zero,-12(a5)
    7d38:	sw	zero,-16(a5)
    7d3c:	addi	a5,a5,16
    7d40:	bgeu	a4,a5,7d2c <.L3>
    7d44:	addi	a3,a5,-8
    7d48:	bltu	a4,a3,81c0 <.L22>
    7d4c:	sw	zero,-12(a5)
    7d50:	sw	zero,-16(a5)
    7d54:	addi	a3,a5,-4
    7d58:	bltu	a4,a3,7d60 <.L5>
    7d5c:	sw	zero,-8(a5)
    7d60:	lui	a4,0x8
    7d64:	addi	a4,a4,456 # 81c8 <__kernel_data_lma>
    7d68:	addi	a5,gp,48 # ffb00820 <__fw_export_ldm_end>
    7d6c:	beq	a4,a5,7dcc <.L7>
    7d70:	addi	a2,gp,48 # ffb00820 <__fw_export_ldm_end>
    7d74:	sub	a2,a2,a5
    7d78:	li	a1,8
    7d7c:	srai	a3,a2,0x2
    7d80:	bge	a1,a2,7db0 <.L8>
    7d84:	li	a6,2
    7d88:	lw	a0,0(a4)
    7d8c:	lw	a1,4(a4)
    7d90:	lw	a2,8(a4)
    7d94:	addi	a4,a4,12
    7d98:	addi	a5,a5,12
    7d9c:	addi	a3,a3,-3
    7da0:	sw	a0,-12(a5)
    7da4:	sw	a1,-8(a5)
    7da8:	sw	a2,-4(a5)
    7dac:	blt	a6,a3,7d88 <.L9>
    7db0:	blez	a3,7dcc <.L7>
    7db4:	lw	a1,0(a4)
    7db8:	li	a2,2
    7dbc:	sw	a1,0(a5)
    7dc0:	bne	a3,a2,7dcc <.L7>
    7dc4:	lw	a4,4(a4)
    7dc8:	sw	a4,4(a5)
    7dcc:	lw	a4,1056(zero) # 420 <.LASF139+0x6>
    7dd0:	li	a3,128
    7dd4:	slli	a4,a4,0x2
    7dd8:	lbu	a5,1011(a4)
    7ddc:	addi	a4,a4,96
    7de0:	beq	a5,a3,7df0 <.L13>
    7de4:	fence
    7de8:	lbu	a5,915(a4)
    7dec:	bne	a5,a3,7de4 <.L11>
    7df0:	lw	a5,-2012(gp) # ffb00014 <rta_l1_base>
    7df4:	lui	a7,0xffb00
    7df8:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    7dfc:	addi	a7,a7,32 # ffb00020 <cb_interface>
    7e00:	lw	s0,0(a5)
    7e04:	lw	t1,72(a7)
    7e08:	lui	a5,0xffef0
    7e0c:	beqz	a4,7e14 <.L12>
    7e10:	addi	a5,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    7e14:	lui	t5,0x45000
    7e18:	lui	a2,0xffe40
    7e1c:	mv	a2,a2
    7e20:	addi	t4,t5,56 # 45000038 <__device_print_strings_info_end+0x3eb00038>
    7e24:	lui	a6,0x45002
    7e28:	sw	t4,0(a2) # ffe40000 <__instrn_buffer>
    7e2c:	addi	a6,a6,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    7e30:	lui	a0,0x45020
    7e34:	sw	a6,0(a2)
    7e38:	addi	a0,a0,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    7e3c:	lui	a1,0x45080
    7e40:	sw	a0,0(a2)
    7e44:	addi	a1,a1,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    7e48:	sw	a1,0(a2)
    7e4c:	ttstallwait	128,1
    7e50:	ttwrcfg	28,0,12
    7e54:	ttwrcfg	29,0,13
    7e58:	ttnop
    7e5c:	ttnop
    7e60:	ttatgetm	0
    7e64:	lui	a4,0xb5800
    7e68:	addi	a4,a4,71 # b5800047 <__device_print_strings_info_end+0xaf300047>
    7e6c:	sw	a4,0(a2)
    7e70:	lui	a4,0xb61e1
    7e74:	addi	a4,a4,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    7e78:	sw	a4,0(a2)
    7e7c:	lui	a4,0xb3fc0
    7e80:	addi	a4,a4,2 # b3fc0002 <__device_print_strings_info_end+0xadac0002>
    7e84:	sw	a4,0(a2)
    7e88:	lui	a4,0xb4ff0
    7e8c:	addi	a4,a4,2 # b4ff0002 <__device_print_strings_info_end+0xaeaf0002>
    7e90:	sw	a4,0(a2)
    7e94:	lui	a4,0xb53f0
    7e98:	addi	a4,a4,2 # b53f0002 <__device_print_strings_info_end+0xaeef0002>
    7e9c:	sw	a4,0(a2)
    7ea0:	ttatrelm	0
    7ea4:	lui	a4,0xb5100
    7ea8:	addi	a4,a4,71 # b5100047 <__device_print_strings_info_end+0xaec00047>
    7eac:	sw	a4,0(a2)
    7eb0:	lui	a4,0xb6ff0
    7eb4:	addi	a4,a4,71 # b6ff0047 <__device_print_strings_info_end+0xb0af0047>
    7eb8:	sw	a4,0(a2)
    7ebc:	lui	a3,0x40
    7ec0:	sw	a3,272(a5)
    7ec4:	li	a4,1361
    7ec8:	sw	a4,280(a5)
    7ecc:	ttstallwait	128,8
    7ed0:	lui	a4,0xb3040
    7ed4:	addi	a4,a4,70 # b3040046 <__device_print_strings_info_end+0xacb40046>
    7ed8:	sw	a4,0(a2)
    7edc:	lui	a4,0xb5080
    7ee0:	addi	a4,a4,71 # b5080047 <__device_print_strings_info_end+0xaeb80047>
    7ee4:	sw	a4,0(a2)
    7ee8:	sw	zero,72(a5)
    7eec:	lui	a4,0xffe00
    7ef0:	sw	a3,208(a4) # ffe000d0 <__fw_export_ldm_end+0x2ff8b0>
    7ef4:	sw	zero,12(sp)
    7ef8:	lw	t6,208(a4)
    7efc:	lui	t3,0x1
    7f00:	lui	a3,0x10
    7f04:	addi	a3,a3,-1 # ffff <.LASF1675+0x6bf2>
    7f08:	sw	t6,12(sp)
    7f0c:	sw	t3,112(a5)
    7f10:	sw	a3,96(a5)
    7f14:	sw	zero,80(a5)
    7f18:	sw	t1,64(a4)
    7f1c:	sw	zero,68(a4)
    7f20:	sw	zero,72(a4)
    7f24:	sw	zero,76(a4)
    7f28:	sw	zero,8(sp)
    7f2c:	lw	a5,76(a4)
    7f30:	sw	a5,8(sp)
    7f34:	ttsetadcxx	4,15,0
    7f38:	ttsetc16	37,260
    7f3c:	ttsetc16	38,10272
    7f40:	ttsetc16	39,4384
    7f44:	lui	a3,0xffe80
    7f48:	addi	t1,a3,8 # ffe80008 <__instrn_buffer+0x40008>
    7f4c:	li	a5,0
    7f50:	sw	a5,0(t1)
    7f54:	lw	a5,0(t1)
    7f58:	and	zero,zero,a5
    7f5c:	lui	a5,0xffb80
    7f60:	li	t1,4
    7f64:	sw	t1,0(a5) # ffb80000 <__fw_export_ldm_end+0x7f7e0>
    7f68:	sw	t1,4(a5)
    7f6c:	lui	t1,0x2000
    7f70:	sw	t1,8(a5)
    7f74:	sw	t1,12(a5)
    7f78:	sw	t1,16(a5)
    7f7c:	lui	t3,0x41000
    7f80:	sw	t3,20(a5)
    7f84:	lui	t3,0x41008
    7f88:	sw	t1,24(a5)
    7f8c:	addi	t1,t3,1 # 41008001 <__device_print_strings_info_end+0x3ab08001>
    7f90:	sw	t1,28(a5)
    7f94:	lui	t1,0x41010
    7f98:	sw	t1,32(a5)
    7f9c:	sw	t4,0(a2)
    7fa0:	sw	a6,0(a2)
    7fa4:	sw	a0,0(a2)
    7fa8:	sw	a1,0(a2)
    7fac:	ttstallwait	128,1
    7fb0:	ttwrcfg	28,0,12
    7fb4:	ttwrcfg	29,0,13
    7fb8:	ttnop
    7fbc:	ttnop
    7fc0:	ttsetadcxx	4,15,0
    7fc4:	li	a5,0
    7fc8:	addi	a3,a3,4
    7fcc:	sw	a5,0(a3)
    7fd0:	lw	a5,0(a3)
    7fd4:	and	zero,zero,a5
    7fd8:	sw	zero,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7fdc:	ttstallwait	33,8
    7fe0:	ttsetdmareg	0,0,0,8
    7fe4:	ttsetdmareg	0,512,0,16
    7fe8:	ttstallwait	128,1
    7fec:	lui	t6,0xb0048
    7ff0:	addi	t6,t6,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    7ff4:	sw	t6,0(a2)
    7ff8:	ttdmanop
    7ffc:	ttdmanop
    8000:	ttsetadcxy	4,0,0,0,0,11
    8004:	ttsetadczw	4,0,0,0,0,15
    8008:	beqz	s0,81ac <.L26>
    800c:	sw	s7,32(sp)
    8010:	sw	s8,28(sp)
    8014:	sw	s10,20(sp)
    8018:	lui	t2,0x1000
    801c:	lui	t0,0x67611
    8020:	lw	a0,76(a7)
    8024:	lw	s8,72(a7)
    8028:	lw	s7,68(a7)
    802c:	lw	s10,64(a7)
    8030:	lhu	a4,90(a7)
    8034:	lw	a3,92(a7)
    8038:	lw	a6,84(a7)
    803c:	sw	s2,52(sp)
    8040:	sw	s3,48(sp)
    8044:	sw	s4,44(sp)
    8048:	sw	s5,40(sp)
    804c:	sw	s6,36(sp)
    8050:	sw	s9,24(sp)
    8054:	addi	s5,t5,24
    8058:	addi	t4,t5,25
    805c:	sw	s11,16(sp)
    8060:	addi	t2,t2,-256 # ffff00 <.LASF1675+0xff6af3>
    8064:	addi	t0,t0,-2038 # 6761080a <__device_print_strings_info_end+0x6111080a>
    8068:	li	t1,0
    806c:	li	t3,0
    8070:	lui	a1,0xffb42
    8074:	lui	s6,0x508c0
    8078:	lui	s4,0x800
    807c:	addi	t5,t5,48
    8080:	lui	s3,0x10104
    8084:	li	s2,1
    8088:	lui	s9,0xb0088
    808c:	lw	a5,32(a1) # ffb42020 <__fw_export_ldm_end+0x41800>
    8090:	add	a5,a0,a5
    8094:	zext.h	a5,a5
    8098:	beq	a4,a5,808c <.L15>
    809c:	ttsemwait	1,2,1
    80a0:	add	a5,a3,a6
    80a4:	addi	a5,a5,-1
    80a8:	slli	a3,a5,0x8
    80ac:	srli	a5,a5,0x10
    80b0:	and	a3,a3,t2
    80b4:	slli	a5,a5,0x8
    80b8:	sw	s6,0(a2)
    80bc:	add	a3,a3,s5
    80c0:	or	s11,a5,s4
    80c4:	sw	a3,0(a2)
    80c8:	add	a3,s11,t4
    80cc:	sw	a3,0(a2)
    80d0:	ttstallwait	128,1
    80d4:	ttwrcfg	12,0,69
    80d8:	add	a5,a5,t4
    80dc:	sw	a5,0(a2)
    80e0:	ttdmanop
    80e4:	ttmop	1,0,0
    80e8:	ttsetadczw	4,0,0,0,0,5
    80ec:	ttstallwait	64,8
    80f0:	add	a5,t1,s3
    80f4:	sw	a5,0(a2)
    80f8:	ttsemget	2
    80fc:	xori	a5,t1,1
    8100:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8104:	mv	a3,t6
    8108:	beq	t1,s2,8110 <.L16>
    810c:	addi	a3,s9,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    8110:	sw	a3,0(a2)
    8114:	ttdmanop
    8118:	ttdmanop
    811c:	add	a6,a6,s8
    8120:	addi	a3,a4,1
    8124:	sw	a6,84(a7)
    8128:	zext.h	a4,a3
    812c:	sw	zero,92(a7)
    8130:	slli	a3,a4,0x8
    8134:	bltu	a6,s7,8168 <.L17>
    8138:	sub	a6,a6,s10
    813c:	add	a3,a3,t5
    8140:	sh	a4,90(a7)
    8144:	sw	a6,84(a7)
    8148:	sw	a3,0(a2)
    814c:	ttstallwait	32,8
    8150:	sw	t0,0(a2)
    8154:	addi	t3,t3,1
    8158:	beq	s0,t3,8184 <.L34>
    815c:	mv	t1,a5
    8160:	li	a3,0
    8164:	j	808c <.L15>
    8168:	add	a3,a3,t5
    816c:	sh	a4,90(a7)
    8170:	sw	a3,0(a2)
    8174:	ttstallwait	32,8
    8178:	sw	t0,0(a2)
    817c:	addi	t3,t3,1
    8180:	bne	s0,t3,815c <.L37>
    8184:	lw	s2,52(sp)
    8188:	lw	s3,48(sp)
    818c:	lw	s4,44(sp)
    8190:	lw	s5,40(sp)
    8194:	lw	s6,36(sp)
    8198:	lw	s7,32(sp)
    819c:	lw	s8,28(sp)
    81a0:	lw	s9,24(sp)
    81a4:	lw	s10,20(sp)
    81a8:	lw	s11,16(sp)
    81ac:	lw	s0,60(sp)
    81b0:	lw	s1,56(sp)
    81b4:	li	a0,0
    81b8:	addi	sp,sp,64
    81bc:	ret
    81c0:	mv	a5,a3
    81c4:	j	7d54 <.L4>

######## BRISC (writer) — kernel=writer_interleaved_no_bcast ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/writer_interleaved_no_bcast/1138989873329363473/brisc/brisc.elf:     file format elf32-littleriscv
00004b60 <_start>:
    4b60:	addi	sp,sp,-80
    4b64:	sw	s0,76(sp)
    4b68:	sw	s1,72(sp)
    4b6c:	sw	s2,68(sp)
    4b70:	lui	a5,0xffb01
    4b74:	addi	a5,a5,-960 # ffb00c40 <__fw_export_ldm_end+0x10>
    4b78:	addi	a4,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4b7c:	bltu	a4,a5,4b98 <.L2>
    4b80:	sw	zero,-4(a5)
    4b84:	sw	zero,-8(a5)
    4b88:	sw	zero,-12(a5)
    4b8c:	sw	zero,-16(a5)
    4b90:	addi	a5,a5,16
    4b94:	bgeu	a4,a5,4b80 <.L3>
    4b98:	addi	a3,a5,-8
    4b9c:	bltu	a4,a3,4bac <.L4>
    4ba0:	sw	zero,-12(a5)
    4ba4:	sw	zero,-16(a5)
    4ba8:	mv	a3,a5
    4bac:	addi	a5,a3,-4
    4bb0:	bltu	a4,a5,4bb8 <.L5>
    4bb4:	sw	zero,-8(a3)
    4bb8:	lui	a4,0x5
    4bbc:	addi	a4,a4,-112 # 4f90 <__kernel_data_lma>
    4bc0:	addi	a5,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4bc4:	beq	a4,a5,4c34 <.L7>
    4bc8:	addi	a2,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4bcc:	sub	a2,a2,a5
    4bd0:	li	a1,8
    4bd4:	srai	a3,a2,0x2
    4bd8:	bge	a1,a2,4c18 <.L8>
    4bdc:	li	a2,2
    4be0:	lw	a7,0(a4)
    4be4:	lw	a6,4(a4)
    4be8:	lw	a0,8(a4)
    4bec:	mv	a1,a5
    4bf0:	mv	a5,a4
    4bf4:	addi	a5,a5,12
    4bf8:	addi	a1,a1,12
    4bfc:	addi	a3,a3,-3
    4c00:	mv	a4,a5
    4c04:	mv	a5,a1
    4c08:	sw	a7,-12(a1)
    4c0c:	sw	a6,-8(a1)
    4c10:	sw	a0,-4(a1)
    4c14:	blt	a2,a3,4be0 <.L9>
    4c18:	blez	a3,4c34 <.L7>
    4c1c:	lw	a1,0(a4)
    4c20:	li	a2,2
    4c24:	sw	a1,0(a5)
    4c28:	bne	a3,a2,4c34 <.L7>
    4c2c:	lw	a4,4(a4)
    4c30:	sw	a4,4(a5)
    4c34:	lui	a5,0xffb30
    4c38:	lw	t1,520(a5) # ffb30208 <__fw_export_ldm_end+0x2f5d8>
    4c3c:	lw	a6,552(a5)
    4c40:	lw	a0,516(a5)
    4c44:	lw	a1,512(a5)
    4c48:	lw	a2,556(a5)
    4c4c:	lw	a5,1056(zero) # 420 <.LVUS47>
    4c50:	sw	a1,-1996(gp) # ffb00024 <noc_nonposted_atomics_acked+0x4>
    4c54:	addi	t4,gp,-1984 # ffb00030 <noc_nonposted_writes_num_issued>
    4c58:	addi	t3,gp,-1992 # ffb00028 <noc_nonposted_writes_acked>
    4c5c:	sw	a2,-2004(gp) # ffb0001c <noc_posted_writes_num_issued+0x4>
    4c60:	sw	t1,-1972(gp) # ffb0003c <noc_reads_num_issued+0x4>
    4c64:	sw	a6,4(t4)
    4c68:	slli	a5,a5,0x2
    4c6c:	lbu	a3,1011(a5)
    4c70:	sw	a0,4(t3)
    4c74:	li	a4,128
    4c78:	addi	a5,a5,96
    4c7c:	beq	a3,a4,4c8c <.L14>
    4c80:	fence
    4c84:	lbu	a3,915(a5)
    4c88:	bne	a3,a4,4c80 <.L11>
    4c8c:	lw	a5,-2012(gp) # ffb00014 <rta_l1_base>
    4c90:	lui	a4,0x1
    4c94:	lw	s1,28(a5)
    4c98:	lw	t5,32(a5)
    4c9c:	lw	s0,24(a5)
    4ca0:	lw	a6,20(a5)
    4ca4:	lw	t0,16(a5)
    4ca8:	lw	t2,4(a5)
    4cac:	lw	a3,36(a5)
    4cb0:	lw	a7,8(a5)
    4cb4:	lw	s2,0(a5)
    4cb8:	addi	a5,a4,-2048 # 800 <.LASF1618>
    4cbc:	sw	a5,24(sp)
    4cc0:	mul	t6,s1,t5
    4cc4:	mul	a2,s0,t6
    4cc8:	mul	a1,a6,a2
    4ccc:	mul	a5,t0,a1
    4cd0:	divu	t1,t2,a5
    4cd4:	sltu	a0,t1,a3
    4cd8:	snez	a4,a7
    4cdc:	sw	s2,16(sp)
    4ce0:	and	a4,a4,a0
    4ce4:	beqz	a4,4f78 <.L12>
    4ce8:	remu	a5,t2,a5
    4cec:	sw	s3,64(sp)
    4cf0:	remu	a0,a5,a1
    4cf4:	sw	s4,60(sp)
    4cf8:	divu	a5,a5,a1
    4cfc:	lui	a4,0xffb00
    4d00:	remu	a1,a0,a2
    4d04:	divu	a0,a0,a2
    4d08:	lui	s2,0x92492
    4d0c:	remu	a2,a1,t6
    4d10:	sw	s5,56(sp)
    4d14:	divu	a1,a1,t6
    4d18:	sw	s6,52(sp)
    4d1c:	divu	t6,a2,t5
    4d20:	sw	s8,44(sp)
    4d24:	remu	a2,a2,t5
    4d28:	sw	s10,36(sp)
    4d2c:	sw	s11,32(sp)
    4d30:	sw	s7,48(sp)
    4d34:	addi	a4,a4,1064 # ffb00428 <cb_interface>
    4d38:	addi	s8,gp,-1492 # ffb0021c <bank_to_dram_offset>
    4d3c:	addi	s10,gp,-1960 # ffb00048 <dram_bank_to_noc_xy>
    4d40:	addi	s11,s2,1171 # 92492493 <__device_print_strings_info_end+0x8bf92493>
    4d44:	li	s6,0
    4d48:	mv	s5,t2
    4d4c:	lui	s3,0x2
    4d50:	sltu	t2,s6,a7
    4d54:	addi	s3,s3,146 # 2092 <.LASF1328+0x11>
    4d58:	sltu	s2,a5,t0
    4d5c:	sw	s3,12(sp)
    4d60:	and	s2,t2,s2
    4d64:	mv	s7,t2
    4d68:	mv	s3,a3
    4d6c:	beqz	s2,4f44 <.L26>
    4d70:	lui	s2,0x1
    4d74:	sltu	a3,a0,a6
    4d78:	addi	s2,s2,-2048 # 800 <.LASF1618>
    4d7c:	and	a3,t2,a3
    4d80:	sw	s2,8(sp)
    4d84:	mv	s7,t2
    4d88:	beqz	a3,4f24 <.L24>
    4d8c:	sw	s9,40(sp)
    4d90:	sltu	s4,a1,s0
    4d94:	and	s4,t2,s4
    4d98:	mv	s7,t2
    4d9c:	lui	s2,0xffb42
    4da0:	lui	a3,0xffb30
    4da4:	beqz	s4,4f04 <.L22>
    4da8:	sltu	s4,t6,s1
    4dac:	and	s4,t2,s4
    4db0:	mv	s7,t2
    4db4:	beqz	s4,4ee8 <.L20>
    4db8:	sltu	s9,a2,t5
    4dbc:	and	s9,t2,s9
    4dc0:	mv	s7,t2
    4dc4:	sub	s4,a2,s6
    4dc8:	mv	t2,s6
    4dcc:	beqz	s9,4ecc <.L21>
    4dd0:	lw	a2,32(s2) # ffb42020 <__fw_export_ldm_end+0x413f0>
    4dd4:	zext.h	a2,a2
    4dd8:	lw	s6,40(s2)
    4ddc:	zext.h	s6,s6
    4de0:	beq	a2,s6,4dd8 <.L15>
    4de4:	add	a2,s5,t2
    4de8:	mulhu	s7,a2,s11
    4dec:	lw	s6,24(sp)
    4df0:	srli	s7,s7,0x2
    4df4:	slli	s9,s7,0x3
    4df8:	mul	s6,s7,s6
    4dfc:	sub	s7,s9,s7
    4e00:	sub	a2,a2,s7
    4e04:	lw	s9,16(sp)
    4e08:	sh2add	s7,a2,s8
    4e0c:	sh1add	a2,a2,s10
    4e10:	lw	s7,0(s7)
    4e14:	lhu	a2,14(a2)
    4e18:	add	s6,s6,s9
    4e1c:	add	s6,s6,s7
    4e20:	lw	s7,80(a4)
    4e24:	slli	a2,a2,0x4
    4e28:	lw	s9,64(a3) # ffb30040 <__fw_export_ldm_end+0x2f410>
    4e2c:	bnez	s9,4e28 <.L16>
    4e30:	lw	s9,12(sp)
    4e34:	srli	a2,a2,0x4
    4e38:	sw	s9,28(a3)
    4e3c:	sw	s7,0(a3)
    4e40:	sw	s6,12(a3)
    4e44:	sw	zero,16(a3)
    4e48:	lw	s6,4(t3)
    4e4c:	lw	s7,4(t4)
    4e50:	sw	a2,20(a3)
    4e54:	lw	a2,8(sp)
    4e58:	addi	s7,s7,1
    4e5c:	sw	a2,32(a3)
    4e60:	addi	a2,s6,1
    4e64:	li	s6,1
    4e68:	sw	s6,64(a3)
    4e6c:	sw	s7,4(t4)
    4e70:	sw	a2,4(t3)
    4e74:	lw	s6,516(a3)
    4e78:	bne	s6,a2,4e74 <.L17>
    4e7c:	fence
    4e80:	lw	s6,32(s2)
    4e84:	lw	a2,72(a4)
    4e88:	addi	s6,s6,1
    4e8c:	sw	s6,32(s2)
    4e90:	lw	s7,80(a4)
    4e94:	lw	s6,68(a4)
    4e98:	add	a2,a2,s7
    4e9c:	sw	a2,80(a4)
    4ea0:	bne	a2,s6,4eb0 <.L18>
    4ea4:	lw	s6,64(a4)
    4ea8:	sub	a2,a2,s6
    4eac:	sw	a2,80(a4)
    4eb0:	addi	t2,t2,1
    4eb4:	add	a2,s4,t2
    4eb8:	sltu	a2,a2,t5
    4ebc:	sltu	s7,t2,a7
    4ec0:	and	a2,s7,a2
    4ec4:	bnez	a2,4dd0 <.L19>
    4ec8:	mv	s6,t2
    4ecc:	addi	t6,t6,1
    4ed0:	sltu	t2,t6,s1
    4ed4:	and	t2,s7,t2
    4ed8:	li	a2,0
    4edc:	beqz	t2,4ee8 <.L20>
    4ee0:	sltu	t2,s6,a7
    4ee4:	j	4db8 <.L23>
    4ee8:	addi	a1,a1,1
    4eec:	sltu	t2,a1,s0
    4ef0:	and	t2,s7,t2
    4ef4:	li	t6,0
    4ef8:	beqz	t2,4f04 <.L22>
    4efc:	sltu	t2,s6,a7
    4f00:	j	4da8 <.L25>
    4f04:	addi	a0,a0,1
    4f08:	sltu	a3,a0,a6
    4f0c:	and	a3,s7,a3
    4f10:	li	a1,0
    4f14:	beqz	a3,4f20 <.L77>
    4f18:	sltu	t2,s6,a7
    4f1c:	j	4d90 <.L27>
    4f20:	lw	s9,40(sp)
    4f24:	addi	a5,a5,1
    4f28:	sltu	a3,a5,t0
    4f2c:	and	a3,s7,a3
    4f30:	li	a0,0
    4f34:	beqz	a3,4f40 <.L73>
    4f38:	sltu	t2,s6,a7
    4f3c:	j	4d70 <.L28>
    4f40:	mv	a3,s3
    4f44:	addi	t1,t1,1
    4f48:	sltu	t2,t1,a3
    4f4c:	and	t2,s7,t2
    4f50:	li	a5,0
    4f54:	bnez	t2,4d4c <.L13>
    4f58:	lw	s3,64(sp)
    4f5c:	lw	s4,60(sp)
    4f60:	lw	s5,56(sp)
    4f64:	lw	s6,52(sp)
    4f68:	lw	s7,48(sp)
    4f6c:	lw	s8,44(sp)
    4f70:	lw	s10,36(sp)
    4f74:	lw	s11,32(sp)
    4f78:	lw	s0,76(sp)
    4f7c:	lw	s1,72(sp)
    4f80:	lw	s2,68(sp)
    4f84:	li	a0,0
    4f88:	addi	sp,sp,80
    4f8c:	ret
