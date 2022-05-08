#include "kernel/param.h"
#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/stat.h"
#include "kernel/riscv.h"



int
main(int argc, char *argv[])
{
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
    	fork();
    }
    int pid = getpid();
    printf("-> %d\n", pid);
    exit(0);
}