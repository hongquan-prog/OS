cmake_minimum_required(VERSION 3.16)

project(kernel)

# enable nasm
set_nasm_obj_format("elf")
ENABLE_LANGUAGE(ASM_NASM)

# c source list
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR} C_SOURCE)

# compile kernel-entry.o
set(KERNEL_ENTRY kernel_entry)
add_library(${KERNEL_ENTRY} OBJECT kernel-entry.asm)
# nasm include format eg: -I/usr/local/share/bochs/inc/
# the target_include_directories function will remove the character '/'
target_compile_options(${KERNEL_ENTRY} PRIVATE ${COMMON_ASM_INCLUDE_OPTION})

# compile kernel.elf
add_executable(${KERNEL_TARGET} ${C_SOURCE} ${COMMON_C_SOURCE} $<TARGET_OBJECTS:${KERNEL_ENTRY}>)
set_target_properties(${KERNEL_TARGET} PROPERTIES SUFFIX .elf)
target_compile_options(${KERNEL_TARGET} PRIVATE -Wall -fdata-sections -ffunction-sections -m32 -fno-builtin -fno-stack-protector)
target_link_options(${KERNEL_TARGET} PRIVATE -m elf_i386 -T${KERNEL_LINK_SCRIPT})
target_include_directories(${KERNEL_TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${COMMON_C_INCLUDE})

# elf convert to bin
add_custom_command(
    TARGET ${KERNEL_TARGET}
    POST_BUILD 
    COMMAND 
    ${CMAKE_OBJCOPY} 
    -O binary 
    ${CMAKE_CURRENT_BINARY_DIR}/${KERNEL_TARGET}.elf
    ${KERNEL_BIN}
    )