cmake_minimum_required(VERSION 3.16)

project(app)

set(APP_ENTRY_OBJ ${CMAKE_CURRENT_BINARY_DIR}/app-entry.o)
set(APP_ELF ${CMAKE_CURRENT_BINARY_DIR}/${APP_TARGET}.elf)

# c source list
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR} C_SOURCE)
set(LINK_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/app.lds)
set(ASM_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/app-entry.asm)

# compile app.elf
add_executable(${APP_TARGET} ${C_SOURCE} ${COMMON_C_SOURCE})
set_target_properties(${APP_TARGET} PROPERTIES SUFFIX .elf)
target_compile_options(${APP_TARGET} PRIVATE -Wall -fdata-sections -ffunction-sections -m32 -fno-builtin -fno-stack-protector)
target_link_options(${APP_TARGET} PRIVATE -m elf_i386 -T${CMAKE_CURRENT_SOURCE_DIR}/app.lds ${APP_ENTRY_OBJ})
target_include_directories(${APP_TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${COMMON_C_INCLUDE})

# compile app-entry.o
add_custom_command(
    TARGET ${APP_TARGET}
    PRE_LINK 
    COMMAND
    ${CMAKE_ASM_NASM_COMPILER} ${CMAKE_CURRENT_SOURCE_DIR}/app-entry.asm
    -f elf 
    ${NASM_COMMON_INCLUDE}
    -o ${APP_ENTRY_OBJ}
    )

# elf convert to bin
add_custom_command(
    TARGET ${APP_TARGET}
    POST_BUILD 
    COMMAND 
    ${CMAKE_OBJCOPY} 
    -O binary 
    ${APP_ELF}
    ${APP_BIN}
    )