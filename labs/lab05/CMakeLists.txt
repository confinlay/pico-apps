cmake_minimum_required(VERSION 3.13)
include(~/Desktop/pico/pico-apps/pico_sdk_import.cmake)
project(lab05 CXX C ASM)

pico_sdk_init()

# Specify the name of the executable.
add_executable(lab05
    lab05.c
)

# Specify the source files to be compiled.
target_sources(lab05 PRIVATE lab05.c lab05.S)

# Pull in commonly used features.
target_link_libraries(lab05 pico_stdlib)

# Create map/bin/hex file etc.
pico_add_extra_outputs(lab05)

# Add the URL via pico_set_program_url.
#apps_auto_set_url(lab05)
