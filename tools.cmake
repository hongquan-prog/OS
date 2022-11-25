# find nasm compiler
find_program(NASM_COMPILER_PATH nasm) 
if (NOT NASM_COMPILER_PATH) 
    message(FATAL_ERROR "Cannot find nasm compiler: nasm") 
endif() 

# find c compiler
if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
    find_program(CLANG_PATH clang) 
    if (NOT CLANG_PATH) 
        message(FATAL_ERROR "Cannot find apple clang compiler: clang") 
    endif()  
else()
    find_program(GCC_PATH gcc) 
    if (NOT GCC_PATH) 
        message(FATAL_ERROR "Cannot find gnu c compiler: gcc") 
    endif() 
endif()

# find linker
find_program(LINKER_PATH ld) 
if (NOT LINKER_PATH) 
    message(FATAL_ERROR "Cannot find linker: ld") 
endif() 
SET(CMAKE_C_LINK_EXECUTABLE "${LINKER_PATH} <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS>  -o <TARGET>")

# find objcopy
find_program(OBJCOPY_PATH ld) 
if (NOT OBJCOPY_PATH) 
    message(FATAL_ERROR "Cannot find objcopy") 
endif() 

# find dd
find_program(DD_PATH dd) 
if (NOT DD_PATH) 
    message(FATAL_ERROR "Cannot find dd command: dd") 
endif() 

# find bximage
find_program(BXIMAGE_PATH bximage) 
if (NOT BXIMAGE_PATH) 
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
if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
    find_path(BOCHS_BIOS_PATH name BIOS-bochs-latest PATHS /opt/homebrew/share/bochs) 
else()
    find_path(BOCHS_BIOS_PATH name BIOS-bochs-latest PATHS /usr/share/bochs /usr/local/share/bochs)
endif()

if(NOT BOCHS_BIOS_PATH)
    message(FATAL_ERROR "Cannot find bochs virtual marchine")
endif() 

if(GCC_PATH)
    set(CMAKE_C_COMPILER ${GCC_PATH} CACHE STRING "gnu c compiler")
else()
    set(CMAKE_C_COMPILER ${CLANG_PATH} CACHE STRING "apple clang compiler")
endif()

set(CMAKE_ASM_NASM_COMPILER ${NASM_COMPILER_PATH} CACHE STRING "nasm compiler")
set(CMAKE_LINKER ${LINKER_PATH} CACHE STRING "linker")
set(CMAKE_OBJCOPY ${OBJCOPY_PATH} CACHE STRING "objcopy")
set(CMAKE_DD ${DD_PATH} CACHE STRING "dd")
set(CMAKE_BXIMAGE ${BXIMAGE_PATH} CACHE STRING "bximage")
set(BOCHS_PATH ${BOCHS_BIOS_PATH} CACHE STRING "bochs virtual marchine")

unset(NASM_COMPILER_PATH)
unset(GCC_PATH)
unset(CLANG_PATH)
unset(LINKER_PATH)
unset(OBJCOPY_PATH)
unset(DD_PATH)
unset(BXIMAGE_PATH)
unset(BOCHS_BIOS_PATH)
