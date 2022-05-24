
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    800001d8:	e4c080e7          	jalr	-436(ra) # 80002020 <sleep>
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
    8000044a:	f54080e7          	jalr	-172(ra) # 8000239a <wakeup>
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
    800008a4:	afa080e7          	jalr	-1286(ra) # 8000239a <wakeup>
    
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
    80000930:	6f4080e7          	jalr	1780(ra) # 80002020 <sleep>
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
    80000ed8:	d4e080e7          	jalr	-690(ra) # 80002c22 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	2e4080e7          	jalr	740(ra) # 800061c0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	bfa080e7          	jalr	-1030(ra) # 80002ade <scheduler>
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
    80000f50:	cae080e7          	jalr	-850(ra) # 80002bfa <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	cce080e7          	jalr	-818(ra) # 80002c22 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	24e080e7          	jalr	590(ra) # 800061aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	25c080e7          	jalr	604(ra) # 800061c0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	442080e7          	jalr	1090(ra) # 800033ae <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	ad2080e7          	jalr	-1326(ra) # 80003a46 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	a7c080e7          	jalr	-1412(ra) # 800049f8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	35e080e7          	jalr	862(ra) # 800062e2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	910080e7          	jalr	-1776(ra) # 8000289c <userinit>
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
    80001960:	ef47a783          	lw	a5,-268(a5) # 80008850 <first.1718>
    80001964:	eb89                	bnez	a5,80001976 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001966:	00001097          	auipc	ra,0x1
    8000196a:	2d4080e7          	jalr	724(ra) # 80002c3a <usertrapret>
}
    8000196e:	60a2                	ld	ra,8(sp)
    80001970:	6402                	ld	s0,0(sp)
    80001972:	0141                	addi	sp,sp,16
    80001974:	8082                	ret
    first = 0;
    80001976:	00007797          	auipc	a5,0x7
    8000197a:	ec07ad23          	sw	zero,-294(a5) # 80008850 <first.1718>
    fsinit(ROOTDEV);
    8000197e:	4505                	li	a0,1
    80001980:	00002097          	auipc	ra,0x2
    80001984:	046080e7          	jalr	70(ra) # 800039c6 <fsinit>
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
    8000199a:	eca90913          	addi	s2,s2,-310 # 80008860 <nextpid>
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
    80001ba4:	ff0080e7          	jalr	-16(ra) # 80002b90 <swtch>
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
    80001d06:	5e6b8b93          	addi	s7,s7,1510 # 800082e8 <states.1768>
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
//void initlock(struct spinlock *, char *)

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
    80001ef2:	96ea8a93          	addi	s5,s5,-1682 # 8000885c <unused_head>
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
      c->runnable_head = -1;
    80001f56:	08d7a023          	sw	a3,128(a5)
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001f5a:	0a878793          	addi	a5,a5,168
    80001f5e:	fee79ce3          	bne	a5,a4,80001f56 <procinit+0xe2>
}
    80001f62:	60e6                	ld	ra,88(sp)
    80001f64:	6446                	ld	s0,80(sp)
    80001f66:	64a6                	ld	s1,72(sp)
    80001f68:	6906                	ld	s2,64(sp)
    80001f6a:	79e2                	ld	s3,56(sp)
    80001f6c:	7a42                	ld	s4,48(sp)
    80001f6e:	7aa2                	ld	s5,40(sp)
    80001f70:	7b02                	ld	s6,32(sp)
    80001f72:	6be2                	ld	s7,24(sp)
    80001f74:	6c42                	ld	s8,16(sp)
    80001f76:	6ca2                	ld	s9,8(sp)
    80001f78:	6d02                	ld	s10,0(sp)
    80001f7a:	6125                	addi	sp,sp,96
    80001f7c:	8082                	ret

0000000080001f7e <yield>:
{
    80001f7e:	1101                	addi	sp,sp,-32
    80001f80:	ec06                	sd	ra,24(sp)
    80001f82:	e822                	sd	s0,16(sp)
    80001f84:	e426                	sd	s1,8(sp)
    80001f86:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f88:	00000097          	auipc	ra,0x0
    80001f8c:	97e080e7          	jalr	-1666(ra) # 80001906 <myproc>
    80001f90:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	c52080e7          	jalr	-942(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80001f9a:	478d                	li	a5,3
    80001f9c:	cc9c                	sw	a5,24(s1)
  add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    80001f9e:	58dc                	lw	a5,52(s1)
    80001fa0:	0a800513          	li	a0,168
    80001fa4:	02a787b3          	mul	a5,a5,a0
    80001fa8:	0000f517          	auipc	a0,0xf
    80001fac:	2f850513          	addi	a0,a0,760 # 800112a0 <cpus>
    80001fb0:	08878613          	addi	a2,a5,136
    80001fb4:	08078793          	addi	a5,a5,128
    80001fb8:	962a                	add	a2,a2,a0
    80001fba:	85a6                	mv	a1,s1
    80001fbc:	953e                	add	a0,a0,a5
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	ddc080e7          	jalr	-548(ra) # 80001d9a <add_to_list>
  sched();
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	b5e080e7          	jalr	-1186(ra) # 80001b24 <sched>
  release(&p->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	cc8080e7          	jalr	-824(ra) # 80000c98 <release>
}
    80001fd8:	60e2                	ld	ra,24(sp)
    80001fda:	6442                	ld	s0,16(sp)
    80001fdc:	64a2                	ld	s1,8(sp)
    80001fde:	6105                	addi	sp,sp,32
    80001fe0:	8082                	ret

0000000080001fe2 <set_cpu>:
{
    80001fe2:	1101                	addi	sp,sp,-32
    80001fe4:	ec06                	sd	ra,24(sp)
    80001fe6:	e822                	sd	s0,16(sp)
    80001fe8:	e426                	sd	s1,8(sp)
    80001fea:	1000                	addi	s0,sp,32
    80001fec:	84aa                	mv	s1,a0
    struct proc* p = myproc();
    80001fee:	00000097          	auipc	ra,0x0
    80001ff2:	918080e7          	jalr	-1768(ra) # 80001906 <myproc>
    if(cas(&p->cpu_num, curr_cpu, cpu_num) !=0)
    80001ff6:	8626                	mv	a2,s1
    80001ff8:	594c                	lw	a1,52(a0)
    80001ffa:	03450513          	addi	a0,a0,52
    80001ffe:	00004097          	auipc	ra,0x4
    80002002:	7c8080e7          	jalr	1992(ra) # 800067c6 <cas>
    80002006:	e919                	bnez	a0,8000201c <set_cpu+0x3a>
    yield();
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	f76080e7          	jalr	-138(ra) # 80001f7e <yield>
    return cpu_num;
    80002010:	8526                	mv	a0,s1
}
    80002012:	60e2                	ld	ra,24(sp)
    80002014:	6442                	ld	s0,16(sp)
    80002016:	64a2                	ld	s1,8(sp)
    80002018:	6105                	addi	sp,sp,32
    8000201a:	8082                	ret
        return -1;
    8000201c:	557d                	li	a0,-1
    8000201e:	bfd5                	j	80002012 <set_cpu+0x30>

0000000080002020 <sleep>:
{
    80002020:	7179                	addi	sp,sp,-48
    80002022:	f406                	sd	ra,40(sp)
    80002024:	f022                	sd	s0,32(sp)
    80002026:	ec26                	sd	s1,24(sp)
    80002028:	e84a                	sd	s2,16(sp)
    8000202a:	e44e                	sd	s3,8(sp)
    8000202c:	1800                	addi	s0,sp,48
    8000202e:	89aa                	mv	s3,a0
    80002030:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	8d4080e7          	jalr	-1836(ra) # 80001906 <myproc>
    8000203a:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	ba8080e7          	jalr	-1112(ra) # 80000be4 <acquire>
  add_to_list(&sleeping_head, p, &lock_sleeping_list);
    80002044:	0000f617          	auipc	a2,0xf
    80002048:	7e460613          	addi	a2,a2,2020 # 80011828 <lock_sleeping_list>
    8000204c:	85a6                	mv	a1,s1
    8000204e:	00007517          	auipc	a0,0x7
    80002052:	80a50513          	addi	a0,a0,-2038 # 80008858 <sleeping_head>
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	d44080e7          	jalr	-700(ra) # 80001d9a <add_to_list>
  release(lk);
    8000205e:	854a                	mv	a0,s2
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	c38080e7          	jalr	-968(ra) # 80000c98 <release>
  p->chan = chan;
    80002068:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000206c:	4789                	li	a5,2
    8000206e:	cc9c                	sw	a5,24(s1)
  sched();
    80002070:	00000097          	auipc	ra,0x0
    80002074:	ab4080e7          	jalr	-1356(ra) # 80001b24 <sched>
  p->chan = 0;
    80002078:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    8000207c:	8526                	mv	a0,s1
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	c1a080e7          	jalr	-998(ra) # 80000c98 <release>
  acquire(lk);
    80002086:	854a                	mv	a0,s2
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	b5c080e7          	jalr	-1188(ra) # 80000be4 <acquire>
}
    80002090:	70a2                	ld	ra,40(sp)
    80002092:	7402                	ld	s0,32(sp)
    80002094:	64e2                	ld	s1,24(sp)
    80002096:	6942                	ld	s2,16(sp)
    80002098:	69a2                	ld	s3,8(sp)
    8000209a:	6145                	addi	sp,sp,48
    8000209c:	8082                	ret

000000008000209e <remove_from_list>:

int remove_from_list(int* curr_proc_index, struct proc* proc_to_remove, struct spinlock* lock) {
    8000209e:	7139                	addi	sp,sp,-64
    800020a0:	fc06                	sd	ra,56(sp)
    800020a2:	f822                	sd	s0,48(sp)
    800020a4:	f426                	sd	s1,40(sp)
    800020a6:	f04a                	sd	s2,32(sp)
    800020a8:	ec4e                	sd	s3,24(sp)
    800020aa:	e852                	sd	s4,16(sp)
    800020ac:	e456                	sd	s5,8(sp)
    800020ae:	e05a                	sd	s6,0(sp)
    800020b0:	0080                	addi	s0,sp,64
    800020b2:	84aa                	mv	s1,a0
    800020b4:	892e                	mv	s2,a1
    800020b6:	89b2                	mv	s3,a2
  acquire(lock);
    800020b8:	8532                	mv	a0,a2
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	b2a080e7          	jalr	-1238(ra) # 80000be4 <acquire>
  if(*curr_proc_index == -1) 
    800020c2:	0004aa03          	lw	s4,0(s1)
    800020c6:	57fd                	li	a5,-1
    800020c8:	0afa0663          	beq	s4,a5,80002174 <remove_from_list+0xd6>
  {
      release(lock);
      return -1;
  }
  acquire(&proc_to_remove->proc_lock);
    800020cc:	04090b13          	addi	s6,s2,64
    800020d0:	855a                	mv	a0,s6
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b12080e7          	jalr	-1262(ra) # 80000be4 <acquire>

  if(*curr_proc_index == proc_to_remove->proc_index){
    800020da:	4088                	lw	a0,0(s1)
    800020dc:	03c92783          	lw	a5,60(s2)
    800020e0:	0aa78063          	beq	a5,a0,80002180 <remove_from_list+0xe2>
      release(&proc_to_remove->proc_lock);
      release(lock);
      return 1;
  }
  
  struct proc* curr_node = &proc[*curr_proc_index];
    800020e4:	18800793          	li	a5,392
    800020e8:	02f50533          	mul	a0,a0,a5
    800020ec:	0000f797          	auipc	a5,0xf
    800020f0:	76c78793          	addi	a5,a5,1900 # 80011858 <proc>
    800020f4:	00f504b3          	add	s1,a0,a5
  acquire(&curr_node->proc_lock);
    800020f8:	04050513          	addi	a0,a0,64
    800020fc:	953e                	add	a0,a0,a5
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	ae6080e7          	jalr	-1306(ra) # 80000be4 <acquire>
  release(lock);
    80002106:	854e                	mv	a0,s3
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	b90080e7          	jalr	-1136(ra) # 80000c98 <release>
  
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002110:	5c88                	lw	a0,56(s1)
    80002112:	57fd                	li	a5,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80002114:	18800a13          	li	s4,392
    80002118:	0000f997          	auipc	s3,0xf
    8000211c:	74098993          	addi	s3,s3,1856 # 80011858 <proc>
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002120:	5afd                	li	s5,-1
    80002122:	02f50c63          	beq	a0,a5,8000215a <remove_from_list+0xbc>
    80002126:	03c92783          	lw	a5,60(s2)
    8000212a:	06a78a63          	beq	a5,a0,8000219e <remove_from_list+0x100>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    8000212e:	03450533          	mul	a0,a0,s4
    80002132:	04050513          	addi	a0,a0,64
    80002136:	954e                	add	a0,a0,s3
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	aac080e7          	jalr	-1364(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    80002140:	04048513          	addi	a0,s1,64
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	b54080e7          	jalr	-1196(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    8000214c:	5c84                	lw	s1,56(s1)
    8000214e:	034484b3          	mul	s1,s1,s4
    80002152:	94ce                	add	s1,s1,s3
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002154:	5c88                	lw	a0,56(s1)
    80002156:	fd5518e3          	bne	a0,s5,80002126 <remove_from_list+0x88>
  }
  if(curr_node->next_proc_index == -1){
    release(&proc_to_remove->proc_lock);
    8000215a:	855a                	mv	a0,s6
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b3c080e7          	jalr	-1220(ra) # 80000c98 <release>
    release(&curr_node->proc_lock);
    80002164:	04048513          	addi	a0,s1,64
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b30080e7          	jalr	-1232(ra) # 80000c98 <release>
    return -1;
    80002170:	5a7d                	li	s4,-1
    80002172:	a899                	j	800021c8 <remove_from_list+0x12a>
      release(lock);
    80002174:	854e                	mv	a0,s3
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b22080e7          	jalr	-1246(ra) # 80000c98 <release>
      return -1;
    8000217e:	a0a9                	j	800021c8 <remove_from_list+0x12a>
      proc_to_remove->next_proc_index = -1;
    80002180:	57fd                	li	a5,-1
    80002182:	02f92c23          	sw	a5,56(s2)
      release(&proc_to_remove->proc_lock);
    80002186:	855a                	mv	a0,s6
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	b10080e7          	jalr	-1264(ra) # 80000c98 <release>
      release(lock);
    80002190:	854e                	mv	a0,s3
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
      return 1;
    8000219a:	4a05                	li	s4,1
    8000219c:	a035                	j	800021c8 <remove_from_list+0x12a>
  if(curr_node->next_proc_index == -1){
    8000219e:	57fd                	li	a5,-1
    800021a0:	faf50de3          	beq	a0,a5,8000215a <remove_from_list+0xbc>
  }

  curr_node->next_proc_index = proc_to_remove->next_proc_index;
    800021a4:	03892783          	lw	a5,56(s2)
    800021a8:	dc9c                	sw	a5,56(s1)
  proc_to_remove->next_proc_index = -1;
    800021aa:	57fd                	li	a5,-1
    800021ac:	02f92c23          	sw	a5,56(s2)
  release(&proc_to_remove->proc_lock);
    800021b0:	855a                	mv	a0,s6
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	ae6080e7          	jalr	-1306(ra) # 80000c98 <release>
  release(&curr_node->proc_lock);
    800021ba:	04048513          	addi	a0,s1,64
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	ada080e7          	jalr	-1318(ra) # 80000c98 <release>
  return 1;
    800021c6:	4a05                	li	s4,1
}
    800021c8:	8552                	mv	a0,s4
    800021ca:	70e2                	ld	ra,56(sp)
    800021cc:	7442                	ld	s0,48(sp)
    800021ce:	74a2                	ld	s1,40(sp)
    800021d0:	7902                	ld	s2,32(sp)
    800021d2:	69e2                	ld	s3,24(sp)
    800021d4:	6a42                	ld	s4,16(sp)
    800021d6:	6aa2                	ld	s5,8(sp)
    800021d8:	6b02                	ld	s6,0(sp)
    800021da:	6121                	addi	sp,sp,64
    800021dc:	8082                	ret

00000000800021de <freeproc>:
{
    800021de:	1101                	addi	sp,sp,-32
    800021e0:	ec06                	sd	ra,24(sp)
    800021e2:	e822                	sd	s0,16(sp)
    800021e4:	e426                	sd	s1,8(sp)
    800021e6:	1000                	addi	s0,sp,32
    800021e8:	84aa                	mv	s1,a0
  if(p->trapframe)
    800021ea:	7d28                	ld	a0,120(a0)
    800021ec:	c509                	beqz	a0,800021f6 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	80a080e7          	jalr	-2038(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    800021f6:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    800021fa:	78a8                	ld	a0,112(s1)
    800021fc:	c511                	beqz	a0,80002208 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800021fe:	74ac                	ld	a1,104(s1)
    80002200:	00000097          	auipc	ra,0x0
    80002204:	85e080e7          	jalr	-1954(ra) # 80001a5e <proc_freepagetable>
  p->pagetable = 0;
    80002208:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    8000220c:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80002210:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002214:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002218:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    8000221c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002220:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002224:	0204a623          	sw	zero,44(s1)
  if(remove_from_list(&zombie_head, p, &lock_zombie_list) == 1){
    80002228:	0000f617          	auipc	a2,0xf
    8000222c:	61860613          	addi	a2,a2,1560 # 80011840 <lock_zombie_list>
    80002230:	85a6                	mv	a1,s1
    80002232:	00006517          	auipc	a0,0x6
    80002236:	62250513          	addi	a0,a0,1570 # 80008854 <zombie_head>
    8000223a:	00000097          	auipc	ra,0x0
    8000223e:	e64080e7          	jalr	-412(ra) # 8000209e <remove_from_list>
    80002242:	4785                	li	a5,1
    80002244:	00f50763          	beq	a0,a5,80002252 <freeproc+0x74>
}
    80002248:	60e2                	ld	ra,24(sp)
    8000224a:	6442                	ld	s0,16(sp)
    8000224c:	64a2                	ld	s1,8(sp)
    8000224e:	6105                	addi	sp,sp,32
    80002250:	8082                	ret
    p->state = UNUSED;
    80002252:	0004ac23          	sw	zero,24(s1)
    add_to_list(&unused_head, p, &lock_unused_list);
    80002256:	0000f617          	auipc	a2,0xf
    8000225a:	5ba60613          	addi	a2,a2,1466 # 80011810 <lock_unused_list>
    8000225e:	85a6                	mv	a1,s1
    80002260:	00006517          	auipc	a0,0x6
    80002264:	5fc50513          	addi	a0,a0,1532 # 8000885c <unused_head>
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	b32080e7          	jalr	-1230(ra) # 80001d9a <add_to_list>
}
    80002270:	bfe1                	j	80002248 <freeproc+0x6a>

0000000080002272 <wait>:
{
    80002272:	715d                	addi	sp,sp,-80
    80002274:	e486                	sd	ra,72(sp)
    80002276:	e0a2                	sd	s0,64(sp)
    80002278:	fc26                	sd	s1,56(sp)
    8000227a:	f84a                	sd	s2,48(sp)
    8000227c:	f44e                	sd	s3,40(sp)
    8000227e:	f052                	sd	s4,32(sp)
    80002280:	ec56                	sd	s5,24(sp)
    80002282:	e85a                	sd	s6,16(sp)
    80002284:	e45e                	sd	s7,8(sp)
    80002286:	e062                	sd	s8,0(sp)
    80002288:	0880                	addi	s0,sp,80
    8000228a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	67a080e7          	jalr	1658(ra) # 80001906 <myproc>
    80002294:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002296:	0000f517          	auipc	a0,0xf
    8000229a:	56250513          	addi	a0,a0,1378 # 800117f8 <wait_lock>
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	946080e7          	jalr	-1722(ra) # 80000be4 <acquire>
    havekids = 0;
    800022a6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022a8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022aa:	00015997          	auipc	s3,0x15
    800022ae:	7ae98993          	addi	s3,s3,1966 # 80017a58 <tickslock>
        havekids = 1;
    800022b2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022b4:	0000fc17          	auipc	s8,0xf
    800022b8:	544c0c13          	addi	s8,s8,1348 # 800117f8 <wait_lock>
    havekids = 0;
    800022bc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022be:	0000f497          	auipc	s1,0xf
    800022c2:	59a48493          	addi	s1,s1,1434 # 80011858 <proc>
    800022c6:	a0bd                	j	80002334 <wait+0xc2>
          pid = np->pid;
    800022c8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022cc:	000b0e63          	beqz	s6,800022e8 <wait+0x76>
    800022d0:	4691                	li	a3,4
    800022d2:	02c48613          	addi	a2,s1,44
    800022d6:	85da                	mv	a1,s6
    800022d8:	07093503          	ld	a0,112(s2)
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	396080e7          	jalr	918(ra) # 80001672 <copyout>
    800022e4:	02054563          	bltz	a0,8000230e <wait+0x9c>
          freeproc(np);
    800022e8:	8526                	mv	a0,s1
    800022ea:	00000097          	auipc	ra,0x0
    800022ee:	ef4080e7          	jalr	-268(ra) # 800021de <freeproc>
          release(&np->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	9a4080e7          	jalr	-1628(ra) # 80000c98 <release>
          release(&wait_lock);
    800022fc:	0000f517          	auipc	a0,0xf
    80002300:	4fc50513          	addi	a0,a0,1276 # 800117f8 <wait_lock>
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	994080e7          	jalr	-1644(ra) # 80000c98 <release>
          return pid;
    8000230c:	a09d                	j	80002372 <wait+0x100>
            release(&np->lock);
    8000230e:	8526                	mv	a0,s1
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	988080e7          	jalr	-1656(ra) # 80000c98 <release>
            release(&wait_lock);
    80002318:	0000f517          	auipc	a0,0xf
    8000231c:	4e050513          	addi	a0,a0,1248 # 800117f8 <wait_lock>
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	978080e7          	jalr	-1672(ra) # 80000c98 <release>
            return -1;
    80002328:	59fd                	li	s3,-1
    8000232a:	a0a1                	j	80002372 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000232c:	18848493          	addi	s1,s1,392
    80002330:	03348463          	beq	s1,s3,80002358 <wait+0xe6>
      if(np->parent == p){
    80002334:	6cbc                	ld	a5,88(s1)
    80002336:	ff279be3          	bne	a5,s2,8000232c <wait+0xba>
        acquire(&np->lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	8a8080e7          	jalr	-1880(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002344:	4c9c                	lw	a5,24(s1)
    80002346:	f94781e3          	beq	a5,s4,800022c8 <wait+0x56>
        release(&np->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	94c080e7          	jalr	-1716(ra) # 80000c98 <release>
        havekids = 1;
    80002354:	8756                	mv	a4,s5
    80002356:	bfd9                	j	8000232c <wait+0xba>
    if(!havekids || p->killed){
    80002358:	c701                	beqz	a4,80002360 <wait+0xee>
    8000235a:	02892783          	lw	a5,40(s2)
    8000235e:	c79d                	beqz	a5,8000238c <wait+0x11a>
      release(&wait_lock);
    80002360:	0000f517          	auipc	a0,0xf
    80002364:	49850513          	addi	a0,a0,1176 # 800117f8 <wait_lock>
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	930080e7          	jalr	-1744(ra) # 80000c98 <release>
      return -1;
    80002370:	59fd                	li	s3,-1
}
    80002372:	854e                	mv	a0,s3
    80002374:	60a6                	ld	ra,72(sp)
    80002376:	6406                	ld	s0,64(sp)
    80002378:	74e2                	ld	s1,56(sp)
    8000237a:	7942                	ld	s2,48(sp)
    8000237c:	79a2                	ld	s3,40(sp)
    8000237e:	7a02                	ld	s4,32(sp)
    80002380:	6ae2                	ld	s5,24(sp)
    80002382:	6b42                	ld	s6,16(sp)
    80002384:	6ba2                	ld	s7,8(sp)
    80002386:	6c02                	ld	s8,0(sp)
    80002388:	6161                	addi	sp,sp,80
    8000238a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000238c:	85e2                	mv	a1,s8
    8000238e:	854a                	mv	a0,s2
    80002390:	00000097          	auipc	ra,0x0
    80002394:	c90080e7          	jalr	-880(ra) # 80002020 <sleep>
    havekids = 0;
    80002398:	b715                	j	800022bc <wait+0x4a>

000000008000239a <wakeup>:
{
    8000239a:	7159                	addi	sp,sp,-112
    8000239c:	f486                	sd	ra,104(sp)
    8000239e:	f0a2                	sd	s0,96(sp)
    800023a0:	eca6                	sd	s1,88(sp)
    800023a2:	e8ca                	sd	s2,80(sp)
    800023a4:	e4ce                	sd	s3,72(sp)
    800023a6:	e0d2                	sd	s4,64(sp)
    800023a8:	fc56                	sd	s5,56(sp)
    800023aa:	f85a                	sd	s6,48(sp)
    800023ac:	f45e                	sd	s7,40(sp)
    800023ae:	f062                	sd	s8,32(sp)
    800023b0:	ec66                	sd	s9,24(sp)
    800023b2:	e86a                	sd	s10,16(sp)
    800023b4:	e46e                	sd	s11,8(sp)
    800023b6:	1880                	addi	s0,sp,112
    800023b8:	8b2a                	mv	s6,a0
  acquire(&lock_sleeping_list);
    800023ba:	0000f517          	auipc	a0,0xf
    800023be:	46e50513          	addi	a0,a0,1134 # 80011828 <lock_sleeping_list>
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	822080e7          	jalr	-2014(ra) # 80000be4 <acquire>
  if(sleeping_head != -1){
    800023ca:	00006497          	auipc	s1,0x6
    800023ce:	48e4a483          	lw	s1,1166(s1) # 80008858 <sleeping_head>
    800023d2:	57fd                	li	a5,-1
    800023d4:	10f48463          	beq	s1,a5,800024dc <wakeup+0x142>
    p = &proc[sleeping_head];
    800023d8:	18800793          	li	a5,392
    800023dc:	02f484b3          	mul	s1,s1,a5
    800023e0:	0000f797          	auipc	a5,0xf
    800023e4:	47878793          	addi	a5,a5,1144 # 80011858 <proc>
    800023e8:	94be                	add	s1,s1,a5
    release(&lock_sleeping_list);
    800023ea:	0000f517          	auipc	a0,0xf
    800023ee:	43e50513          	addi	a0,a0,1086 # 80011828 <lock_sleeping_list>
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
      if (p->state == SLEEPING && p->chan == chan) {
    800023fa:	4a09                	li	s4,2
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    800023fc:	0000fc97          	auipc	s9,0xf
    80002400:	42cc8c93          	addi	s9,s9,1068 # 80011828 <lock_sleeping_list>
    80002404:	00006c17          	auipc	s8,0x6
    80002408:	454c0c13          	addi	s8,s8,1108 # 80008858 <sleeping_head>
              p->state = RUNNABLE;
    8000240c:	4d8d                	li	s11,3
              if(auto_balanced){
    8000240e:	00007d17          	auipc	s10,0x7
    80002412:	c1ad0d13          	addi	s10,s10,-998 # 80009028 <auto_balanced>
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    80002416:	0000fb97          	auipc	s7,0xf
    8000241a:	e8ab8b93          	addi	s7,s7,-374 # 800112a0 <cpus>
        p = &proc[curr_proc];
    8000241e:	0000fa97          	auipc	s5,0xf
    80002422:	43aa8a93          	addi	s5,s5,1082 # 80011858 <proc>
    80002426:	a88d                	j	80002498 <wakeup+0xfe>
      if (p->state == SLEEPING && p->chan == chan) {
    80002428:	709c                	ld	a5,32(s1)
    8000242a:	09679263          	bne	a5,s6,800024ae <wakeup+0x114>
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    8000242e:	8666                	mv	a2,s9
    80002430:	85a6                	mv	a1,s1
    80002432:	8562                	mv	a0,s8
    80002434:	00000097          	auipc	ra,0x0
    80002438:	c6a080e7          	jalr	-918(ra) # 8000209e <remove_from_list>
    8000243c:	c92d                	beqz	a0,800024ae <wakeup+0x114>
              p->state = RUNNABLE;
    8000243e:	01b4ac23          	sw	s11,24(s1)
              if(auto_balanced){
    80002442:	000d2783          	lw	a5,0(s10)
    80002446:	c789                	beqz	a5,80002450 <wakeup+0xb6>
                if(p->cpu_num == cpu_num){
    80002448:	58dc                	lw	a5,52(s1)
    8000244a:	c785                	beqz	a5,80002472 <wakeup+0xd8>
                p->cpu_num = cpu_num;
    8000244c:	0204aa23          	sw	zero,52(s1)
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    80002450:	58c8                	lw	a0,52(s1)
    80002452:	0a800793          	li	a5,168
    80002456:	02f50533          	mul	a0,a0,a5
    8000245a:	08850613          	addi	a2,a0,136
    8000245e:	08050513          	addi	a0,a0,128
    80002462:	965e                	add	a2,a2,s7
    80002464:	85a6                	mv	a1,s1
    80002466:	955e                	add	a0,a0,s7
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	932080e7          	jalr	-1742(ra) # 80001d9a <add_to_list>
    80002470:	a83d                	j	800024ae <wakeup+0x114>
                  while(cas(&c->counter, c->counter, c->counter + 1) != 0);
    80002472:	0a0ba583          	lw	a1,160(s7)
    80002476:	0015861b          	addiw	a2,a1,1
    8000247a:	0000f517          	auipc	a0,0xf
    8000247e:	ec650513          	addi	a0,a0,-314 # 80011340 <cpus+0xa0>
    80002482:	00004097          	auipc	ra,0x4
    80002486:	344080e7          	jalr	836(ra) # 800067c6 <cas>
    8000248a:	f565                	bnez	a0,80002472 <wakeup+0xd8>
    8000248c:	b7c1                	j	8000244c <wakeup+0xb2>
        p = &proc[curr_proc];
    8000248e:	18800493          	li	s1,392
    80002492:	029904b3          	mul	s1,s2,s1
    80002496:	94d6                	add	s1,s1,s5
      acquire(&p->lock);
    80002498:	89a6                	mv	s3,s1
    8000249a:	8526                	mv	a0,s1
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	748080e7          	jalr	1864(ra) # 80000be4 <acquire>
      int next_proc = p->next_proc_index;
    800024a4:	0384a903          	lw	s2,56(s1)
      if (p->state == SLEEPING && p->chan == chan) {
    800024a8:	4c9c                	lw	a5,24(s1)
    800024aa:	f7478fe3          	beq	a5,s4,80002428 <wakeup+0x8e>
      release(&p->lock);
    800024ae:	854e                	mv	a0,s3
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	7e8080e7          	jalr	2024(ra) # 80000c98 <release>
      if(curr_proc != -1) {
    800024b8:	57fd                	li	a5,-1
    800024ba:	fcf91ae3          	bne	s2,a5,8000248e <wakeup+0xf4>
}
    800024be:	70a6                	ld	ra,104(sp)
    800024c0:	7406                	ld	s0,96(sp)
    800024c2:	64e6                	ld	s1,88(sp)
    800024c4:	6946                	ld	s2,80(sp)
    800024c6:	69a6                	ld	s3,72(sp)
    800024c8:	6a06                	ld	s4,64(sp)
    800024ca:	7ae2                	ld	s5,56(sp)
    800024cc:	7b42                	ld	s6,48(sp)
    800024ce:	7ba2                	ld	s7,40(sp)
    800024d0:	7c02                	ld	s8,32(sp)
    800024d2:	6ce2                	ld	s9,24(sp)
    800024d4:	6d42                	ld	s10,16(sp)
    800024d6:	6da2                	ld	s11,8(sp)
    800024d8:	6165                	addi	sp,sp,112
    800024da:	8082                	ret
    release(&lock_sleeping_list);
    800024dc:	0000f517          	auipc	a0,0xf
    800024e0:	34c50513          	addi	a0,a0,844 # 80011828 <lock_sleeping_list>
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	7b4080e7          	jalr	1972(ra) # 80000c98 <release>
    return;
    800024ec:	bfc9                	j	800024be <wakeup+0x124>

00000000800024ee <reparent>:
{
    800024ee:	7179                	addi	sp,sp,-48
    800024f0:	f406                	sd	ra,40(sp)
    800024f2:	f022                	sd	s0,32(sp)
    800024f4:	ec26                	sd	s1,24(sp)
    800024f6:	e84a                	sd	s2,16(sp)
    800024f8:	e44e                	sd	s3,8(sp)
    800024fa:	e052                	sd	s4,0(sp)
    800024fc:	1800                	addi	s0,sp,48
    800024fe:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002500:	0000f497          	auipc	s1,0xf
    80002504:	35848493          	addi	s1,s1,856 # 80011858 <proc>
      pp->parent = initproc;
    80002508:	00007a17          	auipc	s4,0x7
    8000250c:	b28a0a13          	addi	s4,s4,-1240 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002510:	00015997          	auipc	s3,0x15
    80002514:	54898993          	addi	s3,s3,1352 # 80017a58 <tickslock>
    80002518:	a029                	j	80002522 <reparent+0x34>
    8000251a:	18848493          	addi	s1,s1,392
    8000251e:	01348d63          	beq	s1,s3,80002538 <reparent+0x4a>
    if(pp->parent == p){
    80002522:	6cbc                	ld	a5,88(s1)
    80002524:	ff279be3          	bne	a5,s2,8000251a <reparent+0x2c>
      pp->parent = initproc;
    80002528:	000a3503          	ld	a0,0(s4)
    8000252c:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	e6c080e7          	jalr	-404(ra) # 8000239a <wakeup>
    80002536:	b7d5                	j	8000251a <reparent+0x2c>
}
    80002538:	70a2                	ld	ra,40(sp)
    8000253a:	7402                	ld	s0,32(sp)
    8000253c:	64e2                	ld	s1,24(sp)
    8000253e:	6942                	ld	s2,16(sp)
    80002540:	69a2                	ld	s3,8(sp)
    80002542:	6a02                	ld	s4,0(sp)
    80002544:	6145                	addi	sp,sp,48
    80002546:	8082                	ret

0000000080002548 <exit>:
{
    80002548:	7179                	addi	sp,sp,-48
    8000254a:	f406                	sd	ra,40(sp)
    8000254c:	f022                	sd	s0,32(sp)
    8000254e:	ec26                	sd	s1,24(sp)
    80002550:	e84a                	sd	s2,16(sp)
    80002552:	e44e                	sd	s3,8(sp)
    80002554:	e052                	sd	s4,0(sp)
    80002556:	1800                	addi	s0,sp,48
    80002558:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	3ac080e7          	jalr	940(ra) # 80001906 <myproc>
    80002562:	89aa                	mv	s3,a0
  if(p == initproc)
    80002564:	00007797          	auipc	a5,0x7
    80002568:	acc7b783          	ld	a5,-1332(a5) # 80009030 <initproc>
    8000256c:	0f050493          	addi	s1,a0,240
    80002570:	17050913          	addi	s2,a0,368
    80002574:	02a79363          	bne	a5,a0,8000259a <exit+0x52>
    panic("init exiting");
    80002578:	00006517          	auipc	a0,0x6
    8000257c:	ce850513          	addi	a0,a0,-792 # 80008260 <digits+0x220>
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	fbe080e7          	jalr	-66(ra) # 8000053e <panic>
      fileclose(f);
    80002588:	00002097          	auipc	ra,0x2
    8000258c:	554080e7          	jalr	1364(ra) # 80004adc <fileclose>
      p->ofile[fd] = 0;
    80002590:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002594:	04a1                	addi	s1,s1,8
    80002596:	01248563          	beq	s1,s2,800025a0 <exit+0x58>
    if(p->ofile[fd]){
    8000259a:	6088                	ld	a0,0(s1)
    8000259c:	f575                	bnez	a0,80002588 <exit+0x40>
    8000259e:	bfdd                	j	80002594 <exit+0x4c>
  begin_op();
    800025a0:	00002097          	auipc	ra,0x2
    800025a4:	070080e7          	jalr	112(ra) # 80004610 <begin_op>
  iput(p->cwd);
    800025a8:	1709b503          	ld	a0,368(s3)
    800025ac:	00002097          	auipc	ra,0x2
    800025b0:	84c080e7          	jalr	-1972(ra) # 80003df8 <iput>
  end_op();
    800025b4:	00002097          	auipc	ra,0x2
    800025b8:	0dc080e7          	jalr	220(ra) # 80004690 <end_op>
  p->cwd = 0;
    800025bc:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    800025c0:	0000f497          	auipc	s1,0xf
    800025c4:	23848493          	addi	s1,s1,568 # 800117f8 <wait_lock>
    800025c8:	8526                	mv	a0,s1
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	61a080e7          	jalr	1562(ra) # 80000be4 <acquire>
  reparent(p);
    800025d2:	854e                	mv	a0,s3
    800025d4:	00000097          	auipc	ra,0x0
    800025d8:	f1a080e7          	jalr	-230(ra) # 800024ee <reparent>
  wakeup(p->parent);
    800025dc:	0589b503          	ld	a0,88(s3)
    800025e0:	00000097          	auipc	ra,0x0
    800025e4:	dba080e7          	jalr	-582(ra) # 8000239a <wakeup>
  acquire(&p->lock);
    800025e8:	854e                	mv	a0,s3
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	5fa080e7          	jalr	1530(ra) # 80000be4 <acquire>
  p->xstate = status;
    800025f2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025f6:	4795                	li	a5,5
    800025f8:	00f9ac23          	sw	a5,24(s3)
  add_to_list(&zombie_head, p, &lock_zombie_list);
    800025fc:	0000f617          	auipc	a2,0xf
    80002600:	24460613          	addi	a2,a2,580 # 80011840 <lock_zombie_list>
    80002604:	85ce                	mv	a1,s3
    80002606:	00006517          	auipc	a0,0x6
    8000260a:	24e50513          	addi	a0,a0,590 # 80008854 <zombie_head>
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	78c080e7          	jalr	1932(ra) # 80001d9a <add_to_list>
  release(&wait_lock);
    80002616:	8526                	mv	a0,s1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	680080e7          	jalr	1664(ra) # 80000c98 <release>
  sched();
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	504080e7          	jalr	1284(ra) # 80001b24 <sched>
  panic("zombie exit");
    80002628:	00006517          	auipc	a0,0x6
    8000262c:	c4850513          	addi	a0,a0,-952 # 80008270 <digits+0x230>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	f0e080e7          	jalr	-242(ra) # 8000053e <panic>

0000000080002638 <kill>:
{
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	1800                	addi	s0,sp,48
    80002646:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80002648:	0000f497          	auipc	s1,0xf
    8000264c:	21048493          	addi	s1,s1,528 # 80011858 <proc>
    80002650:	00015997          	auipc	s3,0x15
    80002654:	40898993          	addi	s3,s3,1032 # 80017a58 <tickslock>
    acquire(&p->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	58a080e7          	jalr	1418(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002662:	589c                	lw	a5,48(s1)
    80002664:	01278d63          	beq	a5,s2,8000267e <kill+0x46>
    release(&p->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	62e080e7          	jalr	1582(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002672:	18848493          	addi	s1,s1,392
    80002676:	ff3491e3          	bne	s1,s3,80002658 <kill+0x20>
  return -1;
    8000267a:	557d                	li	a0,-1
    8000267c:	a829                	j	80002696 <kill+0x5e>
      p->killed = 1;
    8000267e:	4785                	li	a5,1
    80002680:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002682:	4c98                	lw	a4,24(s1)
    80002684:	4789                	li	a5,2
    80002686:	00f70f63          	beq	a4,a5,800026a4 <kill+0x6c>
      release(&p->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	60c080e7          	jalr	1548(ra) # 80000c98 <release>
      return 0;
    80002694:	4501                	li	a0,0
}
    80002696:	70a2                	ld	ra,40(sp)
    80002698:	7402                	ld	s0,32(sp)
    8000269a:	64e2                	ld	s1,24(sp)
    8000269c:	6942                	ld	s2,16(sp)
    8000269e:	69a2                	ld	s3,8(sp)
    800026a0:	6145                	addi	sp,sp,48
    800026a2:	8082                	ret
        if(remove_from_list(&sleeping_head, p, &lock_sleeping_list) == 1){
    800026a4:	0000f617          	auipc	a2,0xf
    800026a8:	18460613          	addi	a2,a2,388 # 80011828 <lock_sleeping_list>
    800026ac:	85a6                	mv	a1,s1
    800026ae:	00006517          	auipc	a0,0x6
    800026b2:	1aa50513          	addi	a0,a0,426 # 80008858 <sleeping_head>
    800026b6:	00000097          	auipc	ra,0x0
    800026ba:	9e8080e7          	jalr	-1560(ra) # 8000209e <remove_from_list>
    800026be:	4785                	li	a5,1
    800026c0:	fcf515e3          	bne	a0,a5,8000268a <kill+0x52>
          p->state = RUNNABLE;
    800026c4:	478d                	li	a5,3
    800026c6:	cc9c                	sw	a5,24(s1)
          add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    800026c8:	58dc                	lw	a5,52(s1)
    800026ca:	0a800713          	li	a4,168
    800026ce:	02e787b3          	mul	a5,a5,a4
    800026d2:	0000f517          	auipc	a0,0xf
    800026d6:	bce50513          	addi	a0,a0,-1074 # 800112a0 <cpus>
    800026da:	08878613          	addi	a2,a5,136
    800026de:	08078793          	addi	a5,a5,128
    800026e2:	962a                	add	a2,a2,a0
    800026e4:	85a6                	mv	a1,s1
    800026e6:	953e                	add	a0,a0,a5
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	6b2080e7          	jalr	1714(ra) # 80001d9a <add_to_list>
    800026f0:	bf69                	j	8000268a <kill+0x52>

00000000800026f2 <remove_first>:

int remove_first(int* curr_proc_index, struct spinlock* lock) {
    800026f2:	7139                	addi	sp,sp,-64
    800026f4:	fc06                	sd	ra,56(sp)
    800026f6:	f822                	sd	s0,48(sp)
    800026f8:	f426                	sd	s1,40(sp)
    800026fa:	f04a                	sd	s2,32(sp)
    800026fc:	ec4e                	sd	s3,24(sp)
    800026fe:	e852                	sd	s4,16(sp)
    80002700:	e456                	sd	s5,8(sp)
    80002702:	0080                	addi	s0,sp,64
    80002704:	8aaa                	mv	s5,a0
    80002706:	89ae                	mv	s3,a1
    acquire(lock);
    80002708:	852e                	mv	a0,a1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	4da080e7          	jalr	1242(ra) # 80000be4 <acquire>
    
    if (*curr_proc_index != -1){
    80002712:	000aa483          	lw	s1,0(s5)
    80002716:	57fd                	li	a5,-1
    80002718:	04f48d63          	beq	s1,a5,80002772 <remove_first+0x80>
      int index = *curr_proc_index;
      struct proc *p = &proc[index];
      acquire(&p->proc_lock);
    8000271c:	18800793          	li	a5,392
    80002720:	02f484b3          	mul	s1,s1,a5
    80002724:	04048a13          	addi	s4,s1,64
    80002728:	0000f917          	auipc	s2,0xf
    8000272c:	13090913          	addi	s2,s2,304 # 80011858 <proc>
    80002730:	9a4a                	add	s4,s4,s2
    80002732:	8552                	mv	a0,s4
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	4b0080e7          	jalr	1200(ra) # 80000be4 <acquire>
      
      *curr_proc_index = p->next_proc_index;
    8000273c:	94ca                	add	s1,s1,s2
    8000273e:	5c9c                	lw	a5,56(s1)
    80002740:	00faa023          	sw	a5,0(s5)
      p->next_proc_index = -1;
    80002744:	57fd                	li	a5,-1
    80002746:	dc9c                	sw	a5,56(s1)
      int output_proc = p->proc_index;
    80002748:	5cc4                	lw	s1,60(s1)

      release(&p->proc_lock);
    8000274a:	8552                	mv	a0,s4
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	54c080e7          	jalr	1356(ra) # 80000c98 <release>
      release(lock);
    80002754:	854e                	mv	a0,s3
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	542080e7          	jalr	1346(ra) # 80000c98 <release>
    else{

      release(lock);
      return -1;
    }
    8000275e:	8526                	mv	a0,s1
    80002760:	70e2                	ld	ra,56(sp)
    80002762:	7442                	ld	s0,48(sp)
    80002764:	74a2                	ld	s1,40(sp)
    80002766:	7902                	ld	s2,32(sp)
    80002768:	69e2                	ld	s3,24(sp)
    8000276a:	6a42                	ld	s4,16(sp)
    8000276c:	6aa2                	ld	s5,8(sp)
    8000276e:	6121                	addi	sp,sp,64
    80002770:	8082                	ret
      release(lock);
    80002772:	854e                	mv	a0,s3
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	524080e7          	jalr	1316(ra) # 80000c98 <release>
      return -1;
    8000277c:	b7cd                	j	8000275e <remove_first+0x6c>

000000008000277e <allocproc>:
{
    8000277e:	7179                	addi	sp,sp,-48
    80002780:	f406                	sd	ra,40(sp)
    80002782:	f022                	sd	s0,32(sp)
    80002784:	ec26                	sd	s1,24(sp)
    80002786:	e84a                	sd	s2,16(sp)
    80002788:	e44e                	sd	s3,8(sp)
    8000278a:	e052                	sd	s4,0(sp)
    8000278c:	1800                	addi	s0,sp,48
    int allocation = remove_first(&unused_head, &lock_unused_list);
    8000278e:	0000f597          	auipc	a1,0xf
    80002792:	08258593          	addi	a1,a1,130 # 80011810 <lock_unused_list>
    80002796:	00006517          	auipc	a0,0x6
    8000279a:	0c650513          	addi	a0,a0,198 # 8000885c <unused_head>
    8000279e:	00000097          	auipc	ra,0x0
    800027a2:	f54080e7          	jalr	-172(ra) # 800026f2 <remove_first>
    if(allocation == -1){
    800027a6:	57fd                	li	a5,-1
    800027a8:	0af50863          	beq	a0,a5,80002858 <allocproc+0xda>
    800027ac:	892a                	mv	s2,a0
  p=&proc[allocation];
    800027ae:	18800993          	li	s3,392
    800027b2:	033509b3          	mul	s3,a0,s3
    800027b6:	0000f497          	auipc	s1,0xf
    800027ba:	0a248493          	addi	s1,s1,162 # 80011858 <proc>
    800027be:	94ce                	add	s1,s1,s3
  acquire(&p->lock);
    800027c0:	8526                	mv	a0,s1
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	422080e7          	jalr	1058(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	1c0080e7          	jalr	448(ra) # 8000198a <allocpid>
    800027d2:	d888                	sw	a0,48(s1)
  p->state = USED;
    800027d4:	4785                	li	a5,1
    800027d6:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	31c080e7          	jalr	796(ra) # 80000af4 <kalloc>
    800027e0:	8a2a                	mv	s4,a0
    800027e2:	fca8                	sd	a0,120(s1)
    800027e4:	c541                	beqz	a0,8000286c <allocproc+0xee>
  p->pagetable = proc_pagetable(p);
    800027e6:	8526                	mv	a0,s1
    800027e8:	fffff097          	auipc	ra,0xfffff
    800027ec:	1da080e7          	jalr	474(ra) # 800019c2 <proc_pagetable>
    800027f0:	8a2a                	mv	s4,a0
    800027f2:	18800793          	li	a5,392
    800027f6:	02f90733          	mul	a4,s2,a5
    800027fa:	0000f797          	auipc	a5,0xf
    800027fe:	05e78793          	addi	a5,a5,94 # 80011858 <proc>
    80002802:	97ba                	add	a5,a5,a4
    80002804:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    80002806:	cd3d                	beqz	a0,80002884 <allocproc+0x106>
  memset(&p->context, 0, sizeof(p->context));
    80002808:	08098513          	addi	a0,s3,128
    8000280c:	0000fa17          	auipc	s4,0xf
    80002810:	04ca0a13          	addi	s4,s4,76 # 80011858 <proc>
    80002814:	07000613          	li	a2,112
    80002818:	4581                	li	a1,0
    8000281a:	9552                	add	a0,a0,s4
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	4c4080e7          	jalr	1220(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002824:	18800513          	li	a0,392
    80002828:	02a90933          	mul	s2,s2,a0
    8000282c:	9952                	add	s2,s2,s4
    8000282e:	fffff797          	auipc	a5,0xfffff
    80002832:	11678793          	addi	a5,a5,278 # 80001944 <forkret>
    80002836:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    8000283a:	06093783          	ld	a5,96(s2)
    8000283e:	6705                	lui	a4,0x1
    80002840:	97ba                	add	a5,a5,a4
    80002842:	08f93423          	sd	a5,136(s2)
}
    80002846:	8526                	mv	a0,s1
    80002848:	70a2                	ld	ra,40(sp)
    8000284a:	7402                	ld	s0,32(sp)
    8000284c:	64e2                	ld	s1,24(sp)
    8000284e:	6942                	ld	s2,16(sp)
    80002850:	69a2                	ld	s3,8(sp)
    80002852:	6a02                	ld	s4,0(sp)
    80002854:	6145                	addi	sp,sp,48
    80002856:	8082                	ret
      printf("No availble spot in table to allocate\n");
    80002858:	00006517          	auipc	a0,0x6
    8000285c:	a2850513          	addi	a0,a0,-1496 # 80008280 <digits+0x240>
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	d28080e7          	jalr	-728(ra) # 80000588 <printf>
      return 0;
    80002868:	4481                	li	s1,0
    8000286a:	bff1                	j	80002846 <allocproc+0xc8>
    freeproc(p);
    8000286c:	8526                	mv	a0,s1
    8000286e:	00000097          	auipc	ra,0x0
    80002872:	970080e7          	jalr	-1680(ra) # 800021de <freeproc>
    release(&p->lock);
    80002876:	8526                	mv	a0,s1
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	420080e7          	jalr	1056(ra) # 80000c98 <release>
    return 0;
    80002880:	84d2                	mv	s1,s4
    80002882:	b7d1                	j	80002846 <allocproc+0xc8>
    freeproc(p);
    80002884:	8526                	mv	a0,s1
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	958080e7          	jalr	-1704(ra) # 800021de <freeproc>
    release(&p->lock);
    8000288e:	8526                	mv	a0,s1
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	408080e7          	jalr	1032(ra) # 80000c98 <release>
    return 0;
    80002898:	84d2                	mv	s1,s4
    8000289a:	b775                	j	80002846 <allocproc+0xc8>

000000008000289c <userinit>:
{
    8000289c:	1101                	addi	sp,sp,-32
    8000289e:	ec06                	sd	ra,24(sp)
    800028a0:	e822                	sd	s0,16(sp)
    800028a2:	e426                	sd	s1,8(sp)
    800028a4:	1000                	addi	s0,sp,32
  p = allocproc();
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	ed8080e7          	jalr	-296(ra) # 8000277e <allocproc>
    800028ae:	84aa                	mv	s1,a0
  initproc = p;
    800028b0:	00006797          	auipc	a5,0x6
    800028b4:	78a7b023          	sd	a0,1920(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800028b8:	03400613          	li	a2,52
    800028bc:	00006597          	auipc	a1,0x6
    800028c0:	fb458593          	addi	a1,a1,-76 # 80008870 <initcode>
    800028c4:	7928                	ld	a0,112(a0)
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	aa2080e7          	jalr	-1374(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800028ce:	6785                	lui	a5,0x1
    800028d0:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    800028d2:	7cb8                	ld	a4,120(s1)
    800028d4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800028d8:	7cb8                	ld	a4,120(s1)
    800028da:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800028dc:	4641                	li	a2,16
    800028de:	00006597          	auipc	a1,0x6
    800028e2:	9ca58593          	addi	a1,a1,-1590 # 800082a8 <digits+0x268>
    800028e6:	17848513          	addi	a0,s1,376
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	548080e7          	jalr	1352(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800028f2:	00006517          	auipc	a0,0x6
    800028f6:	9c650513          	addi	a0,a0,-1594 # 800082b8 <digits+0x278>
    800028fa:	00002097          	auipc	ra,0x2
    800028fe:	afa080e7          	jalr	-1286(ra) # 800043f4 <namei>
    80002902:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80002906:	478d                	li	a5,3
    80002908:	cc9c                	sw	a5,24(s1)
  add_to_list(&cpus[0].runnable_head, p, &cpus[0].lock_runnable_list);
    8000290a:	0000f617          	auipc	a2,0xf
    8000290e:	a1e60613          	addi	a2,a2,-1506 # 80011328 <cpus+0x88>
    80002912:	85a6                	mv	a1,s1
    80002914:	0000f517          	auipc	a0,0xf
    80002918:	a0c50513          	addi	a0,a0,-1524 # 80011320 <cpus+0x80>
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	47e080e7          	jalr	1150(ra) # 80001d9a <add_to_list>
  release(&p->lock);
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	372080e7          	jalr	882(ra) # 80000c98 <release>
}
    8000292e:	60e2                	ld	ra,24(sp)
    80002930:	6442                	ld	s0,16(sp)
    80002932:	64a2                	ld	s1,8(sp)
    80002934:	6105                	addi	sp,sp,32
    80002936:	8082                	ret

0000000080002938 <fork>:
{
    80002938:	7179                	addi	sp,sp,-48
    8000293a:	f406                	sd	ra,40(sp)
    8000293c:	f022                	sd	s0,32(sp)
    8000293e:	ec26                	sd	s1,24(sp)
    80002940:	e84a                	sd	s2,16(sp)
    80002942:	e44e                	sd	s3,8(sp)
    80002944:	e052                	sd	s4,0(sp)
    80002946:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	fbe080e7          	jalr	-66(ra) # 80001906 <myproc>
    80002950:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002952:	00000097          	auipc	ra,0x0
    80002956:	e2c080e7          	jalr	-468(ra) # 8000277e <allocproc>
    8000295a:	18050063          	beqz	a0,80002ada <fork+0x1a2>
    8000295e:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002960:	0689b603          	ld	a2,104(s3)
    80002964:	792c                	ld	a1,112(a0)
    80002966:	0709b503          	ld	a0,112(s3)
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	c04080e7          	jalr	-1020(ra) # 8000156e <uvmcopy>
    80002972:	04054663          	bltz	a0,800029be <fork+0x86>
  np->sz = p->sz;
    80002976:	0689b783          	ld	a5,104(s3)
    8000297a:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    8000297e:	0789b683          	ld	a3,120(s3)
    80002982:	87b6                	mv	a5,a3
    80002984:	07893703          	ld	a4,120(s2)
    80002988:	12068693          	addi	a3,a3,288
    8000298c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002990:	6788                	ld	a0,8(a5)
    80002992:	6b8c                	ld	a1,16(a5)
    80002994:	6f90                	ld	a2,24(a5)
    80002996:	01073023          	sd	a6,0(a4)
    8000299a:	e708                	sd	a0,8(a4)
    8000299c:	eb0c                	sd	a1,16(a4)
    8000299e:	ef10                	sd	a2,24(a4)
    800029a0:	02078793          	addi	a5,a5,32
    800029a4:	02070713          	addi	a4,a4,32
    800029a8:	fed792e3          	bne	a5,a3,8000298c <fork+0x54>
  np->trapframe->a0 = 0;
    800029ac:	07893783          	ld	a5,120(s2)
    800029b0:	0607b823          	sd	zero,112(a5)
    800029b4:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    800029b8:	17000a13          	li	s4,368
    800029bc:	a03d                	j	800029ea <fork+0xb2>
    freeproc(np);
    800029be:	854a                	mv	a0,s2
    800029c0:	00000097          	auipc	ra,0x0
    800029c4:	81e080e7          	jalr	-2018(ra) # 800021de <freeproc>
    release(&np->lock);
    800029c8:	854a                	mv	a0,s2
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	2ce080e7          	jalr	718(ra) # 80000c98 <release>
    return -1;
    800029d2:	5a7d                	li	s4,-1
    800029d4:	a0ed                	j	80002abe <fork+0x186>
      np->ofile[i] = filedup(p->ofile[i]);
    800029d6:	00002097          	auipc	ra,0x2
    800029da:	0b4080e7          	jalr	180(ra) # 80004a8a <filedup>
    800029de:	009907b3          	add	a5,s2,s1
    800029e2:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800029e4:	04a1                	addi	s1,s1,8
    800029e6:	01448763          	beq	s1,s4,800029f4 <fork+0xbc>
    if(p->ofile[i])
    800029ea:	009987b3          	add	a5,s3,s1
    800029ee:	6388                	ld	a0,0(a5)
    800029f0:	f17d                	bnez	a0,800029d6 <fork+0x9e>
    800029f2:	bfcd                	j	800029e4 <fork+0xac>
  np->cwd = idup(p->cwd);
    800029f4:	1709b503          	ld	a0,368(s3)
    800029f8:	00001097          	auipc	ra,0x1
    800029fc:	208080e7          	jalr	520(ra) # 80003c00 <idup>
    80002a00:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002a04:	4641                	li	a2,16
    80002a06:	17898593          	addi	a1,s3,376
    80002a0a:	17890513          	addi	a0,s2,376
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	424080e7          	jalr	1060(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002a16:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    80002a1a:	854a                	mv	a0,s2
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	27c080e7          	jalr	636(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002a24:	0000f517          	auipc	a0,0xf
    80002a28:	dd450513          	addi	a0,a0,-556 # 800117f8 <wait_lock>
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	1b8080e7          	jalr	440(ra) # 80000be4 <acquire>
  np->parent = p;
    80002a34:	05393c23          	sd	s3,88(s2)
  if(auto_balanced){
    80002a38:	00006797          	auipc	a5,0x6
    80002a3c:	5f07a783          	lw	a5,1520(a5) # 80009028 <auto_balanced>
    80002a40:	cbc1                	beqz	a5,80002ad0 <fork+0x198>
    np->cpu_num = cpu_num;
    80002a42:	02092a23          	sw	zero,52(s2)
    while(cas(&c->counter, c->counter, c->counter + 1) != 0);
    80002a46:	0000f997          	auipc	s3,0xf
    80002a4a:	85a98993          	addi	s3,s3,-1958 # 800112a0 <cpus>
    80002a4e:	0000f497          	auipc	s1,0xf
    80002a52:	8f248493          	addi	s1,s1,-1806 # 80011340 <cpus+0xa0>
    80002a56:	0a09a583          	lw	a1,160(s3)
    80002a5a:	0015861b          	addiw	a2,a1,1
    80002a5e:	8526                	mv	a0,s1
    80002a60:	00004097          	auipc	ra,0x4
    80002a64:	d66080e7          	jalr	-666(ra) # 800067c6 <cas>
    80002a68:	f57d                	bnez	a0,80002a56 <fork+0x11e>
  release(&wait_lock);
    80002a6a:	0000f497          	auipc	s1,0xf
    80002a6e:	83648493          	addi	s1,s1,-1994 # 800112a0 <cpus>
    80002a72:	0000f517          	auipc	a0,0xf
    80002a76:	d8650513          	addi	a0,a0,-634 # 800117f8 <wait_lock>
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	21e080e7          	jalr	542(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002a82:	854a                	mv	a0,s2
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	160080e7          	jalr	352(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002a8c:	478d                	li	a5,3
    80002a8e:	00f92c23          	sw	a5,24(s2)
  add_to_list(&c->runnable_head, np, &c->lock_runnable_list);
    80002a92:	03492503          	lw	a0,52(s2)
    80002a96:	0a800793          	li	a5,168
    80002a9a:	02f50533          	mul	a0,a0,a5
    80002a9e:	08850613          	addi	a2,a0,136
    80002aa2:	08050513          	addi	a0,a0,128
    80002aa6:	9626                	add	a2,a2,s1
    80002aa8:	85ca                	mv	a1,s2
    80002aaa:	9526                	add	a0,a0,s1
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	2ee080e7          	jalr	750(ra) # 80001d9a <add_to_list>
  release(&np->lock);
    80002ab4:	854a                	mv	a0,s2
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	1e2080e7          	jalr	482(ra) # 80000c98 <release>
}
    80002abe:	8552                	mv	a0,s4
    80002ac0:	70a2                	ld	ra,40(sp)
    80002ac2:	7402                	ld	s0,32(sp)
    80002ac4:	64e2                	ld	s1,24(sp)
    80002ac6:	6942                	ld	s2,16(sp)
    80002ac8:	69a2                	ld	s3,8(sp)
    80002aca:	6a02                	ld	s4,0(sp)
    80002acc:	6145                	addi	sp,sp,48
    80002ace:	8082                	ret
    np->cpu_num = p->cpu_num;
    80002ad0:	0349a783          	lw	a5,52(s3)
    80002ad4:	02f92a23          	sw	a5,52(s2)
    80002ad8:	bf49                	j	80002a6a <fork+0x132>
    return -1;
    80002ada:	5a7d                	li	s4,-1
    80002adc:	b7cd                	j	80002abe <fork+0x186>

0000000080002ade <scheduler>:
{
    80002ade:	711d                	addi	sp,sp,-96
    80002ae0:	ec86                	sd	ra,88(sp)
    80002ae2:	e8a2                	sd	s0,80(sp)
    80002ae4:	e4a6                	sd	s1,72(sp)
    80002ae6:	e0ca                	sd	s2,64(sp)
    80002ae8:	fc4e                	sd	s3,56(sp)
    80002aea:	f852                	sd	s4,48(sp)
    80002aec:	f456                	sd	s5,40(sp)
    80002aee:	f05a                	sd	s6,32(sp)
    80002af0:	ec5e                	sd	s7,24(sp)
    80002af2:	e862                	sd	s8,16(sp)
    80002af4:	e466                	sd	s9,8(sp)
    80002af6:	e06a                	sd	s10,0(sp)
    80002af8:	1080                	addi	s0,sp,96
    80002afa:	8712                	mv	a4,tp
  int id = r_tp();
    80002afc:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002afe:	0000eb97          	auipc	s7,0xe
    80002b02:	7a2b8b93          	addi	s7,s7,1954 # 800112a0 <cpus>
    80002b06:	0a800793          	li	a5,168
    80002b0a:	02f707b3          	mul	a5,a4,a5
    80002b0e:	00fb86b3          	add	a3,s7,a5
    80002b12:	0006b023          	sd	zero,0(a3)
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002b16:	08078993          	addi	s3,a5,128
    80002b1a:	99de                	add	s3,s3,s7
    80002b1c:	08878913          	addi	s2,a5,136
    80002b20:	995e                	add	s2,s2,s7
      swtch(&c->context, &p->context);
    80002b22:	07a1                	addi	a5,a5,8
    80002b24:	9bbe                	add	s7,s7,a5
    if(proc_num != -1){
    80002b26:	5a7d                	li	s4,-1
    80002b28:	18800c93          	li	s9,392
      p = &proc[proc_num];
    80002b2c:	0000fb17          	auipc	s6,0xf
    80002b30:	d2cb0b13          	addi	s6,s6,-724 # 80011858 <proc>
      p->state = RUNNING;
    80002b34:	4c11                	li	s8,4
      c->proc = p;
    80002b36:	8ab6                	mv	s5,a3
    80002b38:	a82d                	j	80002b72 <scheduler+0x94>
      p = &proc[proc_num];
    80002b3a:	039504b3          	mul	s1,a0,s9
    80002b3e:	01648d33          	add	s10,s1,s6
      acquire(&p->lock);
    80002b42:	856a                	mv	a0,s10
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	0a0080e7          	jalr	160(ra) # 80000be4 <acquire>
      p->state = RUNNING;
    80002b4c:	018d2c23          	sw	s8,24(s10)
      c->proc = p;
    80002b50:	01aab023          	sd	s10,0(s5)
      swtch(&c->context, &p->context);
    80002b54:	08048593          	addi	a1,s1,128
    80002b58:	95da                	add	a1,a1,s6
    80002b5a:	855e                	mv	a0,s7
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	034080e7          	jalr	52(ra) # 80002b90 <swtch>
      c->proc = 0;
    80002b64:	000ab023          	sd	zero,0(s5)
      release(&p->lock);
    80002b68:	856a                	mv	a0,s10
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	12e080e7          	jalr	302(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b72:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b76:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7a:	10079073          	csrw	sstatus,a5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002b7e:	85ca                	mv	a1,s2
    80002b80:	854e                	mv	a0,s3
    80002b82:	00000097          	auipc	ra,0x0
    80002b86:	b70080e7          	jalr	-1168(ra) # 800026f2 <remove_first>
    if(proc_num != -1){
    80002b8a:	ff4504e3          	beq	a0,s4,80002b72 <scheduler+0x94>
    80002b8e:	b775                	j	80002b3a <scheduler+0x5c>

0000000080002b90 <swtch>:
    80002b90:	00153023          	sd	ra,0(a0)
    80002b94:	00253423          	sd	sp,8(a0)
    80002b98:	e900                	sd	s0,16(a0)
    80002b9a:	ed04                	sd	s1,24(a0)
    80002b9c:	03253023          	sd	s2,32(a0)
    80002ba0:	03353423          	sd	s3,40(a0)
    80002ba4:	03453823          	sd	s4,48(a0)
    80002ba8:	03553c23          	sd	s5,56(a0)
    80002bac:	05653023          	sd	s6,64(a0)
    80002bb0:	05753423          	sd	s7,72(a0)
    80002bb4:	05853823          	sd	s8,80(a0)
    80002bb8:	05953c23          	sd	s9,88(a0)
    80002bbc:	07a53023          	sd	s10,96(a0)
    80002bc0:	07b53423          	sd	s11,104(a0)
    80002bc4:	0005b083          	ld	ra,0(a1)
    80002bc8:	0085b103          	ld	sp,8(a1)
    80002bcc:	6980                	ld	s0,16(a1)
    80002bce:	6d84                	ld	s1,24(a1)
    80002bd0:	0205b903          	ld	s2,32(a1)
    80002bd4:	0285b983          	ld	s3,40(a1)
    80002bd8:	0305ba03          	ld	s4,48(a1)
    80002bdc:	0385ba83          	ld	s5,56(a1)
    80002be0:	0405bb03          	ld	s6,64(a1)
    80002be4:	0485bb83          	ld	s7,72(a1)
    80002be8:	0505bc03          	ld	s8,80(a1)
    80002bec:	0585bc83          	ld	s9,88(a1)
    80002bf0:	0605bd03          	ld	s10,96(a1)
    80002bf4:	0685bd83          	ld	s11,104(a1)
    80002bf8:	8082                	ret

0000000080002bfa <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bfa:	1141                	addi	sp,sp,-16
    80002bfc:	e406                	sd	ra,8(sp)
    80002bfe:	e022                	sd	s0,0(sp)
    80002c00:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c02:	00005597          	auipc	a1,0x5
    80002c06:	71658593          	addi	a1,a1,1814 # 80008318 <states.1768+0x30>
    80002c0a:	00015517          	auipc	a0,0x15
    80002c0e:	e4e50513          	addi	a0,a0,-434 # 80017a58 <tickslock>
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	f42080e7          	jalr	-190(ra) # 80000b54 <initlock>
}
    80002c1a:	60a2                	ld	ra,8(sp)
    80002c1c:	6402                	ld	s0,0(sp)
    80002c1e:	0141                	addi	sp,sp,16
    80002c20:	8082                	ret

0000000080002c22 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c22:	1141                	addi	sp,sp,-16
    80002c24:	e422                	sd	s0,8(sp)
    80002c26:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c28:	00003797          	auipc	a5,0x3
    80002c2c:	4c878793          	addi	a5,a5,1224 # 800060f0 <kernelvec>
    80002c30:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c34:	6422                	ld	s0,8(sp)
    80002c36:	0141                	addi	sp,sp,16
    80002c38:	8082                	ret

0000000080002c3a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c3a:	1141                	addi	sp,sp,-16
    80002c3c:	e406                	sd	ra,8(sp)
    80002c3e:	e022                	sd	s0,0(sp)
    80002c40:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	cc4080e7          	jalr	-828(ra) # 80001906 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c4e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c50:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c54:	00004617          	auipc	a2,0x4
    80002c58:	3ac60613          	addi	a2,a2,940 # 80007000 <_trampoline>
    80002c5c:	00004697          	auipc	a3,0x4
    80002c60:	3a468693          	addi	a3,a3,932 # 80007000 <_trampoline>
    80002c64:	8e91                	sub	a3,a3,a2
    80002c66:	040007b7          	lui	a5,0x4000
    80002c6a:	17fd                	addi	a5,a5,-1
    80002c6c:	07b2                	slli	a5,a5,0xc
    80002c6e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c70:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c74:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c76:	180026f3          	csrr	a3,satp
    80002c7a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c7c:	7d38                	ld	a4,120(a0)
    80002c7e:	7134                	ld	a3,96(a0)
    80002c80:	6585                	lui	a1,0x1
    80002c82:	96ae                	add	a3,a3,a1
    80002c84:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c86:	7d38                	ld	a4,120(a0)
    80002c88:	00000697          	auipc	a3,0x0
    80002c8c:	13868693          	addi	a3,a3,312 # 80002dc0 <usertrap>
    80002c90:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c92:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c94:	8692                	mv	a3,tp
    80002c96:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c98:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c9c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ca0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ca4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ca8:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002caa:	6f18                	ld	a4,24(a4)
    80002cac:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cb0:	792c                	ld	a1,112(a0)
    80002cb2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002cb4:	00004717          	auipc	a4,0x4
    80002cb8:	3dc70713          	addi	a4,a4,988 # 80007090 <userret>
    80002cbc:	8f11                	sub	a4,a4,a2
    80002cbe:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002cc0:	577d                	li	a4,-1
    80002cc2:	177e                	slli	a4,a4,0x3f
    80002cc4:	8dd9                	or	a1,a1,a4
    80002cc6:	02000537          	lui	a0,0x2000
    80002cca:	157d                	addi	a0,a0,-1
    80002ccc:	0536                	slli	a0,a0,0xd
    80002cce:	9782                	jalr	a5
}
    80002cd0:	60a2                	ld	ra,8(sp)
    80002cd2:	6402                	ld	s0,0(sp)
    80002cd4:	0141                	addi	sp,sp,16
    80002cd6:	8082                	ret

0000000080002cd8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002cd8:	1101                	addi	sp,sp,-32
    80002cda:	ec06                	sd	ra,24(sp)
    80002cdc:	e822                	sd	s0,16(sp)
    80002cde:	e426                	sd	s1,8(sp)
    80002ce0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ce2:	00015497          	auipc	s1,0x15
    80002ce6:	d7648493          	addi	s1,s1,-650 # 80017a58 <tickslock>
    80002cea:	8526                	mv	a0,s1
    80002cec:	ffffe097          	auipc	ra,0xffffe
    80002cf0:	ef8080e7          	jalr	-264(ra) # 80000be4 <acquire>
  ticks++;
    80002cf4:	00006517          	auipc	a0,0x6
    80002cf8:	34450513          	addi	a0,a0,836 # 80009038 <ticks>
    80002cfc:	411c                	lw	a5,0(a0)
    80002cfe:	2785                	addiw	a5,a5,1
    80002d00:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	698080e7          	jalr	1688(ra) # 8000239a <wakeup>
  release(&tickslock);
    80002d0a:	8526                	mv	a0,s1
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	f8c080e7          	jalr	-116(ra) # 80000c98 <release>
}
    80002d14:	60e2                	ld	ra,24(sp)
    80002d16:	6442                	ld	s0,16(sp)
    80002d18:	64a2                	ld	s1,8(sp)
    80002d1a:	6105                	addi	sp,sp,32
    80002d1c:	8082                	ret

0000000080002d1e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d1e:	1101                	addi	sp,sp,-32
    80002d20:	ec06                	sd	ra,24(sp)
    80002d22:	e822                	sd	s0,16(sp)
    80002d24:	e426                	sd	s1,8(sp)
    80002d26:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d28:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d2c:	00074d63          	bltz	a4,80002d46 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d30:	57fd                	li	a5,-1
    80002d32:	17fe                	slli	a5,a5,0x3f
    80002d34:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d36:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d38:	06f70363          	beq	a4,a5,80002d9e <devintr+0x80>
  }
}
    80002d3c:	60e2                	ld	ra,24(sp)
    80002d3e:	6442                	ld	s0,16(sp)
    80002d40:	64a2                	ld	s1,8(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret
     (scause & 0xff) == 9){
    80002d46:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d4a:	46a5                	li	a3,9
    80002d4c:	fed792e3          	bne	a5,a3,80002d30 <devintr+0x12>
    int irq = plic_claim();
    80002d50:	00003097          	auipc	ra,0x3
    80002d54:	4a8080e7          	jalr	1192(ra) # 800061f8 <plic_claim>
    80002d58:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d5a:	47a9                	li	a5,10
    80002d5c:	02f50763          	beq	a0,a5,80002d8a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d60:	4785                	li	a5,1
    80002d62:	02f50963          	beq	a0,a5,80002d94 <devintr+0x76>
    return 1;
    80002d66:	4505                	li	a0,1
    } else if(irq){
    80002d68:	d8f1                	beqz	s1,80002d3c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d6a:	85a6                	mv	a1,s1
    80002d6c:	00005517          	auipc	a0,0x5
    80002d70:	5b450513          	addi	a0,a0,1460 # 80008320 <states.1768+0x38>
    80002d74:	ffffe097          	auipc	ra,0xffffe
    80002d78:	814080e7          	jalr	-2028(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d7c:	8526                	mv	a0,s1
    80002d7e:	00003097          	auipc	ra,0x3
    80002d82:	49e080e7          	jalr	1182(ra) # 8000621c <plic_complete>
    return 1;
    80002d86:	4505                	li	a0,1
    80002d88:	bf55                	j	80002d3c <devintr+0x1e>
      uartintr();
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	c1e080e7          	jalr	-994(ra) # 800009a8 <uartintr>
    80002d92:	b7ed                	j	80002d7c <devintr+0x5e>
      virtio_disk_intr();
    80002d94:	00004097          	auipc	ra,0x4
    80002d98:	968080e7          	jalr	-1688(ra) # 800066fc <virtio_disk_intr>
    80002d9c:	b7c5                	j	80002d7c <devintr+0x5e>
    if(cpuid() == 0){
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	b36080e7          	jalr	-1226(ra) # 800018d4 <cpuid>
    80002da6:	c901                	beqz	a0,80002db6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002da8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dac:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dae:	14479073          	csrw	sip,a5
    return 2;
    80002db2:	4509                	li	a0,2
    80002db4:	b761                	j	80002d3c <devintr+0x1e>
      clockintr();
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	f22080e7          	jalr	-222(ra) # 80002cd8 <clockintr>
    80002dbe:	b7ed                	j	80002da8 <devintr+0x8a>

0000000080002dc0 <usertrap>:
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	e426                	sd	s1,8(sp)
    80002dc8:	e04a                	sd	s2,0(sp)
    80002dca:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dcc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002dd0:	1007f793          	andi	a5,a5,256
    80002dd4:	e3ad                	bnez	a5,80002e36 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dd6:	00003797          	auipc	a5,0x3
    80002dda:	31a78793          	addi	a5,a5,794 # 800060f0 <kernelvec>
    80002dde:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	b24080e7          	jalr	-1244(ra) # 80001906 <myproc>
    80002dea:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002dec:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dee:	14102773          	csrr	a4,sepc
    80002df2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002df4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002df8:	47a1                	li	a5,8
    80002dfa:	04f71c63          	bne	a4,a5,80002e52 <usertrap+0x92>
    if(p->killed)
    80002dfe:	551c                	lw	a5,40(a0)
    80002e00:	e3b9                	bnez	a5,80002e46 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e02:	7cb8                	ld	a4,120(s1)
    80002e04:	6f1c                	ld	a5,24(a4)
    80002e06:	0791                	addi	a5,a5,4
    80002e08:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e0e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e12:	10079073          	csrw	sstatus,a5
    syscall();
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	2e0080e7          	jalr	736(ra) # 800030f6 <syscall>
  if(p->killed)
    80002e1e:	549c                	lw	a5,40(s1)
    80002e20:	ebc1                	bnez	a5,80002eb0 <usertrap+0xf0>
  usertrapret();
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	e18080e7          	jalr	-488(ra) # 80002c3a <usertrapret>
}
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6902                	ld	s2,0(sp)
    80002e32:	6105                	addi	sp,sp,32
    80002e34:	8082                	ret
    panic("usertrap: not from user mode");
    80002e36:	00005517          	auipc	a0,0x5
    80002e3a:	50a50513          	addi	a0,a0,1290 # 80008340 <states.1768+0x58>
    80002e3e:	ffffd097          	auipc	ra,0xffffd
    80002e42:	700080e7          	jalr	1792(ra) # 8000053e <panic>
      exit(-1);
    80002e46:	557d                	li	a0,-1
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	700080e7          	jalr	1792(ra) # 80002548 <exit>
    80002e50:	bf4d                	j	80002e02 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	ecc080e7          	jalr	-308(ra) # 80002d1e <devintr>
    80002e5a:	892a                	mv	s2,a0
    80002e5c:	c501                	beqz	a0,80002e64 <usertrap+0xa4>
  if(p->killed)
    80002e5e:	549c                	lw	a5,40(s1)
    80002e60:	c3a1                	beqz	a5,80002ea0 <usertrap+0xe0>
    80002e62:	a815                	j	80002e96 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e64:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e68:	5890                	lw	a2,48(s1)
    80002e6a:	00005517          	auipc	a0,0x5
    80002e6e:	4f650513          	addi	a0,a0,1270 # 80008360 <states.1768+0x78>
    80002e72:	ffffd097          	auipc	ra,0xffffd
    80002e76:	716080e7          	jalr	1814(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e7a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e7e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e82:	00005517          	auipc	a0,0x5
    80002e86:	50e50513          	addi	a0,a0,1294 # 80008390 <states.1768+0xa8>
    80002e8a:	ffffd097          	auipc	ra,0xffffd
    80002e8e:	6fe080e7          	jalr	1790(ra) # 80000588 <printf>
    p->killed = 1;
    80002e92:	4785                	li	a5,1
    80002e94:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e96:	557d                	li	a0,-1
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	6b0080e7          	jalr	1712(ra) # 80002548 <exit>
  if(which_dev == 2)
    80002ea0:	4789                	li	a5,2
    80002ea2:	f8f910e3          	bne	s2,a5,80002e22 <usertrap+0x62>
    yield();
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	0d8080e7          	jalr	216(ra) # 80001f7e <yield>
    80002eae:	bf95                	j	80002e22 <usertrap+0x62>
  int which_dev = 0;
    80002eb0:	4901                	li	s2,0
    80002eb2:	b7d5                	j	80002e96 <usertrap+0xd6>

0000000080002eb4 <kerneltrap>:
{
    80002eb4:	7179                	addi	sp,sp,-48
    80002eb6:	f406                	sd	ra,40(sp)
    80002eb8:	f022                	sd	s0,32(sp)
    80002eba:	ec26                	sd	s1,24(sp)
    80002ebc:	e84a                	sd	s2,16(sp)
    80002ebe:	e44e                	sd	s3,8(sp)
    80002ec0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ec6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eca:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ece:	1004f793          	andi	a5,s1,256
    80002ed2:	cb85                	beqz	a5,80002f02 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ed4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ed8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002eda:	ef85                	bnez	a5,80002f12 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002edc:	00000097          	auipc	ra,0x0
    80002ee0:	e42080e7          	jalr	-446(ra) # 80002d1e <devintr>
    80002ee4:	cd1d                	beqz	a0,80002f22 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ee6:	4789                	li	a5,2
    80002ee8:	06f50a63          	beq	a0,a5,80002f5c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002eec:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ef0:	10049073          	csrw	sstatus,s1
}
    80002ef4:	70a2                	ld	ra,40(sp)
    80002ef6:	7402                	ld	s0,32(sp)
    80002ef8:	64e2                	ld	s1,24(sp)
    80002efa:	6942                	ld	s2,16(sp)
    80002efc:	69a2                	ld	s3,8(sp)
    80002efe:	6145                	addi	sp,sp,48
    80002f00:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f02:	00005517          	auipc	a0,0x5
    80002f06:	4ae50513          	addi	a0,a0,1198 # 800083b0 <states.1768+0xc8>
    80002f0a:	ffffd097          	auipc	ra,0xffffd
    80002f0e:	634080e7          	jalr	1588(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f12:	00005517          	auipc	a0,0x5
    80002f16:	4c650513          	addi	a0,a0,1222 # 800083d8 <states.1768+0xf0>
    80002f1a:	ffffd097          	auipc	ra,0xffffd
    80002f1e:	624080e7          	jalr	1572(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f22:	85ce                	mv	a1,s3
    80002f24:	00005517          	auipc	a0,0x5
    80002f28:	4d450513          	addi	a0,a0,1236 # 800083f8 <states.1768+0x110>
    80002f2c:	ffffd097          	auipc	ra,0xffffd
    80002f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f34:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f38:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f3c:	00005517          	auipc	a0,0x5
    80002f40:	4cc50513          	addi	a0,a0,1228 # 80008408 <states.1768+0x120>
    80002f44:	ffffd097          	auipc	ra,0xffffd
    80002f48:	644080e7          	jalr	1604(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f4c:	00005517          	auipc	a0,0x5
    80002f50:	4d450513          	addi	a0,a0,1236 # 80008420 <states.1768+0x138>
    80002f54:	ffffd097          	auipc	ra,0xffffd
    80002f58:	5ea080e7          	jalr	1514(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	9aa080e7          	jalr	-1622(ra) # 80001906 <myproc>
    80002f64:	d541                	beqz	a0,80002eec <kerneltrap+0x38>
    80002f66:	fffff097          	auipc	ra,0xfffff
    80002f6a:	9a0080e7          	jalr	-1632(ra) # 80001906 <myproc>
    80002f6e:	4d18                	lw	a4,24(a0)
    80002f70:	4791                	li	a5,4
    80002f72:	f6f71de3          	bne	a4,a5,80002eec <kerneltrap+0x38>
    yield();
    80002f76:	fffff097          	auipc	ra,0xfffff
    80002f7a:	008080e7          	jalr	8(ra) # 80001f7e <yield>
    80002f7e:	b7bd                	j	80002eec <kerneltrap+0x38>

0000000080002f80 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f80:	1101                	addi	sp,sp,-32
    80002f82:	ec06                	sd	ra,24(sp)
    80002f84:	e822                	sd	s0,16(sp)
    80002f86:	e426                	sd	s1,8(sp)
    80002f88:	1000                	addi	s0,sp,32
    80002f8a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	97a080e7          	jalr	-1670(ra) # 80001906 <myproc>
  switch (n) {
    80002f94:	4795                	li	a5,5
    80002f96:	0497e163          	bltu	a5,s1,80002fd8 <argraw+0x58>
    80002f9a:	048a                	slli	s1,s1,0x2
    80002f9c:	00005717          	auipc	a4,0x5
    80002fa0:	4bc70713          	addi	a4,a4,1212 # 80008458 <states.1768+0x170>
    80002fa4:	94ba                	add	s1,s1,a4
    80002fa6:	409c                	lw	a5,0(s1)
    80002fa8:	97ba                	add	a5,a5,a4
    80002faa:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fac:	7d3c                	ld	a5,120(a0)
    80002fae:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fb0:	60e2                	ld	ra,24(sp)
    80002fb2:	6442                	ld	s0,16(sp)
    80002fb4:	64a2                	ld	s1,8(sp)
    80002fb6:	6105                	addi	sp,sp,32
    80002fb8:	8082                	ret
    return p->trapframe->a1;
    80002fba:	7d3c                	ld	a5,120(a0)
    80002fbc:	7fa8                	ld	a0,120(a5)
    80002fbe:	bfcd                	j	80002fb0 <argraw+0x30>
    return p->trapframe->a2;
    80002fc0:	7d3c                	ld	a5,120(a0)
    80002fc2:	63c8                	ld	a0,128(a5)
    80002fc4:	b7f5                	j	80002fb0 <argraw+0x30>
    return p->trapframe->a3;
    80002fc6:	7d3c                	ld	a5,120(a0)
    80002fc8:	67c8                	ld	a0,136(a5)
    80002fca:	b7dd                	j	80002fb0 <argraw+0x30>
    return p->trapframe->a4;
    80002fcc:	7d3c                	ld	a5,120(a0)
    80002fce:	6bc8                	ld	a0,144(a5)
    80002fd0:	b7c5                	j	80002fb0 <argraw+0x30>
    return p->trapframe->a5;
    80002fd2:	7d3c                	ld	a5,120(a0)
    80002fd4:	6fc8                	ld	a0,152(a5)
    80002fd6:	bfe9                	j	80002fb0 <argraw+0x30>
  panic("argraw");
    80002fd8:	00005517          	auipc	a0,0x5
    80002fdc:	45850513          	addi	a0,a0,1112 # 80008430 <states.1768+0x148>
    80002fe0:	ffffd097          	auipc	ra,0xffffd
    80002fe4:	55e080e7          	jalr	1374(ra) # 8000053e <panic>

0000000080002fe8 <fetchaddr>:
{
    80002fe8:	1101                	addi	sp,sp,-32
    80002fea:	ec06                	sd	ra,24(sp)
    80002fec:	e822                	sd	s0,16(sp)
    80002fee:	e426                	sd	s1,8(sp)
    80002ff0:	e04a                	sd	s2,0(sp)
    80002ff2:	1000                	addi	s0,sp,32
    80002ff4:	84aa                	mv	s1,a0
    80002ff6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	90e080e7          	jalr	-1778(ra) # 80001906 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003000:	753c                	ld	a5,104(a0)
    80003002:	02f4f863          	bgeu	s1,a5,80003032 <fetchaddr+0x4a>
    80003006:	00848713          	addi	a4,s1,8
    8000300a:	02e7e663          	bltu	a5,a4,80003036 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000300e:	46a1                	li	a3,8
    80003010:	8626                	mv	a2,s1
    80003012:	85ca                	mv	a1,s2
    80003014:	7928                	ld	a0,112(a0)
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	6e8080e7          	jalr	1768(ra) # 800016fe <copyin>
    8000301e:	00a03533          	snez	a0,a0
    80003022:	40a00533          	neg	a0,a0
}
    80003026:	60e2                	ld	ra,24(sp)
    80003028:	6442                	ld	s0,16(sp)
    8000302a:	64a2                	ld	s1,8(sp)
    8000302c:	6902                	ld	s2,0(sp)
    8000302e:	6105                	addi	sp,sp,32
    80003030:	8082                	ret
    return -1;
    80003032:	557d                	li	a0,-1
    80003034:	bfcd                	j	80003026 <fetchaddr+0x3e>
    80003036:	557d                	li	a0,-1
    80003038:	b7fd                	j	80003026 <fetchaddr+0x3e>

000000008000303a <fetchstr>:
{
    8000303a:	7179                	addi	sp,sp,-48
    8000303c:	f406                	sd	ra,40(sp)
    8000303e:	f022                	sd	s0,32(sp)
    80003040:	ec26                	sd	s1,24(sp)
    80003042:	e84a                	sd	s2,16(sp)
    80003044:	e44e                	sd	s3,8(sp)
    80003046:	1800                	addi	s0,sp,48
    80003048:	892a                	mv	s2,a0
    8000304a:	84ae                	mv	s1,a1
    8000304c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000304e:	fffff097          	auipc	ra,0xfffff
    80003052:	8b8080e7          	jalr	-1864(ra) # 80001906 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003056:	86ce                	mv	a3,s3
    80003058:	864a                	mv	a2,s2
    8000305a:	85a6                	mv	a1,s1
    8000305c:	7928                	ld	a0,112(a0)
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	72c080e7          	jalr	1836(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003066:	00054763          	bltz	a0,80003074 <fetchstr+0x3a>
  return strlen(buf);
    8000306a:	8526                	mv	a0,s1
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	df8080e7          	jalr	-520(ra) # 80000e64 <strlen>
}
    80003074:	70a2                	ld	ra,40(sp)
    80003076:	7402                	ld	s0,32(sp)
    80003078:	64e2                	ld	s1,24(sp)
    8000307a:	6942                	ld	s2,16(sp)
    8000307c:	69a2                	ld	s3,8(sp)
    8000307e:	6145                	addi	sp,sp,48
    80003080:	8082                	ret

0000000080003082 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	e426                	sd	s1,8(sp)
    8000308a:	1000                	addi	s0,sp,32
    8000308c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000308e:	00000097          	auipc	ra,0x0
    80003092:	ef2080e7          	jalr	-270(ra) # 80002f80 <argraw>
    80003096:	c088                	sw	a0,0(s1)
  return 0;
}
    80003098:	4501                	li	a0,0
    8000309a:	60e2                	ld	ra,24(sp)
    8000309c:	6442                	ld	s0,16(sp)
    8000309e:	64a2                	ld	s1,8(sp)
    800030a0:	6105                	addi	sp,sp,32
    800030a2:	8082                	ret

00000000800030a4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030a4:	1101                	addi	sp,sp,-32
    800030a6:	ec06                	sd	ra,24(sp)
    800030a8:	e822                	sd	s0,16(sp)
    800030aa:	e426                	sd	s1,8(sp)
    800030ac:	1000                	addi	s0,sp,32
    800030ae:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030b0:	00000097          	auipc	ra,0x0
    800030b4:	ed0080e7          	jalr	-304(ra) # 80002f80 <argraw>
    800030b8:	e088                	sd	a0,0(s1)
  return 0;
}
    800030ba:	4501                	li	a0,0
    800030bc:	60e2                	ld	ra,24(sp)
    800030be:	6442                	ld	s0,16(sp)
    800030c0:	64a2                	ld	s1,8(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret

00000000800030c6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	e04a                	sd	s2,0(sp)
    800030d0:	1000                	addi	s0,sp,32
    800030d2:	84ae                	mv	s1,a1
    800030d4:	8932                	mv	s2,a2
  *ip = argraw(n);
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	eaa080e7          	jalr	-342(ra) # 80002f80 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800030de:	864a                	mv	a2,s2
    800030e0:	85a6                	mv	a1,s1
    800030e2:	00000097          	auipc	ra,0x0
    800030e6:	f58080e7          	jalr	-168(ra) # 8000303a <fetchstr>
}
    800030ea:	60e2                	ld	ra,24(sp)
    800030ec:	6442                	ld	s0,16(sp)
    800030ee:	64a2                	ld	s1,8(sp)
    800030f0:	6902                	ld	s2,0(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret

00000000800030f6 <syscall>:
[SYS_get_cpu] sys_get_cpu,
};

void
syscall(void)
{
    800030f6:	1101                	addi	sp,sp,-32
    800030f8:	ec06                	sd	ra,24(sp)
    800030fa:	e822                	sd	s0,16(sp)
    800030fc:	e426                	sd	s1,8(sp)
    800030fe:	e04a                	sd	s2,0(sp)
    80003100:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	804080e7          	jalr	-2044(ra) # 80001906 <myproc>
    8000310a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000310c:	07853903          	ld	s2,120(a0)
    80003110:	0a893783          	ld	a5,168(s2)
    80003114:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003118:	37fd                	addiw	a5,a5,-1
    8000311a:	4759                	li	a4,22
    8000311c:	00f76f63          	bltu	a4,a5,8000313a <syscall+0x44>
    80003120:	00369713          	slli	a4,a3,0x3
    80003124:	00005797          	auipc	a5,0x5
    80003128:	34c78793          	addi	a5,a5,844 # 80008470 <syscalls>
    8000312c:	97ba                	add	a5,a5,a4
    8000312e:	639c                	ld	a5,0(a5)
    80003130:	c789                	beqz	a5,8000313a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003132:	9782                	jalr	a5
    80003134:	06a93823          	sd	a0,112(s2)
    80003138:	a839                	j	80003156 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000313a:	17848613          	addi	a2,s1,376
    8000313e:	588c                	lw	a1,48(s1)
    80003140:	00005517          	auipc	a0,0x5
    80003144:	2f850513          	addi	a0,a0,760 # 80008438 <states.1768+0x150>
    80003148:	ffffd097          	auipc	ra,0xffffd
    8000314c:	440080e7          	jalr	1088(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003150:	7cbc                	ld	a5,120(s1)
    80003152:	577d                	li	a4,-1
    80003154:	fbb8                	sd	a4,112(a5)
  }
}
    80003156:	60e2                	ld	ra,24(sp)
    80003158:	6442                	ld	s0,16(sp)
    8000315a:	64a2                	ld	s1,8(sp)
    8000315c:	6902                	ld	s2,0(sp)
    8000315e:	6105                	addi	sp,sp,32
    80003160:	8082                	ret

0000000080003162 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003162:	1101                	addi	sp,sp,-32
    80003164:	ec06                	sd	ra,24(sp)
    80003166:	e822                	sd	s0,16(sp)
    80003168:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000316a:	fec40593          	addi	a1,s0,-20
    8000316e:	4501                	li	a0,0
    80003170:	00000097          	auipc	ra,0x0
    80003174:	f12080e7          	jalr	-238(ra) # 80003082 <argint>
    return -1;
    80003178:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000317a:	00054963          	bltz	a0,8000318c <sys_exit+0x2a>
  exit(n);
    8000317e:	fec42503          	lw	a0,-20(s0)
    80003182:	fffff097          	auipc	ra,0xfffff
    80003186:	3c6080e7          	jalr	966(ra) # 80002548 <exit>
  return 0;  // not reached
    8000318a:	4781                	li	a5,0
}
    8000318c:	853e                	mv	a0,a5
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	6105                	addi	sp,sp,32
    80003194:	8082                	ret

0000000080003196 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003196:	1141                	addi	sp,sp,-16
    80003198:	e406                	sd	ra,8(sp)
    8000319a:	e022                	sd	s0,0(sp)
    8000319c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	768080e7          	jalr	1896(ra) # 80001906 <myproc>
}
    800031a6:	5908                	lw	a0,48(a0)
    800031a8:	60a2                	ld	ra,8(sp)
    800031aa:	6402                	ld	s0,0(sp)
    800031ac:	0141                	addi	sp,sp,16
    800031ae:	8082                	ret

00000000800031b0 <sys_fork>:

uint64
sys_fork(void)
{
    800031b0:	1141                	addi	sp,sp,-16
    800031b2:	e406                	sd	ra,8(sp)
    800031b4:	e022                	sd	s0,0(sp)
    800031b6:	0800                	addi	s0,sp,16
  return fork();
    800031b8:	fffff097          	auipc	ra,0xfffff
    800031bc:	780080e7          	jalr	1920(ra) # 80002938 <fork>
}
    800031c0:	60a2                	ld	ra,8(sp)
    800031c2:	6402                	ld	s0,0(sp)
    800031c4:	0141                	addi	sp,sp,16
    800031c6:	8082                	ret

00000000800031c8 <sys_wait>:

uint64
sys_wait(void)
{
    800031c8:	1101                	addi	sp,sp,-32
    800031ca:	ec06                	sd	ra,24(sp)
    800031cc:	e822                	sd	s0,16(sp)
    800031ce:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800031d0:	fe840593          	addi	a1,s0,-24
    800031d4:	4501                	li	a0,0
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	ece080e7          	jalr	-306(ra) # 800030a4 <argaddr>
    800031de:	87aa                	mv	a5,a0
    return -1;
    800031e0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800031e2:	0007c863          	bltz	a5,800031f2 <sys_wait+0x2a>
  return wait(p);
    800031e6:	fe843503          	ld	a0,-24(s0)
    800031ea:	fffff097          	auipc	ra,0xfffff
    800031ee:	088080e7          	jalr	136(ra) # 80002272 <wait>
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	6105                	addi	sp,sp,32
    800031f8:	8082                	ret

00000000800031fa <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031fa:	7179                	addi	sp,sp,-48
    800031fc:	f406                	sd	ra,40(sp)
    800031fe:	f022                	sd	s0,32(sp)
    80003200:	ec26                	sd	s1,24(sp)
    80003202:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003204:	fdc40593          	addi	a1,s0,-36
    80003208:	4501                	li	a0,0
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	e78080e7          	jalr	-392(ra) # 80003082 <argint>
    80003212:	87aa                	mv	a5,a0
    return -1;
    80003214:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003216:	0207c063          	bltz	a5,80003236 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	6ec080e7          	jalr	1772(ra) # 80001906 <myproc>
    80003222:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003224:	fdc42503          	lw	a0,-36(s0)
    80003228:	fffff097          	auipc	ra,0xfffff
    8000322c:	888080e7          	jalr	-1912(ra) # 80001ab0 <growproc>
    80003230:	00054863          	bltz	a0,80003240 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003234:	8526                	mv	a0,s1
}
    80003236:	70a2                	ld	ra,40(sp)
    80003238:	7402                	ld	s0,32(sp)
    8000323a:	64e2                	ld	s1,24(sp)
    8000323c:	6145                	addi	sp,sp,48
    8000323e:	8082                	ret
    return -1;
    80003240:	557d                	li	a0,-1
    80003242:	bfd5                	j	80003236 <sys_sbrk+0x3c>

0000000080003244 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003244:	7139                	addi	sp,sp,-64
    80003246:	fc06                	sd	ra,56(sp)
    80003248:	f822                	sd	s0,48(sp)
    8000324a:	f426                	sd	s1,40(sp)
    8000324c:	f04a                	sd	s2,32(sp)
    8000324e:	ec4e                	sd	s3,24(sp)
    80003250:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003252:	fcc40593          	addi	a1,s0,-52
    80003256:	4501                	li	a0,0
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	e2a080e7          	jalr	-470(ra) # 80003082 <argint>
    return -1;
    80003260:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003262:	06054563          	bltz	a0,800032cc <sys_sleep+0x88>
  acquire(&tickslock);
    80003266:	00014517          	auipc	a0,0x14
    8000326a:	7f250513          	addi	a0,a0,2034 # 80017a58 <tickslock>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	976080e7          	jalr	-1674(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003276:	00006917          	auipc	s2,0x6
    8000327a:	dc292903          	lw	s2,-574(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    8000327e:	fcc42783          	lw	a5,-52(s0)
    80003282:	cf85                	beqz	a5,800032ba <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003284:	00014997          	auipc	s3,0x14
    80003288:	7d498993          	addi	s3,s3,2004 # 80017a58 <tickslock>
    8000328c:	00006497          	auipc	s1,0x6
    80003290:	dac48493          	addi	s1,s1,-596 # 80009038 <ticks>
    if(myproc()->killed){
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	672080e7          	jalr	1650(ra) # 80001906 <myproc>
    8000329c:	551c                	lw	a5,40(a0)
    8000329e:	ef9d                	bnez	a5,800032dc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032a0:	85ce                	mv	a1,s3
    800032a2:	8526                	mv	a0,s1
    800032a4:	fffff097          	auipc	ra,0xfffff
    800032a8:	d7c080e7          	jalr	-644(ra) # 80002020 <sleep>
  while(ticks - ticks0 < n){
    800032ac:	409c                	lw	a5,0(s1)
    800032ae:	412787bb          	subw	a5,a5,s2
    800032b2:	fcc42703          	lw	a4,-52(s0)
    800032b6:	fce7efe3          	bltu	a5,a4,80003294 <sys_sleep+0x50>
  }
  release(&tickslock);
    800032ba:	00014517          	auipc	a0,0x14
    800032be:	79e50513          	addi	a0,a0,1950 # 80017a58 <tickslock>
    800032c2:	ffffe097          	auipc	ra,0xffffe
    800032c6:	9d6080e7          	jalr	-1578(ra) # 80000c98 <release>
  return 0;
    800032ca:	4781                	li	a5,0
}
    800032cc:	853e                	mv	a0,a5
    800032ce:	70e2                	ld	ra,56(sp)
    800032d0:	7442                	ld	s0,48(sp)
    800032d2:	74a2                	ld	s1,40(sp)
    800032d4:	7902                	ld	s2,32(sp)
    800032d6:	69e2                	ld	s3,24(sp)
    800032d8:	6121                	addi	sp,sp,64
    800032da:	8082                	ret
      release(&tickslock);
    800032dc:	00014517          	auipc	a0,0x14
    800032e0:	77c50513          	addi	a0,a0,1916 # 80017a58 <tickslock>
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	9b4080e7          	jalr	-1612(ra) # 80000c98 <release>
      return -1;
    800032ec:	57fd                	li	a5,-1
    800032ee:	bff9                	j	800032cc <sys_sleep+0x88>

00000000800032f0 <sys_kill>:

uint64
sys_kill(void)
{
    800032f0:	1101                	addi	sp,sp,-32
    800032f2:	ec06                	sd	ra,24(sp)
    800032f4:	e822                	sd	s0,16(sp)
    800032f6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800032f8:	fec40593          	addi	a1,s0,-20
    800032fc:	4501                	li	a0,0
    800032fe:	00000097          	auipc	ra,0x0
    80003302:	d84080e7          	jalr	-636(ra) # 80003082 <argint>
    80003306:	87aa                	mv	a5,a0
    return -1;
    80003308:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000330a:	0007c863          	bltz	a5,8000331a <sys_kill+0x2a>
  return kill(pid);
    8000330e:	fec42503          	lw	a0,-20(s0)
    80003312:	fffff097          	auipc	ra,0xfffff
    80003316:	326080e7          	jalr	806(ra) # 80002638 <kill>
}
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	6105                	addi	sp,sp,32
    80003320:	8082                	ret

0000000080003322 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003322:	1101                	addi	sp,sp,-32
    80003324:	ec06                	sd	ra,24(sp)
    80003326:	e822                	sd	s0,16(sp)
    80003328:	e426                	sd	s1,8(sp)
    8000332a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000332c:	00014517          	auipc	a0,0x14
    80003330:	72c50513          	addi	a0,a0,1836 # 80017a58 <tickslock>
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	8b0080e7          	jalr	-1872(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000333c:	00006497          	auipc	s1,0x6
    80003340:	cfc4a483          	lw	s1,-772(s1) # 80009038 <ticks>
  release(&tickslock);
    80003344:	00014517          	auipc	a0,0x14
    80003348:	71450513          	addi	a0,a0,1812 # 80017a58 <tickslock>
    8000334c:	ffffe097          	auipc	ra,0xffffe
    80003350:	94c080e7          	jalr	-1716(ra) # 80000c98 <release>
  return xticks;
}
    80003354:	02049513          	slli	a0,s1,0x20
    80003358:	9101                	srli	a0,a0,0x20
    8000335a:	60e2                	ld	ra,24(sp)
    8000335c:	6442                	ld	s0,16(sp)
    8000335e:	64a2                	ld	s1,8(sp)
    80003360:	6105                	addi	sp,sp,32
    80003362:	8082                	ret

0000000080003364 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80003364:	1101                	addi	sp,sp,-32
    80003366:	ec06                	sd	ra,24(sp)
    80003368:	e822                	sd	s0,16(sp)
    8000336a:	1000                	addi	s0,sp,32
    int cpu_num;
    if(argint(0, &cpu_num) <= -1){
    8000336c:	fec40593          	addi	a1,s0,-20
    80003370:	4501                	li	a0,0
    80003372:	00000097          	auipc	ra,0x0
    80003376:	d10080e7          	jalr	-752(ra) # 80003082 <argint>
    8000337a:	87aa                	mv	a5,a0
      return -1;
    8000337c:	557d                	li	a0,-1
    if(argint(0, &cpu_num) <= -1){
    8000337e:	0007c863          	bltz	a5,8000338e <sys_set_cpu+0x2a>
    }
    
    return set_cpu(cpu_num);
    80003382:	fec42503          	lw	a0,-20(s0)
    80003386:	fffff097          	auipc	ra,0xfffff
    8000338a:	c5c080e7          	jalr	-932(ra) # 80001fe2 <set_cpu>
}
    8000338e:	60e2                	ld	ra,24(sp)
    80003390:	6442                	ld	s0,16(sp)
    80003392:	6105                	addi	sp,sp,32
    80003394:	8082                	ret

0000000080003396 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003396:	1141                	addi	sp,sp,-16
    80003398:	e406                	sd	ra,8(sp)
    8000339a:	e022                	sd	s0,0(sp)
    8000339c:	0800                	addi	s0,sp,16
    return get_cpu();
    8000339e:	fffff097          	auipc	ra,0xfffff
    800033a2:	9c2080e7          	jalr	-1598(ra) # 80001d60 <get_cpu>
    800033a6:	60a2                	ld	ra,8(sp)
    800033a8:	6402                	ld	s0,0(sp)
    800033aa:	0141                	addi	sp,sp,16
    800033ac:	8082                	ret

00000000800033ae <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033ae:	7179                	addi	sp,sp,-48
    800033b0:	f406                	sd	ra,40(sp)
    800033b2:	f022                	sd	s0,32(sp)
    800033b4:	ec26                	sd	s1,24(sp)
    800033b6:	e84a                	sd	s2,16(sp)
    800033b8:	e44e                	sd	s3,8(sp)
    800033ba:	e052                	sd	s4,0(sp)
    800033bc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033be:	00005597          	auipc	a1,0x5
    800033c2:	17258593          	addi	a1,a1,370 # 80008530 <syscalls+0xc0>
    800033c6:	00014517          	auipc	a0,0x14
    800033ca:	6aa50513          	addi	a0,a0,1706 # 80017a70 <bcache>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	786080e7          	jalr	1926(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033d6:	0001c797          	auipc	a5,0x1c
    800033da:	69a78793          	addi	a5,a5,1690 # 8001fa70 <bcache+0x8000>
    800033de:	0001d717          	auipc	a4,0x1d
    800033e2:	8fa70713          	addi	a4,a4,-1798 # 8001fcd8 <bcache+0x8268>
    800033e6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033ea:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033ee:	00014497          	auipc	s1,0x14
    800033f2:	69a48493          	addi	s1,s1,1690 # 80017a88 <bcache+0x18>
    b->next = bcache.head.next;
    800033f6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033f8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033fa:	00005a17          	auipc	s4,0x5
    800033fe:	13ea0a13          	addi	s4,s4,318 # 80008538 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003402:	2b893783          	ld	a5,696(s2)
    80003406:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003408:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000340c:	85d2                	mv	a1,s4
    8000340e:	01048513          	addi	a0,s1,16
    80003412:	00001097          	auipc	ra,0x1
    80003416:	4bc080e7          	jalr	1212(ra) # 800048ce <initsleeplock>
    bcache.head.next->prev = b;
    8000341a:	2b893783          	ld	a5,696(s2)
    8000341e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003420:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003424:	45848493          	addi	s1,s1,1112
    80003428:	fd349de3          	bne	s1,s3,80003402 <binit+0x54>
  }
}
    8000342c:	70a2                	ld	ra,40(sp)
    8000342e:	7402                	ld	s0,32(sp)
    80003430:	64e2                	ld	s1,24(sp)
    80003432:	6942                	ld	s2,16(sp)
    80003434:	69a2                	ld	s3,8(sp)
    80003436:	6a02                	ld	s4,0(sp)
    80003438:	6145                	addi	sp,sp,48
    8000343a:	8082                	ret

000000008000343c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000343c:	7179                	addi	sp,sp,-48
    8000343e:	f406                	sd	ra,40(sp)
    80003440:	f022                	sd	s0,32(sp)
    80003442:	ec26                	sd	s1,24(sp)
    80003444:	e84a                	sd	s2,16(sp)
    80003446:	e44e                	sd	s3,8(sp)
    80003448:	1800                	addi	s0,sp,48
    8000344a:	89aa                	mv	s3,a0
    8000344c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000344e:	00014517          	auipc	a0,0x14
    80003452:	62250513          	addi	a0,a0,1570 # 80017a70 <bcache>
    80003456:	ffffd097          	auipc	ra,0xffffd
    8000345a:	78e080e7          	jalr	1934(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000345e:	0001d497          	auipc	s1,0x1d
    80003462:	8ca4b483          	ld	s1,-1846(s1) # 8001fd28 <bcache+0x82b8>
    80003466:	0001d797          	auipc	a5,0x1d
    8000346a:	87278793          	addi	a5,a5,-1934 # 8001fcd8 <bcache+0x8268>
    8000346e:	02f48f63          	beq	s1,a5,800034ac <bread+0x70>
    80003472:	873e                	mv	a4,a5
    80003474:	a021                	j	8000347c <bread+0x40>
    80003476:	68a4                	ld	s1,80(s1)
    80003478:	02e48a63          	beq	s1,a4,800034ac <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000347c:	449c                	lw	a5,8(s1)
    8000347e:	ff379ce3          	bne	a5,s3,80003476 <bread+0x3a>
    80003482:	44dc                	lw	a5,12(s1)
    80003484:	ff2799e3          	bne	a5,s2,80003476 <bread+0x3a>
      b->refcnt++;
    80003488:	40bc                	lw	a5,64(s1)
    8000348a:	2785                	addiw	a5,a5,1
    8000348c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000348e:	00014517          	auipc	a0,0x14
    80003492:	5e250513          	addi	a0,a0,1506 # 80017a70 <bcache>
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	802080e7          	jalr	-2046(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000349e:	01048513          	addi	a0,s1,16
    800034a2:	00001097          	auipc	ra,0x1
    800034a6:	466080e7          	jalr	1126(ra) # 80004908 <acquiresleep>
      return b;
    800034aa:	a8b9                	j	80003508 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034ac:	0001d497          	auipc	s1,0x1d
    800034b0:	8744b483          	ld	s1,-1932(s1) # 8001fd20 <bcache+0x82b0>
    800034b4:	0001d797          	auipc	a5,0x1d
    800034b8:	82478793          	addi	a5,a5,-2012 # 8001fcd8 <bcache+0x8268>
    800034bc:	00f48863          	beq	s1,a5,800034cc <bread+0x90>
    800034c0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034c2:	40bc                	lw	a5,64(s1)
    800034c4:	cf81                	beqz	a5,800034dc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034c6:	64a4                	ld	s1,72(s1)
    800034c8:	fee49de3          	bne	s1,a4,800034c2 <bread+0x86>
  panic("bget: no buffers");
    800034cc:	00005517          	auipc	a0,0x5
    800034d0:	07450513          	addi	a0,a0,116 # 80008540 <syscalls+0xd0>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	06a080e7          	jalr	106(ra) # 8000053e <panic>
      b->dev = dev;
    800034dc:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800034e0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800034e4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034e8:	4785                	li	a5,1
    800034ea:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034ec:	00014517          	auipc	a0,0x14
    800034f0:	58450513          	addi	a0,a0,1412 # 80017a70 <bcache>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	7a4080e7          	jalr	1956(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034fc:	01048513          	addi	a0,s1,16
    80003500:	00001097          	auipc	ra,0x1
    80003504:	408080e7          	jalr	1032(ra) # 80004908 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003508:	409c                	lw	a5,0(s1)
    8000350a:	cb89                	beqz	a5,8000351c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000350c:	8526                	mv	a0,s1
    8000350e:	70a2                	ld	ra,40(sp)
    80003510:	7402                	ld	s0,32(sp)
    80003512:	64e2                	ld	s1,24(sp)
    80003514:	6942                	ld	s2,16(sp)
    80003516:	69a2                	ld	s3,8(sp)
    80003518:	6145                	addi	sp,sp,48
    8000351a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000351c:	4581                	li	a1,0
    8000351e:	8526                	mv	a0,s1
    80003520:	00003097          	auipc	ra,0x3
    80003524:	f06080e7          	jalr	-250(ra) # 80006426 <virtio_disk_rw>
    b->valid = 1;
    80003528:	4785                	li	a5,1
    8000352a:	c09c                	sw	a5,0(s1)
  return b;
    8000352c:	b7c5                	j	8000350c <bread+0xd0>

000000008000352e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000352e:	1101                	addi	sp,sp,-32
    80003530:	ec06                	sd	ra,24(sp)
    80003532:	e822                	sd	s0,16(sp)
    80003534:	e426                	sd	s1,8(sp)
    80003536:	1000                	addi	s0,sp,32
    80003538:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000353a:	0541                	addi	a0,a0,16
    8000353c:	00001097          	auipc	ra,0x1
    80003540:	466080e7          	jalr	1126(ra) # 800049a2 <holdingsleep>
    80003544:	cd01                	beqz	a0,8000355c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003546:	4585                	li	a1,1
    80003548:	8526                	mv	a0,s1
    8000354a:	00003097          	auipc	ra,0x3
    8000354e:	edc080e7          	jalr	-292(ra) # 80006426 <virtio_disk_rw>
}
    80003552:	60e2                	ld	ra,24(sp)
    80003554:	6442                	ld	s0,16(sp)
    80003556:	64a2                	ld	s1,8(sp)
    80003558:	6105                	addi	sp,sp,32
    8000355a:	8082                	ret
    panic("bwrite");
    8000355c:	00005517          	auipc	a0,0x5
    80003560:	ffc50513          	addi	a0,a0,-4 # 80008558 <syscalls+0xe8>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	fda080e7          	jalr	-38(ra) # 8000053e <panic>

000000008000356c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000356c:	1101                	addi	sp,sp,-32
    8000356e:	ec06                	sd	ra,24(sp)
    80003570:	e822                	sd	s0,16(sp)
    80003572:	e426                	sd	s1,8(sp)
    80003574:	e04a                	sd	s2,0(sp)
    80003576:	1000                	addi	s0,sp,32
    80003578:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000357a:	01050913          	addi	s2,a0,16
    8000357e:	854a                	mv	a0,s2
    80003580:	00001097          	auipc	ra,0x1
    80003584:	422080e7          	jalr	1058(ra) # 800049a2 <holdingsleep>
    80003588:	c92d                	beqz	a0,800035fa <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000358a:	854a                	mv	a0,s2
    8000358c:	00001097          	auipc	ra,0x1
    80003590:	3d2080e7          	jalr	978(ra) # 8000495e <releasesleep>

  acquire(&bcache.lock);
    80003594:	00014517          	auipc	a0,0x14
    80003598:	4dc50513          	addi	a0,a0,1244 # 80017a70 <bcache>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	648080e7          	jalr	1608(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035a4:	40bc                	lw	a5,64(s1)
    800035a6:	37fd                	addiw	a5,a5,-1
    800035a8:	0007871b          	sext.w	a4,a5
    800035ac:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035ae:	eb05                	bnez	a4,800035de <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035b0:	68bc                	ld	a5,80(s1)
    800035b2:	64b8                	ld	a4,72(s1)
    800035b4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035b6:	64bc                	ld	a5,72(s1)
    800035b8:	68b8                	ld	a4,80(s1)
    800035ba:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035bc:	0001c797          	auipc	a5,0x1c
    800035c0:	4b478793          	addi	a5,a5,1204 # 8001fa70 <bcache+0x8000>
    800035c4:	2b87b703          	ld	a4,696(a5)
    800035c8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035ca:	0001c717          	auipc	a4,0x1c
    800035ce:	70e70713          	addi	a4,a4,1806 # 8001fcd8 <bcache+0x8268>
    800035d2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035d4:	2b87b703          	ld	a4,696(a5)
    800035d8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035da:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035de:	00014517          	auipc	a0,0x14
    800035e2:	49250513          	addi	a0,a0,1170 # 80017a70 <bcache>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	6b2080e7          	jalr	1714(ra) # 80000c98 <release>
}
    800035ee:	60e2                	ld	ra,24(sp)
    800035f0:	6442                	ld	s0,16(sp)
    800035f2:	64a2                	ld	s1,8(sp)
    800035f4:	6902                	ld	s2,0(sp)
    800035f6:	6105                	addi	sp,sp,32
    800035f8:	8082                	ret
    panic("brelse");
    800035fa:	00005517          	auipc	a0,0x5
    800035fe:	f6650513          	addi	a0,a0,-154 # 80008560 <syscalls+0xf0>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	f3c080e7          	jalr	-196(ra) # 8000053e <panic>

000000008000360a <bpin>:

void
bpin(struct buf *b) {
    8000360a:	1101                	addi	sp,sp,-32
    8000360c:	ec06                	sd	ra,24(sp)
    8000360e:	e822                	sd	s0,16(sp)
    80003610:	e426                	sd	s1,8(sp)
    80003612:	1000                	addi	s0,sp,32
    80003614:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003616:	00014517          	auipc	a0,0x14
    8000361a:	45a50513          	addi	a0,a0,1114 # 80017a70 <bcache>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	5c6080e7          	jalr	1478(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003626:	40bc                	lw	a5,64(s1)
    80003628:	2785                	addiw	a5,a5,1
    8000362a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000362c:	00014517          	auipc	a0,0x14
    80003630:	44450513          	addi	a0,a0,1092 # 80017a70 <bcache>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	664080e7          	jalr	1636(ra) # 80000c98 <release>
}
    8000363c:	60e2                	ld	ra,24(sp)
    8000363e:	6442                	ld	s0,16(sp)
    80003640:	64a2                	ld	s1,8(sp)
    80003642:	6105                	addi	sp,sp,32
    80003644:	8082                	ret

0000000080003646 <bunpin>:

void
bunpin(struct buf *b) {
    80003646:	1101                	addi	sp,sp,-32
    80003648:	ec06                	sd	ra,24(sp)
    8000364a:	e822                	sd	s0,16(sp)
    8000364c:	e426                	sd	s1,8(sp)
    8000364e:	1000                	addi	s0,sp,32
    80003650:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003652:	00014517          	auipc	a0,0x14
    80003656:	41e50513          	addi	a0,a0,1054 # 80017a70 <bcache>
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	58a080e7          	jalr	1418(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003662:	40bc                	lw	a5,64(s1)
    80003664:	37fd                	addiw	a5,a5,-1
    80003666:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003668:	00014517          	auipc	a0,0x14
    8000366c:	40850513          	addi	a0,a0,1032 # 80017a70 <bcache>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	628080e7          	jalr	1576(ra) # 80000c98 <release>
}
    80003678:	60e2                	ld	ra,24(sp)
    8000367a:	6442                	ld	s0,16(sp)
    8000367c:	64a2                	ld	s1,8(sp)
    8000367e:	6105                	addi	sp,sp,32
    80003680:	8082                	ret

0000000080003682 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003682:	1101                	addi	sp,sp,-32
    80003684:	ec06                	sd	ra,24(sp)
    80003686:	e822                	sd	s0,16(sp)
    80003688:	e426                	sd	s1,8(sp)
    8000368a:	e04a                	sd	s2,0(sp)
    8000368c:	1000                	addi	s0,sp,32
    8000368e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003690:	00d5d59b          	srliw	a1,a1,0xd
    80003694:	0001d797          	auipc	a5,0x1d
    80003698:	ab87a783          	lw	a5,-1352(a5) # 8002014c <sb+0x1c>
    8000369c:	9dbd                	addw	a1,a1,a5
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	d9e080e7          	jalr	-610(ra) # 8000343c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036a6:	0074f713          	andi	a4,s1,7
    800036aa:	4785                	li	a5,1
    800036ac:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036b0:	14ce                	slli	s1,s1,0x33
    800036b2:	90d9                	srli	s1,s1,0x36
    800036b4:	00950733          	add	a4,a0,s1
    800036b8:	05874703          	lbu	a4,88(a4)
    800036bc:	00e7f6b3          	and	a3,a5,a4
    800036c0:	c69d                	beqz	a3,800036ee <bfree+0x6c>
    800036c2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036c4:	94aa                	add	s1,s1,a0
    800036c6:	fff7c793          	not	a5,a5
    800036ca:	8ff9                	and	a5,a5,a4
    800036cc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	118080e7          	jalr	280(ra) # 800047e8 <log_write>
  brelse(bp);
    800036d8:	854a                	mv	a0,s2
    800036da:	00000097          	auipc	ra,0x0
    800036de:	e92080e7          	jalr	-366(ra) # 8000356c <brelse>
}
    800036e2:	60e2                	ld	ra,24(sp)
    800036e4:	6442                	ld	s0,16(sp)
    800036e6:	64a2                	ld	s1,8(sp)
    800036e8:	6902                	ld	s2,0(sp)
    800036ea:	6105                	addi	sp,sp,32
    800036ec:	8082                	ret
    panic("freeing free block");
    800036ee:	00005517          	auipc	a0,0x5
    800036f2:	e7a50513          	addi	a0,a0,-390 # 80008568 <syscalls+0xf8>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	e48080e7          	jalr	-440(ra) # 8000053e <panic>

00000000800036fe <balloc>:
{
    800036fe:	711d                	addi	sp,sp,-96
    80003700:	ec86                	sd	ra,88(sp)
    80003702:	e8a2                	sd	s0,80(sp)
    80003704:	e4a6                	sd	s1,72(sp)
    80003706:	e0ca                	sd	s2,64(sp)
    80003708:	fc4e                	sd	s3,56(sp)
    8000370a:	f852                	sd	s4,48(sp)
    8000370c:	f456                	sd	s5,40(sp)
    8000370e:	f05a                	sd	s6,32(sp)
    80003710:	ec5e                	sd	s7,24(sp)
    80003712:	e862                	sd	s8,16(sp)
    80003714:	e466                	sd	s9,8(sp)
    80003716:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003718:	0001d797          	auipc	a5,0x1d
    8000371c:	a1c7a783          	lw	a5,-1508(a5) # 80020134 <sb+0x4>
    80003720:	cbd1                	beqz	a5,800037b4 <balloc+0xb6>
    80003722:	8baa                	mv	s7,a0
    80003724:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003726:	0001db17          	auipc	s6,0x1d
    8000372a:	a0ab0b13          	addi	s6,s6,-1526 # 80020130 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000372e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003730:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003732:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003734:	6c89                	lui	s9,0x2
    80003736:	a831                	j	80003752 <balloc+0x54>
    brelse(bp);
    80003738:	854a                	mv	a0,s2
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	e32080e7          	jalr	-462(ra) # 8000356c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003742:	015c87bb          	addw	a5,s9,s5
    80003746:	00078a9b          	sext.w	s5,a5
    8000374a:	004b2703          	lw	a4,4(s6)
    8000374e:	06eaf363          	bgeu	s5,a4,800037b4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003752:	41fad79b          	sraiw	a5,s5,0x1f
    80003756:	0137d79b          	srliw	a5,a5,0x13
    8000375a:	015787bb          	addw	a5,a5,s5
    8000375e:	40d7d79b          	sraiw	a5,a5,0xd
    80003762:	01cb2583          	lw	a1,28(s6)
    80003766:	9dbd                	addw	a1,a1,a5
    80003768:	855e                	mv	a0,s7
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	cd2080e7          	jalr	-814(ra) # 8000343c <bread>
    80003772:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003774:	004b2503          	lw	a0,4(s6)
    80003778:	000a849b          	sext.w	s1,s5
    8000377c:	8662                	mv	a2,s8
    8000377e:	faa4fde3          	bgeu	s1,a0,80003738 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003782:	41f6579b          	sraiw	a5,a2,0x1f
    80003786:	01d7d69b          	srliw	a3,a5,0x1d
    8000378a:	00c6873b          	addw	a4,a3,a2
    8000378e:	00777793          	andi	a5,a4,7
    80003792:	9f95                	subw	a5,a5,a3
    80003794:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003798:	4037571b          	sraiw	a4,a4,0x3
    8000379c:	00e906b3          	add	a3,s2,a4
    800037a0:	0586c683          	lbu	a3,88(a3)
    800037a4:	00d7f5b3          	and	a1,a5,a3
    800037a8:	cd91                	beqz	a1,800037c4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037aa:	2605                	addiw	a2,a2,1
    800037ac:	2485                	addiw	s1,s1,1
    800037ae:	fd4618e3          	bne	a2,s4,8000377e <balloc+0x80>
    800037b2:	b759                	j	80003738 <balloc+0x3a>
  panic("balloc: out of blocks");
    800037b4:	00005517          	auipc	a0,0x5
    800037b8:	dcc50513          	addi	a0,a0,-564 # 80008580 <syscalls+0x110>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	d82080e7          	jalr	-638(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037c4:	974a                	add	a4,a4,s2
    800037c6:	8fd5                	or	a5,a5,a3
    800037c8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037cc:	854a                	mv	a0,s2
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	01a080e7          	jalr	26(ra) # 800047e8 <log_write>
        brelse(bp);
    800037d6:	854a                	mv	a0,s2
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	d94080e7          	jalr	-620(ra) # 8000356c <brelse>
  bp = bread(dev, bno);
    800037e0:	85a6                	mv	a1,s1
    800037e2:	855e                	mv	a0,s7
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	c58080e7          	jalr	-936(ra) # 8000343c <bread>
    800037ec:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037ee:	40000613          	li	a2,1024
    800037f2:	4581                	li	a1,0
    800037f4:	05850513          	addi	a0,a0,88
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	4e8080e7          	jalr	1256(ra) # 80000ce0 <memset>
  log_write(bp);
    80003800:	854a                	mv	a0,s2
    80003802:	00001097          	auipc	ra,0x1
    80003806:	fe6080e7          	jalr	-26(ra) # 800047e8 <log_write>
  brelse(bp);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	d60080e7          	jalr	-672(ra) # 8000356c <brelse>
}
    80003814:	8526                	mv	a0,s1
    80003816:	60e6                	ld	ra,88(sp)
    80003818:	6446                	ld	s0,80(sp)
    8000381a:	64a6                	ld	s1,72(sp)
    8000381c:	6906                	ld	s2,64(sp)
    8000381e:	79e2                	ld	s3,56(sp)
    80003820:	7a42                	ld	s4,48(sp)
    80003822:	7aa2                	ld	s5,40(sp)
    80003824:	7b02                	ld	s6,32(sp)
    80003826:	6be2                	ld	s7,24(sp)
    80003828:	6c42                	ld	s8,16(sp)
    8000382a:	6ca2                	ld	s9,8(sp)
    8000382c:	6125                	addi	sp,sp,96
    8000382e:	8082                	ret

0000000080003830 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003830:	7179                	addi	sp,sp,-48
    80003832:	f406                	sd	ra,40(sp)
    80003834:	f022                	sd	s0,32(sp)
    80003836:	ec26                	sd	s1,24(sp)
    80003838:	e84a                	sd	s2,16(sp)
    8000383a:	e44e                	sd	s3,8(sp)
    8000383c:	e052                	sd	s4,0(sp)
    8000383e:	1800                	addi	s0,sp,48
    80003840:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003842:	47ad                	li	a5,11
    80003844:	04b7fe63          	bgeu	a5,a1,800038a0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003848:	ff45849b          	addiw	s1,a1,-12
    8000384c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003850:	0ff00793          	li	a5,255
    80003854:	0ae7e363          	bltu	a5,a4,800038fa <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003858:	08052583          	lw	a1,128(a0)
    8000385c:	c5ad                	beqz	a1,800038c6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000385e:	00092503          	lw	a0,0(s2)
    80003862:	00000097          	auipc	ra,0x0
    80003866:	bda080e7          	jalr	-1062(ra) # 8000343c <bread>
    8000386a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000386c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003870:	02049593          	slli	a1,s1,0x20
    80003874:	9181                	srli	a1,a1,0x20
    80003876:	058a                	slli	a1,a1,0x2
    80003878:	00b784b3          	add	s1,a5,a1
    8000387c:	0004a983          	lw	s3,0(s1)
    80003880:	04098d63          	beqz	s3,800038da <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003884:	8552                	mv	a0,s4
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	ce6080e7          	jalr	-794(ra) # 8000356c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000388e:	854e                	mv	a0,s3
    80003890:	70a2                	ld	ra,40(sp)
    80003892:	7402                	ld	s0,32(sp)
    80003894:	64e2                	ld	s1,24(sp)
    80003896:	6942                	ld	s2,16(sp)
    80003898:	69a2                	ld	s3,8(sp)
    8000389a:	6a02                	ld	s4,0(sp)
    8000389c:	6145                	addi	sp,sp,48
    8000389e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800038a0:	02059493          	slli	s1,a1,0x20
    800038a4:	9081                	srli	s1,s1,0x20
    800038a6:	048a                	slli	s1,s1,0x2
    800038a8:	94aa                	add	s1,s1,a0
    800038aa:	0504a983          	lw	s3,80(s1)
    800038ae:	fe0990e3          	bnez	s3,8000388e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800038b2:	4108                	lw	a0,0(a0)
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	e4a080e7          	jalr	-438(ra) # 800036fe <balloc>
    800038bc:	0005099b          	sext.w	s3,a0
    800038c0:	0534a823          	sw	s3,80(s1)
    800038c4:	b7e9                	j	8000388e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800038c6:	4108                	lw	a0,0(a0)
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	e36080e7          	jalr	-458(ra) # 800036fe <balloc>
    800038d0:	0005059b          	sext.w	a1,a0
    800038d4:	08b92023          	sw	a1,128(s2)
    800038d8:	b759                	j	8000385e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038da:	00092503          	lw	a0,0(s2)
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	e20080e7          	jalr	-480(ra) # 800036fe <balloc>
    800038e6:	0005099b          	sext.w	s3,a0
    800038ea:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038ee:	8552                	mv	a0,s4
    800038f0:	00001097          	auipc	ra,0x1
    800038f4:	ef8080e7          	jalr	-264(ra) # 800047e8 <log_write>
    800038f8:	b771                	j	80003884 <bmap+0x54>
  panic("bmap: out of range");
    800038fa:	00005517          	auipc	a0,0x5
    800038fe:	c9e50513          	addi	a0,a0,-866 # 80008598 <syscalls+0x128>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	c3c080e7          	jalr	-964(ra) # 8000053e <panic>

000000008000390a <iget>:
{
    8000390a:	7179                	addi	sp,sp,-48
    8000390c:	f406                	sd	ra,40(sp)
    8000390e:	f022                	sd	s0,32(sp)
    80003910:	ec26                	sd	s1,24(sp)
    80003912:	e84a                	sd	s2,16(sp)
    80003914:	e44e                	sd	s3,8(sp)
    80003916:	e052                	sd	s4,0(sp)
    80003918:	1800                	addi	s0,sp,48
    8000391a:	89aa                	mv	s3,a0
    8000391c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000391e:	0001d517          	auipc	a0,0x1d
    80003922:	83250513          	addi	a0,a0,-1998 # 80020150 <itable>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	2be080e7          	jalr	702(ra) # 80000be4 <acquire>
  empty = 0;
    8000392e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003930:	0001d497          	auipc	s1,0x1d
    80003934:	83848493          	addi	s1,s1,-1992 # 80020168 <itable+0x18>
    80003938:	0001e697          	auipc	a3,0x1e
    8000393c:	2c068693          	addi	a3,a3,704 # 80021bf8 <log>
    80003940:	a039                	j	8000394e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003942:	02090b63          	beqz	s2,80003978 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003946:	08848493          	addi	s1,s1,136
    8000394a:	02d48a63          	beq	s1,a3,8000397e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000394e:	449c                	lw	a5,8(s1)
    80003950:	fef059e3          	blez	a5,80003942 <iget+0x38>
    80003954:	4098                	lw	a4,0(s1)
    80003956:	ff3716e3          	bne	a4,s3,80003942 <iget+0x38>
    8000395a:	40d8                	lw	a4,4(s1)
    8000395c:	ff4713e3          	bne	a4,s4,80003942 <iget+0x38>
      ip->ref++;
    80003960:	2785                	addiw	a5,a5,1
    80003962:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003964:	0001c517          	auipc	a0,0x1c
    80003968:	7ec50513          	addi	a0,a0,2028 # 80020150 <itable>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	32c080e7          	jalr	812(ra) # 80000c98 <release>
      return ip;
    80003974:	8926                	mv	s2,s1
    80003976:	a03d                	j	800039a4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003978:	f7f9                	bnez	a5,80003946 <iget+0x3c>
    8000397a:	8926                	mv	s2,s1
    8000397c:	b7e9                	j	80003946 <iget+0x3c>
  if(empty == 0)
    8000397e:	02090c63          	beqz	s2,800039b6 <iget+0xac>
  ip->dev = dev;
    80003982:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003986:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000398a:	4785                	li	a5,1
    8000398c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003990:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003994:	0001c517          	auipc	a0,0x1c
    80003998:	7bc50513          	addi	a0,a0,1980 # 80020150 <itable>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	2fc080e7          	jalr	764(ra) # 80000c98 <release>
}
    800039a4:	854a                	mv	a0,s2
    800039a6:	70a2                	ld	ra,40(sp)
    800039a8:	7402                	ld	s0,32(sp)
    800039aa:	64e2                	ld	s1,24(sp)
    800039ac:	6942                	ld	s2,16(sp)
    800039ae:	69a2                	ld	s3,8(sp)
    800039b0:	6a02                	ld	s4,0(sp)
    800039b2:	6145                	addi	sp,sp,48
    800039b4:	8082                	ret
    panic("iget: no inodes");
    800039b6:	00005517          	auipc	a0,0x5
    800039ba:	bfa50513          	addi	a0,a0,-1030 # 800085b0 <syscalls+0x140>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>

00000000800039c6 <fsinit>:
fsinit(int dev) {
    800039c6:	7179                	addi	sp,sp,-48
    800039c8:	f406                	sd	ra,40(sp)
    800039ca:	f022                	sd	s0,32(sp)
    800039cc:	ec26                	sd	s1,24(sp)
    800039ce:	e84a                	sd	s2,16(sp)
    800039d0:	e44e                	sd	s3,8(sp)
    800039d2:	1800                	addi	s0,sp,48
    800039d4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039d6:	4585                	li	a1,1
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	a64080e7          	jalr	-1436(ra) # 8000343c <bread>
    800039e0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039e2:	0001c997          	auipc	s3,0x1c
    800039e6:	74e98993          	addi	s3,s3,1870 # 80020130 <sb>
    800039ea:	02000613          	li	a2,32
    800039ee:	05850593          	addi	a1,a0,88
    800039f2:	854e                	mv	a0,s3
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	34c080e7          	jalr	844(ra) # 80000d40 <memmove>
  brelse(bp);
    800039fc:	8526                	mv	a0,s1
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	b6e080e7          	jalr	-1170(ra) # 8000356c <brelse>
  if(sb.magic != FSMAGIC)
    80003a06:	0009a703          	lw	a4,0(s3)
    80003a0a:	102037b7          	lui	a5,0x10203
    80003a0e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a12:	02f71263          	bne	a4,a5,80003a36 <fsinit+0x70>
  initlog(dev, &sb);
    80003a16:	0001c597          	auipc	a1,0x1c
    80003a1a:	71a58593          	addi	a1,a1,1818 # 80020130 <sb>
    80003a1e:	854a                	mv	a0,s2
    80003a20:	00001097          	auipc	ra,0x1
    80003a24:	b4c080e7          	jalr	-1204(ra) # 8000456c <initlog>
}
    80003a28:	70a2                	ld	ra,40(sp)
    80003a2a:	7402                	ld	s0,32(sp)
    80003a2c:	64e2                	ld	s1,24(sp)
    80003a2e:	6942                	ld	s2,16(sp)
    80003a30:	69a2                	ld	s3,8(sp)
    80003a32:	6145                	addi	sp,sp,48
    80003a34:	8082                	ret
    panic("invalid file system");
    80003a36:	00005517          	auipc	a0,0x5
    80003a3a:	b8a50513          	addi	a0,a0,-1142 # 800085c0 <syscalls+0x150>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>

0000000080003a46 <iinit>:
{
    80003a46:	7179                	addi	sp,sp,-48
    80003a48:	f406                	sd	ra,40(sp)
    80003a4a:	f022                	sd	s0,32(sp)
    80003a4c:	ec26                	sd	s1,24(sp)
    80003a4e:	e84a                	sd	s2,16(sp)
    80003a50:	e44e                	sd	s3,8(sp)
    80003a52:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a54:	00005597          	auipc	a1,0x5
    80003a58:	b8458593          	addi	a1,a1,-1148 # 800085d8 <syscalls+0x168>
    80003a5c:	0001c517          	auipc	a0,0x1c
    80003a60:	6f450513          	addi	a0,a0,1780 # 80020150 <itable>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	0f0080e7          	jalr	240(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a6c:	0001c497          	auipc	s1,0x1c
    80003a70:	70c48493          	addi	s1,s1,1804 # 80020178 <itable+0x28>
    80003a74:	0001e997          	auipc	s3,0x1e
    80003a78:	19498993          	addi	s3,s3,404 # 80021c08 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a7c:	00005917          	auipc	s2,0x5
    80003a80:	b6490913          	addi	s2,s2,-1180 # 800085e0 <syscalls+0x170>
    80003a84:	85ca                	mv	a1,s2
    80003a86:	8526                	mv	a0,s1
    80003a88:	00001097          	auipc	ra,0x1
    80003a8c:	e46080e7          	jalr	-442(ra) # 800048ce <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a90:	08848493          	addi	s1,s1,136
    80003a94:	ff3498e3          	bne	s1,s3,80003a84 <iinit+0x3e>
}
    80003a98:	70a2                	ld	ra,40(sp)
    80003a9a:	7402                	ld	s0,32(sp)
    80003a9c:	64e2                	ld	s1,24(sp)
    80003a9e:	6942                	ld	s2,16(sp)
    80003aa0:	69a2                	ld	s3,8(sp)
    80003aa2:	6145                	addi	sp,sp,48
    80003aa4:	8082                	ret

0000000080003aa6 <ialloc>:
{
    80003aa6:	715d                	addi	sp,sp,-80
    80003aa8:	e486                	sd	ra,72(sp)
    80003aaa:	e0a2                	sd	s0,64(sp)
    80003aac:	fc26                	sd	s1,56(sp)
    80003aae:	f84a                	sd	s2,48(sp)
    80003ab0:	f44e                	sd	s3,40(sp)
    80003ab2:	f052                	sd	s4,32(sp)
    80003ab4:	ec56                	sd	s5,24(sp)
    80003ab6:	e85a                	sd	s6,16(sp)
    80003ab8:	e45e                	sd	s7,8(sp)
    80003aba:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003abc:	0001c717          	auipc	a4,0x1c
    80003ac0:	68072703          	lw	a4,1664(a4) # 8002013c <sb+0xc>
    80003ac4:	4785                	li	a5,1
    80003ac6:	04e7fa63          	bgeu	a5,a4,80003b1a <ialloc+0x74>
    80003aca:	8aaa                	mv	s5,a0
    80003acc:	8bae                	mv	s7,a1
    80003ace:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ad0:	0001ca17          	auipc	s4,0x1c
    80003ad4:	660a0a13          	addi	s4,s4,1632 # 80020130 <sb>
    80003ad8:	00048b1b          	sext.w	s6,s1
    80003adc:	0044d593          	srli	a1,s1,0x4
    80003ae0:	018a2783          	lw	a5,24(s4)
    80003ae4:	9dbd                	addw	a1,a1,a5
    80003ae6:	8556                	mv	a0,s5
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	954080e7          	jalr	-1708(ra) # 8000343c <bread>
    80003af0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003af2:	05850993          	addi	s3,a0,88
    80003af6:	00f4f793          	andi	a5,s1,15
    80003afa:	079a                	slli	a5,a5,0x6
    80003afc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003afe:	00099783          	lh	a5,0(s3)
    80003b02:	c785                	beqz	a5,80003b2a <ialloc+0x84>
    brelse(bp);
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	a68080e7          	jalr	-1432(ra) # 8000356c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b0c:	0485                	addi	s1,s1,1
    80003b0e:	00ca2703          	lw	a4,12(s4)
    80003b12:	0004879b          	sext.w	a5,s1
    80003b16:	fce7e1e3          	bltu	a5,a4,80003ad8 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b1a:	00005517          	auipc	a0,0x5
    80003b1e:	ace50513          	addi	a0,a0,-1330 # 800085e8 <syscalls+0x178>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	a1c080e7          	jalr	-1508(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b2a:	04000613          	li	a2,64
    80003b2e:	4581                	li	a1,0
    80003b30:	854e                	mv	a0,s3
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	1ae080e7          	jalr	430(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b3a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00001097          	auipc	ra,0x1
    80003b44:	ca8080e7          	jalr	-856(ra) # 800047e8 <log_write>
      brelse(bp);
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	a22080e7          	jalr	-1502(ra) # 8000356c <brelse>
      return iget(dev, inum);
    80003b52:	85da                	mv	a1,s6
    80003b54:	8556                	mv	a0,s5
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	db4080e7          	jalr	-588(ra) # 8000390a <iget>
}
    80003b5e:	60a6                	ld	ra,72(sp)
    80003b60:	6406                	ld	s0,64(sp)
    80003b62:	74e2                	ld	s1,56(sp)
    80003b64:	7942                	ld	s2,48(sp)
    80003b66:	79a2                	ld	s3,40(sp)
    80003b68:	7a02                	ld	s4,32(sp)
    80003b6a:	6ae2                	ld	s5,24(sp)
    80003b6c:	6b42                	ld	s6,16(sp)
    80003b6e:	6ba2                	ld	s7,8(sp)
    80003b70:	6161                	addi	sp,sp,80
    80003b72:	8082                	ret

0000000080003b74 <iupdate>:
{
    80003b74:	1101                	addi	sp,sp,-32
    80003b76:	ec06                	sd	ra,24(sp)
    80003b78:	e822                	sd	s0,16(sp)
    80003b7a:	e426                	sd	s1,8(sp)
    80003b7c:	e04a                	sd	s2,0(sp)
    80003b7e:	1000                	addi	s0,sp,32
    80003b80:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b82:	415c                	lw	a5,4(a0)
    80003b84:	0047d79b          	srliw	a5,a5,0x4
    80003b88:	0001c597          	auipc	a1,0x1c
    80003b8c:	5c05a583          	lw	a1,1472(a1) # 80020148 <sb+0x18>
    80003b90:	9dbd                	addw	a1,a1,a5
    80003b92:	4108                	lw	a0,0(a0)
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	8a8080e7          	jalr	-1880(ra) # 8000343c <bread>
    80003b9c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b9e:	05850793          	addi	a5,a0,88
    80003ba2:	40c8                	lw	a0,4(s1)
    80003ba4:	893d                	andi	a0,a0,15
    80003ba6:	051a                	slli	a0,a0,0x6
    80003ba8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003baa:	04449703          	lh	a4,68(s1)
    80003bae:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bb2:	04649703          	lh	a4,70(s1)
    80003bb6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bba:	04849703          	lh	a4,72(s1)
    80003bbe:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003bc2:	04a49703          	lh	a4,74(s1)
    80003bc6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003bca:	44f8                	lw	a4,76(s1)
    80003bcc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bce:	03400613          	li	a2,52
    80003bd2:	05048593          	addi	a1,s1,80
    80003bd6:	0531                	addi	a0,a0,12
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	168080e7          	jalr	360(ra) # 80000d40 <memmove>
  log_write(bp);
    80003be0:	854a                	mv	a0,s2
    80003be2:	00001097          	auipc	ra,0x1
    80003be6:	c06080e7          	jalr	-1018(ra) # 800047e8 <log_write>
  brelse(bp);
    80003bea:	854a                	mv	a0,s2
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	980080e7          	jalr	-1664(ra) # 8000356c <brelse>
}
    80003bf4:	60e2                	ld	ra,24(sp)
    80003bf6:	6442                	ld	s0,16(sp)
    80003bf8:	64a2                	ld	s1,8(sp)
    80003bfa:	6902                	ld	s2,0(sp)
    80003bfc:	6105                	addi	sp,sp,32
    80003bfe:	8082                	ret

0000000080003c00 <idup>:
{
    80003c00:	1101                	addi	sp,sp,-32
    80003c02:	ec06                	sd	ra,24(sp)
    80003c04:	e822                	sd	s0,16(sp)
    80003c06:	e426                	sd	s1,8(sp)
    80003c08:	1000                	addi	s0,sp,32
    80003c0a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c0c:	0001c517          	auipc	a0,0x1c
    80003c10:	54450513          	addi	a0,a0,1348 # 80020150 <itable>
    80003c14:	ffffd097          	auipc	ra,0xffffd
    80003c18:	fd0080e7          	jalr	-48(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c1c:	449c                	lw	a5,8(s1)
    80003c1e:	2785                	addiw	a5,a5,1
    80003c20:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c22:	0001c517          	auipc	a0,0x1c
    80003c26:	52e50513          	addi	a0,a0,1326 # 80020150 <itable>
    80003c2a:	ffffd097          	auipc	ra,0xffffd
    80003c2e:	06e080e7          	jalr	110(ra) # 80000c98 <release>
}
    80003c32:	8526                	mv	a0,s1
    80003c34:	60e2                	ld	ra,24(sp)
    80003c36:	6442                	ld	s0,16(sp)
    80003c38:	64a2                	ld	s1,8(sp)
    80003c3a:	6105                	addi	sp,sp,32
    80003c3c:	8082                	ret

0000000080003c3e <ilock>:
{
    80003c3e:	1101                	addi	sp,sp,-32
    80003c40:	ec06                	sd	ra,24(sp)
    80003c42:	e822                	sd	s0,16(sp)
    80003c44:	e426                	sd	s1,8(sp)
    80003c46:	e04a                	sd	s2,0(sp)
    80003c48:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c4a:	c115                	beqz	a0,80003c6e <ilock+0x30>
    80003c4c:	84aa                	mv	s1,a0
    80003c4e:	451c                	lw	a5,8(a0)
    80003c50:	00f05f63          	blez	a5,80003c6e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c54:	0541                	addi	a0,a0,16
    80003c56:	00001097          	auipc	ra,0x1
    80003c5a:	cb2080e7          	jalr	-846(ra) # 80004908 <acquiresleep>
  if(ip->valid == 0){
    80003c5e:	40bc                	lw	a5,64(s1)
    80003c60:	cf99                	beqz	a5,80003c7e <ilock+0x40>
}
    80003c62:	60e2                	ld	ra,24(sp)
    80003c64:	6442                	ld	s0,16(sp)
    80003c66:	64a2                	ld	s1,8(sp)
    80003c68:	6902                	ld	s2,0(sp)
    80003c6a:	6105                	addi	sp,sp,32
    80003c6c:	8082                	ret
    panic("ilock");
    80003c6e:	00005517          	auipc	a0,0x5
    80003c72:	99250513          	addi	a0,a0,-1646 # 80008600 <syscalls+0x190>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	8c8080e7          	jalr	-1848(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c7e:	40dc                	lw	a5,4(s1)
    80003c80:	0047d79b          	srliw	a5,a5,0x4
    80003c84:	0001c597          	auipc	a1,0x1c
    80003c88:	4c45a583          	lw	a1,1220(a1) # 80020148 <sb+0x18>
    80003c8c:	9dbd                	addw	a1,a1,a5
    80003c8e:	4088                	lw	a0,0(s1)
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	7ac080e7          	jalr	1964(ra) # 8000343c <bread>
    80003c98:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c9a:	05850593          	addi	a1,a0,88
    80003c9e:	40dc                	lw	a5,4(s1)
    80003ca0:	8bbd                	andi	a5,a5,15
    80003ca2:	079a                	slli	a5,a5,0x6
    80003ca4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ca6:	00059783          	lh	a5,0(a1)
    80003caa:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cae:	00259783          	lh	a5,2(a1)
    80003cb2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cb6:	00459783          	lh	a5,4(a1)
    80003cba:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cbe:	00659783          	lh	a5,6(a1)
    80003cc2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cc6:	459c                	lw	a5,8(a1)
    80003cc8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cca:	03400613          	li	a2,52
    80003cce:	05b1                	addi	a1,a1,12
    80003cd0:	05048513          	addi	a0,s1,80
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	06c080e7          	jalr	108(ra) # 80000d40 <memmove>
    brelse(bp);
    80003cdc:	854a                	mv	a0,s2
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	88e080e7          	jalr	-1906(ra) # 8000356c <brelse>
    ip->valid = 1;
    80003ce6:	4785                	li	a5,1
    80003ce8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cea:	04449783          	lh	a5,68(s1)
    80003cee:	fbb5                	bnez	a5,80003c62 <ilock+0x24>
      panic("ilock: no type");
    80003cf0:	00005517          	auipc	a0,0x5
    80003cf4:	91850513          	addi	a0,a0,-1768 # 80008608 <syscalls+0x198>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	846080e7          	jalr	-1978(ra) # 8000053e <panic>

0000000080003d00 <iunlock>:
{
    80003d00:	1101                	addi	sp,sp,-32
    80003d02:	ec06                	sd	ra,24(sp)
    80003d04:	e822                	sd	s0,16(sp)
    80003d06:	e426                	sd	s1,8(sp)
    80003d08:	e04a                	sd	s2,0(sp)
    80003d0a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d0c:	c905                	beqz	a0,80003d3c <iunlock+0x3c>
    80003d0e:	84aa                	mv	s1,a0
    80003d10:	01050913          	addi	s2,a0,16
    80003d14:	854a                	mv	a0,s2
    80003d16:	00001097          	auipc	ra,0x1
    80003d1a:	c8c080e7          	jalr	-884(ra) # 800049a2 <holdingsleep>
    80003d1e:	cd19                	beqz	a0,80003d3c <iunlock+0x3c>
    80003d20:	449c                	lw	a5,8(s1)
    80003d22:	00f05d63          	blez	a5,80003d3c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d26:	854a                	mv	a0,s2
    80003d28:	00001097          	auipc	ra,0x1
    80003d2c:	c36080e7          	jalr	-970(ra) # 8000495e <releasesleep>
}
    80003d30:	60e2                	ld	ra,24(sp)
    80003d32:	6442                	ld	s0,16(sp)
    80003d34:	64a2                	ld	s1,8(sp)
    80003d36:	6902                	ld	s2,0(sp)
    80003d38:	6105                	addi	sp,sp,32
    80003d3a:	8082                	ret
    panic("iunlock");
    80003d3c:	00005517          	auipc	a0,0x5
    80003d40:	8dc50513          	addi	a0,a0,-1828 # 80008618 <syscalls+0x1a8>
    80003d44:	ffffc097          	auipc	ra,0xffffc
    80003d48:	7fa080e7          	jalr	2042(ra) # 8000053e <panic>

0000000080003d4c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d4c:	7179                	addi	sp,sp,-48
    80003d4e:	f406                	sd	ra,40(sp)
    80003d50:	f022                	sd	s0,32(sp)
    80003d52:	ec26                	sd	s1,24(sp)
    80003d54:	e84a                	sd	s2,16(sp)
    80003d56:	e44e                	sd	s3,8(sp)
    80003d58:	e052                	sd	s4,0(sp)
    80003d5a:	1800                	addi	s0,sp,48
    80003d5c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d5e:	05050493          	addi	s1,a0,80
    80003d62:	08050913          	addi	s2,a0,128
    80003d66:	a021                	j	80003d6e <itrunc+0x22>
    80003d68:	0491                	addi	s1,s1,4
    80003d6a:	01248d63          	beq	s1,s2,80003d84 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d6e:	408c                	lw	a1,0(s1)
    80003d70:	dde5                	beqz	a1,80003d68 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d72:	0009a503          	lw	a0,0(s3)
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	90c080e7          	jalr	-1780(ra) # 80003682 <bfree>
      ip->addrs[i] = 0;
    80003d7e:	0004a023          	sw	zero,0(s1)
    80003d82:	b7dd                	j	80003d68 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d84:	0809a583          	lw	a1,128(s3)
    80003d88:	e185                	bnez	a1,80003da8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d8a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d8e:	854e                	mv	a0,s3
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	de4080e7          	jalr	-540(ra) # 80003b74 <iupdate>
}
    80003d98:	70a2                	ld	ra,40(sp)
    80003d9a:	7402                	ld	s0,32(sp)
    80003d9c:	64e2                	ld	s1,24(sp)
    80003d9e:	6942                	ld	s2,16(sp)
    80003da0:	69a2                	ld	s3,8(sp)
    80003da2:	6a02                	ld	s4,0(sp)
    80003da4:	6145                	addi	sp,sp,48
    80003da6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003da8:	0009a503          	lw	a0,0(s3)
    80003dac:	fffff097          	auipc	ra,0xfffff
    80003db0:	690080e7          	jalr	1680(ra) # 8000343c <bread>
    80003db4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003db6:	05850493          	addi	s1,a0,88
    80003dba:	45850913          	addi	s2,a0,1112
    80003dbe:	a811                	j	80003dd2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003dc0:	0009a503          	lw	a0,0(s3)
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	8be080e7          	jalr	-1858(ra) # 80003682 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003dcc:	0491                	addi	s1,s1,4
    80003dce:	01248563          	beq	s1,s2,80003dd8 <itrunc+0x8c>
      if(a[j])
    80003dd2:	408c                	lw	a1,0(s1)
    80003dd4:	dde5                	beqz	a1,80003dcc <itrunc+0x80>
    80003dd6:	b7ed                	j	80003dc0 <itrunc+0x74>
    brelse(bp);
    80003dd8:	8552                	mv	a0,s4
    80003dda:	fffff097          	auipc	ra,0xfffff
    80003dde:	792080e7          	jalr	1938(ra) # 8000356c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003de2:	0809a583          	lw	a1,128(s3)
    80003de6:	0009a503          	lw	a0,0(s3)
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	898080e7          	jalr	-1896(ra) # 80003682 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003df2:	0809a023          	sw	zero,128(s3)
    80003df6:	bf51                	j	80003d8a <itrunc+0x3e>

0000000080003df8 <iput>:
{
    80003df8:	1101                	addi	sp,sp,-32
    80003dfa:	ec06                	sd	ra,24(sp)
    80003dfc:	e822                	sd	s0,16(sp)
    80003dfe:	e426                	sd	s1,8(sp)
    80003e00:	e04a                	sd	s2,0(sp)
    80003e02:	1000                	addi	s0,sp,32
    80003e04:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e06:	0001c517          	auipc	a0,0x1c
    80003e0a:	34a50513          	addi	a0,a0,842 # 80020150 <itable>
    80003e0e:	ffffd097          	auipc	ra,0xffffd
    80003e12:	dd6080e7          	jalr	-554(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e16:	4498                	lw	a4,8(s1)
    80003e18:	4785                	li	a5,1
    80003e1a:	02f70363          	beq	a4,a5,80003e40 <iput+0x48>
  ip->ref--;
    80003e1e:	449c                	lw	a5,8(s1)
    80003e20:	37fd                	addiw	a5,a5,-1
    80003e22:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e24:	0001c517          	auipc	a0,0x1c
    80003e28:	32c50513          	addi	a0,a0,812 # 80020150 <itable>
    80003e2c:	ffffd097          	auipc	ra,0xffffd
    80003e30:	e6c080e7          	jalr	-404(ra) # 80000c98 <release>
}
    80003e34:	60e2                	ld	ra,24(sp)
    80003e36:	6442                	ld	s0,16(sp)
    80003e38:	64a2                	ld	s1,8(sp)
    80003e3a:	6902                	ld	s2,0(sp)
    80003e3c:	6105                	addi	sp,sp,32
    80003e3e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e40:	40bc                	lw	a5,64(s1)
    80003e42:	dff1                	beqz	a5,80003e1e <iput+0x26>
    80003e44:	04a49783          	lh	a5,74(s1)
    80003e48:	fbf9                	bnez	a5,80003e1e <iput+0x26>
    acquiresleep(&ip->lock);
    80003e4a:	01048913          	addi	s2,s1,16
    80003e4e:	854a                	mv	a0,s2
    80003e50:	00001097          	auipc	ra,0x1
    80003e54:	ab8080e7          	jalr	-1352(ra) # 80004908 <acquiresleep>
    release(&itable.lock);
    80003e58:	0001c517          	auipc	a0,0x1c
    80003e5c:	2f850513          	addi	a0,a0,760 # 80020150 <itable>
    80003e60:	ffffd097          	auipc	ra,0xffffd
    80003e64:	e38080e7          	jalr	-456(ra) # 80000c98 <release>
    itrunc(ip);
    80003e68:	8526                	mv	a0,s1
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	ee2080e7          	jalr	-286(ra) # 80003d4c <itrunc>
    ip->type = 0;
    80003e72:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e76:	8526                	mv	a0,s1
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	cfc080e7          	jalr	-772(ra) # 80003b74 <iupdate>
    ip->valid = 0;
    80003e80:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e84:	854a                	mv	a0,s2
    80003e86:	00001097          	auipc	ra,0x1
    80003e8a:	ad8080e7          	jalr	-1320(ra) # 8000495e <releasesleep>
    acquire(&itable.lock);
    80003e8e:	0001c517          	auipc	a0,0x1c
    80003e92:	2c250513          	addi	a0,a0,706 # 80020150 <itable>
    80003e96:	ffffd097          	auipc	ra,0xffffd
    80003e9a:	d4e080e7          	jalr	-690(ra) # 80000be4 <acquire>
    80003e9e:	b741                	j	80003e1e <iput+0x26>

0000000080003ea0 <iunlockput>:
{
    80003ea0:	1101                	addi	sp,sp,-32
    80003ea2:	ec06                	sd	ra,24(sp)
    80003ea4:	e822                	sd	s0,16(sp)
    80003ea6:	e426                	sd	s1,8(sp)
    80003ea8:	1000                	addi	s0,sp,32
    80003eaa:	84aa                	mv	s1,a0
  iunlock(ip);
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	e54080e7          	jalr	-428(ra) # 80003d00 <iunlock>
  iput(ip);
    80003eb4:	8526                	mv	a0,s1
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	f42080e7          	jalr	-190(ra) # 80003df8 <iput>
}
    80003ebe:	60e2                	ld	ra,24(sp)
    80003ec0:	6442                	ld	s0,16(sp)
    80003ec2:	64a2                	ld	s1,8(sp)
    80003ec4:	6105                	addi	sp,sp,32
    80003ec6:	8082                	ret

0000000080003ec8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ec8:	1141                	addi	sp,sp,-16
    80003eca:	e422                	sd	s0,8(sp)
    80003ecc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ece:	411c                	lw	a5,0(a0)
    80003ed0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ed2:	415c                	lw	a5,4(a0)
    80003ed4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ed6:	04451783          	lh	a5,68(a0)
    80003eda:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ede:	04a51783          	lh	a5,74(a0)
    80003ee2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ee6:	04c56783          	lwu	a5,76(a0)
    80003eea:	e99c                	sd	a5,16(a1)
}
    80003eec:	6422                	ld	s0,8(sp)
    80003eee:	0141                	addi	sp,sp,16
    80003ef0:	8082                	ret

0000000080003ef2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ef2:	457c                	lw	a5,76(a0)
    80003ef4:	0ed7e963          	bltu	a5,a3,80003fe6 <readi+0xf4>
{
    80003ef8:	7159                	addi	sp,sp,-112
    80003efa:	f486                	sd	ra,104(sp)
    80003efc:	f0a2                	sd	s0,96(sp)
    80003efe:	eca6                	sd	s1,88(sp)
    80003f00:	e8ca                	sd	s2,80(sp)
    80003f02:	e4ce                	sd	s3,72(sp)
    80003f04:	e0d2                	sd	s4,64(sp)
    80003f06:	fc56                	sd	s5,56(sp)
    80003f08:	f85a                	sd	s6,48(sp)
    80003f0a:	f45e                	sd	s7,40(sp)
    80003f0c:	f062                	sd	s8,32(sp)
    80003f0e:	ec66                	sd	s9,24(sp)
    80003f10:	e86a                	sd	s10,16(sp)
    80003f12:	e46e                	sd	s11,8(sp)
    80003f14:	1880                	addi	s0,sp,112
    80003f16:	8baa                	mv	s7,a0
    80003f18:	8c2e                	mv	s8,a1
    80003f1a:	8ab2                	mv	s5,a2
    80003f1c:	84b6                	mv	s1,a3
    80003f1e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f20:	9f35                	addw	a4,a4,a3
    return 0;
    80003f22:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f24:	0ad76063          	bltu	a4,a3,80003fc4 <readi+0xd2>
  if(off + n > ip->size)
    80003f28:	00e7f463          	bgeu	a5,a4,80003f30 <readi+0x3e>
    n = ip->size - off;
    80003f2c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f30:	0a0b0963          	beqz	s6,80003fe2 <readi+0xf0>
    80003f34:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f36:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f3a:	5cfd                	li	s9,-1
    80003f3c:	a82d                	j	80003f76 <readi+0x84>
    80003f3e:	020a1d93          	slli	s11,s4,0x20
    80003f42:	020ddd93          	srli	s11,s11,0x20
    80003f46:	05890613          	addi	a2,s2,88
    80003f4a:	86ee                	mv	a3,s11
    80003f4c:	963a                	add	a2,a2,a4
    80003f4e:	85d6                	mv	a1,s5
    80003f50:	8562                	mv	a0,s8
    80003f52:	ffffe097          	auipc	ra,0xffffe
    80003f56:	cb4080e7          	jalr	-844(ra) # 80001c06 <either_copyout>
    80003f5a:	05950d63          	beq	a0,s9,80003fb4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f5e:	854a                	mv	a0,s2
    80003f60:	fffff097          	auipc	ra,0xfffff
    80003f64:	60c080e7          	jalr	1548(ra) # 8000356c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f68:	013a09bb          	addw	s3,s4,s3
    80003f6c:	009a04bb          	addw	s1,s4,s1
    80003f70:	9aee                	add	s5,s5,s11
    80003f72:	0569f763          	bgeu	s3,s6,80003fc0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f76:	000ba903          	lw	s2,0(s7)
    80003f7a:	00a4d59b          	srliw	a1,s1,0xa
    80003f7e:	855e                	mv	a0,s7
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	8b0080e7          	jalr	-1872(ra) # 80003830 <bmap>
    80003f88:	0005059b          	sext.w	a1,a0
    80003f8c:	854a                	mv	a0,s2
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	4ae080e7          	jalr	1198(ra) # 8000343c <bread>
    80003f96:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f98:	3ff4f713          	andi	a4,s1,1023
    80003f9c:	40ed07bb          	subw	a5,s10,a4
    80003fa0:	413b06bb          	subw	a3,s6,s3
    80003fa4:	8a3e                	mv	s4,a5
    80003fa6:	2781                	sext.w	a5,a5
    80003fa8:	0006861b          	sext.w	a2,a3
    80003fac:	f8f679e3          	bgeu	a2,a5,80003f3e <readi+0x4c>
    80003fb0:	8a36                	mv	s4,a3
    80003fb2:	b771                	j	80003f3e <readi+0x4c>
      brelse(bp);
    80003fb4:	854a                	mv	a0,s2
    80003fb6:	fffff097          	auipc	ra,0xfffff
    80003fba:	5b6080e7          	jalr	1462(ra) # 8000356c <brelse>
      tot = -1;
    80003fbe:	59fd                	li	s3,-1
  }
  return tot;
    80003fc0:	0009851b          	sext.w	a0,s3
}
    80003fc4:	70a6                	ld	ra,104(sp)
    80003fc6:	7406                	ld	s0,96(sp)
    80003fc8:	64e6                	ld	s1,88(sp)
    80003fca:	6946                	ld	s2,80(sp)
    80003fcc:	69a6                	ld	s3,72(sp)
    80003fce:	6a06                	ld	s4,64(sp)
    80003fd0:	7ae2                	ld	s5,56(sp)
    80003fd2:	7b42                	ld	s6,48(sp)
    80003fd4:	7ba2                	ld	s7,40(sp)
    80003fd6:	7c02                	ld	s8,32(sp)
    80003fd8:	6ce2                	ld	s9,24(sp)
    80003fda:	6d42                	ld	s10,16(sp)
    80003fdc:	6da2                	ld	s11,8(sp)
    80003fde:	6165                	addi	sp,sp,112
    80003fe0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fe2:	89da                	mv	s3,s6
    80003fe4:	bff1                	j	80003fc0 <readi+0xce>
    return 0;
    80003fe6:	4501                	li	a0,0
}
    80003fe8:	8082                	ret

0000000080003fea <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fea:	457c                	lw	a5,76(a0)
    80003fec:	10d7e863          	bltu	a5,a3,800040fc <writei+0x112>
{
    80003ff0:	7159                	addi	sp,sp,-112
    80003ff2:	f486                	sd	ra,104(sp)
    80003ff4:	f0a2                	sd	s0,96(sp)
    80003ff6:	eca6                	sd	s1,88(sp)
    80003ff8:	e8ca                	sd	s2,80(sp)
    80003ffa:	e4ce                	sd	s3,72(sp)
    80003ffc:	e0d2                	sd	s4,64(sp)
    80003ffe:	fc56                	sd	s5,56(sp)
    80004000:	f85a                	sd	s6,48(sp)
    80004002:	f45e                	sd	s7,40(sp)
    80004004:	f062                	sd	s8,32(sp)
    80004006:	ec66                	sd	s9,24(sp)
    80004008:	e86a                	sd	s10,16(sp)
    8000400a:	e46e                	sd	s11,8(sp)
    8000400c:	1880                	addi	s0,sp,112
    8000400e:	8b2a                	mv	s6,a0
    80004010:	8c2e                	mv	s8,a1
    80004012:	8ab2                	mv	s5,a2
    80004014:	8936                	mv	s2,a3
    80004016:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004018:	00e687bb          	addw	a5,a3,a4
    8000401c:	0ed7e263          	bltu	a5,a3,80004100 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004020:	00043737          	lui	a4,0x43
    80004024:	0ef76063          	bltu	a4,a5,80004104 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004028:	0c0b8863          	beqz	s7,800040f8 <writei+0x10e>
    8000402c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000402e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004032:	5cfd                	li	s9,-1
    80004034:	a091                	j	80004078 <writei+0x8e>
    80004036:	02099d93          	slli	s11,s3,0x20
    8000403a:	020ddd93          	srli	s11,s11,0x20
    8000403e:	05848513          	addi	a0,s1,88
    80004042:	86ee                	mv	a3,s11
    80004044:	8656                	mv	a2,s5
    80004046:	85e2                	mv	a1,s8
    80004048:	953a                	add	a0,a0,a4
    8000404a:	ffffe097          	auipc	ra,0xffffe
    8000404e:	c12080e7          	jalr	-1006(ra) # 80001c5c <either_copyin>
    80004052:	07950263          	beq	a0,s9,800040b6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004056:	8526                	mv	a0,s1
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	790080e7          	jalr	1936(ra) # 800047e8 <log_write>
    brelse(bp);
    80004060:	8526                	mv	a0,s1
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	50a080e7          	jalr	1290(ra) # 8000356c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000406a:	01498a3b          	addw	s4,s3,s4
    8000406e:	0129893b          	addw	s2,s3,s2
    80004072:	9aee                	add	s5,s5,s11
    80004074:	057a7663          	bgeu	s4,s7,800040c0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004078:	000b2483          	lw	s1,0(s6)
    8000407c:	00a9559b          	srliw	a1,s2,0xa
    80004080:	855a                	mv	a0,s6
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	7ae080e7          	jalr	1966(ra) # 80003830 <bmap>
    8000408a:	0005059b          	sext.w	a1,a0
    8000408e:	8526                	mv	a0,s1
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	3ac080e7          	jalr	940(ra) # 8000343c <bread>
    80004098:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000409a:	3ff97713          	andi	a4,s2,1023
    8000409e:	40ed07bb          	subw	a5,s10,a4
    800040a2:	414b86bb          	subw	a3,s7,s4
    800040a6:	89be                	mv	s3,a5
    800040a8:	2781                	sext.w	a5,a5
    800040aa:	0006861b          	sext.w	a2,a3
    800040ae:	f8f674e3          	bgeu	a2,a5,80004036 <writei+0x4c>
    800040b2:	89b6                	mv	s3,a3
    800040b4:	b749                	j	80004036 <writei+0x4c>
      brelse(bp);
    800040b6:	8526                	mv	a0,s1
    800040b8:	fffff097          	auipc	ra,0xfffff
    800040bc:	4b4080e7          	jalr	1204(ra) # 8000356c <brelse>
  }

  if(off > ip->size)
    800040c0:	04cb2783          	lw	a5,76(s6)
    800040c4:	0127f463          	bgeu	a5,s2,800040cc <writei+0xe2>
    ip->size = off;
    800040c8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040cc:	855a                	mv	a0,s6
    800040ce:	00000097          	auipc	ra,0x0
    800040d2:	aa6080e7          	jalr	-1370(ra) # 80003b74 <iupdate>

  return tot;
    800040d6:	000a051b          	sext.w	a0,s4
}
    800040da:	70a6                	ld	ra,104(sp)
    800040dc:	7406                	ld	s0,96(sp)
    800040de:	64e6                	ld	s1,88(sp)
    800040e0:	6946                	ld	s2,80(sp)
    800040e2:	69a6                	ld	s3,72(sp)
    800040e4:	6a06                	ld	s4,64(sp)
    800040e6:	7ae2                	ld	s5,56(sp)
    800040e8:	7b42                	ld	s6,48(sp)
    800040ea:	7ba2                	ld	s7,40(sp)
    800040ec:	7c02                	ld	s8,32(sp)
    800040ee:	6ce2                	ld	s9,24(sp)
    800040f0:	6d42                	ld	s10,16(sp)
    800040f2:	6da2                	ld	s11,8(sp)
    800040f4:	6165                	addi	sp,sp,112
    800040f6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f8:	8a5e                	mv	s4,s7
    800040fa:	bfc9                	j	800040cc <writei+0xe2>
    return -1;
    800040fc:	557d                	li	a0,-1
}
    800040fe:	8082                	ret
    return -1;
    80004100:	557d                	li	a0,-1
    80004102:	bfe1                	j	800040da <writei+0xf0>
    return -1;
    80004104:	557d                	li	a0,-1
    80004106:	bfd1                	j	800040da <writei+0xf0>

0000000080004108 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004108:	1141                	addi	sp,sp,-16
    8000410a:	e406                	sd	ra,8(sp)
    8000410c:	e022                	sd	s0,0(sp)
    8000410e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004110:	4639                	li	a2,14
    80004112:	ffffd097          	auipc	ra,0xffffd
    80004116:	ca6080e7          	jalr	-858(ra) # 80000db8 <strncmp>
}
    8000411a:	60a2                	ld	ra,8(sp)
    8000411c:	6402                	ld	s0,0(sp)
    8000411e:	0141                	addi	sp,sp,16
    80004120:	8082                	ret

0000000080004122 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004122:	7139                	addi	sp,sp,-64
    80004124:	fc06                	sd	ra,56(sp)
    80004126:	f822                	sd	s0,48(sp)
    80004128:	f426                	sd	s1,40(sp)
    8000412a:	f04a                	sd	s2,32(sp)
    8000412c:	ec4e                	sd	s3,24(sp)
    8000412e:	e852                	sd	s4,16(sp)
    80004130:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004132:	04451703          	lh	a4,68(a0)
    80004136:	4785                	li	a5,1
    80004138:	00f71a63          	bne	a4,a5,8000414c <dirlookup+0x2a>
    8000413c:	892a                	mv	s2,a0
    8000413e:	89ae                	mv	s3,a1
    80004140:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004142:	457c                	lw	a5,76(a0)
    80004144:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004146:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004148:	e79d                	bnez	a5,80004176 <dirlookup+0x54>
    8000414a:	a8a5                	j	800041c2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000414c:	00004517          	auipc	a0,0x4
    80004150:	4d450513          	addi	a0,a0,1236 # 80008620 <syscalls+0x1b0>
    80004154:	ffffc097          	auipc	ra,0xffffc
    80004158:	3ea080e7          	jalr	1002(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000415c:	00004517          	auipc	a0,0x4
    80004160:	4dc50513          	addi	a0,a0,1244 # 80008638 <syscalls+0x1c8>
    80004164:	ffffc097          	auipc	ra,0xffffc
    80004168:	3da080e7          	jalr	986(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000416c:	24c1                	addiw	s1,s1,16
    8000416e:	04c92783          	lw	a5,76(s2)
    80004172:	04f4f763          	bgeu	s1,a5,800041c0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004176:	4741                	li	a4,16
    80004178:	86a6                	mv	a3,s1
    8000417a:	fc040613          	addi	a2,s0,-64
    8000417e:	4581                	li	a1,0
    80004180:	854a                	mv	a0,s2
    80004182:	00000097          	auipc	ra,0x0
    80004186:	d70080e7          	jalr	-656(ra) # 80003ef2 <readi>
    8000418a:	47c1                	li	a5,16
    8000418c:	fcf518e3          	bne	a0,a5,8000415c <dirlookup+0x3a>
    if(de.inum == 0)
    80004190:	fc045783          	lhu	a5,-64(s0)
    80004194:	dfe1                	beqz	a5,8000416c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004196:	fc240593          	addi	a1,s0,-62
    8000419a:	854e                	mv	a0,s3
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	f6c080e7          	jalr	-148(ra) # 80004108 <namecmp>
    800041a4:	f561                	bnez	a0,8000416c <dirlookup+0x4a>
      if(poff)
    800041a6:	000a0463          	beqz	s4,800041ae <dirlookup+0x8c>
        *poff = off;
    800041aa:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041ae:	fc045583          	lhu	a1,-64(s0)
    800041b2:	00092503          	lw	a0,0(s2)
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	754080e7          	jalr	1876(ra) # 8000390a <iget>
    800041be:	a011                	j	800041c2 <dirlookup+0xa0>
  return 0;
    800041c0:	4501                	li	a0,0
}
    800041c2:	70e2                	ld	ra,56(sp)
    800041c4:	7442                	ld	s0,48(sp)
    800041c6:	74a2                	ld	s1,40(sp)
    800041c8:	7902                	ld	s2,32(sp)
    800041ca:	69e2                	ld	s3,24(sp)
    800041cc:	6a42                	ld	s4,16(sp)
    800041ce:	6121                	addi	sp,sp,64
    800041d0:	8082                	ret

00000000800041d2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041d2:	711d                	addi	sp,sp,-96
    800041d4:	ec86                	sd	ra,88(sp)
    800041d6:	e8a2                	sd	s0,80(sp)
    800041d8:	e4a6                	sd	s1,72(sp)
    800041da:	e0ca                	sd	s2,64(sp)
    800041dc:	fc4e                	sd	s3,56(sp)
    800041de:	f852                	sd	s4,48(sp)
    800041e0:	f456                	sd	s5,40(sp)
    800041e2:	f05a                	sd	s6,32(sp)
    800041e4:	ec5e                	sd	s7,24(sp)
    800041e6:	e862                	sd	s8,16(sp)
    800041e8:	e466                	sd	s9,8(sp)
    800041ea:	1080                	addi	s0,sp,96
    800041ec:	84aa                	mv	s1,a0
    800041ee:	8b2e                	mv	s6,a1
    800041f0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041f2:	00054703          	lbu	a4,0(a0)
    800041f6:	02f00793          	li	a5,47
    800041fa:	02f70363          	beq	a4,a5,80004220 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041fe:	ffffd097          	auipc	ra,0xffffd
    80004202:	708080e7          	jalr	1800(ra) # 80001906 <myproc>
    80004206:	17053503          	ld	a0,368(a0)
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	9f6080e7          	jalr	-1546(ra) # 80003c00 <idup>
    80004212:	89aa                	mv	s3,a0
  while(*path == '/')
    80004214:	02f00913          	li	s2,47
  len = path - s;
    80004218:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000421a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000421c:	4c05                	li	s8,1
    8000421e:	a865                	j	800042d6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004220:	4585                	li	a1,1
    80004222:	4505                	li	a0,1
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	6e6080e7          	jalr	1766(ra) # 8000390a <iget>
    8000422c:	89aa                	mv	s3,a0
    8000422e:	b7dd                	j	80004214 <namex+0x42>
      iunlockput(ip);
    80004230:	854e                	mv	a0,s3
    80004232:	00000097          	auipc	ra,0x0
    80004236:	c6e080e7          	jalr	-914(ra) # 80003ea0 <iunlockput>
      return 0;
    8000423a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000423c:	854e                	mv	a0,s3
    8000423e:	60e6                	ld	ra,88(sp)
    80004240:	6446                	ld	s0,80(sp)
    80004242:	64a6                	ld	s1,72(sp)
    80004244:	6906                	ld	s2,64(sp)
    80004246:	79e2                	ld	s3,56(sp)
    80004248:	7a42                	ld	s4,48(sp)
    8000424a:	7aa2                	ld	s5,40(sp)
    8000424c:	7b02                	ld	s6,32(sp)
    8000424e:	6be2                	ld	s7,24(sp)
    80004250:	6c42                	ld	s8,16(sp)
    80004252:	6ca2                	ld	s9,8(sp)
    80004254:	6125                	addi	sp,sp,96
    80004256:	8082                	ret
      iunlock(ip);
    80004258:	854e                	mv	a0,s3
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	aa6080e7          	jalr	-1370(ra) # 80003d00 <iunlock>
      return ip;
    80004262:	bfe9                	j	8000423c <namex+0x6a>
      iunlockput(ip);
    80004264:	854e                	mv	a0,s3
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	c3a080e7          	jalr	-966(ra) # 80003ea0 <iunlockput>
      return 0;
    8000426e:	89d2                	mv	s3,s4
    80004270:	b7f1                	j	8000423c <namex+0x6a>
  len = path - s;
    80004272:	40b48633          	sub	a2,s1,a1
    80004276:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000427a:	094cd463          	bge	s9,s4,80004302 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000427e:	4639                	li	a2,14
    80004280:	8556                	mv	a0,s5
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	abe080e7          	jalr	-1346(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000428a:	0004c783          	lbu	a5,0(s1)
    8000428e:	01279763          	bne	a5,s2,8000429c <namex+0xca>
    path++;
    80004292:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004294:	0004c783          	lbu	a5,0(s1)
    80004298:	ff278de3          	beq	a5,s2,80004292 <namex+0xc0>
    ilock(ip);
    8000429c:	854e                	mv	a0,s3
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	9a0080e7          	jalr	-1632(ra) # 80003c3e <ilock>
    if(ip->type != T_DIR){
    800042a6:	04499783          	lh	a5,68(s3)
    800042aa:	f98793e3          	bne	a5,s8,80004230 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042ae:	000b0563          	beqz	s6,800042b8 <namex+0xe6>
    800042b2:	0004c783          	lbu	a5,0(s1)
    800042b6:	d3cd                	beqz	a5,80004258 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042b8:	865e                	mv	a2,s7
    800042ba:	85d6                	mv	a1,s5
    800042bc:	854e                	mv	a0,s3
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	e64080e7          	jalr	-412(ra) # 80004122 <dirlookup>
    800042c6:	8a2a                	mv	s4,a0
    800042c8:	dd51                	beqz	a0,80004264 <namex+0x92>
    iunlockput(ip);
    800042ca:	854e                	mv	a0,s3
    800042cc:	00000097          	auipc	ra,0x0
    800042d0:	bd4080e7          	jalr	-1068(ra) # 80003ea0 <iunlockput>
    ip = next;
    800042d4:	89d2                	mv	s3,s4
  while(*path == '/')
    800042d6:	0004c783          	lbu	a5,0(s1)
    800042da:	05279763          	bne	a5,s2,80004328 <namex+0x156>
    path++;
    800042de:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042e0:	0004c783          	lbu	a5,0(s1)
    800042e4:	ff278de3          	beq	a5,s2,800042de <namex+0x10c>
  if(*path == 0)
    800042e8:	c79d                	beqz	a5,80004316 <namex+0x144>
    path++;
    800042ea:	85a6                	mv	a1,s1
  len = path - s;
    800042ec:	8a5e                	mv	s4,s7
    800042ee:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042f0:	01278963          	beq	a5,s2,80004302 <namex+0x130>
    800042f4:	dfbd                	beqz	a5,80004272 <namex+0xa0>
    path++;
    800042f6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042f8:	0004c783          	lbu	a5,0(s1)
    800042fc:	ff279ce3          	bne	a5,s2,800042f4 <namex+0x122>
    80004300:	bf8d                	j	80004272 <namex+0xa0>
    memmove(name, s, len);
    80004302:	2601                	sext.w	a2,a2
    80004304:	8556                	mv	a0,s5
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	a3a080e7          	jalr	-1478(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000430e:	9a56                	add	s4,s4,s5
    80004310:	000a0023          	sb	zero,0(s4)
    80004314:	bf9d                	j	8000428a <namex+0xb8>
  if(nameiparent){
    80004316:	f20b03e3          	beqz	s6,8000423c <namex+0x6a>
    iput(ip);
    8000431a:	854e                	mv	a0,s3
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	adc080e7          	jalr	-1316(ra) # 80003df8 <iput>
    return 0;
    80004324:	4981                	li	s3,0
    80004326:	bf19                	j	8000423c <namex+0x6a>
  if(*path == 0)
    80004328:	d7fd                	beqz	a5,80004316 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000432a:	0004c783          	lbu	a5,0(s1)
    8000432e:	85a6                	mv	a1,s1
    80004330:	b7d1                	j	800042f4 <namex+0x122>

0000000080004332 <dirlink>:
{
    80004332:	7139                	addi	sp,sp,-64
    80004334:	fc06                	sd	ra,56(sp)
    80004336:	f822                	sd	s0,48(sp)
    80004338:	f426                	sd	s1,40(sp)
    8000433a:	f04a                	sd	s2,32(sp)
    8000433c:	ec4e                	sd	s3,24(sp)
    8000433e:	e852                	sd	s4,16(sp)
    80004340:	0080                	addi	s0,sp,64
    80004342:	892a                	mv	s2,a0
    80004344:	8a2e                	mv	s4,a1
    80004346:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004348:	4601                	li	a2,0
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	dd8080e7          	jalr	-552(ra) # 80004122 <dirlookup>
    80004352:	e93d                	bnez	a0,800043c8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004354:	04c92483          	lw	s1,76(s2)
    80004358:	c49d                	beqz	s1,80004386 <dirlink+0x54>
    8000435a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000435c:	4741                	li	a4,16
    8000435e:	86a6                	mv	a3,s1
    80004360:	fc040613          	addi	a2,s0,-64
    80004364:	4581                	li	a1,0
    80004366:	854a                	mv	a0,s2
    80004368:	00000097          	auipc	ra,0x0
    8000436c:	b8a080e7          	jalr	-1142(ra) # 80003ef2 <readi>
    80004370:	47c1                	li	a5,16
    80004372:	06f51163          	bne	a0,a5,800043d4 <dirlink+0xa2>
    if(de.inum == 0)
    80004376:	fc045783          	lhu	a5,-64(s0)
    8000437a:	c791                	beqz	a5,80004386 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000437c:	24c1                	addiw	s1,s1,16
    8000437e:	04c92783          	lw	a5,76(s2)
    80004382:	fcf4ede3          	bltu	s1,a5,8000435c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004386:	4639                	li	a2,14
    80004388:	85d2                	mv	a1,s4
    8000438a:	fc240513          	addi	a0,s0,-62
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	a66080e7          	jalr	-1434(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004396:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000439a:	4741                	li	a4,16
    8000439c:	86a6                	mv	a3,s1
    8000439e:	fc040613          	addi	a2,s0,-64
    800043a2:	4581                	li	a1,0
    800043a4:	854a                	mv	a0,s2
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	c44080e7          	jalr	-956(ra) # 80003fea <writei>
    800043ae:	872a                	mv	a4,a0
    800043b0:	47c1                	li	a5,16
  return 0;
    800043b2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043b4:	02f71863          	bne	a4,a5,800043e4 <dirlink+0xb2>
}
    800043b8:	70e2                	ld	ra,56(sp)
    800043ba:	7442                	ld	s0,48(sp)
    800043bc:	74a2                	ld	s1,40(sp)
    800043be:	7902                	ld	s2,32(sp)
    800043c0:	69e2                	ld	s3,24(sp)
    800043c2:	6a42                	ld	s4,16(sp)
    800043c4:	6121                	addi	sp,sp,64
    800043c6:	8082                	ret
    iput(ip);
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	a30080e7          	jalr	-1488(ra) # 80003df8 <iput>
    return -1;
    800043d0:	557d                	li	a0,-1
    800043d2:	b7dd                	j	800043b8 <dirlink+0x86>
      panic("dirlink read");
    800043d4:	00004517          	auipc	a0,0x4
    800043d8:	27450513          	addi	a0,a0,628 # 80008648 <syscalls+0x1d8>
    800043dc:	ffffc097          	auipc	ra,0xffffc
    800043e0:	162080e7          	jalr	354(ra) # 8000053e <panic>
    panic("dirlink");
    800043e4:	00004517          	auipc	a0,0x4
    800043e8:	37450513          	addi	a0,a0,884 # 80008758 <syscalls+0x2e8>
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	152080e7          	jalr	338(ra) # 8000053e <panic>

00000000800043f4 <namei>:

struct inode*
namei(char *path)
{
    800043f4:	1101                	addi	sp,sp,-32
    800043f6:	ec06                	sd	ra,24(sp)
    800043f8:	e822                	sd	s0,16(sp)
    800043fa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043fc:	fe040613          	addi	a2,s0,-32
    80004400:	4581                	li	a1,0
    80004402:	00000097          	auipc	ra,0x0
    80004406:	dd0080e7          	jalr	-560(ra) # 800041d2 <namex>
}
    8000440a:	60e2                	ld	ra,24(sp)
    8000440c:	6442                	ld	s0,16(sp)
    8000440e:	6105                	addi	sp,sp,32
    80004410:	8082                	ret

0000000080004412 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004412:	1141                	addi	sp,sp,-16
    80004414:	e406                	sd	ra,8(sp)
    80004416:	e022                	sd	s0,0(sp)
    80004418:	0800                	addi	s0,sp,16
    8000441a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000441c:	4585                	li	a1,1
    8000441e:	00000097          	auipc	ra,0x0
    80004422:	db4080e7          	jalr	-588(ra) # 800041d2 <namex>
}
    80004426:	60a2                	ld	ra,8(sp)
    80004428:	6402                	ld	s0,0(sp)
    8000442a:	0141                	addi	sp,sp,16
    8000442c:	8082                	ret

000000008000442e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000442e:	1101                	addi	sp,sp,-32
    80004430:	ec06                	sd	ra,24(sp)
    80004432:	e822                	sd	s0,16(sp)
    80004434:	e426                	sd	s1,8(sp)
    80004436:	e04a                	sd	s2,0(sp)
    80004438:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000443a:	0001d917          	auipc	s2,0x1d
    8000443e:	7be90913          	addi	s2,s2,1982 # 80021bf8 <log>
    80004442:	01892583          	lw	a1,24(s2)
    80004446:	02892503          	lw	a0,40(s2)
    8000444a:	fffff097          	auipc	ra,0xfffff
    8000444e:	ff2080e7          	jalr	-14(ra) # 8000343c <bread>
    80004452:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004454:	02c92683          	lw	a3,44(s2)
    80004458:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000445a:	02d05763          	blez	a3,80004488 <write_head+0x5a>
    8000445e:	0001d797          	auipc	a5,0x1d
    80004462:	7ca78793          	addi	a5,a5,1994 # 80021c28 <log+0x30>
    80004466:	05c50713          	addi	a4,a0,92
    8000446a:	36fd                	addiw	a3,a3,-1
    8000446c:	1682                	slli	a3,a3,0x20
    8000446e:	9281                	srli	a3,a3,0x20
    80004470:	068a                	slli	a3,a3,0x2
    80004472:	0001d617          	auipc	a2,0x1d
    80004476:	7ba60613          	addi	a2,a2,1978 # 80021c2c <log+0x34>
    8000447a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000447c:	4390                	lw	a2,0(a5)
    8000447e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004480:	0791                	addi	a5,a5,4
    80004482:	0711                	addi	a4,a4,4
    80004484:	fed79ce3          	bne	a5,a3,8000447c <write_head+0x4e>
  }
  bwrite(buf);
    80004488:	8526                	mv	a0,s1
    8000448a:	fffff097          	auipc	ra,0xfffff
    8000448e:	0a4080e7          	jalr	164(ra) # 8000352e <bwrite>
  brelse(buf);
    80004492:	8526                	mv	a0,s1
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	0d8080e7          	jalr	216(ra) # 8000356c <brelse>
}
    8000449c:	60e2                	ld	ra,24(sp)
    8000449e:	6442                	ld	s0,16(sp)
    800044a0:	64a2                	ld	s1,8(sp)
    800044a2:	6902                	ld	s2,0(sp)
    800044a4:	6105                	addi	sp,sp,32
    800044a6:	8082                	ret

00000000800044a8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a8:	0001d797          	auipc	a5,0x1d
    800044ac:	77c7a783          	lw	a5,1916(a5) # 80021c24 <log+0x2c>
    800044b0:	0af05d63          	blez	a5,8000456a <install_trans+0xc2>
{
    800044b4:	7139                	addi	sp,sp,-64
    800044b6:	fc06                	sd	ra,56(sp)
    800044b8:	f822                	sd	s0,48(sp)
    800044ba:	f426                	sd	s1,40(sp)
    800044bc:	f04a                	sd	s2,32(sp)
    800044be:	ec4e                	sd	s3,24(sp)
    800044c0:	e852                	sd	s4,16(sp)
    800044c2:	e456                	sd	s5,8(sp)
    800044c4:	e05a                	sd	s6,0(sp)
    800044c6:	0080                	addi	s0,sp,64
    800044c8:	8b2a                	mv	s6,a0
    800044ca:	0001da97          	auipc	s5,0x1d
    800044ce:	75ea8a93          	addi	s5,s5,1886 # 80021c28 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044d4:	0001d997          	auipc	s3,0x1d
    800044d8:	72498993          	addi	s3,s3,1828 # 80021bf8 <log>
    800044dc:	a035                	j	80004508 <install_trans+0x60>
      bunpin(dbuf);
    800044de:	8526                	mv	a0,s1
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	166080e7          	jalr	358(ra) # 80003646 <bunpin>
    brelse(lbuf);
    800044e8:	854a                	mv	a0,s2
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	082080e7          	jalr	130(ra) # 8000356c <brelse>
    brelse(dbuf);
    800044f2:	8526                	mv	a0,s1
    800044f4:	fffff097          	auipc	ra,0xfffff
    800044f8:	078080e7          	jalr	120(ra) # 8000356c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044fc:	2a05                	addiw	s4,s4,1
    800044fe:	0a91                	addi	s5,s5,4
    80004500:	02c9a783          	lw	a5,44(s3)
    80004504:	04fa5963          	bge	s4,a5,80004556 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004508:	0189a583          	lw	a1,24(s3)
    8000450c:	014585bb          	addw	a1,a1,s4
    80004510:	2585                	addiw	a1,a1,1
    80004512:	0289a503          	lw	a0,40(s3)
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	f26080e7          	jalr	-218(ra) # 8000343c <bread>
    8000451e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004520:	000aa583          	lw	a1,0(s5)
    80004524:	0289a503          	lw	a0,40(s3)
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	f14080e7          	jalr	-236(ra) # 8000343c <bread>
    80004530:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004532:	40000613          	li	a2,1024
    80004536:	05890593          	addi	a1,s2,88
    8000453a:	05850513          	addi	a0,a0,88
    8000453e:	ffffd097          	auipc	ra,0xffffd
    80004542:	802080e7          	jalr	-2046(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004546:	8526                	mv	a0,s1
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	fe6080e7          	jalr	-26(ra) # 8000352e <bwrite>
    if(recovering == 0)
    80004550:	f80b1ce3          	bnez	s6,800044e8 <install_trans+0x40>
    80004554:	b769                	j	800044de <install_trans+0x36>
}
    80004556:	70e2                	ld	ra,56(sp)
    80004558:	7442                	ld	s0,48(sp)
    8000455a:	74a2                	ld	s1,40(sp)
    8000455c:	7902                	ld	s2,32(sp)
    8000455e:	69e2                	ld	s3,24(sp)
    80004560:	6a42                	ld	s4,16(sp)
    80004562:	6aa2                	ld	s5,8(sp)
    80004564:	6b02                	ld	s6,0(sp)
    80004566:	6121                	addi	sp,sp,64
    80004568:	8082                	ret
    8000456a:	8082                	ret

000000008000456c <initlog>:
{
    8000456c:	7179                	addi	sp,sp,-48
    8000456e:	f406                	sd	ra,40(sp)
    80004570:	f022                	sd	s0,32(sp)
    80004572:	ec26                	sd	s1,24(sp)
    80004574:	e84a                	sd	s2,16(sp)
    80004576:	e44e                	sd	s3,8(sp)
    80004578:	1800                	addi	s0,sp,48
    8000457a:	892a                	mv	s2,a0
    8000457c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000457e:	0001d497          	auipc	s1,0x1d
    80004582:	67a48493          	addi	s1,s1,1658 # 80021bf8 <log>
    80004586:	00004597          	auipc	a1,0x4
    8000458a:	0d258593          	addi	a1,a1,210 # 80008658 <syscalls+0x1e8>
    8000458e:	8526                	mv	a0,s1
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	5c4080e7          	jalr	1476(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004598:	0149a583          	lw	a1,20(s3)
    8000459c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000459e:	0109a783          	lw	a5,16(s3)
    800045a2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045a4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045a8:	854a                	mv	a0,s2
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	e92080e7          	jalr	-366(ra) # 8000343c <bread>
  log.lh.n = lh->n;
    800045b2:	4d3c                	lw	a5,88(a0)
    800045b4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045b6:	02f05563          	blez	a5,800045e0 <initlog+0x74>
    800045ba:	05c50713          	addi	a4,a0,92
    800045be:	0001d697          	auipc	a3,0x1d
    800045c2:	66a68693          	addi	a3,a3,1642 # 80021c28 <log+0x30>
    800045c6:	37fd                	addiw	a5,a5,-1
    800045c8:	1782                	slli	a5,a5,0x20
    800045ca:	9381                	srli	a5,a5,0x20
    800045cc:	078a                	slli	a5,a5,0x2
    800045ce:	06050613          	addi	a2,a0,96
    800045d2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800045d4:	4310                	lw	a2,0(a4)
    800045d6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800045d8:	0711                	addi	a4,a4,4
    800045da:	0691                	addi	a3,a3,4
    800045dc:	fef71ce3          	bne	a4,a5,800045d4 <initlog+0x68>
  brelse(buf);
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	f8c080e7          	jalr	-116(ra) # 8000356c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045e8:	4505                	li	a0,1
    800045ea:	00000097          	auipc	ra,0x0
    800045ee:	ebe080e7          	jalr	-322(ra) # 800044a8 <install_trans>
  log.lh.n = 0;
    800045f2:	0001d797          	auipc	a5,0x1d
    800045f6:	6207a923          	sw	zero,1586(a5) # 80021c24 <log+0x2c>
  write_head(); // clear the log
    800045fa:	00000097          	auipc	ra,0x0
    800045fe:	e34080e7          	jalr	-460(ra) # 8000442e <write_head>
}
    80004602:	70a2                	ld	ra,40(sp)
    80004604:	7402                	ld	s0,32(sp)
    80004606:	64e2                	ld	s1,24(sp)
    80004608:	6942                	ld	s2,16(sp)
    8000460a:	69a2                	ld	s3,8(sp)
    8000460c:	6145                	addi	sp,sp,48
    8000460e:	8082                	ret

0000000080004610 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004610:	1101                	addi	sp,sp,-32
    80004612:	ec06                	sd	ra,24(sp)
    80004614:	e822                	sd	s0,16(sp)
    80004616:	e426                	sd	s1,8(sp)
    80004618:	e04a                	sd	s2,0(sp)
    8000461a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000461c:	0001d517          	auipc	a0,0x1d
    80004620:	5dc50513          	addi	a0,a0,1500 # 80021bf8 <log>
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	5c0080e7          	jalr	1472(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000462c:	0001d497          	auipc	s1,0x1d
    80004630:	5cc48493          	addi	s1,s1,1484 # 80021bf8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004634:	4979                	li	s2,30
    80004636:	a039                	j	80004644 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004638:	85a6                	mv	a1,s1
    8000463a:	8526                	mv	a0,s1
    8000463c:	ffffe097          	auipc	ra,0xffffe
    80004640:	9e4080e7          	jalr	-1564(ra) # 80002020 <sleep>
    if(log.committing){
    80004644:	50dc                	lw	a5,36(s1)
    80004646:	fbed                	bnez	a5,80004638 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004648:	509c                	lw	a5,32(s1)
    8000464a:	0017871b          	addiw	a4,a5,1
    8000464e:	0007069b          	sext.w	a3,a4
    80004652:	0027179b          	slliw	a5,a4,0x2
    80004656:	9fb9                	addw	a5,a5,a4
    80004658:	0017979b          	slliw	a5,a5,0x1
    8000465c:	54d8                	lw	a4,44(s1)
    8000465e:	9fb9                	addw	a5,a5,a4
    80004660:	00f95963          	bge	s2,a5,80004672 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004664:	85a6                	mv	a1,s1
    80004666:	8526                	mv	a0,s1
    80004668:	ffffe097          	auipc	ra,0xffffe
    8000466c:	9b8080e7          	jalr	-1608(ra) # 80002020 <sleep>
    80004670:	bfd1                	j	80004644 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004672:	0001d517          	auipc	a0,0x1d
    80004676:	58650513          	addi	a0,a0,1414 # 80021bf8 <log>
    8000467a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	61c080e7          	jalr	1564(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004684:	60e2                	ld	ra,24(sp)
    80004686:	6442                	ld	s0,16(sp)
    80004688:	64a2                	ld	s1,8(sp)
    8000468a:	6902                	ld	s2,0(sp)
    8000468c:	6105                	addi	sp,sp,32
    8000468e:	8082                	ret

0000000080004690 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004690:	7139                	addi	sp,sp,-64
    80004692:	fc06                	sd	ra,56(sp)
    80004694:	f822                	sd	s0,48(sp)
    80004696:	f426                	sd	s1,40(sp)
    80004698:	f04a                	sd	s2,32(sp)
    8000469a:	ec4e                	sd	s3,24(sp)
    8000469c:	e852                	sd	s4,16(sp)
    8000469e:	e456                	sd	s5,8(sp)
    800046a0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046a2:	0001d497          	auipc	s1,0x1d
    800046a6:	55648493          	addi	s1,s1,1366 # 80021bf8 <log>
    800046aa:	8526                	mv	a0,s1
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800046b4:	509c                	lw	a5,32(s1)
    800046b6:	37fd                	addiw	a5,a5,-1
    800046b8:	0007891b          	sext.w	s2,a5
    800046bc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046be:	50dc                	lw	a5,36(s1)
    800046c0:	efb9                	bnez	a5,8000471e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046c2:	06091663          	bnez	s2,8000472e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800046c6:	0001d497          	auipc	s1,0x1d
    800046ca:	53248493          	addi	s1,s1,1330 # 80021bf8 <log>
    800046ce:	4785                	li	a5,1
    800046d0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046d2:	8526                	mv	a0,s1
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	5c4080e7          	jalr	1476(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046dc:	54dc                	lw	a5,44(s1)
    800046de:	06f04763          	bgtz	a5,8000474c <end_op+0xbc>
    acquire(&log.lock);
    800046e2:	0001d497          	auipc	s1,0x1d
    800046e6:	51648493          	addi	s1,s1,1302 # 80021bf8 <log>
    800046ea:	8526                	mv	a0,s1
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	4f8080e7          	jalr	1272(ra) # 80000be4 <acquire>
    log.committing = 0;
    800046f4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046f8:	8526                	mv	a0,s1
    800046fa:	ffffe097          	auipc	ra,0xffffe
    800046fe:	ca0080e7          	jalr	-864(ra) # 8000239a <wakeup>
    release(&log.lock);
    80004702:	8526                	mv	a0,s1
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	594080e7          	jalr	1428(ra) # 80000c98 <release>
}
    8000470c:	70e2                	ld	ra,56(sp)
    8000470e:	7442                	ld	s0,48(sp)
    80004710:	74a2                	ld	s1,40(sp)
    80004712:	7902                	ld	s2,32(sp)
    80004714:	69e2                	ld	s3,24(sp)
    80004716:	6a42                	ld	s4,16(sp)
    80004718:	6aa2                	ld	s5,8(sp)
    8000471a:	6121                	addi	sp,sp,64
    8000471c:	8082                	ret
    panic("log.committing");
    8000471e:	00004517          	auipc	a0,0x4
    80004722:	f4250513          	addi	a0,a0,-190 # 80008660 <syscalls+0x1f0>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	e18080e7          	jalr	-488(ra) # 8000053e <panic>
    wakeup(&log);
    8000472e:	0001d497          	auipc	s1,0x1d
    80004732:	4ca48493          	addi	s1,s1,1226 # 80021bf8 <log>
    80004736:	8526                	mv	a0,s1
    80004738:	ffffe097          	auipc	ra,0xffffe
    8000473c:	c62080e7          	jalr	-926(ra) # 8000239a <wakeup>
  release(&log.lock);
    80004740:	8526                	mv	a0,s1
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	556080e7          	jalr	1366(ra) # 80000c98 <release>
  if(do_commit){
    8000474a:	b7c9                	j	8000470c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000474c:	0001da97          	auipc	s5,0x1d
    80004750:	4dca8a93          	addi	s5,s5,1244 # 80021c28 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004754:	0001da17          	auipc	s4,0x1d
    80004758:	4a4a0a13          	addi	s4,s4,1188 # 80021bf8 <log>
    8000475c:	018a2583          	lw	a1,24(s4)
    80004760:	012585bb          	addw	a1,a1,s2
    80004764:	2585                	addiw	a1,a1,1
    80004766:	028a2503          	lw	a0,40(s4)
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	cd2080e7          	jalr	-814(ra) # 8000343c <bread>
    80004772:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004774:	000aa583          	lw	a1,0(s5)
    80004778:	028a2503          	lw	a0,40(s4)
    8000477c:	fffff097          	auipc	ra,0xfffff
    80004780:	cc0080e7          	jalr	-832(ra) # 8000343c <bread>
    80004784:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004786:	40000613          	li	a2,1024
    8000478a:	05850593          	addi	a1,a0,88
    8000478e:	05848513          	addi	a0,s1,88
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	5ae080e7          	jalr	1454(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000479a:	8526                	mv	a0,s1
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	d92080e7          	jalr	-622(ra) # 8000352e <bwrite>
    brelse(from);
    800047a4:	854e                	mv	a0,s3
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	dc6080e7          	jalr	-570(ra) # 8000356c <brelse>
    brelse(to);
    800047ae:	8526                	mv	a0,s1
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	dbc080e7          	jalr	-580(ra) # 8000356c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047b8:	2905                	addiw	s2,s2,1
    800047ba:	0a91                	addi	s5,s5,4
    800047bc:	02ca2783          	lw	a5,44(s4)
    800047c0:	f8f94ee3          	blt	s2,a5,8000475c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	c6a080e7          	jalr	-918(ra) # 8000442e <write_head>
    install_trans(0); // Now install writes to home locations
    800047cc:	4501                	li	a0,0
    800047ce:	00000097          	auipc	ra,0x0
    800047d2:	cda080e7          	jalr	-806(ra) # 800044a8 <install_trans>
    log.lh.n = 0;
    800047d6:	0001d797          	auipc	a5,0x1d
    800047da:	4407a723          	sw	zero,1102(a5) # 80021c24 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	c50080e7          	jalr	-944(ra) # 8000442e <write_head>
    800047e6:	bdf5                	j	800046e2 <end_op+0x52>

00000000800047e8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047e8:	1101                	addi	sp,sp,-32
    800047ea:	ec06                	sd	ra,24(sp)
    800047ec:	e822                	sd	s0,16(sp)
    800047ee:	e426                	sd	s1,8(sp)
    800047f0:	e04a                	sd	s2,0(sp)
    800047f2:	1000                	addi	s0,sp,32
    800047f4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047f6:	0001d917          	auipc	s2,0x1d
    800047fa:	40290913          	addi	s2,s2,1026 # 80021bf8 <log>
    800047fe:	854a                	mv	a0,s2
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	3e4080e7          	jalr	996(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004808:	02c92603          	lw	a2,44(s2)
    8000480c:	47f5                	li	a5,29
    8000480e:	06c7c563          	blt	a5,a2,80004878 <log_write+0x90>
    80004812:	0001d797          	auipc	a5,0x1d
    80004816:	4027a783          	lw	a5,1026(a5) # 80021c14 <log+0x1c>
    8000481a:	37fd                	addiw	a5,a5,-1
    8000481c:	04f65e63          	bge	a2,a5,80004878 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004820:	0001d797          	auipc	a5,0x1d
    80004824:	3f87a783          	lw	a5,1016(a5) # 80021c18 <log+0x20>
    80004828:	06f05063          	blez	a5,80004888 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000482c:	4781                	li	a5,0
    8000482e:	06c05563          	blez	a2,80004898 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004832:	44cc                	lw	a1,12(s1)
    80004834:	0001d717          	auipc	a4,0x1d
    80004838:	3f470713          	addi	a4,a4,1012 # 80021c28 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000483c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000483e:	4314                	lw	a3,0(a4)
    80004840:	04b68c63          	beq	a3,a1,80004898 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004844:	2785                	addiw	a5,a5,1
    80004846:	0711                	addi	a4,a4,4
    80004848:	fef61be3          	bne	a2,a5,8000483e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000484c:	0621                	addi	a2,a2,8
    8000484e:	060a                	slli	a2,a2,0x2
    80004850:	0001d797          	auipc	a5,0x1d
    80004854:	3a878793          	addi	a5,a5,936 # 80021bf8 <log>
    80004858:	963e                	add	a2,a2,a5
    8000485a:	44dc                	lw	a5,12(s1)
    8000485c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000485e:	8526                	mv	a0,s1
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	daa080e7          	jalr	-598(ra) # 8000360a <bpin>
    log.lh.n++;
    80004868:	0001d717          	auipc	a4,0x1d
    8000486c:	39070713          	addi	a4,a4,912 # 80021bf8 <log>
    80004870:	575c                	lw	a5,44(a4)
    80004872:	2785                	addiw	a5,a5,1
    80004874:	d75c                	sw	a5,44(a4)
    80004876:	a835                	j	800048b2 <log_write+0xca>
    panic("too big a transaction");
    80004878:	00004517          	auipc	a0,0x4
    8000487c:	df850513          	addi	a0,a0,-520 # 80008670 <syscalls+0x200>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	cbe080e7          	jalr	-834(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004888:	00004517          	auipc	a0,0x4
    8000488c:	e0050513          	addi	a0,a0,-512 # 80008688 <syscalls+0x218>
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	cae080e7          	jalr	-850(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004898:	00878713          	addi	a4,a5,8
    8000489c:	00271693          	slli	a3,a4,0x2
    800048a0:	0001d717          	auipc	a4,0x1d
    800048a4:	35870713          	addi	a4,a4,856 # 80021bf8 <log>
    800048a8:	9736                	add	a4,a4,a3
    800048aa:	44d4                	lw	a3,12(s1)
    800048ac:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048ae:	faf608e3          	beq	a2,a5,8000485e <log_write+0x76>
  }
  release(&log.lock);
    800048b2:	0001d517          	auipc	a0,0x1d
    800048b6:	34650513          	addi	a0,a0,838 # 80021bf8 <log>
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	3de080e7          	jalr	990(ra) # 80000c98 <release>
}
    800048c2:	60e2                	ld	ra,24(sp)
    800048c4:	6442                	ld	s0,16(sp)
    800048c6:	64a2                	ld	s1,8(sp)
    800048c8:	6902                	ld	s2,0(sp)
    800048ca:	6105                	addi	sp,sp,32
    800048cc:	8082                	ret

00000000800048ce <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048ce:	1101                	addi	sp,sp,-32
    800048d0:	ec06                	sd	ra,24(sp)
    800048d2:	e822                	sd	s0,16(sp)
    800048d4:	e426                	sd	s1,8(sp)
    800048d6:	e04a                	sd	s2,0(sp)
    800048d8:	1000                	addi	s0,sp,32
    800048da:	84aa                	mv	s1,a0
    800048dc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048de:	00004597          	auipc	a1,0x4
    800048e2:	dca58593          	addi	a1,a1,-566 # 800086a8 <syscalls+0x238>
    800048e6:	0521                	addi	a0,a0,8
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	26c080e7          	jalr	620(ra) # 80000b54 <initlock>
  lk->name = name;
    800048f0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048f4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048f8:	0204a423          	sw	zero,40(s1)
}
    800048fc:	60e2                	ld	ra,24(sp)
    800048fe:	6442                	ld	s0,16(sp)
    80004900:	64a2                	ld	s1,8(sp)
    80004902:	6902                	ld	s2,0(sp)
    80004904:	6105                	addi	sp,sp,32
    80004906:	8082                	ret

0000000080004908 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004908:	1101                	addi	sp,sp,-32
    8000490a:	ec06                	sd	ra,24(sp)
    8000490c:	e822                	sd	s0,16(sp)
    8000490e:	e426                	sd	s1,8(sp)
    80004910:	e04a                	sd	s2,0(sp)
    80004912:	1000                	addi	s0,sp,32
    80004914:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004916:	00850913          	addi	s2,a0,8
    8000491a:	854a                	mv	a0,s2
    8000491c:	ffffc097          	auipc	ra,0xffffc
    80004920:	2c8080e7          	jalr	712(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004924:	409c                	lw	a5,0(s1)
    80004926:	cb89                	beqz	a5,80004938 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004928:	85ca                	mv	a1,s2
    8000492a:	8526                	mv	a0,s1
    8000492c:	ffffd097          	auipc	ra,0xffffd
    80004930:	6f4080e7          	jalr	1780(ra) # 80002020 <sleep>
  while (lk->locked) {
    80004934:	409c                	lw	a5,0(s1)
    80004936:	fbed                	bnez	a5,80004928 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004938:	4785                	li	a5,1
    8000493a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000493c:	ffffd097          	auipc	ra,0xffffd
    80004940:	fca080e7          	jalr	-54(ra) # 80001906 <myproc>
    80004944:	591c                	lw	a5,48(a0)
    80004946:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004948:	854a                	mv	a0,s2
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	34e080e7          	jalr	846(ra) # 80000c98 <release>
}
    80004952:	60e2                	ld	ra,24(sp)
    80004954:	6442                	ld	s0,16(sp)
    80004956:	64a2                	ld	s1,8(sp)
    80004958:	6902                	ld	s2,0(sp)
    8000495a:	6105                	addi	sp,sp,32
    8000495c:	8082                	ret

000000008000495e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000495e:	1101                	addi	sp,sp,-32
    80004960:	ec06                	sd	ra,24(sp)
    80004962:	e822                	sd	s0,16(sp)
    80004964:	e426                	sd	s1,8(sp)
    80004966:	e04a                	sd	s2,0(sp)
    80004968:	1000                	addi	s0,sp,32
    8000496a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000496c:	00850913          	addi	s2,a0,8
    80004970:	854a                	mv	a0,s2
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	272080e7          	jalr	626(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000497a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000497e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004982:	8526                	mv	a0,s1
    80004984:	ffffe097          	auipc	ra,0xffffe
    80004988:	a16080e7          	jalr	-1514(ra) # 8000239a <wakeup>
  release(&lk->lk);
    8000498c:	854a                	mv	a0,s2
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	30a080e7          	jalr	778(ra) # 80000c98 <release>
}
    80004996:	60e2                	ld	ra,24(sp)
    80004998:	6442                	ld	s0,16(sp)
    8000499a:	64a2                	ld	s1,8(sp)
    8000499c:	6902                	ld	s2,0(sp)
    8000499e:	6105                	addi	sp,sp,32
    800049a0:	8082                	ret

00000000800049a2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049a2:	7179                	addi	sp,sp,-48
    800049a4:	f406                	sd	ra,40(sp)
    800049a6:	f022                	sd	s0,32(sp)
    800049a8:	ec26                	sd	s1,24(sp)
    800049aa:	e84a                	sd	s2,16(sp)
    800049ac:	e44e                	sd	s3,8(sp)
    800049ae:	1800                	addi	s0,sp,48
    800049b0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049b2:	00850913          	addi	s2,a0,8
    800049b6:	854a                	mv	a0,s2
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	22c080e7          	jalr	556(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049c0:	409c                	lw	a5,0(s1)
    800049c2:	ef99                	bnez	a5,800049e0 <holdingsleep+0x3e>
    800049c4:	4481                	li	s1,0
  release(&lk->lk);
    800049c6:	854a                	mv	a0,s2
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	2d0080e7          	jalr	720(ra) # 80000c98 <release>
  return r;
}
    800049d0:	8526                	mv	a0,s1
    800049d2:	70a2                	ld	ra,40(sp)
    800049d4:	7402                	ld	s0,32(sp)
    800049d6:	64e2                	ld	s1,24(sp)
    800049d8:	6942                	ld	s2,16(sp)
    800049da:	69a2                	ld	s3,8(sp)
    800049dc:	6145                	addi	sp,sp,48
    800049de:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049e0:	0284a983          	lw	s3,40(s1)
    800049e4:	ffffd097          	auipc	ra,0xffffd
    800049e8:	f22080e7          	jalr	-222(ra) # 80001906 <myproc>
    800049ec:	5904                	lw	s1,48(a0)
    800049ee:	413484b3          	sub	s1,s1,s3
    800049f2:	0014b493          	seqz	s1,s1
    800049f6:	bfc1                	j	800049c6 <holdingsleep+0x24>

00000000800049f8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049f8:	1141                	addi	sp,sp,-16
    800049fa:	e406                	sd	ra,8(sp)
    800049fc:	e022                	sd	s0,0(sp)
    800049fe:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a00:	00004597          	auipc	a1,0x4
    80004a04:	cb858593          	addi	a1,a1,-840 # 800086b8 <syscalls+0x248>
    80004a08:	0001d517          	auipc	a0,0x1d
    80004a0c:	33850513          	addi	a0,a0,824 # 80021d40 <ftable>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	144080e7          	jalr	324(ra) # 80000b54 <initlock>
}
    80004a18:	60a2                	ld	ra,8(sp)
    80004a1a:	6402                	ld	s0,0(sp)
    80004a1c:	0141                	addi	sp,sp,16
    80004a1e:	8082                	ret

0000000080004a20 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a20:	1101                	addi	sp,sp,-32
    80004a22:	ec06                	sd	ra,24(sp)
    80004a24:	e822                	sd	s0,16(sp)
    80004a26:	e426                	sd	s1,8(sp)
    80004a28:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a2a:	0001d517          	auipc	a0,0x1d
    80004a2e:	31650513          	addi	a0,a0,790 # 80021d40 <ftable>
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	1b2080e7          	jalr	434(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a3a:	0001d497          	auipc	s1,0x1d
    80004a3e:	31e48493          	addi	s1,s1,798 # 80021d58 <ftable+0x18>
    80004a42:	0001e717          	auipc	a4,0x1e
    80004a46:	2b670713          	addi	a4,a4,694 # 80022cf8 <ftable+0xfb8>
    if(f->ref == 0){
    80004a4a:	40dc                	lw	a5,4(s1)
    80004a4c:	cf99                	beqz	a5,80004a6a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a4e:	02848493          	addi	s1,s1,40
    80004a52:	fee49ce3          	bne	s1,a4,80004a4a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a56:	0001d517          	auipc	a0,0x1d
    80004a5a:	2ea50513          	addi	a0,a0,746 # 80021d40 <ftable>
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
  return 0;
    80004a66:	4481                	li	s1,0
    80004a68:	a819                	j	80004a7e <filealloc+0x5e>
      f->ref = 1;
    80004a6a:	4785                	li	a5,1
    80004a6c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a6e:	0001d517          	auipc	a0,0x1d
    80004a72:	2d250513          	addi	a0,a0,722 # 80021d40 <ftable>
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	222080e7          	jalr	546(ra) # 80000c98 <release>
}
    80004a7e:	8526                	mv	a0,s1
    80004a80:	60e2                	ld	ra,24(sp)
    80004a82:	6442                	ld	s0,16(sp)
    80004a84:	64a2                	ld	s1,8(sp)
    80004a86:	6105                	addi	sp,sp,32
    80004a88:	8082                	ret

0000000080004a8a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a8a:	1101                	addi	sp,sp,-32
    80004a8c:	ec06                	sd	ra,24(sp)
    80004a8e:	e822                	sd	s0,16(sp)
    80004a90:	e426                	sd	s1,8(sp)
    80004a92:	1000                	addi	s0,sp,32
    80004a94:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a96:	0001d517          	auipc	a0,0x1d
    80004a9a:	2aa50513          	addi	a0,a0,682 # 80021d40 <ftable>
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	146080e7          	jalr	326(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004aa6:	40dc                	lw	a5,4(s1)
    80004aa8:	02f05263          	blez	a5,80004acc <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004aac:	2785                	addiw	a5,a5,1
    80004aae:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ab0:	0001d517          	auipc	a0,0x1d
    80004ab4:	29050513          	addi	a0,a0,656 # 80021d40 <ftable>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	1e0080e7          	jalr	480(ra) # 80000c98 <release>
  return f;
}
    80004ac0:	8526                	mv	a0,s1
    80004ac2:	60e2                	ld	ra,24(sp)
    80004ac4:	6442                	ld	s0,16(sp)
    80004ac6:	64a2                	ld	s1,8(sp)
    80004ac8:	6105                	addi	sp,sp,32
    80004aca:	8082                	ret
    panic("filedup");
    80004acc:	00004517          	auipc	a0,0x4
    80004ad0:	bf450513          	addi	a0,a0,-1036 # 800086c0 <syscalls+0x250>
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	a6a080e7          	jalr	-1430(ra) # 8000053e <panic>

0000000080004adc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004adc:	7139                	addi	sp,sp,-64
    80004ade:	fc06                	sd	ra,56(sp)
    80004ae0:	f822                	sd	s0,48(sp)
    80004ae2:	f426                	sd	s1,40(sp)
    80004ae4:	f04a                	sd	s2,32(sp)
    80004ae6:	ec4e                	sd	s3,24(sp)
    80004ae8:	e852                	sd	s4,16(sp)
    80004aea:	e456                	sd	s5,8(sp)
    80004aec:	0080                	addi	s0,sp,64
    80004aee:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004af0:	0001d517          	auipc	a0,0x1d
    80004af4:	25050513          	addi	a0,a0,592 # 80021d40 <ftable>
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	0ec080e7          	jalr	236(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b00:	40dc                	lw	a5,4(s1)
    80004b02:	06f05163          	blez	a5,80004b64 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b06:	37fd                	addiw	a5,a5,-1
    80004b08:	0007871b          	sext.w	a4,a5
    80004b0c:	c0dc                	sw	a5,4(s1)
    80004b0e:	06e04363          	bgtz	a4,80004b74 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b12:	0004a903          	lw	s2,0(s1)
    80004b16:	0094ca83          	lbu	s5,9(s1)
    80004b1a:	0104ba03          	ld	s4,16(s1)
    80004b1e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b22:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b26:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b2a:	0001d517          	auipc	a0,0x1d
    80004b2e:	21650513          	addi	a0,a0,534 # 80021d40 <ftable>
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	166080e7          	jalr	358(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b3a:	4785                	li	a5,1
    80004b3c:	04f90d63          	beq	s2,a5,80004b96 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b40:	3979                	addiw	s2,s2,-2
    80004b42:	4785                	li	a5,1
    80004b44:	0527e063          	bltu	a5,s2,80004b84 <fileclose+0xa8>
    begin_op();
    80004b48:	00000097          	auipc	ra,0x0
    80004b4c:	ac8080e7          	jalr	-1336(ra) # 80004610 <begin_op>
    iput(ff.ip);
    80004b50:	854e                	mv	a0,s3
    80004b52:	fffff097          	auipc	ra,0xfffff
    80004b56:	2a6080e7          	jalr	678(ra) # 80003df8 <iput>
    end_op();
    80004b5a:	00000097          	auipc	ra,0x0
    80004b5e:	b36080e7          	jalr	-1226(ra) # 80004690 <end_op>
    80004b62:	a00d                	j	80004b84 <fileclose+0xa8>
    panic("fileclose");
    80004b64:	00004517          	auipc	a0,0x4
    80004b68:	b6450513          	addi	a0,a0,-1180 # 800086c8 <syscalls+0x258>
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	9d2080e7          	jalr	-1582(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b74:	0001d517          	auipc	a0,0x1d
    80004b78:	1cc50513          	addi	a0,a0,460 # 80021d40 <ftable>
    80004b7c:	ffffc097          	auipc	ra,0xffffc
    80004b80:	11c080e7          	jalr	284(ra) # 80000c98 <release>
  }
}
    80004b84:	70e2                	ld	ra,56(sp)
    80004b86:	7442                	ld	s0,48(sp)
    80004b88:	74a2                	ld	s1,40(sp)
    80004b8a:	7902                	ld	s2,32(sp)
    80004b8c:	69e2                	ld	s3,24(sp)
    80004b8e:	6a42                	ld	s4,16(sp)
    80004b90:	6aa2                	ld	s5,8(sp)
    80004b92:	6121                	addi	sp,sp,64
    80004b94:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b96:	85d6                	mv	a1,s5
    80004b98:	8552                	mv	a0,s4
    80004b9a:	00000097          	auipc	ra,0x0
    80004b9e:	34c080e7          	jalr	844(ra) # 80004ee6 <pipeclose>
    80004ba2:	b7cd                	j	80004b84 <fileclose+0xa8>

0000000080004ba4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ba4:	715d                	addi	sp,sp,-80
    80004ba6:	e486                	sd	ra,72(sp)
    80004ba8:	e0a2                	sd	s0,64(sp)
    80004baa:	fc26                	sd	s1,56(sp)
    80004bac:	f84a                	sd	s2,48(sp)
    80004bae:	f44e                	sd	s3,40(sp)
    80004bb0:	0880                	addi	s0,sp,80
    80004bb2:	84aa                	mv	s1,a0
    80004bb4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	d50080e7          	jalr	-688(ra) # 80001906 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bbe:	409c                	lw	a5,0(s1)
    80004bc0:	37f9                	addiw	a5,a5,-2
    80004bc2:	4705                	li	a4,1
    80004bc4:	04f76763          	bltu	a4,a5,80004c12 <filestat+0x6e>
    80004bc8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bca:	6c88                	ld	a0,24(s1)
    80004bcc:	fffff097          	auipc	ra,0xfffff
    80004bd0:	072080e7          	jalr	114(ra) # 80003c3e <ilock>
    stati(f->ip, &st);
    80004bd4:	fb840593          	addi	a1,s0,-72
    80004bd8:	6c88                	ld	a0,24(s1)
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	2ee080e7          	jalr	750(ra) # 80003ec8 <stati>
    iunlock(f->ip);
    80004be2:	6c88                	ld	a0,24(s1)
    80004be4:	fffff097          	auipc	ra,0xfffff
    80004be8:	11c080e7          	jalr	284(ra) # 80003d00 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bec:	46e1                	li	a3,24
    80004bee:	fb840613          	addi	a2,s0,-72
    80004bf2:	85ce                	mv	a1,s3
    80004bf4:	07093503          	ld	a0,112(s2)
    80004bf8:	ffffd097          	auipc	ra,0xffffd
    80004bfc:	a7a080e7          	jalr	-1414(ra) # 80001672 <copyout>
    80004c00:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c04:	60a6                	ld	ra,72(sp)
    80004c06:	6406                	ld	s0,64(sp)
    80004c08:	74e2                	ld	s1,56(sp)
    80004c0a:	7942                	ld	s2,48(sp)
    80004c0c:	79a2                	ld	s3,40(sp)
    80004c0e:	6161                	addi	sp,sp,80
    80004c10:	8082                	ret
  return -1;
    80004c12:	557d                	li	a0,-1
    80004c14:	bfc5                	j	80004c04 <filestat+0x60>

0000000080004c16 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c16:	7179                	addi	sp,sp,-48
    80004c18:	f406                	sd	ra,40(sp)
    80004c1a:	f022                	sd	s0,32(sp)
    80004c1c:	ec26                	sd	s1,24(sp)
    80004c1e:	e84a                	sd	s2,16(sp)
    80004c20:	e44e                	sd	s3,8(sp)
    80004c22:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c24:	00854783          	lbu	a5,8(a0)
    80004c28:	c3d5                	beqz	a5,80004ccc <fileread+0xb6>
    80004c2a:	84aa                	mv	s1,a0
    80004c2c:	89ae                	mv	s3,a1
    80004c2e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c30:	411c                	lw	a5,0(a0)
    80004c32:	4705                	li	a4,1
    80004c34:	04e78963          	beq	a5,a4,80004c86 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c38:	470d                	li	a4,3
    80004c3a:	04e78d63          	beq	a5,a4,80004c94 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c3e:	4709                	li	a4,2
    80004c40:	06e79e63          	bne	a5,a4,80004cbc <fileread+0xa6>
    ilock(f->ip);
    80004c44:	6d08                	ld	a0,24(a0)
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	ff8080e7          	jalr	-8(ra) # 80003c3e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c4e:	874a                	mv	a4,s2
    80004c50:	5094                	lw	a3,32(s1)
    80004c52:	864e                	mv	a2,s3
    80004c54:	4585                	li	a1,1
    80004c56:	6c88                	ld	a0,24(s1)
    80004c58:	fffff097          	auipc	ra,0xfffff
    80004c5c:	29a080e7          	jalr	666(ra) # 80003ef2 <readi>
    80004c60:	892a                	mv	s2,a0
    80004c62:	00a05563          	blez	a0,80004c6c <fileread+0x56>
      f->off += r;
    80004c66:	509c                	lw	a5,32(s1)
    80004c68:	9fa9                	addw	a5,a5,a0
    80004c6a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c6c:	6c88                	ld	a0,24(s1)
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	092080e7          	jalr	146(ra) # 80003d00 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c76:	854a                	mv	a0,s2
    80004c78:	70a2                	ld	ra,40(sp)
    80004c7a:	7402                	ld	s0,32(sp)
    80004c7c:	64e2                	ld	s1,24(sp)
    80004c7e:	6942                	ld	s2,16(sp)
    80004c80:	69a2                	ld	s3,8(sp)
    80004c82:	6145                	addi	sp,sp,48
    80004c84:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c86:	6908                	ld	a0,16(a0)
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	3c8080e7          	jalr	968(ra) # 80005050 <piperead>
    80004c90:	892a                	mv	s2,a0
    80004c92:	b7d5                	j	80004c76 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c94:	02451783          	lh	a5,36(a0)
    80004c98:	03079693          	slli	a3,a5,0x30
    80004c9c:	92c1                	srli	a3,a3,0x30
    80004c9e:	4725                	li	a4,9
    80004ca0:	02d76863          	bltu	a4,a3,80004cd0 <fileread+0xba>
    80004ca4:	0792                	slli	a5,a5,0x4
    80004ca6:	0001d717          	auipc	a4,0x1d
    80004caa:	ffa70713          	addi	a4,a4,-6 # 80021ca0 <devsw>
    80004cae:	97ba                	add	a5,a5,a4
    80004cb0:	639c                	ld	a5,0(a5)
    80004cb2:	c38d                	beqz	a5,80004cd4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cb4:	4505                	li	a0,1
    80004cb6:	9782                	jalr	a5
    80004cb8:	892a                	mv	s2,a0
    80004cba:	bf75                	j	80004c76 <fileread+0x60>
    panic("fileread");
    80004cbc:	00004517          	auipc	a0,0x4
    80004cc0:	a1c50513          	addi	a0,a0,-1508 # 800086d8 <syscalls+0x268>
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	87a080e7          	jalr	-1926(ra) # 8000053e <panic>
    return -1;
    80004ccc:	597d                	li	s2,-1
    80004cce:	b765                	j	80004c76 <fileread+0x60>
      return -1;
    80004cd0:	597d                	li	s2,-1
    80004cd2:	b755                	j	80004c76 <fileread+0x60>
    80004cd4:	597d                	li	s2,-1
    80004cd6:	b745                	j	80004c76 <fileread+0x60>

0000000080004cd8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cd8:	715d                	addi	sp,sp,-80
    80004cda:	e486                	sd	ra,72(sp)
    80004cdc:	e0a2                	sd	s0,64(sp)
    80004cde:	fc26                	sd	s1,56(sp)
    80004ce0:	f84a                	sd	s2,48(sp)
    80004ce2:	f44e                	sd	s3,40(sp)
    80004ce4:	f052                	sd	s4,32(sp)
    80004ce6:	ec56                	sd	s5,24(sp)
    80004ce8:	e85a                	sd	s6,16(sp)
    80004cea:	e45e                	sd	s7,8(sp)
    80004cec:	e062                	sd	s8,0(sp)
    80004cee:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cf0:	00954783          	lbu	a5,9(a0)
    80004cf4:	10078663          	beqz	a5,80004e00 <filewrite+0x128>
    80004cf8:	892a                	mv	s2,a0
    80004cfa:	8aae                	mv	s5,a1
    80004cfc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cfe:	411c                	lw	a5,0(a0)
    80004d00:	4705                	li	a4,1
    80004d02:	02e78263          	beq	a5,a4,80004d26 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d06:	470d                	li	a4,3
    80004d08:	02e78663          	beq	a5,a4,80004d34 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d0c:	4709                	li	a4,2
    80004d0e:	0ee79163          	bne	a5,a4,80004df0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d12:	0ac05d63          	blez	a2,80004dcc <filewrite+0xf4>
    int i = 0;
    80004d16:	4981                	li	s3,0
    80004d18:	6b05                	lui	s6,0x1
    80004d1a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d1e:	6b85                	lui	s7,0x1
    80004d20:	c00b8b9b          	addiw	s7,s7,-1024
    80004d24:	a861                	j	80004dbc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d26:	6908                	ld	a0,16(a0)
    80004d28:	00000097          	auipc	ra,0x0
    80004d2c:	22e080e7          	jalr	558(ra) # 80004f56 <pipewrite>
    80004d30:	8a2a                	mv	s4,a0
    80004d32:	a045                	j	80004dd2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d34:	02451783          	lh	a5,36(a0)
    80004d38:	03079693          	slli	a3,a5,0x30
    80004d3c:	92c1                	srli	a3,a3,0x30
    80004d3e:	4725                	li	a4,9
    80004d40:	0cd76263          	bltu	a4,a3,80004e04 <filewrite+0x12c>
    80004d44:	0792                	slli	a5,a5,0x4
    80004d46:	0001d717          	auipc	a4,0x1d
    80004d4a:	f5a70713          	addi	a4,a4,-166 # 80021ca0 <devsw>
    80004d4e:	97ba                	add	a5,a5,a4
    80004d50:	679c                	ld	a5,8(a5)
    80004d52:	cbdd                	beqz	a5,80004e08 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d54:	4505                	li	a0,1
    80004d56:	9782                	jalr	a5
    80004d58:	8a2a                	mv	s4,a0
    80004d5a:	a8a5                	j	80004dd2 <filewrite+0xfa>
    80004d5c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d60:	00000097          	auipc	ra,0x0
    80004d64:	8b0080e7          	jalr	-1872(ra) # 80004610 <begin_op>
      ilock(f->ip);
    80004d68:	01893503          	ld	a0,24(s2)
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	ed2080e7          	jalr	-302(ra) # 80003c3e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d74:	8762                	mv	a4,s8
    80004d76:	02092683          	lw	a3,32(s2)
    80004d7a:	01598633          	add	a2,s3,s5
    80004d7e:	4585                	li	a1,1
    80004d80:	01893503          	ld	a0,24(s2)
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	266080e7          	jalr	614(ra) # 80003fea <writei>
    80004d8c:	84aa                	mv	s1,a0
    80004d8e:	00a05763          	blez	a0,80004d9c <filewrite+0xc4>
        f->off += r;
    80004d92:	02092783          	lw	a5,32(s2)
    80004d96:	9fa9                	addw	a5,a5,a0
    80004d98:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d9c:	01893503          	ld	a0,24(s2)
    80004da0:	fffff097          	auipc	ra,0xfffff
    80004da4:	f60080e7          	jalr	-160(ra) # 80003d00 <iunlock>
      end_op();
    80004da8:	00000097          	auipc	ra,0x0
    80004dac:	8e8080e7          	jalr	-1816(ra) # 80004690 <end_op>

      if(r != n1){
    80004db0:	009c1f63          	bne	s8,s1,80004dce <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004db4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004db8:	0149db63          	bge	s3,s4,80004dce <filewrite+0xf6>
      int n1 = n - i;
    80004dbc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004dc0:	84be                	mv	s1,a5
    80004dc2:	2781                	sext.w	a5,a5
    80004dc4:	f8fb5ce3          	bge	s6,a5,80004d5c <filewrite+0x84>
    80004dc8:	84de                	mv	s1,s7
    80004dca:	bf49                	j	80004d5c <filewrite+0x84>
    int i = 0;
    80004dcc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004dce:	013a1f63          	bne	s4,s3,80004dec <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dd2:	8552                	mv	a0,s4
    80004dd4:	60a6                	ld	ra,72(sp)
    80004dd6:	6406                	ld	s0,64(sp)
    80004dd8:	74e2                	ld	s1,56(sp)
    80004dda:	7942                	ld	s2,48(sp)
    80004ddc:	79a2                	ld	s3,40(sp)
    80004dde:	7a02                	ld	s4,32(sp)
    80004de0:	6ae2                	ld	s5,24(sp)
    80004de2:	6b42                	ld	s6,16(sp)
    80004de4:	6ba2                	ld	s7,8(sp)
    80004de6:	6c02                	ld	s8,0(sp)
    80004de8:	6161                	addi	sp,sp,80
    80004dea:	8082                	ret
    ret = (i == n ? n : -1);
    80004dec:	5a7d                	li	s4,-1
    80004dee:	b7d5                	j	80004dd2 <filewrite+0xfa>
    panic("filewrite");
    80004df0:	00004517          	auipc	a0,0x4
    80004df4:	8f850513          	addi	a0,a0,-1800 # 800086e8 <syscalls+0x278>
    80004df8:	ffffb097          	auipc	ra,0xffffb
    80004dfc:	746080e7          	jalr	1862(ra) # 8000053e <panic>
    return -1;
    80004e00:	5a7d                	li	s4,-1
    80004e02:	bfc1                	j	80004dd2 <filewrite+0xfa>
      return -1;
    80004e04:	5a7d                	li	s4,-1
    80004e06:	b7f1                	j	80004dd2 <filewrite+0xfa>
    80004e08:	5a7d                	li	s4,-1
    80004e0a:	b7e1                	j	80004dd2 <filewrite+0xfa>

0000000080004e0c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e0c:	7179                	addi	sp,sp,-48
    80004e0e:	f406                	sd	ra,40(sp)
    80004e10:	f022                	sd	s0,32(sp)
    80004e12:	ec26                	sd	s1,24(sp)
    80004e14:	e84a                	sd	s2,16(sp)
    80004e16:	e44e                	sd	s3,8(sp)
    80004e18:	e052                	sd	s4,0(sp)
    80004e1a:	1800                	addi	s0,sp,48
    80004e1c:	84aa                	mv	s1,a0
    80004e1e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e20:	0005b023          	sd	zero,0(a1)
    80004e24:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e28:	00000097          	auipc	ra,0x0
    80004e2c:	bf8080e7          	jalr	-1032(ra) # 80004a20 <filealloc>
    80004e30:	e088                	sd	a0,0(s1)
    80004e32:	c551                	beqz	a0,80004ebe <pipealloc+0xb2>
    80004e34:	00000097          	auipc	ra,0x0
    80004e38:	bec080e7          	jalr	-1044(ra) # 80004a20 <filealloc>
    80004e3c:	00aa3023          	sd	a0,0(s4)
    80004e40:	c92d                	beqz	a0,80004eb2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	cb2080e7          	jalr	-846(ra) # 80000af4 <kalloc>
    80004e4a:	892a                	mv	s2,a0
    80004e4c:	c125                	beqz	a0,80004eac <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e4e:	4985                	li	s3,1
    80004e50:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e54:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e58:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e5c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e60:	00004597          	auipc	a1,0x4
    80004e64:	89858593          	addi	a1,a1,-1896 # 800086f8 <syscalls+0x288>
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	cec080e7          	jalr	-788(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e70:	609c                	ld	a5,0(s1)
    80004e72:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e76:	609c                	ld	a5,0(s1)
    80004e78:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e7c:	609c                	ld	a5,0(s1)
    80004e7e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e82:	609c                	ld	a5,0(s1)
    80004e84:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e88:	000a3783          	ld	a5,0(s4)
    80004e8c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e90:	000a3783          	ld	a5,0(s4)
    80004e94:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e98:	000a3783          	ld	a5,0(s4)
    80004e9c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ea0:	000a3783          	ld	a5,0(s4)
    80004ea4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ea8:	4501                	li	a0,0
    80004eaa:	a025                	j	80004ed2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004eac:	6088                	ld	a0,0(s1)
    80004eae:	e501                	bnez	a0,80004eb6 <pipealloc+0xaa>
    80004eb0:	a039                	j	80004ebe <pipealloc+0xb2>
    80004eb2:	6088                	ld	a0,0(s1)
    80004eb4:	c51d                	beqz	a0,80004ee2 <pipealloc+0xd6>
    fileclose(*f0);
    80004eb6:	00000097          	auipc	ra,0x0
    80004eba:	c26080e7          	jalr	-986(ra) # 80004adc <fileclose>
  if(*f1)
    80004ebe:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ec2:	557d                	li	a0,-1
  if(*f1)
    80004ec4:	c799                	beqz	a5,80004ed2 <pipealloc+0xc6>
    fileclose(*f1);
    80004ec6:	853e                	mv	a0,a5
    80004ec8:	00000097          	auipc	ra,0x0
    80004ecc:	c14080e7          	jalr	-1004(ra) # 80004adc <fileclose>
  return -1;
    80004ed0:	557d                	li	a0,-1
}
    80004ed2:	70a2                	ld	ra,40(sp)
    80004ed4:	7402                	ld	s0,32(sp)
    80004ed6:	64e2                	ld	s1,24(sp)
    80004ed8:	6942                	ld	s2,16(sp)
    80004eda:	69a2                	ld	s3,8(sp)
    80004edc:	6a02                	ld	s4,0(sp)
    80004ede:	6145                	addi	sp,sp,48
    80004ee0:	8082                	ret
  return -1;
    80004ee2:	557d                	li	a0,-1
    80004ee4:	b7fd                	j	80004ed2 <pipealloc+0xc6>

0000000080004ee6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ee6:	1101                	addi	sp,sp,-32
    80004ee8:	ec06                	sd	ra,24(sp)
    80004eea:	e822                	sd	s0,16(sp)
    80004eec:	e426                	sd	s1,8(sp)
    80004eee:	e04a                	sd	s2,0(sp)
    80004ef0:	1000                	addi	s0,sp,32
    80004ef2:	84aa                	mv	s1,a0
    80004ef4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	cee080e7          	jalr	-786(ra) # 80000be4 <acquire>
  if(writable){
    80004efe:	02090d63          	beqz	s2,80004f38 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f02:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f06:	21848513          	addi	a0,s1,536
    80004f0a:	ffffd097          	auipc	ra,0xffffd
    80004f0e:	490080e7          	jalr	1168(ra) # 8000239a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f12:	2204b783          	ld	a5,544(s1)
    80004f16:	eb95                	bnez	a5,80004f4a <pipeclose+0x64>
    release(&pi->lock);
    80004f18:	8526                	mv	a0,s1
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	d7e080e7          	jalr	-642(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004f22:	8526                	mv	a0,s1
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	ad4080e7          	jalr	-1324(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f2c:	60e2                	ld	ra,24(sp)
    80004f2e:	6442                	ld	s0,16(sp)
    80004f30:	64a2                	ld	s1,8(sp)
    80004f32:	6902                	ld	s2,0(sp)
    80004f34:	6105                	addi	sp,sp,32
    80004f36:	8082                	ret
    pi->readopen = 0;
    80004f38:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f3c:	21c48513          	addi	a0,s1,540
    80004f40:	ffffd097          	auipc	ra,0xffffd
    80004f44:	45a080e7          	jalr	1114(ra) # 8000239a <wakeup>
    80004f48:	b7e9                	j	80004f12 <pipeclose+0x2c>
    release(&pi->lock);
    80004f4a:	8526                	mv	a0,s1
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	d4c080e7          	jalr	-692(ra) # 80000c98 <release>
}
    80004f54:	bfe1                	j	80004f2c <pipeclose+0x46>

0000000080004f56 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f56:	7159                	addi	sp,sp,-112
    80004f58:	f486                	sd	ra,104(sp)
    80004f5a:	f0a2                	sd	s0,96(sp)
    80004f5c:	eca6                	sd	s1,88(sp)
    80004f5e:	e8ca                	sd	s2,80(sp)
    80004f60:	e4ce                	sd	s3,72(sp)
    80004f62:	e0d2                	sd	s4,64(sp)
    80004f64:	fc56                	sd	s5,56(sp)
    80004f66:	f85a                	sd	s6,48(sp)
    80004f68:	f45e                	sd	s7,40(sp)
    80004f6a:	f062                	sd	s8,32(sp)
    80004f6c:	ec66                	sd	s9,24(sp)
    80004f6e:	1880                	addi	s0,sp,112
    80004f70:	84aa                	mv	s1,a0
    80004f72:	8aae                	mv	s5,a1
    80004f74:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f76:	ffffd097          	auipc	ra,0xffffd
    80004f7a:	990080e7          	jalr	-1648(ra) # 80001906 <myproc>
    80004f7e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f80:	8526                	mv	a0,s1
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	c62080e7          	jalr	-926(ra) # 80000be4 <acquire>
  while(i < n){
    80004f8a:	0d405163          	blez	s4,8000504c <pipewrite+0xf6>
    80004f8e:	8ba6                	mv	s7,s1
  int i = 0;
    80004f90:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f92:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f94:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f98:	21c48c13          	addi	s8,s1,540
    80004f9c:	a08d                	j	80004ffe <pipewrite+0xa8>
      release(&pi->lock);
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	cf8080e7          	jalr	-776(ra) # 80000c98 <release>
      return -1;
    80004fa8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004faa:	854a                	mv	a0,s2
    80004fac:	70a6                	ld	ra,104(sp)
    80004fae:	7406                	ld	s0,96(sp)
    80004fb0:	64e6                	ld	s1,88(sp)
    80004fb2:	6946                	ld	s2,80(sp)
    80004fb4:	69a6                	ld	s3,72(sp)
    80004fb6:	6a06                	ld	s4,64(sp)
    80004fb8:	7ae2                	ld	s5,56(sp)
    80004fba:	7b42                	ld	s6,48(sp)
    80004fbc:	7ba2                	ld	s7,40(sp)
    80004fbe:	7c02                	ld	s8,32(sp)
    80004fc0:	6ce2                	ld	s9,24(sp)
    80004fc2:	6165                	addi	sp,sp,112
    80004fc4:	8082                	ret
      wakeup(&pi->nread);
    80004fc6:	8566                	mv	a0,s9
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	3d2080e7          	jalr	978(ra) # 8000239a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fd0:	85de                	mv	a1,s7
    80004fd2:	8562                	mv	a0,s8
    80004fd4:	ffffd097          	auipc	ra,0xffffd
    80004fd8:	04c080e7          	jalr	76(ra) # 80002020 <sleep>
    80004fdc:	a839                	j	80004ffa <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fde:	21c4a783          	lw	a5,540(s1)
    80004fe2:	0017871b          	addiw	a4,a5,1
    80004fe6:	20e4ae23          	sw	a4,540(s1)
    80004fea:	1ff7f793          	andi	a5,a5,511
    80004fee:	97a6                	add	a5,a5,s1
    80004ff0:	f9f44703          	lbu	a4,-97(s0)
    80004ff4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ff8:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ffa:	03495d63          	bge	s2,s4,80005034 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004ffe:	2204a783          	lw	a5,544(s1)
    80005002:	dfd1                	beqz	a5,80004f9e <pipewrite+0x48>
    80005004:	0289a783          	lw	a5,40(s3)
    80005008:	fbd9                	bnez	a5,80004f9e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000500a:	2184a783          	lw	a5,536(s1)
    8000500e:	21c4a703          	lw	a4,540(s1)
    80005012:	2007879b          	addiw	a5,a5,512
    80005016:	faf708e3          	beq	a4,a5,80004fc6 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000501a:	4685                	li	a3,1
    8000501c:	01590633          	add	a2,s2,s5
    80005020:	f9f40593          	addi	a1,s0,-97
    80005024:	0709b503          	ld	a0,112(s3)
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	6d6080e7          	jalr	1750(ra) # 800016fe <copyin>
    80005030:	fb6517e3          	bne	a0,s6,80004fde <pipewrite+0x88>
  wakeup(&pi->nread);
    80005034:	21848513          	addi	a0,s1,536
    80005038:	ffffd097          	auipc	ra,0xffffd
    8000503c:	362080e7          	jalr	866(ra) # 8000239a <wakeup>
  release(&pi->lock);
    80005040:	8526                	mv	a0,s1
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	c56080e7          	jalr	-938(ra) # 80000c98 <release>
  return i;
    8000504a:	b785                	j	80004faa <pipewrite+0x54>
  int i = 0;
    8000504c:	4901                	li	s2,0
    8000504e:	b7dd                	j	80005034 <pipewrite+0xde>

0000000080005050 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005050:	715d                	addi	sp,sp,-80
    80005052:	e486                	sd	ra,72(sp)
    80005054:	e0a2                	sd	s0,64(sp)
    80005056:	fc26                	sd	s1,56(sp)
    80005058:	f84a                	sd	s2,48(sp)
    8000505a:	f44e                	sd	s3,40(sp)
    8000505c:	f052                	sd	s4,32(sp)
    8000505e:	ec56                	sd	s5,24(sp)
    80005060:	e85a                	sd	s6,16(sp)
    80005062:	0880                	addi	s0,sp,80
    80005064:	84aa                	mv	s1,a0
    80005066:	892e                	mv	s2,a1
    80005068:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000506a:	ffffd097          	auipc	ra,0xffffd
    8000506e:	89c080e7          	jalr	-1892(ra) # 80001906 <myproc>
    80005072:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005074:	8b26                	mv	s6,s1
    80005076:	8526                	mv	a0,s1
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	b6c080e7          	jalr	-1172(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005080:	2184a703          	lw	a4,536(s1)
    80005084:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005088:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000508c:	02f71463          	bne	a4,a5,800050b4 <piperead+0x64>
    80005090:	2244a783          	lw	a5,548(s1)
    80005094:	c385                	beqz	a5,800050b4 <piperead+0x64>
    if(pr->killed){
    80005096:	028a2783          	lw	a5,40(s4)
    8000509a:	ebc1                	bnez	a5,8000512a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000509c:	85da                	mv	a1,s6
    8000509e:	854e                	mv	a0,s3
    800050a0:	ffffd097          	auipc	ra,0xffffd
    800050a4:	f80080e7          	jalr	-128(ra) # 80002020 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050a8:	2184a703          	lw	a4,536(s1)
    800050ac:	21c4a783          	lw	a5,540(s1)
    800050b0:	fef700e3          	beq	a4,a5,80005090 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050b4:	09505263          	blez	s5,80005138 <piperead+0xe8>
    800050b8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050ba:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800050bc:	2184a783          	lw	a5,536(s1)
    800050c0:	21c4a703          	lw	a4,540(s1)
    800050c4:	02f70d63          	beq	a4,a5,800050fe <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050c8:	0017871b          	addiw	a4,a5,1
    800050cc:	20e4ac23          	sw	a4,536(s1)
    800050d0:	1ff7f793          	andi	a5,a5,511
    800050d4:	97a6                	add	a5,a5,s1
    800050d6:	0187c783          	lbu	a5,24(a5)
    800050da:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050de:	4685                	li	a3,1
    800050e0:	fbf40613          	addi	a2,s0,-65
    800050e4:	85ca                	mv	a1,s2
    800050e6:	070a3503          	ld	a0,112(s4)
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	588080e7          	jalr	1416(ra) # 80001672 <copyout>
    800050f2:	01650663          	beq	a0,s6,800050fe <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050f6:	2985                	addiw	s3,s3,1
    800050f8:	0905                	addi	s2,s2,1
    800050fa:	fd3a91e3          	bne	s5,s3,800050bc <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050fe:	21c48513          	addi	a0,s1,540
    80005102:	ffffd097          	auipc	ra,0xffffd
    80005106:	298080e7          	jalr	664(ra) # 8000239a <wakeup>
  release(&pi->lock);
    8000510a:	8526                	mv	a0,s1
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>
  return i;
}
    80005114:	854e                	mv	a0,s3
    80005116:	60a6                	ld	ra,72(sp)
    80005118:	6406                	ld	s0,64(sp)
    8000511a:	74e2                	ld	s1,56(sp)
    8000511c:	7942                	ld	s2,48(sp)
    8000511e:	79a2                	ld	s3,40(sp)
    80005120:	7a02                	ld	s4,32(sp)
    80005122:	6ae2                	ld	s5,24(sp)
    80005124:	6b42                	ld	s6,16(sp)
    80005126:	6161                	addi	sp,sp,80
    80005128:	8082                	ret
      release(&pi->lock);
    8000512a:	8526                	mv	a0,s1
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	b6c080e7          	jalr	-1172(ra) # 80000c98 <release>
      return -1;
    80005134:	59fd                	li	s3,-1
    80005136:	bff9                	j	80005114 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005138:	4981                	li	s3,0
    8000513a:	b7d1                	j	800050fe <piperead+0xae>

000000008000513c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000513c:	df010113          	addi	sp,sp,-528
    80005140:	20113423          	sd	ra,520(sp)
    80005144:	20813023          	sd	s0,512(sp)
    80005148:	ffa6                	sd	s1,504(sp)
    8000514a:	fbca                	sd	s2,496(sp)
    8000514c:	f7ce                	sd	s3,488(sp)
    8000514e:	f3d2                	sd	s4,480(sp)
    80005150:	efd6                	sd	s5,472(sp)
    80005152:	ebda                	sd	s6,464(sp)
    80005154:	e7de                	sd	s7,456(sp)
    80005156:	e3e2                	sd	s8,448(sp)
    80005158:	ff66                	sd	s9,440(sp)
    8000515a:	fb6a                	sd	s10,432(sp)
    8000515c:	f76e                	sd	s11,424(sp)
    8000515e:	0c00                	addi	s0,sp,528
    80005160:	84aa                	mv	s1,a0
    80005162:	dea43c23          	sd	a0,-520(s0)
    80005166:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	79c080e7          	jalr	1948(ra) # 80001906 <myproc>
    80005172:	892a                	mv	s2,a0

  begin_op();
    80005174:	fffff097          	auipc	ra,0xfffff
    80005178:	49c080e7          	jalr	1180(ra) # 80004610 <begin_op>

  if((ip = namei(path)) == 0){
    8000517c:	8526                	mv	a0,s1
    8000517e:	fffff097          	auipc	ra,0xfffff
    80005182:	276080e7          	jalr	630(ra) # 800043f4 <namei>
    80005186:	c92d                	beqz	a0,800051f8 <exec+0xbc>
    80005188:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	ab4080e7          	jalr	-1356(ra) # 80003c3e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005192:	04000713          	li	a4,64
    80005196:	4681                	li	a3,0
    80005198:	e5040613          	addi	a2,s0,-432
    8000519c:	4581                	li	a1,0
    8000519e:	8526                	mv	a0,s1
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	d52080e7          	jalr	-686(ra) # 80003ef2 <readi>
    800051a8:	04000793          	li	a5,64
    800051ac:	00f51a63          	bne	a0,a5,800051c0 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051b0:	e5042703          	lw	a4,-432(s0)
    800051b4:	464c47b7          	lui	a5,0x464c4
    800051b8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051bc:	04f70463          	beq	a4,a5,80005204 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051c0:	8526                	mv	a0,s1
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	cde080e7          	jalr	-802(ra) # 80003ea0 <iunlockput>
    end_op();
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	4c6080e7          	jalr	1222(ra) # 80004690 <end_op>
  }
  return -1;
    800051d2:	557d                	li	a0,-1
}
    800051d4:	20813083          	ld	ra,520(sp)
    800051d8:	20013403          	ld	s0,512(sp)
    800051dc:	74fe                	ld	s1,504(sp)
    800051de:	795e                	ld	s2,496(sp)
    800051e0:	79be                	ld	s3,488(sp)
    800051e2:	7a1e                	ld	s4,480(sp)
    800051e4:	6afe                	ld	s5,472(sp)
    800051e6:	6b5e                	ld	s6,464(sp)
    800051e8:	6bbe                	ld	s7,456(sp)
    800051ea:	6c1e                	ld	s8,448(sp)
    800051ec:	7cfa                	ld	s9,440(sp)
    800051ee:	7d5a                	ld	s10,432(sp)
    800051f0:	7dba                	ld	s11,424(sp)
    800051f2:	21010113          	addi	sp,sp,528
    800051f6:	8082                	ret
    end_op();
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	498080e7          	jalr	1176(ra) # 80004690 <end_op>
    return -1;
    80005200:	557d                	li	a0,-1
    80005202:	bfc9                	j	800051d4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005204:	854a                	mv	a0,s2
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	7bc080e7          	jalr	1980(ra) # 800019c2 <proc_pagetable>
    8000520e:	8baa                	mv	s7,a0
    80005210:	d945                	beqz	a0,800051c0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005212:	e7042983          	lw	s3,-400(s0)
    80005216:	e8845783          	lhu	a5,-376(s0)
    8000521a:	c7ad                	beqz	a5,80005284 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000521c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000521e:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005220:	6c85                	lui	s9,0x1
    80005222:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005226:	def43823          	sd	a5,-528(s0)
    8000522a:	a42d                	j	80005454 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000522c:	00003517          	auipc	a0,0x3
    80005230:	4d450513          	addi	a0,a0,1236 # 80008700 <syscalls+0x290>
    80005234:	ffffb097          	auipc	ra,0xffffb
    80005238:	30a080e7          	jalr	778(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000523c:	8756                	mv	a4,s5
    8000523e:	012d86bb          	addw	a3,s11,s2
    80005242:	4581                	li	a1,0
    80005244:	8526                	mv	a0,s1
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	cac080e7          	jalr	-852(ra) # 80003ef2 <readi>
    8000524e:	2501                	sext.w	a0,a0
    80005250:	1aaa9963          	bne	s5,a0,80005402 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005254:	6785                	lui	a5,0x1
    80005256:	0127893b          	addw	s2,a5,s2
    8000525a:	77fd                	lui	a5,0xfffff
    8000525c:	01478a3b          	addw	s4,a5,s4
    80005260:	1f897163          	bgeu	s2,s8,80005442 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005264:	02091593          	slli	a1,s2,0x20
    80005268:	9181                	srli	a1,a1,0x20
    8000526a:	95ea                	add	a1,a1,s10
    8000526c:	855e                	mv	a0,s7
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	e00080e7          	jalr	-512(ra) # 8000106e <walkaddr>
    80005276:	862a                	mv	a2,a0
    if(pa == 0)
    80005278:	d955                	beqz	a0,8000522c <exec+0xf0>
      n = PGSIZE;
    8000527a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000527c:	fd9a70e3          	bgeu	s4,s9,8000523c <exec+0x100>
      n = sz - i;
    80005280:	8ad2                	mv	s5,s4
    80005282:	bf6d                	j	8000523c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005284:	4901                	li	s2,0
  iunlockput(ip);
    80005286:	8526                	mv	a0,s1
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	c18080e7          	jalr	-1000(ra) # 80003ea0 <iunlockput>
  end_op();
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	400080e7          	jalr	1024(ra) # 80004690 <end_op>
  p = myproc();
    80005298:	ffffc097          	auipc	ra,0xffffc
    8000529c:	66e080e7          	jalr	1646(ra) # 80001906 <myproc>
    800052a0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052a2:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800052a6:	6785                	lui	a5,0x1
    800052a8:	17fd                	addi	a5,a5,-1
    800052aa:	993e                	add	s2,s2,a5
    800052ac:	757d                	lui	a0,0xfffff
    800052ae:	00a977b3          	and	a5,s2,a0
    800052b2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052b6:	6609                	lui	a2,0x2
    800052b8:	963e                	add	a2,a2,a5
    800052ba:	85be                	mv	a1,a5
    800052bc:	855e                	mv	a0,s7
    800052be:	ffffc097          	auipc	ra,0xffffc
    800052c2:	164080e7          	jalr	356(ra) # 80001422 <uvmalloc>
    800052c6:	8b2a                	mv	s6,a0
  ip = 0;
    800052c8:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052ca:	12050c63          	beqz	a0,80005402 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052ce:	75f9                	lui	a1,0xffffe
    800052d0:	95aa                	add	a1,a1,a0
    800052d2:	855e                	mv	a0,s7
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	36c080e7          	jalr	876(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800052dc:	7c7d                	lui	s8,0xfffff
    800052de:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800052e0:	e0043783          	ld	a5,-512(s0)
    800052e4:	6388                	ld	a0,0(a5)
    800052e6:	c535                	beqz	a0,80005352 <exec+0x216>
    800052e8:	e9040993          	addi	s3,s0,-368
    800052ec:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052f0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052f2:	ffffc097          	auipc	ra,0xffffc
    800052f6:	b72080e7          	jalr	-1166(ra) # 80000e64 <strlen>
    800052fa:	2505                	addiw	a0,a0,1
    800052fc:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005300:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005304:	13896363          	bltu	s2,s8,8000542a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005308:	e0043d83          	ld	s11,-512(s0)
    8000530c:	000dba03          	ld	s4,0(s11)
    80005310:	8552                	mv	a0,s4
    80005312:	ffffc097          	auipc	ra,0xffffc
    80005316:	b52080e7          	jalr	-1198(ra) # 80000e64 <strlen>
    8000531a:	0015069b          	addiw	a3,a0,1
    8000531e:	8652                	mv	a2,s4
    80005320:	85ca                	mv	a1,s2
    80005322:	855e                	mv	a0,s7
    80005324:	ffffc097          	auipc	ra,0xffffc
    80005328:	34e080e7          	jalr	846(ra) # 80001672 <copyout>
    8000532c:	10054363          	bltz	a0,80005432 <exec+0x2f6>
    ustack[argc] = sp;
    80005330:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005334:	0485                	addi	s1,s1,1
    80005336:	008d8793          	addi	a5,s11,8
    8000533a:	e0f43023          	sd	a5,-512(s0)
    8000533e:	008db503          	ld	a0,8(s11)
    80005342:	c911                	beqz	a0,80005356 <exec+0x21a>
    if(argc >= MAXARG)
    80005344:	09a1                	addi	s3,s3,8
    80005346:	fb3c96e3          	bne	s9,s3,800052f2 <exec+0x1b6>
  sz = sz1;
    8000534a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000534e:	4481                	li	s1,0
    80005350:	a84d                	j	80005402 <exec+0x2c6>
  sp = sz;
    80005352:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005354:	4481                	li	s1,0
  ustack[argc] = 0;
    80005356:	00349793          	slli	a5,s1,0x3
    8000535a:	f9040713          	addi	a4,s0,-112
    8000535e:	97ba                	add	a5,a5,a4
    80005360:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005364:	00148693          	addi	a3,s1,1
    80005368:	068e                	slli	a3,a3,0x3
    8000536a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000536e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005372:	01897663          	bgeu	s2,s8,8000537e <exec+0x242>
  sz = sz1;
    80005376:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000537a:	4481                	li	s1,0
    8000537c:	a059                	j	80005402 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000537e:	e9040613          	addi	a2,s0,-368
    80005382:	85ca                	mv	a1,s2
    80005384:	855e                	mv	a0,s7
    80005386:	ffffc097          	auipc	ra,0xffffc
    8000538a:	2ec080e7          	jalr	748(ra) # 80001672 <copyout>
    8000538e:	0a054663          	bltz	a0,8000543a <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005392:	078ab783          	ld	a5,120(s5)
    80005396:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000539a:	df843783          	ld	a5,-520(s0)
    8000539e:	0007c703          	lbu	a4,0(a5)
    800053a2:	cf11                	beqz	a4,800053be <exec+0x282>
    800053a4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053a6:	02f00693          	li	a3,47
    800053aa:	a039                	j	800053b8 <exec+0x27c>
      last = s+1;
    800053ac:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800053b0:	0785                	addi	a5,a5,1
    800053b2:	fff7c703          	lbu	a4,-1(a5)
    800053b6:	c701                	beqz	a4,800053be <exec+0x282>
    if(*s == '/')
    800053b8:	fed71ce3          	bne	a4,a3,800053b0 <exec+0x274>
    800053bc:	bfc5                	j	800053ac <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800053be:	4641                	li	a2,16
    800053c0:	df843583          	ld	a1,-520(s0)
    800053c4:	178a8513          	addi	a0,s5,376
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	a6a080e7          	jalr	-1430(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800053d0:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800053d4:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800053d8:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053dc:	078ab783          	ld	a5,120(s5)
    800053e0:	e6843703          	ld	a4,-408(s0)
    800053e4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053e6:	078ab783          	ld	a5,120(s5)
    800053ea:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053ee:	85ea                	mv	a1,s10
    800053f0:	ffffc097          	auipc	ra,0xffffc
    800053f4:	66e080e7          	jalr	1646(ra) # 80001a5e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053f8:	0004851b          	sext.w	a0,s1
    800053fc:	bbe1                	j	800051d4 <exec+0x98>
    800053fe:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005402:	e0843583          	ld	a1,-504(s0)
    80005406:	855e                	mv	a0,s7
    80005408:	ffffc097          	auipc	ra,0xffffc
    8000540c:	656080e7          	jalr	1622(ra) # 80001a5e <proc_freepagetable>
  if(ip){
    80005410:	da0498e3          	bnez	s1,800051c0 <exec+0x84>
  return -1;
    80005414:	557d                	li	a0,-1
    80005416:	bb7d                	j	800051d4 <exec+0x98>
    80005418:	e1243423          	sd	s2,-504(s0)
    8000541c:	b7dd                	j	80005402 <exec+0x2c6>
    8000541e:	e1243423          	sd	s2,-504(s0)
    80005422:	b7c5                	j	80005402 <exec+0x2c6>
    80005424:	e1243423          	sd	s2,-504(s0)
    80005428:	bfe9                	j	80005402 <exec+0x2c6>
  sz = sz1;
    8000542a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000542e:	4481                	li	s1,0
    80005430:	bfc9                	j	80005402 <exec+0x2c6>
  sz = sz1;
    80005432:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005436:	4481                	li	s1,0
    80005438:	b7e9                	j	80005402 <exec+0x2c6>
  sz = sz1;
    8000543a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000543e:	4481                	li	s1,0
    80005440:	b7c9                	j	80005402 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005442:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005446:	2b05                	addiw	s6,s6,1
    80005448:	0389899b          	addiw	s3,s3,56
    8000544c:	e8845783          	lhu	a5,-376(s0)
    80005450:	e2fb5be3          	bge	s6,a5,80005286 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005454:	2981                	sext.w	s3,s3
    80005456:	03800713          	li	a4,56
    8000545a:	86ce                	mv	a3,s3
    8000545c:	e1840613          	addi	a2,s0,-488
    80005460:	4581                	li	a1,0
    80005462:	8526                	mv	a0,s1
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	a8e080e7          	jalr	-1394(ra) # 80003ef2 <readi>
    8000546c:	03800793          	li	a5,56
    80005470:	f8f517e3          	bne	a0,a5,800053fe <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005474:	e1842783          	lw	a5,-488(s0)
    80005478:	4705                	li	a4,1
    8000547a:	fce796e3          	bne	a5,a4,80005446 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000547e:	e4043603          	ld	a2,-448(s0)
    80005482:	e3843783          	ld	a5,-456(s0)
    80005486:	f8f669e3          	bltu	a2,a5,80005418 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000548a:	e2843783          	ld	a5,-472(s0)
    8000548e:	963e                	add	a2,a2,a5
    80005490:	f8f667e3          	bltu	a2,a5,8000541e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005494:	85ca                	mv	a1,s2
    80005496:	855e                	mv	a0,s7
    80005498:	ffffc097          	auipc	ra,0xffffc
    8000549c:	f8a080e7          	jalr	-118(ra) # 80001422 <uvmalloc>
    800054a0:	e0a43423          	sd	a0,-504(s0)
    800054a4:	d141                	beqz	a0,80005424 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800054a6:	e2843d03          	ld	s10,-472(s0)
    800054aa:	df043783          	ld	a5,-528(s0)
    800054ae:	00fd77b3          	and	a5,s10,a5
    800054b2:	fba1                	bnez	a5,80005402 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054b4:	e2042d83          	lw	s11,-480(s0)
    800054b8:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054bc:	f80c03e3          	beqz	s8,80005442 <exec+0x306>
    800054c0:	8a62                	mv	s4,s8
    800054c2:	4901                	li	s2,0
    800054c4:	b345                	j	80005264 <exec+0x128>

00000000800054c6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054c6:	7179                	addi	sp,sp,-48
    800054c8:	f406                	sd	ra,40(sp)
    800054ca:	f022                	sd	s0,32(sp)
    800054cc:	ec26                	sd	s1,24(sp)
    800054ce:	e84a                	sd	s2,16(sp)
    800054d0:	1800                	addi	s0,sp,48
    800054d2:	892e                	mv	s2,a1
    800054d4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800054d6:	fdc40593          	addi	a1,s0,-36
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	ba8080e7          	jalr	-1112(ra) # 80003082 <argint>
    800054e2:	04054063          	bltz	a0,80005522 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054e6:	fdc42703          	lw	a4,-36(s0)
    800054ea:	47bd                	li	a5,15
    800054ec:	02e7ed63          	bltu	a5,a4,80005526 <argfd+0x60>
    800054f0:	ffffc097          	auipc	ra,0xffffc
    800054f4:	416080e7          	jalr	1046(ra) # 80001906 <myproc>
    800054f8:	fdc42703          	lw	a4,-36(s0)
    800054fc:	01e70793          	addi	a5,a4,30
    80005500:	078e                	slli	a5,a5,0x3
    80005502:	953e                	add	a0,a0,a5
    80005504:	611c                	ld	a5,0(a0)
    80005506:	c395                	beqz	a5,8000552a <argfd+0x64>
    return -1;
  if(pfd)
    80005508:	00090463          	beqz	s2,80005510 <argfd+0x4a>
    *pfd = fd;
    8000550c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005510:	4501                	li	a0,0
  if(pf)
    80005512:	c091                	beqz	s1,80005516 <argfd+0x50>
    *pf = f;
    80005514:	e09c                	sd	a5,0(s1)
}
    80005516:	70a2                	ld	ra,40(sp)
    80005518:	7402                	ld	s0,32(sp)
    8000551a:	64e2                	ld	s1,24(sp)
    8000551c:	6942                	ld	s2,16(sp)
    8000551e:	6145                	addi	sp,sp,48
    80005520:	8082                	ret
    return -1;
    80005522:	557d                	li	a0,-1
    80005524:	bfcd                	j	80005516 <argfd+0x50>
    return -1;
    80005526:	557d                	li	a0,-1
    80005528:	b7fd                	j	80005516 <argfd+0x50>
    8000552a:	557d                	li	a0,-1
    8000552c:	b7ed                	j	80005516 <argfd+0x50>

000000008000552e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000552e:	1101                	addi	sp,sp,-32
    80005530:	ec06                	sd	ra,24(sp)
    80005532:	e822                	sd	s0,16(sp)
    80005534:	e426                	sd	s1,8(sp)
    80005536:	1000                	addi	s0,sp,32
    80005538:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000553a:	ffffc097          	auipc	ra,0xffffc
    8000553e:	3cc080e7          	jalr	972(ra) # 80001906 <myproc>
    80005542:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005544:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005548:	4501                	li	a0,0
    8000554a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000554c:	6398                	ld	a4,0(a5)
    8000554e:	cb19                	beqz	a4,80005564 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005550:	2505                	addiw	a0,a0,1
    80005552:	07a1                	addi	a5,a5,8
    80005554:	fed51ce3          	bne	a0,a3,8000554c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005558:	557d                	li	a0,-1
}
    8000555a:	60e2                	ld	ra,24(sp)
    8000555c:	6442                	ld	s0,16(sp)
    8000555e:	64a2                	ld	s1,8(sp)
    80005560:	6105                	addi	sp,sp,32
    80005562:	8082                	ret
      p->ofile[fd] = f;
    80005564:	01e50793          	addi	a5,a0,30
    80005568:	078e                	slli	a5,a5,0x3
    8000556a:	963e                	add	a2,a2,a5
    8000556c:	e204                	sd	s1,0(a2)
      return fd;
    8000556e:	b7f5                	j	8000555a <fdalloc+0x2c>

0000000080005570 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005570:	715d                	addi	sp,sp,-80
    80005572:	e486                	sd	ra,72(sp)
    80005574:	e0a2                	sd	s0,64(sp)
    80005576:	fc26                	sd	s1,56(sp)
    80005578:	f84a                	sd	s2,48(sp)
    8000557a:	f44e                	sd	s3,40(sp)
    8000557c:	f052                	sd	s4,32(sp)
    8000557e:	ec56                	sd	s5,24(sp)
    80005580:	0880                	addi	s0,sp,80
    80005582:	89ae                	mv	s3,a1
    80005584:	8ab2                	mv	s5,a2
    80005586:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005588:	fb040593          	addi	a1,s0,-80
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	e86080e7          	jalr	-378(ra) # 80004412 <nameiparent>
    80005594:	892a                	mv	s2,a0
    80005596:	12050f63          	beqz	a0,800056d4 <create+0x164>
    return 0;

  ilock(dp);
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	6a4080e7          	jalr	1700(ra) # 80003c3e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055a2:	4601                	li	a2,0
    800055a4:	fb040593          	addi	a1,s0,-80
    800055a8:	854a                	mv	a0,s2
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	b78080e7          	jalr	-1160(ra) # 80004122 <dirlookup>
    800055b2:	84aa                	mv	s1,a0
    800055b4:	c921                	beqz	a0,80005604 <create+0x94>
    iunlockput(dp);
    800055b6:	854a                	mv	a0,s2
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	8e8080e7          	jalr	-1816(ra) # 80003ea0 <iunlockput>
    ilock(ip);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	67c080e7          	jalr	1660(ra) # 80003c3e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055ca:	2981                	sext.w	s3,s3
    800055cc:	4789                	li	a5,2
    800055ce:	02f99463          	bne	s3,a5,800055f6 <create+0x86>
    800055d2:	0444d783          	lhu	a5,68(s1)
    800055d6:	37f9                	addiw	a5,a5,-2
    800055d8:	17c2                	slli	a5,a5,0x30
    800055da:	93c1                	srli	a5,a5,0x30
    800055dc:	4705                	li	a4,1
    800055de:	00f76c63          	bltu	a4,a5,800055f6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800055e2:	8526                	mv	a0,s1
    800055e4:	60a6                	ld	ra,72(sp)
    800055e6:	6406                	ld	s0,64(sp)
    800055e8:	74e2                	ld	s1,56(sp)
    800055ea:	7942                	ld	s2,48(sp)
    800055ec:	79a2                	ld	s3,40(sp)
    800055ee:	7a02                	ld	s4,32(sp)
    800055f0:	6ae2                	ld	s5,24(sp)
    800055f2:	6161                	addi	sp,sp,80
    800055f4:	8082                	ret
    iunlockput(ip);
    800055f6:	8526                	mv	a0,s1
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	8a8080e7          	jalr	-1880(ra) # 80003ea0 <iunlockput>
    return 0;
    80005600:	4481                	li	s1,0
    80005602:	b7c5                	j	800055e2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005604:	85ce                	mv	a1,s3
    80005606:	00092503          	lw	a0,0(s2)
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	49c080e7          	jalr	1180(ra) # 80003aa6 <ialloc>
    80005612:	84aa                	mv	s1,a0
    80005614:	c529                	beqz	a0,8000565e <create+0xee>
  ilock(ip);
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	628080e7          	jalr	1576(ra) # 80003c3e <ilock>
  ip->major = major;
    8000561e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005622:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005626:	4785                	li	a5,1
    80005628:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	546080e7          	jalr	1350(ra) # 80003b74 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005636:	2981                	sext.w	s3,s3
    80005638:	4785                	li	a5,1
    8000563a:	02f98a63          	beq	s3,a5,8000566e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000563e:	40d0                	lw	a2,4(s1)
    80005640:	fb040593          	addi	a1,s0,-80
    80005644:	854a                	mv	a0,s2
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	cec080e7          	jalr	-788(ra) # 80004332 <dirlink>
    8000564e:	06054b63          	bltz	a0,800056c4 <create+0x154>
  iunlockput(dp);
    80005652:	854a                	mv	a0,s2
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	84c080e7          	jalr	-1972(ra) # 80003ea0 <iunlockput>
  return ip;
    8000565c:	b759                	j	800055e2 <create+0x72>
    panic("create: ialloc");
    8000565e:	00003517          	auipc	a0,0x3
    80005662:	0c250513          	addi	a0,a0,194 # 80008720 <syscalls+0x2b0>
    80005666:	ffffb097          	auipc	ra,0xffffb
    8000566a:	ed8080e7          	jalr	-296(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000566e:	04a95783          	lhu	a5,74(s2)
    80005672:	2785                	addiw	a5,a5,1
    80005674:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005678:	854a                	mv	a0,s2
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	4fa080e7          	jalr	1274(ra) # 80003b74 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005682:	40d0                	lw	a2,4(s1)
    80005684:	00003597          	auipc	a1,0x3
    80005688:	0ac58593          	addi	a1,a1,172 # 80008730 <syscalls+0x2c0>
    8000568c:	8526                	mv	a0,s1
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	ca4080e7          	jalr	-860(ra) # 80004332 <dirlink>
    80005696:	00054f63          	bltz	a0,800056b4 <create+0x144>
    8000569a:	00492603          	lw	a2,4(s2)
    8000569e:	00003597          	auipc	a1,0x3
    800056a2:	09a58593          	addi	a1,a1,154 # 80008738 <syscalls+0x2c8>
    800056a6:	8526                	mv	a0,s1
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	c8a080e7          	jalr	-886(ra) # 80004332 <dirlink>
    800056b0:	f80557e3          	bgez	a0,8000563e <create+0xce>
      panic("create dots");
    800056b4:	00003517          	auipc	a0,0x3
    800056b8:	08c50513          	addi	a0,a0,140 # 80008740 <syscalls+0x2d0>
    800056bc:	ffffb097          	auipc	ra,0xffffb
    800056c0:	e82080e7          	jalr	-382(ra) # 8000053e <panic>
    panic("create: dirlink");
    800056c4:	00003517          	auipc	a0,0x3
    800056c8:	08c50513          	addi	a0,a0,140 # 80008750 <syscalls+0x2e0>
    800056cc:	ffffb097          	auipc	ra,0xffffb
    800056d0:	e72080e7          	jalr	-398(ra) # 8000053e <panic>
    return 0;
    800056d4:	84aa                	mv	s1,a0
    800056d6:	b731                	j	800055e2 <create+0x72>

00000000800056d8 <sys_dup>:
{
    800056d8:	7179                	addi	sp,sp,-48
    800056da:	f406                	sd	ra,40(sp)
    800056dc:	f022                	sd	s0,32(sp)
    800056de:	ec26                	sd	s1,24(sp)
    800056e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056e2:	fd840613          	addi	a2,s0,-40
    800056e6:	4581                	li	a1,0
    800056e8:	4501                	li	a0,0
    800056ea:	00000097          	auipc	ra,0x0
    800056ee:	ddc080e7          	jalr	-548(ra) # 800054c6 <argfd>
    return -1;
    800056f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056f4:	02054363          	bltz	a0,8000571a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056f8:	fd843503          	ld	a0,-40(s0)
    800056fc:	00000097          	auipc	ra,0x0
    80005700:	e32080e7          	jalr	-462(ra) # 8000552e <fdalloc>
    80005704:	84aa                	mv	s1,a0
    return -1;
    80005706:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005708:	00054963          	bltz	a0,8000571a <sys_dup+0x42>
  filedup(f);
    8000570c:	fd843503          	ld	a0,-40(s0)
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	37a080e7          	jalr	890(ra) # 80004a8a <filedup>
  return fd;
    80005718:	87a6                	mv	a5,s1
}
    8000571a:	853e                	mv	a0,a5
    8000571c:	70a2                	ld	ra,40(sp)
    8000571e:	7402                	ld	s0,32(sp)
    80005720:	64e2                	ld	s1,24(sp)
    80005722:	6145                	addi	sp,sp,48
    80005724:	8082                	ret

0000000080005726 <sys_read>:
{
    80005726:	7179                	addi	sp,sp,-48
    80005728:	f406                	sd	ra,40(sp)
    8000572a:	f022                	sd	s0,32(sp)
    8000572c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000572e:	fe840613          	addi	a2,s0,-24
    80005732:	4581                	li	a1,0
    80005734:	4501                	li	a0,0
    80005736:	00000097          	auipc	ra,0x0
    8000573a:	d90080e7          	jalr	-624(ra) # 800054c6 <argfd>
    return -1;
    8000573e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005740:	04054163          	bltz	a0,80005782 <sys_read+0x5c>
    80005744:	fe440593          	addi	a1,s0,-28
    80005748:	4509                	li	a0,2
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	938080e7          	jalr	-1736(ra) # 80003082 <argint>
    return -1;
    80005752:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005754:	02054763          	bltz	a0,80005782 <sys_read+0x5c>
    80005758:	fd840593          	addi	a1,s0,-40
    8000575c:	4505                	li	a0,1
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	946080e7          	jalr	-1722(ra) # 800030a4 <argaddr>
    return -1;
    80005766:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005768:	00054d63          	bltz	a0,80005782 <sys_read+0x5c>
  return fileread(f, p, n);
    8000576c:	fe442603          	lw	a2,-28(s0)
    80005770:	fd843583          	ld	a1,-40(s0)
    80005774:	fe843503          	ld	a0,-24(s0)
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	49e080e7          	jalr	1182(ra) # 80004c16 <fileread>
    80005780:	87aa                	mv	a5,a0
}
    80005782:	853e                	mv	a0,a5
    80005784:	70a2                	ld	ra,40(sp)
    80005786:	7402                	ld	s0,32(sp)
    80005788:	6145                	addi	sp,sp,48
    8000578a:	8082                	ret

000000008000578c <sys_write>:
{
    8000578c:	7179                	addi	sp,sp,-48
    8000578e:	f406                	sd	ra,40(sp)
    80005790:	f022                	sd	s0,32(sp)
    80005792:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005794:	fe840613          	addi	a2,s0,-24
    80005798:	4581                	li	a1,0
    8000579a:	4501                	li	a0,0
    8000579c:	00000097          	auipc	ra,0x0
    800057a0:	d2a080e7          	jalr	-726(ra) # 800054c6 <argfd>
    return -1;
    800057a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a6:	04054163          	bltz	a0,800057e8 <sys_write+0x5c>
    800057aa:	fe440593          	addi	a1,s0,-28
    800057ae:	4509                	li	a0,2
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	8d2080e7          	jalr	-1838(ra) # 80003082 <argint>
    return -1;
    800057b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ba:	02054763          	bltz	a0,800057e8 <sys_write+0x5c>
    800057be:	fd840593          	addi	a1,s0,-40
    800057c2:	4505                	li	a0,1
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	8e0080e7          	jalr	-1824(ra) # 800030a4 <argaddr>
    return -1;
    800057cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ce:	00054d63          	bltz	a0,800057e8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800057d2:	fe442603          	lw	a2,-28(s0)
    800057d6:	fd843583          	ld	a1,-40(s0)
    800057da:	fe843503          	ld	a0,-24(s0)
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	4fa080e7          	jalr	1274(ra) # 80004cd8 <filewrite>
    800057e6:	87aa                	mv	a5,a0
}
    800057e8:	853e                	mv	a0,a5
    800057ea:	70a2                	ld	ra,40(sp)
    800057ec:	7402                	ld	s0,32(sp)
    800057ee:	6145                	addi	sp,sp,48
    800057f0:	8082                	ret

00000000800057f2 <sys_close>:
{
    800057f2:	1101                	addi	sp,sp,-32
    800057f4:	ec06                	sd	ra,24(sp)
    800057f6:	e822                	sd	s0,16(sp)
    800057f8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057fa:	fe040613          	addi	a2,s0,-32
    800057fe:	fec40593          	addi	a1,s0,-20
    80005802:	4501                	li	a0,0
    80005804:	00000097          	auipc	ra,0x0
    80005808:	cc2080e7          	jalr	-830(ra) # 800054c6 <argfd>
    return -1;
    8000580c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000580e:	02054463          	bltz	a0,80005836 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005812:	ffffc097          	auipc	ra,0xffffc
    80005816:	0f4080e7          	jalr	244(ra) # 80001906 <myproc>
    8000581a:	fec42783          	lw	a5,-20(s0)
    8000581e:	07f9                	addi	a5,a5,30
    80005820:	078e                	slli	a5,a5,0x3
    80005822:	97aa                	add	a5,a5,a0
    80005824:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005828:	fe043503          	ld	a0,-32(s0)
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	2b0080e7          	jalr	688(ra) # 80004adc <fileclose>
  return 0;
    80005834:	4781                	li	a5,0
}
    80005836:	853e                	mv	a0,a5
    80005838:	60e2                	ld	ra,24(sp)
    8000583a:	6442                	ld	s0,16(sp)
    8000583c:	6105                	addi	sp,sp,32
    8000583e:	8082                	ret

0000000080005840 <sys_fstat>:
{
    80005840:	1101                	addi	sp,sp,-32
    80005842:	ec06                	sd	ra,24(sp)
    80005844:	e822                	sd	s0,16(sp)
    80005846:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005848:	fe840613          	addi	a2,s0,-24
    8000584c:	4581                	li	a1,0
    8000584e:	4501                	li	a0,0
    80005850:	00000097          	auipc	ra,0x0
    80005854:	c76080e7          	jalr	-906(ra) # 800054c6 <argfd>
    return -1;
    80005858:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000585a:	02054563          	bltz	a0,80005884 <sys_fstat+0x44>
    8000585e:	fe040593          	addi	a1,s0,-32
    80005862:	4505                	li	a0,1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	840080e7          	jalr	-1984(ra) # 800030a4 <argaddr>
    return -1;
    8000586c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000586e:	00054b63          	bltz	a0,80005884 <sys_fstat+0x44>
  return filestat(f, st);
    80005872:	fe043583          	ld	a1,-32(s0)
    80005876:	fe843503          	ld	a0,-24(s0)
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	32a080e7          	jalr	810(ra) # 80004ba4 <filestat>
    80005882:	87aa                	mv	a5,a0
}
    80005884:	853e                	mv	a0,a5
    80005886:	60e2                	ld	ra,24(sp)
    80005888:	6442                	ld	s0,16(sp)
    8000588a:	6105                	addi	sp,sp,32
    8000588c:	8082                	ret

000000008000588e <sys_link>:
{
    8000588e:	7169                	addi	sp,sp,-304
    80005890:	f606                	sd	ra,296(sp)
    80005892:	f222                	sd	s0,288(sp)
    80005894:	ee26                	sd	s1,280(sp)
    80005896:	ea4a                	sd	s2,272(sp)
    80005898:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000589a:	08000613          	li	a2,128
    8000589e:	ed040593          	addi	a1,s0,-304
    800058a2:	4501                	li	a0,0
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	822080e7          	jalr	-2014(ra) # 800030c6 <argstr>
    return -1;
    800058ac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ae:	10054e63          	bltz	a0,800059ca <sys_link+0x13c>
    800058b2:	08000613          	li	a2,128
    800058b6:	f5040593          	addi	a1,s0,-176
    800058ba:	4505                	li	a0,1
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	80a080e7          	jalr	-2038(ra) # 800030c6 <argstr>
    return -1;
    800058c4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058c6:	10054263          	bltz	a0,800059ca <sys_link+0x13c>
  begin_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	d46080e7          	jalr	-698(ra) # 80004610 <begin_op>
  if((ip = namei(old)) == 0){
    800058d2:	ed040513          	addi	a0,s0,-304
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	b1e080e7          	jalr	-1250(ra) # 800043f4 <namei>
    800058de:	84aa                	mv	s1,a0
    800058e0:	c551                	beqz	a0,8000596c <sys_link+0xde>
  ilock(ip);
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	35c080e7          	jalr	860(ra) # 80003c3e <ilock>
  if(ip->type == T_DIR){
    800058ea:	04449703          	lh	a4,68(s1)
    800058ee:	4785                	li	a5,1
    800058f0:	08f70463          	beq	a4,a5,80005978 <sys_link+0xea>
  ip->nlink++;
    800058f4:	04a4d783          	lhu	a5,74(s1)
    800058f8:	2785                	addiw	a5,a5,1
    800058fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058fe:	8526                	mv	a0,s1
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	274080e7          	jalr	628(ra) # 80003b74 <iupdate>
  iunlock(ip);
    80005908:	8526                	mv	a0,s1
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	3f6080e7          	jalr	1014(ra) # 80003d00 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005912:	fd040593          	addi	a1,s0,-48
    80005916:	f5040513          	addi	a0,s0,-176
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	af8080e7          	jalr	-1288(ra) # 80004412 <nameiparent>
    80005922:	892a                	mv	s2,a0
    80005924:	c935                	beqz	a0,80005998 <sys_link+0x10a>
  ilock(dp);
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	318080e7          	jalr	792(ra) # 80003c3e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000592e:	00092703          	lw	a4,0(s2)
    80005932:	409c                	lw	a5,0(s1)
    80005934:	04f71d63          	bne	a4,a5,8000598e <sys_link+0x100>
    80005938:	40d0                	lw	a2,4(s1)
    8000593a:	fd040593          	addi	a1,s0,-48
    8000593e:	854a                	mv	a0,s2
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	9f2080e7          	jalr	-1550(ra) # 80004332 <dirlink>
    80005948:	04054363          	bltz	a0,8000598e <sys_link+0x100>
  iunlockput(dp);
    8000594c:	854a                	mv	a0,s2
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	552080e7          	jalr	1362(ra) # 80003ea0 <iunlockput>
  iput(ip);
    80005956:	8526                	mv	a0,s1
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	4a0080e7          	jalr	1184(ra) # 80003df8 <iput>
  end_op();
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	d30080e7          	jalr	-720(ra) # 80004690 <end_op>
  return 0;
    80005968:	4781                	li	a5,0
    8000596a:	a085                	j	800059ca <sys_link+0x13c>
    end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	d24080e7          	jalr	-732(ra) # 80004690 <end_op>
    return -1;
    80005974:	57fd                	li	a5,-1
    80005976:	a891                	j	800059ca <sys_link+0x13c>
    iunlockput(ip);
    80005978:	8526                	mv	a0,s1
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	526080e7          	jalr	1318(ra) # 80003ea0 <iunlockput>
    end_op();
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	d0e080e7          	jalr	-754(ra) # 80004690 <end_op>
    return -1;
    8000598a:	57fd                	li	a5,-1
    8000598c:	a83d                	j	800059ca <sys_link+0x13c>
    iunlockput(dp);
    8000598e:	854a                	mv	a0,s2
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	510080e7          	jalr	1296(ra) # 80003ea0 <iunlockput>
  ilock(ip);
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	2a4080e7          	jalr	676(ra) # 80003c3e <ilock>
  ip->nlink--;
    800059a2:	04a4d783          	lhu	a5,74(s1)
    800059a6:	37fd                	addiw	a5,a5,-1
    800059a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059ac:	8526                	mv	a0,s1
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	1c6080e7          	jalr	454(ra) # 80003b74 <iupdate>
  iunlockput(ip);
    800059b6:	8526                	mv	a0,s1
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	4e8080e7          	jalr	1256(ra) # 80003ea0 <iunlockput>
  end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	cd0080e7          	jalr	-816(ra) # 80004690 <end_op>
  return -1;
    800059c8:	57fd                	li	a5,-1
}
    800059ca:	853e                	mv	a0,a5
    800059cc:	70b2                	ld	ra,296(sp)
    800059ce:	7412                	ld	s0,288(sp)
    800059d0:	64f2                	ld	s1,280(sp)
    800059d2:	6952                	ld	s2,272(sp)
    800059d4:	6155                	addi	sp,sp,304
    800059d6:	8082                	ret

00000000800059d8 <sys_unlink>:
{
    800059d8:	7151                	addi	sp,sp,-240
    800059da:	f586                	sd	ra,232(sp)
    800059dc:	f1a2                	sd	s0,224(sp)
    800059de:	eda6                	sd	s1,216(sp)
    800059e0:	e9ca                	sd	s2,208(sp)
    800059e2:	e5ce                	sd	s3,200(sp)
    800059e4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059e6:	08000613          	li	a2,128
    800059ea:	f3040593          	addi	a1,s0,-208
    800059ee:	4501                	li	a0,0
    800059f0:	ffffd097          	auipc	ra,0xffffd
    800059f4:	6d6080e7          	jalr	1750(ra) # 800030c6 <argstr>
    800059f8:	18054163          	bltz	a0,80005b7a <sys_unlink+0x1a2>
  begin_op();
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	c14080e7          	jalr	-1004(ra) # 80004610 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a04:	fb040593          	addi	a1,s0,-80
    80005a08:	f3040513          	addi	a0,s0,-208
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	a06080e7          	jalr	-1530(ra) # 80004412 <nameiparent>
    80005a14:	84aa                	mv	s1,a0
    80005a16:	c979                	beqz	a0,80005aec <sys_unlink+0x114>
  ilock(dp);
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	226080e7          	jalr	550(ra) # 80003c3e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a20:	00003597          	auipc	a1,0x3
    80005a24:	d1058593          	addi	a1,a1,-752 # 80008730 <syscalls+0x2c0>
    80005a28:	fb040513          	addi	a0,s0,-80
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	6dc080e7          	jalr	1756(ra) # 80004108 <namecmp>
    80005a34:	14050a63          	beqz	a0,80005b88 <sys_unlink+0x1b0>
    80005a38:	00003597          	auipc	a1,0x3
    80005a3c:	d0058593          	addi	a1,a1,-768 # 80008738 <syscalls+0x2c8>
    80005a40:	fb040513          	addi	a0,s0,-80
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	6c4080e7          	jalr	1732(ra) # 80004108 <namecmp>
    80005a4c:	12050e63          	beqz	a0,80005b88 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a50:	f2c40613          	addi	a2,s0,-212
    80005a54:	fb040593          	addi	a1,s0,-80
    80005a58:	8526                	mv	a0,s1
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	6c8080e7          	jalr	1736(ra) # 80004122 <dirlookup>
    80005a62:	892a                	mv	s2,a0
    80005a64:	12050263          	beqz	a0,80005b88 <sys_unlink+0x1b0>
  ilock(ip);
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	1d6080e7          	jalr	470(ra) # 80003c3e <ilock>
  if(ip->nlink < 1)
    80005a70:	04a91783          	lh	a5,74(s2)
    80005a74:	08f05263          	blez	a5,80005af8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a78:	04491703          	lh	a4,68(s2)
    80005a7c:	4785                	li	a5,1
    80005a7e:	08f70563          	beq	a4,a5,80005b08 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a82:	4641                	li	a2,16
    80005a84:	4581                	li	a1,0
    80005a86:	fc040513          	addi	a0,s0,-64
    80005a8a:	ffffb097          	auipc	ra,0xffffb
    80005a8e:	256080e7          	jalr	598(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a92:	4741                	li	a4,16
    80005a94:	f2c42683          	lw	a3,-212(s0)
    80005a98:	fc040613          	addi	a2,s0,-64
    80005a9c:	4581                	li	a1,0
    80005a9e:	8526                	mv	a0,s1
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	54a080e7          	jalr	1354(ra) # 80003fea <writei>
    80005aa8:	47c1                	li	a5,16
    80005aaa:	0af51563          	bne	a0,a5,80005b54 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005aae:	04491703          	lh	a4,68(s2)
    80005ab2:	4785                	li	a5,1
    80005ab4:	0af70863          	beq	a4,a5,80005b64 <sys_unlink+0x18c>
  iunlockput(dp);
    80005ab8:	8526                	mv	a0,s1
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	3e6080e7          	jalr	998(ra) # 80003ea0 <iunlockput>
  ip->nlink--;
    80005ac2:	04a95783          	lhu	a5,74(s2)
    80005ac6:	37fd                	addiw	a5,a5,-1
    80005ac8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005acc:	854a                	mv	a0,s2
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	0a6080e7          	jalr	166(ra) # 80003b74 <iupdate>
  iunlockput(ip);
    80005ad6:	854a                	mv	a0,s2
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	3c8080e7          	jalr	968(ra) # 80003ea0 <iunlockput>
  end_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	bb0080e7          	jalr	-1104(ra) # 80004690 <end_op>
  return 0;
    80005ae8:	4501                	li	a0,0
    80005aea:	a84d                	j	80005b9c <sys_unlink+0x1c4>
    end_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	ba4080e7          	jalr	-1116(ra) # 80004690 <end_op>
    return -1;
    80005af4:	557d                	li	a0,-1
    80005af6:	a05d                	j	80005b9c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005af8:	00003517          	auipc	a0,0x3
    80005afc:	c6850513          	addi	a0,a0,-920 # 80008760 <syscalls+0x2f0>
    80005b00:	ffffb097          	auipc	ra,0xffffb
    80005b04:	a3e080e7          	jalr	-1474(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b08:	04c92703          	lw	a4,76(s2)
    80005b0c:	02000793          	li	a5,32
    80005b10:	f6e7f9e3          	bgeu	a5,a4,80005a82 <sys_unlink+0xaa>
    80005b14:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b18:	4741                	li	a4,16
    80005b1a:	86ce                	mv	a3,s3
    80005b1c:	f1840613          	addi	a2,s0,-232
    80005b20:	4581                	li	a1,0
    80005b22:	854a                	mv	a0,s2
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	3ce080e7          	jalr	974(ra) # 80003ef2 <readi>
    80005b2c:	47c1                	li	a5,16
    80005b2e:	00f51b63          	bne	a0,a5,80005b44 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b32:	f1845783          	lhu	a5,-232(s0)
    80005b36:	e7a1                	bnez	a5,80005b7e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b38:	29c1                	addiw	s3,s3,16
    80005b3a:	04c92783          	lw	a5,76(s2)
    80005b3e:	fcf9ede3          	bltu	s3,a5,80005b18 <sys_unlink+0x140>
    80005b42:	b781                	j	80005a82 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b44:	00003517          	auipc	a0,0x3
    80005b48:	c3450513          	addi	a0,a0,-972 # 80008778 <syscalls+0x308>
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	9f2080e7          	jalr	-1550(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b54:	00003517          	auipc	a0,0x3
    80005b58:	c3c50513          	addi	a0,a0,-964 # 80008790 <syscalls+0x320>
    80005b5c:	ffffb097          	auipc	ra,0xffffb
    80005b60:	9e2080e7          	jalr	-1566(ra) # 8000053e <panic>
    dp->nlink--;
    80005b64:	04a4d783          	lhu	a5,74(s1)
    80005b68:	37fd                	addiw	a5,a5,-1
    80005b6a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b6e:	8526                	mv	a0,s1
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	004080e7          	jalr	4(ra) # 80003b74 <iupdate>
    80005b78:	b781                	j	80005ab8 <sys_unlink+0xe0>
    return -1;
    80005b7a:	557d                	li	a0,-1
    80005b7c:	a005                	j	80005b9c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b7e:	854a                	mv	a0,s2
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	320080e7          	jalr	800(ra) # 80003ea0 <iunlockput>
  iunlockput(dp);
    80005b88:	8526                	mv	a0,s1
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	316080e7          	jalr	790(ra) # 80003ea0 <iunlockput>
  end_op();
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	afe080e7          	jalr	-1282(ra) # 80004690 <end_op>
  return -1;
    80005b9a:	557d                	li	a0,-1
}
    80005b9c:	70ae                	ld	ra,232(sp)
    80005b9e:	740e                	ld	s0,224(sp)
    80005ba0:	64ee                	ld	s1,216(sp)
    80005ba2:	694e                	ld	s2,208(sp)
    80005ba4:	69ae                	ld	s3,200(sp)
    80005ba6:	616d                	addi	sp,sp,240
    80005ba8:	8082                	ret

0000000080005baa <sys_open>:

uint64
sys_open(void)
{
    80005baa:	7131                	addi	sp,sp,-192
    80005bac:	fd06                	sd	ra,184(sp)
    80005bae:	f922                	sd	s0,176(sp)
    80005bb0:	f526                	sd	s1,168(sp)
    80005bb2:	f14a                	sd	s2,160(sp)
    80005bb4:	ed4e                	sd	s3,152(sp)
    80005bb6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bb8:	08000613          	li	a2,128
    80005bbc:	f5040593          	addi	a1,s0,-176
    80005bc0:	4501                	li	a0,0
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	504080e7          	jalr	1284(ra) # 800030c6 <argstr>
    return -1;
    80005bca:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bcc:	0c054163          	bltz	a0,80005c8e <sys_open+0xe4>
    80005bd0:	f4c40593          	addi	a1,s0,-180
    80005bd4:	4505                	li	a0,1
    80005bd6:	ffffd097          	auipc	ra,0xffffd
    80005bda:	4ac080e7          	jalr	1196(ra) # 80003082 <argint>
    80005bde:	0a054863          	bltz	a0,80005c8e <sys_open+0xe4>

  begin_op();
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	a2e080e7          	jalr	-1490(ra) # 80004610 <begin_op>

  if(omode & O_CREATE){
    80005bea:	f4c42783          	lw	a5,-180(s0)
    80005bee:	2007f793          	andi	a5,a5,512
    80005bf2:	cbdd                	beqz	a5,80005ca8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005bf4:	4681                	li	a3,0
    80005bf6:	4601                	li	a2,0
    80005bf8:	4589                	li	a1,2
    80005bfa:	f5040513          	addi	a0,s0,-176
    80005bfe:	00000097          	auipc	ra,0x0
    80005c02:	972080e7          	jalr	-1678(ra) # 80005570 <create>
    80005c06:	892a                	mv	s2,a0
    if(ip == 0){
    80005c08:	c959                	beqz	a0,80005c9e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c0a:	04491703          	lh	a4,68(s2)
    80005c0e:	478d                	li	a5,3
    80005c10:	00f71763          	bne	a4,a5,80005c1e <sys_open+0x74>
    80005c14:	04695703          	lhu	a4,70(s2)
    80005c18:	47a5                	li	a5,9
    80005c1a:	0ce7ec63          	bltu	a5,a4,80005cf2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	e02080e7          	jalr	-510(ra) # 80004a20 <filealloc>
    80005c26:	89aa                	mv	s3,a0
    80005c28:	10050263          	beqz	a0,80005d2c <sys_open+0x182>
    80005c2c:	00000097          	auipc	ra,0x0
    80005c30:	902080e7          	jalr	-1790(ra) # 8000552e <fdalloc>
    80005c34:	84aa                	mv	s1,a0
    80005c36:	0e054663          	bltz	a0,80005d22 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c3a:	04491703          	lh	a4,68(s2)
    80005c3e:	478d                	li	a5,3
    80005c40:	0cf70463          	beq	a4,a5,80005d08 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c44:	4789                	li	a5,2
    80005c46:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c4a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c4e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c52:	f4c42783          	lw	a5,-180(s0)
    80005c56:	0017c713          	xori	a4,a5,1
    80005c5a:	8b05                	andi	a4,a4,1
    80005c5c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c60:	0037f713          	andi	a4,a5,3
    80005c64:	00e03733          	snez	a4,a4
    80005c68:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c6c:	4007f793          	andi	a5,a5,1024
    80005c70:	c791                	beqz	a5,80005c7c <sys_open+0xd2>
    80005c72:	04491703          	lh	a4,68(s2)
    80005c76:	4789                	li	a5,2
    80005c78:	08f70f63          	beq	a4,a5,80005d16 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c7c:	854a                	mv	a0,s2
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	082080e7          	jalr	130(ra) # 80003d00 <iunlock>
  end_op();
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	a0a080e7          	jalr	-1526(ra) # 80004690 <end_op>

  return fd;
}
    80005c8e:	8526                	mv	a0,s1
    80005c90:	70ea                	ld	ra,184(sp)
    80005c92:	744a                	ld	s0,176(sp)
    80005c94:	74aa                	ld	s1,168(sp)
    80005c96:	790a                	ld	s2,160(sp)
    80005c98:	69ea                	ld	s3,152(sp)
    80005c9a:	6129                	addi	sp,sp,192
    80005c9c:	8082                	ret
      end_op();
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	9f2080e7          	jalr	-1550(ra) # 80004690 <end_op>
      return -1;
    80005ca6:	b7e5                	j	80005c8e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ca8:	f5040513          	addi	a0,s0,-176
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	748080e7          	jalr	1864(ra) # 800043f4 <namei>
    80005cb4:	892a                	mv	s2,a0
    80005cb6:	c905                	beqz	a0,80005ce6 <sys_open+0x13c>
    ilock(ip);
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	f86080e7          	jalr	-122(ra) # 80003c3e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cc0:	04491703          	lh	a4,68(s2)
    80005cc4:	4785                	li	a5,1
    80005cc6:	f4f712e3          	bne	a4,a5,80005c0a <sys_open+0x60>
    80005cca:	f4c42783          	lw	a5,-180(s0)
    80005cce:	dba1                	beqz	a5,80005c1e <sys_open+0x74>
      iunlockput(ip);
    80005cd0:	854a                	mv	a0,s2
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	1ce080e7          	jalr	462(ra) # 80003ea0 <iunlockput>
      end_op();
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	9b6080e7          	jalr	-1610(ra) # 80004690 <end_op>
      return -1;
    80005ce2:	54fd                	li	s1,-1
    80005ce4:	b76d                	j	80005c8e <sys_open+0xe4>
      end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	9aa080e7          	jalr	-1622(ra) # 80004690 <end_op>
      return -1;
    80005cee:	54fd                	li	s1,-1
    80005cf0:	bf79                	j	80005c8e <sys_open+0xe4>
    iunlockput(ip);
    80005cf2:	854a                	mv	a0,s2
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	1ac080e7          	jalr	428(ra) # 80003ea0 <iunlockput>
    end_op();
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	994080e7          	jalr	-1644(ra) # 80004690 <end_op>
    return -1;
    80005d04:	54fd                	li	s1,-1
    80005d06:	b761                	j	80005c8e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d08:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d0c:	04691783          	lh	a5,70(s2)
    80005d10:	02f99223          	sh	a5,36(s3)
    80005d14:	bf2d                	j	80005c4e <sys_open+0xa4>
    itrunc(ip);
    80005d16:	854a                	mv	a0,s2
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	034080e7          	jalr	52(ra) # 80003d4c <itrunc>
    80005d20:	bfb1                	j	80005c7c <sys_open+0xd2>
      fileclose(f);
    80005d22:	854e                	mv	a0,s3
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	db8080e7          	jalr	-584(ra) # 80004adc <fileclose>
    iunlockput(ip);
    80005d2c:	854a                	mv	a0,s2
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	172080e7          	jalr	370(ra) # 80003ea0 <iunlockput>
    end_op();
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	95a080e7          	jalr	-1702(ra) # 80004690 <end_op>
    return -1;
    80005d3e:	54fd                	li	s1,-1
    80005d40:	b7b9                	j	80005c8e <sys_open+0xe4>

0000000080005d42 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d42:	7175                	addi	sp,sp,-144
    80005d44:	e506                	sd	ra,136(sp)
    80005d46:	e122                	sd	s0,128(sp)
    80005d48:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	8c6080e7          	jalr	-1850(ra) # 80004610 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d52:	08000613          	li	a2,128
    80005d56:	f7040593          	addi	a1,s0,-144
    80005d5a:	4501                	li	a0,0
    80005d5c:	ffffd097          	auipc	ra,0xffffd
    80005d60:	36a080e7          	jalr	874(ra) # 800030c6 <argstr>
    80005d64:	02054963          	bltz	a0,80005d96 <sys_mkdir+0x54>
    80005d68:	4681                	li	a3,0
    80005d6a:	4601                	li	a2,0
    80005d6c:	4585                	li	a1,1
    80005d6e:	f7040513          	addi	a0,s0,-144
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	7fe080e7          	jalr	2046(ra) # 80005570 <create>
    80005d7a:	cd11                	beqz	a0,80005d96 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	124080e7          	jalr	292(ra) # 80003ea0 <iunlockput>
  end_op();
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	90c080e7          	jalr	-1780(ra) # 80004690 <end_op>
  return 0;
    80005d8c:	4501                	li	a0,0
}
    80005d8e:	60aa                	ld	ra,136(sp)
    80005d90:	640a                	ld	s0,128(sp)
    80005d92:	6149                	addi	sp,sp,144
    80005d94:	8082                	ret
    end_op();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	8fa080e7          	jalr	-1798(ra) # 80004690 <end_op>
    return -1;
    80005d9e:	557d                	li	a0,-1
    80005da0:	b7fd                	j	80005d8e <sys_mkdir+0x4c>

0000000080005da2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005da2:	7135                	addi	sp,sp,-160
    80005da4:	ed06                	sd	ra,152(sp)
    80005da6:	e922                	sd	s0,144(sp)
    80005da8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	866080e7          	jalr	-1946(ra) # 80004610 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005db2:	08000613          	li	a2,128
    80005db6:	f7040593          	addi	a1,s0,-144
    80005dba:	4501                	li	a0,0
    80005dbc:	ffffd097          	auipc	ra,0xffffd
    80005dc0:	30a080e7          	jalr	778(ra) # 800030c6 <argstr>
    80005dc4:	04054a63          	bltz	a0,80005e18 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005dc8:	f6c40593          	addi	a1,s0,-148
    80005dcc:	4505                	li	a0,1
    80005dce:	ffffd097          	auipc	ra,0xffffd
    80005dd2:	2b4080e7          	jalr	692(ra) # 80003082 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dd6:	04054163          	bltz	a0,80005e18 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005dda:	f6840593          	addi	a1,s0,-152
    80005dde:	4509                	li	a0,2
    80005de0:	ffffd097          	auipc	ra,0xffffd
    80005de4:	2a2080e7          	jalr	674(ra) # 80003082 <argint>
     argint(1, &major) < 0 ||
    80005de8:	02054863          	bltz	a0,80005e18 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dec:	f6841683          	lh	a3,-152(s0)
    80005df0:	f6c41603          	lh	a2,-148(s0)
    80005df4:	458d                	li	a1,3
    80005df6:	f7040513          	addi	a0,s0,-144
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	776080e7          	jalr	1910(ra) # 80005570 <create>
     argint(2, &minor) < 0 ||
    80005e02:	c919                	beqz	a0,80005e18 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	09c080e7          	jalr	156(ra) # 80003ea0 <iunlockput>
  end_op();
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	884080e7          	jalr	-1916(ra) # 80004690 <end_op>
  return 0;
    80005e14:	4501                	li	a0,0
    80005e16:	a031                	j	80005e22 <sys_mknod+0x80>
    end_op();
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	878080e7          	jalr	-1928(ra) # 80004690 <end_op>
    return -1;
    80005e20:	557d                	li	a0,-1
}
    80005e22:	60ea                	ld	ra,152(sp)
    80005e24:	644a                	ld	s0,144(sp)
    80005e26:	610d                	addi	sp,sp,160
    80005e28:	8082                	ret

0000000080005e2a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e2a:	7135                	addi	sp,sp,-160
    80005e2c:	ed06                	sd	ra,152(sp)
    80005e2e:	e922                	sd	s0,144(sp)
    80005e30:	e526                	sd	s1,136(sp)
    80005e32:	e14a                	sd	s2,128(sp)
    80005e34:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e36:	ffffc097          	auipc	ra,0xffffc
    80005e3a:	ad0080e7          	jalr	-1328(ra) # 80001906 <myproc>
    80005e3e:	892a                	mv	s2,a0
  
  begin_op();
    80005e40:	ffffe097          	auipc	ra,0xffffe
    80005e44:	7d0080e7          	jalr	2000(ra) # 80004610 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e48:	08000613          	li	a2,128
    80005e4c:	f6040593          	addi	a1,s0,-160
    80005e50:	4501                	li	a0,0
    80005e52:	ffffd097          	auipc	ra,0xffffd
    80005e56:	274080e7          	jalr	628(ra) # 800030c6 <argstr>
    80005e5a:	04054b63          	bltz	a0,80005eb0 <sys_chdir+0x86>
    80005e5e:	f6040513          	addi	a0,s0,-160
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	592080e7          	jalr	1426(ra) # 800043f4 <namei>
    80005e6a:	84aa                	mv	s1,a0
    80005e6c:	c131                	beqz	a0,80005eb0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	dd0080e7          	jalr	-560(ra) # 80003c3e <ilock>
  if(ip->type != T_DIR){
    80005e76:	04449703          	lh	a4,68(s1)
    80005e7a:	4785                	li	a5,1
    80005e7c:	04f71063          	bne	a4,a5,80005ebc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e80:	8526                	mv	a0,s1
    80005e82:	ffffe097          	auipc	ra,0xffffe
    80005e86:	e7e080e7          	jalr	-386(ra) # 80003d00 <iunlock>
  iput(p->cwd);
    80005e8a:	17093503          	ld	a0,368(s2)
    80005e8e:	ffffe097          	auipc	ra,0xffffe
    80005e92:	f6a080e7          	jalr	-150(ra) # 80003df8 <iput>
  end_op();
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	7fa080e7          	jalr	2042(ra) # 80004690 <end_op>
  p->cwd = ip;
    80005e9e:	16993823          	sd	s1,368(s2)
  return 0;
    80005ea2:	4501                	li	a0,0
}
    80005ea4:	60ea                	ld	ra,152(sp)
    80005ea6:	644a                	ld	s0,144(sp)
    80005ea8:	64aa                	ld	s1,136(sp)
    80005eaa:	690a                	ld	s2,128(sp)
    80005eac:	610d                	addi	sp,sp,160
    80005eae:	8082                	ret
    end_op();
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	7e0080e7          	jalr	2016(ra) # 80004690 <end_op>
    return -1;
    80005eb8:	557d                	li	a0,-1
    80005eba:	b7ed                	j	80005ea4 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ebc:	8526                	mv	a0,s1
    80005ebe:	ffffe097          	auipc	ra,0xffffe
    80005ec2:	fe2080e7          	jalr	-30(ra) # 80003ea0 <iunlockput>
    end_op();
    80005ec6:	ffffe097          	auipc	ra,0xffffe
    80005eca:	7ca080e7          	jalr	1994(ra) # 80004690 <end_op>
    return -1;
    80005ece:	557d                	li	a0,-1
    80005ed0:	bfd1                	j	80005ea4 <sys_chdir+0x7a>

0000000080005ed2 <sys_exec>:

uint64
sys_exec(void)
{
    80005ed2:	7145                	addi	sp,sp,-464
    80005ed4:	e786                	sd	ra,456(sp)
    80005ed6:	e3a2                	sd	s0,448(sp)
    80005ed8:	ff26                	sd	s1,440(sp)
    80005eda:	fb4a                	sd	s2,432(sp)
    80005edc:	f74e                	sd	s3,424(sp)
    80005ede:	f352                	sd	s4,416(sp)
    80005ee0:	ef56                	sd	s5,408(sp)
    80005ee2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ee4:	08000613          	li	a2,128
    80005ee8:	f4040593          	addi	a1,s0,-192
    80005eec:	4501                	li	a0,0
    80005eee:	ffffd097          	auipc	ra,0xffffd
    80005ef2:	1d8080e7          	jalr	472(ra) # 800030c6 <argstr>
    return -1;
    80005ef6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ef8:	0c054a63          	bltz	a0,80005fcc <sys_exec+0xfa>
    80005efc:	e3840593          	addi	a1,s0,-456
    80005f00:	4505                	li	a0,1
    80005f02:	ffffd097          	auipc	ra,0xffffd
    80005f06:	1a2080e7          	jalr	418(ra) # 800030a4 <argaddr>
    80005f0a:	0c054163          	bltz	a0,80005fcc <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f0e:	10000613          	li	a2,256
    80005f12:	4581                	li	a1,0
    80005f14:	e4040513          	addi	a0,s0,-448
    80005f18:	ffffb097          	auipc	ra,0xffffb
    80005f1c:	dc8080e7          	jalr	-568(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f20:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f24:	89a6                	mv	s3,s1
    80005f26:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f28:	02000a13          	li	s4,32
    80005f2c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f30:	00391513          	slli	a0,s2,0x3
    80005f34:	e3040593          	addi	a1,s0,-464
    80005f38:	e3843783          	ld	a5,-456(s0)
    80005f3c:	953e                	add	a0,a0,a5
    80005f3e:	ffffd097          	auipc	ra,0xffffd
    80005f42:	0aa080e7          	jalr	170(ra) # 80002fe8 <fetchaddr>
    80005f46:	02054a63          	bltz	a0,80005f7a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f4a:	e3043783          	ld	a5,-464(s0)
    80005f4e:	c3b9                	beqz	a5,80005f94 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f50:	ffffb097          	auipc	ra,0xffffb
    80005f54:	ba4080e7          	jalr	-1116(ra) # 80000af4 <kalloc>
    80005f58:	85aa                	mv	a1,a0
    80005f5a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f5e:	cd11                	beqz	a0,80005f7a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f60:	6605                	lui	a2,0x1
    80005f62:	e3043503          	ld	a0,-464(s0)
    80005f66:	ffffd097          	auipc	ra,0xffffd
    80005f6a:	0d4080e7          	jalr	212(ra) # 8000303a <fetchstr>
    80005f6e:	00054663          	bltz	a0,80005f7a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f72:	0905                	addi	s2,s2,1
    80005f74:	09a1                	addi	s3,s3,8
    80005f76:	fb491be3          	bne	s2,s4,80005f2c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f7a:	10048913          	addi	s2,s1,256
    80005f7e:	6088                	ld	a0,0(s1)
    80005f80:	c529                	beqz	a0,80005fca <sys_exec+0xf8>
    kfree(argv[i]);
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	a76080e7          	jalr	-1418(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f8a:	04a1                	addi	s1,s1,8
    80005f8c:	ff2499e3          	bne	s1,s2,80005f7e <sys_exec+0xac>
  return -1;
    80005f90:	597d                	li	s2,-1
    80005f92:	a82d                	j	80005fcc <sys_exec+0xfa>
      argv[i] = 0;
    80005f94:	0a8e                	slli	s5,s5,0x3
    80005f96:	fc040793          	addi	a5,s0,-64
    80005f9a:	9abe                	add	s5,s5,a5
    80005f9c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fa0:	e4040593          	addi	a1,s0,-448
    80005fa4:	f4040513          	addi	a0,s0,-192
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	194080e7          	jalr	404(ra) # 8000513c <exec>
    80005fb0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fb2:	10048993          	addi	s3,s1,256
    80005fb6:	6088                	ld	a0,0(s1)
    80005fb8:	c911                	beqz	a0,80005fcc <sys_exec+0xfa>
    kfree(argv[i]);
    80005fba:	ffffb097          	auipc	ra,0xffffb
    80005fbe:	a3e080e7          	jalr	-1474(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc2:	04a1                	addi	s1,s1,8
    80005fc4:	ff3499e3          	bne	s1,s3,80005fb6 <sys_exec+0xe4>
    80005fc8:	a011                	j	80005fcc <sys_exec+0xfa>
  return -1;
    80005fca:	597d                	li	s2,-1
}
    80005fcc:	854a                	mv	a0,s2
    80005fce:	60be                	ld	ra,456(sp)
    80005fd0:	641e                	ld	s0,448(sp)
    80005fd2:	74fa                	ld	s1,440(sp)
    80005fd4:	795a                	ld	s2,432(sp)
    80005fd6:	79ba                	ld	s3,424(sp)
    80005fd8:	7a1a                	ld	s4,416(sp)
    80005fda:	6afa                	ld	s5,408(sp)
    80005fdc:	6179                	addi	sp,sp,464
    80005fde:	8082                	ret

0000000080005fe0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fe0:	7139                	addi	sp,sp,-64
    80005fe2:	fc06                	sd	ra,56(sp)
    80005fe4:	f822                	sd	s0,48(sp)
    80005fe6:	f426                	sd	s1,40(sp)
    80005fe8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fea:	ffffc097          	auipc	ra,0xffffc
    80005fee:	91c080e7          	jalr	-1764(ra) # 80001906 <myproc>
    80005ff2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ff4:	fd840593          	addi	a1,s0,-40
    80005ff8:	4501                	li	a0,0
    80005ffa:	ffffd097          	auipc	ra,0xffffd
    80005ffe:	0aa080e7          	jalr	170(ra) # 800030a4 <argaddr>
    return -1;
    80006002:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006004:	0e054063          	bltz	a0,800060e4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006008:	fc840593          	addi	a1,s0,-56
    8000600c:	fd040513          	addi	a0,s0,-48
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	dfc080e7          	jalr	-516(ra) # 80004e0c <pipealloc>
    return -1;
    80006018:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000601a:	0c054563          	bltz	a0,800060e4 <sys_pipe+0x104>
  fd0 = -1;
    8000601e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006022:	fd043503          	ld	a0,-48(s0)
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	508080e7          	jalr	1288(ra) # 8000552e <fdalloc>
    8000602e:	fca42223          	sw	a0,-60(s0)
    80006032:	08054c63          	bltz	a0,800060ca <sys_pipe+0xea>
    80006036:	fc843503          	ld	a0,-56(s0)
    8000603a:	fffff097          	auipc	ra,0xfffff
    8000603e:	4f4080e7          	jalr	1268(ra) # 8000552e <fdalloc>
    80006042:	fca42023          	sw	a0,-64(s0)
    80006046:	06054863          	bltz	a0,800060b6 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000604a:	4691                	li	a3,4
    8000604c:	fc440613          	addi	a2,s0,-60
    80006050:	fd843583          	ld	a1,-40(s0)
    80006054:	78a8                	ld	a0,112(s1)
    80006056:	ffffb097          	auipc	ra,0xffffb
    8000605a:	61c080e7          	jalr	1564(ra) # 80001672 <copyout>
    8000605e:	02054063          	bltz	a0,8000607e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006062:	4691                	li	a3,4
    80006064:	fc040613          	addi	a2,s0,-64
    80006068:	fd843583          	ld	a1,-40(s0)
    8000606c:	0591                	addi	a1,a1,4
    8000606e:	78a8                	ld	a0,112(s1)
    80006070:	ffffb097          	auipc	ra,0xffffb
    80006074:	602080e7          	jalr	1538(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006078:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000607a:	06055563          	bgez	a0,800060e4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000607e:	fc442783          	lw	a5,-60(s0)
    80006082:	07f9                	addi	a5,a5,30
    80006084:	078e                	slli	a5,a5,0x3
    80006086:	97a6                	add	a5,a5,s1
    80006088:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000608c:	fc042503          	lw	a0,-64(s0)
    80006090:	0579                	addi	a0,a0,30
    80006092:	050e                	slli	a0,a0,0x3
    80006094:	9526                	add	a0,a0,s1
    80006096:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000609a:	fd043503          	ld	a0,-48(s0)
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	a3e080e7          	jalr	-1474(ra) # 80004adc <fileclose>
    fileclose(wf);
    800060a6:	fc843503          	ld	a0,-56(s0)
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	a32080e7          	jalr	-1486(ra) # 80004adc <fileclose>
    return -1;
    800060b2:	57fd                	li	a5,-1
    800060b4:	a805                	j	800060e4 <sys_pipe+0x104>
    if(fd0 >= 0)
    800060b6:	fc442783          	lw	a5,-60(s0)
    800060ba:	0007c863          	bltz	a5,800060ca <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800060be:	01e78513          	addi	a0,a5,30
    800060c2:	050e                	slli	a0,a0,0x3
    800060c4:	9526                	add	a0,a0,s1
    800060c6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060ca:	fd043503          	ld	a0,-48(s0)
    800060ce:	fffff097          	auipc	ra,0xfffff
    800060d2:	a0e080e7          	jalr	-1522(ra) # 80004adc <fileclose>
    fileclose(wf);
    800060d6:	fc843503          	ld	a0,-56(s0)
    800060da:	fffff097          	auipc	ra,0xfffff
    800060de:	a02080e7          	jalr	-1534(ra) # 80004adc <fileclose>
    return -1;
    800060e2:	57fd                	li	a5,-1
}
    800060e4:	853e                	mv	a0,a5
    800060e6:	70e2                	ld	ra,56(sp)
    800060e8:	7442                	ld	s0,48(sp)
    800060ea:	74a2                	ld	s1,40(sp)
    800060ec:	6121                	addi	sp,sp,64
    800060ee:	8082                	ret

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
    80006130:	d85fc0ef          	jal	ra,80002eb4 <kerneltrap>
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
    800062b6:	0e8080e7          	jalr	232(ra) # 8000239a <wakeup>
}
    800062ba:	60a2                	ld	ra,8(sp)
    800062bc:	6402                	ld	s0,0(sp)
    800062be:	0141                	addi	sp,sp,16
    800062c0:	8082                	ret
    panic("free_desc 1");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	4de50513          	addi	a0,a0,1246 # 800087a0 <syscalls+0x330>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	274080e7          	jalr	628(ra) # 8000053e <panic>
    panic("free_desc 2");
    800062d2:	00002517          	auipc	a0,0x2
    800062d6:	4de50513          	addi	a0,a0,1246 # 800087b0 <syscalls+0x340>
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
    800062f0:	4d458593          	addi	a1,a1,1236 # 800087c0 <syscalls+0x350>
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
    800063fa:	3da50513          	addi	a0,a0,986 # 800087d0 <syscalls+0x360>
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	140080e7          	jalr	320(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006406:	00002517          	auipc	a0,0x2
    8000640a:	3ea50513          	addi	a0,a0,1002 # 800087f0 <syscalls+0x380>
    8000640e:	ffffa097          	auipc	ra,0xffffa
    80006412:	130080e7          	jalr	304(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006416:	00002517          	auipc	a0,0x2
    8000641a:	3fa50513          	addi	a0,a0,1018 # 80008810 <syscalls+0x3a0>
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
    800064f6:	b2e080e7          	jalr	-1234(ra) # 80002020 <sleep>
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
    80006640:	9e4080e7          	jalr	-1564(ra) # 80002020 <sleep>
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
    8000677e:	c20080e7          	jalr	-992(ra) # 8000239a <wakeup>

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
    800067ba:	07a50513          	addi	a0,a0,122 # 80008830 <syscalls+0x3c0>
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
