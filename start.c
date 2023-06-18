#include "platform.h"
#include <stdint.h>

char stack0[NCORE * 4096];

uint64_t mtrap_scratch[NCORE][4];

void main(void);
void mtrap(void);

void start() {
    uint64_t myid;
    asm volatile (
    // Save a copy of mhartid in tp for S-mode
            "csrr tp, mhartid;"
            "mv %[myid], tp;"
    // Allow S and U modes RWX permissions of the entire phsycial memory
            "li a0, 0x3fffffffffffffUL;"
            "csrw pmpaddr0, a0;"
            "li a0, (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3);"
            "csrw pmpcfg0, a0;"
    // Delegate interrupts and exceptions to S-mode to handle
            "li a0, 0xffff;"
            "csrw medeleg, a0;"
            "csrw mideleg, a0;"
            : [myid] "=r" (myid)
    );

    // Schedule the 1st timer interrupt, upon which the 2nd one will be scheduled
    // Get the current time (since boot) from mtim (mapped to 0x200bff8)
    ((uint64_t *)(0x2004000))[myid] = *((uint64_t *)(0x200bff8)) + 1000000;
    // Next interrupt happens at the current time plus an interval
    // This is saved into mtimecmp (mapped to 0x2004000)
    
    // Prepare the timer scratch space for mtrap() to directly obtain core-local
    // mtimecmp address and interrupt interval and to save registers to enable
    // stackless trap handling
    uint64_t *myscratch = mtrap_scratch[myid];
    myscratch[2] = (uint64_t)&((uint64_t *)(0x2004000))[myid];
    myscratch[3] = 10000000; // Change this to alter the timer interrupt frequency
    asm volatile (
            "mv a0, %[scratch_addr];"
            "csrw mscratch, a0;"
    // Install mtrap handler and enable M-mode timer interrupt
            // Install handler address to mtvec
            "mv a0, %[handler_addr];"
            "csrw mtvec, a0;"
            // Enable M-mode interrupts globally 
            "csrr a0, mstatus;"
            "addi a1, zero, (1 << 3);"
            "or a0, a0, a1;"
            "csrw mstatus, a0;"
            // Enable M-mode timer interrupt
            "csrr a0, mie;"
            "addi a1, zero, (1 << 7);"
            "or a0, a0, a1;"
            "csrw mie, a0;"
    // Prep to switch to S-mode
            // Set the mret address to main() in mepc
            "mv a0, %[main_addr];"
            "csrw mepc, a0;"
            // Set the previous mode to S-mode
            "csrr a0, mstatus;"
            "li a1, ~(3 << 11);"
            "and a0, a0, a1;"
            "li a1, (1 << 11);"
            "or a0, a0, a1;"
            "csrw mstatus, a0;"
            "mret;"
            :
            : [scratch_addr] "r" ((uint64_t)myscratch),
              [main_addr] "r" ((uint64_t)main),
              [handler_addr] "r" ((uint64_t)mtrap)
    );    

}

