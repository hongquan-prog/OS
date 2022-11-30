function(set_nasm_obj_format output_format)
    set(CMAKE_ASM_NASM_SOURCE_FILE_EXTENSIONS nasm asm s PARENT_SCOPE)

    if(${output_format} STREQUAL "elf")
        set(CMAKE_ASM_NASM_OBJECT_FORMAT elf PARENT_SCOPE)
    elseif(${output_format} STREQUAL "bin")
        set(CMAKE_ASM_NASM_FLAGS "-e" PARENT_SCOPE)
        set(CMAKE_ASM_NASM_OBJECT_FORMAT bin PARENT_SCOPE)
    else()
        message(FATAL_ERROR "unsupported nasm output format: ${output_format}")
    endif()

    set(CMAKE_ASM_NASM_LINK_EXECUTABLE "nasm <OBJECTS> -o <TARGET> <LINK_LIBRARIES>" PARENT_SCOPE)
endfunction()

