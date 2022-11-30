cmake_minimum_required(VERSION 3.16)

project(bootloader)

# enable nasm
set_nasm_obj_format("bin")
ENABLE_LANGUAGE(ASM_NASM)

# compile boot.bin
add_executable(${BOOT_TARGET} boot.asm)
set_target_properties(${BOOT_TARGET} PROPERTIES SUFFIX .bin)
# nasm include format eg: -I/usr/local/share/bochs/inc/
# the target_include_directories function will remove the character '/'
target_compile_options(${BOOT_TARGET} PRIVATE ${COMMON_ASM_INCLUDE_OPTION})

# compile loader.bin
add_executable(${LOADER_TARGET} loader.asm)
set_target_properties(${LOADER_TARGET} PROPERTIES SUFFIX .bin)
# nasm include format eg: -I/usr/local/share/bochs/inc/
# the target_include_directories function will remove the character '/'
target_compile_options(${LOADER_TARGET} PRIVATE ${COMMON_ASM_INCLUDE_OPTION})

# move boot.bin and loader.bin to build directory
add_custom_command(
    TARGET ${BOOT_TARGET}
    POST_BUILD 
    COMMAND 
    cp ${CMAKE_CURRENT_BINARY_DIR}/${BOOT_TARGET}.bin ${BOOT_BIN}
    )

add_custom_command(
    TARGET ${LOADER_TARGET}
    POST_BUILD 
    COMMAND 
    cp ${CMAKE_CURRENT_BINARY_DIR}/${LOADER_TARGET}.bin ${LOADER_BIN}
    )