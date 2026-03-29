# Matmul (fused bias activation) — All 5 cores (stripped)

######## NCRISC (reader) — kernel=reader_bmm_tile_layout_in0_sender_in1_sender ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/reader_bmm_tile_layout_in0_sender_in1_sender/15568716074063352835/ncrisc/ncrisc.elf:     file format elf32-littleriscv
00005f80 <_start>:
    5f80:	addi	sp,sp,-240
    5f84:	sw	s0,236(sp)
    5f88:	sw	s1,232(sp)
    5f8c:	sw	s2,228(sp)
    5f90:	sw	s3,224(sp)
    5f94:	sw	s4,220(sp)
    5f98:	sw	s5,216(sp)
    5f9c:	sw	s6,212(sp)
    5fa0:	sw	s7,208(sp)
    5fa4:	sw	s8,204(sp)
    5fa8:	sw	s10,196(sp)
    5fac:	sw	s11,192(sp)
    5fb0:	lui	a5,0xffb01
    5fb4:	lui	a4,0xffb01
    5fb8:	addi	a5,a5,-976 # ffb00c30 <noc_reads_num_issued>
    5fbc:	addi	a4,a4,-968 # ffb00c38 <__ldm_bss_end>
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
    5ffc:	lui	a4,0x7
    6000:	addi	a4,a4,-988 # 6c24 <__kernel_data_lma>
    6004:	addi	a5,gp,1072 # ffb00c20 <noc_nonposted_writes_acked>
    6008:	beq	a4,a5,6078 <.L7>
    600c:	addi	a2,gp,1072 # ffb00c20 <noc_nonposted_writes_acked>
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
    607c:	lw	a2,520(a5) # ffb20208 <__stack_base+0x1f5c8>
    6080:	lw	a3,552(a5)
    6084:	lw	a4,516(a5)
    6088:	addi	s10,gp,1072 # ffb00c20 <noc_nonposted_writes_acked>
    608c:	addi	s7,gp,1088 # ffb00c30 <noc_reads_num_issued>
    6090:	addi	s11,gp,1080 # ffb00c28 <noc_nonposted_writes_num_issued>
    6094:	lw	a1,512(a5)
    6098:	lw	a5,556(a5)
    609c:	sw	a4,0(s10)
    60a0:	sw	a2,0(s7)
    60a4:	sw	a3,0(s11)
    60a8:	lw	a5,1056(zero) # 420 <.LASF377+0x2>
    60ac:	li	a4,128
    60b0:	slli	a5,a5,0x2
    60b4:	lbu	a3,1011(a5)
    60b8:	addi	a5,a5,96
    60bc:	beq	a3,a4,60cc <.L14>
    60c0:	fence
    60c4:	lbu	a3,915(a5)
    60c8:	bne	a3,a4,60c0 <.L11>
    60cc:	lw	a4,-1976(gp) # ffb00038 <rta_l1_base>
    60d0:	lw	a1,8(a4)
    60d4:	lw	a0,40(a4)
    60d8:	lw	s5,64(a4)
    60dc:	lw	t4,100(a4)
    60e0:	lw	a3,0(a4)
    60e4:	lw	a5,-1000(gp) # ffb00408 <sem_l1_base>
    60e8:	lw	a2,4(a4)
    60ec:	lw	a6,36(a4)
    60f0:	sw	a1,28(sp)
    60f4:	sw	a0,40(sp)
    60f8:	lw	a1,12(a4)
    60fc:	lw	a0,44(a4)
    6100:	sw	a1,68(sp)
    6104:	sw	a0,76(sp)
    6108:	lw	a1,16(a4)
    610c:	lw	a0,48(a4)
    6110:	sw	a1,72(sp)
    6114:	sw	a0,80(sp)
    6118:	lw	a1,20(a4)
    611c:	lw	a0,52(a4)
    6120:	sw	a1,8(sp)
    6124:	sw	a0,12(sp)
    6128:	lw	a1,24(a4)
    612c:	lw	a0,56(a4)
    6130:	sw	a1,32(sp)
    6134:	sw	a0,44(sp)
    6138:	lw	a1,28(a4)
    613c:	lw	a0,60(a4)
    6140:	sw	a1,36(sp)
    6144:	sw	a0,48(sp)
    6148:	lw	a1,32(a4)
    614c:	sw	s5,84(sp)
    6150:	lw	a0,84(a4)
    6154:	lw	t1,148(a4)
    6158:	sw	a3,160(sp)
    615c:	slli	a3,t4,0x4
    6160:	lw	t2,68(a4)
    6164:	lw	s1,72(a4)
    6168:	lw	a7,76(a4)
    616c:	lw	t3,80(a4)
    6170:	lw	s3,96(a4)
    6174:	lw	s0,104(a4)
    6178:	lw	s2,108(a4)
    617c:	lw	t6,112(a4)
    6180:	sw	a0,16(sp)
    6184:	lw	a0,136(a4)
    6188:	lw	t0,116(a4)
    618c:	lw	s8,120(a4)
    6190:	lw	s4,132(a4)
    6194:	lw	t5,144(a4)
    6198:	lw	t4,152(a4)
    619c:	add	s6,a3,a5
    61a0:	sw	a1,176(sp)
    61a4:	li	a3,1
    61a8:	lw	a1,140(a4)
    61ac:	lui	a4,0x1
    61b0:	addi	a4,a4,-2048 # 800 <.LLRL806+0x2>
    61b4:	slli	a0,a0,0x4
    61b8:	add	a0,a0,a5
    61bc:	sw	a3,0(s6)
    61c0:	sw	s6,88(sp)
    61c4:	sw	a0,92(sp)
    61c8:	sw	a3,0(a0)
    61cc:	sw	a4,168(sp)
    61d0:	sw	a4,172(sp)
    61d4:	sw	a4,184(sp)
    61d8:	sw	a4,188(sp)
    61dc:	beqz	t1,6bdc <.L12>
    61e0:	beqz	s5,6bdc <.L12>
    61e4:	slli	a3,a7,0x10
    61e8:	slli	a4,t3,0x16
    61ec:	or	a0,a3,a4
    61f0:	slli	a3,t0,0x16
    61f4:	slli	a4,t6,0x10
    61f8:	or	a4,a4,a3
    61fc:	slli	a3,t2,0x4
    6200:	or	a3,a0,a3
    6204:	slli	a0,s0,0x4
    6208:	or	a4,a4,a0
    620c:	slli	a0,s1,0xa
    6210:	or	a0,a3,a0
    6214:	slli	a3,s2,0xa
    6218:	or	s5,a4,a3
    621c:	slli	a7,s3,0x4
    6220:	lui	a4,0x1000
    6224:	slli	t3,s4,0x4
    6228:	addi	t0,a4,-1 # ffffff <.LASF1693+0xff52b9>
    622c:	add	a7,a7,a5
    6230:	srli	t6,a0,0x4
    6234:	add	a5,t3,a5
    6238:	lui	a3,0x10000
    623c:	srli	a4,s5,0x4
    6240:	sw	a5,56(sp)
    6244:	and	a5,t6,t0
    6248:	addi	t2,a3,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    624c:	sw	a5,100(sp)
    6250:	and	a5,a4,t0
    6254:	lui	a3,0xffb00
    6258:	sw	a5,108(sp)
    625c:	and	a5,s5,t2
    6260:	sw	s9,200(sp)
    6264:	sw	a7,52(sp)
    6268:	addi	s9,a3,1044 # ffb00414 <cb_interface>
    626c:	mv	s1,a1
    6270:	sw	a5,104(sp)
    6274:	li	a4,0
    6278:	lui	s6,0xffb21
    627c:	mv	a3,s8
    6280:	mv	t6,t5
    6284:	mv	a1,a0
    6288:	mv	a7,s5
    628c:	and	a5,a1,t2
    6290:	sw	a6,24(sp)
    6294:	mv	s3,s1
    6298:	sw	a5,96(sp)
    629c:	mv	s1,t4
    62a0:	sw	a2,20(sp)
    62a4:	mv	t4,a6
    62a8:	sw	zero,60(sp)
    62ac:	li	s8,1
    62b0:	mv	s5,t6
    62b4:	sw	t1,112(sp)
    62b8:	mv	a6,a4
    62bc:	lui	a5,0xffb40
    62c0:	lw	a0,40(a5) # ffb40028 <__stack_base+0x3f3e8>
    62c4:	fence
    62c8:	lui	a5,0xffb40
    62cc:	lw	a4,32(a5) # ffb40020 <__stack_base+0x3f3e0>
    62d0:	lw	a5,12(s9)
    62d4:	add	a5,a5,a4
    62d8:	lw	a4,36(sp)
    62dc:	sub	a5,a5,a0
    62e0:	zext.h	a5,a5
    62e4:	blt	a5,a4,62c4 <.L15>
    62e8:	lw	a5,32(sp)
    62ec:	lw	t3,20(s9)
    62f0:	beqz	a5,6bd0 <.L105>
    62f4:	lw	a5,8(sp)
    62f8:	beqz	a5,6bd0 <.L105>
    62fc:	lui	a0,0x92492
    6300:	addi	a5,a0,1171 # 92492493 <__device_print_strings_info_end+0x8bf92493>
    6304:	sw	a5,64(sp)
    6308:	lw	a5,8(sp)
    630c:	lw	t6,20(sp)
    6310:	addi	s4,gp,-1968 # ffb00040 <dram_bank_to_noc_xy>
    6314:	sw	t4,132(sp)
    6318:	addi	t5,gp,-1500 # ffb00214 <bank_to_dram_offset>
    631c:	mv	t4,a2
    6320:	mv	a4,t3
    6324:	li	t1,0
    6328:	li	s0,0
    632c:	slli	a5,a5,0xb
    6330:	lui	a0,0x4
    6334:	sw	a3,116(sp)
    6338:	sw	s3,120(sp)
    633c:	sw	s5,124(sp)
    6340:	sw	s1,128(sp)
    6344:	sw	t3,136(sp)
    6348:	sw	a6,140(sp)
    634c:	mv	a2,a1
    6350:	mv	a6,a4
    6354:	mv	s3,t6
    6358:	li	s5,0
    635c:	sw	s0,144(sp)
    6360:	sw	t6,148(sp)
    6364:	sw	a4,152(sp)
    6368:	sw	a5,156(sp)
    636c:	lw	a5,64(sp)
    6370:	lw	a3,168(sp)
    6374:	mulhu	a4,s3,a5
    6378:	lw	t3,160(sp)
    637c:	srli	a4,a4,0x2
    6380:	slli	a1,a4,0x3
    6384:	mul	a3,a4,a3
    6388:	sub	a4,a1,a4
    638c:	sub	a4,s3,a4
    6390:	sh2add	a1,a4,t5
    6394:	sh1add	a4,a4,s4
    6398:	lw	a1,0(a1)
    639c:	lhu	s2,0(a4)
    63a0:	add	a3,a3,t3
    63a4:	lw	s1,172(sp)
    63a8:	add	a3,a3,a1
    63ac:	slli	s2,s2,0x4
    63b0:	mv	a1,a3
    63b4:	mv	a4,s2
    63b8:	mv	t6,a6
    63bc:	bgeu	a0,s1,6460 <.L21>
    63c0:	lui	a4,0xffffc
    63c4:	addi	a5,a4,-1 # ffffbfff <__stack_base+0x4fb3bf>
    63c8:	add	a5,s1,a5
    63cc:	and	t6,a5,a4
    63d0:	add	t6,t6,a0
    63d4:	add	t6,t6,a6
    63d8:	mv	a4,a3
    63dc:	mv	t3,s2
    63e0:	mv	a1,a6
    63e4:	lw	s0,-1984(s6) # ffb20840 <__stack_base+0x1fc00>
    63e8:	bnez	s0,63e4 <.L19>
    63ec:	sw	a1,-2036(s6)
    63f0:	sw	a4,-2048(s6)
    63f4:	and	s0,t3,t2
    63f8:	sw	s0,-2044(s6)
    63fc:	srli	s0,t3,0x4
    6400:	and	s0,s0,t0
    6404:	sw	s0,-2040(s6)
    6408:	sw	a0,-2016(s6)
    640c:	sw	s8,-1984(s6)
    6410:	lw	s0,0(s7)
    6414:	add	a1,a1,a0
    6418:	addi	s0,s0,1
    641c:	sw	s0,0(s7)
    6420:	add	s0,a4,a0
    6424:	sltu	a4,s0,a4
    6428:	add	t3,a4,t3
    642c:	mv	a4,s0
    6430:	bne	a1,t6,63e4 <.L19>
    6434:	srli	a4,a5,0xe
    6438:	slli	a1,a4,0xe
    643c:	sub	s1,s1,a0
    6440:	addi	a4,a4,1
    6444:	sub	s1,s1,a1
    6448:	slli	a1,a4,0xe
    644c:	add	a1,a3,a1
    6450:	srli	a4,a4,0x12
    6454:	sltu	a3,a1,a3
    6458:	add	a4,s2,a4
    645c:	add	a4,a3,a4
    6460:	lw	a5,-1984(s6)
    6464:	bnez	a5,6460 <.L21>
    6468:	sw	t6,-2036(s6)
    646c:	sw	a1,-2048(s6)
    6470:	and	a3,a4,t2
    6474:	sw	a3,-2044(s6)
    6478:	srli	a4,a4,0x4
    647c:	sw	a4,-2040(s6)
    6480:	sw	s1,-2016(s6)
    6484:	sw	s8,-1984(s6)
    6488:	lw	a4,0(s7)
    648c:	lw	a5,28(sp)
    6490:	addi	a4,a4,1
    6494:	add	s3,s3,a5
    6498:	lw	a5,8(sp)
    649c:	addi	a6,a6,2047
    64a0:	addi	s5,s5,1
    64a4:	sw	a4,0(s7)
    64a8:	addi	a6,a6,1
    64ac:	bne	a5,s5,636c <.L22>
    64b0:	lw	a3,68(sp)
    64b4:	lw	t6,148(sp)
    64b8:	lw	s0,144(sp)
    64bc:	lw	a5,156(sp)
    64c0:	lw	a4,152(sp)
    64c4:	add	t6,t6,a3
    64c8:	lw	a3,32(sp)
    64cc:	addi	s0,s0,1
    64d0:	add	t1,t1,a5
    64d4:	add	a4,a4,a5
    64d8:	bne	a3,s0,6350 <.L23>
    64dc:	mv	a1,a2
    64e0:	lw	a3,116(sp)
    64e4:	mv	a2,t4
    64e8:	lw	s3,120(sp)
    64ec:	lw	s5,124(sp)
    64f0:	lw	s1,128(sp)
    64f4:	lw	t3,136(sp)
    64f8:	lw	a6,140(sp)
    64fc:	lw	t4,132(sp)
    6500:	lw	a5,20(sp)
    6504:	lw	a4,72(sp)
    6508:	lw	a0,0(s7)
    650c:	add	a5,a5,a4
    6510:	sw	a5,20(sp)
    6514:	lui	a4,0xffb20
    6518:	lw	a5,520(a4) # ffb20208 <__stack_base+0x1f5c8>
    651c:	bne	a5,a0,6518 <.L24>
    6520:	fence
    6524:	fence
    6528:	lw	a5,52(sp)
    652c:	lw	a4,16(sp)
    6530:	lw	a5,0(a5)
    6534:	bne	a4,a5,6524 <.L25>
    6538:	lw	a5,52(sp)
    653c:	lui	a4,0x4
    6540:	sw	zero,0(a5)
    6544:	mv	a0,t3
    6548:	mv	t5,a1
    654c:	mv	s0,t3
    6550:	bgeu	a4,t1,6634 <.L26>
    6554:	lui	t5,0xffffc
    6558:	addi	a5,t5,-1 # ffffbfff <__stack_base+0x4fb3bf>
    655c:	add	a5,t1,a5
    6560:	and	s0,a5,t5
    6564:	add	t5,t3,a4
    6568:	add	s0,s0,t5
    656c:	lui	t5,0x8
    6570:	addi	t5,t5,434 # 81b2 <.LASF363+0x6>
    6574:	sw	t5,64(sp)
    6578:	mv	t6,t3
    657c:	mv	s2,a1
    6580:	lui	t5,0xffb20
    6584:	mv	s4,a3
    6588:	sw	a5,116(sp)
    658c:	sw	a2,120(sp)
    6590:	lw	a3,64(t5) # ffb20040 <__stack_base+0x1f400>
    6594:	bnez	a3,6590 <.L27>
    6598:	lw	a3,64(sp)
    659c:	lw	a2,16(sp)
    65a0:	sw	a3,28(t5)
    65a4:	sw	t3,0(t5)
    65a8:	sw	t6,12(t5)
    65ac:	and	a3,s2,t2
    65b0:	sw	a3,16(t5)
    65b4:	srli	a3,s2,0x4
    65b8:	and	a3,a3,t0
    65bc:	sw	a3,20(t5)
    65c0:	sw	a4,32(t5)
    65c4:	sw	s8,64(t5)
    65c8:	lw	a3,0(s11)
    65cc:	lw	a5,0(s10)
    65d0:	addi	a3,a3,1
    65d4:	sw	a3,0(s11)
    65d8:	add	a5,a5,a2
    65dc:	add	a3,t6,a4
    65e0:	sltu	t6,a3,t6
    65e4:	add	t3,t3,a4
    65e8:	sw	a5,0(s10)
    65ec:	add	s2,t6,s2
    65f0:	mv	t6,a3
    65f4:	bne	t3,s0,6590 <.L27>
    65f8:	lw	a5,116(sp)
    65fc:	add	t3,a0,a4
    6600:	srli	t6,a5,0xe
    6604:	sub	a4,t1,a4
    6608:	slli	t1,t6,0xe
    660c:	sltu	a0,t3,a0
    6610:	add	t3,t1,t3
    6614:	add	a0,a0,a1
    6618:	sltu	t1,t3,t1
    661c:	slli	t6,t6,0xe
    6620:	lw	a2,120(sp)
    6624:	add	t5,t1,a0
    6628:	mv	a3,s4
    662c:	mv	a0,t3
    6630:	sub	t1,a4,t6
    6634:	lui	a4,0xffb20
    6638:	lw	a5,64(a4) # ffb20040 <__stack_base+0x1f400>
    663c:	bnez	a5,6638 <.L29>
    6640:	lui	t3,0x8
    6644:	addi	t3,t3,434 # 81b2 <.LASF363+0x6>
    6648:	sw	t3,28(a4)
    664c:	sw	s0,0(a4)
    6650:	sw	a0,12(a4)
    6654:	and	a0,t5,t2
    6658:	srli	t5,t5,0x4
    665c:	sw	a0,16(a4)
    6660:	and	t5,t5,t0
    6664:	sw	t5,20(a4)
    6668:	sw	t1,32(a4)
    666c:	sw	s8,64(a4)
    6670:	lw	a4,0(s11)
    6674:	lw	a0,0(s10)
    6678:	lw	a5,16(sp)
    667c:	addi	a4,a4,1
    6680:	add	a0,a0,a5
    6684:	sw	a0,0(s10)
    6688:	sw	a4,0(s11)
    668c:	lui	a0,0xffb20
    6690:	lw	a5,552(a0) # ffb20228 <__stack_base+0x1f5e8>
    6694:	bne	a5,a4,6690 <.L30>
    6698:	fence
    669c:	lw	a5,64(s6)
    66a0:	bnez	a5,669c <.L31>
    66a4:	lui	a4,0x8
    66a8:	lw	a5,88(sp)
    66ac:	addi	a4,a4,434 # 81b2 <.LASF363+0x6>
    66b0:	sw	a4,28(s6)
    66b4:	sw	a5,0(s6)
    66b8:	sw	a5,12(s6)
    66bc:	lw	a5,96(sp)
    66c0:	li	a4,4
    66c4:	sw	a5,16(s6)
    66c8:	lw	a5,100(sp)
    66cc:	lw	t3,36(sp)
    66d0:	sw	a5,20(s6)
    66d4:	sw	a4,32(s6)
    66d8:	sw	s8,64(s6)
    66dc:	lw	a0,0(s11)
    66e0:	lw	a4,0(s10)
    66e4:	lw	a5,16(sp)
    66e8:	addi	a0,a0,1
    66ec:	add	a4,a4,a5
    66f0:	sw	a4,0(s10)
    66f4:	sw	a0,0(s11)
    66f8:	lui	a5,0xffb40
    66fc:	lw	a0,40(a5) # ffb40028 <__stack_base+0x3f3e8>
    6700:	lw	t1,8(s9)
    6704:	lw	a4,20(s9)
    6708:	add	a0,t3,a0
    670c:	mul	t1,t3,t1
    6710:	sw	a0,40(a5)
    6714:	add	a4,t1,a4
    6718:	lw	a0,4(s9)
    671c:	sw	a4,20(s9)
    6720:	bne	a4,a0,6730 <.L32>
    6724:	lw	a0,0(s9)
    6728:	sub	a4,a4,a0
    672c:	sw	a4,20(s9)
    6730:	lui	a0,0xffb41
    6734:	lw	t1,40(a0) # ffb41028 <__stack_base+0x403e8>
    6738:	fence
    673c:	lw	a4,32(a0)
    6740:	lw	a5,44(s9)
    6744:	add	a5,a5,a4
    6748:	lw	a4,48(sp)
    674c:	sub	a5,a5,t1
    6750:	zext.h	a5,a5
    6754:	blt	a5,a4,6738 <.L33>
    6758:	lw	a5,44(sp)
    675c:	lw	t3,52(s9)
    6760:	beqz	a5,6bc8 <.L106>
    6764:	lw	a5,12(sp)
    6768:	beqz	a5,6bc8 <.L106>
    676c:	lui	a0,0x92492
    6770:	addi	a5,a0,1171 # 92492493 <__device_print_strings_info_end+0x8bf92493>
    6774:	sw	a5,64(sp)
    6778:	lw	a5,12(sp)
    677c:	addi	s4,gp,-1968 # ffb00040 <dram_bank_to_noc_xy>
    6780:	lw	a4,24(sp)
    6784:	sw	t4,132(sp)
    6788:	addi	t5,gp,-1500 # ffb00214 <bank_to_dram_offset>
    678c:	mv	t4,a2
    6790:	li	t6,0
    6794:	li	t1,0
    6798:	mv	s0,t3
    679c:	slli	a5,a5,0xb
    67a0:	lui	a0,0x4
    67a4:	sw	a3,116(sp)
    67a8:	sw	s3,120(sp)
    67ac:	sw	s5,124(sp)
    67b0:	sw	s1,128(sp)
    67b4:	sw	t3,136(sp)
    67b8:	sw	a6,140(sp)
    67bc:	mv	a2,a1
    67c0:	li	s5,0
    67c4:	mv	a6,s0
    67c8:	mv	s3,a4
    67cc:	sw	t1,144(sp)
    67d0:	sw	a4,148(sp)
    67d4:	sw	t6,152(sp)
    67d8:	sw	a5,156(sp)
    67dc:	lw	a5,64(sp)
    67e0:	lw	a3,184(sp)
    67e4:	mulhu	a4,s3,a5
    67e8:	lw	t1,176(sp)
    67ec:	srli	a4,a4,0x2
    67f0:	slli	a1,a4,0x3
    67f4:	mul	a3,a4,a3
    67f8:	sub	a4,a1,a4
    67fc:	sub	a4,s3,a4
    6800:	sh2add	a1,a4,t5
    6804:	sh1add	a4,a4,s4
    6808:	lw	a1,0(a1)
    680c:	lhu	s2,0(a4)
    6810:	add	a3,a3,t1
    6814:	lw	s1,188(sp)
    6818:	add	a3,a3,a1
    681c:	slli	s2,s2,0x4
    6820:	mv	a1,a3
    6824:	mv	a4,s2
    6828:	mv	t3,a6
    682c:	bgeu	a0,s1,68d0 <.L39>
    6830:	lui	a4,0xffffc
    6834:	addi	a5,a4,-1 # ffffbfff <__stack_base+0x4fb3bf>
    6838:	add	a5,s1,a5
    683c:	and	t3,a5,a4
    6840:	add	t3,t3,a0
    6844:	add	t3,t3,a6
    6848:	mv	a4,a3
    684c:	mv	t1,s2
    6850:	mv	a1,a6
    6854:	lw	t6,-1984(s6)
    6858:	bnez	t6,6854 <.L37>
    685c:	sw	a1,-2036(s6)
    6860:	sw	a4,-2048(s6)
    6864:	and	t6,t1,t2
    6868:	sw	t6,-2044(s6)
    686c:	srli	t6,t1,0x4
    6870:	and	t6,t6,t0
    6874:	sw	t6,-2040(s6)
    6878:	sw	a0,-2016(s6)
    687c:	sw	s8,-1984(s6)
    6880:	lw	t6,0(s7)
    6884:	add	a1,a1,a0
    6888:	addi	t6,t6,1
    688c:	sw	t6,0(s7)
    6890:	add	t6,a4,a0
    6894:	sltu	a4,t6,a4
    6898:	add	t1,a4,t1
    689c:	mv	a4,t6
    68a0:	bne	a1,t3,6854 <.L37>
    68a4:	srli	a4,a5,0xe
    68a8:	slli	a1,a4,0xe
    68ac:	sub	s1,s1,a0
    68b0:	addi	a4,a4,1
    68b4:	sub	s1,s1,a1
    68b8:	slli	a1,a4,0xe
    68bc:	add	a1,a3,a1
    68c0:	srli	a4,a4,0x12
    68c4:	sltu	a3,a1,a3
    68c8:	add	a4,s2,a4
    68cc:	add	a4,a3,a4
    68d0:	lw	a5,-1984(s6)
    68d4:	bnez	a5,68d0 <.L39>
    68d8:	sw	t3,-2036(s6)
    68dc:	sw	a1,-2048(s6)
    68e0:	and	a3,a4,t2
    68e4:	sw	a3,-2044(s6)
    68e8:	srli	a4,a4,0x4
    68ec:	sw	a4,-2040(s6)
    68f0:	sw	s1,-2016(s6)
    68f4:	sw	s8,-1984(s6)
    68f8:	lw	a4,0(s7)
    68fc:	lw	a5,40(sp)
    6900:	addi	a4,a4,1
    6904:	add	s3,s3,a5
    6908:	lw	a5,12(sp)
    690c:	addi	a6,a6,2047
    6910:	addi	s5,s5,1
    6914:	sw	a4,0(s7)
    6918:	addi	a6,a6,1
    691c:	bne	a5,s5,67dc <.L40>
    6920:	lw	a3,76(sp)
    6924:	lw	a4,148(sp)
    6928:	lw	t6,152(sp)
    692c:	lw	a5,156(sp)
    6930:	lw	t1,144(sp)
    6934:	add	a4,a4,a3
    6938:	lw	a3,44(sp)
    693c:	addi	t6,t6,1
    6940:	add	t1,t1,a5
    6944:	add	s0,s0,a5
    6948:	bne	a3,t6,67c0 <.L41>
    694c:	mv	a1,a2
    6950:	lw	a3,116(sp)
    6954:	mv	a2,t4
    6958:	lw	s3,120(sp)
    695c:	lw	s5,124(sp)
    6960:	lw	s1,128(sp)
    6964:	lw	t3,136(sp)
    6968:	lw	a6,140(sp)
    696c:	lw	t4,132(sp)
    6970:	lw	a5,24(sp)
    6974:	lw	a4,80(sp)
    6978:	lw	a0,0(s7)
    697c:	add	a5,a5,a4
    6980:	sw	a5,24(sp)
    6984:	lui	a4,0xffb20
    6988:	lw	a5,520(a4) # ffb20208 <__stack_base+0x1f5c8>
    698c:	bne	a5,a0,6988 <.L42>
    6990:	fence
    6994:	fence
    6998:	lw	a5,56(sp)
    699c:	lw	a5,0(a5)
    69a0:	bne	a3,a5,6994 <.L43>
    69a4:	lw	a5,56(sp)
    69a8:	lui	a4,0x4
    69ac:	sw	zero,0(a5)
    69b0:	mv	a0,t3
    69b4:	mv	t5,a7
    69b8:	mv	s0,t3
    69bc:	bgeu	a4,t1,6a94 <.L44>
    69c0:	lui	t5,0xffffc
    69c4:	addi	a5,t5,-1 # ffffbfff <__stack_base+0x4fb3bf>
    69c8:	add	a5,t1,a5
    69cc:	and	s0,a5,t5
    69d0:	add	t5,t3,a4
    69d4:	add	s0,s0,t5
    69d8:	lui	t5,0x8
    69dc:	addi	t5,t5,434 # 81b2 <.LASF363+0x6>
    69e0:	sw	t5,64(sp)
    69e4:	mv	t6,t3
    69e8:	mv	s2,a7
    69ec:	lui	t5,0xffb20
    69f0:	mv	s4,s3
    69f4:	sw	a5,116(sp)
    69f8:	lw	s3,64(t5) # ffb20040 <__stack_base+0x1f400>
    69fc:	bnez	s3,69f8 <.L45>
    6a00:	lw	s3,64(sp)
    6a04:	sw	s3,28(t5)
    6a08:	sw	t3,0(t5)
    6a0c:	sw	t6,12(t5)
    6a10:	and	s3,s2,t2
    6a14:	sw	s3,16(t5)
    6a18:	srli	s3,s2,0x4
    6a1c:	and	s3,s3,t0
    6a20:	sw	s3,20(t5)
    6a24:	sw	a4,32(t5)
    6a28:	sw	s8,64(t5)
    6a2c:	lw	s3,0(s11)
    6a30:	lw	a5,0(s10)
    6a34:	addi	s3,s3,1
    6a38:	sw	s3,0(s11)
    6a3c:	add	a5,a5,a3
    6a40:	add	s3,t6,a4
    6a44:	sltu	t6,s3,t6
    6a48:	add	t3,t3,a4
    6a4c:	sw	a5,0(s10)
    6a50:	add	s2,t6,s2
    6a54:	mv	t6,s3
    6a58:	bne	t3,s0,69f8 <.L45>
    6a5c:	lw	a5,116(sp)
    6a60:	add	t3,a0,a4
    6a64:	srli	t6,a5,0xe
    6a68:	sub	a4,t1,a4
    6a6c:	slli	t1,t6,0xe
    6a70:	sltu	a0,t3,a0
    6a74:	add	t3,t1,t3
    6a78:	add	a0,a0,a7
    6a7c:	sltu	t1,t3,t1
    6a80:	slli	t6,t6,0xe
    6a84:	add	t5,t1,a0
    6a88:	mv	s3,s4
    6a8c:	mv	a0,t3
    6a90:	sub	t1,a4,t6
    6a94:	lui	a4,0xffb20
    6a98:	lw	a5,64(a4) # ffb20040 <__stack_base+0x1f400>
    6a9c:	bnez	a5,6a98 <.L47>
    6aa0:	lui	t3,0x8
    6aa4:	addi	t3,t3,434 # 81b2 <.LASF363+0x6>
    6aa8:	sw	t3,28(a4)
    6aac:	sw	s0,0(a4)
    6ab0:	sw	a0,12(a4)
    6ab4:	and	a0,t5,t2
    6ab8:	srli	t5,t5,0x4
    6abc:	sw	a0,16(a4)
    6ac0:	and	t5,t5,t0
    6ac4:	sw	t5,20(a4)
    6ac8:	sw	t1,32(a4)
    6acc:	sw	s8,64(a4)
    6ad0:	lw	a4,0(s11)
    6ad4:	lw	a0,0(s10)
    6ad8:	addi	a4,a4,1
    6adc:	add	a0,a0,a3
    6ae0:	sw	a0,0(s10)
    6ae4:	sw	a4,0(s11)
    6ae8:	lui	a0,0xffb20
    6aec:	lw	a5,552(a0) # ffb20228 <__stack_base+0x1f5e8>
    6af0:	bne	a5,a4,6aec <.L48>
    6af4:	fence
    6af8:	lw	a5,64(s6)
    6afc:	bnez	a5,6af8 <.L49>
    6b00:	lui	a4,0x8
    6b04:	lw	a5,92(sp)
    6b08:	addi	a4,a4,434 # 81b2 <.LASF363+0x6>
    6b0c:	sw	a4,28(s6)
    6b10:	sw	a5,0(s6)
    6b14:	sw	a5,12(s6)
    6b18:	lw	a5,104(sp)
    6b1c:	li	a4,4
    6b20:	sw	a5,16(s6)
    6b24:	lw	a5,108(sp)
    6b28:	lui	t1,0xffb41
    6b2c:	sw	a5,20(s6)
    6b30:	sw	a4,32(s6)
    6b34:	sw	s8,64(s6)
    6b38:	lw	a0,0(s11)
    6b3c:	lw	a4,0(s10)
    6b40:	addi	a0,a0,1
    6b44:	add	a4,a4,a3
    6b48:	sw	a0,0(s11)
    6b4c:	sw	a4,0(s10)
    6b50:	lw	a4,40(t1) # ffb41028 <__stack_base+0x403e8>
    6b54:	lw	a5,48(sp)
    6b58:	lw	a0,40(s9)
    6b5c:	add	a4,a5,a4
    6b60:	sw	a4,40(t1)
    6b64:	mul	a0,a5,a0
    6b68:	lw	a4,52(s9)
    6b6c:	lw	t1,36(s9)
    6b70:	add	a4,a0,a4
    6b74:	sw	a4,52(s9)
    6b78:	bne	a4,t1,6b88 <.L50>
    6b7c:	lw	a0,32(s9)
    6b80:	sub	a4,a4,a0
    6b84:	sw	a4,52(s9)
    6b88:	lw	a5,60(sp)
    6b8c:	lw	a4,84(sp)
    6b90:	addi	a5,a5,1
    6b94:	sw	a5,60(sp)
    6b98:	bne	a4,a5,62bc <.L51>
    6b9c:	mv	a4,a6
    6ba0:	mv	a6,t4
    6ba4:	mv	t4,s1
    6ba8:	lw	t1,112(sp)
    6bac:	mv	t6,s5
    6bb0:	mv	s1,s3
    6bb4:	addi	a4,a4,1
    6bb8:	beqz	t4,6c14 <.L52>
    6bbc:	beq	t1,a4,6bd8 <.L104>
    6bc0:	add	a2,a2,s1
    6bc4:	j	628c <.L13>
    6bc8:	li	t1,0
    6bcc:	j	6970 <.L35>
    6bd0:	li	t1,0
    6bd4:	j	6500 <.L17>
    6bd8:	lw	s9,200(sp)
    6bdc:	lw	s0,236(sp)
    6be0:	lw	s1,232(sp)
    6be4:	lw	s2,228(sp)
    6be8:	lw	s3,224(sp)
    6bec:	lw	s4,220(sp)
    6bf0:	lw	s5,216(sp)
    6bf4:	lw	s6,212(sp)
    6bf8:	lw	s7,208(sp)
    6bfc:	lw	s8,204(sp)
    6c00:	lw	s10,196(sp)
    6c04:	lw	s11,192(sp)
    6c08:	li	a0,0
    6c0c:	addi	sp,sp,240
    6c10:	ret
    6c14:	beq	t1,a4,6bd8 <.L104>
    6c18:	add	a6,a6,s5
    6c1c:	add	a2,a2,s3
    6c20:	j	628c <.L13>

