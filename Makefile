# ARMGNU is a cross-compiler prefix. We need to use a cross-compiler because we are 
# compiling the source code for the arm64 architecture on an x86 machine. So instead 
# of gcc, we will use aarch64-linux-gnu-gcc.
ARMGNU ?= aarch64-linux-gnu

# Wall Show all warnings.

# nostdlib Don't use the C standard library. Most of the calls in the C standard library 
# eventually interact with the operating system. We are writing a bare-metal program, 
# and we don't have any underlying operating system, so the C standard library is not 
# going to work for us anyway.

# nostartfiles Don't use standard startup files. Startup files are responsible for 
# setting an initial stack pointer, initializing static data, and jumping to the main 
# entry point. We are going to do all of this by ourselves.

# ffreestanding A freestanding environment is an environment in which the standard library 
# may not exist, and program startup may not necessarily be at main. The option 
# -ffreestanding directs the compiler to not assume that standard functions have their 
# usual definition.

# mgeneral-regs-only. Use only general-purpose registers. ARM processors also have NEON 
# registers. We don't want the compiler to use them because they add additional complexity 
# (since, for example, we will need to store the registers during a context switch).
COPS = -Wall -nostdlib -nostartfiles -ffreestanding -Iinclude -mgeneral-regs-only
# Search for header files in the include folder.
ASMOPS = -Iinclude 

BUILD_DIR = build
SRC_DIR = src

all : kernel8.img

clean :
	rm -rf $(BUILD_DIR) *.img 

# These 2 are also targets

# Responsible for compiling C files
$(BUILD_DIR)/%_c.o: $(SRC_DIR)/%.c
	mkdir -p $(@D)
# -MMD parameter. This parameter instructs the gcc compiler to create a 
# dependency file for each generated object file. A dependency file defines 
# all of the dependencies for a particular source file. These dependencies 
# usually contain a list of all included headers. 
	$(ARMGNU)-gcc $(COPS) -MMD -c $< -o $@

# Responsible for compiling Assembler Files
$(BUILD_DIR)/%_s.o: $(SRC_DIR)/%.S
# -MMD parameter. This parameter instructs the gcc compiler to create a 
# dependency file for each generated object file. A dependency file defines 
# all of the dependencies for a particular source file. These dependencies 
# usually contain a list of all included headers. 
	$(ARMGNU)-gcc $(ASMOPS) -MMD -c $< -o $@

# Here we are building an array of all object files (OBJ_FILES) created from the 
# concatenation of both C and assembler source files.
C_FILES = $(wildcard $(SRC_DIR)/*.c)
ASM_FILES = $(wildcard $(SRC_DIR)/*.S)
OBJ_FILES = $(C_FILES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%_c.o)
OBJ_FILES += $(ASM_FILES:$(SRC_DIR)/%.S=$(BUILD_DIR)/%_s.o)

# We need to include all of the generated dependency files so that make knows what 
# exactly to recompile in case a header changes.
DEP_FILES = $(OBJ_FILES:%.o=%.d)
-include $(DEP_FILES)

kernel8.img: $(SRC_DIR)/linker.ld $(OBJ_FILES)
# We use the OBJ_FILES array to build the kernel8.elf file. We use the linker 
# script src/linker.ld to define the basic layout of the resulting executable image 
	$(ARMGNU)-ld -T $(SRC_DIR)/linker.ld -o $(BUILD_DIR)/kernel8.elf  $(OBJ_FILES)
# kernel8.elf is in the ELF format. The problem is that ELF files are designed 
# to be executed by an operating system. To write a bare-metal program, we need 
# to extract all executable and data sections from the ELF file and put them 
# into the kernel8.img image. The trailing 8 denotes ARMv8 which is a 64-bit 
# architecture. This filename tells the firmware to boot the processor into 64-bit 
# mode. 
	$(ARMGNU)-objcopy $(BUILD_DIR)/kernel8.elf -O binary kernel8.img
