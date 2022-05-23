
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	06c78793          	addi	a5,a5,108 # 800060d0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	bb2080e7          	jalr	-1102(ra) # 80001cde <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	744080e7          	jalr	1860(ra) # 80001908 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	ee6080e7          	jalr	-282(ra) # 800020ba <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	a78080e7          	jalr	-1416(ra) # 80001c88 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

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
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f6:	a42080e7          	jalr	-1470(ra) # 80001d34 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fe6080e7          	jalr	-26(ra) # 8000242c <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	7e878793          	addi	a5,a5,2024 # 80021c60 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
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
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
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
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b8c080e7          	jalr	-1140(ra) # 8000242c <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	78e080e7          	jalr	1934(ra) # 800020ba <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	d66080e7          	jalr	-666(ra) # 800018e4 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	d34080e7          	jalr	-716(ra) # 800018e4 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	d28080e7          	jalr	-728(ra) # 800018e4 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	d10080e7          	jalr	-752(ra) # 800018e4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	cd0080e7          	jalr	-816(ra) # 800018e4 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ca4080e7          	jalr	-860(ra) # 800018e4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	a3e080e7          	jalr	-1474(ra) # 800018d4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	a22080e7          	jalr	-1502(ra) # 800018d4 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	c9c080e7          	jalr	-868(ra) # 80002b70 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	234080e7          	jalr	564(ra) # 80006110 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	b44080e7          	jalr	-1212(ra) # 80002a28 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	fca080e7          	jalr	-54(ra) # 80001f0e <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	bfc080e7          	jalr	-1028(ra) # 80002b48 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c1c080e7          	jalr	-996(ra) # 80002b70 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	19e080e7          	jalr	414(ra) # 800060fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	1ac080e7          	jalr	428(ra) # 80006110 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	390080e7          	jalr	912(ra) # 800032fc <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a20080e7          	jalr	-1504(ra) # 80003994 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9ca080e7          	jalr	-1590(ra) # 80004946 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	2ae080e7          	jalr	686(ra) # 80006232 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	88e080e7          	jalr	-1906(ra) # 8000281a <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	fc448493          	addi	s1,s1,-60 # 80011818 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	1aaa0a13          	addi	s4,s4,426 # 80017a18 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	18848493          	addi	s1,s1,392
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018d4:	1141                	addi	sp,sp,-16
    800018d6:	e422                	sd	s0,8(sp)
    800018d8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018da:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018dc:	2501                	sext.w	a0,a0
    800018de:	6422                	ld	s0,8(sp)
    800018e0:	0141                	addi	sp,sp,16
    800018e2:	8082                	ret

00000000800018e4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800018e4:	1141                	addi	sp,sp,-16
    800018e6:	e422                	sd	s0,8(sp)
    800018e8:	0800                	addi	s0,sp,16
    800018ea:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018ec:	0007851b          	sext.w	a0,a5
    800018f0:	00251793          	slli	a5,a0,0x2
    800018f4:	97aa                	add	a5,a5,a0
    800018f6:	0796                	slli	a5,a5,0x5
  return c;
}
    800018f8:	00010517          	auipc	a0,0x10
    800018fc:	9a850513          	addi	a0,a0,-1624 # 800112a0 <cpus>
    80001900:	953e                	add	a0,a0,a5
    80001902:	6422                	ld	s0,8(sp)
    80001904:	0141                	addi	sp,sp,16
    80001906:	8082                	ret

0000000080001908 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001908:	1101                	addi	sp,sp,-32
    8000190a:	ec06                	sd	ra,24(sp)
    8000190c:	e822                	sd	s0,16(sp)
    8000190e:	e426                	sd	s1,8(sp)
    80001910:	1000                	addi	s0,sp,32
  push_off();
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	286080e7          	jalr	646(ra) # 80000b98 <push_off>
    8000191a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000191c:	0007871b          	sext.w	a4,a5
    80001920:	00271793          	slli	a5,a4,0x2
    80001924:	97ba                	add	a5,a5,a4
    80001926:	0796                	slli	a5,a5,0x5
    80001928:	00010717          	auipc	a4,0x10
    8000192c:	97870713          	addi	a4,a4,-1672 # 800112a0 <cpus>
    80001930:	97ba                	add	a5,a5,a4
    80001932:	6384                	ld	s1,0(a5)
  pop_off();
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	304080e7          	jalr	772(ra) # 80000c38 <pop_off>
  return p;
}
    8000193c:	8526                	mv	a0,s1
    8000193e:	60e2                	ld	ra,24(sp)
    80001940:	6442                	ld	s0,16(sp)
    80001942:	64a2                	ld	s1,8(sp)
    80001944:	6105                	addi	sp,sp,32
    80001946:	8082                	ret

0000000080001948 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001948:	1141                	addi	sp,sp,-16
    8000194a:	e406                	sd	ra,8(sp)
    8000194c:	e022                	sd	s0,0(sp)
    8000194e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001950:	00000097          	auipc	ra,0x0
    80001954:	fb8080e7          	jalr	-72(ra) # 80001908 <myproc>
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	340080e7          	jalr	832(ra) # 80000c98 <release>

  if (first) {
    80001960:	00007797          	auipc	a5,0x7
    80001964:	ed07a783          	lw	a5,-304(a5) # 80008830 <first.1706>
    80001968:	eb89                	bnez	a5,8000197a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000196a:	00001097          	auipc	ra,0x1
    8000196e:	21e080e7          	jalr	542(ra) # 80002b88 <usertrapret>
}
    80001972:	60a2                	ld	ra,8(sp)
    80001974:	6402                	ld	s0,0(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret
    first = 0;
    8000197a:	00007797          	auipc	a5,0x7
    8000197e:	ea07ab23          	sw	zero,-330(a5) # 80008830 <first.1706>
    fsinit(ROOTDEV);
    80001982:	4505                	li	a0,1
    80001984:	00002097          	auipc	ra,0x2
    80001988:	f90080e7          	jalr	-112(ra) # 80003914 <fsinit>
    8000198c:	bff9                	j	8000196a <forkret+0x22>

000000008000198e <allocpid>:
allocpid() {
    8000198e:	1101                	addi	sp,sp,-32
    80001990:	ec06                	sd	ra,24(sp)
    80001992:	e822                	sd	s0,16(sp)
    80001994:	e426                	sd	s1,8(sp)
    80001996:	e04a                	sd	s2,0(sp)
    80001998:	1000                	addi	s0,sp,32
    pid = nextpid;
    8000199a:	00007917          	auipc	s2,0x7
    8000199e:	ea690913          	addi	s2,s2,-346 # 80008840 <nextpid>
    800019a2:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid , pid , pid+1));
    800019a6:	0014861b          	addiw	a2,s1,1
    800019aa:	85a6                	mv	a1,s1
    800019ac:	854a                	mv	a0,s2
    800019ae:	00005097          	auipc	ra,0x5
    800019b2:	d68080e7          	jalr	-664(ra) # 80006716 <cas>
    800019b6:	f575                	bnez	a0,800019a2 <allocpid+0x14>
}
    800019b8:	8526                	mv	a0,s1
    800019ba:	60e2                	ld	ra,24(sp)
    800019bc:	6442                	ld	s0,16(sp)
    800019be:	64a2                	ld	s1,8(sp)
    800019c0:	6902                	ld	s2,0(sp)
    800019c2:	6105                	addi	sp,sp,32
    800019c4:	8082                	ret

00000000800019c6 <proc_pagetable>:
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	e04a                	sd	s2,0(sp)
    800019d0:	1000                	addi	s0,sp,32
    800019d2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019d4:	00000097          	auipc	ra,0x0
    800019d8:	966080e7          	jalr	-1690(ra) # 8000133a <uvmcreate>
    800019dc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800019de:	c121                	beqz	a0,80001a1e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019e0:	4729                	li	a4,10
    800019e2:	00005697          	auipc	a3,0x5
    800019e6:	61e68693          	addi	a3,a3,1566 # 80007000 <_trampoline>
    800019ea:	6605                	lui	a2,0x1
    800019ec:	040005b7          	lui	a1,0x4000
    800019f0:	15fd                	addi	a1,a1,-1
    800019f2:	05b2                	slli	a1,a1,0xc
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	6bc080e7          	jalr	1724(ra) # 800010b0 <mappages>
    800019fc:	02054863          	bltz	a0,80001a2c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a00:	4719                	li	a4,6
    80001a02:	07893683          	ld	a3,120(s2)
    80001a06:	6605                	lui	a2,0x1
    80001a08:	020005b7          	lui	a1,0x2000
    80001a0c:	15fd                	addi	a1,a1,-1
    80001a0e:	05b6                	slli	a1,a1,0xd
    80001a10:	8526                	mv	a0,s1
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	69e080e7          	jalr	1694(ra) # 800010b0 <mappages>
    80001a1a:	02054163          	bltz	a0,80001a3c <proc_pagetable+0x76>
}
    80001a1e:	8526                	mv	a0,s1
    80001a20:	60e2                	ld	ra,24(sp)
    80001a22:	6442                	ld	s0,16(sp)
    80001a24:	64a2                	ld	s1,8(sp)
    80001a26:	6902                	ld	s2,0(sp)
    80001a28:	6105                	addi	sp,sp,32
    80001a2a:	8082                	ret
    uvmfree(pagetable, 0);
    80001a2c:	4581                	li	a1,0
    80001a2e:	8526                	mv	a0,s1
    80001a30:	00000097          	auipc	ra,0x0
    80001a34:	b06080e7          	jalr	-1274(ra) # 80001536 <uvmfree>
    return 0;
    80001a38:	4481                	li	s1,0
    80001a3a:	b7d5                	j	80001a1e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a3c:	4681                	li	a3,0
    80001a3e:	4605                	li	a2,1
    80001a40:	040005b7          	lui	a1,0x4000
    80001a44:	15fd                	addi	a1,a1,-1
    80001a46:	05b2                	slli	a1,a1,0xc
    80001a48:	8526                	mv	a0,s1
    80001a4a:	00000097          	auipc	ra,0x0
    80001a4e:	82c080e7          	jalr	-2004(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001a52:	4581                	li	a1,0
    80001a54:	8526                	mv	a0,s1
    80001a56:	00000097          	auipc	ra,0x0
    80001a5a:	ae0080e7          	jalr	-1312(ra) # 80001536 <uvmfree>
    return 0;
    80001a5e:	4481                	li	s1,0
    80001a60:	bf7d                	j	80001a1e <proc_pagetable+0x58>

0000000080001a62 <proc_freepagetable>:
{
    80001a62:	1101                	addi	sp,sp,-32
    80001a64:	ec06                	sd	ra,24(sp)
    80001a66:	e822                	sd	s0,16(sp)
    80001a68:	e426                	sd	s1,8(sp)
    80001a6a:	e04a                	sd	s2,0(sp)
    80001a6c:	1000                	addi	s0,sp,32
    80001a6e:	84aa                	mv	s1,a0
    80001a70:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a72:	4681                	li	a3,0
    80001a74:	4605                	li	a2,1
    80001a76:	040005b7          	lui	a1,0x4000
    80001a7a:	15fd                	addi	a1,a1,-1
    80001a7c:	05b2                	slli	a1,a1,0xc
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	7f8080e7          	jalr	2040(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001a86:	4681                	li	a3,0
    80001a88:	4605                	li	a2,1
    80001a8a:	020005b7          	lui	a1,0x2000
    80001a8e:	15fd                	addi	a1,a1,-1
    80001a90:	05b6                	slli	a1,a1,0xd
    80001a92:	8526                	mv	a0,s1
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	7e2080e7          	jalr	2018(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001a9c:	85ca                	mv	a1,s2
    80001a9e:	8526                	mv	a0,s1
    80001aa0:	00000097          	auipc	ra,0x0
    80001aa4:	a96080e7          	jalr	-1386(ra) # 80001536 <uvmfree>
}
    80001aa8:	60e2                	ld	ra,24(sp)
    80001aaa:	6442                	ld	s0,16(sp)
    80001aac:	64a2                	ld	s1,8(sp)
    80001aae:	6902                	ld	s2,0(sp)
    80001ab0:	6105                	addi	sp,sp,32
    80001ab2:	8082                	ret

0000000080001ab4 <growproc>:
{
    80001ab4:	1101                	addi	sp,sp,-32
    80001ab6:	ec06                	sd	ra,24(sp)
    80001ab8:	e822                	sd	s0,16(sp)
    80001aba:	e426                	sd	s1,8(sp)
    80001abc:	e04a                	sd	s2,0(sp)
    80001abe:	1000                	addi	s0,sp,32
    80001ac0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ac2:	00000097          	auipc	ra,0x0
    80001ac6:	e46080e7          	jalr	-442(ra) # 80001908 <myproc>
    80001aca:	892a                	mv	s2,a0
  sz = p->sz;
    80001acc:	752c                	ld	a1,104(a0)
    80001ace:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ad2:	00904f63          	bgtz	s1,80001af0 <growproc+0x3c>
  } else if(n < 0){
    80001ad6:	0204cc63          	bltz	s1,80001b0e <growproc+0x5a>
  p->sz = sz;
    80001ada:	1602                	slli	a2,a2,0x20
    80001adc:	9201                	srli	a2,a2,0x20
    80001ade:	06c93423          	sd	a2,104(s2)
  return 0;
    80001ae2:	4501                	li	a0,0
}
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001af0:	9e25                	addw	a2,a2,s1
    80001af2:	1602                	slli	a2,a2,0x20
    80001af4:	9201                	srli	a2,a2,0x20
    80001af6:	1582                	slli	a1,a1,0x20
    80001af8:	9181                	srli	a1,a1,0x20
    80001afa:	7928                	ld	a0,112(a0)
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	926080e7          	jalr	-1754(ra) # 80001422 <uvmalloc>
    80001b04:	0005061b          	sext.w	a2,a0
    80001b08:	fa69                	bnez	a2,80001ada <growproc+0x26>
      return -1;
    80001b0a:	557d                	li	a0,-1
    80001b0c:	bfe1                	j	80001ae4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001b0e:	9e25                	addw	a2,a2,s1
    80001b10:	1602                	slli	a2,a2,0x20
    80001b12:	9201                	srli	a2,a2,0x20
    80001b14:	1582                	slli	a1,a1,0x20
    80001b16:	9181                	srli	a1,a1,0x20
    80001b18:	7928                	ld	a0,112(a0)
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	8c0080e7          	jalr	-1856(ra) # 800013da <uvmdealloc>
    80001b22:	0005061b          	sext.w	a2,a0
    80001b26:	bf55                	j	80001ada <growproc+0x26>

0000000080001b28 <sched>:
{
    80001b28:	7179                	addi	sp,sp,-48
    80001b2a:	f406                	sd	ra,40(sp)
    80001b2c:	f022                	sd	s0,32(sp)
    80001b2e:	ec26                	sd	s1,24(sp)
    80001b30:	e84a                	sd	s2,16(sp)
    80001b32:	e44e                	sd	s3,8(sp)
    80001b34:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001b36:	00000097          	auipc	ra,0x0
    80001b3a:	dd2080e7          	jalr	-558(ra) # 80001908 <myproc>
    80001b3e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	02a080e7          	jalr	42(ra) # 80000b6a <holding>
    80001b48:	c559                	beqz	a0,80001bd6 <sched+0xae>
    80001b4a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001b4c:	0007871b          	sext.w	a4,a5
    80001b50:	00271793          	slli	a5,a4,0x2
    80001b54:	97ba                	add	a5,a5,a4
    80001b56:	0796                	slli	a5,a5,0x5
    80001b58:	0000f717          	auipc	a4,0xf
    80001b5c:	74870713          	addi	a4,a4,1864 # 800112a0 <cpus>
    80001b60:	97ba                	add	a5,a5,a4
    80001b62:	5fb8                	lw	a4,120(a5)
    80001b64:	4785                	li	a5,1
    80001b66:	08f71063          	bne	a4,a5,80001be6 <sched+0xbe>
  if(p->state == RUNNING)
    80001b6a:	4c98                	lw	a4,24(s1)
    80001b6c:	4791                	li	a5,4
    80001b6e:	08f70463          	beq	a4,a5,80001bf6 <sched+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001b76:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001b78:	e7d9                	bnez	a5,80001c06 <sched+0xde>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b7a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001b7c:	0000f917          	auipc	s2,0xf
    80001b80:	72490913          	addi	s2,s2,1828 # 800112a0 <cpus>
    80001b84:	0007871b          	sext.w	a4,a5
    80001b88:	00271793          	slli	a5,a4,0x2
    80001b8c:	97ba                	add	a5,a5,a4
    80001b8e:	0796                	slli	a5,a5,0x5
    80001b90:	97ca                	add	a5,a5,s2
    80001b92:	07c7a983          	lw	s3,124(a5)
    80001b96:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80001b98:	0005879b          	sext.w	a5,a1
    80001b9c:	00279593          	slli	a1,a5,0x2
    80001ba0:	95be                	add	a1,a1,a5
    80001ba2:	0596                	slli	a1,a1,0x5
    80001ba4:	05a1                	addi	a1,a1,8
    80001ba6:	95ca                	add	a1,a1,s2
    80001ba8:	08048513          	addi	a0,s1,128
    80001bac:	00001097          	auipc	ra,0x1
    80001bb0:	f32080e7          	jalr	-206(ra) # 80002ade <swtch>
    80001bb4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001bb6:	0007871b          	sext.w	a4,a5
    80001bba:	00271793          	slli	a5,a4,0x2
    80001bbe:	97ba                	add	a5,a5,a4
    80001bc0:	0796                	slli	a5,a5,0x5
    80001bc2:	993e                	add	s2,s2,a5
    80001bc4:	07392e23          	sw	s3,124(s2)
}
    80001bc8:	70a2                	ld	ra,40(sp)
    80001bca:	7402                	ld	s0,32(sp)
    80001bcc:	64e2                	ld	s1,24(sp)
    80001bce:	6942                	ld	s2,16(sp)
    80001bd0:	69a2                	ld	s3,8(sp)
    80001bd2:	6145                	addi	sp,sp,48
    80001bd4:	8082                	ret
    panic("sched p->lock");
    80001bd6:	00006517          	auipc	a0,0x6
    80001bda:	60a50513          	addi	a0,a0,1546 # 800081e0 <digits+0x1a0>
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	960080e7          	jalr	-1696(ra) # 8000053e <panic>
    panic("sched locks");
    80001be6:	00006517          	auipc	a0,0x6
    80001bea:	60a50513          	addi	a0,a0,1546 # 800081f0 <digits+0x1b0>
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	950080e7          	jalr	-1712(ra) # 8000053e <panic>
    panic("sched running");
    80001bf6:	00006517          	auipc	a0,0x6
    80001bfa:	60a50513          	addi	a0,a0,1546 # 80008200 <digits+0x1c0>
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	940080e7          	jalr	-1728(ra) # 8000053e <panic>
    panic("sched interruptible");
    80001c06:	00006517          	auipc	a0,0x6
    80001c0a:	60a50513          	addi	a0,a0,1546 # 80008210 <digits+0x1d0>
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	930080e7          	jalr	-1744(ra) # 8000053e <panic>

0000000080001c16 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80001c16:	7179                	addi	sp,sp,-48
    80001c18:	f406                	sd	ra,40(sp)
    80001c1a:	f022                	sd	s0,32(sp)
    80001c1c:	ec26                	sd	s1,24(sp)
    80001c1e:	e84a                	sd	s2,16(sp)
    80001c20:	e44e                	sd	s3,8(sp)
    80001c22:	1800                	addi	s0,sp,48
    80001c24:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80001c26:	00010497          	auipc	s1,0x10
    80001c2a:	bf248493          	addi	s1,s1,-1038 # 80011818 <proc>
    80001c2e:	00016997          	auipc	s3,0x16
    80001c32:	dea98993          	addi	s3,s3,-534 # 80017a18 <tickslock>
    acquire(&p->lock);
    80001c36:	8526                	mv	a0,s1
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	fac080e7          	jalr	-84(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80001c40:	589c                	lw	a5,48(s1)
    80001c42:	01278d63          	beq	a5,s2,80001c5c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80001c46:	8526                	mv	a0,s1
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	050080e7          	jalr	80(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80001c50:	18848493          	addi	s1,s1,392
    80001c54:	ff3491e3          	bne	s1,s3,80001c36 <kill+0x20>
  }
  return -1;
    80001c58:	557d                	li	a0,-1
    80001c5a:	a829                	j	80001c74 <kill+0x5e>
      p->killed = 1;
    80001c5c:	4785                	li	a5,1
    80001c5e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80001c60:	4c98                	lw	a4,24(s1)
    80001c62:	4789                	li	a5,2
    80001c64:	00f70f63          	beq	a4,a5,80001c82 <kill+0x6c>
      release(&p->lock);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	02e080e7          	jalr	46(ra) # 80000c98 <release>
      return 0;
    80001c72:	4501                	li	a0,0
}
    80001c74:	70a2                	ld	ra,40(sp)
    80001c76:	7402                	ld	s0,32(sp)
    80001c78:	64e2                	ld	s1,24(sp)
    80001c7a:	6942                	ld	s2,16(sp)
    80001c7c:	69a2                	ld	s3,8(sp)
    80001c7e:	6145                	addi	sp,sp,48
    80001c80:	8082                	ret
        p->state = RUNNABLE;
    80001c82:	478d                	li	a5,3
    80001c84:	cc9c                	sw	a5,24(s1)
    80001c86:	b7cd                	j	80001c68 <kill+0x52>

0000000080001c88 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80001c88:	7179                	addi	sp,sp,-48
    80001c8a:	f406                	sd	ra,40(sp)
    80001c8c:	f022                	sd	s0,32(sp)
    80001c8e:	ec26                	sd	s1,24(sp)
    80001c90:	e84a                	sd	s2,16(sp)
    80001c92:	e44e                	sd	s3,8(sp)
    80001c94:	e052                	sd	s4,0(sp)
    80001c96:	1800                	addi	s0,sp,48
    80001c98:	84aa                	mv	s1,a0
    80001c9a:	892e                	mv	s2,a1
    80001c9c:	89b2                	mv	s3,a2
    80001c9e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	c68080e7          	jalr	-920(ra) # 80001908 <myproc>
  if(user_dst){
    80001ca8:	c08d                	beqz	s1,80001cca <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80001caa:	86d2                	mv	a3,s4
    80001cac:	864e                	mv	a2,s3
    80001cae:	85ca                	mv	a1,s2
    80001cb0:	7928                	ld	a0,112(a0)
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	9c0080e7          	jalr	-1600(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80001cba:	70a2                	ld	ra,40(sp)
    80001cbc:	7402                	ld	s0,32(sp)
    80001cbe:	64e2                	ld	s1,24(sp)
    80001cc0:	6942                	ld	s2,16(sp)
    80001cc2:	69a2                	ld	s3,8(sp)
    80001cc4:	6a02                	ld	s4,0(sp)
    80001cc6:	6145                	addi	sp,sp,48
    80001cc8:	8082                	ret
    memmove((char *)dst, src, len);
    80001cca:	000a061b          	sext.w	a2,s4
    80001cce:	85ce                	mv	a1,s3
    80001cd0:	854a                	mv	a0,s2
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	06e080e7          	jalr	110(ra) # 80000d40 <memmove>
    return 0;
    80001cda:	8526                	mv	a0,s1
    80001cdc:	bff9                	j	80001cba <either_copyout+0x32>

0000000080001cde <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80001cde:	7179                	addi	sp,sp,-48
    80001ce0:	f406                	sd	ra,40(sp)
    80001ce2:	f022                	sd	s0,32(sp)
    80001ce4:	ec26                	sd	s1,24(sp)
    80001ce6:	e84a                	sd	s2,16(sp)
    80001ce8:	e44e                	sd	s3,8(sp)
    80001cea:	e052                	sd	s4,0(sp)
    80001cec:	1800                	addi	s0,sp,48
    80001cee:	892a                	mv	s2,a0
    80001cf0:	84ae                	mv	s1,a1
    80001cf2:	89b2                	mv	s3,a2
    80001cf4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	c12080e7          	jalr	-1006(ra) # 80001908 <myproc>
  if(user_src){
    80001cfe:	c08d                	beqz	s1,80001d20 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80001d00:	86d2                	mv	a3,s4
    80001d02:	864e                	mv	a2,s3
    80001d04:	85ca                	mv	a1,s2
    80001d06:	7928                	ld	a0,112(a0)
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	9f6080e7          	jalr	-1546(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80001d10:	70a2                	ld	ra,40(sp)
    80001d12:	7402                	ld	s0,32(sp)
    80001d14:	64e2                	ld	s1,24(sp)
    80001d16:	6942                	ld	s2,16(sp)
    80001d18:	69a2                	ld	s3,8(sp)
    80001d1a:	6a02                	ld	s4,0(sp)
    80001d1c:	6145                	addi	sp,sp,48
    80001d1e:	8082                	ret
    memmove(dst, (char*)src, len);
    80001d20:	000a061b          	sext.w	a2,s4
    80001d24:	85ce                	mv	a1,s3
    80001d26:	854a                	mv	a0,s2
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	018080e7          	jalr	24(ra) # 80000d40 <memmove>
    return 0;
    80001d30:	8526                	mv	a0,s1
    80001d32:	bff9                	j	80001d10 <either_copyin+0x32>

0000000080001d34 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80001d34:	715d                	addi	sp,sp,-80
    80001d36:	e486                	sd	ra,72(sp)
    80001d38:	e0a2                	sd	s0,64(sp)
    80001d3a:	fc26                	sd	s1,56(sp)
    80001d3c:	f84a                	sd	s2,48(sp)
    80001d3e:	f44e                	sd	s3,40(sp)
    80001d40:	f052                	sd	s4,32(sp)
    80001d42:	ec56                	sd	s5,24(sp)
    80001d44:	e85a                	sd	s6,16(sp)
    80001d46:	e45e                	sd	s7,8(sp)
    80001d48:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80001d4a:	00006517          	auipc	a0,0x6
    80001d4e:	37e50513          	addi	a0,a0,894 # 800080c8 <digits+0x88>
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	836080e7          	jalr	-1994(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001d5a:	00010497          	auipc	s1,0x10
    80001d5e:	c3648493          	addi	s1,s1,-970 # 80011990 <proc+0x178>
    80001d62:	00016917          	auipc	s2,0x16
    80001d66:	e2e90913          	addi	s2,s2,-466 # 80017b90 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d6a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80001d6c:	00006997          	auipc	s3,0x6
    80001d70:	4bc98993          	addi	s3,s3,1212 # 80008228 <digits+0x1e8>
    printf("%d %s %s", p->pid, state, p->name);
    80001d74:	00006a97          	auipc	s5,0x6
    80001d78:	4bca8a93          	addi	s5,s5,1212 # 80008230 <digits+0x1f0>
    printf("\n");
    80001d7c:	00006a17          	auipc	s4,0x6
    80001d80:	34ca0a13          	addi	s4,s4,844 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d84:	00006b97          	auipc	s7,0x6
    80001d88:	54cb8b93          	addi	s7,s7,1356 # 800082d0 <states.1745>
    80001d8c:	a00d                	j	80001dae <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80001d8e:	eb86a583          	lw	a1,-328(a3)
    80001d92:	8556                	mv	a0,s5
    80001d94:	ffffe097          	auipc	ra,0xffffe
    80001d98:	7f4080e7          	jalr	2036(ra) # 80000588 <printf>
    printf("\n");
    80001d9c:	8552                	mv	a0,s4
    80001d9e:	ffffe097          	auipc	ra,0xffffe
    80001da2:	7ea080e7          	jalr	2026(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001da6:	18848493          	addi	s1,s1,392
    80001daa:	03248163          	beq	s1,s2,80001dcc <procdump+0x98>
    if(p->state == UNUSED)
    80001dae:	86a6                	mv	a3,s1
    80001db0:	ea04a783          	lw	a5,-352(s1)
    80001db4:	dbed                	beqz	a5,80001da6 <procdump+0x72>
      state = "???";
    80001db6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001db8:	fcfb6be3          	bltu	s6,a5,80001d8e <procdump+0x5a>
    80001dbc:	1782                	slli	a5,a5,0x20
    80001dbe:	9381                	srli	a5,a5,0x20
    80001dc0:	078e                	slli	a5,a5,0x3
    80001dc2:	97de                	add	a5,a5,s7
    80001dc4:	6390                	ld	a2,0(a5)
    80001dc6:	f661                	bnez	a2,80001d8e <procdump+0x5a>
      state = "???";
    80001dc8:	864e                	mv	a2,s3
    80001dca:	b7d1                	j	80001d8e <procdump+0x5a>
  }
}
    80001dcc:	60a6                	ld	ra,72(sp)
    80001dce:	6406                	ld	s0,64(sp)
    80001dd0:	74e2                	ld	s1,56(sp)
    80001dd2:	7942                	ld	s2,48(sp)
    80001dd4:	79a2                	ld	s3,40(sp)
    80001dd6:	7a02                	ld	s4,32(sp)
    80001dd8:	6ae2                	ld	s5,24(sp)
    80001dda:	6b42                	ld	s6,16(sp)
    80001ddc:	6ba2                	ld	s7,8(sp)
    80001dde:	6161                	addi	sp,sp,80
    80001de0:	8082                	ret

0000000080001de2 <get_cpu>:
    return cpu_num;
}

int
get_cpu()
{
    80001de2:	1101                	addi	sp,sp,-32
    80001de4:	ec06                	sd	ra,24(sp)
    80001de6:	e822                	sd	s0,16(sp)
    80001de8:	e426                	sd	s1,8(sp)
    80001dea:	e04a                	sd	s2,0(sp)
    80001dec:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	b1a080e7          	jalr	-1254(ra) # 80001908 <myproc>
    80001df6:	84aa                	mv	s1,a0
  
  int cpu_num;
  acquire(&p->lock);
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	dec080e7          	jalr	-532(ra) # 80000be4 <acquire>
  cpu_num = p->cpu_num;
    80001e00:	0344a903          	lw	s2,52(s1)
  release(&p->lock);
    80001e04:	8526                	mv	a0,s1
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	e92080e7          	jalr	-366(ra) # 80000c98 <release>
  return cpu_num;
}
    80001e0e:	854a                	mv	a0,s2
    80001e10:	60e2                	ld	ra,24(sp)
    80001e12:	6442                	ld	s0,16(sp)
    80001e14:	64a2                	ld	s1,8(sp)
    80001e16:	6902                	ld	s2,0(sp)
    80001e18:	6105                	addi	sp,sp,32
    80001e1a:	8082                	ret

0000000080001e1c <add_to_list>:
//void initlock(struct spinlock *, char *)

void
add_to_list(int* curr_proc_index, struct proc* next_proc, struct spinlock* lock) {
    80001e1c:	7139                	addi	sp,sp,-64
    80001e1e:	fc06                	sd	ra,56(sp)
    80001e20:	f822                	sd	s0,48(sp)
    80001e22:	f426                	sd	s1,40(sp)
    80001e24:	f04a                	sd	s2,32(sp)
    80001e26:	ec4e                	sd	s3,24(sp)
    80001e28:	e852                	sd	s4,16(sp)
    80001e2a:	e456                	sd	s5,8(sp)
    80001e2c:	e05a                	sd	s6,0(sp)
    80001e2e:	0080                	addi	s0,sp,64
    80001e30:	84aa                	mv	s1,a0
    80001e32:	8b2e                	mv	s6,a1
    80001e34:	8932                	mv	s2,a2
  acquire(lock);
    80001e36:	8532                	mv	a0,a2
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	dac080e7          	jalr	-596(ra) # 80000be4 <acquire>

  if(*curr_proc_index == -1){
    80001e40:	409c                	lw	a5,0(s1)
    80001e42:	577d                	li	a4,-1
    80001e44:	0ae78963          	beq	a5,a4,80001ef6 <add_to_list+0xda>
    *curr_proc_index = next_proc->proc_index;
    next_proc->next_proc_index = -1;
    release(lock);
    return;
  }
  struct proc* curr_node = &proc[*curr_proc_index];
    80001e48:	18800513          	li	a0,392
    80001e4c:	02a787b3          	mul	a5,a5,a0
    80001e50:	00010517          	auipc	a0,0x10
    80001e54:	9c850513          	addi	a0,a0,-1592 # 80011818 <proc>
    80001e58:	00a784b3          	add	s1,a5,a0
  acquire(&curr_node->proc_lock);
    80001e5c:	04078793          	addi	a5,a5,64
    80001e60:	953e                	add	a0,a0,a5
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	d82080e7          	jalr	-638(ra) # 80000be4 <acquire>
  release(lock);
    80001e6a:	854a                	mv	a0,s2
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e2c080e7          	jalr	-468(ra) # 80000c98 <release>
  
  while(curr_node->next_proc_index != -1){
    80001e74:	5c88                	lw	a0,56(s1)
    80001e76:	57fd                	li	a5,-1
    80001e78:	04f50963          	beq	a0,a5,80001eca <add_to_list+0xae>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80001e7c:	18800993          	li	s3,392
    80001e80:	00010917          	auipc	s2,0x10
    80001e84:	99890913          	addi	s2,s2,-1640 # 80011818 <proc>
    release(&curr_node->proc_lock);
    curr_node = &proc[curr_node->next_proc_index];
    printf("moving to: %d", curr_node->next_proc_index);
    80001e88:	00006a97          	auipc	s5,0x6
    80001e8c:	3b8a8a93          	addi	s5,s5,952 # 80008240 <digits+0x200>
  while(curr_node->next_proc_index != -1){
    80001e90:	5a7d                	li	s4,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80001e92:	03350533          	mul	a0,a0,s3
    80001e96:	04050513          	addi	a0,a0,64
    80001e9a:	954a                	add	a0,a0,s2
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	d48080e7          	jalr	-696(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    80001ea4:	04048513          	addi	a0,s1,64
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	df0080e7          	jalr	-528(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    80001eb0:	5c84                	lw	s1,56(s1)
    80001eb2:	033484b3          	mul	s1,s1,s3
    80001eb6:	94ca                	add	s1,s1,s2
    printf("moving to: %d", curr_node->next_proc_index);
    80001eb8:	5c8c                	lw	a1,56(s1)
    80001eba:	8556                	mv	a0,s5
    80001ebc:	ffffe097          	auipc	ra,0xffffe
    80001ec0:	6cc080e7          	jalr	1740(ra) # 80000588 <printf>
  while(curr_node->next_proc_index != -1){
    80001ec4:	5c88                	lw	a0,56(s1)
    80001ec6:	fd4516e3          	bne	a0,s4,80001e92 <add_to_list+0x76>
  }

  //result = cas(&curr_node->next_proc_index, -1, next_proc->proc_index) == 0;
  curr_node->next_proc_index = next_proc->proc_index;
    80001eca:	03cb2783          	lw	a5,60(s6) # 103c <_entry-0x7fffefc4>
    80001ece:	dc9c                	sw	a5,56(s1)
  next_proc->next_proc_index = -1;
    80001ed0:	57fd                	li	a5,-1
    80001ed2:	02fb2c23          	sw	a5,56(s6)
  release(&curr_node->proc_lock);
    80001ed6:	04048513          	addi	a0,s1,64
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	dbe080e7          	jalr	-578(ra) # 80000c98 <release>

}
    80001ee2:	70e2                	ld	ra,56(sp)
    80001ee4:	7442                	ld	s0,48(sp)
    80001ee6:	74a2                	ld	s1,40(sp)
    80001ee8:	7902                	ld	s2,32(sp)
    80001eea:	69e2                	ld	s3,24(sp)
    80001eec:	6a42                	ld	s4,16(sp)
    80001eee:	6aa2                	ld	s5,8(sp)
    80001ef0:	6b02                	ld	s6,0(sp)
    80001ef2:	6121                	addi	sp,sp,64
    80001ef4:	8082                	ret
    *curr_proc_index = next_proc->proc_index;
    80001ef6:	03cb2783          	lw	a5,60(s6)
    80001efa:	c09c                	sw	a5,0(s1)
    next_proc->next_proc_index = -1;
    80001efc:	57fd                	li	a5,-1
    80001efe:	02fb2c23          	sw	a5,56(s6)
    release(lock);
    80001f02:	854a                	mv	a0,s2
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	d94080e7          	jalr	-620(ra) # 80000c98 <release>
    return;
    80001f0c:	bfd9                	j	80001ee2 <add_to_list+0xc6>

0000000080001f0e <procinit>:
{
    80001f0e:	711d                	addi	sp,sp,-96
    80001f10:	ec86                	sd	ra,88(sp)
    80001f12:	e8a2                	sd	s0,80(sp)
    80001f14:	e4a6                	sd	s1,72(sp)
    80001f16:	e0ca                	sd	s2,64(sp)
    80001f18:	fc4e                	sd	s3,56(sp)
    80001f1a:	f852                	sd	s4,48(sp)
    80001f1c:	f456                	sd	s5,40(sp)
    80001f1e:	f05a                	sd	s6,32(sp)
    80001f20:	ec5e                	sd	s7,24(sp)
    80001f22:	e862                	sd	s8,16(sp)
    80001f24:	e466                	sd	s9,8(sp)
    80001f26:	e06a                	sd	s10,0(sp)
    80001f28:	1080                	addi	s0,sp,96
  initlock(&pid_lock, "nextpid");
    80001f2a:	00006597          	auipc	a1,0x6
    80001f2e:	32658593          	addi	a1,a1,806 # 80008250 <digits+0x210>
    80001f32:	00010517          	auipc	a0,0x10
    80001f36:	86e50513          	addi	a0,a0,-1938 # 800117a0 <pid_lock>
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	c1a080e7          	jalr	-998(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001f42:	00006597          	auipc	a1,0x6
    80001f46:	31658593          	addi	a1,a1,790 # 80008258 <digits+0x218>
    80001f4a:	00010517          	auipc	a0,0x10
    80001f4e:	86e50513          	addi	a0,a0,-1938 # 800117b8 <wait_lock>
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	c02080e7          	jalr	-1022(ra) # 80000b54 <initlock>
  int index = 0;
    80001f5a:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001f5c:	00010497          	auipc	s1,0x10
    80001f60:	8bc48493          	addi	s1,s1,-1860 # 80011818 <proc>
      initlock(&p->lock, "proc");
    80001f64:	00006d17          	auipc	s10,0x6
    80001f68:	304d0d13          	addi	s10,s10,772 # 80008268 <digits+0x228>
      p->kstack = KSTACK((int) (p - proc));
    80001f6c:	8ca6                	mv	s9,s1
    80001f6e:	00006c17          	auipc	s8,0x6
    80001f72:	092c0c13          	addi	s8,s8,146 # 80008000 <etext>
    80001f76:	040009b7          	lui	s3,0x4000
    80001f7a:	19fd                	addi	s3,s3,-1
    80001f7c:	09b2                	slli	s3,s3,0xc
      p->next_proc_index = -1;
    80001f7e:	5bfd                	li	s7,-1
      add_to_list(&unused_head, p, &lock_unused_list);
    80001f80:	00010b17          	auipc	s6,0x10
    80001f84:	850b0b13          	addi	s6,s6,-1968 # 800117d0 <lock_unused_list>
    80001f88:	00007a97          	auipc	s5,0x7
    80001f8c:	8b4a8a93          	addi	s5,s5,-1868 # 8000883c <unused_head>
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001f90:	00016a17          	auipc	s4,0x16
    80001f94:	a88a0a13          	addi	s4,s4,-1400 # 80017a18 <tickslock>
      initlock(&p->lock, "proc");
    80001f98:	85ea                	mv	a1,s10
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	bb8080e7          	jalr	-1096(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001fa4:	419487b3          	sub	a5,s1,s9
    80001fa8:	878d                	srai	a5,a5,0x3
    80001faa:	000c3703          	ld	a4,0(s8)
    80001fae:	02e787b3          	mul	a5,a5,a4
    80001fb2:	2785                	addiw	a5,a5,1
    80001fb4:	00d7979b          	slliw	a5,a5,0xd
    80001fb8:	40f987b3          	sub	a5,s3,a5
    80001fbc:	f0bc                	sd	a5,96(s1)
      p->proc_index = index;
    80001fbe:	0324ae23          	sw	s2,60(s1)
      p->next_proc_index = -1;
    80001fc2:	0374ac23          	sw	s7,56(s1)
      add_to_list(&unused_head, p, &lock_unused_list);
    80001fc6:	865a                	mv	a2,s6
    80001fc8:	85a6                	mv	a1,s1
    80001fca:	8556                	mv	a0,s5
    80001fcc:	00000097          	auipc	ra,0x0
    80001fd0:	e50080e7          	jalr	-432(ra) # 80001e1c <add_to_list>
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001fd4:	18848493          	addi	s1,s1,392
    80001fd8:	2905                	addiw	s2,s2,1
    80001fda:	fb449fe3          	bne	s1,s4,80001f98 <procinit+0x8a>
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001fde:	0000f797          	auipc	a5,0xf
    80001fe2:	2c278793          	addi	a5,a5,706 # 800112a0 <cpus>
      c->runnable_head = -1;
    80001fe6:	56fd                	li	a3,-1
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001fe8:	0000f717          	auipc	a4,0xf
    80001fec:	7b870713          	addi	a4,a4,1976 # 800117a0 <pid_lock>
      c->runnable_head = -1;
    80001ff0:	08d7a023          	sw	a3,128(a5)
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001ff4:	0a078793          	addi	a5,a5,160
    80001ff8:	fee79ce3          	bne	a5,a4,80001ff0 <procinit+0xe2>
}
    80001ffc:	60e6                	ld	ra,88(sp)
    80001ffe:	6446                	ld	s0,80(sp)
    80002000:	64a6                	ld	s1,72(sp)
    80002002:	6906                	ld	s2,64(sp)
    80002004:	79e2                	ld	s3,56(sp)
    80002006:	7a42                	ld	s4,48(sp)
    80002008:	7aa2                	ld	s5,40(sp)
    8000200a:	7b02                	ld	s6,32(sp)
    8000200c:	6be2                	ld	s7,24(sp)
    8000200e:	6c42                	ld	s8,16(sp)
    80002010:	6ca2                	ld	s9,8(sp)
    80002012:	6d02                	ld	s10,0(sp)
    80002014:	6125                	addi	sp,sp,96
    80002016:	8082                	ret

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	8e6080e7          	jalr	-1818(ra) # 80001908 <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	bb8080e7          	jalr	-1096(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    80002038:	58c8                	lw	a0,52(s1)
    8000203a:	00251793          	slli	a5,a0,0x2
    8000203e:	97aa                	add	a5,a5,a0
    80002040:	0796                	slli	a5,a5,0x5
    80002042:	0000f517          	auipc	a0,0xf
    80002046:	25e50513          	addi	a0,a0,606 # 800112a0 <cpus>
    8000204a:	08878613          	addi	a2,a5,136
    8000204e:	08078793          	addi	a5,a5,128
    80002052:	962a                	add	a2,a2,a0
    80002054:	85a6                	mv	a1,s1
    80002056:	953e                	add	a0,a0,a5
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	dc4080e7          	jalr	-572(ra) # 80001e1c <add_to_list>
  sched();
    80002060:	00000097          	auipc	ra,0x0
    80002064:	ac8080e7          	jalr	-1336(ra) # 80001b28 <sched>
  release(&p->lock);
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	c2e080e7          	jalr	-978(ra) # 80000c98 <release>
}
    80002072:	60e2                	ld	ra,24(sp)
    80002074:	6442                	ld	s0,16(sp)
    80002076:	64a2                	ld	s1,8(sp)
    80002078:	6105                	addi	sp,sp,32
    8000207a:	8082                	ret

000000008000207c <set_cpu>:
{
    8000207c:	1101                	addi	sp,sp,-32
    8000207e:	ec06                	sd	ra,24(sp)
    80002080:	e822                	sd	s0,16(sp)
    80002082:	e426                	sd	s1,8(sp)
    80002084:	1000                	addi	s0,sp,32
    80002086:	84aa                	mv	s1,a0
    struct proc* p = myproc();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	880080e7          	jalr	-1920(ra) # 80001908 <myproc>
    if(cas(&p->cpu_num, curr_cpu, cpu_num) !=0)
    80002090:	8626                	mv	a2,s1
    80002092:	594c                	lw	a1,52(a0)
    80002094:	03450513          	addi	a0,a0,52
    80002098:	00004097          	auipc	ra,0x4
    8000209c:	67e080e7          	jalr	1662(ra) # 80006716 <cas>
    800020a0:	e919                	bnez	a0,800020b6 <set_cpu+0x3a>
    yield();
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	f76080e7          	jalr	-138(ra) # 80002018 <yield>
    return cpu_num;
    800020aa:	8526                	mv	a0,s1
}
    800020ac:	60e2                	ld	ra,24(sp)
    800020ae:	6442                	ld	s0,16(sp)
    800020b0:	64a2                	ld	s1,8(sp)
    800020b2:	6105                	addi	sp,sp,32
    800020b4:	8082                	ret
        return -1;
    800020b6:	557d                	li	a0,-1
    800020b8:	bfd5                	j	800020ac <set_cpu+0x30>

00000000800020ba <sleep>:
{
    800020ba:	7179                	addi	sp,sp,-48
    800020bc:	f406                	sd	ra,40(sp)
    800020be:	f022                	sd	s0,32(sp)
    800020c0:	ec26                	sd	s1,24(sp)
    800020c2:	e84a                	sd	s2,16(sp)
    800020c4:	e44e                	sd	s3,8(sp)
    800020c6:	1800                	addi	s0,sp,48
    800020c8:	89aa                	mv	s3,a0
    800020ca:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	83c080e7          	jalr	-1988(ra) # 80001908 <myproc>
    800020d4:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	b0e080e7          	jalr	-1266(ra) # 80000be4 <acquire>
  add_to_list(&sleeping_head, p, &lock_sleeping_list);
    800020de:	0000f617          	auipc	a2,0xf
    800020e2:	70a60613          	addi	a2,a2,1802 # 800117e8 <lock_sleeping_list>
    800020e6:	85a6                	mv	a1,s1
    800020e8:	00006517          	auipc	a0,0x6
    800020ec:	75050513          	addi	a0,a0,1872 # 80008838 <sleeping_head>
    800020f0:	00000097          	auipc	ra,0x0
    800020f4:	d2c080e7          	jalr	-724(ra) # 80001e1c <add_to_list>
  release(lk);
    800020f8:	854a                	mv	a0,s2
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	b9e080e7          	jalr	-1122(ra) # 80000c98 <release>
  p->chan = chan;
    80002102:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002106:	4789                	li	a5,2
    80002108:	cc9c                	sw	a5,24(s1)
  sched();
    8000210a:	00000097          	auipc	ra,0x0
    8000210e:	a1e080e7          	jalr	-1506(ra) # 80001b28 <sched>
  p->chan = 0;
    80002112:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    80002116:	8526                	mv	a0,s1
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	b80080e7          	jalr	-1152(ra) # 80000c98 <release>
  acquire(lk);
    80002120:	854a                	mv	a0,s2
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	ac2080e7          	jalr	-1342(ra) # 80000be4 <acquire>
}
    8000212a:	70a2                	ld	ra,40(sp)
    8000212c:	7402                	ld	s0,32(sp)
    8000212e:	64e2                	ld	s1,24(sp)
    80002130:	6942                	ld	s2,16(sp)
    80002132:	69a2                	ld	s3,8(sp)
    80002134:	6145                	addi	sp,sp,48
    80002136:	8082                	ret

0000000080002138 <remove_from_list>:

int remove_from_list(int* curr_proc_index, struct proc* proc_to_remove, struct spinlock* lock) {
    80002138:	7139                	addi	sp,sp,-64
    8000213a:	fc06                	sd	ra,56(sp)
    8000213c:	f822                	sd	s0,48(sp)
    8000213e:	f426                	sd	s1,40(sp)
    80002140:	f04a                	sd	s2,32(sp)
    80002142:	ec4e                	sd	s3,24(sp)
    80002144:	e852                	sd	s4,16(sp)
    80002146:	e456                	sd	s5,8(sp)
    80002148:	e05a                	sd	s6,0(sp)
    8000214a:	0080                	addi	s0,sp,64
    8000214c:	84aa                	mv	s1,a0
    8000214e:	892e                	mv	s2,a1
    80002150:	89b2                	mv	s3,a2
  acquire(lock);
    80002152:	8532                	mv	a0,a2
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	a90080e7          	jalr	-1392(ra) # 80000be4 <acquire>
  if(*curr_proc_index == -1) 
    8000215c:	0004aa03          	lw	s4,0(s1)
    80002160:	57fd                	li	a5,-1
    80002162:	0afa0663          	beq	s4,a5,8000220e <remove_from_list+0xd6>
  {
      release(lock);
      return -1;
  }
  acquire(&proc_to_remove->proc_lock);
    80002166:	04090b13          	addi	s6,s2,64
    8000216a:	855a                	mv	a0,s6
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	a78080e7          	jalr	-1416(ra) # 80000be4 <acquire>

  if(*curr_proc_index == proc_to_remove->proc_index){
    80002174:	4088                	lw	a0,0(s1)
    80002176:	03c92783          	lw	a5,60(s2)
    8000217a:	0aa78063          	beq	a5,a0,8000221a <remove_from_list+0xe2>
      release(&proc_to_remove->proc_lock);
      release(lock);
      return 1;
  }
  
  struct proc* curr_node = &proc[*curr_proc_index];
    8000217e:	18800793          	li	a5,392
    80002182:	02f50533          	mul	a0,a0,a5
    80002186:	0000f797          	auipc	a5,0xf
    8000218a:	69278793          	addi	a5,a5,1682 # 80011818 <proc>
    8000218e:	00f504b3          	add	s1,a0,a5
  acquire(&curr_node->proc_lock);
    80002192:	04050513          	addi	a0,a0,64
    80002196:	953e                	add	a0,a0,a5
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	a4c080e7          	jalr	-1460(ra) # 80000be4 <acquire>
  release(lock);
    800021a0:	854e                	mv	a0,s3
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	af6080e7          	jalr	-1290(ra) # 80000c98 <release>
  
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    800021aa:	5c88                	lw	a0,56(s1)
    800021ac:	57fd                	li	a5,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    800021ae:	18800a13          	li	s4,392
    800021b2:	0000f997          	auipc	s3,0xf
    800021b6:	66698993          	addi	s3,s3,1638 # 80011818 <proc>
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    800021ba:	5afd                	li	s5,-1
    800021bc:	02f50c63          	beq	a0,a5,800021f4 <remove_from_list+0xbc>
    800021c0:	03c92783          	lw	a5,60(s2)
    800021c4:	06a78a63          	beq	a5,a0,80002238 <remove_from_list+0x100>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    800021c8:	03450533          	mul	a0,a0,s4
    800021cc:	04050513          	addi	a0,a0,64
    800021d0:	954e                	add	a0,a0,s3
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	a12080e7          	jalr	-1518(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    800021da:	04048513          	addi	a0,s1,64
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    800021e6:	5c84                	lw	s1,56(s1)
    800021e8:	034484b3          	mul	s1,s1,s4
    800021ec:	94ce                	add	s1,s1,s3
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    800021ee:	5c88                	lw	a0,56(s1)
    800021f0:	fd5518e3          	bne	a0,s5,800021c0 <remove_from_list+0x88>
  }
  if(curr_node->next_proc_index == -1){
    release(&proc_to_remove->proc_lock);
    800021f4:	855a                	mv	a0,s6
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	aa2080e7          	jalr	-1374(ra) # 80000c98 <release>
    release(&curr_node->proc_lock);
    800021fe:	04048513          	addi	a0,s1,64
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	a96080e7          	jalr	-1386(ra) # 80000c98 <release>
    return -1;
    8000220a:	5a7d                	li	s4,-1
    8000220c:	a899                	j	80002262 <remove_from_list+0x12a>
      release(lock);
    8000220e:	854e                	mv	a0,s3
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	a88080e7          	jalr	-1400(ra) # 80000c98 <release>
      return -1;
    80002218:	a0a9                	j	80002262 <remove_from_list+0x12a>
      proc_to_remove->next_proc_index = -1;
    8000221a:	57fd                	li	a5,-1
    8000221c:	02f92c23          	sw	a5,56(s2)
      release(&proc_to_remove->proc_lock);
    80002220:	855a                	mv	a0,s6
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>
      release(lock);
    8000222a:	854e                	mv	a0,s3
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>
      return 1;
    80002234:	4a05                	li	s4,1
    80002236:	a035                	j	80002262 <remove_from_list+0x12a>
  if(curr_node->next_proc_index == -1){
    80002238:	57fd                	li	a5,-1
    8000223a:	faf50de3          	beq	a0,a5,800021f4 <remove_from_list+0xbc>
  }

  curr_node->next_proc_index = proc_to_remove->next_proc_index;
    8000223e:	03892783          	lw	a5,56(s2)
    80002242:	dc9c                	sw	a5,56(s1)
  proc_to_remove->next_proc_index = -1;
    80002244:	57fd                	li	a5,-1
    80002246:	02f92c23          	sw	a5,56(s2)
  release(&proc_to_remove->proc_lock);
    8000224a:	855a                	mv	a0,s6
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	a4c080e7          	jalr	-1460(ra) # 80000c98 <release>
  release(&curr_node->proc_lock);
    80002254:	04048513          	addi	a0,s1,64
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	a40080e7          	jalr	-1472(ra) # 80000c98 <release>
  return 1;
    80002260:	4a05                	li	s4,1
}
    80002262:	8552                	mv	a0,s4
    80002264:	70e2                	ld	ra,56(sp)
    80002266:	7442                	ld	s0,48(sp)
    80002268:	74a2                	ld	s1,40(sp)
    8000226a:	7902                	ld	s2,32(sp)
    8000226c:	69e2                	ld	s3,24(sp)
    8000226e:	6a42                	ld	s4,16(sp)
    80002270:	6aa2                	ld	s5,8(sp)
    80002272:	6b02                	ld	s6,0(sp)
    80002274:	6121                	addi	sp,sp,64
    80002276:	8082                	ret

0000000080002278 <freeproc>:
{
    80002278:	1101                	addi	sp,sp,-32
    8000227a:	ec06                	sd	ra,24(sp)
    8000227c:	e822                	sd	s0,16(sp)
    8000227e:	e426                	sd	s1,8(sp)
    80002280:	1000                	addi	s0,sp,32
    80002282:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002284:	7d28                	ld	a0,120(a0)
    80002286:	c509                	beqz	a0,80002290 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002288:	ffffe097          	auipc	ra,0xffffe
    8000228c:	770080e7          	jalr	1904(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002290:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80002294:	78a8                	ld	a0,112(s1)
    80002296:	c511                	beqz	a0,800022a2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002298:	74ac                	ld	a1,104(s1)
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	7c8080e7          	jalr	1992(ra) # 80001a62 <proc_freepagetable>
  p->pagetable = 0;
    800022a2:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    800022a6:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    800022aa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800022ae:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    800022b2:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    800022b6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800022ba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800022be:	0204a623          	sw	zero,44(s1)
  remove_from_list(&zombie_head, p, &lock_zombie_list); //sould we check for return value of -1???/?????????????????????
    800022c2:	0000f617          	auipc	a2,0xf
    800022c6:	53e60613          	addi	a2,a2,1342 # 80011800 <lock_zombie_list>
    800022ca:	85a6                	mv	a1,s1
    800022cc:	00006517          	auipc	a0,0x6
    800022d0:	56850513          	addi	a0,a0,1384 # 80008834 <zombie_head>
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	e64080e7          	jalr	-412(ra) # 80002138 <remove_from_list>
  p->state = UNUSED;
    800022dc:	0004ac23          	sw	zero,24(s1)
  add_to_list(&unused_head, p, &lock_unused_list);
    800022e0:	0000f617          	auipc	a2,0xf
    800022e4:	4f060613          	addi	a2,a2,1264 # 800117d0 <lock_unused_list>
    800022e8:	85a6                	mv	a1,s1
    800022ea:	00006517          	auipc	a0,0x6
    800022ee:	55250513          	addi	a0,a0,1362 # 8000883c <unused_head>
    800022f2:	00000097          	auipc	ra,0x0
    800022f6:	b2a080e7          	jalr	-1238(ra) # 80001e1c <add_to_list>
}
    800022fa:	60e2                	ld	ra,24(sp)
    800022fc:	6442                	ld	s0,16(sp)
    800022fe:	64a2                	ld	s1,8(sp)
    80002300:	6105                	addi	sp,sp,32
    80002302:	8082                	ret

0000000080002304 <wait>:
{
    80002304:	715d                	addi	sp,sp,-80
    80002306:	e486                	sd	ra,72(sp)
    80002308:	e0a2                	sd	s0,64(sp)
    8000230a:	fc26                	sd	s1,56(sp)
    8000230c:	f84a                	sd	s2,48(sp)
    8000230e:	f44e                	sd	s3,40(sp)
    80002310:	f052                	sd	s4,32(sp)
    80002312:	ec56                	sd	s5,24(sp)
    80002314:	e85a                	sd	s6,16(sp)
    80002316:	e45e                	sd	s7,8(sp)
    80002318:	e062                	sd	s8,0(sp)
    8000231a:	0880                	addi	s0,sp,80
    8000231c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	5ea080e7          	jalr	1514(ra) # 80001908 <myproc>
    80002326:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002328:	0000f517          	auipc	a0,0xf
    8000232c:	49050513          	addi	a0,a0,1168 # 800117b8 <wait_lock>
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
    havekids = 0;
    80002338:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000233a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000233c:	00015997          	auipc	s3,0x15
    80002340:	6dc98993          	addi	s3,s3,1756 # 80017a18 <tickslock>
        havekids = 1;
    80002344:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002346:	0000fc17          	auipc	s8,0xf
    8000234a:	472c0c13          	addi	s8,s8,1138 # 800117b8 <wait_lock>
    havekids = 0;
    8000234e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002350:	0000f497          	auipc	s1,0xf
    80002354:	4c848493          	addi	s1,s1,1224 # 80011818 <proc>
    80002358:	a0bd                	j	800023c6 <wait+0xc2>
          pid = np->pid;
    8000235a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000235e:	000b0e63          	beqz	s6,8000237a <wait+0x76>
    80002362:	4691                	li	a3,4
    80002364:	02c48613          	addi	a2,s1,44
    80002368:	85da                	mv	a1,s6
    8000236a:	07093503          	ld	a0,112(s2)
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	304080e7          	jalr	772(ra) # 80001672 <copyout>
    80002376:	02054563          	bltz	a0,800023a0 <wait+0x9c>
          freeproc(np);
    8000237a:	8526                	mv	a0,s1
    8000237c:	00000097          	auipc	ra,0x0
    80002380:	efc080e7          	jalr	-260(ra) # 80002278 <freeproc>
          release(&np->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	912080e7          	jalr	-1774(ra) # 80000c98 <release>
          release(&wait_lock);
    8000238e:	0000f517          	auipc	a0,0xf
    80002392:	42a50513          	addi	a0,a0,1066 # 800117b8 <wait_lock>
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	902080e7          	jalr	-1790(ra) # 80000c98 <release>
          return pid;
    8000239e:	a09d                	j	80002404 <wait+0x100>
            release(&np->lock);
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	8f6080e7          	jalr	-1802(ra) # 80000c98 <release>
            release(&wait_lock);
    800023aa:	0000f517          	auipc	a0,0xf
    800023ae:	40e50513          	addi	a0,a0,1038 # 800117b8 <wait_lock>
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	8e6080e7          	jalr	-1818(ra) # 80000c98 <release>
            return -1;
    800023ba:	59fd                	li	s3,-1
    800023bc:	a0a1                	j	80002404 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800023be:	18848493          	addi	s1,s1,392
    800023c2:	03348463          	beq	s1,s3,800023ea <wait+0xe6>
      if(np->parent == p){
    800023c6:	6cbc                	ld	a5,88(s1)
    800023c8:	ff279be3          	bne	a5,s2,800023be <wait+0xba>
        acquire(&np->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	816080e7          	jalr	-2026(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023d6:	4c9c                	lw	a5,24(s1)
    800023d8:	f94781e3          	beq	a5,s4,8000235a <wait+0x56>
        release(&np->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8ba080e7          	jalr	-1862(ra) # 80000c98 <release>
        havekids = 1;
    800023e6:	8756                	mv	a4,s5
    800023e8:	bfd9                	j	800023be <wait+0xba>
    if(!havekids || p->killed){
    800023ea:	c701                	beqz	a4,800023f2 <wait+0xee>
    800023ec:	02892783          	lw	a5,40(s2)
    800023f0:	c79d                	beqz	a5,8000241e <wait+0x11a>
      release(&wait_lock);
    800023f2:	0000f517          	auipc	a0,0xf
    800023f6:	3c650513          	addi	a0,a0,966 # 800117b8 <wait_lock>
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	89e080e7          	jalr	-1890(ra) # 80000c98 <release>
      return -1;
    80002402:	59fd                	li	s3,-1
}
    80002404:	854e                	mv	a0,s3
    80002406:	60a6                	ld	ra,72(sp)
    80002408:	6406                	ld	s0,64(sp)
    8000240a:	74e2                	ld	s1,56(sp)
    8000240c:	7942                	ld	s2,48(sp)
    8000240e:	79a2                	ld	s3,40(sp)
    80002410:	7a02                	ld	s4,32(sp)
    80002412:	6ae2                	ld	s5,24(sp)
    80002414:	6b42                	ld	s6,16(sp)
    80002416:	6ba2                	ld	s7,8(sp)
    80002418:	6c02                	ld	s8,0(sp)
    8000241a:	6161                	addi	sp,sp,80
    8000241c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000241e:	85e2                	mv	a1,s8
    80002420:	854a                	mv	a0,s2
    80002422:	00000097          	auipc	ra,0x0
    80002426:	c98080e7          	jalr	-872(ra) # 800020ba <sleep>
    havekids = 0;
    8000242a:	b715                	j	8000234e <wait+0x4a>

000000008000242c <wakeup>:
{
    8000242c:	711d                	addi	sp,sp,-96
    8000242e:	ec86                	sd	ra,88(sp)
    80002430:	e8a2                	sd	s0,80(sp)
    80002432:	e4a6                	sd	s1,72(sp)
    80002434:	e0ca                	sd	s2,64(sp)
    80002436:	fc4e                	sd	s3,56(sp)
    80002438:	f852                	sd	s4,48(sp)
    8000243a:	f456                	sd	s5,40(sp)
    8000243c:	f05a                	sd	s6,32(sp)
    8000243e:	ec5e                	sd	s7,24(sp)
    80002440:	e862                	sd	s8,16(sp)
    80002442:	e466                	sd	s9,8(sp)
    80002444:	e06a                	sd	s10,0(sp)
    80002446:	1080                	addi	s0,sp,96
    80002448:	8b2a                	mv	s6,a0
  acquire(&lock_sleeping_list);
    8000244a:	0000f517          	auipc	a0,0xf
    8000244e:	39e50513          	addi	a0,a0,926 # 800117e8 <lock_sleeping_list>
    80002452:	ffffe097          	auipc	ra,0xffffe
    80002456:	792080e7          	jalr	1938(ra) # 80000be4 <acquire>
  if(sleeping_head != -1){
    8000245a:	00006497          	auipc	s1,0x6
    8000245e:	3de4a483          	lw	s1,990(s1) # 80008838 <sleeping_head>
    80002462:	57fd                	li	a5,-1
    80002464:	0af48363          	beq	s1,a5,8000250a <wakeup+0xde>
    p = &proc[sleeping_head];
    80002468:	18800913          	li	s2,392
    8000246c:	03248933          	mul	s2,s1,s2
    80002470:	0000f797          	auipc	a5,0xf
    80002474:	3a878793          	addi	a5,a5,936 # 80011818 <proc>
    80002478:	993e                	add	s2,s2,a5
    release(&lock_sleeping_list);
    8000247a:	0000f517          	auipc	a0,0xf
    8000247e:	36e50513          	addi	a0,a0,878 # 800117e8 <lock_sleeping_list>
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	816080e7          	jalr	-2026(ra) # 80000c98 <release>
      int next_proc = p->next_proc_index;
    8000248a:	84ca                	mv	s1,s2
      if (p->state == SLEEPING && p->chan == chan) {
    8000248c:	4a89                	li	s5,2
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    8000248e:	0000fc17          	auipc	s8,0xf
    80002492:	35ac0c13          	addi	s8,s8,858 # 800117e8 <lock_sleeping_list>
    80002496:	00006b97          	auipc	s7,0x6
    8000249a:	3a2b8b93          	addi	s7,s7,930 # 80008838 <sleeping_head>
              p->state = RUNNABLE;
    8000249e:	4d0d                	li	s10,3
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    800024a0:	0000fc97          	auipc	s9,0xf
    800024a4:	e00c8c93          	addi	s9,s9,-512 # 800112a0 <cpus>
    } while(curr_proc != -1);
    800024a8:	5a7d                	li	s4,-1
    800024aa:	a801                	j	800024ba <wakeup+0x8e>
      release(&p->lock);
    800024ac:	854a                	mv	a0,s2
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	7ea080e7          	jalr	2026(ra) # 80000c98 <release>
    } while(curr_proc != -1);
    800024b6:	07498263          	beq	s3,s4,8000251a <wakeup+0xee>
      acquire(&p->lock);
    800024ba:	854a                	mv	a0,s2
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	728080e7          	jalr	1832(ra) # 80000be4 <acquire>
      int next_proc = p->next_proc_index;
    800024c4:	0384a983          	lw	s3,56(s1)
      if (p->state == SLEEPING && p->chan == chan) {
    800024c8:	4c9c                	lw	a5,24(s1)
    800024ca:	ff5791e3          	bne	a5,s5,800024ac <wakeup+0x80>
    800024ce:	709c                	ld	a5,32(s1)
    800024d0:	fd679ee3          	bne	a5,s6,800024ac <wakeup+0x80>
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    800024d4:	8662                	mv	a2,s8
    800024d6:	85ca                	mv	a1,s2
    800024d8:	855e                	mv	a0,s7
    800024da:	00000097          	auipc	ra,0x0
    800024de:	c5e080e7          	jalr	-930(ra) # 80002138 <remove_from_list>
    800024e2:	d569                	beqz	a0,800024ac <wakeup+0x80>
              p->state = RUNNABLE;
    800024e4:	01a4ac23          	sw	s10,24(s1)
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    800024e8:	58dc                	lw	a5,52(s1)
    800024ea:	00279513          	slli	a0,a5,0x2
    800024ee:	953e                	add	a0,a0,a5
    800024f0:	0516                	slli	a0,a0,0x5
    800024f2:	08850613          	addi	a2,a0,136
    800024f6:	08050513          	addi	a0,a0,128
    800024fa:	9666                	add	a2,a2,s9
    800024fc:	85ca                	mv	a1,s2
    800024fe:	9566                	add	a0,a0,s9
    80002500:	00000097          	auipc	ra,0x0
    80002504:	91c080e7          	jalr	-1764(ra) # 80001e1c <add_to_list>
    80002508:	b755                	j	800024ac <wakeup+0x80>
    release(&lock_sleeping_list);
    8000250a:	0000f517          	auipc	a0,0xf
    8000250e:	2de50513          	addi	a0,a0,734 # 800117e8 <lock_sleeping_list>
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	786080e7          	jalr	1926(ra) # 80000c98 <release>
}
    8000251a:	60e6                	ld	ra,88(sp)
    8000251c:	6446                	ld	s0,80(sp)
    8000251e:	64a6                	ld	s1,72(sp)
    80002520:	6906                	ld	s2,64(sp)
    80002522:	79e2                	ld	s3,56(sp)
    80002524:	7a42                	ld	s4,48(sp)
    80002526:	7aa2                	ld	s5,40(sp)
    80002528:	7b02                	ld	s6,32(sp)
    8000252a:	6be2                	ld	s7,24(sp)
    8000252c:	6c42                	ld	s8,16(sp)
    8000252e:	6ca2                	ld	s9,8(sp)
    80002530:	6d02                	ld	s10,0(sp)
    80002532:	6125                	addi	sp,sp,96
    80002534:	8082                	ret

0000000080002536 <reparent>:
{
    80002536:	7179                	addi	sp,sp,-48
    80002538:	f406                	sd	ra,40(sp)
    8000253a:	f022                	sd	s0,32(sp)
    8000253c:	ec26                	sd	s1,24(sp)
    8000253e:	e84a                	sd	s2,16(sp)
    80002540:	e44e                	sd	s3,8(sp)
    80002542:	e052                	sd	s4,0(sp)
    80002544:	1800                	addi	s0,sp,48
    80002546:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002548:	0000f497          	auipc	s1,0xf
    8000254c:	2d048493          	addi	s1,s1,720 # 80011818 <proc>
      pp->parent = initproc;
    80002550:	00007a17          	auipc	s4,0x7
    80002554:	ad8a0a13          	addi	s4,s4,-1320 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002558:	00015997          	auipc	s3,0x15
    8000255c:	4c098993          	addi	s3,s3,1216 # 80017a18 <tickslock>
    80002560:	a029                	j	8000256a <reparent+0x34>
    80002562:	18848493          	addi	s1,s1,392
    80002566:	01348d63          	beq	s1,s3,80002580 <reparent+0x4a>
    if(pp->parent == p){
    8000256a:	6cbc                	ld	a5,88(s1)
    8000256c:	ff279be3          	bne	a5,s2,80002562 <reparent+0x2c>
      pp->parent = initproc;
    80002570:	000a3503          	ld	a0,0(s4)
    80002574:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002576:	00000097          	auipc	ra,0x0
    8000257a:	eb6080e7          	jalr	-330(ra) # 8000242c <wakeup>
    8000257e:	b7d5                	j	80002562 <reparent+0x2c>
}
    80002580:	70a2                	ld	ra,40(sp)
    80002582:	7402                	ld	s0,32(sp)
    80002584:	64e2                	ld	s1,24(sp)
    80002586:	6942                	ld	s2,16(sp)
    80002588:	69a2                	ld	s3,8(sp)
    8000258a:	6a02                	ld	s4,0(sp)
    8000258c:	6145                	addi	sp,sp,48
    8000258e:	8082                	ret

0000000080002590 <exit>:
{
    80002590:	7179                	addi	sp,sp,-48
    80002592:	f406                	sd	ra,40(sp)
    80002594:	f022                	sd	s0,32(sp)
    80002596:	ec26                	sd	s1,24(sp)
    80002598:	e84a                	sd	s2,16(sp)
    8000259a:	e44e                	sd	s3,8(sp)
    8000259c:	e052                	sd	s4,0(sp)
    8000259e:	1800                	addi	s0,sp,48
    800025a0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025a2:	fffff097          	auipc	ra,0xfffff
    800025a6:	366080e7          	jalr	870(ra) # 80001908 <myproc>
    800025aa:	89aa                	mv	s3,a0
  if(p == initproc)
    800025ac:	00007797          	auipc	a5,0x7
    800025b0:	a7c7b783          	ld	a5,-1412(a5) # 80009028 <initproc>
    800025b4:	0f050493          	addi	s1,a0,240
    800025b8:	17050913          	addi	s2,a0,368
    800025bc:	02a79363          	bne	a5,a0,800025e2 <exit+0x52>
    panic("init exiting");
    800025c0:	00006517          	auipc	a0,0x6
    800025c4:	cb050513          	addi	a0,a0,-848 # 80008270 <digits+0x230>
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	f76080e7          	jalr	-138(ra) # 8000053e <panic>
      fileclose(f);
    800025d0:	00002097          	auipc	ra,0x2
    800025d4:	45a080e7          	jalr	1114(ra) # 80004a2a <fileclose>
      p->ofile[fd] = 0;
    800025d8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025dc:	04a1                	addi	s1,s1,8
    800025de:	01248563          	beq	s1,s2,800025e8 <exit+0x58>
    if(p->ofile[fd]){
    800025e2:	6088                	ld	a0,0(s1)
    800025e4:	f575                	bnez	a0,800025d0 <exit+0x40>
    800025e6:	bfdd                	j	800025dc <exit+0x4c>
  begin_op();
    800025e8:	00002097          	auipc	ra,0x2
    800025ec:	f76080e7          	jalr	-138(ra) # 8000455e <begin_op>
  iput(p->cwd);
    800025f0:	1709b503          	ld	a0,368(s3)
    800025f4:	00001097          	auipc	ra,0x1
    800025f8:	752080e7          	jalr	1874(ra) # 80003d46 <iput>
  end_op();
    800025fc:	00002097          	auipc	ra,0x2
    80002600:	fe2080e7          	jalr	-30(ra) # 800045de <end_op>
  p->cwd = 0;
    80002604:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002608:	0000f497          	auipc	s1,0xf
    8000260c:	1b048493          	addi	s1,s1,432 # 800117b8 <wait_lock>
    80002610:	8526                	mv	a0,s1
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	5d2080e7          	jalr	1490(ra) # 80000be4 <acquire>
  reparent(p);
    8000261a:	854e                	mv	a0,s3
    8000261c:	00000097          	auipc	ra,0x0
    80002620:	f1a080e7          	jalr	-230(ra) # 80002536 <reparent>
  wakeup(p->parent);
    80002624:	0589b503          	ld	a0,88(s3)
    80002628:	00000097          	auipc	ra,0x0
    8000262c:	e04080e7          	jalr	-508(ra) # 8000242c <wakeup>
  acquire(&p->lock);
    80002630:	854e                	mv	a0,s3
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	5b2080e7          	jalr	1458(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000263a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000263e:	4795                	li	a5,5
    80002640:	00f9ac23          	sw	a5,24(s3)
  add_to_list(&zombie_head, p, &lock_zombie_list);
    80002644:	0000f617          	auipc	a2,0xf
    80002648:	1bc60613          	addi	a2,a2,444 # 80011800 <lock_zombie_list>
    8000264c:	85ce                	mv	a1,s3
    8000264e:	00006517          	auipc	a0,0x6
    80002652:	1e650513          	addi	a0,a0,486 # 80008834 <zombie_head>
    80002656:	fffff097          	auipc	ra,0xfffff
    8000265a:	7c6080e7          	jalr	1990(ra) # 80001e1c <add_to_list>
  release(&wait_lock);
    8000265e:	8526                	mv	a0,s1
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	638080e7          	jalr	1592(ra) # 80000c98 <release>
  sched();
    80002668:	fffff097          	auipc	ra,0xfffff
    8000266c:	4c0080e7          	jalr	1216(ra) # 80001b28 <sched>
  panic("zombie exit");
    80002670:	00006517          	auipc	a0,0x6
    80002674:	c1050513          	addi	a0,a0,-1008 # 80008280 <digits+0x240>
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	ec6080e7          	jalr	-314(ra) # 8000053e <panic>

0000000080002680 <remove_first>:

int remove_first(int* curr_proc_index, struct spinlock* lock) {
    80002680:	7139                	addi	sp,sp,-64
    80002682:	fc06                	sd	ra,56(sp)
    80002684:	f822                	sd	s0,48(sp)
    80002686:	f426                	sd	s1,40(sp)
    80002688:	f04a                	sd	s2,32(sp)
    8000268a:	ec4e                	sd	s3,24(sp)
    8000268c:	e852                	sd	s4,16(sp)
    8000268e:	e456                	sd	s5,8(sp)
    80002690:	0080                	addi	s0,sp,64
    80002692:	8aaa                	mv	s5,a0
    80002694:	89ae                	mv	s3,a1
    acquire(lock);
    80002696:	852e                	mv	a0,a1
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	54c080e7          	jalr	1356(ra) # 80000be4 <acquire>
    
    if (*curr_proc_index != -1){
    800026a0:	000aa483          	lw	s1,0(s5)
    800026a4:	57fd                	li	a5,-1
    800026a6:	04f48d63          	beq	s1,a5,80002700 <remove_first+0x80>
      int index = *curr_proc_index;
      struct proc *p = &proc[index];
      acquire(&p->proc_lock);
    800026aa:	18800793          	li	a5,392
    800026ae:	02f484b3          	mul	s1,s1,a5
    800026b2:	04048a13          	addi	s4,s1,64
    800026b6:	0000f917          	auipc	s2,0xf
    800026ba:	16290913          	addi	s2,s2,354 # 80011818 <proc>
    800026be:	9a4a                	add	s4,s4,s2
    800026c0:	8552                	mv	a0,s4
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	522080e7          	jalr	1314(ra) # 80000be4 <acquire>
      
      *curr_proc_index = p->next_proc_index;
    800026ca:	94ca                	add	s1,s1,s2
    800026cc:	5c9c                	lw	a5,56(s1)
    800026ce:	00faa023          	sw	a5,0(s5)
      p->next_proc_index = -1;
    800026d2:	57fd                	li	a5,-1
    800026d4:	dc9c                	sw	a5,56(s1)
      int output_proc = p->proc_index;
    800026d6:	5cc4                	lw	s1,60(s1)

      release(&p->proc_lock);
    800026d8:	8552                	mv	a0,s4
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	5be080e7          	jalr	1470(ra) # 80000c98 <release>
      release(lock);
    800026e2:	854e                	mv	a0,s3
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	5b4080e7          	jalr	1460(ra) # 80000c98 <release>
    else{

      release(lock);
      return -1;
    }
    800026ec:	8526                	mv	a0,s1
    800026ee:	70e2                	ld	ra,56(sp)
    800026f0:	7442                	ld	s0,48(sp)
    800026f2:	74a2                	ld	s1,40(sp)
    800026f4:	7902                	ld	s2,32(sp)
    800026f6:	69e2                	ld	s3,24(sp)
    800026f8:	6a42                	ld	s4,16(sp)
    800026fa:	6aa2                	ld	s5,8(sp)
    800026fc:	6121                	addi	sp,sp,64
    800026fe:	8082                	ret
      release(lock);
    80002700:	854e                	mv	a0,s3
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	596080e7          	jalr	1430(ra) # 80000c98 <release>
      return -1;
    8000270a:	b7cd                	j	800026ec <remove_first+0x6c>

000000008000270c <allocproc>:
{
    8000270c:	7179                	addi	sp,sp,-48
    8000270e:	f406                	sd	ra,40(sp)
    80002710:	f022                	sd	s0,32(sp)
    80002712:	ec26                	sd	s1,24(sp)
    80002714:	e84a                	sd	s2,16(sp)
    80002716:	e44e                	sd	s3,8(sp)
    80002718:	e052                	sd	s4,0(sp)
    8000271a:	1800                	addi	s0,sp,48
    int allocation = remove_first(&unused_head, &lock_unused_list);
    8000271c:	0000f597          	auipc	a1,0xf
    80002720:	0b458593          	addi	a1,a1,180 # 800117d0 <lock_unused_list>
    80002724:	00006517          	auipc	a0,0x6
    80002728:	11850513          	addi	a0,a0,280 # 8000883c <unused_head>
    8000272c:	00000097          	auipc	ra,0x0
    80002730:	f54080e7          	jalr	-172(ra) # 80002680 <remove_first>
    if(allocation == -1){
    80002734:	57fd                	li	a5,-1
    80002736:	0ef50063          	beq	a0,a5,80002816 <allocproc+0x10a>
    8000273a:	892a                	mv	s2,a0
  p=&proc[allocation];
    8000273c:	18800993          	li	s3,392
    80002740:	033509b3          	mul	s3,a0,s3
    80002744:	0000f497          	auipc	s1,0xf
    80002748:	0d448493          	addi	s1,s1,212 # 80011818 <proc>
    8000274c:	94ce                	add	s1,s1,s3
  acquire(&p->lock);
    8000274e:	8526                	mv	a0,s1
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	494080e7          	jalr	1172(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	236080e7          	jalr	566(ra) # 8000198e <allocpid>
    80002760:	d888                	sw	a0,48(s1)
  p->state = USED;
    80002762:	4785                	li	a5,1
    80002764:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	38e080e7          	jalr	910(ra) # 80000af4 <kalloc>
    8000276e:	8a2a                	mv	s4,a0
    80002770:	fca8                	sd	a0,120(s1)
    80002772:	c935                	beqz	a0,800027e6 <allocproc+0xda>
  p->pagetable = proc_pagetable(p);
    80002774:	8526                	mv	a0,s1
    80002776:	fffff097          	auipc	ra,0xfffff
    8000277a:	250080e7          	jalr	592(ra) # 800019c6 <proc_pagetable>
    8000277e:	8a2a                	mv	s4,a0
    80002780:	18800793          	li	a5,392
    80002784:	02f90733          	mul	a4,s2,a5
    80002788:	0000f797          	auipc	a5,0xf
    8000278c:	09078793          	addi	a5,a5,144 # 80011818 <proc>
    80002790:	97ba                	add	a5,a5,a4
    80002792:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    80002794:	c52d                	beqz	a0,800027fe <allocproc+0xf2>
  memset(&p->context, 0, sizeof(p->context));
    80002796:	08098513          	addi	a0,s3,128
    8000279a:	0000fa17          	auipc	s4,0xf
    8000279e:	07ea0a13          	addi	s4,s4,126 # 80011818 <proc>
    800027a2:	07000613          	li	a2,112
    800027a6:	4581                	li	a1,0
    800027a8:	9552                	add	a0,a0,s4
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	536080e7          	jalr	1334(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    800027b2:	18800513          	li	a0,392
    800027b6:	02a90933          	mul	s2,s2,a0
    800027ba:	9952                	add	s2,s2,s4
    800027bc:	fffff797          	auipc	a5,0xfffff
    800027c0:	18c78793          	addi	a5,a5,396 # 80001948 <forkret>
    800027c4:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    800027c8:	06093783          	ld	a5,96(s2)
    800027cc:	6705                	lui	a4,0x1
    800027ce:	97ba                	add	a5,a5,a4
    800027d0:	08f93423          	sd	a5,136(s2)
}
    800027d4:	8526                	mv	a0,s1
    800027d6:	70a2                	ld	ra,40(sp)
    800027d8:	7402                	ld	s0,32(sp)
    800027da:	64e2                	ld	s1,24(sp)
    800027dc:	6942                	ld	s2,16(sp)
    800027de:	69a2                	ld	s3,8(sp)
    800027e0:	6a02                	ld	s4,0(sp)
    800027e2:	6145                	addi	sp,sp,48
    800027e4:	8082                	ret
    freeproc(p);
    800027e6:	8526                	mv	a0,s1
    800027e8:	00000097          	auipc	ra,0x0
    800027ec:	a90080e7          	jalr	-1392(ra) # 80002278 <freeproc>
    release(&p->lock);
    800027f0:	8526                	mv	a0,s1
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	4a6080e7          	jalr	1190(ra) # 80000c98 <release>
    return 0;
    800027fa:	84d2                	mv	s1,s4
    800027fc:	bfe1                	j	800027d4 <allocproc+0xc8>
    freeproc(p);
    800027fe:	8526                	mv	a0,s1
    80002800:	00000097          	auipc	ra,0x0
    80002804:	a78080e7          	jalr	-1416(ra) # 80002278 <freeproc>
    release(&p->lock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	48e080e7          	jalr	1166(ra) # 80000c98 <release>
    return 0;
    80002812:	84d2                	mv	s1,s4
    80002814:	b7c1                	j	800027d4 <allocproc+0xc8>
      return 0;
    80002816:	4481                	li	s1,0
    80002818:	bf75                	j	800027d4 <allocproc+0xc8>

000000008000281a <userinit>:
{
    8000281a:	1101                	addi	sp,sp,-32
    8000281c:	ec06                	sd	ra,24(sp)
    8000281e:	e822                	sd	s0,16(sp)
    80002820:	e426                	sd	s1,8(sp)
    80002822:	1000                	addi	s0,sp,32
  p = allocproc();
    80002824:	00000097          	auipc	ra,0x0
    80002828:	ee8080e7          	jalr	-280(ra) # 8000270c <allocproc>
    8000282c:	84aa                	mv	s1,a0
  initproc = p;
    8000282e:	00006797          	auipc	a5,0x6
    80002832:	7ea7bd23          	sd	a0,2042(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002836:	03400613          	li	a2,52
    8000283a:	00006597          	auipc	a1,0x6
    8000283e:	01658593          	addi	a1,a1,22 # 80008850 <initcode>
    80002842:	7928                	ld	a0,112(a0)
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	b24080e7          	jalr	-1244(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    8000284c:	6785                	lui	a5,0x1
    8000284e:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80002850:	7cb8                	ld	a4,120(s1)
    80002852:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002856:	7cb8                	ld	a4,120(s1)
    80002858:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000285a:	4641                	li	a2,16
    8000285c:	00006597          	auipc	a1,0x6
    80002860:	a3458593          	addi	a1,a1,-1484 # 80008290 <digits+0x250>
    80002864:	17848513          	addi	a0,s1,376
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	5ca080e7          	jalr	1482(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002870:	00006517          	auipc	a0,0x6
    80002874:	a3050513          	addi	a0,a0,-1488 # 800082a0 <digits+0x260>
    80002878:	00002097          	auipc	ra,0x2
    8000287c:	aca080e7          	jalr	-1334(ra) # 80004342 <namei>
    80002880:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80002884:	478d                	li	a5,3
    80002886:	cc9c                	sw	a5,24(s1)
  add_to_list(&cpus[0].runnable_head, p, &cpus[0].lock_runnable_list);
    80002888:	0000f617          	auipc	a2,0xf
    8000288c:	aa060613          	addi	a2,a2,-1376 # 80011328 <cpus+0x88>
    80002890:	85a6                	mv	a1,s1
    80002892:	0000f517          	auipc	a0,0xf
    80002896:	a8e50513          	addi	a0,a0,-1394 # 80011320 <cpus+0x80>
    8000289a:	fffff097          	auipc	ra,0xfffff
    8000289e:	582080e7          	jalr	1410(ra) # 80001e1c <add_to_list>
  release(&p->lock);
    800028a2:	8526                	mv	a0,s1
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	3f4080e7          	jalr	1012(ra) # 80000c98 <release>
}
    800028ac:	60e2                	ld	ra,24(sp)
    800028ae:	6442                	ld	s0,16(sp)
    800028b0:	64a2                	ld	s1,8(sp)
    800028b2:	6105                	addi	sp,sp,32
    800028b4:	8082                	ret

00000000800028b6 <fork>:
{
    800028b6:	7139                	addi	sp,sp,-64
    800028b8:	fc06                	sd	ra,56(sp)
    800028ba:	f822                	sd	s0,48(sp)
    800028bc:	f426                	sd	s1,40(sp)
    800028be:	f04a                	sd	s2,32(sp)
    800028c0:	ec4e                	sd	s3,24(sp)
    800028c2:	e852                	sd	s4,16(sp)
    800028c4:	e456                	sd	s5,8(sp)
    800028c6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	040080e7          	jalr	64(ra) # 80001908 <myproc>
    800028d0:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	e3a080e7          	jalr	-454(ra) # 8000270c <allocproc>
    800028da:	14050563          	beqz	a0,80002a24 <fork+0x16e>
    800028de:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800028e0:	0689b603          	ld	a2,104(s3)
    800028e4:	792c                	ld	a1,112(a0)
    800028e6:	0709b503          	ld	a0,112(s3)
    800028ea:	fffff097          	auipc	ra,0xfffff
    800028ee:	c84080e7          	jalr	-892(ra) # 8000156e <uvmcopy>
    800028f2:	04054663          	bltz	a0,8000293e <fork+0x88>
  np->sz = p->sz;
    800028f6:	0689b783          	ld	a5,104(s3)
    800028fa:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    800028fe:	0789b683          	ld	a3,120(s3)
    80002902:	87b6                	mv	a5,a3
    80002904:	07893703          	ld	a4,120(s2)
    80002908:	12068693          	addi	a3,a3,288
    8000290c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002910:	6788                	ld	a0,8(a5)
    80002912:	6b8c                	ld	a1,16(a5)
    80002914:	6f90                	ld	a2,24(a5)
    80002916:	01073023          	sd	a6,0(a4)
    8000291a:	e708                	sd	a0,8(a4)
    8000291c:	eb0c                	sd	a1,16(a4)
    8000291e:	ef10                	sd	a2,24(a4)
    80002920:	02078793          	addi	a5,a5,32
    80002924:	02070713          	addi	a4,a4,32
    80002928:	fed792e3          	bne	a5,a3,8000290c <fork+0x56>
  np->trapframe->a0 = 0;
    8000292c:	07893783          	ld	a5,120(s2)
    80002930:	0607b823          	sd	zero,112(a5)
    80002934:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80002938:	17000a13          	li	s4,368
    8000293c:	a03d                	j	8000296a <fork+0xb4>
    freeproc(np);
    8000293e:	854a                	mv	a0,s2
    80002940:	00000097          	auipc	ra,0x0
    80002944:	938080e7          	jalr	-1736(ra) # 80002278 <freeproc>
    release(&np->lock);
    80002948:	854a                	mv	a0,s2
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	34e080e7          	jalr	846(ra) # 80000c98 <release>
    return -1;
    80002952:	5afd                	li	s5,-1
    80002954:	a875                	j	80002a10 <fork+0x15a>
      np->ofile[i] = filedup(p->ofile[i]);
    80002956:	00002097          	auipc	ra,0x2
    8000295a:	082080e7          	jalr	130(ra) # 800049d8 <filedup>
    8000295e:	009907b3          	add	a5,s2,s1
    80002962:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002964:	04a1                	addi	s1,s1,8
    80002966:	01448763          	beq	s1,s4,80002974 <fork+0xbe>
    if(p->ofile[i])
    8000296a:	009987b3          	add	a5,s3,s1
    8000296e:	6388                	ld	a0,0(a5)
    80002970:	f17d                	bnez	a0,80002956 <fork+0xa0>
    80002972:	bfcd                	j	80002964 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002974:	1709b503          	ld	a0,368(s3)
    80002978:	00001097          	auipc	ra,0x1
    8000297c:	1d6080e7          	jalr	470(ra) # 80003b4e <idup>
    80002980:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002984:	4641                	li	a2,16
    80002986:	17898593          	addi	a1,s3,376
    8000298a:	17890513          	addi	a0,s2,376
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	4a4080e7          	jalr	1188(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002996:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    8000299a:	854a                	mv	a0,s2
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	2fc080e7          	jalr	764(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800029a4:	0000f497          	auipc	s1,0xf
    800029a8:	8fc48493          	addi	s1,s1,-1796 # 800112a0 <cpus>
    800029ac:	0000fa17          	auipc	s4,0xf
    800029b0:	e0ca0a13          	addi	s4,s4,-500 # 800117b8 <wait_lock>
    800029b4:	8552                	mv	a0,s4
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	22e080e7          	jalr	558(ra) # 80000be4 <acquire>
  np->parent = p;
    800029be:	05393c23          	sd	s3,88(s2)
  np->cpu_num = p->cpu_num;
    800029c2:	0349a783          	lw	a5,52(s3)
    800029c6:	02f92a23          	sw	a5,52(s2)
  release(&wait_lock);
    800029ca:	8552                	mv	a0,s4
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	2cc080e7          	jalr	716(ra) # 80000c98 <release>
  acquire(&np->lock);
    800029d4:	854a                	mv	a0,s2
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	20e080e7          	jalr	526(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800029de:	478d                	li	a5,3
    800029e0:	00f92c23          	sw	a5,24(s2)
  add_to_list(&c->runnable_head, np, &c->lock_runnable_list);
    800029e4:	03492783          	lw	a5,52(s2)
    800029e8:	00279513          	slli	a0,a5,0x2
    800029ec:	953e                	add	a0,a0,a5
    800029ee:	0516                	slli	a0,a0,0x5
    800029f0:	08850613          	addi	a2,a0,136
    800029f4:	08050513          	addi	a0,a0,128
    800029f8:	9626                	add	a2,a2,s1
    800029fa:	85ca                	mv	a1,s2
    800029fc:	9526                	add	a0,a0,s1
    800029fe:	fffff097          	auipc	ra,0xfffff
    80002a02:	41e080e7          	jalr	1054(ra) # 80001e1c <add_to_list>
  release(&np->lock);
    80002a06:	854a                	mv	a0,s2
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	290080e7          	jalr	656(ra) # 80000c98 <release>
}
    80002a10:	8556                	mv	a0,s5
    80002a12:	70e2                	ld	ra,56(sp)
    80002a14:	7442                	ld	s0,48(sp)
    80002a16:	74a2                	ld	s1,40(sp)
    80002a18:	7902                	ld	s2,32(sp)
    80002a1a:	69e2                	ld	s3,24(sp)
    80002a1c:	6a42                	ld	s4,16(sp)
    80002a1e:	6aa2                	ld	s5,8(sp)
    80002a20:	6121                	addi	sp,sp,64
    80002a22:	8082                	ret
    return -1;
    80002a24:	5afd                	li	s5,-1
    80002a26:	b7ed                	j	80002a10 <fork+0x15a>

0000000080002a28 <scheduler>:
{
    80002a28:	711d                	addi	sp,sp,-96
    80002a2a:	ec86                	sd	ra,88(sp)
    80002a2c:	e8a2                	sd	s0,80(sp)
    80002a2e:	e4a6                	sd	s1,72(sp)
    80002a30:	e0ca                	sd	s2,64(sp)
    80002a32:	fc4e                	sd	s3,56(sp)
    80002a34:	f852                	sd	s4,48(sp)
    80002a36:	f456                	sd	s5,40(sp)
    80002a38:	f05a                	sd	s6,32(sp)
    80002a3a:	ec5e                	sd	s7,24(sp)
    80002a3c:	e862                	sd	s8,16(sp)
    80002a3e:	e466                	sd	s9,8(sp)
    80002a40:	e06a                	sd	s10,0(sp)
    80002a42:	1080                	addi	s0,sp,96
    80002a44:	8712                	mv	a4,tp
  int id = r_tp();
    80002a46:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002a48:	0000fb97          	auipc	s7,0xf
    80002a4c:	858b8b93          	addi	s7,s7,-1960 # 800112a0 <cpus>
    80002a50:	00271793          	slli	a5,a4,0x2
    80002a54:	00e786b3          	add	a3,a5,a4
    80002a58:	0696                	slli	a3,a3,0x5
    80002a5a:	96de                	add	a3,a3,s7
    80002a5c:	0006b023          	sd	zero,0(a3)
    80002a60:	97ba                	add	a5,a5,a4
    80002a62:	0796                	slli	a5,a5,0x5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002a64:	08078993          	addi	s3,a5,128
    80002a68:	99de                	add	s3,s3,s7
    80002a6a:	08878913          	addi	s2,a5,136
    80002a6e:	995e                	add	s2,s2,s7
      swtch(&c->context, &p->context);
    80002a70:	07a1                	addi	a5,a5,8
    80002a72:	9bbe                	add	s7,s7,a5
    if(proc_num != -1){
    80002a74:	5a7d                	li	s4,-1
    80002a76:	18800c93          	li	s9,392
      p = &proc[proc_num];
    80002a7a:	0000fb17          	auipc	s6,0xf
    80002a7e:	d9eb0b13          	addi	s6,s6,-610 # 80011818 <proc>
      p->state = RUNNING;
    80002a82:	4c11                	li	s8,4
      c->proc = p;
    80002a84:	8ab6                	mv	s5,a3
    80002a86:	a82d                	j	80002ac0 <scheduler+0x98>
      p = &proc[proc_num];
    80002a88:	039504b3          	mul	s1,a0,s9
    80002a8c:	01648d33          	add	s10,s1,s6
      acquire(&p->lock);
    80002a90:	856a                	mv	a0,s10
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	152080e7          	jalr	338(ra) # 80000be4 <acquire>
      p->state = RUNNING;
    80002a9a:	018d2c23          	sw	s8,24(s10)
      c->proc = p;
    80002a9e:	01aab023          	sd	s10,0(s5)
      swtch(&c->context, &p->context);
    80002aa2:	08048593          	addi	a1,s1,128
    80002aa6:	95da                	add	a1,a1,s6
    80002aa8:	855e                	mv	a0,s7
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	034080e7          	jalr	52(ra) # 80002ade <swtch>
      c->proc = 0;
    80002ab2:	000ab023          	sd	zero,0(s5)
      release(&p->lock);
    80002ab6:	856a                	mv	a0,s10
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	1e0080e7          	jalr	480(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ac4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ac8:	10079073          	csrw	sstatus,a5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002acc:	85ca                	mv	a1,s2
    80002ace:	854e                	mv	a0,s3
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	bb0080e7          	jalr	-1104(ra) # 80002680 <remove_first>
    if(proc_num != -1){
    80002ad8:	ff4504e3          	beq	a0,s4,80002ac0 <scheduler+0x98>
    80002adc:	b775                	j	80002a88 <scheduler+0x60>

0000000080002ade <swtch>:
    80002ade:	00153023          	sd	ra,0(a0)
    80002ae2:	00253423          	sd	sp,8(a0)
    80002ae6:	e900                	sd	s0,16(a0)
    80002ae8:	ed04                	sd	s1,24(a0)
    80002aea:	03253023          	sd	s2,32(a0)
    80002aee:	03353423          	sd	s3,40(a0)
    80002af2:	03453823          	sd	s4,48(a0)
    80002af6:	03553c23          	sd	s5,56(a0)
    80002afa:	05653023          	sd	s6,64(a0)
    80002afe:	05753423          	sd	s7,72(a0)
    80002b02:	05853823          	sd	s8,80(a0)
    80002b06:	05953c23          	sd	s9,88(a0)
    80002b0a:	07a53023          	sd	s10,96(a0)
    80002b0e:	07b53423          	sd	s11,104(a0)
    80002b12:	0005b083          	ld	ra,0(a1)
    80002b16:	0085b103          	ld	sp,8(a1)
    80002b1a:	6980                	ld	s0,16(a1)
    80002b1c:	6d84                	ld	s1,24(a1)
    80002b1e:	0205b903          	ld	s2,32(a1)
    80002b22:	0285b983          	ld	s3,40(a1)
    80002b26:	0305ba03          	ld	s4,48(a1)
    80002b2a:	0385ba83          	ld	s5,56(a1)
    80002b2e:	0405bb03          	ld	s6,64(a1)
    80002b32:	0485bb83          	ld	s7,72(a1)
    80002b36:	0505bc03          	ld	s8,80(a1)
    80002b3a:	0585bc83          	ld	s9,88(a1)
    80002b3e:	0605bd03          	ld	s10,96(a1)
    80002b42:	0685bd83          	ld	s11,104(a1)
    80002b46:	8082                	ret

0000000080002b48 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b48:	1141                	addi	sp,sp,-16
    80002b4a:	e406                	sd	ra,8(sp)
    80002b4c:	e022                	sd	s0,0(sp)
    80002b4e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b50:	00005597          	auipc	a1,0x5
    80002b54:	7b058593          	addi	a1,a1,1968 # 80008300 <states.1745+0x30>
    80002b58:	00015517          	auipc	a0,0x15
    80002b5c:	ec050513          	addi	a0,a0,-320 # 80017a18 <tickslock>
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	ff4080e7          	jalr	-12(ra) # 80000b54 <initlock>
}
    80002b68:	60a2                	ld	ra,8(sp)
    80002b6a:	6402                	ld	s0,0(sp)
    80002b6c:	0141                	addi	sp,sp,16
    80002b6e:	8082                	ret

0000000080002b70 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b70:	1141                	addi	sp,sp,-16
    80002b72:	e422                	sd	s0,8(sp)
    80002b74:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b76:	00003797          	auipc	a5,0x3
    80002b7a:	4ca78793          	addi	a5,a5,1226 # 80006040 <kernelvec>
    80002b7e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b82:	6422                	ld	s0,8(sp)
    80002b84:	0141                	addi	sp,sp,16
    80002b86:	8082                	ret

0000000080002b88 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b88:	1141                	addi	sp,sp,-16
    80002b8a:	e406                	sd	ra,8(sp)
    80002b8c:	e022                	sd	s0,0(sp)
    80002b8e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	d78080e7          	jalr	-648(ra) # 80001908 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b9e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002ba2:	00004617          	auipc	a2,0x4
    80002ba6:	45e60613          	addi	a2,a2,1118 # 80007000 <_trampoline>
    80002baa:	00004697          	auipc	a3,0x4
    80002bae:	45668693          	addi	a3,a3,1110 # 80007000 <_trampoline>
    80002bb2:	8e91                	sub	a3,a3,a2
    80002bb4:	040007b7          	lui	a5,0x4000
    80002bb8:	17fd                	addi	a5,a5,-1
    80002bba:	07b2                	slli	a5,a5,0xc
    80002bbc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bbe:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bc2:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bc4:	180026f3          	csrr	a3,satp
    80002bc8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bca:	7d38                	ld	a4,120(a0)
    80002bcc:	7134                	ld	a3,96(a0)
    80002bce:	6585                	lui	a1,0x1
    80002bd0:	96ae                	add	a3,a3,a1
    80002bd2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bd4:	7d38                	ld	a4,120(a0)
    80002bd6:	00000697          	auipc	a3,0x0
    80002bda:	13868693          	addi	a3,a3,312 # 80002d0e <usertrap>
    80002bde:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002be0:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002be2:	8692                	mv	a3,tp
    80002be4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bea:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bee:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bf2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bf6:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bf8:	6f18                	ld	a4,24(a4)
    80002bfa:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bfe:	792c                	ld	a1,112(a0)
    80002c00:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c02:	00004717          	auipc	a4,0x4
    80002c06:	48e70713          	addi	a4,a4,1166 # 80007090 <userret>
    80002c0a:	8f11                	sub	a4,a4,a2
    80002c0c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c0e:	577d                	li	a4,-1
    80002c10:	177e                	slli	a4,a4,0x3f
    80002c12:	8dd9                	or	a1,a1,a4
    80002c14:	02000537          	lui	a0,0x2000
    80002c18:	157d                	addi	a0,a0,-1
    80002c1a:	0536                	slli	a0,a0,0xd
    80002c1c:	9782                	jalr	a5
}
    80002c1e:	60a2                	ld	ra,8(sp)
    80002c20:	6402                	ld	s0,0(sp)
    80002c22:	0141                	addi	sp,sp,16
    80002c24:	8082                	ret

0000000080002c26 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c26:	1101                	addi	sp,sp,-32
    80002c28:	ec06                	sd	ra,24(sp)
    80002c2a:	e822                	sd	s0,16(sp)
    80002c2c:	e426                	sd	s1,8(sp)
    80002c2e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c30:	00015497          	auipc	s1,0x15
    80002c34:	de848493          	addi	s1,s1,-536 # 80017a18 <tickslock>
    80002c38:	8526                	mv	a0,s1
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	faa080e7          	jalr	-86(ra) # 80000be4 <acquire>
  ticks++;
    80002c42:	00006517          	auipc	a0,0x6
    80002c46:	3ee50513          	addi	a0,a0,1006 # 80009030 <ticks>
    80002c4a:	411c                	lw	a5,0(a0)
    80002c4c:	2785                	addiw	a5,a5,1
    80002c4e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	7dc080e7          	jalr	2012(ra) # 8000242c <wakeup>
  release(&tickslock);
    80002c58:	8526                	mv	a0,s1
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	03e080e7          	jalr	62(ra) # 80000c98 <release>
}
    80002c62:	60e2                	ld	ra,24(sp)
    80002c64:	6442                	ld	s0,16(sp)
    80002c66:	64a2                	ld	s1,8(sp)
    80002c68:	6105                	addi	sp,sp,32
    80002c6a:	8082                	ret

0000000080002c6c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c6c:	1101                	addi	sp,sp,-32
    80002c6e:	ec06                	sd	ra,24(sp)
    80002c70:	e822                	sd	s0,16(sp)
    80002c72:	e426                	sd	s1,8(sp)
    80002c74:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c76:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c7a:	00074d63          	bltz	a4,80002c94 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c7e:	57fd                	li	a5,-1
    80002c80:	17fe                	slli	a5,a5,0x3f
    80002c82:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c84:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c86:	06f70363          	beq	a4,a5,80002cec <devintr+0x80>
  }
}
    80002c8a:	60e2                	ld	ra,24(sp)
    80002c8c:	6442                	ld	s0,16(sp)
    80002c8e:	64a2                	ld	s1,8(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret
     (scause & 0xff) == 9){
    80002c94:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c98:	46a5                	li	a3,9
    80002c9a:	fed792e3          	bne	a5,a3,80002c7e <devintr+0x12>
    int irq = plic_claim();
    80002c9e:	00003097          	auipc	ra,0x3
    80002ca2:	4aa080e7          	jalr	1194(ra) # 80006148 <plic_claim>
    80002ca6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ca8:	47a9                	li	a5,10
    80002caa:	02f50763          	beq	a0,a5,80002cd8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cae:	4785                	li	a5,1
    80002cb0:	02f50963          	beq	a0,a5,80002ce2 <devintr+0x76>
    return 1;
    80002cb4:	4505                	li	a0,1
    } else if(irq){
    80002cb6:	d8f1                	beqz	s1,80002c8a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cb8:	85a6                	mv	a1,s1
    80002cba:	00005517          	auipc	a0,0x5
    80002cbe:	64e50513          	addi	a0,a0,1614 # 80008308 <states.1745+0x38>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8c6080e7          	jalr	-1850(ra) # 80000588 <printf>
      plic_complete(irq);
    80002cca:	8526                	mv	a0,s1
    80002ccc:	00003097          	auipc	ra,0x3
    80002cd0:	4a0080e7          	jalr	1184(ra) # 8000616c <plic_complete>
    return 1;
    80002cd4:	4505                	li	a0,1
    80002cd6:	bf55                	j	80002c8a <devintr+0x1e>
      uartintr();
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	cd0080e7          	jalr	-816(ra) # 800009a8 <uartintr>
    80002ce0:	b7ed                	j	80002cca <devintr+0x5e>
      virtio_disk_intr();
    80002ce2:	00004097          	auipc	ra,0x4
    80002ce6:	96a080e7          	jalr	-1686(ra) # 8000664c <virtio_disk_intr>
    80002cea:	b7c5                	j	80002cca <devintr+0x5e>
    if(cpuid() == 0){
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	be8080e7          	jalr	-1048(ra) # 800018d4 <cpuid>
    80002cf4:	c901                	beqz	a0,80002d04 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002cf6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cfa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cfc:	14479073          	csrw	sip,a5
    return 2;
    80002d00:	4509                	li	a0,2
    80002d02:	b761                	j	80002c8a <devintr+0x1e>
      clockintr();
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	f22080e7          	jalr	-222(ra) # 80002c26 <clockintr>
    80002d0c:	b7ed                	j	80002cf6 <devintr+0x8a>

0000000080002d0e <usertrap>:
{
    80002d0e:	1101                	addi	sp,sp,-32
    80002d10:	ec06                	sd	ra,24(sp)
    80002d12:	e822                	sd	s0,16(sp)
    80002d14:	e426                	sd	s1,8(sp)
    80002d16:	e04a                	sd	s2,0(sp)
    80002d18:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d1a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d1e:	1007f793          	andi	a5,a5,256
    80002d22:	e3ad                	bnez	a5,80002d84 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d24:	00003797          	auipc	a5,0x3
    80002d28:	31c78793          	addi	a5,a5,796 # 80006040 <kernelvec>
    80002d2c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	bd8080e7          	jalr	-1064(ra) # 80001908 <myproc>
    80002d38:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d3a:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d3c:	14102773          	csrr	a4,sepc
    80002d40:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d42:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d46:	47a1                	li	a5,8
    80002d48:	04f71c63          	bne	a4,a5,80002da0 <usertrap+0x92>
    if(p->killed)
    80002d4c:	551c                	lw	a5,40(a0)
    80002d4e:	e3b9                	bnez	a5,80002d94 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d50:	7cb8                	ld	a4,120(s1)
    80002d52:	6f1c                	ld	a5,24(a4)
    80002d54:	0791                	addi	a5,a5,4
    80002d56:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d5c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d60:	10079073          	csrw	sstatus,a5
    syscall();
    80002d64:	00000097          	auipc	ra,0x0
    80002d68:	2e0080e7          	jalr	736(ra) # 80003044 <syscall>
  if(p->killed)
    80002d6c:	549c                	lw	a5,40(s1)
    80002d6e:	ebc1                	bnez	a5,80002dfe <usertrap+0xf0>
  usertrapret();
    80002d70:	00000097          	auipc	ra,0x0
    80002d74:	e18080e7          	jalr	-488(ra) # 80002b88 <usertrapret>
}
    80002d78:	60e2                	ld	ra,24(sp)
    80002d7a:	6442                	ld	s0,16(sp)
    80002d7c:	64a2                	ld	s1,8(sp)
    80002d7e:	6902                	ld	s2,0(sp)
    80002d80:	6105                	addi	sp,sp,32
    80002d82:	8082                	ret
    panic("usertrap: not from user mode");
    80002d84:	00005517          	auipc	a0,0x5
    80002d88:	5a450513          	addi	a0,a0,1444 # 80008328 <states.1745+0x58>
    80002d8c:	ffffd097          	auipc	ra,0xffffd
    80002d90:	7b2080e7          	jalr	1970(ra) # 8000053e <panic>
      exit(-1);
    80002d94:	557d                	li	a0,-1
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	7fa080e7          	jalr	2042(ra) # 80002590 <exit>
    80002d9e:	bf4d                	j	80002d50 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	ecc080e7          	jalr	-308(ra) # 80002c6c <devintr>
    80002da8:	892a                	mv	s2,a0
    80002daa:	c501                	beqz	a0,80002db2 <usertrap+0xa4>
  if(p->killed)
    80002dac:	549c                	lw	a5,40(s1)
    80002dae:	c3a1                	beqz	a5,80002dee <usertrap+0xe0>
    80002db0:	a815                	j	80002de4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002db6:	5890                	lw	a2,48(s1)
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	59050513          	addi	a0,a0,1424 # 80008348 <states.1745+0x78>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	7c8080e7          	jalr	1992(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dc8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dcc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dd0:	00005517          	auipc	a0,0x5
    80002dd4:	5a850513          	addi	a0,a0,1448 # 80008378 <states.1745+0xa8>
    80002dd8:	ffffd097          	auipc	ra,0xffffd
    80002ddc:	7b0080e7          	jalr	1968(ra) # 80000588 <printf>
    p->killed = 1;
    80002de0:	4785                	li	a5,1
    80002de2:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002de4:	557d                	li	a0,-1
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	7aa080e7          	jalr	1962(ra) # 80002590 <exit>
  if(which_dev == 2)
    80002dee:	4789                	li	a5,2
    80002df0:	f8f910e3          	bne	s2,a5,80002d70 <usertrap+0x62>
    yield();
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	224080e7          	jalr	548(ra) # 80002018 <yield>
    80002dfc:	bf95                	j	80002d70 <usertrap+0x62>
  int which_dev = 0;
    80002dfe:	4901                	li	s2,0
    80002e00:	b7d5                	j	80002de4 <usertrap+0xd6>

0000000080002e02 <kerneltrap>:
{
    80002e02:	7179                	addi	sp,sp,-48
    80002e04:	f406                	sd	ra,40(sp)
    80002e06:	f022                	sd	s0,32(sp)
    80002e08:	ec26                	sd	s1,24(sp)
    80002e0a:	e84a                	sd	s2,16(sp)
    80002e0c:	e44e                	sd	s3,8(sp)
    80002e0e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e10:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e14:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e18:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e1c:	1004f793          	andi	a5,s1,256
    80002e20:	cb85                	beqz	a5,80002e50 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e22:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e26:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e28:	ef85                	bnez	a5,80002e60 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	e42080e7          	jalr	-446(ra) # 80002c6c <devintr>
    80002e32:	cd1d                	beqz	a0,80002e70 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e34:	4789                	li	a5,2
    80002e36:	06f50a63          	beq	a0,a5,80002eaa <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e3a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e3e:	10049073          	csrw	sstatus,s1
}
    80002e42:	70a2                	ld	ra,40(sp)
    80002e44:	7402                	ld	s0,32(sp)
    80002e46:	64e2                	ld	s1,24(sp)
    80002e48:	6942                	ld	s2,16(sp)
    80002e4a:	69a2                	ld	s3,8(sp)
    80002e4c:	6145                	addi	sp,sp,48
    80002e4e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	54850513          	addi	a0,a0,1352 # 80008398 <states.1745+0xc8>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	6e6080e7          	jalr	1766(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002e60:	00005517          	auipc	a0,0x5
    80002e64:	56050513          	addi	a0,a0,1376 # 800083c0 <states.1745+0xf0>
    80002e68:	ffffd097          	auipc	ra,0xffffd
    80002e6c:	6d6080e7          	jalr	1750(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002e70:	85ce                	mv	a1,s3
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	56e50513          	addi	a0,a0,1390 # 800083e0 <states.1745+0x110>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	70e080e7          	jalr	1806(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e82:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e86:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e8a:	00005517          	auipc	a0,0x5
    80002e8e:	56650513          	addi	a0,a0,1382 # 800083f0 <states.1745+0x120>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6f6080e7          	jalr	1782(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002e9a:	00005517          	auipc	a0,0x5
    80002e9e:	56e50513          	addi	a0,a0,1390 # 80008408 <states.1745+0x138>
    80002ea2:	ffffd097          	auipc	ra,0xffffd
    80002ea6:	69c080e7          	jalr	1692(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	a5e080e7          	jalr	-1442(ra) # 80001908 <myproc>
    80002eb2:	d541                	beqz	a0,80002e3a <kerneltrap+0x38>
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	a54080e7          	jalr	-1452(ra) # 80001908 <myproc>
    80002ebc:	4d18                	lw	a4,24(a0)
    80002ebe:	4791                	li	a5,4
    80002ec0:	f6f71de3          	bne	a4,a5,80002e3a <kerneltrap+0x38>
    yield();
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	154080e7          	jalr	340(ra) # 80002018 <yield>
    80002ecc:	b7bd                	j	80002e3a <kerneltrap+0x38>

0000000080002ece <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ece:	1101                	addi	sp,sp,-32
    80002ed0:	ec06                	sd	ra,24(sp)
    80002ed2:	e822                	sd	s0,16(sp)
    80002ed4:	e426                	sd	s1,8(sp)
    80002ed6:	1000                	addi	s0,sp,32
    80002ed8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	a2e080e7          	jalr	-1490(ra) # 80001908 <myproc>
  switch (n) {
    80002ee2:	4795                	li	a5,5
    80002ee4:	0497e163          	bltu	a5,s1,80002f26 <argraw+0x58>
    80002ee8:	048a                	slli	s1,s1,0x2
    80002eea:	00005717          	auipc	a4,0x5
    80002eee:	55670713          	addi	a4,a4,1366 # 80008440 <states.1745+0x170>
    80002ef2:	94ba                	add	s1,s1,a4
    80002ef4:	409c                	lw	a5,0(s1)
    80002ef6:	97ba                	add	a5,a5,a4
    80002ef8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002efa:	7d3c                	ld	a5,120(a0)
    80002efc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	64a2                	ld	s1,8(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret
    return p->trapframe->a1;
    80002f08:	7d3c                	ld	a5,120(a0)
    80002f0a:	7fa8                	ld	a0,120(a5)
    80002f0c:	bfcd                	j	80002efe <argraw+0x30>
    return p->trapframe->a2;
    80002f0e:	7d3c                	ld	a5,120(a0)
    80002f10:	63c8                	ld	a0,128(a5)
    80002f12:	b7f5                	j	80002efe <argraw+0x30>
    return p->trapframe->a3;
    80002f14:	7d3c                	ld	a5,120(a0)
    80002f16:	67c8                	ld	a0,136(a5)
    80002f18:	b7dd                	j	80002efe <argraw+0x30>
    return p->trapframe->a4;
    80002f1a:	7d3c                	ld	a5,120(a0)
    80002f1c:	6bc8                	ld	a0,144(a5)
    80002f1e:	b7c5                	j	80002efe <argraw+0x30>
    return p->trapframe->a5;
    80002f20:	7d3c                	ld	a5,120(a0)
    80002f22:	6fc8                	ld	a0,152(a5)
    80002f24:	bfe9                	j	80002efe <argraw+0x30>
  panic("argraw");
    80002f26:	00005517          	auipc	a0,0x5
    80002f2a:	4f250513          	addi	a0,a0,1266 # 80008418 <states.1745+0x148>
    80002f2e:	ffffd097          	auipc	ra,0xffffd
    80002f32:	610080e7          	jalr	1552(ra) # 8000053e <panic>

0000000080002f36 <fetchaddr>:
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	e426                	sd	s1,8(sp)
    80002f3e:	e04a                	sd	s2,0(sp)
    80002f40:	1000                	addi	s0,sp,32
    80002f42:	84aa                	mv	s1,a0
    80002f44:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	9c2080e7          	jalr	-1598(ra) # 80001908 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f4e:	753c                	ld	a5,104(a0)
    80002f50:	02f4f863          	bgeu	s1,a5,80002f80 <fetchaddr+0x4a>
    80002f54:	00848713          	addi	a4,s1,8
    80002f58:	02e7e663          	bltu	a5,a4,80002f84 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f5c:	46a1                	li	a3,8
    80002f5e:	8626                	mv	a2,s1
    80002f60:	85ca                	mv	a1,s2
    80002f62:	7928                	ld	a0,112(a0)
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	79a080e7          	jalr	1946(ra) # 800016fe <copyin>
    80002f6c:	00a03533          	snez	a0,a0
    80002f70:	40a00533          	neg	a0,a0
}
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	64a2                	ld	s1,8(sp)
    80002f7a:	6902                	ld	s2,0(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret
    return -1;
    80002f80:	557d                	li	a0,-1
    80002f82:	bfcd                	j	80002f74 <fetchaddr+0x3e>
    80002f84:	557d                	li	a0,-1
    80002f86:	b7fd                	j	80002f74 <fetchaddr+0x3e>

0000000080002f88 <fetchstr>:
{
    80002f88:	7179                	addi	sp,sp,-48
    80002f8a:	f406                	sd	ra,40(sp)
    80002f8c:	f022                	sd	s0,32(sp)
    80002f8e:	ec26                	sd	s1,24(sp)
    80002f90:	e84a                	sd	s2,16(sp)
    80002f92:	e44e                	sd	s3,8(sp)
    80002f94:	1800                	addi	s0,sp,48
    80002f96:	892a                	mv	s2,a0
    80002f98:	84ae                	mv	s1,a1
    80002f9a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	96c080e7          	jalr	-1684(ra) # 80001908 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002fa4:	86ce                	mv	a3,s3
    80002fa6:	864a                	mv	a2,s2
    80002fa8:	85a6                	mv	a1,s1
    80002faa:	7928                	ld	a0,112(a0)
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	7de080e7          	jalr	2014(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002fb4:	00054763          	bltz	a0,80002fc2 <fetchstr+0x3a>
  return strlen(buf);
    80002fb8:	8526                	mv	a0,s1
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	eaa080e7          	jalr	-342(ra) # 80000e64 <strlen>
}
    80002fc2:	70a2                	ld	ra,40(sp)
    80002fc4:	7402                	ld	s0,32(sp)
    80002fc6:	64e2                	ld	s1,24(sp)
    80002fc8:	6942                	ld	s2,16(sp)
    80002fca:	69a2                	ld	s3,8(sp)
    80002fcc:	6145                	addi	sp,sp,48
    80002fce:	8082                	ret

0000000080002fd0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002fd0:	1101                	addi	sp,sp,-32
    80002fd2:	ec06                	sd	ra,24(sp)
    80002fd4:	e822                	sd	s0,16(sp)
    80002fd6:	e426                	sd	s1,8(sp)
    80002fd8:	1000                	addi	s0,sp,32
    80002fda:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	ef2080e7          	jalr	-270(ra) # 80002ece <argraw>
    80002fe4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002fe6:	4501                	li	a0,0
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	64a2                	ld	s1,8(sp)
    80002fee:	6105                	addi	sp,sp,32
    80002ff0:	8082                	ret

0000000080002ff2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ff2:	1101                	addi	sp,sp,-32
    80002ff4:	ec06                	sd	ra,24(sp)
    80002ff6:	e822                	sd	s0,16(sp)
    80002ff8:	e426                	sd	s1,8(sp)
    80002ffa:	1000                	addi	s0,sp,32
    80002ffc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ffe:	00000097          	auipc	ra,0x0
    80003002:	ed0080e7          	jalr	-304(ra) # 80002ece <argraw>
    80003006:	e088                	sd	a0,0(s1)
  return 0;
}
    80003008:	4501                	li	a0,0
    8000300a:	60e2                	ld	ra,24(sp)
    8000300c:	6442                	ld	s0,16(sp)
    8000300e:	64a2                	ld	s1,8(sp)
    80003010:	6105                	addi	sp,sp,32
    80003012:	8082                	ret

0000000080003014 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003014:	1101                	addi	sp,sp,-32
    80003016:	ec06                	sd	ra,24(sp)
    80003018:	e822                	sd	s0,16(sp)
    8000301a:	e426                	sd	s1,8(sp)
    8000301c:	e04a                	sd	s2,0(sp)
    8000301e:	1000                	addi	s0,sp,32
    80003020:	84ae                	mv	s1,a1
    80003022:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003024:	00000097          	auipc	ra,0x0
    80003028:	eaa080e7          	jalr	-342(ra) # 80002ece <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000302c:	864a                	mv	a2,s2
    8000302e:	85a6                	mv	a1,s1
    80003030:	00000097          	auipc	ra,0x0
    80003034:	f58080e7          	jalr	-168(ra) # 80002f88 <fetchstr>
}
    80003038:	60e2                	ld	ra,24(sp)
    8000303a:	6442                	ld	s0,16(sp)
    8000303c:	64a2                	ld	s1,8(sp)
    8000303e:	6902                	ld	s2,0(sp)
    80003040:	6105                	addi	sp,sp,32
    80003042:	8082                	ret

0000000080003044 <syscall>:
[SYS_get_cpu] sys_get_cpu,
};

void
syscall(void)
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	e426                	sd	s1,8(sp)
    8000304c:	e04a                	sd	s2,0(sp)
    8000304e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003050:	fffff097          	auipc	ra,0xfffff
    80003054:	8b8080e7          	jalr	-1864(ra) # 80001908 <myproc>
    80003058:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000305a:	07853903          	ld	s2,120(a0)
    8000305e:	0a893783          	ld	a5,168(s2)
    80003062:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003066:	37fd                	addiw	a5,a5,-1
    80003068:	4759                	li	a4,22
    8000306a:	00f76f63          	bltu	a4,a5,80003088 <syscall+0x44>
    8000306e:	00369713          	slli	a4,a3,0x3
    80003072:	00005797          	auipc	a5,0x5
    80003076:	3e678793          	addi	a5,a5,998 # 80008458 <syscalls>
    8000307a:	97ba                	add	a5,a5,a4
    8000307c:	639c                	ld	a5,0(a5)
    8000307e:	c789                	beqz	a5,80003088 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003080:	9782                	jalr	a5
    80003082:	06a93823          	sd	a0,112(s2)
    80003086:	a839                	j	800030a4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003088:	17848613          	addi	a2,s1,376
    8000308c:	588c                	lw	a1,48(s1)
    8000308e:	00005517          	auipc	a0,0x5
    80003092:	39250513          	addi	a0,a0,914 # 80008420 <states.1745+0x150>
    80003096:	ffffd097          	auipc	ra,0xffffd
    8000309a:	4f2080e7          	jalr	1266(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000309e:	7cbc                	ld	a5,120(s1)
    800030a0:	577d                	li	a4,-1
    800030a2:	fbb8                	sd	a4,112(a5)
  }
}
    800030a4:	60e2                	ld	ra,24(sp)
    800030a6:	6442                	ld	s0,16(sp)
    800030a8:	64a2                	ld	s1,8(sp)
    800030aa:	6902                	ld	s2,0(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret

00000000800030b0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030b0:	1101                	addi	sp,sp,-32
    800030b2:	ec06                	sd	ra,24(sp)
    800030b4:	e822                	sd	s0,16(sp)
    800030b6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800030b8:	fec40593          	addi	a1,s0,-20
    800030bc:	4501                	li	a0,0
    800030be:	00000097          	auipc	ra,0x0
    800030c2:	f12080e7          	jalr	-238(ra) # 80002fd0 <argint>
    return -1;
    800030c6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030c8:	00054963          	bltz	a0,800030da <sys_exit+0x2a>
  exit(n);
    800030cc:	fec42503          	lw	a0,-20(s0)
    800030d0:	fffff097          	auipc	ra,0xfffff
    800030d4:	4c0080e7          	jalr	1216(ra) # 80002590 <exit>
  return 0;  // not reached
    800030d8:	4781                	li	a5,0
}
    800030da:	853e                	mv	a0,a5
    800030dc:	60e2                	ld	ra,24(sp)
    800030de:	6442                	ld	s0,16(sp)
    800030e0:	6105                	addi	sp,sp,32
    800030e2:	8082                	ret

00000000800030e4 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030e4:	1141                	addi	sp,sp,-16
    800030e6:	e406                	sd	ra,8(sp)
    800030e8:	e022                	sd	s0,0(sp)
    800030ea:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	81c080e7          	jalr	-2020(ra) # 80001908 <myproc>
}
    800030f4:	5908                	lw	a0,48(a0)
    800030f6:	60a2                	ld	ra,8(sp)
    800030f8:	6402                	ld	s0,0(sp)
    800030fa:	0141                	addi	sp,sp,16
    800030fc:	8082                	ret

00000000800030fe <sys_fork>:

uint64
sys_fork(void)
{
    800030fe:	1141                	addi	sp,sp,-16
    80003100:	e406                	sd	ra,8(sp)
    80003102:	e022                	sd	s0,0(sp)
    80003104:	0800                	addi	s0,sp,16
  return fork();
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	7b0080e7          	jalr	1968(ra) # 800028b6 <fork>
}
    8000310e:	60a2                	ld	ra,8(sp)
    80003110:	6402                	ld	s0,0(sp)
    80003112:	0141                	addi	sp,sp,16
    80003114:	8082                	ret

0000000080003116 <sys_wait>:

uint64
sys_wait(void)
{
    80003116:	1101                	addi	sp,sp,-32
    80003118:	ec06                	sd	ra,24(sp)
    8000311a:	e822                	sd	s0,16(sp)
    8000311c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000311e:	fe840593          	addi	a1,s0,-24
    80003122:	4501                	li	a0,0
    80003124:	00000097          	auipc	ra,0x0
    80003128:	ece080e7          	jalr	-306(ra) # 80002ff2 <argaddr>
    8000312c:	87aa                	mv	a5,a0
    return -1;
    8000312e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003130:	0007c863          	bltz	a5,80003140 <sys_wait+0x2a>
  return wait(p);
    80003134:	fe843503          	ld	a0,-24(s0)
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	1cc080e7          	jalr	460(ra) # 80002304 <wait>
}
    80003140:	60e2                	ld	ra,24(sp)
    80003142:	6442                	ld	s0,16(sp)
    80003144:	6105                	addi	sp,sp,32
    80003146:	8082                	ret

0000000080003148 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003148:	7179                	addi	sp,sp,-48
    8000314a:	f406                	sd	ra,40(sp)
    8000314c:	f022                	sd	s0,32(sp)
    8000314e:	ec26                	sd	s1,24(sp)
    80003150:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003152:	fdc40593          	addi	a1,s0,-36
    80003156:	4501                	li	a0,0
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	e78080e7          	jalr	-392(ra) # 80002fd0 <argint>
    80003160:	87aa                	mv	a5,a0
    return -1;
    80003162:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003164:	0207c063          	bltz	a5,80003184 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	7a0080e7          	jalr	1952(ra) # 80001908 <myproc>
    80003170:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003172:	fdc42503          	lw	a0,-36(s0)
    80003176:	fffff097          	auipc	ra,0xfffff
    8000317a:	93e080e7          	jalr	-1730(ra) # 80001ab4 <growproc>
    8000317e:	00054863          	bltz	a0,8000318e <sys_sbrk+0x46>
    return -1;
  return addr;
    80003182:	8526                	mv	a0,s1
}
    80003184:	70a2                	ld	ra,40(sp)
    80003186:	7402                	ld	s0,32(sp)
    80003188:	64e2                	ld	s1,24(sp)
    8000318a:	6145                	addi	sp,sp,48
    8000318c:	8082                	ret
    return -1;
    8000318e:	557d                	li	a0,-1
    80003190:	bfd5                	j	80003184 <sys_sbrk+0x3c>

0000000080003192 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003192:	7139                	addi	sp,sp,-64
    80003194:	fc06                	sd	ra,56(sp)
    80003196:	f822                	sd	s0,48(sp)
    80003198:	f426                	sd	s1,40(sp)
    8000319a:	f04a                	sd	s2,32(sp)
    8000319c:	ec4e                	sd	s3,24(sp)
    8000319e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031a0:	fcc40593          	addi	a1,s0,-52
    800031a4:	4501                	li	a0,0
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	e2a080e7          	jalr	-470(ra) # 80002fd0 <argint>
    return -1;
    800031ae:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031b0:	06054563          	bltz	a0,8000321a <sys_sleep+0x88>
  acquire(&tickslock);
    800031b4:	00015517          	auipc	a0,0x15
    800031b8:	86450513          	addi	a0,a0,-1948 # 80017a18 <tickslock>
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	a28080e7          	jalr	-1496(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800031c4:	00006917          	auipc	s2,0x6
    800031c8:	e6c92903          	lw	s2,-404(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800031cc:	fcc42783          	lw	a5,-52(s0)
    800031d0:	cf85                	beqz	a5,80003208 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031d2:	00015997          	auipc	s3,0x15
    800031d6:	84698993          	addi	s3,s3,-1978 # 80017a18 <tickslock>
    800031da:	00006497          	auipc	s1,0x6
    800031de:	e5648493          	addi	s1,s1,-426 # 80009030 <ticks>
    if(myproc()->killed){
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	726080e7          	jalr	1830(ra) # 80001908 <myproc>
    800031ea:	551c                	lw	a5,40(a0)
    800031ec:	ef9d                	bnez	a5,8000322a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800031ee:	85ce                	mv	a1,s3
    800031f0:	8526                	mv	a0,s1
    800031f2:	fffff097          	auipc	ra,0xfffff
    800031f6:	ec8080e7          	jalr	-312(ra) # 800020ba <sleep>
  while(ticks - ticks0 < n){
    800031fa:	409c                	lw	a5,0(s1)
    800031fc:	412787bb          	subw	a5,a5,s2
    80003200:	fcc42703          	lw	a4,-52(s0)
    80003204:	fce7efe3          	bltu	a5,a4,800031e2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003208:	00015517          	auipc	a0,0x15
    8000320c:	81050513          	addi	a0,a0,-2032 # 80017a18 <tickslock>
    80003210:	ffffe097          	auipc	ra,0xffffe
    80003214:	a88080e7          	jalr	-1400(ra) # 80000c98 <release>
  return 0;
    80003218:	4781                	li	a5,0
}
    8000321a:	853e                	mv	a0,a5
    8000321c:	70e2                	ld	ra,56(sp)
    8000321e:	7442                	ld	s0,48(sp)
    80003220:	74a2                	ld	s1,40(sp)
    80003222:	7902                	ld	s2,32(sp)
    80003224:	69e2                	ld	s3,24(sp)
    80003226:	6121                	addi	sp,sp,64
    80003228:	8082                	ret
      release(&tickslock);
    8000322a:	00014517          	auipc	a0,0x14
    8000322e:	7ee50513          	addi	a0,a0,2030 # 80017a18 <tickslock>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	a66080e7          	jalr	-1434(ra) # 80000c98 <release>
      return -1;
    8000323a:	57fd                	li	a5,-1
    8000323c:	bff9                	j	8000321a <sys_sleep+0x88>

000000008000323e <sys_kill>:

uint64
sys_kill(void)
{
    8000323e:	1101                	addi	sp,sp,-32
    80003240:	ec06                	sd	ra,24(sp)
    80003242:	e822                	sd	s0,16(sp)
    80003244:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003246:	fec40593          	addi	a1,s0,-20
    8000324a:	4501                	li	a0,0
    8000324c:	00000097          	auipc	ra,0x0
    80003250:	d84080e7          	jalr	-636(ra) # 80002fd0 <argint>
    80003254:	87aa                	mv	a5,a0
    return -1;
    80003256:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003258:	0007c863          	bltz	a5,80003268 <sys_kill+0x2a>
  return kill(pid);
    8000325c:	fec42503          	lw	a0,-20(s0)
    80003260:	fffff097          	auipc	ra,0xfffff
    80003264:	9b6080e7          	jalr	-1610(ra) # 80001c16 <kill>
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	6105                	addi	sp,sp,32
    8000326e:	8082                	ret

0000000080003270 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003270:	1101                	addi	sp,sp,-32
    80003272:	ec06                	sd	ra,24(sp)
    80003274:	e822                	sd	s0,16(sp)
    80003276:	e426                	sd	s1,8(sp)
    80003278:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000327a:	00014517          	auipc	a0,0x14
    8000327e:	79e50513          	addi	a0,a0,1950 # 80017a18 <tickslock>
    80003282:	ffffe097          	auipc	ra,0xffffe
    80003286:	962080e7          	jalr	-1694(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000328a:	00006497          	auipc	s1,0x6
    8000328e:	da64a483          	lw	s1,-602(s1) # 80009030 <ticks>
  release(&tickslock);
    80003292:	00014517          	auipc	a0,0x14
    80003296:	78650513          	addi	a0,a0,1926 # 80017a18 <tickslock>
    8000329a:	ffffe097          	auipc	ra,0xffffe
    8000329e:	9fe080e7          	jalr	-1538(ra) # 80000c98 <release>
  return xticks;
}
    800032a2:	02049513          	slli	a0,s1,0x20
    800032a6:	9101                	srli	a0,a0,0x20
    800032a8:	60e2                	ld	ra,24(sp)
    800032aa:	6442                	ld	s0,16(sp)
    800032ac:	64a2                	ld	s1,8(sp)
    800032ae:	6105                	addi	sp,sp,32
    800032b0:	8082                	ret

00000000800032b2 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    800032b2:	1101                	addi	sp,sp,-32
    800032b4:	ec06                	sd	ra,24(sp)
    800032b6:	e822                	sd	s0,16(sp)
    800032b8:	1000                	addi	s0,sp,32
    int cpu_num;
    if(argint(0, &cpu_num) <= -1){
    800032ba:	fec40593          	addi	a1,s0,-20
    800032be:	4501                	li	a0,0
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	d10080e7          	jalr	-752(ra) # 80002fd0 <argint>
    800032c8:	87aa                	mv	a5,a0
      return -1;
    800032ca:	557d                	li	a0,-1
    if(argint(0, &cpu_num) <= -1){
    800032cc:	0007c863          	bltz	a5,800032dc <sys_set_cpu+0x2a>
    }
    
    return set_cpu(cpu_num);
    800032d0:	fec42503          	lw	a0,-20(s0)
    800032d4:	fffff097          	auipc	ra,0xfffff
    800032d8:	da8080e7          	jalr	-600(ra) # 8000207c <set_cpu>
}
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	6105                	addi	sp,sp,32
    800032e2:	8082                	ret

00000000800032e4 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800032e4:	1141                	addi	sp,sp,-16
    800032e6:	e406                	sd	ra,8(sp)
    800032e8:	e022                	sd	s0,0(sp)
    800032ea:	0800                	addi	s0,sp,16
    return get_cpu();
    800032ec:	fffff097          	auipc	ra,0xfffff
    800032f0:	af6080e7          	jalr	-1290(ra) # 80001de2 <get_cpu>
    800032f4:	60a2                	ld	ra,8(sp)
    800032f6:	6402                	ld	s0,0(sp)
    800032f8:	0141                	addi	sp,sp,16
    800032fa:	8082                	ret

00000000800032fc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032fc:	7179                	addi	sp,sp,-48
    800032fe:	f406                	sd	ra,40(sp)
    80003300:	f022                	sd	s0,32(sp)
    80003302:	ec26                	sd	s1,24(sp)
    80003304:	e84a                	sd	s2,16(sp)
    80003306:	e44e                	sd	s3,8(sp)
    80003308:	e052                	sd	s4,0(sp)
    8000330a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000330c:	00005597          	auipc	a1,0x5
    80003310:	20c58593          	addi	a1,a1,524 # 80008518 <syscalls+0xc0>
    80003314:	00014517          	auipc	a0,0x14
    80003318:	71c50513          	addi	a0,a0,1820 # 80017a30 <bcache>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	838080e7          	jalr	-1992(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003324:	0001c797          	auipc	a5,0x1c
    80003328:	70c78793          	addi	a5,a5,1804 # 8001fa30 <bcache+0x8000>
    8000332c:	0001d717          	auipc	a4,0x1d
    80003330:	96c70713          	addi	a4,a4,-1684 # 8001fc98 <bcache+0x8268>
    80003334:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003338:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000333c:	00014497          	auipc	s1,0x14
    80003340:	70c48493          	addi	s1,s1,1804 # 80017a48 <bcache+0x18>
    b->next = bcache.head.next;
    80003344:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003346:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003348:	00005a17          	auipc	s4,0x5
    8000334c:	1d8a0a13          	addi	s4,s4,472 # 80008520 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003350:	2b893783          	ld	a5,696(s2)
    80003354:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003356:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000335a:	85d2                	mv	a1,s4
    8000335c:	01048513          	addi	a0,s1,16
    80003360:	00001097          	auipc	ra,0x1
    80003364:	4bc080e7          	jalr	1212(ra) # 8000481c <initsleeplock>
    bcache.head.next->prev = b;
    80003368:	2b893783          	ld	a5,696(s2)
    8000336c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000336e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003372:	45848493          	addi	s1,s1,1112
    80003376:	fd349de3          	bne	s1,s3,80003350 <binit+0x54>
  }
}
    8000337a:	70a2                	ld	ra,40(sp)
    8000337c:	7402                	ld	s0,32(sp)
    8000337e:	64e2                	ld	s1,24(sp)
    80003380:	6942                	ld	s2,16(sp)
    80003382:	69a2                	ld	s3,8(sp)
    80003384:	6a02                	ld	s4,0(sp)
    80003386:	6145                	addi	sp,sp,48
    80003388:	8082                	ret

000000008000338a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000338a:	7179                	addi	sp,sp,-48
    8000338c:	f406                	sd	ra,40(sp)
    8000338e:	f022                	sd	s0,32(sp)
    80003390:	ec26                	sd	s1,24(sp)
    80003392:	e84a                	sd	s2,16(sp)
    80003394:	e44e                	sd	s3,8(sp)
    80003396:	1800                	addi	s0,sp,48
    80003398:	89aa                	mv	s3,a0
    8000339a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	69450513          	addi	a0,a0,1684 # 80017a30 <bcache>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	840080e7          	jalr	-1984(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033ac:	0001d497          	auipc	s1,0x1d
    800033b0:	93c4b483          	ld	s1,-1732(s1) # 8001fce8 <bcache+0x82b8>
    800033b4:	0001d797          	auipc	a5,0x1d
    800033b8:	8e478793          	addi	a5,a5,-1820 # 8001fc98 <bcache+0x8268>
    800033bc:	02f48f63          	beq	s1,a5,800033fa <bread+0x70>
    800033c0:	873e                	mv	a4,a5
    800033c2:	a021                	j	800033ca <bread+0x40>
    800033c4:	68a4                	ld	s1,80(s1)
    800033c6:	02e48a63          	beq	s1,a4,800033fa <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033ca:	449c                	lw	a5,8(s1)
    800033cc:	ff379ce3          	bne	a5,s3,800033c4 <bread+0x3a>
    800033d0:	44dc                	lw	a5,12(s1)
    800033d2:	ff2799e3          	bne	a5,s2,800033c4 <bread+0x3a>
      b->refcnt++;
    800033d6:	40bc                	lw	a5,64(s1)
    800033d8:	2785                	addiw	a5,a5,1
    800033da:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033dc:	00014517          	auipc	a0,0x14
    800033e0:	65450513          	addi	a0,a0,1620 # 80017a30 <bcache>
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	8b4080e7          	jalr	-1868(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033ec:	01048513          	addi	a0,s1,16
    800033f0:	00001097          	auipc	ra,0x1
    800033f4:	466080e7          	jalr	1126(ra) # 80004856 <acquiresleep>
      return b;
    800033f8:	a8b9                	j	80003456 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033fa:	0001d497          	auipc	s1,0x1d
    800033fe:	8e64b483          	ld	s1,-1818(s1) # 8001fce0 <bcache+0x82b0>
    80003402:	0001d797          	auipc	a5,0x1d
    80003406:	89678793          	addi	a5,a5,-1898 # 8001fc98 <bcache+0x8268>
    8000340a:	00f48863          	beq	s1,a5,8000341a <bread+0x90>
    8000340e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003410:	40bc                	lw	a5,64(s1)
    80003412:	cf81                	beqz	a5,8000342a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003414:	64a4                	ld	s1,72(s1)
    80003416:	fee49de3          	bne	s1,a4,80003410 <bread+0x86>
  panic("bget: no buffers");
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	10e50513          	addi	a0,a0,270 # 80008528 <syscalls+0xd0>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	11c080e7          	jalr	284(ra) # 8000053e <panic>
      b->dev = dev;
    8000342a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000342e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003432:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003436:	4785                	li	a5,1
    80003438:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000343a:	00014517          	auipc	a0,0x14
    8000343e:	5f650513          	addi	a0,a0,1526 # 80017a30 <bcache>
    80003442:	ffffe097          	auipc	ra,0xffffe
    80003446:	856080e7          	jalr	-1962(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000344a:	01048513          	addi	a0,s1,16
    8000344e:	00001097          	auipc	ra,0x1
    80003452:	408080e7          	jalr	1032(ra) # 80004856 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003456:	409c                	lw	a5,0(s1)
    80003458:	cb89                	beqz	a5,8000346a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000345a:	8526                	mv	a0,s1
    8000345c:	70a2                	ld	ra,40(sp)
    8000345e:	7402                	ld	s0,32(sp)
    80003460:	64e2                	ld	s1,24(sp)
    80003462:	6942                	ld	s2,16(sp)
    80003464:	69a2                	ld	s3,8(sp)
    80003466:	6145                	addi	sp,sp,48
    80003468:	8082                	ret
    virtio_disk_rw(b, 0);
    8000346a:	4581                	li	a1,0
    8000346c:	8526                	mv	a0,s1
    8000346e:	00003097          	auipc	ra,0x3
    80003472:	f08080e7          	jalr	-248(ra) # 80006376 <virtio_disk_rw>
    b->valid = 1;
    80003476:	4785                	li	a5,1
    80003478:	c09c                	sw	a5,0(s1)
  return b;
    8000347a:	b7c5                	j	8000345a <bread+0xd0>

000000008000347c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000347c:	1101                	addi	sp,sp,-32
    8000347e:	ec06                	sd	ra,24(sp)
    80003480:	e822                	sd	s0,16(sp)
    80003482:	e426                	sd	s1,8(sp)
    80003484:	1000                	addi	s0,sp,32
    80003486:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003488:	0541                	addi	a0,a0,16
    8000348a:	00001097          	auipc	ra,0x1
    8000348e:	466080e7          	jalr	1126(ra) # 800048f0 <holdingsleep>
    80003492:	cd01                	beqz	a0,800034aa <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003494:	4585                	li	a1,1
    80003496:	8526                	mv	a0,s1
    80003498:	00003097          	auipc	ra,0x3
    8000349c:	ede080e7          	jalr	-290(ra) # 80006376 <virtio_disk_rw>
}
    800034a0:	60e2                	ld	ra,24(sp)
    800034a2:	6442                	ld	s0,16(sp)
    800034a4:	64a2                	ld	s1,8(sp)
    800034a6:	6105                	addi	sp,sp,32
    800034a8:	8082                	ret
    panic("bwrite");
    800034aa:	00005517          	auipc	a0,0x5
    800034ae:	09650513          	addi	a0,a0,150 # 80008540 <syscalls+0xe8>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	08c080e7          	jalr	140(ra) # 8000053e <panic>

00000000800034ba <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034ba:	1101                	addi	sp,sp,-32
    800034bc:	ec06                	sd	ra,24(sp)
    800034be:	e822                	sd	s0,16(sp)
    800034c0:	e426                	sd	s1,8(sp)
    800034c2:	e04a                	sd	s2,0(sp)
    800034c4:	1000                	addi	s0,sp,32
    800034c6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034c8:	01050913          	addi	s2,a0,16
    800034cc:	854a                	mv	a0,s2
    800034ce:	00001097          	auipc	ra,0x1
    800034d2:	422080e7          	jalr	1058(ra) # 800048f0 <holdingsleep>
    800034d6:	c92d                	beqz	a0,80003548 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034d8:	854a                	mv	a0,s2
    800034da:	00001097          	auipc	ra,0x1
    800034de:	3d2080e7          	jalr	978(ra) # 800048ac <releasesleep>

  acquire(&bcache.lock);
    800034e2:	00014517          	auipc	a0,0x14
    800034e6:	54e50513          	addi	a0,a0,1358 # 80017a30 <bcache>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	6fa080e7          	jalr	1786(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034f2:	40bc                	lw	a5,64(s1)
    800034f4:	37fd                	addiw	a5,a5,-1
    800034f6:	0007871b          	sext.w	a4,a5
    800034fa:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034fc:	eb05                	bnez	a4,8000352c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034fe:	68bc                	ld	a5,80(s1)
    80003500:	64b8                	ld	a4,72(s1)
    80003502:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003504:	64bc                	ld	a5,72(s1)
    80003506:	68b8                	ld	a4,80(s1)
    80003508:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000350a:	0001c797          	auipc	a5,0x1c
    8000350e:	52678793          	addi	a5,a5,1318 # 8001fa30 <bcache+0x8000>
    80003512:	2b87b703          	ld	a4,696(a5)
    80003516:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003518:	0001c717          	auipc	a4,0x1c
    8000351c:	78070713          	addi	a4,a4,1920 # 8001fc98 <bcache+0x8268>
    80003520:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003522:	2b87b703          	ld	a4,696(a5)
    80003526:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003528:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000352c:	00014517          	auipc	a0,0x14
    80003530:	50450513          	addi	a0,a0,1284 # 80017a30 <bcache>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	764080e7          	jalr	1892(ra) # 80000c98 <release>
}
    8000353c:	60e2                	ld	ra,24(sp)
    8000353e:	6442                	ld	s0,16(sp)
    80003540:	64a2                	ld	s1,8(sp)
    80003542:	6902                	ld	s2,0(sp)
    80003544:	6105                	addi	sp,sp,32
    80003546:	8082                	ret
    panic("brelse");
    80003548:	00005517          	auipc	a0,0x5
    8000354c:	00050513          	mv	a0,a0
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	fee080e7          	jalr	-18(ra) # 8000053e <panic>

0000000080003558 <bpin>:

void
bpin(struct buf *b) {
    80003558:	1101                	addi	sp,sp,-32
    8000355a:	ec06                	sd	ra,24(sp)
    8000355c:	e822                	sd	s0,16(sp)
    8000355e:	e426                	sd	s1,8(sp)
    80003560:	1000                	addi	s0,sp,32
    80003562:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003564:	00014517          	auipc	a0,0x14
    80003568:	4cc50513          	addi	a0,a0,1228 # 80017a30 <bcache>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	678080e7          	jalr	1656(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003574:	40bc                	lw	a5,64(s1)
    80003576:	2785                	addiw	a5,a5,1
    80003578:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000357a:	00014517          	auipc	a0,0x14
    8000357e:	4b650513          	addi	a0,a0,1206 # 80017a30 <bcache>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	716080e7          	jalr	1814(ra) # 80000c98 <release>
}
    8000358a:	60e2                	ld	ra,24(sp)
    8000358c:	6442                	ld	s0,16(sp)
    8000358e:	64a2                	ld	s1,8(sp)
    80003590:	6105                	addi	sp,sp,32
    80003592:	8082                	ret

0000000080003594 <bunpin>:

void
bunpin(struct buf *b) {
    80003594:	1101                	addi	sp,sp,-32
    80003596:	ec06                	sd	ra,24(sp)
    80003598:	e822                	sd	s0,16(sp)
    8000359a:	e426                	sd	s1,8(sp)
    8000359c:	1000                	addi	s0,sp,32
    8000359e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035a0:	00014517          	auipc	a0,0x14
    800035a4:	49050513          	addi	a0,a0,1168 # 80017a30 <bcache>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	63c080e7          	jalr	1596(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035b0:	40bc                	lw	a5,64(s1)
    800035b2:	37fd                	addiw	a5,a5,-1
    800035b4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035b6:	00014517          	auipc	a0,0x14
    800035ba:	47a50513          	addi	a0,a0,1146 # 80017a30 <bcache>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	6da080e7          	jalr	1754(ra) # 80000c98 <release>
}
    800035c6:	60e2                	ld	ra,24(sp)
    800035c8:	6442                	ld	s0,16(sp)
    800035ca:	64a2                	ld	s1,8(sp)
    800035cc:	6105                	addi	sp,sp,32
    800035ce:	8082                	ret

00000000800035d0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035d0:	1101                	addi	sp,sp,-32
    800035d2:	ec06                	sd	ra,24(sp)
    800035d4:	e822                	sd	s0,16(sp)
    800035d6:	e426                	sd	s1,8(sp)
    800035d8:	e04a                	sd	s2,0(sp)
    800035da:	1000                	addi	s0,sp,32
    800035dc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035de:	00d5d59b          	srliw	a1,a1,0xd
    800035e2:	0001d797          	auipc	a5,0x1d
    800035e6:	b2a7a783          	lw	a5,-1238(a5) # 8002010c <sb+0x1c>
    800035ea:	9dbd                	addw	a1,a1,a5
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	d9e080e7          	jalr	-610(ra) # 8000338a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035f4:	0074f713          	andi	a4,s1,7
    800035f8:	4785                	li	a5,1
    800035fa:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035fe:	14ce                	slli	s1,s1,0x33
    80003600:	90d9                	srli	s1,s1,0x36
    80003602:	00950733          	add	a4,a0,s1
    80003606:	05874703          	lbu	a4,88(a4)
    8000360a:	00e7f6b3          	and	a3,a5,a4
    8000360e:	c69d                	beqz	a3,8000363c <bfree+0x6c>
    80003610:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003612:	94aa                	add	s1,s1,a0
    80003614:	fff7c793          	not	a5,a5
    80003618:	8ff9                	and	a5,a5,a4
    8000361a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000361e:	00001097          	auipc	ra,0x1
    80003622:	118080e7          	jalr	280(ra) # 80004736 <log_write>
  brelse(bp);
    80003626:	854a                	mv	a0,s2
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	e92080e7          	jalr	-366(ra) # 800034ba <brelse>
}
    80003630:	60e2                	ld	ra,24(sp)
    80003632:	6442                	ld	s0,16(sp)
    80003634:	64a2                	ld	s1,8(sp)
    80003636:	6902                	ld	s2,0(sp)
    80003638:	6105                	addi	sp,sp,32
    8000363a:	8082                	ret
    panic("freeing free block");
    8000363c:	00005517          	auipc	a0,0x5
    80003640:	f1450513          	addi	a0,a0,-236 # 80008550 <syscalls+0xf8>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	efa080e7          	jalr	-262(ra) # 8000053e <panic>

000000008000364c <balloc>:
{
    8000364c:	711d                	addi	sp,sp,-96
    8000364e:	ec86                	sd	ra,88(sp)
    80003650:	e8a2                	sd	s0,80(sp)
    80003652:	e4a6                	sd	s1,72(sp)
    80003654:	e0ca                	sd	s2,64(sp)
    80003656:	fc4e                	sd	s3,56(sp)
    80003658:	f852                	sd	s4,48(sp)
    8000365a:	f456                	sd	s5,40(sp)
    8000365c:	f05a                	sd	s6,32(sp)
    8000365e:	ec5e                	sd	s7,24(sp)
    80003660:	e862                	sd	s8,16(sp)
    80003662:	e466                	sd	s9,8(sp)
    80003664:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003666:	0001d797          	auipc	a5,0x1d
    8000366a:	a8e7a783          	lw	a5,-1394(a5) # 800200f4 <sb+0x4>
    8000366e:	cbd1                	beqz	a5,80003702 <balloc+0xb6>
    80003670:	8baa                	mv	s7,a0
    80003672:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003674:	0001db17          	auipc	s6,0x1d
    80003678:	a7cb0b13          	addi	s6,s6,-1412 # 800200f0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000367c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000367e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003680:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003682:	6c89                	lui	s9,0x2
    80003684:	a831                	j	800036a0 <balloc+0x54>
    brelse(bp);
    80003686:	854a                	mv	a0,s2
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	e32080e7          	jalr	-462(ra) # 800034ba <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003690:	015c87bb          	addw	a5,s9,s5
    80003694:	00078a9b          	sext.w	s5,a5
    80003698:	004b2703          	lw	a4,4(s6)
    8000369c:	06eaf363          	bgeu	s5,a4,80003702 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036a0:	41fad79b          	sraiw	a5,s5,0x1f
    800036a4:	0137d79b          	srliw	a5,a5,0x13
    800036a8:	015787bb          	addw	a5,a5,s5
    800036ac:	40d7d79b          	sraiw	a5,a5,0xd
    800036b0:	01cb2583          	lw	a1,28(s6)
    800036b4:	9dbd                	addw	a1,a1,a5
    800036b6:	855e                	mv	a0,s7
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	cd2080e7          	jalr	-814(ra) # 8000338a <bread>
    800036c0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036c2:	004b2503          	lw	a0,4(s6)
    800036c6:	000a849b          	sext.w	s1,s5
    800036ca:	8662                	mv	a2,s8
    800036cc:	faa4fde3          	bgeu	s1,a0,80003686 <balloc+0x3a>
      m = 1 << (bi % 8);
    800036d0:	41f6579b          	sraiw	a5,a2,0x1f
    800036d4:	01d7d69b          	srliw	a3,a5,0x1d
    800036d8:	00c6873b          	addw	a4,a3,a2
    800036dc:	00777793          	andi	a5,a4,7
    800036e0:	9f95                	subw	a5,a5,a3
    800036e2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036e6:	4037571b          	sraiw	a4,a4,0x3
    800036ea:	00e906b3          	add	a3,s2,a4
    800036ee:	0586c683          	lbu	a3,88(a3)
    800036f2:	00d7f5b3          	and	a1,a5,a3
    800036f6:	cd91                	beqz	a1,80003712 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036f8:	2605                	addiw	a2,a2,1
    800036fa:	2485                	addiw	s1,s1,1
    800036fc:	fd4618e3          	bne	a2,s4,800036cc <balloc+0x80>
    80003700:	b759                	j	80003686 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003702:	00005517          	auipc	a0,0x5
    80003706:	e6650513          	addi	a0,a0,-410 # 80008568 <syscalls+0x110>
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	e34080e7          	jalr	-460(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003712:	974a                	add	a4,a4,s2
    80003714:	8fd5                	or	a5,a5,a3
    80003716:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000371a:	854a                	mv	a0,s2
    8000371c:	00001097          	auipc	ra,0x1
    80003720:	01a080e7          	jalr	26(ra) # 80004736 <log_write>
        brelse(bp);
    80003724:	854a                	mv	a0,s2
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	d94080e7          	jalr	-620(ra) # 800034ba <brelse>
  bp = bread(dev, bno);
    8000372e:	85a6                	mv	a1,s1
    80003730:	855e                	mv	a0,s7
    80003732:	00000097          	auipc	ra,0x0
    80003736:	c58080e7          	jalr	-936(ra) # 8000338a <bread>
    8000373a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000373c:	40000613          	li	a2,1024
    80003740:	4581                	li	a1,0
    80003742:	05850513          	addi	a0,a0,88
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	59a080e7          	jalr	1434(ra) # 80000ce0 <memset>
  log_write(bp);
    8000374e:	854a                	mv	a0,s2
    80003750:	00001097          	auipc	ra,0x1
    80003754:	fe6080e7          	jalr	-26(ra) # 80004736 <log_write>
  brelse(bp);
    80003758:	854a                	mv	a0,s2
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	d60080e7          	jalr	-672(ra) # 800034ba <brelse>
}
    80003762:	8526                	mv	a0,s1
    80003764:	60e6                	ld	ra,88(sp)
    80003766:	6446                	ld	s0,80(sp)
    80003768:	64a6                	ld	s1,72(sp)
    8000376a:	6906                	ld	s2,64(sp)
    8000376c:	79e2                	ld	s3,56(sp)
    8000376e:	7a42                	ld	s4,48(sp)
    80003770:	7aa2                	ld	s5,40(sp)
    80003772:	7b02                	ld	s6,32(sp)
    80003774:	6be2                	ld	s7,24(sp)
    80003776:	6c42                	ld	s8,16(sp)
    80003778:	6ca2                	ld	s9,8(sp)
    8000377a:	6125                	addi	sp,sp,96
    8000377c:	8082                	ret

000000008000377e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000377e:	7179                	addi	sp,sp,-48
    80003780:	f406                	sd	ra,40(sp)
    80003782:	f022                	sd	s0,32(sp)
    80003784:	ec26                	sd	s1,24(sp)
    80003786:	e84a                	sd	s2,16(sp)
    80003788:	e44e                	sd	s3,8(sp)
    8000378a:	e052                	sd	s4,0(sp)
    8000378c:	1800                	addi	s0,sp,48
    8000378e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003790:	47ad                	li	a5,11
    80003792:	04b7fe63          	bgeu	a5,a1,800037ee <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003796:	ff45849b          	addiw	s1,a1,-12
    8000379a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000379e:	0ff00793          	li	a5,255
    800037a2:	0ae7e363          	bltu	a5,a4,80003848 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037a6:	08052583          	lw	a1,128(a0)
    800037aa:	c5ad                	beqz	a1,80003814 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037ac:	00092503          	lw	a0,0(s2)
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	bda080e7          	jalr	-1062(ra) # 8000338a <bread>
    800037b8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037ba:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037be:	02049593          	slli	a1,s1,0x20
    800037c2:	9181                	srli	a1,a1,0x20
    800037c4:	058a                	slli	a1,a1,0x2
    800037c6:	00b784b3          	add	s1,a5,a1
    800037ca:	0004a983          	lw	s3,0(s1)
    800037ce:	04098d63          	beqz	s3,80003828 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037d2:	8552                	mv	a0,s4
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	ce6080e7          	jalr	-794(ra) # 800034ba <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037dc:	854e                	mv	a0,s3
    800037de:	70a2                	ld	ra,40(sp)
    800037e0:	7402                	ld	s0,32(sp)
    800037e2:	64e2                	ld	s1,24(sp)
    800037e4:	6942                	ld	s2,16(sp)
    800037e6:	69a2                	ld	s3,8(sp)
    800037e8:	6a02                	ld	s4,0(sp)
    800037ea:	6145                	addi	sp,sp,48
    800037ec:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037ee:	02059493          	slli	s1,a1,0x20
    800037f2:	9081                	srli	s1,s1,0x20
    800037f4:	048a                	slli	s1,s1,0x2
    800037f6:	94aa                	add	s1,s1,a0
    800037f8:	0504a983          	lw	s3,80(s1)
    800037fc:	fe0990e3          	bnez	s3,800037dc <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003800:	4108                	lw	a0,0(a0)
    80003802:	00000097          	auipc	ra,0x0
    80003806:	e4a080e7          	jalr	-438(ra) # 8000364c <balloc>
    8000380a:	0005099b          	sext.w	s3,a0
    8000380e:	0534a823          	sw	s3,80(s1)
    80003812:	b7e9                	j	800037dc <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003814:	4108                	lw	a0,0(a0)
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	e36080e7          	jalr	-458(ra) # 8000364c <balloc>
    8000381e:	0005059b          	sext.w	a1,a0
    80003822:	08b92023          	sw	a1,128(s2)
    80003826:	b759                	j	800037ac <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003828:	00092503          	lw	a0,0(s2)
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	e20080e7          	jalr	-480(ra) # 8000364c <balloc>
    80003834:	0005099b          	sext.w	s3,a0
    80003838:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000383c:	8552                	mv	a0,s4
    8000383e:	00001097          	auipc	ra,0x1
    80003842:	ef8080e7          	jalr	-264(ra) # 80004736 <log_write>
    80003846:	b771                	j	800037d2 <bmap+0x54>
  panic("bmap: out of range");
    80003848:	00005517          	auipc	a0,0x5
    8000384c:	d3850513          	addi	a0,a0,-712 # 80008580 <syscalls+0x128>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	cee080e7          	jalr	-786(ra) # 8000053e <panic>

0000000080003858 <iget>:
{
    80003858:	7179                	addi	sp,sp,-48
    8000385a:	f406                	sd	ra,40(sp)
    8000385c:	f022                	sd	s0,32(sp)
    8000385e:	ec26                	sd	s1,24(sp)
    80003860:	e84a                	sd	s2,16(sp)
    80003862:	e44e                	sd	s3,8(sp)
    80003864:	e052                	sd	s4,0(sp)
    80003866:	1800                	addi	s0,sp,48
    80003868:	89aa                	mv	s3,a0
    8000386a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000386c:	0001d517          	auipc	a0,0x1d
    80003870:	8a450513          	addi	a0,a0,-1884 # 80020110 <itable>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	370080e7          	jalr	880(ra) # 80000be4 <acquire>
  empty = 0;
    8000387c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000387e:	0001d497          	auipc	s1,0x1d
    80003882:	8aa48493          	addi	s1,s1,-1878 # 80020128 <itable+0x18>
    80003886:	0001e697          	auipc	a3,0x1e
    8000388a:	33268693          	addi	a3,a3,818 # 80021bb8 <log>
    8000388e:	a039                	j	8000389c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003890:	02090b63          	beqz	s2,800038c6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003894:	08848493          	addi	s1,s1,136
    80003898:	02d48a63          	beq	s1,a3,800038cc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000389c:	449c                	lw	a5,8(s1)
    8000389e:	fef059e3          	blez	a5,80003890 <iget+0x38>
    800038a2:	4098                	lw	a4,0(s1)
    800038a4:	ff3716e3          	bne	a4,s3,80003890 <iget+0x38>
    800038a8:	40d8                	lw	a4,4(s1)
    800038aa:	ff4713e3          	bne	a4,s4,80003890 <iget+0x38>
      ip->ref++;
    800038ae:	2785                	addiw	a5,a5,1
    800038b0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038b2:	0001d517          	auipc	a0,0x1d
    800038b6:	85e50513          	addi	a0,a0,-1954 # 80020110 <itable>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	3de080e7          	jalr	990(ra) # 80000c98 <release>
      return ip;
    800038c2:	8926                	mv	s2,s1
    800038c4:	a03d                	j	800038f2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038c6:	f7f9                	bnez	a5,80003894 <iget+0x3c>
    800038c8:	8926                	mv	s2,s1
    800038ca:	b7e9                	j	80003894 <iget+0x3c>
  if(empty == 0)
    800038cc:	02090c63          	beqz	s2,80003904 <iget+0xac>
  ip->dev = dev;
    800038d0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038d4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038d8:	4785                	li	a5,1
    800038da:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038de:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038e2:	0001d517          	auipc	a0,0x1d
    800038e6:	82e50513          	addi	a0,a0,-2002 # 80020110 <itable>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
}
    800038f2:	854a                	mv	a0,s2
    800038f4:	70a2                	ld	ra,40(sp)
    800038f6:	7402                	ld	s0,32(sp)
    800038f8:	64e2                	ld	s1,24(sp)
    800038fa:	6942                	ld	s2,16(sp)
    800038fc:	69a2                	ld	s3,8(sp)
    800038fe:	6a02                	ld	s4,0(sp)
    80003900:	6145                	addi	sp,sp,48
    80003902:	8082                	ret
    panic("iget: no inodes");
    80003904:	00005517          	auipc	a0,0x5
    80003908:	c9450513          	addi	a0,a0,-876 # 80008598 <syscalls+0x140>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	c32080e7          	jalr	-974(ra) # 8000053e <panic>

0000000080003914 <fsinit>:
fsinit(int dev) {
    80003914:	7179                	addi	sp,sp,-48
    80003916:	f406                	sd	ra,40(sp)
    80003918:	f022                	sd	s0,32(sp)
    8000391a:	ec26                	sd	s1,24(sp)
    8000391c:	e84a                	sd	s2,16(sp)
    8000391e:	e44e                	sd	s3,8(sp)
    80003920:	1800                	addi	s0,sp,48
    80003922:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003924:	4585                	li	a1,1
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	a64080e7          	jalr	-1436(ra) # 8000338a <bread>
    8000392e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003930:	0001c997          	auipc	s3,0x1c
    80003934:	7c098993          	addi	s3,s3,1984 # 800200f0 <sb>
    80003938:	02000613          	li	a2,32
    8000393c:	05850593          	addi	a1,a0,88
    80003940:	854e                	mv	a0,s3
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	3fe080e7          	jalr	1022(ra) # 80000d40 <memmove>
  brelse(bp);
    8000394a:	8526                	mv	a0,s1
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	b6e080e7          	jalr	-1170(ra) # 800034ba <brelse>
  if(sb.magic != FSMAGIC)
    80003954:	0009a703          	lw	a4,0(s3)
    80003958:	102037b7          	lui	a5,0x10203
    8000395c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003960:	02f71263          	bne	a4,a5,80003984 <fsinit+0x70>
  initlog(dev, &sb);
    80003964:	0001c597          	auipc	a1,0x1c
    80003968:	78c58593          	addi	a1,a1,1932 # 800200f0 <sb>
    8000396c:	854a                	mv	a0,s2
    8000396e:	00001097          	auipc	ra,0x1
    80003972:	b4c080e7          	jalr	-1204(ra) # 800044ba <initlog>
}
    80003976:	70a2                	ld	ra,40(sp)
    80003978:	7402                	ld	s0,32(sp)
    8000397a:	64e2                	ld	s1,24(sp)
    8000397c:	6942                	ld	s2,16(sp)
    8000397e:	69a2                	ld	s3,8(sp)
    80003980:	6145                	addi	sp,sp,48
    80003982:	8082                	ret
    panic("invalid file system");
    80003984:	00005517          	auipc	a0,0x5
    80003988:	c2450513          	addi	a0,a0,-988 # 800085a8 <syscalls+0x150>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	bb2080e7          	jalr	-1102(ra) # 8000053e <panic>

0000000080003994 <iinit>:
{
    80003994:	7179                	addi	sp,sp,-48
    80003996:	f406                	sd	ra,40(sp)
    80003998:	f022                	sd	s0,32(sp)
    8000399a:	ec26                	sd	s1,24(sp)
    8000399c:	e84a                	sd	s2,16(sp)
    8000399e:	e44e                	sd	s3,8(sp)
    800039a0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039a2:	00005597          	auipc	a1,0x5
    800039a6:	c1e58593          	addi	a1,a1,-994 # 800085c0 <syscalls+0x168>
    800039aa:	0001c517          	auipc	a0,0x1c
    800039ae:	76650513          	addi	a0,a0,1894 # 80020110 <itable>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	1a2080e7          	jalr	418(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039ba:	0001c497          	auipc	s1,0x1c
    800039be:	77e48493          	addi	s1,s1,1918 # 80020138 <itable+0x28>
    800039c2:	0001e997          	auipc	s3,0x1e
    800039c6:	20698993          	addi	s3,s3,518 # 80021bc8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039ca:	00005917          	auipc	s2,0x5
    800039ce:	bfe90913          	addi	s2,s2,-1026 # 800085c8 <syscalls+0x170>
    800039d2:	85ca                	mv	a1,s2
    800039d4:	8526                	mv	a0,s1
    800039d6:	00001097          	auipc	ra,0x1
    800039da:	e46080e7          	jalr	-442(ra) # 8000481c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039de:	08848493          	addi	s1,s1,136
    800039e2:	ff3498e3          	bne	s1,s3,800039d2 <iinit+0x3e>
}
    800039e6:	70a2                	ld	ra,40(sp)
    800039e8:	7402                	ld	s0,32(sp)
    800039ea:	64e2                	ld	s1,24(sp)
    800039ec:	6942                	ld	s2,16(sp)
    800039ee:	69a2                	ld	s3,8(sp)
    800039f0:	6145                	addi	sp,sp,48
    800039f2:	8082                	ret

00000000800039f4 <ialloc>:
{
    800039f4:	715d                	addi	sp,sp,-80
    800039f6:	e486                	sd	ra,72(sp)
    800039f8:	e0a2                	sd	s0,64(sp)
    800039fa:	fc26                	sd	s1,56(sp)
    800039fc:	f84a                	sd	s2,48(sp)
    800039fe:	f44e                	sd	s3,40(sp)
    80003a00:	f052                	sd	s4,32(sp)
    80003a02:	ec56                	sd	s5,24(sp)
    80003a04:	e85a                	sd	s6,16(sp)
    80003a06:	e45e                	sd	s7,8(sp)
    80003a08:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a0a:	0001c717          	auipc	a4,0x1c
    80003a0e:	6f272703          	lw	a4,1778(a4) # 800200fc <sb+0xc>
    80003a12:	4785                	li	a5,1
    80003a14:	04e7fa63          	bgeu	a5,a4,80003a68 <ialloc+0x74>
    80003a18:	8aaa                	mv	s5,a0
    80003a1a:	8bae                	mv	s7,a1
    80003a1c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a1e:	0001ca17          	auipc	s4,0x1c
    80003a22:	6d2a0a13          	addi	s4,s4,1746 # 800200f0 <sb>
    80003a26:	00048b1b          	sext.w	s6,s1
    80003a2a:	0044d593          	srli	a1,s1,0x4
    80003a2e:	018a2783          	lw	a5,24(s4)
    80003a32:	9dbd                	addw	a1,a1,a5
    80003a34:	8556                	mv	a0,s5
    80003a36:	00000097          	auipc	ra,0x0
    80003a3a:	954080e7          	jalr	-1708(ra) # 8000338a <bread>
    80003a3e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a40:	05850993          	addi	s3,a0,88
    80003a44:	00f4f793          	andi	a5,s1,15
    80003a48:	079a                	slli	a5,a5,0x6
    80003a4a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a4c:	00099783          	lh	a5,0(s3)
    80003a50:	c785                	beqz	a5,80003a78 <ialloc+0x84>
    brelse(bp);
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	a68080e7          	jalr	-1432(ra) # 800034ba <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a5a:	0485                	addi	s1,s1,1
    80003a5c:	00ca2703          	lw	a4,12(s4)
    80003a60:	0004879b          	sext.w	a5,s1
    80003a64:	fce7e1e3          	bltu	a5,a4,80003a26 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a68:	00005517          	auipc	a0,0x5
    80003a6c:	b6850513          	addi	a0,a0,-1176 # 800085d0 <syscalls+0x178>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	ace080e7          	jalr	-1330(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a78:	04000613          	li	a2,64
    80003a7c:	4581                	li	a1,0
    80003a7e:	854e                	mv	a0,s3
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	260080e7          	jalr	608(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a88:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	00001097          	auipc	ra,0x1
    80003a92:	ca8080e7          	jalr	-856(ra) # 80004736 <log_write>
      brelse(bp);
    80003a96:	854a                	mv	a0,s2
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	a22080e7          	jalr	-1502(ra) # 800034ba <brelse>
      return iget(dev, inum);
    80003aa0:	85da                	mv	a1,s6
    80003aa2:	8556                	mv	a0,s5
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	db4080e7          	jalr	-588(ra) # 80003858 <iget>
}
    80003aac:	60a6                	ld	ra,72(sp)
    80003aae:	6406                	ld	s0,64(sp)
    80003ab0:	74e2                	ld	s1,56(sp)
    80003ab2:	7942                	ld	s2,48(sp)
    80003ab4:	79a2                	ld	s3,40(sp)
    80003ab6:	7a02                	ld	s4,32(sp)
    80003ab8:	6ae2                	ld	s5,24(sp)
    80003aba:	6b42                	ld	s6,16(sp)
    80003abc:	6ba2                	ld	s7,8(sp)
    80003abe:	6161                	addi	sp,sp,80
    80003ac0:	8082                	ret

0000000080003ac2 <iupdate>:
{
    80003ac2:	1101                	addi	sp,sp,-32
    80003ac4:	ec06                	sd	ra,24(sp)
    80003ac6:	e822                	sd	s0,16(sp)
    80003ac8:	e426                	sd	s1,8(sp)
    80003aca:	e04a                	sd	s2,0(sp)
    80003acc:	1000                	addi	s0,sp,32
    80003ace:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ad0:	415c                	lw	a5,4(a0)
    80003ad2:	0047d79b          	srliw	a5,a5,0x4
    80003ad6:	0001c597          	auipc	a1,0x1c
    80003ada:	6325a583          	lw	a1,1586(a1) # 80020108 <sb+0x18>
    80003ade:	9dbd                	addw	a1,a1,a5
    80003ae0:	4108                	lw	a0,0(a0)
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	8a8080e7          	jalr	-1880(ra) # 8000338a <bread>
    80003aea:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aec:	05850793          	addi	a5,a0,88
    80003af0:	40c8                	lw	a0,4(s1)
    80003af2:	893d                	andi	a0,a0,15
    80003af4:	051a                	slli	a0,a0,0x6
    80003af6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003af8:	04449703          	lh	a4,68(s1)
    80003afc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b00:	04649703          	lh	a4,70(s1)
    80003b04:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b08:	04849703          	lh	a4,72(s1)
    80003b0c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b10:	04a49703          	lh	a4,74(s1)
    80003b14:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b18:	44f8                	lw	a4,76(s1)
    80003b1a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b1c:	03400613          	li	a2,52
    80003b20:	05048593          	addi	a1,s1,80
    80003b24:	0531                	addi	a0,a0,12
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	21a080e7          	jalr	538(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b2e:	854a                	mv	a0,s2
    80003b30:	00001097          	auipc	ra,0x1
    80003b34:	c06080e7          	jalr	-1018(ra) # 80004736 <log_write>
  brelse(bp);
    80003b38:	854a                	mv	a0,s2
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	980080e7          	jalr	-1664(ra) # 800034ba <brelse>
}
    80003b42:	60e2                	ld	ra,24(sp)
    80003b44:	6442                	ld	s0,16(sp)
    80003b46:	64a2                	ld	s1,8(sp)
    80003b48:	6902                	ld	s2,0(sp)
    80003b4a:	6105                	addi	sp,sp,32
    80003b4c:	8082                	ret

0000000080003b4e <idup>:
{
    80003b4e:	1101                	addi	sp,sp,-32
    80003b50:	ec06                	sd	ra,24(sp)
    80003b52:	e822                	sd	s0,16(sp)
    80003b54:	e426                	sd	s1,8(sp)
    80003b56:	1000                	addi	s0,sp,32
    80003b58:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b5a:	0001c517          	auipc	a0,0x1c
    80003b5e:	5b650513          	addi	a0,a0,1462 # 80020110 <itable>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	082080e7          	jalr	130(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b6a:	449c                	lw	a5,8(s1)
    80003b6c:	2785                	addiw	a5,a5,1
    80003b6e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b70:	0001c517          	auipc	a0,0x1c
    80003b74:	5a050513          	addi	a0,a0,1440 # 80020110 <itable>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	120080e7          	jalr	288(ra) # 80000c98 <release>
}
    80003b80:	8526                	mv	a0,s1
    80003b82:	60e2                	ld	ra,24(sp)
    80003b84:	6442                	ld	s0,16(sp)
    80003b86:	64a2                	ld	s1,8(sp)
    80003b88:	6105                	addi	sp,sp,32
    80003b8a:	8082                	ret

0000000080003b8c <ilock>:
{
    80003b8c:	1101                	addi	sp,sp,-32
    80003b8e:	ec06                	sd	ra,24(sp)
    80003b90:	e822                	sd	s0,16(sp)
    80003b92:	e426                	sd	s1,8(sp)
    80003b94:	e04a                	sd	s2,0(sp)
    80003b96:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b98:	c115                	beqz	a0,80003bbc <ilock+0x30>
    80003b9a:	84aa                	mv	s1,a0
    80003b9c:	451c                	lw	a5,8(a0)
    80003b9e:	00f05f63          	blez	a5,80003bbc <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ba2:	0541                	addi	a0,a0,16
    80003ba4:	00001097          	auipc	ra,0x1
    80003ba8:	cb2080e7          	jalr	-846(ra) # 80004856 <acquiresleep>
  if(ip->valid == 0){
    80003bac:	40bc                	lw	a5,64(s1)
    80003bae:	cf99                	beqz	a5,80003bcc <ilock+0x40>
}
    80003bb0:	60e2                	ld	ra,24(sp)
    80003bb2:	6442                	ld	s0,16(sp)
    80003bb4:	64a2                	ld	s1,8(sp)
    80003bb6:	6902                	ld	s2,0(sp)
    80003bb8:	6105                	addi	sp,sp,32
    80003bba:	8082                	ret
    panic("ilock");
    80003bbc:	00005517          	auipc	a0,0x5
    80003bc0:	a2c50513          	addi	a0,a0,-1492 # 800085e8 <syscalls+0x190>
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	97a080e7          	jalr	-1670(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bcc:	40dc                	lw	a5,4(s1)
    80003bce:	0047d79b          	srliw	a5,a5,0x4
    80003bd2:	0001c597          	auipc	a1,0x1c
    80003bd6:	5365a583          	lw	a1,1334(a1) # 80020108 <sb+0x18>
    80003bda:	9dbd                	addw	a1,a1,a5
    80003bdc:	4088                	lw	a0,0(s1)
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	7ac080e7          	jalr	1964(ra) # 8000338a <bread>
    80003be6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003be8:	05850593          	addi	a1,a0,88
    80003bec:	40dc                	lw	a5,4(s1)
    80003bee:	8bbd                	andi	a5,a5,15
    80003bf0:	079a                	slli	a5,a5,0x6
    80003bf2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bf4:	00059783          	lh	a5,0(a1)
    80003bf8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bfc:	00259783          	lh	a5,2(a1)
    80003c00:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c04:	00459783          	lh	a5,4(a1)
    80003c08:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c0c:	00659783          	lh	a5,6(a1)
    80003c10:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c14:	459c                	lw	a5,8(a1)
    80003c16:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c18:	03400613          	li	a2,52
    80003c1c:	05b1                	addi	a1,a1,12
    80003c1e:	05048513          	addi	a0,s1,80
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	11e080e7          	jalr	286(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c2a:	854a                	mv	a0,s2
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	88e080e7          	jalr	-1906(ra) # 800034ba <brelse>
    ip->valid = 1;
    80003c34:	4785                	li	a5,1
    80003c36:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c38:	04449783          	lh	a5,68(s1)
    80003c3c:	fbb5                	bnez	a5,80003bb0 <ilock+0x24>
      panic("ilock: no type");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	9b250513          	addi	a0,a0,-1614 # 800085f0 <syscalls+0x198>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8f8080e7          	jalr	-1800(ra) # 8000053e <panic>

0000000080003c4e <iunlock>:
{
    80003c4e:	1101                	addi	sp,sp,-32
    80003c50:	ec06                	sd	ra,24(sp)
    80003c52:	e822                	sd	s0,16(sp)
    80003c54:	e426                	sd	s1,8(sp)
    80003c56:	e04a                	sd	s2,0(sp)
    80003c58:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c5a:	c905                	beqz	a0,80003c8a <iunlock+0x3c>
    80003c5c:	84aa                	mv	s1,a0
    80003c5e:	01050913          	addi	s2,a0,16
    80003c62:	854a                	mv	a0,s2
    80003c64:	00001097          	auipc	ra,0x1
    80003c68:	c8c080e7          	jalr	-884(ra) # 800048f0 <holdingsleep>
    80003c6c:	cd19                	beqz	a0,80003c8a <iunlock+0x3c>
    80003c6e:	449c                	lw	a5,8(s1)
    80003c70:	00f05d63          	blez	a5,80003c8a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c74:	854a                	mv	a0,s2
    80003c76:	00001097          	auipc	ra,0x1
    80003c7a:	c36080e7          	jalr	-970(ra) # 800048ac <releasesleep>
}
    80003c7e:	60e2                	ld	ra,24(sp)
    80003c80:	6442                	ld	s0,16(sp)
    80003c82:	64a2                	ld	s1,8(sp)
    80003c84:	6902                	ld	s2,0(sp)
    80003c86:	6105                	addi	sp,sp,32
    80003c88:	8082                	ret
    panic("iunlock");
    80003c8a:	00005517          	auipc	a0,0x5
    80003c8e:	97650513          	addi	a0,a0,-1674 # 80008600 <syscalls+0x1a8>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	8ac080e7          	jalr	-1876(ra) # 8000053e <panic>

0000000080003c9a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c9a:	7179                	addi	sp,sp,-48
    80003c9c:	f406                	sd	ra,40(sp)
    80003c9e:	f022                	sd	s0,32(sp)
    80003ca0:	ec26                	sd	s1,24(sp)
    80003ca2:	e84a                	sd	s2,16(sp)
    80003ca4:	e44e                	sd	s3,8(sp)
    80003ca6:	e052                	sd	s4,0(sp)
    80003ca8:	1800                	addi	s0,sp,48
    80003caa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cac:	05050493          	addi	s1,a0,80
    80003cb0:	08050913          	addi	s2,a0,128
    80003cb4:	a021                	j	80003cbc <itrunc+0x22>
    80003cb6:	0491                	addi	s1,s1,4
    80003cb8:	01248d63          	beq	s1,s2,80003cd2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cbc:	408c                	lw	a1,0(s1)
    80003cbe:	dde5                	beqz	a1,80003cb6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cc0:	0009a503          	lw	a0,0(s3)
    80003cc4:	00000097          	auipc	ra,0x0
    80003cc8:	90c080e7          	jalr	-1780(ra) # 800035d0 <bfree>
      ip->addrs[i] = 0;
    80003ccc:	0004a023          	sw	zero,0(s1)
    80003cd0:	b7dd                	j	80003cb6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cd2:	0809a583          	lw	a1,128(s3)
    80003cd6:	e185                	bnez	a1,80003cf6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cd8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cdc:	854e                	mv	a0,s3
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	de4080e7          	jalr	-540(ra) # 80003ac2 <iupdate>
}
    80003ce6:	70a2                	ld	ra,40(sp)
    80003ce8:	7402                	ld	s0,32(sp)
    80003cea:	64e2                	ld	s1,24(sp)
    80003cec:	6942                	ld	s2,16(sp)
    80003cee:	69a2                	ld	s3,8(sp)
    80003cf0:	6a02                	ld	s4,0(sp)
    80003cf2:	6145                	addi	sp,sp,48
    80003cf4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cf6:	0009a503          	lw	a0,0(s3)
    80003cfa:	fffff097          	auipc	ra,0xfffff
    80003cfe:	690080e7          	jalr	1680(ra) # 8000338a <bread>
    80003d02:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d04:	05850493          	addi	s1,a0,88
    80003d08:	45850913          	addi	s2,a0,1112
    80003d0c:	a811                	j	80003d20 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d0e:	0009a503          	lw	a0,0(s3)
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	8be080e7          	jalr	-1858(ra) # 800035d0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d1a:	0491                	addi	s1,s1,4
    80003d1c:	01248563          	beq	s1,s2,80003d26 <itrunc+0x8c>
      if(a[j])
    80003d20:	408c                	lw	a1,0(s1)
    80003d22:	dde5                	beqz	a1,80003d1a <itrunc+0x80>
    80003d24:	b7ed                	j	80003d0e <itrunc+0x74>
    brelse(bp);
    80003d26:	8552                	mv	a0,s4
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	792080e7          	jalr	1938(ra) # 800034ba <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d30:	0809a583          	lw	a1,128(s3)
    80003d34:	0009a503          	lw	a0,0(s3)
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	898080e7          	jalr	-1896(ra) # 800035d0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d40:	0809a023          	sw	zero,128(s3)
    80003d44:	bf51                	j	80003cd8 <itrunc+0x3e>

0000000080003d46 <iput>:
{
    80003d46:	1101                	addi	sp,sp,-32
    80003d48:	ec06                	sd	ra,24(sp)
    80003d4a:	e822                	sd	s0,16(sp)
    80003d4c:	e426                	sd	s1,8(sp)
    80003d4e:	e04a                	sd	s2,0(sp)
    80003d50:	1000                	addi	s0,sp,32
    80003d52:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d54:	0001c517          	auipc	a0,0x1c
    80003d58:	3bc50513          	addi	a0,a0,956 # 80020110 <itable>
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	e88080e7          	jalr	-376(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d64:	4498                	lw	a4,8(s1)
    80003d66:	4785                	li	a5,1
    80003d68:	02f70363          	beq	a4,a5,80003d8e <iput+0x48>
  ip->ref--;
    80003d6c:	449c                	lw	a5,8(s1)
    80003d6e:	37fd                	addiw	a5,a5,-1
    80003d70:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d72:	0001c517          	auipc	a0,0x1c
    80003d76:	39e50513          	addi	a0,a0,926 # 80020110 <itable>
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	f1e080e7          	jalr	-226(ra) # 80000c98 <release>
}
    80003d82:	60e2                	ld	ra,24(sp)
    80003d84:	6442                	ld	s0,16(sp)
    80003d86:	64a2                	ld	s1,8(sp)
    80003d88:	6902                	ld	s2,0(sp)
    80003d8a:	6105                	addi	sp,sp,32
    80003d8c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d8e:	40bc                	lw	a5,64(s1)
    80003d90:	dff1                	beqz	a5,80003d6c <iput+0x26>
    80003d92:	04a49783          	lh	a5,74(s1)
    80003d96:	fbf9                	bnez	a5,80003d6c <iput+0x26>
    acquiresleep(&ip->lock);
    80003d98:	01048913          	addi	s2,s1,16
    80003d9c:	854a                	mv	a0,s2
    80003d9e:	00001097          	auipc	ra,0x1
    80003da2:	ab8080e7          	jalr	-1352(ra) # 80004856 <acquiresleep>
    release(&itable.lock);
    80003da6:	0001c517          	auipc	a0,0x1c
    80003daa:	36a50513          	addi	a0,a0,874 # 80020110 <itable>
    80003dae:	ffffd097          	auipc	ra,0xffffd
    80003db2:	eea080e7          	jalr	-278(ra) # 80000c98 <release>
    itrunc(ip);
    80003db6:	8526                	mv	a0,s1
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	ee2080e7          	jalr	-286(ra) # 80003c9a <itrunc>
    ip->type = 0;
    80003dc0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003dc4:	8526                	mv	a0,s1
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	cfc080e7          	jalr	-772(ra) # 80003ac2 <iupdate>
    ip->valid = 0;
    80003dce:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dd2:	854a                	mv	a0,s2
    80003dd4:	00001097          	auipc	ra,0x1
    80003dd8:	ad8080e7          	jalr	-1320(ra) # 800048ac <releasesleep>
    acquire(&itable.lock);
    80003ddc:	0001c517          	auipc	a0,0x1c
    80003de0:	33450513          	addi	a0,a0,820 # 80020110 <itable>
    80003de4:	ffffd097          	auipc	ra,0xffffd
    80003de8:	e00080e7          	jalr	-512(ra) # 80000be4 <acquire>
    80003dec:	b741                	j	80003d6c <iput+0x26>

0000000080003dee <iunlockput>:
{
    80003dee:	1101                	addi	sp,sp,-32
    80003df0:	ec06                	sd	ra,24(sp)
    80003df2:	e822                	sd	s0,16(sp)
    80003df4:	e426                	sd	s1,8(sp)
    80003df6:	1000                	addi	s0,sp,32
    80003df8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	e54080e7          	jalr	-428(ra) # 80003c4e <iunlock>
  iput(ip);
    80003e02:	8526                	mv	a0,s1
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	f42080e7          	jalr	-190(ra) # 80003d46 <iput>
}
    80003e0c:	60e2                	ld	ra,24(sp)
    80003e0e:	6442                	ld	s0,16(sp)
    80003e10:	64a2                	ld	s1,8(sp)
    80003e12:	6105                	addi	sp,sp,32
    80003e14:	8082                	ret

0000000080003e16 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e16:	1141                	addi	sp,sp,-16
    80003e18:	e422                	sd	s0,8(sp)
    80003e1a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e1c:	411c                	lw	a5,0(a0)
    80003e1e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e20:	415c                	lw	a5,4(a0)
    80003e22:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e24:	04451783          	lh	a5,68(a0)
    80003e28:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e2c:	04a51783          	lh	a5,74(a0)
    80003e30:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e34:	04c56783          	lwu	a5,76(a0)
    80003e38:	e99c                	sd	a5,16(a1)
}
    80003e3a:	6422                	ld	s0,8(sp)
    80003e3c:	0141                	addi	sp,sp,16
    80003e3e:	8082                	ret

0000000080003e40 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e40:	457c                	lw	a5,76(a0)
    80003e42:	0ed7e963          	bltu	a5,a3,80003f34 <readi+0xf4>
{
    80003e46:	7159                	addi	sp,sp,-112
    80003e48:	f486                	sd	ra,104(sp)
    80003e4a:	f0a2                	sd	s0,96(sp)
    80003e4c:	eca6                	sd	s1,88(sp)
    80003e4e:	e8ca                	sd	s2,80(sp)
    80003e50:	e4ce                	sd	s3,72(sp)
    80003e52:	e0d2                	sd	s4,64(sp)
    80003e54:	fc56                	sd	s5,56(sp)
    80003e56:	f85a                	sd	s6,48(sp)
    80003e58:	f45e                	sd	s7,40(sp)
    80003e5a:	f062                	sd	s8,32(sp)
    80003e5c:	ec66                	sd	s9,24(sp)
    80003e5e:	e86a                	sd	s10,16(sp)
    80003e60:	e46e                	sd	s11,8(sp)
    80003e62:	1880                	addi	s0,sp,112
    80003e64:	8baa                	mv	s7,a0
    80003e66:	8c2e                	mv	s8,a1
    80003e68:	8ab2                	mv	s5,a2
    80003e6a:	84b6                	mv	s1,a3
    80003e6c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e6e:	9f35                	addw	a4,a4,a3
    return 0;
    80003e70:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e72:	0ad76063          	bltu	a4,a3,80003f12 <readi+0xd2>
  if(off + n > ip->size)
    80003e76:	00e7f463          	bgeu	a5,a4,80003e7e <readi+0x3e>
    n = ip->size - off;
    80003e7a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e7e:	0a0b0963          	beqz	s6,80003f30 <readi+0xf0>
    80003e82:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e84:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e88:	5cfd                	li	s9,-1
    80003e8a:	a82d                	j	80003ec4 <readi+0x84>
    80003e8c:	020a1d93          	slli	s11,s4,0x20
    80003e90:	020ddd93          	srli	s11,s11,0x20
    80003e94:	05890613          	addi	a2,s2,88
    80003e98:	86ee                	mv	a3,s11
    80003e9a:	963a                	add	a2,a2,a4
    80003e9c:	85d6                	mv	a1,s5
    80003e9e:	8562                	mv	a0,s8
    80003ea0:	ffffe097          	auipc	ra,0xffffe
    80003ea4:	de8080e7          	jalr	-536(ra) # 80001c88 <either_copyout>
    80003ea8:	05950d63          	beq	a0,s9,80003f02 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003eac:	854a                	mv	a0,s2
    80003eae:	fffff097          	auipc	ra,0xfffff
    80003eb2:	60c080e7          	jalr	1548(ra) # 800034ba <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eb6:	013a09bb          	addw	s3,s4,s3
    80003eba:	009a04bb          	addw	s1,s4,s1
    80003ebe:	9aee                	add	s5,s5,s11
    80003ec0:	0569f763          	bgeu	s3,s6,80003f0e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ec4:	000ba903          	lw	s2,0(s7)
    80003ec8:	00a4d59b          	srliw	a1,s1,0xa
    80003ecc:	855e                	mv	a0,s7
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	8b0080e7          	jalr	-1872(ra) # 8000377e <bmap>
    80003ed6:	0005059b          	sext.w	a1,a0
    80003eda:	854a                	mv	a0,s2
    80003edc:	fffff097          	auipc	ra,0xfffff
    80003ee0:	4ae080e7          	jalr	1198(ra) # 8000338a <bread>
    80003ee4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ee6:	3ff4f713          	andi	a4,s1,1023
    80003eea:	40ed07bb          	subw	a5,s10,a4
    80003eee:	413b06bb          	subw	a3,s6,s3
    80003ef2:	8a3e                	mv	s4,a5
    80003ef4:	2781                	sext.w	a5,a5
    80003ef6:	0006861b          	sext.w	a2,a3
    80003efa:	f8f679e3          	bgeu	a2,a5,80003e8c <readi+0x4c>
    80003efe:	8a36                	mv	s4,a3
    80003f00:	b771                	j	80003e8c <readi+0x4c>
      brelse(bp);
    80003f02:	854a                	mv	a0,s2
    80003f04:	fffff097          	auipc	ra,0xfffff
    80003f08:	5b6080e7          	jalr	1462(ra) # 800034ba <brelse>
      tot = -1;
    80003f0c:	59fd                	li	s3,-1
  }
  return tot;
    80003f0e:	0009851b          	sext.w	a0,s3
}
    80003f12:	70a6                	ld	ra,104(sp)
    80003f14:	7406                	ld	s0,96(sp)
    80003f16:	64e6                	ld	s1,88(sp)
    80003f18:	6946                	ld	s2,80(sp)
    80003f1a:	69a6                	ld	s3,72(sp)
    80003f1c:	6a06                	ld	s4,64(sp)
    80003f1e:	7ae2                	ld	s5,56(sp)
    80003f20:	7b42                	ld	s6,48(sp)
    80003f22:	7ba2                	ld	s7,40(sp)
    80003f24:	7c02                	ld	s8,32(sp)
    80003f26:	6ce2                	ld	s9,24(sp)
    80003f28:	6d42                	ld	s10,16(sp)
    80003f2a:	6da2                	ld	s11,8(sp)
    80003f2c:	6165                	addi	sp,sp,112
    80003f2e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f30:	89da                	mv	s3,s6
    80003f32:	bff1                	j	80003f0e <readi+0xce>
    return 0;
    80003f34:	4501                	li	a0,0
}
    80003f36:	8082                	ret

0000000080003f38 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f38:	457c                	lw	a5,76(a0)
    80003f3a:	10d7e863          	bltu	a5,a3,8000404a <writei+0x112>
{
    80003f3e:	7159                	addi	sp,sp,-112
    80003f40:	f486                	sd	ra,104(sp)
    80003f42:	f0a2                	sd	s0,96(sp)
    80003f44:	eca6                	sd	s1,88(sp)
    80003f46:	e8ca                	sd	s2,80(sp)
    80003f48:	e4ce                	sd	s3,72(sp)
    80003f4a:	e0d2                	sd	s4,64(sp)
    80003f4c:	fc56                	sd	s5,56(sp)
    80003f4e:	f85a                	sd	s6,48(sp)
    80003f50:	f45e                	sd	s7,40(sp)
    80003f52:	f062                	sd	s8,32(sp)
    80003f54:	ec66                	sd	s9,24(sp)
    80003f56:	e86a                	sd	s10,16(sp)
    80003f58:	e46e                	sd	s11,8(sp)
    80003f5a:	1880                	addi	s0,sp,112
    80003f5c:	8b2a                	mv	s6,a0
    80003f5e:	8c2e                	mv	s8,a1
    80003f60:	8ab2                	mv	s5,a2
    80003f62:	8936                	mv	s2,a3
    80003f64:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f66:	00e687bb          	addw	a5,a3,a4
    80003f6a:	0ed7e263          	bltu	a5,a3,8000404e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f6e:	00043737          	lui	a4,0x43
    80003f72:	0ef76063          	bltu	a4,a5,80004052 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f76:	0c0b8863          	beqz	s7,80004046 <writei+0x10e>
    80003f7a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f7c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f80:	5cfd                	li	s9,-1
    80003f82:	a091                	j	80003fc6 <writei+0x8e>
    80003f84:	02099d93          	slli	s11,s3,0x20
    80003f88:	020ddd93          	srli	s11,s11,0x20
    80003f8c:	05848513          	addi	a0,s1,88
    80003f90:	86ee                	mv	a3,s11
    80003f92:	8656                	mv	a2,s5
    80003f94:	85e2                	mv	a1,s8
    80003f96:	953a                	add	a0,a0,a4
    80003f98:	ffffe097          	auipc	ra,0xffffe
    80003f9c:	d46080e7          	jalr	-698(ra) # 80001cde <either_copyin>
    80003fa0:	07950263          	beq	a0,s9,80004004 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fa4:	8526                	mv	a0,s1
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	790080e7          	jalr	1936(ra) # 80004736 <log_write>
    brelse(bp);
    80003fae:	8526                	mv	a0,s1
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	50a080e7          	jalr	1290(ra) # 800034ba <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fb8:	01498a3b          	addw	s4,s3,s4
    80003fbc:	0129893b          	addw	s2,s3,s2
    80003fc0:	9aee                	add	s5,s5,s11
    80003fc2:	057a7663          	bgeu	s4,s7,8000400e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fc6:	000b2483          	lw	s1,0(s6)
    80003fca:	00a9559b          	srliw	a1,s2,0xa
    80003fce:	855a                	mv	a0,s6
    80003fd0:	fffff097          	auipc	ra,0xfffff
    80003fd4:	7ae080e7          	jalr	1966(ra) # 8000377e <bmap>
    80003fd8:	0005059b          	sext.w	a1,a0
    80003fdc:	8526                	mv	a0,s1
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	3ac080e7          	jalr	940(ra) # 8000338a <bread>
    80003fe6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe8:	3ff97713          	andi	a4,s2,1023
    80003fec:	40ed07bb          	subw	a5,s10,a4
    80003ff0:	414b86bb          	subw	a3,s7,s4
    80003ff4:	89be                	mv	s3,a5
    80003ff6:	2781                	sext.w	a5,a5
    80003ff8:	0006861b          	sext.w	a2,a3
    80003ffc:	f8f674e3          	bgeu	a2,a5,80003f84 <writei+0x4c>
    80004000:	89b6                	mv	s3,a3
    80004002:	b749                	j	80003f84 <writei+0x4c>
      brelse(bp);
    80004004:	8526                	mv	a0,s1
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	4b4080e7          	jalr	1204(ra) # 800034ba <brelse>
  }

  if(off > ip->size)
    8000400e:	04cb2783          	lw	a5,76(s6)
    80004012:	0127f463          	bgeu	a5,s2,8000401a <writei+0xe2>
    ip->size = off;
    80004016:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000401a:	855a                	mv	a0,s6
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	aa6080e7          	jalr	-1370(ra) # 80003ac2 <iupdate>

  return tot;
    80004024:	000a051b          	sext.w	a0,s4
}
    80004028:	70a6                	ld	ra,104(sp)
    8000402a:	7406                	ld	s0,96(sp)
    8000402c:	64e6                	ld	s1,88(sp)
    8000402e:	6946                	ld	s2,80(sp)
    80004030:	69a6                	ld	s3,72(sp)
    80004032:	6a06                	ld	s4,64(sp)
    80004034:	7ae2                	ld	s5,56(sp)
    80004036:	7b42                	ld	s6,48(sp)
    80004038:	7ba2                	ld	s7,40(sp)
    8000403a:	7c02                	ld	s8,32(sp)
    8000403c:	6ce2                	ld	s9,24(sp)
    8000403e:	6d42                	ld	s10,16(sp)
    80004040:	6da2                	ld	s11,8(sp)
    80004042:	6165                	addi	sp,sp,112
    80004044:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004046:	8a5e                	mv	s4,s7
    80004048:	bfc9                	j	8000401a <writei+0xe2>
    return -1;
    8000404a:	557d                	li	a0,-1
}
    8000404c:	8082                	ret
    return -1;
    8000404e:	557d                	li	a0,-1
    80004050:	bfe1                	j	80004028 <writei+0xf0>
    return -1;
    80004052:	557d                	li	a0,-1
    80004054:	bfd1                	j	80004028 <writei+0xf0>

0000000080004056 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004056:	1141                	addi	sp,sp,-16
    80004058:	e406                	sd	ra,8(sp)
    8000405a:	e022                	sd	s0,0(sp)
    8000405c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000405e:	4639                	li	a2,14
    80004060:	ffffd097          	auipc	ra,0xffffd
    80004064:	d58080e7          	jalr	-680(ra) # 80000db8 <strncmp>
}
    80004068:	60a2                	ld	ra,8(sp)
    8000406a:	6402                	ld	s0,0(sp)
    8000406c:	0141                	addi	sp,sp,16
    8000406e:	8082                	ret

0000000080004070 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004070:	7139                	addi	sp,sp,-64
    80004072:	fc06                	sd	ra,56(sp)
    80004074:	f822                	sd	s0,48(sp)
    80004076:	f426                	sd	s1,40(sp)
    80004078:	f04a                	sd	s2,32(sp)
    8000407a:	ec4e                	sd	s3,24(sp)
    8000407c:	e852                	sd	s4,16(sp)
    8000407e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004080:	04451703          	lh	a4,68(a0)
    80004084:	4785                	li	a5,1
    80004086:	00f71a63          	bne	a4,a5,8000409a <dirlookup+0x2a>
    8000408a:	892a                	mv	s2,a0
    8000408c:	89ae                	mv	s3,a1
    8000408e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004090:	457c                	lw	a5,76(a0)
    80004092:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004094:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004096:	e79d                	bnez	a5,800040c4 <dirlookup+0x54>
    80004098:	a8a5                	j	80004110 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000409a:	00004517          	auipc	a0,0x4
    8000409e:	56e50513          	addi	a0,a0,1390 # 80008608 <syscalls+0x1b0>
    800040a2:	ffffc097          	auipc	ra,0xffffc
    800040a6:	49c080e7          	jalr	1180(ra) # 8000053e <panic>
      panic("dirlookup read");
    800040aa:	00004517          	auipc	a0,0x4
    800040ae:	57650513          	addi	a0,a0,1398 # 80008620 <syscalls+0x1c8>
    800040b2:	ffffc097          	auipc	ra,0xffffc
    800040b6:	48c080e7          	jalr	1164(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ba:	24c1                	addiw	s1,s1,16
    800040bc:	04c92783          	lw	a5,76(s2)
    800040c0:	04f4f763          	bgeu	s1,a5,8000410e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c4:	4741                	li	a4,16
    800040c6:	86a6                	mv	a3,s1
    800040c8:	fc040613          	addi	a2,s0,-64
    800040cc:	4581                	li	a1,0
    800040ce:	854a                	mv	a0,s2
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	d70080e7          	jalr	-656(ra) # 80003e40 <readi>
    800040d8:	47c1                	li	a5,16
    800040da:	fcf518e3          	bne	a0,a5,800040aa <dirlookup+0x3a>
    if(de.inum == 0)
    800040de:	fc045783          	lhu	a5,-64(s0)
    800040e2:	dfe1                	beqz	a5,800040ba <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040e4:	fc240593          	addi	a1,s0,-62
    800040e8:	854e                	mv	a0,s3
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	f6c080e7          	jalr	-148(ra) # 80004056 <namecmp>
    800040f2:	f561                	bnez	a0,800040ba <dirlookup+0x4a>
      if(poff)
    800040f4:	000a0463          	beqz	s4,800040fc <dirlookup+0x8c>
        *poff = off;
    800040f8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040fc:	fc045583          	lhu	a1,-64(s0)
    80004100:	00092503          	lw	a0,0(s2)
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	754080e7          	jalr	1876(ra) # 80003858 <iget>
    8000410c:	a011                	j	80004110 <dirlookup+0xa0>
  return 0;
    8000410e:	4501                	li	a0,0
}
    80004110:	70e2                	ld	ra,56(sp)
    80004112:	7442                	ld	s0,48(sp)
    80004114:	74a2                	ld	s1,40(sp)
    80004116:	7902                	ld	s2,32(sp)
    80004118:	69e2                	ld	s3,24(sp)
    8000411a:	6a42                	ld	s4,16(sp)
    8000411c:	6121                	addi	sp,sp,64
    8000411e:	8082                	ret

0000000080004120 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004120:	711d                	addi	sp,sp,-96
    80004122:	ec86                	sd	ra,88(sp)
    80004124:	e8a2                	sd	s0,80(sp)
    80004126:	e4a6                	sd	s1,72(sp)
    80004128:	e0ca                	sd	s2,64(sp)
    8000412a:	fc4e                	sd	s3,56(sp)
    8000412c:	f852                	sd	s4,48(sp)
    8000412e:	f456                	sd	s5,40(sp)
    80004130:	f05a                	sd	s6,32(sp)
    80004132:	ec5e                	sd	s7,24(sp)
    80004134:	e862                	sd	s8,16(sp)
    80004136:	e466                	sd	s9,8(sp)
    80004138:	1080                	addi	s0,sp,96
    8000413a:	84aa                	mv	s1,a0
    8000413c:	8b2e                	mv	s6,a1
    8000413e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004140:	00054703          	lbu	a4,0(a0)
    80004144:	02f00793          	li	a5,47
    80004148:	02f70363          	beq	a4,a5,8000416e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	7bc080e7          	jalr	1980(ra) # 80001908 <myproc>
    80004154:	17053503          	ld	a0,368(a0)
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	9f6080e7          	jalr	-1546(ra) # 80003b4e <idup>
    80004160:	89aa                	mv	s3,a0
  while(*path == '/')
    80004162:	02f00913          	li	s2,47
  len = path - s;
    80004166:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004168:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000416a:	4c05                	li	s8,1
    8000416c:	a865                	j	80004224 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000416e:	4585                	li	a1,1
    80004170:	4505                	li	a0,1
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	6e6080e7          	jalr	1766(ra) # 80003858 <iget>
    8000417a:	89aa                	mv	s3,a0
    8000417c:	b7dd                	j	80004162 <namex+0x42>
      iunlockput(ip);
    8000417e:	854e                	mv	a0,s3
    80004180:	00000097          	auipc	ra,0x0
    80004184:	c6e080e7          	jalr	-914(ra) # 80003dee <iunlockput>
      return 0;
    80004188:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000418a:	854e                	mv	a0,s3
    8000418c:	60e6                	ld	ra,88(sp)
    8000418e:	6446                	ld	s0,80(sp)
    80004190:	64a6                	ld	s1,72(sp)
    80004192:	6906                	ld	s2,64(sp)
    80004194:	79e2                	ld	s3,56(sp)
    80004196:	7a42                	ld	s4,48(sp)
    80004198:	7aa2                	ld	s5,40(sp)
    8000419a:	7b02                	ld	s6,32(sp)
    8000419c:	6be2                	ld	s7,24(sp)
    8000419e:	6c42                	ld	s8,16(sp)
    800041a0:	6ca2                	ld	s9,8(sp)
    800041a2:	6125                	addi	sp,sp,96
    800041a4:	8082                	ret
      iunlock(ip);
    800041a6:	854e                	mv	a0,s3
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	aa6080e7          	jalr	-1370(ra) # 80003c4e <iunlock>
      return ip;
    800041b0:	bfe9                	j	8000418a <namex+0x6a>
      iunlockput(ip);
    800041b2:	854e                	mv	a0,s3
    800041b4:	00000097          	auipc	ra,0x0
    800041b8:	c3a080e7          	jalr	-966(ra) # 80003dee <iunlockput>
      return 0;
    800041bc:	89d2                	mv	s3,s4
    800041be:	b7f1                	j	8000418a <namex+0x6a>
  len = path - s;
    800041c0:	40b48633          	sub	a2,s1,a1
    800041c4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041c8:	094cd463          	bge	s9,s4,80004250 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041cc:	4639                	li	a2,14
    800041ce:	8556                	mv	a0,s5
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	b70080e7          	jalr	-1168(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041d8:	0004c783          	lbu	a5,0(s1)
    800041dc:	01279763          	bne	a5,s2,800041ea <namex+0xca>
    path++;
    800041e0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041e2:	0004c783          	lbu	a5,0(s1)
    800041e6:	ff278de3          	beq	a5,s2,800041e0 <namex+0xc0>
    ilock(ip);
    800041ea:	854e                	mv	a0,s3
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	9a0080e7          	jalr	-1632(ra) # 80003b8c <ilock>
    if(ip->type != T_DIR){
    800041f4:	04499783          	lh	a5,68(s3)
    800041f8:	f98793e3          	bne	a5,s8,8000417e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041fc:	000b0563          	beqz	s6,80004206 <namex+0xe6>
    80004200:	0004c783          	lbu	a5,0(s1)
    80004204:	d3cd                	beqz	a5,800041a6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004206:	865e                	mv	a2,s7
    80004208:	85d6                	mv	a1,s5
    8000420a:	854e                	mv	a0,s3
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	e64080e7          	jalr	-412(ra) # 80004070 <dirlookup>
    80004214:	8a2a                	mv	s4,a0
    80004216:	dd51                	beqz	a0,800041b2 <namex+0x92>
    iunlockput(ip);
    80004218:	854e                	mv	a0,s3
    8000421a:	00000097          	auipc	ra,0x0
    8000421e:	bd4080e7          	jalr	-1068(ra) # 80003dee <iunlockput>
    ip = next;
    80004222:	89d2                	mv	s3,s4
  while(*path == '/')
    80004224:	0004c783          	lbu	a5,0(s1)
    80004228:	05279763          	bne	a5,s2,80004276 <namex+0x156>
    path++;
    8000422c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000422e:	0004c783          	lbu	a5,0(s1)
    80004232:	ff278de3          	beq	a5,s2,8000422c <namex+0x10c>
  if(*path == 0)
    80004236:	c79d                	beqz	a5,80004264 <namex+0x144>
    path++;
    80004238:	85a6                	mv	a1,s1
  len = path - s;
    8000423a:	8a5e                	mv	s4,s7
    8000423c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000423e:	01278963          	beq	a5,s2,80004250 <namex+0x130>
    80004242:	dfbd                	beqz	a5,800041c0 <namex+0xa0>
    path++;
    80004244:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004246:	0004c783          	lbu	a5,0(s1)
    8000424a:	ff279ce3          	bne	a5,s2,80004242 <namex+0x122>
    8000424e:	bf8d                	j	800041c0 <namex+0xa0>
    memmove(name, s, len);
    80004250:	2601                	sext.w	a2,a2
    80004252:	8556                	mv	a0,s5
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	aec080e7          	jalr	-1300(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000425c:	9a56                	add	s4,s4,s5
    8000425e:	000a0023          	sb	zero,0(s4)
    80004262:	bf9d                	j	800041d8 <namex+0xb8>
  if(nameiparent){
    80004264:	f20b03e3          	beqz	s6,8000418a <namex+0x6a>
    iput(ip);
    80004268:	854e                	mv	a0,s3
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	adc080e7          	jalr	-1316(ra) # 80003d46 <iput>
    return 0;
    80004272:	4981                	li	s3,0
    80004274:	bf19                	j	8000418a <namex+0x6a>
  if(*path == 0)
    80004276:	d7fd                	beqz	a5,80004264 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004278:	0004c783          	lbu	a5,0(s1)
    8000427c:	85a6                	mv	a1,s1
    8000427e:	b7d1                	j	80004242 <namex+0x122>

0000000080004280 <dirlink>:
{
    80004280:	7139                	addi	sp,sp,-64
    80004282:	fc06                	sd	ra,56(sp)
    80004284:	f822                	sd	s0,48(sp)
    80004286:	f426                	sd	s1,40(sp)
    80004288:	f04a                	sd	s2,32(sp)
    8000428a:	ec4e                	sd	s3,24(sp)
    8000428c:	e852                	sd	s4,16(sp)
    8000428e:	0080                	addi	s0,sp,64
    80004290:	892a                	mv	s2,a0
    80004292:	8a2e                	mv	s4,a1
    80004294:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004296:	4601                	li	a2,0
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	dd8080e7          	jalr	-552(ra) # 80004070 <dirlookup>
    800042a0:	e93d                	bnez	a0,80004316 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a2:	04c92483          	lw	s1,76(s2)
    800042a6:	c49d                	beqz	s1,800042d4 <dirlink+0x54>
    800042a8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042aa:	4741                	li	a4,16
    800042ac:	86a6                	mv	a3,s1
    800042ae:	fc040613          	addi	a2,s0,-64
    800042b2:	4581                	li	a1,0
    800042b4:	854a                	mv	a0,s2
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	b8a080e7          	jalr	-1142(ra) # 80003e40 <readi>
    800042be:	47c1                	li	a5,16
    800042c0:	06f51163          	bne	a0,a5,80004322 <dirlink+0xa2>
    if(de.inum == 0)
    800042c4:	fc045783          	lhu	a5,-64(s0)
    800042c8:	c791                	beqz	a5,800042d4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ca:	24c1                	addiw	s1,s1,16
    800042cc:	04c92783          	lw	a5,76(s2)
    800042d0:	fcf4ede3          	bltu	s1,a5,800042aa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042d4:	4639                	li	a2,14
    800042d6:	85d2                	mv	a1,s4
    800042d8:	fc240513          	addi	a0,s0,-62
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	b18080e7          	jalr	-1256(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042e4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042e8:	4741                	li	a4,16
    800042ea:	86a6                	mv	a3,s1
    800042ec:	fc040613          	addi	a2,s0,-64
    800042f0:	4581                	li	a1,0
    800042f2:	854a                	mv	a0,s2
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	c44080e7          	jalr	-956(ra) # 80003f38 <writei>
    800042fc:	872a                	mv	a4,a0
    800042fe:	47c1                	li	a5,16
  return 0;
    80004300:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004302:	02f71863          	bne	a4,a5,80004332 <dirlink+0xb2>
}
    80004306:	70e2                	ld	ra,56(sp)
    80004308:	7442                	ld	s0,48(sp)
    8000430a:	74a2                	ld	s1,40(sp)
    8000430c:	7902                	ld	s2,32(sp)
    8000430e:	69e2                	ld	s3,24(sp)
    80004310:	6a42                	ld	s4,16(sp)
    80004312:	6121                	addi	sp,sp,64
    80004314:	8082                	ret
    iput(ip);
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	a30080e7          	jalr	-1488(ra) # 80003d46 <iput>
    return -1;
    8000431e:	557d                	li	a0,-1
    80004320:	b7dd                	j	80004306 <dirlink+0x86>
      panic("dirlink read");
    80004322:	00004517          	auipc	a0,0x4
    80004326:	30e50513          	addi	a0,a0,782 # 80008630 <syscalls+0x1d8>
    8000432a:	ffffc097          	auipc	ra,0xffffc
    8000432e:	214080e7          	jalr	532(ra) # 8000053e <panic>
    panic("dirlink");
    80004332:	00004517          	auipc	a0,0x4
    80004336:	40e50513          	addi	a0,a0,1038 # 80008740 <syscalls+0x2e8>
    8000433a:	ffffc097          	auipc	ra,0xffffc
    8000433e:	204080e7          	jalr	516(ra) # 8000053e <panic>

0000000080004342 <namei>:

struct inode*
namei(char *path)
{
    80004342:	1101                	addi	sp,sp,-32
    80004344:	ec06                	sd	ra,24(sp)
    80004346:	e822                	sd	s0,16(sp)
    80004348:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000434a:	fe040613          	addi	a2,s0,-32
    8000434e:	4581                	li	a1,0
    80004350:	00000097          	auipc	ra,0x0
    80004354:	dd0080e7          	jalr	-560(ra) # 80004120 <namex>
}
    80004358:	60e2                	ld	ra,24(sp)
    8000435a:	6442                	ld	s0,16(sp)
    8000435c:	6105                	addi	sp,sp,32
    8000435e:	8082                	ret

0000000080004360 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004360:	1141                	addi	sp,sp,-16
    80004362:	e406                	sd	ra,8(sp)
    80004364:	e022                	sd	s0,0(sp)
    80004366:	0800                	addi	s0,sp,16
    80004368:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000436a:	4585                	li	a1,1
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	db4080e7          	jalr	-588(ra) # 80004120 <namex>
}
    80004374:	60a2                	ld	ra,8(sp)
    80004376:	6402                	ld	s0,0(sp)
    80004378:	0141                	addi	sp,sp,16
    8000437a:	8082                	ret

000000008000437c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000437c:	1101                	addi	sp,sp,-32
    8000437e:	ec06                	sd	ra,24(sp)
    80004380:	e822                	sd	s0,16(sp)
    80004382:	e426                	sd	s1,8(sp)
    80004384:	e04a                	sd	s2,0(sp)
    80004386:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004388:	0001e917          	auipc	s2,0x1e
    8000438c:	83090913          	addi	s2,s2,-2000 # 80021bb8 <log>
    80004390:	01892583          	lw	a1,24(s2)
    80004394:	02892503          	lw	a0,40(s2)
    80004398:	fffff097          	auipc	ra,0xfffff
    8000439c:	ff2080e7          	jalr	-14(ra) # 8000338a <bread>
    800043a0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043a2:	02c92683          	lw	a3,44(s2)
    800043a6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043a8:	02d05763          	blez	a3,800043d6 <write_head+0x5a>
    800043ac:	0001e797          	auipc	a5,0x1e
    800043b0:	83c78793          	addi	a5,a5,-1988 # 80021be8 <log+0x30>
    800043b4:	05c50713          	addi	a4,a0,92
    800043b8:	36fd                	addiw	a3,a3,-1
    800043ba:	1682                	slli	a3,a3,0x20
    800043bc:	9281                	srli	a3,a3,0x20
    800043be:	068a                	slli	a3,a3,0x2
    800043c0:	0001e617          	auipc	a2,0x1e
    800043c4:	82c60613          	addi	a2,a2,-2004 # 80021bec <log+0x34>
    800043c8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043ca:	4390                	lw	a2,0(a5)
    800043cc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043ce:	0791                	addi	a5,a5,4
    800043d0:	0711                	addi	a4,a4,4
    800043d2:	fed79ce3          	bne	a5,a3,800043ca <write_head+0x4e>
  }
  bwrite(buf);
    800043d6:	8526                	mv	a0,s1
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	0a4080e7          	jalr	164(ra) # 8000347c <bwrite>
  brelse(buf);
    800043e0:	8526                	mv	a0,s1
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	0d8080e7          	jalr	216(ra) # 800034ba <brelse>
}
    800043ea:	60e2                	ld	ra,24(sp)
    800043ec:	6442                	ld	s0,16(sp)
    800043ee:	64a2                	ld	s1,8(sp)
    800043f0:	6902                	ld	s2,0(sp)
    800043f2:	6105                	addi	sp,sp,32
    800043f4:	8082                	ret

00000000800043f6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f6:	0001d797          	auipc	a5,0x1d
    800043fa:	7ee7a783          	lw	a5,2030(a5) # 80021be4 <log+0x2c>
    800043fe:	0af05d63          	blez	a5,800044b8 <install_trans+0xc2>
{
    80004402:	7139                	addi	sp,sp,-64
    80004404:	fc06                	sd	ra,56(sp)
    80004406:	f822                	sd	s0,48(sp)
    80004408:	f426                	sd	s1,40(sp)
    8000440a:	f04a                	sd	s2,32(sp)
    8000440c:	ec4e                	sd	s3,24(sp)
    8000440e:	e852                	sd	s4,16(sp)
    80004410:	e456                	sd	s5,8(sp)
    80004412:	e05a                	sd	s6,0(sp)
    80004414:	0080                	addi	s0,sp,64
    80004416:	8b2a                	mv	s6,a0
    80004418:	0001da97          	auipc	s5,0x1d
    8000441c:	7d0a8a93          	addi	s5,s5,2000 # 80021be8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004420:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004422:	0001d997          	auipc	s3,0x1d
    80004426:	79698993          	addi	s3,s3,1942 # 80021bb8 <log>
    8000442a:	a035                	j	80004456 <install_trans+0x60>
      bunpin(dbuf);
    8000442c:	8526                	mv	a0,s1
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	166080e7          	jalr	358(ra) # 80003594 <bunpin>
    brelse(lbuf);
    80004436:	854a                	mv	a0,s2
    80004438:	fffff097          	auipc	ra,0xfffff
    8000443c:	082080e7          	jalr	130(ra) # 800034ba <brelse>
    brelse(dbuf);
    80004440:	8526                	mv	a0,s1
    80004442:	fffff097          	auipc	ra,0xfffff
    80004446:	078080e7          	jalr	120(ra) # 800034ba <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444a:	2a05                	addiw	s4,s4,1
    8000444c:	0a91                	addi	s5,s5,4
    8000444e:	02c9a783          	lw	a5,44(s3)
    80004452:	04fa5963          	bge	s4,a5,800044a4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004456:	0189a583          	lw	a1,24(s3)
    8000445a:	014585bb          	addw	a1,a1,s4
    8000445e:	2585                	addiw	a1,a1,1
    80004460:	0289a503          	lw	a0,40(s3)
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	f26080e7          	jalr	-218(ra) # 8000338a <bread>
    8000446c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000446e:	000aa583          	lw	a1,0(s5)
    80004472:	0289a503          	lw	a0,40(s3)
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	f14080e7          	jalr	-236(ra) # 8000338a <bread>
    8000447e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004480:	40000613          	li	a2,1024
    80004484:	05890593          	addi	a1,s2,88
    80004488:	05850513          	addi	a0,a0,88
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	8b4080e7          	jalr	-1868(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004494:	8526                	mv	a0,s1
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	fe6080e7          	jalr	-26(ra) # 8000347c <bwrite>
    if(recovering == 0)
    8000449e:	f80b1ce3          	bnez	s6,80004436 <install_trans+0x40>
    800044a2:	b769                	j	8000442c <install_trans+0x36>
}
    800044a4:	70e2                	ld	ra,56(sp)
    800044a6:	7442                	ld	s0,48(sp)
    800044a8:	74a2                	ld	s1,40(sp)
    800044aa:	7902                	ld	s2,32(sp)
    800044ac:	69e2                	ld	s3,24(sp)
    800044ae:	6a42                	ld	s4,16(sp)
    800044b0:	6aa2                	ld	s5,8(sp)
    800044b2:	6b02                	ld	s6,0(sp)
    800044b4:	6121                	addi	sp,sp,64
    800044b6:	8082                	ret
    800044b8:	8082                	ret

00000000800044ba <initlog>:
{
    800044ba:	7179                	addi	sp,sp,-48
    800044bc:	f406                	sd	ra,40(sp)
    800044be:	f022                	sd	s0,32(sp)
    800044c0:	ec26                	sd	s1,24(sp)
    800044c2:	e84a                	sd	s2,16(sp)
    800044c4:	e44e                	sd	s3,8(sp)
    800044c6:	1800                	addi	s0,sp,48
    800044c8:	892a                	mv	s2,a0
    800044ca:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044cc:	0001d497          	auipc	s1,0x1d
    800044d0:	6ec48493          	addi	s1,s1,1772 # 80021bb8 <log>
    800044d4:	00004597          	auipc	a1,0x4
    800044d8:	16c58593          	addi	a1,a1,364 # 80008640 <syscalls+0x1e8>
    800044dc:	8526                	mv	a0,s1
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	676080e7          	jalr	1654(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044e6:	0149a583          	lw	a1,20(s3)
    800044ea:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044ec:	0109a783          	lw	a5,16(s3)
    800044f0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044f2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044f6:	854a                	mv	a0,s2
    800044f8:	fffff097          	auipc	ra,0xfffff
    800044fc:	e92080e7          	jalr	-366(ra) # 8000338a <bread>
  log.lh.n = lh->n;
    80004500:	4d3c                	lw	a5,88(a0)
    80004502:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004504:	02f05563          	blez	a5,8000452e <initlog+0x74>
    80004508:	05c50713          	addi	a4,a0,92
    8000450c:	0001d697          	auipc	a3,0x1d
    80004510:	6dc68693          	addi	a3,a3,1756 # 80021be8 <log+0x30>
    80004514:	37fd                	addiw	a5,a5,-1
    80004516:	1782                	slli	a5,a5,0x20
    80004518:	9381                	srli	a5,a5,0x20
    8000451a:	078a                	slli	a5,a5,0x2
    8000451c:	06050613          	addi	a2,a0,96
    80004520:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004522:	4310                	lw	a2,0(a4)
    80004524:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004526:	0711                	addi	a4,a4,4
    80004528:	0691                	addi	a3,a3,4
    8000452a:	fef71ce3          	bne	a4,a5,80004522 <initlog+0x68>
  brelse(buf);
    8000452e:	fffff097          	auipc	ra,0xfffff
    80004532:	f8c080e7          	jalr	-116(ra) # 800034ba <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004536:	4505                	li	a0,1
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	ebe080e7          	jalr	-322(ra) # 800043f6 <install_trans>
  log.lh.n = 0;
    80004540:	0001d797          	auipc	a5,0x1d
    80004544:	6a07a223          	sw	zero,1700(a5) # 80021be4 <log+0x2c>
  write_head(); // clear the log
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	e34080e7          	jalr	-460(ra) # 8000437c <write_head>
}
    80004550:	70a2                	ld	ra,40(sp)
    80004552:	7402                	ld	s0,32(sp)
    80004554:	64e2                	ld	s1,24(sp)
    80004556:	6942                	ld	s2,16(sp)
    80004558:	69a2                	ld	s3,8(sp)
    8000455a:	6145                	addi	sp,sp,48
    8000455c:	8082                	ret

000000008000455e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000455e:	1101                	addi	sp,sp,-32
    80004560:	ec06                	sd	ra,24(sp)
    80004562:	e822                	sd	s0,16(sp)
    80004564:	e426                	sd	s1,8(sp)
    80004566:	e04a                	sd	s2,0(sp)
    80004568:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000456a:	0001d517          	auipc	a0,0x1d
    8000456e:	64e50513          	addi	a0,a0,1614 # 80021bb8 <log>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	672080e7          	jalr	1650(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000457a:	0001d497          	auipc	s1,0x1d
    8000457e:	63e48493          	addi	s1,s1,1598 # 80021bb8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004582:	4979                	li	s2,30
    80004584:	a039                	j	80004592 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004586:	85a6                	mv	a1,s1
    80004588:	8526                	mv	a0,s1
    8000458a:	ffffe097          	auipc	ra,0xffffe
    8000458e:	b30080e7          	jalr	-1232(ra) # 800020ba <sleep>
    if(log.committing){
    80004592:	50dc                	lw	a5,36(s1)
    80004594:	fbed                	bnez	a5,80004586 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004596:	509c                	lw	a5,32(s1)
    80004598:	0017871b          	addiw	a4,a5,1
    8000459c:	0007069b          	sext.w	a3,a4
    800045a0:	0027179b          	slliw	a5,a4,0x2
    800045a4:	9fb9                	addw	a5,a5,a4
    800045a6:	0017979b          	slliw	a5,a5,0x1
    800045aa:	54d8                	lw	a4,44(s1)
    800045ac:	9fb9                	addw	a5,a5,a4
    800045ae:	00f95963          	bge	s2,a5,800045c0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045b2:	85a6                	mv	a1,s1
    800045b4:	8526                	mv	a0,s1
    800045b6:	ffffe097          	auipc	ra,0xffffe
    800045ba:	b04080e7          	jalr	-1276(ra) # 800020ba <sleep>
    800045be:	bfd1                	j	80004592 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045c0:	0001d517          	auipc	a0,0x1d
    800045c4:	5f850513          	addi	a0,a0,1528 # 80021bb8 <log>
    800045c8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	6ce080e7          	jalr	1742(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045d2:	60e2                	ld	ra,24(sp)
    800045d4:	6442                	ld	s0,16(sp)
    800045d6:	64a2                	ld	s1,8(sp)
    800045d8:	6902                	ld	s2,0(sp)
    800045da:	6105                	addi	sp,sp,32
    800045dc:	8082                	ret

00000000800045de <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045de:	7139                	addi	sp,sp,-64
    800045e0:	fc06                	sd	ra,56(sp)
    800045e2:	f822                	sd	s0,48(sp)
    800045e4:	f426                	sd	s1,40(sp)
    800045e6:	f04a                	sd	s2,32(sp)
    800045e8:	ec4e                	sd	s3,24(sp)
    800045ea:	e852                	sd	s4,16(sp)
    800045ec:	e456                	sd	s5,8(sp)
    800045ee:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045f0:	0001d497          	auipc	s1,0x1d
    800045f4:	5c848493          	addi	s1,s1,1480 # 80021bb8 <log>
    800045f8:	8526                	mv	a0,s1
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	5ea080e7          	jalr	1514(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004602:	509c                	lw	a5,32(s1)
    80004604:	37fd                	addiw	a5,a5,-1
    80004606:	0007891b          	sext.w	s2,a5
    8000460a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000460c:	50dc                	lw	a5,36(s1)
    8000460e:	efb9                	bnez	a5,8000466c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004610:	06091663          	bnez	s2,8000467c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004614:	0001d497          	auipc	s1,0x1d
    80004618:	5a448493          	addi	s1,s1,1444 # 80021bb8 <log>
    8000461c:	4785                	li	a5,1
    8000461e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004620:	8526                	mv	a0,s1
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	676080e7          	jalr	1654(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000462a:	54dc                	lw	a5,44(s1)
    8000462c:	06f04763          	bgtz	a5,8000469a <end_op+0xbc>
    acquire(&log.lock);
    80004630:	0001d497          	auipc	s1,0x1d
    80004634:	58848493          	addi	s1,s1,1416 # 80021bb8 <log>
    80004638:	8526                	mv	a0,s1
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	5aa080e7          	jalr	1450(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004642:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004646:	8526                	mv	a0,s1
    80004648:	ffffe097          	auipc	ra,0xffffe
    8000464c:	de4080e7          	jalr	-540(ra) # 8000242c <wakeup>
    release(&log.lock);
    80004650:	8526                	mv	a0,s1
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	646080e7          	jalr	1606(ra) # 80000c98 <release>
}
    8000465a:	70e2                	ld	ra,56(sp)
    8000465c:	7442                	ld	s0,48(sp)
    8000465e:	74a2                	ld	s1,40(sp)
    80004660:	7902                	ld	s2,32(sp)
    80004662:	69e2                	ld	s3,24(sp)
    80004664:	6a42                	ld	s4,16(sp)
    80004666:	6aa2                	ld	s5,8(sp)
    80004668:	6121                	addi	sp,sp,64
    8000466a:	8082                	ret
    panic("log.committing");
    8000466c:	00004517          	auipc	a0,0x4
    80004670:	fdc50513          	addi	a0,a0,-36 # 80008648 <syscalls+0x1f0>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	eca080e7          	jalr	-310(ra) # 8000053e <panic>
    wakeup(&log);
    8000467c:	0001d497          	auipc	s1,0x1d
    80004680:	53c48493          	addi	s1,s1,1340 # 80021bb8 <log>
    80004684:	8526                	mv	a0,s1
    80004686:	ffffe097          	auipc	ra,0xffffe
    8000468a:	da6080e7          	jalr	-602(ra) # 8000242c <wakeup>
  release(&log.lock);
    8000468e:	8526                	mv	a0,s1
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	608080e7          	jalr	1544(ra) # 80000c98 <release>
  if(do_commit){
    80004698:	b7c9                	j	8000465a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000469a:	0001da97          	auipc	s5,0x1d
    8000469e:	54ea8a93          	addi	s5,s5,1358 # 80021be8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046a2:	0001da17          	auipc	s4,0x1d
    800046a6:	516a0a13          	addi	s4,s4,1302 # 80021bb8 <log>
    800046aa:	018a2583          	lw	a1,24(s4)
    800046ae:	012585bb          	addw	a1,a1,s2
    800046b2:	2585                	addiw	a1,a1,1
    800046b4:	028a2503          	lw	a0,40(s4)
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	cd2080e7          	jalr	-814(ra) # 8000338a <bread>
    800046c0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046c2:	000aa583          	lw	a1,0(s5)
    800046c6:	028a2503          	lw	a0,40(s4)
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	cc0080e7          	jalr	-832(ra) # 8000338a <bread>
    800046d2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046d4:	40000613          	li	a2,1024
    800046d8:	05850593          	addi	a1,a0,88
    800046dc:	05848513          	addi	a0,s1,88
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	660080e7          	jalr	1632(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046e8:	8526                	mv	a0,s1
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	d92080e7          	jalr	-622(ra) # 8000347c <bwrite>
    brelse(from);
    800046f2:	854e                	mv	a0,s3
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	dc6080e7          	jalr	-570(ra) # 800034ba <brelse>
    brelse(to);
    800046fc:	8526                	mv	a0,s1
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	dbc080e7          	jalr	-580(ra) # 800034ba <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004706:	2905                	addiw	s2,s2,1
    80004708:	0a91                	addi	s5,s5,4
    8000470a:	02ca2783          	lw	a5,44(s4)
    8000470e:	f8f94ee3          	blt	s2,a5,800046aa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004712:	00000097          	auipc	ra,0x0
    80004716:	c6a080e7          	jalr	-918(ra) # 8000437c <write_head>
    install_trans(0); // Now install writes to home locations
    8000471a:	4501                	li	a0,0
    8000471c:	00000097          	auipc	ra,0x0
    80004720:	cda080e7          	jalr	-806(ra) # 800043f6 <install_trans>
    log.lh.n = 0;
    80004724:	0001d797          	auipc	a5,0x1d
    80004728:	4c07a023          	sw	zero,1216(a5) # 80021be4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	c50080e7          	jalr	-944(ra) # 8000437c <write_head>
    80004734:	bdf5                	j	80004630 <end_op+0x52>

0000000080004736 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004736:	1101                	addi	sp,sp,-32
    80004738:	ec06                	sd	ra,24(sp)
    8000473a:	e822                	sd	s0,16(sp)
    8000473c:	e426                	sd	s1,8(sp)
    8000473e:	e04a                	sd	s2,0(sp)
    80004740:	1000                	addi	s0,sp,32
    80004742:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004744:	0001d917          	auipc	s2,0x1d
    80004748:	47490913          	addi	s2,s2,1140 # 80021bb8 <log>
    8000474c:	854a                	mv	a0,s2
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	496080e7          	jalr	1174(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004756:	02c92603          	lw	a2,44(s2)
    8000475a:	47f5                	li	a5,29
    8000475c:	06c7c563          	blt	a5,a2,800047c6 <log_write+0x90>
    80004760:	0001d797          	auipc	a5,0x1d
    80004764:	4747a783          	lw	a5,1140(a5) # 80021bd4 <log+0x1c>
    80004768:	37fd                	addiw	a5,a5,-1
    8000476a:	04f65e63          	bge	a2,a5,800047c6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000476e:	0001d797          	auipc	a5,0x1d
    80004772:	46a7a783          	lw	a5,1130(a5) # 80021bd8 <log+0x20>
    80004776:	06f05063          	blez	a5,800047d6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000477a:	4781                	li	a5,0
    8000477c:	06c05563          	blez	a2,800047e6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004780:	44cc                	lw	a1,12(s1)
    80004782:	0001d717          	auipc	a4,0x1d
    80004786:	46670713          	addi	a4,a4,1126 # 80021be8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000478a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000478c:	4314                	lw	a3,0(a4)
    8000478e:	04b68c63          	beq	a3,a1,800047e6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004792:	2785                	addiw	a5,a5,1
    80004794:	0711                	addi	a4,a4,4
    80004796:	fef61be3          	bne	a2,a5,8000478c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000479a:	0621                	addi	a2,a2,8
    8000479c:	060a                	slli	a2,a2,0x2
    8000479e:	0001d797          	auipc	a5,0x1d
    800047a2:	41a78793          	addi	a5,a5,1050 # 80021bb8 <log>
    800047a6:	963e                	add	a2,a2,a5
    800047a8:	44dc                	lw	a5,12(s1)
    800047aa:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047ac:	8526                	mv	a0,s1
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	daa080e7          	jalr	-598(ra) # 80003558 <bpin>
    log.lh.n++;
    800047b6:	0001d717          	auipc	a4,0x1d
    800047ba:	40270713          	addi	a4,a4,1026 # 80021bb8 <log>
    800047be:	575c                	lw	a5,44(a4)
    800047c0:	2785                	addiw	a5,a5,1
    800047c2:	d75c                	sw	a5,44(a4)
    800047c4:	a835                	j	80004800 <log_write+0xca>
    panic("too big a transaction");
    800047c6:	00004517          	auipc	a0,0x4
    800047ca:	e9250513          	addi	a0,a0,-366 # 80008658 <syscalls+0x200>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	d70080e7          	jalr	-656(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047d6:	00004517          	auipc	a0,0x4
    800047da:	e9a50513          	addi	a0,a0,-358 # 80008670 <syscalls+0x218>
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	d60080e7          	jalr	-672(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047e6:	00878713          	addi	a4,a5,8
    800047ea:	00271693          	slli	a3,a4,0x2
    800047ee:	0001d717          	auipc	a4,0x1d
    800047f2:	3ca70713          	addi	a4,a4,970 # 80021bb8 <log>
    800047f6:	9736                	add	a4,a4,a3
    800047f8:	44d4                	lw	a3,12(s1)
    800047fa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047fc:	faf608e3          	beq	a2,a5,800047ac <log_write+0x76>
  }
  release(&log.lock);
    80004800:	0001d517          	auipc	a0,0x1d
    80004804:	3b850513          	addi	a0,a0,952 # 80021bb8 <log>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	490080e7          	jalr	1168(ra) # 80000c98 <release>
}
    80004810:	60e2                	ld	ra,24(sp)
    80004812:	6442                	ld	s0,16(sp)
    80004814:	64a2                	ld	s1,8(sp)
    80004816:	6902                	ld	s2,0(sp)
    80004818:	6105                	addi	sp,sp,32
    8000481a:	8082                	ret

000000008000481c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000481c:	1101                	addi	sp,sp,-32
    8000481e:	ec06                	sd	ra,24(sp)
    80004820:	e822                	sd	s0,16(sp)
    80004822:	e426                	sd	s1,8(sp)
    80004824:	e04a                	sd	s2,0(sp)
    80004826:	1000                	addi	s0,sp,32
    80004828:	84aa                	mv	s1,a0
    8000482a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000482c:	00004597          	auipc	a1,0x4
    80004830:	e6458593          	addi	a1,a1,-412 # 80008690 <syscalls+0x238>
    80004834:	0521                	addi	a0,a0,8
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	31e080e7          	jalr	798(ra) # 80000b54 <initlock>
  lk->name = name;
    8000483e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004842:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004846:	0204a423          	sw	zero,40(s1)
}
    8000484a:	60e2                	ld	ra,24(sp)
    8000484c:	6442                	ld	s0,16(sp)
    8000484e:	64a2                	ld	s1,8(sp)
    80004850:	6902                	ld	s2,0(sp)
    80004852:	6105                	addi	sp,sp,32
    80004854:	8082                	ret

0000000080004856 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004856:	1101                	addi	sp,sp,-32
    80004858:	ec06                	sd	ra,24(sp)
    8000485a:	e822                	sd	s0,16(sp)
    8000485c:	e426                	sd	s1,8(sp)
    8000485e:	e04a                	sd	s2,0(sp)
    80004860:	1000                	addi	s0,sp,32
    80004862:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004864:	00850913          	addi	s2,a0,8
    80004868:	854a                	mv	a0,s2
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	37a080e7          	jalr	890(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004872:	409c                	lw	a5,0(s1)
    80004874:	cb89                	beqz	a5,80004886 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004876:	85ca                	mv	a1,s2
    80004878:	8526                	mv	a0,s1
    8000487a:	ffffe097          	auipc	ra,0xffffe
    8000487e:	840080e7          	jalr	-1984(ra) # 800020ba <sleep>
  while (lk->locked) {
    80004882:	409c                	lw	a5,0(s1)
    80004884:	fbed                	bnez	a5,80004876 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004886:	4785                	li	a5,1
    80004888:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000488a:	ffffd097          	auipc	ra,0xffffd
    8000488e:	07e080e7          	jalr	126(ra) # 80001908 <myproc>
    80004892:	591c                	lw	a5,48(a0)
    80004894:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004896:	854a                	mv	a0,s2
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	400080e7          	jalr	1024(ra) # 80000c98 <release>
}
    800048a0:	60e2                	ld	ra,24(sp)
    800048a2:	6442                	ld	s0,16(sp)
    800048a4:	64a2                	ld	s1,8(sp)
    800048a6:	6902                	ld	s2,0(sp)
    800048a8:	6105                	addi	sp,sp,32
    800048aa:	8082                	ret

00000000800048ac <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048ac:	1101                	addi	sp,sp,-32
    800048ae:	ec06                	sd	ra,24(sp)
    800048b0:	e822                	sd	s0,16(sp)
    800048b2:	e426                	sd	s1,8(sp)
    800048b4:	e04a                	sd	s2,0(sp)
    800048b6:	1000                	addi	s0,sp,32
    800048b8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ba:	00850913          	addi	s2,a0,8
    800048be:	854a                	mv	a0,s2
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	324080e7          	jalr	804(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048c8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048cc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048d0:	8526                	mv	a0,s1
    800048d2:	ffffe097          	auipc	ra,0xffffe
    800048d6:	b5a080e7          	jalr	-1190(ra) # 8000242c <wakeup>
  release(&lk->lk);
    800048da:	854a                	mv	a0,s2
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	3bc080e7          	jalr	956(ra) # 80000c98 <release>
}
    800048e4:	60e2                	ld	ra,24(sp)
    800048e6:	6442                	ld	s0,16(sp)
    800048e8:	64a2                	ld	s1,8(sp)
    800048ea:	6902                	ld	s2,0(sp)
    800048ec:	6105                	addi	sp,sp,32
    800048ee:	8082                	ret

00000000800048f0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048f0:	7179                	addi	sp,sp,-48
    800048f2:	f406                	sd	ra,40(sp)
    800048f4:	f022                	sd	s0,32(sp)
    800048f6:	ec26                	sd	s1,24(sp)
    800048f8:	e84a                	sd	s2,16(sp)
    800048fa:	e44e                	sd	s3,8(sp)
    800048fc:	1800                	addi	s0,sp,48
    800048fe:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004900:	00850913          	addi	s2,a0,8
    80004904:	854a                	mv	a0,s2
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	2de080e7          	jalr	734(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000490e:	409c                	lw	a5,0(s1)
    80004910:	ef99                	bnez	a5,8000492e <holdingsleep+0x3e>
    80004912:	4481                	li	s1,0
  release(&lk->lk);
    80004914:	854a                	mv	a0,s2
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	382080e7          	jalr	898(ra) # 80000c98 <release>
  return r;
}
    8000491e:	8526                	mv	a0,s1
    80004920:	70a2                	ld	ra,40(sp)
    80004922:	7402                	ld	s0,32(sp)
    80004924:	64e2                	ld	s1,24(sp)
    80004926:	6942                	ld	s2,16(sp)
    80004928:	69a2                	ld	s3,8(sp)
    8000492a:	6145                	addi	sp,sp,48
    8000492c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000492e:	0284a983          	lw	s3,40(s1)
    80004932:	ffffd097          	auipc	ra,0xffffd
    80004936:	fd6080e7          	jalr	-42(ra) # 80001908 <myproc>
    8000493a:	5904                	lw	s1,48(a0)
    8000493c:	413484b3          	sub	s1,s1,s3
    80004940:	0014b493          	seqz	s1,s1
    80004944:	bfc1                	j	80004914 <holdingsleep+0x24>

0000000080004946 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004946:	1141                	addi	sp,sp,-16
    80004948:	e406                	sd	ra,8(sp)
    8000494a:	e022                	sd	s0,0(sp)
    8000494c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000494e:	00004597          	auipc	a1,0x4
    80004952:	d5258593          	addi	a1,a1,-686 # 800086a0 <syscalls+0x248>
    80004956:	0001d517          	auipc	a0,0x1d
    8000495a:	3aa50513          	addi	a0,a0,938 # 80021d00 <ftable>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	1f6080e7          	jalr	502(ra) # 80000b54 <initlock>
}
    80004966:	60a2                	ld	ra,8(sp)
    80004968:	6402                	ld	s0,0(sp)
    8000496a:	0141                	addi	sp,sp,16
    8000496c:	8082                	ret

000000008000496e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000496e:	1101                	addi	sp,sp,-32
    80004970:	ec06                	sd	ra,24(sp)
    80004972:	e822                	sd	s0,16(sp)
    80004974:	e426                	sd	s1,8(sp)
    80004976:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004978:	0001d517          	auipc	a0,0x1d
    8000497c:	38850513          	addi	a0,a0,904 # 80021d00 <ftable>
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	264080e7          	jalr	612(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004988:	0001d497          	auipc	s1,0x1d
    8000498c:	39048493          	addi	s1,s1,912 # 80021d18 <ftable+0x18>
    80004990:	0001e717          	auipc	a4,0x1e
    80004994:	32870713          	addi	a4,a4,808 # 80022cb8 <ftable+0xfb8>
    if(f->ref == 0){
    80004998:	40dc                	lw	a5,4(s1)
    8000499a:	cf99                	beqz	a5,800049b8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000499c:	02848493          	addi	s1,s1,40
    800049a0:	fee49ce3          	bne	s1,a4,80004998 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049a4:	0001d517          	auipc	a0,0x1d
    800049a8:	35c50513          	addi	a0,a0,860 # 80021d00 <ftable>
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	2ec080e7          	jalr	748(ra) # 80000c98 <release>
  return 0;
    800049b4:	4481                	li	s1,0
    800049b6:	a819                	j	800049cc <filealloc+0x5e>
      f->ref = 1;
    800049b8:	4785                	li	a5,1
    800049ba:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049bc:	0001d517          	auipc	a0,0x1d
    800049c0:	34450513          	addi	a0,a0,836 # 80021d00 <ftable>
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	2d4080e7          	jalr	724(ra) # 80000c98 <release>
}
    800049cc:	8526                	mv	a0,s1
    800049ce:	60e2                	ld	ra,24(sp)
    800049d0:	6442                	ld	s0,16(sp)
    800049d2:	64a2                	ld	s1,8(sp)
    800049d4:	6105                	addi	sp,sp,32
    800049d6:	8082                	ret

00000000800049d8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049d8:	1101                	addi	sp,sp,-32
    800049da:	ec06                	sd	ra,24(sp)
    800049dc:	e822                	sd	s0,16(sp)
    800049de:	e426                	sd	s1,8(sp)
    800049e0:	1000                	addi	s0,sp,32
    800049e2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049e4:	0001d517          	auipc	a0,0x1d
    800049e8:	31c50513          	addi	a0,a0,796 # 80021d00 <ftable>
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	1f8080e7          	jalr	504(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049f4:	40dc                	lw	a5,4(s1)
    800049f6:	02f05263          	blez	a5,80004a1a <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049fa:	2785                	addiw	a5,a5,1
    800049fc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049fe:	0001d517          	auipc	a0,0x1d
    80004a02:	30250513          	addi	a0,a0,770 # 80021d00 <ftable>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	292080e7          	jalr	658(ra) # 80000c98 <release>
  return f;
}
    80004a0e:	8526                	mv	a0,s1
    80004a10:	60e2                	ld	ra,24(sp)
    80004a12:	6442                	ld	s0,16(sp)
    80004a14:	64a2                	ld	s1,8(sp)
    80004a16:	6105                	addi	sp,sp,32
    80004a18:	8082                	ret
    panic("filedup");
    80004a1a:	00004517          	auipc	a0,0x4
    80004a1e:	c8e50513          	addi	a0,a0,-882 # 800086a8 <syscalls+0x250>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	b1c080e7          	jalr	-1252(ra) # 8000053e <panic>

0000000080004a2a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a2a:	7139                	addi	sp,sp,-64
    80004a2c:	fc06                	sd	ra,56(sp)
    80004a2e:	f822                	sd	s0,48(sp)
    80004a30:	f426                	sd	s1,40(sp)
    80004a32:	f04a                	sd	s2,32(sp)
    80004a34:	ec4e                	sd	s3,24(sp)
    80004a36:	e852                	sd	s4,16(sp)
    80004a38:	e456                	sd	s5,8(sp)
    80004a3a:	0080                	addi	s0,sp,64
    80004a3c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a3e:	0001d517          	auipc	a0,0x1d
    80004a42:	2c250513          	addi	a0,a0,706 # 80021d00 <ftable>
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	19e080e7          	jalr	414(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a4e:	40dc                	lw	a5,4(s1)
    80004a50:	06f05163          	blez	a5,80004ab2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a54:	37fd                	addiw	a5,a5,-1
    80004a56:	0007871b          	sext.w	a4,a5
    80004a5a:	c0dc                	sw	a5,4(s1)
    80004a5c:	06e04363          	bgtz	a4,80004ac2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a60:	0004a903          	lw	s2,0(s1)
    80004a64:	0094ca83          	lbu	s5,9(s1)
    80004a68:	0104ba03          	ld	s4,16(s1)
    80004a6c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a70:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a74:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a78:	0001d517          	auipc	a0,0x1d
    80004a7c:	28850513          	addi	a0,a0,648 # 80021d00 <ftable>
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	218080e7          	jalr	536(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a88:	4785                	li	a5,1
    80004a8a:	04f90d63          	beq	s2,a5,80004ae4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a8e:	3979                	addiw	s2,s2,-2
    80004a90:	4785                	li	a5,1
    80004a92:	0527e063          	bltu	a5,s2,80004ad2 <fileclose+0xa8>
    begin_op();
    80004a96:	00000097          	auipc	ra,0x0
    80004a9a:	ac8080e7          	jalr	-1336(ra) # 8000455e <begin_op>
    iput(ff.ip);
    80004a9e:	854e                	mv	a0,s3
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	2a6080e7          	jalr	678(ra) # 80003d46 <iput>
    end_op();
    80004aa8:	00000097          	auipc	ra,0x0
    80004aac:	b36080e7          	jalr	-1226(ra) # 800045de <end_op>
    80004ab0:	a00d                	j	80004ad2 <fileclose+0xa8>
    panic("fileclose");
    80004ab2:	00004517          	auipc	a0,0x4
    80004ab6:	bfe50513          	addi	a0,a0,-1026 # 800086b0 <syscalls+0x258>
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	a84080e7          	jalr	-1404(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004ac2:	0001d517          	auipc	a0,0x1d
    80004ac6:	23e50513          	addi	a0,a0,574 # 80021d00 <ftable>
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1ce080e7          	jalr	462(ra) # 80000c98 <release>
  }
}
    80004ad2:	70e2                	ld	ra,56(sp)
    80004ad4:	7442                	ld	s0,48(sp)
    80004ad6:	74a2                	ld	s1,40(sp)
    80004ad8:	7902                	ld	s2,32(sp)
    80004ada:	69e2                	ld	s3,24(sp)
    80004adc:	6a42                	ld	s4,16(sp)
    80004ade:	6aa2                	ld	s5,8(sp)
    80004ae0:	6121                	addi	sp,sp,64
    80004ae2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ae4:	85d6                	mv	a1,s5
    80004ae6:	8552                	mv	a0,s4
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	34c080e7          	jalr	844(ra) # 80004e34 <pipeclose>
    80004af0:	b7cd                	j	80004ad2 <fileclose+0xa8>

0000000080004af2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004af2:	715d                	addi	sp,sp,-80
    80004af4:	e486                	sd	ra,72(sp)
    80004af6:	e0a2                	sd	s0,64(sp)
    80004af8:	fc26                	sd	s1,56(sp)
    80004afa:	f84a                	sd	s2,48(sp)
    80004afc:	f44e                	sd	s3,40(sp)
    80004afe:	0880                	addi	s0,sp,80
    80004b00:	84aa                	mv	s1,a0
    80004b02:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b04:	ffffd097          	auipc	ra,0xffffd
    80004b08:	e04080e7          	jalr	-508(ra) # 80001908 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b0c:	409c                	lw	a5,0(s1)
    80004b0e:	37f9                	addiw	a5,a5,-2
    80004b10:	4705                	li	a4,1
    80004b12:	04f76763          	bltu	a4,a5,80004b60 <filestat+0x6e>
    80004b16:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b18:	6c88                	ld	a0,24(s1)
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	072080e7          	jalr	114(ra) # 80003b8c <ilock>
    stati(f->ip, &st);
    80004b22:	fb840593          	addi	a1,s0,-72
    80004b26:	6c88                	ld	a0,24(s1)
    80004b28:	fffff097          	auipc	ra,0xfffff
    80004b2c:	2ee080e7          	jalr	750(ra) # 80003e16 <stati>
    iunlock(f->ip);
    80004b30:	6c88                	ld	a0,24(s1)
    80004b32:	fffff097          	auipc	ra,0xfffff
    80004b36:	11c080e7          	jalr	284(ra) # 80003c4e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b3a:	46e1                	li	a3,24
    80004b3c:	fb840613          	addi	a2,s0,-72
    80004b40:	85ce                	mv	a1,s3
    80004b42:	07093503          	ld	a0,112(s2)
    80004b46:	ffffd097          	auipc	ra,0xffffd
    80004b4a:	b2c080e7          	jalr	-1236(ra) # 80001672 <copyout>
    80004b4e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b52:	60a6                	ld	ra,72(sp)
    80004b54:	6406                	ld	s0,64(sp)
    80004b56:	74e2                	ld	s1,56(sp)
    80004b58:	7942                	ld	s2,48(sp)
    80004b5a:	79a2                	ld	s3,40(sp)
    80004b5c:	6161                	addi	sp,sp,80
    80004b5e:	8082                	ret
  return -1;
    80004b60:	557d                	li	a0,-1
    80004b62:	bfc5                	j	80004b52 <filestat+0x60>

0000000080004b64 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b64:	7179                	addi	sp,sp,-48
    80004b66:	f406                	sd	ra,40(sp)
    80004b68:	f022                	sd	s0,32(sp)
    80004b6a:	ec26                	sd	s1,24(sp)
    80004b6c:	e84a                	sd	s2,16(sp)
    80004b6e:	e44e                	sd	s3,8(sp)
    80004b70:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b72:	00854783          	lbu	a5,8(a0)
    80004b76:	c3d5                	beqz	a5,80004c1a <fileread+0xb6>
    80004b78:	84aa                	mv	s1,a0
    80004b7a:	89ae                	mv	s3,a1
    80004b7c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b7e:	411c                	lw	a5,0(a0)
    80004b80:	4705                	li	a4,1
    80004b82:	04e78963          	beq	a5,a4,80004bd4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b86:	470d                	li	a4,3
    80004b88:	04e78d63          	beq	a5,a4,80004be2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b8c:	4709                	li	a4,2
    80004b8e:	06e79e63          	bne	a5,a4,80004c0a <fileread+0xa6>
    ilock(f->ip);
    80004b92:	6d08                	ld	a0,24(a0)
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	ff8080e7          	jalr	-8(ra) # 80003b8c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b9c:	874a                	mv	a4,s2
    80004b9e:	5094                	lw	a3,32(s1)
    80004ba0:	864e                	mv	a2,s3
    80004ba2:	4585                	li	a1,1
    80004ba4:	6c88                	ld	a0,24(s1)
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	29a080e7          	jalr	666(ra) # 80003e40 <readi>
    80004bae:	892a                	mv	s2,a0
    80004bb0:	00a05563          	blez	a0,80004bba <fileread+0x56>
      f->off += r;
    80004bb4:	509c                	lw	a5,32(s1)
    80004bb6:	9fa9                	addw	a5,a5,a0
    80004bb8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bba:	6c88                	ld	a0,24(s1)
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	092080e7          	jalr	146(ra) # 80003c4e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bc4:	854a                	mv	a0,s2
    80004bc6:	70a2                	ld	ra,40(sp)
    80004bc8:	7402                	ld	s0,32(sp)
    80004bca:	64e2                	ld	s1,24(sp)
    80004bcc:	6942                	ld	s2,16(sp)
    80004bce:	69a2                	ld	s3,8(sp)
    80004bd0:	6145                	addi	sp,sp,48
    80004bd2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bd4:	6908                	ld	a0,16(a0)
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	3c8080e7          	jalr	968(ra) # 80004f9e <piperead>
    80004bde:	892a                	mv	s2,a0
    80004be0:	b7d5                	j	80004bc4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004be2:	02451783          	lh	a5,36(a0)
    80004be6:	03079693          	slli	a3,a5,0x30
    80004bea:	92c1                	srli	a3,a3,0x30
    80004bec:	4725                	li	a4,9
    80004bee:	02d76863          	bltu	a4,a3,80004c1e <fileread+0xba>
    80004bf2:	0792                	slli	a5,a5,0x4
    80004bf4:	0001d717          	auipc	a4,0x1d
    80004bf8:	06c70713          	addi	a4,a4,108 # 80021c60 <devsw>
    80004bfc:	97ba                	add	a5,a5,a4
    80004bfe:	639c                	ld	a5,0(a5)
    80004c00:	c38d                	beqz	a5,80004c22 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c02:	4505                	li	a0,1
    80004c04:	9782                	jalr	a5
    80004c06:	892a                	mv	s2,a0
    80004c08:	bf75                	j	80004bc4 <fileread+0x60>
    panic("fileread");
    80004c0a:	00004517          	auipc	a0,0x4
    80004c0e:	ab650513          	addi	a0,a0,-1354 # 800086c0 <syscalls+0x268>
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	92c080e7          	jalr	-1748(ra) # 8000053e <panic>
    return -1;
    80004c1a:	597d                	li	s2,-1
    80004c1c:	b765                	j	80004bc4 <fileread+0x60>
      return -1;
    80004c1e:	597d                	li	s2,-1
    80004c20:	b755                	j	80004bc4 <fileread+0x60>
    80004c22:	597d                	li	s2,-1
    80004c24:	b745                	j	80004bc4 <fileread+0x60>

0000000080004c26 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c26:	715d                	addi	sp,sp,-80
    80004c28:	e486                	sd	ra,72(sp)
    80004c2a:	e0a2                	sd	s0,64(sp)
    80004c2c:	fc26                	sd	s1,56(sp)
    80004c2e:	f84a                	sd	s2,48(sp)
    80004c30:	f44e                	sd	s3,40(sp)
    80004c32:	f052                	sd	s4,32(sp)
    80004c34:	ec56                	sd	s5,24(sp)
    80004c36:	e85a                	sd	s6,16(sp)
    80004c38:	e45e                	sd	s7,8(sp)
    80004c3a:	e062                	sd	s8,0(sp)
    80004c3c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c3e:	00954783          	lbu	a5,9(a0)
    80004c42:	10078663          	beqz	a5,80004d4e <filewrite+0x128>
    80004c46:	892a                	mv	s2,a0
    80004c48:	8aae                	mv	s5,a1
    80004c4a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c4c:	411c                	lw	a5,0(a0)
    80004c4e:	4705                	li	a4,1
    80004c50:	02e78263          	beq	a5,a4,80004c74 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c54:	470d                	li	a4,3
    80004c56:	02e78663          	beq	a5,a4,80004c82 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c5a:	4709                	li	a4,2
    80004c5c:	0ee79163          	bne	a5,a4,80004d3e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c60:	0ac05d63          	blez	a2,80004d1a <filewrite+0xf4>
    int i = 0;
    80004c64:	4981                	li	s3,0
    80004c66:	6b05                	lui	s6,0x1
    80004c68:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c6c:	6b85                	lui	s7,0x1
    80004c6e:	c00b8b9b          	addiw	s7,s7,-1024
    80004c72:	a861                	j	80004d0a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c74:	6908                	ld	a0,16(a0)
    80004c76:	00000097          	auipc	ra,0x0
    80004c7a:	22e080e7          	jalr	558(ra) # 80004ea4 <pipewrite>
    80004c7e:	8a2a                	mv	s4,a0
    80004c80:	a045                	j	80004d20 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c82:	02451783          	lh	a5,36(a0)
    80004c86:	03079693          	slli	a3,a5,0x30
    80004c8a:	92c1                	srli	a3,a3,0x30
    80004c8c:	4725                	li	a4,9
    80004c8e:	0cd76263          	bltu	a4,a3,80004d52 <filewrite+0x12c>
    80004c92:	0792                	slli	a5,a5,0x4
    80004c94:	0001d717          	auipc	a4,0x1d
    80004c98:	fcc70713          	addi	a4,a4,-52 # 80021c60 <devsw>
    80004c9c:	97ba                	add	a5,a5,a4
    80004c9e:	679c                	ld	a5,8(a5)
    80004ca0:	cbdd                	beqz	a5,80004d56 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ca2:	4505                	li	a0,1
    80004ca4:	9782                	jalr	a5
    80004ca6:	8a2a                	mv	s4,a0
    80004ca8:	a8a5                	j	80004d20 <filewrite+0xfa>
    80004caa:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cae:	00000097          	auipc	ra,0x0
    80004cb2:	8b0080e7          	jalr	-1872(ra) # 8000455e <begin_op>
      ilock(f->ip);
    80004cb6:	01893503          	ld	a0,24(s2)
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	ed2080e7          	jalr	-302(ra) # 80003b8c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cc2:	8762                	mv	a4,s8
    80004cc4:	02092683          	lw	a3,32(s2)
    80004cc8:	01598633          	add	a2,s3,s5
    80004ccc:	4585                	li	a1,1
    80004cce:	01893503          	ld	a0,24(s2)
    80004cd2:	fffff097          	auipc	ra,0xfffff
    80004cd6:	266080e7          	jalr	614(ra) # 80003f38 <writei>
    80004cda:	84aa                	mv	s1,a0
    80004cdc:	00a05763          	blez	a0,80004cea <filewrite+0xc4>
        f->off += r;
    80004ce0:	02092783          	lw	a5,32(s2)
    80004ce4:	9fa9                	addw	a5,a5,a0
    80004ce6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cea:	01893503          	ld	a0,24(s2)
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	f60080e7          	jalr	-160(ra) # 80003c4e <iunlock>
      end_op();
    80004cf6:	00000097          	auipc	ra,0x0
    80004cfa:	8e8080e7          	jalr	-1816(ra) # 800045de <end_op>

      if(r != n1){
    80004cfe:	009c1f63          	bne	s8,s1,80004d1c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d02:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d06:	0149db63          	bge	s3,s4,80004d1c <filewrite+0xf6>
      int n1 = n - i;
    80004d0a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d0e:	84be                	mv	s1,a5
    80004d10:	2781                	sext.w	a5,a5
    80004d12:	f8fb5ce3          	bge	s6,a5,80004caa <filewrite+0x84>
    80004d16:	84de                	mv	s1,s7
    80004d18:	bf49                	j	80004caa <filewrite+0x84>
    int i = 0;
    80004d1a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d1c:	013a1f63          	bne	s4,s3,80004d3a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d20:	8552                	mv	a0,s4
    80004d22:	60a6                	ld	ra,72(sp)
    80004d24:	6406                	ld	s0,64(sp)
    80004d26:	74e2                	ld	s1,56(sp)
    80004d28:	7942                	ld	s2,48(sp)
    80004d2a:	79a2                	ld	s3,40(sp)
    80004d2c:	7a02                	ld	s4,32(sp)
    80004d2e:	6ae2                	ld	s5,24(sp)
    80004d30:	6b42                	ld	s6,16(sp)
    80004d32:	6ba2                	ld	s7,8(sp)
    80004d34:	6c02                	ld	s8,0(sp)
    80004d36:	6161                	addi	sp,sp,80
    80004d38:	8082                	ret
    ret = (i == n ? n : -1);
    80004d3a:	5a7d                	li	s4,-1
    80004d3c:	b7d5                	j	80004d20 <filewrite+0xfa>
    panic("filewrite");
    80004d3e:	00004517          	auipc	a0,0x4
    80004d42:	99250513          	addi	a0,a0,-1646 # 800086d0 <syscalls+0x278>
    80004d46:	ffffb097          	auipc	ra,0xffffb
    80004d4a:	7f8080e7          	jalr	2040(ra) # 8000053e <panic>
    return -1;
    80004d4e:	5a7d                	li	s4,-1
    80004d50:	bfc1                	j	80004d20 <filewrite+0xfa>
      return -1;
    80004d52:	5a7d                	li	s4,-1
    80004d54:	b7f1                	j	80004d20 <filewrite+0xfa>
    80004d56:	5a7d                	li	s4,-1
    80004d58:	b7e1                	j	80004d20 <filewrite+0xfa>

0000000080004d5a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d5a:	7179                	addi	sp,sp,-48
    80004d5c:	f406                	sd	ra,40(sp)
    80004d5e:	f022                	sd	s0,32(sp)
    80004d60:	ec26                	sd	s1,24(sp)
    80004d62:	e84a                	sd	s2,16(sp)
    80004d64:	e44e                	sd	s3,8(sp)
    80004d66:	e052                	sd	s4,0(sp)
    80004d68:	1800                	addi	s0,sp,48
    80004d6a:	84aa                	mv	s1,a0
    80004d6c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d6e:	0005b023          	sd	zero,0(a1)
    80004d72:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d76:	00000097          	auipc	ra,0x0
    80004d7a:	bf8080e7          	jalr	-1032(ra) # 8000496e <filealloc>
    80004d7e:	e088                	sd	a0,0(s1)
    80004d80:	c551                	beqz	a0,80004e0c <pipealloc+0xb2>
    80004d82:	00000097          	auipc	ra,0x0
    80004d86:	bec080e7          	jalr	-1044(ra) # 8000496e <filealloc>
    80004d8a:	00aa3023          	sd	a0,0(s4)
    80004d8e:	c92d                	beqz	a0,80004e00 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	d64080e7          	jalr	-668(ra) # 80000af4 <kalloc>
    80004d98:	892a                	mv	s2,a0
    80004d9a:	c125                	beqz	a0,80004dfa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d9c:	4985                	li	s3,1
    80004d9e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004da2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004da6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004daa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004dae:	00004597          	auipc	a1,0x4
    80004db2:	93258593          	addi	a1,a1,-1742 # 800086e0 <syscalls+0x288>
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	d9e080e7          	jalr	-610(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004dbe:	609c                	ld	a5,0(s1)
    80004dc0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dc4:	609c                	ld	a5,0(s1)
    80004dc6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dca:	609c                	ld	a5,0(s1)
    80004dcc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dd0:	609c                	ld	a5,0(s1)
    80004dd2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dd6:	000a3783          	ld	a5,0(s4)
    80004dda:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dde:	000a3783          	ld	a5,0(s4)
    80004de2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004de6:	000a3783          	ld	a5,0(s4)
    80004dea:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dee:	000a3783          	ld	a5,0(s4)
    80004df2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004df6:	4501                	li	a0,0
    80004df8:	a025                	j	80004e20 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dfa:	6088                	ld	a0,0(s1)
    80004dfc:	e501                	bnez	a0,80004e04 <pipealloc+0xaa>
    80004dfe:	a039                	j	80004e0c <pipealloc+0xb2>
    80004e00:	6088                	ld	a0,0(s1)
    80004e02:	c51d                	beqz	a0,80004e30 <pipealloc+0xd6>
    fileclose(*f0);
    80004e04:	00000097          	auipc	ra,0x0
    80004e08:	c26080e7          	jalr	-986(ra) # 80004a2a <fileclose>
  if(*f1)
    80004e0c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e10:	557d                	li	a0,-1
  if(*f1)
    80004e12:	c799                	beqz	a5,80004e20 <pipealloc+0xc6>
    fileclose(*f1);
    80004e14:	853e                	mv	a0,a5
    80004e16:	00000097          	auipc	ra,0x0
    80004e1a:	c14080e7          	jalr	-1004(ra) # 80004a2a <fileclose>
  return -1;
    80004e1e:	557d                	li	a0,-1
}
    80004e20:	70a2                	ld	ra,40(sp)
    80004e22:	7402                	ld	s0,32(sp)
    80004e24:	64e2                	ld	s1,24(sp)
    80004e26:	6942                	ld	s2,16(sp)
    80004e28:	69a2                	ld	s3,8(sp)
    80004e2a:	6a02                	ld	s4,0(sp)
    80004e2c:	6145                	addi	sp,sp,48
    80004e2e:	8082                	ret
  return -1;
    80004e30:	557d                	li	a0,-1
    80004e32:	b7fd                	j	80004e20 <pipealloc+0xc6>

0000000080004e34 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e34:	1101                	addi	sp,sp,-32
    80004e36:	ec06                	sd	ra,24(sp)
    80004e38:	e822                	sd	s0,16(sp)
    80004e3a:	e426                	sd	s1,8(sp)
    80004e3c:	e04a                	sd	s2,0(sp)
    80004e3e:	1000                	addi	s0,sp,32
    80004e40:	84aa                	mv	s1,a0
    80004e42:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	da0080e7          	jalr	-608(ra) # 80000be4 <acquire>
  if(writable){
    80004e4c:	02090d63          	beqz	s2,80004e86 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e50:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e54:	21848513          	addi	a0,s1,536
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	5d4080e7          	jalr	1492(ra) # 8000242c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e60:	2204b783          	ld	a5,544(s1)
    80004e64:	eb95                	bnez	a5,80004e98 <pipeclose+0x64>
    release(&pi->lock);
    80004e66:	8526                	mv	a0,s1
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	e30080e7          	jalr	-464(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e70:	8526                	mv	a0,s1
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	b86080e7          	jalr	-1146(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e7a:	60e2                	ld	ra,24(sp)
    80004e7c:	6442                	ld	s0,16(sp)
    80004e7e:	64a2                	ld	s1,8(sp)
    80004e80:	6902                	ld	s2,0(sp)
    80004e82:	6105                	addi	sp,sp,32
    80004e84:	8082                	ret
    pi->readopen = 0;
    80004e86:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e8a:	21c48513          	addi	a0,s1,540
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	59e080e7          	jalr	1438(ra) # 8000242c <wakeup>
    80004e96:	b7e9                	j	80004e60 <pipeclose+0x2c>
    release(&pi->lock);
    80004e98:	8526                	mv	a0,s1
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	dfe080e7          	jalr	-514(ra) # 80000c98 <release>
}
    80004ea2:	bfe1                	j	80004e7a <pipeclose+0x46>

0000000080004ea4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ea4:	7159                	addi	sp,sp,-112
    80004ea6:	f486                	sd	ra,104(sp)
    80004ea8:	f0a2                	sd	s0,96(sp)
    80004eaa:	eca6                	sd	s1,88(sp)
    80004eac:	e8ca                	sd	s2,80(sp)
    80004eae:	e4ce                	sd	s3,72(sp)
    80004eb0:	e0d2                	sd	s4,64(sp)
    80004eb2:	fc56                	sd	s5,56(sp)
    80004eb4:	f85a                	sd	s6,48(sp)
    80004eb6:	f45e                	sd	s7,40(sp)
    80004eb8:	f062                	sd	s8,32(sp)
    80004eba:	ec66                	sd	s9,24(sp)
    80004ebc:	1880                	addi	s0,sp,112
    80004ebe:	84aa                	mv	s1,a0
    80004ec0:	8aae                	mv	s5,a1
    80004ec2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	a44080e7          	jalr	-1468(ra) # 80001908 <myproc>
    80004ecc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ece:	8526                	mv	a0,s1
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	d14080e7          	jalr	-748(ra) # 80000be4 <acquire>
  while(i < n){
    80004ed8:	0d405163          	blez	s4,80004f9a <pipewrite+0xf6>
    80004edc:	8ba6                	mv	s7,s1
  int i = 0;
    80004ede:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ee0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ee2:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ee6:	21c48c13          	addi	s8,s1,540
    80004eea:	a08d                	j	80004f4c <pipewrite+0xa8>
      release(&pi->lock);
    80004eec:	8526                	mv	a0,s1
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	daa080e7          	jalr	-598(ra) # 80000c98 <release>
      return -1;
    80004ef6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ef8:	854a                	mv	a0,s2
    80004efa:	70a6                	ld	ra,104(sp)
    80004efc:	7406                	ld	s0,96(sp)
    80004efe:	64e6                	ld	s1,88(sp)
    80004f00:	6946                	ld	s2,80(sp)
    80004f02:	69a6                	ld	s3,72(sp)
    80004f04:	6a06                	ld	s4,64(sp)
    80004f06:	7ae2                	ld	s5,56(sp)
    80004f08:	7b42                	ld	s6,48(sp)
    80004f0a:	7ba2                	ld	s7,40(sp)
    80004f0c:	7c02                	ld	s8,32(sp)
    80004f0e:	6ce2                	ld	s9,24(sp)
    80004f10:	6165                	addi	sp,sp,112
    80004f12:	8082                	ret
      wakeup(&pi->nread);
    80004f14:	8566                	mv	a0,s9
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	516080e7          	jalr	1302(ra) # 8000242c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f1e:	85de                	mv	a1,s7
    80004f20:	8562                	mv	a0,s8
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	198080e7          	jalr	408(ra) # 800020ba <sleep>
    80004f2a:	a839                	j	80004f48 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f2c:	21c4a783          	lw	a5,540(s1)
    80004f30:	0017871b          	addiw	a4,a5,1
    80004f34:	20e4ae23          	sw	a4,540(s1)
    80004f38:	1ff7f793          	andi	a5,a5,511
    80004f3c:	97a6                	add	a5,a5,s1
    80004f3e:	f9f44703          	lbu	a4,-97(s0)
    80004f42:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f46:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f48:	03495d63          	bge	s2,s4,80004f82 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f4c:	2204a783          	lw	a5,544(s1)
    80004f50:	dfd1                	beqz	a5,80004eec <pipewrite+0x48>
    80004f52:	0289a783          	lw	a5,40(s3)
    80004f56:	fbd9                	bnez	a5,80004eec <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f58:	2184a783          	lw	a5,536(s1)
    80004f5c:	21c4a703          	lw	a4,540(s1)
    80004f60:	2007879b          	addiw	a5,a5,512
    80004f64:	faf708e3          	beq	a4,a5,80004f14 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f68:	4685                	li	a3,1
    80004f6a:	01590633          	add	a2,s2,s5
    80004f6e:	f9f40593          	addi	a1,s0,-97
    80004f72:	0709b503          	ld	a0,112(s3)
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	788080e7          	jalr	1928(ra) # 800016fe <copyin>
    80004f7e:	fb6517e3          	bne	a0,s6,80004f2c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f82:	21848513          	addi	a0,s1,536
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	4a6080e7          	jalr	1190(ra) # 8000242c <wakeup>
  release(&pi->lock);
    80004f8e:	8526                	mv	a0,s1
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	d08080e7          	jalr	-760(ra) # 80000c98 <release>
  return i;
    80004f98:	b785                	j	80004ef8 <pipewrite+0x54>
  int i = 0;
    80004f9a:	4901                	li	s2,0
    80004f9c:	b7dd                	j	80004f82 <pipewrite+0xde>

0000000080004f9e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f9e:	715d                	addi	sp,sp,-80
    80004fa0:	e486                	sd	ra,72(sp)
    80004fa2:	e0a2                	sd	s0,64(sp)
    80004fa4:	fc26                	sd	s1,56(sp)
    80004fa6:	f84a                	sd	s2,48(sp)
    80004fa8:	f44e                	sd	s3,40(sp)
    80004faa:	f052                	sd	s4,32(sp)
    80004fac:	ec56                	sd	s5,24(sp)
    80004fae:	e85a                	sd	s6,16(sp)
    80004fb0:	0880                	addi	s0,sp,80
    80004fb2:	84aa                	mv	s1,a0
    80004fb4:	892e                	mv	s2,a1
    80004fb6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	950080e7          	jalr	-1712(ra) # 80001908 <myproc>
    80004fc0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fc2:	8b26                	mv	s6,s1
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	c1e080e7          	jalr	-994(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fce:	2184a703          	lw	a4,536(s1)
    80004fd2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fd6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fda:	02f71463          	bne	a4,a5,80005002 <piperead+0x64>
    80004fde:	2244a783          	lw	a5,548(s1)
    80004fe2:	c385                	beqz	a5,80005002 <piperead+0x64>
    if(pr->killed){
    80004fe4:	028a2783          	lw	a5,40(s4)
    80004fe8:	ebc1                	bnez	a5,80005078 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fea:	85da                	mv	a1,s6
    80004fec:	854e                	mv	a0,s3
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	0cc080e7          	jalr	204(ra) # 800020ba <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ff6:	2184a703          	lw	a4,536(s1)
    80004ffa:	21c4a783          	lw	a5,540(s1)
    80004ffe:	fef700e3          	beq	a4,a5,80004fde <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005002:	09505263          	blez	s5,80005086 <piperead+0xe8>
    80005006:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005008:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000500a:	2184a783          	lw	a5,536(s1)
    8000500e:	21c4a703          	lw	a4,540(s1)
    80005012:	02f70d63          	beq	a4,a5,8000504c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005016:	0017871b          	addiw	a4,a5,1
    8000501a:	20e4ac23          	sw	a4,536(s1)
    8000501e:	1ff7f793          	andi	a5,a5,511
    80005022:	97a6                	add	a5,a5,s1
    80005024:	0187c783          	lbu	a5,24(a5)
    80005028:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000502c:	4685                	li	a3,1
    8000502e:	fbf40613          	addi	a2,s0,-65
    80005032:	85ca                	mv	a1,s2
    80005034:	070a3503          	ld	a0,112(s4)
    80005038:	ffffc097          	auipc	ra,0xffffc
    8000503c:	63a080e7          	jalr	1594(ra) # 80001672 <copyout>
    80005040:	01650663          	beq	a0,s6,8000504c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005044:	2985                	addiw	s3,s3,1
    80005046:	0905                	addi	s2,s2,1
    80005048:	fd3a91e3          	bne	s5,s3,8000500a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000504c:	21c48513          	addi	a0,s1,540
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	3dc080e7          	jalr	988(ra) # 8000242c <wakeup>
  release(&pi->lock);
    80005058:	8526                	mv	a0,s1
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	c3e080e7          	jalr	-962(ra) # 80000c98 <release>
  return i;
}
    80005062:	854e                	mv	a0,s3
    80005064:	60a6                	ld	ra,72(sp)
    80005066:	6406                	ld	s0,64(sp)
    80005068:	74e2                	ld	s1,56(sp)
    8000506a:	7942                	ld	s2,48(sp)
    8000506c:	79a2                	ld	s3,40(sp)
    8000506e:	7a02                	ld	s4,32(sp)
    80005070:	6ae2                	ld	s5,24(sp)
    80005072:	6b42                	ld	s6,16(sp)
    80005074:	6161                	addi	sp,sp,80
    80005076:	8082                	ret
      release(&pi->lock);
    80005078:	8526                	mv	a0,s1
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	c1e080e7          	jalr	-994(ra) # 80000c98 <release>
      return -1;
    80005082:	59fd                	li	s3,-1
    80005084:	bff9                	j	80005062 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005086:	4981                	li	s3,0
    80005088:	b7d1                	j	8000504c <piperead+0xae>

000000008000508a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000508a:	df010113          	addi	sp,sp,-528
    8000508e:	20113423          	sd	ra,520(sp)
    80005092:	20813023          	sd	s0,512(sp)
    80005096:	ffa6                	sd	s1,504(sp)
    80005098:	fbca                	sd	s2,496(sp)
    8000509a:	f7ce                	sd	s3,488(sp)
    8000509c:	f3d2                	sd	s4,480(sp)
    8000509e:	efd6                	sd	s5,472(sp)
    800050a0:	ebda                	sd	s6,464(sp)
    800050a2:	e7de                	sd	s7,456(sp)
    800050a4:	e3e2                	sd	s8,448(sp)
    800050a6:	ff66                	sd	s9,440(sp)
    800050a8:	fb6a                	sd	s10,432(sp)
    800050aa:	f76e                	sd	s11,424(sp)
    800050ac:	0c00                	addi	s0,sp,528
    800050ae:	84aa                	mv	s1,a0
    800050b0:	dea43c23          	sd	a0,-520(s0)
    800050b4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	850080e7          	jalr	-1968(ra) # 80001908 <myproc>
    800050c0:	892a                	mv	s2,a0

  begin_op();
    800050c2:	fffff097          	auipc	ra,0xfffff
    800050c6:	49c080e7          	jalr	1180(ra) # 8000455e <begin_op>

  if((ip = namei(path)) == 0){
    800050ca:	8526                	mv	a0,s1
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	276080e7          	jalr	630(ra) # 80004342 <namei>
    800050d4:	c92d                	beqz	a0,80005146 <exec+0xbc>
    800050d6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050d8:	fffff097          	auipc	ra,0xfffff
    800050dc:	ab4080e7          	jalr	-1356(ra) # 80003b8c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050e0:	04000713          	li	a4,64
    800050e4:	4681                	li	a3,0
    800050e6:	e5040613          	addi	a2,s0,-432
    800050ea:	4581                	li	a1,0
    800050ec:	8526                	mv	a0,s1
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	d52080e7          	jalr	-686(ra) # 80003e40 <readi>
    800050f6:	04000793          	li	a5,64
    800050fa:	00f51a63          	bne	a0,a5,8000510e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050fe:	e5042703          	lw	a4,-432(s0)
    80005102:	464c47b7          	lui	a5,0x464c4
    80005106:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000510a:	04f70463          	beq	a4,a5,80005152 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000510e:	8526                	mv	a0,s1
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	cde080e7          	jalr	-802(ra) # 80003dee <iunlockput>
    end_op();
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	4c6080e7          	jalr	1222(ra) # 800045de <end_op>
  }
  return -1;
    80005120:	557d                	li	a0,-1
}
    80005122:	20813083          	ld	ra,520(sp)
    80005126:	20013403          	ld	s0,512(sp)
    8000512a:	74fe                	ld	s1,504(sp)
    8000512c:	795e                	ld	s2,496(sp)
    8000512e:	79be                	ld	s3,488(sp)
    80005130:	7a1e                	ld	s4,480(sp)
    80005132:	6afe                	ld	s5,472(sp)
    80005134:	6b5e                	ld	s6,464(sp)
    80005136:	6bbe                	ld	s7,456(sp)
    80005138:	6c1e                	ld	s8,448(sp)
    8000513a:	7cfa                	ld	s9,440(sp)
    8000513c:	7d5a                	ld	s10,432(sp)
    8000513e:	7dba                	ld	s11,424(sp)
    80005140:	21010113          	addi	sp,sp,528
    80005144:	8082                	ret
    end_op();
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	498080e7          	jalr	1176(ra) # 800045de <end_op>
    return -1;
    8000514e:	557d                	li	a0,-1
    80005150:	bfc9                	j	80005122 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005152:	854a                	mv	a0,s2
    80005154:	ffffd097          	auipc	ra,0xffffd
    80005158:	872080e7          	jalr	-1934(ra) # 800019c6 <proc_pagetable>
    8000515c:	8baa                	mv	s7,a0
    8000515e:	d945                	beqz	a0,8000510e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005160:	e7042983          	lw	s3,-400(s0)
    80005164:	e8845783          	lhu	a5,-376(s0)
    80005168:	c7ad                	beqz	a5,800051d2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000516a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000516c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000516e:	6c85                	lui	s9,0x1
    80005170:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005174:	def43823          	sd	a5,-528(s0)
    80005178:	a42d                	j	800053a2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000517a:	00003517          	auipc	a0,0x3
    8000517e:	56e50513          	addi	a0,a0,1390 # 800086e8 <syscalls+0x290>
    80005182:	ffffb097          	auipc	ra,0xffffb
    80005186:	3bc080e7          	jalr	956(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000518a:	8756                	mv	a4,s5
    8000518c:	012d86bb          	addw	a3,s11,s2
    80005190:	4581                	li	a1,0
    80005192:	8526                	mv	a0,s1
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	cac080e7          	jalr	-852(ra) # 80003e40 <readi>
    8000519c:	2501                	sext.w	a0,a0
    8000519e:	1aaa9963          	bne	s5,a0,80005350 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800051a2:	6785                	lui	a5,0x1
    800051a4:	0127893b          	addw	s2,a5,s2
    800051a8:	77fd                	lui	a5,0xfffff
    800051aa:	01478a3b          	addw	s4,a5,s4
    800051ae:	1f897163          	bgeu	s2,s8,80005390 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051b2:	02091593          	slli	a1,s2,0x20
    800051b6:	9181                	srli	a1,a1,0x20
    800051b8:	95ea                	add	a1,a1,s10
    800051ba:	855e                	mv	a0,s7
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	eb2080e7          	jalr	-334(ra) # 8000106e <walkaddr>
    800051c4:	862a                	mv	a2,a0
    if(pa == 0)
    800051c6:	d955                	beqz	a0,8000517a <exec+0xf0>
      n = PGSIZE;
    800051c8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051ca:	fd9a70e3          	bgeu	s4,s9,8000518a <exec+0x100>
      n = sz - i;
    800051ce:	8ad2                	mv	s5,s4
    800051d0:	bf6d                	j	8000518a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051d2:	4901                	li	s2,0
  iunlockput(ip);
    800051d4:	8526                	mv	a0,s1
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	c18080e7          	jalr	-1000(ra) # 80003dee <iunlockput>
  end_op();
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	400080e7          	jalr	1024(ra) # 800045de <end_op>
  p = myproc();
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	722080e7          	jalr	1826(ra) # 80001908 <myproc>
    800051ee:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051f0:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800051f4:	6785                	lui	a5,0x1
    800051f6:	17fd                	addi	a5,a5,-1
    800051f8:	993e                	add	s2,s2,a5
    800051fa:	757d                	lui	a0,0xfffff
    800051fc:	00a977b3          	and	a5,s2,a0
    80005200:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005204:	6609                	lui	a2,0x2
    80005206:	963e                	add	a2,a2,a5
    80005208:	85be                	mv	a1,a5
    8000520a:	855e                	mv	a0,s7
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	216080e7          	jalr	534(ra) # 80001422 <uvmalloc>
    80005214:	8b2a                	mv	s6,a0
  ip = 0;
    80005216:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005218:	12050c63          	beqz	a0,80005350 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000521c:	75f9                	lui	a1,0xffffe
    8000521e:	95aa                	add	a1,a1,a0
    80005220:	855e                	mv	a0,s7
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	41e080e7          	jalr	1054(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000522a:	7c7d                	lui	s8,0xfffff
    8000522c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000522e:	e0043783          	ld	a5,-512(s0)
    80005232:	6388                	ld	a0,0(a5)
    80005234:	c535                	beqz	a0,800052a0 <exec+0x216>
    80005236:	e9040993          	addi	s3,s0,-368
    8000523a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000523e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005240:	ffffc097          	auipc	ra,0xffffc
    80005244:	c24080e7          	jalr	-988(ra) # 80000e64 <strlen>
    80005248:	2505                	addiw	a0,a0,1
    8000524a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000524e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005252:	13896363          	bltu	s2,s8,80005378 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005256:	e0043d83          	ld	s11,-512(s0)
    8000525a:	000dba03          	ld	s4,0(s11)
    8000525e:	8552                	mv	a0,s4
    80005260:	ffffc097          	auipc	ra,0xffffc
    80005264:	c04080e7          	jalr	-1020(ra) # 80000e64 <strlen>
    80005268:	0015069b          	addiw	a3,a0,1
    8000526c:	8652                	mv	a2,s4
    8000526e:	85ca                	mv	a1,s2
    80005270:	855e                	mv	a0,s7
    80005272:	ffffc097          	auipc	ra,0xffffc
    80005276:	400080e7          	jalr	1024(ra) # 80001672 <copyout>
    8000527a:	10054363          	bltz	a0,80005380 <exec+0x2f6>
    ustack[argc] = sp;
    8000527e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005282:	0485                	addi	s1,s1,1
    80005284:	008d8793          	addi	a5,s11,8
    80005288:	e0f43023          	sd	a5,-512(s0)
    8000528c:	008db503          	ld	a0,8(s11)
    80005290:	c911                	beqz	a0,800052a4 <exec+0x21a>
    if(argc >= MAXARG)
    80005292:	09a1                	addi	s3,s3,8
    80005294:	fb3c96e3          	bne	s9,s3,80005240 <exec+0x1b6>
  sz = sz1;
    80005298:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000529c:	4481                	li	s1,0
    8000529e:	a84d                	j	80005350 <exec+0x2c6>
  sp = sz;
    800052a0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800052a2:	4481                	li	s1,0
  ustack[argc] = 0;
    800052a4:	00349793          	slli	a5,s1,0x3
    800052a8:	f9040713          	addi	a4,s0,-112
    800052ac:	97ba                	add	a5,a5,a4
    800052ae:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052b2:	00148693          	addi	a3,s1,1
    800052b6:	068e                	slli	a3,a3,0x3
    800052b8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052bc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052c0:	01897663          	bgeu	s2,s8,800052cc <exec+0x242>
  sz = sz1;
    800052c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052c8:	4481                	li	s1,0
    800052ca:	a059                	j	80005350 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052cc:	e9040613          	addi	a2,s0,-368
    800052d0:	85ca                	mv	a1,s2
    800052d2:	855e                	mv	a0,s7
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	39e080e7          	jalr	926(ra) # 80001672 <copyout>
    800052dc:	0a054663          	bltz	a0,80005388 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052e0:	078ab783          	ld	a5,120(s5)
    800052e4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052e8:	df843783          	ld	a5,-520(s0)
    800052ec:	0007c703          	lbu	a4,0(a5)
    800052f0:	cf11                	beqz	a4,8000530c <exec+0x282>
    800052f2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052f4:	02f00693          	li	a3,47
    800052f8:	a039                	j	80005306 <exec+0x27c>
      last = s+1;
    800052fa:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052fe:	0785                	addi	a5,a5,1
    80005300:	fff7c703          	lbu	a4,-1(a5)
    80005304:	c701                	beqz	a4,8000530c <exec+0x282>
    if(*s == '/')
    80005306:	fed71ce3          	bne	a4,a3,800052fe <exec+0x274>
    8000530a:	bfc5                	j	800052fa <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000530c:	4641                	li	a2,16
    8000530e:	df843583          	ld	a1,-520(s0)
    80005312:	178a8513          	addi	a0,s5,376
    80005316:	ffffc097          	auipc	ra,0xffffc
    8000531a:	b1c080e7          	jalr	-1252(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000531e:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005322:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005326:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000532a:	078ab783          	ld	a5,120(s5)
    8000532e:	e6843703          	ld	a4,-408(s0)
    80005332:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005334:	078ab783          	ld	a5,120(s5)
    80005338:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000533c:	85ea                	mv	a1,s10
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	724080e7          	jalr	1828(ra) # 80001a62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005346:	0004851b          	sext.w	a0,s1
    8000534a:	bbe1                	j	80005122 <exec+0x98>
    8000534c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005350:	e0843583          	ld	a1,-504(s0)
    80005354:	855e                	mv	a0,s7
    80005356:	ffffc097          	auipc	ra,0xffffc
    8000535a:	70c080e7          	jalr	1804(ra) # 80001a62 <proc_freepagetable>
  if(ip){
    8000535e:	da0498e3          	bnez	s1,8000510e <exec+0x84>
  return -1;
    80005362:	557d                	li	a0,-1
    80005364:	bb7d                	j	80005122 <exec+0x98>
    80005366:	e1243423          	sd	s2,-504(s0)
    8000536a:	b7dd                	j	80005350 <exec+0x2c6>
    8000536c:	e1243423          	sd	s2,-504(s0)
    80005370:	b7c5                	j	80005350 <exec+0x2c6>
    80005372:	e1243423          	sd	s2,-504(s0)
    80005376:	bfe9                	j	80005350 <exec+0x2c6>
  sz = sz1;
    80005378:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000537c:	4481                	li	s1,0
    8000537e:	bfc9                	j	80005350 <exec+0x2c6>
  sz = sz1;
    80005380:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005384:	4481                	li	s1,0
    80005386:	b7e9                	j	80005350 <exec+0x2c6>
  sz = sz1;
    80005388:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000538c:	4481                	li	s1,0
    8000538e:	b7c9                	j	80005350 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005390:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005394:	2b05                	addiw	s6,s6,1
    80005396:	0389899b          	addiw	s3,s3,56
    8000539a:	e8845783          	lhu	a5,-376(s0)
    8000539e:	e2fb5be3          	bge	s6,a5,800051d4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053a2:	2981                	sext.w	s3,s3
    800053a4:	03800713          	li	a4,56
    800053a8:	86ce                	mv	a3,s3
    800053aa:	e1840613          	addi	a2,s0,-488
    800053ae:	4581                	li	a1,0
    800053b0:	8526                	mv	a0,s1
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	a8e080e7          	jalr	-1394(ra) # 80003e40 <readi>
    800053ba:	03800793          	li	a5,56
    800053be:	f8f517e3          	bne	a0,a5,8000534c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053c2:	e1842783          	lw	a5,-488(s0)
    800053c6:	4705                	li	a4,1
    800053c8:	fce796e3          	bne	a5,a4,80005394 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053cc:	e4043603          	ld	a2,-448(s0)
    800053d0:	e3843783          	ld	a5,-456(s0)
    800053d4:	f8f669e3          	bltu	a2,a5,80005366 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053d8:	e2843783          	ld	a5,-472(s0)
    800053dc:	963e                	add	a2,a2,a5
    800053de:	f8f667e3          	bltu	a2,a5,8000536c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053e2:	85ca                	mv	a1,s2
    800053e4:	855e                	mv	a0,s7
    800053e6:	ffffc097          	auipc	ra,0xffffc
    800053ea:	03c080e7          	jalr	60(ra) # 80001422 <uvmalloc>
    800053ee:	e0a43423          	sd	a0,-504(s0)
    800053f2:	d141                	beqz	a0,80005372 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053f4:	e2843d03          	ld	s10,-472(s0)
    800053f8:	df043783          	ld	a5,-528(s0)
    800053fc:	00fd77b3          	and	a5,s10,a5
    80005400:	fba1                	bnez	a5,80005350 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005402:	e2042d83          	lw	s11,-480(s0)
    80005406:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000540a:	f80c03e3          	beqz	s8,80005390 <exec+0x306>
    8000540e:	8a62                	mv	s4,s8
    80005410:	4901                	li	s2,0
    80005412:	b345                	j	800051b2 <exec+0x128>

0000000080005414 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005414:	7179                	addi	sp,sp,-48
    80005416:	f406                	sd	ra,40(sp)
    80005418:	f022                	sd	s0,32(sp)
    8000541a:	ec26                	sd	s1,24(sp)
    8000541c:	e84a                	sd	s2,16(sp)
    8000541e:	1800                	addi	s0,sp,48
    80005420:	892e                	mv	s2,a1
    80005422:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005424:	fdc40593          	addi	a1,s0,-36
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	ba8080e7          	jalr	-1112(ra) # 80002fd0 <argint>
    80005430:	04054063          	bltz	a0,80005470 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005434:	fdc42703          	lw	a4,-36(s0)
    80005438:	47bd                	li	a5,15
    8000543a:	02e7ed63          	bltu	a5,a4,80005474 <argfd+0x60>
    8000543e:	ffffc097          	auipc	ra,0xffffc
    80005442:	4ca080e7          	jalr	1226(ra) # 80001908 <myproc>
    80005446:	fdc42703          	lw	a4,-36(s0)
    8000544a:	01e70793          	addi	a5,a4,30
    8000544e:	078e                	slli	a5,a5,0x3
    80005450:	953e                	add	a0,a0,a5
    80005452:	611c                	ld	a5,0(a0)
    80005454:	c395                	beqz	a5,80005478 <argfd+0x64>
    return -1;
  if(pfd)
    80005456:	00090463          	beqz	s2,8000545e <argfd+0x4a>
    *pfd = fd;
    8000545a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000545e:	4501                	li	a0,0
  if(pf)
    80005460:	c091                	beqz	s1,80005464 <argfd+0x50>
    *pf = f;
    80005462:	e09c                	sd	a5,0(s1)
}
    80005464:	70a2                	ld	ra,40(sp)
    80005466:	7402                	ld	s0,32(sp)
    80005468:	64e2                	ld	s1,24(sp)
    8000546a:	6942                	ld	s2,16(sp)
    8000546c:	6145                	addi	sp,sp,48
    8000546e:	8082                	ret
    return -1;
    80005470:	557d                	li	a0,-1
    80005472:	bfcd                	j	80005464 <argfd+0x50>
    return -1;
    80005474:	557d                	li	a0,-1
    80005476:	b7fd                	j	80005464 <argfd+0x50>
    80005478:	557d                	li	a0,-1
    8000547a:	b7ed                	j	80005464 <argfd+0x50>

000000008000547c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000547c:	1101                	addi	sp,sp,-32
    8000547e:	ec06                	sd	ra,24(sp)
    80005480:	e822                	sd	s0,16(sp)
    80005482:	e426                	sd	s1,8(sp)
    80005484:	1000                	addi	s0,sp,32
    80005486:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005488:	ffffc097          	auipc	ra,0xffffc
    8000548c:	480080e7          	jalr	1152(ra) # 80001908 <myproc>
    80005490:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005492:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005496:	4501                	li	a0,0
    80005498:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000549a:	6398                	ld	a4,0(a5)
    8000549c:	cb19                	beqz	a4,800054b2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000549e:	2505                	addiw	a0,a0,1
    800054a0:	07a1                	addi	a5,a5,8
    800054a2:	fed51ce3          	bne	a0,a3,8000549a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054a6:	557d                	li	a0,-1
}
    800054a8:	60e2                	ld	ra,24(sp)
    800054aa:	6442                	ld	s0,16(sp)
    800054ac:	64a2                	ld	s1,8(sp)
    800054ae:	6105                	addi	sp,sp,32
    800054b0:	8082                	ret
      p->ofile[fd] = f;
    800054b2:	01e50793          	addi	a5,a0,30
    800054b6:	078e                	slli	a5,a5,0x3
    800054b8:	963e                	add	a2,a2,a5
    800054ba:	e204                	sd	s1,0(a2)
      return fd;
    800054bc:	b7f5                	j	800054a8 <fdalloc+0x2c>

00000000800054be <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054be:	715d                	addi	sp,sp,-80
    800054c0:	e486                	sd	ra,72(sp)
    800054c2:	e0a2                	sd	s0,64(sp)
    800054c4:	fc26                	sd	s1,56(sp)
    800054c6:	f84a                	sd	s2,48(sp)
    800054c8:	f44e                	sd	s3,40(sp)
    800054ca:	f052                	sd	s4,32(sp)
    800054cc:	ec56                	sd	s5,24(sp)
    800054ce:	0880                	addi	s0,sp,80
    800054d0:	89ae                	mv	s3,a1
    800054d2:	8ab2                	mv	s5,a2
    800054d4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054d6:	fb040593          	addi	a1,s0,-80
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	e86080e7          	jalr	-378(ra) # 80004360 <nameiparent>
    800054e2:	892a                	mv	s2,a0
    800054e4:	12050f63          	beqz	a0,80005622 <create+0x164>
    return 0;

  ilock(dp);
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	6a4080e7          	jalr	1700(ra) # 80003b8c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054f0:	4601                	li	a2,0
    800054f2:	fb040593          	addi	a1,s0,-80
    800054f6:	854a                	mv	a0,s2
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	b78080e7          	jalr	-1160(ra) # 80004070 <dirlookup>
    80005500:	84aa                	mv	s1,a0
    80005502:	c921                	beqz	a0,80005552 <create+0x94>
    iunlockput(dp);
    80005504:	854a                	mv	a0,s2
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	8e8080e7          	jalr	-1816(ra) # 80003dee <iunlockput>
    ilock(ip);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	67c080e7          	jalr	1660(ra) # 80003b8c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005518:	2981                	sext.w	s3,s3
    8000551a:	4789                	li	a5,2
    8000551c:	02f99463          	bne	s3,a5,80005544 <create+0x86>
    80005520:	0444d783          	lhu	a5,68(s1)
    80005524:	37f9                	addiw	a5,a5,-2
    80005526:	17c2                	slli	a5,a5,0x30
    80005528:	93c1                	srli	a5,a5,0x30
    8000552a:	4705                	li	a4,1
    8000552c:	00f76c63          	bltu	a4,a5,80005544 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005530:	8526                	mv	a0,s1
    80005532:	60a6                	ld	ra,72(sp)
    80005534:	6406                	ld	s0,64(sp)
    80005536:	74e2                	ld	s1,56(sp)
    80005538:	7942                	ld	s2,48(sp)
    8000553a:	79a2                	ld	s3,40(sp)
    8000553c:	7a02                	ld	s4,32(sp)
    8000553e:	6ae2                	ld	s5,24(sp)
    80005540:	6161                	addi	sp,sp,80
    80005542:	8082                	ret
    iunlockput(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	8a8080e7          	jalr	-1880(ra) # 80003dee <iunlockput>
    return 0;
    8000554e:	4481                	li	s1,0
    80005550:	b7c5                	j	80005530 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005552:	85ce                	mv	a1,s3
    80005554:	00092503          	lw	a0,0(s2)
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	49c080e7          	jalr	1180(ra) # 800039f4 <ialloc>
    80005560:	84aa                	mv	s1,a0
    80005562:	c529                	beqz	a0,800055ac <create+0xee>
  ilock(ip);
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	628080e7          	jalr	1576(ra) # 80003b8c <ilock>
  ip->major = major;
    8000556c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005570:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005574:	4785                	li	a5,1
    80005576:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	546080e7          	jalr	1350(ra) # 80003ac2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005584:	2981                	sext.w	s3,s3
    80005586:	4785                	li	a5,1
    80005588:	02f98a63          	beq	s3,a5,800055bc <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000558c:	40d0                	lw	a2,4(s1)
    8000558e:	fb040593          	addi	a1,s0,-80
    80005592:	854a                	mv	a0,s2
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	cec080e7          	jalr	-788(ra) # 80004280 <dirlink>
    8000559c:	06054b63          	bltz	a0,80005612 <create+0x154>
  iunlockput(dp);
    800055a0:	854a                	mv	a0,s2
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	84c080e7          	jalr	-1972(ra) # 80003dee <iunlockput>
  return ip;
    800055aa:	b759                	j	80005530 <create+0x72>
    panic("create: ialloc");
    800055ac:	00003517          	auipc	a0,0x3
    800055b0:	15c50513          	addi	a0,a0,348 # 80008708 <syscalls+0x2b0>
    800055b4:	ffffb097          	auipc	ra,0xffffb
    800055b8:	f8a080e7          	jalr	-118(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055bc:	04a95783          	lhu	a5,74(s2)
    800055c0:	2785                	addiw	a5,a5,1
    800055c2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055c6:	854a                	mv	a0,s2
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	4fa080e7          	jalr	1274(ra) # 80003ac2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055d0:	40d0                	lw	a2,4(s1)
    800055d2:	00003597          	auipc	a1,0x3
    800055d6:	14658593          	addi	a1,a1,326 # 80008718 <syscalls+0x2c0>
    800055da:	8526                	mv	a0,s1
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	ca4080e7          	jalr	-860(ra) # 80004280 <dirlink>
    800055e4:	00054f63          	bltz	a0,80005602 <create+0x144>
    800055e8:	00492603          	lw	a2,4(s2)
    800055ec:	00003597          	auipc	a1,0x3
    800055f0:	13458593          	addi	a1,a1,308 # 80008720 <syscalls+0x2c8>
    800055f4:	8526                	mv	a0,s1
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	c8a080e7          	jalr	-886(ra) # 80004280 <dirlink>
    800055fe:	f80557e3          	bgez	a0,8000558c <create+0xce>
      panic("create dots");
    80005602:	00003517          	auipc	a0,0x3
    80005606:	12650513          	addi	a0,a0,294 # 80008728 <syscalls+0x2d0>
    8000560a:	ffffb097          	auipc	ra,0xffffb
    8000560e:	f34080e7          	jalr	-204(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005612:	00003517          	auipc	a0,0x3
    80005616:	12650513          	addi	a0,a0,294 # 80008738 <syscalls+0x2e0>
    8000561a:	ffffb097          	auipc	ra,0xffffb
    8000561e:	f24080e7          	jalr	-220(ra) # 8000053e <panic>
    return 0;
    80005622:	84aa                	mv	s1,a0
    80005624:	b731                	j	80005530 <create+0x72>

0000000080005626 <sys_dup>:
{
    80005626:	7179                	addi	sp,sp,-48
    80005628:	f406                	sd	ra,40(sp)
    8000562a:	f022                	sd	s0,32(sp)
    8000562c:	ec26                	sd	s1,24(sp)
    8000562e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005630:	fd840613          	addi	a2,s0,-40
    80005634:	4581                	li	a1,0
    80005636:	4501                	li	a0,0
    80005638:	00000097          	auipc	ra,0x0
    8000563c:	ddc080e7          	jalr	-548(ra) # 80005414 <argfd>
    return -1;
    80005640:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005642:	02054363          	bltz	a0,80005668 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005646:	fd843503          	ld	a0,-40(s0)
    8000564a:	00000097          	auipc	ra,0x0
    8000564e:	e32080e7          	jalr	-462(ra) # 8000547c <fdalloc>
    80005652:	84aa                	mv	s1,a0
    return -1;
    80005654:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005656:	00054963          	bltz	a0,80005668 <sys_dup+0x42>
  filedup(f);
    8000565a:	fd843503          	ld	a0,-40(s0)
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	37a080e7          	jalr	890(ra) # 800049d8 <filedup>
  return fd;
    80005666:	87a6                	mv	a5,s1
}
    80005668:	853e                	mv	a0,a5
    8000566a:	70a2                	ld	ra,40(sp)
    8000566c:	7402                	ld	s0,32(sp)
    8000566e:	64e2                	ld	s1,24(sp)
    80005670:	6145                	addi	sp,sp,48
    80005672:	8082                	ret

0000000080005674 <sys_read>:
{
    80005674:	7179                	addi	sp,sp,-48
    80005676:	f406                	sd	ra,40(sp)
    80005678:	f022                	sd	s0,32(sp)
    8000567a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567c:	fe840613          	addi	a2,s0,-24
    80005680:	4581                	li	a1,0
    80005682:	4501                	li	a0,0
    80005684:	00000097          	auipc	ra,0x0
    80005688:	d90080e7          	jalr	-624(ra) # 80005414 <argfd>
    return -1;
    8000568c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000568e:	04054163          	bltz	a0,800056d0 <sys_read+0x5c>
    80005692:	fe440593          	addi	a1,s0,-28
    80005696:	4509                	li	a0,2
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	938080e7          	jalr	-1736(ra) # 80002fd0 <argint>
    return -1;
    800056a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a2:	02054763          	bltz	a0,800056d0 <sys_read+0x5c>
    800056a6:	fd840593          	addi	a1,s0,-40
    800056aa:	4505                	li	a0,1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	946080e7          	jalr	-1722(ra) # 80002ff2 <argaddr>
    return -1;
    800056b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056b6:	00054d63          	bltz	a0,800056d0 <sys_read+0x5c>
  return fileread(f, p, n);
    800056ba:	fe442603          	lw	a2,-28(s0)
    800056be:	fd843583          	ld	a1,-40(s0)
    800056c2:	fe843503          	ld	a0,-24(s0)
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	49e080e7          	jalr	1182(ra) # 80004b64 <fileread>
    800056ce:	87aa                	mv	a5,a0
}
    800056d0:	853e                	mv	a0,a5
    800056d2:	70a2                	ld	ra,40(sp)
    800056d4:	7402                	ld	s0,32(sp)
    800056d6:	6145                	addi	sp,sp,48
    800056d8:	8082                	ret

00000000800056da <sys_write>:
{
    800056da:	7179                	addi	sp,sp,-48
    800056dc:	f406                	sd	ra,40(sp)
    800056de:	f022                	sd	s0,32(sp)
    800056e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e2:	fe840613          	addi	a2,s0,-24
    800056e6:	4581                	li	a1,0
    800056e8:	4501                	li	a0,0
    800056ea:	00000097          	auipc	ra,0x0
    800056ee:	d2a080e7          	jalr	-726(ra) # 80005414 <argfd>
    return -1;
    800056f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f4:	04054163          	bltz	a0,80005736 <sys_write+0x5c>
    800056f8:	fe440593          	addi	a1,s0,-28
    800056fc:	4509                	li	a0,2
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	8d2080e7          	jalr	-1838(ra) # 80002fd0 <argint>
    return -1;
    80005706:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005708:	02054763          	bltz	a0,80005736 <sys_write+0x5c>
    8000570c:	fd840593          	addi	a1,s0,-40
    80005710:	4505                	li	a0,1
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	8e0080e7          	jalr	-1824(ra) # 80002ff2 <argaddr>
    return -1;
    8000571a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000571c:	00054d63          	bltz	a0,80005736 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005720:	fe442603          	lw	a2,-28(s0)
    80005724:	fd843583          	ld	a1,-40(s0)
    80005728:	fe843503          	ld	a0,-24(s0)
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	4fa080e7          	jalr	1274(ra) # 80004c26 <filewrite>
    80005734:	87aa                	mv	a5,a0
}
    80005736:	853e                	mv	a0,a5
    80005738:	70a2                	ld	ra,40(sp)
    8000573a:	7402                	ld	s0,32(sp)
    8000573c:	6145                	addi	sp,sp,48
    8000573e:	8082                	ret

0000000080005740 <sys_close>:
{
    80005740:	1101                	addi	sp,sp,-32
    80005742:	ec06                	sd	ra,24(sp)
    80005744:	e822                	sd	s0,16(sp)
    80005746:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005748:	fe040613          	addi	a2,s0,-32
    8000574c:	fec40593          	addi	a1,s0,-20
    80005750:	4501                	li	a0,0
    80005752:	00000097          	auipc	ra,0x0
    80005756:	cc2080e7          	jalr	-830(ra) # 80005414 <argfd>
    return -1;
    8000575a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000575c:	02054463          	bltz	a0,80005784 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005760:	ffffc097          	auipc	ra,0xffffc
    80005764:	1a8080e7          	jalr	424(ra) # 80001908 <myproc>
    80005768:	fec42783          	lw	a5,-20(s0)
    8000576c:	07f9                	addi	a5,a5,30
    8000576e:	078e                	slli	a5,a5,0x3
    80005770:	97aa                	add	a5,a5,a0
    80005772:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005776:	fe043503          	ld	a0,-32(s0)
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	2b0080e7          	jalr	688(ra) # 80004a2a <fileclose>
  return 0;
    80005782:	4781                	li	a5,0
}
    80005784:	853e                	mv	a0,a5
    80005786:	60e2                	ld	ra,24(sp)
    80005788:	6442                	ld	s0,16(sp)
    8000578a:	6105                	addi	sp,sp,32
    8000578c:	8082                	ret

000000008000578e <sys_fstat>:
{
    8000578e:	1101                	addi	sp,sp,-32
    80005790:	ec06                	sd	ra,24(sp)
    80005792:	e822                	sd	s0,16(sp)
    80005794:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005796:	fe840613          	addi	a2,s0,-24
    8000579a:	4581                	li	a1,0
    8000579c:	4501                	li	a0,0
    8000579e:	00000097          	auipc	ra,0x0
    800057a2:	c76080e7          	jalr	-906(ra) # 80005414 <argfd>
    return -1;
    800057a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057a8:	02054563          	bltz	a0,800057d2 <sys_fstat+0x44>
    800057ac:	fe040593          	addi	a1,s0,-32
    800057b0:	4505                	li	a0,1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	840080e7          	jalr	-1984(ra) # 80002ff2 <argaddr>
    return -1;
    800057ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057bc:	00054b63          	bltz	a0,800057d2 <sys_fstat+0x44>
  return filestat(f, st);
    800057c0:	fe043583          	ld	a1,-32(s0)
    800057c4:	fe843503          	ld	a0,-24(s0)
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	32a080e7          	jalr	810(ra) # 80004af2 <filestat>
    800057d0:	87aa                	mv	a5,a0
}
    800057d2:	853e                	mv	a0,a5
    800057d4:	60e2                	ld	ra,24(sp)
    800057d6:	6442                	ld	s0,16(sp)
    800057d8:	6105                	addi	sp,sp,32
    800057da:	8082                	ret

00000000800057dc <sys_link>:
{
    800057dc:	7169                	addi	sp,sp,-304
    800057de:	f606                	sd	ra,296(sp)
    800057e0:	f222                	sd	s0,288(sp)
    800057e2:	ee26                	sd	s1,280(sp)
    800057e4:	ea4a                	sd	s2,272(sp)
    800057e6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057e8:	08000613          	li	a2,128
    800057ec:	ed040593          	addi	a1,s0,-304
    800057f0:	4501                	li	a0,0
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	822080e7          	jalr	-2014(ra) # 80003014 <argstr>
    return -1;
    800057fa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057fc:	10054e63          	bltz	a0,80005918 <sys_link+0x13c>
    80005800:	08000613          	li	a2,128
    80005804:	f5040593          	addi	a1,s0,-176
    80005808:	4505                	li	a0,1
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	80a080e7          	jalr	-2038(ra) # 80003014 <argstr>
    return -1;
    80005812:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005814:	10054263          	bltz	a0,80005918 <sys_link+0x13c>
  begin_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	d46080e7          	jalr	-698(ra) # 8000455e <begin_op>
  if((ip = namei(old)) == 0){
    80005820:	ed040513          	addi	a0,s0,-304
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	b1e080e7          	jalr	-1250(ra) # 80004342 <namei>
    8000582c:	84aa                	mv	s1,a0
    8000582e:	c551                	beqz	a0,800058ba <sys_link+0xde>
  ilock(ip);
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	35c080e7          	jalr	860(ra) # 80003b8c <ilock>
  if(ip->type == T_DIR){
    80005838:	04449703          	lh	a4,68(s1)
    8000583c:	4785                	li	a5,1
    8000583e:	08f70463          	beq	a4,a5,800058c6 <sys_link+0xea>
  ip->nlink++;
    80005842:	04a4d783          	lhu	a5,74(s1)
    80005846:	2785                	addiw	a5,a5,1
    80005848:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	274080e7          	jalr	628(ra) # 80003ac2 <iupdate>
  iunlock(ip);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	3f6080e7          	jalr	1014(ra) # 80003c4e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005860:	fd040593          	addi	a1,s0,-48
    80005864:	f5040513          	addi	a0,s0,-176
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	af8080e7          	jalr	-1288(ra) # 80004360 <nameiparent>
    80005870:	892a                	mv	s2,a0
    80005872:	c935                	beqz	a0,800058e6 <sys_link+0x10a>
  ilock(dp);
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	318080e7          	jalr	792(ra) # 80003b8c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000587c:	00092703          	lw	a4,0(s2)
    80005880:	409c                	lw	a5,0(s1)
    80005882:	04f71d63          	bne	a4,a5,800058dc <sys_link+0x100>
    80005886:	40d0                	lw	a2,4(s1)
    80005888:	fd040593          	addi	a1,s0,-48
    8000588c:	854a                	mv	a0,s2
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	9f2080e7          	jalr	-1550(ra) # 80004280 <dirlink>
    80005896:	04054363          	bltz	a0,800058dc <sys_link+0x100>
  iunlockput(dp);
    8000589a:	854a                	mv	a0,s2
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	552080e7          	jalr	1362(ra) # 80003dee <iunlockput>
  iput(ip);
    800058a4:	8526                	mv	a0,s1
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	4a0080e7          	jalr	1184(ra) # 80003d46 <iput>
  end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	d30080e7          	jalr	-720(ra) # 800045de <end_op>
  return 0;
    800058b6:	4781                	li	a5,0
    800058b8:	a085                	j	80005918 <sys_link+0x13c>
    end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	d24080e7          	jalr	-732(ra) # 800045de <end_op>
    return -1;
    800058c2:	57fd                	li	a5,-1
    800058c4:	a891                	j	80005918 <sys_link+0x13c>
    iunlockput(ip);
    800058c6:	8526                	mv	a0,s1
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	526080e7          	jalr	1318(ra) # 80003dee <iunlockput>
    end_op();
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	d0e080e7          	jalr	-754(ra) # 800045de <end_op>
    return -1;
    800058d8:	57fd                	li	a5,-1
    800058da:	a83d                	j	80005918 <sys_link+0x13c>
    iunlockput(dp);
    800058dc:	854a                	mv	a0,s2
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	510080e7          	jalr	1296(ra) # 80003dee <iunlockput>
  ilock(ip);
    800058e6:	8526                	mv	a0,s1
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	2a4080e7          	jalr	676(ra) # 80003b8c <ilock>
  ip->nlink--;
    800058f0:	04a4d783          	lhu	a5,74(s1)
    800058f4:	37fd                	addiw	a5,a5,-1
    800058f6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058fa:	8526                	mv	a0,s1
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	1c6080e7          	jalr	454(ra) # 80003ac2 <iupdate>
  iunlockput(ip);
    80005904:	8526                	mv	a0,s1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	4e8080e7          	jalr	1256(ra) # 80003dee <iunlockput>
  end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	cd0080e7          	jalr	-816(ra) # 800045de <end_op>
  return -1;
    80005916:	57fd                	li	a5,-1
}
    80005918:	853e                	mv	a0,a5
    8000591a:	70b2                	ld	ra,296(sp)
    8000591c:	7412                	ld	s0,288(sp)
    8000591e:	64f2                	ld	s1,280(sp)
    80005920:	6952                	ld	s2,272(sp)
    80005922:	6155                	addi	sp,sp,304
    80005924:	8082                	ret

0000000080005926 <sys_unlink>:
{
    80005926:	7151                	addi	sp,sp,-240
    80005928:	f586                	sd	ra,232(sp)
    8000592a:	f1a2                	sd	s0,224(sp)
    8000592c:	eda6                	sd	s1,216(sp)
    8000592e:	e9ca                	sd	s2,208(sp)
    80005930:	e5ce                	sd	s3,200(sp)
    80005932:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005934:	08000613          	li	a2,128
    80005938:	f3040593          	addi	a1,s0,-208
    8000593c:	4501                	li	a0,0
    8000593e:	ffffd097          	auipc	ra,0xffffd
    80005942:	6d6080e7          	jalr	1750(ra) # 80003014 <argstr>
    80005946:	18054163          	bltz	a0,80005ac8 <sys_unlink+0x1a2>
  begin_op();
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	c14080e7          	jalr	-1004(ra) # 8000455e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005952:	fb040593          	addi	a1,s0,-80
    80005956:	f3040513          	addi	a0,s0,-208
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	a06080e7          	jalr	-1530(ra) # 80004360 <nameiparent>
    80005962:	84aa                	mv	s1,a0
    80005964:	c979                	beqz	a0,80005a3a <sys_unlink+0x114>
  ilock(dp);
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	226080e7          	jalr	550(ra) # 80003b8c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000596e:	00003597          	auipc	a1,0x3
    80005972:	daa58593          	addi	a1,a1,-598 # 80008718 <syscalls+0x2c0>
    80005976:	fb040513          	addi	a0,s0,-80
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	6dc080e7          	jalr	1756(ra) # 80004056 <namecmp>
    80005982:	14050a63          	beqz	a0,80005ad6 <sys_unlink+0x1b0>
    80005986:	00003597          	auipc	a1,0x3
    8000598a:	d9a58593          	addi	a1,a1,-614 # 80008720 <syscalls+0x2c8>
    8000598e:	fb040513          	addi	a0,s0,-80
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	6c4080e7          	jalr	1732(ra) # 80004056 <namecmp>
    8000599a:	12050e63          	beqz	a0,80005ad6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000599e:	f2c40613          	addi	a2,s0,-212
    800059a2:	fb040593          	addi	a1,s0,-80
    800059a6:	8526                	mv	a0,s1
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	6c8080e7          	jalr	1736(ra) # 80004070 <dirlookup>
    800059b0:	892a                	mv	s2,a0
    800059b2:	12050263          	beqz	a0,80005ad6 <sys_unlink+0x1b0>
  ilock(ip);
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	1d6080e7          	jalr	470(ra) # 80003b8c <ilock>
  if(ip->nlink < 1)
    800059be:	04a91783          	lh	a5,74(s2)
    800059c2:	08f05263          	blez	a5,80005a46 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059c6:	04491703          	lh	a4,68(s2)
    800059ca:	4785                	li	a5,1
    800059cc:	08f70563          	beq	a4,a5,80005a56 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059d0:	4641                	li	a2,16
    800059d2:	4581                	li	a1,0
    800059d4:	fc040513          	addi	a0,s0,-64
    800059d8:	ffffb097          	auipc	ra,0xffffb
    800059dc:	308080e7          	jalr	776(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059e0:	4741                	li	a4,16
    800059e2:	f2c42683          	lw	a3,-212(s0)
    800059e6:	fc040613          	addi	a2,s0,-64
    800059ea:	4581                	li	a1,0
    800059ec:	8526                	mv	a0,s1
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	54a080e7          	jalr	1354(ra) # 80003f38 <writei>
    800059f6:	47c1                	li	a5,16
    800059f8:	0af51563          	bne	a0,a5,80005aa2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059fc:	04491703          	lh	a4,68(s2)
    80005a00:	4785                	li	a5,1
    80005a02:	0af70863          	beq	a4,a5,80005ab2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	3e6080e7          	jalr	998(ra) # 80003dee <iunlockput>
  ip->nlink--;
    80005a10:	04a95783          	lhu	a5,74(s2)
    80005a14:	37fd                	addiw	a5,a5,-1
    80005a16:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a1a:	854a                	mv	a0,s2
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	0a6080e7          	jalr	166(ra) # 80003ac2 <iupdate>
  iunlockput(ip);
    80005a24:	854a                	mv	a0,s2
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	3c8080e7          	jalr	968(ra) # 80003dee <iunlockput>
  end_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	bb0080e7          	jalr	-1104(ra) # 800045de <end_op>
  return 0;
    80005a36:	4501                	li	a0,0
    80005a38:	a84d                	j	80005aea <sys_unlink+0x1c4>
    end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	ba4080e7          	jalr	-1116(ra) # 800045de <end_op>
    return -1;
    80005a42:	557d                	li	a0,-1
    80005a44:	a05d                	j	80005aea <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a46:	00003517          	auipc	a0,0x3
    80005a4a:	d0250513          	addi	a0,a0,-766 # 80008748 <syscalls+0x2f0>
    80005a4e:	ffffb097          	auipc	ra,0xffffb
    80005a52:	af0080e7          	jalr	-1296(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a56:	04c92703          	lw	a4,76(s2)
    80005a5a:	02000793          	li	a5,32
    80005a5e:	f6e7f9e3          	bgeu	a5,a4,800059d0 <sys_unlink+0xaa>
    80005a62:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a66:	4741                	li	a4,16
    80005a68:	86ce                	mv	a3,s3
    80005a6a:	f1840613          	addi	a2,s0,-232
    80005a6e:	4581                	li	a1,0
    80005a70:	854a                	mv	a0,s2
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	3ce080e7          	jalr	974(ra) # 80003e40 <readi>
    80005a7a:	47c1                	li	a5,16
    80005a7c:	00f51b63          	bne	a0,a5,80005a92 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a80:	f1845783          	lhu	a5,-232(s0)
    80005a84:	e7a1                	bnez	a5,80005acc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a86:	29c1                	addiw	s3,s3,16
    80005a88:	04c92783          	lw	a5,76(s2)
    80005a8c:	fcf9ede3          	bltu	s3,a5,80005a66 <sys_unlink+0x140>
    80005a90:	b781                	j	800059d0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a92:	00003517          	auipc	a0,0x3
    80005a96:	cce50513          	addi	a0,a0,-818 # 80008760 <syscalls+0x308>
    80005a9a:	ffffb097          	auipc	ra,0xffffb
    80005a9e:	aa4080e7          	jalr	-1372(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005aa2:	00003517          	auipc	a0,0x3
    80005aa6:	cd650513          	addi	a0,a0,-810 # 80008778 <syscalls+0x320>
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>
    dp->nlink--;
    80005ab2:	04a4d783          	lhu	a5,74(s1)
    80005ab6:	37fd                	addiw	a5,a5,-1
    80005ab8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005abc:	8526                	mv	a0,s1
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	004080e7          	jalr	4(ra) # 80003ac2 <iupdate>
    80005ac6:	b781                	j	80005a06 <sys_unlink+0xe0>
    return -1;
    80005ac8:	557d                	li	a0,-1
    80005aca:	a005                	j	80005aea <sys_unlink+0x1c4>
    iunlockput(ip);
    80005acc:	854a                	mv	a0,s2
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	320080e7          	jalr	800(ra) # 80003dee <iunlockput>
  iunlockput(dp);
    80005ad6:	8526                	mv	a0,s1
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	316080e7          	jalr	790(ra) # 80003dee <iunlockput>
  end_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	afe080e7          	jalr	-1282(ra) # 800045de <end_op>
  return -1;
    80005ae8:	557d                	li	a0,-1
}
    80005aea:	70ae                	ld	ra,232(sp)
    80005aec:	740e                	ld	s0,224(sp)
    80005aee:	64ee                	ld	s1,216(sp)
    80005af0:	694e                	ld	s2,208(sp)
    80005af2:	69ae                	ld	s3,200(sp)
    80005af4:	616d                	addi	sp,sp,240
    80005af6:	8082                	ret

0000000080005af8 <sys_open>:

uint64
sys_open(void)
{
    80005af8:	7131                	addi	sp,sp,-192
    80005afa:	fd06                	sd	ra,184(sp)
    80005afc:	f922                	sd	s0,176(sp)
    80005afe:	f526                	sd	s1,168(sp)
    80005b00:	f14a                	sd	s2,160(sp)
    80005b02:	ed4e                	sd	s3,152(sp)
    80005b04:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b06:	08000613          	li	a2,128
    80005b0a:	f5040593          	addi	a1,s0,-176
    80005b0e:	4501                	li	a0,0
    80005b10:	ffffd097          	auipc	ra,0xffffd
    80005b14:	504080e7          	jalr	1284(ra) # 80003014 <argstr>
    return -1;
    80005b18:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b1a:	0c054163          	bltz	a0,80005bdc <sys_open+0xe4>
    80005b1e:	f4c40593          	addi	a1,s0,-180
    80005b22:	4505                	li	a0,1
    80005b24:	ffffd097          	auipc	ra,0xffffd
    80005b28:	4ac080e7          	jalr	1196(ra) # 80002fd0 <argint>
    80005b2c:	0a054863          	bltz	a0,80005bdc <sys_open+0xe4>

  begin_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	a2e080e7          	jalr	-1490(ra) # 8000455e <begin_op>

  if(omode & O_CREATE){
    80005b38:	f4c42783          	lw	a5,-180(s0)
    80005b3c:	2007f793          	andi	a5,a5,512
    80005b40:	cbdd                	beqz	a5,80005bf6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b42:	4681                	li	a3,0
    80005b44:	4601                	li	a2,0
    80005b46:	4589                	li	a1,2
    80005b48:	f5040513          	addi	a0,s0,-176
    80005b4c:	00000097          	auipc	ra,0x0
    80005b50:	972080e7          	jalr	-1678(ra) # 800054be <create>
    80005b54:	892a                	mv	s2,a0
    if(ip == 0){
    80005b56:	c959                	beqz	a0,80005bec <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b58:	04491703          	lh	a4,68(s2)
    80005b5c:	478d                	li	a5,3
    80005b5e:	00f71763          	bne	a4,a5,80005b6c <sys_open+0x74>
    80005b62:	04695703          	lhu	a4,70(s2)
    80005b66:	47a5                	li	a5,9
    80005b68:	0ce7ec63          	bltu	a5,a4,80005c40 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	e02080e7          	jalr	-510(ra) # 8000496e <filealloc>
    80005b74:	89aa                	mv	s3,a0
    80005b76:	10050263          	beqz	a0,80005c7a <sys_open+0x182>
    80005b7a:	00000097          	auipc	ra,0x0
    80005b7e:	902080e7          	jalr	-1790(ra) # 8000547c <fdalloc>
    80005b82:	84aa                	mv	s1,a0
    80005b84:	0e054663          	bltz	a0,80005c70 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b88:	04491703          	lh	a4,68(s2)
    80005b8c:	478d                	li	a5,3
    80005b8e:	0cf70463          	beq	a4,a5,80005c56 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b92:	4789                	li	a5,2
    80005b94:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b98:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b9c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ba0:	f4c42783          	lw	a5,-180(s0)
    80005ba4:	0017c713          	xori	a4,a5,1
    80005ba8:	8b05                	andi	a4,a4,1
    80005baa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bae:	0037f713          	andi	a4,a5,3
    80005bb2:	00e03733          	snez	a4,a4
    80005bb6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bba:	4007f793          	andi	a5,a5,1024
    80005bbe:	c791                	beqz	a5,80005bca <sys_open+0xd2>
    80005bc0:	04491703          	lh	a4,68(s2)
    80005bc4:	4789                	li	a5,2
    80005bc6:	08f70f63          	beq	a4,a5,80005c64 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bca:	854a                	mv	a0,s2
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	082080e7          	jalr	130(ra) # 80003c4e <iunlock>
  end_op();
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	a0a080e7          	jalr	-1526(ra) # 800045de <end_op>

  return fd;
}
    80005bdc:	8526                	mv	a0,s1
    80005bde:	70ea                	ld	ra,184(sp)
    80005be0:	744a                	ld	s0,176(sp)
    80005be2:	74aa                	ld	s1,168(sp)
    80005be4:	790a                	ld	s2,160(sp)
    80005be6:	69ea                	ld	s3,152(sp)
    80005be8:	6129                	addi	sp,sp,192
    80005bea:	8082                	ret
      end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	9f2080e7          	jalr	-1550(ra) # 800045de <end_op>
      return -1;
    80005bf4:	b7e5                	j	80005bdc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bf6:	f5040513          	addi	a0,s0,-176
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	748080e7          	jalr	1864(ra) # 80004342 <namei>
    80005c02:	892a                	mv	s2,a0
    80005c04:	c905                	beqz	a0,80005c34 <sys_open+0x13c>
    ilock(ip);
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	f86080e7          	jalr	-122(ra) # 80003b8c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c0e:	04491703          	lh	a4,68(s2)
    80005c12:	4785                	li	a5,1
    80005c14:	f4f712e3          	bne	a4,a5,80005b58 <sys_open+0x60>
    80005c18:	f4c42783          	lw	a5,-180(s0)
    80005c1c:	dba1                	beqz	a5,80005b6c <sys_open+0x74>
      iunlockput(ip);
    80005c1e:	854a                	mv	a0,s2
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	1ce080e7          	jalr	462(ra) # 80003dee <iunlockput>
      end_op();
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	9b6080e7          	jalr	-1610(ra) # 800045de <end_op>
      return -1;
    80005c30:	54fd                	li	s1,-1
    80005c32:	b76d                	j	80005bdc <sys_open+0xe4>
      end_op();
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	9aa080e7          	jalr	-1622(ra) # 800045de <end_op>
      return -1;
    80005c3c:	54fd                	li	s1,-1
    80005c3e:	bf79                	j	80005bdc <sys_open+0xe4>
    iunlockput(ip);
    80005c40:	854a                	mv	a0,s2
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	1ac080e7          	jalr	428(ra) # 80003dee <iunlockput>
    end_op();
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	994080e7          	jalr	-1644(ra) # 800045de <end_op>
    return -1;
    80005c52:	54fd                	li	s1,-1
    80005c54:	b761                	j	80005bdc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c56:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c5a:	04691783          	lh	a5,70(s2)
    80005c5e:	02f99223          	sh	a5,36(s3)
    80005c62:	bf2d                	j	80005b9c <sys_open+0xa4>
    itrunc(ip);
    80005c64:	854a                	mv	a0,s2
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	034080e7          	jalr	52(ra) # 80003c9a <itrunc>
    80005c6e:	bfb1                	j	80005bca <sys_open+0xd2>
      fileclose(f);
    80005c70:	854e                	mv	a0,s3
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	db8080e7          	jalr	-584(ra) # 80004a2a <fileclose>
    iunlockput(ip);
    80005c7a:	854a                	mv	a0,s2
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	172080e7          	jalr	370(ra) # 80003dee <iunlockput>
    end_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	95a080e7          	jalr	-1702(ra) # 800045de <end_op>
    return -1;
    80005c8c:	54fd                	li	s1,-1
    80005c8e:	b7b9                	j	80005bdc <sys_open+0xe4>

0000000080005c90 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c90:	7175                	addi	sp,sp,-144
    80005c92:	e506                	sd	ra,136(sp)
    80005c94:	e122                	sd	s0,128(sp)
    80005c96:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	8c6080e7          	jalr	-1850(ra) # 8000455e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ca0:	08000613          	li	a2,128
    80005ca4:	f7040593          	addi	a1,s0,-144
    80005ca8:	4501                	li	a0,0
    80005caa:	ffffd097          	auipc	ra,0xffffd
    80005cae:	36a080e7          	jalr	874(ra) # 80003014 <argstr>
    80005cb2:	02054963          	bltz	a0,80005ce4 <sys_mkdir+0x54>
    80005cb6:	4681                	li	a3,0
    80005cb8:	4601                	li	a2,0
    80005cba:	4585                	li	a1,1
    80005cbc:	f7040513          	addi	a0,s0,-144
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	7fe080e7          	jalr	2046(ra) # 800054be <create>
    80005cc8:	cd11                	beqz	a0,80005ce4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	124080e7          	jalr	292(ra) # 80003dee <iunlockput>
  end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	90c080e7          	jalr	-1780(ra) # 800045de <end_op>
  return 0;
    80005cda:	4501                	li	a0,0
}
    80005cdc:	60aa                	ld	ra,136(sp)
    80005cde:	640a                	ld	s0,128(sp)
    80005ce0:	6149                	addi	sp,sp,144
    80005ce2:	8082                	ret
    end_op();
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	8fa080e7          	jalr	-1798(ra) # 800045de <end_op>
    return -1;
    80005cec:	557d                	li	a0,-1
    80005cee:	b7fd                	j	80005cdc <sys_mkdir+0x4c>

0000000080005cf0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cf0:	7135                	addi	sp,sp,-160
    80005cf2:	ed06                	sd	ra,152(sp)
    80005cf4:	e922                	sd	s0,144(sp)
    80005cf6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	866080e7          	jalr	-1946(ra) # 8000455e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d00:	08000613          	li	a2,128
    80005d04:	f7040593          	addi	a1,s0,-144
    80005d08:	4501                	li	a0,0
    80005d0a:	ffffd097          	auipc	ra,0xffffd
    80005d0e:	30a080e7          	jalr	778(ra) # 80003014 <argstr>
    80005d12:	04054a63          	bltz	a0,80005d66 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d16:	f6c40593          	addi	a1,s0,-148
    80005d1a:	4505                	li	a0,1
    80005d1c:	ffffd097          	auipc	ra,0xffffd
    80005d20:	2b4080e7          	jalr	692(ra) # 80002fd0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d24:	04054163          	bltz	a0,80005d66 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d28:	f6840593          	addi	a1,s0,-152
    80005d2c:	4509                	li	a0,2
    80005d2e:	ffffd097          	auipc	ra,0xffffd
    80005d32:	2a2080e7          	jalr	674(ra) # 80002fd0 <argint>
     argint(1, &major) < 0 ||
    80005d36:	02054863          	bltz	a0,80005d66 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d3a:	f6841683          	lh	a3,-152(s0)
    80005d3e:	f6c41603          	lh	a2,-148(s0)
    80005d42:	458d                	li	a1,3
    80005d44:	f7040513          	addi	a0,s0,-144
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	776080e7          	jalr	1910(ra) # 800054be <create>
     argint(2, &minor) < 0 ||
    80005d50:	c919                	beqz	a0,80005d66 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	09c080e7          	jalr	156(ra) # 80003dee <iunlockput>
  end_op();
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	884080e7          	jalr	-1916(ra) # 800045de <end_op>
  return 0;
    80005d62:	4501                	li	a0,0
    80005d64:	a031                	j	80005d70 <sys_mknod+0x80>
    end_op();
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	878080e7          	jalr	-1928(ra) # 800045de <end_op>
    return -1;
    80005d6e:	557d                	li	a0,-1
}
    80005d70:	60ea                	ld	ra,152(sp)
    80005d72:	644a                	ld	s0,144(sp)
    80005d74:	610d                	addi	sp,sp,160
    80005d76:	8082                	ret

0000000080005d78 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d78:	7135                	addi	sp,sp,-160
    80005d7a:	ed06                	sd	ra,152(sp)
    80005d7c:	e922                	sd	s0,144(sp)
    80005d7e:	e526                	sd	s1,136(sp)
    80005d80:	e14a                	sd	s2,128(sp)
    80005d82:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d84:	ffffc097          	auipc	ra,0xffffc
    80005d88:	b84080e7          	jalr	-1148(ra) # 80001908 <myproc>
    80005d8c:	892a                	mv	s2,a0
  
  begin_op();
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	7d0080e7          	jalr	2000(ra) # 8000455e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d96:	08000613          	li	a2,128
    80005d9a:	f6040593          	addi	a1,s0,-160
    80005d9e:	4501                	li	a0,0
    80005da0:	ffffd097          	auipc	ra,0xffffd
    80005da4:	274080e7          	jalr	628(ra) # 80003014 <argstr>
    80005da8:	04054b63          	bltz	a0,80005dfe <sys_chdir+0x86>
    80005dac:	f6040513          	addi	a0,s0,-160
    80005db0:	ffffe097          	auipc	ra,0xffffe
    80005db4:	592080e7          	jalr	1426(ra) # 80004342 <namei>
    80005db8:	84aa                	mv	s1,a0
    80005dba:	c131                	beqz	a0,80005dfe <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	dd0080e7          	jalr	-560(ra) # 80003b8c <ilock>
  if(ip->type != T_DIR){
    80005dc4:	04449703          	lh	a4,68(s1)
    80005dc8:	4785                	li	a5,1
    80005dca:	04f71063          	bne	a4,a5,80005e0a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dce:	8526                	mv	a0,s1
    80005dd0:	ffffe097          	auipc	ra,0xffffe
    80005dd4:	e7e080e7          	jalr	-386(ra) # 80003c4e <iunlock>
  iput(p->cwd);
    80005dd8:	17093503          	ld	a0,368(s2)
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	f6a080e7          	jalr	-150(ra) # 80003d46 <iput>
  end_op();
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	7fa080e7          	jalr	2042(ra) # 800045de <end_op>
  p->cwd = ip;
    80005dec:	16993823          	sd	s1,368(s2)
  return 0;
    80005df0:	4501                	li	a0,0
}
    80005df2:	60ea                	ld	ra,152(sp)
    80005df4:	644a                	ld	s0,144(sp)
    80005df6:	64aa                	ld	s1,136(sp)
    80005df8:	690a                	ld	s2,128(sp)
    80005dfa:	610d                	addi	sp,sp,160
    80005dfc:	8082                	ret
    end_op();
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	7e0080e7          	jalr	2016(ra) # 800045de <end_op>
    return -1;
    80005e06:	557d                	li	a0,-1
    80005e08:	b7ed                	j	80005df2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e0a:	8526                	mv	a0,s1
    80005e0c:	ffffe097          	auipc	ra,0xffffe
    80005e10:	fe2080e7          	jalr	-30(ra) # 80003dee <iunlockput>
    end_op();
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	7ca080e7          	jalr	1994(ra) # 800045de <end_op>
    return -1;
    80005e1c:	557d                	li	a0,-1
    80005e1e:	bfd1                	j	80005df2 <sys_chdir+0x7a>

0000000080005e20 <sys_exec>:

uint64
sys_exec(void)
{
    80005e20:	7145                	addi	sp,sp,-464
    80005e22:	e786                	sd	ra,456(sp)
    80005e24:	e3a2                	sd	s0,448(sp)
    80005e26:	ff26                	sd	s1,440(sp)
    80005e28:	fb4a                	sd	s2,432(sp)
    80005e2a:	f74e                	sd	s3,424(sp)
    80005e2c:	f352                	sd	s4,416(sp)
    80005e2e:	ef56                	sd	s5,408(sp)
    80005e30:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e32:	08000613          	li	a2,128
    80005e36:	f4040593          	addi	a1,s0,-192
    80005e3a:	4501                	li	a0,0
    80005e3c:	ffffd097          	auipc	ra,0xffffd
    80005e40:	1d8080e7          	jalr	472(ra) # 80003014 <argstr>
    return -1;
    80005e44:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e46:	0c054a63          	bltz	a0,80005f1a <sys_exec+0xfa>
    80005e4a:	e3840593          	addi	a1,s0,-456
    80005e4e:	4505                	li	a0,1
    80005e50:	ffffd097          	auipc	ra,0xffffd
    80005e54:	1a2080e7          	jalr	418(ra) # 80002ff2 <argaddr>
    80005e58:	0c054163          	bltz	a0,80005f1a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e5c:	10000613          	li	a2,256
    80005e60:	4581                	li	a1,0
    80005e62:	e4040513          	addi	a0,s0,-448
    80005e66:	ffffb097          	auipc	ra,0xffffb
    80005e6a:	e7a080e7          	jalr	-390(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e6e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e72:	89a6                	mv	s3,s1
    80005e74:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e76:	02000a13          	li	s4,32
    80005e7a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e7e:	00391513          	slli	a0,s2,0x3
    80005e82:	e3040593          	addi	a1,s0,-464
    80005e86:	e3843783          	ld	a5,-456(s0)
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	0aa080e7          	jalr	170(ra) # 80002f36 <fetchaddr>
    80005e94:	02054a63          	bltz	a0,80005ec8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e98:	e3043783          	ld	a5,-464(s0)
    80005e9c:	c3b9                	beqz	a5,80005ee2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e9e:	ffffb097          	auipc	ra,0xffffb
    80005ea2:	c56080e7          	jalr	-938(ra) # 80000af4 <kalloc>
    80005ea6:	85aa                	mv	a1,a0
    80005ea8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005eac:	cd11                	beqz	a0,80005ec8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005eae:	6605                	lui	a2,0x1
    80005eb0:	e3043503          	ld	a0,-464(s0)
    80005eb4:	ffffd097          	auipc	ra,0xffffd
    80005eb8:	0d4080e7          	jalr	212(ra) # 80002f88 <fetchstr>
    80005ebc:	00054663          	bltz	a0,80005ec8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ec0:	0905                	addi	s2,s2,1
    80005ec2:	09a1                	addi	s3,s3,8
    80005ec4:	fb491be3          	bne	s2,s4,80005e7a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec8:	10048913          	addi	s2,s1,256
    80005ecc:	6088                	ld	a0,0(s1)
    80005ece:	c529                	beqz	a0,80005f18 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ed0:	ffffb097          	auipc	ra,0xffffb
    80005ed4:	b28080e7          	jalr	-1240(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed8:	04a1                	addi	s1,s1,8
    80005eda:	ff2499e3          	bne	s1,s2,80005ecc <sys_exec+0xac>
  return -1;
    80005ede:	597d                	li	s2,-1
    80005ee0:	a82d                	j	80005f1a <sys_exec+0xfa>
      argv[i] = 0;
    80005ee2:	0a8e                	slli	s5,s5,0x3
    80005ee4:	fc040793          	addi	a5,s0,-64
    80005ee8:	9abe                	add	s5,s5,a5
    80005eea:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005eee:	e4040593          	addi	a1,s0,-448
    80005ef2:	f4040513          	addi	a0,s0,-192
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	194080e7          	jalr	404(ra) # 8000508a <exec>
    80005efe:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f00:	10048993          	addi	s3,s1,256
    80005f04:	6088                	ld	a0,0(s1)
    80005f06:	c911                	beqz	a0,80005f1a <sys_exec+0xfa>
    kfree(argv[i]);
    80005f08:	ffffb097          	auipc	ra,0xffffb
    80005f0c:	af0080e7          	jalr	-1296(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f10:	04a1                	addi	s1,s1,8
    80005f12:	ff3499e3          	bne	s1,s3,80005f04 <sys_exec+0xe4>
    80005f16:	a011                	j	80005f1a <sys_exec+0xfa>
  return -1;
    80005f18:	597d                	li	s2,-1
}
    80005f1a:	854a                	mv	a0,s2
    80005f1c:	60be                	ld	ra,456(sp)
    80005f1e:	641e                	ld	s0,448(sp)
    80005f20:	74fa                	ld	s1,440(sp)
    80005f22:	795a                	ld	s2,432(sp)
    80005f24:	79ba                	ld	s3,424(sp)
    80005f26:	7a1a                	ld	s4,416(sp)
    80005f28:	6afa                	ld	s5,408(sp)
    80005f2a:	6179                	addi	sp,sp,464
    80005f2c:	8082                	ret

0000000080005f2e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f2e:	7139                	addi	sp,sp,-64
    80005f30:	fc06                	sd	ra,56(sp)
    80005f32:	f822                	sd	s0,48(sp)
    80005f34:	f426                	sd	s1,40(sp)
    80005f36:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	9d0080e7          	jalr	-1584(ra) # 80001908 <myproc>
    80005f40:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f42:	fd840593          	addi	a1,s0,-40
    80005f46:	4501                	li	a0,0
    80005f48:	ffffd097          	auipc	ra,0xffffd
    80005f4c:	0aa080e7          	jalr	170(ra) # 80002ff2 <argaddr>
    return -1;
    80005f50:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f52:	0e054063          	bltz	a0,80006032 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f56:	fc840593          	addi	a1,s0,-56
    80005f5a:	fd040513          	addi	a0,s0,-48
    80005f5e:	fffff097          	auipc	ra,0xfffff
    80005f62:	dfc080e7          	jalr	-516(ra) # 80004d5a <pipealloc>
    return -1;
    80005f66:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f68:	0c054563          	bltz	a0,80006032 <sys_pipe+0x104>
  fd0 = -1;
    80005f6c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f70:	fd043503          	ld	a0,-48(s0)
    80005f74:	fffff097          	auipc	ra,0xfffff
    80005f78:	508080e7          	jalr	1288(ra) # 8000547c <fdalloc>
    80005f7c:	fca42223          	sw	a0,-60(s0)
    80005f80:	08054c63          	bltz	a0,80006018 <sys_pipe+0xea>
    80005f84:	fc843503          	ld	a0,-56(s0)
    80005f88:	fffff097          	auipc	ra,0xfffff
    80005f8c:	4f4080e7          	jalr	1268(ra) # 8000547c <fdalloc>
    80005f90:	fca42023          	sw	a0,-64(s0)
    80005f94:	06054863          	bltz	a0,80006004 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f98:	4691                	li	a3,4
    80005f9a:	fc440613          	addi	a2,s0,-60
    80005f9e:	fd843583          	ld	a1,-40(s0)
    80005fa2:	78a8                	ld	a0,112(s1)
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	6ce080e7          	jalr	1742(ra) # 80001672 <copyout>
    80005fac:	02054063          	bltz	a0,80005fcc <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fb0:	4691                	li	a3,4
    80005fb2:	fc040613          	addi	a2,s0,-64
    80005fb6:	fd843583          	ld	a1,-40(s0)
    80005fba:	0591                	addi	a1,a1,4
    80005fbc:	78a8                	ld	a0,112(s1)
    80005fbe:	ffffb097          	auipc	ra,0xffffb
    80005fc2:	6b4080e7          	jalr	1716(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fc6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fc8:	06055563          	bgez	a0,80006032 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fcc:	fc442783          	lw	a5,-60(s0)
    80005fd0:	07f9                	addi	a5,a5,30
    80005fd2:	078e                	slli	a5,a5,0x3
    80005fd4:	97a6                	add	a5,a5,s1
    80005fd6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fda:	fc042503          	lw	a0,-64(s0)
    80005fde:	0579                	addi	a0,a0,30
    80005fe0:	050e                	slli	a0,a0,0x3
    80005fe2:	9526                	add	a0,a0,s1
    80005fe4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fe8:	fd043503          	ld	a0,-48(s0)
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	a3e080e7          	jalr	-1474(ra) # 80004a2a <fileclose>
    fileclose(wf);
    80005ff4:	fc843503          	ld	a0,-56(s0)
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	a32080e7          	jalr	-1486(ra) # 80004a2a <fileclose>
    return -1;
    80006000:	57fd                	li	a5,-1
    80006002:	a805                	j	80006032 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006004:	fc442783          	lw	a5,-60(s0)
    80006008:	0007c863          	bltz	a5,80006018 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000600c:	01e78513          	addi	a0,a5,30
    80006010:	050e                	slli	a0,a0,0x3
    80006012:	9526                	add	a0,a0,s1
    80006014:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006018:	fd043503          	ld	a0,-48(s0)
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	a0e080e7          	jalr	-1522(ra) # 80004a2a <fileclose>
    fileclose(wf);
    80006024:	fc843503          	ld	a0,-56(s0)
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	a02080e7          	jalr	-1534(ra) # 80004a2a <fileclose>
    return -1;
    80006030:	57fd                	li	a5,-1
}
    80006032:	853e                	mv	a0,a5
    80006034:	70e2                	ld	ra,56(sp)
    80006036:	7442                	ld	s0,48(sp)
    80006038:	74a2                	ld	s1,40(sp)
    8000603a:	6121                	addi	sp,sp,64
    8000603c:	8082                	ret
	...

0000000080006040 <kernelvec>:
    80006040:	7111                	addi	sp,sp,-256
    80006042:	e006                	sd	ra,0(sp)
    80006044:	e40a                	sd	sp,8(sp)
    80006046:	e80e                	sd	gp,16(sp)
    80006048:	ec12                	sd	tp,24(sp)
    8000604a:	f016                	sd	t0,32(sp)
    8000604c:	f41a                	sd	t1,40(sp)
    8000604e:	f81e                	sd	t2,48(sp)
    80006050:	fc22                	sd	s0,56(sp)
    80006052:	e0a6                	sd	s1,64(sp)
    80006054:	e4aa                	sd	a0,72(sp)
    80006056:	e8ae                	sd	a1,80(sp)
    80006058:	ecb2                	sd	a2,88(sp)
    8000605a:	f0b6                	sd	a3,96(sp)
    8000605c:	f4ba                	sd	a4,104(sp)
    8000605e:	f8be                	sd	a5,112(sp)
    80006060:	fcc2                	sd	a6,120(sp)
    80006062:	e146                	sd	a7,128(sp)
    80006064:	e54a                	sd	s2,136(sp)
    80006066:	e94e                	sd	s3,144(sp)
    80006068:	ed52                	sd	s4,152(sp)
    8000606a:	f156                	sd	s5,160(sp)
    8000606c:	f55a                	sd	s6,168(sp)
    8000606e:	f95e                	sd	s7,176(sp)
    80006070:	fd62                	sd	s8,184(sp)
    80006072:	e1e6                	sd	s9,192(sp)
    80006074:	e5ea                	sd	s10,200(sp)
    80006076:	e9ee                	sd	s11,208(sp)
    80006078:	edf2                	sd	t3,216(sp)
    8000607a:	f1f6                	sd	t4,224(sp)
    8000607c:	f5fa                	sd	t5,232(sp)
    8000607e:	f9fe                	sd	t6,240(sp)
    80006080:	d83fc0ef          	jal	ra,80002e02 <kerneltrap>
    80006084:	6082                	ld	ra,0(sp)
    80006086:	6122                	ld	sp,8(sp)
    80006088:	61c2                	ld	gp,16(sp)
    8000608a:	7282                	ld	t0,32(sp)
    8000608c:	7322                	ld	t1,40(sp)
    8000608e:	73c2                	ld	t2,48(sp)
    80006090:	7462                	ld	s0,56(sp)
    80006092:	6486                	ld	s1,64(sp)
    80006094:	6526                	ld	a0,72(sp)
    80006096:	65c6                	ld	a1,80(sp)
    80006098:	6666                	ld	a2,88(sp)
    8000609a:	7686                	ld	a3,96(sp)
    8000609c:	7726                	ld	a4,104(sp)
    8000609e:	77c6                	ld	a5,112(sp)
    800060a0:	7866                	ld	a6,120(sp)
    800060a2:	688a                	ld	a7,128(sp)
    800060a4:	692a                	ld	s2,136(sp)
    800060a6:	69ca                	ld	s3,144(sp)
    800060a8:	6a6a                	ld	s4,152(sp)
    800060aa:	7a8a                	ld	s5,160(sp)
    800060ac:	7b2a                	ld	s6,168(sp)
    800060ae:	7bca                	ld	s7,176(sp)
    800060b0:	7c6a                	ld	s8,184(sp)
    800060b2:	6c8e                	ld	s9,192(sp)
    800060b4:	6d2e                	ld	s10,200(sp)
    800060b6:	6dce                	ld	s11,208(sp)
    800060b8:	6e6e                	ld	t3,216(sp)
    800060ba:	7e8e                	ld	t4,224(sp)
    800060bc:	7f2e                	ld	t5,232(sp)
    800060be:	7fce                	ld	t6,240(sp)
    800060c0:	6111                	addi	sp,sp,256
    800060c2:	10200073          	sret
    800060c6:	00000013          	nop
    800060ca:	00000013          	nop
    800060ce:	0001                	nop

00000000800060d0 <timervec>:
    800060d0:	34051573          	csrrw	a0,mscratch,a0
    800060d4:	e10c                	sd	a1,0(a0)
    800060d6:	e510                	sd	a2,8(a0)
    800060d8:	e914                	sd	a3,16(a0)
    800060da:	6d0c                	ld	a1,24(a0)
    800060dc:	7110                	ld	a2,32(a0)
    800060de:	6194                	ld	a3,0(a1)
    800060e0:	96b2                	add	a3,a3,a2
    800060e2:	e194                	sd	a3,0(a1)
    800060e4:	4589                	li	a1,2
    800060e6:	14459073          	csrw	sip,a1
    800060ea:	6914                	ld	a3,16(a0)
    800060ec:	6510                	ld	a2,8(a0)
    800060ee:	610c                	ld	a1,0(a0)
    800060f0:	34051573          	csrrw	a0,mscratch,a0
    800060f4:	30200073          	mret
	...

00000000800060fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060fa:	1141                	addi	sp,sp,-16
    800060fc:	e422                	sd	s0,8(sp)
    800060fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006100:	0c0007b7          	lui	a5,0xc000
    80006104:	4705                	li	a4,1
    80006106:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006108:	c3d8                	sw	a4,4(a5)
}
    8000610a:	6422                	ld	s0,8(sp)
    8000610c:	0141                	addi	sp,sp,16
    8000610e:	8082                	ret

0000000080006110 <plicinithart>:

void
plicinithart(void)
{
    80006110:	1141                	addi	sp,sp,-16
    80006112:	e406                	sd	ra,8(sp)
    80006114:	e022                	sd	s0,0(sp)
    80006116:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006118:	ffffb097          	auipc	ra,0xffffb
    8000611c:	7bc080e7          	jalr	1980(ra) # 800018d4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006120:	0085171b          	slliw	a4,a0,0x8
    80006124:	0c0027b7          	lui	a5,0xc002
    80006128:	97ba                	add	a5,a5,a4
    8000612a:	40200713          	li	a4,1026
    8000612e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006132:	00d5151b          	slliw	a0,a0,0xd
    80006136:	0c2017b7          	lui	a5,0xc201
    8000613a:	953e                	add	a0,a0,a5
    8000613c:	00052023          	sw	zero,0(a0)
}
    80006140:	60a2                	ld	ra,8(sp)
    80006142:	6402                	ld	s0,0(sp)
    80006144:	0141                	addi	sp,sp,16
    80006146:	8082                	ret

0000000080006148 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006148:	1141                	addi	sp,sp,-16
    8000614a:	e406                	sd	ra,8(sp)
    8000614c:	e022                	sd	s0,0(sp)
    8000614e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006150:	ffffb097          	auipc	ra,0xffffb
    80006154:	784080e7          	jalr	1924(ra) # 800018d4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006158:	00d5179b          	slliw	a5,a0,0xd
    8000615c:	0c201537          	lui	a0,0xc201
    80006160:	953e                	add	a0,a0,a5
  return irq;
}
    80006162:	4148                	lw	a0,4(a0)
    80006164:	60a2                	ld	ra,8(sp)
    80006166:	6402                	ld	s0,0(sp)
    80006168:	0141                	addi	sp,sp,16
    8000616a:	8082                	ret

000000008000616c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000616c:	1101                	addi	sp,sp,-32
    8000616e:	ec06                	sd	ra,24(sp)
    80006170:	e822                	sd	s0,16(sp)
    80006172:	e426                	sd	s1,8(sp)
    80006174:	1000                	addi	s0,sp,32
    80006176:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006178:	ffffb097          	auipc	ra,0xffffb
    8000617c:	75c080e7          	jalr	1884(ra) # 800018d4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006180:	00d5151b          	slliw	a0,a0,0xd
    80006184:	0c2017b7          	lui	a5,0xc201
    80006188:	97aa                	add	a5,a5,a0
    8000618a:	c3c4                	sw	s1,4(a5)
}
    8000618c:	60e2                	ld	ra,24(sp)
    8000618e:	6442                	ld	s0,16(sp)
    80006190:	64a2                	ld	s1,8(sp)
    80006192:	6105                	addi	sp,sp,32
    80006194:	8082                	ret

0000000080006196 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006196:	1141                	addi	sp,sp,-16
    80006198:	e406                	sd	ra,8(sp)
    8000619a:	e022                	sd	s0,0(sp)
    8000619c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000619e:	479d                	li	a5,7
    800061a0:	06a7c963          	blt	a5,a0,80006212 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061a4:	0001d797          	auipc	a5,0x1d
    800061a8:	e5c78793          	addi	a5,a5,-420 # 80023000 <disk>
    800061ac:	00a78733          	add	a4,a5,a0
    800061b0:	6789                	lui	a5,0x2
    800061b2:	97ba                	add	a5,a5,a4
    800061b4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061b8:	e7ad                	bnez	a5,80006222 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061ba:	00451793          	slli	a5,a0,0x4
    800061be:	0001f717          	auipc	a4,0x1f
    800061c2:	e4270713          	addi	a4,a4,-446 # 80025000 <disk+0x2000>
    800061c6:	6314                	ld	a3,0(a4)
    800061c8:	96be                	add	a3,a3,a5
    800061ca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061ce:	6314                	ld	a3,0(a4)
    800061d0:	96be                	add	a3,a3,a5
    800061d2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061d6:	6314                	ld	a3,0(a4)
    800061d8:	96be                	add	a3,a3,a5
    800061da:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061de:	6318                	ld	a4,0(a4)
    800061e0:	97ba                	add	a5,a5,a4
    800061e2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061e6:	0001d797          	auipc	a5,0x1d
    800061ea:	e1a78793          	addi	a5,a5,-486 # 80023000 <disk>
    800061ee:	97aa                	add	a5,a5,a0
    800061f0:	6509                	lui	a0,0x2
    800061f2:	953e                	add	a0,a0,a5
    800061f4:	4785                	li	a5,1
    800061f6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061fa:	0001f517          	auipc	a0,0x1f
    800061fe:	e1e50513          	addi	a0,a0,-482 # 80025018 <disk+0x2018>
    80006202:	ffffc097          	auipc	ra,0xffffc
    80006206:	22a080e7          	jalr	554(ra) # 8000242c <wakeup>
}
    8000620a:	60a2                	ld	ra,8(sp)
    8000620c:	6402                	ld	s0,0(sp)
    8000620e:	0141                	addi	sp,sp,16
    80006210:	8082                	ret
    panic("free_desc 1");
    80006212:	00002517          	auipc	a0,0x2
    80006216:	57650513          	addi	a0,a0,1398 # 80008788 <syscalls+0x330>
    8000621a:	ffffa097          	auipc	ra,0xffffa
    8000621e:	324080e7          	jalr	804(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006222:	00002517          	auipc	a0,0x2
    80006226:	57650513          	addi	a0,a0,1398 # 80008798 <syscalls+0x340>
    8000622a:	ffffa097          	auipc	ra,0xffffa
    8000622e:	314080e7          	jalr	788(ra) # 8000053e <panic>

0000000080006232 <virtio_disk_init>:
{
    80006232:	1101                	addi	sp,sp,-32
    80006234:	ec06                	sd	ra,24(sp)
    80006236:	e822                	sd	s0,16(sp)
    80006238:	e426                	sd	s1,8(sp)
    8000623a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000623c:	00002597          	auipc	a1,0x2
    80006240:	56c58593          	addi	a1,a1,1388 # 800087a8 <syscalls+0x350>
    80006244:	0001f517          	auipc	a0,0x1f
    80006248:	ee450513          	addi	a0,a0,-284 # 80025128 <disk+0x2128>
    8000624c:	ffffb097          	auipc	ra,0xffffb
    80006250:	908080e7          	jalr	-1784(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006254:	100017b7          	lui	a5,0x10001
    80006258:	4398                	lw	a4,0(a5)
    8000625a:	2701                	sext.w	a4,a4
    8000625c:	747277b7          	lui	a5,0x74727
    80006260:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006264:	0ef71163          	bne	a4,a5,80006346 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006268:	100017b7          	lui	a5,0x10001
    8000626c:	43dc                	lw	a5,4(a5)
    8000626e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006270:	4705                	li	a4,1
    80006272:	0ce79a63          	bne	a5,a4,80006346 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006276:	100017b7          	lui	a5,0x10001
    8000627a:	479c                	lw	a5,8(a5)
    8000627c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000627e:	4709                	li	a4,2
    80006280:	0ce79363          	bne	a5,a4,80006346 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006284:	100017b7          	lui	a5,0x10001
    80006288:	47d8                	lw	a4,12(a5)
    8000628a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000628c:	554d47b7          	lui	a5,0x554d4
    80006290:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006294:	0af71963          	bne	a4,a5,80006346 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006298:	100017b7          	lui	a5,0x10001
    8000629c:	4705                	li	a4,1
    8000629e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a0:	470d                	li	a4,3
    800062a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062a6:	c7ffe737          	lui	a4,0xc7ffe
    800062aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800062ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062b0:	2701                	sext.w	a4,a4
    800062b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062b4:	472d                	li	a4,11
    800062b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062b8:	473d                	li	a4,15
    800062ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062bc:	6705                	lui	a4,0x1
    800062be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062c4:	5bdc                	lw	a5,52(a5)
    800062c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062c8:	c7d9                	beqz	a5,80006356 <virtio_disk_init+0x124>
  if(max < NUM)
    800062ca:	471d                	li	a4,7
    800062cc:	08f77d63          	bgeu	a4,a5,80006366 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062d0:	100014b7          	lui	s1,0x10001
    800062d4:	47a1                	li	a5,8
    800062d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062d8:	6609                	lui	a2,0x2
    800062da:	4581                	li	a1,0
    800062dc:	0001d517          	auipc	a0,0x1d
    800062e0:	d2450513          	addi	a0,a0,-732 # 80023000 <disk>
    800062e4:	ffffb097          	auipc	ra,0xffffb
    800062e8:	9fc080e7          	jalr	-1540(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062ec:	0001d717          	auipc	a4,0x1d
    800062f0:	d1470713          	addi	a4,a4,-748 # 80023000 <disk>
    800062f4:	00c75793          	srli	a5,a4,0xc
    800062f8:	2781                	sext.w	a5,a5
    800062fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062fc:	0001f797          	auipc	a5,0x1f
    80006300:	d0478793          	addi	a5,a5,-764 # 80025000 <disk+0x2000>
    80006304:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006306:	0001d717          	auipc	a4,0x1d
    8000630a:	d7a70713          	addi	a4,a4,-646 # 80023080 <disk+0x80>
    8000630e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006310:	0001e717          	auipc	a4,0x1e
    80006314:	cf070713          	addi	a4,a4,-784 # 80024000 <disk+0x1000>
    80006318:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000631a:	4705                	li	a4,1
    8000631c:	00e78c23          	sb	a4,24(a5)
    80006320:	00e78ca3          	sb	a4,25(a5)
    80006324:	00e78d23          	sb	a4,26(a5)
    80006328:	00e78da3          	sb	a4,27(a5)
    8000632c:	00e78e23          	sb	a4,28(a5)
    80006330:	00e78ea3          	sb	a4,29(a5)
    80006334:	00e78f23          	sb	a4,30(a5)
    80006338:	00e78fa3          	sb	a4,31(a5)
}
    8000633c:	60e2                	ld	ra,24(sp)
    8000633e:	6442                	ld	s0,16(sp)
    80006340:	64a2                	ld	s1,8(sp)
    80006342:	6105                	addi	sp,sp,32
    80006344:	8082                	ret
    panic("could not find virtio disk");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	47250513          	addi	a0,a0,1138 # 800087b8 <syscalls+0x360>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006356:	00002517          	auipc	a0,0x2
    8000635a:	48250513          	addi	a0,a0,1154 # 800087d8 <syscalls+0x380>
    8000635e:	ffffa097          	auipc	ra,0xffffa
    80006362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006366:	00002517          	auipc	a0,0x2
    8000636a:	49250513          	addi	a0,a0,1170 # 800087f8 <syscalls+0x3a0>
    8000636e:	ffffa097          	auipc	ra,0xffffa
    80006372:	1d0080e7          	jalr	464(ra) # 8000053e <panic>

0000000080006376 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006376:	7159                	addi	sp,sp,-112
    80006378:	f486                	sd	ra,104(sp)
    8000637a:	f0a2                	sd	s0,96(sp)
    8000637c:	eca6                	sd	s1,88(sp)
    8000637e:	e8ca                	sd	s2,80(sp)
    80006380:	e4ce                	sd	s3,72(sp)
    80006382:	e0d2                	sd	s4,64(sp)
    80006384:	fc56                	sd	s5,56(sp)
    80006386:	f85a                	sd	s6,48(sp)
    80006388:	f45e                	sd	s7,40(sp)
    8000638a:	f062                	sd	s8,32(sp)
    8000638c:	ec66                	sd	s9,24(sp)
    8000638e:	e86a                	sd	s10,16(sp)
    80006390:	1880                	addi	s0,sp,112
    80006392:	892a                	mv	s2,a0
    80006394:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006396:	00c52c83          	lw	s9,12(a0)
    8000639a:	001c9c9b          	slliw	s9,s9,0x1
    8000639e:	1c82                	slli	s9,s9,0x20
    800063a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063a4:	0001f517          	auipc	a0,0x1f
    800063a8:	d8450513          	addi	a0,a0,-636 # 80025128 <disk+0x2128>
    800063ac:	ffffb097          	auipc	ra,0xffffb
    800063b0:	838080e7          	jalr	-1992(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800063b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800063b8:	0001db97          	auipc	s7,0x1d
    800063bc:	c48b8b93          	addi	s7,s7,-952 # 80023000 <disk>
    800063c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800063c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800063c4:	8a4e                	mv	s4,s3
    800063c6:	a051                	j	8000644a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800063c8:	00fb86b3          	add	a3,s7,a5
    800063cc:	96da                	add	a3,a3,s6
    800063ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063d4:	0207c563          	bltz	a5,800063fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063d8:	2485                	addiw	s1,s1,1
    800063da:	0711                	addi	a4,a4,4
    800063dc:	25548063          	beq	s1,s5,8000661c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063e2:	0001f697          	auipc	a3,0x1f
    800063e6:	c3668693          	addi	a3,a3,-970 # 80025018 <disk+0x2018>
    800063ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063ec:	0006c583          	lbu	a1,0(a3)
    800063f0:	fde1                	bnez	a1,800063c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063f2:	2785                	addiw	a5,a5,1
    800063f4:	0685                	addi	a3,a3,1
    800063f6:	ff879be3          	bne	a5,s8,800063ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063fa:	57fd                	li	a5,-1
    800063fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800063fe:	02905a63          	blez	s1,80006432 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006402:	f9042503          	lw	a0,-112(s0)
    80006406:	00000097          	auipc	ra,0x0
    8000640a:	d90080e7          	jalr	-624(ra) # 80006196 <free_desc>
      for(int j = 0; j < i; j++)
    8000640e:	4785                	li	a5,1
    80006410:	0297d163          	bge	a5,s1,80006432 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006414:	f9442503          	lw	a0,-108(s0)
    80006418:	00000097          	auipc	ra,0x0
    8000641c:	d7e080e7          	jalr	-642(ra) # 80006196 <free_desc>
      for(int j = 0; j < i; j++)
    80006420:	4789                	li	a5,2
    80006422:	0097d863          	bge	a5,s1,80006432 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006426:	f9842503          	lw	a0,-104(s0)
    8000642a:	00000097          	auipc	ra,0x0
    8000642e:	d6c080e7          	jalr	-660(ra) # 80006196 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006432:	0001f597          	auipc	a1,0x1f
    80006436:	cf658593          	addi	a1,a1,-778 # 80025128 <disk+0x2128>
    8000643a:	0001f517          	auipc	a0,0x1f
    8000643e:	bde50513          	addi	a0,a0,-1058 # 80025018 <disk+0x2018>
    80006442:	ffffc097          	auipc	ra,0xffffc
    80006446:	c78080e7          	jalr	-904(ra) # 800020ba <sleep>
  for(int i = 0; i < 3; i++){
    8000644a:	f9040713          	addi	a4,s0,-112
    8000644e:	84ce                	mv	s1,s3
    80006450:	bf41                	j	800063e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006452:	20058713          	addi	a4,a1,512
    80006456:	00471693          	slli	a3,a4,0x4
    8000645a:	0001d717          	auipc	a4,0x1d
    8000645e:	ba670713          	addi	a4,a4,-1114 # 80023000 <disk>
    80006462:	9736                	add	a4,a4,a3
    80006464:	4685                	li	a3,1
    80006466:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000646a:	20058713          	addi	a4,a1,512
    8000646e:	00471693          	slli	a3,a4,0x4
    80006472:	0001d717          	auipc	a4,0x1d
    80006476:	b8e70713          	addi	a4,a4,-1138 # 80023000 <disk>
    8000647a:	9736                	add	a4,a4,a3
    8000647c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006480:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006484:	7679                	lui	a2,0xffffe
    80006486:	963e                	add	a2,a2,a5
    80006488:	0001f697          	auipc	a3,0x1f
    8000648c:	b7868693          	addi	a3,a3,-1160 # 80025000 <disk+0x2000>
    80006490:	6298                	ld	a4,0(a3)
    80006492:	9732                	add	a4,a4,a2
    80006494:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006496:	6298                	ld	a4,0(a3)
    80006498:	9732                	add	a4,a4,a2
    8000649a:	4541                	li	a0,16
    8000649c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000649e:	6298                	ld	a4,0(a3)
    800064a0:	9732                	add	a4,a4,a2
    800064a2:	4505                	li	a0,1
    800064a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800064a8:	f9442703          	lw	a4,-108(s0)
    800064ac:	6288                	ld	a0,0(a3)
    800064ae:	962a                	add	a2,a2,a0
    800064b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064b4:	0712                	slli	a4,a4,0x4
    800064b6:	6290                	ld	a2,0(a3)
    800064b8:	963a                	add	a2,a2,a4
    800064ba:	05890513          	addi	a0,s2,88
    800064be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800064c0:	6294                	ld	a3,0(a3)
    800064c2:	96ba                	add	a3,a3,a4
    800064c4:	40000613          	li	a2,1024
    800064c8:	c690                	sw	a2,8(a3)
  if(write)
    800064ca:	140d0063          	beqz	s10,8000660a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064ce:	0001f697          	auipc	a3,0x1f
    800064d2:	b326b683          	ld	a3,-1230(a3) # 80025000 <disk+0x2000>
    800064d6:	96ba                	add	a3,a3,a4
    800064d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064dc:	0001d817          	auipc	a6,0x1d
    800064e0:	b2480813          	addi	a6,a6,-1244 # 80023000 <disk>
    800064e4:	0001f517          	auipc	a0,0x1f
    800064e8:	b1c50513          	addi	a0,a0,-1252 # 80025000 <disk+0x2000>
    800064ec:	6114                	ld	a3,0(a0)
    800064ee:	96ba                	add	a3,a3,a4
    800064f0:	00c6d603          	lhu	a2,12(a3)
    800064f4:	00166613          	ori	a2,a2,1
    800064f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064fc:	f9842683          	lw	a3,-104(s0)
    80006500:	6110                	ld	a2,0(a0)
    80006502:	9732                	add	a4,a4,a2
    80006504:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006508:	20058613          	addi	a2,a1,512
    8000650c:	0612                	slli	a2,a2,0x4
    8000650e:	9642                	add	a2,a2,a6
    80006510:	577d                	li	a4,-1
    80006512:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006516:	00469713          	slli	a4,a3,0x4
    8000651a:	6114                	ld	a3,0(a0)
    8000651c:	96ba                	add	a3,a3,a4
    8000651e:	03078793          	addi	a5,a5,48
    80006522:	97c2                	add	a5,a5,a6
    80006524:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006526:	611c                	ld	a5,0(a0)
    80006528:	97ba                	add	a5,a5,a4
    8000652a:	4685                	li	a3,1
    8000652c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000652e:	611c                	ld	a5,0(a0)
    80006530:	97ba                	add	a5,a5,a4
    80006532:	4809                	li	a6,2
    80006534:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006538:	611c                	ld	a5,0(a0)
    8000653a:	973e                	add	a4,a4,a5
    8000653c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006540:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006544:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006548:	6518                	ld	a4,8(a0)
    8000654a:	00275783          	lhu	a5,2(a4)
    8000654e:	8b9d                	andi	a5,a5,7
    80006550:	0786                	slli	a5,a5,0x1
    80006552:	97ba                	add	a5,a5,a4
    80006554:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006558:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000655c:	6518                	ld	a4,8(a0)
    8000655e:	00275783          	lhu	a5,2(a4)
    80006562:	2785                	addiw	a5,a5,1
    80006564:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006568:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000656c:	100017b7          	lui	a5,0x10001
    80006570:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006574:	00492703          	lw	a4,4(s2)
    80006578:	4785                	li	a5,1
    8000657a:	02f71163          	bne	a4,a5,8000659c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000657e:	0001f997          	auipc	s3,0x1f
    80006582:	baa98993          	addi	s3,s3,-1110 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006586:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006588:	85ce                	mv	a1,s3
    8000658a:	854a                	mv	a0,s2
    8000658c:	ffffc097          	auipc	ra,0xffffc
    80006590:	b2e080e7          	jalr	-1234(ra) # 800020ba <sleep>
  while(b->disk == 1) {
    80006594:	00492783          	lw	a5,4(s2)
    80006598:	fe9788e3          	beq	a5,s1,80006588 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000659c:	f9042903          	lw	s2,-112(s0)
    800065a0:	20090793          	addi	a5,s2,512
    800065a4:	00479713          	slli	a4,a5,0x4
    800065a8:	0001d797          	auipc	a5,0x1d
    800065ac:	a5878793          	addi	a5,a5,-1448 # 80023000 <disk>
    800065b0:	97ba                	add	a5,a5,a4
    800065b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065b6:	0001f997          	auipc	s3,0x1f
    800065ba:	a4a98993          	addi	s3,s3,-1462 # 80025000 <disk+0x2000>
    800065be:	00491713          	slli	a4,s2,0x4
    800065c2:	0009b783          	ld	a5,0(s3)
    800065c6:	97ba                	add	a5,a5,a4
    800065c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065cc:	854a                	mv	a0,s2
    800065ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065d2:	00000097          	auipc	ra,0x0
    800065d6:	bc4080e7          	jalr	-1084(ra) # 80006196 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065da:	8885                	andi	s1,s1,1
    800065dc:	f0ed                	bnez	s1,800065be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065de:	0001f517          	auipc	a0,0x1f
    800065e2:	b4a50513          	addi	a0,a0,-1206 # 80025128 <disk+0x2128>
    800065e6:	ffffa097          	auipc	ra,0xffffa
    800065ea:	6b2080e7          	jalr	1714(ra) # 80000c98 <release>
}
    800065ee:	70a6                	ld	ra,104(sp)
    800065f0:	7406                	ld	s0,96(sp)
    800065f2:	64e6                	ld	s1,88(sp)
    800065f4:	6946                	ld	s2,80(sp)
    800065f6:	69a6                	ld	s3,72(sp)
    800065f8:	6a06                	ld	s4,64(sp)
    800065fa:	7ae2                	ld	s5,56(sp)
    800065fc:	7b42                	ld	s6,48(sp)
    800065fe:	7ba2                	ld	s7,40(sp)
    80006600:	7c02                	ld	s8,32(sp)
    80006602:	6ce2                	ld	s9,24(sp)
    80006604:	6d42                	ld	s10,16(sp)
    80006606:	6165                	addi	sp,sp,112
    80006608:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000660a:	0001f697          	auipc	a3,0x1f
    8000660e:	9f66b683          	ld	a3,-1546(a3) # 80025000 <disk+0x2000>
    80006612:	96ba                	add	a3,a3,a4
    80006614:	4609                	li	a2,2
    80006616:	00c69623          	sh	a2,12(a3)
    8000661a:	b5c9                	j	800064dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000661c:	f9042583          	lw	a1,-112(s0)
    80006620:	20058793          	addi	a5,a1,512
    80006624:	0792                	slli	a5,a5,0x4
    80006626:	0001d517          	auipc	a0,0x1d
    8000662a:	a8250513          	addi	a0,a0,-1406 # 800230a8 <disk+0xa8>
    8000662e:	953e                	add	a0,a0,a5
  if(write)
    80006630:	e20d11e3          	bnez	s10,80006452 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006634:	20058713          	addi	a4,a1,512
    80006638:	00471693          	slli	a3,a4,0x4
    8000663c:	0001d717          	auipc	a4,0x1d
    80006640:	9c470713          	addi	a4,a4,-1596 # 80023000 <disk>
    80006644:	9736                	add	a4,a4,a3
    80006646:	0a072423          	sw	zero,168(a4)
    8000664a:	b505                	j	8000646a <virtio_disk_rw+0xf4>

000000008000664c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000664c:	1101                	addi	sp,sp,-32
    8000664e:	ec06                	sd	ra,24(sp)
    80006650:	e822                	sd	s0,16(sp)
    80006652:	e426                	sd	s1,8(sp)
    80006654:	e04a                	sd	s2,0(sp)
    80006656:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006658:	0001f517          	auipc	a0,0x1f
    8000665c:	ad050513          	addi	a0,a0,-1328 # 80025128 <disk+0x2128>
    80006660:	ffffa097          	auipc	ra,0xffffa
    80006664:	584080e7          	jalr	1412(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006668:	10001737          	lui	a4,0x10001
    8000666c:	533c                	lw	a5,96(a4)
    8000666e:	8b8d                	andi	a5,a5,3
    80006670:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006672:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006676:	0001f797          	auipc	a5,0x1f
    8000667a:	98a78793          	addi	a5,a5,-1654 # 80025000 <disk+0x2000>
    8000667e:	6b94                	ld	a3,16(a5)
    80006680:	0207d703          	lhu	a4,32(a5)
    80006684:	0026d783          	lhu	a5,2(a3)
    80006688:	06f70163          	beq	a4,a5,800066ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000668c:	0001d917          	auipc	s2,0x1d
    80006690:	97490913          	addi	s2,s2,-1676 # 80023000 <disk>
    80006694:	0001f497          	auipc	s1,0x1f
    80006698:	96c48493          	addi	s1,s1,-1684 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000669c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066a0:	6898                	ld	a4,16(s1)
    800066a2:	0204d783          	lhu	a5,32(s1)
    800066a6:	8b9d                	andi	a5,a5,7
    800066a8:	078e                	slli	a5,a5,0x3
    800066aa:	97ba                	add	a5,a5,a4
    800066ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066ae:	20078713          	addi	a4,a5,512
    800066b2:	0712                	slli	a4,a4,0x4
    800066b4:	974a                	add	a4,a4,s2
    800066b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066ba:	e731                	bnez	a4,80006706 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066bc:	20078793          	addi	a5,a5,512
    800066c0:	0792                	slli	a5,a5,0x4
    800066c2:	97ca                	add	a5,a5,s2
    800066c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066ca:	ffffc097          	auipc	ra,0xffffc
    800066ce:	d62080e7          	jalr	-670(ra) # 8000242c <wakeup>

    disk.used_idx += 1;
    800066d2:	0204d783          	lhu	a5,32(s1)
    800066d6:	2785                	addiw	a5,a5,1
    800066d8:	17c2                	slli	a5,a5,0x30
    800066da:	93c1                	srli	a5,a5,0x30
    800066dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066e0:	6898                	ld	a4,16(s1)
    800066e2:	00275703          	lhu	a4,2(a4)
    800066e6:	faf71be3          	bne	a4,a5,8000669c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066ea:	0001f517          	auipc	a0,0x1f
    800066ee:	a3e50513          	addi	a0,a0,-1474 # 80025128 <disk+0x2128>
    800066f2:	ffffa097          	auipc	ra,0xffffa
    800066f6:	5a6080e7          	jalr	1446(ra) # 80000c98 <release>
}
    800066fa:	60e2                	ld	ra,24(sp)
    800066fc:	6442                	ld	s0,16(sp)
    800066fe:	64a2                	ld	s1,8(sp)
    80006700:	6902                	ld	s2,0(sp)
    80006702:	6105                	addi	sp,sp,32
    80006704:	8082                	ret
      panic("virtio_disk_intr status");
    80006706:	00002517          	auipc	a0,0x2
    8000670a:	11250513          	addi	a0,a0,274 # 80008818 <syscalls+0x3c0>
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	e30080e7          	jalr	-464(ra) # 8000053e <panic>

0000000080006716 <cas>:
    80006716:	100522af          	lr.w	t0,(a0)
    8000671a:	00b29563          	bne	t0,a1,80006724 <fail>
    8000671e:	18c5252f          	sc.w	a0,a2,(a0)
    80006722:	8082                	ret

0000000080006724 <fail>:
    80006724:	4505                	li	a0,1
    80006726:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
