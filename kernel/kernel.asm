
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
    80000068:	05c78793          	addi	a5,a5,92 # 800060c0 <timervec>
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
    8000044a:	fd4080e7          	jalr	-44(ra) # 8000241a <wakeup>
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
    800008a4:	b7a080e7          	jalr	-1158(ra) # 8000241a <wakeup>
    
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
    80000ed8:	c8c080e7          	jalr	-884(ra) # 80002b60 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	224080e7          	jalr	548(ra) # 80006100 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	b2a080e7          	jalr	-1238(ra) # 80002a0e <scheduler>
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
    80000f50:	bec080e7          	jalr	-1044(ra) # 80002b38 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c0c080e7          	jalr	-1012(ra) # 80002b60 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	18e080e7          	jalr	398(ra) # 800060ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	19c080e7          	jalr	412(ra) # 80006100 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	380080e7          	jalr	896(ra) # 800032ec <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a10080e7          	jalr	-1520(ra) # 80003984 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9ba080e7          	jalr	-1606(ra) # 80004936 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	29e080e7          	jalr	670(ra) # 80006222 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	87c080e7          	jalr	-1924(ra) # 80002808 <userinit>
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
    80001964:	ec07a783          	lw	a5,-320(a5) # 80008820 <first.1706>
    80001968:	eb89                	bnez	a5,8000197a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000196a:	00001097          	auipc	ra,0x1
    8000196e:	20e080e7          	jalr	526(ra) # 80002b78 <usertrapret>
}
    80001972:	60a2                	ld	ra,8(sp)
    80001974:	6402                	ld	s0,0(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret
    first = 0;
    8000197a:	00007797          	auipc	a5,0x7
    8000197e:	ea07a323          	sw	zero,-346(a5) # 80008820 <first.1706>
    fsinit(ROOTDEV);
    80001982:	4505                	li	a0,1
    80001984:	00002097          	auipc	ra,0x2
    80001988:	f80080e7          	jalr	-128(ra) # 80003904 <fsinit>
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
    800019b2:	d58080e7          	jalr	-680(ra) # 80006706 <cas>
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
    80001bb0:	f22080e7          	jalr	-222(ra) # 80002ace <swtch>
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
    80001d88:	53cb8b93          	addi	s7,s7,1340 # 800082c0 <states.1745>
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
    8000208a:	680080e7          	jalr	1664(ra) # 80006706 <cas>
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
    8000213c:	892e                	mv	s2,a1
    8000213e:	89b2                	mv	s3,a2
  acquire(lock);
    80002140:	8532                	mv	a0,a2
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	aa2080e7          	jalr	-1374(ra) # 80000be4 <acquire>
  if(*curr_proc_index == -1) 
    8000214a:	0004aa03          	lw	s4,0(s1)
    8000214e:	57fd                	li	a5,-1
    80002150:	0afa0663          	beq	s4,a5,800021fc <remove_from_list+0xd6>
  {
      release(lock);
      return -1;
  }
  acquire(&proc_to_remove->proc_lock);
    80002154:	04090b13          	addi	s6,s2,64
    80002158:	855a                	mv	a0,s6
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	a8a080e7          	jalr	-1398(ra) # 80000be4 <acquire>

  if(*curr_proc_index == proc_to_remove->proc_index){
    80002162:	4088                	lw	a0,0(s1)
    80002164:	03c92783          	lw	a5,60(s2)
    80002168:	0aa78063          	beq	a5,a0,80002208 <remove_from_list+0xe2>
      release(&proc_to_remove->proc_lock);
      release(lock);
      return 1;
  }
  
  struct proc* curr_node = &proc[*curr_proc_index];
    8000216c:	18800793          	li	a5,392
    80002170:	02f50533          	mul	a0,a0,a5
    80002174:	0000f797          	auipc	a5,0xf
    80002178:	6a478793          	addi	a5,a5,1700 # 80011818 <proc>
    8000217c:	00f504b3          	add	s1,a0,a5
  acquire(&curr_node->proc_lock);
    80002180:	04050513          	addi	a0,a0,64
    80002184:	953e                	add	a0,a0,a5
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	a5e080e7          	jalr	-1442(ra) # 80000be4 <acquire>
  release(lock);
    8000218e:	854e                	mv	a0,s3
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b08080e7          	jalr	-1272(ra) # 80000c98 <release>
  
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002198:	5c88                	lw	a0,56(s1)
    8000219a:	57fd                	li	a5,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    8000219c:	18800a13          	li	s4,392
    800021a0:	0000f997          	auipc	s3,0xf
    800021a4:	67898993          	addi	s3,s3,1656 # 80011818 <proc>
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    800021a8:	5afd                	li	s5,-1
    800021aa:	02f50c63          	beq	a0,a5,800021e2 <remove_from_list+0xbc>
    800021ae:	03c92783          	lw	a5,60(s2)
    800021b2:	06a78a63          	beq	a5,a0,80002226 <remove_from_list+0x100>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    800021b6:	03450533          	mul	a0,a0,s4
    800021ba:	04050513          	addi	a0,a0,64
    800021be:	954e                	add	a0,a0,s3
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a24080e7          	jalr	-1500(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    800021c8:	04048513          	addi	a0,s1,64
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	acc080e7          	jalr	-1332(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    800021d4:	5c84                	lw	s1,56(s1)
    800021d6:	034484b3          	mul	s1,s1,s4
    800021da:	94ce                	add	s1,s1,s3
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    800021dc:	5c88                	lw	a0,56(s1)
    800021de:	fd5518e3          	bne	a0,s5,800021ae <remove_from_list+0x88>
  }
  if(curr_node->next_proc_index == -1){
    release(&proc_to_remove->proc_lock);
    800021e2:	855a                	mv	a0,s6
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	ab4080e7          	jalr	-1356(ra) # 80000c98 <release>
    release(&curr_node->proc_lock);
    800021ec:	04048513          	addi	a0,s1,64
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	aa8080e7          	jalr	-1368(ra) # 80000c98 <release>
    return -1;
    800021f8:	5a7d                	li	s4,-1
    800021fa:	a899                	j	80002250 <remove_from_list+0x12a>
      release(lock);
    800021fc:	854e                	mv	a0,s3
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	a9a080e7          	jalr	-1382(ra) # 80000c98 <release>
      return -1;
    80002206:	a0a9                	j	80002250 <remove_from_list+0x12a>
      proc_to_remove->next_proc_index = -1;
    80002208:	57fd                	li	a5,-1
    8000220a:	02f92c23          	sw	a5,56(s2)
      release(&proc_to_remove->proc_lock);
    8000220e:	855a                	mv	a0,s6
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	a88080e7          	jalr	-1400(ra) # 80000c98 <release>
      release(lock);
    80002218:	854e                	mv	a0,s3
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a7e080e7          	jalr	-1410(ra) # 80000c98 <release>
      return 1;
    80002222:	4a05                	li	s4,1
    80002224:	a035                	j	80002250 <remove_from_list+0x12a>
  if(curr_node->next_proc_index == -1){
    80002226:	57fd                	li	a5,-1
    80002228:	faf50de3          	beq	a0,a5,800021e2 <remove_from_list+0xbc>
  }

  curr_node->next_proc_index = proc_to_remove->next_proc_index;
    8000222c:	03892783          	lw	a5,56(s2)
    80002230:	dc9c                	sw	a5,56(s1)
  proc_to_remove->next_proc_index = -1;
    80002232:	57fd                	li	a5,-1
    80002234:	02f92c23          	sw	a5,56(s2)
  release(&proc_to_remove->proc_lock);
    80002238:	855a                	mv	a0,s6
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	a5e080e7          	jalr	-1442(ra) # 80000c98 <release>
  release(&curr_node->proc_lock);
    80002242:	04048513          	addi	a0,s1,64
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a52080e7          	jalr	-1454(ra) # 80000c98 <release>
  return 1;
    8000224e:	4a05                	li	s4,1
}
    80002250:	8552                	mv	a0,s4
    80002252:	70e2                	ld	ra,56(sp)
    80002254:	7442                	ld	s0,48(sp)
    80002256:	74a2                	ld	s1,40(sp)
    80002258:	7902                	ld	s2,32(sp)
    8000225a:	69e2                	ld	s3,24(sp)
    8000225c:	6a42                	ld	s4,16(sp)
    8000225e:	6aa2                	ld	s5,8(sp)
    80002260:	6b02                	ld	s6,0(sp)
    80002262:	6121                	addi	sp,sp,64
    80002264:	8082                	ret

0000000080002266 <freeproc>:
{
    80002266:	1101                	addi	sp,sp,-32
    80002268:	ec06                	sd	ra,24(sp)
    8000226a:	e822                	sd	s0,16(sp)
    8000226c:	e426                	sd	s1,8(sp)
    8000226e:	1000                	addi	s0,sp,32
    80002270:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002272:	7d28                	ld	a0,120(a0)
    80002274:	c509                	beqz	a0,8000227e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	782080e7          	jalr	1922(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    8000227e:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80002282:	78a8                	ld	a0,112(s1)
    80002284:	c511                	beqz	a0,80002290 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002286:	74ac                	ld	a1,104(s1)
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	7da080e7          	jalr	2010(ra) # 80001a62 <proc_freepagetable>
  p->pagetable = 0;
    80002290:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80002294:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80002298:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000229c:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    800022a0:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    800022a4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800022a8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800022ac:	0204a623          	sw	zero,44(s1)
  remove_from_list(&zombie_head, p, &lock_zombie_list); //sould we check for return value of -1???/?????????????????????
    800022b0:	0000f617          	auipc	a2,0xf
    800022b4:	55060613          	addi	a2,a2,1360 # 80011800 <lock_zombie_list>
    800022b8:	85a6                	mv	a1,s1
    800022ba:	00006517          	auipc	a0,0x6
    800022be:	56a50513          	addi	a0,a0,1386 # 80008824 <zombie_head>
    800022c2:	00000097          	auipc	ra,0x0
    800022c6:	e64080e7          	jalr	-412(ra) # 80002126 <remove_from_list>
  p->state = UNUSED;
    800022ca:	0004ac23          	sw	zero,24(s1)
  add_to_list(&unused_head, p, &lock_unused_list);
    800022ce:	0000f617          	auipc	a2,0xf
    800022d2:	50260613          	addi	a2,a2,1282 # 800117d0 <lock_unused_list>
    800022d6:	85a6                	mv	a1,s1
    800022d8:	00006517          	auipc	a0,0x6
    800022dc:	55450513          	addi	a0,a0,1364 # 8000882c <unused_head>
    800022e0:	00000097          	auipc	ra,0x0
    800022e4:	b3c080e7          	jalr	-1220(ra) # 80001e1c <add_to_list>
}
    800022e8:	60e2                	ld	ra,24(sp)
    800022ea:	6442                	ld	s0,16(sp)
    800022ec:	64a2                	ld	s1,8(sp)
    800022ee:	6105                	addi	sp,sp,32
    800022f0:	8082                	ret

00000000800022f2 <wait>:
{
    800022f2:	715d                	addi	sp,sp,-80
    800022f4:	e486                	sd	ra,72(sp)
    800022f6:	e0a2                	sd	s0,64(sp)
    800022f8:	fc26                	sd	s1,56(sp)
    800022fa:	f84a                	sd	s2,48(sp)
    800022fc:	f44e                	sd	s3,40(sp)
    800022fe:	f052                	sd	s4,32(sp)
    80002300:	ec56                	sd	s5,24(sp)
    80002302:	e85a                	sd	s6,16(sp)
    80002304:	e45e                	sd	s7,8(sp)
    80002306:	e062                	sd	s8,0(sp)
    80002308:	0880                	addi	s0,sp,80
    8000230a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	5fc080e7          	jalr	1532(ra) # 80001908 <myproc>
    80002314:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002316:	0000f517          	auipc	a0,0xf
    8000231a:	4a250513          	addi	a0,a0,1186 # 800117b8 <wait_lock>
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	8c6080e7          	jalr	-1850(ra) # 80000be4 <acquire>
    havekids = 0;
    80002326:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002328:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000232a:	00015997          	auipc	s3,0x15
    8000232e:	6ee98993          	addi	s3,s3,1774 # 80017a18 <tickslock>
        havekids = 1;
    80002332:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002334:	0000fc17          	auipc	s8,0xf
    80002338:	484c0c13          	addi	s8,s8,1156 # 800117b8 <wait_lock>
    havekids = 0;
    8000233c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000233e:	0000f497          	auipc	s1,0xf
    80002342:	4da48493          	addi	s1,s1,1242 # 80011818 <proc>
    80002346:	a0bd                	j	800023b4 <wait+0xc2>
          pid = np->pid;
    80002348:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000234c:	000b0e63          	beqz	s6,80002368 <wait+0x76>
    80002350:	4691                	li	a3,4
    80002352:	02c48613          	addi	a2,s1,44
    80002356:	85da                	mv	a1,s6
    80002358:	07093503          	ld	a0,112(s2)
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	316080e7          	jalr	790(ra) # 80001672 <copyout>
    80002364:	02054563          	bltz	a0,8000238e <wait+0x9c>
          freeproc(np);
    80002368:	8526                	mv	a0,s1
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	efc080e7          	jalr	-260(ra) # 80002266 <freeproc>
          release(&np->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
          release(&wait_lock);
    8000237c:	0000f517          	auipc	a0,0xf
    80002380:	43c50513          	addi	a0,a0,1084 # 800117b8 <wait_lock>
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	914080e7          	jalr	-1772(ra) # 80000c98 <release>
          return pid;
    8000238c:	a09d                	j	800023f2 <wait+0x100>
            release(&np->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	908080e7          	jalr	-1784(ra) # 80000c98 <release>
            release(&wait_lock);
    80002398:	0000f517          	auipc	a0,0xf
    8000239c:	42050513          	addi	a0,a0,1056 # 800117b8 <wait_lock>
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8f8080e7          	jalr	-1800(ra) # 80000c98 <release>
            return -1;
    800023a8:	59fd                	li	s3,-1
    800023aa:	a0a1                	j	800023f2 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800023ac:	18848493          	addi	s1,s1,392
    800023b0:	03348463          	beq	s1,s3,800023d8 <wait+0xe6>
      if(np->parent == p){
    800023b4:	6cbc                	ld	a5,88(s1)
    800023b6:	ff279be3          	bne	a5,s2,800023ac <wait+0xba>
        acquire(&np->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	828080e7          	jalr	-2008(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023c4:	4c9c                	lw	a5,24(s1)
    800023c6:	f94781e3          	beq	a5,s4,80002348 <wait+0x56>
        release(&np->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8cc080e7          	jalr	-1844(ra) # 80000c98 <release>
        havekids = 1;
    800023d4:	8756                	mv	a4,s5
    800023d6:	bfd9                	j	800023ac <wait+0xba>
    if(!havekids || p->killed){
    800023d8:	c701                	beqz	a4,800023e0 <wait+0xee>
    800023da:	02892783          	lw	a5,40(s2)
    800023de:	c79d                	beqz	a5,8000240c <wait+0x11a>
      release(&wait_lock);
    800023e0:	0000f517          	auipc	a0,0xf
    800023e4:	3d850513          	addi	a0,a0,984 # 800117b8 <wait_lock>
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8b0080e7          	jalr	-1872(ra) # 80000c98 <release>
      return -1;
    800023f0:	59fd                	li	s3,-1
}
    800023f2:	854e                	mv	a0,s3
    800023f4:	60a6                	ld	ra,72(sp)
    800023f6:	6406                	ld	s0,64(sp)
    800023f8:	74e2                	ld	s1,56(sp)
    800023fa:	7942                	ld	s2,48(sp)
    800023fc:	79a2                	ld	s3,40(sp)
    800023fe:	7a02                	ld	s4,32(sp)
    80002400:	6ae2                	ld	s5,24(sp)
    80002402:	6b42                	ld	s6,16(sp)
    80002404:	6ba2                	ld	s7,8(sp)
    80002406:	6c02                	ld	s8,0(sp)
    80002408:	6161                	addi	sp,sp,80
    8000240a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000240c:	85e2                	mv	a1,s8
    8000240e:	854a                	mv	a0,s2
    80002410:	00000097          	auipc	ra,0x0
    80002414:	c98080e7          	jalr	-872(ra) # 800020a8 <sleep>
    havekids = 0;
    80002418:	b715                	j	8000233c <wait+0x4a>

000000008000241a <wakeup>:
{
    8000241a:	711d                	addi	sp,sp,-96
    8000241c:	ec86                	sd	ra,88(sp)
    8000241e:	e8a2                	sd	s0,80(sp)
    80002420:	e4a6                	sd	s1,72(sp)
    80002422:	e0ca                	sd	s2,64(sp)
    80002424:	fc4e                	sd	s3,56(sp)
    80002426:	f852                	sd	s4,48(sp)
    80002428:	f456                	sd	s5,40(sp)
    8000242a:	f05a                	sd	s6,32(sp)
    8000242c:	ec5e                	sd	s7,24(sp)
    8000242e:	e862                	sd	s8,16(sp)
    80002430:	e466                	sd	s9,8(sp)
    80002432:	e06a                	sd	s10,0(sp)
    80002434:	1080                	addi	s0,sp,96
    80002436:	8b2a                	mv	s6,a0
  acquire(&lock_sleeping_list);
    80002438:	0000f517          	auipc	a0,0xf
    8000243c:	3b050513          	addi	a0,a0,944 # 800117e8 <lock_sleeping_list>
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	7a4080e7          	jalr	1956(ra) # 80000be4 <acquire>
  if(sleeping_head != -1){
    80002448:	00006497          	auipc	s1,0x6
    8000244c:	3e04a483          	lw	s1,992(s1) # 80008828 <sleeping_head>
    80002450:	57fd                	li	a5,-1
    80002452:	0af48363          	beq	s1,a5,800024f8 <wakeup+0xde>
    p = &proc[sleeping_head];
    80002456:	18800913          	li	s2,392
    8000245a:	03248933          	mul	s2,s1,s2
    8000245e:	0000f797          	auipc	a5,0xf
    80002462:	3ba78793          	addi	a5,a5,954 # 80011818 <proc>
    80002466:	993e                	add	s2,s2,a5
    release(&lock_sleeping_list);
    80002468:	0000f517          	auipc	a0,0xf
    8000246c:	38050513          	addi	a0,a0,896 # 800117e8 <lock_sleeping_list>
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	828080e7          	jalr	-2008(ra) # 80000c98 <release>
      int next_proc = p->next_proc_index;
    80002478:	84ca                	mv	s1,s2
      if (p->state == SLEEPING && p->chan == chan) {
    8000247a:	4a89                	li	s5,2
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    8000247c:	0000fc17          	auipc	s8,0xf
    80002480:	36cc0c13          	addi	s8,s8,876 # 800117e8 <lock_sleeping_list>
    80002484:	00006b97          	auipc	s7,0x6
    80002488:	3a4b8b93          	addi	s7,s7,932 # 80008828 <sleeping_head>
              p->state = RUNNABLE;
    8000248c:	4d0d                	li	s10,3
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    8000248e:	0000fc97          	auipc	s9,0xf
    80002492:	e12c8c93          	addi	s9,s9,-494 # 800112a0 <cpus>
    } while(curr_proc != -1);
    80002496:	5a7d                	li	s4,-1
    80002498:	a801                	j	800024a8 <wakeup+0x8e>
      release(&p->lock);
    8000249a:	854a                	mv	a0,s2
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	7fc080e7          	jalr	2044(ra) # 80000c98 <release>
    } while(curr_proc != -1);
    800024a4:	07498263          	beq	s3,s4,80002508 <wakeup+0xee>
      acquire(&p->lock);
    800024a8:	854a                	mv	a0,s2
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	73a080e7          	jalr	1850(ra) # 80000be4 <acquire>
      int next_proc = p->next_proc_index;
    800024b2:	0384a983          	lw	s3,56(s1)
      if (p->state == SLEEPING && p->chan == chan) {
    800024b6:	4c9c                	lw	a5,24(s1)
    800024b8:	ff5791e3          	bne	a5,s5,8000249a <wakeup+0x80>
    800024bc:	709c                	ld	a5,32(s1)
    800024be:	fd679ee3          	bne	a5,s6,8000249a <wakeup+0x80>
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    800024c2:	8662                	mv	a2,s8
    800024c4:	85ca                	mv	a1,s2
    800024c6:	855e                	mv	a0,s7
    800024c8:	00000097          	auipc	ra,0x0
    800024cc:	c5e080e7          	jalr	-930(ra) # 80002126 <remove_from_list>
    800024d0:	d569                	beqz	a0,8000249a <wakeup+0x80>
              p->state = RUNNABLE;
    800024d2:	01a4ac23          	sw	s10,24(s1)
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    800024d6:	58dc                	lw	a5,52(s1)
    800024d8:	00279513          	slli	a0,a5,0x2
    800024dc:	953e                	add	a0,a0,a5
    800024de:	0516                	slli	a0,a0,0x5
    800024e0:	08850613          	addi	a2,a0,136
    800024e4:	08050513          	addi	a0,a0,128
    800024e8:	9666                	add	a2,a2,s9
    800024ea:	85ca                	mv	a1,s2
    800024ec:	9566                	add	a0,a0,s9
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	92e080e7          	jalr	-1746(ra) # 80001e1c <add_to_list>
    800024f6:	b755                	j	8000249a <wakeup+0x80>
    release(&lock_sleeping_list);
    800024f8:	0000f517          	auipc	a0,0xf
    800024fc:	2f050513          	addi	a0,a0,752 # 800117e8 <lock_sleeping_list>
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	798080e7          	jalr	1944(ra) # 80000c98 <release>
}
    80002508:	60e6                	ld	ra,88(sp)
    8000250a:	6446                	ld	s0,80(sp)
    8000250c:	64a6                	ld	s1,72(sp)
    8000250e:	6906                	ld	s2,64(sp)
    80002510:	79e2                	ld	s3,56(sp)
    80002512:	7a42                	ld	s4,48(sp)
    80002514:	7aa2                	ld	s5,40(sp)
    80002516:	7b02                	ld	s6,32(sp)
    80002518:	6be2                	ld	s7,24(sp)
    8000251a:	6c42                	ld	s8,16(sp)
    8000251c:	6ca2                	ld	s9,8(sp)
    8000251e:	6d02                	ld	s10,0(sp)
    80002520:	6125                	addi	sp,sp,96
    80002522:	8082                	ret

0000000080002524 <reparent>:
{
    80002524:	7179                	addi	sp,sp,-48
    80002526:	f406                	sd	ra,40(sp)
    80002528:	f022                	sd	s0,32(sp)
    8000252a:	ec26                	sd	s1,24(sp)
    8000252c:	e84a                	sd	s2,16(sp)
    8000252e:	e44e                	sd	s3,8(sp)
    80002530:	e052                	sd	s4,0(sp)
    80002532:	1800                	addi	s0,sp,48
    80002534:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002536:	0000f497          	auipc	s1,0xf
    8000253a:	2e248493          	addi	s1,s1,738 # 80011818 <proc>
      pp->parent = initproc;
    8000253e:	00007a17          	auipc	s4,0x7
    80002542:	aeaa0a13          	addi	s4,s4,-1302 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002546:	00015997          	auipc	s3,0x15
    8000254a:	4d298993          	addi	s3,s3,1234 # 80017a18 <tickslock>
    8000254e:	a029                	j	80002558 <reparent+0x34>
    80002550:	18848493          	addi	s1,s1,392
    80002554:	01348d63          	beq	s1,s3,8000256e <reparent+0x4a>
    if(pp->parent == p){
    80002558:	6cbc                	ld	a5,88(s1)
    8000255a:	ff279be3          	bne	a5,s2,80002550 <reparent+0x2c>
      pp->parent = initproc;
    8000255e:	000a3503          	ld	a0,0(s4)
    80002562:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002564:	00000097          	auipc	ra,0x0
    80002568:	eb6080e7          	jalr	-330(ra) # 8000241a <wakeup>
    8000256c:	b7d5                	j	80002550 <reparent+0x2c>
}
    8000256e:	70a2                	ld	ra,40(sp)
    80002570:	7402                	ld	s0,32(sp)
    80002572:	64e2                	ld	s1,24(sp)
    80002574:	6942                	ld	s2,16(sp)
    80002576:	69a2                	ld	s3,8(sp)
    80002578:	6a02                	ld	s4,0(sp)
    8000257a:	6145                	addi	sp,sp,48
    8000257c:	8082                	ret

000000008000257e <exit>:
{
    8000257e:	7179                	addi	sp,sp,-48
    80002580:	f406                	sd	ra,40(sp)
    80002582:	f022                	sd	s0,32(sp)
    80002584:	ec26                	sd	s1,24(sp)
    80002586:	e84a                	sd	s2,16(sp)
    80002588:	e44e                	sd	s3,8(sp)
    8000258a:	e052                	sd	s4,0(sp)
    8000258c:	1800                	addi	s0,sp,48
    8000258e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	378080e7          	jalr	888(ra) # 80001908 <myproc>
    80002598:	89aa                	mv	s3,a0
  if(p == initproc)
    8000259a:	00007797          	auipc	a5,0x7
    8000259e:	a8e7b783          	ld	a5,-1394(a5) # 80009028 <initproc>
    800025a2:	0f050493          	addi	s1,a0,240
    800025a6:	17050913          	addi	s2,a0,368
    800025aa:	02a79363          	bne	a5,a0,800025d0 <exit+0x52>
    panic("init exiting");
    800025ae:	00006517          	auipc	a0,0x6
    800025b2:	cb250513          	addi	a0,a0,-846 # 80008260 <digits+0x220>
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>
      fileclose(f);
    800025be:	00002097          	auipc	ra,0x2
    800025c2:	45c080e7          	jalr	1116(ra) # 80004a1a <fileclose>
      p->ofile[fd] = 0;
    800025c6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025ca:	04a1                	addi	s1,s1,8
    800025cc:	01248563          	beq	s1,s2,800025d6 <exit+0x58>
    if(p->ofile[fd]){
    800025d0:	6088                	ld	a0,0(s1)
    800025d2:	f575                	bnez	a0,800025be <exit+0x40>
    800025d4:	bfdd                	j	800025ca <exit+0x4c>
  begin_op();
    800025d6:	00002097          	auipc	ra,0x2
    800025da:	f78080e7          	jalr	-136(ra) # 8000454e <begin_op>
  iput(p->cwd);
    800025de:	1709b503          	ld	a0,368(s3)
    800025e2:	00001097          	auipc	ra,0x1
    800025e6:	754080e7          	jalr	1876(ra) # 80003d36 <iput>
  end_op();
    800025ea:	00002097          	auipc	ra,0x2
    800025ee:	fe4080e7          	jalr	-28(ra) # 800045ce <end_op>
  p->cwd = 0;
    800025f2:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    800025f6:	0000f497          	auipc	s1,0xf
    800025fa:	1c248493          	addi	s1,s1,450 # 800117b8 <wait_lock>
    800025fe:	8526                	mv	a0,s1
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
  reparent(p);
    80002608:	854e                	mv	a0,s3
    8000260a:	00000097          	auipc	ra,0x0
    8000260e:	f1a080e7          	jalr	-230(ra) # 80002524 <reparent>
  wakeup(p->parent);
    80002612:	0589b503          	ld	a0,88(s3)
    80002616:	00000097          	auipc	ra,0x0
    8000261a:	e04080e7          	jalr	-508(ra) # 8000241a <wakeup>
  acquire(&p->lock);
    8000261e:	854e                	mv	a0,s3
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	5c4080e7          	jalr	1476(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002628:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000262c:	4795                	li	a5,5
    8000262e:	00f9ac23          	sw	a5,24(s3)
  add_to_list(&zombie_head, p, &lock_zombie_list);
    80002632:	0000f617          	auipc	a2,0xf
    80002636:	1ce60613          	addi	a2,a2,462 # 80011800 <lock_zombie_list>
    8000263a:	85ce                	mv	a1,s3
    8000263c:	00006517          	auipc	a0,0x6
    80002640:	1e850513          	addi	a0,a0,488 # 80008824 <zombie_head>
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	7d8080e7          	jalr	2008(ra) # 80001e1c <add_to_list>
  release(&wait_lock);
    8000264c:	8526                	mv	a0,s1
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	64a080e7          	jalr	1610(ra) # 80000c98 <release>
  sched();
    80002656:	fffff097          	auipc	ra,0xfffff
    8000265a:	4d2080e7          	jalr	1234(ra) # 80001b28 <sched>
  panic("zombie exit");
    8000265e:	00006517          	auipc	a0,0x6
    80002662:	c1250513          	addi	a0,a0,-1006 # 80008270 <digits+0x230>
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	ed8080e7          	jalr	-296(ra) # 8000053e <panic>

000000008000266e <remove_first>:

int remove_first(int* curr_proc_index, struct spinlock* lock) {
    8000266e:	7139                	addi	sp,sp,-64
    80002670:	fc06                	sd	ra,56(sp)
    80002672:	f822                	sd	s0,48(sp)
    80002674:	f426                	sd	s1,40(sp)
    80002676:	f04a                	sd	s2,32(sp)
    80002678:	ec4e                	sd	s3,24(sp)
    8000267a:	e852                	sd	s4,16(sp)
    8000267c:	e456                	sd	s5,8(sp)
    8000267e:	0080                	addi	s0,sp,64
    80002680:	8aaa                	mv	s5,a0
    80002682:	89ae                	mv	s3,a1
    acquire(lock);
    80002684:	852e                	mv	a0,a1
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	55e080e7          	jalr	1374(ra) # 80000be4 <acquire>
    
    if (*curr_proc_index != -1){
    8000268e:	000aa483          	lw	s1,0(s5)
    80002692:	57fd                	li	a5,-1
    80002694:	04f48d63          	beq	s1,a5,800026ee <remove_first+0x80>
      int index = *curr_proc_index;
      struct proc *p = &proc[index];
      acquire(&p->proc_lock);
    80002698:	18800793          	li	a5,392
    8000269c:	02f484b3          	mul	s1,s1,a5
    800026a0:	04048a13          	addi	s4,s1,64
    800026a4:	0000f917          	auipc	s2,0xf
    800026a8:	17490913          	addi	s2,s2,372 # 80011818 <proc>
    800026ac:	9a4a                	add	s4,s4,s2
    800026ae:	8552                	mv	a0,s4
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	534080e7          	jalr	1332(ra) # 80000be4 <acquire>
      
      *curr_proc_index = p->next_proc_index;
    800026b8:	94ca                	add	s1,s1,s2
    800026ba:	5c9c                	lw	a5,56(s1)
    800026bc:	00faa023          	sw	a5,0(s5)
      p->next_proc_index = -1;
    800026c0:	57fd                	li	a5,-1
    800026c2:	dc9c                	sw	a5,56(s1)
      int output_proc = p->proc_index;
    800026c4:	5cc4                	lw	s1,60(s1)

      release(&p->proc_lock);
    800026c6:	8552                	mv	a0,s4
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	5d0080e7          	jalr	1488(ra) # 80000c98 <release>
      release(lock);
    800026d0:	854e                	mv	a0,s3
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	5c6080e7          	jalr	1478(ra) # 80000c98 <release>
    else{

      release(lock);
      return -1;
    }
    800026da:	8526                	mv	a0,s1
    800026dc:	70e2                	ld	ra,56(sp)
    800026de:	7442                	ld	s0,48(sp)
    800026e0:	74a2                	ld	s1,40(sp)
    800026e2:	7902                	ld	s2,32(sp)
    800026e4:	69e2                	ld	s3,24(sp)
    800026e6:	6a42                	ld	s4,16(sp)
    800026e8:	6aa2                	ld	s5,8(sp)
    800026ea:	6121                	addi	sp,sp,64
    800026ec:	8082                	ret
      release(lock);
    800026ee:	854e                	mv	a0,s3
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	5a8080e7          	jalr	1448(ra) # 80000c98 <release>
      return -1;
    800026f8:	b7cd                	j	800026da <remove_first+0x6c>

00000000800026fa <allocproc>:
{
    800026fa:	7179                	addi	sp,sp,-48
    800026fc:	f406                	sd	ra,40(sp)
    800026fe:	f022                	sd	s0,32(sp)
    80002700:	ec26                	sd	s1,24(sp)
    80002702:	e84a                	sd	s2,16(sp)
    80002704:	e44e                	sd	s3,8(sp)
    80002706:	e052                	sd	s4,0(sp)
    80002708:	1800                	addi	s0,sp,48
    int allocation = remove_first(&unused_head, &lock_unused_list);
    8000270a:	0000f597          	auipc	a1,0xf
    8000270e:	0c658593          	addi	a1,a1,198 # 800117d0 <lock_unused_list>
    80002712:	00006517          	auipc	a0,0x6
    80002716:	11a50513          	addi	a0,a0,282 # 8000882c <unused_head>
    8000271a:	00000097          	auipc	ra,0x0
    8000271e:	f54080e7          	jalr	-172(ra) # 8000266e <remove_first>
    if(allocation == -1){
    80002722:	57fd                	li	a5,-1
    80002724:	0ef50063          	beq	a0,a5,80002804 <allocproc+0x10a>
    80002728:	892a                	mv	s2,a0
  p=&proc[allocation];
    8000272a:	18800993          	li	s3,392
    8000272e:	033509b3          	mul	s3,a0,s3
    80002732:	0000f497          	auipc	s1,0xf
    80002736:	0e648493          	addi	s1,s1,230 # 80011818 <proc>
    8000273a:	94ce                	add	s1,s1,s3
  acquire(&p->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    80002746:	fffff097          	auipc	ra,0xfffff
    8000274a:	248080e7          	jalr	584(ra) # 8000198e <allocpid>
    8000274e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80002750:	4785                	li	a5,1
    80002752:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	3a0080e7          	jalr	928(ra) # 80000af4 <kalloc>
    8000275c:	8a2a                	mv	s4,a0
    8000275e:	fca8                	sd	a0,120(s1)
    80002760:	c935                	beqz	a0,800027d4 <allocproc+0xda>
  p->pagetable = proc_pagetable(p);
    80002762:	8526                	mv	a0,s1
    80002764:	fffff097          	auipc	ra,0xfffff
    80002768:	262080e7          	jalr	610(ra) # 800019c6 <proc_pagetable>
    8000276c:	8a2a                	mv	s4,a0
    8000276e:	18800793          	li	a5,392
    80002772:	02f90733          	mul	a4,s2,a5
    80002776:	0000f797          	auipc	a5,0xf
    8000277a:	0a278793          	addi	a5,a5,162 # 80011818 <proc>
    8000277e:	97ba                	add	a5,a5,a4
    80002780:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    80002782:	c52d                	beqz	a0,800027ec <allocproc+0xf2>
  memset(&p->context, 0, sizeof(p->context));
    80002784:	08098513          	addi	a0,s3,128
    80002788:	0000fa17          	auipc	s4,0xf
    8000278c:	090a0a13          	addi	s4,s4,144 # 80011818 <proc>
    80002790:	07000613          	li	a2,112
    80002794:	4581                	li	a1,0
    80002796:	9552                	add	a0,a0,s4
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	548080e7          	jalr	1352(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    800027a0:	18800513          	li	a0,392
    800027a4:	02a90933          	mul	s2,s2,a0
    800027a8:	9952                	add	s2,s2,s4
    800027aa:	fffff797          	auipc	a5,0xfffff
    800027ae:	19e78793          	addi	a5,a5,414 # 80001948 <forkret>
    800027b2:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    800027b6:	06093783          	ld	a5,96(s2)
    800027ba:	6705                	lui	a4,0x1
    800027bc:	97ba                	add	a5,a5,a4
    800027be:	08f93423          	sd	a5,136(s2)
}
    800027c2:	8526                	mv	a0,s1
    800027c4:	70a2                	ld	ra,40(sp)
    800027c6:	7402                	ld	s0,32(sp)
    800027c8:	64e2                	ld	s1,24(sp)
    800027ca:	6942                	ld	s2,16(sp)
    800027cc:	69a2                	ld	s3,8(sp)
    800027ce:	6a02                	ld	s4,0(sp)
    800027d0:	6145                	addi	sp,sp,48
    800027d2:	8082                	ret
    freeproc(p);
    800027d4:	8526                	mv	a0,s1
    800027d6:	00000097          	auipc	ra,0x0
    800027da:	a90080e7          	jalr	-1392(ra) # 80002266 <freeproc>
    release(&p->lock);
    800027de:	8526                	mv	a0,s1
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	4b8080e7          	jalr	1208(ra) # 80000c98 <release>
    return 0;
    800027e8:	84d2                	mv	s1,s4
    800027ea:	bfe1                	j	800027c2 <allocproc+0xc8>
    freeproc(p);
    800027ec:	8526                	mv	a0,s1
    800027ee:	00000097          	auipc	ra,0x0
    800027f2:	a78080e7          	jalr	-1416(ra) # 80002266 <freeproc>
    release(&p->lock);
    800027f6:	8526                	mv	a0,s1
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	4a0080e7          	jalr	1184(ra) # 80000c98 <release>
    return 0;
    80002800:	84d2                	mv	s1,s4
    80002802:	b7c1                	j	800027c2 <allocproc+0xc8>
      return 0;
    80002804:	4481                	li	s1,0
    80002806:	bf75                	j	800027c2 <allocproc+0xc8>

0000000080002808 <userinit>:
{
    80002808:	1101                	addi	sp,sp,-32
    8000280a:	ec06                	sd	ra,24(sp)
    8000280c:	e822                	sd	s0,16(sp)
    8000280e:	e426                	sd	s1,8(sp)
    80002810:	1000                	addi	s0,sp,32
  p = allocproc();
    80002812:	00000097          	auipc	ra,0x0
    80002816:	ee8080e7          	jalr	-280(ra) # 800026fa <allocproc>
    8000281a:	84aa                	mv	s1,a0
  initproc = p;
    8000281c:	00007797          	auipc	a5,0x7
    80002820:	80a7b623          	sd	a0,-2036(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002824:	03400613          	li	a2,52
    80002828:	00006597          	auipc	a1,0x6
    8000282c:	01858593          	addi	a1,a1,24 # 80008840 <initcode>
    80002830:	7928                	ld	a0,112(a0)
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	b36080e7          	jalr	-1226(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    8000283a:	6785                	lui	a5,0x1
    8000283c:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    8000283e:	7cb8                	ld	a4,120(s1)
    80002840:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002844:	7cb8                	ld	a4,120(s1)
    80002846:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002848:	4641                	li	a2,16
    8000284a:	00006597          	auipc	a1,0x6
    8000284e:	a3658593          	addi	a1,a1,-1482 # 80008280 <digits+0x240>
    80002852:	17848513          	addi	a0,s1,376
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	5dc080e7          	jalr	1500(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    8000285e:	00006517          	auipc	a0,0x6
    80002862:	a3250513          	addi	a0,a0,-1486 # 80008290 <digits+0x250>
    80002866:	00002097          	auipc	ra,0x2
    8000286a:	acc080e7          	jalr	-1332(ra) # 80004332 <namei>
    8000286e:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80002872:	478d                	li	a5,3
    80002874:	cc9c                	sw	a5,24(s1)
  add_to_list(&cpus[0].runnable_head, p, &cpus[0].lock_runnable_list);
    80002876:	0000f617          	auipc	a2,0xf
    8000287a:	ab260613          	addi	a2,a2,-1358 # 80011328 <cpus+0x88>
    8000287e:	85a6                	mv	a1,s1
    80002880:	0000f517          	auipc	a0,0xf
    80002884:	aa050513          	addi	a0,a0,-1376 # 80011320 <cpus+0x80>
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	594080e7          	jalr	1428(ra) # 80001e1c <add_to_list>
  release(&p->lock);
    80002890:	8526                	mv	a0,s1
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
}
    8000289a:	60e2                	ld	ra,24(sp)
    8000289c:	6442                	ld	s0,16(sp)
    8000289e:	64a2                	ld	s1,8(sp)
    800028a0:	6105                	addi	sp,sp,32
    800028a2:	8082                	ret

00000000800028a4 <fork>:
{
    800028a4:	7139                	addi	sp,sp,-64
    800028a6:	fc06                	sd	ra,56(sp)
    800028a8:	f822                	sd	s0,48(sp)
    800028aa:	f426                	sd	s1,40(sp)
    800028ac:	f04a                	sd	s2,32(sp)
    800028ae:	ec4e                	sd	s3,24(sp)
    800028b0:	e852                	sd	s4,16(sp)
    800028b2:	e456                	sd	s5,8(sp)
    800028b4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800028b6:	fffff097          	auipc	ra,0xfffff
    800028ba:	052080e7          	jalr	82(ra) # 80001908 <myproc>
    800028be:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	e3a080e7          	jalr	-454(ra) # 800026fa <allocproc>
    800028c8:	14050163          	beqz	a0,80002a0a <fork+0x166>
    800028cc:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800028ce:	0689b603          	ld	a2,104(s3)
    800028d2:	792c                	ld	a1,112(a0)
    800028d4:	0709b503          	ld	a0,112(s3)
    800028d8:	fffff097          	auipc	ra,0xfffff
    800028dc:	c96080e7          	jalr	-874(ra) # 8000156e <uvmcopy>
    800028e0:	04054663          	bltz	a0,8000292c <fork+0x88>
  np->sz = p->sz;
    800028e4:	0689b783          	ld	a5,104(s3)
    800028e8:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    800028ec:	0789b683          	ld	a3,120(s3)
    800028f0:	87b6                	mv	a5,a3
    800028f2:	07893703          	ld	a4,120(s2)
    800028f6:	12068693          	addi	a3,a3,288
    800028fa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800028fe:	6788                	ld	a0,8(a5)
    80002900:	6b8c                	ld	a1,16(a5)
    80002902:	6f90                	ld	a2,24(a5)
    80002904:	01073023          	sd	a6,0(a4)
    80002908:	e708                	sd	a0,8(a4)
    8000290a:	eb0c                	sd	a1,16(a4)
    8000290c:	ef10                	sd	a2,24(a4)
    8000290e:	02078793          	addi	a5,a5,32
    80002912:	02070713          	addi	a4,a4,32
    80002916:	fed792e3          	bne	a5,a3,800028fa <fork+0x56>
  np->trapframe->a0 = 0;
    8000291a:	07893783          	ld	a5,120(s2)
    8000291e:	0607b823          	sd	zero,112(a5)
    80002922:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80002926:	17000a13          	li	s4,368
    8000292a:	a03d                	j	80002958 <fork+0xb4>
    freeproc(np);
    8000292c:	854a                	mv	a0,s2
    8000292e:	00000097          	auipc	ra,0x0
    80002932:	938080e7          	jalr	-1736(ra) # 80002266 <freeproc>
    release(&np->lock);
    80002936:	854a                	mv	a0,s2
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	360080e7          	jalr	864(ra) # 80000c98 <release>
    return -1;
    80002940:	5afd                	li	s5,-1
    80002942:	a855                	j	800029f6 <fork+0x152>
      np->ofile[i] = filedup(p->ofile[i]);
    80002944:	00002097          	auipc	ra,0x2
    80002948:	084080e7          	jalr	132(ra) # 800049c8 <filedup>
    8000294c:	009907b3          	add	a5,s2,s1
    80002950:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002952:	04a1                	addi	s1,s1,8
    80002954:	01448763          	beq	s1,s4,80002962 <fork+0xbe>
    if(p->ofile[i])
    80002958:	009987b3          	add	a5,s3,s1
    8000295c:	6388                	ld	a0,0(a5)
    8000295e:	f17d                	bnez	a0,80002944 <fork+0xa0>
    80002960:	bfcd                	j	80002952 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002962:	1709b503          	ld	a0,368(s3)
    80002966:	00001097          	auipc	ra,0x1
    8000296a:	1d8080e7          	jalr	472(ra) # 80003b3e <idup>
    8000296e:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002972:	4641                	li	a2,16
    80002974:	17898593          	addi	a1,s3,376
    80002978:	17890513          	addi	a0,s2,376
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	4b6080e7          	jalr	1206(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002984:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    80002988:	854a                	mv	a0,s2
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	30e080e7          	jalr	782(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002992:	0000f497          	auipc	s1,0xf
    80002996:	90e48493          	addi	s1,s1,-1778 # 800112a0 <cpus>
    8000299a:	0000fa17          	auipc	s4,0xf
    8000299e:	e1ea0a13          	addi	s4,s4,-482 # 800117b8 <wait_lock>
    800029a2:	8552                	mv	a0,s4
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	240080e7          	jalr	576(ra) # 80000be4 <acquire>
  np->parent = p;
    800029ac:	05393c23          	sd	s3,88(s2)
  release(&wait_lock);
    800029b0:	8552                	mv	a0,s4
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	2e6080e7          	jalr	742(ra) # 80000c98 <release>
  acquire(&np->lock);
    800029ba:	854a                	mv	a0,s2
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	228080e7          	jalr	552(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800029c4:	478d                	li	a5,3
    800029c6:	00f92c23          	sw	a5,24(s2)
  add_to_list(&c->runnable_head, np, &c->lock_runnable_list);
    800029ca:	03492783          	lw	a5,52(s2)
    800029ce:	00279513          	slli	a0,a5,0x2
    800029d2:	953e                	add	a0,a0,a5
    800029d4:	0516                	slli	a0,a0,0x5
    800029d6:	08850613          	addi	a2,a0,136
    800029da:	08050513          	addi	a0,a0,128
    800029de:	9626                	add	a2,a2,s1
    800029e0:	85ca                	mv	a1,s2
    800029e2:	9526                	add	a0,a0,s1
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	438080e7          	jalr	1080(ra) # 80001e1c <add_to_list>
  release(&np->lock);
    800029ec:	854a                	mv	a0,s2
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	2aa080e7          	jalr	682(ra) # 80000c98 <release>
}
    800029f6:	8556                	mv	a0,s5
    800029f8:	70e2                	ld	ra,56(sp)
    800029fa:	7442                	ld	s0,48(sp)
    800029fc:	74a2                	ld	s1,40(sp)
    800029fe:	7902                	ld	s2,32(sp)
    80002a00:	69e2                	ld	s3,24(sp)
    80002a02:	6a42                	ld	s4,16(sp)
    80002a04:	6aa2                	ld	s5,8(sp)
    80002a06:	6121                	addi	sp,sp,64
    80002a08:	8082                	ret
    return -1;
    80002a0a:	5afd                	li	s5,-1
    80002a0c:	b7ed                	j	800029f6 <fork+0x152>

0000000080002a0e <scheduler>:
{
    80002a0e:	711d                	addi	sp,sp,-96
    80002a10:	ec86                	sd	ra,88(sp)
    80002a12:	e8a2                	sd	s0,80(sp)
    80002a14:	e4a6                	sd	s1,72(sp)
    80002a16:	e0ca                	sd	s2,64(sp)
    80002a18:	fc4e                	sd	s3,56(sp)
    80002a1a:	f852                	sd	s4,48(sp)
    80002a1c:	f456                	sd	s5,40(sp)
    80002a1e:	f05a                	sd	s6,32(sp)
    80002a20:	ec5e                	sd	s7,24(sp)
    80002a22:	e862                	sd	s8,16(sp)
    80002a24:	e466                	sd	s9,8(sp)
    80002a26:	e06a                	sd	s10,0(sp)
    80002a28:	1080                	addi	s0,sp,96
    80002a2a:	8712                	mv	a4,tp
  int id = r_tp();
    80002a2c:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002a2e:	0000fc17          	auipc	s8,0xf
    80002a32:	872c0c13          	addi	s8,s8,-1934 # 800112a0 <cpus>
    80002a36:	00271793          	slli	a5,a4,0x2
    80002a3a:	00e786b3          	add	a3,a5,a4
    80002a3e:	0696                	slli	a3,a3,0x5
    80002a40:	96e2                	add	a3,a3,s8
    80002a42:	0006b023          	sd	zero,0(a3)
    80002a46:	97ba                	add	a5,a5,a4
    80002a48:	0796                	slli	a5,a5,0x5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002a4a:	08078993          	addi	s3,a5,128
    80002a4e:	99e2                	add	s3,s3,s8
    80002a50:	08878913          	addi	s2,a5,136
    80002a54:	9962                	add	s2,s2,s8
      swtch(&c->context, &p->context);
    80002a56:	07a1                	addi	a5,a5,8
    80002a58:	9c3e                	add	s8,s8,a5
    if(proc_num != -1){
    80002a5a:	5a7d                	li	s4,-1
    80002a5c:	18800b13          	li	s6,392
      p = &proc[proc_num];
    80002a60:	0000fa97          	auipc	s5,0xf
    80002a64:	db8a8a93          	addi	s5,s5,-584 # 80011818 <proc>
      c->proc = p;
    80002a68:	8bb6                	mv	s7,a3
    80002a6a:	a031                	j	80002a76 <scheduler+0x68>
    release(&p->lock);
    80002a6c:	8566                	mv	a0,s9
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	22a080e7          	jalr	554(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a7e:	10079073          	csrw	sstatus,a5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002a82:	85ca                	mv	a1,s2
    80002a84:	854e                	mv	a0,s3
    80002a86:	00000097          	auipc	ra,0x0
    80002a8a:	be8080e7          	jalr	-1048(ra) # 8000266e <remove_first>
    if(proc_num != -1){
    80002a8e:	ff4504e3          	beq	a0,s4,80002a76 <scheduler+0x68>
      p = &proc[proc_num];
    80002a92:	03650d33          	mul	s10,a0,s6
    80002a96:	015d0cb3          	add	s9,s10,s5
    acquire(&p->lock);
    80002a9a:	8566                	mv	a0,s9
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	148080e7          	jalr	328(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE) {
    80002aa4:	018ca703          	lw	a4,24(s9)
    80002aa8:	478d                	li	a5,3
    80002aaa:	fcf711e3          	bne	a4,a5,80002a6c <scheduler+0x5e>
      p->state = RUNNING;
    80002aae:	4791                	li	a5,4
    80002ab0:	00fcac23          	sw	a5,24(s9)
      c->proc = p;
    80002ab4:	019bb023          	sd	s9,0(s7)
      swtch(&c->context, &p->context);
    80002ab8:	080d0593          	addi	a1,s10,128
    80002abc:	95d6                	add	a1,a1,s5
    80002abe:	8562                	mv	a0,s8
    80002ac0:	00000097          	auipc	ra,0x0
    80002ac4:	00e080e7          	jalr	14(ra) # 80002ace <swtch>
      c->proc = 0;
    80002ac8:	000bb023          	sd	zero,0(s7)
    80002acc:	b745                	j	80002a6c <scheduler+0x5e>

0000000080002ace <swtch>:
    80002ace:	00153023          	sd	ra,0(a0)
    80002ad2:	00253423          	sd	sp,8(a0)
    80002ad6:	e900                	sd	s0,16(a0)
    80002ad8:	ed04                	sd	s1,24(a0)
    80002ada:	03253023          	sd	s2,32(a0)
    80002ade:	03353423          	sd	s3,40(a0)
    80002ae2:	03453823          	sd	s4,48(a0)
    80002ae6:	03553c23          	sd	s5,56(a0)
    80002aea:	05653023          	sd	s6,64(a0)
    80002aee:	05753423          	sd	s7,72(a0)
    80002af2:	05853823          	sd	s8,80(a0)
    80002af6:	05953c23          	sd	s9,88(a0)
    80002afa:	07a53023          	sd	s10,96(a0)
    80002afe:	07b53423          	sd	s11,104(a0)
    80002b02:	0005b083          	ld	ra,0(a1)
    80002b06:	0085b103          	ld	sp,8(a1)
    80002b0a:	6980                	ld	s0,16(a1)
    80002b0c:	6d84                	ld	s1,24(a1)
    80002b0e:	0205b903          	ld	s2,32(a1)
    80002b12:	0285b983          	ld	s3,40(a1)
    80002b16:	0305ba03          	ld	s4,48(a1)
    80002b1a:	0385ba83          	ld	s5,56(a1)
    80002b1e:	0405bb03          	ld	s6,64(a1)
    80002b22:	0485bb83          	ld	s7,72(a1)
    80002b26:	0505bc03          	ld	s8,80(a1)
    80002b2a:	0585bc83          	ld	s9,88(a1)
    80002b2e:	0605bd03          	ld	s10,96(a1)
    80002b32:	0685bd83          	ld	s11,104(a1)
    80002b36:	8082                	ret

0000000080002b38 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b38:	1141                	addi	sp,sp,-16
    80002b3a:	e406                	sd	ra,8(sp)
    80002b3c:	e022                	sd	s0,0(sp)
    80002b3e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b40:	00005597          	auipc	a1,0x5
    80002b44:	7b058593          	addi	a1,a1,1968 # 800082f0 <states.1745+0x30>
    80002b48:	00015517          	auipc	a0,0x15
    80002b4c:	ed050513          	addi	a0,a0,-304 # 80017a18 <tickslock>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	004080e7          	jalr	4(ra) # 80000b54 <initlock>
}
    80002b58:	60a2                	ld	ra,8(sp)
    80002b5a:	6402                	ld	s0,0(sp)
    80002b5c:	0141                	addi	sp,sp,16
    80002b5e:	8082                	ret

0000000080002b60 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b60:	1141                	addi	sp,sp,-16
    80002b62:	e422                	sd	s0,8(sp)
    80002b64:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b66:	00003797          	auipc	a5,0x3
    80002b6a:	4ca78793          	addi	a5,a5,1226 # 80006030 <kernelvec>
    80002b6e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b72:	6422                	ld	s0,8(sp)
    80002b74:	0141                	addi	sp,sp,16
    80002b76:	8082                	ret

0000000080002b78 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b78:	1141                	addi	sp,sp,-16
    80002b7a:	e406                	sd	ra,8(sp)
    80002b7c:	e022                	sd	s0,0(sp)
    80002b7e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b80:	fffff097          	auipc	ra,0xfffff
    80002b84:	d88080e7          	jalr	-632(ra) # 80001908 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b8c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b8e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002b92:	00004617          	auipc	a2,0x4
    80002b96:	46e60613          	addi	a2,a2,1134 # 80007000 <_trampoline>
    80002b9a:	00004697          	auipc	a3,0x4
    80002b9e:	46668693          	addi	a3,a3,1126 # 80007000 <_trampoline>
    80002ba2:	8e91                	sub	a3,a3,a2
    80002ba4:	040007b7          	lui	a5,0x4000
    80002ba8:	17fd                	addi	a5,a5,-1
    80002baa:	07b2                	slli	a5,a5,0xc
    80002bac:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bae:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bb2:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bb4:	180026f3          	csrr	a3,satp
    80002bb8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bba:	7d38                	ld	a4,120(a0)
    80002bbc:	7134                	ld	a3,96(a0)
    80002bbe:	6585                	lui	a1,0x1
    80002bc0:	96ae                	add	a3,a3,a1
    80002bc2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bc4:	7d38                	ld	a4,120(a0)
    80002bc6:	00000697          	auipc	a3,0x0
    80002bca:	13868693          	addi	a3,a3,312 # 80002cfe <usertrap>
    80002bce:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bd0:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bd2:	8692                	mv	a3,tp
    80002bd4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bda:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bde:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002be6:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002be8:	6f18                	ld	a4,24(a4)
    80002bea:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bee:	792c                	ld	a1,112(a0)
    80002bf0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002bf2:	00004717          	auipc	a4,0x4
    80002bf6:	49e70713          	addi	a4,a4,1182 # 80007090 <userret>
    80002bfa:	8f11                	sub	a4,a4,a2
    80002bfc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002bfe:	577d                	li	a4,-1
    80002c00:	177e                	slli	a4,a4,0x3f
    80002c02:	8dd9                	or	a1,a1,a4
    80002c04:	02000537          	lui	a0,0x2000
    80002c08:	157d                	addi	a0,a0,-1
    80002c0a:	0536                	slli	a0,a0,0xd
    80002c0c:	9782                	jalr	a5
}
    80002c0e:	60a2                	ld	ra,8(sp)
    80002c10:	6402                	ld	s0,0(sp)
    80002c12:	0141                	addi	sp,sp,16
    80002c14:	8082                	ret

0000000080002c16 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c16:	1101                	addi	sp,sp,-32
    80002c18:	ec06                	sd	ra,24(sp)
    80002c1a:	e822                	sd	s0,16(sp)
    80002c1c:	e426                	sd	s1,8(sp)
    80002c1e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c20:	00015497          	auipc	s1,0x15
    80002c24:	df848493          	addi	s1,s1,-520 # 80017a18 <tickslock>
    80002c28:	8526                	mv	a0,s1
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	fba080e7          	jalr	-70(ra) # 80000be4 <acquire>
  ticks++;
    80002c32:	00006517          	auipc	a0,0x6
    80002c36:	3fe50513          	addi	a0,a0,1022 # 80009030 <ticks>
    80002c3a:	411c                	lw	a5,0(a0)
    80002c3c:	2785                	addiw	a5,a5,1
    80002c3e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	7da080e7          	jalr	2010(ra) # 8000241a <wakeup>
  release(&tickslock);
    80002c48:	8526                	mv	a0,s1
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	04e080e7          	jalr	78(ra) # 80000c98 <release>
}
    80002c52:	60e2                	ld	ra,24(sp)
    80002c54:	6442                	ld	s0,16(sp)
    80002c56:	64a2                	ld	s1,8(sp)
    80002c58:	6105                	addi	sp,sp,32
    80002c5a:	8082                	ret

0000000080002c5c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	e426                	sd	s1,8(sp)
    80002c64:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c66:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c6a:	00074d63          	bltz	a4,80002c84 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c6e:	57fd                	li	a5,-1
    80002c70:	17fe                	slli	a5,a5,0x3f
    80002c72:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c74:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c76:	06f70363          	beq	a4,a5,80002cdc <devintr+0x80>
  }
}
    80002c7a:	60e2                	ld	ra,24(sp)
    80002c7c:	6442                	ld	s0,16(sp)
    80002c7e:	64a2                	ld	s1,8(sp)
    80002c80:	6105                	addi	sp,sp,32
    80002c82:	8082                	ret
     (scause & 0xff) == 9){
    80002c84:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c88:	46a5                	li	a3,9
    80002c8a:	fed792e3          	bne	a5,a3,80002c6e <devintr+0x12>
    int irq = plic_claim();
    80002c8e:	00003097          	auipc	ra,0x3
    80002c92:	4aa080e7          	jalr	1194(ra) # 80006138 <plic_claim>
    80002c96:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c98:	47a9                	li	a5,10
    80002c9a:	02f50763          	beq	a0,a5,80002cc8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c9e:	4785                	li	a5,1
    80002ca0:	02f50963          	beq	a0,a5,80002cd2 <devintr+0x76>
    return 1;
    80002ca4:	4505                	li	a0,1
    } else if(irq){
    80002ca6:	d8f1                	beqz	s1,80002c7a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ca8:	85a6                	mv	a1,s1
    80002caa:	00005517          	auipc	a0,0x5
    80002cae:	64e50513          	addi	a0,a0,1614 # 800082f8 <states.1745+0x38>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8d6080e7          	jalr	-1834(ra) # 80000588 <printf>
      plic_complete(irq);
    80002cba:	8526                	mv	a0,s1
    80002cbc:	00003097          	auipc	ra,0x3
    80002cc0:	4a0080e7          	jalr	1184(ra) # 8000615c <plic_complete>
    return 1;
    80002cc4:	4505                	li	a0,1
    80002cc6:	bf55                	j	80002c7a <devintr+0x1e>
      uartintr();
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	ce0080e7          	jalr	-800(ra) # 800009a8 <uartintr>
    80002cd0:	b7ed                	j	80002cba <devintr+0x5e>
      virtio_disk_intr();
    80002cd2:	00004097          	auipc	ra,0x4
    80002cd6:	96a080e7          	jalr	-1686(ra) # 8000663c <virtio_disk_intr>
    80002cda:	b7c5                	j	80002cba <devintr+0x5e>
    if(cpuid() == 0){
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	bf8080e7          	jalr	-1032(ra) # 800018d4 <cpuid>
    80002ce4:	c901                	beqz	a0,80002cf4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ce6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cec:	14479073          	csrw	sip,a5
    return 2;
    80002cf0:	4509                	li	a0,2
    80002cf2:	b761                	j	80002c7a <devintr+0x1e>
      clockintr();
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	f22080e7          	jalr	-222(ra) # 80002c16 <clockintr>
    80002cfc:	b7ed                	j	80002ce6 <devintr+0x8a>

0000000080002cfe <usertrap>:
{
    80002cfe:	1101                	addi	sp,sp,-32
    80002d00:	ec06                	sd	ra,24(sp)
    80002d02:	e822                	sd	s0,16(sp)
    80002d04:	e426                	sd	s1,8(sp)
    80002d06:	e04a                	sd	s2,0(sp)
    80002d08:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d0a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d0e:	1007f793          	andi	a5,a5,256
    80002d12:	e3ad                	bnez	a5,80002d74 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d14:	00003797          	auipc	a5,0x3
    80002d18:	31c78793          	addi	a5,a5,796 # 80006030 <kernelvec>
    80002d1c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	be8080e7          	jalr	-1048(ra) # 80001908 <myproc>
    80002d28:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d2a:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d2c:	14102773          	csrr	a4,sepc
    80002d30:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d32:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d36:	47a1                	li	a5,8
    80002d38:	04f71c63          	bne	a4,a5,80002d90 <usertrap+0x92>
    if(p->killed)
    80002d3c:	551c                	lw	a5,40(a0)
    80002d3e:	e3b9                	bnez	a5,80002d84 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d40:	7cb8                	ld	a4,120(s1)
    80002d42:	6f1c                	ld	a5,24(a4)
    80002d44:	0791                	addi	a5,a5,4
    80002d46:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d4c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d50:	10079073          	csrw	sstatus,a5
    syscall();
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	2e0080e7          	jalr	736(ra) # 80003034 <syscall>
  if(p->killed)
    80002d5c:	549c                	lw	a5,40(s1)
    80002d5e:	ebc1                	bnez	a5,80002dee <usertrap+0xf0>
  usertrapret();
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	e18080e7          	jalr	-488(ra) # 80002b78 <usertrapret>
}
    80002d68:	60e2                	ld	ra,24(sp)
    80002d6a:	6442                	ld	s0,16(sp)
    80002d6c:	64a2                	ld	s1,8(sp)
    80002d6e:	6902                	ld	s2,0(sp)
    80002d70:	6105                	addi	sp,sp,32
    80002d72:	8082                	ret
    panic("usertrap: not from user mode");
    80002d74:	00005517          	auipc	a0,0x5
    80002d78:	5a450513          	addi	a0,a0,1444 # 80008318 <states.1745+0x58>
    80002d7c:	ffffd097          	auipc	ra,0xffffd
    80002d80:	7c2080e7          	jalr	1986(ra) # 8000053e <panic>
      exit(-1);
    80002d84:	557d                	li	a0,-1
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	7f8080e7          	jalr	2040(ra) # 8000257e <exit>
    80002d8e:	bf4d                	j	80002d40 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	ecc080e7          	jalr	-308(ra) # 80002c5c <devintr>
    80002d98:	892a                	mv	s2,a0
    80002d9a:	c501                	beqz	a0,80002da2 <usertrap+0xa4>
  if(p->killed)
    80002d9c:	549c                	lw	a5,40(s1)
    80002d9e:	c3a1                	beqz	a5,80002dde <usertrap+0xe0>
    80002da0:	a815                	j	80002dd4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002da2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002da6:	5890                	lw	a2,48(s1)
    80002da8:	00005517          	auipc	a0,0x5
    80002dac:	59050513          	addi	a0,a0,1424 # 80008338 <states.1745+0x78>
    80002db0:	ffffd097          	auipc	ra,0xffffd
    80002db4:	7d8080e7          	jalr	2008(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002db8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dbc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dc0:	00005517          	auipc	a0,0x5
    80002dc4:	5a850513          	addi	a0,a0,1448 # 80008368 <states.1745+0xa8>
    80002dc8:	ffffd097          	auipc	ra,0xffffd
    80002dcc:	7c0080e7          	jalr	1984(ra) # 80000588 <printf>
    p->killed = 1;
    80002dd0:	4785                	li	a5,1
    80002dd2:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002dd4:	557d                	li	a0,-1
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	7a8080e7          	jalr	1960(ra) # 8000257e <exit>
  if(which_dev == 2)
    80002dde:	4789                	li	a5,2
    80002de0:	f8f910e3          	bne	s2,a5,80002d60 <usertrap+0x62>
    yield();
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	21c080e7          	jalr	540(ra) # 80002000 <yield>
    80002dec:	bf95                	j	80002d60 <usertrap+0x62>
  int which_dev = 0;
    80002dee:	4901                	li	s2,0
    80002df0:	b7d5                	j	80002dd4 <usertrap+0xd6>

0000000080002df2 <kerneltrap>:
{
    80002df2:	7179                	addi	sp,sp,-48
    80002df4:	f406                	sd	ra,40(sp)
    80002df6:	f022                	sd	s0,32(sp)
    80002df8:	ec26                	sd	s1,24(sp)
    80002dfa:	e84a                	sd	s2,16(sp)
    80002dfc:	e44e                	sd	s3,8(sp)
    80002dfe:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e00:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e04:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e08:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e0c:	1004f793          	andi	a5,s1,256
    80002e10:	cb85                	beqz	a5,80002e40 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e16:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e18:	ef85                	bnez	a5,80002e50 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	e42080e7          	jalr	-446(ra) # 80002c5c <devintr>
    80002e22:	cd1d                	beqz	a0,80002e60 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e24:	4789                	li	a5,2
    80002e26:	06f50a63          	beq	a0,a5,80002e9a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e2a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e2e:	10049073          	csrw	sstatus,s1
}
    80002e32:	70a2                	ld	ra,40(sp)
    80002e34:	7402                	ld	s0,32(sp)
    80002e36:	64e2                	ld	s1,24(sp)
    80002e38:	6942                	ld	s2,16(sp)
    80002e3a:	69a2                	ld	s3,8(sp)
    80002e3c:	6145                	addi	sp,sp,48
    80002e3e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e40:	00005517          	auipc	a0,0x5
    80002e44:	54850513          	addi	a0,a0,1352 # 80008388 <states.1745+0xc8>
    80002e48:	ffffd097          	auipc	ra,0xffffd
    80002e4c:	6f6080e7          	jalr	1782(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	56050513          	addi	a0,a0,1376 # 800083b0 <states.1745+0xf0>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	6e6080e7          	jalr	1766(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002e60:	85ce                	mv	a1,s3
    80002e62:	00005517          	auipc	a0,0x5
    80002e66:	56e50513          	addi	a0,a0,1390 # 800083d0 <states.1745+0x110>
    80002e6a:	ffffd097          	auipc	ra,0xffffd
    80002e6e:	71e080e7          	jalr	1822(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e76:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e7a:	00005517          	auipc	a0,0x5
    80002e7e:	56650513          	addi	a0,a0,1382 # 800083e0 <states.1745+0x120>
    80002e82:	ffffd097          	auipc	ra,0xffffd
    80002e86:	706080e7          	jalr	1798(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002e8a:	00005517          	auipc	a0,0x5
    80002e8e:	56e50513          	addi	a0,a0,1390 # 800083f8 <states.1745+0x138>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6ac080e7          	jalr	1708(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	a6e080e7          	jalr	-1426(ra) # 80001908 <myproc>
    80002ea2:	d541                	beqz	a0,80002e2a <kerneltrap+0x38>
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	a64080e7          	jalr	-1436(ra) # 80001908 <myproc>
    80002eac:	4d18                	lw	a4,24(a0)
    80002eae:	4791                	li	a5,4
    80002eb0:	f6f71de3          	bne	a4,a5,80002e2a <kerneltrap+0x38>
    yield();
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	14c080e7          	jalr	332(ra) # 80002000 <yield>
    80002ebc:	b7bd                	j	80002e2a <kerneltrap+0x38>

0000000080002ebe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ebe:	1101                	addi	sp,sp,-32
    80002ec0:	ec06                	sd	ra,24(sp)
    80002ec2:	e822                	sd	s0,16(sp)
    80002ec4:	e426                	sd	s1,8(sp)
    80002ec6:	1000                	addi	s0,sp,32
    80002ec8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	a3e080e7          	jalr	-1474(ra) # 80001908 <myproc>
  switch (n) {
    80002ed2:	4795                	li	a5,5
    80002ed4:	0497e163          	bltu	a5,s1,80002f16 <argraw+0x58>
    80002ed8:	048a                	slli	s1,s1,0x2
    80002eda:	00005717          	auipc	a4,0x5
    80002ede:	55670713          	addi	a4,a4,1366 # 80008430 <states.1745+0x170>
    80002ee2:	94ba                	add	s1,s1,a4
    80002ee4:	409c                	lw	a5,0(s1)
    80002ee6:	97ba                	add	a5,a5,a4
    80002ee8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002eea:	7d3c                	ld	a5,120(a0)
    80002eec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	64a2                	ld	s1,8(sp)
    80002ef4:	6105                	addi	sp,sp,32
    80002ef6:	8082                	ret
    return p->trapframe->a1;
    80002ef8:	7d3c                	ld	a5,120(a0)
    80002efa:	7fa8                	ld	a0,120(a5)
    80002efc:	bfcd                	j	80002eee <argraw+0x30>
    return p->trapframe->a2;
    80002efe:	7d3c                	ld	a5,120(a0)
    80002f00:	63c8                	ld	a0,128(a5)
    80002f02:	b7f5                	j	80002eee <argraw+0x30>
    return p->trapframe->a3;
    80002f04:	7d3c                	ld	a5,120(a0)
    80002f06:	67c8                	ld	a0,136(a5)
    80002f08:	b7dd                	j	80002eee <argraw+0x30>
    return p->trapframe->a4;
    80002f0a:	7d3c                	ld	a5,120(a0)
    80002f0c:	6bc8                	ld	a0,144(a5)
    80002f0e:	b7c5                	j	80002eee <argraw+0x30>
    return p->trapframe->a5;
    80002f10:	7d3c                	ld	a5,120(a0)
    80002f12:	6fc8                	ld	a0,152(a5)
    80002f14:	bfe9                	j	80002eee <argraw+0x30>
  panic("argraw");
    80002f16:	00005517          	auipc	a0,0x5
    80002f1a:	4f250513          	addi	a0,a0,1266 # 80008408 <states.1745+0x148>
    80002f1e:	ffffd097          	auipc	ra,0xffffd
    80002f22:	620080e7          	jalr	1568(ra) # 8000053e <panic>

0000000080002f26 <fetchaddr>:
{
    80002f26:	1101                	addi	sp,sp,-32
    80002f28:	ec06                	sd	ra,24(sp)
    80002f2a:	e822                	sd	s0,16(sp)
    80002f2c:	e426                	sd	s1,8(sp)
    80002f2e:	e04a                	sd	s2,0(sp)
    80002f30:	1000                	addi	s0,sp,32
    80002f32:	84aa                	mv	s1,a0
    80002f34:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	9d2080e7          	jalr	-1582(ra) # 80001908 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f3e:	753c                	ld	a5,104(a0)
    80002f40:	02f4f863          	bgeu	s1,a5,80002f70 <fetchaddr+0x4a>
    80002f44:	00848713          	addi	a4,s1,8
    80002f48:	02e7e663          	bltu	a5,a4,80002f74 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f4c:	46a1                	li	a3,8
    80002f4e:	8626                	mv	a2,s1
    80002f50:	85ca                	mv	a1,s2
    80002f52:	7928                	ld	a0,112(a0)
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	7aa080e7          	jalr	1962(ra) # 800016fe <copyin>
    80002f5c:	00a03533          	snez	a0,a0
    80002f60:	40a00533          	neg	a0,a0
}
    80002f64:	60e2                	ld	ra,24(sp)
    80002f66:	6442                	ld	s0,16(sp)
    80002f68:	64a2                	ld	s1,8(sp)
    80002f6a:	6902                	ld	s2,0(sp)
    80002f6c:	6105                	addi	sp,sp,32
    80002f6e:	8082                	ret
    return -1;
    80002f70:	557d                	li	a0,-1
    80002f72:	bfcd                	j	80002f64 <fetchaddr+0x3e>
    80002f74:	557d                	li	a0,-1
    80002f76:	b7fd                	j	80002f64 <fetchaddr+0x3e>

0000000080002f78 <fetchstr>:
{
    80002f78:	7179                	addi	sp,sp,-48
    80002f7a:	f406                	sd	ra,40(sp)
    80002f7c:	f022                	sd	s0,32(sp)
    80002f7e:	ec26                	sd	s1,24(sp)
    80002f80:	e84a                	sd	s2,16(sp)
    80002f82:	e44e                	sd	s3,8(sp)
    80002f84:	1800                	addi	s0,sp,48
    80002f86:	892a                	mv	s2,a0
    80002f88:	84ae                	mv	s1,a1
    80002f8a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	97c080e7          	jalr	-1668(ra) # 80001908 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f94:	86ce                	mv	a3,s3
    80002f96:	864a                	mv	a2,s2
    80002f98:	85a6                	mv	a1,s1
    80002f9a:	7928                	ld	a0,112(a0)
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	7ee080e7          	jalr	2030(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002fa4:	00054763          	bltz	a0,80002fb2 <fetchstr+0x3a>
  return strlen(buf);
    80002fa8:	8526                	mv	a0,s1
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	eba080e7          	jalr	-326(ra) # 80000e64 <strlen>
}
    80002fb2:	70a2                	ld	ra,40(sp)
    80002fb4:	7402                	ld	s0,32(sp)
    80002fb6:	64e2                	ld	s1,24(sp)
    80002fb8:	6942                	ld	s2,16(sp)
    80002fba:	69a2                	ld	s3,8(sp)
    80002fbc:	6145                	addi	sp,sp,48
    80002fbe:	8082                	ret

0000000080002fc0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002fc0:	1101                	addi	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	e426                	sd	s1,8(sp)
    80002fc8:	1000                	addi	s0,sp,32
    80002fca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fcc:	00000097          	auipc	ra,0x0
    80002fd0:	ef2080e7          	jalr	-270(ra) # 80002ebe <argraw>
    80002fd4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002fd6:	4501                	li	a0,0
    80002fd8:	60e2                	ld	ra,24(sp)
    80002fda:	6442                	ld	s0,16(sp)
    80002fdc:	64a2                	ld	s1,8(sp)
    80002fde:	6105                	addi	sp,sp,32
    80002fe0:	8082                	ret

0000000080002fe2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002fe2:	1101                	addi	sp,sp,-32
    80002fe4:	ec06                	sd	ra,24(sp)
    80002fe6:	e822                	sd	s0,16(sp)
    80002fe8:	e426                	sd	s1,8(sp)
    80002fea:	1000                	addi	s0,sp,32
    80002fec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fee:	00000097          	auipc	ra,0x0
    80002ff2:	ed0080e7          	jalr	-304(ra) # 80002ebe <argraw>
    80002ff6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ff8:	4501                	li	a0,0
    80002ffa:	60e2                	ld	ra,24(sp)
    80002ffc:	6442                	ld	s0,16(sp)
    80002ffe:	64a2                	ld	s1,8(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret

0000000080003004 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003004:	1101                	addi	sp,sp,-32
    80003006:	ec06                	sd	ra,24(sp)
    80003008:	e822                	sd	s0,16(sp)
    8000300a:	e426                	sd	s1,8(sp)
    8000300c:	e04a                	sd	s2,0(sp)
    8000300e:	1000                	addi	s0,sp,32
    80003010:	84ae                	mv	s1,a1
    80003012:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003014:	00000097          	auipc	ra,0x0
    80003018:	eaa080e7          	jalr	-342(ra) # 80002ebe <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000301c:	864a                	mv	a2,s2
    8000301e:	85a6                	mv	a1,s1
    80003020:	00000097          	auipc	ra,0x0
    80003024:	f58080e7          	jalr	-168(ra) # 80002f78 <fetchstr>
}
    80003028:	60e2                	ld	ra,24(sp)
    8000302a:	6442                	ld	s0,16(sp)
    8000302c:	64a2                	ld	s1,8(sp)
    8000302e:	6902                	ld	s2,0(sp)
    80003030:	6105                	addi	sp,sp,32
    80003032:	8082                	ret

0000000080003034 <syscall>:
[SYS_get_cpu] sys_get_cpu,
};

void
syscall(void)
{
    80003034:	1101                	addi	sp,sp,-32
    80003036:	ec06                	sd	ra,24(sp)
    80003038:	e822                	sd	s0,16(sp)
    8000303a:	e426                	sd	s1,8(sp)
    8000303c:	e04a                	sd	s2,0(sp)
    8000303e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	8c8080e7          	jalr	-1848(ra) # 80001908 <myproc>
    80003048:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000304a:	07853903          	ld	s2,120(a0)
    8000304e:	0a893783          	ld	a5,168(s2)
    80003052:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003056:	37fd                	addiw	a5,a5,-1
    80003058:	4759                	li	a4,22
    8000305a:	00f76f63          	bltu	a4,a5,80003078 <syscall+0x44>
    8000305e:	00369713          	slli	a4,a3,0x3
    80003062:	00005797          	auipc	a5,0x5
    80003066:	3e678793          	addi	a5,a5,998 # 80008448 <syscalls>
    8000306a:	97ba                	add	a5,a5,a4
    8000306c:	639c                	ld	a5,0(a5)
    8000306e:	c789                	beqz	a5,80003078 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003070:	9782                	jalr	a5
    80003072:	06a93823          	sd	a0,112(s2)
    80003076:	a839                	j	80003094 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003078:	17848613          	addi	a2,s1,376
    8000307c:	588c                	lw	a1,48(s1)
    8000307e:	00005517          	auipc	a0,0x5
    80003082:	39250513          	addi	a0,a0,914 # 80008410 <states.1745+0x150>
    80003086:	ffffd097          	auipc	ra,0xffffd
    8000308a:	502080e7          	jalr	1282(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000308e:	7cbc                	ld	a5,120(s1)
    80003090:	577d                	li	a4,-1
    80003092:	fbb8                	sd	a4,112(a5)
  }
}
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	64a2                	ld	s1,8(sp)
    8000309a:	6902                	ld	s2,0(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret

00000000800030a0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800030a8:	fec40593          	addi	a1,s0,-20
    800030ac:	4501                	li	a0,0
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	f12080e7          	jalr	-238(ra) # 80002fc0 <argint>
    return -1;
    800030b6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030b8:	00054963          	bltz	a0,800030ca <sys_exit+0x2a>
  exit(n);
    800030bc:	fec42503          	lw	a0,-20(s0)
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	4be080e7          	jalr	1214(ra) # 8000257e <exit>
  return 0;  // not reached
    800030c8:	4781                	li	a5,0
}
    800030ca:	853e                	mv	a0,a5
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret

00000000800030d4 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030d4:	1141                	addi	sp,sp,-16
    800030d6:	e406                	sd	ra,8(sp)
    800030d8:	e022                	sd	s0,0(sp)
    800030da:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800030dc:	fffff097          	auipc	ra,0xfffff
    800030e0:	82c080e7          	jalr	-2004(ra) # 80001908 <myproc>
}
    800030e4:	5908                	lw	a0,48(a0)
    800030e6:	60a2                	ld	ra,8(sp)
    800030e8:	6402                	ld	s0,0(sp)
    800030ea:	0141                	addi	sp,sp,16
    800030ec:	8082                	ret

00000000800030ee <sys_fork>:

uint64
sys_fork(void)
{
    800030ee:	1141                	addi	sp,sp,-16
    800030f0:	e406                	sd	ra,8(sp)
    800030f2:	e022                	sd	s0,0(sp)
    800030f4:	0800                	addi	s0,sp,16
  return fork();
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	7ae080e7          	jalr	1966(ra) # 800028a4 <fork>
}
    800030fe:	60a2                	ld	ra,8(sp)
    80003100:	6402                	ld	s0,0(sp)
    80003102:	0141                	addi	sp,sp,16
    80003104:	8082                	ret

0000000080003106 <sys_wait>:

uint64
sys_wait(void)
{
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000310e:	fe840593          	addi	a1,s0,-24
    80003112:	4501                	li	a0,0
    80003114:	00000097          	auipc	ra,0x0
    80003118:	ece080e7          	jalr	-306(ra) # 80002fe2 <argaddr>
    8000311c:	87aa                	mv	a5,a0
    return -1;
    8000311e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003120:	0007c863          	bltz	a5,80003130 <sys_wait+0x2a>
  return wait(p);
    80003124:	fe843503          	ld	a0,-24(s0)
    80003128:	fffff097          	auipc	ra,0xfffff
    8000312c:	1ca080e7          	jalr	458(ra) # 800022f2 <wait>
}
    80003130:	60e2                	ld	ra,24(sp)
    80003132:	6442                	ld	s0,16(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret

0000000080003138 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003138:	7179                	addi	sp,sp,-48
    8000313a:	f406                	sd	ra,40(sp)
    8000313c:	f022                	sd	s0,32(sp)
    8000313e:	ec26                	sd	s1,24(sp)
    80003140:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003142:	fdc40593          	addi	a1,s0,-36
    80003146:	4501                	li	a0,0
    80003148:	00000097          	auipc	ra,0x0
    8000314c:	e78080e7          	jalr	-392(ra) # 80002fc0 <argint>
    80003150:	87aa                	mv	a5,a0
    return -1;
    80003152:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003154:	0207c063          	bltz	a5,80003174 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	7b0080e7          	jalr	1968(ra) # 80001908 <myproc>
    80003160:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003162:	fdc42503          	lw	a0,-36(s0)
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	94e080e7          	jalr	-1714(ra) # 80001ab4 <growproc>
    8000316e:	00054863          	bltz	a0,8000317e <sys_sbrk+0x46>
    return -1;
  return addr;
    80003172:	8526                	mv	a0,s1
}
    80003174:	70a2                	ld	ra,40(sp)
    80003176:	7402                	ld	s0,32(sp)
    80003178:	64e2                	ld	s1,24(sp)
    8000317a:	6145                	addi	sp,sp,48
    8000317c:	8082                	ret
    return -1;
    8000317e:	557d                	li	a0,-1
    80003180:	bfd5                	j	80003174 <sys_sbrk+0x3c>

0000000080003182 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003182:	7139                	addi	sp,sp,-64
    80003184:	fc06                	sd	ra,56(sp)
    80003186:	f822                	sd	s0,48(sp)
    80003188:	f426                	sd	s1,40(sp)
    8000318a:	f04a                	sd	s2,32(sp)
    8000318c:	ec4e                	sd	s3,24(sp)
    8000318e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003190:	fcc40593          	addi	a1,s0,-52
    80003194:	4501                	li	a0,0
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	e2a080e7          	jalr	-470(ra) # 80002fc0 <argint>
    return -1;
    8000319e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031a0:	06054563          	bltz	a0,8000320a <sys_sleep+0x88>
  acquire(&tickslock);
    800031a4:	00015517          	auipc	a0,0x15
    800031a8:	87450513          	addi	a0,a0,-1932 # 80017a18 <tickslock>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	a38080e7          	jalr	-1480(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800031b4:	00006917          	auipc	s2,0x6
    800031b8:	e7c92903          	lw	s2,-388(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800031bc:	fcc42783          	lw	a5,-52(s0)
    800031c0:	cf85                	beqz	a5,800031f8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031c2:	00015997          	auipc	s3,0x15
    800031c6:	85698993          	addi	s3,s3,-1962 # 80017a18 <tickslock>
    800031ca:	00006497          	auipc	s1,0x6
    800031ce:	e6648493          	addi	s1,s1,-410 # 80009030 <ticks>
    if(myproc()->killed){
    800031d2:	ffffe097          	auipc	ra,0xffffe
    800031d6:	736080e7          	jalr	1846(ra) # 80001908 <myproc>
    800031da:	551c                	lw	a5,40(a0)
    800031dc:	ef9d                	bnez	a5,8000321a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800031de:	85ce                	mv	a1,s3
    800031e0:	8526                	mv	a0,s1
    800031e2:	fffff097          	auipc	ra,0xfffff
    800031e6:	ec6080e7          	jalr	-314(ra) # 800020a8 <sleep>
  while(ticks - ticks0 < n){
    800031ea:	409c                	lw	a5,0(s1)
    800031ec:	412787bb          	subw	a5,a5,s2
    800031f0:	fcc42703          	lw	a4,-52(s0)
    800031f4:	fce7efe3          	bltu	a5,a4,800031d2 <sys_sleep+0x50>
  }
  release(&tickslock);
    800031f8:	00015517          	auipc	a0,0x15
    800031fc:	82050513          	addi	a0,a0,-2016 # 80017a18 <tickslock>
    80003200:	ffffe097          	auipc	ra,0xffffe
    80003204:	a98080e7          	jalr	-1384(ra) # 80000c98 <release>
  return 0;
    80003208:	4781                	li	a5,0
}
    8000320a:	853e                	mv	a0,a5
    8000320c:	70e2                	ld	ra,56(sp)
    8000320e:	7442                	ld	s0,48(sp)
    80003210:	74a2                	ld	s1,40(sp)
    80003212:	7902                	ld	s2,32(sp)
    80003214:	69e2                	ld	s3,24(sp)
    80003216:	6121                	addi	sp,sp,64
    80003218:	8082                	ret
      release(&tickslock);
    8000321a:	00014517          	auipc	a0,0x14
    8000321e:	7fe50513          	addi	a0,a0,2046 # 80017a18 <tickslock>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>
      return -1;
    8000322a:	57fd                	li	a5,-1
    8000322c:	bff9                	j	8000320a <sys_sleep+0x88>

000000008000322e <sys_kill>:

uint64
sys_kill(void)
{
    8000322e:	1101                	addi	sp,sp,-32
    80003230:	ec06                	sd	ra,24(sp)
    80003232:	e822                	sd	s0,16(sp)
    80003234:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003236:	fec40593          	addi	a1,s0,-20
    8000323a:	4501                	li	a0,0
    8000323c:	00000097          	auipc	ra,0x0
    80003240:	d84080e7          	jalr	-636(ra) # 80002fc0 <argint>
    80003244:	87aa                	mv	a5,a0
    return -1;
    80003246:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003248:	0007c863          	bltz	a5,80003258 <sys_kill+0x2a>
  return kill(pid);
    8000324c:	fec42503          	lw	a0,-20(s0)
    80003250:	fffff097          	auipc	ra,0xfffff
    80003254:	9c6080e7          	jalr	-1594(ra) # 80001c16 <kill>
}
    80003258:	60e2                	ld	ra,24(sp)
    8000325a:	6442                	ld	s0,16(sp)
    8000325c:	6105                	addi	sp,sp,32
    8000325e:	8082                	ret

0000000080003260 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003260:	1101                	addi	sp,sp,-32
    80003262:	ec06                	sd	ra,24(sp)
    80003264:	e822                	sd	s0,16(sp)
    80003266:	e426                	sd	s1,8(sp)
    80003268:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000326a:	00014517          	auipc	a0,0x14
    8000326e:	7ae50513          	addi	a0,a0,1966 # 80017a18 <tickslock>
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	972080e7          	jalr	-1678(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000327a:	00006497          	auipc	s1,0x6
    8000327e:	db64a483          	lw	s1,-586(s1) # 80009030 <ticks>
  release(&tickslock);
    80003282:	00014517          	auipc	a0,0x14
    80003286:	79650513          	addi	a0,a0,1942 # 80017a18 <tickslock>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	a0e080e7          	jalr	-1522(ra) # 80000c98 <release>
  return xticks;
}
    80003292:	02049513          	slli	a0,s1,0x20
    80003296:	9101                	srli	a0,a0,0x20
    80003298:	60e2                	ld	ra,24(sp)
    8000329a:	6442                	ld	s0,16(sp)
    8000329c:	64a2                	ld	s1,8(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret

00000000800032a2 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    800032a2:	1101                	addi	sp,sp,-32
    800032a4:	ec06                	sd	ra,24(sp)
    800032a6:	e822                	sd	s0,16(sp)
    800032a8:	1000                	addi	s0,sp,32
    int cpu_num;
    if(argint(0, &cpu_num) <= -1){
    800032aa:	fec40593          	addi	a1,s0,-20
    800032ae:	4501                	li	a0,0
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	d10080e7          	jalr	-752(ra) # 80002fc0 <argint>
    800032b8:	87aa                	mv	a5,a0
      return -1;
    800032ba:	557d                	li	a0,-1
    if(argint(0, &cpu_num) <= -1){
    800032bc:	0007c863          	bltz	a5,800032cc <sys_set_cpu+0x2a>
    }
    
    return set_cpu(cpu_num);
    800032c0:	fec42503          	lw	a0,-20(s0)
    800032c4:	fffff097          	auipc	ra,0xfffff
    800032c8:	da6080e7          	jalr	-602(ra) # 8000206a <set_cpu>
}
    800032cc:	60e2                	ld	ra,24(sp)
    800032ce:	6442                	ld	s0,16(sp)
    800032d0:	6105                	addi	sp,sp,32
    800032d2:	8082                	ret

00000000800032d4 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800032d4:	1141                	addi	sp,sp,-16
    800032d6:	e406                	sd	ra,8(sp)
    800032d8:	e022                	sd	s0,0(sp)
    800032da:	0800                	addi	s0,sp,16
    return get_cpu();
    800032dc:	fffff097          	auipc	ra,0xfffff
    800032e0:	b06080e7          	jalr	-1274(ra) # 80001de2 <get_cpu>
    800032e4:	60a2                	ld	ra,8(sp)
    800032e6:	6402                	ld	s0,0(sp)
    800032e8:	0141                	addi	sp,sp,16
    800032ea:	8082                	ret

00000000800032ec <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032ec:	7179                	addi	sp,sp,-48
    800032ee:	f406                	sd	ra,40(sp)
    800032f0:	f022                	sd	s0,32(sp)
    800032f2:	ec26                	sd	s1,24(sp)
    800032f4:	e84a                	sd	s2,16(sp)
    800032f6:	e44e                	sd	s3,8(sp)
    800032f8:	e052                	sd	s4,0(sp)
    800032fa:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032fc:	00005597          	auipc	a1,0x5
    80003300:	20c58593          	addi	a1,a1,524 # 80008508 <syscalls+0xc0>
    80003304:	00014517          	auipc	a0,0x14
    80003308:	72c50513          	addi	a0,a0,1836 # 80017a30 <bcache>
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	848080e7          	jalr	-1976(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003314:	0001c797          	auipc	a5,0x1c
    80003318:	71c78793          	addi	a5,a5,1820 # 8001fa30 <bcache+0x8000>
    8000331c:	0001d717          	auipc	a4,0x1d
    80003320:	97c70713          	addi	a4,a4,-1668 # 8001fc98 <bcache+0x8268>
    80003324:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003328:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000332c:	00014497          	auipc	s1,0x14
    80003330:	71c48493          	addi	s1,s1,1820 # 80017a48 <bcache+0x18>
    b->next = bcache.head.next;
    80003334:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003336:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003338:	00005a17          	auipc	s4,0x5
    8000333c:	1d8a0a13          	addi	s4,s4,472 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003340:	2b893783          	ld	a5,696(s2)
    80003344:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003346:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000334a:	85d2                	mv	a1,s4
    8000334c:	01048513          	addi	a0,s1,16
    80003350:	00001097          	auipc	ra,0x1
    80003354:	4bc080e7          	jalr	1212(ra) # 8000480c <initsleeplock>
    bcache.head.next->prev = b;
    80003358:	2b893783          	ld	a5,696(s2)
    8000335c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000335e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003362:	45848493          	addi	s1,s1,1112
    80003366:	fd349de3          	bne	s1,s3,80003340 <binit+0x54>
  }
}
    8000336a:	70a2                	ld	ra,40(sp)
    8000336c:	7402                	ld	s0,32(sp)
    8000336e:	64e2                	ld	s1,24(sp)
    80003370:	6942                	ld	s2,16(sp)
    80003372:	69a2                	ld	s3,8(sp)
    80003374:	6a02                	ld	s4,0(sp)
    80003376:	6145                	addi	sp,sp,48
    80003378:	8082                	ret

000000008000337a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000337a:	7179                	addi	sp,sp,-48
    8000337c:	f406                	sd	ra,40(sp)
    8000337e:	f022                	sd	s0,32(sp)
    80003380:	ec26                	sd	s1,24(sp)
    80003382:	e84a                	sd	s2,16(sp)
    80003384:	e44e                	sd	s3,8(sp)
    80003386:	1800                	addi	s0,sp,48
    80003388:	89aa                	mv	s3,a0
    8000338a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000338c:	00014517          	auipc	a0,0x14
    80003390:	6a450513          	addi	a0,a0,1700 # 80017a30 <bcache>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	850080e7          	jalr	-1968(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000339c:	0001d497          	auipc	s1,0x1d
    800033a0:	94c4b483          	ld	s1,-1716(s1) # 8001fce8 <bcache+0x82b8>
    800033a4:	0001d797          	auipc	a5,0x1d
    800033a8:	8f478793          	addi	a5,a5,-1804 # 8001fc98 <bcache+0x8268>
    800033ac:	02f48f63          	beq	s1,a5,800033ea <bread+0x70>
    800033b0:	873e                	mv	a4,a5
    800033b2:	a021                	j	800033ba <bread+0x40>
    800033b4:	68a4                	ld	s1,80(s1)
    800033b6:	02e48a63          	beq	s1,a4,800033ea <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033ba:	449c                	lw	a5,8(s1)
    800033bc:	ff379ce3          	bne	a5,s3,800033b4 <bread+0x3a>
    800033c0:	44dc                	lw	a5,12(s1)
    800033c2:	ff2799e3          	bne	a5,s2,800033b4 <bread+0x3a>
      b->refcnt++;
    800033c6:	40bc                	lw	a5,64(s1)
    800033c8:	2785                	addiw	a5,a5,1
    800033ca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033cc:	00014517          	auipc	a0,0x14
    800033d0:	66450513          	addi	a0,a0,1636 # 80017a30 <bcache>
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	8c4080e7          	jalr	-1852(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033dc:	01048513          	addi	a0,s1,16
    800033e0:	00001097          	auipc	ra,0x1
    800033e4:	466080e7          	jalr	1126(ra) # 80004846 <acquiresleep>
      return b;
    800033e8:	a8b9                	j	80003446 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033ea:	0001d497          	auipc	s1,0x1d
    800033ee:	8f64b483          	ld	s1,-1802(s1) # 8001fce0 <bcache+0x82b0>
    800033f2:	0001d797          	auipc	a5,0x1d
    800033f6:	8a678793          	addi	a5,a5,-1882 # 8001fc98 <bcache+0x8268>
    800033fa:	00f48863          	beq	s1,a5,8000340a <bread+0x90>
    800033fe:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003400:	40bc                	lw	a5,64(s1)
    80003402:	cf81                	beqz	a5,8000341a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003404:	64a4                	ld	s1,72(s1)
    80003406:	fee49de3          	bne	s1,a4,80003400 <bread+0x86>
  panic("bget: no buffers");
    8000340a:	00005517          	auipc	a0,0x5
    8000340e:	10e50513          	addi	a0,a0,270 # 80008518 <syscalls+0xd0>
    80003412:	ffffd097          	auipc	ra,0xffffd
    80003416:	12c080e7          	jalr	300(ra) # 8000053e <panic>
      b->dev = dev;
    8000341a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000341e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003422:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003426:	4785                	li	a5,1
    80003428:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000342a:	00014517          	auipc	a0,0x14
    8000342e:	60650513          	addi	a0,a0,1542 # 80017a30 <bcache>
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000343a:	01048513          	addi	a0,s1,16
    8000343e:	00001097          	auipc	ra,0x1
    80003442:	408080e7          	jalr	1032(ra) # 80004846 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003446:	409c                	lw	a5,0(s1)
    80003448:	cb89                	beqz	a5,8000345a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000344a:	8526                	mv	a0,s1
    8000344c:	70a2                	ld	ra,40(sp)
    8000344e:	7402                	ld	s0,32(sp)
    80003450:	64e2                	ld	s1,24(sp)
    80003452:	6942                	ld	s2,16(sp)
    80003454:	69a2                	ld	s3,8(sp)
    80003456:	6145                	addi	sp,sp,48
    80003458:	8082                	ret
    virtio_disk_rw(b, 0);
    8000345a:	4581                	li	a1,0
    8000345c:	8526                	mv	a0,s1
    8000345e:	00003097          	auipc	ra,0x3
    80003462:	f08080e7          	jalr	-248(ra) # 80006366 <virtio_disk_rw>
    b->valid = 1;
    80003466:	4785                	li	a5,1
    80003468:	c09c                	sw	a5,0(s1)
  return b;
    8000346a:	b7c5                	j	8000344a <bread+0xd0>

000000008000346c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000346c:	1101                	addi	sp,sp,-32
    8000346e:	ec06                	sd	ra,24(sp)
    80003470:	e822                	sd	s0,16(sp)
    80003472:	e426                	sd	s1,8(sp)
    80003474:	1000                	addi	s0,sp,32
    80003476:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003478:	0541                	addi	a0,a0,16
    8000347a:	00001097          	auipc	ra,0x1
    8000347e:	466080e7          	jalr	1126(ra) # 800048e0 <holdingsleep>
    80003482:	cd01                	beqz	a0,8000349a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003484:	4585                	li	a1,1
    80003486:	8526                	mv	a0,s1
    80003488:	00003097          	auipc	ra,0x3
    8000348c:	ede080e7          	jalr	-290(ra) # 80006366 <virtio_disk_rw>
}
    80003490:	60e2                	ld	ra,24(sp)
    80003492:	6442                	ld	s0,16(sp)
    80003494:	64a2                	ld	s1,8(sp)
    80003496:	6105                	addi	sp,sp,32
    80003498:	8082                	ret
    panic("bwrite");
    8000349a:	00005517          	auipc	a0,0x5
    8000349e:	09650513          	addi	a0,a0,150 # 80008530 <syscalls+0xe8>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	09c080e7          	jalr	156(ra) # 8000053e <panic>

00000000800034aa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034aa:	1101                	addi	sp,sp,-32
    800034ac:	ec06                	sd	ra,24(sp)
    800034ae:	e822                	sd	s0,16(sp)
    800034b0:	e426                	sd	s1,8(sp)
    800034b2:	e04a                	sd	s2,0(sp)
    800034b4:	1000                	addi	s0,sp,32
    800034b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034b8:	01050913          	addi	s2,a0,16
    800034bc:	854a                	mv	a0,s2
    800034be:	00001097          	auipc	ra,0x1
    800034c2:	422080e7          	jalr	1058(ra) # 800048e0 <holdingsleep>
    800034c6:	c92d                	beqz	a0,80003538 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034c8:	854a                	mv	a0,s2
    800034ca:	00001097          	auipc	ra,0x1
    800034ce:	3d2080e7          	jalr	978(ra) # 8000489c <releasesleep>

  acquire(&bcache.lock);
    800034d2:	00014517          	auipc	a0,0x14
    800034d6:	55e50513          	addi	a0,a0,1374 # 80017a30 <bcache>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	70a080e7          	jalr	1802(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034e2:	40bc                	lw	a5,64(s1)
    800034e4:	37fd                	addiw	a5,a5,-1
    800034e6:	0007871b          	sext.w	a4,a5
    800034ea:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034ec:	eb05                	bnez	a4,8000351c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034ee:	68bc                	ld	a5,80(s1)
    800034f0:	64b8                	ld	a4,72(s1)
    800034f2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034f4:	64bc                	ld	a5,72(s1)
    800034f6:	68b8                	ld	a4,80(s1)
    800034f8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034fa:	0001c797          	auipc	a5,0x1c
    800034fe:	53678793          	addi	a5,a5,1334 # 8001fa30 <bcache+0x8000>
    80003502:	2b87b703          	ld	a4,696(a5)
    80003506:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003508:	0001c717          	auipc	a4,0x1c
    8000350c:	79070713          	addi	a4,a4,1936 # 8001fc98 <bcache+0x8268>
    80003510:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003512:	2b87b703          	ld	a4,696(a5)
    80003516:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003518:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000351c:	00014517          	auipc	a0,0x14
    80003520:	51450513          	addi	a0,a0,1300 # 80017a30 <bcache>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	774080e7          	jalr	1908(ra) # 80000c98 <release>
}
    8000352c:	60e2                	ld	ra,24(sp)
    8000352e:	6442                	ld	s0,16(sp)
    80003530:	64a2                	ld	s1,8(sp)
    80003532:	6902                	ld	s2,0(sp)
    80003534:	6105                	addi	sp,sp,32
    80003536:	8082                	ret
    panic("brelse");
    80003538:	00005517          	auipc	a0,0x5
    8000353c:	00050513          	mv	a0,a0
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>

0000000080003548 <bpin>:

void
bpin(struct buf *b) {
    80003548:	1101                	addi	sp,sp,-32
    8000354a:	ec06                	sd	ra,24(sp)
    8000354c:	e822                	sd	s0,16(sp)
    8000354e:	e426                	sd	s1,8(sp)
    80003550:	1000                	addi	s0,sp,32
    80003552:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003554:	00014517          	auipc	a0,0x14
    80003558:	4dc50513          	addi	a0,a0,1244 # 80017a30 <bcache>
    8000355c:	ffffd097          	auipc	ra,0xffffd
    80003560:	688080e7          	jalr	1672(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003564:	40bc                	lw	a5,64(s1)
    80003566:	2785                	addiw	a5,a5,1
    80003568:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000356a:	00014517          	auipc	a0,0x14
    8000356e:	4c650513          	addi	a0,a0,1222 # 80017a30 <bcache>
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	726080e7          	jalr	1830(ra) # 80000c98 <release>
}
    8000357a:	60e2                	ld	ra,24(sp)
    8000357c:	6442                	ld	s0,16(sp)
    8000357e:	64a2                	ld	s1,8(sp)
    80003580:	6105                	addi	sp,sp,32
    80003582:	8082                	ret

0000000080003584 <bunpin>:

void
bunpin(struct buf *b) {
    80003584:	1101                	addi	sp,sp,-32
    80003586:	ec06                	sd	ra,24(sp)
    80003588:	e822                	sd	s0,16(sp)
    8000358a:	e426                	sd	s1,8(sp)
    8000358c:	1000                	addi	s0,sp,32
    8000358e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003590:	00014517          	auipc	a0,0x14
    80003594:	4a050513          	addi	a0,a0,1184 # 80017a30 <bcache>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	64c080e7          	jalr	1612(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035a0:	40bc                	lw	a5,64(s1)
    800035a2:	37fd                	addiw	a5,a5,-1
    800035a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035a6:	00014517          	auipc	a0,0x14
    800035aa:	48a50513          	addi	a0,a0,1162 # 80017a30 <bcache>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
}
    800035b6:	60e2                	ld	ra,24(sp)
    800035b8:	6442                	ld	s0,16(sp)
    800035ba:	64a2                	ld	s1,8(sp)
    800035bc:	6105                	addi	sp,sp,32
    800035be:	8082                	ret

00000000800035c0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035c0:	1101                	addi	sp,sp,-32
    800035c2:	ec06                	sd	ra,24(sp)
    800035c4:	e822                	sd	s0,16(sp)
    800035c6:	e426                	sd	s1,8(sp)
    800035c8:	e04a                	sd	s2,0(sp)
    800035ca:	1000                	addi	s0,sp,32
    800035cc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035ce:	00d5d59b          	srliw	a1,a1,0xd
    800035d2:	0001d797          	auipc	a5,0x1d
    800035d6:	b3a7a783          	lw	a5,-1222(a5) # 8002010c <sb+0x1c>
    800035da:	9dbd                	addw	a1,a1,a5
    800035dc:	00000097          	auipc	ra,0x0
    800035e0:	d9e080e7          	jalr	-610(ra) # 8000337a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035e4:	0074f713          	andi	a4,s1,7
    800035e8:	4785                	li	a5,1
    800035ea:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035ee:	14ce                	slli	s1,s1,0x33
    800035f0:	90d9                	srli	s1,s1,0x36
    800035f2:	00950733          	add	a4,a0,s1
    800035f6:	05874703          	lbu	a4,88(a4)
    800035fa:	00e7f6b3          	and	a3,a5,a4
    800035fe:	c69d                	beqz	a3,8000362c <bfree+0x6c>
    80003600:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003602:	94aa                	add	s1,s1,a0
    80003604:	fff7c793          	not	a5,a5
    80003608:	8ff9                	and	a5,a5,a4
    8000360a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000360e:	00001097          	auipc	ra,0x1
    80003612:	118080e7          	jalr	280(ra) # 80004726 <log_write>
  brelse(bp);
    80003616:	854a                	mv	a0,s2
    80003618:	00000097          	auipc	ra,0x0
    8000361c:	e92080e7          	jalr	-366(ra) # 800034aa <brelse>
}
    80003620:	60e2                	ld	ra,24(sp)
    80003622:	6442                	ld	s0,16(sp)
    80003624:	64a2                	ld	s1,8(sp)
    80003626:	6902                	ld	s2,0(sp)
    80003628:	6105                	addi	sp,sp,32
    8000362a:	8082                	ret
    panic("freeing free block");
    8000362c:	00005517          	auipc	a0,0x5
    80003630:	f1450513          	addi	a0,a0,-236 # 80008540 <syscalls+0xf8>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	f0a080e7          	jalr	-246(ra) # 8000053e <panic>

000000008000363c <balloc>:
{
    8000363c:	711d                	addi	sp,sp,-96
    8000363e:	ec86                	sd	ra,88(sp)
    80003640:	e8a2                	sd	s0,80(sp)
    80003642:	e4a6                	sd	s1,72(sp)
    80003644:	e0ca                	sd	s2,64(sp)
    80003646:	fc4e                	sd	s3,56(sp)
    80003648:	f852                	sd	s4,48(sp)
    8000364a:	f456                	sd	s5,40(sp)
    8000364c:	f05a                	sd	s6,32(sp)
    8000364e:	ec5e                	sd	s7,24(sp)
    80003650:	e862                	sd	s8,16(sp)
    80003652:	e466                	sd	s9,8(sp)
    80003654:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003656:	0001d797          	auipc	a5,0x1d
    8000365a:	a9e7a783          	lw	a5,-1378(a5) # 800200f4 <sb+0x4>
    8000365e:	cbd1                	beqz	a5,800036f2 <balloc+0xb6>
    80003660:	8baa                	mv	s7,a0
    80003662:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003664:	0001db17          	auipc	s6,0x1d
    80003668:	a8cb0b13          	addi	s6,s6,-1396 # 800200f0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000366c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000366e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003670:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003672:	6c89                	lui	s9,0x2
    80003674:	a831                	j	80003690 <balloc+0x54>
    brelse(bp);
    80003676:	854a                	mv	a0,s2
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	e32080e7          	jalr	-462(ra) # 800034aa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003680:	015c87bb          	addw	a5,s9,s5
    80003684:	00078a9b          	sext.w	s5,a5
    80003688:	004b2703          	lw	a4,4(s6)
    8000368c:	06eaf363          	bgeu	s5,a4,800036f2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003690:	41fad79b          	sraiw	a5,s5,0x1f
    80003694:	0137d79b          	srliw	a5,a5,0x13
    80003698:	015787bb          	addw	a5,a5,s5
    8000369c:	40d7d79b          	sraiw	a5,a5,0xd
    800036a0:	01cb2583          	lw	a1,28(s6)
    800036a4:	9dbd                	addw	a1,a1,a5
    800036a6:	855e                	mv	a0,s7
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	cd2080e7          	jalr	-814(ra) # 8000337a <bread>
    800036b0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b2:	004b2503          	lw	a0,4(s6)
    800036b6:	000a849b          	sext.w	s1,s5
    800036ba:	8662                	mv	a2,s8
    800036bc:	faa4fde3          	bgeu	s1,a0,80003676 <balloc+0x3a>
      m = 1 << (bi % 8);
    800036c0:	41f6579b          	sraiw	a5,a2,0x1f
    800036c4:	01d7d69b          	srliw	a3,a5,0x1d
    800036c8:	00c6873b          	addw	a4,a3,a2
    800036cc:	00777793          	andi	a5,a4,7
    800036d0:	9f95                	subw	a5,a5,a3
    800036d2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036d6:	4037571b          	sraiw	a4,a4,0x3
    800036da:	00e906b3          	add	a3,s2,a4
    800036de:	0586c683          	lbu	a3,88(a3)
    800036e2:	00d7f5b3          	and	a1,a5,a3
    800036e6:	cd91                	beqz	a1,80003702 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036e8:	2605                	addiw	a2,a2,1
    800036ea:	2485                	addiw	s1,s1,1
    800036ec:	fd4618e3          	bne	a2,s4,800036bc <balloc+0x80>
    800036f0:	b759                	j	80003676 <balloc+0x3a>
  panic("balloc: out of blocks");
    800036f2:	00005517          	auipc	a0,0x5
    800036f6:	e6650513          	addi	a0,a0,-410 # 80008558 <syscalls+0x110>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	e44080e7          	jalr	-444(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003702:	974a                	add	a4,a4,s2
    80003704:	8fd5                	or	a5,a5,a3
    80003706:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000370a:	854a                	mv	a0,s2
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	01a080e7          	jalr	26(ra) # 80004726 <log_write>
        brelse(bp);
    80003714:	854a                	mv	a0,s2
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	d94080e7          	jalr	-620(ra) # 800034aa <brelse>
  bp = bread(dev, bno);
    8000371e:	85a6                	mv	a1,s1
    80003720:	855e                	mv	a0,s7
    80003722:	00000097          	auipc	ra,0x0
    80003726:	c58080e7          	jalr	-936(ra) # 8000337a <bread>
    8000372a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000372c:	40000613          	li	a2,1024
    80003730:	4581                	li	a1,0
    80003732:	05850513          	addi	a0,a0,88
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	5aa080e7          	jalr	1450(ra) # 80000ce0 <memset>
  log_write(bp);
    8000373e:	854a                	mv	a0,s2
    80003740:	00001097          	auipc	ra,0x1
    80003744:	fe6080e7          	jalr	-26(ra) # 80004726 <log_write>
  brelse(bp);
    80003748:	854a                	mv	a0,s2
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	d60080e7          	jalr	-672(ra) # 800034aa <brelse>
}
    80003752:	8526                	mv	a0,s1
    80003754:	60e6                	ld	ra,88(sp)
    80003756:	6446                	ld	s0,80(sp)
    80003758:	64a6                	ld	s1,72(sp)
    8000375a:	6906                	ld	s2,64(sp)
    8000375c:	79e2                	ld	s3,56(sp)
    8000375e:	7a42                	ld	s4,48(sp)
    80003760:	7aa2                	ld	s5,40(sp)
    80003762:	7b02                	ld	s6,32(sp)
    80003764:	6be2                	ld	s7,24(sp)
    80003766:	6c42                	ld	s8,16(sp)
    80003768:	6ca2                	ld	s9,8(sp)
    8000376a:	6125                	addi	sp,sp,96
    8000376c:	8082                	ret

000000008000376e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000376e:	7179                	addi	sp,sp,-48
    80003770:	f406                	sd	ra,40(sp)
    80003772:	f022                	sd	s0,32(sp)
    80003774:	ec26                	sd	s1,24(sp)
    80003776:	e84a                	sd	s2,16(sp)
    80003778:	e44e                	sd	s3,8(sp)
    8000377a:	e052                	sd	s4,0(sp)
    8000377c:	1800                	addi	s0,sp,48
    8000377e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003780:	47ad                	li	a5,11
    80003782:	04b7fe63          	bgeu	a5,a1,800037de <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003786:	ff45849b          	addiw	s1,a1,-12
    8000378a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000378e:	0ff00793          	li	a5,255
    80003792:	0ae7e363          	bltu	a5,a4,80003838 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003796:	08052583          	lw	a1,128(a0)
    8000379a:	c5ad                	beqz	a1,80003804 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000379c:	00092503          	lw	a0,0(s2)
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	bda080e7          	jalr	-1062(ra) # 8000337a <bread>
    800037a8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037aa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037ae:	02049593          	slli	a1,s1,0x20
    800037b2:	9181                	srli	a1,a1,0x20
    800037b4:	058a                	slli	a1,a1,0x2
    800037b6:	00b784b3          	add	s1,a5,a1
    800037ba:	0004a983          	lw	s3,0(s1)
    800037be:	04098d63          	beqz	s3,80003818 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037c2:	8552                	mv	a0,s4
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	ce6080e7          	jalr	-794(ra) # 800034aa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037cc:	854e                	mv	a0,s3
    800037ce:	70a2                	ld	ra,40(sp)
    800037d0:	7402                	ld	s0,32(sp)
    800037d2:	64e2                	ld	s1,24(sp)
    800037d4:	6942                	ld	s2,16(sp)
    800037d6:	69a2                	ld	s3,8(sp)
    800037d8:	6a02                	ld	s4,0(sp)
    800037da:	6145                	addi	sp,sp,48
    800037dc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037de:	02059493          	slli	s1,a1,0x20
    800037e2:	9081                	srli	s1,s1,0x20
    800037e4:	048a                	slli	s1,s1,0x2
    800037e6:	94aa                	add	s1,s1,a0
    800037e8:	0504a983          	lw	s3,80(s1)
    800037ec:	fe0990e3          	bnez	s3,800037cc <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037f0:	4108                	lw	a0,0(a0)
    800037f2:	00000097          	auipc	ra,0x0
    800037f6:	e4a080e7          	jalr	-438(ra) # 8000363c <balloc>
    800037fa:	0005099b          	sext.w	s3,a0
    800037fe:	0534a823          	sw	s3,80(s1)
    80003802:	b7e9                	j	800037cc <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003804:	4108                	lw	a0,0(a0)
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	e36080e7          	jalr	-458(ra) # 8000363c <balloc>
    8000380e:	0005059b          	sext.w	a1,a0
    80003812:	08b92023          	sw	a1,128(s2)
    80003816:	b759                	j	8000379c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003818:	00092503          	lw	a0,0(s2)
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	e20080e7          	jalr	-480(ra) # 8000363c <balloc>
    80003824:	0005099b          	sext.w	s3,a0
    80003828:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000382c:	8552                	mv	a0,s4
    8000382e:	00001097          	auipc	ra,0x1
    80003832:	ef8080e7          	jalr	-264(ra) # 80004726 <log_write>
    80003836:	b771                	j	800037c2 <bmap+0x54>
  panic("bmap: out of range");
    80003838:	00005517          	auipc	a0,0x5
    8000383c:	d3850513          	addi	a0,a0,-712 # 80008570 <syscalls+0x128>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	cfe080e7          	jalr	-770(ra) # 8000053e <panic>

0000000080003848 <iget>:
{
    80003848:	7179                	addi	sp,sp,-48
    8000384a:	f406                	sd	ra,40(sp)
    8000384c:	f022                	sd	s0,32(sp)
    8000384e:	ec26                	sd	s1,24(sp)
    80003850:	e84a                	sd	s2,16(sp)
    80003852:	e44e                	sd	s3,8(sp)
    80003854:	e052                	sd	s4,0(sp)
    80003856:	1800                	addi	s0,sp,48
    80003858:	89aa                	mv	s3,a0
    8000385a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000385c:	0001d517          	auipc	a0,0x1d
    80003860:	8b450513          	addi	a0,a0,-1868 # 80020110 <itable>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	380080e7          	jalr	896(ra) # 80000be4 <acquire>
  empty = 0;
    8000386c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000386e:	0001d497          	auipc	s1,0x1d
    80003872:	8ba48493          	addi	s1,s1,-1862 # 80020128 <itable+0x18>
    80003876:	0001e697          	auipc	a3,0x1e
    8000387a:	34268693          	addi	a3,a3,834 # 80021bb8 <log>
    8000387e:	a039                	j	8000388c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003880:	02090b63          	beqz	s2,800038b6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003884:	08848493          	addi	s1,s1,136
    80003888:	02d48a63          	beq	s1,a3,800038bc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000388c:	449c                	lw	a5,8(s1)
    8000388e:	fef059e3          	blez	a5,80003880 <iget+0x38>
    80003892:	4098                	lw	a4,0(s1)
    80003894:	ff3716e3          	bne	a4,s3,80003880 <iget+0x38>
    80003898:	40d8                	lw	a4,4(s1)
    8000389a:	ff4713e3          	bne	a4,s4,80003880 <iget+0x38>
      ip->ref++;
    8000389e:	2785                	addiw	a5,a5,1
    800038a0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038a2:	0001d517          	auipc	a0,0x1d
    800038a6:	86e50513          	addi	a0,a0,-1938 # 80020110 <itable>
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	3ee080e7          	jalr	1006(ra) # 80000c98 <release>
      return ip;
    800038b2:	8926                	mv	s2,s1
    800038b4:	a03d                	j	800038e2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038b6:	f7f9                	bnez	a5,80003884 <iget+0x3c>
    800038b8:	8926                	mv	s2,s1
    800038ba:	b7e9                	j	80003884 <iget+0x3c>
  if(empty == 0)
    800038bc:	02090c63          	beqz	s2,800038f4 <iget+0xac>
  ip->dev = dev;
    800038c0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038c4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038c8:	4785                	li	a5,1
    800038ca:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038ce:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038d2:	0001d517          	auipc	a0,0x1d
    800038d6:	83e50513          	addi	a0,a0,-1986 # 80020110 <itable>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	3be080e7          	jalr	958(ra) # 80000c98 <release>
}
    800038e2:	854a                	mv	a0,s2
    800038e4:	70a2                	ld	ra,40(sp)
    800038e6:	7402                	ld	s0,32(sp)
    800038e8:	64e2                	ld	s1,24(sp)
    800038ea:	6942                	ld	s2,16(sp)
    800038ec:	69a2                	ld	s3,8(sp)
    800038ee:	6a02                	ld	s4,0(sp)
    800038f0:	6145                	addi	sp,sp,48
    800038f2:	8082                	ret
    panic("iget: no inodes");
    800038f4:	00005517          	auipc	a0,0x5
    800038f8:	c9450513          	addi	a0,a0,-876 # 80008588 <syscalls+0x140>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	c42080e7          	jalr	-958(ra) # 8000053e <panic>

0000000080003904 <fsinit>:
fsinit(int dev) {
    80003904:	7179                	addi	sp,sp,-48
    80003906:	f406                	sd	ra,40(sp)
    80003908:	f022                	sd	s0,32(sp)
    8000390a:	ec26                	sd	s1,24(sp)
    8000390c:	e84a                	sd	s2,16(sp)
    8000390e:	e44e                	sd	s3,8(sp)
    80003910:	1800                	addi	s0,sp,48
    80003912:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003914:	4585                	li	a1,1
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	a64080e7          	jalr	-1436(ra) # 8000337a <bread>
    8000391e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003920:	0001c997          	auipc	s3,0x1c
    80003924:	7d098993          	addi	s3,s3,2000 # 800200f0 <sb>
    80003928:	02000613          	li	a2,32
    8000392c:	05850593          	addi	a1,a0,88
    80003930:	854e                	mv	a0,s3
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	40e080e7          	jalr	1038(ra) # 80000d40 <memmove>
  brelse(bp);
    8000393a:	8526                	mv	a0,s1
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	b6e080e7          	jalr	-1170(ra) # 800034aa <brelse>
  if(sb.magic != FSMAGIC)
    80003944:	0009a703          	lw	a4,0(s3)
    80003948:	102037b7          	lui	a5,0x10203
    8000394c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003950:	02f71263          	bne	a4,a5,80003974 <fsinit+0x70>
  initlog(dev, &sb);
    80003954:	0001c597          	auipc	a1,0x1c
    80003958:	79c58593          	addi	a1,a1,1948 # 800200f0 <sb>
    8000395c:	854a                	mv	a0,s2
    8000395e:	00001097          	auipc	ra,0x1
    80003962:	b4c080e7          	jalr	-1204(ra) # 800044aa <initlog>
}
    80003966:	70a2                	ld	ra,40(sp)
    80003968:	7402                	ld	s0,32(sp)
    8000396a:	64e2                	ld	s1,24(sp)
    8000396c:	6942                	ld	s2,16(sp)
    8000396e:	69a2                	ld	s3,8(sp)
    80003970:	6145                	addi	sp,sp,48
    80003972:	8082                	ret
    panic("invalid file system");
    80003974:	00005517          	auipc	a0,0x5
    80003978:	c2450513          	addi	a0,a0,-988 # 80008598 <syscalls+0x150>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	bc2080e7          	jalr	-1086(ra) # 8000053e <panic>

0000000080003984 <iinit>:
{
    80003984:	7179                	addi	sp,sp,-48
    80003986:	f406                	sd	ra,40(sp)
    80003988:	f022                	sd	s0,32(sp)
    8000398a:	ec26                	sd	s1,24(sp)
    8000398c:	e84a                	sd	s2,16(sp)
    8000398e:	e44e                	sd	s3,8(sp)
    80003990:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003992:	00005597          	auipc	a1,0x5
    80003996:	c1e58593          	addi	a1,a1,-994 # 800085b0 <syscalls+0x168>
    8000399a:	0001c517          	auipc	a0,0x1c
    8000399e:	77650513          	addi	a0,a0,1910 # 80020110 <itable>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	1b2080e7          	jalr	434(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039aa:	0001c497          	auipc	s1,0x1c
    800039ae:	78e48493          	addi	s1,s1,1934 # 80020138 <itable+0x28>
    800039b2:	0001e997          	auipc	s3,0x1e
    800039b6:	21698993          	addi	s3,s3,534 # 80021bc8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039ba:	00005917          	auipc	s2,0x5
    800039be:	bfe90913          	addi	s2,s2,-1026 # 800085b8 <syscalls+0x170>
    800039c2:	85ca                	mv	a1,s2
    800039c4:	8526                	mv	a0,s1
    800039c6:	00001097          	auipc	ra,0x1
    800039ca:	e46080e7          	jalr	-442(ra) # 8000480c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039ce:	08848493          	addi	s1,s1,136
    800039d2:	ff3498e3          	bne	s1,s3,800039c2 <iinit+0x3e>
}
    800039d6:	70a2                	ld	ra,40(sp)
    800039d8:	7402                	ld	s0,32(sp)
    800039da:	64e2                	ld	s1,24(sp)
    800039dc:	6942                	ld	s2,16(sp)
    800039de:	69a2                	ld	s3,8(sp)
    800039e0:	6145                	addi	sp,sp,48
    800039e2:	8082                	ret

00000000800039e4 <ialloc>:
{
    800039e4:	715d                	addi	sp,sp,-80
    800039e6:	e486                	sd	ra,72(sp)
    800039e8:	e0a2                	sd	s0,64(sp)
    800039ea:	fc26                	sd	s1,56(sp)
    800039ec:	f84a                	sd	s2,48(sp)
    800039ee:	f44e                	sd	s3,40(sp)
    800039f0:	f052                	sd	s4,32(sp)
    800039f2:	ec56                	sd	s5,24(sp)
    800039f4:	e85a                	sd	s6,16(sp)
    800039f6:	e45e                	sd	s7,8(sp)
    800039f8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039fa:	0001c717          	auipc	a4,0x1c
    800039fe:	70272703          	lw	a4,1794(a4) # 800200fc <sb+0xc>
    80003a02:	4785                	li	a5,1
    80003a04:	04e7fa63          	bgeu	a5,a4,80003a58 <ialloc+0x74>
    80003a08:	8aaa                	mv	s5,a0
    80003a0a:	8bae                	mv	s7,a1
    80003a0c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a0e:	0001ca17          	auipc	s4,0x1c
    80003a12:	6e2a0a13          	addi	s4,s4,1762 # 800200f0 <sb>
    80003a16:	00048b1b          	sext.w	s6,s1
    80003a1a:	0044d593          	srli	a1,s1,0x4
    80003a1e:	018a2783          	lw	a5,24(s4)
    80003a22:	9dbd                	addw	a1,a1,a5
    80003a24:	8556                	mv	a0,s5
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	954080e7          	jalr	-1708(ra) # 8000337a <bread>
    80003a2e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a30:	05850993          	addi	s3,a0,88
    80003a34:	00f4f793          	andi	a5,s1,15
    80003a38:	079a                	slli	a5,a5,0x6
    80003a3a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a3c:	00099783          	lh	a5,0(s3)
    80003a40:	c785                	beqz	a5,80003a68 <ialloc+0x84>
    brelse(bp);
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	a68080e7          	jalr	-1432(ra) # 800034aa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a4a:	0485                	addi	s1,s1,1
    80003a4c:	00ca2703          	lw	a4,12(s4)
    80003a50:	0004879b          	sext.w	a5,s1
    80003a54:	fce7e1e3          	bltu	a5,a4,80003a16 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a58:	00005517          	auipc	a0,0x5
    80003a5c:	b6850513          	addi	a0,a0,-1176 # 800085c0 <syscalls+0x178>
    80003a60:	ffffd097          	auipc	ra,0xffffd
    80003a64:	ade080e7          	jalr	-1314(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a68:	04000613          	li	a2,64
    80003a6c:	4581                	li	a1,0
    80003a6e:	854e                	mv	a0,s3
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	270080e7          	jalr	624(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a78:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a7c:	854a                	mv	a0,s2
    80003a7e:	00001097          	auipc	ra,0x1
    80003a82:	ca8080e7          	jalr	-856(ra) # 80004726 <log_write>
      brelse(bp);
    80003a86:	854a                	mv	a0,s2
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	a22080e7          	jalr	-1502(ra) # 800034aa <brelse>
      return iget(dev, inum);
    80003a90:	85da                	mv	a1,s6
    80003a92:	8556                	mv	a0,s5
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	db4080e7          	jalr	-588(ra) # 80003848 <iget>
}
    80003a9c:	60a6                	ld	ra,72(sp)
    80003a9e:	6406                	ld	s0,64(sp)
    80003aa0:	74e2                	ld	s1,56(sp)
    80003aa2:	7942                	ld	s2,48(sp)
    80003aa4:	79a2                	ld	s3,40(sp)
    80003aa6:	7a02                	ld	s4,32(sp)
    80003aa8:	6ae2                	ld	s5,24(sp)
    80003aaa:	6b42                	ld	s6,16(sp)
    80003aac:	6ba2                	ld	s7,8(sp)
    80003aae:	6161                	addi	sp,sp,80
    80003ab0:	8082                	ret

0000000080003ab2 <iupdate>:
{
    80003ab2:	1101                	addi	sp,sp,-32
    80003ab4:	ec06                	sd	ra,24(sp)
    80003ab6:	e822                	sd	s0,16(sp)
    80003ab8:	e426                	sd	s1,8(sp)
    80003aba:	e04a                	sd	s2,0(sp)
    80003abc:	1000                	addi	s0,sp,32
    80003abe:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ac0:	415c                	lw	a5,4(a0)
    80003ac2:	0047d79b          	srliw	a5,a5,0x4
    80003ac6:	0001c597          	auipc	a1,0x1c
    80003aca:	6425a583          	lw	a1,1602(a1) # 80020108 <sb+0x18>
    80003ace:	9dbd                	addw	a1,a1,a5
    80003ad0:	4108                	lw	a0,0(a0)
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	8a8080e7          	jalr	-1880(ra) # 8000337a <bread>
    80003ada:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003adc:	05850793          	addi	a5,a0,88
    80003ae0:	40c8                	lw	a0,4(s1)
    80003ae2:	893d                	andi	a0,a0,15
    80003ae4:	051a                	slli	a0,a0,0x6
    80003ae6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003ae8:	04449703          	lh	a4,68(s1)
    80003aec:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003af0:	04649703          	lh	a4,70(s1)
    80003af4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003af8:	04849703          	lh	a4,72(s1)
    80003afc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b00:	04a49703          	lh	a4,74(s1)
    80003b04:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b08:	44f8                	lw	a4,76(s1)
    80003b0a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b0c:	03400613          	li	a2,52
    80003b10:	05048593          	addi	a1,s1,80
    80003b14:	0531                	addi	a0,a0,12
    80003b16:	ffffd097          	auipc	ra,0xffffd
    80003b1a:	22a080e7          	jalr	554(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b1e:	854a                	mv	a0,s2
    80003b20:	00001097          	auipc	ra,0x1
    80003b24:	c06080e7          	jalr	-1018(ra) # 80004726 <log_write>
  brelse(bp);
    80003b28:	854a                	mv	a0,s2
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	980080e7          	jalr	-1664(ra) # 800034aa <brelse>
}
    80003b32:	60e2                	ld	ra,24(sp)
    80003b34:	6442                	ld	s0,16(sp)
    80003b36:	64a2                	ld	s1,8(sp)
    80003b38:	6902                	ld	s2,0(sp)
    80003b3a:	6105                	addi	sp,sp,32
    80003b3c:	8082                	ret

0000000080003b3e <idup>:
{
    80003b3e:	1101                	addi	sp,sp,-32
    80003b40:	ec06                	sd	ra,24(sp)
    80003b42:	e822                	sd	s0,16(sp)
    80003b44:	e426                	sd	s1,8(sp)
    80003b46:	1000                	addi	s0,sp,32
    80003b48:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b4a:	0001c517          	auipc	a0,0x1c
    80003b4e:	5c650513          	addi	a0,a0,1478 # 80020110 <itable>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	092080e7          	jalr	146(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b5a:	449c                	lw	a5,8(s1)
    80003b5c:	2785                	addiw	a5,a5,1
    80003b5e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b60:	0001c517          	auipc	a0,0x1c
    80003b64:	5b050513          	addi	a0,a0,1456 # 80020110 <itable>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	130080e7          	jalr	304(ra) # 80000c98 <release>
}
    80003b70:	8526                	mv	a0,s1
    80003b72:	60e2                	ld	ra,24(sp)
    80003b74:	6442                	ld	s0,16(sp)
    80003b76:	64a2                	ld	s1,8(sp)
    80003b78:	6105                	addi	sp,sp,32
    80003b7a:	8082                	ret

0000000080003b7c <ilock>:
{
    80003b7c:	1101                	addi	sp,sp,-32
    80003b7e:	ec06                	sd	ra,24(sp)
    80003b80:	e822                	sd	s0,16(sp)
    80003b82:	e426                	sd	s1,8(sp)
    80003b84:	e04a                	sd	s2,0(sp)
    80003b86:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b88:	c115                	beqz	a0,80003bac <ilock+0x30>
    80003b8a:	84aa                	mv	s1,a0
    80003b8c:	451c                	lw	a5,8(a0)
    80003b8e:	00f05f63          	blez	a5,80003bac <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b92:	0541                	addi	a0,a0,16
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	cb2080e7          	jalr	-846(ra) # 80004846 <acquiresleep>
  if(ip->valid == 0){
    80003b9c:	40bc                	lw	a5,64(s1)
    80003b9e:	cf99                	beqz	a5,80003bbc <ilock+0x40>
}
    80003ba0:	60e2                	ld	ra,24(sp)
    80003ba2:	6442                	ld	s0,16(sp)
    80003ba4:	64a2                	ld	s1,8(sp)
    80003ba6:	6902                	ld	s2,0(sp)
    80003ba8:	6105                	addi	sp,sp,32
    80003baa:	8082                	ret
    panic("ilock");
    80003bac:	00005517          	auipc	a0,0x5
    80003bb0:	a2c50513          	addi	a0,a0,-1492 # 800085d8 <syscalls+0x190>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	98a080e7          	jalr	-1654(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bbc:	40dc                	lw	a5,4(s1)
    80003bbe:	0047d79b          	srliw	a5,a5,0x4
    80003bc2:	0001c597          	auipc	a1,0x1c
    80003bc6:	5465a583          	lw	a1,1350(a1) # 80020108 <sb+0x18>
    80003bca:	9dbd                	addw	a1,a1,a5
    80003bcc:	4088                	lw	a0,0(s1)
    80003bce:	fffff097          	auipc	ra,0xfffff
    80003bd2:	7ac080e7          	jalr	1964(ra) # 8000337a <bread>
    80003bd6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bd8:	05850593          	addi	a1,a0,88
    80003bdc:	40dc                	lw	a5,4(s1)
    80003bde:	8bbd                	andi	a5,a5,15
    80003be0:	079a                	slli	a5,a5,0x6
    80003be2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003be4:	00059783          	lh	a5,0(a1)
    80003be8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bec:	00259783          	lh	a5,2(a1)
    80003bf0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bf4:	00459783          	lh	a5,4(a1)
    80003bf8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003bfc:	00659783          	lh	a5,6(a1)
    80003c00:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c04:	459c                	lw	a5,8(a1)
    80003c06:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c08:	03400613          	li	a2,52
    80003c0c:	05b1                	addi	a1,a1,12
    80003c0e:	05048513          	addi	a0,s1,80
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	12e080e7          	jalr	302(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c1a:	854a                	mv	a0,s2
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	88e080e7          	jalr	-1906(ra) # 800034aa <brelse>
    ip->valid = 1;
    80003c24:	4785                	li	a5,1
    80003c26:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c28:	04449783          	lh	a5,68(s1)
    80003c2c:	fbb5                	bnez	a5,80003ba0 <ilock+0x24>
      panic("ilock: no type");
    80003c2e:	00005517          	auipc	a0,0x5
    80003c32:	9b250513          	addi	a0,a0,-1614 # 800085e0 <syscalls+0x198>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	908080e7          	jalr	-1784(ra) # 8000053e <panic>

0000000080003c3e <iunlock>:
{
    80003c3e:	1101                	addi	sp,sp,-32
    80003c40:	ec06                	sd	ra,24(sp)
    80003c42:	e822                	sd	s0,16(sp)
    80003c44:	e426                	sd	s1,8(sp)
    80003c46:	e04a                	sd	s2,0(sp)
    80003c48:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c4a:	c905                	beqz	a0,80003c7a <iunlock+0x3c>
    80003c4c:	84aa                	mv	s1,a0
    80003c4e:	01050913          	addi	s2,a0,16
    80003c52:	854a                	mv	a0,s2
    80003c54:	00001097          	auipc	ra,0x1
    80003c58:	c8c080e7          	jalr	-884(ra) # 800048e0 <holdingsleep>
    80003c5c:	cd19                	beqz	a0,80003c7a <iunlock+0x3c>
    80003c5e:	449c                	lw	a5,8(s1)
    80003c60:	00f05d63          	blez	a5,80003c7a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c64:	854a                	mv	a0,s2
    80003c66:	00001097          	auipc	ra,0x1
    80003c6a:	c36080e7          	jalr	-970(ra) # 8000489c <releasesleep>
}
    80003c6e:	60e2                	ld	ra,24(sp)
    80003c70:	6442                	ld	s0,16(sp)
    80003c72:	64a2                	ld	s1,8(sp)
    80003c74:	6902                	ld	s2,0(sp)
    80003c76:	6105                	addi	sp,sp,32
    80003c78:	8082                	ret
    panic("iunlock");
    80003c7a:	00005517          	auipc	a0,0x5
    80003c7e:	97650513          	addi	a0,a0,-1674 # 800085f0 <syscalls+0x1a8>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080003c8a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c8a:	7179                	addi	sp,sp,-48
    80003c8c:	f406                	sd	ra,40(sp)
    80003c8e:	f022                	sd	s0,32(sp)
    80003c90:	ec26                	sd	s1,24(sp)
    80003c92:	e84a                	sd	s2,16(sp)
    80003c94:	e44e                	sd	s3,8(sp)
    80003c96:	e052                	sd	s4,0(sp)
    80003c98:	1800                	addi	s0,sp,48
    80003c9a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c9c:	05050493          	addi	s1,a0,80
    80003ca0:	08050913          	addi	s2,a0,128
    80003ca4:	a021                	j	80003cac <itrunc+0x22>
    80003ca6:	0491                	addi	s1,s1,4
    80003ca8:	01248d63          	beq	s1,s2,80003cc2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cac:	408c                	lw	a1,0(s1)
    80003cae:	dde5                	beqz	a1,80003ca6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cb0:	0009a503          	lw	a0,0(s3)
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	90c080e7          	jalr	-1780(ra) # 800035c0 <bfree>
      ip->addrs[i] = 0;
    80003cbc:	0004a023          	sw	zero,0(s1)
    80003cc0:	b7dd                	j	80003ca6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cc2:	0809a583          	lw	a1,128(s3)
    80003cc6:	e185                	bnez	a1,80003ce6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cc8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ccc:	854e                	mv	a0,s3
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	de4080e7          	jalr	-540(ra) # 80003ab2 <iupdate>
}
    80003cd6:	70a2                	ld	ra,40(sp)
    80003cd8:	7402                	ld	s0,32(sp)
    80003cda:	64e2                	ld	s1,24(sp)
    80003cdc:	6942                	ld	s2,16(sp)
    80003cde:	69a2                	ld	s3,8(sp)
    80003ce0:	6a02                	ld	s4,0(sp)
    80003ce2:	6145                	addi	sp,sp,48
    80003ce4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ce6:	0009a503          	lw	a0,0(s3)
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	690080e7          	jalr	1680(ra) # 8000337a <bread>
    80003cf2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cf4:	05850493          	addi	s1,a0,88
    80003cf8:	45850913          	addi	s2,a0,1112
    80003cfc:	a811                	j	80003d10 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003cfe:	0009a503          	lw	a0,0(s3)
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	8be080e7          	jalr	-1858(ra) # 800035c0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d0a:	0491                	addi	s1,s1,4
    80003d0c:	01248563          	beq	s1,s2,80003d16 <itrunc+0x8c>
      if(a[j])
    80003d10:	408c                	lw	a1,0(s1)
    80003d12:	dde5                	beqz	a1,80003d0a <itrunc+0x80>
    80003d14:	b7ed                	j	80003cfe <itrunc+0x74>
    brelse(bp);
    80003d16:	8552                	mv	a0,s4
    80003d18:	fffff097          	auipc	ra,0xfffff
    80003d1c:	792080e7          	jalr	1938(ra) # 800034aa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d20:	0809a583          	lw	a1,128(s3)
    80003d24:	0009a503          	lw	a0,0(s3)
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	898080e7          	jalr	-1896(ra) # 800035c0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d30:	0809a023          	sw	zero,128(s3)
    80003d34:	bf51                	j	80003cc8 <itrunc+0x3e>

0000000080003d36 <iput>:
{
    80003d36:	1101                	addi	sp,sp,-32
    80003d38:	ec06                	sd	ra,24(sp)
    80003d3a:	e822                	sd	s0,16(sp)
    80003d3c:	e426                	sd	s1,8(sp)
    80003d3e:	e04a                	sd	s2,0(sp)
    80003d40:	1000                	addi	s0,sp,32
    80003d42:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d44:	0001c517          	auipc	a0,0x1c
    80003d48:	3cc50513          	addi	a0,a0,972 # 80020110 <itable>
    80003d4c:	ffffd097          	auipc	ra,0xffffd
    80003d50:	e98080e7          	jalr	-360(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d54:	4498                	lw	a4,8(s1)
    80003d56:	4785                	li	a5,1
    80003d58:	02f70363          	beq	a4,a5,80003d7e <iput+0x48>
  ip->ref--;
    80003d5c:	449c                	lw	a5,8(s1)
    80003d5e:	37fd                	addiw	a5,a5,-1
    80003d60:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d62:	0001c517          	auipc	a0,0x1c
    80003d66:	3ae50513          	addi	a0,a0,942 # 80020110 <itable>
    80003d6a:	ffffd097          	auipc	ra,0xffffd
    80003d6e:	f2e080e7          	jalr	-210(ra) # 80000c98 <release>
}
    80003d72:	60e2                	ld	ra,24(sp)
    80003d74:	6442                	ld	s0,16(sp)
    80003d76:	64a2                	ld	s1,8(sp)
    80003d78:	6902                	ld	s2,0(sp)
    80003d7a:	6105                	addi	sp,sp,32
    80003d7c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d7e:	40bc                	lw	a5,64(s1)
    80003d80:	dff1                	beqz	a5,80003d5c <iput+0x26>
    80003d82:	04a49783          	lh	a5,74(s1)
    80003d86:	fbf9                	bnez	a5,80003d5c <iput+0x26>
    acquiresleep(&ip->lock);
    80003d88:	01048913          	addi	s2,s1,16
    80003d8c:	854a                	mv	a0,s2
    80003d8e:	00001097          	auipc	ra,0x1
    80003d92:	ab8080e7          	jalr	-1352(ra) # 80004846 <acquiresleep>
    release(&itable.lock);
    80003d96:	0001c517          	auipc	a0,0x1c
    80003d9a:	37a50513          	addi	a0,a0,890 # 80020110 <itable>
    80003d9e:	ffffd097          	auipc	ra,0xffffd
    80003da2:	efa080e7          	jalr	-262(ra) # 80000c98 <release>
    itrunc(ip);
    80003da6:	8526                	mv	a0,s1
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	ee2080e7          	jalr	-286(ra) # 80003c8a <itrunc>
    ip->type = 0;
    80003db0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003db4:	8526                	mv	a0,s1
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	cfc080e7          	jalr	-772(ra) # 80003ab2 <iupdate>
    ip->valid = 0;
    80003dbe:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dc2:	854a                	mv	a0,s2
    80003dc4:	00001097          	auipc	ra,0x1
    80003dc8:	ad8080e7          	jalr	-1320(ra) # 8000489c <releasesleep>
    acquire(&itable.lock);
    80003dcc:	0001c517          	auipc	a0,0x1c
    80003dd0:	34450513          	addi	a0,a0,836 # 80020110 <itable>
    80003dd4:	ffffd097          	auipc	ra,0xffffd
    80003dd8:	e10080e7          	jalr	-496(ra) # 80000be4 <acquire>
    80003ddc:	b741                	j	80003d5c <iput+0x26>

0000000080003dde <iunlockput>:
{
    80003dde:	1101                	addi	sp,sp,-32
    80003de0:	ec06                	sd	ra,24(sp)
    80003de2:	e822                	sd	s0,16(sp)
    80003de4:	e426                	sd	s1,8(sp)
    80003de6:	1000                	addi	s0,sp,32
    80003de8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	e54080e7          	jalr	-428(ra) # 80003c3e <iunlock>
  iput(ip);
    80003df2:	8526                	mv	a0,s1
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	f42080e7          	jalr	-190(ra) # 80003d36 <iput>
}
    80003dfc:	60e2                	ld	ra,24(sp)
    80003dfe:	6442                	ld	s0,16(sp)
    80003e00:	64a2                	ld	s1,8(sp)
    80003e02:	6105                	addi	sp,sp,32
    80003e04:	8082                	ret

0000000080003e06 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e06:	1141                	addi	sp,sp,-16
    80003e08:	e422                	sd	s0,8(sp)
    80003e0a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e0c:	411c                	lw	a5,0(a0)
    80003e0e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e10:	415c                	lw	a5,4(a0)
    80003e12:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e14:	04451783          	lh	a5,68(a0)
    80003e18:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e1c:	04a51783          	lh	a5,74(a0)
    80003e20:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e24:	04c56783          	lwu	a5,76(a0)
    80003e28:	e99c                	sd	a5,16(a1)
}
    80003e2a:	6422                	ld	s0,8(sp)
    80003e2c:	0141                	addi	sp,sp,16
    80003e2e:	8082                	ret

0000000080003e30 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e30:	457c                	lw	a5,76(a0)
    80003e32:	0ed7e963          	bltu	a5,a3,80003f24 <readi+0xf4>
{
    80003e36:	7159                	addi	sp,sp,-112
    80003e38:	f486                	sd	ra,104(sp)
    80003e3a:	f0a2                	sd	s0,96(sp)
    80003e3c:	eca6                	sd	s1,88(sp)
    80003e3e:	e8ca                	sd	s2,80(sp)
    80003e40:	e4ce                	sd	s3,72(sp)
    80003e42:	e0d2                	sd	s4,64(sp)
    80003e44:	fc56                	sd	s5,56(sp)
    80003e46:	f85a                	sd	s6,48(sp)
    80003e48:	f45e                	sd	s7,40(sp)
    80003e4a:	f062                	sd	s8,32(sp)
    80003e4c:	ec66                	sd	s9,24(sp)
    80003e4e:	e86a                	sd	s10,16(sp)
    80003e50:	e46e                	sd	s11,8(sp)
    80003e52:	1880                	addi	s0,sp,112
    80003e54:	8baa                	mv	s7,a0
    80003e56:	8c2e                	mv	s8,a1
    80003e58:	8ab2                	mv	s5,a2
    80003e5a:	84b6                	mv	s1,a3
    80003e5c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e5e:	9f35                	addw	a4,a4,a3
    return 0;
    80003e60:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e62:	0ad76063          	bltu	a4,a3,80003f02 <readi+0xd2>
  if(off + n > ip->size)
    80003e66:	00e7f463          	bgeu	a5,a4,80003e6e <readi+0x3e>
    n = ip->size - off;
    80003e6a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e6e:	0a0b0963          	beqz	s6,80003f20 <readi+0xf0>
    80003e72:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e74:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e78:	5cfd                	li	s9,-1
    80003e7a:	a82d                	j	80003eb4 <readi+0x84>
    80003e7c:	020a1d93          	slli	s11,s4,0x20
    80003e80:	020ddd93          	srli	s11,s11,0x20
    80003e84:	05890613          	addi	a2,s2,88
    80003e88:	86ee                	mv	a3,s11
    80003e8a:	963a                	add	a2,a2,a4
    80003e8c:	85d6                	mv	a1,s5
    80003e8e:	8562                	mv	a0,s8
    80003e90:	ffffe097          	auipc	ra,0xffffe
    80003e94:	df8080e7          	jalr	-520(ra) # 80001c88 <either_copyout>
    80003e98:	05950d63          	beq	a0,s9,80003ef2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e9c:	854a                	mv	a0,s2
    80003e9e:	fffff097          	auipc	ra,0xfffff
    80003ea2:	60c080e7          	jalr	1548(ra) # 800034aa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ea6:	013a09bb          	addw	s3,s4,s3
    80003eaa:	009a04bb          	addw	s1,s4,s1
    80003eae:	9aee                	add	s5,s5,s11
    80003eb0:	0569f763          	bgeu	s3,s6,80003efe <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003eb4:	000ba903          	lw	s2,0(s7)
    80003eb8:	00a4d59b          	srliw	a1,s1,0xa
    80003ebc:	855e                	mv	a0,s7
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	8b0080e7          	jalr	-1872(ra) # 8000376e <bmap>
    80003ec6:	0005059b          	sext.w	a1,a0
    80003eca:	854a                	mv	a0,s2
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	4ae080e7          	jalr	1198(ra) # 8000337a <bread>
    80003ed4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ed6:	3ff4f713          	andi	a4,s1,1023
    80003eda:	40ed07bb          	subw	a5,s10,a4
    80003ede:	413b06bb          	subw	a3,s6,s3
    80003ee2:	8a3e                	mv	s4,a5
    80003ee4:	2781                	sext.w	a5,a5
    80003ee6:	0006861b          	sext.w	a2,a3
    80003eea:	f8f679e3          	bgeu	a2,a5,80003e7c <readi+0x4c>
    80003eee:	8a36                	mv	s4,a3
    80003ef0:	b771                	j	80003e7c <readi+0x4c>
      brelse(bp);
    80003ef2:	854a                	mv	a0,s2
    80003ef4:	fffff097          	auipc	ra,0xfffff
    80003ef8:	5b6080e7          	jalr	1462(ra) # 800034aa <brelse>
      tot = -1;
    80003efc:	59fd                	li	s3,-1
  }
  return tot;
    80003efe:	0009851b          	sext.w	a0,s3
}
    80003f02:	70a6                	ld	ra,104(sp)
    80003f04:	7406                	ld	s0,96(sp)
    80003f06:	64e6                	ld	s1,88(sp)
    80003f08:	6946                	ld	s2,80(sp)
    80003f0a:	69a6                	ld	s3,72(sp)
    80003f0c:	6a06                	ld	s4,64(sp)
    80003f0e:	7ae2                	ld	s5,56(sp)
    80003f10:	7b42                	ld	s6,48(sp)
    80003f12:	7ba2                	ld	s7,40(sp)
    80003f14:	7c02                	ld	s8,32(sp)
    80003f16:	6ce2                	ld	s9,24(sp)
    80003f18:	6d42                	ld	s10,16(sp)
    80003f1a:	6da2                	ld	s11,8(sp)
    80003f1c:	6165                	addi	sp,sp,112
    80003f1e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f20:	89da                	mv	s3,s6
    80003f22:	bff1                	j	80003efe <readi+0xce>
    return 0;
    80003f24:	4501                	li	a0,0
}
    80003f26:	8082                	ret

0000000080003f28 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f28:	457c                	lw	a5,76(a0)
    80003f2a:	10d7e863          	bltu	a5,a3,8000403a <writei+0x112>
{
    80003f2e:	7159                	addi	sp,sp,-112
    80003f30:	f486                	sd	ra,104(sp)
    80003f32:	f0a2                	sd	s0,96(sp)
    80003f34:	eca6                	sd	s1,88(sp)
    80003f36:	e8ca                	sd	s2,80(sp)
    80003f38:	e4ce                	sd	s3,72(sp)
    80003f3a:	e0d2                	sd	s4,64(sp)
    80003f3c:	fc56                	sd	s5,56(sp)
    80003f3e:	f85a                	sd	s6,48(sp)
    80003f40:	f45e                	sd	s7,40(sp)
    80003f42:	f062                	sd	s8,32(sp)
    80003f44:	ec66                	sd	s9,24(sp)
    80003f46:	e86a                	sd	s10,16(sp)
    80003f48:	e46e                	sd	s11,8(sp)
    80003f4a:	1880                	addi	s0,sp,112
    80003f4c:	8b2a                	mv	s6,a0
    80003f4e:	8c2e                	mv	s8,a1
    80003f50:	8ab2                	mv	s5,a2
    80003f52:	8936                	mv	s2,a3
    80003f54:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f56:	00e687bb          	addw	a5,a3,a4
    80003f5a:	0ed7e263          	bltu	a5,a3,8000403e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f5e:	00043737          	lui	a4,0x43
    80003f62:	0ef76063          	bltu	a4,a5,80004042 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f66:	0c0b8863          	beqz	s7,80004036 <writei+0x10e>
    80003f6a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f6c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f70:	5cfd                	li	s9,-1
    80003f72:	a091                	j	80003fb6 <writei+0x8e>
    80003f74:	02099d93          	slli	s11,s3,0x20
    80003f78:	020ddd93          	srli	s11,s11,0x20
    80003f7c:	05848513          	addi	a0,s1,88
    80003f80:	86ee                	mv	a3,s11
    80003f82:	8656                	mv	a2,s5
    80003f84:	85e2                	mv	a1,s8
    80003f86:	953a                	add	a0,a0,a4
    80003f88:	ffffe097          	auipc	ra,0xffffe
    80003f8c:	d56080e7          	jalr	-682(ra) # 80001cde <either_copyin>
    80003f90:	07950263          	beq	a0,s9,80003ff4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f94:	8526                	mv	a0,s1
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	790080e7          	jalr	1936(ra) # 80004726 <log_write>
    brelse(bp);
    80003f9e:	8526                	mv	a0,s1
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	50a080e7          	jalr	1290(ra) # 800034aa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fa8:	01498a3b          	addw	s4,s3,s4
    80003fac:	0129893b          	addw	s2,s3,s2
    80003fb0:	9aee                	add	s5,s5,s11
    80003fb2:	057a7663          	bgeu	s4,s7,80003ffe <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fb6:	000b2483          	lw	s1,0(s6)
    80003fba:	00a9559b          	srliw	a1,s2,0xa
    80003fbe:	855a                	mv	a0,s6
    80003fc0:	fffff097          	auipc	ra,0xfffff
    80003fc4:	7ae080e7          	jalr	1966(ra) # 8000376e <bmap>
    80003fc8:	0005059b          	sext.w	a1,a0
    80003fcc:	8526                	mv	a0,s1
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	3ac080e7          	jalr	940(ra) # 8000337a <bread>
    80003fd6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fd8:	3ff97713          	andi	a4,s2,1023
    80003fdc:	40ed07bb          	subw	a5,s10,a4
    80003fe0:	414b86bb          	subw	a3,s7,s4
    80003fe4:	89be                	mv	s3,a5
    80003fe6:	2781                	sext.w	a5,a5
    80003fe8:	0006861b          	sext.w	a2,a3
    80003fec:	f8f674e3          	bgeu	a2,a5,80003f74 <writei+0x4c>
    80003ff0:	89b6                	mv	s3,a3
    80003ff2:	b749                	j	80003f74 <writei+0x4c>
      brelse(bp);
    80003ff4:	8526                	mv	a0,s1
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	4b4080e7          	jalr	1204(ra) # 800034aa <brelse>
  }

  if(off > ip->size)
    80003ffe:	04cb2783          	lw	a5,76(s6)
    80004002:	0127f463          	bgeu	a5,s2,8000400a <writei+0xe2>
    ip->size = off;
    80004006:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000400a:	855a                	mv	a0,s6
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	aa6080e7          	jalr	-1370(ra) # 80003ab2 <iupdate>

  return tot;
    80004014:	000a051b          	sext.w	a0,s4
}
    80004018:	70a6                	ld	ra,104(sp)
    8000401a:	7406                	ld	s0,96(sp)
    8000401c:	64e6                	ld	s1,88(sp)
    8000401e:	6946                	ld	s2,80(sp)
    80004020:	69a6                	ld	s3,72(sp)
    80004022:	6a06                	ld	s4,64(sp)
    80004024:	7ae2                	ld	s5,56(sp)
    80004026:	7b42                	ld	s6,48(sp)
    80004028:	7ba2                	ld	s7,40(sp)
    8000402a:	7c02                	ld	s8,32(sp)
    8000402c:	6ce2                	ld	s9,24(sp)
    8000402e:	6d42                	ld	s10,16(sp)
    80004030:	6da2                	ld	s11,8(sp)
    80004032:	6165                	addi	sp,sp,112
    80004034:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004036:	8a5e                	mv	s4,s7
    80004038:	bfc9                	j	8000400a <writei+0xe2>
    return -1;
    8000403a:	557d                	li	a0,-1
}
    8000403c:	8082                	ret
    return -1;
    8000403e:	557d                	li	a0,-1
    80004040:	bfe1                	j	80004018 <writei+0xf0>
    return -1;
    80004042:	557d                	li	a0,-1
    80004044:	bfd1                	j	80004018 <writei+0xf0>

0000000080004046 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004046:	1141                	addi	sp,sp,-16
    80004048:	e406                	sd	ra,8(sp)
    8000404a:	e022                	sd	s0,0(sp)
    8000404c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000404e:	4639                	li	a2,14
    80004050:	ffffd097          	auipc	ra,0xffffd
    80004054:	d68080e7          	jalr	-664(ra) # 80000db8 <strncmp>
}
    80004058:	60a2                	ld	ra,8(sp)
    8000405a:	6402                	ld	s0,0(sp)
    8000405c:	0141                	addi	sp,sp,16
    8000405e:	8082                	ret

0000000080004060 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004060:	7139                	addi	sp,sp,-64
    80004062:	fc06                	sd	ra,56(sp)
    80004064:	f822                	sd	s0,48(sp)
    80004066:	f426                	sd	s1,40(sp)
    80004068:	f04a                	sd	s2,32(sp)
    8000406a:	ec4e                	sd	s3,24(sp)
    8000406c:	e852                	sd	s4,16(sp)
    8000406e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004070:	04451703          	lh	a4,68(a0)
    80004074:	4785                	li	a5,1
    80004076:	00f71a63          	bne	a4,a5,8000408a <dirlookup+0x2a>
    8000407a:	892a                	mv	s2,a0
    8000407c:	89ae                	mv	s3,a1
    8000407e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004080:	457c                	lw	a5,76(a0)
    80004082:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004084:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004086:	e79d                	bnez	a5,800040b4 <dirlookup+0x54>
    80004088:	a8a5                	j	80004100 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000408a:	00004517          	auipc	a0,0x4
    8000408e:	56e50513          	addi	a0,a0,1390 # 800085f8 <syscalls+0x1b0>
    80004092:	ffffc097          	auipc	ra,0xffffc
    80004096:	4ac080e7          	jalr	1196(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000409a:	00004517          	auipc	a0,0x4
    8000409e:	57650513          	addi	a0,a0,1398 # 80008610 <syscalls+0x1c8>
    800040a2:	ffffc097          	auipc	ra,0xffffc
    800040a6:	49c080e7          	jalr	1180(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040aa:	24c1                	addiw	s1,s1,16
    800040ac:	04c92783          	lw	a5,76(s2)
    800040b0:	04f4f763          	bgeu	s1,a5,800040fe <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040b4:	4741                	li	a4,16
    800040b6:	86a6                	mv	a3,s1
    800040b8:	fc040613          	addi	a2,s0,-64
    800040bc:	4581                	li	a1,0
    800040be:	854a                	mv	a0,s2
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	d70080e7          	jalr	-656(ra) # 80003e30 <readi>
    800040c8:	47c1                	li	a5,16
    800040ca:	fcf518e3          	bne	a0,a5,8000409a <dirlookup+0x3a>
    if(de.inum == 0)
    800040ce:	fc045783          	lhu	a5,-64(s0)
    800040d2:	dfe1                	beqz	a5,800040aa <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040d4:	fc240593          	addi	a1,s0,-62
    800040d8:	854e                	mv	a0,s3
    800040da:	00000097          	auipc	ra,0x0
    800040de:	f6c080e7          	jalr	-148(ra) # 80004046 <namecmp>
    800040e2:	f561                	bnez	a0,800040aa <dirlookup+0x4a>
      if(poff)
    800040e4:	000a0463          	beqz	s4,800040ec <dirlookup+0x8c>
        *poff = off;
    800040e8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040ec:	fc045583          	lhu	a1,-64(s0)
    800040f0:	00092503          	lw	a0,0(s2)
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	754080e7          	jalr	1876(ra) # 80003848 <iget>
    800040fc:	a011                	j	80004100 <dirlookup+0xa0>
  return 0;
    800040fe:	4501                	li	a0,0
}
    80004100:	70e2                	ld	ra,56(sp)
    80004102:	7442                	ld	s0,48(sp)
    80004104:	74a2                	ld	s1,40(sp)
    80004106:	7902                	ld	s2,32(sp)
    80004108:	69e2                	ld	s3,24(sp)
    8000410a:	6a42                	ld	s4,16(sp)
    8000410c:	6121                	addi	sp,sp,64
    8000410e:	8082                	ret

0000000080004110 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004110:	711d                	addi	sp,sp,-96
    80004112:	ec86                	sd	ra,88(sp)
    80004114:	e8a2                	sd	s0,80(sp)
    80004116:	e4a6                	sd	s1,72(sp)
    80004118:	e0ca                	sd	s2,64(sp)
    8000411a:	fc4e                	sd	s3,56(sp)
    8000411c:	f852                	sd	s4,48(sp)
    8000411e:	f456                	sd	s5,40(sp)
    80004120:	f05a                	sd	s6,32(sp)
    80004122:	ec5e                	sd	s7,24(sp)
    80004124:	e862                	sd	s8,16(sp)
    80004126:	e466                	sd	s9,8(sp)
    80004128:	1080                	addi	s0,sp,96
    8000412a:	84aa                	mv	s1,a0
    8000412c:	8b2e                	mv	s6,a1
    8000412e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004130:	00054703          	lbu	a4,0(a0)
    80004134:	02f00793          	li	a5,47
    80004138:	02f70363          	beq	a4,a5,8000415e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000413c:	ffffd097          	auipc	ra,0xffffd
    80004140:	7cc080e7          	jalr	1996(ra) # 80001908 <myproc>
    80004144:	17053503          	ld	a0,368(a0)
    80004148:	00000097          	auipc	ra,0x0
    8000414c:	9f6080e7          	jalr	-1546(ra) # 80003b3e <idup>
    80004150:	89aa                	mv	s3,a0
  while(*path == '/')
    80004152:	02f00913          	li	s2,47
  len = path - s;
    80004156:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004158:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000415a:	4c05                	li	s8,1
    8000415c:	a865                	j	80004214 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000415e:	4585                	li	a1,1
    80004160:	4505                	li	a0,1
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	6e6080e7          	jalr	1766(ra) # 80003848 <iget>
    8000416a:	89aa                	mv	s3,a0
    8000416c:	b7dd                	j	80004152 <namex+0x42>
      iunlockput(ip);
    8000416e:	854e                	mv	a0,s3
    80004170:	00000097          	auipc	ra,0x0
    80004174:	c6e080e7          	jalr	-914(ra) # 80003dde <iunlockput>
      return 0;
    80004178:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000417a:	854e                	mv	a0,s3
    8000417c:	60e6                	ld	ra,88(sp)
    8000417e:	6446                	ld	s0,80(sp)
    80004180:	64a6                	ld	s1,72(sp)
    80004182:	6906                	ld	s2,64(sp)
    80004184:	79e2                	ld	s3,56(sp)
    80004186:	7a42                	ld	s4,48(sp)
    80004188:	7aa2                	ld	s5,40(sp)
    8000418a:	7b02                	ld	s6,32(sp)
    8000418c:	6be2                	ld	s7,24(sp)
    8000418e:	6c42                	ld	s8,16(sp)
    80004190:	6ca2                	ld	s9,8(sp)
    80004192:	6125                	addi	sp,sp,96
    80004194:	8082                	ret
      iunlock(ip);
    80004196:	854e                	mv	a0,s3
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	aa6080e7          	jalr	-1370(ra) # 80003c3e <iunlock>
      return ip;
    800041a0:	bfe9                	j	8000417a <namex+0x6a>
      iunlockput(ip);
    800041a2:	854e                	mv	a0,s3
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	c3a080e7          	jalr	-966(ra) # 80003dde <iunlockput>
      return 0;
    800041ac:	89d2                	mv	s3,s4
    800041ae:	b7f1                	j	8000417a <namex+0x6a>
  len = path - s;
    800041b0:	40b48633          	sub	a2,s1,a1
    800041b4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041b8:	094cd463          	bge	s9,s4,80004240 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041bc:	4639                	li	a2,14
    800041be:	8556                	mv	a0,s5
    800041c0:	ffffd097          	auipc	ra,0xffffd
    800041c4:	b80080e7          	jalr	-1152(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041c8:	0004c783          	lbu	a5,0(s1)
    800041cc:	01279763          	bne	a5,s2,800041da <namex+0xca>
    path++;
    800041d0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041d2:	0004c783          	lbu	a5,0(s1)
    800041d6:	ff278de3          	beq	a5,s2,800041d0 <namex+0xc0>
    ilock(ip);
    800041da:	854e                	mv	a0,s3
    800041dc:	00000097          	auipc	ra,0x0
    800041e0:	9a0080e7          	jalr	-1632(ra) # 80003b7c <ilock>
    if(ip->type != T_DIR){
    800041e4:	04499783          	lh	a5,68(s3)
    800041e8:	f98793e3          	bne	a5,s8,8000416e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041ec:	000b0563          	beqz	s6,800041f6 <namex+0xe6>
    800041f0:	0004c783          	lbu	a5,0(s1)
    800041f4:	d3cd                	beqz	a5,80004196 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041f6:	865e                	mv	a2,s7
    800041f8:	85d6                	mv	a1,s5
    800041fa:	854e                	mv	a0,s3
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	e64080e7          	jalr	-412(ra) # 80004060 <dirlookup>
    80004204:	8a2a                	mv	s4,a0
    80004206:	dd51                	beqz	a0,800041a2 <namex+0x92>
    iunlockput(ip);
    80004208:	854e                	mv	a0,s3
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	bd4080e7          	jalr	-1068(ra) # 80003dde <iunlockput>
    ip = next;
    80004212:	89d2                	mv	s3,s4
  while(*path == '/')
    80004214:	0004c783          	lbu	a5,0(s1)
    80004218:	05279763          	bne	a5,s2,80004266 <namex+0x156>
    path++;
    8000421c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000421e:	0004c783          	lbu	a5,0(s1)
    80004222:	ff278de3          	beq	a5,s2,8000421c <namex+0x10c>
  if(*path == 0)
    80004226:	c79d                	beqz	a5,80004254 <namex+0x144>
    path++;
    80004228:	85a6                	mv	a1,s1
  len = path - s;
    8000422a:	8a5e                	mv	s4,s7
    8000422c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000422e:	01278963          	beq	a5,s2,80004240 <namex+0x130>
    80004232:	dfbd                	beqz	a5,800041b0 <namex+0xa0>
    path++;
    80004234:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004236:	0004c783          	lbu	a5,0(s1)
    8000423a:	ff279ce3          	bne	a5,s2,80004232 <namex+0x122>
    8000423e:	bf8d                	j	800041b0 <namex+0xa0>
    memmove(name, s, len);
    80004240:	2601                	sext.w	a2,a2
    80004242:	8556                	mv	a0,s5
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	afc080e7          	jalr	-1284(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000424c:	9a56                	add	s4,s4,s5
    8000424e:	000a0023          	sb	zero,0(s4)
    80004252:	bf9d                	j	800041c8 <namex+0xb8>
  if(nameiparent){
    80004254:	f20b03e3          	beqz	s6,8000417a <namex+0x6a>
    iput(ip);
    80004258:	854e                	mv	a0,s3
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	adc080e7          	jalr	-1316(ra) # 80003d36 <iput>
    return 0;
    80004262:	4981                	li	s3,0
    80004264:	bf19                	j	8000417a <namex+0x6a>
  if(*path == 0)
    80004266:	d7fd                	beqz	a5,80004254 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004268:	0004c783          	lbu	a5,0(s1)
    8000426c:	85a6                	mv	a1,s1
    8000426e:	b7d1                	j	80004232 <namex+0x122>

0000000080004270 <dirlink>:
{
    80004270:	7139                	addi	sp,sp,-64
    80004272:	fc06                	sd	ra,56(sp)
    80004274:	f822                	sd	s0,48(sp)
    80004276:	f426                	sd	s1,40(sp)
    80004278:	f04a                	sd	s2,32(sp)
    8000427a:	ec4e                	sd	s3,24(sp)
    8000427c:	e852                	sd	s4,16(sp)
    8000427e:	0080                	addi	s0,sp,64
    80004280:	892a                	mv	s2,a0
    80004282:	8a2e                	mv	s4,a1
    80004284:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004286:	4601                	li	a2,0
    80004288:	00000097          	auipc	ra,0x0
    8000428c:	dd8080e7          	jalr	-552(ra) # 80004060 <dirlookup>
    80004290:	e93d                	bnez	a0,80004306 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004292:	04c92483          	lw	s1,76(s2)
    80004296:	c49d                	beqz	s1,800042c4 <dirlink+0x54>
    80004298:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000429a:	4741                	li	a4,16
    8000429c:	86a6                	mv	a3,s1
    8000429e:	fc040613          	addi	a2,s0,-64
    800042a2:	4581                	li	a1,0
    800042a4:	854a                	mv	a0,s2
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	b8a080e7          	jalr	-1142(ra) # 80003e30 <readi>
    800042ae:	47c1                	li	a5,16
    800042b0:	06f51163          	bne	a0,a5,80004312 <dirlink+0xa2>
    if(de.inum == 0)
    800042b4:	fc045783          	lhu	a5,-64(s0)
    800042b8:	c791                	beqz	a5,800042c4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ba:	24c1                	addiw	s1,s1,16
    800042bc:	04c92783          	lw	a5,76(s2)
    800042c0:	fcf4ede3          	bltu	s1,a5,8000429a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042c4:	4639                	li	a2,14
    800042c6:	85d2                	mv	a1,s4
    800042c8:	fc240513          	addi	a0,s0,-62
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	b28080e7          	jalr	-1240(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042d4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042d8:	4741                	li	a4,16
    800042da:	86a6                	mv	a3,s1
    800042dc:	fc040613          	addi	a2,s0,-64
    800042e0:	4581                	li	a1,0
    800042e2:	854a                	mv	a0,s2
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	c44080e7          	jalr	-956(ra) # 80003f28 <writei>
    800042ec:	872a                	mv	a4,a0
    800042ee:	47c1                	li	a5,16
  return 0;
    800042f0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f2:	02f71863          	bne	a4,a5,80004322 <dirlink+0xb2>
}
    800042f6:	70e2                	ld	ra,56(sp)
    800042f8:	7442                	ld	s0,48(sp)
    800042fa:	74a2                	ld	s1,40(sp)
    800042fc:	7902                	ld	s2,32(sp)
    800042fe:	69e2                	ld	s3,24(sp)
    80004300:	6a42                	ld	s4,16(sp)
    80004302:	6121                	addi	sp,sp,64
    80004304:	8082                	ret
    iput(ip);
    80004306:	00000097          	auipc	ra,0x0
    8000430a:	a30080e7          	jalr	-1488(ra) # 80003d36 <iput>
    return -1;
    8000430e:	557d                	li	a0,-1
    80004310:	b7dd                	j	800042f6 <dirlink+0x86>
      panic("dirlink read");
    80004312:	00004517          	auipc	a0,0x4
    80004316:	30e50513          	addi	a0,a0,782 # 80008620 <syscalls+0x1d8>
    8000431a:	ffffc097          	auipc	ra,0xffffc
    8000431e:	224080e7          	jalr	548(ra) # 8000053e <panic>
    panic("dirlink");
    80004322:	00004517          	auipc	a0,0x4
    80004326:	40e50513          	addi	a0,a0,1038 # 80008730 <syscalls+0x2e8>
    8000432a:	ffffc097          	auipc	ra,0xffffc
    8000432e:	214080e7          	jalr	532(ra) # 8000053e <panic>

0000000080004332 <namei>:

struct inode*
namei(char *path)
{
    80004332:	1101                	addi	sp,sp,-32
    80004334:	ec06                	sd	ra,24(sp)
    80004336:	e822                	sd	s0,16(sp)
    80004338:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000433a:	fe040613          	addi	a2,s0,-32
    8000433e:	4581                	li	a1,0
    80004340:	00000097          	auipc	ra,0x0
    80004344:	dd0080e7          	jalr	-560(ra) # 80004110 <namex>
}
    80004348:	60e2                	ld	ra,24(sp)
    8000434a:	6442                	ld	s0,16(sp)
    8000434c:	6105                	addi	sp,sp,32
    8000434e:	8082                	ret

0000000080004350 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004350:	1141                	addi	sp,sp,-16
    80004352:	e406                	sd	ra,8(sp)
    80004354:	e022                	sd	s0,0(sp)
    80004356:	0800                	addi	s0,sp,16
    80004358:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000435a:	4585                	li	a1,1
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	db4080e7          	jalr	-588(ra) # 80004110 <namex>
}
    80004364:	60a2                	ld	ra,8(sp)
    80004366:	6402                	ld	s0,0(sp)
    80004368:	0141                	addi	sp,sp,16
    8000436a:	8082                	ret

000000008000436c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000436c:	1101                	addi	sp,sp,-32
    8000436e:	ec06                	sd	ra,24(sp)
    80004370:	e822                	sd	s0,16(sp)
    80004372:	e426                	sd	s1,8(sp)
    80004374:	e04a                	sd	s2,0(sp)
    80004376:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004378:	0001e917          	auipc	s2,0x1e
    8000437c:	84090913          	addi	s2,s2,-1984 # 80021bb8 <log>
    80004380:	01892583          	lw	a1,24(s2)
    80004384:	02892503          	lw	a0,40(s2)
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	ff2080e7          	jalr	-14(ra) # 8000337a <bread>
    80004390:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004392:	02c92683          	lw	a3,44(s2)
    80004396:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004398:	02d05763          	blez	a3,800043c6 <write_head+0x5a>
    8000439c:	0001e797          	auipc	a5,0x1e
    800043a0:	84c78793          	addi	a5,a5,-1972 # 80021be8 <log+0x30>
    800043a4:	05c50713          	addi	a4,a0,92
    800043a8:	36fd                	addiw	a3,a3,-1
    800043aa:	1682                	slli	a3,a3,0x20
    800043ac:	9281                	srli	a3,a3,0x20
    800043ae:	068a                	slli	a3,a3,0x2
    800043b0:	0001e617          	auipc	a2,0x1e
    800043b4:	83c60613          	addi	a2,a2,-1988 # 80021bec <log+0x34>
    800043b8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043ba:	4390                	lw	a2,0(a5)
    800043bc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043be:	0791                	addi	a5,a5,4
    800043c0:	0711                	addi	a4,a4,4
    800043c2:	fed79ce3          	bne	a5,a3,800043ba <write_head+0x4e>
  }
  bwrite(buf);
    800043c6:	8526                	mv	a0,s1
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	0a4080e7          	jalr	164(ra) # 8000346c <bwrite>
  brelse(buf);
    800043d0:	8526                	mv	a0,s1
    800043d2:	fffff097          	auipc	ra,0xfffff
    800043d6:	0d8080e7          	jalr	216(ra) # 800034aa <brelse>
}
    800043da:	60e2                	ld	ra,24(sp)
    800043dc:	6442                	ld	s0,16(sp)
    800043de:	64a2                	ld	s1,8(sp)
    800043e0:	6902                	ld	s2,0(sp)
    800043e2:	6105                	addi	sp,sp,32
    800043e4:	8082                	ret

00000000800043e6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043e6:	0001d797          	auipc	a5,0x1d
    800043ea:	7fe7a783          	lw	a5,2046(a5) # 80021be4 <log+0x2c>
    800043ee:	0af05d63          	blez	a5,800044a8 <install_trans+0xc2>
{
    800043f2:	7139                	addi	sp,sp,-64
    800043f4:	fc06                	sd	ra,56(sp)
    800043f6:	f822                	sd	s0,48(sp)
    800043f8:	f426                	sd	s1,40(sp)
    800043fa:	f04a                	sd	s2,32(sp)
    800043fc:	ec4e                	sd	s3,24(sp)
    800043fe:	e852                	sd	s4,16(sp)
    80004400:	e456                	sd	s5,8(sp)
    80004402:	e05a                	sd	s6,0(sp)
    80004404:	0080                	addi	s0,sp,64
    80004406:	8b2a                	mv	s6,a0
    80004408:	0001da97          	auipc	s5,0x1d
    8000440c:	7e0a8a93          	addi	s5,s5,2016 # 80021be8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004410:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004412:	0001d997          	auipc	s3,0x1d
    80004416:	7a698993          	addi	s3,s3,1958 # 80021bb8 <log>
    8000441a:	a035                	j	80004446 <install_trans+0x60>
      bunpin(dbuf);
    8000441c:	8526                	mv	a0,s1
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	166080e7          	jalr	358(ra) # 80003584 <bunpin>
    brelse(lbuf);
    80004426:	854a                	mv	a0,s2
    80004428:	fffff097          	auipc	ra,0xfffff
    8000442c:	082080e7          	jalr	130(ra) # 800034aa <brelse>
    brelse(dbuf);
    80004430:	8526                	mv	a0,s1
    80004432:	fffff097          	auipc	ra,0xfffff
    80004436:	078080e7          	jalr	120(ra) # 800034aa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000443a:	2a05                	addiw	s4,s4,1
    8000443c:	0a91                	addi	s5,s5,4
    8000443e:	02c9a783          	lw	a5,44(s3)
    80004442:	04fa5963          	bge	s4,a5,80004494 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004446:	0189a583          	lw	a1,24(s3)
    8000444a:	014585bb          	addw	a1,a1,s4
    8000444e:	2585                	addiw	a1,a1,1
    80004450:	0289a503          	lw	a0,40(s3)
    80004454:	fffff097          	auipc	ra,0xfffff
    80004458:	f26080e7          	jalr	-218(ra) # 8000337a <bread>
    8000445c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000445e:	000aa583          	lw	a1,0(s5)
    80004462:	0289a503          	lw	a0,40(s3)
    80004466:	fffff097          	auipc	ra,0xfffff
    8000446a:	f14080e7          	jalr	-236(ra) # 8000337a <bread>
    8000446e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004470:	40000613          	li	a2,1024
    80004474:	05890593          	addi	a1,s2,88
    80004478:	05850513          	addi	a0,a0,88
    8000447c:	ffffd097          	auipc	ra,0xffffd
    80004480:	8c4080e7          	jalr	-1852(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004484:	8526                	mv	a0,s1
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	fe6080e7          	jalr	-26(ra) # 8000346c <bwrite>
    if(recovering == 0)
    8000448e:	f80b1ce3          	bnez	s6,80004426 <install_trans+0x40>
    80004492:	b769                	j	8000441c <install_trans+0x36>
}
    80004494:	70e2                	ld	ra,56(sp)
    80004496:	7442                	ld	s0,48(sp)
    80004498:	74a2                	ld	s1,40(sp)
    8000449a:	7902                	ld	s2,32(sp)
    8000449c:	69e2                	ld	s3,24(sp)
    8000449e:	6a42                	ld	s4,16(sp)
    800044a0:	6aa2                	ld	s5,8(sp)
    800044a2:	6b02                	ld	s6,0(sp)
    800044a4:	6121                	addi	sp,sp,64
    800044a6:	8082                	ret
    800044a8:	8082                	ret

00000000800044aa <initlog>:
{
    800044aa:	7179                	addi	sp,sp,-48
    800044ac:	f406                	sd	ra,40(sp)
    800044ae:	f022                	sd	s0,32(sp)
    800044b0:	ec26                	sd	s1,24(sp)
    800044b2:	e84a                	sd	s2,16(sp)
    800044b4:	e44e                	sd	s3,8(sp)
    800044b6:	1800                	addi	s0,sp,48
    800044b8:	892a                	mv	s2,a0
    800044ba:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044bc:	0001d497          	auipc	s1,0x1d
    800044c0:	6fc48493          	addi	s1,s1,1788 # 80021bb8 <log>
    800044c4:	00004597          	auipc	a1,0x4
    800044c8:	16c58593          	addi	a1,a1,364 # 80008630 <syscalls+0x1e8>
    800044cc:	8526                	mv	a0,s1
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	686080e7          	jalr	1670(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044d6:	0149a583          	lw	a1,20(s3)
    800044da:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044dc:	0109a783          	lw	a5,16(s3)
    800044e0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044e2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044e6:	854a                	mv	a0,s2
    800044e8:	fffff097          	auipc	ra,0xfffff
    800044ec:	e92080e7          	jalr	-366(ra) # 8000337a <bread>
  log.lh.n = lh->n;
    800044f0:	4d3c                	lw	a5,88(a0)
    800044f2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044f4:	02f05563          	blez	a5,8000451e <initlog+0x74>
    800044f8:	05c50713          	addi	a4,a0,92
    800044fc:	0001d697          	auipc	a3,0x1d
    80004500:	6ec68693          	addi	a3,a3,1772 # 80021be8 <log+0x30>
    80004504:	37fd                	addiw	a5,a5,-1
    80004506:	1782                	slli	a5,a5,0x20
    80004508:	9381                	srli	a5,a5,0x20
    8000450a:	078a                	slli	a5,a5,0x2
    8000450c:	06050613          	addi	a2,a0,96
    80004510:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004512:	4310                	lw	a2,0(a4)
    80004514:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004516:	0711                	addi	a4,a4,4
    80004518:	0691                	addi	a3,a3,4
    8000451a:	fef71ce3          	bne	a4,a5,80004512 <initlog+0x68>
  brelse(buf);
    8000451e:	fffff097          	auipc	ra,0xfffff
    80004522:	f8c080e7          	jalr	-116(ra) # 800034aa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004526:	4505                	li	a0,1
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	ebe080e7          	jalr	-322(ra) # 800043e6 <install_trans>
  log.lh.n = 0;
    80004530:	0001d797          	auipc	a5,0x1d
    80004534:	6a07aa23          	sw	zero,1716(a5) # 80021be4 <log+0x2c>
  write_head(); // clear the log
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	e34080e7          	jalr	-460(ra) # 8000436c <write_head>
}
    80004540:	70a2                	ld	ra,40(sp)
    80004542:	7402                	ld	s0,32(sp)
    80004544:	64e2                	ld	s1,24(sp)
    80004546:	6942                	ld	s2,16(sp)
    80004548:	69a2                	ld	s3,8(sp)
    8000454a:	6145                	addi	sp,sp,48
    8000454c:	8082                	ret

000000008000454e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000454e:	1101                	addi	sp,sp,-32
    80004550:	ec06                	sd	ra,24(sp)
    80004552:	e822                	sd	s0,16(sp)
    80004554:	e426                	sd	s1,8(sp)
    80004556:	e04a                	sd	s2,0(sp)
    80004558:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000455a:	0001d517          	auipc	a0,0x1d
    8000455e:	65e50513          	addi	a0,a0,1630 # 80021bb8 <log>
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	682080e7          	jalr	1666(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000456a:	0001d497          	auipc	s1,0x1d
    8000456e:	64e48493          	addi	s1,s1,1614 # 80021bb8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004572:	4979                	li	s2,30
    80004574:	a039                	j	80004582 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004576:	85a6                	mv	a1,s1
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffe097          	auipc	ra,0xffffe
    8000457e:	b2e080e7          	jalr	-1234(ra) # 800020a8 <sleep>
    if(log.committing){
    80004582:	50dc                	lw	a5,36(s1)
    80004584:	fbed                	bnez	a5,80004576 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004586:	509c                	lw	a5,32(s1)
    80004588:	0017871b          	addiw	a4,a5,1
    8000458c:	0007069b          	sext.w	a3,a4
    80004590:	0027179b          	slliw	a5,a4,0x2
    80004594:	9fb9                	addw	a5,a5,a4
    80004596:	0017979b          	slliw	a5,a5,0x1
    8000459a:	54d8                	lw	a4,44(s1)
    8000459c:	9fb9                	addw	a5,a5,a4
    8000459e:	00f95963          	bge	s2,a5,800045b0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045a2:	85a6                	mv	a1,s1
    800045a4:	8526                	mv	a0,s1
    800045a6:	ffffe097          	auipc	ra,0xffffe
    800045aa:	b02080e7          	jalr	-1278(ra) # 800020a8 <sleep>
    800045ae:	bfd1                	j	80004582 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045b0:	0001d517          	auipc	a0,0x1d
    800045b4:	60850513          	addi	a0,a0,1544 # 80021bb8 <log>
    800045b8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	6de080e7          	jalr	1758(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045c2:	60e2                	ld	ra,24(sp)
    800045c4:	6442                	ld	s0,16(sp)
    800045c6:	64a2                	ld	s1,8(sp)
    800045c8:	6902                	ld	s2,0(sp)
    800045ca:	6105                	addi	sp,sp,32
    800045cc:	8082                	ret

00000000800045ce <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045ce:	7139                	addi	sp,sp,-64
    800045d0:	fc06                	sd	ra,56(sp)
    800045d2:	f822                	sd	s0,48(sp)
    800045d4:	f426                	sd	s1,40(sp)
    800045d6:	f04a                	sd	s2,32(sp)
    800045d8:	ec4e                	sd	s3,24(sp)
    800045da:	e852                	sd	s4,16(sp)
    800045dc:	e456                	sd	s5,8(sp)
    800045de:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045e0:	0001d497          	auipc	s1,0x1d
    800045e4:	5d848493          	addi	s1,s1,1496 # 80021bb8 <log>
    800045e8:	8526                	mv	a0,s1
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	5fa080e7          	jalr	1530(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800045f2:	509c                	lw	a5,32(s1)
    800045f4:	37fd                	addiw	a5,a5,-1
    800045f6:	0007891b          	sext.w	s2,a5
    800045fa:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045fc:	50dc                	lw	a5,36(s1)
    800045fe:	efb9                	bnez	a5,8000465c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004600:	06091663          	bnez	s2,8000466c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004604:	0001d497          	auipc	s1,0x1d
    80004608:	5b448493          	addi	s1,s1,1460 # 80021bb8 <log>
    8000460c:	4785                	li	a5,1
    8000460e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004610:	8526                	mv	a0,s1
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	686080e7          	jalr	1670(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000461a:	54dc                	lw	a5,44(s1)
    8000461c:	06f04763          	bgtz	a5,8000468a <end_op+0xbc>
    acquire(&log.lock);
    80004620:	0001d497          	auipc	s1,0x1d
    80004624:	59848493          	addi	s1,s1,1432 # 80021bb8 <log>
    80004628:	8526                	mv	a0,s1
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	5ba080e7          	jalr	1466(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004632:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004636:	8526                	mv	a0,s1
    80004638:	ffffe097          	auipc	ra,0xffffe
    8000463c:	de2080e7          	jalr	-542(ra) # 8000241a <wakeup>
    release(&log.lock);
    80004640:	8526                	mv	a0,s1
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	656080e7          	jalr	1622(ra) # 80000c98 <release>
}
    8000464a:	70e2                	ld	ra,56(sp)
    8000464c:	7442                	ld	s0,48(sp)
    8000464e:	74a2                	ld	s1,40(sp)
    80004650:	7902                	ld	s2,32(sp)
    80004652:	69e2                	ld	s3,24(sp)
    80004654:	6a42                	ld	s4,16(sp)
    80004656:	6aa2                	ld	s5,8(sp)
    80004658:	6121                	addi	sp,sp,64
    8000465a:	8082                	ret
    panic("log.committing");
    8000465c:	00004517          	auipc	a0,0x4
    80004660:	fdc50513          	addi	a0,a0,-36 # 80008638 <syscalls+0x1f0>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	eda080e7          	jalr	-294(ra) # 8000053e <panic>
    wakeup(&log);
    8000466c:	0001d497          	auipc	s1,0x1d
    80004670:	54c48493          	addi	s1,s1,1356 # 80021bb8 <log>
    80004674:	8526                	mv	a0,s1
    80004676:	ffffe097          	auipc	ra,0xffffe
    8000467a:	da4080e7          	jalr	-604(ra) # 8000241a <wakeup>
  release(&log.lock);
    8000467e:	8526                	mv	a0,s1
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	618080e7          	jalr	1560(ra) # 80000c98 <release>
  if(do_commit){
    80004688:	b7c9                	j	8000464a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000468a:	0001da97          	auipc	s5,0x1d
    8000468e:	55ea8a93          	addi	s5,s5,1374 # 80021be8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004692:	0001da17          	auipc	s4,0x1d
    80004696:	526a0a13          	addi	s4,s4,1318 # 80021bb8 <log>
    8000469a:	018a2583          	lw	a1,24(s4)
    8000469e:	012585bb          	addw	a1,a1,s2
    800046a2:	2585                	addiw	a1,a1,1
    800046a4:	028a2503          	lw	a0,40(s4)
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	cd2080e7          	jalr	-814(ra) # 8000337a <bread>
    800046b0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046b2:	000aa583          	lw	a1,0(s5)
    800046b6:	028a2503          	lw	a0,40(s4)
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	cc0080e7          	jalr	-832(ra) # 8000337a <bread>
    800046c2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046c4:	40000613          	li	a2,1024
    800046c8:	05850593          	addi	a1,a0,88
    800046cc:	05848513          	addi	a0,s1,88
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	670080e7          	jalr	1648(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046d8:	8526                	mv	a0,s1
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	d92080e7          	jalr	-622(ra) # 8000346c <bwrite>
    brelse(from);
    800046e2:	854e                	mv	a0,s3
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	dc6080e7          	jalr	-570(ra) # 800034aa <brelse>
    brelse(to);
    800046ec:	8526                	mv	a0,s1
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	dbc080e7          	jalr	-580(ra) # 800034aa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f6:	2905                	addiw	s2,s2,1
    800046f8:	0a91                	addi	s5,s5,4
    800046fa:	02ca2783          	lw	a5,44(s4)
    800046fe:	f8f94ee3          	blt	s2,a5,8000469a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004702:	00000097          	auipc	ra,0x0
    80004706:	c6a080e7          	jalr	-918(ra) # 8000436c <write_head>
    install_trans(0); // Now install writes to home locations
    8000470a:	4501                	li	a0,0
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	cda080e7          	jalr	-806(ra) # 800043e6 <install_trans>
    log.lh.n = 0;
    80004714:	0001d797          	auipc	a5,0x1d
    80004718:	4c07a823          	sw	zero,1232(a5) # 80021be4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000471c:	00000097          	auipc	ra,0x0
    80004720:	c50080e7          	jalr	-944(ra) # 8000436c <write_head>
    80004724:	bdf5                	j	80004620 <end_op+0x52>

0000000080004726 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004726:	1101                	addi	sp,sp,-32
    80004728:	ec06                	sd	ra,24(sp)
    8000472a:	e822                	sd	s0,16(sp)
    8000472c:	e426                	sd	s1,8(sp)
    8000472e:	e04a                	sd	s2,0(sp)
    80004730:	1000                	addi	s0,sp,32
    80004732:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004734:	0001d917          	auipc	s2,0x1d
    80004738:	48490913          	addi	s2,s2,1156 # 80021bb8 <log>
    8000473c:	854a                	mv	a0,s2
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004746:	02c92603          	lw	a2,44(s2)
    8000474a:	47f5                	li	a5,29
    8000474c:	06c7c563          	blt	a5,a2,800047b6 <log_write+0x90>
    80004750:	0001d797          	auipc	a5,0x1d
    80004754:	4847a783          	lw	a5,1156(a5) # 80021bd4 <log+0x1c>
    80004758:	37fd                	addiw	a5,a5,-1
    8000475a:	04f65e63          	bge	a2,a5,800047b6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000475e:	0001d797          	auipc	a5,0x1d
    80004762:	47a7a783          	lw	a5,1146(a5) # 80021bd8 <log+0x20>
    80004766:	06f05063          	blez	a5,800047c6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000476a:	4781                	li	a5,0
    8000476c:	06c05563          	blez	a2,800047d6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004770:	44cc                	lw	a1,12(s1)
    80004772:	0001d717          	auipc	a4,0x1d
    80004776:	47670713          	addi	a4,a4,1142 # 80021be8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000477a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000477c:	4314                	lw	a3,0(a4)
    8000477e:	04b68c63          	beq	a3,a1,800047d6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004782:	2785                	addiw	a5,a5,1
    80004784:	0711                	addi	a4,a4,4
    80004786:	fef61be3          	bne	a2,a5,8000477c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000478a:	0621                	addi	a2,a2,8
    8000478c:	060a                	slli	a2,a2,0x2
    8000478e:	0001d797          	auipc	a5,0x1d
    80004792:	42a78793          	addi	a5,a5,1066 # 80021bb8 <log>
    80004796:	963e                	add	a2,a2,a5
    80004798:	44dc                	lw	a5,12(s1)
    8000479a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000479c:	8526                	mv	a0,s1
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	daa080e7          	jalr	-598(ra) # 80003548 <bpin>
    log.lh.n++;
    800047a6:	0001d717          	auipc	a4,0x1d
    800047aa:	41270713          	addi	a4,a4,1042 # 80021bb8 <log>
    800047ae:	575c                	lw	a5,44(a4)
    800047b0:	2785                	addiw	a5,a5,1
    800047b2:	d75c                	sw	a5,44(a4)
    800047b4:	a835                	j	800047f0 <log_write+0xca>
    panic("too big a transaction");
    800047b6:	00004517          	auipc	a0,0x4
    800047ba:	e9250513          	addi	a0,a0,-366 # 80008648 <syscalls+0x200>
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	d80080e7          	jalr	-640(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047c6:	00004517          	auipc	a0,0x4
    800047ca:	e9a50513          	addi	a0,a0,-358 # 80008660 <syscalls+0x218>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	d70080e7          	jalr	-656(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047d6:	00878713          	addi	a4,a5,8
    800047da:	00271693          	slli	a3,a4,0x2
    800047de:	0001d717          	auipc	a4,0x1d
    800047e2:	3da70713          	addi	a4,a4,986 # 80021bb8 <log>
    800047e6:	9736                	add	a4,a4,a3
    800047e8:	44d4                	lw	a3,12(s1)
    800047ea:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047ec:	faf608e3          	beq	a2,a5,8000479c <log_write+0x76>
  }
  release(&log.lock);
    800047f0:	0001d517          	auipc	a0,0x1d
    800047f4:	3c850513          	addi	a0,a0,968 # 80021bb8 <log>
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	4a0080e7          	jalr	1184(ra) # 80000c98 <release>
}
    80004800:	60e2                	ld	ra,24(sp)
    80004802:	6442                	ld	s0,16(sp)
    80004804:	64a2                	ld	s1,8(sp)
    80004806:	6902                	ld	s2,0(sp)
    80004808:	6105                	addi	sp,sp,32
    8000480a:	8082                	ret

000000008000480c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000480c:	1101                	addi	sp,sp,-32
    8000480e:	ec06                	sd	ra,24(sp)
    80004810:	e822                	sd	s0,16(sp)
    80004812:	e426                	sd	s1,8(sp)
    80004814:	e04a                	sd	s2,0(sp)
    80004816:	1000                	addi	s0,sp,32
    80004818:	84aa                	mv	s1,a0
    8000481a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000481c:	00004597          	auipc	a1,0x4
    80004820:	e6458593          	addi	a1,a1,-412 # 80008680 <syscalls+0x238>
    80004824:	0521                	addi	a0,a0,8
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	32e080e7          	jalr	814(ra) # 80000b54 <initlock>
  lk->name = name;
    8000482e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004832:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004836:	0204a423          	sw	zero,40(s1)
}
    8000483a:	60e2                	ld	ra,24(sp)
    8000483c:	6442                	ld	s0,16(sp)
    8000483e:	64a2                	ld	s1,8(sp)
    80004840:	6902                	ld	s2,0(sp)
    80004842:	6105                	addi	sp,sp,32
    80004844:	8082                	ret

0000000080004846 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004846:	1101                	addi	sp,sp,-32
    80004848:	ec06                	sd	ra,24(sp)
    8000484a:	e822                	sd	s0,16(sp)
    8000484c:	e426                	sd	s1,8(sp)
    8000484e:	e04a                	sd	s2,0(sp)
    80004850:	1000                	addi	s0,sp,32
    80004852:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004854:	00850913          	addi	s2,a0,8
    80004858:	854a                	mv	a0,s2
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	38a080e7          	jalr	906(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004862:	409c                	lw	a5,0(s1)
    80004864:	cb89                	beqz	a5,80004876 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004866:	85ca                	mv	a1,s2
    80004868:	8526                	mv	a0,s1
    8000486a:	ffffe097          	auipc	ra,0xffffe
    8000486e:	83e080e7          	jalr	-1986(ra) # 800020a8 <sleep>
  while (lk->locked) {
    80004872:	409c                	lw	a5,0(s1)
    80004874:	fbed                	bnez	a5,80004866 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004876:	4785                	li	a5,1
    80004878:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000487a:	ffffd097          	auipc	ra,0xffffd
    8000487e:	08e080e7          	jalr	142(ra) # 80001908 <myproc>
    80004882:	591c                	lw	a5,48(a0)
    80004884:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004886:	854a                	mv	a0,s2
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	410080e7          	jalr	1040(ra) # 80000c98 <release>
}
    80004890:	60e2                	ld	ra,24(sp)
    80004892:	6442                	ld	s0,16(sp)
    80004894:	64a2                	ld	s1,8(sp)
    80004896:	6902                	ld	s2,0(sp)
    80004898:	6105                	addi	sp,sp,32
    8000489a:	8082                	ret

000000008000489c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000489c:	1101                	addi	sp,sp,-32
    8000489e:	ec06                	sd	ra,24(sp)
    800048a0:	e822                	sd	s0,16(sp)
    800048a2:	e426                	sd	s1,8(sp)
    800048a4:	e04a                	sd	s2,0(sp)
    800048a6:	1000                	addi	s0,sp,32
    800048a8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048aa:	00850913          	addi	s2,a0,8
    800048ae:	854a                	mv	a0,s2
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	334080e7          	jalr	820(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048b8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048bc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048c0:	8526                	mv	a0,s1
    800048c2:	ffffe097          	auipc	ra,0xffffe
    800048c6:	b58080e7          	jalr	-1192(ra) # 8000241a <wakeup>
  release(&lk->lk);
    800048ca:	854a                	mv	a0,s2
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	3cc080e7          	jalr	972(ra) # 80000c98 <release>
}
    800048d4:	60e2                	ld	ra,24(sp)
    800048d6:	6442                	ld	s0,16(sp)
    800048d8:	64a2                	ld	s1,8(sp)
    800048da:	6902                	ld	s2,0(sp)
    800048dc:	6105                	addi	sp,sp,32
    800048de:	8082                	ret

00000000800048e0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048e0:	7179                	addi	sp,sp,-48
    800048e2:	f406                	sd	ra,40(sp)
    800048e4:	f022                	sd	s0,32(sp)
    800048e6:	ec26                	sd	s1,24(sp)
    800048e8:	e84a                	sd	s2,16(sp)
    800048ea:	e44e                	sd	s3,8(sp)
    800048ec:	1800                	addi	s0,sp,48
    800048ee:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048f0:	00850913          	addi	s2,a0,8
    800048f4:	854a                	mv	a0,s2
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	2ee080e7          	jalr	750(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048fe:	409c                	lw	a5,0(s1)
    80004900:	ef99                	bnez	a5,8000491e <holdingsleep+0x3e>
    80004902:	4481                	li	s1,0
  release(&lk->lk);
    80004904:	854a                	mv	a0,s2
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	392080e7          	jalr	914(ra) # 80000c98 <release>
  return r;
}
    8000490e:	8526                	mv	a0,s1
    80004910:	70a2                	ld	ra,40(sp)
    80004912:	7402                	ld	s0,32(sp)
    80004914:	64e2                	ld	s1,24(sp)
    80004916:	6942                	ld	s2,16(sp)
    80004918:	69a2                	ld	s3,8(sp)
    8000491a:	6145                	addi	sp,sp,48
    8000491c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000491e:	0284a983          	lw	s3,40(s1)
    80004922:	ffffd097          	auipc	ra,0xffffd
    80004926:	fe6080e7          	jalr	-26(ra) # 80001908 <myproc>
    8000492a:	5904                	lw	s1,48(a0)
    8000492c:	413484b3          	sub	s1,s1,s3
    80004930:	0014b493          	seqz	s1,s1
    80004934:	bfc1                	j	80004904 <holdingsleep+0x24>

0000000080004936 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004936:	1141                	addi	sp,sp,-16
    80004938:	e406                	sd	ra,8(sp)
    8000493a:	e022                	sd	s0,0(sp)
    8000493c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000493e:	00004597          	auipc	a1,0x4
    80004942:	d5258593          	addi	a1,a1,-686 # 80008690 <syscalls+0x248>
    80004946:	0001d517          	auipc	a0,0x1d
    8000494a:	3ba50513          	addi	a0,a0,954 # 80021d00 <ftable>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	206080e7          	jalr	518(ra) # 80000b54 <initlock>
}
    80004956:	60a2                	ld	ra,8(sp)
    80004958:	6402                	ld	s0,0(sp)
    8000495a:	0141                	addi	sp,sp,16
    8000495c:	8082                	ret

000000008000495e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000495e:	1101                	addi	sp,sp,-32
    80004960:	ec06                	sd	ra,24(sp)
    80004962:	e822                	sd	s0,16(sp)
    80004964:	e426                	sd	s1,8(sp)
    80004966:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004968:	0001d517          	auipc	a0,0x1d
    8000496c:	39850513          	addi	a0,a0,920 # 80021d00 <ftable>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	274080e7          	jalr	628(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004978:	0001d497          	auipc	s1,0x1d
    8000497c:	3a048493          	addi	s1,s1,928 # 80021d18 <ftable+0x18>
    80004980:	0001e717          	auipc	a4,0x1e
    80004984:	33870713          	addi	a4,a4,824 # 80022cb8 <ftable+0xfb8>
    if(f->ref == 0){
    80004988:	40dc                	lw	a5,4(s1)
    8000498a:	cf99                	beqz	a5,800049a8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000498c:	02848493          	addi	s1,s1,40
    80004990:	fee49ce3          	bne	s1,a4,80004988 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004994:	0001d517          	auipc	a0,0x1d
    80004998:	36c50513          	addi	a0,a0,876 # 80021d00 <ftable>
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	2fc080e7          	jalr	764(ra) # 80000c98 <release>
  return 0;
    800049a4:	4481                	li	s1,0
    800049a6:	a819                	j	800049bc <filealloc+0x5e>
      f->ref = 1;
    800049a8:	4785                	li	a5,1
    800049aa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049ac:	0001d517          	auipc	a0,0x1d
    800049b0:	35450513          	addi	a0,a0,852 # 80021d00 <ftable>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	2e4080e7          	jalr	740(ra) # 80000c98 <release>
}
    800049bc:	8526                	mv	a0,s1
    800049be:	60e2                	ld	ra,24(sp)
    800049c0:	6442                	ld	s0,16(sp)
    800049c2:	64a2                	ld	s1,8(sp)
    800049c4:	6105                	addi	sp,sp,32
    800049c6:	8082                	ret

00000000800049c8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049c8:	1101                	addi	sp,sp,-32
    800049ca:	ec06                	sd	ra,24(sp)
    800049cc:	e822                	sd	s0,16(sp)
    800049ce:	e426                	sd	s1,8(sp)
    800049d0:	1000                	addi	s0,sp,32
    800049d2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049d4:	0001d517          	auipc	a0,0x1d
    800049d8:	32c50513          	addi	a0,a0,812 # 80021d00 <ftable>
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	208080e7          	jalr	520(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049e4:	40dc                	lw	a5,4(s1)
    800049e6:	02f05263          	blez	a5,80004a0a <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049ea:	2785                	addiw	a5,a5,1
    800049ec:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049ee:	0001d517          	auipc	a0,0x1d
    800049f2:	31250513          	addi	a0,a0,786 # 80021d00 <ftable>
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	2a2080e7          	jalr	674(ra) # 80000c98 <release>
  return f;
}
    800049fe:	8526                	mv	a0,s1
    80004a00:	60e2                	ld	ra,24(sp)
    80004a02:	6442                	ld	s0,16(sp)
    80004a04:	64a2                	ld	s1,8(sp)
    80004a06:	6105                	addi	sp,sp,32
    80004a08:	8082                	ret
    panic("filedup");
    80004a0a:	00004517          	auipc	a0,0x4
    80004a0e:	c8e50513          	addi	a0,a0,-882 # 80008698 <syscalls+0x250>
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	b2c080e7          	jalr	-1236(ra) # 8000053e <panic>

0000000080004a1a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a1a:	7139                	addi	sp,sp,-64
    80004a1c:	fc06                	sd	ra,56(sp)
    80004a1e:	f822                	sd	s0,48(sp)
    80004a20:	f426                	sd	s1,40(sp)
    80004a22:	f04a                	sd	s2,32(sp)
    80004a24:	ec4e                	sd	s3,24(sp)
    80004a26:	e852                	sd	s4,16(sp)
    80004a28:	e456                	sd	s5,8(sp)
    80004a2a:	0080                	addi	s0,sp,64
    80004a2c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a2e:	0001d517          	auipc	a0,0x1d
    80004a32:	2d250513          	addi	a0,a0,722 # 80021d00 <ftable>
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a3e:	40dc                	lw	a5,4(s1)
    80004a40:	06f05163          	blez	a5,80004aa2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a44:	37fd                	addiw	a5,a5,-1
    80004a46:	0007871b          	sext.w	a4,a5
    80004a4a:	c0dc                	sw	a5,4(s1)
    80004a4c:	06e04363          	bgtz	a4,80004ab2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a50:	0004a903          	lw	s2,0(s1)
    80004a54:	0094ca83          	lbu	s5,9(s1)
    80004a58:	0104ba03          	ld	s4,16(s1)
    80004a5c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a60:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a64:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a68:	0001d517          	auipc	a0,0x1d
    80004a6c:	29850513          	addi	a0,a0,664 # 80021d00 <ftable>
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	228080e7          	jalr	552(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a78:	4785                	li	a5,1
    80004a7a:	04f90d63          	beq	s2,a5,80004ad4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a7e:	3979                	addiw	s2,s2,-2
    80004a80:	4785                	li	a5,1
    80004a82:	0527e063          	bltu	a5,s2,80004ac2 <fileclose+0xa8>
    begin_op();
    80004a86:	00000097          	auipc	ra,0x0
    80004a8a:	ac8080e7          	jalr	-1336(ra) # 8000454e <begin_op>
    iput(ff.ip);
    80004a8e:	854e                	mv	a0,s3
    80004a90:	fffff097          	auipc	ra,0xfffff
    80004a94:	2a6080e7          	jalr	678(ra) # 80003d36 <iput>
    end_op();
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	b36080e7          	jalr	-1226(ra) # 800045ce <end_op>
    80004aa0:	a00d                	j	80004ac2 <fileclose+0xa8>
    panic("fileclose");
    80004aa2:	00004517          	auipc	a0,0x4
    80004aa6:	bfe50513          	addi	a0,a0,-1026 # 800086a0 <syscalls+0x258>
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004ab2:	0001d517          	auipc	a0,0x1d
    80004ab6:	24e50513          	addi	a0,a0,590 # 80021d00 <ftable>
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	1de080e7          	jalr	478(ra) # 80000c98 <release>
  }
}
    80004ac2:	70e2                	ld	ra,56(sp)
    80004ac4:	7442                	ld	s0,48(sp)
    80004ac6:	74a2                	ld	s1,40(sp)
    80004ac8:	7902                	ld	s2,32(sp)
    80004aca:	69e2                	ld	s3,24(sp)
    80004acc:	6a42                	ld	s4,16(sp)
    80004ace:	6aa2                	ld	s5,8(sp)
    80004ad0:	6121                	addi	sp,sp,64
    80004ad2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ad4:	85d6                	mv	a1,s5
    80004ad6:	8552                	mv	a0,s4
    80004ad8:	00000097          	auipc	ra,0x0
    80004adc:	34c080e7          	jalr	844(ra) # 80004e24 <pipeclose>
    80004ae0:	b7cd                	j	80004ac2 <fileclose+0xa8>

0000000080004ae2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ae2:	715d                	addi	sp,sp,-80
    80004ae4:	e486                	sd	ra,72(sp)
    80004ae6:	e0a2                	sd	s0,64(sp)
    80004ae8:	fc26                	sd	s1,56(sp)
    80004aea:	f84a                	sd	s2,48(sp)
    80004aec:	f44e                	sd	s3,40(sp)
    80004aee:	0880                	addi	s0,sp,80
    80004af0:	84aa                	mv	s1,a0
    80004af2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	e14080e7          	jalr	-492(ra) # 80001908 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004afc:	409c                	lw	a5,0(s1)
    80004afe:	37f9                	addiw	a5,a5,-2
    80004b00:	4705                	li	a4,1
    80004b02:	04f76763          	bltu	a4,a5,80004b50 <filestat+0x6e>
    80004b06:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b08:	6c88                	ld	a0,24(s1)
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	072080e7          	jalr	114(ra) # 80003b7c <ilock>
    stati(f->ip, &st);
    80004b12:	fb840593          	addi	a1,s0,-72
    80004b16:	6c88                	ld	a0,24(s1)
    80004b18:	fffff097          	auipc	ra,0xfffff
    80004b1c:	2ee080e7          	jalr	750(ra) # 80003e06 <stati>
    iunlock(f->ip);
    80004b20:	6c88                	ld	a0,24(s1)
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	11c080e7          	jalr	284(ra) # 80003c3e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b2a:	46e1                	li	a3,24
    80004b2c:	fb840613          	addi	a2,s0,-72
    80004b30:	85ce                	mv	a1,s3
    80004b32:	07093503          	ld	a0,112(s2)
    80004b36:	ffffd097          	auipc	ra,0xffffd
    80004b3a:	b3c080e7          	jalr	-1220(ra) # 80001672 <copyout>
    80004b3e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b42:	60a6                	ld	ra,72(sp)
    80004b44:	6406                	ld	s0,64(sp)
    80004b46:	74e2                	ld	s1,56(sp)
    80004b48:	7942                	ld	s2,48(sp)
    80004b4a:	79a2                	ld	s3,40(sp)
    80004b4c:	6161                	addi	sp,sp,80
    80004b4e:	8082                	ret
  return -1;
    80004b50:	557d                	li	a0,-1
    80004b52:	bfc5                	j	80004b42 <filestat+0x60>

0000000080004b54 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b54:	7179                	addi	sp,sp,-48
    80004b56:	f406                	sd	ra,40(sp)
    80004b58:	f022                	sd	s0,32(sp)
    80004b5a:	ec26                	sd	s1,24(sp)
    80004b5c:	e84a                	sd	s2,16(sp)
    80004b5e:	e44e                	sd	s3,8(sp)
    80004b60:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b62:	00854783          	lbu	a5,8(a0)
    80004b66:	c3d5                	beqz	a5,80004c0a <fileread+0xb6>
    80004b68:	84aa                	mv	s1,a0
    80004b6a:	89ae                	mv	s3,a1
    80004b6c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b6e:	411c                	lw	a5,0(a0)
    80004b70:	4705                	li	a4,1
    80004b72:	04e78963          	beq	a5,a4,80004bc4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b76:	470d                	li	a4,3
    80004b78:	04e78d63          	beq	a5,a4,80004bd2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b7c:	4709                	li	a4,2
    80004b7e:	06e79e63          	bne	a5,a4,80004bfa <fileread+0xa6>
    ilock(f->ip);
    80004b82:	6d08                	ld	a0,24(a0)
    80004b84:	fffff097          	auipc	ra,0xfffff
    80004b88:	ff8080e7          	jalr	-8(ra) # 80003b7c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b8c:	874a                	mv	a4,s2
    80004b8e:	5094                	lw	a3,32(s1)
    80004b90:	864e                	mv	a2,s3
    80004b92:	4585                	li	a1,1
    80004b94:	6c88                	ld	a0,24(s1)
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	29a080e7          	jalr	666(ra) # 80003e30 <readi>
    80004b9e:	892a                	mv	s2,a0
    80004ba0:	00a05563          	blez	a0,80004baa <fileread+0x56>
      f->off += r;
    80004ba4:	509c                	lw	a5,32(s1)
    80004ba6:	9fa9                	addw	a5,a5,a0
    80004ba8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004baa:	6c88                	ld	a0,24(s1)
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	092080e7          	jalr	146(ra) # 80003c3e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bb4:	854a                	mv	a0,s2
    80004bb6:	70a2                	ld	ra,40(sp)
    80004bb8:	7402                	ld	s0,32(sp)
    80004bba:	64e2                	ld	s1,24(sp)
    80004bbc:	6942                	ld	s2,16(sp)
    80004bbe:	69a2                	ld	s3,8(sp)
    80004bc0:	6145                	addi	sp,sp,48
    80004bc2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bc4:	6908                	ld	a0,16(a0)
    80004bc6:	00000097          	auipc	ra,0x0
    80004bca:	3c8080e7          	jalr	968(ra) # 80004f8e <piperead>
    80004bce:	892a                	mv	s2,a0
    80004bd0:	b7d5                	j	80004bb4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bd2:	02451783          	lh	a5,36(a0)
    80004bd6:	03079693          	slli	a3,a5,0x30
    80004bda:	92c1                	srli	a3,a3,0x30
    80004bdc:	4725                	li	a4,9
    80004bde:	02d76863          	bltu	a4,a3,80004c0e <fileread+0xba>
    80004be2:	0792                	slli	a5,a5,0x4
    80004be4:	0001d717          	auipc	a4,0x1d
    80004be8:	07c70713          	addi	a4,a4,124 # 80021c60 <devsw>
    80004bec:	97ba                	add	a5,a5,a4
    80004bee:	639c                	ld	a5,0(a5)
    80004bf0:	c38d                	beqz	a5,80004c12 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bf2:	4505                	li	a0,1
    80004bf4:	9782                	jalr	a5
    80004bf6:	892a                	mv	s2,a0
    80004bf8:	bf75                	j	80004bb4 <fileread+0x60>
    panic("fileread");
    80004bfa:	00004517          	auipc	a0,0x4
    80004bfe:	ab650513          	addi	a0,a0,-1354 # 800086b0 <syscalls+0x268>
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	93c080e7          	jalr	-1732(ra) # 8000053e <panic>
    return -1;
    80004c0a:	597d                	li	s2,-1
    80004c0c:	b765                	j	80004bb4 <fileread+0x60>
      return -1;
    80004c0e:	597d                	li	s2,-1
    80004c10:	b755                	j	80004bb4 <fileread+0x60>
    80004c12:	597d                	li	s2,-1
    80004c14:	b745                	j	80004bb4 <fileread+0x60>

0000000080004c16 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c16:	715d                	addi	sp,sp,-80
    80004c18:	e486                	sd	ra,72(sp)
    80004c1a:	e0a2                	sd	s0,64(sp)
    80004c1c:	fc26                	sd	s1,56(sp)
    80004c1e:	f84a                	sd	s2,48(sp)
    80004c20:	f44e                	sd	s3,40(sp)
    80004c22:	f052                	sd	s4,32(sp)
    80004c24:	ec56                	sd	s5,24(sp)
    80004c26:	e85a                	sd	s6,16(sp)
    80004c28:	e45e                	sd	s7,8(sp)
    80004c2a:	e062                	sd	s8,0(sp)
    80004c2c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c2e:	00954783          	lbu	a5,9(a0)
    80004c32:	10078663          	beqz	a5,80004d3e <filewrite+0x128>
    80004c36:	892a                	mv	s2,a0
    80004c38:	8aae                	mv	s5,a1
    80004c3a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c3c:	411c                	lw	a5,0(a0)
    80004c3e:	4705                	li	a4,1
    80004c40:	02e78263          	beq	a5,a4,80004c64 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c44:	470d                	li	a4,3
    80004c46:	02e78663          	beq	a5,a4,80004c72 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c4a:	4709                	li	a4,2
    80004c4c:	0ee79163          	bne	a5,a4,80004d2e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c50:	0ac05d63          	blez	a2,80004d0a <filewrite+0xf4>
    int i = 0;
    80004c54:	4981                	li	s3,0
    80004c56:	6b05                	lui	s6,0x1
    80004c58:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c5c:	6b85                	lui	s7,0x1
    80004c5e:	c00b8b9b          	addiw	s7,s7,-1024
    80004c62:	a861                	j	80004cfa <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c64:	6908                	ld	a0,16(a0)
    80004c66:	00000097          	auipc	ra,0x0
    80004c6a:	22e080e7          	jalr	558(ra) # 80004e94 <pipewrite>
    80004c6e:	8a2a                	mv	s4,a0
    80004c70:	a045                	j	80004d10 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c72:	02451783          	lh	a5,36(a0)
    80004c76:	03079693          	slli	a3,a5,0x30
    80004c7a:	92c1                	srli	a3,a3,0x30
    80004c7c:	4725                	li	a4,9
    80004c7e:	0cd76263          	bltu	a4,a3,80004d42 <filewrite+0x12c>
    80004c82:	0792                	slli	a5,a5,0x4
    80004c84:	0001d717          	auipc	a4,0x1d
    80004c88:	fdc70713          	addi	a4,a4,-36 # 80021c60 <devsw>
    80004c8c:	97ba                	add	a5,a5,a4
    80004c8e:	679c                	ld	a5,8(a5)
    80004c90:	cbdd                	beqz	a5,80004d46 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c92:	4505                	li	a0,1
    80004c94:	9782                	jalr	a5
    80004c96:	8a2a                	mv	s4,a0
    80004c98:	a8a5                	j	80004d10 <filewrite+0xfa>
    80004c9a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c9e:	00000097          	auipc	ra,0x0
    80004ca2:	8b0080e7          	jalr	-1872(ra) # 8000454e <begin_op>
      ilock(f->ip);
    80004ca6:	01893503          	ld	a0,24(s2)
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	ed2080e7          	jalr	-302(ra) # 80003b7c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cb2:	8762                	mv	a4,s8
    80004cb4:	02092683          	lw	a3,32(s2)
    80004cb8:	01598633          	add	a2,s3,s5
    80004cbc:	4585                	li	a1,1
    80004cbe:	01893503          	ld	a0,24(s2)
    80004cc2:	fffff097          	auipc	ra,0xfffff
    80004cc6:	266080e7          	jalr	614(ra) # 80003f28 <writei>
    80004cca:	84aa                	mv	s1,a0
    80004ccc:	00a05763          	blez	a0,80004cda <filewrite+0xc4>
        f->off += r;
    80004cd0:	02092783          	lw	a5,32(s2)
    80004cd4:	9fa9                	addw	a5,a5,a0
    80004cd6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cda:	01893503          	ld	a0,24(s2)
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	f60080e7          	jalr	-160(ra) # 80003c3e <iunlock>
      end_op();
    80004ce6:	00000097          	auipc	ra,0x0
    80004cea:	8e8080e7          	jalr	-1816(ra) # 800045ce <end_op>

      if(r != n1){
    80004cee:	009c1f63          	bne	s8,s1,80004d0c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cf2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cf6:	0149db63          	bge	s3,s4,80004d0c <filewrite+0xf6>
      int n1 = n - i;
    80004cfa:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004cfe:	84be                	mv	s1,a5
    80004d00:	2781                	sext.w	a5,a5
    80004d02:	f8fb5ce3          	bge	s6,a5,80004c9a <filewrite+0x84>
    80004d06:	84de                	mv	s1,s7
    80004d08:	bf49                	j	80004c9a <filewrite+0x84>
    int i = 0;
    80004d0a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d0c:	013a1f63          	bne	s4,s3,80004d2a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d10:	8552                	mv	a0,s4
    80004d12:	60a6                	ld	ra,72(sp)
    80004d14:	6406                	ld	s0,64(sp)
    80004d16:	74e2                	ld	s1,56(sp)
    80004d18:	7942                	ld	s2,48(sp)
    80004d1a:	79a2                	ld	s3,40(sp)
    80004d1c:	7a02                	ld	s4,32(sp)
    80004d1e:	6ae2                	ld	s5,24(sp)
    80004d20:	6b42                	ld	s6,16(sp)
    80004d22:	6ba2                	ld	s7,8(sp)
    80004d24:	6c02                	ld	s8,0(sp)
    80004d26:	6161                	addi	sp,sp,80
    80004d28:	8082                	ret
    ret = (i == n ? n : -1);
    80004d2a:	5a7d                	li	s4,-1
    80004d2c:	b7d5                	j	80004d10 <filewrite+0xfa>
    panic("filewrite");
    80004d2e:	00004517          	auipc	a0,0x4
    80004d32:	99250513          	addi	a0,a0,-1646 # 800086c0 <syscalls+0x278>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	808080e7          	jalr	-2040(ra) # 8000053e <panic>
    return -1;
    80004d3e:	5a7d                	li	s4,-1
    80004d40:	bfc1                	j	80004d10 <filewrite+0xfa>
      return -1;
    80004d42:	5a7d                	li	s4,-1
    80004d44:	b7f1                	j	80004d10 <filewrite+0xfa>
    80004d46:	5a7d                	li	s4,-1
    80004d48:	b7e1                	j	80004d10 <filewrite+0xfa>

0000000080004d4a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d4a:	7179                	addi	sp,sp,-48
    80004d4c:	f406                	sd	ra,40(sp)
    80004d4e:	f022                	sd	s0,32(sp)
    80004d50:	ec26                	sd	s1,24(sp)
    80004d52:	e84a                	sd	s2,16(sp)
    80004d54:	e44e                	sd	s3,8(sp)
    80004d56:	e052                	sd	s4,0(sp)
    80004d58:	1800                	addi	s0,sp,48
    80004d5a:	84aa                	mv	s1,a0
    80004d5c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d5e:	0005b023          	sd	zero,0(a1)
    80004d62:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d66:	00000097          	auipc	ra,0x0
    80004d6a:	bf8080e7          	jalr	-1032(ra) # 8000495e <filealloc>
    80004d6e:	e088                	sd	a0,0(s1)
    80004d70:	c551                	beqz	a0,80004dfc <pipealloc+0xb2>
    80004d72:	00000097          	auipc	ra,0x0
    80004d76:	bec080e7          	jalr	-1044(ra) # 8000495e <filealloc>
    80004d7a:	00aa3023          	sd	a0,0(s4)
    80004d7e:	c92d                	beqz	a0,80004df0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	d74080e7          	jalr	-652(ra) # 80000af4 <kalloc>
    80004d88:	892a                	mv	s2,a0
    80004d8a:	c125                	beqz	a0,80004dea <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d8c:	4985                	li	s3,1
    80004d8e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d92:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d96:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d9a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d9e:	00004597          	auipc	a1,0x4
    80004da2:	93258593          	addi	a1,a1,-1742 # 800086d0 <syscalls+0x288>
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	dae080e7          	jalr	-594(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004dae:	609c                	ld	a5,0(s1)
    80004db0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004db4:	609c                	ld	a5,0(s1)
    80004db6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dba:	609c                	ld	a5,0(s1)
    80004dbc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dc0:	609c                	ld	a5,0(s1)
    80004dc2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dc6:	000a3783          	ld	a5,0(s4)
    80004dca:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dce:	000a3783          	ld	a5,0(s4)
    80004dd2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dd6:	000a3783          	ld	a5,0(s4)
    80004dda:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dde:	000a3783          	ld	a5,0(s4)
    80004de2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004de6:	4501                	li	a0,0
    80004de8:	a025                	j	80004e10 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dea:	6088                	ld	a0,0(s1)
    80004dec:	e501                	bnez	a0,80004df4 <pipealloc+0xaa>
    80004dee:	a039                	j	80004dfc <pipealloc+0xb2>
    80004df0:	6088                	ld	a0,0(s1)
    80004df2:	c51d                	beqz	a0,80004e20 <pipealloc+0xd6>
    fileclose(*f0);
    80004df4:	00000097          	auipc	ra,0x0
    80004df8:	c26080e7          	jalr	-986(ra) # 80004a1a <fileclose>
  if(*f1)
    80004dfc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e00:	557d                	li	a0,-1
  if(*f1)
    80004e02:	c799                	beqz	a5,80004e10 <pipealloc+0xc6>
    fileclose(*f1);
    80004e04:	853e                	mv	a0,a5
    80004e06:	00000097          	auipc	ra,0x0
    80004e0a:	c14080e7          	jalr	-1004(ra) # 80004a1a <fileclose>
  return -1;
    80004e0e:	557d                	li	a0,-1
}
    80004e10:	70a2                	ld	ra,40(sp)
    80004e12:	7402                	ld	s0,32(sp)
    80004e14:	64e2                	ld	s1,24(sp)
    80004e16:	6942                	ld	s2,16(sp)
    80004e18:	69a2                	ld	s3,8(sp)
    80004e1a:	6a02                	ld	s4,0(sp)
    80004e1c:	6145                	addi	sp,sp,48
    80004e1e:	8082                	ret
  return -1;
    80004e20:	557d                	li	a0,-1
    80004e22:	b7fd                	j	80004e10 <pipealloc+0xc6>

0000000080004e24 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e24:	1101                	addi	sp,sp,-32
    80004e26:	ec06                	sd	ra,24(sp)
    80004e28:	e822                	sd	s0,16(sp)
    80004e2a:	e426                	sd	s1,8(sp)
    80004e2c:	e04a                	sd	s2,0(sp)
    80004e2e:	1000                	addi	s0,sp,32
    80004e30:	84aa                	mv	s1,a0
    80004e32:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e34:	ffffc097          	auipc	ra,0xffffc
    80004e38:	db0080e7          	jalr	-592(ra) # 80000be4 <acquire>
  if(writable){
    80004e3c:	02090d63          	beqz	s2,80004e76 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e40:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e44:	21848513          	addi	a0,s1,536
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	5d2080e7          	jalr	1490(ra) # 8000241a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e50:	2204b783          	ld	a5,544(s1)
    80004e54:	eb95                	bnez	a5,80004e88 <pipeclose+0x64>
    release(&pi->lock);
    80004e56:	8526                	mv	a0,s1
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	e40080e7          	jalr	-448(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e60:	8526                	mv	a0,s1
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	b96080e7          	jalr	-1130(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e6a:	60e2                	ld	ra,24(sp)
    80004e6c:	6442                	ld	s0,16(sp)
    80004e6e:	64a2                	ld	s1,8(sp)
    80004e70:	6902                	ld	s2,0(sp)
    80004e72:	6105                	addi	sp,sp,32
    80004e74:	8082                	ret
    pi->readopen = 0;
    80004e76:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e7a:	21c48513          	addi	a0,s1,540
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	59c080e7          	jalr	1436(ra) # 8000241a <wakeup>
    80004e86:	b7e9                	j	80004e50 <pipeclose+0x2c>
    release(&pi->lock);
    80004e88:	8526                	mv	a0,s1
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	e0e080e7          	jalr	-498(ra) # 80000c98 <release>
}
    80004e92:	bfe1                	j	80004e6a <pipeclose+0x46>

0000000080004e94 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e94:	7159                	addi	sp,sp,-112
    80004e96:	f486                	sd	ra,104(sp)
    80004e98:	f0a2                	sd	s0,96(sp)
    80004e9a:	eca6                	sd	s1,88(sp)
    80004e9c:	e8ca                	sd	s2,80(sp)
    80004e9e:	e4ce                	sd	s3,72(sp)
    80004ea0:	e0d2                	sd	s4,64(sp)
    80004ea2:	fc56                	sd	s5,56(sp)
    80004ea4:	f85a                	sd	s6,48(sp)
    80004ea6:	f45e                	sd	s7,40(sp)
    80004ea8:	f062                	sd	s8,32(sp)
    80004eaa:	ec66                	sd	s9,24(sp)
    80004eac:	1880                	addi	s0,sp,112
    80004eae:	84aa                	mv	s1,a0
    80004eb0:	8aae                	mv	s5,a1
    80004eb2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	a54080e7          	jalr	-1452(ra) # 80001908 <myproc>
    80004ebc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ebe:	8526                	mv	a0,s1
    80004ec0:	ffffc097          	auipc	ra,0xffffc
    80004ec4:	d24080e7          	jalr	-732(ra) # 80000be4 <acquire>
  while(i < n){
    80004ec8:	0d405163          	blez	s4,80004f8a <pipewrite+0xf6>
    80004ecc:	8ba6                	mv	s7,s1
  int i = 0;
    80004ece:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ed0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ed2:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ed6:	21c48c13          	addi	s8,s1,540
    80004eda:	a08d                	j	80004f3c <pipewrite+0xa8>
      release(&pi->lock);
    80004edc:	8526                	mv	a0,s1
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	dba080e7          	jalr	-582(ra) # 80000c98 <release>
      return -1;
    80004ee6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ee8:	854a                	mv	a0,s2
    80004eea:	70a6                	ld	ra,104(sp)
    80004eec:	7406                	ld	s0,96(sp)
    80004eee:	64e6                	ld	s1,88(sp)
    80004ef0:	6946                	ld	s2,80(sp)
    80004ef2:	69a6                	ld	s3,72(sp)
    80004ef4:	6a06                	ld	s4,64(sp)
    80004ef6:	7ae2                	ld	s5,56(sp)
    80004ef8:	7b42                	ld	s6,48(sp)
    80004efa:	7ba2                	ld	s7,40(sp)
    80004efc:	7c02                	ld	s8,32(sp)
    80004efe:	6ce2                	ld	s9,24(sp)
    80004f00:	6165                	addi	sp,sp,112
    80004f02:	8082                	ret
      wakeup(&pi->nread);
    80004f04:	8566                	mv	a0,s9
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	514080e7          	jalr	1300(ra) # 8000241a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f0e:	85de                	mv	a1,s7
    80004f10:	8562                	mv	a0,s8
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	196080e7          	jalr	406(ra) # 800020a8 <sleep>
    80004f1a:	a839                	j	80004f38 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f1c:	21c4a783          	lw	a5,540(s1)
    80004f20:	0017871b          	addiw	a4,a5,1
    80004f24:	20e4ae23          	sw	a4,540(s1)
    80004f28:	1ff7f793          	andi	a5,a5,511
    80004f2c:	97a6                	add	a5,a5,s1
    80004f2e:	f9f44703          	lbu	a4,-97(s0)
    80004f32:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f36:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f38:	03495d63          	bge	s2,s4,80004f72 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f3c:	2204a783          	lw	a5,544(s1)
    80004f40:	dfd1                	beqz	a5,80004edc <pipewrite+0x48>
    80004f42:	0289a783          	lw	a5,40(s3)
    80004f46:	fbd9                	bnez	a5,80004edc <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f48:	2184a783          	lw	a5,536(s1)
    80004f4c:	21c4a703          	lw	a4,540(s1)
    80004f50:	2007879b          	addiw	a5,a5,512
    80004f54:	faf708e3          	beq	a4,a5,80004f04 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f58:	4685                	li	a3,1
    80004f5a:	01590633          	add	a2,s2,s5
    80004f5e:	f9f40593          	addi	a1,s0,-97
    80004f62:	0709b503          	ld	a0,112(s3)
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	798080e7          	jalr	1944(ra) # 800016fe <copyin>
    80004f6e:	fb6517e3          	bne	a0,s6,80004f1c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f72:	21848513          	addi	a0,s1,536
    80004f76:	ffffd097          	auipc	ra,0xffffd
    80004f7a:	4a4080e7          	jalr	1188(ra) # 8000241a <wakeup>
  release(&pi->lock);
    80004f7e:	8526                	mv	a0,s1
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	d18080e7          	jalr	-744(ra) # 80000c98 <release>
  return i;
    80004f88:	b785                	j	80004ee8 <pipewrite+0x54>
  int i = 0;
    80004f8a:	4901                	li	s2,0
    80004f8c:	b7dd                	j	80004f72 <pipewrite+0xde>

0000000080004f8e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f8e:	715d                	addi	sp,sp,-80
    80004f90:	e486                	sd	ra,72(sp)
    80004f92:	e0a2                	sd	s0,64(sp)
    80004f94:	fc26                	sd	s1,56(sp)
    80004f96:	f84a                	sd	s2,48(sp)
    80004f98:	f44e                	sd	s3,40(sp)
    80004f9a:	f052                	sd	s4,32(sp)
    80004f9c:	ec56                	sd	s5,24(sp)
    80004f9e:	e85a                	sd	s6,16(sp)
    80004fa0:	0880                	addi	s0,sp,80
    80004fa2:	84aa                	mv	s1,a0
    80004fa4:	892e                	mv	s2,a1
    80004fa6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fa8:	ffffd097          	auipc	ra,0xffffd
    80004fac:	960080e7          	jalr	-1696(ra) # 80001908 <myproc>
    80004fb0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fb2:	8b26                	mv	s6,s1
    80004fb4:	8526                	mv	a0,s1
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	c2e080e7          	jalr	-978(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fbe:	2184a703          	lw	a4,536(s1)
    80004fc2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fc6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fca:	02f71463          	bne	a4,a5,80004ff2 <piperead+0x64>
    80004fce:	2244a783          	lw	a5,548(s1)
    80004fd2:	c385                	beqz	a5,80004ff2 <piperead+0x64>
    if(pr->killed){
    80004fd4:	028a2783          	lw	a5,40(s4)
    80004fd8:	ebc1                	bnez	a5,80005068 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fda:	85da                	mv	a1,s6
    80004fdc:	854e                	mv	a0,s3
    80004fde:	ffffd097          	auipc	ra,0xffffd
    80004fe2:	0ca080e7          	jalr	202(ra) # 800020a8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fe6:	2184a703          	lw	a4,536(s1)
    80004fea:	21c4a783          	lw	a5,540(s1)
    80004fee:	fef700e3          	beq	a4,a5,80004fce <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ff2:	09505263          	blez	s5,80005076 <piperead+0xe8>
    80004ff6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ff8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ffa:	2184a783          	lw	a5,536(s1)
    80004ffe:	21c4a703          	lw	a4,540(s1)
    80005002:	02f70d63          	beq	a4,a5,8000503c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005006:	0017871b          	addiw	a4,a5,1
    8000500a:	20e4ac23          	sw	a4,536(s1)
    8000500e:	1ff7f793          	andi	a5,a5,511
    80005012:	97a6                	add	a5,a5,s1
    80005014:	0187c783          	lbu	a5,24(a5)
    80005018:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000501c:	4685                	li	a3,1
    8000501e:	fbf40613          	addi	a2,s0,-65
    80005022:	85ca                	mv	a1,s2
    80005024:	070a3503          	ld	a0,112(s4)
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	64a080e7          	jalr	1610(ra) # 80001672 <copyout>
    80005030:	01650663          	beq	a0,s6,8000503c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005034:	2985                	addiw	s3,s3,1
    80005036:	0905                	addi	s2,s2,1
    80005038:	fd3a91e3          	bne	s5,s3,80004ffa <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000503c:	21c48513          	addi	a0,s1,540
    80005040:	ffffd097          	auipc	ra,0xffffd
    80005044:	3da080e7          	jalr	986(ra) # 8000241a <wakeup>
  release(&pi->lock);
    80005048:	8526                	mv	a0,s1
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	c4e080e7          	jalr	-946(ra) # 80000c98 <release>
  return i;
}
    80005052:	854e                	mv	a0,s3
    80005054:	60a6                	ld	ra,72(sp)
    80005056:	6406                	ld	s0,64(sp)
    80005058:	74e2                	ld	s1,56(sp)
    8000505a:	7942                	ld	s2,48(sp)
    8000505c:	79a2                	ld	s3,40(sp)
    8000505e:	7a02                	ld	s4,32(sp)
    80005060:	6ae2                	ld	s5,24(sp)
    80005062:	6b42                	ld	s6,16(sp)
    80005064:	6161                	addi	sp,sp,80
    80005066:	8082                	ret
      release(&pi->lock);
    80005068:	8526                	mv	a0,s1
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	c2e080e7          	jalr	-978(ra) # 80000c98 <release>
      return -1;
    80005072:	59fd                	li	s3,-1
    80005074:	bff9                	j	80005052 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005076:	4981                	li	s3,0
    80005078:	b7d1                	j	8000503c <piperead+0xae>

000000008000507a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000507a:	df010113          	addi	sp,sp,-528
    8000507e:	20113423          	sd	ra,520(sp)
    80005082:	20813023          	sd	s0,512(sp)
    80005086:	ffa6                	sd	s1,504(sp)
    80005088:	fbca                	sd	s2,496(sp)
    8000508a:	f7ce                	sd	s3,488(sp)
    8000508c:	f3d2                	sd	s4,480(sp)
    8000508e:	efd6                	sd	s5,472(sp)
    80005090:	ebda                	sd	s6,464(sp)
    80005092:	e7de                	sd	s7,456(sp)
    80005094:	e3e2                	sd	s8,448(sp)
    80005096:	ff66                	sd	s9,440(sp)
    80005098:	fb6a                	sd	s10,432(sp)
    8000509a:	f76e                	sd	s11,424(sp)
    8000509c:	0c00                	addi	s0,sp,528
    8000509e:	84aa                	mv	s1,a0
    800050a0:	dea43c23          	sd	a0,-520(s0)
    800050a4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	860080e7          	jalr	-1952(ra) # 80001908 <myproc>
    800050b0:	892a                	mv	s2,a0

  begin_op();
    800050b2:	fffff097          	auipc	ra,0xfffff
    800050b6:	49c080e7          	jalr	1180(ra) # 8000454e <begin_op>

  if((ip = namei(path)) == 0){
    800050ba:	8526                	mv	a0,s1
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	276080e7          	jalr	630(ra) # 80004332 <namei>
    800050c4:	c92d                	beqz	a0,80005136 <exec+0xbc>
    800050c6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050c8:	fffff097          	auipc	ra,0xfffff
    800050cc:	ab4080e7          	jalr	-1356(ra) # 80003b7c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050d0:	04000713          	li	a4,64
    800050d4:	4681                	li	a3,0
    800050d6:	e5040613          	addi	a2,s0,-432
    800050da:	4581                	li	a1,0
    800050dc:	8526                	mv	a0,s1
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	d52080e7          	jalr	-686(ra) # 80003e30 <readi>
    800050e6:	04000793          	li	a5,64
    800050ea:	00f51a63          	bne	a0,a5,800050fe <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050ee:	e5042703          	lw	a4,-432(s0)
    800050f2:	464c47b7          	lui	a5,0x464c4
    800050f6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050fa:	04f70463          	beq	a4,a5,80005142 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050fe:	8526                	mv	a0,s1
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	cde080e7          	jalr	-802(ra) # 80003dde <iunlockput>
    end_op();
    80005108:	fffff097          	auipc	ra,0xfffff
    8000510c:	4c6080e7          	jalr	1222(ra) # 800045ce <end_op>
  }
  return -1;
    80005110:	557d                	li	a0,-1
}
    80005112:	20813083          	ld	ra,520(sp)
    80005116:	20013403          	ld	s0,512(sp)
    8000511a:	74fe                	ld	s1,504(sp)
    8000511c:	795e                	ld	s2,496(sp)
    8000511e:	79be                	ld	s3,488(sp)
    80005120:	7a1e                	ld	s4,480(sp)
    80005122:	6afe                	ld	s5,472(sp)
    80005124:	6b5e                	ld	s6,464(sp)
    80005126:	6bbe                	ld	s7,456(sp)
    80005128:	6c1e                	ld	s8,448(sp)
    8000512a:	7cfa                	ld	s9,440(sp)
    8000512c:	7d5a                	ld	s10,432(sp)
    8000512e:	7dba                	ld	s11,424(sp)
    80005130:	21010113          	addi	sp,sp,528
    80005134:	8082                	ret
    end_op();
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	498080e7          	jalr	1176(ra) # 800045ce <end_op>
    return -1;
    8000513e:	557d                	li	a0,-1
    80005140:	bfc9                	j	80005112 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005142:	854a                	mv	a0,s2
    80005144:	ffffd097          	auipc	ra,0xffffd
    80005148:	882080e7          	jalr	-1918(ra) # 800019c6 <proc_pagetable>
    8000514c:	8baa                	mv	s7,a0
    8000514e:	d945                	beqz	a0,800050fe <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005150:	e7042983          	lw	s3,-400(s0)
    80005154:	e8845783          	lhu	a5,-376(s0)
    80005158:	c7ad                	beqz	a5,800051c2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000515a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000515c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000515e:	6c85                	lui	s9,0x1
    80005160:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005164:	def43823          	sd	a5,-528(s0)
    80005168:	a42d                	j	80005392 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000516a:	00003517          	auipc	a0,0x3
    8000516e:	56e50513          	addi	a0,a0,1390 # 800086d8 <syscalls+0x290>
    80005172:	ffffb097          	auipc	ra,0xffffb
    80005176:	3cc080e7          	jalr	972(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000517a:	8756                	mv	a4,s5
    8000517c:	012d86bb          	addw	a3,s11,s2
    80005180:	4581                	li	a1,0
    80005182:	8526                	mv	a0,s1
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	cac080e7          	jalr	-852(ra) # 80003e30 <readi>
    8000518c:	2501                	sext.w	a0,a0
    8000518e:	1aaa9963          	bne	s5,a0,80005340 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005192:	6785                	lui	a5,0x1
    80005194:	0127893b          	addw	s2,a5,s2
    80005198:	77fd                	lui	a5,0xfffff
    8000519a:	01478a3b          	addw	s4,a5,s4
    8000519e:	1f897163          	bgeu	s2,s8,80005380 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051a2:	02091593          	slli	a1,s2,0x20
    800051a6:	9181                	srli	a1,a1,0x20
    800051a8:	95ea                	add	a1,a1,s10
    800051aa:	855e                	mv	a0,s7
    800051ac:	ffffc097          	auipc	ra,0xffffc
    800051b0:	ec2080e7          	jalr	-318(ra) # 8000106e <walkaddr>
    800051b4:	862a                	mv	a2,a0
    if(pa == 0)
    800051b6:	d955                	beqz	a0,8000516a <exec+0xf0>
      n = PGSIZE;
    800051b8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051ba:	fd9a70e3          	bgeu	s4,s9,8000517a <exec+0x100>
      n = sz - i;
    800051be:	8ad2                	mv	s5,s4
    800051c0:	bf6d                	j	8000517a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051c2:	4901                	li	s2,0
  iunlockput(ip);
    800051c4:	8526                	mv	a0,s1
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	c18080e7          	jalr	-1000(ra) # 80003dde <iunlockput>
  end_op();
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	400080e7          	jalr	1024(ra) # 800045ce <end_op>
  p = myproc();
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	732080e7          	jalr	1842(ra) # 80001908 <myproc>
    800051de:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051e0:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800051e4:	6785                	lui	a5,0x1
    800051e6:	17fd                	addi	a5,a5,-1
    800051e8:	993e                	add	s2,s2,a5
    800051ea:	757d                	lui	a0,0xfffff
    800051ec:	00a977b3          	and	a5,s2,a0
    800051f0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051f4:	6609                	lui	a2,0x2
    800051f6:	963e                	add	a2,a2,a5
    800051f8:	85be                	mv	a1,a5
    800051fa:	855e                	mv	a0,s7
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	226080e7          	jalr	550(ra) # 80001422 <uvmalloc>
    80005204:	8b2a                	mv	s6,a0
  ip = 0;
    80005206:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005208:	12050c63          	beqz	a0,80005340 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000520c:	75f9                	lui	a1,0xffffe
    8000520e:	95aa                	add	a1,a1,a0
    80005210:	855e                	mv	a0,s7
    80005212:	ffffc097          	auipc	ra,0xffffc
    80005216:	42e080e7          	jalr	1070(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000521a:	7c7d                	lui	s8,0xfffff
    8000521c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000521e:	e0043783          	ld	a5,-512(s0)
    80005222:	6388                	ld	a0,0(a5)
    80005224:	c535                	beqz	a0,80005290 <exec+0x216>
    80005226:	e9040993          	addi	s3,s0,-368
    8000522a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000522e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	c34080e7          	jalr	-972(ra) # 80000e64 <strlen>
    80005238:	2505                	addiw	a0,a0,1
    8000523a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000523e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005242:	13896363          	bltu	s2,s8,80005368 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005246:	e0043d83          	ld	s11,-512(s0)
    8000524a:	000dba03          	ld	s4,0(s11)
    8000524e:	8552                	mv	a0,s4
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	c14080e7          	jalr	-1004(ra) # 80000e64 <strlen>
    80005258:	0015069b          	addiw	a3,a0,1
    8000525c:	8652                	mv	a2,s4
    8000525e:	85ca                	mv	a1,s2
    80005260:	855e                	mv	a0,s7
    80005262:	ffffc097          	auipc	ra,0xffffc
    80005266:	410080e7          	jalr	1040(ra) # 80001672 <copyout>
    8000526a:	10054363          	bltz	a0,80005370 <exec+0x2f6>
    ustack[argc] = sp;
    8000526e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005272:	0485                	addi	s1,s1,1
    80005274:	008d8793          	addi	a5,s11,8
    80005278:	e0f43023          	sd	a5,-512(s0)
    8000527c:	008db503          	ld	a0,8(s11)
    80005280:	c911                	beqz	a0,80005294 <exec+0x21a>
    if(argc >= MAXARG)
    80005282:	09a1                	addi	s3,s3,8
    80005284:	fb3c96e3          	bne	s9,s3,80005230 <exec+0x1b6>
  sz = sz1;
    80005288:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000528c:	4481                	li	s1,0
    8000528e:	a84d                	j	80005340 <exec+0x2c6>
  sp = sz;
    80005290:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005292:	4481                	li	s1,0
  ustack[argc] = 0;
    80005294:	00349793          	slli	a5,s1,0x3
    80005298:	f9040713          	addi	a4,s0,-112
    8000529c:	97ba                	add	a5,a5,a4
    8000529e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052a2:	00148693          	addi	a3,s1,1
    800052a6:	068e                	slli	a3,a3,0x3
    800052a8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052ac:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052b0:	01897663          	bgeu	s2,s8,800052bc <exec+0x242>
  sz = sz1;
    800052b4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052b8:	4481                	li	s1,0
    800052ba:	a059                	j	80005340 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052bc:	e9040613          	addi	a2,s0,-368
    800052c0:	85ca                	mv	a1,s2
    800052c2:	855e                	mv	a0,s7
    800052c4:	ffffc097          	auipc	ra,0xffffc
    800052c8:	3ae080e7          	jalr	942(ra) # 80001672 <copyout>
    800052cc:	0a054663          	bltz	a0,80005378 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052d0:	078ab783          	ld	a5,120(s5)
    800052d4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052d8:	df843783          	ld	a5,-520(s0)
    800052dc:	0007c703          	lbu	a4,0(a5)
    800052e0:	cf11                	beqz	a4,800052fc <exec+0x282>
    800052e2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052e4:	02f00693          	li	a3,47
    800052e8:	a039                	j	800052f6 <exec+0x27c>
      last = s+1;
    800052ea:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052ee:	0785                	addi	a5,a5,1
    800052f0:	fff7c703          	lbu	a4,-1(a5)
    800052f4:	c701                	beqz	a4,800052fc <exec+0x282>
    if(*s == '/')
    800052f6:	fed71ce3          	bne	a4,a3,800052ee <exec+0x274>
    800052fa:	bfc5                	j	800052ea <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800052fc:	4641                	li	a2,16
    800052fe:	df843583          	ld	a1,-520(s0)
    80005302:	178a8513          	addi	a0,s5,376
    80005306:	ffffc097          	auipc	ra,0xffffc
    8000530a:	b2c080e7          	jalr	-1236(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000530e:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005312:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005316:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000531a:	078ab783          	ld	a5,120(s5)
    8000531e:	e6843703          	ld	a4,-408(s0)
    80005322:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005324:	078ab783          	ld	a5,120(s5)
    80005328:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000532c:	85ea                	mv	a1,s10
    8000532e:	ffffc097          	auipc	ra,0xffffc
    80005332:	734080e7          	jalr	1844(ra) # 80001a62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005336:	0004851b          	sext.w	a0,s1
    8000533a:	bbe1                	j	80005112 <exec+0x98>
    8000533c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005340:	e0843583          	ld	a1,-504(s0)
    80005344:	855e                	mv	a0,s7
    80005346:	ffffc097          	auipc	ra,0xffffc
    8000534a:	71c080e7          	jalr	1820(ra) # 80001a62 <proc_freepagetable>
  if(ip){
    8000534e:	da0498e3          	bnez	s1,800050fe <exec+0x84>
  return -1;
    80005352:	557d                	li	a0,-1
    80005354:	bb7d                	j	80005112 <exec+0x98>
    80005356:	e1243423          	sd	s2,-504(s0)
    8000535a:	b7dd                	j	80005340 <exec+0x2c6>
    8000535c:	e1243423          	sd	s2,-504(s0)
    80005360:	b7c5                	j	80005340 <exec+0x2c6>
    80005362:	e1243423          	sd	s2,-504(s0)
    80005366:	bfe9                	j	80005340 <exec+0x2c6>
  sz = sz1;
    80005368:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000536c:	4481                	li	s1,0
    8000536e:	bfc9                	j	80005340 <exec+0x2c6>
  sz = sz1;
    80005370:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005374:	4481                	li	s1,0
    80005376:	b7e9                	j	80005340 <exec+0x2c6>
  sz = sz1;
    80005378:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000537c:	4481                	li	s1,0
    8000537e:	b7c9                	j	80005340 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005380:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005384:	2b05                	addiw	s6,s6,1
    80005386:	0389899b          	addiw	s3,s3,56
    8000538a:	e8845783          	lhu	a5,-376(s0)
    8000538e:	e2fb5be3          	bge	s6,a5,800051c4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005392:	2981                	sext.w	s3,s3
    80005394:	03800713          	li	a4,56
    80005398:	86ce                	mv	a3,s3
    8000539a:	e1840613          	addi	a2,s0,-488
    8000539e:	4581                	li	a1,0
    800053a0:	8526                	mv	a0,s1
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	a8e080e7          	jalr	-1394(ra) # 80003e30 <readi>
    800053aa:	03800793          	li	a5,56
    800053ae:	f8f517e3          	bne	a0,a5,8000533c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053b2:	e1842783          	lw	a5,-488(s0)
    800053b6:	4705                	li	a4,1
    800053b8:	fce796e3          	bne	a5,a4,80005384 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053bc:	e4043603          	ld	a2,-448(s0)
    800053c0:	e3843783          	ld	a5,-456(s0)
    800053c4:	f8f669e3          	bltu	a2,a5,80005356 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053c8:	e2843783          	ld	a5,-472(s0)
    800053cc:	963e                	add	a2,a2,a5
    800053ce:	f8f667e3          	bltu	a2,a5,8000535c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053d2:	85ca                	mv	a1,s2
    800053d4:	855e                	mv	a0,s7
    800053d6:	ffffc097          	auipc	ra,0xffffc
    800053da:	04c080e7          	jalr	76(ra) # 80001422 <uvmalloc>
    800053de:	e0a43423          	sd	a0,-504(s0)
    800053e2:	d141                	beqz	a0,80005362 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053e4:	e2843d03          	ld	s10,-472(s0)
    800053e8:	df043783          	ld	a5,-528(s0)
    800053ec:	00fd77b3          	and	a5,s10,a5
    800053f0:	fba1                	bnez	a5,80005340 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053f2:	e2042d83          	lw	s11,-480(s0)
    800053f6:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053fa:	f80c03e3          	beqz	s8,80005380 <exec+0x306>
    800053fe:	8a62                	mv	s4,s8
    80005400:	4901                	li	s2,0
    80005402:	b345                	j	800051a2 <exec+0x128>

0000000080005404 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005404:	7179                	addi	sp,sp,-48
    80005406:	f406                	sd	ra,40(sp)
    80005408:	f022                	sd	s0,32(sp)
    8000540a:	ec26                	sd	s1,24(sp)
    8000540c:	e84a                	sd	s2,16(sp)
    8000540e:	1800                	addi	s0,sp,48
    80005410:	892e                	mv	s2,a1
    80005412:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005414:	fdc40593          	addi	a1,s0,-36
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	ba8080e7          	jalr	-1112(ra) # 80002fc0 <argint>
    80005420:	04054063          	bltz	a0,80005460 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005424:	fdc42703          	lw	a4,-36(s0)
    80005428:	47bd                	li	a5,15
    8000542a:	02e7ed63          	bltu	a5,a4,80005464 <argfd+0x60>
    8000542e:	ffffc097          	auipc	ra,0xffffc
    80005432:	4da080e7          	jalr	1242(ra) # 80001908 <myproc>
    80005436:	fdc42703          	lw	a4,-36(s0)
    8000543a:	01e70793          	addi	a5,a4,30
    8000543e:	078e                	slli	a5,a5,0x3
    80005440:	953e                	add	a0,a0,a5
    80005442:	611c                	ld	a5,0(a0)
    80005444:	c395                	beqz	a5,80005468 <argfd+0x64>
    return -1;
  if(pfd)
    80005446:	00090463          	beqz	s2,8000544e <argfd+0x4a>
    *pfd = fd;
    8000544a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000544e:	4501                	li	a0,0
  if(pf)
    80005450:	c091                	beqz	s1,80005454 <argfd+0x50>
    *pf = f;
    80005452:	e09c                	sd	a5,0(s1)
}
    80005454:	70a2                	ld	ra,40(sp)
    80005456:	7402                	ld	s0,32(sp)
    80005458:	64e2                	ld	s1,24(sp)
    8000545a:	6942                	ld	s2,16(sp)
    8000545c:	6145                	addi	sp,sp,48
    8000545e:	8082                	ret
    return -1;
    80005460:	557d                	li	a0,-1
    80005462:	bfcd                	j	80005454 <argfd+0x50>
    return -1;
    80005464:	557d                	li	a0,-1
    80005466:	b7fd                	j	80005454 <argfd+0x50>
    80005468:	557d                	li	a0,-1
    8000546a:	b7ed                	j	80005454 <argfd+0x50>

000000008000546c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000546c:	1101                	addi	sp,sp,-32
    8000546e:	ec06                	sd	ra,24(sp)
    80005470:	e822                	sd	s0,16(sp)
    80005472:	e426                	sd	s1,8(sp)
    80005474:	1000                	addi	s0,sp,32
    80005476:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005478:	ffffc097          	auipc	ra,0xffffc
    8000547c:	490080e7          	jalr	1168(ra) # 80001908 <myproc>
    80005480:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005482:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005486:	4501                	li	a0,0
    80005488:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000548a:	6398                	ld	a4,0(a5)
    8000548c:	cb19                	beqz	a4,800054a2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000548e:	2505                	addiw	a0,a0,1
    80005490:	07a1                	addi	a5,a5,8
    80005492:	fed51ce3          	bne	a0,a3,8000548a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005496:	557d                	li	a0,-1
}
    80005498:	60e2                	ld	ra,24(sp)
    8000549a:	6442                	ld	s0,16(sp)
    8000549c:	64a2                	ld	s1,8(sp)
    8000549e:	6105                	addi	sp,sp,32
    800054a0:	8082                	ret
      p->ofile[fd] = f;
    800054a2:	01e50793          	addi	a5,a0,30
    800054a6:	078e                	slli	a5,a5,0x3
    800054a8:	963e                	add	a2,a2,a5
    800054aa:	e204                	sd	s1,0(a2)
      return fd;
    800054ac:	b7f5                	j	80005498 <fdalloc+0x2c>

00000000800054ae <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054ae:	715d                	addi	sp,sp,-80
    800054b0:	e486                	sd	ra,72(sp)
    800054b2:	e0a2                	sd	s0,64(sp)
    800054b4:	fc26                	sd	s1,56(sp)
    800054b6:	f84a                	sd	s2,48(sp)
    800054b8:	f44e                	sd	s3,40(sp)
    800054ba:	f052                	sd	s4,32(sp)
    800054bc:	ec56                	sd	s5,24(sp)
    800054be:	0880                	addi	s0,sp,80
    800054c0:	89ae                	mv	s3,a1
    800054c2:	8ab2                	mv	s5,a2
    800054c4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054c6:	fb040593          	addi	a1,s0,-80
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	e86080e7          	jalr	-378(ra) # 80004350 <nameiparent>
    800054d2:	892a                	mv	s2,a0
    800054d4:	12050f63          	beqz	a0,80005612 <create+0x164>
    return 0;

  ilock(dp);
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	6a4080e7          	jalr	1700(ra) # 80003b7c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054e0:	4601                	li	a2,0
    800054e2:	fb040593          	addi	a1,s0,-80
    800054e6:	854a                	mv	a0,s2
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	b78080e7          	jalr	-1160(ra) # 80004060 <dirlookup>
    800054f0:	84aa                	mv	s1,a0
    800054f2:	c921                	beqz	a0,80005542 <create+0x94>
    iunlockput(dp);
    800054f4:	854a                	mv	a0,s2
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	8e8080e7          	jalr	-1816(ra) # 80003dde <iunlockput>
    ilock(ip);
    800054fe:	8526                	mv	a0,s1
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	67c080e7          	jalr	1660(ra) # 80003b7c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005508:	2981                	sext.w	s3,s3
    8000550a:	4789                	li	a5,2
    8000550c:	02f99463          	bne	s3,a5,80005534 <create+0x86>
    80005510:	0444d783          	lhu	a5,68(s1)
    80005514:	37f9                	addiw	a5,a5,-2
    80005516:	17c2                	slli	a5,a5,0x30
    80005518:	93c1                	srli	a5,a5,0x30
    8000551a:	4705                	li	a4,1
    8000551c:	00f76c63          	bltu	a4,a5,80005534 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005520:	8526                	mv	a0,s1
    80005522:	60a6                	ld	ra,72(sp)
    80005524:	6406                	ld	s0,64(sp)
    80005526:	74e2                	ld	s1,56(sp)
    80005528:	7942                	ld	s2,48(sp)
    8000552a:	79a2                	ld	s3,40(sp)
    8000552c:	7a02                	ld	s4,32(sp)
    8000552e:	6ae2                	ld	s5,24(sp)
    80005530:	6161                	addi	sp,sp,80
    80005532:	8082                	ret
    iunlockput(ip);
    80005534:	8526                	mv	a0,s1
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	8a8080e7          	jalr	-1880(ra) # 80003dde <iunlockput>
    return 0;
    8000553e:	4481                	li	s1,0
    80005540:	b7c5                	j	80005520 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005542:	85ce                	mv	a1,s3
    80005544:	00092503          	lw	a0,0(s2)
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	49c080e7          	jalr	1180(ra) # 800039e4 <ialloc>
    80005550:	84aa                	mv	s1,a0
    80005552:	c529                	beqz	a0,8000559c <create+0xee>
  ilock(ip);
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	628080e7          	jalr	1576(ra) # 80003b7c <ilock>
  ip->major = major;
    8000555c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005560:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005564:	4785                	li	a5,1
    80005566:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	546080e7          	jalr	1350(ra) # 80003ab2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005574:	2981                	sext.w	s3,s3
    80005576:	4785                	li	a5,1
    80005578:	02f98a63          	beq	s3,a5,800055ac <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000557c:	40d0                	lw	a2,4(s1)
    8000557e:	fb040593          	addi	a1,s0,-80
    80005582:	854a                	mv	a0,s2
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	cec080e7          	jalr	-788(ra) # 80004270 <dirlink>
    8000558c:	06054b63          	bltz	a0,80005602 <create+0x154>
  iunlockput(dp);
    80005590:	854a                	mv	a0,s2
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	84c080e7          	jalr	-1972(ra) # 80003dde <iunlockput>
  return ip;
    8000559a:	b759                	j	80005520 <create+0x72>
    panic("create: ialloc");
    8000559c:	00003517          	auipc	a0,0x3
    800055a0:	15c50513          	addi	a0,a0,348 # 800086f8 <syscalls+0x2b0>
    800055a4:	ffffb097          	auipc	ra,0xffffb
    800055a8:	f9a080e7          	jalr	-102(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055ac:	04a95783          	lhu	a5,74(s2)
    800055b0:	2785                	addiw	a5,a5,1
    800055b2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055b6:	854a                	mv	a0,s2
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	4fa080e7          	jalr	1274(ra) # 80003ab2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055c0:	40d0                	lw	a2,4(s1)
    800055c2:	00003597          	auipc	a1,0x3
    800055c6:	14658593          	addi	a1,a1,326 # 80008708 <syscalls+0x2c0>
    800055ca:	8526                	mv	a0,s1
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	ca4080e7          	jalr	-860(ra) # 80004270 <dirlink>
    800055d4:	00054f63          	bltz	a0,800055f2 <create+0x144>
    800055d8:	00492603          	lw	a2,4(s2)
    800055dc:	00003597          	auipc	a1,0x3
    800055e0:	13458593          	addi	a1,a1,308 # 80008710 <syscalls+0x2c8>
    800055e4:	8526                	mv	a0,s1
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	c8a080e7          	jalr	-886(ra) # 80004270 <dirlink>
    800055ee:	f80557e3          	bgez	a0,8000557c <create+0xce>
      panic("create dots");
    800055f2:	00003517          	auipc	a0,0x3
    800055f6:	12650513          	addi	a0,a0,294 # 80008718 <syscalls+0x2d0>
    800055fa:	ffffb097          	auipc	ra,0xffffb
    800055fe:	f44080e7          	jalr	-188(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005602:	00003517          	auipc	a0,0x3
    80005606:	12650513          	addi	a0,a0,294 # 80008728 <syscalls+0x2e0>
    8000560a:	ffffb097          	auipc	ra,0xffffb
    8000560e:	f34080e7          	jalr	-204(ra) # 8000053e <panic>
    return 0;
    80005612:	84aa                	mv	s1,a0
    80005614:	b731                	j	80005520 <create+0x72>

0000000080005616 <sys_dup>:
{
    80005616:	7179                	addi	sp,sp,-48
    80005618:	f406                	sd	ra,40(sp)
    8000561a:	f022                	sd	s0,32(sp)
    8000561c:	ec26                	sd	s1,24(sp)
    8000561e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005620:	fd840613          	addi	a2,s0,-40
    80005624:	4581                	li	a1,0
    80005626:	4501                	li	a0,0
    80005628:	00000097          	auipc	ra,0x0
    8000562c:	ddc080e7          	jalr	-548(ra) # 80005404 <argfd>
    return -1;
    80005630:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005632:	02054363          	bltz	a0,80005658 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005636:	fd843503          	ld	a0,-40(s0)
    8000563a:	00000097          	auipc	ra,0x0
    8000563e:	e32080e7          	jalr	-462(ra) # 8000546c <fdalloc>
    80005642:	84aa                	mv	s1,a0
    return -1;
    80005644:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005646:	00054963          	bltz	a0,80005658 <sys_dup+0x42>
  filedup(f);
    8000564a:	fd843503          	ld	a0,-40(s0)
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	37a080e7          	jalr	890(ra) # 800049c8 <filedup>
  return fd;
    80005656:	87a6                	mv	a5,s1
}
    80005658:	853e                	mv	a0,a5
    8000565a:	70a2                	ld	ra,40(sp)
    8000565c:	7402                	ld	s0,32(sp)
    8000565e:	64e2                	ld	s1,24(sp)
    80005660:	6145                	addi	sp,sp,48
    80005662:	8082                	ret

0000000080005664 <sys_read>:
{
    80005664:	7179                	addi	sp,sp,-48
    80005666:	f406                	sd	ra,40(sp)
    80005668:	f022                	sd	s0,32(sp)
    8000566a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000566c:	fe840613          	addi	a2,s0,-24
    80005670:	4581                	li	a1,0
    80005672:	4501                	li	a0,0
    80005674:	00000097          	auipc	ra,0x0
    80005678:	d90080e7          	jalr	-624(ra) # 80005404 <argfd>
    return -1;
    8000567c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567e:	04054163          	bltz	a0,800056c0 <sys_read+0x5c>
    80005682:	fe440593          	addi	a1,s0,-28
    80005686:	4509                	li	a0,2
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	938080e7          	jalr	-1736(ra) # 80002fc0 <argint>
    return -1;
    80005690:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005692:	02054763          	bltz	a0,800056c0 <sys_read+0x5c>
    80005696:	fd840593          	addi	a1,s0,-40
    8000569a:	4505                	li	a0,1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	946080e7          	jalr	-1722(ra) # 80002fe2 <argaddr>
    return -1;
    800056a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a6:	00054d63          	bltz	a0,800056c0 <sys_read+0x5c>
  return fileread(f, p, n);
    800056aa:	fe442603          	lw	a2,-28(s0)
    800056ae:	fd843583          	ld	a1,-40(s0)
    800056b2:	fe843503          	ld	a0,-24(s0)
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	49e080e7          	jalr	1182(ra) # 80004b54 <fileread>
    800056be:	87aa                	mv	a5,a0
}
    800056c0:	853e                	mv	a0,a5
    800056c2:	70a2                	ld	ra,40(sp)
    800056c4:	7402                	ld	s0,32(sp)
    800056c6:	6145                	addi	sp,sp,48
    800056c8:	8082                	ret

00000000800056ca <sys_write>:
{
    800056ca:	7179                	addi	sp,sp,-48
    800056cc:	f406                	sd	ra,40(sp)
    800056ce:	f022                	sd	s0,32(sp)
    800056d0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d2:	fe840613          	addi	a2,s0,-24
    800056d6:	4581                	li	a1,0
    800056d8:	4501                	li	a0,0
    800056da:	00000097          	auipc	ra,0x0
    800056de:	d2a080e7          	jalr	-726(ra) # 80005404 <argfd>
    return -1;
    800056e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e4:	04054163          	bltz	a0,80005726 <sys_write+0x5c>
    800056e8:	fe440593          	addi	a1,s0,-28
    800056ec:	4509                	li	a0,2
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	8d2080e7          	jalr	-1838(ra) # 80002fc0 <argint>
    return -1;
    800056f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f8:	02054763          	bltz	a0,80005726 <sys_write+0x5c>
    800056fc:	fd840593          	addi	a1,s0,-40
    80005700:	4505                	li	a0,1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	8e0080e7          	jalr	-1824(ra) # 80002fe2 <argaddr>
    return -1;
    8000570a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000570c:	00054d63          	bltz	a0,80005726 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005710:	fe442603          	lw	a2,-28(s0)
    80005714:	fd843583          	ld	a1,-40(s0)
    80005718:	fe843503          	ld	a0,-24(s0)
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	4fa080e7          	jalr	1274(ra) # 80004c16 <filewrite>
    80005724:	87aa                	mv	a5,a0
}
    80005726:	853e                	mv	a0,a5
    80005728:	70a2                	ld	ra,40(sp)
    8000572a:	7402                	ld	s0,32(sp)
    8000572c:	6145                	addi	sp,sp,48
    8000572e:	8082                	ret

0000000080005730 <sys_close>:
{
    80005730:	1101                	addi	sp,sp,-32
    80005732:	ec06                	sd	ra,24(sp)
    80005734:	e822                	sd	s0,16(sp)
    80005736:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005738:	fe040613          	addi	a2,s0,-32
    8000573c:	fec40593          	addi	a1,s0,-20
    80005740:	4501                	li	a0,0
    80005742:	00000097          	auipc	ra,0x0
    80005746:	cc2080e7          	jalr	-830(ra) # 80005404 <argfd>
    return -1;
    8000574a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000574c:	02054463          	bltz	a0,80005774 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005750:	ffffc097          	auipc	ra,0xffffc
    80005754:	1b8080e7          	jalr	440(ra) # 80001908 <myproc>
    80005758:	fec42783          	lw	a5,-20(s0)
    8000575c:	07f9                	addi	a5,a5,30
    8000575e:	078e                	slli	a5,a5,0x3
    80005760:	97aa                	add	a5,a5,a0
    80005762:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005766:	fe043503          	ld	a0,-32(s0)
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	2b0080e7          	jalr	688(ra) # 80004a1a <fileclose>
  return 0;
    80005772:	4781                	li	a5,0
}
    80005774:	853e                	mv	a0,a5
    80005776:	60e2                	ld	ra,24(sp)
    80005778:	6442                	ld	s0,16(sp)
    8000577a:	6105                	addi	sp,sp,32
    8000577c:	8082                	ret

000000008000577e <sys_fstat>:
{
    8000577e:	1101                	addi	sp,sp,-32
    80005780:	ec06                	sd	ra,24(sp)
    80005782:	e822                	sd	s0,16(sp)
    80005784:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005786:	fe840613          	addi	a2,s0,-24
    8000578a:	4581                	li	a1,0
    8000578c:	4501                	li	a0,0
    8000578e:	00000097          	auipc	ra,0x0
    80005792:	c76080e7          	jalr	-906(ra) # 80005404 <argfd>
    return -1;
    80005796:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005798:	02054563          	bltz	a0,800057c2 <sys_fstat+0x44>
    8000579c:	fe040593          	addi	a1,s0,-32
    800057a0:	4505                	li	a0,1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	840080e7          	jalr	-1984(ra) # 80002fe2 <argaddr>
    return -1;
    800057aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057ac:	00054b63          	bltz	a0,800057c2 <sys_fstat+0x44>
  return filestat(f, st);
    800057b0:	fe043583          	ld	a1,-32(s0)
    800057b4:	fe843503          	ld	a0,-24(s0)
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	32a080e7          	jalr	810(ra) # 80004ae2 <filestat>
    800057c0:	87aa                	mv	a5,a0
}
    800057c2:	853e                	mv	a0,a5
    800057c4:	60e2                	ld	ra,24(sp)
    800057c6:	6442                	ld	s0,16(sp)
    800057c8:	6105                	addi	sp,sp,32
    800057ca:	8082                	ret

00000000800057cc <sys_link>:
{
    800057cc:	7169                	addi	sp,sp,-304
    800057ce:	f606                	sd	ra,296(sp)
    800057d0:	f222                	sd	s0,288(sp)
    800057d2:	ee26                	sd	s1,280(sp)
    800057d4:	ea4a                	sd	s2,272(sp)
    800057d6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d8:	08000613          	li	a2,128
    800057dc:	ed040593          	addi	a1,s0,-304
    800057e0:	4501                	li	a0,0
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	822080e7          	jalr	-2014(ra) # 80003004 <argstr>
    return -1;
    800057ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ec:	10054e63          	bltz	a0,80005908 <sys_link+0x13c>
    800057f0:	08000613          	li	a2,128
    800057f4:	f5040593          	addi	a1,s0,-176
    800057f8:	4505                	li	a0,1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	80a080e7          	jalr	-2038(ra) # 80003004 <argstr>
    return -1;
    80005802:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005804:	10054263          	bltz	a0,80005908 <sys_link+0x13c>
  begin_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	d46080e7          	jalr	-698(ra) # 8000454e <begin_op>
  if((ip = namei(old)) == 0){
    80005810:	ed040513          	addi	a0,s0,-304
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	b1e080e7          	jalr	-1250(ra) # 80004332 <namei>
    8000581c:	84aa                	mv	s1,a0
    8000581e:	c551                	beqz	a0,800058aa <sys_link+0xde>
  ilock(ip);
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	35c080e7          	jalr	860(ra) # 80003b7c <ilock>
  if(ip->type == T_DIR){
    80005828:	04449703          	lh	a4,68(s1)
    8000582c:	4785                	li	a5,1
    8000582e:	08f70463          	beq	a4,a5,800058b6 <sys_link+0xea>
  ip->nlink++;
    80005832:	04a4d783          	lhu	a5,74(s1)
    80005836:	2785                	addiw	a5,a5,1
    80005838:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	274080e7          	jalr	628(ra) # 80003ab2 <iupdate>
  iunlock(ip);
    80005846:	8526                	mv	a0,s1
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	3f6080e7          	jalr	1014(ra) # 80003c3e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005850:	fd040593          	addi	a1,s0,-48
    80005854:	f5040513          	addi	a0,s0,-176
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	af8080e7          	jalr	-1288(ra) # 80004350 <nameiparent>
    80005860:	892a                	mv	s2,a0
    80005862:	c935                	beqz	a0,800058d6 <sys_link+0x10a>
  ilock(dp);
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	318080e7          	jalr	792(ra) # 80003b7c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000586c:	00092703          	lw	a4,0(s2)
    80005870:	409c                	lw	a5,0(s1)
    80005872:	04f71d63          	bne	a4,a5,800058cc <sys_link+0x100>
    80005876:	40d0                	lw	a2,4(s1)
    80005878:	fd040593          	addi	a1,s0,-48
    8000587c:	854a                	mv	a0,s2
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	9f2080e7          	jalr	-1550(ra) # 80004270 <dirlink>
    80005886:	04054363          	bltz	a0,800058cc <sys_link+0x100>
  iunlockput(dp);
    8000588a:	854a                	mv	a0,s2
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	552080e7          	jalr	1362(ra) # 80003dde <iunlockput>
  iput(ip);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	4a0080e7          	jalr	1184(ra) # 80003d36 <iput>
  end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	d30080e7          	jalr	-720(ra) # 800045ce <end_op>
  return 0;
    800058a6:	4781                	li	a5,0
    800058a8:	a085                	j	80005908 <sys_link+0x13c>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	d24080e7          	jalr	-732(ra) # 800045ce <end_op>
    return -1;
    800058b2:	57fd                	li	a5,-1
    800058b4:	a891                	j	80005908 <sys_link+0x13c>
    iunlockput(ip);
    800058b6:	8526                	mv	a0,s1
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	526080e7          	jalr	1318(ra) # 80003dde <iunlockput>
    end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	d0e080e7          	jalr	-754(ra) # 800045ce <end_op>
    return -1;
    800058c8:	57fd                	li	a5,-1
    800058ca:	a83d                	j	80005908 <sys_link+0x13c>
    iunlockput(dp);
    800058cc:	854a                	mv	a0,s2
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	510080e7          	jalr	1296(ra) # 80003dde <iunlockput>
  ilock(ip);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	2a4080e7          	jalr	676(ra) # 80003b7c <ilock>
  ip->nlink--;
    800058e0:	04a4d783          	lhu	a5,74(s1)
    800058e4:	37fd                	addiw	a5,a5,-1
    800058e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	1c6080e7          	jalr	454(ra) # 80003ab2 <iupdate>
  iunlockput(ip);
    800058f4:	8526                	mv	a0,s1
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	4e8080e7          	jalr	1256(ra) # 80003dde <iunlockput>
  end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	cd0080e7          	jalr	-816(ra) # 800045ce <end_op>
  return -1;
    80005906:	57fd                	li	a5,-1
}
    80005908:	853e                	mv	a0,a5
    8000590a:	70b2                	ld	ra,296(sp)
    8000590c:	7412                	ld	s0,288(sp)
    8000590e:	64f2                	ld	s1,280(sp)
    80005910:	6952                	ld	s2,272(sp)
    80005912:	6155                	addi	sp,sp,304
    80005914:	8082                	ret

0000000080005916 <sys_unlink>:
{
    80005916:	7151                	addi	sp,sp,-240
    80005918:	f586                	sd	ra,232(sp)
    8000591a:	f1a2                	sd	s0,224(sp)
    8000591c:	eda6                	sd	s1,216(sp)
    8000591e:	e9ca                	sd	s2,208(sp)
    80005920:	e5ce                	sd	s3,200(sp)
    80005922:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005924:	08000613          	li	a2,128
    80005928:	f3040593          	addi	a1,s0,-208
    8000592c:	4501                	li	a0,0
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	6d6080e7          	jalr	1750(ra) # 80003004 <argstr>
    80005936:	18054163          	bltz	a0,80005ab8 <sys_unlink+0x1a2>
  begin_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	c14080e7          	jalr	-1004(ra) # 8000454e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005942:	fb040593          	addi	a1,s0,-80
    80005946:	f3040513          	addi	a0,s0,-208
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	a06080e7          	jalr	-1530(ra) # 80004350 <nameiparent>
    80005952:	84aa                	mv	s1,a0
    80005954:	c979                	beqz	a0,80005a2a <sys_unlink+0x114>
  ilock(dp);
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	226080e7          	jalr	550(ra) # 80003b7c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000595e:	00003597          	auipc	a1,0x3
    80005962:	daa58593          	addi	a1,a1,-598 # 80008708 <syscalls+0x2c0>
    80005966:	fb040513          	addi	a0,s0,-80
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	6dc080e7          	jalr	1756(ra) # 80004046 <namecmp>
    80005972:	14050a63          	beqz	a0,80005ac6 <sys_unlink+0x1b0>
    80005976:	00003597          	auipc	a1,0x3
    8000597a:	d9a58593          	addi	a1,a1,-614 # 80008710 <syscalls+0x2c8>
    8000597e:	fb040513          	addi	a0,s0,-80
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	6c4080e7          	jalr	1732(ra) # 80004046 <namecmp>
    8000598a:	12050e63          	beqz	a0,80005ac6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000598e:	f2c40613          	addi	a2,s0,-212
    80005992:	fb040593          	addi	a1,s0,-80
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	6c8080e7          	jalr	1736(ra) # 80004060 <dirlookup>
    800059a0:	892a                	mv	s2,a0
    800059a2:	12050263          	beqz	a0,80005ac6 <sys_unlink+0x1b0>
  ilock(ip);
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	1d6080e7          	jalr	470(ra) # 80003b7c <ilock>
  if(ip->nlink < 1)
    800059ae:	04a91783          	lh	a5,74(s2)
    800059b2:	08f05263          	blez	a5,80005a36 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059b6:	04491703          	lh	a4,68(s2)
    800059ba:	4785                	li	a5,1
    800059bc:	08f70563          	beq	a4,a5,80005a46 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059c0:	4641                	li	a2,16
    800059c2:	4581                	li	a1,0
    800059c4:	fc040513          	addi	a0,s0,-64
    800059c8:	ffffb097          	auipc	ra,0xffffb
    800059cc:	318080e7          	jalr	792(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059d0:	4741                	li	a4,16
    800059d2:	f2c42683          	lw	a3,-212(s0)
    800059d6:	fc040613          	addi	a2,s0,-64
    800059da:	4581                	li	a1,0
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	54a080e7          	jalr	1354(ra) # 80003f28 <writei>
    800059e6:	47c1                	li	a5,16
    800059e8:	0af51563          	bne	a0,a5,80005a92 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059ec:	04491703          	lh	a4,68(s2)
    800059f0:	4785                	li	a5,1
    800059f2:	0af70863          	beq	a4,a5,80005aa2 <sys_unlink+0x18c>
  iunlockput(dp);
    800059f6:	8526                	mv	a0,s1
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	3e6080e7          	jalr	998(ra) # 80003dde <iunlockput>
  ip->nlink--;
    80005a00:	04a95783          	lhu	a5,74(s2)
    80005a04:	37fd                	addiw	a5,a5,-1
    80005a06:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a0a:	854a                	mv	a0,s2
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	0a6080e7          	jalr	166(ra) # 80003ab2 <iupdate>
  iunlockput(ip);
    80005a14:	854a                	mv	a0,s2
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	3c8080e7          	jalr	968(ra) # 80003dde <iunlockput>
  end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	bb0080e7          	jalr	-1104(ra) # 800045ce <end_op>
  return 0;
    80005a26:	4501                	li	a0,0
    80005a28:	a84d                	j	80005ada <sys_unlink+0x1c4>
    end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	ba4080e7          	jalr	-1116(ra) # 800045ce <end_op>
    return -1;
    80005a32:	557d                	li	a0,-1
    80005a34:	a05d                	j	80005ada <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a36:	00003517          	auipc	a0,0x3
    80005a3a:	d0250513          	addi	a0,a0,-766 # 80008738 <syscalls+0x2f0>
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a46:	04c92703          	lw	a4,76(s2)
    80005a4a:	02000793          	li	a5,32
    80005a4e:	f6e7f9e3          	bgeu	a5,a4,800059c0 <sys_unlink+0xaa>
    80005a52:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a56:	4741                	li	a4,16
    80005a58:	86ce                	mv	a3,s3
    80005a5a:	f1840613          	addi	a2,s0,-232
    80005a5e:	4581                	li	a1,0
    80005a60:	854a                	mv	a0,s2
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	3ce080e7          	jalr	974(ra) # 80003e30 <readi>
    80005a6a:	47c1                	li	a5,16
    80005a6c:	00f51b63          	bne	a0,a5,80005a82 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a70:	f1845783          	lhu	a5,-232(s0)
    80005a74:	e7a1                	bnez	a5,80005abc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a76:	29c1                	addiw	s3,s3,16
    80005a78:	04c92783          	lw	a5,76(s2)
    80005a7c:	fcf9ede3          	bltu	s3,a5,80005a56 <sys_unlink+0x140>
    80005a80:	b781                	j	800059c0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a82:	00003517          	auipc	a0,0x3
    80005a86:	cce50513          	addi	a0,a0,-818 # 80008750 <syscalls+0x308>
    80005a8a:	ffffb097          	auipc	ra,0xffffb
    80005a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a92:	00003517          	auipc	a0,0x3
    80005a96:	cd650513          	addi	a0,a0,-810 # 80008768 <syscalls+0x320>
    80005a9a:	ffffb097          	auipc	ra,0xffffb
    80005a9e:	aa4080e7          	jalr	-1372(ra) # 8000053e <panic>
    dp->nlink--;
    80005aa2:	04a4d783          	lhu	a5,74(s1)
    80005aa6:	37fd                	addiw	a5,a5,-1
    80005aa8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005aac:	8526                	mv	a0,s1
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	004080e7          	jalr	4(ra) # 80003ab2 <iupdate>
    80005ab6:	b781                	j	800059f6 <sys_unlink+0xe0>
    return -1;
    80005ab8:	557d                	li	a0,-1
    80005aba:	a005                	j	80005ada <sys_unlink+0x1c4>
    iunlockput(ip);
    80005abc:	854a                	mv	a0,s2
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	320080e7          	jalr	800(ra) # 80003dde <iunlockput>
  iunlockput(dp);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	316080e7          	jalr	790(ra) # 80003dde <iunlockput>
  end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	afe080e7          	jalr	-1282(ra) # 800045ce <end_op>
  return -1;
    80005ad8:	557d                	li	a0,-1
}
    80005ada:	70ae                	ld	ra,232(sp)
    80005adc:	740e                	ld	s0,224(sp)
    80005ade:	64ee                	ld	s1,216(sp)
    80005ae0:	694e                	ld	s2,208(sp)
    80005ae2:	69ae                	ld	s3,200(sp)
    80005ae4:	616d                	addi	sp,sp,240
    80005ae6:	8082                	ret

0000000080005ae8 <sys_open>:

uint64
sys_open(void)
{
    80005ae8:	7131                	addi	sp,sp,-192
    80005aea:	fd06                	sd	ra,184(sp)
    80005aec:	f922                	sd	s0,176(sp)
    80005aee:	f526                	sd	s1,168(sp)
    80005af0:	f14a                	sd	s2,160(sp)
    80005af2:	ed4e                	sd	s3,152(sp)
    80005af4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005af6:	08000613          	li	a2,128
    80005afa:	f5040593          	addi	a1,s0,-176
    80005afe:	4501                	li	a0,0
    80005b00:	ffffd097          	auipc	ra,0xffffd
    80005b04:	504080e7          	jalr	1284(ra) # 80003004 <argstr>
    return -1;
    80005b08:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b0a:	0c054163          	bltz	a0,80005bcc <sys_open+0xe4>
    80005b0e:	f4c40593          	addi	a1,s0,-180
    80005b12:	4505                	li	a0,1
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	4ac080e7          	jalr	1196(ra) # 80002fc0 <argint>
    80005b1c:	0a054863          	bltz	a0,80005bcc <sys_open+0xe4>

  begin_op();
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	a2e080e7          	jalr	-1490(ra) # 8000454e <begin_op>

  if(omode & O_CREATE){
    80005b28:	f4c42783          	lw	a5,-180(s0)
    80005b2c:	2007f793          	andi	a5,a5,512
    80005b30:	cbdd                	beqz	a5,80005be6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b32:	4681                	li	a3,0
    80005b34:	4601                	li	a2,0
    80005b36:	4589                	li	a1,2
    80005b38:	f5040513          	addi	a0,s0,-176
    80005b3c:	00000097          	auipc	ra,0x0
    80005b40:	972080e7          	jalr	-1678(ra) # 800054ae <create>
    80005b44:	892a                	mv	s2,a0
    if(ip == 0){
    80005b46:	c959                	beqz	a0,80005bdc <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b48:	04491703          	lh	a4,68(s2)
    80005b4c:	478d                	li	a5,3
    80005b4e:	00f71763          	bne	a4,a5,80005b5c <sys_open+0x74>
    80005b52:	04695703          	lhu	a4,70(s2)
    80005b56:	47a5                	li	a5,9
    80005b58:	0ce7ec63          	bltu	a5,a4,80005c30 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	e02080e7          	jalr	-510(ra) # 8000495e <filealloc>
    80005b64:	89aa                	mv	s3,a0
    80005b66:	10050263          	beqz	a0,80005c6a <sys_open+0x182>
    80005b6a:	00000097          	auipc	ra,0x0
    80005b6e:	902080e7          	jalr	-1790(ra) # 8000546c <fdalloc>
    80005b72:	84aa                	mv	s1,a0
    80005b74:	0e054663          	bltz	a0,80005c60 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b78:	04491703          	lh	a4,68(s2)
    80005b7c:	478d                	li	a5,3
    80005b7e:	0cf70463          	beq	a4,a5,80005c46 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b82:	4789                	li	a5,2
    80005b84:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b88:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b8c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b90:	f4c42783          	lw	a5,-180(s0)
    80005b94:	0017c713          	xori	a4,a5,1
    80005b98:	8b05                	andi	a4,a4,1
    80005b9a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b9e:	0037f713          	andi	a4,a5,3
    80005ba2:	00e03733          	snez	a4,a4
    80005ba6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005baa:	4007f793          	andi	a5,a5,1024
    80005bae:	c791                	beqz	a5,80005bba <sys_open+0xd2>
    80005bb0:	04491703          	lh	a4,68(s2)
    80005bb4:	4789                	li	a5,2
    80005bb6:	08f70f63          	beq	a4,a5,80005c54 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bba:	854a                	mv	a0,s2
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	082080e7          	jalr	130(ra) # 80003c3e <iunlock>
  end_op();
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	a0a080e7          	jalr	-1526(ra) # 800045ce <end_op>

  return fd;
}
    80005bcc:	8526                	mv	a0,s1
    80005bce:	70ea                	ld	ra,184(sp)
    80005bd0:	744a                	ld	s0,176(sp)
    80005bd2:	74aa                	ld	s1,168(sp)
    80005bd4:	790a                	ld	s2,160(sp)
    80005bd6:	69ea                	ld	s3,152(sp)
    80005bd8:	6129                	addi	sp,sp,192
    80005bda:	8082                	ret
      end_op();
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	9f2080e7          	jalr	-1550(ra) # 800045ce <end_op>
      return -1;
    80005be4:	b7e5                	j	80005bcc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005be6:	f5040513          	addi	a0,s0,-176
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	748080e7          	jalr	1864(ra) # 80004332 <namei>
    80005bf2:	892a                	mv	s2,a0
    80005bf4:	c905                	beqz	a0,80005c24 <sys_open+0x13c>
    ilock(ip);
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	f86080e7          	jalr	-122(ra) # 80003b7c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bfe:	04491703          	lh	a4,68(s2)
    80005c02:	4785                	li	a5,1
    80005c04:	f4f712e3          	bne	a4,a5,80005b48 <sys_open+0x60>
    80005c08:	f4c42783          	lw	a5,-180(s0)
    80005c0c:	dba1                	beqz	a5,80005b5c <sys_open+0x74>
      iunlockput(ip);
    80005c0e:	854a                	mv	a0,s2
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	1ce080e7          	jalr	462(ra) # 80003dde <iunlockput>
      end_op();
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	9b6080e7          	jalr	-1610(ra) # 800045ce <end_op>
      return -1;
    80005c20:	54fd                	li	s1,-1
    80005c22:	b76d                	j	80005bcc <sys_open+0xe4>
      end_op();
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	9aa080e7          	jalr	-1622(ra) # 800045ce <end_op>
      return -1;
    80005c2c:	54fd                	li	s1,-1
    80005c2e:	bf79                	j	80005bcc <sys_open+0xe4>
    iunlockput(ip);
    80005c30:	854a                	mv	a0,s2
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	1ac080e7          	jalr	428(ra) # 80003dde <iunlockput>
    end_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	994080e7          	jalr	-1644(ra) # 800045ce <end_op>
    return -1;
    80005c42:	54fd                	li	s1,-1
    80005c44:	b761                	j	80005bcc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c46:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c4a:	04691783          	lh	a5,70(s2)
    80005c4e:	02f99223          	sh	a5,36(s3)
    80005c52:	bf2d                	j	80005b8c <sys_open+0xa4>
    itrunc(ip);
    80005c54:	854a                	mv	a0,s2
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	034080e7          	jalr	52(ra) # 80003c8a <itrunc>
    80005c5e:	bfb1                	j	80005bba <sys_open+0xd2>
      fileclose(f);
    80005c60:	854e                	mv	a0,s3
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	db8080e7          	jalr	-584(ra) # 80004a1a <fileclose>
    iunlockput(ip);
    80005c6a:	854a                	mv	a0,s2
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	172080e7          	jalr	370(ra) # 80003dde <iunlockput>
    end_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	95a080e7          	jalr	-1702(ra) # 800045ce <end_op>
    return -1;
    80005c7c:	54fd                	li	s1,-1
    80005c7e:	b7b9                	j	80005bcc <sys_open+0xe4>

0000000080005c80 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c80:	7175                	addi	sp,sp,-144
    80005c82:	e506                	sd	ra,136(sp)
    80005c84:	e122                	sd	s0,128(sp)
    80005c86:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	8c6080e7          	jalr	-1850(ra) # 8000454e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c90:	08000613          	li	a2,128
    80005c94:	f7040593          	addi	a1,s0,-144
    80005c98:	4501                	li	a0,0
    80005c9a:	ffffd097          	auipc	ra,0xffffd
    80005c9e:	36a080e7          	jalr	874(ra) # 80003004 <argstr>
    80005ca2:	02054963          	bltz	a0,80005cd4 <sys_mkdir+0x54>
    80005ca6:	4681                	li	a3,0
    80005ca8:	4601                	li	a2,0
    80005caa:	4585                	li	a1,1
    80005cac:	f7040513          	addi	a0,s0,-144
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	7fe080e7          	jalr	2046(ra) # 800054ae <create>
    80005cb8:	cd11                	beqz	a0,80005cd4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	124080e7          	jalr	292(ra) # 80003dde <iunlockput>
  end_op();
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	90c080e7          	jalr	-1780(ra) # 800045ce <end_op>
  return 0;
    80005cca:	4501                	li	a0,0
}
    80005ccc:	60aa                	ld	ra,136(sp)
    80005cce:	640a                	ld	s0,128(sp)
    80005cd0:	6149                	addi	sp,sp,144
    80005cd2:	8082                	ret
    end_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	8fa080e7          	jalr	-1798(ra) # 800045ce <end_op>
    return -1;
    80005cdc:	557d                	li	a0,-1
    80005cde:	b7fd                	j	80005ccc <sys_mkdir+0x4c>

0000000080005ce0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ce0:	7135                	addi	sp,sp,-160
    80005ce2:	ed06                	sd	ra,152(sp)
    80005ce4:	e922                	sd	s0,144(sp)
    80005ce6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	866080e7          	jalr	-1946(ra) # 8000454e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cf0:	08000613          	li	a2,128
    80005cf4:	f7040593          	addi	a1,s0,-144
    80005cf8:	4501                	li	a0,0
    80005cfa:	ffffd097          	auipc	ra,0xffffd
    80005cfe:	30a080e7          	jalr	778(ra) # 80003004 <argstr>
    80005d02:	04054a63          	bltz	a0,80005d56 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d06:	f6c40593          	addi	a1,s0,-148
    80005d0a:	4505                	li	a0,1
    80005d0c:	ffffd097          	auipc	ra,0xffffd
    80005d10:	2b4080e7          	jalr	692(ra) # 80002fc0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d14:	04054163          	bltz	a0,80005d56 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d18:	f6840593          	addi	a1,s0,-152
    80005d1c:	4509                	li	a0,2
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	2a2080e7          	jalr	674(ra) # 80002fc0 <argint>
     argint(1, &major) < 0 ||
    80005d26:	02054863          	bltz	a0,80005d56 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d2a:	f6841683          	lh	a3,-152(s0)
    80005d2e:	f6c41603          	lh	a2,-148(s0)
    80005d32:	458d                	li	a1,3
    80005d34:	f7040513          	addi	a0,s0,-144
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	776080e7          	jalr	1910(ra) # 800054ae <create>
     argint(2, &minor) < 0 ||
    80005d40:	c919                	beqz	a0,80005d56 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	09c080e7          	jalr	156(ra) # 80003dde <iunlockput>
  end_op();
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	884080e7          	jalr	-1916(ra) # 800045ce <end_op>
  return 0;
    80005d52:	4501                	li	a0,0
    80005d54:	a031                	j	80005d60 <sys_mknod+0x80>
    end_op();
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	878080e7          	jalr	-1928(ra) # 800045ce <end_op>
    return -1;
    80005d5e:	557d                	li	a0,-1
}
    80005d60:	60ea                	ld	ra,152(sp)
    80005d62:	644a                	ld	s0,144(sp)
    80005d64:	610d                	addi	sp,sp,160
    80005d66:	8082                	ret

0000000080005d68 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d68:	7135                	addi	sp,sp,-160
    80005d6a:	ed06                	sd	ra,152(sp)
    80005d6c:	e922                	sd	s0,144(sp)
    80005d6e:	e526                	sd	s1,136(sp)
    80005d70:	e14a                	sd	s2,128(sp)
    80005d72:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d74:	ffffc097          	auipc	ra,0xffffc
    80005d78:	b94080e7          	jalr	-1132(ra) # 80001908 <myproc>
    80005d7c:	892a                	mv	s2,a0
  
  begin_op();
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	7d0080e7          	jalr	2000(ra) # 8000454e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d86:	08000613          	li	a2,128
    80005d8a:	f6040593          	addi	a1,s0,-160
    80005d8e:	4501                	li	a0,0
    80005d90:	ffffd097          	auipc	ra,0xffffd
    80005d94:	274080e7          	jalr	628(ra) # 80003004 <argstr>
    80005d98:	04054b63          	bltz	a0,80005dee <sys_chdir+0x86>
    80005d9c:	f6040513          	addi	a0,s0,-160
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	592080e7          	jalr	1426(ra) # 80004332 <namei>
    80005da8:	84aa                	mv	s1,a0
    80005daa:	c131                	beqz	a0,80005dee <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	dd0080e7          	jalr	-560(ra) # 80003b7c <ilock>
  if(ip->type != T_DIR){
    80005db4:	04449703          	lh	a4,68(s1)
    80005db8:	4785                	li	a5,1
    80005dba:	04f71063          	bne	a4,a5,80005dfa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dbe:	8526                	mv	a0,s1
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	e7e080e7          	jalr	-386(ra) # 80003c3e <iunlock>
  iput(p->cwd);
    80005dc8:	17093503          	ld	a0,368(s2)
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	f6a080e7          	jalr	-150(ra) # 80003d36 <iput>
  end_op();
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	7fa080e7          	jalr	2042(ra) # 800045ce <end_op>
  p->cwd = ip;
    80005ddc:	16993823          	sd	s1,368(s2)
  return 0;
    80005de0:	4501                	li	a0,0
}
    80005de2:	60ea                	ld	ra,152(sp)
    80005de4:	644a                	ld	s0,144(sp)
    80005de6:	64aa                	ld	s1,136(sp)
    80005de8:	690a                	ld	s2,128(sp)
    80005dea:	610d                	addi	sp,sp,160
    80005dec:	8082                	ret
    end_op();
    80005dee:	ffffe097          	auipc	ra,0xffffe
    80005df2:	7e0080e7          	jalr	2016(ra) # 800045ce <end_op>
    return -1;
    80005df6:	557d                	li	a0,-1
    80005df8:	b7ed                	j	80005de2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005dfa:	8526                	mv	a0,s1
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	fe2080e7          	jalr	-30(ra) # 80003dde <iunlockput>
    end_op();
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	7ca080e7          	jalr	1994(ra) # 800045ce <end_op>
    return -1;
    80005e0c:	557d                	li	a0,-1
    80005e0e:	bfd1                	j	80005de2 <sys_chdir+0x7a>

0000000080005e10 <sys_exec>:

uint64
sys_exec(void)
{
    80005e10:	7145                	addi	sp,sp,-464
    80005e12:	e786                	sd	ra,456(sp)
    80005e14:	e3a2                	sd	s0,448(sp)
    80005e16:	ff26                	sd	s1,440(sp)
    80005e18:	fb4a                	sd	s2,432(sp)
    80005e1a:	f74e                	sd	s3,424(sp)
    80005e1c:	f352                	sd	s4,416(sp)
    80005e1e:	ef56                	sd	s5,408(sp)
    80005e20:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e22:	08000613          	li	a2,128
    80005e26:	f4040593          	addi	a1,s0,-192
    80005e2a:	4501                	li	a0,0
    80005e2c:	ffffd097          	auipc	ra,0xffffd
    80005e30:	1d8080e7          	jalr	472(ra) # 80003004 <argstr>
    return -1;
    80005e34:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e36:	0c054a63          	bltz	a0,80005f0a <sys_exec+0xfa>
    80005e3a:	e3840593          	addi	a1,s0,-456
    80005e3e:	4505                	li	a0,1
    80005e40:	ffffd097          	auipc	ra,0xffffd
    80005e44:	1a2080e7          	jalr	418(ra) # 80002fe2 <argaddr>
    80005e48:	0c054163          	bltz	a0,80005f0a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e4c:	10000613          	li	a2,256
    80005e50:	4581                	li	a1,0
    80005e52:	e4040513          	addi	a0,s0,-448
    80005e56:	ffffb097          	auipc	ra,0xffffb
    80005e5a:	e8a080e7          	jalr	-374(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e5e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e62:	89a6                	mv	s3,s1
    80005e64:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e66:	02000a13          	li	s4,32
    80005e6a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e6e:	00391513          	slli	a0,s2,0x3
    80005e72:	e3040593          	addi	a1,s0,-464
    80005e76:	e3843783          	ld	a5,-456(s0)
    80005e7a:	953e                	add	a0,a0,a5
    80005e7c:	ffffd097          	auipc	ra,0xffffd
    80005e80:	0aa080e7          	jalr	170(ra) # 80002f26 <fetchaddr>
    80005e84:	02054a63          	bltz	a0,80005eb8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e88:	e3043783          	ld	a5,-464(s0)
    80005e8c:	c3b9                	beqz	a5,80005ed2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e8e:	ffffb097          	auipc	ra,0xffffb
    80005e92:	c66080e7          	jalr	-922(ra) # 80000af4 <kalloc>
    80005e96:	85aa                	mv	a1,a0
    80005e98:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e9c:	cd11                	beqz	a0,80005eb8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e9e:	6605                	lui	a2,0x1
    80005ea0:	e3043503          	ld	a0,-464(s0)
    80005ea4:	ffffd097          	auipc	ra,0xffffd
    80005ea8:	0d4080e7          	jalr	212(ra) # 80002f78 <fetchstr>
    80005eac:	00054663          	bltz	a0,80005eb8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005eb0:	0905                	addi	s2,s2,1
    80005eb2:	09a1                	addi	s3,s3,8
    80005eb4:	fb491be3          	bne	s2,s4,80005e6a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eb8:	10048913          	addi	s2,s1,256
    80005ebc:	6088                	ld	a0,0(s1)
    80005ebe:	c529                	beqz	a0,80005f08 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ec0:	ffffb097          	auipc	ra,0xffffb
    80005ec4:	b38080e7          	jalr	-1224(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec8:	04a1                	addi	s1,s1,8
    80005eca:	ff2499e3          	bne	s1,s2,80005ebc <sys_exec+0xac>
  return -1;
    80005ece:	597d                	li	s2,-1
    80005ed0:	a82d                	j	80005f0a <sys_exec+0xfa>
      argv[i] = 0;
    80005ed2:	0a8e                	slli	s5,s5,0x3
    80005ed4:	fc040793          	addi	a5,s0,-64
    80005ed8:	9abe                	add	s5,s5,a5
    80005eda:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ede:	e4040593          	addi	a1,s0,-448
    80005ee2:	f4040513          	addi	a0,s0,-192
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	194080e7          	jalr	404(ra) # 8000507a <exec>
    80005eee:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef0:	10048993          	addi	s3,s1,256
    80005ef4:	6088                	ld	a0,0(s1)
    80005ef6:	c911                	beqz	a0,80005f0a <sys_exec+0xfa>
    kfree(argv[i]);
    80005ef8:	ffffb097          	auipc	ra,0xffffb
    80005efc:	b00080e7          	jalr	-1280(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f00:	04a1                	addi	s1,s1,8
    80005f02:	ff3499e3          	bne	s1,s3,80005ef4 <sys_exec+0xe4>
    80005f06:	a011                	j	80005f0a <sys_exec+0xfa>
  return -1;
    80005f08:	597d                	li	s2,-1
}
    80005f0a:	854a                	mv	a0,s2
    80005f0c:	60be                	ld	ra,456(sp)
    80005f0e:	641e                	ld	s0,448(sp)
    80005f10:	74fa                	ld	s1,440(sp)
    80005f12:	795a                	ld	s2,432(sp)
    80005f14:	79ba                	ld	s3,424(sp)
    80005f16:	7a1a                	ld	s4,416(sp)
    80005f18:	6afa                	ld	s5,408(sp)
    80005f1a:	6179                	addi	sp,sp,464
    80005f1c:	8082                	ret

0000000080005f1e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f1e:	7139                	addi	sp,sp,-64
    80005f20:	fc06                	sd	ra,56(sp)
    80005f22:	f822                	sd	s0,48(sp)
    80005f24:	f426                	sd	s1,40(sp)
    80005f26:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	9e0080e7          	jalr	-1568(ra) # 80001908 <myproc>
    80005f30:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f32:	fd840593          	addi	a1,s0,-40
    80005f36:	4501                	li	a0,0
    80005f38:	ffffd097          	auipc	ra,0xffffd
    80005f3c:	0aa080e7          	jalr	170(ra) # 80002fe2 <argaddr>
    return -1;
    80005f40:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f42:	0e054063          	bltz	a0,80006022 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f46:	fc840593          	addi	a1,s0,-56
    80005f4a:	fd040513          	addi	a0,s0,-48
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	dfc080e7          	jalr	-516(ra) # 80004d4a <pipealloc>
    return -1;
    80005f56:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f58:	0c054563          	bltz	a0,80006022 <sys_pipe+0x104>
  fd0 = -1;
    80005f5c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f60:	fd043503          	ld	a0,-48(s0)
    80005f64:	fffff097          	auipc	ra,0xfffff
    80005f68:	508080e7          	jalr	1288(ra) # 8000546c <fdalloc>
    80005f6c:	fca42223          	sw	a0,-60(s0)
    80005f70:	08054c63          	bltz	a0,80006008 <sys_pipe+0xea>
    80005f74:	fc843503          	ld	a0,-56(s0)
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	4f4080e7          	jalr	1268(ra) # 8000546c <fdalloc>
    80005f80:	fca42023          	sw	a0,-64(s0)
    80005f84:	06054863          	bltz	a0,80005ff4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f88:	4691                	li	a3,4
    80005f8a:	fc440613          	addi	a2,s0,-60
    80005f8e:	fd843583          	ld	a1,-40(s0)
    80005f92:	78a8                	ld	a0,112(s1)
    80005f94:	ffffb097          	auipc	ra,0xffffb
    80005f98:	6de080e7          	jalr	1758(ra) # 80001672 <copyout>
    80005f9c:	02054063          	bltz	a0,80005fbc <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fa0:	4691                	li	a3,4
    80005fa2:	fc040613          	addi	a2,s0,-64
    80005fa6:	fd843583          	ld	a1,-40(s0)
    80005faa:	0591                	addi	a1,a1,4
    80005fac:	78a8                	ld	a0,112(s1)
    80005fae:	ffffb097          	auipc	ra,0xffffb
    80005fb2:	6c4080e7          	jalr	1732(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fb6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fb8:	06055563          	bgez	a0,80006022 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fbc:	fc442783          	lw	a5,-60(s0)
    80005fc0:	07f9                	addi	a5,a5,30
    80005fc2:	078e                	slli	a5,a5,0x3
    80005fc4:	97a6                	add	a5,a5,s1
    80005fc6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fca:	fc042503          	lw	a0,-64(s0)
    80005fce:	0579                	addi	a0,a0,30
    80005fd0:	050e                	slli	a0,a0,0x3
    80005fd2:	9526                	add	a0,a0,s1
    80005fd4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fd8:	fd043503          	ld	a0,-48(s0)
    80005fdc:	fffff097          	auipc	ra,0xfffff
    80005fe0:	a3e080e7          	jalr	-1474(ra) # 80004a1a <fileclose>
    fileclose(wf);
    80005fe4:	fc843503          	ld	a0,-56(s0)
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	a32080e7          	jalr	-1486(ra) # 80004a1a <fileclose>
    return -1;
    80005ff0:	57fd                	li	a5,-1
    80005ff2:	a805                	j	80006022 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ff4:	fc442783          	lw	a5,-60(s0)
    80005ff8:	0007c863          	bltz	a5,80006008 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ffc:	01e78513          	addi	a0,a5,30
    80006000:	050e                	slli	a0,a0,0x3
    80006002:	9526                	add	a0,a0,s1
    80006004:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006008:	fd043503          	ld	a0,-48(s0)
    8000600c:	fffff097          	auipc	ra,0xfffff
    80006010:	a0e080e7          	jalr	-1522(ra) # 80004a1a <fileclose>
    fileclose(wf);
    80006014:	fc843503          	ld	a0,-56(s0)
    80006018:	fffff097          	auipc	ra,0xfffff
    8000601c:	a02080e7          	jalr	-1534(ra) # 80004a1a <fileclose>
    return -1;
    80006020:	57fd                	li	a5,-1
}
    80006022:	853e                	mv	a0,a5
    80006024:	70e2                	ld	ra,56(sp)
    80006026:	7442                	ld	s0,48(sp)
    80006028:	74a2                	ld	s1,40(sp)
    8000602a:	6121                	addi	sp,sp,64
    8000602c:	8082                	ret
	...

0000000080006030 <kernelvec>:
    80006030:	7111                	addi	sp,sp,-256
    80006032:	e006                	sd	ra,0(sp)
    80006034:	e40a                	sd	sp,8(sp)
    80006036:	e80e                	sd	gp,16(sp)
    80006038:	ec12                	sd	tp,24(sp)
    8000603a:	f016                	sd	t0,32(sp)
    8000603c:	f41a                	sd	t1,40(sp)
    8000603e:	f81e                	sd	t2,48(sp)
    80006040:	fc22                	sd	s0,56(sp)
    80006042:	e0a6                	sd	s1,64(sp)
    80006044:	e4aa                	sd	a0,72(sp)
    80006046:	e8ae                	sd	a1,80(sp)
    80006048:	ecb2                	sd	a2,88(sp)
    8000604a:	f0b6                	sd	a3,96(sp)
    8000604c:	f4ba                	sd	a4,104(sp)
    8000604e:	f8be                	sd	a5,112(sp)
    80006050:	fcc2                	sd	a6,120(sp)
    80006052:	e146                	sd	a7,128(sp)
    80006054:	e54a                	sd	s2,136(sp)
    80006056:	e94e                	sd	s3,144(sp)
    80006058:	ed52                	sd	s4,152(sp)
    8000605a:	f156                	sd	s5,160(sp)
    8000605c:	f55a                	sd	s6,168(sp)
    8000605e:	f95e                	sd	s7,176(sp)
    80006060:	fd62                	sd	s8,184(sp)
    80006062:	e1e6                	sd	s9,192(sp)
    80006064:	e5ea                	sd	s10,200(sp)
    80006066:	e9ee                	sd	s11,208(sp)
    80006068:	edf2                	sd	t3,216(sp)
    8000606a:	f1f6                	sd	t4,224(sp)
    8000606c:	f5fa                	sd	t5,232(sp)
    8000606e:	f9fe                	sd	t6,240(sp)
    80006070:	d83fc0ef          	jal	ra,80002df2 <kerneltrap>
    80006074:	6082                	ld	ra,0(sp)
    80006076:	6122                	ld	sp,8(sp)
    80006078:	61c2                	ld	gp,16(sp)
    8000607a:	7282                	ld	t0,32(sp)
    8000607c:	7322                	ld	t1,40(sp)
    8000607e:	73c2                	ld	t2,48(sp)
    80006080:	7462                	ld	s0,56(sp)
    80006082:	6486                	ld	s1,64(sp)
    80006084:	6526                	ld	a0,72(sp)
    80006086:	65c6                	ld	a1,80(sp)
    80006088:	6666                	ld	a2,88(sp)
    8000608a:	7686                	ld	a3,96(sp)
    8000608c:	7726                	ld	a4,104(sp)
    8000608e:	77c6                	ld	a5,112(sp)
    80006090:	7866                	ld	a6,120(sp)
    80006092:	688a                	ld	a7,128(sp)
    80006094:	692a                	ld	s2,136(sp)
    80006096:	69ca                	ld	s3,144(sp)
    80006098:	6a6a                	ld	s4,152(sp)
    8000609a:	7a8a                	ld	s5,160(sp)
    8000609c:	7b2a                	ld	s6,168(sp)
    8000609e:	7bca                	ld	s7,176(sp)
    800060a0:	7c6a                	ld	s8,184(sp)
    800060a2:	6c8e                	ld	s9,192(sp)
    800060a4:	6d2e                	ld	s10,200(sp)
    800060a6:	6dce                	ld	s11,208(sp)
    800060a8:	6e6e                	ld	t3,216(sp)
    800060aa:	7e8e                	ld	t4,224(sp)
    800060ac:	7f2e                	ld	t5,232(sp)
    800060ae:	7fce                	ld	t6,240(sp)
    800060b0:	6111                	addi	sp,sp,256
    800060b2:	10200073          	sret
    800060b6:	00000013          	nop
    800060ba:	00000013          	nop
    800060be:	0001                	nop

00000000800060c0 <timervec>:
    800060c0:	34051573          	csrrw	a0,mscratch,a0
    800060c4:	e10c                	sd	a1,0(a0)
    800060c6:	e510                	sd	a2,8(a0)
    800060c8:	e914                	sd	a3,16(a0)
    800060ca:	6d0c                	ld	a1,24(a0)
    800060cc:	7110                	ld	a2,32(a0)
    800060ce:	6194                	ld	a3,0(a1)
    800060d0:	96b2                	add	a3,a3,a2
    800060d2:	e194                	sd	a3,0(a1)
    800060d4:	4589                	li	a1,2
    800060d6:	14459073          	csrw	sip,a1
    800060da:	6914                	ld	a3,16(a0)
    800060dc:	6510                	ld	a2,8(a0)
    800060de:	610c                	ld	a1,0(a0)
    800060e0:	34051573          	csrrw	a0,mscratch,a0
    800060e4:	30200073          	mret
	...

00000000800060ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ea:	1141                	addi	sp,sp,-16
    800060ec:	e422                	sd	s0,8(sp)
    800060ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060f0:	0c0007b7          	lui	a5,0xc000
    800060f4:	4705                	li	a4,1
    800060f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060f8:	c3d8                	sw	a4,4(a5)
}
    800060fa:	6422                	ld	s0,8(sp)
    800060fc:	0141                	addi	sp,sp,16
    800060fe:	8082                	ret

0000000080006100 <plicinithart>:

void
plicinithart(void)
{
    80006100:	1141                	addi	sp,sp,-16
    80006102:	e406                	sd	ra,8(sp)
    80006104:	e022                	sd	s0,0(sp)
    80006106:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006108:	ffffb097          	auipc	ra,0xffffb
    8000610c:	7cc080e7          	jalr	1996(ra) # 800018d4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006110:	0085171b          	slliw	a4,a0,0x8
    80006114:	0c0027b7          	lui	a5,0xc002
    80006118:	97ba                	add	a5,a5,a4
    8000611a:	40200713          	li	a4,1026
    8000611e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006122:	00d5151b          	slliw	a0,a0,0xd
    80006126:	0c2017b7          	lui	a5,0xc201
    8000612a:	953e                	add	a0,a0,a5
    8000612c:	00052023          	sw	zero,0(a0)
}
    80006130:	60a2                	ld	ra,8(sp)
    80006132:	6402                	ld	s0,0(sp)
    80006134:	0141                	addi	sp,sp,16
    80006136:	8082                	ret

0000000080006138 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006138:	1141                	addi	sp,sp,-16
    8000613a:	e406                	sd	ra,8(sp)
    8000613c:	e022                	sd	s0,0(sp)
    8000613e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006140:	ffffb097          	auipc	ra,0xffffb
    80006144:	794080e7          	jalr	1940(ra) # 800018d4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006148:	00d5179b          	slliw	a5,a0,0xd
    8000614c:	0c201537          	lui	a0,0xc201
    80006150:	953e                	add	a0,a0,a5
  return irq;
}
    80006152:	4148                	lw	a0,4(a0)
    80006154:	60a2                	ld	ra,8(sp)
    80006156:	6402                	ld	s0,0(sp)
    80006158:	0141                	addi	sp,sp,16
    8000615a:	8082                	ret

000000008000615c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000615c:	1101                	addi	sp,sp,-32
    8000615e:	ec06                	sd	ra,24(sp)
    80006160:	e822                	sd	s0,16(sp)
    80006162:	e426                	sd	s1,8(sp)
    80006164:	1000                	addi	s0,sp,32
    80006166:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006168:	ffffb097          	auipc	ra,0xffffb
    8000616c:	76c080e7          	jalr	1900(ra) # 800018d4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006170:	00d5151b          	slliw	a0,a0,0xd
    80006174:	0c2017b7          	lui	a5,0xc201
    80006178:	97aa                	add	a5,a5,a0
    8000617a:	c3c4                	sw	s1,4(a5)
}
    8000617c:	60e2                	ld	ra,24(sp)
    8000617e:	6442                	ld	s0,16(sp)
    80006180:	64a2                	ld	s1,8(sp)
    80006182:	6105                	addi	sp,sp,32
    80006184:	8082                	ret

0000000080006186 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006186:	1141                	addi	sp,sp,-16
    80006188:	e406                	sd	ra,8(sp)
    8000618a:	e022                	sd	s0,0(sp)
    8000618c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000618e:	479d                	li	a5,7
    80006190:	06a7c963          	blt	a5,a0,80006202 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006194:	0001d797          	auipc	a5,0x1d
    80006198:	e6c78793          	addi	a5,a5,-404 # 80023000 <disk>
    8000619c:	00a78733          	add	a4,a5,a0
    800061a0:	6789                	lui	a5,0x2
    800061a2:	97ba                	add	a5,a5,a4
    800061a4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061a8:	e7ad                	bnez	a5,80006212 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061aa:	00451793          	slli	a5,a0,0x4
    800061ae:	0001f717          	auipc	a4,0x1f
    800061b2:	e5270713          	addi	a4,a4,-430 # 80025000 <disk+0x2000>
    800061b6:	6314                	ld	a3,0(a4)
    800061b8:	96be                	add	a3,a3,a5
    800061ba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061be:	6314                	ld	a3,0(a4)
    800061c0:	96be                	add	a3,a3,a5
    800061c2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061c6:	6314                	ld	a3,0(a4)
    800061c8:	96be                	add	a3,a3,a5
    800061ca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061ce:	6318                	ld	a4,0(a4)
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061d6:	0001d797          	auipc	a5,0x1d
    800061da:	e2a78793          	addi	a5,a5,-470 # 80023000 <disk>
    800061de:	97aa                	add	a5,a5,a0
    800061e0:	6509                	lui	a0,0x2
    800061e2:	953e                	add	a0,a0,a5
    800061e4:	4785                	li	a5,1
    800061e6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061ea:	0001f517          	auipc	a0,0x1f
    800061ee:	e2e50513          	addi	a0,a0,-466 # 80025018 <disk+0x2018>
    800061f2:	ffffc097          	auipc	ra,0xffffc
    800061f6:	228080e7          	jalr	552(ra) # 8000241a <wakeup>
}
    800061fa:	60a2                	ld	ra,8(sp)
    800061fc:	6402                	ld	s0,0(sp)
    800061fe:	0141                	addi	sp,sp,16
    80006200:	8082                	ret
    panic("free_desc 1");
    80006202:	00002517          	auipc	a0,0x2
    80006206:	57650513          	addi	a0,a0,1398 # 80008778 <syscalls+0x330>
    8000620a:	ffffa097          	auipc	ra,0xffffa
    8000620e:	334080e7          	jalr	820(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006212:	00002517          	auipc	a0,0x2
    80006216:	57650513          	addi	a0,a0,1398 # 80008788 <syscalls+0x340>
    8000621a:	ffffa097          	auipc	ra,0xffffa
    8000621e:	324080e7          	jalr	804(ra) # 8000053e <panic>

0000000080006222 <virtio_disk_init>:
{
    80006222:	1101                	addi	sp,sp,-32
    80006224:	ec06                	sd	ra,24(sp)
    80006226:	e822                	sd	s0,16(sp)
    80006228:	e426                	sd	s1,8(sp)
    8000622a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000622c:	00002597          	auipc	a1,0x2
    80006230:	56c58593          	addi	a1,a1,1388 # 80008798 <syscalls+0x350>
    80006234:	0001f517          	auipc	a0,0x1f
    80006238:	ef450513          	addi	a0,a0,-268 # 80025128 <disk+0x2128>
    8000623c:	ffffb097          	auipc	ra,0xffffb
    80006240:	918080e7          	jalr	-1768(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006244:	100017b7          	lui	a5,0x10001
    80006248:	4398                	lw	a4,0(a5)
    8000624a:	2701                	sext.w	a4,a4
    8000624c:	747277b7          	lui	a5,0x74727
    80006250:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006254:	0ef71163          	bne	a4,a5,80006336 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006258:	100017b7          	lui	a5,0x10001
    8000625c:	43dc                	lw	a5,4(a5)
    8000625e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006260:	4705                	li	a4,1
    80006262:	0ce79a63          	bne	a5,a4,80006336 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006266:	100017b7          	lui	a5,0x10001
    8000626a:	479c                	lw	a5,8(a5)
    8000626c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000626e:	4709                	li	a4,2
    80006270:	0ce79363          	bne	a5,a4,80006336 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006274:	100017b7          	lui	a5,0x10001
    80006278:	47d8                	lw	a4,12(a5)
    8000627a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000627c:	554d47b7          	lui	a5,0x554d4
    80006280:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006284:	0af71963          	bne	a4,a5,80006336 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006288:	100017b7          	lui	a5,0x10001
    8000628c:	4705                	li	a4,1
    8000628e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006290:	470d                	li	a4,3
    80006292:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006294:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006296:	c7ffe737          	lui	a4,0xc7ffe
    8000629a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000629e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062a0:	2701                	sext.w	a4,a4
    800062a2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a4:	472d                	li	a4,11
    800062a6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a8:	473d                	li	a4,15
    800062aa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062ac:	6705                	lui	a4,0x1
    800062ae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062b4:	5bdc                	lw	a5,52(a5)
    800062b6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062b8:	c7d9                	beqz	a5,80006346 <virtio_disk_init+0x124>
  if(max < NUM)
    800062ba:	471d                	li	a4,7
    800062bc:	08f77d63          	bgeu	a4,a5,80006356 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062c0:	100014b7          	lui	s1,0x10001
    800062c4:	47a1                	li	a5,8
    800062c6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062c8:	6609                	lui	a2,0x2
    800062ca:	4581                	li	a1,0
    800062cc:	0001d517          	auipc	a0,0x1d
    800062d0:	d3450513          	addi	a0,a0,-716 # 80023000 <disk>
    800062d4:	ffffb097          	auipc	ra,0xffffb
    800062d8:	a0c080e7          	jalr	-1524(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062dc:	0001d717          	auipc	a4,0x1d
    800062e0:	d2470713          	addi	a4,a4,-732 # 80023000 <disk>
    800062e4:	00c75793          	srli	a5,a4,0xc
    800062e8:	2781                	sext.w	a5,a5
    800062ea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062ec:	0001f797          	auipc	a5,0x1f
    800062f0:	d1478793          	addi	a5,a5,-748 # 80025000 <disk+0x2000>
    800062f4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062f6:	0001d717          	auipc	a4,0x1d
    800062fa:	d8a70713          	addi	a4,a4,-630 # 80023080 <disk+0x80>
    800062fe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006300:	0001e717          	auipc	a4,0x1e
    80006304:	d0070713          	addi	a4,a4,-768 # 80024000 <disk+0x1000>
    80006308:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000630a:	4705                	li	a4,1
    8000630c:	00e78c23          	sb	a4,24(a5)
    80006310:	00e78ca3          	sb	a4,25(a5)
    80006314:	00e78d23          	sb	a4,26(a5)
    80006318:	00e78da3          	sb	a4,27(a5)
    8000631c:	00e78e23          	sb	a4,28(a5)
    80006320:	00e78ea3          	sb	a4,29(a5)
    80006324:	00e78f23          	sb	a4,30(a5)
    80006328:	00e78fa3          	sb	a4,31(a5)
}
    8000632c:	60e2                	ld	ra,24(sp)
    8000632e:	6442                	ld	s0,16(sp)
    80006330:	64a2                	ld	s1,8(sp)
    80006332:	6105                	addi	sp,sp,32
    80006334:	8082                	ret
    panic("could not find virtio disk");
    80006336:	00002517          	auipc	a0,0x2
    8000633a:	47250513          	addi	a0,a0,1138 # 800087a8 <syscalls+0x360>
    8000633e:	ffffa097          	auipc	ra,0xffffa
    80006342:	200080e7          	jalr	512(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	48250513          	addi	a0,a0,1154 # 800087c8 <syscalls+0x380>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006356:	00002517          	auipc	a0,0x2
    8000635a:	49250513          	addi	a0,a0,1170 # 800087e8 <syscalls+0x3a0>
    8000635e:	ffffa097          	auipc	ra,0xffffa
    80006362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>

0000000080006366 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006366:	7159                	addi	sp,sp,-112
    80006368:	f486                	sd	ra,104(sp)
    8000636a:	f0a2                	sd	s0,96(sp)
    8000636c:	eca6                	sd	s1,88(sp)
    8000636e:	e8ca                	sd	s2,80(sp)
    80006370:	e4ce                	sd	s3,72(sp)
    80006372:	e0d2                	sd	s4,64(sp)
    80006374:	fc56                	sd	s5,56(sp)
    80006376:	f85a                	sd	s6,48(sp)
    80006378:	f45e                	sd	s7,40(sp)
    8000637a:	f062                	sd	s8,32(sp)
    8000637c:	ec66                	sd	s9,24(sp)
    8000637e:	e86a                	sd	s10,16(sp)
    80006380:	1880                	addi	s0,sp,112
    80006382:	892a                	mv	s2,a0
    80006384:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006386:	00c52c83          	lw	s9,12(a0)
    8000638a:	001c9c9b          	slliw	s9,s9,0x1
    8000638e:	1c82                	slli	s9,s9,0x20
    80006390:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006394:	0001f517          	auipc	a0,0x1f
    80006398:	d9450513          	addi	a0,a0,-620 # 80025128 <disk+0x2128>
    8000639c:	ffffb097          	auipc	ra,0xffffb
    800063a0:	848080e7          	jalr	-1976(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800063a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063a6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800063a8:	0001db97          	auipc	s7,0x1d
    800063ac:	c58b8b93          	addi	s7,s7,-936 # 80023000 <disk>
    800063b0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800063b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800063b4:	8a4e                	mv	s4,s3
    800063b6:	a051                	j	8000643a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800063b8:	00fb86b3          	add	a3,s7,a5
    800063bc:	96da                	add	a3,a3,s6
    800063be:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063c2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063c4:	0207c563          	bltz	a5,800063ee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063c8:	2485                	addiw	s1,s1,1
    800063ca:	0711                	addi	a4,a4,4
    800063cc:	25548063          	beq	s1,s5,8000660c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063d0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063d2:	0001f697          	auipc	a3,0x1f
    800063d6:	c4668693          	addi	a3,a3,-954 # 80025018 <disk+0x2018>
    800063da:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063dc:	0006c583          	lbu	a1,0(a3)
    800063e0:	fde1                	bnez	a1,800063b8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063e2:	2785                	addiw	a5,a5,1
    800063e4:	0685                	addi	a3,a3,1
    800063e6:	ff879be3          	bne	a5,s8,800063dc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063ea:	57fd                	li	a5,-1
    800063ec:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800063ee:	02905a63          	blez	s1,80006422 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063f2:	f9042503          	lw	a0,-112(s0)
    800063f6:	00000097          	auipc	ra,0x0
    800063fa:	d90080e7          	jalr	-624(ra) # 80006186 <free_desc>
      for(int j = 0; j < i; j++)
    800063fe:	4785                	li	a5,1
    80006400:	0297d163          	bge	a5,s1,80006422 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006404:	f9442503          	lw	a0,-108(s0)
    80006408:	00000097          	auipc	ra,0x0
    8000640c:	d7e080e7          	jalr	-642(ra) # 80006186 <free_desc>
      for(int j = 0; j < i; j++)
    80006410:	4789                	li	a5,2
    80006412:	0097d863          	bge	a5,s1,80006422 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006416:	f9842503          	lw	a0,-104(s0)
    8000641a:	00000097          	auipc	ra,0x0
    8000641e:	d6c080e7          	jalr	-660(ra) # 80006186 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006422:	0001f597          	auipc	a1,0x1f
    80006426:	d0658593          	addi	a1,a1,-762 # 80025128 <disk+0x2128>
    8000642a:	0001f517          	auipc	a0,0x1f
    8000642e:	bee50513          	addi	a0,a0,-1042 # 80025018 <disk+0x2018>
    80006432:	ffffc097          	auipc	ra,0xffffc
    80006436:	c76080e7          	jalr	-906(ra) # 800020a8 <sleep>
  for(int i = 0; i < 3; i++){
    8000643a:	f9040713          	addi	a4,s0,-112
    8000643e:	84ce                	mv	s1,s3
    80006440:	bf41                	j	800063d0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006442:	20058713          	addi	a4,a1,512
    80006446:	00471693          	slli	a3,a4,0x4
    8000644a:	0001d717          	auipc	a4,0x1d
    8000644e:	bb670713          	addi	a4,a4,-1098 # 80023000 <disk>
    80006452:	9736                	add	a4,a4,a3
    80006454:	4685                	li	a3,1
    80006456:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000645a:	20058713          	addi	a4,a1,512
    8000645e:	00471693          	slli	a3,a4,0x4
    80006462:	0001d717          	auipc	a4,0x1d
    80006466:	b9e70713          	addi	a4,a4,-1122 # 80023000 <disk>
    8000646a:	9736                	add	a4,a4,a3
    8000646c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006470:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006474:	7679                	lui	a2,0xffffe
    80006476:	963e                	add	a2,a2,a5
    80006478:	0001f697          	auipc	a3,0x1f
    8000647c:	b8868693          	addi	a3,a3,-1144 # 80025000 <disk+0x2000>
    80006480:	6298                	ld	a4,0(a3)
    80006482:	9732                	add	a4,a4,a2
    80006484:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006486:	6298                	ld	a4,0(a3)
    80006488:	9732                	add	a4,a4,a2
    8000648a:	4541                	li	a0,16
    8000648c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000648e:	6298                	ld	a4,0(a3)
    80006490:	9732                	add	a4,a4,a2
    80006492:	4505                	li	a0,1
    80006494:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006498:	f9442703          	lw	a4,-108(s0)
    8000649c:	6288                	ld	a0,0(a3)
    8000649e:	962a                	add	a2,a2,a0
    800064a0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064a4:	0712                	slli	a4,a4,0x4
    800064a6:	6290                	ld	a2,0(a3)
    800064a8:	963a                	add	a2,a2,a4
    800064aa:	05890513          	addi	a0,s2,88
    800064ae:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800064b0:	6294                	ld	a3,0(a3)
    800064b2:	96ba                	add	a3,a3,a4
    800064b4:	40000613          	li	a2,1024
    800064b8:	c690                	sw	a2,8(a3)
  if(write)
    800064ba:	140d0063          	beqz	s10,800065fa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064be:	0001f697          	auipc	a3,0x1f
    800064c2:	b426b683          	ld	a3,-1214(a3) # 80025000 <disk+0x2000>
    800064c6:	96ba                	add	a3,a3,a4
    800064c8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064cc:	0001d817          	auipc	a6,0x1d
    800064d0:	b3480813          	addi	a6,a6,-1228 # 80023000 <disk>
    800064d4:	0001f517          	auipc	a0,0x1f
    800064d8:	b2c50513          	addi	a0,a0,-1236 # 80025000 <disk+0x2000>
    800064dc:	6114                	ld	a3,0(a0)
    800064de:	96ba                	add	a3,a3,a4
    800064e0:	00c6d603          	lhu	a2,12(a3)
    800064e4:	00166613          	ori	a2,a2,1
    800064e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064ec:	f9842683          	lw	a3,-104(s0)
    800064f0:	6110                	ld	a2,0(a0)
    800064f2:	9732                	add	a4,a4,a2
    800064f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064f8:	20058613          	addi	a2,a1,512
    800064fc:	0612                	slli	a2,a2,0x4
    800064fe:	9642                	add	a2,a2,a6
    80006500:	577d                	li	a4,-1
    80006502:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006506:	00469713          	slli	a4,a3,0x4
    8000650a:	6114                	ld	a3,0(a0)
    8000650c:	96ba                	add	a3,a3,a4
    8000650e:	03078793          	addi	a5,a5,48
    80006512:	97c2                	add	a5,a5,a6
    80006514:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006516:	611c                	ld	a5,0(a0)
    80006518:	97ba                	add	a5,a5,a4
    8000651a:	4685                	li	a3,1
    8000651c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000651e:	611c                	ld	a5,0(a0)
    80006520:	97ba                	add	a5,a5,a4
    80006522:	4809                	li	a6,2
    80006524:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006528:	611c                	ld	a5,0(a0)
    8000652a:	973e                	add	a4,a4,a5
    8000652c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006530:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006534:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006538:	6518                	ld	a4,8(a0)
    8000653a:	00275783          	lhu	a5,2(a4)
    8000653e:	8b9d                	andi	a5,a5,7
    80006540:	0786                	slli	a5,a5,0x1
    80006542:	97ba                	add	a5,a5,a4
    80006544:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006548:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000654c:	6518                	ld	a4,8(a0)
    8000654e:	00275783          	lhu	a5,2(a4)
    80006552:	2785                	addiw	a5,a5,1
    80006554:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006558:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000655c:	100017b7          	lui	a5,0x10001
    80006560:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006564:	00492703          	lw	a4,4(s2)
    80006568:	4785                	li	a5,1
    8000656a:	02f71163          	bne	a4,a5,8000658c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000656e:	0001f997          	auipc	s3,0x1f
    80006572:	bba98993          	addi	s3,s3,-1094 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006576:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006578:	85ce                	mv	a1,s3
    8000657a:	854a                	mv	a0,s2
    8000657c:	ffffc097          	auipc	ra,0xffffc
    80006580:	b2c080e7          	jalr	-1236(ra) # 800020a8 <sleep>
  while(b->disk == 1) {
    80006584:	00492783          	lw	a5,4(s2)
    80006588:	fe9788e3          	beq	a5,s1,80006578 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000658c:	f9042903          	lw	s2,-112(s0)
    80006590:	20090793          	addi	a5,s2,512
    80006594:	00479713          	slli	a4,a5,0x4
    80006598:	0001d797          	auipc	a5,0x1d
    8000659c:	a6878793          	addi	a5,a5,-1432 # 80023000 <disk>
    800065a0:	97ba                	add	a5,a5,a4
    800065a2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065a6:	0001f997          	auipc	s3,0x1f
    800065aa:	a5a98993          	addi	s3,s3,-1446 # 80025000 <disk+0x2000>
    800065ae:	00491713          	slli	a4,s2,0x4
    800065b2:	0009b783          	ld	a5,0(s3)
    800065b6:	97ba                	add	a5,a5,a4
    800065b8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065bc:	854a                	mv	a0,s2
    800065be:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065c2:	00000097          	auipc	ra,0x0
    800065c6:	bc4080e7          	jalr	-1084(ra) # 80006186 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065ca:	8885                	andi	s1,s1,1
    800065cc:	f0ed                	bnez	s1,800065ae <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065ce:	0001f517          	auipc	a0,0x1f
    800065d2:	b5a50513          	addi	a0,a0,-1190 # 80025128 <disk+0x2128>
    800065d6:	ffffa097          	auipc	ra,0xffffa
    800065da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
}
    800065de:	70a6                	ld	ra,104(sp)
    800065e0:	7406                	ld	s0,96(sp)
    800065e2:	64e6                	ld	s1,88(sp)
    800065e4:	6946                	ld	s2,80(sp)
    800065e6:	69a6                	ld	s3,72(sp)
    800065e8:	6a06                	ld	s4,64(sp)
    800065ea:	7ae2                	ld	s5,56(sp)
    800065ec:	7b42                	ld	s6,48(sp)
    800065ee:	7ba2                	ld	s7,40(sp)
    800065f0:	7c02                	ld	s8,32(sp)
    800065f2:	6ce2                	ld	s9,24(sp)
    800065f4:	6d42                	ld	s10,16(sp)
    800065f6:	6165                	addi	sp,sp,112
    800065f8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065fa:	0001f697          	auipc	a3,0x1f
    800065fe:	a066b683          	ld	a3,-1530(a3) # 80025000 <disk+0x2000>
    80006602:	96ba                	add	a3,a3,a4
    80006604:	4609                	li	a2,2
    80006606:	00c69623          	sh	a2,12(a3)
    8000660a:	b5c9                	j	800064cc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000660c:	f9042583          	lw	a1,-112(s0)
    80006610:	20058793          	addi	a5,a1,512
    80006614:	0792                	slli	a5,a5,0x4
    80006616:	0001d517          	auipc	a0,0x1d
    8000661a:	a9250513          	addi	a0,a0,-1390 # 800230a8 <disk+0xa8>
    8000661e:	953e                	add	a0,a0,a5
  if(write)
    80006620:	e20d11e3          	bnez	s10,80006442 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006624:	20058713          	addi	a4,a1,512
    80006628:	00471693          	slli	a3,a4,0x4
    8000662c:	0001d717          	auipc	a4,0x1d
    80006630:	9d470713          	addi	a4,a4,-1580 # 80023000 <disk>
    80006634:	9736                	add	a4,a4,a3
    80006636:	0a072423          	sw	zero,168(a4)
    8000663a:	b505                	j	8000645a <virtio_disk_rw+0xf4>

000000008000663c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000663c:	1101                	addi	sp,sp,-32
    8000663e:	ec06                	sd	ra,24(sp)
    80006640:	e822                	sd	s0,16(sp)
    80006642:	e426                	sd	s1,8(sp)
    80006644:	e04a                	sd	s2,0(sp)
    80006646:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006648:	0001f517          	auipc	a0,0x1f
    8000664c:	ae050513          	addi	a0,a0,-1312 # 80025128 <disk+0x2128>
    80006650:	ffffa097          	auipc	ra,0xffffa
    80006654:	594080e7          	jalr	1428(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006658:	10001737          	lui	a4,0x10001
    8000665c:	533c                	lw	a5,96(a4)
    8000665e:	8b8d                	andi	a5,a5,3
    80006660:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006662:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006666:	0001f797          	auipc	a5,0x1f
    8000666a:	99a78793          	addi	a5,a5,-1638 # 80025000 <disk+0x2000>
    8000666e:	6b94                	ld	a3,16(a5)
    80006670:	0207d703          	lhu	a4,32(a5)
    80006674:	0026d783          	lhu	a5,2(a3)
    80006678:	06f70163          	beq	a4,a5,800066da <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000667c:	0001d917          	auipc	s2,0x1d
    80006680:	98490913          	addi	s2,s2,-1660 # 80023000 <disk>
    80006684:	0001f497          	auipc	s1,0x1f
    80006688:	97c48493          	addi	s1,s1,-1668 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000668c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006690:	6898                	ld	a4,16(s1)
    80006692:	0204d783          	lhu	a5,32(s1)
    80006696:	8b9d                	andi	a5,a5,7
    80006698:	078e                	slli	a5,a5,0x3
    8000669a:	97ba                	add	a5,a5,a4
    8000669c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000669e:	20078713          	addi	a4,a5,512
    800066a2:	0712                	slli	a4,a4,0x4
    800066a4:	974a                	add	a4,a4,s2
    800066a6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066aa:	e731                	bnez	a4,800066f6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066ac:	20078793          	addi	a5,a5,512
    800066b0:	0792                	slli	a5,a5,0x4
    800066b2:	97ca                	add	a5,a5,s2
    800066b4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066b6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066ba:	ffffc097          	auipc	ra,0xffffc
    800066be:	d60080e7          	jalr	-672(ra) # 8000241a <wakeup>

    disk.used_idx += 1;
    800066c2:	0204d783          	lhu	a5,32(s1)
    800066c6:	2785                	addiw	a5,a5,1
    800066c8:	17c2                	slli	a5,a5,0x30
    800066ca:	93c1                	srli	a5,a5,0x30
    800066cc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066d0:	6898                	ld	a4,16(s1)
    800066d2:	00275703          	lhu	a4,2(a4)
    800066d6:	faf71be3          	bne	a4,a5,8000668c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066da:	0001f517          	auipc	a0,0x1f
    800066de:	a4e50513          	addi	a0,a0,-1458 # 80025128 <disk+0x2128>
    800066e2:	ffffa097          	auipc	ra,0xffffa
    800066e6:	5b6080e7          	jalr	1462(ra) # 80000c98 <release>
}
    800066ea:	60e2                	ld	ra,24(sp)
    800066ec:	6442                	ld	s0,16(sp)
    800066ee:	64a2                	ld	s1,8(sp)
    800066f0:	6902                	ld	s2,0(sp)
    800066f2:	6105                	addi	sp,sp,32
    800066f4:	8082                	ret
      panic("virtio_disk_intr status");
    800066f6:	00002517          	auipc	a0,0x2
    800066fa:	11250513          	addi	a0,a0,274 # 80008808 <syscalls+0x3c0>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	e40080e7          	jalr	-448(ra) # 8000053e <panic>

0000000080006706 <cas>:
    80006706:	100522af          	lr.w	t0,(a0)
    8000670a:	00b29563          	bne	t0,a1,80006714 <fail>
    8000670e:	18c5252f          	sc.w	a0,a2,(a0)
    80006712:	8082                	ret

0000000080006714 <fail>:
    80006714:	4505                	li	a0,1
    80006716:	8082                	ret
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
