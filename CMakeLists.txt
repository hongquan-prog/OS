cmake_minimum_required(VERSION 3.16)

include(tools.cmake)
project(OS)

set(BOOT_TARGET boot)
set(MBR_TARGET mbr)
set(LOADER_TARGET loader)
set(KERNEL_TARGET kernel)
set(APP_TARGET app)

set(MOUNT_DIR  ${CMAKE_SOURCE_DIR}/mnt)
set(OS_IMAGE ${CMAKE_BINARY_DIR}/os.img)
set(BOOT_BIN ${CMAKE_BINARY_DIR}/boot.bin)
set(LOADER_BIN ${CMAKE_BINARY_DIR}/loader.bin)
set(KERNEL_BIN ${CMAKE_BINARY_DIR}/kernel.bin)
set(APP_BIN ${CMAKE_BINARY_DIR}/app.bin)

# common source and include directory
set(COMMON_C_INCLUDE ${CMAKE_SOURCE_DIR}/common)
set(NASM_COMMON_INCLUDE -I${CMAKE_SOURCE_DIR}/common/)
aux_source_directory(${COMMON_C_INCLUDE} COMMON_C_SOURCE)

# compile bootloader kernel application
add_subdirectory(bootloader)
add_subdirectory(kernel)
add_subdirectory(application)

# generate floppy image
add_custom_command(OUTPUT ${OS_IMAGE}
    COMMAND 
    ${BXIMAGE_TOOL}
    -q 
    ${BXIMAGE_PERFORM_OPTION}=create 
    -fd=1.44M 
    ${OS_IMAGE}
    )

# write mbr into floppy
add_custom_target(${MBR_TARGET}
    DEPENDS ${BOOT_TARGET} ${OS_IMAGE}
    COMMAND 
    ${DD_TOOL}
    if=${CMAKE_CURRENT_BINARY_DIR}/${BOOT_TARGET}.bin
    of=${OS_IMAGE}
    bs=512 
    count=1 
    conv=notrunc
    )

# create mnt dir
add_custom_command(OUTPUT ${MOUNT_DIR}
    COMMAND mkdir -p ${MOUNT_DIR}
    )

# move kernel and app into floppy
add_custom_target(copy ALL
    DEPENDS ${MBR_TARGET} ${LOADER_TARGET} ${KERNEL_TARGET} ${APP_TARGET} ${MOUNT_DIR}
    COMMAND
    sudo mount -o loop ${OS_IMAGE} ${MOUNT_DIR}
    COMMAND
	sudo cp ${LOADER_BIN} ${KERNEL_BIN} ${APP_BIN} ${MOUNT_DIR}
    COMMAND
	sleep 0.1
    COMMAND
	sudo umount ${MOUNT_DIR}
    )

# generate bochsrc
configure_file(${CMAKE_SOURCE_DIR}/bochs/bochsrc.in ${CMAKE_SOURCE_DIR}/bochsrc)