######## TRISC0 (unpack) — kernel=bmm_large_block_zm_fused_bias_activation ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/bmm_large_block_zm_fused_bias_activation/10390980522057353870/trisc0/trisc0.elf:     file format elf32-littleriscv
00006930 <_start>:
    6930:	addi	sp,sp,-80
    6934:	sw	s0,76(sp)
    6938:	sw	s1,72(sp)
    693c:	sw	s2,68(sp)
    6940:	sw	s3,64(sp)
    6944:	sw	s4,60(sp)
    6948:	sw	s5,56(sp)
    694c:	sw	s6,52(sp)
    6950:	sw	s7,48(sp)
    6954:	sw	s8,44(sp)
    6958:	sw	s9,40(sp)
    695c:	sw	s10,36(sp)
    6960:	sw	s11,32(sp)
    6964:	lui	a5,0xffb01
    6968:	lui	a4,0xffb01
    696c:	addi	a5,a5,-2000 # ffb00830 <__stack_base>
    6970:	addi	a4,a4,-2012 # ffb00824 <__ldm_bss_end>
    6974:	bltu	a4,a5,6990 <.L2>
    6978:	sw	zero,-4(a5)
    697c:	sw	zero,-8(a5)
    6980:	sw	zero,-12(a5)
    6984:	sw	zero,-16(a5)
    6988:	addi	a5,a5,16
    698c:	bgeu	a4,a5,6978 <.L3>
    6990:	addi	a3,a5,-8
    6994:	bltu	a4,a3,69a4 <.L4>
    6998:	sw	zero,-12(a5)
    699c:	sw	zero,-16(a5)
    69a0:	mv	a3,a5
    69a4:	addi	a5,a3,-4
    69a8:	bltu	a4,a5,69b0 <.L5>
    69ac:	sw	zero,-8(a3)
    69b0:	lui	a4,0x7
    69b4:	addi	a4,a4,396 # 718c <__kernel_data_lma>
    69b8:	addi	a5,gp,48 # ffb00820 <unp_cfg_context>
    69bc:	beq	a4,a5,6a1c <.L7>
    69c0:	addi	a2,gp,48 # ffb00820 <unp_cfg_context>
    69c4:	sub	a2,a2,a5
    69c8:	li	a1,8
    69cc:	srai	a3,a2,0x2
    69d0:	bge	a1,a2,6a00 <.L8>
    69d4:	li	a2,2
    69d8:	lw	a6,0(a4)
    69dc:	lw	a0,4(a4)
    69e0:	lw	a1,8(a4)
    69e4:	addi	a4,a4,12
    69e8:	addi	a5,a5,12
    69ec:	addi	a3,a3,-3
    69f0:	sw	a6,-12(a5)
    69f4:	sw	a0,-8(a5)
    69f8:	sw	a1,-4(a5)
    69fc:	blt	a2,a3,69d8 <.L9>
    6a00:	blez	a3,6a1c <.L7>
    6a04:	lw	a1,0(a4)
    6a08:	li	a2,2
    6a0c:	sw	a1,0(a5)
    6a10:	bne	a3,a2,6a1c <.L7>
    6a14:	lw	a4,4(a4)
    6a18:	sw	a4,4(a5)
    6a1c:	lui	a5,0xffb12
    6a20:	sw	zero,104(a5) # ffb12068 <__stack_base+0x11838>
    6a24:	lw	a5,1056(zero) # 420 <.LASF1199+0x3>
    6a28:	li	a4,128
    6a2c:	slli	a5,a5,0x2
    6a30:	lbu	a3,1011(a5)
    6a34:	addi	a5,a5,96
    6a38:	beq	a3,a4,6a48 <.L13>
    6a3c:	fence
    6a40:	lbu	a3,915(a5)
    6a44:	bne	a3,a4,6a3c <.L11>
    6a48:	ttzerosrc	0,0,1,3
    6a4c:	lui	a4,0xffb00
    6a50:	addi	a4,a4,32 # ffb00020 <cb_interface>
    6a54:	lw	a0,40(a4)
    6a58:	lw	a2,8(a4)
    6a5c:	lui	a3,0xffe80
    6a60:	lw	a5,52(a3) # ffe80034 <__instrn_buffer+0x40034>
    6a64:	zext.b	a5,a5
    6a68:	bnez	a5,6a60 <.L12>
    6a6c:	ttsetadcxy	3,0,0,0,0,11
    6a70:	ttsetadczw	3,0,0,0,0,15
    6a74:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6a78:	lui	a3,0xffef0
    6a7c:	beqz	a5,6a84 <.L14>
    6a80:	addi	a3,a3,896 # ffef0380 <__instrn_buffer+0xb0380>
    6a84:	li	t1,256
    6a88:	sw	t1,228(a3)
    6a8c:	li	a5,512
    6a90:	sw	a5,236(a3)
    6a94:	ttatgetm	0
    6a98:	lui	a5,0xffe40
    6a9c:	mv	a5,a5
    6aa0:	lui	a1,0xb3ff0
    6aa4:	sw	a1,0(a5) # ffe40000 <__instrn_buffer>
    6aa8:	lui	a1,0xb47f0
    6aac:	sw	a1,0(a5)
    6ab0:	lui	a1,0xb3070
    6ab4:	addi	a1,a1,1 # b3070001 <__device_print_strings_info_end+0xacb70001>
    6ab8:	sw	a1,0(a5)
    6abc:	lui	a1,0xb4800
    6ac0:	addi	a1,a1,1 # b4800001 <__device_print_strings_info_end+0xae300001>
    6ac4:	sw	a1,0(a5)
    6ac8:	lui	a1,0xb5010
    6acc:	addi	a1,a1,1 # b5010001 <__device_print_strings_info_end+0xaeb10001>
    6ad0:	sw	a1,0(a5)
    6ad4:	lui	a1,0xb3010
    6ad8:	addi	a1,a1,2 # b3010002 <__device_print_strings_info_end+0xacb10002>
    6adc:	sw	a1,0(a5)
    6ae0:	lui	a1,0xb5400
    6ae4:	addi	s4,a1,71 # b5400047 <__device_print_strings_info_end+0xaef00047>
    6ae8:	sw	s4,0(a5)
    6aec:	addi	a1,a1,119
    6af0:	sw	a1,0(a5)
    6af4:	ttatrelm	0
    6af8:	li	a1,22
    6afc:	sw	a1,256(a3)
    6b00:	lui	a1,0x40
    6b04:	addi	a1,a1,1 # 40001 <.LASF142+0x33f2e>
    6b08:	lui	t3,0x1000
    6b0c:	sw	a1,260(a3)
    6b10:	addi	a6,t3,21 # 1000015 <.LASF142+0xff3f42>
    6b14:	sw	a6,448(a3)
    6b18:	sw	a1,452(a3)
    6b1c:	li	a1,38
    6b20:	sw	a1,288(a3)
    6b24:	lui	a1,0xf0
    6b28:	addi	a1,a1,15 # f000f <.LASF142+0xe3f3c>
    6b2c:	sw	a1,292(a3)
    6b30:	li	a6,37
    6b34:	sw	a6,480(a3)
    6b38:	sw	a1,484(a3)
    6b3c:	lui	a1,0x5e240
    6b40:	addi	a1,a1,-1024 # 5e23fc00 <__device_print_strings_info_end+0x57d3fc00>
    6b44:	sw	a1,0(a5)
    6b48:	lui	a1,0x5e440
    6b4c:	addi	a1,a1,-1024 # 5e43fc00 <__device_print_strings_info_end+0x57f3fc00>
    6b50:	lui	a6,0x400
    6b54:	sw	a1,0(a5)
    6b58:	addi	a6,a6,64 # 400040 <.LASF142+0x3f3f6d>
    6b5c:	sw	a6,336(a3)
    6b60:	add	a7,t3,t1
    6b64:	sw	a7,344(a3)
    6b68:	lui	a1,0xffe00
    6b6c:	sw	a7,160(a1) # ffe000a0 <__stack_base+0x2ff870>
    6b70:	lui	a7,0x800
    6b74:	addi	a7,a7,128 # 800080 <.LASF142+0x7f3fad>
    6b78:	sw	a7,164(a1)
    6b7c:	sw	a6,168(a1)
    6b80:	lui	a6,0x200
    6b84:	addi	a6,a6,32 # 200020 <.LASF142+0x1f3f4d>
    6b88:	sw	a6,172(a1)
    6b8c:	lui	a6,0x100
    6b90:	addi	a6,a6,16 # 100010 <.LASF142+0xf3f3d>
    6b94:	sw	a6,176(a1)
    6b98:	sw	zero,28(sp)
    6b9c:	lw	a1,176(a1)
    6ba0:	sw	a1,28(sp)
    6ba4:	ttsetc16	5,4
    6ba8:	sw	t1,200(a3)
    6bac:	sw	zero,48(gp) # ffb00820 <unp_cfg_context>
    6bb0:	ttsetc16	41,0
    6bb4:	lui	t0,0x45000
    6bb8:	addi	s1,t3,-256
    6bbc:	slli	a0,a0,0x8
    6bc0:	slli	a3,a2,0x8
    6bc4:	addi	s3,t0,72 # 45000048 <__device_print_strings_info_end+0x3eb00048>
    6bc8:	and	a2,a0,s1
    6bcc:	add	a2,a2,s3
    6bd0:	sw	a2,0(a5)
    6bd4:	and	a3,a3,s1
    6bd8:	addi	a2,t0,74
    6bdc:	add	a3,a3,a2
    6be0:	lui	t2,0xb4010
    6be4:	sw	a3,0(a5)
    6be8:	addi	t2,t2,72 # b4010048 <__device_print_strings_info_end+0xadb10048>
    6bec:	sw	t2,0(a5)
    6bf0:	ttsetadczw	3,0,0,0,0,15
    6bf4:	lui	a3,0x5e300
    6bf8:	addi	a3,a3,-1024 # 5e2ffc00 <__device_print_strings_info_end+0x57dffc00>
    6bfc:	sw	a3,0(a5)
    6c00:	lui	a3,0x5e500
    6c04:	addi	a3,a3,-1024 # 5e4ffc00 <__device_print_strings_info_end+0x57fffc00>
    6c08:	sw	a3,0(a5)
    6c0c:	addi	a3,t0,332
    6c10:	sw	a3,0(a5)
    6c14:	ttreplay	0,12,0,1
    6c18:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    6c1c:	ttrdcfg	12,76
    6c20:	ttadddmareg	0,12,12,36
    6c24:	ttstallwait	128,1
    6c28:	ttwrcfg	12,0,76
    6c2c:	ttnop
    6c30:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    6c34:	ttrdcfg	12,77
    6c38:	ttadddmareg	0,12,12,36
    6c3c:	ttstallwait	128,1
    6c40:	ttwrcfg	12,0,77
    6c44:	ttnop
    6c48:	lui	a2,0xffe80
    6c4c:	li	a3,0
    6c50:	addi	a2,a2,8 # ffe80008 <__instrn_buffer+0x40008>
    6c54:	sw	a3,0(a2)
    6c58:	lw	a3,0(a2)
    6c5c:	and	zero,zero,a3
    6c60:	lui	a3,0xffb80
    6c64:	sw	zero,4(a3) # ffb80004 <__stack_base+0x7f7d4>
    6c68:	lui	a2,0x4000
    6c6c:	sw	zero,8(a3)
    6c70:	addi	a2,a2,96 # 4000060 <.LASF142+0x3ff3f8d>
    6c74:	sw	a2,12(a3)
    6c78:	sw	zero,16(a3)
    6c7c:	sw	zero,20(a3)
    6c80:	lui	a2,0x4018
    6c84:	sw	zero,24(a3)
    6c88:	addi	a2,a2,96 # 4018060 <.LASF142+0x400bf8d>
    6c8c:	sw	a2,28(a3)
    6c90:	sw	zero,32(a3)
    6c94:	lui	a3,0x42008
    6c98:	addi	a3,a3,193 # 420080c1 <__device_print_strings_info_end+0x3bb080c1>
    6c9c:	lhu	a0,24(a4)
    6ca0:	lhu	a2,56(a4)
    6ca4:	lui	t1,0xb30f0
    6ca8:	sw	a3,4(sp)
    6cac:	sw	zero,12(sp)
    6cb0:	sw	zero,8(sp)
    6cb4:	lui	a7,0xffb40
    6cb8:	li	a6,6
    6cbc:	lw	a3,40(a7) # ffb40028 <__stack_base+0x3f7f8>
    6cc0:	sub	a3,a3,a0
    6cc4:	zext.h	a3,a3
    6cc8:	bgeu	a6,a3,6cbc <.L15>
    6ccc:	lui	a6,0xffb41
    6cd0:	li	a0,11
    6cd4:	lw	a3,40(a6) # ffb41028 <__stack_base+0x407f8>
    6cd8:	sub	a3,a3,a2
    6cdc:	zext.h	a3,a3
    6ce0:	bgeu	a0,a3,6cd4 <.L16>
    6ce4:	lui	a0,0xffe80
    6ce8:	addi	s5,a0,8 # ffe80008 <__instrn_buffer+0x40008>
    6cec:	li	t6,0
    6cf0:	lui	t4,0x67111
    6cf4:	lui	t3,0x5e300
    6cf8:	lui	a3,0x43800
    6cfc:	addi	t4,t4,1032 # 67111408 <__device_print_strings_info_end+0x60c11408>
    6d00:	addi	t3,t3,-1024 # 5e2ffc00 <__device_print_strings_info_end+0x57dffc00>
    6d04:	li	a6,0
    6d08:	addi	a7,a3,257 # 43800101 <__device_print_strings_info_end+0x3d300101>
    6d0c:	lui	s7,0xffef0
    6d10:	lw	a3,8(sp)
    6d14:	bnez	a3,6f18 <.L65>
    6d18:	lw	s2,16(a4)
    6d1c:	lw	s9,48(a4)
    6d20:	lw	a3,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6d24:	lw	s8,8(a4)
    6d28:	lw	s0,40(a4)
    6d2c:	addi	s11,s2,-1
    6d30:	addi	s10,s9,-1
    6d34:	lui	t5,0xffef0
    6d38:	beqz	a3,6d40 <.L26>
    6d3c:	addi	t5,s7,896 # ffef0380 <__instrn_buffer+0xb0380>
    6d40:	mul	a3,t6,s8
    6d44:	mul	a2,a6,s0
    6d48:	add	a3,a3,s11
    6d4c:	add	s10,a2,s10
    6d50:	lw	a2,52(a0)
    6d54:	andi	a2,a2,254
    6d58:	bnez	a2,6d50 <.L27>
    6d5c:	lw	a2,48(gp) # ffb00820 <unp_cfg_context>
    6d60:	bnez	a2,7120 <.L28>
    6d64:	sw	s10,304(t5) # ffef0130 <__instrn_buffer+0xb0130>
    6d68:	sw	a3,496(t5)
    6d6c:	sw	zero,52(a0)
    6d70:	ttstallwait	8,1024
    6d74:	ttunpacr	1,0,0,0,0,1,1,0,0,0,0,0,1
    6d78:	lui	a3,0x1000
    6d7c:	sw	a3,0(a5)
    6d80:	ttsemget	32
    6d84:	li	a3,1
    6d88:	sw	a3,48(gp) # ffb00820 <unp_cfg_context>
    6d8c:	ttsetc16	41,257
    6d90:	addi	a6,a6,1
    6d94:	li	a3,12
    6d98:	bne	a6,a3,6d10 <.L31>
    6d9c:	addi	t6,t6,1
    6da0:	li	a3,7
    6da4:	bne	t6,a3,6cf0 <.L17>
    6da8:	lw	a2,12(sp)
    6dac:	li	a3,61
    6db0:	bltu	a3,a2,7174 <.L33>
    6db4:	lhu	a2,184(a4)
    6db8:	lui	a6,0xffb45
    6dbc:	li	a0,83
    6dc0:	lw	a3,40(a6) # ffb45028 <__stack_base+0x447f8>
    6dc4:	sub	a3,a3,a2
    6dc8:	zext.h	a3,a3
    6dcc:	bgeu	a0,a3,6dc0 <.L34>
    6dd0:	addi	a3,a2,84
    6dd4:	lw	a0,168(a4)
    6dd8:	zext.h	a3,a3
    6ddc:	addi	a6,t0,8
    6de0:	slli	a2,a3,0x8
    6de4:	sh	a3,184(a4)
    6de8:	sh2add	a3,a0,a0
    6dec:	sh2add	a3,a3,a0
    6df0:	add	a2,a2,a6
    6df4:	sw	a2,0(a5)
    6df8:	ttstallwait	32,6
    6dfc:	lui	a2,0x67111
    6e00:	lw	a6,176(a4)
    6e04:	addi	a2,a2,1032 # 67111408 <__device_print_strings_info_end+0x60c11408>
    6e08:	lw	a0,164(a4)
    6e0c:	sh2add	a3,a3,a6
    6e10:	sw	a2,0(a5)
    6e14:	sw	a3,176(a4)
    6e18:	bltu	a3,a0,6e28 <.L36>
    6e1c:	lw	a2,160(a4)
    6e20:	sub	a3,a3,a2
    6e24:	sw	a3,176(a4)
    6e28:	lhu	a0,24(a4)
    6e2c:	addi	a2,t0,8
    6e30:	addi	a0,a0,7
    6e34:	zext.h	a0,a0
    6e38:	slli	a3,a0,0x8
    6e3c:	add	a3,a3,a2
    6e40:	sh	a0,24(a4)
    6e44:	sw	a3,0(a5)
    6e48:	ttstallwait	32,6
    6e4c:	lui	a2,0x67110
    6e50:	sh3add	a3,s8,s2
    6e54:	sub	a3,a3,s8
    6e58:	lw	a6,4(a4)
    6e5c:	addi	a2,a2,8 # 67110008 <__device_print_strings_info_end+0x60c10008>
    6e60:	sw	a3,16(a4)
    6e64:	sw	a2,0(a5)
    6e68:	bltu	a3,a6,6e78 <.L37>
    6e6c:	lw	a2,0(a4)
    6e70:	sub	a3,a3,a2
    6e74:	sw	a3,16(a4)
    6e78:	lhu	a2,56(a4)
    6e7c:	addi	a6,t0,8
    6e80:	addi	a2,a2,12
    6e84:	zext.h	a2,a2
    6e88:	slli	a3,a2,0x8
    6e8c:	add	a3,a3,a6
    6e90:	sh	a2,56(a4)
    6e94:	sw	a3,0(a5)
    6e98:	ttstallwait	32,6
    6e9c:	lui	a6,0x67110
    6ea0:	sh1add	s0,s0,s0
    6ea4:	sh2add	a3,s0,s9
    6ea8:	lw	a7,36(a4)
    6eac:	addi	a6,a6,1032 # 67110408 <__device_print_strings_info_end+0x60c10408>
    6eb0:	sw	a3,48(a4)
    6eb4:	sw	a6,0(a5)
    6eb8:	bltu	a3,a7,6ec8 <.L38>
    6ebc:	lw	a6,32(a4)
    6ec0:	sub	a3,a3,a6
    6ec4:	sw	a3,48(a4)
    6ec8:	lw	a3,12(sp)
    6ecc:	addi	a6,a3,1 # 1000001 <.LASF142+0xff3f2e>
    6ed0:	sw	a6,12(sp)
    6ed4:	li	a3,64
    6ed8:	bne	a6,a3,6cb4 <.L39>
    6edc:	lw	s0,76(sp)
    6ee0:	lw	s1,72(sp)
    6ee4:	lw	s2,68(sp)
    6ee8:	lw	s3,64(sp)
    6eec:	lw	s4,60(sp)
    6ef0:	lw	s5,56(sp)
    6ef4:	lw	s6,52(sp)
    6ef8:	lw	s7,48(sp)
    6efc:	lw	s8,44(sp)
    6f00:	lw	s9,40(sp)
    6f04:	lw	s10,36(sp)
    6f08:	lw	s11,32(sp)
    6f0c:	li	a0,0
    6f10:	addi	sp,sp,80
    6f14:	ret
    6f18:	lw	a3,168(a4)
    6f1c:	ttstallwait	128,2
    6f20:	lui	a2,0xb30f0
    6f24:	addi	a2,a2,64 # b30f0040 <__device_print_strings_info_end+0xacbf0040>
    6f28:	sw	a2,0(a5)
    6f2c:	slli	a3,a3,0x8
    6f30:	sw	s4,0(a5)
    6f34:	and	a3,a3,s1
    6f38:	addi	a2,t1,1096 # b30f0448 <__device_print_strings_info_end+0xacbf0448>
    6f3c:	sw	a2,0(a5)
    6f40:	add	a3,a3,s3
    6f44:	sw	a3,0(a5)
    6f48:	sw	t2,0(a5)
    6f4c:	ttsetadcxx	1,255,0
    6f50:	li	a3,0
    6f54:	sw	a3,0(s5)
    6f58:	lw	a3,0(s5)
    6f5c:	and	zero,zero,a3
    6f60:	lui	a3,0xffb80
    6f64:	li	a2,4
    6f68:	sw	a2,0(a3) # ffb80000 <__stack_base+0x7f7d0>
    6f6c:	li	a2,1
    6f70:	sw	a2,4(a3)
    6f74:	lw	a2,4(sp)
    6f78:	sw	a2,8(a3)
    6f7c:	lui	a2,0x2000
    6f80:	sw	a2,12(a3)
    6f84:	sw	a2,16(a3)
    6f88:	sw	a7,20(a3)
    6f8c:	sw	a2,24(a3)
    6f90:	sw	a7,28(a3)
    6f94:	sw	a7,32(a3)
    6f98:	lhu	t5,184(a4)
    6f9c:	lui	a2,0xffb45
    6fa0:	lw	a3,40(a2) # ffb45028 <__stack_base+0x447f8>
    6fa4:	zext.h	a3,a3
    6fa8:	beq	a3,t5,6fa0 <.L19>
    6fac:	lw	a3,176(a4)
    6fb0:	addi	a3,a3,-1
    6fb4:	ttsetadczw	3,0,0,0,0,15
    6fb8:	lw	a2,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    6fbc:	beqz	a2,7164 <.L43>
    6fc0:	addi	s0,s7,1200
    6fc4:	addi	a2,s7,1204
    6fc8:	lw	t5,52(a0)
    6fcc:	andi	t5,t5,254
    6fd0:	bnez	t5,6fc8 <.L21>
    6fd4:	lw	t5,48(gp) # ffb00820 <unp_cfg_context>
    6fd8:	bnez	t5,6fe0 <.L22>
    6fdc:	mv	a2,s0
    6fe0:	sw	a3,0(a2)
    6fe4:	sw	zero,52(a0)
    6fe8:	ttstallwait	8,1024
    6fec:	ttmop	1,0,0
    6ff0:	ttsemget	32
    6ff4:	lw	a2,48(gp) # ffb00820 <unp_cfg_context>
    6ff8:	li	a3,1
    6ffc:	sub	t5,a3,a2
    7000:	sw	t5,48(gp) # ffb00820 <unp_cfg_context>
    7004:	beq	a2,a3,715c <.L23>
    7008:	ttsetc16	41,257
    700c:	lhu	a3,184(a4)
    7010:	addi	t5,t0,8
    7014:	addi	a3,a3,1
    7018:	zext.h	a3,a3
    701c:	slli	a2,a3,0x8
    7020:	sh	a3,184(a4)
    7024:	add	a2,a2,t5
    7028:	sw	a2,0(a5)
    702c:	lw	a3,168(a4)
    7030:	ttstallwait	32,6
    7034:	lw	t5,176(a4)
    7038:	lw	a2,164(a4)
    703c:	add	a3,a3,t5
    7040:	sw	t4,0(a5)
    7044:	sw	a3,176(a4)
    7048:	bltu	a3,a2,7058 <.L25>
    704c:	lw	a2,160(a4)
    7050:	sub	a3,a3,a2
    7054:	sw	a3,176(a4)
    7058:	lw	a3,40(a4)
    705c:	ttstallwait	128,2
    7060:	addi	a2,t1,1600
    7064:	sw	a2,0(a5)
    7068:	slli	a3,a3,0x8
    706c:	sw	s4,0(a5)
    7070:	and	a3,a3,s1
    7074:	addi	a2,t1,1608
    7078:	sw	a2,0(a5)
    707c:	add	a3,a3,s3
    7080:	sw	a3,0(a5)
    7084:	sw	t2,0(a5)
    7088:	ttsetadczw	3,0,0,0,0,15
    708c:	lui	a3,0x5e500
    7090:	sw	t3,0(a5)
    7094:	addi	a3,a3,-1024 # 5e4ffc00 <__device_print_strings_info_end+0x57fffc00>
    7098:	sw	a3,0(a5)
    709c:	addi	a3,t0,332
    70a0:	sw	a3,0(a5)
    70a4:	ttreplay	0,12,0,1
    70a8:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    70ac:	ttrdcfg	12,76
    70b0:	ttadddmareg	0,12,12,36
    70b4:	ttstallwait	128,1
    70b8:	ttwrcfg	12,0,76
    70bc:	ttnop
    70c0:	ttunpacr	0,0,0,0,0,1,1,0,0,0,0,0,1
    70c4:	ttrdcfg	12,77
    70c8:	ttadddmareg	0,12,12,36
    70cc:	ttstallwait	128,1
    70d0:	ttwrcfg	12,0,77
    70d4:	ttnop
    70d8:	li	a3,0
    70dc:	sw	a3,0(s5)
    70e0:	lw	a3,0(s5)
    70e4:	and	zero,zero,a3
    70e8:	lui	a3,0xffb80
    70ec:	sw	zero,4(a3) # ffb80004 <__stack_base+0x7f7d4>
    70f0:	lui	a2,0x4000
    70f4:	sw	zero,8(a3)
    70f8:	addi	a2,a2,96 # 4000060 <.LASF142+0x3ff3f8d>
    70fc:	sw	a2,12(a3)
    7100:	sw	zero,16(a3)
    7104:	sw	zero,20(a3)
    7108:	lui	a2,0x4018
    710c:	sw	zero,24(a3)
    7110:	addi	a2,a2,96 # 4018060 <.LASF142+0x400bf8d>
    7114:	sw	a2,28(a3)
    7118:	sw	zero,32(a3)
    711c:	j	6d18 <.L18>
    7120:	sw	s10,308(t5)
    7124:	sw	a3,500(t5)
    7128:	sw	zero,52(a0)
    712c:	ttstallwait	8,1024
    7130:	ttunpacr	1,0,0,0,0,1,1,0,0,0,0,0,1
    7134:	lui	a3,0x1000
    7138:	addi	a3,a3,255 # 10000ff <.LASF142+0xff402c>
    713c:	sw	a3,0(a5)
    7140:	ttsemget	32
    7144:	li	a3,1
    7148:	sub	t5,a3,a2
    714c:	sw	t5,48(gp) # ffb00820 <unp_cfg_context>
    7150:	bne	a2,a3,6d8c <.L29>
    7154:	ttsetc16	41,0
    7158:	j	6d90 <.L30>
    715c:	ttsetc16	41,0
    7160:	j	700c <.L24>
    7164:	lui	a2,0xffef0
    7168:	addi	s0,a2,304 # ffef0130 <__instrn_buffer+0xb0130>
    716c:	addi	a2,a2,308
    7170:	j	6fc8 <.L21>
    7174:	addi	a3,a2,-62
    7178:	lw	a2,8(sp)
    717c:	seqz	a3,a3
    7180:	or	a3,a2,a3
    7184:	sw	a3,8(sp)
    7188:	j	6e28 <.L36>

