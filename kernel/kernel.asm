
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
    80000ed8:	c80080e7          	jalr	-896(ra) # 80002b54 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	224080e7          	jalr	548(ra) # 80006100 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	b28080e7          	jalr	-1240(ra) # 80002a0c <scheduler>
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
    80000f50:	be0080e7          	jalr	-1056(ra) # 80002b2c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c00080e7          	jalr	-1024(ra) # 80002b54 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	18e080e7          	jalr	398(ra) # 800060ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	19c080e7          	jalr	412(ra) # 80006100 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	374080e7          	jalr	884(ra) # 800032e0 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a04080e7          	jalr	-1532(ra) # 80003978 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9ae080e7          	jalr	-1618(ra) # 8000492a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	29e080e7          	jalr	670(ra) # 80006222 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	87a080e7          	jalr	-1926(ra) # 80002806 <userinit>
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
    8000196e:	202080e7          	jalr	514(ra) # 80002b6c <usertrapret>
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
    80001988:	f74080e7          	jalr	-140(ra) # 800038f8 <fsinit>
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
    80001bb0:	f16080e7          	jalr	-234(ra) # 80002ac2 <swtch>
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
    80002432:	1080                	addi	s0,sp,96
    80002434:	8a2a                	mv	s4,a0
  acquire(&lock_sleeping_list);
    80002436:	0000f517          	auipc	a0,0xf
    8000243a:	3b250513          	addi	a0,a0,946 # 800117e8 <lock_sleeping_list>
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	7a6080e7          	jalr	1958(ra) # 80000be4 <acquire>
  if(sleeping_head != -1){
    80002446:	00006917          	auipc	s2,0x6
    8000244a:	3e292903          	lw	s2,994(s2) # 80008828 <sleeping_head>
    8000244e:	57fd                	li	a5,-1
    80002450:	0af90163          	beq	s2,a5,800024f2 <wakeup+0xd8>
    p = &proc[sleeping_head];
    80002454:	18800493          	li	s1,392
    80002458:	029904b3          	mul	s1,s2,s1
    8000245c:	0000f797          	auipc	a5,0xf
    80002460:	3bc78793          	addi	a5,a5,956 # 80011818 <proc>
    80002464:	94be                	add	s1,s1,a5
    release(&lock_sleeping_list);
    80002466:	0000f517          	auipc	a0,0xf
    8000246a:	38250513          	addi	a0,a0,898 # 800117e8 <lock_sleeping_list>
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	82a080e7          	jalr	-2006(ra) # 80000c98 <release>
      int next_proc = p->next_proc_index;
    80002476:	8926                	mv	s2,s1
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    80002478:	0000fb97          	auipc	s7,0xf
    8000247c:	370b8b93          	addi	s7,s7,880 # 800117e8 <lock_sleeping_list>
    80002480:	00006b17          	auipc	s6,0x6
    80002484:	3a8b0b13          	addi	s6,s6,936 # 80008828 <sleeping_head>
              p->state = RUNNABLE;
    80002488:	4c8d                	li	s9,3
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    8000248a:	0000fc17          	auipc	s8,0xf
    8000248e:	e16c0c13          	addi	s8,s8,-490 # 800112a0 <cpus>
    } while(curr_proc != -1);
    80002492:	5afd                	li	s5,-1
    80002494:	a801                	j	800024a4 <wakeup+0x8a>
      release(&p->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	800080e7          	jalr	-2048(ra) # 80000c98 <release>
    } while(curr_proc != -1);
    800024a0:	07598163          	beq	s3,s5,80002502 <wakeup+0xe8>
      int next_proc = p->next_proc_index;
    800024a4:	03892983          	lw	s3,56(s2)
      acquire(&p->lock);
    800024a8:	8526                	mv	a0,s1
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	73a080e7          	jalr	1850(ra) # 80000be4 <acquire>
      if (p->chan == chan) {
    800024b2:	02093783          	ld	a5,32(s2)
    800024b6:	ff4790e3          	bne	a5,s4,80002496 <wakeup+0x7c>
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    800024ba:	865e                	mv	a2,s7
    800024bc:	85a6                	mv	a1,s1
    800024be:	855a                	mv	a0,s6
    800024c0:	00000097          	auipc	ra,0x0
    800024c4:	c66080e7          	jalr	-922(ra) # 80002126 <remove_from_list>
    800024c8:	d579                	beqz	a0,80002496 <wakeup+0x7c>
              p->state = RUNNABLE;
    800024ca:	01992c23          	sw	s9,24(s2)
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    800024ce:	03492783          	lw	a5,52(s2)
    800024d2:	00279513          	slli	a0,a5,0x2
    800024d6:	953e                	add	a0,a0,a5
    800024d8:	0516                	slli	a0,a0,0x5
    800024da:	08850613          	addi	a2,a0,136
    800024de:	08050513          	addi	a0,a0,128
    800024e2:	9662                	add	a2,a2,s8
    800024e4:	85a6                	mv	a1,s1
    800024e6:	9562                	add	a0,a0,s8
    800024e8:	00000097          	auipc	ra,0x0
    800024ec:	934080e7          	jalr	-1740(ra) # 80001e1c <add_to_list>
    800024f0:	b75d                	j	80002496 <wakeup+0x7c>
    release(&lock_sleeping_list);
    800024f2:	0000f517          	auipc	a0,0xf
    800024f6:	2f650513          	addi	a0,a0,758 # 800117e8 <lock_sleeping_list>
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	79e080e7          	jalr	1950(ra) # 80000c98 <release>
}
    80002502:	60e6                	ld	ra,88(sp)
    80002504:	6446                	ld	s0,80(sp)
    80002506:	64a6                	ld	s1,72(sp)
    80002508:	6906                	ld	s2,64(sp)
    8000250a:	79e2                	ld	s3,56(sp)
    8000250c:	7a42                	ld	s4,48(sp)
    8000250e:	7aa2                	ld	s5,40(sp)
    80002510:	7b02                	ld	s6,32(sp)
    80002512:	6be2                	ld	s7,24(sp)
    80002514:	6c42                	ld	s8,16(sp)
    80002516:	6ca2                	ld	s9,8(sp)
    80002518:	6125                	addi	sp,sp,96
    8000251a:	8082                	ret

