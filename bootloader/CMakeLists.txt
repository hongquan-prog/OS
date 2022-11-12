cmake_minimum_required(VERSION 3.16)

project(bootloader)

# enable nasm
set(CMAKE_ASM_NASM_SOURCE_FILE_EXTENSIONS nasm asm S)
set(CMAKE_ASM_NASM_OBJECT_FORMAT bin)
set(CMAKE_ASM_NASM_FLAGS "-e")
set(CMAKE_ASM_NASM_LINK_EXECUTABLE "nasm <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
ENABLE_LANGUAGE(ASM_NASM)

# compile boot.bin
add_executable(${BOOT_TARGET} boot.asm)
set_target_properties(${BOOT_TARGET} PROPERTIES SUFFIX .bin)
target_compile_options(${BOOT_TARGET} PRIVATE -I${COMMON_C_INCLUDE})

# compile loader.bin
add_executable(${LOADER_TARGET} loader.asm)
set_target_properties(${LOADER_TARGET} PROPERTIES SUFFIX .bin)
target_compile_options(${LOADER_TARGET} PRIVATE -I${COMMON_C_INCLUDE})

# generate floppy image
add_custom_command(
    TARGET ${BOOT_TARGET}
    PRE_BUILD 
    COMMAND 
    ${CMAKE_BXIMAGE}
    -q 
    -mode=create 
    -fd=1.44M 
    ${BOOT_IMAGE}
    )

# write boot into image
add_custom_command(
    TARGET ${BOOT_TARGET}
    POST_BUILD 
    COMMAND 
    ${CMAKE_DD}
    if=${CMAKE_CURRENT_BINARY_DIR}/${BOOT_TARGET}.bin
    of=${BOOT_IMAGE}
    bs=512 
    count=1 
    conv=notrunc
    )

# write boot into image
add_custom_command(
    TARGET ${LOADER_TARGET}
    POST_BUILD 
    COMMAND 
    cp ${CMAKE_CURRENT_BINARY_DIR}/${LOADER_TARGET}.bin ${LOADER_BIN}
    )