# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.25

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /opt/homebrew/Cellar/cmake/3.25.2/bin/cmake

# The command to remove a file.
RM = /opt/homebrew/Cellar/cmake/3.25.2/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/conor/Desktop/pico/pico-apps/labs/lab09

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/conor/Desktop/pico/pico-apps/labs/lab09/build

# Utility rule file for cyw43_firmware_package.

# Include any custom commands dependencies for this target.
include pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/compiler_depend.make

# Include the progress variables for this target.
include pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/progress.make

pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package: pico-sdk/src/rp2_common/cyw43_driver/cyw43_resource.o

pico-sdk/src/rp2_common/cyw43_driver/cyw43_resource.o: /Users/conor/Desktop/pico/pico-sdk/lib/cyw43-driver/firmware/43439A0-7.95.49.00.combined
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/Users/conor/Desktop/pico/pico-apps/labs/lab09/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Generating cyw43_resource.o"
	cd /Users/conor/Desktop/pico/pico-sdk/lib/cyw43-driver/firmware && /opt/homebrew/bin/arm-none-eabi-objcopy -I binary -O elf32-littlearm -B arm --readonly-text --rename-section .data=.big_const,contents,alloc,load,readonly,data --redefine-sym _binary_43439A0_7_95_49_00_combined_start=fw_43439A0_7_95_49_00_start --redefine-sym _binary_43439A0_7_95_49_00_combined_end=fw_43439A0_7_95_49_00_end --redefine-sym _binary_43439A0_7_95_49_00_combined_size=fw_43439A0_7_95_49_00_size 43439A0-7.95.49.00.combined /Users/conor/Desktop/pico/pico-apps/labs/lab09/build/pico-sdk/src/rp2_common/cyw43_driver/cyw43_resource.o

cyw43_firmware_package: pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package
cyw43_firmware_package: pico-sdk/src/rp2_common/cyw43_driver/cyw43_resource.o
cyw43_firmware_package: pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/build.make
.PHONY : cyw43_firmware_package

# Rule to build all files generated by this target.
pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/build: cyw43_firmware_package
.PHONY : pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/build

pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/clean:
	cd /Users/conor/Desktop/pico/pico-apps/labs/lab09/build/pico-sdk/src/rp2_common/cyw43_driver && $(CMAKE_COMMAND) -P CMakeFiles/cyw43_firmware_package.dir/cmake_clean.cmake
.PHONY : pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/clean

pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/depend:
	cd /Users/conor/Desktop/pico/pico-apps/labs/lab09/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/conor/Desktop/pico/pico-apps/labs/lab09 /Users/conor/Desktop/pico/pico-sdk/src/rp2_common/cyw43_driver /Users/conor/Desktop/pico/pico-apps/labs/lab09/build /Users/conor/Desktop/pico/pico-apps/labs/lab09/build/pico-sdk/src/rp2_common/cyw43_driver /Users/conor/Desktop/pico/pico-apps/labs/lab09/build/pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : pico-sdk/src/rp2_common/cyw43_driver/CMakeFiles/cyw43_firmware_package.dir/depend

