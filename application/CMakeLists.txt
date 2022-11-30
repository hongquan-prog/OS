cmake_minimum_required(VERSION 3.16)

project(app)

# enable nasm
set_nasm_obj_format("elf")
ENABLE_LANGUAGE(ASM_NASM)

# c source list
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR} C_SOURCE)

# compile app-entry.o
set(APP_ENTRY app_entry)
add_library(${APP_ENTRY} OBJECT app-entry.asm)
# nasm include format eg: -I/usr/local/share/bochs/inc/
# the target_include_directories function will remove the character '/'
target_compile_options(${APP_ENTRY} PRIVATE ${COMMON_ASM_INCLUDE_OPTION})

# compile app.elf
add_executable(${APP_TARGET} ${C_SOURCE} ${COMMON_C_SOURCE} $<TARGET_OBJECTS:${APP_ENTRY}>)
set_target_properties(${APP_TARGET} PROPERTIES SUFFIX .elf)
target_compile_options(${APP_TARGET} PRIVATE -Wall -fdata-sections -ffunction-sections -m32 -fno-builtin -fno-stack-protector)
target_link_options(${APP_TARGET} PRIVATE -m elf_i386 -T${APP_LINK_SCRIPT})
target_include_directories(${APP_TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${COMMON_C_INCLUDE})

# elf convert to bin
add_custom_command(
    TARGET ${APP_TARGET}
    POST_BUILD 
    COMMAND 
    ${CMAKE_OBJCOPY} 
    -O binary 
    ${CMAKE_CURRENT_BINARY_DIR}/${APP_TARGET}.elf
    ${APP_BIN}
    )