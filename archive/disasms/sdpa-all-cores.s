# SDPA Flash Decode — All 5 cores (stripped)

######## NCRISC (reader) — kernel=reader_decode_all ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/reader_decode_all/17235811625424625888/ncrisc/ncrisc.elf:     file format elf32-littleriscv
00005f80 <_start>:
    5f80:	lui	a5,0xffb01
    5f84:	lui	a4,0xffb01
    5f88:	addi	a5,a5,-976 # ffb00c30 <__stack_base>
    5f8c:	addi	a4,a4,-984 # ffb00c28 <__ldm_bss_end>
    5f90:	bltu	a4,a5,5fac <.L2>
    5f94:	sw	zero,-4(a5)
    5f98:	sw	zero,-8(a5)
    5f9c:	sw	zero,-12(a5)
    5fa0:	sw	zero,-16(a5)
    5fa4:	addi	a5,a5,16
    5fa8:	bgeu	a4,a5,5f94 <.L3>
    5fac:	addi	a3,a5,-8
    5fb0:	bltu	a4,a3,5fc0 <.L4>
    5fb4:	sw	zero,-12(a5)
    5fb8:	sw	zero,-16(a5)
    5fbc:	mv	a3,a5
    5fc0:	addi	a5,a3,-4
    5fc4:	bltu	a4,a5,5fcc <.L5>
    5fc8:	sw	zero,-8(a3)
    5fcc:	lui	a4,0x7
    5fd0:	addi	a4,a4,-1304 # 6ae8 <__kernel_data_lma>
    5fd4:	addi	a5,gp,1072 # ffb00c20 <noc_reads_num_issued>
    5fd8:	beq	a4,a5,6048 <.L7>
    5fdc:	addi	a2,gp,1072 # ffb00c20 <noc_reads_num_issued>
    5fe0:	sub	a2,a2,a5
    5fe4:	li	a1,8
    5fe8:	srai	a3,a2,0x2
    5fec:	bge	a1,a2,602c <.L8>
    5ff0:	li	a2,2
    5ff4:	lw	a7,0(a4)
    5ff8:	lw	a6,4(a4)
    5ffc:	lw	a0,8(a4)
    6000:	mv	a1,a5
    6004:	mv	a5,a4
    6008:	addi	a5,a5,12
    600c:	addi	a1,a1,12
    6010:	addi	a3,a3,-3
    6014:	mv	a4,a5
    6018:	mv	a5,a1
    601c:	sw	a7,-12(a1)
    6020:	sw	a6,-8(a1)
    6024:	sw	a0,-4(a1)
    6028:	blt	a2,a3,5ff4 <.L9>
    602c:	blez	a3,6048 <.L7>
    6030:	lw	a1,0(a4)
    6034:	li	a2,2
    6038:	sw	a1,0(a5)
    603c:	bne	a3,a2,6048 <.L7>
    6040:	lw	a4,4(a4)
    6044:	sw	a4,4(a5)
    6048:	lui	a5,0xffb20
    604c:	lw	a4,520(a5) # ffb20208 <__stack_base+0x1f5d8>
    6050:	lw	a3,552(a5)
    6054:	lw	a3,516(a5)
    6058:	addi	a2,gp,1072 # ffb00c20 <noc_reads_num_issued>
    605c:	lw	a3,512(a5)
    6060:	lw	a5,556(a5)
    6064:	sw	a4,0(a2)
    6068:	lw	a5,1056(zero) # 420 <.LVUS46+0x1>
    606c:	li	a4,128
    6070:	slli	a5,a5,0x2
    6074:	lbu	a3,1011(a5)
    6078:	addi	a5,a5,96
    607c:	beq	a3,a4,608c <.L14>
    6080:	fence
    6084:	lbu	a3,915(a5)
    6088:	bne	a3,a4,6080 <.L11>
    608c:	lw	a4,-1976(gp) # ffb00038 <rta_l1_base>
    6090:	lw	t1,0(a4)
    6094:	beqz	t1,6940 <.L119>
    6098:	lw	a5,56(a4)
    609c:	addi	sp,sp,-128
    60a0:	sw	s0,124(sp)
    60a4:	li	a1,-1
    60a8:	lw	t5,4(a4)
    60ac:	lw	t4,8(a4)
    60b0:	lw	t3,16(a4)
    60b4:	lw	a7,28(a4)
    60b8:	lw	t2,36(a4)
    60bc:	lw	a6,40(a4)
    60c0:	lw	a3,44(a4)
    60c4:	lw	t6,48(a4)
    60c8:	beq	a5,a1,6948 <.L120>
    60cc:	srli	a1,a5,0x6
    60d0:	srli	a4,a5,0x5
    60d4:	or	a4,a4,a1
    60d8:	srli	a1,a4,0x2
    60dc:	or	a4,a4,a1
    60e0:	addi	a0,a4,1
    60e4:	li	a4,4
    60e8:	minu	a0,a0,a4
    60ec:	slli	a4,a0,0x5
    60f0:	add	a5,a5,a4
    60f4:	remu	s0,a5,a4
    60f8:	li	a1,15
    60fc:	sub	a5,a5,s0
    6100:	divu	a5,a5,a4
    6104:	bltu	a1,a5,612c <.L20>
    6108:	slt	a1,t6,a5
    610c:	li	a4,0
    6110:	blt	t6,a5,6a2c <.L121>
    6114:	add	t6,a1,a4
    6118:	bne	t6,a4,6154 <.L24>
    611c:	lw	s0,124(sp)
    6120:	li	a0,0
    6124:	addi	sp,sp,128
    6128:	ret
    612c:	sub	a1,a1,t6
    6130:	srli	t6,a5,0x4
    6134:	mul	a4,t6,a1
    6138:	andi	a5,a5,15
    613c:	min	s0,a5,a1
    6140:	add	a4,a4,s0
    6144:	add	t6,t6,a4
    6148:	bge	a1,a5,6154 <.L24>
    614c:	addi	t6,t6,1
    6150:	beq	t6,a4,611c <.L72>
    6154:	sw	s1,120(sp)
    6158:	sw	s2,116(sp)
    615c:	sw	s3,112(sp)
    6160:	sw	s4,108(sp)
    6164:	sw	s5,104(sp)
    6168:	sw	s6,100(sp)
    616c:	li	a5,1
    6170:	beq	t2,a5,6a90 <.L122>
    6174:	lw	a5,-1976(gp) # ffb00038 <rta_l1_base>
    6178:	mv	t2,t1
    617c:	sh2add	a5,a3,a5
    6180:	lw	a1,80(a5)
    6184:	lw	t1,84(a5)
    6188:	slli	a1,a1,0x4
    618c:	slli	a5,t1,0xa
    6190:	or	a5,a5,a1
    6194:	lui	t0,0xffb40
    6198:	lui	a1,0xffb00
    619c:	lw	s1,40(t0) # ffb40028 <__stack_base+0x3f3f8>
    61a0:	addi	a1,a1,1044 # ffb00414 <cb_interface>
    61a4:	li	s0,3
    61a8:	fence
    61ac:	lw	s2,32(t0)
    61b0:	lw	t1,12(a1)
    61b4:	add	t1,t1,s2
    61b8:	sub	t1,t1,s1
    61bc:	zext.h	t1,t1
    61c0:	bgeu	s0,t1,61a8 <.L27>
    61c4:	lw	t0,20(a1)
    61c8:	lui	s6,0x1
    61cc:	lui	s5,0x10000
    61d0:	lui	s2,0x1000
    61d4:	add	s6,t0,s6
    61d8:	addi	s5,s5,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    61dc:	addi	s2,s2,-1 # ffffff <.LASF1570+0xfed8cd>
    61e0:	lui	t1,0xffb21
    61e4:	li	s4,1024
    61e8:	li	s3,1
    61ec:	lw	s0,-1984(t1) # ffb20840 <__stack_base+0x1fc10>
    61f0:	bnez	s0,61ec <.L28>
    61f4:	sw	t0,-2036(t1)
    61f8:	sw	t2,-2048(t1)
    61fc:	and	s0,a5,s5
    6200:	sw	s0,-2044(t1)
    6204:	srli	s0,a5,0x4
    6208:	and	s0,s0,s2
    620c:	sw	s0,-2040(t1)
    6210:	sw	s4,-2016(t1)
    6214:	sw	s3,-1984(t1)
    6218:	lw	s0,0(a2)
    621c:	addi	s1,t2,2047
    6220:	addi	s1,s1,1
    6224:	addi	s0,s0,1
    6228:	sltu	t2,s1,t2
    622c:	addi	t0,t0,1024
    6230:	sw	s0,0(a2)
    6234:	add	a5,t2,a5
    6238:	mv	t2,s1
    623c:	bne	t0,s6,61ec <.L28>
    6240:	lui	a5,0xffb20
    6244:	lw	t1,520(a5) # ffb20208 <__stack_base+0x1f5d8>
    6248:	bne	t1,s0,6244 <.L30>
    624c:	fence
    6250:	lui	t0,0xffb40
    6254:	lw	t1,40(t0) # ffb40028 <__stack_base+0x3f3f8>
    6258:	lw	a5,8(a1)
    625c:	addi	t1,t1,4
    6260:	sw	t1,40(t0)
    6264:	lw	t0,20(a1)
    6268:	lw	t1,4(a1)
    626c:	sh2add	a5,a5,t0
    6270:	sw	a5,20(a1)
    6274:	bne	a5,t1,6284 <.L31>
    6278:	lw	t1,0(a1)
    627c:	sub	a5,a5,t1
    6280:	sw	a5,20(a1)
    6284:	li	a5,1088
    6288:	sw	t4,64(sp)
    628c:	sw	t5,48(sp)
    6290:	sw	a5,56(sp)
    6294:	sw	a5,60(sp)
    6298:	sw	a5,72(sp)
    629c:	sw	a5,76(sp)
    62a0:	lui	t4,0xffb49
    62a4:	lw	t1,40(t4) # ffb49028 <__stack_base+0x483f8>
    62a8:	zext.h	t1,t1
    62ac:	fence
    62b0:	lw	t5,32(t4)
    62b4:	lw	a5,300(a1)
    62b8:	add	a5,a5,t5
    62bc:	zext.h	a5,a5
    62c0:	beq	a5,t1,62ac <.L32>
    62c4:	lui	t1,0x92492
    62c8:	addi	t1,t1,1171 # 92492493 <__device_print_strings_info_end+0x8bf92493>
    62cc:	mulhu	t1,a3,t1
    62d0:	addi	a5,a7,-1
    62d4:	srli	t1,t1,0x2
    62d8:	slli	t4,t1,0x3
    62dc:	ori	a5,a5,63
    62e0:	sub	t4,t4,t1
    62e4:	addi	a5,a5,1
    62e8:	sub	a3,a3,t4
    62ec:	mul	a5,a5,t1
    62f0:	addi	s4,gp,-1500 # ffb00214 <bank_to_dram_offset>
    62f4:	addi	s3,gp,-1968 # ffb00040 <dram_bank_to_noc_xy>
    62f8:	sh2add	t1,a3,s4
    62fc:	add	a5,a5,t3
    6300:	sh1add	a3,a3,s3
    6304:	lw	t1,0(t1)
    6308:	lhu	t3,0(a3)
    630c:	lw	t4,308(a1)
    6310:	add	a5,a5,t1
    6314:	slli	s0,t3,0x4
    6318:	lui	t1,0x4
    631c:	mv	a3,a5
    6320:	mv	t3,s0
    6324:	mv	t2,t4
    6328:	bgeu	t1,a7,63f0 <.L33>
    632c:	lui	t5,0xffffc
    6330:	addi	a3,t5,-1 # ffffbfff <__stack_base+0x4fb3cf>
    6334:	add	a3,a7,a3
    6338:	add	t3,t4,t1
    633c:	and	t5,a3,t5
    6340:	lui	s6,0x10000
    6344:	lui	s5,0x1000
    6348:	sw	s7,96(sp)
    634c:	add	t2,t5,t3
    6350:	addi	s6,s6,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    6354:	addi	s5,s5,-1 # ffffff <.LASF1570+0xfed8cd>
    6358:	mv	t3,a5
    635c:	mv	s2,s0
    6360:	mv	s1,t4
    6364:	lui	t0,0xffb21
    6368:	li	s7,1
    636c:	lw	t5,-1984(t0) # ffb20840 <__stack_base+0x1fc10>
    6370:	bnez	t5,636c <.L34>
    6374:	sw	s1,-2036(t0)
    6378:	sw	t3,-2048(t0)
    637c:	and	t5,s2,s6
    6380:	sw	t5,-2044(t0)
    6384:	srli	t5,s2,0x4
    6388:	and	t5,t5,s5
    638c:	sw	t5,-2040(t0)
    6390:	sw	t1,-2016(t0)
    6394:	sw	s7,-1984(t0)
    6398:	lw	t5,0(a2)
    639c:	add	s1,s1,t1
    63a0:	addi	t5,t5,1
    63a4:	sw	t5,0(a2)
    63a8:	add	t5,t3,t1
    63ac:	sltu	t3,t5,t3
    63b0:	add	s2,t3,s2
    63b4:	mv	t3,t5
    63b8:	bne	s1,t2,636c <.L34>
    63bc:	srli	a3,a3,0xe
    63c0:	sub	t1,a7,t1
    63c4:	slli	a7,a3,0xe
    63c8:	addi	a3,a3,1
    63cc:	sub	a7,t1,a7
    63d0:	slli	t1,a3,0xe
    63d4:	add	t1,a5,t1
    63d8:	srli	a3,a3,0x12
    63dc:	add	t3,s0,a3
    63e0:	sltu	a5,t1,a5
    63e4:	lw	s7,96(sp)
    63e8:	mv	a3,t1
    63ec:	add	t3,a5,t3
    63f0:	lui	a5,0xffb21
    63f4:	lw	t1,-1984(a5) # ffb20840 <__stack_base+0x1fc10>
    63f8:	bnez	t1,63f4 <.L36>
    63fc:	lui	t1,0x10000
    6400:	sw	t2,-2036(a5)
    6404:	addi	t1,t1,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    6408:	sw	a3,-2048(a5)
    640c:	and	a3,t3,t1
    6410:	sw	a3,-2044(a5)
    6414:	srli	t3,t3,0x4
    6418:	sw	t3,-2040(a5)
    641c:	sw	a7,-2016(a5)
    6420:	li	a3,1
    6424:	sw	a3,-1984(a5)
    6428:	lw	a5,0(a2)
    642c:	lui	a3,0xffb20
    6430:	addi	a5,a5,1
    6434:	sw	a5,0(a2)
    6438:	lw	a7,520(a3) # ffb20208 <__stack_base+0x1f5d8>
    643c:	bne	a7,a5,6438 <.L37>
    6440:	fence
    6444:	lui	a7,0xffb49
    6448:	lw	a3,40(a7) # ffb49028 <__stack_base+0x483f8>
    644c:	lw	a5,296(a1)
    6450:	addi	a3,a3,1
    6454:	sw	a3,40(a7)
    6458:	lw	a7,308(a1)
    645c:	lw	a3,292(a1)
    6460:	add	a5,a5,a7
    6464:	sw	a5,308(a1)
    6468:	bne	a5,a3,6478 <.L38>
    646c:	lw	a3,288(a1)
    6470:	sub	a5,a5,a3
    6474:	sw	a5,308(a1)
    6478:	li	a5,-1
    647c:	beq	a6,a5,6a68 <.L116>
    6480:	bgeu	a4,t6,6a68 <.L116>
    6484:	slli	a5,a0,0x4
    6488:	slli	a3,a0,0x2
    648c:	addi	t0,a4,1
    6490:	mul	a4,a3,a4
    6494:	add	a5,a5,a0
    6498:	mul	t1,t0,a3
    649c:	lui	a0,0x1
    64a0:	slli	t2,a6,0x2
    64a4:	sw	s9,88(sp)
    64a8:	sw	s11,80(sp)
    64ac:	lui	s9,0xffffc
    64b0:	lui	a7,0x10000
    64b4:	lui	t3,0x1000
    64b8:	slli	s11,a5,0x6
    64bc:	addi	a5,a0,256 # 1100 <.LLST241>
    64c0:	sw	s10,84(sp)
    64c4:	add	s0,a4,t4
    64c8:	add	a6,t1,t4
    64cc:	sw	a5,32(sp)
    64d0:	mv	s5,t6
    64d4:	sw	s7,96(sp)
    64d8:	mv	t6,t2
    64dc:	sw	s8,92(sp)
    64e0:	addi	s10,s9,-1 # ffffbfff <__stack_base+0x4fb3cf>
    64e4:	addi	a7,a7,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    64e8:	addi	t3,t3,-1 # ffffff <.LASF1570+0xfed8cd>
    64ec:	lui	a4,0x4
    64f0:	lui	a5,0xffb21
    64f4:	li	t1,1
    64f8:	mv	t2,t0
    64fc:	lui	t5,0xffb41
    6500:	lw	t0,40(t5) # ffb41028 <__stack_base+0x403f8>
    6504:	fence
    6508:	lw	t4,32(t5)
    650c:	lw	a0,44(a1)
    6510:	add	a0,a0,t4
    6514:	sub	a0,a0,t0
    6518:	zext.h	a0,a0
    651c:	blt	a0,a3,6504 <.L40>
    6520:	lui	a0,0x92492
    6524:	addi	a0,a0,1171 # 92492493 <__device_print_strings_info_end+0x8bf92493>
    6528:	lw	t5,52(a1)
    652c:	sw	a0,12(sp)
    6530:	mv	t4,s0
    6534:	li	s6,0
    6538:	lui	s7,0xffb20
    653c:	sw	a3,36(sp)
    6540:	sw	s5,40(sp)
    6544:	sw	t6,24(sp)
    6548:	sw	s0,44(sp)
    654c:	sw	a6,28(sp)
    6550:	lw	s1,0(t4)
    6554:	lw	a3,24(sp)
    6558:	mv	s5,t5
    655c:	sw	t5,16(sp)
    6560:	sw	t4,20(sp)
    6564:	sh3add	s1,s1,a3
    6568:	addi	s8,s1,4
    656c:	lw	a3,12(sp)
    6570:	lw	a0,56(sp)
    6574:	mulhu	a3,s1,a3
    6578:	lw	t4,48(sp)
    657c:	srli	a3,a3,0x2
    6580:	slli	a6,a3,0x3
    6584:	mul	a0,a3,a0
    6588:	sub	a3,a6,a3
    658c:	sub	a3,s1,a3
    6590:	sh2add	a6,a3,s4
    6594:	sh1add	a3,a3,s3
    6598:	lw	a6,0(a6)
    659c:	lhu	s2,0(a3)
    65a0:	add	a0,a0,t4
    65a4:	lw	s0,60(sp)
    65a8:	add	t0,a0,a6
    65ac:	slli	s2,s2,0x4
    65b0:	mv	a0,t0
    65b4:	mv	a3,s2
    65b8:	mv	t6,s5
    65bc:	bgeu	a4,s0,6658 <.L44>
    65c0:	add	t5,s0,s10
    65c4:	and	t6,t5,s9
    65c8:	add	t6,t6,a4
    65cc:	add	t6,t6,s5
    65d0:	mv	a3,t0
    65d4:	mv	a6,s2
    65d8:	mv	a0,s5
    65dc:	lw	t4,-1984(a5) # ffb20840 <__stack_base+0x1fc10>
    65e0:	bnez	t4,65dc <.L42>
    65e4:	sw	a0,-2036(a5)
    65e8:	sw	a3,-2048(a5)
    65ec:	and	t4,a6,a7
    65f0:	sw	t4,-2044(a5)
    65f4:	srli	t4,a6,0x4
    65f8:	and	t4,t4,t3
    65fc:	sw	t4,-2040(a5)
    6600:	sw	a4,-2016(a5)
    6604:	sw	t1,-1984(a5)
    6608:	lw	t4,0(a2)
    660c:	add	a0,a0,a4
    6610:	addi	t4,t4,1
    6614:	sw	t4,0(a2)
    6618:	add	t4,a3,a4
    661c:	sltu	a3,t4,a3
    6620:	add	a6,a3,a6
    6624:	mv	a3,t4
    6628:	bne	t6,a0,65dc <.L42>
    662c:	srli	a3,t5,0xe
    6630:	slli	a0,a3,0xe
    6634:	sub	s0,s0,a4
    6638:	addi	a3,a3,1
    663c:	sub	s0,s0,a0
    6640:	slli	a0,a3,0xe
    6644:	add	a0,t0,a0
    6648:	srli	a3,a3,0x12
    664c:	sltu	t0,a0,t0
    6650:	add	a3,s2,a3
    6654:	add	a3,t0,a3
    6658:	lw	t0,-1984(a5)
    665c:	bnez	t0,6658 <.L44>
    6660:	sw	t6,-2036(a5)
    6664:	sw	a0,-2048(a5)
    6668:	and	a0,a3,a7
    666c:	sw	a0,-2044(a5)
    6670:	srli	a3,a3,0x4
    6674:	sw	a3,-2040(a5)
    6678:	sw	s0,-2016(a5)
    667c:	sw	t1,-1984(a5)
    6680:	lw	a3,0(a2)
    6684:	addi	s6,s6,1
    6688:	addi	a3,a3,1
    668c:	sw	a3,0(a2)
    6690:	li	a0,18
    6694:	addi	s1,s1,1
    6698:	add	s5,s5,s11
    669c:	beq	s6,a0,6a3c <.L46>
    66a0:	bne	s1,s8,656c <.L47>
    66a4:	lw	t4,20(sp)
    66a8:	lw	t5,16(sp)
    66ac:	lw	a3,28(sp)
    66b0:	addi	t4,t4,4
    66b4:	addi	t5,t5,1088
    66b8:	bne	a3,t4,6550 <.L48>
    66bc:	lw	a3,36(sp)
    66c0:	lw	s5,40(sp)
    66c4:	lw	t6,24(sp)
    66c8:	lw	s0,44(sp)
    66cc:	lw	a6,28(sp)
    66d0:	lw	t5,0(a2)
    66d4:	lui	t4,0xffb20
    66d8:	lw	a0,520(t4) # ffb20208 <__stack_base+0x1f5d8>
    66dc:	bne	a0,t5,66d8 <.L49>
    66e0:	fence
    66e4:	lui	t5,0xffb41
    66e8:	lw	t4,40(t5) # ffb41028 <__stack_base+0x403f8>
    66ec:	lw	a0,40(a1)
    66f0:	add	t4,a3,t4
    66f4:	sw	t4,40(t5)
    66f8:	mul	a0,a3,a0
    66fc:	lw	t5,52(a1)
    6700:	lw	t4,36(a1)
    6704:	add	a0,a0,t5
    6708:	sw	a0,52(a1)
    670c:	bne	a0,t4,671c <.L50>
    6710:	lw	t4,32(a1)
    6714:	sub	a0,a0,t4
    6718:	sw	a0,52(a1)
    671c:	lui	t5,0xffb42
    6720:	lw	s1,40(t5) # ffb42028 <__stack_base+0x413f8>
    6724:	fence
    6728:	lw	t4,32(t5)
    672c:	lw	a0,76(a1)
    6730:	add	a0,a0,t4
    6734:	sub	a0,a0,s1
    6738:	zext.h	a0,a0
    673c:	blt	a0,a3,6724 <.L51>
    6740:	lw	s2,84(a1)
    6744:	lui	s7,0x92492
    6748:	sw	s5,28(sp)
    674c:	addi	s7,s7,1171 # 92492493 <__device_print_strings_info_end+0x8bf92493>
    6750:	mv	a0,s0
    6754:	sw	a3,24(sp)
    6758:	mv	s5,s2
    675c:	sw	t6,16(sp)
    6760:	sw	s0,36(sp)
    6764:	sw	a6,20(sp)
    6768:	mv	t4,s11
    676c:	lw	s8,0(a0)
    6770:	lw	a3,32(sp)
    6774:	sw	a0,12(sp)
    6778:	add	s11,s5,a3
    677c:	lw	a3,16(sp)
    6780:	sh3add	s8,s8,a3
    6784:	mulhu	a3,s8,s7
    6788:	lw	a0,72(sp)
    678c:	srli	a3,a3,0x2
    6790:	slli	a6,a3,0x3
    6794:	mul	a0,a3,a0
    6798:	sub	a3,a6,a3
    679c:	sub	a3,s8,a3
    67a0:	lw	t5,64(sp)
    67a4:	sh2add	a6,a3,s4
    67a8:	sh1add	a3,a3,s3
    67ac:	lw	a6,0(a6)
    67b0:	lhu	s6,0(a3)
    67b4:	add	a0,a0,t5
    67b8:	lw	s2,76(sp)
    67bc:	add	s1,a0,a6
    67c0:	slli	s6,s6,0x4
    67c4:	mv	a0,s1
    67c8:	mv	a3,s6
    67cc:	mv	s0,s5
    67d0:	bgeu	a4,s2,686c <.L55>
    67d4:	add	t6,s2,s10
    67d8:	and	s0,t6,s9
    67dc:	add	s0,s0,a4
    67e0:	add	s0,s0,s5
    67e4:	mv	a3,s1
    67e8:	mv	a6,s6
    67ec:	mv	a0,s5
    67f0:	lw	t5,-1984(a5)
    67f4:	bnez	t5,67f0 <.L53>
    67f8:	sw	a0,-2036(a5)
    67fc:	sw	a3,-2048(a5)
    6800:	and	t5,a6,a7
    6804:	sw	t5,-2044(a5)
    6808:	srli	t5,a6,0x4
    680c:	and	t5,t5,t3
    6810:	sw	t5,-2040(a5)
    6814:	sw	a4,-2016(a5)
    6818:	sw	t1,-1984(a5)
    681c:	lw	t5,0(a2)
    6820:	add	a0,a0,a4
    6824:	addi	t5,t5,1
    6828:	sw	t5,0(a2)
    682c:	add	t5,a3,a4
    6830:	sltu	a3,t5,a3
    6834:	add	a6,a3,a6
    6838:	mv	a3,t5
    683c:	bne	a0,s0,67f0 <.L53>
    6840:	srli	a3,t6,0xe
    6844:	slli	a0,a3,0xe
    6848:	sub	s2,s2,a4
    684c:	addi	a3,a3,1
    6850:	sub	s2,s2,a0
    6854:	slli	a0,a3,0xe
    6858:	add	a0,s1,a0
    685c:	srli	a3,a3,0x12
    6860:	sltu	s1,a0,s1
    6864:	add	a3,s6,a3
    6868:	add	a3,s1,a3
    686c:	lw	a6,-1984(a5)
    6870:	bnez	a6,686c <.L55>
    6874:	sw	s0,-2036(a5)
    6878:	sw	a0,-2048(a5)
    687c:	and	a0,a3,a7
    6880:	sw	a0,-2044(a5)
    6884:	srli	a3,a3,0x4
    6888:	sw	a3,-2040(a5)
    688c:	sw	s2,-2016(a5)
    6890:	sw	t1,-1984(a5)
    6894:	lw	a3,0(a2)
    6898:	addi	t0,t0,1
    689c:	addi	a3,a3,1
    68a0:	sw	a3,0(a2)
    68a4:	li	a0,18
    68a8:	addi	s8,s8,1
    68ac:	addi	s5,s5,1088
    68b0:	beq	t0,a0,6a50 <.L123>
    68b4:	bne	s5,s11,6784 <.L58>
    68b8:	lw	a0,12(sp)
    68bc:	lw	a3,20(sp)
    68c0:	addi	a0,a0,4
    68c4:	bne	a3,a0,676c <.L59>
    68c8:	lw	a3,24(sp)
    68cc:	lw	s5,28(sp)
    68d0:	lw	t6,16(sp)
    68d4:	lw	s0,36(sp)
    68d8:	lw	a6,20(sp)
    68dc:	lw	t5,0(a2)
    68e0:	mv	s11,t4
    68e4:	lui	t4,0xffb20
    68e8:	lw	a0,520(t4) # ffb20208 <__stack_base+0x1f5d8>
    68ec:	bne	a0,t5,68e8 <.L60>
    68f0:	fence
    68f4:	lui	t5,0xffb42
    68f8:	lw	t4,40(t5) # ffb42028 <__stack_base+0x413f8>
    68fc:	lw	a0,72(a1)
    6900:	add	t4,a3,t4
    6904:	sw	t4,40(t5)
    6908:	mul	a0,a3,a0
    690c:	lw	t5,84(a1)
    6910:	lw	t4,68(a1)
    6914:	add	a0,a0,t5
    6918:	sw	a0,84(a1)
    691c:	bne	a0,t4,692c <.L61>
    6920:	lw	t4,64(a1)
    6924:	sub	a0,a0,t4
    6928:	sw	a0,84(a1)
    692c:	add	a6,a6,a3
    6930:	add	s0,s0,a3
    6934:	bgeu	t2,s5,6aac <.L117>
    6938:	addi	t2,t2,1
    693c:	j	64fc <.L62>
    6940:	li	a0,0
    6944:	ret
    6948:	lui	a0,0xffb48
    694c:	lw	s0,12(a4) # 400c <.LASF2395+0x16>
    6950:	lui	a1,0xffb00
    6954:	lw	a4,40(a0) # ffb48028 <__stack_base+0x473f8>
    6958:	sw	s1,120(sp)
    695c:	addi	a1,a1,1044 # ffb00414 <cb_interface>
    6960:	zext.h	a4,a4
    6964:	fence
    6968:	lw	s1,32(a0)
    696c:	lw	a5,268(a1)
    6970:	add	a5,a5,s1
    6974:	zext.h	a5,a5
    6978:	beq	a4,a5,6964 <.L16>
    697c:	lw	a5,-1500(gp) # ffb00214 <bank_to_dram_offset>
    6980:	lhu	a4,-1968(gp) # ffb00040 <dram_bank_to_noc_xy>
    6984:	lw	a0,276(a1)
    6988:	add	s0,s0,a5
    698c:	slli	a4,a4,0x4
    6990:	lui	a5,0xffb21
    6994:	lw	s1,-1984(a5) # ffb20840 <__stack_base+0x1fc10>
    6998:	bnez	s1,6994 <.L17>
    699c:	sw	a0,-2036(a5)
    69a0:	sw	s0,-2048(a5)
    69a4:	sw	zero,-2044(a5)
    69a8:	srli	a4,a4,0x4
    69ac:	sw	a4,-2040(a5)
    69b0:	li	a4,64
    69b4:	sw	a4,-2016(a5)
    69b8:	li	a4,1
    69bc:	sw	a4,-1984(a5)
    69c0:	lw	a5,0(a2)
    69c4:	lui	a4,0xffb20
    69c8:	addi	a5,a5,1
    69cc:	sw	a5,0(a2)
    69d0:	lw	s0,520(a4) # ffb20208 <__stack_base+0x1f5d8>
    69d4:	bne	s0,a5,69d0 <.L18>
    69d8:	fence
    69dc:	lui	s0,0xffb48
    69e0:	lw	a4,40(s0) # ffb48028 <__stack_base+0x473f8>
    69e4:	lw	a5,264(a1)
    69e8:	addi	a4,a4,1
    69ec:	sw	a4,40(s0)
    69f0:	lw	s0,276(a1)
    69f4:	lw	a4,260(a1)
    69f8:	add	a5,a5,s0
    69fc:	sw	a5,276(a1)
    6a00:	beq	a5,a4,6a1c <.L124>
    6a04:	sh2add	a0,a3,a0
    6a08:	lw	a5,0(a0)
    6a0c:	li	a4,-1
    6a10:	lw	s1,120(sp)
    6a14:	bne	a5,a4,60cc <.L15>
    6a18:	j	611c <.L72>
    6a1c:	lw	a4,256(a1)
    6a20:	sub	a5,a5,a4
    6a24:	sw	a5,276(a1)
    6a28:	j	6a04 <.L19>
    6a2c:	sub	a5,a5,t6
    6a30:	addi	a4,a5,-1
    6a34:	add	t6,a1,a4
    6a38:	j	6118 <.L23>
    6a3c:	lw	a0,520(s7)
    6a40:	bne	a0,a3,6a3c <.L46>
    6a44:	fence
    6a48:	li	s6,0
    6a4c:	j	66a0 <.L45>
    6a50:	lui	a6,0xffb20
    6a54:	lw	a0,520(a6) # ffb20208 <__stack_base+0x1f5d8>
    6a58:	bne	a0,a3,6a54 <.L57>
    6a5c:	fence
    6a60:	li	t0,0
    6a64:	j	68b4 <.L56>
    6a68:	lw	s0,124(sp)
    6a6c:	lw	s1,120(sp)
    6a70:	lw	s2,116(sp)
    6a74:	lw	s3,112(sp)
    6a78:	lw	s4,108(sp)
    6a7c:	lw	s5,104(sp)
    6a80:	lw	s6,100(sp)
    6a84:	li	a0,0
    6a88:	addi	sp,sp,128
    6a8c:	ret
    6a90:	lbu	a5,-1988(gp) # ffb0002c <my_y>
    6a94:	lbu	a1,-1984(gp) # ffb00030 <my_x>
    6a98:	slli	a5,a5,0xa
    6a9c:	slli	a1,a1,0x4
    6aa0:	mv	t2,t1
    6aa4:	or	a5,a5,a1
    6aa8:	j	6194 <.L26>
    6aac:	lw	s0,124(sp)
    6ab0:	lw	s1,120(sp)
    6ab4:	lw	s2,116(sp)
    6ab8:	lw	s3,112(sp)
    6abc:	lw	s4,108(sp)
    6ac0:	lw	s5,104(sp)
    6ac4:	lw	s6,100(sp)
    6ac8:	lw	s7,96(sp)
    6acc:	lw	s8,92(sp)
    6ad0:	lw	s9,88(sp)
    6ad4:	lw	s10,84(sp)
    6ad8:	lw	s11,80(sp)
    6adc:	li	a0,0
    6ae0:	addi	sp,sp,128
    6ae4:	ret

######## TRISC0 (unpack) — kernel=sdpa_flash_decode ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/sdpa_flash_decode/862833422394369673/trisc0/trisc0.elf:     file format elf32-littleriscv
00006930 <_start>:
    6930:	addi	sp,sp,-16
    6934:	sw	ra,12(sp)
    6938:	lui	a5,0xffb01
    693c:	lui	a4,0xffb01
    6940:	addi	a5,a5,-1488 # ffb00a30 <__stack_base>
    6944:	addi	a4,a4,-1500 # ffb00a24 <__ldm_bss_end>
    6948:	bltu	a4,a5,6964 <.L489>
    694c:	sw	zero,-4(a5)
    6950:	sw	zero,-8(a5)
    6954:	sw	zero,-12(a5)
    6958:	sw	zero,-16(a5)
    695c:	addi	a5,a5,16
    6960:	bgeu	a4,a5,694c <.L490>
    6964:	addi	a3,a5,-8
    6968:	bltu	a4,a3,6a34 <.L501>
    696c:	sw	zero,-12(a5)
    6970:	sw	zero,-16(a5)
    6974:	addi	a3,a5,-4
    6978:	bltu	a4,a3,6980 <.L492>
    697c:	sw	zero,-8(a5)
    6980:	lui	a4,0xa
    6984:	addi	a4,a4,184 # a0b8 <__kernel_data_lma>
    6988:	addi	a5,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    698c:	beq	a4,a5,69f0 <.L494>
    6990:	lui	a2,0xffb01
    6994:	addi	a2,a2,-1504 # ffb00a20 <unp_cfg_context>
    6998:	sub	a2,a2,a5
    699c:	li	a1,8
    69a0:	srai	a3,a2,0x2
    69a4:	bge	a1,a2,69d4 <.L495>
    69a8:	li	a6,2
    69ac:	lw	a0,0(a4)
    69b0:	lw	a1,4(a4)
    69b4:	lw	a2,8(a4)
    69b8:	addi	a4,a4,12
    69bc:	addi	a5,a5,12
    69c0:	addi	a3,a3,-3
    69c4:	sw	a0,-12(a5)
    69c8:	sw	a1,-8(a5)
    69cc:	sw	a2,-4(a5)
    69d0:	blt	a6,a3,69ac <.L496>
    69d4:	blez	a3,69f0 <.L494>
    69d8:	lw	a1,0(a4)
    69dc:	li	a2,2
    69e0:	sw	a1,0(a5)
    69e4:	bne	a3,a2,69f0 <.L494>
    69e8:	lw	a4,4(a4)
    69ec:	sw	a4,4(a5)
    69f0:	lui	a5,0xffb12
    69f4:	sw	zero,104(a5) # ffb12068 <__stack_base+0x11638>
    69f8:	lw	a4,1056(zero) # 420 <.LASF186+0x2>
    69fc:	li	a3,128
    6a00:	slli	a4,a4,0x2
    6a04:	lbu	a5,1011(a4)
    6a08:	addi	a4,a4,96
    6a0c:	beq	a5,a3,6a1c <.L498>
    6a10:	fence
    6a14:	lbu	a5,915(a4)
    6a18:	bne	a5,a3,6a10 <.L499>
    6a1c:	ttzerosrc	0,0,1,3
    6a20:	jal	8354 <_Z11kernel_mainv>
    6a24:	lw	ra,12(sp)
    6a28:	li	a0,0
    6a2c:	addi	sp,sp,16
    6a30:	ret
    6a34:	mv	a5,a3
    6a38:	j	6974 <.L491>
00006a3c <_ZN7ckernel16ckernel_template7programEv>:
    6a3c:	lui	a4,0xffe80
    6a40:	li	a5,0
    6a44:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    6a48:	sw	a5,0(a4)
    6a4c:	lw	a5,0(a4)
    6a50:	and	zero,zero,a5
    6a54:	lw	a4,0(a0)
    6a58:	lui	a5,0xffb80
    6a5c:	sw	a4,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    6a60:	lw	a4,4(a0)
    6a64:	sw	a4,4(a5)
    6a68:	lw	a4,24(a0)
    6a6c:	sw	a4,8(a5)
    6a70:	lw	a4,16(a0)
    6a74:	sw	a4,12(a5)
    6a78:	lw	a4,20(a0)
    6a7c:	sw	a4,16(a5)
    6a80:	lw	a4,8(a0)
    6a84:	sw	a4,20(a5)
    6a88:	lw	a4,12(a0)
    6a8c:	sw	a4,24(a5)
    6a90:	lw	a4,28(a0)
    6a94:	sw	a4,28(a5)
    6a98:	lw	a4,32(a0)
    6a9c:	sw	a4,32(a5)
    6aa0:	ret
00006aa4 <_Z13llk_pop_tileslll.constprop.1>:
    6aa4:	lui	a4,0xffb00
    6aa8:	slli	a5,a0,0x5
    6aac:	addi	a4,a4,32 # ffb00020 <cb_interface>
    6ab0:	add	a4,a4,a5
    6ab4:	lhu	a5,24(a4)
    6ab8:	lui	a6,0x45000
    6abc:	add	a5,a5,a1
    6ac0:	lw	a7,8(a4)
    6ac4:	zext.h	a5,a5
    6ac8:	addi	a6,a6,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    6acc:	slli	a2,a5,0x8
    6ad0:	mul	a1,a1,a7
    6ad4:	lui	a3,0xffe40
    6ad8:	sh	a5,24(a4)
    6adc:	add	a2,a2,a6
    6ae0:	mv	a3,a3
    6ae4:	sw	a2,0(a3) # ffe40000 <__instrn_buffer>
    6ae8:	ttstallwait	32,6
    6aec:	lui	a2,0x3fed0
    6af0:	slli	a5,a0,0xc
    6af4:	srli	a5,a5,0x2
    6af8:	addi	a0,a2,8 # 3fed0008 <__device_print_strings_info_end+0x399d0008>
    6afc:	lui	a2,0x40
    6b00:	addi	a2,a2,-1 # 3ffff <.LASF1241+0x2e72c>
    6b04:	add	a5,a5,a0
    6b08:	and	a5,a5,a2
    6b0c:	lui	a2,0x67100
    6b10:	add	a5,a5,a2
    6b14:	sw	a5,0(a3)
    6b18:	lw	a3,16(a4)
    6b1c:	lw	a5,4(a4)
    6b20:	add	a1,a1,a3
    6b24:	sw	a1,16(a4)
    6b28:	bltu	a1,a5,6b38 <.L3>
    6b2c:	lw	a5,0(a4)
    6b30:	sub	a1,a1,a5
    6b34:	sw	a1,16(a4)
    6b38:	ret
00006b3c <_Z13llk_pop_tileslll.constprop.0>:
    6b3c:	lui	a4,0xffb00
    6b40:	slli	a5,a0,0x5
    6b44:	addi	a4,a4,32 # ffb00020 <cb_interface>
    6b48:	add	a4,a4,a5
    6b4c:	lhu	a5,24(a4)
    6b50:	lui	a1,0x45000
    6b54:	addi	a5,a5,1
    6b58:	zext.h	a5,a5
    6b5c:	addi	a1,a1,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    6b60:	slli	a3,a5,0x8
    6b64:	lui	a2,0xffe40
    6b68:	sh	a5,24(a4)
    6b6c:	mv	a2,a2
    6b70:	add	a5,a3,a1
    6b74:	lw	a3,8(a4)
    6b78:	sw	a5,0(a2) # ffe40000 <__instrn_buffer>
    6b7c:	ttstallwait	32,6
    6b80:	lui	a1,0x3fed0
    6b84:	slli	a5,a0,0xc
    6b88:	srli	a5,a5,0x2
    6b8c:	addi	a0,a1,8 # 3fed0008 <__device_print_strings_info_end+0x399d0008>
    6b90:	lui	a1,0x40
    6b94:	addi	a1,a1,-1 # 3ffff <.LASF1241+0x2e72c>
    6b98:	add	a5,a5,a0
    6b9c:	and	a5,a5,a1
    6ba0:	lui	a1,0x67100
    6ba4:	add	a5,a5,a1
    6ba8:	sw	a5,0(a2)
    6bac:	lw	a5,16(a4)
    6bb0:	lw	a2,4(a4)
    6bb4:	add	a5,a3,a5
    6bb8:	sw	a5,16(a4)
    6bbc:	bltu	a5,a2,6bcc <.L5>
    6bc0:	lw	a3,0(a4)
    6bc4:	sub	a5,a5,a3
    6bc8:	sw	a5,16(a4)
    6bcc:	ret
00006bd0 <_Z14_llk_unpack_A_ILN7ckernel13BroadcastTypeE0ELb0ELNS0_26EltwiseBinaryReuseDestTypeE0ELb1EEvmmm>:
    6bd0:	ttsetadczw	3,0,0,0,0,15
    6bd4:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6bd8:	lui	a3,0xffef0
    6bdc:	beqz	a5,6c48 <.L17>
    6be0:	addi	a6,a3,1200 # ffef04b0 <__instrn_buffer+0xb04b0>
    6be4:	addi	a3,a3,1204
    6be8:	lui	a4,0xffe80
    6bec:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    6bf0:	andi	a5,a5,254
    6bf4:	bnez	a5,6bec <.L9>
    6bf8:	lw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    6bfc:	bnez	a4,6c04 <.L10>
    6c00:	mv	a3,a6
    6c04:	sw	a0,0(a3)
    6c08:	lui	a4,0xffe80
    6c0c:	sw	zero,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    6c10:	andi	a1,a1,7
    6c14:	lw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    6c18:	bnez	a1,6c24 <.L13>
    6c1c:	andi	a2,a2,7
    6c20:	beqz	a2,6c5c <.L19>
    6c24:	ttstallwait	8,1024
    6c28:	ttmop	1,0,0
    6c2c:	ttsemget	32
    6c30:	li	a3,1
    6c34:	sub	a2,a3,a4
    6c38:	sw	a2,560(gp) # ffb00a20 <unp_cfg_context>
    6c3c:	beq	a4,a3,6c54 <.L20>
    6c40:	ttsetc16	41,257
    6c44:	ret
    6c48:	addi	a6,a3,304
    6c4c:	addi	a3,a3,308
    6c50:	j	6be8 <.L8>
    6c54:	ttsetc16	41,0
    6c58:	ret
    6c5c:	lui	a3,0xffec2
    6c60:	lw	a2,0(a3) # ffec2000 <__instrn_buffer+0x82000>
    6c64:	addi	a2,a2,4
    6c68:	slli	a1,a2,0x4
    6c6c:	ttsetc16	5,0
    6c70:	ttrdcfg	52,57
    6c74:	lui	a3,0xffe40
    6c78:	lui	a0,0x45040
    6c7c:	mv	a3,a3
    6c80:	addi	a0,a0,36 # 45040024 <__device_print_strings_info_end+0x3eb40024>
    6c84:	sw	a0,0(a3) # ffe40000 <__instrn_buffer>
    6c88:	ttwrcfg	18,0,57
    6c8c:	lui	a0,0x10
    6c90:	slli	a2,a2,0xc
    6c94:	addi	a0,a0,-256 # ff00 <.LASF608+0xd>
    6c98:	zext.h	a2,a2
    6c9c:	and	a1,a1,a0
    6ca0:	bnez	a4,6d1c <.L14>
    6ca4:	lui	a6,0xb3101
    6ca8:	lui	a0,0xb3ff0
    6cac:	addi	a6,a6,73 # b3101049 <__device_print_strings_info_end+0xacc01049>
    6cb0:	addi	a0,a0,84 # b3ff0054 <__device_print_strings_info_end+0xadaf0054>
    6cb4:	lui	a4,0xb4ff0
    6cb8:	sw	a6,0(a3)
    6cbc:	add	a2,a2,a0
    6cc0:	addi	a4,a4,84 # b4ff0054 <__device_print_strings_info_end+0xaeaf0054>
    6cc4:	sw	a2,0(a3)
    6cc8:	add	a1,a1,a4
    6ccc:	sw	a1,0(a3)
    6cd0:	ttsemwait	8,4,2
    6cd4:	ttstallwait	8,1024
    6cd8:	ttmop	1,0,0
    6cdc:	ttsemget	32
    6ce0:	ttstallwait	2,2
    6ce4:	ttsempost	4
    6ce8:	ttwrcfg	52,0,57
    6cec:	lui	a1,0xb3100
    6cf0:	addi	a1,a1,73 # b3100049 <__device_print_strings_info_end+0xacc00049>
    6cf4:	lui	a2,0xb3ff4
    6cf8:	sw	a1,0(a3)
    6cfc:	addi	a2,a2,84 # b3ff4054 <__device_print_strings_info_end+0xadaf4054>
    6d00:	sw	a2,0(a3)
    6d04:	sw	a4,0(a3)
    6d08:	ttsetc16	5,4
    6d0c:	li	a4,1
    6d10:	sw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    6d14:	ttsetc16	41,257
    6d18:	ret
    6d1c:	lui	a7,0xb3202
    6d20:	lui	a6,0xb5ff0
    6d24:	addi	a7,a7,73 # b3202049 <__device_print_strings_info_end+0xacd02049>
    6d28:	addi	a6,a6,84 # b5ff0054 <__device_print_strings_info_end+0xafaf0054>
    6d2c:	lui	a0,0xb6ff0
    6d30:	sw	a7,0(a3)
    6d34:	add	a2,a2,a6
    6d38:	addi	a0,a0,84 # b6ff0054 <__device_print_strings_info_end+0xb0af0054>
    6d3c:	sw	a2,0(a3)
    6d40:	add	a1,a1,a0
    6d44:	sw	a1,0(a3)
    6d48:	ttsemwait	8,4,2
    6d4c:	ttstallwait	8,1024
    6d50:	ttmop	1,0,0
    6d54:	ttsemget	32
    6d58:	ttstallwait	2,2
    6d5c:	ttsempost	4
    6d60:	ttwrcfg	52,0,57
    6d64:	lui	a1,0xb3200
    6d68:	addi	a1,a1,73 # b3200049 <__device_print_strings_info_end+0xacd00049>
    6d6c:	lui	a2,0xb5ff4
    6d70:	sw	a1,0(a3)
    6d74:	addi	a2,a2,84 # b5ff4054 <__device_print_strings_info_end+0xafaf4054>
    6d78:	sw	a2,0(a3)
    6d7c:	sw	a0,0(a3)
    6d80:	ttsetc16	5,4
    6d84:	j	6c30 <.L12>
00006d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>:
    6d88:	lui	a4,0xffb00
    6d8c:	slli	a5,a0,0x5
    6d90:	addi	a4,a4,32 # ffb00020 <cb_interface>
    6d94:	add	a4,a4,a5
    6d98:	addi	a3,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    6d9c:	addi	a5,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    6da0:	sh2add	a5,a0,a5
    6da4:	sh2add	a0,a0,a3
    6da8:	lw	a3,8(a4)
    6dac:	lw	a2,0(a0)
    6db0:	lw	a4,0(a5)
    6db4:	ttstallwait	128,4
    6db8:	andi	a5,a4,31
    6dbc:	lui	a0,0xb30f0
    6dc0:	addi	a5,a5,-26
    6dc4:	addi	a7,a0,112 # b30f0070 <__device_print_strings_info_end+0xacbf0070>
    6dc8:	slli	a4,a4,0x8
    6dcc:	seqz	a5,a5
    6dd0:	zext.h	a4,a4
    6dd4:	lui	a6,0xb5400
    6dd8:	lui	a1,0xffe40
    6ddc:	mv	a1,a1
    6de0:	add	a4,a4,a7
    6de4:	addi	a6,a6,119 # b5400077 <__device_print_strings_info_end+0xaef00077>
    6de8:	slli	a5,a5,0xe
    6dec:	lui	a7,0x1000
    6df0:	sw	a4,0(a1) # ffe40000 <__instrn_buffer>
    6df4:	add	a5,a5,a6
    6df8:	slli	a3,a3,0x8
    6dfc:	slli	a2,a2,0x8
    6e00:	addi	a0,a0,120
    6e04:	zext.h	a2,a2
    6e08:	addi	a7,a7,-256 # ffff00 <.LASF1241+0xfee62d>
    6e0c:	lui	a6,0x45000
    6e10:	sw	a5,0(a1)
    6e14:	add	a4,a2,a0
    6e18:	and	a5,a3,a7
    6e1c:	addi	a3,a6,74 # 4500004a <__device_print_strings_info_end+0x3eb0004a>
    6e20:	sw	a4,0(a1)
    6e24:	add	a5,a5,a3
    6e28:	sw	a5,0(a1)
    6e2c:	ret
00006e30 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm>:
    6e30:	addi	a5,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    6e34:	add	a5,a5,a0
    6e38:	lui	t1,0xffe40
    6e3c:	lui	a4,0xb4010
    6e40:	addi	sp,sp,-16
    6e44:	addi	a4,a4,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    6e48:	mv	t1,t1
    6e4c:	lbu	a3,256(a5)
    6e50:	sw	a4,0(t1) # ffe40000 <__instrn_buffer>
    6e54:	sw	s0,12(sp)
    6e58:	sw	s1,8(sp)
    6e5c:	sw	s2,4(sp)
    6e60:	li	a4,4
    6e64:	lbu	a6,320(a5)
    6e68:	lbu	a2,384(a5)
    6e6c:	beq	a3,a4,7128 <.L23>
    6e70:	bltu	a4,a3,7118 <.L24>
    6e74:	li	a5,1
    6e78:	beq	a3,a5,70e0 <.L25>
    6e7c:	li	a5,2
    6e80:	bne	a3,a5,7130 <.L27>
    6e84:	ttsetadcxx	3,31,0
    6e88:	lui	a5,0x54400
    6e8c:	li	a4,1
    6e90:	addi	a3,a5,129 # 54400081 <__device_print_strings_info_end+0x4df00081>
    6e94:	bltu	a4,a2,6e9c <.L30>
    6e98:	addi	a3,a5,65
    6e9c:	lui	a4,0xffe80
    6ea0:	li	a5,0
    6ea4:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    6ea8:	sw	a5,0(a4)
    6eac:	lw	a5,0(a4)
    6eb0:	and	zero,zero,a5
    6eb4:	lui	a4,0xffb80
    6eb8:	sw	a6,0(a4) # ffb80000 <__stack_base+0x7f5d0>
    6ebc:	lui	a5,0x42808
    6ec0:	sw	a2,4(a4)
    6ec4:	addi	a5,a5,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    6ec8:	sw	a5,8(a4)
    6ecc:	sw	a3,12(a4)
    6ed0:	lui	a5,0x2000
    6ed4:	lui	a3,0x42008
    6ed8:	sw	a5,16(a4)
    6edc:	addi	a3,a3,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    6ee0:	sw	a3,20(a4)
    6ee4:	sw	a5,24(a4)
    6ee8:	lui	a5,0xffb00
    6eec:	sw	a3,28(a4)
    6ef0:	slli	t3,a0,0x5
    6ef4:	addi	a6,a5,32 # ffb00020 <cb_interface>
    6ef8:	sw	a3,32(a4)
    6efc:	add	a5,a6,t3
    6f00:	lui	a4,0xffb40
    6f04:	slli	a7,a0,0xc
    6f08:	addi	a4,a4,40 # ffb40028 <__stack_base+0x3f5f8>
    6f0c:	lhu	a2,24(a5)
    6f10:	add	a4,a7,a4
    6f14:	li	a3,3
    6f18:	lw	a5,0(a4)
    6f1c:	sub	a5,a5,a2
    6f20:	zext.h	a5,a5
    6f24:	bgeu	a3,a5,6f18 <.L31>
    6f28:	slli	t5,a1,0x5
    6f2c:	add	a5,a6,t5
    6f30:	lui	a4,0xffb40
    6f34:	slli	a1,a1,0xc
    6f38:	addi	a4,a4,40 # ffb40028 <__stack_base+0x3f5f8>
    6f3c:	lhu	a3,24(a5)
    6f40:	add	a4,a1,a4
    6f44:	lw	a5,0(a4)
    6f48:	zext.h	a5,a5
    6f4c:	beq	a3,a5,6f44 <.L32>
    6f50:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6f54:	lui	a5,0xffef0
    6f58:	addi	t6,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    6f5c:	bnez	a4,6f64 <.L34>
    6f60:	mv	t6,a5
    6f64:	lw	t4,560(gp) # ffb00a20 <unp_cfg_context>
    6f68:	li	a2,0
    6f6c:	add	t0,a6,t3
    6f70:	add	s0,a6,t5
    6f74:	lui	a4,0xffe80
    6f78:	li	s2,1
    6f7c:	li	t2,4
    6f80:	lw	a3,16(t0)
    6f84:	lw	a5,8(t0)
    6f88:	lw	a0,16(s0)
    6f8c:	mul	a5,a2,a5
    6f90:	addi	a3,a3,-1
    6f94:	add	a3,a3,a5
    6f98:	addi	a0,a0,-1
    6f9c:	ttsetadczw	3,0,0,0,0,15
    6fa0:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    6fa4:	andi	a5,a5,254
    6fa8:	bnez	a5,6fa0 <.L35>
    6fac:	bnez	t4,70e8 <.L36>
    6fb0:	sw	a3,304(t6)
    6fb4:	sw	a0,496(t6)
    6fb8:	sw	zero,52(a4)
    6fbc:	ttstallwait	8,1024
    6fc0:	ttmop	1,0,0
    6fc4:	ttsemget	32
    6fc8:	li	t4,1
    6fcc:	ttsetc16	41,257
    6fd0:	addi	a2,a2,1
    6fd4:	bne	a2,t2,6f80 <.L40>
    6fd8:	add	t3,a6,t3
    6fdc:	lhu	a5,24(t3)
    6fe0:	lui	a3,0x45000
    6fe4:	addi	a5,a5,4
    6fe8:	zext.h	a5,a5
    6fec:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    6ff0:	slli	a4,a5,0x8
    6ff4:	sh	a5,24(t3)
    6ff8:	add	a5,a4,a3
    6ffc:	sw	t4,560(gp) # ffb00a20 <unp_cfg_context>
    7000:	lw	a4,8(t3)
    7004:	sw	a5,0(t1)
    7008:	ttstallwait	32,6
    700c:	lui	a2,0x3fed0
    7010:	srli	a5,a7,0x2
    7014:	addi	a2,a2,8 # 3fed0008 <__device_print_strings_info_end+0x399d0008>
    7018:	lui	a3,0x40
    701c:	addi	a3,a3,-1 # 3ffff <.LASF1241+0x2e72c>
    7020:	add	a5,a5,a2
    7024:	and	a5,a5,a3
    7028:	lui	a3,0x67100
    702c:	add	a5,a5,a3
    7030:	sw	a5,0(t1)
    7034:	lw	a5,16(t3)
    7038:	lw	a3,4(t3)
    703c:	sh2add	a5,a4,a5
    7040:	sw	a5,16(t3)
    7044:	bltu	a5,a3,7054 <.L41>
    7048:	lw	a4,0(t3)
    704c:	sub	a5,a5,a4
    7050:	sw	a5,16(t3)
    7054:	add	a5,a6,t5
    7058:	lhu	a4,24(a5)
    705c:	lui	a2,0x45000
    7060:	addi	a4,a4,1
    7064:	zext.h	a4,a4
    7068:	addi	a2,a2,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    706c:	slli	a3,a4,0x8
    7070:	sh	a4,24(a5)
    7074:	add	a4,a3,a2
    7078:	lw	a3,8(a5)
    707c:	sw	a4,0(t1)
    7080:	ttstallwait	32,6
    7084:	lui	a2,0x3fed0
    7088:	srli	a4,a1,0x2
    708c:	addi	a1,a2,8 # 3fed0008 <__device_print_strings_info_end+0x399d0008>
    7090:	lui	a2,0x40
    7094:	addi	a2,a2,-1 # 3ffff <.LASF1241+0x2e72c>
    7098:	add	a4,a4,a1
    709c:	and	a4,a4,a2
    70a0:	lui	a2,0x67100
    70a4:	add	a4,a4,a2
    70a8:	sw	a4,0(t1)
    70ac:	lw	a4,16(a5)
    70b0:	lw	a2,4(a5)
    70b4:	add	a4,a3,a4
    70b8:	sw	a4,16(a5)
    70bc:	bltu	a4,a2,70cc <.L22>
    70c0:	lw	a3,0(a5)
    70c4:	sub	a4,a4,a3
    70c8:	sw	a4,16(a5)
    70cc:	lw	s0,12(sp)
    70d0:	lw	s1,8(sp)
    70d4:	lw	s2,4(sp)
    70d8:	addi	sp,sp,16
    70dc:	ret
    70e0:	ttsetadcxx	3,15,0
    70e4:	j	6e88 <.L29>
    70e8:	sw	a3,308(t6)
    70ec:	sw	a0,500(t6)
    70f0:	sw	zero,52(a4)
    70f4:	ttstallwait	8,1024
    70f8:	ttmop	1,0,0
    70fc:	ttsemget	32
    7100:	bne	t4,s2,7110 <.L38>
    7104:	ttsetc16	41,0
    7108:	li	t4,0
    710c:	j	6fd0 <.L39>
    7110:	sub	t4,s2,t4
    7114:	j	6fcc <.L37>
    7118:	li	a5,8
    711c:	bne	a3,a5,7130 <.L27>
    7120:	ttsetadcxx	3,127,0
    7124:	j	6e88 <.L29>
    7128:	ttsetadcxx	3,63,0
    712c:	j	6e88 <.L29>
    7130:	ttsetadcxx	3,255,0
    7134:	j	6e88 <.L29>
00007138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>:
    7138:	lui	a4,0xffb00
    713c:	slli	a5,a0,0x5
    7140:	addi	a4,a4,32 # ffb00020 <cb_interface>
    7144:	add	a4,a4,a5
    7148:	addi	a3,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    714c:	addi	a5,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    7150:	sh2add	a5,a0,a5
    7154:	sh2add	a0,a0,a3
    7158:	lw	a3,8(a4)
    715c:	lw	a2,0(a0)
    7160:	lw	a4,0(a5)
    7164:	ttstallwait	128,2
    7168:	andi	a5,a4,31
    716c:	lui	a0,0xb30f0
    7170:	addi	a5,a5,-26
    7174:	addi	a7,a0,64 # b30f0040 <__device_print_strings_info_end+0xacbf0040>
    7178:	slli	a4,a4,0x8
    717c:	seqz	a5,a5
    7180:	zext.h	a4,a4
    7184:	lui	a6,0xb5400
    7188:	lui	a1,0xffe40
    718c:	mv	a1,a1
    7190:	add	a4,a4,a7
    7194:	addi	a6,a6,71 # b5400047 <__device_print_strings_info_end+0xaef00047>
    7198:	slli	a5,a5,0xe
    719c:	lui	a7,0x1000
    71a0:	sw	a4,0(a1) # ffe40000 <__instrn_buffer>
    71a4:	add	a5,a5,a6
    71a8:	slli	a3,a3,0x8
    71ac:	slli	a2,a2,0x8
    71b0:	addi	a0,a0,72
    71b4:	zext.h	a2,a2
    71b8:	addi	a7,a7,-256 # ffff00 <.LASF1241+0xfee62d>
    71bc:	lui	a6,0x45000
    71c0:	sw	a5,0(a1)
    71c4:	add	a4,a2,a0
    71c8:	and	a5,a3,a7
    71cc:	addi	a3,a6,72 # 45000048 <__device_print_strings_info_end+0x3eb00048>
    71d0:	sw	a4,0(a1)
    71d4:	add	a5,a5,a3
    71d8:	sw	a5,0(a1)
    71dc:	ret
000071e0 <_Z17add_block_inplaceILb1EEvmmm.constprop.0>:
    71e0:	lui	t4,0xffe40
    71e4:	lui	a5,0xb4010
    71e8:	addi	sp,sp,-16
    71ec:	mv	t4,t4
    71f0:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    71f4:	sw	s0,12(sp)
    71f8:	sw	a5,0(t4) # ffe40000 <__instrn_buffer>
    71fc:	ttsetadcxx	3,255,0
    7200:	lui	a4,0xffe80
    7204:	li	a5,0
    7208:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    720c:	sw	a5,0(a4)
    7210:	lw	a5,0(a4)
    7214:	and	zero,zero,a5
    7218:	lui	a5,0xffb80
    721c:	li	a4,1
    7220:	sw	a4,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    7224:	li	a4,2
    7228:	sw	a4,4(a5)
    722c:	lui	a4,0x2000
    7230:	sw	a4,8(a5)
    7234:	sw	a4,12(a5)
    7238:	sw	a4,16(a5)
    723c:	lui	a4,0x42008
    7240:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    7244:	sw	a4,20(a5)
    7248:	lui	a4,0x42808
    724c:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    7250:	sw	a4,24(a5)
    7254:	sw	a4,28(a5)
    7258:	lui	a6,0xffb00
    725c:	sw	a4,32(a5)
    7260:	addi	a6,a6,32 # ffb00020 <cb_interface>
    7264:	lhu	a2,856(a6)
    7268:	lui	a3,0xffb5a
    726c:	li	a4,3
    7270:	lw	a5,40(a3) # ffb5a028 <__stack_base+0x595f8>
    7274:	sub	a5,a5,a2
    7278:	zext.h	a5,a5
    727c:	bgeu	a4,a5,7270 <.L52>
    7280:	slli	t6,a0,0x5
    7284:	lui	a5,0xffb40
    7288:	add	a4,a6,t6
    728c:	slli	t5,a0,0xc
    7290:	addi	a5,a5,40 # ffb40028 <__stack_base+0x3f5f8>
    7294:	lhu	a2,24(a4)
    7298:	li	a3,3
    729c:	add	a4,t5,a5
    72a0:	lw	a5,0(a4)
    72a4:	sub	a5,a5,a2
    72a8:	zext.h	a5,a5
    72ac:	bgeu	a3,a5,72a0 <.L53>
    72b0:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    72b4:	lui	a5,0xffef0
    72b8:	addi	t1,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    72bc:	bnez	a4,72c4 <.L55>
    72c0:	mv	t1,a5
    72c4:	lw	a7,560(gp) # ffb00a20 <unp_cfg_context>
    72c8:	li	a1,0
    72cc:	add	t3,a6,t6
    72d0:	lui	a4,0xffe80
    72d4:	li	t2,1
    72d8:	li	t0,4
    72dc:	lw	a2,848(a6)
    72e0:	lw	a0,840(a6)
    72e4:	lw	a3,16(t3)
    72e8:	lw	a5,8(t3)
    72ec:	mul	a0,a1,a0
    72f0:	addi	a2,a2,-1 # 670fffff <__device_print_strings_info_end+0x60bfffff>
    72f4:	mul	a5,a1,a5
    72f8:	addi	a3,a3,-1
    72fc:	add	a2,a2,a0
    7300:	add	a3,a3,a5
    7304:	ttsetadczw	3,0,0,0,0,15
    7308:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    730c:	andi	a5,a5,254
    7310:	bnez	a5,7308 <.L56>
    7314:	bnez	a7,7420 <.L57>
    7318:	sw	a2,304(t1)
    731c:	sw	a3,496(t1)
    7320:	sw	zero,52(a4)
    7324:	ttstallwait	8,1024
    7328:	ttmop	1,0,0
    732c:	ttsemget	32
    7330:	li	a7,1
    7334:	ttsetc16	41,257
    7338:	addi	a1,a1,1
    733c:	bne	a1,t0,72dc <.L61>
    7340:	lhu	a5,856(a6)
    7344:	lui	a3,0x45000
    7348:	addi	a5,a5,4
    734c:	zext.h	a5,a5
    7350:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    7354:	slli	a4,a5,0x8
    7358:	sh	a5,856(a6)
    735c:	add	a4,a4,a3
    7360:	sw	a4,0(t4)
    7364:	lw	a5,840(a6)
    7368:	sw	a7,560(gp) # ffb00a20 <unp_cfg_context>
    736c:	ttstallwait	32,6
    7370:	lui	a4,0x67117
    7374:	lw	a2,848(a6)
    7378:	addi	a4,a4,-2040 # 67116808 <__device_print_strings_info_end+0x60c16808>
    737c:	lw	a3,836(a6)
    7380:	sh2add	a5,a5,a2
    7384:	sw	a4,0(t4)
    7388:	sw	a5,848(a6)
    738c:	bltu	a5,a3,739c <.L62>
    7390:	lw	a4,832(a6)
    7394:	sub	a5,a5,a4
    7398:	sw	a5,848(a6)
    739c:	add	a6,a6,t6
    73a0:	lhu	a5,24(a6)
    73a4:	lui	a3,0x45000
    73a8:	addi	a5,a5,4
    73ac:	zext.h	a5,a5
    73b0:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    73b4:	slli	a4,a5,0x8
    73b8:	sh	a5,24(a6)
    73bc:	add	a5,a4,a3
    73c0:	lw	a4,8(a6)
    73c4:	sw	a5,0(t4)
    73c8:	ttstallwait	32,6
    73cc:	lui	a2,0x3fed0
    73d0:	srli	a5,t5,0x2
    73d4:	addi	a2,a2,8 # 3fed0008 <__device_print_strings_info_end+0x399d0008>
    73d8:	lui	a3,0x40
    73dc:	addi	a3,a3,-1 # 3ffff <.LASF1241+0x2e72c>
    73e0:	add	a5,a5,a2
    73e4:	and	a5,a5,a3
    73e8:	lui	a3,0x67100
    73ec:	add	a5,a5,a3
    73f0:	sw	a5,0(t4)
    73f4:	lw	a5,16(a6)
    73f8:	lw	a3,4(a6)
    73fc:	sh2add	a5,a4,a5
    7400:	sw	a5,16(a6)
    7404:	bltu	a5,a3,7414 <.L51>
    7408:	lw	a4,0(a6)
    740c:	sub	a5,a5,a4
    7410:	sw	a5,16(a6)
    7414:	lw	s0,12(sp)
    7418:	addi	sp,sp,16
    741c:	ret
    7420:	sw	a2,308(t1)
    7424:	sw	a3,500(t1)
    7428:	sw	zero,52(a4)
    742c:	ttstallwait	8,1024
    7430:	ttmop	1,0,0
    7434:	ttsemget	32
    7438:	bne	a7,t2,7448 <.L59>
    743c:	ttsetc16	41,0
    7440:	li	a7,0
    7444:	j	7338 <.L60>
    7448:	sub	a7,t2,a7
    744c:	j	7334 <.L58>
00007450 <_Z17llk_unpack_A_initILN7ckernel13BroadcastTypeE0ELb0ELNS0_26EltwiseBinaryReuseDestTypeE0ELb1EEvmmm.constprop.2>:
    7450:	addi	a5,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    7454:	addi	a4,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    7458:	sh2add	a2,a0,a5
    745c:	sh2add	a3,a0,a4
    7460:	lw	a4,0(a2)
    7464:	lw	a3,0(a3) # 67100000 <__device_print_strings_info_end+0x60c00000>
    7468:	add	a5,a5,a0
    746c:	or	a4,a4,a3
    7470:	andi	a4,a4,7
    7474:	lbu	a3,256(a5)
    7478:	lbu	a2,448(a5)
    747c:	bnez	a4,7518 <.L85>
    7480:	lui	a1,0x1
    7484:	addi	a1,a1,-2048 # 800 <.LASF2683+0x2>
    7488:	lui	a0,0xffb12
    748c:	lui	a5,0xffe40
    7490:	lui	a4,0xb4010
    7494:	mv	a5,a5
    7498:	sw	a1,104(a0) # ffb12068 <__stack_base+0x11638>
    749c:	addi	a4,a4,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    74a0:	sw	a4,0(a5) # ffe40000 <__instrn_buffer>
    74a4:	li	a5,4
    74a8:	beq	a3,a5,75b8 <.L86>
    74ac:	bltu	a5,a3,75d8 <.L76>
    74b0:	li	a5,1
    74b4:	beq	a3,a5,75f0 <.L77>
    74b8:	li	a5,2
    74bc:	bne	a3,a5,75e8 <.L83>
    74c0:	ttsetadcxx	1,31,0
    74c4:	lui	a4,0xffe80
    74c8:	li	a5,0
    74cc:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    74d0:	sw	a5,0(a4)
    74d4:	lw	a5,0(a4)
    74d8:	and	zero,zero,a5
    74dc:	lui	a5,0xffb80
    74e0:	sw	a2,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    74e4:	li	a4,1
    74e8:	sw	a4,4(a5)
    74ec:	lui	a3,0x2000
    74f0:	sw	a3,8(a5)
    74f4:	sw	a3,12(a5)
    74f8:	lui	a4,0x42088
    74fc:	sw	a3,16(a5)
    7500:	addi	a4,a4,129 # 42088081 <__device_print_strings_info_end+0x3bb88081>
    7504:	sw	a4,20(a5)
    7508:	sw	a3,24(a5)
    750c:	sw	a4,28(a5)
    7510:	sw	a4,32(a5)
    7514:	ret
    7518:	lui	a5,0xffe40
    751c:	lui	a4,0xb4010
    7520:	mv	a5,a5
    7524:	addi	a4,a4,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    7528:	sw	a4,0(a5) # ffe40000 <__instrn_buffer>
    752c:	li	a5,4
    7530:	beq	a3,a5,75b0 <.L87>
    7534:	bltu	a5,a3,75c0 <.L79>
    7538:	li	a5,1
    753c:	beq	a3,a5,75a8 <.L80>
    7540:	li	a5,2
    7544:	bne	a3,a5,75d0 <.L82>
    7548:	ttsetadcxx	1,31,0
    754c:	lui	a4,0xffe80
    7550:	li	a5,0
    7554:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    7558:	sw	a5,0(a4)
    755c:	lw	a5,0(a4)
    7560:	and	zero,zero,a5
    7564:	lui	a5,0xffb80
    7568:	sw	a2,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    756c:	li	a4,1
    7570:	sw	a4,4(a5)
    7574:	lui	a4,0x42008
    7578:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    757c:	sw	a4,8(a5)
    7580:	lui	a3,0x2000
    7584:	sw	a3,12(a5)
    7588:	lui	a4,0x43800
    758c:	sw	a3,16(a5)
    7590:	addi	a4,a4,257 # 43800101 <__device_print_strings_info_end+0x3d300101>
    7594:	sw	a4,20(a5)
    7598:	sw	a3,24(a5)
    759c:	sw	a4,28(a5)
    75a0:	sw	a4,32(a5)
    75a4:	ret
    75a8:	ttsetadcxx	1,15,0
    75ac:	j	754c <.L73>
    75b0:	ttsetadcxx	1,63,0
    75b4:	j	754c <.L73>
    75b8:	ttsetadcxx	1,63,0
    75bc:	j	74c4 <.L75>
    75c0:	li	a5,8
    75c4:	bne	a3,a5,75d0 <.L82>
    75c8:	ttsetadcxx	1,127,0
    75cc:	j	754c <.L73>
    75d0:	ttsetadcxx	1,255,0
    75d4:	j	754c <.L73>
    75d8:	li	a5,8
    75dc:	bne	a3,a5,75e8 <.L83>
    75e0:	ttsetadcxx	1,127,0
    75e4:	j	74c4 <.L75>
    75e8:	ttsetadcxx	1,255,0
    75ec:	j	74c4 <.L75>
    75f0:	ttsetadcxx	1,15,0
    75f4:	j	74c4 <.L75>
000075f8 <_Z17add_block_inplaceILb0EEvmmm.constprop.0>:
    75f8:	lui	t3,0xffe40
    75fc:	lui	a5,0xb4010
    7600:	mv	t3,t3
    7604:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    7608:	sw	a5,0(t3) # ffe40000 <__instrn_buffer>
    760c:	ttsetadcxx	3,255,0
    7610:	lui	a4,0xffe80
    7614:	li	a5,0
    7618:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    761c:	sw	a5,0(a4)
    7620:	lw	a5,0(a4)
    7624:	and	zero,zero,a5
    7628:	lui	a5,0xffb80
    762c:	zext.h	t1,a1
    7630:	li	a4,1
    7634:	sw	a4,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    7638:	li	a4,2
    763c:	sw	a4,4(a5)
    7640:	lui	a4,0x2000
    7644:	sw	a4,8(a5)
    7648:	sw	a4,12(a5)
    764c:	sw	a4,16(a5)
    7650:	lui	a4,0x42008
    7654:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    7658:	sw	a4,20(a5)
    765c:	lui	a4,0x42808
    7660:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    7664:	sw	a4,24(a5)
    7668:	lui	a7,0xffb00
    766c:	sw	a4,28(a5)
    7670:	addi	a7,a7,32 # ffb00020 <cb_interface>
    7674:	lhu	a3,792(a7)
    7678:	sw	a4,32(a5)
    767c:	lui	a4,0xffb58
    7680:	lw	a5,40(a4) # ffb58028 <__stack_base+0x575f8>
    7684:	sub	a5,a5,a3
    7688:	zext.h	a5,a5
    768c:	bltu	a5,t1,7680 <.L89>
    7690:	slli	t5,a0,0x5
    7694:	lui	a5,0xffb40
    7698:	add	a3,a7,t5
    769c:	slli	a4,a0,0xc
    76a0:	addi	a5,a5,40 # ffb40028 <__stack_base+0x3f5f8>
    76a4:	lhu	a3,24(a3) # 2000018 <.LASF1241+0x1fee745>
    76a8:	add	a4,a4,a5
    76ac:	lw	a5,0(a4)
    76b0:	sub	a5,a5,a3
    76b4:	zext.h	a5,a5
    76b8:	bltu	a5,t1,76ac <.L90>
    76bc:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    76c0:	lui	a5,0xffef0
    76c4:	addi	t6,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    76c8:	bnez	a4,76d0 <.L92>
    76cc:	mv	t6,a5
    76d0:	lw	t4,560(gp) # ffb00a20 <unp_cfg_context>
    76d4:	add	t5,a7,t5
    76d8:	li	a0,0
    76dc:	lui	a4,0xffe80
    76e0:	li	t0,1
    76e4:	lw	a2,784(a7)
    76e8:	lw	a6,776(a7)
    76ec:	lw	a3,16(t5)
    76f0:	lw	a5,8(t5)
    76f4:	mul	a6,a0,a6
    76f8:	addi	a2,a2,-1
    76fc:	mul	a5,a0,a5
    7700:	addi	a3,a3,-1
    7704:	add	a2,a2,a6
    7708:	add	a3,a3,a5
    770c:	ttsetadczw	3,0,0,0,0,15
    7710:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    7714:	andi	a5,a5,254
    7718:	bnez	a5,7710 <.L93>
    771c:	bnez	t4,77ac <.L94>
    7720:	sw	a2,304(t6)
    7724:	sw	a3,496(t6)
    7728:	sw	zero,52(a4)
    772c:	ttstallwait	8,1024
    7730:	ttmop	1,0,0
    7734:	ttsemget	32
    7738:	li	t4,1
    773c:	ttsetc16	41,257
    7740:	addi	a0,a0,1
    7744:	bne	a1,a0,76e4 <.L98>
    7748:	lhu	a5,792(a7)
    774c:	lui	a3,0x45000
    7750:	add	a5,t1,a5
    7754:	lw	a2,776(a7)
    7758:	zext.h	a5,a5
    775c:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    7760:	slli	a4,a5,0x8
    7764:	mul	a1,a1,a2
    7768:	add	a4,a4,a3
    776c:	sh	a5,792(a7)
    7770:	sw	t4,560(gp) # ffb00a20 <unp_cfg_context>
    7774:	sw	a4,0(t3)
    7778:	ttstallwait	32,6
    777c:	lw	a5,784(a7)
    7780:	lui	a4,0x67116
    7784:	add	a5,a1,a5
    7788:	lw	a3,772(a7)
    778c:	addi	a4,a4,8 # 67116008 <__device_print_strings_info_end+0x60c16008>
    7790:	sw	a5,784(a7)
    7794:	sw	a4,0(t3)
    7798:	bltu	a5,a3,77a8 <.L88>
    779c:	lw	a4,768(a7)
    77a0:	sub	a5,a5,a4
    77a4:	sw	a5,784(a7)
    77a8:	ret
    77ac:	sw	a2,308(t6)
    77b0:	sw	a3,500(t6)
    77b4:	sw	zero,52(a4)
    77b8:	ttstallwait	8,1024
    77bc:	ttmop	1,0,0
    77c0:	ttsemget	32
    77c4:	bne	t4,t0,77d4 <.L96>
    77c8:	ttsetc16	41,0
    77cc:	li	t4,0
    77d0:	j	7740 <.L97>
    77d4:	sub	t4,t0,t4
    77d8:	j	773c <.L95>
000077dc <_Z10move_blockILb1EEvmmm.constprop.3>:
    77dc:	addi	a1,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    77e0:	addi	a6,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    77e4:	sh2add	a5,a0,a1
    77e8:	sh2add	a4,a0,a6
    77ec:	lw	a5,0(a5)
    77f0:	lw	a4,0(a4)
    77f4:	addi	sp,sp,-48
    77f8:	or	a5,a5,a4
    77fc:	add	a3,a1,a0
    7800:	sw	s0,44(sp)
    7804:	sw	s1,40(sp)
    7808:	sw	s2,36(sp)
    780c:	sw	s3,32(sp)
    7810:	sw	s4,28(sp)
    7814:	sw	s5,24(sp)
    7818:	sw	s6,20(sp)
    781c:	sw	s7,16(sp)
    7820:	sw	s8,12(sp)
    7824:	sw	s9,8(sp)
    7828:	andi	a5,a5,7
    782c:	lbu	a4,256(a3)
    7830:	lbu	a3,448(a3)
    7834:	bnez	a5,78d0 <.L137>
    7838:	lui	a2,0x1
    783c:	addi	a2,a2,-2048 # 800 <.LASF2683+0x2>
    7840:	lui	t1,0xffb12
    7844:	lui	a7,0xffe40
    7848:	lui	a5,0xb4010
    784c:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    7850:	sw	a2,104(t1) # ffb12068 <__stack_base+0x11638>
    7854:	mv	a7,a7
    7858:	sw	a5,0(a7) # ffe40000 <__instrn_buffer>
    785c:	li	a5,4
    7860:	beq	a4,a5,7c58 <.L138>
    7864:	bltu	a5,a4,7b48 <.L111>
    7868:	li	a5,1
    786c:	beq	a4,a5,7c60 <.L112>
    7870:	li	a5,2
    7874:	bne	a4,a5,7c50 <.L118>
    7878:	ttsetadcxx	1,31,0
    787c:	lui	a4,0xffe80
    7880:	li	a5,0
    7884:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    7888:	sw	a5,0(a4)
    788c:	lw	a5,0(a4)
    7890:	and	zero,zero,a5
    7894:	lui	a5,0xffb80
    7898:	sw	a3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    789c:	li	a4,1
    78a0:	sw	a4,4(a5)
    78a4:	lui	a3,0x2000
    78a8:	sw	a3,8(a5)
    78ac:	sw	a3,12(a5)
    78b0:	lui	a4,0x42088
    78b4:	sw	a3,16(a5)
    78b8:	addi	a4,a4,129 # 42088081 <__device_print_strings_info_end+0x3bb88081>
    78bc:	sw	a4,20(a5)
    78c0:	sw	a3,24(a5)
    78c4:	sw	a4,28(a5)
    78c8:	sw	a4,32(a5)
    78cc:	j	795c <.L119>
    78d0:	lui	a7,0xffe40
    78d4:	lui	a5,0xb4010
    78d8:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    78dc:	mv	a7,a7
    78e0:	sw	a5,0(a7) # ffe40000 <__instrn_buffer>
    78e4:	li	a5,4
    78e8:	beq	a4,a5,7b40 <.L139>
    78ec:	bltu	a5,a4,7c38 <.L114>
    78f0:	li	a5,1
    78f4:	beq	a4,a5,7b38 <.L115>
    78f8:	li	a5,2
    78fc:	bne	a4,a5,7c48 <.L117>
    7900:	ttsetadcxx	1,31,0
    7904:	lui	a4,0xffe80
    7908:	li	a5,0
    790c:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    7910:	sw	a5,0(a4)
    7914:	lw	a5,0(a4)
    7918:	and	zero,zero,a5
    791c:	lui	a5,0xffb80
    7920:	sw	a3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    7924:	li	a4,1
    7928:	sw	a4,4(a5)
    792c:	lui	a4,0x42008
    7930:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    7934:	sw	a4,8(a5)
    7938:	lui	a3,0x2000
    793c:	sw	a3,12(a5)
    7940:	lui	a4,0x43800
    7944:	sw	a3,16(a5)
    7948:	addi	a4,a4,257 # 43800101 <__device_print_strings_info_end+0x3d300101>
    794c:	sw	a4,20(a5)
    7950:	sw	a3,24(a5)
    7954:	sw	a4,28(a5)
    7958:	sw	a4,32(a5)
    795c:	lui	t3,0xffb00
    7960:	addi	t3,t3,32 # ffb00020 <cb_interface>
    7964:	slli	s2,a0,0x5
    7968:	add	a5,t3,s2
    796c:	lui	a4,0xffb40
    7970:	addi	a4,a4,40 # ffb40028 <__stack_base+0x3f5f8>
    7974:	slli	t5,a0,0xc
    7978:	lhu	a2,24(a5)
    797c:	add	a4,t5,a4
    7980:	li	a3,3
    7984:	lw	a5,0(a4)
    7988:	sub	a5,a5,a2
    798c:	zext.h	a5,a5
    7990:	bgeu	a3,a5,7984 <.L120>
    7994:	sh2add	a1,a0,a1
    7998:	sh2add	a0,a0,a6
    799c:	lw	t4,0(a1)
    79a0:	lw	t0,0(a0)
    79a4:	lui	s1,0x45040
    79a8:	lui	s0,0x10
    79ac:	lui	s7,0xb3202
    79b0:	lui	s6,0xb5ff0
    79b4:	lui	t2,0xb6ff0
    79b8:	lui	s5,0xb3200
    79bc:	lui	s4,0xb5ff4
    79c0:	lui	s3,0xb3101
    79c4:	lw	a1,560(gp) # ffb00a20 <unp_cfg_context>
    79c8:	andi	t4,t4,7
    79cc:	andi	t0,t0,7
    79d0:	addi	s1,s1,36 # 45040024 <__device_print_strings_info_end+0x3eb40024>
    79d4:	addi	s0,s0,-256 # ff00 <.LASF608+0xd>
    79d8:	addi	s7,s7,73 # b3202049 <__device_print_strings_info_end+0xacd02049>
    79dc:	addi	s6,s6,84 # b5ff0054 <__device_print_strings_info_end+0xafaf0054>
    79e0:	addi	t2,t2,84 # b6ff0054 <__device_print_strings_info_end+0xb0af0054>
    79e4:	addi	s5,s5,73 # b3200049 <__device_print_strings_info_end+0xacd00049>
    79e8:	addi	s4,s4,84 # b5ff4054 <__device_print_strings_info_end+0xafaf4054>
    79ec:	addi	s3,s3,73 # b3101049 <__device_print_strings_info_end+0xacc01049>
    79f0:	li	a2,0
    79f4:	add	t1,t3,s2
    79f8:	lui	a0,0xffef0
    79fc:	lui	a4,0xffe80
    7a00:	lw	a3,16(t1)
    7a04:	lw	a5,8(t1)
    7a08:	addi	a3,a3,-1 # 1ffffff <.LASF1241+0x1fee72c>
    7a0c:	mul	a5,a2,a5
    7a10:	add	a3,a3,a5
    7a14:	ttsetadczw	3,0,0,0,0,15
    7a18:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    7a1c:	addi	s9,a0,304 # ffef0130 <__instrn_buffer+0xb0130>
    7a20:	addi	s8,a0,308
    7a24:	beqz	a5,7a30 <.L122>
    7a28:	addi	s9,a0,1200
    7a2c:	addi	s8,a0,1204
    7a30:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    7a34:	andi	a5,a5,254
    7a38:	bnez	a5,7a30 <.L122>
    7a3c:	bnez	a1,7a44 <.L123>
    7a40:	mv	s8,s9
    7a44:	sw	a3,0(s8)
    7a48:	sw	zero,52(a4)
    7a4c:	lw	a5,560(gp) # ffb00a20 <unp_cfg_context>
    7a50:	bnez	t4,7a58 <.L126>
    7a54:	beqz	t0,7b58 <.L140>
    7a58:	ttstallwait	8,1024
    7a5c:	ttmop	1,0,0
    7a60:	ttsemget	32
    7a64:	li	a3,1
    7a68:	sub	a1,a3,a5
    7a6c:	sw	a1,560(gp) # ffb00a20 <unp_cfg_context>
    7a70:	beq	a5,a3,7b2c <.L141>
    7a74:	ttsetc16	41,257
    7a78:	addi	a2,a2,1
    7a7c:	li	a5,4
    7a80:	bne	a2,a5,7a00 <.L130>
    7a84:	add	t3,t3,s2
    7a88:	lhu	a5,24(t3)
    7a8c:	lui	a3,0x45000
    7a90:	add	a5,a5,a2
    7a94:	zext.h	a5,a5
    7a98:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    7a9c:	slli	a4,a5,0x8
    7aa0:	sh	a5,24(t3)
    7aa4:	add	a5,a4,a3
    7aa8:	lw	a4,8(t3)
    7aac:	sw	a5,0(a7)
    7ab0:	ttstallwait	32,6
    7ab4:	lui	a2,0x3fed0
    7ab8:	srli	a5,t5,0x2
    7abc:	addi	a2,a2,8 # 3fed0008 <__device_print_strings_info_end+0x399d0008>
    7ac0:	lui	a3,0x40
    7ac4:	addi	a3,a3,-1 # 3ffff <.LASF1241+0x2e72c>
    7ac8:	add	a5,a5,a2
    7acc:	and	a5,a5,a3
    7ad0:	lui	a3,0x67100
    7ad4:	add	a5,a5,a3
    7ad8:	sw	a5,0(a7)
    7adc:	lw	a5,16(t3)
    7ae0:	lw	a3,4(t3)
    7ae4:	sh2add	a5,a4,a5
    7ae8:	sw	a5,16(t3)
    7aec:	bltu	a5,a3,7afc <.L105>
    7af0:	lw	a4,0(t3)
    7af4:	sub	a5,a5,a4
    7af8:	sw	a5,16(t3)
    7afc:	lw	s0,44(sp)
    7b00:	lw	s1,40(sp)
    7b04:	lw	s2,36(sp)
    7b08:	lw	s3,32(sp)
    7b0c:	lw	s4,28(sp)
    7b10:	lw	s5,24(sp)
    7b14:	lw	s6,20(sp)
    7b18:	lw	s7,16(sp)
    7b1c:	lw	s8,12(sp)
    7b20:	lw	s9,8(sp)
    7b24:	addi	sp,sp,48
    7b28:	ret
    7b2c:	ttsetc16	41,0
    7b30:	li	a1,0
    7b34:	j	7a78 <.L129>
    7b38:	ttsetadcxx	1,15,0
    7b3c:	j	7904 <.L108>
    7b40:	ttsetadcxx	1,63,0
    7b44:	j	7904 <.L108>
    7b48:	li	a5,8
    7b4c:	bne	a4,a5,7c50 <.L118>
    7b50:	ttsetadcxx	1,127,0
    7b54:	j	787c <.L110>
    7b58:	lui	a3,0xffec2
    7b5c:	lw	a3,0(a3) # ffec2000 <__instrn_buffer+0x82000>
    7b60:	addi	a3,a3,4
    7b64:	slli	a1,a3,0x4
    7b68:	ttsetc16	5,0
    7b6c:	ttrdcfg	52,57
    7b70:	sw	s1,0(a7)
    7b74:	ttwrcfg	18,0,57
    7b78:	slli	a3,a3,0xc
    7b7c:	and	a1,a1,s0
    7b80:	zext.h	a3,a3
    7b84:	bnez	a5,7bf4 <.L127>
    7b88:	lui	a5,0xb3ff0
    7b8c:	addi	a5,a5,84 # b3ff0054 <__device_print_strings_info_end+0xadaf0054>
    7b90:	add	a3,a3,a5
    7b94:	lui	a5,0xb4ff0
    7b98:	sw	s3,0(a7)
    7b9c:	addi	a5,a5,84 # b4ff0054 <__device_print_strings_info_end+0xaeaf0054>
    7ba0:	sw	a3,0(a7)
    7ba4:	add	a1,a1,a5
    7ba8:	sw	a1,0(a7)
    7bac:	ttsemwait	8,4,2
    7bb0:	ttstallwait	8,1024
    7bb4:	ttmop	1,0,0
    7bb8:	ttsemget	32
    7bbc:	ttstallwait	2,2
    7bc0:	ttsempost	4
    7bc4:	ttwrcfg	52,0,57
    7bc8:	lui	a1,0xb3100
    7bcc:	addi	a1,a1,73 # b3100049 <__device_print_strings_info_end+0xacc00049>
    7bd0:	lui	a3,0xb3ff4
    7bd4:	sw	a1,0(a7)
    7bd8:	addi	a3,a3,84 # b3ff4054 <__device_print_strings_info_end+0xadaf4054>
    7bdc:	sw	a3,0(a7)
    7be0:	sw	a5,0(a7)
    7be4:	ttsetc16	5,4
    7be8:	li	a1,1
    7bec:	sw	a1,560(gp) # ffb00a20 <unp_cfg_context>
    7bf0:	j	7a74 <.L128>
    7bf4:	sw	s7,0(a7)
    7bf8:	add	a3,a3,s6
    7bfc:	sw	a3,0(a7)
    7c00:	add	a1,a1,t2
    7c04:	sw	a1,0(a7)
    7c08:	ttsemwait	8,4,2
    7c0c:	ttstallwait	8,1024
    7c10:	ttmop	1,0,0
    7c14:	ttsemget	32
    7c18:	ttstallwait	2,2
    7c1c:	ttsempost	4
    7c20:	ttwrcfg	52,0,57
    7c24:	sw	s5,0(a7)
    7c28:	sw	s4,0(a7)
    7c2c:	sw	t2,0(a7)
    7c30:	ttsetc16	5,4
    7c34:	j	7a64 <.L125>
    7c38:	li	a5,8
    7c3c:	bne	a4,a5,7c48 <.L117>
    7c40:	ttsetadcxx	1,127,0
    7c44:	j	7904 <.L108>
    7c48:	ttsetadcxx	1,255,0
    7c4c:	j	7904 <.L108>
    7c50:	ttsetadcxx	1,255,0
    7c54:	j	787c <.L110>
    7c58:	ttsetadcxx	1,63,0
    7c5c:	j	787c <.L110>
    7c60:	ttsetadcxx	1,15,0
    7c64:	j	787c <.L110>
00007c68 <_Z10move_blockILb1EEvmmm.constprop.2>:
    7c68:	addi	a6,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    7c6c:	addi	t1,gp,48 # ffb00820 <_ZL17unpack_dst_format>
    7c70:	sh2add	a5,a0,a6
    7c74:	sh2add	a4,a0,t1
    7c78:	lw	a5,0(a5)
    7c7c:	lw	a4,0(a4)
    7c80:	add	a3,a6,a0
    7c84:	or	a5,a5,a4
    7c88:	andi	a5,a5,7
    7c8c:	lbu	a4,256(a3)
    7c90:	lbu	a3,448(a3)
    7c94:	bnez	a5,7d30 <.L172>
    7c98:	lui	a2,0x1
    7c9c:	addi	a2,a2,-2048 # 800 <.LASF2683+0x2>
    7ca0:	lui	a1,0xffb12
    7ca4:	lui	a7,0xffe40
    7ca8:	lui	a5,0xb4010
    7cac:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    7cb0:	sw	a2,104(a1) # ffb12068 <__stack_base+0x11638>
    7cb4:	mv	a7,a7
    7cb8:	sw	a5,0(a7) # ffe40000 <__instrn_buffer>
    7cbc:	li	a5,4
    7cc0:	beq	a4,a5,806c <.L173>
    7cc4:	bltu	a5,a4,7f10 <.L148>
    7cc8:	li	a5,1
    7ccc:	beq	a4,a5,8074 <.L149>
    7cd0:	li	a5,2
    7cd4:	bne	a4,a5,8064 <.L155>
    7cd8:	ttsetadcxx	1,31,0
    7cdc:	lui	a4,0xffe80
    7ce0:	li	a5,0
    7ce4:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    7ce8:	sw	a5,0(a4)
    7cec:	lw	a5,0(a4)
    7cf0:	and	zero,zero,a5
    7cf4:	lui	a5,0xffb80
    7cf8:	sw	a3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    7cfc:	li	a4,1
    7d00:	sw	a4,4(a5)
    7d04:	lui	a3,0x2000
    7d08:	sw	a3,8(a5)
    7d0c:	sw	a3,12(a5)
    7d10:	lui	a4,0x42088
    7d14:	sw	a3,16(a5)
    7d18:	addi	a4,a4,129 # 42088081 <__device_print_strings_info_end+0x3bb88081>
    7d1c:	sw	a4,20(a5)
    7d20:	sw	a3,24(a5)
    7d24:	sw	a4,28(a5)
    7d28:	sw	a4,32(a5)
    7d2c:	j	7dbc <.L156>
    7d30:	lui	a7,0xffe40
    7d34:	lui	a5,0xb4010
    7d38:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    7d3c:	mv	a7,a7
    7d40:	sw	a5,0(a7) # ffe40000 <__instrn_buffer>
    7d44:	li	a5,4
    7d48:	beq	a4,a5,7f08 <.L174>
    7d4c:	bltu	a5,a4,7fd8 <.L151>
    7d50:	li	a5,1
    7d54:	beq	a4,a5,7f00 <.L152>
    7d58:	li	a5,2
    7d5c:	bne	a4,a5,805c <.L154>
    7d60:	ttsetadcxx	1,31,0
    7d64:	lui	a4,0xffe80
    7d68:	li	a5,0
    7d6c:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    7d70:	sw	a5,0(a4)
    7d74:	lw	a5,0(a4)
    7d78:	and	zero,zero,a5
    7d7c:	lui	a5,0xffb80
    7d80:	sw	a3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    7d84:	li	a4,1
    7d88:	sw	a4,4(a5)
    7d8c:	lui	a4,0x42008
    7d90:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    7d94:	sw	a4,8(a5)
    7d98:	lui	a3,0x2000
    7d9c:	sw	a3,12(a5)
    7da0:	lui	a4,0x43800
    7da4:	sw	a3,16(a5)
    7da8:	addi	a4,a4,257 # 43800101 <__device_print_strings_info_end+0x3d300101>
    7dac:	sw	a4,20(a5)
    7db0:	sw	a3,24(a5)
    7db4:	sw	a4,28(a5)
    7db8:	sw	a4,32(a5)
    7dbc:	lui	a5,0xffb00
    7dc0:	addi	a3,a5,32 # ffb00020 <cb_interface>
    7dc4:	slli	t3,a0,0x5
    7dc8:	add	a5,a3,t3
    7dcc:	lui	a4,0xffb40
    7dd0:	addi	a4,a4,40 # ffb40028 <__stack_base+0x3f5f8>
    7dd4:	slli	a2,a0,0xc
    7dd8:	lhu	a1,24(a5)
    7ddc:	add	a4,a2,a4
    7de0:	lw	a5,0(a4)
    7de4:	zext.h	a5,a5
    7de8:	beq	a5,a1,7de0 <.L157>
    7dec:	add	a5,a3,t3
    7df0:	sh2add	a6,a0,a6
    7df4:	sh2add	a0,a0,t1
    7df8:	lw	a5,16(a5)
    7dfc:	lw	t1,0(a0)
    7e00:	lw	a6,0(a6)
    7e04:	addi	a0,a5,-1
    7e08:	ttsetadczw	3,0,0,0,0,15
    7e0c:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    7e10:	lui	a1,0xffef0
    7e14:	beqz	a5,7f20 <.L169>
    7e18:	addi	t4,a1,1200 # ffef04b0 <__instrn_buffer+0xb04b0>
    7e1c:	addi	a1,a1,1204
    7e20:	lui	a4,0xffe80
    7e24:	lw	a5,52(a4) # ffe80034 <__instrn_buffer+0x40034>
    7e28:	andi	a5,a5,254
    7e2c:	bnez	a5,7e24 <.L159>
    7e30:	lw	a5,560(gp) # ffb00a20 <unp_cfg_context>
    7e34:	bnez	a5,7e3c <.L160>
    7e38:	mv	a1,t4
    7e3c:	sw	a0,0(a1)
    7e40:	lui	a1,0xffe80
    7e44:	sw	zero,52(a1) # ffe80034 <__instrn_buffer+0x40034>
    7e48:	andi	a5,a6,7
    7e4c:	lw	a1,560(gp) # ffb00a20 <unp_cfg_context>
    7e50:	bnez	a5,7e5c <.L162>
    7e54:	andi	t1,t1,7
    7e58:	beqz	t1,7f2c <.L175>
    7e5c:	ttstallwait	8,1024
    7e60:	ttmop	1,0,0
    7e64:	ttsemget	32
    7e68:	li	a5,1
    7e6c:	sub	a0,a5,a1
    7e70:	sw	a0,560(gp) # ffb00a20 <unp_cfg_context>
    7e74:	beq	a1,a5,7ef8 <.L166>
    7e78:	ttsetc16	41,257
    7e7c:	add	a5,a3,t3
    7e80:	lhu	a4,24(a5)
    7e84:	lui	a1,0x45000
    7e88:	addi	a4,a4,1
    7e8c:	zext.h	a4,a4
    7e90:	addi	a1,a1,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    7e94:	slli	a3,a4,0x8
    7e98:	sh	a4,24(a5)
    7e9c:	add	a4,a3,a1
    7ea0:	lw	a3,8(a5)
    7ea4:	sw	a4,0(a7)
    7ea8:	ttstallwait	32,6
    7eac:	lui	a1,0x3fed0
    7eb0:	srli	a4,a2,0x2
    7eb4:	addi	a1,a1,8 # 3fed0008 <__device_print_strings_info_end+0x399d0008>
    7eb8:	lui	a2,0x40
    7ebc:	addi	a2,a2,-1 # 3ffff <.LASF1241+0x2e72c>
    7ec0:	add	a4,a4,a1
    7ec4:	and	a4,a4,a2
    7ec8:	lui	a2,0x67100
    7ecc:	add	a4,a4,a2
    7ed0:	sw	a4,0(a7)
    7ed4:	lw	a4,16(a5)
    7ed8:	lw	a2,4(a5)
    7edc:	add	a4,a3,a4
    7ee0:	sw	a4,16(a5)
    7ee4:	bltu	a4,a2,7ef4 <.L142>
    7ee8:	lw	a3,0(a5)
    7eec:	sub	a4,a4,a3
    7ef0:	sw	a4,16(a5)
    7ef4:	ret
    7ef8:	ttsetc16	41,0
    7efc:	j	7e7c <.L167>
    7f00:	ttsetadcxx	1,15,0
    7f04:	j	7d64 <.L145>
    7f08:	ttsetadcxx	1,63,0
    7f0c:	j	7d64 <.L145>
    7f10:	li	a5,8
    7f14:	bne	a4,a5,8064 <.L155>
    7f18:	ttsetadcxx	1,127,0
    7f1c:	j	7cdc <.L147>
    7f20:	addi	t4,a1,304
    7f24:	addi	a1,a1,308
    7f28:	j	7e20 <.L158>
    7f2c:	lui	a5,0xffec2
    7f30:	lw	a5,0(a5) # ffec2000 <__instrn_buffer+0x82000>
    7f34:	addi	a5,a5,4
    7f38:	slli	a0,a5,0x4
    7f3c:	ttsetc16	5,0
    7f40:	ttrdcfg	52,57
    7f44:	lui	a6,0x45040
    7f48:	addi	a6,a6,36 # 45040024 <__device_print_strings_info_end+0x3eb40024>
    7f4c:	sw	a6,0(a7)
    7f50:	ttwrcfg	18,0,57
    7f54:	lui	a6,0x10
    7f58:	slli	a5,a5,0xc
    7f5c:	addi	a6,a6,-256 # ff00 <.LASF608+0xd>
    7f60:	zext.h	a5,a5
    7f64:	and	a0,a0,a6
    7f68:	beqz	a1,7fe8 <.L163>
    7f6c:	lui	t4,0xb3202
    7f70:	lui	t1,0xb5ff0
    7f74:	addi	t4,t4,73 # b3202049 <__device_print_strings_info_end+0xacd02049>
    7f78:	addi	t1,t1,84 # b5ff0054 <__device_print_strings_info_end+0xafaf0054>
    7f7c:	lui	a6,0xb6ff0
    7f80:	sw	t4,0(a7)
    7f84:	add	a5,a5,t1
    7f88:	addi	a6,a6,84 # b6ff0054 <__device_print_strings_info_end+0xb0af0054>
    7f8c:	sw	a5,0(a7)
    7f90:	add	a0,a0,a6
    7f94:	sw	a0,0(a7)
    7f98:	ttsemwait	8,4,2
    7f9c:	ttstallwait	8,1024
    7fa0:	ttmop	1,0,0
    7fa4:	ttsemget	32
    7fa8:	ttstallwait	2,2
    7fac:	ttsempost	4
    7fb0:	ttwrcfg	52,0,57
    7fb4:	lui	a0,0xb3200
    7fb8:	addi	a0,a0,73 # b3200049 <__device_print_strings_info_end+0xacd00049>
    7fbc:	lui	a5,0xb5ff4
    7fc0:	sw	a0,0(a7)
    7fc4:	addi	a5,a5,84 # b5ff4054 <__device_print_strings_info_end+0xafaf4054>
    7fc8:	sw	a5,0(a7)
    7fcc:	sw	a6,0(a7)
    7fd0:	ttsetc16	5,4
    7fd4:	j	7e68 <.L164>
    7fd8:	li	a5,8
    7fdc:	bne	a4,a5,805c <.L154>
    7fe0:	ttsetadcxx	1,127,0
    7fe4:	j	7d64 <.L145>
    7fe8:	lui	t1,0xb3101
    7fec:	lui	a6,0xb3ff0
    7ff0:	addi	t1,t1,73 # b3101049 <__device_print_strings_info_end+0xacc01049>
    7ff4:	addi	a6,a6,84 # b3ff0054 <__device_print_strings_info_end+0xadaf0054>
    7ff8:	lui	a1,0xb4ff0
    7ffc:	sw	t1,0(a7)
    8000:	add	a5,a5,a6
    8004:	addi	a1,a1,84 # b4ff0054 <__device_print_strings_info_end+0xaeaf0054>
    8008:	sw	a5,0(a7)
    800c:	add	a0,a0,a1
    8010:	sw	a0,0(a7)
    8014:	ttsemwait	8,4,2
    8018:	ttstallwait	8,1024
    801c:	ttmop	1,0,0
    8020:	ttsemget	32
    8024:	ttstallwait	2,2
    8028:	ttsempost	4
    802c:	ttwrcfg	52,0,57
    8030:	lui	a0,0xb3100
    8034:	addi	a0,a0,73 # b3100049 <__device_print_strings_info_end+0xacc00049>
    8038:	lui	a5,0xb3ff4
    803c:	sw	a0,0(a7)
    8040:	addi	a5,a5,84 # b3ff4054 <__device_print_strings_info_end+0xadaf4054>
    8044:	sw	a5,0(a7)
    8048:	sw	a1,0(a7)
    804c:	ttsetc16	5,4
    8050:	li	a5,1
    8054:	sw	a5,560(gp) # ffb00a20 <unp_cfg_context>
    8058:	j	7e78 <.L165>
    805c:	ttsetadcxx	1,255,0
    8060:	j	7d64 <.L145>
    8064:	ttsetadcxx	1,255,0
    8068:	j	7cdc <.L147>
    806c:	ttsetadcxx	1,63,0
    8070:	j	7cdc <.L147>
    8074:	ttsetadcxx	1,15,0
    8078:	j	7cdc <.L147>
0000807c <_Z10move_blockILb1EEvmmm.constprop.1>:
    807c:	lui	a1,0xffe40
    8080:	lui	a5,0xb4010
    8084:	mv	a1,a1
    8088:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    808c:	sw	a5,0(a1) # ffe40000 <__instrn_buffer>
    8090:	ttsetadcxx	1,255,0
    8094:	lui	a4,0xffe80
    8098:	li	a5,0
    809c:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    80a0:	sw	a5,0(a4)
    80a4:	lw	a5,0(a4)
    80a8:	and	zero,zero,a5
    80ac:	lui	a5,0xffb80
    80b0:	li	a4,2
    80b4:	sw	a4,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    80b8:	li	a4,1
    80bc:	sw	a4,4(a5)
    80c0:	lui	a4,0x42008
    80c4:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    80c8:	sw	a4,8(a5)
    80cc:	lui	a2,0x2000
    80d0:	sw	a2,12(a5)
    80d4:	lui	a3,0x43800
    80d8:	sw	a2,16(a5)
    80dc:	addi	a3,a3,257 # 43800101 <__device_print_strings_info_end+0x3d300101>
    80e0:	sw	a3,20(a5)
    80e4:	sw	a2,24(a5)
    80e8:	lui	a4,0xffb00
    80ec:	sw	a3,28(a5)
    80f0:	addi	a4,a4,32 # ffb00020 <cb_interface>
    80f4:	lhu	a2,888(a4)
    80f8:	sw	a3,32(a5)
    80fc:	lui	a3,0xffb5b
    8100:	lw	a5,40(a3) # ffb5b028 <__stack_base+0x5a5f8>
    8104:	zext.h	a5,a5
    8108:	beq	a5,a2,8100 <.L177>
    810c:	lw	a0,880(a4)
    8110:	addi	a0,a0,-1
    8114:	ttsetadczw	3,0,0,0,0,15
    8118:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    811c:	lui	a2,0xffef0
    8120:	beqz	a5,81d4 <.L184>
    8124:	addi	a6,a2,1200 # ffef04b0 <__instrn_buffer+0xb04b0>
    8128:	addi	a2,a2,1204
    812c:	lui	a3,0xffe80
    8130:	lw	a5,52(a3) # ffe80034 <__instrn_buffer+0x40034>
    8134:	andi	a5,a5,254
    8138:	bnez	a5,8130 <.L179>
    813c:	lw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    8140:	bnez	a3,8148 <.L180>
    8144:	mv	a2,a6
    8148:	sw	a0,0(a2)
    814c:	lui	a3,0xffe80
    8150:	sw	zero,52(a3) # ffe80034 <__instrn_buffer+0x40034>
    8154:	ttstallwait	8,1024
    8158:	ttmop	1,0,0
    815c:	ttsemget	32
    8160:	lw	a2,560(gp) # ffb00a20 <unp_cfg_context>
    8164:	li	a3,1
    8168:	sub	a0,a3,a2
    816c:	sw	a0,560(gp) # ffb00a20 <unp_cfg_context>
    8170:	beq	a2,a3,81e0 <.L181>
    8174:	ttsetc16	41,257
    8178:	lhu	a5,888(a4)
    817c:	lui	a2,0x45000
    8180:	addi	a5,a5,1
    8184:	zext.h	a5,a5
    8188:	addi	a2,a2,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    818c:	slli	a3,a5,0x8
    8190:	sh	a5,888(a4)
    8194:	add	a3,a3,a2
    8198:	sw	a3,0(a1)
    819c:	lw	a5,872(a4)
    81a0:	ttstallwait	32,6
    81a4:	lw	a2,880(a4)
    81a8:	lui	a3,0x67117
    81ac:	add	a5,a5,a2
    81b0:	addi	a3,a3,-1016 # 67116c08 <__device_print_strings_info_end+0x60c16c08>
    81b4:	lw	a2,868(a4)
    81b8:	sw	a5,880(a4)
    81bc:	sw	a3,0(a1)
    81c0:	bltu	a5,a2,81d0 <.L176>
    81c4:	lw	a3,864(a4)
    81c8:	sub	a5,a5,a3
    81cc:	sw	a5,880(a4)
    81d0:	ret
    81d4:	addi	a6,a2,304
    81d8:	addi	a2,a2,308
    81dc:	j	812c <.L178>
    81e0:	ttsetc16	41,0
    81e4:	j	8178 <.L182>
000081e8 <_Z10move_blockILb1EEvmmm.constprop.0>:
    81e8:	lui	a1,0xffe40
    81ec:	lui	a5,0xb4010
    81f0:	mv	a1,a1
    81f4:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    81f8:	sw	a5,0(a1) # ffe40000 <__instrn_buffer>
    81fc:	ttsetadcxx	1,255,0
    8200:	lui	a4,0xffe80
    8204:	li	a5,0
    8208:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    820c:	sw	a5,0(a4)
    8210:	lw	a5,0(a4)
    8214:	and	zero,zero,a5
    8218:	lui	a5,0xffb80
    821c:	li	a4,2
    8220:	sw	a4,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    8224:	li	a4,1
    8228:	sw	a4,4(a5)
    822c:	lui	a4,0x42008
    8230:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    8234:	sw	a4,8(a5)
    8238:	lui	a2,0x2000
    823c:	sw	a2,12(a5)
    8240:	lui	a3,0x43800
    8244:	sw	a2,16(a5)
    8248:	addi	a3,a3,257 # 43800101 <__device_print_strings_info_end+0x3d300101>
    824c:	sw	a3,20(a5)
    8250:	sw	a2,24(a5)
    8254:	lui	a4,0xffb00
    8258:	sw	a3,28(a5)
    825c:	addi	a4,a4,32 # ffb00020 <cb_interface>
    8260:	lhu	a2,952(a4)
    8264:	sw	a3,32(a5)
    8268:	lui	a3,0xffb5d
    826c:	lw	a5,40(a3) # ffb5d028 <__stack_base+0x5c5f8>
    8270:	zext.h	a5,a5
    8274:	beq	a5,a2,826c <.L188>
    8278:	lw	a0,944(a4)
    827c:	addi	a0,a0,-1
    8280:	ttsetadczw	3,0,0,0,0,15
    8284:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    8288:	lui	a2,0xffef0
    828c:	beqz	a5,8340 <.L195>
    8290:	addi	a6,a2,1200 # ffef04b0 <__instrn_buffer+0xb04b0>
    8294:	addi	a2,a2,1204
    8298:	lui	a3,0xffe80
    829c:	lw	a5,52(a3) # ffe80034 <__instrn_buffer+0x40034>
    82a0:	andi	a5,a5,254
    82a4:	bnez	a5,829c <.L190>
    82a8:	lw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    82ac:	bnez	a3,82b4 <.L191>
    82b0:	mv	a2,a6
    82b4:	sw	a0,0(a2)
    82b8:	lui	a3,0xffe80
    82bc:	sw	zero,52(a3) # ffe80034 <__instrn_buffer+0x40034>
    82c0:	ttstallwait	8,1024
    82c4:	ttmop	1,0,0
    82c8:	ttsemget	32
    82cc:	lw	a2,560(gp) # ffb00a20 <unp_cfg_context>
    82d0:	li	a3,1
    82d4:	sub	a0,a3,a2
    82d8:	sw	a0,560(gp) # ffb00a20 <unp_cfg_context>
    82dc:	beq	a2,a3,834c <.L192>
    82e0:	ttsetc16	41,257
    82e4:	lhu	a5,952(a4)
    82e8:	lui	a2,0x45000
    82ec:	addi	a5,a5,1
    82f0:	zext.h	a5,a5
    82f4:	addi	a2,a2,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    82f8:	slli	a3,a5,0x8
    82fc:	sh	a5,952(a4)
    8300:	add	a3,a3,a2
    8304:	sw	a3,0(a1)
    8308:	lw	a5,936(a4)
    830c:	ttstallwait	32,6
    8310:	lw	a2,944(a4)
    8314:	lui	a3,0x67117
    8318:	add	a5,a5,a2
    831c:	addi	a3,a3,1032 # 67117408 <__device_print_strings_info_end+0x60c17408>
    8320:	lw	a2,932(a4)
    8324:	sw	a5,944(a4)
    8328:	sw	a3,0(a1)
    832c:	bltu	a5,a2,833c <.L187>
    8330:	lw	a3,928(a4)
    8334:	sub	a5,a5,a3
    8338:	sw	a5,944(a4)
    833c:	ret
    8340:	addi	a6,a2,304
    8344:	addi	a2,a2,308
    8348:	j	8298 <.L189>
    834c:	ttsetc16	41,0
    8350:	j	82e4 <.L193>
00008354 <_Z11kernel_mainv>:
    8354:	lw	a5,-2012(gp) # ffb00014 <rta_l1_base>
    8358:	addi	sp,sp,-224
    835c:	sw	s0,216(sp)
    8360:	sw	s1,212(sp)
    8364:	lw	s0,0(a5)
    8368:	lw	s1,24(a5)
    836c:	sw	s3,204(sp)
    8370:	sw	s4,200(sp)
    8374:	lw	s3,16(a5)
    8378:	lw	s4,12(a5)
    837c:	sw	s9,180(sp)
    8380:	addi	a1,a5,48
    8384:	lw	s9,28(a5)
    8388:	lw	a5,32(a5)
    838c:	li	a2,24
    8390:	addi	a0,sp,100
    8394:	sw	ra,220(sp)
    8398:	sw	a5,28(sp)
    839c:	jal	9f8c <memcpy>
    83a0:	li	a5,65
    83a4:	bne	s0,a5,83ac <.LM1674>
    83a8:	j	974c <.L198>
    83ac:	li	a5,-1
    83b0:	bne	s1,a5,83b8 <.L200>
    83b4:	j	976c <.L469>
    83b8:	srli	a4,s1,0x6
    83bc:	srli	a5,s1,0x5
    83c0:	or	a5,a5,a4
    83c4:	srli	a4,a5,0x2
    83c8:	or	a5,a5,a4
    83cc:	sw	s11,172(sp)
    83d0:	addi	s11,a5,1
    83d4:	li	a5,4
    83d8:	minu	s11,s11,a5
    83dc:	slli	a5,s11,0x5
    83e0:	add	s1,a5,s1
    83e4:	remu	a3,s1,a5
    83e8:	li	a4,15
    83ec:	sub	s1,s1,a3
    83f0:	divu	a5,s1,a5
    83f4:	bgeu	a4,a5,83fc <.LBB5812>
    83f8:	j	97c8 <.L202>
    83fc:	slt	t3,s3,a5
    8400:	li	a0,0
    8404:	bge	s3,a5,840c <.LM1703>
    8408:	j	9eec <.L470>
    840c:	add	t3,t3,a0
    8410:	bne	t3,a0,8418 <.L206>
    8414:	j	9748 <.L468>
    8418:	lw	a3,100(sp)
    841c:	sw	s2,208(sp)
    8420:	sw	s6,192(sp)
    8424:	sw	s10,176(sp)
    8428:	li	a4,1
    842c:	bltu	a3,a5,8438 <.L208>
    8430:	li	a3,-1
    8434:	li	a4,0
    8438:	lw	a2,104(sp)
    843c:	sw	a3,76(sp)
    8440:	bgeu	a2,a5,8448 <.LM1722>
    8444:	j	9ec8 <.L471>
    8448:	li	a2,-1
    844c:	lw	a1,108(sp)
    8450:	sw	a2,80(sp)
    8454:	mv	a3,a4
    8458:	bgeu	a1,a5,8460 <.L372>
    845c:	j	9ee0 <.L472>
    8460:	li	a1,-1
    8464:	lw	a2,112(sp)
    8468:	sw	a1,84(sp)
    846c:	bgeu	a2,a5,8474 <.LM1737>
    8470:	j	9ebc <.L473>
    8474:	li	a2,-1
    8478:	lw	a1,116(sp)
    847c:	sw	a2,88(sp)
    8480:	bgeu	a1,a5,8488 <.LM1744>
    8484:	j	9eb0 <.L474>
    8488:	li	a1,-1
    848c:	lw	a2,120(sp)
    8490:	sw	a1,92(sp)
    8494:	bgeu	a2,a5,849c <.LM1751>
    8498:	j	9ea4 <.L213>
    849c:	li	a2,-1
    84a0:	lui	s2,0xffb00
    84a4:	addi	s2,s2,32 # ffb00020 <cb_interface>
    84a8:	sw	a2,96(sp)
    84ac:	lw	a1,40(s2)
    84b0:	lw	a2,8(s2)
    84b4:	lui	a6,0xffe80
    84b8:	lw	a5,52(a6) # ffe80034 <__instrn_buffer+0x40034>
    84bc:	zext.b	a5,a5
    84c0:	bnez	a5,84b8 <.L207>
    84c4:	ttsetadcxy	3,0,0,0,0,11
    84c8:	ttsetadczw	3,0,0,0,0,15
    84cc:	lw	a7,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    84d0:	lui	a5,0xffef0
    84d4:	beqz	a7,84dc <.L215>
    84d8:	addi	a5,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    84dc:	li	t6,256
    84e0:	sw	t6,228(a5)
    84e4:	li	a7,512
    84e8:	sw	a7,236(a5)
    84ec:	ttatgetm	0
    84f0:	lui	s1,0xffe40
    84f4:	mv	s1,s1
    84f8:	lui	a7,0xb3ff0
    84fc:	sw	a7,0(s1) # ffe40000 <__instrn_buffer>
    8500:	lui	a7,0xb47f0
    8504:	sw	a7,0(s1)
    8508:	lui	a7,0xb3070
    850c:	addi	a7,a7,1 # b3070001 <__device_print_strings_info_end+0xacb70001>
    8510:	sw	a7,0(s1)
    8514:	lui	a7,0xb4800
    8518:	addi	a7,a7,1 # b4800001 <__device_print_strings_info_end+0xae300001>
    851c:	sw	a7,0(s1)
    8520:	lui	a7,0xb5010
    8524:	addi	a7,a7,1 # b5010001 <__device_print_strings_info_end+0xaeb10001>
    8528:	sw	a7,0(s1)
    852c:	lui	a7,0xb3010
    8530:	addi	a7,a7,2 # b3010002 <__device_print_strings_info_end+0xacb10002>
    8534:	sw	a7,0(s1)
    8538:	lui	a7,0xb5400
    853c:	addi	t1,a7,71 # b5400047 <__device_print_strings_info_end+0xaef00047>
    8540:	sw	t1,0(s1)
    8544:	addi	a7,a7,119
    8548:	sw	a7,0(s1)
    854c:	ttatrelm	0
    8550:	li	a7,22
    8554:	sw	a7,256(a5)
    8558:	lui	a7,0x40
    855c:	addi	a7,a7,1 # 40001 <.LASF1241+0x2e72e>
    8560:	sw	a7,260(a5)
    8564:	lui	a7,0x1000
    8568:	addi	t1,a7,21 # 1000015 <.LASF1241+0xfee742>
    856c:	sw	t1,448(a5)
    8570:	lui	t1,0x20
    8574:	addi	t1,t1,1 # 20001 <.LASF1241+0xe72e>
    8578:	sw	t1,452(a5)
    857c:	li	t1,38
    8580:	sw	t1,288(a5)
    8584:	lui	t1,0xf0
    8588:	addi	t1,t1,15 # f000f <.LASF1241+0xde73c>
    858c:	sw	t1,292(a5)
    8590:	li	t4,37
    8594:	sw	t4,480(a5)
    8598:	sw	t1,484(a5)
    859c:	lui	t1,0x5e240
    85a0:	addi	t1,t1,-1024 # 5e23fc00 <__device_print_strings_info_end+0x57d3fc00>
    85a4:	sw	t1,0(s1)
    85a8:	lui	t1,0x5e440
    85ac:	addi	t1,t1,-1024 # 5e43fc00 <__device_print_strings_info_end+0x57f3fc00>
    85b0:	lui	t4,0x400
    85b4:	sw	t1,0(s1)
    85b8:	addi	t4,t4,64 # 400040 <.LASF1241+0x3ee76d>
    85bc:	sw	t4,336(a5)
    85c0:	add	t5,a7,t6
    85c4:	sw	t5,344(a5)
    85c8:	lui	t1,0xffe00
    85cc:	sw	t5,160(t1) # ffe000a0 <__stack_base+0x2ff670>
    85d0:	lui	t5,0x800
    85d4:	addi	t5,t5,128 # 800080 <.LASF1241+0x7ee7ad>
    85d8:	sw	t5,164(t1)
    85dc:	lui	t5,0x200
    85e0:	sw	t4,168(t1)
    85e4:	addi	t5,t5,32 # 200020 <.LASF1241+0x1ee74d>
    85e8:	lui	t4,0x100
    85ec:	sw	t5,172(t1)
    85f0:	addi	t4,t4,16 # 100010 <.LASF1241+0xee73d>
    85f4:	sw	t4,176(t1)
    85f8:	sw	zero,72(sp)
    85fc:	lw	t1,176(t1)
    8600:	sw	t1,72(sp)
    8604:	ttsetc16	5,4
    8608:	sw	t6,200(a5)
    860c:	sw	zero,560(gp) # ffb00a20 <unp_cfg_context>
    8610:	ttsetc16	41,0
    8614:	lui	t1,0x45000
    8618:	addi	a7,a7,-256
    861c:	slli	a1,a1,0x8
    8620:	and	a1,a1,a7
    8624:	slli	a5,a2,0x8
    8628:	addi	a2,t1,72 # 45000048 <__device_print_strings_info_end+0x3eb00048>
    862c:	add	a2,a1,a2
    8630:	and	a5,a5,a7
    8634:	addi	a1,t1,74
    8638:	sw	a2,0(s1)
    863c:	add	a5,a5,a1
    8640:	sw	a5,0(s1)
    8644:	lui	a5,0xb4010
    8648:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    864c:	sw	a5,0(s1)
    8650:	ttsetadczw	3,0,0,0,0,15
    8654:	lui	a5,0x5e300
    8658:	addi	a5,a5,-1024 # 5e2ffc00 <__device_print_strings_info_end+0x57dffc00>
    865c:	sw	a5,0(s1)
    8660:	ttsetadcxx	2,255,0
    8664:	addi	t1,t1,332
    8668:	sw	t1,0(s1)
    866c:	ttreplay	0,12,0,1
    8670:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    8674:	ttrdcfg	12,76
    8678:	ttadddmareg	0,12,12,36
    867c:	ttstallwait	128,1
    8680:	ttwrcfg	12,0,76
    8684:	ttnop
    8688:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    868c:	ttrdcfg	12,77
    8690:	ttadddmareg	0,12,12,36
    8694:	ttstallwait	128,1
    8698:	ttwrcfg	12,0,77
    869c:	ttnop
    86a0:	lui	a2,0xffe80
    86a4:	li	a5,0
    86a8:	addi	a2,a2,8 # ffe80008 <__instrn_buffer+0x40008>
    86ac:	sw	a5,0(a2)
    86b0:	lw	a5,0(a2)
    86b4:	and	zero,zero,a5
    86b8:	lui	a5,0xffb80
    86bc:	sw	zero,4(a5) # ffb80004 <__stack_base+0x7f5d4>
    86c0:	lui	a2,0x4000
    86c4:	sw	zero,8(a5)
    86c8:	addi	a2,a2,96 # 4000060 <.LASF1241+0x3fee78d>
    86cc:	sw	a2,12(a5)
    86d0:	sw	zero,16(a5)
    86d4:	sw	zero,20(a5)
    86d8:	lui	a2,0x4018
    86dc:	sw	zero,24(a5)
    86e0:	addi	a2,a2,96 # 4018060 <.LASF1241+0x400678d>
    86e4:	sw	a2,28(a5)
    86e8:	sw	zero,32(a5)
    86ec:	lhu	a7,24(s2)
    86f0:	lui	a1,0xffb40
    86f4:	li	a2,3
    86f8:	lw	a5,40(a1) # ffb40028 <__stack_base+0x3f5f8>
    86fc:	sub	a5,a5,a7
    8700:	zext.h	a5,a5
    8704:	bgeu	a2,a5,86f8 <.L216>
    8708:	bltu	a0,t3,8710 <.LBB5921>
    870c:	j	9718 <.L336>
    8710:	lui	a2,0x45000
    8714:	addi	a2,a2,76 # 4500004c <__device_print_strings_info_end+0x3eb0004c>
    8718:	slli	a7,s11,0x8
    871c:	addi	a5,s0,-1
    8720:	add	a2,a7,a2
    8724:	seqz	a5,a5
    8728:	sw	a2,32(sp)
    872c:	lui	a2,0xb5400
    8730:	sw	a5,40(sp)
    8734:	addi	a5,a2,119 # b5400077 <__device_print_strings_info_end+0xaef00077>
    8738:	slli	t0,s11,0x2
    873c:	sw	a5,12(sp)
    8740:	addi	a5,t3,-1
    8744:	lui	a1,0x1000
    8748:	sw	s7,188(sp)
    874c:	sw	a5,36(sp)
    8750:	zext.h	a5,t0
    8754:	addi	s7,s11,-1
    8758:	slli	s7,s7,0x10
    875c:	sw	s8,184(sp)
    8760:	lui	s0,0xffe80
    8764:	addi	s8,a1,255 # 10000ff <.LASF1241+0xfee82c>
    8768:	sw	a5,16(sp)
    876c:	mv	a5,s2
    8770:	add	s8,s7,s8
    8774:	sw	s9,48(sp)
    8778:	add	s2,s7,a1
    877c:	addi	s4,s0,8 # ffe80008 <__instrn_buffer+0x40008>
    8780:	li	s3,1
    8784:	sw	a3,44(sp)
    8788:	mv	s9,a0
    878c:	sw	a4,52(sp)
    8790:	sw	t0,20(sp)
    8794:	sw	a0,24(sp)
    8798:	sw	t3,56(sp)
    879c:	mv	s7,a5
    87a0:	sw	s5,196(sp)
    87a4:	zext.h	s5,s11
    87a8:	li	a0,1
    87ac:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    87b0:	lw	a5,8(s7)
    87b4:	ttstallwait	128,4
    87b8:	lui	a3,0x1000
    87bc:	lui	a4,0xb30f0
    87c0:	addi	a3,a3,-256 # ffff00 <.LASF1241+0xfee62d>
    87c4:	slli	a5,a5,0x8
    87c8:	addi	a1,a4,1392 # b30f0570 <__device_print_strings_info_end+0xacbf0570>
    87cc:	and	a5,a5,a3
    87d0:	lw	a3,12(sp)
    87d4:	sw	a1,0(s1)
    87d8:	lui	a0,0x45000
    87dc:	sw	a3,0(s1)
    87e0:	addi	a2,a0,74 # 4500004a <__device_print_strings_info_end+0x3eb0004a>
    87e4:	addi	a4,a4,1400
    87e8:	sw	a4,0(s1)
    87ec:	add	a5,a5,a2
    87f0:	sw	a5,0(s1)
    87f4:	lw	a4,36(sp)
    87f8:	lui	a5,0xb4010
    87fc:	addi	a5,a5,328 # b4010148 <__device_print_strings_info_end+0xadb10148>
    8800:	sw	a5,0(s1)
    8804:	sub	t6,s9,a4
    8808:	lw	a5,40(sp)
    880c:	seqz	t6,t6
    8810:	and	t6,a5,t6
    8814:	sw	t6,60(sp)
    8818:	ttsetadczw	3,0,0,0,0,15
    881c:	lui	a5,0x5e300
    8820:	addi	a5,a5,-1024 # 5e2ffc00 <__device_print_strings_info_end+0x57dffc00>
    8824:	sw	a5,0(s1)
    8828:	ttsetadcxx	2,255,0
    882c:	addi	a0,a0,1100
    8830:	sw	a0,0(s1)
    8834:	ttreplay	0,12,0,1
    8838:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    883c:	ttrdcfg	12,76
    8840:	ttadddmareg	0,12,12,36
    8844:	ttstallwait	128,1
    8848:	ttwrcfg	12,0,76
    884c:	ttnop
    8850:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    8854:	ttrdcfg	12,77
    8858:	ttadddmareg	0,12,12,36
    885c:	ttstallwait	128,1
    8860:	ttwrcfg	12,0,77
    8864:	ttnop
    8868:	li	a5,0
    886c:	sw	a5,0(s4)
    8870:	lw	a5,0(s4)
    8874:	and	zero,zero,a5
    8878:	lui	a5,0xffb80
    887c:	sw	zero,4(a5) # ffb80004 <__stack_base+0x7f5d4>
    8880:	lui	a0,0x4000
    8884:	sw	zero,8(a5)
    8888:	addi	a0,a0,96 # 4000060 <.LASF1241+0x3fee78d>
    888c:	sw	a0,12(a5)
    8890:	sw	zero,16(a5)
    8894:	sw	zero,20(a5)
    8898:	lui	a0,0x4018
    889c:	sw	zero,24(a5)
    88a0:	addi	a0,a0,96 # 4018060 <.LASF1241+0x400678d>
    88a4:	sw	a0,28(a5)
    88a8:	sw	zero,32(a5)
    88ac:	li	a0,1
    88b0:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    88b4:	lw	a0,8(s7)
    88b8:	ttstallwait	128,4
    88bc:	lui	a4,0xb30f0
    88c0:	lw	a3,12(sp)
    88c4:	addi	a1,a4,1392 # b30f0570 <__device_print_strings_info_end+0xacbf0570>
    88c8:	sw	a1,0(s1)
    88cc:	sw	a3,0(s1)
    88d0:	addi	a4,a4,1400
    88d4:	lui	a3,0x1000
    88d8:	sw	a4,0(s1)
    88dc:	addi	a3,a3,-256 # ffff00 <.LASF1241+0xfee62d>
    88e0:	lui	a4,0x45000
    88e4:	slli	a5,a0,0x8
    88e8:	and	a5,a5,a3
    88ec:	addi	a2,a4,74 # 4500004a <__device_print_strings_info_end+0x3eb0004a>
    88f0:	add	a5,a5,a2
    88f4:	sw	a5,0(s1)
    88f8:	lhu	a3,56(s7)
    88fc:	lw	t6,60(sp)
    8900:	lui	a4,0xffb41
    8904:	lw	a5,40(a4) # ffb41028 <__stack_base+0x405f8>
    8908:	lw	a2,16(sp)
    890c:	sub	a5,a5,a3
    8910:	zext.h	a5,a5
    8914:	bltu	a5,a2,8904 <.L220>
    8918:	lhu	a2,24(s7)
    891c:	lui	a3,0xffb40
    8920:	li	a4,3
    8924:	lw	a5,40(a3) # ffb40028 <__stack_base+0x3f5f8>
    8928:	sub	a5,a5,a2
    892c:	zext.h	a5,a5
    8930:	bgeu	a4,a5,8924 <.L221>
    8934:	lw	a2,16(s7)
    8938:	lw	t0,48(s7)
    893c:	lw	a3,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    8940:	lui	a5,0xffef0
    8944:	lw	t5,40(s7)
    8948:	addi	a2,a2,-1
    894c:	addi	a1,t0,-1
    8950:	addi	a4,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    8954:	bnez	a3,895c <.L223>
    8958:	mv	a4,a5
    895c:	lw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    8960:	mul	t4,s11,t5
    8964:	li	t3,4
    8968:	lw	a5,52(s0)
    896c:	andi	a5,a5,254
    8970:	bnez	a5,8968 <.L224>
    8974:	bnez	a3,97fc <.L225>
    8978:	sw	a1,304(a4)
    897c:	sw	a2,496(a4)
    8980:	sw	zero,52(s0)
    8984:	ttstallwait	8,1024
    8988:	ttunpacrnop	1,0,0,0,0,0,0,0,1
    898c:	ttunpacr	1,17,0,0,0,1,0,0,0,0,0,0,1
    8990:	ttunpacr	1,17,0,0,0,1,1,0,0,0,0,0,1
    8994:	ttsetadczw	2,0,0,0,0,5
    8998:	sw	s2,0(s1)
    899c:	ttsemget	32
    89a0:	li	a5,1
    89a4:	ttsetc16	41,257
    89a8:	addi	t3,t3,-1
    89ac:	mv	a3,a5
    89b0:	add	a1,a1,t4
    89b4:	add	a2,a2,a0
    89b8:	bnez	t3,8968 <.L224>
    89bc:	sw	a5,560(gp) # ffb00a20 <unp_cfg_context>
    89c0:	bnez	t6,9838 <.L475>
    89c4:	lhu	a5,56(s7)
    89c8:	lw	a4,16(sp)
    89cc:	lui	a3,0x45000
    89d0:	add	a5,a4,a5
    89d4:	zext.h	a5,a5
    89d8:	addi	a3,a3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    89dc:	slli	a4,a5,0x8
    89e0:	add	a4,a4,a3
    89e4:	sh	a5,56(s7)
    89e8:	sw	a4,0(s1)
    89ec:	ttstallwait	32,6
    89f0:	lw	a5,20(sp)
    89f4:	lui	a4,0x67110
    89f8:	mul	a5,a5,t5
    89fc:	lw	a3,36(s7)
    8a00:	add	a5,a5,t0
    8a04:	addi	a4,a4,1032 # 67110408 <__device_print_strings_info_end+0x60c10408>
    8a08:	sw	a5,48(s7)
    8a0c:	sw	a4,0(s1)
    8a10:	bltu	a5,a3,8a20 <.L241>
    8a14:	lw	a4,32(s7)
    8a18:	sub	a5,a5,a4
    8a1c:	sw	a5,48(s7)
    8a20:	li	a0,24
    8a24:	sw	t3,60(sp)
    8a28:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    8a2c:	lw	a5,168(s7)
    8a30:	ttstallwait	128,4
    8a34:	lui	a3,0x1000
    8a38:	addi	a3,a3,-256 # ffff00 <.LASF1241+0xfee62d>
    8a3c:	slli	a5,a5,0x8
    8a40:	and	a5,a5,a3
    8a44:	lui	a3,0x45000
    8a48:	lui	a4,0xb30f0
    8a4c:	addi	a3,a3,74 # 4500004a <__device_print_strings_info_end+0x3eb0004a>
    8a50:	add	a5,a5,a3
    8a54:	addi	a3,a4,1392 # b30f0570 <__device_print_strings_info_end+0xacbf0570>
    8a58:	sw	a3,0(s1)
    8a5c:	lw	a3,12(sp)
    8a60:	addi	a4,a4,1400
    8a64:	sw	a3,0(s1)
    8a68:	sw	a4,0(s1)
    8a6c:	sw	a5,0(s1)
    8a70:	lhu	a3,184(s7)
    8a74:	lw	t3,60(sp)
    8a78:	lui	a4,0xffb45
    8a7c:	lw	a5,40(a4) # ffb45028 <__stack_base+0x445f8>
    8a80:	zext.h	a5,a5
    8a84:	beq	a5,a3,8a7c <.L242>
    8a88:	lhu	a3,792(s7)
    8a8c:	lui	a4,0xffb58
    8a90:	lw	a5,40(a4) # ffb58028 <__stack_base+0x575f8>
    8a94:	sub	a5,a5,a3
    8a98:	zext.h	a5,a5
    8a9c:	bltu	a5,s5,8a90 <.L243>
    8aa0:	lui	a5,0xb4010
    8aa4:	addi	a5,a5,328 # b4010148 <__device_print_strings_info_end+0xadb10148>
    8aa8:	sw	a5,0(s1)
    8aac:	ttsetadcxx	1,255,0
    8ab0:	ttsetadcxx	2,15,0
    8ab4:	ttreplay	0,2,0,1
    8ab8:	ttunpacr	0,1,0,0,0,1,1,0,0,0,0,0,1
    8abc:	ttunpacr	1,1,0,0,0,1,1,0,0,0,0,0,1
    8ac0:	li	a5,0
    8ac4:	sw	a5,0(s4)
    8ac8:	lw	a5,0(s4)
    8acc:	and	zero,zero,a5
    8ad0:	lui	a5,0xffb80
    8ad4:	sw	s3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    8ad8:	li	a4,2
    8adc:	sw	a4,4(a5)
    8ae0:	lui	a3,0x2000
    8ae4:	sw	a3,8(a5)
    8ae8:	sw	a3,12(a5)
    8aec:	lui	a4,0x4000
    8af0:	sw	a3,16(a5)
    8af4:	addi	a4,a4,32 # 4000020 <.LASF1241+0x3fee74d>
    8af8:	sw	a4,20(a5)
    8afc:	sw	a3,24(a5)
    8b00:	sw	a4,28(a5)
    8b04:	sw	a4,32(a5)
    8b08:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    8b0c:	lui	a5,0xffef0
    8b10:	addi	a1,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    8b14:	bnez	a4,8b1c <.L369>
    8b18:	mv	a1,a5
    8b1c:	lw	a2,560(gp) # ffb00a20 <unp_cfg_context>
    8b20:	lw	a5,784(s7)
    8b24:	lw	a4,776(s7)
    8b28:	lw	a3,176(s7)
    8b2c:	addi	a5,a5,-1
    8b30:	mul	a4,t3,a4
    8b34:	add	a4,a5,a4
    8b38:	addi	a3,a3,-1 # 1ffffff <.LASF1241+0x1fee72c>
    8b3c:	ttsetadczw	3,0,0,0,0,15
    8b40:	lw	a5,52(s0)
    8b44:	andi	a5,a5,254
    8b48:	bnez	a5,8b40 <.L245>
    8b4c:	bnez	a2,9978 <.L246>
    8b50:	sw	a4,304(a1)
    8b54:	sw	a3,496(a1)
    8b58:	sw	zero,52(s0)
    8b5c:	ttstallwait	8,1024
    8b60:	ttmop	1,0,0
    8b64:	ttsemget	32
    8b68:	li	a2,1
    8b6c:	ttsetc16	41,257
    8b70:	addi	t3,t3,1
    8b74:	bne	s11,t3,8b20 <.L250>
    8b78:	lw	a4,24(sp)
    8b7c:	sw	a2,560(gp) # ffb00a20 <unp_cfg_context>
    8b80:	bgeu	a4,s9,8c44 <.L251>
    8b84:	lui	a4,0xb4010
    8b88:	addi	a4,a4,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    8b8c:	sw	a4,0(s1)
    8b90:	ttsetadcxx	1,255,0
    8b94:	li	a4,0
    8b98:	sw	a4,0(s4)
    8b9c:	lw	a4,0(s4)
    8ba0:	and	zero,zero,a4
    8ba4:	lui	a4,0xffb80
    8ba8:	li	a3,2
    8bac:	sw	a3,0(a4) # ffb80000 <__stack_base+0x7f5d0>
    8bb0:	lui	a3,0x42008
    8bb4:	sw	s3,4(a4)
    8bb8:	addi	a3,a3,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    8bbc:	sw	a3,8(a4)
    8bc0:	lui	a2,0x2000
    8bc4:	sw	a2,12(a4)
    8bc8:	lui	a3,0x43800
    8bcc:	sw	a2,16(a4)
    8bd0:	addi	a3,a3,257 # 43800101 <__device_print_strings_info_end+0x3d300101>
    8bd4:	sw	a3,20(a4)
    8bd8:	sw	a2,24(a4)
    8bdc:	sw	a3,28(a4)
    8be0:	sw	a3,32(a4)
    8be4:	lw	a2,912(s7)
    8be8:	addi	a2,a2,-1 # 1ffffff <.LASF1241+0x1fee72c>
    8bec:	ttsetadczw	3,0,0,0,0,15
    8bf0:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    8bf4:	beqz	a4,99b0 <.L377>
    8bf8:	lui	a4,0xffef0
    8bfc:	addi	a1,a4,1200 # ffef04b0 <__instrn_buffer+0xb04b0>
    8c00:	addi	a4,a4,1204
    8c04:	lw	a3,52(s0)
    8c08:	andi	a3,a3,254
    8c0c:	bnez	a3,8c04 <.L253>
    8c10:	lw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    8c14:	bnez	a3,8c1c <.L254>
    8c18:	mv	a4,a1
    8c1c:	sw	a2,0(a4)
    8c20:	sw	zero,52(s0)
    8c24:	ttstallwait	8,1024
    8c28:	ttmop	1,0,0
    8c2c:	ttsemget	32
    8c30:	lw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    8c34:	sub	a3,s3,a4
    8c38:	beq	a4,s3,99a8 <.L476>
    8c3c:	ttsetc16	41,257
    8c40:	sw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    8c44:	li	a0,24
    8c48:	sw	a5,60(sp)
    8c4c:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    8c50:	lw	a4,872(s7)
    8c54:	ttstallwait	128,4
    8c58:	lui	a2,0x1000
    8c5c:	addi	a2,a2,-256 # ffff00 <.LASF1241+0xfee62d>
    8c60:	slli	a4,a4,0x8
    8c64:	and	a4,a4,a2
    8c68:	lui	a2,0x45000
    8c6c:	lui	a3,0xb30f0
    8c70:	addi	a2,a2,74 # 4500004a <__device_print_strings_info_end+0x3eb0004a>
    8c74:	lw	a5,12(sp)
    8c78:	add	a4,a4,a2
    8c7c:	addi	a2,a3,1392 # b30f0570 <__device_print_strings_info_end+0xacbf0570>
    8c80:	sw	a2,0(s1)
    8c84:	sw	a5,0(s1)
    8c88:	addi	a3,a3,1400
    8c8c:	sw	a3,0(s1)
    8c90:	sw	a4,0(s1)
    8c94:	lui	a4,0xb4010
    8c98:	addi	a4,a4,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    8c9c:	sw	a4,0(s1)
    8ca0:	ttsetadcxx	3,255,0
    8ca4:	li	a4,0
    8ca8:	sw	a4,0(s4)
    8cac:	lw	a4,0(s4)
    8cb0:	and	zero,zero,a4
    8cb4:	lui	a4,0xffb80
    8cb8:	sw	s3,0(a4) # ffb80000 <__stack_base+0x7f5d0>
    8cbc:	li	a3,2
    8cc0:	sw	a3,4(a4)
    8cc4:	lui	a3,0x42808
    8cc8:	addi	a3,a3,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    8ccc:	sw	a3,8(a4)
    8cd0:	lui	a3,0x54400
    8cd4:	addi	a3,a3,129 # 54400081 <__device_print_strings_info_end+0x4df00081>
    8cd8:	sw	a3,12(a4)
    8cdc:	lui	a2,0x2000
    8ce0:	lui	a3,0x42008
    8ce4:	sw	a2,16(a4)
    8ce8:	addi	a3,a3,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    8cec:	sw	a3,20(a4)
    8cf0:	sw	a2,24(a4)
    8cf4:	sw	a3,28(a4)
    8cf8:	sw	a3,32(a4)
    8cfc:	lhu	a2,792(s7)
    8d00:	lw	a5,60(sp)
    8d04:	lui	a3,0xffb58
    8d08:	lw	a4,40(a3) # ffb58028 <__stack_base+0x575f8>
    8d0c:	sub	a4,a4,a2
    8d10:	zext.h	a4,a4
    8d14:	bltu	a4,s5,8d08 <.L257>
    8d18:	lhu	a2,888(s7)
    8d1c:	lui	a3,0xffb5b
    8d20:	lw	a4,40(a3) # ffb5b028 <__stack_base+0x5a5f8>
    8d24:	zext.h	a4,a4
    8d28:	beq	a4,a2,8d20 <.L258>
    8d2c:	lw	a3,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    8d30:	lui	a4,0xffef0
    8d34:	addi	a1,a4,896 # ffef0380 <__instrn_buffer+0xb0380>
    8d38:	bnez	a3,8d40 <.L260>
    8d3c:	mv	a1,a4
    8d40:	lw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    8d44:	lw	a2,784(s7)
    8d48:	lw	a3,776(s7)
    8d4c:	lw	a0,880(s7)
    8d50:	mul	a3,a5,a3
    8d54:	addi	a2,a2,-1 # 1ffffff <.LASF1241+0x1fee72c>
    8d58:	add	a2,a2,a3
    8d5c:	addi	a0,a0,-1
    8d60:	ttsetadczw	3,0,0,0,0,15
    8d64:	lw	a3,52(s0)
    8d68:	andi	a3,a3,254
    8d6c:	bnez	a3,8d64 <.L261>
    8d70:	bnez	a4,99c0 <.L262>
    8d74:	sw	a2,304(a1)
    8d78:	sw	a0,496(a1)
    8d7c:	sw	zero,52(s0)
    8d80:	ttstallwait	8,1024
    8d84:	ttmop	1,0,0
    8d88:	ttsemget	32
    8d8c:	li	a4,1
    8d90:	ttsetc16	41,257
    8d94:	addi	a5,a5,1
    8d98:	bne	s11,a5,8d44 <.L266>
    8d9c:	sw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    8da0:	lhu	a4,792(s7)
    8da4:	lui	a2,0x45000
    8da8:	add	a4,s5,a4
    8dac:	zext.h	a4,a4
    8db0:	addi	a2,a2,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    8db4:	slli	a5,a4,0x8
    8db8:	add	a5,a5,a2
    8dbc:	sw	a5,0(s1)
    8dc0:	lw	a5,776(s7)
    8dc4:	sh	a4,792(s7)
    8dc8:	mul	a5,s11,a5
    8dcc:	ttstallwait	32,6
    8dd0:	lw	a1,784(s7)
    8dd4:	lui	a2,0x67116
    8dd8:	add	a5,a5,a1
    8ddc:	addi	a2,a2,8 # 67116008 <__device_print_strings_info_end+0x60c16008>
    8de0:	sw	a5,784(s7)
    8de4:	sw	a2,0(s1)
    8de8:	lw	a2,772(s7)
    8dec:	bltu	a5,a2,8dfc <.L267>
    8df0:	lw	a2,768(s7)
    8df4:	sub	a5,a5,a2
    8df8:	sw	a5,784(s7)
    8dfc:	lui	a2,0xffb58
    8e00:	lw	a5,40(a2) # ffb58028 <__stack_base+0x575f8>
    8e04:	sub	a5,a5,a4
    8e08:	zext.h	a5,a5
    8e0c:	bltu	a5,s5,8e00 <.L268>
    8e10:	li	a0,24
    8e14:	sw	a3,60(sp)
    8e18:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    8e1c:	li	a0,5
    8e20:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    8e24:	lhu	a2,184(s7)
    8e28:	lw	a3,60(sp)
    8e2c:	lui	a4,0xffb45
    8e30:	lw	a5,40(a4) # ffb45028 <__stack_base+0x445f8>
    8e34:	zext.h	a5,a5
    8e38:	beq	a5,a2,8e30 <.L269>
    8e3c:	lhu	a2,792(s7)
    8e40:	lui	a4,0xffb58
    8e44:	lw	a5,40(a4) # ffb58028 <__stack_base+0x575f8>
    8e48:	sub	a5,a5,a2
    8e4c:	zext.h	a5,a5
    8e50:	bltu	a5,s5,8e44 <.L270>
    8e54:	lui	a5,0xb4010
    8e58:	addi	a5,a5,328 # b4010148 <__device_print_strings_info_end+0xadb10148>
    8e5c:	sw	a5,0(s1)
    8e60:	ttsetadcxx	1,255,0
    8e64:	ttsetadcxx	2,15,0
    8e68:	ttreplay	0,2,0,1
    8e6c:	ttunpacr	0,1,0,0,0,1,1,0,0,0,0,0,1
    8e70:	ttunpacr	1,1,0,0,0,1,1,0,0,0,0,0,1
    8e74:	li	a5,0
    8e78:	sw	a5,0(s4)
    8e7c:	lw	a5,0(s4)
    8e80:	and	zero,zero,a5
    8e84:	lui	a5,0xffb80
    8e88:	sw	s3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    8e8c:	li	a4,2
    8e90:	sw	a4,4(a5)
    8e94:	lui	a2,0x2000
    8e98:	sw	a2,8(a5)
    8e9c:	sw	a2,12(a5)
    8ea0:	lui	a4,0x4000
    8ea4:	sw	a2,16(a5)
    8ea8:	addi	a4,a4,32 # 4000020 <.LASF1241+0x3fee74d>
    8eac:	sw	a4,20(a5)
    8eb0:	sw	a2,24(a5)
    8eb4:	sw	a4,28(a5)
    8eb8:	sw	a4,32(a5)
    8ebc:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    8ec0:	lui	a5,0xffef0
    8ec4:	addi	a1,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    8ec8:	bnez	a4,8ed0 <.L272>
    8ecc:	mv	a1,a5
    8ed0:	lw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    8ed4:	lw	a2,776(s7)
    8ed8:	lw	a5,784(s7)
    8edc:	lw	a0,176(s7)
    8ee0:	mul	a2,a3,a2
    8ee4:	addi	a5,a5,-1
    8ee8:	add	a2,a2,a5
    8eec:	addi	a0,a0,-1
    8ef0:	ttsetadczw	3,0,0,0,0,15
    8ef4:	lw	a5,52(s0)
    8ef8:	andi	a5,a5,254
    8efc:	bnez	a5,8ef4 <.L273>
    8f00:	bnez	a4,99f0 <.L477>
    8f04:	sw	a2,304(a1)
    8f08:	sw	a0,496(a1)
    8f0c:	sw	zero,52(s0)
    8f10:	ttstallwait	8,1024
    8f14:	ttmop	1,0,0
    8f18:	ttsemget	32
    8f1c:	li	a4,1
    8f20:	ttsetc16	41,257
    8f24:	addi	a3,a3,1
    8f28:	bne	s11,a3,8ed4 <.L276>
    8f2c:	li	a0,2
    8f30:	sw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    8f34:	sw	a5,60(sp)
    8f38:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    8f3c:	li	a0,24
    8f40:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    8f44:	lui	a4,0xb4010
    8f48:	addi	a4,a4,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    8f4c:	sw	a4,0(s1)
    8f50:	ttsetadczw	3,0,0,0,0,15
    8f54:	lui	a4,0x5e300
    8f58:	addi	a4,a4,-1024 # 5e2ffc00 <__device_print_strings_info_end+0x57dffc00>
    8f5c:	sw	a4,0(s1)
    8f60:	ttsetadcxx	2,255,0
    8f64:	lw	a5,32(sp)
    8f68:	sw	a5,0(s1)
    8f6c:	ttreplay	0,12,0,1
    8f70:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    8f74:	ttrdcfg	12,76
    8f78:	ttadddmareg	0,12,12,36
    8f7c:	ttstallwait	128,1
    8f80:	ttwrcfg	12,0,76
    8f84:	ttnop
    8f88:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    8f8c:	ttrdcfg	12,77
    8f90:	ttadddmareg	0,12,12,36
    8f94:	ttstallwait	128,1
    8f98:	ttwrcfg	12,0,77
    8f9c:	ttnop
    8fa0:	li	a4,0
    8fa4:	sw	a4,0(s4)
    8fa8:	lw	a4,0(s4)
    8fac:	and	zero,zero,a4
    8fb0:	lui	a4,0xffb80
    8fb4:	sw	zero,4(a4) # ffb80004 <__stack_base+0x7f5d4>
    8fb8:	lui	a3,0x4000
    8fbc:	sw	zero,8(a4)
    8fc0:	addi	a3,a3,96 # 4000060 <.LASF1241+0x3fee78d>
    8fc4:	sw	a3,12(a4)
    8fc8:	sw	zero,16(a4)
    8fcc:	sw	zero,20(a4)
    8fd0:	lui	a3,0x4018
    8fd4:	sw	zero,24(a4)
    8fd8:	addi	a3,a3,96 # 4018060 <.LASF1241+0x400678d>
    8fdc:	sw	a3,28(a4)
    8fe0:	sw	zero,32(a4)
    8fe4:	li	a0,2
    8fe8:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    8fec:	li	a0,24
    8ff0:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    8ff4:	lhu	a2,88(s7)
    8ff8:	lw	a5,60(sp)
    8ffc:	lui	a3,0xffb42
    9000:	lw	a4,40(a3) # ffb42028 <__stack_base+0x415f8>
    9004:	lw	a1,16(sp)
    9008:	sub	a4,a4,a2
    900c:	zext.h	a4,a4
    9010:	bltu	a4,a1,9000 <.L282>
    9014:	lhu	a2,792(s7)
    9018:	lui	a3,0xffb58
    901c:	lw	a4,40(a3) # ffb58028 <__stack_base+0x575f8>
    9020:	sub	a4,a4,a2
    9024:	zext.h	a4,a4
    9028:	bltu	a4,s5,901c <.L283>
    902c:	lw	a3,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9030:	lui	a4,0xffef0
    9034:	addi	a1,a4,896 # ffef0380 <__instrn_buffer+0xb0380>
    9038:	bnez	a3,9040 <.L285>
    903c:	mv	a1,a4
    9040:	lw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    9044:	lw	a3,776(s7)
    9048:	lw	a6,784(s7)
    904c:	lw	a2,72(s7)
    9050:	mul	a3,a5,a3
    9054:	lw	a0,80(s7)
    9058:	addi	a6,a6,-1
    905c:	mul	a2,a5,a2
    9060:	addi	a0,a0,-1
    9064:	add	a3,a3,a6
    9068:	sh2add	a2,a2,a0
    906c:	lw	a0,52(s0)
    9070:	andi	a0,a0,254
    9074:	bnez	a0,906c <.L286>
    9078:	beqz	a4,9a20 <.L287>
    907c:	sw	a2,308(a1)
    9080:	sw	a3,500(a1)
    9084:	sw	zero,52(s0)
    9088:	ttstallwait	8,1024
    908c:	ttunpacrnop	1,0,0,0,0,0,0,0,1
    9090:	ttunpacr	1,17,0,0,0,1,0,0,0,0,0,0,1
    9094:	ttunpacr	1,17,0,0,0,1,1,0,0,0,0,0,1
    9098:	ttsetadczw	2,0,0,0,0,5
    909c:	lui	a3,0x1030
    90a0:	addi	a3,a3,255 # 10300ff <.LASF1241+0x101e82c>
    90a4:	sw	a3,0(s1)
    90a8:	ttsemget	32
    90ac:	bne	a4,s3,9a58 <.L478>
    90b0:	ttsetc16	41,0
    90b4:	li	a4,0
    90b8:	addi	a5,a5,1
    90bc:	bne	s11,a5,9044 <.L291>
    90c0:	lhu	a5,88(s7)
    90c4:	lw	a3,16(sp)
    90c8:	sw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    90cc:	add	a5,a3,a5
    90d0:	lui	a4,0x45000
    90d4:	zext.h	a5,a5
    90d8:	addi	a4,a4,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    90dc:	sh	a5,88(s7)
    90e0:	slli	a5,a5,0x8
    90e4:	add	a5,a5,a4
    90e8:	sw	a5,0(s1)
    90ec:	lw	a5,72(s7)
    90f0:	lw	a4,20(sp)
    90f4:	mul	a5,a4,a5
    90f8:	ttstallwait	32,6
    90fc:	lw	a3,80(s7)
    9100:	lui	a4,0x67111
    9104:	add	a5,a5,a3
    9108:	addi	a4,a4,-2040 # 67110808 <__device_print_strings_info_end+0x60c10808>
    910c:	sw	a5,80(s7)
    9110:	sw	a4,0(s1)
    9114:	lw	a4,68(s7)
    9118:	bltu	a5,a4,9128 <.L292>
    911c:	lw	a4,64(s7)
    9120:	sub	a5,a5,a4
    9124:	sw	a5,80(s7)
    9128:	li	a0,25
    912c:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    9130:	lhu	a5,792(s7)
    9134:	lui	a4,0x45000
    9138:	add	a5,s5,a5
    913c:	addi	a4,a4,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    9140:	zext.h	a5,a5
    9144:	sh	a5,792(s7)
    9148:	slli	a5,a5,0x8
    914c:	add	a5,a5,a4
    9150:	sw	a5,0(s1)
    9154:	lw	a5,776(s7)
    9158:	mul	a5,s11,a5
    915c:	ttstallwait	32,6
    9160:	lw	a3,784(s7)
    9164:	lui	a4,0x67116
    9168:	add	a5,a5,a3
    916c:	addi	a4,a4,8 # 67116008 <__device_print_strings_info_end+0x60c16008>
    9170:	sw	a5,784(s7)
    9174:	sw	a4,0(s1)
    9178:	lw	a4,772(s7)
    917c:	bltu	a5,a4,918c <.L293>
    9180:	lw	a4,768(s7)
    9184:	sub	a5,a5,a4
    9188:	sw	a5,784(s7)
    918c:	lw	a5,24(sp)
    9190:	beq	s9,a5,969c <.L294>
    9194:	li	a0,28
    9198:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    919c:	li	a0,27
    91a0:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    91a4:	lui	a5,0xb4010
    91a8:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    91ac:	sw	a5,0(s1)
    91b0:	ttsetadcxx	3,255,0
    91b4:	li	a5,0
    91b8:	sw	a5,0(s4)
    91bc:	lw	a5,0(s4)
    91c0:	and	zero,zero,a5
    91c4:	lui	a5,0xffb80
    91c8:	sw	s3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    91cc:	li	a4,2
    91d0:	sw	a4,4(a5)
    91d4:	lui	a4,0x2000
    91d8:	sw	a4,8(a5)
    91dc:	sw	a4,12(a5)
    91e0:	sw	a4,16(a5)
    91e4:	lui	a4,0x42008
    91e8:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    91ec:	sw	a4,20(a5)
    91f0:	lui	a4,0x42808
    91f4:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    91f8:	sw	a4,24(a5)
    91fc:	sw	a4,28(a5)
    9200:	sw	a4,32(a5)
    9204:	lhu	a3,920(s7)
    9208:	lui	a4,0xffb5c
    920c:	lw	a5,40(a4) # ffb5c028 <__stack_base+0x5b5f8>
    9210:	zext.h	a5,a5
    9214:	beq	a5,a3,920c <.L295>
    9218:	lhu	a3,888(s7)
    921c:	lui	a4,0xffb5b
    9220:	lw	a5,40(a4) # ffb5b028 <__stack_base+0x5a5f8>
    9224:	zext.h	a5,a5
    9228:	beq	a5,a3,9220 <.L296>
    922c:	fence
    9230:	lw	a3,912(s7)
    9234:	lw	a4,880(s7)
    9238:	addi	a3,a3,-1
    923c:	addi	a4,a4,-1
    9240:	ttsetadczw	3,0,0,0,0,15
    9244:	lw	a2,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9248:	lui	a5,0xffef0
    924c:	beqz	a2,9254 <.L298>
    9250:	addi	a5,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    9254:	lw	a2,52(s0)
    9258:	andi	a2,a2,254
    925c:	bnez	a2,9254 <.L298>
    9260:	lw	a2,560(gp) # ffb00a20 <unp_cfg_context>
    9264:	beqz	a2,9a64 <.L299>
    9268:	sw	a3,308(a5)
    926c:	sw	a4,500(a5)
    9270:	sw	zero,52(s0)
    9274:	ttstallwait	8,1024
    9278:	ttmop	1,0,0
    927c:	ttsemget	32
    9280:	sub	a5,s3,a2
    9284:	sw	a5,560(gp) # ffb00a20 <unp_cfg_context>
    9288:	bne	a2,s3,9a80 <.L301>
    928c:	ttsetc16	41,0
    9290:	li	a0,28
    9294:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    9298:	lui	a5,0xb4010
    929c:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    92a0:	sw	a5,0(s1)
    92a4:	ttsetadcxx	3,255,0
    92a8:	li	a5,0
    92ac:	sw	a5,0(s4)
    92b0:	lw	a5,0(s4)
    92b4:	and	zero,zero,a5
    92b8:	lui	a5,0xffb80
    92bc:	sw	s3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    92c0:	li	a4,2
    92c4:	sw	a4,4(a5)
    92c8:	lui	a4,0x2000
    92cc:	sw	a4,8(a5)
    92d0:	sw	a4,12(a5)
    92d4:	sw	a4,16(a5)
    92d8:	lui	a4,0x42008
    92dc:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    92e0:	sw	a4,20(a5)
    92e4:	lui	a4,0x42808
    92e8:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    92ec:	sw	a4,24(a5)
    92f0:	sw	a4,28(a5)
    92f4:	sw	a4,32(a5)
    92f8:	lhu	a3,984(s7)
    92fc:	lui	a4,0xffb5e
    9300:	lw	a5,40(a4) # ffb5e028 <__stack_base+0x5d5f8>
    9304:	zext.h	a5,a5
    9308:	beq	a5,a3,9300 <.L303>
    930c:	lhu	a3,1016(s7)
    9310:	lui	a4,0xffb5f
    9314:	lw	a5,40(a4) # ffb5f028 <__stack_base+0x5e5f8>
    9318:	zext.h	a5,a5
    931c:	beq	a5,a3,9314 <.L304>
    9320:	fence
    9324:	lw	a3,976(s7)
    9328:	lw	a4,1008(s7)
    932c:	addi	a3,a3,-1
    9330:	addi	a4,a4,-1
    9334:	ttsetadczw	3,0,0,0,0,15
    9338:	lw	a2,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    933c:	lui	a5,0xffef0
    9340:	beqz	a2,9348 <.L306>
    9344:	addi	a5,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    9348:	lw	a2,52(s0)
    934c:	andi	a2,a2,254
    9350:	bnez	a2,9348 <.L306>
    9354:	lw	a2,560(gp) # ffb00a20 <unp_cfg_context>
    9358:	beqz	a2,9a88 <.L307>
    935c:	sw	a3,308(a5)
    9360:	sw	a4,500(a5)
    9364:	sw	zero,52(s0)
    9368:	ttstallwait	8,1024
    936c:	ttmop	1,0,0
    9370:	ttsemget	32
    9374:	sub	a5,s3,a2
    9378:	sw	a5,560(gp) # ffb00a20 <unp_cfg_context>
    937c:	bne	a2,s3,9aa4 <.L309>
    9380:	ttsetc16	41,0
    9384:	lhu	a5,984(s7)
    9388:	lui	a4,0x45000
    938c:	addi	a5,a5,1
    9390:	addi	a4,a4,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    9394:	zext.h	a5,a5
    9398:	sh	a5,984(s7)
    939c:	slli	a5,a5,0x8
    93a0:	add	a5,a5,a4
    93a4:	sw	a5,0(s1)
    93a8:	lw	a5,968(s7)
    93ac:	ttstallwait	32,6
    93b0:	lw	a3,976(s7)
    93b4:	lui	a4,0x67118
    93b8:	add	a5,a5,a3
    93bc:	addi	a4,a4,-2040 # 67117808 <__device_print_strings_info_end+0x60c17808>
    93c0:	sw	a5,976(s7)
    93c4:	sw	a4,0(s1)
    93c8:	lw	a4,964(s7)
    93cc:	bltu	a5,a4,93dc <.L311>
    93d0:	lw	a4,960(s7)
    93d4:	sub	a5,a5,a4
    93d8:	sw	a5,976(s7)
    93dc:	li	a0,26
    93e0:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    93e4:	li	a0,31
    93e8:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    93ec:	lui	a5,0xb4010
    93f0:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    93f4:	sw	a5,0(s1)
    93f8:	ttsetadcxx	3,255,0
    93fc:	li	a5,0
    9400:	sw	a5,0(s4)
    9404:	lw	a5,0(s4)
    9408:	and	zero,zero,a5
    940c:	lui	a5,0xffb80
    9410:	sw	s3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    9414:	li	a4,2
    9418:	sw	a4,4(a5)
    941c:	lui	a4,0x42808
    9420:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    9424:	sw	a4,8(a5)
    9428:	lui	a4,0x54400
    942c:	addi	a4,a4,129 # 54400081 <__device_print_strings_info_end+0x4df00081>
    9430:	sw	a4,12(a5)
    9434:	lui	a3,0x2000
    9438:	lui	a4,0x42008
    943c:	sw	a3,16(a5)
    9440:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    9444:	sw	a4,20(a5)
    9448:	sw	a3,24(a5)
    944c:	sw	a4,28(a5)
    9450:	sw	a4,32(a5)
    9454:	lhu	a2,856(s7)
    9458:	lui	a3,0xffb5a
    945c:	li	a4,3
    9460:	lw	a5,40(a3) # ffb5a028 <__stack_base+0x595f8>
    9464:	sub	a5,a5,a2
    9468:	zext.h	a5,a5
    946c:	bgeu	a4,a5,9460 <.L312>
    9470:	lhu	a3,1016(s7)
    9474:	lui	a4,0xffb5f
    9478:	lw	a5,40(a4) # ffb5f028 <__stack_base+0x5e5f8>
    947c:	zext.h	a5,a5
    9480:	beq	a5,a3,9478 <.L313>
    9484:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9488:	lui	a5,0xffef0
    948c:	addi	a1,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    9490:	bnez	a4,9498 <.L315>
    9494:	mv	a1,a5
    9498:	lui	t3,0x45000
    949c:	lui	a0,0x67117
    94a0:	lw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    94a4:	lw	a5,848(s7)
    94a8:	addi	t3,t3,8 # 45000008 <__device_print_strings_info_end+0x3eb00008>
    94ac:	addi	a0,a0,-2040 # 67116808 <__device_print_strings_info_end+0x60c16808>
    94b0:	li	a4,4
    94b4:	lw	a2,1008(s7)
    94b8:	addi	a5,a5,-1
    94bc:	addi	a2,a2,-1 # 1ffffff <.LASF1241+0x1fee72c>
    94c0:	ttsetadczw	3,0,0,0,0,15
    94c4:	lw	a6,52(s0)
    94c8:	andi	a6,a6,254
    94cc:	bnez	a6,94c4 <.L316>
    94d0:	bnez	a3,94f8 <.L479>
    94d4:	sw	a5,304(a1)
    94d8:	sw	a2,496(a1)
    94dc:	sw	zero,52(s0)
    94e0:	ttstallwait	8,1024
    94e4:	ttmop	1,0,0
    94e8:	ttsemget	32
    94ec:	li	a3,1
    94f0:	ttsetc16	41,257
    94f4:	j	951c <.L323>
    94f8:	sw	a5,308(a1)
    94fc:	sw	a2,500(a1)
    9500:	sw	zero,52(s0)
    9504:	ttstallwait	8,1024
    9508:	ttmop	1,0,0
    950c:	ttsemget	32
    9510:	bne	a3,s3,9aac <.L480>
    9514:	ttsetc16	41,0
    9518:	li	a3,0
    951c:	lhu	a2,856(s7)
    9520:	lw	a5,840(s7)
    9524:	addi	a2,a2,1
    9528:	zext.h	a2,a2
    952c:	slli	a6,a2,0x8
    9530:	add	a6,a6,t3
    9534:	sh	a2,856(s7)
    9538:	sw	a6,0(s1)
    953c:	ttstallwait	32,6
    9540:	lw	a6,848(s7)
    9544:	lw	a2,836(s7)
    9548:	add	a5,a5,a6
    954c:	sw	a0,0(s1)
    9550:	sw	a5,848(s7)
    9554:	bltu	a5,a2,9564 <.L322>
    9558:	lw	a2,832(s7)
    955c:	sub	a5,a5,a2
    9560:	sw	a5,848(s7)
    9564:	addi	a4,a4,-1
    9568:	bnez	a4,94b4 <.L320>
    956c:	li	a0,31
    9570:	sw	a4,60(sp)
    9574:	sw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    9578:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    957c:	li	a0,29
    9580:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    9584:	li	a0,30
    9588:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    958c:	lui	a5,0xb4010
    9590:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    9594:	sw	a5,0(s1)
    9598:	ttsetadcxx	3,255,0
    959c:	lw	a4,60(sp)
    95a0:	sw	a4,0(s4)
    95a4:	lw	a4,0(s4)
    95a8:	and	zero,zero,a4
    95ac:	lui	a5,0xffb80
    95b0:	sw	s3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    95b4:	li	a4,2
    95b8:	sw	a4,4(a5)
    95bc:	lui	a4,0x2000
    95c0:	sw	a4,8(a5)
    95c4:	sw	a4,12(a5)
    95c8:	sw	a4,16(a5)
    95cc:	lui	a4,0x42008
    95d0:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    95d4:	sw	a4,20(a5)
    95d8:	lui	a4,0x42808
    95dc:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    95e0:	sw	a4,24(a5)
    95e4:	sw	a4,28(a5)
    95e8:	sw	a4,32(a5)
    95ec:	lhu	a3,952(s7)
    95f0:	lui	a4,0xffb5d
    95f4:	lw	a5,40(a4) # ffb5d028 <__stack_base+0x5c5f8>
    95f8:	zext.h	a5,a5
    95fc:	beq	a5,a3,95f4 <.L327>
    9600:	lhu	a3,984(s7)
    9604:	lui	a4,0xffb5e
    9608:	lw	a5,40(a4) # ffb5e028 <__stack_base+0x5d5f8>
    960c:	zext.h	a5,a5
    9610:	beq	a5,a3,9608 <.L328>
    9614:	lw	a3,944(s7)
    9618:	lw	a4,976(s7)
    961c:	addi	a3,a3,-1
    9620:	addi	a4,a4,-1
    9624:	ttsetadczw	3,0,0,0,0,15
    9628:	lw	a2,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    962c:	lui	a5,0xffef0
    9630:	beqz	a2,9638 <.L330>
    9634:	addi	a5,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    9638:	lw	a2,52(s0)
    963c:	andi	a2,a2,254
    9640:	bnez	a2,9638 <.L330>
    9644:	lw	a2,560(gp) # ffb00a20 <unp_cfg_context>
    9648:	beqz	a2,9ab8 <.L331>
    964c:	sw	a3,308(a5)
    9650:	sw	a4,500(a5)
    9654:	sw	zero,52(s0)
    9658:	ttstallwait	8,1024
    965c:	ttmop	1,0,0
    9660:	ttsemget	32
    9664:	sub	a5,s3,a2
    9668:	sw	a5,560(gp) # ffb00a20 <unp_cfg_context>
    966c:	bne	a2,s3,9ad4 <.L333>
    9670:	ttsetc16	41,0
    9674:	li	a0,29
    9678:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    967c:	li	a0,30
    9680:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    9684:	li	a0,26
    9688:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    968c:	li	a0,25
    9690:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    9694:	li	a0,25
    9698:	jal	71e0 <_Z17add_block_inplaceILb1EEvmmm.constprop.0>
    969c:	li	a0,27
    96a0:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    96a4:	lw	a5,872(s7)
    96a8:	ttstallwait	128,4
    96ac:	lui	a3,0x1000
    96b0:	addi	a3,a3,-256 # ffff00 <.LASF1241+0xfee62d>
    96b4:	slli	a5,a5,0x8
    96b8:	and	a5,a5,a3
    96bc:	lui	a3,0x45000
    96c0:	lui	a4,0xb30f0
    96c4:	addi	a3,a3,74 # 4500004a <__device_print_strings_info_end+0x3eb0004a>
    96c8:	add	a5,a5,a3
    96cc:	addi	a3,a4,1392 # b30f0570 <__device_print_strings_info_end+0xacbf0570>
    96d0:	sw	a3,0(s1)
    96d4:	lw	a3,12(sp)
    96d8:	addi	a4,a4,1400
    96dc:	sw	a3,0(s1)
    96e0:	sw	a4,0(s1)
    96e4:	sw	a5,0(s1)
    96e8:	jal	807c <_Z10move_blockILb1EEvmmm.constprop.1>
    96ec:	jal	81e8 <_Z10move_blockILb1EEvmmm.constprop.0>
    96f0:	addi	s9,s9,1
    96f4:	lw	a5,56(sp)
    96f8:	bltu	s9,a5,87a8 <.L335>
    96fc:	mv	s2,s7
    9700:	lw	a3,44(sp)
    9704:	lw	s9,48(sp)
    9708:	lw	a4,52(sp)
    970c:	lw	s5,196(sp)
    9710:	lw	s7,188(sp)
    9714:	lw	s8,184(sp)
    9718:	bnez	a4,9bb8 <.L481>
    971c:	li	a5,1
    9720:	beq	s9,a5,9b10 <.L482>
    9724:	lw	a4,28(sp)
    9728:	li	a5,-1
    972c:	bne	a4,a5,9adc <.L483>
    9730:	li	a1,4
    9734:	li	a0,0
    9738:	jal	6aa4 <_Z13llk_pop_tileslll.constprop.1>
    973c:	lw	s2,208(sp)
    9740:	lw	s6,192(sp)
    9744:	lw	s10,176(sp)
    9748:	lw	s11,172(sp)
    974c:	lw	ra,220(sp)
    9750:	lw	s0,216(sp)
    9754:	lw	s1,212(sp)
    9758:	lw	s3,204(sp)
    975c:	lw	s4,200(sp)
    9760:	lw	s9,180(sp)
    9764:	addi	sp,sp,224
    9768:	ret
    976c:	sw	s2,208(sp)
    9770:	lui	s2,0xffb00
    9774:	addi	s2,s2,32 # ffb00020 <cb_interface>
    9778:	lhu	a3,280(s2)
    977c:	lui	a4,0xffb48
    9780:	lw	a5,40(a4) # ffb48028 <__stack_base+0x475f8>
    9784:	zext.h	a5,a5
    9788:	beq	a5,a3,9780 <.L201>
    978c:	lw	a5,272(s2)
    9790:	lui	a4,0xffec2
    9794:	slli	a5,a5,0x4
    9798:	sh2add	s4,s4,a5
    979c:	lw	s1,0(s4)
    97a0:	lui	a5,0xffec3
    97a4:	sw	s1,0(a4) # ffec2000 <__instrn_buffer+0x82000>
    97a8:	sw	s1,0(a5) # ffec3000 <__instrn_buffer+0x83000>
    97ac:	li	a0,8
    97b0:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    97b4:	lw	s2,208(sp)
    97b8:	li	a5,-1
    97bc:	beq	s1,a5,97c4 <.LBE5770+0x10>
    97c0:	j	83b8 <.L200>
    97c4:	j	974c <.L198>
    97c8:	sub	a4,a4,s3
    97cc:	srli	t3,a5,0x4
    97d0:	mul	a0,t3,a4
    97d4:	andi	a3,a5,15
    97d8:	min	a2,a3,a4
    97dc:	add	a0,a0,a2
    97e0:	add	t3,t3,a0
    97e4:	blt	a4,a3,97ec <.LM3473>
    97e8:	j	8418 <.L206>
    97ec:	addi	t3,t3,1
    97f0:	beq	t3,a0,97f8 <.LBE5813+0x8>
    97f4:	j	8418 <.L206>
    97f8:	j	9748 <.L468>
    97fc:	sw	a1,308(a4)
    9800:	sw	a2,500(a4)
    9804:	sw	zero,52(s0)
    9808:	ttstallwait	8,1024
    980c:	ttunpacrnop	1,0,0,0,0,0,0,0,1
    9810:	ttunpacr	1,17,0,0,0,1,0,0,0,0,0,0,1
    9814:	ttunpacr	1,17,0,0,0,1,1,0,0,0,0,0,1
    9818:	ttsetadczw	2,0,0,0,0,5
    981c:	sw	s8,0(s1)
    9820:	ttsemget	32
    9824:	bne	a3,s3,9830 <.L227>
    9828:	ttsetc16	41,0
    982c:	j	89a8 <.L228>
    9830:	sub	a5,s3,a3
    9834:	j	89a4 <.L226>
    9838:	lhu	a3,120(s7)
    983c:	lui	a4,0xffb43
    9840:	lw	a5,40(a4) # ffb43028 <__stack_base+0x425f8>
    9844:	sub	a5,a5,a3
    9848:	zext.h	a5,a5
    984c:	bltu	a5,s5,9840 <.L231>
    9850:	lhu	a3,408(s7)
    9854:	lui	a4,0xffb4c
    9858:	lw	a5,40(a4) # ffb4c028 <__stack_base+0x4b5f8>
    985c:	zext.h	a5,a5
    9860:	beq	a5,a3,9858 <.L232>
    9864:	lui	a5,0xb4010
    9868:	addi	a5,a5,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    986c:	sw	a5,0(s1)
    9870:	ttsetadcxx	3,255,0
    9874:	li	a5,0
    9878:	sw	a5,0(s4)
    987c:	lw	a5,0(s4)
    9880:	and	zero,zero,a5
    9884:	lui	a5,0xffb80
    9888:	sw	s3,0(a5) # ffb80000 <__stack_base+0x7f5d0>
    988c:	li	a4,2
    9890:	sw	a4,4(a5)
    9894:	lui	a4,0x2000
    9898:	sw	a4,8(a5)
    989c:	sw	a4,12(a5)
    98a0:	sw	a4,16(a5)
    98a4:	lui	a4,0x42008
    98a8:	addi	a4,a4,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    98ac:	sw	a4,20(a5)
    98b0:	lui	a4,0x42808
    98b4:	addi	a4,a4,193 # 428080c1 <__device_print_strings_info_end+0x3c3080c1>
    98b8:	sw	a4,24(a5)
    98bc:	sw	a4,28(a5)
    98c0:	sw	a4,32(a5)
    98c4:	lw	a4,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    98c8:	lui	a5,0xffef0
    98cc:	addi	a0,a5,896 # ffef0380 <__instrn_buffer+0xb0380>
    98d0:	bnez	a4,98d8 <.L234>
    98d4:	mv	a0,a5
    98d8:	lw	a1,560(gp) # ffb00a20 <unp_cfg_context>
    98dc:	li	a3,0
    98e0:	lw	a5,112(s7)
    98e4:	lw	a4,104(s7)
    98e8:	lw	a2,400(s7)
    98ec:	addi	a5,a5,-1
    98f0:	mul	a4,a3,a4
    98f4:	add	a4,a5,a4
    98f8:	addi	a2,a2,-1
    98fc:	ttsetadczw	3,0,0,0,0,15
    9900:	lw	a5,52(s0)
    9904:	andi	a5,a5,254
    9908:	bnez	a5,9900 <.L235>
    990c:	bnez	a1,9948 <.L236>
    9910:	sw	a2,304(a0)
    9914:	sw	a4,496(a0)
    9918:	sw	zero,52(s0)
    991c:	ttstallwait	8,1024
    9920:	ttmop	1,0,0
    9924:	ttsemget	32
    9928:	li	a1,1
    992c:	ttsetc16	41,257
    9930:	addi	a3,a3,1
    9934:	bne	a3,s11,98e0 <.L240>
    9938:	lw	t5,40(s7)
    993c:	lw	t0,48(s7)
    9940:	sw	a1,560(gp) # ffb00a20 <unp_cfg_context>
    9944:	j	89c4 <.L230>
    9948:	sw	a2,308(a0)
    994c:	sw	a4,500(a0)
    9950:	sw	zero,52(s0)
    9954:	ttstallwait	8,1024
    9958:	ttmop	1,0,0
    995c:	ttsemget	32
    9960:	bne	a1,s3,9970 <.L238>
    9964:	ttsetc16	41,0
    9968:	li	a1,0
    996c:	j	9930 <.L239>
    9970:	sub	a1,s3,a1
    9974:	j	992c <.L237>
    9978:	sw	a4,308(a1)
    997c:	sw	a3,500(a1)
    9980:	sw	zero,52(s0)
    9984:	ttstallwait	8,1024
    9988:	ttmop	1,0,0
    998c:	ttsemget	32
    9990:	bne	a2,s3,99a0 <.L248>
    9994:	ttsetc16	41,0
    9998:	li	a2,0
    999c:	j	8b70 <.L249>
    99a0:	sub	a2,s3,a2
    99a4:	j	8b6c <.L247>
    99a8:	ttsetc16	41,0
    99ac:	j	8c40 <.L256>
    99b0:	lui	a4,0xffef0
    99b4:	addi	a1,a4,304 # ffef0130 <__instrn_buffer+0xb0130>
    99b8:	addi	a4,a4,308
    99bc:	j	8c04 <.L253>
    99c0:	sw	a2,308(a1)
    99c4:	sw	a0,500(a1)
    99c8:	sw	zero,52(s0)
    99cc:	ttstallwait	8,1024
    99d0:	ttmop	1,0,0
    99d4:	ttsemget	32
    99d8:	bne	a4,s3,99e8 <.L264>
    99dc:	ttsetc16	41,0
    99e0:	li	a4,0
    99e4:	j	8d94 <.L265>
    99e8:	sub	a4,s3,a4
    99ec:	j	8d90 <.L263>
    99f0:	sw	a2,308(a1)
    99f4:	sw	a0,500(a1)
    99f8:	sw	zero,52(s0)
    99fc:	ttstallwait	8,1024
    9a00:	ttmop	1,0,0
    9a04:	ttsemget	32
    9a08:	bne	a4,s3,9a18 <.L484>
    9a0c:	ttsetc16	41,0
    9a10:	li	a4,0
    9a14:	j	8f24 <.L278>
    9a18:	sub	a4,s3,a4
    9a1c:	j	8f20 <.L281>
    9a20:	sw	a2,304(a1)
    9a24:	sw	a3,496(a1)
    9a28:	sw	zero,52(s0)
    9a2c:	ttstallwait	8,1024
    9a30:	ttunpacrnop	1,0,0,0,0,0,0,0,1
    9a34:	ttunpacr	1,17,0,0,0,1,0,0,0,0,0,0,1
    9a38:	ttunpacr	1,17,0,0,0,1,1,0,0,0,0,0,1
    9a3c:	ttsetadczw	2,0,0,0,0,5
    9a40:	lui	a4,0x1030
    9a44:	sw	a4,0(s1)
    9a48:	ttsemget	32
    9a4c:	li	a4,1
    9a50:	ttsetc16	41,257
    9a54:	j	90b8 <.L290>
    9a58:	sub	a4,s3,a4
    9a5c:	ttsetc16	41,257
    9a60:	j	90b8 <.L290>
    9a64:	sw	a3,304(a5)
    9a68:	sw	a4,496(a5)
    9a6c:	sw	zero,52(s0)
    9a70:	ttstallwait	8,1024
    9a74:	ttmop	1,0,0
    9a78:	ttsemget	32
    9a7c:	sw	s3,560(gp) # ffb00a20 <unp_cfg_context>
    9a80:	ttsetc16	41,257
    9a84:	j	9290 <.L302>
    9a88:	sw	a3,304(a5)
    9a8c:	sw	a4,496(a5)
    9a90:	sw	zero,52(s0)
    9a94:	ttstallwait	8,1024
    9a98:	ttmop	1,0,0
    9a9c:	ttsemget	32
    9aa0:	sw	s3,560(gp) # ffb00a20 <unp_cfg_context>
    9aa4:	ttsetc16	41,257
    9aa8:	j	9384 <.L310>
    9aac:	sub	a3,s3,a3
    9ab0:	ttsetc16	41,257
    9ab4:	j	951c <.L323>
    9ab8:	sw	a3,304(a5)
    9abc:	sw	a4,496(a5)
    9ac0:	sw	zero,52(s0)
    9ac4:	ttstallwait	8,1024
    9ac8:	ttmop	1,0,0
    9acc:	ttsemget	32
    9ad0:	sw	s3,560(gp) # ffb00a20 <unp_cfg_context>
    9ad4:	ttsetc16	41,257
    9ad8:	j	9674 <.L334>
    9adc:	li	a0,26
    9ae0:	jal	77dc <_Z10move_blockILb1EEvmmm.constprop.3>
    9ae4:	li	a0,28
    9ae8:	jal	7c68 <_Z10move_blockILb1EEvmmm.constprop.2>
    9aec:	li	a0,30
    9af0:	jal	7c68 <_Z10move_blockILb1EEvmmm.constprop.2>
    9af4:	li	a1,4
    9af8:	li	a0,0
    9afc:	jal	6aa4 <_Z13llk_pop_tileslll.constprop.1>
    9b00:	lw	s2,208(sp)
    9b04:	lw	s6,192(sp)
    9b08:	lw	s10,176(sp)
    9b0c:	j	9748 <.L468>
    9b10:	li	a0,30
    9b14:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    9b18:	li	a0,30
    9b1c:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    9b20:	li	a0,30
    9b24:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    9b28:	li	a0,30
    9b2c:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    9b30:	li	a0,30
    9b34:	jal	7450 <_Z17llk_unpack_A_initILN7ckernel13BroadcastTypeE0ELb0ELNS0_26EltwiseBinaryReuseDestTypeE0ELb1EEvmmm.constprop.2>
    9b38:	li	a0,30
    9b3c:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    9b40:	lhu	a3,984(s2)
    9b44:	lui	a4,0xffb5e
    9b48:	lw	a5,40(a4) # ffb5e028 <__stack_base+0x5d5f8>
    9b4c:	zext.h	a5,a5
    9b50:	beq	a5,a3,9b48 <.L365>
    9b54:	lw	a0,976(s2)
    9b58:	li	a2,5
    9b5c:	mv	a1,a2
    9b60:	addi	a0,a0,-1
    9b64:	jal	6bd0 <_Z14_llk_unpack_A_ILN7ckernel13BroadcastTypeE0ELb0ELNS0_26EltwiseBinaryReuseDestTypeE0ELb1EEvmmm>
    9b68:	li	a0,30
    9b6c:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    9b70:	li	a0,26
    9b74:	jal	7138 <_Z36llk_unpack_reconfig_data_format_srcaILb1ELb0EL19p_dim_stride_target0EEvm>
    9b78:	li	a0,30
    9b7c:	jal	6d88 <_Z36llk_unpack_reconfig_data_format_srcbILb1ELb0EL19p_dim_stride_target0EEvm>
    9b80:	li	a1,30
    9b84:	li	a0,26
    9b88:	jal	6e30 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm>
    9b8c:	li	a0,28
    9b90:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    9b94:	li	a0,26
    9b98:	jal	77dc <_Z10move_blockILb1EEvmmm.constprop.3>
    9b9c:	li	a1,4
    9ba0:	li	a0,0
    9ba4:	jal	6aa4 <_Z13llk_pop_tileslll.constprop.1>
    9ba8:	lw	s2,208(sp)
    9bac:	lw	s6,192(sp)
    9bb0:	lw	s10,176(sp)
    9bb4:	j	9748 <.L468>
    9bb8:	beqz	a3,971c <.L219>
    9bbc:	lui	s4,0xb4010
    9bc0:	lui	s0,0x43800
    9bc4:	lui	s3,0x42008
    9bc8:	sw	s5,196(sp)
    9bcc:	sw	s7,188(sp)
    9bd0:	addi	s4,s4,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    9bd4:	addi	s7,sp,76
    9bd8:	addi	s0,s0,257 # 43800101 <__device_print_strings_info_end+0x3d300101>
    9bdc:	addi	s3,s3,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    9be0:	li	s5,-1
    9be4:	sw	s8,184(sp)
    9be8:	sh2add	s8,a3,s7
    9bec:	lw	a5,0(s7)
    9bf0:	beq	a5,s5,9e8c <.L339>
    9bf4:	li	a0,7
    9bf8:	jal	7c68 <_Z10move_blockILb1EEvmmm.constprop.2>
    9bfc:	lhu	a3,216(s2)
    9c00:	lui	a4,0xffb46
    9c04:	lw	a5,40(a4) # ffb46028 <__stack_base+0x455f8>
    9c08:	zext.h	a5,a5
    9c0c:	beq	a5,a3,9c04 <.L340>
    9c10:	lhu	a3,696(s2)
    9c14:	lui	a4,0xffb55
    9c18:	lw	a5,40(a4) # ffb55028 <__stack_base+0x545f8>
    9c1c:	zext.h	a5,a5
    9c20:	beq	a5,a3,9c18 <.L341>
    9c24:	lhu	a3,920(s2)
    9c28:	lui	a4,0xffb5c
    9c2c:	lw	a5,40(a4) # ffb5c028 <__stack_base+0x5b5f8>
    9c30:	zext.h	a5,a5
    9c34:	beq	a5,a3,9c2c <.L342>
    9c38:	lhu	a3,984(s2)
    9c3c:	lui	a4,0xffb5e
    9c40:	lw	a5,40(a4) # ffb5e028 <__stack_base+0x5d5f8>
    9c44:	zext.h	a5,a5
    9c48:	beq	a5,a3,9c40 <.L343>
    9c4c:	sw	s4,0(s1)
    9c50:	ttsetadcxx	1,255,0
    9c54:	li	a5,2
    9c58:	sw	a5,124(sp)
    9c5c:	li	a5,1
    9c60:	sw	a5,128(sp)
    9c64:	addi	a0,sp,124
    9c68:	lui	a5,0x2000
    9c6c:	sw	s0,132(sp)
    9c70:	sw	s0,152(sp)
    9c74:	sw	s0,156(sp)
    9c78:	sw	s3,148(sp)
    9c7c:	sw	a5,136(sp)
    9c80:	sw	a5,140(sp)
    9c84:	sw	a5,144(sp)
    9c88:	jal	6a3c <_ZN7ckernel16ckernel_template7programEv>
    9c8c:	lw	a4,912(s2)
    9c90:	addi	a4,a4,-1
    9c94:	ttsetadczw	3,0,0,0,0,15
    9c98:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9c9c:	beqz	a5,9efc <.L381>
    9ca0:	lui	a5,0xffef0
    9ca4:	addi	a2,a5,1200 # ffef04b0 <__instrn_buffer+0xb04b0>
    9ca8:	addi	a5,a5,1204
    9cac:	lui	a1,0xffe80
    9cb0:	lw	a3,52(a1) # ffe80034 <__instrn_buffer+0x40034>
    9cb4:	andi	a3,a3,254
    9cb8:	bnez	a3,9cb0 <.L345>
    9cbc:	lw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    9cc0:	bnez	a3,9cc8 <.L346>
    9cc4:	mv	a5,a2
    9cc8:	sw	a4,0(a5)
    9ccc:	lui	a5,0xffe80
    9cd0:	sw	zero,52(a5) # ffe80034 <__instrn_buffer+0x40034>
    9cd4:	ttstallwait	8,1024
    9cd8:	ttmop	1,0,0
    9cdc:	ttsemget	32
    9ce0:	lw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    9ce4:	li	a5,1
    9ce8:	sub	a4,a5,a3
    9cec:	sw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    9cf0:	beq	a3,a5,9f0c <.L347>
    9cf4:	ttsetc16	41,257
    9cf8:	lw	a4,208(s2)
    9cfc:	addi	a4,a4,-1
    9d00:	ttsetadczw	3,0,0,0,0,15
    9d04:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9d08:	beqz	a5,9f24 <.L382>
    9d0c:	lui	a5,0xffef0
    9d10:	addi	a1,a5,1200 # ffef04b0 <__instrn_buffer+0xb04b0>
    9d14:	addi	a5,a5,1204
    9d18:	lui	a0,0xffe80
    9d1c:	lw	a2,52(a0) # ffe80034 <__instrn_buffer+0x40034>
    9d20:	andi	a2,a2,254
    9d24:	bnez	a2,9d1c <.L350>
    9d28:	li	a2,1
    9d2c:	bne	a3,a2,9d34 <.L351>
    9d30:	mv	a5,a1
    9d34:	sw	a4,0(a5)
    9d38:	lui	a5,0xffe80
    9d3c:	sw	zero,52(a5) # ffe80034 <__instrn_buffer+0x40034>
    9d40:	ttstallwait	8,1024
    9d44:	ttmop	1,0,0
    9d48:	ttsemget	32
    9d4c:	lw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    9d50:	li	a5,1
    9d54:	sub	a4,a5,a3
    9d58:	sw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    9d5c:	beq	a3,a5,9f34 <.L352>
    9d60:	ttsetc16	41,257
    9d64:	lw	a4,976(s2)
    9d68:	addi	a4,a4,-1
    9d6c:	ttsetadczw	3,0,0,0,0,15
    9d70:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9d74:	beqz	a5,9f4c <.L383>
    9d78:	lui	a5,0xffef0
    9d7c:	addi	a1,a5,1200 # ffef04b0 <__instrn_buffer+0xb04b0>
    9d80:	addi	a5,a5,1204
    9d84:	lui	a0,0xffe80
    9d88:	lw	a2,52(a0) # ffe80034 <__instrn_buffer+0x40034>
    9d8c:	andi	a2,a2,254
    9d90:	bnez	a2,9d88 <.L355>
    9d94:	li	a2,1
    9d98:	bne	a3,a2,9da0 <.L356>
    9d9c:	mv	a5,a1
    9da0:	sw	a4,0(a5)
    9da4:	lui	a5,0xffe80
    9da8:	sw	zero,52(a5) # ffe80034 <__instrn_buffer+0x40034>
    9dac:	ttstallwait	8,1024
    9db0:	ttmop	1,0,0
    9db4:	ttsemget	32
    9db8:	lw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    9dbc:	li	a5,1
    9dc0:	sub	a4,a5,a3
    9dc4:	sw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    9dc8:	beq	a3,a5,9f5c <.L357>
    9dcc:	ttsetc16	41,257
    9dd0:	lw	a4,688(s2)
    9dd4:	addi	a4,a4,-1
    9dd8:	ttsetadczw	3,0,0,0,0,15
    9ddc:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9de0:	beqz	a5,9f74 <.L384>
    9de4:	lui	a5,0xffef0
    9de8:	addi	a1,a5,1200 # ffef04b0 <__instrn_buffer+0xb04b0>
    9dec:	addi	a5,a5,1204
    9df0:	lui	a0,0xffe80
    9df4:	lw	a2,52(a0) # ffe80034 <__instrn_buffer+0x40034>
    9df8:	andi	a2,a2,254
    9dfc:	bnez	a2,9df4 <.L360>
    9e00:	li	a2,1
    9e04:	bne	a3,a2,9e0c <.L361>
    9e08:	mv	a5,a1
    9e0c:	sw	a4,0(a5)
    9e10:	lui	a5,0xffe80
    9e14:	sw	zero,52(a5) # ffe80034 <__instrn_buffer+0x40034>
    9e18:	ttstallwait	8,1024
    9e1c:	ttmop	1,0,0
    9e20:	ttsemget	32
    9e24:	lw	a4,560(gp) # ffb00a20 <unp_cfg_context>
    9e28:	li	a5,1
    9e2c:	sub	a3,a5,a4
    9e30:	sw	a3,560(gp) # ffb00a20 <unp_cfg_context>
    9e34:	beq	a4,a5,9f84 <.L362>
    9e38:	ttsetc16	41,257
    9e3c:	li	a0,30
    9e40:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    9e44:	li	a0,21
    9e48:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    9e4c:	li	a0,16
    9e50:	jal	77dc <_Z10move_blockILb1EEvmmm.constprop.3>
    9e54:	li	a1,31
    9e58:	li	a0,26
    9e5c:	jal	6e30 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm>
    9e60:	li	a1,22
    9e64:	li	a0,23
    9e68:	jal	6e30 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm>
    9e6c:	li	a0,23
    9e70:	jal	71e0 <_Z17add_block_inplaceILb1EEvmmm.constprop.0>
    9e74:	li	a0,28
    9e78:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    9e7c:	li	a0,6
    9e80:	jal	6b3c <_Z13llk_pop_tileslll.constprop.0>
    9e84:	jal	807c <_Z10move_blockILb1EEvmmm.constprop.1>
    9e88:	jal	81e8 <_Z10move_blockILb1EEvmmm.constprop.0>
    9e8c:	addi	s7,s7,4
    9e90:	bne	s7,s8,9bec <.L364>
    9e94:	lw	s5,196(sp)
    9e98:	lw	s7,188(sp)
    9e9c:	lw	s8,184(sp)
    9ea0:	j	971c <.L219>
    9ea4:	addi	a4,a4,1
    9ea8:	li	a3,6
    9eac:	j	84a0 <.L214>
    9eb0:	addi	a4,a4,1
    9eb4:	li	a3,5
    9eb8:	j	848c <.L212>
    9ebc:	addi	a4,a4,1
    9ec0:	li	a3,4
    9ec4:	j	8478 <.L211>
    9ec8:	lw	a1,108(sp)
    9ecc:	sw	a2,80(sp)
    9ed0:	addi	a4,a4,1
    9ed4:	li	a3,2
    9ed8:	bltu	a1,a5,9ee0 <.L472>
    9edc:	j	8460 <.L372>
    9ee0:	addi	a4,a4,1
    9ee4:	li	a3,3
    9ee8:	j	8464 <.L210>
    9eec:	sub	a0,a5,s3
    9ef0:	addi	a0,a0,-1
    9ef4:	add	t3,t3,a0
    9ef8:	j	8410 <.L205>
    9efc:	lui	a5,0xffef0
    9f00:	addi	a2,a5,304 # ffef0130 <__instrn_buffer+0xb0130>
    9f04:	addi	a5,a5,308
    9f08:	j	9cac <.L344>
    9f0c:	ttsetc16	41,0
    9f10:	lw	a4,208(s2)
    9f14:	addi	a4,a4,-1
    9f18:	ttsetadczw	3,0,0,0,0,15
    9f1c:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9f20:	bnez	a5,9d0c <.L485>
    9f24:	lui	a5,0xffef0
    9f28:	addi	a1,a5,304 # ffef0130 <__instrn_buffer+0xb0130>
    9f2c:	addi	a5,a5,308
    9f30:	j	9d18 <.L349>
    9f34:	ttsetc16	41,0
    9f38:	lw	a4,976(s2)
    9f3c:	addi	a4,a4,-1
    9f40:	ttsetadczw	3,0,0,0,0,15
    9f44:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9f48:	bnez	a5,9d78 <.L486>
    9f4c:	lui	a5,0xffef0
    9f50:	addi	a1,a5,304 # ffef0130 <__instrn_buffer+0xb0130>
    9f54:	addi	a5,a5,308
    9f58:	j	9d84 <.L354>
    9f5c:	ttsetc16	41,0
    9f60:	lw	a4,688(s2)
    9f64:	addi	a4,a4,-1
    9f68:	ttsetadczw	3,0,0,0,0,15
    9f6c:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    9f70:	bnez	a5,9de4 <.L487>
    9f74:	lui	a5,0xffef0
    9f78:	addi	a1,a5,304 # ffef0130 <__instrn_buffer+0xb0130>
    9f7c:	addi	a5,a5,308
    9f80:	j	9df0 <.L359>
    9f84:	ttsetc16	41,0
    9f88:	j	9e3c <.L363>
00009f8c <memcpy>:
    9f8c:	xor	a5,a1,a0
    9f90:	andi	a5,a5,3
    9f94:	sltiu	a4,a2,4
    9f98:	snez	a5,a5
    9f9c:	or	a5,a5,a4
    9fa0:	add	a2,a0,a2
    9fa4:	bnez	a5,a008 <.L26>
    9fa8:	andi	a5,a0,3
    9fac:	mv	a4,a0
    9fb0:	bnez	a5,a084 <.L8>
    9fb4:	andi	a6,a2,-4
    9fb8:	sub	a3,a6,a4
    9fbc:	li	a5,32
    9fc0:	blt	a5,a3,a028 <.L9>
    9fc4:	mv	a3,a1
    9fc8:	mv	a5,a4
    9fcc:	bgeu	a4,a6,a000 <.L11>
    9fd0:	lw	a7,0(a3)
    9fd4:	addi	a5,a5,4
    9fd8:	sw	a7,-4(a5)
    9fdc:	addi	a3,a3,4
    9fe0:	bltu	a5,a6,9fd0 <.L10>
    9fe4:	addi	a6,a6,-1
    9fe8:	sub	a6,a6,a4
    9fec:	andi	a6,a6,-4
    9ff0:	addi	a1,a1,4
    9ff4:	addi	a4,a4,4
    9ff8:	add	a1,a1,a6
    9ffc:	add	a4,a4,a6
    a000:	bltu	a4,a2,a010 <.L5>
    a004:	ret
    a008:	mv	a4,a0
    a00c:	bgeu	a0,a2,a004 <.L16>
    a010:	lbu	a5,0(a1)
    a014:	addi	a4,a4,1
    a018:	sb	a5,-1(a4)
    a01c:	addi	a1,a1,1
    a020:	bne	a2,a4,a010 <.L5>
    a024:	ret
    a028:	lw	a3,0(a1)
    a02c:	lw	t0,4(a1)
    a030:	lw	t6,8(a1)
    a034:	lw	t5,12(a1)
    a038:	lw	t4,16(a1)
    a03c:	lw	t3,20(a1)
    a040:	lw	t1,24(a1)
    a044:	lw	a7,28(a1)
    a048:	sw	a3,0(a4)
    a04c:	lw	a3,32(a1)
    a050:	addi	a4,a4,36
    a054:	sw	a3,-4(a4)
    a058:	sw	t0,-32(a4)
    a05c:	sub	a3,a6,a4
    a060:	sw	t6,-28(a4)
    a064:	sw	t5,-24(a4)
    a068:	sw	t4,-20(a4)
    a06c:	sw	t3,-16(a4)
    a070:	sw	t1,-12(a4)
    a074:	sw	a7,-8(a4)
    a078:	addi	a1,a1,36
    a07c:	blt	a5,a3,a028 <.L9>
    a080:	j	9fc4 <.L12>
    a084:	lbu	a5,0(a1)
    a088:	addi	a4,a4,1
    a08c:	sb	a5,-1(a4)
    a090:	andi	a5,a4,3
    a094:	addi	a1,a1,1
    a098:	beqz	a5,9fb4 <.L7>
    a09c:	lbu	a5,0(a1)
    a0a0:	addi	a4,a4,1
    a0a4:	sb	a5,-1(a4)
    a0a8:	andi	a5,a4,3
    a0ac:	addi	a1,a1,1
    a0b0:	bnez	a5,a084 <.L8>
    a0b4:	j	9fb4 <.L7>

######## TRISC1 (math) — kernel=sdpa_flash_decode ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/sdpa_flash_decode/862833422394369673/trisc1/trisc1.elf:     file format elf32-littleriscv
00007110 <_start>:
    7110:	addi	sp,sp,-16
    7114:	sw	ra,12(sp)
    7118:	lui	a5,0xffb00
    711c:	lui	a4,0xffb00
    7120:	addi	a5,a5,560 # ffb00230 <__stack_base>
    7124:	addi	a4,a4,548 # ffb00224 <__ldm_bss_end>
    7128:	bltu	a4,a5,7144 <.L200>
    712c:	sw	zero,-4(a5)
    7130:	sw	zero,-8(a5)
    7134:	sw	zero,-12(a5)
    7138:	sw	zero,-16(a5)
    713c:	addi	a5,a5,16
    7140:	bgeu	a4,a5,712c <.L201>
    7144:	addi	a3,a5,-8
    7148:	bltu	a4,a3,7218 <.L212>
    714c:	sw	zero,-12(a5)
    7150:	sw	zero,-16(a5)
    7154:	addi	a3,a5,-4
    7158:	bltu	a4,a3,7160 <.L203>
    715c:	sw	zero,-8(a5)
    7160:	lui	a4,0xa
    7164:	addi	a4,a4,104 # a068 <__kernel_data_lma>
    7168:	addi	a5,gp,-2000 # ffb00020 <_ZL22unpack_tile_face_r_dim>
    716c:	beq	a4,a5,71d0 <.L205>
    7170:	lui	a2,0xffb00
    7174:	addi	a2,a2,544 # ffb00220 <_ZN7ckernelL20throttled_mop_statusE>
    7178:	sub	a2,a2,a5
    717c:	li	a1,8
    7180:	srai	a3,a2,0x2
    7184:	bge	a1,a2,71b4 <.L206>
    7188:	li	a6,2
    718c:	lw	a0,0(a4)
    7190:	lw	a1,4(a4)
    7194:	lw	a2,8(a4)
    7198:	addi	a4,a4,12
    719c:	addi	a5,a5,12
    71a0:	addi	a3,a3,-3
    71a4:	sw	a0,-12(a5)
    71a8:	sw	a1,-8(a5)
    71ac:	sw	a2,-4(a5)
    71b0:	blt	a6,a3,718c <.L207>
    71b4:	blez	a3,71d0 <.L205>
    71b8:	lw	a1,0(a4)
    71bc:	li	a2,2
    71c0:	sw	a1,0(a5)
    71c4:	bne	a3,a2,71d0 <.L205>
    71c8:	lw	a4,4(a4)
    71cc:	sw	a4,4(a5)
    71d0:	lw	a4,1056(zero) # 420 <.LLST56+0x1>
    71d4:	li	a3,128
    71d8:	slli	a4,a4,0x2
    71dc:	lbu	a5,1011(a4)
    71e0:	addi	a4,a4,96
    71e4:	beq	a5,a3,71f4 <.L209>
    71e8:	fence
    71ec:	lbu	a5,915(a4)
    71f0:	bne	a5,a3,71e8 <.L210>
    71f4:	ttsetc16	13,0
    71f8:	ttsetc16	29,0
    71fc:	ttsetc16	48,0
    7200:	ttzeroacc	3,0,0,1,0
    7204:	jal	83ec <_Z11kernel_mainv>
    7208:	lw	ra,12(sp)
    720c:	li	a0,0
    7210:	addi	sp,sp,16
    7214:	ret
    7218:	mv	a5,a3
    721c:	j	7154 <.L202>
00007220 <_ZN7ckernel16ckernel_template7programEv>:
    7220:	lui	a4,0xffe80
    7224:	li	a5,0
    7228:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    722c:	sw	a5,0(a4)
    7230:	lw	a5,0(a4)
    7234:	and	zero,zero,a5
    7238:	lw	a4,0(a0)
    723c:	lui	a5,0xffb80
    7240:	sw	a4,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    7244:	lw	a4,4(a0)
    7248:	sw	a4,4(a5)
    724c:	lw	a4,24(a0)
    7250:	sw	a4,8(a5)
    7254:	lw	a4,16(a0)
    7258:	sw	a4,12(a5)
    725c:	lw	a4,20(a0)
    7260:	sw	a4,16(a5)
    7264:	lw	a4,8(a0)
    7268:	sw	a4,20(a5)
    726c:	lw	a4,12(a0)
    7270:	sw	a4,24(a5)
    7274:	lw	a4,28(a0)
    7278:	sw	a4,28(a5)
    727c:	lw	a4,32(a0)
    7280:	sw	a4,32(a5)
    7284:	ret
00007288 <_Z33_llk_math_eltwise_unary_datacopy_ILN7ckernel12DataCopyTypeE0ELNS0_7DstSyncE0ELb1ELNS0_13BroadcastTypeE0ELb1EEvmmmm.constprop.3>:
    7288:	or	a0,a0,a1
    728c:	andi	a0,a0,7
    7290:	bnez	a0,72f8 <.L4>
    7294:	ttsemwait	2,128,2
    7298:	ttstallwait	2,2064
    729c:	ttsempost	128
    72a0:	lui	a4,0xffe80
    72a4:	lw	a5,60(a4) # ffe8003c <__instrn_buffer+0x4003c>
    72a8:	zext.b	a5,a5
    72ac:	beqz	a5,72a4 <.L5>
    72b0:	li	a5,1
    72b4:	sw	a5,60(a4)
    72b8:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    72bc:	lui	a4,0xffec1
    72c0:	snez	a5,a5
    72c4:	slli	a5,a5,0x9
    72c8:	sw	a5,0(a4) # ffec1000 <__instrn_buffer+0x81000>
    72cc:	ttsemwait	2,4,1
    72d0:	ttstallwait	2,2064
    72d4:	ttsemget	4
    72d8:	lui	a5,0x100ec
    72dc:	lui	a4,0xffe40
    72e0:	addi	a3,a5,4 # 100ec004 <__device_print_strings_info_end+0x9bec004>
    72e4:	mv	a4,a4
    72e8:	sw	a5,0(a4) # ffe40000 <__instrn_buffer>
    72ec:	addi	a5,a5,1
    72f0:	bne	a5,a3,72e8 <.L6>
    72f4:	ret
    72f8:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    72fc:	lui	a3,0xb2010
    7300:	snez	a5,a5
    7304:	slli	a5,a5,0x9
    7308:	lui	a4,0xffe40
    730c:	add	a5,a5,a3
    7310:	mv	a4,a4
    7314:	sw	a5,0(a4) # ffe40000 <__instrn_buffer>
    7318:	ttmop	1,0,0
    731c:	ttsetrwc	0,0,0,0,0,4
    7320:	ret
00007324 <_ZN7ckernel4sfpu24calculate_binary_max_minILb1ELi8EEEvmmm>:
    7324:	slli	a0,a0,0x6
    7328:	lui	a4,0x9300e
    732c:	lui	a5,0xffe40
    7330:	mv	a5,a5
    7334:	add	a4,a0,a4
    7338:	lui	a3,0x7020e
    733c:	slli	a1,a1,0x6
    7340:	sw	a4,0(a5) # ffe40000 <__instrn_buffer>
    7344:	add	a1,a1,a3
    7348:	slli	a2,a2,0x6
    734c:	lui	a3,0x9370c
    7350:	sw	a1,0(a5)
    7354:	add	a2,a2,a3
    7358:	lui	a3,0x9310e
    735c:	sw	a2,0(a5)
    7360:	add	a0,a0,a3
    7364:	sw	a0,0(a5)
    7368:	sw	a1,0(a5)
    736c:	sw	a2,0(a5)
    7370:	sw	a4,0(a5)
    7374:	sw	a1,0(a5)
    7378:	sw	a2,0(a5)
    737c:	sw	a0,0(a5)
    7380:	sw	a1,0(a5)
    7384:	sw	a2,0(a5)
    7388:	sw	a4,0(a5)
    738c:	sw	a1,0(a5)
    7390:	sw	a2,0(a5)
    7394:	sw	a0,0(a5)
    7398:	sw	a1,0(a5)
    739c:	sw	a2,0(a5)
    73a0:	sw	a4,0(a5)
    73a4:	sw	a1,0(a5)
    73a8:	sw	a2,0(a5)
    73ac:	sw	a0,0(a5)
    73b0:	sw	a1,0(a5)
    73b4:	sw	a2,0(a5)
    73b8:	sfpnop
    73bc:	sfpnop
    73c0:	sfpnop
    73c4:	ret
000073c8 <_Z17add_block_inplaceILb0EEvmmm.isra.0>:
    73c8:	addi	a5,gp,-2000 # ffb00020 <_ZL22unpack_tile_face_r_dim>
    73cc:	add	a0,a5,a0
    73d0:	lbu	a5,0(a0)
    73d4:	ttsetc16	12,2056
    73d8:	ttsetc16	28,8
    73dc:	ttsetc16	47,0
    73e0:	ttsetc16	13,0
    73e4:	ttsetc16	29,0
    73e8:	ttsetc16	48,0
    73ec:	ttsetc16	14,32896
    73f0:	ttsetc16	30,1024
    73f4:	ttsetc16	49,0
    73f8:	ttsetc16	15,32896
    73fc:	ttsetc16	31,36872
    7400:	ttsetc16	50,0
    7404:	lbu	a2,128(a0)
    7408:	lbu	a4,64(a0)
    740c:	lui	a3,0x38022
    7410:	mul	a4,a4,a2
    7414:	li	a2,8
    7418:	zext.b	a4,a4
    741c:	addi	a3,a3,512 # 38022200 <__device_print_strings_info_end+0x31b22200>
    7420:	li	a0,1
    7424:	bgeu	a2,a5,7430 <.L13>
    7428:	srli	a0,a5,0x3
    742c:	lui	a3,0x2000
    7430:	lui	a2,0xffe80
    7434:	li	a5,0
    7438:	addi	a2,a2,8 # ffe80008 <__instrn_buffer+0x40008>
    743c:	sw	a5,0(a2)
    7440:	lw	a5,0(a2)
    7444:	and	zero,zero,a5
    7448:	lui	a5,0xffb80
    744c:	sw	a4,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    7450:	sw	a0,4(a5)
    7454:	lui	a2,0x2000
    7458:	lui	a4,0x37cc0
    745c:	sw	a2,8(a5)
    7460:	addi	a4,a4,3 # 37cc0003 <__device_print_strings_info_end+0x317c0003>
    7464:	sw	a4,12(a5)
    7468:	sw	a2,16(a5)
    746c:	lui	a4,0x28000
    7470:	sw	a4,20(a5)
    7474:	sw	a3,24(a5)
    7478:	sw	a4,28(a5)
    747c:	sw	a4,32(a5)
    7480:	ttsetc16	7,0
    7484:	ttsetrwc	0,0,0,0,0,15
    7488:	lw	a2,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    748c:	ttsemwait	322,2,2
    7490:	snez	a3,a2
    7494:	lui	a7,0xb2010
    7498:	slli	a3,a3,0x9
    749c:	lui	a4,0xffe40
    74a0:	add	a3,a3,a7
    74a4:	mv	a4,a4
    74a8:	sw	a3,0(a4) # ffe40000 <__instrn_buffer>
    74ac:	ttmop	1,0,0
    74b0:	ttsetrwc	0,0,0,0,0,4
    74b4:	ttstallwait	2,2064
    74b8:	ttsempost	2
    74bc:	li	a6,1
    74c0:	sub	t1,a6,a2
    74c4:	ttstallwait	128,2064
    74c8:	addi	a5,a2,-1 # 1ffffff <.LASF2788+0x1fe73ae>
    74cc:	snez	a5,a5
    74d0:	slli	a5,a5,0x9
    74d4:	add	a5,a5,a7
    74d8:	sw	a5,0(a4)
    74dc:	beq	a1,a6,7558 <.L17>
    74e0:	ttsemwait	322,2,2
    74e4:	sw	a5,0(a4)
    74e8:	ttmop	1,0,0
    74ec:	ttsetrwc	0,0,0,0,0,4
    74f0:	ttstallwait	2,2064
    74f4:	ttsempost	2
    74f8:	ttstallwait	128,2064
    74fc:	li	a6,2
    7500:	sw	a3,0(a4)
    7504:	beq	a1,a6,7550 <.L15>
    7508:	ttsemwait	322,2,2
    750c:	sw	a3,0(a4)
    7510:	ttmop	1,0,0
    7514:	ttsetrwc	0,0,0,0,0,4
    7518:	ttstallwait	2,2064
    751c:	ttsempost	2
    7520:	ttstallwait	128,2064
    7524:	li	a6,4
    7528:	sw	a5,0(a4)
    752c:	bne	a1,a6,7558 <.L17>
    7530:	ttsemwait	322,2,2
    7534:	sw	a5,0(a4)
    7538:	ttmop	1,0,0
    753c:	ttsetrwc	0,0,0,0,0,4
    7540:	ttstallwait	2,2064
    7544:	ttsempost	2
    7548:	ttstallwait	128,2064
    754c:	sw	a3,0(a4)
    7550:	sw	a2,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7554:	ret
    7558:	mv	a2,t1
    755c:	sw	a2,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7560:	ret
00007564 <_Z17add_block_inplaceILb0EEvmmm.constprop.0.isra.0>:
    7564:	ttsetc16	12,2056
    7568:	ttsetc16	28,8
    756c:	ttsetc16	47,0
    7570:	ttsetc16	13,0
    7574:	ttsetc16	29,0
    7578:	ttsetc16	48,0
    757c:	ttsetc16	14,32896
    7580:	ttsetc16	30,1024
    7584:	ttsetc16	49,0
    7588:	ttsetc16	15,32896
    758c:	ttsetc16	31,36872
    7590:	ttsetc16	50,0
    7594:	lui	a4,0xffe80
    7598:	li	a5,0
    759c:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    75a0:	sw	a5,0(a4)
    75a4:	lw	a5,0(a4)
    75a8:	and	zero,zero,a5
    75ac:	lui	a5,0xffb80
    75b0:	li	a4,2
    75b4:	sw	a4,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    75b8:	sw	a4,4(a5)
    75bc:	lui	a3,0x2000
    75c0:	lui	a4,0x37cc0
    75c4:	sw	a3,8(a5)
    75c8:	addi	a4,a4,3 # 37cc0003 <__device_print_strings_info_end+0x317c0003>
    75cc:	sw	a4,12(a5)
    75d0:	sw	a3,16(a5)
    75d4:	lui	a4,0x28000
    75d8:	sw	a4,20(a5)
    75dc:	sw	a3,24(a5)
    75e0:	sw	a4,28(a5)
    75e4:	sw	a4,32(a5)
    75e8:	ttsetc16	7,0
    75ec:	ttsetrwc	0,0,0,0,0,15
    75f0:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    75f4:	ttsemwait	322,2,2
    75f8:	snez	a3,a5
    75fc:	lui	a2,0xb2010
    7600:	slli	a3,a3,0x9
    7604:	lui	a4,0xffe40
    7608:	add	a3,a3,a2
    760c:	mv	a4,a4
    7610:	sw	a3,0(a4) # ffe40000 <__instrn_buffer>
    7614:	ttmop	1,0,0
    7618:	ttsetrwc	0,0,0,0,0,4
    761c:	ttstallwait	2,2064
    7620:	ttsempost	2
    7624:	ttstallwait	128,2064
    7628:	addi	a5,a5,-1
    762c:	snez	a5,a5
    7630:	slli	a5,a5,0x9
    7634:	add	a5,a5,a2
    7638:	sw	a5,0(a4)
    763c:	ttsemwait	322,2,2
    7640:	sw	a5,0(a4)
    7644:	ttmop	1,0,0
    7648:	ttsetrwc	0,0,0,0,0,4
    764c:	ttstallwait	2,2064
    7650:	ttsempost	2
    7654:	ttstallwait	128,2064
    7658:	sw	a3,0(a4)
    765c:	ttsemwait	322,2,2
    7660:	sw	a3,0(a4)
    7664:	ttmop	1,0,0
    7668:	ttsetrwc	0,0,0,0,0,4
    766c:	ttstallwait	2,2064
    7670:	ttsempost	2
    7674:	ttstallwait	128,2064
    7678:	sw	a5,0(a4)
    767c:	ttsemwait	322,2,2
    7680:	sw	a5,0(a4)
    7684:	ttmop	1,0,0
    7688:	ttsetrwc	0,0,0,0,0,4
    768c:	ttstallwait	2,2064
    7690:	ttsempost	2
    7694:	ttstallwait	128,2064
    7698:	sw	a3,0(a4)
    769c:	ret
000076a0 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm.isra.0>:
    76a0:	addi	a4,gp,-2000 # ffb00020 <_ZL22unpack_tile_face_r_dim>
    76a4:	add	a5,a4,a0
    76a8:	lbu	a5,0(a5)
    76ac:	ttsetc16	12,2056
    76b0:	ttsetc16	28,8
    76b4:	ttsetc16	47,0
    76b8:	ttsetc16	13,0
    76bc:	ttsetc16	29,0
    76c0:	ttsetc16	48,0
    76c4:	ttsetc16	14,32896
    76c8:	ttsetc16	30,9216
    76cc:	ttsetc16	49,0
    76d0:	ttsetc16	15,32896
    76d4:	ttsetc16	31,36872
    76d8:	ttsetc16	50,0
    76dc:	li	a3,8
    76e0:	li	a2,1
    76e4:	bgeu	a3,a5,76ec <.L21>
    76e8:	srli	a2,a5,0x3
    76ec:	lui	a3,0xffe80
    76f0:	li	a5,0
    76f4:	addi	a3,a3,8 # ffe80008 <__instrn_buffer+0x40008>
    76f8:	sw	a5,0(a3)
    76fc:	lw	a5,0(a3)
    7700:	and	zero,zero,a5
    7704:	lui	a5,0xffb80
    7708:	li	a3,2
    770c:	sw	a3,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    7710:	sw	a2,4(a5)
    7714:	lui	a3,0x2000
    7718:	sw	a3,8(a5)
    771c:	sw	a3,12(a5)
    7720:	sw	a3,16(a5)
    7724:	lui	a2,0x27080
    7728:	sw	a2,20(a5)
    772c:	sw	a3,24(a5)
    7730:	lui	a3,0x2748c
    7734:	sw	a3,28(a5)
    7738:	lui	a3,0x27088
    773c:	sw	a3,32(a5)
    7740:	ttsetc16	7,0
    7744:	ttsetrwc	0,0,0,0,0,15
    7748:	ttsemwait	322,2,2
    774c:	add	a5,a4,a0
    7750:	lw	a0,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7754:	lbu	t3,0(a5)
    7758:	snez	a6,a0
    775c:	slli	a6,a6,0x9
    7760:	lui	a3,0xb2010
    7764:	li	a7,8
    7768:	lbu	a2,64(a5)
    776c:	lbu	a4,128(a5)
    7770:	add	a1,a6,a3
    7774:	bgeu	a7,t3,7818 <.L22>
    7778:	lui	a7,0xffe40
    777c:	mv	a7,a7
    7780:	addi	a3,a3,256 # b2010100 <__device_print_strings_info_end+0xabb10100>
    7784:	sw	a1,0(a7) # ffe40000 <__instrn_buffer>
    7788:	add	a6,a6,a3
    778c:	beqz	a2,78a4 <.L23>
    7790:	beqz	a4,77c8 <.L40>
    7794:	li	a3,0
    7798:	li	a5,0
    779c:	ttmop	1,0,0
    77a0:	addi	a5,a5,1
    77a4:	bne	a5,a4,779c <.L25>
    77a8:	ttsetrwc	2,0,0,0,0,0
    77ac:	addi	a3,a3,1
    77b0:	bne	a2,a3,7798 <.L26>
    77b4:	ttsetrwc	0,0,0,0,0,4
    77b8:	addi	a1,a1,64
    77bc:	beq	a1,a6,77e4 <.L28>
    77c0:	sw	a1,0(a7)
    77c4:	bnez	a4,7794 <.L54>
    77c8:	li	a5,0
    77cc:	ttsetrwc	2,0,0,0,0,0
    77d0:	addi	a5,a5,1
    77d4:	bne	a5,a2,77cc <.L24>
    77d8:	ttsetrwc	0,0,0,0,0,4
    77dc:	addi	a1,a1,64
    77e0:	bne	a1,a6,77c0 <.L55>
    77e4:	ttstallwait	2,2064
    77e8:	ttsempost	2
    77ec:	li	a5,1
    77f0:	sub	a5,a5,a0
    77f4:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    77f8:	ttstallwait	128,2064
    77fc:	addi	a5,a0,-1
    7800:	snez	a5,a5
    7804:	slli	a5,a5,0x9
    7808:	lui	a4,0xb2010
    780c:	add	a5,a5,a4
    7810:	sw	a5,0(a7)
    7814:	ret
    7818:	addi	a3,a3,256
    781c:	lui	a7,0xffe40
    7820:	add	a6,a6,a3
    7824:	mv	a7,a7
    7828:	sw	a1,0(a7) # ffe40000 <__instrn_buffer>
    782c:	beqz	a2,7890 <.L30>
    7830:	beqz	a4,786c <.L51>
    7834:	li	a3,0
    7838:	li	a5,0
    783c:	ttmop	1,0,0
    7840:	ttincrwc	8,8,0,0
    7844:	addi	a5,a5,1
    7848:	bne	a4,a5,783c <.L36>
    784c:	ttsetrwc	2,0,0,0,0,0
    7850:	addi	a3,a3,1
    7854:	bne	a3,a2,7838 <.L31>
    7858:	ttsetrwc	0,0,0,0,0,4
    785c:	addi	a1,a1,64
    7860:	beq	a6,a1,77e4 <.L28>
    7864:	sw	a1,0(a7)
    7868:	bnez	a4,7834 <.L41>
    786c:	li	a5,0
    7870:	ttsetrwc	2,0,0,0,0,0
    7874:	addi	a5,a5,1
    7878:	bne	a2,a5,7870 <.L32>
    787c:	ttsetrwc	0,0,0,0,0,4
    7880:	addi	a1,a1,64
    7884:	beq	a6,a1,77e4 <.L28>
    7888:	sw	a1,0(a7)
    788c:	j	786c <.L51>
    7890:	ttsetrwc	0,0,0,0,0,4
    7894:	addi	a1,a1,64
    7898:	bne	a6,a1,7828 <.L35>
    789c:	j	77e4 <.L28>
    78a0:	sw	a1,0(a7)
    78a4:	ttsetrwc	0,0,0,0,0,4
    78a8:	addi	a1,a1,64
    78ac:	bne	a1,a6,78a0 <.L56>
    78b0:	j	77e4 <.L28>
000078b4 <_Z32calculate_exponential_polynomialILb1ELi4ELb0ELi4ELb1ELt15797EEvv>:
    78b4:	ttsetc16	19,0
    78b8:	ttsetc16	35,0
    78bc:	ttsetc16	54,0
    78c0:	sfploadi	L3,-8791,10
    78c4:	sfploadi	L3,15659,8
    78c8:	sfploadi	L4,-3166,10
    78cc:	sfploadi	L4,15915,8
    78d0:	sfploadi	L5,-548,10
    78d4:	sfploadi	L5,16127,8
    78d8:	sfploadi	L6,-633,10
    78dc:	sfploadi	L6,16255,8
    78e0:	sfploadi	L7,1,10
    78e4:	sfploadi	L7,16256,8
    78e8:	sfpload	L2,0,3,7
    78ec:	sfploadi	L0,15797,0
    78f0:	sfpmad	L2,L2,L0,L9,0
    78f4:	sfploadi	L1,-21957,10
    78f8:	sfploadi	L1,16312,8
    78fc:	sfpmad	L0,L2,L1,L9,0
    7900:	sfpstochrnd	L1,L0,L0,0,3,0
    7904:	sfpcast	L1,L1,0
    7908:	sfploadi	L0,29208,10
    790c:	sfploadi	L0,-16591,8
    7910:	sfpmad	L0,L1,L0,L2,0
    7914:	sfpmad	L2,L0,L3,L4,0
    7918:	sfpmad	L2,L0,L2,L5,0
    791c:	sfpmad	L2,L0,L2,L6,0
    7920:	sfpmad	L0,L0,L2,L7,0
    7924:	lui	a5,0xffe40
    7928:	lui	a4,0x75430
    792c:	mv	a5,a5
    7930:	addi	a4,a4,-496 # 7542fe10 <__device_print_strings_info_end+0x6ef2fe10>
    7934:	sw	a4,0(a5) # ffe40000 <__instrn_buffer>
    7938:	sfpstochrnd	L2,L0,L1,0,2,0
    793c:	sfpsetexp	L2,L9,0x000,0
    7940:	sfpmad	L2,L0,L2,L9,0
    7944:	sfpsetcc	L1,0x000,6
    7948:	sfploadi	L2,0,0
    794c:	sfpencc	0x000,0
    7950:	sfpstore	L2,0,3,7
    7954:	ttincrwc	0,4,0,0
    7958:	sfpload	L2,0,3,7
    795c:	sfploadi	L0,15797,0
    7960:	sfpmad	L2,L2,L0,L9,0
    7964:	sfploadi	L1,-21957,10
    7968:	sfploadi	L1,16312,8
    796c:	sfpmad	L0,L2,L1,L9,0
    7970:	sfpstochrnd	L1,L0,L0,0,3,0
    7974:	sfpcast	L1,L1,0
    7978:	sfploadi	L0,29208,10
    797c:	sfploadi	L0,-16591,8
    7980:	sfpmad	L0,L1,L0,L2,0
    7984:	sfpmad	L2,L0,L3,L4,0
    7988:	sfpmad	L2,L0,L2,L5,0
    798c:	sfpmad	L2,L0,L2,L6,0
    7990:	sfpmad	L0,L0,L2,L7,0
    7994:	sw	a4,0(a5)
    7998:	sfpstochrnd	L2,L0,L1,0,2,0
    799c:	sfpsetexp	L2,L9,0x000,0
    79a0:	sfpmad	L2,L0,L2,L9,0
    79a4:	sfpsetcc	L1,0x000,6
    79a8:	sfploadi	L2,0,0
    79ac:	sfpencc	0x000,0
    79b0:	sfpstore	L2,0,3,7
    79b4:	ttincrwc	0,4,0,0
    79b8:	sfpload	L2,0,3,7
    79bc:	sfploadi	L0,15797,0
    79c0:	sfpmad	L2,L2,L0,L9,0
    79c4:	sfploadi	L1,-21957,10
    79c8:	sfploadi	L1,16312,8
    79cc:	sfpmad	L0,L2,L1,L9,0
    79d0:	sfpstochrnd	L1,L0,L0,0,3,0
    79d4:	sfpcast	L1,L1,0
    79d8:	sfploadi	L0,29208,10
    79dc:	sfploadi	L0,-16591,8
    79e0:	sfpmad	L0,L1,L0,L2,0
    79e4:	sfpmad	L2,L0,L3,L4,0
    79e8:	sfpmad	L2,L0,L2,L5,0
    79ec:	sfpmad	L2,L0,L2,L6,0
    79f0:	sfpmad	L0,L0,L2,L7,0
    79f4:	sw	a4,0(a5)
    79f8:	sfpstochrnd	L2,L0,L1,0,2,0
    79fc:	sfpsetexp	L2,L9,0x000,0
    7a00:	sfpmad	L2,L0,L2,L9,0
    7a04:	sfpsetcc	L1,0x000,6
    7a08:	sfploadi	L2,0,0
    7a0c:	sfpencc	0x000,0
    7a10:	sfpstore	L2,0,3,7
    7a14:	ttincrwc	0,4,0,0
    7a18:	sfpload	L2,0,3,7
    7a1c:	sfploadi	L0,15797,0
    7a20:	sfpmad	L2,L2,L0,L9,0
    7a24:	sfploadi	L1,-21957,10
    7a28:	sfploadi	L1,16312,8
    7a2c:	sfpmad	L0,L2,L1,L9,0
    7a30:	sfpstochrnd	L1,L0,L0,0,3,0
    7a34:	sfpcast	L1,L1,0
    7a38:	sfploadi	L0,29208,10
    7a3c:	sfploadi	L0,-16591,8
    7a40:	sfpmad	L0,L1,L0,L2,0
    7a44:	sfpmad	L2,L0,L3,L4,0
    7a48:	sfpmad	L2,L0,L2,L5,0
    7a4c:	sfpmad	L2,L0,L2,L6,0
    7a50:	sfpmad	L0,L0,L2,L7,0
    7a54:	sw	a4,0(a5)
    7a58:	sfpstochrnd	L2,L0,L1,0,2,0
    7a5c:	sfpsetexp	L2,L9,0x000,0
    7a60:	sfpmad	L2,L0,L2,L9,0
    7a64:	sfpsetcc	L1,0x000,6
    7a68:	sfploadi	L2,0,0
    7a6c:	sfpencc	0x000,0
    7a70:	sfpstore	L2,0,3,7
    7a74:	ttincrwc	0,4,0,0
    7a78:	ret
00007a7c <_Z34calculate_exponential_first_columnILb0ELt15797EEvv>:
    7a7c:	j	78b4 <_Z32calculate_exponential_polynomialILb1ELi4ELb0ELi4ELb1ELt15797EEvv>
00007a80 <_Z28calculate_recip_first_columnILb1EEvv>:
    7a80:	ttreplay	0,26,1,1
    7a84:	sfpload	L0,0,0,7
    7a88:	sfpsetsgn	L2,L0,0x001,1
    7a8c:	sfpsetexp	L2,L2,0x07E,1
    7a90:	sfploadi	L1,16312,8
    7a94:	sfploadi	L1,-21957,10
    7a98:	sfpmul	L3,L2,L1,L9,0
    7a9c:	sfpnop
    7aa0:	sfpaddi	L3,16384,0
    7aa4:	sfpnop
    7aa8:	sfpmul	L1,L1,L3,L9,0
    7aac:	sfpnop
    7ab0:	sfpmul	L2,L2,L1,L9,0
    7ab4:	sfpnop
    7ab8:	sfpaddi	L2,16384,0
    7abc:	sfpnop
    7ac0:	sfpmul	L1,L1,L2,L9,0
    7ac4:	sfpexexp	L0,L0,0
    7ac8:	sfpexexp	L2,L1,0
    7acc:	sfpiadd	L0,L2,0x000,6
    7ad0:	sfpiadd	L0,L0,0x07E,1
    7ad4:	sfploadi	L1,0,0
    7ad8:	sfploadi	L0,0,4
    7adc:	sfpencc	0x003,10
    7ae0:	sfpsetexp	L0,L1,0x000,0
    7ae4:	sfpstore	L0,0,0,7
    7ae8:	ttincrwc	0,4,0,0
    7aec:	ttreplay	0,26,0,0
    7af0:	ttreplay	0,26,0,0
    7af4:	ttreplay	0,26,0,0
    7af8:	ret
00007afc <_Z38_llk_math_eltwise_unary_datacopy_init_ILN7ckernel12DataCopyTypeE0ELb1ELNS0_13BroadcastTypeE0ELb0ELb0EEvmmb.constprop.0>:
    7afc:	ttsetc16	15,0
    7b00:	ttsetc16	31,0
    7b04:	ttsetc16	50,0
    7b08:	ttsetc16	12,1
    7b0c:	ttsetc16	28,1
    7b10:	ttsetc16	47,0
    7b14:	ttsetc16	14,8
    7b18:	ttsetc16	30,8
    7b1c:	ttsetc16	49,0
    7b20:	li	a5,9
    7b24:	lui	a4,0xffe80
    7b28:	beq	a1,a5,7b88 <.L61>
    7b2c:	li	a5,0
    7b30:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    7b34:	sw	a5,0(a4)
    7b38:	lw	a5,0(a4)
    7b3c:	and	zero,zero,a5
    7b40:	lui	a5,0xffb80
    7b44:	sw	a0,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    7b48:	li	a4,2
    7b4c:	sw	a4,4(a5)
    7b50:	lui	a3,0x2000
    7b54:	lui	a4,0x37c00
    7b58:	sw	a3,8(a5)
    7b5c:	addi	a4,a4,3 # 37c00003 <__device_print_strings_info_end+0x31700003>
    7b60:	sw	a4,12(a5)
    7b64:	sw	a3,16(a5)
    7b68:	lui	a4,0x28008
    7b6c:	sw	a4,20(a5)
    7b70:	sw	a3,24(a5)
    7b74:	sw	a4,28(a5)
    7b78:	sw	a4,32(a5)
    7b7c:	ttsetc16	7,0
    7b80:	ttsetrwc	0,0,0,0,0,15
    7b84:	ret
    7b88:	li	a5,0
    7b8c:	addi	a4,a4,8 # 28008008 <__device_print_strings_info_end+0x21b08008>
    7b90:	sw	a5,0(a4)
    7b94:	lw	a5,0(a4)
    7b98:	and	zero,zero,a5
    7b9c:	lui	a5,0xffb80
    7ba0:	sw	a0,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    7ba4:	li	a4,2
    7ba8:	sw	a4,4(a5)
    7bac:	lui	a3,0x2000
    7bb0:	lui	a4,0x37c00
    7bb4:	sw	a3,8(a5)
    7bb8:	addi	a4,a4,3 # 37c00003 <__device_print_strings_info_end+0x31700003>
    7bbc:	sw	a4,12(a5)
    7bc0:	sw	a3,16(a5)
    7bc4:	lui	a4,0x1200a
    7bc8:	sw	a4,20(a5)
    7bcc:	sw	a3,24(a5)
    7bd0:	sw	a4,28(a5)
    7bd4:	sw	a4,32(a5)
    7bd8:	ttsetc16	7,0
    7bdc:	ttsetrwc	0,0,0,0,0,15
    7be0:	ret
00007be4 <_Z10move_blockILb1EEvmmm.constprop.3>:
    7be4:	addi	a5,gp,-2000 # ffb00020 <_ZL22unpack_tile_face_r_dim>
    7be8:	add	a4,a5,a0
    7bec:	sh2add	a5,a0,a5
    7bf0:	lbu	a3,192(a4) # 1200a0c0 <__device_print_strings_info_end+0xbb0a0c0>
    7bf4:	lw	a7,256(a5)
    7bf8:	ttsetc16	15,0
    7bfc:	ttsetc16	31,0
    7c00:	ttsetc16	50,0
    7c04:	ttsetc16	12,1
    7c08:	ttsetc16	28,1
    7c0c:	ttsetc16	47,0
    7c10:	ttsetc16	14,8
    7c14:	ttsetc16	30,8
    7c18:	ttsetc16	49,0
    7c1c:	li	a5,9
    7c20:	lui	a4,0xffe80
    7c24:	beq	a7,a5,7d60 <.L64>
    7c28:	li	a5,0
    7c2c:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    7c30:	sw	a5,0(a4)
    7c34:	lw	a5,0(a4)
    7c38:	and	zero,zero,a5
    7c3c:	lui	a5,0xffb80
    7c40:	sw	a3,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    7c44:	li	a4,2
    7c48:	sw	a4,4(a5)
    7c4c:	lui	a3,0x2000
    7c50:	lui	a4,0x37c00
    7c54:	sw	a3,8(a5)
    7c58:	addi	a4,a4,3 # 37c00003 <__device_print_strings_info_end+0x31700003>
    7c5c:	sw	a4,12(a5)
    7c60:	sw	a3,16(a5)
    7c64:	lui	a4,0x28008
    7c68:	sw	a4,20(a5)
    7c6c:	sw	a3,24(a5)
    7c70:	sw	a4,28(a5)
    7c74:	sw	a4,32(a5)
    7c78:	ttsetc16	7,0
    7c7c:	ttsetrwc	0,0,0,0,0,15
    7c80:	addi	a5,gp,-1744 # ffb00120 <_ZL17unpack_dst_format>
    7c84:	sh2add	a0,a0,a5
    7c88:	lw	a5,0(a0)
    7c8c:	or	a7,a7,a5
    7c90:	lui	a3,0xffe40
    7c94:	lui	a0,0x100ec
    7c98:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7c9c:	andi	a7,a7,7
    7ca0:	mv	a3,a3
    7ca4:	addi	a0,a0,4 # 100ec004 <__device_print_strings_info_end+0x9bec004>
    7ca8:	li	a2,4
    7cac:	lui	a6,0xb2010
    7cb0:	lui	a1,0xffe80
    7cb4:	li	t3,1
    7cb8:	lui	t4,0xffec1
    7cbc:	ttsemwait	322,2,2
    7cc0:	bnez	a7,7d40 <.L66>
    7cc4:	ttsemwait	2,128,2
    7cc8:	ttstallwait	2,2064
    7ccc:	ttsempost	128
    7cd0:	lw	a5,60(a1) # ffe8003c <__instrn_buffer+0x4003c>
    7cd4:	zext.b	a5,a5
    7cd8:	beqz	a5,7cd0 <.L67>
    7cdc:	snez	a4,a4
    7ce0:	slli	a4,a4,0x9
    7ce4:	sw	t3,60(a1)
    7ce8:	sw	a4,0(t4) # ffec1000 <__instrn_buffer+0x81000>
    7cec:	ttsemwait	2,4,1
    7cf0:	ttstallwait	2,2064
    7cf4:	ttsemget	4
    7cf8:	lui	a5,0x100ec
    7cfc:	sw	a5,0(a3) # ffe40000 <__instrn_buffer>
    7d00:	addi	a5,a5,1 # 100ec001 <__device_print_strings_info_end+0x9bec001>
    7d04:	bne	a5,a0,7cfc <.L68>
    7d08:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7d0c:	ttstallwait	2,2064
    7d10:	ttsempost	2
    7d14:	sub	a4,t3,a5
    7d18:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7d1c:	ttstallwait	128,2064
    7d20:	addi	a5,a5,-1
    7d24:	snez	a5,a5
    7d28:	slli	a5,a5,0x9
    7d2c:	add	a5,a5,a6
    7d30:	sw	a5,0(a3)
    7d34:	addi	a2,a2,-1 # 2707ffff <__device_print_strings_info_end+0x20b7ffff>
    7d38:	bnez	a2,7cbc <.L70>
    7d3c:	ret
    7d40:	snez	a5,a4
    7d44:	slli	a5,a5,0x9
    7d48:	add	a5,a5,a6
    7d4c:	sw	a5,0(a3)
    7d50:	ttmop	1,0,0
    7d54:	ttsetrwc	0,0,0,0,0,4
    7d58:	mv	a5,a4
    7d5c:	j	7d0c <.L69>
    7d60:	li	a5,0
    7d64:	addi	a4,a4,8 # 28008008 <__device_print_strings_info_end+0x21b08008>
    7d68:	sw	a5,0(a4)
    7d6c:	lw	a5,0(a4)
    7d70:	and	zero,zero,a5
    7d74:	lui	a5,0xffb80
    7d78:	sw	a3,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    7d7c:	li	a4,2
    7d80:	sw	a4,4(a5)
    7d84:	lui	a3,0x2000
    7d88:	lui	a4,0x37c00
    7d8c:	sw	a3,8(a5)
    7d90:	addi	a4,a4,3 # 37c00003 <__device_print_strings_info_end+0x31700003>
    7d94:	sw	a4,12(a5)
    7d98:	sw	a3,16(a5)
    7d9c:	lui	a4,0x1200a
    7da0:	sw	a4,20(a5)
    7da4:	sw	a3,24(a5)
    7da8:	sw	a4,28(a5)
    7dac:	sw	a4,32(a5)
    7db0:	j	7c78 <.L65>
00007db4 <_Z10move_blockILb1EEvmmm.constprop.0>:
    7db4:	ttsetc16	15,0
    7db8:	ttsetc16	31,0
    7dbc:	ttsetc16	50,0
    7dc0:	ttsetc16	12,1
    7dc4:	ttsetc16	28,1
    7dc8:	ttsetc16	47,0
    7dcc:	ttsetc16	14,8
    7dd0:	ttsetc16	30,8
    7dd4:	ttsetc16	49,0
    7dd8:	lui	a4,0xffe80
    7ddc:	li	a5,0
    7de0:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    7de4:	sw	a5,0(a4)
    7de8:	lw	a5,0(a4)
    7dec:	and	zero,zero,a5
    7df0:	lui	a5,0xffb80
    7df4:	li	a4,2
    7df8:	sw	a4,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    7dfc:	sw	a4,4(a5)
    7e00:	lui	a3,0x2000
    7e04:	lui	a4,0x37c00
    7e08:	sw	a3,8(a5)
    7e0c:	addi	a4,a4,3 # 37c00003 <__device_print_strings_info_end+0x31700003>
    7e10:	sw	a4,12(a5)
    7e14:	sw	a3,16(a5)
    7e18:	lui	a4,0x28008
    7e1c:	sw	a4,20(a5)
    7e20:	sw	a3,24(a5)
    7e24:	sw	a4,28(a5)
    7e28:	sw	a4,32(a5)
    7e2c:	ttsetc16	7,0
    7e30:	ttsetrwc	0,0,0,0,0,15
    7e34:	ttsemwait	322,2,2
    7e38:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7e3c:	lui	a2,0xb2010
    7e40:	snez	a4,a5
    7e44:	slli	a4,a4,0x9
    7e48:	lui	a3,0xffe40
    7e4c:	add	a4,a4,a2
    7e50:	mv	a3,a3
    7e54:	sw	a4,0(a3) # ffe40000 <__instrn_buffer>
    7e58:	ttmop	1,0,0
    7e5c:	ttsetrwc	0,0,0,0,0,4
    7e60:	ttstallwait	2,2064
    7e64:	ttsempost	2
    7e68:	li	a4,1
    7e6c:	sub	a4,a4,a5
    7e70:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7e74:	ttstallwait	128,2064
    7e78:	addi	a5,a5,-1
    7e7c:	snez	a5,a5
    7e80:	slli	a5,a5,0x9
    7e84:	add	a5,a5,a2
    7e88:	sw	a5,0(a3)
    7e8c:	ret
00007e90 <_Z10move_blockILb1EEvmmm.constprop.2>:
    7e90:	addi	a5,gp,-2000 # ffb00020 <_ZL22unpack_tile_face_r_dim>
    7e94:	add	a4,a5,a0
    7e98:	sh2add	a5,a0,a5
    7e9c:	lbu	a2,192(a4) # 280080c0 <__device_print_strings_info_end+0x21b080c0>
    7ea0:	lw	a5,256(a5)
    7ea4:	ttsetc16	15,0
    7ea8:	ttsetc16	31,0
    7eac:	ttsetc16	50,0
    7eb0:	ttsetc16	12,1
    7eb4:	ttsetc16	28,1
    7eb8:	ttsetc16	47,0
    7ebc:	ttsetc16	14,8
    7ec0:	ttsetc16	30,8
    7ec4:	ttsetc16	49,0
    7ec8:	li	a4,9
    7ecc:	lui	a3,0xffe80
    7ed0:	beq	a5,a4,800c <.L77>
    7ed4:	li	a4,0
    7ed8:	addi	a3,a3,8 # ffe80008 <__instrn_buffer+0x40008>
    7edc:	sw	a4,0(a3)
    7ee0:	lw	a4,0(a3)
    7ee4:	and	zero,zero,a4
    7ee8:	lui	a4,0xffb80
    7eec:	sw	a2,0(a4) # ffb80000 <__global_pointer$+0x7f810>
    7ef0:	li	a3,2
    7ef4:	sw	a3,4(a4)
    7ef8:	lui	a2,0x2000
    7efc:	lui	a3,0x37c00
    7f00:	sw	a2,8(a4)
    7f04:	addi	a3,a3,3 # 37c00003 <__device_print_strings_info_end+0x31700003>
    7f08:	sw	a3,12(a4)
    7f0c:	sw	a2,16(a4)
    7f10:	lui	a3,0x28008
    7f14:	sw	a3,20(a4)
    7f18:	sw	a2,24(a4)
    7f1c:	sw	a3,28(a4)
    7f20:	sw	a3,32(a4)
    7f24:	ttsetc16	7,0
    7f28:	ttsetrwc	0,0,0,0,0,15
    7f2c:	ttsemwait	322,2,2
    7f30:	addi	a4,gp,-1744 # ffb00120 <_ZL17unpack_dst_format>
    7f34:	sh2add	a0,a0,a4
    7f38:	lw	a4,0(a0)
    7f3c:	or	a5,a5,a4
    7f40:	andi	a5,a5,7
    7f44:	bnez	a5,7fb0 <.L86>
    7f48:	ttsemwait	2,128,2
    7f4c:	ttstallwait	2,2064
    7f50:	ttsempost	128
    7f54:	lui	a4,0xffe80
    7f58:	lw	a5,60(a4) # ffe8003c <__instrn_buffer+0x4003c>
    7f5c:	zext.b	a5,a5
    7f60:	beqz	a5,7f58 <.L81>
    7f64:	li	a5,1
    7f68:	sw	a5,60(a4)
    7f6c:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7f70:	lui	a4,0xffec1
    7f74:	snez	a5,a5
    7f78:	slli	a5,a5,0x9
    7f7c:	sw	a5,0(a4) # ffec1000 <__instrn_buffer+0x81000>
    7f80:	ttsemwait	2,4,1
    7f84:	ttstallwait	2,2064
    7f88:	ttsemget	4
    7f8c:	lui	a5,0x100ec
    7f90:	lui	a4,0xffe40
    7f94:	addi	a3,a5,4 # 100ec004 <__device_print_strings_info_end+0x9bec004>
    7f98:	mv	a4,a4
    7f9c:	sw	a5,0(a4) # ffe40000 <__instrn_buffer>
    7fa0:	addi	a5,a5,1
    7fa4:	bne	a5,a3,7f9c <.L82>
    7fa8:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7fac:	j	7fd8 <.L80>
    7fb0:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7fb4:	lui	a1,0xb2010
    7fb8:	snez	a3,a5
    7fbc:	slli	a3,a3,0x9
    7fc0:	lui	a4,0xffe40
    7fc4:	add	a3,a3,a1
    7fc8:	mv	a4,a4
    7fcc:	sw	a3,0(a4) # ffe40000 <__instrn_buffer>
    7fd0:	ttmop	1,0,0
    7fd4:	ttsetrwc	0,0,0,0,0,4
    7fd8:	ttstallwait	2,2064
    7fdc:	ttsempost	2
    7fe0:	li	a3,1
    7fe4:	sub	a3,a3,a5
    7fe8:	sw	a3,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7fec:	ttstallwait	128,2064
    7ff0:	addi	a5,a5,-1
    7ff4:	snez	a5,a5
    7ff8:	slli	a5,a5,0x9
    7ffc:	lui	a3,0xb2010
    8000:	add	a5,a5,a3
    8004:	sw	a5,0(a4)
    8008:	ret
    800c:	li	a4,0
    8010:	addi	a3,a3,8 # b2010008 <__device_print_strings_info_end+0xabb10008>
    8014:	sw	a4,0(a3)
    8018:	lw	a4,0(a3)
    801c:	and	zero,zero,a4
    8020:	lui	a4,0xffb80
    8024:	sw	a2,0(a4) # ffb80000 <__global_pointer$+0x7f810>
    8028:	li	a3,2
    802c:	sw	a3,4(a4)
    8030:	lui	a2,0x2000
    8034:	lui	a3,0x37c00
    8038:	sw	a2,8(a4)
    803c:	addi	a3,a3,3 # 37c00003 <__device_print_strings_info_end+0x31700003>
    8040:	sw	a3,12(a4)
    8044:	sw	a2,16(a4)
    8048:	lui	a3,0x1200a
    804c:	sw	a3,20(a4)
    8050:	sw	a2,24(a4)
    8054:	sw	a3,28(a4)
    8058:	sw	a3,32(a4)
    805c:	j	7f24 <.L78>
00008060 <_Z10move_blockILb1EEvmmm.constprop.1>:
    8060:	ttsetc16	15,0
    8064:	ttsetc16	31,0
    8068:	ttsetc16	50,0
    806c:	ttsetc16	12,1
    8070:	ttsetc16	28,1
    8074:	ttsetc16	47,0
    8078:	ttsetc16	14,8
    807c:	ttsetc16	30,8
    8080:	ttsetc16	49,0
    8084:	lui	a4,0xffe80
    8088:	li	a5,0
    808c:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    8090:	sw	a5,0(a4)
    8094:	lw	a5,0(a4)
    8098:	and	zero,zero,a5
    809c:	lui	a5,0xffb80
    80a0:	li	a4,2
    80a4:	sw	a4,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    80a8:	sw	a4,4(a5)
    80ac:	lui	a3,0x2000
    80b0:	lui	a4,0x37c00
    80b4:	sw	a3,8(a5)
    80b8:	addi	a4,a4,3 # 37c00003 <__device_print_strings_info_end+0x31700003>
    80bc:	sw	a4,12(a5)
    80c0:	sw	a3,16(a5)
    80c4:	lui	a4,0x28008
    80c8:	sw	a4,20(a5)
    80cc:	sw	a3,24(a5)
    80d0:	sw	a4,28(a5)
    80d4:	sw	a4,32(a5)
    80d8:	ttsetc16	7,0
    80dc:	ttsetrwc	0,0,0,0,0,15
    80e0:	ttsemwait	322,2,2
    80e4:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    80e8:	lui	a2,0xb2010
    80ec:	snez	a4,a5
    80f0:	slli	a4,a4,0x9
    80f4:	lui	a3,0xffe40
    80f8:	add	a4,a4,a2
    80fc:	mv	a3,a3
    8100:	sw	a4,0(a3) # ffe40000 <__instrn_buffer>
    8104:	ttmop	1,0,0
    8108:	ttsetrwc	0,0,0,0,0,4
    810c:	ttstallwait	2,2064
    8110:	ttsempost	2
    8114:	li	a4,1
    8118:	sub	a4,a4,a5
    811c:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8120:	ttstallwait	128,2064
    8124:	addi	a5,a5,-1
    8128:	snez	a5,a5
    812c:	slli	a5,a5,0x9
    8130:	add	a5,a5,a2
    8134:	sw	a5,0(a3)
    8138:	ret
0000813c <_ZN7ckernel4sfpu21calculate_exponentialILb1ELb1ELb1ELb0ELi8ELb0ELb0EEEvm>:
    813c:	ttsetc16	19,0
    8140:	ttsetc16	35,2
    8144:	ttsetc16	54,0
    8148:	ttreplay	0,16,0,0
    814c:	sfpnop
    8150:	sfpshft2	L4,L14,0x002,5
    8154:	sfpnop
    8158:	sfpshft2	L4,L14,0x003,5
    815c:	sfpnop
    8160:	sfpnop
    8164:	ret
00008168 <_Z20llk_math_matmul_initILN7ckernel12MathFidelityE2ELi0EEvmmmmm.constprop.1>:
    8168:	ttsetc16	12,2048
    816c:	ttsetc16	28,8
    8170:	ttsetc16	47,0
    8174:	ttsetc16	17,49344
    8178:	ttsetc16	33,11264
    817c:	ttsetc16	52,0
    8180:	beqz	a0,8230 <.L90>
    8184:	ttsetc16	13,16416
    8188:	ttsetc16	29,8
    818c:	ttsetc16	48,0
    8190:	ttsetc16	14,16416
    8194:	ttsetc16	30,8
    8198:	ttsetc16	49,0
    819c:	ttsetc16	16,20560
    81a0:	ttsetc16	32,1024
    81a4:	ttsetc16	51,0
    81a8:	ttreplay	16,8,0,1
    81ac:	ttmvmul	0,0,0,0
    81b0:	ttmvmul	0,0,2,0
    81b4:	ttmvmul	0,0,0,0
    81b8:	ttmvmul	0,0,4,0
    81bc:	ttmvmul	0,0,0,0
    81c0:	ttmvmul	0,0,1,0
    81c4:	ttmvmul	0,0,0,0
    81c8:	ttmvmul	0,0,5,0
    81cc:	lui	a4,0xffe80
    81d0:	li	a5,0
    81d4:	addi	a4,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    81d8:	sw	a5,0(a4)
    81dc:	lw	a5,0(a4)
    81e0:	and	zero,zero,a5
    81e4:	lui	a5,0xffb80
    81e8:	li	a4,1
    81ec:	sw	a4,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    81f0:	li	a4,2
    81f4:	sw	a4,4(a5)
    81f8:	lui	a3,0x2000
    81fc:	lui	a4,0x37400
    8200:	sw	a3,8(a5)
    8204:	addi	a4,a4,15 # 3740000f <__device_print_strings_info_end+0x30f0000f>
    8208:	sw	a4,12(a5)
    820c:	lui	a4,0x4040
    8210:	sw	a3,16(a5)
    8214:	addi	a4,a4,128 # 4040080 <.LASF2788+0x402742f>
    8218:	sw	a4,20(a5)
    821c:	sw	a3,24(a5)
    8220:	sw	a4,28(a5)
    8224:	sw	a4,32(a5)
    8228:	ttsetrwc	0,0,0,0,0,15
    822c:	ret
    8230:	ttsetc16	13,16400
    8234:	ttsetc16	29,8
    8238:	ttsetc16	48,0
    823c:	ttsetc16	14,16400
    8240:	ttsetc16	30,8
    8244:	ttsetc16	49,0
    8248:	ttsetc16	16,20496
    824c:	ttsetc16	32,1024
    8250:	ttsetc16	51,0
    8254:	j	81a8 <.L91>
00008258 <_Z36calculate_fused_max_sub_exp_add_tileILb0EEvi>:
    8258:	slli	a4,a0,0x10
    825c:	srli	a4,a4,0x8
    8260:	lui	a5,0x74000
    8264:	addi	a5,a5,64 # 74000040 <__device_print_strings_info_end+0x6db00040>
    8268:	lui	a2,0x74000
    826c:	addi	a2,a2,16 # 74000010 <__device_print_strings_info_end+0x6db00010>
    8270:	lui	a3,0xffe40
    8274:	add	a2,a4,a2
    8278:	mv	a3,a3
    827c:	add	a4,a4,a5
    8280:	li	a5,4
    8284:	sfpload	L1,0,0,7
    8288:	sfpload	L4,64,0,7
    828c:	sfpload	L2,192,0,7
    8290:	sfpload	L3,256,0,7
    8294:	sfpmad	L0,L4,L11,L1,0
    8298:	sfpnop
    829c:	sfpsetcc	L0,0x000,0
    82a0:	sfpstore	L4,128,0,7
    82a4:	sfpcompc
    82a8:	sfpstore	L1,128,0,7
    82ac:	sfpencc	0x003,10
    82b0:	sfpload	L0,128,0,7
    82b4:	sfpadd	L1,L10,L1,L0,2
    82b8:	sfpadd	L4,L10,L4,L0,2
    82bc:	sw	a2,0(a3) # ffe40000 <__instrn_buffer>
    82c0:	sfpnop
    82c4:	sfpsetsgn	L0,L1,0x000,1
    82c8:	ttreplay	0,25,1,1
    82cc:	sfpexexp	L5,L0,10
    82d0:	sfpsetexp	L0,L0,0x07E,1
    82d4:	sfpencc	0x003,10
    82d8:	sfpmul	L6,L0,L8,L9,0
    82dc:	sfpnop
    82e0:	sfpaddi	L6,16220,0
    82e4:	sfpnop
    82e8:	sfpmad	L0,L0,L6,L10,0
    82ec:	sfpsetcc	L5,0x000,4
    82f0:	sfpmul	L0,L0,L0,L9,0
    82f4:	sfpiadd	L5,L5,0xFFF,9
    82f8:	sfpmul	L0,L0,L0,L9,0
    82fc:	sfpiadd	L5,L5,0xFFF,9
    8300:	sfpmul	L0,L0,L0,L9,0
    8304:	sfpiadd	L5,L5,0xFFF,9
    8308:	sfpmul	L0,L0,L0,L9,0
    830c:	sfpiadd	L5,L5,0xFFF,9
    8310:	sfpmul	L0,L0,L0,L9,0
    8314:	sfpiadd	L5,L5,0xFFF,9
    8318:	sfpmul	L0,L0,L0,L9,0
    831c:	sfpiadd	L5,L5,0xFFF,9
    8320:	sfpmul	L0,L0,L0,L9,0
    8324:	sfpiadd	L5,L5,0xFFF,9
    8328:	sfpmul	L0,L0,L0,L9,0
    832c:	sfpencc	0x003,10
    8330:	sfpsetcc	L1,0x000,0
    8334:	sfparecip	L1,L0,0
    8338:	sfpmad	L5,L0,L1,L12,2
    833c:	sfpnop
    8340:	sfpmad	L6,L1,L5,L9,3
    8344:	ttreplay	25,4,1,1
    8348:	sfppushc	0
    834c:	sfpsetcc	L5,0x000,0
    8350:	sfpmad	L5,L0,L6,L12,1
    8354:	sfpnop
    8358:	sfpmad	L1,L6,L5,L9,2
    835c:	sfpnop
    8360:	sfppopc	0
    8364:	sfpmov	L0,L1,0
    8368:	sfpmov	L1,L0,2
    836c:	sfpencc	0x003,10
    8370:	sw	a4,0(a3)
    8374:	sfpnop
    8378:	sfpsetsgn	L0,L4,0x000,1
    837c:	ttreplay	0,25,0,0
    8380:	sfpsetcc	L4,0x000,0
    8384:	sfparecip	L4,L0,0
    8388:	sfpmad	L5,L0,L4,L12,2
    838c:	sfpnop
    8390:	sfpmad	L6,L4,L5,L9,3
    8394:	ttreplay	25,4,0,0
    8398:	sfpmad	L4,L6,L5,L9,2
    839c:	sfppopc	0
    83a0:	sfpmov	L0,L4,0
    83a4:	sfpencc	0x003,10
    83a8:	sfpstore	L1,0,0,7
    83ac:	sfpstore	L0,64,0,7
    83b0:	sfpmul	L0,L0,L3,L9,0
    83b4:	sfpnop
    83b8:	sfpstore	L0,256,0,7
    83bc:	sfpmul	L0,L1,L2,L9,0
    83c0:	sfpnop
    83c4:	sfpstore	L0,192,0,7
    83c8:	sfpload	L0,256,0,7
    83cc:	sfpload	L1,192,0,7
    83d0:	sfpadd	L0,L10,L0,L1,0
    83d4:	sfpnop
    83d8:	sfpstore	L0,192,0,7
    83dc:	ttincrwc	0,4,0,0
    83e0:	addi	a5,a5,-1
    83e4:	bnez	a5,8284 <.L93>
    83e8:	ret
000083ec <_Z11kernel_mainv>:
    83ec:	lw	a5,-2016(gp) # ffb00010 <rta_l1_base>
    83f0:	addi	sp,sp,-208
    83f4:	lw	a4,28(a5)
    83f8:	sw	s0,200(sp)
    83fc:	sw	s2,192(sp)
    8400:	lw	s0,24(a5)
    8404:	lw	s2,0(a5)
    8408:	sw	s3,188(sp)
    840c:	addi	a1,a5,48
    8410:	lw	s3,16(a5)
    8414:	lw	a5,32(a5)
    8418:	li	a2,24
    841c:	addi	a0,sp,84
    8420:	sw	ra,204(sp)
    8424:	sw	a4,20(sp)
    8428:	sw	a5,28(sp)
    842c:	jal	9f3c <memcpy>
    8430:	li	a5,65
    8434:	bne	s2,a5,843c <.LM2478>
    8438:	j	9714 <.L95>
    843c:	li	a5,-1
    8440:	bne	s0,a5,8448 <.L97>
    8444:	j	972c <.L174>
    8448:	srli	a4,s0,0x6
    844c:	srli	a5,s0,0x5
    8450:	or	a5,a5,a4
    8454:	srli	a4,a5,0x2
    8458:	or	a5,a5,a4
    845c:	sw	s1,196(sp)
    8460:	li	t1,4
    8464:	addi	s1,a5,1
    8468:	minu	t1,s1,t1
    846c:	slli	a5,t1,0x5
    8470:	add	s0,a5,s0
    8474:	remu	a3,s0,a5
    8478:	li	a4,15
    847c:	sub	s0,s0,a3
    8480:	divu	a5,s0,a5
    8484:	bgeu	a4,a5,848c <.LBB8241>
    8488:	j	9740 <.L98>
    848c:	slt	a4,s3,a5
    8490:	li	t5,0
    8494:	bge	s3,a5,849c <.LM2508>
    8498:	j	9e54 <.L175>
    849c:	add	a4,a4,t5
    84a0:	sw	a4,12(sp)
    84a4:	bne	a4,t5,84ac <.L102>
    84a8:	j	9e38 <.L176>
    84ac:	lw	a3,84(sp)
    84b0:	sw	s4,184(sp)
    84b4:	sw	s5,180(sp)
    84b8:	sw	s6,176(sp)
    84bc:	sw	s7,172(sp)
    84c0:	sw	s8,168(sp)
    84c4:	sw	s9,164(sp)
    84c8:	sw	s10,160(sp)
    84cc:	sw	s11,156(sp)
    84d0:	bgeu	a3,a5,84d8 <.LM2518>
    84d4:	j	9f30 <.L177>
    84d8:	li	a3,-1
    84dc:	sw	zero,8(sp)
    84e0:	lw	a4,88(sp)
    84e4:	sw	a3,60(sp)
    84e8:	bgeu	a4,a5,84f0 <.LBB8255+0x8>
    84ec:	j	9f18 <.L178>
    84f0:	lw	a4,8(sp)
    84f4:	sw	a4,16(sp)
    84f8:	li	a4,-1
    84fc:	lw	a3,92(sp)
    8500:	sw	a4,64(sp)
    8504:	bgeu	a3,a5,850c <.LM2534>
    8508:	j	9f00 <.L179>
    850c:	li	a3,-1
    8510:	lw	a4,96(sp)
    8514:	sw	a3,68(sp)
    8518:	bgeu	a4,a5,8520 <.LM2541>
    851c:	j	9ee8 <.L180>
    8520:	li	a4,-1
    8524:	lw	a3,100(sp)
    8528:	sw	a4,72(sp)
    852c:	bgeu	a3,a5,8534 <.LM2548>
    8530:	j	9ed0 <.L181>
    8534:	li	a3,-1
    8538:	lw	a4,104(sp)
    853c:	sw	a3,76(sp)
    8540:	bgeu	a4,a5,8548 <.LM2555>
    8544:	j	9eb8 <.L109>
    8548:	li	a4,-1
    854c:	li	a1,1
    8550:	li	a0,0
    8554:	sw	a4,80(sp)
    8558:	sw	t5,32(sp)
    855c:	sw	t1,24(sp)
    8560:	jal	8168 <_Z20llk_math_matmul_initILN7ckernel12MathFidelityE2ELi0EEvmmmmm.constprop.1>
    8564:	lui	a4,0xffe80
    8568:	li	a5,0
    856c:	addi	a3,a4,4 # ffe80004 <__instrn_buffer+0x40004>
    8570:	sw	a5,0(a3)
    8574:	lw	a5,0(a3)
    8578:	and	zero,zero,a5
    857c:	lw	t1,24(sp)
    8580:	lw	t5,32(sp)
    8584:	lw	a5,36(a4)
    8588:	zext.b	a5,a5
    858c:	bnez	a5,8584 <.L103>
    8590:	ttseminit	2,0,2
    8594:	sw	zero,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8598:	ttsetc16	1,0
    859c:	lui	s0,0xffe40
    85a0:	lui	a5,0xb3080
    85a4:	mv	s0,s0
    85a8:	addi	a5,a5,220 # b30800dc <__device_print_strings_info_end+0xacb800dc>
    85ac:	sw	a5,0(s0) # ffe40000 <__instrn_buffer>
    85b0:	ttstallwait	128,16
    85b4:	lui	a5,0xb6800
    85b8:	addi	a5,a5,1 # b6800001 <__device_print_strings_info_end+0xb0300001>
    85bc:	lui	a4,0xb6202
    85c0:	sw	a5,0(s0)
    85c4:	addi	a4,a4,1 # b6202001 <__device_print_strings_info_end+0xafd02001>
    85c8:	lui	a5,0xb6404
    85cc:	addi	a5,a5,1 # b6404001 <__device_print_strings_info_end+0xaff04001>
    85d0:	sw	a4,0(s0)
    85d4:	sw	a5,0(s0)
    85d8:	lw	a5,12(sp)
    85dc:	bltu	t5,a5,85e4 <.LBB8310>
    85e0:	j	96d0 <.L143>
    85e4:	addi	s2,s2,-1
    85e8:	seqz	a5,s2
    85ec:	sw	a5,32(sp)
    85f0:	lw	a5,12(sp)
    85f4:	lui	t3,0xffe80
    85f8:	lui	t4,0x37400
    85fc:	lui	s11,0x4040
    8600:	lui	s5,0xb2010
    8604:	addi	a5,a5,-1
    8608:	addi	t3,t3,8 # ffe80008 <__instrn_buffer+0x40008>
    860c:	addi	t4,t4,15 # 3740000f <__device_print_strings_info_end+0x30f0000f>
    8610:	addi	s11,s11,128 # 4040080 <.LASF2788+0x402742f>
    8614:	addi	s9,s5,192 # b20100c0 <__device_print_strings_info_end+0xabb100c0>
    8618:	sw	a5,24(sp)
    861c:	addi	s2,t1,-1
    8620:	mv	t6,t5
    8624:	lui	s7,0xffb80
    8628:	li	s3,1
    862c:	li	s4,2
    8630:	lw	a5,24(sp)
    8634:	sub	t2,a5,t6
    8638:	lw	a5,32(sp)
    863c:	seqz	t2,t2
    8640:	and	t2,a5,t2
    8644:	ttsetc16	12,2048
    8648:	ttsetc16	28,8
    864c:	ttsetc16	47,0
    8650:	ttsetc16	17,49344
    8654:	ttsetc16	33,11264
    8658:	ttsetc16	52,0
    865c:	ttsetc16	13,16416
    8660:	ttsetc16	29,8
    8664:	ttsetc16	48,0
    8668:	ttsetc16	14,16416
    866c:	ttsetc16	30,8
    8670:	ttsetc16	49,0
    8674:	ttsetc16	16,20560
    8678:	ttsetc16	32,1024
    867c:	ttsetc16	51,0
    8680:	ttreplay	16,8,0,1
    8684:	ttmvmul	0,0,0,0
    8688:	ttmvmul	0,0,2,0
    868c:	ttmvmul	0,0,0,0
    8690:	ttmvmul	0,0,4,0
    8694:	ttmvmul	0,0,0,0
    8698:	ttmvmul	0,0,1,0
    869c:	ttmvmul	0,0,0,0
    86a0:	ttmvmul	0,0,5,0
    86a4:	li	a5,0
    86a8:	sw	a5,0(t3)
    86ac:	lw	a5,0(t3)
    86b0:	and	zero,zero,a5
    86b4:	sw	s3,0(s7) # ffb80000 <__global_pointer$+0x7f810>
    86b8:	sw	s4,4(s7)
    86bc:	lui	a7,0x2000
    86c0:	sw	a7,8(s7)
    86c4:	sw	t4,12(s7)
    86c8:	sw	a7,16(s7)
    86cc:	sw	s11,20(s7)
    86d0:	sw	a7,24(s7)
    86d4:	sw	s11,28(s7)
    86d8:	sw	s11,32(s7)
    86dc:	ttsetrwc	0,0,0,0,0,15
    86e0:	sw	zero,-1488(gp) # ffb00220 <_ZN7ckernelL20throttled_mop_statusE>
    86e4:	ttsemwait	322,2,2
    86e8:	lw	a4,16(zero) # 10 <.LLST0+0x2>
    86ec:	li	s8,4
    86f0:	addi	a6,s5,128
    86f4:	addi	a1,s5,64
    86f8:	li	a5,0
    86fc:	li	a0,3
    8700:	lui	t0,0x26008
    8704:	andi	a4,a4,1
    8708:	sw	a4,56(sp)
    870c:	lw	a2,56(sp)
    8710:	beqz	a2,8840 <.L114>
    8714:	beq	a5,s3,87a0 <.L115>
    8718:	ttsetc16	12,2048
    871c:	ttsetc16	28,8
    8720:	ttsetc16	47,0
    8724:	ttsetc16	17,49344
    8728:	ttsetc16	33,11264
    872c:	ttsetc16	52,0
    8730:	ttsetc16	18,49344
    8734:	ttsetc16	34,35840
    8738:	ttsetc16	53,0
    873c:	ttsetc16	13,16416
    8740:	ttsetc16	29,8
    8744:	ttsetc16	48,0
    8748:	ttsetc16	14,16416
    874c:	ttsetc16	30,8
    8750:	ttsetc16	49,0
    8754:	ttsetc16	16,20560
    8758:	ttsetc16	32,1024
    875c:	ttsetc16	51,0
    8760:	ttreplay	16,8,0,1
    8764:	li	a5,0
    8768:	sw	a5,0(t3)
    876c:	lw	a5,0(t3)
    8770:	and	zero,zero,a5
    8774:	sw	s4,0(s7)
    8778:	sw	s4,4(s7)
    877c:	sw	a7,8(s7)
    8780:	sw	a7,12(s7)
    8784:	sw	a7,16(s7)
    8788:	sw	s11,20(s7)
    878c:	sw	t0,24(s7)
    8790:	sw	t0,28(s7)
    8794:	sw	t0,32(s7)
    8798:	ttsetrwc	0,0,0,0,0,15
    879c:	sw	s3,-1488(gp) # ffb00220 <_ZN7ckernelL20throttled_mop_statusE>
    87a0:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    87a4:	snez	a5,a4
    87a8:	slli	a5,a5,0x9
    87ac:	add	a3,a5,s5
    87b0:	sw	a3,0(s0)
    87b4:	ttmop	1,0,0
    87b8:	ttmop	1,0,0
    87bc:	ttsetrwc	1,0,0,0,0,15
    87c0:	bnez	s2,87c8 <.LM2862>
    87c4:	j	97a4 <.L182>
    87c8:	beq	s1,s3,881c <.L116>
    87cc:	add	a3,a5,a1
    87d0:	sw	a3,0(s0)
    87d4:	ttmop	1,0,0
    87d8:	ttmop	1,0,0
    87dc:	ttsetrwc	1,0,0,0,0,15
    87e0:	beq	s2,s3,977c <.L183>
    87e4:	bgeu	s4,s1,881c <.L116>
    87e8:	add	a3,a5,a6
    87ec:	sw	a3,0(s0)
    87f0:	ttmop	1,0,0
    87f4:	ttmop	1,0,0
    87f8:	ttsetrwc	1,0,0,0,0,15
    87fc:	beq	s2,s4,979c <.L184>
    8800:	bgeu	a0,s1,881c <.L116>
    8804:	add	a5,a5,s9
    8808:	sw	a5,0(s0)
    880c:	ttmop	1,0,0
    8810:	ttmop	1,0,0
    8814:	ttsetrwc	1,0,0,0,0,15
    8818:	ttsetrwc	2,0,0,0,0,15
    881c:	li	a2,1
    8820:	addi	s8,s8,-1
    8824:	beqz	s8,88a4 <.L185>
    8828:	lw	a4,16(zero) # 10 <.LLST0+0x2>
    882c:	mv	a5,a2
    8830:	andi	a4,a4,1
    8834:	sw	a4,56(sp)
    8838:	lw	a2,56(sp)
    883c:	bnez	a2,8714 <.L186>
    8840:	bnez	a5,980c <.L187>
    8844:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8848:	snez	a5,a4
    884c:	slli	a5,a5,0x9
    8850:	add	a3,a5,s5
    8854:	sw	a3,0(s0)
    8858:	ttmop	1,0,0
    885c:	beqz	s2,97f4 <.L188>
    8860:	beq	s1,s3,8820 <.L122>
    8864:	add	a3,a5,a1
    8868:	sw	a3,0(s0)
    886c:	ttmop	1,0,0
    8870:	beq	s2,s3,97c4 <.L189>
    8874:	bgeu	s4,s1,8820 <.L122>
    8878:	add	a3,a5,a6
    887c:	sw	a3,0(s0)
    8880:	ttmop	1,0,0
    8884:	beq	s2,s4,97dc <.L190>
    8888:	bgeu	a0,s1,8820 <.L122>
    888c:	add	a5,a5,s9
    8890:	sw	a5,0(s0)
    8894:	ttmop	1,0,0
    8898:	ttsetrwc	2,0,0,0,0,15
    889c:	addi	s8,s8,-1
    88a0:	bnez	s8,8828 <.L155>
    88a4:	beqz	t2,88ac <.L129>
    88a8:	j	9948 <.L191>
    88ac:	ttstallwait	2,2064
    88b0:	ttsempost	2
    88b4:	sub	a5,s3,a4
    88b8:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    88bc:	ttstallwait	128,2064
    88c0:	addi	a5,a4,-1
    88c4:	snez	a5,a5
    88c8:	slli	a5,a5,0x9
    88cc:	add	a5,a5,s5
    88d0:	sw	a5,0(s0)
    88d4:	sfpconfig	15,0,1
    88d8:	ttsetc16	19,0
    88dc:	ttsetc16	35,0
    88e0:	ttsetc16	54,0
    88e4:	ttsetc16	18,0
    88e8:	ttsetc16	34,2
    88ec:	ttsetc16	53,0
    88f0:	ttsetrwc	0,0,0,0,0,15
    88f4:	sfpswap	L12,L2,9
    88f8:	sfpshft2	L13,L0,0x000,6
    88fc:	sfploadi	L0,140,10
    8900:	sfploadi	L0,221,8
    8904:	sfpconfig	4,0,0
    8908:	sfploadi	L0,0,10
    890c:	sfploadi	L0,21248,8
    8910:	sfpconfig	5,0,0
    8914:	sfpconfig	8,816,1
    8918:	ttsemwait	322,2,2
    891c:	ttsetc16	12,0
    8920:	ttsetc16	28,32768
    8924:	ttsetc16	47,0
    8928:	ttsetc16	13,256
    892c:	ttsetc16	29,1
    8930:	ttsetc16	48,0
    8934:	ttsetc16	14,2048
    8938:	ttsetc16	30,8
    893c:	ttsetc16	49,0
    8940:	ttsetc16	15,0
    8944:	ttsetc16	31,8192
    8948:	ttsetc16	50,0
    894c:	li	a5,0
    8950:	sw	a5,0(t3)
    8954:	lw	a5,0(t3)
    8958:	and	zero,zero,a5
    895c:	sw	s3,0(s7)
    8960:	sw	s4,4(s7)
    8964:	lui	a5,0x2000
    8968:	sw	a5,8(s7)
    896c:	sw	a5,12(s7)
    8970:	sw	a5,16(s7)
    8974:	lui	a4,0x34098
    8978:	sw	a4,20(s7)
    897c:	sw	a5,24(s7)
    8980:	lui	a5,0x34080
    8984:	sw	a5,28(s7)
    8988:	sw	a5,32(s7)
    898c:	ttsetc16	7,0
    8990:	ttsetrwc	0,0,0,0,0,15
    8994:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8998:	snez	a4,a5
    899c:	slli	a4,a4,0x9
    89a0:	add	a4,a4,s5
    89a4:	sw	a4,0(s0)
    89a8:	ttgmpool	3,1,0,0,0
    89ac:	ttgmpool	0,1,0,0,0
    89b0:	ttsetrwc	0,4,0,0,0,3
    89b4:	ttmovd2b	0,16,0,0,0
    89b8:	tttrnspsrcb
    89bc:	ttmovd2b	0,16,0,0,0
    89c0:	ttsetrwc	0,2,0,8,0,2
    89c4:	ttsetrwc	0,2,0,8,0,2
    89c8:	ttzerosrc	0,1,0,1
    89cc:	ttelwadd	0,0,0,2,0
    89d0:	ttelwadd	0,0,0,2,0
    89d4:	ttsetrwc	3,0,0,0,0,6
    89d8:	beq	s1,s3,8a84 <.L131>
    89dc:	sw	a4,0(s0)
    89e0:	ttgmpool	3,1,0,0,0
    89e4:	ttgmpool	0,1,0,0,0
    89e8:	ttsetrwc	0,4,0,0,0,3
    89ec:	ttmovd2b	0,16,0,0,0
    89f0:	tttrnspsrcb
    89f4:	ttmovd2b	0,16,0,0,0
    89f8:	ttsetrwc	0,2,0,8,0,2
    89fc:	ttsetrwc	0,2,0,8,0,2
    8a00:	ttzerosrc	0,1,0,1
    8a04:	ttelwadd	0,0,0,2,0
    8a08:	ttelwadd	0,0,0,2,0
    8a0c:	ttsetrwc	3,0,0,0,0,6
    8a10:	bgeu	s4,s1,8a84 <.L131>
    8a14:	sw	a4,0(s0)
    8a18:	ttgmpool	3,1,0,0,0
    8a1c:	ttgmpool	0,1,0,0,0
    8a20:	ttsetrwc	0,4,0,0,0,3
    8a24:	ttmovd2b	0,16,0,0,0
    8a28:	tttrnspsrcb
    8a2c:	ttmovd2b	0,16,0,0,0
    8a30:	ttsetrwc	0,2,0,8,0,2
    8a34:	ttsetrwc	0,2,0,8,0,2
    8a38:	ttzerosrc	0,1,0,1
    8a3c:	ttelwadd	0,0,0,2,0
    8a40:	ttelwadd	0,0,0,2,0
    8a44:	ttsetrwc	3,0,0,0,0,6
    8a48:	li	a3,3
    8a4c:	bgeu	a3,s1,8a84 <.L131>
    8a50:	sw	a4,0(s0)
    8a54:	ttgmpool	3,1,0,0,0
    8a58:	ttgmpool	0,1,0,0,0
    8a5c:	ttsetrwc	0,4,0,0,0,3
    8a60:	ttmovd2b	0,16,0,0,0
    8a64:	tttrnspsrcb
    8a68:	ttmovd2b	0,16,0,0,0
    8a6c:	ttsetrwc	0,2,0,8,0,2
    8a70:	ttsetrwc	0,2,0,8,0,2
    8a74:	ttzerosrc	0,1,0,1
    8a78:	ttelwadd	0,0,0,2,0
    8a7c:	ttelwadd	0,0,0,2,0
    8a80:	ttsetrwc	3,0,0,0,0,6
    8a84:	bltu	t5,t6,9a38 <.L192>
    8a88:	ttstallwait	2,2064
    8a8c:	ttsempost	2
    8a90:	sub	a4,s3,a5
    8a94:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8a98:	ttstallwait	128,2064
    8a9c:	addi	a5,a5,-1 # 3407ffff <__device_print_strings_info_end+0x2db7ffff>
    8aa0:	snez	a5,a5
    8aa4:	slli	a5,a5,0x9
    8aa8:	add	a5,a5,s5
    8aac:	sw	a5,0(s0)
    8ab0:	ttsetc16	12,2056
    8ab4:	ttsetc16	28,8
    8ab8:	ttsetc16	47,0
    8abc:	ttsetc16	13,0
    8ac0:	ttsetc16	29,0
    8ac4:	ttsetc16	48,0
    8ac8:	ttsetc16	14,32896
    8acc:	ttsetc16	30,1024
    8ad0:	ttsetc16	49,0
    8ad4:	ttsetc16	15,32896
    8ad8:	ttsetc16	31,36872
    8adc:	ttsetc16	50,0
    8ae0:	li	a5,0
    8ae4:	sw	a5,0(t3)
    8ae8:	lw	a5,0(t3)
    8aec:	and	zero,zero,a5
    8af0:	sw	s4,0(s7)
    8af4:	sw	s4,4(s7)
    8af8:	lui	a4,0x2000
    8afc:	lui	a5,0x374c0
    8b00:	sw	a4,8(s7)
    8b04:	addi	a5,a5,3 # 374c0003 <__device_print_strings_info_end+0x30fc0003>
    8b08:	sw	a5,12(s7)
    8b0c:	sw	a4,16(s7)
    8b10:	lui	a5,0x30080
    8b14:	sw	a5,20(s7)
    8b18:	sw	a4,24(s7)
    8b1c:	sw	a5,28(s7)
    8b20:	sw	a5,32(s7)
    8b24:	ttsetc16	7,0
    8b28:	ttsetrwc	0,0,0,0,0,15
    8b2c:	sfpconfig	15,0,1
    8b30:	ttsetc16	19,0
    8b34:	ttsetc16	35,0
    8b38:	ttsetc16	54,0
    8b3c:	ttsetrwc	0,0,0,0,0,15
    8b40:	sfploadi	L0,-27666,10
    8b44:	sfploadi	L0,16898,8
    8b48:	sfpconfig	12,0,0
    8b4c:	sfploadi	L0,-5725,10
    8b50:	sfploadi	L0,18173,8
    8b54:	sfpconfig	13,0,0
    8b58:	sfploadi	L0,15,10
    8b5c:	sfploadi	L0,0,8
    8b60:	sfpconfig	14,0,0
    8b64:	sfpmad	L13,L12,L0,L13,0
    8b68:	sfpstochrnd	L14,L0,L0,0,7,0
    8b6c:	sfpsetsgn	L15,L4,0x000,0
    8b70:	sfploadi	L0,-31249,10
    8b74:	sfploadi	L0,29470,8
    8b78:	sfpconfig	4,0,0
    8b7c:	sfpconfig	8,3840,1
    8b80:	ttreplay	0,32,0,1
    8b84:	sfploadmacro	0,L0,0,0,7
    8b88:	sfpshft2	L4,L14,0x002,5
    8b8c:	sfploadmacro	0,L1,0,0,7
    8b90:	sfpshft2	L4,L14,0x003,5
    8b94:	sfploadmacro	0,L2,0,0,7
    8b98:	sfpshft2	L4,L14,0x000,5
    8b9c:	sfploadmacro	0,L3,0,0,7
    8ba0:	sfpshft2	L4,L14,0x001,5
    8ba4:	sfploadmacro	0,L0,0,0,7
    8ba8:	sfpshft2	L4,L14,0x002,5
    8bac:	sfploadmacro	0,L1,0,0,7
    8bb0:	sfpshft2	L4,L14,0x003,5
    8bb4:	sfploadmacro	0,L2,0,0,7
    8bb8:	sfpshft2	L4,L14,0x000,5
    8bbc:	sfploadmacro	0,L3,0,0,7
    8bc0:	sfpshft2	L4,L14,0x001,5
    8bc4:	sfploadmacro	0,L0,0,0,7
    8bc8:	sfpshft2	L4,L14,0x002,5
    8bcc:	sfploadmacro	0,L1,0,0,7
    8bd0:	sfpshft2	L4,L14,0x003,5
    8bd4:	sfploadmacro	0,L2,0,0,7
    8bd8:	sfpshft2	L4,L14,0x000,5
    8bdc:	sfploadmacro	0,L3,0,0,7
    8be0:	sfpshft2	L4,L14,0x001,5
    8be4:	sfploadmacro	0,L0,0,0,7
    8be8:	sfpshft2	L4,L14,0x002,5
    8bec:	sfploadmacro	0,L1,0,0,7
    8bf0:	sfpshft2	L4,L14,0x003,5
    8bf4:	sfploadmacro	0,L2,0,0,7
    8bf8:	sfpshft2	L4,L14,0x000,5
    8bfc:	sfploadmacro	0,L3,0,0,7
    8c00:	sfpshft2	L4,L14,0x001,5
    8c04:	sfpnop
    8c08:	ttsemwait	322,2,2
    8c0c:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8c10:	snez	a5,a5
    8c14:	slli	a5,a5,0x9
    8c18:	add	a4,a5,s5
    8c1c:	sw	a4,0(s0)
    8c20:	ttmop	1,0,0
    8c24:	ttsetrwc	2,0,0,0,0,0
    8c28:	ttsetrwc	0,0,0,0,0,4
    8c2c:	sw	a4,0(s0)
    8c30:	ttstallwait	256,16
    8c34:	ttsetc16	19,0
    8c38:	ttsetc16	35,2
    8c3c:	ttsetc16	54,0
    8c40:	ttreplay	0,16,0,0
    8c44:	sfpnop
    8c48:	sfpshft2	L4,L14,0x002,5
    8c4c:	sfpnop
    8c50:	sfpshft2	L4,L14,0x003,5
    8c54:	sfpnop
    8c58:	sfpnop
    8c5c:	ttsetrwc	0,4,8,0,0,4
    8c60:	ttsetrwc	0,4,8,0,0,4
    8c64:	ttsetc16	19,0
    8c68:	ttsetc16	35,2
    8c6c:	ttsetc16	54,0
    8c70:	ttreplay	0,16,0,0
    8c74:	sfpnop
    8c78:	sfpshft2	L4,L14,0x002,5
    8c7c:	sfpnop
    8c80:	sfpshft2	L4,L14,0x003,5
    8c84:	sfpnop
    8c88:	sfpnop
    8c8c:	ttsetrwc	0,4,8,0,0,4
    8c90:	ttsetrwc	0,4,8,0,0,4
    8c94:	ttsetrwc	0,4,8,0,0,4
    8c98:	ttsetrwc	0,4,8,0,0,4
    8c9c:	ttsetrwc	0,4,8,0,0,4
    8ca0:	ttsetrwc	0,4,8,0,0,4
    8ca4:	ttsetrwc	0,0,0,0,0,4
    8ca8:	beq	s1,s3,8e70 <.L133>
    8cac:	addi	a4,s5,64
    8cb0:	add	a4,a5,a4
    8cb4:	sw	a4,0(s0)
    8cb8:	ttmop	1,0,0
    8cbc:	ttsetrwc	2,0,0,0,0,0
    8cc0:	ttsetrwc	0,0,0,0,0,4
    8cc4:	sw	a4,0(s0)
    8cc8:	ttstallwait	256,16
    8ccc:	ttsetc16	19,0
    8cd0:	ttsetc16	35,2
    8cd4:	ttsetc16	54,0
    8cd8:	ttreplay	0,16,0,0
    8cdc:	sfpnop
    8ce0:	sfpshft2	L4,L14,0x002,5
    8ce4:	sfpnop
    8ce8:	sfpshft2	L4,L14,0x003,5
    8cec:	sfpnop
    8cf0:	sfpnop
    8cf4:	ttsetrwc	0,4,8,0,0,4
    8cf8:	ttsetrwc	0,4,8,0,0,4
    8cfc:	ttsetc16	19,0
    8d00:	ttsetc16	35,2
    8d04:	ttsetc16	54,0
    8d08:	ttreplay	0,16,0,0
    8d0c:	sfpnop
    8d10:	sfpshft2	L4,L14,0x002,5
    8d14:	sfpnop
    8d18:	sfpshft2	L4,L14,0x003,5
    8d1c:	sfpnop
    8d20:	sfpnop
    8d24:	ttsetrwc	0,4,8,0,0,4
    8d28:	ttsetrwc	0,4,8,0,0,4
    8d2c:	ttsetrwc	0,4,8,0,0,4
    8d30:	ttsetrwc	0,4,8,0,0,4
    8d34:	ttsetrwc	0,4,8,0,0,4
    8d38:	ttsetrwc	0,4,8,0,0,4
    8d3c:	ttsetrwc	0,0,0,0,0,4
    8d40:	bgeu	s4,s1,8e70 <.L133>
    8d44:	addi	a4,s5,128
    8d48:	add	a4,a5,a4
    8d4c:	sw	a4,0(s0)
    8d50:	ttmop	1,0,0
    8d54:	ttsetrwc	2,0,0,0,0,0
    8d58:	ttsetrwc	0,0,0,0,0,4
    8d5c:	sw	a4,0(s0)
    8d60:	ttstallwait	256,16
    8d64:	ttsetc16	19,0
    8d68:	ttsetc16	35,2
    8d6c:	ttsetc16	54,0
    8d70:	ttreplay	0,16,0,0
    8d74:	sfpnop
    8d78:	sfpshft2	L4,L14,0x002,5
    8d7c:	sfpnop
    8d80:	sfpshft2	L4,L14,0x003,5
    8d84:	sfpnop
    8d88:	sfpnop
    8d8c:	ttsetrwc	0,4,8,0,0,4
    8d90:	ttsetrwc	0,4,8,0,0,4
    8d94:	ttsetc16	19,0
    8d98:	ttsetc16	35,2
    8d9c:	ttsetc16	54,0
    8da0:	ttreplay	0,16,0,0
    8da4:	sfpnop
    8da8:	sfpshft2	L4,L14,0x002,5
    8dac:	sfpnop
    8db0:	sfpshft2	L4,L14,0x003,5
    8db4:	sfpnop
    8db8:	sfpnop
    8dbc:	ttsetrwc	0,4,8,0,0,4
    8dc0:	ttsetrwc	0,4,8,0,0,4
    8dc4:	ttsetrwc	0,4,8,0,0,4
    8dc8:	ttsetrwc	0,4,8,0,0,4
    8dcc:	ttsetrwc	0,4,8,0,0,4
    8dd0:	ttsetrwc	0,4,8,0,0,4
    8dd4:	ttsetrwc	0,0,0,0,0,4
    8dd8:	li	a4,3
    8ddc:	bgeu	a4,s1,8e70 <.L133>
    8de0:	add	a5,a5,s9
    8de4:	sw	a5,0(s0)
    8de8:	ttmop	1,0,0
    8dec:	ttsetrwc	2,0,0,0,0,0
    8df0:	ttsetrwc	0,0,0,0,0,4
    8df4:	sw	a5,0(s0)
    8df8:	ttstallwait	256,16
    8dfc:	ttsetc16	19,0
    8e00:	ttsetc16	35,2
    8e04:	ttsetc16	54,0
    8e08:	ttreplay	0,16,0,0
    8e0c:	sfpnop
    8e10:	sfpshft2	L4,L14,0x002,5
    8e14:	sfpnop
    8e18:	sfpshft2	L4,L14,0x003,5
    8e1c:	sfpnop
    8e20:	sfpnop
    8e24:	ttsetrwc	0,4,8,0,0,4
    8e28:	ttsetrwc	0,4,8,0,0,4
    8e2c:	ttsetc16	19,0
    8e30:	ttsetc16	35,2
    8e34:	ttsetc16	54,0
    8e38:	ttreplay	0,16,0,0
    8e3c:	sfpnop
    8e40:	sfpshft2	L4,L14,0x002,5
    8e44:	sfpnop
    8e48:	sfpshft2	L4,L14,0x003,5
    8e4c:	sfpnop
    8e50:	sfpnop
    8e54:	ttsetrwc	0,4,8,0,0,4
    8e58:	ttsetrwc	0,4,8,0,0,4
    8e5c:	ttsetrwc	0,4,8,0,0,4
    8e60:	ttsetrwc	0,4,8,0,0,4
    8e64:	ttsetrwc	0,4,8,0,0,4
    8e68:	ttsetrwc	0,4,8,0,0,4
    8e6c:	ttsetrwc	0,0,0,0,0,4
    8e70:	ttstallwait	2,2064
    8e74:	ttsempost	2
    8e78:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8e7c:	sub	a4,s3,a5
    8e80:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8e84:	ttstallwait	128,2064
    8e88:	addi	a5,a5,-1 # 3007ffff <__device_print_strings_info_end+0x29b7ffff>
    8e8c:	snez	a5,a5
    8e90:	slli	a5,a5,0x9
    8e94:	add	a5,a5,s5
    8e98:	sw	a5,0(s0)
    8e9c:	sfpconfig	15,0,1
    8ea0:	ttsetc16	19,0
    8ea4:	ttsetc16	35,0
    8ea8:	ttsetc16	54,0
    8eac:	ttsetc16	18,0
    8eb0:	ttsetc16	34,2
    8eb4:	ttsetc16	53,0
    8eb8:	ttsetrwc	0,0,0,0,0,15
    8ebc:	sfpswap	L12,L2,9
    8ec0:	sfpshft2	L13,L0,0x000,6
    8ec4:	sfploadi	L0,140,10
    8ec8:	sfploadi	L0,221,8
    8ecc:	sfpconfig	4,0,0
    8ed0:	sfploadi	L0,0,10
    8ed4:	sfploadi	L0,21248,8
    8ed8:	sfpconfig	5,0,0
    8edc:	sfpconfig	8,816,1
    8ee0:	ttsemwait	322,2,2
    8ee4:	ttsetc16	12,0
    8ee8:	ttsetc16	28,32768
    8eec:	ttsetc16	47,0
    8ef0:	ttsetc16	13,256
    8ef4:	ttsetc16	29,1
    8ef8:	ttsetc16	48,0
    8efc:	ttsetc16	14,2048
    8f00:	ttsetc16	30,8
    8f04:	ttsetc16	49,0
    8f08:	ttsetc16	15,0
    8f0c:	ttsetc16	31,8192
    8f10:	ttsetc16	50,0
    8f14:	li	a5,0
    8f18:	sw	a5,0(t3)
    8f1c:	lw	a5,0(t3)
    8f20:	and	zero,zero,a5
    8f24:	sw	s3,0(s7)
    8f28:	sw	s4,4(s7)
    8f2c:	lui	a5,0x2000
    8f30:	sw	a5,8(s7)
    8f34:	sw	a5,12(s7)
    8f38:	sw	a5,16(s7)
    8f3c:	lui	a4,0x34098
    8f40:	sw	a4,20(s7)
    8f44:	sw	a5,24(s7)
    8f48:	lui	a5,0x34080
    8f4c:	sw	a5,28(s7)
    8f50:	sw	a5,32(s7)
    8f54:	ttsetc16	7,0
    8f58:	ttsetrwc	0,0,0,0,0,15
    8f5c:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8f60:	snez	a4,a5
    8f64:	slli	a4,a4,0x9
    8f68:	add	a4,a4,s5
    8f6c:	sw	a4,0(s0)
    8f70:	ttmop	1,0,0
    8f74:	ttcleardvalid	3,0
    8f78:	ttmop	1,0,0
    8f7c:	ttsetrwc	0,4,0,0,0,3
    8f80:	ttmovd2b	0,16,0,0,0
    8f84:	tttrnspsrcb
    8f88:	ttmovd2b	0,16,0,0,0
    8f8c:	ttsetrwc	0,2,0,8,0,2
    8f90:	ttsetrwc	0,2,0,8,0,2
    8f94:	ttzerosrc	0,1,0,1
    8f98:	ttelwadd	0,0,0,2,0
    8f9c:	ttelwadd	0,0,0,2,0
    8fa0:	ttsetrwc	3,0,0,0,0,6
    8fa4:	beq	s1,s3,905c <.L134>
    8fa8:	sw	a4,0(s0)
    8fac:	ttmop	1,0,0
    8fb0:	ttcleardvalid	3,0
    8fb4:	ttmop	1,0,0
    8fb8:	ttsetrwc	0,4,0,0,0,3
    8fbc:	ttmovd2b	0,16,0,0,0
    8fc0:	tttrnspsrcb
    8fc4:	ttmovd2b	0,16,0,0,0
    8fc8:	ttsetrwc	0,2,0,8,0,2
    8fcc:	ttsetrwc	0,2,0,8,0,2
    8fd0:	ttzerosrc	0,1,0,1
    8fd4:	ttelwadd	0,0,0,2,0
    8fd8:	ttelwadd	0,0,0,2,0
    8fdc:	ttsetrwc	3,0,0,0,0,6
    8fe0:	bgeu	s4,s1,905c <.L134>
    8fe4:	sw	a4,0(s0)
    8fe8:	ttmop	1,0,0
    8fec:	ttcleardvalid	3,0
    8ff0:	ttmop	1,0,0
    8ff4:	ttsetrwc	0,4,0,0,0,3
    8ff8:	ttmovd2b	0,16,0,0,0
    8ffc:	tttrnspsrcb
    9000:	ttmovd2b	0,16,0,0,0
    9004:	ttsetrwc	0,2,0,8,0,2
    9008:	ttsetrwc	0,2,0,8,0,2
    900c:	ttzerosrc	0,1,0,1
    9010:	ttelwadd	0,0,0,2,0
    9014:	ttelwadd	0,0,0,2,0
    9018:	ttsetrwc	3,0,0,0,0,6
    901c:	li	a3,3
    9020:	bgeu	a3,s1,905c <.L134>
    9024:	sw	a4,0(s0)
    9028:	ttmop	1,0,0
    902c:	ttcleardvalid	3,0
    9030:	ttmop	1,0,0
    9034:	ttsetrwc	0,4,0,0,0,3
    9038:	ttmovd2b	0,16,0,0,0
    903c:	tttrnspsrcb
    9040:	ttmovd2b	0,16,0,0,0
    9044:	ttsetrwc	0,2,0,8,0,2
    9048:	ttsetrwc	0,2,0,8,0,2
    904c:	ttzerosrc	0,1,0,1
    9050:	ttelwadd	0,0,0,2,0
    9054:	ttelwadd	0,0,0,2,0
    9058:	ttsetrwc	3,0,0,0,0,6
    905c:	ttstallwait	2,2064
    9060:	ttsempost	2
    9064:	sub	a4,s3,a5
    9068:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    906c:	ttstallwait	128,2064
    9070:	addi	a5,a5,-1 # 3407ffff <__device_print_strings_info_end+0x2db7ffff>
    9074:	snez	a5,a5
    9078:	slli	a5,a5,0x9
    907c:	add	a5,a5,s5
    9080:	sw	a5,0(s0)
    9084:	ttsetc16	12,2048
    9088:	ttsetc16	28,8
    908c:	ttsetc16	47,0
    9090:	ttsetc16	17,49344
    9094:	ttsetc16	33,11264
    9098:	ttsetc16	52,0
    909c:	ttsetc16	13,16400
    90a0:	ttsetc16	29,8
    90a4:	ttsetc16	48,0
    90a8:	ttsetc16	14,16400
    90ac:	ttsetc16	30,8
    90b0:	ttsetc16	49,0
    90b4:	ttsetc16	16,20496
    90b8:	ttsetc16	32,1024
    90bc:	ttsetc16	51,0
    90c0:	ttreplay	16,8,0,1
    90c4:	ttmvmul	0,0,0,0
    90c8:	ttmvmul	0,0,2,0
    90cc:	ttmvmul	0,0,0,0
    90d0:	ttmvmul	0,0,4,0
    90d4:	ttmvmul	0,0,0,0
    90d8:	ttmvmul	0,0,1,0
    90dc:	ttmvmul	0,0,0,0
    90e0:	ttmvmul	0,0,5,0
    90e4:	li	a5,0
    90e8:	sw	a5,0(t3)
    90ec:	lw	a5,0(t3)
    90f0:	and	zero,zero,a5
    90f4:	sw	s3,0(s7)
    90f8:	sw	s4,4(s7)
    90fc:	lui	a3,0x2000
    9100:	sw	a3,8(s7)
    9104:	sw	t4,12(s7)
    9108:	sw	a3,16(s7)
    910c:	sw	s11,20(s7)
    9110:	sw	a3,24(s7)
    9114:	sw	s11,28(s7)
    9118:	sw	s11,32(s7)
    911c:	ttsetrwc	0,0,0,0,0,15
    9120:	sw	zero,-1488(gp) # ffb00220 <_ZN7ckernelL20throttled_mop_statusE>
    9124:	ttsemwait	322,2,2
    9128:	li	a4,0
    912c:	addi	a1,s5,64
    9130:	addi	a2,s5,128
    9134:	lui	a0,0x26008
    9138:	j	9234 <.L140>
    913c:	beq	a4,s3,91c8 <.L136>
    9140:	ttsetc16	12,2048
    9144:	ttsetc16	28,8
    9148:	ttsetc16	47,0
    914c:	ttsetc16	17,49344
    9150:	ttsetc16	33,11264
    9154:	ttsetc16	52,0
    9158:	ttsetc16	18,49344
    915c:	ttsetc16	34,35840
    9160:	ttsetc16	53,0
    9164:	ttsetc16	13,16400
    9168:	ttsetc16	29,8
    916c:	ttsetc16	48,0
    9170:	ttsetc16	14,16400
    9174:	ttsetc16	30,8
    9178:	ttsetc16	49,0
    917c:	ttsetc16	16,20496
    9180:	ttsetc16	32,1024
    9184:	ttsetc16	51,0
    9188:	ttreplay	16,8,0,1
    918c:	li	a5,0
    9190:	sw	a5,0(t3)
    9194:	lw	a5,0(t3)
    9198:	and	zero,zero,a5
    919c:	sw	s4,0(s7)
    91a0:	sw	s4,4(s7)
    91a4:	sw	a3,8(s7)
    91a8:	sw	a3,12(s7)
    91ac:	sw	a3,16(s7)
    91b0:	sw	s11,20(s7)
    91b4:	sw	a0,24(s7)
    91b8:	sw	a0,28(s7)
    91bc:	sw	a0,32(s7)
    91c0:	ttsetrwc	0,0,0,0,0,15
    91c4:	sw	s3,-1488(gp) # ffb00220 <_ZN7ckernelL20throttled_mop_statusE>
    91c8:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    91cc:	snez	a5,a4
    91d0:	slli	a5,a5,0x9
    91d4:	add	a6,a5,s5
    91d8:	sw	a6,0(s0)
    91dc:	ttmop	1,0,0
    91e0:	ttmop	1,0,0
    91e4:	ttsetrwc	1,0,0,0,0,15
    91e8:	add	a6,a5,a1
    91ec:	sw	a6,0(s0)
    91f0:	ttmop	1,0,0
    91f4:	ttmop	1,0,0
    91f8:	ttsetrwc	1,0,0,0,0,15
    91fc:	add	a6,a5,a2
    9200:	sw	a6,0(s0)
    9204:	ttmop	1,0,0
    9208:	ttmop	1,0,0
    920c:	ttsetrwc	1,0,0,0,0,15
    9210:	add	a5,a5,s9
    9214:	sw	a5,0(s0)
    9218:	ttmop	1,0,0
    921c:	ttmop	1,0,0
    9220:	ttsetrwc	1,0,0,0,0,15
    9224:	ttsetrwc	2,0,0,0,0,15
    9228:	addi	s8,s8,1
    922c:	beq	s8,t1,9294 <.L139>
    9230:	lw	a4,-1488(gp) # ffb00220 <_ZN7ckernelL20throttled_mop_statusE>
    9234:	lw	a5,16(zero) # 10 <.LLST0+0x2>
    9238:	andi	a5,a5,1
    923c:	sw	a5,52(sp)
    9240:	lw	a5,52(sp)
    9244:	bnez	a5,913c <.L193>
    9248:	bnez	a4,98ac <.L194>
    924c:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9250:	snez	a5,a4
    9254:	slli	a5,a5,0x9
    9258:	add	a6,a5,s5
    925c:	sw	a6,0(s0)
    9260:	ttmop	1,0,0
    9264:	add	a6,a5,a1
    9268:	sw	a6,0(s0)
    926c:	ttmop	1,0,0
    9270:	add	a6,a5,a2
    9274:	sw	a6,0(s0)
    9278:	ttmop	1,0,0
    927c:	add	a5,a5,s9
    9280:	sw	a5,0(s0)
    9284:	ttmop	1,0,0
    9288:	ttsetrwc	2,0,0,0,0,15
    928c:	addi	s8,s8,1
    9290:	bne	s8,t1,9230 <.L195>
    9294:	ttstallwait	2,2064
    9298:	ttsempost	2
    929c:	sub	a5,s3,a4
    92a0:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    92a4:	ttstallwait	128,2064
    92a8:	addi	a5,a4,-1 # 34097fff <__device_print_strings_info_end+0x2db97fff>
    92ac:	snez	a5,a5
    92b0:	slli	a5,a5,0x9
    92b4:	add	a5,a5,s5
    92b8:	sw	a5,0(s0)
    92bc:	sw	t5,40(sp)
    92c0:	sw	t1,36(sp)
    92c4:	beq	t5,t6,9bac <.L141>
    92c8:	ttsetc16	12,2056
    92cc:	ttsetc16	28,8
    92d0:	ttsetc16	47,0
    92d4:	ttsetc16	13,0
    92d8:	ttsetc16	29,0
    92dc:	ttsetc16	48,0
    92e0:	ttsetc16	14,32896
    92e4:	ttsetc16	30,1024
    92e8:	ttsetc16	49,0
    92ec:	ttsetc16	15,32896
    92f0:	ttsetc16	31,36872
    92f4:	ttsetc16	50,0
    92f8:	lui	a4,0x37cc0
    92fc:	lui	a5,0x30000
    9300:	lui	s8,0x2000
    9304:	addi	a4,a4,3 # 37cc0003 <__device_print_strings_info_end+0x317c0003>
    9308:	addi	a0,sp,108
    930c:	sw	s4,108(sp)
    9310:	sw	s4,112(sp)
    9314:	sw	a5,116(sp)
    9318:	sw	a5,136(sp)
    931c:	sw	a5,140(sp)
    9320:	sw	s8,120(sp)
    9324:	sw	s8,128(sp)
    9328:	sw	s8,132(sp)
    932c:	sw	a4,124(sp)
    9330:	sw	t6,44(sp)
    9334:	jal	7220 <_ZN7ckernel16ckernel_template7programEv>
    9338:	ttsetc16	7,0
    933c:	ttsetrwc	0,0,0,0,0,15
    9340:	sfpconfig	15,0,1
    9344:	ttsetc16	19,0
    9348:	ttsetc16	35,0
    934c:	ttsetc16	54,0
    9350:	ttsetrwc	0,0,0,0,0,15
    9354:	sfploadi	L0,16384,0
    9358:	sfpconfig	12,0,0
    935c:	fence
    9360:	ttsemwait	322,2,2
    9364:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9368:	snez	a5,a5
    936c:	slli	a5,a5,0x9
    9370:	add	a5,a5,s5
    9374:	sw	a5,0(s0)
    9378:	ttmop	1,0,0
    937c:	ttsetrwc	0,0,0,0,0,4
    9380:	sw	a5,0(s0)
    9384:	ttstallwait	256,16
    9388:	jal	78b4 <_Z32calculate_exponential_polynomialILb1ELi4ELb0ELi4ELb1ELt15797EEvv>
    938c:	ttsetrwc	0,4,8,0,0,4
    9390:	ttsetrwc	0,4,8,0,0,4
    9394:	ttsetrwc	0,4,8,0,0,4
    9398:	ttsetrwc	0,4,8,0,0,4
    939c:	jal	78b4 <_Z32calculate_exponential_polynomialILb1ELi4ELb0ELi4ELb1ELt15797EEvv>
    93a0:	ttsetrwc	0,4,8,0,0,4
    93a4:	ttsetrwc	0,4,8,0,0,4
    93a8:	ttsetrwc	0,4,8,0,0,4
    93ac:	ttsetrwc	0,4,8,0,0,4
    93b0:	ttsetrwc	0,0,0,0,0,4
    93b4:	ttstallwait	2,2064
    93b8:	ttsempost	2
    93bc:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    93c0:	sub	a3,s3,a5
    93c4:	sw	a3,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    93c8:	ttstallwait	128,2064
    93cc:	addi	a5,a5,-1 # 2fffffff <__device_print_strings_info_end+0x29afffff>
    93d0:	snez	a5,a5
    93d4:	slli	a5,a5,0x9
    93d8:	add	a5,a5,s5
    93dc:	sw	a5,0(s0)
    93e0:	ttsetc16	12,2056
    93e4:	ttsetc16	28,8
    93e8:	ttsetc16	47,0
    93ec:	ttsetc16	13,0
    93f0:	ttsetc16	29,0
    93f4:	ttsetc16	48,0
    93f8:	ttsetc16	14,32896
    93fc:	ttsetc16	30,9216
    9400:	ttsetc16	49,0
    9404:	ttsetc16	15,32896
    9408:	ttsetc16	31,36872
    940c:	ttsetc16	50,0
    9410:	lui	a5,0x27000
    9414:	sw	a5,116(sp)
    9418:	lui	a5,0x27008
    941c:	sw	a5,140(sp)
    9420:	addi	a0,sp,108
    9424:	lui	a5,0x27c0c
    9428:	sw	a5,136(sp)
    942c:	sw	s4,108(sp)
    9430:	sw	s4,112(sp)
    9434:	sw	s8,120(sp)
    9438:	sw	s8,124(sp)
    943c:	sw	s8,128(sp)
    9440:	sw	s8,132(sp)
    9444:	jal	7220 <_ZN7ckernel16ckernel_template7programEv>
    9448:	ttsetc16	7,0
    944c:	ttsetrwc	0,0,0,0,0,15
    9450:	fence
    9454:	ttsemwait	322,2,2
    9458:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    945c:	snez	a3,a5
    9460:	slli	a3,a3,0x9
    9464:	add	a3,a3,s5
    9468:	sw	a3,0(s0)
    946c:	ttmop	1,0,0
    9470:	ttmop	1,0,0
    9474:	ttsetrwc	0,0,0,0,0,4
    9478:	ttstallwait	2,2064
    947c:	ttsempost	2
    9480:	sub	a3,s3,a5
    9484:	sw	a3,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9488:	ttstallwait	128,2064
    948c:	addi	a5,a5,-1 # 27c0bfff <__device_print_strings_info_end+0x2170bfff>
    9490:	snez	a5,a5
    9494:	slli	a5,a5,0x9
    9498:	add	a5,a5,s5
    949c:	sw	a5,0(s0)
    94a0:	ttsetc16	12,2056
    94a4:	ttsetc16	28,8
    94a8:	ttsetc16	47,0
    94ac:	ttsetc16	13,0
    94b0:	ttsetc16	29,0
    94b4:	ttsetc16	48,0
    94b8:	ttsetc16	14,32896
    94bc:	ttsetc16	30,9216
    94c0:	ttsetc16	49,0
    94c4:	ttsetc16	15,32896
    94c8:	ttsetc16	31,36872
    94cc:	ttsetc16	50,0
    94d0:	lui	a4,0xffe80
    94d4:	li	a5,0
    94d8:	addi	t3,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    94dc:	sw	a5,0(t3)
    94e0:	lw	a5,0(t3)
    94e4:	and	zero,zero,a5
    94e8:	sw	s4,0(s7)
    94ec:	sw	s4,4(s7)
    94f0:	sw	s8,8(s7)
    94f4:	sw	s8,12(s7)
    94f8:	sw	s8,16(s7)
    94fc:	lui	a5,0x27080
    9500:	sw	a5,20(s7)
    9504:	sw	s8,24(s7)
    9508:	lui	a5,0x2748c
    950c:	sw	a5,28(s7)
    9510:	lui	a5,0x27088
    9514:	sw	a5,32(s7)
    9518:	ttsetc16	7,0
    951c:	ttsetrwc	0,0,0,0,0,15
    9520:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9524:	ttsemwait	322,2,2
    9528:	snez	a3,a5
    952c:	slli	a3,a3,0x9
    9530:	add	a3,a3,s5
    9534:	sw	a3,0(s0)
    9538:	ttmop	1,0,0
    953c:	ttmop	1,0,0
    9540:	ttsetrwc	2,0,0,0,0,0
    9544:	ttsetrwc	0,0,0,0,0,4
    9548:	ttstallwait	2,2064
    954c:	ttsempost	2
    9550:	ttstallwait	128,2064
    9554:	addi	a5,a5,-1 # 27087fff <__device_print_strings_info_end+0x20b87fff>
    9558:	snez	a5,a5
    955c:	slli	a5,a5,0x9
    9560:	add	a5,a5,s5
    9564:	sw	a5,0(s0)
    9568:	ttsemwait	322,2,2
    956c:	sw	a5,0(s0)
    9570:	ttmop	1,0,0
    9574:	ttmop	1,0,0
    9578:	ttsetrwc	2,0,0,0,0,0
    957c:	ttsetrwc	0,0,0,0,0,4
    9580:	ttstallwait	2,2064
    9584:	ttsempost	2
    9588:	ttstallwait	128,2064
    958c:	sw	a3,0(s0)
    9590:	ttsemwait	322,2,2
    9594:	sw	a3,0(s0)
    9598:	ttmop	1,0,0
    959c:	ttmop	1,0,0
    95a0:	ttsetrwc	2,0,0,0,0,0
    95a4:	ttsetrwc	0,0,0,0,0,4
    95a8:	ttstallwait	2,2064
    95ac:	ttsempost	2
    95b0:	ttstallwait	128,2064
    95b4:	sw	a5,0(s0)
    95b8:	ttsemwait	322,2,2
    95bc:	sw	a5,0(s0)
    95c0:	ttmop	1,0,0
    95c4:	ttmop	1,0,0
    95c8:	ttsetrwc	2,0,0,0,0,0
    95cc:	ttsetrwc	0,0,0,0,0,4
    95d0:	ttstallwait	2,2064
    95d4:	ttsempost	2
    95d8:	ttstallwait	128,2064
    95dc:	sw	a3,0(s0)
    95e0:	ttsetc16	12,2056
    95e4:	ttsetc16	28,8
    95e8:	ttsetc16	47,0
    95ec:	ttsetc16	13,0
    95f0:	ttsetc16	29,0
    95f4:	ttsetc16	48,0
    95f8:	ttsetc16	14,32896
    95fc:	ttsetc16	30,1024
    9600:	ttsetc16	49,0
    9604:	ttsetc16	15,32896
    9608:	ttsetc16	31,36872
    960c:	ttsetc16	50,0
    9610:	lui	a3,0x37cc0
    9614:	lui	a5,0x28000
    9618:	addi	a4,a3,3 # 37cc0003 <__device_print_strings_info_end+0x317c0003>
    961c:	addi	a0,sp,108
    9620:	sw	s4,108(sp)
    9624:	sw	s4,112(sp)
    9628:	sw	s8,120(sp)
    962c:	sw	s8,128(sp)
    9630:	sw	s8,132(sp)
    9634:	sw	a4,124(sp)
    9638:	sw	a5,116(sp)
    963c:	sw	a5,136(sp)
    9640:	sw	a5,140(sp)
    9644:	jal	7220 <_ZN7ckernel16ckernel_template7programEv>
    9648:	ttsetc16	7,0
    964c:	ttsetrwc	0,0,0,0,0,15
    9650:	ttsemwait	322,2,2
    9654:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9658:	snez	a4,a5
    965c:	slli	a4,a4,0x9
    9660:	add	a4,a4,s5
    9664:	sw	a4,0(s0)
    9668:	ttmop	1,0,0
    966c:	ttsetrwc	0,0,0,0,0,4
    9670:	ttstallwait	2,2064
    9674:	ttsempost	2
    9678:	sub	a4,s3,a5
    967c:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9680:	ttstallwait	128,2064
    9684:	addi	a5,a5,-1 # 27ffffff <__device_print_strings_info_end+0x21afffff>
    9688:	snez	a5,a5
    968c:	slli	a5,a5,0x9
    9690:	add	a5,a5,s5
    9694:	sw	a5,0(s0)
    9698:	jal	7564 <_Z17add_block_inplaceILb0EEvmmm.constprop.0.isra.0>
    969c:	jal	8060 <_Z10move_blockILb1EEvmmm.constprop.1>
    96a0:	jal	7db4 <_Z10move_blockILb1EEvmmm.constprop.0>
    96a4:	lw	t6,44(sp)
    96a8:	lui	a4,0xffe80
    96ac:	lw	a5,12(sp)
    96b0:	addi	t3,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    96b4:	addi	t6,t6,1
    96b8:	lui	a4,0x37400
    96bc:	lw	t1,36(sp)
    96c0:	lw	t5,40(sp)
    96c4:	addi	t4,a4,15 # 3740000f <__device_print_strings_info_end+0x30f0000f>
    96c8:	bgeu	t6,a5,96d0 <.L143>
    96cc:	j	8630 <.L144>
    96d0:	lw	a5,8(sp)
    96d4:	bnez	a5,9be4 <.L196>
    96d8:	lw	a4,20(sp)
    96dc:	li	a5,1
    96e0:	beq	a4,a5,9d3c <.L197>
    96e4:	lw	a4,28(sp)
    96e8:	li	a5,-1
    96ec:	bne	a4,a5,9e68 <.L198>
    96f0:	lw	s1,196(sp)
    96f4:	lw	s4,184(sp)
    96f8:	lw	s5,180(sp)
    96fc:	lw	s6,176(sp)
    9700:	lw	s7,172(sp)
    9704:	lw	s8,168(sp)
    9708:	lw	s9,164(sp)
    970c:	lw	s10,160(sp)
    9710:	lw	s11,156(sp)
    9714:	lw	ra,204(sp)
    9718:	lw	s0,200(sp)
    971c:	lw	s2,192(sp)
    9720:	lw	s3,188(sp)
    9724:	addi	sp,sp,208
    9728:	ret
    972c:	lui	a4,0xffec1
    9730:	lw	s0,0(a4) # ffec1000 <__instrn_buffer+0x81000>
    9734:	beq	s0,a5,973c <.LBE8219+0x8>
    9738:	j	8448 <.L97>
    973c:	j	9714 <.L95>
    9740:	sub	a4,a4,s3
    9744:	srli	a2,a5,0x4
    9748:	mul	t5,a2,a4
    974c:	andi	a3,a5,15
    9750:	min	a1,a3,a4
    9754:	add	t5,t5,a1
    9758:	add	a2,a2,t5
    975c:	sw	a2,12(sp)
    9760:	blt	a4,a3,9768 <.LM4351>
    9764:	j	84ac <.L102>
    9768:	addi	a4,a2,1
    976c:	sw	a4,12(sp)
    9770:	beq	a4,t5,9778 <.LBE10258+0x8>
    9774:	j	84ac <.L102>
    9778:	j	9e38 <.L176>
    977c:	ttsetrwc	2,0,0,0,0,15
    9780:	bgeu	s4,s1,881c <.L116>
    9784:	add	a3,a5,a6
    9788:	sw	a3,0(s0)
    978c:	ttmop	1,0,0
    9790:	ttmop	1,0,0
    9794:	ttsetrwc	1,0,0,0,0,15
    9798:	j	8800 <.L119>
    979c:	ttsetrwc	2,0,0,0,0,15
    97a0:	j	8800 <.L119>
    97a4:	ttsetrwc	2,0,0,0,0,15
    97a8:	beq	s1,s3,881c <.L116>
    97ac:	add	a3,a5,a1
    97b0:	sw	a3,0(s0)
    97b4:	ttmop	1,0,0
    97b8:	ttmop	1,0,0
    97bc:	ttsetrwc	1,0,0,0,0,15
    97c0:	j	87e4 <.L118>
    97c4:	ttsetrwc	2,0,0,0,0,15
    97c8:	bgeu	s4,s1,8820 <.L122>
    97cc:	add	a3,a5,a6
    97d0:	sw	a3,0(s0)
    97d4:	ttmop	1,0,0
    97d8:	j	8888 <.L126>
    97dc:	ttsetrwc	2,0,0,0,0,15
    97e0:	bgeu	a0,s1,8820 <.L122>
    97e4:	add	a5,a5,s9
    97e8:	sw	a5,0(s0)
    97ec:	ttmop	1,0,0
    97f0:	j	8820 <.L122>
    97f4:	ttsetrwc	2,0,0,0,0,15
    97f8:	beq	s1,s3,8820 <.L122>
    97fc:	add	a3,a5,a1
    9800:	sw	a3,0(s0)
    9804:	ttmop	1,0,0
    9808:	j	8874 <.L125>
    980c:	ttsetc16	12,2048
    9810:	ttsetc16	28,8
    9814:	ttsetc16	47,0
    9818:	ttsetc16	17,49344
    981c:	ttsetc16	33,11264
    9820:	ttsetc16	52,0
    9824:	ttsetc16	13,16416
    9828:	ttsetc16	29,8
    982c:	ttsetc16	48,0
    9830:	ttsetc16	14,16416
    9834:	ttsetc16	30,8
    9838:	ttsetc16	49,0
    983c:	ttsetc16	16,20560
    9840:	ttsetc16	32,1024
    9844:	ttsetc16	51,0
    9848:	ttreplay	16,8,0,1
    984c:	ttmvmul	0,0,0,0
    9850:	ttmvmul	0,0,2,0
    9854:	ttmvmul	0,0,0,0
    9858:	ttmvmul	0,0,4,0
    985c:	ttmvmul	0,0,0,0
    9860:	ttmvmul	0,0,1,0
    9864:	ttmvmul	0,0,0,0
    9868:	ttmvmul	0,0,5,0
    986c:	mv	a5,a2
    9870:	sw	a5,0(t3)
    9874:	lw	a5,0(t3)
    9878:	and	zero,zero,a5
    987c:	sw	s3,0(s7)
    9880:	sw	s4,4(s7)
    9884:	sw	a7,8(s7)
    9888:	sw	t4,12(s7)
    988c:	sw	a7,16(s7)
    9890:	sw	s11,20(s7)
    9894:	sw	a7,24(s7)
    9898:	sw	s11,28(s7)
    989c:	sw	s11,32(s7)
    98a0:	ttsetrwc	0,0,0,0,0,15
    98a4:	sw	zero,-1488(gp) # ffb00220 <_ZN7ckernelL20throttled_mop_statusE>
    98a8:	j	8844 <.L121>
    98ac:	ttsetc16	12,2048
    98b0:	ttsetc16	28,8
    98b4:	ttsetc16	47,0
    98b8:	ttsetc16	17,49344
    98bc:	ttsetc16	33,11264
    98c0:	ttsetc16	52,0
    98c4:	ttsetc16	13,16400
    98c8:	ttsetc16	29,8
    98cc:	ttsetc16	48,0
    98d0:	ttsetc16	14,16400
    98d4:	ttsetc16	30,8
    98d8:	ttsetc16	49,0
    98dc:	ttsetc16	16,20496
    98e0:	ttsetc16	32,1024
    98e4:	ttsetc16	51,0
    98e8:	ttreplay	16,8,0,1
    98ec:	ttmvmul	0,0,0,0
    98f0:	ttmvmul	0,0,2,0
    98f4:	ttmvmul	0,0,0,0
    98f8:	ttmvmul	0,0,4,0
    98fc:	ttmvmul	0,0,0,0
    9900:	ttmvmul	0,0,1,0
    9904:	ttmvmul	0,0,0,0
    9908:	ttmvmul	0,0,5,0
    990c:	sw	a5,0(t3)
    9910:	lw	a5,0(t3)
    9914:	and	zero,zero,a5
    9918:	sw	s3,0(s7)
    991c:	sw	s4,4(s7)
    9920:	sw	a3,8(s7)
    9924:	sw	t4,12(s7)
    9928:	sw	a3,16(s7)
    992c:	sw	s11,20(s7)
    9930:	sw	a3,24(s7)
    9934:	sw	s11,28(s7)
    9938:	sw	s11,32(s7)
    993c:	ttsetrwc	0,0,0,0,0,15
    9940:	sw	zero,-1488(gp) # ffb00220 <_ZN7ckernelL20throttled_mop_statusE>
    9944:	j	924c <.L138>
    9948:	ttsetc16	12,2056
    994c:	ttsetc16	28,8
    9950:	ttsetc16	47,0
    9954:	ttsetc16	13,0
    9958:	ttsetc16	29,0
    995c:	ttsetc16	48,0
    9960:	ttsetc16	14,32896
    9964:	ttsetc16	30,1024
    9968:	ttsetc16	49,0
    996c:	ttsetc16	15,32896
    9970:	ttsetc16	31,36872
    9974:	ttsetc16	50,0
    9978:	mv	a5,s8
    997c:	sw	a5,0(t3)
    9980:	lw	a5,0(t3)
    9984:	and	zero,zero,a5
    9988:	sw	s4,0(s7)
    998c:	sw	s4,4(s7)
    9990:	lui	a4,0x2000
    9994:	lui	a5,0x37cc0
    9998:	sw	a4,8(s7)
    999c:	addi	a5,a5,3 # 37cc0003 <__device_print_strings_info_end+0x317c0003>
    99a0:	sw	a5,12(s7)
    99a4:	sw	a4,16(s7)
    99a8:	lui	a5,0x28200
    99ac:	sw	a5,20(s7)
    99b0:	sw	a4,24(s7)
    99b4:	sw	a5,28(s7)
    99b8:	sw	a5,32(s7)
    99bc:	ttsetc16	7,0
    99c0:	ttsetrwc	0,0,0,0,0,15
    99c4:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    99c8:	snez	a5,a4
    99cc:	slli	a5,a5,0x9
    99d0:	add	a3,a5,s5
    99d4:	sw	a3,0(s0)
    99d8:	ttmop	1,0,0
    99dc:	ttsetrwc	0,0,0,0,0,4
    99e0:	bne	s1,s3,99e8 <.LBB8661>
    99e4:	j	88ac <.L129>
    99e8:	addi	a3,s5,64
    99ec:	add	a3,a5,a3
    99f0:	sw	a3,0(s0)
    99f4:	ttmop	1,0,0
    99f8:	ttsetrwc	0,0,0,0,0,4
    99fc:	bltu	s4,s1,9a04 <.LBB8662>
    9a00:	j	88ac <.L129>
    9a04:	addi	a3,s5,128
    9a08:	add	a3,a5,a3
    9a0c:	sw	a3,0(s0)
    9a10:	ttmop	1,0,0
    9a14:	ttsetrwc	0,0,0,0,0,4
    9a18:	li	a3,3
    9a1c:	bltu	a3,s1,9a24 <.LBB8663>
    9a20:	j	88ac <.L129>
    9a24:	add	a5,a5,s9
    9a28:	sw	a5,0(s0)
    9a2c:	ttmop	1,0,0
    9a30:	ttsetrwc	0,0,0,0,0,4
    9a34:	j	88ac <.L129>
    9a38:	li	a1,5
    9a3c:	li	a0,2
    9a40:	sw	t6,44(sp)
    9a44:	sw	t5,40(sp)
    9a48:	sw	t1,36(sp)
    9a4c:	jal	7afc <_Z38_llk_math_eltwise_unary_datacopy_init_ILN7ckernel12DataCopyTypeE0ELb1ELNS0_13BroadcastTypeE0ELb0ELb0EEvmmb.constprop.0>
    9a50:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9a54:	addi	a3,s5,64
    9a58:	snez	a4,a5
    9a5c:	slli	a4,a4,0x9
    9a60:	add	a3,a4,a3
    9a64:	sw	a3,0(s0)
    9a68:	ttmop	1,0,0
    9a6c:	ttsetrwc	0,0,0,0,0,4
    9a70:	add	a4,a4,s5
    9a74:	sw	a4,0(s0)
    9a78:	ttstallwait	256,16
    9a7c:	lui	a1,0x9300e
    9a80:	lui	a4,0x7020e
    9a84:	sw	a1,0(s0)
    9a88:	addi	a4,a4,64 # 7020e040 <__device_print_strings_info_end+0x69d0e040>
    9a8c:	sw	a4,0(s0)
    9a90:	lui	a3,0x9370c
    9a94:	sw	a3,0(s0)
    9a98:	lui	a2,0x9310e
    9a9c:	sw	a2,0(s0)
    9aa0:	sw	a4,0(s0)
    9aa4:	sw	a3,0(s0)
    9aa8:	sw	a1,0(s0)
    9aac:	sw	a4,0(s0)
    9ab0:	sw	a3,0(s0)
    9ab4:	sw	a2,0(s0)
    9ab8:	sw	a4,0(s0)
    9abc:	sw	a3,0(s0)
    9ac0:	sw	a1,0(s0)
    9ac4:	sw	a4,0(s0)
    9ac8:	sw	a3,0(s0)
    9acc:	sw	a2,0(s0)
    9ad0:	sw	a4,0(s0)
    9ad4:	sw	a3,0(s0)
    9ad8:	sw	a1,0(s0)
    9adc:	sw	a4,0(s0)
    9ae0:	sw	a3,0(s0)
    9ae4:	sw	a2,0(s0)
    9ae8:	sw	a4,0(s0)
    9aec:	sw	a3,0(s0)
    9af0:	sfpnop
    9af4:	sfpnop
    9af8:	sfpnop
    9afc:	ttsetrwc	0,4,8,0,0,4
    9b00:	ttsetrwc	0,4,8,0,0,4
    9b04:	sw	a1,0(s0)
    9b08:	sw	a4,0(s0)
    9b0c:	sw	a3,0(s0)
    9b10:	sw	a2,0(s0)
    9b14:	sw	a4,0(s0)
    9b18:	sw	a3,0(s0)
    9b1c:	sw	a1,0(s0)
    9b20:	sw	a4,0(s0)
    9b24:	sw	a3,0(s0)
    9b28:	sw	a2,0(s0)
    9b2c:	sw	a4,0(s0)
    9b30:	sw	a3,0(s0)
    9b34:	sw	a1,0(s0)
    9b38:	sw	a4,0(s0)
    9b3c:	sw	a3,0(s0)
    9b40:	sw	a2,0(s0)
    9b44:	sw	a4,0(s0)
    9b48:	sw	a3,0(s0)
    9b4c:	sw	a1,0(s0)
    9b50:	sw	a4,0(s0)
    9b54:	sw	a3,0(s0)
    9b58:	sw	a2,0(s0)
    9b5c:	sw	a4,0(s0)
    9b60:	sw	a3,0(s0)
    9b64:	sfpnop
    9b68:	sfpnop
    9b6c:	sfpnop
    9b70:	ttsetrwc	0,4,8,0,0,4
    9b74:	ttsetrwc	0,4,8,0,0,4
    9b78:	ttsetrwc	0,4,8,0,0,4
    9b7c:	ttsetrwc	0,4,8,0,0,4
    9b80:	ttsetrwc	0,4,8,0,0,4
    9b84:	ttsetrwc	0,4,8,0,0,4
    9b88:	ttsetrwc	0,0,0,0,0,4
    9b8c:	lui	a4,0x37400
    9b90:	addi	t4,a4,15 # 3740000f <__device_print_strings_info_end+0x30f0000f>
    9b94:	lui	a4,0xffe80
    9b98:	lw	t6,44(sp)
    9b9c:	lw	t5,40(sp)
    9ba0:	lw	t1,36(sp)
    9ba4:	addi	t3,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    9ba8:	j	8a88 <.L132>
    9bac:	jal	8060 <_Z10move_blockILb1EEvmmm.constprop.1>
    9bb0:	jal	7db4 <_Z10move_blockILb1EEvmmm.constprop.0>
    9bb4:	lw	t5,40(sp)
    9bb8:	lui	a4,0xffe80
    9bbc:	lw	a5,12(sp)
    9bc0:	addi	t3,a4,8 # ffe80008 <__instrn_buffer+0x40008>
    9bc4:	addi	t6,t5,1
    9bc8:	lui	a4,0x37400
    9bcc:	lw	t1,36(sp)
    9bd0:	addi	t4,a4,15 # 3740000f <__device_print_strings_info_end+0x30f0000f>
    9bd4:	bgeu	t6,a5,9bdc <.LBE10239>
    9bd8:	j	8630 <.L144>
    9bdc:	lw	a5,8(sp)
    9be0:	beqz	a5,96d8 <.L113>
    9be4:	lw	a5,16(sp)
    9be8:	beqz	a5,96d8 <.L113>
    9bec:	lui	s4,0xb2010
    9bf0:	lui	s1,0x4
    9bf4:	addi	s3,sp,60
    9bf8:	addi	s2,s4,64 # b2010040 <__device_print_strings_info_end+0xabb10040>
    9bfc:	sh2add	s7,a5,s3
    9c00:	addi	s1,s1,-587 # 3db5 <.LASF3163+0x5>
    9c04:	li	s5,-1
    9c08:	lw	a5,0(s3)
    9c0c:	li	a0,7
    9c10:	beq	a5,s5,9d28 <.L147>
    9c14:	jal	7e90 <_Z10move_blockILb1EEvmmm.constprop.2>
    9c18:	ttsemwait	322,2,2
    9c1c:	li	a1,5
    9c20:	li	a0,2
    9c24:	jal	7afc <_Z38_llk_math_eltwise_unary_datacopy_init_ILN7ckernel12DataCopyTypeE0ELb1ELNS0_13BroadcastTypeE0ELb0ELb0EEvmmb.constprop.0>
    9c28:	sfpconfig	15,0,1
    9c2c:	ttsetc16	19,0
    9c30:	ttsetc16	35,0
    9c34:	ttsetc16	54,0
    9c38:	ttsetrwc	0,0,0,0,0,15
    9c3c:	sfploadi	L0,16384,0
    9c40:	sfpconfig	12,0,0
    9c44:	li	a1,5
    9c48:	mv	a0,a1
    9c4c:	jal	7288 <_Z33_llk_math_eltwise_unary_datacopy_ILN7ckernel12DataCopyTypeE0ELNS0_7DstSyncE0ELb1ELNS0_13BroadcastTypeE0ELb1EEvmmmm.constprop.3>
    9c50:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9c54:	snez	a5,a5
    9c58:	slli	a5,a5,0x9
    9c5c:	add	a4,a5,s2
    9c60:	sw	a4,0(s0)
    9c64:	ttmop	1,0,0
    9c68:	ttsetrwc	0,0,0,0,0,4
    9c6c:	addi	a4,s4,192
    9c70:	add	a4,a5,a4
    9c74:	sw	a4,0(s0)
    9c78:	ttmop	1,0,0
    9c7c:	ttsetrwc	0,0,0,0,0,4
    9c80:	addi	a4,s4,256
    9c84:	add	a4,a5,a4
    9c88:	sw	a4,0(s0)
    9c8c:	ttmop	1,0,0
    9c90:	ttsetrwc	0,0,0,0,0,4
    9c94:	add	a5,a5,s4
    9c98:	sw	a5,0(s0)
    9c9c:	ttstallwait	256,16
    9ca0:	mv	a0,s1
    9ca4:	jal	8258 <_Z36calculate_fused_max_sub_exp_add_tileILb0EEvi>
    9ca8:	ttsetrwc	0,4,8,0,0,4
    9cac:	ttsetrwc	0,4,8,0,0,4
    9cb0:	mv	a0,s1
    9cb4:	jal	8258 <_Z36calculate_fused_max_sub_exp_add_tileILb0EEvi>
    9cb8:	ttsetrwc	0,4,8,0,0,4
    9cbc:	ttsetrwc	0,4,8,0,0,4
    9cc0:	ttsetrwc	0,4,8,0,0,4
    9cc4:	ttsetrwc	0,4,8,0,0,4
    9cc8:	ttsetrwc	0,4,8,0,0,4
    9ccc:	ttsetrwc	0,4,8,0,0,4
    9cd0:	ttsetrwc	0,0,0,0,0,4
    9cd4:	ttstallwait	2,2064
    9cd8:	ttsempost	2
    9cdc:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9ce0:	li	a4,1
    9ce4:	sub	a4,a4,a5
    9ce8:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9cec:	ttstallwait	128,2064
    9cf0:	addi	a5,a5,-1 # 281fffff <__device_print_strings_info_end+0x21cfffff>
    9cf4:	snez	a5,a5
    9cf8:	slli	a5,a5,0x9
    9cfc:	add	a5,a5,s4
    9d00:	sw	a5,0(s0)
    9d04:	li	a0,16
    9d08:	jal	7be4 <_Z10move_blockILb1EEvmmm.constprop.3>
    9d0c:	li	a0,26
    9d10:	jal	76a0 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm.isra.0>
    9d14:	li	a0,23
    9d18:	jal	76a0 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm.isra.0>
    9d1c:	jal	7564 <_Z17add_block_inplaceILb0EEvmmm.constprop.0.isra.0>
    9d20:	jal	8060 <_Z10move_blockILb1EEvmmm.constprop.1>
    9d24:	jal	7db4 <_Z10move_blockILb1EEvmmm.constprop.0>
    9d28:	addi	s3,s3,4
    9d2c:	bne	s3,s7,9c08 <.L148>
    9d30:	lw	a4,20(sp)
    9d34:	li	a5,1
    9d38:	bne	a4,a5,96e4 <.L171>
    9d3c:	li	a1,5
    9d40:	li	a0,2
    9d44:	jal	7afc <_Z38_llk_math_eltwise_unary_datacopy_init_ILN7ckernel12DataCopyTypeE0ELb1ELNS0_13BroadcastTypeE0ELb0ELb0EEvmmb.constprop.0>
    9d48:	sfpconfig	15,0,1
    9d4c:	ttsetc16	19,0
    9d50:	ttsetc16	35,0
    9d54:	ttsetc16	54,0
    9d58:	ttsetc16	18,0
    9d5c:	ttsetc16	34,2
    9d60:	ttsetc16	53,0
    9d64:	ttsetrwc	0,0,0,0,0,15
    9d68:	ttsemwait	322,2,2
    9d6c:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9d70:	lui	s1,0xb2010
    9d74:	snez	a5,a5
    9d78:	slli	a5,a5,0x9
    9d7c:	add	a5,a5,s1
    9d80:	sw	a5,0(s0)
    9d84:	ttmop	1,0,0
    9d88:	ttsetrwc	0,0,0,0,0,4
    9d8c:	sw	a5,0(s0)
    9d90:	ttstallwait	256,16
    9d94:	jal	7a80 <_Z28calculate_recip_first_columnILb1EEvv>
    9d98:	ttsetrwc	0,4,8,0,0,4
    9d9c:	ttsetrwc	0,4,8,0,0,4
    9da0:	ttsetrwc	0,4,8,0,0,4
    9da4:	ttsetrwc	0,4,8,0,0,4
    9da8:	jal	7a80 <_Z28calculate_recip_first_columnILb1EEvv>
    9dac:	ttsetrwc	0,4,8,0,0,4
    9db0:	ttsetrwc	0,4,8,0,0,4
    9db4:	ttsetrwc	0,4,8,0,0,4
    9db8:	ttsetrwc	0,4,8,0,0,4
    9dbc:	ttsetrwc	0,0,0,0,0,4
    9dc0:	ttstallwait	2,2064
    9dc4:	ttsempost	2
    9dc8:	lw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9dcc:	lw	a4,20(sp)
    9dd0:	sub	a4,a4,a5
    9dd4:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9dd8:	ttstallwait	128,2064
    9ddc:	addi	a5,a5,-1
    9de0:	snez	a5,a5
    9de4:	slli	a5,a5,0x9
    9de8:	add	a5,a5,s1
    9dec:	li	a0,26
    9df0:	sw	a5,0(s0)
    9df4:	jal	76a0 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm.isra.0>
    9df8:	lw	s0,200(sp)
    9dfc:	lw	s1,196(sp)
    9e00:	lw	s4,184(sp)
    9e04:	lw	s5,180(sp)
    9e08:	lw	s6,176(sp)
    9e0c:	lw	s7,172(sp)
    9e10:	lw	s8,168(sp)
    9e14:	lw	s9,164(sp)
    9e18:	lw	s10,160(sp)
    9e1c:	lw	s11,156(sp)
    9e20:	lw	ra,204(sp)
    9e24:	lw	s2,192(sp)
    9e28:	lw	s3,188(sp)
    9e2c:	li	a0,26
    9e30:	addi	sp,sp,208
    9e34:	j	7be4 <_Z10move_blockILb1EEvmmm.constprop.3>
    9e38:	lw	ra,204(sp)
    9e3c:	lw	s0,200(sp)
    9e40:	lw	s1,196(sp)
    9e44:	lw	s2,192(sp)
    9e48:	lw	s3,188(sp)
    9e4c:	addi	sp,sp,208
    9e50:	ret
    9e54:	sub	t5,a5,s3
    9e58:	addi	t5,t5,-1
    9e5c:	add	a4,a4,t5
    9e60:	sw	a4,12(sp)
    9e64:	j	84a4 <.L101>
    9e68:	li	a0,26
    9e6c:	jal	7be4 <_Z10move_blockILb1EEvmmm.constprop.3>
    9e70:	li	a0,28
    9e74:	jal	7e90 <_Z10move_blockILb1EEvmmm.constprop.2>
    9e78:	lw	s0,200(sp)
    9e7c:	lw	s1,196(sp)
    9e80:	lw	s4,184(sp)
    9e84:	lw	s5,180(sp)
    9e88:	lw	s6,176(sp)
    9e8c:	lw	s7,172(sp)
    9e90:	lw	s8,168(sp)
    9e94:	lw	s9,164(sp)
    9e98:	lw	s10,160(sp)
    9e9c:	lw	s11,156(sp)
    9ea0:	lw	ra,204(sp)
    9ea4:	lw	s2,192(sp)
    9ea8:	lw	s3,188(sp)
    9eac:	li	a0,30
    9eb0:	addi	sp,sp,208
    9eb4:	j	7e90 <_Z10move_blockILb1EEvmmm.constprop.2>
    9eb8:	lw	a5,8(sp)
    9ebc:	addi	a5,a5,1
    9ec0:	sw	a5,8(sp)
    9ec4:	li	a5,6
    9ec8:	sw	a5,16(sp)
    9ecc:	j	854c <.L110>
    9ed0:	lw	a4,8(sp)
    9ed4:	addi	a4,a4,1
    9ed8:	sw	a4,8(sp)
    9edc:	li	a4,5
    9ee0:	sw	a4,16(sp)
    9ee4:	j	8538 <.L108>
    9ee8:	lw	a3,8(sp)
    9eec:	addi	a3,a3,1 # 9370c001 <__device_print_strings_info_end+0x8d20c001>
    9ef0:	sw	a3,8(sp)
    9ef4:	li	a3,4
    9ef8:	sw	a3,16(sp)
    9efc:	j	8524 <.L107>
    9f00:	lw	a4,8(sp)
    9f04:	addi	a4,a4,1
    9f08:	sw	a4,8(sp)
    9f0c:	li	a4,3
    9f10:	sw	a4,16(sp)
    9f14:	j	8510 <.L106>
    9f18:	lw	a3,8(sp)
    9f1c:	addi	a3,a3,1
    9f20:	sw	a3,8(sp)
    9f24:	li	a3,2
    9f28:	sw	a3,16(sp)
    9f2c:	j	84fc <.L105>
    9f30:	li	a4,1
    9f34:	sw	a4,8(sp)
    9f38:	j	84e0 <.L104>
00009f3c <memcpy>:
    9f3c:	xor	a5,a1,a0
    9f40:	andi	a5,a5,3
    9f44:	sltiu	a4,a2,4
    9f48:	snez	a5,a5
    9f4c:	or	a5,a5,a4
    9f50:	add	a2,a0,a2
    9f54:	bnez	a5,9fb8 <.L26>
    9f58:	andi	a5,a0,3
    9f5c:	mv	a4,a0
    9f60:	bnez	a5,a034 <.L8>
    9f64:	andi	a6,a2,-4
    9f68:	sub	a3,a6,a4
    9f6c:	li	a5,32
    9f70:	blt	a5,a3,9fd8 <.L9>
    9f74:	mv	a3,a1
    9f78:	mv	a5,a4
    9f7c:	bgeu	a4,a6,9fb0 <.L11>
    9f80:	lw	a7,0(a3)
    9f84:	addi	a5,a5,4
    9f88:	sw	a7,-4(a5)
    9f8c:	addi	a3,a3,4
    9f90:	bltu	a5,a6,9f80 <.L10>
    9f94:	addi	a6,a6,-1 # b200ffff <__device_print_strings_info_end+0xabb0ffff>
    9f98:	sub	a6,a6,a4
    9f9c:	andi	a6,a6,-4
    9fa0:	addi	a1,a1,4 # 9300e004 <__device_print_strings_info_end+0x8cb0e004>
    9fa4:	addi	a4,a4,4
    9fa8:	add	a1,a1,a6
    9fac:	add	a4,a4,a6
    9fb0:	bltu	a4,a2,9fc0 <.L5>
    9fb4:	ret
    9fb8:	mv	a4,a0
    9fbc:	bgeu	a0,a2,9fb4 <.L16>
    9fc0:	lbu	a5,0(a1)
    9fc4:	addi	a4,a4,1
    9fc8:	sb	a5,-1(a4)
    9fcc:	addi	a1,a1,1
    9fd0:	bne	a2,a4,9fc0 <.L5>
    9fd4:	ret
    9fd8:	lw	a3,0(a1)
    9fdc:	lw	t0,4(a1)
    9fe0:	lw	t6,8(a1)
    9fe4:	lw	t5,12(a1)
    9fe8:	lw	t4,16(a1)
    9fec:	lw	t3,20(a1)
    9ff0:	lw	t1,24(a1)
    9ff4:	lw	a7,28(a1)
    9ff8:	sw	a3,0(a4)
    9ffc:	lw	a3,32(a1)
    a000:	addi	a4,a4,36
    a004:	sw	a3,-4(a4)
    a008:	sw	t0,-32(a4)
    a00c:	sub	a3,a6,a4
    a010:	sw	t6,-28(a4)
    a014:	sw	t5,-24(a4)
    a018:	sw	t4,-20(a4)
    a01c:	sw	t3,-16(a4)
    a020:	sw	t1,-12(a4)
    a024:	sw	a7,-8(a4)
    a028:	addi	a1,a1,36
    a02c:	blt	a5,a3,9fd8 <.L9>
    a030:	j	9f74 <.L12>
    a034:	lbu	a5,0(a1)
    a038:	addi	a4,a4,1
    a03c:	sb	a5,-1(a4)
    a040:	andi	a5,a4,3
    a044:	addi	a1,a1,1
    a048:	beqz	a5,9f64 <.L7>
    a04c:	lbu	a5,0(a1)
    a050:	addi	a4,a4,1
    a054:	sb	a5,-1(a4)
    a058:	andi	a5,a4,3
    a05c:	addi	a1,a1,1
    a060:	bnez	a5,a034 <.L8>
    a064:	j	9f64 <.L7>

######## TRISC2 (pack) — kernel=sdpa_flash_decode ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/sdpa_flash_decode/862833422394369673/trisc2/trisc2.elf:     file format elf32-littleriscv
00007d10 <_start>:
    7d10:	addi	sp,sp,-192
    7d14:	sw	ra,188(sp)
    7d18:	sw	s0,184(sp)
    7d1c:	sw	s1,180(sp)
    7d20:	sw	s2,176(sp)
    7d24:	sw	s7,156(sp)
    7d28:	sw	s8,152(sp)
    7d2c:	lui	a5,0xffb01
    7d30:	addi	a5,a5,-1808 # ffb008f0 <__ldm_bss_end+0x10>
    7d34:	addi	a4,gp,240 # ffb008e0 <__ldm_bss_end>
    7d38:	bltu	a4,a5,7d54 <.L75>
    7d3c:	sw	zero,-4(a5)
    7d40:	sw	zero,-8(a5)
    7d44:	sw	zero,-12(a5)
    7d48:	sw	zero,-16(a5)
    7d4c:	addi	a5,a5,16
    7d50:	bgeu	a4,a5,7d3c <.L76>
    7d54:	addi	a3,a5,-8
    7d58:	bltu	a4,a3,7d68 <.L77>
    7d5c:	sw	zero,-12(a5)
    7d60:	sw	zero,-16(a5)
    7d64:	mv	a3,a5
    7d68:	addi	a5,a3,-4
    7d6c:	bltu	a4,a5,7d74 <.L78>
    7d70:	sw	zero,-8(a3)
    7d74:	lui	a4,0xb
    7d78:	addi	a4,a4,-1488 # aa30 <__kernel_data_lma>
    7d7c:	addi	a5,gp,48 # ffb00820 <_ZL20pack_tile_face_r_dim>
    7d80:	beq	a4,a5,7df4 <.L80>
    7d84:	lui	a2,0xffb01
    7d88:	addi	a2,a2,-1824 # ffb008e0 <__ldm_bss_end>
    7d8c:	sub	a2,a2,a5
    7d90:	li	a1,8
    7d94:	srai	a3,a2,0x2
    7d98:	bge	a1,a2,7dd8 <.L81>
    7d9c:	li	a2,2
    7da0:	lw	a7,0(a4)
    7da4:	lw	a6,4(a4)
    7da8:	lw	a0,8(a4)
    7dac:	mv	a1,a5
    7db0:	mv	a5,a4
    7db4:	addi	a5,a5,12
    7db8:	addi	a1,a1,12
    7dbc:	addi	a3,a3,-3
    7dc0:	mv	a4,a5
    7dc4:	mv	a5,a1
    7dc8:	sw	a7,-12(a1)
    7dcc:	sw	a6,-8(a1)
    7dd0:	sw	a0,-4(a1)
    7dd4:	blt	a2,a3,7da0 <.L82>
    7dd8:	blez	a3,7df4 <.L80>
    7ddc:	lw	a1,0(a4)
    7de0:	li	a2,2
    7de4:	sw	a1,0(a5)
    7de8:	bne	a3,a2,7df4 <.L80>
    7dec:	lw	a4,4(a4)
    7df0:	sw	a4,4(a5)
    7df4:	lw	a5,1056(zero) # 420 <.LASF3166+0x5>
    7df8:	li	a4,128
    7dfc:	slli	a5,a5,0x2
    7e00:	lbu	a3,1011(a5)
    7e04:	addi	a5,a5,96
    7e08:	beq	a3,a4,7e18 <.L87>
    7e0c:	fence
    7e10:	lbu	a3,915(a5)
    7e14:	bne	a3,a4,7e0c <.L84>
    7e18:	lw	a5,-2012(gp) # ffb00014 <rta_l1_base>
    7e1c:	li	a2,24
    7e20:	lw	s2,0(a5)
    7e24:	addi	a1,a5,48
    7e28:	addi	a0,sp,80
    7e2c:	lw	s1,16(a5)
    7e30:	lw	s0,24(a5)
    7e34:	lw	s7,28(a5)
    7e38:	lw	s8,32(a5)
    7e3c:	jal	a904 <memcpy>
    7e40:	li	a5,65
    7e44:	bne	s2,a5,7e4c <.LM884>
    7e48:	j	91cc <.L153>
    7e4c:	li	a5,-1
    7e50:	bne	s0,a5,7e58 <.L88>
    7e54:	j	94d8 <.L205>
    7e58:	srli	a4,s0,0x6
    7e5c:	srli	a5,s0,0x5
    7e60:	or	a5,a5,a4
    7e64:	srli	a4,a5,0x2
    7e68:	or	a5,a5,a4
    7e6c:	addi	a4,a5,1
    7e70:	li	a5,4
    7e74:	minu	a5,a4,a5
    7e78:	mv	t5,a5
    7e7c:	slli	a5,a5,0x5
    7e80:	add	s0,s0,a5
    7e84:	remu	a3,s0,a5
    7e88:	mv	t4,a4
    7e8c:	sub	s0,s0,a3
    7e90:	li	a4,15
    7e94:	divu	a5,s0,a5
    7e98:	bgeu	a4,a5,7ea0 <.LBB3651>
    7e9c:	j	91f0 <.L89>
    7ea0:	slt	a3,s1,a5
    7ea4:	li	a4,0
    7ea8:	bge	s1,a5,7eb0 <.L91>
    7eac:	j	9abc <.L206>
    7eb0:	sw	a4,32(sp)
    7eb4:	add	a4,a3,a4
    7eb8:	sw	a4,28(sp)
    7ebc:	lw	a3,32(sp)
    7ec0:	bne	a4,a3,7ec8 <.L93>
    7ec4:	j	91cc <.L153>
    7ec8:	lw	a3,80(sp)
    7ecc:	sw	s5,164(sp)
    7ed0:	sw	s4,168(sp)
    7ed4:	sw	s6,160(sp)
    7ed8:	sw	s10,144(sp)
    7edc:	sw	s11,140(sp)
    7ee0:	li	s5,1
    7ee4:	bltu	a3,a5,7ef0 <.L96>
    7ee8:	li	a3,-1
    7eec:	li	s5,0
    7ef0:	lw	a4,84(sp)
    7ef4:	sw	a3,104(sp)
    7ef8:	bgeu	a4,a5,7f00 <.LM936>
    7efc:	j	9a98 <.L207>
    7f00:	li	a4,-1
    7f04:	lw	a3,88(sp)
    7f08:	sw	a4,108(sp)
    7f0c:	mv	s6,s5
    7f10:	bgeu	a3,a5,7f18 <.L159>
    7f14:	j	9ab0 <.L208>
    7f18:	li	a3,-1
    7f1c:	lw	a4,92(sp)
    7f20:	sw	a3,112(sp)
    7f24:	bgeu	a4,a5,7f2c <.LM951>
    7f28:	j	9a8c <.L209>
    7f2c:	li	a4,-1
    7f30:	lw	a3,96(sp)
    7f34:	sw	a4,116(sp)
    7f38:	bgeu	a3,a5,7f40 <.LM958>
    7f3c:	j	9a80 <.L210>
    7f40:	li	a3,-1
    7f44:	lw	a4,100(sp)
    7f48:	sw	a3,120(sp)
    7f4c:	bgeu	a4,a5,7f54 <.LM965>
    7f50:	j	9a74 <.L101>
    7f54:	li	a4,-1
    7f58:	lui	s1,0xffb00
    7f5c:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    7f60:	addi	s1,s1,32 # ffb00020 <cb_interface>
    7f64:	sw	a4,124(sp)
    7f68:	lw	a2,776(s1)
    7f6c:	lui	a3,0xffef0
    7f70:	beqz	a5,7f78 <.L94>
    7f74:	addi	a3,a3,896 # ffef0380 <__instrn_buffer+0xb0380>
    7f78:	lui	s2,0x45000
    7f7c:	lui	s0,0xffe40
    7f80:	mv	s0,s0
    7f84:	addi	a7,s2,56 # 45000038 <__device_print_strings_info_end+0x3eb00038>
    7f88:	lui	a6,0x45002
    7f8c:	sw	a7,0(s0) # ffe40000 <__instrn_buffer>
    7f90:	addi	a6,a6,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    7f94:	lui	a0,0x45020
    7f98:	sw	a6,0(s0)
    7f9c:	addi	a0,a0,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    7fa0:	lui	a1,0x45080
    7fa4:	sw	a0,0(s0)
    7fa8:	addi	a1,a1,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    7fac:	sw	a1,0(s0)
    7fb0:	ttstallwait	128,1
    7fb4:	ttwrcfg	28,0,12
    7fb8:	ttwrcfg	29,0,13
    7fbc:	ttnop
    7fc0:	ttnop
    7fc4:	ttatgetm	0
    7fc8:	lui	a5,0xb5800
    7fcc:	addi	s10,a5,71 # b5800047 <__device_print_strings_info_end+0xaf300047>
    7fd0:	lui	a5,0xb61e1
    7fd4:	sw	s10,0(s0)
    7fd8:	addi	a5,a5,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    7fdc:	sw	a5,0(s0)
    7fe0:	lui	a5,0xb3fc0
    7fe4:	addi	a5,a5,2 # b3fc0002 <__device_print_strings_info_end+0xadac0002>
    7fe8:	sw	a5,0(s0)
    7fec:	lui	a5,0xb4ff0
    7ff0:	addi	a5,a5,2 # b4ff0002 <__device_print_strings_info_end+0xaeaf0002>
    7ff4:	sw	a5,0(s0)
    7ff8:	lui	a5,0xb53f0
    7ffc:	addi	a5,a5,2 # b53f0002 <__device_print_strings_info_end+0xaeef0002>
    8000:	sw	a5,0(s0)
    8004:	ttatrelm	0
    8008:	lui	a5,0xb5100
    800c:	addi	s11,a5,71 # b5100047 <__device_print_strings_info_end+0xaec00047>
    8010:	lui	a5,0xb6ff0
    8014:	sw	s11,0(s0)
    8018:	addi	a5,a5,71 # b6ff0047 <__device_print_strings_info_end+0xb0af0047>
    801c:	sw	a5,8(sp)
    8020:	sw	a5,0(s0)
    8024:	lui	a4,0x10
    8028:	sw	a4,272(a3)
    802c:	li	a5,1361
    8030:	sw	a5,280(a3)
    8034:	ttstallwait	128,8
    8038:	lui	a5,0xb3040
    803c:	addi	a5,a5,70 # b3040046 <__device_print_strings_info_end+0xacb40046>
    8040:	sw	a5,0(s0)
    8044:	lui	a5,0xb5080
    8048:	addi	a5,a5,71 # b5080047 <__device_print_strings_info_end+0xaeb80047>
    804c:	sw	a5,0(s0)
    8050:	li	a5,1
    8054:	sw	a5,72(a3)
    8058:	lui	a5,0xffe00
    805c:	sw	a4,208(a5) # ffe000d0 <__ldm_bss_end+0x2ff7f0>
    8060:	sw	zero,76(sp)
    8064:	lw	t3,208(a5)
    8068:	lui	t1,0x1
    806c:	addi	a4,a4,-1 # ffff <.LASF1837+0x5>
    8070:	sw	t3,76(sp)
    8074:	sw	t1,112(a3)
    8078:	sw	a4,96(a3)
    807c:	sw	zero,80(a3)
    8080:	sw	a2,64(a5)
    8084:	sw	zero,68(a5)
    8088:	sw	zero,72(a5)
    808c:	sw	zero,76(a5)
    8090:	sw	zero,72(sp)
    8094:	lw	a5,76(a5)
    8098:	sw	a5,72(sp)
    809c:	ttsetadcxx	4,15,0
    80a0:	ttsetc16	37,260
    80a4:	ttsetc16	38,10272
    80a8:	ttsetc16	39,4384
    80ac:	lui	a3,0xffe80
    80b0:	addi	a2,a3,8 # ffe80008 <__instrn_buffer+0x40008>
    80b4:	li	a5,0
    80b8:	sw	a5,0(a2)
    80bc:	lw	a5,0(a2)
    80c0:	and	zero,zero,a5
    80c4:	lui	a5,0xffb80
    80c8:	li	a2,2
    80cc:	sw	a2,0(a5) # ffb80000 <__ldm_bss_end+0x7f720>
    80d0:	li	a2,4
    80d4:	sw	a2,4(a5)
    80d8:	lui	a2,0x2000
    80dc:	sw	a2,8(a5)
    80e0:	sw	a2,12(a5)
    80e4:	sw	a2,16(a5)
    80e8:	lui	t1,0x41000
    80ec:	sw	t1,20(a5)
    80f0:	lui	t1,0x41008
    80f4:	sw	a2,24(a5)
    80f8:	addi	a2,t1,1 # 41008001 <__device_print_strings_info_end+0x3ab08001>
    80fc:	sw	a2,28(a5)
    8100:	lui	a2,0x41010
    8104:	sw	a2,32(a5)
    8108:	sw	a7,0(s0)
    810c:	sw	a6,0(s0)
    8110:	sw	a0,0(s0)
    8114:	sw	a1,0(s0)
    8118:	ttstallwait	128,1
    811c:	ttwrcfg	28,0,12
    8120:	ttwrcfg	29,0,13
    8124:	ttnop
    8128:	ttnop
    812c:	ttsetadcxx	4,15,0
    8130:	li	a5,0
    8134:	addi	a3,a3,4
    8138:	sw	a5,0(a3)
    813c:	lw	a5,0(a3)
    8140:	and	zero,zero,a5
    8144:	sw	zero,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8148:	ttstallwait	33,8
    814c:	ttsetdmareg	0,0,0,8
    8150:	ttsetdmareg	0,512,0,16
    8154:	ttstallwait	128,1
    8158:	lui	a5,0xb0048
    815c:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    8160:	sw	a5,0(s0)
    8164:	ttdmanop
    8168:	ttdmanop
    816c:	ttsetadcxy	4,0,0,0,0,11
    8170:	ttsetadczw	4,0,0,0,0,15
    8174:	lw	a1,32(sp)
    8178:	lw	a5,28(sp)
    817c:	bltu	a1,a5,8184 <.LBB3784>
    8180:	j	91a4 <.L103>
    8184:	lui	a5,0xb30b0
    8188:	addi	a5,a5,274 # b30b0112 <__device_print_strings_info_end+0xacbb0112>
    818c:	lui	a2,0x45055
    8190:	lui	a3,0x45100
    8194:	lui	a4,0xb01c0
    8198:	sw	s3,172(sp)
    819c:	addi	a2,a2,316 # 4505513c <__device_print_strings_info_end+0x3eb5513c>
    81a0:	lui	s3,0x1000
    81a4:	addi	a3,a3,56 # 45100038 <__device_print_strings_info_end+0x3ec00038>
    81a8:	addi	a4,a4,28 # b01c001c <__device_print_strings_info_end+0xa9cc001c>
    81ac:	sw	a5,24(sp)
    81b0:	li	a5,26
    81b4:	sw	s9,148(sp)
    81b8:	sw	s6,56(sp)
    81bc:	sw	s5,60(sp)
    81c0:	sw	a2,12(sp)
    81c4:	sw	a3,16(sp)
    81c8:	sw	a4,20(sp)
    81cc:	addi	s3,s3,-256 # ffff00 <.LASF2126+0xfedf20>
    81d0:	sw	a1,36(sp)
    81d4:	li	s9,0
    81d8:	sw	a5,40(sp)
    81dc:	sw	s7,48(sp)
    81e0:	sw	s8,52(sp)
    81e4:	mv	s6,t5
    81e8:	mv	s5,t4
    81ec:	lw	a5,12(sp)
    81f0:	sw	a5,0(s0)
    81f4:	lw	a1,776(s1)
    81f8:	ttstallwait	128,9
    81fc:	ttwrcfg	30,0,70
    8200:	lw	a5,16(sp)
    8204:	slli	a7,a1,0x8
    8208:	sw	a5,0(s0)
    820c:	lui	a5,0x45000
    8210:	addi	a5,a5,57 # 45000039 <__device_print_strings_info_end+0x3eb00039>
    8214:	sw	a5,0(s0)
    8218:	lw	a5,20(sp)
    821c:	and	a7,a7,s3
    8220:	sw	a5,0(s0)
    8224:	lw	a5,24(sp)
    8228:	lw	a4,8(sp)
    822c:	sw	a5,0(s0)
    8230:	addi	a5,s2,32
    8234:	sw	s10,0(s0)
    8238:	add	a7,a7,a5
    823c:	sw	a7,0(s0)
    8240:	sw	s11,0(s0)
    8244:	lui	a5,0xb61e1
    8248:	sw	a4,0(s0)
    824c:	addi	a5,a5,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    8250:	sw	a5,0(s0)
    8254:	addi	a5,s2,56
    8258:	sw	a5,0(s0)
    825c:	lui	a5,0x45002
    8260:	addi	a5,a5,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    8264:	sw	a5,0(s0)
    8268:	lui	a5,0x45020
    826c:	addi	a5,a5,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    8270:	sw	a5,0(s0)
    8274:	lui	a5,0x45080
    8278:	addi	a5,a5,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    827c:	sw	a5,0(s0)
    8280:	ttstallwait	128,1
    8284:	ttwrcfg	28,0,12
    8288:	ttwrcfg	29,0,13
    828c:	ttnop
    8290:	ttnop
    8294:	lhu	a4,794(s1)
    8298:	lw	t3,780(s1)
    829c:	lui	a3,0xffb58
    82a0:	lw	a5,32(a3) # ffb58020 <__ldm_bss_end+0x57740>
    82a4:	add	a5,t3,a5
    82a8:	sub	a5,a5,a4
    82ac:	zext.h	a5,a5
    82b0:	blt	a5,s6,82a0 <.L104>
    82b4:	ttsemwait	1,2,1
    82b8:	lw	a3,788(s1)
    82bc:	addi	t1,s2,24
    82c0:	addi	a5,a3,-1
    82c4:	slli	a0,a5,0x8
    82c8:	srli	t4,a5,0x10
    82cc:	and	a0,a0,s3
    82d0:	lui	a6,0x508c0
    82d4:	add	a0,a0,t1
    82d8:	sw	a6,0(s0)
    82dc:	slli	t4,t4,0x8
    82e0:	lui	a2,0x800
    82e4:	sw	a0,0(s0)
    82e8:	or	t5,t4,a2
    82ec:	addi	a0,s2,25
    82f0:	add	t5,t5,a0
    82f4:	sw	t5,0(s0)
    82f8:	ttstallwait	128,1
    82fc:	ttwrcfg	12,0,69
    8300:	add	t4,t4,a0
    8304:	sw	t4,0(s0)
    8308:	ttdmanop
    830c:	ttmop	1,0,0
    8310:	ttsetadczw	4,0,0,0,0,5
    8314:	li	t4,1
    8318:	beq	s5,t4,8410 <.L105>
    831c:	add	a5,a1,a5
    8320:	slli	t4,a5,0x8
    8324:	addi	t5,a6,1 # 508c0001 <__device_print_strings_info_end+0x4a3c0001>
    8328:	and	t4,t4,s3
    832c:	sw	t5,0(s0)
    8330:	add	t4,t4,t1
    8334:	sw	t4,0(s0)
    8338:	srli	t4,a5,0x10
    833c:	slli	t4,t4,0x8
    8340:	or	t5,t4,a2
    8344:	add	t5,t5,a0
    8348:	sw	t5,0(s0)
    834c:	ttstallwait	128,1
    8350:	ttwrcfg	12,0,69
    8354:	add	t4,t4,a0
    8358:	sw	t4,0(s0)
    835c:	ttdmanop
    8360:	ttmop	1,0,0
    8364:	ttsetadczw	4,0,0,0,0,5
    8368:	li	t4,2
    836c:	bgeu	t4,s5,8410 <.L105>
    8370:	add	a5,a1,a5
    8374:	slli	t4,a5,0x8
    8378:	addi	t5,a6,2
    837c:	and	t4,t4,s3
    8380:	sw	t5,0(s0)
    8384:	add	t4,t4,t1
    8388:	sw	t4,0(s0)
    838c:	srli	t4,a5,0x10
    8390:	slli	t4,t4,0x8
    8394:	or	t5,t4,a2
    8398:	add	t5,t5,a0
    839c:	sw	t5,0(s0)
    83a0:	ttstallwait	128,1
    83a4:	ttwrcfg	12,0,69
    83a8:	add	t4,t4,a0
    83ac:	sw	t4,0(s0)
    83b0:	ttdmanop
    83b4:	ttmop	1,0,0
    83b8:	ttsetadczw	4,0,0,0,0,5
    83bc:	li	t4,3
    83c0:	bgeu	t4,s5,8410 <.L105>
    83c4:	add	a5,a1,a5
    83c8:	add	a6,a6,t4
    83cc:	sw	a6,0(s0)
    83d0:	slli	a6,a5,0x8
    83d4:	srli	a5,a5,0x10
    83d8:	and	a6,a6,s3
    83dc:	slli	a5,a5,0x8
    83e0:	add	a6,a6,t1
    83e4:	or	a2,a5,a2
    83e8:	sw	a6,0(s0)
    83ec:	add	a2,a2,a0
    83f0:	sw	a2,0(s0)
    83f4:	ttstallwait	128,1
    83f8:	ttwrcfg	12,0,69
    83fc:	add	a5,a5,a0
    8400:	sw	a5,0(s0)
    8404:	ttdmanop
    8408:	ttmop	1,0,0
    840c:	ttsetadczw	4,0,0,0,0,5
    8410:	ttstallwait	64,8
    8414:	lui	a5,0x10144
    8418:	andi	t4,s9,1
    841c:	add	t4,t4,a5
    8420:	sw	t4,0(s0)
    8424:	ttsemget	2
    8428:	li	a5,1
    842c:	sub	t5,a5,s9
    8430:	lui	a0,0xb0048
    8434:	sw	t5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8438:	addi	a0,a0,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    843c:	beq	s9,a5,8448 <.L106>
    8440:	lui	a0,0xb0088
    8444:	addi	a0,a0,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    8448:	sw	a0,0(s0)
    844c:	ttdmanop
    8450:	ttdmanop
    8454:	mul	a5,s6,a1
    8458:	lw	s8,772(s1)
    845c:	add	a3,a3,a5
    8460:	sw	a5,44(sp)
    8464:	sw	zero,796(s1)
    8468:	sw	a3,788(s1)
    846c:	bltu	a3,s8,847c <.L107>
    8470:	lw	a5,768(s1)
    8474:	sub	a3,a3,a5
    8478:	sw	a3,788(s1)
    847c:	add	a5,a4,s6
    8480:	zext.h	a5,a5
    8484:	addi	a2,s2,48
    8488:	slli	a4,a5,0x8
    848c:	add	a4,a4,a2
    8490:	sw	a4,0(s0)
    8494:	sh	a5,794(s1)
    8498:	ttstallwait	32,8
    849c:	lui	a4,0x67616
    84a0:	addi	a4,a4,10 # 6761600a <__device_print_strings_info_end+0x6111600a>
    84a4:	sw	a4,0(s0)
    84a8:	lw	a4,12(sp)
    84ac:	sw	a4,0(s0)
    84b0:	lw	t6,872(s1)
    84b4:	ttstallwait	128,9
    84b8:	ttwrcfg	30,0,70
    84bc:	lw	a4,16(sp)
    84c0:	lw	a2,24(sp)
    84c4:	sw	a4,0(s0)
    84c8:	lui	a4,0x45000
    84cc:	addi	a4,a4,57 # 45000039 <__device_print_strings_info_end+0x3eb00039>
    84d0:	sw	a4,0(s0)
    84d4:	lw	a4,20(sp)
    84d8:	sw	a4,0(s0)
    84dc:	slli	a4,t6,0x8
    84e0:	sw	a2,0(s0)
    84e4:	and	a4,a4,s3
    84e8:	addi	a2,s2,32
    84ec:	sw	s10,0(s0)
    84f0:	add	a4,a4,a2
    84f4:	sw	a4,0(s0)
    84f8:	lw	a2,8(sp)
    84fc:	sw	s11,0(s0)
    8500:	lui	a4,0xb61e1
    8504:	sw	a2,0(s0)
    8508:	addi	a4,a4,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    850c:	sw	a4,0(s0)
    8510:	addi	a4,s2,56
    8514:	sw	a4,0(s0)
    8518:	lui	a4,0x45002
    851c:	addi	a4,a4,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    8520:	sw	a4,0(s0)
    8524:	lui	a4,0x45020
    8528:	addi	a4,a4,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    852c:	sw	a4,0(s0)
    8530:	lui	a4,0x45080
    8534:	addi	a4,a4,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    8538:	sw	a4,0(s0)
    853c:	ttstallwait	128,1
    8540:	ttwrcfg	28,0,12
    8544:	ttwrcfg	29,0,13
    8548:	ttnop
    854c:	ttnop
    8550:	lhu	a2,890(s1)
    8554:	lw	t1,876(s1)
    8558:	lui	a6,0xffb5b
    855c:	lw	a4,32(a6) # ffb5b020 <__ldm_bss_end+0x5a740>
    8560:	add	a4,t1,a4
    8564:	zext.h	a4,a4
    8568:	beq	a2,a4,855c <.L108>
    856c:	ttsemwait	1,2,1
    8570:	ttsetdmareg	0,0,0,56
    8574:	ttsetdmareg	0,170,0,57
    8578:	ttsetdmareg	0,1,0,60
    857c:	ttsetdmareg	1,5461,0,58
    8580:	ttsetdmareg	1,5461,0,59
    8584:	ttstallwait	128,8
    8588:	ttwrcfg	28,0,24
    858c:	ttwrcfg	30,0,25
    8590:	ttwrcfg	29,0,21
    8594:	ttnop
    8598:	ttnop
    859c:	ttsetdmareg	3,16383,0,56
    85a0:	ttsetdmareg	0,0,0,57
    85a4:	ttstallwait	128,8
    85a8:	ttwrcfg	28,0,24
    85ac:	ttwrcfg	28,0,25
    85b0:	ttwrcfg	0,0,20
    85b4:	ttwrcfg	0,0,21
    85b8:	ttnop
    85bc:	ttnop
    85c0:	lw	a6,884(s1)
    85c4:	lw	a4,892(s1)
    85c8:	lui	t1,0x508c0
    85cc:	add	a4,a6,a4
    85d0:	addi	a4,a4,-1
    85d4:	sw	t1,0(s0)
    85d8:	slli	t1,a4,0x8
    85dc:	addi	t0,s2,24
    85e0:	and	t1,t1,s3
    85e4:	add	t1,t1,t0
    85e8:	srli	a4,a4,0x10
    85ec:	sw	t1,0(s0)
    85f0:	slli	a4,a4,0x8
    85f4:	lui	t1,0x800
    85f8:	or	t1,a4,t1
    85fc:	addi	t0,s2,25
    8600:	add	t1,t1,t0
    8604:	sw	t1,0(s0)
    8608:	ttstallwait	128,1
    860c:	ttwrcfg	12,0,69
    8610:	add	a4,a4,t0
    8614:	sw	a4,0(s0)
    8618:	ttdmanop
    861c:	ttmop	1,0,0
    8620:	ttsetadczw	4,0,0,0,0,5
    8624:	ttstallwait	64,8
    8628:	lui	a4,0x10144
    862c:	andi	t1,t5,1
    8630:	add	s7,t1,a4
    8634:	sw	s7,0(s0)
    8638:	ttsemget	2
    863c:	lui	t1,0xb0048
    8640:	sw	s9,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8644:	addi	t1,t1,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    8648:	beqz	s9,8654 <.L109>
    864c:	lui	t1,0xb0088
    8650:	addi	t1,t1,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    8654:	sw	t1,0(s0)
    8658:	ttdmanop
    865c:	ttdmanop
    8660:	add	a6,t6,a6
    8664:	lw	a4,868(s1)
    8668:	sw	a6,884(s1)
    866c:	sw	zero,892(s1)
    8670:	bltu	a6,a4,8680 <.L110>
    8674:	lw	a4,864(s1)
    8678:	sub	a6,a6,a4
    867c:	sw	a6,884(s1)
    8680:	addi	a4,a2,1 # 800001 <.LASF2126+0x7ee021>
    8684:	zext.h	a4,a4
    8688:	addi	a2,s2,48
    868c:	sh	a4,890(s1)
    8690:	slli	a4,a4,0x8
    8694:	add	a4,a4,a2
    8698:	sw	a4,0(s0)
    869c:	ttstallwait	32,8
    86a0:	lui	a4,0x67617
    86a4:	addi	a4,a4,-1014 # 67616c0a <__device_print_strings_info_end+0x61116c0a>
    86a8:	sw	a4,0(s0)
    86ac:	lw	a4,12(sp)
    86b0:	sw	a4,0(s0)
    86b4:	ttstallwait	128,9
    86b8:	ttwrcfg	30,0,70
    86bc:	lw	a4,16(sp)
    86c0:	lw	a2,8(sp)
    86c4:	sw	a4,0(s0)
    86c8:	lui	a4,0x45000
    86cc:	addi	a4,a4,57 # 45000039 <__device_print_strings_info_end+0x3eb00039>
    86d0:	sw	a4,0(s0)
    86d4:	lw	a4,20(sp)
    86d8:	sw	a4,0(s0)
    86dc:	lw	a4,24(sp)
    86e0:	sw	a4,0(s0)
    86e4:	sw	s10,0(s0)
    86e8:	sw	a7,0(s0)
    86ec:	sw	s11,0(s0)
    86f0:	lui	a4,0xb61e1
    86f4:	sw	a2,0(s0)
    86f8:	addi	a4,a4,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    86fc:	sw	a4,0(s0)
    8700:	addi	a2,s2,56
    8704:	lui	a4,0x45002
    8708:	sw	a2,0(s0)
    870c:	addi	a4,a4,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    8710:	lui	a2,0x45020
    8714:	sw	a4,0(s0)
    8718:	addi	a2,a2,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    871c:	lui	a4,0x45080
    8720:	sw	a2,0(s0)
    8724:	addi	a4,a4,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    8728:	sw	a4,0(s0)
    872c:	ttstallwait	128,1
    8730:	ttwrcfg	28,0,12
    8734:	ttwrcfg	29,0,13
    8738:	ttnop
    873c:	ttnop
    8740:	ttsetdmareg	0,8,0,56
    8744:	ttsetdmareg	0,0,0,57
    8748:	ttstallwait	128,9
    874c:	ttwrcfg	28,0,2
    8750:	ttnop
    8754:	ttnop
    8758:	lui	a2,0xffb58
    875c:	lw	a4,32(a2) # ffb58020 <__ldm_bss_end+0x57740>
    8760:	add	a4,t3,a4
    8764:	sub	a4,a4,a5
    8768:	zext.h	a4,a4
    876c:	blt	a4,s6,875c <.L111>
    8770:	ttsemwait	1,2,1
    8774:	addi	a4,a3,-1
    8778:	slli	a2,a4,0x8
    877c:	and	a2,a2,s3
    8780:	addi	t6,s2,24
    8784:	lui	t3,0x508c0
    8788:	srli	a4,a4,0x10
    878c:	add	a2,a2,t6
    8790:	sw	t3,0(s0)
    8794:	slli	a4,a4,0x8
    8798:	lui	a7,0x800
    879c:	sw	a2,0(s0)
    87a0:	addi	a6,s2,25
    87a4:	or	a2,a4,a7
    87a8:	add	a2,a2,a6
    87ac:	sw	a2,0(s0)
    87b0:	ttstallwait	128,1
    87b4:	ttwrcfg	12,0,69
    87b8:	add	a4,a4,a6
    87bc:	sw	a4,0(s0)
    87c0:	ttdmanop
    87c4:	ttmop	1,0,0
    87c8:	ttsetadczw	4,0,0,0,0,5
    87cc:	li	a4,1
    87d0:	beq	s5,a4,88d8 <.L112>
    87d4:	addi	a4,a1,-1
    87d8:	add	a2,a4,a3
    87dc:	slli	t0,a2,0x8
    87e0:	srli	a2,a2,0x10
    87e4:	addi	t2,t3,1 # 508c0001 <__device_print_strings_info_end+0x4a3c0001>
    87e8:	and	t0,t0,s3
    87ec:	slli	a2,a2,0x8
    87f0:	sw	t2,0(s0)
    87f4:	add	t0,t0,t6
    87f8:	or	t2,a2,a7
    87fc:	sw	t0,0(s0)
    8800:	add	t2,t2,a6
    8804:	sw	t2,0(s0)
    8808:	ttstallwait	128,1
    880c:	ttwrcfg	12,0,69
    8810:	add	a2,a2,a6
    8814:	sw	a2,0(s0)
    8818:	ttdmanop
    881c:	ttmop	1,0,0
    8820:	ttsetadczw	4,0,0,0,0,5
    8824:	li	a2,2
    8828:	bgeu	a2,s5,88d8 <.L112>
    882c:	slli	a1,a1,0x1
    8830:	addi	a2,a1,-1
    8834:	add	a2,a2,a3
    8838:	slli	t0,a2,0x8
    883c:	srli	a2,a2,0x10
    8840:	addi	t2,t3,2
    8844:	and	t0,t0,s3
    8848:	slli	a2,a2,0x8
    884c:	sw	t2,0(s0)
    8850:	add	t0,t0,t6
    8854:	or	t2,a2,a7
    8858:	sw	t0,0(s0)
    885c:	add	t2,t2,a6
    8860:	sw	t2,0(s0)
    8864:	ttstallwait	128,1
    8868:	ttwrcfg	12,0,69
    886c:	add	a2,a2,a6
    8870:	sw	a2,0(s0)
    8874:	ttdmanop
    8878:	ttmop	1,0,0
    887c:	ttsetadczw	4,0,0,0,0,5
    8880:	li	a2,3
    8884:	bgeu	a2,s5,88d8 <.L112>
    8888:	add	a4,a4,a1
    888c:	add	a4,a4,a3
    8890:	slli	a2,a4,0x8
    8894:	srli	a4,a4,0x10
    8898:	addi	t3,t3,3
    889c:	and	a2,a2,s3
    88a0:	slli	a4,a4,0x8
    88a4:	sw	t3,0(s0)
    88a8:	add	a2,a2,t6
    88ac:	or	a7,a4,a7
    88b0:	sw	a2,0(s0)
    88b4:	add	a2,a7,a6
    88b8:	sw	a2,0(s0)
    88bc:	ttstallwait	128,1
    88c0:	ttwrcfg	12,0,69
    88c4:	add	a4,a4,a6
    88c8:	sw	a4,0(s0)
    88cc:	ttdmanop
    88d0:	ttmop	1,0,0
    88d4:	ttsetadczw	4,0,0,0,0,5
    88d8:	lw	a4,44(sp)
    88dc:	add	a4,a4,a3
    88e0:	sw	a4,788(s1)
    88e4:	bltu	a4,s8,88f4 <.L113>
    88e8:	lw	a3,768(s1)
    88ec:	sub	a4,a4,a3
    88f0:	sw	a4,788(s1)
    88f4:	add	a5,a5,s6
    88f8:	zext.h	a5,a5
    88fc:	addi	a3,s2,48
    8900:	slli	a4,a5,0x8
    8904:	add	a4,a4,a3
    8908:	sh	a5,794(s1)
    890c:	sw	a4,0(s0)
    8910:	ttstallwait	32,8
    8914:	lui	a5,0x67616
    8918:	addi	a5,a5,10 # 6761600a <__device_print_strings_info_end+0x6111600a>
    891c:	sw	a5,0(s0)
    8920:	ttstallwait	64,8
    8924:	sw	t4,0(s0)
    8928:	ttsemget	2
    892c:	sw	t5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8930:	sw	a0,0(s0)
    8934:	ttdmanop
    8938:	ttdmanop
    893c:	ttsetdmareg	0,0,0,56
    8940:	ttsetdmareg	0,0,0,57
    8944:	ttstallwait	128,9
    8948:	ttwrcfg	28,0,2
    894c:	ttnop
    8950:	ttnop
    8954:	lw	a5,12(sp)
    8958:	sw	a5,0(s0)
    895c:	lw	a3,936(s1)
    8960:	ttstallwait	128,9
    8964:	ttwrcfg	30,0,70
    8968:	lw	a5,16(sp)
    896c:	lw	a4,24(sp)
    8970:	sw	a5,0(s0)
    8974:	lui	a5,0x45000
    8978:	addi	a5,a5,57 # 45000039 <__device_print_strings_info_end+0x3eb00039>
    897c:	sw	a5,0(s0)
    8980:	lw	a5,20(sp)
    8984:	sw	a5,0(s0)
    8988:	slli	a5,a3,0x8
    898c:	sw	a4,0(s0)
    8990:	and	a5,a5,s3
    8994:	addi	a4,s2,32
    8998:	sw	s10,0(s0)
    899c:	add	a5,a5,a4
    89a0:	sw	a5,0(s0)
    89a4:	lw	a4,8(sp)
    89a8:	sw	s11,0(s0)
    89ac:	lui	a5,0xb61e1
    89b0:	sw	a4,0(s0)
    89b4:	addi	a5,a5,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    89b8:	sw	a5,0(s0)
    89bc:	addi	a5,s2,56
    89c0:	sw	a5,0(s0)
    89c4:	lui	a5,0x45002
    89c8:	addi	a5,a5,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    89cc:	sw	a5,0(s0)
    89d0:	lui	a5,0x45020
    89d4:	addi	a5,a5,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    89d8:	sw	a5,0(s0)
    89dc:	lui	a5,0x45080
    89e0:	addi	a5,a5,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    89e4:	sw	a5,0(s0)
    89e8:	ttstallwait	128,1
    89ec:	ttwrcfg	28,0,12
    89f0:	ttwrcfg	29,0,13
    89f4:	ttnop
    89f8:	ttnop
    89fc:	lhu	a2,954(s1)
    8a00:	lw	a1,940(s1)
    8a04:	lui	a4,0xffb5d
    8a08:	lw	a5,32(a4) # ffb5d020 <__ldm_bss_end+0x5c740>
    8a0c:	add	a5,a1,a5
    8a10:	zext.h	a5,a5
    8a14:	beq	a2,a5,8a08 <.L114>
    8a18:	ttsemwait	1,2,1
    8a1c:	ttsetdmareg	0,0,0,56
    8a20:	ttsetdmareg	0,170,0,57
    8a24:	ttsetdmareg	0,1,0,60
    8a28:	ttsetdmareg	1,5461,0,58
    8a2c:	ttsetdmareg	1,5461,0,59
    8a30:	ttstallwait	128,8
    8a34:	ttwrcfg	28,0,24
    8a38:	ttwrcfg	30,0,25
    8a3c:	ttwrcfg	29,0,21
    8a40:	ttnop
    8a44:	ttnop
    8a48:	ttsetdmareg	3,16383,0,56
    8a4c:	ttsetdmareg	0,0,0,57
    8a50:	ttstallwait	128,8
    8a54:	ttwrcfg	28,0,24
    8a58:	ttwrcfg	28,0,25
    8a5c:	ttwrcfg	0,0,20
    8a60:	ttwrcfg	0,0,21
    8a64:	ttnop
    8a68:	ttnop
    8a6c:	lw	a1,948(s1)
    8a70:	lw	a4,956(s1)
    8a74:	lui	a5,0x508c0
    8a78:	add	a4,a1,a4
    8a7c:	addi	a4,a4,-1
    8a80:	slli	a6,a4,0x8
    8a84:	srli	a4,a4,0x10
    8a88:	sw	a5,0(s0)
    8a8c:	and	a6,a6,s3
    8a90:	slli	a5,a4,0x8
    8a94:	addi	a4,s2,24
    8a98:	add	a4,a6,a4
    8a9c:	sw	a4,0(s0)
    8aa0:	lui	a4,0x800
    8aa4:	or	a4,a5,a4
    8aa8:	addi	a6,s2,25
    8aac:	add	a4,a4,a6
    8ab0:	sw	a4,0(s0)
    8ab4:	ttstallwait	128,1
    8ab8:	ttwrcfg	12,0,69
    8abc:	add	a5,a5,a6
    8ac0:	sw	a5,0(s0)
    8ac4:	ttdmanop
    8ac8:	ttmop	1,0,0
    8acc:	ttsetadczw	4,0,0,0,0,5
    8ad0:	ttstallwait	64,8
    8ad4:	sw	s7,0(s0)
    8ad8:	ttsemget	2
    8adc:	sw	s9,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8ae0:	sw	t1,0(s0)
    8ae4:	ttdmanop
    8ae8:	ttdmanop
    8aec:	add	a5,a3,a1
    8af0:	lw	a4,932(s1)
    8af4:	sw	a5,948(s1)
    8af8:	sw	zero,956(s1)
    8afc:	bltu	a5,a4,8b0c <.L115>
    8b00:	lw	a4,928(s1)
    8b04:	sub	a5,a5,a4
    8b08:	sw	a5,948(s1)
    8b0c:	addi	a5,a2,1
    8b10:	zext.h	a5,a5
    8b14:	addi	a3,s2,48
    8b18:	slli	a4,a5,0x8
    8b1c:	add	a4,a4,a3
    8b20:	sh	a5,954(s1)
    8b24:	sw	a4,0(s0)
    8b28:	ttstallwait	32,8
    8b2c:	lui	a5,0x67617
    8b30:	addi	a5,a5,1034 # 6761740a <__device_print_strings_info_end+0x6111740a>
    8b34:	sw	a5,0(s0)
    8b38:	lw	a5,12(sp)
    8b3c:	sw	a5,0(s0)
    8b40:	lw	a5,808(s1)
    8b44:	ttstallwait	128,9
    8b48:	ttwrcfg	30,0,70
    8b4c:	lw	a4,16(sp)
    8b50:	slli	a5,a5,0x8
    8b54:	sw	a4,0(s0)
    8b58:	lui	a4,0x45000
    8b5c:	addi	a4,a4,57 # 45000039 <__device_print_strings_info_end+0x3eb00039>
    8b60:	sw	a4,0(s0)
    8b64:	lw	a4,20(sp)
    8b68:	and	a5,a5,s3
    8b6c:	sw	a4,0(s0)
    8b70:	lw	a4,24(sp)
    8b74:	sw	a4,0(s0)
    8b78:	addi	a4,s2,32
    8b7c:	sw	s10,0(s0)
    8b80:	add	a5,a5,a4
    8b84:	sw	a5,0(s0)
    8b88:	lw	a4,8(sp)
    8b8c:	sw	s11,0(s0)
    8b90:	lui	a5,0xb61e1
    8b94:	sw	a4,0(s0)
    8b98:	addi	a5,a5,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    8b9c:	sw	a5,0(s0)
    8ba0:	addi	a5,s2,56
    8ba4:	sw	a5,0(s0)
    8ba8:	lui	a5,0x45002
    8bac:	addi	a5,a5,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    8bb0:	sw	a5,0(s0)
    8bb4:	lui	a5,0x45020
    8bb8:	addi	a5,a5,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    8bbc:	sw	a5,0(s0)
    8bc0:	lui	a5,0x45080
    8bc4:	addi	a5,a5,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    8bc8:	sw	a5,0(s0)
    8bcc:	ttstallwait	128,1
    8bd0:	ttwrcfg	28,0,12
    8bd4:	ttwrcfg	29,0,13
    8bd8:	ttnop
    8bdc:	ttnop
    8be0:	lw	a4,40(sp)
    8be4:	li	a1,3
    8be8:	slli	t6,a4,0x5
    8bec:	add	a5,s1,t6
    8bf0:	lhu	a7,26(a5)
    8bf4:	lw	a2,12(a5)
    8bf8:	lui	a5,0xffb40
    8bfc:	slli	a3,a4,0xc
    8c00:	addi	a5,a5,32 # ffb40020 <__ldm_bss_end+0x3f740>
    8c04:	sub	a2,a2,a7
    8c08:	add	a5,a3,a5
    8c0c:	lw	a4,0(a5)
    8c10:	add	a4,a2,a4
    8c14:	zext.h	a4,a4
    8c18:	bgeu	a1,a4,8c0c <.L116>
    8c1c:	ttsemwait	1,2,1
    8c20:	add	t1,s1,t6
    8c24:	lw	t2,20(t1)
    8c28:	addi	t0,s2,24
    8c2c:	addi	a5,t2,-1
    8c30:	slli	a1,a5,0x8
    8c34:	srli	a2,a5,0x10
    8c38:	and	a1,a1,s3
    8c3c:	lui	t3,0x508c0
    8c40:	lw	a4,8(t1)
    8c44:	add	a1,a1,t0
    8c48:	sw	t3,0(s0)
    8c4c:	slli	a2,a2,0x8
    8c50:	lui	a6,0x800
    8c54:	sw	a1,0(s0)
    8c58:	or	s9,a2,a6
    8c5c:	addi	a1,s2,25
    8c60:	add	s9,s9,a1
    8c64:	sw	s9,0(s0)
    8c68:	ttstallwait	128,1
    8c6c:	ttwrcfg	12,0,69
    8c70:	add	a2,a2,a1
    8c74:	sw	a2,0(s0)
    8c78:	ttdmanop
    8c7c:	ttmop	1,0,0
    8c80:	ttsetadczw	4,0,0,0,0,5
    8c84:	add	t2,t2,a4
    8c88:	addi	a2,t2,-1
    8c8c:	addi	s9,t3,1 # 508c0001 <__device_print_strings_info_end+0x4a3c0001>
    8c90:	sw	s9,0(s0)
    8c94:	slli	s9,a2,0x8
    8c98:	and	s9,s9,s3
    8c9c:	srli	a2,a2,0x10
    8ca0:	add	s9,s9,t0
    8ca4:	slli	a2,a2,0x8
    8ca8:	sw	s9,0(s0)
    8cac:	or	s9,a2,a6
    8cb0:	add	s9,s9,a1
    8cb4:	sw	s9,0(s0)
    8cb8:	ttstallwait	128,1
    8cbc:	ttwrcfg	12,0,69
    8cc0:	add	a2,a2,a1
    8cc4:	sw	a2,0(s0)
    8cc8:	ttdmanop
    8ccc:	ttmop	1,0,0
    8cd0:	ttsetadczw	4,0,0,0,0,5
    8cd4:	addi	a2,t3,2
    8cd8:	sh1add	a5,a4,a5
    8cdc:	slli	s9,a5,0x8
    8ce0:	sw	a2,0(s0)
    8ce4:	and	s9,s9,s3
    8ce8:	srli	a2,a5,0x10
    8cec:	add	s9,s9,t0
    8cf0:	slli	a2,a2,0x8
    8cf4:	sw	s9,0(s0)
    8cf8:	or	s9,a2,a6
    8cfc:	add	s9,s9,a1
    8d00:	sw	s9,0(s0)
    8d04:	ttstallwait	128,1
    8d08:	ttwrcfg	12,0,69
    8d0c:	add	a2,a2,a1
    8d10:	sw	a2,0(s0)
    8d14:	ttdmanop
    8d18:	ttmop	1,0,0
    8d1c:	ttsetadczw	4,0,0,0,0,5
    8d20:	add	a5,a4,a5
    8d24:	slli	a2,a5,0x8
    8d28:	srli	a5,a5,0x10
    8d2c:	addi	t3,t3,3
    8d30:	and	a2,a2,s3
    8d34:	slli	a5,a5,0x8
    8d38:	sw	t3,0(s0)
    8d3c:	add	a2,a2,t0
    8d40:	or	a6,a5,a6
    8d44:	sw	a2,0(s0)
    8d48:	add	a2,a6,a1
    8d4c:	sw	a2,0(s0)
    8d50:	ttstallwait	128,1
    8d54:	ttwrcfg	12,0,69
    8d58:	add	a5,a5,a1
    8d5c:	sw	a5,0(s0)
    8d60:	ttdmanop
    8d64:	ttmop	1,0,0
    8d68:	ttsetadczw	4,0,0,0,0,5
    8d6c:	ttstallwait	64,8
    8d70:	sw	t4,0(s0)
    8d74:	ttsemget	2
    8d78:	sw	t5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8d7c:	sw	a0,0(s0)
    8d80:	ttdmanop
    8d84:	ttdmanop
    8d88:	sh1add	a4,a4,a4
    8d8c:	lw	a2,4(t1)
    8d90:	add	a5,a4,t2
    8d94:	sw	a5,20(t1)
    8d98:	sw	zero,28(t1)
    8d9c:	bltu	a5,a2,8dac <.L117>
    8da0:	lw	a4,0(t1)
    8da4:	sub	a5,a5,a4
    8da8:	sw	a5,20(t1)
    8dac:	addi	a5,a7,4 # 800004 <.LASF2126+0x7ee024>
    8db0:	zext.h	a5,a5
    8db4:	add	t6,s1,t6
    8db8:	slli	a4,a5,0x8
    8dbc:	addi	a2,s2,48
    8dc0:	sh	a5,26(t6)
    8dc4:	add	a5,a4,a2
    8dc8:	sw	a5,0(s0)
    8dcc:	ttstallwait	32,8
    8dd0:	lui	a4,0x3fed0
    8dd4:	srli	a5,a3,0x2
    8dd8:	addi	a3,a4,10 # 3fed000a <__device_print_strings_info_end+0x399d000a>
    8ddc:	lui	a4,0x40
    8de0:	addi	a4,a4,-1 # 3ffff <.LASF2126+0x2e01f>
    8de4:	add	a5,a5,a3
    8de8:	and	a5,a5,a4
    8dec:	lui	a4,0x67600
    8df0:	add	a5,a5,a4
    8df4:	sw	a5,0(s0)
    8df8:	lw	a4,36(sp)
    8dfc:	lw	a5,32(sp)
    8e00:	beq	a5,a4,9228 <.L164>
    8e04:	li	a0,31
    8e08:	jal	9ac8 <_Z29llk_pack_reconfig_data_formatILb1ELb0EEvm>
    8e0c:	lhu	a2,1018(s1)
    8e10:	lw	a3,1004(s1)
    8e14:	lui	a4,0xffb5f
    8e18:	lw	a5,32(a4) # ffb5f020 <__ldm_bss_end+0x5e740>
    8e1c:	add	a5,a3,a5
    8e20:	zext.h	a5,a5
    8e24:	beq	a5,a2,8e18 <.L119>
    8e28:	fence
    8e2c:	ttsemwait	1,2,1
    8e30:	lw	a4,1012(s1)
    8e34:	lw	a5,1020(s1)
    8e38:	lui	a3,0x508c0
    8e3c:	add	a5,a4,a5
    8e40:	addi	a5,a5,-1
    8e44:	slli	a2,a5,0x8
    8e48:	srli	a5,a5,0x10
    8e4c:	sw	a3,0(s0)
    8e50:	addi	a1,s2,24
    8e54:	and	a2,a2,s3
    8e58:	slli	a5,a5,0x8
    8e5c:	lui	a3,0x800
    8e60:	add	a2,a2,a1
    8e64:	or	a3,a5,a3
    8e68:	addi	a1,s2,25
    8e6c:	sw	a2,0(s0)
    8e70:	add	a3,a3,a1
    8e74:	sw	a3,0(s0)
    8e78:	lw	a3,1000(s1)
    8e7c:	ttstallwait	128,1
    8e80:	ttwrcfg	12,0,69
    8e84:	add	a5,a5,a1
    8e88:	sw	a5,0(s0)
    8e8c:	ttdmanop
    8e90:	ttmop	1,0,0
    8e94:	ttsetadczw	4,0,0,0,0,5
    8e98:	add	a5,a4,a3
    8e9c:	lw	a4,996(s1)
    8ea0:	sw	a5,1012(s1)
    8ea4:	sw	zero,1020(s1)
    8ea8:	bltu	a5,a4,8eb8 <.L120>
    8eac:	lw	a4,992(s1)
    8eb0:	sub	a5,a5,a4
    8eb4:	sw	a5,1012(s1)
    8eb8:	lhu	a5,1018(s1)
    8ebc:	addi	a3,s2,48
    8ec0:	addi	a5,a5,1
    8ec4:	zext.h	a5,a5
    8ec8:	slli	a4,a5,0x8
    8ecc:	add	a4,a4,a3
    8ed0:	sh	a5,1018(s1)
    8ed4:	sw	a4,0(s0)
    8ed8:	ttstallwait	32,8
    8edc:	lui	a5,0x67618
    8ee0:	addi	a5,a5,-1014 # 67617c0a <__device_print_strings_info_end+0x61117c0a>
    8ee4:	sw	a5,0(s0)
    8ee8:	ttstallwait	64,8
    8eec:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8ef0:	lui	a3,0x10144
    8ef4:	andi	a5,a4,1
    8ef8:	add	a5,a5,a3
    8efc:	sw	a5,0(s0)
    8f00:	ttsemget	2
    8f04:	li	a3,1
    8f08:	sub	a5,a3,a4
    8f0c:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8f10:	lui	a5,0xb0048
    8f14:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    8f18:	beq	a4,a3,8f24 <.L121>
    8f1c:	lui	a5,0xb0088
    8f20:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    8f24:	sw	a5,0(s0)
    8f28:	ttdmanop
    8f2c:	ttdmanop
    8f30:	fence
    8f34:	ttsemwait	1,2,1
    8f38:	lhu	a3,986(s1)
    8f3c:	lw	a2,972(s1)
    8f40:	lui	a4,0xffb5e
    8f44:	lw	a5,32(a4) # ffb5e020 <__ldm_bss_end+0x5d740>
    8f48:	add	a5,a2,a5
    8f4c:	zext.h	a5,a5
    8f50:	beq	a5,a3,8f44 <.L122>
    8f54:	lw	a4,980(s1)
    8f58:	lw	a5,988(s1)
    8f5c:	addi	a6,s2,24
    8f60:	add	a5,a4,a5
    8f64:	addi	a5,a5,-1
    8f68:	slli	a1,a5,0x8
    8f6c:	srli	a5,a5,0x10
    8f70:	and	a1,a1,s3
    8f74:	slli	a5,a5,0x8
    8f78:	lui	a0,0x508c0
    8f7c:	lui	a2,0x800
    8f80:	sw	a0,0(s0)
    8f84:	add	a1,a1,a6
    8f88:	or	a2,a5,a2
    8f8c:	addi	a0,s2,25
    8f90:	sw	a1,0(s0)
    8f94:	add	a2,a2,a0
    8f98:	sw	a2,0(s0)
    8f9c:	lw	a2,968(s1)
    8fa0:	ttstallwait	128,1
    8fa4:	ttwrcfg	12,0,69
    8fa8:	add	a5,a5,a0
    8fac:	sw	a5,0(s0)
    8fb0:	ttdmanop
    8fb4:	ttmop	1,0,0
    8fb8:	ttsetadczw	4,0,0,0,0,5
    8fbc:	add	a5,a4,a2
    8fc0:	lw	a4,964(s1)
    8fc4:	sw	a5,980(s1)
    8fc8:	sw	zero,988(s1)
    8fcc:	bltu	a5,a4,8fdc <.L123>
    8fd0:	lw	a4,960(s1)
    8fd4:	sub	a5,a5,a4
    8fd8:	sw	a5,980(s1)
    8fdc:	addi	a5,a3,1 # 10144001 <__device_print_strings_info_end+0x9c44001>
    8fe0:	zext.h	a5,a5
    8fe4:	addi	a3,s2,48
    8fe8:	slli	a4,a5,0x8
    8fec:	add	a4,a4,a3
    8ff0:	sh	a5,986(s1)
    8ff4:	sw	a4,0(s0)
    8ff8:	ttstallwait	32,8
    8ffc:	lui	a5,0x67618
    9000:	addi	a5,a5,-2038 # 6761780a <__device_print_strings_info_end+0x6111780a>
    9004:	sw	a5,0(s0)
    9008:	ttstallwait	64,8
    900c:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9010:	lui	a3,0x10144
    9014:	andi	a5,a4,1
    9018:	add	a5,a5,a3
    901c:	sw	a5,0(s0)
    9020:	ttsemget	2
    9024:	li	a3,1
    9028:	sub	a5,a3,a4
    902c:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9030:	lui	a5,0xb0048
    9034:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    9038:	beq	a4,a3,9044 <.L124>
    903c:	lui	a5,0xb0088
    9040:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    9044:	sw	a5,0(s0)
    9048:	ttdmanop
    904c:	ttdmanop
    9050:	li	a0,26
    9054:	jal	9ac8 <_Z29llk_pack_reconfig_data_formatILb1ELb0EEvm>
    9058:	lw	s9,840(s1)
    905c:	lhu	a3,858(s1)
    9060:	lui	a6,0x67617
    9064:	lw	a7,844(s1)
    9068:	lw	t2,836(s1)
    906c:	lw	t0,832(s1)
    9070:	lw	a4,860(s1)
    9074:	lw	a1,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9078:	lw	a2,852(s1)
    907c:	addi	t1,a3,4 # 10144004 <__device_print_strings_info_end+0x9c44004>
    9080:	addi	t6,s2,24
    9084:	zext.h	t1,t1
    9088:	addi	t4,s2,25
    908c:	addi	t5,s2,48
    9090:	addi	a6,a6,-2038 # 6761680a <__device_print_strings_info_end+0x6111680a>
    9094:	lui	a0,0xffb5a
    9098:	li	t3,1
    909c:	ttsemwait	1,2,1
    90a0:	lw	a5,32(a0) # ffb5a020 <__ldm_bss_end+0x59740>
    90a4:	add	a5,a7,a5
    90a8:	zext.h	a5,a5
    90ac:	beq	a3,a5,90a0 <.L125>
    90b0:	add	a5,a2,a4
    90b4:	addi	a5,a5,-1
    90b8:	slli	a4,a5,0x8
    90bc:	and	a4,a4,s3
    90c0:	lui	s7,0x508c0
    90c4:	sw	s7,0(s0)
    90c8:	add	a4,a4,t6
    90cc:	srli	a5,a5,0x10
    90d0:	sw	a4,0(s0)
    90d4:	slli	a5,a5,0x8
    90d8:	lui	a4,0x800
    90dc:	or	a4,a5,a4
    90e0:	add	a4,a4,t4
    90e4:	sw	a4,0(s0)
    90e8:	ttstallwait	128,1
    90ec:	ttwrcfg	12,0,69
    90f0:	add	a5,a5,t4
    90f4:	sw	a5,0(s0)
    90f8:	ttdmanop
    90fc:	ttmop	1,0,0
    9100:	ttsetadczw	4,0,0,0,0,5
    9104:	add	a2,a2,s9
    9108:	sw	a2,852(s1)
    910c:	sw	zero,860(s1)
    9110:	bltu	a2,t2,911c <.L130>
    9114:	sub	a2,a2,t0
    9118:	sw	a2,852(s1)
    911c:	addi	a3,a3,1
    9120:	zext.h	a3,a3
    9124:	slli	a5,a3,0x8
    9128:	add	a5,a5,t5
    912c:	sw	a5,0(s0)
    9130:	sh	a3,858(s1)
    9134:	ttstallwait	32,8
    9138:	sw	a6,0(s0)
    913c:	ttstallwait	64,8
    9140:	lui	a4,0x10144
    9144:	andi	a5,a1,1
    9148:	add	a5,a5,a4
    914c:	sw	a5,0(s0)
    9150:	ttsemget	2
    9154:	sub	s7,t3,a1
    9158:	lui	a5,0xb0048
    915c:	sw	s7,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9160:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    9164:	beq	a1,t3,9170 <.L127>
    9168:	lui	a5,0xb0088
    916c:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    9170:	sw	a5,0(s0)
    9174:	ttdmanop
    9178:	ttdmanop
    917c:	li	a4,0
    9180:	beq	a3,t1,92fc <.L211>
    9184:	mv	a1,s7
    9188:	j	909c <.L128>
    918c:	lw	s7,48(sp)
    9190:	lw	s8,52(sp)
    9194:	lw	s6,56(sp)
    9198:	lw	s5,60(sp)
    919c:	lw	s3,172(sp)
    91a0:	lw	s9,148(sp)
    91a4:	bnez	s5,969c <.L135>
    91a8:	li	a5,1
    91ac:	beq	s7,a5,951c <.L212>
    91b0:	li	a5,-1
    91b4:	bne	s8,a5,94ec <.L213>
    91b8:	lw	s4,168(sp)
    91bc:	lw	s5,164(sp)
    91c0:	lw	s6,160(sp)
    91c4:	lw	s10,144(sp)
    91c8:	lw	s11,140(sp)
    91cc:	lw	ra,188(sp)
    91d0:	lw	s0,184(sp)
    91d4:	lw	s1,180(sp)
    91d8:	lw	s2,176(sp)
    91dc:	lw	s7,156(sp)
    91e0:	lw	s8,152(sp)
    91e4:	li	a0,0
    91e8:	addi	sp,sp,192
    91ec:	ret
    91f0:	sub	a4,a4,s1
    91f4:	srli	a2,a5,0x4
    91f8:	mul	a0,a2,a4
    91fc:	andi	a3,a5,15
    9200:	min	a1,a3,a4
    9204:	add	a1,a0,a1
    9208:	add	a2,a2,a1
    920c:	sw	a1,32(sp)
    9210:	sw	a2,28(sp)
    9214:	blt	a4,a3,921c <.LM2544>
    9218:	j	7ec8 <.L93>
    921c:	addi	a4,a2,1 # 800001 <.LASF2126+0x7ee021>
    9220:	sw	a4,28(sp)
    9224:	j	7ebc <.L92>
    9228:	li	a5,25
    922c:	sw	a5,40(sp)
    9230:	lw	a5,12(sp)
    9234:	sw	a5,0(s0)
    9238:	lw	a5,904(s1)
    923c:	ttstallwait	128,9
    9240:	ttwrcfg	30,0,70
    9244:	lw	a4,16(sp)
    9248:	slli	a5,a5,0x8
    924c:	sw	a4,0(s0)
    9250:	lui	a4,0x45000
    9254:	addi	a4,a4,57 # 45000039 <__device_print_strings_info_end+0x3eb00039>
    9258:	sw	a4,0(s0)
    925c:	lw	a4,20(sp)
    9260:	and	a5,a5,s3
    9264:	sw	a4,0(s0)
    9268:	lw	a4,24(sp)
    926c:	sw	a4,0(s0)
    9270:	addi	a4,s2,32
    9274:	sw	s10,0(s0)
    9278:	add	a5,a5,a4
    927c:	sw	a5,0(s0)
    9280:	lw	a4,8(sp)
    9284:	sw	s11,0(s0)
    9288:	lui	a5,0xb61e1
    928c:	sw	a4,0(s0)
    9290:	addi	a5,a5,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    9294:	sw	a5,0(s0)
    9298:	addi	a4,s2,56
    929c:	lui	a5,0x45002
    92a0:	sw	a4,0(s0)
    92a4:	addi	a5,a5,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    92a8:	lui	a4,0x45020
    92ac:	sw	a5,0(s0)
    92b0:	addi	a4,a4,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    92b4:	lui	a5,0x45080
    92b8:	sw	a4,0(s0)
    92bc:	addi	a5,a5,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    92c0:	sw	a5,0(s0)
    92c4:	ttstallwait	128,1
    92c8:	ttwrcfg	28,0,12
    92cc:	ttwrcfg	29,0,13
    92d0:	ttnop
    92d4:	ttnop
    92d8:	jal	a3f0 <_Z10move_blockILb1EEvmmm.constprop.1>
    92dc:	jal	a530 <_Z10move_blockILb1EEvmmm.constprop.0>
    92e0:	lw	a5,36(sp)
    92e4:	lw	a4,28(sp)
    92e8:	addi	a5,a5,1
    92ec:	sw	a5,36(sp)
    92f0:	bgeu	a5,a4,918c <.L202>
    92f4:	lw	s9,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    92f8:	j	81ec <.L134>
    92fc:	li	a0,29
    9300:	jal	9ac8 <_Z29llk_pack_reconfig_data_formatILb1ELb0EEvm>
    9304:	ttsemwait	1,2,1
    9308:	lw	a0,956(s1)
    930c:	lw	a1,948(s1)
    9310:	lui	a5,0x508c0
    9314:	sw	a5,0(s0)
    9318:	add	a5,a1,a0
    931c:	addi	a5,a5,-1 # 508bffff <__device_print_strings_info_end+0x4a3bffff>
    9320:	slli	a2,a5,0x8
    9324:	lw	a4,936(s1)
    9328:	addi	a6,s2,24
    932c:	and	a2,a2,s3
    9330:	srli	a5,a5,0x10
    9334:	add	a2,a2,a6
    9338:	slli	a5,a5,0x8
    933c:	lui	a3,0x800
    9340:	sw	a2,0(s0)
    9344:	or	a3,a5,a3
    9348:	addi	a6,s2,25
    934c:	add	a0,a4,a0
    9350:	add	a3,a3,a6
    9354:	sw	a0,956(s1)
    9358:	sw	a3,0(s0)
    935c:	ttstallwait	128,1
    9360:	ttwrcfg	12,0,69
    9364:	add	a5,a5,a6
    9368:	sw	a5,0(s0)
    936c:	ttdmanop
    9370:	ttmop	1,0,0
    9374:	ttsetadczw	4,0,0,0,0,5
    9378:	ttstallwait	64,8
    937c:	lw	a3,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9380:	lui	a2,0x10144
    9384:	andi	a5,a3,1
    9388:	add	a5,a5,a2
    938c:	sw	a5,0(s0)
    9390:	ttsemget	2
    9394:	li	a2,1
    9398:	sub	a5,a2,a3
    939c:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    93a0:	lui	a5,0xb0048
    93a4:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    93a8:	beq	a3,a2,93b4 <.L131>
    93ac:	lui	a5,0xb0088
    93b0:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    93b4:	sw	a5,0(s0)
    93b8:	ttdmanop
    93bc:	ttdmanop
    93c0:	lhu	a3,954(s1)
    93c4:	lw	a0,940(s1)
    93c8:	lui	a2,0xffb5d
    93cc:	lw	a5,32(a2) # ffb5d020 <__ldm_bss_end+0x5c740>
    93d0:	add	a5,a0,a5
    93d4:	zext.h	a5,a5
    93d8:	beq	a3,a5,93cc <.L132>
    93dc:	add	a5,a4,a1
    93e0:	lw	a4,932(s1)
    93e4:	sw	a5,948(s1)
    93e8:	sw	zero,956(s1)
    93ec:	bltu	a5,a4,93fc <.L133>
    93f0:	lw	a4,928(s1)
    93f4:	sub	a5,a5,a4
    93f8:	sw	a5,948(s1)
    93fc:	addi	a5,a3,1 # 800001 <.LASF2126+0x7ee021>
    9400:	zext.h	a5,a5
    9404:	addi	a3,s2,48
    9408:	slli	a4,a5,0x8
    940c:	add	a4,a4,a3
    9410:	sh	a5,954(s1)
    9414:	sw	a4,0(s0)
    9418:	ttstallwait	32,8
    941c:	lui	a5,0x67617
    9420:	addi	a5,a5,1034 # 6761740a <__device_print_strings_info_end+0x6111740a>
    9424:	sw	a5,0(s0)
    9428:	lw	a5,12(sp)
    942c:	sw	a5,0(s0)
    9430:	lw	a5,840(s1)
    9434:	ttstallwait	128,9
    9438:	ttwrcfg	30,0,70
    943c:	lw	a4,16(sp)
    9440:	slli	a5,a5,0x8
    9444:	sw	a4,0(s0)
    9448:	lui	a4,0x45000
    944c:	addi	a4,a4,57 # 45000039 <__device_print_strings_info_end+0x3eb00039>
    9450:	sw	a4,0(s0)
    9454:	lw	a4,20(sp)
    9458:	and	a5,a5,s3
    945c:	sw	a4,0(s0)
    9460:	lw	a4,24(sp)
    9464:	sw	a4,0(s0)
    9468:	addi	a4,s2,32
    946c:	sw	s10,0(s0)
    9470:	add	a5,a5,a4
    9474:	sw	a5,0(s0)
    9478:	lw	a4,8(sp)
    947c:	sw	s11,0(s0)
    9480:	lui	a5,0xb61e1
    9484:	sw	a4,0(s0)
    9488:	addi	a5,a5,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    948c:	sw	a5,0(s0)
    9490:	addi	a4,s2,56
    9494:	lui	a5,0x45002
    9498:	sw	a4,0(s0)
    949c:	addi	a5,a5,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    94a0:	lui	a4,0x45020
    94a4:	sw	a5,0(s0)
    94a8:	addi	a4,a4,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    94ac:	lui	a5,0x45080
    94b0:	sw	a4,0(s0)
    94b4:	addi	a5,a5,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    94b8:	sw	a5,0(s0)
    94bc:	ttstallwait	128,1
    94c0:	ttwrcfg	28,0,12
    94c4:	ttwrcfg	29,0,13
    94c8:	ttnop
    94cc:	ttnop
    94d0:	jal	9d84 <_Z17add_block_inplaceILb0EEvmmm.constprop.0>
    94d4:	j	9230 <.L118>
    94d8:	lui	a4,0xffec1
    94dc:	lw	s0,0(a4) # ffec1000 <__instrn_buffer+0x81000>
    94e0:	beq	s0,a5,94e8 <.LBE3629+0x8>
    94e4:	j	7e58 <.L88>
    94e8:	j	91cc <.L153>
    94ec:	li	a0,16
    94f0:	jal	a20c <_Z10move_blockILb1EEvmmm.constprop.3>
    94f4:	li	a0,17
    94f8:	jal	a090 <_Z10move_blockILb1EEvmmm.constprop.2>
    94fc:	li	a0,18
    9500:	jal	a090 <_Z10move_blockILb1EEvmmm.constprop.2>
    9504:	lw	s4,168(sp)
    9508:	lw	s5,164(sp)
    950c:	lw	s6,160(sp)
    9510:	lw	s10,144(sp)
    9514:	lw	s11,140(sp)
    9518:	j	91cc <.L153>
    951c:	li	a0,30
    9520:	jal	9ac8 <_Z29llk_pack_reconfig_data_formatILb1ELb0EEvm>
    9524:	li	a0,30
    9528:	jal	9ac8 <_Z29llk_pack_reconfig_data_formatILb1ELb0EEvm>
    952c:	li	a0,30
    9530:	jal	9ac8 <_Z29llk_pack_reconfig_data_formatILb1ELb0EEvm>
    9534:	ttsemwait	1,2,1
    9538:	lw	a0,988(s1)
    953c:	lw	a6,980(s1)
    9540:	lui	a4,0x1000
    9544:	add	a5,a0,a6
    9548:	addi	a5,a5,-1
    954c:	slli	a1,a5,0x8
    9550:	addi	a4,a4,-256 # ffff00 <.LASF2126+0xfedf20>
    9554:	lui	a3,0x45000
    9558:	addi	a7,a3,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    955c:	lui	t1,0x508c0
    9560:	and	a1,a1,a4
    9564:	srli	a5,a5,0x10
    9568:	lw	a4,968(s1)
    956c:	slli	a5,a5,0x8
    9570:	sw	t1,0(s0)
    9574:	add	a1,a1,a7
    9578:	lui	a2,0x800
    957c:	sw	a1,0(s0)
    9580:	addi	a3,a3,25
    9584:	or	a2,a5,a2
    9588:	add	a0,a4,a0
    958c:	add	a2,a2,a3
    9590:	sw	a0,988(s1)
    9594:	sw	a2,0(s0)
    9598:	ttstallwait	128,1
    959c:	ttwrcfg	12,0,69
    95a0:	add	a5,a5,a3
    95a4:	sw	a5,0(s0)
    95a8:	ttdmanop
    95ac:	ttmop	1,0,0
    95b0:	ttsetadczw	4,0,0,0,0,5
    95b4:	ttstallwait	64,8
    95b8:	lw	a3,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    95bc:	lui	a2,0x10144
    95c0:	andi	a5,a3,1
    95c4:	add	a5,a5,a2
    95c8:	sw	a5,0(s0)
    95cc:	ttsemget	2
    95d0:	sub	a5,s7,a3
    95d4:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    95d8:	lui	a5,0xb0048
    95dc:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    95e0:	beq	a3,s7,95ec <.L150>
    95e4:	lui	a5,0xb0088
    95e8:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    95ec:	sw	a5,0(s0)
    95f0:	ttdmanop
    95f4:	ttdmanop
    95f8:	lhu	a3,986(s1)
    95fc:	lw	a1,972(s1)
    9600:	lui	a2,0xffb5e
    9604:	lw	a5,32(a2) # ffb5e020 <__ldm_bss_end+0x5d740>
    9608:	add	a5,a1,a5
    960c:	zext.h	a5,a5
    9610:	beq	a5,a3,9604 <.L151>
    9614:	add	a5,a4,a6
    9618:	lw	a4,964(s1)
    961c:	sw	a5,980(s1)
    9620:	sw	zero,988(s1)
    9624:	bltu	a5,a4,9634 <.L152>
    9628:	lw	a4,960(s1)
    962c:	sub	a5,a5,a4
    9630:	sw	a5,980(s1)
    9634:	addi	a5,a3,1
    9638:	lui	a3,0x45000
    963c:	zext.h	a5,a5
    9640:	addi	a3,a3,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    9644:	slli	a4,a5,0x8
    9648:	add	a4,a4,a3
    964c:	sh	a5,986(s1)
    9650:	sw	a4,0(s0)
    9654:	ttstallwait	32,8
    9658:	lui	a5,0x67618
    965c:	addi	a5,a5,-2038 # 6761780a <__device_print_strings_info_end+0x6111780a>
    9660:	sw	a5,0(s0)
    9664:	li	a0,26
    9668:	jal	9ac8 <_Z29llk_pack_reconfig_data_formatILb1ELb0EEvm>
    966c:	li	a0,26
    9670:	jal	a670 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm.isra.0>
    9674:	li	a0,20
    9678:	jal	9ac8 <_Z29llk_pack_reconfig_data_formatILb1ELb0EEvm>
    967c:	li	a0,20
    9680:	jal	a20c <_Z10move_blockILb1EEvmmm.constprop.3>
    9684:	lw	s4,168(sp)
    9688:	lw	s5,164(sp)
    968c:	lw	s6,160(sp)
    9690:	lw	s10,144(sp)
    9694:	lw	s11,140(sp)
    9698:	j	91cc <.L153>
    969c:	beqz	s6,91a8 <.L138>
    96a0:	sw	s9,148(sp)
    96a4:	lui	s10,0x1000
    96a8:	lui	s9,0x45000
    96ac:	sw	s3,172(sp)
    96b0:	addi	s11,sp,104
    96b4:	lui	s3,0x508c0
    96b8:	sh2add	s5,s6,s11
    96bc:	addi	s10,s10,-256 # ffff00 <.LASF2126+0xfedf20>
    96c0:	addi	s2,s9,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    96c4:	lw	a5,0(s11)
    96c8:	li	a4,-1
    96cc:	beq	a5,a4,9a60 <.L139>
    96d0:	li	a0,21
    96d4:	jal	a090 <_Z10move_blockILb1EEvmmm.constprop.2>
    96d8:	lhu	t1,890(s1)
    96dc:	lw	a3,876(s1)
    96e0:	lui	a4,0xffb5b
    96e4:	lw	a5,32(a4) # ffb5b020 <__ldm_bss_end+0x5a740>
    96e8:	add	a5,a3,a5
    96ec:	zext.h	a5,a5
    96f0:	beq	a5,t1,96e4 <.L140>
    96f4:	lhu	a7,954(s1)
    96f8:	lw	a3,940(s1)
    96fc:	lui	a4,0xffb5d
    9700:	lw	a5,32(a4) # ffb5d020 <__ldm_bss_end+0x5c740>
    9704:	add	a5,a3,a5
    9708:	zext.h	a5,a5
    970c:	beq	a5,a7,9700 <.L141>
    9710:	lhu	a6,1018(s1)
    9714:	lw	a3,1004(s1)
    9718:	lui	a4,0xffb5f
    971c:	lw	a5,32(a4) # ffb5f020 <__ldm_bss_end+0x5e740>
    9720:	add	a5,a3,a5
    9724:	zext.h	a5,a5
    9728:	beq	a5,a6,971c <.L142>
    972c:	lhu	a0,730(s1)
    9730:	lw	a3,716(s1)
    9734:	lui	a4,0xffb56
    9738:	lw	a5,32(a4) # ffb56020 <__ldm_bss_end+0x55740>
    973c:	add	a5,a3,a5
    9740:	zext.h	a5,a5
    9744:	beq	a5,a0,9738 <.L143>
    9748:	ttsemwait	1,2,1
    974c:	lw	a3,1012(s1)
    9750:	lw	a5,1020(s1)
    9754:	lui	a1,0x800
    9758:	add	a5,a3,a5
    975c:	addi	a5,a5,-1
    9760:	slli	a4,a5,0x8
    9764:	and	a4,a4,s10
    9768:	srli	a5,a5,0x10
    976c:	sw	s3,0(s0)
    9770:	add	a4,a4,s2
    9774:	slli	a5,a5,0x8
    9778:	sw	a4,0(s0)
    977c:	addi	a2,s9,25
    9780:	or	a4,a5,a1
    9784:	add	a4,a4,a2
    9788:	sw	a4,0(s0)
    978c:	lw	t3,1000(s1)
    9790:	ttstallwait	128,1
    9794:	ttwrcfg	12,0,69
    9798:	add	a5,a5,a2
    979c:	sw	a5,0(s0)
    97a0:	ttdmanop
    97a4:	ttmop	1,0,0
    97a8:	ttsetadczw	4,0,0,0,0,5
    97ac:	lw	a4,724(s1)
    97b0:	lw	a5,732(s1)
    97b4:	lui	t4,0x508c0
    97b8:	add	a5,a4,a5
    97bc:	addi	t4,t4,1 # 508c0001 <__device_print_strings_info_end+0x4a3c0001>
    97c0:	addi	a5,a5,-1
    97c4:	sw	t4,0(s0)
    97c8:	slli	t4,a5,0x8
    97cc:	and	t4,t4,s10
    97d0:	srli	a5,a5,0x10
    97d4:	add	t4,t4,s2
    97d8:	slli	a5,a5,0x8
    97dc:	sw	t4,0(s0)
    97e0:	or	t4,a5,a1
    97e4:	add	t4,t4,a2
    97e8:	sw	t4,0(s0)
    97ec:	lw	t4,712(s1)
    97f0:	ttstallwait	128,1
    97f4:	ttwrcfg	12,0,69
    97f8:	add	a5,a5,a2
    97fc:	sw	a5,0(s0)
    9800:	ttdmanop
    9804:	ttmop	1,0,0
    9808:	ttsetadczw	4,0,0,0,0,5
    980c:	lw	t6,884(s1)
    9810:	lw	a5,892(s1)
    9814:	addi	t5,s3,2 # 508c0002 <__device_print_strings_info_end+0x4a3c0002>
    9818:	add	a5,t6,a5
    981c:	addi	a5,a5,-1
    9820:	sw	t5,0(s0)
    9824:	slli	t5,a5,0x8
    9828:	and	t5,t5,s10
    982c:	srli	a5,a5,0x10
    9830:	add	t5,t5,s2
    9834:	slli	a5,a5,0x8
    9838:	sw	t5,0(s0)
    983c:	or	t5,a5,a1
    9840:	add	t5,t5,a2
    9844:	sw	t5,0(s0)
    9848:	lw	t0,872(s1)
    984c:	ttstallwait	128,1
    9850:	ttwrcfg	12,0,69
    9854:	add	a5,a5,a2
    9858:	sw	a5,0(s0)
    985c:	ttdmanop
    9860:	ttmop	1,0,0
    9864:	ttsetadczw	4,0,0,0,0,5
    9868:	lw	t5,948(s1)
    986c:	lw	a5,956(s1)
    9870:	addi	t2,s3,3
    9874:	add	a5,t5,a5
    9878:	addi	a5,a5,-1
    987c:	sw	t2,0(s0)
    9880:	slli	t2,a5,0x8
    9884:	srli	a5,a5,0x10
    9888:	and	t2,t2,s10
    988c:	slli	a5,a5,0x8
    9890:	add	t2,t2,s2
    9894:	or	a1,a5,a1
    9898:	sw	t2,0(s0)
    989c:	add	a1,a1,a2
    98a0:	sw	a1,0(s0)
    98a4:	lw	a1,936(s1)
    98a8:	ttstallwait	128,1
    98ac:	ttwrcfg	12,0,69
    98b0:	add	a5,a5,a2
    98b4:	sw	a5,0(s0)
    98b8:	ttdmanop
    98bc:	ttmop	1,0,0
    98c0:	ttsetadczw	4,0,0,0,0,5
    98c4:	add	a5,t6,t0
    98c8:	lw	a2,868(s1)
    98cc:	sw	a5,884(s1)
    98d0:	sw	zero,892(s1)
    98d4:	bltu	a5,a2,98e4 <.L144>
    98d8:	lw	a2,864(s1)
    98dc:	sub	a5,a5,a2
    98e0:	sw	a5,884(s1)
    98e4:	addi	a5,t1,1 # 508c0001 <__device_print_strings_info_end+0x4a3c0001>
    98e8:	zext.h	a5,a5
    98ec:	addi	t1,s9,48
    98f0:	slli	a2,a5,0x8
    98f4:	add	a2,a2,t1
    98f8:	sh	a5,890(s1)
    98fc:	sw	a2,0(s0)
    9900:	ttstallwait	32,8
    9904:	lui	a2,0x67617
    9908:	add	a5,t5,a1
    990c:	addi	a2,a2,-1014 # 67616c0a <__device_print_strings_info_end+0x61116c0a>
    9910:	lw	a1,932(s1)
    9914:	sw	a5,948(s1)
    9918:	sw	zero,956(s1)
    991c:	sw	a2,0(s0)
    9920:	bltu	a5,a1,9930 <.L145>
    9924:	lw	a2,928(s1)
    9928:	sub	a5,a5,a2
    992c:	sw	a5,948(s1)
    9930:	addi	a5,a7,1
    9934:	zext.h	a5,a5
    9938:	addi	a1,s9,48
    993c:	slli	a2,a5,0x8
    9940:	add	a2,a2,a1
    9944:	sh	a5,954(s1)
    9948:	sw	a2,0(s0)
    994c:	ttstallwait	32,8
    9950:	lui	a5,0x67617
    9954:	add	a3,a3,t3
    9958:	lw	a2,996(s1)
    995c:	addi	a5,a5,1034 # 6761740a <__device_print_strings_info_end+0x6111740a>
    9960:	sw	a3,1012(s1)
    9964:	sw	zero,1020(s1)
    9968:	sw	a5,0(s0)
    996c:	bltu	a3,a2,997c <.L146>
    9970:	lw	a5,992(s1)
    9974:	sub	a3,a3,a5
    9978:	sw	a3,1012(s1)
    997c:	addi	a5,a6,1
    9980:	zext.h	a5,a5
    9984:	addi	a2,s9,48
    9988:	slli	a3,a5,0x8
    998c:	add	a3,a3,a2
    9990:	sh	a5,1018(s1)
    9994:	sw	a3,0(s0)
    9998:	ttstallwait	32,8
    999c:	lui	a5,0x67618
    99a0:	add	a4,a4,t4
    99a4:	lw	a3,708(s1)
    99a8:	addi	a5,a5,-1014 # 67617c0a <__device_print_strings_info_end+0x61117c0a>
    99ac:	sw	a4,724(s1)
    99b0:	sw	zero,732(s1)
    99b4:	sw	a5,0(s0)
    99b8:	bltu	a4,a3,99c8 <.L147>
    99bc:	lw	a5,704(s1)
    99c0:	sub	a4,a4,a5
    99c4:	sw	a4,724(s1)
    99c8:	addi	a5,a0,1
    99cc:	zext.h	a5,a5
    99d0:	addi	a3,s9,48
    99d4:	slli	a4,a5,0x8
    99d8:	add	a4,a4,a3
    99dc:	sh	a5,730(s1)
    99e0:	sw	a4,0(s0)
    99e4:	ttstallwait	32,8
    99e8:	lui	a5,0x67616
    99ec:	addi	a5,a5,-2038 # 6761580a <__device_print_strings_info_end+0x6111580a>
    99f0:	sw	a5,0(s0)
    99f4:	ttstallwait	64,8
    99f8:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    99fc:	lui	a3,0x10144
    9a00:	andi	a5,a4,1
    9a04:	add	a5,a5,a3
    9a08:	sw	a5,0(s0)
    9a0c:	ttsemget	2
    9a10:	li	a3,1
    9a14:	sub	a5,a3,a4
    9a18:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9a1c:	lui	a5,0xb0048
    9a20:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    9a24:	beq	a4,a3,9a30 <.L148>
    9a28:	lui	a5,0xb0088
    9a2c:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    9a30:	sw	a5,0(s0)
    9a34:	ttdmanop
    9a38:	ttdmanop
    9a3c:	li	a0,23
    9a40:	jal	a20c <_Z10move_blockILb1EEvmmm.constprop.3>
    9a44:	li	a0,26
    9a48:	jal	a670 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm.isra.0>
    9a4c:	li	a0,23
    9a50:	jal	a670 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm.isra.0>
    9a54:	jal	9d84 <_Z17add_block_inplaceILb0EEvmmm.constprop.0>
    9a58:	jal	a3f0 <_Z10move_blockILb1EEvmmm.constprop.1>
    9a5c:	jal	a530 <_Z10move_blockILb1EEvmmm.constprop.0>
    9a60:	addi	s11,s11,4
    9a64:	bne	s5,s11,96c4 <.L149>
    9a68:	lw	s3,172(sp)
    9a6c:	lw	s9,148(sp)
    9a70:	j	91a8 <.L138>
    9a74:	addi	s5,s5,1
    9a78:	li	s6,6
    9a7c:	j	7f58 <.L102>
    9a80:	addi	s5,s5,1
    9a84:	li	s6,5
    9a88:	j	7f44 <.L100>
    9a8c:	addi	s5,s5,1
    9a90:	li	s6,4
    9a94:	j	7f30 <.L99>
    9a98:	lw	a3,88(sp)
    9a9c:	sw	a4,108(sp)
    9aa0:	addi	s5,s5,1
    9aa4:	li	s6,2
    9aa8:	bltu	a3,a5,9ab0 <.L208>
    9aac:	j	7f18 <.L159>
    9ab0:	addi	s5,s5,1
    9ab4:	li	s6,3
    9ab8:	j	7f1c <.L98>
    9abc:	sub	a4,a5,s1
    9ac0:	addi	a4,a4,-1
    9ac4:	j	7eb0 <.L91>
00009ac8 <_Z29llk_pack_reconfig_data_formatILb1ELb0EEvm>:
    9ac8:	addi	a5,gp,176 # ffb008a0 <_ZL15pack_dst_format>
    9acc:	add	a5,a5,a0
    9ad0:	addi	a6,gp,48 # ffb00820 <_ZL20pack_tile_face_r_dim>
    9ad4:	add	a6,a6,a0
    9ad8:	lbu	a1,0(a5)
    9adc:	lui	a5,0xffb00
    9ae0:	slli	a0,a0,0x5
    9ae4:	lbu	a2,128(a6)
    9ae8:	addi	a5,a5,32 # ffb00020 <cb_interface>
    9aec:	add	a5,a5,a0
    9af0:	andi	t4,a1,15
    9af4:	andi	a4,a1,31
    9af8:	li	t5,26
    9afc:	lw	a0,8(a5)
    9b00:	lbu	a3,0(a6)
    9b04:	lbu	t3,64(a6)
    9b08:	addi	sp,sp,-16
    9b0c:	mv	t1,t4
    9b10:	andi	a7,a2,15
    9b14:	li	a5,1
    9b18:	beq	a4,t5,9b20 <.L2>
    9b1c:	mv	a5,a2
    9b20:	andi	a5,a5,15
    9b24:	slli	a6,t4,0x4
    9b28:	slli	a5,a5,0x8
    9b2c:	or	a5,a5,a6
    9b30:	lui	a6,0x1
    9b34:	addi	a6,a6,-16 # ff0 <.LLRL1740+0x1c>
    9b38:	li	t6,1
    9b3c:	and	a5,a5,a6
    9b40:	sw	t6,12(sp)
    9b44:	or	a5,a5,t6
    9b48:	sh	a5,12(sp)
    9b4c:	lw	a6,12(sp)
    9b50:	lui	t5,0x1000
    9b54:	addi	t5,t5,-256 # ffff00 <.LASF2126+0xfedf20>
    9b58:	lui	t4,0x45000
    9b5c:	slli	a6,a6,0x8
    9b60:	and	a6,a6,t5
    9b64:	addi	t0,t4,60 # 4500003c <__device_print_strings_info_end+0x3eb0003c>
    9b68:	lui	a5,0xffe40
    9b6c:	add	a6,a6,t0
    9b70:	mv	a5,a5
    9b74:	sw	a6,0(a5) # ffe40000 <__instrn_buffer>
    9b78:	ttstallwait	128,9
    9b7c:	ttwrcfg	30,0,70
    9b80:	slli	a3,a3,0x10
    9b84:	addi	a6,t4,56
    9b88:	and	a3,a3,t5
    9b8c:	add	a3,a3,a6
    9b90:	sw	a3,0(a5)
    9b94:	addi	t4,t4,57
    9b98:	lui	a3,0xb01c0
    9b9c:	addi	a3,a3,28 # b01c001c <__device_print_strings_info_end+0xa9cc001c>
    9ba0:	sw	t4,0(a5)
    9ba4:	sw	a3,0(a5)
    9ba8:	li	a6,30
    9bac:	mv	a3,t6
    9bb0:	beq	a1,a6,9d3c <.L23>
    9bb4:	beq	a2,t6,9bcc <.L4>
    9bb8:	andi	a6,a2,12
    9bbc:	bnez	a6,9d4c <.L5>
    9bc0:	bnez	a7,9bd0 <.L6>
    9bc4:	li	a6,26
    9bc8:	bne	a4,a6,9bd0 <.L6>
    9bcc:	ori	a3,a3,8
    9bd0:	lui	t4,0xb30b0
    9bd4:	lui	a6,0x9
    9bd8:	slli	a3,a3,0x8
    9bdc:	addi	t4,t4,18 # b30b0012 <__device_print_strings_info_end+0xacbb0012>
    9be0:	zext.h	a3,a3
    9be4:	addi	a6,a6,-1844 # 88cc <.LM1798>
    9be8:	add	a3,a3,t4
    9bec:	srl	a6,a6,t1
    9bf0:	sw	a3,0(a5)
    9bf4:	andi	a3,a6,1
    9bf8:	bnez	a3,9ce0 <.L8>
    9bfc:	andi	a3,a1,11
    9c00:	li	a6,10
    9c04:	bne	a3,a6,9c0c <.L10>
    9c08:	ttwrcfg	0,0,68
    9c0c:	addi	a4,a4,-26
    9c10:	seqz	a4,a4
    9c14:	lui	t3,0xb5800
    9c18:	lui	a6,0x1000
    9c1c:	slli	a3,a0,0x8
    9c20:	slli	a4,a4,0xf
    9c24:	addi	t3,t3,71 # b5800047 <__device_print_strings_info_end+0xaf300047>
    9c28:	addi	a6,a6,-256 # ffff00 <.LASF2126+0xfedf20>
    9c2c:	lui	a0,0x45000
    9c30:	add	a4,a4,t3
    9c34:	and	a3,a3,a6
    9c38:	addi	a0,a0,32 # 45000020 <__device_print_strings_info_end+0x3eb00020>
    9c3c:	sw	a4,0(a5)
    9c40:	add	a4,a3,a0
    9c44:	sw	a4,0(a5)
    9c48:	andi	a4,a1,12
    9c4c:	bnez	a4,9d20 <.L11>
    9c50:	andi	a1,a1,14
    9c54:	bnez	a1,9d28 <.L21>
    9c58:	lui	a3,0xb6ff0
    9c5c:	lui	a1,0xb5100
    9c60:	addi	a3,a3,71 # b6ff0047 <__device_print_strings_info_end+0xb0af0047>
    9c64:	addi	a1,a1,71 # b5100047 <__device_print_strings_info_end+0xaec00047>
    9c68:	lui	a4,0xb61e0
    9c6c:	sw	a1,0(a5)
    9c70:	slli	a7,a7,0x9
    9c74:	addi	a4,a4,1 # b61e0001 <__device_print_strings_info_end+0xafce0001>
    9c78:	sw	a3,0(a5)
    9c7c:	add	a7,a7,a4
    9c80:	andi	a2,a2,3
    9c84:	sw	a7,0(a5)
    9c88:	beqz	a2,9d04 <.L17>
    9c8c:	li	a4,1
    9c90:	beq	a2,a4,9d68 <.L24>
    9c94:	lui	a4,0x45040
    9c98:	lui	a3,0x45010
    9c9c:	lui	a2,0x45001
    9ca0:	addi	a4,a4,59 # 4504003b <__device_print_strings_info_end+0x3eb4003b>
    9ca4:	addi	a3,a3,58 # 4501003a <__device_print_strings_info_end+0x3eb1003a>
    9ca8:	addi	a2,a2,57 # 45001039 <__device_print_strings_info_end+0x3eb01039>
    9cac:	lui	a1,0x45000
    9cb0:	addi	a1,a1,56 # 45000038 <__device_print_strings_info_end+0x3eb00038>
    9cb4:	sw	a1,0(a5)
    9cb8:	sw	a2,0(a5)
    9cbc:	sw	a3,0(a5)
    9cc0:	sw	a4,0(a5)
    9cc4:	ttstallwait	128,1
    9cc8:	ttwrcfg	28,0,12
    9ccc:	ttwrcfg	29,0,13
    9cd0:	ttnop
    9cd4:	ttnop
    9cd8:	addi	sp,sp,16
    9cdc:	ret
    9ce0:	lui	a3,0xb5ff0
    9ce4:	addi	a3,a3,68 # b5ff0044 <__device_print_strings_info_end+0xafaf0044>
    9ce8:	slli	t3,t3,0x8
    9cec:	add	t3,t3,a3
    9cf0:	lui	a3,0xb6ff0
    9cf4:	sw	t3,0(a5)
    9cf8:	addi	a3,a3,68 # b6ff0044 <__device_print_strings_info_end+0xb0af0044>
    9cfc:	sw	a3,0(a5)
    9d00:	j	9c0c <.L10>
    9d04:	lui	a4,0x45100
    9d08:	lui	a3,0x45040
    9d0c:	lui	a2,0x45004
    9d10:	addi	a4,a4,59 # 4510003b <__device_print_strings_info_end+0x3ec0003b>
    9d14:	addi	a3,a3,58 # 4504003a <__device_print_strings_info_end+0x3eb4003a>
    9d18:	addi	a2,a2,57 # 45004039 <__device_print_strings_info_end+0x3eb04039>
    9d1c:	j	9cac <.L13>
    9d20:	li	a4,11
    9d24:	bne	t1,a4,9c58 <.L16>
    9d28:	lui	a3,0xb6ff7
    9d2c:	lui	a1,0xb5101
    9d30:	addi	a3,a3,327 # b6ff7147 <__device_print_strings_info_end+0xb0af7147>
    9d34:	addi	a1,a1,71 # b5101047 <__device_print_strings_info_end+0xaec01047>
    9d38:	j	9c68 <.L12>
    9d3c:	li	a3,3
    9d40:	beq	a2,t6,9bcc <.L4>
    9d44:	andi	a6,a2,12
    9d48:	beqz	a6,9bd0 <.L6>
    9d4c:	addi	a6,a7,-10
    9d50:	zext.b	a6,a6
    9d54:	li	t4,1
    9d58:	bgeu	t4,a6,9bd0 <.L6>
    9d5c:	li	a6,26
    9d60:	bne	a4,a6,9bd0 <.L6>
    9d64:	j	9bcc <.L4>
    9d68:	lui	a4,0x45080
    9d6c:	lui	a3,0x45020
    9d70:	lui	a2,0x45002
    9d74:	addi	a4,a4,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    9d78:	addi	a3,a3,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    9d7c:	addi	a2,a2,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    9d80:	j	9cac <.L13>
00009d84 <_Z17add_block_inplaceILb0EEvmmm.constprop.0>:
    9d84:	lui	a2,0xffb00
    9d88:	addi	a2,a2,32 # ffb00020 <cb_interface>
    9d8c:	addi	sp,sp,-16
    9d90:	lw	t1,852(a2)
    9d94:	lw	a0,860(a2)
    9d98:	lw	a1,840(a2)
    9d9c:	lw	a7,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    9da0:	sw	s0,12(sp)
    9da4:	ttsemwait	1,2,1
    9da8:	add	a5,a0,t1
    9dac:	addi	a5,a5,-1
    9db0:	lui	a4,0x1000
    9db4:	slli	t3,a5,0x8
    9db8:	addi	a4,a4,-256 # ffff00 <.LASF2126+0xfedf20>
    9dbc:	and	t3,t3,a4
    9dc0:	lui	a3,0x45000
    9dc4:	srli	a5,a5,0x10
    9dc8:	lui	a4,0xffe40
    9dcc:	mv	a4,a4
    9dd0:	addi	t5,a3,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    9dd4:	slli	a5,a5,0x8
    9dd8:	lui	t4,0x508c0
    9ddc:	lui	a6,0x800
    9de0:	sw	t4,0(a4) # ffe40000 <__instrn_buffer>
    9de4:	add	t3,t3,t5
    9de8:	addi	a3,a3,25
    9dec:	or	a6,a5,a6
    9df0:	sw	t3,0(a4)
    9df4:	add	a6,a6,a3
    9df8:	sw	a6,0(a4)
    9dfc:	add	a0,a0,a1
    9e00:	ttstallwait	128,1
    9e04:	ttwrcfg	12,0,69
    9e08:	add	a5,a5,a3
    9e0c:	sw	a5,0(a4)
    9e10:	ttdmanop
    9e14:	ttmop	1,0,0
    9e18:	ttsetadczw	4,0,0,0,0,5
    9e1c:	ttstallwait	64,8
    9e20:	lui	a5,0x10144
    9e24:	andi	t6,a7,1
    9e28:	add	t6,t6,a5
    9e2c:	sw	t6,0(a4)
    9e30:	ttsemget	2
    9e34:	li	a5,1
    9e38:	lui	t4,0xb0088
    9e3c:	sub	a6,a5,a7
    9e40:	addi	t4,t4,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    9e44:	bne	a7,a5,9e50 <.L26>
    9e48:	lui	t4,0xb0048
    9e4c:	addi	t4,t4,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    9e50:	sw	t4,0(a4)
    9e54:	ttdmanop
    9e58:	ttdmanop
    9e5c:	ttsemwait	1,2,1
    9e60:	addi	a5,t1,-1
    9e64:	add	a3,a0,a5
    9e68:	lui	t3,0x1000
    9e6c:	slli	t0,a3,0x8
    9e70:	addi	t3,t3,-256 # ffff00 <.LASF2126+0xfedf20>
    9e74:	lui	t5,0x508c0
    9e78:	and	t0,t0,t3
    9e7c:	lui	t3,0x45000
    9e80:	sw	t5,0(a4)
    9e84:	srli	a3,a3,0x10
    9e88:	addi	t5,t3,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    9e8c:	add	t0,t0,t5
    9e90:	slli	a3,a3,0x8
    9e94:	lui	t5,0x800
    9e98:	addi	t3,t3,25
    9e9c:	or	t5,a3,t5
    9ea0:	sw	t0,0(a4)
    9ea4:	add	t5,t5,t3
    9ea8:	add	a0,a1,a0
    9eac:	sw	t5,0(a4)
    9eb0:	ttstallwait	128,1
    9eb4:	ttwrcfg	12,0,69
    9eb8:	add	a3,a3,t3
    9ebc:	sw	a3,0(a4)
    9ec0:	ttdmanop
    9ec4:	ttmop	1,0,0
    9ec8:	ttsetadczw	4,0,0,0,0,5
    9ecc:	ttstallwait	64,8
    9ed0:	lui	a3,0x10144
    9ed4:	andi	a6,a6,1
    9ed8:	add	a6,a6,a3
    9edc:	sw	a6,0(a4)
    9ee0:	ttsemget	2
    9ee4:	lui	a3,0xb0048
    9ee8:	addi	a3,a3,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    9eec:	beqz	a7,9ef8 <.L27>
    9ef0:	lui	a3,0xb0088
    9ef4:	addi	a3,a3,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    9ef8:	sw	a3,0(a4)
    9efc:	ttdmanop
    9f00:	ttdmanop
    9f04:	ttsemwait	1,2,1
    9f08:	lui	t0,0x1000
    9f0c:	add	a5,a0,a5
    9f10:	slli	t5,a5,0x8
    9f14:	addi	t0,t0,-256 # ffff00 <.LASF2126+0xfedf20>
    9f18:	lui	a3,0x45000
    9f1c:	addi	t2,a3,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    9f20:	and	t5,t5,t0
    9f24:	lui	s0,0x508c0
    9f28:	srli	a5,a5,0x10
    9f2c:	add	t5,t5,t2
    9f30:	sw	s0,0(a4)
    9f34:	slli	a5,a5,0x8
    9f38:	lui	t3,0x800
    9f3c:	sw	t5,0(a4)
    9f40:	addi	a3,a3,25
    9f44:	or	t5,a5,t3
    9f48:	add	t5,t5,a3
    9f4c:	add	t1,t1,a1
    9f50:	sw	t5,0(a4)
    9f54:	ttstallwait	128,1
    9f58:	ttwrcfg	12,0,69
    9f5c:	add	a5,a5,a3
    9f60:	sw	a5,0(a4)
    9f64:	ttdmanop
    9f68:	ttmop	1,0,0
    9f6c:	ttsetadczw	4,0,0,0,0,5
    9f70:	ttstallwait	64,8
    9f74:	sw	t6,0(a4)
    9f78:	ttsemget	2
    9f7c:	sw	t4,0(a4)
    9f80:	ttdmanop
    9f84:	ttdmanop
    9f88:	ttsemwait	1,2,1
    9f8c:	addi	a5,t1,-1
    9f90:	add	a5,a5,a0
    9f94:	slli	t4,a5,0x8
    9f98:	srli	a5,a5,0x10
    9f9c:	and	t4,t4,t0
    9fa0:	slli	a5,a5,0x8
    9fa4:	sw	s0,0(a4)
    9fa8:	add	t4,t4,t2
    9fac:	or	t3,a5,t3
    9fb0:	sw	t4,0(a4)
    9fb4:	add	t3,t3,a3
    9fb8:	sw	t3,0(a4)
    9fbc:	ttstallwait	128,1
    9fc0:	ttwrcfg	12,0,69
    9fc4:	add	a5,a5,a3
    9fc8:	sw	a5,0(a4)
    9fcc:	ttdmanop
    9fd0:	ttmop	1,0,0
    9fd4:	ttsetadczw	4,0,0,0,0,5
    9fd8:	ttstallwait	64,8
    9fdc:	sw	a6,0(a4)
    9fe0:	ttsemget	2
    9fe4:	lui	a5,0xb0048
    9fe8:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    9fec:	beqz	a7,9ff8 <.L28>
    9ff0:	lui	a5,0xb0088
    9ff4:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    9ff8:	sw	a5,0(a4)
    9ffc:	ttdmanop
    a000:	ttdmanop
    a004:	sh1add	a0,a1,a0
    a008:	lhu	a3,858(a2)
    a00c:	lw	a7,844(a2)
    a010:	sw	a0,860(a2)
    a014:	lui	a6,0xffb5a
    a018:	li	a0,3
    a01c:	lw	a5,32(a6) # ffb5a020 <__ldm_bss_end+0x59740>
    a020:	add	a5,a7,a5
    a024:	sub	a5,a5,a3
    a028:	zext.h	a5,a5
    a02c:	bgeu	a0,a5,a01c <.L29>
    a030:	sh1add	a1,a1,a1
    a034:	lw	a5,836(a2)
    a038:	add	a1,a1,t1
    a03c:	sw	a1,852(a2)
    a040:	sw	zero,860(a2)
    a044:	bltu	a1,a5,a054 <.L30>
    a048:	lw	a5,832(a2)
    a04c:	sub	a1,a1,a5
    a050:	sw	a1,852(a2)
    a054:	addi	a3,a3,4
    a058:	lui	a1,0x45000
    a05c:	zext.h	a3,a3
    a060:	addi	a1,a1,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    a064:	slli	a5,a3,0x8
    a068:	add	a5,a5,a1
    a06c:	sh	a3,858(a2)
    a070:	sw	a5,0(a4)
    a074:	ttstallwait	32,8
    a078:	lui	a5,0x67617
    a07c:	lw	s0,12(sp)
    a080:	addi	a5,a5,-2038 # 6761680a <__device_print_strings_info_end+0x6111680a>
    a084:	sw	a5,0(a4)
    a088:	addi	sp,sp,16
    a08c:	ret
0000a090 <_Z10move_blockILb1EEvmmm.constprop.2>:
    a090:	lui	a2,0xffb00
    a094:	slli	t1,a0,0x5
    a098:	addi	a2,a2,32 # ffb00020 <cb_interface>
    a09c:	add	a5,a2,t1
    a0a0:	lhu	a1,26(a5)
    a0a4:	lw	a3,12(a5)
    a0a8:	lui	a4,0xffb40
    a0ac:	slli	a0,a0,0xc
    a0b0:	addi	a4,a4,32 # ffb40020 <__ldm_bss_end+0x3f740>
    a0b4:	sub	a3,a3,a1
    a0b8:	add	a4,a0,a4
    a0bc:	lw	a5,0(a4)
    a0c0:	add	a5,a3,a5
    a0c4:	zext.h	a5,a5
    a0c8:	beqz	a5,a0bc <.L40>
    a0cc:	ttsemwait	1,2,1
    a0d0:	add	a3,a2,t1
    a0d4:	lw	a6,20(a3)
    a0d8:	lw	a5,28(a3)
    a0dc:	lui	a4,0x1000
    a0e0:	add	a5,a6,a5
    a0e4:	addi	a5,a5,-1
    a0e8:	slli	t4,a5,0x8
    a0ec:	addi	a4,a4,-256 # ffff00 <.LASF2126+0xfedf20>
    a0f0:	lui	a7,0x45000
    a0f4:	addi	t3,a7,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    a0f8:	and	t4,t4,a4
    a0fc:	srli	a5,a5,0x10
    a100:	lui	a4,0xffe40
    a104:	mv	a4,a4
    a108:	add	t4,t4,t3
    a10c:	slli	a5,a5,0x8
    a110:	lui	t6,0x508c0
    a114:	lui	t3,0x800
    a118:	lw	t5,8(a3)
    a11c:	addi	a7,a7,25
    a120:	sw	t6,0(a4) # ffe40000 <__instrn_buffer>
    a124:	or	t3,a5,t3
    a128:	sw	t4,0(a4)
    a12c:	add	t3,t3,a7
    a130:	sw	t3,0(a4)
    a134:	ttstallwait	128,1
    a138:	ttwrcfg	12,0,69
    a13c:	add	a5,a5,a7
    a140:	sw	a5,0(a4)
    a144:	ttdmanop
    a148:	ttmop	1,0,0
    a14c:	ttsetadczw	4,0,0,0,0,5
    a150:	add	a5,a6,t5
    a154:	lw	a6,4(a3)
    a158:	sw	a5,20(a3)
    a15c:	sw	zero,28(a3)
    a160:	bltu	a5,a6,a170 <.L41>
    a164:	lw	a6,0(a3)
    a168:	sub	a5,a5,a6
    a16c:	sw	a5,20(a3)
    a170:	addi	a5,a1,1
    a174:	lui	a1,0x45000
    a178:	zext.h	a5,a5
    a17c:	add	a2,a2,t1
    a180:	slli	a3,a5,0x8
    a184:	addi	a1,a1,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    a188:	sh	a5,26(a2)
    a18c:	add	a5,a3,a1
    a190:	sw	a5,0(a4)
    a194:	ttstallwait	32,8
    a198:	lui	a3,0x3fed0
    a19c:	srli	a5,a0,0x2
    a1a0:	addi	a3,a3,10 # 3fed000a <__device_print_strings_info_end+0x399d000a>
    a1a4:	add	a5,a5,a3
    a1a8:	lui	a3,0x40
    a1ac:	addi	a3,a3,-1 # 3ffff <.LASF2126+0x2e01f>
    a1b0:	and	a5,a5,a3
    a1b4:	lui	a3,0x67600
    a1b8:	add	a5,a5,a3
    a1bc:	sw	a5,0(a4)
    a1c0:	ttstallwait	64,8
    a1c4:	lw	a3,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a1c8:	lui	a2,0x10144
    a1cc:	andi	a5,a3,1
    a1d0:	add	a5,a5,a2
    a1d4:	sw	a5,0(a4)
    a1d8:	ttsemget	2
    a1dc:	li	a2,1
    a1e0:	sub	a5,a2,a3
    a1e4:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a1e8:	lui	a5,0xb0048
    a1ec:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    a1f0:	beq	a3,a2,a1fc <.L42>
    a1f4:	lui	a5,0xb0088
    a1f8:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    a1fc:	sw	a5,0(a4)
    a200:	ttdmanop
    a204:	ttdmanop
    a208:	ret
0000a20c <_Z10move_blockILb1EEvmmm.constprop.3>:
    a20c:	addi	sp,sp,-48
    a210:	lui	t5,0xffb00
    a214:	sw	s6,20(sp)
    a218:	addi	t5,t5,32 # ffb00020 <cb_interface>
    a21c:	slli	s6,a0,0x5
    a220:	add	a5,t5,s6
    a224:	lhu	a3,26(a5)
    a228:	lw	a2,12(a5)
    a22c:	lui	a4,0xffb40
    a230:	slli	a0,a0,0xc
    a234:	addi	a4,a4,32 # ffb40020 <__ldm_bss_end+0x3f740>
    a238:	sw	s0,44(sp)
    a23c:	sw	s1,40(sp)
    a240:	sw	s2,36(sp)
    a244:	sw	s3,32(sp)
    a248:	sw	s4,28(sp)
    a24c:	sw	s5,24(sp)
    a250:	sw	s7,16(sp)
    a254:	sw	s8,12(sp)
    a258:	sw	s9,8(sp)
    a25c:	sub	a2,a2,a3
    a260:	add	a4,a0,a4
    a264:	li	a1,3
    a268:	lw	a5,0(a4)
    a26c:	add	a5,a2,a5
    a270:	zext.h	a5,a5
    a274:	bgeu	a1,a5,a268 <.L47>
    a278:	lui	a5,0x3fed0
    a27c:	addi	a5,a5,10 # 3fed000a <__device_print_strings_info_end+0x399d000a>
    a280:	srli	a0,a0,0x2
    a284:	add	a0,a0,a5
    a288:	lui	a5,0x40
    a28c:	addi	a5,a5,-1 # 3ffff <.LASF2126+0x2e01f>
    a290:	add	s4,t5,s6
    a294:	and	a0,a0,a5
    a298:	lui	a5,0x67600
    a29c:	lui	t1,0x45000
    a2a0:	add	a0,a0,a5
    a2a4:	lui	a4,0xffe40
    a2a8:	lui	t4,0x1000
    a2ac:	lw	a2,20(s4)
    a2b0:	lw	a5,28(s4)
    a2b4:	lw	s3,8(s4)
    a2b8:	lw	s2,4(s4)
    a2bc:	lw	a1,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a2c0:	addi	t3,a3,4 # 67600004 <__device_print_strings_info_end+0x61100004>
    a2c4:	addi	s1,t1,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    a2c8:	zext.h	t3,t3
    a2cc:	addi	a7,t1,25
    a2d0:	mv	a4,a4
    a2d4:	addi	t4,t4,-256 # ffff00 <.LASF2126+0xfedf20>
    a2d8:	addi	t1,t1,48
    a2dc:	lui	s0,0x508c0
    a2e0:	lui	t2,0x800
    a2e4:	lui	t0,0x10144
    a2e8:	li	a6,1
    a2ec:	lui	t6,0xb0048
    a2f0:	lui	s5,0xb0088
    a2f4:	ttsemwait	1,2,1
    a2f8:	add	a5,a5,a2
    a2fc:	addi	a5,a5,-1 # 675fffff <__device_print_strings_info_end+0x610fffff>
    a300:	slli	s8,a5,0x8
    a304:	srli	a5,a5,0x10
    a308:	and	s8,s8,t4
    a30c:	slli	a5,a5,0x8
    a310:	sw	s0,0(a4) # ffe40000 <__instrn_buffer>
    a314:	add	s8,s8,s1
    a318:	or	s9,a5,t2
    a31c:	sw	s8,0(a4)
    a320:	add	s8,s9,a7
    a324:	sw	s8,0(a4)
    a328:	ttstallwait	128,1
    a32c:	ttwrcfg	12,0,69
    a330:	add	a5,a5,a7
    a334:	sw	a5,0(a4)
    a338:	ttdmanop
    a33c:	ttmop	1,0,0
    a340:	ttsetadczw	4,0,0,0,0,5
    a344:	addi	a3,a3,1
    a348:	zext.h	a3,a3
    a34c:	add	a2,a2,s3
    a350:	slli	a5,a3,0x8
    a354:	add	a5,a5,t1
    a358:	bltu	a2,s2,a364 <.L48>
    a35c:	lw	s8,0(s4)
    a360:	sub	a2,a2,s8
    a364:	sw	a5,0(a4)
    a368:	ttstallwait	32,8
    a36c:	sw	a0,0(a4)
    a370:	ttstallwait	64,8
    a374:	andi	a5,a1,1
    a378:	add	a5,a5,t0
    a37c:	sw	a5,0(a4)
    a380:	ttsemget	2
    a384:	sub	s8,a6,a1
    a388:	addi	a5,t6,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    a38c:	beq	a1,a6,a394 <.L49>
    a390:	addi	a5,s5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    a394:	sw	a5,0(a4)
    a398:	ttdmanop
    a39c:	ttdmanop
    a3a0:	li	a5,0
    a3a4:	mv	a1,s8
    a3a8:	bne	a3,t3,a2f4 <.L50>
    a3ac:	add	t5,t5,s6
    a3b0:	lw	s0,44(sp)
    a3b4:	sw	s8,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a3b8:	sh	a3,26(t5)
    a3bc:	sw	zero,28(t5)
    a3c0:	sw	a2,20(t5)
    a3c4:	lw	s1,40(sp)
    a3c8:	lw	s2,36(sp)
    a3cc:	lw	s3,32(sp)
    a3d0:	lw	s4,28(sp)
    a3d4:	lw	s5,24(sp)
    a3d8:	lw	s6,20(sp)
    a3dc:	lw	s7,16(sp)
    a3e0:	lw	s8,12(sp)
    a3e4:	lw	s9,8(sp)
    a3e8:	addi	sp,sp,48
    a3ec:	ret
0000a3f0 <_Z10move_blockILb1EEvmmm.constprop.1>:
    a3f0:	lui	a3,0xffb00
    a3f4:	addi	a3,a3,32 # ffb00020 <cb_interface>
    a3f8:	lhu	a4,922(a3)
    a3fc:	lw	a1,908(a3)
    a400:	lui	a2,0xffb5c
    a404:	lw	a5,32(a2) # ffb5c020 <__ldm_bss_end+0x5b740>
    a408:	add	a5,a1,a5
    a40c:	zext.h	a5,a5
    a410:	beq	a4,a5,a404 <.L56>
    a414:	ttsemwait	1,2,1
    a418:	lw	a1,916(a3)
    a41c:	lw	a5,924(a3)
    a420:	lui	a2,0x1000
    a424:	add	a5,a1,a5
    a428:	addi	a5,a5,-1
    a42c:	slli	a7,a5,0x8
    a430:	addi	a2,a2,-256 # ffff00 <.LASF2126+0xfedf20>
    a434:	and	a7,a7,a2
    a438:	lui	a0,0x45000
    a43c:	srli	a5,a5,0x10
    a440:	lui	a2,0xffe40
    a444:	mv	a2,a2
    a448:	addi	t3,a0,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    a44c:	slli	a5,a5,0x8
    a450:	lui	t1,0x508c0
    a454:	lui	a6,0x800
    a458:	sw	t1,0(a2) # ffe40000 <__instrn_buffer>
    a45c:	add	a7,a7,t3
    a460:	addi	a0,a0,25
    a464:	or	a6,a5,a6
    a468:	sw	a7,0(a2)
    a46c:	add	a6,a6,a0
    a470:	sw	a6,0(a2)
    a474:	lw	a6,904(a3)
    a478:	ttstallwait	128,1
    a47c:	ttwrcfg	12,0,69
    a480:	add	a5,a5,a0
    a484:	sw	a5,0(a2)
    a488:	ttdmanop
    a48c:	ttmop	1,0,0
    a490:	ttsetadczw	4,0,0,0,0,5
    a494:	add	a5,a1,a6
    a498:	lw	a1,900(a3)
    a49c:	sw	a5,916(a3)
    a4a0:	sw	zero,924(a3)
    a4a4:	bltu	a5,a1,a4b4 <.L57>
    a4a8:	lw	a1,896(a3)
    a4ac:	sub	a5,a5,a1
    a4b0:	sw	a5,916(a3)
    a4b4:	addi	a4,a4,1
    a4b8:	lui	a5,0x45000
    a4bc:	zext.h	a4,a4
    a4c0:	addi	a5,a5,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    a4c4:	sh	a4,922(a3)
    a4c8:	slli	a4,a4,0x8
    a4cc:	add	a4,a4,a5
    a4d0:	sw	a4,0(a2)
    a4d4:	ttstallwait	32,8
    a4d8:	lui	a5,0x67617
    a4dc:	addi	a5,a5,10 # 6761700a <__device_print_strings_info_end+0x6111700a>
    a4e0:	sw	a5,0(a2)
    a4e4:	ttstallwait	64,8
    a4e8:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a4ec:	lui	a3,0x10144
    a4f0:	andi	a5,a4,1
    a4f4:	add	a5,a5,a3
    a4f8:	sw	a5,0(a2)
    a4fc:	ttsemget	2
    a500:	li	a3,1
    a504:	sub	a5,a3,a4
    a508:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a50c:	lui	a5,0xb0048
    a510:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    a514:	beq	a4,a3,a520 <.L58>
    a518:	lui	a5,0xb0088
    a51c:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    a520:	sw	a5,0(a2)
    a524:	ttdmanop
    a528:	ttdmanop
    a52c:	ret
0000a530 <_Z10move_blockILb1EEvmmm.constprop.0>:
    a530:	lui	a3,0xffb00
    a534:	addi	a3,a3,32 # ffb00020 <cb_interface>
    a538:	lhu	a4,986(a3)
    a53c:	lw	a1,972(a3)
    a540:	lui	a2,0xffb5e
    a544:	lw	a5,32(a2) # ffb5e020 <__ldm_bss_end+0x5d740>
    a548:	add	a5,a1,a5
    a54c:	zext.h	a5,a5
    a550:	beq	a4,a5,a544 <.L62>
    a554:	ttsemwait	1,2,1
    a558:	lw	a1,980(a3)
    a55c:	lw	a5,988(a3)
    a560:	lui	a2,0x1000
    a564:	add	a5,a1,a5
    a568:	addi	a5,a5,-1
    a56c:	slli	a7,a5,0x8
    a570:	addi	a2,a2,-256 # ffff00 <.LASF2126+0xfedf20>
    a574:	and	a7,a7,a2
    a578:	lui	a0,0x45000
    a57c:	srli	a5,a5,0x10
    a580:	lui	a2,0xffe40
    a584:	mv	a2,a2
    a588:	addi	t3,a0,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    a58c:	slli	a5,a5,0x8
    a590:	lui	t1,0x508c0
    a594:	lui	a6,0x800
    a598:	sw	t1,0(a2) # ffe40000 <__instrn_buffer>
    a59c:	add	a7,a7,t3
    a5a0:	addi	a0,a0,25
    a5a4:	or	a6,a5,a6
    a5a8:	sw	a7,0(a2)
    a5ac:	add	a6,a6,a0
    a5b0:	sw	a6,0(a2)
    a5b4:	lw	a6,968(a3)
    a5b8:	ttstallwait	128,1
    a5bc:	ttwrcfg	12,0,69
    a5c0:	add	a5,a5,a0
    a5c4:	sw	a5,0(a2)
    a5c8:	ttdmanop
    a5cc:	ttmop	1,0,0
    a5d0:	ttsetadczw	4,0,0,0,0,5
    a5d4:	add	a5,a1,a6
    a5d8:	lw	a1,964(a3)
    a5dc:	sw	a5,980(a3)
    a5e0:	sw	zero,988(a3)
    a5e4:	bltu	a5,a1,a5f4 <.L63>
    a5e8:	lw	a1,960(a3)
    a5ec:	sub	a5,a5,a1
    a5f0:	sw	a5,980(a3)
    a5f4:	addi	a4,a4,1
    a5f8:	lui	a5,0x45000
    a5fc:	zext.h	a4,a4
    a600:	addi	a5,a5,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    a604:	sh	a4,986(a3)
    a608:	slli	a4,a4,0x8
    a60c:	add	a4,a4,a5
    a610:	sw	a4,0(a2)
    a614:	ttstallwait	32,8
    a618:	lui	a5,0x67618
    a61c:	addi	a5,a5,-2038 # 6761780a <__device_print_strings_info_end+0x6111780a>
    a620:	sw	a5,0(a2)
    a624:	ttstallwait	64,8
    a628:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a62c:	lui	a3,0x10144
    a630:	andi	a5,a4,1
    a634:	add	a5,a5,a3
    a638:	sw	a5,0(a2)
    a63c:	ttsemget	2
    a640:	li	a3,1
    a644:	sub	a5,a3,a4
    a648:	sw	a5,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a64c:	lui	a5,0xb0048
    a650:	addi	a5,a5,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    a654:	beq	a4,a3,a660 <.L64>
    a658:	lui	a5,0xb0088
    a65c:	addi	a5,a5,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    a660:	sw	a5,0(a2)
    a664:	ttdmanop
    a668:	ttdmanop
    a66c:	ret
0000a670 <_Z28mul_block_bcast_cols_inplaceILm1ELm4EEvmm.isra.0>:
    a670:	lui	a2,0xffb00
    a674:	slli	a6,a0,0x5
    a678:	addi	a2,a2,32 # ffb00020 <cb_interface>
    a67c:	add	a5,a2,a6
    a680:	lhu	a1,26(a5)
    a684:	lw	a3,12(a5)
    a688:	lui	a4,0xffb40
    a68c:	addi	sp,sp,-16
    a690:	slli	a0,a0,0xc
    a694:	addi	a4,a4,32 # ffb40020 <__ldm_bss_end+0x3f740>
    a698:	sw	s0,12(sp)
    a69c:	sw	s1,8(sp)
    a6a0:	sub	a3,a3,a1
    a6a4:	add	a4,a0,a4
    a6a8:	li	a7,3
    a6ac:	lw	a5,0(a4)
    a6b0:	add	a5,a3,a5
    a6b4:	zext.h	a5,a5
    a6b8:	bgeu	a7,a5,a6ac <.L68>
    a6bc:	ttsemwait	1,2,1
    a6c0:	add	t3,a2,a6
    a6c4:	lw	t5,28(t3) # 80001c <.LASF2126+0x7ee03c>
    a6c8:	lw	s0,20(t3)
    a6cc:	lui	t6,0x1000
    a6d0:	add	a4,s0,t5
    a6d4:	addi	a4,a4,-1
    a6d8:	slli	t1,a4,0x8
    a6dc:	lui	a7,0x45000
    a6e0:	addi	t6,t6,-256 # ffff00 <.LASF2126+0xfedf20>
    a6e4:	srli	a4,a4,0x10
    a6e8:	lui	a5,0xffe40
    a6ec:	mv	a5,a5
    a6f0:	addi	t0,a7,24 # 45000018 <__device_print_strings_info_end+0x3eb00018>
    a6f4:	slli	a4,a4,0x8
    a6f8:	lui	t4,0x800
    a6fc:	and	t1,t1,t6
    a700:	lui	t2,0x508c0
    a704:	lw	a3,8(t3)
    a708:	or	s1,a4,t4
    a70c:	sw	t2,0(a5) # ffe40000 <__instrn_buffer>
    a710:	addi	a7,a7,25
    a714:	add	t1,t1,t0
    a718:	add	s1,s1,a7
    a71c:	sw	t1,0(a5)
    a720:	sw	s1,0(a5)
    a724:	add	t5,t5,a3
    a728:	ttstallwait	128,1
    a72c:	ttwrcfg	12,0,69
    a730:	add	a4,a4,a7
    a734:	sw	a4,0(a5)
    a738:	ttdmanop
    a73c:	ttmop	1,0,0
    a740:	ttsetadczw	4,0,0,0,0,5
    a744:	addi	a4,s0,-1 # 508bffff <__device_print_strings_info_end+0x4a3bffff>
    a748:	add	t1,t5,a4
    a74c:	addi	s1,t2,1 # 508c0001 <__device_print_strings_info_end+0x4a3c0001>
    a750:	sw	s1,0(a5)
    a754:	slli	s1,t1,0x8
    a758:	and	s1,s1,t6
    a75c:	srli	t1,t1,0x10
    a760:	add	s1,s1,t0
    a764:	slli	t1,t1,0x8
    a768:	sw	s1,0(a5)
    a76c:	or	s1,t1,t4
    a770:	add	s1,s1,a7
    a774:	add	t5,a3,t5
    a778:	sw	s1,0(a5)
    a77c:	ttstallwait	128,1
    a780:	ttwrcfg	12,0,69
    a784:	add	t1,t1,a7
    a788:	sw	t1,0(a5)
    a78c:	ttdmanop
    a790:	ttmop	1,0,0
    a794:	ttsetadczw	4,0,0,0,0,5
    a798:	add	a4,t5,a4
    a79c:	slli	t1,a4,0x8
    a7a0:	srli	a4,a4,0x10
    a7a4:	addi	s1,t2,2
    a7a8:	and	t1,t1,t6
    a7ac:	slli	a4,a4,0x8
    a7b0:	sw	s1,0(a5)
    a7b4:	add	t1,t1,t0
    a7b8:	or	s1,a4,t4
    a7bc:	sw	t1,0(a5)
    a7c0:	add	s1,s1,a7
    a7c4:	add	t1,s0,a3
    a7c8:	sw	s1,0(a5)
    a7cc:	ttstallwait	128,1
    a7d0:	ttwrcfg	12,0,69
    a7d4:	add	a4,a4,a7
    a7d8:	sw	a4,0(a5)
    a7dc:	ttdmanop
    a7e0:	ttmop	1,0,0
    a7e4:	ttsetadczw	4,0,0,0,0,5
    a7e8:	addi	a4,t1,-1 # 508bffff <__device_print_strings_info_end+0x4a3bffff>
    a7ec:	add	a4,a4,t5
    a7f0:	slli	t5,a4,0x8
    a7f4:	srli	a4,a4,0x10
    a7f8:	addi	t2,t2,3
    a7fc:	and	t5,t5,t6
    a800:	slli	a4,a4,0x8
    a804:	sw	t2,0(a5)
    a808:	add	t5,t5,t0
    a80c:	or	t4,a4,t4
    a810:	sw	t5,0(a5)
    a814:	add	t4,t4,a7
    a818:	sw	t4,0(a5)
    a81c:	ttstallwait	128,1
    a820:	ttwrcfg	12,0,69
    a824:	add	a4,a4,a7
    a828:	sw	a4,0(a5)
    a82c:	ttdmanop
    a830:	ttmop	1,0,0
    a834:	ttsetadczw	4,0,0,0,0,5
    a838:	sh1add	a3,a3,a3
    a83c:	lw	a4,4(t3)
    a840:	add	a3,a3,t1
    a844:	sw	a3,20(t3)
    a848:	sw	zero,28(t3)
    a84c:	bltu	a3,a4,a85c <.L69>
    a850:	lw	a4,0(t3)
    a854:	sub	a3,a3,a4
    a858:	sw	a3,20(t3)
    a85c:	addi	a1,a1,4
    a860:	lui	a3,0x45000
    a864:	zext.h	a1,a1
    a868:	add	a2,a2,a6
    a86c:	slli	a4,a1,0x8
    a870:	addi	a3,a3,48 # 45000030 <__device_print_strings_info_end+0x3eb00030>
    a874:	sh	a1,26(a2)
    a878:	add	a4,a4,a3
    a87c:	sw	a4,0(a5)
    a880:	ttstallwait	32,8
    a884:	lui	a3,0x3fed0
    a888:	srli	a4,a0,0x2
    a88c:	addi	a3,a3,10 # 3fed000a <__device_print_strings_info_end+0x399d000a>
    a890:	add	a4,a4,a3
    a894:	lui	a3,0x40
    a898:	addi	a3,a3,-1 # 3ffff <.LASF2126+0x2e01f>
    a89c:	and	a4,a4,a3
    a8a0:	lui	a3,0x67600
    a8a4:	add	a4,a4,a3
    a8a8:	sw	a4,0(a5)
    a8ac:	ttstallwait	64,8
    a8b0:	lw	a3,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a8b4:	lui	a2,0x10144
    a8b8:	andi	a4,a3,1
    a8bc:	add	a4,a4,a2
    a8c0:	sw	a4,0(a5)
    a8c4:	ttsemget	2
    a8c8:	li	a2,1
    a8cc:	sub	a4,a2,a3
    a8d0:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    a8d4:	lui	a4,0xb0048
    a8d8:	addi	a4,a4,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    a8dc:	beq	a3,a2,a8e8 <.L70>
    a8e0:	lui	a4,0xb0088
    a8e4:	addi	a4,a4,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    a8e8:	sw	a4,0(a5)
    a8ec:	ttdmanop
    a8f0:	ttdmanop
    a8f4:	lw	s0,12(sp)
    a8f8:	lw	s1,8(sp)
    a8fc:	addi	sp,sp,16
    a900:	ret
0000a904 <memcpy>:
    a904:	xor	a5,a1,a0
    a908:	andi	a5,a5,3
    a90c:	sltiu	a4,a2,4
    a910:	snez	a5,a5
    a914:	or	a5,a5,a4
    a918:	add	a2,a0,a2
    a91c:	bnez	a5,a980 <.L26>
    a920:	andi	a5,a0,3
    a924:	mv	a4,a0
    a928:	bnez	a5,a9fc <.L8>
    a92c:	andi	a6,a2,-4
    a930:	sub	a3,a6,a4
    a934:	li	a5,32
    a938:	blt	a5,a3,a9a0 <.L9>
    a93c:	mv	a3,a1
    a940:	mv	a5,a4
    a944:	bgeu	a4,a6,a978 <.L11>
    a948:	lw	a7,0(a3) # 67600000 <__device_print_strings_info_end+0x61100000>
    a94c:	addi	a5,a5,4
    a950:	sw	a7,-4(a5)
    a954:	addi	a3,a3,4
    a958:	bltu	a5,a6,a948 <.L10>
    a95c:	addi	a6,a6,-1 # 7fffff <.LASF2126+0x7ee01f>
    a960:	sub	a6,a6,a4
    a964:	andi	a6,a6,-4
    a968:	addi	a1,a1,4
    a96c:	addi	a4,a4,4
    a970:	add	a1,a1,a6
    a974:	add	a4,a4,a6
    a978:	bltu	a4,a2,a988 <.L5>
    a97c:	ret
    a980:	mv	a4,a0
    a984:	bgeu	a0,a2,a97c <.L16>
    a988:	lbu	a5,0(a1)
    a98c:	addi	a4,a4,1
    a990:	sb	a5,-1(a4)
    a994:	addi	a1,a1,1
    a998:	bne	a2,a4,a988 <.L5>
    a99c:	ret
    a9a0:	lw	a3,0(a1)
    a9a4:	lw	t0,4(a1)
    a9a8:	lw	t6,8(a1)
    a9ac:	lw	t5,12(a1)
    a9b0:	lw	t4,16(a1)
    a9b4:	lw	t3,20(a1)
    a9b8:	lw	t1,24(a1)
    a9bc:	lw	a7,28(a1)
    a9c0:	sw	a3,0(a4)
    a9c4:	lw	a3,32(a1)
    a9c8:	addi	a4,a4,36
    a9cc:	sw	a3,-4(a4)
    a9d0:	sw	t0,-32(a4)
    a9d4:	sub	a3,a6,a4
    a9d8:	sw	t6,-28(a4)
    a9dc:	sw	t5,-24(a4)
    a9e0:	sw	t4,-20(a4)
    a9e4:	sw	t3,-16(a4)
    a9e8:	sw	t1,-12(a4)
    a9ec:	sw	a7,-8(a4)
    a9f0:	addi	a1,a1,36
    a9f4:	blt	a5,a3,a9a0 <.L9>
    a9f8:	j	a93c <.L12>
    a9fc:	lbu	a5,0(a1)
    aa00:	addi	a4,a4,1
    aa04:	sb	a5,-1(a4)
    aa08:	andi	a5,a4,3
    aa0c:	addi	a1,a1,1
    aa10:	beqz	a5,a92c <.L7>
    aa14:	lbu	a5,0(a1)
    aa18:	addi	a4,a4,1
    aa1c:	sb	a5,-1(a4)
    aa20:	andi	a5,a4,3
    aa24:	addi	a1,a1,1
    aa28:	bnez	a5,a9fc <.L8>
    aa2c:	j	a92c <.L7>

######## BRISC (writer) — kernel=writer_decode_all ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/writer_decode_all/16310776386780280687/brisc/brisc.elf:     file format elf32-littleriscv
00004b60 <_start>:
    4b60:	addi	sp,sp,-256
    4b64:	sw	ra,252(sp)
    4b68:	sw	s0,248(sp)
    4b6c:	sw	s1,244(sp)
    4b70:	sw	s4,232(sp)
    4b74:	lui	a5,0xffb01
    4b78:	addi	a5,a5,-912 # ffb00c70 <__ldm_bss_end+0x10>
    4b7c:	addi	a4,gp,1136 # ffb00c60 <__ldm_bss_end>
    4b80:	bltu	a4,a5,4b9c <.L25>
    4b84:	sw	zero,-4(a5)
    4b88:	sw	zero,-8(a5)
    4b8c:	sw	zero,-12(a5)
    4b90:	sw	zero,-16(a5)
    4b94:	addi	a5,a5,16
    4b98:	bgeu	a4,a5,4b84 <.L26>
    4b9c:	addi	a3,a5,-8
    4ba0:	bltu	a4,a3,59e8 <.L136>
    4ba4:	sw	zero,-12(a5)
    4ba8:	sw	zero,-16(a5)
    4bac:	addi	a3,a5,-4
    4bb0:	bltu	a4,a3,4bb8 <.L28>
    4bb4:	sw	zero,-8(a5)
    4bb8:	lui	a4,0x6
    4bbc:	addi	a4,a4,-400 # 5e70 <__kernel_data_lma>
    4bc0:	addi	a5,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4bc4:	beq	a4,a5,4c40 <.L30>
    4bc8:	lui	a2,0xffb01
    4bcc:	addi	a2,a2,-928 # ffb00c60 <__ldm_bss_end>
    4bd0:	sub	a2,a2,a5
    4bd4:	li	a1,8
    4bd8:	srai	a3,a2,0x2
    4bdc:	bge	a1,a2,4c24 <.L31>
    4be0:	mv	a2,a5
    4be4:	li	a6,2
    4be8:	mv	a5,a4
    4bec:	mv	a4,a2
    4bf0:	lw	a0,0(a5)
    4bf4:	lw	a1,4(a5)
    4bf8:	lw	a2,8(a5)
    4bfc:	addi	a5,a5,12
    4c00:	addi	a4,a4,12
    4c04:	addi	a3,a3,-3
    4c08:	sw	a0,-12(a4)
    4c0c:	sw	a1,-8(a4)
    4c10:	sw	a2,-4(a4)
    4c14:	blt	a6,a3,4bf0 <.L32>
    4c18:	mv	a2,a4
    4c1c:	mv	a4,a5
    4c20:	mv	a5,a2
    4c24:	blez	a3,4c40 <.L30>
    4c28:	lw	a1,0(a4)
    4c2c:	li	a2,2
    4c30:	sw	a1,0(a5)
    4c34:	bne	a3,a2,4c40 <.L30>
    4c38:	lw	a4,4(a4)
    4c3c:	sw	a4,4(a5)
    4c40:	lui	a5,0xffb30
    4c44:	lw	t3,520(a5) # ffb30208 <__ldm_bss_end+0x2f5a8>
    4c48:	lw	t1,552(a5)
    4c4c:	lw	a7,516(a5)
    4c50:	lw	a6,512(a5)
    4c54:	lw	a0,556(a5)
    4c58:	lw	a2,1056(zero) # 420 <.LVUS114+0x1>
    4c5c:	addi	t5,gp,-1976 # ffb00038 <noc_reads_num_issued>
    4c60:	addi	a3,gp,-1984 # ffb00030 <noc_nonposted_writes_num_issued>
    4c64:	addi	a4,gp,-1992 # ffb00028 <noc_nonposted_writes_acked>
    4c68:	addi	s1,gp,-2000 # ffb00020 <noc_nonposted_atomics_acked>
    4c6c:	sw	a0,-2004(gp) # ffb0001c <noc_posted_writes_num_issued+0x4>
    4c70:	sw	t3,4(t5)
    4c74:	slli	a2,a2,0x2
    4c78:	lbu	a5,1011(a2)
    4c7c:	sw	t1,4(a3)
    4c80:	sw	a7,4(a4)
    4c84:	sw	a6,4(s1)
    4c88:	li	a1,128
    4c8c:	addi	a2,a2,96
    4c90:	beq	a5,a1,4ca0 <.L36>
    4c94:	fence
    4c98:	lbu	a5,915(a2)
    4c9c:	bne	a5,a1,4c94 <.L34>
    4ca0:	addi	a2,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4ca4:	lw	a1,4(a2)
    4ca8:	sw	a1,100(sp)
    4cac:	lw	a1,12(a2)
    4cb0:	lw	t6,-2012(gp) # ffb00014 <rta_l1_base>
    4cb4:	sw	a1,108(sp)
    4cb8:	lw	a1,20(a2)
    4cbc:	lw	t1,24(a2)
    4cc0:	lw	a7,28(a2)
    4cc4:	sw	a1,116(sp)
    4cc8:	lw	a1,40(a2)
    4ccc:	lw	t3,20(t6)
    4cd0:	lw	s4,0(t6)
    4cd4:	lw	s0,28(t6)
    4cd8:	sw	t1,120(sp)
    4cdc:	lw	t1,24(t6)
    4ce0:	sw	a7,124(sp)
    4ce4:	lw	a7,36(t6)
    4ce8:	sw	a1,136(sp)
    4cec:	lw	a1,40(t6)
    4cf0:	lw	a0,0(a2)
    4cf4:	lw	a6,32(a2)
    4cf8:	sw	a0,96(sp)
    4cfc:	lw	a0,8(a2)
    4d00:	sw	t3,4(sp)
    4d04:	sw	a0,104(sp)
    4d08:	lw	a0,16(a2)
    4d0c:	sw	a6,128(sp)
    4d10:	sw	a0,112(sp)
    4d14:	lw	a0,36(a2)
    4d18:	sw	a1,8(sp)
    4d1c:	lw	a1,44(t6)
    4d20:	sw	a0,132(sp)
    4d24:	addi	t4,sp,144
    4d28:	addi	t2,sp,168
    4d2c:	sw	a1,12(sp)
    4d30:	lw	a1,48(t6)
    4d34:	lw	a5,-980(gp) # ffb0041c <sem_l1_base>
    4d38:	lw	a2,44(a2)
    4d3c:	sw	a2,140(sp)
    4d40:	mv	a2,t4
    4d44:	sw	a1,16(sp)
    4d48:	addi	a1,t6,64
    4d4c:	lw	a0,0(a1)
    4d50:	addi	a2,a2,4
    4d54:	sw	a0,-4(a2)
    4d58:	addi	a1,a1,4
    4d5c:	bne	t2,a2,4d4c <.L35>
    4d60:	beqz	s4,55ac <.L122>
    4d64:	li	a2,-1
    4d68:	beq	a7,a2,55e8 <.L225>
    4d6c:	srli	a1,a7,0x6
    4d70:	srli	a2,a7,0x5
    4d74:	or	a2,a2,a1
    4d78:	srli	a1,a2,0x2
    4d7c:	or	a2,a2,a1
    4d80:	addi	t3,a2,1
    4d84:	li	a2,4
    4d88:	minu	t3,t3,a2
    4d8c:	slli	t0,t3,0x5
    4d90:	add	a2,a7,t0
    4d94:	remu	a0,a2,t0
    4d98:	li	a1,15
    4d9c:	sub	a2,a2,a0
    4da0:	divu	a6,a2,t0
    4da4:	bgeu	a1,a6,55c8 <.L226>
    4da8:	sw	s5,228(sp)
    4dac:	sw	s11,204(sp)
    4db0:	mv	a0,t2
    4db4:	mv	s11,t2
    4db8:	sw	s2,240(sp)
    4dbc:	sw	s3,236(sp)
    4dc0:	sw	s6,224(sp)
    4dc4:	sw	s7,220(sp)
    4dc8:	sw	s8,216(sp)
    4dcc:	sw	s9,212(sp)
    4dd0:	sw	s10,208(sp)
    4dd4:	li	t2,0
    4dd8:	li	s5,0
    4ddc:	li	a1,0
    4de0:	li	s0,6
    4de4:	j	4dfc <.L42>
    4de8:	li	a2,-1
    4dec:	sw	a2,0(a0)
    4df0:	addi	t4,t4,4
    4df4:	addi	a0,a0,4
    4df8:	beq	a1,s0,4e20 <.L227>
    4dfc:	lw	a2,0(t4)
    4e00:	addi	a1,a1,1
    4e04:	bgeu	a2,a6,4de8 <.L138>
    4e08:	sw	a2,0(a0)
    4e0c:	addi	s5,s5,1
    4e10:	mv	t2,a1
    4e14:	addi	t4,t4,4
    4e18:	addi	a0,a0,4
    4e1c:	bne	a1,s0,4dfc <.L42>
    4e20:	lui	t4,0xffb45
    4e24:	lw	a0,40(t4) # ffb45028 <__ldm_bss_end+0x443c8>
    4e28:	lui	a6,0xffb00
    4e2c:	sw	t2,76(sp)
    4e30:	zext.h	a0,a0
    4e34:	addi	a6,a6,1064 # ffb00428 <cb_interface>
    4e38:	fence
    4e3c:	lw	a1,32(t4)
    4e40:	lw	a2,172(a6)
    4e44:	add	a2,a2,a1
    4e48:	zext.h	a2,a2
    4e4c:	beq	a2,a0,4e38 <.L43>
    4e50:	addi	a0,gp,-2024 # ffb00008 <my_x>
    4e54:	addi	a1,gp,-2028 # ffb00004 <my_y>
    4e58:	lbu	a2,1(a1)
    4e5c:	sw	a1,40(sp)
    4e60:	lbu	a1,1(a0)
    4e64:	sw	a0,36(sp)
    4e68:	slli	a1,a1,0x4
    4e6c:	slli	a2,a2,0xa
    4e70:	lw	a0,180(a6)
    4e74:	or	t4,a2,a1
    4e78:	lui	a1,0xffb31
    4e7c:	lw	a2,-1984(a1) # ffb30840 <__ldm_bss_end+0x2fbe0>
    4e80:	bnez	a2,4e7c <.L44>
    4e84:	sw	zero,-2044(a1)
    4e88:	srli	a2,t4,0x4
    4e8c:	sw	a2,-2040(a1)
    4e90:	lui	s0,0x3
    4e94:	li	a2,512
    4e98:	sw	a2,-2016(a1)
    4e9c:	addi	s0,s0,704 # 32c0 <.LASF471+0x4>
    4ea0:	addi	s3,a0,1024
    4ea4:	mv	t4,a0
    4ea8:	lui	a1,0xffb31
    4eac:	li	s2,1
    4eb0:	lw	a2,-1984(a1) # ffb30840 <__ldm_bss_end+0x2fbe0>
    4eb4:	bnez	a2,4eb0 <.L45>
    4eb8:	lw	a2,4(t5)
    4ebc:	sw	t4,-2036(a1)
    4ec0:	sw	s0,-2048(a1)
    4ec4:	addi	a2,a2,1
    4ec8:	sw	s2,-1984(a1)
    4ecc:	addi	t4,t4,512
    4ed0:	sw	a2,4(t5)
    4ed4:	bne	t4,s3,4eb0 <.L45>
    4ed8:	lui	t4,0xffb30
    4edc:	lw	a1,520(t4) # ffb30208 <__ldm_bss_end+0x2f5a8>
    4ee0:	bne	a2,a1,4edc <.L47>
    4ee4:	fence
    4ee8:	lui	a1,0x3f804
    4eec:	addi	t4,a0,32
    4ef0:	mv	a2,a0
    4ef4:	addi	a1,a1,-128 # 3f803f80 <__device_print_strings_info_end+0x39303f80>
    4ef8:	sw	a1,0(a2)
    4efc:	addi	a2,a2,4
    4f00:	bne	t4,a2,4ef8 <.L48>
    4f04:	lui	a1,0x3f804
    4f08:	addi	a2,a0,512
    4f0c:	addi	a1,a1,-128 # 3f803f80 <__device_print_strings_info_end+0x39303f80>
    4f10:	addi	a0,a0,544
    4f14:	sw	a1,0(a2)
    4f18:	addi	a2,a2,4
    4f1c:	bne	a0,a2,4f14 <.L49>
    4f20:	lui	a0,0xffb45
    4f24:	lw	a1,40(a0) # ffb45028 <__ldm_bss_end+0x443c8>
    4f28:	lw	a2,168(a6)
    4f2c:	addi	a1,a1,1
    4f30:	sw	a1,40(a0)
    4f34:	lw	a0,180(a6)
    4f38:	lw	a1,164(a6)
    4f3c:	add	a2,a2,a0
    4f40:	sw	a2,180(a6)
    4f44:	bne	a2,a1,4f54 <.L50>
    4f48:	lw	a1,160(a6)
    4f4c:	sub	a2,a2,a1
    4f50:	sw	a2,180(a6)
    4f54:	lui	t4,0xffb4c
    4f58:	lw	a0,40(t4) # ffb4c028 <__ldm_bss_end+0x4b3c8>
    4f5c:	zext.h	a0,a0
    4f60:	fence
    4f64:	lw	a1,32(t4)
    4f68:	lw	a2,396(a6)
    4f6c:	add	a2,a2,a1
    4f70:	zext.h	a2,a2
    4f74:	beq	a2,a0,4f60 <.L51>
    4f78:	lw	a2,40(sp)
    4f7c:	lw	a1,36(sp)
    4f80:	lbu	a2,1(a2)
    4f84:	lbu	a1,1(a1)
    4f88:	slli	a2,a2,0xa
    4f8c:	slli	a1,a1,0x4
    4f90:	lw	t4,404(a6)
    4f94:	or	a0,a2,a1
    4f98:	lui	a1,0xffb31
    4f9c:	lw	a2,-1984(a1) # ffb30840 <__ldm_bss_end+0x2fbe0>
    4fa0:	bnez	a2,4f9c <.L52>
    4fa4:	sw	zero,-2044(a1)
    4fa8:	srli	a2,a0,0x4
    4fac:	sw	a2,-2040(a1)
    4fb0:	lui	s0,0x3
    4fb4:	li	a2,512
    4fb8:	sw	a2,-2016(a1)
    4fbc:	addi	s0,s0,704 # 32c0 <.LASF471+0x4>
    4fc0:	addi	s3,t4,1024
    4fc4:	lui	a1,0xffb31
    4fc8:	li	s2,1
    4fcc:	lw	a2,-1984(a1) # ffb30840 <__ldm_bss_end+0x2fbe0>
    4fd0:	bnez	a2,4fcc <.L53>
    4fd4:	lw	a0,4(t5)
    4fd8:	sw	t4,-2036(a1)
    4fdc:	sw	s0,-2048(a1)
    4fe0:	addi	a0,a0,1
    4fe4:	sw	s2,-1984(a1)
    4fe8:	addi	t4,t4,512
    4fec:	sw	a0,4(t5)
    4ff0:	bne	t4,s3,4fcc <.L53>
    4ff4:	lui	t4,0xffb30
    4ff8:	lw	a1,520(t4) # ffb30208 <__ldm_bss_end+0x2f5a8>
    4ffc:	bne	a0,a1,4ff8 <.L55>
    5000:	fence
    5004:	lui	t4,0xffb4c
    5008:	lw	a0,40(t4) # ffb4c028 <__ldm_bss_end+0x4b3c8>
    500c:	lw	a1,392(a6)
    5010:	addi	a0,a0,1
    5014:	sw	a0,40(t4)
    5018:	lw	t4,404(a6)
    501c:	lw	a0,388(a6)
    5020:	add	a1,a1,t4
    5024:	sw	a1,404(a6)
    5028:	bne	a1,a0,5038 <.L56>
    502c:	lw	a0,384(a6)
    5030:	sub	a1,a1,a0
    5034:	sw	a1,404(a6)
    5038:	lui	t4,0xffb4b
    503c:	lw	a0,40(t4) # ffb4b028 <__ldm_bss_end+0x4a3c8>
    5040:	zext.h	a0,a0
    5044:	fence
    5048:	lw	t2,32(t4)
    504c:	lw	a1,364(a6)
    5050:	add	a1,a1,t2
    5054:	zext.h	a1,a1
    5058:	beq	a1,a0,5044 <.L57>
    505c:	lw	a0,372(a6)
    5060:	lui	t4,0x4
    5064:	addi	s0,a0,512
    5068:	mv	a1,a0
    506c:	addi	t4,t4,-128 # 3f80 <.LLST1152+0x2>
    5070:	sh	t4,0(a1)
    5074:	addi	a1,a1,32
    5078:	bne	s0,a1,5070 <.L58>
    507c:	lui	t4,0x4
    5080:	addi	a1,a0,1024
    5084:	addi	t4,t4,-128 # 3f80 <.LLST1152+0x2>
    5088:	addi	a0,a0,1536
    508c:	sh	t4,0(a1)
    5090:	addi	a1,a1,32
    5094:	bne	a0,a1,508c <.L59>
    5098:	lui	t4,0xffb4b
    509c:	lw	a0,40(t4) # ffb4b028 <__ldm_bss_end+0x4a3c8>
    50a0:	lw	a1,360(a6)
    50a4:	addi	a0,a0,1
    50a8:	sw	a0,40(t4)
    50ac:	lw	t4,372(a6)
    50b0:	lw	a0,356(a6)
    50b4:	add	a1,a1,t4
    50b8:	sw	a1,372(a6)
    50bc:	bne	a1,a0,50cc <.L60>
    50c0:	lw	a0,352(a6)
    50c4:	sub	a1,a1,a0
    50c8:	sw	a1,372(a6)
    50cc:	lui	a0,0xffb43
    50d0:	remu	a1,a7,t0
    50d4:	lw	a7,40(a0) # ffb43028 <__ldm_bss_end+0x423c8>
    50d8:	sw	a1,72(sp)
    50dc:	srli	s0,a1,0x5
    50e0:	fence
    50e4:	lw	t4,32(a0)
    50e8:	lw	a1,108(a6)
    50ec:	add	a1,a1,t4
    50f0:	sub	a1,a1,a7
    50f4:	zext.h	a1,a1
    50f8:	blt	a1,t3,50e0 <.L61>
    50fc:	lw	a0,40(sp)
    5100:	lw	t0,112(a6)
    5104:	lbu	a7,1(a0)
    5108:	lw	a0,36(sp)
    510c:	addi	a1,s0,1
    5110:	lbu	a0,1(a0)
    5114:	slli	a1,a1,0xa
    5118:	add	t4,a1,t0
    511c:	slli	a7,a7,0xa
    5120:	slli	a0,a0,0x4
    5124:	or	a0,a7,a0
    5128:	sltu	a1,t4,a1
    512c:	add	a1,a1,a0
    5130:	sw	t4,24(sp)
    5134:	sw	a0,32(sp)
    5138:	sw	a1,28(sp)
    513c:	sw	t0,20(sp)
    5140:	bnez	s0,5670 <.L228>
    5144:	li	s8,0
    5148:	sw	a5,44(sp)
    514c:	lw	a5,72(sp)
    5150:	li	a1,0
    5154:	mv	a0,s8
    5158:	sw	a6,68(sp)
    515c:	sw	t0,64(sp)
    5160:	sw	a2,60(sp)
    5164:	sw	t3,56(sp)
    5168:	sw	t1,52(sp)
    516c:	sw	t6,48(sp)
    5170:	andi	s2,a5,31
    5174:	jal	5dc4 <_Z9fill_tileILm1024EEvmmm.constprop.0>
    5178:	addi	t5,gp,-1976 # ffb00038 <noc_reads_num_issued>
    517c:	li	a1,31
    5180:	lw	a5,44(sp)
    5184:	lw	t6,48(sp)
    5188:	lw	t1,52(sp)
    518c:	lw	t3,56(sp)
    5190:	lw	a2,60(sp)
    5194:	lw	t0,64(sp)
    5198:	lw	a6,68(sp)
    519c:	addi	a4,gp,-1992 # ffb00028 <noc_nonposted_writes_acked>
    51a0:	addi	a3,gp,-1984 # ffb00030 <noc_nonposted_writes_num_issued>
    51a4:	beq	s2,a1,5268 <.L63>
    51a8:	lw	a1,116(a6)
    51ac:	slli	a0,s8,0xa
    51b0:	add	s6,a0,a1
    51b4:	sltiu	s7,s2,15
    51b8:	addi	s3,s2,1
    51bc:	li	a1,14
    51c0:	xori	s7,s7,1
    51c4:	andi	t4,s3,15
    51c8:	bltu	a1,s2,51e8 <.L77>
    51cc:	lui	a0,0xff810
    51d0:	addi	a0,a0,-128 # ff80ff80 <__device_print_strings_info_end+0xf930ff80>
    51d4:	addi	a1,s6,512
    51d8:	addi	a7,s6,1024
    51dc:	sw	a0,0(a1)
    51e0:	addi	a1,a1,4
    51e4:	bne	a7,a1,51dc <.L76>
    51e8:	slli	a7,s7,0x9
    51ec:	addi	a1,a7,32
    51f0:	addi	a0,t4,1
    51f4:	addi	a7,a7,544
    51f8:	andi	s3,s3,1
    51fc:	add	a1,a1,s6
    5200:	add	a7,a7,s6
    5204:	srli	s2,a0,0x1
    5208:	slli	t2,s7,0x7
    520c:	bnez	s3,5238 <.L74>
    5210:	lui	s6,0xff810
    5214:	addi	s6,s6,-128 # ff80ff80 <__device_print_strings_info_end+0xf930ff80>
    5218:	addi	s9,s2,-8
    521c:	sh2add	a0,s9,a1
    5220:	sw	s6,0(a0)
    5224:	addi	a0,a0,4
    5228:	bne	a0,a1,5220 <.L79>
    522c:	addi	a1,a1,32
    5230:	beq	a1,a7,5268 <.L63>
    5234:	beqz	s3,521c <.L81>
    5238:	slli	a0,s7,0x8
    523c:	add	a0,a0,t4
    5240:	slli	s6,t2,0x1
    5244:	sub	a0,a0,s6
    5248:	addi	a0,a0,-16
    524c:	li	s10,-128
    5250:	li	s9,8
    5254:	sh1add	s6,a0,a1
    5258:	sh	s10,0(s6)
    525c:	bne	s2,s9,5210 <.L75>
    5260:	addi	a1,a1,32
    5264:	bne	a7,a1,5254 <.L82>
    5268:	lw	a1,32(sp)
    526c:	lui	a7,0xffb31
    5270:	srli	s7,a1,0x4
    5274:	lw	a1,28(sp)
    5278:	li	s3,1024
    527c:	andi	s10,a1,15
    5280:	srli	s9,a1,0x4
    5284:	mv	a1,s8
    5288:	mv	s8,s5
    528c:	mv	s5,a2
    5290:	mv	a2,a5
    5294:	addi	a5,a1,1
    5298:	li	s2,1
    529c:	addi	s6,s0,-2
    52a0:	addi	t2,t3,-1
    52a4:	beq	t3,a5,52f8 <.L87>
    52a8:	addi	t0,t0,1024
    52ac:	bltu	a5,s0,561c <.L64>
    52b0:	beq	s0,a5,5cfc <.L229>
    52b4:	beq	s0,a1,56c8 <.L230>
    52b8:	lw	a1,-1984(a7) # ffb30840 <__ldm_bss_end+0x2fbe0>
    52bc:	bnez	a1,52b8 <.L83>
    52c0:	lw	a1,24(sp)
    52c4:	sw	t0,-2036(a7)
    52c8:	sw	a1,-2048(a7)
    52cc:	sw	s10,-2044(a7)
    52d0:	lw	a1,4(t5)
    52d4:	sw	s9,-2040(a7)
    52d8:	sw	s3,-2016(a7)
    52dc:	addi	a1,a1,1
    52e0:	sw	s2,-1984(a7)
    52e4:	sw	a1,4(t5)
    52e8:	beq	t2,a5,5708 <.L231>
    52ec:	mv	a1,a5
    52f0:	addi	a5,a1,1
    52f4:	bne	t3,a5,52a8 <.L232>
    52f8:	lui	a0,0xffb43
    52fc:	lw	a1,40(a0) # ffb43028 <__ldm_bss_end+0x423c8>
    5300:	lw	a7,104(a6)
    5304:	add	a1,t3,a1
    5308:	sw	a1,40(a0)
    530c:	mul	a1,t3,a7
    5310:	lw	a7,116(a6)
    5314:	lw	a0,100(a6)
    5318:	add	a1,a1,a7
    531c:	sw	a1,116(a6)
    5320:	mv	a5,a2
    5324:	mv	a2,s5
    5328:	mv	s5,s8
    532c:	bne	a1,a0,533c <.L89>
    5330:	lw	a0,96(a6)
    5334:	sub	a1,a1,a0
    5338:	sw	a1,116(a6)
    533c:	lui	a1,0x1
    5340:	addi	a1,a1,-2048 # 800 <.LASF2442+0x2>
    5344:	lw	a7,4(a4)
    5348:	sw	s4,80(sp)
    534c:	sw	a1,88(sp)
    5350:	lui	a0,0xffb30
    5354:	lw	a1,516(a0) # ffb30204 <__ldm_bss_end+0x2f5a4>
    5358:	bne	a1,a7,5354 <.L90>
    535c:	fence
    5360:	lw	a1,4(sp)
    5364:	li	a0,-1
    5368:	beq	a1,a0,5588 <.L221>
    536c:	lw	a1,12(sp)
    5370:	addi	a0,a1,1
    5374:	lw	a1,8(sp)
    5378:	snez	a0,a0
    537c:	addi	a1,a1,-1
    5380:	snez	a1,a1
    5384:	and	a1,a0,a1
    5388:	bnez	s5,571c <.L91>
    538c:	bnez	a1,59f0 <.L233>
    5390:	lw	a1,8(sp)
    5394:	li	a5,1
    5398:	bne	a1,a5,5588 <.L221>
    539c:	lui	a1,0xffb54
    53a0:	lw	a7,32(a1) # ffb54020 <__ldm_bss_end+0x533c0>
    53a4:	li	a0,3
    53a8:	lw	a5,40(a1)
    53ac:	sub	a5,a5,a7
    53b0:	zext.h	a5,a5
    53b4:	bgeu	a0,a5,53a8 <.L123>
    53b8:	lw	a0,4(a3)
    53bc:	lui	a1,0xffb30
    53c0:	lw	a5,552(a1) # ffb30228 <__ldm_bss_end+0x2f5c8>
    53c4:	bne	a5,a0,53c0 <.L124>
    53c8:	fence
    53cc:	lw	a5,4(sp)
    53d0:	slli	s7,a5,0x3
    53d4:	lui	s1,0x92492
    53d8:	lui	t6,0x2
    53dc:	lui	t5,0x10000
    53e0:	lw	s5,656(a6)
    53e4:	addi	s6,s7,8
    53e8:	addi	s3,gp,-1492 # ffb0021c <bank_to_dram_offset>
    53ec:	addi	s2,gp,-1960 # ffb00048 <dram_bank_to_noc_xy>
    53f0:	addi	s1,s1,1171 # 92492493 <__device_print_strings_info_end+0x8bf92493>
    53f4:	addi	t6,t6,146 # 2092 <.LVUS511+0x5>
    53f8:	addi	t5,t5,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    53fc:	li	s0,0
    5400:	lui	a5,0xffb30
    5404:	li	t2,32
    5408:	li	t0,1
    540c:	li	s4,9
    5410:	li	s8,4
    5414:	mv	t4,s7
    5418:	andi	a0,t4,31
    541c:	addi	s9,a0,16
    5420:	andi	a1,t4,16
    5424:	slli	s9,s9,0x5
    5428:	srli	a7,t4,0x5
    542c:	bnez	a1,5434 <.L127>
    5430:	slli	s9,a0,0x5
    5434:	sh2add	a7,a7,s0
    5438:	sh2add	a1,t1,a7
    543c:	mulhu	t3,a1,s1
    5440:	lw	a0,88(sp)
    5444:	srli	t3,t3,0x2
    5448:	slli	s10,t3,0x3
    544c:	mul	a0,t3,a0
    5450:	sub	t3,s10,t3
    5454:	sub	a1,a1,t3
    5458:	lw	s10,80(sp)
    545c:	sh2add	t3,a1,s3
    5460:	sh1add	a1,a1,s2
    5464:	lw	t3,0(t3)
    5468:	add	a0,a0,s10
    546c:	add	a0,a0,t3
    5470:	lhu	a1,14(a1)
    5474:	slli	a7,a7,0xb
    5478:	add	t3,a0,s9
    547c:	add	a7,a7,s5
    5480:	sltu	a0,t3,a0
    5484:	slli	a1,a1,0x4
    5488:	add	a7,a7,s9
    548c:	add	a0,a0,a1
    5490:	lw	a1,64(a5) # ffb30040 <__ldm_bss_end+0x2f3e0>
    5494:	bnez	a1,5490 <.L128>
    5498:	sw	t6,28(a5)
    549c:	sw	a7,0(a5)
    54a0:	sw	t3,12(a5)
    54a4:	and	a1,a0,t5
    54a8:	sw	a1,16(a5)
    54ac:	srli	s9,a0,0x4
    54b0:	lw	s10,4(a3)
    54b4:	lw	a1,4(a4)
    54b8:	sw	s9,20(a5)
    54bc:	sw	t2,32(a5)
    54c0:	addi	s9,t3,512
    54c4:	sw	t0,64(a5)
    54c8:	addi	s10,s10,1
    54cc:	addi	a1,a1,1
    54d0:	sltu	t3,s9,t3
    54d4:	addi	a7,a7,512
    54d8:	sw	s10,4(a3)
    54dc:	sw	a1,4(a4)
    54e0:	add	t3,t3,a0
    54e4:	lw	a1,64(a5)
    54e8:	bnez	a1,54e4 <.L129>
    54ec:	sw	t6,28(a5)
    54f0:	sw	a7,0(a5)
    54f4:	sw	s9,12(a5)
    54f8:	and	a1,t3,t5
    54fc:	sw	a1,16(a5)
    5500:	srli	t3,t3,0x4
    5504:	sw	t3,20(a5)
    5508:	lw	a1,4(a3)
    550c:	lw	a0,4(a4)
    5510:	sw	t2,32(a5)
    5514:	sw	t0,64(a5)
    5518:	addi	a1,a1,1
    551c:	addi	a0,a0,1
    5520:	addi	a2,a2,1
    5524:	sw	a1,4(a3)
    5528:	sw	a0,4(a4)
    552c:	beq	a2,s4,56f4 <.L131>
    5530:	addi	t4,t4,1
    5534:	bne	t4,s6,5418 <.L132>
    5538:	addi	s0,s0,1
    553c:	bne	s0,s8,5414 <.L125>
    5540:	lw	a3,4(a4)
    5544:	lui	a4,0xffb30
    5548:	lw	a5,516(a4) # ffb30204 <__ldm_bss_end+0x2f5a4>
    554c:	bne	a5,a3,5548 <.L134>
    5550:	fence
    5554:	lui	a4,0xffb54
    5558:	lw	a5,32(a4) # ffb54020 <__ldm_bss_end+0x533c0>
    555c:	addi	a5,a5,4
    5560:	sw	a5,32(a4)
    5564:	lw	a3,656(a6)
    5568:	lw	a5,648(a6)
    556c:	lw	a4,644(a6)
    5570:	sh2add	a5,a5,a3
    5574:	sw	a5,656(a6)
    5578:	bne	a5,a4,5588 <.L221>
    557c:	lw	a4,640(a6)
    5580:	sub	a5,a5,a4
    5584:	sw	a5,656(a6)
    5588:	lw	s2,240(sp)
    558c:	lw	s3,236(sp)
    5590:	lw	s5,228(sp)
    5594:	lw	s6,224(sp)
    5598:	lw	s7,220(sp)
    559c:	lw	s8,216(sp)
    55a0:	lw	s9,212(sp)
    55a4:	lw	s10,208(sp)
    55a8:	lw	s11,204(sp)
    55ac:	lw	ra,252(sp)
    55b0:	lw	s0,248(sp)
    55b4:	lw	s1,244(sp)
    55b8:	lw	s4,232(sp)
    55bc:	li	a0,0
    55c0:	addi	sp,sp,256
    55c4:	ret
    55c8:	blt	s0,a6,4da8 <.L40>
    55cc:	lw	ra,252(sp)
    55d0:	lw	s0,248(sp)
    55d4:	lw	s1,244(sp)
    55d8:	lw	s4,232(sp)
    55dc:	li	a0,0
    55e0:	addi	sp,sp,256
    55e4:	ret
    55e8:	lui	a0,0xffb48
    55ec:	lw	a1,32(a0) # ffb48020 <__ldm_bss_end+0x473c0>
    55f0:	zext.h	a1,a1
    55f4:	lw	a2,40(a0)
    55f8:	zext.h	a2,a2
    55fc:	beq	a2,a1,55f4 <.L39>
    5600:	lui	a6,0xffb00
    5604:	lw	a2,1336(a6) # ffb00538 <cb_interface+0x110>
    5608:	li	a1,-1
    560c:	sh2add	a2,t1,a2
    5610:	lw	a7,0(a2)
    5614:	bne	a7,a1,4d6c <.L38>
    5618:	j	55ac <.L122>
    561c:	lw	a1,-1984(a7)
    5620:	bnez	a1,561c <.L64>
    5624:	lw	a1,20(sp)
    5628:	sw	t0,-2036(a7)
    562c:	sw	a1,-2048(a7)
    5630:	sw	zero,-2044(a7)
    5634:	lw	a1,4(t5)
    5638:	sw	s7,-2040(a7)
    563c:	sw	s3,-2016(a7)
    5640:	addi	a1,a1,1
    5644:	snez	a0,s6
    5648:	sw	s2,-1984(a7)
    564c:	sw	a1,4(t5)
    5650:	addi	a0,a0,1
    5654:	lui	t4,0xffb30
    5658:	bne	a0,a5,52ec <.L222>
    565c:	lw	a0,520(t4) # ffb30208 <__ldm_bss_end+0x2f5a8>
    5660:	bne	a0,a1,565c <.L65>
    5664:	fence
    5668:	mv	a1,a5
    566c:	j	52f0 <.L234>
    5670:	li	a1,0
    5674:	li	a0,0
    5678:	sw	a6,68(sp)
    567c:	sw	t0,64(sp)
    5680:	sw	a2,60(sp)
    5684:	sw	t3,56(sp)
    5688:	sw	t1,52(sp)
    568c:	sw	t6,48(sp)
    5690:	sw	a5,44(sp)
    5694:	jal	5dc4 <_Z9fill_tileILm1024EEvmmm.constprop.0>
    5698:	addi	t5,gp,-1976 # ffb00038 <noc_reads_num_issued>
    569c:	lw	a5,44(sp)
    56a0:	lw	t6,48(sp)
    56a4:	lw	t1,52(sp)
    56a8:	lw	t3,56(sp)
    56ac:	lw	a2,60(sp)
    56b0:	lw	t0,64(sp)
    56b4:	lw	a6,68(sp)
    56b8:	li	s8,0
    56bc:	addi	a4,gp,-1992 # ffb00028 <noc_nonposted_writes_acked>
    56c0:	addi	a3,gp,-1984 # ffb00030 <noc_nonposted_writes_num_issued>
    56c4:	j	5268 <.L63>
    56c8:	lw	a0,116(a6)
    56cc:	slli	a1,a5,0xa
    56d0:	add	a1,a1,a0
    56d4:	lui	a0,0xff810
    56d8:	addi	t4,a1,1024
    56dc:	addi	a0,a0,-128 # ff80ff80 <__device_print_strings_info_end+0xf930ff80>
    56e0:	sw	a0,0(a1)
    56e4:	addi	a1,a1,4
    56e8:	bne	t4,a1,56e0 <.L84>
    56ec:	mv	a1,a5
    56f0:	j	52f0 <.L234>
    56f4:	lw	a2,552(a5)
    56f8:	bne	a2,a1,56f4 <.L131>
    56fc:	fence
    5700:	li	a2,0
    5704:	j	5530 <.L130>
    5708:	lui	t4,0xffb30
    570c:	lw	a0,520(t4) # ffb30208 <__ldm_bss_end+0x2f5a8>
    5710:	bne	a0,a1,570c <.L86>
    5714:	fence
    5718:	j	5668 <.L235>
    571c:	lw	t3,76(sp)
    5720:	beqz	t3,538c <.L94>
    5724:	lui	a0,0x2
    5728:	addi	a0,a0,-2048 # 1800 <.LLST342+0x3>
    572c:	lui	a7,0x10000
    5730:	addi	t4,sp,120
    5734:	addi	a7,a7,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    5738:	sw	a0,28(sp)
    573c:	sh2add	a0,t3,t4
    5740:	sw	a7,20(sp)
    5744:	sw	a0,24(sp)
    5748:	li	s6,0
    574c:	li	s9,0
    5750:	lui	s2,0xffb47
    5754:	lui	a0,0xffb31
    5758:	li	s10,1
    575c:	lui	a7,0xffb30
    5760:	lui	s0,0xffb46
    5764:	lui	t0,0xffb50
    5768:	li	s5,3
    576c:	j	5794 <.L109>
    5770:	lw	t3,28(sp)
    5774:	addi	t4,t4,4
    5778:	add	t3,s6,t3
    577c:	sltu	s6,t3,s6
    5780:	add	s9,s6,s9
    5784:	mv	s6,t3
    5788:	lw	t3,24(sp)
    578c:	addi	s11,s11,4
    5790:	beq	t3,t4,538c <.L94>
    5794:	lw	t3,0(s11)
    5798:	li	t2,-1
    579c:	beq	t3,t2,5770 <.L96>
    57a0:	fence
    57a4:	lw	t3,0(a5)
    57a8:	lw	t2,0(t4)
    57ac:	srl	t3,t3,t2
    57b0:	andi	t3,t3,15
    57b4:	beqz	t3,57a0 <.L95>
    57b8:	lw	t2,36(sp)
    57bc:	lw	t3,40(sp)
    57c0:	lbu	s3,1(t2)
    57c4:	lbu	t3,1(t3)
    57c8:	lw	t2,624(a6)
    57cc:	slli	s3,s3,0x4
    57d0:	slli	t3,t3,0xa
    57d4:	or	t3,t3,s3
    57d8:	add	s3,t2,s6
    57dc:	sltu	t2,s3,t2
    57e0:	add	t3,t3,s9
    57e4:	add	s7,t2,t3
    57e8:	lw	t2,40(s2) # ffb47028 <__ldm_bss_end+0x463c8>
    57ec:	zext.h	t2,t2
    57f0:	fence
    57f4:	lw	s4,32(s2)
    57f8:	lw	t3,236(a6)
    57fc:	add	t3,t3,s4
    5800:	zext.h	t3,t3
    5804:	beq	t3,t2,57f0 <.L97>
    5808:	lw	t2,244(a6)
    580c:	lw	t3,-1984(a0) # ffb30840 <__ldm_bss_end+0x2fbe0>
    5810:	bnez	t3,580c <.L98>
    5814:	lw	t3,20(sp)
    5818:	sw	t2,-2036(a0)
    581c:	sw	s3,-2048(a0)
    5820:	and	t3,s7,t3
    5824:	sw	t3,-2044(a0)
    5828:	srli	t3,s7,0x4
    582c:	sw	t3,-2040(a0)
    5830:	lw	s4,4(t5)
    5834:	li	t3,1024
    5838:	sw	t3,-2016(a0)
    583c:	addi	s8,s3,1024
    5840:	addi	s4,s4,1
    5844:	sltu	t3,s8,s3
    5848:	sw	s10,-1984(a0)
    584c:	sw	s4,4(t5)
    5850:	add	t3,t3,s7
    5854:	lw	t2,520(a7) # ffb30208 <__ldm_bss_end+0x2f5a8>
    5858:	bne	t2,s4,5854 <.L99>
    585c:	fence
    5860:	lw	t2,40(s2)
    5864:	lw	s4,232(a6)
    5868:	addi	t2,t2,1
    586c:	sw	t2,40(s2)
    5870:	lw	t2,244(a6)
    5874:	add	t2,s4,t2
    5878:	lw	s4,228(a6)
    587c:	sw	t2,244(a6)
    5880:	bne	t2,s4,5890 <.L100>
    5884:	lw	s4,224(a6)
    5888:	sub	t2,t2,s4
    588c:	sw	t2,244(a6)
    5890:	lw	s4,40(s0) # ffb46028 <__ldm_bss_end+0x453c8>
    5894:	sw	a5,32(sp)
    5898:	zext.h	s4,s4
    589c:	fence
    58a0:	lw	t2,32(s0)
    58a4:	lw	a5,204(a6)
    58a8:	add	a5,a5,t2
    58ac:	zext.h	a5,a5
    58b0:	beq	a5,s4,589c <.L101>
    58b4:	lw	a5,32(sp)
    58b8:	lw	s4,212(a6)
    58bc:	lw	t2,-1984(a0)
    58c0:	bnez	t2,58bc <.L102>
    58c4:	lw	t2,20(sp)
    58c8:	sw	s4,-2036(a0)
    58cc:	sw	s8,-2048(a0)
    58d0:	and	t2,t3,t2
    58d4:	sw	t2,-2044(a0)
    58d8:	srli	t3,t3,0x4
    58dc:	lw	s4,4(t5)
    58e0:	addi	t2,s3,2047
    58e4:	sw	t3,-2040(a0)
    58e8:	li	t3,1024
    58ec:	sw	t3,-2016(a0)
    58f0:	addi	t2,t2,1
    58f4:	sltu	s3,t2,s3
    58f8:	addi	s4,s4,1
    58fc:	sw	s10,-1984(a0)
    5900:	add	s3,s3,s7
    5904:	sw	s4,4(t5)
    5908:	lw	t3,520(a7)
    590c:	bne	t3,s4,5908 <.L103>
    5910:	fence
    5914:	lw	s4,40(s0)
    5918:	lw	t3,200(a6)
    591c:	addi	s4,s4,1
    5920:	sw	s4,40(s0)
    5924:	lw	s7,212(a6)
    5928:	lw	s4,196(a6)
    592c:	add	t3,t3,s7
    5930:	sw	t3,212(a6)
    5934:	beq	t3,s4,59d8 <.L236>
    5938:	lw	s4,40(t0) # ffb50028 <__ldm_bss_end+0x4f3c8>
    593c:	fence
    5940:	lw	s7,32(t0)
    5944:	lw	t3,524(a6)
    5948:	add	t3,t3,s7
    594c:	sub	t3,t3,s4
    5950:	zext.h	t3,t3
    5954:	bgeu	s5,t3,593c <.L105>
    5958:	lw	s4,532(a6)
    595c:	lw	t3,-1984(a0)
    5960:	bnez	t3,595c <.L106>
    5964:	lw	t3,20(sp)
    5968:	sw	s4,-2036(a0)
    596c:	sw	t2,-2048(a0)
    5970:	and	t3,s3,t3
    5974:	sw	t3,-2044(a0)
    5978:	srli	s3,s3,0x4
    597c:	lw	t2,4(t5)
    5980:	lui	t3,0x1
    5984:	sw	s3,-2040(a0)
    5988:	sw	t3,-2016(a0)
    598c:	addi	t2,t2,1
    5990:	sw	s10,-1984(a0)
    5994:	sw	t2,4(t5)
    5998:	lw	t3,520(a7)
    599c:	bne	t3,t2,5998 <.L107>
    59a0:	fence
    59a4:	lw	t2,40(t0)
    59a8:	lw	t3,520(a6)
    59ac:	addi	t2,t2,4
    59b0:	sw	t2,40(t0)
    59b4:	lw	s3,532(a6)
    59b8:	lw	t2,516(a6)
    59bc:	sh2add	t3,t3,s3
    59c0:	sw	t3,532(a6)
    59c4:	bne	t3,t2,5770 <.L96>
    59c8:	lw	t2,512(a6)
    59cc:	sub	t3,t3,t2
    59d0:	sw	t3,532(a6)
    59d4:	j	5770 <.L96>
    59d8:	lw	s4,192(a6)
    59dc:	sub	t3,t3,s4
    59e0:	sw	t3,212(a6)
    59e4:	j	5938 <.L104>
    59e8:	mv	a5,a3
    59ec:	j	4bac <.L27>
    59f0:	lui	a1,0xffb50
    59f4:	lw	a7,32(a1) # ffb50020 <__ldm_bss_end+0x4f3c0>
    59f8:	li	a0,3
    59fc:	lw	a2,40(a1)
    5a00:	sub	a2,a2,a7
    5a04:	zext.h	a2,a2
    5a08:	bgeu	a0,a2,59fc <.L110>
    5a0c:	lui	a0,0xffb51
    5a10:	lw	a2,32(a0) # ffb51020 <__ldm_bss_end+0x503c0>
    5a14:	zext.h	a2,a2
    5a18:	lw	a1,40(a0)
    5a1c:	zext.h	a1,a1
    5a20:	beq	a2,a1,5a18 <.L111>
    5a24:	lui	a0,0xffb52
    5a28:	lw	a2,32(a0) # ffb52020 <__ldm_bss_end+0x513c0>
    5a2c:	zext.h	a2,a2
    5a30:	lw	a1,40(a0)
    5a34:	zext.h	a1,a1
    5a38:	beq	a2,a1,5a30 <.L112>
    5a3c:	lw	a2,12(sp)
    5a40:	lw	a1,16(sp)
    5a44:	sh2add	a2,a2,t6
    5a48:	lw	t1,152(a2)
    5a4c:	lw	a7,88(a2)
    5a50:	sh1add	a2,a1,a1
    5a54:	lw	a0,628(a6)
    5a58:	slli	a2,a2,0xb
    5a5c:	add	a2,a0,a2
    5a60:	sltu	t3,a2,a0
    5a64:	lw	t4,592(a6)
    5a68:	lui	a0,0xffb30
    5a6c:	slli	a1,t1,0xa
    5a70:	slli	a7,a7,0x4
    5a74:	or	a1,a1,a7
    5a78:	add	t3,t3,a1
    5a7c:	lw	a7,64(a0) # ffb30040 <__ldm_bss_end+0x2f3e0>
    5a80:	bnez	a7,5a7c <.L113>
    5a84:	lui	a7,0x2
    5a88:	addi	a7,a7,146 # 2092 <.LVUS511+0x5>
    5a8c:	sw	a7,28(a0)
    5a90:	lui	a7,0x10000
    5a94:	sw	t4,0(a0)
    5a98:	addi	a7,a7,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    5a9c:	sw	a2,12(a0)
    5aa0:	and	a7,t3,a7
    5aa4:	slli	t1,t3,0x4
    5aa8:	sw	a7,16(a0)
    5aac:	srli	a7,t1,0x8
    5ab0:	sw	a7,20(a0)
    5ab4:	li	a7,1024
    5ab8:	sw	a7,32(a0)
    5abc:	li	a7,1
    5ac0:	sw	a7,64(a0)
    5ac4:	lw	t1,4(a3)
    5ac8:	lw	a0,4(a4)
    5acc:	addi	t4,a2,1024
    5ad0:	add	a0,a0,a7
    5ad4:	add	t1,t1,a7
    5ad8:	lw	t5,560(a6)
    5adc:	sltu	a7,t4,a2
    5ae0:	sw	a0,4(a4)
    5ae4:	sw	t1,4(a3)
    5ae8:	add	a7,a7,t3
    5aec:	lui	a0,0xffb30
    5af0:	lw	t1,64(a0) # ffb30040 <__ldm_bss_end+0x2f3e0>
    5af4:	bnez	t1,5af0 <.L114>
    5af8:	lui	t1,0x2
    5afc:	addi	t1,t1,146 # 2092 <.LVUS511+0x5>
    5b00:	sw	t1,28(a0)
    5b04:	lui	t1,0x10000
    5b08:	sw	t5,0(a0)
    5b0c:	addi	t1,t1,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    5b10:	sw	t4,12(a0)
    5b14:	and	t1,a7,t1
    5b18:	sw	t1,16(a0)
    5b1c:	slli	t1,a7,0x4
    5b20:	srli	a7,t1,0x8
    5b24:	sw	a7,20(a0)
    5b28:	li	a7,1024
    5b2c:	sw	a7,32(a0)
    5b30:	lw	t4,4(a3)
    5b34:	lw	a7,4(a4)
    5b38:	li	t5,1
    5b3c:	addi	t1,a2,2047
    5b40:	sw	t5,64(a0)
    5b44:	add	t1,t1,t5
    5b48:	addi	a0,a7,1
    5b4c:	sltu	a2,t1,a2
    5b50:	addi	t4,t4,1
    5b54:	lw	t5,528(a6)
    5b58:	sw	a0,4(a4)
    5b5c:	add	a2,a2,t3
    5b60:	sw	t4,4(a3)
    5b64:	lui	a0,0xffb30
    5b68:	lw	a7,64(a0) # ffb30040 <__ldm_bss_end+0x2f3e0>
    5b6c:	bnez	a7,5b68 <.L115>
    5b70:	lui	a7,0x2
    5b74:	addi	a7,a7,146 # 2092 <.LVUS511+0x5>
    5b78:	sw	a7,28(a0)
    5b7c:	lui	a7,0x10000
    5b80:	sw	t5,0(a0)
    5b84:	addi	a7,a7,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    5b88:	sw	t1,12(a0)
    5b8c:	and	a7,a2,a7
    5b90:	sw	a7,16(a0)
    5b94:	slli	a7,a2,0x4
    5b98:	lw	t1,4(a3)
    5b9c:	srli	a2,a7,0x8
    5ba0:	lw	a7,4(a4)
    5ba4:	lui	t3,0x1
    5ba8:	sw	a2,20(a0)
    5bac:	sw	t3,32(a0)
    5bb0:	addi	a2,a7,1
    5bb4:	addi	t1,t1,1
    5bb8:	sw	a2,4(a4)
    5bbc:	li	a7,1
    5bc0:	sw	t1,4(a3)
    5bc4:	sw	a7,64(a0)
    5bc8:	lui	a4,0xffb30
    5bcc:	lw	a3,516(a4) # ffb30204 <__ldm_bss_end+0x2f5a4>
    5bd0:	bne	a3,a2,5bcc <.L116>
    5bd4:	fence
    5bd8:	lw	a4,16(sp)
    5bdc:	sh2add	a4,a4,sp
    5be0:	lw	a0,96(a4)
    5be4:	lui	a4,0xffb32
    5be8:	lw	a3,-1984(a4) # ffb31840 <__ldm_bss_end+0x30be0>
    5bec:	bnez	a3,5be8 <.L117>
    5bf0:	lui	a2,0x10000
    5bf4:	sw	a5,-2048(a4)
    5bf8:	and	a2,a1,a2
    5bfc:	slli	a3,a1,0x4
    5c00:	sw	a2,-2044(a4)
    5c04:	srli	a3,a3,0x8
    5c08:	lui	a2,0x2
    5c0c:	srli	a5,a5,0x2
    5c10:	lui	a1,0x1
    5c14:	sw	a3,-2040(a4)
    5c18:	andi	a5,a5,3
    5c1c:	addi	a3,a2,145 # 2091 <.LVUS511+0x4>
    5c20:	addi	a1,a1,124 # 107c <.LVUS228>
    5c24:	sw	a3,-2020(a4)
    5c28:	or	a5,a5,a1
    5c2c:	sw	a5,-2016(a4)
    5c30:	sw	a0,-2008(a4)
    5c34:	li	a5,1
    5c38:	sw	a5,-1984(a4)
    5c3c:	lui	a3,0xffb50
    5c40:	lw	a5,32(a3) # ffb50020 <__ldm_bss_end+0x4f3c0>
    5c44:	lw	a4,4(s1)
    5c48:	addi	a5,a5,4
    5c4c:	sw	a5,32(a3)
    5c50:	lw	a2,528(a6)
    5c54:	lw	a5,520(a6)
    5c58:	addi	a4,a4,1
    5c5c:	lw	a3,516(a6)
    5c60:	sh2add	a5,a5,a2
    5c64:	sw	a4,4(s1)
    5c68:	sw	a5,528(a6)
    5c6c:	bne	a5,a3,5c7c <.L118>
    5c70:	lw	a4,512(a6)
    5c74:	sub	a5,a5,a4
    5c78:	sw	a5,528(a6)
    5c7c:	lui	a4,0xffb51
    5c80:	lw	a5,32(a4) # ffb51020 <__ldm_bss_end+0x503c0>
    5c84:	addi	a5,a5,1
    5c88:	sw	a5,32(a4)
    5c8c:	lw	a3,560(a6)
    5c90:	lw	a5,552(a6)
    5c94:	lw	a4,548(a6)
    5c98:	add	a5,a5,a3
    5c9c:	sw	a5,560(a6)
    5ca0:	bne	a5,a4,5cb0 <.L119>
    5ca4:	lw	a4,544(a6)
    5ca8:	sub	a5,a5,a4
    5cac:	sw	a5,560(a6)
    5cb0:	lui	a4,0xffb52
    5cb4:	lw	a5,32(a4) # ffb52020 <__ldm_bss_end+0x513c0>
    5cb8:	addi	a5,a5,1
    5cbc:	sw	a5,32(a4)
    5cc0:	lw	a3,592(a6)
    5cc4:	lw	a5,584(a6)
    5cc8:	lw	a4,580(a6)
    5ccc:	add	a5,a5,a3
    5cd0:	sw	a5,592(a6)
    5cd4:	bne	a5,a4,5ce4 <.L120>
    5cd8:	lw	a4,576(a6)
    5cdc:	sub	a5,a5,a4
    5ce0:	sw	a5,592(a6)
    5ce4:	lw	a4,4(s1)
    5ce8:	lui	a5,0xffb30
    5cec:	lw	a3,512(a5) # ffb30200 <__ldm_bss_end+0x2f5a0>
    5cf0:	bne	a3,a4,5cec <.L121>
    5cf4:	fence
    5cf8:	j	5588 <.L221>
    5cfc:	mv	a5,a2
    5d00:	mv	a2,s5
    5d04:	mv	s5,s8
    5d08:	mv	s8,s0
    5d0c:	j	5148 <.L62>
00005d10 <_Z9fill_tileILm1088EEvmmm.constprop.0>:
    5d10:	slli	a5,a0,0x4
    5d14:	lui	a4,0xffb00
    5d18:	lw	a4,1500(a4) # ffb005dc <cb_interface+0x1b4>
    5d1c:	add	a5,a5,a0
    5d20:	slli	a5,a5,0x6
    5d24:	add	a5,a5,a4
    5d28:	bnez	a1,5da8 <.L2>
    5d2c:	lbu	a2,-2027(gp) # ffb00005 <my_y+0x1>
    5d30:	lbu	a4,-2023(gp) # ffb00009 <my_x+0x1>
    5d34:	slli	a2,a2,0xa
    5d38:	slli	a4,a4,0x4
    5d3c:	or	a2,a2,a4
    5d40:	lui	a0,0x3
    5d44:	srli	a2,a2,0x4
    5d48:	addi	a1,gp,-1976 # ffb00038 <noc_reads_num_issued>
    5d4c:	addi	a0,a0,704 # 32c0 <.LASF471+0x4>
    5d50:	addi	t1,a5,1024
    5d54:	lui	a3,0xffb31
    5d58:	li	a7,512
    5d5c:	li	a6,1
    5d60:	lw	a4,-1984(a3) # ffb30840 <__ldm_bss_end+0x2fbe0>
    5d64:	bnez	a4,5d60 <.L3>
    5d68:	sw	a5,-2036(a3)
    5d6c:	sw	a0,-2048(a3)
    5d70:	sw	zero,-2044(a3)
    5d74:	lw	a4,4(a1)
    5d78:	sw	a2,-2040(a3)
    5d7c:	sw	a7,-2016(a3)
    5d80:	addi	a4,a4,1
    5d84:	sw	a6,-1984(a3)
    5d88:	addi	a5,a5,512
    5d8c:	sw	a4,4(a1)
    5d90:	bne	a5,t1,5d60 <.L3>
    5d94:	lui	a3,0xffb30
    5d98:	lw	a5,520(a3) # ffb30208 <__ldm_bss_end+0x2f5a8>
    5d9c:	bne	a5,a4,5d98 <.L5>
    5da0:	fence
    5da4:	ret
    5da8:	lui	a4,0xff810
    5dac:	addi	a4,a4,-128 # ff80ff80 <__device_print_strings_info_end+0xf930ff80>
    5db0:	addi	a3,a5,1088
    5db4:	sw	a4,0(a5)
    5db8:	addi	a5,a5,4
    5dbc:	bne	a5,a3,5db4 <.L7>
    5dc0:	ret
00005dc4 <_Z9fill_tileILm1024EEvmmm.constprop.0>:
    5dc4:	lui	a5,0xffb00
    5dc8:	lw	a4,1180(a5) # ffb0049c <cb_interface+0x74>
    5dcc:	slli	a5,a0,0xa
    5dd0:	add	a5,a5,a4
    5dd4:	bnez	a1,5e54 <.L14>
    5dd8:	lbu	a2,-2027(gp) # ffb00005 <my_y+0x1>
    5ddc:	lbu	a4,-2023(gp) # ffb00009 <my_x+0x1>
    5de0:	slli	a2,a2,0xa
    5de4:	slli	a4,a4,0x4
    5de8:	or	a2,a2,a4
    5dec:	lui	a0,0x3
    5df0:	srli	a2,a2,0x4
    5df4:	addi	a1,gp,-1976 # ffb00038 <noc_reads_num_issued>
    5df8:	addi	a0,a0,704 # 32c0 <.LASF471+0x4>
    5dfc:	addi	t1,a5,1024
    5e00:	lui	a3,0xffb31
    5e04:	li	a7,512
    5e08:	li	a6,1
    5e0c:	lw	a4,-1984(a3) # ffb30840 <__ldm_bss_end+0x2fbe0>
    5e10:	bnez	a4,5e0c <.L15>
    5e14:	sw	a5,-2036(a3)
    5e18:	sw	a0,-2048(a3)
    5e1c:	sw	zero,-2044(a3)
    5e20:	lw	a4,4(a1)
    5e24:	sw	a2,-2040(a3)
    5e28:	sw	a7,-2016(a3)
    5e2c:	addi	a4,a4,1
    5e30:	sw	a6,-1984(a3)
    5e34:	addi	a5,a5,512
    5e38:	sw	a4,4(a1)
    5e3c:	bne	a5,t1,5e0c <.L15>
    5e40:	lui	a3,0xffb30
    5e44:	lw	a5,520(a3) # ffb30208 <__ldm_bss_end+0x2f5a8>
    5e48:	bne	a5,a4,5e44 <.L17>
    5e4c:	fence
    5e50:	ret
    5e54:	lui	a4,0xff810
    5e58:	addi	a4,a4,-128 # ff80ff80 <__device_print_strings_info_end+0xf930ff80>
    5e5c:	addi	a3,a5,1024
    5e60:	sw	a4,0(a5)
    5e64:	addi	a5,a5,4
    5e68:	bne	a5,a3,5e60 <.L19>
    5e6c:	ret
