
.text
.align 4
.global mtrap

mtrap:
    # Save a0 into mscratch and load mscratch into a0
    csrrw a0, mscratch, a0

# a0 no holds the address of the scratch space for this core

    # Save a1, a2, and a3 in the scratch space for using them
    sd a1, (a0)
    sd a2, 8(a0)

# Sechdule the next timer interrupt of the currnet one being handled at mtimecmp + interval
    # Get mtimecmp
    ld a1, 16(a0)
    ld a1, (a1)
    # Get interval
    ld a2, 24(a0)
    # Save mtimecmp + interval into mtimecmp
    add a2, a2, a1
    ld a1, 16(a0)
    sd a2, (a1)

# Arrange for a S-mode software interrupt, which is going to start the scheduler
    csrw sip, 1 << 1

# Restore a1, a2, and a0
    sd a1, (a0)
    sd a2, (a0)
    csrrw a0, mscratch, a0
    
    mret

    

