
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
    80000068:	0cc78793          	addi	a5,a5,204 # 80006130 <timervec>
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
    80000130:	b40080e7          	jalr	-1216(ra) # 80001c6c <either_copyin>
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
    800001d8:	e5c080e7          	jalr	-420(ra) # 80002030 <sleep>
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
    80000214:	a06080e7          	jalr	-1530(ra) # 80001c16 <either_copyout>
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
    800002f6:	9d0080e7          	jalr	-1584(ra) # 80001cc2 <procdump>
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
    8000044a:	f64080e7          	jalr	-156(ra) # 800023aa <wakeup>
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
    800008a4:	b0a080e7          	jalr	-1270(ra) # 800023aa <wakeup>
    
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
    80000930:	704080e7          	jalr	1796(ra) # 80002030 <sleep>
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
    80000ed8:	cfa080e7          	jalr	-774(ra) # 80002bce <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	294080e7          	jalr	660(ra) # 80006170 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	ba2080e7          	jalr	-1118(ra) # 80002a86 <scheduler>
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
    80000f48:	f40080e7          	jalr	-192(ra) # 80001e84 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	c5a080e7          	jalr	-934(ra) # 80002ba6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c7a080e7          	jalr	-902(ra) # 80002bce <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	1fe080e7          	jalr	510(ra) # 8000615a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	20c080e7          	jalr	524(ra) # 80006170 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	3ee080e7          	jalr	1006(ra) # 8000335a <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	a7e080e7          	jalr	-1410(ra) # 800039f2 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	a28080e7          	jalr	-1496(ra) # 800049a4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	30e080e7          	jalr	782(ra) # 80006292 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	8ec080e7          	jalr	-1812(ra) # 80002878 <userinit>
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
    80001964:	ef07a783          	lw	a5,-272(a5) # 80008850 <first.1706>
    80001968:	eb89                	bnez	a5,8000197a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000196a:	00001097          	auipc	ra,0x1
    8000196e:	27c080e7          	jalr	636(ra) # 80002be6 <usertrapret>
}
    80001972:	60a2                	ld	ra,8(sp)
    80001974:	6402                	ld	s0,0(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret
    first = 0;
    8000197a:	00007797          	auipc	a5,0x7
    8000197e:	ec07ab23          	sw	zero,-298(a5) # 80008850 <first.1706>
    fsinit(ROOTDEV);
    80001982:	4505                	li	a0,1
    80001984:	00002097          	auipc	ra,0x2
    80001988:	fee080e7          	jalr	-18(ra) # 80003972 <fsinit>
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
    8000199e:	ec690913          	addi	s2,s2,-314 # 80008860 <nextpid>
    800019a2:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid , pid , pid+1));
    800019a6:	0014861b          	addiw	a2,s1,1
    800019aa:	85a6                	mv	a1,s1
    800019ac:	854a                	mv	a0,s2
    800019ae:	00005097          	auipc	ra,0x5
    800019b2:	dc8080e7          	jalr	-568(ra) # 80006776 <cas>
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
    80001bb0:	f90080e7          	jalr	-112(ra) # 80002b3c <swtch>
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

0000000080001c16 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80001c16:	7179                	addi	sp,sp,-48
    80001c18:	f406                	sd	ra,40(sp)
    80001c1a:	f022                	sd	s0,32(sp)
    80001c1c:	ec26                	sd	s1,24(sp)
    80001c1e:	e84a                	sd	s2,16(sp)
    80001c20:	e44e                	sd	s3,8(sp)
    80001c22:	e052                	sd	s4,0(sp)
    80001c24:	1800                	addi	s0,sp,48
    80001c26:	84aa                	mv	s1,a0
    80001c28:	892e                	mv	s2,a1
    80001c2a:	89b2                	mv	s3,a2
    80001c2c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	cda080e7          	jalr	-806(ra) # 80001908 <myproc>
  if(user_dst){
    80001c36:	c08d                	beqz	s1,80001c58 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80001c38:	86d2                	mv	a3,s4
    80001c3a:	864e                	mv	a2,s3
    80001c3c:	85ca                	mv	a1,s2
    80001c3e:	7928                	ld	a0,112(a0)
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	a32080e7          	jalr	-1486(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80001c48:	70a2                	ld	ra,40(sp)
    80001c4a:	7402                	ld	s0,32(sp)
    80001c4c:	64e2                	ld	s1,24(sp)
    80001c4e:	6942                	ld	s2,16(sp)
    80001c50:	69a2                	ld	s3,8(sp)
    80001c52:	6a02                	ld	s4,0(sp)
    80001c54:	6145                	addi	sp,sp,48
    80001c56:	8082                	ret
    memmove((char *)dst, src, len);
    80001c58:	000a061b          	sext.w	a2,s4
    80001c5c:	85ce                	mv	a1,s3
    80001c5e:	854a                	mv	a0,s2
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	0e0080e7          	jalr	224(ra) # 80000d40 <memmove>
    return 0;
    80001c68:	8526                	mv	a0,s1
    80001c6a:	bff9                	j	80001c48 <either_copyout+0x32>

0000000080001c6c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80001c6c:	7179                	addi	sp,sp,-48
    80001c6e:	f406                	sd	ra,40(sp)
    80001c70:	f022                	sd	s0,32(sp)
    80001c72:	ec26                	sd	s1,24(sp)
    80001c74:	e84a                	sd	s2,16(sp)
    80001c76:	e44e                	sd	s3,8(sp)
    80001c78:	e052                	sd	s4,0(sp)
    80001c7a:	1800                	addi	s0,sp,48
    80001c7c:	892a                	mv	s2,a0
    80001c7e:	84ae                	mv	s1,a1
    80001c80:	89b2                	mv	s3,a2
    80001c82:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	c84080e7          	jalr	-892(ra) # 80001908 <myproc>
  if(user_src){
    80001c8c:	c08d                	beqz	s1,80001cae <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80001c8e:	86d2                	mv	a3,s4
    80001c90:	864e                	mv	a2,s3
    80001c92:	85ca                	mv	a1,s2
    80001c94:	7928                	ld	a0,112(a0)
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	a68080e7          	jalr	-1432(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80001c9e:	70a2                	ld	ra,40(sp)
    80001ca0:	7402                	ld	s0,32(sp)
    80001ca2:	64e2                	ld	s1,24(sp)
    80001ca4:	6942                	ld	s2,16(sp)
    80001ca6:	69a2                	ld	s3,8(sp)
    80001ca8:	6a02                	ld	s4,0(sp)
    80001caa:	6145                	addi	sp,sp,48
    80001cac:	8082                	ret
    memmove(dst, (char*)src, len);
    80001cae:	000a061b          	sext.w	a2,s4
    80001cb2:	85ce                	mv	a1,s3
    80001cb4:	854a                	mv	a0,s2
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	08a080e7          	jalr	138(ra) # 80000d40 <memmove>
    return 0;
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	bff9                	j	80001c9e <either_copyin+0x32>

0000000080001cc2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80001cc2:	715d                	addi	sp,sp,-80
    80001cc4:	e486                	sd	ra,72(sp)
    80001cc6:	e0a2                	sd	s0,64(sp)
    80001cc8:	fc26                	sd	s1,56(sp)
    80001cca:	f84a                	sd	s2,48(sp)
    80001ccc:	f44e                	sd	s3,40(sp)
    80001cce:	f052                	sd	s4,32(sp)
    80001cd0:	ec56                	sd	s5,24(sp)
    80001cd2:	e85a                	sd	s6,16(sp)
    80001cd4:	e45e                	sd	s7,8(sp)
    80001cd6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80001cd8:	00006517          	auipc	a0,0x6
    80001cdc:	3f050513          	addi	a0,a0,1008 # 800080c8 <digits+0x88>
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	8a8080e7          	jalr	-1880(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001ce8:	00010497          	auipc	s1,0x10
    80001cec:	ca848493          	addi	s1,s1,-856 # 80011990 <proc+0x178>
    80001cf0:	00016917          	auipc	s2,0x16
    80001cf4:	ea090913          	addi	s2,s2,-352 # 80017b90 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001cf8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80001cfa:	00006997          	auipc	s3,0x6
    80001cfe:	52e98993          	addi	s3,s3,1326 # 80008228 <digits+0x1e8>
    printf("%d %s %s", p->pid, state, p->name);
    80001d02:	00006a97          	auipc	s5,0x6
    80001d06:	52ea8a93          	addi	s5,s5,1326 # 80008230 <digits+0x1f0>
    printf("\n");
    80001d0a:	00006a17          	auipc	s4,0x6
    80001d0e:	3bea0a13          	addi	s4,s4,958 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d12:	00006b97          	auipc	s7,0x6
    80001d16:	5d6b8b93          	addi	s7,s7,1494 # 800082e8 <states.1746>
    80001d1a:	a00d                	j	80001d3c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80001d1c:	eb86a583          	lw	a1,-328(a3)
    80001d20:	8556                	mv	a0,s5
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	866080e7          	jalr	-1946(ra) # 80000588 <printf>
    printf("\n");
    80001d2a:	8552                	mv	a0,s4
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	85c080e7          	jalr	-1956(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80001d34:	18848493          	addi	s1,s1,392
    80001d38:	03248163          	beq	s1,s2,80001d5a <procdump+0x98>
    if(p->state == UNUSED)
    80001d3c:	86a6                	mv	a3,s1
    80001d3e:	ea04a783          	lw	a5,-352(s1)
    80001d42:	dbed                	beqz	a5,80001d34 <procdump+0x72>
      state = "???";
    80001d44:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80001d46:	fcfb6be3          	bltu	s6,a5,80001d1c <procdump+0x5a>
    80001d4a:	1782                	slli	a5,a5,0x20
    80001d4c:	9381                	srli	a5,a5,0x20
    80001d4e:	078e                	slli	a5,a5,0x3
    80001d50:	97de                	add	a5,a5,s7
    80001d52:	6390                	ld	a2,0(a5)
    80001d54:	f661                	bnez	a2,80001d1c <procdump+0x5a>
      state = "???";
    80001d56:	864e                	mv	a2,s3
    80001d58:	b7d1                	j	80001d1c <procdump+0x5a>
  }
}
    80001d5a:	60a6                	ld	ra,72(sp)
    80001d5c:	6406                	ld	s0,64(sp)
    80001d5e:	74e2                	ld	s1,56(sp)
    80001d60:	7942                	ld	s2,48(sp)
    80001d62:	79a2                	ld	s3,40(sp)
    80001d64:	7a02                	ld	s4,32(sp)
    80001d66:	6ae2                	ld	s5,24(sp)
    80001d68:	6b42                	ld	s6,16(sp)
    80001d6a:	6ba2                	ld	s7,8(sp)
    80001d6c:	6161                	addi	sp,sp,80
    80001d6e:	8082                	ret

0000000080001d70 <get_cpu>:
    return cpu_num;
}

int
get_cpu()
{
    80001d70:	1101                	addi	sp,sp,-32
    80001d72:	ec06                	sd	ra,24(sp)
    80001d74:	e822                	sd	s0,16(sp)
    80001d76:	e426                	sd	s1,8(sp)
    80001d78:	e04a                	sd	s2,0(sp)
    80001d7a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	b8c080e7          	jalr	-1140(ra) # 80001908 <myproc>
    80001d84:	84aa                	mv	s1,a0
  
  int cpu_num;
  acquire(&p->lock);
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	e5e080e7          	jalr	-418(ra) # 80000be4 <acquire>
  cpu_num = p->cpu_num;
    80001d8e:	0344a903          	lw	s2,52(s1)
  release(&p->lock);
    80001d92:	8526                	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	f04080e7          	jalr	-252(ra) # 80000c98 <release>
  return cpu_num;
}
    80001d9c:	854a                	mv	a0,s2
    80001d9e:	60e2                	ld	ra,24(sp)
    80001da0:	6442                	ld	s0,16(sp)
    80001da2:	64a2                	ld	s1,8(sp)
    80001da4:	6902                	ld	s2,0(sp)
    80001da6:	6105                	addi	sp,sp,32
    80001da8:	8082                	ret

0000000080001daa <add_to_list>:
//void initlock(struct spinlock *, char *)

void
add_to_list(int* curr_proc_index, struct proc* next_proc, struct spinlock* lock) {
    80001daa:	7139                	addi	sp,sp,-64
    80001dac:	fc06                	sd	ra,56(sp)
    80001dae:	f822                	sd	s0,48(sp)
    80001db0:	f426                	sd	s1,40(sp)
    80001db2:	f04a                	sd	s2,32(sp)
    80001db4:	ec4e                	sd	s3,24(sp)
    80001db6:	e852                	sd	s4,16(sp)
    80001db8:	e456                	sd	s5,8(sp)
    80001dba:	0080                	addi	s0,sp,64
    80001dbc:	84aa                	mv	s1,a0
    80001dbe:	8aae                	mv	s5,a1
    80001dc0:	8932                	mv	s2,a2
  acquire(lock);
    80001dc2:	8532                	mv	a0,a2
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	e20080e7          	jalr	-480(ra) # 80000be4 <acquire>

  if(*curr_proc_index == -1){
    80001dcc:	409c                	lw	a5,0(s1)
    80001dce:	577d                	li	a4,-1
    80001dd0:	08e78e63          	beq	a5,a4,80001e6c <add_to_list+0xc2>
    *curr_proc_index = next_proc->proc_index;
    next_proc->next_proc_index = -1;
    release(lock);
    return;
  }
  struct proc* curr_node = &proc[*curr_proc_index];
    80001dd4:	18800513          	li	a0,392
    80001dd8:	02a787b3          	mul	a5,a5,a0
    80001ddc:	00010517          	auipc	a0,0x10
    80001de0:	a3c50513          	addi	a0,a0,-1476 # 80011818 <proc>
    80001de4:	00a784b3          	add	s1,a5,a0
  acquire(&curr_node->proc_lock);
    80001de8:	04078793          	addi	a5,a5,64
    80001dec:	953e                	add	a0,a0,a5
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	df6080e7          	jalr	-522(ra) # 80000be4 <acquire>
  release(lock);
    80001df6:	854a                	mv	a0,s2
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	ea0080e7          	jalr	-352(ra) # 80000c98 <release>
  
  while(curr_node->next_proc_index != -1){
    80001e00:	5c88                	lw	a0,56(s1)
    80001e02:	57fd                	li	a5,-1
    80001e04:	02f50f63          	beq	a0,a5,80001e42 <add_to_list+0x98>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80001e08:	18800993          	li	s3,392
    80001e0c:	00010917          	auipc	s2,0x10
    80001e10:	a0c90913          	addi	s2,s2,-1524 # 80011818 <proc>
  while(curr_node->next_proc_index != -1){
    80001e14:	5a7d                	li	s4,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80001e16:	03350533          	mul	a0,a0,s3
    80001e1a:	04050513          	addi	a0,a0,64
    80001e1e:	954a                	add	a0,a0,s2
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	dc4080e7          	jalr	-572(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    80001e28:	04048513          	addi	a0,s1,64
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	e6c080e7          	jalr	-404(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    80001e34:	5c84                	lw	s1,56(s1)
    80001e36:	033484b3          	mul	s1,s1,s3
    80001e3a:	94ca                	add	s1,s1,s2
  while(curr_node->next_proc_index != -1){
    80001e3c:	5c88                	lw	a0,56(s1)
    80001e3e:	fd451ce3          	bne	a0,s4,80001e16 <add_to_list+0x6c>
    // printf("moving to: %d", curr_node->next_proc_index);
  }

  curr_node->next_proc_index = next_proc->proc_index;
    80001e42:	03caa783          	lw	a5,60(s5)
    80001e46:	dc9c                	sw	a5,56(s1)
  next_proc->next_proc_index = -1;
    80001e48:	57fd                	li	a5,-1
    80001e4a:	02faac23          	sw	a5,56(s5)
  release(&curr_node->proc_lock);
    80001e4e:	04048513          	addi	a0,s1,64
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e46080e7          	jalr	-442(ra) # 80000c98 <release>

}
    80001e5a:	70e2                	ld	ra,56(sp)
    80001e5c:	7442                	ld	s0,48(sp)
    80001e5e:	74a2                	ld	s1,40(sp)
    80001e60:	7902                	ld	s2,32(sp)
    80001e62:	69e2                	ld	s3,24(sp)
    80001e64:	6a42                	ld	s4,16(sp)
    80001e66:	6aa2                	ld	s5,8(sp)
    80001e68:	6121                	addi	sp,sp,64
    80001e6a:	8082                	ret
    *curr_proc_index = next_proc->proc_index;
    80001e6c:	03caa783          	lw	a5,60(s5)
    80001e70:	c09c                	sw	a5,0(s1)
    next_proc->next_proc_index = -1;
    80001e72:	57fd                	li	a5,-1
    80001e74:	02faac23          	sw	a5,56(s5)
    release(lock);
    80001e78:	854a                	mv	a0,s2
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	e1e080e7          	jalr	-482(ra) # 80000c98 <release>
    return;
    80001e82:	bfe1                	j	80001e5a <add_to_list+0xb0>

0000000080001e84 <procinit>:
{
    80001e84:	711d                	addi	sp,sp,-96
    80001e86:	ec86                	sd	ra,88(sp)
    80001e88:	e8a2                	sd	s0,80(sp)
    80001e8a:	e4a6                	sd	s1,72(sp)
    80001e8c:	e0ca                	sd	s2,64(sp)
    80001e8e:	fc4e                	sd	s3,56(sp)
    80001e90:	f852                	sd	s4,48(sp)
    80001e92:	f456                	sd	s5,40(sp)
    80001e94:	f05a                	sd	s6,32(sp)
    80001e96:	ec5e                	sd	s7,24(sp)
    80001e98:	e862                	sd	s8,16(sp)
    80001e9a:	e466                	sd	s9,8(sp)
    80001e9c:	e06a                	sd	s10,0(sp)
    80001e9e:	1080                	addi	s0,sp,96
  initlock(&pid_lock, "nextpid");
    80001ea0:	00006597          	auipc	a1,0x6
    80001ea4:	3a058593          	addi	a1,a1,928 # 80008240 <digits+0x200>
    80001ea8:	00010517          	auipc	a0,0x10
    80001eac:	8f850513          	addi	a0,a0,-1800 # 800117a0 <pid_lock>
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	ca4080e7          	jalr	-860(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001eb8:	00006597          	auipc	a1,0x6
    80001ebc:	39058593          	addi	a1,a1,912 # 80008248 <digits+0x208>
    80001ec0:	00010517          	auipc	a0,0x10
    80001ec4:	8f850513          	addi	a0,a0,-1800 # 800117b8 <wait_lock>
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	c8c080e7          	jalr	-884(ra) # 80000b54 <initlock>
  int index = 0;
    80001ed0:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001ed2:	00010497          	auipc	s1,0x10
    80001ed6:	94648493          	addi	s1,s1,-1722 # 80011818 <proc>
      initlock(&p->lock, "proc");
    80001eda:	00006d17          	auipc	s10,0x6
    80001ede:	37ed0d13          	addi	s10,s10,894 # 80008258 <digits+0x218>
      p->kstack = KSTACK((int) (p - proc));
    80001ee2:	8ca6                	mv	s9,s1
    80001ee4:	00006c17          	auipc	s8,0x6
    80001ee8:	11cc0c13          	addi	s8,s8,284 # 80008000 <etext>
    80001eec:	040009b7          	lui	s3,0x4000
    80001ef0:	19fd                	addi	s3,s3,-1
    80001ef2:	09b2                	slli	s3,s3,0xc
      p->next_proc_index = -1;
    80001ef4:	5bfd                	li	s7,-1
      add_to_list(&unused_head, p, &lock_unused_list);
    80001ef6:	00010b17          	auipc	s6,0x10
    80001efa:	8dab0b13          	addi	s6,s6,-1830 # 800117d0 <lock_unused_list>
    80001efe:	00007a97          	auipc	s5,0x7
    80001f02:	95ea8a93          	addi	s5,s5,-1698 # 8000885c <unused_head>
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001f06:	00016a17          	auipc	s4,0x16
    80001f0a:	b12a0a13          	addi	s4,s4,-1262 # 80017a18 <tickslock>
      initlock(&p->lock, "proc");
    80001f0e:	85ea                	mv	a1,s10
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	c42080e7          	jalr	-958(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001f1a:	419487b3          	sub	a5,s1,s9
    80001f1e:	878d                	srai	a5,a5,0x3
    80001f20:	000c3703          	ld	a4,0(s8)
    80001f24:	02e787b3          	mul	a5,a5,a4
    80001f28:	2785                	addiw	a5,a5,1
    80001f2a:	00d7979b          	slliw	a5,a5,0xd
    80001f2e:	40f987b3          	sub	a5,s3,a5
    80001f32:	f0bc                	sd	a5,96(s1)
      p->proc_index = index;
    80001f34:	0324ae23          	sw	s2,60(s1)
      p->next_proc_index = -1;
    80001f38:	0374ac23          	sw	s7,56(s1)
      add_to_list(&unused_head, p, &lock_unused_list);
    80001f3c:	865a                	mv	a2,s6
    80001f3e:	85a6                	mv	a1,s1
    80001f40:	8556                	mv	a0,s5
    80001f42:	00000097          	auipc	ra,0x0
    80001f46:	e68080e7          	jalr	-408(ra) # 80001daa <add_to_list>
  for(p = proc; p < &proc[NPROC]; p++, index++) {
    80001f4a:	18848493          	addi	s1,s1,392
    80001f4e:	2905                	addiw	s2,s2,1
    80001f50:	fb449fe3          	bne	s1,s4,80001f0e <procinit+0x8a>
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001f54:	0000f797          	auipc	a5,0xf
    80001f58:	34c78793          	addi	a5,a5,844 # 800112a0 <cpus>
      c->runnable_head = -1;
    80001f5c:	56fd                	li	a3,-1
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001f5e:	00010717          	auipc	a4,0x10
    80001f62:	84270713          	addi	a4,a4,-1982 # 800117a0 <pid_lock>
      c->runnable_head = -1;
    80001f66:	08d7a023          	sw	a3,128(a5)
    for(c = cpus; c < &cpus[NCPU]; c++) {
    80001f6a:	0a078793          	addi	a5,a5,160
    80001f6e:	fee79ce3          	bne	a5,a4,80001f66 <procinit+0xe2>
}
    80001f72:	60e6                	ld	ra,88(sp)
    80001f74:	6446                	ld	s0,80(sp)
    80001f76:	64a6                	ld	s1,72(sp)
    80001f78:	6906                	ld	s2,64(sp)
    80001f7a:	79e2                	ld	s3,56(sp)
    80001f7c:	7a42                	ld	s4,48(sp)
    80001f7e:	7aa2                	ld	s5,40(sp)
    80001f80:	7b02                	ld	s6,32(sp)
    80001f82:	6be2                	ld	s7,24(sp)
    80001f84:	6c42                	ld	s8,16(sp)
    80001f86:	6ca2                	ld	s9,8(sp)
    80001f88:	6d02                	ld	s10,0(sp)
    80001f8a:	6125                	addi	sp,sp,96
    80001f8c:	8082                	ret

0000000080001f8e <yield>:
{
    80001f8e:	1101                	addi	sp,sp,-32
    80001f90:	ec06                	sd	ra,24(sp)
    80001f92:	e822                	sd	s0,16(sp)
    80001f94:	e426                	sd	s1,8(sp)
    80001f96:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f98:	00000097          	auipc	ra,0x0
    80001f9c:	970080e7          	jalr	-1680(ra) # 80001908 <myproc>
    80001fa0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	c42080e7          	jalr	-958(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80001faa:	478d                	li	a5,3
    80001fac:	cc9c                	sw	a5,24(s1)
  add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    80001fae:	58c8                	lw	a0,52(s1)
    80001fb0:	00251793          	slli	a5,a0,0x2
    80001fb4:	97aa                	add	a5,a5,a0
    80001fb6:	0796                	slli	a5,a5,0x5
    80001fb8:	0000f517          	auipc	a0,0xf
    80001fbc:	2e850513          	addi	a0,a0,744 # 800112a0 <cpus>
    80001fc0:	08878613          	addi	a2,a5,136
    80001fc4:	08078793          	addi	a5,a5,128
    80001fc8:	962a                	add	a2,a2,a0
    80001fca:	85a6                	mv	a1,s1
    80001fcc:	953e                	add	a0,a0,a5
    80001fce:	00000097          	auipc	ra,0x0
    80001fd2:	ddc080e7          	jalr	-548(ra) # 80001daa <add_to_list>
  sched();
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	b52080e7          	jalr	-1198(ra) # 80001b28 <sched>
  release(&p->lock);
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	cb8080e7          	jalr	-840(ra) # 80000c98 <release>
}
    80001fe8:	60e2                	ld	ra,24(sp)
    80001fea:	6442                	ld	s0,16(sp)
    80001fec:	64a2                	ld	s1,8(sp)
    80001fee:	6105                	addi	sp,sp,32
    80001ff0:	8082                	ret

0000000080001ff2 <set_cpu>:
{
    80001ff2:	1101                	addi	sp,sp,-32
    80001ff4:	ec06                	sd	ra,24(sp)
    80001ff6:	e822                	sd	s0,16(sp)
    80001ff8:	e426                	sd	s1,8(sp)
    80001ffa:	1000                	addi	s0,sp,32
    80001ffc:	84aa                	mv	s1,a0
    struct proc* p = myproc();
    80001ffe:	00000097          	auipc	ra,0x0
    80002002:	90a080e7          	jalr	-1782(ra) # 80001908 <myproc>
    if(cas(&p->cpu_num, curr_cpu, cpu_num) !=0)
    80002006:	8626                	mv	a2,s1
    80002008:	594c                	lw	a1,52(a0)
    8000200a:	03450513          	addi	a0,a0,52
    8000200e:	00004097          	auipc	ra,0x4
    80002012:	768080e7          	jalr	1896(ra) # 80006776 <cas>
    80002016:	e919                	bnez	a0,8000202c <set_cpu+0x3a>
    yield();
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	f76080e7          	jalr	-138(ra) # 80001f8e <yield>
    return cpu_num;
    80002020:	8526                	mv	a0,s1
}
    80002022:	60e2                	ld	ra,24(sp)
    80002024:	6442                	ld	s0,16(sp)
    80002026:	64a2                	ld	s1,8(sp)
    80002028:	6105                	addi	sp,sp,32
    8000202a:	8082                	ret
        return -1;
    8000202c:	557d                	li	a0,-1
    8000202e:	bfd5                	j	80002022 <set_cpu+0x30>

0000000080002030 <sleep>:
{
    80002030:	7179                	addi	sp,sp,-48
    80002032:	f406                	sd	ra,40(sp)
    80002034:	f022                	sd	s0,32(sp)
    80002036:	ec26                	sd	s1,24(sp)
    80002038:	e84a                	sd	s2,16(sp)
    8000203a:	e44e                	sd	s3,8(sp)
    8000203c:	1800                	addi	s0,sp,48
    8000203e:	89aa                	mv	s3,a0
    80002040:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002042:	00000097          	auipc	ra,0x0
    80002046:	8c6080e7          	jalr	-1850(ra) # 80001908 <myproc>
    8000204a:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	b98080e7          	jalr	-1128(ra) # 80000be4 <acquire>
  add_to_list(&sleeping_head, p, &lock_sleeping_list);
    80002054:	0000f617          	auipc	a2,0xf
    80002058:	79460613          	addi	a2,a2,1940 # 800117e8 <lock_sleeping_list>
    8000205c:	85a6                	mv	a1,s1
    8000205e:	00006517          	auipc	a0,0x6
    80002062:	7fa50513          	addi	a0,a0,2042 # 80008858 <sleeping_head>
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	d44080e7          	jalr	-700(ra) # 80001daa <add_to_list>
  release(lk);
    8000206e:	854a                	mv	a0,s2
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	c28080e7          	jalr	-984(ra) # 80000c98 <release>
  p->chan = chan;
    80002078:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000207c:	4789                	li	a5,2
    8000207e:	cc9c                	sw	a5,24(s1)
  sched();
    80002080:	00000097          	auipc	ra,0x0
    80002084:	aa8080e7          	jalr	-1368(ra) # 80001b28 <sched>
  p->chan = 0;
    80002088:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	c0a080e7          	jalr	-1014(ra) # 80000c98 <release>
  acquire(lk);
    80002096:	854a                	mv	a0,s2
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	b4c080e7          	jalr	-1204(ra) # 80000be4 <acquire>
}
    800020a0:	70a2                	ld	ra,40(sp)
    800020a2:	7402                	ld	s0,32(sp)
    800020a4:	64e2                	ld	s1,24(sp)
    800020a6:	6942                	ld	s2,16(sp)
    800020a8:	69a2                	ld	s3,8(sp)
    800020aa:	6145                	addi	sp,sp,48
    800020ac:	8082                	ret

00000000800020ae <remove_from_list>:

int remove_from_list(int* curr_proc_index, struct proc* proc_to_remove, struct spinlock* lock) {
    800020ae:	7139                	addi	sp,sp,-64
    800020b0:	fc06                	sd	ra,56(sp)
    800020b2:	f822                	sd	s0,48(sp)
    800020b4:	f426                	sd	s1,40(sp)
    800020b6:	f04a                	sd	s2,32(sp)
    800020b8:	ec4e                	sd	s3,24(sp)
    800020ba:	e852                	sd	s4,16(sp)
    800020bc:	e456                	sd	s5,8(sp)
    800020be:	e05a                	sd	s6,0(sp)
    800020c0:	0080                	addi	s0,sp,64
    800020c2:	84aa                	mv	s1,a0
    800020c4:	892e                	mv	s2,a1
    800020c6:	89b2                	mv	s3,a2
  acquire(lock);
    800020c8:	8532                	mv	a0,a2
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	b1a080e7          	jalr	-1254(ra) # 80000be4 <acquire>
  if(*curr_proc_index == -1) 
    800020d2:	0004aa03          	lw	s4,0(s1)
    800020d6:	57fd                	li	a5,-1
    800020d8:	0afa0663          	beq	s4,a5,80002184 <remove_from_list+0xd6>
  {
      release(lock);
      return -1;
  }
  acquire(&proc_to_remove->proc_lock);
    800020dc:	04090b13          	addi	s6,s2,64
    800020e0:	855a                	mv	a0,s6
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <acquire>

  if(*curr_proc_index == proc_to_remove->proc_index){
    800020ea:	4088                	lw	a0,0(s1)
    800020ec:	03c92783          	lw	a5,60(s2)
    800020f0:	0aa78063          	beq	a5,a0,80002190 <remove_from_list+0xe2>
      release(&proc_to_remove->proc_lock);
      release(lock);
      return 1;
  }
  
  struct proc* curr_node = &proc[*curr_proc_index];
    800020f4:	18800793          	li	a5,392
    800020f8:	02f50533          	mul	a0,a0,a5
    800020fc:	0000f797          	auipc	a5,0xf
    80002100:	71c78793          	addi	a5,a5,1820 # 80011818 <proc>
    80002104:	00f504b3          	add	s1,a0,a5
  acquire(&curr_node->proc_lock);
    80002108:	04050513          	addi	a0,a0,64
    8000210c:	953e                	add	a0,a0,a5
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	ad6080e7          	jalr	-1322(ra) # 80000be4 <acquire>
  release(lock);
    80002116:	854e                	mv	a0,s3
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	b80080e7          	jalr	-1152(ra) # 80000c98 <release>
  
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002120:	5c88                	lw	a0,56(s1)
    80002122:	57fd                	li	a5,-1
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    80002124:	18800a13          	li	s4,392
    80002128:	0000f997          	auipc	s3,0xf
    8000212c:	6f098993          	addi	s3,s3,1776 # 80011818 <proc>
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002130:	5afd                	li	s5,-1
    80002132:	02f50c63          	beq	a0,a5,8000216a <remove_from_list+0xbc>
    80002136:	03c92783          	lw	a5,60(s2)
    8000213a:	06a78a63          	beq	a5,a0,800021ae <remove_from_list+0x100>
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    8000213e:	03450533          	mul	a0,a0,s4
    80002142:	04050513          	addi	a0,a0,64
    80002146:	954e                	add	a0,a0,s3
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	a9c080e7          	jalr	-1380(ra) # 80000be4 <acquire>
    release(&curr_node->proc_lock);
    80002150:	04048513          	addi	a0,s1,64
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	b44080e7          	jalr	-1212(ra) # 80000c98 <release>
    curr_node = &proc[curr_node->next_proc_index];
    8000215c:	5c84                	lw	s1,56(s1)
    8000215e:	034484b3          	mul	s1,s1,s4
    80002162:	94ce                	add	s1,s1,s3
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    80002164:	5c88                	lw	a0,56(s1)
    80002166:	fd5518e3          	bne	a0,s5,80002136 <remove_from_list+0x88>
  }
  if(curr_node->next_proc_index == -1){
    release(&proc_to_remove->proc_lock);
    8000216a:	855a                	mv	a0,s6
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b2c080e7          	jalr	-1236(ra) # 80000c98 <release>
    release(&curr_node->proc_lock);
    80002174:	04048513          	addi	a0,s1,64
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b20080e7          	jalr	-1248(ra) # 80000c98 <release>
    return -1;
    80002180:	5a7d                	li	s4,-1
    80002182:	a899                	j	800021d8 <remove_from_list+0x12a>
      release(lock);
    80002184:	854e                	mv	a0,s3
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	b12080e7          	jalr	-1262(ra) # 80000c98 <release>
      return -1;
    8000218e:	a0a9                	j	800021d8 <remove_from_list+0x12a>
      proc_to_remove->next_proc_index = -1;
    80002190:	57fd                	li	a5,-1
    80002192:	02f92c23          	sw	a5,56(s2)
      release(&proc_to_remove->proc_lock);
    80002196:	855a                	mv	a0,s6
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	b00080e7          	jalr	-1280(ra) # 80000c98 <release>
      release(lock);
    800021a0:	854e                	mv	a0,s3
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	af6080e7          	jalr	-1290(ra) # 80000c98 <release>
      return 1;
    800021aa:	4a05                	li	s4,1
    800021ac:	a035                	j	800021d8 <remove_from_list+0x12a>
  if(curr_node->next_proc_index == -1){
    800021ae:	57fd                	li	a5,-1
    800021b0:	faf50de3          	beq	a0,a5,8000216a <remove_from_list+0xbc>
  }

  curr_node->next_proc_index = proc_to_remove->next_proc_index;
    800021b4:	03892783          	lw	a5,56(s2)
    800021b8:	dc9c                	sw	a5,56(s1)
  proc_to_remove->next_proc_index = -1;
    800021ba:	57fd                	li	a5,-1
    800021bc:	02f92c23          	sw	a5,56(s2)
  release(&proc_to_remove->proc_lock);
    800021c0:	855a                	mv	a0,s6
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	ad6080e7          	jalr	-1322(ra) # 80000c98 <release>
  release(&curr_node->proc_lock);
    800021ca:	04048513          	addi	a0,s1,64
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	aca080e7          	jalr	-1334(ra) # 80000c98 <release>
  return 1;
    800021d6:	4a05                	li	s4,1
}
    800021d8:	8552                	mv	a0,s4
    800021da:	70e2                	ld	ra,56(sp)
    800021dc:	7442                	ld	s0,48(sp)
    800021de:	74a2                	ld	s1,40(sp)
    800021e0:	7902                	ld	s2,32(sp)
    800021e2:	69e2                	ld	s3,24(sp)
    800021e4:	6a42                	ld	s4,16(sp)
    800021e6:	6aa2                	ld	s5,8(sp)
    800021e8:	6b02                	ld	s6,0(sp)
    800021ea:	6121                	addi	sp,sp,64
    800021ec:	8082                	ret

00000000800021ee <freeproc>:
{
    800021ee:	1101                	addi	sp,sp,-32
    800021f0:	ec06                	sd	ra,24(sp)
    800021f2:	e822                	sd	s0,16(sp)
    800021f4:	e426                	sd	s1,8(sp)
    800021f6:	1000                	addi	s0,sp,32
    800021f8:	84aa                	mv	s1,a0
  if(p->trapframe)
    800021fa:	7d28                	ld	a0,120(a0)
    800021fc:	c509                	beqz	a0,80002206 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800021fe:	ffffe097          	auipc	ra,0xffffe
    80002202:	7fa080e7          	jalr	2042(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002206:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    8000220a:	78a8                	ld	a0,112(s1)
    8000220c:	c511                	beqz	a0,80002218 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    8000220e:	74ac                	ld	a1,104(s1)
    80002210:	00000097          	auipc	ra,0x0
    80002214:	852080e7          	jalr	-1966(ra) # 80001a62 <proc_freepagetable>
  p->pagetable = 0;
    80002218:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    8000221c:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80002220:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002224:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80002228:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    8000222c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002230:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002234:	0204a623          	sw	zero,44(s1)
  if(remove_from_list(&zombie_head, p, &lock_zombie_list) == 1){
    80002238:	0000f617          	auipc	a2,0xf
    8000223c:	5c860613          	addi	a2,a2,1480 # 80011800 <lock_zombie_list>
    80002240:	85a6                	mv	a1,s1
    80002242:	00006517          	auipc	a0,0x6
    80002246:	61250513          	addi	a0,a0,1554 # 80008854 <zombie_head>
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	e64080e7          	jalr	-412(ra) # 800020ae <remove_from_list>
    80002252:	4785                	li	a5,1
    80002254:	00f50763          	beq	a0,a5,80002262 <freeproc+0x74>
}
    80002258:	60e2                	ld	ra,24(sp)
    8000225a:	6442                	ld	s0,16(sp)
    8000225c:	64a2                	ld	s1,8(sp)
    8000225e:	6105                	addi	sp,sp,32
    80002260:	8082                	ret
    p->state = UNUSED;
    80002262:	0004ac23          	sw	zero,24(s1)
    add_to_list(&unused_head, p, &lock_unused_list);
    80002266:	0000f617          	auipc	a2,0xf
    8000226a:	56a60613          	addi	a2,a2,1386 # 800117d0 <lock_unused_list>
    8000226e:	85a6                	mv	a1,s1
    80002270:	00006517          	auipc	a0,0x6
    80002274:	5ec50513          	addi	a0,a0,1516 # 8000885c <unused_head>
    80002278:	00000097          	auipc	ra,0x0
    8000227c:	b32080e7          	jalr	-1230(ra) # 80001daa <add_to_list>
}
    80002280:	bfe1                	j	80002258 <freeproc+0x6a>

0000000080002282 <wait>:
{
    80002282:	715d                	addi	sp,sp,-80
    80002284:	e486                	sd	ra,72(sp)
    80002286:	e0a2                	sd	s0,64(sp)
    80002288:	fc26                	sd	s1,56(sp)
    8000228a:	f84a                	sd	s2,48(sp)
    8000228c:	f44e                	sd	s3,40(sp)
    8000228e:	f052                	sd	s4,32(sp)
    80002290:	ec56                	sd	s5,24(sp)
    80002292:	e85a                	sd	s6,16(sp)
    80002294:	e45e                	sd	s7,8(sp)
    80002296:	e062                	sd	s8,0(sp)
    80002298:	0880                	addi	s0,sp,80
    8000229a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	66c080e7          	jalr	1644(ra) # 80001908 <myproc>
    800022a4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022a6:	0000f517          	auipc	a0,0xf
    800022aa:	51250513          	addi	a0,a0,1298 # 800117b8 <wait_lock>
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	936080e7          	jalr	-1738(ra) # 80000be4 <acquire>
    havekids = 0;
    800022b6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022b8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022ba:	00015997          	auipc	s3,0x15
    800022be:	75e98993          	addi	s3,s3,1886 # 80017a18 <tickslock>
        havekids = 1;
    800022c2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022c4:	0000fc17          	auipc	s8,0xf
    800022c8:	4f4c0c13          	addi	s8,s8,1268 # 800117b8 <wait_lock>
    havekids = 0;
    800022cc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022ce:	0000f497          	auipc	s1,0xf
    800022d2:	54a48493          	addi	s1,s1,1354 # 80011818 <proc>
    800022d6:	a0bd                	j	80002344 <wait+0xc2>
          pid = np->pid;
    800022d8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022dc:	000b0e63          	beqz	s6,800022f8 <wait+0x76>
    800022e0:	4691                	li	a3,4
    800022e2:	02c48613          	addi	a2,s1,44
    800022e6:	85da                	mv	a1,s6
    800022e8:	07093503          	ld	a0,112(s2)
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	386080e7          	jalr	902(ra) # 80001672 <copyout>
    800022f4:	02054563          	bltz	a0,8000231e <wait+0x9c>
          freeproc(np);
    800022f8:	8526                	mv	a0,s1
    800022fa:	00000097          	auipc	ra,0x0
    800022fe:	ef4080e7          	jalr	-268(ra) # 800021ee <freeproc>
          release(&np->lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	994080e7          	jalr	-1644(ra) # 80000c98 <release>
          release(&wait_lock);
    8000230c:	0000f517          	auipc	a0,0xf
    80002310:	4ac50513          	addi	a0,a0,1196 # 800117b8 <wait_lock>
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	984080e7          	jalr	-1660(ra) # 80000c98 <release>
          return pid;
    8000231c:	a09d                	j	80002382 <wait+0x100>
            release(&np->lock);
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	978080e7          	jalr	-1672(ra) # 80000c98 <release>
            release(&wait_lock);
    80002328:	0000f517          	auipc	a0,0xf
    8000232c:	49050513          	addi	a0,a0,1168 # 800117b8 <wait_lock>
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	968080e7          	jalr	-1688(ra) # 80000c98 <release>
            return -1;
    80002338:	59fd                	li	s3,-1
    8000233a:	a0a1                	j	80002382 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000233c:	18848493          	addi	s1,s1,392
    80002340:	03348463          	beq	s1,s3,80002368 <wait+0xe6>
      if(np->parent == p){
    80002344:	6cbc                	ld	a5,88(s1)
    80002346:	ff279be3          	bne	a5,s2,8000233c <wait+0xba>
        acquire(&np->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	898080e7          	jalr	-1896(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002354:	4c9c                	lw	a5,24(s1)
    80002356:	f94781e3          	beq	a5,s4,800022d8 <wait+0x56>
        release(&np->lock);
    8000235a:	8526                	mv	a0,s1
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	93c080e7          	jalr	-1732(ra) # 80000c98 <release>
        havekids = 1;
    80002364:	8756                	mv	a4,s5
    80002366:	bfd9                	j	8000233c <wait+0xba>
    if(!havekids || p->killed){
    80002368:	c701                	beqz	a4,80002370 <wait+0xee>
    8000236a:	02892783          	lw	a5,40(s2)
    8000236e:	c79d                	beqz	a5,8000239c <wait+0x11a>
      release(&wait_lock);
    80002370:	0000f517          	auipc	a0,0xf
    80002374:	44850513          	addi	a0,a0,1096 # 800117b8 <wait_lock>
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	920080e7          	jalr	-1760(ra) # 80000c98 <release>
      return -1;
    80002380:	59fd                	li	s3,-1
}
    80002382:	854e                	mv	a0,s3
    80002384:	60a6                	ld	ra,72(sp)
    80002386:	6406                	ld	s0,64(sp)
    80002388:	74e2                	ld	s1,56(sp)
    8000238a:	7942                	ld	s2,48(sp)
    8000238c:	79a2                	ld	s3,40(sp)
    8000238e:	7a02                	ld	s4,32(sp)
    80002390:	6ae2                	ld	s5,24(sp)
    80002392:	6b42                	ld	s6,16(sp)
    80002394:	6ba2                	ld	s7,8(sp)
    80002396:	6c02                	ld	s8,0(sp)
    80002398:	6161                	addi	sp,sp,80
    8000239a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000239c:	85e2                	mv	a1,s8
    8000239e:	854a                	mv	a0,s2
    800023a0:	00000097          	auipc	ra,0x0
    800023a4:	c90080e7          	jalr	-880(ra) # 80002030 <sleep>
    havekids = 0;
    800023a8:	b715                	j	800022cc <wait+0x4a>

00000000800023aa <wakeup>:
{
    800023aa:	7159                	addi	sp,sp,-112
    800023ac:	f486                	sd	ra,104(sp)
    800023ae:	f0a2                	sd	s0,96(sp)
    800023b0:	eca6                	sd	s1,88(sp)
    800023b2:	e8ca                	sd	s2,80(sp)
    800023b4:	e4ce                	sd	s3,72(sp)
    800023b6:	e0d2                	sd	s4,64(sp)
    800023b8:	fc56                	sd	s5,56(sp)
    800023ba:	f85a                	sd	s6,48(sp)
    800023bc:	f45e                	sd	s7,40(sp)
    800023be:	f062                	sd	s8,32(sp)
    800023c0:	ec66                	sd	s9,24(sp)
    800023c2:	e86a                	sd	s10,16(sp)
    800023c4:	e46e                	sd	s11,8(sp)
    800023c6:	1880                	addi	s0,sp,112
    800023c8:	8c2a                	mv	s8,a0
  acquire(&lock_sleeping_list);
    800023ca:	0000f517          	auipc	a0,0xf
    800023ce:	41e50513          	addi	a0,a0,1054 # 800117e8 <lock_sleeping_list>
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	812080e7          	jalr	-2030(ra) # 80000be4 <acquire>
  if(sleeping_head != -1){
    800023da:	00006497          	auipc	s1,0x6
    800023de:	47e4a483          	lw	s1,1150(s1) # 80008858 <sleeping_head>
    800023e2:	57fd                	li	a5,-1
    800023e4:	0cf48a63          	beq	s1,a5,800024b8 <wakeup+0x10e>
    p = &proc[sleeping_head];
    800023e8:	18800793          	li	a5,392
    800023ec:	02f484b3          	mul	s1,s1,a5
    800023f0:	0000f797          	auipc	a5,0xf
    800023f4:	42878793          	addi	a5,a5,1064 # 80011818 <proc>
    800023f8:	94be                	add	s1,s1,a5
    release(&lock_sleeping_list);
    800023fa:	0000f517          	auipc	a0,0xf
    800023fe:	3ee50513          	addi	a0,a0,1006 # 800117e8 <lock_sleeping_list>
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	896080e7          	jalr	-1898(ra) # 80000c98 <release>
      if (p->state == SLEEPING && p->chan == chan) {
    8000240a:	4a89                	li	s5,2
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    8000240c:	0000fd17          	auipc	s10,0xf
    80002410:	3dcd0d13          	addi	s10,s10,988 # 800117e8 <lock_sleeping_list>
    80002414:	00006c97          	auipc	s9,0x6
    80002418:	444c8c93          	addi	s9,s9,1092 # 80008858 <sleeping_head>
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    8000241c:	0000fd97          	auipc	s11,0xf
    80002420:	e84d8d93          	addi	s11,s11,-380 # 800112a0 <cpus>
      if(curr_proc != -1) {
    80002424:	5a7d                	li	s4,-1
        p = &proc[curr_proc];
    80002426:	18800b93          	li	s7,392
    8000242a:	0000fb17          	auipc	s6,0xf
    8000242e:	3eeb0b13          	addi	s6,s6,1006 # 80011818 <proc>
    80002432:	a091                	j	80002476 <wakeup+0xcc>
      if (p->state == SLEEPING && p->chan == chan) {
    80002434:	709c                	ld	a5,32(s1)
    80002436:	05879b63          	bne	a5,s8,8000248c <wakeup+0xe2>
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
    8000243a:	866a                	mv	a2,s10
    8000243c:	85a6                	mv	a1,s1
    8000243e:	8566                	mv	a0,s9
    80002440:	00000097          	auipc	ra,0x0
    80002444:	c6e080e7          	jalr	-914(ra) # 800020ae <remove_from_list>
    80002448:	c131                	beqz	a0,8000248c <wakeup+0xe2>
              p->state = RUNNABLE;
    8000244a:	478d                	li	a5,3
    8000244c:	cc9c                	sw	a5,24(s1)
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    8000244e:	58dc                	lw	a5,52(s1)
    80002450:	00279513          	slli	a0,a5,0x2
    80002454:	953e                	add	a0,a0,a5
    80002456:	0516                	slli	a0,a0,0x5
    80002458:	08850613          	addi	a2,a0,136
    8000245c:	08050513          	addi	a0,a0,128
    80002460:	966e                	add	a2,a2,s11
    80002462:	85a6                	mv	a1,s1
    80002464:	956e                	add	a0,a0,s11
    80002466:	00000097          	auipc	ra,0x0
    8000246a:	944080e7          	jalr	-1724(ra) # 80001daa <add_to_list>
    8000246e:	a839                	j	8000248c <wakeup+0xe2>
        p = &proc[curr_proc];
    80002470:	037904b3          	mul	s1,s2,s7
    80002474:	94da                	add	s1,s1,s6
      acquire(&p->lock);
    80002476:	89a6                	mv	s3,s1
    80002478:	8526                	mv	a0,s1
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	76a080e7          	jalr	1898(ra) # 80000be4 <acquire>
      int next_proc = p->next_proc_index;
    80002482:	0384a903          	lw	s2,56(s1)
      if (p->state == SLEEPING && p->chan == chan) {
    80002486:	4c9c                	lw	a5,24(s1)
    80002488:	fb5786e3          	beq	a5,s5,80002434 <wakeup+0x8a>
      release(&p->lock);
    8000248c:	854e                	mv	a0,s3
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	80a080e7          	jalr	-2038(ra) # 80000c98 <release>
      if(curr_proc != -1) {
    80002496:	fd491de3          	bne	s2,s4,80002470 <wakeup+0xc6>
}
    8000249a:	70a6                	ld	ra,104(sp)
    8000249c:	7406                	ld	s0,96(sp)
    8000249e:	64e6                	ld	s1,88(sp)
    800024a0:	6946                	ld	s2,80(sp)
    800024a2:	69a6                	ld	s3,72(sp)
    800024a4:	6a06                	ld	s4,64(sp)
    800024a6:	7ae2                	ld	s5,56(sp)
    800024a8:	7b42                	ld	s6,48(sp)
    800024aa:	7ba2                	ld	s7,40(sp)
    800024ac:	7c02                	ld	s8,32(sp)
    800024ae:	6ce2                	ld	s9,24(sp)
    800024b0:	6d42                	ld	s10,16(sp)
    800024b2:	6da2                	ld	s11,8(sp)
    800024b4:	6165                	addi	sp,sp,112
    800024b6:	8082                	ret
    release(&lock_sleeping_list);
    800024b8:	0000f517          	auipc	a0,0xf
    800024bc:	33050513          	addi	a0,a0,816 # 800117e8 <lock_sleeping_list>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	7d8080e7          	jalr	2008(ra) # 80000c98 <release>
    return;
    800024c8:	bfc9                	j	8000249a <wakeup+0xf0>

00000000800024ca <reparent>:
{
    800024ca:	7179                	addi	sp,sp,-48
    800024cc:	f406                	sd	ra,40(sp)
    800024ce:	f022                	sd	s0,32(sp)
    800024d0:	ec26                	sd	s1,24(sp)
    800024d2:	e84a                	sd	s2,16(sp)
    800024d4:	e44e                	sd	s3,8(sp)
    800024d6:	e052                	sd	s4,0(sp)
    800024d8:	1800                	addi	s0,sp,48
    800024da:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024dc:	0000f497          	auipc	s1,0xf
    800024e0:	33c48493          	addi	s1,s1,828 # 80011818 <proc>
      pp->parent = initproc;
    800024e4:	00007a17          	auipc	s4,0x7
    800024e8:	b44a0a13          	addi	s4,s4,-1212 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ec:	00015997          	auipc	s3,0x15
    800024f0:	52c98993          	addi	s3,s3,1324 # 80017a18 <tickslock>
    800024f4:	a029                	j	800024fe <reparent+0x34>
    800024f6:	18848493          	addi	s1,s1,392
    800024fa:	01348d63          	beq	s1,s3,80002514 <reparent+0x4a>
    if(pp->parent == p){
    800024fe:	6cbc                	ld	a5,88(s1)
    80002500:	ff279be3          	bne	a5,s2,800024f6 <reparent+0x2c>
      pp->parent = initproc;
    80002504:	000a3503          	ld	a0,0(s4)
    80002508:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    8000250a:	00000097          	auipc	ra,0x0
    8000250e:	ea0080e7          	jalr	-352(ra) # 800023aa <wakeup>
    80002512:	b7d5                	j	800024f6 <reparent+0x2c>
}
    80002514:	70a2                	ld	ra,40(sp)
    80002516:	7402                	ld	s0,32(sp)
    80002518:	64e2                	ld	s1,24(sp)
    8000251a:	6942                	ld	s2,16(sp)
    8000251c:	69a2                	ld	s3,8(sp)
    8000251e:	6a02                	ld	s4,0(sp)
    80002520:	6145                	addi	sp,sp,48
    80002522:	8082                	ret

0000000080002524 <exit>:
{
    80002524:	7179                	addi	sp,sp,-48
    80002526:	f406                	sd	ra,40(sp)
    80002528:	f022                	sd	s0,32(sp)
    8000252a:	ec26                	sd	s1,24(sp)
    8000252c:	e84a                	sd	s2,16(sp)
    8000252e:	e44e                	sd	s3,8(sp)
    80002530:	e052                	sd	s4,0(sp)
    80002532:	1800                	addi	s0,sp,48
    80002534:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	3d2080e7          	jalr	978(ra) # 80001908 <myproc>
    8000253e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002540:	00007797          	auipc	a5,0x7
    80002544:	ae87b783          	ld	a5,-1304(a5) # 80009028 <initproc>
    80002548:	0f050493          	addi	s1,a0,240
    8000254c:	17050913          	addi	s2,a0,368
    80002550:	02a79363          	bne	a5,a0,80002576 <exit+0x52>
    panic("init exiting");
    80002554:	00006517          	auipc	a0,0x6
    80002558:	d0c50513          	addi	a0,a0,-756 # 80008260 <digits+0x220>
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	fe2080e7          	jalr	-30(ra) # 8000053e <panic>
      fileclose(f);
    80002564:	00002097          	auipc	ra,0x2
    80002568:	524080e7          	jalr	1316(ra) # 80004a88 <fileclose>
      p->ofile[fd] = 0;
    8000256c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002570:	04a1                	addi	s1,s1,8
    80002572:	01248563          	beq	s1,s2,8000257c <exit+0x58>
    if(p->ofile[fd]){
    80002576:	6088                	ld	a0,0(s1)
    80002578:	f575                	bnez	a0,80002564 <exit+0x40>
    8000257a:	bfdd                	j	80002570 <exit+0x4c>
  begin_op();
    8000257c:	00002097          	auipc	ra,0x2
    80002580:	040080e7          	jalr	64(ra) # 800045bc <begin_op>
  iput(p->cwd);
    80002584:	1709b503          	ld	a0,368(s3)
    80002588:	00002097          	auipc	ra,0x2
    8000258c:	81c080e7          	jalr	-2020(ra) # 80003da4 <iput>
  end_op();
    80002590:	00002097          	auipc	ra,0x2
    80002594:	0ac080e7          	jalr	172(ra) # 8000463c <end_op>
  p->cwd = 0;
    80002598:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    8000259c:	0000f497          	auipc	s1,0xf
    800025a0:	21c48493          	addi	s1,s1,540 # 800117b8 <wait_lock>
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	63e080e7          	jalr	1598(ra) # 80000be4 <acquire>
  reparent(p);
    800025ae:	854e                	mv	a0,s3
    800025b0:	00000097          	auipc	ra,0x0
    800025b4:	f1a080e7          	jalr	-230(ra) # 800024ca <reparent>
  wakeup(p->parent);
    800025b8:	0589b503          	ld	a0,88(s3)
    800025bc:	00000097          	auipc	ra,0x0
    800025c0:	dee080e7          	jalr	-530(ra) # 800023aa <wakeup>
  acquire(&p->lock);
    800025c4:	854e                	mv	a0,s3
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	61e080e7          	jalr	1566(ra) # 80000be4 <acquire>
  p->xstate = status;
    800025ce:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025d2:	4795                	li	a5,5
    800025d4:	00f9ac23          	sw	a5,24(s3)
  add_to_list(&zombie_head, p, &lock_zombie_list);
    800025d8:	0000f617          	auipc	a2,0xf
    800025dc:	22860613          	addi	a2,a2,552 # 80011800 <lock_zombie_list>
    800025e0:	85ce                	mv	a1,s3
    800025e2:	00006517          	auipc	a0,0x6
    800025e6:	27250513          	addi	a0,a0,626 # 80008854 <zombie_head>
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	7c0080e7          	jalr	1984(ra) # 80001daa <add_to_list>
  release(&wait_lock);
    800025f2:	8526                	mv	a0,s1
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	6a4080e7          	jalr	1700(ra) # 80000c98 <release>
  sched();
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	52c080e7          	jalr	1324(ra) # 80001b28 <sched>
  panic("zombie exit");
    80002604:	00006517          	auipc	a0,0x6
    80002608:	c6c50513          	addi	a0,a0,-916 # 80008270 <digits+0x230>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	f32080e7          	jalr	-206(ra) # 8000053e <panic>

0000000080002614 <kill>:
{
    80002614:	7179                	addi	sp,sp,-48
    80002616:	f406                	sd	ra,40(sp)
    80002618:	f022                	sd	s0,32(sp)
    8000261a:	ec26                	sd	s1,24(sp)
    8000261c:	e84a                	sd	s2,16(sp)
    8000261e:	e44e                	sd	s3,8(sp)
    80002620:	1800                	addi	s0,sp,48
    80002622:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80002624:	0000f497          	auipc	s1,0xf
    80002628:	1f448493          	addi	s1,s1,500 # 80011818 <proc>
    8000262c:	00015997          	auipc	s3,0x15
    80002630:	3ec98993          	addi	s3,s3,1004 # 80017a18 <tickslock>
    acquire(&p->lock);
    80002634:	8526                	mv	a0,s1
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	5ae080e7          	jalr	1454(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000263e:	589c                	lw	a5,48(s1)
    80002640:	01278d63          	beq	a5,s2,8000265a <kill+0x46>
    release(&p->lock);
    80002644:	8526                	mv	a0,s1
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000264e:	18848493          	addi	s1,s1,392
    80002652:	ff3491e3          	bne	s1,s3,80002634 <kill+0x20>
  return -1;
    80002656:	557d                	li	a0,-1
    80002658:	a829                	j	80002672 <kill+0x5e>
      p->killed = 1;
    8000265a:	4785                	li	a5,1
    8000265c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000265e:	4c98                	lw	a4,24(s1)
    80002660:	4789                	li	a5,2
    80002662:	00f70f63          	beq	a4,a5,80002680 <kill+0x6c>
      release(&p->lock);
    80002666:	8526                	mv	a0,s1
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	630080e7          	jalr	1584(ra) # 80000c98 <release>
      return 0;
    80002670:	4501                	li	a0,0
}
    80002672:	70a2                	ld	ra,40(sp)
    80002674:	7402                	ld	s0,32(sp)
    80002676:	64e2                	ld	s1,24(sp)
    80002678:	6942                	ld	s2,16(sp)
    8000267a:	69a2                	ld	s3,8(sp)
    8000267c:	6145                	addi	sp,sp,48
    8000267e:	8082                	ret
        if(remove_from_list(&sleeping_head, p, &lock_sleeping_list) == 1){
    80002680:	0000f617          	auipc	a2,0xf
    80002684:	16860613          	addi	a2,a2,360 # 800117e8 <lock_sleeping_list>
    80002688:	85a6                	mv	a1,s1
    8000268a:	00006517          	auipc	a0,0x6
    8000268e:	1ce50513          	addi	a0,a0,462 # 80008858 <sleeping_head>
    80002692:	00000097          	auipc	ra,0x0
    80002696:	a1c080e7          	jalr	-1508(ra) # 800020ae <remove_from_list>
    8000269a:	4785                	li	a5,1
    8000269c:	fcf515e3          	bne	a0,a5,80002666 <kill+0x52>
          p->state = RUNNABLE;
    800026a0:	478d                	li	a5,3
    800026a2:	cc9c                	sw	a5,24(s1)
          add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
    800026a4:	58d8                	lw	a4,52(s1)
    800026a6:	00271793          	slli	a5,a4,0x2
    800026aa:	97ba                	add	a5,a5,a4
    800026ac:	0796                	slli	a5,a5,0x5
    800026ae:	0000f517          	auipc	a0,0xf
    800026b2:	bf250513          	addi	a0,a0,-1038 # 800112a0 <cpus>
    800026b6:	08878613          	addi	a2,a5,136
    800026ba:	08078793          	addi	a5,a5,128
    800026be:	962a                	add	a2,a2,a0
    800026c0:	85a6                	mv	a1,s1
    800026c2:	953e                	add	a0,a0,a5
    800026c4:	fffff097          	auipc	ra,0xfffff
    800026c8:	6e6080e7          	jalr	1766(ra) # 80001daa <add_to_list>
    800026cc:	bf69                	j	80002666 <kill+0x52>

00000000800026ce <remove_first>:

int remove_first(int* curr_proc_index, struct spinlock* lock) {
    800026ce:	7139                	addi	sp,sp,-64
    800026d0:	fc06                	sd	ra,56(sp)
    800026d2:	f822                	sd	s0,48(sp)
    800026d4:	f426                	sd	s1,40(sp)
    800026d6:	f04a                	sd	s2,32(sp)
    800026d8:	ec4e                	sd	s3,24(sp)
    800026da:	e852                	sd	s4,16(sp)
    800026dc:	e456                	sd	s5,8(sp)
    800026de:	0080                	addi	s0,sp,64
    800026e0:	8aaa                	mv	s5,a0
    800026e2:	89ae                	mv	s3,a1
    acquire(lock);
    800026e4:	852e                	mv	a0,a1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	4fe080e7          	jalr	1278(ra) # 80000be4 <acquire>
    
    if (*curr_proc_index != -1){
    800026ee:	000aa483          	lw	s1,0(s5)
    800026f2:	57fd                	li	a5,-1
    800026f4:	04f48d63          	beq	s1,a5,8000274e <remove_first+0x80>
      int index = *curr_proc_index;
      struct proc *p = &proc[index];
      acquire(&p->proc_lock);
    800026f8:	18800793          	li	a5,392
    800026fc:	02f484b3          	mul	s1,s1,a5
    80002700:	04048a13          	addi	s4,s1,64
    80002704:	0000f917          	auipc	s2,0xf
    80002708:	11490913          	addi	s2,s2,276 # 80011818 <proc>
    8000270c:	9a4a                	add	s4,s4,s2
    8000270e:	8552                	mv	a0,s4
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	4d4080e7          	jalr	1236(ra) # 80000be4 <acquire>
      
      *curr_proc_index = p->next_proc_index;
    80002718:	94ca                	add	s1,s1,s2
    8000271a:	5c9c                	lw	a5,56(s1)
    8000271c:	00faa023          	sw	a5,0(s5)
      p->next_proc_index = -1;
    80002720:	57fd                	li	a5,-1
    80002722:	dc9c                	sw	a5,56(s1)
      int output_proc = p->proc_index;
    80002724:	5cc4                	lw	s1,60(s1)

      release(&p->proc_lock);
    80002726:	8552                	mv	a0,s4
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	570080e7          	jalr	1392(ra) # 80000c98 <release>
      release(lock);
    80002730:	854e                	mv	a0,s3
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	566080e7          	jalr	1382(ra) # 80000c98 <release>
    else{

      release(lock);
      return -1;
    }
    8000273a:	8526                	mv	a0,s1
    8000273c:	70e2                	ld	ra,56(sp)
    8000273e:	7442                	ld	s0,48(sp)
    80002740:	74a2                	ld	s1,40(sp)
    80002742:	7902                	ld	s2,32(sp)
    80002744:	69e2                	ld	s3,24(sp)
    80002746:	6a42                	ld	s4,16(sp)
    80002748:	6aa2                	ld	s5,8(sp)
    8000274a:	6121                	addi	sp,sp,64
    8000274c:	8082                	ret
      release(lock);
    8000274e:	854e                	mv	a0,s3
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	548080e7          	jalr	1352(ra) # 80000c98 <release>
      return -1;
    80002758:	b7cd                	j	8000273a <remove_first+0x6c>

000000008000275a <allocproc>:
{
    8000275a:	7179                	addi	sp,sp,-48
    8000275c:	f406                	sd	ra,40(sp)
    8000275e:	f022                	sd	s0,32(sp)
    80002760:	ec26                	sd	s1,24(sp)
    80002762:	e84a                	sd	s2,16(sp)
    80002764:	e44e                	sd	s3,8(sp)
    80002766:	e052                	sd	s4,0(sp)
    80002768:	1800                	addi	s0,sp,48
    int allocation = remove_first(&unused_head, &lock_unused_list);
    8000276a:	0000f597          	auipc	a1,0xf
    8000276e:	06658593          	addi	a1,a1,102 # 800117d0 <lock_unused_list>
    80002772:	00006517          	auipc	a0,0x6
    80002776:	0ea50513          	addi	a0,a0,234 # 8000885c <unused_head>
    8000277a:	00000097          	auipc	ra,0x0
    8000277e:	f54080e7          	jalr	-172(ra) # 800026ce <remove_first>
    if(allocation == -1){
    80002782:	57fd                	li	a5,-1
    80002784:	0af50863          	beq	a0,a5,80002834 <allocproc+0xda>
    80002788:	892a                	mv	s2,a0
  p=&proc[allocation];
    8000278a:	18800993          	li	s3,392
    8000278e:	033509b3          	mul	s3,a0,s3
    80002792:	0000f497          	auipc	s1,0xf
    80002796:	08648493          	addi	s1,s1,134 # 80011818 <proc>
    8000279a:	94ce                	add	s1,s1,s3
  acquire(&p->lock);
    8000279c:	8526                	mv	a0,s1
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	446080e7          	jalr	1094(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    800027a6:	fffff097          	auipc	ra,0xfffff
    800027aa:	1e8080e7          	jalr	488(ra) # 8000198e <allocpid>
    800027ae:	d888                	sw	a0,48(s1)
  p->state = USED;
    800027b0:	4785                	li	a5,1
    800027b2:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	340080e7          	jalr	832(ra) # 80000af4 <kalloc>
    800027bc:	8a2a                	mv	s4,a0
    800027be:	fca8                	sd	a0,120(s1)
    800027c0:	c541                	beqz	a0,80002848 <allocproc+0xee>
  p->pagetable = proc_pagetable(p);
    800027c2:	8526                	mv	a0,s1
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	202080e7          	jalr	514(ra) # 800019c6 <proc_pagetable>
    800027cc:	8a2a                	mv	s4,a0
    800027ce:	18800793          	li	a5,392
    800027d2:	02f90733          	mul	a4,s2,a5
    800027d6:	0000f797          	auipc	a5,0xf
    800027da:	04278793          	addi	a5,a5,66 # 80011818 <proc>
    800027de:	97ba                	add	a5,a5,a4
    800027e0:	fba8                	sd	a0,112(a5)
  if(p->pagetable == 0){
    800027e2:	cd3d                	beqz	a0,80002860 <allocproc+0x106>
  memset(&p->context, 0, sizeof(p->context));
    800027e4:	08098513          	addi	a0,s3,128
    800027e8:	0000fa17          	auipc	s4,0xf
    800027ec:	030a0a13          	addi	s4,s4,48 # 80011818 <proc>
    800027f0:	07000613          	li	a2,112
    800027f4:	4581                	li	a1,0
    800027f6:	9552                	add	a0,a0,s4
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	4e8080e7          	jalr	1256(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002800:	18800513          	li	a0,392
    80002804:	02a90933          	mul	s2,s2,a0
    80002808:	9952                	add	s2,s2,s4
    8000280a:	fffff797          	auipc	a5,0xfffff
    8000280e:	13e78793          	addi	a5,a5,318 # 80001948 <forkret>
    80002812:	08f93023          	sd	a5,128(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002816:	06093783          	ld	a5,96(s2)
    8000281a:	6705                	lui	a4,0x1
    8000281c:	97ba                	add	a5,a5,a4
    8000281e:	08f93423          	sd	a5,136(s2)
}
    80002822:	8526                	mv	a0,s1
    80002824:	70a2                	ld	ra,40(sp)
    80002826:	7402                	ld	s0,32(sp)
    80002828:	64e2                	ld	s1,24(sp)
    8000282a:	6942                	ld	s2,16(sp)
    8000282c:	69a2                	ld	s3,8(sp)
    8000282e:	6a02                	ld	s4,0(sp)
    80002830:	6145                	addi	sp,sp,48
    80002832:	8082                	ret
      printf("No availble spot in table to allocate\n");
    80002834:	00006517          	auipc	a0,0x6
    80002838:	a4c50513          	addi	a0,a0,-1460 # 80008280 <digits+0x240>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d4c080e7          	jalr	-692(ra) # 80000588 <printf>
      return 0;
    80002844:	4481                	li	s1,0
    80002846:	bff1                	j	80002822 <allocproc+0xc8>
    freeproc(p);
    80002848:	8526                	mv	a0,s1
    8000284a:	00000097          	auipc	ra,0x0
    8000284e:	9a4080e7          	jalr	-1628(ra) # 800021ee <freeproc>
    release(&p->lock);
    80002852:	8526                	mv	a0,s1
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	444080e7          	jalr	1092(ra) # 80000c98 <release>
    return 0;
    8000285c:	84d2                	mv	s1,s4
    8000285e:	b7d1                	j	80002822 <allocproc+0xc8>
    freeproc(p);
    80002860:	8526                	mv	a0,s1
    80002862:	00000097          	auipc	ra,0x0
    80002866:	98c080e7          	jalr	-1652(ra) # 800021ee <freeproc>
    release(&p->lock);
    8000286a:	8526                	mv	a0,s1
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	42c080e7          	jalr	1068(ra) # 80000c98 <release>
    return 0;
    80002874:	84d2                	mv	s1,s4
    80002876:	b775                	j	80002822 <allocproc+0xc8>

0000000080002878 <userinit>:
{
    80002878:	1101                	addi	sp,sp,-32
    8000287a:	ec06                	sd	ra,24(sp)
    8000287c:	e822                	sd	s0,16(sp)
    8000287e:	e426                	sd	s1,8(sp)
    80002880:	1000                	addi	s0,sp,32
  p = allocproc();
    80002882:	00000097          	auipc	ra,0x0
    80002886:	ed8080e7          	jalr	-296(ra) # 8000275a <allocproc>
    8000288a:	84aa                	mv	s1,a0
  initproc = p;
    8000288c:	00006797          	auipc	a5,0x6
    80002890:	78a7be23          	sd	a0,1948(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002894:	03400613          	li	a2,52
    80002898:	00006597          	auipc	a1,0x6
    8000289c:	fd858593          	addi	a1,a1,-40 # 80008870 <initcode>
    800028a0:	7928                	ld	a0,112(a0)
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	ac6080e7          	jalr	-1338(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800028aa:	6785                	lui	a5,0x1
    800028ac:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    800028ae:	7cb8                	ld	a4,120(s1)
    800028b0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800028b4:	7cb8                	ld	a4,120(s1)
    800028b6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800028b8:	4641                	li	a2,16
    800028ba:	00006597          	auipc	a1,0x6
    800028be:	9ee58593          	addi	a1,a1,-1554 # 800082a8 <digits+0x268>
    800028c2:	17848513          	addi	a0,s1,376
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	56c080e7          	jalr	1388(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800028ce:	00006517          	auipc	a0,0x6
    800028d2:	9ea50513          	addi	a0,a0,-1558 # 800082b8 <digits+0x278>
    800028d6:	00002097          	auipc	ra,0x2
    800028da:	aca080e7          	jalr	-1334(ra) # 800043a0 <namei>
    800028de:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    800028e2:	478d                	li	a5,3
    800028e4:	cc9c                	sw	a5,24(s1)
  add_to_list(&cpus[0].runnable_head, p, &cpus[0].lock_runnable_list);
    800028e6:	0000f617          	auipc	a2,0xf
    800028ea:	a4260613          	addi	a2,a2,-1470 # 80011328 <cpus+0x88>
    800028ee:	85a6                	mv	a1,s1
    800028f0:	0000f517          	auipc	a0,0xf
    800028f4:	a3050513          	addi	a0,a0,-1488 # 80011320 <cpus+0x80>
    800028f8:	fffff097          	auipc	ra,0xfffff
    800028fc:	4b2080e7          	jalr	1202(ra) # 80001daa <add_to_list>
  release(&p->lock);
    80002900:	8526                	mv	a0,s1
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	396080e7          	jalr	918(ra) # 80000c98 <release>
}
    8000290a:	60e2                	ld	ra,24(sp)
    8000290c:	6442                	ld	s0,16(sp)
    8000290e:	64a2                	ld	s1,8(sp)
    80002910:	6105                	addi	sp,sp,32
    80002912:	8082                	ret

0000000080002914 <fork>:
{
    80002914:	7139                	addi	sp,sp,-64
    80002916:	fc06                	sd	ra,56(sp)
    80002918:	f822                	sd	s0,48(sp)
    8000291a:	f426                	sd	s1,40(sp)
    8000291c:	f04a                	sd	s2,32(sp)
    8000291e:	ec4e                	sd	s3,24(sp)
    80002920:	e852                	sd	s4,16(sp)
    80002922:	e456                	sd	s5,8(sp)
    80002924:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002926:	fffff097          	auipc	ra,0xfffff
    8000292a:	fe2080e7          	jalr	-30(ra) # 80001908 <myproc>
    8000292e:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002930:	00000097          	auipc	ra,0x0
    80002934:	e2a080e7          	jalr	-470(ra) # 8000275a <allocproc>
    80002938:	14050563          	beqz	a0,80002a82 <fork+0x16e>
    8000293c:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000293e:	0689b603          	ld	a2,104(s3)
    80002942:	792c                	ld	a1,112(a0)
    80002944:	0709b503          	ld	a0,112(s3)
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	c26080e7          	jalr	-986(ra) # 8000156e <uvmcopy>
    80002950:	04054663          	bltz	a0,8000299c <fork+0x88>
  np->sz = p->sz;
    80002954:	0689b783          	ld	a5,104(s3)
    80002958:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    8000295c:	0789b683          	ld	a3,120(s3)
    80002960:	87b6                	mv	a5,a3
    80002962:	07893703          	ld	a4,120(s2)
    80002966:	12068693          	addi	a3,a3,288
    8000296a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000296e:	6788                	ld	a0,8(a5)
    80002970:	6b8c                	ld	a1,16(a5)
    80002972:	6f90                	ld	a2,24(a5)
    80002974:	01073023          	sd	a6,0(a4)
    80002978:	e708                	sd	a0,8(a4)
    8000297a:	eb0c                	sd	a1,16(a4)
    8000297c:	ef10                	sd	a2,24(a4)
    8000297e:	02078793          	addi	a5,a5,32
    80002982:	02070713          	addi	a4,a4,32
    80002986:	fed792e3          	bne	a5,a3,8000296a <fork+0x56>
  np->trapframe->a0 = 0;
    8000298a:	07893783          	ld	a5,120(s2)
    8000298e:	0607b823          	sd	zero,112(a5)
    80002992:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80002996:	17000a13          	li	s4,368
    8000299a:	a03d                	j	800029c8 <fork+0xb4>
    freeproc(np);
    8000299c:	854a                	mv	a0,s2
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	850080e7          	jalr	-1968(ra) # 800021ee <freeproc>
    release(&np->lock);
    800029a6:	854a                	mv	a0,s2
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	2f0080e7          	jalr	752(ra) # 80000c98 <release>
    return -1;
    800029b0:	5afd                	li	s5,-1
    800029b2:	a875                	j	80002a6e <fork+0x15a>
      np->ofile[i] = filedup(p->ofile[i]);
    800029b4:	00002097          	auipc	ra,0x2
    800029b8:	082080e7          	jalr	130(ra) # 80004a36 <filedup>
    800029bc:	009907b3          	add	a5,s2,s1
    800029c0:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800029c2:	04a1                	addi	s1,s1,8
    800029c4:	01448763          	beq	s1,s4,800029d2 <fork+0xbe>
    if(p->ofile[i])
    800029c8:	009987b3          	add	a5,s3,s1
    800029cc:	6388                	ld	a0,0(a5)
    800029ce:	f17d                	bnez	a0,800029b4 <fork+0xa0>
    800029d0:	bfcd                	j	800029c2 <fork+0xae>
  np->cwd = idup(p->cwd);
    800029d2:	1709b503          	ld	a0,368(s3)
    800029d6:	00001097          	auipc	ra,0x1
    800029da:	1d6080e7          	jalr	470(ra) # 80003bac <idup>
    800029de:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800029e2:	4641                	li	a2,16
    800029e4:	17898593          	addi	a1,s3,376
    800029e8:	17890513          	addi	a0,s2,376
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	446080e7          	jalr	1094(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800029f4:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    800029f8:	854a                	mv	a0,s2
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	29e080e7          	jalr	670(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002a02:	0000f497          	auipc	s1,0xf
    80002a06:	89e48493          	addi	s1,s1,-1890 # 800112a0 <cpus>
    80002a0a:	0000fa17          	auipc	s4,0xf
    80002a0e:	daea0a13          	addi	s4,s4,-594 # 800117b8 <wait_lock>
    80002a12:	8552                	mv	a0,s4
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	1d0080e7          	jalr	464(ra) # 80000be4 <acquire>
  np->parent = p;
    80002a1c:	05393c23          	sd	s3,88(s2)
  np->cpu_num = p->cpu_num;
    80002a20:	0349a783          	lw	a5,52(s3)
    80002a24:	02f92a23          	sw	a5,52(s2)
  release(&wait_lock);
    80002a28:	8552                	mv	a0,s4
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	26e080e7          	jalr	622(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002a32:	854a                	mv	a0,s2
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	1b0080e7          	jalr	432(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002a3c:	478d                	li	a5,3
    80002a3e:	00f92c23          	sw	a5,24(s2)
  add_to_list(&c->runnable_head, np, &c->lock_runnable_list);
    80002a42:	03492783          	lw	a5,52(s2)
    80002a46:	00279513          	slli	a0,a5,0x2
    80002a4a:	953e                	add	a0,a0,a5
    80002a4c:	0516                	slli	a0,a0,0x5
    80002a4e:	08850613          	addi	a2,a0,136
    80002a52:	08050513          	addi	a0,a0,128
    80002a56:	9626                	add	a2,a2,s1
    80002a58:	85ca                	mv	a1,s2
    80002a5a:	9526                	add	a0,a0,s1
    80002a5c:	fffff097          	auipc	ra,0xfffff
    80002a60:	34e080e7          	jalr	846(ra) # 80001daa <add_to_list>
  release(&np->lock);
    80002a64:	854a                	mv	a0,s2
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	232080e7          	jalr	562(ra) # 80000c98 <release>
}
    80002a6e:	8556                	mv	a0,s5
    80002a70:	70e2                	ld	ra,56(sp)
    80002a72:	7442                	ld	s0,48(sp)
    80002a74:	74a2                	ld	s1,40(sp)
    80002a76:	7902                	ld	s2,32(sp)
    80002a78:	69e2                	ld	s3,24(sp)
    80002a7a:	6a42                	ld	s4,16(sp)
    80002a7c:	6aa2                	ld	s5,8(sp)
    80002a7e:	6121                	addi	sp,sp,64
    80002a80:	8082                	ret
    return -1;
    80002a82:	5afd                	li	s5,-1
    80002a84:	b7ed                	j	80002a6e <fork+0x15a>

0000000080002a86 <scheduler>:
{
    80002a86:	711d                	addi	sp,sp,-96
    80002a88:	ec86                	sd	ra,88(sp)
    80002a8a:	e8a2                	sd	s0,80(sp)
    80002a8c:	e4a6                	sd	s1,72(sp)
    80002a8e:	e0ca                	sd	s2,64(sp)
    80002a90:	fc4e                	sd	s3,56(sp)
    80002a92:	f852                	sd	s4,48(sp)
    80002a94:	f456                	sd	s5,40(sp)
    80002a96:	f05a                	sd	s6,32(sp)
    80002a98:	ec5e                	sd	s7,24(sp)
    80002a9a:	e862                	sd	s8,16(sp)
    80002a9c:	e466                	sd	s9,8(sp)
    80002a9e:	e06a                	sd	s10,0(sp)
    80002aa0:	1080                	addi	s0,sp,96
    80002aa2:	8712                	mv	a4,tp
  int id = r_tp();
    80002aa4:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002aa6:	0000eb97          	auipc	s7,0xe
    80002aaa:	7fab8b93          	addi	s7,s7,2042 # 800112a0 <cpus>
    80002aae:	00271793          	slli	a5,a4,0x2
    80002ab2:	00e786b3          	add	a3,a5,a4
    80002ab6:	0696                	slli	a3,a3,0x5
    80002ab8:	96de                	add	a3,a3,s7
    80002aba:	0006b023          	sd	zero,0(a3)
    80002abe:	97ba                	add	a5,a5,a4
    80002ac0:	0796                	slli	a5,a5,0x5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002ac2:	08078993          	addi	s3,a5,128
    80002ac6:	99de                	add	s3,s3,s7
    80002ac8:	08878913          	addi	s2,a5,136
    80002acc:	995e                	add	s2,s2,s7
      swtch(&c->context, &p->context);
    80002ace:	07a1                	addi	a5,a5,8
    80002ad0:	9bbe                	add	s7,s7,a5
    if(proc_num != -1){
    80002ad2:	5a7d                	li	s4,-1
    80002ad4:	18800c93          	li	s9,392
      p = &proc[proc_num];
    80002ad8:	0000fb17          	auipc	s6,0xf
    80002adc:	d40b0b13          	addi	s6,s6,-704 # 80011818 <proc>
      p->state = RUNNING;
    80002ae0:	4c11                	li	s8,4
      c->proc = p;
    80002ae2:	8ab6                	mv	s5,a3
    80002ae4:	a82d                	j	80002b1e <scheduler+0x98>
      p = &proc[proc_num];
    80002ae6:	039504b3          	mul	s1,a0,s9
    80002aea:	01648d33          	add	s10,s1,s6
      acquire(&p->lock);
    80002aee:	856a                	mv	a0,s10
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	0f4080e7          	jalr	244(ra) # 80000be4 <acquire>
      p->state = RUNNING;
    80002af8:	018d2c23          	sw	s8,24(s10)
      c->proc = p;
    80002afc:	01aab023          	sd	s10,0(s5)
      swtch(&c->context, &p->context);
    80002b00:	08048593          	addi	a1,s1,128
    80002b04:	95da                	add	a1,a1,s6
    80002b06:	855e                	mv	a0,s7
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	034080e7          	jalr	52(ra) # 80002b3c <swtch>
      c->proc = 0;
    80002b10:	000ab023          	sd	zero,0(s5)
      release(&p->lock);
    80002b14:	856a                	mv	a0,s10
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	182080e7          	jalr	386(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b22:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b26:	10079073          	csrw	sstatus,a5
    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    80002b2a:	85ca                	mv	a1,s2
    80002b2c:	854e                	mv	a0,s3
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	ba0080e7          	jalr	-1120(ra) # 800026ce <remove_first>
    if(proc_num != -1){
    80002b36:	ff4504e3          	beq	a0,s4,80002b1e <scheduler+0x98>
    80002b3a:	b775                	j	80002ae6 <scheduler+0x60>

0000000080002b3c <swtch>:
    80002b3c:	00153023          	sd	ra,0(a0)
    80002b40:	00253423          	sd	sp,8(a0)
    80002b44:	e900                	sd	s0,16(a0)
    80002b46:	ed04                	sd	s1,24(a0)
    80002b48:	03253023          	sd	s2,32(a0)
    80002b4c:	03353423          	sd	s3,40(a0)
    80002b50:	03453823          	sd	s4,48(a0)
    80002b54:	03553c23          	sd	s5,56(a0)
    80002b58:	05653023          	sd	s6,64(a0)
    80002b5c:	05753423          	sd	s7,72(a0)
    80002b60:	05853823          	sd	s8,80(a0)
    80002b64:	05953c23          	sd	s9,88(a0)
    80002b68:	07a53023          	sd	s10,96(a0)
    80002b6c:	07b53423          	sd	s11,104(a0)
    80002b70:	0005b083          	ld	ra,0(a1)
    80002b74:	0085b103          	ld	sp,8(a1)
    80002b78:	6980                	ld	s0,16(a1)
    80002b7a:	6d84                	ld	s1,24(a1)
    80002b7c:	0205b903          	ld	s2,32(a1)
    80002b80:	0285b983          	ld	s3,40(a1)
    80002b84:	0305ba03          	ld	s4,48(a1)
    80002b88:	0385ba83          	ld	s5,56(a1)
    80002b8c:	0405bb03          	ld	s6,64(a1)
    80002b90:	0485bb83          	ld	s7,72(a1)
    80002b94:	0505bc03          	ld	s8,80(a1)
    80002b98:	0585bc83          	ld	s9,88(a1)
    80002b9c:	0605bd03          	ld	s10,96(a1)
    80002ba0:	0685bd83          	ld	s11,104(a1)
    80002ba4:	8082                	ret

0000000080002ba6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ba6:	1141                	addi	sp,sp,-16
    80002ba8:	e406                	sd	ra,8(sp)
    80002baa:	e022                	sd	s0,0(sp)
    80002bac:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bae:	00005597          	auipc	a1,0x5
    80002bb2:	76a58593          	addi	a1,a1,1898 # 80008318 <states.1746+0x30>
    80002bb6:	00015517          	auipc	a0,0x15
    80002bba:	e6250513          	addi	a0,a0,-414 # 80017a18 <tickslock>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	f96080e7          	jalr	-106(ra) # 80000b54 <initlock>
}
    80002bc6:	60a2                	ld	ra,8(sp)
    80002bc8:	6402                	ld	s0,0(sp)
    80002bca:	0141                	addi	sp,sp,16
    80002bcc:	8082                	ret

0000000080002bce <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bce:	1141                	addi	sp,sp,-16
    80002bd0:	e422                	sd	s0,8(sp)
    80002bd2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bd4:	00003797          	auipc	a5,0x3
    80002bd8:	4cc78793          	addi	a5,a5,1228 # 800060a0 <kernelvec>
    80002bdc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002be0:	6422                	ld	s0,8(sp)
    80002be2:	0141                	addi	sp,sp,16
    80002be4:	8082                	ret

0000000080002be6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002be6:	1141                	addi	sp,sp,-16
    80002be8:	e406                	sd	ra,8(sp)
    80002bea:	e022                	sd	s0,0(sp)
    80002bec:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	d1a080e7          	jalr	-742(ra) # 80001908 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bf6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bfa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bfc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c00:	00004617          	auipc	a2,0x4
    80002c04:	40060613          	addi	a2,a2,1024 # 80007000 <_trampoline>
    80002c08:	00004697          	auipc	a3,0x4
    80002c0c:	3f868693          	addi	a3,a3,1016 # 80007000 <_trampoline>
    80002c10:	8e91                	sub	a3,a3,a2
    80002c12:	040007b7          	lui	a5,0x4000
    80002c16:	17fd                	addi	a5,a5,-1
    80002c18:	07b2                	slli	a5,a5,0xc
    80002c1a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c1c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c20:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c22:	180026f3          	csrr	a3,satp
    80002c26:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c28:	7d38                	ld	a4,120(a0)
    80002c2a:	7134                	ld	a3,96(a0)
    80002c2c:	6585                	lui	a1,0x1
    80002c2e:	96ae                	add	a3,a3,a1
    80002c30:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c32:	7d38                	ld	a4,120(a0)
    80002c34:	00000697          	auipc	a3,0x0
    80002c38:	13868693          	addi	a3,a3,312 # 80002d6c <usertrap>
    80002c3c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c3e:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c40:	8692                	mv	a3,tp
    80002c42:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c44:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c48:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c4c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c50:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c54:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c56:	6f18                	ld	a4,24(a4)
    80002c58:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c5c:	792c                	ld	a1,112(a0)
    80002c5e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c60:	00004717          	auipc	a4,0x4
    80002c64:	43070713          	addi	a4,a4,1072 # 80007090 <userret>
    80002c68:	8f11                	sub	a4,a4,a2
    80002c6a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c6c:	577d                	li	a4,-1
    80002c6e:	177e                	slli	a4,a4,0x3f
    80002c70:	8dd9                	or	a1,a1,a4
    80002c72:	02000537          	lui	a0,0x2000
    80002c76:	157d                	addi	a0,a0,-1
    80002c78:	0536                	slli	a0,a0,0xd
    80002c7a:	9782                	jalr	a5
}
    80002c7c:	60a2                	ld	ra,8(sp)
    80002c7e:	6402                	ld	s0,0(sp)
    80002c80:	0141                	addi	sp,sp,16
    80002c82:	8082                	ret

0000000080002c84 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c84:	1101                	addi	sp,sp,-32
    80002c86:	ec06                	sd	ra,24(sp)
    80002c88:	e822                	sd	s0,16(sp)
    80002c8a:	e426                	sd	s1,8(sp)
    80002c8c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c8e:	00015497          	auipc	s1,0x15
    80002c92:	d8a48493          	addi	s1,s1,-630 # 80017a18 <tickslock>
    80002c96:	8526                	mv	a0,s1
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	f4c080e7          	jalr	-180(ra) # 80000be4 <acquire>
  ticks++;
    80002ca0:	00006517          	auipc	a0,0x6
    80002ca4:	39050513          	addi	a0,a0,912 # 80009030 <ticks>
    80002ca8:	411c                	lw	a5,0(a0)
    80002caa:	2785                	addiw	a5,a5,1
    80002cac:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	6fc080e7          	jalr	1788(ra) # 800023aa <wakeup>
  release(&tickslock);
    80002cb6:	8526                	mv	a0,s1
    80002cb8:	ffffe097          	auipc	ra,0xffffe
    80002cbc:	fe0080e7          	jalr	-32(ra) # 80000c98 <release>
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret

0000000080002cca <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002cca:	1101                	addi	sp,sp,-32
    80002ccc:	ec06                	sd	ra,24(sp)
    80002cce:	e822                	sd	s0,16(sp)
    80002cd0:	e426                	sd	s1,8(sp)
    80002cd2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cd4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cd8:	00074d63          	bltz	a4,80002cf2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cdc:	57fd                	li	a5,-1
    80002cde:	17fe                	slli	a5,a5,0x3f
    80002ce0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ce2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ce4:	06f70363          	beq	a4,a5,80002d4a <devintr+0x80>
  }
}
    80002ce8:	60e2                	ld	ra,24(sp)
    80002cea:	6442                	ld	s0,16(sp)
    80002cec:	64a2                	ld	s1,8(sp)
    80002cee:	6105                	addi	sp,sp,32
    80002cf0:	8082                	ret
     (scause & 0xff) == 9){
    80002cf2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cf6:	46a5                	li	a3,9
    80002cf8:	fed792e3          	bne	a5,a3,80002cdc <devintr+0x12>
    int irq = plic_claim();
    80002cfc:	00003097          	auipc	ra,0x3
    80002d00:	4ac080e7          	jalr	1196(ra) # 800061a8 <plic_claim>
    80002d04:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d06:	47a9                	li	a5,10
    80002d08:	02f50763          	beq	a0,a5,80002d36 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d0c:	4785                	li	a5,1
    80002d0e:	02f50963          	beq	a0,a5,80002d40 <devintr+0x76>
    return 1;
    80002d12:	4505                	li	a0,1
    } else if(irq){
    80002d14:	d8f1                	beqz	s1,80002ce8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d16:	85a6                	mv	a1,s1
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	60850513          	addi	a0,a0,1544 # 80008320 <states.1746+0x38>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	868080e7          	jalr	-1944(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d28:	8526                	mv	a0,s1
    80002d2a:	00003097          	auipc	ra,0x3
    80002d2e:	4a2080e7          	jalr	1186(ra) # 800061cc <plic_complete>
    return 1;
    80002d32:	4505                	li	a0,1
    80002d34:	bf55                	j	80002ce8 <devintr+0x1e>
      uartintr();
    80002d36:	ffffe097          	auipc	ra,0xffffe
    80002d3a:	c72080e7          	jalr	-910(ra) # 800009a8 <uartintr>
    80002d3e:	b7ed                	j	80002d28 <devintr+0x5e>
      virtio_disk_intr();
    80002d40:	00004097          	auipc	ra,0x4
    80002d44:	96c080e7          	jalr	-1684(ra) # 800066ac <virtio_disk_intr>
    80002d48:	b7c5                	j	80002d28 <devintr+0x5e>
    if(cpuid() == 0){
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	b8a080e7          	jalr	-1142(ra) # 800018d4 <cpuid>
    80002d52:	c901                	beqz	a0,80002d62 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d54:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d58:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d5a:	14479073          	csrw	sip,a5
    return 2;
    80002d5e:	4509                	li	a0,2
    80002d60:	b761                	j	80002ce8 <devintr+0x1e>
      clockintr();
    80002d62:	00000097          	auipc	ra,0x0
    80002d66:	f22080e7          	jalr	-222(ra) # 80002c84 <clockintr>
    80002d6a:	b7ed                	j	80002d54 <devintr+0x8a>

0000000080002d6c <usertrap>:
{
    80002d6c:	1101                	addi	sp,sp,-32
    80002d6e:	ec06                	sd	ra,24(sp)
    80002d70:	e822                	sd	s0,16(sp)
    80002d72:	e426                	sd	s1,8(sp)
    80002d74:	e04a                	sd	s2,0(sp)
    80002d76:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d78:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d7c:	1007f793          	andi	a5,a5,256
    80002d80:	e3ad                	bnez	a5,80002de2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d82:	00003797          	auipc	a5,0x3
    80002d86:	31e78793          	addi	a5,a5,798 # 800060a0 <kernelvec>
    80002d8a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	b7a080e7          	jalr	-1158(ra) # 80001908 <myproc>
    80002d96:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d98:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d9a:	14102773          	csrr	a4,sepc
    80002d9e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002da0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002da4:	47a1                	li	a5,8
    80002da6:	04f71c63          	bne	a4,a5,80002dfe <usertrap+0x92>
    if(p->killed)
    80002daa:	551c                	lw	a5,40(a0)
    80002dac:	e3b9                	bnez	a5,80002df2 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002dae:	7cb8                	ld	a4,120(s1)
    80002db0:	6f1c                	ld	a5,24(a4)
    80002db2:	0791                	addi	a5,a5,4
    80002db4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dbe:	10079073          	csrw	sstatus,a5
    syscall();
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	2e0080e7          	jalr	736(ra) # 800030a2 <syscall>
  if(p->killed)
    80002dca:	549c                	lw	a5,40(s1)
    80002dcc:	ebc1                	bnez	a5,80002e5c <usertrap+0xf0>
  usertrapret();
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	e18080e7          	jalr	-488(ra) # 80002be6 <usertrapret>
}
    80002dd6:	60e2                	ld	ra,24(sp)
    80002dd8:	6442                	ld	s0,16(sp)
    80002dda:	64a2                	ld	s1,8(sp)
    80002ddc:	6902                	ld	s2,0(sp)
    80002dde:	6105                	addi	sp,sp,32
    80002de0:	8082                	ret
    panic("usertrap: not from user mode");
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	55e50513          	addi	a0,a0,1374 # 80008340 <states.1746+0x58>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	754080e7          	jalr	1876(ra) # 8000053e <panic>
      exit(-1);
    80002df2:	557d                	li	a0,-1
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	730080e7          	jalr	1840(ra) # 80002524 <exit>
    80002dfc:	bf4d                	j	80002dae <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002dfe:	00000097          	auipc	ra,0x0
    80002e02:	ecc080e7          	jalr	-308(ra) # 80002cca <devintr>
    80002e06:	892a                	mv	s2,a0
    80002e08:	c501                	beqz	a0,80002e10 <usertrap+0xa4>
  if(p->killed)
    80002e0a:	549c                	lw	a5,40(s1)
    80002e0c:	c3a1                	beqz	a5,80002e4c <usertrap+0xe0>
    80002e0e:	a815                	j	80002e42 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e10:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e14:	5890                	lw	a2,48(s1)
    80002e16:	00005517          	auipc	a0,0x5
    80002e1a:	54a50513          	addi	a0,a0,1354 # 80008360 <states.1746+0x78>
    80002e1e:	ffffd097          	auipc	ra,0xffffd
    80002e22:	76a080e7          	jalr	1898(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e26:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e2a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e2e:	00005517          	auipc	a0,0x5
    80002e32:	56250513          	addi	a0,a0,1378 # 80008390 <states.1746+0xa8>
    80002e36:	ffffd097          	auipc	ra,0xffffd
    80002e3a:	752080e7          	jalr	1874(ra) # 80000588 <printf>
    p->killed = 1;
    80002e3e:	4785                	li	a5,1
    80002e40:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e42:	557d                	li	a0,-1
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	6e0080e7          	jalr	1760(ra) # 80002524 <exit>
  if(which_dev == 2)
    80002e4c:	4789                	li	a5,2
    80002e4e:	f8f910e3          	bne	s2,a5,80002dce <usertrap+0x62>
    yield();
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	13c080e7          	jalr	316(ra) # 80001f8e <yield>
    80002e5a:	bf95                	j	80002dce <usertrap+0x62>
  int which_dev = 0;
    80002e5c:	4901                	li	s2,0
    80002e5e:	b7d5                	j	80002e42 <usertrap+0xd6>

0000000080002e60 <kerneltrap>:
{
    80002e60:	7179                	addi	sp,sp,-48
    80002e62:	f406                	sd	ra,40(sp)
    80002e64:	f022                	sd	s0,32(sp)
    80002e66:	ec26                	sd	s1,24(sp)
    80002e68:	e84a                	sd	s2,16(sp)
    80002e6a:	e44e                	sd	s3,8(sp)
    80002e6c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e6e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e72:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e76:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e7a:	1004f793          	andi	a5,s1,256
    80002e7e:	cb85                	beqz	a5,80002eae <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e80:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e84:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e86:	ef85                	bnez	a5,80002ebe <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	e42080e7          	jalr	-446(ra) # 80002cca <devintr>
    80002e90:	cd1d                	beqz	a0,80002ece <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e92:	4789                	li	a5,2
    80002e94:	06f50a63          	beq	a0,a5,80002f08 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e98:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e9c:	10049073          	csrw	sstatus,s1
}
    80002ea0:	70a2                	ld	ra,40(sp)
    80002ea2:	7402                	ld	s0,32(sp)
    80002ea4:	64e2                	ld	s1,24(sp)
    80002ea6:	6942                	ld	s2,16(sp)
    80002ea8:	69a2                	ld	s3,8(sp)
    80002eaa:	6145                	addi	sp,sp,48
    80002eac:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002eae:	00005517          	auipc	a0,0x5
    80002eb2:	50250513          	addi	a0,a0,1282 # 800083b0 <states.1746+0xc8>
    80002eb6:	ffffd097          	auipc	ra,0xffffd
    80002eba:	688080e7          	jalr	1672(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ebe:	00005517          	auipc	a0,0x5
    80002ec2:	51a50513          	addi	a0,a0,1306 # 800083d8 <states.1746+0xf0>
    80002ec6:	ffffd097          	auipc	ra,0xffffd
    80002eca:	678080e7          	jalr	1656(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ece:	85ce                	mv	a1,s3
    80002ed0:	00005517          	auipc	a0,0x5
    80002ed4:	52850513          	addi	a0,a0,1320 # 800083f8 <states.1746+0x110>
    80002ed8:	ffffd097          	auipc	ra,0xffffd
    80002edc:	6b0080e7          	jalr	1712(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ee0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ee4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ee8:	00005517          	auipc	a0,0x5
    80002eec:	52050513          	addi	a0,a0,1312 # 80008408 <states.1746+0x120>
    80002ef0:	ffffd097          	auipc	ra,0xffffd
    80002ef4:	698080e7          	jalr	1688(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ef8:	00005517          	auipc	a0,0x5
    80002efc:	52850513          	addi	a0,a0,1320 # 80008420 <states.1746+0x138>
    80002f00:	ffffd097          	auipc	ra,0xffffd
    80002f04:	63e080e7          	jalr	1598(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	a00080e7          	jalr	-1536(ra) # 80001908 <myproc>
    80002f10:	d541                	beqz	a0,80002e98 <kerneltrap+0x38>
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	9f6080e7          	jalr	-1546(ra) # 80001908 <myproc>
    80002f1a:	4d18                	lw	a4,24(a0)
    80002f1c:	4791                	li	a5,4
    80002f1e:	f6f71de3          	bne	a4,a5,80002e98 <kerneltrap+0x38>
    yield();
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	06c080e7          	jalr	108(ra) # 80001f8e <yield>
    80002f2a:	b7bd                	j	80002e98 <kerneltrap+0x38>

0000000080002f2c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f2c:	1101                	addi	sp,sp,-32
    80002f2e:	ec06                	sd	ra,24(sp)
    80002f30:	e822                	sd	s0,16(sp)
    80002f32:	e426                	sd	s1,8(sp)
    80002f34:	1000                	addi	s0,sp,32
    80002f36:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	9d0080e7          	jalr	-1584(ra) # 80001908 <myproc>
  switch (n) {
    80002f40:	4795                	li	a5,5
    80002f42:	0497e163          	bltu	a5,s1,80002f84 <argraw+0x58>
    80002f46:	048a                	slli	s1,s1,0x2
    80002f48:	00005717          	auipc	a4,0x5
    80002f4c:	51070713          	addi	a4,a4,1296 # 80008458 <states.1746+0x170>
    80002f50:	94ba                	add	s1,s1,a4
    80002f52:	409c                	lw	a5,0(s1)
    80002f54:	97ba                	add	a5,a5,a4
    80002f56:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f58:	7d3c                	ld	a5,120(a0)
    80002f5a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	64a2                	ld	s1,8(sp)
    80002f62:	6105                	addi	sp,sp,32
    80002f64:	8082                	ret
    return p->trapframe->a1;
    80002f66:	7d3c                	ld	a5,120(a0)
    80002f68:	7fa8                	ld	a0,120(a5)
    80002f6a:	bfcd                	j	80002f5c <argraw+0x30>
    return p->trapframe->a2;
    80002f6c:	7d3c                	ld	a5,120(a0)
    80002f6e:	63c8                	ld	a0,128(a5)
    80002f70:	b7f5                	j	80002f5c <argraw+0x30>
    return p->trapframe->a3;
    80002f72:	7d3c                	ld	a5,120(a0)
    80002f74:	67c8                	ld	a0,136(a5)
    80002f76:	b7dd                	j	80002f5c <argraw+0x30>
    return p->trapframe->a4;
    80002f78:	7d3c                	ld	a5,120(a0)
    80002f7a:	6bc8                	ld	a0,144(a5)
    80002f7c:	b7c5                	j	80002f5c <argraw+0x30>
    return p->trapframe->a5;
    80002f7e:	7d3c                	ld	a5,120(a0)
    80002f80:	6fc8                	ld	a0,152(a5)
    80002f82:	bfe9                	j	80002f5c <argraw+0x30>
  panic("argraw");
    80002f84:	00005517          	auipc	a0,0x5
    80002f88:	4ac50513          	addi	a0,a0,1196 # 80008430 <states.1746+0x148>
    80002f8c:	ffffd097          	auipc	ra,0xffffd
    80002f90:	5b2080e7          	jalr	1458(ra) # 8000053e <panic>

0000000080002f94 <fetchaddr>:
{
    80002f94:	1101                	addi	sp,sp,-32
    80002f96:	ec06                	sd	ra,24(sp)
    80002f98:	e822                	sd	s0,16(sp)
    80002f9a:	e426                	sd	s1,8(sp)
    80002f9c:	e04a                	sd	s2,0(sp)
    80002f9e:	1000                	addi	s0,sp,32
    80002fa0:	84aa                	mv	s1,a0
    80002fa2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	964080e7          	jalr	-1692(ra) # 80001908 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002fac:	753c                	ld	a5,104(a0)
    80002fae:	02f4f863          	bgeu	s1,a5,80002fde <fetchaddr+0x4a>
    80002fb2:	00848713          	addi	a4,s1,8
    80002fb6:	02e7e663          	bltu	a5,a4,80002fe2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fba:	46a1                	li	a3,8
    80002fbc:	8626                	mv	a2,s1
    80002fbe:	85ca                	mv	a1,s2
    80002fc0:	7928                	ld	a0,112(a0)
    80002fc2:	ffffe097          	auipc	ra,0xffffe
    80002fc6:	73c080e7          	jalr	1852(ra) # 800016fe <copyin>
    80002fca:	00a03533          	snez	a0,a0
    80002fce:	40a00533          	neg	a0,a0
}
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	64a2                	ld	s1,8(sp)
    80002fd8:	6902                	ld	s2,0(sp)
    80002fda:	6105                	addi	sp,sp,32
    80002fdc:	8082                	ret
    return -1;
    80002fde:	557d                	li	a0,-1
    80002fe0:	bfcd                	j	80002fd2 <fetchaddr+0x3e>
    80002fe2:	557d                	li	a0,-1
    80002fe4:	b7fd                	j	80002fd2 <fetchaddr+0x3e>

0000000080002fe6 <fetchstr>:
{
    80002fe6:	7179                	addi	sp,sp,-48
    80002fe8:	f406                	sd	ra,40(sp)
    80002fea:	f022                	sd	s0,32(sp)
    80002fec:	ec26                	sd	s1,24(sp)
    80002fee:	e84a                	sd	s2,16(sp)
    80002ff0:	e44e                	sd	s3,8(sp)
    80002ff2:	1800                	addi	s0,sp,48
    80002ff4:	892a                	mv	s2,a0
    80002ff6:	84ae                	mv	s1,a1
    80002ff8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	90e080e7          	jalr	-1778(ra) # 80001908 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003002:	86ce                	mv	a3,s3
    80003004:	864a                	mv	a2,s2
    80003006:	85a6                	mv	a1,s1
    80003008:	7928                	ld	a0,112(a0)
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	780080e7          	jalr	1920(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003012:	00054763          	bltz	a0,80003020 <fetchstr+0x3a>
  return strlen(buf);
    80003016:	8526                	mv	a0,s1
    80003018:	ffffe097          	auipc	ra,0xffffe
    8000301c:	e4c080e7          	jalr	-436(ra) # 80000e64 <strlen>
}
    80003020:	70a2                	ld	ra,40(sp)
    80003022:	7402                	ld	s0,32(sp)
    80003024:	64e2                	ld	s1,24(sp)
    80003026:	6942                	ld	s2,16(sp)
    80003028:	69a2                	ld	s3,8(sp)
    8000302a:	6145                	addi	sp,sp,48
    8000302c:	8082                	ret

000000008000302e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	e426                	sd	s1,8(sp)
    80003036:	1000                	addi	s0,sp,32
    80003038:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000303a:	00000097          	auipc	ra,0x0
    8000303e:	ef2080e7          	jalr	-270(ra) # 80002f2c <argraw>
    80003042:	c088                	sw	a0,0(s1)
  return 0;
}
    80003044:	4501                	li	a0,0
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	64a2                	ld	s1,8(sp)
    8000304c:	6105                	addi	sp,sp,32
    8000304e:	8082                	ret

0000000080003050 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003050:	1101                	addi	sp,sp,-32
    80003052:	ec06                	sd	ra,24(sp)
    80003054:	e822                	sd	s0,16(sp)
    80003056:	e426                	sd	s1,8(sp)
    80003058:	1000                	addi	s0,sp,32
    8000305a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	ed0080e7          	jalr	-304(ra) # 80002f2c <argraw>
    80003064:	e088                	sd	a0,0(s1)
  return 0;
}
    80003066:	4501                	li	a0,0
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	64a2                	ld	s1,8(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret

0000000080003072 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003072:	1101                	addi	sp,sp,-32
    80003074:	ec06                	sd	ra,24(sp)
    80003076:	e822                	sd	s0,16(sp)
    80003078:	e426                	sd	s1,8(sp)
    8000307a:	e04a                	sd	s2,0(sp)
    8000307c:	1000                	addi	s0,sp,32
    8000307e:	84ae                	mv	s1,a1
    80003080:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003082:	00000097          	auipc	ra,0x0
    80003086:	eaa080e7          	jalr	-342(ra) # 80002f2c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000308a:	864a                	mv	a2,s2
    8000308c:	85a6                	mv	a1,s1
    8000308e:	00000097          	auipc	ra,0x0
    80003092:	f58080e7          	jalr	-168(ra) # 80002fe6 <fetchstr>
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	64a2                	ld	s1,8(sp)
    8000309c:	6902                	ld	s2,0(sp)
    8000309e:	6105                	addi	sp,sp,32
    800030a0:	8082                	ret

00000000800030a2 <syscall>:
[SYS_get_cpu] sys_get_cpu,
};

void
syscall(void)
{
    800030a2:	1101                	addi	sp,sp,-32
    800030a4:	ec06                	sd	ra,24(sp)
    800030a6:	e822                	sd	s0,16(sp)
    800030a8:	e426                	sd	s1,8(sp)
    800030aa:	e04a                	sd	s2,0(sp)
    800030ac:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030ae:	fffff097          	auipc	ra,0xfffff
    800030b2:	85a080e7          	jalr	-1958(ra) # 80001908 <myproc>
    800030b6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030b8:	07853903          	ld	s2,120(a0)
    800030bc:	0a893783          	ld	a5,168(s2)
    800030c0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030c4:	37fd                	addiw	a5,a5,-1
    800030c6:	4759                	li	a4,22
    800030c8:	00f76f63          	bltu	a4,a5,800030e6 <syscall+0x44>
    800030cc:	00369713          	slli	a4,a3,0x3
    800030d0:	00005797          	auipc	a5,0x5
    800030d4:	3a078793          	addi	a5,a5,928 # 80008470 <syscalls>
    800030d8:	97ba                	add	a5,a5,a4
    800030da:	639c                	ld	a5,0(a5)
    800030dc:	c789                	beqz	a5,800030e6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030de:	9782                	jalr	a5
    800030e0:	06a93823          	sd	a0,112(s2)
    800030e4:	a839                	j	80003102 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030e6:	17848613          	addi	a2,s1,376
    800030ea:	588c                	lw	a1,48(s1)
    800030ec:	00005517          	auipc	a0,0x5
    800030f0:	34c50513          	addi	a0,a0,844 # 80008438 <states.1746+0x150>
    800030f4:	ffffd097          	auipc	ra,0xffffd
    800030f8:	494080e7          	jalr	1172(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030fc:	7cbc                	ld	a5,120(s1)
    800030fe:	577d                	li	a4,-1
    80003100:	fbb8                	sd	a4,112(a5)
  }
}
    80003102:	60e2                	ld	ra,24(sp)
    80003104:	6442                	ld	s0,16(sp)
    80003106:	64a2                	ld	s1,8(sp)
    80003108:	6902                	ld	s2,0(sp)
    8000310a:	6105                	addi	sp,sp,32
    8000310c:	8082                	ret

000000008000310e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000310e:	1101                	addi	sp,sp,-32
    80003110:	ec06                	sd	ra,24(sp)
    80003112:	e822                	sd	s0,16(sp)
    80003114:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003116:	fec40593          	addi	a1,s0,-20
    8000311a:	4501                	li	a0,0
    8000311c:	00000097          	auipc	ra,0x0
    80003120:	f12080e7          	jalr	-238(ra) # 8000302e <argint>
    return -1;
    80003124:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003126:	00054963          	bltz	a0,80003138 <sys_exit+0x2a>
  exit(n);
    8000312a:	fec42503          	lw	a0,-20(s0)
    8000312e:	fffff097          	auipc	ra,0xfffff
    80003132:	3f6080e7          	jalr	1014(ra) # 80002524 <exit>
  return 0;  // not reached
    80003136:	4781                	li	a5,0
}
    80003138:	853e                	mv	a0,a5
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003142:	1141                	addi	sp,sp,-16
    80003144:	e406                	sd	ra,8(sp)
    80003146:	e022                	sd	s0,0(sp)
    80003148:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	7be080e7          	jalr	1982(ra) # 80001908 <myproc>
}
    80003152:	5908                	lw	a0,48(a0)
    80003154:	60a2                	ld	ra,8(sp)
    80003156:	6402                	ld	s0,0(sp)
    80003158:	0141                	addi	sp,sp,16
    8000315a:	8082                	ret

000000008000315c <sys_fork>:

uint64
sys_fork(void)
{
    8000315c:	1141                	addi	sp,sp,-16
    8000315e:	e406                	sd	ra,8(sp)
    80003160:	e022                	sd	s0,0(sp)
    80003162:	0800                	addi	s0,sp,16
  return fork();
    80003164:	fffff097          	auipc	ra,0xfffff
    80003168:	7b0080e7          	jalr	1968(ra) # 80002914 <fork>
}
    8000316c:	60a2                	ld	ra,8(sp)
    8000316e:	6402                	ld	s0,0(sp)
    80003170:	0141                	addi	sp,sp,16
    80003172:	8082                	ret

0000000080003174 <sys_wait>:

uint64
sys_wait(void)
{
    80003174:	1101                	addi	sp,sp,-32
    80003176:	ec06                	sd	ra,24(sp)
    80003178:	e822                	sd	s0,16(sp)
    8000317a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000317c:	fe840593          	addi	a1,s0,-24
    80003180:	4501                	li	a0,0
    80003182:	00000097          	auipc	ra,0x0
    80003186:	ece080e7          	jalr	-306(ra) # 80003050 <argaddr>
    8000318a:	87aa                	mv	a5,a0
    return -1;
    8000318c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000318e:	0007c863          	bltz	a5,8000319e <sys_wait+0x2a>
  return wait(p);
    80003192:	fe843503          	ld	a0,-24(s0)
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	0ec080e7          	jalr	236(ra) # 80002282 <wait>
}
    8000319e:	60e2                	ld	ra,24(sp)
    800031a0:	6442                	ld	s0,16(sp)
    800031a2:	6105                	addi	sp,sp,32
    800031a4:	8082                	ret

00000000800031a6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031a6:	7179                	addi	sp,sp,-48
    800031a8:	f406                	sd	ra,40(sp)
    800031aa:	f022                	sd	s0,32(sp)
    800031ac:	ec26                	sd	s1,24(sp)
    800031ae:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800031b0:	fdc40593          	addi	a1,s0,-36
    800031b4:	4501                	li	a0,0
    800031b6:	00000097          	auipc	ra,0x0
    800031ba:	e78080e7          	jalr	-392(ra) # 8000302e <argint>
    800031be:	87aa                	mv	a5,a0
    return -1;
    800031c0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800031c2:	0207c063          	bltz	a5,800031e2 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	742080e7          	jalr	1858(ra) # 80001908 <myproc>
    800031ce:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800031d0:	fdc42503          	lw	a0,-36(s0)
    800031d4:	fffff097          	auipc	ra,0xfffff
    800031d8:	8e0080e7          	jalr	-1824(ra) # 80001ab4 <growproc>
    800031dc:	00054863          	bltz	a0,800031ec <sys_sbrk+0x46>
    return -1;
  return addr;
    800031e0:	8526                	mv	a0,s1
}
    800031e2:	70a2                	ld	ra,40(sp)
    800031e4:	7402                	ld	s0,32(sp)
    800031e6:	64e2                	ld	s1,24(sp)
    800031e8:	6145                	addi	sp,sp,48
    800031ea:	8082                	ret
    return -1;
    800031ec:	557d                	li	a0,-1
    800031ee:	bfd5                	j	800031e2 <sys_sbrk+0x3c>

00000000800031f0 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031f0:	7139                	addi	sp,sp,-64
    800031f2:	fc06                	sd	ra,56(sp)
    800031f4:	f822                	sd	s0,48(sp)
    800031f6:	f426                	sd	s1,40(sp)
    800031f8:	f04a                	sd	s2,32(sp)
    800031fa:	ec4e                	sd	s3,24(sp)
    800031fc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800031fe:	fcc40593          	addi	a1,s0,-52
    80003202:	4501                	li	a0,0
    80003204:	00000097          	auipc	ra,0x0
    80003208:	e2a080e7          	jalr	-470(ra) # 8000302e <argint>
    return -1;
    8000320c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000320e:	06054563          	bltz	a0,80003278 <sys_sleep+0x88>
  acquire(&tickslock);
    80003212:	00015517          	auipc	a0,0x15
    80003216:	80650513          	addi	a0,a0,-2042 # 80017a18 <tickslock>
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	9ca080e7          	jalr	-1590(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003222:	00006917          	auipc	s2,0x6
    80003226:	e0e92903          	lw	s2,-498(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000322a:	fcc42783          	lw	a5,-52(s0)
    8000322e:	cf85                	beqz	a5,80003266 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003230:	00014997          	auipc	s3,0x14
    80003234:	7e898993          	addi	s3,s3,2024 # 80017a18 <tickslock>
    80003238:	00006497          	auipc	s1,0x6
    8000323c:	df848493          	addi	s1,s1,-520 # 80009030 <ticks>
    if(myproc()->killed){
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	6c8080e7          	jalr	1736(ra) # 80001908 <myproc>
    80003248:	551c                	lw	a5,40(a0)
    8000324a:	ef9d                	bnez	a5,80003288 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000324c:	85ce                	mv	a1,s3
    8000324e:	8526                	mv	a0,s1
    80003250:	fffff097          	auipc	ra,0xfffff
    80003254:	de0080e7          	jalr	-544(ra) # 80002030 <sleep>
  while(ticks - ticks0 < n){
    80003258:	409c                	lw	a5,0(s1)
    8000325a:	412787bb          	subw	a5,a5,s2
    8000325e:	fcc42703          	lw	a4,-52(s0)
    80003262:	fce7efe3          	bltu	a5,a4,80003240 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003266:	00014517          	auipc	a0,0x14
    8000326a:	7b250513          	addi	a0,a0,1970 # 80017a18 <tickslock>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	a2a080e7          	jalr	-1494(ra) # 80000c98 <release>
  return 0;
    80003276:	4781                	li	a5,0
}
    80003278:	853e                	mv	a0,a5
    8000327a:	70e2                	ld	ra,56(sp)
    8000327c:	7442                	ld	s0,48(sp)
    8000327e:	74a2                	ld	s1,40(sp)
    80003280:	7902                	ld	s2,32(sp)
    80003282:	69e2                	ld	s3,24(sp)
    80003284:	6121                	addi	sp,sp,64
    80003286:	8082                	ret
      release(&tickslock);
    80003288:	00014517          	auipc	a0,0x14
    8000328c:	79050513          	addi	a0,a0,1936 # 80017a18 <tickslock>
    80003290:	ffffe097          	auipc	ra,0xffffe
    80003294:	a08080e7          	jalr	-1528(ra) # 80000c98 <release>
      return -1;
    80003298:	57fd                	li	a5,-1
    8000329a:	bff9                	j	80003278 <sys_sleep+0x88>

000000008000329c <sys_kill>:

uint64
sys_kill(void)
{
    8000329c:	1101                	addi	sp,sp,-32
    8000329e:	ec06                	sd	ra,24(sp)
    800032a0:	e822                	sd	s0,16(sp)
    800032a2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800032a4:	fec40593          	addi	a1,s0,-20
    800032a8:	4501                	li	a0,0
    800032aa:	00000097          	auipc	ra,0x0
    800032ae:	d84080e7          	jalr	-636(ra) # 8000302e <argint>
    800032b2:	87aa                	mv	a5,a0
    return -1;
    800032b4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800032b6:	0007c863          	bltz	a5,800032c6 <sys_kill+0x2a>
  return kill(pid);
    800032ba:	fec42503          	lw	a0,-20(s0)
    800032be:	fffff097          	auipc	ra,0xfffff
    800032c2:	356080e7          	jalr	854(ra) # 80002614 <kill>
}
    800032c6:	60e2                	ld	ra,24(sp)
    800032c8:	6442                	ld	s0,16(sp)
    800032ca:	6105                	addi	sp,sp,32
    800032cc:	8082                	ret

00000000800032ce <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032ce:	1101                	addi	sp,sp,-32
    800032d0:	ec06                	sd	ra,24(sp)
    800032d2:	e822                	sd	s0,16(sp)
    800032d4:	e426                	sd	s1,8(sp)
    800032d6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032d8:	00014517          	auipc	a0,0x14
    800032dc:	74050513          	addi	a0,a0,1856 # 80017a18 <tickslock>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	904080e7          	jalr	-1788(ra) # 80000be4 <acquire>
  xticks = ticks;
    800032e8:	00006497          	auipc	s1,0x6
    800032ec:	d484a483          	lw	s1,-696(s1) # 80009030 <ticks>
  release(&tickslock);
    800032f0:	00014517          	auipc	a0,0x14
    800032f4:	72850513          	addi	a0,a0,1832 # 80017a18 <tickslock>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	9a0080e7          	jalr	-1632(ra) # 80000c98 <release>
  return xticks;
}
    80003300:	02049513          	slli	a0,s1,0x20
    80003304:	9101                	srli	a0,a0,0x20
    80003306:	60e2                	ld	ra,24(sp)
    80003308:	6442                	ld	s0,16(sp)
    8000330a:	64a2                	ld	s1,8(sp)
    8000330c:	6105                	addi	sp,sp,32
    8000330e:	8082                	ret

0000000080003310 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80003310:	1101                	addi	sp,sp,-32
    80003312:	ec06                	sd	ra,24(sp)
    80003314:	e822                	sd	s0,16(sp)
    80003316:	1000                	addi	s0,sp,32
    int cpu_num;
    if(argint(0, &cpu_num) <= -1){
    80003318:	fec40593          	addi	a1,s0,-20
    8000331c:	4501                	li	a0,0
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	d10080e7          	jalr	-752(ra) # 8000302e <argint>
    80003326:	87aa                	mv	a5,a0
      return -1;
    80003328:	557d                	li	a0,-1
    if(argint(0, &cpu_num) <= -1){
    8000332a:	0007c863          	bltz	a5,8000333a <sys_set_cpu+0x2a>
    }
    
    return set_cpu(cpu_num);
    8000332e:	fec42503          	lw	a0,-20(s0)
    80003332:	fffff097          	auipc	ra,0xfffff
    80003336:	cc0080e7          	jalr	-832(ra) # 80001ff2 <set_cpu>
}
    8000333a:	60e2                	ld	ra,24(sp)
    8000333c:	6442                	ld	s0,16(sp)
    8000333e:	6105                	addi	sp,sp,32
    80003340:	8082                	ret

0000000080003342 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003342:	1141                	addi	sp,sp,-16
    80003344:	e406                	sd	ra,8(sp)
    80003346:	e022                	sd	s0,0(sp)
    80003348:	0800                	addi	s0,sp,16
    return get_cpu();
    8000334a:	fffff097          	auipc	ra,0xfffff
    8000334e:	a26080e7          	jalr	-1498(ra) # 80001d70 <get_cpu>
    80003352:	60a2                	ld	ra,8(sp)
    80003354:	6402                	ld	s0,0(sp)
    80003356:	0141                	addi	sp,sp,16
    80003358:	8082                	ret

000000008000335a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000335a:	7179                	addi	sp,sp,-48
    8000335c:	f406                	sd	ra,40(sp)
    8000335e:	f022                	sd	s0,32(sp)
    80003360:	ec26                	sd	s1,24(sp)
    80003362:	e84a                	sd	s2,16(sp)
    80003364:	e44e                	sd	s3,8(sp)
    80003366:	e052                	sd	s4,0(sp)
    80003368:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000336a:	00005597          	auipc	a1,0x5
    8000336e:	1c658593          	addi	a1,a1,454 # 80008530 <syscalls+0xc0>
    80003372:	00014517          	auipc	a0,0x14
    80003376:	6be50513          	addi	a0,a0,1726 # 80017a30 <bcache>
    8000337a:	ffffd097          	auipc	ra,0xffffd
    8000337e:	7da080e7          	jalr	2010(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003382:	0001c797          	auipc	a5,0x1c
    80003386:	6ae78793          	addi	a5,a5,1710 # 8001fa30 <bcache+0x8000>
    8000338a:	0001d717          	auipc	a4,0x1d
    8000338e:	90e70713          	addi	a4,a4,-1778 # 8001fc98 <bcache+0x8268>
    80003392:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003396:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000339a:	00014497          	auipc	s1,0x14
    8000339e:	6ae48493          	addi	s1,s1,1710 # 80017a48 <bcache+0x18>
    b->next = bcache.head.next;
    800033a2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033a4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033a6:	00005a17          	auipc	s4,0x5
    800033aa:	192a0a13          	addi	s4,s4,402 # 80008538 <syscalls+0xc8>
    b->next = bcache.head.next;
    800033ae:	2b893783          	ld	a5,696(s2)
    800033b2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033b4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033b8:	85d2                	mv	a1,s4
    800033ba:	01048513          	addi	a0,s1,16
    800033be:	00001097          	auipc	ra,0x1
    800033c2:	4bc080e7          	jalr	1212(ra) # 8000487a <initsleeplock>
    bcache.head.next->prev = b;
    800033c6:	2b893783          	ld	a5,696(s2)
    800033ca:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033cc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033d0:	45848493          	addi	s1,s1,1112
    800033d4:	fd349de3          	bne	s1,s3,800033ae <binit+0x54>
  }
}
    800033d8:	70a2                	ld	ra,40(sp)
    800033da:	7402                	ld	s0,32(sp)
    800033dc:	64e2                	ld	s1,24(sp)
    800033de:	6942                	ld	s2,16(sp)
    800033e0:	69a2                	ld	s3,8(sp)
    800033e2:	6a02                	ld	s4,0(sp)
    800033e4:	6145                	addi	sp,sp,48
    800033e6:	8082                	ret

00000000800033e8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033e8:	7179                	addi	sp,sp,-48
    800033ea:	f406                	sd	ra,40(sp)
    800033ec:	f022                	sd	s0,32(sp)
    800033ee:	ec26                	sd	s1,24(sp)
    800033f0:	e84a                	sd	s2,16(sp)
    800033f2:	e44e                	sd	s3,8(sp)
    800033f4:	1800                	addi	s0,sp,48
    800033f6:	89aa                	mv	s3,a0
    800033f8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800033fa:	00014517          	auipc	a0,0x14
    800033fe:	63650513          	addi	a0,a0,1590 # 80017a30 <bcache>
    80003402:	ffffd097          	auipc	ra,0xffffd
    80003406:	7e2080e7          	jalr	2018(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000340a:	0001d497          	auipc	s1,0x1d
    8000340e:	8de4b483          	ld	s1,-1826(s1) # 8001fce8 <bcache+0x82b8>
    80003412:	0001d797          	auipc	a5,0x1d
    80003416:	88678793          	addi	a5,a5,-1914 # 8001fc98 <bcache+0x8268>
    8000341a:	02f48f63          	beq	s1,a5,80003458 <bread+0x70>
    8000341e:	873e                	mv	a4,a5
    80003420:	a021                	j	80003428 <bread+0x40>
    80003422:	68a4                	ld	s1,80(s1)
    80003424:	02e48a63          	beq	s1,a4,80003458 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003428:	449c                	lw	a5,8(s1)
    8000342a:	ff379ce3          	bne	a5,s3,80003422 <bread+0x3a>
    8000342e:	44dc                	lw	a5,12(s1)
    80003430:	ff2799e3          	bne	a5,s2,80003422 <bread+0x3a>
      b->refcnt++;
    80003434:	40bc                	lw	a5,64(s1)
    80003436:	2785                	addiw	a5,a5,1
    80003438:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000343a:	00014517          	auipc	a0,0x14
    8000343e:	5f650513          	addi	a0,a0,1526 # 80017a30 <bcache>
    80003442:	ffffe097          	auipc	ra,0xffffe
    80003446:	856080e7          	jalr	-1962(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000344a:	01048513          	addi	a0,s1,16
    8000344e:	00001097          	auipc	ra,0x1
    80003452:	466080e7          	jalr	1126(ra) # 800048b4 <acquiresleep>
      return b;
    80003456:	a8b9                	j	800034b4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003458:	0001d497          	auipc	s1,0x1d
    8000345c:	8884b483          	ld	s1,-1912(s1) # 8001fce0 <bcache+0x82b0>
    80003460:	0001d797          	auipc	a5,0x1d
    80003464:	83878793          	addi	a5,a5,-1992 # 8001fc98 <bcache+0x8268>
    80003468:	00f48863          	beq	s1,a5,80003478 <bread+0x90>
    8000346c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000346e:	40bc                	lw	a5,64(s1)
    80003470:	cf81                	beqz	a5,80003488 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003472:	64a4                	ld	s1,72(s1)
    80003474:	fee49de3          	bne	s1,a4,8000346e <bread+0x86>
  panic("bget: no buffers");
    80003478:	00005517          	auipc	a0,0x5
    8000347c:	0c850513          	addi	a0,a0,200 # 80008540 <syscalls+0xd0>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	0be080e7          	jalr	190(ra) # 8000053e <panic>
      b->dev = dev;
    80003488:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000348c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003490:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003494:	4785                	li	a5,1
    80003496:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003498:	00014517          	auipc	a0,0x14
    8000349c:	59850513          	addi	a0,a0,1432 # 80017a30 <bcache>
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034a8:	01048513          	addi	a0,s1,16
    800034ac:	00001097          	auipc	ra,0x1
    800034b0:	408080e7          	jalr	1032(ra) # 800048b4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034b4:	409c                	lw	a5,0(s1)
    800034b6:	cb89                	beqz	a5,800034c8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034b8:	8526                	mv	a0,s1
    800034ba:	70a2                	ld	ra,40(sp)
    800034bc:	7402                	ld	s0,32(sp)
    800034be:	64e2                	ld	s1,24(sp)
    800034c0:	6942                	ld	s2,16(sp)
    800034c2:	69a2                	ld	s3,8(sp)
    800034c4:	6145                	addi	sp,sp,48
    800034c6:	8082                	ret
    virtio_disk_rw(b, 0);
    800034c8:	4581                	li	a1,0
    800034ca:	8526                	mv	a0,s1
    800034cc:	00003097          	auipc	ra,0x3
    800034d0:	f0a080e7          	jalr	-246(ra) # 800063d6 <virtio_disk_rw>
    b->valid = 1;
    800034d4:	4785                	li	a5,1
    800034d6:	c09c                	sw	a5,0(s1)
  return b;
    800034d8:	b7c5                	j	800034b8 <bread+0xd0>

00000000800034da <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034da:	1101                	addi	sp,sp,-32
    800034dc:	ec06                	sd	ra,24(sp)
    800034de:	e822                	sd	s0,16(sp)
    800034e0:	e426                	sd	s1,8(sp)
    800034e2:	1000                	addi	s0,sp,32
    800034e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034e6:	0541                	addi	a0,a0,16
    800034e8:	00001097          	auipc	ra,0x1
    800034ec:	466080e7          	jalr	1126(ra) # 8000494e <holdingsleep>
    800034f0:	cd01                	beqz	a0,80003508 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034f2:	4585                	li	a1,1
    800034f4:	8526                	mv	a0,s1
    800034f6:	00003097          	auipc	ra,0x3
    800034fa:	ee0080e7          	jalr	-288(ra) # 800063d6 <virtio_disk_rw>
}
    800034fe:	60e2                	ld	ra,24(sp)
    80003500:	6442                	ld	s0,16(sp)
    80003502:	64a2                	ld	s1,8(sp)
    80003504:	6105                	addi	sp,sp,32
    80003506:	8082                	ret
    panic("bwrite");
    80003508:	00005517          	auipc	a0,0x5
    8000350c:	05050513          	addi	a0,a0,80 # 80008558 <syscalls+0xe8>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	02e080e7          	jalr	46(ra) # 8000053e <panic>

0000000080003518 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003518:	1101                	addi	sp,sp,-32
    8000351a:	ec06                	sd	ra,24(sp)
    8000351c:	e822                	sd	s0,16(sp)
    8000351e:	e426                	sd	s1,8(sp)
    80003520:	e04a                	sd	s2,0(sp)
    80003522:	1000                	addi	s0,sp,32
    80003524:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003526:	01050913          	addi	s2,a0,16
    8000352a:	854a                	mv	a0,s2
    8000352c:	00001097          	auipc	ra,0x1
    80003530:	422080e7          	jalr	1058(ra) # 8000494e <holdingsleep>
    80003534:	c92d                	beqz	a0,800035a6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003536:	854a                	mv	a0,s2
    80003538:	00001097          	auipc	ra,0x1
    8000353c:	3d2080e7          	jalr	978(ra) # 8000490a <releasesleep>

  acquire(&bcache.lock);
    80003540:	00014517          	auipc	a0,0x14
    80003544:	4f050513          	addi	a0,a0,1264 # 80017a30 <bcache>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	69c080e7          	jalr	1692(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003550:	40bc                	lw	a5,64(s1)
    80003552:	37fd                	addiw	a5,a5,-1
    80003554:	0007871b          	sext.w	a4,a5
    80003558:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000355a:	eb05                	bnez	a4,8000358a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000355c:	68bc                	ld	a5,80(s1)
    8000355e:	64b8                	ld	a4,72(s1)
    80003560:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003562:	64bc                	ld	a5,72(s1)
    80003564:	68b8                	ld	a4,80(s1)
    80003566:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003568:	0001c797          	auipc	a5,0x1c
    8000356c:	4c878793          	addi	a5,a5,1224 # 8001fa30 <bcache+0x8000>
    80003570:	2b87b703          	ld	a4,696(a5)
    80003574:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003576:	0001c717          	auipc	a4,0x1c
    8000357a:	72270713          	addi	a4,a4,1826 # 8001fc98 <bcache+0x8268>
    8000357e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003580:	2b87b703          	ld	a4,696(a5)
    80003584:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003586:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000358a:	00014517          	auipc	a0,0x14
    8000358e:	4a650513          	addi	a0,a0,1190 # 80017a30 <bcache>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	706080e7          	jalr	1798(ra) # 80000c98 <release>
}
    8000359a:	60e2                	ld	ra,24(sp)
    8000359c:	6442                	ld	s0,16(sp)
    8000359e:	64a2                	ld	s1,8(sp)
    800035a0:	6902                	ld	s2,0(sp)
    800035a2:	6105                	addi	sp,sp,32
    800035a4:	8082                	ret
    panic("brelse");
    800035a6:	00005517          	auipc	a0,0x5
    800035aa:	fba50513          	addi	a0,a0,-70 # 80008560 <syscalls+0xf0>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>

00000000800035b6 <bpin>:

void
bpin(struct buf *b) {
    800035b6:	1101                	addi	sp,sp,-32
    800035b8:	ec06                	sd	ra,24(sp)
    800035ba:	e822                	sd	s0,16(sp)
    800035bc:	e426                	sd	s1,8(sp)
    800035be:	1000                	addi	s0,sp,32
    800035c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035c2:	00014517          	auipc	a0,0x14
    800035c6:	46e50513          	addi	a0,a0,1134 # 80017a30 <bcache>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	61a080e7          	jalr	1562(ra) # 80000be4 <acquire>
  b->refcnt++;
    800035d2:	40bc                	lw	a5,64(s1)
    800035d4:	2785                	addiw	a5,a5,1
    800035d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035d8:	00014517          	auipc	a0,0x14
    800035dc:	45850513          	addi	a0,a0,1112 # 80017a30 <bcache>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	6b8080e7          	jalr	1720(ra) # 80000c98 <release>
}
    800035e8:	60e2                	ld	ra,24(sp)
    800035ea:	6442                	ld	s0,16(sp)
    800035ec:	64a2                	ld	s1,8(sp)
    800035ee:	6105                	addi	sp,sp,32
    800035f0:	8082                	ret

00000000800035f2 <bunpin>:

void
bunpin(struct buf *b) {
    800035f2:	1101                	addi	sp,sp,-32
    800035f4:	ec06                	sd	ra,24(sp)
    800035f6:	e822                	sd	s0,16(sp)
    800035f8:	e426                	sd	s1,8(sp)
    800035fa:	1000                	addi	s0,sp,32
    800035fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035fe:	00014517          	auipc	a0,0x14
    80003602:	43250513          	addi	a0,a0,1074 # 80017a30 <bcache>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	5de080e7          	jalr	1502(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000360e:	40bc                	lw	a5,64(s1)
    80003610:	37fd                	addiw	a5,a5,-1
    80003612:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003614:	00014517          	auipc	a0,0x14
    80003618:	41c50513          	addi	a0,a0,1052 # 80017a30 <bcache>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	67c080e7          	jalr	1660(ra) # 80000c98 <release>
}
    80003624:	60e2                	ld	ra,24(sp)
    80003626:	6442                	ld	s0,16(sp)
    80003628:	64a2                	ld	s1,8(sp)
    8000362a:	6105                	addi	sp,sp,32
    8000362c:	8082                	ret

000000008000362e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000362e:	1101                	addi	sp,sp,-32
    80003630:	ec06                	sd	ra,24(sp)
    80003632:	e822                	sd	s0,16(sp)
    80003634:	e426                	sd	s1,8(sp)
    80003636:	e04a                	sd	s2,0(sp)
    80003638:	1000                	addi	s0,sp,32
    8000363a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000363c:	00d5d59b          	srliw	a1,a1,0xd
    80003640:	0001d797          	auipc	a5,0x1d
    80003644:	acc7a783          	lw	a5,-1332(a5) # 8002010c <sb+0x1c>
    80003648:	9dbd                	addw	a1,a1,a5
    8000364a:	00000097          	auipc	ra,0x0
    8000364e:	d9e080e7          	jalr	-610(ra) # 800033e8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003652:	0074f713          	andi	a4,s1,7
    80003656:	4785                	li	a5,1
    80003658:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000365c:	14ce                	slli	s1,s1,0x33
    8000365e:	90d9                	srli	s1,s1,0x36
    80003660:	00950733          	add	a4,a0,s1
    80003664:	05874703          	lbu	a4,88(a4)
    80003668:	00e7f6b3          	and	a3,a5,a4
    8000366c:	c69d                	beqz	a3,8000369a <bfree+0x6c>
    8000366e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003670:	94aa                	add	s1,s1,a0
    80003672:	fff7c793          	not	a5,a5
    80003676:	8ff9                	and	a5,a5,a4
    80003678:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000367c:	00001097          	auipc	ra,0x1
    80003680:	118080e7          	jalr	280(ra) # 80004794 <log_write>
  brelse(bp);
    80003684:	854a                	mv	a0,s2
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	e92080e7          	jalr	-366(ra) # 80003518 <brelse>
}
    8000368e:	60e2                	ld	ra,24(sp)
    80003690:	6442                	ld	s0,16(sp)
    80003692:	64a2                	ld	s1,8(sp)
    80003694:	6902                	ld	s2,0(sp)
    80003696:	6105                	addi	sp,sp,32
    80003698:	8082                	ret
    panic("freeing free block");
    8000369a:	00005517          	auipc	a0,0x5
    8000369e:	ece50513          	addi	a0,a0,-306 # 80008568 <syscalls+0xf8>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	e9c080e7          	jalr	-356(ra) # 8000053e <panic>

00000000800036aa <balloc>:
{
    800036aa:	711d                	addi	sp,sp,-96
    800036ac:	ec86                	sd	ra,88(sp)
    800036ae:	e8a2                	sd	s0,80(sp)
    800036b0:	e4a6                	sd	s1,72(sp)
    800036b2:	e0ca                	sd	s2,64(sp)
    800036b4:	fc4e                	sd	s3,56(sp)
    800036b6:	f852                	sd	s4,48(sp)
    800036b8:	f456                	sd	s5,40(sp)
    800036ba:	f05a                	sd	s6,32(sp)
    800036bc:	ec5e                	sd	s7,24(sp)
    800036be:	e862                	sd	s8,16(sp)
    800036c0:	e466                	sd	s9,8(sp)
    800036c2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036c4:	0001d797          	auipc	a5,0x1d
    800036c8:	a307a783          	lw	a5,-1488(a5) # 800200f4 <sb+0x4>
    800036cc:	cbd1                	beqz	a5,80003760 <balloc+0xb6>
    800036ce:	8baa                	mv	s7,a0
    800036d0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036d2:	0001db17          	auipc	s6,0x1d
    800036d6:	a1eb0b13          	addi	s6,s6,-1506 # 800200f0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036da:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036dc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036de:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036e0:	6c89                	lui	s9,0x2
    800036e2:	a831                	j	800036fe <balloc+0x54>
    brelse(bp);
    800036e4:	854a                	mv	a0,s2
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	e32080e7          	jalr	-462(ra) # 80003518 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036ee:	015c87bb          	addw	a5,s9,s5
    800036f2:	00078a9b          	sext.w	s5,a5
    800036f6:	004b2703          	lw	a4,4(s6)
    800036fa:	06eaf363          	bgeu	s5,a4,80003760 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036fe:	41fad79b          	sraiw	a5,s5,0x1f
    80003702:	0137d79b          	srliw	a5,a5,0x13
    80003706:	015787bb          	addw	a5,a5,s5
    8000370a:	40d7d79b          	sraiw	a5,a5,0xd
    8000370e:	01cb2583          	lw	a1,28(s6)
    80003712:	9dbd                	addw	a1,a1,a5
    80003714:	855e                	mv	a0,s7
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	cd2080e7          	jalr	-814(ra) # 800033e8 <bread>
    8000371e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003720:	004b2503          	lw	a0,4(s6)
    80003724:	000a849b          	sext.w	s1,s5
    80003728:	8662                	mv	a2,s8
    8000372a:	faa4fde3          	bgeu	s1,a0,800036e4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000372e:	41f6579b          	sraiw	a5,a2,0x1f
    80003732:	01d7d69b          	srliw	a3,a5,0x1d
    80003736:	00c6873b          	addw	a4,a3,a2
    8000373a:	00777793          	andi	a5,a4,7
    8000373e:	9f95                	subw	a5,a5,a3
    80003740:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003744:	4037571b          	sraiw	a4,a4,0x3
    80003748:	00e906b3          	add	a3,s2,a4
    8000374c:	0586c683          	lbu	a3,88(a3)
    80003750:	00d7f5b3          	and	a1,a5,a3
    80003754:	cd91                	beqz	a1,80003770 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003756:	2605                	addiw	a2,a2,1
    80003758:	2485                	addiw	s1,s1,1
    8000375a:	fd4618e3          	bne	a2,s4,8000372a <balloc+0x80>
    8000375e:	b759                	j	800036e4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003760:	00005517          	auipc	a0,0x5
    80003764:	e2050513          	addi	a0,a0,-480 # 80008580 <syscalls+0x110>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	dd6080e7          	jalr	-554(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003770:	974a                	add	a4,a4,s2
    80003772:	8fd5                	or	a5,a5,a3
    80003774:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003778:	854a                	mv	a0,s2
    8000377a:	00001097          	auipc	ra,0x1
    8000377e:	01a080e7          	jalr	26(ra) # 80004794 <log_write>
        brelse(bp);
    80003782:	854a                	mv	a0,s2
    80003784:	00000097          	auipc	ra,0x0
    80003788:	d94080e7          	jalr	-620(ra) # 80003518 <brelse>
  bp = bread(dev, bno);
    8000378c:	85a6                	mv	a1,s1
    8000378e:	855e                	mv	a0,s7
    80003790:	00000097          	auipc	ra,0x0
    80003794:	c58080e7          	jalr	-936(ra) # 800033e8 <bread>
    80003798:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000379a:	40000613          	li	a2,1024
    8000379e:	4581                	li	a1,0
    800037a0:	05850513          	addi	a0,a0,88
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	53c080e7          	jalr	1340(ra) # 80000ce0 <memset>
  log_write(bp);
    800037ac:	854a                	mv	a0,s2
    800037ae:	00001097          	auipc	ra,0x1
    800037b2:	fe6080e7          	jalr	-26(ra) # 80004794 <log_write>
  brelse(bp);
    800037b6:	854a                	mv	a0,s2
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	d60080e7          	jalr	-672(ra) # 80003518 <brelse>
}
    800037c0:	8526                	mv	a0,s1
    800037c2:	60e6                	ld	ra,88(sp)
    800037c4:	6446                	ld	s0,80(sp)
    800037c6:	64a6                	ld	s1,72(sp)
    800037c8:	6906                	ld	s2,64(sp)
    800037ca:	79e2                	ld	s3,56(sp)
    800037cc:	7a42                	ld	s4,48(sp)
    800037ce:	7aa2                	ld	s5,40(sp)
    800037d0:	7b02                	ld	s6,32(sp)
    800037d2:	6be2                	ld	s7,24(sp)
    800037d4:	6c42                	ld	s8,16(sp)
    800037d6:	6ca2                	ld	s9,8(sp)
    800037d8:	6125                	addi	sp,sp,96
    800037da:	8082                	ret

00000000800037dc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800037dc:	7179                	addi	sp,sp,-48
    800037de:	f406                	sd	ra,40(sp)
    800037e0:	f022                	sd	s0,32(sp)
    800037e2:	ec26                	sd	s1,24(sp)
    800037e4:	e84a                	sd	s2,16(sp)
    800037e6:	e44e                	sd	s3,8(sp)
    800037e8:	e052                	sd	s4,0(sp)
    800037ea:	1800                	addi	s0,sp,48
    800037ec:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037ee:	47ad                	li	a5,11
    800037f0:	04b7fe63          	bgeu	a5,a1,8000384c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037f4:	ff45849b          	addiw	s1,a1,-12
    800037f8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037fc:	0ff00793          	li	a5,255
    80003800:	0ae7e363          	bltu	a5,a4,800038a6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003804:	08052583          	lw	a1,128(a0)
    80003808:	c5ad                	beqz	a1,80003872 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000380a:	00092503          	lw	a0,0(s2)
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	bda080e7          	jalr	-1062(ra) # 800033e8 <bread>
    80003816:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003818:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000381c:	02049593          	slli	a1,s1,0x20
    80003820:	9181                	srli	a1,a1,0x20
    80003822:	058a                	slli	a1,a1,0x2
    80003824:	00b784b3          	add	s1,a5,a1
    80003828:	0004a983          	lw	s3,0(s1)
    8000382c:	04098d63          	beqz	s3,80003886 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003830:	8552                	mv	a0,s4
    80003832:	00000097          	auipc	ra,0x0
    80003836:	ce6080e7          	jalr	-794(ra) # 80003518 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000383a:	854e                	mv	a0,s3
    8000383c:	70a2                	ld	ra,40(sp)
    8000383e:	7402                	ld	s0,32(sp)
    80003840:	64e2                	ld	s1,24(sp)
    80003842:	6942                	ld	s2,16(sp)
    80003844:	69a2                	ld	s3,8(sp)
    80003846:	6a02                	ld	s4,0(sp)
    80003848:	6145                	addi	sp,sp,48
    8000384a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000384c:	02059493          	slli	s1,a1,0x20
    80003850:	9081                	srli	s1,s1,0x20
    80003852:	048a                	slli	s1,s1,0x2
    80003854:	94aa                	add	s1,s1,a0
    80003856:	0504a983          	lw	s3,80(s1)
    8000385a:	fe0990e3          	bnez	s3,8000383a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000385e:	4108                	lw	a0,0(a0)
    80003860:	00000097          	auipc	ra,0x0
    80003864:	e4a080e7          	jalr	-438(ra) # 800036aa <balloc>
    80003868:	0005099b          	sext.w	s3,a0
    8000386c:	0534a823          	sw	s3,80(s1)
    80003870:	b7e9                	j	8000383a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003872:	4108                	lw	a0,0(a0)
    80003874:	00000097          	auipc	ra,0x0
    80003878:	e36080e7          	jalr	-458(ra) # 800036aa <balloc>
    8000387c:	0005059b          	sext.w	a1,a0
    80003880:	08b92023          	sw	a1,128(s2)
    80003884:	b759                	j	8000380a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003886:	00092503          	lw	a0,0(s2)
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	e20080e7          	jalr	-480(ra) # 800036aa <balloc>
    80003892:	0005099b          	sext.w	s3,a0
    80003896:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000389a:	8552                	mv	a0,s4
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	ef8080e7          	jalr	-264(ra) # 80004794 <log_write>
    800038a4:	b771                	j	80003830 <bmap+0x54>
  panic("bmap: out of range");
    800038a6:	00005517          	auipc	a0,0x5
    800038aa:	cf250513          	addi	a0,a0,-782 # 80008598 <syscalls+0x128>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	c90080e7          	jalr	-880(ra) # 8000053e <panic>

00000000800038b6 <iget>:
{
    800038b6:	7179                	addi	sp,sp,-48
    800038b8:	f406                	sd	ra,40(sp)
    800038ba:	f022                	sd	s0,32(sp)
    800038bc:	ec26                	sd	s1,24(sp)
    800038be:	e84a                	sd	s2,16(sp)
    800038c0:	e44e                	sd	s3,8(sp)
    800038c2:	e052                	sd	s4,0(sp)
    800038c4:	1800                	addi	s0,sp,48
    800038c6:	89aa                	mv	s3,a0
    800038c8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038ca:	0001d517          	auipc	a0,0x1d
    800038ce:	84650513          	addi	a0,a0,-1978 # 80020110 <itable>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	312080e7          	jalr	786(ra) # 80000be4 <acquire>
  empty = 0;
    800038da:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038dc:	0001d497          	auipc	s1,0x1d
    800038e0:	84c48493          	addi	s1,s1,-1972 # 80020128 <itable+0x18>
    800038e4:	0001e697          	auipc	a3,0x1e
    800038e8:	2d468693          	addi	a3,a3,724 # 80021bb8 <log>
    800038ec:	a039                	j	800038fa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038ee:	02090b63          	beqz	s2,80003924 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038f2:	08848493          	addi	s1,s1,136
    800038f6:	02d48a63          	beq	s1,a3,8000392a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038fa:	449c                	lw	a5,8(s1)
    800038fc:	fef059e3          	blez	a5,800038ee <iget+0x38>
    80003900:	4098                	lw	a4,0(s1)
    80003902:	ff3716e3          	bne	a4,s3,800038ee <iget+0x38>
    80003906:	40d8                	lw	a4,4(s1)
    80003908:	ff4713e3          	bne	a4,s4,800038ee <iget+0x38>
      ip->ref++;
    8000390c:	2785                	addiw	a5,a5,1
    8000390e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003910:	0001d517          	auipc	a0,0x1d
    80003914:	80050513          	addi	a0,a0,-2048 # 80020110 <itable>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	380080e7          	jalr	896(ra) # 80000c98 <release>
      return ip;
    80003920:	8926                	mv	s2,s1
    80003922:	a03d                	j	80003950 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003924:	f7f9                	bnez	a5,800038f2 <iget+0x3c>
    80003926:	8926                	mv	s2,s1
    80003928:	b7e9                	j	800038f2 <iget+0x3c>
  if(empty == 0)
    8000392a:	02090c63          	beqz	s2,80003962 <iget+0xac>
  ip->dev = dev;
    8000392e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003932:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003936:	4785                	li	a5,1
    80003938:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000393c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003940:	0001c517          	auipc	a0,0x1c
    80003944:	7d050513          	addi	a0,a0,2000 # 80020110 <itable>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	350080e7          	jalr	848(ra) # 80000c98 <release>
}
    80003950:	854a                	mv	a0,s2
    80003952:	70a2                	ld	ra,40(sp)
    80003954:	7402                	ld	s0,32(sp)
    80003956:	64e2                	ld	s1,24(sp)
    80003958:	6942                	ld	s2,16(sp)
    8000395a:	69a2                	ld	s3,8(sp)
    8000395c:	6a02                	ld	s4,0(sp)
    8000395e:	6145                	addi	sp,sp,48
    80003960:	8082                	ret
    panic("iget: no inodes");
    80003962:	00005517          	auipc	a0,0x5
    80003966:	c4e50513          	addi	a0,a0,-946 # 800085b0 <syscalls+0x140>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	bd4080e7          	jalr	-1068(ra) # 8000053e <panic>

0000000080003972 <fsinit>:
fsinit(int dev) {
    80003972:	7179                	addi	sp,sp,-48
    80003974:	f406                	sd	ra,40(sp)
    80003976:	f022                	sd	s0,32(sp)
    80003978:	ec26                	sd	s1,24(sp)
    8000397a:	e84a                	sd	s2,16(sp)
    8000397c:	e44e                	sd	s3,8(sp)
    8000397e:	1800                	addi	s0,sp,48
    80003980:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003982:	4585                	li	a1,1
    80003984:	00000097          	auipc	ra,0x0
    80003988:	a64080e7          	jalr	-1436(ra) # 800033e8 <bread>
    8000398c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000398e:	0001c997          	auipc	s3,0x1c
    80003992:	76298993          	addi	s3,s3,1890 # 800200f0 <sb>
    80003996:	02000613          	li	a2,32
    8000399a:	05850593          	addi	a1,a0,88
    8000399e:	854e                	mv	a0,s3
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	3a0080e7          	jalr	928(ra) # 80000d40 <memmove>
  brelse(bp);
    800039a8:	8526                	mv	a0,s1
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	b6e080e7          	jalr	-1170(ra) # 80003518 <brelse>
  if(sb.magic != FSMAGIC)
    800039b2:	0009a703          	lw	a4,0(s3)
    800039b6:	102037b7          	lui	a5,0x10203
    800039ba:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039be:	02f71263          	bne	a4,a5,800039e2 <fsinit+0x70>
  initlog(dev, &sb);
    800039c2:	0001c597          	auipc	a1,0x1c
    800039c6:	72e58593          	addi	a1,a1,1838 # 800200f0 <sb>
    800039ca:	854a                	mv	a0,s2
    800039cc:	00001097          	auipc	ra,0x1
    800039d0:	b4c080e7          	jalr	-1204(ra) # 80004518 <initlog>
}
    800039d4:	70a2                	ld	ra,40(sp)
    800039d6:	7402                	ld	s0,32(sp)
    800039d8:	64e2                	ld	s1,24(sp)
    800039da:	6942                	ld	s2,16(sp)
    800039dc:	69a2                	ld	s3,8(sp)
    800039de:	6145                	addi	sp,sp,48
    800039e0:	8082                	ret
    panic("invalid file system");
    800039e2:	00005517          	auipc	a0,0x5
    800039e6:	bde50513          	addi	a0,a0,-1058 # 800085c0 <syscalls+0x150>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	b54080e7          	jalr	-1196(ra) # 8000053e <panic>

00000000800039f2 <iinit>:
{
    800039f2:	7179                	addi	sp,sp,-48
    800039f4:	f406                	sd	ra,40(sp)
    800039f6:	f022                	sd	s0,32(sp)
    800039f8:	ec26                	sd	s1,24(sp)
    800039fa:	e84a                	sd	s2,16(sp)
    800039fc:	e44e                	sd	s3,8(sp)
    800039fe:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a00:	00005597          	auipc	a1,0x5
    80003a04:	bd858593          	addi	a1,a1,-1064 # 800085d8 <syscalls+0x168>
    80003a08:	0001c517          	auipc	a0,0x1c
    80003a0c:	70850513          	addi	a0,a0,1800 # 80020110 <itable>
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	144080e7          	jalr	324(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a18:	0001c497          	auipc	s1,0x1c
    80003a1c:	72048493          	addi	s1,s1,1824 # 80020138 <itable+0x28>
    80003a20:	0001e997          	auipc	s3,0x1e
    80003a24:	1a898993          	addi	s3,s3,424 # 80021bc8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a28:	00005917          	auipc	s2,0x5
    80003a2c:	bb890913          	addi	s2,s2,-1096 # 800085e0 <syscalls+0x170>
    80003a30:	85ca                	mv	a1,s2
    80003a32:	8526                	mv	a0,s1
    80003a34:	00001097          	auipc	ra,0x1
    80003a38:	e46080e7          	jalr	-442(ra) # 8000487a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a3c:	08848493          	addi	s1,s1,136
    80003a40:	ff3498e3          	bne	s1,s3,80003a30 <iinit+0x3e>
}
    80003a44:	70a2                	ld	ra,40(sp)
    80003a46:	7402                	ld	s0,32(sp)
    80003a48:	64e2                	ld	s1,24(sp)
    80003a4a:	6942                	ld	s2,16(sp)
    80003a4c:	69a2                	ld	s3,8(sp)
    80003a4e:	6145                	addi	sp,sp,48
    80003a50:	8082                	ret

0000000080003a52 <ialloc>:
{
    80003a52:	715d                	addi	sp,sp,-80
    80003a54:	e486                	sd	ra,72(sp)
    80003a56:	e0a2                	sd	s0,64(sp)
    80003a58:	fc26                	sd	s1,56(sp)
    80003a5a:	f84a                	sd	s2,48(sp)
    80003a5c:	f44e                	sd	s3,40(sp)
    80003a5e:	f052                	sd	s4,32(sp)
    80003a60:	ec56                	sd	s5,24(sp)
    80003a62:	e85a                	sd	s6,16(sp)
    80003a64:	e45e                	sd	s7,8(sp)
    80003a66:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a68:	0001c717          	auipc	a4,0x1c
    80003a6c:	69472703          	lw	a4,1684(a4) # 800200fc <sb+0xc>
    80003a70:	4785                	li	a5,1
    80003a72:	04e7fa63          	bgeu	a5,a4,80003ac6 <ialloc+0x74>
    80003a76:	8aaa                	mv	s5,a0
    80003a78:	8bae                	mv	s7,a1
    80003a7a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a7c:	0001ca17          	auipc	s4,0x1c
    80003a80:	674a0a13          	addi	s4,s4,1652 # 800200f0 <sb>
    80003a84:	00048b1b          	sext.w	s6,s1
    80003a88:	0044d593          	srli	a1,s1,0x4
    80003a8c:	018a2783          	lw	a5,24(s4)
    80003a90:	9dbd                	addw	a1,a1,a5
    80003a92:	8556                	mv	a0,s5
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	954080e7          	jalr	-1708(ra) # 800033e8 <bread>
    80003a9c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a9e:	05850993          	addi	s3,a0,88
    80003aa2:	00f4f793          	andi	a5,s1,15
    80003aa6:	079a                	slli	a5,a5,0x6
    80003aa8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003aaa:	00099783          	lh	a5,0(s3)
    80003aae:	c785                	beqz	a5,80003ad6 <ialloc+0x84>
    brelse(bp);
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	a68080e7          	jalr	-1432(ra) # 80003518 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ab8:	0485                	addi	s1,s1,1
    80003aba:	00ca2703          	lw	a4,12(s4)
    80003abe:	0004879b          	sext.w	a5,s1
    80003ac2:	fce7e1e3          	bltu	a5,a4,80003a84 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ac6:	00005517          	auipc	a0,0x5
    80003aca:	b2250513          	addi	a0,a0,-1246 # 800085e8 <syscalls+0x178>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	a70080e7          	jalr	-1424(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003ad6:	04000613          	li	a2,64
    80003ada:	4581                	li	a1,0
    80003adc:	854e                	mv	a0,s3
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	202080e7          	jalr	514(ra) # 80000ce0 <memset>
      dip->type = type;
    80003ae6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003aea:	854a                	mv	a0,s2
    80003aec:	00001097          	auipc	ra,0x1
    80003af0:	ca8080e7          	jalr	-856(ra) # 80004794 <log_write>
      brelse(bp);
    80003af4:	854a                	mv	a0,s2
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	a22080e7          	jalr	-1502(ra) # 80003518 <brelse>
      return iget(dev, inum);
    80003afe:	85da                	mv	a1,s6
    80003b00:	8556                	mv	a0,s5
    80003b02:	00000097          	auipc	ra,0x0
    80003b06:	db4080e7          	jalr	-588(ra) # 800038b6 <iget>
}
    80003b0a:	60a6                	ld	ra,72(sp)
    80003b0c:	6406                	ld	s0,64(sp)
    80003b0e:	74e2                	ld	s1,56(sp)
    80003b10:	7942                	ld	s2,48(sp)
    80003b12:	79a2                	ld	s3,40(sp)
    80003b14:	7a02                	ld	s4,32(sp)
    80003b16:	6ae2                	ld	s5,24(sp)
    80003b18:	6b42                	ld	s6,16(sp)
    80003b1a:	6ba2                	ld	s7,8(sp)
    80003b1c:	6161                	addi	sp,sp,80
    80003b1e:	8082                	ret

0000000080003b20 <iupdate>:
{
    80003b20:	1101                	addi	sp,sp,-32
    80003b22:	ec06                	sd	ra,24(sp)
    80003b24:	e822                	sd	s0,16(sp)
    80003b26:	e426                	sd	s1,8(sp)
    80003b28:	e04a                	sd	s2,0(sp)
    80003b2a:	1000                	addi	s0,sp,32
    80003b2c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b2e:	415c                	lw	a5,4(a0)
    80003b30:	0047d79b          	srliw	a5,a5,0x4
    80003b34:	0001c597          	auipc	a1,0x1c
    80003b38:	5d45a583          	lw	a1,1492(a1) # 80020108 <sb+0x18>
    80003b3c:	9dbd                	addw	a1,a1,a5
    80003b3e:	4108                	lw	a0,0(a0)
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	8a8080e7          	jalr	-1880(ra) # 800033e8 <bread>
    80003b48:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b4a:	05850793          	addi	a5,a0,88
    80003b4e:	40c8                	lw	a0,4(s1)
    80003b50:	893d                	andi	a0,a0,15
    80003b52:	051a                	slli	a0,a0,0x6
    80003b54:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b56:	04449703          	lh	a4,68(s1)
    80003b5a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b5e:	04649703          	lh	a4,70(s1)
    80003b62:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b66:	04849703          	lh	a4,72(s1)
    80003b6a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b6e:	04a49703          	lh	a4,74(s1)
    80003b72:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b76:	44f8                	lw	a4,76(s1)
    80003b78:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b7a:	03400613          	li	a2,52
    80003b7e:	05048593          	addi	a1,s1,80
    80003b82:	0531                	addi	a0,a0,12
    80003b84:	ffffd097          	auipc	ra,0xffffd
    80003b88:	1bc080e7          	jalr	444(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b8c:	854a                	mv	a0,s2
    80003b8e:	00001097          	auipc	ra,0x1
    80003b92:	c06080e7          	jalr	-1018(ra) # 80004794 <log_write>
  brelse(bp);
    80003b96:	854a                	mv	a0,s2
    80003b98:	00000097          	auipc	ra,0x0
    80003b9c:	980080e7          	jalr	-1664(ra) # 80003518 <brelse>
}
    80003ba0:	60e2                	ld	ra,24(sp)
    80003ba2:	6442                	ld	s0,16(sp)
    80003ba4:	64a2                	ld	s1,8(sp)
    80003ba6:	6902                	ld	s2,0(sp)
    80003ba8:	6105                	addi	sp,sp,32
    80003baa:	8082                	ret

0000000080003bac <idup>:
{
    80003bac:	1101                	addi	sp,sp,-32
    80003bae:	ec06                	sd	ra,24(sp)
    80003bb0:	e822                	sd	s0,16(sp)
    80003bb2:	e426                	sd	s1,8(sp)
    80003bb4:	1000                	addi	s0,sp,32
    80003bb6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bb8:	0001c517          	auipc	a0,0x1c
    80003bbc:	55850513          	addi	a0,a0,1368 # 80020110 <itable>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	024080e7          	jalr	36(ra) # 80000be4 <acquire>
  ip->ref++;
    80003bc8:	449c                	lw	a5,8(s1)
    80003bca:	2785                	addiw	a5,a5,1
    80003bcc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bce:	0001c517          	auipc	a0,0x1c
    80003bd2:	54250513          	addi	a0,a0,1346 # 80020110 <itable>
    80003bd6:	ffffd097          	auipc	ra,0xffffd
    80003bda:	0c2080e7          	jalr	194(ra) # 80000c98 <release>
}
    80003bde:	8526                	mv	a0,s1
    80003be0:	60e2                	ld	ra,24(sp)
    80003be2:	6442                	ld	s0,16(sp)
    80003be4:	64a2                	ld	s1,8(sp)
    80003be6:	6105                	addi	sp,sp,32
    80003be8:	8082                	ret

0000000080003bea <ilock>:
{
    80003bea:	1101                	addi	sp,sp,-32
    80003bec:	ec06                	sd	ra,24(sp)
    80003bee:	e822                	sd	s0,16(sp)
    80003bf0:	e426                	sd	s1,8(sp)
    80003bf2:	e04a                	sd	s2,0(sp)
    80003bf4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bf6:	c115                	beqz	a0,80003c1a <ilock+0x30>
    80003bf8:	84aa                	mv	s1,a0
    80003bfa:	451c                	lw	a5,8(a0)
    80003bfc:	00f05f63          	blez	a5,80003c1a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c00:	0541                	addi	a0,a0,16
    80003c02:	00001097          	auipc	ra,0x1
    80003c06:	cb2080e7          	jalr	-846(ra) # 800048b4 <acquiresleep>
  if(ip->valid == 0){
    80003c0a:	40bc                	lw	a5,64(s1)
    80003c0c:	cf99                	beqz	a5,80003c2a <ilock+0x40>
}
    80003c0e:	60e2                	ld	ra,24(sp)
    80003c10:	6442                	ld	s0,16(sp)
    80003c12:	64a2                	ld	s1,8(sp)
    80003c14:	6902                	ld	s2,0(sp)
    80003c16:	6105                	addi	sp,sp,32
    80003c18:	8082                	ret
    panic("ilock");
    80003c1a:	00005517          	auipc	a0,0x5
    80003c1e:	9e650513          	addi	a0,a0,-1562 # 80008600 <syscalls+0x190>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c2a:	40dc                	lw	a5,4(s1)
    80003c2c:	0047d79b          	srliw	a5,a5,0x4
    80003c30:	0001c597          	auipc	a1,0x1c
    80003c34:	4d85a583          	lw	a1,1240(a1) # 80020108 <sb+0x18>
    80003c38:	9dbd                	addw	a1,a1,a5
    80003c3a:	4088                	lw	a0,0(s1)
    80003c3c:	fffff097          	auipc	ra,0xfffff
    80003c40:	7ac080e7          	jalr	1964(ra) # 800033e8 <bread>
    80003c44:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c46:	05850593          	addi	a1,a0,88
    80003c4a:	40dc                	lw	a5,4(s1)
    80003c4c:	8bbd                	andi	a5,a5,15
    80003c4e:	079a                	slli	a5,a5,0x6
    80003c50:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c52:	00059783          	lh	a5,0(a1)
    80003c56:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c5a:	00259783          	lh	a5,2(a1)
    80003c5e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c62:	00459783          	lh	a5,4(a1)
    80003c66:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c6a:	00659783          	lh	a5,6(a1)
    80003c6e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c72:	459c                	lw	a5,8(a1)
    80003c74:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c76:	03400613          	li	a2,52
    80003c7a:	05b1                	addi	a1,a1,12
    80003c7c:	05048513          	addi	a0,s1,80
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	0c0080e7          	jalr	192(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c88:	854a                	mv	a0,s2
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	88e080e7          	jalr	-1906(ra) # 80003518 <brelse>
    ip->valid = 1;
    80003c92:	4785                	li	a5,1
    80003c94:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c96:	04449783          	lh	a5,68(s1)
    80003c9a:	fbb5                	bnez	a5,80003c0e <ilock+0x24>
      panic("ilock: no type");
    80003c9c:	00005517          	auipc	a0,0x5
    80003ca0:	96c50513          	addi	a0,a0,-1684 # 80008608 <syscalls+0x198>
    80003ca4:	ffffd097          	auipc	ra,0xffffd
    80003ca8:	89a080e7          	jalr	-1894(ra) # 8000053e <panic>

0000000080003cac <iunlock>:
{
    80003cac:	1101                	addi	sp,sp,-32
    80003cae:	ec06                	sd	ra,24(sp)
    80003cb0:	e822                	sd	s0,16(sp)
    80003cb2:	e426                	sd	s1,8(sp)
    80003cb4:	e04a                	sd	s2,0(sp)
    80003cb6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cb8:	c905                	beqz	a0,80003ce8 <iunlock+0x3c>
    80003cba:	84aa                	mv	s1,a0
    80003cbc:	01050913          	addi	s2,a0,16
    80003cc0:	854a                	mv	a0,s2
    80003cc2:	00001097          	auipc	ra,0x1
    80003cc6:	c8c080e7          	jalr	-884(ra) # 8000494e <holdingsleep>
    80003cca:	cd19                	beqz	a0,80003ce8 <iunlock+0x3c>
    80003ccc:	449c                	lw	a5,8(s1)
    80003cce:	00f05d63          	blez	a5,80003ce8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cd2:	854a                	mv	a0,s2
    80003cd4:	00001097          	auipc	ra,0x1
    80003cd8:	c36080e7          	jalr	-970(ra) # 8000490a <releasesleep>
}
    80003cdc:	60e2                	ld	ra,24(sp)
    80003cde:	6442                	ld	s0,16(sp)
    80003ce0:	64a2                	ld	s1,8(sp)
    80003ce2:	6902                	ld	s2,0(sp)
    80003ce4:	6105                	addi	sp,sp,32
    80003ce6:	8082                	ret
    panic("iunlock");
    80003ce8:	00005517          	auipc	a0,0x5
    80003cec:	93050513          	addi	a0,a0,-1744 # 80008618 <syscalls+0x1a8>
    80003cf0:	ffffd097          	auipc	ra,0xffffd
    80003cf4:	84e080e7          	jalr	-1970(ra) # 8000053e <panic>

0000000080003cf8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cf8:	7179                	addi	sp,sp,-48
    80003cfa:	f406                	sd	ra,40(sp)
    80003cfc:	f022                	sd	s0,32(sp)
    80003cfe:	ec26                	sd	s1,24(sp)
    80003d00:	e84a                	sd	s2,16(sp)
    80003d02:	e44e                	sd	s3,8(sp)
    80003d04:	e052                	sd	s4,0(sp)
    80003d06:	1800                	addi	s0,sp,48
    80003d08:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d0a:	05050493          	addi	s1,a0,80
    80003d0e:	08050913          	addi	s2,a0,128
    80003d12:	a021                	j	80003d1a <itrunc+0x22>
    80003d14:	0491                	addi	s1,s1,4
    80003d16:	01248d63          	beq	s1,s2,80003d30 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d1a:	408c                	lw	a1,0(s1)
    80003d1c:	dde5                	beqz	a1,80003d14 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d1e:	0009a503          	lw	a0,0(s3)
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	90c080e7          	jalr	-1780(ra) # 8000362e <bfree>
      ip->addrs[i] = 0;
    80003d2a:	0004a023          	sw	zero,0(s1)
    80003d2e:	b7dd                	j	80003d14 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d30:	0809a583          	lw	a1,128(s3)
    80003d34:	e185                	bnez	a1,80003d54 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d36:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d3a:	854e                	mv	a0,s3
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	de4080e7          	jalr	-540(ra) # 80003b20 <iupdate>
}
    80003d44:	70a2                	ld	ra,40(sp)
    80003d46:	7402                	ld	s0,32(sp)
    80003d48:	64e2                	ld	s1,24(sp)
    80003d4a:	6942                	ld	s2,16(sp)
    80003d4c:	69a2                	ld	s3,8(sp)
    80003d4e:	6a02                	ld	s4,0(sp)
    80003d50:	6145                	addi	sp,sp,48
    80003d52:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d54:	0009a503          	lw	a0,0(s3)
    80003d58:	fffff097          	auipc	ra,0xfffff
    80003d5c:	690080e7          	jalr	1680(ra) # 800033e8 <bread>
    80003d60:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d62:	05850493          	addi	s1,a0,88
    80003d66:	45850913          	addi	s2,a0,1112
    80003d6a:	a811                	j	80003d7e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d6c:	0009a503          	lw	a0,0(s3)
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	8be080e7          	jalr	-1858(ra) # 8000362e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d78:	0491                	addi	s1,s1,4
    80003d7a:	01248563          	beq	s1,s2,80003d84 <itrunc+0x8c>
      if(a[j])
    80003d7e:	408c                	lw	a1,0(s1)
    80003d80:	dde5                	beqz	a1,80003d78 <itrunc+0x80>
    80003d82:	b7ed                	j	80003d6c <itrunc+0x74>
    brelse(bp);
    80003d84:	8552                	mv	a0,s4
    80003d86:	fffff097          	auipc	ra,0xfffff
    80003d8a:	792080e7          	jalr	1938(ra) # 80003518 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d8e:	0809a583          	lw	a1,128(s3)
    80003d92:	0009a503          	lw	a0,0(s3)
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	898080e7          	jalr	-1896(ra) # 8000362e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d9e:	0809a023          	sw	zero,128(s3)
    80003da2:	bf51                	j	80003d36 <itrunc+0x3e>

0000000080003da4 <iput>:
{
    80003da4:	1101                	addi	sp,sp,-32
    80003da6:	ec06                	sd	ra,24(sp)
    80003da8:	e822                	sd	s0,16(sp)
    80003daa:	e426                	sd	s1,8(sp)
    80003dac:	e04a                	sd	s2,0(sp)
    80003dae:	1000                	addi	s0,sp,32
    80003db0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003db2:	0001c517          	auipc	a0,0x1c
    80003db6:	35e50513          	addi	a0,a0,862 # 80020110 <itable>
    80003dba:	ffffd097          	auipc	ra,0xffffd
    80003dbe:	e2a080e7          	jalr	-470(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dc2:	4498                	lw	a4,8(s1)
    80003dc4:	4785                	li	a5,1
    80003dc6:	02f70363          	beq	a4,a5,80003dec <iput+0x48>
  ip->ref--;
    80003dca:	449c                	lw	a5,8(s1)
    80003dcc:	37fd                	addiw	a5,a5,-1
    80003dce:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dd0:	0001c517          	auipc	a0,0x1c
    80003dd4:	34050513          	addi	a0,a0,832 # 80020110 <itable>
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	ec0080e7          	jalr	-320(ra) # 80000c98 <release>
}
    80003de0:	60e2                	ld	ra,24(sp)
    80003de2:	6442                	ld	s0,16(sp)
    80003de4:	64a2                	ld	s1,8(sp)
    80003de6:	6902                	ld	s2,0(sp)
    80003de8:	6105                	addi	sp,sp,32
    80003dea:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dec:	40bc                	lw	a5,64(s1)
    80003dee:	dff1                	beqz	a5,80003dca <iput+0x26>
    80003df0:	04a49783          	lh	a5,74(s1)
    80003df4:	fbf9                	bnez	a5,80003dca <iput+0x26>
    acquiresleep(&ip->lock);
    80003df6:	01048913          	addi	s2,s1,16
    80003dfa:	854a                	mv	a0,s2
    80003dfc:	00001097          	auipc	ra,0x1
    80003e00:	ab8080e7          	jalr	-1352(ra) # 800048b4 <acquiresleep>
    release(&itable.lock);
    80003e04:	0001c517          	auipc	a0,0x1c
    80003e08:	30c50513          	addi	a0,a0,780 # 80020110 <itable>
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	e8c080e7          	jalr	-372(ra) # 80000c98 <release>
    itrunc(ip);
    80003e14:	8526                	mv	a0,s1
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	ee2080e7          	jalr	-286(ra) # 80003cf8 <itrunc>
    ip->type = 0;
    80003e1e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e22:	8526                	mv	a0,s1
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	cfc080e7          	jalr	-772(ra) # 80003b20 <iupdate>
    ip->valid = 0;
    80003e2c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e30:	854a                	mv	a0,s2
    80003e32:	00001097          	auipc	ra,0x1
    80003e36:	ad8080e7          	jalr	-1320(ra) # 8000490a <releasesleep>
    acquire(&itable.lock);
    80003e3a:	0001c517          	auipc	a0,0x1c
    80003e3e:	2d650513          	addi	a0,a0,726 # 80020110 <itable>
    80003e42:	ffffd097          	auipc	ra,0xffffd
    80003e46:	da2080e7          	jalr	-606(ra) # 80000be4 <acquire>
    80003e4a:	b741                	j	80003dca <iput+0x26>

0000000080003e4c <iunlockput>:
{
    80003e4c:	1101                	addi	sp,sp,-32
    80003e4e:	ec06                	sd	ra,24(sp)
    80003e50:	e822                	sd	s0,16(sp)
    80003e52:	e426                	sd	s1,8(sp)
    80003e54:	1000                	addi	s0,sp,32
    80003e56:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	e54080e7          	jalr	-428(ra) # 80003cac <iunlock>
  iput(ip);
    80003e60:	8526                	mv	a0,s1
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	f42080e7          	jalr	-190(ra) # 80003da4 <iput>
}
    80003e6a:	60e2                	ld	ra,24(sp)
    80003e6c:	6442                	ld	s0,16(sp)
    80003e6e:	64a2                	ld	s1,8(sp)
    80003e70:	6105                	addi	sp,sp,32
    80003e72:	8082                	ret

0000000080003e74 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e74:	1141                	addi	sp,sp,-16
    80003e76:	e422                	sd	s0,8(sp)
    80003e78:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e7a:	411c                	lw	a5,0(a0)
    80003e7c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e7e:	415c                	lw	a5,4(a0)
    80003e80:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e82:	04451783          	lh	a5,68(a0)
    80003e86:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e8a:	04a51783          	lh	a5,74(a0)
    80003e8e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e92:	04c56783          	lwu	a5,76(a0)
    80003e96:	e99c                	sd	a5,16(a1)
}
    80003e98:	6422                	ld	s0,8(sp)
    80003e9a:	0141                	addi	sp,sp,16
    80003e9c:	8082                	ret

0000000080003e9e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e9e:	457c                	lw	a5,76(a0)
    80003ea0:	0ed7e963          	bltu	a5,a3,80003f92 <readi+0xf4>
{
    80003ea4:	7159                	addi	sp,sp,-112
    80003ea6:	f486                	sd	ra,104(sp)
    80003ea8:	f0a2                	sd	s0,96(sp)
    80003eaa:	eca6                	sd	s1,88(sp)
    80003eac:	e8ca                	sd	s2,80(sp)
    80003eae:	e4ce                	sd	s3,72(sp)
    80003eb0:	e0d2                	sd	s4,64(sp)
    80003eb2:	fc56                	sd	s5,56(sp)
    80003eb4:	f85a                	sd	s6,48(sp)
    80003eb6:	f45e                	sd	s7,40(sp)
    80003eb8:	f062                	sd	s8,32(sp)
    80003eba:	ec66                	sd	s9,24(sp)
    80003ebc:	e86a                	sd	s10,16(sp)
    80003ebe:	e46e                	sd	s11,8(sp)
    80003ec0:	1880                	addi	s0,sp,112
    80003ec2:	8baa                	mv	s7,a0
    80003ec4:	8c2e                	mv	s8,a1
    80003ec6:	8ab2                	mv	s5,a2
    80003ec8:	84b6                	mv	s1,a3
    80003eca:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ecc:	9f35                	addw	a4,a4,a3
    return 0;
    80003ece:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ed0:	0ad76063          	bltu	a4,a3,80003f70 <readi+0xd2>
  if(off + n > ip->size)
    80003ed4:	00e7f463          	bgeu	a5,a4,80003edc <readi+0x3e>
    n = ip->size - off;
    80003ed8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003edc:	0a0b0963          	beqz	s6,80003f8e <readi+0xf0>
    80003ee0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ee2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ee6:	5cfd                	li	s9,-1
    80003ee8:	a82d                	j	80003f22 <readi+0x84>
    80003eea:	020a1d93          	slli	s11,s4,0x20
    80003eee:	020ddd93          	srli	s11,s11,0x20
    80003ef2:	05890613          	addi	a2,s2,88
    80003ef6:	86ee                	mv	a3,s11
    80003ef8:	963a                	add	a2,a2,a4
    80003efa:	85d6                	mv	a1,s5
    80003efc:	8562                	mv	a0,s8
    80003efe:	ffffe097          	auipc	ra,0xffffe
    80003f02:	d18080e7          	jalr	-744(ra) # 80001c16 <either_copyout>
    80003f06:	05950d63          	beq	a0,s9,80003f60 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f0a:	854a                	mv	a0,s2
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	60c080e7          	jalr	1548(ra) # 80003518 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f14:	013a09bb          	addw	s3,s4,s3
    80003f18:	009a04bb          	addw	s1,s4,s1
    80003f1c:	9aee                	add	s5,s5,s11
    80003f1e:	0569f763          	bgeu	s3,s6,80003f6c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f22:	000ba903          	lw	s2,0(s7)
    80003f26:	00a4d59b          	srliw	a1,s1,0xa
    80003f2a:	855e                	mv	a0,s7
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	8b0080e7          	jalr	-1872(ra) # 800037dc <bmap>
    80003f34:	0005059b          	sext.w	a1,a0
    80003f38:	854a                	mv	a0,s2
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	4ae080e7          	jalr	1198(ra) # 800033e8 <bread>
    80003f42:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f44:	3ff4f713          	andi	a4,s1,1023
    80003f48:	40ed07bb          	subw	a5,s10,a4
    80003f4c:	413b06bb          	subw	a3,s6,s3
    80003f50:	8a3e                	mv	s4,a5
    80003f52:	2781                	sext.w	a5,a5
    80003f54:	0006861b          	sext.w	a2,a3
    80003f58:	f8f679e3          	bgeu	a2,a5,80003eea <readi+0x4c>
    80003f5c:	8a36                	mv	s4,a3
    80003f5e:	b771                	j	80003eea <readi+0x4c>
      brelse(bp);
    80003f60:	854a                	mv	a0,s2
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	5b6080e7          	jalr	1462(ra) # 80003518 <brelse>
      tot = -1;
    80003f6a:	59fd                	li	s3,-1
  }
  return tot;
    80003f6c:	0009851b          	sext.w	a0,s3
}
    80003f70:	70a6                	ld	ra,104(sp)
    80003f72:	7406                	ld	s0,96(sp)
    80003f74:	64e6                	ld	s1,88(sp)
    80003f76:	6946                	ld	s2,80(sp)
    80003f78:	69a6                	ld	s3,72(sp)
    80003f7a:	6a06                	ld	s4,64(sp)
    80003f7c:	7ae2                	ld	s5,56(sp)
    80003f7e:	7b42                	ld	s6,48(sp)
    80003f80:	7ba2                	ld	s7,40(sp)
    80003f82:	7c02                	ld	s8,32(sp)
    80003f84:	6ce2                	ld	s9,24(sp)
    80003f86:	6d42                	ld	s10,16(sp)
    80003f88:	6da2                	ld	s11,8(sp)
    80003f8a:	6165                	addi	sp,sp,112
    80003f8c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f8e:	89da                	mv	s3,s6
    80003f90:	bff1                	j	80003f6c <readi+0xce>
    return 0;
    80003f92:	4501                	li	a0,0
}
    80003f94:	8082                	ret

0000000080003f96 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f96:	457c                	lw	a5,76(a0)
    80003f98:	10d7e863          	bltu	a5,a3,800040a8 <writei+0x112>
{
    80003f9c:	7159                	addi	sp,sp,-112
    80003f9e:	f486                	sd	ra,104(sp)
    80003fa0:	f0a2                	sd	s0,96(sp)
    80003fa2:	eca6                	sd	s1,88(sp)
    80003fa4:	e8ca                	sd	s2,80(sp)
    80003fa6:	e4ce                	sd	s3,72(sp)
    80003fa8:	e0d2                	sd	s4,64(sp)
    80003faa:	fc56                	sd	s5,56(sp)
    80003fac:	f85a                	sd	s6,48(sp)
    80003fae:	f45e                	sd	s7,40(sp)
    80003fb0:	f062                	sd	s8,32(sp)
    80003fb2:	ec66                	sd	s9,24(sp)
    80003fb4:	e86a                	sd	s10,16(sp)
    80003fb6:	e46e                	sd	s11,8(sp)
    80003fb8:	1880                	addi	s0,sp,112
    80003fba:	8b2a                	mv	s6,a0
    80003fbc:	8c2e                	mv	s8,a1
    80003fbe:	8ab2                	mv	s5,a2
    80003fc0:	8936                	mv	s2,a3
    80003fc2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003fc4:	00e687bb          	addw	a5,a3,a4
    80003fc8:	0ed7e263          	bltu	a5,a3,800040ac <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fcc:	00043737          	lui	a4,0x43
    80003fd0:	0ef76063          	bltu	a4,a5,800040b0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fd4:	0c0b8863          	beqz	s7,800040a4 <writei+0x10e>
    80003fd8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fda:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fde:	5cfd                	li	s9,-1
    80003fe0:	a091                	j	80004024 <writei+0x8e>
    80003fe2:	02099d93          	slli	s11,s3,0x20
    80003fe6:	020ddd93          	srli	s11,s11,0x20
    80003fea:	05848513          	addi	a0,s1,88
    80003fee:	86ee                	mv	a3,s11
    80003ff0:	8656                	mv	a2,s5
    80003ff2:	85e2                	mv	a1,s8
    80003ff4:	953a                	add	a0,a0,a4
    80003ff6:	ffffe097          	auipc	ra,0xffffe
    80003ffa:	c76080e7          	jalr	-906(ra) # 80001c6c <either_copyin>
    80003ffe:	07950263          	beq	a0,s9,80004062 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004002:	8526                	mv	a0,s1
    80004004:	00000097          	auipc	ra,0x0
    80004008:	790080e7          	jalr	1936(ra) # 80004794 <log_write>
    brelse(bp);
    8000400c:	8526                	mv	a0,s1
    8000400e:	fffff097          	auipc	ra,0xfffff
    80004012:	50a080e7          	jalr	1290(ra) # 80003518 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004016:	01498a3b          	addw	s4,s3,s4
    8000401a:	0129893b          	addw	s2,s3,s2
    8000401e:	9aee                	add	s5,s5,s11
    80004020:	057a7663          	bgeu	s4,s7,8000406c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004024:	000b2483          	lw	s1,0(s6)
    80004028:	00a9559b          	srliw	a1,s2,0xa
    8000402c:	855a                	mv	a0,s6
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	7ae080e7          	jalr	1966(ra) # 800037dc <bmap>
    80004036:	0005059b          	sext.w	a1,a0
    8000403a:	8526                	mv	a0,s1
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	3ac080e7          	jalr	940(ra) # 800033e8 <bread>
    80004044:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004046:	3ff97713          	andi	a4,s2,1023
    8000404a:	40ed07bb          	subw	a5,s10,a4
    8000404e:	414b86bb          	subw	a3,s7,s4
    80004052:	89be                	mv	s3,a5
    80004054:	2781                	sext.w	a5,a5
    80004056:	0006861b          	sext.w	a2,a3
    8000405a:	f8f674e3          	bgeu	a2,a5,80003fe2 <writei+0x4c>
    8000405e:	89b6                	mv	s3,a3
    80004060:	b749                	j	80003fe2 <writei+0x4c>
      brelse(bp);
    80004062:	8526                	mv	a0,s1
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	4b4080e7          	jalr	1204(ra) # 80003518 <brelse>
  }

  if(off > ip->size)
    8000406c:	04cb2783          	lw	a5,76(s6)
    80004070:	0127f463          	bgeu	a5,s2,80004078 <writei+0xe2>
    ip->size = off;
    80004074:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004078:	855a                	mv	a0,s6
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	aa6080e7          	jalr	-1370(ra) # 80003b20 <iupdate>

  return tot;
    80004082:	000a051b          	sext.w	a0,s4
}
    80004086:	70a6                	ld	ra,104(sp)
    80004088:	7406                	ld	s0,96(sp)
    8000408a:	64e6                	ld	s1,88(sp)
    8000408c:	6946                	ld	s2,80(sp)
    8000408e:	69a6                	ld	s3,72(sp)
    80004090:	6a06                	ld	s4,64(sp)
    80004092:	7ae2                	ld	s5,56(sp)
    80004094:	7b42                	ld	s6,48(sp)
    80004096:	7ba2                	ld	s7,40(sp)
    80004098:	7c02                	ld	s8,32(sp)
    8000409a:	6ce2                	ld	s9,24(sp)
    8000409c:	6d42                	ld	s10,16(sp)
    8000409e:	6da2                	ld	s11,8(sp)
    800040a0:	6165                	addi	sp,sp,112
    800040a2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040a4:	8a5e                	mv	s4,s7
    800040a6:	bfc9                	j	80004078 <writei+0xe2>
    return -1;
    800040a8:	557d                	li	a0,-1
}
    800040aa:	8082                	ret
    return -1;
    800040ac:	557d                	li	a0,-1
    800040ae:	bfe1                	j	80004086 <writei+0xf0>
    return -1;
    800040b0:	557d                	li	a0,-1
    800040b2:	bfd1                	j	80004086 <writei+0xf0>

00000000800040b4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040b4:	1141                	addi	sp,sp,-16
    800040b6:	e406                	sd	ra,8(sp)
    800040b8:	e022                	sd	s0,0(sp)
    800040ba:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040bc:	4639                	li	a2,14
    800040be:	ffffd097          	auipc	ra,0xffffd
    800040c2:	cfa080e7          	jalr	-774(ra) # 80000db8 <strncmp>
}
    800040c6:	60a2                	ld	ra,8(sp)
    800040c8:	6402                	ld	s0,0(sp)
    800040ca:	0141                	addi	sp,sp,16
    800040cc:	8082                	ret

00000000800040ce <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040ce:	7139                	addi	sp,sp,-64
    800040d0:	fc06                	sd	ra,56(sp)
    800040d2:	f822                	sd	s0,48(sp)
    800040d4:	f426                	sd	s1,40(sp)
    800040d6:	f04a                	sd	s2,32(sp)
    800040d8:	ec4e                	sd	s3,24(sp)
    800040da:	e852                	sd	s4,16(sp)
    800040dc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040de:	04451703          	lh	a4,68(a0)
    800040e2:	4785                	li	a5,1
    800040e4:	00f71a63          	bne	a4,a5,800040f8 <dirlookup+0x2a>
    800040e8:	892a                	mv	s2,a0
    800040ea:	89ae                	mv	s3,a1
    800040ec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ee:	457c                	lw	a5,76(a0)
    800040f0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040f2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f4:	e79d                	bnez	a5,80004122 <dirlookup+0x54>
    800040f6:	a8a5                	j	8000416e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040f8:	00004517          	auipc	a0,0x4
    800040fc:	52850513          	addi	a0,a0,1320 # 80008620 <syscalls+0x1b0>
    80004100:	ffffc097          	auipc	ra,0xffffc
    80004104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004108:	00004517          	auipc	a0,0x4
    8000410c:	53050513          	addi	a0,a0,1328 # 80008638 <syscalls+0x1c8>
    80004110:	ffffc097          	auipc	ra,0xffffc
    80004114:	42e080e7          	jalr	1070(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004118:	24c1                	addiw	s1,s1,16
    8000411a:	04c92783          	lw	a5,76(s2)
    8000411e:	04f4f763          	bgeu	s1,a5,8000416c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004122:	4741                	li	a4,16
    80004124:	86a6                	mv	a3,s1
    80004126:	fc040613          	addi	a2,s0,-64
    8000412a:	4581                	li	a1,0
    8000412c:	854a                	mv	a0,s2
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	d70080e7          	jalr	-656(ra) # 80003e9e <readi>
    80004136:	47c1                	li	a5,16
    80004138:	fcf518e3          	bne	a0,a5,80004108 <dirlookup+0x3a>
    if(de.inum == 0)
    8000413c:	fc045783          	lhu	a5,-64(s0)
    80004140:	dfe1                	beqz	a5,80004118 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004142:	fc240593          	addi	a1,s0,-62
    80004146:	854e                	mv	a0,s3
    80004148:	00000097          	auipc	ra,0x0
    8000414c:	f6c080e7          	jalr	-148(ra) # 800040b4 <namecmp>
    80004150:	f561                	bnez	a0,80004118 <dirlookup+0x4a>
      if(poff)
    80004152:	000a0463          	beqz	s4,8000415a <dirlookup+0x8c>
        *poff = off;
    80004156:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000415a:	fc045583          	lhu	a1,-64(s0)
    8000415e:	00092503          	lw	a0,0(s2)
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	754080e7          	jalr	1876(ra) # 800038b6 <iget>
    8000416a:	a011                	j	8000416e <dirlookup+0xa0>
  return 0;
    8000416c:	4501                	li	a0,0
}
    8000416e:	70e2                	ld	ra,56(sp)
    80004170:	7442                	ld	s0,48(sp)
    80004172:	74a2                	ld	s1,40(sp)
    80004174:	7902                	ld	s2,32(sp)
    80004176:	69e2                	ld	s3,24(sp)
    80004178:	6a42                	ld	s4,16(sp)
    8000417a:	6121                	addi	sp,sp,64
    8000417c:	8082                	ret

000000008000417e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000417e:	711d                	addi	sp,sp,-96
    80004180:	ec86                	sd	ra,88(sp)
    80004182:	e8a2                	sd	s0,80(sp)
    80004184:	e4a6                	sd	s1,72(sp)
    80004186:	e0ca                	sd	s2,64(sp)
    80004188:	fc4e                	sd	s3,56(sp)
    8000418a:	f852                	sd	s4,48(sp)
    8000418c:	f456                	sd	s5,40(sp)
    8000418e:	f05a                	sd	s6,32(sp)
    80004190:	ec5e                	sd	s7,24(sp)
    80004192:	e862                	sd	s8,16(sp)
    80004194:	e466                	sd	s9,8(sp)
    80004196:	1080                	addi	s0,sp,96
    80004198:	84aa                	mv	s1,a0
    8000419a:	8b2e                	mv	s6,a1
    8000419c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000419e:	00054703          	lbu	a4,0(a0)
    800041a2:	02f00793          	li	a5,47
    800041a6:	02f70363          	beq	a4,a5,800041cc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	75e080e7          	jalr	1886(ra) # 80001908 <myproc>
    800041b2:	17053503          	ld	a0,368(a0)
    800041b6:	00000097          	auipc	ra,0x0
    800041ba:	9f6080e7          	jalr	-1546(ra) # 80003bac <idup>
    800041be:	89aa                	mv	s3,a0
  while(*path == '/')
    800041c0:	02f00913          	li	s2,47
  len = path - s;
    800041c4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800041c6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041c8:	4c05                	li	s8,1
    800041ca:	a865                	j	80004282 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041cc:	4585                	li	a1,1
    800041ce:	4505                	li	a0,1
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	6e6080e7          	jalr	1766(ra) # 800038b6 <iget>
    800041d8:	89aa                	mv	s3,a0
    800041da:	b7dd                	j	800041c0 <namex+0x42>
      iunlockput(ip);
    800041dc:	854e                	mv	a0,s3
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	c6e080e7          	jalr	-914(ra) # 80003e4c <iunlockput>
      return 0;
    800041e6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041e8:	854e                	mv	a0,s3
    800041ea:	60e6                	ld	ra,88(sp)
    800041ec:	6446                	ld	s0,80(sp)
    800041ee:	64a6                	ld	s1,72(sp)
    800041f0:	6906                	ld	s2,64(sp)
    800041f2:	79e2                	ld	s3,56(sp)
    800041f4:	7a42                	ld	s4,48(sp)
    800041f6:	7aa2                	ld	s5,40(sp)
    800041f8:	7b02                	ld	s6,32(sp)
    800041fa:	6be2                	ld	s7,24(sp)
    800041fc:	6c42                	ld	s8,16(sp)
    800041fe:	6ca2                	ld	s9,8(sp)
    80004200:	6125                	addi	sp,sp,96
    80004202:	8082                	ret
      iunlock(ip);
    80004204:	854e                	mv	a0,s3
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	aa6080e7          	jalr	-1370(ra) # 80003cac <iunlock>
      return ip;
    8000420e:	bfe9                	j	800041e8 <namex+0x6a>
      iunlockput(ip);
    80004210:	854e                	mv	a0,s3
    80004212:	00000097          	auipc	ra,0x0
    80004216:	c3a080e7          	jalr	-966(ra) # 80003e4c <iunlockput>
      return 0;
    8000421a:	89d2                	mv	s3,s4
    8000421c:	b7f1                	j	800041e8 <namex+0x6a>
  len = path - s;
    8000421e:	40b48633          	sub	a2,s1,a1
    80004222:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004226:	094cd463          	bge	s9,s4,800042ae <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000422a:	4639                	li	a2,14
    8000422c:	8556                	mv	a0,s5
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	b12080e7          	jalr	-1262(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004236:	0004c783          	lbu	a5,0(s1)
    8000423a:	01279763          	bne	a5,s2,80004248 <namex+0xca>
    path++;
    8000423e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004240:	0004c783          	lbu	a5,0(s1)
    80004244:	ff278de3          	beq	a5,s2,8000423e <namex+0xc0>
    ilock(ip);
    80004248:	854e                	mv	a0,s3
    8000424a:	00000097          	auipc	ra,0x0
    8000424e:	9a0080e7          	jalr	-1632(ra) # 80003bea <ilock>
    if(ip->type != T_DIR){
    80004252:	04499783          	lh	a5,68(s3)
    80004256:	f98793e3          	bne	a5,s8,800041dc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000425a:	000b0563          	beqz	s6,80004264 <namex+0xe6>
    8000425e:	0004c783          	lbu	a5,0(s1)
    80004262:	d3cd                	beqz	a5,80004204 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004264:	865e                	mv	a2,s7
    80004266:	85d6                	mv	a1,s5
    80004268:	854e                	mv	a0,s3
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	e64080e7          	jalr	-412(ra) # 800040ce <dirlookup>
    80004272:	8a2a                	mv	s4,a0
    80004274:	dd51                	beqz	a0,80004210 <namex+0x92>
    iunlockput(ip);
    80004276:	854e                	mv	a0,s3
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	bd4080e7          	jalr	-1068(ra) # 80003e4c <iunlockput>
    ip = next;
    80004280:	89d2                	mv	s3,s4
  while(*path == '/')
    80004282:	0004c783          	lbu	a5,0(s1)
    80004286:	05279763          	bne	a5,s2,800042d4 <namex+0x156>
    path++;
    8000428a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000428c:	0004c783          	lbu	a5,0(s1)
    80004290:	ff278de3          	beq	a5,s2,8000428a <namex+0x10c>
  if(*path == 0)
    80004294:	c79d                	beqz	a5,800042c2 <namex+0x144>
    path++;
    80004296:	85a6                	mv	a1,s1
  len = path - s;
    80004298:	8a5e                	mv	s4,s7
    8000429a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000429c:	01278963          	beq	a5,s2,800042ae <namex+0x130>
    800042a0:	dfbd                	beqz	a5,8000421e <namex+0xa0>
    path++;
    800042a2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042a4:	0004c783          	lbu	a5,0(s1)
    800042a8:	ff279ce3          	bne	a5,s2,800042a0 <namex+0x122>
    800042ac:	bf8d                	j	8000421e <namex+0xa0>
    memmove(name, s, len);
    800042ae:	2601                	sext.w	a2,a2
    800042b0:	8556                	mv	a0,s5
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	a8e080e7          	jalr	-1394(ra) # 80000d40 <memmove>
    name[len] = 0;
    800042ba:	9a56                	add	s4,s4,s5
    800042bc:	000a0023          	sb	zero,0(s4)
    800042c0:	bf9d                	j	80004236 <namex+0xb8>
  if(nameiparent){
    800042c2:	f20b03e3          	beqz	s6,800041e8 <namex+0x6a>
    iput(ip);
    800042c6:	854e                	mv	a0,s3
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	adc080e7          	jalr	-1316(ra) # 80003da4 <iput>
    return 0;
    800042d0:	4981                	li	s3,0
    800042d2:	bf19                	j	800041e8 <namex+0x6a>
  if(*path == 0)
    800042d4:	d7fd                	beqz	a5,800042c2 <namex+0x144>
  while(*path != '/' && *path != 0)
    800042d6:	0004c783          	lbu	a5,0(s1)
    800042da:	85a6                	mv	a1,s1
    800042dc:	b7d1                	j	800042a0 <namex+0x122>

00000000800042de <dirlink>:
{
    800042de:	7139                	addi	sp,sp,-64
    800042e0:	fc06                	sd	ra,56(sp)
    800042e2:	f822                	sd	s0,48(sp)
    800042e4:	f426                	sd	s1,40(sp)
    800042e6:	f04a                	sd	s2,32(sp)
    800042e8:	ec4e                	sd	s3,24(sp)
    800042ea:	e852                	sd	s4,16(sp)
    800042ec:	0080                	addi	s0,sp,64
    800042ee:	892a                	mv	s2,a0
    800042f0:	8a2e                	mv	s4,a1
    800042f2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042f4:	4601                	li	a2,0
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	dd8080e7          	jalr	-552(ra) # 800040ce <dirlookup>
    800042fe:	e93d                	bnez	a0,80004374 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004300:	04c92483          	lw	s1,76(s2)
    80004304:	c49d                	beqz	s1,80004332 <dirlink+0x54>
    80004306:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004308:	4741                	li	a4,16
    8000430a:	86a6                	mv	a3,s1
    8000430c:	fc040613          	addi	a2,s0,-64
    80004310:	4581                	li	a1,0
    80004312:	854a                	mv	a0,s2
    80004314:	00000097          	auipc	ra,0x0
    80004318:	b8a080e7          	jalr	-1142(ra) # 80003e9e <readi>
    8000431c:	47c1                	li	a5,16
    8000431e:	06f51163          	bne	a0,a5,80004380 <dirlink+0xa2>
    if(de.inum == 0)
    80004322:	fc045783          	lhu	a5,-64(s0)
    80004326:	c791                	beqz	a5,80004332 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004328:	24c1                	addiw	s1,s1,16
    8000432a:	04c92783          	lw	a5,76(s2)
    8000432e:	fcf4ede3          	bltu	s1,a5,80004308 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004332:	4639                	li	a2,14
    80004334:	85d2                	mv	a1,s4
    80004336:	fc240513          	addi	a0,s0,-62
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	aba080e7          	jalr	-1350(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004342:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004346:	4741                	li	a4,16
    80004348:	86a6                	mv	a3,s1
    8000434a:	fc040613          	addi	a2,s0,-64
    8000434e:	4581                	li	a1,0
    80004350:	854a                	mv	a0,s2
    80004352:	00000097          	auipc	ra,0x0
    80004356:	c44080e7          	jalr	-956(ra) # 80003f96 <writei>
    8000435a:	872a                	mv	a4,a0
    8000435c:	47c1                	li	a5,16
  return 0;
    8000435e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004360:	02f71863          	bne	a4,a5,80004390 <dirlink+0xb2>
}
    80004364:	70e2                	ld	ra,56(sp)
    80004366:	7442                	ld	s0,48(sp)
    80004368:	74a2                	ld	s1,40(sp)
    8000436a:	7902                	ld	s2,32(sp)
    8000436c:	69e2                	ld	s3,24(sp)
    8000436e:	6a42                	ld	s4,16(sp)
    80004370:	6121                	addi	sp,sp,64
    80004372:	8082                	ret
    iput(ip);
    80004374:	00000097          	auipc	ra,0x0
    80004378:	a30080e7          	jalr	-1488(ra) # 80003da4 <iput>
    return -1;
    8000437c:	557d                	li	a0,-1
    8000437e:	b7dd                	j	80004364 <dirlink+0x86>
      panic("dirlink read");
    80004380:	00004517          	auipc	a0,0x4
    80004384:	2c850513          	addi	a0,a0,712 # 80008648 <syscalls+0x1d8>
    80004388:	ffffc097          	auipc	ra,0xffffc
    8000438c:	1b6080e7          	jalr	438(ra) # 8000053e <panic>
    panic("dirlink");
    80004390:	00004517          	auipc	a0,0x4
    80004394:	3c850513          	addi	a0,a0,968 # 80008758 <syscalls+0x2e8>
    80004398:	ffffc097          	auipc	ra,0xffffc
    8000439c:	1a6080e7          	jalr	422(ra) # 8000053e <panic>

00000000800043a0 <namei>:

struct inode*
namei(char *path)
{
    800043a0:	1101                	addi	sp,sp,-32
    800043a2:	ec06                	sd	ra,24(sp)
    800043a4:	e822                	sd	s0,16(sp)
    800043a6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043a8:	fe040613          	addi	a2,s0,-32
    800043ac:	4581                	li	a1,0
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	dd0080e7          	jalr	-560(ra) # 8000417e <namex>
}
    800043b6:	60e2                	ld	ra,24(sp)
    800043b8:	6442                	ld	s0,16(sp)
    800043ba:	6105                	addi	sp,sp,32
    800043bc:	8082                	ret

00000000800043be <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043be:	1141                	addi	sp,sp,-16
    800043c0:	e406                	sd	ra,8(sp)
    800043c2:	e022                	sd	s0,0(sp)
    800043c4:	0800                	addi	s0,sp,16
    800043c6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043c8:	4585                	li	a1,1
    800043ca:	00000097          	auipc	ra,0x0
    800043ce:	db4080e7          	jalr	-588(ra) # 8000417e <namex>
}
    800043d2:	60a2                	ld	ra,8(sp)
    800043d4:	6402                	ld	s0,0(sp)
    800043d6:	0141                	addi	sp,sp,16
    800043d8:	8082                	ret

00000000800043da <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043da:	1101                	addi	sp,sp,-32
    800043dc:	ec06                	sd	ra,24(sp)
    800043de:	e822                	sd	s0,16(sp)
    800043e0:	e426                	sd	s1,8(sp)
    800043e2:	e04a                	sd	s2,0(sp)
    800043e4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043e6:	0001d917          	auipc	s2,0x1d
    800043ea:	7d290913          	addi	s2,s2,2002 # 80021bb8 <log>
    800043ee:	01892583          	lw	a1,24(s2)
    800043f2:	02892503          	lw	a0,40(s2)
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	ff2080e7          	jalr	-14(ra) # 800033e8 <bread>
    800043fe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004400:	02c92683          	lw	a3,44(s2)
    80004404:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004406:	02d05763          	blez	a3,80004434 <write_head+0x5a>
    8000440a:	0001d797          	auipc	a5,0x1d
    8000440e:	7de78793          	addi	a5,a5,2014 # 80021be8 <log+0x30>
    80004412:	05c50713          	addi	a4,a0,92
    80004416:	36fd                	addiw	a3,a3,-1
    80004418:	1682                	slli	a3,a3,0x20
    8000441a:	9281                	srli	a3,a3,0x20
    8000441c:	068a                	slli	a3,a3,0x2
    8000441e:	0001d617          	auipc	a2,0x1d
    80004422:	7ce60613          	addi	a2,a2,1998 # 80021bec <log+0x34>
    80004426:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004428:	4390                	lw	a2,0(a5)
    8000442a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000442c:	0791                	addi	a5,a5,4
    8000442e:	0711                	addi	a4,a4,4
    80004430:	fed79ce3          	bne	a5,a3,80004428 <write_head+0x4e>
  }
  bwrite(buf);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	0a4080e7          	jalr	164(ra) # 800034da <bwrite>
  brelse(buf);
    8000443e:	8526                	mv	a0,s1
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	0d8080e7          	jalr	216(ra) # 80003518 <brelse>
}
    80004448:	60e2                	ld	ra,24(sp)
    8000444a:	6442                	ld	s0,16(sp)
    8000444c:	64a2                	ld	s1,8(sp)
    8000444e:	6902                	ld	s2,0(sp)
    80004450:	6105                	addi	sp,sp,32
    80004452:	8082                	ret

0000000080004454 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004454:	0001d797          	auipc	a5,0x1d
    80004458:	7907a783          	lw	a5,1936(a5) # 80021be4 <log+0x2c>
    8000445c:	0af05d63          	blez	a5,80004516 <install_trans+0xc2>
{
    80004460:	7139                	addi	sp,sp,-64
    80004462:	fc06                	sd	ra,56(sp)
    80004464:	f822                	sd	s0,48(sp)
    80004466:	f426                	sd	s1,40(sp)
    80004468:	f04a                	sd	s2,32(sp)
    8000446a:	ec4e                	sd	s3,24(sp)
    8000446c:	e852                	sd	s4,16(sp)
    8000446e:	e456                	sd	s5,8(sp)
    80004470:	e05a                	sd	s6,0(sp)
    80004472:	0080                	addi	s0,sp,64
    80004474:	8b2a                	mv	s6,a0
    80004476:	0001da97          	auipc	s5,0x1d
    8000447a:	772a8a93          	addi	s5,s5,1906 # 80021be8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004480:	0001d997          	auipc	s3,0x1d
    80004484:	73898993          	addi	s3,s3,1848 # 80021bb8 <log>
    80004488:	a035                	j	800044b4 <install_trans+0x60>
      bunpin(dbuf);
    8000448a:	8526                	mv	a0,s1
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	166080e7          	jalr	358(ra) # 800035f2 <bunpin>
    brelse(lbuf);
    80004494:	854a                	mv	a0,s2
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	082080e7          	jalr	130(ra) # 80003518 <brelse>
    brelse(dbuf);
    8000449e:	8526                	mv	a0,s1
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	078080e7          	jalr	120(ra) # 80003518 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a8:	2a05                	addiw	s4,s4,1
    800044aa:	0a91                	addi	s5,s5,4
    800044ac:	02c9a783          	lw	a5,44(s3)
    800044b0:	04fa5963          	bge	s4,a5,80004502 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044b4:	0189a583          	lw	a1,24(s3)
    800044b8:	014585bb          	addw	a1,a1,s4
    800044bc:	2585                	addiw	a1,a1,1
    800044be:	0289a503          	lw	a0,40(s3)
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	f26080e7          	jalr	-218(ra) # 800033e8 <bread>
    800044ca:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044cc:	000aa583          	lw	a1,0(s5)
    800044d0:	0289a503          	lw	a0,40(s3)
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	f14080e7          	jalr	-236(ra) # 800033e8 <bread>
    800044dc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044de:	40000613          	li	a2,1024
    800044e2:	05890593          	addi	a1,s2,88
    800044e6:	05850513          	addi	a0,a0,88
    800044ea:	ffffd097          	auipc	ra,0xffffd
    800044ee:	856080e7          	jalr	-1962(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044f2:	8526                	mv	a0,s1
    800044f4:	fffff097          	auipc	ra,0xfffff
    800044f8:	fe6080e7          	jalr	-26(ra) # 800034da <bwrite>
    if(recovering == 0)
    800044fc:	f80b1ce3          	bnez	s6,80004494 <install_trans+0x40>
    80004500:	b769                	j	8000448a <install_trans+0x36>
}
    80004502:	70e2                	ld	ra,56(sp)
    80004504:	7442                	ld	s0,48(sp)
    80004506:	74a2                	ld	s1,40(sp)
    80004508:	7902                	ld	s2,32(sp)
    8000450a:	69e2                	ld	s3,24(sp)
    8000450c:	6a42                	ld	s4,16(sp)
    8000450e:	6aa2                	ld	s5,8(sp)
    80004510:	6b02                	ld	s6,0(sp)
    80004512:	6121                	addi	sp,sp,64
    80004514:	8082                	ret
    80004516:	8082                	ret

0000000080004518 <initlog>:
{
    80004518:	7179                	addi	sp,sp,-48
    8000451a:	f406                	sd	ra,40(sp)
    8000451c:	f022                	sd	s0,32(sp)
    8000451e:	ec26                	sd	s1,24(sp)
    80004520:	e84a                	sd	s2,16(sp)
    80004522:	e44e                	sd	s3,8(sp)
    80004524:	1800                	addi	s0,sp,48
    80004526:	892a                	mv	s2,a0
    80004528:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000452a:	0001d497          	auipc	s1,0x1d
    8000452e:	68e48493          	addi	s1,s1,1678 # 80021bb8 <log>
    80004532:	00004597          	auipc	a1,0x4
    80004536:	12658593          	addi	a1,a1,294 # 80008658 <syscalls+0x1e8>
    8000453a:	8526                	mv	a0,s1
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	618080e7          	jalr	1560(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004544:	0149a583          	lw	a1,20(s3)
    80004548:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000454a:	0109a783          	lw	a5,16(s3)
    8000454e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004550:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004554:	854a                	mv	a0,s2
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	e92080e7          	jalr	-366(ra) # 800033e8 <bread>
  log.lh.n = lh->n;
    8000455e:	4d3c                	lw	a5,88(a0)
    80004560:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004562:	02f05563          	blez	a5,8000458c <initlog+0x74>
    80004566:	05c50713          	addi	a4,a0,92
    8000456a:	0001d697          	auipc	a3,0x1d
    8000456e:	67e68693          	addi	a3,a3,1662 # 80021be8 <log+0x30>
    80004572:	37fd                	addiw	a5,a5,-1
    80004574:	1782                	slli	a5,a5,0x20
    80004576:	9381                	srli	a5,a5,0x20
    80004578:	078a                	slli	a5,a5,0x2
    8000457a:	06050613          	addi	a2,a0,96
    8000457e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004580:	4310                	lw	a2,0(a4)
    80004582:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004584:	0711                	addi	a4,a4,4
    80004586:	0691                	addi	a3,a3,4
    80004588:	fef71ce3          	bne	a4,a5,80004580 <initlog+0x68>
  brelse(buf);
    8000458c:	fffff097          	auipc	ra,0xfffff
    80004590:	f8c080e7          	jalr	-116(ra) # 80003518 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004594:	4505                	li	a0,1
    80004596:	00000097          	auipc	ra,0x0
    8000459a:	ebe080e7          	jalr	-322(ra) # 80004454 <install_trans>
  log.lh.n = 0;
    8000459e:	0001d797          	auipc	a5,0x1d
    800045a2:	6407a323          	sw	zero,1606(a5) # 80021be4 <log+0x2c>
  write_head(); // clear the log
    800045a6:	00000097          	auipc	ra,0x0
    800045aa:	e34080e7          	jalr	-460(ra) # 800043da <write_head>
}
    800045ae:	70a2                	ld	ra,40(sp)
    800045b0:	7402                	ld	s0,32(sp)
    800045b2:	64e2                	ld	s1,24(sp)
    800045b4:	6942                	ld	s2,16(sp)
    800045b6:	69a2                	ld	s3,8(sp)
    800045b8:	6145                	addi	sp,sp,48
    800045ba:	8082                	ret

00000000800045bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045bc:	1101                	addi	sp,sp,-32
    800045be:	ec06                	sd	ra,24(sp)
    800045c0:	e822                	sd	s0,16(sp)
    800045c2:	e426                	sd	s1,8(sp)
    800045c4:	e04a                	sd	s2,0(sp)
    800045c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045c8:	0001d517          	auipc	a0,0x1d
    800045cc:	5f050513          	addi	a0,a0,1520 # 80021bb8 <log>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	614080e7          	jalr	1556(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800045d8:	0001d497          	auipc	s1,0x1d
    800045dc:	5e048493          	addi	s1,s1,1504 # 80021bb8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045e0:	4979                	li	s2,30
    800045e2:	a039                	j	800045f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045e4:	85a6                	mv	a1,s1
    800045e6:	8526                	mv	a0,s1
    800045e8:	ffffe097          	auipc	ra,0xffffe
    800045ec:	a48080e7          	jalr	-1464(ra) # 80002030 <sleep>
    if(log.committing){
    800045f0:	50dc                	lw	a5,36(s1)
    800045f2:	fbed                	bnez	a5,800045e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045f4:	509c                	lw	a5,32(s1)
    800045f6:	0017871b          	addiw	a4,a5,1
    800045fa:	0007069b          	sext.w	a3,a4
    800045fe:	0027179b          	slliw	a5,a4,0x2
    80004602:	9fb9                	addw	a5,a5,a4
    80004604:	0017979b          	slliw	a5,a5,0x1
    80004608:	54d8                	lw	a4,44(s1)
    8000460a:	9fb9                	addw	a5,a5,a4
    8000460c:	00f95963          	bge	s2,a5,8000461e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004610:	85a6                	mv	a1,s1
    80004612:	8526                	mv	a0,s1
    80004614:	ffffe097          	auipc	ra,0xffffe
    80004618:	a1c080e7          	jalr	-1508(ra) # 80002030 <sleep>
    8000461c:	bfd1                	j	800045f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000461e:	0001d517          	auipc	a0,0x1d
    80004622:	59a50513          	addi	a0,a0,1434 # 80021bb8 <log>
    80004626:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	670080e7          	jalr	1648(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004630:	60e2                	ld	ra,24(sp)
    80004632:	6442                	ld	s0,16(sp)
    80004634:	64a2                	ld	s1,8(sp)
    80004636:	6902                	ld	s2,0(sp)
    80004638:	6105                	addi	sp,sp,32
    8000463a:	8082                	ret

000000008000463c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000463c:	7139                	addi	sp,sp,-64
    8000463e:	fc06                	sd	ra,56(sp)
    80004640:	f822                	sd	s0,48(sp)
    80004642:	f426                	sd	s1,40(sp)
    80004644:	f04a                	sd	s2,32(sp)
    80004646:	ec4e                	sd	s3,24(sp)
    80004648:	e852                	sd	s4,16(sp)
    8000464a:	e456                	sd	s5,8(sp)
    8000464c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000464e:	0001d497          	auipc	s1,0x1d
    80004652:	56a48493          	addi	s1,s1,1386 # 80021bb8 <log>
    80004656:	8526                	mv	a0,s1
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	58c080e7          	jalr	1420(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004660:	509c                	lw	a5,32(s1)
    80004662:	37fd                	addiw	a5,a5,-1
    80004664:	0007891b          	sext.w	s2,a5
    80004668:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000466a:	50dc                	lw	a5,36(s1)
    8000466c:	efb9                	bnez	a5,800046ca <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000466e:	06091663          	bnez	s2,800046da <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004672:	0001d497          	auipc	s1,0x1d
    80004676:	54648493          	addi	s1,s1,1350 # 80021bb8 <log>
    8000467a:	4785                	li	a5,1
    8000467c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000467e:	8526                	mv	a0,s1
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	618080e7          	jalr	1560(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004688:	54dc                	lw	a5,44(s1)
    8000468a:	06f04763          	bgtz	a5,800046f8 <end_op+0xbc>
    acquire(&log.lock);
    8000468e:	0001d497          	auipc	s1,0x1d
    80004692:	52a48493          	addi	s1,s1,1322 # 80021bb8 <log>
    80004696:	8526                	mv	a0,s1
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	54c080e7          	jalr	1356(ra) # 80000be4 <acquire>
    log.committing = 0;
    800046a0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046a4:	8526                	mv	a0,s1
    800046a6:	ffffe097          	auipc	ra,0xffffe
    800046aa:	d04080e7          	jalr	-764(ra) # 800023aa <wakeup>
    release(&log.lock);
    800046ae:	8526                	mv	a0,s1
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	5e8080e7          	jalr	1512(ra) # 80000c98 <release>
}
    800046b8:	70e2                	ld	ra,56(sp)
    800046ba:	7442                	ld	s0,48(sp)
    800046bc:	74a2                	ld	s1,40(sp)
    800046be:	7902                	ld	s2,32(sp)
    800046c0:	69e2                	ld	s3,24(sp)
    800046c2:	6a42                	ld	s4,16(sp)
    800046c4:	6aa2                	ld	s5,8(sp)
    800046c6:	6121                	addi	sp,sp,64
    800046c8:	8082                	ret
    panic("log.committing");
    800046ca:	00004517          	auipc	a0,0x4
    800046ce:	f9650513          	addi	a0,a0,-106 # 80008660 <syscalls+0x1f0>
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	e6c080e7          	jalr	-404(ra) # 8000053e <panic>
    wakeup(&log);
    800046da:	0001d497          	auipc	s1,0x1d
    800046de:	4de48493          	addi	s1,s1,1246 # 80021bb8 <log>
    800046e2:	8526                	mv	a0,s1
    800046e4:	ffffe097          	auipc	ra,0xffffe
    800046e8:	cc6080e7          	jalr	-826(ra) # 800023aa <wakeup>
  release(&log.lock);
    800046ec:	8526                	mv	a0,s1
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	5aa080e7          	jalr	1450(ra) # 80000c98 <release>
  if(do_commit){
    800046f6:	b7c9                	j	800046b8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f8:	0001da97          	auipc	s5,0x1d
    800046fc:	4f0a8a93          	addi	s5,s5,1264 # 80021be8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004700:	0001da17          	auipc	s4,0x1d
    80004704:	4b8a0a13          	addi	s4,s4,1208 # 80021bb8 <log>
    80004708:	018a2583          	lw	a1,24(s4)
    8000470c:	012585bb          	addw	a1,a1,s2
    80004710:	2585                	addiw	a1,a1,1
    80004712:	028a2503          	lw	a0,40(s4)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	cd2080e7          	jalr	-814(ra) # 800033e8 <bread>
    8000471e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004720:	000aa583          	lw	a1,0(s5)
    80004724:	028a2503          	lw	a0,40(s4)
    80004728:	fffff097          	auipc	ra,0xfffff
    8000472c:	cc0080e7          	jalr	-832(ra) # 800033e8 <bread>
    80004730:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004732:	40000613          	li	a2,1024
    80004736:	05850593          	addi	a1,a0,88
    8000473a:	05848513          	addi	a0,s1,88
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	602080e7          	jalr	1538(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004746:	8526                	mv	a0,s1
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	d92080e7          	jalr	-622(ra) # 800034da <bwrite>
    brelse(from);
    80004750:	854e                	mv	a0,s3
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	dc6080e7          	jalr	-570(ra) # 80003518 <brelse>
    brelse(to);
    8000475a:	8526                	mv	a0,s1
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	dbc080e7          	jalr	-580(ra) # 80003518 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004764:	2905                	addiw	s2,s2,1
    80004766:	0a91                	addi	s5,s5,4
    80004768:	02ca2783          	lw	a5,44(s4)
    8000476c:	f8f94ee3          	blt	s2,a5,80004708 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004770:	00000097          	auipc	ra,0x0
    80004774:	c6a080e7          	jalr	-918(ra) # 800043da <write_head>
    install_trans(0); // Now install writes to home locations
    80004778:	4501                	li	a0,0
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	cda080e7          	jalr	-806(ra) # 80004454 <install_trans>
    log.lh.n = 0;
    80004782:	0001d797          	auipc	a5,0x1d
    80004786:	4607a123          	sw	zero,1122(a5) # 80021be4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	c50080e7          	jalr	-944(ra) # 800043da <write_head>
    80004792:	bdf5                	j	8000468e <end_op+0x52>

0000000080004794 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004794:	1101                	addi	sp,sp,-32
    80004796:	ec06                	sd	ra,24(sp)
    80004798:	e822                	sd	s0,16(sp)
    8000479a:	e426                	sd	s1,8(sp)
    8000479c:	e04a                	sd	s2,0(sp)
    8000479e:	1000                	addi	s0,sp,32
    800047a0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047a2:	0001d917          	auipc	s2,0x1d
    800047a6:	41690913          	addi	s2,s2,1046 # 80021bb8 <log>
    800047aa:	854a                	mv	a0,s2
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	438080e7          	jalr	1080(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047b4:	02c92603          	lw	a2,44(s2)
    800047b8:	47f5                	li	a5,29
    800047ba:	06c7c563          	blt	a5,a2,80004824 <log_write+0x90>
    800047be:	0001d797          	auipc	a5,0x1d
    800047c2:	4167a783          	lw	a5,1046(a5) # 80021bd4 <log+0x1c>
    800047c6:	37fd                	addiw	a5,a5,-1
    800047c8:	04f65e63          	bge	a2,a5,80004824 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047cc:	0001d797          	auipc	a5,0x1d
    800047d0:	40c7a783          	lw	a5,1036(a5) # 80021bd8 <log+0x20>
    800047d4:	06f05063          	blez	a5,80004834 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047d8:	4781                	li	a5,0
    800047da:	06c05563          	blez	a2,80004844 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047de:	44cc                	lw	a1,12(s1)
    800047e0:	0001d717          	auipc	a4,0x1d
    800047e4:	40870713          	addi	a4,a4,1032 # 80021be8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047e8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047ea:	4314                	lw	a3,0(a4)
    800047ec:	04b68c63          	beq	a3,a1,80004844 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047f0:	2785                	addiw	a5,a5,1
    800047f2:	0711                	addi	a4,a4,4
    800047f4:	fef61be3          	bne	a2,a5,800047ea <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047f8:	0621                	addi	a2,a2,8
    800047fa:	060a                	slli	a2,a2,0x2
    800047fc:	0001d797          	auipc	a5,0x1d
    80004800:	3bc78793          	addi	a5,a5,956 # 80021bb8 <log>
    80004804:	963e                	add	a2,a2,a5
    80004806:	44dc                	lw	a5,12(s1)
    80004808:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000480a:	8526                	mv	a0,s1
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	daa080e7          	jalr	-598(ra) # 800035b6 <bpin>
    log.lh.n++;
    80004814:	0001d717          	auipc	a4,0x1d
    80004818:	3a470713          	addi	a4,a4,932 # 80021bb8 <log>
    8000481c:	575c                	lw	a5,44(a4)
    8000481e:	2785                	addiw	a5,a5,1
    80004820:	d75c                	sw	a5,44(a4)
    80004822:	a835                	j	8000485e <log_write+0xca>
    panic("too big a transaction");
    80004824:	00004517          	auipc	a0,0x4
    80004828:	e4c50513          	addi	a0,a0,-436 # 80008670 <syscalls+0x200>
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	d12080e7          	jalr	-750(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004834:	00004517          	auipc	a0,0x4
    80004838:	e5450513          	addi	a0,a0,-428 # 80008688 <syscalls+0x218>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	d02080e7          	jalr	-766(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004844:	00878713          	addi	a4,a5,8
    80004848:	00271693          	slli	a3,a4,0x2
    8000484c:	0001d717          	auipc	a4,0x1d
    80004850:	36c70713          	addi	a4,a4,876 # 80021bb8 <log>
    80004854:	9736                	add	a4,a4,a3
    80004856:	44d4                	lw	a3,12(s1)
    80004858:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000485a:	faf608e3          	beq	a2,a5,8000480a <log_write+0x76>
  }
  release(&log.lock);
    8000485e:	0001d517          	auipc	a0,0x1d
    80004862:	35a50513          	addi	a0,a0,858 # 80021bb8 <log>
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	432080e7          	jalr	1074(ra) # 80000c98 <release>
}
    8000486e:	60e2                	ld	ra,24(sp)
    80004870:	6442                	ld	s0,16(sp)
    80004872:	64a2                	ld	s1,8(sp)
    80004874:	6902                	ld	s2,0(sp)
    80004876:	6105                	addi	sp,sp,32
    80004878:	8082                	ret

000000008000487a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000487a:	1101                	addi	sp,sp,-32
    8000487c:	ec06                	sd	ra,24(sp)
    8000487e:	e822                	sd	s0,16(sp)
    80004880:	e426                	sd	s1,8(sp)
    80004882:	e04a                	sd	s2,0(sp)
    80004884:	1000                	addi	s0,sp,32
    80004886:	84aa                	mv	s1,a0
    80004888:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000488a:	00004597          	auipc	a1,0x4
    8000488e:	e1e58593          	addi	a1,a1,-482 # 800086a8 <syscalls+0x238>
    80004892:	0521                	addi	a0,a0,8
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	2c0080e7          	jalr	704(ra) # 80000b54 <initlock>
  lk->name = name;
    8000489c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048a0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048a4:	0204a423          	sw	zero,40(s1)
}
    800048a8:	60e2                	ld	ra,24(sp)
    800048aa:	6442                	ld	s0,16(sp)
    800048ac:	64a2                	ld	s1,8(sp)
    800048ae:	6902                	ld	s2,0(sp)
    800048b0:	6105                	addi	sp,sp,32
    800048b2:	8082                	ret

00000000800048b4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048b4:	1101                	addi	sp,sp,-32
    800048b6:	ec06                	sd	ra,24(sp)
    800048b8:	e822                	sd	s0,16(sp)
    800048ba:	e426                	sd	s1,8(sp)
    800048bc:	e04a                	sd	s2,0(sp)
    800048be:	1000                	addi	s0,sp,32
    800048c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048c2:	00850913          	addi	s2,a0,8
    800048c6:	854a                	mv	a0,s2
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	31c080e7          	jalr	796(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800048d0:	409c                	lw	a5,0(s1)
    800048d2:	cb89                	beqz	a5,800048e4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048d4:	85ca                	mv	a1,s2
    800048d6:	8526                	mv	a0,s1
    800048d8:	ffffd097          	auipc	ra,0xffffd
    800048dc:	758080e7          	jalr	1880(ra) # 80002030 <sleep>
  while (lk->locked) {
    800048e0:	409c                	lw	a5,0(s1)
    800048e2:	fbed                	bnez	a5,800048d4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048e4:	4785                	li	a5,1
    800048e6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048e8:	ffffd097          	auipc	ra,0xffffd
    800048ec:	020080e7          	jalr	32(ra) # 80001908 <myproc>
    800048f0:	591c                	lw	a5,48(a0)
    800048f2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048f4:	854a                	mv	a0,s2
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	3a2080e7          	jalr	930(ra) # 80000c98 <release>
}
    800048fe:	60e2                	ld	ra,24(sp)
    80004900:	6442                	ld	s0,16(sp)
    80004902:	64a2                	ld	s1,8(sp)
    80004904:	6902                	ld	s2,0(sp)
    80004906:	6105                	addi	sp,sp,32
    80004908:	8082                	ret

000000008000490a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000490a:	1101                	addi	sp,sp,-32
    8000490c:	ec06                	sd	ra,24(sp)
    8000490e:	e822                	sd	s0,16(sp)
    80004910:	e426                	sd	s1,8(sp)
    80004912:	e04a                	sd	s2,0(sp)
    80004914:	1000                	addi	s0,sp,32
    80004916:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004918:	00850913          	addi	s2,a0,8
    8000491c:	854a                	mv	a0,s2
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	2c6080e7          	jalr	710(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004926:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000492a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000492e:	8526                	mv	a0,s1
    80004930:	ffffe097          	auipc	ra,0xffffe
    80004934:	a7a080e7          	jalr	-1414(ra) # 800023aa <wakeup>
  release(&lk->lk);
    80004938:	854a                	mv	a0,s2
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	35e080e7          	jalr	862(ra) # 80000c98 <release>
}
    80004942:	60e2                	ld	ra,24(sp)
    80004944:	6442                	ld	s0,16(sp)
    80004946:	64a2                	ld	s1,8(sp)
    80004948:	6902                	ld	s2,0(sp)
    8000494a:	6105                	addi	sp,sp,32
    8000494c:	8082                	ret

000000008000494e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000494e:	7179                	addi	sp,sp,-48
    80004950:	f406                	sd	ra,40(sp)
    80004952:	f022                	sd	s0,32(sp)
    80004954:	ec26                	sd	s1,24(sp)
    80004956:	e84a                	sd	s2,16(sp)
    80004958:	e44e                	sd	s3,8(sp)
    8000495a:	1800                	addi	s0,sp,48
    8000495c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000495e:	00850913          	addi	s2,a0,8
    80004962:	854a                	mv	a0,s2
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	280080e7          	jalr	640(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000496c:	409c                	lw	a5,0(s1)
    8000496e:	ef99                	bnez	a5,8000498c <holdingsleep+0x3e>
    80004970:	4481                	li	s1,0
  release(&lk->lk);
    80004972:	854a                	mv	a0,s2
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	324080e7          	jalr	804(ra) # 80000c98 <release>
  return r;
}
    8000497c:	8526                	mv	a0,s1
    8000497e:	70a2                	ld	ra,40(sp)
    80004980:	7402                	ld	s0,32(sp)
    80004982:	64e2                	ld	s1,24(sp)
    80004984:	6942                	ld	s2,16(sp)
    80004986:	69a2                	ld	s3,8(sp)
    80004988:	6145                	addi	sp,sp,48
    8000498a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000498c:	0284a983          	lw	s3,40(s1)
    80004990:	ffffd097          	auipc	ra,0xffffd
    80004994:	f78080e7          	jalr	-136(ra) # 80001908 <myproc>
    80004998:	5904                	lw	s1,48(a0)
    8000499a:	413484b3          	sub	s1,s1,s3
    8000499e:	0014b493          	seqz	s1,s1
    800049a2:	bfc1                	j	80004972 <holdingsleep+0x24>

00000000800049a4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049a4:	1141                	addi	sp,sp,-16
    800049a6:	e406                	sd	ra,8(sp)
    800049a8:	e022                	sd	s0,0(sp)
    800049aa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049ac:	00004597          	auipc	a1,0x4
    800049b0:	d0c58593          	addi	a1,a1,-756 # 800086b8 <syscalls+0x248>
    800049b4:	0001d517          	auipc	a0,0x1d
    800049b8:	34c50513          	addi	a0,a0,844 # 80021d00 <ftable>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	198080e7          	jalr	408(ra) # 80000b54 <initlock>
}
    800049c4:	60a2                	ld	ra,8(sp)
    800049c6:	6402                	ld	s0,0(sp)
    800049c8:	0141                	addi	sp,sp,16
    800049ca:	8082                	ret

00000000800049cc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049cc:	1101                	addi	sp,sp,-32
    800049ce:	ec06                	sd	ra,24(sp)
    800049d0:	e822                	sd	s0,16(sp)
    800049d2:	e426                	sd	s1,8(sp)
    800049d4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049d6:	0001d517          	auipc	a0,0x1d
    800049da:	32a50513          	addi	a0,a0,810 # 80021d00 <ftable>
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	206080e7          	jalr	518(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049e6:	0001d497          	auipc	s1,0x1d
    800049ea:	33248493          	addi	s1,s1,818 # 80021d18 <ftable+0x18>
    800049ee:	0001e717          	auipc	a4,0x1e
    800049f2:	2ca70713          	addi	a4,a4,714 # 80022cb8 <ftable+0xfb8>
    if(f->ref == 0){
    800049f6:	40dc                	lw	a5,4(s1)
    800049f8:	cf99                	beqz	a5,80004a16 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049fa:	02848493          	addi	s1,s1,40
    800049fe:	fee49ce3          	bne	s1,a4,800049f6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a02:	0001d517          	auipc	a0,0x1d
    80004a06:	2fe50513          	addi	a0,a0,766 # 80021d00 <ftable>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	28e080e7          	jalr	654(ra) # 80000c98 <release>
  return 0;
    80004a12:	4481                	li	s1,0
    80004a14:	a819                	j	80004a2a <filealloc+0x5e>
      f->ref = 1;
    80004a16:	4785                	li	a5,1
    80004a18:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a1a:	0001d517          	auipc	a0,0x1d
    80004a1e:	2e650513          	addi	a0,a0,742 # 80021d00 <ftable>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	276080e7          	jalr	630(ra) # 80000c98 <release>
}
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	60e2                	ld	ra,24(sp)
    80004a2e:	6442                	ld	s0,16(sp)
    80004a30:	64a2                	ld	s1,8(sp)
    80004a32:	6105                	addi	sp,sp,32
    80004a34:	8082                	ret

0000000080004a36 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a36:	1101                	addi	sp,sp,-32
    80004a38:	ec06                	sd	ra,24(sp)
    80004a3a:	e822                	sd	s0,16(sp)
    80004a3c:	e426                	sd	s1,8(sp)
    80004a3e:	1000                	addi	s0,sp,32
    80004a40:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a42:	0001d517          	auipc	a0,0x1d
    80004a46:	2be50513          	addi	a0,a0,702 # 80021d00 <ftable>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	19a080e7          	jalr	410(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a52:	40dc                	lw	a5,4(s1)
    80004a54:	02f05263          	blez	a5,80004a78 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a58:	2785                	addiw	a5,a5,1
    80004a5a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a5c:	0001d517          	auipc	a0,0x1d
    80004a60:	2a450513          	addi	a0,a0,676 # 80021d00 <ftable>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
  return f;
}
    80004a6c:	8526                	mv	a0,s1
    80004a6e:	60e2                	ld	ra,24(sp)
    80004a70:	6442                	ld	s0,16(sp)
    80004a72:	64a2                	ld	s1,8(sp)
    80004a74:	6105                	addi	sp,sp,32
    80004a76:	8082                	ret
    panic("filedup");
    80004a78:	00004517          	auipc	a0,0x4
    80004a7c:	c4850513          	addi	a0,a0,-952 # 800086c0 <syscalls+0x250>
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	abe080e7          	jalr	-1346(ra) # 8000053e <panic>

0000000080004a88 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a88:	7139                	addi	sp,sp,-64
    80004a8a:	fc06                	sd	ra,56(sp)
    80004a8c:	f822                	sd	s0,48(sp)
    80004a8e:	f426                	sd	s1,40(sp)
    80004a90:	f04a                	sd	s2,32(sp)
    80004a92:	ec4e                	sd	s3,24(sp)
    80004a94:	e852                	sd	s4,16(sp)
    80004a96:	e456                	sd	s5,8(sp)
    80004a98:	0080                	addi	s0,sp,64
    80004a9a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a9c:	0001d517          	auipc	a0,0x1d
    80004aa0:	26450513          	addi	a0,a0,612 # 80021d00 <ftable>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	140080e7          	jalr	320(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004aac:	40dc                	lw	a5,4(s1)
    80004aae:	06f05163          	blez	a5,80004b10 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ab2:	37fd                	addiw	a5,a5,-1
    80004ab4:	0007871b          	sext.w	a4,a5
    80004ab8:	c0dc                	sw	a5,4(s1)
    80004aba:	06e04363          	bgtz	a4,80004b20 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004abe:	0004a903          	lw	s2,0(s1)
    80004ac2:	0094ca83          	lbu	s5,9(s1)
    80004ac6:	0104ba03          	ld	s4,16(s1)
    80004aca:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ace:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ad2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ad6:	0001d517          	auipc	a0,0x1d
    80004ada:	22a50513          	addi	a0,a0,554 # 80021d00 <ftable>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	1ba080e7          	jalr	442(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004ae6:	4785                	li	a5,1
    80004ae8:	04f90d63          	beq	s2,a5,80004b42 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004aec:	3979                	addiw	s2,s2,-2
    80004aee:	4785                	li	a5,1
    80004af0:	0527e063          	bltu	a5,s2,80004b30 <fileclose+0xa8>
    begin_op();
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	ac8080e7          	jalr	-1336(ra) # 800045bc <begin_op>
    iput(ff.ip);
    80004afc:	854e                	mv	a0,s3
    80004afe:	fffff097          	auipc	ra,0xfffff
    80004b02:	2a6080e7          	jalr	678(ra) # 80003da4 <iput>
    end_op();
    80004b06:	00000097          	auipc	ra,0x0
    80004b0a:	b36080e7          	jalr	-1226(ra) # 8000463c <end_op>
    80004b0e:	a00d                	j	80004b30 <fileclose+0xa8>
    panic("fileclose");
    80004b10:	00004517          	auipc	a0,0x4
    80004b14:	bb850513          	addi	a0,a0,-1096 # 800086c8 <syscalls+0x258>
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	a26080e7          	jalr	-1498(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b20:	0001d517          	auipc	a0,0x1d
    80004b24:	1e050513          	addi	a0,a0,480 # 80021d00 <ftable>
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	170080e7          	jalr	368(ra) # 80000c98 <release>
  }
}
    80004b30:	70e2                	ld	ra,56(sp)
    80004b32:	7442                	ld	s0,48(sp)
    80004b34:	74a2                	ld	s1,40(sp)
    80004b36:	7902                	ld	s2,32(sp)
    80004b38:	69e2                	ld	s3,24(sp)
    80004b3a:	6a42                	ld	s4,16(sp)
    80004b3c:	6aa2                	ld	s5,8(sp)
    80004b3e:	6121                	addi	sp,sp,64
    80004b40:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b42:	85d6                	mv	a1,s5
    80004b44:	8552                	mv	a0,s4
    80004b46:	00000097          	auipc	ra,0x0
    80004b4a:	34c080e7          	jalr	844(ra) # 80004e92 <pipeclose>
    80004b4e:	b7cd                	j	80004b30 <fileclose+0xa8>

0000000080004b50 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b50:	715d                	addi	sp,sp,-80
    80004b52:	e486                	sd	ra,72(sp)
    80004b54:	e0a2                	sd	s0,64(sp)
    80004b56:	fc26                	sd	s1,56(sp)
    80004b58:	f84a                	sd	s2,48(sp)
    80004b5a:	f44e                	sd	s3,40(sp)
    80004b5c:	0880                	addi	s0,sp,80
    80004b5e:	84aa                	mv	s1,a0
    80004b60:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b62:	ffffd097          	auipc	ra,0xffffd
    80004b66:	da6080e7          	jalr	-602(ra) # 80001908 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b6a:	409c                	lw	a5,0(s1)
    80004b6c:	37f9                	addiw	a5,a5,-2
    80004b6e:	4705                	li	a4,1
    80004b70:	04f76763          	bltu	a4,a5,80004bbe <filestat+0x6e>
    80004b74:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b76:	6c88                	ld	a0,24(s1)
    80004b78:	fffff097          	auipc	ra,0xfffff
    80004b7c:	072080e7          	jalr	114(ra) # 80003bea <ilock>
    stati(f->ip, &st);
    80004b80:	fb840593          	addi	a1,s0,-72
    80004b84:	6c88                	ld	a0,24(s1)
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	2ee080e7          	jalr	750(ra) # 80003e74 <stati>
    iunlock(f->ip);
    80004b8e:	6c88                	ld	a0,24(s1)
    80004b90:	fffff097          	auipc	ra,0xfffff
    80004b94:	11c080e7          	jalr	284(ra) # 80003cac <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b98:	46e1                	li	a3,24
    80004b9a:	fb840613          	addi	a2,s0,-72
    80004b9e:	85ce                	mv	a1,s3
    80004ba0:	07093503          	ld	a0,112(s2)
    80004ba4:	ffffd097          	auipc	ra,0xffffd
    80004ba8:	ace080e7          	jalr	-1330(ra) # 80001672 <copyout>
    80004bac:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bb0:	60a6                	ld	ra,72(sp)
    80004bb2:	6406                	ld	s0,64(sp)
    80004bb4:	74e2                	ld	s1,56(sp)
    80004bb6:	7942                	ld	s2,48(sp)
    80004bb8:	79a2                	ld	s3,40(sp)
    80004bba:	6161                	addi	sp,sp,80
    80004bbc:	8082                	ret
  return -1;
    80004bbe:	557d                	li	a0,-1
    80004bc0:	bfc5                	j	80004bb0 <filestat+0x60>

0000000080004bc2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bc2:	7179                	addi	sp,sp,-48
    80004bc4:	f406                	sd	ra,40(sp)
    80004bc6:	f022                	sd	s0,32(sp)
    80004bc8:	ec26                	sd	s1,24(sp)
    80004bca:	e84a                	sd	s2,16(sp)
    80004bcc:	e44e                	sd	s3,8(sp)
    80004bce:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bd0:	00854783          	lbu	a5,8(a0)
    80004bd4:	c3d5                	beqz	a5,80004c78 <fileread+0xb6>
    80004bd6:	84aa                	mv	s1,a0
    80004bd8:	89ae                	mv	s3,a1
    80004bda:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bdc:	411c                	lw	a5,0(a0)
    80004bde:	4705                	li	a4,1
    80004be0:	04e78963          	beq	a5,a4,80004c32 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004be4:	470d                	li	a4,3
    80004be6:	04e78d63          	beq	a5,a4,80004c40 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bea:	4709                	li	a4,2
    80004bec:	06e79e63          	bne	a5,a4,80004c68 <fileread+0xa6>
    ilock(f->ip);
    80004bf0:	6d08                	ld	a0,24(a0)
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	ff8080e7          	jalr	-8(ra) # 80003bea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bfa:	874a                	mv	a4,s2
    80004bfc:	5094                	lw	a3,32(s1)
    80004bfe:	864e                	mv	a2,s3
    80004c00:	4585                	li	a1,1
    80004c02:	6c88                	ld	a0,24(s1)
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	29a080e7          	jalr	666(ra) # 80003e9e <readi>
    80004c0c:	892a                	mv	s2,a0
    80004c0e:	00a05563          	blez	a0,80004c18 <fileread+0x56>
      f->off += r;
    80004c12:	509c                	lw	a5,32(s1)
    80004c14:	9fa9                	addw	a5,a5,a0
    80004c16:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c18:	6c88                	ld	a0,24(s1)
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	092080e7          	jalr	146(ra) # 80003cac <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c22:	854a                	mv	a0,s2
    80004c24:	70a2                	ld	ra,40(sp)
    80004c26:	7402                	ld	s0,32(sp)
    80004c28:	64e2                	ld	s1,24(sp)
    80004c2a:	6942                	ld	s2,16(sp)
    80004c2c:	69a2                	ld	s3,8(sp)
    80004c2e:	6145                	addi	sp,sp,48
    80004c30:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c32:	6908                	ld	a0,16(a0)
    80004c34:	00000097          	auipc	ra,0x0
    80004c38:	3c8080e7          	jalr	968(ra) # 80004ffc <piperead>
    80004c3c:	892a                	mv	s2,a0
    80004c3e:	b7d5                	j	80004c22 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c40:	02451783          	lh	a5,36(a0)
    80004c44:	03079693          	slli	a3,a5,0x30
    80004c48:	92c1                	srli	a3,a3,0x30
    80004c4a:	4725                	li	a4,9
    80004c4c:	02d76863          	bltu	a4,a3,80004c7c <fileread+0xba>
    80004c50:	0792                	slli	a5,a5,0x4
    80004c52:	0001d717          	auipc	a4,0x1d
    80004c56:	00e70713          	addi	a4,a4,14 # 80021c60 <devsw>
    80004c5a:	97ba                	add	a5,a5,a4
    80004c5c:	639c                	ld	a5,0(a5)
    80004c5e:	c38d                	beqz	a5,80004c80 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c60:	4505                	li	a0,1
    80004c62:	9782                	jalr	a5
    80004c64:	892a                	mv	s2,a0
    80004c66:	bf75                	j	80004c22 <fileread+0x60>
    panic("fileread");
    80004c68:	00004517          	auipc	a0,0x4
    80004c6c:	a7050513          	addi	a0,a0,-1424 # 800086d8 <syscalls+0x268>
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	8ce080e7          	jalr	-1842(ra) # 8000053e <panic>
    return -1;
    80004c78:	597d                	li	s2,-1
    80004c7a:	b765                	j	80004c22 <fileread+0x60>
      return -1;
    80004c7c:	597d                	li	s2,-1
    80004c7e:	b755                	j	80004c22 <fileread+0x60>
    80004c80:	597d                	li	s2,-1
    80004c82:	b745                	j	80004c22 <fileread+0x60>

0000000080004c84 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c84:	715d                	addi	sp,sp,-80
    80004c86:	e486                	sd	ra,72(sp)
    80004c88:	e0a2                	sd	s0,64(sp)
    80004c8a:	fc26                	sd	s1,56(sp)
    80004c8c:	f84a                	sd	s2,48(sp)
    80004c8e:	f44e                	sd	s3,40(sp)
    80004c90:	f052                	sd	s4,32(sp)
    80004c92:	ec56                	sd	s5,24(sp)
    80004c94:	e85a                	sd	s6,16(sp)
    80004c96:	e45e                	sd	s7,8(sp)
    80004c98:	e062                	sd	s8,0(sp)
    80004c9a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c9c:	00954783          	lbu	a5,9(a0)
    80004ca0:	10078663          	beqz	a5,80004dac <filewrite+0x128>
    80004ca4:	892a                	mv	s2,a0
    80004ca6:	8aae                	mv	s5,a1
    80004ca8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004caa:	411c                	lw	a5,0(a0)
    80004cac:	4705                	li	a4,1
    80004cae:	02e78263          	beq	a5,a4,80004cd2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cb2:	470d                	li	a4,3
    80004cb4:	02e78663          	beq	a5,a4,80004ce0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cb8:	4709                	li	a4,2
    80004cba:	0ee79163          	bne	a5,a4,80004d9c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cbe:	0ac05d63          	blez	a2,80004d78 <filewrite+0xf4>
    int i = 0;
    80004cc2:	4981                	li	s3,0
    80004cc4:	6b05                	lui	s6,0x1
    80004cc6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cca:	6b85                	lui	s7,0x1
    80004ccc:	c00b8b9b          	addiw	s7,s7,-1024
    80004cd0:	a861                	j	80004d68 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cd2:	6908                	ld	a0,16(a0)
    80004cd4:	00000097          	auipc	ra,0x0
    80004cd8:	22e080e7          	jalr	558(ra) # 80004f02 <pipewrite>
    80004cdc:	8a2a                	mv	s4,a0
    80004cde:	a045                	j	80004d7e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ce0:	02451783          	lh	a5,36(a0)
    80004ce4:	03079693          	slli	a3,a5,0x30
    80004ce8:	92c1                	srli	a3,a3,0x30
    80004cea:	4725                	li	a4,9
    80004cec:	0cd76263          	bltu	a4,a3,80004db0 <filewrite+0x12c>
    80004cf0:	0792                	slli	a5,a5,0x4
    80004cf2:	0001d717          	auipc	a4,0x1d
    80004cf6:	f6e70713          	addi	a4,a4,-146 # 80021c60 <devsw>
    80004cfa:	97ba                	add	a5,a5,a4
    80004cfc:	679c                	ld	a5,8(a5)
    80004cfe:	cbdd                	beqz	a5,80004db4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d00:	4505                	li	a0,1
    80004d02:	9782                	jalr	a5
    80004d04:	8a2a                	mv	s4,a0
    80004d06:	a8a5                	j	80004d7e <filewrite+0xfa>
    80004d08:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d0c:	00000097          	auipc	ra,0x0
    80004d10:	8b0080e7          	jalr	-1872(ra) # 800045bc <begin_op>
      ilock(f->ip);
    80004d14:	01893503          	ld	a0,24(s2)
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	ed2080e7          	jalr	-302(ra) # 80003bea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d20:	8762                	mv	a4,s8
    80004d22:	02092683          	lw	a3,32(s2)
    80004d26:	01598633          	add	a2,s3,s5
    80004d2a:	4585                	li	a1,1
    80004d2c:	01893503          	ld	a0,24(s2)
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	266080e7          	jalr	614(ra) # 80003f96 <writei>
    80004d38:	84aa                	mv	s1,a0
    80004d3a:	00a05763          	blez	a0,80004d48 <filewrite+0xc4>
        f->off += r;
    80004d3e:	02092783          	lw	a5,32(s2)
    80004d42:	9fa9                	addw	a5,a5,a0
    80004d44:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d48:	01893503          	ld	a0,24(s2)
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	f60080e7          	jalr	-160(ra) # 80003cac <iunlock>
      end_op();
    80004d54:	00000097          	auipc	ra,0x0
    80004d58:	8e8080e7          	jalr	-1816(ra) # 8000463c <end_op>

      if(r != n1){
    80004d5c:	009c1f63          	bne	s8,s1,80004d7a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d60:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d64:	0149db63          	bge	s3,s4,80004d7a <filewrite+0xf6>
      int n1 = n - i;
    80004d68:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d6c:	84be                	mv	s1,a5
    80004d6e:	2781                	sext.w	a5,a5
    80004d70:	f8fb5ce3          	bge	s6,a5,80004d08 <filewrite+0x84>
    80004d74:	84de                	mv	s1,s7
    80004d76:	bf49                	j	80004d08 <filewrite+0x84>
    int i = 0;
    80004d78:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d7a:	013a1f63          	bne	s4,s3,80004d98 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d7e:	8552                	mv	a0,s4
    80004d80:	60a6                	ld	ra,72(sp)
    80004d82:	6406                	ld	s0,64(sp)
    80004d84:	74e2                	ld	s1,56(sp)
    80004d86:	7942                	ld	s2,48(sp)
    80004d88:	79a2                	ld	s3,40(sp)
    80004d8a:	7a02                	ld	s4,32(sp)
    80004d8c:	6ae2                	ld	s5,24(sp)
    80004d8e:	6b42                	ld	s6,16(sp)
    80004d90:	6ba2                	ld	s7,8(sp)
    80004d92:	6c02                	ld	s8,0(sp)
    80004d94:	6161                	addi	sp,sp,80
    80004d96:	8082                	ret
    ret = (i == n ? n : -1);
    80004d98:	5a7d                	li	s4,-1
    80004d9a:	b7d5                	j	80004d7e <filewrite+0xfa>
    panic("filewrite");
    80004d9c:	00004517          	auipc	a0,0x4
    80004da0:	94c50513          	addi	a0,a0,-1716 # 800086e8 <syscalls+0x278>
    80004da4:	ffffb097          	auipc	ra,0xffffb
    80004da8:	79a080e7          	jalr	1946(ra) # 8000053e <panic>
    return -1;
    80004dac:	5a7d                	li	s4,-1
    80004dae:	bfc1                	j	80004d7e <filewrite+0xfa>
      return -1;
    80004db0:	5a7d                	li	s4,-1
    80004db2:	b7f1                	j	80004d7e <filewrite+0xfa>
    80004db4:	5a7d                	li	s4,-1
    80004db6:	b7e1                	j	80004d7e <filewrite+0xfa>

0000000080004db8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004db8:	7179                	addi	sp,sp,-48
    80004dba:	f406                	sd	ra,40(sp)
    80004dbc:	f022                	sd	s0,32(sp)
    80004dbe:	ec26                	sd	s1,24(sp)
    80004dc0:	e84a                	sd	s2,16(sp)
    80004dc2:	e44e                	sd	s3,8(sp)
    80004dc4:	e052                	sd	s4,0(sp)
    80004dc6:	1800                	addi	s0,sp,48
    80004dc8:	84aa                	mv	s1,a0
    80004dca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dcc:	0005b023          	sd	zero,0(a1)
    80004dd0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dd4:	00000097          	auipc	ra,0x0
    80004dd8:	bf8080e7          	jalr	-1032(ra) # 800049cc <filealloc>
    80004ddc:	e088                	sd	a0,0(s1)
    80004dde:	c551                	beqz	a0,80004e6a <pipealloc+0xb2>
    80004de0:	00000097          	auipc	ra,0x0
    80004de4:	bec080e7          	jalr	-1044(ra) # 800049cc <filealloc>
    80004de8:	00aa3023          	sd	a0,0(s4)
    80004dec:	c92d                	beqz	a0,80004e5e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	d06080e7          	jalr	-762(ra) # 80000af4 <kalloc>
    80004df6:	892a                	mv	s2,a0
    80004df8:	c125                	beqz	a0,80004e58 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004dfa:	4985                	li	s3,1
    80004dfc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e00:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e04:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e08:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e0c:	00004597          	auipc	a1,0x4
    80004e10:	8ec58593          	addi	a1,a1,-1812 # 800086f8 <syscalls+0x288>
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	d40080e7          	jalr	-704(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e1c:	609c                	ld	a5,0(s1)
    80004e1e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e22:	609c                	ld	a5,0(s1)
    80004e24:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e28:	609c                	ld	a5,0(s1)
    80004e2a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e2e:	609c                	ld	a5,0(s1)
    80004e30:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e34:	000a3783          	ld	a5,0(s4)
    80004e38:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e3c:	000a3783          	ld	a5,0(s4)
    80004e40:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e44:	000a3783          	ld	a5,0(s4)
    80004e48:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e4c:	000a3783          	ld	a5,0(s4)
    80004e50:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e54:	4501                	li	a0,0
    80004e56:	a025                	j	80004e7e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e58:	6088                	ld	a0,0(s1)
    80004e5a:	e501                	bnez	a0,80004e62 <pipealloc+0xaa>
    80004e5c:	a039                	j	80004e6a <pipealloc+0xb2>
    80004e5e:	6088                	ld	a0,0(s1)
    80004e60:	c51d                	beqz	a0,80004e8e <pipealloc+0xd6>
    fileclose(*f0);
    80004e62:	00000097          	auipc	ra,0x0
    80004e66:	c26080e7          	jalr	-986(ra) # 80004a88 <fileclose>
  if(*f1)
    80004e6a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e6e:	557d                	li	a0,-1
  if(*f1)
    80004e70:	c799                	beqz	a5,80004e7e <pipealloc+0xc6>
    fileclose(*f1);
    80004e72:	853e                	mv	a0,a5
    80004e74:	00000097          	auipc	ra,0x0
    80004e78:	c14080e7          	jalr	-1004(ra) # 80004a88 <fileclose>
  return -1;
    80004e7c:	557d                	li	a0,-1
}
    80004e7e:	70a2                	ld	ra,40(sp)
    80004e80:	7402                	ld	s0,32(sp)
    80004e82:	64e2                	ld	s1,24(sp)
    80004e84:	6942                	ld	s2,16(sp)
    80004e86:	69a2                	ld	s3,8(sp)
    80004e88:	6a02                	ld	s4,0(sp)
    80004e8a:	6145                	addi	sp,sp,48
    80004e8c:	8082                	ret
  return -1;
    80004e8e:	557d                	li	a0,-1
    80004e90:	b7fd                	j	80004e7e <pipealloc+0xc6>

0000000080004e92 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e92:	1101                	addi	sp,sp,-32
    80004e94:	ec06                	sd	ra,24(sp)
    80004e96:	e822                	sd	s0,16(sp)
    80004e98:	e426                	sd	s1,8(sp)
    80004e9a:	e04a                	sd	s2,0(sp)
    80004e9c:	1000                	addi	s0,sp,32
    80004e9e:	84aa                	mv	s1,a0
    80004ea0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	d42080e7          	jalr	-702(ra) # 80000be4 <acquire>
  if(writable){
    80004eaa:	02090d63          	beqz	s2,80004ee4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004eae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004eb2:	21848513          	addi	a0,s1,536
    80004eb6:	ffffd097          	auipc	ra,0xffffd
    80004eba:	4f4080e7          	jalr	1268(ra) # 800023aa <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ebe:	2204b783          	ld	a5,544(s1)
    80004ec2:	eb95                	bnez	a5,80004ef6 <pipeclose+0x64>
    release(&pi->lock);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	dd2080e7          	jalr	-558(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ece:	8526                	mv	a0,s1
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	b28080e7          	jalr	-1240(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ed8:	60e2                	ld	ra,24(sp)
    80004eda:	6442                	ld	s0,16(sp)
    80004edc:	64a2                	ld	s1,8(sp)
    80004ede:	6902                	ld	s2,0(sp)
    80004ee0:	6105                	addi	sp,sp,32
    80004ee2:	8082                	ret
    pi->readopen = 0;
    80004ee4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ee8:	21c48513          	addi	a0,s1,540
    80004eec:	ffffd097          	auipc	ra,0xffffd
    80004ef0:	4be080e7          	jalr	1214(ra) # 800023aa <wakeup>
    80004ef4:	b7e9                	j	80004ebe <pipeclose+0x2c>
    release(&pi->lock);
    80004ef6:	8526                	mv	a0,s1
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	da0080e7          	jalr	-608(ra) # 80000c98 <release>
}
    80004f00:	bfe1                	j	80004ed8 <pipeclose+0x46>

0000000080004f02 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f02:	7159                	addi	sp,sp,-112
    80004f04:	f486                	sd	ra,104(sp)
    80004f06:	f0a2                	sd	s0,96(sp)
    80004f08:	eca6                	sd	s1,88(sp)
    80004f0a:	e8ca                	sd	s2,80(sp)
    80004f0c:	e4ce                	sd	s3,72(sp)
    80004f0e:	e0d2                	sd	s4,64(sp)
    80004f10:	fc56                	sd	s5,56(sp)
    80004f12:	f85a                	sd	s6,48(sp)
    80004f14:	f45e                	sd	s7,40(sp)
    80004f16:	f062                	sd	s8,32(sp)
    80004f18:	ec66                	sd	s9,24(sp)
    80004f1a:	1880                	addi	s0,sp,112
    80004f1c:	84aa                	mv	s1,a0
    80004f1e:	8aae                	mv	s5,a1
    80004f20:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	9e6080e7          	jalr	-1562(ra) # 80001908 <myproc>
    80004f2a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f2c:	8526                	mv	a0,s1
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	cb6080e7          	jalr	-842(ra) # 80000be4 <acquire>
  while(i < n){
    80004f36:	0d405163          	blez	s4,80004ff8 <pipewrite+0xf6>
    80004f3a:	8ba6                	mv	s7,s1
  int i = 0;
    80004f3c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f3e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f40:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f44:	21c48c13          	addi	s8,s1,540
    80004f48:	a08d                	j	80004faa <pipewrite+0xa8>
      release(&pi->lock);
    80004f4a:	8526                	mv	a0,s1
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	d4c080e7          	jalr	-692(ra) # 80000c98 <release>
      return -1;
    80004f54:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f56:	854a                	mv	a0,s2
    80004f58:	70a6                	ld	ra,104(sp)
    80004f5a:	7406                	ld	s0,96(sp)
    80004f5c:	64e6                	ld	s1,88(sp)
    80004f5e:	6946                	ld	s2,80(sp)
    80004f60:	69a6                	ld	s3,72(sp)
    80004f62:	6a06                	ld	s4,64(sp)
    80004f64:	7ae2                	ld	s5,56(sp)
    80004f66:	7b42                	ld	s6,48(sp)
    80004f68:	7ba2                	ld	s7,40(sp)
    80004f6a:	7c02                	ld	s8,32(sp)
    80004f6c:	6ce2                	ld	s9,24(sp)
    80004f6e:	6165                	addi	sp,sp,112
    80004f70:	8082                	ret
      wakeup(&pi->nread);
    80004f72:	8566                	mv	a0,s9
    80004f74:	ffffd097          	auipc	ra,0xffffd
    80004f78:	436080e7          	jalr	1078(ra) # 800023aa <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f7c:	85de                	mv	a1,s7
    80004f7e:	8562                	mv	a0,s8
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	0b0080e7          	jalr	176(ra) # 80002030 <sleep>
    80004f88:	a839                	j	80004fa6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f8a:	21c4a783          	lw	a5,540(s1)
    80004f8e:	0017871b          	addiw	a4,a5,1
    80004f92:	20e4ae23          	sw	a4,540(s1)
    80004f96:	1ff7f793          	andi	a5,a5,511
    80004f9a:	97a6                	add	a5,a5,s1
    80004f9c:	f9f44703          	lbu	a4,-97(s0)
    80004fa0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fa4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004fa6:	03495d63          	bge	s2,s4,80004fe0 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004faa:	2204a783          	lw	a5,544(s1)
    80004fae:	dfd1                	beqz	a5,80004f4a <pipewrite+0x48>
    80004fb0:	0289a783          	lw	a5,40(s3)
    80004fb4:	fbd9                	bnez	a5,80004f4a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fb6:	2184a783          	lw	a5,536(s1)
    80004fba:	21c4a703          	lw	a4,540(s1)
    80004fbe:	2007879b          	addiw	a5,a5,512
    80004fc2:	faf708e3          	beq	a4,a5,80004f72 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fc6:	4685                	li	a3,1
    80004fc8:	01590633          	add	a2,s2,s5
    80004fcc:	f9f40593          	addi	a1,s0,-97
    80004fd0:	0709b503          	ld	a0,112(s3)
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	72a080e7          	jalr	1834(ra) # 800016fe <copyin>
    80004fdc:	fb6517e3          	bne	a0,s6,80004f8a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004fe0:	21848513          	addi	a0,s1,536
    80004fe4:	ffffd097          	auipc	ra,0xffffd
    80004fe8:	3c6080e7          	jalr	966(ra) # 800023aa <wakeup>
  release(&pi->lock);
    80004fec:	8526                	mv	a0,s1
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	caa080e7          	jalr	-854(ra) # 80000c98 <release>
  return i;
    80004ff6:	b785                	j	80004f56 <pipewrite+0x54>
  int i = 0;
    80004ff8:	4901                	li	s2,0
    80004ffa:	b7dd                	j	80004fe0 <pipewrite+0xde>

0000000080004ffc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ffc:	715d                	addi	sp,sp,-80
    80004ffe:	e486                	sd	ra,72(sp)
    80005000:	e0a2                	sd	s0,64(sp)
    80005002:	fc26                	sd	s1,56(sp)
    80005004:	f84a                	sd	s2,48(sp)
    80005006:	f44e                	sd	s3,40(sp)
    80005008:	f052                	sd	s4,32(sp)
    8000500a:	ec56                	sd	s5,24(sp)
    8000500c:	e85a                	sd	s6,16(sp)
    8000500e:	0880                	addi	s0,sp,80
    80005010:	84aa                	mv	s1,a0
    80005012:	892e                	mv	s2,a1
    80005014:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	8f2080e7          	jalr	-1806(ra) # 80001908 <myproc>
    8000501e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005020:	8b26                	mv	s6,s1
    80005022:	8526                	mv	a0,s1
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	bc0080e7          	jalr	-1088(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000502c:	2184a703          	lw	a4,536(s1)
    80005030:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005034:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005038:	02f71463          	bne	a4,a5,80005060 <piperead+0x64>
    8000503c:	2244a783          	lw	a5,548(s1)
    80005040:	c385                	beqz	a5,80005060 <piperead+0x64>
    if(pr->killed){
    80005042:	028a2783          	lw	a5,40(s4)
    80005046:	ebc1                	bnez	a5,800050d6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005048:	85da                	mv	a1,s6
    8000504a:	854e                	mv	a0,s3
    8000504c:	ffffd097          	auipc	ra,0xffffd
    80005050:	fe4080e7          	jalr	-28(ra) # 80002030 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005054:	2184a703          	lw	a4,536(s1)
    80005058:	21c4a783          	lw	a5,540(s1)
    8000505c:	fef700e3          	beq	a4,a5,8000503c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005060:	09505263          	blez	s5,800050e4 <piperead+0xe8>
    80005064:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005066:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005068:	2184a783          	lw	a5,536(s1)
    8000506c:	21c4a703          	lw	a4,540(s1)
    80005070:	02f70d63          	beq	a4,a5,800050aa <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005074:	0017871b          	addiw	a4,a5,1
    80005078:	20e4ac23          	sw	a4,536(s1)
    8000507c:	1ff7f793          	andi	a5,a5,511
    80005080:	97a6                	add	a5,a5,s1
    80005082:	0187c783          	lbu	a5,24(a5)
    80005086:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000508a:	4685                	li	a3,1
    8000508c:	fbf40613          	addi	a2,s0,-65
    80005090:	85ca                	mv	a1,s2
    80005092:	070a3503          	ld	a0,112(s4)
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	5dc080e7          	jalr	1500(ra) # 80001672 <copyout>
    8000509e:	01650663          	beq	a0,s6,800050aa <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050a2:	2985                	addiw	s3,s3,1
    800050a4:	0905                	addi	s2,s2,1
    800050a6:	fd3a91e3          	bne	s5,s3,80005068 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050aa:	21c48513          	addi	a0,s1,540
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	2fc080e7          	jalr	764(ra) # 800023aa <wakeup>
  release(&pi->lock);
    800050b6:	8526                	mv	a0,s1
    800050b8:	ffffc097          	auipc	ra,0xffffc
    800050bc:	be0080e7          	jalr	-1056(ra) # 80000c98 <release>
  return i;
}
    800050c0:	854e                	mv	a0,s3
    800050c2:	60a6                	ld	ra,72(sp)
    800050c4:	6406                	ld	s0,64(sp)
    800050c6:	74e2                	ld	s1,56(sp)
    800050c8:	7942                	ld	s2,48(sp)
    800050ca:	79a2                	ld	s3,40(sp)
    800050cc:	7a02                	ld	s4,32(sp)
    800050ce:	6ae2                	ld	s5,24(sp)
    800050d0:	6b42                	ld	s6,16(sp)
    800050d2:	6161                	addi	sp,sp,80
    800050d4:	8082                	ret
      release(&pi->lock);
    800050d6:	8526                	mv	a0,s1
    800050d8:	ffffc097          	auipc	ra,0xffffc
    800050dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
      return -1;
    800050e0:	59fd                	li	s3,-1
    800050e2:	bff9                	j	800050c0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050e4:	4981                	li	s3,0
    800050e6:	b7d1                	j	800050aa <piperead+0xae>

00000000800050e8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050e8:	df010113          	addi	sp,sp,-528
    800050ec:	20113423          	sd	ra,520(sp)
    800050f0:	20813023          	sd	s0,512(sp)
    800050f4:	ffa6                	sd	s1,504(sp)
    800050f6:	fbca                	sd	s2,496(sp)
    800050f8:	f7ce                	sd	s3,488(sp)
    800050fa:	f3d2                	sd	s4,480(sp)
    800050fc:	efd6                	sd	s5,472(sp)
    800050fe:	ebda                	sd	s6,464(sp)
    80005100:	e7de                	sd	s7,456(sp)
    80005102:	e3e2                	sd	s8,448(sp)
    80005104:	ff66                	sd	s9,440(sp)
    80005106:	fb6a                	sd	s10,432(sp)
    80005108:	f76e                	sd	s11,424(sp)
    8000510a:	0c00                	addi	s0,sp,528
    8000510c:	84aa                	mv	s1,a0
    8000510e:	dea43c23          	sd	a0,-520(s0)
    80005112:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005116:	ffffc097          	auipc	ra,0xffffc
    8000511a:	7f2080e7          	jalr	2034(ra) # 80001908 <myproc>
    8000511e:	892a                	mv	s2,a0

  begin_op();
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	49c080e7          	jalr	1180(ra) # 800045bc <begin_op>

  if((ip = namei(path)) == 0){
    80005128:	8526                	mv	a0,s1
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	276080e7          	jalr	630(ra) # 800043a0 <namei>
    80005132:	c92d                	beqz	a0,800051a4 <exec+0xbc>
    80005134:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	ab4080e7          	jalr	-1356(ra) # 80003bea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000513e:	04000713          	li	a4,64
    80005142:	4681                	li	a3,0
    80005144:	e5040613          	addi	a2,s0,-432
    80005148:	4581                	li	a1,0
    8000514a:	8526                	mv	a0,s1
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	d52080e7          	jalr	-686(ra) # 80003e9e <readi>
    80005154:	04000793          	li	a5,64
    80005158:	00f51a63          	bne	a0,a5,8000516c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000515c:	e5042703          	lw	a4,-432(s0)
    80005160:	464c47b7          	lui	a5,0x464c4
    80005164:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005168:	04f70463          	beq	a4,a5,800051b0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000516c:	8526                	mv	a0,s1
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	cde080e7          	jalr	-802(ra) # 80003e4c <iunlockput>
    end_op();
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	4c6080e7          	jalr	1222(ra) # 8000463c <end_op>
  }
  return -1;
    8000517e:	557d                	li	a0,-1
}
    80005180:	20813083          	ld	ra,520(sp)
    80005184:	20013403          	ld	s0,512(sp)
    80005188:	74fe                	ld	s1,504(sp)
    8000518a:	795e                	ld	s2,496(sp)
    8000518c:	79be                	ld	s3,488(sp)
    8000518e:	7a1e                	ld	s4,480(sp)
    80005190:	6afe                	ld	s5,472(sp)
    80005192:	6b5e                	ld	s6,464(sp)
    80005194:	6bbe                	ld	s7,456(sp)
    80005196:	6c1e                	ld	s8,448(sp)
    80005198:	7cfa                	ld	s9,440(sp)
    8000519a:	7d5a                	ld	s10,432(sp)
    8000519c:	7dba                	ld	s11,424(sp)
    8000519e:	21010113          	addi	sp,sp,528
    800051a2:	8082                	ret
    end_op();
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	498080e7          	jalr	1176(ra) # 8000463c <end_op>
    return -1;
    800051ac:	557d                	li	a0,-1
    800051ae:	bfc9                	j	80005180 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051b0:	854a                	mv	a0,s2
    800051b2:	ffffd097          	auipc	ra,0xffffd
    800051b6:	814080e7          	jalr	-2028(ra) # 800019c6 <proc_pagetable>
    800051ba:	8baa                	mv	s7,a0
    800051bc:	d945                	beqz	a0,8000516c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051be:	e7042983          	lw	s3,-400(s0)
    800051c2:	e8845783          	lhu	a5,-376(s0)
    800051c6:	c7ad                	beqz	a5,80005230 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051c8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ca:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800051cc:	6c85                	lui	s9,0x1
    800051ce:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051d2:	def43823          	sd	a5,-528(s0)
    800051d6:	a42d                	j	80005400 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051d8:	00003517          	auipc	a0,0x3
    800051dc:	52850513          	addi	a0,a0,1320 # 80008700 <syscalls+0x290>
    800051e0:	ffffb097          	auipc	ra,0xffffb
    800051e4:	35e080e7          	jalr	862(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051e8:	8756                	mv	a4,s5
    800051ea:	012d86bb          	addw	a3,s11,s2
    800051ee:	4581                	li	a1,0
    800051f0:	8526                	mv	a0,s1
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	cac080e7          	jalr	-852(ra) # 80003e9e <readi>
    800051fa:	2501                	sext.w	a0,a0
    800051fc:	1aaa9963          	bne	s5,a0,800053ae <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005200:	6785                	lui	a5,0x1
    80005202:	0127893b          	addw	s2,a5,s2
    80005206:	77fd                	lui	a5,0xfffff
    80005208:	01478a3b          	addw	s4,a5,s4
    8000520c:	1f897163          	bgeu	s2,s8,800053ee <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005210:	02091593          	slli	a1,s2,0x20
    80005214:	9181                	srli	a1,a1,0x20
    80005216:	95ea                	add	a1,a1,s10
    80005218:	855e                	mv	a0,s7
    8000521a:	ffffc097          	auipc	ra,0xffffc
    8000521e:	e54080e7          	jalr	-428(ra) # 8000106e <walkaddr>
    80005222:	862a                	mv	a2,a0
    if(pa == 0)
    80005224:	d955                	beqz	a0,800051d8 <exec+0xf0>
      n = PGSIZE;
    80005226:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005228:	fd9a70e3          	bgeu	s4,s9,800051e8 <exec+0x100>
      n = sz - i;
    8000522c:	8ad2                	mv	s5,s4
    8000522e:	bf6d                	j	800051e8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005230:	4901                	li	s2,0
  iunlockput(ip);
    80005232:	8526                	mv	a0,s1
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	c18080e7          	jalr	-1000(ra) # 80003e4c <iunlockput>
  end_op();
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	400080e7          	jalr	1024(ra) # 8000463c <end_op>
  p = myproc();
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	6c4080e7          	jalr	1732(ra) # 80001908 <myproc>
    8000524c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000524e:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005252:	6785                	lui	a5,0x1
    80005254:	17fd                	addi	a5,a5,-1
    80005256:	993e                	add	s2,s2,a5
    80005258:	757d                	lui	a0,0xfffff
    8000525a:	00a977b3          	and	a5,s2,a0
    8000525e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005262:	6609                	lui	a2,0x2
    80005264:	963e                	add	a2,a2,a5
    80005266:	85be                	mv	a1,a5
    80005268:	855e                	mv	a0,s7
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	1b8080e7          	jalr	440(ra) # 80001422 <uvmalloc>
    80005272:	8b2a                	mv	s6,a0
  ip = 0;
    80005274:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005276:	12050c63          	beqz	a0,800053ae <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000527a:	75f9                	lui	a1,0xffffe
    8000527c:	95aa                	add	a1,a1,a0
    8000527e:	855e                	mv	a0,s7
    80005280:	ffffc097          	auipc	ra,0xffffc
    80005284:	3c0080e7          	jalr	960(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005288:	7c7d                	lui	s8,0xfffff
    8000528a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000528c:	e0043783          	ld	a5,-512(s0)
    80005290:	6388                	ld	a0,0(a5)
    80005292:	c535                	beqz	a0,800052fe <exec+0x216>
    80005294:	e9040993          	addi	s3,s0,-368
    80005298:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000529c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000529e:	ffffc097          	auipc	ra,0xffffc
    800052a2:	bc6080e7          	jalr	-1082(ra) # 80000e64 <strlen>
    800052a6:	2505                	addiw	a0,a0,1
    800052a8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052ac:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052b0:	13896363          	bltu	s2,s8,800053d6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052b4:	e0043d83          	ld	s11,-512(s0)
    800052b8:	000dba03          	ld	s4,0(s11)
    800052bc:	8552                	mv	a0,s4
    800052be:	ffffc097          	auipc	ra,0xffffc
    800052c2:	ba6080e7          	jalr	-1114(ra) # 80000e64 <strlen>
    800052c6:	0015069b          	addiw	a3,a0,1
    800052ca:	8652                	mv	a2,s4
    800052cc:	85ca                	mv	a1,s2
    800052ce:	855e                	mv	a0,s7
    800052d0:	ffffc097          	auipc	ra,0xffffc
    800052d4:	3a2080e7          	jalr	930(ra) # 80001672 <copyout>
    800052d8:	10054363          	bltz	a0,800053de <exec+0x2f6>
    ustack[argc] = sp;
    800052dc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052e0:	0485                	addi	s1,s1,1
    800052e2:	008d8793          	addi	a5,s11,8
    800052e6:	e0f43023          	sd	a5,-512(s0)
    800052ea:	008db503          	ld	a0,8(s11)
    800052ee:	c911                	beqz	a0,80005302 <exec+0x21a>
    if(argc >= MAXARG)
    800052f0:	09a1                	addi	s3,s3,8
    800052f2:	fb3c96e3          	bne	s9,s3,8000529e <exec+0x1b6>
  sz = sz1;
    800052f6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052fa:	4481                	li	s1,0
    800052fc:	a84d                	j	800053ae <exec+0x2c6>
  sp = sz;
    800052fe:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005300:	4481                	li	s1,0
  ustack[argc] = 0;
    80005302:	00349793          	slli	a5,s1,0x3
    80005306:	f9040713          	addi	a4,s0,-112
    8000530a:	97ba                	add	a5,a5,a4
    8000530c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005310:	00148693          	addi	a3,s1,1
    80005314:	068e                	slli	a3,a3,0x3
    80005316:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000531a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000531e:	01897663          	bgeu	s2,s8,8000532a <exec+0x242>
  sz = sz1;
    80005322:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005326:	4481                	li	s1,0
    80005328:	a059                	j	800053ae <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000532a:	e9040613          	addi	a2,s0,-368
    8000532e:	85ca                	mv	a1,s2
    80005330:	855e                	mv	a0,s7
    80005332:	ffffc097          	auipc	ra,0xffffc
    80005336:	340080e7          	jalr	832(ra) # 80001672 <copyout>
    8000533a:	0a054663          	bltz	a0,800053e6 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000533e:	078ab783          	ld	a5,120(s5)
    80005342:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005346:	df843783          	ld	a5,-520(s0)
    8000534a:	0007c703          	lbu	a4,0(a5)
    8000534e:	cf11                	beqz	a4,8000536a <exec+0x282>
    80005350:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005352:	02f00693          	li	a3,47
    80005356:	a039                	j	80005364 <exec+0x27c>
      last = s+1;
    80005358:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000535c:	0785                	addi	a5,a5,1
    8000535e:	fff7c703          	lbu	a4,-1(a5)
    80005362:	c701                	beqz	a4,8000536a <exec+0x282>
    if(*s == '/')
    80005364:	fed71ce3          	bne	a4,a3,8000535c <exec+0x274>
    80005368:	bfc5                	j	80005358 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000536a:	4641                	li	a2,16
    8000536c:	df843583          	ld	a1,-520(s0)
    80005370:	178a8513          	addi	a0,s5,376
    80005374:	ffffc097          	auipc	ra,0xffffc
    80005378:	abe080e7          	jalr	-1346(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000537c:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005380:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005384:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005388:	078ab783          	ld	a5,120(s5)
    8000538c:	e6843703          	ld	a4,-408(s0)
    80005390:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005392:	078ab783          	ld	a5,120(s5)
    80005396:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000539a:	85ea                	mv	a1,s10
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	6c6080e7          	jalr	1734(ra) # 80001a62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053a4:	0004851b          	sext.w	a0,s1
    800053a8:	bbe1                	j	80005180 <exec+0x98>
    800053aa:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053ae:	e0843583          	ld	a1,-504(s0)
    800053b2:	855e                	mv	a0,s7
    800053b4:	ffffc097          	auipc	ra,0xffffc
    800053b8:	6ae080e7          	jalr	1710(ra) # 80001a62 <proc_freepagetable>
  if(ip){
    800053bc:	da0498e3          	bnez	s1,8000516c <exec+0x84>
  return -1;
    800053c0:	557d                	li	a0,-1
    800053c2:	bb7d                	j	80005180 <exec+0x98>
    800053c4:	e1243423          	sd	s2,-504(s0)
    800053c8:	b7dd                	j	800053ae <exec+0x2c6>
    800053ca:	e1243423          	sd	s2,-504(s0)
    800053ce:	b7c5                	j	800053ae <exec+0x2c6>
    800053d0:	e1243423          	sd	s2,-504(s0)
    800053d4:	bfe9                	j	800053ae <exec+0x2c6>
  sz = sz1;
    800053d6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053da:	4481                	li	s1,0
    800053dc:	bfc9                	j	800053ae <exec+0x2c6>
  sz = sz1;
    800053de:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053e2:	4481                	li	s1,0
    800053e4:	b7e9                	j	800053ae <exec+0x2c6>
  sz = sz1;
    800053e6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053ea:	4481                	li	s1,0
    800053ec:	b7c9                	j	800053ae <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053ee:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053f2:	2b05                	addiw	s6,s6,1
    800053f4:	0389899b          	addiw	s3,s3,56
    800053f8:	e8845783          	lhu	a5,-376(s0)
    800053fc:	e2fb5be3          	bge	s6,a5,80005232 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005400:	2981                	sext.w	s3,s3
    80005402:	03800713          	li	a4,56
    80005406:	86ce                	mv	a3,s3
    80005408:	e1840613          	addi	a2,s0,-488
    8000540c:	4581                	li	a1,0
    8000540e:	8526                	mv	a0,s1
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	a8e080e7          	jalr	-1394(ra) # 80003e9e <readi>
    80005418:	03800793          	li	a5,56
    8000541c:	f8f517e3          	bne	a0,a5,800053aa <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005420:	e1842783          	lw	a5,-488(s0)
    80005424:	4705                	li	a4,1
    80005426:	fce796e3          	bne	a5,a4,800053f2 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000542a:	e4043603          	ld	a2,-448(s0)
    8000542e:	e3843783          	ld	a5,-456(s0)
    80005432:	f8f669e3          	bltu	a2,a5,800053c4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005436:	e2843783          	ld	a5,-472(s0)
    8000543a:	963e                	add	a2,a2,a5
    8000543c:	f8f667e3          	bltu	a2,a5,800053ca <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005440:	85ca                	mv	a1,s2
    80005442:	855e                	mv	a0,s7
    80005444:	ffffc097          	auipc	ra,0xffffc
    80005448:	fde080e7          	jalr	-34(ra) # 80001422 <uvmalloc>
    8000544c:	e0a43423          	sd	a0,-504(s0)
    80005450:	d141                	beqz	a0,800053d0 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005452:	e2843d03          	ld	s10,-472(s0)
    80005456:	df043783          	ld	a5,-528(s0)
    8000545a:	00fd77b3          	and	a5,s10,a5
    8000545e:	fba1                	bnez	a5,800053ae <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005460:	e2042d83          	lw	s11,-480(s0)
    80005464:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005468:	f80c03e3          	beqz	s8,800053ee <exec+0x306>
    8000546c:	8a62                	mv	s4,s8
    8000546e:	4901                	li	s2,0
    80005470:	b345                	j	80005210 <exec+0x128>

0000000080005472 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005472:	7179                	addi	sp,sp,-48
    80005474:	f406                	sd	ra,40(sp)
    80005476:	f022                	sd	s0,32(sp)
    80005478:	ec26                	sd	s1,24(sp)
    8000547a:	e84a                	sd	s2,16(sp)
    8000547c:	1800                	addi	s0,sp,48
    8000547e:	892e                	mv	s2,a1
    80005480:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005482:	fdc40593          	addi	a1,s0,-36
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	ba8080e7          	jalr	-1112(ra) # 8000302e <argint>
    8000548e:	04054063          	bltz	a0,800054ce <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005492:	fdc42703          	lw	a4,-36(s0)
    80005496:	47bd                	li	a5,15
    80005498:	02e7ed63          	bltu	a5,a4,800054d2 <argfd+0x60>
    8000549c:	ffffc097          	auipc	ra,0xffffc
    800054a0:	46c080e7          	jalr	1132(ra) # 80001908 <myproc>
    800054a4:	fdc42703          	lw	a4,-36(s0)
    800054a8:	01e70793          	addi	a5,a4,30
    800054ac:	078e                	slli	a5,a5,0x3
    800054ae:	953e                	add	a0,a0,a5
    800054b0:	611c                	ld	a5,0(a0)
    800054b2:	c395                	beqz	a5,800054d6 <argfd+0x64>
    return -1;
  if(pfd)
    800054b4:	00090463          	beqz	s2,800054bc <argfd+0x4a>
    *pfd = fd;
    800054b8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054bc:	4501                	li	a0,0
  if(pf)
    800054be:	c091                	beqz	s1,800054c2 <argfd+0x50>
    *pf = f;
    800054c0:	e09c                	sd	a5,0(s1)
}
    800054c2:	70a2                	ld	ra,40(sp)
    800054c4:	7402                	ld	s0,32(sp)
    800054c6:	64e2                	ld	s1,24(sp)
    800054c8:	6942                	ld	s2,16(sp)
    800054ca:	6145                	addi	sp,sp,48
    800054cc:	8082                	ret
    return -1;
    800054ce:	557d                	li	a0,-1
    800054d0:	bfcd                	j	800054c2 <argfd+0x50>
    return -1;
    800054d2:	557d                	li	a0,-1
    800054d4:	b7fd                	j	800054c2 <argfd+0x50>
    800054d6:	557d                	li	a0,-1
    800054d8:	b7ed                	j	800054c2 <argfd+0x50>

00000000800054da <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054da:	1101                	addi	sp,sp,-32
    800054dc:	ec06                	sd	ra,24(sp)
    800054de:	e822                	sd	s0,16(sp)
    800054e0:	e426                	sd	s1,8(sp)
    800054e2:	1000                	addi	s0,sp,32
    800054e4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054e6:	ffffc097          	auipc	ra,0xffffc
    800054ea:	422080e7          	jalr	1058(ra) # 80001908 <myproc>
    800054ee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054f0:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    800054f4:	4501                	li	a0,0
    800054f6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054f8:	6398                	ld	a4,0(a5)
    800054fa:	cb19                	beqz	a4,80005510 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054fc:	2505                	addiw	a0,a0,1
    800054fe:	07a1                	addi	a5,a5,8
    80005500:	fed51ce3          	bne	a0,a3,800054f8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005504:	557d                	li	a0,-1
}
    80005506:	60e2                	ld	ra,24(sp)
    80005508:	6442                	ld	s0,16(sp)
    8000550a:	64a2                	ld	s1,8(sp)
    8000550c:	6105                	addi	sp,sp,32
    8000550e:	8082                	ret
      p->ofile[fd] = f;
    80005510:	01e50793          	addi	a5,a0,30
    80005514:	078e                	slli	a5,a5,0x3
    80005516:	963e                	add	a2,a2,a5
    80005518:	e204                	sd	s1,0(a2)
      return fd;
    8000551a:	b7f5                	j	80005506 <fdalloc+0x2c>

000000008000551c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000551c:	715d                	addi	sp,sp,-80
    8000551e:	e486                	sd	ra,72(sp)
    80005520:	e0a2                	sd	s0,64(sp)
    80005522:	fc26                	sd	s1,56(sp)
    80005524:	f84a                	sd	s2,48(sp)
    80005526:	f44e                	sd	s3,40(sp)
    80005528:	f052                	sd	s4,32(sp)
    8000552a:	ec56                	sd	s5,24(sp)
    8000552c:	0880                	addi	s0,sp,80
    8000552e:	89ae                	mv	s3,a1
    80005530:	8ab2                	mv	s5,a2
    80005532:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005534:	fb040593          	addi	a1,s0,-80
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	e86080e7          	jalr	-378(ra) # 800043be <nameiparent>
    80005540:	892a                	mv	s2,a0
    80005542:	12050f63          	beqz	a0,80005680 <create+0x164>
    return 0;

  ilock(dp);
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	6a4080e7          	jalr	1700(ra) # 80003bea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000554e:	4601                	li	a2,0
    80005550:	fb040593          	addi	a1,s0,-80
    80005554:	854a                	mv	a0,s2
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	b78080e7          	jalr	-1160(ra) # 800040ce <dirlookup>
    8000555e:	84aa                	mv	s1,a0
    80005560:	c921                	beqz	a0,800055b0 <create+0x94>
    iunlockput(dp);
    80005562:	854a                	mv	a0,s2
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	8e8080e7          	jalr	-1816(ra) # 80003e4c <iunlockput>
    ilock(ip);
    8000556c:	8526                	mv	a0,s1
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	67c080e7          	jalr	1660(ra) # 80003bea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005576:	2981                	sext.w	s3,s3
    80005578:	4789                	li	a5,2
    8000557a:	02f99463          	bne	s3,a5,800055a2 <create+0x86>
    8000557e:	0444d783          	lhu	a5,68(s1)
    80005582:	37f9                	addiw	a5,a5,-2
    80005584:	17c2                	slli	a5,a5,0x30
    80005586:	93c1                	srli	a5,a5,0x30
    80005588:	4705                	li	a4,1
    8000558a:	00f76c63          	bltu	a4,a5,800055a2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000558e:	8526                	mv	a0,s1
    80005590:	60a6                	ld	ra,72(sp)
    80005592:	6406                	ld	s0,64(sp)
    80005594:	74e2                	ld	s1,56(sp)
    80005596:	7942                	ld	s2,48(sp)
    80005598:	79a2                	ld	s3,40(sp)
    8000559a:	7a02                	ld	s4,32(sp)
    8000559c:	6ae2                	ld	s5,24(sp)
    8000559e:	6161                	addi	sp,sp,80
    800055a0:	8082                	ret
    iunlockput(ip);
    800055a2:	8526                	mv	a0,s1
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	8a8080e7          	jalr	-1880(ra) # 80003e4c <iunlockput>
    return 0;
    800055ac:	4481                	li	s1,0
    800055ae:	b7c5                	j	8000558e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055b0:	85ce                	mv	a1,s3
    800055b2:	00092503          	lw	a0,0(s2)
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	49c080e7          	jalr	1180(ra) # 80003a52 <ialloc>
    800055be:	84aa                	mv	s1,a0
    800055c0:	c529                	beqz	a0,8000560a <create+0xee>
  ilock(ip);
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	628080e7          	jalr	1576(ra) # 80003bea <ilock>
  ip->major = major;
    800055ca:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055ce:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055d2:	4785                	li	a5,1
    800055d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055d8:	8526                	mv	a0,s1
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	546080e7          	jalr	1350(ra) # 80003b20 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055e2:	2981                	sext.w	s3,s3
    800055e4:	4785                	li	a5,1
    800055e6:	02f98a63          	beq	s3,a5,8000561a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800055ea:	40d0                	lw	a2,4(s1)
    800055ec:	fb040593          	addi	a1,s0,-80
    800055f0:	854a                	mv	a0,s2
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	cec080e7          	jalr	-788(ra) # 800042de <dirlink>
    800055fa:	06054b63          	bltz	a0,80005670 <create+0x154>
  iunlockput(dp);
    800055fe:	854a                	mv	a0,s2
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	84c080e7          	jalr	-1972(ra) # 80003e4c <iunlockput>
  return ip;
    80005608:	b759                	j	8000558e <create+0x72>
    panic("create: ialloc");
    8000560a:	00003517          	auipc	a0,0x3
    8000560e:	11650513          	addi	a0,a0,278 # 80008720 <syscalls+0x2b0>
    80005612:	ffffb097          	auipc	ra,0xffffb
    80005616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000561a:	04a95783          	lhu	a5,74(s2)
    8000561e:	2785                	addiw	a5,a5,1
    80005620:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005624:	854a                	mv	a0,s2
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	4fa080e7          	jalr	1274(ra) # 80003b20 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000562e:	40d0                	lw	a2,4(s1)
    80005630:	00003597          	auipc	a1,0x3
    80005634:	10058593          	addi	a1,a1,256 # 80008730 <syscalls+0x2c0>
    80005638:	8526                	mv	a0,s1
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	ca4080e7          	jalr	-860(ra) # 800042de <dirlink>
    80005642:	00054f63          	bltz	a0,80005660 <create+0x144>
    80005646:	00492603          	lw	a2,4(s2)
    8000564a:	00003597          	auipc	a1,0x3
    8000564e:	0ee58593          	addi	a1,a1,238 # 80008738 <syscalls+0x2c8>
    80005652:	8526                	mv	a0,s1
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	c8a080e7          	jalr	-886(ra) # 800042de <dirlink>
    8000565c:	f80557e3          	bgez	a0,800055ea <create+0xce>
      panic("create dots");
    80005660:	00003517          	auipc	a0,0x3
    80005664:	0e050513          	addi	a0,a0,224 # 80008740 <syscalls+0x2d0>
    80005668:	ffffb097          	auipc	ra,0xffffb
    8000566c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005670:	00003517          	auipc	a0,0x3
    80005674:	0e050513          	addi	a0,a0,224 # 80008750 <syscalls+0x2e0>
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	ec6080e7          	jalr	-314(ra) # 8000053e <panic>
    return 0;
    80005680:	84aa                	mv	s1,a0
    80005682:	b731                	j	8000558e <create+0x72>

0000000080005684 <sys_dup>:
{
    80005684:	7179                	addi	sp,sp,-48
    80005686:	f406                	sd	ra,40(sp)
    80005688:	f022                	sd	s0,32(sp)
    8000568a:	ec26                	sd	s1,24(sp)
    8000568c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000568e:	fd840613          	addi	a2,s0,-40
    80005692:	4581                	li	a1,0
    80005694:	4501                	li	a0,0
    80005696:	00000097          	auipc	ra,0x0
    8000569a:	ddc080e7          	jalr	-548(ra) # 80005472 <argfd>
    return -1;
    8000569e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056a0:	02054363          	bltz	a0,800056c6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056a4:	fd843503          	ld	a0,-40(s0)
    800056a8:	00000097          	auipc	ra,0x0
    800056ac:	e32080e7          	jalr	-462(ra) # 800054da <fdalloc>
    800056b0:	84aa                	mv	s1,a0
    return -1;
    800056b2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056b4:	00054963          	bltz	a0,800056c6 <sys_dup+0x42>
  filedup(f);
    800056b8:	fd843503          	ld	a0,-40(s0)
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	37a080e7          	jalr	890(ra) # 80004a36 <filedup>
  return fd;
    800056c4:	87a6                	mv	a5,s1
}
    800056c6:	853e                	mv	a0,a5
    800056c8:	70a2                	ld	ra,40(sp)
    800056ca:	7402                	ld	s0,32(sp)
    800056cc:	64e2                	ld	s1,24(sp)
    800056ce:	6145                	addi	sp,sp,48
    800056d0:	8082                	ret

00000000800056d2 <sys_read>:
{
    800056d2:	7179                	addi	sp,sp,-48
    800056d4:	f406                	sd	ra,40(sp)
    800056d6:	f022                	sd	s0,32(sp)
    800056d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056da:	fe840613          	addi	a2,s0,-24
    800056de:	4581                	li	a1,0
    800056e0:	4501                	li	a0,0
    800056e2:	00000097          	auipc	ra,0x0
    800056e6:	d90080e7          	jalr	-624(ra) # 80005472 <argfd>
    return -1;
    800056ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ec:	04054163          	bltz	a0,8000572e <sys_read+0x5c>
    800056f0:	fe440593          	addi	a1,s0,-28
    800056f4:	4509                	li	a0,2
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	938080e7          	jalr	-1736(ra) # 8000302e <argint>
    return -1;
    800056fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005700:	02054763          	bltz	a0,8000572e <sys_read+0x5c>
    80005704:	fd840593          	addi	a1,s0,-40
    80005708:	4505                	li	a0,1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	946080e7          	jalr	-1722(ra) # 80003050 <argaddr>
    return -1;
    80005712:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005714:	00054d63          	bltz	a0,8000572e <sys_read+0x5c>
  return fileread(f, p, n);
    80005718:	fe442603          	lw	a2,-28(s0)
    8000571c:	fd843583          	ld	a1,-40(s0)
    80005720:	fe843503          	ld	a0,-24(s0)
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	49e080e7          	jalr	1182(ra) # 80004bc2 <fileread>
    8000572c:	87aa                	mv	a5,a0
}
    8000572e:	853e                	mv	a0,a5
    80005730:	70a2                	ld	ra,40(sp)
    80005732:	7402                	ld	s0,32(sp)
    80005734:	6145                	addi	sp,sp,48
    80005736:	8082                	ret

0000000080005738 <sys_write>:
{
    80005738:	7179                	addi	sp,sp,-48
    8000573a:	f406                	sd	ra,40(sp)
    8000573c:	f022                	sd	s0,32(sp)
    8000573e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005740:	fe840613          	addi	a2,s0,-24
    80005744:	4581                	li	a1,0
    80005746:	4501                	li	a0,0
    80005748:	00000097          	auipc	ra,0x0
    8000574c:	d2a080e7          	jalr	-726(ra) # 80005472 <argfd>
    return -1;
    80005750:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005752:	04054163          	bltz	a0,80005794 <sys_write+0x5c>
    80005756:	fe440593          	addi	a1,s0,-28
    8000575a:	4509                	li	a0,2
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	8d2080e7          	jalr	-1838(ra) # 8000302e <argint>
    return -1;
    80005764:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005766:	02054763          	bltz	a0,80005794 <sys_write+0x5c>
    8000576a:	fd840593          	addi	a1,s0,-40
    8000576e:	4505                	li	a0,1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	8e0080e7          	jalr	-1824(ra) # 80003050 <argaddr>
    return -1;
    80005778:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000577a:	00054d63          	bltz	a0,80005794 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000577e:	fe442603          	lw	a2,-28(s0)
    80005782:	fd843583          	ld	a1,-40(s0)
    80005786:	fe843503          	ld	a0,-24(s0)
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	4fa080e7          	jalr	1274(ra) # 80004c84 <filewrite>
    80005792:	87aa                	mv	a5,a0
}
    80005794:	853e                	mv	a0,a5
    80005796:	70a2                	ld	ra,40(sp)
    80005798:	7402                	ld	s0,32(sp)
    8000579a:	6145                	addi	sp,sp,48
    8000579c:	8082                	ret

000000008000579e <sys_close>:
{
    8000579e:	1101                	addi	sp,sp,-32
    800057a0:	ec06                	sd	ra,24(sp)
    800057a2:	e822                	sd	s0,16(sp)
    800057a4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057a6:	fe040613          	addi	a2,s0,-32
    800057aa:	fec40593          	addi	a1,s0,-20
    800057ae:	4501                	li	a0,0
    800057b0:	00000097          	auipc	ra,0x0
    800057b4:	cc2080e7          	jalr	-830(ra) # 80005472 <argfd>
    return -1;
    800057b8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057ba:	02054463          	bltz	a0,800057e2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057be:	ffffc097          	auipc	ra,0xffffc
    800057c2:	14a080e7          	jalr	330(ra) # 80001908 <myproc>
    800057c6:	fec42783          	lw	a5,-20(s0)
    800057ca:	07f9                	addi	a5,a5,30
    800057cc:	078e                	slli	a5,a5,0x3
    800057ce:	97aa                	add	a5,a5,a0
    800057d0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800057d4:	fe043503          	ld	a0,-32(s0)
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	2b0080e7          	jalr	688(ra) # 80004a88 <fileclose>
  return 0;
    800057e0:	4781                	li	a5,0
}
    800057e2:	853e                	mv	a0,a5
    800057e4:	60e2                	ld	ra,24(sp)
    800057e6:	6442                	ld	s0,16(sp)
    800057e8:	6105                	addi	sp,sp,32
    800057ea:	8082                	ret

00000000800057ec <sys_fstat>:
{
    800057ec:	1101                	addi	sp,sp,-32
    800057ee:	ec06                	sd	ra,24(sp)
    800057f0:	e822                	sd	s0,16(sp)
    800057f2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057f4:	fe840613          	addi	a2,s0,-24
    800057f8:	4581                	li	a1,0
    800057fa:	4501                	li	a0,0
    800057fc:	00000097          	auipc	ra,0x0
    80005800:	c76080e7          	jalr	-906(ra) # 80005472 <argfd>
    return -1;
    80005804:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005806:	02054563          	bltz	a0,80005830 <sys_fstat+0x44>
    8000580a:	fe040593          	addi	a1,s0,-32
    8000580e:	4505                	li	a0,1
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	840080e7          	jalr	-1984(ra) # 80003050 <argaddr>
    return -1;
    80005818:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000581a:	00054b63          	bltz	a0,80005830 <sys_fstat+0x44>
  return filestat(f, st);
    8000581e:	fe043583          	ld	a1,-32(s0)
    80005822:	fe843503          	ld	a0,-24(s0)
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	32a080e7          	jalr	810(ra) # 80004b50 <filestat>
    8000582e:	87aa                	mv	a5,a0
}
    80005830:	853e                	mv	a0,a5
    80005832:	60e2                	ld	ra,24(sp)
    80005834:	6442                	ld	s0,16(sp)
    80005836:	6105                	addi	sp,sp,32
    80005838:	8082                	ret

000000008000583a <sys_link>:
{
    8000583a:	7169                	addi	sp,sp,-304
    8000583c:	f606                	sd	ra,296(sp)
    8000583e:	f222                	sd	s0,288(sp)
    80005840:	ee26                	sd	s1,280(sp)
    80005842:	ea4a                	sd	s2,272(sp)
    80005844:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005846:	08000613          	li	a2,128
    8000584a:	ed040593          	addi	a1,s0,-304
    8000584e:	4501                	li	a0,0
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	822080e7          	jalr	-2014(ra) # 80003072 <argstr>
    return -1;
    80005858:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000585a:	10054e63          	bltz	a0,80005976 <sys_link+0x13c>
    8000585e:	08000613          	li	a2,128
    80005862:	f5040593          	addi	a1,s0,-176
    80005866:	4505                	li	a0,1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	80a080e7          	jalr	-2038(ra) # 80003072 <argstr>
    return -1;
    80005870:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005872:	10054263          	bltz	a0,80005976 <sys_link+0x13c>
  begin_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	d46080e7          	jalr	-698(ra) # 800045bc <begin_op>
  if((ip = namei(old)) == 0){
    8000587e:	ed040513          	addi	a0,s0,-304
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	b1e080e7          	jalr	-1250(ra) # 800043a0 <namei>
    8000588a:	84aa                	mv	s1,a0
    8000588c:	c551                	beqz	a0,80005918 <sys_link+0xde>
  ilock(ip);
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	35c080e7          	jalr	860(ra) # 80003bea <ilock>
  if(ip->type == T_DIR){
    80005896:	04449703          	lh	a4,68(s1)
    8000589a:	4785                	li	a5,1
    8000589c:	08f70463          	beq	a4,a5,80005924 <sys_link+0xea>
  ip->nlink++;
    800058a0:	04a4d783          	lhu	a5,74(s1)
    800058a4:	2785                	addiw	a5,a5,1
    800058a6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	274080e7          	jalr	628(ra) # 80003b20 <iupdate>
  iunlock(ip);
    800058b4:	8526                	mv	a0,s1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	3f6080e7          	jalr	1014(ra) # 80003cac <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058be:	fd040593          	addi	a1,s0,-48
    800058c2:	f5040513          	addi	a0,s0,-176
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	af8080e7          	jalr	-1288(ra) # 800043be <nameiparent>
    800058ce:	892a                	mv	s2,a0
    800058d0:	c935                	beqz	a0,80005944 <sys_link+0x10a>
  ilock(dp);
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	318080e7          	jalr	792(ra) # 80003bea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058da:	00092703          	lw	a4,0(s2)
    800058de:	409c                	lw	a5,0(s1)
    800058e0:	04f71d63          	bne	a4,a5,8000593a <sys_link+0x100>
    800058e4:	40d0                	lw	a2,4(s1)
    800058e6:	fd040593          	addi	a1,s0,-48
    800058ea:	854a                	mv	a0,s2
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	9f2080e7          	jalr	-1550(ra) # 800042de <dirlink>
    800058f4:	04054363          	bltz	a0,8000593a <sys_link+0x100>
  iunlockput(dp);
    800058f8:	854a                	mv	a0,s2
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	552080e7          	jalr	1362(ra) # 80003e4c <iunlockput>
  iput(ip);
    80005902:	8526                	mv	a0,s1
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	4a0080e7          	jalr	1184(ra) # 80003da4 <iput>
  end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	d30080e7          	jalr	-720(ra) # 8000463c <end_op>
  return 0;
    80005914:	4781                	li	a5,0
    80005916:	a085                	j	80005976 <sys_link+0x13c>
    end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	d24080e7          	jalr	-732(ra) # 8000463c <end_op>
    return -1;
    80005920:	57fd                	li	a5,-1
    80005922:	a891                	j	80005976 <sys_link+0x13c>
    iunlockput(ip);
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	526080e7          	jalr	1318(ra) # 80003e4c <iunlockput>
    end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	d0e080e7          	jalr	-754(ra) # 8000463c <end_op>
    return -1;
    80005936:	57fd                	li	a5,-1
    80005938:	a83d                	j	80005976 <sys_link+0x13c>
    iunlockput(dp);
    8000593a:	854a                	mv	a0,s2
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	510080e7          	jalr	1296(ra) # 80003e4c <iunlockput>
  ilock(ip);
    80005944:	8526                	mv	a0,s1
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	2a4080e7          	jalr	676(ra) # 80003bea <ilock>
  ip->nlink--;
    8000594e:	04a4d783          	lhu	a5,74(s1)
    80005952:	37fd                	addiw	a5,a5,-1
    80005954:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	1c6080e7          	jalr	454(ra) # 80003b20 <iupdate>
  iunlockput(ip);
    80005962:	8526                	mv	a0,s1
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	4e8080e7          	jalr	1256(ra) # 80003e4c <iunlockput>
  end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	cd0080e7          	jalr	-816(ra) # 8000463c <end_op>
  return -1;
    80005974:	57fd                	li	a5,-1
}
    80005976:	853e                	mv	a0,a5
    80005978:	70b2                	ld	ra,296(sp)
    8000597a:	7412                	ld	s0,288(sp)
    8000597c:	64f2                	ld	s1,280(sp)
    8000597e:	6952                	ld	s2,272(sp)
    80005980:	6155                	addi	sp,sp,304
    80005982:	8082                	ret

0000000080005984 <sys_unlink>:
{
    80005984:	7151                	addi	sp,sp,-240
    80005986:	f586                	sd	ra,232(sp)
    80005988:	f1a2                	sd	s0,224(sp)
    8000598a:	eda6                	sd	s1,216(sp)
    8000598c:	e9ca                	sd	s2,208(sp)
    8000598e:	e5ce                	sd	s3,200(sp)
    80005990:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005992:	08000613          	li	a2,128
    80005996:	f3040593          	addi	a1,s0,-208
    8000599a:	4501                	li	a0,0
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	6d6080e7          	jalr	1750(ra) # 80003072 <argstr>
    800059a4:	18054163          	bltz	a0,80005b26 <sys_unlink+0x1a2>
  begin_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	c14080e7          	jalr	-1004(ra) # 800045bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059b0:	fb040593          	addi	a1,s0,-80
    800059b4:	f3040513          	addi	a0,s0,-208
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	a06080e7          	jalr	-1530(ra) # 800043be <nameiparent>
    800059c0:	84aa                	mv	s1,a0
    800059c2:	c979                	beqz	a0,80005a98 <sys_unlink+0x114>
  ilock(dp);
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	226080e7          	jalr	550(ra) # 80003bea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059cc:	00003597          	auipc	a1,0x3
    800059d0:	d6458593          	addi	a1,a1,-668 # 80008730 <syscalls+0x2c0>
    800059d4:	fb040513          	addi	a0,s0,-80
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	6dc080e7          	jalr	1756(ra) # 800040b4 <namecmp>
    800059e0:	14050a63          	beqz	a0,80005b34 <sys_unlink+0x1b0>
    800059e4:	00003597          	auipc	a1,0x3
    800059e8:	d5458593          	addi	a1,a1,-684 # 80008738 <syscalls+0x2c8>
    800059ec:	fb040513          	addi	a0,s0,-80
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	6c4080e7          	jalr	1732(ra) # 800040b4 <namecmp>
    800059f8:	12050e63          	beqz	a0,80005b34 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059fc:	f2c40613          	addi	a2,s0,-212
    80005a00:	fb040593          	addi	a1,s0,-80
    80005a04:	8526                	mv	a0,s1
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	6c8080e7          	jalr	1736(ra) # 800040ce <dirlookup>
    80005a0e:	892a                	mv	s2,a0
    80005a10:	12050263          	beqz	a0,80005b34 <sys_unlink+0x1b0>
  ilock(ip);
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	1d6080e7          	jalr	470(ra) # 80003bea <ilock>
  if(ip->nlink < 1)
    80005a1c:	04a91783          	lh	a5,74(s2)
    80005a20:	08f05263          	blez	a5,80005aa4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a24:	04491703          	lh	a4,68(s2)
    80005a28:	4785                	li	a5,1
    80005a2a:	08f70563          	beq	a4,a5,80005ab4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a2e:	4641                	li	a2,16
    80005a30:	4581                	li	a1,0
    80005a32:	fc040513          	addi	a0,s0,-64
    80005a36:	ffffb097          	auipc	ra,0xffffb
    80005a3a:	2aa080e7          	jalr	682(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a3e:	4741                	li	a4,16
    80005a40:	f2c42683          	lw	a3,-212(s0)
    80005a44:	fc040613          	addi	a2,s0,-64
    80005a48:	4581                	li	a1,0
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	54a080e7          	jalr	1354(ra) # 80003f96 <writei>
    80005a54:	47c1                	li	a5,16
    80005a56:	0af51563          	bne	a0,a5,80005b00 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a5a:	04491703          	lh	a4,68(s2)
    80005a5e:	4785                	li	a5,1
    80005a60:	0af70863          	beq	a4,a5,80005b10 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a64:	8526                	mv	a0,s1
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	3e6080e7          	jalr	998(ra) # 80003e4c <iunlockput>
  ip->nlink--;
    80005a6e:	04a95783          	lhu	a5,74(s2)
    80005a72:	37fd                	addiw	a5,a5,-1
    80005a74:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a78:	854a                	mv	a0,s2
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	0a6080e7          	jalr	166(ra) # 80003b20 <iupdate>
  iunlockput(ip);
    80005a82:	854a                	mv	a0,s2
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	3c8080e7          	jalr	968(ra) # 80003e4c <iunlockput>
  end_op();
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	bb0080e7          	jalr	-1104(ra) # 8000463c <end_op>
  return 0;
    80005a94:	4501                	li	a0,0
    80005a96:	a84d                	j	80005b48 <sys_unlink+0x1c4>
    end_op();
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	ba4080e7          	jalr	-1116(ra) # 8000463c <end_op>
    return -1;
    80005aa0:	557d                	li	a0,-1
    80005aa2:	a05d                	j	80005b48 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005aa4:	00003517          	auipc	a0,0x3
    80005aa8:	cbc50513          	addi	a0,a0,-836 # 80008760 <syscalls+0x2f0>
    80005aac:	ffffb097          	auipc	ra,0xffffb
    80005ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ab4:	04c92703          	lw	a4,76(s2)
    80005ab8:	02000793          	li	a5,32
    80005abc:	f6e7f9e3          	bgeu	a5,a4,80005a2e <sys_unlink+0xaa>
    80005ac0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ac4:	4741                	li	a4,16
    80005ac6:	86ce                	mv	a3,s3
    80005ac8:	f1840613          	addi	a2,s0,-232
    80005acc:	4581                	li	a1,0
    80005ace:	854a                	mv	a0,s2
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	3ce080e7          	jalr	974(ra) # 80003e9e <readi>
    80005ad8:	47c1                	li	a5,16
    80005ada:	00f51b63          	bne	a0,a5,80005af0 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ade:	f1845783          	lhu	a5,-232(s0)
    80005ae2:	e7a1                	bnez	a5,80005b2a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ae4:	29c1                	addiw	s3,s3,16
    80005ae6:	04c92783          	lw	a5,76(s2)
    80005aea:	fcf9ede3          	bltu	s3,a5,80005ac4 <sys_unlink+0x140>
    80005aee:	b781                	j	80005a2e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005af0:	00003517          	auipc	a0,0x3
    80005af4:	c8850513          	addi	a0,a0,-888 # 80008778 <syscalls+0x308>
    80005af8:	ffffb097          	auipc	ra,0xffffb
    80005afc:	a46080e7          	jalr	-1466(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b00:	00003517          	auipc	a0,0x3
    80005b04:	c9050513          	addi	a0,a0,-880 # 80008790 <syscalls+0x320>
    80005b08:	ffffb097          	auipc	ra,0xffffb
    80005b0c:	a36080e7          	jalr	-1482(ra) # 8000053e <panic>
    dp->nlink--;
    80005b10:	04a4d783          	lhu	a5,74(s1)
    80005b14:	37fd                	addiw	a5,a5,-1
    80005b16:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	004080e7          	jalr	4(ra) # 80003b20 <iupdate>
    80005b24:	b781                	j	80005a64 <sys_unlink+0xe0>
    return -1;
    80005b26:	557d                	li	a0,-1
    80005b28:	a005                	j	80005b48 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b2a:	854a                	mv	a0,s2
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	320080e7          	jalr	800(ra) # 80003e4c <iunlockput>
  iunlockput(dp);
    80005b34:	8526                	mv	a0,s1
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	316080e7          	jalr	790(ra) # 80003e4c <iunlockput>
  end_op();
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	afe080e7          	jalr	-1282(ra) # 8000463c <end_op>
  return -1;
    80005b46:	557d                	li	a0,-1
}
    80005b48:	70ae                	ld	ra,232(sp)
    80005b4a:	740e                	ld	s0,224(sp)
    80005b4c:	64ee                	ld	s1,216(sp)
    80005b4e:	694e                	ld	s2,208(sp)
    80005b50:	69ae                	ld	s3,200(sp)
    80005b52:	616d                	addi	sp,sp,240
    80005b54:	8082                	ret

0000000080005b56 <sys_open>:

uint64
sys_open(void)
{
    80005b56:	7131                	addi	sp,sp,-192
    80005b58:	fd06                	sd	ra,184(sp)
    80005b5a:	f922                	sd	s0,176(sp)
    80005b5c:	f526                	sd	s1,168(sp)
    80005b5e:	f14a                	sd	s2,160(sp)
    80005b60:	ed4e                	sd	s3,152(sp)
    80005b62:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b64:	08000613          	li	a2,128
    80005b68:	f5040593          	addi	a1,s0,-176
    80005b6c:	4501                	li	a0,0
    80005b6e:	ffffd097          	auipc	ra,0xffffd
    80005b72:	504080e7          	jalr	1284(ra) # 80003072 <argstr>
    return -1;
    80005b76:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b78:	0c054163          	bltz	a0,80005c3a <sys_open+0xe4>
    80005b7c:	f4c40593          	addi	a1,s0,-180
    80005b80:	4505                	li	a0,1
    80005b82:	ffffd097          	auipc	ra,0xffffd
    80005b86:	4ac080e7          	jalr	1196(ra) # 8000302e <argint>
    80005b8a:	0a054863          	bltz	a0,80005c3a <sys_open+0xe4>

  begin_op();
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	a2e080e7          	jalr	-1490(ra) # 800045bc <begin_op>

  if(omode & O_CREATE){
    80005b96:	f4c42783          	lw	a5,-180(s0)
    80005b9a:	2007f793          	andi	a5,a5,512
    80005b9e:	cbdd                	beqz	a5,80005c54 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ba0:	4681                	li	a3,0
    80005ba2:	4601                	li	a2,0
    80005ba4:	4589                	li	a1,2
    80005ba6:	f5040513          	addi	a0,s0,-176
    80005baa:	00000097          	auipc	ra,0x0
    80005bae:	972080e7          	jalr	-1678(ra) # 8000551c <create>
    80005bb2:	892a                	mv	s2,a0
    if(ip == 0){
    80005bb4:	c959                	beqz	a0,80005c4a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bb6:	04491703          	lh	a4,68(s2)
    80005bba:	478d                	li	a5,3
    80005bbc:	00f71763          	bne	a4,a5,80005bca <sys_open+0x74>
    80005bc0:	04695703          	lhu	a4,70(s2)
    80005bc4:	47a5                	li	a5,9
    80005bc6:	0ce7ec63          	bltu	a5,a4,80005c9e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	e02080e7          	jalr	-510(ra) # 800049cc <filealloc>
    80005bd2:	89aa                	mv	s3,a0
    80005bd4:	10050263          	beqz	a0,80005cd8 <sys_open+0x182>
    80005bd8:	00000097          	auipc	ra,0x0
    80005bdc:	902080e7          	jalr	-1790(ra) # 800054da <fdalloc>
    80005be0:	84aa                	mv	s1,a0
    80005be2:	0e054663          	bltz	a0,80005cce <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005be6:	04491703          	lh	a4,68(s2)
    80005bea:	478d                	li	a5,3
    80005bec:	0cf70463          	beq	a4,a5,80005cb4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bf0:	4789                	li	a5,2
    80005bf2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bf6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005bfa:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bfe:	f4c42783          	lw	a5,-180(s0)
    80005c02:	0017c713          	xori	a4,a5,1
    80005c06:	8b05                	andi	a4,a4,1
    80005c08:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c0c:	0037f713          	andi	a4,a5,3
    80005c10:	00e03733          	snez	a4,a4
    80005c14:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c18:	4007f793          	andi	a5,a5,1024
    80005c1c:	c791                	beqz	a5,80005c28 <sys_open+0xd2>
    80005c1e:	04491703          	lh	a4,68(s2)
    80005c22:	4789                	li	a5,2
    80005c24:	08f70f63          	beq	a4,a5,80005cc2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c28:	854a                	mv	a0,s2
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	082080e7          	jalr	130(ra) # 80003cac <iunlock>
  end_op();
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	a0a080e7          	jalr	-1526(ra) # 8000463c <end_op>

  return fd;
}
    80005c3a:	8526                	mv	a0,s1
    80005c3c:	70ea                	ld	ra,184(sp)
    80005c3e:	744a                	ld	s0,176(sp)
    80005c40:	74aa                	ld	s1,168(sp)
    80005c42:	790a                	ld	s2,160(sp)
    80005c44:	69ea                	ld	s3,152(sp)
    80005c46:	6129                	addi	sp,sp,192
    80005c48:	8082                	ret
      end_op();
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	9f2080e7          	jalr	-1550(ra) # 8000463c <end_op>
      return -1;
    80005c52:	b7e5                	j	80005c3a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c54:	f5040513          	addi	a0,s0,-176
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	748080e7          	jalr	1864(ra) # 800043a0 <namei>
    80005c60:	892a                	mv	s2,a0
    80005c62:	c905                	beqz	a0,80005c92 <sys_open+0x13c>
    ilock(ip);
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	f86080e7          	jalr	-122(ra) # 80003bea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c6c:	04491703          	lh	a4,68(s2)
    80005c70:	4785                	li	a5,1
    80005c72:	f4f712e3          	bne	a4,a5,80005bb6 <sys_open+0x60>
    80005c76:	f4c42783          	lw	a5,-180(s0)
    80005c7a:	dba1                	beqz	a5,80005bca <sys_open+0x74>
      iunlockput(ip);
    80005c7c:	854a                	mv	a0,s2
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	1ce080e7          	jalr	462(ra) # 80003e4c <iunlockput>
      end_op();
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	9b6080e7          	jalr	-1610(ra) # 8000463c <end_op>
      return -1;
    80005c8e:	54fd                	li	s1,-1
    80005c90:	b76d                	j	80005c3a <sys_open+0xe4>
      end_op();
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	9aa080e7          	jalr	-1622(ra) # 8000463c <end_op>
      return -1;
    80005c9a:	54fd                	li	s1,-1
    80005c9c:	bf79                	j	80005c3a <sys_open+0xe4>
    iunlockput(ip);
    80005c9e:	854a                	mv	a0,s2
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	1ac080e7          	jalr	428(ra) # 80003e4c <iunlockput>
    end_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	994080e7          	jalr	-1644(ra) # 8000463c <end_op>
    return -1;
    80005cb0:	54fd                	li	s1,-1
    80005cb2:	b761                	j	80005c3a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cb4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cb8:	04691783          	lh	a5,70(s2)
    80005cbc:	02f99223          	sh	a5,36(s3)
    80005cc0:	bf2d                	j	80005bfa <sys_open+0xa4>
    itrunc(ip);
    80005cc2:	854a                	mv	a0,s2
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	034080e7          	jalr	52(ra) # 80003cf8 <itrunc>
    80005ccc:	bfb1                	j	80005c28 <sys_open+0xd2>
      fileclose(f);
    80005cce:	854e                	mv	a0,s3
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	db8080e7          	jalr	-584(ra) # 80004a88 <fileclose>
    iunlockput(ip);
    80005cd8:	854a                	mv	a0,s2
    80005cda:	ffffe097          	auipc	ra,0xffffe
    80005cde:	172080e7          	jalr	370(ra) # 80003e4c <iunlockput>
    end_op();
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	95a080e7          	jalr	-1702(ra) # 8000463c <end_op>
    return -1;
    80005cea:	54fd                	li	s1,-1
    80005cec:	b7b9                	j	80005c3a <sys_open+0xe4>

0000000080005cee <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cee:	7175                	addi	sp,sp,-144
    80005cf0:	e506                	sd	ra,136(sp)
    80005cf2:	e122                	sd	s0,128(sp)
    80005cf4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	8c6080e7          	jalr	-1850(ra) # 800045bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cfe:	08000613          	li	a2,128
    80005d02:	f7040593          	addi	a1,s0,-144
    80005d06:	4501                	li	a0,0
    80005d08:	ffffd097          	auipc	ra,0xffffd
    80005d0c:	36a080e7          	jalr	874(ra) # 80003072 <argstr>
    80005d10:	02054963          	bltz	a0,80005d42 <sys_mkdir+0x54>
    80005d14:	4681                	li	a3,0
    80005d16:	4601                	li	a2,0
    80005d18:	4585                	li	a1,1
    80005d1a:	f7040513          	addi	a0,s0,-144
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	7fe080e7          	jalr	2046(ra) # 8000551c <create>
    80005d26:	cd11                	beqz	a0,80005d42 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	124080e7          	jalr	292(ra) # 80003e4c <iunlockput>
  end_op();
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	90c080e7          	jalr	-1780(ra) # 8000463c <end_op>
  return 0;
    80005d38:	4501                	li	a0,0
}
    80005d3a:	60aa                	ld	ra,136(sp)
    80005d3c:	640a                	ld	s0,128(sp)
    80005d3e:	6149                	addi	sp,sp,144
    80005d40:	8082                	ret
    end_op();
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	8fa080e7          	jalr	-1798(ra) # 8000463c <end_op>
    return -1;
    80005d4a:	557d                	li	a0,-1
    80005d4c:	b7fd                	j	80005d3a <sys_mkdir+0x4c>

0000000080005d4e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d4e:	7135                	addi	sp,sp,-160
    80005d50:	ed06                	sd	ra,152(sp)
    80005d52:	e922                	sd	s0,144(sp)
    80005d54:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	866080e7          	jalr	-1946(ra) # 800045bc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d5e:	08000613          	li	a2,128
    80005d62:	f7040593          	addi	a1,s0,-144
    80005d66:	4501                	li	a0,0
    80005d68:	ffffd097          	auipc	ra,0xffffd
    80005d6c:	30a080e7          	jalr	778(ra) # 80003072 <argstr>
    80005d70:	04054a63          	bltz	a0,80005dc4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d74:	f6c40593          	addi	a1,s0,-148
    80005d78:	4505                	li	a0,1
    80005d7a:	ffffd097          	auipc	ra,0xffffd
    80005d7e:	2b4080e7          	jalr	692(ra) # 8000302e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d82:	04054163          	bltz	a0,80005dc4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d86:	f6840593          	addi	a1,s0,-152
    80005d8a:	4509                	li	a0,2
    80005d8c:	ffffd097          	auipc	ra,0xffffd
    80005d90:	2a2080e7          	jalr	674(ra) # 8000302e <argint>
     argint(1, &major) < 0 ||
    80005d94:	02054863          	bltz	a0,80005dc4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d98:	f6841683          	lh	a3,-152(s0)
    80005d9c:	f6c41603          	lh	a2,-148(s0)
    80005da0:	458d                	li	a1,3
    80005da2:	f7040513          	addi	a0,s0,-144
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	776080e7          	jalr	1910(ra) # 8000551c <create>
     argint(2, &minor) < 0 ||
    80005dae:	c919                	beqz	a0,80005dc4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005db0:	ffffe097          	auipc	ra,0xffffe
    80005db4:	09c080e7          	jalr	156(ra) # 80003e4c <iunlockput>
  end_op();
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	884080e7          	jalr	-1916(ra) # 8000463c <end_op>
  return 0;
    80005dc0:	4501                	li	a0,0
    80005dc2:	a031                	j	80005dce <sys_mknod+0x80>
    end_op();
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	878080e7          	jalr	-1928(ra) # 8000463c <end_op>
    return -1;
    80005dcc:	557d                	li	a0,-1
}
    80005dce:	60ea                	ld	ra,152(sp)
    80005dd0:	644a                	ld	s0,144(sp)
    80005dd2:	610d                	addi	sp,sp,160
    80005dd4:	8082                	ret

0000000080005dd6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dd6:	7135                	addi	sp,sp,-160
    80005dd8:	ed06                	sd	ra,152(sp)
    80005dda:	e922                	sd	s0,144(sp)
    80005ddc:	e526                	sd	s1,136(sp)
    80005dde:	e14a                	sd	s2,128(sp)
    80005de0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005de2:	ffffc097          	auipc	ra,0xffffc
    80005de6:	b26080e7          	jalr	-1242(ra) # 80001908 <myproc>
    80005dea:	892a                	mv	s2,a0
  
  begin_op();
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	7d0080e7          	jalr	2000(ra) # 800045bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005df4:	08000613          	li	a2,128
    80005df8:	f6040593          	addi	a1,s0,-160
    80005dfc:	4501                	li	a0,0
    80005dfe:	ffffd097          	auipc	ra,0xffffd
    80005e02:	274080e7          	jalr	628(ra) # 80003072 <argstr>
    80005e06:	04054b63          	bltz	a0,80005e5c <sys_chdir+0x86>
    80005e0a:	f6040513          	addi	a0,s0,-160
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	592080e7          	jalr	1426(ra) # 800043a0 <namei>
    80005e16:	84aa                	mv	s1,a0
    80005e18:	c131                	beqz	a0,80005e5c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e1a:	ffffe097          	auipc	ra,0xffffe
    80005e1e:	dd0080e7          	jalr	-560(ra) # 80003bea <ilock>
  if(ip->type != T_DIR){
    80005e22:	04449703          	lh	a4,68(s1)
    80005e26:	4785                	li	a5,1
    80005e28:	04f71063          	bne	a4,a5,80005e68 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e2c:	8526                	mv	a0,s1
    80005e2e:	ffffe097          	auipc	ra,0xffffe
    80005e32:	e7e080e7          	jalr	-386(ra) # 80003cac <iunlock>
  iput(p->cwd);
    80005e36:	17093503          	ld	a0,368(s2)
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	f6a080e7          	jalr	-150(ra) # 80003da4 <iput>
  end_op();
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	7fa080e7          	jalr	2042(ra) # 8000463c <end_op>
  p->cwd = ip;
    80005e4a:	16993823          	sd	s1,368(s2)
  return 0;
    80005e4e:	4501                	li	a0,0
}
    80005e50:	60ea                	ld	ra,152(sp)
    80005e52:	644a                	ld	s0,144(sp)
    80005e54:	64aa                	ld	s1,136(sp)
    80005e56:	690a                	ld	s2,128(sp)
    80005e58:	610d                	addi	sp,sp,160
    80005e5a:	8082                	ret
    end_op();
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	7e0080e7          	jalr	2016(ra) # 8000463c <end_op>
    return -1;
    80005e64:	557d                	li	a0,-1
    80005e66:	b7ed                	j	80005e50 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e68:	8526                	mv	a0,s1
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	fe2080e7          	jalr	-30(ra) # 80003e4c <iunlockput>
    end_op();
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	7ca080e7          	jalr	1994(ra) # 8000463c <end_op>
    return -1;
    80005e7a:	557d                	li	a0,-1
    80005e7c:	bfd1                	j	80005e50 <sys_chdir+0x7a>

0000000080005e7e <sys_exec>:

uint64
sys_exec(void)
{
    80005e7e:	7145                	addi	sp,sp,-464
    80005e80:	e786                	sd	ra,456(sp)
    80005e82:	e3a2                	sd	s0,448(sp)
    80005e84:	ff26                	sd	s1,440(sp)
    80005e86:	fb4a                	sd	s2,432(sp)
    80005e88:	f74e                	sd	s3,424(sp)
    80005e8a:	f352                	sd	s4,416(sp)
    80005e8c:	ef56                	sd	s5,408(sp)
    80005e8e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e90:	08000613          	li	a2,128
    80005e94:	f4040593          	addi	a1,s0,-192
    80005e98:	4501                	li	a0,0
    80005e9a:	ffffd097          	auipc	ra,0xffffd
    80005e9e:	1d8080e7          	jalr	472(ra) # 80003072 <argstr>
    return -1;
    80005ea2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ea4:	0c054a63          	bltz	a0,80005f78 <sys_exec+0xfa>
    80005ea8:	e3840593          	addi	a1,s0,-456
    80005eac:	4505                	li	a0,1
    80005eae:	ffffd097          	auipc	ra,0xffffd
    80005eb2:	1a2080e7          	jalr	418(ra) # 80003050 <argaddr>
    80005eb6:	0c054163          	bltz	a0,80005f78 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005eba:	10000613          	li	a2,256
    80005ebe:	4581                	li	a1,0
    80005ec0:	e4040513          	addi	a0,s0,-448
    80005ec4:	ffffb097          	auipc	ra,0xffffb
    80005ec8:	e1c080e7          	jalr	-484(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ecc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ed0:	89a6                	mv	s3,s1
    80005ed2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ed4:	02000a13          	li	s4,32
    80005ed8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005edc:	00391513          	slli	a0,s2,0x3
    80005ee0:	e3040593          	addi	a1,s0,-464
    80005ee4:	e3843783          	ld	a5,-456(s0)
    80005ee8:	953e                	add	a0,a0,a5
    80005eea:	ffffd097          	auipc	ra,0xffffd
    80005eee:	0aa080e7          	jalr	170(ra) # 80002f94 <fetchaddr>
    80005ef2:	02054a63          	bltz	a0,80005f26 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ef6:	e3043783          	ld	a5,-464(s0)
    80005efa:	c3b9                	beqz	a5,80005f40 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005efc:	ffffb097          	auipc	ra,0xffffb
    80005f00:	bf8080e7          	jalr	-1032(ra) # 80000af4 <kalloc>
    80005f04:	85aa                	mv	a1,a0
    80005f06:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f0a:	cd11                	beqz	a0,80005f26 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f0c:	6605                	lui	a2,0x1
    80005f0e:	e3043503          	ld	a0,-464(s0)
    80005f12:	ffffd097          	auipc	ra,0xffffd
    80005f16:	0d4080e7          	jalr	212(ra) # 80002fe6 <fetchstr>
    80005f1a:	00054663          	bltz	a0,80005f26 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f1e:	0905                	addi	s2,s2,1
    80005f20:	09a1                	addi	s3,s3,8
    80005f22:	fb491be3          	bne	s2,s4,80005ed8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f26:	10048913          	addi	s2,s1,256
    80005f2a:	6088                	ld	a0,0(s1)
    80005f2c:	c529                	beqz	a0,80005f76 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f2e:	ffffb097          	auipc	ra,0xffffb
    80005f32:	aca080e7          	jalr	-1334(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f36:	04a1                	addi	s1,s1,8
    80005f38:	ff2499e3          	bne	s1,s2,80005f2a <sys_exec+0xac>
  return -1;
    80005f3c:	597d                	li	s2,-1
    80005f3e:	a82d                	j	80005f78 <sys_exec+0xfa>
      argv[i] = 0;
    80005f40:	0a8e                	slli	s5,s5,0x3
    80005f42:	fc040793          	addi	a5,s0,-64
    80005f46:	9abe                	add	s5,s5,a5
    80005f48:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f4c:	e4040593          	addi	a1,s0,-448
    80005f50:	f4040513          	addi	a0,s0,-192
    80005f54:	fffff097          	auipc	ra,0xfffff
    80005f58:	194080e7          	jalr	404(ra) # 800050e8 <exec>
    80005f5c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f5e:	10048993          	addi	s3,s1,256
    80005f62:	6088                	ld	a0,0(s1)
    80005f64:	c911                	beqz	a0,80005f78 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f66:	ffffb097          	auipc	ra,0xffffb
    80005f6a:	a92080e7          	jalr	-1390(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f6e:	04a1                	addi	s1,s1,8
    80005f70:	ff3499e3          	bne	s1,s3,80005f62 <sys_exec+0xe4>
    80005f74:	a011                	j	80005f78 <sys_exec+0xfa>
  return -1;
    80005f76:	597d                	li	s2,-1
}
    80005f78:	854a                	mv	a0,s2
    80005f7a:	60be                	ld	ra,456(sp)
    80005f7c:	641e                	ld	s0,448(sp)
    80005f7e:	74fa                	ld	s1,440(sp)
    80005f80:	795a                	ld	s2,432(sp)
    80005f82:	79ba                	ld	s3,424(sp)
    80005f84:	7a1a                	ld	s4,416(sp)
    80005f86:	6afa                	ld	s5,408(sp)
    80005f88:	6179                	addi	sp,sp,464
    80005f8a:	8082                	ret

0000000080005f8c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f8c:	7139                	addi	sp,sp,-64
    80005f8e:	fc06                	sd	ra,56(sp)
    80005f90:	f822                	sd	s0,48(sp)
    80005f92:	f426                	sd	s1,40(sp)
    80005f94:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f96:	ffffc097          	auipc	ra,0xffffc
    80005f9a:	972080e7          	jalr	-1678(ra) # 80001908 <myproc>
    80005f9e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005fa0:	fd840593          	addi	a1,s0,-40
    80005fa4:	4501                	li	a0,0
    80005fa6:	ffffd097          	auipc	ra,0xffffd
    80005faa:	0aa080e7          	jalr	170(ra) # 80003050 <argaddr>
    return -1;
    80005fae:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fb0:	0e054063          	bltz	a0,80006090 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fb4:	fc840593          	addi	a1,s0,-56
    80005fb8:	fd040513          	addi	a0,s0,-48
    80005fbc:	fffff097          	auipc	ra,0xfffff
    80005fc0:	dfc080e7          	jalr	-516(ra) # 80004db8 <pipealloc>
    return -1;
    80005fc4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fc6:	0c054563          	bltz	a0,80006090 <sys_pipe+0x104>
  fd0 = -1;
    80005fca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fce:	fd043503          	ld	a0,-48(s0)
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	508080e7          	jalr	1288(ra) # 800054da <fdalloc>
    80005fda:	fca42223          	sw	a0,-60(s0)
    80005fde:	08054c63          	bltz	a0,80006076 <sys_pipe+0xea>
    80005fe2:	fc843503          	ld	a0,-56(s0)
    80005fe6:	fffff097          	auipc	ra,0xfffff
    80005fea:	4f4080e7          	jalr	1268(ra) # 800054da <fdalloc>
    80005fee:	fca42023          	sw	a0,-64(s0)
    80005ff2:	06054863          	bltz	a0,80006062 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ff6:	4691                	li	a3,4
    80005ff8:	fc440613          	addi	a2,s0,-60
    80005ffc:	fd843583          	ld	a1,-40(s0)
    80006000:	78a8                	ld	a0,112(s1)
    80006002:	ffffb097          	auipc	ra,0xffffb
    80006006:	670080e7          	jalr	1648(ra) # 80001672 <copyout>
    8000600a:	02054063          	bltz	a0,8000602a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000600e:	4691                	li	a3,4
    80006010:	fc040613          	addi	a2,s0,-64
    80006014:	fd843583          	ld	a1,-40(s0)
    80006018:	0591                	addi	a1,a1,4
    8000601a:	78a8                	ld	a0,112(s1)
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	656080e7          	jalr	1622(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006024:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006026:	06055563          	bgez	a0,80006090 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000602a:	fc442783          	lw	a5,-60(s0)
    8000602e:	07f9                	addi	a5,a5,30
    80006030:	078e                	slli	a5,a5,0x3
    80006032:	97a6                	add	a5,a5,s1
    80006034:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006038:	fc042503          	lw	a0,-64(s0)
    8000603c:	0579                	addi	a0,a0,30
    8000603e:	050e                	slli	a0,a0,0x3
    80006040:	9526                	add	a0,a0,s1
    80006042:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006046:	fd043503          	ld	a0,-48(s0)
    8000604a:	fffff097          	auipc	ra,0xfffff
    8000604e:	a3e080e7          	jalr	-1474(ra) # 80004a88 <fileclose>
    fileclose(wf);
    80006052:	fc843503          	ld	a0,-56(s0)
    80006056:	fffff097          	auipc	ra,0xfffff
    8000605a:	a32080e7          	jalr	-1486(ra) # 80004a88 <fileclose>
    return -1;
    8000605e:	57fd                	li	a5,-1
    80006060:	a805                	j	80006090 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006062:	fc442783          	lw	a5,-60(s0)
    80006066:	0007c863          	bltz	a5,80006076 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000606a:	01e78513          	addi	a0,a5,30
    8000606e:	050e                	slli	a0,a0,0x3
    80006070:	9526                	add	a0,a0,s1
    80006072:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006076:	fd043503          	ld	a0,-48(s0)
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	a0e080e7          	jalr	-1522(ra) # 80004a88 <fileclose>
    fileclose(wf);
    80006082:	fc843503          	ld	a0,-56(s0)
    80006086:	fffff097          	auipc	ra,0xfffff
    8000608a:	a02080e7          	jalr	-1534(ra) # 80004a88 <fileclose>
    return -1;
    8000608e:	57fd                	li	a5,-1
}
    80006090:	853e                	mv	a0,a5
    80006092:	70e2                	ld	ra,56(sp)
    80006094:	7442                	ld	s0,48(sp)
    80006096:	74a2                	ld	s1,40(sp)
    80006098:	6121                	addi	sp,sp,64
    8000609a:	8082                	ret
    8000609c:	0000                	unimp
	...

00000000800060a0 <kernelvec>:
    800060a0:	7111                	addi	sp,sp,-256
    800060a2:	e006                	sd	ra,0(sp)
    800060a4:	e40a                	sd	sp,8(sp)
    800060a6:	e80e                	sd	gp,16(sp)
    800060a8:	ec12                	sd	tp,24(sp)
    800060aa:	f016                	sd	t0,32(sp)
    800060ac:	f41a                	sd	t1,40(sp)
    800060ae:	f81e                	sd	t2,48(sp)
    800060b0:	fc22                	sd	s0,56(sp)
    800060b2:	e0a6                	sd	s1,64(sp)
    800060b4:	e4aa                	sd	a0,72(sp)
    800060b6:	e8ae                	sd	a1,80(sp)
    800060b8:	ecb2                	sd	a2,88(sp)
    800060ba:	f0b6                	sd	a3,96(sp)
    800060bc:	f4ba                	sd	a4,104(sp)
    800060be:	f8be                	sd	a5,112(sp)
    800060c0:	fcc2                	sd	a6,120(sp)
    800060c2:	e146                	sd	a7,128(sp)
    800060c4:	e54a                	sd	s2,136(sp)
    800060c6:	e94e                	sd	s3,144(sp)
    800060c8:	ed52                	sd	s4,152(sp)
    800060ca:	f156                	sd	s5,160(sp)
    800060cc:	f55a                	sd	s6,168(sp)
    800060ce:	f95e                	sd	s7,176(sp)
    800060d0:	fd62                	sd	s8,184(sp)
    800060d2:	e1e6                	sd	s9,192(sp)
    800060d4:	e5ea                	sd	s10,200(sp)
    800060d6:	e9ee                	sd	s11,208(sp)
    800060d8:	edf2                	sd	t3,216(sp)
    800060da:	f1f6                	sd	t4,224(sp)
    800060dc:	f5fa                	sd	t5,232(sp)
    800060de:	f9fe                	sd	t6,240(sp)
    800060e0:	d81fc0ef          	jal	ra,80002e60 <kerneltrap>
    800060e4:	6082                	ld	ra,0(sp)
    800060e6:	6122                	ld	sp,8(sp)
    800060e8:	61c2                	ld	gp,16(sp)
    800060ea:	7282                	ld	t0,32(sp)
    800060ec:	7322                	ld	t1,40(sp)
    800060ee:	73c2                	ld	t2,48(sp)
    800060f0:	7462                	ld	s0,56(sp)
    800060f2:	6486                	ld	s1,64(sp)
    800060f4:	6526                	ld	a0,72(sp)
    800060f6:	65c6                	ld	a1,80(sp)
    800060f8:	6666                	ld	a2,88(sp)
    800060fa:	7686                	ld	a3,96(sp)
    800060fc:	7726                	ld	a4,104(sp)
    800060fe:	77c6                	ld	a5,112(sp)
    80006100:	7866                	ld	a6,120(sp)
    80006102:	688a                	ld	a7,128(sp)
    80006104:	692a                	ld	s2,136(sp)
    80006106:	69ca                	ld	s3,144(sp)
    80006108:	6a6a                	ld	s4,152(sp)
    8000610a:	7a8a                	ld	s5,160(sp)
    8000610c:	7b2a                	ld	s6,168(sp)
    8000610e:	7bca                	ld	s7,176(sp)
    80006110:	7c6a                	ld	s8,184(sp)
    80006112:	6c8e                	ld	s9,192(sp)
    80006114:	6d2e                	ld	s10,200(sp)
    80006116:	6dce                	ld	s11,208(sp)
    80006118:	6e6e                	ld	t3,216(sp)
    8000611a:	7e8e                	ld	t4,224(sp)
    8000611c:	7f2e                	ld	t5,232(sp)
    8000611e:	7fce                	ld	t6,240(sp)
    80006120:	6111                	addi	sp,sp,256
    80006122:	10200073          	sret
    80006126:	00000013          	nop
    8000612a:	00000013          	nop
    8000612e:	0001                	nop

0000000080006130 <timervec>:
    80006130:	34051573          	csrrw	a0,mscratch,a0
    80006134:	e10c                	sd	a1,0(a0)
    80006136:	e510                	sd	a2,8(a0)
    80006138:	e914                	sd	a3,16(a0)
    8000613a:	6d0c                	ld	a1,24(a0)
    8000613c:	7110                	ld	a2,32(a0)
    8000613e:	6194                	ld	a3,0(a1)
    80006140:	96b2                	add	a3,a3,a2
    80006142:	e194                	sd	a3,0(a1)
    80006144:	4589                	li	a1,2
    80006146:	14459073          	csrw	sip,a1
    8000614a:	6914                	ld	a3,16(a0)
    8000614c:	6510                	ld	a2,8(a0)
    8000614e:	610c                	ld	a1,0(a0)
    80006150:	34051573          	csrrw	a0,mscratch,a0
    80006154:	30200073          	mret
	...

000000008000615a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000615a:	1141                	addi	sp,sp,-16
    8000615c:	e422                	sd	s0,8(sp)
    8000615e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006160:	0c0007b7          	lui	a5,0xc000
    80006164:	4705                	li	a4,1
    80006166:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006168:	c3d8                	sw	a4,4(a5)
}
    8000616a:	6422                	ld	s0,8(sp)
    8000616c:	0141                	addi	sp,sp,16
    8000616e:	8082                	ret

0000000080006170 <plicinithart>:

void
plicinithart(void)
{
    80006170:	1141                	addi	sp,sp,-16
    80006172:	e406                	sd	ra,8(sp)
    80006174:	e022                	sd	s0,0(sp)
    80006176:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006178:	ffffb097          	auipc	ra,0xffffb
    8000617c:	75c080e7          	jalr	1884(ra) # 800018d4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006180:	0085171b          	slliw	a4,a0,0x8
    80006184:	0c0027b7          	lui	a5,0xc002
    80006188:	97ba                	add	a5,a5,a4
    8000618a:	40200713          	li	a4,1026
    8000618e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006192:	00d5151b          	slliw	a0,a0,0xd
    80006196:	0c2017b7          	lui	a5,0xc201
    8000619a:	953e                	add	a0,a0,a5
    8000619c:	00052023          	sw	zero,0(a0)
}
    800061a0:	60a2                	ld	ra,8(sp)
    800061a2:	6402                	ld	s0,0(sp)
    800061a4:	0141                	addi	sp,sp,16
    800061a6:	8082                	ret

00000000800061a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061a8:	1141                	addi	sp,sp,-16
    800061aa:	e406                	sd	ra,8(sp)
    800061ac:	e022                	sd	s0,0(sp)
    800061ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	724080e7          	jalr	1828(ra) # 800018d4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061b8:	00d5179b          	slliw	a5,a0,0xd
    800061bc:	0c201537          	lui	a0,0xc201
    800061c0:	953e                	add	a0,a0,a5
  return irq;
}
    800061c2:	4148                	lw	a0,4(a0)
    800061c4:	60a2                	ld	ra,8(sp)
    800061c6:	6402                	ld	s0,0(sp)
    800061c8:	0141                	addi	sp,sp,16
    800061ca:	8082                	ret

00000000800061cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061cc:	1101                	addi	sp,sp,-32
    800061ce:	ec06                	sd	ra,24(sp)
    800061d0:	e822                	sd	s0,16(sp)
    800061d2:	e426                	sd	s1,8(sp)
    800061d4:	1000                	addi	s0,sp,32
    800061d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061d8:	ffffb097          	auipc	ra,0xffffb
    800061dc:	6fc080e7          	jalr	1788(ra) # 800018d4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061e0:	00d5151b          	slliw	a0,a0,0xd
    800061e4:	0c2017b7          	lui	a5,0xc201
    800061e8:	97aa                	add	a5,a5,a0
    800061ea:	c3c4                	sw	s1,4(a5)
}
    800061ec:	60e2                	ld	ra,24(sp)
    800061ee:	6442                	ld	s0,16(sp)
    800061f0:	64a2                	ld	s1,8(sp)
    800061f2:	6105                	addi	sp,sp,32
    800061f4:	8082                	ret

00000000800061f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061f6:	1141                	addi	sp,sp,-16
    800061f8:	e406                	sd	ra,8(sp)
    800061fa:	e022                	sd	s0,0(sp)
    800061fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061fe:	479d                	li	a5,7
    80006200:	06a7c963          	blt	a5,a0,80006272 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006204:	0001d797          	auipc	a5,0x1d
    80006208:	dfc78793          	addi	a5,a5,-516 # 80023000 <disk>
    8000620c:	00a78733          	add	a4,a5,a0
    80006210:	6789                	lui	a5,0x2
    80006212:	97ba                	add	a5,a5,a4
    80006214:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006218:	e7ad                	bnez	a5,80006282 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000621a:	00451793          	slli	a5,a0,0x4
    8000621e:	0001f717          	auipc	a4,0x1f
    80006222:	de270713          	addi	a4,a4,-542 # 80025000 <disk+0x2000>
    80006226:	6314                	ld	a3,0(a4)
    80006228:	96be                	add	a3,a3,a5
    8000622a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000622e:	6314                	ld	a3,0(a4)
    80006230:	96be                	add	a3,a3,a5
    80006232:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006236:	6314                	ld	a3,0(a4)
    80006238:	96be                	add	a3,a3,a5
    8000623a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000623e:	6318                	ld	a4,0(a4)
    80006240:	97ba                	add	a5,a5,a4
    80006242:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006246:	0001d797          	auipc	a5,0x1d
    8000624a:	dba78793          	addi	a5,a5,-582 # 80023000 <disk>
    8000624e:	97aa                	add	a5,a5,a0
    80006250:	6509                	lui	a0,0x2
    80006252:	953e                	add	a0,a0,a5
    80006254:	4785                	li	a5,1
    80006256:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000625a:	0001f517          	auipc	a0,0x1f
    8000625e:	dbe50513          	addi	a0,a0,-578 # 80025018 <disk+0x2018>
    80006262:	ffffc097          	auipc	ra,0xffffc
    80006266:	148080e7          	jalr	328(ra) # 800023aa <wakeup>
}
    8000626a:	60a2                	ld	ra,8(sp)
    8000626c:	6402                	ld	s0,0(sp)
    8000626e:	0141                	addi	sp,sp,16
    80006270:	8082                	ret
    panic("free_desc 1");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	52e50513          	addi	a0,a0,1326 # 800087a0 <syscalls+0x330>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c4080e7          	jalr	708(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	52e50513          	addi	a0,a0,1326 # 800087b0 <syscalls+0x340>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b4080e7          	jalr	692(ra) # 8000053e <panic>

0000000080006292 <virtio_disk_init>:
{
    80006292:	1101                	addi	sp,sp,-32
    80006294:	ec06                	sd	ra,24(sp)
    80006296:	e822                	sd	s0,16(sp)
    80006298:	e426                	sd	s1,8(sp)
    8000629a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000629c:	00002597          	auipc	a1,0x2
    800062a0:	52458593          	addi	a1,a1,1316 # 800087c0 <syscalls+0x350>
    800062a4:	0001f517          	auipc	a0,0x1f
    800062a8:	e8450513          	addi	a0,a0,-380 # 80025128 <disk+0x2128>
    800062ac:	ffffb097          	auipc	ra,0xffffb
    800062b0:	8a8080e7          	jalr	-1880(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062b4:	100017b7          	lui	a5,0x10001
    800062b8:	4398                	lw	a4,0(a5)
    800062ba:	2701                	sext.w	a4,a4
    800062bc:	747277b7          	lui	a5,0x74727
    800062c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062c4:	0ef71163          	bne	a4,a5,800063a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062c8:	100017b7          	lui	a5,0x10001
    800062cc:	43dc                	lw	a5,4(a5)
    800062ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062d0:	4705                	li	a4,1
    800062d2:	0ce79a63          	bne	a5,a4,800063a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062d6:	100017b7          	lui	a5,0x10001
    800062da:	479c                	lw	a5,8(a5)
    800062dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062de:	4709                	li	a4,2
    800062e0:	0ce79363          	bne	a5,a4,800063a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062e4:	100017b7          	lui	a5,0x10001
    800062e8:	47d8                	lw	a4,12(a5)
    800062ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062ec:	554d47b7          	lui	a5,0x554d4
    800062f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062f4:	0af71963          	bne	a4,a5,800063a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f8:	100017b7          	lui	a5,0x10001
    800062fc:	4705                	li	a4,1
    800062fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006300:	470d                	li	a4,3
    80006302:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006304:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006306:	c7ffe737          	lui	a4,0xc7ffe
    8000630a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000630e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006310:	2701                	sext.w	a4,a4
    80006312:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006314:	472d                	li	a4,11
    80006316:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006318:	473d                	li	a4,15
    8000631a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000631c:	6705                	lui	a4,0x1
    8000631e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006320:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006324:	5bdc                	lw	a5,52(a5)
    80006326:	2781                	sext.w	a5,a5
  if(max == 0)
    80006328:	c7d9                	beqz	a5,800063b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000632a:	471d                	li	a4,7
    8000632c:	08f77d63          	bgeu	a4,a5,800063c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006330:	100014b7          	lui	s1,0x10001
    80006334:	47a1                	li	a5,8
    80006336:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006338:	6609                	lui	a2,0x2
    8000633a:	4581                	li	a1,0
    8000633c:	0001d517          	auipc	a0,0x1d
    80006340:	cc450513          	addi	a0,a0,-828 # 80023000 <disk>
    80006344:	ffffb097          	auipc	ra,0xffffb
    80006348:	99c080e7          	jalr	-1636(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000634c:	0001d717          	auipc	a4,0x1d
    80006350:	cb470713          	addi	a4,a4,-844 # 80023000 <disk>
    80006354:	00c75793          	srli	a5,a4,0xc
    80006358:	2781                	sext.w	a5,a5
    8000635a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000635c:	0001f797          	auipc	a5,0x1f
    80006360:	ca478793          	addi	a5,a5,-860 # 80025000 <disk+0x2000>
    80006364:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006366:	0001d717          	auipc	a4,0x1d
    8000636a:	d1a70713          	addi	a4,a4,-742 # 80023080 <disk+0x80>
    8000636e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006370:	0001e717          	auipc	a4,0x1e
    80006374:	c9070713          	addi	a4,a4,-880 # 80024000 <disk+0x1000>
    80006378:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000637a:	4705                	li	a4,1
    8000637c:	00e78c23          	sb	a4,24(a5)
    80006380:	00e78ca3          	sb	a4,25(a5)
    80006384:	00e78d23          	sb	a4,26(a5)
    80006388:	00e78da3          	sb	a4,27(a5)
    8000638c:	00e78e23          	sb	a4,28(a5)
    80006390:	00e78ea3          	sb	a4,29(a5)
    80006394:	00e78f23          	sb	a4,30(a5)
    80006398:	00e78fa3          	sb	a4,31(a5)
}
    8000639c:	60e2                	ld	ra,24(sp)
    8000639e:	6442                	ld	s0,16(sp)
    800063a0:	64a2                	ld	s1,8(sp)
    800063a2:	6105                	addi	sp,sp,32
    800063a4:	8082                	ret
    panic("could not find virtio disk");
    800063a6:	00002517          	auipc	a0,0x2
    800063aa:	42a50513          	addi	a0,a0,1066 # 800087d0 <syscalls+0x360>
    800063ae:	ffffa097          	auipc	ra,0xffffa
    800063b2:	190080e7          	jalr	400(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063b6:	00002517          	auipc	a0,0x2
    800063ba:	43a50513          	addi	a0,a0,1082 # 800087f0 <syscalls+0x380>
    800063be:	ffffa097          	auipc	ra,0xffffa
    800063c2:	180080e7          	jalr	384(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	44a50513          	addi	a0,a0,1098 # 80008810 <syscalls+0x3a0>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	170080e7          	jalr	368(ra) # 8000053e <panic>

00000000800063d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063d6:	7159                	addi	sp,sp,-112
    800063d8:	f486                	sd	ra,104(sp)
    800063da:	f0a2                	sd	s0,96(sp)
    800063dc:	eca6                	sd	s1,88(sp)
    800063de:	e8ca                	sd	s2,80(sp)
    800063e0:	e4ce                	sd	s3,72(sp)
    800063e2:	e0d2                	sd	s4,64(sp)
    800063e4:	fc56                	sd	s5,56(sp)
    800063e6:	f85a                	sd	s6,48(sp)
    800063e8:	f45e                	sd	s7,40(sp)
    800063ea:	f062                	sd	s8,32(sp)
    800063ec:	ec66                	sd	s9,24(sp)
    800063ee:	e86a                	sd	s10,16(sp)
    800063f0:	1880                	addi	s0,sp,112
    800063f2:	892a                	mv	s2,a0
    800063f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063f6:	00c52c83          	lw	s9,12(a0)
    800063fa:	001c9c9b          	slliw	s9,s9,0x1
    800063fe:	1c82                	slli	s9,s9,0x20
    80006400:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006404:	0001f517          	auipc	a0,0x1f
    80006408:	d2450513          	addi	a0,a0,-732 # 80025128 <disk+0x2128>
    8000640c:	ffffa097          	auipc	ra,0xffffa
    80006410:	7d8080e7          	jalr	2008(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006414:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006416:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006418:	0001db97          	auipc	s7,0x1d
    8000641c:	be8b8b93          	addi	s7,s7,-1048 # 80023000 <disk>
    80006420:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006422:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006424:	8a4e                	mv	s4,s3
    80006426:	a051                	j	800064aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006428:	00fb86b3          	add	a3,s7,a5
    8000642c:	96da                	add	a3,a3,s6
    8000642e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006432:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006434:	0207c563          	bltz	a5,8000645e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006438:	2485                	addiw	s1,s1,1
    8000643a:	0711                	addi	a4,a4,4
    8000643c:	25548063          	beq	s1,s5,8000667c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006440:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006442:	0001f697          	auipc	a3,0x1f
    80006446:	bd668693          	addi	a3,a3,-1066 # 80025018 <disk+0x2018>
    8000644a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000644c:	0006c583          	lbu	a1,0(a3)
    80006450:	fde1                	bnez	a1,80006428 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006452:	2785                	addiw	a5,a5,1
    80006454:	0685                	addi	a3,a3,1
    80006456:	ff879be3          	bne	a5,s8,8000644c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000645a:	57fd                	li	a5,-1
    8000645c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000645e:	02905a63          	blez	s1,80006492 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006462:	f9042503          	lw	a0,-112(s0)
    80006466:	00000097          	auipc	ra,0x0
    8000646a:	d90080e7          	jalr	-624(ra) # 800061f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000646e:	4785                	li	a5,1
    80006470:	0297d163          	bge	a5,s1,80006492 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006474:	f9442503          	lw	a0,-108(s0)
    80006478:	00000097          	auipc	ra,0x0
    8000647c:	d7e080e7          	jalr	-642(ra) # 800061f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006480:	4789                	li	a5,2
    80006482:	0097d863          	bge	a5,s1,80006492 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006486:	f9842503          	lw	a0,-104(s0)
    8000648a:	00000097          	auipc	ra,0x0
    8000648e:	d6c080e7          	jalr	-660(ra) # 800061f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006492:	0001f597          	auipc	a1,0x1f
    80006496:	c9658593          	addi	a1,a1,-874 # 80025128 <disk+0x2128>
    8000649a:	0001f517          	auipc	a0,0x1f
    8000649e:	b7e50513          	addi	a0,a0,-1154 # 80025018 <disk+0x2018>
    800064a2:	ffffc097          	auipc	ra,0xffffc
    800064a6:	b8e080e7          	jalr	-1138(ra) # 80002030 <sleep>
  for(int i = 0; i < 3; i++){
    800064aa:	f9040713          	addi	a4,s0,-112
    800064ae:	84ce                	mv	s1,s3
    800064b0:	bf41                	j	80006440 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064b2:	20058713          	addi	a4,a1,512
    800064b6:	00471693          	slli	a3,a4,0x4
    800064ba:	0001d717          	auipc	a4,0x1d
    800064be:	b4670713          	addi	a4,a4,-1210 # 80023000 <disk>
    800064c2:	9736                	add	a4,a4,a3
    800064c4:	4685                	li	a3,1
    800064c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064ca:	20058713          	addi	a4,a1,512
    800064ce:	00471693          	slli	a3,a4,0x4
    800064d2:	0001d717          	auipc	a4,0x1d
    800064d6:	b2e70713          	addi	a4,a4,-1234 # 80023000 <disk>
    800064da:	9736                	add	a4,a4,a3
    800064dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064e4:	7679                	lui	a2,0xffffe
    800064e6:	963e                	add	a2,a2,a5
    800064e8:	0001f697          	auipc	a3,0x1f
    800064ec:	b1868693          	addi	a3,a3,-1256 # 80025000 <disk+0x2000>
    800064f0:	6298                	ld	a4,0(a3)
    800064f2:	9732                	add	a4,a4,a2
    800064f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064f6:	6298                	ld	a4,0(a3)
    800064f8:	9732                	add	a4,a4,a2
    800064fa:	4541                	li	a0,16
    800064fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064fe:	6298                	ld	a4,0(a3)
    80006500:	9732                	add	a4,a4,a2
    80006502:	4505                	li	a0,1
    80006504:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006508:	f9442703          	lw	a4,-108(s0)
    8000650c:	6288                	ld	a0,0(a3)
    8000650e:	962a                	add	a2,a2,a0
    80006510:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006514:	0712                	slli	a4,a4,0x4
    80006516:	6290                	ld	a2,0(a3)
    80006518:	963a                	add	a2,a2,a4
    8000651a:	05890513          	addi	a0,s2,88
    8000651e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006520:	6294                	ld	a3,0(a3)
    80006522:	96ba                	add	a3,a3,a4
    80006524:	40000613          	li	a2,1024
    80006528:	c690                	sw	a2,8(a3)
  if(write)
    8000652a:	140d0063          	beqz	s10,8000666a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000652e:	0001f697          	auipc	a3,0x1f
    80006532:	ad26b683          	ld	a3,-1326(a3) # 80025000 <disk+0x2000>
    80006536:	96ba                	add	a3,a3,a4
    80006538:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000653c:	0001d817          	auipc	a6,0x1d
    80006540:	ac480813          	addi	a6,a6,-1340 # 80023000 <disk>
    80006544:	0001f517          	auipc	a0,0x1f
    80006548:	abc50513          	addi	a0,a0,-1348 # 80025000 <disk+0x2000>
    8000654c:	6114                	ld	a3,0(a0)
    8000654e:	96ba                	add	a3,a3,a4
    80006550:	00c6d603          	lhu	a2,12(a3)
    80006554:	00166613          	ori	a2,a2,1
    80006558:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000655c:	f9842683          	lw	a3,-104(s0)
    80006560:	6110                	ld	a2,0(a0)
    80006562:	9732                	add	a4,a4,a2
    80006564:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006568:	20058613          	addi	a2,a1,512
    8000656c:	0612                	slli	a2,a2,0x4
    8000656e:	9642                	add	a2,a2,a6
    80006570:	577d                	li	a4,-1
    80006572:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006576:	00469713          	slli	a4,a3,0x4
    8000657a:	6114                	ld	a3,0(a0)
    8000657c:	96ba                	add	a3,a3,a4
    8000657e:	03078793          	addi	a5,a5,48
    80006582:	97c2                	add	a5,a5,a6
    80006584:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006586:	611c                	ld	a5,0(a0)
    80006588:	97ba                	add	a5,a5,a4
    8000658a:	4685                	li	a3,1
    8000658c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000658e:	611c                	ld	a5,0(a0)
    80006590:	97ba                	add	a5,a5,a4
    80006592:	4809                	li	a6,2
    80006594:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006598:	611c                	ld	a5,0(a0)
    8000659a:	973e                	add	a4,a4,a5
    8000659c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065a8:	6518                	ld	a4,8(a0)
    800065aa:	00275783          	lhu	a5,2(a4)
    800065ae:	8b9d                	andi	a5,a5,7
    800065b0:	0786                	slli	a5,a5,0x1
    800065b2:	97ba                	add	a5,a5,a4
    800065b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065bc:	6518                	ld	a4,8(a0)
    800065be:	00275783          	lhu	a5,2(a4)
    800065c2:	2785                	addiw	a5,a5,1
    800065c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065cc:	100017b7          	lui	a5,0x10001
    800065d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065d4:	00492703          	lw	a4,4(s2)
    800065d8:	4785                	li	a5,1
    800065da:	02f71163          	bne	a4,a5,800065fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065de:	0001f997          	auipc	s3,0x1f
    800065e2:	b4a98993          	addi	s3,s3,-1206 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800065e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065e8:	85ce                	mv	a1,s3
    800065ea:	854a                	mv	a0,s2
    800065ec:	ffffc097          	auipc	ra,0xffffc
    800065f0:	a44080e7          	jalr	-1468(ra) # 80002030 <sleep>
  while(b->disk == 1) {
    800065f4:	00492783          	lw	a5,4(s2)
    800065f8:	fe9788e3          	beq	a5,s1,800065e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800065fc:	f9042903          	lw	s2,-112(s0)
    80006600:	20090793          	addi	a5,s2,512
    80006604:	00479713          	slli	a4,a5,0x4
    80006608:	0001d797          	auipc	a5,0x1d
    8000660c:	9f878793          	addi	a5,a5,-1544 # 80023000 <disk>
    80006610:	97ba                	add	a5,a5,a4
    80006612:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006616:	0001f997          	auipc	s3,0x1f
    8000661a:	9ea98993          	addi	s3,s3,-1558 # 80025000 <disk+0x2000>
    8000661e:	00491713          	slli	a4,s2,0x4
    80006622:	0009b783          	ld	a5,0(s3)
    80006626:	97ba                	add	a5,a5,a4
    80006628:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000662c:	854a                	mv	a0,s2
    8000662e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006632:	00000097          	auipc	ra,0x0
    80006636:	bc4080e7          	jalr	-1084(ra) # 800061f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000663a:	8885                	andi	s1,s1,1
    8000663c:	f0ed                	bnez	s1,8000661e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000663e:	0001f517          	auipc	a0,0x1f
    80006642:	aea50513          	addi	a0,a0,-1302 # 80025128 <disk+0x2128>
    80006646:	ffffa097          	auipc	ra,0xffffa
    8000664a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
}
    8000664e:	70a6                	ld	ra,104(sp)
    80006650:	7406                	ld	s0,96(sp)
    80006652:	64e6                	ld	s1,88(sp)
    80006654:	6946                	ld	s2,80(sp)
    80006656:	69a6                	ld	s3,72(sp)
    80006658:	6a06                	ld	s4,64(sp)
    8000665a:	7ae2                	ld	s5,56(sp)
    8000665c:	7b42                	ld	s6,48(sp)
    8000665e:	7ba2                	ld	s7,40(sp)
    80006660:	7c02                	ld	s8,32(sp)
    80006662:	6ce2                	ld	s9,24(sp)
    80006664:	6d42                	ld	s10,16(sp)
    80006666:	6165                	addi	sp,sp,112
    80006668:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000666a:	0001f697          	auipc	a3,0x1f
    8000666e:	9966b683          	ld	a3,-1642(a3) # 80025000 <disk+0x2000>
    80006672:	96ba                	add	a3,a3,a4
    80006674:	4609                	li	a2,2
    80006676:	00c69623          	sh	a2,12(a3)
    8000667a:	b5c9                	j	8000653c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000667c:	f9042583          	lw	a1,-112(s0)
    80006680:	20058793          	addi	a5,a1,512
    80006684:	0792                	slli	a5,a5,0x4
    80006686:	0001d517          	auipc	a0,0x1d
    8000668a:	a2250513          	addi	a0,a0,-1502 # 800230a8 <disk+0xa8>
    8000668e:	953e                	add	a0,a0,a5
  if(write)
    80006690:	e20d11e3          	bnez	s10,800064b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006694:	20058713          	addi	a4,a1,512
    80006698:	00471693          	slli	a3,a4,0x4
    8000669c:	0001d717          	auipc	a4,0x1d
    800066a0:	96470713          	addi	a4,a4,-1692 # 80023000 <disk>
    800066a4:	9736                	add	a4,a4,a3
    800066a6:	0a072423          	sw	zero,168(a4)
    800066aa:	b505                	j	800064ca <virtio_disk_rw+0xf4>

00000000800066ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066ac:	1101                	addi	sp,sp,-32
    800066ae:	ec06                	sd	ra,24(sp)
    800066b0:	e822                	sd	s0,16(sp)
    800066b2:	e426                	sd	s1,8(sp)
    800066b4:	e04a                	sd	s2,0(sp)
    800066b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066b8:	0001f517          	auipc	a0,0x1f
    800066bc:	a7050513          	addi	a0,a0,-1424 # 80025128 <disk+0x2128>
    800066c0:	ffffa097          	auipc	ra,0xffffa
    800066c4:	524080e7          	jalr	1316(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066c8:	10001737          	lui	a4,0x10001
    800066cc:	533c                	lw	a5,96(a4)
    800066ce:	8b8d                	andi	a5,a5,3
    800066d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066d6:	0001f797          	auipc	a5,0x1f
    800066da:	92a78793          	addi	a5,a5,-1750 # 80025000 <disk+0x2000>
    800066de:	6b94                	ld	a3,16(a5)
    800066e0:	0207d703          	lhu	a4,32(a5)
    800066e4:	0026d783          	lhu	a5,2(a3)
    800066e8:	06f70163          	beq	a4,a5,8000674a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066ec:	0001d917          	auipc	s2,0x1d
    800066f0:	91490913          	addi	s2,s2,-1772 # 80023000 <disk>
    800066f4:	0001f497          	auipc	s1,0x1f
    800066f8:	90c48493          	addi	s1,s1,-1780 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800066fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006700:	6898                	ld	a4,16(s1)
    80006702:	0204d783          	lhu	a5,32(s1)
    80006706:	8b9d                	andi	a5,a5,7
    80006708:	078e                	slli	a5,a5,0x3
    8000670a:	97ba                	add	a5,a5,a4
    8000670c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000670e:	20078713          	addi	a4,a5,512
    80006712:	0712                	slli	a4,a4,0x4
    80006714:	974a                	add	a4,a4,s2
    80006716:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000671a:	e731                	bnez	a4,80006766 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000671c:	20078793          	addi	a5,a5,512
    80006720:	0792                	slli	a5,a5,0x4
    80006722:	97ca                	add	a5,a5,s2
    80006724:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006726:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000672a:	ffffc097          	auipc	ra,0xffffc
    8000672e:	c80080e7          	jalr	-896(ra) # 800023aa <wakeup>

    disk.used_idx += 1;
    80006732:	0204d783          	lhu	a5,32(s1)
    80006736:	2785                	addiw	a5,a5,1
    80006738:	17c2                	slli	a5,a5,0x30
    8000673a:	93c1                	srli	a5,a5,0x30
    8000673c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006740:	6898                	ld	a4,16(s1)
    80006742:	00275703          	lhu	a4,2(a4)
    80006746:	faf71be3          	bne	a4,a5,800066fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000674a:	0001f517          	auipc	a0,0x1f
    8000674e:	9de50513          	addi	a0,a0,-1570 # 80025128 <disk+0x2128>
    80006752:	ffffa097          	auipc	ra,0xffffa
    80006756:	546080e7          	jalr	1350(ra) # 80000c98 <release>
}
    8000675a:	60e2                	ld	ra,24(sp)
    8000675c:	6442                	ld	s0,16(sp)
    8000675e:	64a2                	ld	s1,8(sp)
    80006760:	6902                	ld	s2,0(sp)
    80006762:	6105                	addi	sp,sp,32
    80006764:	8082                	ret
      panic("virtio_disk_intr status");
    80006766:	00002517          	auipc	a0,0x2
    8000676a:	0ca50513          	addi	a0,a0,202 # 80008830 <syscalls+0x3c0>
    8000676e:	ffffa097          	auipc	ra,0xffffa
    80006772:	dd0080e7          	jalr	-560(ra) # 8000053e <panic>

0000000080006776 <cas>:
    80006776:	100522af          	lr.w	t0,(a0)
    8000677a:	00b29563          	bne	t0,a1,80006784 <fail>
    8000677e:	18c5252f          	sc.w	a0,a2,(a0)
    80006782:	8082                	ret

0000000080006784 <fail>:
    80006784:	4505                	li	a0,1
    80006786:	8082                	ret
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