######## TRISC1 (math) — kernel=bmm_large_block_zm_fused_bias_activation ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/bmm_large_block_zm_fused_bias_activation/10390980522057353870/trisc1/trisc1.elf:     file format elf32-littleriscv
00007110 <_start>:
    7110:	addi	sp,sp,-64
    7114:	sw	s0,60(sp)
    7118:	sw	s1,56(sp)
    711c:	sw	s2,52(sp)
    7120:	sw	s3,48(sp)
    7124:	sw	s4,44(sp)
    7128:	sw	s5,40(sp)
    712c:	sw	s6,36(sp)
    7130:	sw	s7,32(sp)
    7134:	sw	s8,28(sp)
    7138:	sw	s9,24(sp)
    713c:	sw	s10,20(sp)
    7140:	sw	s11,16(sp)
    7144:	lui	a5,0xffb00
    7148:	lui	a4,0xffb00
    714c:	addi	a5,a5,48 # ffb00030 <__stack_base>
    7150:	addi	a4,a4,36 # ffb00024 <__ldm_bss_end>
    7154:	bltu	a4,a5,7170 <.L2>
    7158:	sw	zero,-4(a5)
    715c:	sw	zero,-8(a5)
    7160:	sw	zero,-12(a5)
    7164:	sw	zero,-16(a5)
    7168:	addi	a5,a5,16
    716c:	bgeu	a4,a5,7158 <.L3>
    7170:	addi	a3,a5,-8
    7174:	bltu	a4,a3,7184 <.L4>
    7178:	sw	zero,-12(a5)
    717c:	sw	zero,-16(a5)
    7180:	mv	a3,a5
    7184:	addi	a5,a3,-4
    7188:	bltu	a4,a5,7190 <.L5>
    718c:	sw	zero,-8(a3)
    7190:	lui	a4,0x8
    7194:	addi	a4,a4,-1788 # 7904 <__kernel_data_lma>
    7198:	addi	a5,gp,-2000 # ffb00020 <_ZN7ckernelL20throttled_mop_statusE>
    719c:	beq	a4,a5,71fc <.L7>
    71a0:	addi	a2,gp,-2000 # ffb00020 <_ZN7ckernelL20throttled_mop_statusE>
    71a4:	sub	a2,a2,a5
    71a8:	li	a1,8
    71ac:	srai	a3,a2,0x2
    71b0:	bge	a1,a2,71e0 <.L8>
    71b4:	li	a2,2
    71b8:	lw	a6,0(a4)
    71bc:	lw	a0,4(a4)
    71c0:	lw	a1,8(a4)
    71c4:	addi	a4,a4,12
    71c8:	addi	a5,a5,12
    71cc:	addi	a3,a3,-3
    71d0:	sw	a6,-12(a5)
    71d4:	sw	a0,-8(a5)
    71d8:	sw	a1,-4(a5)
    71dc:	blt	a2,a3,71b8 <.L9>
    71e0:	blez	a3,71fc <.L7>
    71e4:	lw	a1,0(a4)
    71e8:	li	a2,2
    71ec:	sw	a1,0(a5)
    71f0:	bne	a3,a2,71fc <.L7>
    71f4:	lw	a4,4(a4)
    71f8:	sw	a4,4(a5)
    71fc:	lw	a5,1056(zero) # 420 <.LVUS102>
    7200:	li	a4,128
    7204:	slli	a5,a5,0x2
    7208:	lbu	a3,1011(a5)
    720c:	addi	a5,a5,96
    7210:	beq	a3,a4,7220 <.L13>
    7214:	fence
    7218:	lbu	a3,915(a5)
    721c:	bne	a3,a4,7214 <.L11>
    7220:	ttsetc16	13,0
    7224:	ttsetc16	29,0
    7228:	ttsetc16	48,0
    722c:	ttzeroacc	3,0,0,1,0
    7230:	ttsetc16	12,2048
    7234:	ttsetc16	28,8
    7238:	ttsetc16	47,0
    723c:	ttsetc16	17,49344
    7240:	ttsetc16	33,11264
    7244:	ttsetc16	52,0
    7248:	ttsetc16	13,16400
    724c:	ttsetc16	29,8
    7250:	ttsetc16	48,0
    7254:	ttsetc16	14,24640
    7258:	ttsetc16	30,8
    725c:	ttsetc16	49,0
    7260:	ttsetc16	16,28768
    7264:	ttsetc16	32,1024
    7268:	ttsetc16	51,0
    726c:	ttreplay	16,16,0,1
    7270:	ttmvmul	0,0,0,0
    7274:	ttmvmul	0,0,1,0
    7278:	ttmvmul	0,0,0,0
    727c:	ttmvmul	0,0,2,0
    7280:	ttmvmul	0,0,0,0
    7284:	ttmvmul	0,0,1,0
    7288:	ttmvmul	0,0,0,0
    728c:	ttmvmul	0,0,4,0
    7290:	ttmvmul	0,0,0,0
    7294:	ttmvmul	0,0,1,0
    7298:	ttmvmul	0,0,0,0
    729c:	ttmvmul	0,0,2,0
    72a0:	ttmvmul	0,0,0,0
    72a4:	ttmvmul	0,0,1,0
    72a8:	ttmvmul	0,0,0,0
    72ac:	ttmvmul	0,0,5,0
    72b0:	lui	a2,0xffe80
    72b4:	addi	a3,a2,8 # ffe80008 <__instrn_buffer+0x40008>
    72b8:	li	a5,0
    72bc:	sw	a5,0(a3)
    72c0:	lw	a5,0(a3)
    72c4:	and	zero,zero,a5
    72c8:	lui	a5,0xffb80
    72cc:	li	a3,1
    72d0:	sw	a3,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    72d4:	li	a3,2
    72d8:	sw	a3,4(a5)
    72dc:	lui	a1,0x2000
    72e0:	lui	a3,0x37400
    72e4:	sw	a1,8(a5)
    72e8:	addi	a3,a3,15 # 3740000f <__device_print_strings_info_end+0x30f0000f>
    72ec:	sw	a3,12(a5)
    72f0:	lui	a3,0x4040
    72f4:	sw	a1,16(a5)
    72f8:	addi	a3,a3,256 # 4040100 <.LASF142+0x4032be2>
    72fc:	sw	a3,20(a5)
    7300:	sw	a1,24(a5)
    7304:	sw	a3,28(a5)
    7308:	sw	a3,32(a5)
    730c:	ttsetrwc	0,0,0,0,0,15
    7310:	li	a5,0
    7314:	addi	a4,a2,4
    7318:	sw	a5,0(a4)
    731c:	lw	a5,0(a4)
    7320:	and	zero,zero,a5
    7324:	lw	a5,36(a2)
    7328:	zext.b	a5,a5
    732c:	bnez	a5,7324 <.L12>
    7330:	ttseminit	2,0,2
    7334:	sw	zero,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7338:	ttsetc16	1,0
    733c:	lui	a1,0xffe40
    7340:	lui	a5,0xb3080
    7344:	mv	a1,a1
    7348:	addi	a5,a5,220 # b30800dc <__device_print_strings_info_end+0xacb800dc>
    734c:	sw	a5,0(a1) # ffe40000 <__instrn_buffer>
    7350:	ttstallwait	128,16
    7354:	lui	a5,0xb6800
    7358:	addi	a5,a5,1 # b6800001 <__device_print_strings_info_end+0xb0300001>
    735c:	sw	a5,0(a1)
    7360:	lui	a5,0xb6202
    7364:	addi	a5,a5,1 # b6202001 <__device_print_strings_info_end+0xafd02001>
    7368:	sw	a5,0(a1)
    736c:	lui	a5,0xb6404
    7370:	addi	a5,a5,1 # b6404001 <__device_print_strings_info_end+0xaff04001>
    7374:	sw	a5,0(a1)
    7378:	lui	t4,0xffe80
    737c:	lui	s6,0x4040
    7380:	lui	t2,0x37400
    7384:	sw	zero,-2000(gp) # ffb00020 <_ZN7ckernelL20throttled_mop_statusE>
    7388:	addi	t4,t4,8 # ffe80008 <__instrn_buffer+0x40008>
    738c:	addi	s0,s6,176 # 40400b0 <.LASF142+0x4032b92>
    7390:	addi	t2,t2,15 # 3740000f <__device_print_strings_info_end+0x30f0000f>
    7394:	li	t0,0
    7398:	li	s7,0
    739c:	li	a2,1
    73a0:	lui	a5,0xffb80
    73a4:	li	t1,2
    73a8:	lui	a0,0xb2010
    73ac:	bnez	s7,7634 <.L35>
    73b0:	li	s3,7
    73b4:	lui	a7,0x2000
    73b8:	lui	s5,0x26008
    73bc:	lui	s4,0x26014
    73c0:	li	t5,12
    73c4:	lui	s1,0x26010
    73c8:	addi	t6,s6,256
    73cc:	j	7420 <.L31>
    73d0:	bnez	a3,751c <.L24>
    73d4:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    73d8:	snez	a3,a4
    73dc:	slli	a3,a3,0x9
    73e0:	add	a3,a3,a0
    73e4:	sw	a3,0(a1)
    73e8:	ttmop	1,0,0
    73ec:	ttsetrwc	2,0,0,0,0,15
    73f0:	addi	a3,a4,-1
    73f4:	snez	a3,a3
    73f8:	slli	a3,a3,0x9
    73fc:	add	a3,a3,a0
    7400:	sub	a4,a2,a4
    7404:	ttstallwait	2,2064
    7408:	ttsempost	2
    740c:	sw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7410:	ttstallwait	128,2064
    7414:	sw	a3,0(a1)
    7418:	addi	t5,t5,-1
    741c:	beqz	t5,75d8 <.L49>
    7420:	ttsemwait	322,2,2
    7424:	lw	a4,16(zero) # 10 <.LLST2+0x2>
    7428:	lw	a3,-2000(gp) # ffb00020 <_ZN7ckernelL20throttled_mop_statusE>
    742c:	andi	a4,a4,1
    7430:	sw	a4,12(sp)
    7434:	lw	a4,12(sp)
    7438:	beqz	a4,73d0 <.L50>
    743c:	beq	a3,a2,74f4 <.L28>
    7440:	ttsetc16	12,2048
    7444:	ttsetc16	28,8
    7448:	ttsetc16	47,0
    744c:	ttsetc16	17,49344
    7450:	ttsetc16	33,11264
    7454:	ttsetc16	52,0
    7458:	ttsetc16	18,49344
    745c:	ttsetc16	34,35840
    7460:	ttsetc16	53,0
    7464:	ttsetc16	13,16400
    7468:	ttsetc16	29,8
    746c:	ttsetc16	48,0
    7470:	ttsetc16	14,24640
    7474:	ttsetc16	30,8
    7478:	ttsetc16	49,0
    747c:	ttsetc16	16,28768
    7480:	ttsetc16	32,1024
    7484:	ttsetc16	51,0
    7488:	ttreplay	16,11,0,1
    748c:	ttnop
    7490:	ttnop
    7494:	ttmvmul	0,0,0,0
    7498:	ttnop
    749c:	ttnop
    74a0:	ttmvmul	0,0,1,0
    74a4:	ttnop
    74a8:	ttnop
    74ac:	ttmvmul	0,0,0,0
    74b0:	ttnop
    74b4:	ttnop
    74b8:	li	a4,0
    74bc:	sw	a4,0(t4)
    74c0:	lw	a4,0(t4)
    74c4:	and	zero,zero,a4
    74c8:	sw	t1,0(a5) # ffb80000 <__global_pointer$+0x7f810>
    74cc:	sw	t1,4(a5)
    74d0:	sw	a7,8(a5)
    74d4:	sw	a7,12(a5)
    74d8:	sw	a7,16(a5)
    74dc:	sw	s0,20(a5)
    74e0:	sw	s5,24(a5)
    74e4:	sw	s4,28(a5)
    74e8:	sw	s1,32(a5)
    74ec:	ttsetrwc	0,0,0,0,0,15
    74f0:	sw	a2,-2000(gp) # ffb00020 <_ZN7ckernelL20throttled_mop_statusE>
    74f4:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    74f8:	snez	a3,a4
    74fc:	slli	a3,a3,0x9
    7500:	add	a3,a3,a0
    7504:	sw	a3,0(a1)
    7508:	ttmop	1,0,0
    750c:	ttmop	1,0,0
    7510:	ttsetrwc	1,0,0,0,0,15
    7514:	ttsetrwc	2,0,0,0,0,15
    7518:	j	73f0 <.L25>
    751c:	ttsetc16	12,2048
    7520:	ttsetc16	28,8
    7524:	ttsetc16	47,0
    7528:	ttsetc16	17,49344
    752c:	ttsetc16	33,11264
    7530:	ttsetc16	52,0
    7534:	ttsetc16	13,16400
    7538:	ttsetc16	29,8
    753c:	ttsetc16	48,0
    7540:	ttsetc16	14,24640
    7544:	ttsetc16	30,8
    7548:	ttsetc16	49,0
    754c:	ttsetc16	16,28768
    7550:	ttsetc16	32,1024
    7554:	ttsetc16	51,0
    7558:	ttreplay	16,16,0,1
    755c:	ttmvmul	0,0,0,0
    7560:	ttmvmul	0,0,1,0
    7564:	ttmvmul	0,0,0,0
    7568:	ttmvmul	0,0,2,0
    756c:	ttmvmul	0,0,0,0
    7570:	ttmvmul	0,0,1,0
    7574:	ttmvmul	0,0,0,0
    7578:	ttmvmul	0,0,4,0
    757c:	ttmvmul	0,0,0,0
    7580:	ttmvmul	0,0,1,0
    7584:	ttmvmul	0,0,0,0
    7588:	ttmvmul	0,0,2,0
    758c:	ttmvmul	0,0,0,0
    7590:	ttmvmul	0,0,1,0
    7594:	ttmvmul	0,0,0,0
    7598:	ttmvmul	0,0,5,0
    759c:	sw	a4,0(t4)
    75a0:	lw	a4,0(t4)
    75a4:	and	zero,zero,a4
    75a8:	sw	a2,0(a5)
    75ac:	sw	t1,4(a5)
    75b0:	sw	a7,8(a5)
    75b4:	sw	t2,12(a5)
    75b8:	sw	a7,16(a5)
    75bc:	sw	t6,20(a5)
    75c0:	sw	a7,24(a5)
    75c4:	sw	t6,28(a5)
    75c8:	sw	t6,32(a5)
    75cc:	ttsetrwc	0,0,0,0,0,15
    75d0:	sw	zero,-2000(gp) # ffb00020 <_ZN7ckernelL20throttled_mop_statusE>
    75d4:	j	73d4 <.L26>
    75d8:	addi	s3,s3,-1
    75dc:	bnez	s3,73c0 <.L32>
    75e0:	addi	a4,t0,-62
    75e4:	seqz	a4,a4
    75e8:	addi	t0,t0,1
    75ec:	li	a3,64
    75f0:	or	s7,s7,a4
    75f4:	bne	t0,a3,73ac <.L14>
    75f8:	lw	s0,60(sp)
    75fc:	lw	s1,56(sp)
    7600:	lw	s2,52(sp)
    7604:	lw	s3,48(sp)
    7608:	lw	s4,44(sp)
    760c:	lw	s5,40(sp)
    7610:	lw	s6,36(sp)
    7614:	lw	s7,32(sp)
    7618:	lw	s8,28(sp)
    761c:	lw	s9,24(sp)
    7620:	lw	s10,20(sp)
    7624:	lw	s11,16(sp)
    7628:	li	a0,0
    762c:	addi	sp,sp,64
    7630:	ret
    7634:	lui	s3,0x37c00
    7638:	addi	s3,s3,3 # 37c00003 <__device_print_strings_info_end+0x31700003>
    763c:	li	s11,7
    7640:	li	s5,4
    7644:	lui	a3,0x2000
    7648:	lui	s1,0x28008
    764c:	addi	t6,s6,256
    7650:	lui	s10,0x26008
    7654:	lui	s9,0x26014
    7658:	lui	s8,0x26010
    765c:	li	t5,12
    7660:	add	s2,a5,t5
    7664:	j	776c <.L19>
    7668:	ttsetc16	12,2048
    766c:	ttsetc16	28,8
    7670:	ttsetc16	47,0
    7674:	ttsetc16	17,49344
    7678:	ttsetc16	33,11264
    767c:	ttsetc16	52,0
    7680:	ttsetc16	18,49344
    7684:	ttsetc16	34,35840
    7688:	ttsetc16	53,0
    768c:	ttsetc16	13,16400
    7690:	ttsetc16	29,8
    7694:	ttsetc16	48,0
    7698:	ttsetc16	14,24640
    769c:	ttsetc16	30,8
    76a0:	ttsetc16	49,0
    76a4:	ttsetc16	16,28768
    76a8:	ttsetc16	32,1024
    76ac:	ttsetc16	51,0
    76b0:	ttreplay	16,11,0,1
    76b4:	ttnop
    76b8:	ttnop
    76bc:	ttmvmul	0,0,0,0
    76c0:	ttnop
    76c4:	ttnop
    76c8:	ttmvmul	0,0,1,0
    76cc:	ttnop
    76d0:	ttnop
    76d4:	ttmvmul	0,0,0,0
    76d8:	ttnop
    76dc:	ttnop
    76e0:	sw	a7,0(t4)
    76e4:	lw	a7,0(t4)
    76e8:	and	zero,zero,a7
    76ec:	sw	t1,0(a5)
    76f0:	sw	t1,4(a5)
    76f4:	sw	a3,8(a5)
    76f8:	sw	a3,0(s2)
    76fc:	sw	a3,16(a5)
    7700:	sw	s0,20(a5)
    7704:	sw	s10,24(a5)
    7708:	sw	s9,28(a5)
    770c:	sw	s8,32(a5)
    7710:	ttsetrwc	0,0,0,0,0,15
    7714:	lw	a7,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    7718:	sw	a2,-2000(gp) # ffb00020 <_ZN7ckernelL20throttled_mop_statusE>
    771c:	snez	a4,a7
    7720:	slli	a4,a4,0x9
    7724:	add	a4,a4,a0
    7728:	sw	a4,0(a1)
    772c:	ttmop	1,0,0
    7730:	ttmop	1,0,0
    7734:	ttsetrwc	1,0,0,0,0,15
    7738:	ttsetrwc	2,0,0,0,0,15
    773c:	addi	a4,a7,-1 # 1ffffff <.LASF142+0x1ff2ae1>
    7740:	snez	a4,a4
    7744:	slli	a4,a4,0x9
    7748:	add	a4,a4,a0
    774c:	sub	a7,a2,a7
    7750:	ttstallwait	2,2064
    7754:	ttsempost	2
    7758:	sw	a7,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    775c:	ttstallwait	128,2064
    7760:	sw	a4,0(a1)
    7764:	addi	t5,t5,-1
    7768:	beqz	t5,78e0 <.L51>
    776c:	ttsemwait	322,2,2
    7770:	ttsetc16	15,0
    7774:	ttsetc16	31,0
    7778:	ttsetc16	50,0
    777c:	ttsetc16	12,1
    7780:	ttsetc16	28,1
    7784:	ttsetc16	47,0
    7788:	ttsetc16	14,8
    778c:	ttsetc16	30,8
    7790:	ttsetc16	49,0
    7794:	li	a7,0
    7798:	mv	a4,a7
    779c:	sw	a4,0(t4)
    77a0:	lw	a4,0(t4)
    77a4:	and	zero,zero,a4
    77a8:	sw	s5,0(a5)
    77ac:	sw	t1,4(a5)
    77b0:	sw	a3,8(a5)
    77b4:	sw	s3,0(s2)
    77b8:	sw	a3,16(a5)
    77bc:	sw	s1,20(a5)
    77c0:	sw	a3,24(a5)
    77c4:	sw	s1,28(a5)
    77c8:	sw	s1,32(a5)
    77cc:	ttsetc16	7,0
    77d0:	ttsetrwc	0,0,0,0,0,15
    77d4:	lw	a4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    77d8:	snez	a4,a4
    77dc:	slli	a4,a4,0x9
    77e0:	add	a4,a4,a0
    77e4:	sw	a4,0(a1)
    77e8:	ttmop	1,0,0
    77ec:	ttsetrwc	0,0,0,0,0,4
    77f0:	ttsetc16	12,2048
    77f4:	ttsetc16	28,8
    77f8:	ttsetc16	47,0
    77fc:	ttsetc16	17,49344
    7800:	ttsetc16	33,11264
    7804:	ttsetc16	52,0
    7808:	ttsetc16	13,16400
    780c:	ttsetc16	29,8
    7810:	ttsetc16	48,0
    7814:	ttsetc16	14,24640
    7818:	ttsetc16	30,8
    781c:	ttsetc16	49,0
    7820:	ttsetc16	16,28768
    7824:	ttsetc16	32,1024
    7828:	ttsetc16	51,0
    782c:	ttreplay	16,16,0,1
    7830:	ttmvmul	0,0,0,0
    7834:	ttmvmul	0,0,1,0
    7838:	ttmvmul	0,0,0,0
    783c:	ttmvmul	0,0,2,0
    7840:	ttmvmul	0,0,0,0
    7844:	ttmvmul	0,0,1,0
    7848:	ttmvmul	0,0,0,0
    784c:	ttmvmul	0,0,4,0
    7850:	ttmvmul	0,0,0,0
    7854:	ttmvmul	0,0,1,0
    7858:	ttmvmul	0,0,0,0
    785c:	ttmvmul	0,0,2,0
    7860:	ttmvmul	0,0,0,0
    7864:	ttmvmul	0,0,1,0
    7868:	ttmvmul	0,0,0,0
    786c:	ttmvmul	0,0,5,0
    7870:	mv	a4,a7
    7874:	sw	a4,0(t4)
    7878:	lw	a4,0(t4)
    787c:	and	zero,zero,a4
    7880:	sw	a2,0(a5)
    7884:	sw	t1,4(a5)
    7888:	sw	a3,8(a5)
    788c:	sw	t2,0(s2)
    7890:	sw	a3,16(a5)
    7894:	sw	t6,20(a5)
    7898:	sw	a3,24(a5)
    789c:	sw	t6,28(a5)
    78a0:	sw	t6,32(a5)
    78a4:	ttsetrwc	0,0,0,0,0,15
    78a8:	sw	zero,-2000(gp) # ffb00020 <_ZN7ckernelL20throttled_mop_statusE>
    78ac:	lw	a4,16(zero) # 10 <.LLST2+0x2>
    78b0:	andi	a4,a4,1
    78b4:	sw	a4,12(sp)
    78b8:	lw	a4,12(sp)
    78bc:	bnez	a4,7668 <.L52>
    78c0:	lw	a7,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    78c4:	snez	a4,a7
    78c8:	slli	a4,a4,0x9
    78cc:	add	a4,a4,a0
    78d0:	sw	a4,0(a1)
    78d4:	ttmop	1,0,0
    78d8:	ttsetrwc	2,0,0,0,0,15
    78dc:	j	773c <.L16>
    78e0:	addi	s11,s11,-1
    78e4:	bnez	s11,765c <.L22>
    78e8:	addi	a4,t0,-62
    78ec:	seqz	a4,a4
    78f0:	addi	t0,t0,1
    78f4:	li	a3,64
    78f8:	or	s7,s7,a4
    78fc:	bne	t0,a3,73ac <.L14>
    7900:	j	75f8 <.L21>

