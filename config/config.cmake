set(CONFIG_KERNEL_LINK_ADDR 0xB000 CACHE STRING "kernel start address")
set(CONFIG_APP_LINK_ADDR 0xF000 CACHE STRING "application start address")

set(KERNEL_LINK_SCRIPT ${CMAKE_BINARY_DIR}/kernel.lds)
set(APP_LINK_SCRIPT ${CMAKE_BINARY_DIR}/app.lds)

# generate link script
configure_file(${CMAKE_CURRENT_LIST_DIR}/kernel.lds.in ${KERNEL_LINK_SCRIPT})
configure_file(${CMAKE_CURRENT_LIST_DIR}/app.lds.in ${APP_LINK_SCRIPT})