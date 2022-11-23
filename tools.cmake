# find nasm compiler
find_program(NASM_COMPILER_PATH nasm) 
if (NOT NASM_COMPILER_PATH) 
    message(FATAL_ERROR "Cannot find nasm compiler: nasm") 
endif() 

# find c compiler
find_program(C_COMPILER_PATH gcc) 
if (NOT C_COMPILER_PATH) 
    message(FATAL_ERROR "Cannot find c compiler: gcc") 
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

    string(FIND "${BXIMAGE_OUTPUT}" "-func=" BXIMAGE_OPTION_POS)

    if (BXIMAGE_OPTION_POS STREQUAL "-1")
        set(BXIMAGE_PERFORM_OPTION "-create")
    else()
        set(BXIMAGE_PERFORM_OPTION "-func")
    endif()

    unset(BXIMAGE_OPTION_POS)
    unset(BXIMAGE_OUTPUT)
endif() 

# find bochs
find_path(BOCHS_PATH name BIOS-bochs-latest PATHS /usr/share/bochs /usr/local/share/bochs) 
if (NOT BOCHS_PATH) 
    message(FATAL_ERROR "Cannot find bochs virtual marchine")
endif() 

# find vgabios
find_path(VGABIOS_PATH name vgabios.bin PATHS /usr/share/vgabios /usr/local/share/vgabios) 
if (NOT VGABIOS_PATH) 
    message(FATAL_ERROR "Cannot find vgabios") 
endif() 

set(CMAKE_ASM_NASM_COMPILER ${NASM_COMPILER_PATH} CACHE STRING "nasm compiler")
set(CMAKE_C_COMPILER ${C_COMPILER_PATH} CACHE STRING "gnu c compiler")
set(CMAKE_LINKER ${LINKER_PATH} CACHE STRING "linker")
set(CMAKE_OBJCOPY ${OBJCOPY_PATH} CACHE STRING "objcopy")
set(CMAKE_DD ${DD_PATH} CACHE STRING "dd")
set(CMAKE_BXIMAGE ${BXIMAGE_PATH} CACHE STRING "bximage")
set(CMAKE_VGABIOS ${VGABIOS_PATH} CACHE STRING "vgabios")
set(CMAKE_BOCHS ${BOCHS_PATH} CACHE STRING "bochs virtual marchine")

unset(NASM_COMPILER_PATH)
unset(C_COMPILER_PATH)
unset(LINKER_PATH)
unset(OBJCOPY_PATH)
unset(DD_PATH)
unset(VGABIOS_PATH)
unset(BXIMAGE_PATH)
unset(BOCHS_PATH)