000000008000251c <reparent>:
{
    8000251c:	7179                	addi	sp,sp,-48
    8000251e:	f406                	sd	ra,40(sp)
    80002520:	f022                	sd	s0,32(sp)
    80002522:	ec26                	sd	s1,24(sp)
    80002524:	e84a                	sd	s2,16(sp)
    80002526:	e44e                	sd	s3,8(sp)
    80002528:	e052                	sd	s4,0(sp)
    8000252a:	1800                	addi	s0,sp,48
    8000252c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	2ea48493          	addi	s1,s1,746 # 80011818 <proc>
      pp->parent = initproc;
    80002536:	00007a17          	auipc	s4,0x7
    8000253a:	af2a0a13          	addi	s4,s4,-1294 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000253e:	00015997          	auipc	s3,0x15
    80002542:	4da98993          	addi	s3,s3,1242 # 80017a18 <tickslock>
    80002546:	a029                	j	80002550 <reparent+0x34>
    80002548:	18848493          	addi	s1,s1,392
    8000254c:	01348d63          	beq	s1,s3,80002566 <reparent+0x4a>
    if(pp->parent == p){
    80002550:	6cbc                	ld	a5,88(s1)
    80002552:	ff279be3          	bne	a5,s2,80002548 <reparent+0x2c>
      pp->parent = initproc;
    80002556:	000a3503          	ld	a0,0(s4)
    8000255a:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    8000255c:	00000097          	auipc	ra,0x0
    80002560:	ebe080e7          	jalr	-322(ra) # 8000241a <wakeup>
    80002564:	b7d5                	j	80002548 <reparent+0x2c>
}
    80002566:	70a2                	ld	ra,40(sp)
    80002568:	7402                	ld	s0,32(sp)
    8000256a:	64e2                	ld	s1,24(sp)
    8000256c:	6942                	ld	s2,16(sp)
    8000256e:	69a2                	ld	s3,8(sp)
    80002570:	6a02                	ld	s4,0(sp)
    80002572:	6145                	addi	sp,sp,48
    80002574:	8082                	ret

0000000080002576 <exit>:
{
    80002576:	7179                	addi	sp,sp,-48
    80002578:	f406                	sd	ra,40(sp)
    8000257a:	f022                	sd	s0,32(sp)
    8000257c:	ec26                	sd	s1,24(sp)
    8000257e:	e84a                	sd	s2,16(sp)
    80002580:	e44e                	sd	s3,8(sp)
    80002582:	e052                	sd	s4,0(sp)
    80002584:	1800                	addi	s0,sp,48
    80002586:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	380080e7          	jalr	896(ra) # 80001908 <myproc>
    80002590:	89aa                	mv	s3,a0
  if(p == initproc)
    80002592:	00007797          	auipc	a5,0x7
    80002596:	a967b783          	ld	a5,-1386(a5) # 80009028 <initproc>
    8000259a:	0f050493          	addi	s1,a0,240
    8000259e:	17050913          	addi	s2,a0,368
    800025a2:	02a79363          	bne	a5,a0,800025c8 <exit+0x52>
    panic("init exiting");
    800025a6:	00006517          	auipc	a0,0x6
    800025aa:	cba50513          	addi	a0,a0,-838 # 80008260 <digits+0x220>
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
      fileclose(f);
    800025b6:	00002097          	auipc	ra,0x2
    800025ba:	458080e7          	jalr	1112(ra) # 80004a0e <fileclose>
      p->ofile[fd] = 0;
    800025be:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025c2:	04a1                	addi	s1,s1,8
    800025c4:	01248563          	beq	s1,s2,800025ce <exit+0x58>
    if(p->ofile[fd]){
    800025c8:	6088                	ld	a0,0(s1)
    800025ca:	f575                	bnez	a0,800025b6 <exit+0x40>
    800025cc:	bfdd                	j	800025c2 <exit+0x4c>
  begin_op();
    800025ce:	00002097          	auipc	ra,0x2
    800025d2:	f74080e7          	jalr	-140(ra) # 80004542 <begin_op>
  iput(p->cwd);
    800025d6:	1709b503          	ld	a0,368(s3)
    800025da:	00001097          	auipc	ra,0x1
    800025de:	750080e7          	jalr	1872(ra) # 80003d2a <iput>
  end_op();
    800025e2:	00002097          	auipc	ra,0x2
    800025e6:	fe0080e7          	jalr	-32(ra) # 800045c2 <end_op>
  p->cwd = 0;
    800025ea:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    800025ee:	0000f497          	auipc	s1,0xf
    800025f2:	1ca48493          	addi	s1,s1,458 # 800117b8 <wait_lock>
    800025f6:	8526                	mv	a0,s1
    800025f8:	ffffe097          	auipc	ra,0xffffe
    800025fc:	5ec080e7          	jalr	1516(ra) # 80000be4 <acquire>
  reparent(p);
    80002600:	854e                	mv	a0,s3
    80002602:	00000097          	auipc	ra,0x0
    80002606:	f1a080e7          	jalr	-230(ra) # 8000251c <reparent>
  wakeup(p->parent);
    8000260a:	0589b503          	ld	a0,88(s3)
    8000260e:	00000097          	auipc	ra,0x0
    80002612:	e0c080e7          	jalr	-500(ra) # 8000241a <wakeup>
  acquire(&p->lock);
    80002616:	854e                	mv	a0,s3
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	5cc080e7          	jalr	1484(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002620:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002624:	4795                	li	a5,5
    80002626:	00f9ac23          	sw	a5,24(s3)
  add_to_list(&zombie_head, p, &lock_zombie_list);
    8000262a:	0000f617          	auipc	a2,0xf
    8000262e:	1d660613          	addi	a2,a2,470 # 80011800 <lock_zombie_list>
    80002632:	85ce                	mv	a1,s3
    80002634:	00006517          	auipc	a0,0x6
    80002638:	1f050513          	addi	a0,a0,496 # 80008824 <zombie_head>
    8000263c:	fffff097          	auipc	ra,0xfffff
    80002640:	7e0080e7          	jalr	2016(ra) # 80001e1c <add_to_list>
  release(&wait_lock);
    80002644:	8526                	mv	a0,s1
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
  sched();
    8000264e:	fffff097          	auipc	ra,0xfffff
    80002652:	4da080e7          	jalr	1242(ra) # 80001b28 <sched>
  panic("zombie exit");
    80002656:	00006517          	auipc	a0,0x6
    8000265a:	c1a50513          	addi	a0,a0,-998 # 80008270 <digits+0x230>
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>

0000000080002666 <remove_first>:

int remove_first(int* curr_proc_index, struct spinlock* lock) {
    80002666:	7139                	addi	sp,sp,-64
    80002668:	fc06                	sd	ra,56(sp)
    8000266a:	f822                	sd	s0,48(sp)
    8000266c:	f426                	sd	s1,40(sp)
    8000266e:	f04a                	sd	s2,32(sp)
    80002670:	ec4e                	sd	s3,24(sp)
    80002672:	e852                	sd	s4,16(sp)
    80002674:	e456                	sd	s5,8(sp)
    80002676:	0080                	addi	s0,sp,64
    80002678:	8aaa                	mv	s5,a0
    8000267a:	89ae                	mv	s3,a1
    acquire(lock);
    8000267c:	852e                	mv	a0,a1
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	566080e7          	jalr	1382(ra) # 80000be4 <acquire>
    
    if (*curr_proc_index != -1){
    80002686:	000aa483          	lw	s1,0(s5)
    8000268a:	57fd                	li	a5,-1
    8000268c:	04f48d63          	beq	s1,a5,800026e6 <remove_first+0x80>
      int index = *curr_proc_index;
      struct proc *p = &proc[index];
      acquire(&p->proc_lock);
    80002690:	18800793          	li	a5,392
    80002694:	02f484b3          	mul	s1,s1,a5
    80002698:	04048a13          	addi	s4,s1,64
    8000269c:	0000f917          	auipc	s2,0xf
    800026a0:	17c90913          	addi	s2,s2,380 # 80011818 <proc>
    800026a4:	9a4a                	add	s4,s4,s2
    800026a6:	8552                	mv	a0,s4
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	53c080e7          	jalr	1340(ra) # 80000be4 <acquire>
      
      *curr_proc_index = p->next_proc_index;
    800026b0:	94ca                	add	s1,s1,s2
    800026b2:	5c9c                	lw	a5,56(s1)
    800026b4:	00faa023          	sw	a5,0(s5)
      p->next_proc_index = -1;
    800026b8:	57fd                	li	a5,-1
    800026ba:	dc9c                	sw	a5,56(s1)
      int output_proc = p->proc_index;
    800026bc:	5cc4                	lw	s1,60(s1)

      release(&p->proc_lock);
    800026be:	8552                	mv	a0,s4
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	5d8080e7          	jalr	1496(ra) # 80000c98 <release>
      release(lock);
    800026c8:	854e                	mv	a0,s3
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	5ce080e7          	jalr	1486(ra) # 80000c98 <release>
    else{

      release(lock);
      return -1;
    }
    800026d2:	8526                	mv	a0,s1
    800026d4:	70e2                	ld	ra,56(sp)
    800026d6:	7442                	ld	s0,48(sp)
    800026d8:	74a2                	ld	s1,40(sp)
    800026da:	7902                	ld	s2,32(sp)
    800026dc:	69e2                	ld	s3,24(sp)
    800026de:	6a42                	ld	s4,16(sp)
    800026e0:	6aa2                	ld	s5,8(sp)
    800026e2:	6121                	addi	sp,sp,64
    800026e4:	8082                	ret
      release(lock);
    800026e6:	854e                	mv	a0,s3
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	5b0080e7          	jalr	1456(ra) # 80000c98 <release>
      return -1;
    800026f0:	b7cd                	j	800026d2 <remove_first+0x6c>

00000000800026f2 <allocproc>:
{
    800026f2:	7179                	addi	sp,sp,-48
    800026f4:	f406                	sd	ra,40(sp)
    800026f6:	f022                	sd	s0,32(sp)
    800026f8:	ec26                	sd	s1,24(sp)
    800026fa:	e84a                	sd	s2,16(sp)
    800026fc:	e44e                	sd	s3,8(sp)
    800026fe:	e052                	sd	s4,0(sp)
    80002700:	1800                	addi	s0,sp,48
    if(unused_head == -1){
    80002702:	00006917          	auipc	s2,0x6
    80002706:	12a92903          	lw	s2,298(s2) # 8000882c <unused_head>
    8000270a:	57fd                	li	a5,-1
    8000270c:	0ef90b63          	beq	s2,a5,80002802 <allocproc+0x110>
    p=&proc[unused_head];
    80002710:	18800993          	li	s3,392
    80002714:	033909b3          	mul	s3,s2,s3
    80002718:	0000f497          	auipc	s1,0xf
    8000271c:	10048493          	addi	s1,s1,256 # 80011818 <proc>
    80002720:	94ce                	add	s1,s1,s3
    acquire(&p->lock);
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	4c0080e7          	jalr	1216(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    8000272c:	fffff097          	auipc	ra,0xfffff
    80002730:	262080e7          	jalr	610(ra) # 8000198e <allocpid>
    80002734:	d888                	sw	a0,48(s1)
  remove_first(&unused_head, &lock_unused_list); //different from the origin
    80002736:	0000f597          	auipc	a1,0xf
    8000273a:	09a58593          	addi	a1,a1,154 # 800117d0 <lock_unused_list>
    8000273e:	00006517          	auipc	a0,0x6
    80002742:	0ee50513          	addi	a0,a0,238 # 8000882c <unused_head>
    80002746:	00000097          	auipc	ra,0x0
    8000274a:	f20080e7          	jalr	-224(ra) # 80002666 <remove_first>
  p->state = USED;
    8000274e:	4785                	li	a5,1
    80002750:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	3a2080e7          	jalr	930(ra) # 80000af4 <kalloc>
    8000275a:	8a2a                	mv	s4,a0
    8000275c:	fca8                	sd	a0,120(s1)
    8000275e:	c935                	beqz	a0,800027d2 <allocproc+0xe0>
  p->pagetable = proc_pagetable(p);
    80002760:	8526                	mv	a0,s1
    80002762:	fffff097          	auipc	ra,0xfffff
    80002766:	264080e7          	jalr	612(ra) # 800019c6 <proc_pagetable>
    8000276a:	8a2a                	mv	s4,a0
    8000276c:	18800793          	li	a5,392
    80002770:	02f90733          	mul	a4,s2,a5
    80002774:	0000f797          	auipc	a5,0xf
    80002778:	0a478793          	addi	a5,a5,164 # 80011818 <proc>
    8000277c:	97ba                	add	a5,a5,a4
    8000277e:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    80002780:	c52d                	beqz	a0,800027ea <allocproc+0xf8>
  memset(&p->context, 0, sizeof(p->context));
    80002782:	08098513          	addi	a0,s3,128
    80002786:	0000fa17          	auipc	s4,0xf
    8000278a:	092a0a13          	addi	s4,s4,146 # 80011818 <proc>
    8000278e:	07000613          	li	a2,112
    80002792:	4581                	li	a1,0
    80002794:	9552                	add	a0,a0,s4
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	54a080e7          	jalr	1354(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000279e:	18800793          	li	a5,392
    800027a2:	02f90933          	mul	s2,s2,a5
    800027a6:	9952                	add	s2,s2,s4
    800027a8:	fffff797          	auipc	a5,0xfffff
    800027ac:	1a078793          	addi	a5,a5,416 # 80001948 <forkret>
    800027b0:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    800027b4:	06093783          	ld	a5,96(s2)
    800027b8:	6705                	lui	a4,0x1
    800027ba:	97ba                	add	a5,a5,a4
    800027bc:	08f93423          	sd	a5,136(s2)
}
    800027c0:	8526                	mv	a0,s1
    800027c2:	70a2                	ld	ra,40(sp)
    800027c4:	7402                	ld	s0,32(sp)
    800027c6:	64e2                	ld	s1,24(sp)
    800027c8:	6942                	ld	s2,16(sp)
    800027ca:	69a2                	ld	s3,8(sp)
    800027cc:	6a02                	ld	s4,0(sp)
    800027ce:	6145                	addi	sp,sp,48
    800027d0:	8082                	ret
    freeproc(p);
    800027d2:	8526                	mv	a0,s1
    800027d4:	00000097          	auipc	ra,0x0
    800027d8:	a92080e7          	jalr	-1390(ra) # 80002266 <freeproc>
    release(&p->lock);
    800027dc:	8526                	mv	a0,s1
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	4ba080e7          	jalr	1210(ra) # 80000c98 <release>
    return 0;
    800027e6:	84d2                	mv	s1,s4
    800027e8:	bfe1                	j	800027c0 <allocproc+0xce>
    freeproc(p);
    800027ea:	8526                	mv	a0,s1
    800027ec:	00000097          	auipc	ra,0x0
    800027f0:	a7a080e7          	jalr	-1414(ra) # 80002266 <freeproc>
    release(&p->lock);
    800027f4:	8526                	mv	a0,s1
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	4a2080e7          	jalr	1186(ra) # 80000c98 <release>
    return 0;
    800027fe:	84d2                	mv	s1,s4
    80002800:	b7c1                	j	800027c0 <allocproc+0xce>
      return 0;
    80002802:	4481                	li	s1,0
    80002804:	bf75                	j	800027c0 <allocproc+0xce>

0000000080002806 <userinit>:
{
    80002806:	1101                	addi	sp,sp,-32
    80002808:	ec06                	sd	ra,24(sp)
    8000280a:	e822                	sd	s0,16(sp)
    8000280c:	e426                	sd	s1,8(sp)
    8000280e:	1000                	addi	s0,sp,32
  p = allocproc();
    80002810:	00000097          	auipc	ra,0x0
    80002814:	ee2080e7          	jalr	-286(ra) # 800026f2 <allocproc>
    80002818:	84aa                	mv	s1,a0
  initproc = p;
    8000281a:	00007797          	auipc	a5,0x7
    8000281e:	80a7b723          	sd	a0,-2034(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002822:	03400613          	li	a2,52
    80002826:	00006597          	auipc	a1,0x6
    8000282a:	01a58593          	addi	a1,a1,26 # 80008840 <initcode>
    8000282e:	7928                	ld	a0,112(a0)
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	b38080e7          	jalr	-1224(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002838:	6785                	lui	a5,0x1
    8000283a:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    8000283c:	7cb8                	ld	a4,120(s1)
    8000283e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002842:	7cb8                	ld	a4,120(s1)
    80002844:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002846:	4641                	li	a2,16
    80002848:	00006597          	auipc	a1,0x6
    8000284c:	a3858593          	addi	a1,a1,-1480 # 80008280 <digits+0x240>
    80002850:	17848513          	addi	a0,s1,376
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	5de080e7          	jalr	1502(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    8000285c:	00006517          	auipc	a0,0x6
    80002860:	a3450513          	addi	a0,a0,-1484 # 80008290 <digits+0x250>
    80002864:	00002097          	auipc	ra,0x2
    80002868:	ac2080e7          	jalr	-1342(ra) # 80004326 <namei>
    8000286c:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80002870:	478d                	li	a5,3
    80002872:	cc9c                	sw	a5,24(s1)
  add_to_list(&cpus[0].runnable_head, p, &cpus[0].lock_runnable_list);
    80002874:	0000f617          	auipc	a2,0xf
    80002878:	ab460613          	addi	a2,a2,-1356 # 80011328 <cpus+0x88>
    8000287c:	85a6                	mv	a1,s1
    8000287e:	0000f517          	auipc	a0,0xf
    80002882:	aa250513          	addi	a0,a0,-1374 # 80011320 <cpus+0x80>
    80002886:	fffff097          	auipc	ra,0xfffff
    8000288a:	596080e7          	jalr	1430(ra) # 80001e1c <add_to_list>
  release(&p->lock);
    8000288e:	8526                	mv	a0,s1
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	408080e7          	jalr	1032(ra) # 80000c98 <release>
}
    80002898:	60e2                	ld	ra,24(sp)
    8000289a:	6442                	ld	s0,16(sp)
    8000289c:	64a2                	ld	s1,8(sp)
    8000289e:	6105                	addi	sp,sp,32
    800028a0:	8082                	ret

00000000800028a2 <fork>:
{
    800028a2:	7139                	addi	sp,sp,-64
    800028a4:	fc06                	sd	ra,56(sp)
    800028a6:	f822                	sd	s0,48(sp)
    800028a8:	f426                	sd	s1,40(sp)
    800028aa:	f04a                	sd	s2,32(sp)
    800028ac:	ec4e                	sd	s3,24(sp)
    800028ae:	e852                	sd	s4,16(sp)
    800028b0:	e456                	sd	s5,8(sp)
    800028b2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	054080e7          	jalr	84(ra) # 80001908 <myproc>
    800028bc:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800028be:	00000097          	auipc	ra,0x0
    800028c2:	e34080e7          	jalr	-460(ra) # 800026f2 <allocproc>
    800028c6:	14050163          	beqz	a0,80002a08 <fork+0x166>
    800028ca:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800028cc:	0689b603          	ld	a2,104(s3)
    800028d0:	792c                	ld	a1,112(a0)
    800028d2:	0709b503          	ld	a0,112(s3)
    800028d6:	fffff097          	auipc	ra,0xfffff
    800028da:	c98080e7          	jalr	-872(ra) # 8000156e <uvmcopy>
    800028de:	04054663          	bltz	a0,8000292a <fork+0x88>
  np->sz = p->sz;
    800028e2:	0689b783          	ld	a5,104(s3)
    800028e6:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    800028ea:	0789b683          	ld	a3,120(s3)
    800028ee:	87b6                	mv	a5,a3
    800028f0:	07893703          	ld	a4,120(s2)
    800028f4:	12068693          	addi	a3,a3,288
    800028f8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800028fc:	6788                	ld	a0,8(a5)
    800028fe:	6b8c                	ld	a1,16(a5)
    80002900:	6f90                	ld	a2,24(a5)
    80002902:	01073023          	sd	a6,0(a4)
    80002906:	e708                	sd	a0,8(a4)
    80002908:	eb0c                	sd	a1,16(a4)
    8000290a:	ef10                	sd	a2,24(a4)
    8000290c:	02078793          	addi	a5,a5,32
    80002910:	02070713          	addi	a4,a4,32
    80002914:	fed792e3          	bne	a5,a3,800028f8 <fork+0x56>
  np->trapframe->a0 = 0;
    80002918:	07893783          	ld	a5,120(s2)
    8000291c:	0607b823          	sd	zero,112(a5)
    80002920:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80002924:	17000a13          	li	s4,368
    80002928:	a03d                	j	80002956 <fork+0xb4>
    freeproc(np);
    8000292a:	854a                	mv	a0,s2
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	93a080e7          	jalr	-1734(ra) # 80002266 <freeproc>
    release(&np->lock);
    80002934:	854a                	mv	a0,s2
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	362080e7          	jalr	866(ra) # 80000c98 <release>
    return -1;
    8000293e:	5afd                	li	s5,-1
    80002940:	a855                	j	800029f4 <fork+0x152>
      np->ofile[i] = filedup(p->ofile[i]);
    80002942:	00002097          	auipc	ra,0x2
    80002946:	07a080e7          	jalr	122(ra) # 800049bc <filedup>
    8000294a:	009907b3          	add	a5,s2,s1
    8000294e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002950:	04a1                	addi	s1,s1,8
    80002952:	01448763          	beq	s1,s4,80002960 <fork+0xbe>
    if(p->ofile[i])
    80002956:	009987b3          	add	a5,s3,s1
    8000295a:	6388                	ld	a0,0(a5)
    8000295c:	f17d                	bnez	a0,80002942 <fork+0xa0>
    8000295e:	bfcd                	j	80002950 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002960:	1709b503          	ld	a0,368(s3)
    80002964:	00001097          	auipc	ra,0x1
    80002968:	1ce080e7          	jalr	462(ra) # 80003b32 <idup>
    8000296c:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002970:	4641                	li	a2,16
    80002972:	17898593          	addi	a1,s3,376
    80002976:	17890513          	addi	a0,s2,376
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	4b8080e7          	jalr	1208(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002982:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    80002986:	854a                	mv	a0,s2
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	310080e7          	jalr	784(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002990:	0000f497          	auipc	s1,0xf
    80002994:	91048493          	addi	s1,s1,-1776 # 800112a0 <cpus>
    80002998:	0000fa17          	auipc	s4,0xf
    8000299c:	e20a0a13          	addi	s4,s4,-480 # 800117b8 <wait_lock>
    800029a0:	8552                	mv	a0,s4
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	242080e7          	jalr	578(ra) # 80000be4 <acquire>
  np->parent = p;
    800029aa:	05393c23          	sd	s3,88(s2)
  release(&wait_lock);
    800029ae:	8552                	mv	a0,s4
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	2e8080e7          	jalr	744(ra) # 80000c98 <release>
  acquire(&np->lock);
    800029b8:	854a                	mv	a0,s2
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	22a080e7          	jalr	554(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800029c2:	478d                	li	a5,3
    800029c4:	00f92c23          	sw	a5,24(s2)
  add_to_list(&c->runnable_head, np, &c->lock_runnable_list);
    800029c8:	03492783          	lw	a5,52(s2)
    800029cc:	00279513          	slli	a0,a5,0x2
    800029d0:	953e                	add	a0,a0,a5
    800029d2:	0516                	slli	a0,a0,0x5
    800029d4:	08850613          	addi	a2,a0,136
    800029d8:	08050513          	addi	a0,a0,128
    800029dc:	9626                	add	a2,a2,s1
    800029de:	85ca                	mv	a1,s2
    800029e0:	9526                	add	a0,a0,s1
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	43a080e7          	jalr	1082(ra) # 80001e1c <add_to_list>
  release(&np->lock);
    800029ea:	854a                	mv	a0,s2
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	2ac080e7          	jalr	684(ra) # 80000c98 <release>
}
    800029f4:	8556                	mv	a0,s5
    800029f6:	70e2                	ld	ra,56(sp)
    800029f8:	7442                	ld	s0,48(sp)
    800029fa:	74a2                	ld	s1,40(sp)
    800029fc:	7902                	ld	s2,32(sp)
    800029fe:	69e2                	ld	s3,24(sp)
    80002a00:	6a42                	ld	s4,16(sp)
    80002a02:	6aa2                	ld	s5,8(sp)
    80002a04:	6121                	addi	sp,sp,64
    80002a06:	8082                	ret
    return -1;
    80002a08:	5afd                	li	s5,-1
    80002a0a:	b7ed                	j	800029f4 <fork+0x152>

0000000080002a0c <scheduler>:
{
    80002a0c:	715d                	addi	sp,sp,-80
    80002a0e:	e486                	sd	ra,72(sp)
    80002a10:	e0a2                	sd	s0,64(sp)
    80002a12:	fc26                	sd	s1,56(sp)
    80002a14:	f84a                	sd	s2,48(sp)
    80002a16:	f44e                	sd	s3,40(sp)
    80002a18:	f052                	sd	s4,32(sp)
    80002a1a:	ec56                	sd	s5,24(sp)
    80002a1c:	e85a                	sd	s6,16(sp)
    80002a1e:	e45e                	sd	s7,8(sp)
    80002a20:	e062                	sd	s8,0(sp)
    80002a22:	0880                	addi	s0,sp,80
    80002a24:	8712                	mv	a4,tp
  int id = r_tp();
    80002a26:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002a28:	0000fb17          	auipc	s6,0xf
    80002a2c:	878b0b13          	addi	s6,s6,-1928 # 800112a0 <cpus>
    80002a30:	00271793          	slli	a5,a4,0x2
    80002a34:	00e786b3          	add	a3,a5,a4
    80002a38:	0696                	slli	a3,a3,0x5
    80002a3a:	96da                	add	a3,a3,s6
    80002a3c:	0006b023          	sd	zero,0(a3)
    80002a40:	97ba                	add	a5,a5,a4
    80002a42:	0796                	slli	a5,a5,0x5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002a44:	08078c13          	addi	s8,a5,128
    80002a48:	9c5a                	add	s8,s8,s6
    80002a4a:	08878b93          	addi	s7,a5,136
    80002a4e:	9bda                	add	s7,s7,s6
        swtch(&c->context, &p->context);
    80002a50:	07a1                	addi	a5,a5,8
    80002a52:	9b3e                	add	s6,s6,a5
      if(p->state == RUNNABLE) {
    80002a54:	498d                	li	s3,3
        c->proc = p;
    80002a56:	8a36                	mv	s4,a3
    for(p = proc; p < &proc[NPROC]; p++) {
    80002a58:	00015917          	auipc	s2,0x15
    80002a5c:	fc090913          	addi	s2,s2,-64 # 80017a18 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a64:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a68:	10079073          	csrw	sstatus,a5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002a6c:	85de                	mv	a1,s7
    80002a6e:	8562                	mv	a0,s8
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	bf6080e7          	jalr	-1034(ra) # 80002666 <remove_first>
    80002a78:	0000f497          	auipc	s1,0xf
    80002a7c:	da048493          	addi	s1,s1,-608 # 80011818 <proc>
        p->state = RUNNING;
    80002a80:	4a91                	li	s5,4
    80002a82:	a03d                	j	80002ab0 <scheduler+0xa4>
    80002a84:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80002a88:	009a3023          	sd	s1,0(s4)
        swtch(&c->context, &p->context);
    80002a8c:	08048593          	addi	a1,s1,128
    80002a90:	855a                	mv	a0,s6
    80002a92:	00000097          	auipc	ra,0x0
    80002a96:	030080e7          	jalr	48(ra) # 80002ac2 <swtch>
        c->proc = 0;
    80002a9a:	000a3023          	sd	zero,0(s4)
      release(&p->lock);
    80002a9e:	8526                	mv	a0,s1
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	1f8080e7          	jalr	504(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002aa8:	18848493          	addi	s1,s1,392
    80002aac:	fb248ae3          	beq	s1,s2,80002a60 <scheduler+0x54>
      acquire(&p->lock);
    80002ab0:	8526                	mv	a0,s1
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	132080e7          	jalr	306(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002aba:	4c9c                	lw	a5,24(s1)
    80002abc:	ff3791e3          	bne	a5,s3,80002a9e <scheduler+0x92>
    80002ac0:	b7d1                	j	80002a84 <scheduler+0x78>

0000000080002ac2 <swtch>:
    80002ac2:	00153023          	sd	ra,0(a0)
    80002ac6:	00253423          	sd	sp,8(a0)
    80002aca:	e900                	sd	s0,16(a0)
    80002acc:	ed04                	sd	s1,24(a0)
    80002ace:	03253023          	sd	s2,32(a0)
    80002ad2:	03353423          	sd	s3,40(a0)
    80002ad6:	03453823          	sd	s4,48(a0)
    80002ada:	03553c23          	sd	s5,56(a0)
    80002ade:	05653023          	sd	s6,64(a0)
    80002ae2:	05753423          	sd	s7,72(a0)
    80002ae6:	05853823          	sd	s8,80(a0)
    80002aea:	05953c23          	sd	s9,88(a0)
    80002aee:	07a53023          	sd	s10,96(a0)
    80002af2:	07b53423          	sd	s11,104(a0)
    80002af6:	0005b083          	ld	ra,0(a1)
    80002afa:	0085b103          	ld	sp,8(a1)
    80002afe:	6980                	ld	s0,16(a1)
    80002b00:	6d84                	ld	s1,24(a1)
    80002b02:	0205b903          	ld	s2,32(a1)
    80002b06:	0285b983          	ld	s3,40(a1)
    80002b0a:	0305ba03          	ld	s4,48(a1)
    80002b0e:	0385ba83          	ld	s5,56(a1)
    80002b12:	0405bb03          	ld	s6,64(a1)
    80002b16:	0485bb83          	ld	s7,72(a1)
    80002b1a:	0505bc03          	ld	s8,80(a1)
    80002b1e:	0585bc83          	ld	s9,88(a1)
    80002b22:	0605bd03          	ld	s10,96(a1)
    80002b26:	0685bd83          	ld	s11,104(a1)
    80002b2a:	8082                	ret

0000000080002b2c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b2c:	1141                	addi	sp,sp,-16
    80002b2e:	e406                	sd	ra,8(sp)
    80002b30:	e022                	sd	s0,0(sp)
    80002b32:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b34:	00005597          	auipc	a1,0x5
    80002b38:	7bc58593          	addi	a1,a1,1980 # 800082f0 <states.1747+0x30>
    80002b3c:	00015517          	auipc	a0,0x15
    80002b40:	edc50513          	addi	a0,a0,-292 # 80017a18 <tickslock>
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	010080e7          	jalr	16(ra) # 80000b54 <initlock>
}
    80002b4c:	60a2                	ld	ra,8(sp)
    80002b4e:	6402                	ld	s0,0(sp)
    80002b50:	0141                	addi	sp,sp,16
    80002b52:	8082                	ret

0000000080002b54 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b54:	1141                	addi	sp,sp,-16
    80002b56:	e422                	sd	s0,8(sp)
    80002b58:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b5a:	00003797          	auipc	a5,0x3
    80002b5e:	4d678793          	addi	a5,a5,1238 # 80006030 <kernelvec>
    80002b62:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b66:	6422                	ld	s0,8(sp)
    80002b68:	0141                	addi	sp,sp,16
    80002b6a:	8082                	ret

0000000080002b6c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b6c:	1141                	addi	sp,sp,-16
    80002b6e:	e406                	sd	ra,8(sp)
    80002b70:	e022                	sd	s0,0(sp)
    80002b72:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	d94080e7          	jalr	-620(ra) # 80001908 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b80:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b82:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002b86:	00004617          	auipc	a2,0x4
    80002b8a:	47a60613          	addi	a2,a2,1146 # 80007000 <_trampoline>
    80002b8e:	00004697          	auipc	a3,0x4
    80002b92:	47268693          	addi	a3,a3,1138 # 80007000 <_trampoline>
    80002b96:	8e91                	sub	a3,a3,a2
    80002b98:	040007b7          	lui	a5,0x4000
    80002b9c:	17fd                	addi	a5,a5,-1
    80002b9e:	07b2                	slli	a5,a5,0xc
    80002ba0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ba2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ba6:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ba8:	180026f3          	csrr	a3,satp
    80002bac:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bae:	7d38                	ld	a4,120(a0)
    80002bb0:	7134                	ld	a3,96(a0)
    80002bb2:	6585                	lui	a1,0x1
    80002bb4:	96ae                	add	a3,a3,a1
    80002bb6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bb8:	7d38                	ld	a4,120(a0)
    80002bba:	00000697          	auipc	a3,0x0
    80002bbe:	13868693          	addi	a3,a3,312 # 80002cf2 <usertrap>
    80002bc2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bc4:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bc6:	8692                	mv	a3,tp
    80002bc8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bca:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bce:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bd2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bda:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bdc:	6f18                	ld	a4,24(a4)
    80002bde:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002be2:	792c                	ld	a1,112(a0)
    80002be4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002be6:	00004717          	auipc	a4,0x4
    80002bea:	4aa70713          	addi	a4,a4,1194 # 80007090 <userret>
    80002bee:	8f11                	sub	a4,a4,a2
    80002bf0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002bf2:	577d                	li	a4,-1
    80002bf4:	177e                	slli	a4,a4,0x3f
    80002bf6:	8dd9                	or	a1,a1,a4
    80002bf8:	02000537          	lui	a0,0x2000
    80002bfc:	157d                	addi	a0,a0,-1
    80002bfe:	0536                	slli	a0,a0,0xd
    80002c00:	9782                	jalr	a5
}
    80002c02:	60a2                	ld	ra,8(sp)
    80002c04:	6402                	ld	s0,0(sp)
    80002c06:	0141                	addi	sp,sp,16
    80002c08:	8082                	ret

0000000080002c0a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c0a:	1101                	addi	sp,sp,-32
    80002c0c:	ec06                	sd	ra,24(sp)
    80002c0e:	e822                	sd	s0,16(sp)
    80002c10:	e426                	sd	s1,8(sp)
    80002c12:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c14:	00015497          	auipc	s1,0x15
    80002c18:	e0448493          	addi	s1,s1,-508 # 80017a18 <tickslock>
    80002c1c:	8526                	mv	a0,s1
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	fc6080e7          	jalr	-58(ra) # 80000be4 <acquire>
  ticks++;
    80002c26:	00006517          	auipc	a0,0x6
    80002c2a:	40a50513          	addi	a0,a0,1034 # 80009030 <ticks>
    80002c2e:	411c                	lw	a5,0(a0)
    80002c30:	2785                	addiw	a5,a5,1
    80002c32:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	7e6080e7          	jalr	2022(ra) # 8000241a <wakeup>
  release(&tickslock);
    80002c3c:	8526                	mv	a0,s1
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	05a080e7          	jalr	90(ra) # 80000c98 <release>
}
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	64a2                	ld	s1,8(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret

0000000080002c50 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	e426                	sd	s1,8(sp)
    80002c58:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c5e:	00074d63          	bltz	a4,80002c78 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c62:	57fd                	li	a5,-1
    80002c64:	17fe                	slli	a5,a5,0x3f
    80002c66:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c68:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c6a:	06f70363          	beq	a4,a5,80002cd0 <devintr+0x80>
  }
}
    80002c6e:	60e2                	ld	ra,24(sp)
    80002c70:	6442                	ld	s0,16(sp)
    80002c72:	64a2                	ld	s1,8(sp)
    80002c74:	6105                	addi	sp,sp,32
    80002c76:	8082                	ret
     (scause & 0xff) == 9){
    80002c78:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c7c:	46a5                	li	a3,9
    80002c7e:	fed792e3          	bne	a5,a3,80002c62 <devintr+0x12>
    int irq = plic_claim();
    80002c82:	00003097          	auipc	ra,0x3
    80002c86:	4b6080e7          	jalr	1206(ra) # 80006138 <plic_claim>
    80002c8a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c8c:	47a9                	li	a5,10
    80002c8e:	02f50763          	beq	a0,a5,80002cbc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c92:	4785                	li	a5,1
    80002c94:	02f50963          	beq	a0,a5,80002cc6 <devintr+0x76>
    return 1;
    80002c98:	4505                	li	a0,1
    } else if(irq){
    80002c9a:	d8f1                	beqz	s1,80002c6e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c9c:	85a6                	mv	a1,s1
    80002c9e:	00005517          	auipc	a0,0x5
    80002ca2:	65a50513          	addi	a0,a0,1626 # 800082f8 <states.1747+0x38>
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	8e2080e7          	jalr	-1822(ra) # 80000588 <printf>
      plic_complete(irq);
    80002cae:	8526                	mv	a0,s1
    80002cb0:	00003097          	auipc	ra,0x3
    80002cb4:	4ac080e7          	jalr	1196(ra) # 8000615c <plic_complete>
    return 1;
    80002cb8:	4505                	li	a0,1
    80002cba:	bf55                	j	80002c6e <devintr+0x1e>
      uartintr();
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	cec080e7          	jalr	-788(ra) # 800009a8 <uartintr>
    80002cc4:	b7ed                	j	80002cae <devintr+0x5e>
      virtio_disk_intr();
    80002cc6:	00004097          	auipc	ra,0x4
    80002cca:	976080e7          	jalr	-1674(ra) # 8000663c <virtio_disk_intr>
    80002cce:	b7c5                	j	80002cae <devintr+0x5e>
    if(cpuid() == 0){
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	c04080e7          	jalr	-1020(ra) # 800018d4 <cpuid>
    80002cd8:	c901                	beqz	a0,80002ce8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002cda:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cde:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ce0:	14479073          	csrw	sip,a5
    return 2;
    80002ce4:	4509                	li	a0,2
    80002ce6:	b761                	j	80002c6e <devintr+0x1e>
      clockintr();
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	f22080e7          	jalr	-222(ra) # 80002c0a <clockintr>
    80002cf0:	b7ed                	j	80002cda <devintr+0x8a>

0000000080002cf2 <usertrap>:
{
    80002cf2:	1101                	addi	sp,sp,-32
    80002cf4:	ec06                	sd	ra,24(sp)
    80002cf6:	e822                	sd	s0,16(sp)
    80002cf8:	e426                	sd	s1,8(sp)
    80002cfa:	e04a                	sd	s2,0(sp)
    80002cfc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cfe:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d02:	1007f793          	andi	a5,a5,256
    80002d06:	e3ad                	bnez	a5,80002d68 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d08:	00003797          	auipc	a5,0x3
    80002d0c:	32878793          	addi	a5,a5,808 # 80006030 <kernelvec>
    80002d10:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	bf4080e7          	jalr	-1036(ra) # 80001908 <myproc>
    80002d1c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d1e:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d20:	14102773          	csrr	a4,sepc
    80002d24:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d26:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d2a:	47a1                	li	a5,8
    80002d2c:	04f71c63          	bne	a4,a5,80002d84 <usertrap+0x92>
    if(p->killed)
    80002d30:	551c                	lw	a5,40(a0)
    80002d32:	e3b9                	bnez	a5,80002d78 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d34:	7cb8                	ld	a4,120(s1)
    80002d36:	6f1c                	ld	a5,24(a4)
    80002d38:	0791                	addi	a5,a5,4
    80002d3a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d3c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d40:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d44:	10079073          	csrw	sstatus,a5
    syscall();
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	2e0080e7          	jalr	736(ra) # 80003028 <syscall>
  if(p->killed)
    80002d50:	549c                	lw	a5,40(s1)
    80002d52:	ebc1                	bnez	a5,80002de2 <usertrap+0xf0>
  usertrapret();
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	e18080e7          	jalr	-488(ra) # 80002b6c <usertrapret>
}
    80002d5c:	60e2                	ld	ra,24(sp)
    80002d5e:	6442                	ld	s0,16(sp)
    80002d60:	64a2                	ld	s1,8(sp)
    80002d62:	6902                	ld	s2,0(sp)
    80002d64:	6105                	addi	sp,sp,32
    80002d66:	8082                	ret
    panic("usertrap: not from user mode");
    80002d68:	00005517          	auipc	a0,0x5
    80002d6c:	5b050513          	addi	a0,a0,1456 # 80008318 <states.1747+0x58>
    80002d70:	ffffd097          	auipc	ra,0xffffd
    80002d74:	7ce080e7          	jalr	1998(ra) # 8000053e <panic>
      exit(-1);
    80002d78:	557d                	li	a0,-1
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	7fc080e7          	jalr	2044(ra) # 80002576 <exit>
    80002d82:	bf4d                	j	80002d34 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	ecc080e7          	jalr	-308(ra) # 80002c50 <devintr>
    80002d8c:	892a                	mv	s2,a0
    80002d8e:	c501                	beqz	a0,80002d96 <usertrap+0xa4>
  if(p->killed)
    80002d90:	549c                	lw	a5,40(s1)
    80002d92:	c3a1                	beqz	a5,80002dd2 <usertrap+0xe0>
    80002d94:	a815                	j	80002dc8 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d96:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d9a:	5890                	lw	a2,48(s1)
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	59c50513          	addi	a0,a0,1436 # 80008338 <states.1747+0x78>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	7e4080e7          	jalr	2020(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dac:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002db0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002db4:	00005517          	auipc	a0,0x5
    80002db8:	5b450513          	addi	a0,a0,1460 # 80008368 <states.1747+0xa8>
    80002dbc:	ffffd097          	auipc	ra,0xffffd
    80002dc0:	7cc080e7          	jalr	1996(ra) # 80000588 <printf>
    p->killed = 1;
    80002dc4:	4785                	li	a5,1
    80002dc6:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002dc8:	557d                	li	a0,-1
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	7ac080e7          	jalr	1964(ra) # 80002576 <exit>
  if(which_dev == 2)
    80002dd2:	4789                	li	a5,2
    80002dd4:	f8f910e3          	bne	s2,a5,80002d54 <usertrap+0x62>
    yield();
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	228080e7          	jalr	552(ra) # 80002000 <yield>
    80002de0:	bf95                	j	80002d54 <usertrap+0x62>
  int which_dev = 0;
    80002de2:	4901                	li	s2,0
    80002de4:	b7d5                	j	80002dc8 <usertrap+0xd6>

0000000080002de6 <kerneltrap>:
{
    80002de6:	7179                	addi	sp,sp,-48
    80002de8:	f406                	sd	ra,40(sp)
    80002dea:	f022                	sd	s0,32(sp)
    80002dec:	ec26                	sd	s1,24(sp)
    80002dee:	e84a                	sd	s2,16(sp)
    80002df0:	e44e                	sd	s3,8(sp)
    80002df2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002df4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dfc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e00:	1004f793          	andi	a5,s1,256
    80002e04:	cb85                	beqz	a5,80002e34 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e06:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e0a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e0c:	ef85                	bnez	a5,80002e44 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	e42080e7          	jalr	-446(ra) # 80002c50 <devintr>
    80002e16:	cd1d                	beqz	a0,80002e54 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e18:	4789                	li	a5,2
    80002e1a:	06f50a63          	beq	a0,a5,80002e8e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e1e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e22:	10049073          	csrw	sstatus,s1
}
    80002e26:	70a2                	ld	ra,40(sp)
    80002e28:	7402                	ld	s0,32(sp)
    80002e2a:	64e2                	ld	s1,24(sp)
    80002e2c:	6942                	ld	s2,16(sp)
    80002e2e:	69a2                	ld	s3,8(sp)
    80002e30:	6145                	addi	sp,sp,48
    80002e32:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e34:	00005517          	auipc	a0,0x5
    80002e38:	55450513          	addi	a0,a0,1364 # 80008388 <states.1747+0xc8>
    80002e3c:	ffffd097          	auipc	ra,0xffffd
    80002e40:	702080e7          	jalr	1794(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002e44:	00005517          	auipc	a0,0x5
    80002e48:	56c50513          	addi	a0,a0,1388 # 800083b0 <states.1747+0xf0>
    80002e4c:	ffffd097          	auipc	ra,0xffffd
    80002e50:	6f2080e7          	jalr	1778(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002e54:	85ce                	mv	a1,s3
    80002e56:	00005517          	auipc	a0,0x5
    80002e5a:	57a50513          	addi	a0,a0,1402 # 800083d0 <states.1747+0x110>
    80002e5e:	ffffd097          	auipc	ra,0xffffd
    80002e62:	72a080e7          	jalr	1834(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e66:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e6a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e6e:	00005517          	auipc	a0,0x5
    80002e72:	57250513          	addi	a0,a0,1394 # 800083e0 <states.1747+0x120>
    80002e76:	ffffd097          	auipc	ra,0xffffd
    80002e7a:	712080e7          	jalr	1810(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002e7e:	00005517          	auipc	a0,0x5
    80002e82:	57a50513          	addi	a0,a0,1402 # 800083f8 <states.1747+0x138>
    80002e86:	ffffd097          	auipc	ra,0xffffd
    80002e8a:	6b8080e7          	jalr	1720(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	a7a080e7          	jalr	-1414(ra) # 80001908 <myproc>
    80002e96:	d541                	beqz	a0,80002e1e <kerneltrap+0x38>
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	a70080e7          	jalr	-1424(ra) # 80001908 <myproc>
    80002ea0:	4d18                	lw	a4,24(a0)
    80002ea2:	4791                	li	a5,4
    80002ea4:	f6f71de3          	bne	a4,a5,80002e1e <kerneltrap+0x38>
    yield();
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	158080e7          	jalr	344(ra) # 80002000 <yield>
    80002eb0:	b7bd                	j	80002e1e <kerneltrap+0x38>

0000000080002eb2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002eb2:	1101                	addi	sp,sp,-32
    80002eb4:	ec06                	sd	ra,24(sp)
    80002eb6:	e822                	sd	s0,16(sp)
    80002eb8:	e426                	sd	s1,8(sp)
    80002eba:	1000                	addi	s0,sp,32
    80002ebc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	a4a080e7          	jalr	-1462(ra) # 80001908 <myproc>
  switch (n) {
    80002ec6:	4795                	li	a5,5
    80002ec8:	0497e163          	bltu	a5,s1,80002f0a <argraw+0x58>
    80002ecc:	048a                	slli	s1,s1,0x2
    80002ece:	00005717          	auipc	a4,0x5
    80002ed2:	56270713          	addi	a4,a4,1378 # 80008430 <states.1747+0x170>
    80002ed6:	94ba                	add	s1,s1,a4
    80002ed8:	409c                	lw	a5,0(s1)
    80002eda:	97ba                	add	a5,a5,a4
    80002edc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ede:	7d3c                	ld	a5,120(a0)
    80002ee0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ee2:	60e2                	ld	ra,24(sp)
    80002ee4:	6442                	ld	s0,16(sp)
    80002ee6:	64a2                	ld	s1,8(sp)
    80002ee8:	6105                	addi	sp,sp,32
    80002eea:	8082                	ret
    return p->trapframe->a1;
    80002eec:	7d3c                	ld	a5,120(a0)
    80002eee:	7fa8                	ld	a0,120(a5)
    80002ef0:	bfcd                	j	80002ee2 <argraw+0x30>
    return p->trapframe->a2;
    80002ef2:	7d3c                	ld	a5,120(a0)
    80002ef4:	63c8                	ld	a0,128(a5)
    80002ef6:	b7f5                	j	80002ee2 <argraw+0x30>
    return p->trapframe->a3;
    80002ef8:	7d3c                	ld	a5,120(a0)
    80002efa:	67c8                	ld	a0,136(a5)
    80002efc:	b7dd                	j	80002ee2 <argraw+0x30>
    return p->trapframe->a4;
    80002efe:	7d3c                	ld	a5,120(a0)
    80002f00:	6bc8                	ld	a0,144(a5)
    80002f02:	b7c5                	j	80002ee2 <argraw+0x30>
    return p->trapframe->a5;
    80002f04:	7d3c                	ld	a5,120(a0)
    80002f06:	6fc8                	ld	a0,152(a5)
    80002f08:	bfe9                	j	80002ee2 <argraw+0x30>
  panic("argraw");
    80002f0a:	00005517          	auipc	a0,0x5
    80002f0e:	4fe50513          	addi	a0,a0,1278 # 80008408 <states.1747+0x148>
    80002f12:	ffffd097          	auipc	ra,0xffffd
    80002f16:	62c080e7          	jalr	1580(ra) # 8000053e <panic>

0000000080002f1a <fetchaddr>:
{
    80002f1a:	1101                	addi	sp,sp,-32
    80002f1c:	ec06                	sd	ra,24(sp)
    80002f1e:	e822                	sd	s0,16(sp)
    80002f20:	e426                	sd	s1,8(sp)
    80002f22:	e04a                	sd	s2,0(sp)
    80002f24:	1000                	addi	s0,sp,32
    80002f26:	84aa                	mv	s1,a0
    80002f28:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	9de080e7          	jalr	-1570(ra) # 80001908 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f32:	753c                	ld	a5,104(a0)
    80002f34:	02f4f863          	bgeu	s1,a5,80002f64 <fetchaddr+0x4a>
    80002f38:	00848713          	addi	a4,s1,8
    80002f3c:	02e7e663          	bltu	a5,a4,80002f68 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f40:	46a1                	li	a3,8
    80002f42:	8626                	mv	a2,s1
    80002f44:	85ca                	mv	a1,s2
    80002f46:	7928                	ld	a0,112(a0)
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	7b6080e7          	jalr	1974(ra) # 800016fe <copyin>
    80002f50:	00a03533          	snez	a0,a0
    80002f54:	40a00533          	neg	a0,a0
}
    80002f58:	60e2                	ld	ra,24(sp)
    80002f5a:	6442                	ld	s0,16(sp)
    80002f5c:	64a2                	ld	s1,8(sp)
    80002f5e:	6902                	ld	s2,0(sp)
    80002f60:	6105                	addi	sp,sp,32
    80002f62:	8082                	ret
    return -1;
    80002f64:	557d                	li	a0,-1
    80002f66:	bfcd                	j	80002f58 <fetchaddr+0x3e>
    80002f68:	557d                	li	a0,-1
    80002f6a:	b7fd                	j	80002f58 <fetchaddr+0x3e>

0000000080002f6c <fetchstr>:
{
    80002f6c:	7179                	addi	sp,sp,-48
    80002f6e:	f406                	sd	ra,40(sp)
    80002f70:	f022                	sd	s0,32(sp)
    80002f72:	ec26                	sd	s1,24(sp)
    80002f74:	e84a                	sd	s2,16(sp)
    80002f76:	e44e                	sd	s3,8(sp)
    80002f78:	1800                	addi	s0,sp,48
    80002f7a:	892a                	mv	s2,a0
    80002f7c:	84ae                	mv	s1,a1
    80002f7e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	988080e7          	jalr	-1656(ra) # 80001908 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f88:	86ce                	mv	a3,s3
    80002f8a:	864a                	mv	a2,s2
    80002f8c:	85a6                	mv	a1,s1
    80002f8e:	7928                	ld	a0,112(a0)
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	7fa080e7          	jalr	2042(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002f98:	00054763          	bltz	a0,80002fa6 <fetchstr+0x3a>
  return strlen(buf);
    80002f9c:	8526                	mv	a0,s1
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	ec6080e7          	jalr	-314(ra) # 80000e64 <strlen>
}
    80002fa6:	70a2                	ld	ra,40(sp)
    80002fa8:	7402                	ld	s0,32(sp)
    80002faa:	64e2                	ld	s1,24(sp)
    80002fac:	6942                	ld	s2,16(sp)
    80002fae:	69a2                	ld	s3,8(sp)
    80002fb0:	6145                	addi	sp,sp,48
    80002fb2:	8082                	ret

0000000080002fb4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002fb4:	1101                	addi	sp,sp,-32
    80002fb6:	ec06                	sd	ra,24(sp)
    80002fb8:	e822                	sd	s0,16(sp)
    80002fba:	e426                	sd	s1,8(sp)
    80002fbc:	1000                	addi	s0,sp,32
    80002fbe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fc0:	00000097          	auipc	ra,0x0
    80002fc4:	ef2080e7          	jalr	-270(ra) # 80002eb2 <argraw>
    80002fc8:	c088                	sw	a0,0(s1)
  return 0;
}
    80002fca:	4501                	li	a0,0
    80002fcc:	60e2                	ld	ra,24(sp)
    80002fce:	6442                	ld	s0,16(sp)
    80002fd0:	64a2                	ld	s1,8(sp)
    80002fd2:	6105                	addi	sp,sp,32
    80002fd4:	8082                	ret

0000000080002fd6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	e426                	sd	s1,8(sp)
    80002fde:	1000                	addi	s0,sp,32
    80002fe0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fe2:	00000097          	auipc	ra,0x0
    80002fe6:	ed0080e7          	jalr	-304(ra) # 80002eb2 <argraw>
    80002fea:	e088                	sd	a0,0(s1)
  return 0;
}
    80002fec:	4501                	li	a0,0
    80002fee:	60e2                	ld	ra,24(sp)
    80002ff0:	6442                	ld	s0,16(sp)
    80002ff2:	64a2                	ld	s1,8(sp)
    80002ff4:	6105                	addi	sp,sp,32
    80002ff6:	8082                	ret

0000000080002ff8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	e426                	sd	s1,8(sp)
    80003000:	e04a                	sd	s2,0(sp)
    80003002:	1000                	addi	s0,sp,32
    80003004:	84ae                	mv	s1,a1
    80003006:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003008:	00000097          	auipc	ra,0x0
    8000300c:	eaa080e7          	jalr	-342(ra) # 80002eb2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003010:	864a                	mv	a2,s2
    80003012:	85a6                	mv	a1,s1
    80003014:	00000097          	auipc	ra,0x0
    80003018:	f58080e7          	jalr	-168(ra) # 80002f6c <fetchstr>
}
    8000301c:	60e2                	ld	ra,24(sp)
    8000301e:	6442                	ld	s0,16(sp)
    80003020:	64a2                	ld	s1,8(sp)
    80003022:	6902                	ld	s2,0(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <syscall>:
[SYS_get_cpu] sys_get_cpu,
};

void
syscall(void)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	e04a                	sd	s2,0(sp)
    80003032:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	8d4080e7          	jalr	-1836(ra) # 80001908 <myproc>
    8000303c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000303e:	07853903          	ld	s2,120(a0)
    80003042:	0a893783          	ld	a5,168(s2)
    80003046:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000304a:	37fd                	addiw	a5,a5,-1
    8000304c:	4759                	li	a4,22
    8000304e:	00f76f63          	bltu	a4,a5,8000306c <syscall+0x44>
    80003052:	00369713          	slli	a4,a3,0x3
    80003056:	00005797          	auipc	a5,0x5
    8000305a:	3f278793          	addi	a5,a5,1010 # 80008448 <syscalls>
    8000305e:	97ba                	add	a5,a5,a4
    80003060:	639c                	ld	a5,0(a5)
    80003062:	c789                	beqz	a5,8000306c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003064:	9782                	jalr	a5
    80003066:	06a93823          	sd	a0,112(s2)
    8000306a:	a839                	j	80003088 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000306c:	17848613          	addi	a2,s1,376
    80003070:	588c                	lw	a1,48(s1)
    80003072:	00005517          	auipc	a0,0x5
    80003076:	39e50513          	addi	a0,a0,926 # 80008410 <states.1747+0x150>
    8000307a:	ffffd097          	auipc	ra,0xffffd
    8000307e:	50e080e7          	jalr	1294(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003082:	7cbc                	ld	a5,120(s1)
    80003084:	577d                	li	a4,-1
    80003086:	fbb8                	sd	a4,112(a5)
  }
}
    80003088:	60e2                	ld	ra,24(sp)
    8000308a:	6442                	ld	s0,16(sp)
    8000308c:	64a2                	ld	s1,8(sp)
    8000308e:	6902                	ld	s2,0(sp)
    80003090:	6105                	addi	sp,sp,32
    80003092:	8082                	ret

0000000080003094 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000309c:	fec40593          	addi	a1,s0,-20
    800030a0:	4501                	li	a0,0
    800030a2:	00000097          	auipc	ra,0x0
    800030a6:	f12080e7          	jalr	-238(ra) # 80002fb4 <argint>
    return -1;
    800030aa:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030ac:	00054963          	bltz	a0,800030be <sys_exit+0x2a>
  exit(n);
    800030b0:	fec42503          	lw	a0,-20(s0)
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	4c2080e7          	jalr	1218(ra) # 80002576 <exit>
  return 0;  // not reached
    800030bc:	4781                	li	a5,0
}
    800030be:	853e                	mv	a0,a5
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	6105                	addi	sp,sp,32
    800030c6:	8082                	ret

00000000800030c8 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030c8:	1141                	addi	sp,sp,-16
    800030ca:	e406                	sd	ra,8(sp)
    800030cc:	e022                	sd	s0,0(sp)
    800030ce:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800030d0:	fffff097          	auipc	ra,0xfffff
    800030d4:	838080e7          	jalr	-1992(ra) # 80001908 <myproc>
}
    800030d8:	5908                	lw	a0,48(a0)
    800030da:	60a2                	ld	ra,8(sp)
    800030dc:	6402                	ld	s0,0(sp)
    800030de:	0141                	addi	sp,sp,16
    800030e0:	8082                	ret

00000000800030e2 <sys_fork>:

uint64
sys_fork(void)
{
    800030e2:	1141                	addi	sp,sp,-16
    800030e4:	e406                	sd	ra,8(sp)
    800030e6:	e022                	sd	s0,0(sp)
    800030e8:	0800                	addi	s0,sp,16
  return fork();
    800030ea:	fffff097          	auipc	ra,0xfffff
    800030ee:	7b8080e7          	jalr	1976(ra) # 800028a2 <fork>
}
    800030f2:	60a2                	ld	ra,8(sp)
    800030f4:	6402                	ld	s0,0(sp)
    800030f6:	0141                	addi	sp,sp,16
    800030f8:	8082                	ret

00000000800030fa <sys_wait>:

uint64
sys_wait(void)
{
    800030fa:	1101                	addi	sp,sp,-32
    800030fc:	ec06                	sd	ra,24(sp)
    800030fe:	e822                	sd	s0,16(sp)
    80003100:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003102:	fe840593          	addi	a1,s0,-24
    80003106:	4501                	li	a0,0
    80003108:	00000097          	auipc	ra,0x0
    8000310c:	ece080e7          	jalr	-306(ra) # 80002fd6 <argaddr>
    80003110:	87aa                	mv	a5,a0
    return -1;
    80003112:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003114:	0007c863          	bltz	a5,80003124 <sys_wait+0x2a>
  return wait(p);
    80003118:	fe843503          	ld	a0,-24(s0)
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	1d6080e7          	jalr	470(ra) # 800022f2 <wait>
}
    80003124:	60e2                	ld	ra,24(sp)
    80003126:	6442                	ld	s0,16(sp)
    80003128:	6105                	addi	sp,sp,32
    8000312a:	8082                	ret

000000008000312c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000312c:	7179                	addi	sp,sp,-48
    8000312e:	f406                	sd	ra,40(sp)
    80003130:	f022                	sd	s0,32(sp)
    80003132:	ec26                	sd	s1,24(sp)
    80003134:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003136:	fdc40593          	addi	a1,s0,-36
    8000313a:	4501                	li	a0,0
    8000313c:	00000097          	auipc	ra,0x0
    80003140:	e78080e7          	jalr	-392(ra) # 80002fb4 <argint>
    80003144:	87aa                	mv	a5,a0
    return -1;
    80003146:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003148:	0207c063          	bltz	a5,80003168 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	7bc080e7          	jalr	1980(ra) # 80001908 <myproc>
    80003154:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003156:	fdc42503          	lw	a0,-36(s0)
    8000315a:	fffff097          	auipc	ra,0xfffff
    8000315e:	95a080e7          	jalr	-1702(ra) # 80001ab4 <growproc>
    80003162:	00054863          	bltz	a0,80003172 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003166:	8526                	mv	a0,s1
}
    80003168:	70a2                	ld	ra,40(sp)
    8000316a:	7402                	ld	s0,32(sp)
    8000316c:	64e2                	ld	s1,24(sp)
    8000316e:	6145                	addi	sp,sp,48
    80003170:	8082                	ret
    return -1;
    80003172:	557d                	li	a0,-1
    80003174:	bfd5                	j	80003168 <sys_sbrk+0x3c>

0000000080003176 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003176:	7139                	addi	sp,sp,-64
    80003178:	fc06                	sd	ra,56(sp)
    8000317a:	f822                	sd	s0,48(sp)
    8000317c:	f426                	sd	s1,40(sp)
    8000317e:	f04a                	sd	s2,32(sp)
    80003180:	ec4e                	sd	s3,24(sp)
    80003182:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003184:	fcc40593          	addi	a1,s0,-52
    80003188:	4501                	li	a0,0
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	e2a080e7          	jalr	-470(ra) # 80002fb4 <argint>
    return -1;
    80003192:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003194:	06054563          	bltz	a0,800031fe <sys_sleep+0x88>
  acquire(&tickslock);
    80003198:	00015517          	auipc	a0,0x15
    8000319c:	88050513          	addi	a0,a0,-1920 # 80017a18 <tickslock>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	a44080e7          	jalr	-1468(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800031a8:	00006917          	auipc	s2,0x6
    800031ac:	e8892903          	lw	s2,-376(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800031b0:	fcc42783          	lw	a5,-52(s0)
    800031b4:	cf85                	beqz	a5,800031ec <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031b6:	00015997          	auipc	s3,0x15
    800031ba:	86298993          	addi	s3,s3,-1950 # 80017a18 <tickslock>
    800031be:	00006497          	auipc	s1,0x6
    800031c2:	e7248493          	addi	s1,s1,-398 # 80009030 <ticks>
    if(myproc()->killed){
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	742080e7          	jalr	1858(ra) # 80001908 <myproc>
    800031ce:	551c                	lw	a5,40(a0)
    800031d0:	ef9d                	bnez	a5,8000320e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800031d2:	85ce                	mv	a1,s3
    800031d4:	8526                	mv	a0,s1
    800031d6:	fffff097          	auipc	ra,0xfffff
    800031da:	ed2080e7          	jalr	-302(ra) # 800020a8 <sleep>
  while(ticks - ticks0 < n){
    800031de:	409c                	lw	a5,0(s1)
    800031e0:	412787bb          	subw	a5,a5,s2
    800031e4:	fcc42703          	lw	a4,-52(s0)
    800031e8:	fce7efe3          	bltu	a5,a4,800031c6 <sys_sleep+0x50>
  }
  release(&tickslock);
    800031ec:	00015517          	auipc	a0,0x15
    800031f0:	82c50513          	addi	a0,a0,-2004 # 80017a18 <tickslock>
    800031f4:	ffffe097          	auipc	ra,0xffffe
    800031f8:	aa4080e7          	jalr	-1372(ra) # 80000c98 <release>
  return 0;
    800031fc:	4781                	li	a5,0
}
    800031fe:	853e                	mv	a0,a5
    80003200:	70e2                	ld	ra,56(sp)
    80003202:	7442                	ld	s0,48(sp)
    80003204:	74a2                	ld	s1,40(sp)
    80003206:	7902                	ld	s2,32(sp)
    80003208:	69e2                	ld	s3,24(sp)
    8000320a:	6121                	addi	sp,sp,64
    8000320c:	8082                	ret
      release(&tickslock);
    8000320e:	00015517          	auipc	a0,0x15
    80003212:	80a50513          	addi	a0,a0,-2038 # 80017a18 <tickslock>
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	a82080e7          	jalr	-1406(ra) # 80000c98 <release>
      return -1;
    8000321e:	57fd                	li	a5,-1
    80003220:	bff9                	j	800031fe <sys_sleep+0x88>

0000000080003222 <sys_kill>:

uint64
sys_kill(void)
{
    80003222:	1101                	addi	sp,sp,-32
    80003224:	ec06                	sd	ra,24(sp)
    80003226:	e822                	sd	s0,16(sp)
    80003228:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000322a:	fec40593          	addi	a1,s0,-20
    8000322e:	4501                	li	a0,0
    80003230:	00000097          	auipc	ra,0x0
    80003234:	d84080e7          	jalr	-636(ra) # 80002fb4 <argint>
    80003238:	87aa                	mv	a5,a0
    return -1;
    8000323a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000323c:	0007c863          	bltz	a5,8000324c <sys_kill+0x2a>
  return kill(pid);
    80003240:	fec42503          	lw	a0,-20(s0)
    80003244:	fffff097          	auipc	ra,0xfffff
    80003248:	9d2080e7          	jalr	-1582(ra) # 80001c16 <kill>
}
    8000324c:	60e2                	ld	ra,24(sp)
    8000324e:	6442                	ld	s0,16(sp)
    80003250:	6105                	addi	sp,sp,32
    80003252:	8082                	ret

0000000080003254 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003254:	1101                	addi	sp,sp,-32
    80003256:	ec06                	sd	ra,24(sp)
    80003258:	e822                	sd	s0,16(sp)
    8000325a:	e426                	sd	s1,8(sp)
    8000325c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000325e:	00014517          	auipc	a0,0x14
    80003262:	7ba50513          	addi	a0,a0,1978 # 80017a18 <tickslock>
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	97e080e7          	jalr	-1666(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000326e:	00006497          	auipc	s1,0x6
    80003272:	dc24a483          	lw	s1,-574(s1) # 80009030 <ticks>
  release(&tickslock);
    80003276:	00014517          	auipc	a0,0x14
    8000327a:	7a250513          	addi	a0,a0,1954 # 80017a18 <tickslock>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	a1a080e7          	jalr	-1510(ra) # 80000c98 <release>
  return xticks;
}
    80003286:	02049513          	slli	a0,s1,0x20
    8000328a:	9101                	srli	a0,a0,0x20
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6105                	addi	sp,sp,32
    80003294:	8082                	ret

0000000080003296 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80003296:	1101                	addi	sp,sp,-32
    80003298:	ec06                	sd	ra,24(sp)
    8000329a:	e822                	sd	s0,16(sp)
    8000329c:	1000                	addi	s0,sp,32
    int cpu_num;
    if(argint(0, &cpu_num) <= -1){
    8000329e:	fec40593          	addi	a1,s0,-20
    800032a2:	4501                	li	a0,0
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	d10080e7          	jalr	-752(ra) # 80002fb4 <argint>
    800032ac:	87aa                	mv	a5,a0
      return -1;
    800032ae:	557d                	li	a0,-1
    if(argint(0, &cpu_num) <= -1){
    800032b0:	0007c863          	bltz	a5,800032c0 <sys_set_cpu+0x2a>
    }
    
    return set_cpu(cpu_num);
    800032b4:	fec42503          	lw	a0,-20(s0)
    800032b8:	fffff097          	auipc	ra,0xfffff
    800032bc:	db2080e7          	jalr	-590(ra) # 8000206a <set_cpu>
}
    800032c0:	60e2                	ld	ra,24(sp)
    800032c2:	6442                	ld	s0,16(sp)
    800032c4:	6105                	addi	sp,sp,32
    800032c6:	8082                	ret

00000000800032c8 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800032c8:	1141                	addi	sp,sp,-16
    800032ca:	e406                	sd	ra,8(sp)
    800032cc:	e022                	sd	s0,0(sp)
    800032ce:	0800                	addi	s0,sp,16
    return get_cpu();
    800032d0:	fffff097          	auipc	ra,0xfffff
    800032d4:	b12080e7          	jalr	-1262(ra) # 80001de2 <get_cpu>
    800032d8:	60a2                	ld	ra,8(sp)
    800032da:	6402                	ld	s0,0(sp)
    800032dc:	0141                	addi	sp,sp,16
    800032de:	8082                	ret

00000000800032e0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032e0:	7179                	addi	sp,sp,-48
    800032e2:	f406                	sd	ra,40(sp)
    800032e4:	f022                	sd	s0,32(sp)
    800032e6:	ec26                	sd	s1,24(sp)
    800032e8:	e84a                	sd	s2,16(sp)
    800032ea:	e44e                	sd	s3,8(sp)
    800032ec:	e052                	sd	s4,0(sp)
    800032ee:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032f0:	00005597          	auipc	a1,0x5
    800032f4:	21858593          	addi	a1,a1,536 # 80008508 <syscalls+0xc0>
    800032f8:	00014517          	auipc	a0,0x14
    800032fc:	73850513          	addi	a0,a0,1848 # 80017a30 <bcache>
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	854080e7          	jalr	-1964(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003308:	0001c797          	auipc	a5,0x1c
    8000330c:	72878793          	addi	a5,a5,1832 # 8001fa30 <bcache+0x8000>
    80003310:	0001d717          	auipc	a4,0x1d
    80003314:	98870713          	addi	a4,a4,-1656 # 8001fc98 <bcache+0x8268>
    80003318:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000331c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003320:	00014497          	auipc	s1,0x14
    80003324:	72848493          	addi	s1,s1,1832 # 80017a48 <bcache+0x18>
    b->next = bcache.head.next;
    80003328:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000332a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000332c:	00005a17          	auipc	s4,0x5
    80003330:	1e4a0a13          	addi	s4,s4,484 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003334:	2b893783          	ld	a5,696(s2)
    80003338:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000333a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000333e:	85d2                	mv	a1,s4
    80003340:	01048513          	addi	a0,s1,16
    80003344:	00001097          	auipc	ra,0x1
    80003348:	4bc080e7          	jalr	1212(ra) # 80004800 <initsleeplock>
    bcache.head.next->prev = b;
    8000334c:	2b893783          	ld	a5,696(s2)
    80003350:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003352:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003356:	45848493          	addi	s1,s1,1112
    8000335a:	fd349de3          	bne	s1,s3,80003334 <binit+0x54>
  }
}
    8000335e:	70a2                	ld	ra,40(sp)
    80003360:	7402                	ld	s0,32(sp)
    80003362:	64e2                	ld	s1,24(sp)
    80003364:	6942                	ld	s2,16(sp)
    80003366:	69a2                	ld	s3,8(sp)
    80003368:	6a02                	ld	s4,0(sp)
    8000336a:	6145                	addi	sp,sp,48
    8000336c:	8082                	ret

000000008000336e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000336e:	7179                	addi	sp,sp,-48
    80003370:	f406                	sd	ra,40(sp)
    80003372:	f022                	sd	s0,32(sp)
    80003374:	ec26                	sd	s1,24(sp)
    80003376:	e84a                	sd	s2,16(sp)
    80003378:	e44e                	sd	s3,8(sp)
    8000337a:	1800                	addi	s0,sp,48
    8000337c:	89aa                	mv	s3,a0
    8000337e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003380:	00014517          	auipc	a0,0x14
    80003384:	6b050513          	addi	a0,a0,1712 # 80017a30 <bcache>
    80003388:	ffffe097          	auipc	ra,0xffffe
    8000338c:	85c080e7          	jalr	-1956(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003390:	0001d497          	auipc	s1,0x1d
    80003394:	9584b483          	ld	s1,-1704(s1) # 8001fce8 <bcache+0x82b8>
    80003398:	0001d797          	auipc	a5,0x1d
    8000339c:	90078793          	addi	a5,a5,-1792 # 8001fc98 <bcache+0x8268>
    800033a0:	02f48f63          	beq	s1,a5,800033de <bread+0x70>
    800033a4:	873e                	mv	a4,a5
    800033a6:	a021                	j	800033ae <bread+0x40>
    800033a8:	68a4                	ld	s1,80(s1)
    800033aa:	02e48a63          	beq	s1,a4,800033de <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033ae:	449c                	lw	a5,8(s1)
    800033b0:	ff379ce3          	bne	a5,s3,800033a8 <bread+0x3a>
    800033b4:	44dc                	lw	a5,12(s1)
    800033b6:	ff2799e3          	bne	a5,s2,800033a8 <bread+0x3a>
      b->refcnt++;
    800033ba:	40bc                	lw	a5,64(s1)
    800033bc:	2785                	addiw	a5,a5,1
    800033be:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033c0:	00014517          	auipc	a0,0x14
    800033c4:	67050513          	addi	a0,a0,1648 # 80017a30 <bcache>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	8d0080e7          	jalr	-1840(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033d0:	01048513          	addi	a0,s1,16
    800033d4:	00001097          	auipc	ra,0x1
    800033d8:	466080e7          	jalr	1126(ra) # 8000483a <acquiresleep>
      return b;
    800033dc:	a8b9                	j	8000343a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033de:	0001d497          	auipc	s1,0x1d
    800033e2:	9024b483          	ld	s1,-1790(s1) # 8001fce0 <bcache+0x82b0>
    800033e6:	0001d797          	auipc	a5,0x1d
    800033ea:	8b278793          	addi	a5,a5,-1870 # 8001fc98 <bcache+0x8268>
    800033ee:	00f48863          	beq	s1,a5,800033fe <bread+0x90>
    800033f2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033f4:	40bc                	lw	a5,64(s1)
    800033f6:	cf81                	beqz	a5,8000340e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033f8:	64a4                	ld	s1,72(s1)
    800033fa:	fee49de3          	bne	s1,a4,800033f4 <bread+0x86>
  panic("bget: no buffers");
    800033fe:	00005517          	auipc	a0,0x5
    80003402:	11a50513          	addi	a0,a0,282 # 80008518 <syscalls+0xd0>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	138080e7          	jalr	312(ra) # 8000053e <panic>
      b->dev = dev;
    8000340e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003412:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003416:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000341a:	4785                	li	a5,1
    8000341c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000341e:	00014517          	auipc	a0,0x14
    80003422:	61250513          	addi	a0,a0,1554 # 80017a30 <bcache>
    80003426:	ffffe097          	auipc	ra,0xffffe
    8000342a:	872080e7          	jalr	-1934(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000342e:	01048513          	addi	a0,s1,16
    80003432:	00001097          	auipc	ra,0x1
    80003436:	408080e7          	jalr	1032(ra) # 8000483a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000343a:	409c                	lw	a5,0(s1)
    8000343c:	cb89                	beqz	a5,8000344e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000343e:	8526                	mv	a0,s1
    80003440:	70a2                	ld	ra,40(sp)
    80003442:	7402                	ld	s0,32(sp)
    80003444:	64e2                	ld	s1,24(sp)
    80003446:	6942                	ld	s2,16(sp)
    80003448:	69a2                	ld	s3,8(sp)
    8000344a:	6145                	addi	sp,sp,48
    8000344c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000344e:	4581                	li	a1,0
    80003450:	8526                	mv	a0,s1
    80003452:	00003097          	auipc	ra,0x3
    80003456:	f14080e7          	jalr	-236(ra) # 80006366 <virtio_disk_rw>
    b->valid = 1;
    8000345a:	4785                	li	a5,1
    8000345c:	c09c                	sw	a5,0(s1)
  return b;
    8000345e:	b7c5                	j	8000343e <bread+0xd0>

0000000080003460 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003460:	1101                	addi	sp,sp,-32
    80003462:	ec06                	sd	ra,24(sp)
    80003464:	e822                	sd	s0,16(sp)
    80003466:	e426                	sd	s1,8(sp)
    80003468:	1000                	addi	s0,sp,32
    8000346a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000346c:	0541                	addi	a0,a0,16
    8000346e:	00001097          	auipc	ra,0x1
    80003472:	466080e7          	jalr	1126(ra) # 800048d4 <holdingsleep>
    80003476:	cd01                	beqz	a0,8000348e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003478:	4585                	li	a1,1
    8000347a:	8526                	mv	a0,s1
    8000347c:	00003097          	auipc	ra,0x3
    80003480:	eea080e7          	jalr	-278(ra) # 80006366 <virtio_disk_rw>
}
    80003484:	60e2                	ld	ra,24(sp)
    80003486:	6442                	ld	s0,16(sp)
    80003488:	64a2                	ld	s1,8(sp)
    8000348a:	6105                	addi	sp,sp,32
    8000348c:	8082                	ret
    panic("bwrite");
    8000348e:	00005517          	auipc	a0,0x5
    80003492:	0a250513          	addi	a0,a0,162 # 80008530 <syscalls+0xe8>
    80003496:	ffffd097          	auipc	ra,0xffffd
    8000349a:	0a8080e7          	jalr	168(ra) # 8000053e <panic>

000000008000349e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000349e:	1101                	addi	sp,sp,-32
    800034a0:	ec06                	sd	ra,24(sp)
    800034a2:	e822                	sd	s0,16(sp)
    800034a4:	e426                	sd	s1,8(sp)
    800034a6:	e04a                	sd	s2,0(sp)
    800034a8:	1000                	addi	s0,sp,32
    800034aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034ac:	01050913          	addi	s2,a0,16
    800034b0:	854a                	mv	a0,s2
    800034b2:	00001097          	auipc	ra,0x1
    800034b6:	422080e7          	jalr	1058(ra) # 800048d4 <holdingsleep>
    800034ba:	c92d                	beqz	a0,8000352c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034bc:	854a                	mv	a0,s2
    800034be:	00001097          	auipc	ra,0x1
    800034c2:	3d2080e7          	jalr	978(ra) # 80004890 <releasesleep>

  acquire(&bcache.lock);
    800034c6:	00014517          	auipc	a0,0x14
    800034ca:	56a50513          	addi	a0,a0,1386 # 80017a30 <bcache>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	716080e7          	jalr	1814(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034d6:	40bc                	lw	a5,64(s1)
    800034d8:	37fd                	addiw	a5,a5,-1
    800034da:	0007871b          	sext.w	a4,a5
    800034de:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034e0:	eb05                	bnez	a4,80003510 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034e2:	68bc                	ld	a5,80(s1)
    800034e4:	64b8                	ld	a4,72(s1)
    800034e6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034e8:	64bc                	ld	a5,72(s1)
    800034ea:	68b8                	ld	a4,80(s1)
    800034ec:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034ee:	0001c797          	auipc	a5,0x1c
    800034f2:	54278793          	addi	a5,a5,1346 # 8001fa30 <bcache+0x8000>
    800034f6:	2b87b703          	ld	a4,696(a5)
    800034fa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034fc:	0001c717          	auipc	a4,0x1c
    80003500:	79c70713          	addi	a4,a4,1948 # 8001fc98 <bcache+0x8268>
    80003504:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003506:	2b87b703          	ld	a4,696(a5)
    8000350a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000350c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003510:	00014517          	auipc	a0,0x14
    80003514:	52050513          	addi	a0,a0,1312 # 80017a30 <bcache>
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	780080e7          	jalr	1920(ra) # 80000c98 <release>
}
    80003520:	60e2                	ld	ra,24(sp)
    80003522:	6442                	ld	s0,16(sp)
    80003524:	64a2                	ld	s1,8(sp)
    80003526:	6902                	ld	s2,0(sp)
    80003528:	6105                	addi	sp,sp,32
    8000352a:	8082                	ret
    panic("brelse");
    8000352c:	00005517          	auipc	a0,0x5
    80003530:	00c50513          	addi	a0,a0,12 # 80008538 <syscalls+0xf0>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	00a080e7          	jalr	10(ra) # 8000053e <panic>

000000008000353c <bpin>:

void
bpin(struct buf *b) {
    8000353c:	1101                	addi	sp,sp,-32
    8000353e:	ec06                	sd	ra,24(sp)
    80003540:	e822                	sd	s0,16(sp)
    80003542:	e426                	sd	s1,8(sp)
    80003544:	1000                	addi	s0,sp,32
    80003546:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003548:	00014517          	auipc	a0,0x14
    8000354c:	4e850513          	addi	a0,a0,1256 # 80017a30 <bcache>
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	694080e7          	jalr	1684(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003558:	40bc                	lw	a5,64(s1)
    8000355a:	2785                	addiw	a5,a5,1
    8000355c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000355e:	00014517          	auipc	a0,0x14
    80003562:	4d250513          	addi	a0,a0,1234 # 80017a30 <bcache>
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	732080e7          	jalr	1842(ra) # 80000c98 <release>
}
    8000356e:	60e2                	ld	ra,24(sp)
    80003570:	6442                	ld	s0,16(sp)
    80003572:	64a2                	ld	s1,8(sp)
    80003574:	6105                	addi	sp,sp,32
    80003576:	8082                	ret

0000000080003578 <bunpin>:

void
bunpin(struct buf *b) {
    80003578:	1101                	addi	sp,sp,-32
    8000357a:	ec06                	sd	ra,24(sp)
    8000357c:	e822                	sd	s0,16(sp)
    8000357e:	e426                	sd	s1,8(sp)
    80003580:	1000                	addi	s0,sp,32
    80003582:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003584:	00014517          	auipc	a0,0x14
    80003588:	4ac50513          	addi	a0,a0,1196 # 80017a30 <bcache>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	658080e7          	jalr	1624(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003594:	40bc                	lw	a5,64(s1)
    80003596:	37fd                	addiw	a5,a5,-1
    80003598:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000359a:	00014517          	auipc	a0,0x14
    8000359e:	49650513          	addi	a0,a0,1174 # 80017a30 <bcache>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	6f6080e7          	jalr	1782(ra) # 80000c98 <release>
}
    800035aa:	60e2                	ld	ra,24(sp)
    800035ac:	6442                	ld	s0,16(sp)
    800035ae:	64a2                	ld	s1,8(sp)
    800035b0:	6105                	addi	sp,sp,32
    800035b2:	8082                	ret

00000000800035b4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035b4:	1101                	addi	sp,sp,-32
    800035b6:	ec06                	sd	ra,24(sp)
    800035b8:	e822                	sd	s0,16(sp)
    800035ba:	e426                	sd	s1,8(sp)
    800035bc:	e04a                	sd	s2,0(sp)
    800035be:	1000                	addi	s0,sp,32
    800035c0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035c2:	00d5d59b          	srliw	a1,a1,0xd
    800035c6:	0001d797          	auipc	a5,0x1d
    800035ca:	b467a783          	lw	a5,-1210(a5) # 8002010c <sb+0x1c>
    800035ce:	9dbd                	addw	a1,a1,a5
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	d9e080e7          	jalr	-610(ra) # 8000336e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035d8:	0074f713          	andi	a4,s1,7
    800035dc:	4785                	li	a5,1
    800035de:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035e2:	14ce                	slli	s1,s1,0x33
    800035e4:	90d9                	srli	s1,s1,0x36
    800035e6:	00950733          	add	a4,a0,s1
    800035ea:	05874703          	lbu	a4,88(a4)
    800035ee:	00e7f6b3          	and	a3,a5,a4
    800035f2:	c69d                	beqz	a3,80003620 <bfree+0x6c>
    800035f4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035f6:	94aa                	add	s1,s1,a0
    800035f8:	fff7c793          	not	a5,a5
    800035fc:	8ff9                	and	a5,a5,a4
    800035fe:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003602:	00001097          	auipc	ra,0x1
    80003606:	118080e7          	jalr	280(ra) # 8000471a <log_write>
  brelse(bp);
    8000360a:	854a                	mv	a0,s2
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	e92080e7          	jalr	-366(ra) # 8000349e <brelse>
}
    80003614:	60e2                	ld	ra,24(sp)
    80003616:	6442                	ld	s0,16(sp)
    80003618:	64a2                	ld	s1,8(sp)
    8000361a:	6902                	ld	s2,0(sp)
    8000361c:	6105                	addi	sp,sp,32
    8000361e:	8082                	ret
    panic("freeing free block");
    80003620:	00005517          	auipc	a0,0x5
    80003624:	f2050513          	addi	a0,a0,-224 # 80008540 <syscalls+0xf8>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	f16080e7          	jalr	-234(ra) # 8000053e <panic>

0000000080003630 <balloc>:
{
    80003630:	711d                	addi	sp,sp,-96
    80003632:	ec86                	sd	ra,88(sp)
    80003634:	e8a2                	sd	s0,80(sp)
    80003636:	e4a6                	sd	s1,72(sp)
    80003638:	e0ca                	sd	s2,64(sp)
    8000363a:	fc4e                	sd	s3,56(sp)
    8000363c:	f852                	sd	s4,48(sp)
    8000363e:	f456                	sd	s5,40(sp)
    80003640:	f05a                	sd	s6,32(sp)
    80003642:	ec5e                	sd	s7,24(sp)
    80003644:	e862                	sd	s8,16(sp)
    80003646:	e466                	sd	s9,8(sp)
    80003648:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000364a:	0001d797          	auipc	a5,0x1d
    8000364e:	aaa7a783          	lw	a5,-1366(a5) # 800200f4 <sb+0x4>
    80003652:	cbd1                	beqz	a5,800036e6 <balloc+0xb6>
    80003654:	8baa                	mv	s7,a0
    80003656:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003658:	0001db17          	auipc	s6,0x1d
    8000365c:	a98b0b13          	addi	s6,s6,-1384 # 800200f0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003660:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003662:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003664:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003666:	6c89                	lui	s9,0x2
    80003668:	a831                	j	80003684 <balloc+0x54>
    brelse(bp);
    8000366a:	854a                	mv	a0,s2
    8000366c:	00000097          	auipc	ra,0x0
    80003670:	e32080e7          	jalr	-462(ra) # 8000349e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003674:	015c87bb          	addw	a5,s9,s5
    80003678:	00078a9b          	sext.w	s5,a5
    8000367c:	004b2703          	lw	a4,4(s6)
    80003680:	06eaf363          	bgeu	s5,a4,800036e6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003684:	41fad79b          	sraiw	a5,s5,0x1f
    80003688:	0137d79b          	srliw	a5,a5,0x13
    8000368c:	015787bb          	addw	a5,a5,s5
    80003690:	40d7d79b          	sraiw	a5,a5,0xd
    80003694:	01cb2583          	lw	a1,28(s6)
    80003698:	9dbd                	addw	a1,a1,a5
    8000369a:	855e                	mv	a0,s7
    8000369c:	00000097          	auipc	ra,0x0
    800036a0:	cd2080e7          	jalr	-814(ra) # 8000336e <bread>
    800036a4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036a6:	004b2503          	lw	a0,4(s6)
    800036aa:	000a849b          	sext.w	s1,s5
    800036ae:	8662                	mv	a2,s8
    800036b0:	faa4fde3          	bgeu	s1,a0,8000366a <balloc+0x3a>
      m = 1 << (bi % 8);
    800036b4:	41f6579b          	sraiw	a5,a2,0x1f
    800036b8:	01d7d69b          	srliw	a3,a5,0x1d
    800036bc:	00c6873b          	addw	a4,a3,a2
    800036c0:	00777793          	andi	a5,a4,7
    800036c4:	9f95                	subw	a5,a5,a3
    800036c6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036ca:	4037571b          	sraiw	a4,a4,0x3
    800036ce:	00e906b3          	add	a3,s2,a4
    800036d2:	0586c683          	lbu	a3,88(a3)
    800036d6:	00d7f5b3          	and	a1,a5,a3
    800036da:	cd91                	beqz	a1,800036f6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036dc:	2605                	addiw	a2,a2,1
    800036de:	2485                	addiw	s1,s1,1
    800036e0:	fd4618e3          	bne	a2,s4,800036b0 <balloc+0x80>
    800036e4:	b759                	j	8000366a <balloc+0x3a>
  panic("balloc: out of blocks");
    800036e6:	00005517          	auipc	a0,0x5
    800036ea:	e7250513          	addi	a0,a0,-398 # 80008558 <syscalls+0x110>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	e50080e7          	jalr	-432(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036f6:	974a                	add	a4,a4,s2
    800036f8:	8fd5                	or	a5,a5,a3
    800036fa:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036fe:	854a                	mv	a0,s2
    80003700:	00001097          	auipc	ra,0x1
    80003704:	01a080e7          	jalr	26(ra) # 8000471a <log_write>
        brelse(bp);
    80003708:	854a                	mv	a0,s2
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	d94080e7          	jalr	-620(ra) # 8000349e <brelse>
  bp = bread(dev, bno);
    80003712:	85a6                	mv	a1,s1
    80003714:	855e                	mv	a0,s7
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	c58080e7          	jalr	-936(ra) # 8000336e <bread>
    8000371e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003720:	40000613          	li	a2,1024
    80003724:	4581                	li	a1,0
    80003726:	05850513          	addi	a0,a0,88
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	5b6080e7          	jalr	1462(ra) # 80000ce0 <memset>
  log_write(bp);
    80003732:	854a                	mv	a0,s2
    80003734:	00001097          	auipc	ra,0x1
    80003738:	fe6080e7          	jalr	-26(ra) # 8000471a <log_write>
  brelse(bp);
    8000373c:	854a                	mv	a0,s2
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	d60080e7          	jalr	-672(ra) # 8000349e <brelse>
}
    80003746:	8526                	mv	a0,s1
    80003748:	60e6                	ld	ra,88(sp)
    8000374a:	6446                	ld	s0,80(sp)
    8000374c:	64a6                	ld	s1,72(sp)
    8000374e:	6906                	ld	s2,64(sp)
    80003750:	79e2                	ld	s3,56(sp)
    80003752:	7a42                	ld	s4,48(sp)
    80003754:	7aa2                	ld	s5,40(sp)
    80003756:	7b02                	ld	s6,32(sp)
    80003758:	6be2                	ld	s7,24(sp)
    8000375a:	6c42                	ld	s8,16(sp)
    8000375c:	6ca2                	ld	s9,8(sp)
    8000375e:	6125                	addi	sp,sp,96
    80003760:	8082                	ret

0000000080003762 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003762:	7179                	addi	sp,sp,-48
    80003764:	f406                	sd	ra,40(sp)
    80003766:	f022                	sd	s0,32(sp)
    80003768:	ec26                	sd	s1,24(sp)
    8000376a:	e84a                	sd	s2,16(sp)
    8000376c:	e44e                	sd	s3,8(sp)
    8000376e:	e052                	sd	s4,0(sp)
    80003770:	1800                	addi	s0,sp,48
    80003772:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003774:	47ad                	li	a5,11
    80003776:	04b7fe63          	bgeu	a5,a1,800037d2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000377a:	ff45849b          	addiw	s1,a1,-12
    8000377e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003782:	0ff00793          	li	a5,255
    80003786:	0ae7e363          	bltu	a5,a4,8000382c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000378a:	08052583          	lw	a1,128(a0)
    8000378e:	c5ad                	beqz	a1,800037f8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003790:	00092503          	lw	a0,0(s2)
    80003794:	00000097          	auipc	ra,0x0
    80003798:	bda080e7          	jalr	-1062(ra) # 8000336e <bread>
    8000379c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000379e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037a2:	02049593          	slli	a1,s1,0x20
    800037a6:	9181                	srli	a1,a1,0x20
    800037a8:	058a                	slli	a1,a1,0x2
    800037aa:	00b784b3          	add	s1,a5,a1
    800037ae:	0004a983          	lw	s3,0(s1)
    800037b2:	04098d63          	beqz	s3,8000380c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037b6:	8552                	mv	a0,s4
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	ce6080e7          	jalr	-794(ra) # 8000349e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037c0:	854e                	mv	a0,s3
    800037c2:	70a2                	ld	ra,40(sp)
    800037c4:	7402                	ld	s0,32(sp)
    800037c6:	64e2                	ld	s1,24(sp)
    800037c8:	6942                	ld	s2,16(sp)
    800037ca:	69a2                	ld	s3,8(sp)
    800037cc:	6a02                	ld	s4,0(sp)
    800037ce:	6145                	addi	sp,sp,48
    800037d0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037d2:	02059493          	slli	s1,a1,0x20
    800037d6:	9081                	srli	s1,s1,0x20
    800037d8:	048a                	slli	s1,s1,0x2
    800037da:	94aa                	add	s1,s1,a0
    800037dc:	0504a983          	lw	s3,80(s1)
    800037e0:	fe0990e3          	bnez	s3,800037c0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037e4:	4108                	lw	a0,0(a0)
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	e4a080e7          	jalr	-438(ra) # 80003630 <balloc>
    800037ee:	0005099b          	sext.w	s3,a0
    800037f2:	0534a823          	sw	s3,80(s1)
    800037f6:	b7e9                	j	800037c0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800037f8:	4108                	lw	a0,0(a0)
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	e36080e7          	jalr	-458(ra) # 80003630 <balloc>
    80003802:	0005059b          	sext.w	a1,a0
    80003806:	08b92023          	sw	a1,128(s2)
    8000380a:	b759                	j	80003790 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000380c:	00092503          	lw	a0,0(s2)
    80003810:	00000097          	auipc	ra,0x0
    80003814:	e20080e7          	jalr	-480(ra) # 80003630 <balloc>
    80003818:	0005099b          	sext.w	s3,a0
    8000381c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003820:	8552                	mv	a0,s4
    80003822:	00001097          	auipc	ra,0x1
    80003826:	ef8080e7          	jalr	-264(ra) # 8000471a <log_write>
    8000382a:	b771                	j	800037b6 <bmap+0x54>
  panic("bmap: out of range");
    8000382c:	00005517          	auipc	a0,0x5
    80003830:	d4450513          	addi	a0,a0,-700 # 80008570 <syscalls+0x128>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	d0a080e7          	jalr	-758(ra) # 8000053e <panic>

000000008000383c <iget>:
{
    8000383c:	7179                	addi	sp,sp,-48
    8000383e:	f406                	sd	ra,40(sp)
    80003840:	f022                	sd	s0,32(sp)
    80003842:	ec26                	sd	s1,24(sp)
    80003844:	e84a                	sd	s2,16(sp)
    80003846:	e44e                	sd	s3,8(sp)
    80003848:	e052                	sd	s4,0(sp)
    8000384a:	1800                	addi	s0,sp,48
    8000384c:	89aa                	mv	s3,a0
    8000384e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003850:	0001d517          	auipc	a0,0x1d
    80003854:	8c050513          	addi	a0,a0,-1856 # 80020110 <itable>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	38c080e7          	jalr	908(ra) # 80000be4 <acquire>
  empty = 0;
    80003860:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003862:	0001d497          	auipc	s1,0x1d
    80003866:	8c648493          	addi	s1,s1,-1850 # 80020128 <itable+0x18>
    8000386a:	0001e697          	auipc	a3,0x1e
    8000386e:	34e68693          	addi	a3,a3,846 # 80021bb8 <log>
    80003872:	a039                	j	80003880 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003874:	02090b63          	beqz	s2,800038aa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003878:	08848493          	addi	s1,s1,136
    8000387c:	02d48a63          	beq	s1,a3,800038b0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003880:	449c                	lw	a5,8(s1)
    80003882:	fef059e3          	blez	a5,80003874 <iget+0x38>
    80003886:	4098                	lw	a4,0(s1)
    80003888:	ff3716e3          	bne	a4,s3,80003874 <iget+0x38>
    8000388c:	40d8                	lw	a4,4(s1)
    8000388e:	ff4713e3          	bne	a4,s4,80003874 <iget+0x38>
      ip->ref++;
    80003892:	2785                	addiw	a5,a5,1
    80003894:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003896:	0001d517          	auipc	a0,0x1d
    8000389a:	87a50513          	addi	a0,a0,-1926 # 80020110 <itable>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	3fa080e7          	jalr	1018(ra) # 80000c98 <release>
      return ip;
    800038a6:	8926                	mv	s2,s1
    800038a8:	a03d                	j	800038d6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038aa:	f7f9                	bnez	a5,80003878 <iget+0x3c>
    800038ac:	8926                	mv	s2,s1
    800038ae:	b7e9                	j	80003878 <iget+0x3c>
  if(empty == 0)
    800038b0:	02090c63          	beqz	s2,800038e8 <iget+0xac>
  ip->dev = dev;
    800038b4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038b8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038bc:	4785                	li	a5,1
    800038be:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038c2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038c6:	0001d517          	auipc	a0,0x1d
    800038ca:	84a50513          	addi	a0,a0,-1974 # 80020110 <itable>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	3ca080e7          	jalr	970(ra) # 80000c98 <release>
}
    800038d6:	854a                	mv	a0,s2
    800038d8:	70a2                	ld	ra,40(sp)
    800038da:	7402                	ld	s0,32(sp)
    800038dc:	64e2                	ld	s1,24(sp)
    800038de:	6942                	ld	s2,16(sp)
    800038e0:	69a2                	ld	s3,8(sp)
    800038e2:	6a02                	ld	s4,0(sp)
    800038e4:	6145                	addi	sp,sp,48
    800038e6:	8082                	ret
    panic("iget: no inodes");
    800038e8:	00005517          	auipc	a0,0x5
    800038ec:	ca050513          	addi	a0,a0,-864 # 80008588 <syscalls+0x140>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	c4e080e7          	jalr	-946(ra) # 8000053e <panic>

00000000800038f8 <fsinit>:
fsinit(int dev) {
    800038f8:	7179                	addi	sp,sp,-48
    800038fa:	f406                	sd	ra,40(sp)
    800038fc:	f022                	sd	s0,32(sp)
    800038fe:	ec26                	sd	s1,24(sp)
    80003900:	e84a                	sd	s2,16(sp)
    80003902:	e44e                	sd	s3,8(sp)
    80003904:	1800                	addi	s0,sp,48
    80003906:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003908:	4585                	li	a1,1
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	a64080e7          	jalr	-1436(ra) # 8000336e <bread>
    80003912:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003914:	0001c997          	auipc	s3,0x1c
    80003918:	7dc98993          	addi	s3,s3,2012 # 800200f0 <sb>
    8000391c:	02000613          	li	a2,32
    80003920:	05850593          	addi	a1,a0,88
    80003924:	854e                	mv	a0,s3
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	41a080e7          	jalr	1050(ra) # 80000d40 <memmove>
  brelse(bp);
    8000392e:	8526                	mv	a0,s1
    80003930:	00000097          	auipc	ra,0x0
    80003934:	b6e080e7          	jalr	-1170(ra) # 8000349e <brelse>
  if(sb.magic != FSMAGIC)
    80003938:	0009a703          	lw	a4,0(s3)
    8000393c:	102037b7          	lui	a5,0x10203
    80003940:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003944:	02f71263          	bne	a4,a5,80003968 <fsinit+0x70>
  initlog(dev, &sb);
    80003948:	0001c597          	auipc	a1,0x1c
    8000394c:	7a858593          	addi	a1,a1,1960 # 800200f0 <sb>
    80003950:	854a                	mv	a0,s2
    80003952:	00001097          	auipc	ra,0x1
    80003956:	b4c080e7          	jalr	-1204(ra) # 8000449e <initlog>
}
    8000395a:	70a2                	ld	ra,40(sp)
    8000395c:	7402                	ld	s0,32(sp)
    8000395e:	64e2                	ld	s1,24(sp)
    80003960:	6942                	ld	s2,16(sp)
    80003962:	69a2                	ld	s3,8(sp)
    80003964:	6145                	addi	sp,sp,48
    80003966:	8082                	ret
    panic("invalid file system");
    80003968:	00005517          	auipc	a0,0x5
    8000396c:	c3050513          	addi	a0,a0,-976 # 80008598 <syscalls+0x150>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>

0000000080003978 <iinit>:
{
    80003978:	7179                	addi	sp,sp,-48
    8000397a:	f406                	sd	ra,40(sp)
    8000397c:	f022                	sd	s0,32(sp)
    8000397e:	ec26                	sd	s1,24(sp)
    80003980:	e84a                	sd	s2,16(sp)
    80003982:	e44e                	sd	s3,8(sp)
    80003984:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003986:	00005597          	auipc	a1,0x5
    8000398a:	c2a58593          	addi	a1,a1,-982 # 800085b0 <syscalls+0x168>
    8000398e:	0001c517          	auipc	a0,0x1c
    80003992:	78250513          	addi	a0,a0,1922 # 80020110 <itable>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	1be080e7          	jalr	446(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000399e:	0001c497          	auipc	s1,0x1c
    800039a2:	79a48493          	addi	s1,s1,1946 # 80020138 <itable+0x28>
    800039a6:	0001e997          	auipc	s3,0x1e
    800039aa:	22298993          	addi	s3,s3,546 # 80021bc8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039ae:	00005917          	auipc	s2,0x5
    800039b2:	c0a90913          	addi	s2,s2,-1014 # 800085b8 <syscalls+0x170>
    800039b6:	85ca                	mv	a1,s2
    800039b8:	8526                	mv	a0,s1
    800039ba:	00001097          	auipc	ra,0x1
    800039be:	e46080e7          	jalr	-442(ra) # 80004800 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039c2:	08848493          	addi	s1,s1,136
    800039c6:	ff3498e3          	bne	s1,s3,800039b6 <iinit+0x3e>
}
    800039ca:	70a2                	ld	ra,40(sp)
    800039cc:	7402                	ld	s0,32(sp)
    800039ce:	64e2                	ld	s1,24(sp)
    800039d0:	6942                	ld	s2,16(sp)
    800039d2:	69a2                	ld	s3,8(sp)
    800039d4:	6145                	addi	sp,sp,48
    800039d6:	8082                	ret

00000000800039d8 <ialloc>:
{
    800039d8:	715d                	addi	sp,sp,-80
    800039da:	e486                	sd	ra,72(sp)
    800039dc:	e0a2                	sd	s0,64(sp)
    800039de:	fc26                	sd	s1,56(sp)
    800039e0:	f84a                	sd	s2,48(sp)
    800039e2:	f44e                	sd	s3,40(sp)
    800039e4:	f052                	sd	s4,32(sp)
    800039e6:	ec56                	sd	s5,24(sp)
    800039e8:	e85a                	sd	s6,16(sp)
    800039ea:	e45e                	sd	s7,8(sp)
    800039ec:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039ee:	0001c717          	auipc	a4,0x1c
    800039f2:	70e72703          	lw	a4,1806(a4) # 800200fc <sb+0xc>
    800039f6:	4785                	li	a5,1
    800039f8:	04e7fa63          	bgeu	a5,a4,80003a4c <ialloc+0x74>
    800039fc:	8aaa                	mv	s5,a0
    800039fe:	8bae                	mv	s7,a1
    80003a00:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a02:	0001ca17          	auipc	s4,0x1c
    80003a06:	6eea0a13          	addi	s4,s4,1774 # 800200f0 <sb>
    80003a0a:	00048b1b          	sext.w	s6,s1
    80003a0e:	0044d593          	srli	a1,s1,0x4
    80003a12:	018a2783          	lw	a5,24(s4)
    80003a16:	9dbd                	addw	a1,a1,a5
    80003a18:	8556                	mv	a0,s5
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	954080e7          	jalr	-1708(ra) # 8000336e <bread>
    80003a22:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a24:	05850993          	addi	s3,a0,88
    80003a28:	00f4f793          	andi	a5,s1,15
    80003a2c:	079a                	slli	a5,a5,0x6
    80003a2e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a30:	00099783          	lh	a5,0(s3)
    80003a34:	c785                	beqz	a5,80003a5c <ialloc+0x84>
    brelse(bp);
    80003a36:	00000097          	auipc	ra,0x0
    80003a3a:	a68080e7          	jalr	-1432(ra) # 8000349e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a3e:	0485                	addi	s1,s1,1
    80003a40:	00ca2703          	lw	a4,12(s4)
    80003a44:	0004879b          	sext.w	a5,s1
    80003a48:	fce7e1e3          	bltu	a5,a4,80003a0a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a4c:	00005517          	auipc	a0,0x5
    80003a50:	b7450513          	addi	a0,a0,-1164 # 800085c0 <syscalls+0x178>
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	aea080e7          	jalr	-1302(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a5c:	04000613          	li	a2,64
    80003a60:	4581                	li	a1,0
    80003a62:	854e                	mv	a0,s3
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	27c080e7          	jalr	636(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a6c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a70:	854a                	mv	a0,s2
    80003a72:	00001097          	auipc	ra,0x1
    80003a76:	ca8080e7          	jalr	-856(ra) # 8000471a <log_write>
      brelse(bp);
    80003a7a:	854a                	mv	a0,s2
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	a22080e7          	jalr	-1502(ra) # 8000349e <brelse>
      return iget(dev, inum);
    80003a84:	85da                	mv	a1,s6
    80003a86:	8556                	mv	a0,s5
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	db4080e7          	jalr	-588(ra) # 8000383c <iget>
}
    80003a90:	60a6                	ld	ra,72(sp)
    80003a92:	6406                	ld	s0,64(sp)
    80003a94:	74e2                	ld	s1,56(sp)
    80003a96:	7942                	ld	s2,48(sp)
    80003a98:	79a2                	ld	s3,40(sp)
    80003a9a:	7a02                	ld	s4,32(sp)
    80003a9c:	6ae2                	ld	s5,24(sp)
    80003a9e:	6b42                	ld	s6,16(sp)
    80003aa0:	6ba2                	ld	s7,8(sp)
    80003aa2:	6161                	addi	sp,sp,80
    80003aa4:	8082                	ret

0000000080003aa6 <iupdate>:
{
    80003aa6:	1101                	addi	sp,sp,-32
    80003aa8:	ec06                	sd	ra,24(sp)
    80003aaa:	e822                	sd	s0,16(sp)
    80003aac:	e426                	sd	s1,8(sp)
    80003aae:	e04a                	sd	s2,0(sp)
    80003ab0:	1000                	addi	s0,sp,32
    80003ab2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ab4:	415c                	lw	a5,4(a0)
    80003ab6:	0047d79b          	srliw	a5,a5,0x4
    80003aba:	0001c597          	auipc	a1,0x1c
    80003abe:	64e5a583          	lw	a1,1614(a1) # 80020108 <sb+0x18>
    80003ac2:	9dbd                	addw	a1,a1,a5
    80003ac4:	4108                	lw	a0,0(a0)
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	8a8080e7          	jalr	-1880(ra) # 8000336e <bread>
    80003ace:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ad0:	05850793          	addi	a5,a0,88
    80003ad4:	40c8                	lw	a0,4(s1)
    80003ad6:	893d                	andi	a0,a0,15
    80003ad8:	051a                	slli	a0,a0,0x6
    80003ada:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003adc:	04449703          	lh	a4,68(s1)
    80003ae0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ae4:	04649703          	lh	a4,70(s1)
    80003ae8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003aec:	04849703          	lh	a4,72(s1)
    80003af0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003af4:	04a49703          	lh	a4,74(s1)
    80003af8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003afc:	44f8                	lw	a4,76(s1)
    80003afe:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b00:	03400613          	li	a2,52
    80003b04:	05048593          	addi	a1,s1,80
    80003b08:	0531                	addi	a0,a0,12
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	236080e7          	jalr	566(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b12:	854a                	mv	a0,s2
    80003b14:	00001097          	auipc	ra,0x1
    80003b18:	c06080e7          	jalr	-1018(ra) # 8000471a <log_write>
  brelse(bp);
    80003b1c:	854a                	mv	a0,s2
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	980080e7          	jalr	-1664(ra) # 8000349e <brelse>
}
    80003b26:	60e2                	ld	ra,24(sp)
    80003b28:	6442                	ld	s0,16(sp)
    80003b2a:	64a2                	ld	s1,8(sp)
    80003b2c:	6902                	ld	s2,0(sp)
    80003b2e:	6105                	addi	sp,sp,32
    80003b30:	8082                	ret

0000000080003b32 <idup>:
{
    80003b32:	1101                	addi	sp,sp,-32
    80003b34:	ec06                	sd	ra,24(sp)
    80003b36:	e822                	sd	s0,16(sp)
    80003b38:	e426                	sd	s1,8(sp)
    80003b3a:	1000                	addi	s0,sp,32
    80003b3c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b3e:	0001c517          	auipc	a0,0x1c
    80003b42:	5d250513          	addi	a0,a0,1490 # 80020110 <itable>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	09e080e7          	jalr	158(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b4e:	449c                	lw	a5,8(s1)
    80003b50:	2785                	addiw	a5,a5,1
    80003b52:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b54:	0001c517          	auipc	a0,0x1c
    80003b58:	5bc50513          	addi	a0,a0,1468 # 80020110 <itable>
    80003b5c:	ffffd097          	auipc	ra,0xffffd
    80003b60:	13c080e7          	jalr	316(ra) # 80000c98 <release>
}
    80003b64:	8526                	mv	a0,s1
    80003b66:	60e2                	ld	ra,24(sp)
    80003b68:	6442                	ld	s0,16(sp)
    80003b6a:	64a2                	ld	s1,8(sp)
    80003b6c:	6105                	addi	sp,sp,32
    80003b6e:	8082                	ret

0000000080003b70 <ilock>:
{
    80003b70:	1101                	addi	sp,sp,-32
    80003b72:	ec06                	sd	ra,24(sp)
    80003b74:	e822                	sd	s0,16(sp)
    80003b76:	e426                	sd	s1,8(sp)
    80003b78:	e04a                	sd	s2,0(sp)
    80003b7a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b7c:	c115                	beqz	a0,80003ba0 <ilock+0x30>
    80003b7e:	84aa                	mv	s1,a0
    80003b80:	451c                	lw	a5,8(a0)
    80003b82:	00f05f63          	blez	a5,80003ba0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b86:	0541                	addi	a0,a0,16
    80003b88:	00001097          	auipc	ra,0x1
    80003b8c:	cb2080e7          	jalr	-846(ra) # 8000483a <acquiresleep>
  if(ip->valid == 0){
    80003b90:	40bc                	lw	a5,64(s1)
    80003b92:	cf99                	beqz	a5,80003bb0 <ilock+0x40>
}
    80003b94:	60e2                	ld	ra,24(sp)
    80003b96:	6442                	ld	s0,16(sp)
    80003b98:	64a2                	ld	s1,8(sp)
    80003b9a:	6902                	ld	s2,0(sp)
    80003b9c:	6105                	addi	sp,sp,32
    80003b9e:	8082                	ret
    panic("ilock");
    80003ba0:	00005517          	auipc	a0,0x5
    80003ba4:	a3850513          	addi	a0,a0,-1480 # 800085d8 <syscalls+0x190>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	996080e7          	jalr	-1642(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bb0:	40dc                	lw	a5,4(s1)
    80003bb2:	0047d79b          	srliw	a5,a5,0x4
    80003bb6:	0001c597          	auipc	a1,0x1c
    80003bba:	5525a583          	lw	a1,1362(a1) # 80020108 <sb+0x18>
    80003bbe:	9dbd                	addw	a1,a1,a5
    80003bc0:	4088                	lw	a0,0(s1)
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	7ac080e7          	jalr	1964(ra) # 8000336e <bread>
    80003bca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bcc:	05850593          	addi	a1,a0,88
    80003bd0:	40dc                	lw	a5,4(s1)
    80003bd2:	8bbd                	andi	a5,a5,15
    80003bd4:	079a                	slli	a5,a5,0x6
    80003bd6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bd8:	00059783          	lh	a5,0(a1)
    80003bdc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003be0:	00259783          	lh	a5,2(a1)
    80003be4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003be8:	00459783          	lh	a5,4(a1)
    80003bec:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003bf0:	00659783          	lh	a5,6(a1)
    80003bf4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bf8:	459c                	lw	a5,8(a1)
    80003bfa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bfc:	03400613          	li	a2,52
    80003c00:	05b1                	addi	a1,a1,12
    80003c02:	05048513          	addi	a0,s1,80
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	13a080e7          	jalr	314(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c0e:	854a                	mv	a0,s2
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	88e080e7          	jalr	-1906(ra) # 8000349e <brelse>
    ip->valid = 1;
    80003c18:	4785                	li	a5,1
    80003c1a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c1c:	04449783          	lh	a5,68(s1)
    80003c20:	fbb5                	bnez	a5,80003b94 <ilock+0x24>
      panic("ilock: no type");
    80003c22:	00005517          	auipc	a0,0x5
    80003c26:	9be50513          	addi	a0,a0,-1602 # 800085e0 <syscalls+0x198>
    80003c2a:	ffffd097          	auipc	ra,0xffffd
    80003c2e:	914080e7          	jalr	-1772(ra) # 8000053e <panic>

0000000080003c32 <iunlock>:
{
    80003c32:	1101                	addi	sp,sp,-32
    80003c34:	ec06                	sd	ra,24(sp)
    80003c36:	e822                	sd	s0,16(sp)
    80003c38:	e426                	sd	s1,8(sp)
    80003c3a:	e04a                	sd	s2,0(sp)
    80003c3c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c3e:	c905                	beqz	a0,80003c6e <iunlock+0x3c>
    80003c40:	84aa                	mv	s1,a0
    80003c42:	01050913          	addi	s2,a0,16
    80003c46:	854a                	mv	a0,s2
    80003c48:	00001097          	auipc	ra,0x1
    80003c4c:	c8c080e7          	jalr	-884(ra) # 800048d4 <holdingsleep>
    80003c50:	cd19                	beqz	a0,80003c6e <iunlock+0x3c>
    80003c52:	449c                	lw	a5,8(s1)
    80003c54:	00f05d63          	blez	a5,80003c6e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c58:	854a                	mv	a0,s2
    80003c5a:	00001097          	auipc	ra,0x1
    80003c5e:	c36080e7          	jalr	-970(ra) # 80004890 <releasesleep>
}
    80003c62:	60e2                	ld	ra,24(sp)
    80003c64:	6442                	ld	s0,16(sp)
    80003c66:	64a2                	ld	s1,8(sp)
    80003c68:	6902                	ld	s2,0(sp)
    80003c6a:	6105                	addi	sp,sp,32
    80003c6c:	8082                	ret
    panic("iunlock");
    80003c6e:	00005517          	auipc	a0,0x5
    80003c72:	98250513          	addi	a0,a0,-1662 # 800085f0 <syscalls+0x1a8>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	8c8080e7          	jalr	-1848(ra) # 8000053e <panic>

0000000080003c7e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c7e:	7179                	addi	sp,sp,-48
    80003c80:	f406                	sd	ra,40(sp)
    80003c82:	f022                	sd	s0,32(sp)
    80003c84:	ec26                	sd	s1,24(sp)
    80003c86:	e84a                	sd	s2,16(sp)
    80003c88:	e44e                	sd	s3,8(sp)
    80003c8a:	e052                	sd	s4,0(sp)
    80003c8c:	1800                	addi	s0,sp,48
    80003c8e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c90:	05050493          	addi	s1,a0,80
    80003c94:	08050913          	addi	s2,a0,128
    80003c98:	a021                	j	80003ca0 <itrunc+0x22>
    80003c9a:	0491                	addi	s1,s1,4
    80003c9c:	01248d63          	beq	s1,s2,80003cb6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ca0:	408c                	lw	a1,0(s1)
    80003ca2:	dde5                	beqz	a1,80003c9a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ca4:	0009a503          	lw	a0,0(s3)
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	90c080e7          	jalr	-1780(ra) # 800035b4 <bfree>
      ip->addrs[i] = 0;
    80003cb0:	0004a023          	sw	zero,0(s1)
    80003cb4:	b7dd                	j	80003c9a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cb6:	0809a583          	lw	a1,128(s3)
    80003cba:	e185                	bnez	a1,80003cda <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cbc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cc0:	854e                	mv	a0,s3
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	de4080e7          	jalr	-540(ra) # 80003aa6 <iupdate>
}
    80003cca:	70a2                	ld	ra,40(sp)
    80003ccc:	7402                	ld	s0,32(sp)
    80003cce:	64e2                	ld	s1,24(sp)
    80003cd0:	6942                	ld	s2,16(sp)
    80003cd2:	69a2                	ld	s3,8(sp)
    80003cd4:	6a02                	ld	s4,0(sp)
    80003cd6:	6145                	addi	sp,sp,48
    80003cd8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cda:	0009a503          	lw	a0,0(s3)
    80003cde:	fffff097          	auipc	ra,0xfffff
    80003ce2:	690080e7          	jalr	1680(ra) # 8000336e <bread>
    80003ce6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ce8:	05850493          	addi	s1,a0,88
    80003cec:	45850913          	addi	s2,a0,1112
    80003cf0:	a811                	j	80003d04 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003cf2:	0009a503          	lw	a0,0(s3)
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	8be080e7          	jalr	-1858(ra) # 800035b4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003cfe:	0491                	addi	s1,s1,4
    80003d00:	01248563          	beq	s1,s2,80003d0a <itrunc+0x8c>
      if(a[j])
    80003d04:	408c                	lw	a1,0(s1)
    80003d06:	dde5                	beqz	a1,80003cfe <itrunc+0x80>
    80003d08:	b7ed                	j	80003cf2 <itrunc+0x74>
    brelse(bp);
    80003d0a:	8552                	mv	a0,s4
    80003d0c:	fffff097          	auipc	ra,0xfffff
    80003d10:	792080e7          	jalr	1938(ra) # 8000349e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d14:	0809a583          	lw	a1,128(s3)
    80003d18:	0009a503          	lw	a0,0(s3)
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	898080e7          	jalr	-1896(ra) # 800035b4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d24:	0809a023          	sw	zero,128(s3)
    80003d28:	bf51                	j	80003cbc <itrunc+0x3e>

0000000080003d2a <iput>:
{
    80003d2a:	1101                	addi	sp,sp,-32
    80003d2c:	ec06                	sd	ra,24(sp)
    80003d2e:	e822                	sd	s0,16(sp)
    80003d30:	e426                	sd	s1,8(sp)
    80003d32:	e04a                	sd	s2,0(sp)
    80003d34:	1000                	addi	s0,sp,32
    80003d36:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d38:	0001c517          	auipc	a0,0x1c
    80003d3c:	3d850513          	addi	a0,a0,984 # 80020110 <itable>
    80003d40:	ffffd097          	auipc	ra,0xffffd
    80003d44:	ea4080e7          	jalr	-348(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d48:	4498                	lw	a4,8(s1)
    80003d4a:	4785                	li	a5,1
    80003d4c:	02f70363          	beq	a4,a5,80003d72 <iput+0x48>
  ip->ref--;
    80003d50:	449c                	lw	a5,8(s1)
    80003d52:	37fd                	addiw	a5,a5,-1
    80003d54:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d56:	0001c517          	auipc	a0,0x1c
    80003d5a:	3ba50513          	addi	a0,a0,954 # 80020110 <itable>
    80003d5e:	ffffd097          	auipc	ra,0xffffd
    80003d62:	f3a080e7          	jalr	-198(ra) # 80000c98 <release>
}
    80003d66:	60e2                	ld	ra,24(sp)
    80003d68:	6442                	ld	s0,16(sp)
    80003d6a:	64a2                	ld	s1,8(sp)
    80003d6c:	6902                	ld	s2,0(sp)
    80003d6e:	6105                	addi	sp,sp,32
    80003d70:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d72:	40bc                	lw	a5,64(s1)
    80003d74:	dff1                	beqz	a5,80003d50 <iput+0x26>
    80003d76:	04a49783          	lh	a5,74(s1)
    80003d7a:	fbf9                	bnez	a5,80003d50 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d7c:	01048913          	addi	s2,s1,16
    80003d80:	854a                	mv	a0,s2
    80003d82:	00001097          	auipc	ra,0x1
    80003d86:	ab8080e7          	jalr	-1352(ra) # 8000483a <acquiresleep>
    release(&itable.lock);
    80003d8a:	0001c517          	auipc	a0,0x1c
    80003d8e:	38650513          	addi	a0,a0,902 # 80020110 <itable>
    80003d92:	ffffd097          	auipc	ra,0xffffd
    80003d96:	f06080e7          	jalr	-250(ra) # 80000c98 <release>
    itrunc(ip);
    80003d9a:	8526                	mv	a0,s1
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	ee2080e7          	jalr	-286(ra) # 80003c7e <itrunc>
    ip->type = 0;
    80003da4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003da8:	8526                	mv	a0,s1
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	cfc080e7          	jalr	-772(ra) # 80003aa6 <iupdate>
    ip->valid = 0;
    80003db2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003db6:	854a                	mv	a0,s2
    80003db8:	00001097          	auipc	ra,0x1
    80003dbc:	ad8080e7          	jalr	-1320(ra) # 80004890 <releasesleep>
    acquire(&itable.lock);
    80003dc0:	0001c517          	auipc	a0,0x1c
    80003dc4:	35050513          	addi	a0,a0,848 # 80020110 <itable>
    80003dc8:	ffffd097          	auipc	ra,0xffffd
    80003dcc:	e1c080e7          	jalr	-484(ra) # 80000be4 <acquire>
    80003dd0:	b741                	j	80003d50 <iput+0x26>

0000000080003dd2 <iunlockput>:
{
    80003dd2:	1101                	addi	sp,sp,-32
    80003dd4:	ec06                	sd	ra,24(sp)
    80003dd6:	e822                	sd	s0,16(sp)
    80003dd8:	e426                	sd	s1,8(sp)
    80003dda:	1000                	addi	s0,sp,32
    80003ddc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	e54080e7          	jalr	-428(ra) # 80003c32 <iunlock>
  iput(ip);
    80003de6:	8526                	mv	a0,s1
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	f42080e7          	jalr	-190(ra) # 80003d2a <iput>
}
    80003df0:	60e2                	ld	ra,24(sp)
    80003df2:	6442                	ld	s0,16(sp)
    80003df4:	64a2                	ld	s1,8(sp)
    80003df6:	6105                	addi	sp,sp,32
    80003df8:	8082                	ret

0000000080003dfa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003dfa:	1141                	addi	sp,sp,-16
    80003dfc:	e422                	sd	s0,8(sp)
    80003dfe:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e00:	411c                	lw	a5,0(a0)
    80003e02:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e04:	415c                	lw	a5,4(a0)
    80003e06:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e08:	04451783          	lh	a5,68(a0)
    80003e0c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e10:	04a51783          	lh	a5,74(a0)
    80003e14:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e18:	04c56783          	lwu	a5,76(a0)
    80003e1c:	e99c                	sd	a5,16(a1)
}
    80003e1e:	6422                	ld	s0,8(sp)
    80003e20:	0141                	addi	sp,sp,16
    80003e22:	8082                	ret

0000000080003e24 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e24:	457c                	lw	a5,76(a0)
    80003e26:	0ed7e963          	bltu	a5,a3,80003f18 <readi+0xf4>
{
    80003e2a:	7159                	addi	sp,sp,-112
    80003e2c:	f486                	sd	ra,104(sp)
    80003e2e:	f0a2                	sd	s0,96(sp)
    80003e30:	eca6                	sd	s1,88(sp)
    80003e32:	e8ca                	sd	s2,80(sp)
    80003e34:	e4ce                	sd	s3,72(sp)
    80003e36:	e0d2                	sd	s4,64(sp)
    80003e38:	fc56                	sd	s5,56(sp)
    80003e3a:	f85a                	sd	s6,48(sp)
    80003e3c:	f45e                	sd	s7,40(sp)
    80003e3e:	f062                	sd	s8,32(sp)
    80003e40:	ec66                	sd	s9,24(sp)
    80003e42:	e86a                	sd	s10,16(sp)
    80003e44:	e46e                	sd	s11,8(sp)
    80003e46:	1880                	addi	s0,sp,112
    80003e48:	8baa                	mv	s7,a0
    80003e4a:	8c2e                	mv	s8,a1
    80003e4c:	8ab2                	mv	s5,a2
    80003e4e:	84b6                	mv	s1,a3
    80003e50:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e52:	9f35                	addw	a4,a4,a3
    return 0;
    80003e54:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e56:	0ad76063          	bltu	a4,a3,80003ef6 <readi+0xd2>
  if(off + n > ip->size)
    80003e5a:	00e7f463          	bgeu	a5,a4,80003e62 <readi+0x3e>
    n = ip->size - off;
    80003e5e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e62:	0a0b0963          	beqz	s6,80003f14 <readi+0xf0>
    80003e66:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e68:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e6c:	5cfd                	li	s9,-1
    80003e6e:	a82d                	j	80003ea8 <readi+0x84>
    80003e70:	020a1d93          	slli	s11,s4,0x20
    80003e74:	020ddd93          	srli	s11,s11,0x20
    80003e78:	05890613          	addi	a2,s2,88
    80003e7c:	86ee                	mv	a3,s11
    80003e7e:	963a                	add	a2,a2,a4
    80003e80:	85d6                	mv	a1,s5
    80003e82:	8562                	mv	a0,s8
    80003e84:	ffffe097          	auipc	ra,0xffffe
    80003e88:	e04080e7          	jalr	-508(ra) # 80001c88 <either_copyout>
    80003e8c:	05950d63          	beq	a0,s9,80003ee6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e90:	854a                	mv	a0,s2
    80003e92:	fffff097          	auipc	ra,0xfffff
    80003e96:	60c080e7          	jalr	1548(ra) # 8000349e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e9a:	013a09bb          	addw	s3,s4,s3
    80003e9e:	009a04bb          	addw	s1,s4,s1
    80003ea2:	9aee                	add	s5,s5,s11
    80003ea4:	0569f763          	bgeu	s3,s6,80003ef2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ea8:	000ba903          	lw	s2,0(s7)
    80003eac:	00a4d59b          	srliw	a1,s1,0xa
    80003eb0:	855e                	mv	a0,s7
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	8b0080e7          	jalr	-1872(ra) # 80003762 <bmap>
    80003eba:	0005059b          	sext.w	a1,a0
    80003ebe:	854a                	mv	a0,s2
    80003ec0:	fffff097          	auipc	ra,0xfffff
    80003ec4:	4ae080e7          	jalr	1198(ra) # 8000336e <bread>
    80003ec8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eca:	3ff4f713          	andi	a4,s1,1023
    80003ece:	40ed07bb          	subw	a5,s10,a4
    80003ed2:	413b06bb          	subw	a3,s6,s3
    80003ed6:	8a3e                	mv	s4,a5
    80003ed8:	2781                	sext.w	a5,a5
    80003eda:	0006861b          	sext.w	a2,a3
    80003ede:	f8f679e3          	bgeu	a2,a5,80003e70 <readi+0x4c>
    80003ee2:	8a36                	mv	s4,a3
    80003ee4:	b771                	j	80003e70 <readi+0x4c>
      brelse(bp);
    80003ee6:	854a                	mv	a0,s2
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	5b6080e7          	jalr	1462(ra) # 8000349e <brelse>
      tot = -1;
    80003ef0:	59fd                	li	s3,-1
  }
  return tot;
    80003ef2:	0009851b          	sext.w	a0,s3
}
    80003ef6:	70a6                	ld	ra,104(sp)
    80003ef8:	7406                	ld	s0,96(sp)
    80003efa:	64e6                	ld	s1,88(sp)
    80003efc:	6946                	ld	s2,80(sp)
    80003efe:	69a6                	ld	s3,72(sp)
    80003f00:	6a06                	ld	s4,64(sp)
    80003f02:	7ae2                	ld	s5,56(sp)
    80003f04:	7b42                	ld	s6,48(sp)
    80003f06:	7ba2                	ld	s7,40(sp)
    80003f08:	7c02                	ld	s8,32(sp)
    80003f0a:	6ce2                	ld	s9,24(sp)
    80003f0c:	6d42                	ld	s10,16(sp)
    80003f0e:	6da2                	ld	s11,8(sp)
    80003f10:	6165                	addi	sp,sp,112
    80003f12:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f14:	89da                	mv	s3,s6
    80003f16:	bff1                	j	80003ef2 <readi+0xce>
    return 0;
    80003f18:	4501                	li	a0,0
}
    80003f1a:	8082                	ret

0000000080003f1c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f1c:	457c                	lw	a5,76(a0)
    80003f1e:	10d7e863          	bltu	a5,a3,8000402e <writei+0x112>
{
    80003f22:	7159                	addi	sp,sp,-112
    80003f24:	f486                	sd	ra,104(sp)
    80003f26:	f0a2                	sd	s0,96(sp)
    80003f28:	eca6                	sd	s1,88(sp)
    80003f2a:	e8ca                	sd	s2,80(sp)
    80003f2c:	e4ce                	sd	s3,72(sp)
    80003f2e:	e0d2                	sd	s4,64(sp)
    80003f30:	fc56                	sd	s5,56(sp)
    80003f32:	f85a                	sd	s6,48(sp)
    80003f34:	f45e                	sd	s7,40(sp)
    80003f36:	f062                	sd	s8,32(sp)
    80003f38:	ec66                	sd	s9,24(sp)
    80003f3a:	e86a                	sd	s10,16(sp)
    80003f3c:	e46e                	sd	s11,8(sp)
    80003f3e:	1880                	addi	s0,sp,112
    80003f40:	8b2a                	mv	s6,a0
    80003f42:	8c2e                	mv	s8,a1
    80003f44:	8ab2                	mv	s5,a2
    80003f46:	8936                	mv	s2,a3
    80003f48:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f4a:	00e687bb          	addw	a5,a3,a4
    80003f4e:	0ed7e263          	bltu	a5,a3,80004032 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f52:	00043737          	lui	a4,0x43
    80003f56:	0ef76063          	bltu	a4,a5,80004036 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f5a:	0c0b8863          	beqz	s7,8000402a <writei+0x10e>
    80003f5e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f60:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f64:	5cfd                	li	s9,-1
    80003f66:	a091                	j	80003faa <writei+0x8e>
    80003f68:	02099d93          	slli	s11,s3,0x20
    80003f6c:	020ddd93          	srli	s11,s11,0x20
    80003f70:	05848513          	addi	a0,s1,88
    80003f74:	86ee                	mv	a3,s11
    80003f76:	8656                	mv	a2,s5
    80003f78:	85e2                	mv	a1,s8
    80003f7a:	953a                	add	a0,a0,a4
    80003f7c:	ffffe097          	auipc	ra,0xffffe
    80003f80:	d62080e7          	jalr	-670(ra) # 80001cde <either_copyin>
    80003f84:	07950263          	beq	a0,s9,80003fe8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f88:	8526                	mv	a0,s1
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	790080e7          	jalr	1936(ra) # 8000471a <log_write>
    brelse(bp);
    80003f92:	8526                	mv	a0,s1
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	50a080e7          	jalr	1290(ra) # 8000349e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f9c:	01498a3b          	addw	s4,s3,s4
    80003fa0:	0129893b          	addw	s2,s3,s2
    80003fa4:	9aee                	add	s5,s5,s11
    80003fa6:	057a7663          	bgeu	s4,s7,80003ff2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003faa:	000b2483          	lw	s1,0(s6)
    80003fae:	00a9559b          	srliw	a1,s2,0xa
    80003fb2:	855a                	mv	a0,s6
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	7ae080e7          	jalr	1966(ra) # 80003762 <bmap>
    80003fbc:	0005059b          	sext.w	a1,a0
    80003fc0:	8526                	mv	a0,s1
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	3ac080e7          	jalr	940(ra) # 8000336e <bread>
    80003fca:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fcc:	3ff97713          	andi	a4,s2,1023
    80003fd0:	40ed07bb          	subw	a5,s10,a4
    80003fd4:	414b86bb          	subw	a3,s7,s4
    80003fd8:	89be                	mv	s3,a5
    80003fda:	2781                	sext.w	a5,a5
    80003fdc:	0006861b          	sext.w	a2,a3
    80003fe0:	f8f674e3          	bgeu	a2,a5,80003f68 <writei+0x4c>
    80003fe4:	89b6                	mv	s3,a3
    80003fe6:	b749                	j	80003f68 <writei+0x4c>
      brelse(bp);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	4b4080e7          	jalr	1204(ra) # 8000349e <brelse>
  }

  if(off > ip->size)
    80003ff2:	04cb2783          	lw	a5,76(s6)
    80003ff6:	0127f463          	bgeu	a5,s2,80003ffe <writei+0xe2>
    ip->size = off;
    80003ffa:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ffe:	855a                	mv	a0,s6
    80004000:	00000097          	auipc	ra,0x0
    80004004:	aa6080e7          	jalr	-1370(ra) # 80003aa6 <iupdate>

  return tot;
    80004008:	000a051b          	sext.w	a0,s4
}
    8000400c:	70a6                	ld	ra,104(sp)
    8000400e:	7406                	ld	s0,96(sp)
    80004010:	64e6                	ld	s1,88(sp)
    80004012:	6946                	ld	s2,80(sp)
    80004014:	69a6                	ld	s3,72(sp)
    80004016:	6a06                	ld	s4,64(sp)
    80004018:	7ae2                	ld	s5,56(sp)
    8000401a:	7b42                	ld	s6,48(sp)
    8000401c:	7ba2                	ld	s7,40(sp)
    8000401e:	7c02                	ld	s8,32(sp)
    80004020:	6ce2                	ld	s9,24(sp)
    80004022:	6d42                	ld	s10,16(sp)
    80004024:	6da2                	ld	s11,8(sp)
    80004026:	6165                	addi	sp,sp,112
    80004028:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000402a:	8a5e                	mv	s4,s7
    8000402c:	bfc9                	j	80003ffe <writei+0xe2>
    return -1;
    8000402e:	557d                	li	a0,-1
}
    80004030:	8082                	ret
    return -1;
    80004032:	557d                	li	a0,-1
    80004034:	bfe1                	j	8000400c <writei+0xf0>
    return -1;
    80004036:	557d                	li	a0,-1
    80004038:	bfd1                	j	8000400c <writei+0xf0>

000000008000403a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000403a:	1141                	addi	sp,sp,-16
    8000403c:	e406                	sd	ra,8(sp)
    8000403e:	e022                	sd	s0,0(sp)
    80004040:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004042:	4639                	li	a2,14
    80004044:	ffffd097          	auipc	ra,0xffffd
    80004048:	d74080e7          	jalr	-652(ra) # 80000db8 <strncmp>
}
    8000404c:	60a2                	ld	ra,8(sp)
    8000404e:	6402                	ld	s0,0(sp)
    80004050:	0141                	addi	sp,sp,16
    80004052:	8082                	ret

0000000080004054 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004054:	7139                	addi	sp,sp,-64
    80004056:	fc06                	sd	ra,56(sp)
    80004058:	f822                	sd	s0,48(sp)
    8000405a:	f426                	sd	s1,40(sp)
    8000405c:	f04a                	sd	s2,32(sp)
    8000405e:	ec4e                	sd	s3,24(sp)
    80004060:	e852                	sd	s4,16(sp)
    80004062:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004064:	04451703          	lh	a4,68(a0)
    80004068:	4785                	li	a5,1
    8000406a:	00f71a63          	bne	a4,a5,8000407e <dirlookup+0x2a>
    8000406e:	892a                	mv	s2,a0
    80004070:	89ae                	mv	s3,a1
    80004072:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004074:	457c                	lw	a5,76(a0)
    80004076:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004078:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000407a:	e79d                	bnez	a5,800040a8 <dirlookup+0x54>
    8000407c:	a8a5                	j	800040f4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000407e:	00004517          	auipc	a0,0x4
    80004082:	57a50513          	addi	a0,a0,1402 # 800085f8 <syscalls+0x1b0>
    80004086:	ffffc097          	auipc	ra,0xffffc
    8000408a:	4b8080e7          	jalr	1208(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000408e:	00004517          	auipc	a0,0x4
    80004092:	58250513          	addi	a0,a0,1410 # 80008610 <syscalls+0x1c8>
    80004096:	ffffc097          	auipc	ra,0xffffc
    8000409a:	4a8080e7          	jalr	1192(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409e:	24c1                	addiw	s1,s1,16
    800040a0:	04c92783          	lw	a5,76(s2)
    800040a4:	04f4f763          	bgeu	s1,a5,800040f2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a8:	4741                	li	a4,16
    800040aa:	86a6                	mv	a3,s1
    800040ac:	fc040613          	addi	a2,s0,-64
    800040b0:	4581                	li	a1,0
    800040b2:	854a                	mv	a0,s2
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	d70080e7          	jalr	-656(ra) # 80003e24 <readi>
    800040bc:	47c1                	li	a5,16
    800040be:	fcf518e3          	bne	a0,a5,8000408e <dirlookup+0x3a>
    if(de.inum == 0)
    800040c2:	fc045783          	lhu	a5,-64(s0)
    800040c6:	dfe1                	beqz	a5,8000409e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040c8:	fc240593          	addi	a1,s0,-62
    800040cc:	854e                	mv	a0,s3
    800040ce:	00000097          	auipc	ra,0x0
    800040d2:	f6c080e7          	jalr	-148(ra) # 8000403a <namecmp>
    800040d6:	f561                	bnez	a0,8000409e <dirlookup+0x4a>
      if(poff)
    800040d8:	000a0463          	beqz	s4,800040e0 <dirlookup+0x8c>
        *poff = off;
    800040dc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040e0:	fc045583          	lhu	a1,-64(s0)
    800040e4:	00092503          	lw	a0,0(s2)
    800040e8:	fffff097          	auipc	ra,0xfffff
    800040ec:	754080e7          	jalr	1876(ra) # 8000383c <iget>
    800040f0:	a011                	j	800040f4 <dirlookup+0xa0>
  return 0;
    800040f2:	4501                	li	a0,0
}
    800040f4:	70e2                	ld	ra,56(sp)
    800040f6:	7442                	ld	s0,48(sp)
    800040f8:	74a2                	ld	s1,40(sp)
    800040fa:	7902                	ld	s2,32(sp)
    800040fc:	69e2                	ld	s3,24(sp)
    800040fe:	6a42                	ld	s4,16(sp)
    80004100:	6121                	addi	sp,sp,64
    80004102:	8082                	ret

0000000080004104 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004104:	711d                	addi	sp,sp,-96
    80004106:	ec86                	sd	ra,88(sp)
    80004108:	e8a2                	sd	s0,80(sp)
    8000410a:	e4a6                	sd	s1,72(sp)
    8000410c:	e0ca                	sd	s2,64(sp)
    8000410e:	fc4e                	sd	s3,56(sp)
    80004110:	f852                	sd	s4,48(sp)
    80004112:	f456                	sd	s5,40(sp)
    80004114:	f05a                	sd	s6,32(sp)
    80004116:	ec5e                	sd	s7,24(sp)
    80004118:	e862                	sd	s8,16(sp)
    8000411a:	e466                	sd	s9,8(sp)
    8000411c:	1080                	addi	s0,sp,96
    8000411e:	84aa                	mv	s1,a0
    80004120:	8b2e                	mv	s6,a1
    80004122:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004124:	00054703          	lbu	a4,0(a0)
    80004128:	02f00793          	li	a5,47
    8000412c:	02f70363          	beq	a4,a5,80004152 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004130:	ffffd097          	auipc	ra,0xffffd
    80004134:	7d8080e7          	jalr	2008(ra) # 80001908 <myproc>
    80004138:	17053503          	ld	a0,368(a0)
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	9f6080e7          	jalr	-1546(ra) # 80003b32 <idup>
    80004144:	89aa                	mv	s3,a0
  while(*path == '/')
    80004146:	02f00913          	li	s2,47
  len = path - s;
    8000414a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000414c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000414e:	4c05                	li	s8,1
    80004150:	a865                	j	80004208 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004152:	4585                	li	a1,1
    80004154:	4505                	li	a0,1
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	6e6080e7          	jalr	1766(ra) # 8000383c <iget>
    8000415e:	89aa                	mv	s3,a0
    80004160:	b7dd                	j	80004146 <namex+0x42>
      iunlockput(ip);
    80004162:	854e                	mv	a0,s3
    80004164:	00000097          	auipc	ra,0x0
    80004168:	c6e080e7          	jalr	-914(ra) # 80003dd2 <iunlockput>
      return 0;
    8000416c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000416e:	854e                	mv	a0,s3
    80004170:	60e6                	ld	ra,88(sp)
    80004172:	6446                	ld	s0,80(sp)
    80004174:	64a6                	ld	s1,72(sp)
    80004176:	6906                	ld	s2,64(sp)
    80004178:	79e2                	ld	s3,56(sp)
    8000417a:	7a42                	ld	s4,48(sp)
    8000417c:	7aa2                	ld	s5,40(sp)
    8000417e:	7b02                	ld	s6,32(sp)
    80004180:	6be2                	ld	s7,24(sp)
    80004182:	6c42                	ld	s8,16(sp)
    80004184:	6ca2                	ld	s9,8(sp)
    80004186:	6125                	addi	sp,sp,96
    80004188:	8082                	ret
      iunlock(ip);
    8000418a:	854e                	mv	a0,s3
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	aa6080e7          	jalr	-1370(ra) # 80003c32 <iunlock>
      return ip;
    80004194:	bfe9                	j	8000416e <namex+0x6a>
      iunlockput(ip);
    80004196:	854e                	mv	a0,s3
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	c3a080e7          	jalr	-966(ra) # 80003dd2 <iunlockput>
      return 0;
    800041a0:	89d2                	mv	s3,s4
    800041a2:	b7f1                	j	8000416e <namex+0x6a>
  len = path - s;
    800041a4:	40b48633          	sub	a2,s1,a1
    800041a8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041ac:	094cd463          	bge	s9,s4,80004234 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041b0:	4639                	li	a2,14
    800041b2:	8556                	mv	a0,s5
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	b8c080e7          	jalr	-1140(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041bc:	0004c783          	lbu	a5,0(s1)
    800041c0:	01279763          	bne	a5,s2,800041ce <namex+0xca>
    path++;
    800041c4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041c6:	0004c783          	lbu	a5,0(s1)
    800041ca:	ff278de3          	beq	a5,s2,800041c4 <namex+0xc0>
    ilock(ip);
    800041ce:	854e                	mv	a0,s3
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	9a0080e7          	jalr	-1632(ra) # 80003b70 <ilock>
    if(ip->type != T_DIR){
    800041d8:	04499783          	lh	a5,68(s3)
    800041dc:	f98793e3          	bne	a5,s8,80004162 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041e0:	000b0563          	beqz	s6,800041ea <namex+0xe6>
    800041e4:	0004c783          	lbu	a5,0(s1)
    800041e8:	d3cd                	beqz	a5,8000418a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041ea:	865e                	mv	a2,s7
    800041ec:	85d6                	mv	a1,s5
    800041ee:	854e                	mv	a0,s3
    800041f0:	00000097          	auipc	ra,0x0
    800041f4:	e64080e7          	jalr	-412(ra) # 80004054 <dirlookup>
    800041f8:	8a2a                	mv	s4,a0
    800041fa:	dd51                	beqz	a0,80004196 <namex+0x92>
    iunlockput(ip);
    800041fc:	854e                	mv	a0,s3
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	bd4080e7          	jalr	-1068(ra) # 80003dd2 <iunlockput>
    ip = next;
    80004206:	89d2                	mv	s3,s4
  while(*path == '/')
    80004208:	0004c783          	lbu	a5,0(s1)
    8000420c:	05279763          	bne	a5,s2,8000425a <namex+0x156>
    path++;
    80004210:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004212:	0004c783          	lbu	a5,0(s1)
    80004216:	ff278de3          	beq	a5,s2,80004210 <namex+0x10c>
  if(*path == 0)
    8000421a:	c79d                	beqz	a5,80004248 <namex+0x144>
    path++;
    8000421c:	85a6                	mv	a1,s1
  len = path - s;
    8000421e:	8a5e                	mv	s4,s7
    80004220:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004222:	01278963          	beq	a5,s2,80004234 <namex+0x130>
    80004226:	dfbd                	beqz	a5,800041a4 <namex+0xa0>
    path++;
    80004228:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000422a:	0004c783          	lbu	a5,0(s1)
    8000422e:	ff279ce3          	bne	a5,s2,80004226 <namex+0x122>
    80004232:	bf8d                	j	800041a4 <namex+0xa0>
    memmove(name, s, len);
    80004234:	2601                	sext.w	a2,a2
    80004236:	8556                	mv	a0,s5
    80004238:	ffffd097          	auipc	ra,0xffffd
    8000423c:	b08080e7          	jalr	-1272(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004240:	9a56                	add	s4,s4,s5
    80004242:	000a0023          	sb	zero,0(s4)
    80004246:	bf9d                	j	800041bc <namex+0xb8>
  if(nameiparent){
    80004248:	f20b03e3          	beqz	s6,8000416e <namex+0x6a>
    iput(ip);
    8000424c:	854e                	mv	a0,s3
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	adc080e7          	jalr	-1316(ra) # 80003d2a <iput>
    return 0;
    80004256:	4981                	li	s3,0
    80004258:	bf19                	j	8000416e <namex+0x6a>
  if(*path == 0)
    8000425a:	d7fd                	beqz	a5,80004248 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000425c:	0004c783          	lbu	a5,0(s1)
    80004260:	85a6                	mv	a1,s1
    80004262:	b7d1                	j	80004226 <namex+0x122>

0000000080004264 <dirlink>:
{
    80004264:	7139                	addi	sp,sp,-64
    80004266:	fc06                	sd	ra,56(sp)
    80004268:	f822                	sd	s0,48(sp)
    8000426a:	f426                	sd	s1,40(sp)
    8000426c:	f04a                	sd	s2,32(sp)
    8000426e:	ec4e                	sd	s3,24(sp)
    80004270:	e852                	sd	s4,16(sp)
    80004272:	0080                	addi	s0,sp,64
    80004274:	892a                	mv	s2,a0
    80004276:	8a2e                	mv	s4,a1
    80004278:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000427a:	4601                	li	a2,0
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	dd8080e7          	jalr	-552(ra) # 80004054 <dirlookup>
    80004284:	e93d                	bnez	a0,800042fa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004286:	04c92483          	lw	s1,76(s2)
    8000428a:	c49d                	beqz	s1,800042b8 <dirlink+0x54>
    8000428c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000428e:	4741                	li	a4,16
    80004290:	86a6                	mv	a3,s1
    80004292:	fc040613          	addi	a2,s0,-64
    80004296:	4581                	li	a1,0
    80004298:	854a                	mv	a0,s2
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	b8a080e7          	jalr	-1142(ra) # 80003e24 <readi>
    800042a2:	47c1                	li	a5,16
    800042a4:	06f51163          	bne	a0,a5,80004306 <dirlink+0xa2>
    if(de.inum == 0)
    800042a8:	fc045783          	lhu	a5,-64(s0)
    800042ac:	c791                	beqz	a5,800042b8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ae:	24c1                	addiw	s1,s1,16
    800042b0:	04c92783          	lw	a5,76(s2)
    800042b4:	fcf4ede3          	bltu	s1,a5,8000428e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042b8:	4639                	li	a2,14
    800042ba:	85d2                	mv	a1,s4
    800042bc:	fc240513          	addi	a0,s0,-62
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	b34080e7          	jalr	-1228(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042c8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042cc:	4741                	li	a4,16
    800042ce:	86a6                	mv	a3,s1
    800042d0:	fc040613          	addi	a2,s0,-64
    800042d4:	4581                	li	a1,0
    800042d6:	854a                	mv	a0,s2
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	c44080e7          	jalr	-956(ra) # 80003f1c <writei>
    800042e0:	872a                	mv	a4,a0
    800042e2:	47c1                	li	a5,16
  return 0;
    800042e4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042e6:	02f71863          	bne	a4,a5,80004316 <dirlink+0xb2>
}
    800042ea:	70e2                	ld	ra,56(sp)
    800042ec:	7442                	ld	s0,48(sp)
    800042ee:	74a2                	ld	s1,40(sp)
    800042f0:	7902                	ld	s2,32(sp)
    800042f2:	69e2                	ld	s3,24(sp)
    800042f4:	6a42                	ld	s4,16(sp)
    800042f6:	6121                	addi	sp,sp,64
    800042f8:	8082                	ret
    iput(ip);
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	a30080e7          	jalr	-1488(ra) # 80003d2a <iput>
    return -1;
    80004302:	557d                	li	a0,-1
    80004304:	b7dd                	j	800042ea <dirlink+0x86>
      panic("dirlink read");
    80004306:	00004517          	auipc	a0,0x4
    8000430a:	31a50513          	addi	a0,a0,794 # 80008620 <syscalls+0x1d8>
    8000430e:	ffffc097          	auipc	ra,0xffffc
    80004312:	230080e7          	jalr	560(ra) # 8000053e <panic>
    panic("dirlink");
    80004316:	00004517          	auipc	a0,0x4
    8000431a:	41a50513          	addi	a0,a0,1050 # 80008730 <syscalls+0x2e8>
    8000431e:	ffffc097          	auipc	ra,0xffffc
    80004322:	220080e7          	jalr	544(ra) # 8000053e <panic>

0000000080004326 <namei>:

struct inode*
namei(char *path)
{
    80004326:	1101                	addi	sp,sp,-32
    80004328:	ec06                	sd	ra,24(sp)
    8000432a:	e822                	sd	s0,16(sp)
    8000432c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000432e:	fe040613          	addi	a2,s0,-32
    80004332:	4581                	li	a1,0
    80004334:	00000097          	auipc	ra,0x0
    80004338:	dd0080e7          	jalr	-560(ra) # 80004104 <namex>
}
    8000433c:	60e2                	ld	ra,24(sp)
    8000433e:	6442                	ld	s0,16(sp)
    80004340:	6105                	addi	sp,sp,32
    80004342:	8082                	ret

0000000080004344 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004344:	1141                	addi	sp,sp,-16
    80004346:	e406                	sd	ra,8(sp)
    80004348:	e022                	sd	s0,0(sp)
    8000434a:	0800                	addi	s0,sp,16
    8000434c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000434e:	4585                	li	a1,1
    80004350:	00000097          	auipc	ra,0x0
    80004354:	db4080e7          	jalr	-588(ra) # 80004104 <namex>
}
    80004358:	60a2                	ld	ra,8(sp)
    8000435a:	6402                	ld	s0,0(sp)
    8000435c:	0141                	addi	sp,sp,16
    8000435e:	8082                	ret

0000000080004360 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004360:	1101                	addi	sp,sp,-32
    80004362:	ec06                	sd	ra,24(sp)
    80004364:	e822                	sd	s0,16(sp)
    80004366:	e426                	sd	s1,8(sp)
    80004368:	e04a                	sd	s2,0(sp)
    8000436a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000436c:	0001e917          	auipc	s2,0x1e
    80004370:	84c90913          	addi	s2,s2,-1972 # 80021bb8 <log>
    80004374:	01892583          	lw	a1,24(s2)
    80004378:	02892503          	lw	a0,40(s2)
    8000437c:	fffff097          	auipc	ra,0xfffff
    80004380:	ff2080e7          	jalr	-14(ra) # 8000336e <bread>
    80004384:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004386:	02c92683          	lw	a3,44(s2)
    8000438a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000438c:	02d05763          	blez	a3,800043ba <write_head+0x5a>
    80004390:	0001e797          	auipc	a5,0x1e
    80004394:	85878793          	addi	a5,a5,-1960 # 80021be8 <log+0x30>
    80004398:	05c50713          	addi	a4,a0,92
    8000439c:	36fd                	addiw	a3,a3,-1
    8000439e:	1682                	slli	a3,a3,0x20
    800043a0:	9281                	srli	a3,a3,0x20
    800043a2:	068a                	slli	a3,a3,0x2
    800043a4:	0001e617          	auipc	a2,0x1e
    800043a8:	84860613          	addi	a2,a2,-1976 # 80021bec <log+0x34>
    800043ac:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043ae:	4390                	lw	a2,0(a5)
    800043b0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043b2:	0791                	addi	a5,a5,4
    800043b4:	0711                	addi	a4,a4,4
    800043b6:	fed79ce3          	bne	a5,a3,800043ae <write_head+0x4e>
  }
  bwrite(buf);
    800043ba:	8526                	mv	a0,s1
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	0a4080e7          	jalr	164(ra) # 80003460 <bwrite>
  brelse(buf);
    800043c4:	8526                	mv	a0,s1
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	0d8080e7          	jalr	216(ra) # 8000349e <brelse>
}
    800043ce:	60e2                	ld	ra,24(sp)
    800043d0:	6442                	ld	s0,16(sp)
    800043d2:	64a2                	ld	s1,8(sp)
    800043d4:	6902                	ld	s2,0(sp)
    800043d6:	6105                	addi	sp,sp,32
    800043d8:	8082                	ret

00000000800043da <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043da:	0001e797          	auipc	a5,0x1e
    800043de:	80a7a783          	lw	a5,-2038(a5) # 80021be4 <log+0x2c>
    800043e2:	0af05d63          	blez	a5,8000449c <install_trans+0xc2>
{
    800043e6:	7139                	addi	sp,sp,-64
    800043e8:	fc06                	sd	ra,56(sp)
    800043ea:	f822                	sd	s0,48(sp)
    800043ec:	f426                	sd	s1,40(sp)
    800043ee:	f04a                	sd	s2,32(sp)
    800043f0:	ec4e                	sd	s3,24(sp)
    800043f2:	e852                	sd	s4,16(sp)
    800043f4:	e456                	sd	s5,8(sp)
    800043f6:	e05a                	sd	s6,0(sp)
    800043f8:	0080                	addi	s0,sp,64
    800043fa:	8b2a                	mv	s6,a0
    800043fc:	0001da97          	auipc	s5,0x1d
    80004400:	7eca8a93          	addi	s5,s5,2028 # 80021be8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004404:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004406:	0001d997          	auipc	s3,0x1d
    8000440a:	7b298993          	addi	s3,s3,1970 # 80021bb8 <log>
    8000440e:	a035                	j	8000443a <install_trans+0x60>
      bunpin(dbuf);
    80004410:	8526                	mv	a0,s1
    80004412:	fffff097          	auipc	ra,0xfffff
    80004416:	166080e7          	jalr	358(ra) # 80003578 <bunpin>
    brelse(lbuf);
    8000441a:	854a                	mv	a0,s2
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	082080e7          	jalr	130(ra) # 8000349e <brelse>
    brelse(dbuf);
    80004424:	8526                	mv	a0,s1
    80004426:	fffff097          	auipc	ra,0xfffff
    8000442a:	078080e7          	jalr	120(ra) # 8000349e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000442e:	2a05                	addiw	s4,s4,1
    80004430:	0a91                	addi	s5,s5,4
    80004432:	02c9a783          	lw	a5,44(s3)
    80004436:	04fa5963          	bge	s4,a5,80004488 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000443a:	0189a583          	lw	a1,24(s3)
    8000443e:	014585bb          	addw	a1,a1,s4
    80004442:	2585                	addiw	a1,a1,1
    80004444:	0289a503          	lw	a0,40(s3)
    80004448:	fffff097          	auipc	ra,0xfffff
    8000444c:	f26080e7          	jalr	-218(ra) # 8000336e <bread>
    80004450:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004452:	000aa583          	lw	a1,0(s5)
    80004456:	0289a503          	lw	a0,40(s3)
    8000445a:	fffff097          	auipc	ra,0xfffff
    8000445e:	f14080e7          	jalr	-236(ra) # 8000336e <bread>
    80004462:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004464:	40000613          	li	a2,1024
    80004468:	05890593          	addi	a1,s2,88
    8000446c:	05850513          	addi	a0,a0,88
    80004470:	ffffd097          	auipc	ra,0xffffd
    80004474:	8d0080e7          	jalr	-1840(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004478:	8526                	mv	a0,s1
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	fe6080e7          	jalr	-26(ra) # 80003460 <bwrite>
    if(recovering == 0)
    80004482:	f80b1ce3          	bnez	s6,8000441a <install_trans+0x40>
    80004486:	b769                	j	80004410 <install_trans+0x36>
}
    80004488:	70e2                	ld	ra,56(sp)
    8000448a:	7442                	ld	s0,48(sp)
    8000448c:	74a2                	ld	s1,40(sp)
    8000448e:	7902                	ld	s2,32(sp)
    80004490:	69e2                	ld	s3,24(sp)
    80004492:	6a42                	ld	s4,16(sp)
    80004494:	6aa2                	ld	s5,8(sp)
    80004496:	6b02                	ld	s6,0(sp)
    80004498:	6121                	addi	sp,sp,64
    8000449a:	8082                	ret
    8000449c:	8082                	ret

000000008000449e <initlog>:
{
    8000449e:	7179                	addi	sp,sp,-48
    800044a0:	f406                	sd	ra,40(sp)
    800044a2:	f022                	sd	s0,32(sp)
    800044a4:	ec26                	sd	s1,24(sp)
    800044a6:	e84a                	sd	s2,16(sp)
    800044a8:	e44e                	sd	s3,8(sp)
    800044aa:	1800                	addi	s0,sp,48
    800044ac:	892a                	mv	s2,a0
    800044ae:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044b0:	0001d497          	auipc	s1,0x1d
    800044b4:	70848493          	addi	s1,s1,1800 # 80021bb8 <log>
    800044b8:	00004597          	auipc	a1,0x4
    800044bc:	17858593          	addi	a1,a1,376 # 80008630 <syscalls+0x1e8>
    800044c0:	8526                	mv	a0,s1
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	692080e7          	jalr	1682(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044ca:	0149a583          	lw	a1,20(s3)
    800044ce:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044d0:	0109a783          	lw	a5,16(s3)
    800044d4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044d6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044da:	854a                	mv	a0,s2
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	e92080e7          	jalr	-366(ra) # 8000336e <bread>
  log.lh.n = lh->n;
    800044e4:	4d3c                	lw	a5,88(a0)
    800044e6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044e8:	02f05563          	blez	a5,80004512 <initlog+0x74>
    800044ec:	05c50713          	addi	a4,a0,92
    800044f0:	0001d697          	auipc	a3,0x1d
    800044f4:	6f868693          	addi	a3,a3,1784 # 80021be8 <log+0x30>
    800044f8:	37fd                	addiw	a5,a5,-1
    800044fa:	1782                	slli	a5,a5,0x20
    800044fc:	9381                	srli	a5,a5,0x20
    800044fe:	078a                	slli	a5,a5,0x2
    80004500:	06050613          	addi	a2,a0,96
    80004504:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004506:	4310                	lw	a2,0(a4)
    80004508:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000450a:	0711                	addi	a4,a4,4
    8000450c:	0691                	addi	a3,a3,4
    8000450e:	fef71ce3          	bne	a4,a5,80004506 <initlog+0x68>
  brelse(buf);
    80004512:	fffff097          	auipc	ra,0xfffff
    80004516:	f8c080e7          	jalr	-116(ra) # 8000349e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000451a:	4505                	li	a0,1
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	ebe080e7          	jalr	-322(ra) # 800043da <install_trans>
  log.lh.n = 0;
    80004524:	0001d797          	auipc	a5,0x1d
    80004528:	6c07a023          	sw	zero,1728(a5) # 80021be4 <log+0x2c>
  write_head(); // clear the log
    8000452c:	00000097          	auipc	ra,0x0
    80004530:	e34080e7          	jalr	-460(ra) # 80004360 <write_head>
}
    80004534:	70a2                	ld	ra,40(sp)
    80004536:	7402                	ld	s0,32(sp)
    80004538:	64e2                	ld	s1,24(sp)
    8000453a:	6942                	ld	s2,16(sp)
    8000453c:	69a2                	ld	s3,8(sp)
    8000453e:	6145                	addi	sp,sp,48
    80004540:	8082                	ret

0000000080004542 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004542:	1101                	addi	sp,sp,-32
    80004544:	ec06                	sd	ra,24(sp)
    80004546:	e822                	sd	s0,16(sp)
    80004548:	e426                	sd	s1,8(sp)
    8000454a:	e04a                	sd	s2,0(sp)
    8000454c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000454e:	0001d517          	auipc	a0,0x1d
    80004552:	66a50513          	addi	a0,a0,1642 # 80021bb8 <log>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	68e080e7          	jalr	1678(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000455e:	0001d497          	auipc	s1,0x1d
    80004562:	65a48493          	addi	s1,s1,1626 # 80021bb8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004566:	4979                	li	s2,30
    80004568:	a039                	j	80004576 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000456a:	85a6                	mv	a1,s1
    8000456c:	8526                	mv	a0,s1
    8000456e:	ffffe097          	auipc	ra,0xffffe
    80004572:	b3a080e7          	jalr	-1222(ra) # 800020a8 <sleep>
    if(log.committing){
    80004576:	50dc                	lw	a5,36(s1)
    80004578:	fbed                	bnez	a5,8000456a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000457a:	509c                	lw	a5,32(s1)
    8000457c:	0017871b          	addiw	a4,a5,1
    80004580:	0007069b          	sext.w	a3,a4
    80004584:	0027179b          	slliw	a5,a4,0x2
    80004588:	9fb9                	addw	a5,a5,a4
    8000458a:	0017979b          	slliw	a5,a5,0x1
    8000458e:	54d8                	lw	a4,44(s1)
    80004590:	9fb9                	addw	a5,a5,a4
    80004592:	00f95963          	bge	s2,a5,800045a4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004596:	85a6                	mv	a1,s1
    80004598:	8526                	mv	a0,s1
    8000459a:	ffffe097          	auipc	ra,0xffffe
    8000459e:	b0e080e7          	jalr	-1266(ra) # 800020a8 <sleep>
    800045a2:	bfd1                	j	80004576 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045a4:	0001d517          	auipc	a0,0x1d
    800045a8:	61450513          	addi	a0,a0,1556 # 80021bb8 <log>
    800045ac:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045b6:	60e2                	ld	ra,24(sp)
    800045b8:	6442                	ld	s0,16(sp)
    800045ba:	64a2                	ld	s1,8(sp)
    800045bc:	6902                	ld	s2,0(sp)
    800045be:	6105                	addi	sp,sp,32
    800045c0:	8082                	ret

00000000800045c2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045c2:	7139                	addi	sp,sp,-64
    800045c4:	fc06                	sd	ra,56(sp)
    800045c6:	f822                	sd	s0,48(sp)
    800045c8:	f426                	sd	s1,40(sp)
    800045ca:	f04a                	sd	s2,32(sp)
    800045cc:	ec4e                	sd	s3,24(sp)
    800045ce:	e852                	sd	s4,16(sp)
    800045d0:	e456                	sd	s5,8(sp)
    800045d2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045d4:	0001d497          	auipc	s1,0x1d
    800045d8:	5e448493          	addi	s1,s1,1508 # 80021bb8 <log>
    800045dc:	8526                	mv	a0,s1
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	606080e7          	jalr	1542(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800045e6:	509c                	lw	a5,32(s1)
    800045e8:	37fd                	addiw	a5,a5,-1
    800045ea:	0007891b          	sext.w	s2,a5
    800045ee:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045f0:	50dc                	lw	a5,36(s1)
    800045f2:	efb9                	bnez	a5,80004650 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045f4:	06091663          	bnez	s2,80004660 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800045f8:	0001d497          	auipc	s1,0x1d
    800045fc:	5c048493          	addi	s1,s1,1472 # 80021bb8 <log>
    80004600:	4785                	li	a5,1
    80004602:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004604:	8526                	mv	a0,s1
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	692080e7          	jalr	1682(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000460e:	54dc                	lw	a5,44(s1)
    80004610:	06f04763          	bgtz	a5,8000467e <end_op+0xbc>
    acquire(&log.lock);
    80004614:	0001d497          	auipc	s1,0x1d
    80004618:	5a448493          	addi	s1,s1,1444 # 80021bb8 <log>
    8000461c:	8526                	mv	a0,s1
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	5c6080e7          	jalr	1478(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004626:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000462a:	8526                	mv	a0,s1
    8000462c:	ffffe097          	auipc	ra,0xffffe
    80004630:	dee080e7          	jalr	-530(ra) # 8000241a <wakeup>
    release(&log.lock);
    80004634:	8526                	mv	a0,s1
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	662080e7          	jalr	1634(ra) # 80000c98 <release>
}
    8000463e:	70e2                	ld	ra,56(sp)
    80004640:	7442                	ld	s0,48(sp)
    80004642:	74a2                	ld	s1,40(sp)
    80004644:	7902                	ld	s2,32(sp)
    80004646:	69e2                	ld	s3,24(sp)
    80004648:	6a42                	ld	s4,16(sp)
    8000464a:	6aa2                	ld	s5,8(sp)
    8000464c:	6121                	addi	sp,sp,64
    8000464e:	8082                	ret
    panic("log.committing");
    80004650:	00004517          	auipc	a0,0x4
    80004654:	fe850513          	addi	a0,a0,-24 # 80008638 <syscalls+0x1f0>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	ee6080e7          	jalr	-282(ra) # 8000053e <panic>
    wakeup(&log);
    80004660:	0001d497          	auipc	s1,0x1d
    80004664:	55848493          	addi	s1,s1,1368 # 80021bb8 <log>
    80004668:	8526                	mv	a0,s1
    8000466a:	ffffe097          	auipc	ra,0xffffe
    8000466e:	db0080e7          	jalr	-592(ra) # 8000241a <wakeup>
  release(&log.lock);
    80004672:	8526                	mv	a0,s1
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	624080e7          	jalr	1572(ra) # 80000c98 <release>
  if(do_commit){
    8000467c:	b7c9                	j	8000463e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000467e:	0001da97          	auipc	s5,0x1d
    80004682:	56aa8a93          	addi	s5,s5,1386 # 80021be8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004686:	0001da17          	auipc	s4,0x1d
    8000468a:	532a0a13          	addi	s4,s4,1330 # 80021bb8 <log>
    8000468e:	018a2583          	lw	a1,24(s4)
    80004692:	012585bb          	addw	a1,a1,s2
    80004696:	2585                	addiw	a1,a1,1
    80004698:	028a2503          	lw	a0,40(s4)
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	cd2080e7          	jalr	-814(ra) # 8000336e <bread>
    800046a4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046a6:	000aa583          	lw	a1,0(s5)
    800046aa:	028a2503          	lw	a0,40(s4)
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	cc0080e7          	jalr	-832(ra) # 8000336e <bread>
    800046b6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046b8:	40000613          	li	a2,1024
    800046bc:	05850593          	addi	a1,a0,88
    800046c0:	05848513          	addi	a0,s1,88
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	67c080e7          	jalr	1660(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046cc:	8526                	mv	a0,s1
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	d92080e7          	jalr	-622(ra) # 80003460 <bwrite>
    brelse(from);
    800046d6:	854e                	mv	a0,s3
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	dc6080e7          	jalr	-570(ra) # 8000349e <brelse>
    brelse(to);
    800046e0:	8526                	mv	a0,s1
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	dbc080e7          	jalr	-580(ra) # 8000349e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ea:	2905                	addiw	s2,s2,1
    800046ec:	0a91                	addi	s5,s5,4
    800046ee:	02ca2783          	lw	a5,44(s4)
    800046f2:	f8f94ee3          	blt	s2,a5,8000468e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046f6:	00000097          	auipc	ra,0x0
    800046fa:	c6a080e7          	jalr	-918(ra) # 80004360 <write_head>
    install_trans(0); // Now install writes to home locations
    800046fe:	4501                	li	a0,0
    80004700:	00000097          	auipc	ra,0x0
    80004704:	cda080e7          	jalr	-806(ra) # 800043da <install_trans>
    log.lh.n = 0;
    80004708:	0001d797          	auipc	a5,0x1d
    8000470c:	4c07ae23          	sw	zero,1244(a5) # 80021be4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004710:	00000097          	auipc	ra,0x0
    80004714:	c50080e7          	jalr	-944(ra) # 80004360 <write_head>
    80004718:	bdf5                	j	80004614 <end_op+0x52>

000000008000471a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000471a:	1101                	addi	sp,sp,-32
    8000471c:	ec06                	sd	ra,24(sp)
    8000471e:	e822                	sd	s0,16(sp)
    80004720:	e426                	sd	s1,8(sp)
    80004722:	e04a                	sd	s2,0(sp)
    80004724:	1000                	addi	s0,sp,32
    80004726:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004728:	0001d917          	auipc	s2,0x1d
    8000472c:	49090913          	addi	s2,s2,1168 # 80021bb8 <log>
    80004730:	854a                	mv	a0,s2
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	4b2080e7          	jalr	1202(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000473a:	02c92603          	lw	a2,44(s2)
    8000473e:	47f5                	li	a5,29
    80004740:	06c7c563          	blt	a5,a2,800047aa <log_write+0x90>
    80004744:	0001d797          	auipc	a5,0x1d
    80004748:	4907a783          	lw	a5,1168(a5) # 80021bd4 <log+0x1c>
    8000474c:	37fd                	addiw	a5,a5,-1
    8000474e:	04f65e63          	bge	a2,a5,800047aa <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004752:	0001d797          	auipc	a5,0x1d
    80004756:	4867a783          	lw	a5,1158(a5) # 80021bd8 <log+0x20>
    8000475a:	06f05063          	blez	a5,800047ba <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000475e:	4781                	li	a5,0
    80004760:	06c05563          	blez	a2,800047ca <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004764:	44cc                	lw	a1,12(s1)
    80004766:	0001d717          	auipc	a4,0x1d
    8000476a:	48270713          	addi	a4,a4,1154 # 80021be8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000476e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004770:	4314                	lw	a3,0(a4)
    80004772:	04b68c63          	beq	a3,a1,800047ca <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004776:	2785                	addiw	a5,a5,1
    80004778:	0711                	addi	a4,a4,4
    8000477a:	fef61be3          	bne	a2,a5,80004770 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000477e:	0621                	addi	a2,a2,8
    80004780:	060a                	slli	a2,a2,0x2
    80004782:	0001d797          	auipc	a5,0x1d
    80004786:	43678793          	addi	a5,a5,1078 # 80021bb8 <log>
    8000478a:	963e                	add	a2,a2,a5
    8000478c:	44dc                	lw	a5,12(s1)
    8000478e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004790:	8526                	mv	a0,s1
    80004792:	fffff097          	auipc	ra,0xfffff
    80004796:	daa080e7          	jalr	-598(ra) # 8000353c <bpin>
    log.lh.n++;
    8000479a:	0001d717          	auipc	a4,0x1d
    8000479e:	41e70713          	addi	a4,a4,1054 # 80021bb8 <log>
    800047a2:	575c                	lw	a5,44(a4)
    800047a4:	2785                	addiw	a5,a5,1
    800047a6:	d75c                	sw	a5,44(a4)
    800047a8:	a835                	j	800047e4 <log_write+0xca>
    panic("too big a transaction");
    800047aa:	00004517          	auipc	a0,0x4
    800047ae:	e9e50513          	addi	a0,a0,-354 # 80008648 <syscalls+0x200>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	d8c080e7          	jalr	-628(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047ba:	00004517          	auipc	a0,0x4
    800047be:	ea650513          	addi	a0,a0,-346 # 80008660 <syscalls+0x218>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047ca:	00878713          	addi	a4,a5,8
    800047ce:	00271693          	slli	a3,a4,0x2
    800047d2:	0001d717          	auipc	a4,0x1d
    800047d6:	3e670713          	addi	a4,a4,998 # 80021bb8 <log>
    800047da:	9736                	add	a4,a4,a3
    800047dc:	44d4                	lw	a3,12(s1)
    800047de:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047e0:	faf608e3          	beq	a2,a5,80004790 <log_write+0x76>
  }
  release(&log.lock);
    800047e4:	0001d517          	auipc	a0,0x1d
    800047e8:	3d450513          	addi	a0,a0,980 # 80021bb8 <log>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	4ac080e7          	jalr	1196(ra) # 80000c98 <release>
}
    800047f4:	60e2                	ld	ra,24(sp)
    800047f6:	6442                	ld	s0,16(sp)
    800047f8:	64a2                	ld	s1,8(sp)
    800047fa:	6902                	ld	s2,0(sp)
    800047fc:	6105                	addi	sp,sp,32
    800047fe:	8082                	ret

0000000080004800 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004800:	1101                	addi	sp,sp,-32
    80004802:	ec06                	sd	ra,24(sp)
    80004804:	e822                	sd	s0,16(sp)
    80004806:	e426                	sd	s1,8(sp)
    80004808:	e04a                	sd	s2,0(sp)
    8000480a:	1000                	addi	s0,sp,32
    8000480c:	84aa                	mv	s1,a0
    8000480e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004810:	00004597          	auipc	a1,0x4
    80004814:	e7058593          	addi	a1,a1,-400 # 80008680 <syscalls+0x238>
    80004818:	0521                	addi	a0,a0,8
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	33a080e7          	jalr	826(ra) # 80000b54 <initlock>
  lk->name = name;
    80004822:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004826:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000482a:	0204a423          	sw	zero,40(s1)
}
    8000482e:	60e2                	ld	ra,24(sp)
    80004830:	6442                	ld	s0,16(sp)
    80004832:	64a2                	ld	s1,8(sp)
    80004834:	6902                	ld	s2,0(sp)
    80004836:	6105                	addi	sp,sp,32
    80004838:	8082                	ret

000000008000483a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000483a:	1101                	addi	sp,sp,-32
    8000483c:	ec06                	sd	ra,24(sp)
    8000483e:	e822                	sd	s0,16(sp)
    80004840:	e426                	sd	s1,8(sp)
    80004842:	e04a                	sd	s2,0(sp)
    80004844:	1000                	addi	s0,sp,32
    80004846:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004848:	00850913          	addi	s2,a0,8
    8000484c:	854a                	mv	a0,s2
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	396080e7          	jalr	918(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004856:	409c                	lw	a5,0(s1)
    80004858:	cb89                	beqz	a5,8000486a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000485a:	85ca                	mv	a1,s2
    8000485c:	8526                	mv	a0,s1
    8000485e:	ffffe097          	auipc	ra,0xffffe
    80004862:	84a080e7          	jalr	-1974(ra) # 800020a8 <sleep>
  while (lk->locked) {
    80004866:	409c                	lw	a5,0(s1)
    80004868:	fbed                	bnez	a5,8000485a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000486a:	4785                	li	a5,1
    8000486c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000486e:	ffffd097          	auipc	ra,0xffffd
    80004872:	09a080e7          	jalr	154(ra) # 80001908 <myproc>
    80004876:	591c                	lw	a5,48(a0)
    80004878:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000487a:	854a                	mv	a0,s2
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	41c080e7          	jalr	1052(ra) # 80000c98 <release>
}
    80004884:	60e2                	ld	ra,24(sp)
    80004886:	6442                	ld	s0,16(sp)
    80004888:	64a2                	ld	s1,8(sp)
    8000488a:	6902                	ld	s2,0(sp)
    8000488c:	6105                	addi	sp,sp,32
    8000488e:	8082                	ret

0000000080004890 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004890:	1101                	addi	sp,sp,-32
    80004892:	ec06                	sd	ra,24(sp)
    80004894:	e822                	sd	s0,16(sp)
    80004896:	e426                	sd	s1,8(sp)
    80004898:	e04a                	sd	s2,0(sp)
    8000489a:	1000                	addi	s0,sp,32
    8000489c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000489e:	00850913          	addi	s2,a0,8
    800048a2:	854a                	mv	a0,s2
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	340080e7          	jalr	832(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048ac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048b0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048b4:	8526                	mv	a0,s1
    800048b6:	ffffe097          	auipc	ra,0xffffe
    800048ba:	b64080e7          	jalr	-1180(ra) # 8000241a <wakeup>
  release(&lk->lk);
    800048be:	854a                	mv	a0,s2
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	3d8080e7          	jalr	984(ra) # 80000c98 <release>
}
    800048c8:	60e2                	ld	ra,24(sp)
    800048ca:	6442                	ld	s0,16(sp)
    800048cc:	64a2                	ld	s1,8(sp)
    800048ce:	6902                	ld	s2,0(sp)
    800048d0:	6105                	addi	sp,sp,32
    800048d2:	8082                	ret

00000000800048d4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048d4:	7179                	addi	sp,sp,-48
    800048d6:	f406                	sd	ra,40(sp)
    800048d8:	f022                	sd	s0,32(sp)
    800048da:	ec26                	sd	s1,24(sp)
    800048dc:	e84a                	sd	s2,16(sp)
    800048de:	e44e                	sd	s3,8(sp)
    800048e0:	1800                	addi	s0,sp,48
    800048e2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048e4:	00850913          	addi	s2,a0,8
    800048e8:	854a                	mv	a0,s2
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	2fa080e7          	jalr	762(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048f2:	409c                	lw	a5,0(s1)
    800048f4:	ef99                	bnez	a5,80004912 <holdingsleep+0x3e>
    800048f6:	4481                	li	s1,0
  release(&lk->lk);
    800048f8:	854a                	mv	a0,s2
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	39e080e7          	jalr	926(ra) # 80000c98 <release>
  return r;
}
    80004902:	8526                	mv	a0,s1
    80004904:	70a2                	ld	ra,40(sp)
    80004906:	7402                	ld	s0,32(sp)
    80004908:	64e2                	ld	s1,24(sp)
    8000490a:	6942                	ld	s2,16(sp)
    8000490c:	69a2                	ld	s3,8(sp)
    8000490e:	6145                	addi	sp,sp,48
    80004910:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004912:	0284a983          	lw	s3,40(s1)
    80004916:	ffffd097          	auipc	ra,0xffffd
    8000491a:	ff2080e7          	jalr	-14(ra) # 80001908 <myproc>
    8000491e:	5904                	lw	s1,48(a0)
    80004920:	413484b3          	sub	s1,s1,s3
    80004924:	0014b493          	seqz	s1,s1
    80004928:	bfc1                	j	800048f8 <holdingsleep+0x24>

000000008000492a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000492a:	1141                	addi	sp,sp,-16
    8000492c:	e406                	sd	ra,8(sp)
    8000492e:	e022                	sd	s0,0(sp)
    80004930:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004932:	00004597          	auipc	a1,0x4
    80004936:	d5e58593          	addi	a1,a1,-674 # 80008690 <syscalls+0x248>
    8000493a:	0001d517          	auipc	a0,0x1d
    8000493e:	3c650513          	addi	a0,a0,966 # 80021d00 <ftable>
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	212080e7          	jalr	530(ra) # 80000b54 <initlock>
}
    8000494a:	60a2                	ld	ra,8(sp)
    8000494c:	6402                	ld	s0,0(sp)
    8000494e:	0141                	addi	sp,sp,16
    80004950:	8082                	ret

0000000080004952 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004952:	1101                	addi	sp,sp,-32
    80004954:	ec06                	sd	ra,24(sp)
    80004956:	e822                	sd	s0,16(sp)
    80004958:	e426                	sd	s1,8(sp)
    8000495a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000495c:	0001d517          	auipc	a0,0x1d
    80004960:	3a450513          	addi	a0,a0,932 # 80021d00 <ftable>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	280080e7          	jalr	640(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000496c:	0001d497          	auipc	s1,0x1d
    80004970:	3ac48493          	addi	s1,s1,940 # 80021d18 <ftable+0x18>
    80004974:	0001e717          	auipc	a4,0x1e
    80004978:	34470713          	addi	a4,a4,836 # 80022cb8 <ftable+0xfb8>
    if(f->ref == 0){
    8000497c:	40dc                	lw	a5,4(s1)
    8000497e:	cf99                	beqz	a5,8000499c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004980:	02848493          	addi	s1,s1,40
    80004984:	fee49ce3          	bne	s1,a4,8000497c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004988:	0001d517          	auipc	a0,0x1d
    8000498c:	37850513          	addi	a0,a0,888 # 80021d00 <ftable>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	308080e7          	jalr	776(ra) # 80000c98 <release>
  return 0;
    80004998:	4481                	li	s1,0
    8000499a:	a819                	j	800049b0 <filealloc+0x5e>
      f->ref = 1;
    8000499c:	4785                	li	a5,1
    8000499e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049a0:	0001d517          	auipc	a0,0x1d
    800049a4:	36050513          	addi	a0,a0,864 # 80021d00 <ftable>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	2f0080e7          	jalr	752(ra) # 80000c98 <release>
}
    800049b0:	8526                	mv	a0,s1
    800049b2:	60e2                	ld	ra,24(sp)
    800049b4:	6442                	ld	s0,16(sp)
    800049b6:	64a2                	ld	s1,8(sp)
    800049b8:	6105                	addi	sp,sp,32
    800049ba:	8082                	ret

00000000800049bc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049bc:	1101                	addi	sp,sp,-32
    800049be:	ec06                	sd	ra,24(sp)
    800049c0:	e822                	sd	s0,16(sp)
    800049c2:	e426                	sd	s1,8(sp)
    800049c4:	1000                	addi	s0,sp,32
    800049c6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049c8:	0001d517          	auipc	a0,0x1d
    800049cc:	33850513          	addi	a0,a0,824 # 80021d00 <ftable>
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	214080e7          	jalr	532(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049d8:	40dc                	lw	a5,4(s1)
    800049da:	02f05263          	blez	a5,800049fe <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049de:	2785                	addiw	a5,a5,1
    800049e0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049e2:	0001d517          	auipc	a0,0x1d
    800049e6:	31e50513          	addi	a0,a0,798 # 80021d00 <ftable>
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	2ae080e7          	jalr	686(ra) # 80000c98 <release>
  return f;
}
    800049f2:	8526                	mv	a0,s1
    800049f4:	60e2                	ld	ra,24(sp)
    800049f6:	6442                	ld	s0,16(sp)
    800049f8:	64a2                	ld	s1,8(sp)
    800049fa:	6105                	addi	sp,sp,32
    800049fc:	8082                	ret
    panic("filedup");
    800049fe:	00004517          	auipc	a0,0x4
    80004a02:	c9a50513          	addi	a0,a0,-870 # 80008698 <syscalls+0x250>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	b38080e7          	jalr	-1224(ra) # 8000053e <panic>

0000000080004a0e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a0e:	7139                	addi	sp,sp,-64
    80004a10:	fc06                	sd	ra,56(sp)
    80004a12:	f822                	sd	s0,48(sp)
    80004a14:	f426                	sd	s1,40(sp)
    80004a16:	f04a                	sd	s2,32(sp)
    80004a18:	ec4e                	sd	s3,24(sp)
    80004a1a:	e852                	sd	s4,16(sp)
    80004a1c:	e456                	sd	s5,8(sp)
    80004a1e:	0080                	addi	s0,sp,64
    80004a20:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a22:	0001d517          	auipc	a0,0x1d
    80004a26:	2de50513          	addi	a0,a0,734 # 80021d00 <ftable>
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	1ba080e7          	jalr	442(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a32:	40dc                	lw	a5,4(s1)
    80004a34:	06f05163          	blez	a5,80004a96 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a38:	37fd                	addiw	a5,a5,-1
    80004a3a:	0007871b          	sext.w	a4,a5
    80004a3e:	c0dc                	sw	a5,4(s1)
    80004a40:	06e04363          	bgtz	a4,80004aa6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a44:	0004a903          	lw	s2,0(s1)
    80004a48:	0094ca83          	lbu	s5,9(s1)
    80004a4c:	0104ba03          	ld	s4,16(s1)
    80004a50:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a54:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a58:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a5c:	0001d517          	auipc	a0,0x1d
    80004a60:	2a450513          	addi	a0,a0,676 # 80021d00 <ftable>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	234080e7          	jalr	564(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a6c:	4785                	li	a5,1
    80004a6e:	04f90d63          	beq	s2,a5,80004ac8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a72:	3979                	addiw	s2,s2,-2
    80004a74:	4785                	li	a5,1
    80004a76:	0527e063          	bltu	a5,s2,80004ab6 <fileclose+0xa8>
    begin_op();
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	ac8080e7          	jalr	-1336(ra) # 80004542 <begin_op>
    iput(ff.ip);
    80004a82:	854e                	mv	a0,s3
    80004a84:	fffff097          	auipc	ra,0xfffff
    80004a88:	2a6080e7          	jalr	678(ra) # 80003d2a <iput>
    end_op();
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	b36080e7          	jalr	-1226(ra) # 800045c2 <end_op>
    80004a94:	a00d                	j	80004ab6 <fileclose+0xa8>
    panic("fileclose");
    80004a96:	00004517          	auipc	a0,0x4
    80004a9a:	c0a50513          	addi	a0,a0,-1014 # 800086a0 <syscalls+0x258>
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	aa0080e7          	jalr	-1376(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004aa6:	0001d517          	auipc	a0,0x1d
    80004aaa:	25a50513          	addi	a0,a0,602 # 80021d00 <ftable>
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	1ea080e7          	jalr	490(ra) # 80000c98 <release>
  }
}
    80004ab6:	70e2                	ld	ra,56(sp)
    80004ab8:	7442                	ld	s0,48(sp)
    80004aba:	74a2                	ld	s1,40(sp)
    80004abc:	7902                	ld	s2,32(sp)
    80004abe:	69e2                	ld	s3,24(sp)
    80004ac0:	6a42                	ld	s4,16(sp)
    80004ac2:	6aa2                	ld	s5,8(sp)
    80004ac4:	6121                	addi	sp,sp,64
    80004ac6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ac8:	85d6                	mv	a1,s5
    80004aca:	8552                	mv	a0,s4
    80004acc:	00000097          	auipc	ra,0x0
    80004ad0:	34c080e7          	jalr	844(ra) # 80004e18 <pipeclose>
    80004ad4:	b7cd                	j	80004ab6 <fileclose+0xa8>

0000000080004ad6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ad6:	715d                	addi	sp,sp,-80
    80004ad8:	e486                	sd	ra,72(sp)
    80004ada:	e0a2                	sd	s0,64(sp)
    80004adc:	fc26                	sd	s1,56(sp)
    80004ade:	f84a                	sd	s2,48(sp)
    80004ae0:	f44e                	sd	s3,40(sp)
    80004ae2:	0880                	addi	s0,sp,80
    80004ae4:	84aa                	mv	s1,a0
    80004ae6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ae8:	ffffd097          	auipc	ra,0xffffd
    80004aec:	e20080e7          	jalr	-480(ra) # 80001908 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004af0:	409c                	lw	a5,0(s1)
    80004af2:	37f9                	addiw	a5,a5,-2
    80004af4:	4705                	li	a4,1
    80004af6:	04f76763          	bltu	a4,a5,80004b44 <filestat+0x6e>
    80004afa:	892a                	mv	s2,a0
    ilock(f->ip);
    80004afc:	6c88                	ld	a0,24(s1)
    80004afe:	fffff097          	auipc	ra,0xfffff
    80004b02:	072080e7          	jalr	114(ra) # 80003b70 <ilock>
    stati(f->ip, &st);
    80004b06:	fb840593          	addi	a1,s0,-72
    80004b0a:	6c88                	ld	a0,24(s1)
    80004b0c:	fffff097          	auipc	ra,0xfffff
    80004b10:	2ee080e7          	jalr	750(ra) # 80003dfa <stati>
    iunlock(f->ip);
    80004b14:	6c88                	ld	a0,24(s1)
    80004b16:	fffff097          	auipc	ra,0xfffff
    80004b1a:	11c080e7          	jalr	284(ra) # 80003c32 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b1e:	46e1                	li	a3,24
    80004b20:	fb840613          	addi	a2,s0,-72
    80004b24:	85ce                	mv	a1,s3
    80004b26:	07093503          	ld	a0,112(s2)
    80004b2a:	ffffd097          	auipc	ra,0xffffd
    80004b2e:	b48080e7          	jalr	-1208(ra) # 80001672 <copyout>
    80004b32:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b36:	60a6                	ld	ra,72(sp)
    80004b38:	6406                	ld	s0,64(sp)
    80004b3a:	74e2                	ld	s1,56(sp)
    80004b3c:	7942                	ld	s2,48(sp)
    80004b3e:	79a2                	ld	s3,40(sp)
    80004b40:	6161                	addi	sp,sp,80
    80004b42:	8082                	ret
  return -1;
    80004b44:	557d                	li	a0,-1
    80004b46:	bfc5                	j	80004b36 <filestat+0x60>

0000000080004b48 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b48:	7179                	addi	sp,sp,-48
    80004b4a:	f406                	sd	ra,40(sp)
    80004b4c:	f022                	sd	s0,32(sp)
    80004b4e:	ec26                	sd	s1,24(sp)
    80004b50:	e84a                	sd	s2,16(sp)
    80004b52:	e44e                	sd	s3,8(sp)
    80004b54:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b56:	00854783          	lbu	a5,8(a0)
    80004b5a:	c3d5                	beqz	a5,80004bfe <fileread+0xb6>
    80004b5c:	84aa                	mv	s1,a0
    80004b5e:	89ae                	mv	s3,a1
    80004b60:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b62:	411c                	lw	a5,0(a0)
    80004b64:	4705                	li	a4,1
    80004b66:	04e78963          	beq	a5,a4,80004bb8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b6a:	470d                	li	a4,3
    80004b6c:	04e78d63          	beq	a5,a4,80004bc6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b70:	4709                	li	a4,2
    80004b72:	06e79e63          	bne	a5,a4,80004bee <fileread+0xa6>
    ilock(f->ip);
    80004b76:	6d08                	ld	a0,24(a0)
    80004b78:	fffff097          	auipc	ra,0xfffff
    80004b7c:	ff8080e7          	jalr	-8(ra) # 80003b70 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b80:	874a                	mv	a4,s2
    80004b82:	5094                	lw	a3,32(s1)
    80004b84:	864e                	mv	a2,s3
    80004b86:	4585                	li	a1,1
    80004b88:	6c88                	ld	a0,24(s1)
    80004b8a:	fffff097          	auipc	ra,0xfffff
    80004b8e:	29a080e7          	jalr	666(ra) # 80003e24 <readi>
    80004b92:	892a                	mv	s2,a0
    80004b94:	00a05563          	blez	a0,80004b9e <fileread+0x56>
      f->off += r;
    80004b98:	509c                	lw	a5,32(s1)
    80004b9a:	9fa9                	addw	a5,a5,a0
    80004b9c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b9e:	6c88                	ld	a0,24(s1)
    80004ba0:	fffff097          	auipc	ra,0xfffff
    80004ba4:	092080e7          	jalr	146(ra) # 80003c32 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ba8:	854a                	mv	a0,s2
    80004baa:	70a2                	ld	ra,40(sp)
    80004bac:	7402                	ld	s0,32(sp)
    80004bae:	64e2                	ld	s1,24(sp)
    80004bb0:	6942                	ld	s2,16(sp)
    80004bb2:	69a2                	ld	s3,8(sp)
    80004bb4:	6145                	addi	sp,sp,48
    80004bb6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bb8:	6908                	ld	a0,16(a0)
    80004bba:	00000097          	auipc	ra,0x0
    80004bbe:	3c8080e7          	jalr	968(ra) # 80004f82 <piperead>
    80004bc2:	892a                	mv	s2,a0
    80004bc4:	b7d5                	j	80004ba8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bc6:	02451783          	lh	a5,36(a0)
    80004bca:	03079693          	slli	a3,a5,0x30
    80004bce:	92c1                	srli	a3,a3,0x30
    80004bd0:	4725                	li	a4,9
    80004bd2:	02d76863          	bltu	a4,a3,80004c02 <fileread+0xba>
    80004bd6:	0792                	slli	a5,a5,0x4
    80004bd8:	0001d717          	auipc	a4,0x1d
    80004bdc:	08870713          	addi	a4,a4,136 # 80021c60 <devsw>
    80004be0:	97ba                	add	a5,a5,a4
    80004be2:	639c                	ld	a5,0(a5)
    80004be4:	c38d                	beqz	a5,80004c06 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004be6:	4505                	li	a0,1
    80004be8:	9782                	jalr	a5
    80004bea:	892a                	mv	s2,a0
    80004bec:	bf75                	j	80004ba8 <fileread+0x60>
    panic("fileread");
    80004bee:	00004517          	auipc	a0,0x4
    80004bf2:	ac250513          	addi	a0,a0,-1342 # 800086b0 <syscalls+0x268>
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	948080e7          	jalr	-1720(ra) # 8000053e <panic>
    return -1;
    80004bfe:	597d                	li	s2,-1
    80004c00:	b765                	j	80004ba8 <fileread+0x60>
      return -1;
    80004c02:	597d                	li	s2,-1
    80004c04:	b755                	j	80004ba8 <fileread+0x60>
    80004c06:	597d                	li	s2,-1
    80004c08:	b745                	j	80004ba8 <fileread+0x60>

0000000080004c0a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c0a:	715d                	addi	sp,sp,-80
    80004c0c:	e486                	sd	ra,72(sp)
    80004c0e:	e0a2                	sd	s0,64(sp)
    80004c10:	fc26                	sd	s1,56(sp)
    80004c12:	f84a                	sd	s2,48(sp)
    80004c14:	f44e                	sd	s3,40(sp)
    80004c16:	f052                	sd	s4,32(sp)
    80004c18:	ec56                	sd	s5,24(sp)
    80004c1a:	e85a                	sd	s6,16(sp)
    80004c1c:	e45e                	sd	s7,8(sp)
    80004c1e:	e062                	sd	s8,0(sp)
    80004c20:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c22:	00954783          	lbu	a5,9(a0)
    80004c26:	10078663          	beqz	a5,80004d32 <filewrite+0x128>
    80004c2a:	892a                	mv	s2,a0
    80004c2c:	8aae                	mv	s5,a1
    80004c2e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c30:	411c                	lw	a5,0(a0)
    80004c32:	4705                	li	a4,1
    80004c34:	02e78263          	beq	a5,a4,80004c58 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c38:	470d                	li	a4,3
    80004c3a:	02e78663          	beq	a5,a4,80004c66 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c3e:	4709                	li	a4,2
    80004c40:	0ee79163          	bne	a5,a4,80004d22 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c44:	0ac05d63          	blez	a2,80004cfe <filewrite+0xf4>
    int i = 0;
    80004c48:	4981                	li	s3,0
    80004c4a:	6b05                	lui	s6,0x1
    80004c4c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c50:	6b85                	lui	s7,0x1
    80004c52:	c00b8b9b          	addiw	s7,s7,-1024
    80004c56:	a861                	j	80004cee <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c58:	6908                	ld	a0,16(a0)
    80004c5a:	00000097          	auipc	ra,0x0
    80004c5e:	22e080e7          	jalr	558(ra) # 80004e88 <pipewrite>
    80004c62:	8a2a                	mv	s4,a0
    80004c64:	a045                	j	80004d04 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c66:	02451783          	lh	a5,36(a0)
    80004c6a:	03079693          	slli	a3,a5,0x30
    80004c6e:	92c1                	srli	a3,a3,0x30
    80004c70:	4725                	li	a4,9
    80004c72:	0cd76263          	bltu	a4,a3,80004d36 <filewrite+0x12c>
    80004c76:	0792                	slli	a5,a5,0x4
    80004c78:	0001d717          	auipc	a4,0x1d
    80004c7c:	fe870713          	addi	a4,a4,-24 # 80021c60 <devsw>
    80004c80:	97ba                	add	a5,a5,a4
    80004c82:	679c                	ld	a5,8(a5)
    80004c84:	cbdd                	beqz	a5,80004d3a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c86:	4505                	li	a0,1
    80004c88:	9782                	jalr	a5
    80004c8a:	8a2a                	mv	s4,a0
    80004c8c:	a8a5                	j	80004d04 <filewrite+0xfa>
    80004c8e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c92:	00000097          	auipc	ra,0x0
    80004c96:	8b0080e7          	jalr	-1872(ra) # 80004542 <begin_op>
      ilock(f->ip);
    80004c9a:	01893503          	ld	a0,24(s2)
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	ed2080e7          	jalr	-302(ra) # 80003b70 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ca6:	8762                	mv	a4,s8
    80004ca8:	02092683          	lw	a3,32(s2)
    80004cac:	01598633          	add	a2,s3,s5
    80004cb0:	4585                	li	a1,1
    80004cb2:	01893503          	ld	a0,24(s2)
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	266080e7          	jalr	614(ra) # 80003f1c <writei>
    80004cbe:	84aa                	mv	s1,a0
    80004cc0:	00a05763          	blez	a0,80004cce <filewrite+0xc4>
        f->off += r;
    80004cc4:	02092783          	lw	a5,32(s2)
    80004cc8:	9fa9                	addw	a5,a5,a0
    80004cca:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cce:	01893503          	ld	a0,24(s2)
    80004cd2:	fffff097          	auipc	ra,0xfffff
    80004cd6:	f60080e7          	jalr	-160(ra) # 80003c32 <iunlock>
      end_op();
    80004cda:	00000097          	auipc	ra,0x0
    80004cde:	8e8080e7          	jalr	-1816(ra) # 800045c2 <end_op>

      if(r != n1){
    80004ce2:	009c1f63          	bne	s8,s1,80004d00 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ce6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cea:	0149db63          	bge	s3,s4,80004d00 <filewrite+0xf6>
      int n1 = n - i;
    80004cee:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004cf2:	84be                	mv	s1,a5
    80004cf4:	2781                	sext.w	a5,a5
    80004cf6:	f8fb5ce3          	bge	s6,a5,80004c8e <filewrite+0x84>
    80004cfa:	84de                	mv	s1,s7
    80004cfc:	bf49                	j	80004c8e <filewrite+0x84>
    int i = 0;
    80004cfe:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d00:	013a1f63          	bne	s4,s3,80004d1e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d04:	8552                	mv	a0,s4
    80004d06:	60a6                	ld	ra,72(sp)
    80004d08:	6406                	ld	s0,64(sp)
    80004d0a:	74e2                	ld	s1,56(sp)
    80004d0c:	7942                	ld	s2,48(sp)
    80004d0e:	79a2                	ld	s3,40(sp)
    80004d10:	7a02                	ld	s4,32(sp)
    80004d12:	6ae2                	ld	s5,24(sp)
    80004d14:	6b42                	ld	s6,16(sp)
    80004d16:	6ba2                	ld	s7,8(sp)
    80004d18:	6c02                	ld	s8,0(sp)
    80004d1a:	6161                	addi	sp,sp,80
    80004d1c:	8082                	ret
    ret = (i == n ? n : -1);
    80004d1e:	5a7d                	li	s4,-1
    80004d20:	b7d5                	j	80004d04 <filewrite+0xfa>
    panic("filewrite");
    80004d22:	00004517          	auipc	a0,0x4
    80004d26:	99e50513          	addi	a0,a0,-1634 # 800086c0 <syscalls+0x278>
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	814080e7          	jalr	-2028(ra) # 8000053e <panic>
    return -1;
    80004d32:	5a7d                	li	s4,-1
    80004d34:	bfc1                	j	80004d04 <filewrite+0xfa>
      return -1;
    80004d36:	5a7d                	li	s4,-1
    80004d38:	b7f1                	j	80004d04 <filewrite+0xfa>
    80004d3a:	5a7d                	li	s4,-1
    80004d3c:	b7e1                	j	80004d04 <filewrite+0xfa>

0000000080004d3e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d3e:	7179                	addi	sp,sp,-48
    80004d40:	f406                	sd	ra,40(sp)
    80004d42:	f022                	sd	s0,32(sp)
    80004d44:	ec26                	sd	s1,24(sp)
    80004d46:	e84a                	sd	s2,16(sp)
    80004d48:	e44e                	sd	s3,8(sp)
    80004d4a:	e052                	sd	s4,0(sp)
    80004d4c:	1800                	addi	s0,sp,48
    80004d4e:	84aa                	mv	s1,a0
    80004d50:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d52:	0005b023          	sd	zero,0(a1)
    80004d56:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d5a:	00000097          	auipc	ra,0x0
    80004d5e:	bf8080e7          	jalr	-1032(ra) # 80004952 <filealloc>
    80004d62:	e088                	sd	a0,0(s1)
    80004d64:	c551                	beqz	a0,80004df0 <pipealloc+0xb2>
    80004d66:	00000097          	auipc	ra,0x0
    80004d6a:	bec080e7          	jalr	-1044(ra) # 80004952 <filealloc>
    80004d6e:	00aa3023          	sd	a0,0(s4)
    80004d72:	c92d                	beqz	a0,80004de4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	d80080e7          	jalr	-640(ra) # 80000af4 <kalloc>
    80004d7c:	892a                	mv	s2,a0
    80004d7e:	c125                	beqz	a0,80004dde <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d80:	4985                	li	s3,1
    80004d82:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d86:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d8a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d8e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d92:	00004597          	auipc	a1,0x4
    80004d96:	93e58593          	addi	a1,a1,-1730 # 800086d0 <syscalls+0x288>
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	dba080e7          	jalr	-582(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004da2:	609c                	ld	a5,0(s1)
    80004da4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004da8:	609c                	ld	a5,0(s1)
    80004daa:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dae:	609c                	ld	a5,0(s1)
    80004db0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004db4:	609c                	ld	a5,0(s1)
    80004db6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dba:	000a3783          	ld	a5,0(s4)
    80004dbe:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dc2:	000a3783          	ld	a5,0(s4)
    80004dc6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dca:	000a3783          	ld	a5,0(s4)
    80004dce:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dd2:	000a3783          	ld	a5,0(s4)
    80004dd6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dda:	4501                	li	a0,0
    80004ddc:	a025                	j	80004e04 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dde:	6088                	ld	a0,0(s1)
    80004de0:	e501                	bnez	a0,80004de8 <pipealloc+0xaa>
    80004de2:	a039                	j	80004df0 <pipealloc+0xb2>
    80004de4:	6088                	ld	a0,0(s1)
    80004de6:	c51d                	beqz	a0,80004e14 <pipealloc+0xd6>
    fileclose(*f0);
    80004de8:	00000097          	auipc	ra,0x0
    80004dec:	c26080e7          	jalr	-986(ra) # 80004a0e <fileclose>
  if(*f1)
    80004df0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004df4:	557d                	li	a0,-1
  if(*f1)
    80004df6:	c799                	beqz	a5,80004e04 <pipealloc+0xc6>
    fileclose(*f1);
    80004df8:	853e                	mv	a0,a5
    80004dfa:	00000097          	auipc	ra,0x0
    80004dfe:	c14080e7          	jalr	-1004(ra) # 80004a0e <fileclose>
  return -1;
    80004e02:	557d                	li	a0,-1
}
    80004e04:	70a2                	ld	ra,40(sp)
    80004e06:	7402                	ld	s0,32(sp)
    80004e08:	64e2                	ld	s1,24(sp)
    80004e0a:	6942                	ld	s2,16(sp)
    80004e0c:	69a2                	ld	s3,8(sp)
    80004e0e:	6a02                	ld	s4,0(sp)
    80004e10:	6145                	addi	sp,sp,48
    80004e12:	8082                	ret
  return -1;
    80004e14:	557d                	li	a0,-1
    80004e16:	b7fd                	j	80004e04 <pipealloc+0xc6>

0000000080004e18 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e18:	1101                	addi	sp,sp,-32
    80004e1a:	ec06                	sd	ra,24(sp)
    80004e1c:	e822                	sd	s0,16(sp)
    80004e1e:	e426                	sd	s1,8(sp)
    80004e20:	e04a                	sd	s2,0(sp)
    80004e22:	1000                	addi	s0,sp,32
    80004e24:	84aa                	mv	s1,a0
    80004e26:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	dbc080e7          	jalr	-580(ra) # 80000be4 <acquire>
  if(writable){
    80004e30:	02090d63          	beqz	s2,80004e6a <pipeclose+0x52>
    pi->writeopen = 0;
    80004e34:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e38:	21848513          	addi	a0,s1,536
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	5de080e7          	jalr	1502(ra) # 8000241a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e44:	2204b783          	ld	a5,544(s1)
    80004e48:	eb95                	bnez	a5,80004e7c <pipeclose+0x64>
    release(&pi->lock);
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	e4c080e7          	jalr	-436(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e54:	8526                	mv	a0,s1
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	ba2080e7          	jalr	-1118(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e5e:	60e2                	ld	ra,24(sp)
    80004e60:	6442                	ld	s0,16(sp)
    80004e62:	64a2                	ld	s1,8(sp)
    80004e64:	6902                	ld	s2,0(sp)
    80004e66:	6105                	addi	sp,sp,32
    80004e68:	8082                	ret
    pi->readopen = 0;
    80004e6a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e6e:	21c48513          	addi	a0,s1,540
    80004e72:	ffffd097          	auipc	ra,0xffffd
    80004e76:	5a8080e7          	jalr	1448(ra) # 8000241a <wakeup>
    80004e7a:	b7e9                	j	80004e44 <pipeclose+0x2c>
    release(&pi->lock);
    80004e7c:	8526                	mv	a0,s1
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	e1a080e7          	jalr	-486(ra) # 80000c98 <release>
}
    80004e86:	bfe1                	j	80004e5e <pipeclose+0x46>

0000000080004e88 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e88:	7159                	addi	sp,sp,-112
    80004e8a:	f486                	sd	ra,104(sp)
    80004e8c:	f0a2                	sd	s0,96(sp)
    80004e8e:	eca6                	sd	s1,88(sp)
    80004e90:	e8ca                	sd	s2,80(sp)
    80004e92:	e4ce                	sd	s3,72(sp)
    80004e94:	e0d2                	sd	s4,64(sp)
    80004e96:	fc56                	sd	s5,56(sp)
    80004e98:	f85a                	sd	s6,48(sp)
    80004e9a:	f45e                	sd	s7,40(sp)
    80004e9c:	f062                	sd	s8,32(sp)
    80004e9e:	ec66                	sd	s9,24(sp)
    80004ea0:	1880                	addi	s0,sp,112
    80004ea2:	84aa                	mv	s1,a0
    80004ea4:	8aae                	mv	s5,a1
    80004ea6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	a60080e7          	jalr	-1440(ra) # 80001908 <myproc>
    80004eb0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	d30080e7          	jalr	-720(ra) # 80000be4 <acquire>
  while(i < n){
    80004ebc:	0d405163          	blez	s4,80004f7e <pipewrite+0xf6>
    80004ec0:	8ba6                	mv	s7,s1
  int i = 0;
    80004ec2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ec4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ec6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004eca:	21c48c13          	addi	s8,s1,540
    80004ece:	a08d                	j	80004f30 <pipewrite+0xa8>
      release(&pi->lock);
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	dc6080e7          	jalr	-570(ra) # 80000c98 <release>
      return -1;
    80004eda:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004edc:	854a                	mv	a0,s2
    80004ede:	70a6                	ld	ra,104(sp)
    80004ee0:	7406                	ld	s0,96(sp)
    80004ee2:	64e6                	ld	s1,88(sp)
    80004ee4:	6946                	ld	s2,80(sp)
    80004ee6:	69a6                	ld	s3,72(sp)
    80004ee8:	6a06                	ld	s4,64(sp)
    80004eea:	7ae2                	ld	s5,56(sp)
    80004eec:	7b42                	ld	s6,48(sp)
    80004eee:	7ba2                	ld	s7,40(sp)
    80004ef0:	7c02                	ld	s8,32(sp)
    80004ef2:	6ce2                	ld	s9,24(sp)
    80004ef4:	6165                	addi	sp,sp,112
    80004ef6:	8082                	ret
      wakeup(&pi->nread);
    80004ef8:	8566                	mv	a0,s9
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	520080e7          	jalr	1312(ra) # 8000241a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f02:	85de                	mv	a1,s7
    80004f04:	8562                	mv	a0,s8
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	1a2080e7          	jalr	418(ra) # 800020a8 <sleep>
    80004f0e:	a839                	j	80004f2c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f10:	21c4a783          	lw	a5,540(s1)
    80004f14:	0017871b          	addiw	a4,a5,1
    80004f18:	20e4ae23          	sw	a4,540(s1)
    80004f1c:	1ff7f793          	andi	a5,a5,511
    80004f20:	97a6                	add	a5,a5,s1
    80004f22:	f9f44703          	lbu	a4,-97(s0)
    80004f26:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f2a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f2c:	03495d63          	bge	s2,s4,80004f66 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f30:	2204a783          	lw	a5,544(s1)
    80004f34:	dfd1                	beqz	a5,80004ed0 <pipewrite+0x48>
    80004f36:	0289a783          	lw	a5,40(s3)
    80004f3a:	fbd9                	bnez	a5,80004ed0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f3c:	2184a783          	lw	a5,536(s1)
    80004f40:	21c4a703          	lw	a4,540(s1)
    80004f44:	2007879b          	addiw	a5,a5,512
    80004f48:	faf708e3          	beq	a4,a5,80004ef8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f4c:	4685                	li	a3,1
    80004f4e:	01590633          	add	a2,s2,s5
    80004f52:	f9f40593          	addi	a1,s0,-97
    80004f56:	0709b503          	ld	a0,112(s3)
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	7a4080e7          	jalr	1956(ra) # 800016fe <copyin>
    80004f62:	fb6517e3          	bne	a0,s6,80004f10 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f66:	21848513          	addi	a0,s1,536
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	4b0080e7          	jalr	1200(ra) # 8000241a <wakeup>
  release(&pi->lock);
    80004f72:	8526                	mv	a0,s1
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	d24080e7          	jalr	-732(ra) # 80000c98 <release>
  return i;
    80004f7c:	b785                	j	80004edc <pipewrite+0x54>
  int i = 0;
    80004f7e:	4901                	li	s2,0
    80004f80:	b7dd                	j	80004f66 <pipewrite+0xde>

0000000080004f82 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f82:	715d                	addi	sp,sp,-80
    80004f84:	e486                	sd	ra,72(sp)
    80004f86:	e0a2                	sd	s0,64(sp)
    80004f88:	fc26                	sd	s1,56(sp)
    80004f8a:	f84a                	sd	s2,48(sp)
    80004f8c:	f44e                	sd	s3,40(sp)
    80004f8e:	f052                	sd	s4,32(sp)
    80004f90:	ec56                	sd	s5,24(sp)
    80004f92:	e85a                	sd	s6,16(sp)
    80004f94:	0880                	addi	s0,sp,80
    80004f96:	84aa                	mv	s1,a0
    80004f98:	892e                	mv	s2,a1
    80004f9a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	96c080e7          	jalr	-1684(ra) # 80001908 <myproc>
    80004fa4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fa6:	8b26                	mv	s6,s1
    80004fa8:	8526                	mv	a0,s1
    80004faa:	ffffc097          	auipc	ra,0xffffc
    80004fae:	c3a080e7          	jalr	-966(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fb2:	2184a703          	lw	a4,536(s1)
    80004fb6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fba:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fbe:	02f71463          	bne	a4,a5,80004fe6 <piperead+0x64>
    80004fc2:	2244a783          	lw	a5,548(s1)
    80004fc6:	c385                	beqz	a5,80004fe6 <piperead+0x64>
    if(pr->killed){
    80004fc8:	028a2783          	lw	a5,40(s4)
    80004fcc:	ebc1                	bnez	a5,8000505c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fce:	85da                	mv	a1,s6
    80004fd0:	854e                	mv	a0,s3
    80004fd2:	ffffd097          	auipc	ra,0xffffd
    80004fd6:	0d6080e7          	jalr	214(ra) # 800020a8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fda:	2184a703          	lw	a4,536(s1)
    80004fde:	21c4a783          	lw	a5,540(s1)
    80004fe2:	fef700e3          	beq	a4,a5,80004fc2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fe6:	09505263          	blez	s5,8000506a <piperead+0xe8>
    80004fea:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fec:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004fee:	2184a783          	lw	a5,536(s1)
    80004ff2:	21c4a703          	lw	a4,540(s1)
    80004ff6:	02f70d63          	beq	a4,a5,80005030 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ffa:	0017871b          	addiw	a4,a5,1
    80004ffe:	20e4ac23          	sw	a4,536(s1)
    80005002:	1ff7f793          	andi	a5,a5,511
    80005006:	97a6                	add	a5,a5,s1
    80005008:	0187c783          	lbu	a5,24(a5)
    8000500c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005010:	4685                	li	a3,1
    80005012:	fbf40613          	addi	a2,s0,-65
    80005016:	85ca                	mv	a1,s2
    80005018:	070a3503          	ld	a0,112(s4)
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	656080e7          	jalr	1622(ra) # 80001672 <copyout>
    80005024:	01650663          	beq	a0,s6,80005030 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005028:	2985                	addiw	s3,s3,1
    8000502a:	0905                	addi	s2,s2,1
    8000502c:	fd3a91e3          	bne	s5,s3,80004fee <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005030:	21c48513          	addi	a0,s1,540
    80005034:	ffffd097          	auipc	ra,0xffffd
    80005038:	3e6080e7          	jalr	998(ra) # 8000241a <wakeup>
  release(&pi->lock);
    8000503c:	8526                	mv	a0,s1
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	c5a080e7          	jalr	-934(ra) # 80000c98 <release>
  return i;
}
    80005046:	854e                	mv	a0,s3
    80005048:	60a6                	ld	ra,72(sp)
    8000504a:	6406                	ld	s0,64(sp)
    8000504c:	74e2                	ld	s1,56(sp)
    8000504e:	7942                	ld	s2,48(sp)
    80005050:	79a2                	ld	s3,40(sp)
    80005052:	7a02                	ld	s4,32(sp)
    80005054:	6ae2                	ld	s5,24(sp)
    80005056:	6b42                	ld	s6,16(sp)
    80005058:	6161                	addi	sp,sp,80
    8000505a:	8082                	ret
      release(&pi->lock);
    8000505c:	8526                	mv	a0,s1
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	c3a080e7          	jalr	-966(ra) # 80000c98 <release>
      return -1;
    80005066:	59fd                	li	s3,-1
    80005068:	bff9                	j	80005046 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000506a:	4981                	li	s3,0
    8000506c:	b7d1                	j	80005030 <piperead+0xae>

000000008000506e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000506e:	df010113          	addi	sp,sp,-528
    80005072:	20113423          	sd	ra,520(sp)
    80005076:	20813023          	sd	s0,512(sp)
    8000507a:	ffa6                	sd	s1,504(sp)
    8000507c:	fbca                	sd	s2,496(sp)
    8000507e:	f7ce                	sd	s3,488(sp)
    80005080:	f3d2                	sd	s4,480(sp)
    80005082:	efd6                	sd	s5,472(sp)
    80005084:	ebda                	sd	s6,464(sp)
    80005086:	e7de                	sd	s7,456(sp)
    80005088:	e3e2                	sd	s8,448(sp)
    8000508a:	ff66                	sd	s9,440(sp)
    8000508c:	fb6a                	sd	s10,432(sp)
    8000508e:	f76e                	sd	s11,424(sp)
    80005090:	0c00                	addi	s0,sp,528
    80005092:	84aa                	mv	s1,a0
    80005094:	dea43c23          	sd	a0,-520(s0)
    80005098:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	86c080e7          	jalr	-1940(ra) # 80001908 <myproc>
    800050a4:	892a                	mv	s2,a0

  begin_op();
    800050a6:	fffff097          	auipc	ra,0xfffff
    800050aa:	49c080e7          	jalr	1180(ra) # 80004542 <begin_op>

  if((ip = namei(path)) == 0){
    800050ae:	8526                	mv	a0,s1
    800050b0:	fffff097          	auipc	ra,0xfffff
    800050b4:	276080e7          	jalr	630(ra) # 80004326 <namei>
    800050b8:	c92d                	beqz	a0,8000512a <exec+0xbc>
    800050ba:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	ab4080e7          	jalr	-1356(ra) # 80003b70 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050c4:	04000713          	li	a4,64
    800050c8:	4681                	li	a3,0
    800050ca:	e5040613          	addi	a2,s0,-432
    800050ce:	4581                	li	a1,0
    800050d0:	8526                	mv	a0,s1
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	d52080e7          	jalr	-686(ra) # 80003e24 <readi>
    800050da:	04000793          	li	a5,64
    800050de:	00f51a63          	bne	a0,a5,800050f2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050e2:	e5042703          	lw	a4,-432(s0)
    800050e6:	464c47b7          	lui	a5,0x464c4
    800050ea:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050ee:	04f70463          	beq	a4,a5,80005136 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050f2:	8526                	mv	a0,s1
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	cde080e7          	jalr	-802(ra) # 80003dd2 <iunlockput>
    end_op();
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	4c6080e7          	jalr	1222(ra) # 800045c2 <end_op>
  }
  return -1;
    80005104:	557d                	li	a0,-1
}
    80005106:	20813083          	ld	ra,520(sp)
    8000510a:	20013403          	ld	s0,512(sp)
    8000510e:	74fe                	ld	s1,504(sp)
    80005110:	795e                	ld	s2,496(sp)
    80005112:	79be                	ld	s3,488(sp)
    80005114:	7a1e                	ld	s4,480(sp)
    80005116:	6afe                	ld	s5,472(sp)
    80005118:	6b5e                	ld	s6,464(sp)
    8000511a:	6bbe                	ld	s7,456(sp)
    8000511c:	6c1e                	ld	s8,448(sp)
    8000511e:	7cfa                	ld	s9,440(sp)
    80005120:	7d5a                	ld	s10,432(sp)
    80005122:	7dba                	ld	s11,424(sp)
    80005124:	21010113          	addi	sp,sp,528
    80005128:	8082                	ret
    end_op();
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	498080e7          	jalr	1176(ra) # 800045c2 <end_op>
    return -1;
    80005132:	557d                	li	a0,-1
    80005134:	bfc9                	j	80005106 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005136:	854a                	mv	a0,s2
    80005138:	ffffd097          	auipc	ra,0xffffd
    8000513c:	88e080e7          	jalr	-1906(ra) # 800019c6 <proc_pagetable>
    80005140:	8baa                	mv	s7,a0
    80005142:	d945                	beqz	a0,800050f2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005144:	e7042983          	lw	s3,-400(s0)
    80005148:	e8845783          	lhu	a5,-376(s0)
    8000514c:	c7ad                	beqz	a5,800051b6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000514e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005150:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005152:	6c85                	lui	s9,0x1
    80005154:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005158:	def43823          	sd	a5,-528(s0)
    8000515c:	a42d                	j	80005386 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000515e:	00003517          	auipc	a0,0x3
    80005162:	57a50513          	addi	a0,a0,1402 # 800086d8 <syscalls+0x290>
    80005166:	ffffb097          	auipc	ra,0xffffb
    8000516a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000516e:	8756                	mv	a4,s5
    80005170:	012d86bb          	addw	a3,s11,s2
    80005174:	4581                	li	a1,0
    80005176:	8526                	mv	a0,s1
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	cac080e7          	jalr	-852(ra) # 80003e24 <readi>
    80005180:	2501                	sext.w	a0,a0
    80005182:	1aaa9963          	bne	s5,a0,80005334 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005186:	6785                	lui	a5,0x1
    80005188:	0127893b          	addw	s2,a5,s2
    8000518c:	77fd                	lui	a5,0xfffff
    8000518e:	01478a3b          	addw	s4,a5,s4
    80005192:	1f897163          	bgeu	s2,s8,80005374 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005196:	02091593          	slli	a1,s2,0x20
    8000519a:	9181                	srli	a1,a1,0x20
    8000519c:	95ea                	add	a1,a1,s10
    8000519e:	855e                	mv	a0,s7
    800051a0:	ffffc097          	auipc	ra,0xffffc
    800051a4:	ece080e7          	jalr	-306(ra) # 8000106e <walkaddr>
    800051a8:	862a                	mv	a2,a0
    if(pa == 0)
    800051aa:	d955                	beqz	a0,8000515e <exec+0xf0>
      n = PGSIZE;
    800051ac:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051ae:	fd9a70e3          	bgeu	s4,s9,8000516e <exec+0x100>
      n = sz - i;
    800051b2:	8ad2                	mv	s5,s4
    800051b4:	bf6d                	j	8000516e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051b6:	4901                	li	s2,0
  iunlockput(ip);
    800051b8:	8526                	mv	a0,s1
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	c18080e7          	jalr	-1000(ra) # 80003dd2 <iunlockput>
  end_op();
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	400080e7          	jalr	1024(ra) # 800045c2 <end_op>
  p = myproc();
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	73e080e7          	jalr	1854(ra) # 80001908 <myproc>
    800051d2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051d4:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800051d8:	6785                	lui	a5,0x1
    800051da:	17fd                	addi	a5,a5,-1
    800051dc:	993e                	add	s2,s2,a5
    800051de:	757d                	lui	a0,0xfffff
    800051e0:	00a977b3          	and	a5,s2,a0
    800051e4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051e8:	6609                	lui	a2,0x2
    800051ea:	963e                	add	a2,a2,a5
    800051ec:	85be                	mv	a1,a5
    800051ee:	855e                	mv	a0,s7
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	232080e7          	jalr	562(ra) # 80001422 <uvmalloc>
    800051f8:	8b2a                	mv	s6,a0
  ip = 0;
    800051fa:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051fc:	12050c63          	beqz	a0,80005334 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005200:	75f9                	lui	a1,0xffffe
    80005202:	95aa                	add	a1,a1,a0
    80005204:	855e                	mv	a0,s7
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	43a080e7          	jalr	1082(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000520e:	7c7d                	lui	s8,0xfffff
    80005210:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005212:	e0043783          	ld	a5,-512(s0)
    80005216:	6388                	ld	a0,0(a5)
    80005218:	c535                	beqz	a0,80005284 <exec+0x216>
    8000521a:	e9040993          	addi	s3,s0,-368
    8000521e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005222:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	c40080e7          	jalr	-960(ra) # 80000e64 <strlen>
    8000522c:	2505                	addiw	a0,a0,1
    8000522e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005232:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005236:	13896363          	bltu	s2,s8,8000535c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000523a:	e0043d83          	ld	s11,-512(s0)
    8000523e:	000dba03          	ld	s4,0(s11)
    80005242:	8552                	mv	a0,s4
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	c20080e7          	jalr	-992(ra) # 80000e64 <strlen>
    8000524c:	0015069b          	addiw	a3,a0,1
    80005250:	8652                	mv	a2,s4
    80005252:	85ca                	mv	a1,s2
    80005254:	855e                	mv	a0,s7
    80005256:	ffffc097          	auipc	ra,0xffffc
    8000525a:	41c080e7          	jalr	1052(ra) # 80001672 <copyout>
    8000525e:	10054363          	bltz	a0,80005364 <exec+0x2f6>
    ustack[argc] = sp;
    80005262:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005266:	0485                	addi	s1,s1,1
    80005268:	008d8793          	addi	a5,s11,8
    8000526c:	e0f43023          	sd	a5,-512(s0)
    80005270:	008db503          	ld	a0,8(s11)
    80005274:	c911                	beqz	a0,80005288 <exec+0x21a>
    if(argc >= MAXARG)
    80005276:	09a1                	addi	s3,s3,8
    80005278:	fb3c96e3          	bne	s9,s3,80005224 <exec+0x1b6>
  sz = sz1;
    8000527c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005280:	4481                	li	s1,0
    80005282:	a84d                	j	80005334 <exec+0x2c6>
  sp = sz;
    80005284:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005286:	4481                	li	s1,0
  ustack[argc] = 0;
    80005288:	00349793          	slli	a5,s1,0x3
    8000528c:	f9040713          	addi	a4,s0,-112
    80005290:	97ba                	add	a5,a5,a4
    80005292:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005296:	00148693          	addi	a3,s1,1
    8000529a:	068e                	slli	a3,a3,0x3
    8000529c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052a0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052a4:	01897663          	bgeu	s2,s8,800052b0 <exec+0x242>
  sz = sz1;
    800052a8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052ac:	4481                	li	s1,0
    800052ae:	a059                	j	80005334 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052b0:	e9040613          	addi	a2,s0,-368
    800052b4:	85ca                	mv	a1,s2
    800052b6:	855e                	mv	a0,s7
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	3ba080e7          	jalr	954(ra) # 80001672 <copyout>
    800052c0:	0a054663          	bltz	a0,8000536c <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052c4:	078ab783          	ld	a5,120(s5)
    800052c8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052cc:	df843783          	ld	a5,-520(s0)
    800052d0:	0007c703          	lbu	a4,0(a5)
    800052d4:	cf11                	beqz	a4,800052f0 <exec+0x282>
    800052d6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052d8:	02f00693          	li	a3,47
    800052dc:	a039                	j	800052ea <exec+0x27c>
      last = s+1;
    800052de:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052e2:	0785                	addi	a5,a5,1
    800052e4:	fff7c703          	lbu	a4,-1(a5)
    800052e8:	c701                	beqz	a4,800052f0 <exec+0x282>
    if(*s == '/')
    800052ea:	fed71ce3          	bne	a4,a3,800052e2 <exec+0x274>
    800052ee:	bfc5                	j	800052de <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800052f0:	4641                	li	a2,16
    800052f2:	df843583          	ld	a1,-520(s0)
    800052f6:	178a8513          	addi	a0,s5,376
    800052fa:	ffffc097          	auipc	ra,0xffffc
    800052fe:	b38080e7          	jalr	-1224(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005302:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005306:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    8000530a:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000530e:	078ab783          	ld	a5,120(s5)
    80005312:	e6843703          	ld	a4,-408(s0)
    80005316:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005318:	078ab783          	ld	a5,120(s5)
    8000531c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005320:	85ea                	mv	a1,s10
    80005322:	ffffc097          	auipc	ra,0xffffc
    80005326:	740080e7          	jalr	1856(ra) # 80001a62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000532a:	0004851b          	sext.w	a0,s1
    8000532e:	bbe1                	j	80005106 <exec+0x98>
    80005330:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005334:	e0843583          	ld	a1,-504(s0)
    80005338:	855e                	mv	a0,s7
    8000533a:	ffffc097          	auipc	ra,0xffffc
    8000533e:	728080e7          	jalr	1832(ra) # 80001a62 <proc_freepagetable>
  if(ip){
    80005342:	da0498e3          	bnez	s1,800050f2 <exec+0x84>
  return -1;
    80005346:	557d                	li	a0,-1
    80005348:	bb7d                	j	80005106 <exec+0x98>
    8000534a:	e1243423          	sd	s2,-504(s0)
    8000534e:	b7dd                	j	80005334 <exec+0x2c6>
    80005350:	e1243423          	sd	s2,-504(s0)
    80005354:	b7c5                	j	80005334 <exec+0x2c6>
    80005356:	e1243423          	sd	s2,-504(s0)
    8000535a:	bfe9                	j	80005334 <exec+0x2c6>
  sz = sz1;
    8000535c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005360:	4481                	li	s1,0
    80005362:	bfc9                	j	80005334 <exec+0x2c6>
  sz = sz1;
    80005364:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005368:	4481                	li	s1,0
    8000536a:	b7e9                	j	80005334 <exec+0x2c6>
  sz = sz1;
    8000536c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005370:	4481                	li	s1,0
    80005372:	b7c9                	j	80005334 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005374:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005378:	2b05                	addiw	s6,s6,1
    8000537a:	0389899b          	addiw	s3,s3,56
    8000537e:	e8845783          	lhu	a5,-376(s0)
    80005382:	e2fb5be3          	bge	s6,a5,800051b8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005386:	2981                	sext.w	s3,s3
    80005388:	03800713          	li	a4,56
    8000538c:	86ce                	mv	a3,s3
    8000538e:	e1840613          	addi	a2,s0,-488
    80005392:	4581                	li	a1,0
    80005394:	8526                	mv	a0,s1
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	a8e080e7          	jalr	-1394(ra) # 80003e24 <readi>
    8000539e:	03800793          	li	a5,56
    800053a2:	f8f517e3          	bne	a0,a5,80005330 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053a6:	e1842783          	lw	a5,-488(s0)
    800053aa:	4705                	li	a4,1
    800053ac:	fce796e3          	bne	a5,a4,80005378 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053b0:	e4043603          	ld	a2,-448(s0)
    800053b4:	e3843783          	ld	a5,-456(s0)
    800053b8:	f8f669e3          	bltu	a2,a5,8000534a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053bc:	e2843783          	ld	a5,-472(s0)
    800053c0:	963e                	add	a2,a2,a5
    800053c2:	f8f667e3          	bltu	a2,a5,80005350 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053c6:	85ca                	mv	a1,s2
    800053c8:	855e                	mv	a0,s7
    800053ca:	ffffc097          	auipc	ra,0xffffc
    800053ce:	058080e7          	jalr	88(ra) # 80001422 <uvmalloc>
    800053d2:	e0a43423          	sd	a0,-504(s0)
    800053d6:	d141                	beqz	a0,80005356 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053d8:	e2843d03          	ld	s10,-472(s0)
    800053dc:	df043783          	ld	a5,-528(s0)
    800053e0:	00fd77b3          	and	a5,s10,a5
    800053e4:	fba1                	bnez	a5,80005334 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053e6:	e2042d83          	lw	s11,-480(s0)
    800053ea:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053ee:	f80c03e3          	beqz	s8,80005374 <exec+0x306>
    800053f2:	8a62                	mv	s4,s8
    800053f4:	4901                	li	s2,0
    800053f6:	b345                	j	80005196 <exec+0x128>

00000000800053f8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053f8:	7179                	addi	sp,sp,-48
    800053fa:	f406                	sd	ra,40(sp)
    800053fc:	f022                	sd	s0,32(sp)
    800053fe:	ec26                	sd	s1,24(sp)
    80005400:	e84a                	sd	s2,16(sp)
    80005402:	1800                	addi	s0,sp,48
    80005404:	892e                	mv	s2,a1
    80005406:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005408:	fdc40593          	addi	a1,s0,-36
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	ba8080e7          	jalr	-1112(ra) # 80002fb4 <argint>
    80005414:	04054063          	bltz	a0,80005454 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005418:	fdc42703          	lw	a4,-36(s0)
    8000541c:	47bd                	li	a5,15
    8000541e:	02e7ed63          	bltu	a5,a4,80005458 <argfd+0x60>
    80005422:	ffffc097          	auipc	ra,0xffffc
    80005426:	4e6080e7          	jalr	1254(ra) # 80001908 <myproc>
    8000542a:	fdc42703          	lw	a4,-36(s0)
    8000542e:	01e70793          	addi	a5,a4,30
    80005432:	078e                	slli	a5,a5,0x3
    80005434:	953e                	add	a0,a0,a5
    80005436:	611c                	ld	a5,0(a0)
    80005438:	c395                	beqz	a5,8000545c <argfd+0x64>
    return -1;
  if(pfd)
    8000543a:	00090463          	beqz	s2,80005442 <argfd+0x4a>
    *pfd = fd;
    8000543e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005442:	4501                	li	a0,0
  if(pf)
    80005444:	c091                	beqz	s1,80005448 <argfd+0x50>
    *pf = f;
    80005446:	e09c                	sd	a5,0(s1)
}
    80005448:	70a2                	ld	ra,40(sp)
    8000544a:	7402                	ld	s0,32(sp)
    8000544c:	64e2                	ld	s1,24(sp)
    8000544e:	6942                	ld	s2,16(sp)
    80005450:	6145                	addi	sp,sp,48
    80005452:	8082                	ret
    return -1;
    80005454:	557d                	li	a0,-1
    80005456:	bfcd                	j	80005448 <argfd+0x50>
    return -1;
    80005458:	557d                	li	a0,-1
    8000545a:	b7fd                	j	80005448 <argfd+0x50>
    8000545c:	557d                	li	a0,-1
    8000545e:	b7ed                	j	80005448 <argfd+0x50>

0000000080005460 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005460:	1101                	addi	sp,sp,-32
    80005462:	ec06                	sd	ra,24(sp)
    80005464:	e822                	sd	s0,16(sp)
    80005466:	e426                	sd	s1,8(sp)
    80005468:	1000                	addi	s0,sp,32
    8000546a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000546c:	ffffc097          	auipc	ra,0xffffc
    80005470:	49c080e7          	jalr	1180(ra) # 80001908 <myproc>
    80005474:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005476:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    8000547a:	4501                	li	a0,0
    8000547c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000547e:	6398                	ld	a4,0(a5)
    80005480:	cb19                	beqz	a4,80005496 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005482:	2505                	addiw	a0,a0,1
    80005484:	07a1                	addi	a5,a5,8
    80005486:	fed51ce3          	bne	a0,a3,8000547e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000548a:	557d                	li	a0,-1
}
    8000548c:	60e2                	ld	ra,24(sp)
    8000548e:	6442                	ld	s0,16(sp)
    80005490:	64a2                	ld	s1,8(sp)
    80005492:	6105                	addi	sp,sp,32
    80005494:	8082                	ret
      p->ofile[fd] = f;
    80005496:	01e50793          	addi	a5,a0,30
    8000549a:	078e                	slli	a5,a5,0x3
    8000549c:	963e                	add	a2,a2,a5
    8000549e:	e204                	sd	s1,0(a2)
      return fd;
    800054a0:	b7f5                	j	8000548c <fdalloc+0x2c>

00000000800054a2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054a2:	715d                	addi	sp,sp,-80
    800054a4:	e486                	sd	ra,72(sp)
    800054a6:	e0a2                	sd	s0,64(sp)
    800054a8:	fc26                	sd	s1,56(sp)
    800054aa:	f84a                	sd	s2,48(sp)
    800054ac:	f44e                	sd	s3,40(sp)
    800054ae:	f052                	sd	s4,32(sp)
    800054b0:	ec56                	sd	s5,24(sp)
    800054b2:	0880                	addi	s0,sp,80
    800054b4:	89ae                	mv	s3,a1
    800054b6:	8ab2                	mv	s5,a2
    800054b8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054ba:	fb040593          	addi	a1,s0,-80
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	e86080e7          	jalr	-378(ra) # 80004344 <nameiparent>
    800054c6:	892a                	mv	s2,a0
    800054c8:	12050f63          	beqz	a0,80005606 <create+0x164>
    return 0;

  ilock(dp);
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	6a4080e7          	jalr	1700(ra) # 80003b70 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054d4:	4601                	li	a2,0
    800054d6:	fb040593          	addi	a1,s0,-80
    800054da:	854a                	mv	a0,s2
    800054dc:	fffff097          	auipc	ra,0xfffff
    800054e0:	b78080e7          	jalr	-1160(ra) # 80004054 <dirlookup>
    800054e4:	84aa                	mv	s1,a0
    800054e6:	c921                	beqz	a0,80005536 <create+0x94>
    iunlockput(dp);
    800054e8:	854a                	mv	a0,s2
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	8e8080e7          	jalr	-1816(ra) # 80003dd2 <iunlockput>
    ilock(ip);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	67c080e7          	jalr	1660(ra) # 80003b70 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054fc:	2981                	sext.w	s3,s3
    800054fe:	4789                	li	a5,2
    80005500:	02f99463          	bne	s3,a5,80005528 <create+0x86>
    80005504:	0444d783          	lhu	a5,68(s1)
    80005508:	37f9                	addiw	a5,a5,-2
    8000550a:	17c2                	slli	a5,a5,0x30
    8000550c:	93c1                	srli	a5,a5,0x30
    8000550e:	4705                	li	a4,1
    80005510:	00f76c63          	bltu	a4,a5,80005528 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005514:	8526                	mv	a0,s1
    80005516:	60a6                	ld	ra,72(sp)
    80005518:	6406                	ld	s0,64(sp)
    8000551a:	74e2                	ld	s1,56(sp)
    8000551c:	7942                	ld	s2,48(sp)
    8000551e:	79a2                	ld	s3,40(sp)
    80005520:	7a02                	ld	s4,32(sp)
    80005522:	6ae2                	ld	s5,24(sp)
    80005524:	6161                	addi	sp,sp,80
    80005526:	8082                	ret
    iunlockput(ip);
    80005528:	8526                	mv	a0,s1
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	8a8080e7          	jalr	-1880(ra) # 80003dd2 <iunlockput>
    return 0;
    80005532:	4481                	li	s1,0
    80005534:	b7c5                	j	80005514 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005536:	85ce                	mv	a1,s3
    80005538:	00092503          	lw	a0,0(s2)
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	49c080e7          	jalr	1180(ra) # 800039d8 <ialloc>
    80005544:	84aa                	mv	s1,a0
    80005546:	c529                	beqz	a0,80005590 <create+0xee>
  ilock(ip);
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	628080e7          	jalr	1576(ra) # 80003b70 <ilock>
  ip->major = major;
    80005550:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005554:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005558:	4785                	li	a5,1
    8000555a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000555e:	8526                	mv	a0,s1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	546080e7          	jalr	1350(ra) # 80003aa6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005568:	2981                	sext.w	s3,s3
    8000556a:	4785                	li	a5,1
    8000556c:	02f98a63          	beq	s3,a5,800055a0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005570:	40d0                	lw	a2,4(s1)
    80005572:	fb040593          	addi	a1,s0,-80
    80005576:	854a                	mv	a0,s2
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	cec080e7          	jalr	-788(ra) # 80004264 <dirlink>
    80005580:	06054b63          	bltz	a0,800055f6 <create+0x154>
  iunlockput(dp);
    80005584:	854a                	mv	a0,s2
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	84c080e7          	jalr	-1972(ra) # 80003dd2 <iunlockput>
  return ip;
    8000558e:	b759                	j	80005514 <create+0x72>
    panic("create: ialloc");
    80005590:	00003517          	auipc	a0,0x3
    80005594:	16850513          	addi	a0,a0,360 # 800086f8 <syscalls+0x2b0>
    80005598:	ffffb097          	auipc	ra,0xffffb
    8000559c:	fa6080e7          	jalr	-90(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055a0:	04a95783          	lhu	a5,74(s2)
    800055a4:	2785                	addiw	a5,a5,1
    800055a6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055aa:	854a                	mv	a0,s2
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	4fa080e7          	jalr	1274(ra) # 80003aa6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055b4:	40d0                	lw	a2,4(s1)
    800055b6:	00003597          	auipc	a1,0x3
    800055ba:	15258593          	addi	a1,a1,338 # 80008708 <syscalls+0x2c0>
    800055be:	8526                	mv	a0,s1
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	ca4080e7          	jalr	-860(ra) # 80004264 <dirlink>
    800055c8:	00054f63          	bltz	a0,800055e6 <create+0x144>
    800055cc:	00492603          	lw	a2,4(s2)
    800055d0:	00003597          	auipc	a1,0x3
    800055d4:	14058593          	addi	a1,a1,320 # 80008710 <syscalls+0x2c8>
    800055d8:	8526                	mv	a0,s1
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	c8a080e7          	jalr	-886(ra) # 80004264 <dirlink>
    800055e2:	f80557e3          	bgez	a0,80005570 <create+0xce>
      panic("create dots");
    800055e6:	00003517          	auipc	a0,0x3
    800055ea:	13250513          	addi	a0,a0,306 # 80008718 <syscalls+0x2d0>
    800055ee:	ffffb097          	auipc	ra,0xffffb
    800055f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>
    panic("create: dirlink");
    800055f6:	00003517          	auipc	a0,0x3
    800055fa:	13250513          	addi	a0,a0,306 # 80008728 <syscalls+0x2e0>
    800055fe:	ffffb097          	auipc	ra,0xffffb
    80005602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
    return 0;
    80005606:	84aa                	mv	s1,a0
    80005608:	b731                	j	80005514 <create+0x72>

000000008000560a <sys_dup>:
{
    8000560a:	7179                	addi	sp,sp,-48
    8000560c:	f406                	sd	ra,40(sp)
    8000560e:	f022                	sd	s0,32(sp)
    80005610:	ec26                	sd	s1,24(sp)
    80005612:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005614:	fd840613          	addi	a2,s0,-40
    80005618:	4581                	li	a1,0
    8000561a:	4501                	li	a0,0
    8000561c:	00000097          	auipc	ra,0x0
    80005620:	ddc080e7          	jalr	-548(ra) # 800053f8 <argfd>
    return -1;
    80005624:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005626:	02054363          	bltz	a0,8000564c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000562a:	fd843503          	ld	a0,-40(s0)
    8000562e:	00000097          	auipc	ra,0x0
    80005632:	e32080e7          	jalr	-462(ra) # 80005460 <fdalloc>
    80005636:	84aa                	mv	s1,a0
    return -1;
    80005638:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000563a:	00054963          	bltz	a0,8000564c <sys_dup+0x42>
  filedup(f);
    8000563e:	fd843503          	ld	a0,-40(s0)
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	37a080e7          	jalr	890(ra) # 800049bc <filedup>
  return fd;
    8000564a:	87a6                	mv	a5,s1
}
    8000564c:	853e                	mv	a0,a5
    8000564e:	70a2                	ld	ra,40(sp)
    80005650:	7402                	ld	s0,32(sp)
    80005652:	64e2                	ld	s1,24(sp)
    80005654:	6145                	addi	sp,sp,48
    80005656:	8082                	ret

0000000080005658 <sys_read>:
{
    80005658:	7179                	addi	sp,sp,-48
    8000565a:	f406                	sd	ra,40(sp)
    8000565c:	f022                	sd	s0,32(sp)
    8000565e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005660:	fe840613          	addi	a2,s0,-24
    80005664:	4581                	li	a1,0
    80005666:	4501                	li	a0,0
    80005668:	00000097          	auipc	ra,0x0
    8000566c:	d90080e7          	jalr	-624(ra) # 800053f8 <argfd>
    return -1;
    80005670:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005672:	04054163          	bltz	a0,800056b4 <sys_read+0x5c>
    80005676:	fe440593          	addi	a1,s0,-28
    8000567a:	4509                	li	a0,2
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	938080e7          	jalr	-1736(ra) # 80002fb4 <argint>
    return -1;
    80005684:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005686:	02054763          	bltz	a0,800056b4 <sys_read+0x5c>
    8000568a:	fd840593          	addi	a1,s0,-40
    8000568e:	4505                	li	a0,1
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	946080e7          	jalr	-1722(ra) # 80002fd6 <argaddr>
    return -1;
    80005698:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000569a:	00054d63          	bltz	a0,800056b4 <sys_read+0x5c>
  return fileread(f, p, n);
    8000569e:	fe442603          	lw	a2,-28(s0)
    800056a2:	fd843583          	ld	a1,-40(s0)
    800056a6:	fe843503          	ld	a0,-24(s0)
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	49e080e7          	jalr	1182(ra) # 80004b48 <fileread>
    800056b2:	87aa                	mv	a5,a0
}
    800056b4:	853e                	mv	a0,a5
    800056b6:	70a2                	ld	ra,40(sp)
    800056b8:	7402                	ld	s0,32(sp)
    800056ba:	6145                	addi	sp,sp,48
    800056bc:	8082                	ret

00000000800056be <sys_write>:
{
    800056be:	7179                	addi	sp,sp,-48
    800056c0:	f406                	sd	ra,40(sp)
    800056c2:	f022                	sd	s0,32(sp)
    800056c4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056c6:	fe840613          	addi	a2,s0,-24
    800056ca:	4581                	li	a1,0
    800056cc:	4501                	li	a0,0
    800056ce:	00000097          	auipc	ra,0x0
    800056d2:	d2a080e7          	jalr	-726(ra) # 800053f8 <argfd>
    return -1;
    800056d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d8:	04054163          	bltz	a0,8000571a <sys_write+0x5c>
    800056dc:	fe440593          	addi	a1,s0,-28
    800056e0:	4509                	li	a0,2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	8d2080e7          	jalr	-1838(ra) # 80002fb4 <argint>
    return -1;
    800056ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ec:	02054763          	bltz	a0,8000571a <sys_write+0x5c>
    800056f0:	fd840593          	addi	a1,s0,-40
    800056f4:	4505                	li	a0,1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	8e0080e7          	jalr	-1824(ra) # 80002fd6 <argaddr>
    return -1;
    800056fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005700:	00054d63          	bltz	a0,8000571a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005704:	fe442603          	lw	a2,-28(s0)
    80005708:	fd843583          	ld	a1,-40(s0)
    8000570c:	fe843503          	ld	a0,-24(s0)
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	4fa080e7          	jalr	1274(ra) # 80004c0a <filewrite>
    80005718:	87aa                	mv	a5,a0
}
    8000571a:	853e                	mv	a0,a5
    8000571c:	70a2                	ld	ra,40(sp)
    8000571e:	7402                	ld	s0,32(sp)
    80005720:	6145                	addi	sp,sp,48
    80005722:	8082                	ret

0000000080005724 <sys_close>:
{
    80005724:	1101                	addi	sp,sp,-32
    80005726:	ec06                	sd	ra,24(sp)
    80005728:	e822                	sd	s0,16(sp)
    8000572a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000572c:	fe040613          	addi	a2,s0,-32
    80005730:	fec40593          	addi	a1,s0,-20
    80005734:	4501                	li	a0,0
    80005736:	00000097          	auipc	ra,0x0
    8000573a:	cc2080e7          	jalr	-830(ra) # 800053f8 <argfd>
    return -1;
    8000573e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005740:	02054463          	bltz	a0,80005768 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005744:	ffffc097          	auipc	ra,0xffffc
    80005748:	1c4080e7          	jalr	452(ra) # 80001908 <myproc>
    8000574c:	fec42783          	lw	a5,-20(s0)
    80005750:	07f9                	addi	a5,a5,30
    80005752:	078e                	slli	a5,a5,0x3
    80005754:	97aa                	add	a5,a5,a0
    80005756:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000575a:	fe043503          	ld	a0,-32(s0)
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	2b0080e7          	jalr	688(ra) # 80004a0e <fileclose>
  return 0;
    80005766:	4781                	li	a5,0
}
    80005768:	853e                	mv	a0,a5
    8000576a:	60e2                	ld	ra,24(sp)
    8000576c:	6442                	ld	s0,16(sp)
    8000576e:	6105                	addi	sp,sp,32
    80005770:	8082                	ret

0000000080005772 <sys_fstat>:
{
    80005772:	1101                	addi	sp,sp,-32
    80005774:	ec06                	sd	ra,24(sp)
    80005776:	e822                	sd	s0,16(sp)
    80005778:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000577a:	fe840613          	addi	a2,s0,-24
    8000577e:	4581                	li	a1,0
    80005780:	4501                	li	a0,0
    80005782:	00000097          	auipc	ra,0x0
    80005786:	c76080e7          	jalr	-906(ra) # 800053f8 <argfd>
    return -1;
    8000578a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000578c:	02054563          	bltz	a0,800057b6 <sys_fstat+0x44>
    80005790:	fe040593          	addi	a1,s0,-32
    80005794:	4505                	li	a0,1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	840080e7          	jalr	-1984(ra) # 80002fd6 <argaddr>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057a0:	00054b63          	bltz	a0,800057b6 <sys_fstat+0x44>
  return filestat(f, st);
    800057a4:	fe043583          	ld	a1,-32(s0)
    800057a8:	fe843503          	ld	a0,-24(s0)
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	32a080e7          	jalr	810(ra) # 80004ad6 <filestat>
    800057b4:	87aa                	mv	a5,a0
}
    800057b6:	853e                	mv	a0,a5
    800057b8:	60e2                	ld	ra,24(sp)
    800057ba:	6442                	ld	s0,16(sp)
    800057bc:	6105                	addi	sp,sp,32
    800057be:	8082                	ret

00000000800057c0 <sys_link>:
{
    800057c0:	7169                	addi	sp,sp,-304
    800057c2:	f606                	sd	ra,296(sp)
    800057c4:	f222                	sd	s0,288(sp)
    800057c6:	ee26                	sd	s1,280(sp)
    800057c8:	ea4a                	sd	s2,272(sp)
    800057ca:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057cc:	08000613          	li	a2,128
    800057d0:	ed040593          	addi	a1,s0,-304
    800057d4:	4501                	li	a0,0
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	822080e7          	jalr	-2014(ra) # 80002ff8 <argstr>
    return -1;
    800057de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057e0:	10054e63          	bltz	a0,800058fc <sys_link+0x13c>
    800057e4:	08000613          	li	a2,128
    800057e8:	f5040593          	addi	a1,s0,-176
    800057ec:	4505                	li	a0,1
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	80a080e7          	jalr	-2038(ra) # 80002ff8 <argstr>
    return -1;
    800057f6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f8:	10054263          	bltz	a0,800058fc <sys_link+0x13c>
  begin_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	d46080e7          	jalr	-698(ra) # 80004542 <begin_op>
  if((ip = namei(old)) == 0){
    80005804:	ed040513          	addi	a0,s0,-304
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	b1e080e7          	jalr	-1250(ra) # 80004326 <namei>
    80005810:	84aa                	mv	s1,a0
    80005812:	c551                	beqz	a0,8000589e <sys_link+0xde>
  ilock(ip);
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	35c080e7          	jalr	860(ra) # 80003b70 <ilock>
  if(ip->type == T_DIR){
    8000581c:	04449703          	lh	a4,68(s1)
    80005820:	4785                	li	a5,1
    80005822:	08f70463          	beq	a4,a5,800058aa <sys_link+0xea>
  ip->nlink++;
    80005826:	04a4d783          	lhu	a5,74(s1)
    8000582a:	2785                	addiw	a5,a5,1
    8000582c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005830:	8526                	mv	a0,s1
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	274080e7          	jalr	628(ra) # 80003aa6 <iupdate>
  iunlock(ip);
    8000583a:	8526                	mv	a0,s1
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	3f6080e7          	jalr	1014(ra) # 80003c32 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005844:	fd040593          	addi	a1,s0,-48
    80005848:	f5040513          	addi	a0,s0,-176
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	af8080e7          	jalr	-1288(ra) # 80004344 <nameiparent>
    80005854:	892a                	mv	s2,a0
    80005856:	c935                	beqz	a0,800058ca <sys_link+0x10a>
  ilock(dp);
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	318080e7          	jalr	792(ra) # 80003b70 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005860:	00092703          	lw	a4,0(s2)
    80005864:	409c                	lw	a5,0(s1)
    80005866:	04f71d63          	bne	a4,a5,800058c0 <sys_link+0x100>
    8000586a:	40d0                	lw	a2,4(s1)
    8000586c:	fd040593          	addi	a1,s0,-48
    80005870:	854a                	mv	a0,s2
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	9f2080e7          	jalr	-1550(ra) # 80004264 <dirlink>
    8000587a:	04054363          	bltz	a0,800058c0 <sys_link+0x100>
  iunlockput(dp);
    8000587e:	854a                	mv	a0,s2
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	552080e7          	jalr	1362(ra) # 80003dd2 <iunlockput>
  iput(ip);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	4a0080e7          	jalr	1184(ra) # 80003d2a <iput>
  end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	d30080e7          	jalr	-720(ra) # 800045c2 <end_op>
  return 0;
    8000589a:	4781                	li	a5,0
    8000589c:	a085                	j	800058fc <sys_link+0x13c>
    end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	d24080e7          	jalr	-732(ra) # 800045c2 <end_op>
    return -1;
    800058a6:	57fd                	li	a5,-1
    800058a8:	a891                	j	800058fc <sys_link+0x13c>
    iunlockput(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	526080e7          	jalr	1318(ra) # 80003dd2 <iunlockput>
    end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	d0e080e7          	jalr	-754(ra) # 800045c2 <end_op>
    return -1;
    800058bc:	57fd                	li	a5,-1
    800058be:	a83d                	j	800058fc <sys_link+0x13c>
    iunlockput(dp);
    800058c0:	854a                	mv	a0,s2
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	510080e7          	jalr	1296(ra) # 80003dd2 <iunlockput>
  ilock(ip);
    800058ca:	8526                	mv	a0,s1
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	2a4080e7          	jalr	676(ra) # 80003b70 <ilock>
  ip->nlink--;
    800058d4:	04a4d783          	lhu	a5,74(s1)
    800058d8:	37fd                	addiw	a5,a5,-1
    800058da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	1c6080e7          	jalr	454(ra) # 80003aa6 <iupdate>
  iunlockput(ip);
    800058e8:	8526                	mv	a0,s1
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	4e8080e7          	jalr	1256(ra) # 80003dd2 <iunlockput>
  end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	cd0080e7          	jalr	-816(ra) # 800045c2 <end_op>
  return -1;
    800058fa:	57fd                	li	a5,-1
}
    800058fc:	853e                	mv	a0,a5
    800058fe:	70b2                	ld	ra,296(sp)
    80005900:	7412                	ld	s0,288(sp)
    80005902:	64f2                	ld	s1,280(sp)
    80005904:	6952                	ld	s2,272(sp)
    80005906:	6155                	addi	sp,sp,304
    80005908:	8082                	ret

000000008000590a <sys_unlink>:
{
    8000590a:	7151                	addi	sp,sp,-240
    8000590c:	f586                	sd	ra,232(sp)
    8000590e:	f1a2                	sd	s0,224(sp)
    80005910:	eda6                	sd	s1,216(sp)
    80005912:	e9ca                	sd	s2,208(sp)
    80005914:	e5ce                	sd	s3,200(sp)
    80005916:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005918:	08000613          	li	a2,128
    8000591c:	f3040593          	addi	a1,s0,-208
    80005920:	4501                	li	a0,0
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	6d6080e7          	jalr	1750(ra) # 80002ff8 <argstr>
    8000592a:	18054163          	bltz	a0,80005aac <sys_unlink+0x1a2>
  begin_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	c14080e7          	jalr	-1004(ra) # 80004542 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005936:	fb040593          	addi	a1,s0,-80
    8000593a:	f3040513          	addi	a0,s0,-208
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	a06080e7          	jalr	-1530(ra) # 80004344 <nameiparent>
    80005946:	84aa                	mv	s1,a0
    80005948:	c979                	beqz	a0,80005a1e <sys_unlink+0x114>
  ilock(dp);
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	226080e7          	jalr	550(ra) # 80003b70 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005952:	00003597          	auipc	a1,0x3
    80005956:	db658593          	addi	a1,a1,-586 # 80008708 <syscalls+0x2c0>
    8000595a:	fb040513          	addi	a0,s0,-80
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	6dc080e7          	jalr	1756(ra) # 8000403a <namecmp>
    80005966:	14050a63          	beqz	a0,80005aba <sys_unlink+0x1b0>
    8000596a:	00003597          	auipc	a1,0x3
    8000596e:	da658593          	addi	a1,a1,-602 # 80008710 <syscalls+0x2c8>
    80005972:	fb040513          	addi	a0,s0,-80
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	6c4080e7          	jalr	1732(ra) # 8000403a <namecmp>
    8000597e:	12050e63          	beqz	a0,80005aba <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005982:	f2c40613          	addi	a2,s0,-212
    80005986:	fb040593          	addi	a1,s0,-80
    8000598a:	8526                	mv	a0,s1
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	6c8080e7          	jalr	1736(ra) # 80004054 <dirlookup>
    80005994:	892a                	mv	s2,a0
    80005996:	12050263          	beqz	a0,80005aba <sys_unlink+0x1b0>
  ilock(ip);
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	1d6080e7          	jalr	470(ra) # 80003b70 <ilock>
  if(ip->nlink < 1)
    800059a2:	04a91783          	lh	a5,74(s2)
    800059a6:	08f05263          	blez	a5,80005a2a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059aa:	04491703          	lh	a4,68(s2)
    800059ae:	4785                	li	a5,1
    800059b0:	08f70563          	beq	a4,a5,80005a3a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059b4:	4641                	li	a2,16
    800059b6:	4581                	li	a1,0
    800059b8:	fc040513          	addi	a0,s0,-64
    800059bc:	ffffb097          	auipc	ra,0xffffb
    800059c0:	324080e7          	jalr	804(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059c4:	4741                	li	a4,16
    800059c6:	f2c42683          	lw	a3,-212(s0)
    800059ca:	fc040613          	addi	a2,s0,-64
    800059ce:	4581                	li	a1,0
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	54a080e7          	jalr	1354(ra) # 80003f1c <writei>
    800059da:	47c1                	li	a5,16
    800059dc:	0af51563          	bne	a0,a5,80005a86 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059e0:	04491703          	lh	a4,68(s2)
    800059e4:	4785                	li	a5,1
    800059e6:	0af70863          	beq	a4,a5,80005a96 <sys_unlink+0x18c>
  iunlockput(dp);
    800059ea:	8526                	mv	a0,s1
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	3e6080e7          	jalr	998(ra) # 80003dd2 <iunlockput>
  ip->nlink--;
    800059f4:	04a95783          	lhu	a5,74(s2)
    800059f8:	37fd                	addiw	a5,a5,-1
    800059fa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059fe:	854a                	mv	a0,s2
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	0a6080e7          	jalr	166(ra) # 80003aa6 <iupdate>
  iunlockput(ip);
    80005a08:	854a                	mv	a0,s2
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	3c8080e7          	jalr	968(ra) # 80003dd2 <iunlockput>
  end_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	bb0080e7          	jalr	-1104(ra) # 800045c2 <end_op>
  return 0;
    80005a1a:	4501                	li	a0,0
    80005a1c:	a84d                	j	80005ace <sys_unlink+0x1c4>
    end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	ba4080e7          	jalr	-1116(ra) # 800045c2 <end_op>
    return -1;
    80005a26:	557d                	li	a0,-1
    80005a28:	a05d                	j	80005ace <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a2a:	00003517          	auipc	a0,0x3
    80005a2e:	d0e50513          	addi	a0,a0,-754 # 80008738 <syscalls+0x2f0>
    80005a32:	ffffb097          	auipc	ra,0xffffb
    80005a36:	b0c080e7          	jalr	-1268(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a3a:	04c92703          	lw	a4,76(s2)
    80005a3e:	02000793          	li	a5,32
    80005a42:	f6e7f9e3          	bgeu	a5,a4,800059b4 <sys_unlink+0xaa>
    80005a46:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a4a:	4741                	li	a4,16
    80005a4c:	86ce                	mv	a3,s3
    80005a4e:	f1840613          	addi	a2,s0,-232
    80005a52:	4581                	li	a1,0
    80005a54:	854a                	mv	a0,s2
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	3ce080e7          	jalr	974(ra) # 80003e24 <readi>
    80005a5e:	47c1                	li	a5,16
    80005a60:	00f51b63          	bne	a0,a5,80005a76 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a64:	f1845783          	lhu	a5,-232(s0)
    80005a68:	e7a1                	bnez	a5,80005ab0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a6a:	29c1                	addiw	s3,s3,16
    80005a6c:	04c92783          	lw	a5,76(s2)
    80005a70:	fcf9ede3          	bltu	s3,a5,80005a4a <sys_unlink+0x140>
    80005a74:	b781                	j	800059b4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a76:	00003517          	auipc	a0,0x3
    80005a7a:	cda50513          	addi	a0,a0,-806 # 80008750 <syscalls+0x308>
    80005a7e:	ffffb097          	auipc	ra,0xffffb
    80005a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a86:	00003517          	auipc	a0,0x3
    80005a8a:	ce250513          	addi	a0,a0,-798 # 80008768 <syscalls+0x320>
    80005a8e:	ffffb097          	auipc	ra,0xffffb
    80005a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>
    dp->nlink--;
    80005a96:	04a4d783          	lhu	a5,74(s1)
    80005a9a:	37fd                	addiw	a5,a5,-1
    80005a9c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005aa0:	8526                	mv	a0,s1
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	004080e7          	jalr	4(ra) # 80003aa6 <iupdate>
    80005aaa:	b781                	j	800059ea <sys_unlink+0xe0>
    return -1;
    80005aac:	557d                	li	a0,-1
    80005aae:	a005                	j	80005ace <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ab0:	854a                	mv	a0,s2
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	320080e7          	jalr	800(ra) # 80003dd2 <iunlockput>
  iunlockput(dp);
    80005aba:	8526                	mv	a0,s1
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	316080e7          	jalr	790(ra) # 80003dd2 <iunlockput>
  end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	afe080e7          	jalr	-1282(ra) # 800045c2 <end_op>
  return -1;
    80005acc:	557d                	li	a0,-1
}
    80005ace:	70ae                	ld	ra,232(sp)
    80005ad0:	740e                	ld	s0,224(sp)
    80005ad2:	64ee                	ld	s1,216(sp)
    80005ad4:	694e                	ld	s2,208(sp)
    80005ad6:	69ae                	ld	s3,200(sp)
    80005ad8:	616d                	addi	sp,sp,240
    80005ada:	8082                	ret

0000000080005adc <sys_open>:

uint64
sys_open(void)
{
    80005adc:	7131                	addi	sp,sp,-192
    80005ade:	fd06                	sd	ra,184(sp)
    80005ae0:	f922                	sd	s0,176(sp)
    80005ae2:	f526                	sd	s1,168(sp)
    80005ae4:	f14a                	sd	s2,160(sp)
    80005ae6:	ed4e                	sd	s3,152(sp)
    80005ae8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005aea:	08000613          	li	a2,128
    80005aee:	f5040593          	addi	a1,s0,-176
    80005af2:	4501                	li	a0,0
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	504080e7          	jalr	1284(ra) # 80002ff8 <argstr>
    return -1;
    80005afc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005afe:	0c054163          	bltz	a0,80005bc0 <sys_open+0xe4>
    80005b02:	f4c40593          	addi	a1,s0,-180
    80005b06:	4505                	li	a0,1
    80005b08:	ffffd097          	auipc	ra,0xffffd
    80005b0c:	4ac080e7          	jalr	1196(ra) # 80002fb4 <argint>
    80005b10:	0a054863          	bltz	a0,80005bc0 <sys_open+0xe4>

  begin_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	a2e080e7          	jalr	-1490(ra) # 80004542 <begin_op>

  if(omode & O_CREATE){
    80005b1c:	f4c42783          	lw	a5,-180(s0)
    80005b20:	2007f793          	andi	a5,a5,512
    80005b24:	cbdd                	beqz	a5,80005bda <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b26:	4681                	li	a3,0
    80005b28:	4601                	li	a2,0
    80005b2a:	4589                	li	a1,2
    80005b2c:	f5040513          	addi	a0,s0,-176
    80005b30:	00000097          	auipc	ra,0x0
    80005b34:	972080e7          	jalr	-1678(ra) # 800054a2 <create>
    80005b38:	892a                	mv	s2,a0
    if(ip == 0){
    80005b3a:	c959                	beqz	a0,80005bd0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b3c:	04491703          	lh	a4,68(s2)
    80005b40:	478d                	li	a5,3
    80005b42:	00f71763          	bne	a4,a5,80005b50 <sys_open+0x74>
    80005b46:	04695703          	lhu	a4,70(s2)
    80005b4a:	47a5                	li	a5,9
    80005b4c:	0ce7ec63          	bltu	a5,a4,80005c24 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	e02080e7          	jalr	-510(ra) # 80004952 <filealloc>
    80005b58:	89aa                	mv	s3,a0
    80005b5a:	10050263          	beqz	a0,80005c5e <sys_open+0x182>
    80005b5e:	00000097          	auipc	ra,0x0
    80005b62:	902080e7          	jalr	-1790(ra) # 80005460 <fdalloc>
    80005b66:	84aa                	mv	s1,a0
    80005b68:	0e054663          	bltz	a0,80005c54 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b6c:	04491703          	lh	a4,68(s2)
    80005b70:	478d                	li	a5,3
    80005b72:	0cf70463          	beq	a4,a5,80005c3a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b76:	4789                	li	a5,2
    80005b78:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b7c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b80:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b84:	f4c42783          	lw	a5,-180(s0)
    80005b88:	0017c713          	xori	a4,a5,1
    80005b8c:	8b05                	andi	a4,a4,1
    80005b8e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b92:	0037f713          	andi	a4,a5,3
    80005b96:	00e03733          	snez	a4,a4
    80005b9a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b9e:	4007f793          	andi	a5,a5,1024
    80005ba2:	c791                	beqz	a5,80005bae <sys_open+0xd2>
    80005ba4:	04491703          	lh	a4,68(s2)
    80005ba8:	4789                	li	a5,2
    80005baa:	08f70f63          	beq	a4,a5,80005c48 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bae:	854a                	mv	a0,s2
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	082080e7          	jalr	130(ra) # 80003c32 <iunlock>
  end_op();
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	a0a080e7          	jalr	-1526(ra) # 800045c2 <end_op>

  return fd;
}
    80005bc0:	8526                	mv	a0,s1
    80005bc2:	70ea                	ld	ra,184(sp)
    80005bc4:	744a                	ld	s0,176(sp)
    80005bc6:	74aa                	ld	s1,168(sp)
    80005bc8:	790a                	ld	s2,160(sp)
    80005bca:	69ea                	ld	s3,152(sp)
    80005bcc:	6129                	addi	sp,sp,192
    80005bce:	8082                	ret
      end_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	9f2080e7          	jalr	-1550(ra) # 800045c2 <end_op>
      return -1;
    80005bd8:	b7e5                	j	80005bc0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bda:	f5040513          	addi	a0,s0,-176
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	748080e7          	jalr	1864(ra) # 80004326 <namei>
    80005be6:	892a                	mv	s2,a0
    80005be8:	c905                	beqz	a0,80005c18 <sys_open+0x13c>
    ilock(ip);
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	f86080e7          	jalr	-122(ra) # 80003b70 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bf2:	04491703          	lh	a4,68(s2)
    80005bf6:	4785                	li	a5,1
    80005bf8:	f4f712e3          	bne	a4,a5,80005b3c <sys_open+0x60>
    80005bfc:	f4c42783          	lw	a5,-180(s0)
    80005c00:	dba1                	beqz	a5,80005b50 <sys_open+0x74>
      iunlockput(ip);
    80005c02:	854a                	mv	a0,s2
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	1ce080e7          	jalr	462(ra) # 80003dd2 <iunlockput>
      end_op();
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	9b6080e7          	jalr	-1610(ra) # 800045c2 <end_op>
      return -1;
    80005c14:	54fd                	li	s1,-1
    80005c16:	b76d                	j	80005bc0 <sys_open+0xe4>
      end_op();
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	9aa080e7          	jalr	-1622(ra) # 800045c2 <end_op>
      return -1;
    80005c20:	54fd                	li	s1,-1
    80005c22:	bf79                	j	80005bc0 <sys_open+0xe4>
    iunlockput(ip);
    80005c24:	854a                	mv	a0,s2
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	1ac080e7          	jalr	428(ra) # 80003dd2 <iunlockput>
    end_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	994080e7          	jalr	-1644(ra) # 800045c2 <end_op>
    return -1;
    80005c36:	54fd                	li	s1,-1
    80005c38:	b761                	j	80005bc0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c3a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c3e:	04691783          	lh	a5,70(s2)
    80005c42:	02f99223          	sh	a5,36(s3)
    80005c46:	bf2d                	j	80005b80 <sys_open+0xa4>
    itrunc(ip);
    80005c48:	854a                	mv	a0,s2
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	034080e7          	jalr	52(ra) # 80003c7e <itrunc>
    80005c52:	bfb1                	j	80005bae <sys_open+0xd2>
      fileclose(f);
    80005c54:	854e                	mv	a0,s3
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	db8080e7          	jalr	-584(ra) # 80004a0e <fileclose>
    iunlockput(ip);
    80005c5e:	854a                	mv	a0,s2
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	172080e7          	jalr	370(ra) # 80003dd2 <iunlockput>
    end_op();
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	95a080e7          	jalr	-1702(ra) # 800045c2 <end_op>
    return -1;
    80005c70:	54fd                	li	s1,-1
    80005c72:	b7b9                	j	80005bc0 <sys_open+0xe4>

0000000080005c74 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c74:	7175                	addi	sp,sp,-144
    80005c76:	e506                	sd	ra,136(sp)
    80005c78:	e122                	sd	s0,128(sp)
    80005c7a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	8c6080e7          	jalr	-1850(ra) # 80004542 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c84:	08000613          	li	a2,128
    80005c88:	f7040593          	addi	a1,s0,-144
    80005c8c:	4501                	li	a0,0
    80005c8e:	ffffd097          	auipc	ra,0xffffd
    80005c92:	36a080e7          	jalr	874(ra) # 80002ff8 <argstr>
    80005c96:	02054963          	bltz	a0,80005cc8 <sys_mkdir+0x54>
    80005c9a:	4681                	li	a3,0
    80005c9c:	4601                	li	a2,0
    80005c9e:	4585                	li	a1,1
    80005ca0:	f7040513          	addi	a0,s0,-144
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	7fe080e7          	jalr	2046(ra) # 800054a2 <create>
    80005cac:	cd11                	beqz	a0,80005cc8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	124080e7          	jalr	292(ra) # 80003dd2 <iunlockput>
  end_op();
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	90c080e7          	jalr	-1780(ra) # 800045c2 <end_op>
  return 0;
    80005cbe:	4501                	li	a0,0
}
    80005cc0:	60aa                	ld	ra,136(sp)
    80005cc2:	640a                	ld	s0,128(sp)
    80005cc4:	6149                	addi	sp,sp,144
    80005cc6:	8082                	ret
    end_op();
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	8fa080e7          	jalr	-1798(ra) # 800045c2 <end_op>
    return -1;
    80005cd0:	557d                	li	a0,-1
    80005cd2:	b7fd                	j	80005cc0 <sys_mkdir+0x4c>

0000000080005cd4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cd4:	7135                	addi	sp,sp,-160
    80005cd6:	ed06                	sd	ra,152(sp)
    80005cd8:	e922                	sd	s0,144(sp)
    80005cda:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	866080e7          	jalr	-1946(ra) # 80004542 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ce4:	08000613          	li	a2,128
    80005ce8:	f7040593          	addi	a1,s0,-144
    80005cec:	4501                	li	a0,0
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	30a080e7          	jalr	778(ra) # 80002ff8 <argstr>
    80005cf6:	04054a63          	bltz	a0,80005d4a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005cfa:	f6c40593          	addi	a1,s0,-148
    80005cfe:	4505                	li	a0,1
    80005d00:	ffffd097          	auipc	ra,0xffffd
    80005d04:	2b4080e7          	jalr	692(ra) # 80002fb4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d08:	04054163          	bltz	a0,80005d4a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d0c:	f6840593          	addi	a1,s0,-152
    80005d10:	4509                	li	a0,2
    80005d12:	ffffd097          	auipc	ra,0xffffd
    80005d16:	2a2080e7          	jalr	674(ra) # 80002fb4 <argint>
     argint(1, &major) < 0 ||
    80005d1a:	02054863          	bltz	a0,80005d4a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d1e:	f6841683          	lh	a3,-152(s0)
    80005d22:	f6c41603          	lh	a2,-148(s0)
    80005d26:	458d                	li	a1,3
    80005d28:	f7040513          	addi	a0,s0,-144
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	776080e7          	jalr	1910(ra) # 800054a2 <create>
     argint(2, &minor) < 0 ||
    80005d34:	c919                	beqz	a0,80005d4a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	09c080e7          	jalr	156(ra) # 80003dd2 <iunlockput>
  end_op();
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	884080e7          	jalr	-1916(ra) # 800045c2 <end_op>
  return 0;
    80005d46:	4501                	li	a0,0
    80005d48:	a031                	j	80005d54 <sys_mknod+0x80>
    end_op();
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	878080e7          	jalr	-1928(ra) # 800045c2 <end_op>
    return -1;
    80005d52:	557d                	li	a0,-1
}
    80005d54:	60ea                	ld	ra,152(sp)
    80005d56:	644a                	ld	s0,144(sp)
    80005d58:	610d                	addi	sp,sp,160
    80005d5a:	8082                	ret

0000000080005d5c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d5c:	7135                	addi	sp,sp,-160
    80005d5e:	ed06                	sd	ra,152(sp)
    80005d60:	e922                	sd	s0,144(sp)
    80005d62:	e526                	sd	s1,136(sp)
    80005d64:	e14a                	sd	s2,128(sp)
    80005d66:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	ba0080e7          	jalr	-1120(ra) # 80001908 <myproc>
    80005d70:	892a                	mv	s2,a0
  
  begin_op();
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	7d0080e7          	jalr	2000(ra) # 80004542 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d7a:	08000613          	li	a2,128
    80005d7e:	f6040593          	addi	a1,s0,-160
    80005d82:	4501                	li	a0,0
    80005d84:	ffffd097          	auipc	ra,0xffffd
    80005d88:	274080e7          	jalr	628(ra) # 80002ff8 <argstr>
    80005d8c:	04054b63          	bltz	a0,80005de2 <sys_chdir+0x86>
    80005d90:	f6040513          	addi	a0,s0,-160
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	592080e7          	jalr	1426(ra) # 80004326 <namei>
    80005d9c:	84aa                	mv	s1,a0
    80005d9e:	c131                	beqz	a0,80005de2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	dd0080e7          	jalr	-560(ra) # 80003b70 <ilock>
  if(ip->type != T_DIR){
    80005da8:	04449703          	lh	a4,68(s1)
    80005dac:	4785                	li	a5,1
    80005dae:	04f71063          	bne	a4,a5,80005dee <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005db2:	8526                	mv	a0,s1
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	e7e080e7          	jalr	-386(ra) # 80003c32 <iunlock>
  iput(p->cwd);
    80005dbc:	17093503          	ld	a0,368(s2)
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	f6a080e7          	jalr	-150(ra) # 80003d2a <iput>
  end_op();
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	7fa080e7          	jalr	2042(ra) # 800045c2 <end_op>
  p->cwd = ip;
    80005dd0:	16993823          	sd	s1,368(s2)
  return 0;
    80005dd4:	4501                	li	a0,0
}
    80005dd6:	60ea                	ld	ra,152(sp)
    80005dd8:	644a                	ld	s0,144(sp)
    80005dda:	64aa                	ld	s1,136(sp)
    80005ddc:	690a                	ld	s2,128(sp)
    80005dde:	610d                	addi	sp,sp,160
    80005de0:	8082                	ret
    end_op();
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	7e0080e7          	jalr	2016(ra) # 800045c2 <end_op>
    return -1;
    80005dea:	557d                	li	a0,-1
    80005dec:	b7ed                	j	80005dd6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005dee:	8526                	mv	a0,s1
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	fe2080e7          	jalr	-30(ra) # 80003dd2 <iunlockput>
    end_op();
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	7ca080e7          	jalr	1994(ra) # 800045c2 <end_op>
    return -1;
    80005e00:	557d                	li	a0,-1
    80005e02:	bfd1                	j	80005dd6 <sys_chdir+0x7a>

0000000080005e04 <sys_exec>:

uint64
sys_exec(void)
{
    80005e04:	7145                	addi	sp,sp,-464
    80005e06:	e786                	sd	ra,456(sp)
    80005e08:	e3a2                	sd	s0,448(sp)
    80005e0a:	ff26                	sd	s1,440(sp)
    80005e0c:	fb4a                	sd	s2,432(sp)
    80005e0e:	f74e                	sd	s3,424(sp)
    80005e10:	f352                	sd	s4,416(sp)
    80005e12:	ef56                	sd	s5,408(sp)
    80005e14:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e16:	08000613          	li	a2,128
    80005e1a:	f4040593          	addi	a1,s0,-192
    80005e1e:	4501                	li	a0,0
    80005e20:	ffffd097          	auipc	ra,0xffffd
    80005e24:	1d8080e7          	jalr	472(ra) # 80002ff8 <argstr>
    return -1;
    80005e28:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e2a:	0c054a63          	bltz	a0,80005efe <sys_exec+0xfa>
    80005e2e:	e3840593          	addi	a1,s0,-456
    80005e32:	4505                	li	a0,1
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	1a2080e7          	jalr	418(ra) # 80002fd6 <argaddr>
    80005e3c:	0c054163          	bltz	a0,80005efe <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e40:	10000613          	li	a2,256
    80005e44:	4581                	li	a1,0
    80005e46:	e4040513          	addi	a0,s0,-448
    80005e4a:	ffffb097          	auipc	ra,0xffffb
    80005e4e:	e96080e7          	jalr	-362(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e52:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e56:	89a6                	mv	s3,s1
    80005e58:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e5a:	02000a13          	li	s4,32
    80005e5e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e62:	00391513          	slli	a0,s2,0x3
    80005e66:	e3040593          	addi	a1,s0,-464
    80005e6a:	e3843783          	ld	a5,-456(s0)
    80005e6e:	953e                	add	a0,a0,a5
    80005e70:	ffffd097          	auipc	ra,0xffffd
    80005e74:	0aa080e7          	jalr	170(ra) # 80002f1a <fetchaddr>
    80005e78:	02054a63          	bltz	a0,80005eac <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e7c:	e3043783          	ld	a5,-464(s0)
    80005e80:	c3b9                	beqz	a5,80005ec6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e82:	ffffb097          	auipc	ra,0xffffb
    80005e86:	c72080e7          	jalr	-910(ra) # 80000af4 <kalloc>
    80005e8a:	85aa                	mv	a1,a0
    80005e8c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e90:	cd11                	beqz	a0,80005eac <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e92:	6605                	lui	a2,0x1
    80005e94:	e3043503          	ld	a0,-464(s0)
    80005e98:	ffffd097          	auipc	ra,0xffffd
    80005e9c:	0d4080e7          	jalr	212(ra) # 80002f6c <fetchstr>
    80005ea0:	00054663          	bltz	a0,80005eac <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ea4:	0905                	addi	s2,s2,1
    80005ea6:	09a1                	addi	s3,s3,8
    80005ea8:	fb491be3          	bne	s2,s4,80005e5e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eac:	10048913          	addi	s2,s1,256
    80005eb0:	6088                	ld	a0,0(s1)
    80005eb2:	c529                	beqz	a0,80005efc <sys_exec+0xf8>
    kfree(argv[i]);
    80005eb4:	ffffb097          	auipc	ra,0xffffb
    80005eb8:	b44080e7          	jalr	-1212(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ebc:	04a1                	addi	s1,s1,8
    80005ebe:	ff2499e3          	bne	s1,s2,80005eb0 <sys_exec+0xac>
  return -1;
    80005ec2:	597d                	li	s2,-1
    80005ec4:	a82d                	j	80005efe <sys_exec+0xfa>
      argv[i] = 0;
    80005ec6:	0a8e                	slli	s5,s5,0x3
    80005ec8:	fc040793          	addi	a5,s0,-64
    80005ecc:	9abe                	add	s5,s5,a5
    80005ece:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ed2:	e4040593          	addi	a1,s0,-448
    80005ed6:	f4040513          	addi	a0,s0,-192
    80005eda:	fffff097          	auipc	ra,0xfffff
    80005ede:	194080e7          	jalr	404(ra) # 8000506e <exec>
    80005ee2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ee4:	10048993          	addi	s3,s1,256
    80005ee8:	6088                	ld	a0,0(s1)
    80005eea:	c911                	beqz	a0,80005efe <sys_exec+0xfa>
    kfree(argv[i]);
    80005eec:	ffffb097          	auipc	ra,0xffffb
    80005ef0:	b0c080e7          	jalr	-1268(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef4:	04a1                	addi	s1,s1,8
    80005ef6:	ff3499e3          	bne	s1,s3,80005ee8 <sys_exec+0xe4>
    80005efa:	a011                	j	80005efe <sys_exec+0xfa>
  return -1;
    80005efc:	597d                	li	s2,-1
}
    80005efe:	854a                	mv	a0,s2
    80005f00:	60be                	ld	ra,456(sp)
    80005f02:	641e                	ld	s0,448(sp)
    80005f04:	74fa                	ld	s1,440(sp)
    80005f06:	795a                	ld	s2,432(sp)
    80005f08:	79ba                	ld	s3,424(sp)
    80005f0a:	7a1a                	ld	s4,416(sp)
    80005f0c:	6afa                	ld	s5,408(sp)
    80005f0e:	6179                	addi	sp,sp,464
    80005f10:	8082                	ret

0000000080005f12 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f12:	7139                	addi	sp,sp,-64
    80005f14:	fc06                	sd	ra,56(sp)
    80005f16:	f822                	sd	s0,48(sp)
    80005f18:	f426                	sd	s1,40(sp)
    80005f1a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f1c:	ffffc097          	auipc	ra,0xffffc
    80005f20:	9ec080e7          	jalr	-1556(ra) # 80001908 <myproc>
    80005f24:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f26:	fd840593          	addi	a1,s0,-40
    80005f2a:	4501                	li	a0,0
    80005f2c:	ffffd097          	auipc	ra,0xffffd
    80005f30:	0aa080e7          	jalr	170(ra) # 80002fd6 <argaddr>
    return -1;
    80005f34:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f36:	0e054063          	bltz	a0,80006016 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f3a:	fc840593          	addi	a1,s0,-56
    80005f3e:	fd040513          	addi	a0,s0,-48
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	dfc080e7          	jalr	-516(ra) # 80004d3e <pipealloc>
    return -1;
    80005f4a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f4c:	0c054563          	bltz	a0,80006016 <sys_pipe+0x104>
  fd0 = -1;
    80005f50:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f54:	fd043503          	ld	a0,-48(s0)
    80005f58:	fffff097          	auipc	ra,0xfffff
    80005f5c:	508080e7          	jalr	1288(ra) # 80005460 <fdalloc>
    80005f60:	fca42223          	sw	a0,-60(s0)
    80005f64:	08054c63          	bltz	a0,80005ffc <sys_pipe+0xea>
    80005f68:	fc843503          	ld	a0,-56(s0)
    80005f6c:	fffff097          	auipc	ra,0xfffff
    80005f70:	4f4080e7          	jalr	1268(ra) # 80005460 <fdalloc>
    80005f74:	fca42023          	sw	a0,-64(s0)
    80005f78:	06054863          	bltz	a0,80005fe8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f7c:	4691                	li	a3,4
    80005f7e:	fc440613          	addi	a2,s0,-60
    80005f82:	fd843583          	ld	a1,-40(s0)
    80005f86:	78a8                	ld	a0,112(s1)
    80005f88:	ffffb097          	auipc	ra,0xffffb
    80005f8c:	6ea080e7          	jalr	1770(ra) # 80001672 <copyout>
    80005f90:	02054063          	bltz	a0,80005fb0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f94:	4691                	li	a3,4
    80005f96:	fc040613          	addi	a2,s0,-64
    80005f9a:	fd843583          	ld	a1,-40(s0)
    80005f9e:	0591                	addi	a1,a1,4
    80005fa0:	78a8                	ld	a0,112(s1)
    80005fa2:	ffffb097          	auipc	ra,0xffffb
    80005fa6:	6d0080e7          	jalr	1744(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005faa:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fac:	06055563          	bgez	a0,80006016 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fb0:	fc442783          	lw	a5,-60(s0)
    80005fb4:	07f9                	addi	a5,a5,30
    80005fb6:	078e                	slli	a5,a5,0x3
    80005fb8:	97a6                	add	a5,a5,s1
    80005fba:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fbe:	fc042503          	lw	a0,-64(s0)
    80005fc2:	0579                	addi	a0,a0,30
    80005fc4:	050e                	slli	a0,a0,0x3
    80005fc6:	9526                	add	a0,a0,s1
    80005fc8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fcc:	fd043503          	ld	a0,-48(s0)
    80005fd0:	fffff097          	auipc	ra,0xfffff
    80005fd4:	a3e080e7          	jalr	-1474(ra) # 80004a0e <fileclose>
    fileclose(wf);
    80005fd8:	fc843503          	ld	a0,-56(s0)
    80005fdc:	fffff097          	auipc	ra,0xfffff
    80005fe0:	a32080e7          	jalr	-1486(ra) # 80004a0e <fileclose>
    return -1;
    80005fe4:	57fd                	li	a5,-1
    80005fe6:	a805                	j	80006016 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005fe8:	fc442783          	lw	a5,-60(s0)
    80005fec:	0007c863          	bltz	a5,80005ffc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ff0:	01e78513          	addi	a0,a5,30
    80005ff4:	050e                	slli	a0,a0,0x3
    80005ff6:	9526                	add	a0,a0,s1
    80005ff8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ffc:	fd043503          	ld	a0,-48(s0)
    80006000:	fffff097          	auipc	ra,0xfffff
    80006004:	a0e080e7          	jalr	-1522(ra) # 80004a0e <fileclose>
    fileclose(wf);
    80006008:	fc843503          	ld	a0,-56(s0)
    8000600c:	fffff097          	auipc	ra,0xfffff
    80006010:	a02080e7          	jalr	-1534(ra) # 80004a0e <fileclose>
    return -1;
    80006014:	57fd                	li	a5,-1
}
    80006016:	853e                	mv	a0,a5
    80006018:	70e2                	ld	ra,56(sp)
    8000601a:	7442                	ld	s0,48(sp)
    8000601c:	74a2                	ld	s1,40(sp)
    8000601e:	6121                	addi	sp,sp,64
    80006020:	8082                	ret
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
    80006070:	d77fc0ef          	jal	ra,80002de6 <kerneltrap>
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
