
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
    80000068:	11c78793          	addi	a5,a5,284 # 80006180 <timervec>
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
    80000130:	b30080e7          	jalr	-1232(ra) # 80001c5c <either_copyin>
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
    800001c8:	742080e7          	jalr	1858(ra) # 80001906 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	e50080e7          	jalr	-432(ra) # 80002024 <sleep>
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
    80000214:	9f6080e7          	jalr	-1546(ra) # 80001c06 <either_copyout>
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
    800002f6:	9c0080e7          	jalr	-1600(ra) # 80001cb2 <procdump>
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
    8000044a:	f5e080e7          	jalr	-162(ra) # 800023a4 <wakeup>
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
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	82878793          	addi	a5,a5,-2008 # 80021ca0 <devsw>
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
    800008a4:	b04080e7          	jalr	-1276(ra) # 800023a4 <wakeup>
    
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
    80000930:	6f8080e7          	jalr	1784(ra) # 80002024 <sleep>
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
    80000ed8:	d48080e7          	jalr	-696(ra) # 80002c1c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	2e4080e7          	jalr	740(ra) # 800061c0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	bf4080e7          	jalr	-1036(ra) # 80002ad8 <scheduler>
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
    80000f48:	f30080e7          	jalr	-208(ra) # 80001e74 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	ca8080e7          	jalr	-856(ra) # 80002bf4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	cc8080e7          	jalr	-824(ra) # 80002c1c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	24e080e7          	jalr	590(ra) # 800061aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	25c080e7          	jalr	604(ra) # 800061c0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	43c080e7          	jalr	1084(ra) # 800033a8 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	acc080e7          	jalr	-1332(ra) # 80003a40 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	a76080e7          	jalr	-1418(ra) # 800049f2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	35e080e7          	jalr	862(ra) # 800062e2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	90a080e7          	jalr	-1782(ra) # 80002896 <userinit>
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
    80001858:	00448493          	addi	s1,s1,4 # 80011858 <proc>
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
    80001872:	1eaa0a13          	addi	s4,s4,490 # 80017a58 <tickslock>
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
    800018ec:	2781                	sext.w	a5,a5
    800018ee:	0a800513          	li	a0,168
    800018f2:	02a787b3          	mul	a5,a5,a0
  return c;
}
    800018f6:	00010517          	auipc	a0,0x10
    800018fa:	9aa50513          	addi	a0,a0,-1622 # 800112a0 <cpus>
    800018fe:	953e                	add	a0,a0,a5
    80001900:	6422                	ld	s0,8(sp)
    80001902:	0141                	addi	sp,sp,16
    80001904:	8082                	ret

0000000080001906 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001906:	1101                	addi	sp,sp,-32
    80001908:	ec06                	sd	ra,24(sp)
    8000190a:	e822                	sd	s0,16(sp)
    8000190c:	e426                	sd	s1,8(sp)
    8000190e:	1000                	addi	s0,sp,32
  push_off();
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	288080e7          	jalr	648(ra) # 80000b98 <push_off>
    80001918:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000191a:	2781                	sext.w	a5,a5
    8000191c:	0a800713          	li	a4,168
    80001920:	02e787b3          	mul	a5,a5,a4
    80001924:	00010717          	auipc	a4,0x10
    80001928:	97c70713          	addi	a4,a4,-1668 # 800112a0 <cpus>
    8000192c:	97ba                	add	a5,a5,a4
    8000192e:	6384                	ld	s1,0(a5)
  pop_off();
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	308080e7          	jalr	776(ra) # 80000c38 <pop_off>
  return p;
}
    80001938:	8526                	mv	a0,s1
    8000193a:	60e2                	ld	ra,24(sp)
    8000193c:	6442                	ld	s0,16(sp)
    8000193e:	64a2                	ld	s1,8(sp)
    80001940:	6105                	addi	sp,sp,32
    80001942:	8082                	ret

0000000080001944 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001944:	1141                	addi	sp,sp,-16
    80001946:	e406                	sd	ra,8(sp)
    80001948:	e022                	sd	s0,0(sp)
    8000194a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    8000194c:	00000097          	auipc	ra,0x0
    80001950:	fba080e7          	jalr	-70(ra) # 80001906 <myproc>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	344080e7          	jalr	836(ra) # 80000c98 <release>

  if (first) {
    8000195c:	00007797          	auipc	a5,0x7
    80001960:	ec47a783          	lw	a5,-316(a5) # 80008820 <first.1718>
    80001964:	eb89                	bnez	a5,80001976 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001966:	00001097          	auipc	ra,0x1
    8000196a:	2ce080e7          	jalr	718(ra) # 80002c34 <usertrapret>
}
    8000196e:	60a2                	ld	ra,8(sp)
    80001970:	6402                	ld	s0,0(sp)
    80001972:	0141                	addi	sp,sp,16
    80001974:	8082                	ret
    first = 0;
    80001976:	00007797          	auipc	a5,0x7
    8000197a:	ea07a523          	sw	zero,-342(a5) # 80008820 <first.1718>
    fsinit(ROOTDEV);
    8000197e:	4505                	li	a0,1
    80001980:	00002097          	auipc	ra,0x2
    80001984:	040080e7          	jalr	64(ra) # 800039c0 <fsinit>
    80001988:	bff9                	j	80001966 <forkret+0x22>

000000008000198a <allocpid>:
allocpid() {
    8000198a:	1101                	addi	sp,sp,-32
    8000198c:	ec06                	sd	ra,24(sp)
    8000198e:	e822                	sd	s0,16(sp)
    80001990:	e426                	sd	s1,8(sp)
    80001992:	e04a                	sd	s2,0(sp)
    80001994:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001996:	00007917          	auipc	s2,0x7
    8000199a:	e9a90913          	addi	s2,s2,-358 # 80008830 <nextpid>
    8000199e:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid , pid , pid+1));
    800019a2:	0014861b          	addiw	a2,s1,1
    800019a6:	85a6                	mv	a1,s1
    800019a8:	854a                	mv	a0,s2
    800019aa:	00005097          	auipc	ra,0x5
    800019ae:	e1c080e7          	jalr	-484(ra) # 800067c6 <cas>
    800019b2:	f575                	bnez	a0,8000199e <allocpid+0x14>
}
    800019b4:	8526                	mv	a0,s1
    800019b6:	60e2                	ld	ra,24(sp)
    800019b8:	6442                	ld	s0,16(sp)
    800019ba:	64a2                	ld	s1,8(sp)
    800019bc:	6902                	ld	s2,0(sp)
    800019be:	6105                	addi	sp,sp,32
    800019c0:	8082                	ret

00000000800019c2 <proc_pagetable>:
{
    800019c2:	1101                	addi	sp,sp,-32
    800019c4:	ec06                	sd	ra,24(sp)
    800019c6:	e822                	sd	s0,16(sp)
    800019c8:	e426                	sd	s1,8(sp)
    800019ca:	e04a                	sd	s2,0(sp)
    800019cc:	1000                	addi	s0,sp,32
    800019ce:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019d0:	00000097          	auipc	ra,0x0
    800019d4:	96a080e7          	jalr	-1686(ra) # 8000133a <uvmcreate>
    800019d8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800019da:	c121                	beqz	a0,80001a1a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019dc:	4729                	li	a4,10
    800019de:	00005697          	auipc	a3,0x5
    800019e2:	62268693          	addi	a3,a3,1570 # 80007000 <_trampoline>
    800019e6:	6605                	lui	a2,0x1
    800019e8:	040005b7          	lui	a1,0x4000
    800019ec:	15fd                	addi	a1,a1,-1
    800019ee:	05b2                	slli	a1,a1,0xc
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	6c0080e7          	jalr	1728(ra) # 800010b0 <mappages>
    800019f8:	02054863          	bltz	a0,80001a28 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800019fc:	4719                	li	a4,6
    800019fe:	07893683          	ld	a3,120(s2)
    80001a02:	6605                	lui	a2,0x1
    80001a04:	020005b7          	lui	a1,0x2000
    80001a08:	15fd                	addi	a1,a1,-1
    80001a0a:	05b6                	slli	a1,a1,0xd
    80001a0c:	8526                	mv	a0,s1
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	6a2080e7          	jalr	1698(ra) # 800010b0 <mappages>
    80001a16:	02054163          	bltz	a0,80001a38 <proc_pagetable+0x76>
}
    80001a1a:	8526                	mv	a0,s1
    80001a1c:	60e2                	ld	ra,24(sp)
    80001a1e:	6442                	ld	s0,16(sp)
    80001a20:	64a2                	ld	s1,8(sp)
    80001a22:	6902                	ld	s2,0(sp)
    80001a24:	6105                	addi	sp,sp,32
    80001a26:	8082                	ret
    uvmfree(pagetable, 0);
    80001a28:	4581                	li	a1,0
    80001a2a:	8526                	mv	a0,s1
    80001a2c:	00000097          	auipc	ra,0x0
    80001a30:	b0a080e7          	jalr	-1270(ra) # 80001536 <uvmfree>
    return 0;
    80001a34:	4481                	li	s1,0
    80001a36:	b7d5                	j	80001a1a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a38:	4681                	li	a3,0
    80001a3a:	4605                	li	a2,1
    80001a3c:	040005b7          	lui	a1,0x4000
    80001a40:	15fd                	addi	a1,a1,-1
    80001a42:	05b2                	slli	a1,a1,0xc
    80001a44:	8526                	mv	a0,s1
    80001a46:	00000097          	auipc	ra,0x0
    80001a4a:	830080e7          	jalr	-2000(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001a4e:	4581                	li	a1,0
    80001a50:	8526                	mv	a0,s1
    80001a52:	00000097          	auipc	ra,0x0
    80001a56:	ae4080e7          	jalr	-1308(ra) # 80001536 <uvmfree>
    return 0;
    80001a5a:	4481                	li	s1,0
    80001a5c:	bf7d                	j	80001a1a <proc_pagetable+0x58>

0000000080001a5e <proc_freepagetable>:
{
    80001a5e:	1101                	addi	sp,sp,-32
    80001a60:	ec06                	sd	ra,24(sp)
    80001a62:	e822                	sd	s0,16(sp)
    80001a64:	e426                	sd	s1,8(sp)
    80001a66:	e04a                	sd	s2,0(sp)
    80001a68:	1000                	addi	s0,sp,32
    80001a6a:	84aa                	mv	s1,a0
    80001a6c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a6e:	4681                	li	a3,0
    80001a70:	4605                	li	a2,1
    80001a72:	040005b7          	lui	a1,0x4000
    80001a76:	15fd                	addi	a1,a1,-1
    80001a78:	05b2                	slli	a1,a1,0xc
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	7fc080e7          	jalr	2044(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001a82:	4681                	li	a3,0
    80001a84:	4605                	li	a2,1
    80001a86:	020005b7          	lui	a1,0x2000
    80001a8a:	15fd                	addi	a1,a1,-1
    80001a8c:	05b6                	slli	a1,a1,0xd
    80001a8e:	8526                	mv	a0,s1
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	7e6080e7          	jalr	2022(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001a98:	85ca                	mv	a1,s2
    80001a9a:	8526                	mv	a0,s1
    80001a9c:	00000097          	auipc	ra,0x0
    80001aa0:	a9a080e7          	jalr	-1382(ra) # 80001536 <uvmfree>
}
    80001aa4:	60e2                	ld	ra,24(sp)
    80001aa6:	6442                	ld	s0,16(sp)
    80001aa8:	64a2                	ld	s1,8(sp)
    80001aaa:	6902                	ld	s2,0(sp)
    80001aac:	6105                	addi	sp,sp,32
    80001aae:	8082                	ret

0000000080001ab0 <growproc>:
{
    80001ab0:	1101                	addi	sp,sp,-32
    80001ab2:	ec06                	sd	ra,24(sp)
    80001ab4:	e822                	sd	s0,16(sp)
    80001ab6:	e426                	sd	s1,8(sp)
    80001ab8:	e04a                	sd	s2,0(sp)
    80001aba:	1000                	addi	s0,sp,32
    80001abc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001abe:	00000097          	auipc	ra,0x0
    80001ac2:	e48080e7          	jalr	-440(ra) # 80001906 <myproc>
    80001ac6:	892a                	mv	s2,a0
  sz = p->sz;
    80001ac8:	752c                	ld	a1,104(a0)
    80001aca:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ace:	00904f63          	bgtz	s1,80001aec <growproc+0x3c>
  } else if(n < 0){
    80001ad2:	0204cc63          	bltz	s1,80001b0a <growproc+0x5a>
  p->sz = sz;
    80001ad6:	1602                	slli	a2,a2,0x20
    80001ad8:	9201                	srli	a2,a2,0x20
    80001ada:	06c93423          	sd	a2,104(s2)
  return 0;
    80001ade:	4501                	li	a0,0
}
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6902                	ld	s2,0(sp)
    80001ae8:	6105                	addi	sp,sp,32
    80001aea:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001aec:	9e25                	addw	a2,a2,s1
    80001aee:	1602                	slli	a2,a2,0x20
    80001af0:	9201                	srli	a2,a2,0x20
    80001af2:	1582                	slli	a1,a1,0x20
    80001af4:	9181                	srli	a1,a1,0x20
    80001af6:	7928                	ld	a0,112(a0)
    80001af8:	00000097          	auipc	ra,0x0
    80001afc:	92a080e7          	jalr	-1750(ra) # 80001422 <uvmalloc>
    80001b00:	0005061b          	sext.w	a2,a0
    80001b04:	fa69                	bnez	a2,80001ad6 <growproc+0x26>
      return -1;
    80001b06:	557d                	li	a0,-1
    80001b08:	bfe1                	j	80001ae0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001b0a:	9e25                	addw	a2,a2,s1
    80001b0c:	1602                	slli	a2,a2,0x20
    80001b0e:	9201                	srli	a2,a2,0x20
    80001b10:	1582                	slli	a1,a1,0x20
    80001b12:	9181                	srli	a1,a1,0x20
    80001b14:	7928                	ld	a0,112(a0)
    80001b16:	00000097          	auipc	ra,0x0
    80001b1a:	8c4080e7          	jalr	-1852(ra) # 800013da <uvmdealloc>
    80001b1e:	0005061b          	sext.w	a2,a0
    80001b22:	bf55                	j	80001ad6 <growproc+0x26>

0000000080001b24 <sched>:
{
    80001b24:	7179                	addi	sp,sp,-48
    80001b26:	f406                	sd	ra,40(sp)
    80001b28:	f022                	sd	s0,32(sp)
    80001b2a:	ec26                	sd	s1,24(sp)
    80001b2c:	e84a                	sd	s2,16(sp)
    80001b2e:	e44e                	sd	s3,8(sp)
    80001b30:	e052                	sd	s4,0(sp)
    80001b32:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	dd2080e7          	jalr	-558(ra) # 80001906 <myproc>
    80001b3c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	02c080e7          	jalr	44(ra) # 80000b6a <holding>
    80001b46:	c141                	beqz	a0,80001bc6 <sched+0xa2>
    80001b48:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001b4a:	2781                	sext.w	a5,a5
    80001b4c:	0a800713          	li	a4,168
    80001b50:	02e787b3          	mul	a5,a5,a4
    80001b54:	0000f717          	auipc	a4,0xf
    80001b58:	74c70713          	addi	a4,a4,1868 # 800112a0 <cpus>
    80001b5c:	97ba                	add	a5,a5,a4
    80001b5e:	5fb8                	lw	a4,120(a5)
    80001b60:	4785                	li	a5,1
    80001b62:	06f71a63          	bne	a4,a5,80001bd6 <sched+0xb2>
  if(p->state == RUNNING)
    80001b66:	4c98                	lw	a4,24(s1)
    80001b68:	4791                	li	a5,4
    80001b6a:	06f70e63          	beq	a4,a5,80001be6 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b6e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001b72:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001b74:	e3c9                	bnez	a5,80001bf6 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b76:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001b78:	0000f917          	auipc	s2,0xf
    80001b7c:	72890913          	addi	s2,s2,1832 # 800112a0 <cpus>
    80001b80:	2781                	sext.w	a5,a5
    80001b82:	0a800993          	li	s3,168
    80001b86:	033787b3          	mul	a5,a5,s3
    80001b8a:	97ca                	add	a5,a5,s2
    80001b8c:	07c7aa03          	lw	s4,124(a5)
    80001b90:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80001b92:	2581                	sext.w	a1,a1
    80001b94:	033585b3          	mul	a1,a1,s3
    80001b98:	05a1                	addi	a1,a1,8
    80001b9a:	95ca                	add	a1,a1,s2
    80001b9c:	08048513          	addi	a0,s1,128
    80001ba0:	00001097          	auipc	ra,0x1
    80001ba4:	fea080e7          	jalr	-22(ra) # 80002b8a <swtch>
    80001ba8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001baa:	2781                	sext.w	a5,a5
    80001bac:	033787b3          	mul	a5,a5,s3
    80001bb0:	993e                	add	s2,s2,a5
    80001bb2:	07492e23          	sw	s4,124(s2)
}
    80001bb6:	70a2                	ld	ra,40(sp)
    80001bb8:	7402                	ld	s0,32(sp)
    80001bba:	64e2                	ld	s1,24(sp)
    80001bbc:	6942                	ld	s2,16(sp)
    80001bbe:	69a2                	ld	s3,8(sp)
    80001bc0:	6a02                	ld	s4,0(sp)
    80001bc2:	6145                	addi	sp,sp,48
    80001bc4:	8082                	ret
    panic("sched p->lock");
    80001bc6:	00006517          	auipc	a0,0x6
    80001bca:	61a50513          	addi	a0,a0,1562 # 800081e0 <digits+0x1a0>
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	970080e7          	jalr	-1680(ra) # 8000053e <panic>
    panic("sched locks");
    80001bd6:	00006517          	auipc	a0,0x6
    80001bda:	61a50513          	addi	a0,a0,1562 # 800081f0 <digits+0x1b0>
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	960080e7          	jalr	-1696(ra) # 8000053e <panic>
    panic("sched running");
    80001be6:	00006517          	auipc	a0,0x6
    80001bea:	61a50513          	addi	a0,a0,1562 # 80008200 <digits+0x1c0>
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	950080e7          	jalr	-1712(ra) # 8000053e <panic>
    panic("sched interruptible");
    80001bf6:	00006517          	auipc	a0,0x6
    80001bfa:	61a50513          	addi	a0,a0,1562 # 80008210 <digits+0x1d0>
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	940080e7          	jalr	-1728(ra) # 8000053e <panic>

0000000080001c06 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80001c06:	7179                	addi	sp,sp,-48
    80001c08:	f406                	sd	ra,40(sp)
    80001c0a:	f022                	sd	s0,32(sp)
    80001c0c:	ec26                	sd	s1,24(sp)
    80001c0e:	e84a                	sd	s2,16(sp)
    80001c10:	e44e                	sd	s3,8(sp)
    80001c12:	e052                	sd	s4,0(sp)
    80001c14:	1800                	addi	s0,sp,48
    80001c16:	84aa                	mv	s1,a0
    80001c18:	892e                	mv	s2,a1
    80001c1a:	89b2                	mv	s3,a2
    80001c1c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	ce8080e7          	jalr	-792(ra) # 80001906 <myproc>
  if(user_dst){
    80001c26:	c08d                	beqz	s1,80001c48 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80001c28:	86d2                	mv	a3,s4
    80001c2a:	864e                	mv	a2,s3
    80001c2c:	85ca                	mv	a1,s2
    80001c2e:	7928                	ld	a0,112(a0)
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	a42080e7          	jalr	-1470(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80001c38:	70a2                	ld	ra,40(sp)
    80001c3a:	7402                	ld	s0,32(sp)
    80001c3c:	64e2                	ld	s1,24(sp)
    80001c3e:	6942                	ld	s2,16(sp)
    80001c40:	69a2                	ld	s3,8(sp)
    80001c42:	6a02                	ld	s4,0(sp)
    80001c44:	6145                	addi	sp,sp,48
    80001c46:	8082                	ret
    memmove((char *)dst, src, len);
    80001c48:	000a061b          	sext.w	a2,s4
    80001c4c:	85ce                	mv	a1,s3
    80001c4e:	854a                	mv	a0,s2
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	0f0080e7          	jalr	240(ra) # 80000d40 <memmove>
    return 0;
    80001c58:	8526                	mv	a0,s1
    80001c5a:	bff9                	j	80001c38 <either_copyout+0x32>

0000000080001c5c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80001c5c:	7179                	addi	sp,sp,-48
    80001c5e:	f406                	sd	ra,40(sp)
    80001c60:	f022                	sd	s0,32(sp)
    80001c62:	ec26                	sd	s1,24(sp)
    80001c64:	e84a                	sd	s2,16(sp)
    80001c66:	e44e                	sd	s3,8(sp)
    80001c68:	e052                	sd	s4,0(sp)
    80001c6a:	1800                	addi	s0,sp,48
    80001c6c:	892a                	mv	s2,a0
    80001c6e:	84ae                	mv	s1,a1
    80001c70:	89b2                	mv	s3,a2
    80001c72:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	c92080e7          	jalr	-878(ra) # 80001906 <myproc>
  if(user_src){
    80001c7c:	c08d                	beqz	s1,80001c9e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80001c7e:	86d2                	mv	a3,s4
    80001c80:	864e                	mv	a2,s3
    80001c82:	85ca                	mv	a1,s2
    80001c84:	7928                	ld	a0,112(a0)
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	a78080e7          	jalr	-1416(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80001c8e:	70a2                	ld	ra,40(sp)
    80001c90:	7402                	ld	s0,32(sp)
    80001c92:	64e2                	ld	s1,24(sp)
    80001c94:	6942                	ld	s2,16(sp)
    80001c96:	69a2                	ld	s3,8(sp)
    80001c98:	6a02                	ld	s4,0(sp)
    80001c9a:	6145                	addi	sp,sp,48
    80001c9c:	8082                	ret
    memmove(dst, (char*)src, len);
    80001c9e:	000a061b          	sext.w	a2,s4
    80001ca2:	85ce                	mv	a1,s3
    80001ca4:	854a                	mv	a0,s2
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	09a080e7          	jalr	154(ra) # 80000d40 <memmove>
    return 0;
    80001cae:	8526                	mv	a0,s1
    80001cb0:	bff9                	j	80001c8e <either_copyin+0x32>

0000000080001cb2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80001cb2:	715d                	addi	sp,sp,-80
    80001cb4:	e486                	sd	ra,72(sp)
    80001cb6:	e0a2                	sd	s0,64(sp)
    80001cb8:	fc26                	sd	s1,56(sp)
    80001cba:	f84a                	sd	s2,48(sp)
    80001cbc:	f44e                	sd	s3,40(sp)
    80001cbe:	f052                	sd	s4,32(sp)
    80001cc0:	ec56                	sd	s5,24(sp)
    80001cc2:	e85a                	sd	s6,16(sp)
    80001cc4:	e45e                	sd	s7,8(sp)
    80001cc6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	40050513          	addi	a0,a0,1024 # 800080c8 <digits+0x88>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	8b8080e7          	jalr	-1864(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001cd8:	00010497          	auipc	s1,0x10
    80001cdc:	cf848493          	addi	s1,s1,-776 # 800119d0 <proc+0x178>
    80001ce0:	00016917          	auipc	s2,0x16
    80001ce4:	ef090913          	addi	s2,s2,-272 # 80017bd0 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001ce8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80001cea:	00006997          	auipc	s3,0x6
    80001cee:	53e98993          	addi	s3,s3,1342 # 80008228 <digits+0x1e8>
    printf("%d %s %s", p->pid, state, p->name);
    80001cf2:	00006a97          	auipc	s5,0x6
    80001cf6:	53ea8a93          	addi	s5,s5,1342 # 80008230 <digits+0x1f0>
    printf("\n");
    80001cfa:	00006a17          	auipc	s4,0x6
    80001cfe:	3cea0a13          	addi	s4,s4,974 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d02:	00006b97          	auipc	s7,0x6
    80001d06:	5beb8b93          	addi	s7,s7,1470 # 800082c0 <states.1768>
    80001d0a:	a00d                	j	80001d2c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80001d0c:	eb86a583          	lw	a1,-328(a3)
    80001d10:	8556                	mv	a0,s5
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	876080e7          	jalr	-1930(ra) # 80000588 <printf>
    printf("\n");
    80001d1a:	8552                	mv	a0,s4
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	86c080e7          	jalr	-1940(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001d24:	18848493          	addi	s1,s1,392
    80001d28:	03248163          	beq	s1,s2,80001d4a <procdump+0x98>
    if(p->state == UNUSED)
    80001d2c:	86a6                	mv	a3,s1
    80001d2e:	ea04a783          	lw	a5,-352(s1)
    80001d32:	dbed                	beqz	a5,80001d24 <procdump+0x72>
      state = "???";
    80001d34:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d36:	fcfb6be3          	bltu	s6,a5,80001d0c <procdump+0x5a>
    80001d3a:	1782                	slli	a5,a5,0x20
    80001d3c:	9381                	srli	a5,a5,0x20
    80001d3e:	078e                	slli	a5,a5,0x3
    80001d40:	97de                	add	a5,a5,s7
    80001d42:	6390                	ld	a2,0(a5)
    80001d44:	f661                	bnez	a2,80001d0c <procdump+0x5a>
      state = "???";
    80001d46:	864e                	mv	a2,s3
    80001d48:	b7d1                	j	80001d0c <procdump+0x5a>
  }
}
    80001d4a:	60a6                	ld	ra,72(sp)
    80001d4c:	6406                	ld	s0,64(sp)
    80001d4e:	74e2                	ld	s1,56(sp)
    80001d50:	7942                	ld	s2,48(sp)
    80001d52:	79a2                	ld	s3,40(sp)
    80001d54:	7a02                	ld	s4,32(sp)
    80001d56:	6ae2                	ld	s5,24(sp)
    80001d58:	6b42                	ld	s6,16(sp)
    80001d5a:	6ba2                	ld	s7,8(sp)
    80001d5c:	6161                	addi	sp,sp,80
    80001d5e:	8082                	ret

0000000080001d60 <get_cpu>:
    return cpu_num;
}

int
get_cpu()
{
    80001d60:	1101                	addi	sp,sp,-32
    80001d62:	ec06                	sd	ra,24(sp)
    80001d64:	e822                	sd	s0,16(sp)
    80001d66:	e426                	sd	s1,8(sp)
    80001d68:	e04a                	sd	s2,0(sp)
    80001d6a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	b9a080e7          	jalr	-1126(ra) # 80001906 <myproc>
    80001d74:	84aa                	mv	s1,a0
  
  int cpu_num;
  acquire(&p->lock);
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	e6e080e7          	jalr	-402(ra) # 80000be4 <acquire>
  cpu_num = p->cpu_num;
    80001d7e:	0344a903          	lw	s2,52(s1)
  release(&p->lock);
    80001d82:	8526                	mv	a0,s1
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	f14080e7          	jalr	-236(ra) # 80000c98 <release>
  return cpu_num;
}
    80001d8c:	854a                	mv	a0,s2
    80001d8e:	60e2                	ld	ra,24(sp)
    80001d90:	6442                	ld	s0,16(sp)
    80001d92:	64a2                	ld	s1,8(sp)
    80001d94:	6902                	ld	s2,0(sp)
    80001d96:	6105                	addi	sp,sp,32
    80001d98:	8082                	ret

0000000080001d9a <add_to_list>:

void
add_to_list(int* curr_proc_index, struct proc* next_proc, struct spinlock* lock) {
    80001d9a:	7139                	addi	sp,sp,-64
    80001d9c:	fc06                	sd	ra,56(sp)
    80001d9e:	f822                	sd	s0,48(sp)
    80001da0:	f426                	sd	s1,40(sp)
    80001da2:	f04a                	sd	s2,32(sp)
    80001da4:	ec4e                	sd	s3,24(sp)
    80001da6:	e852                	sd	s4,16(sp)
    80001da8:	e456                	sd	s5,8(sp)
    80001daa:	0080                	addi	s0,sp,64
    80001dac:	84aa                	mv	s1,a0
    80001dae:	8aae                	mv	s5,a1
    80001db0:	8932                	mv	s2,a2
  acquire(lock);
    80001db2:	8532                	mv	a0,a2
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	e30080e7          	jalr	-464(ra) # 80000be4 <acquire>

  if(*curr_proc_index == -1){
    80001dbc:	409c                	lw	a5,0(s1)
    80001dbe:	577d                	li	a4,-1
    80001dc0:	08e78e63          	beq	a5,a4,80001e5c <add_to_list+0xc2>
    *curr_proc_index = next_proc->proc_index;
    next_proc->next_proc_index = -1;
    release(lock);
    return;
  }
  struct proc* curr_node = &proc[*curr_proc_index];
    80001dc4:	18800513          	li	a0,392
    80001dc8:	02a787b3          	mul	a5,a5,a0
    80001dcc:	00010517          	auipc	a0,0x10
    80001dd0:	a8c50513          	addi	a0,a0,-1396 # 80011858 <proc>
    80001dd4:	00a784b3          	add	s1,a5,a0
  acquire(&curr_node->proc_lock);
    80001dd8:	04078793          	addi	a5,a5,64
    80001ddc:	953e                	add	a0,a0,a5
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	e06080e7          	jalr	-506(ra) # 80000be4 <acquire>
  release(lock);
    80001de6:	854a                	mv	a0,s2
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	eb0080e7          	jalr	-336(ra) # 80000c98 <release>
  
  while(curr_node->next_proc_index != -1){
    80001df0:	5c88                	lw	a0,56(s1)
    80001df2:	57fd                	li	a5,-1
    80001df4:	02f50f63          	beq	a0,a5,80001e32 <add_to_list+0x98>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80001df8:	18800993          	li	s3,392
    80001dfc:	00010917          	auipc	s2,0x10
    80001e00:	a5c90913          	addi	s2,s2,-1444 # 80011858 <proc>
  while(curr_node->next_proc_index != -1){
    80001e04:	5a7d                	li	s4,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80001e06:	03350533          	mul	a0,a0,s3
    80001e0a:	04050513          	addi	a0,a0,64
    80001e0e:	954a                	add	a0,a0,s2
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	dd4080e7          	jalr	-556(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    80001e18:	04048513          	addi	a0,s1,64
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	e7c080e7          	jalr	-388(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    80001e24:	5c84                	lw	s1,56(s1)
    80001e26:	033484b3          	mul	s1,s1,s3
    80001e2a:	94ca                	add	s1,s1,s2
  while(curr_node->next_proc_index != -1){
    80001e2c:	5c88                	lw	a0,56(s1)
    80001e2e:	fd451ce3          	bne	a0,s4,80001e06 <add_to_list+0x6c>
    // printf("moving to: %d", curr_node->next_proc_index);
  }

  curr_node->next_proc_index = next_proc->proc_index;
    80001e32:	03caa783          	lw	a5,60(s5)
    80001e36:	dc9c                	sw	a5,56(s1)
  next_proc->next_proc_index = -1;
    80001e38:	57fd                	li	a5,-1
    80001e3a:	02faac23          	sw	a5,56(s5)
  release(&curr_node->proc_lock);
    80001e3e:	04048513          	addi	a0,s1,64
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e56080e7          	jalr	-426(ra) # 80000c98 <release>

}
    80001e4a:	70e2                	ld	ra,56(sp)
    80001e4c:	7442                	ld	s0,48(sp)
    80001e4e:	74a2                	ld	s1,40(sp)
    80001e50:	7902                	ld	s2,32(sp)
    80001e52:	69e2                	ld	s3,24(sp)
    80001e54:	6a42                	ld	s4,16(sp)
    80001e56:	6aa2                	ld	s5,8(sp)
    80001e58:	6121                	addi	sp,sp,64
    80001e5a:	8082                	ret
    *curr_proc_index = next_proc->proc_index;
    80001e5c:	03caa783          	lw	a5,60(s5)
    80001e60:	c09c                	sw	a5,0(s1)
    next_proc->next_proc_index = -1;
    80001e62:	57fd                	li	a5,-1
    80001e64:	02faac23          	sw	a5,56(s5)
    release(lock);
    80001e68:	854a                	mv	a0,s2
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e2e080e7          	jalr	-466(ra) # 80000c98 <release>
    return;
    80001e72:	bfe1                	j	80001e4a <add_to_list+0xb0>

0000000080001e74 <procinit>:
{
    80001e74:	711d                	addi	sp,sp,-96
    80001e76:	ec86                	sd	ra,88(sp)
    80001e78:	e8a2                	sd	s0,80(sp)
    80001e7a:	e4a6                	sd	s1,72(sp)
    80001e7c:	e0ca                	sd	s2,64(sp)
    80001e7e:	fc4e                	sd	s3,56(sp)
    80001e80:	f852                	sd	s4,48(sp)
    80001e82:	f456                	sd	s5,40(sp)
    80001e84:	f05a                	sd	s6,32(sp)
    80001e86:	ec5e                	sd	s7,24(sp)
    80001e88:	e862                	sd	s8,16(sp)
    80001e8a:	e466                	sd	s9,8(sp)
    80001e8c:	e06a                	sd	s10,0(sp)
    80001e8e:	1080                	addi	s0,sp,96
  initlock(&pid_lock, "nextpid");
    80001e90:	00006597          	auipc	a1,0x6
    80001e94:	3b058593          	addi	a1,a1,944 # 80008240 <digits+0x200>
    80001e98:	00010517          	auipc	a0,0x10
    80001e9c:	94850513          	addi	a0,a0,-1720 # 800117e0 <pid_lock>
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	cb4080e7          	jalr	-844(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ea8:	00006597          	auipc	a1,0x6
    80001eac:	3a058593          	addi	a1,a1,928 # 80008248 <digits+0x208>
    80001eb0:	00010517          	auipc	a0,0x10
    80001eb4:	94850513          	addi	a0,a0,-1720 # 800117f8 <wait_lock>
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	c9c080e7          	jalr	-868(ra) # 80000b54 <initlock>
  int index = 0;
    80001ec0:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001ec2:	00010497          	auipc	s1,0x10
    80001ec6:	99648493          	addi	s1,s1,-1642 # 80011858 <proc>
      initlock(&p->lock, "proc");
    80001eca:	00006d17          	auipc	s10,0x6
    80001ece:	38ed0d13          	addi	s10,s10,910 # 80008258 <digits+0x218>
      p->kstack = KSTACK((int) (p - proc));
    80001ed2:	8ca6                	mv	s9,s1
    80001ed4:	00006c17          	auipc	s8,0x6
    80001ed8:	12cc0c13          	addi	s8,s8,300 # 80008000 <etext>
    80001edc:	040009b7          	lui	s3,0x4000
    80001ee0:	19fd                	addi	s3,s3,-1
    80001ee2:	09b2                	slli	s3,s3,0xc
      p->next_proc_index = -1;
    80001ee4:	5bfd                	li	s7,-1
      add_to_list(&unused_head, p, &lock_unused_list);
    80001ee6:	00010b17          	auipc	s6,0x10
    80001eea:	92ab0b13          	addi	s6,s6,-1750 # 80011810 <lock_unused_list>
    80001eee:	00007a97          	auipc	s5,0x7
    80001ef2:	93ea8a93          	addi	s5,s5,-1730 # 8000882c <unused_head>
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001ef6:	00016a17          	auipc	s4,0x16
    80001efa:	b62a0a13          	addi	s4,s4,-1182 # 80017a58 <tickslock>
      initlock(&p->lock, "proc");
    80001efe:	85ea                	mv	a1,s10
    80001f00:	8526                	mv	a0,s1
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	c52080e7          	jalr	-942(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001f0a:	419487b3          	sub	a5,s1,s9
    80001f0e:	878d                	srai	a5,a5,0x3
    80001f10:	000c3703          	ld	a4,0(s8)
    80001f14:	02e787b3          	mul	a5,a5,a4
    80001f18:	2785                	addiw	a5,a5,1
    80001f1a:	00d7979b          	slliw	a5,a5,0xd
    80001f1e:	40f987b3          	sub	a5,s3,a5
    80001f22:	f0bc                	sd	a5,96(s1)
      p->proc_index = index;
    80001f24:	0324ae23          	sw	s2,60(s1)
      p->next_proc_index = -1;
    80001f28:	0374ac23          	sw	s7,56(s1)
      add_to_list(&unused_head, p, &lock_unused_list);
    80001f2c:	865a                	mv	a2,s6
    80001f2e:	85a6                	mv	a1,s1
    80001f30:	8556                	mv	a0,s5
    80001f32:	00000097          	auipc	ra,0x0
    80001f36:	e68080e7          	jalr	-408(ra) # 80001d9a <add_to_list>
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001f3a:	18848493          	addi	s1,s1,392
    80001f3e:	2905                	addiw	s2,s2,1
    80001f40:	fb449fe3          	bne	s1,s4,80001efe <procinit+0x8a>
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001f44:	0000f797          	auipc	a5,0xf
    80001f48:	35c78793          	addi	a5,a5,860 # 800112a0 <cpus>
      c->runnable_head = -1;
    80001f4c:	56fd                	li	a3,-1
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001f4e:	00010717          	auipc	a4,0x10
    80001f52:	89270713          	addi	a4,a4,-1902 # 800117e0 <pid_lock>
      c->counter= 0;
    80001f56:	0a07a023          	sw	zero,160(a5)
      c->runnable_head = -1;
    80001f5a:	08d7a023          	sw	a3,128(a5)
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001f5e:	0a878793          	addi	a5,a5,168
    80001f62:	fee79ae3          	bne	a5,a4,80001f56 <procinit+0xe2>
}
    80001f66:	60e6                	ld	ra,88(sp)
    80001f68:	6446                	ld	s0,80(sp)
    80001f6a:	64a6                	ld	s1,72(sp)
    80001f6c:	6906                	ld	s2,64(sp)
    80001f6e:	79e2                	ld	s3,56(sp)
    80001f70:	7a42                	ld	s4,48(sp)
    80001f72:	7aa2                	ld	s5,40(sp)
    80001f74:	7b02                	ld	s6,32(sp)
    80001f76:	6be2                	ld	s7,24(sp)
    80001f78:	6c42                	ld	s8,16(sp)
    80001f7a:	6ca2                	ld	s9,8(sp)
    80001f7c:	6d02                	ld	s10,0(sp)
    80001f7e:	6125                	addi	sp,sp,96
    80001f80:	8082                	ret

0000000080001f82 <yield>:
{
    80001f82:	1101                	addi	sp,sp,-32
    80001f84:	ec06                	sd	ra,24(sp)
    80001f86:	e822                	sd	s0,16(sp)
    80001f88:	e426                	sd	s1,8(sp)
    80001f8a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f8c:	00000097          	auipc	ra,0x0
    80001f90:	97a080e7          	jalr	-1670(ra) # 80001906 <myproc>
    80001f94:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	c4e080e7          	jalr	-946(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80001f9e:	478d                	li	a5,3
    80001fa0:	cc9c                	sw	a5,24(s1)
  add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    80001fa2:	58dc                	lw	a5,52(s1)
    80001fa4:	0a800513          	li	a0,168
    80001fa8:	02a787b3          	mul	a5,a5,a0
    80001fac:	0000f517          	auipc	a0,0xf
    80001fb0:	2f450513          	addi	a0,a0,756 # 800112a0 <cpus>
    80001fb4:	08878613          	addi	a2,a5,136
    80001fb8:	08078793          	addi	a5,a5,128
    80001fbc:	962a                	add	a2,a2,a0
    80001fbe:	85a6                	mv	a1,s1
    80001fc0:	953e                	add	a0,a0,a5
    80001fc2:	00000097          	auipc	ra,0x0
    80001fc6:	dd8080e7          	jalr	-552(ra) # 80001d9a <add_to_list>
  sched();
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	b5a080e7          	jalr	-1190(ra) # 80001b24 <sched>
  release(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	cc4080e7          	jalr	-828(ra) # 80000c98 <release>
}
    80001fdc:	60e2                	ld	ra,24(sp)
    80001fde:	6442                	ld	s0,16(sp)
    80001fe0:	64a2                	ld	s1,8(sp)
    80001fe2:	6105                	addi	sp,sp,32
    80001fe4:	8082                	ret

0000000080001fe6 <set_cpu>:
{
    80001fe6:	1101                	addi	sp,sp,-32
    80001fe8:	ec06                	sd	ra,24(sp)
    80001fea:	e822                	sd	s0,16(sp)
    80001fec:	e426                	sd	s1,8(sp)
    80001fee:	1000                	addi	s0,sp,32
    80001ff0:	84aa                	mv	s1,a0
    struct proc* p = myproc();
    80001ff2:	00000097          	auipc	ra,0x0
    80001ff6:	914080e7          	jalr	-1772(ra) # 80001906 <myproc>
    if(cas(&p->cpu_num, curr_cpu, cpu_num) !=0)
    80001ffa:	8626                	mv	a2,s1
    80001ffc:	594c                	lw	a1,52(a0)
    80001ffe:	03450513          	addi	a0,a0,52
    80002002:	00004097          	auipc	ra,0x4
    80002006:	7c4080e7          	jalr	1988(ra) # 800067c6 <cas>
    8000200a:	e919                	bnez	a0,80002020 <set_cpu+0x3a>
    yield();
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	f76080e7          	jalr	-138(ra) # 80001f82 <yield>
    return cpu_num;
    80002014:	8526                	mv	a0,s1
}
    80002016:	60e2                	ld	ra,24(sp)
    80002018:	6442                	ld	s0,16(sp)
    8000201a:	64a2                	ld	s1,8(sp)
    8000201c:	6105                	addi	sp,sp,32
    8000201e:	8082                	ret
        return -1;
    80002020:	557d                	li	a0,-1
    80002022:	bfd5                	j	80002016 <set_cpu+0x30>

0000000080002024 <sleep>:
{
    80002024:	7179                	addi	sp,sp,-48
    80002026:	f406                	sd	ra,40(sp)
    80002028:	f022                	sd	s0,32(sp)
    8000202a:	ec26                	sd	s1,24(sp)
    8000202c:	e84a                	sd	s2,16(sp)
    8000202e:	e44e                	sd	s3,8(sp)
    80002030:	1800                	addi	s0,sp,48
    80002032:	89aa                	mv	s3,a0
    80002034:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	8d0080e7          	jalr	-1840(ra) # 80001906 <myproc>
    8000203e:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	ba4080e7          	jalr	-1116(ra) # 80000be4 <acquire>
  add_to_list(&sleeping_head, p, &lock_sleeping_list);
    80002048:	0000f617          	auipc	a2,0xf
    8000204c:	7e060613          	addi	a2,a2,2016 # 80011828 <lock_sleeping_list>
    80002050:	85a6                	mv	a1,s1
    80002052:	00006517          	auipc	a0,0x6
    80002056:	7d650513          	addi	a0,a0,2006 # 80008828 <sleeping_head>
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	d40080e7          	jalr	-704(ra) # 80001d9a <add_to_list>
  release(lk);
    80002062:	854a                	mv	a0,s2
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c34080e7          	jalr	-972(ra) # 80000c98 <release>
  p->chan = chan;
    8000206c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002070:	4789                	li	a5,2
    80002072:	cc9c                	sw	a5,24(s1)
  sched();
    80002074:	00000097          	auipc	ra,0x0
    80002078:	ab0080e7          	jalr	-1360(ra) # 80001b24 <sched>
  p->chan = 0;
    8000207c:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    80002080:	8526                	mv	a0,s1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	c16080e7          	jalr	-1002(ra) # 80000c98 <release>
  acquire(lk);
    8000208a:	854a                	mv	a0,s2
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	b58080e7          	jalr	-1192(ra) # 80000be4 <acquire>
}
    80002094:	70a2                	ld	ra,40(sp)
    80002096:	7402                	ld	s0,32(sp)
    80002098:	64e2                	ld	s1,24(sp)
    8000209a:	6942                	ld	s2,16(sp)
    8000209c:	69a2                	ld	s3,8(sp)
    8000209e:	6145                	addi	sp,sp,48
    800020a0:	8082                	ret

00000000800020a2 <remove_from_list>:

int remove_from_list(int* curr_proc_index, struct proc* proc_to_remove, struct spinlock* lock) {
    800020a2:	7139                	addi	sp,sp,-64
    800020a4:	fc06                	sd	ra,56(sp)
    800020a6:	f822                	sd	s0,48(sp)
    800020a8:	f426                	sd	s1,40(sp)
    800020aa:	f04a                	sd	s2,32(sp)
    800020ac:	ec4e                	sd	s3,24(sp)
    800020ae:	e852                	sd	s4,16(sp)
    800020b0:	e456                	sd	s5,8(sp)
    800020b2:	e05a                	sd	s6,0(sp)
    800020b4:	0080                	addi	s0,sp,64
    800020b6:	84aa                	mv	s1,a0
    800020b8:	892e                	mv	s2,a1
    800020ba:	89b2                	mv	s3,a2
  acquire(lock);
    800020bc:	8532                	mv	a0,a2
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b26080e7          	jalr	-1242(ra) # 80000be4 <acquire>
  if(*curr_proc_index == -1) 
    800020c6:	0004aa03          	lw	s4,0(s1)
    800020ca:	57fd                	li	a5,-1
    800020cc:	0afa0663          	beq	s4,a5,80002178 <remove_from_list+0xd6>
  {
      release(lock);
      return -1;
  }
  acquire(&proc_to_remove->proc_lock);
    800020d0:	04090b13          	addi	s6,s2,64
    800020d4:	855a                	mv	a0,s6
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	b0e080e7          	jalr	-1266(ra) # 80000be4 <acquire>

  if(*curr_proc_index == proc_to_remove->proc_index){
    800020de:	409c                	lw	a5,0(s1)
    800020e0:	03c92703          	lw	a4,60(s2)
    800020e4:	0af70063          	beq	a4,a5,80002184 <remove_from_list+0xe2>
      release(&proc_to_remove->proc_lock);
      release(lock);
      return 1;
  }
  
  struct proc* curr_node = &proc[*curr_proc_index];
    800020e8:	18800513          	li	a0,392
    800020ec:	02a787b3          	mul	a5,a5,a0
    800020f0:	0000f517          	auipc	a0,0xf
    800020f4:	76850513          	addi	a0,a0,1896 # 80011858 <proc>
    800020f8:	00a784b3          	add	s1,a5,a0
  acquire(&curr_node->proc_lock);
    800020fc:	04078793          	addi	a5,a5,64
    80002100:	953e                	add	a0,a0,a5
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ae2080e7          	jalr	-1310(ra) # 80000be4 <acquire>
  release(lock);
    8000210a:	854e                	mv	a0,s3
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>
  
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002114:	5c88                	lw	a0,56(s1)
    80002116:	57fd                	li	a5,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80002118:	18800a13          	li	s4,392
    8000211c:	0000f997          	auipc	s3,0xf
    80002120:	73c98993          	addi	s3,s3,1852 # 80011858 <proc>
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002124:	5afd                	li	s5,-1
    80002126:	02f50c63          	beq	a0,a5,8000215e <remove_from_list+0xbc>
    8000212a:	03c92783          	lw	a5,60(s2)
    8000212e:	06a78d63          	beq	a5,a0,800021a8 <remove_from_list+0x106>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80002132:	03450533          	mul	a0,a0,s4
    80002136:	04050513          	addi	a0,a0,64
    8000213a:	954e                	add	a0,a0,s3
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	aa8080e7          	jalr	-1368(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    80002144:	04048513          	addi	a0,s1,64
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b50080e7          	jalr	-1200(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    80002150:	5c84                	lw	s1,56(s1)
    80002152:	034484b3          	mul	s1,s1,s4
    80002156:	94ce                	add	s1,s1,s3
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002158:	5c88                	lw	a0,56(s1)
    8000215a:	fd5518e3          	bne	a0,s5,8000212a <remove_from_list+0x88>
  }
  if(curr_node->next_proc_index == -1){
    release(&proc_to_remove->proc_lock);
    8000215e:	855a                	mv	a0,s6
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
    release(&curr_node->proc_lock);
    80002168:	04048513          	addi	a0,s1,64
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b2c080e7          	jalr	-1236(ra) # 80000c98 <release>
    return -1;
    80002174:	5a7d                	li	s4,-1
    80002176:	a8b1                	j	800021d2 <remove_from_list+0x130>
      release(lock);
    80002178:	854e                	mv	a0,s3
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	b1e080e7          	jalr	-1250(ra) # 80000c98 <release>
      return -1;
    80002182:	a881                	j	800021d2 <remove_from_list+0x130>
      *curr_proc_index = proc_to_remove->next_proc_index;
    80002184:	03892783          	lw	a5,56(s2)
    80002188:	c09c                	sw	a5,0(s1)
      proc_to_remove->next_proc_index = -1;
    8000218a:	57fd                	li	a5,-1
    8000218c:	02f92c23          	sw	a5,56(s2)
      release(&proc_to_remove->proc_lock);
    80002190:	855a                	mv	a0,s6
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
      release(lock);
    8000219a:	854e                	mv	a0,s3
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	afc080e7          	jalr	-1284(ra) # 80000c98 <release>
      return 1;
    800021a4:	4a05                	li	s4,1
    800021a6:	a035                	j	800021d2 <remove_from_list+0x130>
  if(curr_node->next_proc_index == -1){
    800021a8:	57fd                	li	a5,-1
    800021aa:	faf50ae3          	beq	a0,a5,8000215e <remove_from_list+0xbc>
  }

  curr_node->next_proc_index = proc_to_remove->next_proc_index;
    800021ae:	03892783          	lw	a5,56(s2)
    800021b2:	dc9c                	sw	a5,56(s1)
  proc_to_remove->next_proc_index = -1;
    800021b4:	57fd                	li	a5,-1
    800021b6:	02f92c23          	sw	a5,56(s2)
  release(&proc_to_remove->proc_lock);
    800021ba:	855a                	mv	a0,s6
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	adc080e7          	jalr	-1316(ra) # 80000c98 <release>
  release(&curr_node->proc_lock);
    800021c4:	04048513          	addi	a0,s1,64
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	ad0080e7          	jalr	-1328(ra) # 80000c98 <release>
  return 1;
    800021d0:	4a05                	li	s4,1
}
    800021d2:	8552                	mv	a0,s4
    800021d4:	70e2                	ld	ra,56(sp)
    800021d6:	7442                	ld	s0,48(sp)
    800021d8:	74a2                	ld	s1,40(sp)
    800021da:	7902                	ld	s2,32(sp)
    800021dc:	69e2                	ld	s3,24(sp)
    800021de:	6a42                	ld	s4,16(sp)
    800021e0:	6aa2                	ld	s5,8(sp)
    800021e2:	6b02                	ld	s6,0(sp)
    800021e4:	6121                	addi	sp,sp,64
    800021e6:	8082                	ret

00000000800021e8 <freeproc>:
{
    800021e8:	1101                	addi	sp,sp,-32
    800021ea:	ec06                	sd	ra,24(sp)
    800021ec:	e822                	sd	s0,16(sp)
    800021ee:	e426                	sd	s1,8(sp)
    800021f0:	1000                	addi	s0,sp,32
    800021f2:	84aa                	mv	s1,a0
  if(p->trapframe)
    800021f4:	7d28                	ld	a0,120(a0)
    800021f6:	c509                	beqz	a0,80002200 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	800080e7          	jalr	-2048(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002200:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80002204:	78a8                	ld	a0,112(s1)
    80002206:	c511                	beqz	a0,80002212 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002208:	74ac                	ld	a1,104(s1)
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	854080e7          	jalr	-1964(ra) # 80001a5e <proc_freepagetable>
  p->pagetable = 0;
    80002212:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80002216:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    8000221a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000221e:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002222:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80002226:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000222a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000222e:	0204a623          	sw	zero,44(s1)
  if(remove_from_list(&zombie_head, p, &lock_zombie_list) == 1){
    80002232:	0000f617          	auipc	a2,0xf
    80002236:	60e60613          	addi	a2,a2,1550 # 80011840 <lock_zombie_list>
    8000223a:	85a6                	mv	a1,s1
    8000223c:	00006517          	auipc	a0,0x6
    80002240:	5e850513          	addi	a0,a0,1512 # 80008824 <zombie_head>
    80002244:	00000097          	auipc	ra,0x0
    80002248:	e5e080e7          	jalr	-418(ra) # 800020a2 <remove_from_list>
    8000224c:	4785                	li	a5,1
    8000224e:	00f50763          	beq	a0,a5,8000225c <freeproc+0x74>
}
    80002252:	60e2                	ld	ra,24(sp)
    80002254:	6442                	ld	s0,16(sp)
    80002256:	64a2                	ld	s1,8(sp)
    80002258:	6105                	addi	sp,sp,32
    8000225a:	8082                	ret
    p->state = UNUSED;
    8000225c:	0004ac23          	sw	zero,24(s1)
    add_to_list(&unused_head, p, &lock_unused_list);
    80002260:	0000f617          	auipc	a2,0xf
    80002264:	5b060613          	addi	a2,a2,1456 # 80011810 <lock_unused_list>
    80002268:	85a6                	mv	a1,s1
    8000226a:	00006517          	auipc	a0,0x6
    8000226e:	5c250513          	addi	a0,a0,1474 # 8000882c <unused_head>
    80002272:	00000097          	auipc	ra,0x0
    80002276:	b28080e7          	jalr	-1240(ra) # 80001d9a <add_to_list>
}
    8000227a:	bfe1                	j	80002252 <freeproc+0x6a>

000000008000227c <wait>:
{
    8000227c:	715d                	addi	sp,sp,-80
    8000227e:	e486                	sd	ra,72(sp)
    80002280:	e0a2                	sd	s0,64(sp)
    80002282:	fc26                	sd	s1,56(sp)
    80002284:	f84a                	sd	s2,48(sp)
    80002286:	f44e                	sd	s3,40(sp)
    80002288:	f052                	sd	s4,32(sp)
    8000228a:	ec56                	sd	s5,24(sp)
    8000228c:	e85a                	sd	s6,16(sp)
    8000228e:	e45e                	sd	s7,8(sp)
    80002290:	e062                	sd	s8,0(sp)
    80002292:	0880                	addi	s0,sp,80
    80002294:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	670080e7          	jalr	1648(ra) # 80001906 <myproc>
    8000229e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022a0:	0000f517          	auipc	a0,0xf
    800022a4:	55850513          	addi	a0,a0,1368 # 800117f8 <wait_lock>
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	93c080e7          	jalr	-1732(ra) # 80000be4 <acquire>
    havekids = 0;
    800022b0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022b2:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022b4:	00015997          	auipc	s3,0x15
    800022b8:	7a498993          	addi	s3,s3,1956 # 80017a58 <tickslock>
        havekids = 1;
    800022bc:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022be:	0000fc17          	auipc	s8,0xf
    800022c2:	53ac0c13          	addi	s8,s8,1338 # 800117f8 <wait_lock>
    havekids = 0;
    800022c6:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022c8:	0000f497          	auipc	s1,0xf
    800022cc:	59048493          	addi	s1,s1,1424 # 80011858 <proc>
    800022d0:	a0bd                	j	8000233e <wait+0xc2>
          pid = np->pid;
    800022d2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022d6:	000b0e63          	beqz	s6,800022f2 <wait+0x76>
    800022da:	4691                	li	a3,4
    800022dc:	02c48613          	addi	a2,s1,44
    800022e0:	85da                	mv	a1,s6
    800022e2:	07093503          	ld	a0,112(s2)
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	38c080e7          	jalr	908(ra) # 80001672 <copyout>
    800022ee:	02054563          	bltz	a0,80002318 <wait+0x9c>
          freeproc(np);
    800022f2:	8526                	mv	a0,s1
    800022f4:	00000097          	auipc	ra,0x0
    800022f8:	ef4080e7          	jalr	-268(ra) # 800021e8 <freeproc>
          release(&np->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	99a080e7          	jalr	-1638(ra) # 80000c98 <release>
          release(&wait_lock);
    80002306:	0000f517          	auipc	a0,0xf
    8000230a:	4f250513          	addi	a0,a0,1266 # 800117f8 <wait_lock>
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	98a080e7          	jalr	-1654(ra) # 80000c98 <release>
          return pid;
    80002316:	a09d                	j	8000237c <wait+0x100>
            release(&np->lock);
    80002318:	8526                	mv	a0,s1
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	97e080e7          	jalr	-1666(ra) # 80000c98 <release>
            release(&wait_lock);
    80002322:	0000f517          	auipc	a0,0xf
    80002326:	4d650513          	addi	a0,a0,1238 # 800117f8 <wait_lock>
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	96e080e7          	jalr	-1682(ra) # 80000c98 <release>
            return -1;
    80002332:	59fd                	li	s3,-1
    80002334:	a0a1                	j	8000237c <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002336:	18848493          	addi	s1,s1,392
    8000233a:	03348463          	beq	s1,s3,80002362 <wait+0xe6>
      if(np->parent == p){
    8000233e:	6cbc                	ld	a5,88(s1)
    80002340:	ff279be3          	bne	a5,s2,80002336 <wait+0xba>
        acquire(&np->lock);
    80002344:	8526                	mv	a0,s1
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	89e080e7          	jalr	-1890(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000234e:	4c9c                	lw	a5,24(s1)
    80002350:	f94781e3          	beq	a5,s4,800022d2 <wait+0x56>
        release(&np->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	942080e7          	jalr	-1726(ra) # 80000c98 <release>
        havekids = 1;
    8000235e:	8756                	mv	a4,s5
    80002360:	bfd9                	j	80002336 <wait+0xba>
    if(!havekids || p->killed){
    80002362:	c701                	beqz	a4,8000236a <wait+0xee>
    80002364:	02892783          	lw	a5,40(s2)
    80002368:	c79d                	beqz	a5,80002396 <wait+0x11a>
      release(&wait_lock);
    8000236a:	0000f517          	auipc	a0,0xf
    8000236e:	48e50513          	addi	a0,a0,1166 # 800117f8 <wait_lock>
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	926080e7          	jalr	-1754(ra) # 80000c98 <release>
      return -1;
    8000237a:	59fd                	li	s3,-1
}
    8000237c:	854e                	mv	a0,s3
    8000237e:	60a6                	ld	ra,72(sp)
    80002380:	6406                	ld	s0,64(sp)
    80002382:	74e2                	ld	s1,56(sp)
    80002384:	7942                	ld	s2,48(sp)
    80002386:	79a2                	ld	s3,40(sp)
    80002388:	7a02                	ld	s4,32(sp)
    8000238a:	6ae2                	ld	s5,24(sp)
    8000238c:	6b42                	ld	s6,16(sp)
    8000238e:	6ba2                	ld	s7,8(sp)
    80002390:	6c02                	ld	s8,0(sp)
    80002392:	6161                	addi	sp,sp,80
    80002394:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002396:	85e2                	mv	a1,s8
    80002398:	854a                	mv	a0,s2
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	c8a080e7          	jalr	-886(ra) # 80002024 <sleep>
    havekids = 0;
    800023a2:	b715                	j	800022c6 <wait+0x4a>

00000000800023a4 <wakeup>:
{
    800023a4:	7159                	addi	sp,sp,-112
    800023a6:	f486                	sd	ra,104(sp)
    800023a8:	f0a2                	sd	s0,96(sp)
    800023aa:	eca6                	sd	s1,88(sp)
    800023ac:	e8ca                	sd	s2,80(sp)
    800023ae:	e4ce                	sd	s3,72(sp)
    800023b0:	e0d2                	sd	s4,64(sp)
    800023b2:	fc56                	sd	s5,56(sp)
    800023b4:	f85a                	sd	s6,48(sp)
    800023b6:	f45e                	sd	s7,40(sp)
    800023b8:	f062                	sd	s8,32(sp)
    800023ba:	ec66                	sd	s9,24(sp)
    800023bc:	e86a                	sd	s10,16(sp)
    800023be:	e46e                	sd	s11,8(sp)
    800023c0:	1880                	addi	s0,sp,112
    800023c2:	8b2a                	mv	s6,a0
  acquire(&lock_sleeping_list);
    800023c4:	0000f517          	auipc	a0,0xf
    800023c8:	46450513          	addi	a0,a0,1124 # 80011828 <lock_sleeping_list>
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	818080e7          	jalr	-2024(ra) # 80000be4 <acquire>
  if(sleeping_head != -1){
    800023d4:	00006497          	auipc	s1,0x6
    800023d8:	4544a483          	lw	s1,1108(s1) # 80008828 <sleeping_head>
    800023dc:	57fd                	li	a5,-1
    800023de:	10f48463          	beq	s1,a5,800024e6 <wakeup+0x142>
    p = &proc[sleeping_head];
    800023e2:	18800793          	li	a5,392
    800023e6:	02f484b3          	mul	s1,s1,a5
    800023ea:	0000f797          	auipc	a5,0xf
    800023ee:	46e78793          	addi	a5,a5,1134 # 80011858 <proc>
    800023f2:	94be                	add	s1,s1,a5
    release(&lock_sleeping_list);
    800023f4:	0000f517          	auipc	a0,0xf
    800023f8:	43450513          	addi	a0,a0,1076 # 80011828 <lock_sleeping_list>
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	89c080e7          	jalr	-1892(ra) # 80000c98 <release>
      if (p->state == SLEEPING && p->chan == chan) {
    80002404:	4a09                	li	s4,2
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    80002406:	0000fc97          	auipc	s9,0xf
    8000240a:	422c8c93          	addi	s9,s9,1058 # 80011828 <lock_sleeping_list>
    8000240e:	00006c17          	auipc	s8,0x6
    80002412:	41ac0c13          	addi	s8,s8,1050 # 80008828 <sleeping_head>
              p->state = RUNNABLE;
    80002416:	4d8d                	li	s11,3
              if(auto_balanced){
    80002418:	00007d17          	auipc	s10,0x7
    8000241c:	c10d0d13          	addi	s10,s10,-1008 # 80009028 <auto_balanced>
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    80002420:	0000fb97          	auipc	s7,0xf
    80002424:	e80b8b93          	addi	s7,s7,-384 # 800112a0 <cpus>
        p = &proc[curr_proc];
    80002428:	0000fa97          	auipc	s5,0xf
    8000242c:	430a8a93          	addi	s5,s5,1072 # 80011858 <proc>
    80002430:	a88d                	j	800024a2 <wakeup+0xfe>
      if (p->state == SLEEPING && p->chan == chan) {
    80002432:	709c                	ld	a5,32(s1)
    80002434:	09679263          	bne	a5,s6,800024b8 <wakeup+0x114>
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    80002438:	8666                	mv	a2,s9
    8000243a:	85a6                	mv	a1,s1
    8000243c:	8562                	mv	a0,s8
    8000243e:	00000097          	auipc	ra,0x0
    80002442:	c64080e7          	jalr	-924(ra) # 800020a2 <remove_from_list>
    80002446:	c92d                	beqz	a0,800024b8 <wakeup+0x114>
              p->state = RUNNABLE;
    80002448:	01b4ac23          	sw	s11,24(s1)
              if(auto_balanced){
    8000244c:	000d2783          	lw	a5,0(s10)
    80002450:	c789                	beqz	a5,8000245a <wakeup+0xb6>
                if(p->cpu_num == cpu_num){
    80002452:	58dc                	lw	a5,52(s1)
    80002454:	c785                	beqz	a5,8000247c <wakeup+0xd8>
                p->cpu_num = cpu_num;
    80002456:	0204aa23          	sw	zero,52(s1)
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    8000245a:	58c8                	lw	a0,52(s1)
    8000245c:	0a800793          	li	a5,168
    80002460:	02f50533          	mul	a0,a0,a5
    80002464:	08850613          	addi	a2,a0,136
    80002468:	08050513          	addi	a0,a0,128
    8000246c:	965e                	add	a2,a2,s7
    8000246e:	85a6                	mv	a1,s1
    80002470:	955e                	add	a0,a0,s7
    80002472:	00000097          	auipc	ra,0x0
    80002476:	928080e7          	jalr	-1752(ra) # 80001d9a <add_to_list>
    8000247a:	a83d                	j	800024b8 <wakeup+0x114>
                  while(cas(&c->counter, c->counter, c->counter + 1) != 0);
    8000247c:	0a0ba583          	lw	a1,160(s7)
    80002480:	0015861b          	addiw	a2,a1,1
    80002484:	0000f517          	auipc	a0,0xf
    80002488:	ebc50513          	addi	a0,a0,-324 # 80011340 <cpus+0xa0>
    8000248c:	00004097          	auipc	ra,0x4
    80002490:	33a080e7          	jalr	826(ra) # 800067c6 <cas>
    80002494:	f565                	bnez	a0,8000247c <wakeup+0xd8>
    80002496:	b7c1                	j	80002456 <wakeup+0xb2>
        p = &proc[curr_proc];
    80002498:	18800493          	li	s1,392
    8000249c:	029904b3          	mul	s1,s2,s1
    800024a0:	94d6                	add	s1,s1,s5
      acquire(&p->lock);
    800024a2:	89a6                	mv	s3,s1
    800024a4:	8526                	mv	a0,s1
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	73e080e7          	jalr	1854(ra) # 80000be4 <acquire>
      int next_proc = p->next_proc_index;
    800024ae:	0384a903          	lw	s2,56(s1)
      if (p->state == SLEEPING && p->chan == chan) {
    800024b2:	4c9c                	lw	a5,24(s1)
    800024b4:	f7478fe3          	beq	a5,s4,80002432 <wakeup+0x8e>
      release(&p->lock);
    800024b8:	854e                	mv	a0,s3
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	7de080e7          	jalr	2014(ra) # 80000c98 <release>
      if(curr_proc != -1) {
    800024c2:	57fd                	li	a5,-1
    800024c4:	fcf91ae3          	bne	s2,a5,80002498 <wakeup+0xf4>
}
    800024c8:	70a6                	ld	ra,104(sp)
    800024ca:	7406                	ld	s0,96(sp)
    800024cc:	64e6                	ld	s1,88(sp)
    800024ce:	6946                	ld	s2,80(sp)
    800024d0:	69a6                	ld	s3,72(sp)
    800024d2:	6a06                	ld	s4,64(sp)
    800024d4:	7ae2                	ld	s5,56(sp)
    800024d6:	7b42                	ld	s6,48(sp)
    800024d8:	7ba2                	ld	s7,40(sp)
    800024da:	7c02                	ld	s8,32(sp)
    800024dc:	6ce2                	ld	s9,24(sp)
    800024de:	6d42                	ld	s10,16(sp)
    800024e0:	6da2                	ld	s11,8(sp)
    800024e2:	6165                	addi	sp,sp,112
    800024e4:	8082                	ret
    release(&lock_sleeping_list);
    800024e6:	0000f517          	auipc	a0,0xf
    800024ea:	34250513          	addi	a0,a0,834 # 80011828 <lock_sleeping_list>
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	7aa080e7          	jalr	1962(ra) # 80000c98 <release>
    return;
    800024f6:	bfc9                	j	800024c8 <wakeup+0x124>

00000000800024f8 <reparent>:
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	e052                	sd	s4,0(sp)
    80002506:	1800                	addi	s0,sp,48
    80002508:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000250a:	0000f497          	auipc	s1,0xf
    8000250e:	34e48493          	addi	s1,s1,846 # 80011858 <proc>
      pp->parent = initproc;
    80002512:	00007a17          	auipc	s4,0x7
    80002516:	b1ea0a13          	addi	s4,s4,-1250 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000251a:	00015997          	auipc	s3,0x15
    8000251e:	53e98993          	addi	s3,s3,1342 # 80017a58 <tickslock>
    80002522:	a029                	j	8000252c <reparent+0x34>
    80002524:	18848493          	addi	s1,s1,392
    80002528:	01348d63          	beq	s1,s3,80002542 <reparent+0x4a>
    if(pp->parent == p){
    8000252c:	6cbc                	ld	a5,88(s1)
    8000252e:	ff279be3          	bne	a5,s2,80002524 <reparent+0x2c>
      pp->parent = initproc;
    80002532:	000a3503          	ld	a0,0(s4)
    80002536:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002538:	00000097          	auipc	ra,0x0
    8000253c:	e6c080e7          	jalr	-404(ra) # 800023a4 <wakeup>
    80002540:	b7d5                	j	80002524 <reparent+0x2c>
}
    80002542:	70a2                	ld	ra,40(sp)
    80002544:	7402                	ld	s0,32(sp)
    80002546:	64e2                	ld	s1,24(sp)
    80002548:	6942                	ld	s2,16(sp)
    8000254a:	69a2                	ld	s3,8(sp)
    8000254c:	6a02                	ld	s4,0(sp)
    8000254e:	6145                	addi	sp,sp,48
    80002550:	8082                	ret

0000000080002552 <exit>:
{
    80002552:	7179                	addi	sp,sp,-48
    80002554:	f406                	sd	ra,40(sp)
    80002556:	f022                	sd	s0,32(sp)
    80002558:	ec26                	sd	s1,24(sp)
    8000255a:	e84a                	sd	s2,16(sp)
    8000255c:	e44e                	sd	s3,8(sp)
    8000255e:	e052                	sd	s4,0(sp)
    80002560:	1800                	addi	s0,sp,48
    80002562:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	3a2080e7          	jalr	930(ra) # 80001906 <myproc>
    8000256c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000256e:	00007797          	auipc	a5,0x7
    80002572:	ac27b783          	ld	a5,-1342(a5) # 80009030 <initproc>
    80002576:	0f050493          	addi	s1,a0,240
    8000257a:	17050913          	addi	s2,a0,368
    8000257e:	02a79363          	bne	a5,a0,800025a4 <exit+0x52>
    panic("init exiting");
    80002582:	00006517          	auipc	a0,0x6
    80002586:	cde50513          	addi	a0,a0,-802 # 80008260 <digits+0x220>
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>
      fileclose(f);
    80002592:	00002097          	auipc	ra,0x2
    80002596:	544080e7          	jalr	1348(ra) # 80004ad6 <fileclose>
      p->ofile[fd] = 0;
    8000259a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000259e:	04a1                	addi	s1,s1,8
    800025a0:	01248563          	beq	s1,s2,800025aa <exit+0x58>
    if(p->ofile[fd]){
    800025a4:	6088                	ld	a0,0(s1)
    800025a6:	f575                	bnez	a0,80002592 <exit+0x40>
    800025a8:	bfdd                	j	8000259e <exit+0x4c>
  begin_op();
    800025aa:	00002097          	auipc	ra,0x2
    800025ae:	060080e7          	jalr	96(ra) # 8000460a <begin_op>
  iput(p->cwd);
    800025b2:	1709b503          	ld	a0,368(s3)
    800025b6:	00002097          	auipc	ra,0x2
    800025ba:	83c080e7          	jalr	-1988(ra) # 80003df2 <iput>
  end_op();
    800025be:	00002097          	auipc	ra,0x2
    800025c2:	0cc080e7          	jalr	204(ra) # 8000468a <end_op>
  p->cwd = 0;
    800025c6:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    800025ca:	0000f497          	auipc	s1,0xf
    800025ce:	22e48493          	addi	s1,s1,558 # 800117f8 <wait_lock>
    800025d2:	8526                	mv	a0,s1
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	610080e7          	jalr	1552(ra) # 80000be4 <acquire>
  reparent(p);
    800025dc:	854e                	mv	a0,s3
    800025de:	00000097          	auipc	ra,0x0
    800025e2:	f1a080e7          	jalr	-230(ra) # 800024f8 <reparent>
  wakeup(p->parent);
    800025e6:	0589b503          	ld	a0,88(s3)
    800025ea:	00000097          	auipc	ra,0x0
    800025ee:	dba080e7          	jalr	-582(ra) # 800023a4 <wakeup>
  acquire(&p->lock);
    800025f2:	854e                	mv	a0,s3
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	5f0080e7          	jalr	1520(ra) # 80000be4 <acquire>
  p->xstate = status;
    800025fc:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002600:	4795                	li	a5,5
    80002602:	00f9ac23          	sw	a5,24(s3)
  add_to_list(&zombie_head, p, &lock_zombie_list);
    80002606:	0000f617          	auipc	a2,0xf
    8000260a:	23a60613          	addi	a2,a2,570 # 80011840 <lock_zombie_list>
    8000260e:	85ce                	mv	a1,s3
    80002610:	00006517          	auipc	a0,0x6
    80002614:	21450513          	addi	a0,a0,532 # 80008824 <zombie_head>
    80002618:	fffff097          	auipc	ra,0xfffff
    8000261c:	782080e7          	jalr	1922(ra) # 80001d9a <add_to_list>
  release(&wait_lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	676080e7          	jalr	1654(ra) # 80000c98 <release>
  sched();
    8000262a:	fffff097          	auipc	ra,0xfffff
    8000262e:	4fa080e7          	jalr	1274(ra) # 80001b24 <sched>
  panic("zombie exit");
    80002632:	00006517          	auipc	a0,0x6
    80002636:	c3e50513          	addi	a0,a0,-962 # 80008270 <digits+0x230>
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	f04080e7          	jalr	-252(ra) # 8000053e <panic>

0000000080002642 <kill>:
{
    80002642:	7179                	addi	sp,sp,-48
    80002644:	f406                	sd	ra,40(sp)
    80002646:	f022                	sd	s0,32(sp)
    80002648:	ec26                	sd	s1,24(sp)
    8000264a:	e84a                	sd	s2,16(sp)
    8000264c:	e44e                	sd	s3,8(sp)
    8000264e:	1800                	addi	s0,sp,48
    80002650:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80002652:	0000f497          	auipc	s1,0xf
    80002656:	20648493          	addi	s1,s1,518 # 80011858 <proc>
    8000265a:	00015997          	auipc	s3,0x15
    8000265e:	3fe98993          	addi	s3,s3,1022 # 80017a58 <tickslock>
    acquire(&p->lock);
    80002662:	8526                	mv	a0,s1
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	580080e7          	jalr	1408(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000266c:	589c                	lw	a5,48(s1)
    8000266e:	01278d63          	beq	a5,s2,80002688 <kill+0x46>
    release(&p->lock);
    80002672:	8526                	mv	a0,s1
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	624080e7          	jalr	1572(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000267c:	18848493          	addi	s1,s1,392
    80002680:	ff3491e3          	bne	s1,s3,80002662 <kill+0x20>
  return -1;
    80002684:	557d                	li	a0,-1
    80002686:	a829                	j	800026a0 <kill+0x5e>
      p->killed = 1;
    80002688:	4785                	li	a5,1
    8000268a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000268c:	4c98                	lw	a4,24(s1)
    8000268e:	4789                	li	a5,2
    80002690:	00f70f63          	beq	a4,a5,800026ae <kill+0x6c>
      release(&p->lock);
    80002694:	8526                	mv	a0,s1
    80002696:	ffffe097          	auipc	ra,0xffffe
    8000269a:	602080e7          	jalr	1538(ra) # 80000c98 <release>
      return 0;
    8000269e:	4501                	li	a0,0
}
    800026a0:	70a2                	ld	ra,40(sp)
    800026a2:	7402                	ld	s0,32(sp)
    800026a4:	64e2                	ld	s1,24(sp)
    800026a6:	6942                	ld	s2,16(sp)
    800026a8:	69a2                	ld	s3,8(sp)
    800026aa:	6145                	addi	sp,sp,48
    800026ac:	8082                	ret
        if(remove_from_list(&sleeping_head, p, &lock_sleeping_list) == 1){
    800026ae:	0000f617          	auipc	a2,0xf
    800026b2:	17a60613          	addi	a2,a2,378 # 80011828 <lock_sleeping_list>
    800026b6:	85a6                	mv	a1,s1
    800026b8:	00006517          	auipc	a0,0x6
    800026bc:	17050513          	addi	a0,a0,368 # 80008828 <sleeping_head>
    800026c0:	00000097          	auipc	ra,0x0
    800026c4:	9e2080e7          	jalr	-1566(ra) # 800020a2 <remove_from_list>
    800026c8:	4785                	li	a5,1
    800026ca:	fcf515e3          	bne	a0,a5,80002694 <kill+0x52>
          p->state = RUNNABLE;
    800026ce:	478d                	li	a5,3
    800026d0:	cc9c                	sw	a5,24(s1)
          add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    800026d2:	58dc                	lw	a5,52(s1)
    800026d4:	0a800713          	li	a4,168
    800026d8:	02e787b3          	mul	a5,a5,a4
    800026dc:	0000f517          	auipc	a0,0xf
    800026e0:	bc450513          	addi	a0,a0,-1084 # 800112a0 <cpus>
    800026e4:	08878613          	addi	a2,a5,136
    800026e8:	08078793          	addi	a5,a5,128
    800026ec:	962a                	add	a2,a2,a0
    800026ee:	85a6                	mv	a1,s1
    800026f0:	953e                	add	a0,a0,a5
    800026f2:	fffff097          	auipc	ra,0xfffff
    800026f6:	6a8080e7          	jalr	1704(ra) # 80001d9a <add_to_list>
    800026fa:	bf69                	j	80002694 <kill+0x52>

00000000800026fc <remove_first>:

int remove_first(int* curr_proc_index, struct spinlock* lock) {
    800026fc:	7139                	addi	sp,sp,-64
    800026fe:	fc06                	sd	ra,56(sp)
    80002700:	f822                	sd	s0,48(sp)
    80002702:	f426                	sd	s1,40(sp)
    80002704:	f04a                	sd	s2,32(sp)
    80002706:	ec4e                	sd	s3,24(sp)
    80002708:	e852                	sd	s4,16(sp)
    8000270a:	e456                	sd	s5,8(sp)
    8000270c:	0080                	addi	s0,sp,64
    8000270e:	8aaa                	mv	s5,a0
    80002710:	89ae                	mv	s3,a1
    acquire(lock);
    80002712:	852e                	mv	a0,a1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	4d0080e7          	jalr	1232(ra) # 80000be4 <acquire>
    
    if (*curr_proc_index != -1){
    8000271c:	000aa483          	lw	s1,0(s5)
    80002720:	57fd                	li	a5,-1
    80002722:	04f48d63          	beq	s1,a5,8000277c <remove_first+0x80>
      int index = *curr_proc_index;
      struct proc *p = &proc[index];
      acquire(&p->proc_lock);
    80002726:	18800793          	li	a5,392
    8000272a:	02f484b3          	mul	s1,s1,a5
    8000272e:	04048a13          	addi	s4,s1,64
    80002732:	0000f917          	auipc	s2,0xf
    80002736:	12690913          	addi	s2,s2,294 # 80011858 <proc>
    8000273a:	9a4a                	add	s4,s4,s2
    8000273c:	8552                	mv	a0,s4
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
      
      *curr_proc_index = p->next_proc_index;
    80002746:	94ca                	add	s1,s1,s2
    80002748:	5c9c                	lw	a5,56(s1)
    8000274a:	00faa023          	sw	a5,0(s5)
      p->next_proc_index = -1;
    8000274e:	57fd                	li	a5,-1
    80002750:	dc9c                	sw	a5,56(s1)
      int output_proc = p->proc_index;
    80002752:	5cc4                	lw	s1,60(s1)

      release(&p->proc_lock);
    80002754:	8552                	mv	a0,s4
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	542080e7          	jalr	1346(ra) # 80000c98 <release>
      release(lock);
    8000275e:	854e                	mv	a0,s3
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	538080e7          	jalr	1336(ra) # 80000c98 <release>
    else{

      release(lock);
      return -1;
    }
    80002768:	8526                	mv	a0,s1
    8000276a:	70e2                	ld	ra,56(sp)
    8000276c:	7442                	ld	s0,48(sp)
    8000276e:	74a2                	ld	s1,40(sp)
    80002770:	7902                	ld	s2,32(sp)
    80002772:	69e2                	ld	s3,24(sp)
    80002774:	6a42                	ld	s4,16(sp)
    80002776:	6aa2                	ld	s5,8(sp)
    80002778:	6121                	addi	sp,sp,64
    8000277a:	8082                	ret
      release(lock);
    8000277c:	854e                	mv	a0,s3
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	51a080e7          	jalr	1306(ra) # 80000c98 <release>
      return -1;
    80002786:	b7cd                	j	80002768 <remove_first+0x6c>

0000000080002788 <allocproc>:
{
    80002788:	7179                	addi	sp,sp,-48
    8000278a:	f406                	sd	ra,40(sp)
    8000278c:	f022                	sd	s0,32(sp)
    8000278e:	ec26                	sd	s1,24(sp)
    80002790:	e84a                	sd	s2,16(sp)
    80002792:	e44e                	sd	s3,8(sp)
    80002794:	e052                	sd	s4,0(sp)
    80002796:	1800                	addi	s0,sp,48
    int allocation = remove_first(&unused_head, &lock_unused_list);
    80002798:	0000f597          	auipc	a1,0xf
    8000279c:	07858593          	addi	a1,a1,120 # 80011810 <lock_unused_list>
    800027a0:	00006517          	auipc	a0,0x6
    800027a4:	08c50513          	addi	a0,a0,140 # 8000882c <unused_head>
    800027a8:	00000097          	auipc	ra,0x0
    800027ac:	f54080e7          	jalr	-172(ra) # 800026fc <remove_first>
    if(allocation == -1){
    800027b0:	57fd                	li	a5,-1
    800027b2:	0ef50063          	beq	a0,a5,80002892 <allocproc+0x10a>
    800027b6:	892a                	mv	s2,a0
  p=&proc[allocation];
    800027b8:	18800993          	li	s3,392
    800027bc:	033509b3          	mul	s3,a0,s3
    800027c0:	0000f497          	auipc	s1,0xf
    800027c4:	09848493          	addi	s1,s1,152 # 80011858 <proc>
    800027c8:	94ce                	add	s1,s1,s3
  acquire(&p->lock);
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	418080e7          	jalr	1048(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800027d4:	fffff097          	auipc	ra,0xfffff
    800027d8:	1b6080e7          	jalr	438(ra) # 8000198a <allocpid>
    800027dc:	d888                	sw	a0,48(s1)
  p->state = USED;
    800027de:	4785                	li	a5,1
    800027e0:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	312080e7          	jalr	786(ra) # 80000af4 <kalloc>
    800027ea:	8a2a                	mv	s4,a0
    800027ec:	fca8                	sd	a0,120(s1)
    800027ee:	c935                	beqz	a0,80002862 <allocproc+0xda>
  p->pagetable = proc_pagetable(p);
    800027f0:	8526                	mv	a0,s1
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	1d0080e7          	jalr	464(ra) # 800019c2 <proc_pagetable>
    800027fa:	8a2a                	mv	s4,a0
    800027fc:	18800793          	li	a5,392
    80002800:	02f90733          	mul	a4,s2,a5
    80002804:	0000f797          	auipc	a5,0xf
    80002808:	05478793          	addi	a5,a5,84 # 80011858 <proc>
    8000280c:	97ba                	add	a5,a5,a4
    8000280e:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    80002810:	c52d                	beqz	a0,8000287a <allocproc+0xf2>
  memset(&p->context, 0, sizeof(p->context));
    80002812:	08098513          	addi	a0,s3,128
    80002816:	0000fa17          	auipc	s4,0xf
    8000281a:	042a0a13          	addi	s4,s4,66 # 80011858 <proc>
    8000281e:	07000613          	li	a2,112
    80002822:	4581                	li	a1,0
    80002824:	9552                	add	a0,a0,s4
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	4ba080e7          	jalr	1210(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000282e:	18800513          	li	a0,392
    80002832:	02a90933          	mul	s2,s2,a0
    80002836:	9952                	add	s2,s2,s4
    80002838:	fffff797          	auipc	a5,0xfffff
    8000283c:	10c78793          	addi	a5,a5,268 # 80001944 <forkret>
    80002840:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002844:	06093783          	ld	a5,96(s2)
    80002848:	6705                	lui	a4,0x1
    8000284a:	97ba                	add	a5,a5,a4
    8000284c:	08f93423          	sd	a5,136(s2)
}
    80002850:	8526                	mv	a0,s1
    80002852:	70a2                	ld	ra,40(sp)
    80002854:	7402                	ld	s0,32(sp)
    80002856:	64e2                	ld	s1,24(sp)
    80002858:	6942                	ld	s2,16(sp)
    8000285a:	69a2                	ld	s3,8(sp)
    8000285c:	6a02                	ld	s4,0(sp)
    8000285e:	6145                	addi	sp,sp,48
    80002860:	8082                	ret
    freeproc(p);
    80002862:	8526                	mv	a0,s1
    80002864:	00000097          	auipc	ra,0x0
    80002868:	984080e7          	jalr	-1660(ra) # 800021e8 <freeproc>
    release(&p->lock);
    8000286c:	8526                	mv	a0,s1
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	42a080e7          	jalr	1066(ra) # 80000c98 <release>
    return 0;
    80002876:	84d2                	mv	s1,s4
    80002878:	bfe1                	j	80002850 <allocproc+0xc8>
    freeproc(p);
    8000287a:	8526                	mv	a0,s1
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	96c080e7          	jalr	-1684(ra) # 800021e8 <freeproc>
    release(&p->lock);
    80002884:	8526                	mv	a0,s1
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	412080e7          	jalr	1042(ra) # 80000c98 <release>
    return 0;
    8000288e:	84d2                	mv	s1,s4
    80002890:	b7c1                	j	80002850 <allocproc+0xc8>
      return 0;
    80002892:	4481                	li	s1,0
    80002894:	bf75                	j	80002850 <allocproc+0xc8>

0000000080002896 <userinit>:
{
    80002896:	1101                	addi	sp,sp,-32
    80002898:	ec06                	sd	ra,24(sp)
    8000289a:	e822                	sd	s0,16(sp)
    8000289c:	e426                	sd	s1,8(sp)
    8000289e:	1000                	addi	s0,sp,32
  p = allocproc();
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	ee8080e7          	jalr	-280(ra) # 80002788 <allocproc>
    800028a8:	84aa                	mv	s1,a0
  initproc = p;
    800028aa:	00006797          	auipc	a5,0x6
    800028ae:	78a7b323          	sd	a0,1926(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800028b2:	03400613          	li	a2,52
    800028b6:	00006597          	auipc	a1,0x6
    800028ba:	f8a58593          	addi	a1,a1,-118 # 80008840 <initcode>
    800028be:	7928                	ld	a0,112(a0)
    800028c0:	fffff097          	auipc	ra,0xfffff
    800028c4:	aa8080e7          	jalr	-1368(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800028c8:	6785                	lui	a5,0x1
    800028ca:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    800028cc:	7cb8                	ld	a4,120(s1)
    800028ce:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800028d2:	7cb8                	ld	a4,120(s1)
    800028d4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800028d6:	4641                	li	a2,16
    800028d8:	00006597          	auipc	a1,0x6
    800028dc:	9a858593          	addi	a1,a1,-1624 # 80008280 <digits+0x240>
    800028e0:	17848513          	addi	a0,s1,376
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	54e080e7          	jalr	1358(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800028ec:	00006517          	auipc	a0,0x6
    800028f0:	9a450513          	addi	a0,a0,-1628 # 80008290 <digits+0x250>
    800028f4:	00002097          	auipc	ra,0x2
    800028f8:	afa080e7          	jalr	-1286(ra) # 800043ee <namei>
    800028fc:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80002900:	478d                	li	a5,3
    80002902:	cc9c                	sw	a5,24(s1)
  add_to_list(&cpus[0].runnable_head, p, &cpus[0].lock_runnable_list);
    80002904:	0000f617          	auipc	a2,0xf
    80002908:	a2460613          	addi	a2,a2,-1500 # 80011328 <cpus+0x88>
    8000290c:	85a6                	mv	a1,s1
    8000290e:	0000f517          	auipc	a0,0xf
    80002912:	a1250513          	addi	a0,a0,-1518 # 80011320 <cpus+0x80>
    80002916:	fffff097          	auipc	ra,0xfffff
    8000291a:	484080e7          	jalr	1156(ra) # 80001d9a <add_to_list>
  release(&p->lock);
    8000291e:	8526                	mv	a0,s1
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	378080e7          	jalr	888(ra) # 80000c98 <release>
}
    80002928:	60e2                	ld	ra,24(sp)
    8000292a:	6442                	ld	s0,16(sp)
    8000292c:	64a2                	ld	s1,8(sp)
    8000292e:	6105                	addi	sp,sp,32
    80002930:	8082                	ret

0000000080002932 <fork>:
{
    80002932:	7179                	addi	sp,sp,-48
    80002934:	f406                	sd	ra,40(sp)
    80002936:	f022                	sd	s0,32(sp)
    80002938:	ec26                	sd	s1,24(sp)
    8000293a:	e84a                	sd	s2,16(sp)
    8000293c:	e44e                	sd	s3,8(sp)
    8000293e:	e052                	sd	s4,0(sp)
    80002940:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	fc4080e7          	jalr	-60(ra) # 80001906 <myproc>
    8000294a:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	e3c080e7          	jalr	-452(ra) # 80002788 <allocproc>
    80002954:	18050063          	beqz	a0,80002ad4 <fork+0x1a2>
    80002958:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000295a:	0689b603          	ld	a2,104(s3)
    8000295e:	792c                	ld	a1,112(a0)
    80002960:	0709b503          	ld	a0,112(s3)
    80002964:	fffff097          	auipc	ra,0xfffff
    80002968:	c0a080e7          	jalr	-1014(ra) # 8000156e <uvmcopy>
    8000296c:	04054663          	bltz	a0,800029b8 <fork+0x86>
  np->sz = p->sz;
    80002970:	0689b783          	ld	a5,104(s3)
    80002974:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    80002978:	0789b683          	ld	a3,120(s3)
    8000297c:	87b6                	mv	a5,a3
    8000297e:	07893703          	ld	a4,120(s2)
    80002982:	12068693          	addi	a3,a3,288
    80002986:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000298a:	6788                	ld	a0,8(a5)
    8000298c:	6b8c                	ld	a1,16(a5)
    8000298e:	6f90                	ld	a2,24(a5)
    80002990:	01073023          	sd	a6,0(a4)
    80002994:	e708                	sd	a0,8(a4)
    80002996:	eb0c                	sd	a1,16(a4)
    80002998:	ef10                	sd	a2,24(a4)
    8000299a:	02078793          	addi	a5,a5,32
    8000299e:	02070713          	addi	a4,a4,32
    800029a2:	fed792e3          	bne	a5,a3,80002986 <fork+0x54>
  np->trapframe->a0 = 0;
    800029a6:	07893783          	ld	a5,120(s2)
    800029aa:	0607b823          	sd	zero,112(a5)
    800029ae:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    800029b2:	17000a13          	li	s4,368
    800029b6:	a03d                	j	800029e4 <fork+0xb2>
    freeproc(np);
    800029b8:	854a                	mv	a0,s2
    800029ba:	00000097          	auipc	ra,0x0
    800029be:	82e080e7          	jalr	-2002(ra) # 800021e8 <freeproc>
    release(&np->lock);
    800029c2:	854a                	mv	a0,s2
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	2d4080e7          	jalr	724(ra) # 80000c98 <release>
    return -1;
    800029cc:	5a7d                	li	s4,-1
    800029ce:	a0ed                	j	80002ab8 <fork+0x186>
      np->ofile[i] = filedup(p->ofile[i]);
    800029d0:	00002097          	auipc	ra,0x2
    800029d4:	0b4080e7          	jalr	180(ra) # 80004a84 <filedup>
    800029d8:	009907b3          	add	a5,s2,s1
    800029dc:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800029de:	04a1                	addi	s1,s1,8
    800029e0:	01448763          	beq	s1,s4,800029ee <fork+0xbc>
    if(p->ofile[i])
    800029e4:	009987b3          	add	a5,s3,s1
    800029e8:	6388                	ld	a0,0(a5)
    800029ea:	f17d                	bnez	a0,800029d0 <fork+0x9e>
    800029ec:	bfcd                	j	800029de <fork+0xac>
  np->cwd = idup(p->cwd);
    800029ee:	1709b503          	ld	a0,368(s3)
    800029f2:	00001097          	auipc	ra,0x1
    800029f6:	208080e7          	jalr	520(ra) # 80003bfa <idup>
    800029fa:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800029fe:	4641                	li	a2,16
    80002a00:	17898593          	addi	a1,s3,376
    80002a04:	17890513          	addi	a0,s2,376
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	42a080e7          	jalr	1066(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002a10:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    80002a14:	854a                	mv	a0,s2
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	282080e7          	jalr	642(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002a1e:	0000f517          	auipc	a0,0xf
    80002a22:	dda50513          	addi	a0,a0,-550 # 800117f8 <wait_lock>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	1be080e7          	jalr	446(ra) # 80000be4 <acquire>
  np->parent = p;
    80002a2e:	05393c23          	sd	s3,88(s2)
  if(auto_balanced){
    80002a32:	00006797          	auipc	a5,0x6
    80002a36:	5f67a783          	lw	a5,1526(a5) # 80009028 <auto_balanced>
    80002a3a:	cbc1                	beqz	a5,80002aca <fork+0x198>
    np->cpu_num = cpu_num;
    80002a3c:	02092a23          	sw	zero,52(s2)
    while(cas(&c->counter, c->counter, c->counter + 1) != 0);
    80002a40:	0000f997          	auipc	s3,0xf
    80002a44:	86098993          	addi	s3,s3,-1952 # 800112a0 <cpus>
    80002a48:	0000f497          	auipc	s1,0xf
    80002a4c:	8f848493          	addi	s1,s1,-1800 # 80011340 <cpus+0xa0>
    80002a50:	0a09a583          	lw	a1,160(s3)
    80002a54:	0015861b          	addiw	a2,a1,1
    80002a58:	8526                	mv	a0,s1
    80002a5a:	00004097          	auipc	ra,0x4
    80002a5e:	d6c080e7          	jalr	-660(ra) # 800067c6 <cas>
    80002a62:	f57d                	bnez	a0,80002a50 <fork+0x11e>
  release(&wait_lock);
    80002a64:	0000f497          	auipc	s1,0xf
    80002a68:	83c48493          	addi	s1,s1,-1988 # 800112a0 <cpus>
    80002a6c:	0000f517          	auipc	a0,0xf
    80002a70:	d8c50513          	addi	a0,a0,-628 # 800117f8 <wait_lock>
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	224080e7          	jalr	548(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002a7c:	854a                	mv	a0,s2
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	166080e7          	jalr	358(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002a86:	478d                	li	a5,3
    80002a88:	00f92c23          	sw	a5,24(s2)
  add_to_list(&c->runnable_head, np, &c->lock_runnable_list);
    80002a8c:	03492503          	lw	a0,52(s2)
    80002a90:	0a800793          	li	a5,168
    80002a94:	02f50533          	mul	a0,a0,a5
    80002a98:	08850613          	addi	a2,a0,136
    80002a9c:	08050513          	addi	a0,a0,128
    80002aa0:	9626                	add	a2,a2,s1
    80002aa2:	85ca                	mv	a1,s2
    80002aa4:	9526                	add	a0,a0,s1
    80002aa6:	fffff097          	auipc	ra,0xfffff
    80002aaa:	2f4080e7          	jalr	756(ra) # 80001d9a <add_to_list>
  release(&np->lock);
    80002aae:	854a                	mv	a0,s2
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	1e8080e7          	jalr	488(ra) # 80000c98 <release>
}
    80002ab8:	8552                	mv	a0,s4
    80002aba:	70a2                	ld	ra,40(sp)
    80002abc:	7402                	ld	s0,32(sp)
    80002abe:	64e2                	ld	s1,24(sp)
    80002ac0:	6942                	ld	s2,16(sp)
    80002ac2:	69a2                	ld	s3,8(sp)
    80002ac4:	6a02                	ld	s4,0(sp)
    80002ac6:	6145                	addi	sp,sp,48
    80002ac8:	8082                	ret
    np->cpu_num = p->cpu_num;
    80002aca:	0349a783          	lw	a5,52(s3)
    80002ace:	02f92a23          	sw	a5,52(s2)
    80002ad2:	bf49                	j	80002a64 <fork+0x132>
    return -1;
    80002ad4:	5a7d                	li	s4,-1
    80002ad6:	b7cd                	j	80002ab8 <fork+0x186>

0000000080002ad8 <scheduler>:
{
    80002ad8:	711d                	addi	sp,sp,-96
    80002ada:	ec86                	sd	ra,88(sp)
    80002adc:	e8a2                	sd	s0,80(sp)
    80002ade:	e4a6                	sd	s1,72(sp)
    80002ae0:	e0ca                	sd	s2,64(sp)
    80002ae2:	fc4e                	sd	s3,56(sp)
    80002ae4:	f852                	sd	s4,48(sp)
    80002ae6:	f456                	sd	s5,40(sp)
    80002ae8:	f05a                	sd	s6,32(sp)
    80002aea:	ec5e                	sd	s7,24(sp)
    80002aec:	e862                	sd	s8,16(sp)
    80002aee:	e466                	sd	s9,8(sp)
    80002af0:	e06a                	sd	s10,0(sp)
    80002af2:	1080                	addi	s0,sp,96
    80002af4:	8712                	mv	a4,tp
  int id = r_tp();
    80002af6:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002af8:	0000eb97          	auipc	s7,0xe
    80002afc:	7a8b8b93          	addi	s7,s7,1960 # 800112a0 <cpus>
    80002b00:	0a800793          	li	a5,168
    80002b04:	02f707b3          	mul	a5,a4,a5
    80002b08:	00fb86b3          	add	a3,s7,a5
    80002b0c:	0006b023          	sd	zero,0(a3)
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002b10:	08078993          	addi	s3,a5,128
    80002b14:	99de                	add	s3,s3,s7
    80002b16:	08878913          	addi	s2,a5,136
    80002b1a:	995e                	add	s2,s2,s7
      swtch(&c->context, &p->context);
    80002b1c:	07a1                	addi	a5,a5,8
    80002b1e:	9bbe                	add	s7,s7,a5
    if(proc_num != -1){
    80002b20:	5a7d                	li	s4,-1
    80002b22:	18800c93          	li	s9,392
      p = &proc[proc_num];
    80002b26:	0000fb17          	auipc	s6,0xf
    80002b2a:	d32b0b13          	addi	s6,s6,-718 # 80011858 <proc>
      p->state = RUNNING;
    80002b2e:	4c11                	li	s8,4
      c->proc = p;
    80002b30:	8ab6                	mv	s5,a3
    80002b32:	a82d                	j	80002b6c <scheduler+0x94>
      p = &proc[proc_num];
    80002b34:	039504b3          	mul	s1,a0,s9
    80002b38:	01648d33          	add	s10,s1,s6
      acquire(&p->lock);
    80002b3c:	856a                	mv	a0,s10
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	0a6080e7          	jalr	166(ra) # 80000be4 <acquire>
      p->state = RUNNING;
    80002b46:	018d2c23          	sw	s8,24(s10)
      c->proc = p;
    80002b4a:	01aab023          	sd	s10,0(s5)
      swtch(&c->context, &p->context);
    80002b4e:	08048593          	addi	a1,s1,128
    80002b52:	95da                	add	a1,a1,s6
    80002b54:	855e                	mv	a0,s7
    80002b56:	00000097          	auipc	ra,0x0
    80002b5a:	034080e7          	jalr	52(ra) # 80002b8a <swtch>
      c->proc = 0;
    80002b5e:	000ab023          	sd	zero,0(s5)
      release(&p->lock);
    80002b62:	856a                	mv	a0,s10
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	134080e7          	jalr	308(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b70:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b74:	10079073          	csrw	sstatus,a5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002b78:	85ca                	mv	a1,s2
    80002b7a:	854e                	mv	a0,s3
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	b80080e7          	jalr	-1152(ra) # 800026fc <remove_first>
    if(proc_num != -1){
    80002b84:	ff4504e3          	beq	a0,s4,80002b6c <scheduler+0x94>
    80002b88:	b775                	j	80002b34 <scheduler+0x5c>

0000000080002b8a <swtch>:
    80002b8a:	00153023          	sd	ra,0(a0)
    80002b8e:	00253423          	sd	sp,8(a0)
    80002b92:	e900                	sd	s0,16(a0)
    80002b94:	ed04                	sd	s1,24(a0)
    80002b96:	03253023          	sd	s2,32(a0)
    80002b9a:	03353423          	sd	s3,40(a0)
    80002b9e:	03453823          	sd	s4,48(a0)
    80002ba2:	03553c23          	sd	s5,56(a0)
    80002ba6:	05653023          	sd	s6,64(a0)
    80002baa:	05753423          	sd	s7,72(a0)
    80002bae:	05853823          	sd	s8,80(a0)
    80002bb2:	05953c23          	sd	s9,88(a0)
    80002bb6:	07a53023          	sd	s10,96(a0)
    80002bba:	07b53423          	sd	s11,104(a0)
    80002bbe:	0005b083          	ld	ra,0(a1)
    80002bc2:	0085b103          	ld	sp,8(a1)
    80002bc6:	6980                	ld	s0,16(a1)
    80002bc8:	6d84                	ld	s1,24(a1)
    80002bca:	0205b903          	ld	s2,32(a1)
    80002bce:	0285b983          	ld	s3,40(a1)
    80002bd2:	0305ba03          	ld	s4,48(a1)
    80002bd6:	0385ba83          	ld	s5,56(a1)
    80002bda:	0405bb03          	ld	s6,64(a1)
    80002bde:	0485bb83          	ld	s7,72(a1)
    80002be2:	0505bc03          	ld	s8,80(a1)
    80002be6:	0585bc83          	ld	s9,88(a1)
    80002bea:	0605bd03          	ld	s10,96(a1)
    80002bee:	0685bd83          	ld	s11,104(a1)
    80002bf2:	8082                	ret

0000000080002bf4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bf4:	1141                	addi	sp,sp,-16
    80002bf6:	e406                	sd	ra,8(sp)
    80002bf8:	e022                	sd	s0,0(sp)
    80002bfa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bfc:	00005597          	auipc	a1,0x5
    80002c00:	6f458593          	addi	a1,a1,1780 # 800082f0 <states.1768+0x30>
    80002c04:	00015517          	auipc	a0,0x15
    80002c08:	e5450513          	addi	a0,a0,-428 # 80017a58 <tickslock>
    80002c0c:	ffffe097          	auipc	ra,0xffffe
    80002c10:	f48080e7          	jalr	-184(ra) # 80000b54 <initlock>
}
    80002c14:	60a2                	ld	ra,8(sp)
    80002c16:	6402                	ld	s0,0(sp)
    80002c18:	0141                	addi	sp,sp,16
    80002c1a:	8082                	ret

0000000080002c1c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c1c:	1141                	addi	sp,sp,-16
    80002c1e:	e422                	sd	s0,8(sp)
    80002c20:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c22:	00003797          	auipc	a5,0x3
    80002c26:	4ce78793          	addi	a5,a5,1230 # 800060f0 <kernelvec>
    80002c2a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c2e:	6422                	ld	s0,8(sp)
    80002c30:	0141                	addi	sp,sp,16
    80002c32:	8082                	ret

0000000080002c34 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c34:	1141                	addi	sp,sp,-16
    80002c36:	e406                	sd	ra,8(sp)
    80002c38:	e022                	sd	s0,0(sp)
    80002c3a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c3c:	fffff097          	auipc	ra,0xfffff
    80002c40:	cca080e7          	jalr	-822(ra) # 80001906 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c44:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c48:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c4a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c4e:	00004617          	auipc	a2,0x4
    80002c52:	3b260613          	addi	a2,a2,946 # 80007000 <_trampoline>
    80002c56:	00004697          	auipc	a3,0x4
    80002c5a:	3aa68693          	addi	a3,a3,938 # 80007000 <_trampoline>
    80002c5e:	8e91                	sub	a3,a3,a2
    80002c60:	040007b7          	lui	a5,0x4000
    80002c64:	17fd                	addi	a5,a5,-1
    80002c66:	07b2                	slli	a5,a5,0xc
    80002c68:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c6a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c6e:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c70:	180026f3          	csrr	a3,satp
    80002c74:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c76:	7d38                	ld	a4,120(a0)
    80002c78:	7134                	ld	a3,96(a0)
    80002c7a:	6585                	lui	a1,0x1
    80002c7c:	96ae                	add	a3,a3,a1
    80002c7e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c80:	7d38                	ld	a4,120(a0)
    80002c82:	00000697          	auipc	a3,0x0
    80002c86:	13868693          	addi	a3,a3,312 # 80002dba <usertrap>
    80002c8a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c8c:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c8e:	8692                	mv	a3,tp
    80002c90:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c92:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c96:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c9a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c9e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ca2:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ca4:	6f18                	ld	a4,24(a4)
    80002ca6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002caa:	792c                	ld	a1,112(a0)
    80002cac:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002cae:	00004717          	auipc	a4,0x4
    80002cb2:	3e270713          	addi	a4,a4,994 # 80007090 <userret>
    80002cb6:	8f11                	sub	a4,a4,a2
    80002cb8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002cba:	577d                	li	a4,-1
    80002cbc:	177e                	slli	a4,a4,0x3f
    80002cbe:	8dd9                	or	a1,a1,a4
    80002cc0:	02000537          	lui	a0,0x2000
    80002cc4:	157d                	addi	a0,a0,-1
    80002cc6:	0536                	slli	a0,a0,0xd
    80002cc8:	9782                	jalr	a5
}
    80002cca:	60a2                	ld	ra,8(sp)
    80002ccc:	6402                	ld	s0,0(sp)
    80002cce:	0141                	addi	sp,sp,16
    80002cd0:	8082                	ret

0000000080002cd2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002cd2:	1101                	addi	sp,sp,-32
    80002cd4:	ec06                	sd	ra,24(sp)
    80002cd6:	e822                	sd	s0,16(sp)
    80002cd8:	e426                	sd	s1,8(sp)
    80002cda:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cdc:	00015497          	auipc	s1,0x15
    80002ce0:	d7c48493          	addi	s1,s1,-644 # 80017a58 <tickslock>
    80002ce4:	8526                	mv	a0,s1
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	efe080e7          	jalr	-258(ra) # 80000be4 <acquire>
  ticks++;
    80002cee:	00006517          	auipc	a0,0x6
    80002cf2:	34a50513          	addi	a0,a0,842 # 80009038 <ticks>
    80002cf6:	411c                	lw	a5,0(a0)
    80002cf8:	2785                	addiw	a5,a5,1
    80002cfa:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	6a8080e7          	jalr	1704(ra) # 800023a4 <wakeup>
  release(&tickslock);
    80002d04:	8526                	mv	a0,s1
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	f92080e7          	jalr	-110(ra) # 80000c98 <release>
}
    80002d0e:	60e2                	ld	ra,24(sp)
    80002d10:	6442                	ld	s0,16(sp)
    80002d12:	64a2                	ld	s1,8(sp)
    80002d14:	6105                	addi	sp,sp,32
    80002d16:	8082                	ret

0000000080002d18 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	e426                	sd	s1,8(sp)
    80002d20:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d22:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d26:	00074d63          	bltz	a4,80002d40 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d2a:	57fd                	li	a5,-1
    80002d2c:	17fe                	slli	a5,a5,0x3f
    80002d2e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d30:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d32:	06f70363          	beq	a4,a5,80002d98 <devintr+0x80>
  }
}
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	64a2                	ld	s1,8(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret
     (scause & 0xff) == 9){
    80002d40:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d44:	46a5                	li	a3,9
    80002d46:	fed792e3          	bne	a5,a3,80002d2a <devintr+0x12>
    int irq = plic_claim();
    80002d4a:	00003097          	auipc	ra,0x3
    80002d4e:	4ae080e7          	jalr	1198(ra) # 800061f8 <plic_claim>
    80002d52:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d54:	47a9                	li	a5,10
    80002d56:	02f50763          	beq	a0,a5,80002d84 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d5a:	4785                	li	a5,1
    80002d5c:	02f50963          	beq	a0,a5,80002d8e <devintr+0x76>
    return 1;
    80002d60:	4505                	li	a0,1
    } else if(irq){
    80002d62:	d8f1                	beqz	s1,80002d36 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d64:	85a6                	mv	a1,s1
    80002d66:	00005517          	auipc	a0,0x5
    80002d6a:	59250513          	addi	a0,a0,1426 # 800082f8 <states.1768+0x38>
    80002d6e:	ffffe097          	auipc	ra,0xffffe
    80002d72:	81a080e7          	jalr	-2022(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d76:	8526                	mv	a0,s1
    80002d78:	00003097          	auipc	ra,0x3
    80002d7c:	4a4080e7          	jalr	1188(ra) # 8000621c <plic_complete>
    return 1;
    80002d80:	4505                	li	a0,1
    80002d82:	bf55                	j	80002d36 <devintr+0x1e>
      uartintr();
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	c24080e7          	jalr	-988(ra) # 800009a8 <uartintr>
    80002d8c:	b7ed                	j	80002d76 <devintr+0x5e>
      virtio_disk_intr();
    80002d8e:	00004097          	auipc	ra,0x4
    80002d92:	96e080e7          	jalr	-1682(ra) # 800066fc <virtio_disk_intr>
    80002d96:	b7c5                	j	80002d76 <devintr+0x5e>
    if(cpuid() == 0){
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	b3c080e7          	jalr	-1220(ra) # 800018d4 <cpuid>
    80002da0:	c901                	beqz	a0,80002db0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002da2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002da6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002da8:	14479073          	csrw	sip,a5
    return 2;
    80002dac:	4509                	li	a0,2
    80002dae:	b761                	j	80002d36 <devintr+0x1e>
      clockintr();
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	f22080e7          	jalr	-222(ra) # 80002cd2 <clockintr>
    80002db8:	b7ed                	j	80002da2 <devintr+0x8a>

0000000080002dba <usertrap>:
{
    80002dba:	1101                	addi	sp,sp,-32
    80002dbc:	ec06                	sd	ra,24(sp)
    80002dbe:	e822                	sd	s0,16(sp)
    80002dc0:	e426                	sd	s1,8(sp)
    80002dc2:	e04a                	sd	s2,0(sp)
    80002dc4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dc6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002dca:	1007f793          	andi	a5,a5,256
    80002dce:	e3ad                	bnez	a5,80002e30 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dd0:	00003797          	auipc	a5,0x3
    80002dd4:	32078793          	addi	a5,a5,800 # 800060f0 <kernelvec>
    80002dd8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	b2a080e7          	jalr	-1238(ra) # 80001906 <myproc>
    80002de4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002de6:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002de8:	14102773          	csrr	a4,sepc
    80002dec:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dee:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002df2:	47a1                	li	a5,8
    80002df4:	04f71c63          	bne	a4,a5,80002e4c <usertrap+0x92>
    if(p->killed)
    80002df8:	551c                	lw	a5,40(a0)
    80002dfa:	e3b9                	bnez	a5,80002e40 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002dfc:	7cb8                	ld	a4,120(s1)
    80002dfe:	6f1c                	ld	a5,24(a4)
    80002e00:	0791                	addi	a5,a5,4
    80002e02:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e0c:	10079073          	csrw	sstatus,a5
    syscall();
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	2e0080e7          	jalr	736(ra) # 800030f0 <syscall>
  if(p->killed)
    80002e18:	549c                	lw	a5,40(s1)
    80002e1a:	ebc1                	bnez	a5,80002eaa <usertrap+0xf0>
  usertrapret();
    80002e1c:	00000097          	auipc	ra,0x0
    80002e20:	e18080e7          	jalr	-488(ra) # 80002c34 <usertrapret>
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6902                	ld	s2,0(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret
    panic("usertrap: not from user mode");
    80002e30:	00005517          	auipc	a0,0x5
    80002e34:	4e850513          	addi	a0,a0,1256 # 80008318 <states.1768+0x58>
    80002e38:	ffffd097          	auipc	ra,0xffffd
    80002e3c:	706080e7          	jalr	1798(ra) # 8000053e <panic>
      exit(-1);
    80002e40:	557d                	li	a0,-1
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	710080e7          	jalr	1808(ra) # 80002552 <exit>
    80002e4a:	bf4d                	j	80002dfc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	ecc080e7          	jalr	-308(ra) # 80002d18 <devintr>
    80002e54:	892a                	mv	s2,a0
    80002e56:	c501                	beqz	a0,80002e5e <usertrap+0xa4>
  if(p->killed)
    80002e58:	549c                	lw	a5,40(s1)
    80002e5a:	c3a1                	beqz	a5,80002e9a <usertrap+0xe0>
    80002e5c:	a815                	j	80002e90 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e5e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e62:	5890                	lw	a2,48(s1)
    80002e64:	00005517          	auipc	a0,0x5
    80002e68:	4d450513          	addi	a0,a0,1236 # 80008338 <states.1768+0x78>
    80002e6c:	ffffd097          	auipc	ra,0xffffd
    80002e70:	71c080e7          	jalr	1820(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e74:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e78:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e7c:	00005517          	auipc	a0,0x5
    80002e80:	4ec50513          	addi	a0,a0,1260 # 80008368 <states.1768+0xa8>
    80002e84:	ffffd097          	auipc	ra,0xffffd
    80002e88:	704080e7          	jalr	1796(ra) # 80000588 <printf>
    p->killed = 1;
    80002e8c:	4785                	li	a5,1
    80002e8e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e90:	557d                	li	a0,-1
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	6c0080e7          	jalr	1728(ra) # 80002552 <exit>
  if(which_dev == 2)
    80002e9a:	4789                	li	a5,2
    80002e9c:	f8f910e3          	bne	s2,a5,80002e1c <usertrap+0x62>
    yield();
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	0e2080e7          	jalr	226(ra) # 80001f82 <yield>
    80002ea8:	bf95                	j	80002e1c <usertrap+0x62>
  int which_dev = 0;
    80002eaa:	4901                	li	s2,0
    80002eac:	b7d5                	j	80002e90 <usertrap+0xd6>

0000000080002eae <kerneltrap>:
{
    80002eae:	7179                	addi	sp,sp,-48
    80002eb0:	f406                	sd	ra,40(sp)
    80002eb2:	f022                	sd	s0,32(sp)
    80002eb4:	ec26                	sd	s1,24(sp)
    80002eb6:	e84a                	sd	s2,16(sp)
    80002eb8:	e44e                	sd	s3,8(sp)
    80002eba:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ebc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ec0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ec4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ec8:	1004f793          	andi	a5,s1,256
    80002ecc:	cb85                	beqz	a5,80002efc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ece:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ed2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ed4:	ef85                	bnez	a5,80002f0c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	e42080e7          	jalr	-446(ra) # 80002d18 <devintr>
    80002ede:	cd1d                	beqz	a0,80002f1c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ee0:	4789                	li	a5,2
    80002ee2:	06f50a63          	beq	a0,a5,80002f56 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ee6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eea:	10049073          	csrw	sstatus,s1
}
    80002eee:	70a2                	ld	ra,40(sp)
    80002ef0:	7402                	ld	s0,32(sp)
    80002ef2:	64e2                	ld	s1,24(sp)
    80002ef4:	6942                	ld	s2,16(sp)
    80002ef6:	69a2                	ld	s3,8(sp)
    80002ef8:	6145                	addi	sp,sp,48
    80002efa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002efc:	00005517          	auipc	a0,0x5
    80002f00:	48c50513          	addi	a0,a0,1164 # 80008388 <states.1768+0xc8>
    80002f04:	ffffd097          	auipc	ra,0xffffd
    80002f08:	63a080e7          	jalr	1594(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f0c:	00005517          	auipc	a0,0x5
    80002f10:	4a450513          	addi	a0,a0,1188 # 800083b0 <states.1768+0xf0>
    80002f14:	ffffd097          	auipc	ra,0xffffd
    80002f18:	62a080e7          	jalr	1578(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f1c:	85ce                	mv	a1,s3
    80002f1e:	00005517          	auipc	a0,0x5
    80002f22:	4b250513          	addi	a0,a0,1202 # 800083d0 <states.1768+0x110>
    80002f26:	ffffd097          	auipc	ra,0xffffd
    80002f2a:	662080e7          	jalr	1634(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f2e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f32:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f36:	00005517          	auipc	a0,0x5
    80002f3a:	4aa50513          	addi	a0,a0,1194 # 800083e0 <states.1768+0x120>
    80002f3e:	ffffd097          	auipc	ra,0xffffd
    80002f42:	64a080e7          	jalr	1610(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f46:	00005517          	auipc	a0,0x5
    80002f4a:	4b250513          	addi	a0,a0,1202 # 800083f8 <states.1768+0x138>
    80002f4e:	ffffd097          	auipc	ra,0xffffd
    80002f52:	5f0080e7          	jalr	1520(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	9b0080e7          	jalr	-1616(ra) # 80001906 <myproc>
    80002f5e:	d541                	beqz	a0,80002ee6 <kerneltrap+0x38>
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	9a6080e7          	jalr	-1626(ra) # 80001906 <myproc>
    80002f68:	4d18                	lw	a4,24(a0)
    80002f6a:	4791                	li	a5,4
    80002f6c:	f6f71de3          	bne	a4,a5,80002ee6 <kerneltrap+0x38>
    yield();
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	012080e7          	jalr	18(ra) # 80001f82 <yield>
    80002f78:	b7bd                	j	80002ee6 <kerneltrap+0x38>

0000000080002f7a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	e426                	sd	s1,8(sp)
    80002f82:	1000                	addi	s0,sp,32
    80002f84:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	980080e7          	jalr	-1664(ra) # 80001906 <myproc>
  switch (n) {
    80002f8e:	4795                	li	a5,5
    80002f90:	0497e163          	bltu	a5,s1,80002fd2 <argraw+0x58>
    80002f94:	048a                	slli	s1,s1,0x2
    80002f96:	00005717          	auipc	a4,0x5
    80002f9a:	49a70713          	addi	a4,a4,1178 # 80008430 <states.1768+0x170>
    80002f9e:	94ba                	add	s1,s1,a4
    80002fa0:	409c                	lw	a5,0(s1)
    80002fa2:	97ba                	add	a5,a5,a4
    80002fa4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fa6:	7d3c                	ld	a5,120(a0)
    80002fa8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002faa:	60e2                	ld	ra,24(sp)
    80002fac:	6442                	ld	s0,16(sp)
    80002fae:	64a2                	ld	s1,8(sp)
    80002fb0:	6105                	addi	sp,sp,32
    80002fb2:	8082                	ret
    return p->trapframe->a1;
    80002fb4:	7d3c                	ld	a5,120(a0)
    80002fb6:	7fa8                	ld	a0,120(a5)
    80002fb8:	bfcd                	j	80002faa <argraw+0x30>
    return p->trapframe->a2;
    80002fba:	7d3c                	ld	a5,120(a0)
    80002fbc:	63c8                	ld	a0,128(a5)
    80002fbe:	b7f5                	j	80002faa <argraw+0x30>
    return p->trapframe->a3;
    80002fc0:	7d3c                	ld	a5,120(a0)
    80002fc2:	67c8                	ld	a0,136(a5)
    80002fc4:	b7dd                	j	80002faa <argraw+0x30>
    return p->trapframe->a4;
    80002fc6:	7d3c                	ld	a5,120(a0)
    80002fc8:	6bc8                	ld	a0,144(a5)
    80002fca:	b7c5                	j	80002faa <argraw+0x30>
    return p->trapframe->a5;
    80002fcc:	7d3c                	ld	a5,120(a0)
    80002fce:	6fc8                	ld	a0,152(a5)
    80002fd0:	bfe9                	j	80002faa <argraw+0x30>
  panic("argraw");
    80002fd2:	00005517          	auipc	a0,0x5
    80002fd6:	43650513          	addi	a0,a0,1078 # 80008408 <states.1768+0x148>
    80002fda:	ffffd097          	auipc	ra,0xffffd
    80002fde:	564080e7          	jalr	1380(ra) # 8000053e <panic>

0000000080002fe2 <fetchaddr>:
{
    80002fe2:	1101                	addi	sp,sp,-32
    80002fe4:	ec06                	sd	ra,24(sp)
    80002fe6:	e822                	sd	s0,16(sp)
    80002fe8:	e426                	sd	s1,8(sp)
    80002fea:	e04a                	sd	s2,0(sp)
    80002fec:	1000                	addi	s0,sp,32
    80002fee:	84aa                	mv	s1,a0
    80002ff0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ff2:	fffff097          	auipc	ra,0xfffff
    80002ff6:	914080e7          	jalr	-1772(ra) # 80001906 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ffa:	753c                	ld	a5,104(a0)
    80002ffc:	02f4f863          	bgeu	s1,a5,8000302c <fetchaddr+0x4a>
    80003000:	00848713          	addi	a4,s1,8
    80003004:	02e7e663          	bltu	a5,a4,80003030 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003008:	46a1                	li	a3,8
    8000300a:	8626                	mv	a2,s1
    8000300c:	85ca                	mv	a1,s2
    8000300e:	7928                	ld	a0,112(a0)
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	6ee080e7          	jalr	1774(ra) # 800016fe <copyin>
    80003018:	00a03533          	snez	a0,a0
    8000301c:	40a00533          	neg	a0,a0
}
    80003020:	60e2                	ld	ra,24(sp)
    80003022:	6442                	ld	s0,16(sp)
    80003024:	64a2                	ld	s1,8(sp)
    80003026:	6902                	ld	s2,0(sp)
    80003028:	6105                	addi	sp,sp,32
    8000302a:	8082                	ret
    return -1;
    8000302c:	557d                	li	a0,-1
    8000302e:	bfcd                	j	80003020 <fetchaddr+0x3e>
    80003030:	557d                	li	a0,-1
    80003032:	b7fd                	j	80003020 <fetchaddr+0x3e>

0000000080003034 <fetchstr>:
{
    80003034:	7179                	addi	sp,sp,-48
    80003036:	f406                	sd	ra,40(sp)
    80003038:	f022                	sd	s0,32(sp)
    8000303a:	ec26                	sd	s1,24(sp)
    8000303c:	e84a                	sd	s2,16(sp)
    8000303e:	e44e                	sd	s3,8(sp)
    80003040:	1800                	addi	s0,sp,48
    80003042:	892a                	mv	s2,a0
    80003044:	84ae                	mv	s1,a1
    80003046:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	8be080e7          	jalr	-1858(ra) # 80001906 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003050:	86ce                	mv	a3,s3
    80003052:	864a                	mv	a2,s2
    80003054:	85a6                	mv	a1,s1
    80003056:	7928                	ld	a0,112(a0)
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	732080e7          	jalr	1842(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003060:	00054763          	bltz	a0,8000306e <fetchstr+0x3a>
  return strlen(buf);
    80003064:	8526                	mv	a0,s1
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	dfe080e7          	jalr	-514(ra) # 80000e64 <strlen>
}
    8000306e:	70a2                	ld	ra,40(sp)
    80003070:	7402                	ld	s0,32(sp)
    80003072:	64e2                	ld	s1,24(sp)
    80003074:	6942                	ld	s2,16(sp)
    80003076:	69a2                	ld	s3,8(sp)
    80003078:	6145                	addi	sp,sp,48
    8000307a:	8082                	ret

000000008000307c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000307c:	1101                	addi	sp,sp,-32
    8000307e:	ec06                	sd	ra,24(sp)
    80003080:	e822                	sd	s0,16(sp)
    80003082:	e426                	sd	s1,8(sp)
    80003084:	1000                	addi	s0,sp,32
    80003086:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	ef2080e7          	jalr	-270(ra) # 80002f7a <argraw>
    80003090:	c088                	sw	a0,0(s1)
  return 0;
}
    80003092:	4501                	li	a0,0
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	64a2                	ld	s1,8(sp)
    8000309a:	6105                	addi	sp,sp,32
    8000309c:	8082                	ret

000000008000309e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000309e:	1101                	addi	sp,sp,-32
    800030a0:	ec06                	sd	ra,24(sp)
    800030a2:	e822                	sd	s0,16(sp)
    800030a4:	e426                	sd	s1,8(sp)
    800030a6:	1000                	addi	s0,sp,32
    800030a8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030aa:	00000097          	auipc	ra,0x0
    800030ae:	ed0080e7          	jalr	-304(ra) # 80002f7a <argraw>
    800030b2:	e088                	sd	a0,0(s1)
  return 0;
}
    800030b4:	4501                	li	a0,0
    800030b6:	60e2                	ld	ra,24(sp)
    800030b8:	6442                	ld	s0,16(sp)
    800030ba:	64a2                	ld	s1,8(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret

00000000800030c0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030c0:	1101                	addi	sp,sp,-32
    800030c2:	ec06                	sd	ra,24(sp)
    800030c4:	e822                	sd	s0,16(sp)
    800030c6:	e426                	sd	s1,8(sp)
    800030c8:	e04a                	sd	s2,0(sp)
    800030ca:	1000                	addi	s0,sp,32
    800030cc:	84ae                	mv	s1,a1
    800030ce:	8932                	mv	s2,a2
  *ip = argraw(n);
    800030d0:	00000097          	auipc	ra,0x0
    800030d4:	eaa080e7          	jalr	-342(ra) # 80002f7a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800030d8:	864a                	mv	a2,s2
    800030da:	85a6                	mv	a1,s1
    800030dc:	00000097          	auipc	ra,0x0
    800030e0:	f58080e7          	jalr	-168(ra) # 80003034 <fetchstr>
}
    800030e4:	60e2                	ld	ra,24(sp)
    800030e6:	6442                	ld	s0,16(sp)
    800030e8:	64a2                	ld	s1,8(sp)
    800030ea:	6902                	ld	s2,0(sp)
    800030ec:	6105                	addi	sp,sp,32
    800030ee:	8082                	ret

00000000800030f0 <syscall>:
[SYS_get_cpu] sys_get_cpu,
};

void
syscall(void)
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	e04a                	sd	s2,0(sp)
    800030fa:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030fc:	fffff097          	auipc	ra,0xfffff
    80003100:	80a080e7          	jalr	-2038(ra) # 80001906 <myproc>
    80003104:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003106:	07853903          	ld	s2,120(a0)
    8000310a:	0a893783          	ld	a5,168(s2)
    8000310e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003112:	37fd                	addiw	a5,a5,-1
    80003114:	4759                	li	a4,22
    80003116:	00f76f63          	bltu	a4,a5,80003134 <syscall+0x44>
    8000311a:	00369713          	slli	a4,a3,0x3
    8000311e:	00005797          	auipc	a5,0x5
    80003122:	32a78793          	addi	a5,a5,810 # 80008448 <syscalls>
    80003126:	97ba                	add	a5,a5,a4
    80003128:	639c                	ld	a5,0(a5)
    8000312a:	c789                	beqz	a5,80003134 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000312c:	9782                	jalr	a5
    8000312e:	06a93823          	sd	a0,112(s2)
    80003132:	a839                	j	80003150 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003134:	17848613          	addi	a2,s1,376
    80003138:	588c                	lw	a1,48(s1)
    8000313a:	00005517          	auipc	a0,0x5
    8000313e:	2d650513          	addi	a0,a0,726 # 80008410 <states.1768+0x150>
    80003142:	ffffd097          	auipc	ra,0xffffd
    80003146:	446080e7          	jalr	1094(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000314a:	7cbc                	ld	a5,120(s1)
    8000314c:	577d                	li	a4,-1
    8000314e:	fbb8                	sd	a4,112(a5)
  }
}
    80003150:	60e2                	ld	ra,24(sp)
    80003152:	6442                	ld	s0,16(sp)
    80003154:	64a2                	ld	s1,8(sp)
    80003156:	6902                	ld	s2,0(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret

000000008000315c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003164:	fec40593          	addi	a1,s0,-20
    80003168:	4501                	li	a0,0
    8000316a:	00000097          	auipc	ra,0x0
    8000316e:	f12080e7          	jalr	-238(ra) # 8000307c <argint>
    return -1;
    80003172:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003174:	00054963          	bltz	a0,80003186 <sys_exit+0x2a>
  exit(n);
    80003178:	fec42503          	lw	a0,-20(s0)
    8000317c:	fffff097          	auipc	ra,0xfffff
    80003180:	3d6080e7          	jalr	982(ra) # 80002552 <exit>
  return 0;  // not reached
    80003184:	4781                	li	a5,0
}
    80003186:	853e                	mv	a0,a5
    80003188:	60e2                	ld	ra,24(sp)
    8000318a:	6442                	ld	s0,16(sp)
    8000318c:	6105                	addi	sp,sp,32
    8000318e:	8082                	ret

0000000080003190 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003190:	1141                	addi	sp,sp,-16
    80003192:	e406                	sd	ra,8(sp)
    80003194:	e022                	sd	s0,0(sp)
    80003196:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	76e080e7          	jalr	1902(ra) # 80001906 <myproc>
}
    800031a0:	5908                	lw	a0,48(a0)
    800031a2:	60a2                	ld	ra,8(sp)
    800031a4:	6402                	ld	s0,0(sp)
    800031a6:	0141                	addi	sp,sp,16
    800031a8:	8082                	ret

00000000800031aa <sys_fork>:

uint64
sys_fork(void)
{
    800031aa:	1141                	addi	sp,sp,-16
    800031ac:	e406                	sd	ra,8(sp)
    800031ae:	e022                	sd	s0,0(sp)
    800031b0:	0800                	addi	s0,sp,16
  return fork();
    800031b2:	fffff097          	auipc	ra,0xfffff
    800031b6:	780080e7          	jalr	1920(ra) # 80002932 <fork>
}
    800031ba:	60a2                	ld	ra,8(sp)
    800031bc:	6402                	ld	s0,0(sp)
    800031be:	0141                	addi	sp,sp,16
    800031c0:	8082                	ret

00000000800031c2 <sys_wait>:

uint64
sys_wait(void)
{
    800031c2:	1101                	addi	sp,sp,-32
    800031c4:	ec06                	sd	ra,24(sp)
    800031c6:	e822                	sd	s0,16(sp)
    800031c8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800031ca:	fe840593          	addi	a1,s0,-24
    800031ce:	4501                	li	a0,0
    800031d0:	00000097          	auipc	ra,0x0
    800031d4:	ece080e7          	jalr	-306(ra) # 8000309e <argaddr>
    800031d8:	87aa                	mv	a5,a0
    return -1;
    800031da:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800031dc:	0007c863          	bltz	a5,800031ec <sys_wait+0x2a>
  return wait(p);
    800031e0:	fe843503          	ld	a0,-24(s0)
    800031e4:	fffff097          	auipc	ra,0xfffff
    800031e8:	098080e7          	jalr	152(ra) # 8000227c <wait>
}
    800031ec:	60e2                	ld	ra,24(sp)
    800031ee:	6442                	ld	s0,16(sp)
    800031f0:	6105                	addi	sp,sp,32
    800031f2:	8082                	ret

00000000800031f4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031f4:	7179                	addi	sp,sp,-48
    800031f6:	f406                	sd	ra,40(sp)
    800031f8:	f022                	sd	s0,32(sp)
    800031fa:	ec26                	sd	s1,24(sp)
    800031fc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800031fe:	fdc40593          	addi	a1,s0,-36
    80003202:	4501                	li	a0,0
    80003204:	00000097          	auipc	ra,0x0
    80003208:	e78080e7          	jalr	-392(ra) # 8000307c <argint>
    8000320c:	87aa                	mv	a5,a0
    return -1;
    8000320e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003210:	0207c063          	bltz	a5,80003230 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	6f2080e7          	jalr	1778(ra) # 80001906 <myproc>
    8000321c:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    8000321e:	fdc42503          	lw	a0,-36(s0)
    80003222:	fffff097          	auipc	ra,0xfffff
    80003226:	88e080e7          	jalr	-1906(ra) # 80001ab0 <growproc>
    8000322a:	00054863          	bltz	a0,8000323a <sys_sbrk+0x46>
    return -1;
  return addr;
    8000322e:	8526                	mv	a0,s1
}
    80003230:	70a2                	ld	ra,40(sp)
    80003232:	7402                	ld	s0,32(sp)
    80003234:	64e2                	ld	s1,24(sp)
    80003236:	6145                	addi	sp,sp,48
    80003238:	8082                	ret
    return -1;
    8000323a:	557d                	li	a0,-1
    8000323c:	bfd5                	j	80003230 <sys_sbrk+0x3c>

000000008000323e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000323e:	7139                	addi	sp,sp,-64
    80003240:	fc06                	sd	ra,56(sp)
    80003242:	f822                	sd	s0,48(sp)
    80003244:	f426                	sd	s1,40(sp)
    80003246:	f04a                	sd	s2,32(sp)
    80003248:	ec4e                	sd	s3,24(sp)
    8000324a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000324c:	fcc40593          	addi	a1,s0,-52
    80003250:	4501                	li	a0,0
    80003252:	00000097          	auipc	ra,0x0
    80003256:	e2a080e7          	jalr	-470(ra) # 8000307c <argint>
    return -1;
    8000325a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000325c:	06054563          	bltz	a0,800032c6 <sys_sleep+0x88>
  acquire(&tickslock);
    80003260:	00014517          	auipc	a0,0x14
    80003264:	7f850513          	addi	a0,a0,2040 # 80017a58 <tickslock>
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	97c080e7          	jalr	-1668(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003270:	00006917          	auipc	s2,0x6
    80003274:	dc892903          	lw	s2,-568(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80003278:	fcc42783          	lw	a5,-52(s0)
    8000327c:	cf85                	beqz	a5,800032b4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000327e:	00014997          	auipc	s3,0x14
    80003282:	7da98993          	addi	s3,s3,2010 # 80017a58 <tickslock>
    80003286:	00006497          	auipc	s1,0x6
    8000328a:	db248493          	addi	s1,s1,-590 # 80009038 <ticks>
    if(myproc()->killed){
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	678080e7          	jalr	1656(ra) # 80001906 <myproc>
    80003296:	551c                	lw	a5,40(a0)
    80003298:	ef9d                	bnez	a5,800032d6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000329a:	85ce                	mv	a1,s3
    8000329c:	8526                	mv	a0,s1
    8000329e:	fffff097          	auipc	ra,0xfffff
    800032a2:	d86080e7          	jalr	-634(ra) # 80002024 <sleep>
  while(ticks - ticks0 < n){
    800032a6:	409c                	lw	a5,0(s1)
    800032a8:	412787bb          	subw	a5,a5,s2
    800032ac:	fcc42703          	lw	a4,-52(s0)
    800032b0:	fce7efe3          	bltu	a5,a4,8000328e <sys_sleep+0x50>
  }
  release(&tickslock);
    800032b4:	00014517          	auipc	a0,0x14
    800032b8:	7a450513          	addi	a0,a0,1956 # 80017a58 <tickslock>
    800032bc:	ffffe097          	auipc	ra,0xffffe
    800032c0:	9dc080e7          	jalr	-1572(ra) # 80000c98 <release>
  return 0;
    800032c4:	4781                	li	a5,0
}
    800032c6:	853e                	mv	a0,a5
    800032c8:	70e2                	ld	ra,56(sp)
    800032ca:	7442                	ld	s0,48(sp)
    800032cc:	74a2                	ld	s1,40(sp)
    800032ce:	7902                	ld	s2,32(sp)
    800032d0:	69e2                	ld	s3,24(sp)
    800032d2:	6121                	addi	sp,sp,64
    800032d4:	8082                	ret
      release(&tickslock);
    800032d6:	00014517          	auipc	a0,0x14
    800032da:	78250513          	addi	a0,a0,1922 # 80017a58 <tickslock>
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	9ba080e7          	jalr	-1606(ra) # 80000c98 <release>
      return -1;
    800032e6:	57fd                	li	a5,-1
    800032e8:	bff9                	j	800032c6 <sys_sleep+0x88>

00000000800032ea <sys_kill>:

uint64
sys_kill(void)
{
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800032f2:	fec40593          	addi	a1,s0,-20
    800032f6:	4501                	li	a0,0
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	d84080e7          	jalr	-636(ra) # 8000307c <argint>
    80003300:	87aa                	mv	a5,a0
    return -1;
    80003302:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003304:	0007c863          	bltz	a5,80003314 <sys_kill+0x2a>
  return kill(pid);
    80003308:	fec42503          	lw	a0,-20(s0)
    8000330c:	fffff097          	auipc	ra,0xfffff
    80003310:	336080e7          	jalr	822(ra) # 80002642 <kill>
}
    80003314:	60e2                	ld	ra,24(sp)
    80003316:	6442                	ld	s0,16(sp)
    80003318:	6105                	addi	sp,sp,32
    8000331a:	8082                	ret

000000008000331c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000331c:	1101                	addi	sp,sp,-32
    8000331e:	ec06                	sd	ra,24(sp)
    80003320:	e822                	sd	s0,16(sp)
    80003322:	e426                	sd	s1,8(sp)
    80003324:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003326:	00014517          	auipc	a0,0x14
    8000332a:	73250513          	addi	a0,a0,1842 # 80017a58 <tickslock>
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	8b6080e7          	jalr	-1866(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003336:	00006497          	auipc	s1,0x6
    8000333a:	d024a483          	lw	s1,-766(s1) # 80009038 <ticks>
  release(&tickslock);
    8000333e:	00014517          	auipc	a0,0x14
    80003342:	71a50513          	addi	a0,a0,1818 # 80017a58 <tickslock>
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	952080e7          	jalr	-1710(ra) # 80000c98 <release>
  return xticks;
}
    8000334e:	02049513          	slli	a0,s1,0x20
    80003352:	9101                	srli	a0,a0,0x20
    80003354:	60e2                	ld	ra,24(sp)
    80003356:	6442                	ld	s0,16(sp)
    80003358:	64a2                	ld	s1,8(sp)
    8000335a:	6105                	addi	sp,sp,32
    8000335c:	8082                	ret

000000008000335e <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    8000335e:	1101                	addi	sp,sp,-32
    80003360:	ec06                	sd	ra,24(sp)
    80003362:	e822                	sd	s0,16(sp)
    80003364:	1000                	addi	s0,sp,32
    int cpu_num;
    if(argint(0, &cpu_num) <= -1){
    80003366:	fec40593          	addi	a1,s0,-20
    8000336a:	4501                	li	a0,0
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	d10080e7          	jalr	-752(ra) # 8000307c <argint>
    80003374:	87aa                	mv	a5,a0
      return -1;
    80003376:	557d                	li	a0,-1
    if(argint(0, &cpu_num) <= -1){
    80003378:	0007c863          	bltz	a5,80003388 <sys_set_cpu+0x2a>
    }
    
    return set_cpu(cpu_num);
    8000337c:	fec42503          	lw	a0,-20(s0)
    80003380:	fffff097          	auipc	ra,0xfffff
    80003384:	c66080e7          	jalr	-922(ra) # 80001fe6 <set_cpu>
}
    80003388:	60e2                	ld	ra,24(sp)
    8000338a:	6442                	ld	s0,16(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret

0000000080003390 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003390:	1141                	addi	sp,sp,-16
    80003392:	e406                	sd	ra,8(sp)
    80003394:	e022                	sd	s0,0(sp)
    80003396:	0800                	addi	s0,sp,16
    return get_cpu();
    80003398:	fffff097          	auipc	ra,0xfffff
    8000339c:	9c8080e7          	jalr	-1592(ra) # 80001d60 <get_cpu>
    800033a0:	60a2                	ld	ra,8(sp)
    800033a2:	6402                	ld	s0,0(sp)
    800033a4:	0141                	addi	sp,sp,16
    800033a6:	8082                	ret

00000000800033a8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033a8:	7179                	addi	sp,sp,-48
    800033aa:	f406                	sd	ra,40(sp)
    800033ac:	f022                	sd	s0,32(sp)
    800033ae:	ec26                	sd	s1,24(sp)
    800033b0:	e84a                	sd	s2,16(sp)
    800033b2:	e44e                	sd	s3,8(sp)
    800033b4:	e052                	sd	s4,0(sp)
    800033b6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033b8:	00005597          	auipc	a1,0x5
    800033bc:	15058593          	addi	a1,a1,336 # 80008508 <syscalls+0xc0>
    800033c0:	00014517          	auipc	a0,0x14
    800033c4:	6b050513          	addi	a0,a0,1712 # 80017a70 <bcache>
    800033c8:	ffffd097          	auipc	ra,0xffffd
    800033cc:	78c080e7          	jalr	1932(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033d0:	0001c797          	auipc	a5,0x1c
    800033d4:	6a078793          	addi	a5,a5,1696 # 8001fa70 <bcache+0x8000>
    800033d8:	0001d717          	auipc	a4,0x1d
    800033dc:	90070713          	addi	a4,a4,-1792 # 8001fcd8 <bcache+0x8268>
    800033e0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033e4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033e8:	00014497          	auipc	s1,0x14
    800033ec:	6a048493          	addi	s1,s1,1696 # 80017a88 <bcache+0x18>
    b->next = bcache.head.next;
    800033f0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033f2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033f4:	00005a17          	auipc	s4,0x5
    800033f8:	11ca0a13          	addi	s4,s4,284 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    800033fc:	2b893783          	ld	a5,696(s2)
    80003400:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003402:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003406:	85d2                	mv	a1,s4
    80003408:	01048513          	addi	a0,s1,16
    8000340c:	00001097          	auipc	ra,0x1
    80003410:	4bc080e7          	jalr	1212(ra) # 800048c8 <initsleeplock>
    bcache.head.next->prev = b;
    80003414:	2b893783          	ld	a5,696(s2)
    80003418:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000341a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000341e:	45848493          	addi	s1,s1,1112
    80003422:	fd349de3          	bne	s1,s3,800033fc <binit+0x54>
  }
}
    80003426:	70a2                	ld	ra,40(sp)
    80003428:	7402                	ld	s0,32(sp)
    8000342a:	64e2                	ld	s1,24(sp)
    8000342c:	6942                	ld	s2,16(sp)
    8000342e:	69a2                	ld	s3,8(sp)
    80003430:	6a02                	ld	s4,0(sp)
    80003432:	6145                	addi	sp,sp,48
    80003434:	8082                	ret

0000000080003436 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003436:	7179                	addi	sp,sp,-48
    80003438:	f406                	sd	ra,40(sp)
    8000343a:	f022                	sd	s0,32(sp)
    8000343c:	ec26                	sd	s1,24(sp)
    8000343e:	e84a                	sd	s2,16(sp)
    80003440:	e44e                	sd	s3,8(sp)
    80003442:	1800                	addi	s0,sp,48
    80003444:	89aa                	mv	s3,a0
    80003446:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003448:	00014517          	auipc	a0,0x14
    8000344c:	62850513          	addi	a0,a0,1576 # 80017a70 <bcache>
    80003450:	ffffd097          	auipc	ra,0xffffd
    80003454:	794080e7          	jalr	1940(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003458:	0001d497          	auipc	s1,0x1d
    8000345c:	8d04b483          	ld	s1,-1840(s1) # 8001fd28 <bcache+0x82b8>
    80003460:	0001d797          	auipc	a5,0x1d
    80003464:	87878793          	addi	a5,a5,-1928 # 8001fcd8 <bcache+0x8268>
    80003468:	02f48f63          	beq	s1,a5,800034a6 <bread+0x70>
    8000346c:	873e                	mv	a4,a5
    8000346e:	a021                	j	80003476 <bread+0x40>
    80003470:	68a4                	ld	s1,80(s1)
    80003472:	02e48a63          	beq	s1,a4,800034a6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003476:	449c                	lw	a5,8(s1)
    80003478:	ff379ce3          	bne	a5,s3,80003470 <bread+0x3a>
    8000347c:	44dc                	lw	a5,12(s1)
    8000347e:	ff2799e3          	bne	a5,s2,80003470 <bread+0x3a>
      b->refcnt++;
    80003482:	40bc                	lw	a5,64(s1)
    80003484:	2785                	addiw	a5,a5,1
    80003486:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003488:	00014517          	auipc	a0,0x14
    8000348c:	5e850513          	addi	a0,a0,1512 # 80017a70 <bcache>
    80003490:	ffffe097          	auipc	ra,0xffffe
    80003494:	808080e7          	jalr	-2040(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003498:	01048513          	addi	a0,s1,16
    8000349c:	00001097          	auipc	ra,0x1
    800034a0:	466080e7          	jalr	1126(ra) # 80004902 <acquiresleep>
      return b;
    800034a4:	a8b9                	j	80003502 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034a6:	0001d497          	auipc	s1,0x1d
    800034aa:	87a4b483          	ld	s1,-1926(s1) # 8001fd20 <bcache+0x82b0>
    800034ae:	0001d797          	auipc	a5,0x1d
    800034b2:	82a78793          	addi	a5,a5,-2006 # 8001fcd8 <bcache+0x8268>
    800034b6:	00f48863          	beq	s1,a5,800034c6 <bread+0x90>
    800034ba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034bc:	40bc                	lw	a5,64(s1)
    800034be:	cf81                	beqz	a5,800034d6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034c0:	64a4                	ld	s1,72(s1)
    800034c2:	fee49de3          	bne	s1,a4,800034bc <bread+0x86>
  panic("bget: no buffers");
    800034c6:	00005517          	auipc	a0,0x5
    800034ca:	05250513          	addi	a0,a0,82 # 80008518 <syscalls+0xd0>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
      b->dev = dev;
    800034d6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800034da:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800034de:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034e2:	4785                	li	a5,1
    800034e4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034e6:	00014517          	auipc	a0,0x14
    800034ea:	58a50513          	addi	a0,a0,1418 # 80017a70 <bcache>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	7aa080e7          	jalr	1962(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034f6:	01048513          	addi	a0,s1,16
    800034fa:	00001097          	auipc	ra,0x1
    800034fe:	408080e7          	jalr	1032(ra) # 80004902 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003502:	409c                	lw	a5,0(s1)
    80003504:	cb89                	beqz	a5,80003516 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003506:	8526                	mv	a0,s1
    80003508:	70a2                	ld	ra,40(sp)
    8000350a:	7402                	ld	s0,32(sp)
    8000350c:	64e2                	ld	s1,24(sp)
    8000350e:	6942                	ld	s2,16(sp)
    80003510:	69a2                	ld	s3,8(sp)
    80003512:	6145                	addi	sp,sp,48
    80003514:	8082                	ret
    virtio_disk_rw(b, 0);
    80003516:	4581                	li	a1,0
    80003518:	8526                	mv	a0,s1
    8000351a:	00003097          	auipc	ra,0x3
    8000351e:	f0c080e7          	jalr	-244(ra) # 80006426 <virtio_disk_rw>
    b->valid = 1;
    80003522:	4785                	li	a5,1
    80003524:	c09c                	sw	a5,0(s1)
  return b;
    80003526:	b7c5                	j	80003506 <bread+0xd0>

0000000080003528 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003528:	1101                	addi	sp,sp,-32
    8000352a:	ec06                	sd	ra,24(sp)
    8000352c:	e822                	sd	s0,16(sp)
    8000352e:	e426                	sd	s1,8(sp)
    80003530:	1000                	addi	s0,sp,32
    80003532:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003534:	0541                	addi	a0,a0,16
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	466080e7          	jalr	1126(ra) # 8000499c <holdingsleep>
    8000353e:	cd01                	beqz	a0,80003556 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003540:	4585                	li	a1,1
    80003542:	8526                	mv	a0,s1
    80003544:	00003097          	auipc	ra,0x3
    80003548:	ee2080e7          	jalr	-286(ra) # 80006426 <virtio_disk_rw>
}
    8000354c:	60e2                	ld	ra,24(sp)
    8000354e:	6442                	ld	s0,16(sp)
    80003550:	64a2                	ld	s1,8(sp)
    80003552:	6105                	addi	sp,sp,32
    80003554:	8082                	ret
    panic("bwrite");
    80003556:	00005517          	auipc	a0,0x5
    8000355a:	fda50513          	addi	a0,a0,-38 # 80008530 <syscalls+0xe8>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	fe0080e7          	jalr	-32(ra) # 8000053e <panic>

0000000080003566 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003566:	1101                	addi	sp,sp,-32
    80003568:	ec06                	sd	ra,24(sp)
    8000356a:	e822                	sd	s0,16(sp)
    8000356c:	e426                	sd	s1,8(sp)
    8000356e:	e04a                	sd	s2,0(sp)
    80003570:	1000                	addi	s0,sp,32
    80003572:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003574:	01050913          	addi	s2,a0,16
    80003578:	854a                	mv	a0,s2
    8000357a:	00001097          	auipc	ra,0x1
    8000357e:	422080e7          	jalr	1058(ra) # 8000499c <holdingsleep>
    80003582:	c92d                	beqz	a0,800035f4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003584:	854a                	mv	a0,s2
    80003586:	00001097          	auipc	ra,0x1
    8000358a:	3d2080e7          	jalr	978(ra) # 80004958 <releasesleep>

  acquire(&bcache.lock);
    8000358e:	00014517          	auipc	a0,0x14
    80003592:	4e250513          	addi	a0,a0,1250 # 80017a70 <bcache>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	64e080e7          	jalr	1614(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000359e:	40bc                	lw	a5,64(s1)
    800035a0:	37fd                	addiw	a5,a5,-1
    800035a2:	0007871b          	sext.w	a4,a5
    800035a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035a8:	eb05                	bnez	a4,800035d8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035aa:	68bc                	ld	a5,80(s1)
    800035ac:	64b8                	ld	a4,72(s1)
    800035ae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035b0:	64bc                	ld	a5,72(s1)
    800035b2:	68b8                	ld	a4,80(s1)
    800035b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035b6:	0001c797          	auipc	a5,0x1c
    800035ba:	4ba78793          	addi	a5,a5,1210 # 8001fa70 <bcache+0x8000>
    800035be:	2b87b703          	ld	a4,696(a5)
    800035c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035c4:	0001c717          	auipc	a4,0x1c
    800035c8:	71470713          	addi	a4,a4,1812 # 8001fcd8 <bcache+0x8268>
    800035cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035ce:	2b87b703          	ld	a4,696(a5)
    800035d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035d8:	00014517          	auipc	a0,0x14
    800035dc:	49850513          	addi	a0,a0,1176 # 80017a70 <bcache>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	6b8080e7          	jalr	1720(ra) # 80000c98 <release>
}
    800035e8:	60e2                	ld	ra,24(sp)
    800035ea:	6442                	ld	s0,16(sp)
    800035ec:	64a2                	ld	s1,8(sp)
    800035ee:	6902                	ld	s2,0(sp)
    800035f0:	6105                	addi	sp,sp,32
    800035f2:	8082                	ret
    panic("brelse");
    800035f4:	00005517          	auipc	a0,0x5
    800035f8:	f4450513          	addi	a0,a0,-188 # 80008538 <syscalls+0xf0>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	f42080e7          	jalr	-190(ra) # 8000053e <panic>

0000000080003604 <bpin>:

void
bpin(struct buf *b) {
    80003604:	1101                	addi	sp,sp,-32
    80003606:	ec06                	sd	ra,24(sp)
    80003608:	e822                	sd	s0,16(sp)
    8000360a:	e426                	sd	s1,8(sp)
    8000360c:	1000                	addi	s0,sp,32
    8000360e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003610:	00014517          	auipc	a0,0x14
    80003614:	46050513          	addi	a0,a0,1120 # 80017a70 <bcache>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	5cc080e7          	jalr	1484(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003620:	40bc                	lw	a5,64(s1)
    80003622:	2785                	addiw	a5,a5,1
    80003624:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003626:	00014517          	auipc	a0,0x14
    8000362a:	44a50513          	addi	a0,a0,1098 # 80017a70 <bcache>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
}
    80003636:	60e2                	ld	ra,24(sp)
    80003638:	6442                	ld	s0,16(sp)
    8000363a:	64a2                	ld	s1,8(sp)
    8000363c:	6105                	addi	sp,sp,32
    8000363e:	8082                	ret

0000000080003640 <bunpin>:

void
bunpin(struct buf *b) {
    80003640:	1101                	addi	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	1000                	addi	s0,sp,32
    8000364a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000364c:	00014517          	auipc	a0,0x14
    80003650:	42450513          	addi	a0,a0,1060 # 80017a70 <bcache>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	590080e7          	jalr	1424(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000365c:	40bc                	lw	a5,64(s1)
    8000365e:	37fd                	addiw	a5,a5,-1
    80003660:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003662:	00014517          	auipc	a0,0x14
    80003666:	40e50513          	addi	a0,a0,1038 # 80017a70 <bcache>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	62e080e7          	jalr	1582(ra) # 80000c98 <release>
}
    80003672:	60e2                	ld	ra,24(sp)
    80003674:	6442                	ld	s0,16(sp)
    80003676:	64a2                	ld	s1,8(sp)
    80003678:	6105                	addi	sp,sp,32
    8000367a:	8082                	ret

000000008000367c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000367c:	1101                	addi	sp,sp,-32
    8000367e:	ec06                	sd	ra,24(sp)
    80003680:	e822                	sd	s0,16(sp)
    80003682:	e426                	sd	s1,8(sp)
    80003684:	e04a                	sd	s2,0(sp)
    80003686:	1000                	addi	s0,sp,32
    80003688:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000368a:	00d5d59b          	srliw	a1,a1,0xd
    8000368e:	0001d797          	auipc	a5,0x1d
    80003692:	abe7a783          	lw	a5,-1346(a5) # 8002014c <sb+0x1c>
    80003696:	9dbd                	addw	a1,a1,a5
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	d9e080e7          	jalr	-610(ra) # 80003436 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036a0:	0074f713          	andi	a4,s1,7
    800036a4:	4785                	li	a5,1
    800036a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036aa:	14ce                	slli	s1,s1,0x33
    800036ac:	90d9                	srli	s1,s1,0x36
    800036ae:	00950733          	add	a4,a0,s1
    800036b2:	05874703          	lbu	a4,88(a4)
    800036b6:	00e7f6b3          	and	a3,a5,a4
    800036ba:	c69d                	beqz	a3,800036e8 <bfree+0x6c>
    800036bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036be:	94aa                	add	s1,s1,a0
    800036c0:	fff7c793          	not	a5,a5
    800036c4:	8ff9                	and	a5,a5,a4
    800036c6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036ca:	00001097          	auipc	ra,0x1
    800036ce:	118080e7          	jalr	280(ra) # 800047e2 <log_write>
  brelse(bp);
    800036d2:	854a                	mv	a0,s2
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	e92080e7          	jalr	-366(ra) # 80003566 <brelse>
}
    800036dc:	60e2                	ld	ra,24(sp)
    800036de:	6442                	ld	s0,16(sp)
    800036e0:	64a2                	ld	s1,8(sp)
    800036e2:	6902                	ld	s2,0(sp)
    800036e4:	6105                	addi	sp,sp,32
    800036e6:	8082                	ret
    panic("freeing free block");
    800036e8:	00005517          	auipc	a0,0x5
    800036ec:	e5850513          	addi	a0,a0,-424 # 80008540 <syscalls+0xf8>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	e4e080e7          	jalr	-434(ra) # 8000053e <panic>

00000000800036f8 <balloc>:
{
    800036f8:	711d                	addi	sp,sp,-96
    800036fa:	ec86                	sd	ra,88(sp)
    800036fc:	e8a2                	sd	s0,80(sp)
    800036fe:	e4a6                	sd	s1,72(sp)
    80003700:	e0ca                	sd	s2,64(sp)
    80003702:	fc4e                	sd	s3,56(sp)
    80003704:	f852                	sd	s4,48(sp)
    80003706:	f456                	sd	s5,40(sp)
    80003708:	f05a                	sd	s6,32(sp)
    8000370a:	ec5e                	sd	s7,24(sp)
    8000370c:	e862                	sd	s8,16(sp)
    8000370e:	e466                	sd	s9,8(sp)
    80003710:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003712:	0001d797          	auipc	a5,0x1d
    80003716:	a227a783          	lw	a5,-1502(a5) # 80020134 <sb+0x4>
    8000371a:	cbd1                	beqz	a5,800037ae <balloc+0xb6>
    8000371c:	8baa                	mv	s7,a0
    8000371e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003720:	0001db17          	auipc	s6,0x1d
    80003724:	a10b0b13          	addi	s6,s6,-1520 # 80020130 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003728:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000372a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000372c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000372e:	6c89                	lui	s9,0x2
    80003730:	a831                	j	8000374c <balloc+0x54>
    brelse(bp);
    80003732:	854a                	mv	a0,s2
    80003734:	00000097          	auipc	ra,0x0
    80003738:	e32080e7          	jalr	-462(ra) # 80003566 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000373c:	015c87bb          	addw	a5,s9,s5
    80003740:	00078a9b          	sext.w	s5,a5
    80003744:	004b2703          	lw	a4,4(s6)
    80003748:	06eaf363          	bgeu	s5,a4,800037ae <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000374c:	41fad79b          	sraiw	a5,s5,0x1f
    80003750:	0137d79b          	srliw	a5,a5,0x13
    80003754:	015787bb          	addw	a5,a5,s5
    80003758:	40d7d79b          	sraiw	a5,a5,0xd
    8000375c:	01cb2583          	lw	a1,28(s6)
    80003760:	9dbd                	addw	a1,a1,a5
    80003762:	855e                	mv	a0,s7
    80003764:	00000097          	auipc	ra,0x0
    80003768:	cd2080e7          	jalr	-814(ra) # 80003436 <bread>
    8000376c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000376e:	004b2503          	lw	a0,4(s6)
    80003772:	000a849b          	sext.w	s1,s5
    80003776:	8662                	mv	a2,s8
    80003778:	faa4fde3          	bgeu	s1,a0,80003732 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000377c:	41f6579b          	sraiw	a5,a2,0x1f
    80003780:	01d7d69b          	srliw	a3,a5,0x1d
    80003784:	00c6873b          	addw	a4,a3,a2
    80003788:	00777793          	andi	a5,a4,7
    8000378c:	9f95                	subw	a5,a5,a3
    8000378e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003792:	4037571b          	sraiw	a4,a4,0x3
    80003796:	00e906b3          	add	a3,s2,a4
    8000379a:	0586c683          	lbu	a3,88(a3)
    8000379e:	00d7f5b3          	and	a1,a5,a3
    800037a2:	cd91                	beqz	a1,800037be <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037a4:	2605                	addiw	a2,a2,1
    800037a6:	2485                	addiw	s1,s1,1
    800037a8:	fd4618e3          	bne	a2,s4,80003778 <balloc+0x80>
    800037ac:	b759                	j	80003732 <balloc+0x3a>
  panic("balloc: out of blocks");
    800037ae:	00005517          	auipc	a0,0x5
    800037b2:	daa50513          	addi	a0,a0,-598 # 80008558 <syscalls+0x110>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	d88080e7          	jalr	-632(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037be:	974a                	add	a4,a4,s2
    800037c0:	8fd5                	or	a5,a5,a3
    800037c2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037c6:	854a                	mv	a0,s2
    800037c8:	00001097          	auipc	ra,0x1
    800037cc:	01a080e7          	jalr	26(ra) # 800047e2 <log_write>
        brelse(bp);
    800037d0:	854a                	mv	a0,s2
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	d94080e7          	jalr	-620(ra) # 80003566 <brelse>
  bp = bread(dev, bno);
    800037da:	85a6                	mv	a1,s1
    800037dc:	855e                	mv	a0,s7
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	c58080e7          	jalr	-936(ra) # 80003436 <bread>
    800037e6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037e8:	40000613          	li	a2,1024
    800037ec:	4581                	li	a1,0
    800037ee:	05850513          	addi	a0,a0,88
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	4ee080e7          	jalr	1262(ra) # 80000ce0 <memset>
  log_write(bp);
    800037fa:	854a                	mv	a0,s2
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	fe6080e7          	jalr	-26(ra) # 800047e2 <log_write>
  brelse(bp);
    80003804:	854a                	mv	a0,s2
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	d60080e7          	jalr	-672(ra) # 80003566 <brelse>
}
    8000380e:	8526                	mv	a0,s1
    80003810:	60e6                	ld	ra,88(sp)
    80003812:	6446                	ld	s0,80(sp)
    80003814:	64a6                	ld	s1,72(sp)
    80003816:	6906                	ld	s2,64(sp)
    80003818:	79e2                	ld	s3,56(sp)
    8000381a:	7a42                	ld	s4,48(sp)
    8000381c:	7aa2                	ld	s5,40(sp)
    8000381e:	7b02                	ld	s6,32(sp)
    80003820:	6be2                	ld	s7,24(sp)
    80003822:	6c42                	ld	s8,16(sp)
    80003824:	6ca2                	ld	s9,8(sp)
    80003826:	6125                	addi	sp,sp,96
    80003828:	8082                	ret

000000008000382a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000382a:	7179                	addi	sp,sp,-48
    8000382c:	f406                	sd	ra,40(sp)
    8000382e:	f022                	sd	s0,32(sp)
    80003830:	ec26                	sd	s1,24(sp)
    80003832:	e84a                	sd	s2,16(sp)
    80003834:	e44e                	sd	s3,8(sp)
    80003836:	e052                	sd	s4,0(sp)
    80003838:	1800                	addi	s0,sp,48
    8000383a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000383c:	47ad                	li	a5,11
    8000383e:	04b7fe63          	bgeu	a5,a1,8000389a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003842:	ff45849b          	addiw	s1,a1,-12
    80003846:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000384a:	0ff00793          	li	a5,255
    8000384e:	0ae7e363          	bltu	a5,a4,800038f4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003852:	08052583          	lw	a1,128(a0)
    80003856:	c5ad                	beqz	a1,800038c0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003858:	00092503          	lw	a0,0(s2)
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	bda080e7          	jalr	-1062(ra) # 80003436 <bread>
    80003864:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003866:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000386a:	02049593          	slli	a1,s1,0x20
    8000386e:	9181                	srli	a1,a1,0x20
    80003870:	058a                	slli	a1,a1,0x2
    80003872:	00b784b3          	add	s1,a5,a1
    80003876:	0004a983          	lw	s3,0(s1)
    8000387a:	04098d63          	beqz	s3,800038d4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000387e:	8552                	mv	a0,s4
    80003880:	00000097          	auipc	ra,0x0
    80003884:	ce6080e7          	jalr	-794(ra) # 80003566 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003888:	854e                	mv	a0,s3
    8000388a:	70a2                	ld	ra,40(sp)
    8000388c:	7402                	ld	s0,32(sp)
    8000388e:	64e2                	ld	s1,24(sp)
    80003890:	6942                	ld	s2,16(sp)
    80003892:	69a2                	ld	s3,8(sp)
    80003894:	6a02                	ld	s4,0(sp)
    80003896:	6145                	addi	sp,sp,48
    80003898:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000389a:	02059493          	slli	s1,a1,0x20
    8000389e:	9081                	srli	s1,s1,0x20
    800038a0:	048a                	slli	s1,s1,0x2
    800038a2:	94aa                	add	s1,s1,a0
    800038a4:	0504a983          	lw	s3,80(s1)
    800038a8:	fe0990e3          	bnez	s3,80003888 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800038ac:	4108                	lw	a0,0(a0)
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	e4a080e7          	jalr	-438(ra) # 800036f8 <balloc>
    800038b6:	0005099b          	sext.w	s3,a0
    800038ba:	0534a823          	sw	s3,80(s1)
    800038be:	b7e9                	j	80003888 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800038c0:	4108                	lw	a0,0(a0)
    800038c2:	00000097          	auipc	ra,0x0
    800038c6:	e36080e7          	jalr	-458(ra) # 800036f8 <balloc>
    800038ca:	0005059b          	sext.w	a1,a0
    800038ce:	08b92023          	sw	a1,128(s2)
    800038d2:	b759                	j	80003858 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038d4:	00092503          	lw	a0,0(s2)
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	e20080e7          	jalr	-480(ra) # 800036f8 <balloc>
    800038e0:	0005099b          	sext.w	s3,a0
    800038e4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038e8:	8552                	mv	a0,s4
    800038ea:	00001097          	auipc	ra,0x1
    800038ee:	ef8080e7          	jalr	-264(ra) # 800047e2 <log_write>
    800038f2:	b771                	j	8000387e <bmap+0x54>
  panic("bmap: out of range");
    800038f4:	00005517          	auipc	a0,0x5
    800038f8:	c7c50513          	addi	a0,a0,-900 # 80008570 <syscalls+0x128>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	c42080e7          	jalr	-958(ra) # 8000053e <panic>

0000000080003904 <iget>:
{
    80003904:	7179                	addi	sp,sp,-48
    80003906:	f406                	sd	ra,40(sp)
    80003908:	f022                	sd	s0,32(sp)
    8000390a:	ec26                	sd	s1,24(sp)
    8000390c:	e84a                	sd	s2,16(sp)
    8000390e:	e44e                	sd	s3,8(sp)
    80003910:	e052                	sd	s4,0(sp)
    80003912:	1800                	addi	s0,sp,48
    80003914:	89aa                	mv	s3,a0
    80003916:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003918:	0001d517          	auipc	a0,0x1d
    8000391c:	83850513          	addi	a0,a0,-1992 # 80020150 <itable>
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	2c4080e7          	jalr	708(ra) # 80000be4 <acquire>
  empty = 0;
    80003928:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000392a:	0001d497          	auipc	s1,0x1d
    8000392e:	83e48493          	addi	s1,s1,-1986 # 80020168 <itable+0x18>
    80003932:	0001e697          	auipc	a3,0x1e
    80003936:	2c668693          	addi	a3,a3,710 # 80021bf8 <log>
    8000393a:	a039                	j	80003948 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000393c:	02090b63          	beqz	s2,80003972 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003940:	08848493          	addi	s1,s1,136
    80003944:	02d48a63          	beq	s1,a3,80003978 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003948:	449c                	lw	a5,8(s1)
    8000394a:	fef059e3          	blez	a5,8000393c <iget+0x38>
    8000394e:	4098                	lw	a4,0(s1)
    80003950:	ff3716e3          	bne	a4,s3,8000393c <iget+0x38>
    80003954:	40d8                	lw	a4,4(s1)
    80003956:	ff4713e3          	bne	a4,s4,8000393c <iget+0x38>
      ip->ref++;
    8000395a:	2785                	addiw	a5,a5,1
    8000395c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000395e:	0001c517          	auipc	a0,0x1c
    80003962:	7f250513          	addi	a0,a0,2034 # 80020150 <itable>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	332080e7          	jalr	818(ra) # 80000c98 <release>
      return ip;
    8000396e:	8926                	mv	s2,s1
    80003970:	a03d                	j	8000399e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003972:	f7f9                	bnez	a5,80003940 <iget+0x3c>
    80003974:	8926                	mv	s2,s1
    80003976:	b7e9                	j	80003940 <iget+0x3c>
  if(empty == 0)
    80003978:	02090c63          	beqz	s2,800039b0 <iget+0xac>
  ip->dev = dev;
    8000397c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003980:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003984:	4785                	li	a5,1
    80003986:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000398a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000398e:	0001c517          	auipc	a0,0x1c
    80003992:	7c250513          	addi	a0,a0,1986 # 80020150 <itable>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	302080e7          	jalr	770(ra) # 80000c98 <release>
}
    8000399e:	854a                	mv	a0,s2
    800039a0:	70a2                	ld	ra,40(sp)
    800039a2:	7402                	ld	s0,32(sp)
    800039a4:	64e2                	ld	s1,24(sp)
    800039a6:	6942                	ld	s2,16(sp)
    800039a8:	69a2                	ld	s3,8(sp)
    800039aa:	6a02                	ld	s4,0(sp)
    800039ac:	6145                	addi	sp,sp,48
    800039ae:	8082                	ret
    panic("iget: no inodes");
    800039b0:	00005517          	auipc	a0,0x5
    800039b4:	bd850513          	addi	a0,a0,-1064 # 80008588 <syscalls+0x140>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	b86080e7          	jalr	-1146(ra) # 8000053e <panic>

00000000800039c0 <fsinit>:
fsinit(int dev) {
    800039c0:	7179                	addi	sp,sp,-48
    800039c2:	f406                	sd	ra,40(sp)
    800039c4:	f022                	sd	s0,32(sp)
    800039c6:	ec26                	sd	s1,24(sp)
    800039c8:	e84a                	sd	s2,16(sp)
    800039ca:	e44e                	sd	s3,8(sp)
    800039cc:	1800                	addi	s0,sp,48
    800039ce:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039d0:	4585                	li	a1,1
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	a64080e7          	jalr	-1436(ra) # 80003436 <bread>
    800039da:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039dc:	0001c997          	auipc	s3,0x1c
    800039e0:	75498993          	addi	s3,s3,1876 # 80020130 <sb>
    800039e4:	02000613          	li	a2,32
    800039e8:	05850593          	addi	a1,a0,88
    800039ec:	854e                	mv	a0,s3
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	352080e7          	jalr	850(ra) # 80000d40 <memmove>
  brelse(bp);
    800039f6:	8526                	mv	a0,s1
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	b6e080e7          	jalr	-1170(ra) # 80003566 <brelse>
  if(sb.magic != FSMAGIC)
    80003a00:	0009a703          	lw	a4,0(s3)
    80003a04:	102037b7          	lui	a5,0x10203
    80003a08:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a0c:	02f71263          	bne	a4,a5,80003a30 <fsinit+0x70>
  initlog(dev, &sb);
    80003a10:	0001c597          	auipc	a1,0x1c
    80003a14:	72058593          	addi	a1,a1,1824 # 80020130 <sb>
    80003a18:	854a                	mv	a0,s2
    80003a1a:	00001097          	auipc	ra,0x1
    80003a1e:	b4c080e7          	jalr	-1204(ra) # 80004566 <initlog>
}
    80003a22:	70a2                	ld	ra,40(sp)
    80003a24:	7402                	ld	s0,32(sp)
    80003a26:	64e2                	ld	s1,24(sp)
    80003a28:	6942                	ld	s2,16(sp)
    80003a2a:	69a2                	ld	s3,8(sp)
    80003a2c:	6145                	addi	sp,sp,48
    80003a2e:	8082                	ret
    panic("invalid file system");
    80003a30:	00005517          	auipc	a0,0x5
    80003a34:	b6850513          	addi	a0,a0,-1176 # 80008598 <syscalls+0x150>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	b06080e7          	jalr	-1274(ra) # 8000053e <panic>

0000000080003a40 <iinit>:
{
    80003a40:	7179                	addi	sp,sp,-48
    80003a42:	f406                	sd	ra,40(sp)
    80003a44:	f022                	sd	s0,32(sp)
    80003a46:	ec26                	sd	s1,24(sp)
    80003a48:	e84a                	sd	s2,16(sp)
    80003a4a:	e44e                	sd	s3,8(sp)
    80003a4c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a4e:	00005597          	auipc	a1,0x5
    80003a52:	b6258593          	addi	a1,a1,-1182 # 800085b0 <syscalls+0x168>
    80003a56:	0001c517          	auipc	a0,0x1c
    80003a5a:	6fa50513          	addi	a0,a0,1786 # 80020150 <itable>
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	0f6080e7          	jalr	246(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a66:	0001c497          	auipc	s1,0x1c
    80003a6a:	71248493          	addi	s1,s1,1810 # 80020178 <itable+0x28>
    80003a6e:	0001e997          	auipc	s3,0x1e
    80003a72:	19a98993          	addi	s3,s3,410 # 80021c08 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a76:	00005917          	auipc	s2,0x5
    80003a7a:	b4290913          	addi	s2,s2,-1214 # 800085b8 <syscalls+0x170>
    80003a7e:	85ca                	mv	a1,s2
    80003a80:	8526                	mv	a0,s1
    80003a82:	00001097          	auipc	ra,0x1
    80003a86:	e46080e7          	jalr	-442(ra) # 800048c8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a8a:	08848493          	addi	s1,s1,136
    80003a8e:	ff3498e3          	bne	s1,s3,80003a7e <iinit+0x3e>
}
    80003a92:	70a2                	ld	ra,40(sp)
    80003a94:	7402                	ld	s0,32(sp)
    80003a96:	64e2                	ld	s1,24(sp)
    80003a98:	6942                	ld	s2,16(sp)
    80003a9a:	69a2                	ld	s3,8(sp)
    80003a9c:	6145                	addi	sp,sp,48
    80003a9e:	8082                	ret

0000000080003aa0 <ialloc>:
{
    80003aa0:	715d                	addi	sp,sp,-80
    80003aa2:	e486                	sd	ra,72(sp)
    80003aa4:	e0a2                	sd	s0,64(sp)
    80003aa6:	fc26                	sd	s1,56(sp)
    80003aa8:	f84a                	sd	s2,48(sp)
    80003aaa:	f44e                	sd	s3,40(sp)
    80003aac:	f052                	sd	s4,32(sp)
    80003aae:	ec56                	sd	s5,24(sp)
    80003ab0:	e85a                	sd	s6,16(sp)
    80003ab2:	e45e                	sd	s7,8(sp)
    80003ab4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ab6:	0001c717          	auipc	a4,0x1c
    80003aba:	68672703          	lw	a4,1670(a4) # 8002013c <sb+0xc>
    80003abe:	4785                	li	a5,1
    80003ac0:	04e7fa63          	bgeu	a5,a4,80003b14 <ialloc+0x74>
    80003ac4:	8aaa                	mv	s5,a0
    80003ac6:	8bae                	mv	s7,a1
    80003ac8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003aca:	0001ca17          	auipc	s4,0x1c
    80003ace:	666a0a13          	addi	s4,s4,1638 # 80020130 <sb>
    80003ad2:	00048b1b          	sext.w	s6,s1
    80003ad6:	0044d593          	srli	a1,s1,0x4
    80003ada:	018a2783          	lw	a5,24(s4)
    80003ade:	9dbd                	addw	a1,a1,a5
    80003ae0:	8556                	mv	a0,s5
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	954080e7          	jalr	-1708(ra) # 80003436 <bread>
    80003aea:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003aec:	05850993          	addi	s3,a0,88
    80003af0:	00f4f793          	andi	a5,s1,15
    80003af4:	079a                	slli	a5,a5,0x6
    80003af6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003af8:	00099783          	lh	a5,0(s3)
    80003afc:	c785                	beqz	a5,80003b24 <ialloc+0x84>
    brelse(bp);
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	a68080e7          	jalr	-1432(ra) # 80003566 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b06:	0485                	addi	s1,s1,1
    80003b08:	00ca2703          	lw	a4,12(s4)
    80003b0c:	0004879b          	sext.w	a5,s1
    80003b10:	fce7e1e3          	bltu	a5,a4,80003ad2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b14:	00005517          	auipc	a0,0x5
    80003b18:	aac50513          	addi	a0,a0,-1364 # 800085c0 <syscalls+0x178>
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	a22080e7          	jalr	-1502(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b24:	04000613          	li	a2,64
    80003b28:	4581                	li	a1,0
    80003b2a:	854e                	mv	a0,s3
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	1b4080e7          	jalr	436(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b34:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b38:	854a                	mv	a0,s2
    80003b3a:	00001097          	auipc	ra,0x1
    80003b3e:	ca8080e7          	jalr	-856(ra) # 800047e2 <log_write>
      brelse(bp);
    80003b42:	854a                	mv	a0,s2
    80003b44:	00000097          	auipc	ra,0x0
    80003b48:	a22080e7          	jalr	-1502(ra) # 80003566 <brelse>
      return iget(dev, inum);
    80003b4c:	85da                	mv	a1,s6
    80003b4e:	8556                	mv	a0,s5
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	db4080e7          	jalr	-588(ra) # 80003904 <iget>
}
    80003b58:	60a6                	ld	ra,72(sp)
    80003b5a:	6406                	ld	s0,64(sp)
    80003b5c:	74e2                	ld	s1,56(sp)
    80003b5e:	7942                	ld	s2,48(sp)
    80003b60:	79a2                	ld	s3,40(sp)
    80003b62:	7a02                	ld	s4,32(sp)
    80003b64:	6ae2                	ld	s5,24(sp)
    80003b66:	6b42                	ld	s6,16(sp)
    80003b68:	6ba2                	ld	s7,8(sp)
    80003b6a:	6161                	addi	sp,sp,80
    80003b6c:	8082                	ret

0000000080003b6e <iupdate>:
{
    80003b6e:	1101                	addi	sp,sp,-32
    80003b70:	ec06                	sd	ra,24(sp)
    80003b72:	e822                	sd	s0,16(sp)
    80003b74:	e426                	sd	s1,8(sp)
    80003b76:	e04a                	sd	s2,0(sp)
    80003b78:	1000                	addi	s0,sp,32
    80003b7a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b7c:	415c                	lw	a5,4(a0)
    80003b7e:	0047d79b          	srliw	a5,a5,0x4
    80003b82:	0001c597          	auipc	a1,0x1c
    80003b86:	5c65a583          	lw	a1,1478(a1) # 80020148 <sb+0x18>
    80003b8a:	9dbd                	addw	a1,a1,a5
    80003b8c:	4108                	lw	a0,0(a0)
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	8a8080e7          	jalr	-1880(ra) # 80003436 <bread>
    80003b96:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b98:	05850793          	addi	a5,a0,88
    80003b9c:	40c8                	lw	a0,4(s1)
    80003b9e:	893d                	andi	a0,a0,15
    80003ba0:	051a                	slli	a0,a0,0x6
    80003ba2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003ba4:	04449703          	lh	a4,68(s1)
    80003ba8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bac:	04649703          	lh	a4,70(s1)
    80003bb0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bb4:	04849703          	lh	a4,72(s1)
    80003bb8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bbc:	04a49703          	lh	a4,74(s1)
    80003bc0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003bc4:	44f8                	lw	a4,76(s1)
    80003bc6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bc8:	03400613          	li	a2,52
    80003bcc:	05048593          	addi	a1,s1,80
    80003bd0:	0531                	addi	a0,a0,12
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	16e080e7          	jalr	366(ra) # 80000d40 <memmove>
  log_write(bp);
    80003bda:	854a                	mv	a0,s2
    80003bdc:	00001097          	auipc	ra,0x1
    80003be0:	c06080e7          	jalr	-1018(ra) # 800047e2 <log_write>
  brelse(bp);
    80003be4:	854a                	mv	a0,s2
    80003be6:	00000097          	auipc	ra,0x0
    80003bea:	980080e7          	jalr	-1664(ra) # 80003566 <brelse>
}
    80003bee:	60e2                	ld	ra,24(sp)
    80003bf0:	6442                	ld	s0,16(sp)
    80003bf2:	64a2                	ld	s1,8(sp)
    80003bf4:	6902                	ld	s2,0(sp)
    80003bf6:	6105                	addi	sp,sp,32
    80003bf8:	8082                	ret

0000000080003bfa <idup>:
{
    80003bfa:	1101                	addi	sp,sp,-32
    80003bfc:	ec06                	sd	ra,24(sp)
    80003bfe:	e822                	sd	s0,16(sp)
    80003c00:	e426                	sd	s1,8(sp)
    80003c02:	1000                	addi	s0,sp,32
    80003c04:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c06:	0001c517          	auipc	a0,0x1c
    80003c0a:	54a50513          	addi	a0,a0,1354 # 80020150 <itable>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	fd6080e7          	jalr	-42(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c16:	449c                	lw	a5,8(s1)
    80003c18:	2785                	addiw	a5,a5,1
    80003c1a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c1c:	0001c517          	auipc	a0,0x1c
    80003c20:	53450513          	addi	a0,a0,1332 # 80020150 <itable>
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	074080e7          	jalr	116(ra) # 80000c98 <release>
}
    80003c2c:	8526                	mv	a0,s1
    80003c2e:	60e2                	ld	ra,24(sp)
    80003c30:	6442                	ld	s0,16(sp)
    80003c32:	64a2                	ld	s1,8(sp)
    80003c34:	6105                	addi	sp,sp,32
    80003c36:	8082                	ret

0000000080003c38 <ilock>:
{
    80003c38:	1101                	addi	sp,sp,-32
    80003c3a:	ec06                	sd	ra,24(sp)
    80003c3c:	e822                	sd	s0,16(sp)
    80003c3e:	e426                	sd	s1,8(sp)
    80003c40:	e04a                	sd	s2,0(sp)
    80003c42:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c44:	c115                	beqz	a0,80003c68 <ilock+0x30>
    80003c46:	84aa                	mv	s1,a0
    80003c48:	451c                	lw	a5,8(a0)
    80003c4a:	00f05f63          	blez	a5,80003c68 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c4e:	0541                	addi	a0,a0,16
    80003c50:	00001097          	auipc	ra,0x1
    80003c54:	cb2080e7          	jalr	-846(ra) # 80004902 <acquiresleep>
  if(ip->valid == 0){
    80003c58:	40bc                	lw	a5,64(s1)
    80003c5a:	cf99                	beqz	a5,80003c78 <ilock+0x40>
}
    80003c5c:	60e2                	ld	ra,24(sp)
    80003c5e:	6442                	ld	s0,16(sp)
    80003c60:	64a2                	ld	s1,8(sp)
    80003c62:	6902                	ld	s2,0(sp)
    80003c64:	6105                	addi	sp,sp,32
    80003c66:	8082                	ret
    panic("ilock");
    80003c68:	00005517          	auipc	a0,0x5
    80003c6c:	97050513          	addi	a0,a0,-1680 # 800085d8 <syscalls+0x190>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	8ce080e7          	jalr	-1842(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c78:	40dc                	lw	a5,4(s1)
    80003c7a:	0047d79b          	srliw	a5,a5,0x4
    80003c7e:	0001c597          	auipc	a1,0x1c
    80003c82:	4ca5a583          	lw	a1,1226(a1) # 80020148 <sb+0x18>
    80003c86:	9dbd                	addw	a1,a1,a5
    80003c88:	4088                	lw	a0,0(s1)
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	7ac080e7          	jalr	1964(ra) # 80003436 <bread>
    80003c92:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c94:	05850593          	addi	a1,a0,88
    80003c98:	40dc                	lw	a5,4(s1)
    80003c9a:	8bbd                	andi	a5,a5,15
    80003c9c:	079a                	slli	a5,a5,0x6
    80003c9e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ca0:	00059783          	lh	a5,0(a1)
    80003ca4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ca8:	00259783          	lh	a5,2(a1)
    80003cac:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cb0:	00459783          	lh	a5,4(a1)
    80003cb4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cb8:	00659783          	lh	a5,6(a1)
    80003cbc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cc0:	459c                	lw	a5,8(a1)
    80003cc2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cc4:	03400613          	li	a2,52
    80003cc8:	05b1                	addi	a1,a1,12
    80003cca:	05048513          	addi	a0,s1,80
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	072080e7          	jalr	114(ra) # 80000d40 <memmove>
    brelse(bp);
    80003cd6:	854a                	mv	a0,s2
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	88e080e7          	jalr	-1906(ra) # 80003566 <brelse>
    ip->valid = 1;
    80003ce0:	4785                	li	a5,1
    80003ce2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ce4:	04449783          	lh	a5,68(s1)
    80003ce8:	fbb5                	bnez	a5,80003c5c <ilock+0x24>
      panic("ilock: no type");
    80003cea:	00005517          	auipc	a0,0x5
    80003cee:	8f650513          	addi	a0,a0,-1802 # 800085e0 <syscalls+0x198>
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	84c080e7          	jalr	-1972(ra) # 8000053e <panic>

0000000080003cfa <iunlock>:
{
    80003cfa:	1101                	addi	sp,sp,-32
    80003cfc:	ec06                	sd	ra,24(sp)
    80003cfe:	e822                	sd	s0,16(sp)
    80003d00:	e426                	sd	s1,8(sp)
    80003d02:	e04a                	sd	s2,0(sp)
    80003d04:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d06:	c905                	beqz	a0,80003d36 <iunlock+0x3c>
    80003d08:	84aa                	mv	s1,a0
    80003d0a:	01050913          	addi	s2,a0,16
    80003d0e:	854a                	mv	a0,s2
    80003d10:	00001097          	auipc	ra,0x1
    80003d14:	c8c080e7          	jalr	-884(ra) # 8000499c <holdingsleep>
    80003d18:	cd19                	beqz	a0,80003d36 <iunlock+0x3c>
    80003d1a:	449c                	lw	a5,8(s1)
    80003d1c:	00f05d63          	blez	a5,80003d36 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d20:	854a                	mv	a0,s2
    80003d22:	00001097          	auipc	ra,0x1
    80003d26:	c36080e7          	jalr	-970(ra) # 80004958 <releasesleep>
}
    80003d2a:	60e2                	ld	ra,24(sp)
    80003d2c:	6442                	ld	s0,16(sp)
    80003d2e:	64a2                	ld	s1,8(sp)
    80003d30:	6902                	ld	s2,0(sp)
    80003d32:	6105                	addi	sp,sp,32
    80003d34:	8082                	ret
    panic("iunlock");
    80003d36:	00005517          	auipc	a0,0x5
    80003d3a:	8ba50513          	addi	a0,a0,-1862 # 800085f0 <syscalls+0x1a8>
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	800080e7          	jalr	-2048(ra) # 8000053e <panic>

0000000080003d46 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d46:	7179                	addi	sp,sp,-48
    80003d48:	f406                	sd	ra,40(sp)
    80003d4a:	f022                	sd	s0,32(sp)
    80003d4c:	ec26                	sd	s1,24(sp)
    80003d4e:	e84a                	sd	s2,16(sp)
    80003d50:	e44e                	sd	s3,8(sp)
    80003d52:	e052                	sd	s4,0(sp)
    80003d54:	1800                	addi	s0,sp,48
    80003d56:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d58:	05050493          	addi	s1,a0,80
    80003d5c:	08050913          	addi	s2,a0,128
    80003d60:	a021                	j	80003d68 <itrunc+0x22>
    80003d62:	0491                	addi	s1,s1,4
    80003d64:	01248d63          	beq	s1,s2,80003d7e <itrunc+0x38>
    if(ip->addrs[i]){
    80003d68:	408c                	lw	a1,0(s1)
    80003d6a:	dde5                	beqz	a1,80003d62 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d6c:	0009a503          	lw	a0,0(s3)
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	90c080e7          	jalr	-1780(ra) # 8000367c <bfree>
      ip->addrs[i] = 0;
    80003d78:	0004a023          	sw	zero,0(s1)
    80003d7c:	b7dd                	j	80003d62 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d7e:	0809a583          	lw	a1,128(s3)
    80003d82:	e185                	bnez	a1,80003da2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d84:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d88:	854e                	mv	a0,s3
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	de4080e7          	jalr	-540(ra) # 80003b6e <iupdate>
}
    80003d92:	70a2                	ld	ra,40(sp)
    80003d94:	7402                	ld	s0,32(sp)
    80003d96:	64e2                	ld	s1,24(sp)
    80003d98:	6942                	ld	s2,16(sp)
    80003d9a:	69a2                	ld	s3,8(sp)
    80003d9c:	6a02                	ld	s4,0(sp)
    80003d9e:	6145                	addi	sp,sp,48
    80003da0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003da2:	0009a503          	lw	a0,0(s3)
    80003da6:	fffff097          	auipc	ra,0xfffff
    80003daa:	690080e7          	jalr	1680(ra) # 80003436 <bread>
    80003dae:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003db0:	05850493          	addi	s1,a0,88
    80003db4:	45850913          	addi	s2,a0,1112
    80003db8:	a811                	j	80003dcc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003dba:	0009a503          	lw	a0,0(s3)
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	8be080e7          	jalr	-1858(ra) # 8000367c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003dc6:	0491                	addi	s1,s1,4
    80003dc8:	01248563          	beq	s1,s2,80003dd2 <itrunc+0x8c>
      if(a[j])
    80003dcc:	408c                	lw	a1,0(s1)
    80003dce:	dde5                	beqz	a1,80003dc6 <itrunc+0x80>
    80003dd0:	b7ed                	j	80003dba <itrunc+0x74>
    brelse(bp);
    80003dd2:	8552                	mv	a0,s4
    80003dd4:	fffff097          	auipc	ra,0xfffff
    80003dd8:	792080e7          	jalr	1938(ra) # 80003566 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ddc:	0809a583          	lw	a1,128(s3)
    80003de0:	0009a503          	lw	a0,0(s3)
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	898080e7          	jalr	-1896(ra) # 8000367c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003dec:	0809a023          	sw	zero,128(s3)
    80003df0:	bf51                	j	80003d84 <itrunc+0x3e>

0000000080003df2 <iput>:
{
    80003df2:	1101                	addi	sp,sp,-32
    80003df4:	ec06                	sd	ra,24(sp)
    80003df6:	e822                	sd	s0,16(sp)
    80003df8:	e426                	sd	s1,8(sp)
    80003dfa:	e04a                	sd	s2,0(sp)
    80003dfc:	1000                	addi	s0,sp,32
    80003dfe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e00:	0001c517          	auipc	a0,0x1c
    80003e04:	35050513          	addi	a0,a0,848 # 80020150 <itable>
    80003e08:	ffffd097          	auipc	ra,0xffffd
    80003e0c:	ddc080e7          	jalr	-548(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e10:	4498                	lw	a4,8(s1)
    80003e12:	4785                	li	a5,1
    80003e14:	02f70363          	beq	a4,a5,80003e3a <iput+0x48>
  ip->ref--;
    80003e18:	449c                	lw	a5,8(s1)
    80003e1a:	37fd                	addiw	a5,a5,-1
    80003e1c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e1e:	0001c517          	auipc	a0,0x1c
    80003e22:	33250513          	addi	a0,a0,818 # 80020150 <itable>
    80003e26:	ffffd097          	auipc	ra,0xffffd
    80003e2a:	e72080e7          	jalr	-398(ra) # 80000c98 <release>
}
    80003e2e:	60e2                	ld	ra,24(sp)
    80003e30:	6442                	ld	s0,16(sp)
    80003e32:	64a2                	ld	s1,8(sp)
    80003e34:	6902                	ld	s2,0(sp)
    80003e36:	6105                	addi	sp,sp,32
    80003e38:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e3a:	40bc                	lw	a5,64(s1)
    80003e3c:	dff1                	beqz	a5,80003e18 <iput+0x26>
    80003e3e:	04a49783          	lh	a5,74(s1)
    80003e42:	fbf9                	bnez	a5,80003e18 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e44:	01048913          	addi	s2,s1,16
    80003e48:	854a                	mv	a0,s2
    80003e4a:	00001097          	auipc	ra,0x1
    80003e4e:	ab8080e7          	jalr	-1352(ra) # 80004902 <acquiresleep>
    release(&itable.lock);
    80003e52:	0001c517          	auipc	a0,0x1c
    80003e56:	2fe50513          	addi	a0,a0,766 # 80020150 <itable>
    80003e5a:	ffffd097          	auipc	ra,0xffffd
    80003e5e:	e3e080e7          	jalr	-450(ra) # 80000c98 <release>
    itrunc(ip);
    80003e62:	8526                	mv	a0,s1
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	ee2080e7          	jalr	-286(ra) # 80003d46 <itrunc>
    ip->type = 0;
    80003e6c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e70:	8526                	mv	a0,s1
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	cfc080e7          	jalr	-772(ra) # 80003b6e <iupdate>
    ip->valid = 0;
    80003e7a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e7e:	854a                	mv	a0,s2
    80003e80:	00001097          	auipc	ra,0x1
    80003e84:	ad8080e7          	jalr	-1320(ra) # 80004958 <releasesleep>
    acquire(&itable.lock);
    80003e88:	0001c517          	auipc	a0,0x1c
    80003e8c:	2c850513          	addi	a0,a0,712 # 80020150 <itable>
    80003e90:	ffffd097          	auipc	ra,0xffffd
    80003e94:	d54080e7          	jalr	-684(ra) # 80000be4 <acquire>
    80003e98:	b741                	j	80003e18 <iput+0x26>

0000000080003e9a <iunlockput>:
{
    80003e9a:	1101                	addi	sp,sp,-32
    80003e9c:	ec06                	sd	ra,24(sp)
    80003e9e:	e822                	sd	s0,16(sp)
    80003ea0:	e426                	sd	s1,8(sp)
    80003ea2:	1000                	addi	s0,sp,32
    80003ea4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	e54080e7          	jalr	-428(ra) # 80003cfa <iunlock>
  iput(ip);
    80003eae:	8526                	mv	a0,s1
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	f42080e7          	jalr	-190(ra) # 80003df2 <iput>
}
    80003eb8:	60e2                	ld	ra,24(sp)
    80003eba:	6442                	ld	s0,16(sp)
    80003ebc:	64a2                	ld	s1,8(sp)
    80003ebe:	6105                	addi	sp,sp,32
    80003ec0:	8082                	ret

0000000080003ec2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ec2:	1141                	addi	sp,sp,-16
    80003ec4:	e422                	sd	s0,8(sp)
    80003ec6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ec8:	411c                	lw	a5,0(a0)
    80003eca:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ecc:	415c                	lw	a5,4(a0)
    80003ece:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ed0:	04451783          	lh	a5,68(a0)
    80003ed4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ed8:	04a51783          	lh	a5,74(a0)
    80003edc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ee0:	04c56783          	lwu	a5,76(a0)
    80003ee4:	e99c                	sd	a5,16(a1)
}
    80003ee6:	6422                	ld	s0,8(sp)
    80003ee8:	0141                	addi	sp,sp,16
    80003eea:	8082                	ret

0000000080003eec <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eec:	457c                	lw	a5,76(a0)
    80003eee:	0ed7e963          	bltu	a5,a3,80003fe0 <readi+0xf4>
{
    80003ef2:	7159                	addi	sp,sp,-112
    80003ef4:	f486                	sd	ra,104(sp)
    80003ef6:	f0a2                	sd	s0,96(sp)
    80003ef8:	eca6                	sd	s1,88(sp)
    80003efa:	e8ca                	sd	s2,80(sp)
    80003efc:	e4ce                	sd	s3,72(sp)
    80003efe:	e0d2                	sd	s4,64(sp)
    80003f00:	fc56                	sd	s5,56(sp)
    80003f02:	f85a                	sd	s6,48(sp)
    80003f04:	f45e                	sd	s7,40(sp)
    80003f06:	f062                	sd	s8,32(sp)
    80003f08:	ec66                	sd	s9,24(sp)
    80003f0a:	e86a                	sd	s10,16(sp)
    80003f0c:	e46e                	sd	s11,8(sp)
    80003f0e:	1880                	addi	s0,sp,112
    80003f10:	8baa                	mv	s7,a0
    80003f12:	8c2e                	mv	s8,a1
    80003f14:	8ab2                	mv	s5,a2
    80003f16:	84b6                	mv	s1,a3
    80003f18:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f1a:	9f35                	addw	a4,a4,a3
    return 0;
    80003f1c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f1e:	0ad76063          	bltu	a4,a3,80003fbe <readi+0xd2>
  if(off + n > ip->size)
    80003f22:	00e7f463          	bgeu	a5,a4,80003f2a <readi+0x3e>
    n = ip->size - off;
    80003f26:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f2a:	0a0b0963          	beqz	s6,80003fdc <readi+0xf0>
    80003f2e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f30:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f34:	5cfd                	li	s9,-1
    80003f36:	a82d                	j	80003f70 <readi+0x84>
    80003f38:	020a1d93          	slli	s11,s4,0x20
    80003f3c:	020ddd93          	srli	s11,s11,0x20
    80003f40:	05890613          	addi	a2,s2,88
    80003f44:	86ee                	mv	a3,s11
    80003f46:	963a                	add	a2,a2,a4
    80003f48:	85d6                	mv	a1,s5
    80003f4a:	8562                	mv	a0,s8
    80003f4c:	ffffe097          	auipc	ra,0xffffe
    80003f50:	cba080e7          	jalr	-838(ra) # 80001c06 <either_copyout>
    80003f54:	05950d63          	beq	a0,s9,80003fae <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f58:	854a                	mv	a0,s2
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	60c080e7          	jalr	1548(ra) # 80003566 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f62:	013a09bb          	addw	s3,s4,s3
    80003f66:	009a04bb          	addw	s1,s4,s1
    80003f6a:	9aee                	add	s5,s5,s11
    80003f6c:	0569f763          	bgeu	s3,s6,80003fba <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f70:	000ba903          	lw	s2,0(s7)
    80003f74:	00a4d59b          	srliw	a1,s1,0xa
    80003f78:	855e                	mv	a0,s7
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	8b0080e7          	jalr	-1872(ra) # 8000382a <bmap>
    80003f82:	0005059b          	sext.w	a1,a0
    80003f86:	854a                	mv	a0,s2
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	4ae080e7          	jalr	1198(ra) # 80003436 <bread>
    80003f90:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f92:	3ff4f713          	andi	a4,s1,1023
    80003f96:	40ed07bb          	subw	a5,s10,a4
    80003f9a:	413b06bb          	subw	a3,s6,s3
    80003f9e:	8a3e                	mv	s4,a5
    80003fa0:	2781                	sext.w	a5,a5
    80003fa2:	0006861b          	sext.w	a2,a3
    80003fa6:	f8f679e3          	bgeu	a2,a5,80003f38 <readi+0x4c>
    80003faa:	8a36                	mv	s4,a3
    80003fac:	b771                	j	80003f38 <readi+0x4c>
      brelse(bp);
    80003fae:	854a                	mv	a0,s2
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	5b6080e7          	jalr	1462(ra) # 80003566 <brelse>
      tot = -1;
    80003fb8:	59fd                	li	s3,-1
  }
  return tot;
    80003fba:	0009851b          	sext.w	a0,s3
}
    80003fbe:	70a6                	ld	ra,104(sp)
    80003fc0:	7406                	ld	s0,96(sp)
    80003fc2:	64e6                	ld	s1,88(sp)
    80003fc4:	6946                	ld	s2,80(sp)
    80003fc6:	69a6                	ld	s3,72(sp)
    80003fc8:	6a06                	ld	s4,64(sp)
    80003fca:	7ae2                	ld	s5,56(sp)
    80003fcc:	7b42                	ld	s6,48(sp)
    80003fce:	7ba2                	ld	s7,40(sp)
    80003fd0:	7c02                	ld	s8,32(sp)
    80003fd2:	6ce2                	ld	s9,24(sp)
    80003fd4:	6d42                	ld	s10,16(sp)
    80003fd6:	6da2                	ld	s11,8(sp)
    80003fd8:	6165                	addi	sp,sp,112
    80003fda:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fdc:	89da                	mv	s3,s6
    80003fde:	bff1                	j	80003fba <readi+0xce>
    return 0;
    80003fe0:	4501                	li	a0,0
}
    80003fe2:	8082                	ret

0000000080003fe4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fe4:	457c                	lw	a5,76(a0)
    80003fe6:	10d7e863          	bltu	a5,a3,800040f6 <writei+0x112>
{
    80003fea:	7159                	addi	sp,sp,-112
    80003fec:	f486                	sd	ra,104(sp)
    80003fee:	f0a2                	sd	s0,96(sp)
    80003ff0:	eca6                	sd	s1,88(sp)
    80003ff2:	e8ca                	sd	s2,80(sp)
    80003ff4:	e4ce                	sd	s3,72(sp)
    80003ff6:	e0d2                	sd	s4,64(sp)
    80003ff8:	fc56                	sd	s5,56(sp)
    80003ffa:	f85a                	sd	s6,48(sp)
    80003ffc:	f45e                	sd	s7,40(sp)
    80003ffe:	f062                	sd	s8,32(sp)
    80004000:	ec66                	sd	s9,24(sp)
    80004002:	e86a                	sd	s10,16(sp)
    80004004:	e46e                	sd	s11,8(sp)
    80004006:	1880                	addi	s0,sp,112
    80004008:	8b2a                	mv	s6,a0
    8000400a:	8c2e                	mv	s8,a1
    8000400c:	8ab2                	mv	s5,a2
    8000400e:	8936                	mv	s2,a3
    80004010:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004012:	00e687bb          	addw	a5,a3,a4
    80004016:	0ed7e263          	bltu	a5,a3,800040fa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000401a:	00043737          	lui	a4,0x43
    8000401e:	0ef76063          	bltu	a4,a5,800040fe <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004022:	0c0b8863          	beqz	s7,800040f2 <writei+0x10e>
    80004026:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004028:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000402c:	5cfd                	li	s9,-1
    8000402e:	a091                	j	80004072 <writei+0x8e>
    80004030:	02099d93          	slli	s11,s3,0x20
    80004034:	020ddd93          	srli	s11,s11,0x20
    80004038:	05848513          	addi	a0,s1,88
    8000403c:	86ee                	mv	a3,s11
    8000403e:	8656                	mv	a2,s5
    80004040:	85e2                	mv	a1,s8
    80004042:	953a                	add	a0,a0,a4
    80004044:	ffffe097          	auipc	ra,0xffffe
    80004048:	c18080e7          	jalr	-1000(ra) # 80001c5c <either_copyin>
    8000404c:	07950263          	beq	a0,s9,800040b0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004050:	8526                	mv	a0,s1
    80004052:	00000097          	auipc	ra,0x0
    80004056:	790080e7          	jalr	1936(ra) # 800047e2 <log_write>
    brelse(bp);
    8000405a:	8526                	mv	a0,s1
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	50a080e7          	jalr	1290(ra) # 80003566 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004064:	01498a3b          	addw	s4,s3,s4
    80004068:	0129893b          	addw	s2,s3,s2
    8000406c:	9aee                	add	s5,s5,s11
    8000406e:	057a7663          	bgeu	s4,s7,800040ba <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004072:	000b2483          	lw	s1,0(s6)
    80004076:	00a9559b          	srliw	a1,s2,0xa
    8000407a:	855a                	mv	a0,s6
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	7ae080e7          	jalr	1966(ra) # 8000382a <bmap>
    80004084:	0005059b          	sext.w	a1,a0
    80004088:	8526                	mv	a0,s1
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	3ac080e7          	jalr	940(ra) # 80003436 <bread>
    80004092:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004094:	3ff97713          	andi	a4,s2,1023
    80004098:	40ed07bb          	subw	a5,s10,a4
    8000409c:	414b86bb          	subw	a3,s7,s4
    800040a0:	89be                	mv	s3,a5
    800040a2:	2781                	sext.w	a5,a5
    800040a4:	0006861b          	sext.w	a2,a3
    800040a8:	f8f674e3          	bgeu	a2,a5,80004030 <writei+0x4c>
    800040ac:	89b6                	mv	s3,a3
    800040ae:	b749                	j	80004030 <writei+0x4c>
      brelse(bp);
    800040b0:	8526                	mv	a0,s1
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	4b4080e7          	jalr	1204(ra) # 80003566 <brelse>
  }

  if(off > ip->size)
    800040ba:	04cb2783          	lw	a5,76(s6)
    800040be:	0127f463          	bgeu	a5,s2,800040c6 <writei+0xe2>
    ip->size = off;
    800040c2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040c6:	855a                	mv	a0,s6
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	aa6080e7          	jalr	-1370(ra) # 80003b6e <iupdate>

  return tot;
    800040d0:	000a051b          	sext.w	a0,s4
}
    800040d4:	70a6                	ld	ra,104(sp)
    800040d6:	7406                	ld	s0,96(sp)
    800040d8:	64e6                	ld	s1,88(sp)
    800040da:	6946                	ld	s2,80(sp)
    800040dc:	69a6                	ld	s3,72(sp)
    800040de:	6a06                	ld	s4,64(sp)
    800040e0:	7ae2                	ld	s5,56(sp)
    800040e2:	7b42                	ld	s6,48(sp)
    800040e4:	7ba2                	ld	s7,40(sp)
    800040e6:	7c02                	ld	s8,32(sp)
    800040e8:	6ce2                	ld	s9,24(sp)
    800040ea:	6d42                	ld	s10,16(sp)
    800040ec:	6da2                	ld	s11,8(sp)
    800040ee:	6165                	addi	sp,sp,112
    800040f0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f2:	8a5e                	mv	s4,s7
    800040f4:	bfc9                	j	800040c6 <writei+0xe2>
    return -1;
    800040f6:	557d                	li	a0,-1
}
    800040f8:	8082                	ret
    return -1;
    800040fa:	557d                	li	a0,-1
    800040fc:	bfe1                	j	800040d4 <writei+0xf0>
    return -1;
    800040fe:	557d                	li	a0,-1
    80004100:	bfd1                	j	800040d4 <writei+0xf0>

0000000080004102 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004102:	1141                	addi	sp,sp,-16
    80004104:	e406                	sd	ra,8(sp)
    80004106:	e022                	sd	s0,0(sp)
    80004108:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000410a:	4639                	li	a2,14
    8000410c:	ffffd097          	auipc	ra,0xffffd
    80004110:	cac080e7          	jalr	-852(ra) # 80000db8 <strncmp>
}
    80004114:	60a2                	ld	ra,8(sp)
    80004116:	6402                	ld	s0,0(sp)
    80004118:	0141                	addi	sp,sp,16
    8000411a:	8082                	ret

000000008000411c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000411c:	7139                	addi	sp,sp,-64
    8000411e:	fc06                	sd	ra,56(sp)
    80004120:	f822                	sd	s0,48(sp)
    80004122:	f426                	sd	s1,40(sp)
    80004124:	f04a                	sd	s2,32(sp)
    80004126:	ec4e                	sd	s3,24(sp)
    80004128:	e852                	sd	s4,16(sp)
    8000412a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000412c:	04451703          	lh	a4,68(a0)
    80004130:	4785                	li	a5,1
    80004132:	00f71a63          	bne	a4,a5,80004146 <dirlookup+0x2a>
    80004136:	892a                	mv	s2,a0
    80004138:	89ae                	mv	s3,a1
    8000413a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000413c:	457c                	lw	a5,76(a0)
    8000413e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004140:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004142:	e79d                	bnez	a5,80004170 <dirlookup+0x54>
    80004144:	a8a5                	j	800041bc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004146:	00004517          	auipc	a0,0x4
    8000414a:	4b250513          	addi	a0,a0,1202 # 800085f8 <syscalls+0x1b0>
    8000414e:	ffffc097          	auipc	ra,0xffffc
    80004152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004156:	00004517          	auipc	a0,0x4
    8000415a:	4ba50513          	addi	a0,a0,1210 # 80008610 <syscalls+0x1c8>
    8000415e:	ffffc097          	auipc	ra,0xffffc
    80004162:	3e0080e7          	jalr	992(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004166:	24c1                	addiw	s1,s1,16
    80004168:	04c92783          	lw	a5,76(s2)
    8000416c:	04f4f763          	bgeu	s1,a5,800041ba <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004170:	4741                	li	a4,16
    80004172:	86a6                	mv	a3,s1
    80004174:	fc040613          	addi	a2,s0,-64
    80004178:	4581                	li	a1,0
    8000417a:	854a                	mv	a0,s2
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	d70080e7          	jalr	-656(ra) # 80003eec <readi>
    80004184:	47c1                	li	a5,16
    80004186:	fcf518e3          	bne	a0,a5,80004156 <dirlookup+0x3a>
    if(de.inum == 0)
    8000418a:	fc045783          	lhu	a5,-64(s0)
    8000418e:	dfe1                	beqz	a5,80004166 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004190:	fc240593          	addi	a1,s0,-62
    80004194:	854e                	mv	a0,s3
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	f6c080e7          	jalr	-148(ra) # 80004102 <namecmp>
    8000419e:	f561                	bnez	a0,80004166 <dirlookup+0x4a>
      if(poff)
    800041a0:	000a0463          	beqz	s4,800041a8 <dirlookup+0x8c>
        *poff = off;
    800041a4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041a8:	fc045583          	lhu	a1,-64(s0)
    800041ac:	00092503          	lw	a0,0(s2)
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	754080e7          	jalr	1876(ra) # 80003904 <iget>
    800041b8:	a011                	j	800041bc <dirlookup+0xa0>
  return 0;
    800041ba:	4501                	li	a0,0
}
    800041bc:	70e2                	ld	ra,56(sp)
    800041be:	7442                	ld	s0,48(sp)
    800041c0:	74a2                	ld	s1,40(sp)
    800041c2:	7902                	ld	s2,32(sp)
    800041c4:	69e2                	ld	s3,24(sp)
    800041c6:	6a42                	ld	s4,16(sp)
    800041c8:	6121                	addi	sp,sp,64
    800041ca:	8082                	ret

00000000800041cc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041cc:	711d                	addi	sp,sp,-96
    800041ce:	ec86                	sd	ra,88(sp)
    800041d0:	e8a2                	sd	s0,80(sp)
    800041d2:	e4a6                	sd	s1,72(sp)
    800041d4:	e0ca                	sd	s2,64(sp)
    800041d6:	fc4e                	sd	s3,56(sp)
    800041d8:	f852                	sd	s4,48(sp)
    800041da:	f456                	sd	s5,40(sp)
    800041dc:	f05a                	sd	s6,32(sp)
    800041de:	ec5e                	sd	s7,24(sp)
    800041e0:	e862                	sd	s8,16(sp)
    800041e2:	e466                	sd	s9,8(sp)
    800041e4:	1080                	addi	s0,sp,96
    800041e6:	84aa                	mv	s1,a0
    800041e8:	8b2e                	mv	s6,a1
    800041ea:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041ec:	00054703          	lbu	a4,0(a0)
    800041f0:	02f00793          	li	a5,47
    800041f4:	02f70363          	beq	a4,a5,8000421a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	70e080e7          	jalr	1806(ra) # 80001906 <myproc>
    80004200:	17053503          	ld	a0,368(a0)
    80004204:	00000097          	auipc	ra,0x0
    80004208:	9f6080e7          	jalr	-1546(ra) # 80003bfa <idup>
    8000420c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000420e:	02f00913          	li	s2,47
  len = path - s;
    80004212:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004214:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004216:	4c05                	li	s8,1
    80004218:	a865                	j	800042d0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000421a:	4585                	li	a1,1
    8000421c:	4505                	li	a0,1
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	6e6080e7          	jalr	1766(ra) # 80003904 <iget>
    80004226:	89aa                	mv	s3,a0
    80004228:	b7dd                	j	8000420e <namex+0x42>
      iunlockput(ip);
    8000422a:	854e                	mv	a0,s3
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	c6e080e7          	jalr	-914(ra) # 80003e9a <iunlockput>
      return 0;
    80004234:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004236:	854e                	mv	a0,s3
    80004238:	60e6                	ld	ra,88(sp)
    8000423a:	6446                	ld	s0,80(sp)
    8000423c:	64a6                	ld	s1,72(sp)
    8000423e:	6906                	ld	s2,64(sp)
    80004240:	79e2                	ld	s3,56(sp)
    80004242:	7a42                	ld	s4,48(sp)
    80004244:	7aa2                	ld	s5,40(sp)
    80004246:	7b02                	ld	s6,32(sp)
    80004248:	6be2                	ld	s7,24(sp)
    8000424a:	6c42                	ld	s8,16(sp)
    8000424c:	6ca2                	ld	s9,8(sp)
    8000424e:	6125                	addi	sp,sp,96
    80004250:	8082                	ret
      iunlock(ip);
    80004252:	854e                	mv	a0,s3
    80004254:	00000097          	auipc	ra,0x0
    80004258:	aa6080e7          	jalr	-1370(ra) # 80003cfa <iunlock>
      return ip;
    8000425c:	bfe9                	j	80004236 <namex+0x6a>
      iunlockput(ip);
    8000425e:	854e                	mv	a0,s3
    80004260:	00000097          	auipc	ra,0x0
    80004264:	c3a080e7          	jalr	-966(ra) # 80003e9a <iunlockput>
      return 0;
    80004268:	89d2                	mv	s3,s4
    8000426a:	b7f1                	j	80004236 <namex+0x6a>
  len = path - s;
    8000426c:	40b48633          	sub	a2,s1,a1
    80004270:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004274:	094cd463          	bge	s9,s4,800042fc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004278:	4639                	li	a2,14
    8000427a:	8556                	mv	a0,s5
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	ac4080e7          	jalr	-1340(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004284:	0004c783          	lbu	a5,0(s1)
    80004288:	01279763          	bne	a5,s2,80004296 <namex+0xca>
    path++;
    8000428c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000428e:	0004c783          	lbu	a5,0(s1)
    80004292:	ff278de3          	beq	a5,s2,8000428c <namex+0xc0>
    ilock(ip);
    80004296:	854e                	mv	a0,s3
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	9a0080e7          	jalr	-1632(ra) # 80003c38 <ilock>
    if(ip->type != T_DIR){
    800042a0:	04499783          	lh	a5,68(s3)
    800042a4:	f98793e3          	bne	a5,s8,8000422a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042a8:	000b0563          	beqz	s6,800042b2 <namex+0xe6>
    800042ac:	0004c783          	lbu	a5,0(s1)
    800042b0:	d3cd                	beqz	a5,80004252 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042b2:	865e                	mv	a2,s7
    800042b4:	85d6                	mv	a1,s5
    800042b6:	854e                	mv	a0,s3
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	e64080e7          	jalr	-412(ra) # 8000411c <dirlookup>
    800042c0:	8a2a                	mv	s4,a0
    800042c2:	dd51                	beqz	a0,8000425e <namex+0x92>
    iunlockput(ip);
    800042c4:	854e                	mv	a0,s3
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	bd4080e7          	jalr	-1068(ra) # 80003e9a <iunlockput>
    ip = next;
    800042ce:	89d2                	mv	s3,s4
  while(*path == '/')
    800042d0:	0004c783          	lbu	a5,0(s1)
    800042d4:	05279763          	bne	a5,s2,80004322 <namex+0x156>
    path++;
    800042d8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042da:	0004c783          	lbu	a5,0(s1)
    800042de:	ff278de3          	beq	a5,s2,800042d8 <namex+0x10c>
  if(*path == 0)
    800042e2:	c79d                	beqz	a5,80004310 <namex+0x144>
    path++;
    800042e4:	85a6                	mv	a1,s1
  len = path - s;
    800042e6:	8a5e                	mv	s4,s7
    800042e8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042ea:	01278963          	beq	a5,s2,800042fc <namex+0x130>
    800042ee:	dfbd                	beqz	a5,8000426c <namex+0xa0>
    path++;
    800042f0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042f2:	0004c783          	lbu	a5,0(s1)
    800042f6:	ff279ce3          	bne	a5,s2,800042ee <namex+0x122>
    800042fa:	bf8d                	j	8000426c <namex+0xa0>
    memmove(name, s, len);
    800042fc:	2601                	sext.w	a2,a2
    800042fe:	8556                	mv	a0,s5
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	a40080e7          	jalr	-1472(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004308:	9a56                	add	s4,s4,s5
    8000430a:	000a0023          	sb	zero,0(s4)
    8000430e:	bf9d                	j	80004284 <namex+0xb8>
  if(nameiparent){
    80004310:	f20b03e3          	beqz	s6,80004236 <namex+0x6a>
    iput(ip);
    80004314:	854e                	mv	a0,s3
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	adc080e7          	jalr	-1316(ra) # 80003df2 <iput>
    return 0;
    8000431e:	4981                	li	s3,0
    80004320:	bf19                	j	80004236 <namex+0x6a>
  if(*path == 0)
    80004322:	d7fd                	beqz	a5,80004310 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004324:	0004c783          	lbu	a5,0(s1)
    80004328:	85a6                	mv	a1,s1
    8000432a:	b7d1                	j	800042ee <namex+0x122>

000000008000432c <dirlink>:
{
    8000432c:	7139                	addi	sp,sp,-64
    8000432e:	fc06                	sd	ra,56(sp)
    80004330:	f822                	sd	s0,48(sp)
    80004332:	f426                	sd	s1,40(sp)
    80004334:	f04a                	sd	s2,32(sp)
    80004336:	ec4e                	sd	s3,24(sp)
    80004338:	e852                	sd	s4,16(sp)
    8000433a:	0080                	addi	s0,sp,64
    8000433c:	892a                	mv	s2,a0
    8000433e:	8a2e                	mv	s4,a1
    80004340:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004342:	4601                	li	a2,0
    80004344:	00000097          	auipc	ra,0x0
    80004348:	dd8080e7          	jalr	-552(ra) # 8000411c <dirlookup>
    8000434c:	e93d                	bnez	a0,800043c2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000434e:	04c92483          	lw	s1,76(s2)
    80004352:	c49d                	beqz	s1,80004380 <dirlink+0x54>
    80004354:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004356:	4741                	li	a4,16
    80004358:	86a6                	mv	a3,s1
    8000435a:	fc040613          	addi	a2,s0,-64
    8000435e:	4581                	li	a1,0
    80004360:	854a                	mv	a0,s2
    80004362:	00000097          	auipc	ra,0x0
    80004366:	b8a080e7          	jalr	-1142(ra) # 80003eec <readi>
    8000436a:	47c1                	li	a5,16
    8000436c:	06f51163          	bne	a0,a5,800043ce <dirlink+0xa2>
    if(de.inum == 0)
    80004370:	fc045783          	lhu	a5,-64(s0)
    80004374:	c791                	beqz	a5,80004380 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004376:	24c1                	addiw	s1,s1,16
    80004378:	04c92783          	lw	a5,76(s2)
    8000437c:	fcf4ede3          	bltu	s1,a5,80004356 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004380:	4639                	li	a2,14
    80004382:	85d2                	mv	a1,s4
    80004384:	fc240513          	addi	a0,s0,-62
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	a6c080e7          	jalr	-1428(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004390:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004394:	4741                	li	a4,16
    80004396:	86a6                	mv	a3,s1
    80004398:	fc040613          	addi	a2,s0,-64
    8000439c:	4581                	li	a1,0
    8000439e:	854a                	mv	a0,s2
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	c44080e7          	jalr	-956(ra) # 80003fe4 <writei>
    800043a8:	872a                	mv	a4,a0
    800043aa:	47c1                	li	a5,16
  return 0;
    800043ac:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043ae:	02f71863          	bne	a4,a5,800043de <dirlink+0xb2>
}
    800043b2:	70e2                	ld	ra,56(sp)
    800043b4:	7442                	ld	s0,48(sp)
    800043b6:	74a2                	ld	s1,40(sp)
    800043b8:	7902                	ld	s2,32(sp)
    800043ba:	69e2                	ld	s3,24(sp)
    800043bc:	6a42                	ld	s4,16(sp)
    800043be:	6121                	addi	sp,sp,64
    800043c0:	8082                	ret
    iput(ip);
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	a30080e7          	jalr	-1488(ra) # 80003df2 <iput>
    return -1;
    800043ca:	557d                	li	a0,-1
    800043cc:	b7dd                	j	800043b2 <dirlink+0x86>
      panic("dirlink read");
    800043ce:	00004517          	auipc	a0,0x4
    800043d2:	25250513          	addi	a0,a0,594 # 80008620 <syscalls+0x1d8>
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	168080e7          	jalr	360(ra) # 8000053e <panic>
    panic("dirlink");
    800043de:	00004517          	auipc	a0,0x4
    800043e2:	35250513          	addi	a0,a0,850 # 80008730 <syscalls+0x2e8>
    800043e6:	ffffc097          	auipc	ra,0xffffc
    800043ea:	158080e7          	jalr	344(ra) # 8000053e <panic>

00000000800043ee <namei>:

struct inode*
namei(char *path)
{
    800043ee:	1101                	addi	sp,sp,-32
    800043f0:	ec06                	sd	ra,24(sp)
    800043f2:	e822                	sd	s0,16(sp)
    800043f4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043f6:	fe040613          	addi	a2,s0,-32
    800043fa:	4581                	li	a1,0
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	dd0080e7          	jalr	-560(ra) # 800041cc <namex>
}
    80004404:	60e2                	ld	ra,24(sp)
    80004406:	6442                	ld	s0,16(sp)
    80004408:	6105                	addi	sp,sp,32
    8000440a:	8082                	ret

000000008000440c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000440c:	1141                	addi	sp,sp,-16
    8000440e:	e406                	sd	ra,8(sp)
    80004410:	e022                	sd	s0,0(sp)
    80004412:	0800                	addi	s0,sp,16
    80004414:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004416:	4585                	li	a1,1
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	db4080e7          	jalr	-588(ra) # 800041cc <namex>
}
    80004420:	60a2                	ld	ra,8(sp)
    80004422:	6402                	ld	s0,0(sp)
    80004424:	0141                	addi	sp,sp,16
    80004426:	8082                	ret

0000000080004428 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004428:	1101                	addi	sp,sp,-32
    8000442a:	ec06                	sd	ra,24(sp)
    8000442c:	e822                	sd	s0,16(sp)
    8000442e:	e426                	sd	s1,8(sp)
    80004430:	e04a                	sd	s2,0(sp)
    80004432:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004434:	0001d917          	auipc	s2,0x1d
    80004438:	7c490913          	addi	s2,s2,1988 # 80021bf8 <log>
    8000443c:	01892583          	lw	a1,24(s2)
    80004440:	02892503          	lw	a0,40(s2)
    80004444:	fffff097          	auipc	ra,0xfffff
    80004448:	ff2080e7          	jalr	-14(ra) # 80003436 <bread>
    8000444c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000444e:	02c92683          	lw	a3,44(s2)
    80004452:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004454:	02d05763          	blez	a3,80004482 <write_head+0x5a>
    80004458:	0001d797          	auipc	a5,0x1d
    8000445c:	7d078793          	addi	a5,a5,2000 # 80021c28 <log+0x30>
    80004460:	05c50713          	addi	a4,a0,92
    80004464:	36fd                	addiw	a3,a3,-1
    80004466:	1682                	slli	a3,a3,0x20
    80004468:	9281                	srli	a3,a3,0x20
    8000446a:	068a                	slli	a3,a3,0x2
    8000446c:	0001d617          	auipc	a2,0x1d
    80004470:	7c060613          	addi	a2,a2,1984 # 80021c2c <log+0x34>
    80004474:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004476:	4390                	lw	a2,0(a5)
    80004478:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000447a:	0791                	addi	a5,a5,4
    8000447c:	0711                	addi	a4,a4,4
    8000447e:	fed79ce3          	bne	a5,a3,80004476 <write_head+0x4e>
  }
  bwrite(buf);
    80004482:	8526                	mv	a0,s1
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	0a4080e7          	jalr	164(ra) # 80003528 <bwrite>
  brelse(buf);
    8000448c:	8526                	mv	a0,s1
    8000448e:	fffff097          	auipc	ra,0xfffff
    80004492:	0d8080e7          	jalr	216(ra) # 80003566 <brelse>
}
    80004496:	60e2                	ld	ra,24(sp)
    80004498:	6442                	ld	s0,16(sp)
    8000449a:	64a2                	ld	s1,8(sp)
    8000449c:	6902                	ld	s2,0(sp)
    8000449e:	6105                	addi	sp,sp,32
    800044a0:	8082                	ret

00000000800044a2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a2:	0001d797          	auipc	a5,0x1d
    800044a6:	7827a783          	lw	a5,1922(a5) # 80021c24 <log+0x2c>
    800044aa:	0af05d63          	blez	a5,80004564 <install_trans+0xc2>
{
    800044ae:	7139                	addi	sp,sp,-64
    800044b0:	fc06                	sd	ra,56(sp)
    800044b2:	f822                	sd	s0,48(sp)
    800044b4:	f426                	sd	s1,40(sp)
    800044b6:	f04a                	sd	s2,32(sp)
    800044b8:	ec4e                	sd	s3,24(sp)
    800044ba:	e852                	sd	s4,16(sp)
    800044bc:	e456                	sd	s5,8(sp)
    800044be:	e05a                	sd	s6,0(sp)
    800044c0:	0080                	addi	s0,sp,64
    800044c2:	8b2a                	mv	s6,a0
    800044c4:	0001da97          	auipc	s5,0x1d
    800044c8:	764a8a93          	addi	s5,s5,1892 # 80021c28 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044cc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044ce:	0001d997          	auipc	s3,0x1d
    800044d2:	72a98993          	addi	s3,s3,1834 # 80021bf8 <log>
    800044d6:	a035                	j	80004502 <install_trans+0x60>
      bunpin(dbuf);
    800044d8:	8526                	mv	a0,s1
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	166080e7          	jalr	358(ra) # 80003640 <bunpin>
    brelse(lbuf);
    800044e2:	854a                	mv	a0,s2
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	082080e7          	jalr	130(ra) # 80003566 <brelse>
    brelse(dbuf);
    800044ec:	8526                	mv	a0,s1
    800044ee:	fffff097          	auipc	ra,0xfffff
    800044f2:	078080e7          	jalr	120(ra) # 80003566 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f6:	2a05                	addiw	s4,s4,1
    800044f8:	0a91                	addi	s5,s5,4
    800044fa:	02c9a783          	lw	a5,44(s3)
    800044fe:	04fa5963          	bge	s4,a5,80004550 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004502:	0189a583          	lw	a1,24(s3)
    80004506:	014585bb          	addw	a1,a1,s4
    8000450a:	2585                	addiw	a1,a1,1
    8000450c:	0289a503          	lw	a0,40(s3)
    80004510:	fffff097          	auipc	ra,0xfffff
    80004514:	f26080e7          	jalr	-218(ra) # 80003436 <bread>
    80004518:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000451a:	000aa583          	lw	a1,0(s5)
    8000451e:	0289a503          	lw	a0,40(s3)
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	f14080e7          	jalr	-236(ra) # 80003436 <bread>
    8000452a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000452c:	40000613          	li	a2,1024
    80004530:	05890593          	addi	a1,s2,88
    80004534:	05850513          	addi	a0,a0,88
    80004538:	ffffd097          	auipc	ra,0xffffd
    8000453c:	808080e7          	jalr	-2040(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004540:	8526                	mv	a0,s1
    80004542:	fffff097          	auipc	ra,0xfffff
    80004546:	fe6080e7          	jalr	-26(ra) # 80003528 <bwrite>
    if(recovering == 0)
    8000454a:	f80b1ce3          	bnez	s6,800044e2 <install_trans+0x40>
    8000454e:	b769                	j	800044d8 <install_trans+0x36>
}
    80004550:	70e2                	ld	ra,56(sp)
    80004552:	7442                	ld	s0,48(sp)
    80004554:	74a2                	ld	s1,40(sp)
    80004556:	7902                	ld	s2,32(sp)
    80004558:	69e2                	ld	s3,24(sp)
    8000455a:	6a42                	ld	s4,16(sp)
    8000455c:	6aa2                	ld	s5,8(sp)
    8000455e:	6b02                	ld	s6,0(sp)
    80004560:	6121                	addi	sp,sp,64
    80004562:	8082                	ret
    80004564:	8082                	ret

0000000080004566 <initlog>:
{
    80004566:	7179                	addi	sp,sp,-48
    80004568:	f406                	sd	ra,40(sp)
    8000456a:	f022                	sd	s0,32(sp)
    8000456c:	ec26                	sd	s1,24(sp)
    8000456e:	e84a                	sd	s2,16(sp)
    80004570:	e44e                	sd	s3,8(sp)
    80004572:	1800                	addi	s0,sp,48
    80004574:	892a                	mv	s2,a0
    80004576:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004578:	0001d497          	auipc	s1,0x1d
    8000457c:	68048493          	addi	s1,s1,1664 # 80021bf8 <log>
    80004580:	00004597          	auipc	a1,0x4
    80004584:	0b058593          	addi	a1,a1,176 # 80008630 <syscalls+0x1e8>
    80004588:	8526                	mv	a0,s1
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	5ca080e7          	jalr	1482(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004592:	0149a583          	lw	a1,20(s3)
    80004596:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004598:	0109a783          	lw	a5,16(s3)
    8000459c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000459e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045a2:	854a                	mv	a0,s2
    800045a4:	fffff097          	auipc	ra,0xfffff
    800045a8:	e92080e7          	jalr	-366(ra) # 80003436 <bread>
  log.lh.n = lh->n;
    800045ac:	4d3c                	lw	a5,88(a0)
    800045ae:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045b0:	02f05563          	blez	a5,800045da <initlog+0x74>
    800045b4:	05c50713          	addi	a4,a0,92
    800045b8:	0001d697          	auipc	a3,0x1d
    800045bc:	67068693          	addi	a3,a3,1648 # 80021c28 <log+0x30>
    800045c0:	37fd                	addiw	a5,a5,-1
    800045c2:	1782                	slli	a5,a5,0x20
    800045c4:	9381                	srli	a5,a5,0x20
    800045c6:	078a                	slli	a5,a5,0x2
    800045c8:	06050613          	addi	a2,a0,96
    800045cc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800045ce:	4310                	lw	a2,0(a4)
    800045d0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800045d2:	0711                	addi	a4,a4,4
    800045d4:	0691                	addi	a3,a3,4
    800045d6:	fef71ce3          	bne	a4,a5,800045ce <initlog+0x68>
  brelse(buf);
    800045da:	fffff097          	auipc	ra,0xfffff
    800045de:	f8c080e7          	jalr	-116(ra) # 80003566 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045e2:	4505                	li	a0,1
    800045e4:	00000097          	auipc	ra,0x0
    800045e8:	ebe080e7          	jalr	-322(ra) # 800044a2 <install_trans>
  log.lh.n = 0;
    800045ec:	0001d797          	auipc	a5,0x1d
    800045f0:	6207ac23          	sw	zero,1592(a5) # 80021c24 <log+0x2c>
  write_head(); // clear the log
    800045f4:	00000097          	auipc	ra,0x0
    800045f8:	e34080e7          	jalr	-460(ra) # 80004428 <write_head>
}
    800045fc:	70a2                	ld	ra,40(sp)
    800045fe:	7402                	ld	s0,32(sp)
    80004600:	64e2                	ld	s1,24(sp)
    80004602:	6942                	ld	s2,16(sp)
    80004604:	69a2                	ld	s3,8(sp)
    80004606:	6145                	addi	sp,sp,48
    80004608:	8082                	ret

000000008000460a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000460a:	1101                	addi	sp,sp,-32
    8000460c:	ec06                	sd	ra,24(sp)
    8000460e:	e822                	sd	s0,16(sp)
    80004610:	e426                	sd	s1,8(sp)
    80004612:	e04a                	sd	s2,0(sp)
    80004614:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004616:	0001d517          	auipc	a0,0x1d
    8000461a:	5e250513          	addi	a0,a0,1506 # 80021bf8 <log>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	5c6080e7          	jalr	1478(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004626:	0001d497          	auipc	s1,0x1d
    8000462a:	5d248493          	addi	s1,s1,1490 # 80021bf8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000462e:	4979                	li	s2,30
    80004630:	a039                	j	8000463e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004632:	85a6                	mv	a1,s1
    80004634:	8526                	mv	a0,s1
    80004636:	ffffe097          	auipc	ra,0xffffe
    8000463a:	9ee080e7          	jalr	-1554(ra) # 80002024 <sleep>
    if(log.committing){
    8000463e:	50dc                	lw	a5,36(s1)
    80004640:	fbed                	bnez	a5,80004632 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004642:	509c                	lw	a5,32(s1)
    80004644:	0017871b          	addiw	a4,a5,1
    80004648:	0007069b          	sext.w	a3,a4
    8000464c:	0027179b          	slliw	a5,a4,0x2
    80004650:	9fb9                	addw	a5,a5,a4
    80004652:	0017979b          	slliw	a5,a5,0x1
    80004656:	54d8                	lw	a4,44(s1)
    80004658:	9fb9                	addw	a5,a5,a4
    8000465a:	00f95963          	bge	s2,a5,8000466c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000465e:	85a6                	mv	a1,s1
    80004660:	8526                	mv	a0,s1
    80004662:	ffffe097          	auipc	ra,0xffffe
    80004666:	9c2080e7          	jalr	-1598(ra) # 80002024 <sleep>
    8000466a:	bfd1                	j	8000463e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000466c:	0001d517          	auipc	a0,0x1d
    80004670:	58c50513          	addi	a0,a0,1420 # 80021bf8 <log>
    80004674:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000467e:	60e2                	ld	ra,24(sp)
    80004680:	6442                	ld	s0,16(sp)
    80004682:	64a2                	ld	s1,8(sp)
    80004684:	6902                	ld	s2,0(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret

000000008000468a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000468a:	7139                	addi	sp,sp,-64
    8000468c:	fc06                	sd	ra,56(sp)
    8000468e:	f822                	sd	s0,48(sp)
    80004690:	f426                	sd	s1,40(sp)
    80004692:	f04a                	sd	s2,32(sp)
    80004694:	ec4e                	sd	s3,24(sp)
    80004696:	e852                	sd	s4,16(sp)
    80004698:	e456                	sd	s5,8(sp)
    8000469a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000469c:	0001d497          	auipc	s1,0x1d
    800046a0:	55c48493          	addi	s1,s1,1372 # 80021bf8 <log>
    800046a4:	8526                	mv	a0,s1
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	53e080e7          	jalr	1342(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800046ae:	509c                	lw	a5,32(s1)
    800046b0:	37fd                	addiw	a5,a5,-1
    800046b2:	0007891b          	sext.w	s2,a5
    800046b6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046b8:	50dc                	lw	a5,36(s1)
    800046ba:	efb9                	bnez	a5,80004718 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046bc:	06091663          	bnez	s2,80004728 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800046c0:	0001d497          	auipc	s1,0x1d
    800046c4:	53848493          	addi	s1,s1,1336 # 80021bf8 <log>
    800046c8:	4785                	li	a5,1
    800046ca:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046cc:	8526                	mv	a0,s1
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	5ca080e7          	jalr	1482(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046d6:	54dc                	lw	a5,44(s1)
    800046d8:	06f04763          	bgtz	a5,80004746 <end_op+0xbc>
    acquire(&log.lock);
    800046dc:	0001d497          	auipc	s1,0x1d
    800046e0:	51c48493          	addi	s1,s1,1308 # 80021bf8 <log>
    800046e4:	8526                	mv	a0,s1
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	4fe080e7          	jalr	1278(ra) # 80000be4 <acquire>
    log.committing = 0;
    800046ee:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffe097          	auipc	ra,0xffffe
    800046f8:	cb0080e7          	jalr	-848(ra) # 800023a4 <wakeup>
    release(&log.lock);
    800046fc:	8526                	mv	a0,s1
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	59a080e7          	jalr	1434(ra) # 80000c98 <release>
}
    80004706:	70e2                	ld	ra,56(sp)
    80004708:	7442                	ld	s0,48(sp)
    8000470a:	74a2                	ld	s1,40(sp)
    8000470c:	7902                	ld	s2,32(sp)
    8000470e:	69e2                	ld	s3,24(sp)
    80004710:	6a42                	ld	s4,16(sp)
    80004712:	6aa2                	ld	s5,8(sp)
    80004714:	6121                	addi	sp,sp,64
    80004716:	8082                	ret
    panic("log.committing");
    80004718:	00004517          	auipc	a0,0x4
    8000471c:	f2050513          	addi	a0,a0,-224 # 80008638 <syscalls+0x1f0>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	e1e080e7          	jalr	-482(ra) # 8000053e <panic>
    wakeup(&log);
    80004728:	0001d497          	auipc	s1,0x1d
    8000472c:	4d048493          	addi	s1,s1,1232 # 80021bf8 <log>
    80004730:	8526                	mv	a0,s1
    80004732:	ffffe097          	auipc	ra,0xffffe
    80004736:	c72080e7          	jalr	-910(ra) # 800023a4 <wakeup>
  release(&log.lock);
    8000473a:	8526                	mv	a0,s1
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	55c080e7          	jalr	1372(ra) # 80000c98 <release>
  if(do_commit){
    80004744:	b7c9                	j	80004706 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004746:	0001da97          	auipc	s5,0x1d
    8000474a:	4e2a8a93          	addi	s5,s5,1250 # 80021c28 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000474e:	0001da17          	auipc	s4,0x1d
    80004752:	4aaa0a13          	addi	s4,s4,1194 # 80021bf8 <log>
    80004756:	018a2583          	lw	a1,24(s4)
    8000475a:	012585bb          	addw	a1,a1,s2
    8000475e:	2585                	addiw	a1,a1,1
    80004760:	028a2503          	lw	a0,40(s4)
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	cd2080e7          	jalr	-814(ra) # 80003436 <bread>
    8000476c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000476e:	000aa583          	lw	a1,0(s5)
    80004772:	028a2503          	lw	a0,40(s4)
    80004776:	fffff097          	auipc	ra,0xfffff
    8000477a:	cc0080e7          	jalr	-832(ra) # 80003436 <bread>
    8000477e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004780:	40000613          	li	a2,1024
    80004784:	05850593          	addi	a1,a0,88
    80004788:	05848513          	addi	a0,s1,88
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	5b4080e7          	jalr	1460(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004794:	8526                	mv	a0,s1
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	d92080e7          	jalr	-622(ra) # 80003528 <bwrite>
    brelse(from);
    8000479e:	854e                	mv	a0,s3
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	dc6080e7          	jalr	-570(ra) # 80003566 <brelse>
    brelse(to);
    800047a8:	8526                	mv	a0,s1
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	dbc080e7          	jalr	-580(ra) # 80003566 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047b2:	2905                	addiw	s2,s2,1
    800047b4:	0a91                	addi	s5,s5,4
    800047b6:	02ca2783          	lw	a5,44(s4)
    800047ba:	f8f94ee3          	blt	s2,a5,80004756 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047be:	00000097          	auipc	ra,0x0
    800047c2:	c6a080e7          	jalr	-918(ra) # 80004428 <write_head>
    install_trans(0); // Now install writes to home locations
    800047c6:	4501                	li	a0,0
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	cda080e7          	jalr	-806(ra) # 800044a2 <install_trans>
    log.lh.n = 0;
    800047d0:	0001d797          	auipc	a5,0x1d
    800047d4:	4407aa23          	sw	zero,1108(a5) # 80021c24 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047d8:	00000097          	auipc	ra,0x0
    800047dc:	c50080e7          	jalr	-944(ra) # 80004428 <write_head>
    800047e0:	bdf5                	j	800046dc <end_op+0x52>

00000000800047e2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047e2:	1101                	addi	sp,sp,-32
    800047e4:	ec06                	sd	ra,24(sp)
    800047e6:	e822                	sd	s0,16(sp)
    800047e8:	e426                	sd	s1,8(sp)
    800047ea:	e04a                	sd	s2,0(sp)
    800047ec:	1000                	addi	s0,sp,32
    800047ee:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047f0:	0001d917          	auipc	s2,0x1d
    800047f4:	40890913          	addi	s2,s2,1032 # 80021bf8 <log>
    800047f8:	854a                	mv	a0,s2
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	3ea080e7          	jalr	1002(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004802:	02c92603          	lw	a2,44(s2)
    80004806:	47f5                	li	a5,29
    80004808:	06c7c563          	blt	a5,a2,80004872 <log_write+0x90>
    8000480c:	0001d797          	auipc	a5,0x1d
    80004810:	4087a783          	lw	a5,1032(a5) # 80021c14 <log+0x1c>
    80004814:	37fd                	addiw	a5,a5,-1
    80004816:	04f65e63          	bge	a2,a5,80004872 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000481a:	0001d797          	auipc	a5,0x1d
    8000481e:	3fe7a783          	lw	a5,1022(a5) # 80021c18 <log+0x20>
    80004822:	06f05063          	blez	a5,80004882 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004826:	4781                	li	a5,0
    80004828:	06c05563          	blez	a2,80004892 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000482c:	44cc                	lw	a1,12(s1)
    8000482e:	0001d717          	auipc	a4,0x1d
    80004832:	3fa70713          	addi	a4,a4,1018 # 80021c28 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004836:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004838:	4314                	lw	a3,0(a4)
    8000483a:	04b68c63          	beq	a3,a1,80004892 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000483e:	2785                	addiw	a5,a5,1
    80004840:	0711                	addi	a4,a4,4
    80004842:	fef61be3          	bne	a2,a5,80004838 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004846:	0621                	addi	a2,a2,8
    80004848:	060a                	slli	a2,a2,0x2
    8000484a:	0001d797          	auipc	a5,0x1d
    8000484e:	3ae78793          	addi	a5,a5,942 # 80021bf8 <log>
    80004852:	963e                	add	a2,a2,a5
    80004854:	44dc                	lw	a5,12(s1)
    80004856:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004858:	8526                	mv	a0,s1
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	daa080e7          	jalr	-598(ra) # 80003604 <bpin>
    log.lh.n++;
    80004862:	0001d717          	auipc	a4,0x1d
    80004866:	39670713          	addi	a4,a4,918 # 80021bf8 <log>
    8000486a:	575c                	lw	a5,44(a4)
    8000486c:	2785                	addiw	a5,a5,1
    8000486e:	d75c                	sw	a5,44(a4)
    80004870:	a835                	j	800048ac <log_write+0xca>
    panic("too big a transaction");
    80004872:	00004517          	auipc	a0,0x4
    80004876:	dd650513          	addi	a0,a0,-554 # 80008648 <syscalls+0x200>
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	cc4080e7          	jalr	-828(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004882:	00004517          	auipc	a0,0x4
    80004886:	dde50513          	addi	a0,a0,-546 # 80008660 <syscalls+0x218>
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	cb4080e7          	jalr	-844(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004892:	00878713          	addi	a4,a5,8
    80004896:	00271693          	slli	a3,a4,0x2
    8000489a:	0001d717          	auipc	a4,0x1d
    8000489e:	35e70713          	addi	a4,a4,862 # 80021bf8 <log>
    800048a2:	9736                	add	a4,a4,a3
    800048a4:	44d4                	lw	a3,12(s1)
    800048a6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048a8:	faf608e3          	beq	a2,a5,80004858 <log_write+0x76>
  }
  release(&log.lock);
    800048ac:	0001d517          	auipc	a0,0x1d
    800048b0:	34c50513          	addi	a0,a0,844 # 80021bf8 <log>
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	3e4080e7          	jalr	996(ra) # 80000c98 <release>
}
    800048bc:	60e2                	ld	ra,24(sp)
    800048be:	6442                	ld	s0,16(sp)
    800048c0:	64a2                	ld	s1,8(sp)
    800048c2:	6902                	ld	s2,0(sp)
    800048c4:	6105                	addi	sp,sp,32
    800048c6:	8082                	ret

00000000800048c8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048c8:	1101                	addi	sp,sp,-32
    800048ca:	ec06                	sd	ra,24(sp)
    800048cc:	e822                	sd	s0,16(sp)
    800048ce:	e426                	sd	s1,8(sp)
    800048d0:	e04a                	sd	s2,0(sp)
    800048d2:	1000                	addi	s0,sp,32
    800048d4:	84aa                	mv	s1,a0
    800048d6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048d8:	00004597          	auipc	a1,0x4
    800048dc:	da858593          	addi	a1,a1,-600 # 80008680 <syscalls+0x238>
    800048e0:	0521                	addi	a0,a0,8
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	272080e7          	jalr	626(ra) # 80000b54 <initlock>
  lk->name = name;
    800048ea:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048ee:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048f2:	0204a423          	sw	zero,40(s1)
}
    800048f6:	60e2                	ld	ra,24(sp)
    800048f8:	6442                	ld	s0,16(sp)
    800048fa:	64a2                	ld	s1,8(sp)
    800048fc:	6902                	ld	s2,0(sp)
    800048fe:	6105                	addi	sp,sp,32
    80004900:	8082                	ret

0000000080004902 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004902:	1101                	addi	sp,sp,-32
    80004904:	ec06                	sd	ra,24(sp)
    80004906:	e822                	sd	s0,16(sp)
    80004908:	e426                	sd	s1,8(sp)
    8000490a:	e04a                	sd	s2,0(sp)
    8000490c:	1000                	addi	s0,sp,32
    8000490e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004910:	00850913          	addi	s2,a0,8
    80004914:	854a                	mv	a0,s2
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	2ce080e7          	jalr	718(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000491e:	409c                	lw	a5,0(s1)
    80004920:	cb89                	beqz	a5,80004932 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004922:	85ca                	mv	a1,s2
    80004924:	8526                	mv	a0,s1
    80004926:	ffffd097          	auipc	ra,0xffffd
    8000492a:	6fe080e7          	jalr	1790(ra) # 80002024 <sleep>
  while (lk->locked) {
    8000492e:	409c                	lw	a5,0(s1)
    80004930:	fbed                	bnez	a5,80004922 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004932:	4785                	li	a5,1
    80004934:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004936:	ffffd097          	auipc	ra,0xffffd
    8000493a:	fd0080e7          	jalr	-48(ra) # 80001906 <myproc>
    8000493e:	591c                	lw	a5,48(a0)
    80004940:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004942:	854a                	mv	a0,s2
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	354080e7          	jalr	852(ra) # 80000c98 <release>
}
    8000494c:	60e2                	ld	ra,24(sp)
    8000494e:	6442                	ld	s0,16(sp)
    80004950:	64a2                	ld	s1,8(sp)
    80004952:	6902                	ld	s2,0(sp)
    80004954:	6105                	addi	sp,sp,32
    80004956:	8082                	ret

0000000080004958 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004958:	1101                	addi	sp,sp,-32
    8000495a:	ec06                	sd	ra,24(sp)
    8000495c:	e822                	sd	s0,16(sp)
    8000495e:	e426                	sd	s1,8(sp)
    80004960:	e04a                	sd	s2,0(sp)
    80004962:	1000                	addi	s0,sp,32
    80004964:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004966:	00850913          	addi	s2,a0,8
    8000496a:	854a                	mv	a0,s2
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	278080e7          	jalr	632(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004974:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004978:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000497c:	8526                	mv	a0,s1
    8000497e:	ffffe097          	auipc	ra,0xffffe
    80004982:	a26080e7          	jalr	-1498(ra) # 800023a4 <wakeup>
  release(&lk->lk);
    80004986:	854a                	mv	a0,s2
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	310080e7          	jalr	784(ra) # 80000c98 <release>
}
    80004990:	60e2                	ld	ra,24(sp)
    80004992:	6442                	ld	s0,16(sp)
    80004994:	64a2                	ld	s1,8(sp)
    80004996:	6902                	ld	s2,0(sp)
    80004998:	6105                	addi	sp,sp,32
    8000499a:	8082                	ret

000000008000499c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000499c:	7179                	addi	sp,sp,-48
    8000499e:	f406                	sd	ra,40(sp)
    800049a0:	f022                	sd	s0,32(sp)
    800049a2:	ec26                	sd	s1,24(sp)
    800049a4:	e84a                	sd	s2,16(sp)
    800049a6:	e44e                	sd	s3,8(sp)
    800049a8:	1800                	addi	s0,sp,48
    800049aa:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049ac:	00850913          	addi	s2,a0,8
    800049b0:	854a                	mv	a0,s2
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	232080e7          	jalr	562(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049ba:	409c                	lw	a5,0(s1)
    800049bc:	ef99                	bnez	a5,800049da <holdingsleep+0x3e>
    800049be:	4481                	li	s1,0
  release(&lk->lk);
    800049c0:	854a                	mv	a0,s2
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	2d6080e7          	jalr	726(ra) # 80000c98 <release>
  return r;
}
    800049ca:	8526                	mv	a0,s1
    800049cc:	70a2                	ld	ra,40(sp)
    800049ce:	7402                	ld	s0,32(sp)
    800049d0:	64e2                	ld	s1,24(sp)
    800049d2:	6942                	ld	s2,16(sp)
    800049d4:	69a2                	ld	s3,8(sp)
    800049d6:	6145                	addi	sp,sp,48
    800049d8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049da:	0284a983          	lw	s3,40(s1)
    800049de:	ffffd097          	auipc	ra,0xffffd
    800049e2:	f28080e7          	jalr	-216(ra) # 80001906 <myproc>
    800049e6:	5904                	lw	s1,48(a0)
    800049e8:	413484b3          	sub	s1,s1,s3
    800049ec:	0014b493          	seqz	s1,s1
    800049f0:	bfc1                	j	800049c0 <holdingsleep+0x24>

00000000800049f2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049f2:	1141                	addi	sp,sp,-16
    800049f4:	e406                	sd	ra,8(sp)
    800049f6:	e022                	sd	s0,0(sp)
    800049f8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049fa:	00004597          	auipc	a1,0x4
    800049fe:	c9658593          	addi	a1,a1,-874 # 80008690 <syscalls+0x248>
    80004a02:	0001d517          	auipc	a0,0x1d
    80004a06:	33e50513          	addi	a0,a0,830 # 80021d40 <ftable>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	14a080e7          	jalr	330(ra) # 80000b54 <initlock>
}
    80004a12:	60a2                	ld	ra,8(sp)
    80004a14:	6402                	ld	s0,0(sp)
    80004a16:	0141                	addi	sp,sp,16
    80004a18:	8082                	ret

0000000080004a1a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a1a:	1101                	addi	sp,sp,-32
    80004a1c:	ec06                	sd	ra,24(sp)
    80004a1e:	e822                	sd	s0,16(sp)
    80004a20:	e426                	sd	s1,8(sp)
    80004a22:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a24:	0001d517          	auipc	a0,0x1d
    80004a28:	31c50513          	addi	a0,a0,796 # 80021d40 <ftable>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	1b8080e7          	jalr	440(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a34:	0001d497          	auipc	s1,0x1d
    80004a38:	32448493          	addi	s1,s1,804 # 80021d58 <ftable+0x18>
    80004a3c:	0001e717          	auipc	a4,0x1e
    80004a40:	2bc70713          	addi	a4,a4,700 # 80022cf8 <ftable+0xfb8>
    if(f->ref == 0){
    80004a44:	40dc                	lw	a5,4(s1)
    80004a46:	cf99                	beqz	a5,80004a64 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a48:	02848493          	addi	s1,s1,40
    80004a4c:	fee49ce3          	bne	s1,a4,80004a44 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a50:	0001d517          	auipc	a0,0x1d
    80004a54:	2f050513          	addi	a0,a0,752 # 80021d40 <ftable>
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	240080e7          	jalr	576(ra) # 80000c98 <release>
  return 0;
    80004a60:	4481                	li	s1,0
    80004a62:	a819                	j	80004a78 <filealloc+0x5e>
      f->ref = 1;
    80004a64:	4785                	li	a5,1
    80004a66:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a68:	0001d517          	auipc	a0,0x1d
    80004a6c:	2d850513          	addi	a0,a0,728 # 80021d40 <ftable>
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	228080e7          	jalr	552(ra) # 80000c98 <release>
}
    80004a78:	8526                	mv	a0,s1
    80004a7a:	60e2                	ld	ra,24(sp)
    80004a7c:	6442                	ld	s0,16(sp)
    80004a7e:	64a2                	ld	s1,8(sp)
    80004a80:	6105                	addi	sp,sp,32
    80004a82:	8082                	ret

0000000080004a84 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a84:	1101                	addi	sp,sp,-32
    80004a86:	ec06                	sd	ra,24(sp)
    80004a88:	e822                	sd	s0,16(sp)
    80004a8a:	e426                	sd	s1,8(sp)
    80004a8c:	1000                	addi	s0,sp,32
    80004a8e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a90:	0001d517          	auipc	a0,0x1d
    80004a94:	2b050513          	addi	a0,a0,688 # 80021d40 <ftable>
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	14c080e7          	jalr	332(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004aa0:	40dc                	lw	a5,4(s1)
    80004aa2:	02f05263          	blez	a5,80004ac6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004aa6:	2785                	addiw	a5,a5,1
    80004aa8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004aaa:	0001d517          	auipc	a0,0x1d
    80004aae:	29650513          	addi	a0,a0,662 # 80021d40 <ftable>
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	1e6080e7          	jalr	486(ra) # 80000c98 <release>
  return f;
}
    80004aba:	8526                	mv	a0,s1
    80004abc:	60e2                	ld	ra,24(sp)
    80004abe:	6442                	ld	s0,16(sp)
    80004ac0:	64a2                	ld	s1,8(sp)
    80004ac2:	6105                	addi	sp,sp,32
    80004ac4:	8082                	ret
    panic("filedup");
    80004ac6:	00004517          	auipc	a0,0x4
    80004aca:	bd250513          	addi	a0,a0,-1070 # 80008698 <syscalls+0x250>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	a70080e7          	jalr	-1424(ra) # 8000053e <panic>

0000000080004ad6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ad6:	7139                	addi	sp,sp,-64
    80004ad8:	fc06                	sd	ra,56(sp)
    80004ada:	f822                	sd	s0,48(sp)
    80004adc:	f426                	sd	s1,40(sp)
    80004ade:	f04a                	sd	s2,32(sp)
    80004ae0:	ec4e                	sd	s3,24(sp)
    80004ae2:	e852                	sd	s4,16(sp)
    80004ae4:	e456                	sd	s5,8(sp)
    80004ae6:	0080                	addi	s0,sp,64
    80004ae8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004aea:	0001d517          	auipc	a0,0x1d
    80004aee:	25650513          	addi	a0,a0,598 # 80021d40 <ftable>
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	0f2080e7          	jalr	242(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004afa:	40dc                	lw	a5,4(s1)
    80004afc:	06f05163          	blez	a5,80004b5e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b00:	37fd                	addiw	a5,a5,-1
    80004b02:	0007871b          	sext.w	a4,a5
    80004b06:	c0dc                	sw	a5,4(s1)
    80004b08:	06e04363          	bgtz	a4,80004b6e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b0c:	0004a903          	lw	s2,0(s1)
    80004b10:	0094ca83          	lbu	s5,9(s1)
    80004b14:	0104ba03          	ld	s4,16(s1)
    80004b18:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b1c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b20:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b24:	0001d517          	auipc	a0,0x1d
    80004b28:	21c50513          	addi	a0,a0,540 # 80021d40 <ftable>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	16c080e7          	jalr	364(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b34:	4785                	li	a5,1
    80004b36:	04f90d63          	beq	s2,a5,80004b90 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b3a:	3979                	addiw	s2,s2,-2
    80004b3c:	4785                	li	a5,1
    80004b3e:	0527e063          	bltu	a5,s2,80004b7e <fileclose+0xa8>
    begin_op();
    80004b42:	00000097          	auipc	ra,0x0
    80004b46:	ac8080e7          	jalr	-1336(ra) # 8000460a <begin_op>
    iput(ff.ip);
    80004b4a:	854e                	mv	a0,s3
    80004b4c:	fffff097          	auipc	ra,0xfffff
    80004b50:	2a6080e7          	jalr	678(ra) # 80003df2 <iput>
    end_op();
    80004b54:	00000097          	auipc	ra,0x0
    80004b58:	b36080e7          	jalr	-1226(ra) # 8000468a <end_op>
    80004b5c:	a00d                	j	80004b7e <fileclose+0xa8>
    panic("fileclose");
    80004b5e:	00004517          	auipc	a0,0x4
    80004b62:	b4250513          	addi	a0,a0,-1214 # 800086a0 <syscalls+0x258>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	9d8080e7          	jalr	-1576(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b6e:	0001d517          	auipc	a0,0x1d
    80004b72:	1d250513          	addi	a0,a0,466 # 80021d40 <ftable>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	122080e7          	jalr	290(ra) # 80000c98 <release>
  }
}
    80004b7e:	70e2                	ld	ra,56(sp)
    80004b80:	7442                	ld	s0,48(sp)
    80004b82:	74a2                	ld	s1,40(sp)
    80004b84:	7902                	ld	s2,32(sp)
    80004b86:	69e2                	ld	s3,24(sp)
    80004b88:	6a42                	ld	s4,16(sp)
    80004b8a:	6aa2                	ld	s5,8(sp)
    80004b8c:	6121                	addi	sp,sp,64
    80004b8e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b90:	85d6                	mv	a1,s5
    80004b92:	8552                	mv	a0,s4
    80004b94:	00000097          	auipc	ra,0x0
    80004b98:	34c080e7          	jalr	844(ra) # 80004ee0 <pipeclose>
    80004b9c:	b7cd                	j	80004b7e <fileclose+0xa8>

0000000080004b9e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b9e:	715d                	addi	sp,sp,-80
    80004ba0:	e486                	sd	ra,72(sp)
    80004ba2:	e0a2                	sd	s0,64(sp)
    80004ba4:	fc26                	sd	s1,56(sp)
    80004ba6:	f84a                	sd	s2,48(sp)
    80004ba8:	f44e                	sd	s3,40(sp)
    80004baa:	0880                	addi	s0,sp,80
    80004bac:	84aa                	mv	s1,a0
    80004bae:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bb0:	ffffd097          	auipc	ra,0xffffd
    80004bb4:	d56080e7          	jalr	-682(ra) # 80001906 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bb8:	409c                	lw	a5,0(s1)
    80004bba:	37f9                	addiw	a5,a5,-2
    80004bbc:	4705                	li	a4,1
    80004bbe:	04f76763          	bltu	a4,a5,80004c0c <filestat+0x6e>
    80004bc2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bc4:	6c88                	ld	a0,24(s1)
    80004bc6:	fffff097          	auipc	ra,0xfffff
    80004bca:	072080e7          	jalr	114(ra) # 80003c38 <ilock>
    stati(f->ip, &st);
    80004bce:	fb840593          	addi	a1,s0,-72
    80004bd2:	6c88                	ld	a0,24(s1)
    80004bd4:	fffff097          	auipc	ra,0xfffff
    80004bd8:	2ee080e7          	jalr	750(ra) # 80003ec2 <stati>
    iunlock(f->ip);
    80004bdc:	6c88                	ld	a0,24(s1)
    80004bde:	fffff097          	auipc	ra,0xfffff
    80004be2:	11c080e7          	jalr	284(ra) # 80003cfa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004be6:	46e1                	li	a3,24
    80004be8:	fb840613          	addi	a2,s0,-72
    80004bec:	85ce                	mv	a1,s3
    80004bee:	07093503          	ld	a0,112(s2)
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	a80080e7          	jalr	-1408(ra) # 80001672 <copyout>
    80004bfa:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bfe:	60a6                	ld	ra,72(sp)
    80004c00:	6406                	ld	s0,64(sp)
    80004c02:	74e2                	ld	s1,56(sp)
    80004c04:	7942                	ld	s2,48(sp)
    80004c06:	79a2                	ld	s3,40(sp)
    80004c08:	6161                	addi	sp,sp,80
    80004c0a:	8082                	ret
  return -1;
    80004c0c:	557d                	li	a0,-1
    80004c0e:	bfc5                	j	80004bfe <filestat+0x60>

0000000080004c10 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c10:	7179                	addi	sp,sp,-48
    80004c12:	f406                	sd	ra,40(sp)
    80004c14:	f022                	sd	s0,32(sp)
    80004c16:	ec26                	sd	s1,24(sp)
    80004c18:	e84a                	sd	s2,16(sp)
    80004c1a:	e44e                	sd	s3,8(sp)
    80004c1c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c1e:	00854783          	lbu	a5,8(a0)
    80004c22:	c3d5                	beqz	a5,80004cc6 <fileread+0xb6>
    80004c24:	84aa                	mv	s1,a0
    80004c26:	89ae                	mv	s3,a1
    80004c28:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c2a:	411c                	lw	a5,0(a0)
    80004c2c:	4705                	li	a4,1
    80004c2e:	04e78963          	beq	a5,a4,80004c80 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c32:	470d                	li	a4,3
    80004c34:	04e78d63          	beq	a5,a4,80004c8e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c38:	4709                	li	a4,2
    80004c3a:	06e79e63          	bne	a5,a4,80004cb6 <fileread+0xa6>
    ilock(f->ip);
    80004c3e:	6d08                	ld	a0,24(a0)
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	ff8080e7          	jalr	-8(ra) # 80003c38 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c48:	874a                	mv	a4,s2
    80004c4a:	5094                	lw	a3,32(s1)
    80004c4c:	864e                	mv	a2,s3
    80004c4e:	4585                	li	a1,1
    80004c50:	6c88                	ld	a0,24(s1)
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	29a080e7          	jalr	666(ra) # 80003eec <readi>
    80004c5a:	892a                	mv	s2,a0
    80004c5c:	00a05563          	blez	a0,80004c66 <fileread+0x56>
      f->off += r;
    80004c60:	509c                	lw	a5,32(s1)
    80004c62:	9fa9                	addw	a5,a5,a0
    80004c64:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c66:	6c88                	ld	a0,24(s1)
    80004c68:	fffff097          	auipc	ra,0xfffff
    80004c6c:	092080e7          	jalr	146(ra) # 80003cfa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c70:	854a                	mv	a0,s2
    80004c72:	70a2                	ld	ra,40(sp)
    80004c74:	7402                	ld	s0,32(sp)
    80004c76:	64e2                	ld	s1,24(sp)
    80004c78:	6942                	ld	s2,16(sp)
    80004c7a:	69a2                	ld	s3,8(sp)
    80004c7c:	6145                	addi	sp,sp,48
    80004c7e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c80:	6908                	ld	a0,16(a0)
    80004c82:	00000097          	auipc	ra,0x0
    80004c86:	3c8080e7          	jalr	968(ra) # 8000504a <piperead>
    80004c8a:	892a                	mv	s2,a0
    80004c8c:	b7d5                	j	80004c70 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c8e:	02451783          	lh	a5,36(a0)
    80004c92:	03079693          	slli	a3,a5,0x30
    80004c96:	92c1                	srli	a3,a3,0x30
    80004c98:	4725                	li	a4,9
    80004c9a:	02d76863          	bltu	a4,a3,80004cca <fileread+0xba>
    80004c9e:	0792                	slli	a5,a5,0x4
    80004ca0:	0001d717          	auipc	a4,0x1d
    80004ca4:	00070713          	mv	a4,a4
    80004ca8:	97ba                	add	a5,a5,a4
    80004caa:	639c                	ld	a5,0(a5)
    80004cac:	c38d                	beqz	a5,80004cce <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cae:	4505                	li	a0,1
    80004cb0:	9782                	jalr	a5
    80004cb2:	892a                	mv	s2,a0
    80004cb4:	bf75                	j	80004c70 <fileread+0x60>
    panic("fileread");
    80004cb6:	00004517          	auipc	a0,0x4
    80004cba:	9fa50513          	addi	a0,a0,-1542 # 800086b0 <syscalls+0x268>
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>
    return -1;
    80004cc6:	597d                	li	s2,-1
    80004cc8:	b765                	j	80004c70 <fileread+0x60>
      return -1;
    80004cca:	597d                	li	s2,-1
    80004ccc:	b755                	j	80004c70 <fileread+0x60>
    80004cce:	597d                	li	s2,-1
    80004cd0:	b745                	j	80004c70 <fileread+0x60>

0000000080004cd2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cd2:	715d                	addi	sp,sp,-80
    80004cd4:	e486                	sd	ra,72(sp)
    80004cd6:	e0a2                	sd	s0,64(sp)
    80004cd8:	fc26                	sd	s1,56(sp)
    80004cda:	f84a                	sd	s2,48(sp)
    80004cdc:	f44e                	sd	s3,40(sp)
    80004cde:	f052                	sd	s4,32(sp)
    80004ce0:	ec56                	sd	s5,24(sp)
    80004ce2:	e85a                	sd	s6,16(sp)
    80004ce4:	e45e                	sd	s7,8(sp)
    80004ce6:	e062                	sd	s8,0(sp)
    80004ce8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cea:	00954783          	lbu	a5,9(a0)
    80004cee:	10078663          	beqz	a5,80004dfa <filewrite+0x128>
    80004cf2:	892a                	mv	s2,a0
    80004cf4:	8aae                	mv	s5,a1
    80004cf6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cf8:	411c                	lw	a5,0(a0)
    80004cfa:	4705                	li	a4,1
    80004cfc:	02e78263          	beq	a5,a4,80004d20 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d00:	470d                	li	a4,3
    80004d02:	02e78663          	beq	a5,a4,80004d2e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d06:	4709                	li	a4,2
    80004d08:	0ee79163          	bne	a5,a4,80004dea <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d0c:	0ac05d63          	blez	a2,80004dc6 <filewrite+0xf4>
    int i = 0;
    80004d10:	4981                	li	s3,0
    80004d12:	6b05                	lui	s6,0x1
    80004d14:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d18:	6b85                	lui	s7,0x1
    80004d1a:	c00b8b9b          	addiw	s7,s7,-1024
    80004d1e:	a861                	j	80004db6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d20:	6908                	ld	a0,16(a0)
    80004d22:	00000097          	auipc	ra,0x0
    80004d26:	22e080e7          	jalr	558(ra) # 80004f50 <pipewrite>
    80004d2a:	8a2a                	mv	s4,a0
    80004d2c:	a045                	j	80004dcc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d2e:	02451783          	lh	a5,36(a0)
    80004d32:	03079693          	slli	a3,a5,0x30
    80004d36:	92c1                	srli	a3,a3,0x30
    80004d38:	4725                	li	a4,9
    80004d3a:	0cd76263          	bltu	a4,a3,80004dfe <filewrite+0x12c>
    80004d3e:	0792                	slli	a5,a5,0x4
    80004d40:	0001d717          	auipc	a4,0x1d
    80004d44:	f6070713          	addi	a4,a4,-160 # 80021ca0 <devsw>
    80004d48:	97ba                	add	a5,a5,a4
    80004d4a:	679c                	ld	a5,8(a5)
    80004d4c:	cbdd                	beqz	a5,80004e02 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d4e:	4505                	li	a0,1
    80004d50:	9782                	jalr	a5
    80004d52:	8a2a                	mv	s4,a0
    80004d54:	a8a5                	j	80004dcc <filewrite+0xfa>
    80004d56:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d5a:	00000097          	auipc	ra,0x0
    80004d5e:	8b0080e7          	jalr	-1872(ra) # 8000460a <begin_op>
      ilock(f->ip);
    80004d62:	01893503          	ld	a0,24(s2)
    80004d66:	fffff097          	auipc	ra,0xfffff
    80004d6a:	ed2080e7          	jalr	-302(ra) # 80003c38 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d6e:	8762                	mv	a4,s8
    80004d70:	02092683          	lw	a3,32(s2)
    80004d74:	01598633          	add	a2,s3,s5
    80004d78:	4585                	li	a1,1
    80004d7a:	01893503          	ld	a0,24(s2)
    80004d7e:	fffff097          	auipc	ra,0xfffff
    80004d82:	266080e7          	jalr	614(ra) # 80003fe4 <writei>
    80004d86:	84aa                	mv	s1,a0
    80004d88:	00a05763          	blez	a0,80004d96 <filewrite+0xc4>
        f->off += r;
    80004d8c:	02092783          	lw	a5,32(s2)
    80004d90:	9fa9                	addw	a5,a5,a0
    80004d92:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d96:	01893503          	ld	a0,24(s2)
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	f60080e7          	jalr	-160(ra) # 80003cfa <iunlock>
      end_op();
    80004da2:	00000097          	auipc	ra,0x0
    80004da6:	8e8080e7          	jalr	-1816(ra) # 8000468a <end_op>

      if(r != n1){
    80004daa:	009c1f63          	bne	s8,s1,80004dc8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004dae:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004db2:	0149db63          	bge	s3,s4,80004dc8 <filewrite+0xf6>
      int n1 = n - i;
    80004db6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004dba:	84be                	mv	s1,a5
    80004dbc:	2781                	sext.w	a5,a5
    80004dbe:	f8fb5ce3          	bge	s6,a5,80004d56 <filewrite+0x84>
    80004dc2:	84de                	mv	s1,s7
    80004dc4:	bf49                	j	80004d56 <filewrite+0x84>
    int i = 0;
    80004dc6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004dc8:	013a1f63          	bne	s4,s3,80004de6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dcc:	8552                	mv	a0,s4
    80004dce:	60a6                	ld	ra,72(sp)
    80004dd0:	6406                	ld	s0,64(sp)
    80004dd2:	74e2                	ld	s1,56(sp)
    80004dd4:	7942                	ld	s2,48(sp)
    80004dd6:	79a2                	ld	s3,40(sp)
    80004dd8:	7a02                	ld	s4,32(sp)
    80004dda:	6ae2                	ld	s5,24(sp)
    80004ddc:	6b42                	ld	s6,16(sp)
    80004dde:	6ba2                	ld	s7,8(sp)
    80004de0:	6c02                	ld	s8,0(sp)
    80004de2:	6161                	addi	sp,sp,80
    80004de4:	8082                	ret
    ret = (i == n ? n : -1);
    80004de6:	5a7d                	li	s4,-1
    80004de8:	b7d5                	j	80004dcc <filewrite+0xfa>
    panic("filewrite");
    80004dea:	00004517          	auipc	a0,0x4
    80004dee:	8d650513          	addi	a0,a0,-1834 # 800086c0 <syscalls+0x278>
    80004df2:	ffffb097          	auipc	ra,0xffffb
    80004df6:	74c080e7          	jalr	1868(ra) # 8000053e <panic>
    return -1;
    80004dfa:	5a7d                	li	s4,-1
    80004dfc:	bfc1                	j	80004dcc <filewrite+0xfa>
      return -1;
    80004dfe:	5a7d                	li	s4,-1
    80004e00:	b7f1                	j	80004dcc <filewrite+0xfa>
    80004e02:	5a7d                	li	s4,-1
    80004e04:	b7e1                	j	80004dcc <filewrite+0xfa>

0000000080004e06 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e06:	7179                	addi	sp,sp,-48
    80004e08:	f406                	sd	ra,40(sp)
    80004e0a:	f022                	sd	s0,32(sp)
    80004e0c:	ec26                	sd	s1,24(sp)
    80004e0e:	e84a                	sd	s2,16(sp)
    80004e10:	e44e                	sd	s3,8(sp)
    80004e12:	e052                	sd	s4,0(sp)
    80004e14:	1800                	addi	s0,sp,48
    80004e16:	84aa                	mv	s1,a0
    80004e18:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e1a:	0005b023          	sd	zero,0(a1)
    80004e1e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e22:	00000097          	auipc	ra,0x0
    80004e26:	bf8080e7          	jalr	-1032(ra) # 80004a1a <filealloc>
    80004e2a:	e088                	sd	a0,0(s1)
    80004e2c:	c551                	beqz	a0,80004eb8 <pipealloc+0xb2>
    80004e2e:	00000097          	auipc	ra,0x0
    80004e32:	bec080e7          	jalr	-1044(ra) # 80004a1a <filealloc>
    80004e36:	00aa3023          	sd	a0,0(s4)
    80004e3a:	c92d                	beqz	a0,80004eac <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	cb8080e7          	jalr	-840(ra) # 80000af4 <kalloc>
    80004e44:	892a                	mv	s2,a0
    80004e46:	c125                	beqz	a0,80004ea6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e48:	4985                	li	s3,1
    80004e4a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e4e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e52:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e56:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e5a:	00004597          	auipc	a1,0x4
    80004e5e:	87658593          	addi	a1,a1,-1930 # 800086d0 <syscalls+0x288>
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	cf2080e7          	jalr	-782(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e6a:	609c                	ld	a5,0(s1)
    80004e6c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e70:	609c                	ld	a5,0(s1)
    80004e72:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e76:	609c                	ld	a5,0(s1)
    80004e78:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e7c:	609c                	ld	a5,0(s1)
    80004e7e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e82:	000a3783          	ld	a5,0(s4)
    80004e86:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e8a:	000a3783          	ld	a5,0(s4)
    80004e8e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e92:	000a3783          	ld	a5,0(s4)
    80004e96:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e9a:	000a3783          	ld	a5,0(s4)
    80004e9e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ea2:	4501                	li	a0,0
    80004ea4:	a025                	j	80004ecc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ea6:	6088                	ld	a0,0(s1)
    80004ea8:	e501                	bnez	a0,80004eb0 <pipealloc+0xaa>
    80004eaa:	a039                	j	80004eb8 <pipealloc+0xb2>
    80004eac:	6088                	ld	a0,0(s1)
    80004eae:	c51d                	beqz	a0,80004edc <pipealloc+0xd6>
    fileclose(*f0);
    80004eb0:	00000097          	auipc	ra,0x0
    80004eb4:	c26080e7          	jalr	-986(ra) # 80004ad6 <fileclose>
  if(*f1)
    80004eb8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ebc:	557d                	li	a0,-1
  if(*f1)
    80004ebe:	c799                	beqz	a5,80004ecc <pipealloc+0xc6>
    fileclose(*f1);
    80004ec0:	853e                	mv	a0,a5
    80004ec2:	00000097          	auipc	ra,0x0
    80004ec6:	c14080e7          	jalr	-1004(ra) # 80004ad6 <fileclose>
  return -1;
    80004eca:	557d                	li	a0,-1
}
    80004ecc:	70a2                	ld	ra,40(sp)
    80004ece:	7402                	ld	s0,32(sp)
    80004ed0:	64e2                	ld	s1,24(sp)
    80004ed2:	6942                	ld	s2,16(sp)
    80004ed4:	69a2                	ld	s3,8(sp)
    80004ed6:	6a02                	ld	s4,0(sp)
    80004ed8:	6145                	addi	sp,sp,48
    80004eda:	8082                	ret
  return -1;
    80004edc:	557d                	li	a0,-1
    80004ede:	b7fd                	j	80004ecc <pipealloc+0xc6>

0000000080004ee0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ee0:	1101                	addi	sp,sp,-32
    80004ee2:	ec06                	sd	ra,24(sp)
    80004ee4:	e822                	sd	s0,16(sp)
    80004ee6:	e426                	sd	s1,8(sp)
    80004ee8:	e04a                	sd	s2,0(sp)
    80004eea:	1000                	addi	s0,sp,32
    80004eec:	84aa                	mv	s1,a0
    80004eee:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	cf4080e7          	jalr	-780(ra) # 80000be4 <acquire>
  if(writable){
    80004ef8:	02090d63          	beqz	s2,80004f32 <pipeclose+0x52>
    pi->writeopen = 0;
    80004efc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f00:	21848513          	addi	a0,s1,536
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	4a0080e7          	jalr	1184(ra) # 800023a4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f0c:	2204b783          	ld	a5,544(s1)
    80004f10:	eb95                	bnez	a5,80004f44 <pipeclose+0x64>
    release(&pi->lock);
    80004f12:	8526                	mv	a0,s1
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	d84080e7          	jalr	-636(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004f1c:	8526                	mv	a0,s1
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	ada080e7          	jalr	-1318(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f26:	60e2                	ld	ra,24(sp)
    80004f28:	6442                	ld	s0,16(sp)
    80004f2a:	64a2                	ld	s1,8(sp)
    80004f2c:	6902                	ld	s2,0(sp)
    80004f2e:	6105                	addi	sp,sp,32
    80004f30:	8082                	ret
    pi->readopen = 0;
    80004f32:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f36:	21c48513          	addi	a0,s1,540
    80004f3a:	ffffd097          	auipc	ra,0xffffd
    80004f3e:	46a080e7          	jalr	1130(ra) # 800023a4 <wakeup>
    80004f42:	b7e9                	j	80004f0c <pipeclose+0x2c>
    release(&pi->lock);
    80004f44:	8526                	mv	a0,s1
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	d52080e7          	jalr	-686(ra) # 80000c98 <release>
}
    80004f4e:	bfe1                	j	80004f26 <pipeclose+0x46>

0000000080004f50 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f50:	7159                	addi	sp,sp,-112
    80004f52:	f486                	sd	ra,104(sp)
    80004f54:	f0a2                	sd	s0,96(sp)
    80004f56:	eca6                	sd	s1,88(sp)
    80004f58:	e8ca                	sd	s2,80(sp)
    80004f5a:	e4ce                	sd	s3,72(sp)
    80004f5c:	e0d2                	sd	s4,64(sp)
    80004f5e:	fc56                	sd	s5,56(sp)
    80004f60:	f85a                	sd	s6,48(sp)
    80004f62:	f45e                	sd	s7,40(sp)
    80004f64:	f062                	sd	s8,32(sp)
    80004f66:	ec66                	sd	s9,24(sp)
    80004f68:	1880                	addi	s0,sp,112
    80004f6a:	84aa                	mv	s1,a0
    80004f6c:	8aae                	mv	s5,a1
    80004f6e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f70:	ffffd097          	auipc	ra,0xffffd
    80004f74:	996080e7          	jalr	-1642(ra) # 80001906 <myproc>
    80004f78:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f7a:	8526                	mv	a0,s1
    80004f7c:	ffffc097          	auipc	ra,0xffffc
    80004f80:	c68080e7          	jalr	-920(ra) # 80000be4 <acquire>
  while(i < n){
    80004f84:	0d405163          	blez	s4,80005046 <pipewrite+0xf6>
    80004f88:	8ba6                	mv	s7,s1
  int i = 0;
    80004f8a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f8c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f8e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f92:	21c48c13          	addi	s8,s1,540
    80004f96:	a08d                	j	80004ff8 <pipewrite+0xa8>
      release(&pi->lock);
    80004f98:	8526                	mv	a0,s1
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	cfe080e7          	jalr	-770(ra) # 80000c98 <release>
      return -1;
    80004fa2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fa4:	854a                	mv	a0,s2
    80004fa6:	70a6                	ld	ra,104(sp)
    80004fa8:	7406                	ld	s0,96(sp)
    80004faa:	64e6                	ld	s1,88(sp)
    80004fac:	6946                	ld	s2,80(sp)
    80004fae:	69a6                	ld	s3,72(sp)
    80004fb0:	6a06                	ld	s4,64(sp)
    80004fb2:	7ae2                	ld	s5,56(sp)
    80004fb4:	7b42                	ld	s6,48(sp)
    80004fb6:	7ba2                	ld	s7,40(sp)
    80004fb8:	7c02                	ld	s8,32(sp)
    80004fba:	6ce2                	ld	s9,24(sp)
    80004fbc:	6165                	addi	sp,sp,112
    80004fbe:	8082                	ret
      wakeup(&pi->nread);
    80004fc0:	8566                	mv	a0,s9
    80004fc2:	ffffd097          	auipc	ra,0xffffd
    80004fc6:	3e2080e7          	jalr	994(ra) # 800023a4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fca:	85de                	mv	a1,s7
    80004fcc:	8562                	mv	a0,s8
    80004fce:	ffffd097          	auipc	ra,0xffffd
    80004fd2:	056080e7          	jalr	86(ra) # 80002024 <sleep>
    80004fd6:	a839                	j	80004ff4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fd8:	21c4a783          	lw	a5,540(s1)
    80004fdc:	0017871b          	addiw	a4,a5,1
    80004fe0:	20e4ae23          	sw	a4,540(s1)
    80004fe4:	1ff7f793          	andi	a5,a5,511
    80004fe8:	97a6                	add	a5,a5,s1
    80004fea:	f9f44703          	lbu	a4,-97(s0)
    80004fee:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ff2:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ff4:	03495d63          	bge	s2,s4,8000502e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004ff8:	2204a783          	lw	a5,544(s1)
    80004ffc:	dfd1                	beqz	a5,80004f98 <pipewrite+0x48>
    80004ffe:	0289a783          	lw	a5,40(s3)
    80005002:	fbd9                	bnez	a5,80004f98 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005004:	2184a783          	lw	a5,536(s1)
    80005008:	21c4a703          	lw	a4,540(s1)
    8000500c:	2007879b          	addiw	a5,a5,512
    80005010:	faf708e3          	beq	a4,a5,80004fc0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005014:	4685                	li	a3,1
    80005016:	01590633          	add	a2,s2,s5
    8000501a:	f9f40593          	addi	a1,s0,-97
    8000501e:	0709b503          	ld	a0,112(s3)
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	6dc080e7          	jalr	1756(ra) # 800016fe <copyin>
    8000502a:	fb6517e3          	bne	a0,s6,80004fd8 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000502e:	21848513          	addi	a0,s1,536
    80005032:	ffffd097          	auipc	ra,0xffffd
    80005036:	372080e7          	jalr	882(ra) # 800023a4 <wakeup>
  release(&pi->lock);
    8000503a:	8526                	mv	a0,s1
    8000503c:	ffffc097          	auipc	ra,0xffffc
    80005040:	c5c080e7          	jalr	-932(ra) # 80000c98 <release>
  return i;
    80005044:	b785                	j	80004fa4 <pipewrite+0x54>
  int i = 0;
    80005046:	4901                	li	s2,0
    80005048:	b7dd                	j	8000502e <pipewrite+0xde>

000000008000504a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000504a:	715d                	addi	sp,sp,-80
    8000504c:	e486                	sd	ra,72(sp)
    8000504e:	e0a2                	sd	s0,64(sp)
    80005050:	fc26                	sd	s1,56(sp)
    80005052:	f84a                	sd	s2,48(sp)
    80005054:	f44e                	sd	s3,40(sp)
    80005056:	f052                	sd	s4,32(sp)
    80005058:	ec56                	sd	s5,24(sp)
    8000505a:	e85a                	sd	s6,16(sp)
    8000505c:	0880                	addi	s0,sp,80
    8000505e:	84aa                	mv	s1,a0
    80005060:	892e                	mv	s2,a1
    80005062:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	8a2080e7          	jalr	-1886(ra) # 80001906 <myproc>
    8000506c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000506e:	8b26                	mv	s6,s1
    80005070:	8526                	mv	a0,s1
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	b72080e7          	jalr	-1166(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000507a:	2184a703          	lw	a4,536(s1)
    8000507e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005082:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005086:	02f71463          	bne	a4,a5,800050ae <piperead+0x64>
    8000508a:	2244a783          	lw	a5,548(s1)
    8000508e:	c385                	beqz	a5,800050ae <piperead+0x64>
    if(pr->killed){
    80005090:	028a2783          	lw	a5,40(s4)
    80005094:	ebc1                	bnez	a5,80005124 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005096:	85da                	mv	a1,s6
    80005098:	854e                	mv	a0,s3
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	f8a080e7          	jalr	-118(ra) # 80002024 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050a2:	2184a703          	lw	a4,536(s1)
    800050a6:	21c4a783          	lw	a5,540(s1)
    800050aa:	fef700e3          	beq	a4,a5,8000508a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ae:	09505263          	blez	s5,80005132 <piperead+0xe8>
    800050b2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050b4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800050b6:	2184a783          	lw	a5,536(s1)
    800050ba:	21c4a703          	lw	a4,540(s1)
    800050be:	02f70d63          	beq	a4,a5,800050f8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050c2:	0017871b          	addiw	a4,a5,1
    800050c6:	20e4ac23          	sw	a4,536(s1)
    800050ca:	1ff7f793          	andi	a5,a5,511
    800050ce:	97a6                	add	a5,a5,s1
    800050d0:	0187c783          	lbu	a5,24(a5)
    800050d4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050d8:	4685                	li	a3,1
    800050da:	fbf40613          	addi	a2,s0,-65
    800050de:	85ca                	mv	a1,s2
    800050e0:	070a3503          	ld	a0,112(s4)
    800050e4:	ffffc097          	auipc	ra,0xffffc
    800050e8:	58e080e7          	jalr	1422(ra) # 80001672 <copyout>
    800050ec:	01650663          	beq	a0,s6,800050f8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050f0:	2985                	addiw	s3,s3,1
    800050f2:	0905                	addi	s2,s2,1
    800050f4:	fd3a91e3          	bne	s5,s3,800050b6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050f8:	21c48513          	addi	a0,s1,540
    800050fc:	ffffd097          	auipc	ra,0xffffd
    80005100:	2a8080e7          	jalr	680(ra) # 800023a4 <wakeup>
  release(&pi->lock);
    80005104:	8526                	mv	a0,s1
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	b92080e7          	jalr	-1134(ra) # 80000c98 <release>
  return i;
}
    8000510e:	854e                	mv	a0,s3
    80005110:	60a6                	ld	ra,72(sp)
    80005112:	6406                	ld	s0,64(sp)
    80005114:	74e2                	ld	s1,56(sp)
    80005116:	7942                	ld	s2,48(sp)
    80005118:	79a2                	ld	s3,40(sp)
    8000511a:	7a02                	ld	s4,32(sp)
    8000511c:	6ae2                	ld	s5,24(sp)
    8000511e:	6b42                	ld	s6,16(sp)
    80005120:	6161                	addi	sp,sp,80
    80005122:	8082                	ret
      release(&pi->lock);
    80005124:	8526                	mv	a0,s1
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	b72080e7          	jalr	-1166(ra) # 80000c98 <release>
      return -1;
    8000512e:	59fd                	li	s3,-1
    80005130:	bff9                	j	8000510e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005132:	4981                	li	s3,0
    80005134:	b7d1                	j	800050f8 <piperead+0xae>

0000000080005136 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005136:	df010113          	addi	sp,sp,-528
    8000513a:	20113423          	sd	ra,520(sp)
    8000513e:	20813023          	sd	s0,512(sp)
    80005142:	ffa6                	sd	s1,504(sp)
    80005144:	fbca                	sd	s2,496(sp)
    80005146:	f7ce                	sd	s3,488(sp)
    80005148:	f3d2                	sd	s4,480(sp)
    8000514a:	efd6                	sd	s5,472(sp)
    8000514c:	ebda                	sd	s6,464(sp)
    8000514e:	e7de                	sd	s7,456(sp)
    80005150:	e3e2                	sd	s8,448(sp)
    80005152:	ff66                	sd	s9,440(sp)
    80005154:	fb6a                	sd	s10,432(sp)
    80005156:	f76e                	sd	s11,424(sp)
    80005158:	0c00                	addi	s0,sp,528
    8000515a:	84aa                	mv	s1,a0
    8000515c:	dea43c23          	sd	a0,-520(s0)
    80005160:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	7a2080e7          	jalr	1954(ra) # 80001906 <myproc>
    8000516c:	892a                	mv	s2,a0

  begin_op();
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	49c080e7          	jalr	1180(ra) # 8000460a <begin_op>

  if((ip = namei(path)) == 0){
    80005176:	8526                	mv	a0,s1
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	276080e7          	jalr	630(ra) # 800043ee <namei>
    80005180:	c92d                	beqz	a0,800051f2 <exec+0xbc>
    80005182:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	ab4080e7          	jalr	-1356(ra) # 80003c38 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000518c:	04000713          	li	a4,64
    80005190:	4681                	li	a3,0
    80005192:	e5040613          	addi	a2,s0,-432
    80005196:	4581                	li	a1,0
    80005198:	8526                	mv	a0,s1
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	d52080e7          	jalr	-686(ra) # 80003eec <readi>
    800051a2:	04000793          	li	a5,64
    800051a6:	00f51a63          	bne	a0,a5,800051ba <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051aa:	e5042703          	lw	a4,-432(s0)
    800051ae:	464c47b7          	lui	a5,0x464c4
    800051b2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051b6:	04f70463          	beq	a4,a5,800051fe <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051ba:	8526                	mv	a0,s1
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	cde080e7          	jalr	-802(ra) # 80003e9a <iunlockput>
    end_op();
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	4c6080e7          	jalr	1222(ra) # 8000468a <end_op>
  }
  return -1;
    800051cc:	557d                	li	a0,-1
}
    800051ce:	20813083          	ld	ra,520(sp)
    800051d2:	20013403          	ld	s0,512(sp)
    800051d6:	74fe                	ld	s1,504(sp)
    800051d8:	795e                	ld	s2,496(sp)
    800051da:	79be                	ld	s3,488(sp)
    800051dc:	7a1e                	ld	s4,480(sp)
    800051de:	6afe                	ld	s5,472(sp)
    800051e0:	6b5e                	ld	s6,464(sp)
    800051e2:	6bbe                	ld	s7,456(sp)
    800051e4:	6c1e                	ld	s8,448(sp)
    800051e6:	7cfa                	ld	s9,440(sp)
    800051e8:	7d5a                	ld	s10,432(sp)
    800051ea:	7dba                	ld	s11,424(sp)
    800051ec:	21010113          	addi	sp,sp,528
    800051f0:	8082                	ret
    end_op();
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	498080e7          	jalr	1176(ra) # 8000468a <end_op>
    return -1;
    800051fa:	557d                	li	a0,-1
    800051fc:	bfc9                	j	800051ce <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051fe:	854a                	mv	a0,s2
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	7c2080e7          	jalr	1986(ra) # 800019c2 <proc_pagetable>
    80005208:	8baa                	mv	s7,a0
    8000520a:	d945                	beqz	a0,800051ba <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000520c:	e7042983          	lw	s3,-400(s0)
    80005210:	e8845783          	lhu	a5,-376(s0)
    80005214:	c7ad                	beqz	a5,8000527e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005216:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005218:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000521a:	6c85                	lui	s9,0x1
    8000521c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005220:	def43823          	sd	a5,-528(s0)
    80005224:	a42d                	j	8000544e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005226:	00003517          	auipc	a0,0x3
    8000522a:	4b250513          	addi	a0,a0,1202 # 800086d8 <syscalls+0x290>
    8000522e:	ffffb097          	auipc	ra,0xffffb
    80005232:	310080e7          	jalr	784(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005236:	8756                	mv	a4,s5
    80005238:	012d86bb          	addw	a3,s11,s2
    8000523c:	4581                	li	a1,0
    8000523e:	8526                	mv	a0,s1
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	cac080e7          	jalr	-852(ra) # 80003eec <readi>
    80005248:	2501                	sext.w	a0,a0
    8000524a:	1aaa9963          	bne	s5,a0,800053fc <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000524e:	6785                	lui	a5,0x1
    80005250:	0127893b          	addw	s2,a5,s2
    80005254:	77fd                	lui	a5,0xfffff
    80005256:	01478a3b          	addw	s4,a5,s4
    8000525a:	1f897163          	bgeu	s2,s8,8000543c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000525e:	02091593          	slli	a1,s2,0x20
    80005262:	9181                	srli	a1,a1,0x20
    80005264:	95ea                	add	a1,a1,s10
    80005266:	855e                	mv	a0,s7
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	e06080e7          	jalr	-506(ra) # 8000106e <walkaddr>
    80005270:	862a                	mv	a2,a0
    if(pa == 0)
    80005272:	d955                	beqz	a0,80005226 <exec+0xf0>
      n = PGSIZE;
    80005274:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005276:	fd9a70e3          	bgeu	s4,s9,80005236 <exec+0x100>
      n = sz - i;
    8000527a:	8ad2                	mv	s5,s4
    8000527c:	bf6d                	j	80005236 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000527e:	4901                	li	s2,0
  iunlockput(ip);
    80005280:	8526                	mv	a0,s1
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	c18080e7          	jalr	-1000(ra) # 80003e9a <iunlockput>
  end_op();
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	400080e7          	jalr	1024(ra) # 8000468a <end_op>
  p = myproc();
    80005292:	ffffc097          	auipc	ra,0xffffc
    80005296:	674080e7          	jalr	1652(ra) # 80001906 <myproc>
    8000529a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000529c:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800052a0:	6785                	lui	a5,0x1
    800052a2:	17fd                	addi	a5,a5,-1
    800052a4:	993e                	add	s2,s2,a5
    800052a6:	757d                	lui	a0,0xfffff
    800052a8:	00a977b3          	and	a5,s2,a0
    800052ac:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052b0:	6609                	lui	a2,0x2
    800052b2:	963e                	add	a2,a2,a5
    800052b4:	85be                	mv	a1,a5
    800052b6:	855e                	mv	a0,s7
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	16a080e7          	jalr	362(ra) # 80001422 <uvmalloc>
    800052c0:	8b2a                	mv	s6,a0
  ip = 0;
    800052c2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052c4:	12050c63          	beqz	a0,800053fc <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052c8:	75f9                	lui	a1,0xffffe
    800052ca:	95aa                	add	a1,a1,a0
    800052cc:	855e                	mv	a0,s7
    800052ce:	ffffc097          	auipc	ra,0xffffc
    800052d2:	372080e7          	jalr	882(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800052d6:	7c7d                	lui	s8,0xfffff
    800052d8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800052da:	e0043783          	ld	a5,-512(s0)
    800052de:	6388                	ld	a0,0(a5)
    800052e0:	c535                	beqz	a0,8000534c <exec+0x216>
    800052e2:	e9040993          	addi	s3,s0,-368
    800052e6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052ea:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052ec:	ffffc097          	auipc	ra,0xffffc
    800052f0:	b78080e7          	jalr	-1160(ra) # 80000e64 <strlen>
    800052f4:	2505                	addiw	a0,a0,1
    800052f6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052fa:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052fe:	13896363          	bltu	s2,s8,80005424 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005302:	e0043d83          	ld	s11,-512(s0)
    80005306:	000dba03          	ld	s4,0(s11)
    8000530a:	8552                	mv	a0,s4
    8000530c:	ffffc097          	auipc	ra,0xffffc
    80005310:	b58080e7          	jalr	-1192(ra) # 80000e64 <strlen>
    80005314:	0015069b          	addiw	a3,a0,1
    80005318:	8652                	mv	a2,s4
    8000531a:	85ca                	mv	a1,s2
    8000531c:	855e                	mv	a0,s7
    8000531e:	ffffc097          	auipc	ra,0xffffc
    80005322:	354080e7          	jalr	852(ra) # 80001672 <copyout>
    80005326:	10054363          	bltz	a0,8000542c <exec+0x2f6>
    ustack[argc] = sp;
    8000532a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000532e:	0485                	addi	s1,s1,1
    80005330:	008d8793          	addi	a5,s11,8
    80005334:	e0f43023          	sd	a5,-512(s0)
    80005338:	008db503          	ld	a0,8(s11)
    8000533c:	c911                	beqz	a0,80005350 <exec+0x21a>
    if(argc >= MAXARG)
    8000533e:	09a1                	addi	s3,s3,8
    80005340:	fb3c96e3          	bne	s9,s3,800052ec <exec+0x1b6>
  sz = sz1;
    80005344:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005348:	4481                	li	s1,0
    8000534a:	a84d                	j	800053fc <exec+0x2c6>
  sp = sz;
    8000534c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000534e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005350:	00349793          	slli	a5,s1,0x3
    80005354:	f9040713          	addi	a4,s0,-112
    80005358:	97ba                	add	a5,a5,a4
    8000535a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000535e:	00148693          	addi	a3,s1,1
    80005362:	068e                	slli	a3,a3,0x3
    80005364:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005368:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000536c:	01897663          	bgeu	s2,s8,80005378 <exec+0x242>
  sz = sz1;
    80005370:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005374:	4481                	li	s1,0
    80005376:	a059                	j	800053fc <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005378:	e9040613          	addi	a2,s0,-368
    8000537c:	85ca                	mv	a1,s2
    8000537e:	855e                	mv	a0,s7
    80005380:	ffffc097          	auipc	ra,0xffffc
    80005384:	2f2080e7          	jalr	754(ra) # 80001672 <copyout>
    80005388:	0a054663          	bltz	a0,80005434 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000538c:	078ab783          	ld	a5,120(s5)
    80005390:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005394:	df843783          	ld	a5,-520(s0)
    80005398:	0007c703          	lbu	a4,0(a5)
    8000539c:	cf11                	beqz	a4,800053b8 <exec+0x282>
    8000539e:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053a0:	02f00693          	li	a3,47
    800053a4:	a039                	j	800053b2 <exec+0x27c>
      last = s+1;
    800053a6:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053aa:	0785                	addi	a5,a5,1
    800053ac:	fff7c703          	lbu	a4,-1(a5)
    800053b0:	c701                	beqz	a4,800053b8 <exec+0x282>
    if(*s == '/')
    800053b2:	fed71ce3          	bne	a4,a3,800053aa <exec+0x274>
    800053b6:	bfc5                	j	800053a6 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800053b8:	4641                	li	a2,16
    800053ba:	df843583          	ld	a1,-520(s0)
    800053be:	178a8513          	addi	a0,s5,376
    800053c2:	ffffc097          	auipc	ra,0xffffc
    800053c6:	a70080e7          	jalr	-1424(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800053ca:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800053ce:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800053d2:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053d6:	078ab783          	ld	a5,120(s5)
    800053da:	e6843703          	ld	a4,-408(s0)
    800053de:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053e0:	078ab783          	ld	a5,120(s5)
    800053e4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053e8:	85ea                	mv	a1,s10
    800053ea:	ffffc097          	auipc	ra,0xffffc
    800053ee:	674080e7          	jalr	1652(ra) # 80001a5e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053f2:	0004851b          	sext.w	a0,s1
    800053f6:	bbe1                	j	800051ce <exec+0x98>
    800053f8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053fc:	e0843583          	ld	a1,-504(s0)
    80005400:	855e                	mv	a0,s7
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	65c080e7          	jalr	1628(ra) # 80001a5e <proc_freepagetable>
  if(ip){
    8000540a:	da0498e3          	bnez	s1,800051ba <exec+0x84>
  return -1;
    8000540e:	557d                	li	a0,-1
    80005410:	bb7d                	j	800051ce <exec+0x98>
    80005412:	e1243423          	sd	s2,-504(s0)
    80005416:	b7dd                	j	800053fc <exec+0x2c6>
    80005418:	e1243423          	sd	s2,-504(s0)
    8000541c:	b7c5                	j	800053fc <exec+0x2c6>
    8000541e:	e1243423          	sd	s2,-504(s0)
    80005422:	bfe9                	j	800053fc <exec+0x2c6>
  sz = sz1;
    80005424:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005428:	4481                	li	s1,0
    8000542a:	bfc9                	j	800053fc <exec+0x2c6>
  sz = sz1;
    8000542c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005430:	4481                	li	s1,0
    80005432:	b7e9                	j	800053fc <exec+0x2c6>
  sz = sz1;
    80005434:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005438:	4481                	li	s1,0
    8000543a:	b7c9                	j	800053fc <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000543c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005440:	2b05                	addiw	s6,s6,1
    80005442:	0389899b          	addiw	s3,s3,56
    80005446:	e8845783          	lhu	a5,-376(s0)
    8000544a:	e2fb5be3          	bge	s6,a5,80005280 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000544e:	2981                	sext.w	s3,s3
    80005450:	03800713          	li	a4,56
    80005454:	86ce                	mv	a3,s3
    80005456:	e1840613          	addi	a2,s0,-488
    8000545a:	4581                	li	a1,0
    8000545c:	8526                	mv	a0,s1
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	a8e080e7          	jalr	-1394(ra) # 80003eec <readi>
    80005466:	03800793          	li	a5,56
    8000546a:	f8f517e3          	bne	a0,a5,800053f8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000546e:	e1842783          	lw	a5,-488(s0)
    80005472:	4705                	li	a4,1
    80005474:	fce796e3          	bne	a5,a4,80005440 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005478:	e4043603          	ld	a2,-448(s0)
    8000547c:	e3843783          	ld	a5,-456(s0)
    80005480:	f8f669e3          	bltu	a2,a5,80005412 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005484:	e2843783          	ld	a5,-472(s0)
    80005488:	963e                	add	a2,a2,a5
    8000548a:	f8f667e3          	bltu	a2,a5,80005418 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000548e:	85ca                	mv	a1,s2
    80005490:	855e                	mv	a0,s7
    80005492:	ffffc097          	auipc	ra,0xffffc
    80005496:	f90080e7          	jalr	-112(ra) # 80001422 <uvmalloc>
    8000549a:	e0a43423          	sd	a0,-504(s0)
    8000549e:	d141                	beqz	a0,8000541e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800054a0:	e2843d03          	ld	s10,-472(s0)
    800054a4:	df043783          	ld	a5,-528(s0)
    800054a8:	00fd77b3          	and	a5,s10,a5
    800054ac:	fba1                	bnez	a5,800053fc <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054ae:	e2042d83          	lw	s11,-480(s0)
    800054b2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054b6:	f80c03e3          	beqz	s8,8000543c <exec+0x306>
    800054ba:	8a62                	mv	s4,s8
    800054bc:	4901                	li	s2,0
    800054be:	b345                	j	8000525e <exec+0x128>

00000000800054c0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054c0:	7179                	addi	sp,sp,-48
    800054c2:	f406                	sd	ra,40(sp)
    800054c4:	f022                	sd	s0,32(sp)
    800054c6:	ec26                	sd	s1,24(sp)
    800054c8:	e84a                	sd	s2,16(sp)
    800054ca:	1800                	addi	s0,sp,48
    800054cc:	892e                	mv	s2,a1
    800054ce:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800054d0:	fdc40593          	addi	a1,s0,-36
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	ba8080e7          	jalr	-1112(ra) # 8000307c <argint>
    800054dc:	04054063          	bltz	a0,8000551c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054e0:	fdc42703          	lw	a4,-36(s0)
    800054e4:	47bd                	li	a5,15
    800054e6:	02e7ed63          	bltu	a5,a4,80005520 <argfd+0x60>
    800054ea:	ffffc097          	auipc	ra,0xffffc
    800054ee:	41c080e7          	jalr	1052(ra) # 80001906 <myproc>
    800054f2:	fdc42703          	lw	a4,-36(s0)
    800054f6:	01e70793          	addi	a5,a4,30
    800054fa:	078e                	slli	a5,a5,0x3
    800054fc:	953e                	add	a0,a0,a5
    800054fe:	611c                	ld	a5,0(a0)
    80005500:	c395                	beqz	a5,80005524 <argfd+0x64>
    return -1;
  if(pfd)
    80005502:	00090463          	beqz	s2,8000550a <argfd+0x4a>
    *pfd = fd;
    80005506:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000550a:	4501                	li	a0,0
  if(pf)
    8000550c:	c091                	beqz	s1,80005510 <argfd+0x50>
    *pf = f;
    8000550e:	e09c                	sd	a5,0(s1)
}
    80005510:	70a2                	ld	ra,40(sp)
    80005512:	7402                	ld	s0,32(sp)
    80005514:	64e2                	ld	s1,24(sp)
    80005516:	6942                	ld	s2,16(sp)
    80005518:	6145                	addi	sp,sp,48
    8000551a:	8082                	ret
    return -1;
    8000551c:	557d                	li	a0,-1
    8000551e:	bfcd                	j	80005510 <argfd+0x50>
    return -1;
    80005520:	557d                	li	a0,-1
    80005522:	b7fd                	j	80005510 <argfd+0x50>
    80005524:	557d                	li	a0,-1
    80005526:	b7ed                	j	80005510 <argfd+0x50>

0000000080005528 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005528:	1101                	addi	sp,sp,-32
    8000552a:	ec06                	sd	ra,24(sp)
    8000552c:	e822                	sd	s0,16(sp)
    8000552e:	e426                	sd	s1,8(sp)
    80005530:	1000                	addi	s0,sp,32
    80005532:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005534:	ffffc097          	auipc	ra,0xffffc
    80005538:	3d2080e7          	jalr	978(ra) # 80001906 <myproc>
    8000553c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000553e:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005542:	4501                	li	a0,0
    80005544:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005546:	6398                	ld	a4,0(a5)
    80005548:	cb19                	beqz	a4,8000555e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000554a:	2505                	addiw	a0,a0,1
    8000554c:	07a1                	addi	a5,a5,8
    8000554e:	fed51ce3          	bne	a0,a3,80005546 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005552:	557d                	li	a0,-1
}
    80005554:	60e2                	ld	ra,24(sp)
    80005556:	6442                	ld	s0,16(sp)
    80005558:	64a2                	ld	s1,8(sp)
    8000555a:	6105                	addi	sp,sp,32
    8000555c:	8082                	ret
      p->ofile[fd] = f;
    8000555e:	01e50793          	addi	a5,a0,30
    80005562:	078e                	slli	a5,a5,0x3
    80005564:	963e                	add	a2,a2,a5
    80005566:	e204                	sd	s1,0(a2)
      return fd;
    80005568:	b7f5                	j	80005554 <fdalloc+0x2c>

000000008000556a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000556a:	715d                	addi	sp,sp,-80
    8000556c:	e486                	sd	ra,72(sp)
    8000556e:	e0a2                	sd	s0,64(sp)
    80005570:	fc26                	sd	s1,56(sp)
    80005572:	f84a                	sd	s2,48(sp)
    80005574:	f44e                	sd	s3,40(sp)
    80005576:	f052                	sd	s4,32(sp)
    80005578:	ec56                	sd	s5,24(sp)
    8000557a:	0880                	addi	s0,sp,80
    8000557c:	89ae                	mv	s3,a1
    8000557e:	8ab2                	mv	s5,a2
    80005580:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005582:	fb040593          	addi	a1,s0,-80
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	e86080e7          	jalr	-378(ra) # 8000440c <nameiparent>
    8000558e:	892a                	mv	s2,a0
    80005590:	12050f63          	beqz	a0,800056ce <create+0x164>
    return 0;

  ilock(dp);
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	6a4080e7          	jalr	1700(ra) # 80003c38 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000559c:	4601                	li	a2,0
    8000559e:	fb040593          	addi	a1,s0,-80
    800055a2:	854a                	mv	a0,s2
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	b78080e7          	jalr	-1160(ra) # 8000411c <dirlookup>
    800055ac:	84aa                	mv	s1,a0
    800055ae:	c921                	beqz	a0,800055fe <create+0x94>
    iunlockput(dp);
    800055b0:	854a                	mv	a0,s2
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	8e8080e7          	jalr	-1816(ra) # 80003e9a <iunlockput>
    ilock(ip);
    800055ba:	8526                	mv	a0,s1
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	67c080e7          	jalr	1660(ra) # 80003c38 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055c4:	2981                	sext.w	s3,s3
    800055c6:	4789                	li	a5,2
    800055c8:	02f99463          	bne	s3,a5,800055f0 <create+0x86>
    800055cc:	0444d783          	lhu	a5,68(s1)
    800055d0:	37f9                	addiw	a5,a5,-2
    800055d2:	17c2                	slli	a5,a5,0x30
    800055d4:	93c1                	srli	a5,a5,0x30
    800055d6:	4705                	li	a4,1
    800055d8:	00f76c63          	bltu	a4,a5,800055f0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800055dc:	8526                	mv	a0,s1
    800055de:	60a6                	ld	ra,72(sp)
    800055e0:	6406                	ld	s0,64(sp)
    800055e2:	74e2                	ld	s1,56(sp)
    800055e4:	7942                	ld	s2,48(sp)
    800055e6:	79a2                	ld	s3,40(sp)
    800055e8:	7a02                	ld	s4,32(sp)
    800055ea:	6ae2                	ld	s5,24(sp)
    800055ec:	6161                	addi	sp,sp,80
    800055ee:	8082                	ret
    iunlockput(ip);
    800055f0:	8526                	mv	a0,s1
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	8a8080e7          	jalr	-1880(ra) # 80003e9a <iunlockput>
    return 0;
    800055fa:	4481                	li	s1,0
    800055fc:	b7c5                	j	800055dc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055fe:	85ce                	mv	a1,s3
    80005600:	00092503          	lw	a0,0(s2)
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	49c080e7          	jalr	1180(ra) # 80003aa0 <ialloc>
    8000560c:	84aa                	mv	s1,a0
    8000560e:	c529                	beqz	a0,80005658 <create+0xee>
  ilock(ip);
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	628080e7          	jalr	1576(ra) # 80003c38 <ilock>
  ip->major = major;
    80005618:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000561c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005620:	4785                	li	a5,1
    80005622:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	546080e7          	jalr	1350(ra) # 80003b6e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005630:	2981                	sext.w	s3,s3
    80005632:	4785                	li	a5,1
    80005634:	02f98a63          	beq	s3,a5,80005668 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005638:	40d0                	lw	a2,4(s1)
    8000563a:	fb040593          	addi	a1,s0,-80
    8000563e:	854a                	mv	a0,s2
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	cec080e7          	jalr	-788(ra) # 8000432c <dirlink>
    80005648:	06054b63          	bltz	a0,800056be <create+0x154>
  iunlockput(dp);
    8000564c:	854a                	mv	a0,s2
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	84c080e7          	jalr	-1972(ra) # 80003e9a <iunlockput>
  return ip;
    80005656:	b759                	j	800055dc <create+0x72>
    panic("create: ialloc");
    80005658:	00003517          	auipc	a0,0x3
    8000565c:	0a050513          	addi	a0,a0,160 # 800086f8 <syscalls+0x2b0>
    80005660:	ffffb097          	auipc	ra,0xffffb
    80005664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005668:	04a95783          	lhu	a5,74(s2)
    8000566c:	2785                	addiw	a5,a5,1
    8000566e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005672:	854a                	mv	a0,s2
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	4fa080e7          	jalr	1274(ra) # 80003b6e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000567c:	40d0                	lw	a2,4(s1)
    8000567e:	00003597          	auipc	a1,0x3
    80005682:	08a58593          	addi	a1,a1,138 # 80008708 <syscalls+0x2c0>
    80005686:	8526                	mv	a0,s1
    80005688:	fffff097          	auipc	ra,0xfffff
    8000568c:	ca4080e7          	jalr	-860(ra) # 8000432c <dirlink>
    80005690:	00054f63          	bltz	a0,800056ae <create+0x144>
    80005694:	00492603          	lw	a2,4(s2)
    80005698:	00003597          	auipc	a1,0x3
    8000569c:	07858593          	addi	a1,a1,120 # 80008710 <syscalls+0x2c8>
    800056a0:	8526                	mv	a0,s1
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	c8a080e7          	jalr	-886(ra) # 8000432c <dirlink>
    800056aa:	f80557e3          	bgez	a0,80005638 <create+0xce>
      panic("create dots");
    800056ae:	00003517          	auipc	a0,0x3
    800056b2:	06a50513          	addi	a0,a0,106 # 80008718 <syscalls+0x2d0>
    800056b6:	ffffb097          	auipc	ra,0xffffb
    800056ba:	e88080e7          	jalr	-376(ra) # 8000053e <panic>
    panic("create: dirlink");
    800056be:	00003517          	auipc	a0,0x3
    800056c2:	06a50513          	addi	a0,a0,106 # 80008728 <syscalls+0x2e0>
    800056c6:	ffffb097          	auipc	ra,0xffffb
    800056ca:	e78080e7          	jalr	-392(ra) # 8000053e <panic>
    return 0;
    800056ce:	84aa                	mv	s1,a0
    800056d0:	b731                	j	800055dc <create+0x72>

00000000800056d2 <sys_dup>:
{
    800056d2:	7179                	addi	sp,sp,-48
    800056d4:	f406                	sd	ra,40(sp)
    800056d6:	f022                	sd	s0,32(sp)
    800056d8:	ec26                	sd	s1,24(sp)
    800056da:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056dc:	fd840613          	addi	a2,s0,-40
    800056e0:	4581                	li	a1,0
    800056e2:	4501                	li	a0,0
    800056e4:	00000097          	auipc	ra,0x0
    800056e8:	ddc080e7          	jalr	-548(ra) # 800054c0 <argfd>
    return -1;
    800056ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056ee:	02054363          	bltz	a0,80005714 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056f2:	fd843503          	ld	a0,-40(s0)
    800056f6:	00000097          	auipc	ra,0x0
    800056fa:	e32080e7          	jalr	-462(ra) # 80005528 <fdalloc>
    800056fe:	84aa                	mv	s1,a0
    return -1;
    80005700:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005702:	00054963          	bltz	a0,80005714 <sys_dup+0x42>
  filedup(f);
    80005706:	fd843503          	ld	a0,-40(s0)
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	37a080e7          	jalr	890(ra) # 80004a84 <filedup>
  return fd;
    80005712:	87a6                	mv	a5,s1
}
    80005714:	853e                	mv	a0,a5
    80005716:	70a2                	ld	ra,40(sp)
    80005718:	7402                	ld	s0,32(sp)
    8000571a:	64e2                	ld	s1,24(sp)
    8000571c:	6145                	addi	sp,sp,48
    8000571e:	8082                	ret

0000000080005720 <sys_read>:
{
    80005720:	7179                	addi	sp,sp,-48
    80005722:	f406                	sd	ra,40(sp)
    80005724:	f022                	sd	s0,32(sp)
    80005726:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005728:	fe840613          	addi	a2,s0,-24
    8000572c:	4581                	li	a1,0
    8000572e:	4501                	li	a0,0
    80005730:	00000097          	auipc	ra,0x0
    80005734:	d90080e7          	jalr	-624(ra) # 800054c0 <argfd>
    return -1;
    80005738:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000573a:	04054163          	bltz	a0,8000577c <sys_read+0x5c>
    8000573e:	fe440593          	addi	a1,s0,-28
    80005742:	4509                	li	a0,2
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	938080e7          	jalr	-1736(ra) # 8000307c <argint>
    return -1;
    8000574c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000574e:	02054763          	bltz	a0,8000577c <sys_read+0x5c>
    80005752:	fd840593          	addi	a1,s0,-40
    80005756:	4505                	li	a0,1
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	946080e7          	jalr	-1722(ra) # 8000309e <argaddr>
    return -1;
    80005760:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005762:	00054d63          	bltz	a0,8000577c <sys_read+0x5c>
  return fileread(f, p, n);
    80005766:	fe442603          	lw	a2,-28(s0)
    8000576a:	fd843583          	ld	a1,-40(s0)
    8000576e:	fe843503          	ld	a0,-24(s0)
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	49e080e7          	jalr	1182(ra) # 80004c10 <fileread>
    8000577a:	87aa                	mv	a5,a0
}
    8000577c:	853e                	mv	a0,a5
    8000577e:	70a2                	ld	ra,40(sp)
    80005780:	7402                	ld	s0,32(sp)
    80005782:	6145                	addi	sp,sp,48
    80005784:	8082                	ret

0000000080005786 <sys_write>:
{
    80005786:	7179                	addi	sp,sp,-48
    80005788:	f406                	sd	ra,40(sp)
    8000578a:	f022                	sd	s0,32(sp)
    8000578c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000578e:	fe840613          	addi	a2,s0,-24
    80005792:	4581                	li	a1,0
    80005794:	4501                	li	a0,0
    80005796:	00000097          	auipc	ra,0x0
    8000579a:	d2a080e7          	jalr	-726(ra) # 800054c0 <argfd>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a0:	04054163          	bltz	a0,800057e2 <sys_write+0x5c>
    800057a4:	fe440593          	addi	a1,s0,-28
    800057a8:	4509                	li	a0,2
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	8d2080e7          	jalr	-1838(ra) # 8000307c <argint>
    return -1;
    800057b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057b4:	02054763          	bltz	a0,800057e2 <sys_write+0x5c>
    800057b8:	fd840593          	addi	a1,s0,-40
    800057bc:	4505                	li	a0,1
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	8e0080e7          	jalr	-1824(ra) # 8000309e <argaddr>
    return -1;
    800057c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057c8:	00054d63          	bltz	a0,800057e2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800057cc:	fe442603          	lw	a2,-28(s0)
    800057d0:	fd843583          	ld	a1,-40(s0)
    800057d4:	fe843503          	ld	a0,-24(s0)
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	4fa080e7          	jalr	1274(ra) # 80004cd2 <filewrite>
    800057e0:	87aa                	mv	a5,a0
}
    800057e2:	853e                	mv	a0,a5
    800057e4:	70a2                	ld	ra,40(sp)
    800057e6:	7402                	ld	s0,32(sp)
    800057e8:	6145                	addi	sp,sp,48
    800057ea:	8082                	ret

00000000800057ec <sys_close>:
{
    800057ec:	1101                	addi	sp,sp,-32
    800057ee:	ec06                	sd	ra,24(sp)
    800057f0:	e822                	sd	s0,16(sp)
    800057f2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057f4:	fe040613          	addi	a2,s0,-32
    800057f8:	fec40593          	addi	a1,s0,-20
    800057fc:	4501                	li	a0,0
    800057fe:	00000097          	auipc	ra,0x0
    80005802:	cc2080e7          	jalr	-830(ra) # 800054c0 <argfd>
    return -1;
    80005806:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005808:	02054463          	bltz	a0,80005830 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000580c:	ffffc097          	auipc	ra,0xffffc
    80005810:	0fa080e7          	jalr	250(ra) # 80001906 <myproc>
    80005814:	fec42783          	lw	a5,-20(s0)
    80005818:	07f9                	addi	a5,a5,30
    8000581a:	078e                	slli	a5,a5,0x3
    8000581c:	97aa                	add	a5,a5,a0
    8000581e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005822:	fe043503          	ld	a0,-32(s0)
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	2b0080e7          	jalr	688(ra) # 80004ad6 <fileclose>
  return 0;
    8000582e:	4781                	li	a5,0
}
    80005830:	853e                	mv	a0,a5
    80005832:	60e2                	ld	ra,24(sp)
    80005834:	6442                	ld	s0,16(sp)
    80005836:	6105                	addi	sp,sp,32
    80005838:	8082                	ret

000000008000583a <sys_fstat>:
{
    8000583a:	1101                	addi	sp,sp,-32
    8000583c:	ec06                	sd	ra,24(sp)
    8000583e:	e822                	sd	s0,16(sp)
    80005840:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005842:	fe840613          	addi	a2,s0,-24
    80005846:	4581                	li	a1,0
    80005848:	4501                	li	a0,0
    8000584a:	00000097          	auipc	ra,0x0
    8000584e:	c76080e7          	jalr	-906(ra) # 800054c0 <argfd>
    return -1;
    80005852:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005854:	02054563          	bltz	a0,8000587e <sys_fstat+0x44>
    80005858:	fe040593          	addi	a1,s0,-32
    8000585c:	4505                	li	a0,1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	840080e7          	jalr	-1984(ra) # 8000309e <argaddr>
    return -1;
    80005866:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005868:	00054b63          	bltz	a0,8000587e <sys_fstat+0x44>
  return filestat(f, st);
    8000586c:	fe043583          	ld	a1,-32(s0)
    80005870:	fe843503          	ld	a0,-24(s0)
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	32a080e7          	jalr	810(ra) # 80004b9e <filestat>
    8000587c:	87aa                	mv	a5,a0
}
    8000587e:	853e                	mv	a0,a5
    80005880:	60e2                	ld	ra,24(sp)
    80005882:	6442                	ld	s0,16(sp)
    80005884:	6105                	addi	sp,sp,32
    80005886:	8082                	ret

0000000080005888 <sys_link>:
{
    80005888:	7169                	addi	sp,sp,-304
    8000588a:	f606                	sd	ra,296(sp)
    8000588c:	f222                	sd	s0,288(sp)
    8000588e:	ee26                	sd	s1,280(sp)
    80005890:	ea4a                	sd	s2,272(sp)
    80005892:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005894:	08000613          	li	a2,128
    80005898:	ed040593          	addi	a1,s0,-304
    8000589c:	4501                	li	a0,0
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	822080e7          	jalr	-2014(ra) # 800030c0 <argstr>
    return -1;
    800058a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058a8:	10054e63          	bltz	a0,800059c4 <sys_link+0x13c>
    800058ac:	08000613          	li	a2,128
    800058b0:	f5040593          	addi	a1,s0,-176
    800058b4:	4505                	li	a0,1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	80a080e7          	jalr	-2038(ra) # 800030c0 <argstr>
    return -1;
    800058be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058c0:	10054263          	bltz	a0,800059c4 <sys_link+0x13c>
  begin_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	d46080e7          	jalr	-698(ra) # 8000460a <begin_op>
  if((ip = namei(old)) == 0){
    800058cc:	ed040513          	addi	a0,s0,-304
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	b1e080e7          	jalr	-1250(ra) # 800043ee <namei>
    800058d8:	84aa                	mv	s1,a0
    800058da:	c551                	beqz	a0,80005966 <sys_link+0xde>
  ilock(ip);
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	35c080e7          	jalr	860(ra) # 80003c38 <ilock>
  if(ip->type == T_DIR){
    800058e4:	04449703          	lh	a4,68(s1)
    800058e8:	4785                	li	a5,1
    800058ea:	08f70463          	beq	a4,a5,80005972 <sys_link+0xea>
  ip->nlink++;
    800058ee:	04a4d783          	lhu	a5,74(s1)
    800058f2:	2785                	addiw	a5,a5,1
    800058f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058f8:	8526                	mv	a0,s1
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	274080e7          	jalr	628(ra) # 80003b6e <iupdate>
  iunlock(ip);
    80005902:	8526                	mv	a0,s1
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	3f6080e7          	jalr	1014(ra) # 80003cfa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000590c:	fd040593          	addi	a1,s0,-48
    80005910:	f5040513          	addi	a0,s0,-176
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	af8080e7          	jalr	-1288(ra) # 8000440c <nameiparent>
    8000591c:	892a                	mv	s2,a0
    8000591e:	c935                	beqz	a0,80005992 <sys_link+0x10a>
  ilock(dp);
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	318080e7          	jalr	792(ra) # 80003c38 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005928:	00092703          	lw	a4,0(s2)
    8000592c:	409c                	lw	a5,0(s1)
    8000592e:	04f71d63          	bne	a4,a5,80005988 <sys_link+0x100>
    80005932:	40d0                	lw	a2,4(s1)
    80005934:	fd040593          	addi	a1,s0,-48
    80005938:	854a                	mv	a0,s2
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	9f2080e7          	jalr	-1550(ra) # 8000432c <dirlink>
    80005942:	04054363          	bltz	a0,80005988 <sys_link+0x100>
  iunlockput(dp);
    80005946:	854a                	mv	a0,s2
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	552080e7          	jalr	1362(ra) # 80003e9a <iunlockput>
  iput(ip);
    80005950:	8526                	mv	a0,s1
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	4a0080e7          	jalr	1184(ra) # 80003df2 <iput>
  end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	d30080e7          	jalr	-720(ra) # 8000468a <end_op>
  return 0;
    80005962:	4781                	li	a5,0
    80005964:	a085                	j	800059c4 <sys_link+0x13c>
    end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	d24080e7          	jalr	-732(ra) # 8000468a <end_op>
    return -1;
    8000596e:	57fd                	li	a5,-1
    80005970:	a891                	j	800059c4 <sys_link+0x13c>
    iunlockput(ip);
    80005972:	8526                	mv	a0,s1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	526080e7          	jalr	1318(ra) # 80003e9a <iunlockput>
    end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	d0e080e7          	jalr	-754(ra) # 8000468a <end_op>
    return -1;
    80005984:	57fd                	li	a5,-1
    80005986:	a83d                	j	800059c4 <sys_link+0x13c>
    iunlockput(dp);
    80005988:	854a                	mv	a0,s2
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	510080e7          	jalr	1296(ra) # 80003e9a <iunlockput>
  ilock(ip);
    80005992:	8526                	mv	a0,s1
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	2a4080e7          	jalr	676(ra) # 80003c38 <ilock>
  ip->nlink--;
    8000599c:	04a4d783          	lhu	a5,74(s1)
    800059a0:	37fd                	addiw	a5,a5,-1
    800059a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059a6:	8526                	mv	a0,s1
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	1c6080e7          	jalr	454(ra) # 80003b6e <iupdate>
  iunlockput(ip);
    800059b0:	8526                	mv	a0,s1
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	4e8080e7          	jalr	1256(ra) # 80003e9a <iunlockput>
  end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	cd0080e7          	jalr	-816(ra) # 8000468a <end_op>
  return -1;
    800059c2:	57fd                	li	a5,-1
}
    800059c4:	853e                	mv	a0,a5
    800059c6:	70b2                	ld	ra,296(sp)
    800059c8:	7412                	ld	s0,288(sp)
    800059ca:	64f2                	ld	s1,280(sp)
    800059cc:	6952                	ld	s2,272(sp)
    800059ce:	6155                	addi	sp,sp,304
    800059d0:	8082                	ret

00000000800059d2 <sys_unlink>:
{
    800059d2:	7151                	addi	sp,sp,-240
    800059d4:	f586                	sd	ra,232(sp)
    800059d6:	f1a2                	sd	s0,224(sp)
    800059d8:	eda6                	sd	s1,216(sp)
    800059da:	e9ca                	sd	s2,208(sp)
    800059dc:	e5ce                	sd	s3,200(sp)
    800059de:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059e0:	08000613          	li	a2,128
    800059e4:	f3040593          	addi	a1,s0,-208
    800059e8:	4501                	li	a0,0
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	6d6080e7          	jalr	1750(ra) # 800030c0 <argstr>
    800059f2:	18054163          	bltz	a0,80005b74 <sys_unlink+0x1a2>
  begin_op();
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	c14080e7          	jalr	-1004(ra) # 8000460a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059fe:	fb040593          	addi	a1,s0,-80
    80005a02:	f3040513          	addi	a0,s0,-208
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	a06080e7          	jalr	-1530(ra) # 8000440c <nameiparent>
    80005a0e:	84aa                	mv	s1,a0
    80005a10:	c979                	beqz	a0,80005ae6 <sys_unlink+0x114>
  ilock(dp);
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	226080e7          	jalr	550(ra) # 80003c38 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a1a:	00003597          	auipc	a1,0x3
    80005a1e:	cee58593          	addi	a1,a1,-786 # 80008708 <syscalls+0x2c0>
    80005a22:	fb040513          	addi	a0,s0,-80
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	6dc080e7          	jalr	1756(ra) # 80004102 <namecmp>
    80005a2e:	14050a63          	beqz	a0,80005b82 <sys_unlink+0x1b0>
    80005a32:	00003597          	auipc	a1,0x3
    80005a36:	cde58593          	addi	a1,a1,-802 # 80008710 <syscalls+0x2c8>
    80005a3a:	fb040513          	addi	a0,s0,-80
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	6c4080e7          	jalr	1732(ra) # 80004102 <namecmp>
    80005a46:	12050e63          	beqz	a0,80005b82 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a4a:	f2c40613          	addi	a2,s0,-212
    80005a4e:	fb040593          	addi	a1,s0,-80
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	6c8080e7          	jalr	1736(ra) # 8000411c <dirlookup>
    80005a5c:	892a                	mv	s2,a0
    80005a5e:	12050263          	beqz	a0,80005b82 <sys_unlink+0x1b0>
  ilock(ip);
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	1d6080e7          	jalr	470(ra) # 80003c38 <ilock>
  if(ip->nlink < 1)
    80005a6a:	04a91783          	lh	a5,74(s2)
    80005a6e:	08f05263          	blez	a5,80005af2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a72:	04491703          	lh	a4,68(s2)
    80005a76:	4785                	li	a5,1
    80005a78:	08f70563          	beq	a4,a5,80005b02 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a7c:	4641                	li	a2,16
    80005a7e:	4581                	li	a1,0
    80005a80:	fc040513          	addi	a0,s0,-64
    80005a84:	ffffb097          	auipc	ra,0xffffb
    80005a88:	25c080e7          	jalr	604(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a8c:	4741                	li	a4,16
    80005a8e:	f2c42683          	lw	a3,-212(s0)
    80005a92:	fc040613          	addi	a2,s0,-64
    80005a96:	4581                	li	a1,0
    80005a98:	8526                	mv	a0,s1
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	54a080e7          	jalr	1354(ra) # 80003fe4 <writei>
    80005aa2:	47c1                	li	a5,16
    80005aa4:	0af51563          	bne	a0,a5,80005b4e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005aa8:	04491703          	lh	a4,68(s2)
    80005aac:	4785                	li	a5,1
    80005aae:	0af70863          	beq	a4,a5,80005b5e <sys_unlink+0x18c>
  iunlockput(dp);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	3e6080e7          	jalr	998(ra) # 80003e9a <iunlockput>
  ip->nlink--;
    80005abc:	04a95783          	lhu	a5,74(s2)
    80005ac0:	37fd                	addiw	a5,a5,-1
    80005ac2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ac6:	854a                	mv	a0,s2
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	0a6080e7          	jalr	166(ra) # 80003b6e <iupdate>
  iunlockput(ip);
    80005ad0:	854a                	mv	a0,s2
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	3c8080e7          	jalr	968(ra) # 80003e9a <iunlockput>
  end_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	bb0080e7          	jalr	-1104(ra) # 8000468a <end_op>
  return 0;
    80005ae2:	4501                	li	a0,0
    80005ae4:	a84d                	j	80005b96 <sys_unlink+0x1c4>
    end_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	ba4080e7          	jalr	-1116(ra) # 8000468a <end_op>
    return -1;
    80005aee:	557d                	li	a0,-1
    80005af0:	a05d                	j	80005b96 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005af2:	00003517          	auipc	a0,0x3
    80005af6:	c4650513          	addi	a0,a0,-954 # 80008738 <syscalls+0x2f0>
    80005afa:	ffffb097          	auipc	ra,0xffffb
    80005afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b02:	04c92703          	lw	a4,76(s2)
    80005b06:	02000793          	li	a5,32
    80005b0a:	f6e7f9e3          	bgeu	a5,a4,80005a7c <sys_unlink+0xaa>
    80005b0e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b12:	4741                	li	a4,16
    80005b14:	86ce                	mv	a3,s3
    80005b16:	f1840613          	addi	a2,s0,-232
    80005b1a:	4581                	li	a1,0
    80005b1c:	854a                	mv	a0,s2
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	3ce080e7          	jalr	974(ra) # 80003eec <readi>
    80005b26:	47c1                	li	a5,16
    80005b28:	00f51b63          	bne	a0,a5,80005b3e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b2c:	f1845783          	lhu	a5,-232(s0)
    80005b30:	e7a1                	bnez	a5,80005b78 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b32:	29c1                	addiw	s3,s3,16
    80005b34:	04c92783          	lw	a5,76(s2)
    80005b38:	fcf9ede3          	bltu	s3,a5,80005b12 <sys_unlink+0x140>
    80005b3c:	b781                	j	80005a7c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b3e:	00003517          	auipc	a0,0x3
    80005b42:	c1250513          	addi	a0,a0,-1006 # 80008750 <syscalls+0x308>
    80005b46:	ffffb097          	auipc	ra,0xffffb
    80005b4a:	9f8080e7          	jalr	-1544(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b4e:	00003517          	auipc	a0,0x3
    80005b52:	c1a50513          	addi	a0,a0,-998 # 80008768 <syscalls+0x320>
    80005b56:	ffffb097          	auipc	ra,0xffffb
    80005b5a:	9e8080e7          	jalr	-1560(ra) # 8000053e <panic>
    dp->nlink--;
    80005b5e:	04a4d783          	lhu	a5,74(s1)
    80005b62:	37fd                	addiw	a5,a5,-1
    80005b64:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b68:	8526                	mv	a0,s1
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	004080e7          	jalr	4(ra) # 80003b6e <iupdate>
    80005b72:	b781                	j	80005ab2 <sys_unlink+0xe0>
    return -1;
    80005b74:	557d                	li	a0,-1
    80005b76:	a005                	j	80005b96 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b78:	854a                	mv	a0,s2
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	320080e7          	jalr	800(ra) # 80003e9a <iunlockput>
  iunlockput(dp);
    80005b82:	8526                	mv	a0,s1
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	316080e7          	jalr	790(ra) # 80003e9a <iunlockput>
  end_op();
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	afe080e7          	jalr	-1282(ra) # 8000468a <end_op>
  return -1;
    80005b94:	557d                	li	a0,-1
}
    80005b96:	70ae                	ld	ra,232(sp)
    80005b98:	740e                	ld	s0,224(sp)
    80005b9a:	64ee                	ld	s1,216(sp)
    80005b9c:	694e                	ld	s2,208(sp)
    80005b9e:	69ae                	ld	s3,200(sp)
    80005ba0:	616d                	addi	sp,sp,240
    80005ba2:	8082                	ret

0000000080005ba4 <sys_open>:

uint64
sys_open(void)
{
    80005ba4:	7131                	addi	sp,sp,-192
    80005ba6:	fd06                	sd	ra,184(sp)
    80005ba8:	f922                	sd	s0,176(sp)
    80005baa:	f526                	sd	s1,168(sp)
    80005bac:	f14a                	sd	s2,160(sp)
    80005bae:	ed4e                	sd	s3,152(sp)
    80005bb0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bb2:	08000613          	li	a2,128
    80005bb6:	f5040593          	addi	a1,s0,-176
    80005bba:	4501                	li	a0,0
    80005bbc:	ffffd097          	auipc	ra,0xffffd
    80005bc0:	504080e7          	jalr	1284(ra) # 800030c0 <argstr>
    return -1;
    80005bc4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bc6:	0c054163          	bltz	a0,80005c88 <sys_open+0xe4>
    80005bca:	f4c40593          	addi	a1,s0,-180
    80005bce:	4505                	li	a0,1
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	4ac080e7          	jalr	1196(ra) # 8000307c <argint>
    80005bd8:	0a054863          	bltz	a0,80005c88 <sys_open+0xe4>

  begin_op();
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	a2e080e7          	jalr	-1490(ra) # 8000460a <begin_op>

  if(omode & O_CREATE){
    80005be4:	f4c42783          	lw	a5,-180(s0)
    80005be8:	2007f793          	andi	a5,a5,512
    80005bec:	cbdd                	beqz	a5,80005ca2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005bee:	4681                	li	a3,0
    80005bf0:	4601                	li	a2,0
    80005bf2:	4589                	li	a1,2
    80005bf4:	f5040513          	addi	a0,s0,-176
    80005bf8:	00000097          	auipc	ra,0x0
    80005bfc:	972080e7          	jalr	-1678(ra) # 8000556a <create>
    80005c00:	892a                	mv	s2,a0
    if(ip == 0){
    80005c02:	c959                	beqz	a0,80005c98 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c04:	04491703          	lh	a4,68(s2)
    80005c08:	478d                	li	a5,3
    80005c0a:	00f71763          	bne	a4,a5,80005c18 <sys_open+0x74>
    80005c0e:	04695703          	lhu	a4,70(s2)
    80005c12:	47a5                	li	a5,9
    80005c14:	0ce7ec63          	bltu	a5,a4,80005cec <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	e02080e7          	jalr	-510(ra) # 80004a1a <filealloc>
    80005c20:	89aa                	mv	s3,a0
    80005c22:	10050263          	beqz	a0,80005d26 <sys_open+0x182>
    80005c26:	00000097          	auipc	ra,0x0
    80005c2a:	902080e7          	jalr	-1790(ra) # 80005528 <fdalloc>
    80005c2e:	84aa                	mv	s1,a0
    80005c30:	0e054663          	bltz	a0,80005d1c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c34:	04491703          	lh	a4,68(s2)
    80005c38:	478d                	li	a5,3
    80005c3a:	0cf70463          	beq	a4,a5,80005d02 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c3e:	4789                	li	a5,2
    80005c40:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c44:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c48:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c4c:	f4c42783          	lw	a5,-180(s0)
    80005c50:	0017c713          	xori	a4,a5,1
    80005c54:	8b05                	andi	a4,a4,1
    80005c56:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c5a:	0037f713          	andi	a4,a5,3
    80005c5e:	00e03733          	snez	a4,a4
    80005c62:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c66:	4007f793          	andi	a5,a5,1024
    80005c6a:	c791                	beqz	a5,80005c76 <sys_open+0xd2>
    80005c6c:	04491703          	lh	a4,68(s2)
    80005c70:	4789                	li	a5,2
    80005c72:	08f70f63          	beq	a4,a5,80005d10 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c76:	854a                	mv	a0,s2
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	082080e7          	jalr	130(ra) # 80003cfa <iunlock>
  end_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	a0a080e7          	jalr	-1526(ra) # 8000468a <end_op>

  return fd;
}
    80005c88:	8526                	mv	a0,s1
    80005c8a:	70ea                	ld	ra,184(sp)
    80005c8c:	744a                	ld	s0,176(sp)
    80005c8e:	74aa                	ld	s1,168(sp)
    80005c90:	790a                	ld	s2,160(sp)
    80005c92:	69ea                	ld	s3,152(sp)
    80005c94:	6129                	addi	sp,sp,192
    80005c96:	8082                	ret
      end_op();
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	9f2080e7          	jalr	-1550(ra) # 8000468a <end_op>
      return -1;
    80005ca0:	b7e5                	j	80005c88 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ca2:	f5040513          	addi	a0,s0,-176
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	748080e7          	jalr	1864(ra) # 800043ee <namei>
    80005cae:	892a                	mv	s2,a0
    80005cb0:	c905                	beqz	a0,80005ce0 <sys_open+0x13c>
    ilock(ip);
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	f86080e7          	jalr	-122(ra) # 80003c38 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cba:	04491703          	lh	a4,68(s2)
    80005cbe:	4785                	li	a5,1
    80005cc0:	f4f712e3          	bne	a4,a5,80005c04 <sys_open+0x60>
    80005cc4:	f4c42783          	lw	a5,-180(s0)
    80005cc8:	dba1                	beqz	a5,80005c18 <sys_open+0x74>
      iunlockput(ip);
    80005cca:	854a                	mv	a0,s2
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	1ce080e7          	jalr	462(ra) # 80003e9a <iunlockput>
      end_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	9b6080e7          	jalr	-1610(ra) # 8000468a <end_op>
      return -1;
    80005cdc:	54fd                	li	s1,-1
    80005cde:	b76d                	j	80005c88 <sys_open+0xe4>
      end_op();
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	9aa080e7          	jalr	-1622(ra) # 8000468a <end_op>
      return -1;
    80005ce8:	54fd                	li	s1,-1
    80005cea:	bf79                	j	80005c88 <sys_open+0xe4>
    iunlockput(ip);
    80005cec:	854a                	mv	a0,s2
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	1ac080e7          	jalr	428(ra) # 80003e9a <iunlockput>
    end_op();
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	994080e7          	jalr	-1644(ra) # 8000468a <end_op>
    return -1;
    80005cfe:	54fd                	li	s1,-1
    80005d00:	b761                	j	80005c88 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d02:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d06:	04691783          	lh	a5,70(s2)
    80005d0a:	02f99223          	sh	a5,36(s3)
    80005d0e:	bf2d                	j	80005c48 <sys_open+0xa4>
    itrunc(ip);
    80005d10:	854a                	mv	a0,s2
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	034080e7          	jalr	52(ra) # 80003d46 <itrunc>
    80005d1a:	bfb1                	j	80005c76 <sys_open+0xd2>
      fileclose(f);
    80005d1c:	854e                	mv	a0,s3
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	db8080e7          	jalr	-584(ra) # 80004ad6 <fileclose>
    iunlockput(ip);
    80005d26:	854a                	mv	a0,s2
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	172080e7          	jalr	370(ra) # 80003e9a <iunlockput>
    end_op();
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	95a080e7          	jalr	-1702(ra) # 8000468a <end_op>
    return -1;
    80005d38:	54fd                	li	s1,-1
    80005d3a:	b7b9                	j	80005c88 <sys_open+0xe4>

0000000080005d3c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d3c:	7175                	addi	sp,sp,-144
    80005d3e:	e506                	sd	ra,136(sp)
    80005d40:	e122                	sd	s0,128(sp)
    80005d42:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	8c6080e7          	jalr	-1850(ra) # 8000460a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d4c:	08000613          	li	a2,128
    80005d50:	f7040593          	addi	a1,s0,-144
    80005d54:	4501                	li	a0,0
    80005d56:	ffffd097          	auipc	ra,0xffffd
    80005d5a:	36a080e7          	jalr	874(ra) # 800030c0 <argstr>
    80005d5e:	02054963          	bltz	a0,80005d90 <sys_mkdir+0x54>
    80005d62:	4681                	li	a3,0
    80005d64:	4601                	li	a2,0
    80005d66:	4585                	li	a1,1
    80005d68:	f7040513          	addi	a0,s0,-144
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	7fe080e7          	jalr	2046(ra) # 8000556a <create>
    80005d74:	cd11                	beqz	a0,80005d90 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d76:	ffffe097          	auipc	ra,0xffffe
    80005d7a:	124080e7          	jalr	292(ra) # 80003e9a <iunlockput>
  end_op();
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	90c080e7          	jalr	-1780(ra) # 8000468a <end_op>
  return 0;
    80005d86:	4501                	li	a0,0
}
    80005d88:	60aa                	ld	ra,136(sp)
    80005d8a:	640a                	ld	s0,128(sp)
    80005d8c:	6149                	addi	sp,sp,144
    80005d8e:	8082                	ret
    end_op();
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	8fa080e7          	jalr	-1798(ra) # 8000468a <end_op>
    return -1;
    80005d98:	557d                	li	a0,-1
    80005d9a:	b7fd                	j	80005d88 <sys_mkdir+0x4c>

0000000080005d9c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d9c:	7135                	addi	sp,sp,-160
    80005d9e:	ed06                	sd	ra,152(sp)
    80005da0:	e922                	sd	s0,144(sp)
    80005da2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	866080e7          	jalr	-1946(ra) # 8000460a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dac:	08000613          	li	a2,128
    80005db0:	f7040593          	addi	a1,s0,-144
    80005db4:	4501                	li	a0,0
    80005db6:	ffffd097          	auipc	ra,0xffffd
    80005dba:	30a080e7          	jalr	778(ra) # 800030c0 <argstr>
    80005dbe:	04054a63          	bltz	a0,80005e12 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005dc2:	f6c40593          	addi	a1,s0,-148
    80005dc6:	4505                	li	a0,1
    80005dc8:	ffffd097          	auipc	ra,0xffffd
    80005dcc:	2b4080e7          	jalr	692(ra) # 8000307c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dd0:	04054163          	bltz	a0,80005e12 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005dd4:	f6840593          	addi	a1,s0,-152
    80005dd8:	4509                	li	a0,2
    80005dda:	ffffd097          	auipc	ra,0xffffd
    80005dde:	2a2080e7          	jalr	674(ra) # 8000307c <argint>
     argint(1, &major) < 0 ||
    80005de2:	02054863          	bltz	a0,80005e12 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005de6:	f6841683          	lh	a3,-152(s0)
    80005dea:	f6c41603          	lh	a2,-148(s0)
    80005dee:	458d                	li	a1,3
    80005df0:	f7040513          	addi	a0,s0,-144
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	776080e7          	jalr	1910(ra) # 8000556a <create>
     argint(2, &minor) < 0 ||
    80005dfc:	c919                	beqz	a0,80005e12 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	09c080e7          	jalr	156(ra) # 80003e9a <iunlockput>
  end_op();
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	884080e7          	jalr	-1916(ra) # 8000468a <end_op>
  return 0;
    80005e0e:	4501                	li	a0,0
    80005e10:	a031                	j	80005e1c <sys_mknod+0x80>
    end_op();
    80005e12:	fffff097          	auipc	ra,0xfffff
    80005e16:	878080e7          	jalr	-1928(ra) # 8000468a <end_op>
    return -1;
    80005e1a:	557d                	li	a0,-1
}
    80005e1c:	60ea                	ld	ra,152(sp)
    80005e1e:	644a                	ld	s0,144(sp)
    80005e20:	610d                	addi	sp,sp,160
    80005e22:	8082                	ret

0000000080005e24 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e24:	7135                	addi	sp,sp,-160
    80005e26:	ed06                	sd	ra,152(sp)
    80005e28:	e922                	sd	s0,144(sp)
    80005e2a:	e526                	sd	s1,136(sp)
    80005e2c:	e14a                	sd	s2,128(sp)
    80005e2e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e30:	ffffc097          	auipc	ra,0xffffc
    80005e34:	ad6080e7          	jalr	-1322(ra) # 80001906 <myproc>
    80005e38:	892a                	mv	s2,a0
  
  begin_op();
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	7d0080e7          	jalr	2000(ra) # 8000460a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e42:	08000613          	li	a2,128
    80005e46:	f6040593          	addi	a1,s0,-160
    80005e4a:	4501                	li	a0,0
    80005e4c:	ffffd097          	auipc	ra,0xffffd
    80005e50:	274080e7          	jalr	628(ra) # 800030c0 <argstr>
    80005e54:	04054b63          	bltz	a0,80005eaa <sys_chdir+0x86>
    80005e58:	f6040513          	addi	a0,s0,-160
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	592080e7          	jalr	1426(ra) # 800043ee <namei>
    80005e64:	84aa                	mv	s1,a0
    80005e66:	c131                	beqz	a0,80005eaa <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e68:	ffffe097          	auipc	ra,0xffffe
    80005e6c:	dd0080e7          	jalr	-560(ra) # 80003c38 <ilock>
  if(ip->type != T_DIR){
    80005e70:	04449703          	lh	a4,68(s1)
    80005e74:	4785                	li	a5,1
    80005e76:	04f71063          	bne	a4,a5,80005eb6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e7a:	8526                	mv	a0,s1
    80005e7c:	ffffe097          	auipc	ra,0xffffe
    80005e80:	e7e080e7          	jalr	-386(ra) # 80003cfa <iunlock>
  iput(p->cwd);
    80005e84:	17093503          	ld	a0,368(s2)
    80005e88:	ffffe097          	auipc	ra,0xffffe
    80005e8c:	f6a080e7          	jalr	-150(ra) # 80003df2 <iput>
  end_op();
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	7fa080e7          	jalr	2042(ra) # 8000468a <end_op>
  p->cwd = ip;
    80005e98:	16993823          	sd	s1,368(s2)
  return 0;
    80005e9c:	4501                	li	a0,0
}
    80005e9e:	60ea                	ld	ra,152(sp)
    80005ea0:	644a                	ld	s0,144(sp)
    80005ea2:	64aa                	ld	s1,136(sp)
    80005ea4:	690a                	ld	s2,128(sp)
    80005ea6:	610d                	addi	sp,sp,160
    80005ea8:	8082                	ret
    end_op();
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	7e0080e7          	jalr	2016(ra) # 8000468a <end_op>
    return -1;
    80005eb2:	557d                	li	a0,-1
    80005eb4:	b7ed                	j	80005e9e <sys_chdir+0x7a>
    iunlockput(ip);
    80005eb6:	8526                	mv	a0,s1
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	fe2080e7          	jalr	-30(ra) # 80003e9a <iunlockput>
    end_op();
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	7ca080e7          	jalr	1994(ra) # 8000468a <end_op>
    return -1;
    80005ec8:	557d                	li	a0,-1
    80005eca:	bfd1                	j	80005e9e <sys_chdir+0x7a>

0000000080005ecc <sys_exec>:

uint64
sys_exec(void)
{
    80005ecc:	7145                	addi	sp,sp,-464
    80005ece:	e786                	sd	ra,456(sp)
    80005ed0:	e3a2                	sd	s0,448(sp)
    80005ed2:	ff26                	sd	s1,440(sp)
    80005ed4:	fb4a                	sd	s2,432(sp)
    80005ed6:	f74e                	sd	s3,424(sp)
    80005ed8:	f352                	sd	s4,416(sp)
    80005eda:	ef56                	sd	s5,408(sp)
    80005edc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ede:	08000613          	li	a2,128
    80005ee2:	f4040593          	addi	a1,s0,-192
    80005ee6:	4501                	li	a0,0
    80005ee8:	ffffd097          	auipc	ra,0xffffd
    80005eec:	1d8080e7          	jalr	472(ra) # 800030c0 <argstr>
    return -1;
    80005ef0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ef2:	0c054a63          	bltz	a0,80005fc6 <sys_exec+0xfa>
    80005ef6:	e3840593          	addi	a1,s0,-456
    80005efa:	4505                	li	a0,1
    80005efc:	ffffd097          	auipc	ra,0xffffd
    80005f00:	1a2080e7          	jalr	418(ra) # 8000309e <argaddr>
    80005f04:	0c054163          	bltz	a0,80005fc6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f08:	10000613          	li	a2,256
    80005f0c:	4581                	li	a1,0
    80005f0e:	e4040513          	addi	a0,s0,-448
    80005f12:	ffffb097          	auipc	ra,0xffffb
    80005f16:	dce080e7          	jalr	-562(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f1a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f1e:	89a6                	mv	s3,s1
    80005f20:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f22:	02000a13          	li	s4,32
    80005f26:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f2a:	00391513          	slli	a0,s2,0x3
    80005f2e:	e3040593          	addi	a1,s0,-464
    80005f32:	e3843783          	ld	a5,-456(s0)
    80005f36:	953e                	add	a0,a0,a5
    80005f38:	ffffd097          	auipc	ra,0xffffd
    80005f3c:	0aa080e7          	jalr	170(ra) # 80002fe2 <fetchaddr>
    80005f40:	02054a63          	bltz	a0,80005f74 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f44:	e3043783          	ld	a5,-464(s0)
    80005f48:	c3b9                	beqz	a5,80005f8e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	baa080e7          	jalr	-1110(ra) # 80000af4 <kalloc>
    80005f52:	85aa                	mv	a1,a0
    80005f54:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f58:	cd11                	beqz	a0,80005f74 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f5a:	6605                	lui	a2,0x1
    80005f5c:	e3043503          	ld	a0,-464(s0)
    80005f60:	ffffd097          	auipc	ra,0xffffd
    80005f64:	0d4080e7          	jalr	212(ra) # 80003034 <fetchstr>
    80005f68:	00054663          	bltz	a0,80005f74 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f6c:	0905                	addi	s2,s2,1
    80005f6e:	09a1                	addi	s3,s3,8
    80005f70:	fb491be3          	bne	s2,s4,80005f26 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f74:	10048913          	addi	s2,s1,256
    80005f78:	6088                	ld	a0,0(s1)
    80005f7a:	c529                	beqz	a0,80005fc4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f7c:	ffffb097          	auipc	ra,0xffffb
    80005f80:	a7c080e7          	jalr	-1412(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f84:	04a1                	addi	s1,s1,8
    80005f86:	ff2499e3          	bne	s1,s2,80005f78 <sys_exec+0xac>
  return -1;
    80005f8a:	597d                	li	s2,-1
    80005f8c:	a82d                	j	80005fc6 <sys_exec+0xfa>
      argv[i] = 0;
    80005f8e:	0a8e                	slli	s5,s5,0x3
    80005f90:	fc040793          	addi	a5,s0,-64
    80005f94:	9abe                	add	s5,s5,a5
    80005f96:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f9a:	e4040593          	addi	a1,s0,-448
    80005f9e:	f4040513          	addi	a0,s0,-192
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	194080e7          	jalr	404(ra) # 80005136 <exec>
    80005faa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fac:	10048993          	addi	s3,s1,256
    80005fb0:	6088                	ld	a0,0(s1)
    80005fb2:	c911                	beqz	a0,80005fc6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005fb4:	ffffb097          	auipc	ra,0xffffb
    80005fb8:	a44080e7          	jalr	-1468(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fbc:	04a1                	addi	s1,s1,8
    80005fbe:	ff3499e3          	bne	s1,s3,80005fb0 <sys_exec+0xe4>
    80005fc2:	a011                	j	80005fc6 <sys_exec+0xfa>
  return -1;
    80005fc4:	597d                	li	s2,-1
}
    80005fc6:	854a                	mv	a0,s2
    80005fc8:	60be                	ld	ra,456(sp)
    80005fca:	641e                	ld	s0,448(sp)
    80005fcc:	74fa                	ld	s1,440(sp)
    80005fce:	795a                	ld	s2,432(sp)
    80005fd0:	79ba                	ld	s3,424(sp)
    80005fd2:	7a1a                	ld	s4,416(sp)
    80005fd4:	6afa                	ld	s5,408(sp)
    80005fd6:	6179                	addi	sp,sp,464
    80005fd8:	8082                	ret

0000000080005fda <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fda:	7139                	addi	sp,sp,-64
    80005fdc:	fc06                	sd	ra,56(sp)
    80005fde:	f822                	sd	s0,48(sp)
    80005fe0:	f426                	sd	s1,40(sp)
    80005fe2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fe4:	ffffc097          	auipc	ra,0xffffc
    80005fe8:	922080e7          	jalr	-1758(ra) # 80001906 <myproc>
    80005fec:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005fee:	fd840593          	addi	a1,s0,-40
    80005ff2:	4501                	li	a0,0
    80005ff4:	ffffd097          	auipc	ra,0xffffd
    80005ff8:	0aa080e7          	jalr	170(ra) # 8000309e <argaddr>
    return -1;
    80005ffc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ffe:	0e054063          	bltz	a0,800060de <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006002:	fc840593          	addi	a1,s0,-56
    80006006:	fd040513          	addi	a0,s0,-48
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	dfc080e7          	jalr	-516(ra) # 80004e06 <pipealloc>
    return -1;
    80006012:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006014:	0c054563          	bltz	a0,800060de <sys_pipe+0x104>
  fd0 = -1;
    80006018:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000601c:	fd043503          	ld	a0,-48(s0)
    80006020:	fffff097          	auipc	ra,0xfffff
    80006024:	508080e7          	jalr	1288(ra) # 80005528 <fdalloc>
    80006028:	fca42223          	sw	a0,-60(s0)
    8000602c:	08054c63          	bltz	a0,800060c4 <sys_pipe+0xea>
    80006030:	fc843503          	ld	a0,-56(s0)
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	4f4080e7          	jalr	1268(ra) # 80005528 <fdalloc>
    8000603c:	fca42023          	sw	a0,-64(s0)
    80006040:	06054863          	bltz	a0,800060b0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006044:	4691                	li	a3,4
    80006046:	fc440613          	addi	a2,s0,-60
    8000604a:	fd843583          	ld	a1,-40(s0)
    8000604e:	78a8                	ld	a0,112(s1)
    80006050:	ffffb097          	auipc	ra,0xffffb
    80006054:	622080e7          	jalr	1570(ra) # 80001672 <copyout>
    80006058:	02054063          	bltz	a0,80006078 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000605c:	4691                	li	a3,4
    8000605e:	fc040613          	addi	a2,s0,-64
    80006062:	fd843583          	ld	a1,-40(s0)
    80006066:	0591                	addi	a1,a1,4
    80006068:	78a8                	ld	a0,112(s1)
    8000606a:	ffffb097          	auipc	ra,0xffffb
    8000606e:	608080e7          	jalr	1544(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006072:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006074:	06055563          	bgez	a0,800060de <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006078:	fc442783          	lw	a5,-60(s0)
    8000607c:	07f9                	addi	a5,a5,30
    8000607e:	078e                	slli	a5,a5,0x3
    80006080:	97a6                	add	a5,a5,s1
    80006082:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006086:	fc042503          	lw	a0,-64(s0)
    8000608a:	0579                	addi	a0,a0,30
    8000608c:	050e                	slli	a0,a0,0x3
    8000608e:	9526                	add	a0,a0,s1
    80006090:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006094:	fd043503          	ld	a0,-48(s0)
    80006098:	fffff097          	auipc	ra,0xfffff
    8000609c:	a3e080e7          	jalr	-1474(ra) # 80004ad6 <fileclose>
    fileclose(wf);
    800060a0:	fc843503          	ld	a0,-56(s0)
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	a32080e7          	jalr	-1486(ra) # 80004ad6 <fileclose>
    return -1;
    800060ac:	57fd                	li	a5,-1
    800060ae:	a805                	j	800060de <sys_pipe+0x104>
    if(fd0 >= 0)
    800060b0:	fc442783          	lw	a5,-60(s0)
    800060b4:	0007c863          	bltz	a5,800060c4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800060b8:	01e78513          	addi	a0,a5,30
    800060bc:	050e                	slli	a0,a0,0x3
    800060be:	9526                	add	a0,a0,s1
    800060c0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060c4:	fd043503          	ld	a0,-48(s0)
    800060c8:	fffff097          	auipc	ra,0xfffff
    800060cc:	a0e080e7          	jalr	-1522(ra) # 80004ad6 <fileclose>
    fileclose(wf);
    800060d0:	fc843503          	ld	a0,-56(s0)
    800060d4:	fffff097          	auipc	ra,0xfffff
    800060d8:	a02080e7          	jalr	-1534(ra) # 80004ad6 <fileclose>
    return -1;
    800060dc:	57fd                	li	a5,-1
}
    800060de:	853e                	mv	a0,a5
    800060e0:	70e2                	ld	ra,56(sp)
    800060e2:	7442                	ld	s0,48(sp)
    800060e4:	74a2                	ld	s1,40(sp)
    800060e6:	6121                	addi	sp,sp,64
    800060e8:	8082                	ret
    800060ea:	0000                	unimp
    800060ec:	0000                	unimp
	...

00000000800060f0 <kernelvec>:
    800060f0:	7111                	addi	sp,sp,-256
    800060f2:	e006                	sd	ra,0(sp)
    800060f4:	e40a                	sd	sp,8(sp)
    800060f6:	e80e                	sd	gp,16(sp)
    800060f8:	ec12                	sd	tp,24(sp)
    800060fa:	f016                	sd	t0,32(sp)
    800060fc:	f41a                	sd	t1,40(sp)
    800060fe:	f81e                	sd	t2,48(sp)
    80006100:	fc22                	sd	s0,56(sp)
    80006102:	e0a6                	sd	s1,64(sp)
    80006104:	e4aa                	sd	a0,72(sp)
    80006106:	e8ae                	sd	a1,80(sp)
    80006108:	ecb2                	sd	a2,88(sp)
    8000610a:	f0b6                	sd	a3,96(sp)
    8000610c:	f4ba                	sd	a4,104(sp)
    8000610e:	f8be                	sd	a5,112(sp)
    80006110:	fcc2                	sd	a6,120(sp)
    80006112:	e146                	sd	a7,128(sp)
    80006114:	e54a                	sd	s2,136(sp)
    80006116:	e94e                	sd	s3,144(sp)
    80006118:	ed52                	sd	s4,152(sp)
    8000611a:	f156                	sd	s5,160(sp)
    8000611c:	f55a                	sd	s6,168(sp)
    8000611e:	f95e                	sd	s7,176(sp)
    80006120:	fd62                	sd	s8,184(sp)
    80006122:	e1e6                	sd	s9,192(sp)
    80006124:	e5ea                	sd	s10,200(sp)
    80006126:	e9ee                	sd	s11,208(sp)
    80006128:	edf2                	sd	t3,216(sp)
    8000612a:	f1f6                	sd	t4,224(sp)
    8000612c:	f5fa                	sd	t5,232(sp)
    8000612e:	f9fe                	sd	t6,240(sp)
    80006130:	d7ffc0ef          	jal	ra,80002eae <kerneltrap>
    80006134:	6082                	ld	ra,0(sp)
    80006136:	6122                	ld	sp,8(sp)
    80006138:	61c2                	ld	gp,16(sp)
    8000613a:	7282                	ld	t0,32(sp)
    8000613c:	7322                	ld	t1,40(sp)
    8000613e:	73c2                	ld	t2,48(sp)
    80006140:	7462                	ld	s0,56(sp)
    80006142:	6486                	ld	s1,64(sp)
    80006144:	6526                	ld	a0,72(sp)
    80006146:	65c6                	ld	a1,80(sp)
    80006148:	6666                	ld	a2,88(sp)
    8000614a:	7686                	ld	a3,96(sp)
    8000614c:	7726                	ld	a4,104(sp)
    8000614e:	77c6                	ld	a5,112(sp)
    80006150:	7866                	ld	a6,120(sp)
    80006152:	688a                	ld	a7,128(sp)
    80006154:	692a                	ld	s2,136(sp)
    80006156:	69ca                	ld	s3,144(sp)
    80006158:	6a6a                	ld	s4,152(sp)
    8000615a:	7a8a                	ld	s5,160(sp)
    8000615c:	7b2a                	ld	s6,168(sp)
    8000615e:	7bca                	ld	s7,176(sp)
    80006160:	7c6a                	ld	s8,184(sp)
    80006162:	6c8e                	ld	s9,192(sp)
    80006164:	6d2e                	ld	s10,200(sp)
    80006166:	6dce                	ld	s11,208(sp)
    80006168:	6e6e                	ld	t3,216(sp)
    8000616a:	7e8e                	ld	t4,224(sp)
    8000616c:	7f2e                	ld	t5,232(sp)
    8000616e:	7fce                	ld	t6,240(sp)
    80006170:	6111                	addi	sp,sp,256
    80006172:	10200073          	sret
    80006176:	00000013          	nop
    8000617a:	00000013          	nop
    8000617e:	0001                	nop

0000000080006180 <timervec>:
    80006180:	34051573          	csrrw	a0,mscratch,a0
    80006184:	e10c                	sd	a1,0(a0)
    80006186:	e510                	sd	a2,8(a0)
    80006188:	e914                	sd	a3,16(a0)
    8000618a:	6d0c                	ld	a1,24(a0)
    8000618c:	7110                	ld	a2,32(a0)
    8000618e:	6194                	ld	a3,0(a1)
    80006190:	96b2                	add	a3,a3,a2
    80006192:	e194                	sd	a3,0(a1)
    80006194:	4589                	li	a1,2
    80006196:	14459073          	csrw	sip,a1
    8000619a:	6914                	ld	a3,16(a0)
    8000619c:	6510                	ld	a2,8(a0)
    8000619e:	610c                	ld	a1,0(a0)
    800061a0:	34051573          	csrrw	a0,mscratch,a0
    800061a4:	30200073          	mret
	...

00000000800061aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061aa:	1141                	addi	sp,sp,-16
    800061ac:	e422                	sd	s0,8(sp)
    800061ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061b0:	0c0007b7          	lui	a5,0xc000
    800061b4:	4705                	li	a4,1
    800061b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061b8:	c3d8                	sw	a4,4(a5)
}
    800061ba:	6422                	ld	s0,8(sp)
    800061bc:	0141                	addi	sp,sp,16
    800061be:	8082                	ret

00000000800061c0 <plicinithart>:

void
plicinithart(void)
{
    800061c0:	1141                	addi	sp,sp,-16
    800061c2:	e406                	sd	ra,8(sp)
    800061c4:	e022                	sd	s0,0(sp)
    800061c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061c8:	ffffb097          	auipc	ra,0xffffb
    800061cc:	70c080e7          	jalr	1804(ra) # 800018d4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061d0:	0085171b          	slliw	a4,a0,0x8
    800061d4:	0c0027b7          	lui	a5,0xc002
    800061d8:	97ba                	add	a5,a5,a4
    800061da:	40200713          	li	a4,1026
    800061de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061e2:	00d5151b          	slliw	a0,a0,0xd
    800061e6:	0c2017b7          	lui	a5,0xc201
    800061ea:	953e                	add	a0,a0,a5
    800061ec:	00052023          	sw	zero,0(a0)
}
    800061f0:	60a2                	ld	ra,8(sp)
    800061f2:	6402                	ld	s0,0(sp)
    800061f4:	0141                	addi	sp,sp,16
    800061f6:	8082                	ret

00000000800061f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061f8:	1141                	addi	sp,sp,-16
    800061fa:	e406                	sd	ra,8(sp)
    800061fc:	e022                	sd	s0,0(sp)
    800061fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006200:	ffffb097          	auipc	ra,0xffffb
    80006204:	6d4080e7          	jalr	1748(ra) # 800018d4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006208:	00d5179b          	slliw	a5,a0,0xd
    8000620c:	0c201537          	lui	a0,0xc201
    80006210:	953e                	add	a0,a0,a5
  return irq;
}
    80006212:	4148                	lw	a0,4(a0)
    80006214:	60a2                	ld	ra,8(sp)
    80006216:	6402                	ld	s0,0(sp)
    80006218:	0141                	addi	sp,sp,16
    8000621a:	8082                	ret

000000008000621c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000621c:	1101                	addi	sp,sp,-32
    8000621e:	ec06                	sd	ra,24(sp)
    80006220:	e822                	sd	s0,16(sp)
    80006222:	e426                	sd	s1,8(sp)
    80006224:	1000                	addi	s0,sp,32
    80006226:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006228:	ffffb097          	auipc	ra,0xffffb
    8000622c:	6ac080e7          	jalr	1708(ra) # 800018d4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006230:	00d5151b          	slliw	a0,a0,0xd
    80006234:	0c2017b7          	lui	a5,0xc201
    80006238:	97aa                	add	a5,a5,a0
    8000623a:	c3c4                	sw	s1,4(a5)
}
    8000623c:	60e2                	ld	ra,24(sp)
    8000623e:	6442                	ld	s0,16(sp)
    80006240:	64a2                	ld	s1,8(sp)
    80006242:	6105                	addi	sp,sp,32
    80006244:	8082                	ret

0000000080006246 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006246:	1141                	addi	sp,sp,-16
    80006248:	e406                	sd	ra,8(sp)
    8000624a:	e022                	sd	s0,0(sp)
    8000624c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000624e:	479d                	li	a5,7
    80006250:	06a7c963          	blt	a5,a0,800062c2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006254:	0001d797          	auipc	a5,0x1d
    80006258:	dac78793          	addi	a5,a5,-596 # 80023000 <disk>
    8000625c:	00a78733          	add	a4,a5,a0
    80006260:	6789                	lui	a5,0x2
    80006262:	97ba                	add	a5,a5,a4
    80006264:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006268:	e7ad                	bnez	a5,800062d2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000626a:	00451793          	slli	a5,a0,0x4
    8000626e:	0001f717          	auipc	a4,0x1f
    80006272:	d9270713          	addi	a4,a4,-622 # 80025000 <disk+0x2000>
    80006276:	6314                	ld	a3,0(a4)
    80006278:	96be                	add	a3,a3,a5
    8000627a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000627e:	6314                	ld	a3,0(a4)
    80006280:	96be                	add	a3,a3,a5
    80006282:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006286:	6314                	ld	a3,0(a4)
    80006288:	96be                	add	a3,a3,a5
    8000628a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000628e:	6318                	ld	a4,0(a4)
    80006290:	97ba                	add	a5,a5,a4
    80006292:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006296:	0001d797          	auipc	a5,0x1d
    8000629a:	d6a78793          	addi	a5,a5,-662 # 80023000 <disk>
    8000629e:	97aa                	add	a5,a5,a0
    800062a0:	6509                	lui	a0,0x2
    800062a2:	953e                	add	a0,a0,a5
    800062a4:	4785                	li	a5,1
    800062a6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062aa:	0001f517          	auipc	a0,0x1f
    800062ae:	d6e50513          	addi	a0,a0,-658 # 80025018 <disk+0x2018>
    800062b2:	ffffc097          	auipc	ra,0xffffc
    800062b6:	0f2080e7          	jalr	242(ra) # 800023a4 <wakeup>
}
    800062ba:	60a2                	ld	ra,8(sp)
    800062bc:	6402                	ld	s0,0(sp)
    800062be:	0141                	addi	sp,sp,16
    800062c0:	8082                	ret
    panic("free_desc 1");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	4b650513          	addi	a0,a0,1206 # 80008778 <syscalls+0x330>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	274080e7          	jalr	628(ra) # 8000053e <panic>
    panic("free_desc 2");
    800062d2:	00002517          	auipc	a0,0x2
    800062d6:	4b650513          	addi	a0,a0,1206 # 80008788 <syscalls+0x340>
    800062da:	ffffa097          	auipc	ra,0xffffa
    800062de:	264080e7          	jalr	612(ra) # 8000053e <panic>

00000000800062e2 <virtio_disk_init>:
{
    800062e2:	1101                	addi	sp,sp,-32
    800062e4:	ec06                	sd	ra,24(sp)
    800062e6:	e822                	sd	s0,16(sp)
    800062e8:	e426                	sd	s1,8(sp)
    800062ea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062ec:	00002597          	auipc	a1,0x2
    800062f0:	4ac58593          	addi	a1,a1,1196 # 80008798 <syscalls+0x350>
    800062f4:	0001f517          	auipc	a0,0x1f
    800062f8:	e3450513          	addi	a0,a0,-460 # 80025128 <disk+0x2128>
    800062fc:	ffffb097          	auipc	ra,0xffffb
    80006300:	858080e7          	jalr	-1960(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006304:	100017b7          	lui	a5,0x10001
    80006308:	4398                	lw	a4,0(a5)
    8000630a:	2701                	sext.w	a4,a4
    8000630c:	747277b7          	lui	a5,0x74727
    80006310:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006314:	0ef71163          	bne	a4,a5,800063f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006318:	100017b7          	lui	a5,0x10001
    8000631c:	43dc                	lw	a5,4(a5)
    8000631e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006320:	4705                	li	a4,1
    80006322:	0ce79a63          	bne	a5,a4,800063f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006326:	100017b7          	lui	a5,0x10001
    8000632a:	479c                	lw	a5,8(a5)
    8000632c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000632e:	4709                	li	a4,2
    80006330:	0ce79363          	bne	a5,a4,800063f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006334:	100017b7          	lui	a5,0x10001
    80006338:	47d8                	lw	a4,12(a5)
    8000633a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000633c:	554d47b7          	lui	a5,0x554d4
    80006340:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006344:	0af71963          	bne	a4,a5,800063f6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006348:	100017b7          	lui	a5,0x10001
    8000634c:	4705                	li	a4,1
    8000634e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006350:	470d                	li	a4,3
    80006352:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006354:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006356:	c7ffe737          	lui	a4,0xc7ffe
    8000635a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000635e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006360:	2701                	sext.w	a4,a4
    80006362:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006364:	472d                	li	a4,11
    80006366:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006368:	473d                	li	a4,15
    8000636a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000636c:	6705                	lui	a4,0x1
    8000636e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006370:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006374:	5bdc                	lw	a5,52(a5)
    80006376:	2781                	sext.w	a5,a5
  if(max == 0)
    80006378:	c7d9                	beqz	a5,80006406 <virtio_disk_init+0x124>
  if(max < NUM)
    8000637a:	471d                	li	a4,7
    8000637c:	08f77d63          	bgeu	a4,a5,80006416 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006380:	100014b7          	lui	s1,0x10001
    80006384:	47a1                	li	a5,8
    80006386:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006388:	6609                	lui	a2,0x2
    8000638a:	4581                	li	a1,0
    8000638c:	0001d517          	auipc	a0,0x1d
    80006390:	c7450513          	addi	a0,a0,-908 # 80023000 <disk>
    80006394:	ffffb097          	auipc	ra,0xffffb
    80006398:	94c080e7          	jalr	-1716(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000639c:	0001d717          	auipc	a4,0x1d
    800063a0:	c6470713          	addi	a4,a4,-924 # 80023000 <disk>
    800063a4:	00c75793          	srli	a5,a4,0xc
    800063a8:	2781                	sext.w	a5,a5
    800063aa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063ac:	0001f797          	auipc	a5,0x1f
    800063b0:	c5478793          	addi	a5,a5,-940 # 80025000 <disk+0x2000>
    800063b4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800063b6:	0001d717          	auipc	a4,0x1d
    800063ba:	cca70713          	addi	a4,a4,-822 # 80023080 <disk+0x80>
    800063be:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800063c0:	0001e717          	auipc	a4,0x1e
    800063c4:	c4070713          	addi	a4,a4,-960 # 80024000 <disk+0x1000>
    800063c8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800063ca:	4705                	li	a4,1
    800063cc:	00e78c23          	sb	a4,24(a5)
    800063d0:	00e78ca3          	sb	a4,25(a5)
    800063d4:	00e78d23          	sb	a4,26(a5)
    800063d8:	00e78da3          	sb	a4,27(a5)
    800063dc:	00e78e23          	sb	a4,28(a5)
    800063e0:	00e78ea3          	sb	a4,29(a5)
    800063e4:	00e78f23          	sb	a4,30(a5)
    800063e8:	00e78fa3          	sb	a4,31(a5)
}
    800063ec:	60e2                	ld	ra,24(sp)
    800063ee:	6442                	ld	s0,16(sp)
    800063f0:	64a2                	ld	s1,8(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret
    panic("could not find virtio disk");
    800063f6:	00002517          	auipc	a0,0x2
    800063fa:	3b250513          	addi	a0,a0,946 # 800087a8 <syscalls+0x360>
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	140080e7          	jalr	320(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006406:	00002517          	auipc	a0,0x2
    8000640a:	3c250513          	addi	a0,a0,962 # 800087c8 <syscalls+0x380>
    8000640e:	ffffa097          	auipc	ra,0xffffa
    80006412:	130080e7          	jalr	304(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006416:	00002517          	auipc	a0,0x2
    8000641a:	3d250513          	addi	a0,a0,978 # 800087e8 <syscalls+0x3a0>
    8000641e:	ffffa097          	auipc	ra,0xffffa
    80006422:	120080e7          	jalr	288(ra) # 8000053e <panic>

0000000080006426 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006426:	7159                	addi	sp,sp,-112
    80006428:	f486                	sd	ra,104(sp)
    8000642a:	f0a2                	sd	s0,96(sp)
    8000642c:	eca6                	sd	s1,88(sp)
    8000642e:	e8ca                	sd	s2,80(sp)
    80006430:	e4ce                	sd	s3,72(sp)
    80006432:	e0d2                	sd	s4,64(sp)
    80006434:	fc56                	sd	s5,56(sp)
    80006436:	f85a                	sd	s6,48(sp)
    80006438:	f45e                	sd	s7,40(sp)
    8000643a:	f062                	sd	s8,32(sp)
    8000643c:	ec66                	sd	s9,24(sp)
    8000643e:	e86a                	sd	s10,16(sp)
    80006440:	1880                	addi	s0,sp,112
    80006442:	892a                	mv	s2,a0
    80006444:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006446:	00c52c83          	lw	s9,12(a0)
    8000644a:	001c9c9b          	slliw	s9,s9,0x1
    8000644e:	1c82                	slli	s9,s9,0x20
    80006450:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006454:	0001f517          	auipc	a0,0x1f
    80006458:	cd450513          	addi	a0,a0,-812 # 80025128 <disk+0x2128>
    8000645c:	ffffa097          	auipc	ra,0xffffa
    80006460:	788080e7          	jalr	1928(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006464:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006466:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006468:	0001db97          	auipc	s7,0x1d
    8000646c:	b98b8b93          	addi	s7,s7,-1128 # 80023000 <disk>
    80006470:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006472:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006474:	8a4e                	mv	s4,s3
    80006476:	a051                	j	800064fa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006478:	00fb86b3          	add	a3,s7,a5
    8000647c:	96da                	add	a3,a3,s6
    8000647e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006482:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006484:	0207c563          	bltz	a5,800064ae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006488:	2485                	addiw	s1,s1,1
    8000648a:	0711                	addi	a4,a4,4
    8000648c:	25548063          	beq	s1,s5,800066cc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006490:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006492:	0001f697          	auipc	a3,0x1f
    80006496:	b8668693          	addi	a3,a3,-1146 # 80025018 <disk+0x2018>
    8000649a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000649c:	0006c583          	lbu	a1,0(a3)
    800064a0:	fde1                	bnez	a1,80006478 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064a2:	2785                	addiw	a5,a5,1
    800064a4:	0685                	addi	a3,a3,1
    800064a6:	ff879be3          	bne	a5,s8,8000649c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064aa:	57fd                	li	a5,-1
    800064ac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800064ae:	02905a63          	blez	s1,800064e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064b2:	f9042503          	lw	a0,-112(s0)
    800064b6:	00000097          	auipc	ra,0x0
    800064ba:	d90080e7          	jalr	-624(ra) # 80006246 <free_desc>
      for(int j = 0; j < i; j++)
    800064be:	4785                	li	a5,1
    800064c0:	0297d163          	bge	a5,s1,800064e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064c4:	f9442503          	lw	a0,-108(s0)
    800064c8:	00000097          	auipc	ra,0x0
    800064cc:	d7e080e7          	jalr	-642(ra) # 80006246 <free_desc>
      for(int j = 0; j < i; j++)
    800064d0:	4789                	li	a5,2
    800064d2:	0097d863          	bge	a5,s1,800064e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064d6:	f9842503          	lw	a0,-104(s0)
    800064da:	00000097          	auipc	ra,0x0
    800064de:	d6c080e7          	jalr	-660(ra) # 80006246 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064e2:	0001f597          	auipc	a1,0x1f
    800064e6:	c4658593          	addi	a1,a1,-954 # 80025128 <disk+0x2128>
    800064ea:	0001f517          	auipc	a0,0x1f
    800064ee:	b2e50513          	addi	a0,a0,-1234 # 80025018 <disk+0x2018>
    800064f2:	ffffc097          	auipc	ra,0xffffc
    800064f6:	b32080e7          	jalr	-1230(ra) # 80002024 <sleep>
  for(int i = 0; i < 3; i++){
    800064fa:	f9040713          	addi	a4,s0,-112
    800064fe:	84ce                	mv	s1,s3
    80006500:	bf41                	j	80006490 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006502:	20058713          	addi	a4,a1,512
    80006506:	00471693          	slli	a3,a4,0x4
    8000650a:	0001d717          	auipc	a4,0x1d
    8000650e:	af670713          	addi	a4,a4,-1290 # 80023000 <disk>
    80006512:	9736                	add	a4,a4,a3
    80006514:	4685                	li	a3,1
    80006516:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000651a:	20058713          	addi	a4,a1,512
    8000651e:	00471693          	slli	a3,a4,0x4
    80006522:	0001d717          	auipc	a4,0x1d
    80006526:	ade70713          	addi	a4,a4,-1314 # 80023000 <disk>
    8000652a:	9736                	add	a4,a4,a3
    8000652c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006530:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006534:	7679                	lui	a2,0xffffe
    80006536:	963e                	add	a2,a2,a5
    80006538:	0001f697          	auipc	a3,0x1f
    8000653c:	ac868693          	addi	a3,a3,-1336 # 80025000 <disk+0x2000>
    80006540:	6298                	ld	a4,0(a3)
    80006542:	9732                	add	a4,a4,a2
    80006544:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006546:	6298                	ld	a4,0(a3)
    80006548:	9732                	add	a4,a4,a2
    8000654a:	4541                	li	a0,16
    8000654c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000654e:	6298                	ld	a4,0(a3)
    80006550:	9732                	add	a4,a4,a2
    80006552:	4505                	li	a0,1
    80006554:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006558:	f9442703          	lw	a4,-108(s0)
    8000655c:	6288                	ld	a0,0(a3)
    8000655e:	962a                	add	a2,a2,a0
    80006560:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006564:	0712                	slli	a4,a4,0x4
    80006566:	6290                	ld	a2,0(a3)
    80006568:	963a                	add	a2,a2,a4
    8000656a:	05890513          	addi	a0,s2,88
    8000656e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006570:	6294                	ld	a3,0(a3)
    80006572:	96ba                	add	a3,a3,a4
    80006574:	40000613          	li	a2,1024
    80006578:	c690                	sw	a2,8(a3)
  if(write)
    8000657a:	140d0063          	beqz	s10,800066ba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000657e:	0001f697          	auipc	a3,0x1f
    80006582:	a826b683          	ld	a3,-1406(a3) # 80025000 <disk+0x2000>
    80006586:	96ba                	add	a3,a3,a4
    80006588:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000658c:	0001d817          	auipc	a6,0x1d
    80006590:	a7480813          	addi	a6,a6,-1420 # 80023000 <disk>
    80006594:	0001f517          	auipc	a0,0x1f
    80006598:	a6c50513          	addi	a0,a0,-1428 # 80025000 <disk+0x2000>
    8000659c:	6114                	ld	a3,0(a0)
    8000659e:	96ba                	add	a3,a3,a4
    800065a0:	00c6d603          	lhu	a2,12(a3)
    800065a4:	00166613          	ori	a2,a2,1
    800065a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065ac:	f9842683          	lw	a3,-104(s0)
    800065b0:	6110                	ld	a2,0(a0)
    800065b2:	9732                	add	a4,a4,a2
    800065b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065b8:	20058613          	addi	a2,a1,512
    800065bc:	0612                	slli	a2,a2,0x4
    800065be:	9642                	add	a2,a2,a6
    800065c0:	577d                	li	a4,-1
    800065c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065c6:	00469713          	slli	a4,a3,0x4
    800065ca:	6114                	ld	a3,0(a0)
    800065cc:	96ba                	add	a3,a3,a4
    800065ce:	03078793          	addi	a5,a5,48
    800065d2:	97c2                	add	a5,a5,a6
    800065d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800065d6:	611c                	ld	a5,0(a0)
    800065d8:	97ba                	add	a5,a5,a4
    800065da:	4685                	li	a3,1
    800065dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065de:	611c                	ld	a5,0(a0)
    800065e0:	97ba                	add	a5,a5,a4
    800065e2:	4809                	li	a6,2
    800065e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065e8:	611c                	ld	a5,0(a0)
    800065ea:	973e                	add	a4,a4,a5
    800065ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065f8:	6518                	ld	a4,8(a0)
    800065fa:	00275783          	lhu	a5,2(a4)
    800065fe:	8b9d                	andi	a5,a5,7
    80006600:	0786                	slli	a5,a5,0x1
    80006602:	97ba                	add	a5,a5,a4
    80006604:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006608:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000660c:	6518                	ld	a4,8(a0)
    8000660e:	00275783          	lhu	a5,2(a4)
    80006612:	2785                	addiw	a5,a5,1
    80006614:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006618:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000661c:	100017b7          	lui	a5,0x10001
    80006620:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006624:	00492703          	lw	a4,4(s2)
    80006628:	4785                	li	a5,1
    8000662a:	02f71163          	bne	a4,a5,8000664c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000662e:	0001f997          	auipc	s3,0x1f
    80006632:	afa98993          	addi	s3,s3,-1286 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006636:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006638:	85ce                	mv	a1,s3
    8000663a:	854a                	mv	a0,s2
    8000663c:	ffffc097          	auipc	ra,0xffffc
    80006640:	9e8080e7          	jalr	-1560(ra) # 80002024 <sleep>
  while(b->disk == 1) {
    80006644:	00492783          	lw	a5,4(s2)
    80006648:	fe9788e3          	beq	a5,s1,80006638 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000664c:	f9042903          	lw	s2,-112(s0)
    80006650:	20090793          	addi	a5,s2,512
    80006654:	00479713          	slli	a4,a5,0x4
    80006658:	0001d797          	auipc	a5,0x1d
    8000665c:	9a878793          	addi	a5,a5,-1624 # 80023000 <disk>
    80006660:	97ba                	add	a5,a5,a4
    80006662:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006666:	0001f997          	auipc	s3,0x1f
    8000666a:	99a98993          	addi	s3,s3,-1638 # 80025000 <disk+0x2000>
    8000666e:	00491713          	slli	a4,s2,0x4
    80006672:	0009b783          	ld	a5,0(s3)
    80006676:	97ba                	add	a5,a5,a4
    80006678:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000667c:	854a                	mv	a0,s2
    8000667e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006682:	00000097          	auipc	ra,0x0
    80006686:	bc4080e7          	jalr	-1084(ra) # 80006246 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000668a:	8885                	andi	s1,s1,1
    8000668c:	f0ed                	bnez	s1,8000666e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000668e:	0001f517          	auipc	a0,0x1f
    80006692:	a9a50513          	addi	a0,a0,-1382 # 80025128 <disk+0x2128>
    80006696:	ffffa097          	auipc	ra,0xffffa
    8000669a:	602080e7          	jalr	1538(ra) # 80000c98 <release>
}
    8000669e:	70a6                	ld	ra,104(sp)
    800066a0:	7406                	ld	s0,96(sp)
    800066a2:	64e6                	ld	s1,88(sp)
    800066a4:	6946                	ld	s2,80(sp)
    800066a6:	69a6                	ld	s3,72(sp)
    800066a8:	6a06                	ld	s4,64(sp)
    800066aa:	7ae2                	ld	s5,56(sp)
    800066ac:	7b42                	ld	s6,48(sp)
    800066ae:	7ba2                	ld	s7,40(sp)
    800066b0:	7c02                	ld	s8,32(sp)
    800066b2:	6ce2                	ld	s9,24(sp)
    800066b4:	6d42                	ld	s10,16(sp)
    800066b6:	6165                	addi	sp,sp,112
    800066b8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066ba:	0001f697          	auipc	a3,0x1f
    800066be:	9466b683          	ld	a3,-1722(a3) # 80025000 <disk+0x2000>
    800066c2:	96ba                	add	a3,a3,a4
    800066c4:	4609                	li	a2,2
    800066c6:	00c69623          	sh	a2,12(a3)
    800066ca:	b5c9                	j	8000658c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066cc:	f9042583          	lw	a1,-112(s0)
    800066d0:	20058793          	addi	a5,a1,512
    800066d4:	0792                	slli	a5,a5,0x4
    800066d6:	0001d517          	auipc	a0,0x1d
    800066da:	9d250513          	addi	a0,a0,-1582 # 800230a8 <disk+0xa8>
    800066de:	953e                	add	a0,a0,a5
  if(write)
    800066e0:	e20d11e3          	bnez	s10,80006502 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800066e4:	20058713          	addi	a4,a1,512
    800066e8:	00471693          	slli	a3,a4,0x4
    800066ec:	0001d717          	auipc	a4,0x1d
    800066f0:	91470713          	addi	a4,a4,-1772 # 80023000 <disk>
    800066f4:	9736                	add	a4,a4,a3
    800066f6:	0a072423          	sw	zero,168(a4)
    800066fa:	b505                	j	8000651a <virtio_disk_rw+0xf4>

00000000800066fc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066fc:	1101                	addi	sp,sp,-32
    800066fe:	ec06                	sd	ra,24(sp)
    80006700:	e822                	sd	s0,16(sp)
    80006702:	e426                	sd	s1,8(sp)
    80006704:	e04a                	sd	s2,0(sp)
    80006706:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006708:	0001f517          	auipc	a0,0x1f
    8000670c:	a2050513          	addi	a0,a0,-1504 # 80025128 <disk+0x2128>
    80006710:	ffffa097          	auipc	ra,0xffffa
    80006714:	4d4080e7          	jalr	1236(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006718:	10001737          	lui	a4,0x10001
    8000671c:	533c                	lw	a5,96(a4)
    8000671e:	8b8d                	andi	a5,a5,3
    80006720:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006722:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006726:	0001f797          	auipc	a5,0x1f
    8000672a:	8da78793          	addi	a5,a5,-1830 # 80025000 <disk+0x2000>
    8000672e:	6b94                	ld	a3,16(a5)
    80006730:	0207d703          	lhu	a4,32(a5)
    80006734:	0026d783          	lhu	a5,2(a3)
    80006738:	06f70163          	beq	a4,a5,8000679a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000673c:	0001d917          	auipc	s2,0x1d
    80006740:	8c490913          	addi	s2,s2,-1852 # 80023000 <disk>
    80006744:	0001f497          	auipc	s1,0x1f
    80006748:	8bc48493          	addi	s1,s1,-1860 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000674c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006750:	6898                	ld	a4,16(s1)
    80006752:	0204d783          	lhu	a5,32(s1)
    80006756:	8b9d                	andi	a5,a5,7
    80006758:	078e                	slli	a5,a5,0x3
    8000675a:	97ba                	add	a5,a5,a4
    8000675c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000675e:	20078713          	addi	a4,a5,512
    80006762:	0712                	slli	a4,a4,0x4
    80006764:	974a                	add	a4,a4,s2
    80006766:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000676a:	e731                	bnez	a4,800067b6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000676c:	20078793          	addi	a5,a5,512
    80006770:	0792                	slli	a5,a5,0x4
    80006772:	97ca                	add	a5,a5,s2
    80006774:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006776:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000677a:	ffffc097          	auipc	ra,0xffffc
    8000677e:	c2a080e7          	jalr	-982(ra) # 800023a4 <wakeup>

    disk.used_idx += 1;
    80006782:	0204d783          	lhu	a5,32(s1)
    80006786:	2785                	addiw	a5,a5,1
    80006788:	17c2                	slli	a5,a5,0x30
    8000678a:	93c1                	srli	a5,a5,0x30
    8000678c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006790:	6898                	ld	a4,16(s1)
    80006792:	00275703          	lhu	a4,2(a4)
    80006796:	faf71be3          	bne	a4,a5,8000674c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000679a:	0001f517          	auipc	a0,0x1f
    8000679e:	98e50513          	addi	a0,a0,-1650 # 80025128 <disk+0x2128>
    800067a2:	ffffa097          	auipc	ra,0xffffa
    800067a6:	4f6080e7          	jalr	1270(ra) # 80000c98 <release>
}
    800067aa:	60e2                	ld	ra,24(sp)
    800067ac:	6442                	ld	s0,16(sp)
    800067ae:	64a2                	ld	s1,8(sp)
    800067b0:	6902                	ld	s2,0(sp)
    800067b2:	6105                	addi	sp,sp,32
    800067b4:	8082                	ret
      panic("virtio_disk_intr status");
    800067b6:	00002517          	auipc	a0,0x2
    800067ba:	05250513          	addi	a0,a0,82 # 80008808 <syscalls+0x3c0>
    800067be:	ffffa097          	auipc	ra,0xffffa
    800067c2:	d80080e7          	jalr	-640(ra) # 8000053e <panic>

00000000800067c6 <cas>:
    800067c6:	100522af          	lr.w	t0,(a0)
    800067ca:	00b29563          	bne	t0,a1,800067d4 <fail>
    800067ce:	18c5252f          	sc.w	a0,a2,(a0)
    800067d2:	8082                	ret

00000000800067d4 <fail>:
    800067d4:	4505                	li	a0,1
    800067d6:	8082                	ret
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
