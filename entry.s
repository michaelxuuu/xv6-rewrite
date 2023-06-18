# Kernel entry, linked to the very begining of the binary
# where `qemu -kernel` jumps

.text
.global _entry
.extern stack0 # per-core stacks used during boot

_entry:
    csrr a0, mhartid
    addi a0, a0, 1
    slli a0, a0, 12
    la sp, stack0
    add sp, sp, a0
    call start
    j .

