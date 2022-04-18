.PHONY:all clean rebuild install

CC := gcc-9
LD := ld
RM := rm -fr
NASM := nasm

BLFUNC_SRC := bootloader-func.asm
BOOT_SRC := boot.asm
BOOT_BIN := boot.bin

LOADER_SRC := loader.asm
INCLUDE_SRC := common.asm
LOADER_BIN := loader.bin

IMAGE_PATH := $(abspath .)
IMAGE := $(IMAGE_PATH)/boot.img
MOUNT_DIR := $(IMAGE_PATH)/mnt

DIR_BUILD := build
DIR_DEPS := $(DIR_BUILD)/deps
DIR_EXES := $(DIR_BUILD)/exes
DIR_OBJS := $(DIR_BUILD)/objs
DIRS := $(DIR_BUILD) $(DIR_DEPS) $(DIR_EXES) $(DIR_OBJS) $(MOUNT_DIR)

TYPE_SRC := .c
TYPE_INC := .h
TYPE_OBJ := .o
TYPE_DEP := .d
APP_DIR_SRC := application
APP_DIR_INC := application
COMMON_DIR_SRC := common
COMMON_DIR_INC := common
KERNEL_DIR_SRC := kernel
KERNEL_DIR_INC := kernel
vpath %$(TYPE_INC) $(KERNEL_DIR_INC):$(APP_DIR_INC):$(COMMON_DIR_INC)
vpath %$(TYPE_SRC) $(KERNEL_DIR_SRC):$(APP_DIR_SRC):$(COMMON_DIR_SRC)

CFLAGS := $(addprefix -I,$(KERNEL_DIR_INC) $(COMMON_DIR_INC) $(APP_DIR_INC))

KERNEL_SRC := $(wildcard $(KERNEL_DIR_SRC)/*$(TYPE_SRC))
KERNEL_SRC += $(wildcard $(COMMON_DIR_SRC)/*$(TYPE_SRC))
KERNEL_SRC := $(notdir $(KERNEL_SRC))
KERNEL_LDS := kernel.lds
KERNEL_BIN := kernel.bin
KERNEL_ENTRY_SRC := kernel-entry.asm
KERNEL_ENTRY_OUT := $(DIR_OBJS)/kernel-entry.o

KERNEL_OBJS := $(KERNEL_SRC:$(TYPE_SRC)=$(TYPE_OBJ))
KERNEL_OBJS := $(addprefix $(DIR_OBJS)/, $(KERNEL_OBJS))
KERNEL_DEPS := $(KERNEL_SRC:$(TYPE_SRC)=$(TYPE_DEP))
KERNEL_DEPS := $(addprefix $(DIR_DEPS)/, $(KERNEL_DEPS))

KERNEL_ELF := kernel.elf
KERNEL_ELF := $(addprefix $(DIR_EXES)/, $(KERNEL_ELF))

APP_SRC := $(wildcard $(APP_DIR_SRC)/*$(TYPE_SRC))
APP_SRC += $(wildcard $(COMMON_DIR_SRC)/*$(TYPE_SRC))
APP_SRC := $(notdir $(APP_SRC))
APP_LDS := app.lds
APP_BIN := app.bin
APP_ENTRY_SRC := app-entry.asm
APP_ENTRY_OUT := $(DIR_OBJS)/app-entry.o

APP_OBJS := $(APP_SRC:$(TYPE_SRC)=$(TYPE_OBJ))
APP_OBJS := $(addprefix $(DIR_OBJS)/, $(APP_OBJS))
APP_DEPS := $(APP_SRC:$(TYPE_SRC)=$(TYPE_DEP))
APP_DEPS := $(addprefix $(DIR_DEPS)/, $(APP_DEPS))

APP_ELF := app.elf
APP_ELF := $(addprefix $(DIR_EXES)/, $(APP_ELF))

all: $(DIRS) $(IMAGE) $(BOOT_BIN) install

$(DIRS) :
	mkdir -p $@

ifeq ("$(MAKECMDGOALS)", "all")
-include $(KERNEL_DEPS)
-include $(APP_DEPS)
endif

ifeq ("$(MAKECMDGOALS)", "")
-include $(KERNEL_DEPS)
-include $(APP_DEPS)
endif

$(IMAGE):
	bximage -q -func=create -fd=1.44M $@

$(BOOT_BIN):$(BOOT_SRC) $(BLFUNC_SRC)
	nasm $< -o $@
	dd if=$(BOOT_BIN) of=$(IMAGE) bs=512 count=1 conv=notrunc

$(LOADER_BIN):$(LOADER_SRC) $(INCLUDE_SRC) $(BLFUNC_SRC)
	nasm $< -o $@ 

$(KERNEL_ENTRY_OUT) : $(KERNEL_ENTRY_SRC) $(INCLUDE_SRC)
	nasm -f elf $< -o $@

$(KERNEL_BIN) : $(KERNEL_ELF) 
	objcopy -O binary $< $@

$(KERNEL_ELF) : $(KERNEL_ENTRY_OUT) $(KERNEL_OBJS)
	$(LD) -m elf_i386 $^ -o $@ -T$(KERNEL_LDS)

$(APP_ENTRY_OUT) : $(APP_ENTRY_SRC) $(INCLUDE_SRC)
	nasm -f elf $< -o $@

$(APP_BIN) : $(APP_ELF) 
	objcopy -O binary $< $@

$(APP_ELF) : $(APP_ENTRY_OUT) $(APP_OBJS)
	$(LD) -m elf_i386 $^ -o $@ -T$(APP_LDS)

$(DIR_OBJS)/%$(TYPE_OBJ) : %$(TYPE_SRC)
	$(CC) $(CFLAGS) -m32 -fno-builtin -fno-stack-protector -c $(filter %$(TYPE_SRC), $^) -o $@

ifeq ("$(wildcard $(DIR_DEPS))", "")
$(DIR_DEPS)/%$(TYPE_DEP) : $(DIR_DEPS) %$(TYPE_SRC)
else
$(DIR_DEPS)/%$(TYPE_DEP) : %$(TYPE_SRC)
endif
	@echo "Creating $@ ..."
	@set -e; \
	$(CC) $(CFLAGS) -MM -E $(filter %$(TYPE_SRC), $^) | sed 's,\(.*\)\.o[ :]*,$(DIR_OBJS)/\1.o $@ : ,g' > $@

install:$(LOADER_BIN) $(KERNEL_BIN) $(APP_BIN)
	sudo mount -o loop $(IMAGE) $(MOUNT_DIR) 
	sudo cp $^ $(MOUNT_DIR)/
	sleep 0.1
	sudo umount $(MOUNT_DIR) 

clean: 
	$(RM) $(BOOT_BIN) $(LOADER_BIN) $(KERNEL_BIN) $(APP_BIN) $(DIRS) $(IMAGE)

rebuild: clean all