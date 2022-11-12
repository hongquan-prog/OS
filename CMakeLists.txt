cmake_minimum_required(VERSION 3.16)

project(OS)
include(tools.cmake)

set(BOOT_TARGET boot)
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
aux_source_directory(${COMMON_C_INCLUDE} COMMON_C_SOURCE)

# compile bootloader kernel application
add_subdirectory(bootloader)
add_subdirectory(kernel)
add_subdirectory(application)

# generate floppy image
add_custom_command(OUTPUT ${OS_IMAGE}
    COMMAND 
    ${CMAKE_BXIMAGE}
    -q 
    -mode=create 
    -fd=1.44M 
    ${OS_IMAGE}
    )

# write mbr into floppy
add_custom_target(mbr ALL
    DEPENDS ${BOOT_TARGET} ${OS_IMAGE}
    COMMAND 
    ${CMAKE_DD}
    if=${CMAKE_CURRENT_BINARY_DIR}/${BOOT_TARGET}.bin
    of=${OS_IMAGE}
    bs=512 
    count=1 
    conv=notrunc
    )

# move kernel and app into floppy
add_custom_target(copy ALL
    DEPENDS ${OS_IMAGE} ${LOADER_TARGET} ${KERNEL_TARGET} ${APP_TARGET}
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