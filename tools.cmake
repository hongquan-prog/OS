set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ADM64)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# find nasm compiler
find_program(CMAKE_ASM_NASM_COMPILER nasm) 
if (NOT CMAKE_ASM_NASM_COMPILER) 
    message(FATAL_ERROR "Cannot find nasm compiler: nasm") 
endif() 

# find c compiler
find_program(CMAKE_C_COMPILER gcc) 
if (NOT CMAKE_C_COMPILER) 
    message(FATAL_ERROR "Cannot find gnu c compiler: gcc") 
endif() 
find_program(CMAKE_CXX_COMPILER g++) 
if (NOT CMAKE_CXX_COMPILER) 
    message(FATAL_ERROR "Cannot find gnu c++ compiler: g++") 
endif() 

# find linker
find_program(CMAKE_LINKER ld) 
if (NOT CMAKE_LINKER) 
    message(FATAL_ERROR "Cannot find linker: ld") 
endif() 
SET(CMAKE_C_LINK_EXECUTABLE "${CMAKE_LINKER} <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET>")

# find objcopy
find_program(CMAKE_OBJCOPY objcopy) 
if (NOT CMAKE_OBJCOPY) 
    message(FATAL_ERROR "Cannot find objcopy") 
endif() 

# find dd
find_program(DD_TOOL dd) 
if (NOT DD_TOOL) 
    message(FATAL_ERROR "Cannot find dd command: dd") 
endif() 

# find bximage
find_program(BXIMAGE_TOOL bximage) 
if (NOT BXIMAGE_TOOL) 
    message(FATAL_ERROR "Cannot find bximage command: bximage") 
else()
    execute_process(COMMAND bximage 
    --help
    OUTPUT_VARIABLE BXIMAGE_OUTPUT
    ERROR_VARIABLE BXIMAGE_OUTPUT)

    string(FIND "${BXIMAGE_OUTPUT}" "-func=" POS)
    if (NOT POS STREQUAL "-1")
        set(BXIMAGE_PERFORM_OPTION "-func")
    endif()

    string(FIND "${BXIMAGE_OUTPUT}" "-mode=" POS)
    if (NOT POS STREQUAL "-1")
        set(BXIMAGE_PERFORM_OPTION "-mode")
    endif()

    unset(POS)
    unset(BXIMAGE_OUTPUT)
endif() 

# find bochs
find_path(BOCHS_BIOS_PATH name BIOS-bochs-latest PATHS /usr/share/bochs /usr/local/share/bochs)

if(NOT BOCHS_BIOS_PATH)
    message(FATAL_ERROR "Cannot find bochs virtual marchine")
endif() 

# generate bochsrc
configure_file(${CMAKE_SOURCE_DIR}/config/bochsrc.in ${CMAKE_SOURCE_DIR}/bochsrc)


