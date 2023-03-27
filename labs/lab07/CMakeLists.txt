cmake_minimum_required(VERSION 3.13)
include(~/Desktop/pico/pico-apps/pico_sdk_import.cmake)
project(lab07 CXX C ASM)

pico_sdk_init()

# Specify the name of the executable.
add_executable(lab07
lab07.c
)

# Specify the source files to be compiled.
target_sources(lab07 PRIVATE lab07.c lab07.S)

# Pull in commonly used features.
target_link_libraries(lab07 pico_stdlib pico_multicore)

# Create map/bin/hex file etc.
pico_add_extra_outputs(lab07)

# Add the URL via pico_set_program_url.
#apps_auto_set_url(lab06)