######## TRISC2 (pack) — kernel=bmm_large_block_zm_fused_bias_activation ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/bmm_large_block_zm_fused_bias_activation/10390980522057353870/trisc2/trisc2.elf:     file format elf32-littleriscv
00007d10 <_start>:
    7d10:	addi	sp,sp,-144
    7d14:	sw	s0,140(sp)
    7d18:	sw	s1,136(sp)
    7d1c:	sw	s2,132(sp)
    7d20:	sw	s3,128(sp)
    7d24:	sw	s4,124(sp)
    7d28:	sw	s5,120(sp)
    7d2c:	sw	s6,116(sp)
    7d30:	sw	s7,112(sp)
    7d34:	sw	s8,108(sp)
    7d38:	sw	s9,104(sp)
    7d3c:	sw	s10,100(sp)
    7d40:	sw	s11,96(sp)
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
    7d70:	bltu	a4,a3,7d80 <.L4>
    7d74:	sw	zero,-12(a5)
    7d78:	sw	zero,-16(a5)
    7d7c:	mv	a3,a5
    7d80:	addi	a5,a3,-4
    7d84:	bltu	a4,a5,7d8c <.L5>
    7d88:	sw	zero,-8(a3)
    7d8c:	lui	a4,0x8
    7d90:	addi	a4,a4,1216 # 84c0 <__kernel_data_lma>
    7d94:	addi	a5,gp,48 # ffb00820 <__fw_export_ldm_end>
    7d98:	beq	a4,a5,7e08 <.L7>
    7d9c:	addi	a2,gp,48 # ffb00820 <__fw_export_ldm_end>
    7da0:	sub	a2,a2,a5
    7da4:	li	a1,8
    7da8:	srai	a3,a2,0x2
    7dac:	bge	a1,a2,7dec <.L8>
    7db0:	li	a2,2
    7db4:	lw	a7,0(a4)
    7db8:	lw	a6,4(a4)
    7dbc:	lw	a0,8(a4)
    7dc0:	mv	a1,a5
    7dc4:	mv	a5,a4
    7dc8:	addi	a5,a5,12
    7dcc:	addi	a1,a1,12
    7dd0:	addi	a3,a3,-3
    7dd4:	mv	a4,a5
    7dd8:	mv	a5,a1
    7ddc:	sw	a7,-12(a1)
    7de0:	sw	a6,-8(a1)
    7de4:	sw	a0,-4(a1)
    7de8:	blt	a2,a3,7db4 <.L9>
    7dec:	blez	a3,7e08 <.L7>
    7df0:	lw	a1,0(a4)
    7df4:	li	a2,2
    7df8:	sw	a1,0(a5)
    7dfc:	bne	a3,a2,7e08 <.L7>
    7e00:	lw	a4,4(a4)
    7e04:	sw	a4,4(a5)
    7e08:	lw	a5,1056(zero) # 420 <.LASF1612+0x3>
    7e0c:	li	a4,128
    7e10:	slli	a5,a5,0x2
    7e14:	lbu	a3,1011(a5)
    7e18:	addi	a5,a5,96
    7e1c:	beq	a3,a4,7e2c <.L13>
    7e20:	fence
    7e24:	lbu	a3,915(a5)
    7e28:	bne	a3,a4,7e20 <.L11>
    7e2c:	lui	a4,0xffb00
    7e30:	lw	a5,-2004(gp) # ffb0001c <_ZN7ckernel12cfg_state_idE>
    7e34:	addi	s7,a4,32 # ffb00020 <cb_interface>
    7e38:	lw	a7,168(s7)
    7e3c:	lui	a4,0xffef0
    7e40:	beqz	a5,7e48 <.L12>
    7e44:	addi	a4,a4,896 # ffef0380 <__instrn_buffer+0xb0380>
    7e48:	lui	t3,0x45000
    7e4c:	lui	a5,0xffe40
    7e50:	mv	a5,a5
    7e54:	addi	t6,t3,56 # 45000038 <__device_print_strings_info_end+0x3eb00038>
    7e58:	lui	a6,0x45004
    7e5c:	sw	t6,0(a5) # ffe40000 <__instrn_buffer>
    7e60:	addi	a6,a6,57 # 45004039 <__device_print_strings_info_end+0x3eb04039>
    7e64:	lui	a0,0x45040
    7e68:	sw	a6,0(a5)
    7e6c:	addi	a0,a0,58 # 4504003a <__device_print_strings_info_end+0x3eb4003a>
    7e70:	lui	a1,0x45100
    7e74:	sw	a0,0(a5)
    7e78:	addi	a1,a1,59 # 4510003b <__device_print_strings_info_end+0x3ec0003b>
    7e7c:	sw	a1,0(a5)
    7e80:	ttstallwait	128,1
    7e84:	ttwrcfg	28,0,12
    7e88:	ttwrcfg	29,0,13
    7e8c:	ttnop
    7e90:	ttnop
    7e94:	ttatgetm	0
    7e98:	lui	a3,0xb5800
    7e9c:	addi	a3,a3,71 # b5800047 <__device_print_strings_info_end+0xaf300047>
    7ea0:	sw	a3,0(a5)
    7ea4:	lui	a3,0xb61e0
    7ea8:	addi	a3,a3,1 # b61e0001 <__device_print_strings_info_end+0xafce0001>
    7eac:	sw	a3,0(a5)
    7eb0:	lui	a3,0xb3fc0
    7eb4:	addi	a3,a3,2 # b3fc0002 <__device_print_strings_info_end+0xadac0002>
    7eb8:	sw	a3,0(a5)
    7ebc:	lui	a3,0xb4ff0
    7ec0:	addi	a3,a3,2 # b4ff0002 <__device_print_strings_info_end+0xaeaf0002>
    7ec4:	sw	a3,0(a5)
    7ec8:	lui	a3,0xb53f0
    7ecc:	addi	a3,a3,2 # b53f0002 <__device_print_strings_info_end+0xaeef0002>
    7ed0:	sw	a3,0(a5)
    7ed4:	ttatrelm	0
    7ed8:	lui	a3,0xb5100
    7edc:	addi	a3,a3,71 # b5100047 <__device_print_strings_info_end+0xaec00047>
    7ee0:	sw	a3,0(a5)
    7ee4:	lui	a3,0xb6ff0
    7ee8:	addi	a3,a3,71 # b6ff0047 <__device_print_strings_info_end+0xb0af0047>
    7eec:	sw	a3,0(a5)
    7ef0:	lui	a2,0x40
    7ef4:	sw	a2,272(a4)
    7ef8:	li	t1,1
    7efc:	sw	t1,280(a4)
    7f00:	ttstallwait	128,8
    7f04:	lui	a3,0xb3040
    7f08:	addi	a3,a3,70 # b3040046 <__device_print_strings_info_end+0xacb40046>
    7f0c:	sw	a3,0(a5)
    7f10:	lui	a3,0xb5080
    7f14:	addi	a3,a3,71 # b5080047 <__device_print_strings_info_end+0xaeb80047>
    7f18:	sw	a3,32(sp)
    7f1c:	sw	a3,0(a5)
    7f20:	sw	t1,72(a4)
    7f24:	lui	a3,0xffe00
    7f28:	sw	a2,208(a3) # ffe000d0 <__fw_export_ldm_end+0x2ff8b0>
    7f2c:	sw	zero,92(sp)
    7f30:	lw	t5,208(a3)
    7f34:	lui	t4,0x1
    7f38:	lui	a2,0x10
    7f3c:	addi	a2,a2,-1 # ffff <.LASF151+0x4f80>
    7f40:	sw	t5,92(sp)
    7f44:	sw	t4,112(a4)
    7f48:	sw	a2,96(a4)
    7f4c:	sw	zero,80(a4)
    7f50:	sw	a7,64(a3)
    7f54:	sw	zero,68(a3)
    7f58:	sw	zero,72(a3)
    7f5c:	sw	zero,76(a3)
    7f60:	sw	zero,88(sp)
    7f64:	lw	a4,76(a3)
    7f68:	sw	a4,88(sp)
    7f6c:	ttsetadcxx	4,15,0
    7f70:	ttsetc16	37,260
    7f74:	ttsetc16	38,10272
    7f78:	ttsetc16	39,4384
    7f7c:	lui	a2,0xffe80
    7f80:	addi	a7,a2,8 # ffe80008 <__instrn_buffer+0x40008>
    7f84:	li	a4,0
    7f88:	sw	a4,0(a7)
    7f8c:	lw	a4,0(a7)
    7f90:	and	zero,zero,a4
    7f94:	lui	a4,0xffb80
    7f98:	li	a7,4
    7f9c:	sw	a7,0(a4) # ffb80000 <__fw_export_ldm_end+0x7f7e0>
    7fa0:	sw	a7,4(a4)
    7fa4:	lui	a7,0x2000
    7fa8:	sw	a7,8(a4)
    7fac:	sw	a7,12(a4)
    7fb0:	sw	a7,16(a4)
    7fb4:	lui	t4,0x41000
    7fb8:	sw	t4,20(a4)
    7fbc:	sw	a7,24(a4)
    7fc0:	lui	a7,0x41008
    7fc4:	add	a7,a7,t1
    7fc8:	sw	a7,28(a4)
    7fcc:	lui	a7,0x41010
    7fd0:	sw	a7,32(a4)
    7fd4:	sw	t6,0(a5)
    7fd8:	sw	a6,0(a5)
    7fdc:	sw	a0,0(a5)
    7fe0:	sw	a1,0(a5)
    7fe4:	ttstallwait	128,1
    7fe8:	ttwrcfg	28,0,12
    7fec:	ttwrcfg	29,0,13
    7ff0:	ttnop
    7ff4:	ttnop
    7ff8:	ttsetadcxx	4,15,0
    7ffc:	li	a4,0
    8000:	addi	a2,a2,4
    8004:	sw	a4,0(a2)
    8008:	lw	a4,0(a2)
    800c:	and	zero,zero,a4
    8010:	sw	zero,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8014:	ttstallwait	33,8
    8018:	ttsetdmareg	0,0,0,8
    801c:	ttsetdmareg	0,512,0,16
    8020:	ttstallwait	128,1
    8024:	lui	a4,0xb0048
    8028:	addi	a4,a4,180 # b00480b4 <__device_print_strings_info_end+0xa9b480b4>
    802c:	sw	a4,12(sp)
    8030:	sw	a4,0(a5)
    8034:	ttdmanop
    8038:	ttdmanop
    803c:	ttsetadcxy	4,0,0,0,0,11
    8040:	ttsetadczw	4,0,0,0,0,15
    8044:	lw	a4,136(s7)
    8048:	lui	a3,0x1000
    804c:	addi	a6,a3,-256 # ffff00 <.LASF151+0xff4e81>
    8050:	sw	a4,36(sp)
    8054:	slli	a4,a4,0x8
    8058:	addi	a3,t3,32
    805c:	and	a4,a4,a6
    8060:	add	a4,a4,a3
    8064:	sw	a4,76(sp)
    8068:	lw	a4,172(s7)
    806c:	lw	a2,132(s7)
    8070:	sw	a4,24(sp)
    8074:	lw	a4,164(s7)
    8078:	lw	s11,168(s7)
    807c:	lui	a3,0xb5081
    8080:	sw	a2,40(sp)
    8084:	lw	a2,128(s7)
    8088:	sw	a4,16(sp)
    808c:	addi	a3,a3,-1977 # b5080847 <__device_print_strings_info_end+0xaeb80847>
    8090:	lw	s8,140(s7)
    8094:	lw	a4,160(s7)
    8098:	sw	a2,44(sp)
    809c:	sw	a3,28(sp)
    80a0:	mv	a0,t1
    80a4:	lui	s9,0xb0088
    80a8:	li	a7,0
    80ac:	li	s6,0
    80b0:	mv	a2,s11
    80b4:	lui	a3,0x67611
    80b8:	addi	a3,a3,1034 # 6761140a <__device_print_strings_info_end+0x6111140a>
    80bc:	sw	a3,20(sp)
    80c0:	li	s11,7
    80c4:	addi	s10,t3,24
    80c8:	li	a3,63
    80cc:	beq	a7,a3,8294 <.L38>
    80d0:	lui	a3,0xb3040
    80d4:	li	t5,12
    80d8:	lui	t2,0xffb44
    80dc:	lui	s4,0xffb45
    80e0:	li	t0,1
    80e4:	addi	s5,a3,70 # b3040046 <__device_print_strings_info_end+0xacb40046>
    80e8:	lui	s3,0x508c0
    80ec:	lui	s2,0x800
    80f0:	addi	t6,t3,25
    80f4:	lui	s1,0x10144
    80f8:	addi	s0,t3,48
    80fc:	beqz	a7,8244 <.L50>
    8100:	lhu	a1,186(s7)
    8104:	lw	a3,32(s4) # ffb45020 <__fw_export_ldm_end+0x44800>
    8108:	lw	t1,24(sp)
    810c:	add	a3,t1,a3
    8110:	zext.h	a3,a3
    8114:	beq	a1,a3,8104 <.L22>
    8118:	ttsemwait	1,2,1
    811c:	beqz	a7,8280 <.L51>
    8120:	beq	a7,t0,8264 <.L52>
    8124:	lw	t1,180(s7)
    8128:	lw	a3,188(s7)
    812c:	sw	s3,0(a5)
    8130:	add	a3,t1,a3
    8134:	addi	a3,a3,-1
    8138:	slli	t4,a3,0x8
    813c:	and	t4,t4,a6
    8140:	srli	a3,a3,0x10
    8144:	add	t4,t4,s10
    8148:	slli	a3,a3,0x8
    814c:	sw	t4,0(a5)
    8150:	or	t4,a3,s2
    8154:	add	t4,t4,t6
    8158:	sw	t4,0(a5)
    815c:	ttstallwait	128,1
    8160:	ttwrcfg	12,0,69
    8164:	add	a3,a3,t6
    8168:	sw	a3,0(a5)
    816c:	ttdmanop
    8170:	ttmop	1,0,0
    8174:	ttsetadczw	4,0,0,0,0,5
    8178:	ttstallwait	64,8
    817c:	add	a3,s6,s1
    8180:	sw	a3,0(a5)
    8184:	ttsemget	2
    8188:	xori	t4,s6,1
    818c:	sw	t4,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    8190:	lw	a3,12(sp)
    8194:	beq	s6,t0,819c <.L25>
    8198:	addi	a3,s9,180 # b00880b4 <__device_print_strings_info_end+0xa9b880b4>
    819c:	sw	a3,0(a5)
    81a0:	ttdmanop
    81a4:	ttdmanop
    81a8:	add	t1,a2,t1
    81ac:	lw	a3,16(sp)
    81b0:	sw	t1,180(s7)
    81b4:	sw	zero,188(s7)
    81b8:	bltu	t1,a3,81c4 <.L26>
    81bc:	sub	t1,t1,a4
    81c0:	sw	t1,180(s7)
    81c4:	addi	a1,a1,1
    81c8:	zext.h	a1,a1
    81cc:	sh	a1,186(s7)
    81d0:	slli	a1,a1,0x8
    81d4:	add	a1,a1,s0
    81d8:	sw	a1,0(a5)
    81dc:	ttstallwait	32,8
    81e0:	lw	a3,20(sp)
    81e4:	addi	t5,t5,-1
    81e8:	sw	a3,0(a5)
    81ec:	mv	s6,t4
    81f0:	bnez	t5,80fc <.L27>
    81f4:	addi	s11,s11,-1
    81f8:	bnez	s11,80c8 <.L30>
    81fc:	addi	a7,a7,1 # 41010001 <__device_print_strings_info_end+0x3ab10001>
    8200:	li	a3,64
    8204:	bne	a7,a3,80b4 <.L14>
    8208:	lw	s0,140(sp)
    820c:	lw	s1,136(sp)
    8210:	lw	s2,132(sp)
    8214:	lw	s3,128(sp)
    8218:	lw	s4,124(sp)
    821c:	lw	s5,120(sp)
    8220:	lw	s6,116(sp)
    8224:	lw	s7,112(sp)
    8228:	lw	s8,108(sp)
    822c:	lw	s9,104(sp)
    8230:	lw	s10,100(sp)
    8234:	lw	s11,96(sp)
    8238:	li	a0,0
    823c:	addi	sp,sp,144
    8240:	ret
    8244:	lhu	a1,154(s7)
    8248:	lw	a3,32(t2) # ffb44020 <__fw_export_ldm_end+0x43800>
    824c:	add	a3,s8,a3
    8250:	sub	a3,a3,a1
    8254:	zext.h	a3,a3
    8258:	blt	a3,a0,8248 <.L21>
    825c:	addi	a0,a0,1
    8260:	j	8100 <.L20>
    8264:	ttstallwait	128,8
    8268:	lui	a3,0xb3040
    826c:	addi	a3,a3,1094 # b3040446 <__device_print_strings_info_end+0xacb40446>
    8270:	sw	a3,0(a5)
    8274:	lw	a3,28(sp)
    8278:	sw	a3,0(a5)
    827c:	j	8124 <.L24>
    8280:	ttstallwait	128,8
    8284:	lw	a3,32(sp)
    8288:	sw	s5,0(a5)
    828c:	sw	a3,0(a5)
    8290:	j	8124 <.L24>
    8294:	lui	t0,0xb5100
    8298:	addi	a3,t0,71 # b5100047 <__device_print_strings_info_end+0xaec00047>
    829c:	lui	t6,0xb6ff0
    82a0:	lui	t5,0xb61e1
    82a4:	sw	a3,48(sp)
    82a8:	addi	a3,t6,71 # b6ff0047 <__device_print_strings_info_end+0xb0af0047>
    82ac:	lui	t4,0x45002
    82b0:	sw	a3,52(sp)
    82b4:	addi	a3,t5,-1535 # b61e0a01 <__device_print_strings_info_end+0xafce0a01>
    82b8:	lui	t1,0x45020
    82bc:	sw	a3,56(sp)
    82c0:	addi	a3,t4,57 # 45002039 <__device_print_strings_info_end+0x3eb02039>
    82c4:	lui	a1,0x45080
    82c8:	sw	a3,60(sp)
    82cc:	addi	a3,t1,58 # 4502003a <__device_print_strings_info_end+0x3eb2003a>
    82d0:	sw	a3,64(sp)
    82d4:	addi	a3,a1,59 # 4508003b <__device_print_strings_info_end+0x3eb8003b>
    82d8:	sw	a3,68(sp)
    82dc:	lui	a3,0x67611
    82e0:	addi	a3,a3,10 # 6761100a <__device_print_strings_info_end+0x6111100a>
    82e4:	lui	t2,0xb5800
    82e8:	lui	s2,0x45055
    82ec:	lui	s1,0x45100
    82f0:	lui	s0,0xb01c0
    82f4:	lui	s3,0xb30b0
    82f8:	sw	a3,72(sp)
    82fc:	lw	a3,44(sp)
    8300:	addi	s5,t2,71 # b5800047 <__device_print_strings_info_end+0xaf300047>
    8304:	addi	s2,s2,316 # 4505513c <__device_print_strings_info_end+0x3eb5513c>
    8308:	addi	s1,s1,56 # 45100038 <__device_print_strings_info_end+0x3ec00038>
    830c:	addi	s0,s0,28 # b01c001c <__device_print_strings_info_end+0xa9cc001c>
    8310:	addi	s4,s3,274 # b30b0112 <__device_print_strings_info_end+0xacbb0112>
    8314:	mv	t1,s6
    8318:	li	t2,12
    831c:	lui	t5,0xffb44
    8320:	lhu	t4,154(s7)
    8324:	lw	a1,32(t5) # ffb44020 <__fw_export_ldm_end+0x43800>
    8328:	add	a1,s8,a1
    832c:	zext.h	a1,a1
    8330:	beq	t4,a1,8324 <.L15>
    8334:	ttsemwait	1,2,1
    8338:	sw	s2,0(a5)
    833c:	ttstallwait	128,9
    8340:	ttwrcfg	30,0,70
    8344:	lui	a1,0x45000
    8348:	sw	s1,0(a5)
    834c:	addi	a1,a1,57 # 45000039 <__device_print_strings_info_end+0x3eb00039>
    8350:	sw	a1,0(a5)
    8354:	sw	s0,0(a5)
    8358:	lw	a1,76(sp)
    835c:	sw	s4,0(a5)
    8360:	sw	s5,0(a5)
    8364:	sw	a1,0(a5)
    8368:	lw	a1,48(sp)
    836c:	sw	a1,0(a5)
    8370:	lw	a1,52(sp)
    8374:	sw	a1,0(a5)
    8378:	lw	a1,56(sp)
    837c:	sw	a1,0(a5)
    8380:	addi	a1,t3,56
    8384:	sw	a1,0(a5)
    8388:	lw	a1,60(sp)
    838c:	sw	a1,0(a5)
    8390:	lw	a1,64(sp)
    8394:	sw	a1,0(a5)
    8398:	lw	a1,68(sp)
    839c:	sw	a1,0(a5)
    83a0:	ttstallwait	128,1
    83a4:	ttwrcfg	28,0,12
    83a8:	ttwrcfg	29,0,13
    83ac:	ttnop
    83b0:	ttnop
    83b4:	ttstallwait	128,8
    83b8:	lw	a1,148(s7)
    83bc:	lw	t6,156(s7)
    83c0:	lui	t0,0xb3040
    83c4:	lw	s3,32(sp)
    83c8:	addi	t0,t0,70 # b3040046 <__device_print_strings_info_end+0xacb40046>
    83cc:	add	t6,a1,t6
    83d0:	sw	t0,0(a5)
    83d4:	addi	t6,t6,-1
    83d8:	sw	s3,0(a5)
    83dc:	slli	t0,t6,0x8
    83e0:	lui	s3,0x508c0
    83e4:	sw	s3,0(a5)
    83e8:	and	t0,t0,a6
    83ec:	addi	s3,t3,24
    83f0:	add	t0,t0,s3
    83f4:	srli	t6,t6,0x10
    83f8:	sw	t0,0(a5)
    83fc:	slli	t6,t6,0x8
    8400:	lui	t0,0x800
    8404:	or	t0,t6,t0
    8408:	addi	s3,t3,25
    840c:	add	t0,t0,s3
    8410:	sw	t0,0(a5)
    8414:	ttstallwait	128,1
    8418:	ttwrcfg	12,0,69
    841c:	add	t6,t6,s3
    8420:	sw	t6,0(a5)
    8424:	ttdmanop
    8428:	ttmop	1,0,0
    842c:	ttsetadczw	4,0,0,0,0,5
    8430:	ttstallwait	64,8
    8434:	lui	t6,0x10144
    8438:	add	t6,s6,t6
    843c:	sw	t6,0(a5)
    8440:	ttsemget	2
    8444:	xori	s6,s6,1
    8448:	sw	s6,-2032(gp) # ffb00000 <_ZN7ckernel14dest_offset_idE>
    844c:	li	t0,1
    8450:	lw	t6,12(sp)
    8454:	beq	t1,t0,845c <.L16>
    8458:	addi	t6,s9,180
    845c:	sw	t6,0(a5)
    8460:	ttdmanop
    8464:	ttdmanop
    8468:	lw	t1,36(sp)
    846c:	sw	zero,156(s7)
    8470:	add	a1,t1,a1
    8474:	lw	t1,40(sp)
    8478:	sw	a1,148(s7)
    847c:	bltu	a1,t1,8488 <.L17>
    8480:	sub	a1,a1,a3
    8484:	sw	a1,148(s7)
    8488:	addi	a1,t4,1
    848c:	addi	t1,t3,48
    8490:	zext.h	a1,a1
    8494:	sh	a1,154(s7)
    8498:	slli	a1,a1,0x8
    849c:	add	a1,a1,t1
    84a0:	sw	a1,0(a5)
    84a4:	ttstallwait	32,8
    84a8:	lw	a1,72(sp)
    84ac:	addi	t2,t2,-1
    84b0:	sw	a1,0(a5)
    84b4:	beqz	t2,81f4 <.L19>
    84b8:	mv	t1,s6
    84bc:	j	8320 <.L18>

