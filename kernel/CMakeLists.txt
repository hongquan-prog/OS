cmake_minimum_required(VERSION 3.16)

project(kernel)

set(KERNEL_ENTRY_OBJ ${CMAKE_CURRENT_BINARY_DIR}/kernel-entry.o)
set(KERNEL_ELF ${CMAKE_CURRENT_BINARY_DIR}/${KERNEL_TARGET}.elf)

# c source list
set(LINK_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/kernel.lds)
set(ASM_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/kernel-entry.asm)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR} C_SOURCE)

# compile kernel.elf
add_executable(${KERNEL_TARGET} ${C_SOURCE} ${COMMON_C_SOURCE})
set_target_properties(${KERNEL_TARGET} PROPERTIES SUFFIX .elf)
target_compile_options(${KERNEL_TARGET} PRIVATE -m32 -fno-builtin -fno-stack-protector)
target_link_options(${KERNEL_TARGET} PRIVATE -m elf_i386 -T${LINK_SCRIPT} ${KERNEL_ENTRY_OBJ})
target_include_directories(${KERNEL_TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${COMMON_C_INCLUDE})

# compile kernel-entry.o
add_custom_command(
    TARGET ${KERNEL_TARGET}
    PRE_LINK 
    COMMAND
    ${CMAKE_ASM_NASM_COMPILER} ${ASM_SOURCE}
    -f elf 
    -I ${CMAKE_SOURCE_DIR} -I ${COMMON_C_INCLUDE}
    -o ${KERNEL_ENTRY_OBJ}
    )

# elf convert to bin
add_custom_command(
    TARGET ${KERNEL_TARGET}
    POST_BUILD 
    COMMAND 
    ${CMAKE_OBJCOPY} 
    -O binary 
    ${KERNEL_ELF}
    ${KERNEL_BIN}
    )