cmake_minimum_required(VERSION 3.13)
include(~/Desktop/pico/pico-apps/pico_sdk_import.cmake)
project(lab04 CXX C ASM)

pico_sdk_init()

# Specify the name of the executable.
add_executable(lab04
    lab04.c
)

# Specify the source files to be compiled.
target_sources(lab04 PRIVATE lab04.c lab04.S)

# Pull in commonly used features.
target_link_libraries(lab04  pico_stdlib)

# Create map/bin/hex file etc.
pico_add_extra_outputs(lab04)

# Add the URL via pico_set_program_url.
#apps_auto_set_url(lab04)
