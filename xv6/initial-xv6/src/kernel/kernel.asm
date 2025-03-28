
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8d070713          	addi	a4,a4,-1840 # 80008920 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	13e78793          	addi	a5,a5,318 # 800061a0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdba6f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	51e080e7          	jalr	1310(ra) # 80002648 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	2ca080e7          	jalr	714(ra) # 80002492 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	008080e7          	jalr	8(ra) # 800021de <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	3e0080e7          	jalr	992(ra) # 800025f2 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	3ac080e7          	jalr	940(ra) # 8000269e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dfc080e7          	jalr	-516(ra) # 80002242 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	78078793          	addi	a5,a5,1920 # 80021bf8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07aa23          	sw	zero,1492(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	d3250513          	addi	a0,a0,-718 # 800082a0 <digits+0x260>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	36f72023          	sw	a5,864(a4) # 800088e0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	564dad83          	lw	s11,1380(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	50e50513          	addi	a0,a0,1294 # 80010b08 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3b050513          	addi	a0,a0,944 # 80010b08 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	39448493          	addi	s1,s1,916 # 80010b08 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	35450513          	addi	a0,a0,852 # 80010b28 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0e07a783          	lw	a5,224(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0b07b783          	ld	a5,176(a5) # 800088e8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0b073703          	ld	a4,176(a4) # 800088f0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2c6a0a13          	addi	s4,s4,710 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	07e48493          	addi	s1,s1,126 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	07e98993          	addi	s3,s3,126 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	9ae080e7          	jalr	-1618(ra) # 80002242 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	25850513          	addi	a0,a0,600 # 80010b28 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0007a783          	lw	a5,0(a5) # 800088e0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	00673703          	ld	a4,6(a4) # 800088f0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	ff67b783          	ld	a5,-10(a5) # 800088e8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	22a98993          	addi	s3,s3,554 # 80010b28 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fe248493          	addi	s1,s1,-30 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fe290913          	addi	s2,s2,-30 # 800088f0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	8c0080e7          	jalr	-1856(ra) # 800021de <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1f448493          	addi	s1,s1,500 # 80010b28 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fae7b423          	sd	a4,-88(a5) # 800088f0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	16e48493          	addi	s1,s1,366 # 80010b28 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	39478793          	addi	a5,a5,916 # 80022d90 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	14490913          	addi	s2,s2,324 # 80010b60 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0a650513          	addi	a0,a0,166 # 80010b60 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	2c250513          	addi	a0,a0,706 # 80022d90 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	07048493          	addi	s1,s1,112 # 80010b60 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	05850513          	addi	a0,a0,88 # 80010b60 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	02c50513          	addi	a0,a0,44 # 80010b60 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc271>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a7070713          	addi	a4,a4,-1424 # 800088f8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	b22080e7          	jalr	-1246(ra) # 800029e0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	31a080e7          	jalr	794(ra) # 800061e0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	01e080e7          	jalr	30(ra) # 80001eec <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	3ba50513          	addi	a0,a0,954 # 800082a0 <digits+0x260>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	39a50513          	addi	a0,a0,922 # 800082a0 <digits+0x260>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a82080e7          	jalr	-1406(ra) # 800029b8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	aa2080e7          	jalr	-1374(ra) # 800029e0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	284080e7          	jalr	644(ra) # 800061ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	292080e7          	jalr	658(ra) # 800061e0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	428080e7          	jalr	1064(ra) # 8000337e <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	ac8080e7          	jalr	-1336(ra) # 80003a26 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	a6e080e7          	jalr	-1426(ra) # 800049d4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	37a080e7          	jalr	890(ra) # 800062e8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d58080e7          	jalr	-680(ra) # 80001cce <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72a23          	sw	a5,-1676(a4) # 800088f8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9687b783          	ld	a5,-1688(a5) # 80008900 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc267>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6aa7b623          	sd	a0,1708(a5) # 80008900 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc270>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	76448493          	addi	s1,s1,1892 # 80010fb0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	14aa0a13          	addi	s4,s4,330 # 800179b0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1a848493          	addi	s1,s1,424
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	29850513          	addi	a0,a0,664 # 80010b80 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	29850513          	addi	a0,a0,664 # 80010b98 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6a048493          	addi	s1,s1,1696 # 80010fb0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	07e98993          	addi	s3,s3,126 # 800179b0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1a848493          	addi	s1,s1,424
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	21450513          	addi	a0,a0,532 # 80010bb0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1bc70713          	addi	a4,a4,444 # 80010b80 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e747a783          	lw	a5,-396(a5) # 80008870 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	ff2080e7          	jalr	-14(ra) # 800029f8 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407ad23          	sw	zero,-422(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	f86080e7          	jalr	-122(ra) # 800039a6 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	14a90913          	addi	s2,s2,330 # 80010b80 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e2c78793          	addi	a5,a5,-468 # 80008874 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3ee48493          	addi	s1,s1,1006 # 80010fb0 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	de690913          	addi	s2,s2,-538 # 800179b0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	1a848493          	addi	s1,s1,424
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a871                	j	80001c90 <allocproc+0xda>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  p->readcount = 0;
    80001c04:	1604aa23          	sw	zero,372(s1)
  p->timeinterval = 0;
    80001c08:	1804a223          	sw	zero,388(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	eda080e7          	jalr	-294(ra) # 80000ae6 <kalloc>
    80001c14:	892a                	mv	s2,a0
    80001c16:	eca8                	sd	a0,88(s1)
    80001c18:	c159                	beqz	a0,80001c9e <allocproc+0xe8>
  p->trapp = (struct trapframe *)kalloc();
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	ecc080e7          	jalr	-308(ra) # 80000ae6 <kalloc>
    80001c22:	16a4bc23          	sd	a0,376(s1)
  p->pagetable = proc_pagetable(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e48080e7          	jalr	-440(ra) # 80001a70 <proc_pagetable>
    80001c30:	892a                	mv	s2,a0
    80001c32:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c34:	c149                	beqz	a0,80001cb6 <allocproc+0x100>
  memset(&p->context, 0, sizeof(p->context));
    80001c36:	07000613          	li	a2,112
    80001c3a:	4581                	li	a1,0
    80001c3c:	06048513          	addi	a0,s1,96
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	092080e7          	jalr	146(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c48:	00000797          	auipc	a5,0x0
    80001c4c:	d9c78793          	addi	a5,a5,-612 # 800019e4 <forkret>
    80001c50:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c52:	60bc                	ld	a5,64(s1)
    80001c54:	6705                	lui	a4,0x1
    80001c56:	97ba                	add	a5,a5,a4
    80001c58:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c5a:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c5e:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c62:	00007797          	auipc	a5,0x7
    80001c66:	cb67a783          	lw	a5,-842(a5) # 80008918 <ticks>
    80001c6a:	16f4a623          	sw	a5,364(s1)
  if (p->done != -1)
    80001c6e:	1a04a703          	lw	a4,416(s1)
    80001c72:	57fd                	li	a5,-1
    80001c74:	00f70e63          	beq	a4,a5,80001c90 <allocproc+0xda>
    p->qnum = 0;
    80001c78:	1804aa23          	sw	zero,404(s1)
    p->runtime = 0;
    80001c7c:	1804ae23          	sw	zero,412(s1)
    p->timeslice = 1;
    80001c80:	4785                	li	a5,1
    80001c82:	18f4ac23          	sw	a5,408(s1)
    p->done = -1;
    80001c86:	57fd                	li	a5,-1
    80001c88:	1af4a023          	sw	a5,416(s1)
    p->waittime = 0;
    80001c8c:	1a04a223          	sw	zero,420(s1)
}
    80001c90:	8526                	mv	a0,s1
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6902                	ld	s2,0(sp)
    80001c9a:	6105                	addi	sp,sp,32
    80001c9c:	8082                	ret
    freeproc(p);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	ebe080e7          	jalr	-322(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001ca8:	8526                	mv	a0,s1
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	fe0080e7          	jalr	-32(ra) # 80000c8a <release>
    return 0;
    80001cb2:	84ca                	mv	s1,s2
    80001cb4:	bff1                	j	80001c90 <allocproc+0xda>
    freeproc(p);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	ea6080e7          	jalr	-346(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	fc8080e7          	jalr	-56(ra) # 80000c8a <release>
    return 0;
    80001cca:	84ca                	mv	s1,s2
    80001ccc:	b7d1                	j	80001c90 <allocproc+0xda>

0000000080001cce <userinit>:
{
    80001cce:	1101                	addi	sp,sp,-32
    80001cd0:	ec06                	sd	ra,24(sp)
    80001cd2:	e822                	sd	s0,16(sp)
    80001cd4:	e426                	sd	s1,8(sp)
    80001cd6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cd8:	00000097          	auipc	ra,0x0
    80001cdc:	ede080e7          	jalr	-290(ra) # 80001bb6 <allocproc>
    80001ce0:	84aa                	mv	s1,a0
  initproc = p;
    80001ce2:	00007797          	auipc	a5,0x7
    80001ce6:	c2a7b723          	sd	a0,-978(a5) # 80008910 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cea:	03400613          	li	a2,52
    80001cee:	00007597          	auipc	a1,0x7
    80001cf2:	b9258593          	addi	a1,a1,-1134 # 80008880 <initcode>
    80001cf6:	6928                	ld	a0,80(a0)
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	65e080e7          	jalr	1630(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001d00:	6785                	lui	a5,0x1
    80001d02:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d04:	6cb8                	ld	a4,88(s1)
    80001d06:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d0a:	6cb8                	ld	a4,88(s1)
    80001d0c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d0e:	4641                	li	a2,16
    80001d10:	00006597          	auipc	a1,0x6
    80001d14:	4f058593          	addi	a1,a1,1264 # 80008200 <digits+0x1c0>
    80001d18:	15848513          	addi	a0,s1,344
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	100080e7          	jalr	256(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d24:	00006517          	auipc	a0,0x6
    80001d28:	4ec50513          	addi	a0,a0,1260 # 80008210 <digits+0x1d0>
    80001d2c:	00002097          	auipc	ra,0x2
    80001d30:	6a4080e7          	jalr	1700(ra) # 800043d0 <namei>
    80001d34:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d38:	478d                	li	a5,3
    80001d3a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	f4c080e7          	jalr	-180(ra) # 80000c8a <release>
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6105                	addi	sp,sp,32
    80001d4e:	8082                	ret

0000000080001d50 <growproc>:
{
    80001d50:	1101                	addi	sp,sp,-32
    80001d52:	ec06                	sd	ra,24(sp)
    80001d54:	e822                	sd	s0,16(sp)
    80001d56:	e426                	sd	s1,8(sp)
    80001d58:	e04a                	sd	s2,0(sp)
    80001d5a:	1000                	addi	s0,sp,32
    80001d5c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	c4e080e7          	jalr	-946(ra) # 800019ac <myproc>
    80001d66:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d68:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d6a:	01204c63          	bgtz	s2,80001d82 <growproc+0x32>
  else if (n < 0)
    80001d6e:	02094663          	bltz	s2,80001d9a <growproc+0x4a>
  p->sz = sz;
    80001d72:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d74:	4501                	li	a0,0
}
    80001d76:	60e2                	ld	ra,24(sp)
    80001d78:	6442                	ld	s0,16(sp)
    80001d7a:	64a2                	ld	s1,8(sp)
    80001d7c:	6902                	ld	s2,0(sp)
    80001d7e:	6105                	addi	sp,sp,32
    80001d80:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d82:	4691                	li	a3,4
    80001d84:	00b90633          	add	a2,s2,a1
    80001d88:	6928                	ld	a0,80(a0)
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	686080e7          	jalr	1670(ra) # 80001410 <uvmalloc>
    80001d92:	85aa                	mv	a1,a0
    80001d94:	fd79                	bnez	a0,80001d72 <growproc+0x22>
      return -1;
    80001d96:	557d                	li	a0,-1
    80001d98:	bff9                	j	80001d76 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9a:	00b90633          	add	a2,s2,a1
    80001d9e:	6928                	ld	a0,80(a0)
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	628080e7          	jalr	1576(ra) # 800013c8 <uvmdealloc>
    80001da8:	85aa                	mv	a1,a0
    80001daa:	b7e1                	j	80001d72 <growproc+0x22>

0000000080001dac <fork>:
{
    80001dac:	7139                	addi	sp,sp,-64
    80001dae:	fc06                	sd	ra,56(sp)
    80001db0:	f822                	sd	s0,48(sp)
    80001db2:	f426                	sd	s1,40(sp)
    80001db4:	f04a                	sd	s2,32(sp)
    80001db6:	ec4e                	sd	s3,24(sp)
    80001db8:	e852                	sd	s4,16(sp)
    80001dba:	e456                	sd	s5,8(sp)
    80001dbc:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	bee080e7          	jalr	-1042(ra) # 800019ac <myproc>
    80001dc6:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dc8:	00000097          	auipc	ra,0x0
    80001dcc:	dee080e7          	jalr	-530(ra) # 80001bb6 <allocproc>
    80001dd0:	10050c63          	beqz	a0,80001ee8 <fork+0x13c>
    80001dd4:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dd6:	048ab603          	ld	a2,72(s5)
    80001dda:	692c                	ld	a1,80(a0)
    80001ddc:	050ab503          	ld	a0,80(s5)
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	788080e7          	jalr	1928(ra) # 80001568 <uvmcopy>
    80001de8:	04054863          	bltz	a0,80001e38 <fork+0x8c>
  np->sz = p->sz;
    80001dec:	048ab783          	ld	a5,72(s5)
    80001df0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001df4:	058ab683          	ld	a3,88(s5)
    80001df8:	87b6                	mv	a5,a3
    80001dfa:	058a3703          	ld	a4,88(s4)
    80001dfe:	12068693          	addi	a3,a3,288
    80001e02:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e06:	6788                	ld	a0,8(a5)
    80001e08:	6b8c                	ld	a1,16(a5)
    80001e0a:	6f90                	ld	a2,24(a5)
    80001e0c:	01073023          	sd	a6,0(a4)
    80001e10:	e708                	sd	a0,8(a4)
    80001e12:	eb0c                	sd	a1,16(a4)
    80001e14:	ef10                	sd	a2,24(a4)
    80001e16:	02078793          	addi	a5,a5,32
    80001e1a:	02070713          	addi	a4,a4,32
    80001e1e:	fed792e3          	bne	a5,a3,80001e02 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e22:	058a3783          	ld	a5,88(s4)
    80001e26:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e2a:	0d0a8493          	addi	s1,s5,208
    80001e2e:	0d0a0913          	addi	s2,s4,208
    80001e32:	150a8993          	addi	s3,s5,336
    80001e36:	a00d                	j	80001e58 <fork+0xac>
    freeproc(np);
    80001e38:	8552                	mv	a0,s4
    80001e3a:	00000097          	auipc	ra,0x0
    80001e3e:	d24080e7          	jalr	-732(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e42:	8552                	mv	a0,s4
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	e46080e7          	jalr	-442(ra) # 80000c8a <release>
    return -1;
    80001e4c:	597d                	li	s2,-1
    80001e4e:	a059                	j	80001ed4 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e50:	04a1                	addi	s1,s1,8
    80001e52:	0921                	addi	s2,s2,8
    80001e54:	01348b63          	beq	s1,s3,80001e6a <fork+0xbe>
    if (p->ofile[i])
    80001e58:	6088                	ld	a0,0(s1)
    80001e5a:	d97d                	beqz	a0,80001e50 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5c:	00003097          	auipc	ra,0x3
    80001e60:	c0a080e7          	jalr	-1014(ra) # 80004a66 <filedup>
    80001e64:	00a93023          	sd	a0,0(s2)
    80001e68:	b7e5                	j	80001e50 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e6a:	150ab503          	ld	a0,336(s5)
    80001e6e:	00002097          	auipc	ra,0x2
    80001e72:	d78080e7          	jalr	-648(ra) # 80003be6 <idup>
    80001e76:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7a:	4641                	li	a2,16
    80001e7c:	158a8593          	addi	a1,s5,344
    80001e80:	158a0513          	addi	a0,s4,344
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	f98080e7          	jalr	-104(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e8c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e90:	8552                	mv	a0,s4
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	df8080e7          	jalr	-520(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e9a:	0000f497          	auipc	s1,0xf
    80001e9e:	cfe48493          	addi	s1,s1,-770 # 80010b98 <wait_lock>
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	d32080e7          	jalr	-718(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001eac:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	dd8080e7          	jalr	-552(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001eba:	8552                	mv	a0,s4
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	d1a080e7          	jalr	-742(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ec4:	478d                	li	a5,3
    80001ec6:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eca:	8552                	mv	a0,s4
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	dbe080e7          	jalr	-578(ra) # 80000c8a <release>
}
    80001ed4:	854a                	mv	a0,s2
    80001ed6:	70e2                	ld	ra,56(sp)
    80001ed8:	7442                	ld	s0,48(sp)
    80001eda:	74a2                	ld	s1,40(sp)
    80001edc:	7902                	ld	s2,32(sp)
    80001ede:	69e2                	ld	s3,24(sp)
    80001ee0:	6a42                	ld	s4,16(sp)
    80001ee2:	6aa2                	ld	s5,8(sp)
    80001ee4:	6121                	addi	sp,sp,64
    80001ee6:	8082                	ret
    return -1;
    80001ee8:	597d                	li	s2,-1
    80001eea:	b7ed                	j	80001ed4 <fork+0x128>

0000000080001eec <scheduler>:
{
    80001eec:	7139                	addi	sp,sp,-64
    80001eee:	fc06                	sd	ra,56(sp)
    80001ef0:	f822                	sd	s0,48(sp)
    80001ef2:	f426                	sd	s1,40(sp)
    80001ef4:	f04a                	sd	s2,32(sp)
    80001ef6:	ec4e                	sd	s3,24(sp)
    80001ef8:	e852                	sd	s4,16(sp)
    80001efa:	e456                	sd	s5,8(sp)
    80001efc:	0080                	addi	s0,sp,64
    80001efe:	8792                	mv	a5,tp
  int id = r_tp();
    80001f00:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f02:	00779a13          	slli	s4,a5,0x7
    80001f06:	0000f717          	auipc	a4,0xf
    80001f0a:	c7a70713          	addi	a4,a4,-902 # 80010b80 <pid_lock>
    80001f0e:	9752                	add	a4,a4,s4
    80001f10:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &p->context);
    80001f14:	0000f717          	auipc	a4,0xf
    80001f18:	ca470713          	addi	a4,a4,-860 # 80010bb8 <cpus+0x8>
    80001f1c:	9a3a                	add	s4,s4,a4
for (p = proc; p < &proc[NPROC]; p++)
    80001f1e:	00016497          	auipc	s1,0x16
    80001f22:	a9248493          	addi	s1,s1,-1390 # 800179b0 <tickslock>
        if (p->waittime >= 30 && 1 )
    80001f26:	4975                	li	s2,29
      c->proc = p;
    80001f28:	079e                	slli	a5,a5,0x7
    80001f2a:	0000f997          	auipc	s3,0xf
    80001f2e:	c5698993          	addi	s3,s3,-938 # 80010b80 <pid_lock>
    80001f32:	99be                	add	s3,s3,a5
    80001f34:	aa85                	j	800020a4 <scheduler+0x1b8>
        else if (p->qnum == 1)
    80001f36:	00a68963          	beq	a3,a0,80001f48 <scheduler+0x5c>
        else if (p->qnum == 2)
    80001f3a:	03068663          	beq	a3,a6,80001f66 <scheduler+0x7a>
        else if (p->qnum == 3)
    80001f3e:	00e69763          	bne	a3,a4,80001f4c <scheduler+0x60>
          p->timeslice = 15;
    80001f42:	1867ac23          	sw	t1,408(a5)
    80001f46:	a019                	j	80001f4c <scheduler+0x60>
          p->timeslice = 3;
    80001f48:	18e7ac23          	sw	a4,408(a5)
for (p = proc; p < &proc[NPROC]; p++)
    80001f4c:	1a878793          	addi	a5,a5,424
    80001f50:	00978e63          	beq	a5,s1,80001f6c <scheduler+0x80>
      if (p->state == RUNNABLE)
    80001f54:	4f94                	lw	a3,24(a5)
    80001f56:	fee69be3          	bne	a3,a4,80001f4c <scheduler+0x60>
        if (p->qnum == 0)
    80001f5a:	1947a683          	lw	a3,404(a5)
    80001f5e:	fee1                	bnez	a3,80001f36 <scheduler+0x4a>
          p->timeslice = 1;
    80001f60:	18a7ac23          	sw	a0,408(a5)
    80001f64:	b7e5                	j	80001f4c <scheduler+0x60>
          p->timeslice = 9;
    80001f66:	1917ac23          	sw	a7,408(a5)
    80001f6a:	b7cd                	j	80001f4c <scheduler+0x60>
   for (p = proc; p < &proc[NPROC]; p++)
    80001f6c:	0000f797          	auipc	a5,0xf
    80001f70:	04478793          	addi	a5,a5,68 # 80010fb0 <proc>
    80001f74:	a005                	j	80001f94 <scheduler+0xa8>
        else if (p->qnum == 1)
    80001f76:	00a60963          	beq	a2,a0,80001f88 <scheduler+0x9c>
        else if (p->qnum == 2)
    80001f7a:	05060763          	beq	a2,a6,80001fc8 <scheduler+0xdc>
        else if (p->qnum == 3)
    80001f7e:	00e61763          	bne	a2,a4,80001f8c <scheduler+0xa0>
          p->timeslice = 15;
    80001f82:	1867ac23          	sw	t1,408(a5)
    80001f86:	a019                	j	80001f8c <scheduler+0xa0>
          p->timeslice = 3;
    80001f88:	18e7ac23          	sw	a4,408(a5)
   for (p = proc; p < &proc[NPROC]; p++)
    80001f8c:	1a878793          	addi	a5,a5,424
    80001f90:	02978f63          	beq	a5,s1,80001fce <scheduler+0xe2>
      if (p->state == RUNNABLE)
    80001f94:	4f94                	lw	a3,24(a5)
    80001f96:	fee69be3          	bne	a3,a4,80001f8c <scheduler+0xa0>
        if (p->runtime >= p->timeslice)
    80001f9a:	19c7a603          	lw	a2,412(a5)
    80001f9e:	1987a683          	lw	a3,408(a5)
    80001fa2:	fed645e3          	blt	a2,a3,80001f8c <scheduler+0xa0>
          if(p->qnum!=3){
    80001fa6:	1947a683          	lw	a3,404(a5)
    80001faa:	fce68ce3          	beq	a3,a4,80001f82 <scheduler+0x96>
          p->qnum++;
    80001fae:	2685                	addiw	a3,a3,1
    80001fb0:	0006861b          	sext.w	a2,a3
    80001fb4:	18d7aa23          	sw	a3,404(a5)
          p->runtime = 0;
    80001fb8:	1807ae23          	sw	zero,412(a5)
          p->waittime=0;
    80001fbc:	1a07a223          	sw	zero,420(a5)
            if (p->qnum == 0)
    80001fc0:	fa5d                	bnez	a2,80001f76 <scheduler+0x8a>
          p->timeslice = 1;
    80001fc2:	18a7ac23          	sw	a0,408(a5)
    80001fc6:	b7d9                	j	80001f8c <scheduler+0xa0>
          p->timeslice = 9;
    80001fc8:	1917ac23          	sw	a7,408(a5)
    80001fcc:	b7c1                	j	80001f8c <scheduler+0xa0>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fce:	0000f797          	auipc	a5,0xf
    80001fd2:	fe278793          	addi	a5,a5,-30 # 80010fb0 <proc>
    80001fd6:	a005                	j	80001ff6 <scheduler+0x10a>
        else if (p->qnum == 1)
    80001fd8:	00a60963          	beq	a2,a0,80001fea <scheduler+0xfe>
        else if (p->qnum == 2)
    80001fdc:	05060563          	beq	a2,a6,80002026 <scheduler+0x13a>
        else if (p->qnum == 3)
    80001fe0:	00e61763          	bne	a2,a4,80001fee <scheduler+0x102>
          p->timeslice = 15;
    80001fe4:	1867ac23          	sw	t1,408(a5)
    80001fe8:	a019                	j	80001fee <scheduler+0x102>
          p->timeslice = 3;
    80001fea:	18e7ac23          	sw	a4,408(a5)
    for (p = proc; p < &proc[NPROC]; p++)
    80001fee:	1a878793          	addi	a5,a5,424
    80001ff2:	02978d63          	beq	a5,s1,8000202c <scheduler+0x140>
      if (p->state == RUNNABLE)
    80001ff6:	4f94                	lw	a3,24(a5)
    80001ff8:	fee69be3          	bne	a3,a4,80001fee <scheduler+0x102>
        if (p->waittime >= 30 && 1 )
    80001ffc:	1a47a683          	lw	a3,420(a5)
    80002000:	fed957e3          	bge	s2,a3,80001fee <scheduler+0x102>
          if (p->qnum > 0)
    80002004:	1947a683          	lw	a3,404(a5)
    80002008:	fed053e3          	blez	a3,80001fee <scheduler+0x102>
            p->qnum--;
    8000200c:	36fd                	addiw	a3,a3,-1
    8000200e:	0006861b          	sext.w	a2,a3
    80002012:	18d7aa23          	sw	a3,404(a5)
            p->waittime = 0;
    80002016:	1a07a223          	sw	zero,420(a5)
            p->runtime = 0;
    8000201a:	1807ae23          	sw	zero,412(a5)
        if (p->qnum == 0)
    8000201e:	fe4d                	bnez	a2,80001fd8 <scheduler+0xec>
          p->timeslice = 1;
    80002020:	18a7ac23          	sw	a0,408(a5)
    80002024:	b7e9                	j	80001fee <scheduler+0x102>
          p->timeslice = 9;
    80002026:	1917ac23          	sw	a7,408(a5)
    8000202a:	b7d1                	j	80001fee <scheduler+0x102>
    8000202c:	0000f797          	auipc	a5,0xf
    80002030:	12c78793          	addi	a5,a5,300 # 80011158 <proc+0x1a8>
    int mini = 13;
    80002034:	8f76                	mv	t5,t4
    struct proc *temmp = 0;
    80002036:	8af2                	mv	s5,t3
    80002038:	a029                	j	80002042 <scheduler+0x156>
    for (p = proc; p < &proc[NPROC]; p++)
    8000203a:	0296f463          	bgeu	a3,s1,80002062 <scheduler+0x176>
    8000203e:	1a878793          	addi	a5,a5,424
    80002042:	e5878593          	addi	a1,a5,-424
      if (p->state == RUNNABLE)
    80002046:	86be                	mv	a3,a5
    80002048:	e707a603          	lw	a2,-400(a5)
    8000204c:	fee617e3          	bne	a2,a4,8000203a <scheduler+0x14e>
        int x = p->qnum;
    80002050:	fec7a603          	lw	a2,-20(a5)
        if (x < mini)
    80002054:	ffe653e3          	bge	a2,t5,8000203a <scheduler+0x14e>
    for (p = proc; p < &proc[NPROC]; p++)
    80002058:	0697f863          	bgeu	a5,s1,800020c8 <scheduler+0x1dc>
          mini = x;
    8000205c:	8f32                	mv	t5,a2
    for (p = proc; p < &proc[NPROC]; p++)
    8000205e:	8aae                	mv	s5,a1
    80002060:	bff9                	j	8000203e <scheduler+0x152>
    if (p != 0)
    80002062:	040a8863          	beqz	s5,800020b2 <scheduler+0x1c6>
      acquire(&p->lock);
    80002066:	8556                	mv	a0,s5
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	b6e080e7          	jalr	-1170(ra) # 80000bd6 <acquire>
      p->state = RUNNING;
    80002070:	4791                	li	a5,4
    80002072:	00faac23          	sw	a5,24(s5)
      p->runtime++;
    80002076:	19caa783          	lw	a5,412(s5)
    8000207a:	2785                	addiw	a5,a5,1
    8000207c:	18faae23          	sw	a5,412(s5)
      p->waittime=0;
    80002080:	1a0aa223          	sw	zero,420(s5)
      c->proc = p;
    80002084:	0359b823          	sd	s5,48(s3)
      swtch(&c->context, &p->context);
    80002088:	060a8593          	addi	a1,s5,96
    8000208c:	8552                	mv	a0,s4
    8000208e:	00001097          	auipc	ra,0x1
    80002092:	8c0080e7          	jalr	-1856(ra) # 8000294e <swtch>
      c->proc = 0;
    80002096:	0209b823          	sd	zero,48(s3)
      release(&p->lock);
    8000209a:	8556                	mv	a0,s5
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	bee080e7          	jalr	-1042(ra) # 80000c8a <release>
      if (p->state == RUNNABLE)
    800020a4:	470d                	li	a4,3
        else if (p->qnum == 1)
    800020a6:	4505                	li	a0,1
        else if (p->qnum == 2)
    800020a8:	4809                	li	a6,2
          p->timeslice = 15;
    800020aa:	433d                	li	t1,15
          p->timeslice = 9;
    800020ac:	48a5                	li	a7,9
    int mini = 13;
    800020ae:	4eb5                	li	t4,13
    struct proc *temmp = 0;
    800020b0:	4e01                	li	t3,0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020b6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ba:	10079073          	csrw	sstatus,a5
for (p = proc; p < &proc[NPROC]; p++)
    800020be:	0000f797          	auipc	a5,0xf
    800020c2:	ef278793          	addi	a5,a5,-270 # 80010fb0 <proc>
    800020c6:	b579                	j	80001f54 <scheduler+0x68>
    for (p = proc; p < &proc[NPROC]; p++)
    800020c8:	8aae                	mv	s5,a1
    800020ca:	bf71                	j	80002066 <scheduler+0x17a>

00000000800020cc <sched>:
{
    800020cc:	7179                	addi	sp,sp,-48
    800020ce:	f406                	sd	ra,40(sp)
    800020d0:	f022                	sd	s0,32(sp)
    800020d2:	ec26                	sd	s1,24(sp)
    800020d4:	e84a                	sd	s2,16(sp)
    800020d6:	e44e                	sd	s3,8(sp)
    800020d8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020da:	00000097          	auipc	ra,0x0
    800020de:	8d2080e7          	jalr	-1838(ra) # 800019ac <myproc>
    800020e2:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	a78080e7          	jalr	-1416(ra) # 80000b5c <holding>
    800020ec:	c93d                	beqz	a0,80002162 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ee:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800020f0:	2781                	sext.w	a5,a5
    800020f2:	079e                	slli	a5,a5,0x7
    800020f4:	0000f717          	auipc	a4,0xf
    800020f8:	a8c70713          	addi	a4,a4,-1396 # 80010b80 <pid_lock>
    800020fc:	97ba                	add	a5,a5,a4
    800020fe:	0a87a703          	lw	a4,168(a5)
    80002102:	4785                	li	a5,1
    80002104:	06f71763          	bne	a4,a5,80002172 <sched+0xa6>
  if (p->state == RUNNING)
    80002108:	4c98                	lw	a4,24(s1)
    8000210a:	4791                	li	a5,4
    8000210c:	06f70b63          	beq	a4,a5,80002182 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002110:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002114:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002116:	efb5                	bnez	a5,80002192 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002118:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000211a:	0000f917          	auipc	s2,0xf
    8000211e:	a6690913          	addi	s2,s2,-1434 # 80010b80 <pid_lock>
    80002122:	2781                	sext.w	a5,a5
    80002124:	079e                	slli	a5,a5,0x7
    80002126:	97ca                	add	a5,a5,s2
    80002128:	0ac7a983          	lw	s3,172(a5)
    8000212c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000212e:	2781                	sext.w	a5,a5
    80002130:	079e                	slli	a5,a5,0x7
    80002132:	0000f597          	auipc	a1,0xf
    80002136:	a8658593          	addi	a1,a1,-1402 # 80010bb8 <cpus+0x8>
    8000213a:	95be                	add	a1,a1,a5
    8000213c:	06048513          	addi	a0,s1,96
    80002140:	00001097          	auipc	ra,0x1
    80002144:	80e080e7          	jalr	-2034(ra) # 8000294e <swtch>
    80002148:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000214a:	2781                	sext.w	a5,a5
    8000214c:	079e                	slli	a5,a5,0x7
    8000214e:	993e                	add	s2,s2,a5
    80002150:	0b392623          	sw	s3,172(s2)
}
    80002154:	70a2                	ld	ra,40(sp)
    80002156:	7402                	ld	s0,32(sp)
    80002158:	64e2                	ld	s1,24(sp)
    8000215a:	6942                	ld	s2,16(sp)
    8000215c:	69a2                	ld	s3,8(sp)
    8000215e:	6145                	addi	sp,sp,48
    80002160:	8082                	ret
    panic("sched p->lock");
    80002162:	00006517          	auipc	a0,0x6
    80002166:	0b650513          	addi	a0,a0,182 # 80008218 <digits+0x1d8>
    8000216a:	ffffe097          	auipc	ra,0xffffe
    8000216e:	3d6080e7          	jalr	982(ra) # 80000540 <panic>
    panic("sched locks");
    80002172:	00006517          	auipc	a0,0x6
    80002176:	0b650513          	addi	a0,a0,182 # 80008228 <digits+0x1e8>
    8000217a:	ffffe097          	auipc	ra,0xffffe
    8000217e:	3c6080e7          	jalr	966(ra) # 80000540 <panic>
    panic("sched running");
    80002182:	00006517          	auipc	a0,0x6
    80002186:	0b650513          	addi	a0,a0,182 # 80008238 <digits+0x1f8>
    8000218a:	ffffe097          	auipc	ra,0xffffe
    8000218e:	3b6080e7          	jalr	950(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002192:	00006517          	auipc	a0,0x6
    80002196:	0b650513          	addi	a0,a0,182 # 80008248 <digits+0x208>
    8000219a:	ffffe097          	auipc	ra,0xffffe
    8000219e:	3a6080e7          	jalr	934(ra) # 80000540 <panic>

00000000800021a2 <yield>:
{
    800021a2:	1101                	addi	sp,sp,-32
    800021a4:	ec06                	sd	ra,24(sp)
    800021a6:	e822                	sd	s0,16(sp)
    800021a8:	e426                	sd	s1,8(sp)
    800021aa:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	800080e7          	jalr	-2048(ra) # 800019ac <myproc>
    800021b4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	a20080e7          	jalr	-1504(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800021be:	478d                	li	a5,3
    800021c0:	cc9c                	sw	a5,24(s1)
  sched();
    800021c2:	00000097          	auipc	ra,0x0
    800021c6:	f0a080e7          	jalr	-246(ra) # 800020cc <sched>
  release(&p->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	abe080e7          	jalr	-1346(ra) # 80000c8a <release>
}
    800021d4:	60e2                	ld	ra,24(sp)
    800021d6:	6442                	ld	s0,16(sp)
    800021d8:	64a2                	ld	s1,8(sp)
    800021da:	6105                	addi	sp,sp,32
    800021dc:	8082                	ret

00000000800021de <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800021de:	7179                	addi	sp,sp,-48
    800021e0:	f406                	sd	ra,40(sp)
    800021e2:	f022                	sd	s0,32(sp)
    800021e4:	ec26                	sd	s1,24(sp)
    800021e6:	e84a                	sd	s2,16(sp)
    800021e8:	e44e                	sd	s3,8(sp)
    800021ea:	1800                	addi	s0,sp,48
    800021ec:	89aa                	mv	s3,a0
    800021ee:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	7bc080e7          	jalr	1980(ra) # 800019ac <myproc>
    800021f8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	9dc080e7          	jalr	-1572(ra) # 80000bd6 <acquire>
  release(lk);
    80002202:	854a                	mv	a0,s2
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	a86080e7          	jalr	-1402(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000220c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002210:	4789                	li	a5,2
    80002212:	cc9c                	sw	a5,24(s1)

  sched();
    80002214:	00000097          	auipc	ra,0x0
    80002218:	eb8080e7          	jalr	-328(ra) # 800020cc <sched>

  // Tidy up.
  p->chan = 0;
    8000221c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a68080e7          	jalr	-1432(ra) # 80000c8a <release>
  acquire(lk);
    8000222a:	854a                	mv	a0,s2
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	9aa080e7          	jalr	-1622(ra) # 80000bd6 <acquire>
}
    80002234:	70a2                	ld	ra,40(sp)
    80002236:	7402                	ld	s0,32(sp)
    80002238:	64e2                	ld	s1,24(sp)
    8000223a:	6942                	ld	s2,16(sp)
    8000223c:	69a2                	ld	s3,8(sp)
    8000223e:	6145                	addi	sp,sp,48
    80002240:	8082                	ret

0000000080002242 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002242:	7139                	addi	sp,sp,-64
    80002244:	fc06                	sd	ra,56(sp)
    80002246:	f822                	sd	s0,48(sp)
    80002248:	f426                	sd	s1,40(sp)
    8000224a:	f04a                	sd	s2,32(sp)
    8000224c:	ec4e                	sd	s3,24(sp)
    8000224e:	e852                	sd	s4,16(sp)
    80002250:	e456                	sd	s5,8(sp)
    80002252:	0080                	addi	s0,sp,64
    80002254:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002256:	0000f497          	auipc	s1,0xf
    8000225a:	d5a48493          	addi	s1,s1,-678 # 80010fb0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000225e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002260:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002262:	00015917          	auipc	s2,0x15
    80002266:	74e90913          	addi	s2,s2,1870 # 800179b0 <tickslock>
    8000226a:	a811                	j	8000227e <wakeup+0x3c>
      }
      release(&p->lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	a1c080e7          	jalr	-1508(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002276:	1a848493          	addi	s1,s1,424
    8000227a:	03248663          	beq	s1,s2,800022a6 <wakeup+0x64>
    if (p != myproc())
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	72e080e7          	jalr	1838(ra) # 800019ac <myproc>
    80002286:	fea488e3          	beq	s1,a0,80002276 <wakeup+0x34>
      acquire(&p->lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	94a080e7          	jalr	-1718(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002294:	4c9c                	lw	a5,24(s1)
    80002296:	fd379be3          	bne	a5,s3,8000226c <wakeup+0x2a>
    8000229a:	709c                	ld	a5,32(s1)
    8000229c:	fd4798e3          	bne	a5,s4,8000226c <wakeup+0x2a>
        p->state = RUNNABLE;
    800022a0:	0154ac23          	sw	s5,24(s1)
    800022a4:	b7e1                	j	8000226c <wakeup+0x2a>
    }
  }
}
    800022a6:	70e2                	ld	ra,56(sp)
    800022a8:	7442                	ld	s0,48(sp)
    800022aa:	74a2                	ld	s1,40(sp)
    800022ac:	7902                	ld	s2,32(sp)
    800022ae:	69e2                	ld	s3,24(sp)
    800022b0:	6a42                	ld	s4,16(sp)
    800022b2:	6aa2                	ld	s5,8(sp)
    800022b4:	6121                	addi	sp,sp,64
    800022b6:	8082                	ret

00000000800022b8 <reparent>:
{
    800022b8:	7179                	addi	sp,sp,-48
    800022ba:	f406                	sd	ra,40(sp)
    800022bc:	f022                	sd	s0,32(sp)
    800022be:	ec26                	sd	s1,24(sp)
    800022c0:	e84a                	sd	s2,16(sp)
    800022c2:	e44e                	sd	s3,8(sp)
    800022c4:	e052                	sd	s4,0(sp)
    800022c6:	1800                	addi	s0,sp,48
    800022c8:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022ca:	0000f497          	auipc	s1,0xf
    800022ce:	ce648493          	addi	s1,s1,-794 # 80010fb0 <proc>
      pp->parent = initproc;
    800022d2:	00006a17          	auipc	s4,0x6
    800022d6:	63ea0a13          	addi	s4,s4,1598 # 80008910 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022da:	00015997          	auipc	s3,0x15
    800022de:	6d698993          	addi	s3,s3,1750 # 800179b0 <tickslock>
    800022e2:	a029                	j	800022ec <reparent+0x34>
    800022e4:	1a848493          	addi	s1,s1,424
    800022e8:	01348d63          	beq	s1,s3,80002302 <reparent+0x4a>
    if (pp->parent == p)
    800022ec:	7c9c                	ld	a5,56(s1)
    800022ee:	ff279be3          	bne	a5,s2,800022e4 <reparent+0x2c>
      pp->parent = initproc;
    800022f2:	000a3503          	ld	a0,0(s4)
    800022f6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022f8:	00000097          	auipc	ra,0x0
    800022fc:	f4a080e7          	jalr	-182(ra) # 80002242 <wakeup>
    80002300:	b7d5                	j	800022e4 <reparent+0x2c>
}
    80002302:	70a2                	ld	ra,40(sp)
    80002304:	7402                	ld	s0,32(sp)
    80002306:	64e2                	ld	s1,24(sp)
    80002308:	6942                	ld	s2,16(sp)
    8000230a:	69a2                	ld	s3,8(sp)
    8000230c:	6a02                	ld	s4,0(sp)
    8000230e:	6145                	addi	sp,sp,48
    80002310:	8082                	ret

0000000080002312 <exit>:
{
    80002312:	7179                	addi	sp,sp,-48
    80002314:	f406                	sd	ra,40(sp)
    80002316:	f022                	sd	s0,32(sp)
    80002318:	ec26                	sd	s1,24(sp)
    8000231a:	e84a                	sd	s2,16(sp)
    8000231c:	e44e                	sd	s3,8(sp)
    8000231e:	e052                	sd	s4,0(sp)
    80002320:	1800                	addi	s0,sp,48
    80002322:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	688080e7          	jalr	1672(ra) # 800019ac <myproc>
    8000232c:	89aa                	mv	s3,a0
  if (p == initproc)
    8000232e:	00006797          	auipc	a5,0x6
    80002332:	5e27b783          	ld	a5,1506(a5) # 80008910 <initproc>
    80002336:	0d050493          	addi	s1,a0,208
    8000233a:	15050913          	addi	s2,a0,336
    8000233e:	02a79363          	bne	a5,a0,80002364 <exit+0x52>
    panic("init exiting");
    80002342:	00006517          	auipc	a0,0x6
    80002346:	f1e50513          	addi	a0,a0,-226 # 80008260 <digits+0x220>
    8000234a:	ffffe097          	auipc	ra,0xffffe
    8000234e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
      fileclose(f);
    80002352:	00002097          	auipc	ra,0x2
    80002356:	766080e7          	jalr	1894(ra) # 80004ab8 <fileclose>
      p->ofile[fd] = 0;
    8000235a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000235e:	04a1                	addi	s1,s1,8
    80002360:	01248563          	beq	s1,s2,8000236a <exit+0x58>
    if (p->ofile[fd])
    80002364:	6088                	ld	a0,0(s1)
    80002366:	f575                	bnez	a0,80002352 <exit+0x40>
    80002368:	bfdd                	j	8000235e <exit+0x4c>
  begin_op();
    8000236a:	00002097          	auipc	ra,0x2
    8000236e:	286080e7          	jalr	646(ra) # 800045f0 <begin_op>
  iput(p->cwd);
    80002372:	1509b503          	ld	a0,336(s3)
    80002376:	00002097          	auipc	ra,0x2
    8000237a:	a68080e7          	jalr	-1432(ra) # 80003dde <iput>
  end_op();
    8000237e:	00002097          	auipc	ra,0x2
    80002382:	2f0080e7          	jalr	752(ra) # 8000466e <end_op>
  p->cwd = 0;
    80002386:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000238a:	0000f497          	auipc	s1,0xf
    8000238e:	80e48493          	addi	s1,s1,-2034 # 80010b98 <wait_lock>
    80002392:	8526                	mv	a0,s1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	842080e7          	jalr	-1982(ra) # 80000bd6 <acquire>
  reparent(p);
    8000239c:	854e                	mv	a0,s3
    8000239e:	00000097          	auipc	ra,0x0
    800023a2:	f1a080e7          	jalr	-230(ra) # 800022b8 <reparent>
  wakeup(p->parent);
    800023a6:	0389b503          	ld	a0,56(s3)
    800023aa:	00000097          	auipc	ra,0x0
    800023ae:	e98080e7          	jalr	-360(ra) # 80002242 <wakeup>
  acquire(&p->lock);
    800023b2:	854e                	mv	a0,s3
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	822080e7          	jalr	-2014(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800023bc:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023c0:	4795                	li	a5,5
    800023c2:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800023c6:	00006797          	auipc	a5,0x6
    800023ca:	5527a783          	lw	a5,1362(a5) # 80008918 <ticks>
    800023ce:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8b6080e7          	jalr	-1866(ra) # 80000c8a <release>
  sched();
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	cf0080e7          	jalr	-784(ra) # 800020cc <sched>
  panic("zombie exit");
    800023e4:	00006517          	auipc	a0,0x6
    800023e8:	e8c50513          	addi	a0,a0,-372 # 80008270 <digits+0x230>
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	154080e7          	jalr	340(ra) # 80000540 <panic>

00000000800023f4 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023f4:	7179                	addi	sp,sp,-48
    800023f6:	f406                	sd	ra,40(sp)
    800023f8:	f022                	sd	s0,32(sp)
    800023fa:	ec26                	sd	s1,24(sp)
    800023fc:	e84a                	sd	s2,16(sp)
    800023fe:	e44e                	sd	s3,8(sp)
    80002400:	1800                	addi	s0,sp,48
    80002402:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002404:	0000f497          	auipc	s1,0xf
    80002408:	bac48493          	addi	s1,s1,-1108 # 80010fb0 <proc>
    8000240c:	00015997          	auipc	s3,0x15
    80002410:	5a498993          	addi	s3,s3,1444 # 800179b0 <tickslock>
  {
    acquire(&p->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	ffffe097          	auipc	ra,0xffffe
    8000241a:	7c0080e7          	jalr	1984(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    8000241e:	589c                	lw	a5,48(s1)
    80002420:	01278d63          	beq	a5,s2,8000243a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	864080e7          	jalr	-1948(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000242e:	1a848493          	addi	s1,s1,424
    80002432:	ff3491e3          	bne	s1,s3,80002414 <kill+0x20>
  }
  return -1;
    80002436:	557d                	li	a0,-1
    80002438:	a829                	j	80002452 <kill+0x5e>
      p->killed = 1;
    8000243a:	4785                	li	a5,1
    8000243c:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000243e:	4c98                	lw	a4,24(s1)
    80002440:	4789                	li	a5,2
    80002442:	00f70f63          	beq	a4,a5,80002460 <kill+0x6c>
      release(&p->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	842080e7          	jalr	-1982(ra) # 80000c8a <release>
      return 0;
    80002450:	4501                	li	a0,0
}
    80002452:	70a2                	ld	ra,40(sp)
    80002454:	7402                	ld	s0,32(sp)
    80002456:	64e2                	ld	s1,24(sp)
    80002458:	6942                	ld	s2,16(sp)
    8000245a:	69a2                	ld	s3,8(sp)
    8000245c:	6145                	addi	sp,sp,48
    8000245e:	8082                	ret
        p->state = RUNNABLE;
    80002460:	478d                	li	a5,3
    80002462:	cc9c                	sw	a5,24(s1)
    80002464:	b7cd                	j	80002446 <kill+0x52>

0000000080002466 <setkilled>:

void setkilled(struct proc *p)
{
    80002466:	1101                	addi	sp,sp,-32
    80002468:	ec06                	sd	ra,24(sp)
    8000246a:	e822                	sd	s0,16(sp)
    8000246c:	e426                	sd	s1,8(sp)
    8000246e:	1000                	addi	s0,sp,32
    80002470:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002472:	ffffe097          	auipc	ra,0xffffe
    80002476:	764080e7          	jalr	1892(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000247a:	4785                	li	a5,1
    8000247c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	80a080e7          	jalr	-2038(ra) # 80000c8a <release>
}
    80002488:	60e2                	ld	ra,24(sp)
    8000248a:	6442                	ld	s0,16(sp)
    8000248c:	64a2                	ld	s1,8(sp)
    8000248e:	6105                	addi	sp,sp,32
    80002490:	8082                	ret

0000000080002492 <killed>:

int killed(struct proc *p)
{
    80002492:	1101                	addi	sp,sp,-32
    80002494:	ec06                	sd	ra,24(sp)
    80002496:	e822                	sd	s0,16(sp)
    80002498:	e426                	sd	s1,8(sp)
    8000249a:	e04a                	sd	s2,0(sp)
    8000249c:	1000                	addi	s0,sp,32
    8000249e:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	736080e7          	jalr	1846(ra) # 80000bd6 <acquire>
  k = p->killed;
    800024a8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	7dc080e7          	jalr	2012(ra) # 80000c8a <release>
  return k;
}
    800024b6:	854a                	mv	a0,s2
    800024b8:	60e2                	ld	ra,24(sp)
    800024ba:	6442                	ld	s0,16(sp)
    800024bc:	64a2                	ld	s1,8(sp)
    800024be:	6902                	ld	s2,0(sp)
    800024c0:	6105                	addi	sp,sp,32
    800024c2:	8082                	ret

00000000800024c4 <wait>:
{
    800024c4:	715d                	addi	sp,sp,-80
    800024c6:	e486                	sd	ra,72(sp)
    800024c8:	e0a2                	sd	s0,64(sp)
    800024ca:	fc26                	sd	s1,56(sp)
    800024cc:	f84a                	sd	s2,48(sp)
    800024ce:	f44e                	sd	s3,40(sp)
    800024d0:	f052                	sd	s4,32(sp)
    800024d2:	ec56                	sd	s5,24(sp)
    800024d4:	e85a                	sd	s6,16(sp)
    800024d6:	e45e                	sd	s7,8(sp)
    800024d8:	e062                	sd	s8,0(sp)
    800024da:	0880                	addi	s0,sp,80
    800024dc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	4ce080e7          	jalr	1230(ra) # 800019ac <myproc>
    800024e6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024e8:	0000e517          	auipc	a0,0xe
    800024ec:	6b050513          	addi	a0,a0,1712 # 80010b98 <wait_lock>
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	6e6080e7          	jalr	1766(ra) # 80000bd6 <acquire>
    havekids = 0;
    800024f8:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800024fa:	4a15                	li	s4,5
        havekids = 1;
    800024fc:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024fe:	00015997          	auipc	s3,0x15
    80002502:	4b298993          	addi	s3,s3,1202 # 800179b0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002506:	0000ec17          	auipc	s8,0xe
    8000250a:	692c0c13          	addi	s8,s8,1682 # 80010b98 <wait_lock>
    havekids = 0;
    8000250e:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002510:	0000f497          	auipc	s1,0xf
    80002514:	aa048493          	addi	s1,s1,-1376 # 80010fb0 <proc>
    80002518:	a0bd                	j	80002586 <wait+0xc2>
          pid = pp->pid;
    8000251a:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000251e:	000b0e63          	beqz	s6,8000253a <wait+0x76>
    80002522:	4691                	li	a3,4
    80002524:	02c48613          	addi	a2,s1,44
    80002528:	85da                	mv	a1,s6
    8000252a:	05093503          	ld	a0,80(s2)
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	13e080e7          	jalr	318(ra) # 8000166c <copyout>
    80002536:	02054563          	bltz	a0,80002560 <wait+0x9c>
          freeproc(pp);
    8000253a:	8526                	mv	a0,s1
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	622080e7          	jalr	1570(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002544:	8526                	mv	a0,s1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	744080e7          	jalr	1860(ra) # 80000c8a <release>
          release(&wait_lock);
    8000254e:	0000e517          	auipc	a0,0xe
    80002552:	64a50513          	addi	a0,a0,1610 # 80010b98 <wait_lock>
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	734080e7          	jalr	1844(ra) # 80000c8a <release>
          return pid;
    8000255e:	a0b5                	j	800025ca <wait+0x106>
            release(&pp->lock);
    80002560:	8526                	mv	a0,s1
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	728080e7          	jalr	1832(ra) # 80000c8a <release>
            release(&wait_lock);
    8000256a:	0000e517          	auipc	a0,0xe
    8000256e:	62e50513          	addi	a0,a0,1582 # 80010b98 <wait_lock>
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	718080e7          	jalr	1816(ra) # 80000c8a <release>
            return -1;
    8000257a:	59fd                	li	s3,-1
    8000257c:	a0b9                	j	800025ca <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000257e:	1a848493          	addi	s1,s1,424
    80002582:	03348463          	beq	s1,s3,800025aa <wait+0xe6>
      if (pp->parent == p)
    80002586:	7c9c                	ld	a5,56(s1)
    80002588:	ff279be3          	bne	a5,s2,8000257e <wait+0xba>
        acquire(&pp->lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	648080e7          	jalr	1608(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002596:	4c9c                	lw	a5,24(s1)
    80002598:	f94781e3          	beq	a5,s4,8000251a <wait+0x56>
        release(&pp->lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	6ec080e7          	jalr	1772(ra) # 80000c8a <release>
        havekids = 1;
    800025a6:	8756                	mv	a4,s5
    800025a8:	bfd9                	j	8000257e <wait+0xba>
    if (!havekids || killed(p))
    800025aa:	c719                	beqz	a4,800025b8 <wait+0xf4>
    800025ac:	854a                	mv	a0,s2
    800025ae:	00000097          	auipc	ra,0x0
    800025b2:	ee4080e7          	jalr	-284(ra) # 80002492 <killed>
    800025b6:	c51d                	beqz	a0,800025e4 <wait+0x120>
      release(&wait_lock);
    800025b8:	0000e517          	auipc	a0,0xe
    800025bc:	5e050513          	addi	a0,a0,1504 # 80010b98 <wait_lock>
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	6ca080e7          	jalr	1738(ra) # 80000c8a <release>
      return -1;
    800025c8:	59fd                	li	s3,-1
}
    800025ca:	854e                	mv	a0,s3
    800025cc:	60a6                	ld	ra,72(sp)
    800025ce:	6406                	ld	s0,64(sp)
    800025d0:	74e2                	ld	s1,56(sp)
    800025d2:	7942                	ld	s2,48(sp)
    800025d4:	79a2                	ld	s3,40(sp)
    800025d6:	7a02                	ld	s4,32(sp)
    800025d8:	6ae2                	ld	s5,24(sp)
    800025da:	6b42                	ld	s6,16(sp)
    800025dc:	6ba2                	ld	s7,8(sp)
    800025de:	6c02                	ld	s8,0(sp)
    800025e0:	6161                	addi	sp,sp,80
    800025e2:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025e4:	85e2                	mv	a1,s8
    800025e6:	854a                	mv	a0,s2
    800025e8:	00000097          	auipc	ra,0x0
    800025ec:	bf6080e7          	jalr	-1034(ra) # 800021de <sleep>
    havekids = 0;
    800025f0:	bf39                	j	8000250e <wait+0x4a>

00000000800025f2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025f2:	7179                	addi	sp,sp,-48
    800025f4:	f406                	sd	ra,40(sp)
    800025f6:	f022                	sd	s0,32(sp)
    800025f8:	ec26                	sd	s1,24(sp)
    800025fa:	e84a                	sd	s2,16(sp)
    800025fc:	e44e                	sd	s3,8(sp)
    800025fe:	e052                	sd	s4,0(sp)
    80002600:	1800                	addi	s0,sp,48
    80002602:	84aa                	mv	s1,a0
    80002604:	892e                	mv	s2,a1
    80002606:	89b2                	mv	s3,a2
    80002608:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	3a2080e7          	jalr	930(ra) # 800019ac <myproc>
  if (user_dst)
    80002612:	c08d                	beqz	s1,80002634 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002614:	86d2                	mv	a3,s4
    80002616:	864e                	mv	a2,s3
    80002618:	85ca                	mv	a1,s2
    8000261a:	6928                	ld	a0,80(a0)
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	050080e7          	jalr	80(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002624:	70a2                	ld	ra,40(sp)
    80002626:	7402                	ld	s0,32(sp)
    80002628:	64e2                	ld	s1,24(sp)
    8000262a:	6942                	ld	s2,16(sp)
    8000262c:	69a2                	ld	s3,8(sp)
    8000262e:	6a02                	ld	s4,0(sp)
    80002630:	6145                	addi	sp,sp,48
    80002632:	8082                	ret
    memmove((char *)dst, src, len);
    80002634:	000a061b          	sext.w	a2,s4
    80002638:	85ce                	mv	a1,s3
    8000263a:	854a                	mv	a0,s2
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	6f2080e7          	jalr	1778(ra) # 80000d2e <memmove>
    return 0;
    80002644:	8526                	mv	a0,s1
    80002646:	bff9                	j	80002624 <either_copyout+0x32>

0000000080002648 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002648:	7179                	addi	sp,sp,-48
    8000264a:	f406                	sd	ra,40(sp)
    8000264c:	f022                	sd	s0,32(sp)
    8000264e:	ec26                	sd	s1,24(sp)
    80002650:	e84a                	sd	s2,16(sp)
    80002652:	e44e                	sd	s3,8(sp)
    80002654:	e052                	sd	s4,0(sp)
    80002656:	1800                	addi	s0,sp,48
    80002658:	892a                	mv	s2,a0
    8000265a:	84ae                	mv	s1,a1
    8000265c:	89b2                	mv	s3,a2
    8000265e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	34c080e7          	jalr	844(ra) # 800019ac <myproc>
  if (user_src)
    80002668:	c08d                	beqz	s1,8000268a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000266a:	86d2                	mv	a3,s4
    8000266c:	864e                	mv	a2,s3
    8000266e:	85ca                	mv	a1,s2
    80002670:	6928                	ld	a0,80(a0)
    80002672:	fffff097          	auipc	ra,0xfffff
    80002676:	086080e7          	jalr	134(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000267a:	70a2                	ld	ra,40(sp)
    8000267c:	7402                	ld	s0,32(sp)
    8000267e:	64e2                	ld	s1,24(sp)
    80002680:	6942                	ld	s2,16(sp)
    80002682:	69a2                	ld	s3,8(sp)
    80002684:	6a02                	ld	s4,0(sp)
    80002686:	6145                	addi	sp,sp,48
    80002688:	8082                	ret
    memmove(dst, (char *)src, len);
    8000268a:	000a061b          	sext.w	a2,s4
    8000268e:	85ce                	mv	a1,s3
    80002690:	854a                	mv	a0,s2
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	69c080e7          	jalr	1692(ra) # 80000d2e <memmove>
    return 0;
    8000269a:	8526                	mv	a0,s1
    8000269c:	bff9                	j	8000267a <either_copyin+0x32>

000000008000269e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000269e:	715d                	addi	sp,sp,-80
    800026a0:	e486                	sd	ra,72(sp)
    800026a2:	e0a2                	sd	s0,64(sp)
    800026a4:	fc26                	sd	s1,56(sp)
    800026a6:	f84a                	sd	s2,48(sp)
    800026a8:	f44e                	sd	s3,40(sp)
    800026aa:	f052                	sd	s4,32(sp)
    800026ac:	ec56                	sd	s5,24(sp)
    800026ae:	e85a                	sd	s6,16(sp)
    800026b0:	e45e                	sd	s7,8(sp)
    800026b2:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800026b4:	00006517          	auipc	a0,0x6
    800026b8:	bec50513          	addi	a0,a0,-1044 # 800082a0 <digits+0x260>
    800026bc:	ffffe097          	auipc	ra,0xffffe
    800026c0:	ece080e7          	jalr	-306(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026c4:	0000f497          	auipc	s1,0xf
    800026c8:	a4448493          	addi	s1,s1,-1468 # 80011108 <proc+0x158>
    800026cc:	00015917          	auipc	s2,0x15
    800026d0:	43c90913          	addi	s2,s2,1084 # 80017b08 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026d4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026d6:	00006997          	auipc	s3,0x6
    800026da:	baa98993          	addi	s3,s3,-1110 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800026de:	00006a97          	auipc	s5,0x6
    800026e2:	baaa8a93          	addi	s5,s5,-1110 # 80008288 <digits+0x248>
    printf("\n");
    800026e6:	00006a17          	auipc	s4,0x6
    800026ea:	bbaa0a13          	addi	s4,s4,-1094 # 800082a0 <digits+0x260>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026ee:	00006b97          	auipc	s7,0x6
    800026f2:	beab8b93          	addi	s7,s7,-1046 # 800082d8 <states.0>
    800026f6:	a00d                	j	80002718 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026f8:	ed86a583          	lw	a1,-296(a3)
    800026fc:	8556                	mv	a0,s5
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	e8c080e7          	jalr	-372(ra) # 8000058a <printf>
    printf("\n");
    80002706:	8552                	mv	a0,s4
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	e82080e7          	jalr	-382(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002710:	1a848493          	addi	s1,s1,424
    80002714:	03248263          	beq	s1,s2,80002738 <procdump+0x9a>
    if (p->state == UNUSED)
    80002718:	86a6                	mv	a3,s1
    8000271a:	ec04a783          	lw	a5,-320(s1)
    8000271e:	dbed                	beqz	a5,80002710 <procdump+0x72>
      state = "???";
    80002720:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002722:	fcfb6be3          	bltu	s6,a5,800026f8 <procdump+0x5a>
    80002726:	02079713          	slli	a4,a5,0x20
    8000272a:	01d75793          	srli	a5,a4,0x1d
    8000272e:	97de                	add	a5,a5,s7
    80002730:	6390                	ld	a2,0(a5)
    80002732:	f279                	bnez	a2,800026f8 <procdump+0x5a>
      state = "???";
    80002734:	864e                	mv	a2,s3
    80002736:	b7c9                	j	800026f8 <procdump+0x5a>
  }
}
    80002738:	60a6                	ld	ra,72(sp)
    8000273a:	6406                	ld	s0,64(sp)
    8000273c:	74e2                	ld	s1,56(sp)
    8000273e:	7942                	ld	s2,48(sp)
    80002740:	79a2                	ld	s3,40(sp)
    80002742:	7a02                	ld	s4,32(sp)
    80002744:	6ae2                	ld	s5,24(sp)
    80002746:	6b42                	ld	s6,16(sp)
    80002748:	6ba2                	ld	s7,8(sp)
    8000274a:	6161                	addi	sp,sp,80
    8000274c:	8082                	ret

000000008000274e <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000274e:	711d                	addi	sp,sp,-96
    80002750:	ec86                	sd	ra,88(sp)
    80002752:	e8a2                	sd	s0,80(sp)
    80002754:	e4a6                	sd	s1,72(sp)
    80002756:	e0ca                	sd	s2,64(sp)
    80002758:	fc4e                	sd	s3,56(sp)
    8000275a:	f852                	sd	s4,48(sp)
    8000275c:	f456                	sd	s5,40(sp)
    8000275e:	f05a                	sd	s6,32(sp)
    80002760:	ec5e                	sd	s7,24(sp)
    80002762:	e862                	sd	s8,16(sp)
    80002764:	e466                	sd	s9,8(sp)
    80002766:	e06a                	sd	s10,0(sp)
    80002768:	1080                	addi	s0,sp,96
    8000276a:	8b2a                	mv	s6,a0
    8000276c:	8bae                	mv	s7,a1
    8000276e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002770:	fffff097          	auipc	ra,0xfffff
    80002774:	23c080e7          	jalr	572(ra) # 800019ac <myproc>
    80002778:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000277a:	0000e517          	auipc	a0,0xe
    8000277e:	41e50513          	addi	a0,a0,1054 # 80010b98 <wait_lock>
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	454080e7          	jalr	1108(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000278a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000278c:	4a15                	li	s4,5
        havekids = 1;
    8000278e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002790:	00015997          	auipc	s3,0x15
    80002794:	22098993          	addi	s3,s3,544 # 800179b0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002798:	0000ed17          	auipc	s10,0xe
    8000279c:	400d0d13          	addi	s10,s10,1024 # 80010b98 <wait_lock>
    havekids = 0;
    800027a0:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800027a2:	0000f497          	auipc	s1,0xf
    800027a6:	80e48493          	addi	s1,s1,-2034 # 80010fb0 <proc>
    800027aa:	a059                	j	80002830 <waitx+0xe2>
          pid = np->pid;
    800027ac:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800027b0:	1684a783          	lw	a5,360(s1)
    800027b4:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800027b8:	16c4a703          	lw	a4,364(s1)
    800027bc:	9f3d                	addw	a4,a4,a5
    800027be:	1704a783          	lw	a5,368(s1)
    800027c2:	9f99                	subw	a5,a5,a4
    800027c4:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027c8:	000b0e63          	beqz	s6,800027e4 <waitx+0x96>
    800027cc:	4691                	li	a3,4
    800027ce:	02c48613          	addi	a2,s1,44
    800027d2:	85da                	mv	a1,s6
    800027d4:	05093503          	ld	a0,80(s2)
    800027d8:	fffff097          	auipc	ra,0xfffff
    800027dc:	e94080e7          	jalr	-364(ra) # 8000166c <copyout>
    800027e0:	02054563          	bltz	a0,8000280a <waitx+0xbc>
          freeproc(np);
    800027e4:	8526                	mv	a0,s1
    800027e6:	fffff097          	auipc	ra,0xfffff
    800027ea:	378080e7          	jalr	888(ra) # 80001b5e <freeproc>
          release(&np->lock);
    800027ee:	8526                	mv	a0,s1
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	49a080e7          	jalr	1178(ra) # 80000c8a <release>
          release(&wait_lock);
    800027f8:	0000e517          	auipc	a0,0xe
    800027fc:	3a050513          	addi	a0,a0,928 # 80010b98 <wait_lock>
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	48a080e7          	jalr	1162(ra) # 80000c8a <release>
          return pid;
    80002808:	a09d                	j	8000286e <waitx+0x120>
            release(&np->lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	47e080e7          	jalr	1150(ra) # 80000c8a <release>
            release(&wait_lock);
    80002814:	0000e517          	auipc	a0,0xe
    80002818:	38450513          	addi	a0,a0,900 # 80010b98 <wait_lock>
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	46e080e7          	jalr	1134(ra) # 80000c8a <release>
            return -1;
    80002824:	59fd                	li	s3,-1
    80002826:	a0a1                	j	8000286e <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002828:	1a848493          	addi	s1,s1,424
    8000282c:	03348463          	beq	s1,s3,80002854 <waitx+0x106>
      if (np->parent == p)
    80002830:	7c9c                	ld	a5,56(s1)
    80002832:	ff279be3          	bne	a5,s2,80002828 <waitx+0xda>
        acquire(&np->lock);
    80002836:	8526                	mv	a0,s1
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	39e080e7          	jalr	926(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002840:	4c9c                	lw	a5,24(s1)
    80002842:	f74785e3          	beq	a5,s4,800027ac <waitx+0x5e>
        release(&np->lock);
    80002846:	8526                	mv	a0,s1
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	442080e7          	jalr	1090(ra) # 80000c8a <release>
        havekids = 1;
    80002850:	8756                	mv	a4,s5
    80002852:	bfd9                	j	80002828 <waitx+0xda>
    if (!havekids || p->killed)
    80002854:	c701                	beqz	a4,8000285c <waitx+0x10e>
    80002856:	02892783          	lw	a5,40(s2)
    8000285a:	cb8d                	beqz	a5,8000288c <waitx+0x13e>
      release(&wait_lock);
    8000285c:	0000e517          	auipc	a0,0xe
    80002860:	33c50513          	addi	a0,a0,828 # 80010b98 <wait_lock>
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	426080e7          	jalr	1062(ra) # 80000c8a <release>
      return -1;
    8000286c:	59fd                	li	s3,-1
  }
}
    8000286e:	854e                	mv	a0,s3
    80002870:	60e6                	ld	ra,88(sp)
    80002872:	6446                	ld	s0,80(sp)
    80002874:	64a6                	ld	s1,72(sp)
    80002876:	6906                	ld	s2,64(sp)
    80002878:	79e2                	ld	s3,56(sp)
    8000287a:	7a42                	ld	s4,48(sp)
    8000287c:	7aa2                	ld	s5,40(sp)
    8000287e:	7b02                	ld	s6,32(sp)
    80002880:	6be2                	ld	s7,24(sp)
    80002882:	6c42                	ld	s8,16(sp)
    80002884:	6ca2                	ld	s9,8(sp)
    80002886:	6d02                	ld	s10,0(sp)
    80002888:	6125                	addi	sp,sp,96
    8000288a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000288c:	85ea                	mv	a1,s10
    8000288e:	854a                	mv	a0,s2
    80002890:	00000097          	auipc	ra,0x0
    80002894:	94e080e7          	jalr	-1714(ra) # 800021de <sleep>
    havekids = 0;
    80002898:	b721                	j	800027a0 <waitx+0x52>

000000008000289a <update_time>:

void update_time()
{
    8000289a:	7139                	addi	sp,sp,-64
    8000289c:	fc06                	sd	ra,56(sp)
    8000289e:	f822                	sd	s0,48(sp)
    800028a0:	f426                	sd	s1,40(sp)
    800028a2:	f04a                	sd	s2,32(sp)
    800028a4:	ec4e                	sd	s3,24(sp)
    800028a6:	e852                	sd	s4,16(sp)
    800028a8:	e456                	sd	s5,8(sp)
    800028aa:	0080                	addi	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800028ac:	0000e497          	auipc	s1,0xe
    800028b0:	70448493          	addi	s1,s1,1796 # 80010fb0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800028b4:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800028b6:	00015917          	auipc	s2,0x15
    800028ba:	0fa90913          	addi	s2,s2,250 # 800179b0 <tickslock>
    800028be:	a811                	j	800028d2 <update_time+0x38>
    {
      p->rtime++;
    }
    release(&p->lock);
    800028c0:	8526                	mv	a0,s1
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	3c8080e7          	jalr	968(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800028ca:	1a848493          	addi	s1,s1,424
    800028ce:	03248063          	beq	s1,s2,800028ee <update_time+0x54>
    acquire(&p->lock);
    800028d2:	8526                	mv	a0,s1
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	302080e7          	jalr	770(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    800028dc:	4c9c                	lw	a5,24(s1)
    800028de:	ff3791e3          	bne	a5,s3,800028c0 <update_time+0x26>
      p->rtime++;
    800028e2:	1684a783          	lw	a5,360(s1)
    800028e6:	2785                	addiw	a5,a5,1
    800028e8:	16f4a423          	sw	a5,360(s1)
    800028ec:	bfd1                	j	800028c0 <update_time+0x26>
  }
  for (p = proc; p < &proc[NPROC]; p++)
    800028ee:	0000e497          	auipc	s1,0xe
    800028f2:	6c248493          	addi	s1,s1,1730 # 80010fb0 <proc>
  {
      if((p->state!=UNUSED) &&(p->pid>=9) &&(p->pid<=13)){
    800028f6:	4991                	li	s3,4
    printf("%d %d %d\n",p->pid,ticks,p->qnum);
    800028f8:	00006a97          	auipc	s5,0x6
    800028fc:	020a8a93          	addi	s5,s5,32 # 80008918 <ticks>
    80002900:	00006a17          	auipc	s4,0x6
    80002904:	998a0a13          	addi	s4,s4,-1640 # 80008298 <digits+0x258>
  for (p = proc; p < &proc[NPROC]; p++)
    80002908:	00015917          	auipc	s2,0x15
    8000290c:	0a890913          	addi	s2,s2,168 # 800179b0 <tickslock>
    80002910:	a029                	j	8000291a <update_time+0x80>
    80002912:	1a848493          	addi	s1,s1,424
    80002916:	03248363          	beq	s1,s2,8000293c <update_time+0xa2>
      if((p->state!=UNUSED) &&(p->pid>=9) &&(p->pid<=13)){
    8000291a:	4c9c                	lw	a5,24(s1)
    8000291c:	dbfd                	beqz	a5,80002912 <update_time+0x78>
    8000291e:	588c                	lw	a1,48(s1)
    80002920:	ff75879b          	addiw	a5,a1,-9
    80002924:	fef9e7e3          	bltu	s3,a5,80002912 <update_time+0x78>
    printf("%d %d %d\n",p->pid,ticks,p->qnum);
    80002928:	1944a683          	lw	a3,404(s1)
    8000292c:	000aa603          	lw	a2,0(s5)
    80002930:	8552                	mv	a0,s4
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	c58080e7          	jalr	-936(ra) # 8000058a <printf>
    8000293a:	bfe1                	j	80002912 <update_time+0x78>
      }
  }

 
    8000293c:	70e2                	ld	ra,56(sp)
    8000293e:	7442                	ld	s0,48(sp)
    80002940:	74a2                	ld	s1,40(sp)
    80002942:	7902                	ld	s2,32(sp)
    80002944:	69e2                	ld	s3,24(sp)
    80002946:	6a42                	ld	s4,16(sp)
    80002948:	6aa2                	ld	s5,8(sp)
    8000294a:	6121                	addi	sp,sp,64
    8000294c:	8082                	ret

000000008000294e <swtch>:
    8000294e:	00153023          	sd	ra,0(a0)
    80002952:	00253423          	sd	sp,8(a0)
    80002956:	e900                	sd	s0,16(a0)
    80002958:	ed04                	sd	s1,24(a0)
    8000295a:	03253023          	sd	s2,32(a0)
    8000295e:	03353423          	sd	s3,40(a0)
    80002962:	03453823          	sd	s4,48(a0)
    80002966:	03553c23          	sd	s5,56(a0)
    8000296a:	05653023          	sd	s6,64(a0)
    8000296e:	05753423          	sd	s7,72(a0)
    80002972:	05853823          	sd	s8,80(a0)
    80002976:	05953c23          	sd	s9,88(a0)
    8000297a:	07a53023          	sd	s10,96(a0)
    8000297e:	07b53423          	sd	s11,104(a0)
    80002982:	0005b083          	ld	ra,0(a1)
    80002986:	0085b103          	ld	sp,8(a1)
    8000298a:	6980                	ld	s0,16(a1)
    8000298c:	6d84                	ld	s1,24(a1)
    8000298e:	0205b903          	ld	s2,32(a1)
    80002992:	0285b983          	ld	s3,40(a1)
    80002996:	0305ba03          	ld	s4,48(a1)
    8000299a:	0385ba83          	ld	s5,56(a1)
    8000299e:	0405bb03          	ld	s6,64(a1)
    800029a2:	0485bb83          	ld	s7,72(a1)
    800029a6:	0505bc03          	ld	s8,80(a1)
    800029aa:	0585bc83          	ld	s9,88(a1)
    800029ae:	0605bd03          	ld	s10,96(a1)
    800029b2:	0685bd83          	ld	s11,104(a1)
    800029b6:	8082                	ret

00000000800029b8 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800029b8:	1141                	addi	sp,sp,-16
    800029ba:	e406                	sd	ra,8(sp)
    800029bc:	e022                	sd	s0,0(sp)
    800029be:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029c0:	00006597          	auipc	a1,0x6
    800029c4:	94858593          	addi	a1,a1,-1720 # 80008308 <states.0+0x30>
    800029c8:	00015517          	auipc	a0,0x15
    800029cc:	fe850513          	addi	a0,a0,-24 # 800179b0 <tickslock>
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	176080e7          	jalr	374(ra) # 80000b46 <initlock>
}
    800029d8:	60a2                	ld	ra,8(sp)
    800029da:	6402                	ld	s0,0(sp)
    800029dc:	0141                	addi	sp,sp,16
    800029de:	8082                	ret

00000000800029e0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800029e0:	1141                	addi	sp,sp,-16
    800029e2:	e422                	sd	s0,8(sp)
    800029e4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e6:	00003797          	auipc	a5,0x3
    800029ea:	72a78793          	addi	a5,a5,1834 # 80006110 <kernelvec>
    800029ee:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029f2:	6422                	ld	s0,8(sp)
    800029f4:	0141                	addi	sp,sp,16
    800029f6:	8082                	ret

00000000800029f8 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800029f8:	1141                	addi	sp,sp,-16
    800029fa:	e406                	sd	ra,8(sp)
    800029fc:	e022                	sd	s0,0(sp)
    800029fe:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	fac080e7          	jalr	-84(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a08:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a0c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a0e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a12:	00004697          	auipc	a3,0x4
    80002a16:	5ee68693          	addi	a3,a3,1518 # 80007000 <_trampoline>
    80002a1a:	00004717          	auipc	a4,0x4
    80002a1e:	5e670713          	addi	a4,a4,1510 # 80007000 <_trampoline>
    80002a22:	8f15                	sub	a4,a4,a3
    80002a24:	040007b7          	lui	a5,0x4000
    80002a28:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a2a:	07b2                	slli	a5,a5,0xc
    80002a2c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a2e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a32:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a34:	18002673          	csrr	a2,satp
    80002a38:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a3a:	6d30                	ld	a2,88(a0)
    80002a3c:	6138                	ld	a4,64(a0)
    80002a3e:	6585                	lui	a1,0x1
    80002a40:	972e                	add	a4,a4,a1
    80002a42:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a44:	6d38                	ld	a4,88(a0)
    80002a46:	00000617          	auipc	a2,0x0
    80002a4a:	18a60613          	addi	a2,a2,394 # 80002bd0 <usertrap>
    80002a4e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002a50:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a52:	8612                	mv	a2,tp
    80002a54:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a56:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a5a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a5e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a62:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a66:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a68:	6f18                	ld	a4,24(a4)
    80002a6a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a6e:	6928                	ld	a0,80(a0)
    80002a70:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a72:	00004717          	auipc	a4,0x4
    80002a76:	62a70713          	addi	a4,a4,1578 # 8000709c <userret>
    80002a7a:	8f15                	sub	a4,a4,a3
    80002a7c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a7e:	577d                	li	a4,-1
    80002a80:	177e                	slli	a4,a4,0x3f
    80002a82:	8d59                	or	a0,a0,a4
    80002a84:	9782                	jalr	a5
}
    80002a86:	60a2                	ld	ra,8(sp)
    80002a88:	6402                	ld	s0,0(sp)
    80002a8a:	0141                	addi	sp,sp,16
    80002a8c:	8082                	ret

0000000080002a8e <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002a8e:	1141                	addi	sp,sp,-16
    80002a90:	e406                	sd	ra,8(sp)
    80002a92:	e022                	sd	s0,0(sp)
    80002a94:	0800                	addi	s0,sp,16
  acquire(&tickslock);
    80002a96:	00015517          	auipc	a0,0x15
    80002a9a:	f1a50513          	addi	a0,a0,-230 # 800179b0 <tickslock>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	138080e7          	jalr	312(ra) # 80000bd6 <acquire>
  ticks++;
    80002aa6:	00006717          	auipc	a4,0x6
    80002aaa:	e7270713          	addi	a4,a4,-398 # 80008918 <ticks>
    80002aae:	431c                	lw	a5,0(a4)
    80002ab0:	2785                	addiw	a5,a5,1
    80002ab2:	c31c                	sw	a5,0(a4)
  update_time();
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	de6080e7          	jalr	-538(ra) # 8000289a <update_time>
  if(myproc()!=0)
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	ef0080e7          	jalr	-272(ra) # 800019ac <myproc>
    80002ac4:	c911                	beqz	a0,80002ad8 <clockintr+0x4a>
  myproc()->tickks++;
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	ee6080e7          	jalr	-282(ra) # 800019ac <myproc>
    80002ace:	19052783          	lw	a5,400(a0)
    80002ad2:	2785                	addiw	a5,a5,1
    80002ad4:	18f52823          	sw	a5,400(a0)
{
    80002ad8:	0000e797          	auipc	a5,0xe
    80002adc:	4d878793          	addi	a5,a5,1240 # 80010fb0 <proc>
  //   release(&p->lock);
  // }
  struct proc* p;
   for (p = proc; p < &proc[NPROC]; p++)
    {
      if (p->state == RUNNABLE)
    80002ae0:	460d                	li	a2,3
   for (p = proc; p < &proc[NPROC]; p++)
    80002ae2:	00015697          	auipc	a3,0x15
    80002ae6:	ece68693          	addi	a3,a3,-306 # 800179b0 <tickslock>
    80002aea:	a029                	j	80002af4 <clockintr+0x66>
    80002aec:	1a878793          	addi	a5,a5,424
    80002af0:	00d78b63          	beq	a5,a3,80002b06 <clockintr+0x78>
      if (p->state == RUNNABLE)
    80002af4:	4f98                	lw	a4,24(a5)
    80002af6:	fec71be3          	bne	a4,a2,80002aec <clockintr+0x5e>
      {
        // if(!(p->qnum==0 && p->waittime==0))
        p->waittime++;
    80002afa:	1a47a703          	lw	a4,420(a5)
    80002afe:	2705                	addiw	a4,a4,1
    80002b00:	1ae7a223          	sw	a4,420(a5)
    80002b04:	b7e5                	j	80002aec <clockintr+0x5e>
      }
    }
  wakeup(&ticks);
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	e1250513          	addi	a0,a0,-494 # 80008918 <ticks>
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	734080e7          	jalr	1844(ra) # 80002242 <wakeup>
  release(&tickslock);
    80002b16:	00015517          	auipc	a0,0x15
    80002b1a:	e9a50513          	addi	a0,a0,-358 # 800179b0 <tickslock>
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	16c080e7          	jalr	364(ra) # 80000c8a <release>
}
    80002b26:	60a2                	ld	ra,8(sp)
    80002b28:	6402                	ld	s0,0(sp)
    80002b2a:	0141                	addi	sp,sp,16
    80002b2c:	8082                	ret

0000000080002b2e <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002b2e:	1101                	addi	sp,sp,-32
    80002b30:	ec06                	sd	ra,24(sp)
    80002b32:	e822                	sd	s0,16(sp)
    80002b34:	e426                	sd	s1,8(sp)
    80002b36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b38:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002b3c:	00074d63          	bltz	a4,80002b56 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002b40:	57fd                	li	a5,-1
    80002b42:	17fe                	slli	a5,a5,0x3f
    80002b44:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002b46:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002b48:	06f70363          	beq	a4,a5,80002bae <devintr+0x80>
  }
}
    80002b4c:	60e2                	ld	ra,24(sp)
    80002b4e:	6442                	ld	s0,16(sp)
    80002b50:	64a2                	ld	s1,8(sp)
    80002b52:	6105                	addi	sp,sp,32
    80002b54:	8082                	ret
      (scause & 0xff) == 9)
    80002b56:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002b5a:	46a5                	li	a3,9
    80002b5c:	fed792e3          	bne	a5,a3,80002b40 <devintr+0x12>
    int irq = plic_claim();
    80002b60:	00003097          	auipc	ra,0x3
    80002b64:	6b8080e7          	jalr	1720(ra) # 80006218 <plic_claim>
    80002b68:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002b6a:	47a9                	li	a5,10
    80002b6c:	02f50763          	beq	a0,a5,80002b9a <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002b70:	4785                	li	a5,1
    80002b72:	02f50963          	beq	a0,a5,80002ba4 <devintr+0x76>
    return 1;
    80002b76:	4505                	li	a0,1
    else if (irq)
    80002b78:	d8f1                	beqz	s1,80002b4c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b7a:	85a6                	mv	a1,s1
    80002b7c:	00005517          	auipc	a0,0x5
    80002b80:	79450513          	addi	a0,a0,1940 # 80008310 <states.0+0x38>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	a06080e7          	jalr	-1530(ra) # 8000058a <printf>
      plic_complete(irq);
    80002b8c:	8526                	mv	a0,s1
    80002b8e:	00003097          	auipc	ra,0x3
    80002b92:	6ae080e7          	jalr	1710(ra) # 8000623c <plic_complete>
    return 1;
    80002b96:	4505                	li	a0,1
    80002b98:	bf55                	j	80002b4c <devintr+0x1e>
      uartintr();
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	dfe080e7          	jalr	-514(ra) # 80000998 <uartintr>
    80002ba2:	b7ed                	j	80002b8c <devintr+0x5e>
      virtio_disk_intr();
    80002ba4:	00004097          	auipc	ra,0x4
    80002ba8:	b60080e7          	jalr	-1184(ra) # 80006704 <virtio_disk_intr>
    80002bac:	b7c5                	j	80002b8c <devintr+0x5e>
    if (cpuid() == 0)
    80002bae:	fffff097          	auipc	ra,0xfffff
    80002bb2:	dd2080e7          	jalr	-558(ra) # 80001980 <cpuid>
    80002bb6:	c901                	beqz	a0,80002bc6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bb8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bbc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bbe:	14479073          	csrw	sip,a5
    return 2;
    80002bc2:	4509                	li	a0,2
    80002bc4:	b761                	j	80002b4c <devintr+0x1e>
      clockintr();
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	ec8080e7          	jalr	-312(ra) # 80002a8e <clockintr>
    80002bce:	b7ed                	j	80002bb8 <devintr+0x8a>

0000000080002bd0 <usertrap>:
{
    80002bd0:	1101                	addi	sp,sp,-32
    80002bd2:	ec06                	sd	ra,24(sp)
    80002bd4:	e822                	sd	s0,16(sp)
    80002bd6:	e426                	sd	s1,8(sp)
    80002bd8:	e04a                	sd	s2,0(sp)
    80002bda:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bdc:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002be0:	1007f793          	andi	a5,a5,256
    80002be4:	efb9                	bnez	a5,80002c42 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002be6:	00003797          	auipc	a5,0x3
    80002bea:	52a78793          	addi	a5,a5,1322 # 80006110 <kernelvec>
    80002bee:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	dba080e7          	jalr	-582(ra) # 800019ac <myproc>
    80002bfa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bfc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bfe:	14102773          	csrr	a4,sepc
    80002c02:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c04:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002c08:	47a1                	li	a5,8
    80002c0a:	04f70463          	beq	a4,a5,80002c52 <usertrap+0x82>
  else if ((which_dev = devintr()) != 0)
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	f20080e7          	jalr	-224(ra) # 80002b2e <devintr>
    80002c16:	892a                	mv	s2,a0
    80002c18:	c16d                	beqz	a0,80002cfa <usertrap+0x12a>
    if(which_dev == 2)
    80002c1a:	4789                	li	a5,2
    80002c1c:	06f50663          	beq	a0,a5,80002c88 <usertrap+0xb8>
  if (killed(p))
    80002c20:	8526                	mv	a0,s1
    80002c22:	00000097          	auipc	ra,0x0
    80002c26:	870080e7          	jalr	-1936(ra) # 80002492 <killed>
    80002c2a:	10051563          	bnez	a0,80002d34 <usertrap+0x164>
  usertrapret();
    80002c2e:	00000097          	auipc	ra,0x0
    80002c32:	dca080e7          	jalr	-566(ra) # 800029f8 <usertrapret>
}
    80002c36:	60e2                	ld	ra,24(sp)
    80002c38:	6442                	ld	s0,16(sp)
    80002c3a:	64a2                	ld	s1,8(sp)
    80002c3c:	6902                	ld	s2,0(sp)
    80002c3e:	6105                	addi	sp,sp,32
    80002c40:	8082                	ret
    panic("usertrap: not from user mode");
    80002c42:	00005517          	auipc	a0,0x5
    80002c46:	6ee50513          	addi	a0,a0,1774 # 80008330 <states.0+0x58>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	8f6080e7          	jalr	-1802(ra) # 80000540 <panic>
    if (killed(p))
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	840080e7          	jalr	-1984(ra) # 80002492 <killed>
    80002c5a:	e10d                	bnez	a0,80002c7c <usertrap+0xac>
    p->trapframe->epc += 4;
    80002c5c:	6cb8                	ld	a4,88(s1)
    80002c5e:	6f1c                	ld	a5,24(a4)
    80002c60:	0791                	addi	a5,a5,4
    80002c62:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c6c:	10079073          	csrw	sstatus,a5
    syscall();
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	328080e7          	jalr	808(ra) # 80002f98 <syscall>
  int which_dev = 0;
    80002c78:	4901                	li	s2,0
    80002c7a:	b75d                	j	80002c20 <usertrap+0x50>
      exit(-1);
    80002c7c:	557d                	li	a0,-1
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	694080e7          	jalr	1684(ra) # 80002312 <exit>
    80002c86:	bfd9                	j	80002c5c <usertrap+0x8c>
      myproc()->timeinterval++;
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	d24080e7          	jalr	-732(ra) # 800019ac <myproc>
    80002c90:	18452783          	lw	a5,388(a0)
    80002c94:	2785                	addiw	a5,a5,1
    80002c96:	18f52223          	sw	a5,388(a0)
       if(myproc()->timeinterval==myproc()->giventimeinterval){
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	d12080e7          	jalr	-750(ra) # 800019ac <myproc>
    80002ca2:	18452903          	lw	s2,388(a0)
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	d06080e7          	jalr	-762(ra) # 800019ac <myproc>
    80002cae:	18052783          	lw	a5,384(a0)
    80002cb2:	01278e63          	beq	a5,s2,80002cce <usertrap+0xfe>
  if (killed(p))
    80002cb6:	8526                	mv	a0,s1
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	7da080e7          	jalr	2010(ra) # 80002492 <killed>
    80002cc0:	c151                	beqz	a0,80002d44 <usertrap+0x174>
    exit(-1);
    80002cc2:	557d                	li	a0,-1
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	64e080e7          	jalr	1614(ra) # 80002312 <exit>
  if (which_dev == 2)
    80002ccc:	a8a5                	j	80002d44 <usertrap+0x174>
  memmove(p->trapp,p->trapframe,PGSIZE);
    80002cce:	6605                	lui	a2,0x1
    80002cd0:	6cac                	ld	a1,88(s1)
    80002cd2:	1784b503          	ld	a0,376(s1)
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	058080e7          	jalr	88(ra) # 80000d2e <memmove>
      myproc()->trapframe->epc=(uint64)(myproc()->funhandler); // funhadler is put in program counter 
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	cce080e7          	jalr	-818(ra) # 800019ac <myproc>
    80002ce6:	18853903          	ld	s2,392(a0)
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	cc2080e7          	jalr	-830(ra) # 800019ac <myproc>
    80002cf2:	6d3c                	ld	a5,88(a0)
    80002cf4:	0127bc23          	sd	s2,24(a5)
    80002cf8:	bf7d                	j	80002cb6 <usertrap+0xe6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cfa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cfe:	5890                	lw	a2,48(s1)
    80002d00:	00005517          	auipc	a0,0x5
    80002d04:	65050513          	addi	a0,a0,1616 # 80008350 <states.0+0x78>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	882080e7          	jalr	-1918(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d14:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	66850513          	addi	a0,a0,1640 # 80008380 <states.0+0xa8>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	86a080e7          	jalr	-1942(ra) # 8000058a <printf>
    setkilled(p);
    80002d28:	8526                	mv	a0,s1
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	73c080e7          	jalr	1852(ra) # 80002466 <setkilled>
    80002d32:	b5fd                	j	80002c20 <usertrap+0x50>
    exit(-1);
    80002d34:	557d                	li	a0,-1
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	5dc080e7          	jalr	1500(ra) # 80002312 <exit>
  if (which_dev == 2)
    80002d3e:	4789                	li	a5,2
    80002d40:	eef917e3          	bne	s2,a5,80002c2e <usertrap+0x5e>
    yield();
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	45e080e7          	jalr	1118(ra) # 800021a2 <yield>
    80002d4c:	b5cd                	j	80002c2e <usertrap+0x5e>

0000000080002d4e <kerneltrap>:
{
    80002d4e:	7179                	addi	sp,sp,-48
    80002d50:	f406                	sd	ra,40(sp)
    80002d52:	f022                	sd	s0,32(sp)
    80002d54:	ec26                	sd	s1,24(sp)
    80002d56:	e84a                	sd	s2,16(sp)
    80002d58:	e44e                	sd	s3,8(sp)
    80002d5a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d5c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d60:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d64:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002d68:	1004f793          	andi	a5,s1,256
    80002d6c:	cb85                	beqz	a5,80002d9c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d6e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d72:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002d74:	ef85                	bnez	a5,80002dac <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002d76:	00000097          	auipc	ra,0x0
    80002d7a:	db8080e7          	jalr	-584(ra) # 80002b2e <devintr>
    80002d7e:	cd1d                	beqz	a0,80002dbc <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d80:	4789                	li	a5,2
    80002d82:	06f50a63          	beq	a0,a5,80002df6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d86:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d8a:	10049073          	csrw	sstatus,s1
}
    80002d8e:	70a2                	ld	ra,40(sp)
    80002d90:	7402                	ld	s0,32(sp)
    80002d92:	64e2                	ld	s1,24(sp)
    80002d94:	6942                	ld	s2,16(sp)
    80002d96:	69a2                	ld	s3,8(sp)
    80002d98:	6145                	addi	sp,sp,48
    80002d9a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	60450513          	addi	a0,a0,1540 # 800083a0 <states.0+0xc8>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	79c080e7          	jalr	1948(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002dac:	00005517          	auipc	a0,0x5
    80002db0:	61c50513          	addi	a0,a0,1564 # 800083c8 <states.0+0xf0>
    80002db4:	ffffd097          	auipc	ra,0xffffd
    80002db8:	78c080e7          	jalr	1932(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002dbc:	85ce                	mv	a1,s3
    80002dbe:	00005517          	auipc	a0,0x5
    80002dc2:	62a50513          	addi	a0,a0,1578 # 800083e8 <states.0+0x110>
    80002dc6:	ffffd097          	auipc	ra,0xffffd
    80002dca:	7c4080e7          	jalr	1988(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dd2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dd6:	00005517          	auipc	a0,0x5
    80002dda:	62250513          	addi	a0,a0,1570 # 800083f8 <states.0+0x120>
    80002dde:	ffffd097          	auipc	ra,0xffffd
    80002de2:	7ac080e7          	jalr	1964(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002de6:	00005517          	auipc	a0,0x5
    80002dea:	62a50513          	addi	a0,a0,1578 # 80008410 <states.0+0x138>
    80002dee:	ffffd097          	auipc	ra,0xffffd
    80002df2:	752080e7          	jalr	1874(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	bb6080e7          	jalr	-1098(ra) # 800019ac <myproc>
    80002dfe:	d541                	beqz	a0,80002d86 <kerneltrap+0x38>
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	bac080e7          	jalr	-1108(ra) # 800019ac <myproc>
    80002e08:	4d18                	lw	a4,24(a0)
    80002e0a:	4791                	li	a5,4
    80002e0c:	f6f71de3          	bne	a4,a5,80002d86 <kerneltrap+0x38>
    yield();
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	392080e7          	jalr	914(ra) # 800021a2 <yield>
    80002e18:	b7bd                	j	80002d86 <kerneltrap+0x38>

0000000080002e1a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	e426                	sd	s1,8(sp)
    80002e22:	1000                	addi	s0,sp,32
    80002e24:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e26:	fffff097          	auipc	ra,0xfffff
    80002e2a:	b86080e7          	jalr	-1146(ra) # 800019ac <myproc>
  switch (n) {
    80002e2e:	4795                	li	a5,5
    80002e30:	0497e163          	bltu	a5,s1,80002e72 <argraw+0x58>
    80002e34:	048a                	slli	s1,s1,0x2
    80002e36:	00005717          	auipc	a4,0x5
    80002e3a:	61270713          	addi	a4,a4,1554 # 80008448 <states.0+0x170>
    80002e3e:	94ba                	add	s1,s1,a4
    80002e40:	409c                	lw	a5,0(s1)
    80002e42:	97ba                	add	a5,a5,a4
    80002e44:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e46:	6d3c                	ld	a5,88(a0)
    80002e48:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e4a:	60e2                	ld	ra,24(sp)
    80002e4c:	6442                	ld	s0,16(sp)
    80002e4e:	64a2                	ld	s1,8(sp)
    80002e50:	6105                	addi	sp,sp,32
    80002e52:	8082                	ret
    return p->trapframe->a1;
    80002e54:	6d3c                	ld	a5,88(a0)
    80002e56:	7fa8                	ld	a0,120(a5)
    80002e58:	bfcd                	j	80002e4a <argraw+0x30>
    return p->trapframe->a2;
    80002e5a:	6d3c                	ld	a5,88(a0)
    80002e5c:	63c8                	ld	a0,128(a5)
    80002e5e:	b7f5                	j	80002e4a <argraw+0x30>
    return p->trapframe->a3;
    80002e60:	6d3c                	ld	a5,88(a0)
    80002e62:	67c8                	ld	a0,136(a5)
    80002e64:	b7dd                	j	80002e4a <argraw+0x30>
    return p->trapframe->a4;
    80002e66:	6d3c                	ld	a5,88(a0)
    80002e68:	6bc8                	ld	a0,144(a5)
    80002e6a:	b7c5                	j	80002e4a <argraw+0x30>
    return p->trapframe->a5;
    80002e6c:	6d3c                	ld	a5,88(a0)
    80002e6e:	6fc8                	ld	a0,152(a5)
    80002e70:	bfe9                	j	80002e4a <argraw+0x30>
  panic("argraw");
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	5ae50513          	addi	a0,a0,1454 # 80008420 <states.0+0x148>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	6c6080e7          	jalr	1734(ra) # 80000540 <panic>

0000000080002e82 <fetchaddr>:
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	e426                	sd	s1,8(sp)
    80002e8a:	e04a                	sd	s2,0(sp)
    80002e8c:	1000                	addi	s0,sp,32
    80002e8e:	84aa                	mv	s1,a0
    80002e90:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	b1a080e7          	jalr	-1254(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e9a:	653c                	ld	a5,72(a0)
    80002e9c:	02f4f863          	bgeu	s1,a5,80002ecc <fetchaddr+0x4a>
    80002ea0:	00848713          	addi	a4,s1,8
    80002ea4:	02e7e663          	bltu	a5,a4,80002ed0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ea8:	46a1                	li	a3,8
    80002eaa:	8626                	mv	a2,s1
    80002eac:	85ca                	mv	a1,s2
    80002eae:	6928                	ld	a0,80(a0)
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	848080e7          	jalr	-1976(ra) # 800016f8 <copyin>
    80002eb8:	00a03533          	snez	a0,a0
    80002ebc:	40a00533          	neg	a0,a0
}
    80002ec0:	60e2                	ld	ra,24(sp)
    80002ec2:	6442                	ld	s0,16(sp)
    80002ec4:	64a2                	ld	s1,8(sp)
    80002ec6:	6902                	ld	s2,0(sp)
    80002ec8:	6105                	addi	sp,sp,32
    80002eca:	8082                	ret
    return -1;
    80002ecc:	557d                	li	a0,-1
    80002ece:	bfcd                	j	80002ec0 <fetchaddr+0x3e>
    80002ed0:	557d                	li	a0,-1
    80002ed2:	b7fd                	j	80002ec0 <fetchaddr+0x3e>

0000000080002ed4 <fetchstr>:
{
    80002ed4:	7179                	addi	sp,sp,-48
    80002ed6:	f406                	sd	ra,40(sp)
    80002ed8:	f022                	sd	s0,32(sp)
    80002eda:	ec26                	sd	s1,24(sp)
    80002edc:	e84a                	sd	s2,16(sp)
    80002ede:	e44e                	sd	s3,8(sp)
    80002ee0:	1800                	addi	s0,sp,48
    80002ee2:	892a                	mv	s2,a0
    80002ee4:	84ae                	mv	s1,a1
    80002ee6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	ac4080e7          	jalr	-1340(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ef0:	86ce                	mv	a3,s3
    80002ef2:	864a                	mv	a2,s2
    80002ef4:	85a6                	mv	a1,s1
    80002ef6:	6928                	ld	a0,80(a0)
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	88e080e7          	jalr	-1906(ra) # 80001786 <copyinstr>
    80002f00:	00054e63          	bltz	a0,80002f1c <fetchstr+0x48>
  return strlen(buf);
    80002f04:	8526                	mv	a0,s1
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	f48080e7          	jalr	-184(ra) # 80000e4e <strlen>
}
    80002f0e:	70a2                	ld	ra,40(sp)
    80002f10:	7402                	ld	s0,32(sp)
    80002f12:	64e2                	ld	s1,24(sp)
    80002f14:	6942                	ld	s2,16(sp)
    80002f16:	69a2                	ld	s3,8(sp)
    80002f18:	6145                	addi	sp,sp,48
    80002f1a:	8082                	ret
    return -1;
    80002f1c:	557d                	li	a0,-1
    80002f1e:	bfc5                	j	80002f0e <fetchstr+0x3a>

0000000080002f20 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f20:	1101                	addi	sp,sp,-32
    80002f22:	ec06                	sd	ra,24(sp)
    80002f24:	e822                	sd	s0,16(sp)
    80002f26:	e426                	sd	s1,8(sp)
    80002f28:	1000                	addi	s0,sp,32
    80002f2a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	eee080e7          	jalr	-274(ra) # 80002e1a <argraw>
    80002f34:	c088                	sw	a0,0(s1)
}
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	64a2                	ld	s1,8(sp)
    80002f3c:	6105                	addi	sp,sp,32
    80002f3e:	8082                	ret

0000000080002f40 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f40:	1101                	addi	sp,sp,-32
    80002f42:	ec06                	sd	ra,24(sp)
    80002f44:	e822                	sd	s0,16(sp)
    80002f46:	e426                	sd	s1,8(sp)
    80002f48:	1000                	addi	s0,sp,32
    80002f4a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f4c:	00000097          	auipc	ra,0x0
    80002f50:	ece080e7          	jalr	-306(ra) # 80002e1a <argraw>
    80002f54:	e088                	sd	a0,0(s1)
}
    80002f56:	60e2                	ld	ra,24(sp)
    80002f58:	6442                	ld	s0,16(sp)
    80002f5a:	64a2                	ld	s1,8(sp)
    80002f5c:	6105                	addi	sp,sp,32
    80002f5e:	8082                	ret

0000000080002f60 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f60:	7179                	addi	sp,sp,-48
    80002f62:	f406                	sd	ra,40(sp)
    80002f64:	f022                	sd	s0,32(sp)
    80002f66:	ec26                	sd	s1,24(sp)
    80002f68:	e84a                	sd	s2,16(sp)
    80002f6a:	1800                	addi	s0,sp,48
    80002f6c:	84ae                	mv	s1,a1
    80002f6e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f70:	fd840593          	addi	a1,s0,-40
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	fcc080e7          	jalr	-52(ra) # 80002f40 <argaddr>
  return fetchstr(addr, buf, max);
    80002f7c:	864a                	mv	a2,s2
    80002f7e:	85a6                	mv	a1,s1
    80002f80:	fd843503          	ld	a0,-40(s0)
    80002f84:	00000097          	auipc	ra,0x0
    80002f88:	f50080e7          	jalr	-176(ra) # 80002ed4 <fetchstr>
}
    80002f8c:	70a2                	ld	ra,40(sp)
    80002f8e:	7402                	ld	s0,32(sp)
    80002f90:	64e2                	ld	s1,24(sp)
    80002f92:	6942                	ld	s2,16(sp)
    80002f94:	6145                	addi	sp,sp,48
    80002f96:	8082                	ret

0000000080002f98 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002f98:	1101                	addi	sp,sp,-32
    80002f9a:	ec06                	sd	ra,24(sp)
    80002f9c:	e822                	sd	s0,16(sp)
    80002f9e:	e426                	sd	s1,8(sp)
    80002fa0:	e04a                	sd	s2,0(sp)
    80002fa2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	a08080e7          	jalr	-1528(ra) # 800019ac <myproc>
    80002fac:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fae:	05853903          	ld	s2,88(a0)
    80002fb2:	0a893783          	ld	a5,168(s2)
    80002fb6:	0007869b          	sext.w	a3,a5
    if (num==SYS_read){
    80002fba:	4715                	li	a4,5
    80002fbc:	02e68763          	beq	a3,a4,80002fea <syscall+0x52>
      reedcount++;
  }
  if(num==SYS_getreadcount){
    80002fc0:	475d                	li	a4,23
    80002fc2:	04e69763          	bne	a3,a4,80003010 <syscall+0x78>
      p->readcount=reedcount;
    80002fc6:	00006717          	auipc	a4,0x6
    80002fca:	95672703          	lw	a4,-1706(a4) # 8000891c <reedcount>
    80002fce:	16e52a23          	sw	a4,372(a0)
  }

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fd2:	37fd                	addiw	a5,a5,-1
    80002fd4:	4661                	li	a2,24
    80002fd6:	00000717          	auipc	a4,0x0
    80002fda:	2f870713          	addi	a4,a4,760 # 800032ce <sys_getreadcount>
    80002fde:	04f66663          	bltu	a2,a5,8000302a <syscall+0x92>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fe2:	9702                	jalr	a4
    80002fe4:	06a93823          	sd	a0,112(s2)
    80002fe8:	a8b9                	j	80003046 <syscall+0xae>
      reedcount++;
    80002fea:	00006617          	auipc	a2,0x6
    80002fee:	93260613          	addi	a2,a2,-1742 # 8000891c <reedcount>
    80002ff2:	4218                	lw	a4,0(a2)
    80002ff4:	2705                	addiw	a4,a4,1
    80002ff6:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ff8:	37fd                	addiw	a5,a5,-1
    80002ffa:	4761                	li	a4,24
    80002ffc:	02f76763          	bltu	a4,a5,8000302a <syscall+0x92>
    80003000:	068e                	slli	a3,a3,0x3
    80003002:	00005797          	auipc	a5,0x5
    80003006:	45e78793          	addi	a5,a5,1118 # 80008460 <syscalls>
    8000300a:	97b6                	add	a5,a5,a3
    8000300c:	6398                	ld	a4,0(a5)
    8000300e:	bfd1                	j	80002fe2 <syscall+0x4a>
    80003010:	37fd                	addiw	a5,a5,-1
    80003012:	4761                	li	a4,24
    80003014:	00f76b63          	bltu	a4,a5,8000302a <syscall+0x92>
    80003018:	00369713          	slli	a4,a3,0x3
    8000301c:	00005797          	auipc	a5,0x5
    80003020:	44478793          	addi	a5,a5,1092 # 80008460 <syscalls>
    80003024:	97ba                	add	a5,a5,a4
    80003026:	6398                	ld	a4,0(a5)
    80003028:	ff4d                	bnez	a4,80002fe2 <syscall+0x4a>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000302a:	15848613          	addi	a2,s1,344
    8000302e:	588c                	lw	a1,48(s1)
    80003030:	00005517          	auipc	a0,0x5
    80003034:	3f850513          	addi	a0,a0,1016 # 80008428 <states.0+0x150>
    80003038:	ffffd097          	auipc	ra,0xffffd
    8000303c:	552080e7          	jalr	1362(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003040:	6cbc                	ld	a5,88(s1)
    80003042:	577d                	li	a4,-1
    80003044:	fbb8                	sd	a4,112(a5)
  }
}
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	64a2                	ld	s1,8(sp)
    8000304c:	6902                	ld	s2,0(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret

0000000080003052 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000305a:	fec40593          	addi	a1,s0,-20
    8000305e:	4501                	li	a0,0
    80003060:	00000097          	auipc	ra,0x0
    80003064:	ec0080e7          	jalr	-320(ra) # 80002f20 <argint>
  exit(n);
    80003068:	fec42503          	lw	a0,-20(s0)
    8000306c:	fffff097          	auipc	ra,0xfffff
    80003070:	2a6080e7          	jalr	678(ra) # 80002312 <exit>
  return 0; // not reached
}
    80003074:	4501                	li	a0,0
    80003076:	60e2                	ld	ra,24(sp)
    80003078:	6442                	ld	s0,16(sp)
    8000307a:	6105                	addi	sp,sp,32
    8000307c:	8082                	ret

000000008000307e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000307e:	1141                	addi	sp,sp,-16
    80003080:	e406                	sd	ra,8(sp)
    80003082:	e022                	sd	s0,0(sp)
    80003084:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	926080e7          	jalr	-1754(ra) # 800019ac <myproc>
}
    8000308e:	5908                	lw	a0,48(a0)
    80003090:	60a2                	ld	ra,8(sp)
    80003092:	6402                	ld	s0,0(sp)
    80003094:	0141                	addi	sp,sp,16
    80003096:	8082                	ret

0000000080003098 <sys_fork>:

uint64
sys_fork(void)
{
    80003098:	1141                	addi	sp,sp,-16
    8000309a:	e406                	sd	ra,8(sp)
    8000309c:	e022                	sd	s0,0(sp)
    8000309e:	0800                	addi	s0,sp,16
  return fork();
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	d0c080e7          	jalr	-756(ra) # 80001dac <fork>
}
    800030a8:	60a2                	ld	ra,8(sp)
    800030aa:	6402                	ld	s0,0(sp)
    800030ac:	0141                	addi	sp,sp,16
    800030ae:	8082                	ret

00000000800030b0 <sys_wait>:

uint64
sys_wait(void)
{
    800030b0:	1101                	addi	sp,sp,-32
    800030b2:	ec06                	sd	ra,24(sp)
    800030b4:	e822                	sd	s0,16(sp)
    800030b6:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800030b8:	fe840593          	addi	a1,s0,-24
    800030bc:	4501                	li	a0,0
    800030be:	00000097          	auipc	ra,0x0
    800030c2:	e82080e7          	jalr	-382(ra) # 80002f40 <argaddr>
  return wait(p);
    800030c6:	fe843503          	ld	a0,-24(s0)
    800030ca:	fffff097          	auipc	ra,0xfffff
    800030ce:	3fa080e7          	jalr	1018(ra) # 800024c4 <wait>
}
    800030d2:	60e2                	ld	ra,24(sp)
    800030d4:	6442                	ld	s0,16(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret

00000000800030da <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030da:	7179                	addi	sp,sp,-48
    800030dc:	f406                	sd	ra,40(sp)
    800030de:	f022                	sd	s0,32(sp)
    800030e0:	ec26                	sd	s1,24(sp)
    800030e2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800030e4:	fdc40593          	addi	a1,s0,-36
    800030e8:	4501                	li	a0,0
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	e36080e7          	jalr	-458(ra) # 80002f20 <argint>
  addr = myproc()->sz;
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	8ba080e7          	jalr	-1862(ra) # 800019ac <myproc>
    800030fa:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800030fc:	fdc42503          	lw	a0,-36(s0)
    80003100:	fffff097          	auipc	ra,0xfffff
    80003104:	c50080e7          	jalr	-944(ra) # 80001d50 <growproc>
    80003108:	00054863          	bltz	a0,80003118 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000310c:	8526                	mv	a0,s1
    8000310e:	70a2                	ld	ra,40(sp)
    80003110:	7402                	ld	s0,32(sp)
    80003112:	64e2                	ld	s1,24(sp)
    80003114:	6145                	addi	sp,sp,48
    80003116:	8082                	ret
    return -1;
    80003118:	54fd                	li	s1,-1
    8000311a:	bfcd                	j	8000310c <sys_sbrk+0x32>

000000008000311c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000311c:	7139                	addi	sp,sp,-64
    8000311e:	fc06                	sd	ra,56(sp)
    80003120:	f822                	sd	s0,48(sp)
    80003122:	f426                	sd	s1,40(sp)
    80003124:	f04a                	sd	s2,32(sp)
    80003126:	ec4e                	sd	s3,24(sp)
    80003128:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000312a:	fcc40593          	addi	a1,s0,-52
    8000312e:	4501                	li	a0,0
    80003130:	00000097          	auipc	ra,0x0
    80003134:	df0080e7          	jalr	-528(ra) # 80002f20 <argint>
  acquire(&tickslock);
    80003138:	00015517          	auipc	a0,0x15
    8000313c:	87850513          	addi	a0,a0,-1928 # 800179b0 <tickslock>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	a96080e7          	jalr	-1386(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003148:	00005917          	auipc	s2,0x5
    8000314c:	7d092903          	lw	s2,2000(s2) # 80008918 <ticks>
  while (ticks - ticks0 < n)
    80003150:	fcc42783          	lw	a5,-52(s0)
    80003154:	cf9d                	beqz	a5,80003192 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003156:	00015997          	auipc	s3,0x15
    8000315a:	85a98993          	addi	s3,s3,-1958 # 800179b0 <tickslock>
    8000315e:	00005497          	auipc	s1,0x5
    80003162:	7ba48493          	addi	s1,s1,1978 # 80008918 <ticks>
    if (killed(myproc()))
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	846080e7          	jalr	-1978(ra) # 800019ac <myproc>
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	324080e7          	jalr	804(ra) # 80002492 <killed>
    80003176:	ed15                	bnez	a0,800031b2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003178:	85ce                	mv	a1,s3
    8000317a:	8526                	mv	a0,s1
    8000317c:	fffff097          	auipc	ra,0xfffff
    80003180:	062080e7          	jalr	98(ra) # 800021de <sleep>
  while (ticks - ticks0 < n)
    80003184:	409c                	lw	a5,0(s1)
    80003186:	412787bb          	subw	a5,a5,s2
    8000318a:	fcc42703          	lw	a4,-52(s0)
    8000318e:	fce7ece3          	bltu	a5,a4,80003166 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003192:	00015517          	auipc	a0,0x15
    80003196:	81e50513          	addi	a0,a0,-2018 # 800179b0 <tickslock>
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	af0080e7          	jalr	-1296(ra) # 80000c8a <release>
  return 0;
    800031a2:	4501                	li	a0,0
}
    800031a4:	70e2                	ld	ra,56(sp)
    800031a6:	7442                	ld	s0,48(sp)
    800031a8:	74a2                	ld	s1,40(sp)
    800031aa:	7902                	ld	s2,32(sp)
    800031ac:	69e2                	ld	s3,24(sp)
    800031ae:	6121                	addi	sp,sp,64
    800031b0:	8082                	ret
      release(&tickslock);
    800031b2:	00014517          	auipc	a0,0x14
    800031b6:	7fe50513          	addi	a0,a0,2046 # 800179b0 <tickslock>
    800031ba:	ffffe097          	auipc	ra,0xffffe
    800031be:	ad0080e7          	jalr	-1328(ra) # 80000c8a <release>
      return -1;
    800031c2:	557d                	li	a0,-1
    800031c4:	b7c5                	j	800031a4 <sys_sleep+0x88>

00000000800031c6 <sys_kill>:

uint64
sys_kill(void)
{
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800031ce:	fec40593          	addi	a1,s0,-20
    800031d2:	4501                	li	a0,0
    800031d4:	00000097          	auipc	ra,0x0
    800031d8:	d4c080e7          	jalr	-692(ra) # 80002f20 <argint>
  return kill(pid);
    800031dc:	fec42503          	lw	a0,-20(s0)
    800031e0:	fffff097          	auipc	ra,0xfffff
    800031e4:	214080e7          	jalr	532(ra) # 800023f4 <kill>
}
    800031e8:	60e2                	ld	ra,24(sp)
    800031ea:	6442                	ld	s0,16(sp)
    800031ec:	6105                	addi	sp,sp,32
    800031ee:	8082                	ret

00000000800031f0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031f0:	1101                	addi	sp,sp,-32
    800031f2:	ec06                	sd	ra,24(sp)
    800031f4:	e822                	sd	s0,16(sp)
    800031f6:	e426                	sd	s1,8(sp)
    800031f8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031fa:	00014517          	auipc	a0,0x14
    800031fe:	7b650513          	addi	a0,a0,1974 # 800179b0 <tickslock>
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	9d4080e7          	jalr	-1580(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000320a:	00005497          	auipc	s1,0x5
    8000320e:	70e4a483          	lw	s1,1806(s1) # 80008918 <ticks>
  release(&tickslock);
    80003212:	00014517          	auipc	a0,0x14
    80003216:	79e50513          	addi	a0,a0,1950 # 800179b0 <tickslock>
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	a70080e7          	jalr	-1424(ra) # 80000c8a <release>
  return xticks;
}
    80003222:	02049513          	slli	a0,s1,0x20
    80003226:	9101                	srli	a0,a0,0x20
    80003228:	60e2                	ld	ra,24(sp)
    8000322a:	6442                	ld	s0,16(sp)
    8000322c:	64a2                	ld	s1,8(sp)
    8000322e:	6105                	addi	sp,sp,32
    80003230:	8082                	ret

0000000080003232 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003232:	7139                	addi	sp,sp,-64
    80003234:	fc06                	sd	ra,56(sp)
    80003236:	f822                	sd	s0,48(sp)
    80003238:	f426                	sd	s1,40(sp)
    8000323a:	f04a                	sd	s2,32(sp)
    8000323c:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000323e:	fd840593          	addi	a1,s0,-40
    80003242:	4501                	li	a0,0
    80003244:	00000097          	auipc	ra,0x0
    80003248:	cfc080e7          	jalr	-772(ra) # 80002f40 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000324c:	fd040593          	addi	a1,s0,-48
    80003250:	4505                	li	a0,1
    80003252:	00000097          	auipc	ra,0x0
    80003256:	cee080e7          	jalr	-786(ra) # 80002f40 <argaddr>
  argaddr(2, &addr2);
    8000325a:	fc840593          	addi	a1,s0,-56
    8000325e:	4509                	li	a0,2
    80003260:	00000097          	auipc	ra,0x0
    80003264:	ce0080e7          	jalr	-800(ra) # 80002f40 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003268:	fc040613          	addi	a2,s0,-64
    8000326c:	fc440593          	addi	a1,s0,-60
    80003270:	fd843503          	ld	a0,-40(s0)
    80003274:	fffff097          	auipc	ra,0xfffff
    80003278:	4da080e7          	jalr	1242(ra) # 8000274e <waitx>
    8000327c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	72e080e7          	jalr	1838(ra) # 800019ac <myproc>
    80003286:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003288:	4691                	li	a3,4
    8000328a:	fc440613          	addi	a2,s0,-60
    8000328e:	fd043583          	ld	a1,-48(s0)
    80003292:	6928                	ld	a0,80(a0)
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	3d8080e7          	jalr	984(ra) # 8000166c <copyout>
    return -1;
    8000329c:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000329e:	00054f63          	bltz	a0,800032bc <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800032a2:	4691                	li	a3,4
    800032a4:	fc040613          	addi	a2,s0,-64
    800032a8:	fc843583          	ld	a1,-56(s0)
    800032ac:	68a8                	ld	a0,80(s1)
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	3be080e7          	jalr	958(ra) # 8000166c <copyout>
    800032b6:	00054a63          	bltz	a0,800032ca <sys_waitx+0x98>
    return -1;
  return ret;
    800032ba:	87ca                	mv	a5,s2
}
    800032bc:	853e                	mv	a0,a5
    800032be:	70e2                	ld	ra,56(sp)
    800032c0:	7442                	ld	s0,48(sp)
    800032c2:	74a2                	ld	s1,40(sp)
    800032c4:	7902                	ld	s2,32(sp)
    800032c6:	6121                	addi	sp,sp,64
    800032c8:	8082                	ret
    return -1;
    800032ca:	57fd                	li	a5,-1
    800032cc:	bfc5                	j	800032bc <sys_waitx+0x8a>

00000000800032ce <sys_getreadcount>:
int
sys_getreadcount(void)
{
    800032ce:	1141                	addi	sp,sp,-16
    800032d0:	e406                	sd	ra,8(sp)
    800032d2:	e022                	sd	s0,0(sp)
    800032d4:	0800                	addi	s0,sp,16
  return myproc()->readcount;
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	6d6080e7          	jalr	1750(ra) # 800019ac <myproc>
}
    800032de:	17452503          	lw	a0,372(a0)
    800032e2:	60a2                	ld	ra,8(sp)
    800032e4:	6402                	ld	s0,0(sp)
    800032e6:	0141                	addi	sp,sp,16
    800032e8:	8082                	ret

00000000800032ea <sys_sigalarm>:
int 
sys_sigalarm(void){
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	1000                	addi	s0,sp,32

  uint64 addr,addr1; 
  argaddr(0, &addr);
    800032f2:	fe840593          	addi	a1,s0,-24
    800032f6:	4501                	li	a0,0
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	c48080e7          	jalr	-952(ra) # 80002f40 <argaddr>
  argaddr(1, &addr1);
    80003300:	fe040593          	addi	a1,s0,-32
    80003304:	4505                	li	a0,1
    80003306:	00000097          	auipc	ra,0x0
    8000330a:	c3a080e7          	jalr	-966(ra) # 80002f40 <argaddr>
  //  if(argint(0, &addr) < 0 || argaddr(1, &addr1) < 0)
  //       return -1;
  struct proc *p = myproc();
    8000330e:	ffffe097          	auipc	ra,0xffffe
    80003312:	69e080e7          	jalr	1694(ra) # 800019ac <myproc>
  p->giventimeinterval=addr;
    80003316:	fe843783          	ld	a5,-24(s0)
    8000331a:	18f52023          	sw	a5,384(a0)
  p->funhandler=(void*)(addr1);
    8000331e:	fe043783          	ld	a5,-32(s0)
    80003322:	18f53423          	sd	a5,392(a0)
  return 0;
}
    80003326:	4501                	li	a0,0
    80003328:	60e2                	ld	ra,24(sp)
    8000332a:	6442                	ld	s0,16(sp)
    8000332c:	6105                	addi	sp,sp,32
    8000332e:	8082                	ret

0000000080003330 <sys_sigreturn>:
int 
sys_sigreturn(void){
    80003330:	1101                	addi	sp,sp,-32
    80003332:	ec06                	sd	ra,24(sp)
    80003334:	e822                	sd	s0,16(sp)
    80003336:	e426                	sd	s1,8(sp)
    80003338:	1000                	addi	s0,sp,32
  memmove(myproc()->trapframe,myproc()->trapp,PGSIZE);
    8000333a:	ffffe097          	auipc	ra,0xffffe
    8000333e:	672080e7          	jalr	1650(ra) # 800019ac <myproc>
    80003342:	6d24                	ld	s1,88(a0)
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	668080e7          	jalr	1640(ra) # 800019ac <myproc>
    8000334c:	6605                	lui	a2,0x1
    8000334e:	17853583          	ld	a1,376(a0)
    80003352:	8526                	mv	a0,s1
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	9da080e7          	jalr	-1574(ra) # 80000d2e <memmove>
     myproc()->timeinterval=0;
    8000335c:	ffffe097          	auipc	ra,0xffffe
    80003360:	650080e7          	jalr	1616(ra) # 800019ac <myproc>
    80003364:	18052223          	sw	zero,388(a0)
return myproc()->trapframe->a0;
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	644080e7          	jalr	1604(ra) # 800019ac <myproc>
    80003370:	6d3c                	ld	a5,88(a0)
    80003372:	5ba8                	lw	a0,112(a5)
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6105                	addi	sp,sp,32
    8000337c:	8082                	ret

000000008000337e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000337e:	7179                	addi	sp,sp,-48
    80003380:	f406                	sd	ra,40(sp)
    80003382:	f022                	sd	s0,32(sp)
    80003384:	ec26                	sd	s1,24(sp)
    80003386:	e84a                	sd	s2,16(sp)
    80003388:	e44e                	sd	s3,8(sp)
    8000338a:	e052                	sd	s4,0(sp)
    8000338c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000338e:	00005597          	auipc	a1,0x5
    80003392:	1a258593          	addi	a1,a1,418 # 80008530 <syscalls+0xd0>
    80003396:	00014517          	auipc	a0,0x14
    8000339a:	63250513          	addi	a0,a0,1586 # 800179c8 <bcache>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	7a8080e7          	jalr	1960(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033a6:	0001c797          	auipc	a5,0x1c
    800033aa:	62278793          	addi	a5,a5,1570 # 8001f9c8 <bcache+0x8000>
    800033ae:	0001d717          	auipc	a4,0x1d
    800033b2:	88270713          	addi	a4,a4,-1918 # 8001fc30 <bcache+0x8268>
    800033b6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033ba:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033be:	00014497          	auipc	s1,0x14
    800033c2:	62248493          	addi	s1,s1,1570 # 800179e0 <bcache+0x18>
    b->next = bcache.head.next;
    800033c6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033c8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033ca:	00005a17          	auipc	s4,0x5
    800033ce:	16ea0a13          	addi	s4,s4,366 # 80008538 <syscalls+0xd8>
    b->next = bcache.head.next;
    800033d2:	2b893783          	ld	a5,696(s2)
    800033d6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033d8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033dc:	85d2                	mv	a1,s4
    800033de:	01048513          	addi	a0,s1,16
    800033e2:	00001097          	auipc	ra,0x1
    800033e6:	4c8080e7          	jalr	1224(ra) # 800048aa <initsleeplock>
    bcache.head.next->prev = b;
    800033ea:	2b893783          	ld	a5,696(s2)
    800033ee:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033f0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033f4:	45848493          	addi	s1,s1,1112
    800033f8:	fd349de3          	bne	s1,s3,800033d2 <binit+0x54>
  }
}
    800033fc:	70a2                	ld	ra,40(sp)
    800033fe:	7402                	ld	s0,32(sp)
    80003400:	64e2                	ld	s1,24(sp)
    80003402:	6942                	ld	s2,16(sp)
    80003404:	69a2                	ld	s3,8(sp)
    80003406:	6a02                	ld	s4,0(sp)
    80003408:	6145                	addi	sp,sp,48
    8000340a:	8082                	ret

000000008000340c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000340c:	7179                	addi	sp,sp,-48
    8000340e:	f406                	sd	ra,40(sp)
    80003410:	f022                	sd	s0,32(sp)
    80003412:	ec26                	sd	s1,24(sp)
    80003414:	e84a                	sd	s2,16(sp)
    80003416:	e44e                	sd	s3,8(sp)
    80003418:	1800                	addi	s0,sp,48
    8000341a:	892a                	mv	s2,a0
    8000341c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000341e:	00014517          	auipc	a0,0x14
    80003422:	5aa50513          	addi	a0,a0,1450 # 800179c8 <bcache>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	7b0080e7          	jalr	1968(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000342e:	0001d497          	auipc	s1,0x1d
    80003432:	8524b483          	ld	s1,-1966(s1) # 8001fc80 <bcache+0x82b8>
    80003436:	0001c797          	auipc	a5,0x1c
    8000343a:	7fa78793          	addi	a5,a5,2042 # 8001fc30 <bcache+0x8268>
    8000343e:	02f48f63          	beq	s1,a5,8000347c <bread+0x70>
    80003442:	873e                	mv	a4,a5
    80003444:	a021                	j	8000344c <bread+0x40>
    80003446:	68a4                	ld	s1,80(s1)
    80003448:	02e48a63          	beq	s1,a4,8000347c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000344c:	449c                	lw	a5,8(s1)
    8000344e:	ff279ce3          	bne	a5,s2,80003446 <bread+0x3a>
    80003452:	44dc                	lw	a5,12(s1)
    80003454:	ff3799e3          	bne	a5,s3,80003446 <bread+0x3a>
      b->refcnt++;
    80003458:	40bc                	lw	a5,64(s1)
    8000345a:	2785                	addiw	a5,a5,1
    8000345c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000345e:	00014517          	auipc	a0,0x14
    80003462:	56a50513          	addi	a0,a0,1386 # 800179c8 <bcache>
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	824080e7          	jalr	-2012(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000346e:	01048513          	addi	a0,s1,16
    80003472:	00001097          	auipc	ra,0x1
    80003476:	472080e7          	jalr	1138(ra) # 800048e4 <acquiresleep>
      return b;
    8000347a:	a8b9                	j	800034d8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000347c:	0001c497          	auipc	s1,0x1c
    80003480:	7fc4b483          	ld	s1,2044(s1) # 8001fc78 <bcache+0x82b0>
    80003484:	0001c797          	auipc	a5,0x1c
    80003488:	7ac78793          	addi	a5,a5,1964 # 8001fc30 <bcache+0x8268>
    8000348c:	00f48863          	beq	s1,a5,8000349c <bread+0x90>
    80003490:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003492:	40bc                	lw	a5,64(s1)
    80003494:	cf81                	beqz	a5,800034ac <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003496:	64a4                	ld	s1,72(s1)
    80003498:	fee49de3          	bne	s1,a4,80003492 <bread+0x86>
  panic("bget: no buffers");
    8000349c:	00005517          	auipc	a0,0x5
    800034a0:	0a450513          	addi	a0,a0,164 # 80008540 <syscalls+0xe0>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	09c080e7          	jalr	156(ra) # 80000540 <panic>
      b->dev = dev;
    800034ac:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034b0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034b4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034b8:	4785                	li	a5,1
    800034ba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034bc:	00014517          	auipc	a0,0x14
    800034c0:	50c50513          	addi	a0,a0,1292 # 800179c8 <bcache>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	7c6080e7          	jalr	1990(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800034cc:	01048513          	addi	a0,s1,16
    800034d0:	00001097          	auipc	ra,0x1
    800034d4:	414080e7          	jalr	1044(ra) # 800048e4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034d8:	409c                	lw	a5,0(s1)
    800034da:	cb89                	beqz	a5,800034ec <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034dc:	8526                	mv	a0,s1
    800034de:	70a2                	ld	ra,40(sp)
    800034e0:	7402                	ld	s0,32(sp)
    800034e2:	64e2                	ld	s1,24(sp)
    800034e4:	6942                	ld	s2,16(sp)
    800034e6:	69a2                	ld	s3,8(sp)
    800034e8:	6145                	addi	sp,sp,48
    800034ea:	8082                	ret
    virtio_disk_rw(b, 0);
    800034ec:	4581                	li	a1,0
    800034ee:	8526                	mv	a0,s1
    800034f0:	00003097          	auipc	ra,0x3
    800034f4:	fe2080e7          	jalr	-30(ra) # 800064d2 <virtio_disk_rw>
    b->valid = 1;
    800034f8:	4785                	li	a5,1
    800034fa:	c09c                	sw	a5,0(s1)
  return b;
    800034fc:	b7c5                	j	800034dc <bread+0xd0>

00000000800034fe <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034fe:	1101                	addi	sp,sp,-32
    80003500:	ec06                	sd	ra,24(sp)
    80003502:	e822                	sd	s0,16(sp)
    80003504:	e426                	sd	s1,8(sp)
    80003506:	1000                	addi	s0,sp,32
    80003508:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000350a:	0541                	addi	a0,a0,16
    8000350c:	00001097          	auipc	ra,0x1
    80003510:	472080e7          	jalr	1138(ra) # 8000497e <holdingsleep>
    80003514:	cd01                	beqz	a0,8000352c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003516:	4585                	li	a1,1
    80003518:	8526                	mv	a0,s1
    8000351a:	00003097          	auipc	ra,0x3
    8000351e:	fb8080e7          	jalr	-72(ra) # 800064d2 <virtio_disk_rw>
}
    80003522:	60e2                	ld	ra,24(sp)
    80003524:	6442                	ld	s0,16(sp)
    80003526:	64a2                	ld	s1,8(sp)
    80003528:	6105                	addi	sp,sp,32
    8000352a:	8082                	ret
    panic("bwrite");
    8000352c:	00005517          	auipc	a0,0x5
    80003530:	02c50513          	addi	a0,a0,44 # 80008558 <syscalls+0xf8>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	00c080e7          	jalr	12(ra) # 80000540 <panic>

000000008000353c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000353c:	1101                	addi	sp,sp,-32
    8000353e:	ec06                	sd	ra,24(sp)
    80003540:	e822                	sd	s0,16(sp)
    80003542:	e426                	sd	s1,8(sp)
    80003544:	e04a                	sd	s2,0(sp)
    80003546:	1000                	addi	s0,sp,32
    80003548:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000354a:	01050913          	addi	s2,a0,16
    8000354e:	854a                	mv	a0,s2
    80003550:	00001097          	auipc	ra,0x1
    80003554:	42e080e7          	jalr	1070(ra) # 8000497e <holdingsleep>
    80003558:	c92d                	beqz	a0,800035ca <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000355a:	854a                	mv	a0,s2
    8000355c:	00001097          	auipc	ra,0x1
    80003560:	3de080e7          	jalr	990(ra) # 8000493a <releasesleep>

  acquire(&bcache.lock);
    80003564:	00014517          	auipc	a0,0x14
    80003568:	46450513          	addi	a0,a0,1124 # 800179c8 <bcache>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	66a080e7          	jalr	1642(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003574:	40bc                	lw	a5,64(s1)
    80003576:	37fd                	addiw	a5,a5,-1
    80003578:	0007871b          	sext.w	a4,a5
    8000357c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000357e:	eb05                	bnez	a4,800035ae <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003580:	68bc                	ld	a5,80(s1)
    80003582:	64b8                	ld	a4,72(s1)
    80003584:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003586:	64bc                	ld	a5,72(s1)
    80003588:	68b8                	ld	a4,80(s1)
    8000358a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000358c:	0001c797          	auipc	a5,0x1c
    80003590:	43c78793          	addi	a5,a5,1084 # 8001f9c8 <bcache+0x8000>
    80003594:	2b87b703          	ld	a4,696(a5)
    80003598:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000359a:	0001c717          	auipc	a4,0x1c
    8000359e:	69670713          	addi	a4,a4,1686 # 8001fc30 <bcache+0x8268>
    800035a2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035a4:	2b87b703          	ld	a4,696(a5)
    800035a8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035aa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035ae:	00014517          	auipc	a0,0x14
    800035b2:	41a50513          	addi	a0,a0,1050 # 800179c8 <bcache>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	6d4080e7          	jalr	1748(ra) # 80000c8a <release>
}
    800035be:	60e2                	ld	ra,24(sp)
    800035c0:	6442                	ld	s0,16(sp)
    800035c2:	64a2                	ld	s1,8(sp)
    800035c4:	6902                	ld	s2,0(sp)
    800035c6:	6105                	addi	sp,sp,32
    800035c8:	8082                	ret
    panic("brelse");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	f9650513          	addi	a0,a0,-106 # 80008560 <syscalls+0x100>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f6e080e7          	jalr	-146(ra) # 80000540 <panic>

00000000800035da <bpin>:

void
bpin(struct buf *b) {
    800035da:	1101                	addi	sp,sp,-32
    800035dc:	ec06                	sd	ra,24(sp)
    800035de:	e822                	sd	s0,16(sp)
    800035e0:	e426                	sd	s1,8(sp)
    800035e2:	1000                	addi	s0,sp,32
    800035e4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035e6:	00014517          	auipc	a0,0x14
    800035ea:	3e250513          	addi	a0,a0,994 # 800179c8 <bcache>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	5e8080e7          	jalr	1512(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800035f6:	40bc                	lw	a5,64(s1)
    800035f8:	2785                	addiw	a5,a5,1
    800035fa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035fc:	00014517          	auipc	a0,0x14
    80003600:	3cc50513          	addi	a0,a0,972 # 800179c8 <bcache>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	686080e7          	jalr	1670(ra) # 80000c8a <release>
}
    8000360c:	60e2                	ld	ra,24(sp)
    8000360e:	6442                	ld	s0,16(sp)
    80003610:	64a2                	ld	s1,8(sp)
    80003612:	6105                	addi	sp,sp,32
    80003614:	8082                	ret

0000000080003616 <bunpin>:

void
bunpin(struct buf *b) {
    80003616:	1101                	addi	sp,sp,-32
    80003618:	ec06                	sd	ra,24(sp)
    8000361a:	e822                	sd	s0,16(sp)
    8000361c:	e426                	sd	s1,8(sp)
    8000361e:	1000                	addi	s0,sp,32
    80003620:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003622:	00014517          	auipc	a0,0x14
    80003626:	3a650513          	addi	a0,a0,934 # 800179c8 <bcache>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	5ac080e7          	jalr	1452(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003632:	40bc                	lw	a5,64(s1)
    80003634:	37fd                	addiw	a5,a5,-1
    80003636:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003638:	00014517          	auipc	a0,0x14
    8000363c:	39050513          	addi	a0,a0,912 # 800179c8 <bcache>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	64a080e7          	jalr	1610(ra) # 80000c8a <release>
}
    80003648:	60e2                	ld	ra,24(sp)
    8000364a:	6442                	ld	s0,16(sp)
    8000364c:	64a2                	ld	s1,8(sp)
    8000364e:	6105                	addi	sp,sp,32
    80003650:	8082                	ret

0000000080003652 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003652:	1101                	addi	sp,sp,-32
    80003654:	ec06                	sd	ra,24(sp)
    80003656:	e822                	sd	s0,16(sp)
    80003658:	e426                	sd	s1,8(sp)
    8000365a:	e04a                	sd	s2,0(sp)
    8000365c:	1000                	addi	s0,sp,32
    8000365e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003660:	00d5d59b          	srliw	a1,a1,0xd
    80003664:	0001d797          	auipc	a5,0x1d
    80003668:	a407a783          	lw	a5,-1472(a5) # 800200a4 <sb+0x1c>
    8000366c:	9dbd                	addw	a1,a1,a5
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	d9e080e7          	jalr	-610(ra) # 8000340c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003676:	0074f713          	andi	a4,s1,7
    8000367a:	4785                	li	a5,1
    8000367c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003680:	14ce                	slli	s1,s1,0x33
    80003682:	90d9                	srli	s1,s1,0x36
    80003684:	00950733          	add	a4,a0,s1
    80003688:	05874703          	lbu	a4,88(a4)
    8000368c:	00e7f6b3          	and	a3,a5,a4
    80003690:	c69d                	beqz	a3,800036be <bfree+0x6c>
    80003692:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003694:	94aa                	add	s1,s1,a0
    80003696:	fff7c793          	not	a5,a5
    8000369a:	8f7d                	and	a4,a4,a5
    8000369c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800036a0:	00001097          	auipc	ra,0x1
    800036a4:	126080e7          	jalr	294(ra) # 800047c6 <log_write>
  brelse(bp);
    800036a8:	854a                	mv	a0,s2
    800036aa:	00000097          	auipc	ra,0x0
    800036ae:	e92080e7          	jalr	-366(ra) # 8000353c <brelse>
}
    800036b2:	60e2                	ld	ra,24(sp)
    800036b4:	6442                	ld	s0,16(sp)
    800036b6:	64a2                	ld	s1,8(sp)
    800036b8:	6902                	ld	s2,0(sp)
    800036ba:	6105                	addi	sp,sp,32
    800036bc:	8082                	ret
    panic("freeing free block");
    800036be:	00005517          	auipc	a0,0x5
    800036c2:	eaa50513          	addi	a0,a0,-342 # 80008568 <syscalls+0x108>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	e7a080e7          	jalr	-390(ra) # 80000540 <panic>

00000000800036ce <balloc>:
{
    800036ce:	711d                	addi	sp,sp,-96
    800036d0:	ec86                	sd	ra,88(sp)
    800036d2:	e8a2                	sd	s0,80(sp)
    800036d4:	e4a6                	sd	s1,72(sp)
    800036d6:	e0ca                	sd	s2,64(sp)
    800036d8:	fc4e                	sd	s3,56(sp)
    800036da:	f852                	sd	s4,48(sp)
    800036dc:	f456                	sd	s5,40(sp)
    800036de:	f05a                	sd	s6,32(sp)
    800036e0:	ec5e                	sd	s7,24(sp)
    800036e2:	e862                	sd	s8,16(sp)
    800036e4:	e466                	sd	s9,8(sp)
    800036e6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036e8:	0001d797          	auipc	a5,0x1d
    800036ec:	9a47a783          	lw	a5,-1628(a5) # 8002008c <sb+0x4>
    800036f0:	cff5                	beqz	a5,800037ec <balloc+0x11e>
    800036f2:	8baa                	mv	s7,a0
    800036f4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036f6:	0001db17          	auipc	s6,0x1d
    800036fa:	992b0b13          	addi	s6,s6,-1646 # 80020088 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036fe:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003700:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003702:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003704:	6c89                	lui	s9,0x2
    80003706:	a061                	j	8000378e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003708:	97ca                	add	a5,a5,s2
    8000370a:	8e55                	or	a2,a2,a3
    8000370c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	00001097          	auipc	ra,0x1
    80003716:	0b4080e7          	jalr	180(ra) # 800047c6 <log_write>
        brelse(bp);
    8000371a:	854a                	mv	a0,s2
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	e20080e7          	jalr	-480(ra) # 8000353c <brelse>
  bp = bread(dev, bno);
    80003724:	85a6                	mv	a1,s1
    80003726:	855e                	mv	a0,s7
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	ce4080e7          	jalr	-796(ra) # 8000340c <bread>
    80003730:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003732:	40000613          	li	a2,1024
    80003736:	4581                	li	a1,0
    80003738:	05850513          	addi	a0,a0,88
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	596080e7          	jalr	1430(ra) # 80000cd2 <memset>
  log_write(bp);
    80003744:	854a                	mv	a0,s2
    80003746:	00001097          	auipc	ra,0x1
    8000374a:	080080e7          	jalr	128(ra) # 800047c6 <log_write>
  brelse(bp);
    8000374e:	854a                	mv	a0,s2
    80003750:	00000097          	auipc	ra,0x0
    80003754:	dec080e7          	jalr	-532(ra) # 8000353c <brelse>
}
    80003758:	8526                	mv	a0,s1
    8000375a:	60e6                	ld	ra,88(sp)
    8000375c:	6446                	ld	s0,80(sp)
    8000375e:	64a6                	ld	s1,72(sp)
    80003760:	6906                	ld	s2,64(sp)
    80003762:	79e2                	ld	s3,56(sp)
    80003764:	7a42                	ld	s4,48(sp)
    80003766:	7aa2                	ld	s5,40(sp)
    80003768:	7b02                	ld	s6,32(sp)
    8000376a:	6be2                	ld	s7,24(sp)
    8000376c:	6c42                	ld	s8,16(sp)
    8000376e:	6ca2                	ld	s9,8(sp)
    80003770:	6125                	addi	sp,sp,96
    80003772:	8082                	ret
    brelse(bp);
    80003774:	854a                	mv	a0,s2
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	dc6080e7          	jalr	-570(ra) # 8000353c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000377e:	015c87bb          	addw	a5,s9,s5
    80003782:	00078a9b          	sext.w	s5,a5
    80003786:	004b2703          	lw	a4,4(s6)
    8000378a:	06eaf163          	bgeu	s5,a4,800037ec <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000378e:	41fad79b          	sraiw	a5,s5,0x1f
    80003792:	0137d79b          	srliw	a5,a5,0x13
    80003796:	015787bb          	addw	a5,a5,s5
    8000379a:	40d7d79b          	sraiw	a5,a5,0xd
    8000379e:	01cb2583          	lw	a1,28(s6)
    800037a2:	9dbd                	addw	a1,a1,a5
    800037a4:	855e                	mv	a0,s7
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	c66080e7          	jalr	-922(ra) # 8000340c <bread>
    800037ae:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037b0:	004b2503          	lw	a0,4(s6)
    800037b4:	000a849b          	sext.w	s1,s5
    800037b8:	8762                	mv	a4,s8
    800037ba:	faa4fde3          	bgeu	s1,a0,80003774 <balloc+0xa6>
      m = 1 << (bi % 8);
    800037be:	00777693          	andi	a3,a4,7
    800037c2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037c6:	41f7579b          	sraiw	a5,a4,0x1f
    800037ca:	01d7d79b          	srliw	a5,a5,0x1d
    800037ce:	9fb9                	addw	a5,a5,a4
    800037d0:	4037d79b          	sraiw	a5,a5,0x3
    800037d4:	00f90633          	add	a2,s2,a5
    800037d8:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800037dc:	00c6f5b3          	and	a1,a3,a2
    800037e0:	d585                	beqz	a1,80003708 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037e2:	2705                	addiw	a4,a4,1
    800037e4:	2485                	addiw	s1,s1,1
    800037e6:	fd471ae3          	bne	a4,s4,800037ba <balloc+0xec>
    800037ea:	b769                	j	80003774 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800037ec:	00005517          	auipc	a0,0x5
    800037f0:	d9450513          	addi	a0,a0,-620 # 80008580 <syscalls+0x120>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	d96080e7          	jalr	-618(ra) # 8000058a <printf>
  return 0;
    800037fc:	4481                	li	s1,0
    800037fe:	bfa9                	j	80003758 <balloc+0x8a>

0000000080003800 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003800:	7179                	addi	sp,sp,-48
    80003802:	f406                	sd	ra,40(sp)
    80003804:	f022                	sd	s0,32(sp)
    80003806:	ec26                	sd	s1,24(sp)
    80003808:	e84a                	sd	s2,16(sp)
    8000380a:	e44e                	sd	s3,8(sp)
    8000380c:	e052                	sd	s4,0(sp)
    8000380e:	1800                	addi	s0,sp,48
    80003810:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003812:	47ad                	li	a5,11
    80003814:	02b7e863          	bltu	a5,a1,80003844 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003818:	02059793          	slli	a5,a1,0x20
    8000381c:	01e7d593          	srli	a1,a5,0x1e
    80003820:	00b504b3          	add	s1,a0,a1
    80003824:	0504a903          	lw	s2,80(s1)
    80003828:	06091e63          	bnez	s2,800038a4 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000382c:	4108                	lw	a0,0(a0)
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	ea0080e7          	jalr	-352(ra) # 800036ce <balloc>
    80003836:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000383a:	06090563          	beqz	s2,800038a4 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000383e:	0524a823          	sw	s2,80(s1)
    80003842:	a08d                	j	800038a4 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003844:	ff45849b          	addiw	s1,a1,-12
    80003848:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000384c:	0ff00793          	li	a5,255
    80003850:	08e7e563          	bltu	a5,a4,800038da <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003854:	08052903          	lw	s2,128(a0)
    80003858:	00091d63          	bnez	s2,80003872 <bmap+0x72>
      addr = balloc(ip->dev);
    8000385c:	4108                	lw	a0,0(a0)
    8000385e:	00000097          	auipc	ra,0x0
    80003862:	e70080e7          	jalr	-400(ra) # 800036ce <balloc>
    80003866:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000386a:	02090d63          	beqz	s2,800038a4 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000386e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003872:	85ca                	mv	a1,s2
    80003874:	0009a503          	lw	a0,0(s3)
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	b94080e7          	jalr	-1132(ra) # 8000340c <bread>
    80003880:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003882:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003886:	02049713          	slli	a4,s1,0x20
    8000388a:	01e75593          	srli	a1,a4,0x1e
    8000388e:	00b784b3          	add	s1,a5,a1
    80003892:	0004a903          	lw	s2,0(s1)
    80003896:	02090063          	beqz	s2,800038b6 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000389a:	8552                	mv	a0,s4
    8000389c:	00000097          	auipc	ra,0x0
    800038a0:	ca0080e7          	jalr	-864(ra) # 8000353c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038a4:	854a                	mv	a0,s2
    800038a6:	70a2                	ld	ra,40(sp)
    800038a8:	7402                	ld	s0,32(sp)
    800038aa:	64e2                	ld	s1,24(sp)
    800038ac:	6942                	ld	s2,16(sp)
    800038ae:	69a2                	ld	s3,8(sp)
    800038b0:	6a02                	ld	s4,0(sp)
    800038b2:	6145                	addi	sp,sp,48
    800038b4:	8082                	ret
      addr = balloc(ip->dev);
    800038b6:	0009a503          	lw	a0,0(s3)
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	e14080e7          	jalr	-492(ra) # 800036ce <balloc>
    800038c2:	0005091b          	sext.w	s2,a0
      if(addr){
    800038c6:	fc090ae3          	beqz	s2,8000389a <bmap+0x9a>
        a[bn] = addr;
    800038ca:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800038ce:	8552                	mv	a0,s4
    800038d0:	00001097          	auipc	ra,0x1
    800038d4:	ef6080e7          	jalr	-266(ra) # 800047c6 <log_write>
    800038d8:	b7c9                	j	8000389a <bmap+0x9a>
  panic("bmap: out of range");
    800038da:	00005517          	auipc	a0,0x5
    800038de:	cbe50513          	addi	a0,a0,-834 # 80008598 <syscalls+0x138>
    800038e2:	ffffd097          	auipc	ra,0xffffd
    800038e6:	c5e080e7          	jalr	-930(ra) # 80000540 <panic>

00000000800038ea <iget>:
{
    800038ea:	7179                	addi	sp,sp,-48
    800038ec:	f406                	sd	ra,40(sp)
    800038ee:	f022                	sd	s0,32(sp)
    800038f0:	ec26                	sd	s1,24(sp)
    800038f2:	e84a                	sd	s2,16(sp)
    800038f4:	e44e                	sd	s3,8(sp)
    800038f6:	e052                	sd	s4,0(sp)
    800038f8:	1800                	addi	s0,sp,48
    800038fa:	89aa                	mv	s3,a0
    800038fc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038fe:	0001c517          	auipc	a0,0x1c
    80003902:	7aa50513          	addi	a0,a0,1962 # 800200a8 <itable>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	2d0080e7          	jalr	720(ra) # 80000bd6 <acquire>
  empty = 0;
    8000390e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003910:	0001c497          	auipc	s1,0x1c
    80003914:	7b048493          	addi	s1,s1,1968 # 800200c0 <itable+0x18>
    80003918:	0001e697          	auipc	a3,0x1e
    8000391c:	23868693          	addi	a3,a3,568 # 80021b50 <log>
    80003920:	a039                	j	8000392e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003922:	02090b63          	beqz	s2,80003958 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003926:	08848493          	addi	s1,s1,136
    8000392a:	02d48a63          	beq	s1,a3,8000395e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000392e:	449c                	lw	a5,8(s1)
    80003930:	fef059e3          	blez	a5,80003922 <iget+0x38>
    80003934:	4098                	lw	a4,0(s1)
    80003936:	ff3716e3          	bne	a4,s3,80003922 <iget+0x38>
    8000393a:	40d8                	lw	a4,4(s1)
    8000393c:	ff4713e3          	bne	a4,s4,80003922 <iget+0x38>
      ip->ref++;
    80003940:	2785                	addiw	a5,a5,1
    80003942:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003944:	0001c517          	auipc	a0,0x1c
    80003948:	76450513          	addi	a0,a0,1892 # 800200a8 <itable>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	33e080e7          	jalr	830(ra) # 80000c8a <release>
      return ip;
    80003954:	8926                	mv	s2,s1
    80003956:	a03d                	j	80003984 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003958:	f7f9                	bnez	a5,80003926 <iget+0x3c>
    8000395a:	8926                	mv	s2,s1
    8000395c:	b7e9                	j	80003926 <iget+0x3c>
  if(empty == 0)
    8000395e:	02090c63          	beqz	s2,80003996 <iget+0xac>
  ip->dev = dev;
    80003962:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003966:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000396a:	4785                	li	a5,1
    8000396c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003970:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003974:	0001c517          	auipc	a0,0x1c
    80003978:	73450513          	addi	a0,a0,1844 # 800200a8 <itable>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	30e080e7          	jalr	782(ra) # 80000c8a <release>
}
    80003984:	854a                	mv	a0,s2
    80003986:	70a2                	ld	ra,40(sp)
    80003988:	7402                	ld	s0,32(sp)
    8000398a:	64e2                	ld	s1,24(sp)
    8000398c:	6942                	ld	s2,16(sp)
    8000398e:	69a2                	ld	s3,8(sp)
    80003990:	6a02                	ld	s4,0(sp)
    80003992:	6145                	addi	sp,sp,48
    80003994:	8082                	ret
    panic("iget: no inodes");
    80003996:	00005517          	auipc	a0,0x5
    8000399a:	c1a50513          	addi	a0,a0,-998 # 800085b0 <syscalls+0x150>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	ba2080e7          	jalr	-1118(ra) # 80000540 <panic>

00000000800039a6 <fsinit>:
fsinit(int dev) {
    800039a6:	7179                	addi	sp,sp,-48
    800039a8:	f406                	sd	ra,40(sp)
    800039aa:	f022                	sd	s0,32(sp)
    800039ac:	ec26                	sd	s1,24(sp)
    800039ae:	e84a                	sd	s2,16(sp)
    800039b0:	e44e                	sd	s3,8(sp)
    800039b2:	1800                	addi	s0,sp,48
    800039b4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039b6:	4585                	li	a1,1
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	a54080e7          	jalr	-1452(ra) # 8000340c <bread>
    800039c0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039c2:	0001c997          	auipc	s3,0x1c
    800039c6:	6c698993          	addi	s3,s3,1734 # 80020088 <sb>
    800039ca:	02000613          	li	a2,32
    800039ce:	05850593          	addi	a1,a0,88
    800039d2:	854e                	mv	a0,s3
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	35a080e7          	jalr	858(ra) # 80000d2e <memmove>
  brelse(bp);
    800039dc:	8526                	mv	a0,s1
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	b5e080e7          	jalr	-1186(ra) # 8000353c <brelse>
  if(sb.magic != FSMAGIC)
    800039e6:	0009a703          	lw	a4,0(s3)
    800039ea:	102037b7          	lui	a5,0x10203
    800039ee:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039f2:	02f71263          	bne	a4,a5,80003a16 <fsinit+0x70>
  initlog(dev, &sb);
    800039f6:	0001c597          	auipc	a1,0x1c
    800039fa:	69258593          	addi	a1,a1,1682 # 80020088 <sb>
    800039fe:	854a                	mv	a0,s2
    80003a00:	00001097          	auipc	ra,0x1
    80003a04:	b4a080e7          	jalr	-1206(ra) # 8000454a <initlog>
}
    80003a08:	70a2                	ld	ra,40(sp)
    80003a0a:	7402                	ld	s0,32(sp)
    80003a0c:	64e2                	ld	s1,24(sp)
    80003a0e:	6942                	ld	s2,16(sp)
    80003a10:	69a2                	ld	s3,8(sp)
    80003a12:	6145                	addi	sp,sp,48
    80003a14:	8082                	ret
    panic("invalid file system");
    80003a16:	00005517          	auipc	a0,0x5
    80003a1a:	baa50513          	addi	a0,a0,-1110 # 800085c0 <syscalls+0x160>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	b22080e7          	jalr	-1246(ra) # 80000540 <panic>

0000000080003a26 <iinit>:
{
    80003a26:	7179                	addi	sp,sp,-48
    80003a28:	f406                	sd	ra,40(sp)
    80003a2a:	f022                	sd	s0,32(sp)
    80003a2c:	ec26                	sd	s1,24(sp)
    80003a2e:	e84a                	sd	s2,16(sp)
    80003a30:	e44e                	sd	s3,8(sp)
    80003a32:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a34:	00005597          	auipc	a1,0x5
    80003a38:	ba458593          	addi	a1,a1,-1116 # 800085d8 <syscalls+0x178>
    80003a3c:	0001c517          	auipc	a0,0x1c
    80003a40:	66c50513          	addi	a0,a0,1644 # 800200a8 <itable>
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	102080e7          	jalr	258(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a4c:	0001c497          	auipc	s1,0x1c
    80003a50:	68448493          	addi	s1,s1,1668 # 800200d0 <itable+0x28>
    80003a54:	0001e997          	auipc	s3,0x1e
    80003a58:	10c98993          	addi	s3,s3,268 # 80021b60 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a5c:	00005917          	auipc	s2,0x5
    80003a60:	b8490913          	addi	s2,s2,-1148 # 800085e0 <syscalls+0x180>
    80003a64:	85ca                	mv	a1,s2
    80003a66:	8526                	mv	a0,s1
    80003a68:	00001097          	auipc	ra,0x1
    80003a6c:	e42080e7          	jalr	-446(ra) # 800048aa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a70:	08848493          	addi	s1,s1,136
    80003a74:	ff3498e3          	bne	s1,s3,80003a64 <iinit+0x3e>
}
    80003a78:	70a2                	ld	ra,40(sp)
    80003a7a:	7402                	ld	s0,32(sp)
    80003a7c:	64e2                	ld	s1,24(sp)
    80003a7e:	6942                	ld	s2,16(sp)
    80003a80:	69a2                	ld	s3,8(sp)
    80003a82:	6145                	addi	sp,sp,48
    80003a84:	8082                	ret

0000000080003a86 <ialloc>:
{
    80003a86:	715d                	addi	sp,sp,-80
    80003a88:	e486                	sd	ra,72(sp)
    80003a8a:	e0a2                	sd	s0,64(sp)
    80003a8c:	fc26                	sd	s1,56(sp)
    80003a8e:	f84a                	sd	s2,48(sp)
    80003a90:	f44e                	sd	s3,40(sp)
    80003a92:	f052                	sd	s4,32(sp)
    80003a94:	ec56                	sd	s5,24(sp)
    80003a96:	e85a                	sd	s6,16(sp)
    80003a98:	e45e                	sd	s7,8(sp)
    80003a9a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a9c:	0001c717          	auipc	a4,0x1c
    80003aa0:	5f872703          	lw	a4,1528(a4) # 80020094 <sb+0xc>
    80003aa4:	4785                	li	a5,1
    80003aa6:	04e7fa63          	bgeu	a5,a4,80003afa <ialloc+0x74>
    80003aaa:	8aaa                	mv	s5,a0
    80003aac:	8bae                	mv	s7,a1
    80003aae:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ab0:	0001ca17          	auipc	s4,0x1c
    80003ab4:	5d8a0a13          	addi	s4,s4,1496 # 80020088 <sb>
    80003ab8:	00048b1b          	sext.w	s6,s1
    80003abc:	0044d593          	srli	a1,s1,0x4
    80003ac0:	018a2783          	lw	a5,24(s4)
    80003ac4:	9dbd                	addw	a1,a1,a5
    80003ac6:	8556                	mv	a0,s5
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	944080e7          	jalr	-1724(ra) # 8000340c <bread>
    80003ad0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ad2:	05850993          	addi	s3,a0,88
    80003ad6:	00f4f793          	andi	a5,s1,15
    80003ada:	079a                	slli	a5,a5,0x6
    80003adc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ade:	00099783          	lh	a5,0(s3)
    80003ae2:	c3a1                	beqz	a5,80003b22 <ialloc+0x9c>
    brelse(bp);
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	a58080e7          	jalr	-1448(ra) # 8000353c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003aec:	0485                	addi	s1,s1,1
    80003aee:	00ca2703          	lw	a4,12(s4)
    80003af2:	0004879b          	sext.w	a5,s1
    80003af6:	fce7e1e3          	bltu	a5,a4,80003ab8 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003afa:	00005517          	auipc	a0,0x5
    80003afe:	aee50513          	addi	a0,a0,-1298 # 800085e8 <syscalls+0x188>
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	a88080e7          	jalr	-1400(ra) # 8000058a <printf>
  return 0;
    80003b0a:	4501                	li	a0,0
}
    80003b0c:	60a6                	ld	ra,72(sp)
    80003b0e:	6406                	ld	s0,64(sp)
    80003b10:	74e2                	ld	s1,56(sp)
    80003b12:	7942                	ld	s2,48(sp)
    80003b14:	79a2                	ld	s3,40(sp)
    80003b16:	7a02                	ld	s4,32(sp)
    80003b18:	6ae2                	ld	s5,24(sp)
    80003b1a:	6b42                	ld	s6,16(sp)
    80003b1c:	6ba2                	ld	s7,8(sp)
    80003b1e:	6161                	addi	sp,sp,80
    80003b20:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b22:	04000613          	li	a2,64
    80003b26:	4581                	li	a1,0
    80003b28:	854e                	mv	a0,s3
    80003b2a:	ffffd097          	auipc	ra,0xffffd
    80003b2e:	1a8080e7          	jalr	424(ra) # 80000cd2 <memset>
      dip->type = type;
    80003b32:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b36:	854a                	mv	a0,s2
    80003b38:	00001097          	auipc	ra,0x1
    80003b3c:	c8e080e7          	jalr	-882(ra) # 800047c6 <log_write>
      brelse(bp);
    80003b40:	854a                	mv	a0,s2
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	9fa080e7          	jalr	-1542(ra) # 8000353c <brelse>
      return iget(dev, inum);
    80003b4a:	85da                	mv	a1,s6
    80003b4c:	8556                	mv	a0,s5
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	d9c080e7          	jalr	-612(ra) # 800038ea <iget>
    80003b56:	bf5d                	j	80003b0c <ialloc+0x86>

0000000080003b58 <iupdate>:
{
    80003b58:	1101                	addi	sp,sp,-32
    80003b5a:	ec06                	sd	ra,24(sp)
    80003b5c:	e822                	sd	s0,16(sp)
    80003b5e:	e426                	sd	s1,8(sp)
    80003b60:	e04a                	sd	s2,0(sp)
    80003b62:	1000                	addi	s0,sp,32
    80003b64:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b66:	415c                	lw	a5,4(a0)
    80003b68:	0047d79b          	srliw	a5,a5,0x4
    80003b6c:	0001c597          	auipc	a1,0x1c
    80003b70:	5345a583          	lw	a1,1332(a1) # 800200a0 <sb+0x18>
    80003b74:	9dbd                	addw	a1,a1,a5
    80003b76:	4108                	lw	a0,0(a0)
    80003b78:	00000097          	auipc	ra,0x0
    80003b7c:	894080e7          	jalr	-1900(ra) # 8000340c <bread>
    80003b80:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b82:	05850793          	addi	a5,a0,88
    80003b86:	40d8                	lw	a4,4(s1)
    80003b88:	8b3d                	andi	a4,a4,15
    80003b8a:	071a                	slli	a4,a4,0x6
    80003b8c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b8e:	04449703          	lh	a4,68(s1)
    80003b92:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b96:	04649703          	lh	a4,70(s1)
    80003b9a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b9e:	04849703          	lh	a4,72(s1)
    80003ba2:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003ba6:	04a49703          	lh	a4,74(s1)
    80003baa:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003bae:	44f8                	lw	a4,76(s1)
    80003bb0:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bb2:	03400613          	li	a2,52
    80003bb6:	05048593          	addi	a1,s1,80
    80003bba:	00c78513          	addi	a0,a5,12
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	170080e7          	jalr	368(ra) # 80000d2e <memmove>
  log_write(bp);
    80003bc6:	854a                	mv	a0,s2
    80003bc8:	00001097          	auipc	ra,0x1
    80003bcc:	bfe080e7          	jalr	-1026(ra) # 800047c6 <log_write>
  brelse(bp);
    80003bd0:	854a                	mv	a0,s2
    80003bd2:	00000097          	auipc	ra,0x0
    80003bd6:	96a080e7          	jalr	-1686(ra) # 8000353c <brelse>
}
    80003bda:	60e2                	ld	ra,24(sp)
    80003bdc:	6442                	ld	s0,16(sp)
    80003bde:	64a2                	ld	s1,8(sp)
    80003be0:	6902                	ld	s2,0(sp)
    80003be2:	6105                	addi	sp,sp,32
    80003be4:	8082                	ret

0000000080003be6 <idup>:
{
    80003be6:	1101                	addi	sp,sp,-32
    80003be8:	ec06                	sd	ra,24(sp)
    80003bea:	e822                	sd	s0,16(sp)
    80003bec:	e426                	sd	s1,8(sp)
    80003bee:	1000                	addi	s0,sp,32
    80003bf0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bf2:	0001c517          	auipc	a0,0x1c
    80003bf6:	4b650513          	addi	a0,a0,1206 # 800200a8 <itable>
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	fdc080e7          	jalr	-36(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003c02:	449c                	lw	a5,8(s1)
    80003c04:	2785                	addiw	a5,a5,1
    80003c06:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c08:	0001c517          	auipc	a0,0x1c
    80003c0c:	4a050513          	addi	a0,a0,1184 # 800200a8 <itable>
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	07a080e7          	jalr	122(ra) # 80000c8a <release>
}
    80003c18:	8526                	mv	a0,s1
    80003c1a:	60e2                	ld	ra,24(sp)
    80003c1c:	6442                	ld	s0,16(sp)
    80003c1e:	64a2                	ld	s1,8(sp)
    80003c20:	6105                	addi	sp,sp,32
    80003c22:	8082                	ret

0000000080003c24 <ilock>:
{
    80003c24:	1101                	addi	sp,sp,-32
    80003c26:	ec06                	sd	ra,24(sp)
    80003c28:	e822                	sd	s0,16(sp)
    80003c2a:	e426                	sd	s1,8(sp)
    80003c2c:	e04a                	sd	s2,0(sp)
    80003c2e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c30:	c115                	beqz	a0,80003c54 <ilock+0x30>
    80003c32:	84aa                	mv	s1,a0
    80003c34:	451c                	lw	a5,8(a0)
    80003c36:	00f05f63          	blez	a5,80003c54 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c3a:	0541                	addi	a0,a0,16
    80003c3c:	00001097          	auipc	ra,0x1
    80003c40:	ca8080e7          	jalr	-856(ra) # 800048e4 <acquiresleep>
  if(ip->valid == 0){
    80003c44:	40bc                	lw	a5,64(s1)
    80003c46:	cf99                	beqz	a5,80003c64 <ilock+0x40>
}
    80003c48:	60e2                	ld	ra,24(sp)
    80003c4a:	6442                	ld	s0,16(sp)
    80003c4c:	64a2                	ld	s1,8(sp)
    80003c4e:	6902                	ld	s2,0(sp)
    80003c50:	6105                	addi	sp,sp,32
    80003c52:	8082                	ret
    panic("ilock");
    80003c54:	00005517          	auipc	a0,0x5
    80003c58:	9ac50513          	addi	a0,a0,-1620 # 80008600 <syscalls+0x1a0>
    80003c5c:	ffffd097          	auipc	ra,0xffffd
    80003c60:	8e4080e7          	jalr	-1820(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c64:	40dc                	lw	a5,4(s1)
    80003c66:	0047d79b          	srliw	a5,a5,0x4
    80003c6a:	0001c597          	auipc	a1,0x1c
    80003c6e:	4365a583          	lw	a1,1078(a1) # 800200a0 <sb+0x18>
    80003c72:	9dbd                	addw	a1,a1,a5
    80003c74:	4088                	lw	a0,0(s1)
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	796080e7          	jalr	1942(ra) # 8000340c <bread>
    80003c7e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c80:	05850593          	addi	a1,a0,88
    80003c84:	40dc                	lw	a5,4(s1)
    80003c86:	8bbd                	andi	a5,a5,15
    80003c88:	079a                	slli	a5,a5,0x6
    80003c8a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c8c:	00059783          	lh	a5,0(a1)
    80003c90:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c94:	00259783          	lh	a5,2(a1)
    80003c98:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c9c:	00459783          	lh	a5,4(a1)
    80003ca0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ca4:	00659783          	lh	a5,6(a1)
    80003ca8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cac:	459c                	lw	a5,8(a1)
    80003cae:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cb0:	03400613          	li	a2,52
    80003cb4:	05b1                	addi	a1,a1,12
    80003cb6:	05048513          	addi	a0,s1,80
    80003cba:	ffffd097          	auipc	ra,0xffffd
    80003cbe:	074080e7          	jalr	116(ra) # 80000d2e <memmove>
    brelse(bp);
    80003cc2:	854a                	mv	a0,s2
    80003cc4:	00000097          	auipc	ra,0x0
    80003cc8:	878080e7          	jalr	-1928(ra) # 8000353c <brelse>
    ip->valid = 1;
    80003ccc:	4785                	li	a5,1
    80003cce:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cd0:	04449783          	lh	a5,68(s1)
    80003cd4:	fbb5                	bnez	a5,80003c48 <ilock+0x24>
      panic("ilock: no type");
    80003cd6:	00005517          	auipc	a0,0x5
    80003cda:	93250513          	addi	a0,a0,-1742 # 80008608 <syscalls+0x1a8>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	862080e7          	jalr	-1950(ra) # 80000540 <panic>

0000000080003ce6 <iunlock>:
{
    80003ce6:	1101                	addi	sp,sp,-32
    80003ce8:	ec06                	sd	ra,24(sp)
    80003cea:	e822                	sd	s0,16(sp)
    80003cec:	e426                	sd	s1,8(sp)
    80003cee:	e04a                	sd	s2,0(sp)
    80003cf0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cf2:	c905                	beqz	a0,80003d22 <iunlock+0x3c>
    80003cf4:	84aa                	mv	s1,a0
    80003cf6:	01050913          	addi	s2,a0,16
    80003cfa:	854a                	mv	a0,s2
    80003cfc:	00001097          	auipc	ra,0x1
    80003d00:	c82080e7          	jalr	-894(ra) # 8000497e <holdingsleep>
    80003d04:	cd19                	beqz	a0,80003d22 <iunlock+0x3c>
    80003d06:	449c                	lw	a5,8(s1)
    80003d08:	00f05d63          	blez	a5,80003d22 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d0c:	854a                	mv	a0,s2
    80003d0e:	00001097          	auipc	ra,0x1
    80003d12:	c2c080e7          	jalr	-980(ra) # 8000493a <releasesleep>
}
    80003d16:	60e2                	ld	ra,24(sp)
    80003d18:	6442                	ld	s0,16(sp)
    80003d1a:	64a2                	ld	s1,8(sp)
    80003d1c:	6902                	ld	s2,0(sp)
    80003d1e:	6105                	addi	sp,sp,32
    80003d20:	8082                	ret
    panic("iunlock");
    80003d22:	00005517          	auipc	a0,0x5
    80003d26:	8f650513          	addi	a0,a0,-1802 # 80008618 <syscalls+0x1b8>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	816080e7          	jalr	-2026(ra) # 80000540 <panic>

0000000080003d32 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d32:	7179                	addi	sp,sp,-48
    80003d34:	f406                	sd	ra,40(sp)
    80003d36:	f022                	sd	s0,32(sp)
    80003d38:	ec26                	sd	s1,24(sp)
    80003d3a:	e84a                	sd	s2,16(sp)
    80003d3c:	e44e                	sd	s3,8(sp)
    80003d3e:	e052                	sd	s4,0(sp)
    80003d40:	1800                	addi	s0,sp,48
    80003d42:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d44:	05050493          	addi	s1,a0,80
    80003d48:	08050913          	addi	s2,a0,128
    80003d4c:	a021                	j	80003d54 <itrunc+0x22>
    80003d4e:	0491                	addi	s1,s1,4
    80003d50:	01248d63          	beq	s1,s2,80003d6a <itrunc+0x38>
    if(ip->addrs[i]){
    80003d54:	408c                	lw	a1,0(s1)
    80003d56:	dde5                	beqz	a1,80003d4e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d58:	0009a503          	lw	a0,0(s3)
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	8f6080e7          	jalr	-1802(ra) # 80003652 <bfree>
      ip->addrs[i] = 0;
    80003d64:	0004a023          	sw	zero,0(s1)
    80003d68:	b7dd                	j	80003d4e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d6a:	0809a583          	lw	a1,128(s3)
    80003d6e:	e185                	bnez	a1,80003d8e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d70:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d74:	854e                	mv	a0,s3
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	de2080e7          	jalr	-542(ra) # 80003b58 <iupdate>
}
    80003d7e:	70a2                	ld	ra,40(sp)
    80003d80:	7402                	ld	s0,32(sp)
    80003d82:	64e2                	ld	s1,24(sp)
    80003d84:	6942                	ld	s2,16(sp)
    80003d86:	69a2                	ld	s3,8(sp)
    80003d88:	6a02                	ld	s4,0(sp)
    80003d8a:	6145                	addi	sp,sp,48
    80003d8c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d8e:	0009a503          	lw	a0,0(s3)
    80003d92:	fffff097          	auipc	ra,0xfffff
    80003d96:	67a080e7          	jalr	1658(ra) # 8000340c <bread>
    80003d9a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d9c:	05850493          	addi	s1,a0,88
    80003da0:	45850913          	addi	s2,a0,1112
    80003da4:	a021                	j	80003dac <itrunc+0x7a>
    80003da6:	0491                	addi	s1,s1,4
    80003da8:	01248b63          	beq	s1,s2,80003dbe <itrunc+0x8c>
      if(a[j])
    80003dac:	408c                	lw	a1,0(s1)
    80003dae:	dde5                	beqz	a1,80003da6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003db0:	0009a503          	lw	a0,0(s3)
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	89e080e7          	jalr	-1890(ra) # 80003652 <bfree>
    80003dbc:	b7ed                	j	80003da6 <itrunc+0x74>
    brelse(bp);
    80003dbe:	8552                	mv	a0,s4
    80003dc0:	fffff097          	auipc	ra,0xfffff
    80003dc4:	77c080e7          	jalr	1916(ra) # 8000353c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dc8:	0809a583          	lw	a1,128(s3)
    80003dcc:	0009a503          	lw	a0,0(s3)
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	882080e7          	jalr	-1918(ra) # 80003652 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003dd8:	0809a023          	sw	zero,128(s3)
    80003ddc:	bf51                	j	80003d70 <itrunc+0x3e>

0000000080003dde <iput>:
{
    80003dde:	1101                	addi	sp,sp,-32
    80003de0:	ec06                	sd	ra,24(sp)
    80003de2:	e822                	sd	s0,16(sp)
    80003de4:	e426                	sd	s1,8(sp)
    80003de6:	e04a                	sd	s2,0(sp)
    80003de8:	1000                	addi	s0,sp,32
    80003dea:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dec:	0001c517          	auipc	a0,0x1c
    80003df0:	2bc50513          	addi	a0,a0,700 # 800200a8 <itable>
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	de2080e7          	jalr	-542(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dfc:	4498                	lw	a4,8(s1)
    80003dfe:	4785                	li	a5,1
    80003e00:	02f70363          	beq	a4,a5,80003e26 <iput+0x48>
  ip->ref--;
    80003e04:	449c                	lw	a5,8(s1)
    80003e06:	37fd                	addiw	a5,a5,-1
    80003e08:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e0a:	0001c517          	auipc	a0,0x1c
    80003e0e:	29e50513          	addi	a0,a0,670 # 800200a8 <itable>
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	e78080e7          	jalr	-392(ra) # 80000c8a <release>
}
    80003e1a:	60e2                	ld	ra,24(sp)
    80003e1c:	6442                	ld	s0,16(sp)
    80003e1e:	64a2                	ld	s1,8(sp)
    80003e20:	6902                	ld	s2,0(sp)
    80003e22:	6105                	addi	sp,sp,32
    80003e24:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e26:	40bc                	lw	a5,64(s1)
    80003e28:	dff1                	beqz	a5,80003e04 <iput+0x26>
    80003e2a:	04a49783          	lh	a5,74(s1)
    80003e2e:	fbf9                	bnez	a5,80003e04 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e30:	01048913          	addi	s2,s1,16
    80003e34:	854a                	mv	a0,s2
    80003e36:	00001097          	auipc	ra,0x1
    80003e3a:	aae080e7          	jalr	-1362(ra) # 800048e4 <acquiresleep>
    release(&itable.lock);
    80003e3e:	0001c517          	auipc	a0,0x1c
    80003e42:	26a50513          	addi	a0,a0,618 # 800200a8 <itable>
    80003e46:	ffffd097          	auipc	ra,0xffffd
    80003e4a:	e44080e7          	jalr	-444(ra) # 80000c8a <release>
    itrunc(ip);
    80003e4e:	8526                	mv	a0,s1
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	ee2080e7          	jalr	-286(ra) # 80003d32 <itrunc>
    ip->type = 0;
    80003e58:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e5c:	8526                	mv	a0,s1
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	cfa080e7          	jalr	-774(ra) # 80003b58 <iupdate>
    ip->valid = 0;
    80003e66:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	00001097          	auipc	ra,0x1
    80003e70:	ace080e7          	jalr	-1330(ra) # 8000493a <releasesleep>
    acquire(&itable.lock);
    80003e74:	0001c517          	auipc	a0,0x1c
    80003e78:	23450513          	addi	a0,a0,564 # 800200a8 <itable>
    80003e7c:	ffffd097          	auipc	ra,0xffffd
    80003e80:	d5a080e7          	jalr	-678(ra) # 80000bd6 <acquire>
    80003e84:	b741                	j	80003e04 <iput+0x26>

0000000080003e86 <iunlockput>:
{
    80003e86:	1101                	addi	sp,sp,-32
    80003e88:	ec06                	sd	ra,24(sp)
    80003e8a:	e822                	sd	s0,16(sp)
    80003e8c:	e426                	sd	s1,8(sp)
    80003e8e:	1000                	addi	s0,sp,32
    80003e90:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	e54080e7          	jalr	-428(ra) # 80003ce6 <iunlock>
  iput(ip);
    80003e9a:	8526                	mv	a0,s1
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	f42080e7          	jalr	-190(ra) # 80003dde <iput>
}
    80003ea4:	60e2                	ld	ra,24(sp)
    80003ea6:	6442                	ld	s0,16(sp)
    80003ea8:	64a2                	ld	s1,8(sp)
    80003eaa:	6105                	addi	sp,sp,32
    80003eac:	8082                	ret

0000000080003eae <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003eae:	1141                	addi	sp,sp,-16
    80003eb0:	e422                	sd	s0,8(sp)
    80003eb2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003eb4:	411c                	lw	a5,0(a0)
    80003eb6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003eb8:	415c                	lw	a5,4(a0)
    80003eba:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ebc:	04451783          	lh	a5,68(a0)
    80003ec0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ec4:	04a51783          	lh	a5,74(a0)
    80003ec8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ecc:	04c56783          	lwu	a5,76(a0)
    80003ed0:	e99c                	sd	a5,16(a1)
}
    80003ed2:	6422                	ld	s0,8(sp)
    80003ed4:	0141                	addi	sp,sp,16
    80003ed6:	8082                	ret

0000000080003ed8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ed8:	457c                	lw	a5,76(a0)
    80003eda:	0ed7e963          	bltu	a5,a3,80003fcc <readi+0xf4>
{
    80003ede:	7159                	addi	sp,sp,-112
    80003ee0:	f486                	sd	ra,104(sp)
    80003ee2:	f0a2                	sd	s0,96(sp)
    80003ee4:	eca6                	sd	s1,88(sp)
    80003ee6:	e8ca                	sd	s2,80(sp)
    80003ee8:	e4ce                	sd	s3,72(sp)
    80003eea:	e0d2                	sd	s4,64(sp)
    80003eec:	fc56                	sd	s5,56(sp)
    80003eee:	f85a                	sd	s6,48(sp)
    80003ef0:	f45e                	sd	s7,40(sp)
    80003ef2:	f062                	sd	s8,32(sp)
    80003ef4:	ec66                	sd	s9,24(sp)
    80003ef6:	e86a                	sd	s10,16(sp)
    80003ef8:	e46e                	sd	s11,8(sp)
    80003efa:	1880                	addi	s0,sp,112
    80003efc:	8b2a                	mv	s6,a0
    80003efe:	8bae                	mv	s7,a1
    80003f00:	8a32                	mv	s4,a2
    80003f02:	84b6                	mv	s1,a3
    80003f04:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f06:	9f35                	addw	a4,a4,a3
    return 0;
    80003f08:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f0a:	0ad76063          	bltu	a4,a3,80003faa <readi+0xd2>
  if(off + n > ip->size)
    80003f0e:	00e7f463          	bgeu	a5,a4,80003f16 <readi+0x3e>
    n = ip->size - off;
    80003f12:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f16:	0a0a8963          	beqz	s5,80003fc8 <readi+0xf0>
    80003f1a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f1c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f20:	5c7d                	li	s8,-1
    80003f22:	a82d                	j	80003f5c <readi+0x84>
    80003f24:	020d1d93          	slli	s11,s10,0x20
    80003f28:	020ddd93          	srli	s11,s11,0x20
    80003f2c:	05890613          	addi	a2,s2,88
    80003f30:	86ee                	mv	a3,s11
    80003f32:	963a                	add	a2,a2,a4
    80003f34:	85d2                	mv	a1,s4
    80003f36:	855e                	mv	a0,s7
    80003f38:	ffffe097          	auipc	ra,0xffffe
    80003f3c:	6ba080e7          	jalr	1722(ra) # 800025f2 <either_copyout>
    80003f40:	05850d63          	beq	a0,s8,80003f9a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f44:	854a                	mv	a0,s2
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	5f6080e7          	jalr	1526(ra) # 8000353c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f4e:	013d09bb          	addw	s3,s10,s3
    80003f52:	009d04bb          	addw	s1,s10,s1
    80003f56:	9a6e                	add	s4,s4,s11
    80003f58:	0559f763          	bgeu	s3,s5,80003fa6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f5c:	00a4d59b          	srliw	a1,s1,0xa
    80003f60:	855a                	mv	a0,s6
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	89e080e7          	jalr	-1890(ra) # 80003800 <bmap>
    80003f6a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f6e:	cd85                	beqz	a1,80003fa6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f70:	000b2503          	lw	a0,0(s6)
    80003f74:	fffff097          	auipc	ra,0xfffff
    80003f78:	498080e7          	jalr	1176(ra) # 8000340c <bread>
    80003f7c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f7e:	3ff4f713          	andi	a4,s1,1023
    80003f82:	40ec87bb          	subw	a5,s9,a4
    80003f86:	413a86bb          	subw	a3,s5,s3
    80003f8a:	8d3e                	mv	s10,a5
    80003f8c:	2781                	sext.w	a5,a5
    80003f8e:	0006861b          	sext.w	a2,a3
    80003f92:	f8f679e3          	bgeu	a2,a5,80003f24 <readi+0x4c>
    80003f96:	8d36                	mv	s10,a3
    80003f98:	b771                	j	80003f24 <readi+0x4c>
      brelse(bp);
    80003f9a:	854a                	mv	a0,s2
    80003f9c:	fffff097          	auipc	ra,0xfffff
    80003fa0:	5a0080e7          	jalr	1440(ra) # 8000353c <brelse>
      tot = -1;
    80003fa4:	59fd                	li	s3,-1
  }
  return tot;
    80003fa6:	0009851b          	sext.w	a0,s3
}
    80003faa:	70a6                	ld	ra,104(sp)
    80003fac:	7406                	ld	s0,96(sp)
    80003fae:	64e6                	ld	s1,88(sp)
    80003fb0:	6946                	ld	s2,80(sp)
    80003fb2:	69a6                	ld	s3,72(sp)
    80003fb4:	6a06                	ld	s4,64(sp)
    80003fb6:	7ae2                	ld	s5,56(sp)
    80003fb8:	7b42                	ld	s6,48(sp)
    80003fba:	7ba2                	ld	s7,40(sp)
    80003fbc:	7c02                	ld	s8,32(sp)
    80003fbe:	6ce2                	ld	s9,24(sp)
    80003fc0:	6d42                	ld	s10,16(sp)
    80003fc2:	6da2                	ld	s11,8(sp)
    80003fc4:	6165                	addi	sp,sp,112
    80003fc6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fc8:	89d6                	mv	s3,s5
    80003fca:	bff1                	j	80003fa6 <readi+0xce>
    return 0;
    80003fcc:	4501                	li	a0,0
}
    80003fce:	8082                	ret

0000000080003fd0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fd0:	457c                	lw	a5,76(a0)
    80003fd2:	10d7e863          	bltu	a5,a3,800040e2 <writei+0x112>
{
    80003fd6:	7159                	addi	sp,sp,-112
    80003fd8:	f486                	sd	ra,104(sp)
    80003fda:	f0a2                	sd	s0,96(sp)
    80003fdc:	eca6                	sd	s1,88(sp)
    80003fde:	e8ca                	sd	s2,80(sp)
    80003fe0:	e4ce                	sd	s3,72(sp)
    80003fe2:	e0d2                	sd	s4,64(sp)
    80003fe4:	fc56                	sd	s5,56(sp)
    80003fe6:	f85a                	sd	s6,48(sp)
    80003fe8:	f45e                	sd	s7,40(sp)
    80003fea:	f062                	sd	s8,32(sp)
    80003fec:	ec66                	sd	s9,24(sp)
    80003fee:	e86a                	sd	s10,16(sp)
    80003ff0:	e46e                	sd	s11,8(sp)
    80003ff2:	1880                	addi	s0,sp,112
    80003ff4:	8aaa                	mv	s5,a0
    80003ff6:	8bae                	mv	s7,a1
    80003ff8:	8a32                	mv	s4,a2
    80003ffa:	8936                	mv	s2,a3
    80003ffc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ffe:	00e687bb          	addw	a5,a3,a4
    80004002:	0ed7e263          	bltu	a5,a3,800040e6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004006:	00043737          	lui	a4,0x43
    8000400a:	0ef76063          	bltu	a4,a5,800040ea <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000400e:	0c0b0863          	beqz	s6,800040de <writei+0x10e>
    80004012:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004014:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004018:	5c7d                	li	s8,-1
    8000401a:	a091                	j	8000405e <writei+0x8e>
    8000401c:	020d1d93          	slli	s11,s10,0x20
    80004020:	020ddd93          	srli	s11,s11,0x20
    80004024:	05848513          	addi	a0,s1,88
    80004028:	86ee                	mv	a3,s11
    8000402a:	8652                	mv	a2,s4
    8000402c:	85de                	mv	a1,s7
    8000402e:	953a                	add	a0,a0,a4
    80004030:	ffffe097          	auipc	ra,0xffffe
    80004034:	618080e7          	jalr	1560(ra) # 80002648 <either_copyin>
    80004038:	07850263          	beq	a0,s8,8000409c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000403c:	8526                	mv	a0,s1
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	788080e7          	jalr	1928(ra) # 800047c6 <log_write>
    brelse(bp);
    80004046:	8526                	mv	a0,s1
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	4f4080e7          	jalr	1268(ra) # 8000353c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004050:	013d09bb          	addw	s3,s10,s3
    80004054:	012d093b          	addw	s2,s10,s2
    80004058:	9a6e                	add	s4,s4,s11
    8000405a:	0569f663          	bgeu	s3,s6,800040a6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000405e:	00a9559b          	srliw	a1,s2,0xa
    80004062:	8556                	mv	a0,s5
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	79c080e7          	jalr	1948(ra) # 80003800 <bmap>
    8000406c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004070:	c99d                	beqz	a1,800040a6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004072:	000aa503          	lw	a0,0(s5)
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	396080e7          	jalr	918(ra) # 8000340c <bread>
    8000407e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004080:	3ff97713          	andi	a4,s2,1023
    80004084:	40ec87bb          	subw	a5,s9,a4
    80004088:	413b06bb          	subw	a3,s6,s3
    8000408c:	8d3e                	mv	s10,a5
    8000408e:	2781                	sext.w	a5,a5
    80004090:	0006861b          	sext.w	a2,a3
    80004094:	f8f674e3          	bgeu	a2,a5,8000401c <writei+0x4c>
    80004098:	8d36                	mv	s10,a3
    8000409a:	b749                	j	8000401c <writei+0x4c>
      brelse(bp);
    8000409c:	8526                	mv	a0,s1
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	49e080e7          	jalr	1182(ra) # 8000353c <brelse>
  }

  if(off > ip->size)
    800040a6:	04caa783          	lw	a5,76(s5)
    800040aa:	0127f463          	bgeu	a5,s2,800040b2 <writei+0xe2>
    ip->size = off;
    800040ae:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040b2:	8556                	mv	a0,s5
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	aa4080e7          	jalr	-1372(ra) # 80003b58 <iupdate>

  return tot;
    800040bc:	0009851b          	sext.w	a0,s3
}
    800040c0:	70a6                	ld	ra,104(sp)
    800040c2:	7406                	ld	s0,96(sp)
    800040c4:	64e6                	ld	s1,88(sp)
    800040c6:	6946                	ld	s2,80(sp)
    800040c8:	69a6                	ld	s3,72(sp)
    800040ca:	6a06                	ld	s4,64(sp)
    800040cc:	7ae2                	ld	s5,56(sp)
    800040ce:	7b42                	ld	s6,48(sp)
    800040d0:	7ba2                	ld	s7,40(sp)
    800040d2:	7c02                	ld	s8,32(sp)
    800040d4:	6ce2                	ld	s9,24(sp)
    800040d6:	6d42                	ld	s10,16(sp)
    800040d8:	6da2                	ld	s11,8(sp)
    800040da:	6165                	addi	sp,sp,112
    800040dc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040de:	89da                	mv	s3,s6
    800040e0:	bfc9                	j	800040b2 <writei+0xe2>
    return -1;
    800040e2:	557d                	li	a0,-1
}
    800040e4:	8082                	ret
    return -1;
    800040e6:	557d                	li	a0,-1
    800040e8:	bfe1                	j	800040c0 <writei+0xf0>
    return -1;
    800040ea:	557d                	li	a0,-1
    800040ec:	bfd1                	j	800040c0 <writei+0xf0>

00000000800040ee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040ee:	1141                	addi	sp,sp,-16
    800040f0:	e406                	sd	ra,8(sp)
    800040f2:	e022                	sd	s0,0(sp)
    800040f4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040f6:	4639                	li	a2,14
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	caa080e7          	jalr	-854(ra) # 80000da2 <strncmp>
}
    80004100:	60a2                	ld	ra,8(sp)
    80004102:	6402                	ld	s0,0(sp)
    80004104:	0141                	addi	sp,sp,16
    80004106:	8082                	ret

0000000080004108 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004108:	7139                	addi	sp,sp,-64
    8000410a:	fc06                	sd	ra,56(sp)
    8000410c:	f822                	sd	s0,48(sp)
    8000410e:	f426                	sd	s1,40(sp)
    80004110:	f04a                	sd	s2,32(sp)
    80004112:	ec4e                	sd	s3,24(sp)
    80004114:	e852                	sd	s4,16(sp)
    80004116:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004118:	04451703          	lh	a4,68(a0)
    8000411c:	4785                	li	a5,1
    8000411e:	00f71a63          	bne	a4,a5,80004132 <dirlookup+0x2a>
    80004122:	892a                	mv	s2,a0
    80004124:	89ae                	mv	s3,a1
    80004126:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004128:	457c                	lw	a5,76(a0)
    8000412a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000412c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000412e:	e79d                	bnez	a5,8000415c <dirlookup+0x54>
    80004130:	a8a5                	j	800041a8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004132:	00004517          	auipc	a0,0x4
    80004136:	4ee50513          	addi	a0,a0,1262 # 80008620 <syscalls+0x1c0>
    8000413a:	ffffc097          	auipc	ra,0xffffc
    8000413e:	406080e7          	jalr	1030(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004142:	00004517          	auipc	a0,0x4
    80004146:	4f650513          	addi	a0,a0,1270 # 80008638 <syscalls+0x1d8>
    8000414a:	ffffc097          	auipc	ra,0xffffc
    8000414e:	3f6080e7          	jalr	1014(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004152:	24c1                	addiw	s1,s1,16
    80004154:	04c92783          	lw	a5,76(s2)
    80004158:	04f4f763          	bgeu	s1,a5,800041a6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000415c:	4741                	li	a4,16
    8000415e:	86a6                	mv	a3,s1
    80004160:	fc040613          	addi	a2,s0,-64
    80004164:	4581                	li	a1,0
    80004166:	854a                	mv	a0,s2
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	d70080e7          	jalr	-656(ra) # 80003ed8 <readi>
    80004170:	47c1                	li	a5,16
    80004172:	fcf518e3          	bne	a0,a5,80004142 <dirlookup+0x3a>
    if(de.inum == 0)
    80004176:	fc045783          	lhu	a5,-64(s0)
    8000417a:	dfe1                	beqz	a5,80004152 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000417c:	fc240593          	addi	a1,s0,-62
    80004180:	854e                	mv	a0,s3
    80004182:	00000097          	auipc	ra,0x0
    80004186:	f6c080e7          	jalr	-148(ra) # 800040ee <namecmp>
    8000418a:	f561                	bnez	a0,80004152 <dirlookup+0x4a>
      if(poff)
    8000418c:	000a0463          	beqz	s4,80004194 <dirlookup+0x8c>
        *poff = off;
    80004190:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004194:	fc045583          	lhu	a1,-64(s0)
    80004198:	00092503          	lw	a0,0(s2)
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	74e080e7          	jalr	1870(ra) # 800038ea <iget>
    800041a4:	a011                	j	800041a8 <dirlookup+0xa0>
  return 0;
    800041a6:	4501                	li	a0,0
}
    800041a8:	70e2                	ld	ra,56(sp)
    800041aa:	7442                	ld	s0,48(sp)
    800041ac:	74a2                	ld	s1,40(sp)
    800041ae:	7902                	ld	s2,32(sp)
    800041b0:	69e2                	ld	s3,24(sp)
    800041b2:	6a42                	ld	s4,16(sp)
    800041b4:	6121                	addi	sp,sp,64
    800041b6:	8082                	ret

00000000800041b8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041b8:	711d                	addi	sp,sp,-96
    800041ba:	ec86                	sd	ra,88(sp)
    800041bc:	e8a2                	sd	s0,80(sp)
    800041be:	e4a6                	sd	s1,72(sp)
    800041c0:	e0ca                	sd	s2,64(sp)
    800041c2:	fc4e                	sd	s3,56(sp)
    800041c4:	f852                	sd	s4,48(sp)
    800041c6:	f456                	sd	s5,40(sp)
    800041c8:	f05a                	sd	s6,32(sp)
    800041ca:	ec5e                	sd	s7,24(sp)
    800041cc:	e862                	sd	s8,16(sp)
    800041ce:	e466                	sd	s9,8(sp)
    800041d0:	e06a                	sd	s10,0(sp)
    800041d2:	1080                	addi	s0,sp,96
    800041d4:	84aa                	mv	s1,a0
    800041d6:	8b2e                	mv	s6,a1
    800041d8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041da:	00054703          	lbu	a4,0(a0)
    800041de:	02f00793          	li	a5,47
    800041e2:	02f70363          	beq	a4,a5,80004208 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041e6:	ffffd097          	auipc	ra,0xffffd
    800041ea:	7c6080e7          	jalr	1990(ra) # 800019ac <myproc>
    800041ee:	15053503          	ld	a0,336(a0)
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	9f4080e7          	jalr	-1548(ra) # 80003be6 <idup>
    800041fa:	8a2a                	mv	s4,a0
  while(*path == '/')
    800041fc:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004200:	4cb5                	li	s9,13
  len = path - s;
    80004202:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004204:	4c05                	li	s8,1
    80004206:	a87d                	j	800042c4 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004208:	4585                	li	a1,1
    8000420a:	4505                	li	a0,1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	6de080e7          	jalr	1758(ra) # 800038ea <iget>
    80004214:	8a2a                	mv	s4,a0
    80004216:	b7dd                	j	800041fc <namex+0x44>
      iunlockput(ip);
    80004218:	8552                	mv	a0,s4
    8000421a:	00000097          	auipc	ra,0x0
    8000421e:	c6c080e7          	jalr	-916(ra) # 80003e86 <iunlockput>
      return 0;
    80004222:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004224:	8552                	mv	a0,s4
    80004226:	60e6                	ld	ra,88(sp)
    80004228:	6446                	ld	s0,80(sp)
    8000422a:	64a6                	ld	s1,72(sp)
    8000422c:	6906                	ld	s2,64(sp)
    8000422e:	79e2                	ld	s3,56(sp)
    80004230:	7a42                	ld	s4,48(sp)
    80004232:	7aa2                	ld	s5,40(sp)
    80004234:	7b02                	ld	s6,32(sp)
    80004236:	6be2                	ld	s7,24(sp)
    80004238:	6c42                	ld	s8,16(sp)
    8000423a:	6ca2                	ld	s9,8(sp)
    8000423c:	6d02                	ld	s10,0(sp)
    8000423e:	6125                	addi	sp,sp,96
    80004240:	8082                	ret
      iunlock(ip);
    80004242:	8552                	mv	a0,s4
    80004244:	00000097          	auipc	ra,0x0
    80004248:	aa2080e7          	jalr	-1374(ra) # 80003ce6 <iunlock>
      return ip;
    8000424c:	bfe1                	j	80004224 <namex+0x6c>
      iunlockput(ip);
    8000424e:	8552                	mv	a0,s4
    80004250:	00000097          	auipc	ra,0x0
    80004254:	c36080e7          	jalr	-970(ra) # 80003e86 <iunlockput>
      return 0;
    80004258:	8a4e                	mv	s4,s3
    8000425a:	b7e9                	j	80004224 <namex+0x6c>
  len = path - s;
    8000425c:	40998633          	sub	a2,s3,s1
    80004260:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004264:	09acd863          	bge	s9,s10,800042f4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004268:	4639                	li	a2,14
    8000426a:	85a6                	mv	a1,s1
    8000426c:	8556                	mv	a0,s5
    8000426e:	ffffd097          	auipc	ra,0xffffd
    80004272:	ac0080e7          	jalr	-1344(ra) # 80000d2e <memmove>
    80004276:	84ce                	mv	s1,s3
  while(*path == '/')
    80004278:	0004c783          	lbu	a5,0(s1)
    8000427c:	01279763          	bne	a5,s2,8000428a <namex+0xd2>
    path++;
    80004280:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004282:	0004c783          	lbu	a5,0(s1)
    80004286:	ff278de3          	beq	a5,s2,80004280 <namex+0xc8>
    ilock(ip);
    8000428a:	8552                	mv	a0,s4
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	998080e7          	jalr	-1640(ra) # 80003c24 <ilock>
    if(ip->type != T_DIR){
    80004294:	044a1783          	lh	a5,68(s4)
    80004298:	f98790e3          	bne	a5,s8,80004218 <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000429c:	000b0563          	beqz	s6,800042a6 <namex+0xee>
    800042a0:	0004c783          	lbu	a5,0(s1)
    800042a4:	dfd9                	beqz	a5,80004242 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042a6:	865e                	mv	a2,s7
    800042a8:	85d6                	mv	a1,s5
    800042aa:	8552                	mv	a0,s4
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	e5c080e7          	jalr	-420(ra) # 80004108 <dirlookup>
    800042b4:	89aa                	mv	s3,a0
    800042b6:	dd41                	beqz	a0,8000424e <namex+0x96>
    iunlockput(ip);
    800042b8:	8552                	mv	a0,s4
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	bcc080e7          	jalr	-1076(ra) # 80003e86 <iunlockput>
    ip = next;
    800042c2:	8a4e                	mv	s4,s3
  while(*path == '/')
    800042c4:	0004c783          	lbu	a5,0(s1)
    800042c8:	01279763          	bne	a5,s2,800042d6 <namex+0x11e>
    path++;
    800042cc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042ce:	0004c783          	lbu	a5,0(s1)
    800042d2:	ff278de3          	beq	a5,s2,800042cc <namex+0x114>
  if(*path == 0)
    800042d6:	cb9d                	beqz	a5,8000430c <namex+0x154>
  while(*path != '/' && *path != 0)
    800042d8:	0004c783          	lbu	a5,0(s1)
    800042dc:	89a6                	mv	s3,s1
  len = path - s;
    800042de:	8d5e                	mv	s10,s7
    800042e0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042e2:	01278963          	beq	a5,s2,800042f4 <namex+0x13c>
    800042e6:	dbbd                	beqz	a5,8000425c <namex+0xa4>
    path++;
    800042e8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800042ea:	0009c783          	lbu	a5,0(s3)
    800042ee:	ff279ce3          	bne	a5,s2,800042e6 <namex+0x12e>
    800042f2:	b7ad                	j	8000425c <namex+0xa4>
    memmove(name, s, len);
    800042f4:	2601                	sext.w	a2,a2
    800042f6:	85a6                	mv	a1,s1
    800042f8:	8556                	mv	a0,s5
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	a34080e7          	jalr	-1484(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004302:	9d56                	add	s10,s10,s5
    80004304:	000d0023          	sb	zero,0(s10)
    80004308:	84ce                	mv	s1,s3
    8000430a:	b7bd                	j	80004278 <namex+0xc0>
  if(nameiparent){
    8000430c:	f00b0ce3          	beqz	s6,80004224 <namex+0x6c>
    iput(ip);
    80004310:	8552                	mv	a0,s4
    80004312:	00000097          	auipc	ra,0x0
    80004316:	acc080e7          	jalr	-1332(ra) # 80003dde <iput>
    return 0;
    8000431a:	4a01                	li	s4,0
    8000431c:	b721                	j	80004224 <namex+0x6c>

000000008000431e <dirlink>:
{
    8000431e:	7139                	addi	sp,sp,-64
    80004320:	fc06                	sd	ra,56(sp)
    80004322:	f822                	sd	s0,48(sp)
    80004324:	f426                	sd	s1,40(sp)
    80004326:	f04a                	sd	s2,32(sp)
    80004328:	ec4e                	sd	s3,24(sp)
    8000432a:	e852                	sd	s4,16(sp)
    8000432c:	0080                	addi	s0,sp,64
    8000432e:	892a                	mv	s2,a0
    80004330:	8a2e                	mv	s4,a1
    80004332:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004334:	4601                	li	a2,0
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	dd2080e7          	jalr	-558(ra) # 80004108 <dirlookup>
    8000433e:	e93d                	bnez	a0,800043b4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004340:	04c92483          	lw	s1,76(s2)
    80004344:	c49d                	beqz	s1,80004372 <dirlink+0x54>
    80004346:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004348:	4741                	li	a4,16
    8000434a:	86a6                	mv	a3,s1
    8000434c:	fc040613          	addi	a2,s0,-64
    80004350:	4581                	li	a1,0
    80004352:	854a                	mv	a0,s2
    80004354:	00000097          	auipc	ra,0x0
    80004358:	b84080e7          	jalr	-1148(ra) # 80003ed8 <readi>
    8000435c:	47c1                	li	a5,16
    8000435e:	06f51163          	bne	a0,a5,800043c0 <dirlink+0xa2>
    if(de.inum == 0)
    80004362:	fc045783          	lhu	a5,-64(s0)
    80004366:	c791                	beqz	a5,80004372 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004368:	24c1                	addiw	s1,s1,16
    8000436a:	04c92783          	lw	a5,76(s2)
    8000436e:	fcf4ede3          	bltu	s1,a5,80004348 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004372:	4639                	li	a2,14
    80004374:	85d2                	mv	a1,s4
    80004376:	fc240513          	addi	a0,s0,-62
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	a64080e7          	jalr	-1436(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004382:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004386:	4741                	li	a4,16
    80004388:	86a6                	mv	a3,s1
    8000438a:	fc040613          	addi	a2,s0,-64
    8000438e:	4581                	li	a1,0
    80004390:	854a                	mv	a0,s2
    80004392:	00000097          	auipc	ra,0x0
    80004396:	c3e080e7          	jalr	-962(ra) # 80003fd0 <writei>
    8000439a:	1541                	addi	a0,a0,-16
    8000439c:	00a03533          	snez	a0,a0
    800043a0:	40a00533          	neg	a0,a0
}
    800043a4:	70e2                	ld	ra,56(sp)
    800043a6:	7442                	ld	s0,48(sp)
    800043a8:	74a2                	ld	s1,40(sp)
    800043aa:	7902                	ld	s2,32(sp)
    800043ac:	69e2                	ld	s3,24(sp)
    800043ae:	6a42                	ld	s4,16(sp)
    800043b0:	6121                	addi	sp,sp,64
    800043b2:	8082                	ret
    iput(ip);
    800043b4:	00000097          	auipc	ra,0x0
    800043b8:	a2a080e7          	jalr	-1494(ra) # 80003dde <iput>
    return -1;
    800043bc:	557d                	li	a0,-1
    800043be:	b7dd                	j	800043a4 <dirlink+0x86>
      panic("dirlink read");
    800043c0:	00004517          	auipc	a0,0x4
    800043c4:	28850513          	addi	a0,a0,648 # 80008648 <syscalls+0x1e8>
    800043c8:	ffffc097          	auipc	ra,0xffffc
    800043cc:	178080e7          	jalr	376(ra) # 80000540 <panic>

00000000800043d0 <namei>:

struct inode*
namei(char *path)
{
    800043d0:	1101                	addi	sp,sp,-32
    800043d2:	ec06                	sd	ra,24(sp)
    800043d4:	e822                	sd	s0,16(sp)
    800043d6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043d8:	fe040613          	addi	a2,s0,-32
    800043dc:	4581                	li	a1,0
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	dda080e7          	jalr	-550(ra) # 800041b8 <namex>
}
    800043e6:	60e2                	ld	ra,24(sp)
    800043e8:	6442                	ld	s0,16(sp)
    800043ea:	6105                	addi	sp,sp,32
    800043ec:	8082                	ret

00000000800043ee <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043ee:	1141                	addi	sp,sp,-16
    800043f0:	e406                	sd	ra,8(sp)
    800043f2:	e022                	sd	s0,0(sp)
    800043f4:	0800                	addi	s0,sp,16
    800043f6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043f8:	4585                	li	a1,1
    800043fa:	00000097          	auipc	ra,0x0
    800043fe:	dbe080e7          	jalr	-578(ra) # 800041b8 <namex>
}
    80004402:	60a2                	ld	ra,8(sp)
    80004404:	6402                	ld	s0,0(sp)
    80004406:	0141                	addi	sp,sp,16
    80004408:	8082                	ret

000000008000440a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000440a:	1101                	addi	sp,sp,-32
    8000440c:	ec06                	sd	ra,24(sp)
    8000440e:	e822                	sd	s0,16(sp)
    80004410:	e426                	sd	s1,8(sp)
    80004412:	e04a                	sd	s2,0(sp)
    80004414:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004416:	0001d917          	auipc	s2,0x1d
    8000441a:	73a90913          	addi	s2,s2,1850 # 80021b50 <log>
    8000441e:	01892583          	lw	a1,24(s2)
    80004422:	02892503          	lw	a0,40(s2)
    80004426:	fffff097          	auipc	ra,0xfffff
    8000442a:	fe6080e7          	jalr	-26(ra) # 8000340c <bread>
    8000442e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004430:	02c92683          	lw	a3,44(s2)
    80004434:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004436:	02d05863          	blez	a3,80004466 <write_head+0x5c>
    8000443a:	0001d797          	auipc	a5,0x1d
    8000443e:	74678793          	addi	a5,a5,1862 # 80021b80 <log+0x30>
    80004442:	05c50713          	addi	a4,a0,92
    80004446:	36fd                	addiw	a3,a3,-1
    80004448:	02069613          	slli	a2,a3,0x20
    8000444c:	01e65693          	srli	a3,a2,0x1e
    80004450:	0001d617          	auipc	a2,0x1d
    80004454:	73460613          	addi	a2,a2,1844 # 80021b84 <log+0x34>
    80004458:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000445a:	4390                	lw	a2,0(a5)
    8000445c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000445e:	0791                	addi	a5,a5,4
    80004460:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004462:	fed79ce3          	bne	a5,a3,8000445a <write_head+0x50>
  }
  bwrite(buf);
    80004466:	8526                	mv	a0,s1
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	096080e7          	jalr	150(ra) # 800034fe <bwrite>
  brelse(buf);
    80004470:	8526                	mv	a0,s1
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	0ca080e7          	jalr	202(ra) # 8000353c <brelse>
}
    8000447a:	60e2                	ld	ra,24(sp)
    8000447c:	6442                	ld	s0,16(sp)
    8000447e:	64a2                	ld	s1,8(sp)
    80004480:	6902                	ld	s2,0(sp)
    80004482:	6105                	addi	sp,sp,32
    80004484:	8082                	ret

0000000080004486 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004486:	0001d797          	auipc	a5,0x1d
    8000448a:	6f67a783          	lw	a5,1782(a5) # 80021b7c <log+0x2c>
    8000448e:	0af05d63          	blez	a5,80004548 <install_trans+0xc2>
{
    80004492:	7139                	addi	sp,sp,-64
    80004494:	fc06                	sd	ra,56(sp)
    80004496:	f822                	sd	s0,48(sp)
    80004498:	f426                	sd	s1,40(sp)
    8000449a:	f04a                	sd	s2,32(sp)
    8000449c:	ec4e                	sd	s3,24(sp)
    8000449e:	e852                	sd	s4,16(sp)
    800044a0:	e456                	sd	s5,8(sp)
    800044a2:	e05a                	sd	s6,0(sp)
    800044a4:	0080                	addi	s0,sp,64
    800044a6:	8b2a                	mv	s6,a0
    800044a8:	0001da97          	auipc	s5,0x1d
    800044ac:	6d8a8a93          	addi	s5,s5,1752 # 80021b80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044b2:	0001d997          	auipc	s3,0x1d
    800044b6:	69e98993          	addi	s3,s3,1694 # 80021b50 <log>
    800044ba:	a00d                	j	800044dc <install_trans+0x56>
    brelse(lbuf);
    800044bc:	854a                	mv	a0,s2
    800044be:	fffff097          	auipc	ra,0xfffff
    800044c2:	07e080e7          	jalr	126(ra) # 8000353c <brelse>
    brelse(dbuf);
    800044c6:	8526                	mv	a0,s1
    800044c8:	fffff097          	auipc	ra,0xfffff
    800044cc:	074080e7          	jalr	116(ra) # 8000353c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d0:	2a05                	addiw	s4,s4,1
    800044d2:	0a91                	addi	s5,s5,4
    800044d4:	02c9a783          	lw	a5,44(s3)
    800044d8:	04fa5e63          	bge	s4,a5,80004534 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044dc:	0189a583          	lw	a1,24(s3)
    800044e0:	014585bb          	addw	a1,a1,s4
    800044e4:	2585                	addiw	a1,a1,1
    800044e6:	0289a503          	lw	a0,40(s3)
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	f22080e7          	jalr	-222(ra) # 8000340c <bread>
    800044f2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044f4:	000aa583          	lw	a1,0(s5)
    800044f8:	0289a503          	lw	a0,40(s3)
    800044fc:	fffff097          	auipc	ra,0xfffff
    80004500:	f10080e7          	jalr	-240(ra) # 8000340c <bread>
    80004504:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004506:	40000613          	li	a2,1024
    8000450a:	05890593          	addi	a1,s2,88
    8000450e:	05850513          	addi	a0,a0,88
    80004512:	ffffd097          	auipc	ra,0xffffd
    80004516:	81c080e7          	jalr	-2020(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000451a:	8526                	mv	a0,s1
    8000451c:	fffff097          	auipc	ra,0xfffff
    80004520:	fe2080e7          	jalr	-30(ra) # 800034fe <bwrite>
    if(recovering == 0)
    80004524:	f80b1ce3          	bnez	s6,800044bc <install_trans+0x36>
      bunpin(dbuf);
    80004528:	8526                	mv	a0,s1
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	0ec080e7          	jalr	236(ra) # 80003616 <bunpin>
    80004532:	b769                	j	800044bc <install_trans+0x36>
}
    80004534:	70e2                	ld	ra,56(sp)
    80004536:	7442                	ld	s0,48(sp)
    80004538:	74a2                	ld	s1,40(sp)
    8000453a:	7902                	ld	s2,32(sp)
    8000453c:	69e2                	ld	s3,24(sp)
    8000453e:	6a42                	ld	s4,16(sp)
    80004540:	6aa2                	ld	s5,8(sp)
    80004542:	6b02                	ld	s6,0(sp)
    80004544:	6121                	addi	sp,sp,64
    80004546:	8082                	ret
    80004548:	8082                	ret

000000008000454a <initlog>:
{
    8000454a:	7179                	addi	sp,sp,-48
    8000454c:	f406                	sd	ra,40(sp)
    8000454e:	f022                	sd	s0,32(sp)
    80004550:	ec26                	sd	s1,24(sp)
    80004552:	e84a                	sd	s2,16(sp)
    80004554:	e44e                	sd	s3,8(sp)
    80004556:	1800                	addi	s0,sp,48
    80004558:	892a                	mv	s2,a0
    8000455a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000455c:	0001d497          	auipc	s1,0x1d
    80004560:	5f448493          	addi	s1,s1,1524 # 80021b50 <log>
    80004564:	00004597          	auipc	a1,0x4
    80004568:	0f458593          	addi	a1,a1,244 # 80008658 <syscalls+0x1f8>
    8000456c:	8526                	mv	a0,s1
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	5d8080e7          	jalr	1496(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004576:	0149a583          	lw	a1,20(s3)
    8000457a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000457c:	0109a783          	lw	a5,16(s3)
    80004580:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004582:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004586:	854a                	mv	a0,s2
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	e84080e7          	jalr	-380(ra) # 8000340c <bread>
  log.lh.n = lh->n;
    80004590:	4d34                	lw	a3,88(a0)
    80004592:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004594:	02d05663          	blez	a3,800045c0 <initlog+0x76>
    80004598:	05c50793          	addi	a5,a0,92
    8000459c:	0001d717          	auipc	a4,0x1d
    800045a0:	5e470713          	addi	a4,a4,1508 # 80021b80 <log+0x30>
    800045a4:	36fd                	addiw	a3,a3,-1
    800045a6:	02069613          	slli	a2,a3,0x20
    800045aa:	01e65693          	srli	a3,a2,0x1e
    800045ae:	06050613          	addi	a2,a0,96
    800045b2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800045b4:	4390                	lw	a2,0(a5)
    800045b6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045b8:	0791                	addi	a5,a5,4
    800045ba:	0711                	addi	a4,a4,4
    800045bc:	fed79ce3          	bne	a5,a3,800045b4 <initlog+0x6a>
  brelse(buf);
    800045c0:	fffff097          	auipc	ra,0xfffff
    800045c4:	f7c080e7          	jalr	-132(ra) # 8000353c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045c8:	4505                	li	a0,1
    800045ca:	00000097          	auipc	ra,0x0
    800045ce:	ebc080e7          	jalr	-324(ra) # 80004486 <install_trans>
  log.lh.n = 0;
    800045d2:	0001d797          	auipc	a5,0x1d
    800045d6:	5a07a523          	sw	zero,1450(a5) # 80021b7c <log+0x2c>
  write_head(); // clear the log
    800045da:	00000097          	auipc	ra,0x0
    800045de:	e30080e7          	jalr	-464(ra) # 8000440a <write_head>
}
    800045e2:	70a2                	ld	ra,40(sp)
    800045e4:	7402                	ld	s0,32(sp)
    800045e6:	64e2                	ld	s1,24(sp)
    800045e8:	6942                	ld	s2,16(sp)
    800045ea:	69a2                	ld	s3,8(sp)
    800045ec:	6145                	addi	sp,sp,48
    800045ee:	8082                	ret

00000000800045f0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045f0:	1101                	addi	sp,sp,-32
    800045f2:	ec06                	sd	ra,24(sp)
    800045f4:	e822                	sd	s0,16(sp)
    800045f6:	e426                	sd	s1,8(sp)
    800045f8:	e04a                	sd	s2,0(sp)
    800045fa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045fc:	0001d517          	auipc	a0,0x1d
    80004600:	55450513          	addi	a0,a0,1364 # 80021b50 <log>
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	5d2080e7          	jalr	1490(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000460c:	0001d497          	auipc	s1,0x1d
    80004610:	54448493          	addi	s1,s1,1348 # 80021b50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004614:	4979                	li	s2,30
    80004616:	a039                	j	80004624 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004618:	85a6                	mv	a1,s1
    8000461a:	8526                	mv	a0,s1
    8000461c:	ffffe097          	auipc	ra,0xffffe
    80004620:	bc2080e7          	jalr	-1086(ra) # 800021de <sleep>
    if(log.committing){
    80004624:	50dc                	lw	a5,36(s1)
    80004626:	fbed                	bnez	a5,80004618 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004628:	5098                	lw	a4,32(s1)
    8000462a:	2705                	addiw	a4,a4,1
    8000462c:	0007069b          	sext.w	a3,a4
    80004630:	0027179b          	slliw	a5,a4,0x2
    80004634:	9fb9                	addw	a5,a5,a4
    80004636:	0017979b          	slliw	a5,a5,0x1
    8000463a:	54d8                	lw	a4,44(s1)
    8000463c:	9fb9                	addw	a5,a5,a4
    8000463e:	00f95963          	bge	s2,a5,80004650 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004642:	85a6                	mv	a1,s1
    80004644:	8526                	mv	a0,s1
    80004646:	ffffe097          	auipc	ra,0xffffe
    8000464a:	b98080e7          	jalr	-1128(ra) # 800021de <sleep>
    8000464e:	bfd9                	j	80004624 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004650:	0001d517          	auipc	a0,0x1d
    80004654:	50050513          	addi	a0,a0,1280 # 80021b50 <log>
    80004658:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	630080e7          	jalr	1584(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004662:	60e2                	ld	ra,24(sp)
    80004664:	6442                	ld	s0,16(sp)
    80004666:	64a2                	ld	s1,8(sp)
    80004668:	6902                	ld	s2,0(sp)
    8000466a:	6105                	addi	sp,sp,32
    8000466c:	8082                	ret

000000008000466e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000466e:	7139                	addi	sp,sp,-64
    80004670:	fc06                	sd	ra,56(sp)
    80004672:	f822                	sd	s0,48(sp)
    80004674:	f426                	sd	s1,40(sp)
    80004676:	f04a                	sd	s2,32(sp)
    80004678:	ec4e                	sd	s3,24(sp)
    8000467a:	e852                	sd	s4,16(sp)
    8000467c:	e456                	sd	s5,8(sp)
    8000467e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004680:	0001d497          	auipc	s1,0x1d
    80004684:	4d048493          	addi	s1,s1,1232 # 80021b50 <log>
    80004688:	8526                	mv	a0,s1
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	54c080e7          	jalr	1356(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004692:	509c                	lw	a5,32(s1)
    80004694:	37fd                	addiw	a5,a5,-1
    80004696:	0007891b          	sext.w	s2,a5
    8000469a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000469c:	50dc                	lw	a5,36(s1)
    8000469e:	e7b9                	bnez	a5,800046ec <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046a0:	04091e63          	bnez	s2,800046fc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800046a4:	0001d497          	auipc	s1,0x1d
    800046a8:	4ac48493          	addi	s1,s1,1196 # 80021b50 <log>
    800046ac:	4785                	li	a5,1
    800046ae:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046b0:	8526                	mv	a0,s1
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	5d8080e7          	jalr	1496(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046ba:	54dc                	lw	a5,44(s1)
    800046bc:	06f04763          	bgtz	a5,8000472a <end_op+0xbc>
    acquire(&log.lock);
    800046c0:	0001d497          	auipc	s1,0x1d
    800046c4:	49048493          	addi	s1,s1,1168 # 80021b50 <log>
    800046c8:	8526                	mv	a0,s1
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	50c080e7          	jalr	1292(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800046d2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046d6:	8526                	mv	a0,s1
    800046d8:	ffffe097          	auipc	ra,0xffffe
    800046dc:	b6a080e7          	jalr	-1174(ra) # 80002242 <wakeup>
    release(&log.lock);
    800046e0:	8526                	mv	a0,s1
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	5a8080e7          	jalr	1448(ra) # 80000c8a <release>
}
    800046ea:	a03d                	j	80004718 <end_op+0xaa>
    panic("log.committing");
    800046ec:	00004517          	auipc	a0,0x4
    800046f0:	f7450513          	addi	a0,a0,-140 # 80008660 <syscalls+0x200>
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	e4c080e7          	jalr	-436(ra) # 80000540 <panic>
    wakeup(&log);
    800046fc:	0001d497          	auipc	s1,0x1d
    80004700:	45448493          	addi	s1,s1,1108 # 80021b50 <log>
    80004704:	8526                	mv	a0,s1
    80004706:	ffffe097          	auipc	ra,0xffffe
    8000470a:	b3c080e7          	jalr	-1220(ra) # 80002242 <wakeup>
  release(&log.lock);
    8000470e:	8526                	mv	a0,s1
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	57a080e7          	jalr	1402(ra) # 80000c8a <release>
}
    80004718:	70e2                	ld	ra,56(sp)
    8000471a:	7442                	ld	s0,48(sp)
    8000471c:	74a2                	ld	s1,40(sp)
    8000471e:	7902                	ld	s2,32(sp)
    80004720:	69e2                	ld	s3,24(sp)
    80004722:	6a42                	ld	s4,16(sp)
    80004724:	6aa2                	ld	s5,8(sp)
    80004726:	6121                	addi	sp,sp,64
    80004728:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000472a:	0001da97          	auipc	s5,0x1d
    8000472e:	456a8a93          	addi	s5,s5,1110 # 80021b80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004732:	0001da17          	auipc	s4,0x1d
    80004736:	41ea0a13          	addi	s4,s4,1054 # 80021b50 <log>
    8000473a:	018a2583          	lw	a1,24(s4)
    8000473e:	012585bb          	addw	a1,a1,s2
    80004742:	2585                	addiw	a1,a1,1
    80004744:	028a2503          	lw	a0,40(s4)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	cc4080e7          	jalr	-828(ra) # 8000340c <bread>
    80004750:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004752:	000aa583          	lw	a1,0(s5)
    80004756:	028a2503          	lw	a0,40(s4)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	cb2080e7          	jalr	-846(ra) # 8000340c <bread>
    80004762:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004764:	40000613          	li	a2,1024
    80004768:	05850593          	addi	a1,a0,88
    8000476c:	05848513          	addi	a0,s1,88
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	5be080e7          	jalr	1470(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004778:	8526                	mv	a0,s1
    8000477a:	fffff097          	auipc	ra,0xfffff
    8000477e:	d84080e7          	jalr	-636(ra) # 800034fe <bwrite>
    brelse(from);
    80004782:	854e                	mv	a0,s3
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	db8080e7          	jalr	-584(ra) # 8000353c <brelse>
    brelse(to);
    8000478c:	8526                	mv	a0,s1
    8000478e:	fffff097          	auipc	ra,0xfffff
    80004792:	dae080e7          	jalr	-594(ra) # 8000353c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004796:	2905                	addiw	s2,s2,1
    80004798:	0a91                	addi	s5,s5,4
    8000479a:	02ca2783          	lw	a5,44(s4)
    8000479e:	f8f94ee3          	blt	s2,a5,8000473a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	c68080e7          	jalr	-920(ra) # 8000440a <write_head>
    install_trans(0); // Now install writes to home locations
    800047aa:	4501                	li	a0,0
    800047ac:	00000097          	auipc	ra,0x0
    800047b0:	cda080e7          	jalr	-806(ra) # 80004486 <install_trans>
    log.lh.n = 0;
    800047b4:	0001d797          	auipc	a5,0x1d
    800047b8:	3c07a423          	sw	zero,968(a5) # 80021b7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	c4e080e7          	jalr	-946(ra) # 8000440a <write_head>
    800047c4:	bdf5                	j	800046c0 <end_op+0x52>

00000000800047c6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047c6:	1101                	addi	sp,sp,-32
    800047c8:	ec06                	sd	ra,24(sp)
    800047ca:	e822                	sd	s0,16(sp)
    800047cc:	e426                	sd	s1,8(sp)
    800047ce:	e04a                	sd	s2,0(sp)
    800047d0:	1000                	addi	s0,sp,32
    800047d2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047d4:	0001d917          	auipc	s2,0x1d
    800047d8:	37c90913          	addi	s2,s2,892 # 80021b50 <log>
    800047dc:	854a                	mv	a0,s2
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	3f8080e7          	jalr	1016(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047e6:	02c92603          	lw	a2,44(s2)
    800047ea:	47f5                	li	a5,29
    800047ec:	06c7c563          	blt	a5,a2,80004856 <log_write+0x90>
    800047f0:	0001d797          	auipc	a5,0x1d
    800047f4:	37c7a783          	lw	a5,892(a5) # 80021b6c <log+0x1c>
    800047f8:	37fd                	addiw	a5,a5,-1
    800047fa:	04f65e63          	bge	a2,a5,80004856 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047fe:	0001d797          	auipc	a5,0x1d
    80004802:	3727a783          	lw	a5,882(a5) # 80021b70 <log+0x20>
    80004806:	06f05063          	blez	a5,80004866 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000480a:	4781                	li	a5,0
    8000480c:	06c05563          	blez	a2,80004876 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004810:	44cc                	lw	a1,12(s1)
    80004812:	0001d717          	auipc	a4,0x1d
    80004816:	36e70713          	addi	a4,a4,878 # 80021b80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000481a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000481c:	4314                	lw	a3,0(a4)
    8000481e:	04b68c63          	beq	a3,a1,80004876 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004822:	2785                	addiw	a5,a5,1
    80004824:	0711                	addi	a4,a4,4
    80004826:	fef61be3          	bne	a2,a5,8000481c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000482a:	0621                	addi	a2,a2,8
    8000482c:	060a                	slli	a2,a2,0x2
    8000482e:	0001d797          	auipc	a5,0x1d
    80004832:	32278793          	addi	a5,a5,802 # 80021b50 <log>
    80004836:	97b2                	add	a5,a5,a2
    80004838:	44d8                	lw	a4,12(s1)
    8000483a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000483c:	8526                	mv	a0,s1
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	d9c080e7          	jalr	-612(ra) # 800035da <bpin>
    log.lh.n++;
    80004846:	0001d717          	auipc	a4,0x1d
    8000484a:	30a70713          	addi	a4,a4,778 # 80021b50 <log>
    8000484e:	575c                	lw	a5,44(a4)
    80004850:	2785                	addiw	a5,a5,1
    80004852:	d75c                	sw	a5,44(a4)
    80004854:	a82d                	j	8000488e <log_write+0xc8>
    panic("too big a transaction");
    80004856:	00004517          	auipc	a0,0x4
    8000485a:	e1a50513          	addi	a0,a0,-486 # 80008670 <syscalls+0x210>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	ce2080e7          	jalr	-798(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004866:	00004517          	auipc	a0,0x4
    8000486a:	e2250513          	addi	a0,a0,-478 # 80008688 <syscalls+0x228>
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	cd2080e7          	jalr	-814(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004876:	00878693          	addi	a3,a5,8
    8000487a:	068a                	slli	a3,a3,0x2
    8000487c:	0001d717          	auipc	a4,0x1d
    80004880:	2d470713          	addi	a4,a4,724 # 80021b50 <log>
    80004884:	9736                	add	a4,a4,a3
    80004886:	44d4                	lw	a3,12(s1)
    80004888:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000488a:	faf609e3          	beq	a2,a5,8000483c <log_write+0x76>
  }
  release(&log.lock);
    8000488e:	0001d517          	auipc	a0,0x1d
    80004892:	2c250513          	addi	a0,a0,706 # 80021b50 <log>
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	3f4080e7          	jalr	1012(ra) # 80000c8a <release>
}
    8000489e:	60e2                	ld	ra,24(sp)
    800048a0:	6442                	ld	s0,16(sp)
    800048a2:	64a2                	ld	s1,8(sp)
    800048a4:	6902                	ld	s2,0(sp)
    800048a6:	6105                	addi	sp,sp,32
    800048a8:	8082                	ret

00000000800048aa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048aa:	1101                	addi	sp,sp,-32
    800048ac:	ec06                	sd	ra,24(sp)
    800048ae:	e822                	sd	s0,16(sp)
    800048b0:	e426                	sd	s1,8(sp)
    800048b2:	e04a                	sd	s2,0(sp)
    800048b4:	1000                	addi	s0,sp,32
    800048b6:	84aa                	mv	s1,a0
    800048b8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048ba:	00004597          	auipc	a1,0x4
    800048be:	dee58593          	addi	a1,a1,-530 # 800086a8 <syscalls+0x248>
    800048c2:	0521                	addi	a0,a0,8
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	282080e7          	jalr	642(ra) # 80000b46 <initlock>
  lk->name = name;
    800048cc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048d4:	0204a423          	sw	zero,40(s1)
}
    800048d8:	60e2                	ld	ra,24(sp)
    800048da:	6442                	ld	s0,16(sp)
    800048dc:	64a2                	ld	s1,8(sp)
    800048de:	6902                	ld	s2,0(sp)
    800048e0:	6105                	addi	sp,sp,32
    800048e2:	8082                	ret

00000000800048e4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048e4:	1101                	addi	sp,sp,-32
    800048e6:	ec06                	sd	ra,24(sp)
    800048e8:	e822                	sd	s0,16(sp)
    800048ea:	e426                	sd	s1,8(sp)
    800048ec:	e04a                	sd	s2,0(sp)
    800048ee:	1000                	addi	s0,sp,32
    800048f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048f2:	00850913          	addi	s2,a0,8
    800048f6:	854a                	mv	a0,s2
    800048f8:	ffffc097          	auipc	ra,0xffffc
    800048fc:	2de080e7          	jalr	734(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004900:	409c                	lw	a5,0(s1)
    80004902:	cb89                	beqz	a5,80004914 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004904:	85ca                	mv	a1,s2
    80004906:	8526                	mv	a0,s1
    80004908:	ffffe097          	auipc	ra,0xffffe
    8000490c:	8d6080e7          	jalr	-1834(ra) # 800021de <sleep>
  while (lk->locked) {
    80004910:	409c                	lw	a5,0(s1)
    80004912:	fbed                	bnez	a5,80004904 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004914:	4785                	li	a5,1
    80004916:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004918:	ffffd097          	auipc	ra,0xffffd
    8000491c:	094080e7          	jalr	148(ra) # 800019ac <myproc>
    80004920:	591c                	lw	a5,48(a0)
    80004922:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004924:	854a                	mv	a0,s2
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	364080e7          	jalr	868(ra) # 80000c8a <release>
}
    8000492e:	60e2                	ld	ra,24(sp)
    80004930:	6442                	ld	s0,16(sp)
    80004932:	64a2                	ld	s1,8(sp)
    80004934:	6902                	ld	s2,0(sp)
    80004936:	6105                	addi	sp,sp,32
    80004938:	8082                	ret

000000008000493a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000493a:	1101                	addi	sp,sp,-32
    8000493c:	ec06                	sd	ra,24(sp)
    8000493e:	e822                	sd	s0,16(sp)
    80004940:	e426                	sd	s1,8(sp)
    80004942:	e04a                	sd	s2,0(sp)
    80004944:	1000                	addi	s0,sp,32
    80004946:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004948:	00850913          	addi	s2,a0,8
    8000494c:	854a                	mv	a0,s2
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	288080e7          	jalr	648(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004956:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000495a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000495e:	8526                	mv	a0,s1
    80004960:	ffffe097          	auipc	ra,0xffffe
    80004964:	8e2080e7          	jalr	-1822(ra) # 80002242 <wakeup>
  release(&lk->lk);
    80004968:	854a                	mv	a0,s2
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	320080e7          	jalr	800(ra) # 80000c8a <release>
}
    80004972:	60e2                	ld	ra,24(sp)
    80004974:	6442                	ld	s0,16(sp)
    80004976:	64a2                	ld	s1,8(sp)
    80004978:	6902                	ld	s2,0(sp)
    8000497a:	6105                	addi	sp,sp,32
    8000497c:	8082                	ret

000000008000497e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000497e:	7179                	addi	sp,sp,-48
    80004980:	f406                	sd	ra,40(sp)
    80004982:	f022                	sd	s0,32(sp)
    80004984:	ec26                	sd	s1,24(sp)
    80004986:	e84a                	sd	s2,16(sp)
    80004988:	e44e                	sd	s3,8(sp)
    8000498a:	1800                	addi	s0,sp,48
    8000498c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000498e:	00850913          	addi	s2,a0,8
    80004992:	854a                	mv	a0,s2
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	242080e7          	jalr	578(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000499c:	409c                	lw	a5,0(s1)
    8000499e:	ef99                	bnez	a5,800049bc <holdingsleep+0x3e>
    800049a0:	4481                	li	s1,0
  release(&lk->lk);
    800049a2:	854a                	mv	a0,s2
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	2e6080e7          	jalr	742(ra) # 80000c8a <release>
  return r;
}
    800049ac:	8526                	mv	a0,s1
    800049ae:	70a2                	ld	ra,40(sp)
    800049b0:	7402                	ld	s0,32(sp)
    800049b2:	64e2                	ld	s1,24(sp)
    800049b4:	6942                	ld	s2,16(sp)
    800049b6:	69a2                	ld	s3,8(sp)
    800049b8:	6145                	addi	sp,sp,48
    800049ba:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049bc:	0284a983          	lw	s3,40(s1)
    800049c0:	ffffd097          	auipc	ra,0xffffd
    800049c4:	fec080e7          	jalr	-20(ra) # 800019ac <myproc>
    800049c8:	5904                	lw	s1,48(a0)
    800049ca:	413484b3          	sub	s1,s1,s3
    800049ce:	0014b493          	seqz	s1,s1
    800049d2:	bfc1                	j	800049a2 <holdingsleep+0x24>

00000000800049d4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049d4:	1141                	addi	sp,sp,-16
    800049d6:	e406                	sd	ra,8(sp)
    800049d8:	e022                	sd	s0,0(sp)
    800049da:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049dc:	00004597          	auipc	a1,0x4
    800049e0:	cdc58593          	addi	a1,a1,-804 # 800086b8 <syscalls+0x258>
    800049e4:	0001d517          	auipc	a0,0x1d
    800049e8:	2b450513          	addi	a0,a0,692 # 80021c98 <ftable>
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	15a080e7          	jalr	346(ra) # 80000b46 <initlock>
}
    800049f4:	60a2                	ld	ra,8(sp)
    800049f6:	6402                	ld	s0,0(sp)
    800049f8:	0141                	addi	sp,sp,16
    800049fa:	8082                	ret

00000000800049fc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049fc:	1101                	addi	sp,sp,-32
    800049fe:	ec06                	sd	ra,24(sp)
    80004a00:	e822                	sd	s0,16(sp)
    80004a02:	e426                	sd	s1,8(sp)
    80004a04:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a06:	0001d517          	auipc	a0,0x1d
    80004a0a:	29250513          	addi	a0,a0,658 # 80021c98 <ftable>
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	1c8080e7          	jalr	456(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a16:	0001d497          	auipc	s1,0x1d
    80004a1a:	29a48493          	addi	s1,s1,666 # 80021cb0 <ftable+0x18>
    80004a1e:	0001e717          	auipc	a4,0x1e
    80004a22:	23270713          	addi	a4,a4,562 # 80022c50 <disk>
    if(f->ref == 0){
    80004a26:	40dc                	lw	a5,4(s1)
    80004a28:	cf99                	beqz	a5,80004a46 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a2a:	02848493          	addi	s1,s1,40
    80004a2e:	fee49ce3          	bne	s1,a4,80004a26 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a32:	0001d517          	auipc	a0,0x1d
    80004a36:	26650513          	addi	a0,a0,614 # 80021c98 <ftable>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
  return 0;
    80004a42:	4481                	li	s1,0
    80004a44:	a819                	j	80004a5a <filealloc+0x5e>
      f->ref = 1;
    80004a46:	4785                	li	a5,1
    80004a48:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a4a:	0001d517          	auipc	a0,0x1d
    80004a4e:	24e50513          	addi	a0,a0,590 # 80021c98 <ftable>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	238080e7          	jalr	568(ra) # 80000c8a <release>
}
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	60e2                	ld	ra,24(sp)
    80004a5e:	6442                	ld	s0,16(sp)
    80004a60:	64a2                	ld	s1,8(sp)
    80004a62:	6105                	addi	sp,sp,32
    80004a64:	8082                	ret

0000000080004a66 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a66:	1101                	addi	sp,sp,-32
    80004a68:	ec06                	sd	ra,24(sp)
    80004a6a:	e822                	sd	s0,16(sp)
    80004a6c:	e426                	sd	s1,8(sp)
    80004a6e:	1000                	addi	s0,sp,32
    80004a70:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a72:	0001d517          	auipc	a0,0x1d
    80004a76:	22650513          	addi	a0,a0,550 # 80021c98 <ftable>
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	15c080e7          	jalr	348(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004a82:	40dc                	lw	a5,4(s1)
    80004a84:	02f05263          	blez	a5,80004aa8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a88:	2785                	addiw	a5,a5,1
    80004a8a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a8c:	0001d517          	auipc	a0,0x1d
    80004a90:	20c50513          	addi	a0,a0,524 # 80021c98 <ftable>
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	1f6080e7          	jalr	502(ra) # 80000c8a <release>
  return f;
}
    80004a9c:	8526                	mv	a0,s1
    80004a9e:	60e2                	ld	ra,24(sp)
    80004aa0:	6442                	ld	s0,16(sp)
    80004aa2:	64a2                	ld	s1,8(sp)
    80004aa4:	6105                	addi	sp,sp,32
    80004aa6:	8082                	ret
    panic("filedup");
    80004aa8:	00004517          	auipc	a0,0x4
    80004aac:	c1850513          	addi	a0,a0,-1000 # 800086c0 <syscalls+0x260>
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	a90080e7          	jalr	-1392(ra) # 80000540 <panic>

0000000080004ab8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ab8:	7139                	addi	sp,sp,-64
    80004aba:	fc06                	sd	ra,56(sp)
    80004abc:	f822                	sd	s0,48(sp)
    80004abe:	f426                	sd	s1,40(sp)
    80004ac0:	f04a                	sd	s2,32(sp)
    80004ac2:	ec4e                	sd	s3,24(sp)
    80004ac4:	e852                	sd	s4,16(sp)
    80004ac6:	e456                	sd	s5,8(sp)
    80004ac8:	0080                	addi	s0,sp,64
    80004aca:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004acc:	0001d517          	auipc	a0,0x1d
    80004ad0:	1cc50513          	addi	a0,a0,460 # 80021c98 <ftable>
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	102080e7          	jalr	258(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004adc:	40dc                	lw	a5,4(s1)
    80004ade:	06f05163          	blez	a5,80004b40 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ae2:	37fd                	addiw	a5,a5,-1
    80004ae4:	0007871b          	sext.w	a4,a5
    80004ae8:	c0dc                	sw	a5,4(s1)
    80004aea:	06e04363          	bgtz	a4,80004b50 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004aee:	0004a903          	lw	s2,0(s1)
    80004af2:	0094ca83          	lbu	s5,9(s1)
    80004af6:	0104ba03          	ld	s4,16(s1)
    80004afa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004afe:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b02:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b06:	0001d517          	auipc	a0,0x1d
    80004b0a:	19250513          	addi	a0,a0,402 # 80021c98 <ftable>
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	17c080e7          	jalr	380(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004b16:	4785                	li	a5,1
    80004b18:	04f90d63          	beq	s2,a5,80004b72 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b1c:	3979                	addiw	s2,s2,-2
    80004b1e:	4785                	li	a5,1
    80004b20:	0527e063          	bltu	a5,s2,80004b60 <fileclose+0xa8>
    begin_op();
    80004b24:	00000097          	auipc	ra,0x0
    80004b28:	acc080e7          	jalr	-1332(ra) # 800045f0 <begin_op>
    iput(ff.ip);
    80004b2c:	854e                	mv	a0,s3
    80004b2e:	fffff097          	auipc	ra,0xfffff
    80004b32:	2b0080e7          	jalr	688(ra) # 80003dde <iput>
    end_op();
    80004b36:	00000097          	auipc	ra,0x0
    80004b3a:	b38080e7          	jalr	-1224(ra) # 8000466e <end_op>
    80004b3e:	a00d                	j	80004b60 <fileclose+0xa8>
    panic("fileclose");
    80004b40:	00004517          	auipc	a0,0x4
    80004b44:	b8850513          	addi	a0,a0,-1144 # 800086c8 <syscalls+0x268>
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	9f8080e7          	jalr	-1544(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004b50:	0001d517          	auipc	a0,0x1d
    80004b54:	14850513          	addi	a0,a0,328 # 80021c98 <ftable>
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	132080e7          	jalr	306(ra) # 80000c8a <release>
  }
}
    80004b60:	70e2                	ld	ra,56(sp)
    80004b62:	7442                	ld	s0,48(sp)
    80004b64:	74a2                	ld	s1,40(sp)
    80004b66:	7902                	ld	s2,32(sp)
    80004b68:	69e2                	ld	s3,24(sp)
    80004b6a:	6a42                	ld	s4,16(sp)
    80004b6c:	6aa2                	ld	s5,8(sp)
    80004b6e:	6121                	addi	sp,sp,64
    80004b70:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b72:	85d6                	mv	a1,s5
    80004b74:	8552                	mv	a0,s4
    80004b76:	00000097          	auipc	ra,0x0
    80004b7a:	34c080e7          	jalr	844(ra) # 80004ec2 <pipeclose>
    80004b7e:	b7cd                	j	80004b60 <fileclose+0xa8>

0000000080004b80 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b80:	715d                	addi	sp,sp,-80
    80004b82:	e486                	sd	ra,72(sp)
    80004b84:	e0a2                	sd	s0,64(sp)
    80004b86:	fc26                	sd	s1,56(sp)
    80004b88:	f84a                	sd	s2,48(sp)
    80004b8a:	f44e                	sd	s3,40(sp)
    80004b8c:	0880                	addi	s0,sp,80
    80004b8e:	84aa                	mv	s1,a0
    80004b90:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	e1a080e7          	jalr	-486(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b9a:	409c                	lw	a5,0(s1)
    80004b9c:	37f9                	addiw	a5,a5,-2
    80004b9e:	4705                	li	a4,1
    80004ba0:	04f76763          	bltu	a4,a5,80004bee <filestat+0x6e>
    80004ba4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ba6:	6c88                	ld	a0,24(s1)
    80004ba8:	fffff097          	auipc	ra,0xfffff
    80004bac:	07c080e7          	jalr	124(ra) # 80003c24 <ilock>
    stati(f->ip, &st);
    80004bb0:	fb840593          	addi	a1,s0,-72
    80004bb4:	6c88                	ld	a0,24(s1)
    80004bb6:	fffff097          	auipc	ra,0xfffff
    80004bba:	2f8080e7          	jalr	760(ra) # 80003eae <stati>
    iunlock(f->ip);
    80004bbe:	6c88                	ld	a0,24(s1)
    80004bc0:	fffff097          	auipc	ra,0xfffff
    80004bc4:	126080e7          	jalr	294(ra) # 80003ce6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bc8:	46e1                	li	a3,24
    80004bca:	fb840613          	addi	a2,s0,-72
    80004bce:	85ce                	mv	a1,s3
    80004bd0:	05093503          	ld	a0,80(s2)
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	a98080e7          	jalr	-1384(ra) # 8000166c <copyout>
    80004bdc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004be0:	60a6                	ld	ra,72(sp)
    80004be2:	6406                	ld	s0,64(sp)
    80004be4:	74e2                	ld	s1,56(sp)
    80004be6:	7942                	ld	s2,48(sp)
    80004be8:	79a2                	ld	s3,40(sp)
    80004bea:	6161                	addi	sp,sp,80
    80004bec:	8082                	ret
  return -1;
    80004bee:	557d                	li	a0,-1
    80004bf0:	bfc5                	j	80004be0 <filestat+0x60>

0000000080004bf2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bf2:	7179                	addi	sp,sp,-48
    80004bf4:	f406                	sd	ra,40(sp)
    80004bf6:	f022                	sd	s0,32(sp)
    80004bf8:	ec26                	sd	s1,24(sp)
    80004bfa:	e84a                	sd	s2,16(sp)
    80004bfc:	e44e                	sd	s3,8(sp)
    80004bfe:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c00:	00854783          	lbu	a5,8(a0)
    80004c04:	c3d5                	beqz	a5,80004ca8 <fileread+0xb6>
    80004c06:	84aa                	mv	s1,a0
    80004c08:	89ae                	mv	s3,a1
    80004c0a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c0c:	411c                	lw	a5,0(a0)
    80004c0e:	4705                	li	a4,1
    80004c10:	04e78963          	beq	a5,a4,80004c62 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c14:	470d                	li	a4,3
    80004c16:	04e78d63          	beq	a5,a4,80004c70 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c1a:	4709                	li	a4,2
    80004c1c:	06e79e63          	bne	a5,a4,80004c98 <fileread+0xa6>
    ilock(f->ip);
    80004c20:	6d08                	ld	a0,24(a0)
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	002080e7          	jalr	2(ra) # 80003c24 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c2a:	874a                	mv	a4,s2
    80004c2c:	5094                	lw	a3,32(s1)
    80004c2e:	864e                	mv	a2,s3
    80004c30:	4585                	li	a1,1
    80004c32:	6c88                	ld	a0,24(s1)
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	2a4080e7          	jalr	676(ra) # 80003ed8 <readi>
    80004c3c:	892a                	mv	s2,a0
    80004c3e:	00a05563          	blez	a0,80004c48 <fileread+0x56>
      f->off += r;
    80004c42:	509c                	lw	a5,32(s1)
    80004c44:	9fa9                	addw	a5,a5,a0
    80004c46:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c48:	6c88                	ld	a0,24(s1)
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	09c080e7          	jalr	156(ra) # 80003ce6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c52:	854a                	mv	a0,s2
    80004c54:	70a2                	ld	ra,40(sp)
    80004c56:	7402                	ld	s0,32(sp)
    80004c58:	64e2                	ld	s1,24(sp)
    80004c5a:	6942                	ld	s2,16(sp)
    80004c5c:	69a2                	ld	s3,8(sp)
    80004c5e:	6145                	addi	sp,sp,48
    80004c60:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c62:	6908                	ld	a0,16(a0)
    80004c64:	00000097          	auipc	ra,0x0
    80004c68:	3c6080e7          	jalr	966(ra) # 8000502a <piperead>
    80004c6c:	892a                	mv	s2,a0
    80004c6e:	b7d5                	j	80004c52 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c70:	02451783          	lh	a5,36(a0)
    80004c74:	03079693          	slli	a3,a5,0x30
    80004c78:	92c1                	srli	a3,a3,0x30
    80004c7a:	4725                	li	a4,9
    80004c7c:	02d76863          	bltu	a4,a3,80004cac <fileread+0xba>
    80004c80:	0792                	slli	a5,a5,0x4
    80004c82:	0001d717          	auipc	a4,0x1d
    80004c86:	f7670713          	addi	a4,a4,-138 # 80021bf8 <devsw>
    80004c8a:	97ba                	add	a5,a5,a4
    80004c8c:	639c                	ld	a5,0(a5)
    80004c8e:	c38d                	beqz	a5,80004cb0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c90:	4505                	li	a0,1
    80004c92:	9782                	jalr	a5
    80004c94:	892a                	mv	s2,a0
    80004c96:	bf75                	j	80004c52 <fileread+0x60>
    panic("fileread");
    80004c98:	00004517          	auipc	a0,0x4
    80004c9c:	a4050513          	addi	a0,a0,-1472 # 800086d8 <syscalls+0x278>
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	8a0080e7          	jalr	-1888(ra) # 80000540 <panic>
    return -1;
    80004ca8:	597d                	li	s2,-1
    80004caa:	b765                	j	80004c52 <fileread+0x60>
      return -1;
    80004cac:	597d                	li	s2,-1
    80004cae:	b755                	j	80004c52 <fileread+0x60>
    80004cb0:	597d                	li	s2,-1
    80004cb2:	b745                	j	80004c52 <fileread+0x60>

0000000080004cb4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cb4:	715d                	addi	sp,sp,-80
    80004cb6:	e486                	sd	ra,72(sp)
    80004cb8:	e0a2                	sd	s0,64(sp)
    80004cba:	fc26                	sd	s1,56(sp)
    80004cbc:	f84a                	sd	s2,48(sp)
    80004cbe:	f44e                	sd	s3,40(sp)
    80004cc0:	f052                	sd	s4,32(sp)
    80004cc2:	ec56                	sd	s5,24(sp)
    80004cc4:	e85a                	sd	s6,16(sp)
    80004cc6:	e45e                	sd	s7,8(sp)
    80004cc8:	e062                	sd	s8,0(sp)
    80004cca:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ccc:	00954783          	lbu	a5,9(a0)
    80004cd0:	10078663          	beqz	a5,80004ddc <filewrite+0x128>
    80004cd4:	892a                	mv	s2,a0
    80004cd6:	8b2e                	mv	s6,a1
    80004cd8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cda:	411c                	lw	a5,0(a0)
    80004cdc:	4705                	li	a4,1
    80004cde:	02e78263          	beq	a5,a4,80004d02 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ce2:	470d                	li	a4,3
    80004ce4:	02e78663          	beq	a5,a4,80004d10 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ce8:	4709                	li	a4,2
    80004cea:	0ee79163          	bne	a5,a4,80004dcc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cee:	0ac05d63          	blez	a2,80004da8 <filewrite+0xf4>
    int i = 0;
    80004cf2:	4981                	li	s3,0
    80004cf4:	6b85                	lui	s7,0x1
    80004cf6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004cfa:	6c05                	lui	s8,0x1
    80004cfc:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004d00:	a861                	j	80004d98 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d02:	6908                	ld	a0,16(a0)
    80004d04:	00000097          	auipc	ra,0x0
    80004d08:	22e080e7          	jalr	558(ra) # 80004f32 <pipewrite>
    80004d0c:	8a2a                	mv	s4,a0
    80004d0e:	a045                	j	80004dae <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d10:	02451783          	lh	a5,36(a0)
    80004d14:	03079693          	slli	a3,a5,0x30
    80004d18:	92c1                	srli	a3,a3,0x30
    80004d1a:	4725                	li	a4,9
    80004d1c:	0cd76263          	bltu	a4,a3,80004de0 <filewrite+0x12c>
    80004d20:	0792                	slli	a5,a5,0x4
    80004d22:	0001d717          	auipc	a4,0x1d
    80004d26:	ed670713          	addi	a4,a4,-298 # 80021bf8 <devsw>
    80004d2a:	97ba                	add	a5,a5,a4
    80004d2c:	679c                	ld	a5,8(a5)
    80004d2e:	cbdd                	beqz	a5,80004de4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d30:	4505                	li	a0,1
    80004d32:	9782                	jalr	a5
    80004d34:	8a2a                	mv	s4,a0
    80004d36:	a8a5                	j	80004dae <filewrite+0xfa>
    80004d38:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d3c:	00000097          	auipc	ra,0x0
    80004d40:	8b4080e7          	jalr	-1868(ra) # 800045f0 <begin_op>
      ilock(f->ip);
    80004d44:	01893503          	ld	a0,24(s2)
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	edc080e7          	jalr	-292(ra) # 80003c24 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d50:	8756                	mv	a4,s5
    80004d52:	02092683          	lw	a3,32(s2)
    80004d56:	01698633          	add	a2,s3,s6
    80004d5a:	4585                	li	a1,1
    80004d5c:	01893503          	ld	a0,24(s2)
    80004d60:	fffff097          	auipc	ra,0xfffff
    80004d64:	270080e7          	jalr	624(ra) # 80003fd0 <writei>
    80004d68:	84aa                	mv	s1,a0
    80004d6a:	00a05763          	blez	a0,80004d78 <filewrite+0xc4>
        f->off += r;
    80004d6e:	02092783          	lw	a5,32(s2)
    80004d72:	9fa9                	addw	a5,a5,a0
    80004d74:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d78:	01893503          	ld	a0,24(s2)
    80004d7c:	fffff097          	auipc	ra,0xfffff
    80004d80:	f6a080e7          	jalr	-150(ra) # 80003ce6 <iunlock>
      end_op();
    80004d84:	00000097          	auipc	ra,0x0
    80004d88:	8ea080e7          	jalr	-1814(ra) # 8000466e <end_op>

      if(r != n1){
    80004d8c:	009a9f63          	bne	s5,s1,80004daa <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d90:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d94:	0149db63          	bge	s3,s4,80004daa <filewrite+0xf6>
      int n1 = n - i;
    80004d98:	413a04bb          	subw	s1,s4,s3
    80004d9c:	0004879b          	sext.w	a5,s1
    80004da0:	f8fbdce3          	bge	s7,a5,80004d38 <filewrite+0x84>
    80004da4:	84e2                	mv	s1,s8
    80004da6:	bf49                	j	80004d38 <filewrite+0x84>
    int i = 0;
    80004da8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004daa:	013a1f63          	bne	s4,s3,80004dc8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dae:	8552                	mv	a0,s4
    80004db0:	60a6                	ld	ra,72(sp)
    80004db2:	6406                	ld	s0,64(sp)
    80004db4:	74e2                	ld	s1,56(sp)
    80004db6:	7942                	ld	s2,48(sp)
    80004db8:	79a2                	ld	s3,40(sp)
    80004dba:	7a02                	ld	s4,32(sp)
    80004dbc:	6ae2                	ld	s5,24(sp)
    80004dbe:	6b42                	ld	s6,16(sp)
    80004dc0:	6ba2                	ld	s7,8(sp)
    80004dc2:	6c02                	ld	s8,0(sp)
    80004dc4:	6161                	addi	sp,sp,80
    80004dc6:	8082                	ret
    ret = (i == n ? n : -1);
    80004dc8:	5a7d                	li	s4,-1
    80004dca:	b7d5                	j	80004dae <filewrite+0xfa>
    panic("filewrite");
    80004dcc:	00004517          	auipc	a0,0x4
    80004dd0:	91c50513          	addi	a0,a0,-1764 # 800086e8 <syscalls+0x288>
    80004dd4:	ffffb097          	auipc	ra,0xffffb
    80004dd8:	76c080e7          	jalr	1900(ra) # 80000540 <panic>
    return -1;
    80004ddc:	5a7d                	li	s4,-1
    80004dde:	bfc1                	j	80004dae <filewrite+0xfa>
      return -1;
    80004de0:	5a7d                	li	s4,-1
    80004de2:	b7f1                	j	80004dae <filewrite+0xfa>
    80004de4:	5a7d                	li	s4,-1
    80004de6:	b7e1                	j	80004dae <filewrite+0xfa>

0000000080004de8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004de8:	7179                	addi	sp,sp,-48
    80004dea:	f406                	sd	ra,40(sp)
    80004dec:	f022                	sd	s0,32(sp)
    80004dee:	ec26                	sd	s1,24(sp)
    80004df0:	e84a                	sd	s2,16(sp)
    80004df2:	e44e                	sd	s3,8(sp)
    80004df4:	e052                	sd	s4,0(sp)
    80004df6:	1800                	addi	s0,sp,48
    80004df8:	84aa                	mv	s1,a0
    80004dfa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dfc:	0005b023          	sd	zero,0(a1)
    80004e00:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e04:	00000097          	auipc	ra,0x0
    80004e08:	bf8080e7          	jalr	-1032(ra) # 800049fc <filealloc>
    80004e0c:	e088                	sd	a0,0(s1)
    80004e0e:	c551                	beqz	a0,80004e9a <pipealloc+0xb2>
    80004e10:	00000097          	auipc	ra,0x0
    80004e14:	bec080e7          	jalr	-1044(ra) # 800049fc <filealloc>
    80004e18:	00aa3023          	sd	a0,0(s4)
    80004e1c:	c92d                	beqz	a0,80004e8e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	cc8080e7          	jalr	-824(ra) # 80000ae6 <kalloc>
    80004e26:	892a                	mv	s2,a0
    80004e28:	c125                	beqz	a0,80004e88 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e2a:	4985                	li	s3,1
    80004e2c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e30:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e34:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e38:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e3c:	00004597          	auipc	a1,0x4
    80004e40:	8bc58593          	addi	a1,a1,-1860 # 800086f8 <syscalls+0x298>
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	d02080e7          	jalr	-766(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004e4c:	609c                	ld	a5,0(s1)
    80004e4e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e52:	609c                	ld	a5,0(s1)
    80004e54:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e58:	609c                	ld	a5,0(s1)
    80004e5a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e5e:	609c                	ld	a5,0(s1)
    80004e60:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e64:	000a3783          	ld	a5,0(s4)
    80004e68:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e6c:	000a3783          	ld	a5,0(s4)
    80004e70:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e74:	000a3783          	ld	a5,0(s4)
    80004e78:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e7c:	000a3783          	ld	a5,0(s4)
    80004e80:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e84:	4501                	li	a0,0
    80004e86:	a025                	j	80004eae <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e88:	6088                	ld	a0,0(s1)
    80004e8a:	e501                	bnez	a0,80004e92 <pipealloc+0xaa>
    80004e8c:	a039                	j	80004e9a <pipealloc+0xb2>
    80004e8e:	6088                	ld	a0,0(s1)
    80004e90:	c51d                	beqz	a0,80004ebe <pipealloc+0xd6>
    fileclose(*f0);
    80004e92:	00000097          	auipc	ra,0x0
    80004e96:	c26080e7          	jalr	-986(ra) # 80004ab8 <fileclose>
  if(*f1)
    80004e9a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e9e:	557d                	li	a0,-1
  if(*f1)
    80004ea0:	c799                	beqz	a5,80004eae <pipealloc+0xc6>
    fileclose(*f1);
    80004ea2:	853e                	mv	a0,a5
    80004ea4:	00000097          	auipc	ra,0x0
    80004ea8:	c14080e7          	jalr	-1004(ra) # 80004ab8 <fileclose>
  return -1;
    80004eac:	557d                	li	a0,-1
}
    80004eae:	70a2                	ld	ra,40(sp)
    80004eb0:	7402                	ld	s0,32(sp)
    80004eb2:	64e2                	ld	s1,24(sp)
    80004eb4:	6942                	ld	s2,16(sp)
    80004eb6:	69a2                	ld	s3,8(sp)
    80004eb8:	6a02                	ld	s4,0(sp)
    80004eba:	6145                	addi	sp,sp,48
    80004ebc:	8082                	ret
  return -1;
    80004ebe:	557d                	li	a0,-1
    80004ec0:	b7fd                	j	80004eae <pipealloc+0xc6>

0000000080004ec2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ec2:	1101                	addi	sp,sp,-32
    80004ec4:	ec06                	sd	ra,24(sp)
    80004ec6:	e822                	sd	s0,16(sp)
    80004ec8:	e426                	sd	s1,8(sp)
    80004eca:	e04a                	sd	s2,0(sp)
    80004ecc:	1000                	addi	s0,sp,32
    80004ece:	84aa                	mv	s1,a0
    80004ed0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	d04080e7          	jalr	-764(ra) # 80000bd6 <acquire>
  if(writable){
    80004eda:	02090d63          	beqz	s2,80004f14 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ede:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ee2:	21848513          	addi	a0,s1,536
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	35c080e7          	jalr	860(ra) # 80002242 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004eee:	2204b783          	ld	a5,544(s1)
    80004ef2:	eb95                	bnez	a5,80004f26 <pipeclose+0x64>
    release(&pi->lock);
    80004ef4:	8526                	mv	a0,s1
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	d94080e7          	jalr	-620(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004efe:	8526                	mv	a0,s1
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	ae8080e7          	jalr	-1304(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004f08:	60e2                	ld	ra,24(sp)
    80004f0a:	6442                	ld	s0,16(sp)
    80004f0c:	64a2                	ld	s1,8(sp)
    80004f0e:	6902                	ld	s2,0(sp)
    80004f10:	6105                	addi	sp,sp,32
    80004f12:	8082                	ret
    pi->readopen = 0;
    80004f14:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f18:	21c48513          	addi	a0,s1,540
    80004f1c:	ffffd097          	auipc	ra,0xffffd
    80004f20:	326080e7          	jalr	806(ra) # 80002242 <wakeup>
    80004f24:	b7e9                	j	80004eee <pipeclose+0x2c>
    release(&pi->lock);
    80004f26:	8526                	mv	a0,s1
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	d62080e7          	jalr	-670(ra) # 80000c8a <release>
}
    80004f30:	bfe1                	j	80004f08 <pipeclose+0x46>

0000000080004f32 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f32:	711d                	addi	sp,sp,-96
    80004f34:	ec86                	sd	ra,88(sp)
    80004f36:	e8a2                	sd	s0,80(sp)
    80004f38:	e4a6                	sd	s1,72(sp)
    80004f3a:	e0ca                	sd	s2,64(sp)
    80004f3c:	fc4e                	sd	s3,56(sp)
    80004f3e:	f852                	sd	s4,48(sp)
    80004f40:	f456                	sd	s5,40(sp)
    80004f42:	f05a                	sd	s6,32(sp)
    80004f44:	ec5e                	sd	s7,24(sp)
    80004f46:	e862                	sd	s8,16(sp)
    80004f48:	1080                	addi	s0,sp,96
    80004f4a:	84aa                	mv	s1,a0
    80004f4c:	8aae                	mv	s5,a1
    80004f4e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80004f58:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f5a:	8526                	mv	a0,s1
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	c7a080e7          	jalr	-902(ra) # 80000bd6 <acquire>
  while(i < n){
    80004f64:	0b405663          	blez	s4,80005010 <pipewrite+0xde>
  int i = 0;
    80004f68:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f6a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f6c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f70:	21c48b93          	addi	s7,s1,540
    80004f74:	a089                	j	80004fb6 <pipewrite+0x84>
      release(&pi->lock);
    80004f76:	8526                	mv	a0,s1
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	d12080e7          	jalr	-750(ra) # 80000c8a <release>
      return -1;
    80004f80:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f82:	854a                	mv	a0,s2
    80004f84:	60e6                	ld	ra,88(sp)
    80004f86:	6446                	ld	s0,80(sp)
    80004f88:	64a6                	ld	s1,72(sp)
    80004f8a:	6906                	ld	s2,64(sp)
    80004f8c:	79e2                	ld	s3,56(sp)
    80004f8e:	7a42                	ld	s4,48(sp)
    80004f90:	7aa2                	ld	s5,40(sp)
    80004f92:	7b02                	ld	s6,32(sp)
    80004f94:	6be2                	ld	s7,24(sp)
    80004f96:	6c42                	ld	s8,16(sp)
    80004f98:	6125                	addi	sp,sp,96
    80004f9a:	8082                	ret
      wakeup(&pi->nread);
    80004f9c:	8562                	mv	a0,s8
    80004f9e:	ffffd097          	auipc	ra,0xffffd
    80004fa2:	2a4080e7          	jalr	676(ra) # 80002242 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fa6:	85a6                	mv	a1,s1
    80004fa8:	855e                	mv	a0,s7
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	234080e7          	jalr	564(ra) # 800021de <sleep>
  while(i < n){
    80004fb2:	07495063          	bge	s2,s4,80005012 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004fb6:	2204a783          	lw	a5,544(s1)
    80004fba:	dfd5                	beqz	a5,80004f76 <pipewrite+0x44>
    80004fbc:	854e                	mv	a0,s3
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	4d4080e7          	jalr	1236(ra) # 80002492 <killed>
    80004fc6:	f945                	bnez	a0,80004f76 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fc8:	2184a783          	lw	a5,536(s1)
    80004fcc:	21c4a703          	lw	a4,540(s1)
    80004fd0:	2007879b          	addiw	a5,a5,512
    80004fd4:	fcf704e3          	beq	a4,a5,80004f9c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fd8:	4685                	li	a3,1
    80004fda:	01590633          	add	a2,s2,s5
    80004fde:	faf40593          	addi	a1,s0,-81
    80004fe2:	0509b503          	ld	a0,80(s3)
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	712080e7          	jalr	1810(ra) # 800016f8 <copyin>
    80004fee:	03650263          	beq	a0,s6,80005012 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ff2:	21c4a783          	lw	a5,540(s1)
    80004ff6:	0017871b          	addiw	a4,a5,1
    80004ffa:	20e4ae23          	sw	a4,540(s1)
    80004ffe:	1ff7f793          	andi	a5,a5,511
    80005002:	97a6                	add	a5,a5,s1
    80005004:	faf44703          	lbu	a4,-81(s0)
    80005008:	00e78c23          	sb	a4,24(a5)
      i++;
    8000500c:	2905                	addiw	s2,s2,1
    8000500e:	b755                	j	80004fb2 <pipewrite+0x80>
  int i = 0;
    80005010:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005012:	21848513          	addi	a0,s1,536
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	22c080e7          	jalr	556(ra) # 80002242 <wakeup>
  release(&pi->lock);
    8000501e:	8526                	mv	a0,s1
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	c6a080e7          	jalr	-918(ra) # 80000c8a <release>
  return i;
    80005028:	bfa9                	j	80004f82 <pipewrite+0x50>

000000008000502a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000502a:	715d                	addi	sp,sp,-80
    8000502c:	e486                	sd	ra,72(sp)
    8000502e:	e0a2                	sd	s0,64(sp)
    80005030:	fc26                	sd	s1,56(sp)
    80005032:	f84a                	sd	s2,48(sp)
    80005034:	f44e                	sd	s3,40(sp)
    80005036:	f052                	sd	s4,32(sp)
    80005038:	ec56                	sd	s5,24(sp)
    8000503a:	e85a                	sd	s6,16(sp)
    8000503c:	0880                	addi	s0,sp,80
    8000503e:	84aa                	mv	s1,a0
    80005040:	892e                	mv	s2,a1
    80005042:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	968080e7          	jalr	-1688(ra) # 800019ac <myproc>
    8000504c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000504e:	8526                	mv	a0,s1
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	b86080e7          	jalr	-1146(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005058:	2184a703          	lw	a4,536(s1)
    8000505c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005060:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005064:	02f71763          	bne	a4,a5,80005092 <piperead+0x68>
    80005068:	2244a783          	lw	a5,548(s1)
    8000506c:	c39d                	beqz	a5,80005092 <piperead+0x68>
    if(killed(pr)){
    8000506e:	8552                	mv	a0,s4
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	422080e7          	jalr	1058(ra) # 80002492 <killed>
    80005078:	e949                	bnez	a0,8000510a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000507a:	85a6                	mv	a1,s1
    8000507c:	854e                	mv	a0,s3
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	160080e7          	jalr	352(ra) # 800021de <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005086:	2184a703          	lw	a4,536(s1)
    8000508a:	21c4a783          	lw	a5,540(s1)
    8000508e:	fcf70de3          	beq	a4,a5,80005068 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005092:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005094:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005096:	05505463          	blez	s5,800050de <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000509a:	2184a783          	lw	a5,536(s1)
    8000509e:	21c4a703          	lw	a4,540(s1)
    800050a2:	02f70e63          	beq	a4,a5,800050de <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050a6:	0017871b          	addiw	a4,a5,1
    800050aa:	20e4ac23          	sw	a4,536(s1)
    800050ae:	1ff7f793          	andi	a5,a5,511
    800050b2:	97a6                	add	a5,a5,s1
    800050b4:	0187c783          	lbu	a5,24(a5)
    800050b8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050bc:	4685                	li	a3,1
    800050be:	fbf40613          	addi	a2,s0,-65
    800050c2:	85ca                	mv	a1,s2
    800050c4:	050a3503          	ld	a0,80(s4)
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	5a4080e7          	jalr	1444(ra) # 8000166c <copyout>
    800050d0:	01650763          	beq	a0,s6,800050de <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050d4:	2985                	addiw	s3,s3,1
    800050d6:	0905                	addi	s2,s2,1
    800050d8:	fd3a91e3          	bne	s5,s3,8000509a <piperead+0x70>
    800050dc:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050de:	21c48513          	addi	a0,s1,540
    800050e2:	ffffd097          	auipc	ra,0xffffd
    800050e6:	160080e7          	jalr	352(ra) # 80002242 <wakeup>
  release(&pi->lock);
    800050ea:	8526                	mv	a0,s1
    800050ec:	ffffc097          	auipc	ra,0xffffc
    800050f0:	b9e080e7          	jalr	-1122(ra) # 80000c8a <release>
  return i;
}
    800050f4:	854e                	mv	a0,s3
    800050f6:	60a6                	ld	ra,72(sp)
    800050f8:	6406                	ld	s0,64(sp)
    800050fa:	74e2                	ld	s1,56(sp)
    800050fc:	7942                	ld	s2,48(sp)
    800050fe:	79a2                	ld	s3,40(sp)
    80005100:	7a02                	ld	s4,32(sp)
    80005102:	6ae2                	ld	s5,24(sp)
    80005104:	6b42                	ld	s6,16(sp)
    80005106:	6161                	addi	sp,sp,80
    80005108:	8082                	ret
      release(&pi->lock);
    8000510a:	8526                	mv	a0,s1
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	b7e080e7          	jalr	-1154(ra) # 80000c8a <release>
      return -1;
    80005114:	59fd                	li	s3,-1
    80005116:	bff9                	j	800050f4 <piperead+0xca>

0000000080005118 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005118:	1141                	addi	sp,sp,-16
    8000511a:	e422                	sd	s0,8(sp)
    8000511c:	0800                	addi	s0,sp,16
    8000511e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005120:	8905                	andi	a0,a0,1
    80005122:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005124:	8b89                	andi	a5,a5,2
    80005126:	c399                	beqz	a5,8000512c <flags2perm+0x14>
      perm |= PTE_W;
    80005128:	00456513          	ori	a0,a0,4
    return perm;
}
    8000512c:	6422                	ld	s0,8(sp)
    8000512e:	0141                	addi	sp,sp,16
    80005130:	8082                	ret

0000000080005132 <exec>:

int
exec(char *path, char **argv)
{
    80005132:	de010113          	addi	sp,sp,-544
    80005136:	20113c23          	sd	ra,536(sp)
    8000513a:	20813823          	sd	s0,528(sp)
    8000513e:	20913423          	sd	s1,520(sp)
    80005142:	21213023          	sd	s2,512(sp)
    80005146:	ffce                	sd	s3,504(sp)
    80005148:	fbd2                	sd	s4,496(sp)
    8000514a:	f7d6                	sd	s5,488(sp)
    8000514c:	f3da                	sd	s6,480(sp)
    8000514e:	efde                	sd	s7,472(sp)
    80005150:	ebe2                	sd	s8,464(sp)
    80005152:	e7e6                	sd	s9,456(sp)
    80005154:	e3ea                	sd	s10,448(sp)
    80005156:	ff6e                	sd	s11,440(sp)
    80005158:	1400                	addi	s0,sp,544
    8000515a:	892a                	mv	s2,a0
    8000515c:	dea43423          	sd	a0,-536(s0)
    80005160:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005164:	ffffd097          	auipc	ra,0xffffd
    80005168:	848080e7          	jalr	-1976(ra) # 800019ac <myproc>
    8000516c:	84aa                	mv	s1,a0

  begin_op();
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	482080e7          	jalr	1154(ra) # 800045f0 <begin_op>

  if((ip = namei(path)) == 0){
    80005176:	854a                	mv	a0,s2
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	258080e7          	jalr	600(ra) # 800043d0 <namei>
    80005180:	c93d                	beqz	a0,800051f6 <exec+0xc4>
    80005182:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	aa0080e7          	jalr	-1376(ra) # 80003c24 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000518c:	04000713          	li	a4,64
    80005190:	4681                	li	a3,0
    80005192:	e5040613          	addi	a2,s0,-432
    80005196:	4581                	li	a1,0
    80005198:	8556                	mv	a0,s5
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	d3e080e7          	jalr	-706(ra) # 80003ed8 <readi>
    800051a2:	04000793          	li	a5,64
    800051a6:	00f51a63          	bne	a0,a5,800051ba <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800051aa:	e5042703          	lw	a4,-432(s0)
    800051ae:	464c47b7          	lui	a5,0x464c4
    800051b2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051b6:	04f70663          	beq	a4,a5,80005202 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051ba:	8556                	mv	a0,s5
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	cca080e7          	jalr	-822(ra) # 80003e86 <iunlockput>
    end_op();
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	4aa080e7          	jalr	1194(ra) # 8000466e <end_op>
  }
  return -1;
    800051cc:	557d                	li	a0,-1
}
    800051ce:	21813083          	ld	ra,536(sp)
    800051d2:	21013403          	ld	s0,528(sp)
    800051d6:	20813483          	ld	s1,520(sp)
    800051da:	20013903          	ld	s2,512(sp)
    800051de:	79fe                	ld	s3,504(sp)
    800051e0:	7a5e                	ld	s4,496(sp)
    800051e2:	7abe                	ld	s5,488(sp)
    800051e4:	7b1e                	ld	s6,480(sp)
    800051e6:	6bfe                	ld	s7,472(sp)
    800051e8:	6c5e                	ld	s8,464(sp)
    800051ea:	6cbe                	ld	s9,456(sp)
    800051ec:	6d1e                	ld	s10,448(sp)
    800051ee:	7dfa                	ld	s11,440(sp)
    800051f0:	22010113          	addi	sp,sp,544
    800051f4:	8082                	ret
    end_op();
    800051f6:	fffff097          	auipc	ra,0xfffff
    800051fa:	478080e7          	jalr	1144(ra) # 8000466e <end_op>
    return -1;
    800051fe:	557d                	li	a0,-1
    80005200:	b7f9                	j	800051ce <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005202:	8526                	mv	a0,s1
    80005204:	ffffd097          	auipc	ra,0xffffd
    80005208:	86c080e7          	jalr	-1940(ra) # 80001a70 <proc_pagetable>
    8000520c:	8b2a                	mv	s6,a0
    8000520e:	d555                	beqz	a0,800051ba <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005210:	e7042783          	lw	a5,-400(s0)
    80005214:	e8845703          	lhu	a4,-376(s0)
    80005218:	c735                	beqz	a4,80005284 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000521a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000521c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005220:	6a05                	lui	s4,0x1
    80005222:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005226:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000522a:	6d85                	lui	s11,0x1
    8000522c:	7d7d                	lui	s10,0xfffff
    8000522e:	ac3d                	j	8000546c <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005230:	00003517          	auipc	a0,0x3
    80005234:	4d050513          	addi	a0,a0,1232 # 80008700 <syscalls+0x2a0>
    80005238:	ffffb097          	auipc	ra,0xffffb
    8000523c:	308080e7          	jalr	776(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005240:	874a                	mv	a4,s2
    80005242:	009c86bb          	addw	a3,s9,s1
    80005246:	4581                	li	a1,0
    80005248:	8556                	mv	a0,s5
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	c8e080e7          	jalr	-882(ra) # 80003ed8 <readi>
    80005252:	2501                	sext.w	a0,a0
    80005254:	1aa91963          	bne	s2,a0,80005406 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005258:	009d84bb          	addw	s1,s11,s1
    8000525c:	013d09bb          	addw	s3,s10,s3
    80005260:	1f74f663          	bgeu	s1,s7,8000544c <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005264:	02049593          	slli	a1,s1,0x20
    80005268:	9181                	srli	a1,a1,0x20
    8000526a:	95e2                	add	a1,a1,s8
    8000526c:	855a                	mv	a0,s6
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	dee080e7          	jalr	-530(ra) # 8000105c <walkaddr>
    80005276:	862a                	mv	a2,a0
    if(pa == 0)
    80005278:	dd45                	beqz	a0,80005230 <exec+0xfe>
      n = PGSIZE;
    8000527a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000527c:	fd49f2e3          	bgeu	s3,s4,80005240 <exec+0x10e>
      n = sz - i;
    80005280:	894e                	mv	s2,s3
    80005282:	bf7d                	j	80005240 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005284:	4901                	li	s2,0
  iunlockput(ip);
    80005286:	8556                	mv	a0,s5
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	bfe080e7          	jalr	-1026(ra) # 80003e86 <iunlockput>
  end_op();
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	3de080e7          	jalr	990(ra) # 8000466e <end_op>
  p = myproc();
    80005298:	ffffc097          	auipc	ra,0xffffc
    8000529c:	714080e7          	jalr	1812(ra) # 800019ac <myproc>
    800052a0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800052a2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052a6:	6785                	lui	a5,0x1
    800052a8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800052aa:	97ca                	add	a5,a5,s2
    800052ac:	777d                	lui	a4,0xfffff
    800052ae:	8ff9                	and	a5,a5,a4
    800052b0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052b4:	4691                	li	a3,4
    800052b6:	6609                	lui	a2,0x2
    800052b8:	963e                	add	a2,a2,a5
    800052ba:	85be                	mv	a1,a5
    800052bc:	855a                	mv	a0,s6
    800052be:	ffffc097          	auipc	ra,0xffffc
    800052c2:	152080e7          	jalr	338(ra) # 80001410 <uvmalloc>
    800052c6:	8c2a                	mv	s8,a0
  ip = 0;
    800052c8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052ca:	12050e63          	beqz	a0,80005406 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052ce:	75f9                	lui	a1,0xffffe
    800052d0:	95aa                	add	a1,a1,a0
    800052d2:	855a                	mv	a0,s6
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	366080e7          	jalr	870(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800052dc:	7afd                	lui	s5,0xfffff
    800052de:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800052e0:	df043783          	ld	a5,-528(s0)
    800052e4:	6388                	ld	a0,0(a5)
    800052e6:	c925                	beqz	a0,80005356 <exec+0x224>
    800052e8:	e9040993          	addi	s3,s0,-368
    800052ec:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052f0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052f2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052f4:	ffffc097          	auipc	ra,0xffffc
    800052f8:	b5a080e7          	jalr	-1190(ra) # 80000e4e <strlen>
    800052fc:	0015079b          	addiw	a5,a0,1
    80005300:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005304:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005308:	13596663          	bltu	s2,s5,80005434 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000530c:	df043d83          	ld	s11,-528(s0)
    80005310:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005314:	8552                	mv	a0,s4
    80005316:	ffffc097          	auipc	ra,0xffffc
    8000531a:	b38080e7          	jalr	-1224(ra) # 80000e4e <strlen>
    8000531e:	0015069b          	addiw	a3,a0,1
    80005322:	8652                	mv	a2,s4
    80005324:	85ca                	mv	a1,s2
    80005326:	855a                	mv	a0,s6
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	344080e7          	jalr	836(ra) # 8000166c <copyout>
    80005330:	10054663          	bltz	a0,8000543c <exec+0x30a>
    ustack[argc] = sp;
    80005334:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005338:	0485                	addi	s1,s1,1
    8000533a:	008d8793          	addi	a5,s11,8
    8000533e:	def43823          	sd	a5,-528(s0)
    80005342:	008db503          	ld	a0,8(s11)
    80005346:	c911                	beqz	a0,8000535a <exec+0x228>
    if(argc >= MAXARG)
    80005348:	09a1                	addi	s3,s3,8
    8000534a:	fb3c95e3          	bne	s9,s3,800052f4 <exec+0x1c2>
  sz = sz1;
    8000534e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005352:	4a81                	li	s5,0
    80005354:	a84d                	j	80005406 <exec+0x2d4>
  sp = sz;
    80005356:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005358:	4481                	li	s1,0
  ustack[argc] = 0;
    8000535a:	00349793          	slli	a5,s1,0x3
    8000535e:	f9078793          	addi	a5,a5,-112
    80005362:	97a2                	add	a5,a5,s0
    80005364:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005368:	00148693          	addi	a3,s1,1
    8000536c:	068e                	slli	a3,a3,0x3
    8000536e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005372:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005376:	01597663          	bgeu	s2,s5,80005382 <exec+0x250>
  sz = sz1;
    8000537a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000537e:	4a81                	li	s5,0
    80005380:	a059                	j	80005406 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005382:	e9040613          	addi	a2,s0,-368
    80005386:	85ca                	mv	a1,s2
    80005388:	855a                	mv	a0,s6
    8000538a:	ffffc097          	auipc	ra,0xffffc
    8000538e:	2e2080e7          	jalr	738(ra) # 8000166c <copyout>
    80005392:	0a054963          	bltz	a0,80005444 <exec+0x312>
  p->trapframe->a1 = sp;
    80005396:	058bb783          	ld	a5,88(s7)
    8000539a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000539e:	de843783          	ld	a5,-536(s0)
    800053a2:	0007c703          	lbu	a4,0(a5)
    800053a6:	cf11                	beqz	a4,800053c2 <exec+0x290>
    800053a8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053aa:	02f00693          	li	a3,47
    800053ae:	a039                	j	800053bc <exec+0x28a>
      last = s+1;
    800053b0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800053b4:	0785                	addi	a5,a5,1
    800053b6:	fff7c703          	lbu	a4,-1(a5)
    800053ba:	c701                	beqz	a4,800053c2 <exec+0x290>
    if(*s == '/')
    800053bc:	fed71ce3          	bne	a4,a3,800053b4 <exec+0x282>
    800053c0:	bfc5                	j	800053b0 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800053c2:	4641                	li	a2,16
    800053c4:	de843583          	ld	a1,-536(s0)
    800053c8:	158b8513          	addi	a0,s7,344
    800053cc:	ffffc097          	auipc	ra,0xffffc
    800053d0:	a50080e7          	jalr	-1456(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800053d4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800053d8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800053dc:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053e0:	058bb783          	ld	a5,88(s7)
    800053e4:	e6843703          	ld	a4,-408(s0)
    800053e8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053ea:	058bb783          	ld	a5,88(s7)
    800053ee:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053f2:	85ea                	mv	a1,s10
    800053f4:	ffffc097          	auipc	ra,0xffffc
    800053f8:	718080e7          	jalr	1816(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053fc:	0004851b          	sext.w	a0,s1
    80005400:	b3f9                	j	800051ce <exec+0x9c>
    80005402:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005406:	df843583          	ld	a1,-520(s0)
    8000540a:	855a                	mv	a0,s6
    8000540c:	ffffc097          	auipc	ra,0xffffc
    80005410:	700080e7          	jalr	1792(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80005414:	da0a93e3          	bnez	s5,800051ba <exec+0x88>
  return -1;
    80005418:	557d                	li	a0,-1
    8000541a:	bb55                	j	800051ce <exec+0x9c>
    8000541c:	df243c23          	sd	s2,-520(s0)
    80005420:	b7dd                	j	80005406 <exec+0x2d4>
    80005422:	df243c23          	sd	s2,-520(s0)
    80005426:	b7c5                	j	80005406 <exec+0x2d4>
    80005428:	df243c23          	sd	s2,-520(s0)
    8000542c:	bfe9                	j	80005406 <exec+0x2d4>
    8000542e:	df243c23          	sd	s2,-520(s0)
    80005432:	bfd1                	j	80005406 <exec+0x2d4>
  sz = sz1;
    80005434:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005438:	4a81                	li	s5,0
    8000543a:	b7f1                	j	80005406 <exec+0x2d4>
  sz = sz1;
    8000543c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005440:	4a81                	li	s5,0
    80005442:	b7d1                	j	80005406 <exec+0x2d4>
  sz = sz1;
    80005444:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005448:	4a81                	li	s5,0
    8000544a:	bf75                	j	80005406 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000544c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005450:	e0843783          	ld	a5,-504(s0)
    80005454:	0017869b          	addiw	a3,a5,1
    80005458:	e0d43423          	sd	a3,-504(s0)
    8000545c:	e0043783          	ld	a5,-512(s0)
    80005460:	0387879b          	addiw	a5,a5,56
    80005464:	e8845703          	lhu	a4,-376(s0)
    80005468:	e0e6dfe3          	bge	a3,a4,80005286 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000546c:	2781                	sext.w	a5,a5
    8000546e:	e0f43023          	sd	a5,-512(s0)
    80005472:	03800713          	li	a4,56
    80005476:	86be                	mv	a3,a5
    80005478:	e1840613          	addi	a2,s0,-488
    8000547c:	4581                	li	a1,0
    8000547e:	8556                	mv	a0,s5
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	a58080e7          	jalr	-1448(ra) # 80003ed8 <readi>
    80005488:	03800793          	li	a5,56
    8000548c:	f6f51be3          	bne	a0,a5,80005402 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005490:	e1842783          	lw	a5,-488(s0)
    80005494:	4705                	li	a4,1
    80005496:	fae79de3          	bne	a5,a4,80005450 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000549a:	e4043483          	ld	s1,-448(s0)
    8000549e:	e3843783          	ld	a5,-456(s0)
    800054a2:	f6f4ede3          	bltu	s1,a5,8000541c <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054a6:	e2843783          	ld	a5,-472(s0)
    800054aa:	94be                	add	s1,s1,a5
    800054ac:	f6f4ebe3          	bltu	s1,a5,80005422 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800054b0:	de043703          	ld	a4,-544(s0)
    800054b4:	8ff9                	and	a5,a5,a4
    800054b6:	fbad                	bnez	a5,80005428 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054b8:	e1c42503          	lw	a0,-484(s0)
    800054bc:	00000097          	auipc	ra,0x0
    800054c0:	c5c080e7          	jalr	-932(ra) # 80005118 <flags2perm>
    800054c4:	86aa                	mv	a3,a0
    800054c6:	8626                	mv	a2,s1
    800054c8:	85ca                	mv	a1,s2
    800054ca:	855a                	mv	a0,s6
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	f44080e7          	jalr	-188(ra) # 80001410 <uvmalloc>
    800054d4:	dea43c23          	sd	a0,-520(s0)
    800054d8:	d939                	beqz	a0,8000542e <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054da:	e2843c03          	ld	s8,-472(s0)
    800054de:	e2042c83          	lw	s9,-480(s0)
    800054e2:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054e6:	f60b83e3          	beqz	s7,8000544c <exec+0x31a>
    800054ea:	89de                	mv	s3,s7
    800054ec:	4481                	li	s1,0
    800054ee:	bb9d                	j	80005264 <exec+0x132>

00000000800054f0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054f0:	7179                	addi	sp,sp,-48
    800054f2:	f406                	sd	ra,40(sp)
    800054f4:	f022                	sd	s0,32(sp)
    800054f6:	ec26                	sd	s1,24(sp)
    800054f8:	e84a                	sd	s2,16(sp)
    800054fa:	1800                	addi	s0,sp,48
    800054fc:	892e                	mv	s2,a1
    800054fe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005500:	fdc40593          	addi	a1,s0,-36
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	a1c080e7          	jalr	-1508(ra) # 80002f20 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000550c:	fdc42703          	lw	a4,-36(s0)
    80005510:	47bd                	li	a5,15
    80005512:	02e7eb63          	bltu	a5,a4,80005548 <argfd+0x58>
    80005516:	ffffc097          	auipc	ra,0xffffc
    8000551a:	496080e7          	jalr	1174(ra) # 800019ac <myproc>
    8000551e:	fdc42703          	lw	a4,-36(s0)
    80005522:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc28a>
    80005526:	078e                	slli	a5,a5,0x3
    80005528:	953e                	add	a0,a0,a5
    8000552a:	611c                	ld	a5,0(a0)
    8000552c:	c385                	beqz	a5,8000554c <argfd+0x5c>
    return -1;
  if(pfd)
    8000552e:	00090463          	beqz	s2,80005536 <argfd+0x46>
    *pfd = fd;
    80005532:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005536:	4501                	li	a0,0
  if(pf)
    80005538:	c091                	beqz	s1,8000553c <argfd+0x4c>
    *pf = f;
    8000553a:	e09c                	sd	a5,0(s1)
}
    8000553c:	70a2                	ld	ra,40(sp)
    8000553e:	7402                	ld	s0,32(sp)
    80005540:	64e2                	ld	s1,24(sp)
    80005542:	6942                	ld	s2,16(sp)
    80005544:	6145                	addi	sp,sp,48
    80005546:	8082                	ret
    return -1;
    80005548:	557d                	li	a0,-1
    8000554a:	bfcd                	j	8000553c <argfd+0x4c>
    8000554c:	557d                	li	a0,-1
    8000554e:	b7fd                	j	8000553c <argfd+0x4c>

0000000080005550 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005550:	1101                	addi	sp,sp,-32
    80005552:	ec06                	sd	ra,24(sp)
    80005554:	e822                	sd	s0,16(sp)
    80005556:	e426                	sd	s1,8(sp)
    80005558:	1000                	addi	s0,sp,32
    8000555a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000555c:	ffffc097          	auipc	ra,0xffffc
    80005560:	450080e7          	jalr	1104(ra) # 800019ac <myproc>
    80005564:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005566:	0d050793          	addi	a5,a0,208
    8000556a:	4501                	li	a0,0
    8000556c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000556e:	6398                	ld	a4,0(a5)
    80005570:	cb19                	beqz	a4,80005586 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005572:	2505                	addiw	a0,a0,1
    80005574:	07a1                	addi	a5,a5,8
    80005576:	fed51ce3          	bne	a0,a3,8000556e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000557a:	557d                	li	a0,-1
}
    8000557c:	60e2                	ld	ra,24(sp)
    8000557e:	6442                	ld	s0,16(sp)
    80005580:	64a2                	ld	s1,8(sp)
    80005582:	6105                	addi	sp,sp,32
    80005584:	8082                	ret
      p->ofile[fd] = f;
    80005586:	01a50793          	addi	a5,a0,26
    8000558a:	078e                	slli	a5,a5,0x3
    8000558c:	963e                	add	a2,a2,a5
    8000558e:	e204                	sd	s1,0(a2)
      return fd;
    80005590:	b7f5                	j	8000557c <fdalloc+0x2c>

0000000080005592 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005592:	715d                	addi	sp,sp,-80
    80005594:	e486                	sd	ra,72(sp)
    80005596:	e0a2                	sd	s0,64(sp)
    80005598:	fc26                	sd	s1,56(sp)
    8000559a:	f84a                	sd	s2,48(sp)
    8000559c:	f44e                	sd	s3,40(sp)
    8000559e:	f052                	sd	s4,32(sp)
    800055a0:	ec56                	sd	s5,24(sp)
    800055a2:	e85a                	sd	s6,16(sp)
    800055a4:	0880                	addi	s0,sp,80
    800055a6:	8b2e                	mv	s6,a1
    800055a8:	89b2                	mv	s3,a2
    800055aa:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055ac:	fb040593          	addi	a1,s0,-80
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	e3e080e7          	jalr	-450(ra) # 800043ee <nameiparent>
    800055b8:	84aa                	mv	s1,a0
    800055ba:	14050f63          	beqz	a0,80005718 <create+0x186>
    return 0;

  ilock(dp);
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	666080e7          	jalr	1638(ra) # 80003c24 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055c6:	4601                	li	a2,0
    800055c8:	fb040593          	addi	a1,s0,-80
    800055cc:	8526                	mv	a0,s1
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	b3a080e7          	jalr	-1222(ra) # 80004108 <dirlookup>
    800055d6:	8aaa                	mv	s5,a0
    800055d8:	c931                	beqz	a0,8000562c <create+0x9a>
    iunlockput(dp);
    800055da:	8526                	mv	a0,s1
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	8aa080e7          	jalr	-1878(ra) # 80003e86 <iunlockput>
    ilock(ip);
    800055e4:	8556                	mv	a0,s5
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	63e080e7          	jalr	1598(ra) # 80003c24 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055ee:	000b059b          	sext.w	a1,s6
    800055f2:	4789                	li	a5,2
    800055f4:	02f59563          	bne	a1,a5,8000561e <create+0x8c>
    800055f8:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc2b4>
    800055fc:	37f9                	addiw	a5,a5,-2
    800055fe:	17c2                	slli	a5,a5,0x30
    80005600:	93c1                	srli	a5,a5,0x30
    80005602:	4705                	li	a4,1
    80005604:	00f76d63          	bltu	a4,a5,8000561e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005608:	8556                	mv	a0,s5
    8000560a:	60a6                	ld	ra,72(sp)
    8000560c:	6406                	ld	s0,64(sp)
    8000560e:	74e2                	ld	s1,56(sp)
    80005610:	7942                	ld	s2,48(sp)
    80005612:	79a2                	ld	s3,40(sp)
    80005614:	7a02                	ld	s4,32(sp)
    80005616:	6ae2                	ld	s5,24(sp)
    80005618:	6b42                	ld	s6,16(sp)
    8000561a:	6161                	addi	sp,sp,80
    8000561c:	8082                	ret
    iunlockput(ip);
    8000561e:	8556                	mv	a0,s5
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	866080e7          	jalr	-1946(ra) # 80003e86 <iunlockput>
    return 0;
    80005628:	4a81                	li	s5,0
    8000562a:	bff9                	j	80005608 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000562c:	85da                	mv	a1,s6
    8000562e:	4088                	lw	a0,0(s1)
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	456080e7          	jalr	1110(ra) # 80003a86 <ialloc>
    80005638:	8a2a                	mv	s4,a0
    8000563a:	c539                	beqz	a0,80005688 <create+0xf6>
  ilock(ip);
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	5e8080e7          	jalr	1512(ra) # 80003c24 <ilock>
  ip->major = major;
    80005644:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005648:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000564c:	4905                	li	s2,1
    8000564e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005652:	8552                	mv	a0,s4
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	504080e7          	jalr	1284(ra) # 80003b58 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000565c:	000b059b          	sext.w	a1,s6
    80005660:	03258b63          	beq	a1,s2,80005696 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005664:	004a2603          	lw	a2,4(s4)
    80005668:	fb040593          	addi	a1,s0,-80
    8000566c:	8526                	mv	a0,s1
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	cb0080e7          	jalr	-848(ra) # 8000431e <dirlink>
    80005676:	06054f63          	bltz	a0,800056f4 <create+0x162>
  iunlockput(dp);
    8000567a:	8526                	mv	a0,s1
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	80a080e7          	jalr	-2038(ra) # 80003e86 <iunlockput>
  return ip;
    80005684:	8ad2                	mv	s5,s4
    80005686:	b749                	j	80005608 <create+0x76>
    iunlockput(dp);
    80005688:	8526                	mv	a0,s1
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	7fc080e7          	jalr	2044(ra) # 80003e86 <iunlockput>
    return 0;
    80005692:	8ad2                	mv	s5,s4
    80005694:	bf95                	j	80005608 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005696:	004a2603          	lw	a2,4(s4)
    8000569a:	00003597          	auipc	a1,0x3
    8000569e:	08658593          	addi	a1,a1,134 # 80008720 <syscalls+0x2c0>
    800056a2:	8552                	mv	a0,s4
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	c7a080e7          	jalr	-902(ra) # 8000431e <dirlink>
    800056ac:	04054463          	bltz	a0,800056f4 <create+0x162>
    800056b0:	40d0                	lw	a2,4(s1)
    800056b2:	00003597          	auipc	a1,0x3
    800056b6:	07658593          	addi	a1,a1,118 # 80008728 <syscalls+0x2c8>
    800056ba:	8552                	mv	a0,s4
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	c62080e7          	jalr	-926(ra) # 8000431e <dirlink>
    800056c4:	02054863          	bltz	a0,800056f4 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800056c8:	004a2603          	lw	a2,4(s4)
    800056cc:	fb040593          	addi	a1,s0,-80
    800056d0:	8526                	mv	a0,s1
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	c4c080e7          	jalr	-948(ra) # 8000431e <dirlink>
    800056da:	00054d63          	bltz	a0,800056f4 <create+0x162>
    dp->nlink++;  // for ".."
    800056de:	04a4d783          	lhu	a5,74(s1)
    800056e2:	2785                	addiw	a5,a5,1
    800056e4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	46e080e7          	jalr	1134(ra) # 80003b58 <iupdate>
    800056f2:	b761                	j	8000567a <create+0xe8>
  ip->nlink = 0;
    800056f4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800056f8:	8552                	mv	a0,s4
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	45e080e7          	jalr	1118(ra) # 80003b58 <iupdate>
  iunlockput(ip);
    80005702:	8552                	mv	a0,s4
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	782080e7          	jalr	1922(ra) # 80003e86 <iunlockput>
  iunlockput(dp);
    8000570c:	8526                	mv	a0,s1
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	778080e7          	jalr	1912(ra) # 80003e86 <iunlockput>
  return 0;
    80005716:	bdcd                	j	80005608 <create+0x76>
    return 0;
    80005718:	8aaa                	mv	s5,a0
    8000571a:	b5fd                	j	80005608 <create+0x76>

000000008000571c <sys_dup>:
{
    8000571c:	7179                	addi	sp,sp,-48
    8000571e:	f406                	sd	ra,40(sp)
    80005720:	f022                	sd	s0,32(sp)
    80005722:	ec26                	sd	s1,24(sp)
    80005724:	e84a                	sd	s2,16(sp)
    80005726:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005728:	fd840613          	addi	a2,s0,-40
    8000572c:	4581                	li	a1,0
    8000572e:	4501                	li	a0,0
    80005730:	00000097          	auipc	ra,0x0
    80005734:	dc0080e7          	jalr	-576(ra) # 800054f0 <argfd>
    return -1;
    80005738:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000573a:	02054363          	bltz	a0,80005760 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000573e:	fd843903          	ld	s2,-40(s0)
    80005742:	854a                	mv	a0,s2
    80005744:	00000097          	auipc	ra,0x0
    80005748:	e0c080e7          	jalr	-500(ra) # 80005550 <fdalloc>
    8000574c:	84aa                	mv	s1,a0
    return -1;
    8000574e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005750:	00054863          	bltz	a0,80005760 <sys_dup+0x44>
  filedup(f);
    80005754:	854a                	mv	a0,s2
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	310080e7          	jalr	784(ra) # 80004a66 <filedup>
  return fd;
    8000575e:	87a6                	mv	a5,s1
}
    80005760:	853e                	mv	a0,a5
    80005762:	70a2                	ld	ra,40(sp)
    80005764:	7402                	ld	s0,32(sp)
    80005766:	64e2                	ld	s1,24(sp)
    80005768:	6942                	ld	s2,16(sp)
    8000576a:	6145                	addi	sp,sp,48
    8000576c:	8082                	ret

000000008000576e <sys_read>:
{
    8000576e:	7179                	addi	sp,sp,-48
    80005770:	f406                	sd	ra,40(sp)
    80005772:	f022                	sd	s0,32(sp)
    80005774:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005776:	fd840593          	addi	a1,s0,-40
    8000577a:	4505                	li	a0,1
    8000577c:	ffffd097          	auipc	ra,0xffffd
    80005780:	7c4080e7          	jalr	1988(ra) # 80002f40 <argaddr>
  argint(2, &n);
    80005784:	fe440593          	addi	a1,s0,-28
    80005788:	4509                	li	a0,2
    8000578a:	ffffd097          	auipc	ra,0xffffd
    8000578e:	796080e7          	jalr	1942(ra) # 80002f20 <argint>
  if(argfd(0, 0, &f) < 0)
    80005792:	fe840613          	addi	a2,s0,-24
    80005796:	4581                	li	a1,0
    80005798:	4501                	li	a0,0
    8000579a:	00000097          	auipc	ra,0x0
    8000579e:	d56080e7          	jalr	-682(ra) # 800054f0 <argfd>
    800057a2:	87aa                	mv	a5,a0
    return -1;
    800057a4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057a6:	0007cc63          	bltz	a5,800057be <sys_read+0x50>
  return fileread(f, p, n);
    800057aa:	fe442603          	lw	a2,-28(s0)
    800057ae:	fd843583          	ld	a1,-40(s0)
    800057b2:	fe843503          	ld	a0,-24(s0)
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	43c080e7          	jalr	1084(ra) # 80004bf2 <fileread>
}
    800057be:	70a2                	ld	ra,40(sp)
    800057c0:	7402                	ld	s0,32(sp)
    800057c2:	6145                	addi	sp,sp,48
    800057c4:	8082                	ret

00000000800057c6 <sys_write>:
{
    800057c6:	7179                	addi	sp,sp,-48
    800057c8:	f406                	sd	ra,40(sp)
    800057ca:	f022                	sd	s0,32(sp)
    800057cc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057ce:	fd840593          	addi	a1,s0,-40
    800057d2:	4505                	li	a0,1
    800057d4:	ffffd097          	auipc	ra,0xffffd
    800057d8:	76c080e7          	jalr	1900(ra) # 80002f40 <argaddr>
  argint(2, &n);
    800057dc:	fe440593          	addi	a1,s0,-28
    800057e0:	4509                	li	a0,2
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	73e080e7          	jalr	1854(ra) # 80002f20 <argint>
  if(argfd(0, 0, &f) < 0)
    800057ea:	fe840613          	addi	a2,s0,-24
    800057ee:	4581                	li	a1,0
    800057f0:	4501                	li	a0,0
    800057f2:	00000097          	auipc	ra,0x0
    800057f6:	cfe080e7          	jalr	-770(ra) # 800054f0 <argfd>
    800057fa:	87aa                	mv	a5,a0
    return -1;
    800057fc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057fe:	0007cc63          	bltz	a5,80005816 <sys_write+0x50>
  return filewrite(f, p, n);
    80005802:	fe442603          	lw	a2,-28(s0)
    80005806:	fd843583          	ld	a1,-40(s0)
    8000580a:	fe843503          	ld	a0,-24(s0)
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	4a6080e7          	jalr	1190(ra) # 80004cb4 <filewrite>
}
    80005816:	70a2                	ld	ra,40(sp)
    80005818:	7402                	ld	s0,32(sp)
    8000581a:	6145                	addi	sp,sp,48
    8000581c:	8082                	ret

000000008000581e <sys_close>:
{
    8000581e:	1101                	addi	sp,sp,-32
    80005820:	ec06                	sd	ra,24(sp)
    80005822:	e822                	sd	s0,16(sp)
    80005824:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005826:	fe040613          	addi	a2,s0,-32
    8000582a:	fec40593          	addi	a1,s0,-20
    8000582e:	4501                	li	a0,0
    80005830:	00000097          	auipc	ra,0x0
    80005834:	cc0080e7          	jalr	-832(ra) # 800054f0 <argfd>
    return -1;
    80005838:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000583a:	02054463          	bltz	a0,80005862 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000583e:	ffffc097          	auipc	ra,0xffffc
    80005842:	16e080e7          	jalr	366(ra) # 800019ac <myproc>
    80005846:	fec42783          	lw	a5,-20(s0)
    8000584a:	07e9                	addi	a5,a5,26
    8000584c:	078e                	slli	a5,a5,0x3
    8000584e:	953e                	add	a0,a0,a5
    80005850:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005854:	fe043503          	ld	a0,-32(s0)
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	260080e7          	jalr	608(ra) # 80004ab8 <fileclose>
  return 0;
    80005860:	4781                	li	a5,0
}
    80005862:	853e                	mv	a0,a5
    80005864:	60e2                	ld	ra,24(sp)
    80005866:	6442                	ld	s0,16(sp)
    80005868:	6105                	addi	sp,sp,32
    8000586a:	8082                	ret

000000008000586c <sys_fstat>:
{
    8000586c:	1101                	addi	sp,sp,-32
    8000586e:	ec06                	sd	ra,24(sp)
    80005870:	e822                	sd	s0,16(sp)
    80005872:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005874:	fe040593          	addi	a1,s0,-32
    80005878:	4505                	li	a0,1
    8000587a:	ffffd097          	auipc	ra,0xffffd
    8000587e:	6c6080e7          	jalr	1734(ra) # 80002f40 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005882:	fe840613          	addi	a2,s0,-24
    80005886:	4581                	li	a1,0
    80005888:	4501                	li	a0,0
    8000588a:	00000097          	auipc	ra,0x0
    8000588e:	c66080e7          	jalr	-922(ra) # 800054f0 <argfd>
    80005892:	87aa                	mv	a5,a0
    return -1;
    80005894:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005896:	0007ca63          	bltz	a5,800058aa <sys_fstat+0x3e>
  return filestat(f, st);
    8000589a:	fe043583          	ld	a1,-32(s0)
    8000589e:	fe843503          	ld	a0,-24(s0)
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	2de080e7          	jalr	734(ra) # 80004b80 <filestat>
}
    800058aa:	60e2                	ld	ra,24(sp)
    800058ac:	6442                	ld	s0,16(sp)
    800058ae:	6105                	addi	sp,sp,32
    800058b0:	8082                	ret

00000000800058b2 <sys_link>:
{
    800058b2:	7169                	addi	sp,sp,-304
    800058b4:	f606                	sd	ra,296(sp)
    800058b6:	f222                	sd	s0,288(sp)
    800058b8:	ee26                	sd	s1,280(sp)
    800058ba:	ea4a                	sd	s2,272(sp)
    800058bc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058be:	08000613          	li	a2,128
    800058c2:	ed040593          	addi	a1,s0,-304
    800058c6:	4501                	li	a0,0
    800058c8:	ffffd097          	auipc	ra,0xffffd
    800058cc:	698080e7          	jalr	1688(ra) # 80002f60 <argstr>
    return -1;
    800058d0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058d2:	10054e63          	bltz	a0,800059ee <sys_link+0x13c>
    800058d6:	08000613          	li	a2,128
    800058da:	f5040593          	addi	a1,s0,-176
    800058de:	4505                	li	a0,1
    800058e0:	ffffd097          	auipc	ra,0xffffd
    800058e4:	680080e7          	jalr	1664(ra) # 80002f60 <argstr>
    return -1;
    800058e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ea:	10054263          	bltz	a0,800059ee <sys_link+0x13c>
  begin_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	d02080e7          	jalr	-766(ra) # 800045f0 <begin_op>
  if((ip = namei(old)) == 0){
    800058f6:	ed040513          	addi	a0,s0,-304
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	ad6080e7          	jalr	-1322(ra) # 800043d0 <namei>
    80005902:	84aa                	mv	s1,a0
    80005904:	c551                	beqz	a0,80005990 <sys_link+0xde>
  ilock(ip);
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	31e080e7          	jalr	798(ra) # 80003c24 <ilock>
  if(ip->type == T_DIR){
    8000590e:	04449703          	lh	a4,68(s1)
    80005912:	4785                	li	a5,1
    80005914:	08f70463          	beq	a4,a5,8000599c <sys_link+0xea>
  ip->nlink++;
    80005918:	04a4d783          	lhu	a5,74(s1)
    8000591c:	2785                	addiw	a5,a5,1
    8000591e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005922:	8526                	mv	a0,s1
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	234080e7          	jalr	564(ra) # 80003b58 <iupdate>
  iunlock(ip);
    8000592c:	8526                	mv	a0,s1
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	3b8080e7          	jalr	952(ra) # 80003ce6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005936:	fd040593          	addi	a1,s0,-48
    8000593a:	f5040513          	addi	a0,s0,-176
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	ab0080e7          	jalr	-1360(ra) # 800043ee <nameiparent>
    80005946:	892a                	mv	s2,a0
    80005948:	c935                	beqz	a0,800059bc <sys_link+0x10a>
  ilock(dp);
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	2da080e7          	jalr	730(ra) # 80003c24 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005952:	00092703          	lw	a4,0(s2)
    80005956:	409c                	lw	a5,0(s1)
    80005958:	04f71d63          	bne	a4,a5,800059b2 <sys_link+0x100>
    8000595c:	40d0                	lw	a2,4(s1)
    8000595e:	fd040593          	addi	a1,s0,-48
    80005962:	854a                	mv	a0,s2
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	9ba080e7          	jalr	-1606(ra) # 8000431e <dirlink>
    8000596c:	04054363          	bltz	a0,800059b2 <sys_link+0x100>
  iunlockput(dp);
    80005970:	854a                	mv	a0,s2
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	514080e7          	jalr	1300(ra) # 80003e86 <iunlockput>
  iput(ip);
    8000597a:	8526                	mv	a0,s1
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	462080e7          	jalr	1122(ra) # 80003dde <iput>
  end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	cea080e7          	jalr	-790(ra) # 8000466e <end_op>
  return 0;
    8000598c:	4781                	li	a5,0
    8000598e:	a085                	j	800059ee <sys_link+0x13c>
    end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	cde080e7          	jalr	-802(ra) # 8000466e <end_op>
    return -1;
    80005998:	57fd                	li	a5,-1
    8000599a:	a891                	j	800059ee <sys_link+0x13c>
    iunlockput(ip);
    8000599c:	8526                	mv	a0,s1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	4e8080e7          	jalr	1256(ra) # 80003e86 <iunlockput>
    end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	cc8080e7          	jalr	-824(ra) # 8000466e <end_op>
    return -1;
    800059ae:	57fd                	li	a5,-1
    800059b0:	a83d                	j	800059ee <sys_link+0x13c>
    iunlockput(dp);
    800059b2:	854a                	mv	a0,s2
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	4d2080e7          	jalr	1234(ra) # 80003e86 <iunlockput>
  ilock(ip);
    800059bc:	8526                	mv	a0,s1
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	266080e7          	jalr	614(ra) # 80003c24 <ilock>
  ip->nlink--;
    800059c6:	04a4d783          	lhu	a5,74(s1)
    800059ca:	37fd                	addiw	a5,a5,-1
    800059cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	186080e7          	jalr	390(ra) # 80003b58 <iupdate>
  iunlockput(ip);
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	4aa080e7          	jalr	1194(ra) # 80003e86 <iunlockput>
  end_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	c8a080e7          	jalr	-886(ra) # 8000466e <end_op>
  return -1;
    800059ec:	57fd                	li	a5,-1
}
    800059ee:	853e                	mv	a0,a5
    800059f0:	70b2                	ld	ra,296(sp)
    800059f2:	7412                	ld	s0,288(sp)
    800059f4:	64f2                	ld	s1,280(sp)
    800059f6:	6952                	ld	s2,272(sp)
    800059f8:	6155                	addi	sp,sp,304
    800059fa:	8082                	ret

00000000800059fc <sys_unlink>:
{
    800059fc:	7151                	addi	sp,sp,-240
    800059fe:	f586                	sd	ra,232(sp)
    80005a00:	f1a2                	sd	s0,224(sp)
    80005a02:	eda6                	sd	s1,216(sp)
    80005a04:	e9ca                	sd	s2,208(sp)
    80005a06:	e5ce                	sd	s3,200(sp)
    80005a08:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a0a:	08000613          	li	a2,128
    80005a0e:	f3040593          	addi	a1,s0,-208
    80005a12:	4501                	li	a0,0
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	54c080e7          	jalr	1356(ra) # 80002f60 <argstr>
    80005a1c:	18054163          	bltz	a0,80005b9e <sys_unlink+0x1a2>
  begin_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	bd0080e7          	jalr	-1072(ra) # 800045f0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a28:	fb040593          	addi	a1,s0,-80
    80005a2c:	f3040513          	addi	a0,s0,-208
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	9be080e7          	jalr	-1602(ra) # 800043ee <nameiparent>
    80005a38:	84aa                	mv	s1,a0
    80005a3a:	c979                	beqz	a0,80005b10 <sys_unlink+0x114>
  ilock(dp);
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	1e8080e7          	jalr	488(ra) # 80003c24 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a44:	00003597          	auipc	a1,0x3
    80005a48:	cdc58593          	addi	a1,a1,-804 # 80008720 <syscalls+0x2c0>
    80005a4c:	fb040513          	addi	a0,s0,-80
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	69e080e7          	jalr	1694(ra) # 800040ee <namecmp>
    80005a58:	14050a63          	beqz	a0,80005bac <sys_unlink+0x1b0>
    80005a5c:	00003597          	auipc	a1,0x3
    80005a60:	ccc58593          	addi	a1,a1,-820 # 80008728 <syscalls+0x2c8>
    80005a64:	fb040513          	addi	a0,s0,-80
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	686080e7          	jalr	1670(ra) # 800040ee <namecmp>
    80005a70:	12050e63          	beqz	a0,80005bac <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a74:	f2c40613          	addi	a2,s0,-212
    80005a78:	fb040593          	addi	a1,s0,-80
    80005a7c:	8526                	mv	a0,s1
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	68a080e7          	jalr	1674(ra) # 80004108 <dirlookup>
    80005a86:	892a                	mv	s2,a0
    80005a88:	12050263          	beqz	a0,80005bac <sys_unlink+0x1b0>
  ilock(ip);
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	198080e7          	jalr	408(ra) # 80003c24 <ilock>
  if(ip->nlink < 1)
    80005a94:	04a91783          	lh	a5,74(s2)
    80005a98:	08f05263          	blez	a5,80005b1c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a9c:	04491703          	lh	a4,68(s2)
    80005aa0:	4785                	li	a5,1
    80005aa2:	08f70563          	beq	a4,a5,80005b2c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005aa6:	4641                	li	a2,16
    80005aa8:	4581                	li	a1,0
    80005aaa:	fc040513          	addi	a0,s0,-64
    80005aae:	ffffb097          	auipc	ra,0xffffb
    80005ab2:	224080e7          	jalr	548(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ab6:	4741                	li	a4,16
    80005ab8:	f2c42683          	lw	a3,-212(s0)
    80005abc:	fc040613          	addi	a2,s0,-64
    80005ac0:	4581                	li	a1,0
    80005ac2:	8526                	mv	a0,s1
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	50c080e7          	jalr	1292(ra) # 80003fd0 <writei>
    80005acc:	47c1                	li	a5,16
    80005ace:	0af51563          	bne	a0,a5,80005b78 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ad2:	04491703          	lh	a4,68(s2)
    80005ad6:	4785                	li	a5,1
    80005ad8:	0af70863          	beq	a4,a5,80005b88 <sys_unlink+0x18c>
  iunlockput(dp);
    80005adc:	8526                	mv	a0,s1
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	3a8080e7          	jalr	936(ra) # 80003e86 <iunlockput>
  ip->nlink--;
    80005ae6:	04a95783          	lhu	a5,74(s2)
    80005aea:	37fd                	addiw	a5,a5,-1
    80005aec:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005af0:	854a                	mv	a0,s2
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	066080e7          	jalr	102(ra) # 80003b58 <iupdate>
  iunlockput(ip);
    80005afa:	854a                	mv	a0,s2
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	38a080e7          	jalr	906(ra) # 80003e86 <iunlockput>
  end_op();
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	b6a080e7          	jalr	-1174(ra) # 8000466e <end_op>
  return 0;
    80005b0c:	4501                	li	a0,0
    80005b0e:	a84d                	j	80005bc0 <sys_unlink+0x1c4>
    end_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	b5e080e7          	jalr	-1186(ra) # 8000466e <end_op>
    return -1;
    80005b18:	557d                	li	a0,-1
    80005b1a:	a05d                	j	80005bc0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b1c:	00003517          	auipc	a0,0x3
    80005b20:	c1450513          	addi	a0,a0,-1004 # 80008730 <syscalls+0x2d0>
    80005b24:	ffffb097          	auipc	ra,0xffffb
    80005b28:	a1c080e7          	jalr	-1508(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b2c:	04c92703          	lw	a4,76(s2)
    80005b30:	02000793          	li	a5,32
    80005b34:	f6e7f9e3          	bgeu	a5,a4,80005aa6 <sys_unlink+0xaa>
    80005b38:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b3c:	4741                	li	a4,16
    80005b3e:	86ce                	mv	a3,s3
    80005b40:	f1840613          	addi	a2,s0,-232
    80005b44:	4581                	li	a1,0
    80005b46:	854a                	mv	a0,s2
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	390080e7          	jalr	912(ra) # 80003ed8 <readi>
    80005b50:	47c1                	li	a5,16
    80005b52:	00f51b63          	bne	a0,a5,80005b68 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b56:	f1845783          	lhu	a5,-232(s0)
    80005b5a:	e7a1                	bnez	a5,80005ba2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b5c:	29c1                	addiw	s3,s3,16
    80005b5e:	04c92783          	lw	a5,76(s2)
    80005b62:	fcf9ede3          	bltu	s3,a5,80005b3c <sys_unlink+0x140>
    80005b66:	b781                	j	80005aa6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b68:	00003517          	auipc	a0,0x3
    80005b6c:	be050513          	addi	a0,a0,-1056 # 80008748 <syscalls+0x2e8>
    80005b70:	ffffb097          	auipc	ra,0xffffb
    80005b74:	9d0080e7          	jalr	-1584(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005b78:	00003517          	auipc	a0,0x3
    80005b7c:	be850513          	addi	a0,a0,-1048 # 80008760 <syscalls+0x300>
    80005b80:	ffffb097          	auipc	ra,0xffffb
    80005b84:	9c0080e7          	jalr	-1600(ra) # 80000540 <panic>
    dp->nlink--;
    80005b88:	04a4d783          	lhu	a5,74(s1)
    80005b8c:	37fd                	addiw	a5,a5,-1
    80005b8e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b92:	8526                	mv	a0,s1
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	fc4080e7          	jalr	-60(ra) # 80003b58 <iupdate>
    80005b9c:	b781                	j	80005adc <sys_unlink+0xe0>
    return -1;
    80005b9e:	557d                	li	a0,-1
    80005ba0:	a005                	j	80005bc0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ba2:	854a                	mv	a0,s2
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	2e2080e7          	jalr	738(ra) # 80003e86 <iunlockput>
  iunlockput(dp);
    80005bac:	8526                	mv	a0,s1
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	2d8080e7          	jalr	728(ra) # 80003e86 <iunlockput>
  end_op();
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	ab8080e7          	jalr	-1352(ra) # 8000466e <end_op>
  return -1;
    80005bbe:	557d                	li	a0,-1
}
    80005bc0:	70ae                	ld	ra,232(sp)
    80005bc2:	740e                	ld	s0,224(sp)
    80005bc4:	64ee                	ld	s1,216(sp)
    80005bc6:	694e                	ld	s2,208(sp)
    80005bc8:	69ae                	ld	s3,200(sp)
    80005bca:	616d                	addi	sp,sp,240
    80005bcc:	8082                	ret

0000000080005bce <sys_open>:

uint64
sys_open(void)
{
    80005bce:	7131                	addi	sp,sp,-192
    80005bd0:	fd06                	sd	ra,184(sp)
    80005bd2:	f922                	sd	s0,176(sp)
    80005bd4:	f526                	sd	s1,168(sp)
    80005bd6:	f14a                	sd	s2,160(sp)
    80005bd8:	ed4e                	sd	s3,152(sp)
    80005bda:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005bdc:	f4c40593          	addi	a1,s0,-180
    80005be0:	4505                	li	a0,1
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	33e080e7          	jalr	830(ra) # 80002f20 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bea:	08000613          	li	a2,128
    80005bee:	f5040593          	addi	a1,s0,-176
    80005bf2:	4501                	li	a0,0
    80005bf4:	ffffd097          	auipc	ra,0xffffd
    80005bf8:	36c080e7          	jalr	876(ra) # 80002f60 <argstr>
    80005bfc:	87aa                	mv	a5,a0
    return -1;
    80005bfe:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c00:	0a07c963          	bltz	a5,80005cb2 <sys_open+0xe4>

  begin_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	9ec080e7          	jalr	-1556(ra) # 800045f0 <begin_op>

  if(omode & O_CREATE){
    80005c0c:	f4c42783          	lw	a5,-180(s0)
    80005c10:	2007f793          	andi	a5,a5,512
    80005c14:	cfc5                	beqz	a5,80005ccc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c16:	4681                	li	a3,0
    80005c18:	4601                	li	a2,0
    80005c1a:	4589                	li	a1,2
    80005c1c:	f5040513          	addi	a0,s0,-176
    80005c20:	00000097          	auipc	ra,0x0
    80005c24:	972080e7          	jalr	-1678(ra) # 80005592 <create>
    80005c28:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c2a:	c959                	beqz	a0,80005cc0 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c2c:	04449703          	lh	a4,68(s1)
    80005c30:	478d                	li	a5,3
    80005c32:	00f71763          	bne	a4,a5,80005c40 <sys_open+0x72>
    80005c36:	0464d703          	lhu	a4,70(s1)
    80005c3a:	47a5                	li	a5,9
    80005c3c:	0ce7ed63          	bltu	a5,a4,80005d16 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	dbc080e7          	jalr	-580(ra) # 800049fc <filealloc>
    80005c48:	89aa                	mv	s3,a0
    80005c4a:	10050363          	beqz	a0,80005d50 <sys_open+0x182>
    80005c4e:	00000097          	auipc	ra,0x0
    80005c52:	902080e7          	jalr	-1790(ra) # 80005550 <fdalloc>
    80005c56:	892a                	mv	s2,a0
    80005c58:	0e054763          	bltz	a0,80005d46 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c5c:	04449703          	lh	a4,68(s1)
    80005c60:	478d                	li	a5,3
    80005c62:	0cf70563          	beq	a4,a5,80005d2c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c66:	4789                	li	a5,2
    80005c68:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c6c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c70:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c74:	f4c42783          	lw	a5,-180(s0)
    80005c78:	0017c713          	xori	a4,a5,1
    80005c7c:	8b05                	andi	a4,a4,1
    80005c7e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c82:	0037f713          	andi	a4,a5,3
    80005c86:	00e03733          	snez	a4,a4
    80005c8a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c8e:	4007f793          	andi	a5,a5,1024
    80005c92:	c791                	beqz	a5,80005c9e <sys_open+0xd0>
    80005c94:	04449703          	lh	a4,68(s1)
    80005c98:	4789                	li	a5,2
    80005c9a:	0af70063          	beq	a4,a5,80005d3a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c9e:	8526                	mv	a0,s1
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	046080e7          	jalr	70(ra) # 80003ce6 <iunlock>
  end_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	9c6080e7          	jalr	-1594(ra) # 8000466e <end_op>

  return fd;
    80005cb0:	854a                	mv	a0,s2
}
    80005cb2:	70ea                	ld	ra,184(sp)
    80005cb4:	744a                	ld	s0,176(sp)
    80005cb6:	74aa                	ld	s1,168(sp)
    80005cb8:	790a                	ld	s2,160(sp)
    80005cba:	69ea                	ld	s3,152(sp)
    80005cbc:	6129                	addi	sp,sp,192
    80005cbe:	8082                	ret
      end_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	9ae080e7          	jalr	-1618(ra) # 8000466e <end_op>
      return -1;
    80005cc8:	557d                	li	a0,-1
    80005cca:	b7e5                	j	80005cb2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ccc:	f5040513          	addi	a0,s0,-176
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	700080e7          	jalr	1792(ra) # 800043d0 <namei>
    80005cd8:	84aa                	mv	s1,a0
    80005cda:	c905                	beqz	a0,80005d0a <sys_open+0x13c>
    ilock(ip);
    80005cdc:	ffffe097          	auipc	ra,0xffffe
    80005ce0:	f48080e7          	jalr	-184(ra) # 80003c24 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ce4:	04449703          	lh	a4,68(s1)
    80005ce8:	4785                	li	a5,1
    80005cea:	f4f711e3          	bne	a4,a5,80005c2c <sys_open+0x5e>
    80005cee:	f4c42783          	lw	a5,-180(s0)
    80005cf2:	d7b9                	beqz	a5,80005c40 <sys_open+0x72>
      iunlockput(ip);
    80005cf4:	8526                	mv	a0,s1
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	190080e7          	jalr	400(ra) # 80003e86 <iunlockput>
      end_op();
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	970080e7          	jalr	-1680(ra) # 8000466e <end_op>
      return -1;
    80005d06:	557d                	li	a0,-1
    80005d08:	b76d                	j	80005cb2 <sys_open+0xe4>
      end_op();
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	964080e7          	jalr	-1692(ra) # 8000466e <end_op>
      return -1;
    80005d12:	557d                	li	a0,-1
    80005d14:	bf79                	j	80005cb2 <sys_open+0xe4>
    iunlockput(ip);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	16e080e7          	jalr	366(ra) # 80003e86 <iunlockput>
    end_op();
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	94e080e7          	jalr	-1714(ra) # 8000466e <end_op>
    return -1;
    80005d28:	557d                	li	a0,-1
    80005d2a:	b761                	j	80005cb2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d2c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d30:	04649783          	lh	a5,70(s1)
    80005d34:	02f99223          	sh	a5,36(s3)
    80005d38:	bf25                	j	80005c70 <sys_open+0xa2>
    itrunc(ip);
    80005d3a:	8526                	mv	a0,s1
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	ff6080e7          	jalr	-10(ra) # 80003d32 <itrunc>
    80005d44:	bfa9                	j	80005c9e <sys_open+0xd0>
      fileclose(f);
    80005d46:	854e                	mv	a0,s3
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	d70080e7          	jalr	-656(ra) # 80004ab8 <fileclose>
    iunlockput(ip);
    80005d50:	8526                	mv	a0,s1
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	134080e7          	jalr	308(ra) # 80003e86 <iunlockput>
    end_op();
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	914080e7          	jalr	-1772(ra) # 8000466e <end_op>
    return -1;
    80005d62:	557d                	li	a0,-1
    80005d64:	b7b9                	j	80005cb2 <sys_open+0xe4>

0000000080005d66 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d66:	7175                	addi	sp,sp,-144
    80005d68:	e506                	sd	ra,136(sp)
    80005d6a:	e122                	sd	s0,128(sp)
    80005d6c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	882080e7          	jalr	-1918(ra) # 800045f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d76:	08000613          	li	a2,128
    80005d7a:	f7040593          	addi	a1,s0,-144
    80005d7e:	4501                	li	a0,0
    80005d80:	ffffd097          	auipc	ra,0xffffd
    80005d84:	1e0080e7          	jalr	480(ra) # 80002f60 <argstr>
    80005d88:	02054963          	bltz	a0,80005dba <sys_mkdir+0x54>
    80005d8c:	4681                	li	a3,0
    80005d8e:	4601                	li	a2,0
    80005d90:	4585                	li	a1,1
    80005d92:	f7040513          	addi	a0,s0,-144
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	7fc080e7          	jalr	2044(ra) # 80005592 <create>
    80005d9e:	cd11                	beqz	a0,80005dba <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	0e6080e7          	jalr	230(ra) # 80003e86 <iunlockput>
  end_op();
    80005da8:	fffff097          	auipc	ra,0xfffff
    80005dac:	8c6080e7          	jalr	-1850(ra) # 8000466e <end_op>
  return 0;
    80005db0:	4501                	li	a0,0
}
    80005db2:	60aa                	ld	ra,136(sp)
    80005db4:	640a                	ld	s0,128(sp)
    80005db6:	6149                	addi	sp,sp,144
    80005db8:	8082                	ret
    end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	8b4080e7          	jalr	-1868(ra) # 8000466e <end_op>
    return -1;
    80005dc2:	557d                	li	a0,-1
    80005dc4:	b7fd                	j	80005db2 <sys_mkdir+0x4c>

0000000080005dc6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dc6:	7135                	addi	sp,sp,-160
    80005dc8:	ed06                	sd	ra,152(sp)
    80005dca:	e922                	sd	s0,144(sp)
    80005dcc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	822080e7          	jalr	-2014(ra) # 800045f0 <begin_op>
  argint(1, &major);
    80005dd6:	f6c40593          	addi	a1,s0,-148
    80005dda:	4505                	li	a0,1
    80005ddc:	ffffd097          	auipc	ra,0xffffd
    80005de0:	144080e7          	jalr	324(ra) # 80002f20 <argint>
  argint(2, &minor);
    80005de4:	f6840593          	addi	a1,s0,-152
    80005de8:	4509                	li	a0,2
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	136080e7          	jalr	310(ra) # 80002f20 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005df2:	08000613          	li	a2,128
    80005df6:	f7040593          	addi	a1,s0,-144
    80005dfa:	4501                	li	a0,0
    80005dfc:	ffffd097          	auipc	ra,0xffffd
    80005e00:	164080e7          	jalr	356(ra) # 80002f60 <argstr>
    80005e04:	02054b63          	bltz	a0,80005e3a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e08:	f6841683          	lh	a3,-152(s0)
    80005e0c:	f6c41603          	lh	a2,-148(s0)
    80005e10:	458d                	li	a1,3
    80005e12:	f7040513          	addi	a0,s0,-144
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	77c080e7          	jalr	1916(ra) # 80005592 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e1e:	cd11                	beqz	a0,80005e3a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	066080e7          	jalr	102(ra) # 80003e86 <iunlockput>
  end_op();
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	846080e7          	jalr	-1978(ra) # 8000466e <end_op>
  return 0;
    80005e30:	4501                	li	a0,0
}
    80005e32:	60ea                	ld	ra,152(sp)
    80005e34:	644a                	ld	s0,144(sp)
    80005e36:	610d                	addi	sp,sp,160
    80005e38:	8082                	ret
    end_op();
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	834080e7          	jalr	-1996(ra) # 8000466e <end_op>
    return -1;
    80005e42:	557d                	li	a0,-1
    80005e44:	b7fd                	j	80005e32 <sys_mknod+0x6c>

0000000080005e46 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e46:	7135                	addi	sp,sp,-160
    80005e48:	ed06                	sd	ra,152(sp)
    80005e4a:	e922                	sd	s0,144(sp)
    80005e4c:	e526                	sd	s1,136(sp)
    80005e4e:	e14a                	sd	s2,128(sp)
    80005e50:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e52:	ffffc097          	auipc	ra,0xffffc
    80005e56:	b5a080e7          	jalr	-1190(ra) # 800019ac <myproc>
    80005e5a:	892a                	mv	s2,a0
  
  begin_op();
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	794080e7          	jalr	1940(ra) # 800045f0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e64:	08000613          	li	a2,128
    80005e68:	f6040593          	addi	a1,s0,-160
    80005e6c:	4501                	li	a0,0
    80005e6e:	ffffd097          	auipc	ra,0xffffd
    80005e72:	0f2080e7          	jalr	242(ra) # 80002f60 <argstr>
    80005e76:	04054b63          	bltz	a0,80005ecc <sys_chdir+0x86>
    80005e7a:	f6040513          	addi	a0,s0,-160
    80005e7e:	ffffe097          	auipc	ra,0xffffe
    80005e82:	552080e7          	jalr	1362(ra) # 800043d0 <namei>
    80005e86:	84aa                	mv	s1,a0
    80005e88:	c131                	beqz	a0,80005ecc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e8a:	ffffe097          	auipc	ra,0xffffe
    80005e8e:	d9a080e7          	jalr	-614(ra) # 80003c24 <ilock>
  if(ip->type != T_DIR){
    80005e92:	04449703          	lh	a4,68(s1)
    80005e96:	4785                	li	a5,1
    80005e98:	04f71063          	bne	a4,a5,80005ed8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e9c:	8526                	mv	a0,s1
    80005e9e:	ffffe097          	auipc	ra,0xffffe
    80005ea2:	e48080e7          	jalr	-440(ra) # 80003ce6 <iunlock>
  iput(p->cwd);
    80005ea6:	15093503          	ld	a0,336(s2)
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	f34080e7          	jalr	-204(ra) # 80003dde <iput>
  end_op();
    80005eb2:	ffffe097          	auipc	ra,0xffffe
    80005eb6:	7bc080e7          	jalr	1980(ra) # 8000466e <end_op>
  p->cwd = ip;
    80005eba:	14993823          	sd	s1,336(s2)
  return 0;
    80005ebe:	4501                	li	a0,0
}
    80005ec0:	60ea                	ld	ra,152(sp)
    80005ec2:	644a                	ld	s0,144(sp)
    80005ec4:	64aa                	ld	s1,136(sp)
    80005ec6:	690a                	ld	s2,128(sp)
    80005ec8:	610d                	addi	sp,sp,160
    80005eca:	8082                	ret
    end_op();
    80005ecc:	ffffe097          	auipc	ra,0xffffe
    80005ed0:	7a2080e7          	jalr	1954(ra) # 8000466e <end_op>
    return -1;
    80005ed4:	557d                	li	a0,-1
    80005ed6:	b7ed                	j	80005ec0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ed8:	8526                	mv	a0,s1
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	fac080e7          	jalr	-84(ra) # 80003e86 <iunlockput>
    end_op();
    80005ee2:	ffffe097          	auipc	ra,0xffffe
    80005ee6:	78c080e7          	jalr	1932(ra) # 8000466e <end_op>
    return -1;
    80005eea:	557d                	li	a0,-1
    80005eec:	bfd1                	j	80005ec0 <sys_chdir+0x7a>

0000000080005eee <sys_exec>:

uint64
sys_exec(void)
{
    80005eee:	7145                	addi	sp,sp,-464
    80005ef0:	e786                	sd	ra,456(sp)
    80005ef2:	e3a2                	sd	s0,448(sp)
    80005ef4:	ff26                	sd	s1,440(sp)
    80005ef6:	fb4a                	sd	s2,432(sp)
    80005ef8:	f74e                	sd	s3,424(sp)
    80005efa:	f352                	sd	s4,416(sp)
    80005efc:	ef56                	sd	s5,408(sp)
    80005efe:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f00:	e3840593          	addi	a1,s0,-456
    80005f04:	4505                	li	a0,1
    80005f06:	ffffd097          	auipc	ra,0xffffd
    80005f0a:	03a080e7          	jalr	58(ra) # 80002f40 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f0e:	08000613          	li	a2,128
    80005f12:	f4040593          	addi	a1,s0,-192
    80005f16:	4501                	li	a0,0
    80005f18:	ffffd097          	auipc	ra,0xffffd
    80005f1c:	048080e7          	jalr	72(ra) # 80002f60 <argstr>
    80005f20:	87aa                	mv	a5,a0
    return -1;
    80005f22:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f24:	0c07c363          	bltz	a5,80005fea <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005f28:	10000613          	li	a2,256
    80005f2c:	4581                	li	a1,0
    80005f2e:	e4040513          	addi	a0,s0,-448
    80005f32:	ffffb097          	auipc	ra,0xffffb
    80005f36:	da0080e7          	jalr	-608(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f3a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f3e:	89a6                	mv	s3,s1
    80005f40:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f42:	02000a13          	li	s4,32
    80005f46:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f4a:	00391513          	slli	a0,s2,0x3
    80005f4e:	e3040593          	addi	a1,s0,-464
    80005f52:	e3843783          	ld	a5,-456(s0)
    80005f56:	953e                	add	a0,a0,a5
    80005f58:	ffffd097          	auipc	ra,0xffffd
    80005f5c:	f2a080e7          	jalr	-214(ra) # 80002e82 <fetchaddr>
    80005f60:	02054a63          	bltz	a0,80005f94 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005f64:	e3043783          	ld	a5,-464(s0)
    80005f68:	c3b9                	beqz	a5,80005fae <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f6a:	ffffb097          	auipc	ra,0xffffb
    80005f6e:	b7c080e7          	jalr	-1156(ra) # 80000ae6 <kalloc>
    80005f72:	85aa                	mv	a1,a0
    80005f74:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f78:	cd11                	beqz	a0,80005f94 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f7a:	6605                	lui	a2,0x1
    80005f7c:	e3043503          	ld	a0,-464(s0)
    80005f80:	ffffd097          	auipc	ra,0xffffd
    80005f84:	f54080e7          	jalr	-172(ra) # 80002ed4 <fetchstr>
    80005f88:	00054663          	bltz	a0,80005f94 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005f8c:	0905                	addi	s2,s2,1
    80005f8e:	09a1                	addi	s3,s3,8
    80005f90:	fb491be3          	bne	s2,s4,80005f46 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f94:	f4040913          	addi	s2,s0,-192
    80005f98:	6088                	ld	a0,0(s1)
    80005f9a:	c539                	beqz	a0,80005fe8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	a4c080e7          	jalr	-1460(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fa4:	04a1                	addi	s1,s1,8
    80005fa6:	ff2499e3          	bne	s1,s2,80005f98 <sys_exec+0xaa>
  return -1;
    80005faa:	557d                	li	a0,-1
    80005fac:	a83d                	j	80005fea <sys_exec+0xfc>
      argv[i] = 0;
    80005fae:	0a8e                	slli	s5,s5,0x3
    80005fb0:	fc0a8793          	addi	a5,s5,-64
    80005fb4:	00878ab3          	add	s5,a5,s0
    80005fb8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fbc:	e4040593          	addi	a1,s0,-448
    80005fc0:	f4040513          	addi	a0,s0,-192
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	16e080e7          	jalr	366(ra) # 80005132 <exec>
    80005fcc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fce:	f4040993          	addi	s3,s0,-192
    80005fd2:	6088                	ld	a0,0(s1)
    80005fd4:	c901                	beqz	a0,80005fe4 <sys_exec+0xf6>
    kfree(argv[i]);
    80005fd6:	ffffb097          	auipc	ra,0xffffb
    80005fda:	a12080e7          	jalr	-1518(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fde:	04a1                	addi	s1,s1,8
    80005fe0:	ff3499e3          	bne	s1,s3,80005fd2 <sys_exec+0xe4>
  return ret;
    80005fe4:	854a                	mv	a0,s2
    80005fe6:	a011                	j	80005fea <sys_exec+0xfc>
  return -1;
    80005fe8:	557d                	li	a0,-1
}
    80005fea:	60be                	ld	ra,456(sp)
    80005fec:	641e                	ld	s0,448(sp)
    80005fee:	74fa                	ld	s1,440(sp)
    80005ff0:	795a                	ld	s2,432(sp)
    80005ff2:	79ba                	ld	s3,424(sp)
    80005ff4:	7a1a                	ld	s4,416(sp)
    80005ff6:	6afa                	ld	s5,408(sp)
    80005ff8:	6179                	addi	sp,sp,464
    80005ffa:	8082                	ret

0000000080005ffc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ffc:	7139                	addi	sp,sp,-64
    80005ffe:	fc06                	sd	ra,56(sp)
    80006000:	f822                	sd	s0,48(sp)
    80006002:	f426                	sd	s1,40(sp)
    80006004:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006006:	ffffc097          	auipc	ra,0xffffc
    8000600a:	9a6080e7          	jalr	-1626(ra) # 800019ac <myproc>
    8000600e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006010:	fd840593          	addi	a1,s0,-40
    80006014:	4501                	li	a0,0
    80006016:	ffffd097          	auipc	ra,0xffffd
    8000601a:	f2a080e7          	jalr	-214(ra) # 80002f40 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000601e:	fc840593          	addi	a1,s0,-56
    80006022:	fd040513          	addi	a0,s0,-48
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	dc2080e7          	jalr	-574(ra) # 80004de8 <pipealloc>
    return -1;
    8000602e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006030:	0c054463          	bltz	a0,800060f8 <sys_pipe+0xfc>
  fd0 = -1;
    80006034:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006038:	fd043503          	ld	a0,-48(s0)
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	514080e7          	jalr	1300(ra) # 80005550 <fdalloc>
    80006044:	fca42223          	sw	a0,-60(s0)
    80006048:	08054b63          	bltz	a0,800060de <sys_pipe+0xe2>
    8000604c:	fc843503          	ld	a0,-56(s0)
    80006050:	fffff097          	auipc	ra,0xfffff
    80006054:	500080e7          	jalr	1280(ra) # 80005550 <fdalloc>
    80006058:	fca42023          	sw	a0,-64(s0)
    8000605c:	06054863          	bltz	a0,800060cc <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006060:	4691                	li	a3,4
    80006062:	fc440613          	addi	a2,s0,-60
    80006066:	fd843583          	ld	a1,-40(s0)
    8000606a:	68a8                	ld	a0,80(s1)
    8000606c:	ffffb097          	auipc	ra,0xffffb
    80006070:	600080e7          	jalr	1536(ra) # 8000166c <copyout>
    80006074:	02054063          	bltz	a0,80006094 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006078:	4691                	li	a3,4
    8000607a:	fc040613          	addi	a2,s0,-64
    8000607e:	fd843583          	ld	a1,-40(s0)
    80006082:	0591                	addi	a1,a1,4
    80006084:	68a8                	ld	a0,80(s1)
    80006086:	ffffb097          	auipc	ra,0xffffb
    8000608a:	5e6080e7          	jalr	1510(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000608e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006090:	06055463          	bgez	a0,800060f8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006094:	fc442783          	lw	a5,-60(s0)
    80006098:	07e9                	addi	a5,a5,26
    8000609a:	078e                	slli	a5,a5,0x3
    8000609c:	97a6                	add	a5,a5,s1
    8000609e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060a2:	fc042783          	lw	a5,-64(s0)
    800060a6:	07e9                	addi	a5,a5,26
    800060a8:	078e                	slli	a5,a5,0x3
    800060aa:	94be                	add	s1,s1,a5
    800060ac:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060b0:	fd043503          	ld	a0,-48(s0)
    800060b4:	fffff097          	auipc	ra,0xfffff
    800060b8:	a04080e7          	jalr	-1532(ra) # 80004ab8 <fileclose>
    fileclose(wf);
    800060bc:	fc843503          	ld	a0,-56(s0)
    800060c0:	fffff097          	auipc	ra,0xfffff
    800060c4:	9f8080e7          	jalr	-1544(ra) # 80004ab8 <fileclose>
    return -1;
    800060c8:	57fd                	li	a5,-1
    800060ca:	a03d                	j	800060f8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800060cc:	fc442783          	lw	a5,-60(s0)
    800060d0:	0007c763          	bltz	a5,800060de <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800060d4:	07e9                	addi	a5,a5,26
    800060d6:	078e                	slli	a5,a5,0x3
    800060d8:	97a6                	add	a5,a5,s1
    800060da:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800060de:	fd043503          	ld	a0,-48(s0)
    800060e2:	fffff097          	auipc	ra,0xfffff
    800060e6:	9d6080e7          	jalr	-1578(ra) # 80004ab8 <fileclose>
    fileclose(wf);
    800060ea:	fc843503          	ld	a0,-56(s0)
    800060ee:	fffff097          	auipc	ra,0xfffff
    800060f2:	9ca080e7          	jalr	-1590(ra) # 80004ab8 <fileclose>
    return -1;
    800060f6:	57fd                	li	a5,-1
}
    800060f8:	853e                	mv	a0,a5
    800060fa:	70e2                	ld	ra,56(sp)
    800060fc:	7442                	ld	s0,48(sp)
    800060fe:	74a2                	ld	s1,40(sp)
    80006100:	6121                	addi	sp,sp,64
    80006102:	8082                	ret
	...

0000000080006110 <kernelvec>:
    80006110:	7111                	addi	sp,sp,-256
    80006112:	e006                	sd	ra,0(sp)
    80006114:	e40a                	sd	sp,8(sp)
    80006116:	e80e                	sd	gp,16(sp)
    80006118:	ec12                	sd	tp,24(sp)
    8000611a:	f016                	sd	t0,32(sp)
    8000611c:	f41a                	sd	t1,40(sp)
    8000611e:	f81e                	sd	t2,48(sp)
    80006120:	fc22                	sd	s0,56(sp)
    80006122:	e0a6                	sd	s1,64(sp)
    80006124:	e4aa                	sd	a0,72(sp)
    80006126:	e8ae                	sd	a1,80(sp)
    80006128:	ecb2                	sd	a2,88(sp)
    8000612a:	f0b6                	sd	a3,96(sp)
    8000612c:	f4ba                	sd	a4,104(sp)
    8000612e:	f8be                	sd	a5,112(sp)
    80006130:	fcc2                	sd	a6,120(sp)
    80006132:	e146                	sd	a7,128(sp)
    80006134:	e54a                	sd	s2,136(sp)
    80006136:	e94e                	sd	s3,144(sp)
    80006138:	ed52                	sd	s4,152(sp)
    8000613a:	f156                	sd	s5,160(sp)
    8000613c:	f55a                	sd	s6,168(sp)
    8000613e:	f95e                	sd	s7,176(sp)
    80006140:	fd62                	sd	s8,184(sp)
    80006142:	e1e6                	sd	s9,192(sp)
    80006144:	e5ea                	sd	s10,200(sp)
    80006146:	e9ee                	sd	s11,208(sp)
    80006148:	edf2                	sd	t3,216(sp)
    8000614a:	f1f6                	sd	t4,224(sp)
    8000614c:	f5fa                	sd	t5,232(sp)
    8000614e:	f9fe                	sd	t6,240(sp)
    80006150:	bfffc0ef          	jal	ra,80002d4e <kerneltrap>
    80006154:	6082                	ld	ra,0(sp)
    80006156:	6122                	ld	sp,8(sp)
    80006158:	61c2                	ld	gp,16(sp)
    8000615a:	7282                	ld	t0,32(sp)
    8000615c:	7322                	ld	t1,40(sp)
    8000615e:	73c2                	ld	t2,48(sp)
    80006160:	7462                	ld	s0,56(sp)
    80006162:	6486                	ld	s1,64(sp)
    80006164:	6526                	ld	a0,72(sp)
    80006166:	65c6                	ld	a1,80(sp)
    80006168:	6666                	ld	a2,88(sp)
    8000616a:	7686                	ld	a3,96(sp)
    8000616c:	7726                	ld	a4,104(sp)
    8000616e:	77c6                	ld	a5,112(sp)
    80006170:	7866                	ld	a6,120(sp)
    80006172:	688a                	ld	a7,128(sp)
    80006174:	692a                	ld	s2,136(sp)
    80006176:	69ca                	ld	s3,144(sp)
    80006178:	6a6a                	ld	s4,152(sp)
    8000617a:	7a8a                	ld	s5,160(sp)
    8000617c:	7b2a                	ld	s6,168(sp)
    8000617e:	7bca                	ld	s7,176(sp)
    80006180:	7c6a                	ld	s8,184(sp)
    80006182:	6c8e                	ld	s9,192(sp)
    80006184:	6d2e                	ld	s10,200(sp)
    80006186:	6dce                	ld	s11,208(sp)
    80006188:	6e6e                	ld	t3,216(sp)
    8000618a:	7e8e                	ld	t4,224(sp)
    8000618c:	7f2e                	ld	t5,232(sp)
    8000618e:	7fce                	ld	t6,240(sp)
    80006190:	6111                	addi	sp,sp,256
    80006192:	10200073          	sret
    80006196:	00000013          	nop
    8000619a:	00000013          	nop
    8000619e:	0001                	nop

00000000800061a0 <timervec>:
    800061a0:	34051573          	csrrw	a0,mscratch,a0
    800061a4:	e10c                	sd	a1,0(a0)
    800061a6:	e510                	sd	a2,8(a0)
    800061a8:	e914                	sd	a3,16(a0)
    800061aa:	6d0c                	ld	a1,24(a0)
    800061ac:	7110                	ld	a2,32(a0)
    800061ae:	6194                	ld	a3,0(a1)
    800061b0:	96b2                	add	a3,a3,a2
    800061b2:	e194                	sd	a3,0(a1)
    800061b4:	4589                	li	a1,2
    800061b6:	14459073          	csrw	sip,a1
    800061ba:	6914                	ld	a3,16(a0)
    800061bc:	6510                	ld	a2,8(a0)
    800061be:	610c                	ld	a1,0(a0)
    800061c0:	34051573          	csrrw	a0,mscratch,a0
    800061c4:	30200073          	mret
	...

00000000800061ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ca:	1141                	addi	sp,sp,-16
    800061cc:	e422                	sd	s0,8(sp)
    800061ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061d0:	0c0007b7          	lui	a5,0xc000
    800061d4:	4705                	li	a4,1
    800061d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061d8:	c3d8                	sw	a4,4(a5)
}
    800061da:	6422                	ld	s0,8(sp)
    800061dc:	0141                	addi	sp,sp,16
    800061de:	8082                	ret

00000000800061e0 <plicinithart>:

void
plicinithart(void)
{
    800061e0:	1141                	addi	sp,sp,-16
    800061e2:	e406                	sd	ra,8(sp)
    800061e4:	e022                	sd	s0,0(sp)
    800061e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061e8:	ffffb097          	auipc	ra,0xffffb
    800061ec:	798080e7          	jalr	1944(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061f0:	0085171b          	slliw	a4,a0,0x8
    800061f4:	0c0027b7          	lui	a5,0xc002
    800061f8:	97ba                	add	a5,a5,a4
    800061fa:	40200713          	li	a4,1026
    800061fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006202:	00d5151b          	slliw	a0,a0,0xd
    80006206:	0c2017b7          	lui	a5,0xc201
    8000620a:	97aa                	add	a5,a5,a0
    8000620c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006210:	60a2                	ld	ra,8(sp)
    80006212:	6402                	ld	s0,0(sp)
    80006214:	0141                	addi	sp,sp,16
    80006216:	8082                	ret

0000000080006218 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006218:	1141                	addi	sp,sp,-16
    8000621a:	e406                	sd	ra,8(sp)
    8000621c:	e022                	sd	s0,0(sp)
    8000621e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006220:	ffffb097          	auipc	ra,0xffffb
    80006224:	760080e7          	jalr	1888(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006228:	00d5151b          	slliw	a0,a0,0xd
    8000622c:	0c2017b7          	lui	a5,0xc201
    80006230:	97aa                	add	a5,a5,a0
  return irq;
}
    80006232:	43c8                	lw	a0,4(a5)
    80006234:	60a2                	ld	ra,8(sp)
    80006236:	6402                	ld	s0,0(sp)
    80006238:	0141                	addi	sp,sp,16
    8000623a:	8082                	ret

000000008000623c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000623c:	1101                	addi	sp,sp,-32
    8000623e:	ec06                	sd	ra,24(sp)
    80006240:	e822                	sd	s0,16(sp)
    80006242:	e426                	sd	s1,8(sp)
    80006244:	1000                	addi	s0,sp,32
    80006246:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006248:	ffffb097          	auipc	ra,0xffffb
    8000624c:	738080e7          	jalr	1848(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006250:	00d5151b          	slliw	a0,a0,0xd
    80006254:	0c2017b7          	lui	a5,0xc201
    80006258:	97aa                	add	a5,a5,a0
    8000625a:	c3c4                	sw	s1,4(a5)
}
    8000625c:	60e2                	ld	ra,24(sp)
    8000625e:	6442                	ld	s0,16(sp)
    80006260:	64a2                	ld	s1,8(sp)
    80006262:	6105                	addi	sp,sp,32
    80006264:	8082                	ret

0000000080006266 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006266:	1141                	addi	sp,sp,-16
    80006268:	e406                	sd	ra,8(sp)
    8000626a:	e022                	sd	s0,0(sp)
    8000626c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000626e:	479d                	li	a5,7
    80006270:	04a7cc63          	blt	a5,a0,800062c8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006274:	0001d797          	auipc	a5,0x1d
    80006278:	9dc78793          	addi	a5,a5,-1572 # 80022c50 <disk>
    8000627c:	97aa                	add	a5,a5,a0
    8000627e:	0187c783          	lbu	a5,24(a5)
    80006282:	ebb9                	bnez	a5,800062d8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006284:	00451693          	slli	a3,a0,0x4
    80006288:	0001d797          	auipc	a5,0x1d
    8000628c:	9c878793          	addi	a5,a5,-1592 # 80022c50 <disk>
    80006290:	6398                	ld	a4,0(a5)
    80006292:	9736                	add	a4,a4,a3
    80006294:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006298:	6398                	ld	a4,0(a5)
    8000629a:	9736                	add	a4,a4,a3
    8000629c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800062a0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800062a4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800062a8:	97aa                	add	a5,a5,a0
    800062aa:	4705                	li	a4,1
    800062ac:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800062b0:	0001d517          	auipc	a0,0x1d
    800062b4:	9b850513          	addi	a0,a0,-1608 # 80022c68 <disk+0x18>
    800062b8:	ffffc097          	auipc	ra,0xffffc
    800062bc:	f8a080e7          	jalr	-118(ra) # 80002242 <wakeup>
}
    800062c0:	60a2                	ld	ra,8(sp)
    800062c2:	6402                	ld	s0,0(sp)
    800062c4:	0141                	addi	sp,sp,16
    800062c6:	8082                	ret
    panic("free_desc 1");
    800062c8:	00002517          	auipc	a0,0x2
    800062cc:	4a850513          	addi	a0,a0,1192 # 80008770 <syscalls+0x310>
    800062d0:	ffffa097          	auipc	ra,0xffffa
    800062d4:	270080e7          	jalr	624(ra) # 80000540 <panic>
    panic("free_desc 2");
    800062d8:	00002517          	auipc	a0,0x2
    800062dc:	4a850513          	addi	a0,a0,1192 # 80008780 <syscalls+0x320>
    800062e0:	ffffa097          	auipc	ra,0xffffa
    800062e4:	260080e7          	jalr	608(ra) # 80000540 <panic>

00000000800062e8 <virtio_disk_init>:
{
    800062e8:	1101                	addi	sp,sp,-32
    800062ea:	ec06                	sd	ra,24(sp)
    800062ec:	e822                	sd	s0,16(sp)
    800062ee:	e426                	sd	s1,8(sp)
    800062f0:	e04a                	sd	s2,0(sp)
    800062f2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062f4:	00002597          	auipc	a1,0x2
    800062f8:	49c58593          	addi	a1,a1,1180 # 80008790 <syscalls+0x330>
    800062fc:	0001d517          	auipc	a0,0x1d
    80006300:	a7c50513          	addi	a0,a0,-1412 # 80022d78 <disk+0x128>
    80006304:	ffffb097          	auipc	ra,0xffffb
    80006308:	842080e7          	jalr	-1982(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000630c:	100017b7          	lui	a5,0x10001
    80006310:	4398                	lw	a4,0(a5)
    80006312:	2701                	sext.w	a4,a4
    80006314:	747277b7          	lui	a5,0x74727
    80006318:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000631c:	14f71b63          	bne	a4,a5,80006472 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006320:	100017b7          	lui	a5,0x10001
    80006324:	43dc                	lw	a5,4(a5)
    80006326:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006328:	4709                	li	a4,2
    8000632a:	14e79463          	bne	a5,a4,80006472 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000632e:	100017b7          	lui	a5,0x10001
    80006332:	479c                	lw	a5,8(a5)
    80006334:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006336:	12e79e63          	bne	a5,a4,80006472 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000633a:	100017b7          	lui	a5,0x10001
    8000633e:	47d8                	lw	a4,12(a5)
    80006340:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006342:	554d47b7          	lui	a5,0x554d4
    80006346:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000634a:	12f71463          	bne	a4,a5,80006472 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000634e:	100017b7          	lui	a5,0x10001
    80006352:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006356:	4705                	li	a4,1
    80006358:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000635a:	470d                	li	a4,3
    8000635c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000635e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006360:	c7ffe6b7          	lui	a3,0xc7ffe
    80006364:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb9cf>
    80006368:	8f75                	and	a4,a4,a3
    8000636a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000636c:	472d                	li	a4,11
    8000636e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006370:	5bbc                	lw	a5,112(a5)
    80006372:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006376:	8ba1                	andi	a5,a5,8
    80006378:	10078563          	beqz	a5,80006482 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000637c:	100017b7          	lui	a5,0x10001
    80006380:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006384:	43fc                	lw	a5,68(a5)
    80006386:	2781                	sext.w	a5,a5
    80006388:	10079563          	bnez	a5,80006492 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000638c:	100017b7          	lui	a5,0x10001
    80006390:	5bdc                	lw	a5,52(a5)
    80006392:	2781                	sext.w	a5,a5
  if(max == 0)
    80006394:	10078763          	beqz	a5,800064a2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006398:	471d                	li	a4,7
    8000639a:	10f77c63          	bgeu	a4,a5,800064b2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000639e:	ffffa097          	auipc	ra,0xffffa
    800063a2:	748080e7          	jalr	1864(ra) # 80000ae6 <kalloc>
    800063a6:	0001d497          	auipc	s1,0x1d
    800063aa:	8aa48493          	addi	s1,s1,-1878 # 80022c50 <disk>
    800063ae:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063b0:	ffffa097          	auipc	ra,0xffffa
    800063b4:	736080e7          	jalr	1846(ra) # 80000ae6 <kalloc>
    800063b8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	72c080e7          	jalr	1836(ra) # 80000ae6 <kalloc>
    800063c2:	87aa                	mv	a5,a0
    800063c4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800063c6:	6088                	ld	a0,0(s1)
    800063c8:	cd6d                	beqz	a0,800064c2 <virtio_disk_init+0x1da>
    800063ca:	0001d717          	auipc	a4,0x1d
    800063ce:	88e73703          	ld	a4,-1906(a4) # 80022c58 <disk+0x8>
    800063d2:	cb65                	beqz	a4,800064c2 <virtio_disk_init+0x1da>
    800063d4:	c7fd                	beqz	a5,800064c2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800063d6:	6605                	lui	a2,0x1
    800063d8:	4581                	li	a1,0
    800063da:	ffffb097          	auipc	ra,0xffffb
    800063de:	8f8080e7          	jalr	-1800(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800063e2:	0001d497          	auipc	s1,0x1d
    800063e6:	86e48493          	addi	s1,s1,-1938 # 80022c50 <disk>
    800063ea:	6605                	lui	a2,0x1
    800063ec:	4581                	li	a1,0
    800063ee:	6488                	ld	a0,8(s1)
    800063f0:	ffffb097          	auipc	ra,0xffffb
    800063f4:	8e2080e7          	jalr	-1822(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800063f8:	6605                	lui	a2,0x1
    800063fa:	4581                	li	a1,0
    800063fc:	6888                	ld	a0,16(s1)
    800063fe:	ffffb097          	auipc	ra,0xffffb
    80006402:	8d4080e7          	jalr	-1836(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006406:	100017b7          	lui	a5,0x10001
    8000640a:	4721                	li	a4,8
    8000640c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000640e:	4098                	lw	a4,0(s1)
    80006410:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006414:	40d8                	lw	a4,4(s1)
    80006416:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000641a:	6498                	ld	a4,8(s1)
    8000641c:	0007069b          	sext.w	a3,a4
    80006420:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006424:	9701                	srai	a4,a4,0x20
    80006426:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000642a:	6898                	ld	a4,16(s1)
    8000642c:	0007069b          	sext.w	a3,a4
    80006430:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006434:	9701                	srai	a4,a4,0x20
    80006436:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000643a:	4705                	li	a4,1
    8000643c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000643e:	00e48c23          	sb	a4,24(s1)
    80006442:	00e48ca3          	sb	a4,25(s1)
    80006446:	00e48d23          	sb	a4,26(s1)
    8000644a:	00e48da3          	sb	a4,27(s1)
    8000644e:	00e48e23          	sb	a4,28(s1)
    80006452:	00e48ea3          	sb	a4,29(s1)
    80006456:	00e48f23          	sb	a4,30(s1)
    8000645a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000645e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006462:	0727a823          	sw	s2,112(a5)
}
    80006466:	60e2                	ld	ra,24(sp)
    80006468:	6442                	ld	s0,16(sp)
    8000646a:	64a2                	ld	s1,8(sp)
    8000646c:	6902                	ld	s2,0(sp)
    8000646e:	6105                	addi	sp,sp,32
    80006470:	8082                	ret
    panic("could not find virtio disk");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	32e50513          	addi	a0,a0,814 # 800087a0 <syscalls+0x340>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c6080e7          	jalr	198(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	33e50513          	addi	a0,a0,830 # 800087c0 <syscalls+0x360>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b6080e7          	jalr	182(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	34e50513          	addi	a0,a0,846 # 800087e0 <syscalls+0x380>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	0a6080e7          	jalr	166(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800064a2:	00002517          	auipc	a0,0x2
    800064a6:	35e50513          	addi	a0,a0,862 # 80008800 <syscalls+0x3a0>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	096080e7          	jalr	150(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800064b2:	00002517          	auipc	a0,0x2
    800064b6:	36e50513          	addi	a0,a0,878 # 80008820 <syscalls+0x3c0>
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	086080e7          	jalr	134(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800064c2:	00002517          	auipc	a0,0x2
    800064c6:	37e50513          	addi	a0,a0,894 # 80008840 <syscalls+0x3e0>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	076080e7          	jalr	118(ra) # 80000540 <panic>

00000000800064d2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064d2:	7119                	addi	sp,sp,-128
    800064d4:	fc86                	sd	ra,120(sp)
    800064d6:	f8a2                	sd	s0,112(sp)
    800064d8:	f4a6                	sd	s1,104(sp)
    800064da:	f0ca                	sd	s2,96(sp)
    800064dc:	ecce                	sd	s3,88(sp)
    800064de:	e8d2                	sd	s4,80(sp)
    800064e0:	e4d6                	sd	s5,72(sp)
    800064e2:	e0da                	sd	s6,64(sp)
    800064e4:	fc5e                	sd	s7,56(sp)
    800064e6:	f862                	sd	s8,48(sp)
    800064e8:	f466                	sd	s9,40(sp)
    800064ea:	f06a                	sd	s10,32(sp)
    800064ec:	ec6e                	sd	s11,24(sp)
    800064ee:	0100                	addi	s0,sp,128
    800064f0:	8aaa                	mv	s5,a0
    800064f2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064f4:	00c52d03          	lw	s10,12(a0)
    800064f8:	001d1d1b          	slliw	s10,s10,0x1
    800064fc:	1d02                	slli	s10,s10,0x20
    800064fe:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006502:	0001d517          	auipc	a0,0x1d
    80006506:	87650513          	addi	a0,a0,-1930 # 80022d78 <disk+0x128>
    8000650a:	ffffa097          	auipc	ra,0xffffa
    8000650e:	6cc080e7          	jalr	1740(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006512:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006514:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006516:	0001cb97          	auipc	s7,0x1c
    8000651a:	73ab8b93          	addi	s7,s7,1850 # 80022c50 <disk>
  for(int i = 0; i < 3; i++){
    8000651e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006520:	0001dc97          	auipc	s9,0x1d
    80006524:	858c8c93          	addi	s9,s9,-1960 # 80022d78 <disk+0x128>
    80006528:	a08d                	j	8000658a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000652a:	00fb8733          	add	a4,s7,a5
    8000652e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006532:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006534:	0207c563          	bltz	a5,8000655e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006538:	2905                	addiw	s2,s2,1
    8000653a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000653c:	05690c63          	beq	s2,s6,80006594 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006540:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006542:	0001c717          	auipc	a4,0x1c
    80006546:	70e70713          	addi	a4,a4,1806 # 80022c50 <disk>
    8000654a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000654c:	01874683          	lbu	a3,24(a4)
    80006550:	fee9                	bnez	a3,8000652a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006552:	2785                	addiw	a5,a5,1
    80006554:	0705                	addi	a4,a4,1
    80006556:	fe979be3          	bne	a5,s1,8000654c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000655a:	57fd                	li	a5,-1
    8000655c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000655e:	01205d63          	blez	s2,80006578 <virtio_disk_rw+0xa6>
    80006562:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006564:	000a2503          	lw	a0,0(s4)
    80006568:	00000097          	auipc	ra,0x0
    8000656c:	cfe080e7          	jalr	-770(ra) # 80006266 <free_desc>
      for(int j = 0; j < i; j++)
    80006570:	2d85                	addiw	s11,s11,1
    80006572:	0a11                	addi	s4,s4,4
    80006574:	ff2d98e3          	bne	s11,s2,80006564 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006578:	85e6                	mv	a1,s9
    8000657a:	0001c517          	auipc	a0,0x1c
    8000657e:	6ee50513          	addi	a0,a0,1774 # 80022c68 <disk+0x18>
    80006582:	ffffc097          	auipc	ra,0xffffc
    80006586:	c5c080e7          	jalr	-932(ra) # 800021de <sleep>
  for(int i = 0; i < 3; i++){
    8000658a:	f8040a13          	addi	s4,s0,-128
{
    8000658e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006590:	894e                	mv	s2,s3
    80006592:	b77d                	j	80006540 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006594:	f8042503          	lw	a0,-128(s0)
    80006598:	00a50713          	addi	a4,a0,10
    8000659c:	0712                	slli	a4,a4,0x4

  if(write)
    8000659e:	0001c797          	auipc	a5,0x1c
    800065a2:	6b278793          	addi	a5,a5,1714 # 80022c50 <disk>
    800065a6:	00e786b3          	add	a3,a5,a4
    800065aa:	01803633          	snez	a2,s8
    800065ae:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065b0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800065b4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065b8:	f6070613          	addi	a2,a4,-160
    800065bc:	6394                	ld	a3,0(a5)
    800065be:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065c0:	00870593          	addi	a1,a4,8
    800065c4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065c6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065c8:	0007b803          	ld	a6,0(a5)
    800065cc:	9642                	add	a2,a2,a6
    800065ce:	46c1                	li	a3,16
    800065d0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065d2:	4585                	li	a1,1
    800065d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800065d8:	f8442683          	lw	a3,-124(s0)
    800065dc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065e0:	0692                	slli	a3,a3,0x4
    800065e2:	9836                	add	a6,a6,a3
    800065e4:	058a8613          	addi	a2,s5,88
    800065e8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800065ec:	0007b803          	ld	a6,0(a5)
    800065f0:	96c2                	add	a3,a3,a6
    800065f2:	40000613          	li	a2,1024
    800065f6:	c690                	sw	a2,8(a3)
  if(write)
    800065f8:	001c3613          	seqz	a2,s8
    800065fc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006600:	00166613          	ori	a2,a2,1
    80006604:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006608:	f8842603          	lw	a2,-120(s0)
    8000660c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006610:	00250693          	addi	a3,a0,2
    80006614:	0692                	slli	a3,a3,0x4
    80006616:	96be                	add	a3,a3,a5
    80006618:	58fd                	li	a7,-1
    8000661a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000661e:	0612                	slli	a2,a2,0x4
    80006620:	9832                	add	a6,a6,a2
    80006622:	f9070713          	addi	a4,a4,-112
    80006626:	973e                	add	a4,a4,a5
    80006628:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000662c:	6398                	ld	a4,0(a5)
    8000662e:	9732                	add	a4,a4,a2
    80006630:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006632:	4609                	li	a2,2
    80006634:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006638:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000663c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006640:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006644:	6794                	ld	a3,8(a5)
    80006646:	0026d703          	lhu	a4,2(a3)
    8000664a:	8b1d                	andi	a4,a4,7
    8000664c:	0706                	slli	a4,a4,0x1
    8000664e:	96ba                	add	a3,a3,a4
    80006650:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006654:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006658:	6798                	ld	a4,8(a5)
    8000665a:	00275783          	lhu	a5,2(a4)
    8000665e:	2785                	addiw	a5,a5,1
    80006660:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006664:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006668:	100017b7          	lui	a5,0x10001
    8000666c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006670:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006674:	0001c917          	auipc	s2,0x1c
    80006678:	70490913          	addi	s2,s2,1796 # 80022d78 <disk+0x128>
  while(b->disk == 1) {
    8000667c:	4485                	li	s1,1
    8000667e:	00b79c63          	bne	a5,a1,80006696 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006682:	85ca                	mv	a1,s2
    80006684:	8556                	mv	a0,s5
    80006686:	ffffc097          	auipc	ra,0xffffc
    8000668a:	b58080e7          	jalr	-1192(ra) # 800021de <sleep>
  while(b->disk == 1) {
    8000668e:	004aa783          	lw	a5,4(s5)
    80006692:	fe9788e3          	beq	a5,s1,80006682 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006696:	f8042903          	lw	s2,-128(s0)
    8000669a:	00290713          	addi	a4,s2,2
    8000669e:	0712                	slli	a4,a4,0x4
    800066a0:	0001c797          	auipc	a5,0x1c
    800066a4:	5b078793          	addi	a5,a5,1456 # 80022c50 <disk>
    800066a8:	97ba                	add	a5,a5,a4
    800066aa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800066ae:	0001c997          	auipc	s3,0x1c
    800066b2:	5a298993          	addi	s3,s3,1442 # 80022c50 <disk>
    800066b6:	00491713          	slli	a4,s2,0x4
    800066ba:	0009b783          	ld	a5,0(s3)
    800066be:	97ba                	add	a5,a5,a4
    800066c0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066c4:	854a                	mv	a0,s2
    800066c6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066ca:	00000097          	auipc	ra,0x0
    800066ce:	b9c080e7          	jalr	-1124(ra) # 80006266 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066d2:	8885                	andi	s1,s1,1
    800066d4:	f0ed                	bnez	s1,800066b6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066d6:	0001c517          	auipc	a0,0x1c
    800066da:	6a250513          	addi	a0,a0,1698 # 80022d78 <disk+0x128>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	5ac080e7          	jalr	1452(ra) # 80000c8a <release>
}
    800066e6:	70e6                	ld	ra,120(sp)
    800066e8:	7446                	ld	s0,112(sp)
    800066ea:	74a6                	ld	s1,104(sp)
    800066ec:	7906                	ld	s2,96(sp)
    800066ee:	69e6                	ld	s3,88(sp)
    800066f0:	6a46                	ld	s4,80(sp)
    800066f2:	6aa6                	ld	s5,72(sp)
    800066f4:	6b06                	ld	s6,64(sp)
    800066f6:	7be2                	ld	s7,56(sp)
    800066f8:	7c42                	ld	s8,48(sp)
    800066fa:	7ca2                	ld	s9,40(sp)
    800066fc:	7d02                	ld	s10,32(sp)
    800066fe:	6de2                	ld	s11,24(sp)
    80006700:	6109                	addi	sp,sp,128
    80006702:	8082                	ret

0000000080006704 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006704:	1101                	addi	sp,sp,-32
    80006706:	ec06                	sd	ra,24(sp)
    80006708:	e822                	sd	s0,16(sp)
    8000670a:	e426                	sd	s1,8(sp)
    8000670c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000670e:	0001c497          	auipc	s1,0x1c
    80006712:	54248493          	addi	s1,s1,1346 # 80022c50 <disk>
    80006716:	0001c517          	auipc	a0,0x1c
    8000671a:	66250513          	addi	a0,a0,1634 # 80022d78 <disk+0x128>
    8000671e:	ffffa097          	auipc	ra,0xffffa
    80006722:	4b8080e7          	jalr	1208(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006726:	10001737          	lui	a4,0x10001
    8000672a:	533c                	lw	a5,96(a4)
    8000672c:	8b8d                	andi	a5,a5,3
    8000672e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006730:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006734:	689c                	ld	a5,16(s1)
    80006736:	0204d703          	lhu	a4,32(s1)
    8000673a:	0027d783          	lhu	a5,2(a5)
    8000673e:	04f70863          	beq	a4,a5,8000678e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006742:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006746:	6898                	ld	a4,16(s1)
    80006748:	0204d783          	lhu	a5,32(s1)
    8000674c:	8b9d                	andi	a5,a5,7
    8000674e:	078e                	slli	a5,a5,0x3
    80006750:	97ba                	add	a5,a5,a4
    80006752:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006754:	00278713          	addi	a4,a5,2
    80006758:	0712                	slli	a4,a4,0x4
    8000675a:	9726                	add	a4,a4,s1
    8000675c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006760:	e721                	bnez	a4,800067a8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006762:	0789                	addi	a5,a5,2
    80006764:	0792                	slli	a5,a5,0x4
    80006766:	97a6                	add	a5,a5,s1
    80006768:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000676a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000676e:	ffffc097          	auipc	ra,0xffffc
    80006772:	ad4080e7          	jalr	-1324(ra) # 80002242 <wakeup>

    disk.used_idx += 1;
    80006776:	0204d783          	lhu	a5,32(s1)
    8000677a:	2785                	addiw	a5,a5,1
    8000677c:	17c2                	slli	a5,a5,0x30
    8000677e:	93c1                	srli	a5,a5,0x30
    80006780:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006784:	6898                	ld	a4,16(s1)
    80006786:	00275703          	lhu	a4,2(a4)
    8000678a:	faf71ce3          	bne	a4,a5,80006742 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000678e:	0001c517          	auipc	a0,0x1c
    80006792:	5ea50513          	addi	a0,a0,1514 # 80022d78 <disk+0x128>
    80006796:	ffffa097          	auipc	ra,0xffffa
    8000679a:	4f4080e7          	jalr	1268(ra) # 80000c8a <release>
}
    8000679e:	60e2                	ld	ra,24(sp)
    800067a0:	6442                	ld	s0,16(sp)
    800067a2:	64a2                	ld	s1,8(sp)
    800067a4:	6105                	addi	sp,sp,32
    800067a6:	8082                	ret
      panic("virtio_disk_intr status");
    800067a8:	00002517          	auipc	a0,0x2
    800067ac:	0b050513          	addi	a0,a0,176 # 80008858 <syscalls+0x3f8>
    800067b0:	ffffa097          	auipc	ra,0xffffa
    800067b4:	d90080e7          	jalr	-624(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
