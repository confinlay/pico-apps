# Raspberry Pi Pico RP2040 Application Repository

This repository contains 12 applications created as part of a "Microprocessor Systems" university module. They were designed to run on a Raspberry Pi Pico RP2040, and were programmed using a combination of ARM Assembly and C.
**Yet to be completed: Labs 7-10, Assignment 2.**

## assignments

### assignments/assign01
A program which utilised alarm and IO hardware interrupts to allow for the build-in LED on the Pi Pico board to blink at a given rate. Interrupt service routines were created for each of 3 onboard buttons to allow for the LED flashing rate to be doubled, halved, stopped and reset based on the user's input. This program was entirely written in ARM assembly, only utilising basic wrapper functions written in C for IO initialising.


### assignments/assign02
A morse code game written in ARM assembly which tasks the player with correctly inputting more code messages using the built in button on the Pi Pico board. 

## labs

Top-level folder containing skeleton project templates for the ten course lab exercises.

### labs/lab01

A simple program to blink the built in LED on the Raspberry Pi Pico.

### labs/lab02

Used functions to implement the wallis product estimate of pi to a given number of iterations. Compared the accuracy obtained using single-precision floating-point values with that obtained by using double-precision floating-point values.

### labs/lab03

A program to toggle the state of the LED on the Pi Pico board when a button is pressed. This was done using flow control and not hardware interrupts.

### labs/lab04

Exercise to flash a second pico device to become a "picoprobe" for debugging purposes. 

### labs/lab05

A re-implementation of the blink project using interrupt service handler routines.

### labs/lab05

A program to measure the effect of running proccesses in parallel using the Pico's second core, rather than sequentially. The test functions used were the wallis product calculations from lab02.
## examples

Top level folder containing all example projects.

### examples/blink_asm

An assembly-based application that flashes the built-in LED of the Pi Pico board using subroutines with the delay between LED toggles set using a CPU sleep command.

### examples/blink_c

A C-based application that flashes the built-in LED of the Pi Pico board with the delay between LED toggles set using a CPU sleep command.

### examples/blink_svc

An assembly-based application that flashes the built-in LED of the Pi Pico board using SVC exception handlers with the delay between LED toggles set using a CPU sleep command.

### examples/hello_c

A C-based application that uses UART0 to print a "Hello World!" message to the console.

### examples/multi_c

A C-based application that uses both CPU cores to calculate factorial and Fibonacci sequences and display the results to the console.

### examples/ws2812_rgb

A C-based application that uses PIO to alternately flash the NeoPixel on the MAKER-PI-PICO board red, green then blue in a continuous loop.
