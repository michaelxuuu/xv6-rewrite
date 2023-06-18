SRC = $(wildcard *.c)
ASM = $(wildcard *.s)
OBJ = $(SRC:.c=.o) $(ASM:.s=.o)

CPUS = 1

QEMUOPTS = -machine virt -bios none -kernel kernel.bin -m 128M -smp $(CPUS) -nographic
QEMUOPTS += -global virtio-mmio.force-legacy=false
# QEMUOPTS += -drive file=,if=none,format=raw,id=x0
# QEMUOPTS += -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

QEMU = qemu-system-riscv64
TOOLPREFIX = riscv64-unknown-elf-

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)as
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -I.
CFLAGS += -fno-stack-protector

build: kernel.bin

qemu: kernel.bin
	$(QEMU) $(QEMUOPTS) -s -S

# Do `make gdb` and `make qemu` in two termianl windows; otherwise, ctrl-c would terminate qemu immediately
gdb:
	gdb -ex "target extended-remote localhost:1234" \
							-ex "symbol-file kernel.o"

kernel.bin: kernel.o
	$(OBJCOPY) $< $@ -O binary

kernel.o: entry.o $(OBJ)
	$(LD) -Tkernel.ld -o $@ $^

%.o : %.c
	$(CC) -c $(CFLAGS) -o $@ $< -g

%.o : %.s
	$(AS) -o $@ $< -g

clean:
	rm *.o kernel.bin