######## BRISC (writer) — kernel=writer_bmm_tile_layout ########

/home/boop/.cache/tt-metal-cache/5327768567736097984/kernels/writer_bmm_tile_layout/4484800811839388329/brisc/brisc.elf:     file format elf32-littleriscv
00004b60 <_start>:
    4b60:	addi	sp,sp,-144
    4b64:	sw	s3,128(sp)
    4b68:	sw	s5,120(sp)
    4b6c:	sw	s9,104(sp)
    4b70:	sw	s10,100(sp)
    4b74:	sw	s11,96(sp)
    4b78:	lui	a5,0xffb01
    4b7c:	addi	a5,a5,-960 # ffb00c40 <__fw_export_ldm_end+0x10>
    4b80:	addi	a4,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4b84:	bltu	a4,a5,4ba0 <.L2>
    4b88:	sw	zero,-4(a5)
    4b8c:	sw	zero,-8(a5)
    4b90:	sw	zero,-12(a5)
    4b94:	sw	zero,-16(a5)
    4b98:	addi	a5,a5,16
    4b9c:	bgeu	a4,a5,4b88 <.L3>
    4ba0:	addi	a3,a5,-8
    4ba4:	bltu	a4,a3,4bb4 <.L4>
    4ba8:	sw	zero,-12(a5)
    4bac:	sw	zero,-16(a5)
    4bb0:	mv	a3,a5
    4bb4:	addi	a5,a3,-4
    4bb8:	bltu	a4,a5,4bc0 <.L5>
    4bbc:	sw	zero,-8(a3)
    4bc0:	lui	a4,0x5
    4bc4:	addi	a4,a4,216 # 50d8 <__kernel_data_lma>
    4bc8:	addi	a5,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4bcc:	beq	a4,a5,4c3c <.L7>
    4bd0:	addi	a2,gp,1088 # ffb00c30 <__fw_export_ldm_end>
    4bd4:	sub	a2,a2,a5
    4bd8:	li	a1,8
    4bdc:	srai	a3,a2,0x2
    4be0:	bge	a1,a2,4c20 <.L8>
    4be4:	li	a2,2
    4be8:	lw	a7,0(a4)
    4bec:	lw	a6,4(a4)
    4bf0:	lw	a0,8(a4)
    4bf4:	mv	a1,a5
    4bf8:	mv	a5,a4
    4bfc:	addi	a5,a5,12
    4c00:	addi	a1,a1,12
    4c04:	addi	a3,a3,-3
    4c08:	mv	a4,a5
    4c0c:	mv	a5,a1
    4c10:	sw	a7,-12(a1)
    4c14:	sw	a6,-8(a1)
    4c18:	sw	a0,-4(a1)
    4c1c:	blt	a2,a3,4be8 <.L9>
    4c20:	blez	a3,4c3c <.L7>
    4c24:	lw	a1,0(a4)
    4c28:	li	a2,2
    4c2c:	sw	a1,0(a5)
    4c30:	bne	a3,a2,4c3c <.L7>
    4c34:	lw	a4,4(a4)
    4c38:	sw	a4,4(a5)
    4c3c:	lui	a5,0xffb20
    4c40:	lw	a7,520(a5) # ffb20208 <__fw_export_ldm_end+0x1f5d8>
    4c44:	lw	a0,552(a5)
    4c48:	lw	a1,516(a5)
    4c4c:	lw	a2,512(a5)
    4c50:	lw	a4,556(a5)
    4c54:	addi	s9,gp,-1992 # ffb00028 <noc_nonposted_writes_acked>
    4c58:	addi	s10,gp,-1984 # ffb00030 <noc_nonposted_writes_num_issued>
    4c5c:	sw	a4,-2008(gp) # ffb00018 <noc_posted_writes_num_issued>
    4c60:	sw	a7,-1976(gp) # ffb00038 <noc_reads_num_issued>
    4c64:	sw	a0,0(s10)
    4c68:	sw	a1,0(s9)
    4c6c:	sw	a2,-2000(gp) # ffb00020 <noc_nonposted_atomics_acked>
    4c70:	lw	a5,1056(zero) # 420 <.LVUS83+0xb>
    4c74:	li	a4,128
    4c78:	slli	a5,a5,0x2
    4c7c:	lbu	a3,1011(a5)
    4c80:	addi	a5,a5,96
    4c84:	beq	a3,a4,4c94 <.L14>
    4c88:	fence
    4c8c:	lbu	a3,915(a5)
    4c90:	bne	a3,a4,4c88 <.L11>
    4c94:	lw	a5,-2012(gp) # ffb00014 <rta_l1_base>
    4c98:	lui	a4,0x1
    4c9c:	lw	a1,8(a5)
    4ca0:	lw	a2,0(a5)
    4ca4:	lw	a3,48(a5)
    4ca8:	addi	a4,a4,-2048 # 800 <.LASF1736+0x1>
    4cac:	sw	a4,88(sp)
    4cb0:	sw	a4,92(sp)
    4cb4:	lw	s3,16(a5)
    4cb8:	lw	a4,4(a5)
    4cbc:	lw	t1,20(a5)
    4cc0:	lw	s11,24(a5)
    4cc4:	lw	s5,28(a5)
    4cc8:	lw	t3,32(a5)
    4ccc:	sw	a1,4(sp)
    4cd0:	lw	a1,12(a5)
    4cd4:	sw	a2,80(sp)
    4cd8:	lw	t5,36(a5)
    4cdc:	lw	a0,40(a5)
    4ce0:	lw	a6,44(a5)
    4ce4:	sw	a1,8(sp)
    4ce8:	beqz	a3,50b8 <.L12>
    4cec:	li	a5,0
    4cf0:	beqz	a0,50b8 <.L12>
    4cf4:	lui	a1,0x2
    4cf8:	lui	a2,0x10000
    4cfc:	sw	s6,116(sp)
    4d00:	sw	s7,112(sp)
    4d04:	sw	s8,108(sp)
    4d08:	addi	s7,a1,146 # 2092 <.LASF374+0x14>
    4d0c:	addi	s6,a2,15 # 1000000f <__device_print_strings_info_end+0x9b0000f>
    4d10:	mv	t4,s3
    4d14:	mv	a7,a0
    4d18:	mv	a2,a3
    4d1c:	sw	s4,124(sp)
    4d20:	lui	s8,0xffffc
    4d24:	mv	s3,s11
    4d28:	mv	a1,s5
    4d2c:	mv	a0,t3
    4d30:	mv	a3,t5
    4d34:	lui	t3,0x1000
    4d38:	addi	t3,t3,-1 # ffffff <.LASF1597+0xff609d>
    4d3c:	lui	t5,0xffb00
    4d40:	sw	t3,24(sp)
    4d44:	addi	s4,t5,1064 # ffb00428 <cb_interface>
    4d48:	mv	t6,a4
    4d4c:	li	t0,0
    4d50:	beqz	a3,509c <.L27>
    4d54:	mv	t5,a4
    4d58:	sw	s0,140(sp)
    4d5c:	mv	a4,a5
    4d60:	sw	s1,136(sp)
    4d64:	mv	a5,t4
    4d68:	sw	s2,132(sp)
    4d6c:	mv	t4,a6
    4d70:	mv	a6,a2
    4d74:	mv	s5,t1
    4d78:	mv	s2,a6
    4d7c:	mv	a2,t6
    4d80:	li	t3,0
    4d84:	lui	s11,0xffb50
    4d88:	mv	s1,t5
    4d8c:	mv	t2,a7
    4d90:	mv	t1,t4
    4d94:	mv	a6,a4
    4d98:	lw	a7,32(s11) # ffb50020 <__fw_export_ldm_end+0x4f3f0>
    4d9c:	lw	a4,40(s11)
    4da0:	sub	a4,a4,a7
    4da4:	zext.h	a4,a4
    4da8:	blt	a4,a0,4d9c <.L15>
    4dac:	beqz	a1,5004 <.L16>
    4db0:	beqz	s3,5004 <.L16>
    4db4:	lui	a4,0x92492
    4db8:	addi	a4,a4,1171 # 92492493 <__device_print_strings_info_end+0x8bf92493>
    4dbc:	addi	a7,gp,-1960 # ffb00048 <dram_bank_to_noc_xy>
    4dc0:	sw	a4,12(sp)
    4dc4:	lw	t5,528(s4)
    4dc8:	slli	a4,s3,0xb
    4dcc:	sw	a7,16(sp)
    4dd0:	sw	a4,20(sp)
    4dd4:	sw	a0,40(sp)
    4dd8:	sw	t1,52(sp)
    4ddc:	mv	s0,a2
    4de0:	li	a7,0
    4de4:	lui	t4,0x4
    4de8:	lui	a4,0xffb20
    4dec:	sw	s1,28(sp)
    4df0:	sw	a5,32(sp)
    4df4:	sw	s5,36(sp)
    4df8:	sw	a3,44(sp)
    4dfc:	sw	t2,48(sp)
    4e00:	mv	a0,a2
    4e04:	mv	t1,t6
    4e08:	sw	s2,64(sp)
    4e0c:	mv	a2,t5
    4e10:	mv	t6,s0
    4e14:	li	s1,0
    4e18:	sw	a7,56(sp)
    4e1c:	sw	a1,60(sp)
    4e20:	mv	s5,a0
    4e24:	mv	s2,t3
    4e28:	sw	a6,68(sp)
    4e2c:	lw	a5,12(sp)
    4e30:	lw	a1,88(sp)
    4e34:	mulhu	a5,t6,a5
    4e38:	lw	a7,80(sp)
    4e3c:	srli	a5,a5,0x2
    4e40:	slli	a3,a5,0x3
    4e44:	mul	a0,a5,a1
    4e48:	sub	a3,a3,a5
    4e4c:	lw	a1,16(sp)
    4e50:	sub	a3,t6,a3
    4e54:	addi	a5,gp,-1492 # ffb0021c <bank_to_dram_offset>
    4e58:	sh2add	a5,a3,a5
    4e5c:	sh1add	a3,a3,a1
    4e60:	lw	a1,0(a5)
    4e64:	add	a5,a0,a7
    4e68:	lhu	a7,0(a3)
    4e6c:	lw	a3,92(sp)
    4e70:	add	a5,a5,a1
    4e74:	slli	a7,a7,0x4
    4e78:	mv	t3,a5
    4e7c:	mv	a0,a7
    4e80:	mv	a1,a2
    4e84:	bgeu	t4,a3,4f50 <.L20>
    4e88:	lui	a1,0xffffc
    4e8c:	addi	a1,a1,-1 # ffffbfff <__fw_export_ldm_end+0x4fb3cf>
    4e90:	add	a6,a3,a1
    4e94:	and	a1,a6,s8
    4e98:	add	a1,a1,t4
    4e9c:	add	a1,a1,a2
    4ea0:	mv	a0,a5
    4ea4:	mv	t2,a7
    4ea8:	mv	t3,a2
    4eac:	sw	s3,72(sp)
    4eb0:	sw	a2,76(sp)
    4eb4:	lw	a2,64(a4) # ffb20040 <__fw_export_ldm_end+0x1f410>
    4eb8:	bnez	a2,4eb4 <.L18>
    4ebc:	sw	s7,28(a4)
    4ec0:	sw	t3,0(a4)
    4ec4:	sw	a0,12(a4)
    4ec8:	lw	s3,24(sp)
    4ecc:	and	a2,t2,s6
    4ed0:	sw	a2,16(a4)
    4ed4:	srli	a2,t2,0x4
    4ed8:	and	a2,a2,s3
    4edc:	sw	a2,20(a4)
    4ee0:	sw	t4,32(a4)
    4ee4:	li	a2,1
    4ee8:	sw	a2,64(a4)
    4eec:	lw	a2,0(s10)
    4ef0:	add	s3,a0,t4
    4ef4:	addi	a2,a2,1
    4ef8:	sw	a2,0(s10)
    4efc:	lw	a2,0(s9)
    4f00:	sltu	a0,s3,a0
    4f04:	addi	a2,a2,1
    4f08:	add	t3,t3,t4
    4f0c:	sw	a2,0(s9)
    4f10:	add	t2,a0,t2
    4f14:	mv	a0,s3
    4f18:	bne	t3,a1,4eb4 <.L18>
    4f1c:	srli	a0,a6,0xe
    4f20:	slli	t3,a0,0xe
    4f24:	sub	a3,a3,t4
    4f28:	addi	a0,a0,1
    4f2c:	sub	a3,a3,t3
    4f30:	slli	t3,a0,0xe
    4f34:	add	t3,a5,t3
    4f38:	srli	a0,a0,0x12
    4f3c:	sltu	a5,t3,a5
    4f40:	add	a0,a7,a0
    4f44:	lw	s3,72(sp)
    4f48:	lw	a2,76(sp)
    4f4c:	add	a0,a5,a0
    4f50:	lw	a5,64(a4)
    4f54:	bnez	a5,4f50 <.L20>
    4f58:	sw	s7,28(a4)
    4f5c:	sw	a1,0(a4)
    4f60:	sw	t3,12(a4)
    4f64:	and	a5,a0,s6
    4f68:	sw	a5,16(a4)
    4f6c:	srli	a0,a0,0x4
    4f70:	sw	a0,20(a4)
    4f74:	sw	a3,32(a4)
    4f78:	li	a5,1
    4f7c:	sw	a5,64(a4)
    4f80:	lw	a5,0(s9)
    4f84:	lw	a3,0(s10)
    4f88:	addi	a5,a5,1
    4f8c:	addi	a3,a3,1
    4f90:	sw	a5,0(s9)
    4f94:	lw	a5,4(sp)
    4f98:	addi	a2,a2,2047
    4f9c:	addi	s1,s1,1
    4fa0:	sw	a3,0(s10)
    4fa4:	addi	a2,a2,1
    4fa8:	add	t6,t6,a5
    4fac:	bne	s3,s1,4e2c <.L21>
    4fb0:	lw	a5,20(sp)
    4fb4:	lw	a7,56(sp)
    4fb8:	add	t5,t5,a5
    4fbc:	lw	a1,60(sp)
    4fc0:	lw	a5,8(sp)
    4fc4:	addi	a7,a7,1
    4fc8:	mv	t3,s2
    4fcc:	lw	a6,68(sp)
    4fd0:	lw	s2,64(sp)
    4fd4:	mv	a0,s5
    4fd8:	add	s0,s0,a5
    4fdc:	bne	a7,a1,4e08 <.L22>
    4fe0:	mv	a2,a0
    4fe4:	mv	t6,t1
    4fe8:	lw	s1,28(sp)
    4fec:	lw	a5,32(sp)
    4ff0:	lw	s5,36(sp)
    4ff4:	lw	a3,44(sp)
    4ff8:	lw	t2,48(sp)
    4ffc:	lw	a0,40(sp)
    5000:	lw	t1,52(sp)
    5004:	lw	a7,0(s9)
    5008:	lui	a4,0xffb20
    500c:	lw	t4,516(a4) # ffb20204 <__fw_export_ldm_end+0x1f5d4>
    5010:	bne	t4,a7,500c <.L23>
    5014:	fence
    5018:	lw	a7,32(s11)
    501c:	lw	a4,520(s4)
    5020:	lw	t4,528(s4)
    5024:	add	a7,a0,a7
    5028:	mul	a4,a0,a4
    502c:	sw	a7,32(s11)
    5030:	add	a4,a4,t4
    5034:	lw	a7,516(s4)
    5038:	sw	a4,528(s4)
    503c:	bne	a4,a7,504c <.L24>
    5040:	lw	a7,512(s4)
    5044:	sub	a4,a4,a7
    5048:	sw	a4,528(s4)
    504c:	addi	t3,t3,1
    5050:	add	a2,a2,a5
    5054:	bne	a3,t3,4d98 <.L25>
    5058:	addi	t0,t0,1
    505c:	mv	t4,t1
    5060:	mv	a4,a6
    5064:	mv	t5,s1
    5068:	mv	a7,t2
    506c:	mv	t1,s5
    5070:	mv	a6,s2
    5074:	add	t6,t6,s5
    5078:	bne	t2,t0,4d74 <.L26>
    507c:	mv	a2,s2
    5080:	mv	a6,t4
    5084:	lw	s0,140(sp)
    5088:	mv	t4,a5
    508c:	lw	s2,132(sp)
    5090:	mv	a5,a4
    5094:	mv	a4,s1
    5098:	lw	s1,136(sp)
    509c:	addi	a5,a5,1
    50a0:	add	a4,a4,a6
    50a4:	bne	a2,a5,4d34 <.L13>
    50a8:	lw	s4,124(sp)
    50ac:	lw	s6,116(sp)
    50b0:	lw	s7,112(sp)
    50b4:	lw	s8,108(sp)
    50b8:	lw	s3,128(sp)
    50bc:	lw	s5,120(sp)
    50c0:	lw	s9,104(sp)
    50c4:	lw	s10,100(sp)
    50c8:	lw	s11,96(sp)
    50cc:	li	a0,0
    50d0:	addi	sp,sp,144
    50d4:	ret
