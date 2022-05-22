
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	04c78793          	addi	a5,a5,76 # 800060b0 <timervec>
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
    800001d8:	ed4080e7          	jalr	-300(ra) # 800020a8 <sleep>
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
    8000044a:	fcc080e7          	jalr	-52(ra) # 80002412 <wakeup>
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
    800008a4:	b72080e7          	jalr	-1166(ra) # 80002412 <wakeup>
    
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
    80000930:	77c080e7          	jalr	1916(ra) # 800020a8 <sleep>
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
    80000ed8:	c78080e7          	jalr	-904(ra) # 80002b4c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	214080e7          	jalr	532(ra) # 800060f0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	b20080e7          	jalr	-1248(ra) # 80002a04 <scheduler>
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
    80000f48:	fb2080e7          	jalr	-78(ra) # 80001ef6 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	bd8080e7          	jalr	-1064(ra) # 80002b24 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	bf8080e7          	jalr	-1032(ra) # 80002b4c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	17e080e7          	jalr	382(ra) # 800060da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	18c080e7          	jalr	396(ra) # 800060f0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	36c080e7          	jalr	876(ra) # 800032d8 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	9fc080e7          	jalr	-1540(ra) # 80003970 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9a6080e7          	jalr	-1626(ra) # 80004922 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	28e080e7          	jalr	654(ra) # 80006212 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	872080e7          	jalr	-1934(ra) # 800027fe <userinit>
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
    80001964:	ec07a783          	lw	a5,-320(a5) # 80008820 <first.1708>
    80001968:	eb89                	bnez	a5,8000197a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000196a:	00001097          	auipc	ra,0x1
    8000196e:	1fa080e7          	jalr	506(ra) # 80002b64 <usertrapret>
}
    80001972:	60a2                	ld	ra,8(sp)
    80001974:	6402                	ld	s0,0(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret
    first = 0;
    8000197a:	00007797          	auipc	a5,0x7
    8000197e:	ea07a323          	sw	zero,-346(a5) # 80008820 <first.1708>
    fsinit(ROOTDEV);
    80001982:	4505                	li	a0,1
    80001984:	00002097          	auipc	ra,0x2
    80001988:	f6c080e7          	jalr	-148(ra) # 800038f0 <fsinit>
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
    8000199e:	e9690913          	addi	s2,s2,-362 # 80008830 <nextpid>
    800019a2:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid , pid , pid+1));
    800019a6:	0014861b          	addiw	a2,s1,1
    800019aa:	85a6                	mv	a1,s1
    800019ac:	854a                	mv	a0,s2
    800019ae:	00005097          	auipc	ra,0x5
    800019b2:	d48080e7          	jalr	-696(ra) # 800066f6 <cas>
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
    80001bb0:	f0e080e7          	jalr	-242(ra) # 80002aba <swtch>
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
    80001d88:	53cb8b93          	addi	s7,s7,1340 # 800082c0 <states.1747>
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
    80001e2c:	0080                	addi	s0,sp,64
    80001e2e:	84aa                	mv	s1,a0
    80001e30:	8aae                	mv	s5,a1
    80001e32:	8932                	mv	s2,a2
  acquire(lock);
    80001e34:	8532                	mv	a0,a2
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	dae080e7          	jalr	-594(ra) # 80000be4 <acquire>
  //acquire to next_proc? <-
  if(*curr_proc_index == -1){
    80001e3e:	409c                	lw	a5,0(s1)
    80001e40:	577d                	li	a4,-1
    80001e42:	08e78e63          	beq	a5,a4,80001ede <add_to_list+0xc2>
    *curr_proc_index = next_proc->proc_index;
    next_proc->next_proc_index = -1;
    release(lock);
    return;
  }
  struct proc* curr_node = &proc[*curr_proc_index];
    80001e46:	18800513          	li	a0,392
    80001e4a:	02a787b3          	mul	a5,a5,a0
    80001e4e:	00010517          	auipc	a0,0x10
    80001e52:	9ca50513          	addi	a0,a0,-1590 # 80011818 <proc>
    80001e56:	00a784b3          	add	s1,a5,a0
  acquire(&curr_node->proc_lock);
    80001e5a:	04078793          	addi	a5,a5,64
    80001e5e:	953e                	add	a0,a0,a5
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	d84080e7          	jalr	-636(ra) # 80000be4 <acquire>
  release(lock);
    80001e68:	854a                	mv	a0,s2
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e2e080e7          	jalr	-466(ra) # 80000c98 <release>
  // result = add_proc_to_list_rec(&proc[*curr_proc_index], next_proc);
  // return result;
  while(curr_node->next_proc_index != -1){
    80001e72:	5c88                	lw	a0,56(s1)
    80001e74:	57fd                	li	a5,-1
    80001e76:	02f50f63          	beq	a0,a5,80001eb4 <add_to_list+0x98>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80001e7a:	18800993          	li	s3,392
    80001e7e:	00010917          	auipc	s2,0x10
    80001e82:	99a90913          	addi	s2,s2,-1638 # 80011818 <proc>
  while(curr_node->next_proc_index != -1){
    80001e86:	5a7d                	li	s4,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80001e88:	03350533          	mul	a0,a0,s3
    80001e8c:	04050513          	addi	a0,a0,64
    80001e90:	954a                	add	a0,a0,s2
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d52080e7          	jalr	-686(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    80001e9a:	04048513          	addi	a0,s1,64
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	dfa080e7          	jalr	-518(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    80001ea6:	5c84                	lw	s1,56(s1)
    80001ea8:	033484b3          	mul	s1,s1,s3
    80001eac:	94ca                	add	s1,s1,s2
  while(curr_node->next_proc_index != -1){
    80001eae:	5c88                	lw	a0,56(s1)
    80001eb0:	fd451ce3          	bne	a0,s4,80001e88 <add_to_list+0x6c>
  }

  //result = cas(&curr_node->next_proc_index, -1, next_proc->proc_index) == 0;
  curr_node->next_proc_index = next_proc->proc_index;
    80001eb4:	03caa783          	lw	a5,60(s5)
    80001eb8:	dc9c                	sw	a5,56(s1)
  next_proc->next_proc_index = -1;
    80001eba:	57fd                	li	a5,-1
    80001ebc:	02faac23          	sw	a5,56(s5)
  release(&curr_node->proc_lock);
    80001ec0:	04048513          	addi	a0,s1,64
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	dd4080e7          	jalr	-556(ra) # 80000c98 <release>

}
    80001ecc:	70e2                	ld	ra,56(sp)
    80001ece:	7442                	ld	s0,48(sp)
    80001ed0:	74a2                	ld	s1,40(sp)
    80001ed2:	7902                	ld	s2,32(sp)
    80001ed4:	69e2                	ld	s3,24(sp)
    80001ed6:	6a42                	ld	s4,16(sp)
    80001ed8:	6aa2                	ld	s5,8(sp)
    80001eda:	6121                	addi	sp,sp,64
    80001edc:	8082                	ret
    *curr_proc_index = next_proc->proc_index;
    80001ede:	03caa783          	lw	a5,60(s5)
    80001ee2:	c09c                	sw	a5,0(s1)
    next_proc->next_proc_index = -1;
    80001ee4:	57fd                	li	a5,-1
    80001ee6:	02faac23          	sw	a5,56(s5)
    release(lock);
    80001eea:	854a                	mv	a0,s2
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	dac080e7          	jalr	-596(ra) # 80000c98 <release>
    return;
    80001ef4:	bfe1                	j	80001ecc <add_to_list+0xb0>

0000000080001ef6 <procinit>:
{
    80001ef6:	711d                	addi	sp,sp,-96
    80001ef8:	ec86                	sd	ra,88(sp)
    80001efa:	e8a2                	sd	s0,80(sp)
    80001efc:	e4a6                	sd	s1,72(sp)
    80001efe:	e0ca                	sd	s2,64(sp)
    80001f00:	fc4e                	sd	s3,56(sp)
    80001f02:	f852                	sd	s4,48(sp)
    80001f04:	f456                	sd	s5,40(sp)
    80001f06:	f05a                	sd	s6,32(sp)
    80001f08:	ec5e                	sd	s7,24(sp)
    80001f0a:	e862                	sd	s8,16(sp)
    80001f0c:	e466                	sd	s9,8(sp)
    80001f0e:	e06a                	sd	s10,0(sp)
    80001f10:	1080                	addi	s0,sp,96
  initlock(&pid_lock, "nextpid");
    80001f12:	00006597          	auipc	a1,0x6
    80001f16:	32e58593          	addi	a1,a1,814 # 80008240 <digits+0x200>
    80001f1a:	00010517          	auipc	a0,0x10
    80001f1e:	88650513          	addi	a0,a0,-1914 # 800117a0 <pid_lock>
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	c32080e7          	jalr	-974(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001f2a:	00006597          	auipc	a1,0x6
    80001f2e:	31e58593          	addi	a1,a1,798 # 80008248 <digits+0x208>
    80001f32:	00010517          	auipc	a0,0x10
    80001f36:	88650513          	addi	a0,a0,-1914 # 800117b8 <wait_lock>
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	c1a080e7          	jalr	-998(ra) # 80000b54 <initlock>
  int index = -1;
    80001f42:	597d                	li	s2,-1
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001f44:	00010497          	auipc	s1,0x10
    80001f48:	8d448493          	addi	s1,s1,-1836 # 80011818 <proc>
      initlock(&p->lock, "proc");
    80001f4c:	00006d17          	auipc	s10,0x6
    80001f50:	30cd0d13          	addi	s10,s10,780 # 80008258 <digits+0x218>
      p->kstack = KSTACK((int) (p - proc));
    80001f54:	8ca6                	mv	s9,s1
    80001f56:	00006c17          	auipc	s8,0x6
    80001f5a:	0aac0c13          	addi	s8,s8,170 # 80008000 <etext>
    80001f5e:	040009b7          	lui	s3,0x4000
    80001f62:	19fd                	addi	s3,s3,-1
    80001f64:	09b2                	slli	s3,s3,0xc
      p->next_proc_index = -1;
    80001f66:	5bfd                	li	s7,-1
      add_to_list(&unused_head, p, &lock_unused_list);
    80001f68:	00010b17          	auipc	s6,0x10
    80001f6c:	868b0b13          	addi	s6,s6,-1944 # 800117d0 <lock_unused_list>
    80001f70:	00007a97          	auipc	s5,0x7
    80001f74:	8bca8a93          	addi	s5,s5,-1860 # 8000882c <unused_head>
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001f78:	00016a17          	auipc	s4,0x16
    80001f7c:	aa0a0a13          	addi	s4,s4,-1376 # 80017a18 <tickslock>
      initlock(&p->lock, "proc");
    80001f80:	85ea                	mv	a1,s10
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	bd0080e7          	jalr	-1072(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001f8c:	419487b3          	sub	a5,s1,s9
    80001f90:	878d                	srai	a5,a5,0x3
    80001f92:	000c3703          	ld	a4,0(s8)
    80001f96:	02e787b3          	mul	a5,a5,a4
    80001f9a:	2785                	addiw	a5,a5,1
    80001f9c:	00d7979b          	slliw	a5,a5,0xd
    80001fa0:	40f987b3          	sub	a5,s3,a5
    80001fa4:	f0bc                	sd	a5,96(s1)
      p->proc_index = index;
    80001fa6:	0324ae23          	sw	s2,60(s1)
      p->next_proc_index = -1;
    80001faa:	0374ac23          	sw	s7,56(s1)
      add_to_list(&unused_head, p, &lock_unused_list);
    80001fae:	865a                	mv	a2,s6
    80001fb0:	85a6                	mv	a1,s1
    80001fb2:	8556                	mv	a0,s5
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	e68080e7          	jalr	-408(ra) # 80001e1c <add_to_list>
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001fbc:	18848493          	addi	s1,s1,392
    80001fc0:	2905                	addiw	s2,s2,1
    80001fc2:	fb449fe3          	bne	s1,s4,80001f80 <procinit+0x8a>
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001fc6:	0000f797          	auipc	a5,0xf
    80001fca:	2da78793          	addi	a5,a5,730 # 800112a0 <cpus>
      c->runnable_head = -1;
    80001fce:	56fd                	li	a3,-1
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001fd0:	0000f717          	auipc	a4,0xf
    80001fd4:	7d070713          	addi	a4,a4,2000 # 800117a0 <pid_lock>
      c->runnable_head = -1;
    80001fd8:	08d7a023          	sw	a3,128(a5)
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001fdc:	0a078793          	addi	a5,a5,160
    80001fe0:	fee79ce3          	bne	a5,a4,80001fd8 <procinit+0xe2>
}
    80001fe4:	60e6                	ld	ra,88(sp)
    80001fe6:	6446                	ld	s0,80(sp)
    80001fe8:	64a6                	ld	s1,72(sp)
    80001fea:	6906                	ld	s2,64(sp)
    80001fec:	79e2                	ld	s3,56(sp)
    80001fee:	7a42                	ld	s4,48(sp)
    80001ff0:	7aa2                	ld	s5,40(sp)
    80001ff2:	7b02                	ld	s6,32(sp)
    80001ff4:	6be2                	ld	s7,24(sp)
    80001ff6:	6c42                	ld	s8,16(sp)
    80001ff8:	6ca2                	ld	s9,8(sp)
    80001ffa:	6d02                	ld	s10,0(sp)
    80001ffc:	6125                	addi	sp,sp,96
    80001ffe:	8082                	ret

0000000080002000 <yield>:
{
    80002000:	1101                	addi	sp,sp,-32
    80002002:	ec06                	sd	ra,24(sp)
    80002004:	e822                	sd	s0,16(sp)
    80002006:	e426                	sd	s1,8(sp)
    80002008:	e04a                	sd	s2,0(sp)
    8000200a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	8fc080e7          	jalr	-1796(ra) # 80001908 <myproc>
    80002014:	84aa                	mv	s1,a0
  struct cpu *c = &cpus[p->cpu_num];
    80002016:	03452903          	lw	s2,52(a0)
  acquire(&p->lock);
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	bca080e7          	jalr	-1078(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002022:	478d                	li	a5,3
    80002024:	cc9c                	sw	a5,24(s1)
  add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    80002026:	00291793          	slli	a5,s2,0x2
    8000202a:	97ca                	add	a5,a5,s2
    8000202c:	0796                	slli	a5,a5,0x5
    8000202e:	0000f517          	auipc	a0,0xf
    80002032:	27250513          	addi	a0,a0,626 # 800112a0 <cpus>
    80002036:	08878613          	addi	a2,a5,136
    8000203a:	08078793          	addi	a5,a5,128
    8000203e:	962a                	add	a2,a2,a0
    80002040:	85a6                	mv	a1,s1
    80002042:	953e                	add	a0,a0,a5
    80002044:	00000097          	auipc	ra,0x0
    80002048:	dd8080e7          	jalr	-552(ra) # 80001e1c <add_to_list>
  sched();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	adc080e7          	jalr	-1316(ra) # 80001b28 <sched>
  release(&p->lock);
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	c42080e7          	jalr	-958(ra) # 80000c98 <release>
}
    8000205e:	60e2                	ld	ra,24(sp)
    80002060:	6442                	ld	s0,16(sp)
    80002062:	64a2                	ld	s1,8(sp)
    80002064:	6902                	ld	s2,0(sp)
    80002066:	6105                	addi	sp,sp,32
    80002068:	8082                	ret

000000008000206a <set_cpu>:
{
    8000206a:	1101                	addi	sp,sp,-32
    8000206c:	ec06                	sd	ra,24(sp)
    8000206e:	e822                	sd	s0,16(sp)
    80002070:	e426                	sd	s1,8(sp)
    80002072:	1000                	addi	s0,sp,32
    80002074:	84aa                	mv	s1,a0
    struct proc* p = myproc();
    80002076:	00000097          	auipc	ra,0x0
    8000207a:	892080e7          	jalr	-1902(ra) # 80001908 <myproc>
    if(cas(&p->cpu_num, curr_cpu, cpu_num) !=0)
    8000207e:	8626                	mv	a2,s1
    80002080:	594c                	lw	a1,52(a0)
    80002082:	03450513          	addi	a0,a0,52
    80002086:	00004097          	auipc	ra,0x4
    8000208a:	670080e7          	jalr	1648(ra) # 800066f6 <cas>
    8000208e:	e919                	bnez	a0,800020a4 <set_cpu+0x3a>
    yield();
    80002090:	00000097          	auipc	ra,0x0
    80002094:	f70080e7          	jalr	-144(ra) # 80002000 <yield>
    return cpu_num;
    80002098:	8526                	mv	a0,s1
}
    8000209a:	60e2                	ld	ra,24(sp)
    8000209c:	6442                	ld	s0,16(sp)
    8000209e:	64a2                	ld	s1,8(sp)
    800020a0:	6105                	addi	sp,sp,32
    800020a2:	8082                	ret
        return -1;
    800020a4:	557d                	li	a0,-1
    800020a6:	bfd5                	j	8000209a <set_cpu+0x30>

00000000800020a8 <sleep>:
{
    800020a8:	7179                	addi	sp,sp,-48
    800020aa:	f406                	sd	ra,40(sp)
    800020ac:	f022                	sd	s0,32(sp)
    800020ae:	ec26                	sd	s1,24(sp)
    800020b0:	e84a                	sd	s2,16(sp)
    800020b2:	e44e                	sd	s3,8(sp)
    800020b4:	1800                	addi	s0,sp,48
    800020b6:	89aa                	mv	s3,a0
    800020b8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	84e080e7          	jalr	-1970(ra) # 80001908 <myproc>
    800020c2:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b20080e7          	jalr	-1248(ra) # 80000be4 <acquire>
  add_to_list(&sleeping_head, p, &lock_sleeping_list);
    800020cc:	0000f617          	auipc	a2,0xf
    800020d0:	71c60613          	addi	a2,a2,1820 # 800117e8 <lock_sleeping_list>
    800020d4:	85a6                	mv	a1,s1
    800020d6:	00006517          	auipc	a0,0x6
    800020da:	75250513          	addi	a0,a0,1874 # 80008828 <sleeping_head>
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	d3e080e7          	jalr	-706(ra) # 80001e1c <add_to_list>
  release(lk);
    800020e6:	854a                	mv	a0,s2
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	bb0080e7          	jalr	-1104(ra) # 80000c98 <release>
  p->chan = chan;
    800020f0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020f4:	4789                	li	a5,2
    800020f6:	cc9c                	sw	a5,24(s1)
  sched();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	a30080e7          	jalr	-1488(ra) # 80001b28 <sched>
  p->chan = 0;
    80002100:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    80002104:	8526                	mv	a0,s1
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b92080e7          	jalr	-1134(ra) # 80000c98 <release>
  acquire(lk);
    8000210e:	854a                	mv	a0,s2
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	ad4080e7          	jalr	-1324(ra) # 80000be4 <acquire>
}
    80002118:	70a2                	ld	ra,40(sp)
    8000211a:	7402                	ld	s0,32(sp)
    8000211c:	64e2                	ld	s1,24(sp)
    8000211e:	6942                	ld	s2,16(sp)
    80002120:	69a2                	ld	s3,8(sp)
    80002122:	6145                	addi	sp,sp,48
    80002124:	8082                	ret

0000000080002126 <remove_from_list>:

int remove_from_list(int* curr_proc_index, struct proc* proc_to_remove, struct spinlock* lock) {
    80002126:	7139                	addi	sp,sp,-64
    80002128:	fc06                	sd	ra,56(sp)
    8000212a:	f822                	sd	s0,48(sp)
    8000212c:	f426                	sd	s1,40(sp)
    8000212e:	f04a                	sd	s2,32(sp)
    80002130:	ec4e                	sd	s3,24(sp)
    80002132:	e852                	sd	s4,16(sp)
    80002134:	e456                	sd	s5,8(sp)
    80002136:	e05a                	sd	s6,0(sp)
    80002138:	0080                	addi	s0,sp,64
    8000213a:	84aa                	mv	s1,a0
    8000213c:	8a2e                	mv	s4,a1
    8000213e:	8932                	mv	s2,a2
  acquire(lock);
    80002140:	8532                	mv	a0,a2
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	aa2080e7          	jalr	-1374(ra) # 80000be4 <acquire>
  if(*curr_proc_index == -1) 
    8000214a:	0004a983          	lw	s3,0(s1)
    8000214e:	57fd                	li	a5,-1
    80002150:	0af98c63          	beq	s3,a5,80002208 <remove_from_list+0xe2>
  {
      release(lock);
      return -1;
  }
  acquire(&proc_to_remove->proc_lock);
    80002154:	040a0b13          	addi	s6,s4,64
    80002158:	855a                	mv	a0,s6
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	a8a080e7          	jalr	-1398(ra) # 80000be4 <acquire>

  if(*curr_proc_index == proc_to_remove->proc_index){
    80002162:	409c                	lw	a5,0(s1)
    80002164:	03ca2703          	lw	a4,60(s4)
    80002168:	0ae78663          	beq	a5,a4,80002214 <remove_from_list+0xee>
      release(lock);
      return 1;
  }
  // release(&proc_to_remove->proc_lock);
  
  struct proc* curr_node = &proc[*curr_proc_index];
    8000216c:	18800513          	li	a0,392
    80002170:	02a787b3          	mul	a5,a5,a0
    80002174:	0000f517          	auipc	a0,0xf
    80002178:	6a450513          	addi	a0,a0,1700 # 80011818 <proc>
    8000217c:	00a784b3          	add	s1,a5,a0
  acquire(&curr_node->proc_lock);
    80002180:	04078793          	addi	a5,a5,64
    80002184:	953e                	add	a0,a0,a5
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	a5e080e7          	jalr	-1442(ra) # 80000be4 <acquire>
  release(lock);
    8000218e:	854a                	mv	a0,s2
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b08080e7          	jalr	-1272(ra) # 80000c98 <release>
  
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002198:	5c88                	lw	a0,56(s1)
    8000219a:	57fd                	li	a5,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    8000219c:	18800993          	li	s3,392
    800021a0:	0000f917          	auipc	s2,0xf
    800021a4:	67890913          	addi	s2,s2,1656 # 80011818 <proc>
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    800021a8:	5afd                	li	s5,-1
    800021aa:	02f50c63          	beq	a0,a5,800021e2 <remove_from_list+0xbc>
    800021ae:	03ca2783          	lw	a5,60(s4)
    800021b2:	08a78163          	beq	a5,a0,80002234 <remove_from_list+0x10e>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    800021b6:	03350533          	mul	a0,a0,s3
    800021ba:	04050513          	addi	a0,a0,64
    800021be:	954a                	add	a0,a0,s2
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a24080e7          	jalr	-1500(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    800021c8:	04048513          	addi	a0,s1,64
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	acc080e7          	jalr	-1332(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    800021d4:	5c84                	lw	s1,56(s1)
    800021d6:	033484b3          	mul	s1,s1,s3
    800021da:	94ca                	add	s1,s1,s2
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    800021dc:	5c88                	lw	a0,56(s1)
    800021de:	fd5518e3          	bne	a0,s5,800021ae <remove_from_list+0x88>
  if(curr_node->next_proc_index != -1){
    release(&curr_node->proc_lock);
    return -1;
  }

  curr_node->next_proc_index = proc_to_remove->next_proc_index;
    800021e2:	038a2783          	lw	a5,56(s4)
    800021e6:	dc9c                	sw	a5,56(s1)
  proc_to_remove->next_proc_index = -1;
    800021e8:	57fd                	li	a5,-1
    800021ea:	02fa2c23          	sw	a5,56(s4)
  release(&proc_to_remove->proc_lock);
    800021ee:	855a                	mv	a0,s6
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	aa8080e7          	jalr	-1368(ra) # 80000c98 <release>
  release(&curr_node->proc_lock);
    800021f8:	04048513          	addi	a0,s1,64
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	a9c080e7          	jalr	-1380(ra) # 80000c98 <release>
  return 1;
    80002204:	4985                	li	s3,1
    80002206:	a089                	j	80002248 <remove_from_list+0x122>
      release(lock);
    80002208:	854a                	mv	a0,s2
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a8e080e7          	jalr	-1394(ra) # 80000c98 <release>
      return -1;
    80002212:	a81d                	j	80002248 <remove_from_list+0x122>
      *curr_proc_index = proc_to_remove->proc_index;
    80002214:	c098                	sw	a4,0(s1)
      proc_to_remove->next_proc_index = -1;
    80002216:	57fd                	li	a5,-1
    80002218:	02fa2c23          	sw	a5,56(s4)
      release(&proc_to_remove->proc_lock);
    8000221c:	855a                	mv	a0,s6
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	a7a080e7          	jalr	-1414(ra) # 80000c98 <release>
      release(lock);
    80002226:	854a                	mv	a0,s2
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a70080e7          	jalr	-1424(ra) # 80000c98 <release>
      return 1;
    80002230:	4985                	li	s3,1
    80002232:	a819                	j	80002248 <remove_from_list+0x122>
  if(curr_node->next_proc_index != -1){
    80002234:	57fd                	li	a5,-1
    80002236:	faf506e3          	beq	a0,a5,800021e2 <remove_from_list+0xbc>
    release(&curr_node->proc_lock);
    8000223a:	04048513          	addi	a0,s1,64
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
    return -1;
    80002246:	59fd                	li	s3,-1
}
    80002248:	854e                	mv	a0,s3
    8000224a:	70e2                	ld	ra,56(sp)
    8000224c:	7442                	ld	s0,48(sp)
    8000224e:	74a2                	ld	s1,40(sp)
    80002250:	7902                	ld	s2,32(sp)
    80002252:	69e2                	ld	s3,24(sp)
    80002254:	6a42                	ld	s4,16(sp)
    80002256:	6aa2                	ld	s5,8(sp)
    80002258:	6b02                	ld	s6,0(sp)
    8000225a:	6121                	addi	sp,sp,64
    8000225c:	8082                	ret

000000008000225e <freeproc>:
{
    8000225e:	1101                	addi	sp,sp,-32
    80002260:	ec06                	sd	ra,24(sp)
    80002262:	e822                	sd	s0,16(sp)
    80002264:	e426                	sd	s1,8(sp)
    80002266:	1000                	addi	s0,sp,32
    80002268:	84aa                	mv	s1,a0
  if(p->trapframe)
    8000226a:	7d28                	ld	a0,120(a0)
    8000226c:	c509                	beqz	a0,80002276 <freeproc+0x18>
    kfree((void*)p->trapframe);
    8000226e:	ffffe097          	auipc	ra,0xffffe
    80002272:	78a080e7          	jalr	1930(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002276:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    8000227a:	78a8                	ld	a0,112(s1)
    8000227c:	c511                	beqz	a0,80002288 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    8000227e:	74ac                	ld	a1,104(s1)
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	7e2080e7          	jalr	2018(ra) # 80001a62 <proc_freepagetable>
  p->pagetable = 0;
    80002288:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    8000228c:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80002290:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002294:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002298:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    8000229c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800022a0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800022a4:	0204a623          	sw	zero,44(s1)
  remove_from_list(&zombie_head, p, &lock_zombie_list); //sould we check for return value of -1???/?????????????????????
    800022a8:	0000f617          	auipc	a2,0xf
    800022ac:	55860613          	addi	a2,a2,1368 # 80011800 <lock_zombie_list>
    800022b0:	85a6                	mv	a1,s1
    800022b2:	00006517          	auipc	a0,0x6
    800022b6:	57250513          	addi	a0,a0,1394 # 80008824 <zombie_head>
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	e6c080e7          	jalr	-404(ra) # 80002126 <remove_from_list>
  p->state = UNUSED;
    800022c2:	0004ac23          	sw	zero,24(s1)
  add_to_list(&unused_head, p, &lock_unused_list);
    800022c6:	0000f617          	auipc	a2,0xf
    800022ca:	50a60613          	addi	a2,a2,1290 # 800117d0 <lock_unused_list>
    800022ce:	85a6                	mv	a1,s1
    800022d0:	00006517          	auipc	a0,0x6
    800022d4:	55c50513          	addi	a0,a0,1372 # 8000882c <unused_head>
    800022d8:	00000097          	auipc	ra,0x0
    800022dc:	b44080e7          	jalr	-1212(ra) # 80001e1c <add_to_list>
}
    800022e0:	60e2                	ld	ra,24(sp)
    800022e2:	6442                	ld	s0,16(sp)
    800022e4:	64a2                	ld	s1,8(sp)
    800022e6:	6105                	addi	sp,sp,32
    800022e8:	8082                	ret

00000000800022ea <wait>:
{
    800022ea:	715d                	addi	sp,sp,-80
    800022ec:	e486                	sd	ra,72(sp)
    800022ee:	e0a2                	sd	s0,64(sp)
    800022f0:	fc26                	sd	s1,56(sp)
    800022f2:	f84a                	sd	s2,48(sp)
    800022f4:	f44e                	sd	s3,40(sp)
    800022f6:	f052                	sd	s4,32(sp)
    800022f8:	ec56                	sd	s5,24(sp)
    800022fa:	e85a                	sd	s6,16(sp)
    800022fc:	e45e                	sd	s7,8(sp)
    800022fe:	e062                	sd	s8,0(sp)
    80002300:	0880                	addi	s0,sp,80
    80002302:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	604080e7          	jalr	1540(ra) # 80001908 <myproc>
    8000230c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000230e:	0000f517          	auipc	a0,0xf
    80002312:	4aa50513          	addi	a0,a0,1194 # 800117b8 <wait_lock>
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	8ce080e7          	jalr	-1842(ra) # 80000be4 <acquire>
    havekids = 0;
    8000231e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002320:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002322:	00015997          	auipc	s3,0x15
    80002326:	6f698993          	addi	s3,s3,1782 # 80017a18 <tickslock>
        havekids = 1;
    8000232a:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000232c:	0000fc17          	auipc	s8,0xf
    80002330:	48cc0c13          	addi	s8,s8,1164 # 800117b8 <wait_lock>
    havekids = 0;
    80002334:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002336:	0000f497          	auipc	s1,0xf
    8000233a:	4e248493          	addi	s1,s1,1250 # 80011818 <proc>
    8000233e:	a0bd                	j	800023ac <wait+0xc2>
          pid = np->pid;
    80002340:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002344:	000b0e63          	beqz	s6,80002360 <wait+0x76>
    80002348:	4691                	li	a3,4
    8000234a:	02c48613          	addi	a2,s1,44
    8000234e:	85da                	mv	a1,s6
    80002350:	07093503          	ld	a0,112(s2)
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	31e080e7          	jalr	798(ra) # 80001672 <copyout>
    8000235c:	02054563          	bltz	a0,80002386 <wait+0x9c>
          freeproc(np);
    80002360:	8526                	mv	a0,s1
    80002362:	00000097          	auipc	ra,0x0
    80002366:	efc080e7          	jalr	-260(ra) # 8000225e <freeproc>
          release(&np->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
          release(&wait_lock);
    80002374:	0000f517          	auipc	a0,0xf
    80002378:	44450513          	addi	a0,a0,1092 # 800117b8 <wait_lock>
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	91c080e7          	jalr	-1764(ra) # 80000c98 <release>
          return pid;
    80002384:	a09d                	j	800023ea <wait+0x100>
            release(&np->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
            release(&wait_lock);
    80002390:	0000f517          	auipc	a0,0xf
    80002394:	42850513          	addi	a0,a0,1064 # 800117b8 <wait_lock>
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	900080e7          	jalr	-1792(ra) # 80000c98 <release>
            return -1;
    800023a0:	59fd                	li	s3,-1
    800023a2:	a0a1                	j	800023ea <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800023a4:	18848493          	addi	s1,s1,392
    800023a8:	03348463          	beq	s1,s3,800023d0 <wait+0xe6>
      if(np->parent == p){
    800023ac:	6cbc                	ld	a5,88(s1)
    800023ae:	ff279be3          	bne	a5,s2,800023a4 <wait+0xba>
        acquire(&np->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	830080e7          	jalr	-2000(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023bc:	4c9c                	lw	a5,24(s1)
    800023be:	f94781e3          	beq	a5,s4,80002340 <wait+0x56>
        release(&np->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8d4080e7          	jalr	-1836(ra) # 80000c98 <release>
        havekids = 1;
    800023cc:	8756                	mv	a4,s5
    800023ce:	bfd9                	j	800023a4 <wait+0xba>
    if(!havekids || p->killed){
    800023d0:	c701                	beqz	a4,800023d8 <wait+0xee>
    800023d2:	02892783          	lw	a5,40(s2)
    800023d6:	c79d                	beqz	a5,80002404 <wait+0x11a>
      release(&wait_lock);
    800023d8:	0000f517          	auipc	a0,0xf
    800023dc:	3e050513          	addi	a0,a0,992 # 800117b8 <wait_lock>
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8b8080e7          	jalr	-1864(ra) # 80000c98 <release>
      return -1;
    800023e8:	59fd                	li	s3,-1
}
    800023ea:	854e                	mv	a0,s3
    800023ec:	60a6                	ld	ra,72(sp)
    800023ee:	6406                	ld	s0,64(sp)
    800023f0:	74e2                	ld	s1,56(sp)
    800023f2:	7942                	ld	s2,48(sp)
    800023f4:	79a2                	ld	s3,40(sp)
    800023f6:	7a02                	ld	s4,32(sp)
    800023f8:	6ae2                	ld	s5,24(sp)
    800023fa:	6b42                	ld	s6,16(sp)
    800023fc:	6ba2                	ld	s7,8(sp)
    800023fe:	6c02                	ld	s8,0(sp)
    80002400:	6161                	addi	sp,sp,80
    80002402:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002404:	85e2                	mv	a1,s8
    80002406:	854a                	mv	a0,s2
    80002408:	00000097          	auipc	ra,0x0
    8000240c:	ca0080e7          	jalr	-864(ra) # 800020a8 <sleep>
    havekids = 0;
    80002410:	b715                	j	80002334 <wait+0x4a>

0000000080002412 <wakeup>:
{
    80002412:	711d                	addi	sp,sp,-96
    80002414:	ec86                	sd	ra,88(sp)
    80002416:	e8a2                	sd	s0,80(sp)
    80002418:	e4a6                	sd	s1,72(sp)
    8000241a:	e0ca                	sd	s2,64(sp)
    8000241c:	fc4e                	sd	s3,56(sp)
    8000241e:	f852                	sd	s4,48(sp)
    80002420:	f456                	sd	s5,40(sp)
    80002422:	f05a                	sd	s6,32(sp)
    80002424:	ec5e                	sd	s7,24(sp)
    80002426:	e862                	sd	s8,16(sp)
    80002428:	e466                	sd	s9,8(sp)
    8000242a:	1080                	addi	s0,sp,96
    8000242c:	8a2a                	mv	s4,a0
  acquire(&lock_sleeping_list);
    8000242e:	0000f517          	auipc	a0,0xf
    80002432:	3ba50513          	addi	a0,a0,954 # 800117e8 <lock_sleeping_list>
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	7ae080e7          	jalr	1966(ra) # 80000be4 <acquire>
  if(sleeping_head != -1){
    8000243e:	00006917          	auipc	s2,0x6
    80002442:	3ea92903          	lw	s2,1002(s2) # 80008828 <sleeping_head>
    80002446:	57fd                	li	a5,-1
    80002448:	0af90163          	beq	s2,a5,800024ea <wakeup+0xd8>
    p = &proc[sleeping_head];
    8000244c:	18800493          	li	s1,392
    80002450:	029904b3          	mul	s1,s2,s1
    80002454:	0000f797          	auipc	a5,0xf
    80002458:	3c478793          	addi	a5,a5,964 # 80011818 <proc>
    8000245c:	94be                	add	s1,s1,a5
    release(&lock_sleeping_list);
    8000245e:	0000f517          	auipc	a0,0xf
    80002462:	38a50513          	addi	a0,a0,906 # 800117e8 <lock_sleeping_list>
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	832080e7          	jalr	-1998(ra) # 80000c98 <release>
      int next_proc = p->next_proc_index;
    8000246e:	8926                	mv	s2,s1
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    80002470:	0000fb97          	auipc	s7,0xf
    80002474:	378b8b93          	addi	s7,s7,888 # 800117e8 <lock_sleeping_list>
    80002478:	00006b17          	auipc	s6,0x6
    8000247c:	3b0b0b13          	addi	s6,s6,944 # 80008828 <sleeping_head>
              p->state = RUNNABLE;
    80002480:	4c8d                	li	s9,3
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    80002482:	0000fc17          	auipc	s8,0xf
    80002486:	e1ec0c13          	addi	s8,s8,-482 # 800112a0 <cpus>
    } while(curr_proc != -1);
    8000248a:	5afd                	li	s5,-1
    8000248c:	a801                	j	8000249c <wakeup+0x8a>
      release(&p->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	808080e7          	jalr	-2040(ra) # 80000c98 <release>
    } while(curr_proc != -1);
    80002498:	07598163          	beq	s3,s5,800024fa <wakeup+0xe8>
      int next_proc = p->next_proc_index;
    8000249c:	03892983          	lw	s3,56(s2)
      acquire(&p->lock);
    800024a0:	8526                	mv	a0,s1
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	742080e7          	jalr	1858(ra) # 80000be4 <acquire>
      if (p->chan == chan) {
    800024aa:	02093783          	ld	a5,32(s2)
    800024ae:	ff4790e3          	bne	a5,s4,8000248e <wakeup+0x7c>
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    800024b2:	865e                	mv	a2,s7
    800024b4:	85a6                	mv	a1,s1
    800024b6:	855a                	mv	a0,s6
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	c6e080e7          	jalr	-914(ra) # 80002126 <remove_from_list>
    800024c0:	d579                	beqz	a0,8000248e <wakeup+0x7c>
              p->state = RUNNABLE;
    800024c2:	01992c23          	sw	s9,24(s2)
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    800024c6:	03492783          	lw	a5,52(s2)
    800024ca:	00279513          	slli	a0,a5,0x2
    800024ce:	953e                	add	a0,a0,a5
    800024d0:	0516                	slli	a0,a0,0x5
    800024d2:	08850613          	addi	a2,a0,136
    800024d6:	08050513          	addi	a0,a0,128
    800024da:	9662                	add	a2,a2,s8
    800024dc:	85a6                	mv	a1,s1
    800024de:	9562                	add	a0,a0,s8
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	93c080e7          	jalr	-1732(ra) # 80001e1c <add_to_list>
    800024e8:	b75d                	j	8000248e <wakeup+0x7c>
    release(&lock_sleeping_list);
    800024ea:	0000f517          	auipc	a0,0xf
    800024ee:	2fe50513          	addi	a0,a0,766 # 800117e8 <lock_sleeping_list>
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	7a6080e7          	jalr	1958(ra) # 80000c98 <release>
}
    800024fa:	60e6                	ld	ra,88(sp)
    800024fc:	6446                	ld	s0,80(sp)
    800024fe:	64a6                	ld	s1,72(sp)
    80002500:	6906                	ld	s2,64(sp)
    80002502:	79e2                	ld	s3,56(sp)
    80002504:	7a42                	ld	s4,48(sp)
    80002506:	7aa2                	ld	s5,40(sp)
    80002508:	7b02                	ld	s6,32(sp)
    8000250a:	6be2                	ld	s7,24(sp)
    8000250c:	6c42                	ld	s8,16(sp)
    8000250e:	6ca2                	ld	s9,8(sp)
    80002510:	6125                	addi	sp,sp,96
    80002512:	8082                	ret

0000000080002514 <reparent>:
{
    80002514:	7179                	addi	sp,sp,-48
    80002516:	f406                	sd	ra,40(sp)
    80002518:	f022                	sd	s0,32(sp)
    8000251a:	ec26                	sd	s1,24(sp)
    8000251c:	e84a                	sd	s2,16(sp)
    8000251e:	e44e                	sd	s3,8(sp)
    80002520:	e052                	sd	s4,0(sp)
    80002522:	1800                	addi	s0,sp,48
    80002524:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002526:	0000f497          	auipc	s1,0xf
    8000252a:	2f248493          	addi	s1,s1,754 # 80011818 <proc>
      pp->parent = initproc;
    8000252e:	00007a17          	auipc	s4,0x7
    80002532:	afaa0a13          	addi	s4,s4,-1286 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002536:	00015997          	auipc	s3,0x15
    8000253a:	4e298993          	addi	s3,s3,1250 # 80017a18 <tickslock>
    8000253e:	a029                	j	80002548 <reparent+0x34>
    80002540:	18848493          	addi	s1,s1,392
    80002544:	01348d63          	beq	s1,s3,8000255e <reparent+0x4a>
    if(pp->parent == p){
    80002548:	6cbc                	ld	a5,88(s1)
    8000254a:	ff279be3          	bne	a5,s2,80002540 <reparent+0x2c>
      pp->parent = initproc;
    8000254e:	000a3503          	ld	a0,0(s4)
    80002552:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002554:	00000097          	auipc	ra,0x0
    80002558:	ebe080e7          	jalr	-322(ra) # 80002412 <wakeup>
    8000255c:	b7d5                	j	80002540 <reparent+0x2c>
}
    8000255e:	70a2                	ld	ra,40(sp)
    80002560:	7402                	ld	s0,32(sp)
    80002562:	64e2                	ld	s1,24(sp)
    80002564:	6942                	ld	s2,16(sp)
    80002566:	69a2                	ld	s3,8(sp)
    80002568:	6a02                	ld	s4,0(sp)
    8000256a:	6145                	addi	sp,sp,48
    8000256c:	8082                	ret

000000008000256e <exit>:
{
    8000256e:	7179                	addi	sp,sp,-48
    80002570:	f406                	sd	ra,40(sp)
    80002572:	f022                	sd	s0,32(sp)
    80002574:	ec26                	sd	s1,24(sp)
    80002576:	e84a                	sd	s2,16(sp)
    80002578:	e44e                	sd	s3,8(sp)
    8000257a:	e052                	sd	s4,0(sp)
    8000257c:	1800                	addi	s0,sp,48
    8000257e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002580:	fffff097          	auipc	ra,0xfffff
    80002584:	388080e7          	jalr	904(ra) # 80001908 <myproc>
    80002588:	89aa                	mv	s3,a0
  if(p == initproc)
    8000258a:	00007797          	auipc	a5,0x7
    8000258e:	a9e7b783          	ld	a5,-1378(a5) # 80009028 <initproc>
    80002592:	0f050493          	addi	s1,a0,240
    80002596:	17050913          	addi	s2,a0,368
    8000259a:	02a79363          	bne	a5,a0,800025c0 <exit+0x52>
    panic("init exiting");
    8000259e:	00006517          	auipc	a0,0x6
    800025a2:	cc250513          	addi	a0,a0,-830 # 80008260 <digits+0x220>
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>
      fileclose(f);
    800025ae:	00002097          	auipc	ra,0x2
    800025b2:	458080e7          	jalr	1112(ra) # 80004a06 <fileclose>
      p->ofile[fd] = 0;
    800025b6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025ba:	04a1                	addi	s1,s1,8
    800025bc:	01248563          	beq	s1,s2,800025c6 <exit+0x58>
    if(p->ofile[fd]){
    800025c0:	6088                	ld	a0,0(s1)
    800025c2:	f575                	bnez	a0,800025ae <exit+0x40>
    800025c4:	bfdd                	j	800025ba <exit+0x4c>
  begin_op();
    800025c6:	00002097          	auipc	ra,0x2
    800025ca:	f74080e7          	jalr	-140(ra) # 8000453a <begin_op>
  iput(p->cwd);
    800025ce:	1709b503          	ld	a0,368(s3)
    800025d2:	00001097          	auipc	ra,0x1
    800025d6:	750080e7          	jalr	1872(ra) # 80003d22 <iput>
  end_op();
    800025da:	00002097          	auipc	ra,0x2
    800025de:	fe0080e7          	jalr	-32(ra) # 800045ba <end_op>
  p->cwd = 0;
    800025e2:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    800025e6:	0000f497          	auipc	s1,0xf
    800025ea:	1d248493          	addi	s1,s1,466 # 800117b8 <wait_lock>
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	5f4080e7          	jalr	1524(ra) # 80000be4 <acquire>
  reparent(p);
    800025f8:	854e                	mv	a0,s3
    800025fa:	00000097          	auipc	ra,0x0
    800025fe:	f1a080e7          	jalr	-230(ra) # 80002514 <reparent>
  wakeup(p->parent);
    80002602:	0589b503          	ld	a0,88(s3)
    80002606:	00000097          	auipc	ra,0x0
    8000260a:	e0c080e7          	jalr	-500(ra) # 80002412 <wakeup>
  acquire(&p->lock);
    8000260e:	854e                	mv	a0,s3
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	5d4080e7          	jalr	1492(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002618:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000261c:	4795                	li	a5,5
    8000261e:	00f9ac23          	sw	a5,24(s3)
  add_to_list(&zombie_head, p, &lock_zombie_list);
    80002622:	0000f617          	auipc	a2,0xf
    80002626:	1de60613          	addi	a2,a2,478 # 80011800 <lock_zombie_list>
    8000262a:	85ce                	mv	a1,s3
    8000262c:	00006517          	auipc	a0,0x6
    80002630:	1f850513          	addi	a0,a0,504 # 80008824 <zombie_head>
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	7e8080e7          	jalr	2024(ra) # 80001e1c <add_to_list>
  release(&wait_lock);
    8000263c:	8526                	mv	a0,s1
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	65a080e7          	jalr	1626(ra) # 80000c98 <release>
  sched();
    80002646:	fffff097          	auipc	ra,0xfffff
    8000264a:	4e2080e7          	jalr	1250(ra) # 80001b28 <sched>
  panic("zombie exit");
    8000264e:	00006517          	auipc	a0,0x6
    80002652:	c2250513          	addi	a0,a0,-990 # 80008270 <digits+0x230>
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	ee8080e7          	jalr	-280(ra) # 8000053e <panic>

000000008000265e <remove_first>:

int remove_first(int* curr_proc_index, struct spinlock* lock) {
    8000265e:	7139                	addi	sp,sp,-64
    80002660:	fc06                	sd	ra,56(sp)
    80002662:	f822                	sd	s0,48(sp)
    80002664:	f426                	sd	s1,40(sp)
    80002666:	f04a                	sd	s2,32(sp)
    80002668:	ec4e                	sd	s3,24(sp)
    8000266a:	e852                	sd	s4,16(sp)
    8000266c:	e456                	sd	s5,8(sp)
    8000266e:	0080                	addi	s0,sp,64
    80002670:	8aaa                	mv	s5,a0
    80002672:	89ae                	mv	s3,a1
    acquire(lock);
    80002674:	852e                	mv	a0,a1
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	56e080e7          	jalr	1390(ra) # 80000be4 <acquire>
    
    if (*curr_proc_index != -1){
    8000267e:	000aa483          	lw	s1,0(s5)
    80002682:	57fd                	li	a5,-1
    80002684:	04f48d63          	beq	s1,a5,800026de <remove_first+0x80>
      int index = *curr_proc_index;
      struct proc *p = &proc[index];
      acquire(&p->proc_lock);
    80002688:	18800793          	li	a5,392
    8000268c:	02f484b3          	mul	s1,s1,a5
    80002690:	04048a13          	addi	s4,s1,64
    80002694:	0000f917          	auipc	s2,0xf
    80002698:	18490913          	addi	s2,s2,388 # 80011818 <proc>
    8000269c:	9a4a                	add	s4,s4,s2
    8000269e:	8552                	mv	a0,s4
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	544080e7          	jalr	1348(ra) # 80000be4 <acquire>
      
      *curr_proc_index = p->next_proc_index;
    800026a8:	94ca                	add	s1,s1,s2
    800026aa:	5c9c                	lw	a5,56(s1)
    800026ac:	00faa023          	sw	a5,0(s5)
      p->next_proc_index = -1;
    800026b0:	57fd                	li	a5,-1
    800026b2:	dc9c                	sw	a5,56(s1)
      int output_proc = p->proc_index;
    800026b4:	5cc4                	lw	s1,60(s1)

      release(&p->proc_lock);
    800026b6:	8552                	mv	a0,s4
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	5e0080e7          	jalr	1504(ra) # 80000c98 <release>
      release(lock);
    800026c0:	854e                	mv	a0,s3
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	5d6080e7          	jalr	1494(ra) # 80000c98 <release>
    else{

      release(lock);
      return -1;
    }
    800026ca:	8526                	mv	a0,s1
    800026cc:	70e2                	ld	ra,56(sp)
    800026ce:	7442                	ld	s0,48(sp)
    800026d0:	74a2                	ld	s1,40(sp)
    800026d2:	7902                	ld	s2,32(sp)
    800026d4:	69e2                	ld	s3,24(sp)
    800026d6:	6a42                	ld	s4,16(sp)
    800026d8:	6aa2                	ld	s5,8(sp)
    800026da:	6121                	addi	sp,sp,64
    800026dc:	8082                	ret
      release(lock);
    800026de:	854e                	mv	a0,s3
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	5b8080e7          	jalr	1464(ra) # 80000c98 <release>
      return -1;
    800026e8:	b7cd                	j	800026ca <remove_first+0x6c>

00000000800026ea <allocproc>:
{
    800026ea:	7179                	addi	sp,sp,-48
    800026ec:	f406                	sd	ra,40(sp)
    800026ee:	f022                	sd	s0,32(sp)
    800026f0:	ec26                	sd	s1,24(sp)
    800026f2:	e84a                	sd	s2,16(sp)
    800026f4:	e44e                	sd	s3,8(sp)
    800026f6:	e052                	sd	s4,0(sp)
    800026f8:	1800                	addi	s0,sp,48
    if(unused_head == -1){
    800026fa:	00006917          	auipc	s2,0x6
    800026fe:	13292903          	lw	s2,306(s2) # 8000882c <unused_head>
    80002702:	57fd                	li	a5,-1
    80002704:	0ef90b63          	beq	s2,a5,800027fa <allocproc+0x110>
    p=&proc[unused_head];
    80002708:	18800993          	li	s3,392
    8000270c:	033909b3          	mul	s3,s2,s3
    80002710:	0000f497          	auipc	s1,0xf
    80002714:	10848493          	addi	s1,s1,264 # 80011818 <proc>
    80002718:	94ce                	add	s1,s1,s3
    acquire(&p->lock);
    8000271a:	8526                	mv	a0,s1
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	4c8080e7          	jalr	1224(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    80002724:	fffff097          	auipc	ra,0xfffff
    80002728:	26a080e7          	jalr	618(ra) # 8000198e <allocpid>
    8000272c:	d888                	sw	a0,48(s1)
  remove_first(&unused_head, &lock_unused_list); //different from the origin
    8000272e:	0000f597          	auipc	a1,0xf
    80002732:	0a258593          	addi	a1,a1,162 # 800117d0 <lock_unused_list>
    80002736:	00006517          	auipc	a0,0x6
    8000273a:	0f650513          	addi	a0,a0,246 # 8000882c <unused_head>
    8000273e:	00000097          	auipc	ra,0x0
    80002742:	f20080e7          	jalr	-224(ra) # 8000265e <remove_first>
  p->state = USED;
    80002746:	4785                	li	a5,1
    80002748:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	3aa080e7          	jalr	938(ra) # 80000af4 <kalloc>
    80002752:	8a2a                	mv	s4,a0
    80002754:	fca8                	sd	a0,120(s1)
    80002756:	c935                	beqz	a0,800027ca <allocproc+0xe0>
  p->pagetable = proc_pagetable(p);
    80002758:	8526                	mv	a0,s1
    8000275a:	fffff097          	auipc	ra,0xfffff
    8000275e:	26c080e7          	jalr	620(ra) # 800019c6 <proc_pagetable>
    80002762:	8a2a                	mv	s4,a0
    80002764:	18800793          	li	a5,392
    80002768:	02f90733          	mul	a4,s2,a5
    8000276c:	0000f797          	auipc	a5,0xf
    80002770:	0ac78793          	addi	a5,a5,172 # 80011818 <proc>
    80002774:	97ba                	add	a5,a5,a4
    80002776:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    80002778:	c52d                	beqz	a0,800027e2 <allocproc+0xf8>
  memset(&p->context, 0, sizeof(p->context));
    8000277a:	08098513          	addi	a0,s3,128
    8000277e:	0000fa17          	auipc	s4,0xf
    80002782:	09aa0a13          	addi	s4,s4,154 # 80011818 <proc>
    80002786:	07000613          	li	a2,112
    8000278a:	4581                	li	a1,0
    8000278c:	9552                	add	a0,a0,s4
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	552080e7          	jalr	1362(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002796:	18800793          	li	a5,392
    8000279a:	02f90933          	mul	s2,s2,a5
    8000279e:	9952                	add	s2,s2,s4
    800027a0:	fffff797          	auipc	a5,0xfffff
    800027a4:	1a878793          	addi	a5,a5,424 # 80001948 <forkret>
    800027a8:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    800027ac:	06093783          	ld	a5,96(s2)
    800027b0:	6705                	lui	a4,0x1
    800027b2:	97ba                	add	a5,a5,a4
    800027b4:	08f93423          	sd	a5,136(s2)
}
    800027b8:	8526                	mv	a0,s1
    800027ba:	70a2                	ld	ra,40(sp)
    800027bc:	7402                	ld	s0,32(sp)
    800027be:	64e2                	ld	s1,24(sp)
    800027c0:	6942                	ld	s2,16(sp)
    800027c2:	69a2                	ld	s3,8(sp)
    800027c4:	6a02                	ld	s4,0(sp)
    800027c6:	6145                	addi	sp,sp,48
    800027c8:	8082                	ret
    freeproc(p);
    800027ca:	8526                	mv	a0,s1
    800027cc:	00000097          	auipc	ra,0x0
    800027d0:	a92080e7          	jalr	-1390(ra) # 8000225e <freeproc>
    release(&p->lock);
    800027d4:	8526                	mv	a0,s1
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	4c2080e7          	jalr	1218(ra) # 80000c98 <release>
    return 0;
    800027de:	84d2                	mv	s1,s4
    800027e0:	bfe1                	j	800027b8 <allocproc+0xce>
    freeproc(p);
    800027e2:	8526                	mv	a0,s1
    800027e4:	00000097          	auipc	ra,0x0
    800027e8:	a7a080e7          	jalr	-1414(ra) # 8000225e <freeproc>
    release(&p->lock);
    800027ec:	8526                	mv	a0,s1
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	4aa080e7          	jalr	1194(ra) # 80000c98 <release>
    return 0;
    800027f6:	84d2                	mv	s1,s4
    800027f8:	b7c1                	j	800027b8 <allocproc+0xce>
      return 0;
    800027fa:	4481                	li	s1,0
    800027fc:	bf75                	j	800027b8 <allocproc+0xce>

00000000800027fe <userinit>:
{
    800027fe:	1101                	addi	sp,sp,-32
    80002800:	ec06                	sd	ra,24(sp)
    80002802:	e822                	sd	s0,16(sp)
    80002804:	e426                	sd	s1,8(sp)
    80002806:	1000                	addi	s0,sp,32
  p = allocproc();
    80002808:	00000097          	auipc	ra,0x0
    8000280c:	ee2080e7          	jalr	-286(ra) # 800026ea <allocproc>
    80002810:	84aa                	mv	s1,a0
  initproc = p;
    80002812:	00007797          	auipc	a5,0x7
    80002816:	80a7bb23          	sd	a0,-2026(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000281a:	03400613          	li	a2,52
    8000281e:	00006597          	auipc	a1,0x6
    80002822:	02258593          	addi	a1,a1,34 # 80008840 <initcode>
    80002826:	7928                	ld	a0,112(a0)
    80002828:	fffff097          	auipc	ra,0xfffff
    8000282c:	b40080e7          	jalr	-1216(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002830:	6785                	lui	a5,0x1
    80002832:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80002834:	7cb8                	ld	a4,120(s1)
    80002836:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000283a:	7cb8                	ld	a4,120(s1)
    8000283c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000283e:	4641                	li	a2,16
    80002840:	00006597          	auipc	a1,0x6
    80002844:	a4058593          	addi	a1,a1,-1472 # 80008280 <digits+0x240>
    80002848:	17848513          	addi	a0,s1,376
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	5e6080e7          	jalr	1510(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002854:	00006517          	auipc	a0,0x6
    80002858:	a3c50513          	addi	a0,a0,-1476 # 80008290 <digits+0x250>
    8000285c:	00002097          	auipc	ra,0x2
    80002860:	ac2080e7          	jalr	-1342(ra) # 8000431e <namei>
    80002864:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80002868:	478d                	li	a5,3
    8000286a:	cc9c                	sw	a5,24(s1)
  add_to_list(&cpus[0].runnable_head, p, &cpus[0].lock_runnable_list);
    8000286c:	0000f617          	auipc	a2,0xf
    80002870:	abc60613          	addi	a2,a2,-1348 # 80011328 <cpus+0x88>
    80002874:	85a6                	mv	a1,s1
    80002876:	0000f517          	auipc	a0,0xf
    8000287a:	aaa50513          	addi	a0,a0,-1366 # 80011320 <cpus+0x80>
    8000287e:	fffff097          	auipc	ra,0xfffff
    80002882:	59e080e7          	jalr	1438(ra) # 80001e1c <add_to_list>
  release(&p->lock);
    80002886:	8526                	mv	a0,s1
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	410080e7          	jalr	1040(ra) # 80000c98 <release>
}
    80002890:	60e2                	ld	ra,24(sp)
    80002892:	6442                	ld	s0,16(sp)
    80002894:	64a2                	ld	s1,8(sp)
    80002896:	6105                	addi	sp,sp,32
    80002898:	8082                	ret

000000008000289a <fork>:
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
  struct proc *p = myproc();
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	05c080e7          	jalr	92(ra) # 80001908 <myproc>
    800028b4:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	e34080e7          	jalr	-460(ra) # 800026ea <allocproc>
    800028be:	14050163          	beqz	a0,80002a00 <fork+0x166>
    800028c2:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800028c4:	0689b603          	ld	a2,104(s3)
    800028c8:	792c                	ld	a1,112(a0)
    800028ca:	0709b503          	ld	a0,112(s3)
    800028ce:	fffff097          	auipc	ra,0xfffff
    800028d2:	ca0080e7          	jalr	-864(ra) # 8000156e <uvmcopy>
    800028d6:	04054663          	bltz	a0,80002922 <fork+0x88>
  np->sz = p->sz;
    800028da:	0689b783          	ld	a5,104(s3)
    800028de:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    800028e2:	0789b683          	ld	a3,120(s3)
    800028e6:	87b6                	mv	a5,a3
    800028e8:	07893703          	ld	a4,120(s2)
    800028ec:	12068693          	addi	a3,a3,288
    800028f0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800028f4:	6788                	ld	a0,8(a5)
    800028f6:	6b8c                	ld	a1,16(a5)
    800028f8:	6f90                	ld	a2,24(a5)
    800028fa:	01073023          	sd	a6,0(a4)
    800028fe:	e708                	sd	a0,8(a4)
    80002900:	eb0c                	sd	a1,16(a4)
    80002902:	ef10                	sd	a2,24(a4)
    80002904:	02078793          	addi	a5,a5,32
    80002908:	02070713          	addi	a4,a4,32
    8000290c:	fed792e3          	bne	a5,a3,800028f0 <fork+0x56>
  np->trapframe->a0 = 0;
    80002910:	07893783          	ld	a5,120(s2)
    80002914:	0607b823          	sd	zero,112(a5)
    80002918:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    8000291c:	17000a13          	li	s4,368
    80002920:	a03d                	j	8000294e <fork+0xb4>
    freeproc(np);
    80002922:	854a                	mv	a0,s2
    80002924:	00000097          	auipc	ra,0x0
    80002928:	93a080e7          	jalr	-1734(ra) # 8000225e <freeproc>
    release(&np->lock);
    8000292c:	854a                	mv	a0,s2
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	36a080e7          	jalr	874(ra) # 80000c98 <release>
    return -1;
    80002936:	5afd                	li	s5,-1
    80002938:	a855                	j	800029ec <fork+0x152>
      np->ofile[i] = filedup(p->ofile[i]);
    8000293a:	00002097          	auipc	ra,0x2
    8000293e:	07a080e7          	jalr	122(ra) # 800049b4 <filedup>
    80002942:	009907b3          	add	a5,s2,s1
    80002946:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002948:	04a1                	addi	s1,s1,8
    8000294a:	01448763          	beq	s1,s4,80002958 <fork+0xbe>
    if(p->ofile[i])
    8000294e:	009987b3          	add	a5,s3,s1
    80002952:	6388                	ld	a0,0(a5)
    80002954:	f17d                	bnez	a0,8000293a <fork+0xa0>
    80002956:	bfcd                	j	80002948 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002958:	1709b503          	ld	a0,368(s3)
    8000295c:	00001097          	auipc	ra,0x1
    80002960:	1ce080e7          	jalr	462(ra) # 80003b2a <idup>
    80002964:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002968:	4641                	li	a2,16
    8000296a:	17898593          	addi	a1,s3,376
    8000296e:	17890513          	addi	a0,s2,376
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	4c0080e7          	jalr	1216(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000297a:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    8000297e:	854a                	mv	a0,s2
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	318080e7          	jalr	792(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002988:	0000f497          	auipc	s1,0xf
    8000298c:	91848493          	addi	s1,s1,-1768 # 800112a0 <cpus>
    80002990:	0000fa17          	auipc	s4,0xf
    80002994:	e28a0a13          	addi	s4,s4,-472 # 800117b8 <wait_lock>
    80002998:	8552                	mv	a0,s4
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	24a080e7          	jalr	586(ra) # 80000be4 <acquire>
  np->parent = p;
    800029a2:	05393c23          	sd	s3,88(s2)
  release(&wait_lock);
    800029a6:	8552                	mv	a0,s4
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	2f0080e7          	jalr	752(ra) # 80000c98 <release>
  acquire(&np->lock);
    800029b0:	854a                	mv	a0,s2
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	232080e7          	jalr	562(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800029ba:	478d                	li	a5,3
    800029bc:	00f92c23          	sw	a5,24(s2)
  add_to_list(&c->runnable_head, np, &c->lock_runnable_list);
    800029c0:	03492783          	lw	a5,52(s2)
    800029c4:	00279513          	slli	a0,a5,0x2
    800029c8:	953e                	add	a0,a0,a5
    800029ca:	0516                	slli	a0,a0,0x5
    800029cc:	08850613          	addi	a2,a0,136
    800029d0:	08050513          	addi	a0,a0,128
    800029d4:	9626                	add	a2,a2,s1
    800029d6:	85ca                	mv	a1,s2
    800029d8:	9526                	add	a0,a0,s1
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	442080e7          	jalr	1090(ra) # 80001e1c <add_to_list>
  release(&np->lock);
    800029e2:	854a                	mv	a0,s2
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	2b4080e7          	jalr	692(ra) # 80000c98 <release>
}
    800029ec:	8556                	mv	a0,s5
    800029ee:	70e2                	ld	ra,56(sp)
    800029f0:	7442                	ld	s0,48(sp)
    800029f2:	74a2                	ld	s1,40(sp)
    800029f4:	7902                	ld	s2,32(sp)
    800029f6:	69e2                	ld	s3,24(sp)
    800029f8:	6a42                	ld	s4,16(sp)
    800029fa:	6aa2                	ld	s5,8(sp)
    800029fc:	6121                	addi	sp,sp,64
    800029fe:	8082                	ret
    return -1;
    80002a00:	5afd                	li	s5,-1
    80002a02:	b7ed                	j	800029ec <fork+0x152>

0000000080002a04 <scheduler>:
{
    80002a04:	715d                	addi	sp,sp,-80
    80002a06:	e486                	sd	ra,72(sp)
    80002a08:	e0a2                	sd	s0,64(sp)
    80002a0a:	fc26                	sd	s1,56(sp)
    80002a0c:	f84a                	sd	s2,48(sp)
    80002a0e:	f44e                	sd	s3,40(sp)
    80002a10:	f052                	sd	s4,32(sp)
    80002a12:	ec56                	sd	s5,24(sp)
    80002a14:	e85a                	sd	s6,16(sp)
    80002a16:	e45e                	sd	s7,8(sp)
    80002a18:	e062                	sd	s8,0(sp)
    80002a1a:	0880                	addi	s0,sp,80
    80002a1c:	8712                	mv	a4,tp
  int id = r_tp();
    80002a1e:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002a20:	0000fb17          	auipc	s6,0xf
    80002a24:	880b0b13          	addi	s6,s6,-1920 # 800112a0 <cpus>
    80002a28:	00271793          	slli	a5,a4,0x2
    80002a2c:	00e786b3          	add	a3,a5,a4
    80002a30:	0696                	slli	a3,a3,0x5
    80002a32:	96da                	add	a3,a3,s6
    80002a34:	0006b023          	sd	zero,0(a3)
    80002a38:	97ba                	add	a5,a5,a4
    80002a3a:	0796                	slli	a5,a5,0x5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002a3c:	08078c13          	addi	s8,a5,128
    80002a40:	9c5a                	add	s8,s8,s6
    80002a42:	08878b93          	addi	s7,a5,136
    80002a46:	9bda                	add	s7,s7,s6
        swtch(&c->context, &p->context);
    80002a48:	07a1                	addi	a5,a5,8
    80002a4a:	9b3e                	add	s6,s6,a5
      if(p->state == RUNNABLE) {
    80002a4c:	498d                	li	s3,3
        c->proc = p;
    80002a4e:	8a36                	mv	s4,a3
    for(p = proc; p < &proc[NPROC]; p++) {
    80002a50:	00015917          	auipc	s2,0x15
    80002a54:	fc890913          	addi	s2,s2,-56 # 80017a18 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a5c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a60:	10079073          	csrw	sstatus,a5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002a64:	85de                	mv	a1,s7
    80002a66:	8562                	mv	a0,s8
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	bf6080e7          	jalr	-1034(ra) # 8000265e <remove_first>
    80002a70:	0000f497          	auipc	s1,0xf
    80002a74:	da848493          	addi	s1,s1,-600 # 80011818 <proc>
        p->state = RUNNING;
    80002a78:	4a91                	li	s5,4
    80002a7a:	a03d                	j	80002aa8 <scheduler+0xa4>
    80002a7c:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80002a80:	009a3023          	sd	s1,0(s4)
        swtch(&c->context, &p->context);
    80002a84:	08048593          	addi	a1,s1,128
    80002a88:	855a                	mv	a0,s6
    80002a8a:	00000097          	auipc	ra,0x0
    80002a8e:	030080e7          	jalr	48(ra) # 80002aba <swtch>
        c->proc = 0;
    80002a92:	000a3023          	sd	zero,0(s4)
      release(&p->lock);
    80002a96:	8526                	mv	a0,s1
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	200080e7          	jalr	512(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002aa0:	18848493          	addi	s1,s1,392
    80002aa4:	fb248ae3          	beq	s1,s2,80002a58 <scheduler+0x54>
      acquire(&p->lock);
    80002aa8:	8526                	mv	a0,s1
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	13a080e7          	jalr	314(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002ab2:	4c9c                	lw	a5,24(s1)
    80002ab4:	ff3791e3          	bne	a5,s3,80002a96 <scheduler+0x92>
    80002ab8:	b7d1                	j	80002a7c <scheduler+0x78>

0000000080002aba <swtch>:
    80002aba:	00153023          	sd	ra,0(a0)
    80002abe:	00253423          	sd	sp,8(a0)
    80002ac2:	e900                	sd	s0,16(a0)
    80002ac4:	ed04                	sd	s1,24(a0)
    80002ac6:	03253023          	sd	s2,32(a0)
    80002aca:	03353423          	sd	s3,40(a0)
    80002ace:	03453823          	sd	s4,48(a0)
    80002ad2:	03553c23          	sd	s5,56(a0)
    80002ad6:	05653023          	sd	s6,64(a0)
    80002ada:	05753423          	sd	s7,72(a0)
    80002ade:	05853823          	sd	s8,80(a0)
    80002ae2:	05953c23          	sd	s9,88(a0)
    80002ae6:	07a53023          	sd	s10,96(a0)
    80002aea:	07b53423          	sd	s11,104(a0)
    80002aee:	0005b083          	ld	ra,0(a1)
    80002af2:	0085b103          	ld	sp,8(a1)
    80002af6:	6980                	ld	s0,16(a1)
    80002af8:	6d84                	ld	s1,24(a1)
    80002afa:	0205b903          	ld	s2,32(a1)
    80002afe:	0285b983          	ld	s3,40(a1)
    80002b02:	0305ba03          	ld	s4,48(a1)
    80002b06:	0385ba83          	ld	s5,56(a1)
    80002b0a:	0405bb03          	ld	s6,64(a1)
    80002b0e:	0485bb83          	ld	s7,72(a1)
    80002b12:	0505bc03          	ld	s8,80(a1)
    80002b16:	0585bc83          	ld	s9,88(a1)
    80002b1a:	0605bd03          	ld	s10,96(a1)
    80002b1e:	0685bd83          	ld	s11,104(a1)
    80002b22:	8082                	ret

0000000080002b24 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b24:	1141                	addi	sp,sp,-16
    80002b26:	e406                	sd	ra,8(sp)
    80002b28:	e022                	sd	s0,0(sp)
    80002b2a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b2c:	00005597          	auipc	a1,0x5
    80002b30:	7c458593          	addi	a1,a1,1988 # 800082f0 <states.1747+0x30>
    80002b34:	00015517          	auipc	a0,0x15
    80002b38:	ee450513          	addi	a0,a0,-284 # 80017a18 <tickslock>
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	018080e7          	jalr	24(ra) # 80000b54 <initlock>
}
    80002b44:	60a2                	ld	ra,8(sp)
    80002b46:	6402                	ld	s0,0(sp)
    80002b48:	0141                	addi	sp,sp,16
    80002b4a:	8082                	ret

0000000080002b4c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b4c:	1141                	addi	sp,sp,-16
    80002b4e:	e422                	sd	s0,8(sp)
    80002b50:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b52:	00003797          	auipc	a5,0x3
    80002b56:	4ce78793          	addi	a5,a5,1230 # 80006020 <kernelvec>
    80002b5a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b5e:	6422                	ld	s0,8(sp)
    80002b60:	0141                	addi	sp,sp,16
    80002b62:	8082                	ret

0000000080002b64 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b64:	1141                	addi	sp,sp,-16
    80002b66:	e406                	sd	ra,8(sp)
    80002b68:	e022                	sd	s0,0(sp)
    80002b6a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	d9c080e7          	jalr	-612(ra) # 80001908 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b74:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b78:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002b7e:	00004617          	auipc	a2,0x4
    80002b82:	48260613          	addi	a2,a2,1154 # 80007000 <_trampoline>
    80002b86:	00004697          	auipc	a3,0x4
    80002b8a:	47a68693          	addi	a3,a3,1146 # 80007000 <_trampoline>
    80002b8e:	8e91                	sub	a3,a3,a2
    80002b90:	040007b7          	lui	a5,0x4000
    80002b94:	17fd                	addi	a5,a5,-1
    80002b96:	07b2                	slli	a5,a5,0xc
    80002b98:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b9a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b9e:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ba0:	180026f3          	csrr	a3,satp
    80002ba4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ba6:	7d38                	ld	a4,120(a0)
    80002ba8:	7134                	ld	a3,96(a0)
    80002baa:	6585                	lui	a1,0x1
    80002bac:	96ae                	add	a3,a3,a1
    80002bae:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bb0:	7d38                	ld	a4,120(a0)
    80002bb2:	00000697          	auipc	a3,0x0
    80002bb6:	13868693          	addi	a3,a3,312 # 80002cea <usertrap>
    80002bba:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bbc:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bbe:	8692                	mv	a3,tp
    80002bc0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bc6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bca:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bce:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bd2:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bd4:	6f18                	ld	a4,24(a4)
    80002bd6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bda:	792c                	ld	a1,112(a0)
    80002bdc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002bde:	00004717          	auipc	a4,0x4
    80002be2:	4b270713          	addi	a4,a4,1202 # 80007090 <userret>
    80002be6:	8f11                	sub	a4,a4,a2
    80002be8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002bea:	577d                	li	a4,-1
    80002bec:	177e                	slli	a4,a4,0x3f
    80002bee:	8dd9                	or	a1,a1,a4
    80002bf0:	02000537          	lui	a0,0x2000
    80002bf4:	157d                	addi	a0,a0,-1
    80002bf6:	0536                	slli	a0,a0,0xd
    80002bf8:	9782                	jalr	a5
}
    80002bfa:	60a2                	ld	ra,8(sp)
    80002bfc:	6402                	ld	s0,0(sp)
    80002bfe:	0141                	addi	sp,sp,16
    80002c00:	8082                	ret

0000000080002c02 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c02:	1101                	addi	sp,sp,-32
    80002c04:	ec06                	sd	ra,24(sp)
    80002c06:	e822                	sd	s0,16(sp)
    80002c08:	e426                	sd	s1,8(sp)
    80002c0a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c0c:	00015497          	auipc	s1,0x15
    80002c10:	e0c48493          	addi	s1,s1,-500 # 80017a18 <tickslock>
    80002c14:	8526                	mv	a0,s1
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	fce080e7          	jalr	-50(ra) # 80000be4 <acquire>
  ticks++;
    80002c1e:	00006517          	auipc	a0,0x6
    80002c22:	41250513          	addi	a0,a0,1042 # 80009030 <ticks>
    80002c26:	411c                	lw	a5,0(a0)
    80002c28:	2785                	addiw	a5,a5,1
    80002c2a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	7e6080e7          	jalr	2022(ra) # 80002412 <wakeup>
  release(&tickslock);
    80002c34:	8526                	mv	a0,s1
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	062080e7          	jalr	98(ra) # 80000c98 <release>
}
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	64a2                	ld	s1,8(sp)
    80002c44:	6105                	addi	sp,sp,32
    80002c46:	8082                	ret

0000000080002c48 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c48:	1101                	addi	sp,sp,-32
    80002c4a:	ec06                	sd	ra,24(sp)
    80002c4c:	e822                	sd	s0,16(sp)
    80002c4e:	e426                	sd	s1,8(sp)
    80002c50:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c52:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c56:	00074d63          	bltz	a4,80002c70 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c5a:	57fd                	li	a5,-1
    80002c5c:	17fe                	slli	a5,a5,0x3f
    80002c5e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c60:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c62:	06f70363          	beq	a4,a5,80002cc8 <devintr+0x80>
  }
}
    80002c66:	60e2                	ld	ra,24(sp)
    80002c68:	6442                	ld	s0,16(sp)
    80002c6a:	64a2                	ld	s1,8(sp)
    80002c6c:	6105                	addi	sp,sp,32
    80002c6e:	8082                	ret
     (scause & 0xff) == 9){
    80002c70:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c74:	46a5                	li	a3,9
    80002c76:	fed792e3          	bne	a5,a3,80002c5a <devintr+0x12>
    int irq = plic_claim();
    80002c7a:	00003097          	auipc	ra,0x3
    80002c7e:	4ae080e7          	jalr	1198(ra) # 80006128 <plic_claim>
    80002c82:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c84:	47a9                	li	a5,10
    80002c86:	02f50763          	beq	a0,a5,80002cb4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c8a:	4785                	li	a5,1
    80002c8c:	02f50963          	beq	a0,a5,80002cbe <devintr+0x76>
    return 1;
    80002c90:	4505                	li	a0,1
    } else if(irq){
    80002c92:	d8f1                	beqz	s1,80002c66 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c94:	85a6                	mv	a1,s1
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	66250513          	addi	a0,a0,1634 # 800082f8 <states.1747+0x38>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8ea080e7          	jalr	-1814(ra) # 80000588 <printf>
      plic_complete(irq);
    80002ca6:	8526                	mv	a0,s1
    80002ca8:	00003097          	auipc	ra,0x3
    80002cac:	4a4080e7          	jalr	1188(ra) # 8000614c <plic_complete>
    return 1;
    80002cb0:	4505                	li	a0,1
    80002cb2:	bf55                	j	80002c66 <devintr+0x1e>
      uartintr();
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	cf4080e7          	jalr	-780(ra) # 800009a8 <uartintr>
    80002cbc:	b7ed                	j	80002ca6 <devintr+0x5e>
      virtio_disk_intr();
    80002cbe:	00004097          	auipc	ra,0x4
    80002cc2:	96e080e7          	jalr	-1682(ra) # 8000662c <virtio_disk_intr>
    80002cc6:	b7c5                	j	80002ca6 <devintr+0x5e>
    if(cpuid() == 0){
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	c0c080e7          	jalr	-1012(ra) # 800018d4 <cpuid>
    80002cd0:	c901                	beqz	a0,80002ce0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002cd2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cd8:	14479073          	csrw	sip,a5
    return 2;
    80002cdc:	4509                	li	a0,2
    80002cde:	b761                	j	80002c66 <devintr+0x1e>
      clockintr();
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	f22080e7          	jalr	-222(ra) # 80002c02 <clockintr>
    80002ce8:	b7ed                	j	80002cd2 <devintr+0x8a>

0000000080002cea <usertrap>:
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	e426                	sd	s1,8(sp)
    80002cf2:	e04a                	sd	s2,0(sp)
    80002cf4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cf6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002cfa:	1007f793          	andi	a5,a5,256
    80002cfe:	e3ad                	bnez	a5,80002d60 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d00:	00003797          	auipc	a5,0x3
    80002d04:	32078793          	addi	a5,a5,800 # 80006020 <kernelvec>
    80002d08:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	bfc080e7          	jalr	-1028(ra) # 80001908 <myproc>
    80002d14:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d16:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d18:	14102773          	csrr	a4,sepc
    80002d1c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d1e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d22:	47a1                	li	a5,8
    80002d24:	04f71c63          	bne	a4,a5,80002d7c <usertrap+0x92>
    if(p->killed)
    80002d28:	551c                	lw	a5,40(a0)
    80002d2a:	e3b9                	bnez	a5,80002d70 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d2c:	7cb8                	ld	a4,120(s1)
    80002d2e:	6f1c                	ld	a5,24(a4)
    80002d30:	0791                	addi	a5,a5,4
    80002d32:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d38:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d3c:	10079073          	csrw	sstatus,a5
    syscall();
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	2e0080e7          	jalr	736(ra) # 80003020 <syscall>
  if(p->killed)
    80002d48:	549c                	lw	a5,40(s1)
    80002d4a:	ebc1                	bnez	a5,80002dda <usertrap+0xf0>
  usertrapret();
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	e18080e7          	jalr	-488(ra) # 80002b64 <usertrapret>
}
    80002d54:	60e2                	ld	ra,24(sp)
    80002d56:	6442                	ld	s0,16(sp)
    80002d58:	64a2                	ld	s1,8(sp)
    80002d5a:	6902                	ld	s2,0(sp)
    80002d5c:	6105                	addi	sp,sp,32
    80002d5e:	8082                	ret
    panic("usertrap: not from user mode");
    80002d60:	00005517          	auipc	a0,0x5
    80002d64:	5b850513          	addi	a0,a0,1464 # 80008318 <states.1747+0x58>
    80002d68:	ffffd097          	auipc	ra,0xffffd
    80002d6c:	7d6080e7          	jalr	2006(ra) # 8000053e <panic>
      exit(-1);
    80002d70:	557d                	li	a0,-1
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	7fc080e7          	jalr	2044(ra) # 8000256e <exit>
    80002d7a:	bf4d                	j	80002d2c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	ecc080e7          	jalr	-308(ra) # 80002c48 <devintr>
    80002d84:	892a                	mv	s2,a0
    80002d86:	c501                	beqz	a0,80002d8e <usertrap+0xa4>
  if(p->killed)
    80002d88:	549c                	lw	a5,40(s1)
    80002d8a:	c3a1                	beqz	a5,80002dca <usertrap+0xe0>
    80002d8c:	a815                	j	80002dc0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d8e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d92:	5890                	lw	a2,48(s1)
    80002d94:	00005517          	auipc	a0,0x5
    80002d98:	5a450513          	addi	a0,a0,1444 # 80008338 <states.1747+0x78>
    80002d9c:	ffffd097          	auipc	ra,0xffffd
    80002da0:	7ec080e7          	jalr	2028(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002da4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002da8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dac:	00005517          	auipc	a0,0x5
    80002db0:	5bc50513          	addi	a0,a0,1468 # 80008368 <states.1747+0xa8>
    80002db4:	ffffd097          	auipc	ra,0xffffd
    80002db8:	7d4080e7          	jalr	2004(ra) # 80000588 <printf>
    p->killed = 1;
    80002dbc:	4785                	li	a5,1
    80002dbe:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002dc0:	557d                	li	a0,-1
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	7ac080e7          	jalr	1964(ra) # 8000256e <exit>
  if(which_dev == 2)
    80002dca:	4789                	li	a5,2
    80002dcc:	f8f910e3          	bne	s2,a5,80002d4c <usertrap+0x62>
    yield();
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	230080e7          	jalr	560(ra) # 80002000 <yield>
    80002dd8:	bf95                	j	80002d4c <usertrap+0x62>
  int which_dev = 0;
    80002dda:	4901                	li	s2,0
    80002ddc:	b7d5                	j	80002dc0 <usertrap+0xd6>

0000000080002dde <kerneltrap>:
{
    80002dde:	7179                	addi	sp,sp,-48
    80002de0:	f406                	sd	ra,40(sp)
    80002de2:	f022                	sd	s0,32(sp)
    80002de4:	ec26                	sd	s1,24(sp)
    80002de6:	e84a                	sd	s2,16(sp)
    80002de8:	e44e                	sd	s3,8(sp)
    80002dea:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dec:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002df4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002df8:	1004f793          	andi	a5,s1,256
    80002dfc:	cb85                	beqz	a5,80002e2c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dfe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e02:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e04:	ef85                	bnez	a5,80002e3c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	e42080e7          	jalr	-446(ra) # 80002c48 <devintr>
    80002e0e:	cd1d                	beqz	a0,80002e4c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e10:	4789                	li	a5,2
    80002e12:	06f50a63          	beq	a0,a5,80002e86 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e16:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e1a:	10049073          	csrw	sstatus,s1
}
    80002e1e:	70a2                	ld	ra,40(sp)
    80002e20:	7402                	ld	s0,32(sp)
    80002e22:	64e2                	ld	s1,24(sp)
    80002e24:	6942                	ld	s2,16(sp)
    80002e26:	69a2                	ld	s3,8(sp)
    80002e28:	6145                	addi	sp,sp,48
    80002e2a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e2c:	00005517          	auipc	a0,0x5
    80002e30:	55c50513          	addi	a0,a0,1372 # 80008388 <states.1747+0xc8>
    80002e34:	ffffd097          	auipc	ra,0xffffd
    80002e38:	70a080e7          	jalr	1802(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002e3c:	00005517          	auipc	a0,0x5
    80002e40:	57450513          	addi	a0,a0,1396 # 800083b0 <states.1747+0xf0>
    80002e44:	ffffd097          	auipc	ra,0xffffd
    80002e48:	6fa080e7          	jalr	1786(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002e4c:	85ce                	mv	a1,s3
    80002e4e:	00005517          	auipc	a0,0x5
    80002e52:	58250513          	addi	a0,a0,1410 # 800083d0 <states.1747+0x110>
    80002e56:	ffffd097          	auipc	ra,0xffffd
    80002e5a:	732080e7          	jalr	1842(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e5e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e62:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e66:	00005517          	auipc	a0,0x5
    80002e6a:	57a50513          	addi	a0,a0,1402 # 800083e0 <states.1747+0x120>
    80002e6e:	ffffd097          	auipc	ra,0xffffd
    80002e72:	71a080e7          	jalr	1818(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002e76:	00005517          	auipc	a0,0x5
    80002e7a:	58250513          	addi	a0,a0,1410 # 800083f8 <states.1747+0x138>
    80002e7e:	ffffd097          	auipc	ra,0xffffd
    80002e82:	6c0080e7          	jalr	1728(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	a82080e7          	jalr	-1406(ra) # 80001908 <myproc>
    80002e8e:	d541                	beqz	a0,80002e16 <kerneltrap+0x38>
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	a78080e7          	jalr	-1416(ra) # 80001908 <myproc>
    80002e98:	4d18                	lw	a4,24(a0)
    80002e9a:	4791                	li	a5,4
    80002e9c:	f6f71de3          	bne	a4,a5,80002e16 <kerneltrap+0x38>
    yield();
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	160080e7          	jalr	352(ra) # 80002000 <yield>
    80002ea8:	b7bd                	j	80002e16 <kerneltrap+0x38>

0000000080002eaa <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002eaa:	1101                	addi	sp,sp,-32
    80002eac:	ec06                	sd	ra,24(sp)
    80002eae:	e822                	sd	s0,16(sp)
    80002eb0:	e426                	sd	s1,8(sp)
    80002eb2:	1000                	addi	s0,sp,32
    80002eb4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	a52080e7          	jalr	-1454(ra) # 80001908 <myproc>
  switch (n) {
    80002ebe:	4795                	li	a5,5
    80002ec0:	0497e163          	bltu	a5,s1,80002f02 <argraw+0x58>
    80002ec4:	048a                	slli	s1,s1,0x2
    80002ec6:	00005717          	auipc	a4,0x5
    80002eca:	56a70713          	addi	a4,a4,1386 # 80008430 <states.1747+0x170>
    80002ece:	94ba                	add	s1,s1,a4
    80002ed0:	409c                	lw	a5,0(s1)
    80002ed2:	97ba                	add	a5,a5,a4
    80002ed4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ed6:	7d3c                	ld	a5,120(a0)
    80002ed8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002eda:	60e2                	ld	ra,24(sp)
    80002edc:	6442                	ld	s0,16(sp)
    80002ede:	64a2                	ld	s1,8(sp)
    80002ee0:	6105                	addi	sp,sp,32
    80002ee2:	8082                	ret
    return p->trapframe->a1;
    80002ee4:	7d3c                	ld	a5,120(a0)
    80002ee6:	7fa8                	ld	a0,120(a5)
    80002ee8:	bfcd                	j	80002eda <argraw+0x30>
    return p->trapframe->a2;
    80002eea:	7d3c                	ld	a5,120(a0)
    80002eec:	63c8                	ld	a0,128(a5)
    80002eee:	b7f5                	j	80002eda <argraw+0x30>
    return p->trapframe->a3;
    80002ef0:	7d3c                	ld	a5,120(a0)
    80002ef2:	67c8                	ld	a0,136(a5)
    80002ef4:	b7dd                	j	80002eda <argraw+0x30>
    return p->trapframe->a4;
    80002ef6:	7d3c                	ld	a5,120(a0)
    80002ef8:	6bc8                	ld	a0,144(a5)
    80002efa:	b7c5                	j	80002eda <argraw+0x30>
    return p->trapframe->a5;
    80002efc:	7d3c                	ld	a5,120(a0)
    80002efe:	6fc8                	ld	a0,152(a5)
    80002f00:	bfe9                	j	80002eda <argraw+0x30>
  panic("argraw");
    80002f02:	00005517          	auipc	a0,0x5
    80002f06:	50650513          	addi	a0,a0,1286 # 80008408 <states.1747+0x148>
    80002f0a:	ffffd097          	auipc	ra,0xffffd
    80002f0e:	634080e7          	jalr	1588(ra) # 8000053e <panic>

0000000080002f12 <fetchaddr>:
{
    80002f12:	1101                	addi	sp,sp,-32
    80002f14:	ec06                	sd	ra,24(sp)
    80002f16:	e822                	sd	s0,16(sp)
    80002f18:	e426                	sd	s1,8(sp)
    80002f1a:	e04a                	sd	s2,0(sp)
    80002f1c:	1000                	addi	s0,sp,32
    80002f1e:	84aa                	mv	s1,a0
    80002f20:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	9e6080e7          	jalr	-1562(ra) # 80001908 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f2a:	753c                	ld	a5,104(a0)
    80002f2c:	02f4f863          	bgeu	s1,a5,80002f5c <fetchaddr+0x4a>
    80002f30:	00848713          	addi	a4,s1,8
    80002f34:	02e7e663          	bltu	a5,a4,80002f60 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f38:	46a1                	li	a3,8
    80002f3a:	8626                	mv	a2,s1
    80002f3c:	85ca                	mv	a1,s2
    80002f3e:	7928                	ld	a0,112(a0)
    80002f40:	ffffe097          	auipc	ra,0xffffe
    80002f44:	7be080e7          	jalr	1982(ra) # 800016fe <copyin>
    80002f48:	00a03533          	snez	a0,a0
    80002f4c:	40a00533          	neg	a0,a0
}
    80002f50:	60e2                	ld	ra,24(sp)
    80002f52:	6442                	ld	s0,16(sp)
    80002f54:	64a2                	ld	s1,8(sp)
    80002f56:	6902                	ld	s2,0(sp)
    80002f58:	6105                	addi	sp,sp,32
    80002f5a:	8082                	ret
    return -1;
    80002f5c:	557d                	li	a0,-1
    80002f5e:	bfcd                	j	80002f50 <fetchaddr+0x3e>
    80002f60:	557d                	li	a0,-1
    80002f62:	b7fd                	j	80002f50 <fetchaddr+0x3e>

0000000080002f64 <fetchstr>:
{
    80002f64:	7179                	addi	sp,sp,-48
    80002f66:	f406                	sd	ra,40(sp)
    80002f68:	f022                	sd	s0,32(sp)
    80002f6a:	ec26                	sd	s1,24(sp)
    80002f6c:	e84a                	sd	s2,16(sp)
    80002f6e:	e44e                	sd	s3,8(sp)
    80002f70:	1800                	addi	s0,sp,48
    80002f72:	892a                	mv	s2,a0
    80002f74:	84ae                	mv	s1,a1
    80002f76:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f78:	fffff097          	auipc	ra,0xfffff
    80002f7c:	990080e7          	jalr	-1648(ra) # 80001908 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f80:	86ce                	mv	a3,s3
    80002f82:	864a                	mv	a2,s2
    80002f84:	85a6                	mv	a1,s1
    80002f86:	7928                	ld	a0,112(a0)
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	802080e7          	jalr	-2046(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002f90:	00054763          	bltz	a0,80002f9e <fetchstr+0x3a>
  return strlen(buf);
    80002f94:	8526                	mv	a0,s1
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	ece080e7          	jalr	-306(ra) # 80000e64 <strlen>
}
    80002f9e:	70a2                	ld	ra,40(sp)
    80002fa0:	7402                	ld	s0,32(sp)
    80002fa2:	64e2                	ld	s1,24(sp)
    80002fa4:	6942                	ld	s2,16(sp)
    80002fa6:	69a2                	ld	s3,8(sp)
    80002fa8:	6145                	addi	sp,sp,48
    80002faa:	8082                	ret

0000000080002fac <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002fac:	1101                	addi	sp,sp,-32
    80002fae:	ec06                	sd	ra,24(sp)
    80002fb0:	e822                	sd	s0,16(sp)
    80002fb2:	e426                	sd	s1,8(sp)
    80002fb4:	1000                	addi	s0,sp,32
    80002fb6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fb8:	00000097          	auipc	ra,0x0
    80002fbc:	ef2080e7          	jalr	-270(ra) # 80002eaa <argraw>
    80002fc0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002fc2:	4501                	li	a0,0
    80002fc4:	60e2                	ld	ra,24(sp)
    80002fc6:	6442                	ld	s0,16(sp)
    80002fc8:	64a2                	ld	s1,8(sp)
    80002fca:	6105                	addi	sp,sp,32
    80002fcc:	8082                	ret

0000000080002fce <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002fce:	1101                	addi	sp,sp,-32
    80002fd0:	ec06                	sd	ra,24(sp)
    80002fd2:	e822                	sd	s0,16(sp)
    80002fd4:	e426                	sd	s1,8(sp)
    80002fd6:	1000                	addi	s0,sp,32
    80002fd8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fda:	00000097          	auipc	ra,0x0
    80002fde:	ed0080e7          	jalr	-304(ra) # 80002eaa <argraw>
    80002fe2:	e088                	sd	a0,0(s1)
  return 0;
}
    80002fe4:	4501                	li	a0,0
    80002fe6:	60e2                	ld	ra,24(sp)
    80002fe8:	6442                	ld	s0,16(sp)
    80002fea:	64a2                	ld	s1,8(sp)
    80002fec:	6105                	addi	sp,sp,32
    80002fee:	8082                	ret

0000000080002ff0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ff0:	1101                	addi	sp,sp,-32
    80002ff2:	ec06                	sd	ra,24(sp)
    80002ff4:	e822                	sd	s0,16(sp)
    80002ff6:	e426                	sd	s1,8(sp)
    80002ff8:	e04a                	sd	s2,0(sp)
    80002ffa:	1000                	addi	s0,sp,32
    80002ffc:	84ae                	mv	s1,a1
    80002ffe:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003000:	00000097          	auipc	ra,0x0
    80003004:	eaa080e7          	jalr	-342(ra) # 80002eaa <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003008:	864a                	mv	a2,s2
    8000300a:	85a6                	mv	a1,s1
    8000300c:	00000097          	auipc	ra,0x0
    80003010:	f58080e7          	jalr	-168(ra) # 80002f64 <fetchstr>
}
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	64a2                	ld	s1,8(sp)
    8000301a:	6902                	ld	s2,0(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret

0000000080003020 <syscall>:
[SYS_get_cpu] sys_get_cpu,
};

void
syscall(void)
{
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	e426                	sd	s1,8(sp)
    80003028:	e04a                	sd	s2,0(sp)
    8000302a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000302c:	fffff097          	auipc	ra,0xfffff
    80003030:	8dc080e7          	jalr	-1828(ra) # 80001908 <myproc>
    80003034:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003036:	07853903          	ld	s2,120(a0)
    8000303a:	0a893783          	ld	a5,168(s2)
    8000303e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003042:	37fd                	addiw	a5,a5,-1
    80003044:	4759                	li	a4,22
    80003046:	00f76f63          	bltu	a4,a5,80003064 <syscall+0x44>
    8000304a:	00369713          	slli	a4,a3,0x3
    8000304e:	00005797          	auipc	a5,0x5
    80003052:	3fa78793          	addi	a5,a5,1018 # 80008448 <syscalls>
    80003056:	97ba                	add	a5,a5,a4
    80003058:	639c                	ld	a5,0(a5)
    8000305a:	c789                	beqz	a5,80003064 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000305c:	9782                	jalr	a5
    8000305e:	06a93823          	sd	a0,112(s2)
    80003062:	a839                	j	80003080 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003064:	17848613          	addi	a2,s1,376
    80003068:	588c                	lw	a1,48(s1)
    8000306a:	00005517          	auipc	a0,0x5
    8000306e:	3a650513          	addi	a0,a0,934 # 80008410 <states.1747+0x150>
    80003072:	ffffd097          	auipc	ra,0xffffd
    80003076:	516080e7          	jalr	1302(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000307a:	7cbc                	ld	a5,120(s1)
    8000307c:	577d                	li	a4,-1
    8000307e:	fbb8                	sd	a4,112(a5)
  }
}
    80003080:	60e2                	ld	ra,24(sp)
    80003082:	6442                	ld	s0,16(sp)
    80003084:	64a2                	ld	s1,8(sp)
    80003086:	6902                	ld	s2,0(sp)
    80003088:	6105                	addi	sp,sp,32
    8000308a:	8082                	ret

000000008000308c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000308c:	1101                	addi	sp,sp,-32
    8000308e:	ec06                	sd	ra,24(sp)
    80003090:	e822                	sd	s0,16(sp)
    80003092:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003094:	fec40593          	addi	a1,s0,-20
    80003098:	4501                	li	a0,0
    8000309a:	00000097          	auipc	ra,0x0
    8000309e:	f12080e7          	jalr	-238(ra) # 80002fac <argint>
    return -1;
    800030a2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030a4:	00054963          	bltz	a0,800030b6 <sys_exit+0x2a>
  exit(n);
    800030a8:	fec42503          	lw	a0,-20(s0)
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	4c2080e7          	jalr	1218(ra) # 8000256e <exit>
  return 0;  // not reached
    800030b4:	4781                	li	a5,0
}
    800030b6:	853e                	mv	a0,a5
    800030b8:	60e2                	ld	ra,24(sp)
    800030ba:	6442                	ld	s0,16(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret

00000000800030c0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030c0:	1141                	addi	sp,sp,-16
    800030c2:	e406                	sd	ra,8(sp)
    800030c4:	e022                	sd	s0,0(sp)
    800030c6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	840080e7          	jalr	-1984(ra) # 80001908 <myproc>
}
    800030d0:	5908                	lw	a0,48(a0)
    800030d2:	60a2                	ld	ra,8(sp)
    800030d4:	6402                	ld	s0,0(sp)
    800030d6:	0141                	addi	sp,sp,16
    800030d8:	8082                	ret

00000000800030da <sys_fork>:

uint64
sys_fork(void)
{
    800030da:	1141                	addi	sp,sp,-16
    800030dc:	e406                	sd	ra,8(sp)
    800030de:	e022                	sd	s0,0(sp)
    800030e0:	0800                	addi	s0,sp,16
  return fork();
    800030e2:	fffff097          	auipc	ra,0xfffff
    800030e6:	7b8080e7          	jalr	1976(ra) # 8000289a <fork>
}
    800030ea:	60a2                	ld	ra,8(sp)
    800030ec:	6402                	ld	s0,0(sp)
    800030ee:	0141                	addi	sp,sp,16
    800030f0:	8082                	ret

00000000800030f2 <sys_wait>:

uint64
sys_wait(void)
{
    800030f2:	1101                	addi	sp,sp,-32
    800030f4:	ec06                	sd	ra,24(sp)
    800030f6:	e822                	sd	s0,16(sp)
    800030f8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800030fa:	fe840593          	addi	a1,s0,-24
    800030fe:	4501                	li	a0,0
    80003100:	00000097          	auipc	ra,0x0
    80003104:	ece080e7          	jalr	-306(ra) # 80002fce <argaddr>
    80003108:	87aa                	mv	a5,a0
    return -1;
    8000310a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000310c:	0007c863          	bltz	a5,8000311c <sys_wait+0x2a>
  return wait(p);
    80003110:	fe843503          	ld	a0,-24(s0)
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	1d6080e7          	jalr	470(ra) # 800022ea <wait>
}
    8000311c:	60e2                	ld	ra,24(sp)
    8000311e:	6442                	ld	s0,16(sp)
    80003120:	6105                	addi	sp,sp,32
    80003122:	8082                	ret

0000000080003124 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003124:	7179                	addi	sp,sp,-48
    80003126:	f406                	sd	ra,40(sp)
    80003128:	f022                	sd	s0,32(sp)
    8000312a:	ec26                	sd	s1,24(sp)
    8000312c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000312e:	fdc40593          	addi	a1,s0,-36
    80003132:	4501                	li	a0,0
    80003134:	00000097          	auipc	ra,0x0
    80003138:	e78080e7          	jalr	-392(ra) # 80002fac <argint>
    8000313c:	87aa                	mv	a5,a0
    return -1;
    8000313e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003140:	0207c063          	bltz	a5,80003160 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	7c4080e7          	jalr	1988(ra) # 80001908 <myproc>
    8000314c:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    8000314e:	fdc42503          	lw	a0,-36(s0)
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	962080e7          	jalr	-1694(ra) # 80001ab4 <growproc>
    8000315a:	00054863          	bltz	a0,8000316a <sys_sbrk+0x46>
    return -1;
  return addr;
    8000315e:	8526                	mv	a0,s1
}
    80003160:	70a2                	ld	ra,40(sp)
    80003162:	7402                	ld	s0,32(sp)
    80003164:	64e2                	ld	s1,24(sp)
    80003166:	6145                	addi	sp,sp,48
    80003168:	8082                	ret
    return -1;
    8000316a:	557d                	li	a0,-1
    8000316c:	bfd5                	j	80003160 <sys_sbrk+0x3c>

000000008000316e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000316e:	7139                	addi	sp,sp,-64
    80003170:	fc06                	sd	ra,56(sp)
    80003172:	f822                	sd	s0,48(sp)
    80003174:	f426                	sd	s1,40(sp)
    80003176:	f04a                	sd	s2,32(sp)
    80003178:	ec4e                	sd	s3,24(sp)
    8000317a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000317c:	fcc40593          	addi	a1,s0,-52
    80003180:	4501                	li	a0,0
    80003182:	00000097          	auipc	ra,0x0
    80003186:	e2a080e7          	jalr	-470(ra) # 80002fac <argint>
    return -1;
    8000318a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000318c:	06054563          	bltz	a0,800031f6 <sys_sleep+0x88>
  acquire(&tickslock);
    80003190:	00015517          	auipc	a0,0x15
    80003194:	88850513          	addi	a0,a0,-1912 # 80017a18 <tickslock>
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	a4c080e7          	jalr	-1460(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800031a0:	00006917          	auipc	s2,0x6
    800031a4:	e9092903          	lw	s2,-368(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800031a8:	fcc42783          	lw	a5,-52(s0)
    800031ac:	cf85                	beqz	a5,800031e4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031ae:	00015997          	auipc	s3,0x15
    800031b2:	86a98993          	addi	s3,s3,-1942 # 80017a18 <tickslock>
    800031b6:	00006497          	auipc	s1,0x6
    800031ba:	e7a48493          	addi	s1,s1,-390 # 80009030 <ticks>
    if(myproc()->killed){
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	74a080e7          	jalr	1866(ra) # 80001908 <myproc>
    800031c6:	551c                	lw	a5,40(a0)
    800031c8:	ef9d                	bnez	a5,80003206 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800031ca:	85ce                	mv	a1,s3
    800031cc:	8526                	mv	a0,s1
    800031ce:	fffff097          	auipc	ra,0xfffff
    800031d2:	eda080e7          	jalr	-294(ra) # 800020a8 <sleep>
  while(ticks - ticks0 < n){
    800031d6:	409c                	lw	a5,0(s1)
    800031d8:	412787bb          	subw	a5,a5,s2
    800031dc:	fcc42703          	lw	a4,-52(s0)
    800031e0:	fce7efe3          	bltu	a5,a4,800031be <sys_sleep+0x50>
  }
  release(&tickslock);
    800031e4:	00015517          	auipc	a0,0x15
    800031e8:	83450513          	addi	a0,a0,-1996 # 80017a18 <tickslock>
    800031ec:	ffffe097          	auipc	ra,0xffffe
    800031f0:	aac080e7          	jalr	-1364(ra) # 80000c98 <release>
  return 0;
    800031f4:	4781                	li	a5,0
}
    800031f6:	853e                	mv	a0,a5
    800031f8:	70e2                	ld	ra,56(sp)
    800031fa:	7442                	ld	s0,48(sp)
    800031fc:	74a2                	ld	s1,40(sp)
    800031fe:	7902                	ld	s2,32(sp)
    80003200:	69e2                	ld	s3,24(sp)
    80003202:	6121                	addi	sp,sp,64
    80003204:	8082                	ret
      release(&tickslock);
    80003206:	00015517          	auipc	a0,0x15
    8000320a:	81250513          	addi	a0,a0,-2030 # 80017a18 <tickslock>
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
      return -1;
    80003216:	57fd                	li	a5,-1
    80003218:	bff9                	j	800031f6 <sys_sleep+0x88>

000000008000321a <sys_kill>:

uint64
sys_kill(void)
{
    8000321a:	1101                	addi	sp,sp,-32
    8000321c:	ec06                	sd	ra,24(sp)
    8000321e:	e822                	sd	s0,16(sp)
    80003220:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003222:	fec40593          	addi	a1,s0,-20
    80003226:	4501                	li	a0,0
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	d84080e7          	jalr	-636(ra) # 80002fac <argint>
    80003230:	87aa                	mv	a5,a0
    return -1;
    80003232:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003234:	0007c863          	bltz	a5,80003244 <sys_kill+0x2a>
  return kill(pid);
    80003238:	fec42503          	lw	a0,-20(s0)
    8000323c:	fffff097          	auipc	ra,0xfffff
    80003240:	9da080e7          	jalr	-1574(ra) # 80001c16 <kill>
}
    80003244:	60e2                	ld	ra,24(sp)
    80003246:	6442                	ld	s0,16(sp)
    80003248:	6105                	addi	sp,sp,32
    8000324a:	8082                	ret

000000008000324c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000324c:	1101                	addi	sp,sp,-32
    8000324e:	ec06                	sd	ra,24(sp)
    80003250:	e822                	sd	s0,16(sp)
    80003252:	e426                	sd	s1,8(sp)
    80003254:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003256:	00014517          	auipc	a0,0x14
    8000325a:	7c250513          	addi	a0,a0,1986 # 80017a18 <tickslock>
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	986080e7          	jalr	-1658(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003266:	00006497          	auipc	s1,0x6
    8000326a:	dca4a483          	lw	s1,-566(s1) # 80009030 <ticks>
  release(&tickslock);
    8000326e:	00014517          	auipc	a0,0x14
    80003272:	7aa50513          	addi	a0,a0,1962 # 80017a18 <tickslock>
    80003276:	ffffe097          	auipc	ra,0xffffe
    8000327a:	a22080e7          	jalr	-1502(ra) # 80000c98 <release>
  return xticks;
}
    8000327e:	02049513          	slli	a0,s1,0x20
    80003282:	9101                	srli	a0,a0,0x20
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	64a2                	ld	s1,8(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret

000000008000328e <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    8000328e:	1101                	addi	sp,sp,-32
    80003290:	ec06                	sd	ra,24(sp)
    80003292:	e822                	sd	s0,16(sp)
    80003294:	1000                	addi	s0,sp,32
    int cpu_num;
    if(argint(0, &cpu_num) <= -1){
    80003296:	fec40593          	addi	a1,s0,-20
    8000329a:	4501                	li	a0,0
    8000329c:	00000097          	auipc	ra,0x0
    800032a0:	d10080e7          	jalr	-752(ra) # 80002fac <argint>
    800032a4:	87aa                	mv	a5,a0
      return -1;
    800032a6:	557d                	li	a0,-1
    if(argint(0, &cpu_num) <= -1){
    800032a8:	0007c863          	bltz	a5,800032b8 <sys_set_cpu+0x2a>
    }
    
    return set_cpu(cpu_num);
    800032ac:	fec42503          	lw	a0,-20(s0)
    800032b0:	fffff097          	auipc	ra,0xfffff
    800032b4:	dba080e7          	jalr	-582(ra) # 8000206a <set_cpu>
}
    800032b8:	60e2                	ld	ra,24(sp)
    800032ba:	6442                	ld	s0,16(sp)
    800032bc:	6105                	addi	sp,sp,32
    800032be:	8082                	ret

00000000800032c0 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800032c0:	1141                	addi	sp,sp,-16
    800032c2:	e406                	sd	ra,8(sp)
    800032c4:	e022                	sd	s0,0(sp)
    800032c6:	0800                	addi	s0,sp,16
    return get_cpu();
    800032c8:	fffff097          	auipc	ra,0xfffff
    800032cc:	b1a080e7          	jalr	-1254(ra) # 80001de2 <get_cpu>
    800032d0:	60a2                	ld	ra,8(sp)
    800032d2:	6402                	ld	s0,0(sp)
    800032d4:	0141                	addi	sp,sp,16
    800032d6:	8082                	ret

00000000800032d8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032d8:	7179                	addi	sp,sp,-48
    800032da:	f406                	sd	ra,40(sp)
    800032dc:	f022                	sd	s0,32(sp)
    800032de:	ec26                	sd	s1,24(sp)
    800032e0:	e84a                	sd	s2,16(sp)
    800032e2:	e44e                	sd	s3,8(sp)
    800032e4:	e052                	sd	s4,0(sp)
    800032e6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032e8:	00005597          	auipc	a1,0x5
    800032ec:	22058593          	addi	a1,a1,544 # 80008508 <syscalls+0xc0>
    800032f0:	00014517          	auipc	a0,0x14
    800032f4:	74050513          	addi	a0,a0,1856 # 80017a30 <bcache>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	85c080e7          	jalr	-1956(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003300:	0001c797          	auipc	a5,0x1c
    80003304:	73078793          	addi	a5,a5,1840 # 8001fa30 <bcache+0x8000>
    80003308:	0001d717          	auipc	a4,0x1d
    8000330c:	99070713          	addi	a4,a4,-1648 # 8001fc98 <bcache+0x8268>
    80003310:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003314:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003318:	00014497          	auipc	s1,0x14
    8000331c:	73048493          	addi	s1,s1,1840 # 80017a48 <bcache+0x18>
    b->next = bcache.head.next;
    80003320:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003322:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003324:	00005a17          	auipc	s4,0x5
    80003328:	1eca0a13          	addi	s4,s4,492 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000332c:	2b893783          	ld	a5,696(s2)
    80003330:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003332:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003336:	85d2                	mv	a1,s4
    80003338:	01048513          	addi	a0,s1,16
    8000333c:	00001097          	auipc	ra,0x1
    80003340:	4bc080e7          	jalr	1212(ra) # 800047f8 <initsleeplock>
    bcache.head.next->prev = b;
    80003344:	2b893783          	ld	a5,696(s2)
    80003348:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000334a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000334e:	45848493          	addi	s1,s1,1112
    80003352:	fd349de3          	bne	s1,s3,8000332c <binit+0x54>
  }
}
    80003356:	70a2                	ld	ra,40(sp)
    80003358:	7402                	ld	s0,32(sp)
    8000335a:	64e2                	ld	s1,24(sp)
    8000335c:	6942                	ld	s2,16(sp)
    8000335e:	69a2                	ld	s3,8(sp)
    80003360:	6a02                	ld	s4,0(sp)
    80003362:	6145                	addi	sp,sp,48
    80003364:	8082                	ret

0000000080003366 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003366:	7179                	addi	sp,sp,-48
    80003368:	f406                	sd	ra,40(sp)
    8000336a:	f022                	sd	s0,32(sp)
    8000336c:	ec26                	sd	s1,24(sp)
    8000336e:	e84a                	sd	s2,16(sp)
    80003370:	e44e                	sd	s3,8(sp)
    80003372:	1800                	addi	s0,sp,48
    80003374:	89aa                	mv	s3,a0
    80003376:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003378:	00014517          	auipc	a0,0x14
    8000337c:	6b850513          	addi	a0,a0,1720 # 80017a30 <bcache>
    80003380:	ffffe097          	auipc	ra,0xffffe
    80003384:	864080e7          	jalr	-1948(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003388:	0001d497          	auipc	s1,0x1d
    8000338c:	9604b483          	ld	s1,-1696(s1) # 8001fce8 <bcache+0x82b8>
    80003390:	0001d797          	auipc	a5,0x1d
    80003394:	90878793          	addi	a5,a5,-1784 # 8001fc98 <bcache+0x8268>
    80003398:	02f48f63          	beq	s1,a5,800033d6 <bread+0x70>
    8000339c:	873e                	mv	a4,a5
    8000339e:	a021                	j	800033a6 <bread+0x40>
    800033a0:	68a4                	ld	s1,80(s1)
    800033a2:	02e48a63          	beq	s1,a4,800033d6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033a6:	449c                	lw	a5,8(s1)
    800033a8:	ff379ce3          	bne	a5,s3,800033a0 <bread+0x3a>
    800033ac:	44dc                	lw	a5,12(s1)
    800033ae:	ff2799e3          	bne	a5,s2,800033a0 <bread+0x3a>
      b->refcnt++;
    800033b2:	40bc                	lw	a5,64(s1)
    800033b4:	2785                	addiw	a5,a5,1
    800033b6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033b8:	00014517          	auipc	a0,0x14
    800033bc:	67850513          	addi	a0,a0,1656 # 80017a30 <bcache>
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	8d8080e7          	jalr	-1832(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033c8:	01048513          	addi	a0,s1,16
    800033cc:	00001097          	auipc	ra,0x1
    800033d0:	466080e7          	jalr	1126(ra) # 80004832 <acquiresleep>
      return b;
    800033d4:	a8b9                	j	80003432 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033d6:	0001d497          	auipc	s1,0x1d
    800033da:	90a4b483          	ld	s1,-1782(s1) # 8001fce0 <bcache+0x82b0>
    800033de:	0001d797          	auipc	a5,0x1d
    800033e2:	8ba78793          	addi	a5,a5,-1862 # 8001fc98 <bcache+0x8268>
    800033e6:	00f48863          	beq	s1,a5,800033f6 <bread+0x90>
    800033ea:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033ec:	40bc                	lw	a5,64(s1)
    800033ee:	cf81                	beqz	a5,80003406 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033f0:	64a4                	ld	s1,72(s1)
    800033f2:	fee49de3          	bne	s1,a4,800033ec <bread+0x86>
  panic("bget: no buffers");
    800033f6:	00005517          	auipc	a0,0x5
    800033fa:	12250513          	addi	a0,a0,290 # 80008518 <syscalls+0xd0>
    800033fe:	ffffd097          	auipc	ra,0xffffd
    80003402:	140080e7          	jalr	320(ra) # 8000053e <panic>
      b->dev = dev;
    80003406:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000340a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000340e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003412:	4785                	li	a5,1
    80003414:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003416:	00014517          	auipc	a0,0x14
    8000341a:	61a50513          	addi	a0,a0,1562 # 80017a30 <bcache>
    8000341e:	ffffe097          	auipc	ra,0xffffe
    80003422:	87a080e7          	jalr	-1926(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003426:	01048513          	addi	a0,s1,16
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	408080e7          	jalr	1032(ra) # 80004832 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003432:	409c                	lw	a5,0(s1)
    80003434:	cb89                	beqz	a5,80003446 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003436:	8526                	mv	a0,s1
    80003438:	70a2                	ld	ra,40(sp)
    8000343a:	7402                	ld	s0,32(sp)
    8000343c:	64e2                	ld	s1,24(sp)
    8000343e:	6942                	ld	s2,16(sp)
    80003440:	69a2                	ld	s3,8(sp)
    80003442:	6145                	addi	sp,sp,48
    80003444:	8082                	ret
    virtio_disk_rw(b, 0);
    80003446:	4581                	li	a1,0
    80003448:	8526                	mv	a0,s1
    8000344a:	00003097          	auipc	ra,0x3
    8000344e:	f0c080e7          	jalr	-244(ra) # 80006356 <virtio_disk_rw>
    b->valid = 1;
    80003452:	4785                	li	a5,1
    80003454:	c09c                	sw	a5,0(s1)
  return b;
    80003456:	b7c5                	j	80003436 <bread+0xd0>

0000000080003458 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003458:	1101                	addi	sp,sp,-32
    8000345a:	ec06                	sd	ra,24(sp)
    8000345c:	e822                	sd	s0,16(sp)
    8000345e:	e426                	sd	s1,8(sp)
    80003460:	1000                	addi	s0,sp,32
    80003462:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003464:	0541                	addi	a0,a0,16
    80003466:	00001097          	auipc	ra,0x1
    8000346a:	466080e7          	jalr	1126(ra) # 800048cc <holdingsleep>
    8000346e:	cd01                	beqz	a0,80003486 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003470:	4585                	li	a1,1
    80003472:	8526                	mv	a0,s1
    80003474:	00003097          	auipc	ra,0x3
    80003478:	ee2080e7          	jalr	-286(ra) # 80006356 <virtio_disk_rw>
}
    8000347c:	60e2                	ld	ra,24(sp)
    8000347e:	6442                	ld	s0,16(sp)
    80003480:	64a2                	ld	s1,8(sp)
    80003482:	6105                	addi	sp,sp,32
    80003484:	8082                	ret
    panic("bwrite");
    80003486:	00005517          	auipc	a0,0x5
    8000348a:	0aa50513          	addi	a0,a0,170 # 80008530 <syscalls+0xe8>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>

0000000080003496 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003496:	1101                	addi	sp,sp,-32
    80003498:	ec06                	sd	ra,24(sp)
    8000349a:	e822                	sd	s0,16(sp)
    8000349c:	e426                	sd	s1,8(sp)
    8000349e:	e04a                	sd	s2,0(sp)
    800034a0:	1000                	addi	s0,sp,32
    800034a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034a4:	01050913          	addi	s2,a0,16
    800034a8:	854a                	mv	a0,s2
    800034aa:	00001097          	auipc	ra,0x1
    800034ae:	422080e7          	jalr	1058(ra) # 800048cc <holdingsleep>
    800034b2:	c92d                	beqz	a0,80003524 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034b4:	854a                	mv	a0,s2
    800034b6:	00001097          	auipc	ra,0x1
    800034ba:	3d2080e7          	jalr	978(ra) # 80004888 <releasesleep>

  acquire(&bcache.lock);
    800034be:	00014517          	auipc	a0,0x14
    800034c2:	57250513          	addi	a0,a0,1394 # 80017a30 <bcache>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	71e080e7          	jalr	1822(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034ce:	40bc                	lw	a5,64(s1)
    800034d0:	37fd                	addiw	a5,a5,-1
    800034d2:	0007871b          	sext.w	a4,a5
    800034d6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034d8:	eb05                	bnez	a4,80003508 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034da:	68bc                	ld	a5,80(s1)
    800034dc:	64b8                	ld	a4,72(s1)
    800034de:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034e0:	64bc                	ld	a5,72(s1)
    800034e2:	68b8                	ld	a4,80(s1)
    800034e4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034e6:	0001c797          	auipc	a5,0x1c
    800034ea:	54a78793          	addi	a5,a5,1354 # 8001fa30 <bcache+0x8000>
    800034ee:	2b87b703          	ld	a4,696(a5)
    800034f2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034f4:	0001c717          	auipc	a4,0x1c
    800034f8:	7a470713          	addi	a4,a4,1956 # 8001fc98 <bcache+0x8268>
    800034fc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034fe:	2b87b703          	ld	a4,696(a5)
    80003502:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003504:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003508:	00014517          	auipc	a0,0x14
    8000350c:	52850513          	addi	a0,a0,1320 # 80017a30 <bcache>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	788080e7          	jalr	1928(ra) # 80000c98 <release>
}
    80003518:	60e2                	ld	ra,24(sp)
    8000351a:	6442                	ld	s0,16(sp)
    8000351c:	64a2                	ld	s1,8(sp)
    8000351e:	6902                	ld	s2,0(sp)
    80003520:	6105                	addi	sp,sp,32
    80003522:	8082                	ret
    panic("brelse");
    80003524:	00005517          	auipc	a0,0x5
    80003528:	01450513          	addi	a0,a0,20 # 80008538 <syscalls+0xf0>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	012080e7          	jalr	18(ra) # 8000053e <panic>

0000000080003534 <bpin>:

void
bpin(struct buf *b) {
    80003534:	1101                	addi	sp,sp,-32
    80003536:	ec06                	sd	ra,24(sp)
    80003538:	e822                	sd	s0,16(sp)
    8000353a:	e426                	sd	s1,8(sp)
    8000353c:	1000                	addi	s0,sp,32
    8000353e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003540:	00014517          	auipc	a0,0x14
    80003544:	4f050513          	addi	a0,a0,1264 # 80017a30 <bcache>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	69c080e7          	jalr	1692(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003550:	40bc                	lw	a5,64(s1)
    80003552:	2785                	addiw	a5,a5,1
    80003554:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003556:	00014517          	auipc	a0,0x14
    8000355a:	4da50513          	addi	a0,a0,1242 # 80017a30 <bcache>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	73a080e7          	jalr	1850(ra) # 80000c98 <release>
}
    80003566:	60e2                	ld	ra,24(sp)
    80003568:	6442                	ld	s0,16(sp)
    8000356a:	64a2                	ld	s1,8(sp)
    8000356c:	6105                	addi	sp,sp,32
    8000356e:	8082                	ret

0000000080003570 <bunpin>:

void
bunpin(struct buf *b) {
    80003570:	1101                	addi	sp,sp,-32
    80003572:	ec06                	sd	ra,24(sp)
    80003574:	e822                	sd	s0,16(sp)
    80003576:	e426                	sd	s1,8(sp)
    80003578:	1000                	addi	s0,sp,32
    8000357a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000357c:	00014517          	auipc	a0,0x14
    80003580:	4b450513          	addi	a0,a0,1204 # 80017a30 <bcache>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	660080e7          	jalr	1632(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000358c:	40bc                	lw	a5,64(s1)
    8000358e:	37fd                	addiw	a5,a5,-1
    80003590:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003592:	00014517          	auipc	a0,0x14
    80003596:	49e50513          	addi	a0,a0,1182 # 80017a30 <bcache>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	6fe080e7          	jalr	1790(ra) # 80000c98 <release>
}
    800035a2:	60e2                	ld	ra,24(sp)
    800035a4:	6442                	ld	s0,16(sp)
    800035a6:	64a2                	ld	s1,8(sp)
    800035a8:	6105                	addi	sp,sp,32
    800035aa:	8082                	ret

00000000800035ac <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035ac:	1101                	addi	sp,sp,-32
    800035ae:	ec06                	sd	ra,24(sp)
    800035b0:	e822                	sd	s0,16(sp)
    800035b2:	e426                	sd	s1,8(sp)
    800035b4:	e04a                	sd	s2,0(sp)
    800035b6:	1000                	addi	s0,sp,32
    800035b8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035ba:	00d5d59b          	srliw	a1,a1,0xd
    800035be:	0001d797          	auipc	a5,0x1d
    800035c2:	b4e7a783          	lw	a5,-1202(a5) # 8002010c <sb+0x1c>
    800035c6:	9dbd                	addw	a1,a1,a5
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	d9e080e7          	jalr	-610(ra) # 80003366 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035d0:	0074f713          	andi	a4,s1,7
    800035d4:	4785                	li	a5,1
    800035d6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035da:	14ce                	slli	s1,s1,0x33
    800035dc:	90d9                	srli	s1,s1,0x36
    800035de:	00950733          	add	a4,a0,s1
    800035e2:	05874703          	lbu	a4,88(a4)
    800035e6:	00e7f6b3          	and	a3,a5,a4
    800035ea:	c69d                	beqz	a3,80003618 <bfree+0x6c>
    800035ec:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035ee:	94aa                	add	s1,s1,a0
    800035f0:	fff7c793          	not	a5,a5
    800035f4:	8ff9                	and	a5,a5,a4
    800035f6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800035fa:	00001097          	auipc	ra,0x1
    800035fe:	118080e7          	jalr	280(ra) # 80004712 <log_write>
  brelse(bp);
    80003602:	854a                	mv	a0,s2
    80003604:	00000097          	auipc	ra,0x0
    80003608:	e92080e7          	jalr	-366(ra) # 80003496 <brelse>
}
    8000360c:	60e2                	ld	ra,24(sp)
    8000360e:	6442                	ld	s0,16(sp)
    80003610:	64a2                	ld	s1,8(sp)
    80003612:	6902                	ld	s2,0(sp)
    80003614:	6105                	addi	sp,sp,32
    80003616:	8082                	ret
    panic("freeing free block");
    80003618:	00005517          	auipc	a0,0x5
    8000361c:	f2850513          	addi	a0,a0,-216 # 80008540 <syscalls+0xf8>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	f1e080e7          	jalr	-226(ra) # 8000053e <panic>

0000000080003628 <balloc>:
{
    80003628:	711d                	addi	sp,sp,-96
    8000362a:	ec86                	sd	ra,88(sp)
    8000362c:	e8a2                	sd	s0,80(sp)
    8000362e:	e4a6                	sd	s1,72(sp)
    80003630:	e0ca                	sd	s2,64(sp)
    80003632:	fc4e                	sd	s3,56(sp)
    80003634:	f852                	sd	s4,48(sp)
    80003636:	f456                	sd	s5,40(sp)
    80003638:	f05a                	sd	s6,32(sp)
    8000363a:	ec5e                	sd	s7,24(sp)
    8000363c:	e862                	sd	s8,16(sp)
    8000363e:	e466                	sd	s9,8(sp)
    80003640:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003642:	0001d797          	auipc	a5,0x1d
    80003646:	ab27a783          	lw	a5,-1358(a5) # 800200f4 <sb+0x4>
    8000364a:	cbd1                	beqz	a5,800036de <balloc+0xb6>
    8000364c:	8baa                	mv	s7,a0
    8000364e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003650:	0001db17          	auipc	s6,0x1d
    80003654:	aa0b0b13          	addi	s6,s6,-1376 # 800200f0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003658:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000365a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000365c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000365e:	6c89                	lui	s9,0x2
    80003660:	a831                	j	8000367c <balloc+0x54>
    brelse(bp);
    80003662:	854a                	mv	a0,s2
    80003664:	00000097          	auipc	ra,0x0
    80003668:	e32080e7          	jalr	-462(ra) # 80003496 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000366c:	015c87bb          	addw	a5,s9,s5
    80003670:	00078a9b          	sext.w	s5,a5
    80003674:	004b2703          	lw	a4,4(s6)
    80003678:	06eaf363          	bgeu	s5,a4,800036de <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000367c:	41fad79b          	sraiw	a5,s5,0x1f
    80003680:	0137d79b          	srliw	a5,a5,0x13
    80003684:	015787bb          	addw	a5,a5,s5
    80003688:	40d7d79b          	sraiw	a5,a5,0xd
    8000368c:	01cb2583          	lw	a1,28(s6)
    80003690:	9dbd                	addw	a1,a1,a5
    80003692:	855e                	mv	a0,s7
    80003694:	00000097          	auipc	ra,0x0
    80003698:	cd2080e7          	jalr	-814(ra) # 80003366 <bread>
    8000369c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000369e:	004b2503          	lw	a0,4(s6)
    800036a2:	000a849b          	sext.w	s1,s5
    800036a6:	8662                	mv	a2,s8
    800036a8:	faa4fde3          	bgeu	s1,a0,80003662 <balloc+0x3a>
      m = 1 << (bi % 8);
    800036ac:	41f6579b          	sraiw	a5,a2,0x1f
    800036b0:	01d7d69b          	srliw	a3,a5,0x1d
    800036b4:	00c6873b          	addw	a4,a3,a2
    800036b8:	00777793          	andi	a5,a4,7
    800036bc:	9f95                	subw	a5,a5,a3
    800036be:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036c2:	4037571b          	sraiw	a4,a4,0x3
    800036c6:	00e906b3          	add	a3,s2,a4
    800036ca:	0586c683          	lbu	a3,88(a3)
    800036ce:	00d7f5b3          	and	a1,a5,a3
    800036d2:	cd91                	beqz	a1,800036ee <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036d4:	2605                	addiw	a2,a2,1
    800036d6:	2485                	addiw	s1,s1,1
    800036d8:	fd4618e3          	bne	a2,s4,800036a8 <balloc+0x80>
    800036dc:	b759                	j	80003662 <balloc+0x3a>
  panic("balloc: out of blocks");
    800036de:	00005517          	auipc	a0,0x5
    800036e2:	e7a50513          	addi	a0,a0,-390 # 80008558 <syscalls+0x110>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	e58080e7          	jalr	-424(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036ee:	974a                	add	a4,a4,s2
    800036f0:	8fd5                	or	a5,a5,a3
    800036f2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036f6:	854a                	mv	a0,s2
    800036f8:	00001097          	auipc	ra,0x1
    800036fc:	01a080e7          	jalr	26(ra) # 80004712 <log_write>
        brelse(bp);
    80003700:	854a                	mv	a0,s2
    80003702:	00000097          	auipc	ra,0x0
    80003706:	d94080e7          	jalr	-620(ra) # 80003496 <brelse>
  bp = bread(dev, bno);
    8000370a:	85a6                	mv	a1,s1
    8000370c:	855e                	mv	a0,s7
    8000370e:	00000097          	auipc	ra,0x0
    80003712:	c58080e7          	jalr	-936(ra) # 80003366 <bread>
    80003716:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003718:	40000613          	li	a2,1024
    8000371c:	4581                	li	a1,0
    8000371e:	05850513          	addi	a0,a0,88
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	5be080e7          	jalr	1470(ra) # 80000ce0 <memset>
  log_write(bp);
    8000372a:	854a                	mv	a0,s2
    8000372c:	00001097          	auipc	ra,0x1
    80003730:	fe6080e7          	jalr	-26(ra) # 80004712 <log_write>
  brelse(bp);
    80003734:	854a                	mv	a0,s2
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	d60080e7          	jalr	-672(ra) # 80003496 <brelse>
}
    8000373e:	8526                	mv	a0,s1
    80003740:	60e6                	ld	ra,88(sp)
    80003742:	6446                	ld	s0,80(sp)
    80003744:	64a6                	ld	s1,72(sp)
    80003746:	6906                	ld	s2,64(sp)
    80003748:	79e2                	ld	s3,56(sp)
    8000374a:	7a42                	ld	s4,48(sp)
    8000374c:	7aa2                	ld	s5,40(sp)
    8000374e:	7b02                	ld	s6,32(sp)
    80003750:	6be2                	ld	s7,24(sp)
    80003752:	6c42                	ld	s8,16(sp)
    80003754:	6ca2                	ld	s9,8(sp)
    80003756:	6125                	addi	sp,sp,96
    80003758:	8082                	ret

000000008000375a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000375a:	7179                	addi	sp,sp,-48
    8000375c:	f406                	sd	ra,40(sp)
    8000375e:	f022                	sd	s0,32(sp)
    80003760:	ec26                	sd	s1,24(sp)
    80003762:	e84a                	sd	s2,16(sp)
    80003764:	e44e                	sd	s3,8(sp)
    80003766:	e052                	sd	s4,0(sp)
    80003768:	1800                	addi	s0,sp,48
    8000376a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000376c:	47ad                	li	a5,11
    8000376e:	04b7fe63          	bgeu	a5,a1,800037ca <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003772:	ff45849b          	addiw	s1,a1,-12
    80003776:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000377a:	0ff00793          	li	a5,255
    8000377e:	0ae7e363          	bltu	a5,a4,80003824 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003782:	08052583          	lw	a1,128(a0)
    80003786:	c5ad                	beqz	a1,800037f0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003788:	00092503          	lw	a0,0(s2)
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	bda080e7          	jalr	-1062(ra) # 80003366 <bread>
    80003794:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003796:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000379a:	02049593          	slli	a1,s1,0x20
    8000379e:	9181                	srli	a1,a1,0x20
    800037a0:	058a                	slli	a1,a1,0x2
    800037a2:	00b784b3          	add	s1,a5,a1
    800037a6:	0004a983          	lw	s3,0(s1)
    800037aa:	04098d63          	beqz	s3,80003804 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037ae:	8552                	mv	a0,s4
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	ce6080e7          	jalr	-794(ra) # 80003496 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037b8:	854e                	mv	a0,s3
    800037ba:	70a2                	ld	ra,40(sp)
    800037bc:	7402                	ld	s0,32(sp)
    800037be:	64e2                	ld	s1,24(sp)
    800037c0:	6942                	ld	s2,16(sp)
    800037c2:	69a2                	ld	s3,8(sp)
    800037c4:	6a02                	ld	s4,0(sp)
    800037c6:	6145                	addi	sp,sp,48
    800037c8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037ca:	02059493          	slli	s1,a1,0x20
    800037ce:	9081                	srli	s1,s1,0x20
    800037d0:	048a                	slli	s1,s1,0x2
    800037d2:	94aa                	add	s1,s1,a0
    800037d4:	0504a983          	lw	s3,80(s1)
    800037d8:	fe0990e3          	bnez	s3,800037b8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037dc:	4108                	lw	a0,0(a0)
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	e4a080e7          	jalr	-438(ra) # 80003628 <balloc>
    800037e6:	0005099b          	sext.w	s3,a0
    800037ea:	0534a823          	sw	s3,80(s1)
    800037ee:	b7e9                	j	800037b8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800037f0:	4108                	lw	a0,0(a0)
    800037f2:	00000097          	auipc	ra,0x0
    800037f6:	e36080e7          	jalr	-458(ra) # 80003628 <balloc>
    800037fa:	0005059b          	sext.w	a1,a0
    800037fe:	08b92023          	sw	a1,128(s2)
    80003802:	b759                	j	80003788 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003804:	00092503          	lw	a0,0(s2)
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	e20080e7          	jalr	-480(ra) # 80003628 <balloc>
    80003810:	0005099b          	sext.w	s3,a0
    80003814:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003818:	8552                	mv	a0,s4
    8000381a:	00001097          	auipc	ra,0x1
    8000381e:	ef8080e7          	jalr	-264(ra) # 80004712 <log_write>
    80003822:	b771                	j	800037ae <bmap+0x54>
  panic("bmap: out of range");
    80003824:	00005517          	auipc	a0,0x5
    80003828:	d4c50513          	addi	a0,a0,-692 # 80008570 <syscalls+0x128>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	d12080e7          	jalr	-750(ra) # 8000053e <panic>

0000000080003834 <iget>:
{
    80003834:	7179                	addi	sp,sp,-48
    80003836:	f406                	sd	ra,40(sp)
    80003838:	f022                	sd	s0,32(sp)
    8000383a:	ec26                	sd	s1,24(sp)
    8000383c:	e84a                	sd	s2,16(sp)
    8000383e:	e44e                	sd	s3,8(sp)
    80003840:	e052                	sd	s4,0(sp)
    80003842:	1800                	addi	s0,sp,48
    80003844:	89aa                	mv	s3,a0
    80003846:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003848:	0001d517          	auipc	a0,0x1d
    8000384c:	8c850513          	addi	a0,a0,-1848 # 80020110 <itable>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	394080e7          	jalr	916(ra) # 80000be4 <acquire>
  empty = 0;
    80003858:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000385a:	0001d497          	auipc	s1,0x1d
    8000385e:	8ce48493          	addi	s1,s1,-1842 # 80020128 <itable+0x18>
    80003862:	0001e697          	auipc	a3,0x1e
    80003866:	35668693          	addi	a3,a3,854 # 80021bb8 <log>
    8000386a:	a039                	j	80003878 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000386c:	02090b63          	beqz	s2,800038a2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003870:	08848493          	addi	s1,s1,136
    80003874:	02d48a63          	beq	s1,a3,800038a8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003878:	449c                	lw	a5,8(s1)
    8000387a:	fef059e3          	blez	a5,8000386c <iget+0x38>
    8000387e:	4098                	lw	a4,0(s1)
    80003880:	ff3716e3          	bne	a4,s3,8000386c <iget+0x38>
    80003884:	40d8                	lw	a4,4(s1)
    80003886:	ff4713e3          	bne	a4,s4,8000386c <iget+0x38>
      ip->ref++;
    8000388a:	2785                	addiw	a5,a5,1
    8000388c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000388e:	0001d517          	auipc	a0,0x1d
    80003892:	88250513          	addi	a0,a0,-1918 # 80020110 <itable>
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	402080e7          	jalr	1026(ra) # 80000c98 <release>
      return ip;
    8000389e:	8926                	mv	s2,s1
    800038a0:	a03d                	j	800038ce <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038a2:	f7f9                	bnez	a5,80003870 <iget+0x3c>
    800038a4:	8926                	mv	s2,s1
    800038a6:	b7e9                	j	80003870 <iget+0x3c>
  if(empty == 0)
    800038a8:	02090c63          	beqz	s2,800038e0 <iget+0xac>
  ip->dev = dev;
    800038ac:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038b0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038b4:	4785                	li	a5,1
    800038b6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038ba:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038be:	0001d517          	auipc	a0,0x1d
    800038c2:	85250513          	addi	a0,a0,-1966 # 80020110 <itable>
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	3d2080e7          	jalr	978(ra) # 80000c98 <release>
}
    800038ce:	854a                	mv	a0,s2
    800038d0:	70a2                	ld	ra,40(sp)
    800038d2:	7402                	ld	s0,32(sp)
    800038d4:	64e2                	ld	s1,24(sp)
    800038d6:	6942                	ld	s2,16(sp)
    800038d8:	69a2                	ld	s3,8(sp)
    800038da:	6a02                	ld	s4,0(sp)
    800038dc:	6145                	addi	sp,sp,48
    800038de:	8082                	ret
    panic("iget: no inodes");
    800038e0:	00005517          	auipc	a0,0x5
    800038e4:	ca850513          	addi	a0,a0,-856 # 80008588 <syscalls+0x140>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	c56080e7          	jalr	-938(ra) # 8000053e <panic>

00000000800038f0 <fsinit>:
fsinit(int dev) {
    800038f0:	7179                	addi	sp,sp,-48
    800038f2:	f406                	sd	ra,40(sp)
    800038f4:	f022                	sd	s0,32(sp)
    800038f6:	ec26                	sd	s1,24(sp)
    800038f8:	e84a                	sd	s2,16(sp)
    800038fa:	e44e                	sd	s3,8(sp)
    800038fc:	1800                	addi	s0,sp,48
    800038fe:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003900:	4585                	li	a1,1
    80003902:	00000097          	auipc	ra,0x0
    80003906:	a64080e7          	jalr	-1436(ra) # 80003366 <bread>
    8000390a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000390c:	0001c997          	auipc	s3,0x1c
    80003910:	7e498993          	addi	s3,s3,2020 # 800200f0 <sb>
    80003914:	02000613          	li	a2,32
    80003918:	05850593          	addi	a1,a0,88
    8000391c:	854e                	mv	a0,s3
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	422080e7          	jalr	1058(ra) # 80000d40 <memmove>
  brelse(bp);
    80003926:	8526                	mv	a0,s1
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	b6e080e7          	jalr	-1170(ra) # 80003496 <brelse>
  if(sb.magic != FSMAGIC)
    80003930:	0009a703          	lw	a4,0(s3)
    80003934:	102037b7          	lui	a5,0x10203
    80003938:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000393c:	02f71263          	bne	a4,a5,80003960 <fsinit+0x70>
  initlog(dev, &sb);
    80003940:	0001c597          	auipc	a1,0x1c
    80003944:	7b058593          	addi	a1,a1,1968 # 800200f0 <sb>
    80003948:	854a                	mv	a0,s2
    8000394a:	00001097          	auipc	ra,0x1
    8000394e:	b4c080e7          	jalr	-1204(ra) # 80004496 <initlog>
}
    80003952:	70a2                	ld	ra,40(sp)
    80003954:	7402                	ld	s0,32(sp)
    80003956:	64e2                	ld	s1,24(sp)
    80003958:	6942                	ld	s2,16(sp)
    8000395a:	69a2                	ld	s3,8(sp)
    8000395c:	6145                	addi	sp,sp,48
    8000395e:	8082                	ret
    panic("invalid file system");
    80003960:	00005517          	auipc	a0,0x5
    80003964:	c3850513          	addi	a0,a0,-968 # 80008598 <syscalls+0x150>
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	bd6080e7          	jalr	-1066(ra) # 8000053e <panic>

0000000080003970 <iinit>:
{
    80003970:	7179                	addi	sp,sp,-48
    80003972:	f406                	sd	ra,40(sp)
    80003974:	f022                	sd	s0,32(sp)
    80003976:	ec26                	sd	s1,24(sp)
    80003978:	e84a                	sd	s2,16(sp)
    8000397a:	e44e                	sd	s3,8(sp)
    8000397c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000397e:	00005597          	auipc	a1,0x5
    80003982:	c3258593          	addi	a1,a1,-974 # 800085b0 <syscalls+0x168>
    80003986:	0001c517          	auipc	a0,0x1c
    8000398a:	78a50513          	addi	a0,a0,1930 # 80020110 <itable>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	1c6080e7          	jalr	454(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003996:	0001c497          	auipc	s1,0x1c
    8000399a:	7a248493          	addi	s1,s1,1954 # 80020138 <itable+0x28>
    8000399e:	0001e997          	auipc	s3,0x1e
    800039a2:	22a98993          	addi	s3,s3,554 # 80021bc8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039a6:	00005917          	auipc	s2,0x5
    800039aa:	c1290913          	addi	s2,s2,-1006 # 800085b8 <syscalls+0x170>
    800039ae:	85ca                	mv	a1,s2
    800039b0:	8526                	mv	a0,s1
    800039b2:	00001097          	auipc	ra,0x1
    800039b6:	e46080e7          	jalr	-442(ra) # 800047f8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039ba:	08848493          	addi	s1,s1,136
    800039be:	ff3498e3          	bne	s1,s3,800039ae <iinit+0x3e>
}
    800039c2:	70a2                	ld	ra,40(sp)
    800039c4:	7402                	ld	s0,32(sp)
    800039c6:	64e2                	ld	s1,24(sp)
    800039c8:	6942                	ld	s2,16(sp)
    800039ca:	69a2                	ld	s3,8(sp)
    800039cc:	6145                	addi	sp,sp,48
    800039ce:	8082                	ret

00000000800039d0 <ialloc>:
{
    800039d0:	715d                	addi	sp,sp,-80
    800039d2:	e486                	sd	ra,72(sp)
    800039d4:	e0a2                	sd	s0,64(sp)
    800039d6:	fc26                	sd	s1,56(sp)
    800039d8:	f84a                	sd	s2,48(sp)
    800039da:	f44e                	sd	s3,40(sp)
    800039dc:	f052                	sd	s4,32(sp)
    800039de:	ec56                	sd	s5,24(sp)
    800039e0:	e85a                	sd	s6,16(sp)
    800039e2:	e45e                	sd	s7,8(sp)
    800039e4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039e6:	0001c717          	auipc	a4,0x1c
    800039ea:	71672703          	lw	a4,1814(a4) # 800200fc <sb+0xc>
    800039ee:	4785                	li	a5,1
    800039f0:	04e7fa63          	bgeu	a5,a4,80003a44 <ialloc+0x74>
    800039f4:	8aaa                	mv	s5,a0
    800039f6:	8bae                	mv	s7,a1
    800039f8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039fa:	0001ca17          	auipc	s4,0x1c
    800039fe:	6f6a0a13          	addi	s4,s4,1782 # 800200f0 <sb>
    80003a02:	00048b1b          	sext.w	s6,s1
    80003a06:	0044d593          	srli	a1,s1,0x4
    80003a0a:	018a2783          	lw	a5,24(s4)
    80003a0e:	9dbd                	addw	a1,a1,a5
    80003a10:	8556                	mv	a0,s5
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	954080e7          	jalr	-1708(ra) # 80003366 <bread>
    80003a1a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a1c:	05850993          	addi	s3,a0,88
    80003a20:	00f4f793          	andi	a5,s1,15
    80003a24:	079a                	slli	a5,a5,0x6
    80003a26:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a28:	00099783          	lh	a5,0(s3)
    80003a2c:	c785                	beqz	a5,80003a54 <ialloc+0x84>
    brelse(bp);
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	a68080e7          	jalr	-1432(ra) # 80003496 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a36:	0485                	addi	s1,s1,1
    80003a38:	00ca2703          	lw	a4,12(s4)
    80003a3c:	0004879b          	sext.w	a5,s1
    80003a40:	fce7e1e3          	bltu	a5,a4,80003a02 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a44:	00005517          	auipc	a0,0x5
    80003a48:	b7c50513          	addi	a0,a0,-1156 # 800085c0 <syscalls+0x178>
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	af2080e7          	jalr	-1294(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a54:	04000613          	li	a2,64
    80003a58:	4581                	li	a1,0
    80003a5a:	854e                	mv	a0,s3
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	284080e7          	jalr	644(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a64:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a68:	854a                	mv	a0,s2
    80003a6a:	00001097          	auipc	ra,0x1
    80003a6e:	ca8080e7          	jalr	-856(ra) # 80004712 <log_write>
      brelse(bp);
    80003a72:	854a                	mv	a0,s2
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	a22080e7          	jalr	-1502(ra) # 80003496 <brelse>
      return iget(dev, inum);
    80003a7c:	85da                	mv	a1,s6
    80003a7e:	8556                	mv	a0,s5
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	db4080e7          	jalr	-588(ra) # 80003834 <iget>
}
    80003a88:	60a6                	ld	ra,72(sp)
    80003a8a:	6406                	ld	s0,64(sp)
    80003a8c:	74e2                	ld	s1,56(sp)
    80003a8e:	7942                	ld	s2,48(sp)
    80003a90:	79a2                	ld	s3,40(sp)
    80003a92:	7a02                	ld	s4,32(sp)
    80003a94:	6ae2                	ld	s5,24(sp)
    80003a96:	6b42                	ld	s6,16(sp)
    80003a98:	6ba2                	ld	s7,8(sp)
    80003a9a:	6161                	addi	sp,sp,80
    80003a9c:	8082                	ret

0000000080003a9e <iupdate>:
{
    80003a9e:	1101                	addi	sp,sp,-32
    80003aa0:	ec06                	sd	ra,24(sp)
    80003aa2:	e822                	sd	s0,16(sp)
    80003aa4:	e426                	sd	s1,8(sp)
    80003aa6:	e04a                	sd	s2,0(sp)
    80003aa8:	1000                	addi	s0,sp,32
    80003aaa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003aac:	415c                	lw	a5,4(a0)
    80003aae:	0047d79b          	srliw	a5,a5,0x4
    80003ab2:	0001c597          	auipc	a1,0x1c
    80003ab6:	6565a583          	lw	a1,1622(a1) # 80020108 <sb+0x18>
    80003aba:	9dbd                	addw	a1,a1,a5
    80003abc:	4108                	lw	a0,0(a0)
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	8a8080e7          	jalr	-1880(ra) # 80003366 <bread>
    80003ac6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ac8:	05850793          	addi	a5,a0,88
    80003acc:	40c8                	lw	a0,4(s1)
    80003ace:	893d                	andi	a0,a0,15
    80003ad0:	051a                	slli	a0,a0,0x6
    80003ad2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003ad4:	04449703          	lh	a4,68(s1)
    80003ad8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003adc:	04649703          	lh	a4,70(s1)
    80003ae0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ae4:	04849703          	lh	a4,72(s1)
    80003ae8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003aec:	04a49703          	lh	a4,74(s1)
    80003af0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003af4:	44f8                	lw	a4,76(s1)
    80003af6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003af8:	03400613          	li	a2,52
    80003afc:	05048593          	addi	a1,s1,80
    80003b00:	0531                	addi	a0,a0,12
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	23e080e7          	jalr	574(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b0a:	854a                	mv	a0,s2
    80003b0c:	00001097          	auipc	ra,0x1
    80003b10:	c06080e7          	jalr	-1018(ra) # 80004712 <log_write>
  brelse(bp);
    80003b14:	854a                	mv	a0,s2
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	980080e7          	jalr	-1664(ra) # 80003496 <brelse>
}
    80003b1e:	60e2                	ld	ra,24(sp)
    80003b20:	6442                	ld	s0,16(sp)
    80003b22:	64a2                	ld	s1,8(sp)
    80003b24:	6902                	ld	s2,0(sp)
    80003b26:	6105                	addi	sp,sp,32
    80003b28:	8082                	ret

0000000080003b2a <idup>:
{
    80003b2a:	1101                	addi	sp,sp,-32
    80003b2c:	ec06                	sd	ra,24(sp)
    80003b2e:	e822                	sd	s0,16(sp)
    80003b30:	e426                	sd	s1,8(sp)
    80003b32:	1000                	addi	s0,sp,32
    80003b34:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b36:	0001c517          	auipc	a0,0x1c
    80003b3a:	5da50513          	addi	a0,a0,1498 # 80020110 <itable>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	0a6080e7          	jalr	166(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b46:	449c                	lw	a5,8(s1)
    80003b48:	2785                	addiw	a5,a5,1
    80003b4a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b4c:	0001c517          	auipc	a0,0x1c
    80003b50:	5c450513          	addi	a0,a0,1476 # 80020110 <itable>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	144080e7          	jalr	324(ra) # 80000c98 <release>
}
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	60e2                	ld	ra,24(sp)
    80003b60:	6442                	ld	s0,16(sp)
    80003b62:	64a2                	ld	s1,8(sp)
    80003b64:	6105                	addi	sp,sp,32
    80003b66:	8082                	ret

0000000080003b68 <ilock>:
{
    80003b68:	1101                	addi	sp,sp,-32
    80003b6a:	ec06                	sd	ra,24(sp)
    80003b6c:	e822                	sd	s0,16(sp)
    80003b6e:	e426                	sd	s1,8(sp)
    80003b70:	e04a                	sd	s2,0(sp)
    80003b72:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b74:	c115                	beqz	a0,80003b98 <ilock+0x30>
    80003b76:	84aa                	mv	s1,a0
    80003b78:	451c                	lw	a5,8(a0)
    80003b7a:	00f05f63          	blez	a5,80003b98 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b7e:	0541                	addi	a0,a0,16
    80003b80:	00001097          	auipc	ra,0x1
    80003b84:	cb2080e7          	jalr	-846(ra) # 80004832 <acquiresleep>
  if(ip->valid == 0){
    80003b88:	40bc                	lw	a5,64(s1)
    80003b8a:	cf99                	beqz	a5,80003ba8 <ilock+0x40>
}
    80003b8c:	60e2                	ld	ra,24(sp)
    80003b8e:	6442                	ld	s0,16(sp)
    80003b90:	64a2                	ld	s1,8(sp)
    80003b92:	6902                	ld	s2,0(sp)
    80003b94:	6105                	addi	sp,sp,32
    80003b96:	8082                	ret
    panic("ilock");
    80003b98:	00005517          	auipc	a0,0x5
    80003b9c:	a4050513          	addi	a0,a0,-1472 # 800085d8 <syscalls+0x190>
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	99e080e7          	jalr	-1634(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ba8:	40dc                	lw	a5,4(s1)
    80003baa:	0047d79b          	srliw	a5,a5,0x4
    80003bae:	0001c597          	auipc	a1,0x1c
    80003bb2:	55a5a583          	lw	a1,1370(a1) # 80020108 <sb+0x18>
    80003bb6:	9dbd                	addw	a1,a1,a5
    80003bb8:	4088                	lw	a0,0(s1)
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	7ac080e7          	jalr	1964(ra) # 80003366 <bread>
    80003bc2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bc4:	05850593          	addi	a1,a0,88
    80003bc8:	40dc                	lw	a5,4(s1)
    80003bca:	8bbd                	andi	a5,a5,15
    80003bcc:	079a                	slli	a5,a5,0x6
    80003bce:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bd0:	00059783          	lh	a5,0(a1)
    80003bd4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bd8:	00259783          	lh	a5,2(a1)
    80003bdc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003be0:	00459783          	lh	a5,4(a1)
    80003be4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003be8:	00659783          	lh	a5,6(a1)
    80003bec:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bf0:	459c                	lw	a5,8(a1)
    80003bf2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bf4:	03400613          	li	a2,52
    80003bf8:	05b1                	addi	a1,a1,12
    80003bfa:	05048513          	addi	a0,s1,80
    80003bfe:	ffffd097          	auipc	ra,0xffffd
    80003c02:	142080e7          	jalr	322(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c06:	854a                	mv	a0,s2
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	88e080e7          	jalr	-1906(ra) # 80003496 <brelse>
    ip->valid = 1;
    80003c10:	4785                	li	a5,1
    80003c12:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c14:	04449783          	lh	a5,68(s1)
    80003c18:	fbb5                	bnez	a5,80003b8c <ilock+0x24>
      panic("ilock: no type");
    80003c1a:	00005517          	auipc	a0,0x5
    80003c1e:	9c650513          	addi	a0,a0,-1594 # 800085e0 <syscalls+0x198>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080003c2a <iunlock>:
{
    80003c2a:	1101                	addi	sp,sp,-32
    80003c2c:	ec06                	sd	ra,24(sp)
    80003c2e:	e822                	sd	s0,16(sp)
    80003c30:	e426                	sd	s1,8(sp)
    80003c32:	e04a                	sd	s2,0(sp)
    80003c34:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c36:	c905                	beqz	a0,80003c66 <iunlock+0x3c>
    80003c38:	84aa                	mv	s1,a0
    80003c3a:	01050913          	addi	s2,a0,16
    80003c3e:	854a                	mv	a0,s2
    80003c40:	00001097          	auipc	ra,0x1
    80003c44:	c8c080e7          	jalr	-884(ra) # 800048cc <holdingsleep>
    80003c48:	cd19                	beqz	a0,80003c66 <iunlock+0x3c>
    80003c4a:	449c                	lw	a5,8(s1)
    80003c4c:	00f05d63          	blez	a5,80003c66 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c50:	854a                	mv	a0,s2
    80003c52:	00001097          	auipc	ra,0x1
    80003c56:	c36080e7          	jalr	-970(ra) # 80004888 <releasesleep>
}
    80003c5a:	60e2                	ld	ra,24(sp)
    80003c5c:	6442                	ld	s0,16(sp)
    80003c5e:	64a2                	ld	s1,8(sp)
    80003c60:	6902                	ld	s2,0(sp)
    80003c62:	6105                	addi	sp,sp,32
    80003c64:	8082                	ret
    panic("iunlock");
    80003c66:	00005517          	auipc	a0,0x5
    80003c6a:	98a50513          	addi	a0,a0,-1654 # 800085f0 <syscalls+0x1a8>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	8d0080e7          	jalr	-1840(ra) # 8000053e <panic>

0000000080003c76 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c76:	7179                	addi	sp,sp,-48
    80003c78:	f406                	sd	ra,40(sp)
    80003c7a:	f022                	sd	s0,32(sp)
    80003c7c:	ec26                	sd	s1,24(sp)
    80003c7e:	e84a                	sd	s2,16(sp)
    80003c80:	e44e                	sd	s3,8(sp)
    80003c82:	e052                	sd	s4,0(sp)
    80003c84:	1800                	addi	s0,sp,48
    80003c86:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c88:	05050493          	addi	s1,a0,80
    80003c8c:	08050913          	addi	s2,a0,128
    80003c90:	a021                	j	80003c98 <itrunc+0x22>
    80003c92:	0491                	addi	s1,s1,4
    80003c94:	01248d63          	beq	s1,s2,80003cae <itrunc+0x38>
    if(ip->addrs[i]){
    80003c98:	408c                	lw	a1,0(s1)
    80003c9a:	dde5                	beqz	a1,80003c92 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c9c:	0009a503          	lw	a0,0(s3)
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	90c080e7          	jalr	-1780(ra) # 800035ac <bfree>
      ip->addrs[i] = 0;
    80003ca8:	0004a023          	sw	zero,0(s1)
    80003cac:	b7dd                	j	80003c92 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cae:	0809a583          	lw	a1,128(s3)
    80003cb2:	e185                	bnez	a1,80003cd2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cb4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cb8:	854e                	mv	a0,s3
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	de4080e7          	jalr	-540(ra) # 80003a9e <iupdate>
}
    80003cc2:	70a2                	ld	ra,40(sp)
    80003cc4:	7402                	ld	s0,32(sp)
    80003cc6:	64e2                	ld	s1,24(sp)
    80003cc8:	6942                	ld	s2,16(sp)
    80003cca:	69a2                	ld	s3,8(sp)
    80003ccc:	6a02                	ld	s4,0(sp)
    80003cce:	6145                	addi	sp,sp,48
    80003cd0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cd2:	0009a503          	lw	a0,0(s3)
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	690080e7          	jalr	1680(ra) # 80003366 <bread>
    80003cde:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ce0:	05850493          	addi	s1,a0,88
    80003ce4:	45850913          	addi	s2,a0,1112
    80003ce8:	a811                	j	80003cfc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003cea:	0009a503          	lw	a0,0(s3)
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	8be080e7          	jalr	-1858(ra) # 800035ac <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003cf6:	0491                	addi	s1,s1,4
    80003cf8:	01248563          	beq	s1,s2,80003d02 <itrunc+0x8c>
      if(a[j])
    80003cfc:	408c                	lw	a1,0(s1)
    80003cfe:	dde5                	beqz	a1,80003cf6 <itrunc+0x80>
    80003d00:	b7ed                	j	80003cea <itrunc+0x74>
    brelse(bp);
    80003d02:	8552                	mv	a0,s4
    80003d04:	fffff097          	auipc	ra,0xfffff
    80003d08:	792080e7          	jalr	1938(ra) # 80003496 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d0c:	0809a583          	lw	a1,128(s3)
    80003d10:	0009a503          	lw	a0,0(s3)
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	898080e7          	jalr	-1896(ra) # 800035ac <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d1c:	0809a023          	sw	zero,128(s3)
    80003d20:	bf51                	j	80003cb4 <itrunc+0x3e>

0000000080003d22 <iput>:
{
    80003d22:	1101                	addi	sp,sp,-32
    80003d24:	ec06                	sd	ra,24(sp)
    80003d26:	e822                	sd	s0,16(sp)
    80003d28:	e426                	sd	s1,8(sp)
    80003d2a:	e04a                	sd	s2,0(sp)
    80003d2c:	1000                	addi	s0,sp,32
    80003d2e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d30:	0001c517          	auipc	a0,0x1c
    80003d34:	3e050513          	addi	a0,a0,992 # 80020110 <itable>
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	eac080e7          	jalr	-340(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d40:	4498                	lw	a4,8(s1)
    80003d42:	4785                	li	a5,1
    80003d44:	02f70363          	beq	a4,a5,80003d6a <iput+0x48>
  ip->ref--;
    80003d48:	449c                	lw	a5,8(s1)
    80003d4a:	37fd                	addiw	a5,a5,-1
    80003d4c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d4e:	0001c517          	auipc	a0,0x1c
    80003d52:	3c250513          	addi	a0,a0,962 # 80020110 <itable>
    80003d56:	ffffd097          	auipc	ra,0xffffd
    80003d5a:	f42080e7          	jalr	-190(ra) # 80000c98 <release>
}
    80003d5e:	60e2                	ld	ra,24(sp)
    80003d60:	6442                	ld	s0,16(sp)
    80003d62:	64a2                	ld	s1,8(sp)
    80003d64:	6902                	ld	s2,0(sp)
    80003d66:	6105                	addi	sp,sp,32
    80003d68:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d6a:	40bc                	lw	a5,64(s1)
    80003d6c:	dff1                	beqz	a5,80003d48 <iput+0x26>
    80003d6e:	04a49783          	lh	a5,74(s1)
    80003d72:	fbf9                	bnez	a5,80003d48 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d74:	01048913          	addi	s2,s1,16
    80003d78:	854a                	mv	a0,s2
    80003d7a:	00001097          	auipc	ra,0x1
    80003d7e:	ab8080e7          	jalr	-1352(ra) # 80004832 <acquiresleep>
    release(&itable.lock);
    80003d82:	0001c517          	auipc	a0,0x1c
    80003d86:	38e50513          	addi	a0,a0,910 # 80020110 <itable>
    80003d8a:	ffffd097          	auipc	ra,0xffffd
    80003d8e:	f0e080e7          	jalr	-242(ra) # 80000c98 <release>
    itrunc(ip);
    80003d92:	8526                	mv	a0,s1
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	ee2080e7          	jalr	-286(ra) # 80003c76 <itrunc>
    ip->type = 0;
    80003d9c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003da0:	8526                	mv	a0,s1
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	cfc080e7          	jalr	-772(ra) # 80003a9e <iupdate>
    ip->valid = 0;
    80003daa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dae:	854a                	mv	a0,s2
    80003db0:	00001097          	auipc	ra,0x1
    80003db4:	ad8080e7          	jalr	-1320(ra) # 80004888 <releasesleep>
    acquire(&itable.lock);
    80003db8:	0001c517          	auipc	a0,0x1c
    80003dbc:	35850513          	addi	a0,a0,856 # 80020110 <itable>
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	e24080e7          	jalr	-476(ra) # 80000be4 <acquire>
    80003dc8:	b741                	j	80003d48 <iput+0x26>

0000000080003dca <iunlockput>:
{
    80003dca:	1101                	addi	sp,sp,-32
    80003dcc:	ec06                	sd	ra,24(sp)
    80003dce:	e822                	sd	s0,16(sp)
    80003dd0:	e426                	sd	s1,8(sp)
    80003dd2:	1000                	addi	s0,sp,32
    80003dd4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	e54080e7          	jalr	-428(ra) # 80003c2a <iunlock>
  iput(ip);
    80003dde:	8526                	mv	a0,s1
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	f42080e7          	jalr	-190(ra) # 80003d22 <iput>
}
    80003de8:	60e2                	ld	ra,24(sp)
    80003dea:	6442                	ld	s0,16(sp)
    80003dec:	64a2                	ld	s1,8(sp)
    80003dee:	6105                	addi	sp,sp,32
    80003df0:	8082                	ret

0000000080003df2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003df2:	1141                	addi	sp,sp,-16
    80003df4:	e422                	sd	s0,8(sp)
    80003df6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003df8:	411c                	lw	a5,0(a0)
    80003dfa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dfc:	415c                	lw	a5,4(a0)
    80003dfe:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e00:	04451783          	lh	a5,68(a0)
    80003e04:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e08:	04a51783          	lh	a5,74(a0)
    80003e0c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e10:	04c56783          	lwu	a5,76(a0)
    80003e14:	e99c                	sd	a5,16(a1)
}
    80003e16:	6422                	ld	s0,8(sp)
    80003e18:	0141                	addi	sp,sp,16
    80003e1a:	8082                	ret

0000000080003e1c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e1c:	457c                	lw	a5,76(a0)
    80003e1e:	0ed7e963          	bltu	a5,a3,80003f10 <readi+0xf4>
{
    80003e22:	7159                	addi	sp,sp,-112
    80003e24:	f486                	sd	ra,104(sp)
    80003e26:	f0a2                	sd	s0,96(sp)
    80003e28:	eca6                	sd	s1,88(sp)
    80003e2a:	e8ca                	sd	s2,80(sp)
    80003e2c:	e4ce                	sd	s3,72(sp)
    80003e2e:	e0d2                	sd	s4,64(sp)
    80003e30:	fc56                	sd	s5,56(sp)
    80003e32:	f85a                	sd	s6,48(sp)
    80003e34:	f45e                	sd	s7,40(sp)
    80003e36:	f062                	sd	s8,32(sp)
    80003e38:	ec66                	sd	s9,24(sp)
    80003e3a:	e86a                	sd	s10,16(sp)
    80003e3c:	e46e                	sd	s11,8(sp)
    80003e3e:	1880                	addi	s0,sp,112
    80003e40:	8baa                	mv	s7,a0
    80003e42:	8c2e                	mv	s8,a1
    80003e44:	8ab2                	mv	s5,a2
    80003e46:	84b6                	mv	s1,a3
    80003e48:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e4a:	9f35                	addw	a4,a4,a3
    return 0;
    80003e4c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e4e:	0ad76063          	bltu	a4,a3,80003eee <readi+0xd2>
  if(off + n > ip->size)
    80003e52:	00e7f463          	bgeu	a5,a4,80003e5a <readi+0x3e>
    n = ip->size - off;
    80003e56:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e5a:	0a0b0963          	beqz	s6,80003f0c <readi+0xf0>
    80003e5e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e60:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e64:	5cfd                	li	s9,-1
    80003e66:	a82d                	j	80003ea0 <readi+0x84>
    80003e68:	020a1d93          	slli	s11,s4,0x20
    80003e6c:	020ddd93          	srli	s11,s11,0x20
    80003e70:	05890613          	addi	a2,s2,88
    80003e74:	86ee                	mv	a3,s11
    80003e76:	963a                	add	a2,a2,a4
    80003e78:	85d6                	mv	a1,s5
    80003e7a:	8562                	mv	a0,s8
    80003e7c:	ffffe097          	auipc	ra,0xffffe
    80003e80:	e0c080e7          	jalr	-500(ra) # 80001c88 <either_copyout>
    80003e84:	05950d63          	beq	a0,s9,80003ede <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e88:	854a                	mv	a0,s2
    80003e8a:	fffff097          	auipc	ra,0xfffff
    80003e8e:	60c080e7          	jalr	1548(ra) # 80003496 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e92:	013a09bb          	addw	s3,s4,s3
    80003e96:	009a04bb          	addw	s1,s4,s1
    80003e9a:	9aee                	add	s5,s5,s11
    80003e9c:	0569f763          	bgeu	s3,s6,80003eea <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ea0:	000ba903          	lw	s2,0(s7)
    80003ea4:	00a4d59b          	srliw	a1,s1,0xa
    80003ea8:	855e                	mv	a0,s7
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	8b0080e7          	jalr	-1872(ra) # 8000375a <bmap>
    80003eb2:	0005059b          	sext.w	a1,a0
    80003eb6:	854a                	mv	a0,s2
    80003eb8:	fffff097          	auipc	ra,0xfffff
    80003ebc:	4ae080e7          	jalr	1198(ra) # 80003366 <bread>
    80003ec0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec2:	3ff4f713          	andi	a4,s1,1023
    80003ec6:	40ed07bb          	subw	a5,s10,a4
    80003eca:	413b06bb          	subw	a3,s6,s3
    80003ece:	8a3e                	mv	s4,a5
    80003ed0:	2781                	sext.w	a5,a5
    80003ed2:	0006861b          	sext.w	a2,a3
    80003ed6:	f8f679e3          	bgeu	a2,a5,80003e68 <readi+0x4c>
    80003eda:	8a36                	mv	s4,a3
    80003edc:	b771                	j	80003e68 <readi+0x4c>
      brelse(bp);
    80003ede:	854a                	mv	a0,s2
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	5b6080e7          	jalr	1462(ra) # 80003496 <brelse>
      tot = -1;
    80003ee8:	59fd                	li	s3,-1
  }
  return tot;
    80003eea:	0009851b          	sext.w	a0,s3
}
    80003eee:	70a6                	ld	ra,104(sp)
    80003ef0:	7406                	ld	s0,96(sp)
    80003ef2:	64e6                	ld	s1,88(sp)
    80003ef4:	6946                	ld	s2,80(sp)
    80003ef6:	69a6                	ld	s3,72(sp)
    80003ef8:	6a06                	ld	s4,64(sp)
    80003efa:	7ae2                	ld	s5,56(sp)
    80003efc:	7b42                	ld	s6,48(sp)
    80003efe:	7ba2                	ld	s7,40(sp)
    80003f00:	7c02                	ld	s8,32(sp)
    80003f02:	6ce2                	ld	s9,24(sp)
    80003f04:	6d42                	ld	s10,16(sp)
    80003f06:	6da2                	ld	s11,8(sp)
    80003f08:	6165                	addi	sp,sp,112
    80003f0a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f0c:	89da                	mv	s3,s6
    80003f0e:	bff1                	j	80003eea <readi+0xce>
    return 0;
    80003f10:	4501                	li	a0,0
}
    80003f12:	8082                	ret

0000000080003f14 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f14:	457c                	lw	a5,76(a0)
    80003f16:	10d7e863          	bltu	a5,a3,80004026 <writei+0x112>
{
    80003f1a:	7159                	addi	sp,sp,-112
    80003f1c:	f486                	sd	ra,104(sp)
    80003f1e:	f0a2                	sd	s0,96(sp)
    80003f20:	eca6                	sd	s1,88(sp)
    80003f22:	e8ca                	sd	s2,80(sp)
    80003f24:	e4ce                	sd	s3,72(sp)
    80003f26:	e0d2                	sd	s4,64(sp)
    80003f28:	fc56                	sd	s5,56(sp)
    80003f2a:	f85a                	sd	s6,48(sp)
    80003f2c:	f45e                	sd	s7,40(sp)
    80003f2e:	f062                	sd	s8,32(sp)
    80003f30:	ec66                	sd	s9,24(sp)
    80003f32:	e86a                	sd	s10,16(sp)
    80003f34:	e46e                	sd	s11,8(sp)
    80003f36:	1880                	addi	s0,sp,112
    80003f38:	8b2a                	mv	s6,a0
    80003f3a:	8c2e                	mv	s8,a1
    80003f3c:	8ab2                	mv	s5,a2
    80003f3e:	8936                	mv	s2,a3
    80003f40:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f42:	00e687bb          	addw	a5,a3,a4
    80003f46:	0ed7e263          	bltu	a5,a3,8000402a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f4a:	00043737          	lui	a4,0x43
    80003f4e:	0ef76063          	bltu	a4,a5,8000402e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f52:	0c0b8863          	beqz	s7,80004022 <writei+0x10e>
    80003f56:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f58:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f5c:	5cfd                	li	s9,-1
    80003f5e:	a091                	j	80003fa2 <writei+0x8e>
    80003f60:	02099d93          	slli	s11,s3,0x20
    80003f64:	020ddd93          	srli	s11,s11,0x20
    80003f68:	05848513          	addi	a0,s1,88
    80003f6c:	86ee                	mv	a3,s11
    80003f6e:	8656                	mv	a2,s5
    80003f70:	85e2                	mv	a1,s8
    80003f72:	953a                	add	a0,a0,a4
    80003f74:	ffffe097          	auipc	ra,0xffffe
    80003f78:	d6a080e7          	jalr	-662(ra) # 80001cde <either_copyin>
    80003f7c:	07950263          	beq	a0,s9,80003fe0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f80:	8526                	mv	a0,s1
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	790080e7          	jalr	1936(ra) # 80004712 <log_write>
    brelse(bp);
    80003f8a:	8526                	mv	a0,s1
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	50a080e7          	jalr	1290(ra) # 80003496 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f94:	01498a3b          	addw	s4,s3,s4
    80003f98:	0129893b          	addw	s2,s3,s2
    80003f9c:	9aee                	add	s5,s5,s11
    80003f9e:	057a7663          	bgeu	s4,s7,80003fea <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fa2:	000b2483          	lw	s1,0(s6)
    80003fa6:	00a9559b          	srliw	a1,s2,0xa
    80003faa:	855a                	mv	a0,s6
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	7ae080e7          	jalr	1966(ra) # 8000375a <bmap>
    80003fb4:	0005059b          	sext.w	a1,a0
    80003fb8:	8526                	mv	a0,s1
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	3ac080e7          	jalr	940(ra) # 80003366 <bread>
    80003fc2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fc4:	3ff97713          	andi	a4,s2,1023
    80003fc8:	40ed07bb          	subw	a5,s10,a4
    80003fcc:	414b86bb          	subw	a3,s7,s4
    80003fd0:	89be                	mv	s3,a5
    80003fd2:	2781                	sext.w	a5,a5
    80003fd4:	0006861b          	sext.w	a2,a3
    80003fd8:	f8f674e3          	bgeu	a2,a5,80003f60 <writei+0x4c>
    80003fdc:	89b6                	mv	s3,a3
    80003fde:	b749                	j	80003f60 <writei+0x4c>
      brelse(bp);
    80003fe0:	8526                	mv	a0,s1
    80003fe2:	fffff097          	auipc	ra,0xfffff
    80003fe6:	4b4080e7          	jalr	1204(ra) # 80003496 <brelse>
  }

  if(off > ip->size)
    80003fea:	04cb2783          	lw	a5,76(s6)
    80003fee:	0127f463          	bgeu	a5,s2,80003ff6 <writei+0xe2>
    ip->size = off;
    80003ff2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ff6:	855a                	mv	a0,s6
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	aa6080e7          	jalr	-1370(ra) # 80003a9e <iupdate>

  return tot;
    80004000:	000a051b          	sext.w	a0,s4
}
    80004004:	70a6                	ld	ra,104(sp)
    80004006:	7406                	ld	s0,96(sp)
    80004008:	64e6                	ld	s1,88(sp)
    8000400a:	6946                	ld	s2,80(sp)
    8000400c:	69a6                	ld	s3,72(sp)
    8000400e:	6a06                	ld	s4,64(sp)
    80004010:	7ae2                	ld	s5,56(sp)
    80004012:	7b42                	ld	s6,48(sp)
    80004014:	7ba2                	ld	s7,40(sp)
    80004016:	7c02                	ld	s8,32(sp)
    80004018:	6ce2                	ld	s9,24(sp)
    8000401a:	6d42                	ld	s10,16(sp)
    8000401c:	6da2                	ld	s11,8(sp)
    8000401e:	6165                	addi	sp,sp,112
    80004020:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004022:	8a5e                	mv	s4,s7
    80004024:	bfc9                	j	80003ff6 <writei+0xe2>
    return -1;
    80004026:	557d                	li	a0,-1
}
    80004028:	8082                	ret
    return -1;
    8000402a:	557d                	li	a0,-1
    8000402c:	bfe1                	j	80004004 <writei+0xf0>
    return -1;
    8000402e:	557d                	li	a0,-1
    80004030:	bfd1                	j	80004004 <writei+0xf0>

0000000080004032 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004032:	1141                	addi	sp,sp,-16
    80004034:	e406                	sd	ra,8(sp)
    80004036:	e022                	sd	s0,0(sp)
    80004038:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000403a:	4639                	li	a2,14
    8000403c:	ffffd097          	auipc	ra,0xffffd
    80004040:	d7c080e7          	jalr	-644(ra) # 80000db8 <strncmp>
}
    80004044:	60a2                	ld	ra,8(sp)
    80004046:	6402                	ld	s0,0(sp)
    80004048:	0141                	addi	sp,sp,16
    8000404a:	8082                	ret

000000008000404c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000404c:	7139                	addi	sp,sp,-64
    8000404e:	fc06                	sd	ra,56(sp)
    80004050:	f822                	sd	s0,48(sp)
    80004052:	f426                	sd	s1,40(sp)
    80004054:	f04a                	sd	s2,32(sp)
    80004056:	ec4e                	sd	s3,24(sp)
    80004058:	e852                	sd	s4,16(sp)
    8000405a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000405c:	04451703          	lh	a4,68(a0)
    80004060:	4785                	li	a5,1
    80004062:	00f71a63          	bne	a4,a5,80004076 <dirlookup+0x2a>
    80004066:	892a                	mv	s2,a0
    80004068:	89ae                	mv	s3,a1
    8000406a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406c:	457c                	lw	a5,76(a0)
    8000406e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004070:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004072:	e79d                	bnez	a5,800040a0 <dirlookup+0x54>
    80004074:	a8a5                	j	800040ec <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004076:	00004517          	auipc	a0,0x4
    8000407a:	58250513          	addi	a0,a0,1410 # 800085f8 <syscalls+0x1b0>
    8000407e:	ffffc097          	auipc	ra,0xffffc
    80004082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004086:	00004517          	auipc	a0,0x4
    8000408a:	58a50513          	addi	a0,a0,1418 # 80008610 <syscalls+0x1c8>
    8000408e:	ffffc097          	auipc	ra,0xffffc
    80004092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004096:	24c1                	addiw	s1,s1,16
    80004098:	04c92783          	lw	a5,76(s2)
    8000409c:	04f4f763          	bgeu	s1,a5,800040ea <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a0:	4741                	li	a4,16
    800040a2:	86a6                	mv	a3,s1
    800040a4:	fc040613          	addi	a2,s0,-64
    800040a8:	4581                	li	a1,0
    800040aa:	854a                	mv	a0,s2
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	d70080e7          	jalr	-656(ra) # 80003e1c <readi>
    800040b4:	47c1                	li	a5,16
    800040b6:	fcf518e3          	bne	a0,a5,80004086 <dirlookup+0x3a>
    if(de.inum == 0)
    800040ba:	fc045783          	lhu	a5,-64(s0)
    800040be:	dfe1                	beqz	a5,80004096 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040c0:	fc240593          	addi	a1,s0,-62
    800040c4:	854e                	mv	a0,s3
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	f6c080e7          	jalr	-148(ra) # 80004032 <namecmp>
    800040ce:	f561                	bnez	a0,80004096 <dirlookup+0x4a>
      if(poff)
    800040d0:	000a0463          	beqz	s4,800040d8 <dirlookup+0x8c>
        *poff = off;
    800040d4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040d8:	fc045583          	lhu	a1,-64(s0)
    800040dc:	00092503          	lw	a0,0(s2)
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	754080e7          	jalr	1876(ra) # 80003834 <iget>
    800040e8:	a011                	j	800040ec <dirlookup+0xa0>
  return 0;
    800040ea:	4501                	li	a0,0
}
    800040ec:	70e2                	ld	ra,56(sp)
    800040ee:	7442                	ld	s0,48(sp)
    800040f0:	74a2                	ld	s1,40(sp)
    800040f2:	7902                	ld	s2,32(sp)
    800040f4:	69e2                	ld	s3,24(sp)
    800040f6:	6a42                	ld	s4,16(sp)
    800040f8:	6121                	addi	sp,sp,64
    800040fa:	8082                	ret

00000000800040fc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040fc:	711d                	addi	sp,sp,-96
    800040fe:	ec86                	sd	ra,88(sp)
    80004100:	e8a2                	sd	s0,80(sp)
    80004102:	e4a6                	sd	s1,72(sp)
    80004104:	e0ca                	sd	s2,64(sp)
    80004106:	fc4e                	sd	s3,56(sp)
    80004108:	f852                	sd	s4,48(sp)
    8000410a:	f456                	sd	s5,40(sp)
    8000410c:	f05a                	sd	s6,32(sp)
    8000410e:	ec5e                	sd	s7,24(sp)
    80004110:	e862                	sd	s8,16(sp)
    80004112:	e466                	sd	s9,8(sp)
    80004114:	1080                	addi	s0,sp,96
    80004116:	84aa                	mv	s1,a0
    80004118:	8b2e                	mv	s6,a1
    8000411a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000411c:	00054703          	lbu	a4,0(a0)
    80004120:	02f00793          	li	a5,47
    80004124:	02f70363          	beq	a4,a5,8000414a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004128:	ffffd097          	auipc	ra,0xffffd
    8000412c:	7e0080e7          	jalr	2016(ra) # 80001908 <myproc>
    80004130:	17053503          	ld	a0,368(a0)
    80004134:	00000097          	auipc	ra,0x0
    80004138:	9f6080e7          	jalr	-1546(ra) # 80003b2a <idup>
    8000413c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000413e:	02f00913          	li	s2,47
  len = path - s;
    80004142:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004144:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004146:	4c05                	li	s8,1
    80004148:	a865                	j	80004200 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000414a:	4585                	li	a1,1
    8000414c:	4505                	li	a0,1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	6e6080e7          	jalr	1766(ra) # 80003834 <iget>
    80004156:	89aa                	mv	s3,a0
    80004158:	b7dd                	j	8000413e <namex+0x42>
      iunlockput(ip);
    8000415a:	854e                	mv	a0,s3
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	c6e080e7          	jalr	-914(ra) # 80003dca <iunlockput>
      return 0;
    80004164:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004166:	854e                	mv	a0,s3
    80004168:	60e6                	ld	ra,88(sp)
    8000416a:	6446                	ld	s0,80(sp)
    8000416c:	64a6                	ld	s1,72(sp)
    8000416e:	6906                	ld	s2,64(sp)
    80004170:	79e2                	ld	s3,56(sp)
    80004172:	7a42                	ld	s4,48(sp)
    80004174:	7aa2                	ld	s5,40(sp)
    80004176:	7b02                	ld	s6,32(sp)
    80004178:	6be2                	ld	s7,24(sp)
    8000417a:	6c42                	ld	s8,16(sp)
    8000417c:	6ca2                	ld	s9,8(sp)
    8000417e:	6125                	addi	sp,sp,96
    80004180:	8082                	ret
      iunlock(ip);
    80004182:	854e                	mv	a0,s3
    80004184:	00000097          	auipc	ra,0x0
    80004188:	aa6080e7          	jalr	-1370(ra) # 80003c2a <iunlock>
      return ip;
    8000418c:	bfe9                	j	80004166 <namex+0x6a>
      iunlockput(ip);
    8000418e:	854e                	mv	a0,s3
    80004190:	00000097          	auipc	ra,0x0
    80004194:	c3a080e7          	jalr	-966(ra) # 80003dca <iunlockput>
      return 0;
    80004198:	89d2                	mv	s3,s4
    8000419a:	b7f1                	j	80004166 <namex+0x6a>
  len = path - s;
    8000419c:	40b48633          	sub	a2,s1,a1
    800041a0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041a4:	094cd463          	bge	s9,s4,8000422c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041a8:	4639                	li	a2,14
    800041aa:	8556                	mv	a0,s5
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	b94080e7          	jalr	-1132(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041b4:	0004c783          	lbu	a5,0(s1)
    800041b8:	01279763          	bne	a5,s2,800041c6 <namex+0xca>
    path++;
    800041bc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041be:	0004c783          	lbu	a5,0(s1)
    800041c2:	ff278de3          	beq	a5,s2,800041bc <namex+0xc0>
    ilock(ip);
    800041c6:	854e                	mv	a0,s3
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	9a0080e7          	jalr	-1632(ra) # 80003b68 <ilock>
    if(ip->type != T_DIR){
    800041d0:	04499783          	lh	a5,68(s3)
    800041d4:	f98793e3          	bne	a5,s8,8000415a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041d8:	000b0563          	beqz	s6,800041e2 <namex+0xe6>
    800041dc:	0004c783          	lbu	a5,0(s1)
    800041e0:	d3cd                	beqz	a5,80004182 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041e2:	865e                	mv	a2,s7
    800041e4:	85d6                	mv	a1,s5
    800041e6:	854e                	mv	a0,s3
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	e64080e7          	jalr	-412(ra) # 8000404c <dirlookup>
    800041f0:	8a2a                	mv	s4,a0
    800041f2:	dd51                	beqz	a0,8000418e <namex+0x92>
    iunlockput(ip);
    800041f4:	854e                	mv	a0,s3
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	bd4080e7          	jalr	-1068(ra) # 80003dca <iunlockput>
    ip = next;
    800041fe:	89d2                	mv	s3,s4
  while(*path == '/')
    80004200:	0004c783          	lbu	a5,0(s1)
    80004204:	05279763          	bne	a5,s2,80004252 <namex+0x156>
    path++;
    80004208:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000420a:	0004c783          	lbu	a5,0(s1)
    8000420e:	ff278de3          	beq	a5,s2,80004208 <namex+0x10c>
  if(*path == 0)
    80004212:	c79d                	beqz	a5,80004240 <namex+0x144>
    path++;
    80004214:	85a6                	mv	a1,s1
  len = path - s;
    80004216:	8a5e                	mv	s4,s7
    80004218:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000421a:	01278963          	beq	a5,s2,8000422c <namex+0x130>
    8000421e:	dfbd                	beqz	a5,8000419c <namex+0xa0>
    path++;
    80004220:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004222:	0004c783          	lbu	a5,0(s1)
    80004226:	ff279ce3          	bne	a5,s2,8000421e <namex+0x122>
    8000422a:	bf8d                	j	8000419c <namex+0xa0>
    memmove(name, s, len);
    8000422c:	2601                	sext.w	a2,a2
    8000422e:	8556                	mv	a0,s5
    80004230:	ffffd097          	auipc	ra,0xffffd
    80004234:	b10080e7          	jalr	-1264(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004238:	9a56                	add	s4,s4,s5
    8000423a:	000a0023          	sb	zero,0(s4)
    8000423e:	bf9d                	j	800041b4 <namex+0xb8>
  if(nameiparent){
    80004240:	f20b03e3          	beqz	s6,80004166 <namex+0x6a>
    iput(ip);
    80004244:	854e                	mv	a0,s3
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	adc080e7          	jalr	-1316(ra) # 80003d22 <iput>
    return 0;
    8000424e:	4981                	li	s3,0
    80004250:	bf19                	j	80004166 <namex+0x6a>
  if(*path == 0)
    80004252:	d7fd                	beqz	a5,80004240 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004254:	0004c783          	lbu	a5,0(s1)
    80004258:	85a6                	mv	a1,s1
    8000425a:	b7d1                	j	8000421e <namex+0x122>

000000008000425c <dirlink>:
{
    8000425c:	7139                	addi	sp,sp,-64
    8000425e:	fc06                	sd	ra,56(sp)
    80004260:	f822                	sd	s0,48(sp)
    80004262:	f426                	sd	s1,40(sp)
    80004264:	f04a                	sd	s2,32(sp)
    80004266:	ec4e                	sd	s3,24(sp)
    80004268:	e852                	sd	s4,16(sp)
    8000426a:	0080                	addi	s0,sp,64
    8000426c:	892a                	mv	s2,a0
    8000426e:	8a2e                	mv	s4,a1
    80004270:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004272:	4601                	li	a2,0
    80004274:	00000097          	auipc	ra,0x0
    80004278:	dd8080e7          	jalr	-552(ra) # 8000404c <dirlookup>
    8000427c:	e93d                	bnez	a0,800042f2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000427e:	04c92483          	lw	s1,76(s2)
    80004282:	c49d                	beqz	s1,800042b0 <dirlink+0x54>
    80004284:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004286:	4741                	li	a4,16
    80004288:	86a6                	mv	a3,s1
    8000428a:	fc040613          	addi	a2,s0,-64
    8000428e:	4581                	li	a1,0
    80004290:	854a                	mv	a0,s2
    80004292:	00000097          	auipc	ra,0x0
    80004296:	b8a080e7          	jalr	-1142(ra) # 80003e1c <readi>
    8000429a:	47c1                	li	a5,16
    8000429c:	06f51163          	bne	a0,a5,800042fe <dirlink+0xa2>
    if(de.inum == 0)
    800042a0:	fc045783          	lhu	a5,-64(s0)
    800042a4:	c791                	beqz	a5,800042b0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a6:	24c1                	addiw	s1,s1,16
    800042a8:	04c92783          	lw	a5,76(s2)
    800042ac:	fcf4ede3          	bltu	s1,a5,80004286 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042b0:	4639                	li	a2,14
    800042b2:	85d2                	mv	a1,s4
    800042b4:	fc240513          	addi	a0,s0,-62
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	b3c080e7          	jalr	-1220(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042c0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042c4:	4741                	li	a4,16
    800042c6:	86a6                	mv	a3,s1
    800042c8:	fc040613          	addi	a2,s0,-64
    800042cc:	4581                	li	a1,0
    800042ce:	854a                	mv	a0,s2
    800042d0:	00000097          	auipc	ra,0x0
    800042d4:	c44080e7          	jalr	-956(ra) # 80003f14 <writei>
    800042d8:	872a                	mv	a4,a0
    800042da:	47c1                	li	a5,16
  return 0;
    800042dc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042de:	02f71863          	bne	a4,a5,8000430e <dirlink+0xb2>
}
    800042e2:	70e2                	ld	ra,56(sp)
    800042e4:	7442                	ld	s0,48(sp)
    800042e6:	74a2                	ld	s1,40(sp)
    800042e8:	7902                	ld	s2,32(sp)
    800042ea:	69e2                	ld	s3,24(sp)
    800042ec:	6a42                	ld	s4,16(sp)
    800042ee:	6121                	addi	sp,sp,64
    800042f0:	8082                	ret
    iput(ip);
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	a30080e7          	jalr	-1488(ra) # 80003d22 <iput>
    return -1;
    800042fa:	557d                	li	a0,-1
    800042fc:	b7dd                	j	800042e2 <dirlink+0x86>
      panic("dirlink read");
    800042fe:	00004517          	auipc	a0,0x4
    80004302:	32250513          	addi	a0,a0,802 # 80008620 <syscalls+0x1d8>
    80004306:	ffffc097          	auipc	ra,0xffffc
    8000430a:	238080e7          	jalr	568(ra) # 8000053e <panic>
    panic("dirlink");
    8000430e:	00004517          	auipc	a0,0x4
    80004312:	42250513          	addi	a0,a0,1058 # 80008730 <syscalls+0x2e8>
    80004316:	ffffc097          	auipc	ra,0xffffc
    8000431a:	228080e7          	jalr	552(ra) # 8000053e <panic>

000000008000431e <namei>:

struct inode*
namei(char *path)
{
    8000431e:	1101                	addi	sp,sp,-32
    80004320:	ec06                	sd	ra,24(sp)
    80004322:	e822                	sd	s0,16(sp)
    80004324:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004326:	fe040613          	addi	a2,s0,-32
    8000432a:	4581                	li	a1,0
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	dd0080e7          	jalr	-560(ra) # 800040fc <namex>
}
    80004334:	60e2                	ld	ra,24(sp)
    80004336:	6442                	ld	s0,16(sp)
    80004338:	6105                	addi	sp,sp,32
    8000433a:	8082                	ret

000000008000433c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000433c:	1141                	addi	sp,sp,-16
    8000433e:	e406                	sd	ra,8(sp)
    80004340:	e022                	sd	s0,0(sp)
    80004342:	0800                	addi	s0,sp,16
    80004344:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004346:	4585                	li	a1,1
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	db4080e7          	jalr	-588(ra) # 800040fc <namex>
}
    80004350:	60a2                	ld	ra,8(sp)
    80004352:	6402                	ld	s0,0(sp)
    80004354:	0141                	addi	sp,sp,16
    80004356:	8082                	ret

0000000080004358 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004358:	1101                	addi	sp,sp,-32
    8000435a:	ec06                	sd	ra,24(sp)
    8000435c:	e822                	sd	s0,16(sp)
    8000435e:	e426                	sd	s1,8(sp)
    80004360:	e04a                	sd	s2,0(sp)
    80004362:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004364:	0001e917          	auipc	s2,0x1e
    80004368:	85490913          	addi	s2,s2,-1964 # 80021bb8 <log>
    8000436c:	01892583          	lw	a1,24(s2)
    80004370:	02892503          	lw	a0,40(s2)
    80004374:	fffff097          	auipc	ra,0xfffff
    80004378:	ff2080e7          	jalr	-14(ra) # 80003366 <bread>
    8000437c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000437e:	02c92683          	lw	a3,44(s2)
    80004382:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004384:	02d05763          	blez	a3,800043b2 <write_head+0x5a>
    80004388:	0001e797          	auipc	a5,0x1e
    8000438c:	86078793          	addi	a5,a5,-1952 # 80021be8 <log+0x30>
    80004390:	05c50713          	addi	a4,a0,92
    80004394:	36fd                	addiw	a3,a3,-1
    80004396:	1682                	slli	a3,a3,0x20
    80004398:	9281                	srli	a3,a3,0x20
    8000439a:	068a                	slli	a3,a3,0x2
    8000439c:	0001e617          	auipc	a2,0x1e
    800043a0:	85060613          	addi	a2,a2,-1968 # 80021bec <log+0x34>
    800043a4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043a6:	4390                	lw	a2,0(a5)
    800043a8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043aa:	0791                	addi	a5,a5,4
    800043ac:	0711                	addi	a4,a4,4
    800043ae:	fed79ce3          	bne	a5,a3,800043a6 <write_head+0x4e>
  }
  bwrite(buf);
    800043b2:	8526                	mv	a0,s1
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	0a4080e7          	jalr	164(ra) # 80003458 <bwrite>
  brelse(buf);
    800043bc:	8526                	mv	a0,s1
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	0d8080e7          	jalr	216(ra) # 80003496 <brelse>
}
    800043c6:	60e2                	ld	ra,24(sp)
    800043c8:	6442                	ld	s0,16(sp)
    800043ca:	64a2                	ld	s1,8(sp)
    800043cc:	6902                	ld	s2,0(sp)
    800043ce:	6105                	addi	sp,sp,32
    800043d0:	8082                	ret

00000000800043d2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d2:	0001e797          	auipc	a5,0x1e
    800043d6:	8127a783          	lw	a5,-2030(a5) # 80021be4 <log+0x2c>
    800043da:	0af05d63          	blez	a5,80004494 <install_trans+0xc2>
{
    800043de:	7139                	addi	sp,sp,-64
    800043e0:	fc06                	sd	ra,56(sp)
    800043e2:	f822                	sd	s0,48(sp)
    800043e4:	f426                	sd	s1,40(sp)
    800043e6:	f04a                	sd	s2,32(sp)
    800043e8:	ec4e                	sd	s3,24(sp)
    800043ea:	e852                	sd	s4,16(sp)
    800043ec:	e456                	sd	s5,8(sp)
    800043ee:	e05a                	sd	s6,0(sp)
    800043f0:	0080                	addi	s0,sp,64
    800043f2:	8b2a                	mv	s6,a0
    800043f4:	0001da97          	auipc	s5,0x1d
    800043f8:	7f4a8a93          	addi	s5,s5,2036 # 80021be8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043fe:	0001d997          	auipc	s3,0x1d
    80004402:	7ba98993          	addi	s3,s3,1978 # 80021bb8 <log>
    80004406:	a035                	j	80004432 <install_trans+0x60>
      bunpin(dbuf);
    80004408:	8526                	mv	a0,s1
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	166080e7          	jalr	358(ra) # 80003570 <bunpin>
    brelse(lbuf);
    80004412:	854a                	mv	a0,s2
    80004414:	fffff097          	auipc	ra,0xfffff
    80004418:	082080e7          	jalr	130(ra) # 80003496 <brelse>
    brelse(dbuf);
    8000441c:	8526                	mv	a0,s1
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	078080e7          	jalr	120(ra) # 80003496 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004426:	2a05                	addiw	s4,s4,1
    80004428:	0a91                	addi	s5,s5,4
    8000442a:	02c9a783          	lw	a5,44(s3)
    8000442e:	04fa5963          	bge	s4,a5,80004480 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004432:	0189a583          	lw	a1,24(s3)
    80004436:	014585bb          	addw	a1,a1,s4
    8000443a:	2585                	addiw	a1,a1,1
    8000443c:	0289a503          	lw	a0,40(s3)
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	f26080e7          	jalr	-218(ra) # 80003366 <bread>
    80004448:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000444a:	000aa583          	lw	a1,0(s5)
    8000444e:	0289a503          	lw	a0,40(s3)
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	f14080e7          	jalr	-236(ra) # 80003366 <bread>
    8000445a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000445c:	40000613          	li	a2,1024
    80004460:	05890593          	addi	a1,s2,88
    80004464:	05850513          	addi	a0,a0,88
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	8d8080e7          	jalr	-1832(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004470:	8526                	mv	a0,s1
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	fe6080e7          	jalr	-26(ra) # 80003458 <bwrite>
    if(recovering == 0)
    8000447a:	f80b1ce3          	bnez	s6,80004412 <install_trans+0x40>
    8000447e:	b769                	j	80004408 <install_trans+0x36>
}
    80004480:	70e2                	ld	ra,56(sp)
    80004482:	7442                	ld	s0,48(sp)
    80004484:	74a2                	ld	s1,40(sp)
    80004486:	7902                	ld	s2,32(sp)
    80004488:	69e2                	ld	s3,24(sp)
    8000448a:	6a42                	ld	s4,16(sp)
    8000448c:	6aa2                	ld	s5,8(sp)
    8000448e:	6b02                	ld	s6,0(sp)
    80004490:	6121                	addi	sp,sp,64
    80004492:	8082                	ret
    80004494:	8082                	ret

0000000080004496 <initlog>:
{
    80004496:	7179                	addi	sp,sp,-48
    80004498:	f406                	sd	ra,40(sp)
    8000449a:	f022                	sd	s0,32(sp)
    8000449c:	ec26                	sd	s1,24(sp)
    8000449e:	e84a                	sd	s2,16(sp)
    800044a0:	e44e                	sd	s3,8(sp)
    800044a2:	1800                	addi	s0,sp,48
    800044a4:	892a                	mv	s2,a0
    800044a6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044a8:	0001d497          	auipc	s1,0x1d
    800044ac:	71048493          	addi	s1,s1,1808 # 80021bb8 <log>
    800044b0:	00004597          	auipc	a1,0x4
    800044b4:	18058593          	addi	a1,a1,384 # 80008630 <syscalls+0x1e8>
    800044b8:	8526                	mv	a0,s1
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	69a080e7          	jalr	1690(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044c2:	0149a583          	lw	a1,20(s3)
    800044c6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044c8:	0109a783          	lw	a5,16(s3)
    800044cc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044ce:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044d2:	854a                	mv	a0,s2
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	e92080e7          	jalr	-366(ra) # 80003366 <bread>
  log.lh.n = lh->n;
    800044dc:	4d3c                	lw	a5,88(a0)
    800044de:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044e0:	02f05563          	blez	a5,8000450a <initlog+0x74>
    800044e4:	05c50713          	addi	a4,a0,92
    800044e8:	0001d697          	auipc	a3,0x1d
    800044ec:	70068693          	addi	a3,a3,1792 # 80021be8 <log+0x30>
    800044f0:	37fd                	addiw	a5,a5,-1
    800044f2:	1782                	slli	a5,a5,0x20
    800044f4:	9381                	srli	a5,a5,0x20
    800044f6:	078a                	slli	a5,a5,0x2
    800044f8:	06050613          	addi	a2,a0,96
    800044fc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800044fe:	4310                	lw	a2,0(a4)
    80004500:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004502:	0711                	addi	a4,a4,4
    80004504:	0691                	addi	a3,a3,4
    80004506:	fef71ce3          	bne	a4,a5,800044fe <initlog+0x68>
  brelse(buf);
    8000450a:	fffff097          	auipc	ra,0xfffff
    8000450e:	f8c080e7          	jalr	-116(ra) # 80003496 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004512:	4505                	li	a0,1
    80004514:	00000097          	auipc	ra,0x0
    80004518:	ebe080e7          	jalr	-322(ra) # 800043d2 <install_trans>
  log.lh.n = 0;
    8000451c:	0001d797          	auipc	a5,0x1d
    80004520:	6c07a423          	sw	zero,1736(a5) # 80021be4 <log+0x2c>
  write_head(); // clear the log
    80004524:	00000097          	auipc	ra,0x0
    80004528:	e34080e7          	jalr	-460(ra) # 80004358 <write_head>
}
    8000452c:	70a2                	ld	ra,40(sp)
    8000452e:	7402                	ld	s0,32(sp)
    80004530:	64e2                	ld	s1,24(sp)
    80004532:	6942                	ld	s2,16(sp)
    80004534:	69a2                	ld	s3,8(sp)
    80004536:	6145                	addi	sp,sp,48
    80004538:	8082                	ret

000000008000453a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000453a:	1101                	addi	sp,sp,-32
    8000453c:	ec06                	sd	ra,24(sp)
    8000453e:	e822                	sd	s0,16(sp)
    80004540:	e426                	sd	s1,8(sp)
    80004542:	e04a                	sd	s2,0(sp)
    80004544:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004546:	0001d517          	auipc	a0,0x1d
    8000454a:	67250513          	addi	a0,a0,1650 # 80021bb8 <log>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	696080e7          	jalr	1686(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004556:	0001d497          	auipc	s1,0x1d
    8000455a:	66248493          	addi	s1,s1,1634 # 80021bb8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000455e:	4979                	li	s2,30
    80004560:	a039                	j	8000456e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004562:	85a6                	mv	a1,s1
    80004564:	8526                	mv	a0,s1
    80004566:	ffffe097          	auipc	ra,0xffffe
    8000456a:	b42080e7          	jalr	-1214(ra) # 800020a8 <sleep>
    if(log.committing){
    8000456e:	50dc                	lw	a5,36(s1)
    80004570:	fbed                	bnez	a5,80004562 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004572:	509c                	lw	a5,32(s1)
    80004574:	0017871b          	addiw	a4,a5,1
    80004578:	0007069b          	sext.w	a3,a4
    8000457c:	0027179b          	slliw	a5,a4,0x2
    80004580:	9fb9                	addw	a5,a5,a4
    80004582:	0017979b          	slliw	a5,a5,0x1
    80004586:	54d8                	lw	a4,44(s1)
    80004588:	9fb9                	addw	a5,a5,a4
    8000458a:	00f95963          	bge	s2,a5,8000459c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000458e:	85a6                	mv	a1,s1
    80004590:	8526                	mv	a0,s1
    80004592:	ffffe097          	auipc	ra,0xffffe
    80004596:	b16080e7          	jalr	-1258(ra) # 800020a8 <sleep>
    8000459a:	bfd1                	j	8000456e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000459c:	0001d517          	auipc	a0,0x1d
    800045a0:	61c50513          	addi	a0,a0,1564 # 80021bb8 <log>
    800045a4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	6f2080e7          	jalr	1778(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045ae:	60e2                	ld	ra,24(sp)
    800045b0:	6442                	ld	s0,16(sp)
    800045b2:	64a2                	ld	s1,8(sp)
    800045b4:	6902                	ld	s2,0(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045ba:	7139                	addi	sp,sp,-64
    800045bc:	fc06                	sd	ra,56(sp)
    800045be:	f822                	sd	s0,48(sp)
    800045c0:	f426                	sd	s1,40(sp)
    800045c2:	f04a                	sd	s2,32(sp)
    800045c4:	ec4e                	sd	s3,24(sp)
    800045c6:	e852                	sd	s4,16(sp)
    800045c8:	e456                	sd	s5,8(sp)
    800045ca:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045cc:	0001d497          	auipc	s1,0x1d
    800045d0:	5ec48493          	addi	s1,s1,1516 # 80021bb8 <log>
    800045d4:	8526                	mv	a0,s1
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	60e080e7          	jalr	1550(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800045de:	509c                	lw	a5,32(s1)
    800045e0:	37fd                	addiw	a5,a5,-1
    800045e2:	0007891b          	sext.w	s2,a5
    800045e6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045e8:	50dc                	lw	a5,36(s1)
    800045ea:	efb9                	bnez	a5,80004648 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045ec:	06091663          	bnez	s2,80004658 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800045f0:	0001d497          	auipc	s1,0x1d
    800045f4:	5c848493          	addi	s1,s1,1480 # 80021bb8 <log>
    800045f8:	4785                	li	a5,1
    800045fa:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045fc:	8526                	mv	a0,s1
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	69a080e7          	jalr	1690(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004606:	54dc                	lw	a5,44(s1)
    80004608:	06f04763          	bgtz	a5,80004676 <end_op+0xbc>
    acquire(&log.lock);
    8000460c:	0001d497          	auipc	s1,0x1d
    80004610:	5ac48493          	addi	s1,s1,1452 # 80021bb8 <log>
    80004614:	8526                	mv	a0,s1
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	5ce080e7          	jalr	1486(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000461e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004622:	8526                	mv	a0,s1
    80004624:	ffffe097          	auipc	ra,0xffffe
    80004628:	dee080e7          	jalr	-530(ra) # 80002412 <wakeup>
    release(&log.lock);
    8000462c:	8526                	mv	a0,s1
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
}
    80004636:	70e2                	ld	ra,56(sp)
    80004638:	7442                	ld	s0,48(sp)
    8000463a:	74a2                	ld	s1,40(sp)
    8000463c:	7902                	ld	s2,32(sp)
    8000463e:	69e2                	ld	s3,24(sp)
    80004640:	6a42                	ld	s4,16(sp)
    80004642:	6aa2                	ld	s5,8(sp)
    80004644:	6121                	addi	sp,sp,64
    80004646:	8082                	ret
    panic("log.committing");
    80004648:	00004517          	auipc	a0,0x4
    8000464c:	ff050513          	addi	a0,a0,-16 # 80008638 <syscalls+0x1f0>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	eee080e7          	jalr	-274(ra) # 8000053e <panic>
    wakeup(&log);
    80004658:	0001d497          	auipc	s1,0x1d
    8000465c:	56048493          	addi	s1,s1,1376 # 80021bb8 <log>
    80004660:	8526                	mv	a0,s1
    80004662:	ffffe097          	auipc	ra,0xffffe
    80004666:	db0080e7          	jalr	-592(ra) # 80002412 <wakeup>
  release(&log.lock);
    8000466a:	8526                	mv	a0,s1
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	62c080e7          	jalr	1580(ra) # 80000c98 <release>
  if(do_commit){
    80004674:	b7c9                	j	80004636 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004676:	0001da97          	auipc	s5,0x1d
    8000467a:	572a8a93          	addi	s5,s5,1394 # 80021be8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000467e:	0001da17          	auipc	s4,0x1d
    80004682:	53aa0a13          	addi	s4,s4,1338 # 80021bb8 <log>
    80004686:	018a2583          	lw	a1,24(s4)
    8000468a:	012585bb          	addw	a1,a1,s2
    8000468e:	2585                	addiw	a1,a1,1
    80004690:	028a2503          	lw	a0,40(s4)
    80004694:	fffff097          	auipc	ra,0xfffff
    80004698:	cd2080e7          	jalr	-814(ra) # 80003366 <bread>
    8000469c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000469e:	000aa583          	lw	a1,0(s5)
    800046a2:	028a2503          	lw	a0,40(s4)
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	cc0080e7          	jalr	-832(ra) # 80003366 <bread>
    800046ae:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046b0:	40000613          	li	a2,1024
    800046b4:	05850593          	addi	a1,a0,88
    800046b8:	05848513          	addi	a0,s1,88
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	684080e7          	jalr	1668(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046c4:	8526                	mv	a0,s1
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	d92080e7          	jalr	-622(ra) # 80003458 <bwrite>
    brelse(from);
    800046ce:	854e                	mv	a0,s3
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	dc6080e7          	jalr	-570(ra) # 80003496 <brelse>
    brelse(to);
    800046d8:	8526                	mv	a0,s1
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	dbc080e7          	jalr	-580(ra) # 80003496 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046e2:	2905                	addiw	s2,s2,1
    800046e4:	0a91                	addi	s5,s5,4
    800046e6:	02ca2783          	lw	a5,44(s4)
    800046ea:	f8f94ee3          	blt	s2,a5,80004686 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046ee:	00000097          	auipc	ra,0x0
    800046f2:	c6a080e7          	jalr	-918(ra) # 80004358 <write_head>
    install_trans(0); // Now install writes to home locations
    800046f6:	4501                	li	a0,0
    800046f8:	00000097          	auipc	ra,0x0
    800046fc:	cda080e7          	jalr	-806(ra) # 800043d2 <install_trans>
    log.lh.n = 0;
    80004700:	0001d797          	auipc	a5,0x1d
    80004704:	4e07a223          	sw	zero,1252(a5) # 80021be4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004708:	00000097          	auipc	ra,0x0
    8000470c:	c50080e7          	jalr	-944(ra) # 80004358 <write_head>
    80004710:	bdf5                	j	8000460c <end_op+0x52>

0000000080004712 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004712:	1101                	addi	sp,sp,-32
    80004714:	ec06                	sd	ra,24(sp)
    80004716:	e822                	sd	s0,16(sp)
    80004718:	e426                	sd	s1,8(sp)
    8000471a:	e04a                	sd	s2,0(sp)
    8000471c:	1000                	addi	s0,sp,32
    8000471e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004720:	0001d917          	auipc	s2,0x1d
    80004724:	49890913          	addi	s2,s2,1176 # 80021bb8 <log>
    80004728:	854a                	mv	a0,s2
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	4ba080e7          	jalr	1210(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004732:	02c92603          	lw	a2,44(s2)
    80004736:	47f5                	li	a5,29
    80004738:	06c7c563          	blt	a5,a2,800047a2 <log_write+0x90>
    8000473c:	0001d797          	auipc	a5,0x1d
    80004740:	4987a783          	lw	a5,1176(a5) # 80021bd4 <log+0x1c>
    80004744:	37fd                	addiw	a5,a5,-1
    80004746:	04f65e63          	bge	a2,a5,800047a2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000474a:	0001d797          	auipc	a5,0x1d
    8000474e:	48e7a783          	lw	a5,1166(a5) # 80021bd8 <log+0x20>
    80004752:	06f05063          	blez	a5,800047b2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004756:	4781                	li	a5,0
    80004758:	06c05563          	blez	a2,800047c2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000475c:	44cc                	lw	a1,12(s1)
    8000475e:	0001d717          	auipc	a4,0x1d
    80004762:	48a70713          	addi	a4,a4,1162 # 80021be8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004766:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004768:	4314                	lw	a3,0(a4)
    8000476a:	04b68c63          	beq	a3,a1,800047c2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000476e:	2785                	addiw	a5,a5,1
    80004770:	0711                	addi	a4,a4,4
    80004772:	fef61be3          	bne	a2,a5,80004768 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004776:	0621                	addi	a2,a2,8
    80004778:	060a                	slli	a2,a2,0x2
    8000477a:	0001d797          	auipc	a5,0x1d
    8000477e:	43e78793          	addi	a5,a5,1086 # 80021bb8 <log>
    80004782:	963e                	add	a2,a2,a5
    80004784:	44dc                	lw	a5,12(s1)
    80004786:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004788:	8526                	mv	a0,s1
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	daa080e7          	jalr	-598(ra) # 80003534 <bpin>
    log.lh.n++;
    80004792:	0001d717          	auipc	a4,0x1d
    80004796:	42670713          	addi	a4,a4,1062 # 80021bb8 <log>
    8000479a:	575c                	lw	a5,44(a4)
    8000479c:	2785                	addiw	a5,a5,1
    8000479e:	d75c                	sw	a5,44(a4)
    800047a0:	a835                	j	800047dc <log_write+0xca>
    panic("too big a transaction");
    800047a2:	00004517          	auipc	a0,0x4
    800047a6:	ea650513          	addi	a0,a0,-346 # 80008648 <syscalls+0x200>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	d94080e7          	jalr	-620(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047b2:	00004517          	auipc	a0,0x4
    800047b6:	eae50513          	addi	a0,a0,-338 # 80008660 <syscalls+0x218>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	d84080e7          	jalr	-636(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047c2:	00878713          	addi	a4,a5,8
    800047c6:	00271693          	slli	a3,a4,0x2
    800047ca:	0001d717          	auipc	a4,0x1d
    800047ce:	3ee70713          	addi	a4,a4,1006 # 80021bb8 <log>
    800047d2:	9736                	add	a4,a4,a3
    800047d4:	44d4                	lw	a3,12(s1)
    800047d6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047d8:	faf608e3          	beq	a2,a5,80004788 <log_write+0x76>
  }
  release(&log.lock);
    800047dc:	0001d517          	auipc	a0,0x1d
    800047e0:	3dc50513          	addi	a0,a0,988 # 80021bb8 <log>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4b4080e7          	jalr	1204(ra) # 80000c98 <release>
}
    800047ec:	60e2                	ld	ra,24(sp)
    800047ee:	6442                	ld	s0,16(sp)
    800047f0:	64a2                	ld	s1,8(sp)
    800047f2:	6902                	ld	s2,0(sp)
    800047f4:	6105                	addi	sp,sp,32
    800047f6:	8082                	ret

00000000800047f8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047f8:	1101                	addi	sp,sp,-32
    800047fa:	ec06                	sd	ra,24(sp)
    800047fc:	e822                	sd	s0,16(sp)
    800047fe:	e426                	sd	s1,8(sp)
    80004800:	e04a                	sd	s2,0(sp)
    80004802:	1000                	addi	s0,sp,32
    80004804:	84aa                	mv	s1,a0
    80004806:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004808:	00004597          	auipc	a1,0x4
    8000480c:	e7858593          	addi	a1,a1,-392 # 80008680 <syscalls+0x238>
    80004810:	0521                	addi	a0,a0,8
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	342080e7          	jalr	834(ra) # 80000b54 <initlock>
  lk->name = name;
    8000481a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000481e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004822:	0204a423          	sw	zero,40(s1)
}
    80004826:	60e2                	ld	ra,24(sp)
    80004828:	6442                	ld	s0,16(sp)
    8000482a:	64a2                	ld	s1,8(sp)
    8000482c:	6902                	ld	s2,0(sp)
    8000482e:	6105                	addi	sp,sp,32
    80004830:	8082                	ret

0000000080004832 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004832:	1101                	addi	sp,sp,-32
    80004834:	ec06                	sd	ra,24(sp)
    80004836:	e822                	sd	s0,16(sp)
    80004838:	e426                	sd	s1,8(sp)
    8000483a:	e04a                	sd	s2,0(sp)
    8000483c:	1000                	addi	s0,sp,32
    8000483e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004840:	00850913          	addi	s2,a0,8
    80004844:	854a                	mv	a0,s2
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	39e080e7          	jalr	926(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000484e:	409c                	lw	a5,0(s1)
    80004850:	cb89                	beqz	a5,80004862 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004852:	85ca                	mv	a1,s2
    80004854:	8526                	mv	a0,s1
    80004856:	ffffe097          	auipc	ra,0xffffe
    8000485a:	852080e7          	jalr	-1966(ra) # 800020a8 <sleep>
  while (lk->locked) {
    8000485e:	409c                	lw	a5,0(s1)
    80004860:	fbed                	bnez	a5,80004852 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004862:	4785                	li	a5,1
    80004864:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004866:	ffffd097          	auipc	ra,0xffffd
    8000486a:	0a2080e7          	jalr	162(ra) # 80001908 <myproc>
    8000486e:	591c                	lw	a5,48(a0)
    80004870:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004872:	854a                	mv	a0,s2
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	424080e7          	jalr	1060(ra) # 80000c98 <release>
}
    8000487c:	60e2                	ld	ra,24(sp)
    8000487e:	6442                	ld	s0,16(sp)
    80004880:	64a2                	ld	s1,8(sp)
    80004882:	6902                	ld	s2,0(sp)
    80004884:	6105                	addi	sp,sp,32
    80004886:	8082                	ret

0000000080004888 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004888:	1101                	addi	sp,sp,-32
    8000488a:	ec06                	sd	ra,24(sp)
    8000488c:	e822                	sd	s0,16(sp)
    8000488e:	e426                	sd	s1,8(sp)
    80004890:	e04a                	sd	s2,0(sp)
    80004892:	1000                	addi	s0,sp,32
    80004894:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004896:	00850913          	addi	s2,a0,8
    8000489a:	854a                	mv	a0,s2
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	348080e7          	jalr	840(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048a4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048a8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffe097          	auipc	ra,0xffffe
    800048b2:	b64080e7          	jalr	-1180(ra) # 80002412 <wakeup>
  release(&lk->lk);
    800048b6:	854a                	mv	a0,s2
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	3e0080e7          	jalr	992(ra) # 80000c98 <release>
}
    800048c0:	60e2                	ld	ra,24(sp)
    800048c2:	6442                	ld	s0,16(sp)
    800048c4:	64a2                	ld	s1,8(sp)
    800048c6:	6902                	ld	s2,0(sp)
    800048c8:	6105                	addi	sp,sp,32
    800048ca:	8082                	ret

00000000800048cc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048cc:	7179                	addi	sp,sp,-48
    800048ce:	f406                	sd	ra,40(sp)
    800048d0:	f022                	sd	s0,32(sp)
    800048d2:	ec26                	sd	s1,24(sp)
    800048d4:	e84a                	sd	s2,16(sp)
    800048d6:	e44e                	sd	s3,8(sp)
    800048d8:	1800                	addi	s0,sp,48
    800048da:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048dc:	00850913          	addi	s2,a0,8
    800048e0:	854a                	mv	a0,s2
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	302080e7          	jalr	770(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048ea:	409c                	lw	a5,0(s1)
    800048ec:	ef99                	bnez	a5,8000490a <holdingsleep+0x3e>
    800048ee:	4481                	li	s1,0
  release(&lk->lk);
    800048f0:	854a                	mv	a0,s2
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	3a6080e7          	jalr	934(ra) # 80000c98 <release>
  return r;
}
    800048fa:	8526                	mv	a0,s1
    800048fc:	70a2                	ld	ra,40(sp)
    800048fe:	7402                	ld	s0,32(sp)
    80004900:	64e2                	ld	s1,24(sp)
    80004902:	6942                	ld	s2,16(sp)
    80004904:	69a2                	ld	s3,8(sp)
    80004906:	6145                	addi	sp,sp,48
    80004908:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000490a:	0284a983          	lw	s3,40(s1)
    8000490e:	ffffd097          	auipc	ra,0xffffd
    80004912:	ffa080e7          	jalr	-6(ra) # 80001908 <myproc>
    80004916:	5904                	lw	s1,48(a0)
    80004918:	413484b3          	sub	s1,s1,s3
    8000491c:	0014b493          	seqz	s1,s1
    80004920:	bfc1                	j	800048f0 <holdingsleep+0x24>

0000000080004922 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004922:	1141                	addi	sp,sp,-16
    80004924:	e406                	sd	ra,8(sp)
    80004926:	e022                	sd	s0,0(sp)
    80004928:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000492a:	00004597          	auipc	a1,0x4
    8000492e:	d6658593          	addi	a1,a1,-666 # 80008690 <syscalls+0x248>
    80004932:	0001d517          	auipc	a0,0x1d
    80004936:	3ce50513          	addi	a0,a0,974 # 80021d00 <ftable>
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	21a080e7          	jalr	538(ra) # 80000b54 <initlock>
}
    80004942:	60a2                	ld	ra,8(sp)
    80004944:	6402                	ld	s0,0(sp)
    80004946:	0141                	addi	sp,sp,16
    80004948:	8082                	ret

000000008000494a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000494a:	1101                	addi	sp,sp,-32
    8000494c:	ec06                	sd	ra,24(sp)
    8000494e:	e822                	sd	s0,16(sp)
    80004950:	e426                	sd	s1,8(sp)
    80004952:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004954:	0001d517          	auipc	a0,0x1d
    80004958:	3ac50513          	addi	a0,a0,940 # 80021d00 <ftable>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	288080e7          	jalr	648(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004964:	0001d497          	auipc	s1,0x1d
    80004968:	3b448493          	addi	s1,s1,948 # 80021d18 <ftable+0x18>
    8000496c:	0001e717          	auipc	a4,0x1e
    80004970:	34c70713          	addi	a4,a4,844 # 80022cb8 <ftable+0xfb8>
    if(f->ref == 0){
    80004974:	40dc                	lw	a5,4(s1)
    80004976:	cf99                	beqz	a5,80004994 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004978:	02848493          	addi	s1,s1,40
    8000497c:	fee49ce3          	bne	s1,a4,80004974 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004980:	0001d517          	auipc	a0,0x1d
    80004984:	38050513          	addi	a0,a0,896 # 80021d00 <ftable>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	310080e7          	jalr	784(ra) # 80000c98 <release>
  return 0;
    80004990:	4481                	li	s1,0
    80004992:	a819                	j	800049a8 <filealloc+0x5e>
      f->ref = 1;
    80004994:	4785                	li	a5,1
    80004996:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004998:	0001d517          	auipc	a0,0x1d
    8000499c:	36850513          	addi	a0,a0,872 # 80021d00 <ftable>
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	2f8080e7          	jalr	760(ra) # 80000c98 <release>
}
    800049a8:	8526                	mv	a0,s1
    800049aa:	60e2                	ld	ra,24(sp)
    800049ac:	6442                	ld	s0,16(sp)
    800049ae:	64a2                	ld	s1,8(sp)
    800049b0:	6105                	addi	sp,sp,32
    800049b2:	8082                	ret

00000000800049b4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049b4:	1101                	addi	sp,sp,-32
    800049b6:	ec06                	sd	ra,24(sp)
    800049b8:	e822                	sd	s0,16(sp)
    800049ba:	e426                	sd	s1,8(sp)
    800049bc:	1000                	addi	s0,sp,32
    800049be:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049c0:	0001d517          	auipc	a0,0x1d
    800049c4:	34050513          	addi	a0,a0,832 # 80021d00 <ftable>
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	21c080e7          	jalr	540(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049d0:	40dc                	lw	a5,4(s1)
    800049d2:	02f05263          	blez	a5,800049f6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049d6:	2785                	addiw	a5,a5,1
    800049d8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049da:	0001d517          	auipc	a0,0x1d
    800049de:	32650513          	addi	a0,a0,806 # 80021d00 <ftable>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	2b6080e7          	jalr	694(ra) # 80000c98 <release>
  return f;
}
    800049ea:	8526                	mv	a0,s1
    800049ec:	60e2                	ld	ra,24(sp)
    800049ee:	6442                	ld	s0,16(sp)
    800049f0:	64a2                	ld	s1,8(sp)
    800049f2:	6105                	addi	sp,sp,32
    800049f4:	8082                	ret
    panic("filedup");
    800049f6:	00004517          	auipc	a0,0x4
    800049fa:	ca250513          	addi	a0,a0,-862 # 80008698 <syscalls+0x250>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	b40080e7          	jalr	-1216(ra) # 8000053e <panic>

0000000080004a06 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a06:	7139                	addi	sp,sp,-64
    80004a08:	fc06                	sd	ra,56(sp)
    80004a0a:	f822                	sd	s0,48(sp)
    80004a0c:	f426                	sd	s1,40(sp)
    80004a0e:	f04a                	sd	s2,32(sp)
    80004a10:	ec4e                	sd	s3,24(sp)
    80004a12:	e852                	sd	s4,16(sp)
    80004a14:	e456                	sd	s5,8(sp)
    80004a16:	0080                	addi	s0,sp,64
    80004a18:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a1a:	0001d517          	auipc	a0,0x1d
    80004a1e:	2e650513          	addi	a0,a0,742 # 80021d00 <ftable>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	1c2080e7          	jalr	450(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a2a:	40dc                	lw	a5,4(s1)
    80004a2c:	06f05163          	blez	a5,80004a8e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a30:	37fd                	addiw	a5,a5,-1
    80004a32:	0007871b          	sext.w	a4,a5
    80004a36:	c0dc                	sw	a5,4(s1)
    80004a38:	06e04363          	bgtz	a4,80004a9e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a3c:	0004a903          	lw	s2,0(s1)
    80004a40:	0094ca83          	lbu	s5,9(s1)
    80004a44:	0104ba03          	ld	s4,16(s1)
    80004a48:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a4c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a50:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a54:	0001d517          	auipc	a0,0x1d
    80004a58:	2ac50513          	addi	a0,a0,684 # 80021d00 <ftable>
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	23c080e7          	jalr	572(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a64:	4785                	li	a5,1
    80004a66:	04f90d63          	beq	s2,a5,80004ac0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a6a:	3979                	addiw	s2,s2,-2
    80004a6c:	4785                	li	a5,1
    80004a6e:	0527e063          	bltu	a5,s2,80004aae <fileclose+0xa8>
    begin_op();
    80004a72:	00000097          	auipc	ra,0x0
    80004a76:	ac8080e7          	jalr	-1336(ra) # 8000453a <begin_op>
    iput(ff.ip);
    80004a7a:	854e                	mv	a0,s3
    80004a7c:	fffff097          	auipc	ra,0xfffff
    80004a80:	2a6080e7          	jalr	678(ra) # 80003d22 <iput>
    end_op();
    80004a84:	00000097          	auipc	ra,0x0
    80004a88:	b36080e7          	jalr	-1226(ra) # 800045ba <end_op>
    80004a8c:	a00d                	j	80004aae <fileclose+0xa8>
    panic("fileclose");
    80004a8e:	00004517          	auipc	a0,0x4
    80004a92:	c1250513          	addi	a0,a0,-1006 # 800086a0 <syscalls+0x258>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	aa8080e7          	jalr	-1368(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a9e:	0001d517          	auipc	a0,0x1d
    80004aa2:	26250513          	addi	a0,a0,610 # 80021d00 <ftable>
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	1f2080e7          	jalr	498(ra) # 80000c98 <release>
  }
}
    80004aae:	70e2                	ld	ra,56(sp)
    80004ab0:	7442                	ld	s0,48(sp)
    80004ab2:	74a2                	ld	s1,40(sp)
    80004ab4:	7902                	ld	s2,32(sp)
    80004ab6:	69e2                	ld	s3,24(sp)
    80004ab8:	6a42                	ld	s4,16(sp)
    80004aba:	6aa2                	ld	s5,8(sp)
    80004abc:	6121                	addi	sp,sp,64
    80004abe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ac0:	85d6                	mv	a1,s5
    80004ac2:	8552                	mv	a0,s4
    80004ac4:	00000097          	auipc	ra,0x0
    80004ac8:	34c080e7          	jalr	844(ra) # 80004e10 <pipeclose>
    80004acc:	b7cd                	j	80004aae <fileclose+0xa8>

0000000080004ace <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ace:	715d                	addi	sp,sp,-80
    80004ad0:	e486                	sd	ra,72(sp)
    80004ad2:	e0a2                	sd	s0,64(sp)
    80004ad4:	fc26                	sd	s1,56(sp)
    80004ad6:	f84a                	sd	s2,48(sp)
    80004ad8:	f44e                	sd	s3,40(sp)
    80004ada:	0880                	addi	s0,sp,80
    80004adc:	84aa                	mv	s1,a0
    80004ade:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ae0:	ffffd097          	auipc	ra,0xffffd
    80004ae4:	e28080e7          	jalr	-472(ra) # 80001908 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ae8:	409c                	lw	a5,0(s1)
    80004aea:	37f9                	addiw	a5,a5,-2
    80004aec:	4705                	li	a4,1
    80004aee:	04f76763          	bltu	a4,a5,80004b3c <filestat+0x6e>
    80004af2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004af4:	6c88                	ld	a0,24(s1)
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	072080e7          	jalr	114(ra) # 80003b68 <ilock>
    stati(f->ip, &st);
    80004afe:	fb840593          	addi	a1,s0,-72
    80004b02:	6c88                	ld	a0,24(s1)
    80004b04:	fffff097          	auipc	ra,0xfffff
    80004b08:	2ee080e7          	jalr	750(ra) # 80003df2 <stati>
    iunlock(f->ip);
    80004b0c:	6c88                	ld	a0,24(s1)
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	11c080e7          	jalr	284(ra) # 80003c2a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b16:	46e1                	li	a3,24
    80004b18:	fb840613          	addi	a2,s0,-72
    80004b1c:	85ce                	mv	a1,s3
    80004b1e:	07093503          	ld	a0,112(s2)
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	b50080e7          	jalr	-1200(ra) # 80001672 <copyout>
    80004b2a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b2e:	60a6                	ld	ra,72(sp)
    80004b30:	6406                	ld	s0,64(sp)
    80004b32:	74e2                	ld	s1,56(sp)
    80004b34:	7942                	ld	s2,48(sp)
    80004b36:	79a2                	ld	s3,40(sp)
    80004b38:	6161                	addi	sp,sp,80
    80004b3a:	8082                	ret
  return -1;
    80004b3c:	557d                	li	a0,-1
    80004b3e:	bfc5                	j	80004b2e <filestat+0x60>

0000000080004b40 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b40:	7179                	addi	sp,sp,-48
    80004b42:	f406                	sd	ra,40(sp)
    80004b44:	f022                	sd	s0,32(sp)
    80004b46:	ec26                	sd	s1,24(sp)
    80004b48:	e84a                	sd	s2,16(sp)
    80004b4a:	e44e                	sd	s3,8(sp)
    80004b4c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b4e:	00854783          	lbu	a5,8(a0)
    80004b52:	c3d5                	beqz	a5,80004bf6 <fileread+0xb6>
    80004b54:	84aa                	mv	s1,a0
    80004b56:	89ae                	mv	s3,a1
    80004b58:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b5a:	411c                	lw	a5,0(a0)
    80004b5c:	4705                	li	a4,1
    80004b5e:	04e78963          	beq	a5,a4,80004bb0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b62:	470d                	li	a4,3
    80004b64:	04e78d63          	beq	a5,a4,80004bbe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b68:	4709                	li	a4,2
    80004b6a:	06e79e63          	bne	a5,a4,80004be6 <fileread+0xa6>
    ilock(f->ip);
    80004b6e:	6d08                	ld	a0,24(a0)
    80004b70:	fffff097          	auipc	ra,0xfffff
    80004b74:	ff8080e7          	jalr	-8(ra) # 80003b68 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b78:	874a                	mv	a4,s2
    80004b7a:	5094                	lw	a3,32(s1)
    80004b7c:	864e                	mv	a2,s3
    80004b7e:	4585                	li	a1,1
    80004b80:	6c88                	ld	a0,24(s1)
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	29a080e7          	jalr	666(ra) # 80003e1c <readi>
    80004b8a:	892a                	mv	s2,a0
    80004b8c:	00a05563          	blez	a0,80004b96 <fileread+0x56>
      f->off += r;
    80004b90:	509c                	lw	a5,32(s1)
    80004b92:	9fa9                	addw	a5,a5,a0
    80004b94:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b96:	6c88                	ld	a0,24(s1)
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	092080e7          	jalr	146(ra) # 80003c2a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ba0:	854a                	mv	a0,s2
    80004ba2:	70a2                	ld	ra,40(sp)
    80004ba4:	7402                	ld	s0,32(sp)
    80004ba6:	64e2                	ld	s1,24(sp)
    80004ba8:	6942                	ld	s2,16(sp)
    80004baa:	69a2                	ld	s3,8(sp)
    80004bac:	6145                	addi	sp,sp,48
    80004bae:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bb0:	6908                	ld	a0,16(a0)
    80004bb2:	00000097          	auipc	ra,0x0
    80004bb6:	3c8080e7          	jalr	968(ra) # 80004f7a <piperead>
    80004bba:	892a                	mv	s2,a0
    80004bbc:	b7d5                	j	80004ba0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bbe:	02451783          	lh	a5,36(a0)
    80004bc2:	03079693          	slli	a3,a5,0x30
    80004bc6:	92c1                	srli	a3,a3,0x30
    80004bc8:	4725                	li	a4,9
    80004bca:	02d76863          	bltu	a4,a3,80004bfa <fileread+0xba>
    80004bce:	0792                	slli	a5,a5,0x4
    80004bd0:	0001d717          	auipc	a4,0x1d
    80004bd4:	09070713          	addi	a4,a4,144 # 80021c60 <devsw>
    80004bd8:	97ba                	add	a5,a5,a4
    80004bda:	639c                	ld	a5,0(a5)
    80004bdc:	c38d                	beqz	a5,80004bfe <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bde:	4505                	li	a0,1
    80004be0:	9782                	jalr	a5
    80004be2:	892a                	mv	s2,a0
    80004be4:	bf75                	j	80004ba0 <fileread+0x60>
    panic("fileread");
    80004be6:	00004517          	auipc	a0,0x4
    80004bea:	aca50513          	addi	a0,a0,-1334 # 800086b0 <syscalls+0x268>
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	950080e7          	jalr	-1712(ra) # 8000053e <panic>
    return -1;
    80004bf6:	597d                	li	s2,-1
    80004bf8:	b765                	j	80004ba0 <fileread+0x60>
      return -1;
    80004bfa:	597d                	li	s2,-1
    80004bfc:	b755                	j	80004ba0 <fileread+0x60>
    80004bfe:	597d                	li	s2,-1
    80004c00:	b745                	j	80004ba0 <fileread+0x60>

0000000080004c02 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c02:	715d                	addi	sp,sp,-80
    80004c04:	e486                	sd	ra,72(sp)
    80004c06:	e0a2                	sd	s0,64(sp)
    80004c08:	fc26                	sd	s1,56(sp)
    80004c0a:	f84a                	sd	s2,48(sp)
    80004c0c:	f44e                	sd	s3,40(sp)
    80004c0e:	f052                	sd	s4,32(sp)
    80004c10:	ec56                	sd	s5,24(sp)
    80004c12:	e85a                	sd	s6,16(sp)
    80004c14:	e45e                	sd	s7,8(sp)
    80004c16:	e062                	sd	s8,0(sp)
    80004c18:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c1a:	00954783          	lbu	a5,9(a0)
    80004c1e:	10078663          	beqz	a5,80004d2a <filewrite+0x128>
    80004c22:	892a                	mv	s2,a0
    80004c24:	8aae                	mv	s5,a1
    80004c26:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c28:	411c                	lw	a5,0(a0)
    80004c2a:	4705                	li	a4,1
    80004c2c:	02e78263          	beq	a5,a4,80004c50 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c30:	470d                	li	a4,3
    80004c32:	02e78663          	beq	a5,a4,80004c5e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c36:	4709                	li	a4,2
    80004c38:	0ee79163          	bne	a5,a4,80004d1a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c3c:	0ac05d63          	blez	a2,80004cf6 <filewrite+0xf4>
    int i = 0;
    80004c40:	4981                	li	s3,0
    80004c42:	6b05                	lui	s6,0x1
    80004c44:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c48:	6b85                	lui	s7,0x1
    80004c4a:	c00b8b9b          	addiw	s7,s7,-1024
    80004c4e:	a861                	j	80004ce6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c50:	6908                	ld	a0,16(a0)
    80004c52:	00000097          	auipc	ra,0x0
    80004c56:	22e080e7          	jalr	558(ra) # 80004e80 <pipewrite>
    80004c5a:	8a2a                	mv	s4,a0
    80004c5c:	a045                	j	80004cfc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c5e:	02451783          	lh	a5,36(a0)
    80004c62:	03079693          	slli	a3,a5,0x30
    80004c66:	92c1                	srli	a3,a3,0x30
    80004c68:	4725                	li	a4,9
    80004c6a:	0cd76263          	bltu	a4,a3,80004d2e <filewrite+0x12c>
    80004c6e:	0792                	slli	a5,a5,0x4
    80004c70:	0001d717          	auipc	a4,0x1d
    80004c74:	ff070713          	addi	a4,a4,-16 # 80021c60 <devsw>
    80004c78:	97ba                	add	a5,a5,a4
    80004c7a:	679c                	ld	a5,8(a5)
    80004c7c:	cbdd                	beqz	a5,80004d32 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c7e:	4505                	li	a0,1
    80004c80:	9782                	jalr	a5
    80004c82:	8a2a                	mv	s4,a0
    80004c84:	a8a5                	j	80004cfc <filewrite+0xfa>
    80004c86:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c8a:	00000097          	auipc	ra,0x0
    80004c8e:	8b0080e7          	jalr	-1872(ra) # 8000453a <begin_op>
      ilock(f->ip);
    80004c92:	01893503          	ld	a0,24(s2)
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	ed2080e7          	jalr	-302(ra) # 80003b68 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c9e:	8762                	mv	a4,s8
    80004ca0:	02092683          	lw	a3,32(s2)
    80004ca4:	01598633          	add	a2,s3,s5
    80004ca8:	4585                	li	a1,1
    80004caa:	01893503          	ld	a0,24(s2)
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	266080e7          	jalr	614(ra) # 80003f14 <writei>
    80004cb6:	84aa                	mv	s1,a0
    80004cb8:	00a05763          	blez	a0,80004cc6 <filewrite+0xc4>
        f->off += r;
    80004cbc:	02092783          	lw	a5,32(s2)
    80004cc0:	9fa9                	addw	a5,a5,a0
    80004cc2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cc6:	01893503          	ld	a0,24(s2)
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	f60080e7          	jalr	-160(ra) # 80003c2a <iunlock>
      end_op();
    80004cd2:	00000097          	auipc	ra,0x0
    80004cd6:	8e8080e7          	jalr	-1816(ra) # 800045ba <end_op>

      if(r != n1){
    80004cda:	009c1f63          	bne	s8,s1,80004cf8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cde:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ce2:	0149db63          	bge	s3,s4,80004cf8 <filewrite+0xf6>
      int n1 = n - i;
    80004ce6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004cea:	84be                	mv	s1,a5
    80004cec:	2781                	sext.w	a5,a5
    80004cee:	f8fb5ce3          	bge	s6,a5,80004c86 <filewrite+0x84>
    80004cf2:	84de                	mv	s1,s7
    80004cf4:	bf49                	j	80004c86 <filewrite+0x84>
    int i = 0;
    80004cf6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004cf8:	013a1f63          	bne	s4,s3,80004d16 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cfc:	8552                	mv	a0,s4
    80004cfe:	60a6                	ld	ra,72(sp)
    80004d00:	6406                	ld	s0,64(sp)
    80004d02:	74e2                	ld	s1,56(sp)
    80004d04:	7942                	ld	s2,48(sp)
    80004d06:	79a2                	ld	s3,40(sp)
    80004d08:	7a02                	ld	s4,32(sp)
    80004d0a:	6ae2                	ld	s5,24(sp)
    80004d0c:	6b42                	ld	s6,16(sp)
    80004d0e:	6ba2                	ld	s7,8(sp)
    80004d10:	6c02                	ld	s8,0(sp)
    80004d12:	6161                	addi	sp,sp,80
    80004d14:	8082                	ret
    ret = (i == n ? n : -1);
    80004d16:	5a7d                	li	s4,-1
    80004d18:	b7d5                	j	80004cfc <filewrite+0xfa>
    panic("filewrite");
    80004d1a:	00004517          	auipc	a0,0x4
    80004d1e:	9a650513          	addi	a0,a0,-1626 # 800086c0 <syscalls+0x278>
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	81c080e7          	jalr	-2020(ra) # 8000053e <panic>
    return -1;
    80004d2a:	5a7d                	li	s4,-1
    80004d2c:	bfc1                	j	80004cfc <filewrite+0xfa>
      return -1;
    80004d2e:	5a7d                	li	s4,-1
    80004d30:	b7f1                	j	80004cfc <filewrite+0xfa>
    80004d32:	5a7d                	li	s4,-1
    80004d34:	b7e1                	j	80004cfc <filewrite+0xfa>

0000000080004d36 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d36:	7179                	addi	sp,sp,-48
    80004d38:	f406                	sd	ra,40(sp)
    80004d3a:	f022                	sd	s0,32(sp)
    80004d3c:	ec26                	sd	s1,24(sp)
    80004d3e:	e84a                	sd	s2,16(sp)
    80004d40:	e44e                	sd	s3,8(sp)
    80004d42:	e052                	sd	s4,0(sp)
    80004d44:	1800                	addi	s0,sp,48
    80004d46:	84aa                	mv	s1,a0
    80004d48:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d4a:	0005b023          	sd	zero,0(a1)
    80004d4e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d52:	00000097          	auipc	ra,0x0
    80004d56:	bf8080e7          	jalr	-1032(ra) # 8000494a <filealloc>
    80004d5a:	e088                	sd	a0,0(s1)
    80004d5c:	c551                	beqz	a0,80004de8 <pipealloc+0xb2>
    80004d5e:	00000097          	auipc	ra,0x0
    80004d62:	bec080e7          	jalr	-1044(ra) # 8000494a <filealloc>
    80004d66:	00aa3023          	sd	a0,0(s4)
    80004d6a:	c92d                	beqz	a0,80004ddc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	d88080e7          	jalr	-632(ra) # 80000af4 <kalloc>
    80004d74:	892a                	mv	s2,a0
    80004d76:	c125                	beqz	a0,80004dd6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d78:	4985                	li	s3,1
    80004d7a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d7e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d82:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d86:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d8a:	00004597          	auipc	a1,0x4
    80004d8e:	94658593          	addi	a1,a1,-1722 # 800086d0 <syscalls+0x288>
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	dc2080e7          	jalr	-574(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004d9a:	609c                	ld	a5,0(s1)
    80004d9c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004da0:	609c                	ld	a5,0(s1)
    80004da2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004da6:	609c                	ld	a5,0(s1)
    80004da8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dac:	609c                	ld	a5,0(s1)
    80004dae:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004db2:	000a3783          	ld	a5,0(s4)
    80004db6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dba:	000a3783          	ld	a5,0(s4)
    80004dbe:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dc2:	000a3783          	ld	a5,0(s4)
    80004dc6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dca:	000a3783          	ld	a5,0(s4)
    80004dce:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dd2:	4501                	li	a0,0
    80004dd4:	a025                	j	80004dfc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dd6:	6088                	ld	a0,0(s1)
    80004dd8:	e501                	bnez	a0,80004de0 <pipealloc+0xaa>
    80004dda:	a039                	j	80004de8 <pipealloc+0xb2>
    80004ddc:	6088                	ld	a0,0(s1)
    80004dde:	c51d                	beqz	a0,80004e0c <pipealloc+0xd6>
    fileclose(*f0);
    80004de0:	00000097          	auipc	ra,0x0
    80004de4:	c26080e7          	jalr	-986(ra) # 80004a06 <fileclose>
  if(*f1)
    80004de8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dec:	557d                	li	a0,-1
  if(*f1)
    80004dee:	c799                	beqz	a5,80004dfc <pipealloc+0xc6>
    fileclose(*f1);
    80004df0:	853e                	mv	a0,a5
    80004df2:	00000097          	auipc	ra,0x0
    80004df6:	c14080e7          	jalr	-1004(ra) # 80004a06 <fileclose>
  return -1;
    80004dfa:	557d                	li	a0,-1
}
    80004dfc:	70a2                	ld	ra,40(sp)
    80004dfe:	7402                	ld	s0,32(sp)
    80004e00:	64e2                	ld	s1,24(sp)
    80004e02:	6942                	ld	s2,16(sp)
    80004e04:	69a2                	ld	s3,8(sp)
    80004e06:	6a02                	ld	s4,0(sp)
    80004e08:	6145                	addi	sp,sp,48
    80004e0a:	8082                	ret
  return -1;
    80004e0c:	557d                	li	a0,-1
    80004e0e:	b7fd                	j	80004dfc <pipealloc+0xc6>

0000000080004e10 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e10:	1101                	addi	sp,sp,-32
    80004e12:	ec06                	sd	ra,24(sp)
    80004e14:	e822                	sd	s0,16(sp)
    80004e16:	e426                	sd	s1,8(sp)
    80004e18:	e04a                	sd	s2,0(sp)
    80004e1a:	1000                	addi	s0,sp,32
    80004e1c:	84aa                	mv	s1,a0
    80004e1e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	dc4080e7          	jalr	-572(ra) # 80000be4 <acquire>
  if(writable){
    80004e28:	02090d63          	beqz	s2,80004e62 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e2c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e30:	21848513          	addi	a0,s1,536
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	5de080e7          	jalr	1502(ra) # 80002412 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e3c:	2204b783          	ld	a5,544(s1)
    80004e40:	eb95                	bnez	a5,80004e74 <pipeclose+0x64>
    release(&pi->lock);
    80004e42:	8526                	mv	a0,s1
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	e54080e7          	jalr	-428(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e4c:	8526                	mv	a0,s1
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	baa080e7          	jalr	-1110(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e56:	60e2                	ld	ra,24(sp)
    80004e58:	6442                	ld	s0,16(sp)
    80004e5a:	64a2                	ld	s1,8(sp)
    80004e5c:	6902                	ld	s2,0(sp)
    80004e5e:	6105                	addi	sp,sp,32
    80004e60:	8082                	ret
    pi->readopen = 0;
    80004e62:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e66:	21c48513          	addi	a0,s1,540
    80004e6a:	ffffd097          	auipc	ra,0xffffd
    80004e6e:	5a8080e7          	jalr	1448(ra) # 80002412 <wakeup>
    80004e72:	b7e9                	j	80004e3c <pipeclose+0x2c>
    release(&pi->lock);
    80004e74:	8526                	mv	a0,s1
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
}
    80004e7e:	bfe1                	j	80004e56 <pipeclose+0x46>

0000000080004e80 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e80:	7159                	addi	sp,sp,-112
    80004e82:	f486                	sd	ra,104(sp)
    80004e84:	f0a2                	sd	s0,96(sp)
    80004e86:	eca6                	sd	s1,88(sp)
    80004e88:	e8ca                	sd	s2,80(sp)
    80004e8a:	e4ce                	sd	s3,72(sp)
    80004e8c:	e0d2                	sd	s4,64(sp)
    80004e8e:	fc56                	sd	s5,56(sp)
    80004e90:	f85a                	sd	s6,48(sp)
    80004e92:	f45e                	sd	s7,40(sp)
    80004e94:	f062                	sd	s8,32(sp)
    80004e96:	ec66                	sd	s9,24(sp)
    80004e98:	1880                	addi	s0,sp,112
    80004e9a:	84aa                	mv	s1,a0
    80004e9c:	8aae                	mv	s5,a1
    80004e9e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ea0:	ffffd097          	auipc	ra,0xffffd
    80004ea4:	a68080e7          	jalr	-1432(ra) # 80001908 <myproc>
    80004ea8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004eaa:	8526                	mv	a0,s1
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	d38080e7          	jalr	-712(ra) # 80000be4 <acquire>
  while(i < n){
    80004eb4:	0d405163          	blez	s4,80004f76 <pipewrite+0xf6>
    80004eb8:	8ba6                	mv	s7,s1
  int i = 0;
    80004eba:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ebc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ebe:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ec2:	21c48c13          	addi	s8,s1,540
    80004ec6:	a08d                	j	80004f28 <pipewrite+0xa8>
      release(&pi->lock);
    80004ec8:	8526                	mv	a0,s1
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	dce080e7          	jalr	-562(ra) # 80000c98 <release>
      return -1;
    80004ed2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ed4:	854a                	mv	a0,s2
    80004ed6:	70a6                	ld	ra,104(sp)
    80004ed8:	7406                	ld	s0,96(sp)
    80004eda:	64e6                	ld	s1,88(sp)
    80004edc:	6946                	ld	s2,80(sp)
    80004ede:	69a6                	ld	s3,72(sp)
    80004ee0:	6a06                	ld	s4,64(sp)
    80004ee2:	7ae2                	ld	s5,56(sp)
    80004ee4:	7b42                	ld	s6,48(sp)
    80004ee6:	7ba2                	ld	s7,40(sp)
    80004ee8:	7c02                	ld	s8,32(sp)
    80004eea:	6ce2                	ld	s9,24(sp)
    80004eec:	6165                	addi	sp,sp,112
    80004eee:	8082                	ret
      wakeup(&pi->nread);
    80004ef0:	8566                	mv	a0,s9
    80004ef2:	ffffd097          	auipc	ra,0xffffd
    80004ef6:	520080e7          	jalr	1312(ra) # 80002412 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004efa:	85de                	mv	a1,s7
    80004efc:	8562                	mv	a0,s8
    80004efe:	ffffd097          	auipc	ra,0xffffd
    80004f02:	1aa080e7          	jalr	426(ra) # 800020a8 <sleep>
    80004f06:	a839                	j	80004f24 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f08:	21c4a783          	lw	a5,540(s1)
    80004f0c:	0017871b          	addiw	a4,a5,1
    80004f10:	20e4ae23          	sw	a4,540(s1)
    80004f14:	1ff7f793          	andi	a5,a5,511
    80004f18:	97a6                	add	a5,a5,s1
    80004f1a:	f9f44703          	lbu	a4,-97(s0)
    80004f1e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f22:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f24:	03495d63          	bge	s2,s4,80004f5e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f28:	2204a783          	lw	a5,544(s1)
    80004f2c:	dfd1                	beqz	a5,80004ec8 <pipewrite+0x48>
    80004f2e:	0289a783          	lw	a5,40(s3)
    80004f32:	fbd9                	bnez	a5,80004ec8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f34:	2184a783          	lw	a5,536(s1)
    80004f38:	21c4a703          	lw	a4,540(s1)
    80004f3c:	2007879b          	addiw	a5,a5,512
    80004f40:	faf708e3          	beq	a4,a5,80004ef0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f44:	4685                	li	a3,1
    80004f46:	01590633          	add	a2,s2,s5
    80004f4a:	f9f40593          	addi	a1,s0,-97
    80004f4e:	0709b503          	ld	a0,112(s3)
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	7ac080e7          	jalr	1964(ra) # 800016fe <copyin>
    80004f5a:	fb6517e3          	bne	a0,s6,80004f08 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f5e:	21848513          	addi	a0,s1,536
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	4b0080e7          	jalr	1200(ra) # 80002412 <wakeup>
  release(&pi->lock);
    80004f6a:	8526                	mv	a0,s1
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	d2c080e7          	jalr	-724(ra) # 80000c98 <release>
  return i;
    80004f74:	b785                	j	80004ed4 <pipewrite+0x54>
  int i = 0;
    80004f76:	4901                	li	s2,0
    80004f78:	b7dd                	j	80004f5e <pipewrite+0xde>

0000000080004f7a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f7a:	715d                	addi	sp,sp,-80
    80004f7c:	e486                	sd	ra,72(sp)
    80004f7e:	e0a2                	sd	s0,64(sp)
    80004f80:	fc26                	sd	s1,56(sp)
    80004f82:	f84a                	sd	s2,48(sp)
    80004f84:	f44e                	sd	s3,40(sp)
    80004f86:	f052                	sd	s4,32(sp)
    80004f88:	ec56                	sd	s5,24(sp)
    80004f8a:	e85a                	sd	s6,16(sp)
    80004f8c:	0880                	addi	s0,sp,80
    80004f8e:	84aa                	mv	s1,a0
    80004f90:	892e                	mv	s2,a1
    80004f92:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	974080e7          	jalr	-1676(ra) # 80001908 <myproc>
    80004f9c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f9e:	8b26                	mv	s6,s1
    80004fa0:	8526                	mv	a0,s1
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	c42080e7          	jalr	-958(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004faa:	2184a703          	lw	a4,536(s1)
    80004fae:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fb2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fb6:	02f71463          	bne	a4,a5,80004fde <piperead+0x64>
    80004fba:	2244a783          	lw	a5,548(s1)
    80004fbe:	c385                	beqz	a5,80004fde <piperead+0x64>
    if(pr->killed){
    80004fc0:	028a2783          	lw	a5,40(s4)
    80004fc4:	ebc1                	bnez	a5,80005054 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fc6:	85da                	mv	a1,s6
    80004fc8:	854e                	mv	a0,s3
    80004fca:	ffffd097          	auipc	ra,0xffffd
    80004fce:	0de080e7          	jalr	222(ra) # 800020a8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fd2:	2184a703          	lw	a4,536(s1)
    80004fd6:	21c4a783          	lw	a5,540(s1)
    80004fda:	fef700e3          	beq	a4,a5,80004fba <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fde:	09505263          	blez	s5,80005062 <piperead+0xe8>
    80004fe2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fe4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004fe6:	2184a783          	lw	a5,536(s1)
    80004fea:	21c4a703          	lw	a4,540(s1)
    80004fee:	02f70d63          	beq	a4,a5,80005028 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ff2:	0017871b          	addiw	a4,a5,1
    80004ff6:	20e4ac23          	sw	a4,536(s1)
    80004ffa:	1ff7f793          	andi	a5,a5,511
    80004ffe:	97a6                	add	a5,a5,s1
    80005000:	0187c783          	lbu	a5,24(a5)
    80005004:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005008:	4685                	li	a3,1
    8000500a:	fbf40613          	addi	a2,s0,-65
    8000500e:	85ca                	mv	a1,s2
    80005010:	070a3503          	ld	a0,112(s4)
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	65e080e7          	jalr	1630(ra) # 80001672 <copyout>
    8000501c:	01650663          	beq	a0,s6,80005028 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005020:	2985                	addiw	s3,s3,1
    80005022:	0905                	addi	s2,s2,1
    80005024:	fd3a91e3          	bne	s5,s3,80004fe6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005028:	21c48513          	addi	a0,s1,540
    8000502c:	ffffd097          	auipc	ra,0xffffd
    80005030:	3e6080e7          	jalr	998(ra) # 80002412 <wakeup>
  release(&pi->lock);
    80005034:	8526                	mv	a0,s1
    80005036:	ffffc097          	auipc	ra,0xffffc
    8000503a:	c62080e7          	jalr	-926(ra) # 80000c98 <release>
  return i;
}
    8000503e:	854e                	mv	a0,s3
    80005040:	60a6                	ld	ra,72(sp)
    80005042:	6406                	ld	s0,64(sp)
    80005044:	74e2                	ld	s1,56(sp)
    80005046:	7942                	ld	s2,48(sp)
    80005048:	79a2                	ld	s3,40(sp)
    8000504a:	7a02                	ld	s4,32(sp)
    8000504c:	6ae2                	ld	s5,24(sp)
    8000504e:	6b42                	ld	s6,16(sp)
    80005050:	6161                	addi	sp,sp,80
    80005052:	8082                	ret
      release(&pi->lock);
    80005054:	8526                	mv	a0,s1
    80005056:	ffffc097          	auipc	ra,0xffffc
    8000505a:	c42080e7          	jalr	-958(ra) # 80000c98 <release>
      return -1;
    8000505e:	59fd                	li	s3,-1
    80005060:	bff9                	j	8000503e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005062:	4981                	li	s3,0
    80005064:	b7d1                	j	80005028 <piperead+0xae>

0000000080005066 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005066:	df010113          	addi	sp,sp,-528
    8000506a:	20113423          	sd	ra,520(sp)
    8000506e:	20813023          	sd	s0,512(sp)
    80005072:	ffa6                	sd	s1,504(sp)
    80005074:	fbca                	sd	s2,496(sp)
    80005076:	f7ce                	sd	s3,488(sp)
    80005078:	f3d2                	sd	s4,480(sp)
    8000507a:	efd6                	sd	s5,472(sp)
    8000507c:	ebda                	sd	s6,464(sp)
    8000507e:	e7de                	sd	s7,456(sp)
    80005080:	e3e2                	sd	s8,448(sp)
    80005082:	ff66                	sd	s9,440(sp)
    80005084:	fb6a                	sd	s10,432(sp)
    80005086:	f76e                	sd	s11,424(sp)
    80005088:	0c00                	addi	s0,sp,528
    8000508a:	84aa                	mv	s1,a0
    8000508c:	dea43c23          	sd	a0,-520(s0)
    80005090:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005094:	ffffd097          	auipc	ra,0xffffd
    80005098:	874080e7          	jalr	-1932(ra) # 80001908 <myproc>
    8000509c:	892a                	mv	s2,a0

  begin_op();
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	49c080e7          	jalr	1180(ra) # 8000453a <begin_op>

  if((ip = namei(path)) == 0){
    800050a6:	8526                	mv	a0,s1
    800050a8:	fffff097          	auipc	ra,0xfffff
    800050ac:	276080e7          	jalr	630(ra) # 8000431e <namei>
    800050b0:	c92d                	beqz	a0,80005122 <exec+0xbc>
    800050b2:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050b4:	fffff097          	auipc	ra,0xfffff
    800050b8:	ab4080e7          	jalr	-1356(ra) # 80003b68 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050bc:	04000713          	li	a4,64
    800050c0:	4681                	li	a3,0
    800050c2:	e5040613          	addi	a2,s0,-432
    800050c6:	4581                	li	a1,0
    800050c8:	8526                	mv	a0,s1
    800050ca:	fffff097          	auipc	ra,0xfffff
    800050ce:	d52080e7          	jalr	-686(ra) # 80003e1c <readi>
    800050d2:	04000793          	li	a5,64
    800050d6:	00f51a63          	bne	a0,a5,800050ea <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050da:	e5042703          	lw	a4,-432(s0)
    800050de:	464c47b7          	lui	a5,0x464c4
    800050e2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050e6:	04f70463          	beq	a4,a5,8000512e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050ea:	8526                	mv	a0,s1
    800050ec:	fffff097          	auipc	ra,0xfffff
    800050f0:	cde080e7          	jalr	-802(ra) # 80003dca <iunlockput>
    end_op();
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	4c6080e7          	jalr	1222(ra) # 800045ba <end_op>
  }
  return -1;
    800050fc:	557d                	li	a0,-1
}
    800050fe:	20813083          	ld	ra,520(sp)
    80005102:	20013403          	ld	s0,512(sp)
    80005106:	74fe                	ld	s1,504(sp)
    80005108:	795e                	ld	s2,496(sp)
    8000510a:	79be                	ld	s3,488(sp)
    8000510c:	7a1e                	ld	s4,480(sp)
    8000510e:	6afe                	ld	s5,472(sp)
    80005110:	6b5e                	ld	s6,464(sp)
    80005112:	6bbe                	ld	s7,456(sp)
    80005114:	6c1e                	ld	s8,448(sp)
    80005116:	7cfa                	ld	s9,440(sp)
    80005118:	7d5a                	ld	s10,432(sp)
    8000511a:	7dba                	ld	s11,424(sp)
    8000511c:	21010113          	addi	sp,sp,528
    80005120:	8082                	ret
    end_op();
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	498080e7          	jalr	1176(ra) # 800045ba <end_op>
    return -1;
    8000512a:	557d                	li	a0,-1
    8000512c:	bfc9                	j	800050fe <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000512e:	854a                	mv	a0,s2
    80005130:	ffffd097          	auipc	ra,0xffffd
    80005134:	896080e7          	jalr	-1898(ra) # 800019c6 <proc_pagetable>
    80005138:	8baa                	mv	s7,a0
    8000513a:	d945                	beqz	a0,800050ea <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000513c:	e7042983          	lw	s3,-400(s0)
    80005140:	e8845783          	lhu	a5,-376(s0)
    80005144:	c7ad                	beqz	a5,800051ae <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005146:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005148:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000514a:	6c85                	lui	s9,0x1
    8000514c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005150:	def43823          	sd	a5,-528(s0)
    80005154:	a42d                	j	8000537e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005156:	00003517          	auipc	a0,0x3
    8000515a:	58250513          	addi	a0,a0,1410 # 800086d8 <syscalls+0x290>
    8000515e:	ffffb097          	auipc	ra,0xffffb
    80005162:	3e0080e7          	jalr	992(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005166:	8756                	mv	a4,s5
    80005168:	012d86bb          	addw	a3,s11,s2
    8000516c:	4581                	li	a1,0
    8000516e:	8526                	mv	a0,s1
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	cac080e7          	jalr	-852(ra) # 80003e1c <readi>
    80005178:	2501                	sext.w	a0,a0
    8000517a:	1aaa9963          	bne	s5,a0,8000532c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000517e:	6785                	lui	a5,0x1
    80005180:	0127893b          	addw	s2,a5,s2
    80005184:	77fd                	lui	a5,0xfffff
    80005186:	01478a3b          	addw	s4,a5,s4
    8000518a:	1f897163          	bgeu	s2,s8,8000536c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000518e:	02091593          	slli	a1,s2,0x20
    80005192:	9181                	srli	a1,a1,0x20
    80005194:	95ea                	add	a1,a1,s10
    80005196:	855e                	mv	a0,s7
    80005198:	ffffc097          	auipc	ra,0xffffc
    8000519c:	ed6080e7          	jalr	-298(ra) # 8000106e <walkaddr>
    800051a0:	862a                	mv	a2,a0
    if(pa == 0)
    800051a2:	d955                	beqz	a0,80005156 <exec+0xf0>
      n = PGSIZE;
    800051a4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051a6:	fd9a70e3          	bgeu	s4,s9,80005166 <exec+0x100>
      n = sz - i;
    800051aa:	8ad2                	mv	s5,s4
    800051ac:	bf6d                	j	80005166 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051ae:	4901                	li	s2,0
  iunlockput(ip);
    800051b0:	8526                	mv	a0,s1
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	c18080e7          	jalr	-1000(ra) # 80003dca <iunlockput>
  end_op();
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	400080e7          	jalr	1024(ra) # 800045ba <end_op>
  p = myproc();
    800051c2:	ffffc097          	auipc	ra,0xffffc
    800051c6:	746080e7          	jalr	1862(ra) # 80001908 <myproc>
    800051ca:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051cc:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800051d0:	6785                	lui	a5,0x1
    800051d2:	17fd                	addi	a5,a5,-1
    800051d4:	993e                	add	s2,s2,a5
    800051d6:	757d                	lui	a0,0xfffff
    800051d8:	00a977b3          	and	a5,s2,a0
    800051dc:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051e0:	6609                	lui	a2,0x2
    800051e2:	963e                	add	a2,a2,a5
    800051e4:	85be                	mv	a1,a5
    800051e6:	855e                	mv	a0,s7
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	23a080e7          	jalr	570(ra) # 80001422 <uvmalloc>
    800051f0:	8b2a                	mv	s6,a0
  ip = 0;
    800051f2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051f4:	12050c63          	beqz	a0,8000532c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051f8:	75f9                	lui	a1,0xffffe
    800051fa:	95aa                	add	a1,a1,a0
    800051fc:	855e                	mv	a0,s7
    800051fe:	ffffc097          	auipc	ra,0xffffc
    80005202:	442080e7          	jalr	1090(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005206:	7c7d                	lui	s8,0xfffff
    80005208:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000520a:	e0043783          	ld	a5,-512(s0)
    8000520e:	6388                	ld	a0,0(a5)
    80005210:	c535                	beqz	a0,8000527c <exec+0x216>
    80005212:	e9040993          	addi	s3,s0,-368
    80005216:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000521a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	c48080e7          	jalr	-952(ra) # 80000e64 <strlen>
    80005224:	2505                	addiw	a0,a0,1
    80005226:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000522a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000522e:	13896363          	bltu	s2,s8,80005354 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005232:	e0043d83          	ld	s11,-512(s0)
    80005236:	000dba03          	ld	s4,0(s11)
    8000523a:	8552                	mv	a0,s4
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	c28080e7          	jalr	-984(ra) # 80000e64 <strlen>
    80005244:	0015069b          	addiw	a3,a0,1
    80005248:	8652                	mv	a2,s4
    8000524a:	85ca                	mv	a1,s2
    8000524c:	855e                	mv	a0,s7
    8000524e:	ffffc097          	auipc	ra,0xffffc
    80005252:	424080e7          	jalr	1060(ra) # 80001672 <copyout>
    80005256:	10054363          	bltz	a0,8000535c <exec+0x2f6>
    ustack[argc] = sp;
    8000525a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000525e:	0485                	addi	s1,s1,1
    80005260:	008d8793          	addi	a5,s11,8
    80005264:	e0f43023          	sd	a5,-512(s0)
    80005268:	008db503          	ld	a0,8(s11)
    8000526c:	c911                	beqz	a0,80005280 <exec+0x21a>
    if(argc >= MAXARG)
    8000526e:	09a1                	addi	s3,s3,8
    80005270:	fb3c96e3          	bne	s9,s3,8000521c <exec+0x1b6>
  sz = sz1;
    80005274:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005278:	4481                	li	s1,0
    8000527a:	a84d                	j	8000532c <exec+0x2c6>
  sp = sz;
    8000527c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000527e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005280:	00349793          	slli	a5,s1,0x3
    80005284:	f9040713          	addi	a4,s0,-112
    80005288:	97ba                	add	a5,a5,a4
    8000528a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000528e:	00148693          	addi	a3,s1,1
    80005292:	068e                	slli	a3,a3,0x3
    80005294:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005298:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000529c:	01897663          	bgeu	s2,s8,800052a8 <exec+0x242>
  sz = sz1;
    800052a0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052a4:	4481                	li	s1,0
    800052a6:	a059                	j	8000532c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052a8:	e9040613          	addi	a2,s0,-368
    800052ac:	85ca                	mv	a1,s2
    800052ae:	855e                	mv	a0,s7
    800052b0:	ffffc097          	auipc	ra,0xffffc
    800052b4:	3c2080e7          	jalr	962(ra) # 80001672 <copyout>
    800052b8:	0a054663          	bltz	a0,80005364 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052bc:	078ab783          	ld	a5,120(s5)
    800052c0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052c4:	df843783          	ld	a5,-520(s0)
    800052c8:	0007c703          	lbu	a4,0(a5)
    800052cc:	cf11                	beqz	a4,800052e8 <exec+0x282>
    800052ce:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052d0:	02f00693          	li	a3,47
    800052d4:	a039                	j	800052e2 <exec+0x27c>
      last = s+1;
    800052d6:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052da:	0785                	addi	a5,a5,1
    800052dc:	fff7c703          	lbu	a4,-1(a5)
    800052e0:	c701                	beqz	a4,800052e8 <exec+0x282>
    if(*s == '/')
    800052e2:	fed71ce3          	bne	a4,a3,800052da <exec+0x274>
    800052e6:	bfc5                	j	800052d6 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800052e8:	4641                	li	a2,16
    800052ea:	df843583          	ld	a1,-520(s0)
    800052ee:	178a8513          	addi	a0,s5,376
    800052f2:	ffffc097          	auipc	ra,0xffffc
    800052f6:	b40080e7          	jalr	-1216(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800052fa:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800052fe:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005302:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005306:	078ab783          	ld	a5,120(s5)
    8000530a:	e6843703          	ld	a4,-408(s0)
    8000530e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005310:	078ab783          	ld	a5,120(s5)
    80005314:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005318:	85ea                	mv	a1,s10
    8000531a:	ffffc097          	auipc	ra,0xffffc
    8000531e:	748080e7          	jalr	1864(ra) # 80001a62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005322:	0004851b          	sext.w	a0,s1
    80005326:	bbe1                	j	800050fe <exec+0x98>
    80005328:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000532c:	e0843583          	ld	a1,-504(s0)
    80005330:	855e                	mv	a0,s7
    80005332:	ffffc097          	auipc	ra,0xffffc
    80005336:	730080e7          	jalr	1840(ra) # 80001a62 <proc_freepagetable>
  if(ip){
    8000533a:	da0498e3          	bnez	s1,800050ea <exec+0x84>
  return -1;
    8000533e:	557d                	li	a0,-1
    80005340:	bb7d                	j	800050fe <exec+0x98>
    80005342:	e1243423          	sd	s2,-504(s0)
    80005346:	b7dd                	j	8000532c <exec+0x2c6>
    80005348:	e1243423          	sd	s2,-504(s0)
    8000534c:	b7c5                	j	8000532c <exec+0x2c6>
    8000534e:	e1243423          	sd	s2,-504(s0)
    80005352:	bfe9                	j	8000532c <exec+0x2c6>
  sz = sz1;
    80005354:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005358:	4481                	li	s1,0
    8000535a:	bfc9                	j	8000532c <exec+0x2c6>
  sz = sz1;
    8000535c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005360:	4481                	li	s1,0
    80005362:	b7e9                	j	8000532c <exec+0x2c6>
  sz = sz1;
    80005364:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005368:	4481                	li	s1,0
    8000536a:	b7c9                	j	8000532c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000536c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005370:	2b05                	addiw	s6,s6,1
    80005372:	0389899b          	addiw	s3,s3,56
    80005376:	e8845783          	lhu	a5,-376(s0)
    8000537a:	e2fb5be3          	bge	s6,a5,800051b0 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000537e:	2981                	sext.w	s3,s3
    80005380:	03800713          	li	a4,56
    80005384:	86ce                	mv	a3,s3
    80005386:	e1840613          	addi	a2,s0,-488
    8000538a:	4581                	li	a1,0
    8000538c:	8526                	mv	a0,s1
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	a8e080e7          	jalr	-1394(ra) # 80003e1c <readi>
    80005396:	03800793          	li	a5,56
    8000539a:	f8f517e3          	bne	a0,a5,80005328 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000539e:	e1842783          	lw	a5,-488(s0)
    800053a2:	4705                	li	a4,1
    800053a4:	fce796e3          	bne	a5,a4,80005370 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053a8:	e4043603          	ld	a2,-448(s0)
    800053ac:	e3843783          	ld	a5,-456(s0)
    800053b0:	f8f669e3          	bltu	a2,a5,80005342 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053b4:	e2843783          	ld	a5,-472(s0)
    800053b8:	963e                	add	a2,a2,a5
    800053ba:	f8f667e3          	bltu	a2,a5,80005348 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053be:	85ca                	mv	a1,s2
    800053c0:	855e                	mv	a0,s7
    800053c2:	ffffc097          	auipc	ra,0xffffc
    800053c6:	060080e7          	jalr	96(ra) # 80001422 <uvmalloc>
    800053ca:	e0a43423          	sd	a0,-504(s0)
    800053ce:	d141                	beqz	a0,8000534e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053d0:	e2843d03          	ld	s10,-472(s0)
    800053d4:	df043783          	ld	a5,-528(s0)
    800053d8:	00fd77b3          	and	a5,s10,a5
    800053dc:	fba1                	bnez	a5,8000532c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053de:	e2042d83          	lw	s11,-480(s0)
    800053e2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053e6:	f80c03e3          	beqz	s8,8000536c <exec+0x306>
    800053ea:	8a62                	mv	s4,s8
    800053ec:	4901                	li	s2,0
    800053ee:	b345                	j	8000518e <exec+0x128>

00000000800053f0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053f0:	7179                	addi	sp,sp,-48
    800053f2:	f406                	sd	ra,40(sp)
    800053f4:	f022                	sd	s0,32(sp)
    800053f6:	ec26                	sd	s1,24(sp)
    800053f8:	e84a                	sd	s2,16(sp)
    800053fa:	1800                	addi	s0,sp,48
    800053fc:	892e                	mv	s2,a1
    800053fe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005400:	fdc40593          	addi	a1,s0,-36
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	ba8080e7          	jalr	-1112(ra) # 80002fac <argint>
    8000540c:	04054063          	bltz	a0,8000544c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005410:	fdc42703          	lw	a4,-36(s0)
    80005414:	47bd                	li	a5,15
    80005416:	02e7ed63          	bltu	a5,a4,80005450 <argfd+0x60>
    8000541a:	ffffc097          	auipc	ra,0xffffc
    8000541e:	4ee080e7          	jalr	1262(ra) # 80001908 <myproc>
    80005422:	fdc42703          	lw	a4,-36(s0)
    80005426:	01e70793          	addi	a5,a4,30
    8000542a:	078e                	slli	a5,a5,0x3
    8000542c:	953e                	add	a0,a0,a5
    8000542e:	611c                	ld	a5,0(a0)
    80005430:	c395                	beqz	a5,80005454 <argfd+0x64>
    return -1;
  if(pfd)
    80005432:	00090463          	beqz	s2,8000543a <argfd+0x4a>
    *pfd = fd;
    80005436:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000543a:	4501                	li	a0,0
  if(pf)
    8000543c:	c091                	beqz	s1,80005440 <argfd+0x50>
    *pf = f;
    8000543e:	e09c                	sd	a5,0(s1)
}
    80005440:	70a2                	ld	ra,40(sp)
    80005442:	7402                	ld	s0,32(sp)
    80005444:	64e2                	ld	s1,24(sp)
    80005446:	6942                	ld	s2,16(sp)
    80005448:	6145                	addi	sp,sp,48
    8000544a:	8082                	ret
    return -1;
    8000544c:	557d                	li	a0,-1
    8000544e:	bfcd                	j	80005440 <argfd+0x50>
    return -1;
    80005450:	557d                	li	a0,-1
    80005452:	b7fd                	j	80005440 <argfd+0x50>
    80005454:	557d                	li	a0,-1
    80005456:	b7ed                	j	80005440 <argfd+0x50>

0000000080005458 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005458:	1101                	addi	sp,sp,-32
    8000545a:	ec06                	sd	ra,24(sp)
    8000545c:	e822                	sd	s0,16(sp)
    8000545e:	e426                	sd	s1,8(sp)
    80005460:	1000                	addi	s0,sp,32
    80005462:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	4a4080e7          	jalr	1188(ra) # 80001908 <myproc>
    8000546c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000546e:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005472:	4501                	li	a0,0
    80005474:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005476:	6398                	ld	a4,0(a5)
    80005478:	cb19                	beqz	a4,8000548e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000547a:	2505                	addiw	a0,a0,1
    8000547c:	07a1                	addi	a5,a5,8
    8000547e:	fed51ce3          	bne	a0,a3,80005476 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005482:	557d                	li	a0,-1
}
    80005484:	60e2                	ld	ra,24(sp)
    80005486:	6442                	ld	s0,16(sp)
    80005488:	64a2                	ld	s1,8(sp)
    8000548a:	6105                	addi	sp,sp,32
    8000548c:	8082                	ret
      p->ofile[fd] = f;
    8000548e:	01e50793          	addi	a5,a0,30
    80005492:	078e                	slli	a5,a5,0x3
    80005494:	963e                	add	a2,a2,a5
    80005496:	e204                	sd	s1,0(a2)
      return fd;
    80005498:	b7f5                	j	80005484 <fdalloc+0x2c>

000000008000549a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000549a:	715d                	addi	sp,sp,-80
    8000549c:	e486                	sd	ra,72(sp)
    8000549e:	e0a2                	sd	s0,64(sp)
    800054a0:	fc26                	sd	s1,56(sp)
    800054a2:	f84a                	sd	s2,48(sp)
    800054a4:	f44e                	sd	s3,40(sp)
    800054a6:	f052                	sd	s4,32(sp)
    800054a8:	ec56                	sd	s5,24(sp)
    800054aa:	0880                	addi	s0,sp,80
    800054ac:	89ae                	mv	s3,a1
    800054ae:	8ab2                	mv	s5,a2
    800054b0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054b2:	fb040593          	addi	a1,s0,-80
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	e86080e7          	jalr	-378(ra) # 8000433c <nameiparent>
    800054be:	892a                	mv	s2,a0
    800054c0:	12050f63          	beqz	a0,800055fe <create+0x164>
    return 0;

  ilock(dp);
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	6a4080e7          	jalr	1700(ra) # 80003b68 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054cc:	4601                	li	a2,0
    800054ce:	fb040593          	addi	a1,s0,-80
    800054d2:	854a                	mv	a0,s2
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	b78080e7          	jalr	-1160(ra) # 8000404c <dirlookup>
    800054dc:	84aa                	mv	s1,a0
    800054de:	c921                	beqz	a0,8000552e <create+0x94>
    iunlockput(dp);
    800054e0:	854a                	mv	a0,s2
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	8e8080e7          	jalr	-1816(ra) # 80003dca <iunlockput>
    ilock(ip);
    800054ea:	8526                	mv	a0,s1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	67c080e7          	jalr	1660(ra) # 80003b68 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054f4:	2981                	sext.w	s3,s3
    800054f6:	4789                	li	a5,2
    800054f8:	02f99463          	bne	s3,a5,80005520 <create+0x86>
    800054fc:	0444d783          	lhu	a5,68(s1)
    80005500:	37f9                	addiw	a5,a5,-2
    80005502:	17c2                	slli	a5,a5,0x30
    80005504:	93c1                	srli	a5,a5,0x30
    80005506:	4705                	li	a4,1
    80005508:	00f76c63          	bltu	a4,a5,80005520 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000550c:	8526                	mv	a0,s1
    8000550e:	60a6                	ld	ra,72(sp)
    80005510:	6406                	ld	s0,64(sp)
    80005512:	74e2                	ld	s1,56(sp)
    80005514:	7942                	ld	s2,48(sp)
    80005516:	79a2                	ld	s3,40(sp)
    80005518:	7a02                	ld	s4,32(sp)
    8000551a:	6ae2                	ld	s5,24(sp)
    8000551c:	6161                	addi	sp,sp,80
    8000551e:	8082                	ret
    iunlockput(ip);
    80005520:	8526                	mv	a0,s1
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	8a8080e7          	jalr	-1880(ra) # 80003dca <iunlockput>
    return 0;
    8000552a:	4481                	li	s1,0
    8000552c:	b7c5                	j	8000550c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000552e:	85ce                	mv	a1,s3
    80005530:	00092503          	lw	a0,0(s2)
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	49c080e7          	jalr	1180(ra) # 800039d0 <ialloc>
    8000553c:	84aa                	mv	s1,a0
    8000553e:	c529                	beqz	a0,80005588 <create+0xee>
  ilock(ip);
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	628080e7          	jalr	1576(ra) # 80003b68 <ilock>
  ip->major = major;
    80005548:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000554c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005550:	4785                	li	a5,1
    80005552:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005556:	8526                	mv	a0,s1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	546080e7          	jalr	1350(ra) # 80003a9e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005560:	2981                	sext.w	s3,s3
    80005562:	4785                	li	a5,1
    80005564:	02f98a63          	beq	s3,a5,80005598 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005568:	40d0                	lw	a2,4(s1)
    8000556a:	fb040593          	addi	a1,s0,-80
    8000556e:	854a                	mv	a0,s2
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	cec080e7          	jalr	-788(ra) # 8000425c <dirlink>
    80005578:	06054b63          	bltz	a0,800055ee <create+0x154>
  iunlockput(dp);
    8000557c:	854a                	mv	a0,s2
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	84c080e7          	jalr	-1972(ra) # 80003dca <iunlockput>
  return ip;
    80005586:	b759                	j	8000550c <create+0x72>
    panic("create: ialloc");
    80005588:	00003517          	auipc	a0,0x3
    8000558c:	17050513          	addi	a0,a0,368 # 800086f8 <syscalls+0x2b0>
    80005590:	ffffb097          	auipc	ra,0xffffb
    80005594:	fae080e7          	jalr	-82(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005598:	04a95783          	lhu	a5,74(s2)
    8000559c:	2785                	addiw	a5,a5,1
    8000559e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055a2:	854a                	mv	a0,s2
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	4fa080e7          	jalr	1274(ra) # 80003a9e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055ac:	40d0                	lw	a2,4(s1)
    800055ae:	00003597          	auipc	a1,0x3
    800055b2:	15a58593          	addi	a1,a1,346 # 80008708 <syscalls+0x2c0>
    800055b6:	8526                	mv	a0,s1
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	ca4080e7          	jalr	-860(ra) # 8000425c <dirlink>
    800055c0:	00054f63          	bltz	a0,800055de <create+0x144>
    800055c4:	00492603          	lw	a2,4(s2)
    800055c8:	00003597          	auipc	a1,0x3
    800055cc:	14858593          	addi	a1,a1,328 # 80008710 <syscalls+0x2c8>
    800055d0:	8526                	mv	a0,s1
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	c8a080e7          	jalr	-886(ra) # 8000425c <dirlink>
    800055da:	f80557e3          	bgez	a0,80005568 <create+0xce>
      panic("create dots");
    800055de:	00003517          	auipc	a0,0x3
    800055e2:	13a50513          	addi	a0,a0,314 # 80008718 <syscalls+0x2d0>
    800055e6:	ffffb097          	auipc	ra,0xffffb
    800055ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
    panic("create: dirlink");
    800055ee:	00003517          	auipc	a0,0x3
    800055f2:	13a50513          	addi	a0,a0,314 # 80008728 <syscalls+0x2e0>
    800055f6:	ffffb097          	auipc	ra,0xffffb
    800055fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
    return 0;
    800055fe:	84aa                	mv	s1,a0
    80005600:	b731                	j	8000550c <create+0x72>

0000000080005602 <sys_dup>:
{
    80005602:	7179                	addi	sp,sp,-48
    80005604:	f406                	sd	ra,40(sp)
    80005606:	f022                	sd	s0,32(sp)
    80005608:	ec26                	sd	s1,24(sp)
    8000560a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000560c:	fd840613          	addi	a2,s0,-40
    80005610:	4581                	li	a1,0
    80005612:	4501                	li	a0,0
    80005614:	00000097          	auipc	ra,0x0
    80005618:	ddc080e7          	jalr	-548(ra) # 800053f0 <argfd>
    return -1;
    8000561c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000561e:	02054363          	bltz	a0,80005644 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005622:	fd843503          	ld	a0,-40(s0)
    80005626:	00000097          	auipc	ra,0x0
    8000562a:	e32080e7          	jalr	-462(ra) # 80005458 <fdalloc>
    8000562e:	84aa                	mv	s1,a0
    return -1;
    80005630:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005632:	00054963          	bltz	a0,80005644 <sys_dup+0x42>
  filedup(f);
    80005636:	fd843503          	ld	a0,-40(s0)
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	37a080e7          	jalr	890(ra) # 800049b4 <filedup>
  return fd;
    80005642:	87a6                	mv	a5,s1
}
    80005644:	853e                	mv	a0,a5
    80005646:	70a2                	ld	ra,40(sp)
    80005648:	7402                	ld	s0,32(sp)
    8000564a:	64e2                	ld	s1,24(sp)
    8000564c:	6145                	addi	sp,sp,48
    8000564e:	8082                	ret

0000000080005650 <sys_read>:
{
    80005650:	7179                	addi	sp,sp,-48
    80005652:	f406                	sd	ra,40(sp)
    80005654:	f022                	sd	s0,32(sp)
    80005656:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005658:	fe840613          	addi	a2,s0,-24
    8000565c:	4581                	li	a1,0
    8000565e:	4501                	li	a0,0
    80005660:	00000097          	auipc	ra,0x0
    80005664:	d90080e7          	jalr	-624(ra) # 800053f0 <argfd>
    return -1;
    80005668:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000566a:	04054163          	bltz	a0,800056ac <sys_read+0x5c>
    8000566e:	fe440593          	addi	a1,s0,-28
    80005672:	4509                	li	a0,2
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	938080e7          	jalr	-1736(ra) # 80002fac <argint>
    return -1;
    8000567c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567e:	02054763          	bltz	a0,800056ac <sys_read+0x5c>
    80005682:	fd840593          	addi	a1,s0,-40
    80005686:	4505                	li	a0,1
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	946080e7          	jalr	-1722(ra) # 80002fce <argaddr>
    return -1;
    80005690:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005692:	00054d63          	bltz	a0,800056ac <sys_read+0x5c>
  return fileread(f, p, n);
    80005696:	fe442603          	lw	a2,-28(s0)
    8000569a:	fd843583          	ld	a1,-40(s0)
    8000569e:	fe843503          	ld	a0,-24(s0)
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	49e080e7          	jalr	1182(ra) # 80004b40 <fileread>
    800056aa:	87aa                	mv	a5,a0
}
    800056ac:	853e                	mv	a0,a5
    800056ae:	70a2                	ld	ra,40(sp)
    800056b0:	7402                	ld	s0,32(sp)
    800056b2:	6145                	addi	sp,sp,48
    800056b4:	8082                	ret

00000000800056b6 <sys_write>:
{
    800056b6:	7179                	addi	sp,sp,-48
    800056b8:	f406                	sd	ra,40(sp)
    800056ba:	f022                	sd	s0,32(sp)
    800056bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056be:	fe840613          	addi	a2,s0,-24
    800056c2:	4581                	li	a1,0
    800056c4:	4501                	li	a0,0
    800056c6:	00000097          	auipc	ra,0x0
    800056ca:	d2a080e7          	jalr	-726(ra) # 800053f0 <argfd>
    return -1;
    800056ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d0:	04054163          	bltz	a0,80005712 <sys_write+0x5c>
    800056d4:	fe440593          	addi	a1,s0,-28
    800056d8:	4509                	li	a0,2
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	8d2080e7          	jalr	-1838(ra) # 80002fac <argint>
    return -1;
    800056e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e4:	02054763          	bltz	a0,80005712 <sys_write+0x5c>
    800056e8:	fd840593          	addi	a1,s0,-40
    800056ec:	4505                	li	a0,1
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	8e0080e7          	jalr	-1824(ra) # 80002fce <argaddr>
    return -1;
    800056f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f8:	00054d63          	bltz	a0,80005712 <sys_write+0x5c>
  return filewrite(f, p, n);
    800056fc:	fe442603          	lw	a2,-28(s0)
    80005700:	fd843583          	ld	a1,-40(s0)
    80005704:	fe843503          	ld	a0,-24(s0)
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	4fa080e7          	jalr	1274(ra) # 80004c02 <filewrite>
    80005710:	87aa                	mv	a5,a0
}
    80005712:	853e                	mv	a0,a5
    80005714:	70a2                	ld	ra,40(sp)
    80005716:	7402                	ld	s0,32(sp)
    80005718:	6145                	addi	sp,sp,48
    8000571a:	8082                	ret

000000008000571c <sys_close>:
{
    8000571c:	1101                	addi	sp,sp,-32
    8000571e:	ec06                	sd	ra,24(sp)
    80005720:	e822                	sd	s0,16(sp)
    80005722:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005724:	fe040613          	addi	a2,s0,-32
    80005728:	fec40593          	addi	a1,s0,-20
    8000572c:	4501                	li	a0,0
    8000572e:	00000097          	auipc	ra,0x0
    80005732:	cc2080e7          	jalr	-830(ra) # 800053f0 <argfd>
    return -1;
    80005736:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005738:	02054463          	bltz	a0,80005760 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000573c:	ffffc097          	auipc	ra,0xffffc
    80005740:	1cc080e7          	jalr	460(ra) # 80001908 <myproc>
    80005744:	fec42783          	lw	a5,-20(s0)
    80005748:	07f9                	addi	a5,a5,30
    8000574a:	078e                	slli	a5,a5,0x3
    8000574c:	97aa                	add	a5,a5,a0
    8000574e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005752:	fe043503          	ld	a0,-32(s0)
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	2b0080e7          	jalr	688(ra) # 80004a06 <fileclose>
  return 0;
    8000575e:	4781                	li	a5,0
}
    80005760:	853e                	mv	a0,a5
    80005762:	60e2                	ld	ra,24(sp)
    80005764:	6442                	ld	s0,16(sp)
    80005766:	6105                	addi	sp,sp,32
    80005768:	8082                	ret

000000008000576a <sys_fstat>:
{
    8000576a:	1101                	addi	sp,sp,-32
    8000576c:	ec06                	sd	ra,24(sp)
    8000576e:	e822                	sd	s0,16(sp)
    80005770:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005772:	fe840613          	addi	a2,s0,-24
    80005776:	4581                	li	a1,0
    80005778:	4501                	li	a0,0
    8000577a:	00000097          	auipc	ra,0x0
    8000577e:	c76080e7          	jalr	-906(ra) # 800053f0 <argfd>
    return -1;
    80005782:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005784:	02054563          	bltz	a0,800057ae <sys_fstat+0x44>
    80005788:	fe040593          	addi	a1,s0,-32
    8000578c:	4505                	li	a0,1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	840080e7          	jalr	-1984(ra) # 80002fce <argaddr>
    return -1;
    80005796:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005798:	00054b63          	bltz	a0,800057ae <sys_fstat+0x44>
  return filestat(f, st);
    8000579c:	fe043583          	ld	a1,-32(s0)
    800057a0:	fe843503          	ld	a0,-24(s0)
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	32a080e7          	jalr	810(ra) # 80004ace <filestat>
    800057ac:	87aa                	mv	a5,a0
}
    800057ae:	853e                	mv	a0,a5
    800057b0:	60e2                	ld	ra,24(sp)
    800057b2:	6442                	ld	s0,16(sp)
    800057b4:	6105                	addi	sp,sp,32
    800057b6:	8082                	ret

00000000800057b8 <sys_link>:
{
    800057b8:	7169                	addi	sp,sp,-304
    800057ba:	f606                	sd	ra,296(sp)
    800057bc:	f222                	sd	s0,288(sp)
    800057be:	ee26                	sd	s1,280(sp)
    800057c0:	ea4a                	sd	s2,272(sp)
    800057c2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057c4:	08000613          	li	a2,128
    800057c8:	ed040593          	addi	a1,s0,-304
    800057cc:	4501                	li	a0,0
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	822080e7          	jalr	-2014(ra) # 80002ff0 <argstr>
    return -1;
    800057d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d8:	10054e63          	bltz	a0,800058f4 <sys_link+0x13c>
    800057dc:	08000613          	li	a2,128
    800057e0:	f5040593          	addi	a1,s0,-176
    800057e4:	4505                	li	a0,1
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	80a080e7          	jalr	-2038(ra) # 80002ff0 <argstr>
    return -1;
    800057ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f0:	10054263          	bltz	a0,800058f4 <sys_link+0x13c>
  begin_op();
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	d46080e7          	jalr	-698(ra) # 8000453a <begin_op>
  if((ip = namei(old)) == 0){
    800057fc:	ed040513          	addi	a0,s0,-304
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	b1e080e7          	jalr	-1250(ra) # 8000431e <namei>
    80005808:	84aa                	mv	s1,a0
    8000580a:	c551                	beqz	a0,80005896 <sys_link+0xde>
  ilock(ip);
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	35c080e7          	jalr	860(ra) # 80003b68 <ilock>
  if(ip->type == T_DIR){
    80005814:	04449703          	lh	a4,68(s1)
    80005818:	4785                	li	a5,1
    8000581a:	08f70463          	beq	a4,a5,800058a2 <sys_link+0xea>
  ip->nlink++;
    8000581e:	04a4d783          	lhu	a5,74(s1)
    80005822:	2785                	addiw	a5,a5,1
    80005824:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	274080e7          	jalr	628(ra) # 80003a9e <iupdate>
  iunlock(ip);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	3f6080e7          	jalr	1014(ra) # 80003c2a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000583c:	fd040593          	addi	a1,s0,-48
    80005840:	f5040513          	addi	a0,s0,-176
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	af8080e7          	jalr	-1288(ra) # 8000433c <nameiparent>
    8000584c:	892a                	mv	s2,a0
    8000584e:	c935                	beqz	a0,800058c2 <sys_link+0x10a>
  ilock(dp);
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	318080e7          	jalr	792(ra) # 80003b68 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005858:	00092703          	lw	a4,0(s2)
    8000585c:	409c                	lw	a5,0(s1)
    8000585e:	04f71d63          	bne	a4,a5,800058b8 <sys_link+0x100>
    80005862:	40d0                	lw	a2,4(s1)
    80005864:	fd040593          	addi	a1,s0,-48
    80005868:	854a                	mv	a0,s2
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	9f2080e7          	jalr	-1550(ra) # 8000425c <dirlink>
    80005872:	04054363          	bltz	a0,800058b8 <sys_link+0x100>
  iunlockput(dp);
    80005876:	854a                	mv	a0,s2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	552080e7          	jalr	1362(ra) # 80003dca <iunlockput>
  iput(ip);
    80005880:	8526                	mv	a0,s1
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	4a0080e7          	jalr	1184(ra) # 80003d22 <iput>
  end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	d30080e7          	jalr	-720(ra) # 800045ba <end_op>
  return 0;
    80005892:	4781                	li	a5,0
    80005894:	a085                	j	800058f4 <sys_link+0x13c>
    end_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	d24080e7          	jalr	-732(ra) # 800045ba <end_op>
    return -1;
    8000589e:	57fd                	li	a5,-1
    800058a0:	a891                	j	800058f4 <sys_link+0x13c>
    iunlockput(ip);
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	526080e7          	jalr	1318(ra) # 80003dca <iunlockput>
    end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	d0e080e7          	jalr	-754(ra) # 800045ba <end_op>
    return -1;
    800058b4:	57fd                	li	a5,-1
    800058b6:	a83d                	j	800058f4 <sys_link+0x13c>
    iunlockput(dp);
    800058b8:	854a                	mv	a0,s2
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	510080e7          	jalr	1296(ra) # 80003dca <iunlockput>
  ilock(ip);
    800058c2:	8526                	mv	a0,s1
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	2a4080e7          	jalr	676(ra) # 80003b68 <ilock>
  ip->nlink--;
    800058cc:	04a4d783          	lhu	a5,74(s1)
    800058d0:	37fd                	addiw	a5,a5,-1
    800058d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	1c6080e7          	jalr	454(ra) # 80003a9e <iupdate>
  iunlockput(ip);
    800058e0:	8526                	mv	a0,s1
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	4e8080e7          	jalr	1256(ra) # 80003dca <iunlockput>
  end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	cd0080e7          	jalr	-816(ra) # 800045ba <end_op>
  return -1;
    800058f2:	57fd                	li	a5,-1
}
    800058f4:	853e                	mv	a0,a5
    800058f6:	70b2                	ld	ra,296(sp)
    800058f8:	7412                	ld	s0,288(sp)
    800058fa:	64f2                	ld	s1,280(sp)
    800058fc:	6952                	ld	s2,272(sp)
    800058fe:	6155                	addi	sp,sp,304
    80005900:	8082                	ret

0000000080005902 <sys_unlink>:
{
    80005902:	7151                	addi	sp,sp,-240
    80005904:	f586                	sd	ra,232(sp)
    80005906:	f1a2                	sd	s0,224(sp)
    80005908:	eda6                	sd	s1,216(sp)
    8000590a:	e9ca                	sd	s2,208(sp)
    8000590c:	e5ce                	sd	s3,200(sp)
    8000590e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005910:	08000613          	li	a2,128
    80005914:	f3040593          	addi	a1,s0,-208
    80005918:	4501                	li	a0,0
    8000591a:	ffffd097          	auipc	ra,0xffffd
    8000591e:	6d6080e7          	jalr	1750(ra) # 80002ff0 <argstr>
    80005922:	18054163          	bltz	a0,80005aa4 <sys_unlink+0x1a2>
  begin_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	c14080e7          	jalr	-1004(ra) # 8000453a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000592e:	fb040593          	addi	a1,s0,-80
    80005932:	f3040513          	addi	a0,s0,-208
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	a06080e7          	jalr	-1530(ra) # 8000433c <nameiparent>
    8000593e:	84aa                	mv	s1,a0
    80005940:	c979                	beqz	a0,80005a16 <sys_unlink+0x114>
  ilock(dp);
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	226080e7          	jalr	550(ra) # 80003b68 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000594a:	00003597          	auipc	a1,0x3
    8000594e:	dbe58593          	addi	a1,a1,-578 # 80008708 <syscalls+0x2c0>
    80005952:	fb040513          	addi	a0,s0,-80
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	6dc080e7          	jalr	1756(ra) # 80004032 <namecmp>
    8000595e:	14050a63          	beqz	a0,80005ab2 <sys_unlink+0x1b0>
    80005962:	00003597          	auipc	a1,0x3
    80005966:	dae58593          	addi	a1,a1,-594 # 80008710 <syscalls+0x2c8>
    8000596a:	fb040513          	addi	a0,s0,-80
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	6c4080e7          	jalr	1732(ra) # 80004032 <namecmp>
    80005976:	12050e63          	beqz	a0,80005ab2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000597a:	f2c40613          	addi	a2,s0,-212
    8000597e:	fb040593          	addi	a1,s0,-80
    80005982:	8526                	mv	a0,s1
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	6c8080e7          	jalr	1736(ra) # 8000404c <dirlookup>
    8000598c:	892a                	mv	s2,a0
    8000598e:	12050263          	beqz	a0,80005ab2 <sys_unlink+0x1b0>
  ilock(ip);
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	1d6080e7          	jalr	470(ra) # 80003b68 <ilock>
  if(ip->nlink < 1)
    8000599a:	04a91783          	lh	a5,74(s2)
    8000599e:	08f05263          	blez	a5,80005a22 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059a2:	04491703          	lh	a4,68(s2)
    800059a6:	4785                	li	a5,1
    800059a8:	08f70563          	beq	a4,a5,80005a32 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059ac:	4641                	li	a2,16
    800059ae:	4581                	li	a1,0
    800059b0:	fc040513          	addi	a0,s0,-64
    800059b4:	ffffb097          	auipc	ra,0xffffb
    800059b8:	32c080e7          	jalr	812(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059bc:	4741                	li	a4,16
    800059be:	f2c42683          	lw	a3,-212(s0)
    800059c2:	fc040613          	addi	a2,s0,-64
    800059c6:	4581                	li	a1,0
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	54a080e7          	jalr	1354(ra) # 80003f14 <writei>
    800059d2:	47c1                	li	a5,16
    800059d4:	0af51563          	bne	a0,a5,80005a7e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059d8:	04491703          	lh	a4,68(s2)
    800059dc:	4785                	li	a5,1
    800059de:	0af70863          	beq	a4,a5,80005a8e <sys_unlink+0x18c>
  iunlockput(dp);
    800059e2:	8526                	mv	a0,s1
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	3e6080e7          	jalr	998(ra) # 80003dca <iunlockput>
  ip->nlink--;
    800059ec:	04a95783          	lhu	a5,74(s2)
    800059f0:	37fd                	addiw	a5,a5,-1
    800059f2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059f6:	854a                	mv	a0,s2
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	0a6080e7          	jalr	166(ra) # 80003a9e <iupdate>
  iunlockput(ip);
    80005a00:	854a                	mv	a0,s2
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	3c8080e7          	jalr	968(ra) # 80003dca <iunlockput>
  end_op();
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	bb0080e7          	jalr	-1104(ra) # 800045ba <end_op>
  return 0;
    80005a12:	4501                	li	a0,0
    80005a14:	a84d                	j	80005ac6 <sys_unlink+0x1c4>
    end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	ba4080e7          	jalr	-1116(ra) # 800045ba <end_op>
    return -1;
    80005a1e:	557d                	li	a0,-1
    80005a20:	a05d                	j	80005ac6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a22:	00003517          	auipc	a0,0x3
    80005a26:	d1650513          	addi	a0,a0,-746 # 80008738 <syscalls+0x2f0>
    80005a2a:	ffffb097          	auipc	ra,0xffffb
    80005a2e:	b14080e7          	jalr	-1260(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a32:	04c92703          	lw	a4,76(s2)
    80005a36:	02000793          	li	a5,32
    80005a3a:	f6e7f9e3          	bgeu	a5,a4,800059ac <sys_unlink+0xaa>
    80005a3e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a42:	4741                	li	a4,16
    80005a44:	86ce                	mv	a3,s3
    80005a46:	f1840613          	addi	a2,s0,-232
    80005a4a:	4581                	li	a1,0
    80005a4c:	854a                	mv	a0,s2
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	3ce080e7          	jalr	974(ra) # 80003e1c <readi>
    80005a56:	47c1                	li	a5,16
    80005a58:	00f51b63          	bne	a0,a5,80005a6e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a5c:	f1845783          	lhu	a5,-232(s0)
    80005a60:	e7a1                	bnez	a5,80005aa8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a62:	29c1                	addiw	s3,s3,16
    80005a64:	04c92783          	lw	a5,76(s2)
    80005a68:	fcf9ede3          	bltu	s3,a5,80005a42 <sys_unlink+0x140>
    80005a6c:	b781                	j	800059ac <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a6e:	00003517          	auipc	a0,0x3
    80005a72:	ce250513          	addi	a0,a0,-798 # 80008750 <syscalls+0x308>
    80005a76:	ffffb097          	auipc	ra,0xffffb
    80005a7a:	ac8080e7          	jalr	-1336(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a7e:	00003517          	auipc	a0,0x3
    80005a82:	cea50513          	addi	a0,a0,-790 # 80008768 <syscalls+0x320>
    80005a86:	ffffb097          	auipc	ra,0xffffb
    80005a8a:	ab8080e7          	jalr	-1352(ra) # 8000053e <panic>
    dp->nlink--;
    80005a8e:	04a4d783          	lhu	a5,74(s1)
    80005a92:	37fd                	addiw	a5,a5,-1
    80005a94:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a98:	8526                	mv	a0,s1
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	004080e7          	jalr	4(ra) # 80003a9e <iupdate>
    80005aa2:	b781                	j	800059e2 <sys_unlink+0xe0>
    return -1;
    80005aa4:	557d                	li	a0,-1
    80005aa6:	a005                	j	80005ac6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005aa8:	854a                	mv	a0,s2
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	320080e7          	jalr	800(ra) # 80003dca <iunlockput>
  iunlockput(dp);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	316080e7          	jalr	790(ra) # 80003dca <iunlockput>
  end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	afe080e7          	jalr	-1282(ra) # 800045ba <end_op>
  return -1;
    80005ac4:	557d                	li	a0,-1
}
    80005ac6:	70ae                	ld	ra,232(sp)
    80005ac8:	740e                	ld	s0,224(sp)
    80005aca:	64ee                	ld	s1,216(sp)
    80005acc:	694e                	ld	s2,208(sp)
    80005ace:	69ae                	ld	s3,200(sp)
    80005ad0:	616d                	addi	sp,sp,240
    80005ad2:	8082                	ret

0000000080005ad4 <sys_open>:

uint64
sys_open(void)
{
    80005ad4:	7131                	addi	sp,sp,-192
    80005ad6:	fd06                	sd	ra,184(sp)
    80005ad8:	f922                	sd	s0,176(sp)
    80005ada:	f526                	sd	s1,168(sp)
    80005adc:	f14a                	sd	s2,160(sp)
    80005ade:	ed4e                	sd	s3,152(sp)
    80005ae0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ae2:	08000613          	li	a2,128
    80005ae6:	f5040593          	addi	a1,s0,-176
    80005aea:	4501                	li	a0,0
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	504080e7          	jalr	1284(ra) # 80002ff0 <argstr>
    return -1;
    80005af4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005af6:	0c054163          	bltz	a0,80005bb8 <sys_open+0xe4>
    80005afa:	f4c40593          	addi	a1,s0,-180
    80005afe:	4505                	li	a0,1
    80005b00:	ffffd097          	auipc	ra,0xffffd
    80005b04:	4ac080e7          	jalr	1196(ra) # 80002fac <argint>
    80005b08:	0a054863          	bltz	a0,80005bb8 <sys_open+0xe4>

  begin_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	a2e080e7          	jalr	-1490(ra) # 8000453a <begin_op>

  if(omode & O_CREATE){
    80005b14:	f4c42783          	lw	a5,-180(s0)
    80005b18:	2007f793          	andi	a5,a5,512
    80005b1c:	cbdd                	beqz	a5,80005bd2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b1e:	4681                	li	a3,0
    80005b20:	4601                	li	a2,0
    80005b22:	4589                	li	a1,2
    80005b24:	f5040513          	addi	a0,s0,-176
    80005b28:	00000097          	auipc	ra,0x0
    80005b2c:	972080e7          	jalr	-1678(ra) # 8000549a <create>
    80005b30:	892a                	mv	s2,a0
    if(ip == 0){
    80005b32:	c959                	beqz	a0,80005bc8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b34:	04491703          	lh	a4,68(s2)
    80005b38:	478d                	li	a5,3
    80005b3a:	00f71763          	bne	a4,a5,80005b48 <sys_open+0x74>
    80005b3e:	04695703          	lhu	a4,70(s2)
    80005b42:	47a5                	li	a5,9
    80005b44:	0ce7ec63          	bltu	a5,a4,80005c1c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	e02080e7          	jalr	-510(ra) # 8000494a <filealloc>
    80005b50:	89aa                	mv	s3,a0
    80005b52:	10050263          	beqz	a0,80005c56 <sys_open+0x182>
    80005b56:	00000097          	auipc	ra,0x0
    80005b5a:	902080e7          	jalr	-1790(ra) # 80005458 <fdalloc>
    80005b5e:	84aa                	mv	s1,a0
    80005b60:	0e054663          	bltz	a0,80005c4c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b64:	04491703          	lh	a4,68(s2)
    80005b68:	478d                	li	a5,3
    80005b6a:	0cf70463          	beq	a4,a5,80005c32 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b6e:	4789                	li	a5,2
    80005b70:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b74:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b78:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b7c:	f4c42783          	lw	a5,-180(s0)
    80005b80:	0017c713          	xori	a4,a5,1
    80005b84:	8b05                	andi	a4,a4,1
    80005b86:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b8a:	0037f713          	andi	a4,a5,3
    80005b8e:	00e03733          	snez	a4,a4
    80005b92:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b96:	4007f793          	andi	a5,a5,1024
    80005b9a:	c791                	beqz	a5,80005ba6 <sys_open+0xd2>
    80005b9c:	04491703          	lh	a4,68(s2)
    80005ba0:	4789                	li	a5,2
    80005ba2:	08f70f63          	beq	a4,a5,80005c40 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ba6:	854a                	mv	a0,s2
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	082080e7          	jalr	130(ra) # 80003c2a <iunlock>
  end_op();
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	a0a080e7          	jalr	-1526(ra) # 800045ba <end_op>

  return fd;
}
    80005bb8:	8526                	mv	a0,s1
    80005bba:	70ea                	ld	ra,184(sp)
    80005bbc:	744a                	ld	s0,176(sp)
    80005bbe:	74aa                	ld	s1,168(sp)
    80005bc0:	790a                	ld	s2,160(sp)
    80005bc2:	69ea                	ld	s3,152(sp)
    80005bc4:	6129                	addi	sp,sp,192
    80005bc6:	8082                	ret
      end_op();
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	9f2080e7          	jalr	-1550(ra) # 800045ba <end_op>
      return -1;
    80005bd0:	b7e5                	j	80005bb8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bd2:	f5040513          	addi	a0,s0,-176
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	748080e7          	jalr	1864(ra) # 8000431e <namei>
    80005bde:	892a                	mv	s2,a0
    80005be0:	c905                	beqz	a0,80005c10 <sys_open+0x13c>
    ilock(ip);
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	f86080e7          	jalr	-122(ra) # 80003b68 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bea:	04491703          	lh	a4,68(s2)
    80005bee:	4785                	li	a5,1
    80005bf0:	f4f712e3          	bne	a4,a5,80005b34 <sys_open+0x60>
    80005bf4:	f4c42783          	lw	a5,-180(s0)
    80005bf8:	dba1                	beqz	a5,80005b48 <sys_open+0x74>
      iunlockput(ip);
    80005bfa:	854a                	mv	a0,s2
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	1ce080e7          	jalr	462(ra) # 80003dca <iunlockput>
      end_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	9b6080e7          	jalr	-1610(ra) # 800045ba <end_op>
      return -1;
    80005c0c:	54fd                	li	s1,-1
    80005c0e:	b76d                	j	80005bb8 <sys_open+0xe4>
      end_op();
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	9aa080e7          	jalr	-1622(ra) # 800045ba <end_op>
      return -1;
    80005c18:	54fd                	li	s1,-1
    80005c1a:	bf79                	j	80005bb8 <sys_open+0xe4>
    iunlockput(ip);
    80005c1c:	854a                	mv	a0,s2
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	1ac080e7          	jalr	428(ra) # 80003dca <iunlockput>
    end_op();
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	994080e7          	jalr	-1644(ra) # 800045ba <end_op>
    return -1;
    80005c2e:	54fd                	li	s1,-1
    80005c30:	b761                	j	80005bb8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c32:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c36:	04691783          	lh	a5,70(s2)
    80005c3a:	02f99223          	sh	a5,36(s3)
    80005c3e:	bf2d                	j	80005b78 <sys_open+0xa4>
    itrunc(ip);
    80005c40:	854a                	mv	a0,s2
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	034080e7          	jalr	52(ra) # 80003c76 <itrunc>
    80005c4a:	bfb1                	j	80005ba6 <sys_open+0xd2>
      fileclose(f);
    80005c4c:	854e                	mv	a0,s3
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	db8080e7          	jalr	-584(ra) # 80004a06 <fileclose>
    iunlockput(ip);
    80005c56:	854a                	mv	a0,s2
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	172080e7          	jalr	370(ra) # 80003dca <iunlockput>
    end_op();
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	95a080e7          	jalr	-1702(ra) # 800045ba <end_op>
    return -1;
    80005c68:	54fd                	li	s1,-1
    80005c6a:	b7b9                	j	80005bb8 <sys_open+0xe4>

0000000080005c6c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c6c:	7175                	addi	sp,sp,-144
    80005c6e:	e506                	sd	ra,136(sp)
    80005c70:	e122                	sd	s0,128(sp)
    80005c72:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	8c6080e7          	jalr	-1850(ra) # 8000453a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c7c:	08000613          	li	a2,128
    80005c80:	f7040593          	addi	a1,s0,-144
    80005c84:	4501                	li	a0,0
    80005c86:	ffffd097          	auipc	ra,0xffffd
    80005c8a:	36a080e7          	jalr	874(ra) # 80002ff0 <argstr>
    80005c8e:	02054963          	bltz	a0,80005cc0 <sys_mkdir+0x54>
    80005c92:	4681                	li	a3,0
    80005c94:	4601                	li	a2,0
    80005c96:	4585                	li	a1,1
    80005c98:	f7040513          	addi	a0,s0,-144
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	7fe080e7          	jalr	2046(ra) # 8000549a <create>
    80005ca4:	cd11                	beqz	a0,80005cc0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	124080e7          	jalr	292(ra) # 80003dca <iunlockput>
  end_op();
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	90c080e7          	jalr	-1780(ra) # 800045ba <end_op>
  return 0;
    80005cb6:	4501                	li	a0,0
}
    80005cb8:	60aa                	ld	ra,136(sp)
    80005cba:	640a                	ld	s0,128(sp)
    80005cbc:	6149                	addi	sp,sp,144
    80005cbe:	8082                	ret
    end_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	8fa080e7          	jalr	-1798(ra) # 800045ba <end_op>
    return -1;
    80005cc8:	557d                	li	a0,-1
    80005cca:	b7fd                	j	80005cb8 <sys_mkdir+0x4c>

0000000080005ccc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ccc:	7135                	addi	sp,sp,-160
    80005cce:	ed06                	sd	ra,152(sp)
    80005cd0:	e922                	sd	s0,144(sp)
    80005cd2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	866080e7          	jalr	-1946(ra) # 8000453a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cdc:	08000613          	li	a2,128
    80005ce0:	f7040593          	addi	a1,s0,-144
    80005ce4:	4501                	li	a0,0
    80005ce6:	ffffd097          	auipc	ra,0xffffd
    80005cea:	30a080e7          	jalr	778(ra) # 80002ff0 <argstr>
    80005cee:	04054a63          	bltz	a0,80005d42 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005cf2:	f6c40593          	addi	a1,s0,-148
    80005cf6:	4505                	li	a0,1
    80005cf8:	ffffd097          	auipc	ra,0xffffd
    80005cfc:	2b4080e7          	jalr	692(ra) # 80002fac <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d00:	04054163          	bltz	a0,80005d42 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d04:	f6840593          	addi	a1,s0,-152
    80005d08:	4509                	li	a0,2
    80005d0a:	ffffd097          	auipc	ra,0xffffd
    80005d0e:	2a2080e7          	jalr	674(ra) # 80002fac <argint>
     argint(1, &major) < 0 ||
    80005d12:	02054863          	bltz	a0,80005d42 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d16:	f6841683          	lh	a3,-152(s0)
    80005d1a:	f6c41603          	lh	a2,-148(s0)
    80005d1e:	458d                	li	a1,3
    80005d20:	f7040513          	addi	a0,s0,-144
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	776080e7          	jalr	1910(ra) # 8000549a <create>
     argint(2, &minor) < 0 ||
    80005d2c:	c919                	beqz	a0,80005d42 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	09c080e7          	jalr	156(ra) # 80003dca <iunlockput>
  end_op();
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	884080e7          	jalr	-1916(ra) # 800045ba <end_op>
  return 0;
    80005d3e:	4501                	li	a0,0
    80005d40:	a031                	j	80005d4c <sys_mknod+0x80>
    end_op();
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	878080e7          	jalr	-1928(ra) # 800045ba <end_op>
    return -1;
    80005d4a:	557d                	li	a0,-1
}
    80005d4c:	60ea                	ld	ra,152(sp)
    80005d4e:	644a                	ld	s0,144(sp)
    80005d50:	610d                	addi	sp,sp,160
    80005d52:	8082                	ret

0000000080005d54 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d54:	7135                	addi	sp,sp,-160
    80005d56:	ed06                	sd	ra,152(sp)
    80005d58:	e922                	sd	s0,144(sp)
    80005d5a:	e526                	sd	s1,136(sp)
    80005d5c:	e14a                	sd	s2,128(sp)
    80005d5e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d60:	ffffc097          	auipc	ra,0xffffc
    80005d64:	ba8080e7          	jalr	-1112(ra) # 80001908 <myproc>
    80005d68:	892a                	mv	s2,a0
  
  begin_op();
    80005d6a:	ffffe097          	auipc	ra,0xffffe
    80005d6e:	7d0080e7          	jalr	2000(ra) # 8000453a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d72:	08000613          	li	a2,128
    80005d76:	f6040593          	addi	a1,s0,-160
    80005d7a:	4501                	li	a0,0
    80005d7c:	ffffd097          	auipc	ra,0xffffd
    80005d80:	274080e7          	jalr	628(ra) # 80002ff0 <argstr>
    80005d84:	04054b63          	bltz	a0,80005dda <sys_chdir+0x86>
    80005d88:	f6040513          	addi	a0,s0,-160
    80005d8c:	ffffe097          	auipc	ra,0xffffe
    80005d90:	592080e7          	jalr	1426(ra) # 8000431e <namei>
    80005d94:	84aa                	mv	s1,a0
    80005d96:	c131                	beqz	a0,80005dda <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d98:	ffffe097          	auipc	ra,0xffffe
    80005d9c:	dd0080e7          	jalr	-560(ra) # 80003b68 <ilock>
  if(ip->type != T_DIR){
    80005da0:	04449703          	lh	a4,68(s1)
    80005da4:	4785                	li	a5,1
    80005da6:	04f71063          	bne	a4,a5,80005de6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005daa:	8526                	mv	a0,s1
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	e7e080e7          	jalr	-386(ra) # 80003c2a <iunlock>
  iput(p->cwd);
    80005db4:	17093503          	ld	a0,368(s2)
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	f6a080e7          	jalr	-150(ra) # 80003d22 <iput>
  end_op();
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	7fa080e7          	jalr	2042(ra) # 800045ba <end_op>
  p->cwd = ip;
    80005dc8:	16993823          	sd	s1,368(s2)
  return 0;
    80005dcc:	4501                	li	a0,0
}
    80005dce:	60ea                	ld	ra,152(sp)
    80005dd0:	644a                	ld	s0,144(sp)
    80005dd2:	64aa                	ld	s1,136(sp)
    80005dd4:	690a                	ld	s2,128(sp)
    80005dd6:	610d                	addi	sp,sp,160
    80005dd8:	8082                	ret
    end_op();
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	7e0080e7          	jalr	2016(ra) # 800045ba <end_op>
    return -1;
    80005de2:	557d                	li	a0,-1
    80005de4:	b7ed                	j	80005dce <sys_chdir+0x7a>
    iunlockput(ip);
    80005de6:	8526                	mv	a0,s1
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	fe2080e7          	jalr	-30(ra) # 80003dca <iunlockput>
    end_op();
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	7ca080e7          	jalr	1994(ra) # 800045ba <end_op>
    return -1;
    80005df8:	557d                	li	a0,-1
    80005dfa:	bfd1                	j	80005dce <sys_chdir+0x7a>

0000000080005dfc <sys_exec>:

uint64
sys_exec(void)
{
    80005dfc:	7145                	addi	sp,sp,-464
    80005dfe:	e786                	sd	ra,456(sp)
    80005e00:	e3a2                	sd	s0,448(sp)
    80005e02:	ff26                	sd	s1,440(sp)
    80005e04:	fb4a                	sd	s2,432(sp)
    80005e06:	f74e                	sd	s3,424(sp)
    80005e08:	f352                	sd	s4,416(sp)
    80005e0a:	ef56                	sd	s5,408(sp)
    80005e0c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e0e:	08000613          	li	a2,128
    80005e12:	f4040593          	addi	a1,s0,-192
    80005e16:	4501                	li	a0,0
    80005e18:	ffffd097          	auipc	ra,0xffffd
    80005e1c:	1d8080e7          	jalr	472(ra) # 80002ff0 <argstr>
    return -1;
    80005e20:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e22:	0c054a63          	bltz	a0,80005ef6 <sys_exec+0xfa>
    80005e26:	e3840593          	addi	a1,s0,-456
    80005e2a:	4505                	li	a0,1
    80005e2c:	ffffd097          	auipc	ra,0xffffd
    80005e30:	1a2080e7          	jalr	418(ra) # 80002fce <argaddr>
    80005e34:	0c054163          	bltz	a0,80005ef6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e38:	10000613          	li	a2,256
    80005e3c:	4581                	li	a1,0
    80005e3e:	e4040513          	addi	a0,s0,-448
    80005e42:	ffffb097          	auipc	ra,0xffffb
    80005e46:	e9e080e7          	jalr	-354(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e4a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e4e:	89a6                	mv	s3,s1
    80005e50:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e52:	02000a13          	li	s4,32
    80005e56:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e5a:	00391513          	slli	a0,s2,0x3
    80005e5e:	e3040593          	addi	a1,s0,-464
    80005e62:	e3843783          	ld	a5,-456(s0)
    80005e66:	953e                	add	a0,a0,a5
    80005e68:	ffffd097          	auipc	ra,0xffffd
    80005e6c:	0aa080e7          	jalr	170(ra) # 80002f12 <fetchaddr>
    80005e70:	02054a63          	bltz	a0,80005ea4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e74:	e3043783          	ld	a5,-464(s0)
    80005e78:	c3b9                	beqz	a5,80005ebe <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e7a:	ffffb097          	auipc	ra,0xffffb
    80005e7e:	c7a080e7          	jalr	-902(ra) # 80000af4 <kalloc>
    80005e82:	85aa                	mv	a1,a0
    80005e84:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e88:	cd11                	beqz	a0,80005ea4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e8a:	6605                	lui	a2,0x1
    80005e8c:	e3043503          	ld	a0,-464(s0)
    80005e90:	ffffd097          	auipc	ra,0xffffd
    80005e94:	0d4080e7          	jalr	212(ra) # 80002f64 <fetchstr>
    80005e98:	00054663          	bltz	a0,80005ea4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e9c:	0905                	addi	s2,s2,1
    80005e9e:	09a1                	addi	s3,s3,8
    80005ea0:	fb491be3          	bne	s2,s4,80005e56 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ea4:	10048913          	addi	s2,s1,256
    80005ea8:	6088                	ld	a0,0(s1)
    80005eaa:	c529                	beqz	a0,80005ef4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005eac:	ffffb097          	auipc	ra,0xffffb
    80005eb0:	b4c080e7          	jalr	-1204(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eb4:	04a1                	addi	s1,s1,8
    80005eb6:	ff2499e3          	bne	s1,s2,80005ea8 <sys_exec+0xac>
  return -1;
    80005eba:	597d                	li	s2,-1
    80005ebc:	a82d                	j	80005ef6 <sys_exec+0xfa>
      argv[i] = 0;
    80005ebe:	0a8e                	slli	s5,s5,0x3
    80005ec0:	fc040793          	addi	a5,s0,-64
    80005ec4:	9abe                	add	s5,s5,a5
    80005ec6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005eca:	e4040593          	addi	a1,s0,-448
    80005ece:	f4040513          	addi	a0,s0,-192
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	194080e7          	jalr	404(ra) # 80005066 <exec>
    80005eda:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005edc:	10048993          	addi	s3,s1,256
    80005ee0:	6088                	ld	a0,0(s1)
    80005ee2:	c911                	beqz	a0,80005ef6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ee4:	ffffb097          	auipc	ra,0xffffb
    80005ee8:	b14080e7          	jalr	-1260(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eec:	04a1                	addi	s1,s1,8
    80005eee:	ff3499e3          	bne	s1,s3,80005ee0 <sys_exec+0xe4>
    80005ef2:	a011                	j	80005ef6 <sys_exec+0xfa>
  return -1;
    80005ef4:	597d                	li	s2,-1
}
    80005ef6:	854a                	mv	a0,s2
    80005ef8:	60be                	ld	ra,456(sp)
    80005efa:	641e                	ld	s0,448(sp)
    80005efc:	74fa                	ld	s1,440(sp)
    80005efe:	795a                	ld	s2,432(sp)
    80005f00:	79ba                	ld	s3,424(sp)
    80005f02:	7a1a                	ld	s4,416(sp)
    80005f04:	6afa                	ld	s5,408(sp)
    80005f06:	6179                	addi	sp,sp,464
    80005f08:	8082                	ret

0000000080005f0a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f0a:	7139                	addi	sp,sp,-64
    80005f0c:	fc06                	sd	ra,56(sp)
    80005f0e:	f822                	sd	s0,48(sp)
    80005f10:	f426                	sd	s1,40(sp)
    80005f12:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f14:	ffffc097          	auipc	ra,0xffffc
    80005f18:	9f4080e7          	jalr	-1548(ra) # 80001908 <myproc>
    80005f1c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f1e:	fd840593          	addi	a1,s0,-40
    80005f22:	4501                	li	a0,0
    80005f24:	ffffd097          	auipc	ra,0xffffd
    80005f28:	0aa080e7          	jalr	170(ra) # 80002fce <argaddr>
    return -1;
    80005f2c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f2e:	0e054063          	bltz	a0,8000600e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f32:	fc840593          	addi	a1,s0,-56
    80005f36:	fd040513          	addi	a0,s0,-48
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	dfc080e7          	jalr	-516(ra) # 80004d36 <pipealloc>
    return -1;
    80005f42:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f44:	0c054563          	bltz	a0,8000600e <sys_pipe+0x104>
  fd0 = -1;
    80005f48:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f4c:	fd043503          	ld	a0,-48(s0)
    80005f50:	fffff097          	auipc	ra,0xfffff
    80005f54:	508080e7          	jalr	1288(ra) # 80005458 <fdalloc>
    80005f58:	fca42223          	sw	a0,-60(s0)
    80005f5c:	08054c63          	bltz	a0,80005ff4 <sys_pipe+0xea>
    80005f60:	fc843503          	ld	a0,-56(s0)
    80005f64:	fffff097          	auipc	ra,0xfffff
    80005f68:	4f4080e7          	jalr	1268(ra) # 80005458 <fdalloc>
    80005f6c:	fca42023          	sw	a0,-64(s0)
    80005f70:	06054863          	bltz	a0,80005fe0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f74:	4691                	li	a3,4
    80005f76:	fc440613          	addi	a2,s0,-60
    80005f7a:	fd843583          	ld	a1,-40(s0)
    80005f7e:	78a8                	ld	a0,112(s1)
    80005f80:	ffffb097          	auipc	ra,0xffffb
    80005f84:	6f2080e7          	jalr	1778(ra) # 80001672 <copyout>
    80005f88:	02054063          	bltz	a0,80005fa8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f8c:	4691                	li	a3,4
    80005f8e:	fc040613          	addi	a2,s0,-64
    80005f92:	fd843583          	ld	a1,-40(s0)
    80005f96:	0591                	addi	a1,a1,4
    80005f98:	78a8                	ld	a0,112(s1)
    80005f9a:	ffffb097          	auipc	ra,0xffffb
    80005f9e:	6d8080e7          	jalr	1752(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fa2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fa4:	06055563          	bgez	a0,8000600e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fa8:	fc442783          	lw	a5,-60(s0)
    80005fac:	07f9                	addi	a5,a5,30
    80005fae:	078e                	slli	a5,a5,0x3
    80005fb0:	97a6                	add	a5,a5,s1
    80005fb2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fb6:	fc042503          	lw	a0,-64(s0)
    80005fba:	0579                	addi	a0,a0,30
    80005fbc:	050e                	slli	a0,a0,0x3
    80005fbe:	9526                	add	a0,a0,s1
    80005fc0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fc4:	fd043503          	ld	a0,-48(s0)
    80005fc8:	fffff097          	auipc	ra,0xfffff
    80005fcc:	a3e080e7          	jalr	-1474(ra) # 80004a06 <fileclose>
    fileclose(wf);
    80005fd0:	fc843503          	ld	a0,-56(s0)
    80005fd4:	fffff097          	auipc	ra,0xfffff
    80005fd8:	a32080e7          	jalr	-1486(ra) # 80004a06 <fileclose>
    return -1;
    80005fdc:	57fd                	li	a5,-1
    80005fde:	a805                	j	8000600e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005fe0:	fc442783          	lw	a5,-60(s0)
    80005fe4:	0007c863          	bltz	a5,80005ff4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005fe8:	01e78513          	addi	a0,a5,30
    80005fec:	050e                	slli	a0,a0,0x3
    80005fee:	9526                	add	a0,a0,s1
    80005ff0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ff4:	fd043503          	ld	a0,-48(s0)
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	a0e080e7          	jalr	-1522(ra) # 80004a06 <fileclose>
    fileclose(wf);
    80006000:	fc843503          	ld	a0,-56(s0)
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	a02080e7          	jalr	-1534(ra) # 80004a06 <fileclose>
    return -1;
    8000600c:	57fd                	li	a5,-1
}
    8000600e:	853e                	mv	a0,a5
    80006010:	70e2                	ld	ra,56(sp)
    80006012:	7442                	ld	s0,48(sp)
    80006014:	74a2                	ld	s1,40(sp)
    80006016:	6121                	addi	sp,sp,64
    80006018:	8082                	ret
    8000601a:	0000                	unimp
    8000601c:	0000                	unimp
	...

0000000080006020 <kernelvec>:
    80006020:	7111                	addi	sp,sp,-256
    80006022:	e006                	sd	ra,0(sp)
    80006024:	e40a                	sd	sp,8(sp)
    80006026:	e80e                	sd	gp,16(sp)
    80006028:	ec12                	sd	tp,24(sp)
    8000602a:	f016                	sd	t0,32(sp)
    8000602c:	f41a                	sd	t1,40(sp)
    8000602e:	f81e                	sd	t2,48(sp)
    80006030:	fc22                	sd	s0,56(sp)
    80006032:	e0a6                	sd	s1,64(sp)
    80006034:	e4aa                	sd	a0,72(sp)
    80006036:	e8ae                	sd	a1,80(sp)
    80006038:	ecb2                	sd	a2,88(sp)
    8000603a:	f0b6                	sd	a3,96(sp)
    8000603c:	f4ba                	sd	a4,104(sp)
    8000603e:	f8be                	sd	a5,112(sp)
    80006040:	fcc2                	sd	a6,120(sp)
    80006042:	e146                	sd	a7,128(sp)
    80006044:	e54a                	sd	s2,136(sp)
    80006046:	e94e                	sd	s3,144(sp)
    80006048:	ed52                	sd	s4,152(sp)
    8000604a:	f156                	sd	s5,160(sp)
    8000604c:	f55a                	sd	s6,168(sp)
    8000604e:	f95e                	sd	s7,176(sp)
    80006050:	fd62                	sd	s8,184(sp)
    80006052:	e1e6                	sd	s9,192(sp)
    80006054:	e5ea                	sd	s10,200(sp)
    80006056:	e9ee                	sd	s11,208(sp)
    80006058:	edf2                	sd	t3,216(sp)
    8000605a:	f1f6                	sd	t4,224(sp)
    8000605c:	f5fa                	sd	t5,232(sp)
    8000605e:	f9fe                	sd	t6,240(sp)
    80006060:	d7ffc0ef          	jal	ra,80002dde <kerneltrap>
    80006064:	6082                	ld	ra,0(sp)
    80006066:	6122                	ld	sp,8(sp)
    80006068:	61c2                	ld	gp,16(sp)
    8000606a:	7282                	ld	t0,32(sp)
    8000606c:	7322                	ld	t1,40(sp)
    8000606e:	73c2                	ld	t2,48(sp)
    80006070:	7462                	ld	s0,56(sp)
    80006072:	6486                	ld	s1,64(sp)
    80006074:	6526                	ld	a0,72(sp)
    80006076:	65c6                	ld	a1,80(sp)
    80006078:	6666                	ld	a2,88(sp)
    8000607a:	7686                	ld	a3,96(sp)
    8000607c:	7726                	ld	a4,104(sp)
    8000607e:	77c6                	ld	a5,112(sp)
    80006080:	7866                	ld	a6,120(sp)
    80006082:	688a                	ld	a7,128(sp)
    80006084:	692a                	ld	s2,136(sp)
    80006086:	69ca                	ld	s3,144(sp)
    80006088:	6a6a                	ld	s4,152(sp)
    8000608a:	7a8a                	ld	s5,160(sp)
    8000608c:	7b2a                	ld	s6,168(sp)
    8000608e:	7bca                	ld	s7,176(sp)
    80006090:	7c6a                	ld	s8,184(sp)
    80006092:	6c8e                	ld	s9,192(sp)
    80006094:	6d2e                	ld	s10,200(sp)
    80006096:	6dce                	ld	s11,208(sp)
    80006098:	6e6e                	ld	t3,216(sp)
    8000609a:	7e8e                	ld	t4,224(sp)
    8000609c:	7f2e                	ld	t5,232(sp)
    8000609e:	7fce                	ld	t6,240(sp)
    800060a0:	6111                	addi	sp,sp,256
    800060a2:	10200073          	sret
    800060a6:	00000013          	nop
    800060aa:	00000013          	nop
    800060ae:	0001                	nop

00000000800060b0 <timervec>:
    800060b0:	34051573          	csrrw	a0,mscratch,a0
    800060b4:	e10c                	sd	a1,0(a0)
    800060b6:	e510                	sd	a2,8(a0)
    800060b8:	e914                	sd	a3,16(a0)
    800060ba:	6d0c                	ld	a1,24(a0)
    800060bc:	7110                	ld	a2,32(a0)
    800060be:	6194                	ld	a3,0(a1)
    800060c0:	96b2                	add	a3,a3,a2
    800060c2:	e194                	sd	a3,0(a1)
    800060c4:	4589                	li	a1,2
    800060c6:	14459073          	csrw	sip,a1
    800060ca:	6914                	ld	a3,16(a0)
    800060cc:	6510                	ld	a2,8(a0)
    800060ce:	610c                	ld	a1,0(a0)
    800060d0:	34051573          	csrrw	a0,mscratch,a0
    800060d4:	30200073          	mret
	...

00000000800060da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060da:	1141                	addi	sp,sp,-16
    800060dc:	e422                	sd	s0,8(sp)
    800060de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060e0:	0c0007b7          	lui	a5,0xc000
    800060e4:	4705                	li	a4,1
    800060e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060e8:	c3d8                	sw	a4,4(a5)
}
    800060ea:	6422                	ld	s0,8(sp)
    800060ec:	0141                	addi	sp,sp,16
    800060ee:	8082                	ret

00000000800060f0 <plicinithart>:

void
plicinithart(void)
{
    800060f0:	1141                	addi	sp,sp,-16
    800060f2:	e406                	sd	ra,8(sp)
    800060f4:	e022                	sd	s0,0(sp)
    800060f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060f8:	ffffb097          	auipc	ra,0xffffb
    800060fc:	7dc080e7          	jalr	2012(ra) # 800018d4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006100:	0085171b          	slliw	a4,a0,0x8
    80006104:	0c0027b7          	lui	a5,0xc002
    80006108:	97ba                	add	a5,a5,a4
    8000610a:	40200713          	li	a4,1026
    8000610e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006112:	00d5151b          	slliw	a0,a0,0xd
    80006116:	0c2017b7          	lui	a5,0xc201
    8000611a:	953e                	add	a0,a0,a5
    8000611c:	00052023          	sw	zero,0(a0)
}
    80006120:	60a2                	ld	ra,8(sp)
    80006122:	6402                	ld	s0,0(sp)
    80006124:	0141                	addi	sp,sp,16
    80006126:	8082                	ret

0000000080006128 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006128:	1141                	addi	sp,sp,-16
    8000612a:	e406                	sd	ra,8(sp)
    8000612c:	e022                	sd	s0,0(sp)
    8000612e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	7a4080e7          	jalr	1956(ra) # 800018d4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006138:	00d5179b          	slliw	a5,a0,0xd
    8000613c:	0c201537          	lui	a0,0xc201
    80006140:	953e                	add	a0,a0,a5
  return irq;
}
    80006142:	4148                	lw	a0,4(a0)
    80006144:	60a2                	ld	ra,8(sp)
    80006146:	6402                	ld	s0,0(sp)
    80006148:	0141                	addi	sp,sp,16
    8000614a:	8082                	ret

000000008000614c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000614c:	1101                	addi	sp,sp,-32
    8000614e:	ec06                	sd	ra,24(sp)
    80006150:	e822                	sd	s0,16(sp)
    80006152:	e426                	sd	s1,8(sp)
    80006154:	1000                	addi	s0,sp,32
    80006156:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006158:	ffffb097          	auipc	ra,0xffffb
    8000615c:	77c080e7          	jalr	1916(ra) # 800018d4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006160:	00d5151b          	slliw	a0,a0,0xd
    80006164:	0c2017b7          	lui	a5,0xc201
    80006168:	97aa                	add	a5,a5,a0
    8000616a:	c3c4                	sw	s1,4(a5)
}
    8000616c:	60e2                	ld	ra,24(sp)
    8000616e:	6442                	ld	s0,16(sp)
    80006170:	64a2                	ld	s1,8(sp)
    80006172:	6105                	addi	sp,sp,32
    80006174:	8082                	ret

0000000080006176 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006176:	1141                	addi	sp,sp,-16
    80006178:	e406                	sd	ra,8(sp)
    8000617a:	e022                	sd	s0,0(sp)
    8000617c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000617e:	479d                	li	a5,7
    80006180:	06a7c963          	blt	a5,a0,800061f2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006184:	0001d797          	auipc	a5,0x1d
    80006188:	e7c78793          	addi	a5,a5,-388 # 80023000 <disk>
    8000618c:	00a78733          	add	a4,a5,a0
    80006190:	6789                	lui	a5,0x2
    80006192:	97ba                	add	a5,a5,a4
    80006194:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006198:	e7ad                	bnez	a5,80006202 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000619a:	00451793          	slli	a5,a0,0x4
    8000619e:	0001f717          	auipc	a4,0x1f
    800061a2:	e6270713          	addi	a4,a4,-414 # 80025000 <disk+0x2000>
    800061a6:	6314                	ld	a3,0(a4)
    800061a8:	96be                	add	a3,a3,a5
    800061aa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061ae:	6314                	ld	a3,0(a4)
    800061b0:	96be                	add	a3,a3,a5
    800061b2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061b6:	6314                	ld	a3,0(a4)
    800061b8:	96be                	add	a3,a3,a5
    800061ba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061be:	6318                	ld	a4,0(a4)
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061c6:	0001d797          	auipc	a5,0x1d
    800061ca:	e3a78793          	addi	a5,a5,-454 # 80023000 <disk>
    800061ce:	97aa                	add	a5,a5,a0
    800061d0:	6509                	lui	a0,0x2
    800061d2:	953e                	add	a0,a0,a5
    800061d4:	4785                	li	a5,1
    800061d6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061da:	0001f517          	auipc	a0,0x1f
    800061de:	e3e50513          	addi	a0,a0,-450 # 80025018 <disk+0x2018>
    800061e2:	ffffc097          	auipc	ra,0xffffc
    800061e6:	230080e7          	jalr	560(ra) # 80002412 <wakeup>
}
    800061ea:	60a2                	ld	ra,8(sp)
    800061ec:	6402                	ld	s0,0(sp)
    800061ee:	0141                	addi	sp,sp,16
    800061f0:	8082                	ret
    panic("free_desc 1");
    800061f2:	00002517          	auipc	a0,0x2
    800061f6:	58650513          	addi	a0,a0,1414 # 80008778 <syscalls+0x330>
    800061fa:	ffffa097          	auipc	ra,0xffffa
    800061fe:	344080e7          	jalr	836(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006202:	00002517          	auipc	a0,0x2
    80006206:	58650513          	addi	a0,a0,1414 # 80008788 <syscalls+0x340>
    8000620a:	ffffa097          	auipc	ra,0xffffa
    8000620e:	334080e7          	jalr	820(ra) # 8000053e <panic>

0000000080006212 <virtio_disk_init>:
{
    80006212:	1101                	addi	sp,sp,-32
    80006214:	ec06                	sd	ra,24(sp)
    80006216:	e822                	sd	s0,16(sp)
    80006218:	e426                	sd	s1,8(sp)
    8000621a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000621c:	00002597          	auipc	a1,0x2
    80006220:	57c58593          	addi	a1,a1,1404 # 80008798 <syscalls+0x350>
    80006224:	0001f517          	auipc	a0,0x1f
    80006228:	f0450513          	addi	a0,a0,-252 # 80025128 <disk+0x2128>
    8000622c:	ffffb097          	auipc	ra,0xffffb
    80006230:	928080e7          	jalr	-1752(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006234:	100017b7          	lui	a5,0x10001
    80006238:	4398                	lw	a4,0(a5)
    8000623a:	2701                	sext.w	a4,a4
    8000623c:	747277b7          	lui	a5,0x74727
    80006240:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006244:	0ef71163          	bne	a4,a5,80006326 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006248:	100017b7          	lui	a5,0x10001
    8000624c:	43dc                	lw	a5,4(a5)
    8000624e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006250:	4705                	li	a4,1
    80006252:	0ce79a63          	bne	a5,a4,80006326 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006256:	100017b7          	lui	a5,0x10001
    8000625a:	479c                	lw	a5,8(a5)
    8000625c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000625e:	4709                	li	a4,2
    80006260:	0ce79363          	bne	a5,a4,80006326 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006264:	100017b7          	lui	a5,0x10001
    80006268:	47d8                	lw	a4,12(a5)
    8000626a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000626c:	554d47b7          	lui	a5,0x554d4
    80006270:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006274:	0af71963          	bne	a4,a5,80006326 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006278:	100017b7          	lui	a5,0x10001
    8000627c:	4705                	li	a4,1
    8000627e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006280:	470d                	li	a4,3
    80006282:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006284:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006286:	c7ffe737          	lui	a4,0xc7ffe
    8000628a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000628e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006290:	2701                	sext.w	a4,a4
    80006292:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006294:	472d                	li	a4,11
    80006296:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006298:	473d                	li	a4,15
    8000629a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000629c:	6705                	lui	a4,0x1
    8000629e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062a4:	5bdc                	lw	a5,52(a5)
    800062a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062a8:	c7d9                	beqz	a5,80006336 <virtio_disk_init+0x124>
  if(max < NUM)
    800062aa:	471d                	li	a4,7
    800062ac:	08f77d63          	bgeu	a4,a5,80006346 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062b0:	100014b7          	lui	s1,0x10001
    800062b4:	47a1                	li	a5,8
    800062b6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062b8:	6609                	lui	a2,0x2
    800062ba:	4581                	li	a1,0
    800062bc:	0001d517          	auipc	a0,0x1d
    800062c0:	d4450513          	addi	a0,a0,-700 # 80023000 <disk>
    800062c4:	ffffb097          	auipc	ra,0xffffb
    800062c8:	a1c080e7          	jalr	-1508(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062cc:	0001d717          	auipc	a4,0x1d
    800062d0:	d3470713          	addi	a4,a4,-716 # 80023000 <disk>
    800062d4:	00c75793          	srli	a5,a4,0xc
    800062d8:	2781                	sext.w	a5,a5
    800062da:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062dc:	0001f797          	auipc	a5,0x1f
    800062e0:	d2478793          	addi	a5,a5,-732 # 80025000 <disk+0x2000>
    800062e4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062e6:	0001d717          	auipc	a4,0x1d
    800062ea:	d9a70713          	addi	a4,a4,-614 # 80023080 <disk+0x80>
    800062ee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062f0:	0001e717          	auipc	a4,0x1e
    800062f4:	d1070713          	addi	a4,a4,-752 # 80024000 <disk+0x1000>
    800062f8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062fa:	4705                	li	a4,1
    800062fc:	00e78c23          	sb	a4,24(a5)
    80006300:	00e78ca3          	sb	a4,25(a5)
    80006304:	00e78d23          	sb	a4,26(a5)
    80006308:	00e78da3          	sb	a4,27(a5)
    8000630c:	00e78e23          	sb	a4,28(a5)
    80006310:	00e78ea3          	sb	a4,29(a5)
    80006314:	00e78f23          	sb	a4,30(a5)
    80006318:	00e78fa3          	sb	a4,31(a5)
}
    8000631c:	60e2                	ld	ra,24(sp)
    8000631e:	6442                	ld	s0,16(sp)
    80006320:	64a2                	ld	s1,8(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret
    panic("could not find virtio disk");
    80006326:	00002517          	auipc	a0,0x2
    8000632a:	48250513          	addi	a0,a0,1154 # 800087a8 <syscalls+0x360>
    8000632e:	ffffa097          	auipc	ra,0xffffa
    80006332:	210080e7          	jalr	528(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006336:	00002517          	auipc	a0,0x2
    8000633a:	49250513          	addi	a0,a0,1170 # 800087c8 <syscalls+0x380>
    8000633e:	ffffa097          	auipc	ra,0xffffa
    80006342:	200080e7          	jalr	512(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	4a250513          	addi	a0,a0,1186 # 800087e8 <syscalls+0x3a0>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>

0000000080006356 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006356:	7159                	addi	sp,sp,-112
    80006358:	f486                	sd	ra,104(sp)
    8000635a:	f0a2                	sd	s0,96(sp)
    8000635c:	eca6                	sd	s1,88(sp)
    8000635e:	e8ca                	sd	s2,80(sp)
    80006360:	e4ce                	sd	s3,72(sp)
    80006362:	e0d2                	sd	s4,64(sp)
    80006364:	fc56                	sd	s5,56(sp)
    80006366:	f85a                	sd	s6,48(sp)
    80006368:	f45e                	sd	s7,40(sp)
    8000636a:	f062                	sd	s8,32(sp)
    8000636c:	ec66                	sd	s9,24(sp)
    8000636e:	e86a                	sd	s10,16(sp)
    80006370:	1880                	addi	s0,sp,112
    80006372:	892a                	mv	s2,a0
    80006374:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006376:	00c52c83          	lw	s9,12(a0)
    8000637a:	001c9c9b          	slliw	s9,s9,0x1
    8000637e:	1c82                	slli	s9,s9,0x20
    80006380:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006384:	0001f517          	auipc	a0,0x1f
    80006388:	da450513          	addi	a0,a0,-604 # 80025128 <disk+0x2128>
    8000638c:	ffffb097          	auipc	ra,0xffffb
    80006390:	858080e7          	jalr	-1960(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006394:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006396:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006398:	0001db97          	auipc	s7,0x1d
    8000639c:	c68b8b93          	addi	s7,s7,-920 # 80023000 <disk>
    800063a0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800063a2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800063a4:	8a4e                	mv	s4,s3
    800063a6:	a051                	j	8000642a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800063a8:	00fb86b3          	add	a3,s7,a5
    800063ac:	96da                	add	a3,a3,s6
    800063ae:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063b2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063b4:	0207c563          	bltz	a5,800063de <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063b8:	2485                	addiw	s1,s1,1
    800063ba:	0711                	addi	a4,a4,4
    800063bc:	25548063          	beq	s1,s5,800065fc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063c0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063c2:	0001f697          	auipc	a3,0x1f
    800063c6:	c5668693          	addi	a3,a3,-938 # 80025018 <disk+0x2018>
    800063ca:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063cc:	0006c583          	lbu	a1,0(a3)
    800063d0:	fde1                	bnez	a1,800063a8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063d2:	2785                	addiw	a5,a5,1
    800063d4:	0685                	addi	a3,a3,1
    800063d6:	ff879be3          	bne	a5,s8,800063cc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063da:	57fd                	li	a5,-1
    800063dc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800063de:	02905a63          	blez	s1,80006412 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063e2:	f9042503          	lw	a0,-112(s0)
    800063e6:	00000097          	auipc	ra,0x0
    800063ea:	d90080e7          	jalr	-624(ra) # 80006176 <free_desc>
      for(int j = 0; j < i; j++)
    800063ee:	4785                	li	a5,1
    800063f0:	0297d163          	bge	a5,s1,80006412 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063f4:	f9442503          	lw	a0,-108(s0)
    800063f8:	00000097          	auipc	ra,0x0
    800063fc:	d7e080e7          	jalr	-642(ra) # 80006176 <free_desc>
      for(int j = 0; j < i; j++)
    80006400:	4789                	li	a5,2
    80006402:	0097d863          	bge	a5,s1,80006412 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006406:	f9842503          	lw	a0,-104(s0)
    8000640a:	00000097          	auipc	ra,0x0
    8000640e:	d6c080e7          	jalr	-660(ra) # 80006176 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006412:	0001f597          	auipc	a1,0x1f
    80006416:	d1658593          	addi	a1,a1,-746 # 80025128 <disk+0x2128>
    8000641a:	0001f517          	auipc	a0,0x1f
    8000641e:	bfe50513          	addi	a0,a0,-1026 # 80025018 <disk+0x2018>
    80006422:	ffffc097          	auipc	ra,0xffffc
    80006426:	c86080e7          	jalr	-890(ra) # 800020a8 <sleep>
  for(int i = 0; i < 3; i++){
    8000642a:	f9040713          	addi	a4,s0,-112
    8000642e:	84ce                	mv	s1,s3
    80006430:	bf41                	j	800063c0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006432:	20058713          	addi	a4,a1,512
    80006436:	00471693          	slli	a3,a4,0x4
    8000643a:	0001d717          	auipc	a4,0x1d
    8000643e:	bc670713          	addi	a4,a4,-1082 # 80023000 <disk>
    80006442:	9736                	add	a4,a4,a3
    80006444:	4685                	li	a3,1
    80006446:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000644a:	20058713          	addi	a4,a1,512
    8000644e:	00471693          	slli	a3,a4,0x4
    80006452:	0001d717          	auipc	a4,0x1d
    80006456:	bae70713          	addi	a4,a4,-1106 # 80023000 <disk>
    8000645a:	9736                	add	a4,a4,a3
    8000645c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006460:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006464:	7679                	lui	a2,0xffffe
    80006466:	963e                	add	a2,a2,a5
    80006468:	0001f697          	auipc	a3,0x1f
    8000646c:	b9868693          	addi	a3,a3,-1128 # 80025000 <disk+0x2000>
    80006470:	6298                	ld	a4,0(a3)
    80006472:	9732                	add	a4,a4,a2
    80006474:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006476:	6298                	ld	a4,0(a3)
    80006478:	9732                	add	a4,a4,a2
    8000647a:	4541                	li	a0,16
    8000647c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000647e:	6298                	ld	a4,0(a3)
    80006480:	9732                	add	a4,a4,a2
    80006482:	4505                	li	a0,1
    80006484:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006488:	f9442703          	lw	a4,-108(s0)
    8000648c:	6288                	ld	a0,0(a3)
    8000648e:	962a                	add	a2,a2,a0
    80006490:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006494:	0712                	slli	a4,a4,0x4
    80006496:	6290                	ld	a2,0(a3)
    80006498:	963a                	add	a2,a2,a4
    8000649a:	05890513          	addi	a0,s2,88
    8000649e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800064a0:	6294                	ld	a3,0(a3)
    800064a2:	96ba                	add	a3,a3,a4
    800064a4:	40000613          	li	a2,1024
    800064a8:	c690                	sw	a2,8(a3)
  if(write)
    800064aa:	140d0063          	beqz	s10,800065ea <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064ae:	0001f697          	auipc	a3,0x1f
    800064b2:	b526b683          	ld	a3,-1198(a3) # 80025000 <disk+0x2000>
    800064b6:	96ba                	add	a3,a3,a4
    800064b8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064bc:	0001d817          	auipc	a6,0x1d
    800064c0:	b4480813          	addi	a6,a6,-1212 # 80023000 <disk>
    800064c4:	0001f517          	auipc	a0,0x1f
    800064c8:	b3c50513          	addi	a0,a0,-1220 # 80025000 <disk+0x2000>
    800064cc:	6114                	ld	a3,0(a0)
    800064ce:	96ba                	add	a3,a3,a4
    800064d0:	00c6d603          	lhu	a2,12(a3)
    800064d4:	00166613          	ori	a2,a2,1
    800064d8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064dc:	f9842683          	lw	a3,-104(s0)
    800064e0:	6110                	ld	a2,0(a0)
    800064e2:	9732                	add	a4,a4,a2
    800064e4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064e8:	20058613          	addi	a2,a1,512
    800064ec:	0612                	slli	a2,a2,0x4
    800064ee:	9642                	add	a2,a2,a6
    800064f0:	577d                	li	a4,-1
    800064f2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064f6:	00469713          	slli	a4,a3,0x4
    800064fa:	6114                	ld	a3,0(a0)
    800064fc:	96ba                	add	a3,a3,a4
    800064fe:	03078793          	addi	a5,a5,48
    80006502:	97c2                	add	a5,a5,a6
    80006504:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006506:	611c                	ld	a5,0(a0)
    80006508:	97ba                	add	a5,a5,a4
    8000650a:	4685                	li	a3,1
    8000650c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000650e:	611c                	ld	a5,0(a0)
    80006510:	97ba                	add	a5,a5,a4
    80006512:	4809                	li	a6,2
    80006514:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006518:	611c                	ld	a5,0(a0)
    8000651a:	973e                	add	a4,a4,a5
    8000651c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006520:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006524:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006528:	6518                	ld	a4,8(a0)
    8000652a:	00275783          	lhu	a5,2(a4)
    8000652e:	8b9d                	andi	a5,a5,7
    80006530:	0786                	slli	a5,a5,0x1
    80006532:	97ba                	add	a5,a5,a4
    80006534:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006538:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000653c:	6518                	ld	a4,8(a0)
    8000653e:	00275783          	lhu	a5,2(a4)
    80006542:	2785                	addiw	a5,a5,1
    80006544:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006548:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000654c:	100017b7          	lui	a5,0x10001
    80006550:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006554:	00492703          	lw	a4,4(s2)
    80006558:	4785                	li	a5,1
    8000655a:	02f71163          	bne	a4,a5,8000657c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000655e:	0001f997          	auipc	s3,0x1f
    80006562:	bca98993          	addi	s3,s3,-1078 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006566:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006568:	85ce                	mv	a1,s3
    8000656a:	854a                	mv	a0,s2
    8000656c:	ffffc097          	auipc	ra,0xffffc
    80006570:	b3c080e7          	jalr	-1220(ra) # 800020a8 <sleep>
  while(b->disk == 1) {
    80006574:	00492783          	lw	a5,4(s2)
    80006578:	fe9788e3          	beq	a5,s1,80006568 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000657c:	f9042903          	lw	s2,-112(s0)
    80006580:	20090793          	addi	a5,s2,512
    80006584:	00479713          	slli	a4,a5,0x4
    80006588:	0001d797          	auipc	a5,0x1d
    8000658c:	a7878793          	addi	a5,a5,-1416 # 80023000 <disk>
    80006590:	97ba                	add	a5,a5,a4
    80006592:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006596:	0001f997          	auipc	s3,0x1f
    8000659a:	a6a98993          	addi	s3,s3,-1430 # 80025000 <disk+0x2000>
    8000659e:	00491713          	slli	a4,s2,0x4
    800065a2:	0009b783          	ld	a5,0(s3)
    800065a6:	97ba                	add	a5,a5,a4
    800065a8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065ac:	854a                	mv	a0,s2
    800065ae:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065b2:	00000097          	auipc	ra,0x0
    800065b6:	bc4080e7          	jalr	-1084(ra) # 80006176 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065ba:	8885                	andi	s1,s1,1
    800065bc:	f0ed                	bnez	s1,8000659e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065be:	0001f517          	auipc	a0,0x1f
    800065c2:	b6a50513          	addi	a0,a0,-1174 # 80025128 <disk+0x2128>
    800065c6:	ffffa097          	auipc	ra,0xffffa
    800065ca:	6d2080e7          	jalr	1746(ra) # 80000c98 <release>
}
    800065ce:	70a6                	ld	ra,104(sp)
    800065d0:	7406                	ld	s0,96(sp)
    800065d2:	64e6                	ld	s1,88(sp)
    800065d4:	6946                	ld	s2,80(sp)
    800065d6:	69a6                	ld	s3,72(sp)
    800065d8:	6a06                	ld	s4,64(sp)
    800065da:	7ae2                	ld	s5,56(sp)
    800065dc:	7b42                	ld	s6,48(sp)
    800065de:	7ba2                	ld	s7,40(sp)
    800065e0:	7c02                	ld	s8,32(sp)
    800065e2:	6ce2                	ld	s9,24(sp)
    800065e4:	6d42                	ld	s10,16(sp)
    800065e6:	6165                	addi	sp,sp,112
    800065e8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065ea:	0001f697          	auipc	a3,0x1f
    800065ee:	a166b683          	ld	a3,-1514(a3) # 80025000 <disk+0x2000>
    800065f2:	96ba                	add	a3,a3,a4
    800065f4:	4609                	li	a2,2
    800065f6:	00c69623          	sh	a2,12(a3)
    800065fa:	b5c9                	j	800064bc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065fc:	f9042583          	lw	a1,-112(s0)
    80006600:	20058793          	addi	a5,a1,512
    80006604:	0792                	slli	a5,a5,0x4
    80006606:	0001d517          	auipc	a0,0x1d
    8000660a:	aa250513          	addi	a0,a0,-1374 # 800230a8 <disk+0xa8>
    8000660e:	953e                	add	a0,a0,a5
  if(write)
    80006610:	e20d11e3          	bnez	s10,80006432 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006614:	20058713          	addi	a4,a1,512
    80006618:	00471693          	slli	a3,a4,0x4
    8000661c:	0001d717          	auipc	a4,0x1d
    80006620:	9e470713          	addi	a4,a4,-1564 # 80023000 <disk>
    80006624:	9736                	add	a4,a4,a3
    80006626:	0a072423          	sw	zero,168(a4)
    8000662a:	b505                	j	8000644a <virtio_disk_rw+0xf4>

000000008000662c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000662c:	1101                	addi	sp,sp,-32
    8000662e:	ec06                	sd	ra,24(sp)
    80006630:	e822                	sd	s0,16(sp)
    80006632:	e426                	sd	s1,8(sp)
    80006634:	e04a                	sd	s2,0(sp)
    80006636:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006638:	0001f517          	auipc	a0,0x1f
    8000663c:	af050513          	addi	a0,a0,-1296 # 80025128 <disk+0x2128>
    80006640:	ffffa097          	auipc	ra,0xffffa
    80006644:	5a4080e7          	jalr	1444(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006648:	10001737          	lui	a4,0x10001
    8000664c:	533c                	lw	a5,96(a4)
    8000664e:	8b8d                	andi	a5,a5,3
    80006650:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006652:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006656:	0001f797          	auipc	a5,0x1f
    8000665a:	9aa78793          	addi	a5,a5,-1622 # 80025000 <disk+0x2000>
    8000665e:	6b94                	ld	a3,16(a5)
    80006660:	0207d703          	lhu	a4,32(a5)
    80006664:	0026d783          	lhu	a5,2(a3)
    80006668:	06f70163          	beq	a4,a5,800066ca <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000666c:	0001d917          	auipc	s2,0x1d
    80006670:	99490913          	addi	s2,s2,-1644 # 80023000 <disk>
    80006674:	0001f497          	auipc	s1,0x1f
    80006678:	98c48493          	addi	s1,s1,-1652 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000667c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006680:	6898                	ld	a4,16(s1)
    80006682:	0204d783          	lhu	a5,32(s1)
    80006686:	8b9d                	andi	a5,a5,7
    80006688:	078e                	slli	a5,a5,0x3
    8000668a:	97ba                	add	a5,a5,a4
    8000668c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000668e:	20078713          	addi	a4,a5,512
    80006692:	0712                	slli	a4,a4,0x4
    80006694:	974a                	add	a4,a4,s2
    80006696:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000669a:	e731                	bnez	a4,800066e6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000669c:	20078793          	addi	a5,a5,512
    800066a0:	0792                	slli	a5,a5,0x4
    800066a2:	97ca                	add	a5,a5,s2
    800066a4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066a6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066aa:	ffffc097          	auipc	ra,0xffffc
    800066ae:	d68080e7          	jalr	-664(ra) # 80002412 <wakeup>

    disk.used_idx += 1;
    800066b2:	0204d783          	lhu	a5,32(s1)
    800066b6:	2785                	addiw	a5,a5,1
    800066b8:	17c2                	slli	a5,a5,0x30
    800066ba:	93c1                	srli	a5,a5,0x30
    800066bc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066c0:	6898                	ld	a4,16(s1)
    800066c2:	00275703          	lhu	a4,2(a4)
    800066c6:	faf71be3          	bne	a4,a5,8000667c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066ca:	0001f517          	auipc	a0,0x1f
    800066ce:	a5e50513          	addi	a0,a0,-1442 # 80025128 <disk+0x2128>
    800066d2:	ffffa097          	auipc	ra,0xffffa
    800066d6:	5c6080e7          	jalr	1478(ra) # 80000c98 <release>
}
    800066da:	60e2                	ld	ra,24(sp)
    800066dc:	6442                	ld	s0,16(sp)
    800066de:	64a2                	ld	s1,8(sp)
    800066e0:	6902                	ld	s2,0(sp)
    800066e2:	6105                	addi	sp,sp,32
    800066e4:	8082                	ret
      panic("virtio_disk_intr status");
    800066e6:	00002517          	auipc	a0,0x2
    800066ea:	12250513          	addi	a0,a0,290 # 80008808 <syscalls+0x3c0>
    800066ee:	ffffa097          	auipc	ra,0xffffa
    800066f2:	e50080e7          	jalr	-432(ra) # 8000053e <panic>

00000000800066f6 <cas>:
    800066f6:	100522af          	lr.w	t0,(a0)
    800066fa:	00b29563          	bne	t0,a1,80006704 <fail>
    800066fe:	18c5252f          	sc.w	a0,a2,(a0)
    80006702:	8082                	ret

0000000080006704 <fail>:
    80006704:	4505                	li	a0,1
    80006706:	8082                	ret
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
