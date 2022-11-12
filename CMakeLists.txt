cmake_minimum_required(VERSION 3.16)

project(OS)
include(tools.cmake)

set(BOOT_TARGET boot)
set(LOADER_TARGET loader)
set(KERNEL_TARGET kernel)
set(APP_TARGET app)

set(MOUNT_DIR  ${CMAKE_SOURCE_DIR}/mnt)
set(BOOT_IMAGE ${CMAKE_BINARY_DIR}/boot.img)
set(LOADER_BIN ${CMAKE_BINARY_DIR}/${LOADER_TARGET}.bin)
set(KERNEL_BIN ${CMAKE_BINARY_DIR}/${KERNEL_TARGET}.bin)
set(APP_BIN ${CMAKE_BINARY_DIR}/${APP_TARGET}.bin)

# generate bochsrc
configure_file(${CMAKE_SOURCE_DIR}/bochs/bochsrc.in ${CMAKE_SOURCE_DIR}/bochsrc)

# common source and include directory
set(COMMON_C_INCLUDE ${CMAKE_SOURCE_DIR}/common)
aux_source_directory(${COMMON_C_INCLUDE} COMMON_C_SOURCE)

add_subdirectory(bootloader)
add_subdirectory(kernel)
add_subdirectory(application)

# write kernel and app
add_custom_target(Name ALL
    DEPENDS ${BOOT_TARGET} ${LOADER_TARGET} ${KERNEL_TARGET} ${APP_TARGET}
    COMMAND
    sudo mount -o loop ${BOOT_IMAGE} ${MOUNT_DIR}
    COMMAND
	sudo cp ${LOADER_BIN} ${KERNEL_BIN} ${APP_BIN} ${MOUNT_DIR}
    COMMAND
	sleep 0.1
    COMMAND
	sudo umount ${MOUNT_DIR}
    )