#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);
extern uint64 cas(volatile void *addr, int expected, int newval);

#ifdef OFF
int auto_balanced = 0;
#else
int auto_balanced = 1;
#endif

extern char trampoline[]; // trampoline.S

int unused_head = -1;
int sleeping_head = -1;
int zombie_head = -1;
struct spinlock lock_unused_list;
struct spinlock lock_sleeping_list;
struct spinlock lock_zombie_list;

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table at boot time.
void
procinit(void)
{
  struct proc *p;
  struct cpu *c;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  int index = 0;
  for(p = proc; p < &proc[NPROC]; p++, index++) {
      initlock(&p->lock, "proc");
      p->kstack = KSTACK((int) (p - proc));

      p->proc_index = index;
      p->next_proc_index = -1;
      add_to_list(&unused_head, p, &lock_unused_list);
  }

    for(c = cpus; c < &cpus[NCPU]; c++) {
      c->counter= 0;
      c->runnable_head = -1;
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid() {
  int pid;
  do {
    pid = nextpid;
  } while (cas(&nextpid , pid , pid+1));

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;
    int allocation = remove_first(&unused_head, &lock_unused_list);
    if(allocation == -1){
      return 0;
    }

  p=&proc[allocation];
  acquire(&p->lock);

  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;

  if(remove_from_list(&zombie_head, p, &lock_zombie_list) == 1){
    p->state = UNUSED;
    add_to_list(&unused_head, p, &lock_unused_list);
  } 

}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;
  add_to_list(&cpus[0].runnable_head, p, &cpus[0].lock_runnable_list);


  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  if(auto_balanced){
    int cpu_num = 0;
    struct cpu *c;
    int min = cpus[cpu_num].counter;
    for(int i = 1; i < CPUS; i++){  
        if (min > cpus[i].counter){
            min = cpus[i].counter;
            cpu_num = i;
        }
    }
    np->cpu_num = cpu_num;
    c = &cpus[cpu_num];
    while(cas(&c->counter, c->counter, c->counter + 1) != 0);

  }
  else{
    np->cpu_num = p->cpu_num;
  }
  // printf("-> %d <-",np->cpu_num);
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  struct cpu *c = &cpus[np->cpu_num];
  add_to_list(&c->runnable_head, np, &c->lock_runnable_list);
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any c.hildren to init.
  reparent(p);
  
  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  add_to_list(&zombie_head, p, &lock_zombie_list);

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  
  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    int proc_num = remove_first(&c->runnable_head, &c->lock_runnable_list);
    if(proc_num != -1){
      p = &proc[proc_num];
      acquire(&p->lock);
      // Switch to chosen process.  It is the process's job
      // to release its lock and then reacquire it
      // before jumping back to us.
      p->state = RUNNING;
      // printf("Im Rinning -> %d\n", p->pid);
      c->proc = p;
      swtch(&c->context, &p->context);

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
      release(&p->lock);
    }
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  struct cpu *c;
  acquire(&p->lock);
  p->state = RUNNABLE;

  c = &cpus[p->cpu_num];
  add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  //add process to sleeping list
  add_to_list(&sleeping_head, p, &lock_sleeping_list);
  
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;
  // printf("proc %d went to sleep\n", p->pid);
  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
 void
wakeup(void *chan)
{
  struct proc *p;
  struct cpu *c;
  acquire(&lock_sleeping_list);

  if(sleeping_head != -1){
    p = &proc[sleeping_head];
    release(&lock_sleeping_list);

    int curr_proc;
    do
    {
      acquire(&p->lock);
      int next_proc = p->next_proc_index;
      if (p->state == SLEEPING && p->chan == chan) {
          if(remove_from_list(&sleeping_head, p, &lock_sleeping_list)){
              p->state = RUNNABLE;
              if(auto_balanced){
                int cpu_num = 0;
                struct cpu *c;
                int min = cpus[cpu_num].counter;
                for(int i = 1; i < CPUS; i++){  
                    if (min > cpus[i].counter){
                        min = cpus[i].counter;
                        cpu_num = i;
                    }
                }
                if(p->cpu_num == cpu_num){
                  c = &cpus[cpu_num];
                  while(cas(&c->counter, c->counter, c->counter + 1) != 0);
                }
                p->cpu_num = cpu_num;
              }
              c = &cpus[p->cpu_num];
              add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
          }
      }
      release(&p->lock);
      curr_proc = next_proc;
      if(curr_proc != -1) {
        p = &proc[curr_proc];
      }
    } while(curr_proc != -1);
  }
  else{
    release(&lock_sleeping_list);
    return;
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        if(remove_from_list(&sleeping_head, p, &lock_sleeping_list) == 1){
          p->state = RUNNABLE;

          struct cpu *c = &cpus[p->cpu_num];
          add_to_list(&c->runnable_head, p, &c->lock_runnable_list);
        }
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

int
set_cpu(int cpu_num)
{
    struct proc* p = myproc();
    int curr_cpu = p->cpu_num;
    if(cas(&p->cpu_num, curr_cpu, cpu_num) !=0)
        return -1;
    yield();

    return cpu_num;
}

int
get_cpu()
{
  struct proc *p = myproc();
  
  int cpu_num;
  acquire(&p->lock);
  cpu_num = p->cpu_num;
  release(&p->lock);
  return cpu_num;
}

void
add_to_list(int* curr_proc_index, struct proc* next_proc, struct spinlock* lock) {
  acquire(lock);

  if(*curr_proc_index == -1){
    *curr_proc_index = next_proc->proc_index;
    next_proc->next_proc_index = -1;
    release(lock);
    return;
  }
  struct proc* curr_node = &proc[*curr_proc_index];
  acquire(&curr_node->proc_lock);
  release(lock);
  
  while(curr_node->next_proc_index != -1){
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    release(&curr_node->proc_lock);
    curr_node = &proc[curr_node->next_proc_index];
    // printf("moving to: %d", curr_node->next_proc_index);
  }

  curr_node->next_proc_index = next_proc->proc_index;
  next_proc->next_proc_index = -1;
  release(&curr_node->proc_lock);

}

int remove_from_list(int* curr_proc_index, struct proc* proc_to_remove, struct spinlock* lock) {
  acquire(lock);
  if(*curr_proc_index == -1) 
  {
      release(lock);
      return -1;
  }
  acquire(&proc_to_remove->proc_lock);

  if(*curr_proc_index == proc_to_remove->proc_index){
      *curr_proc_index = proc_to_remove->next_proc_index;
      proc_to_remove->next_proc_index = -1;
      release(&proc_to_remove->proc_lock);
      release(lock);
      return 1;
  }
  
  struct proc* curr_node = &proc[*curr_proc_index];
  acquire(&curr_node->proc_lock);
  release(lock);
  
  while(curr_node->next_proc_index != -1 && curr_node->next_proc_index != proc_to_remove->proc_index){
    acquire(&proc[curr_node->next_proc_index].proc_lock);
    release(&curr_node->proc_lock);
    curr_node = &proc[curr_node->next_proc_index];
  }
  if(curr_node->next_proc_index == -1){
    release(&proc_to_remove->proc_lock);
    release(&curr_node->proc_lock);
    return -1;
  }

  curr_node->next_proc_index = proc_to_remove->next_proc_index;
  proc_to_remove->next_proc_index = -1;
  release(&proc_to_remove->proc_lock);
  release(&curr_node->proc_lock);
  return 1;
}

int remove_first(int* curr_proc_index, struct spinlock* lock) {
    acquire(lock);
    
    if (*curr_proc_index != -1){
      int index = *curr_proc_index;
      struct proc *p = &proc[index];
      acquire(&p->proc_lock);
      
      *curr_proc_index = p->next_proc_index;
      p->next_proc_index = -1;
      int output_proc = p->proc_index;

      release(&p->proc_lock);
      release(lock);
      return output_proc;
    }
    //didn't find a proc to run in the list
    else{

      release(lock);
      return -1;
    }
}