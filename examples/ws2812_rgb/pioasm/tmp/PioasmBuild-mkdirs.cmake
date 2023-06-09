# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/Users/conor/desktop/pico/pico-sdk/tools/pioasm"
  "/Users/conor/desktop/pico/pico-apps/pioasm"
  "/Users/conor/desktop/pico/pico-apps/examples/ws2812_rgb/pioasm"
  "/Users/conor/desktop/pico/pico-apps/examples/ws2812_rgb/pioasm/tmp"
  "/Users/conor/desktop/pico/pico-apps/examples/ws2812_rgb/pioasm/src/PioasmBuild-stamp"
  "/Users/conor/desktop/pico/pico-apps/examples/ws2812_rgb/pioasm/src"
  "/Users/conor/desktop/pico/pico-apps/examples/ws2812_rgb/pioasm/src/PioasmBuild-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/Users/conor/desktop/pico/pico-apps/examples/ws2812_rgb/pioasm/src/PioasmBuild-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/Users/conor/desktop/pico/pico-apps/examples/ws2812_rgb/pioasm/src/PioasmBuild-stamp${cfgdir}") # cfgdir has leading slash
endif()
