#include "hardware/regs/addressmap.h"
#include "hardware/regs/m0plus.h"

.syntax unified                 @ Specify unified assembly syntax
.cpu    cortex-m0plus           @ Specify CPU type is Cortex M0+
.thumb                          @ Specify thumb assembly for RP2040
.global main_asm                @ Provide program starting address to the linker
.align 4                        @ Specify code alignment

.equ    SLEEP_TIME, 500         @ Specify the sleep time (in ms)
.equ    LED_GPIO_PIN, 25        @ Specify the pin that the LED is connected to
.equ    LED_GPIO_OUT, 1         @ Specify the direction of the GPIO pin
.equ    LED_VALUE_ON, 1         @ Specify the value that turns the LED "on"
.equ    LED_VALUE_OFF, 0        @ Specify the value that turns the LED "off"
.equ    SVC_ISR_OFFSET, 0x2C    @ The SVC is entry 11 in the vector table
.equ    SVC_MAX_INSTRS, 0x01    @ Maximum allowed SVC subroutines

@ Entry point to the ASM portion of the program
main_asm:
    bl      init_gpio_led       @ Initialise the GPIO LED pin
    bl      install_svc_isr     @ Install the SVC interrupt service routine
loop:
    svc     #0                  @ Call the SVC ISR with value 0 (turns on LED)
    nop                         @ Add a no-op instruction for alignment after SVC
    bl      do_sleep            @ Short pause before proceeding
    svc     #1                  @ Call the SVC ISR with value 1 (turns off LED)
    nop                         @ Add a no-op instruction for alignment after SVC
    bl      do_sleep            @ Add a short pause before proceeding
    b       loop                @ Always jump back to the start of the loop

@ Subroutine used to introduce a short delay in the application
do_sleep:
    push    {lr}                @ Push the contents of the link register onto the stack
    ldr     r0, =SLEEP_TIME     @ Set the value of SLEEP_TIME we want to wait for
    bl      sleep_ms            @ Sleep until SLEEP_TIME has elapsed
    pop     {pc}                @ Pop the stored address to the program counter

@ Subroutine used to initialise the PI Pico built-in LED
init_gpio_led:
    push    {lr}                @ Push the contents of the link register onto the stack
    movs    r0, #LED_GPIO_PIN   @ This value is the GPIO LED pin on the PI PICO board
    bl      asm_gpio_init       @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #LED_GPIO_PIN   @ This value is the GPIO LED pin on the PI PICO board
    movs    r1, #LED_GPIO_OUT   @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir    @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    pop     {pc}                @ Pop the stored address to the program counter

@ Subroutine used to install the SVC interrupt service handler
install_svc_isr:
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)    @ Load the address of the relocated Vector table base into r2
    ldr     r1, [r2]                                @ Load the value at memory address found in r2 to register r1 
    movs    r2, #SVC_ISR_OFFSET                     @ Load the offset needed to arrive at entry 11 in the vector table
    add     r2, r1                                  @ Add the offset to the table base and store in r2
    ldr     r0, =svc_isr                            @ Load the entry address of svc_isr into r0
    str     r0, [r2]                                @ Store this entry address at the memory address pointed to by r2 (entry 11 in the vector table)
    bx      lr                                      @ Branch back to where the install_svc_isr function was called

@ SVC interrupt service handler routine
.thumb_func                     @ Required for all interrupt service routines
svc_isr:
    push    {lr}                @ Push the contents of the link register onto the stack
    ldr     r0, [sp, #0x1C]     @ Retrieve the address of the SVC opcode
    subs    r0, #0x2            @ Subtract 2 from the opcode address
    ldr     r0, [r0]            @ Loads the value stored at the address pointed to by r0 to r0 (the opcode)
    ldr     r1, =#0xFF          @ Loads a value into r1 which will cause the lower 8-bits to be high in preparation for bitwise operation
    ands    r0, r1              @ Ands r0 and r1, removing the higher 8-bits from r0
    cmp     r0, #SVC_MAX_INSTRS @ Ensures r0 is not greater than the max possible instruction entry
    bgt     svc_done            @ Break from subroutine if it is
    adr     r1, svc_jmptbl      @ Loads the address of the SVC jump table into r1
    lsls    r0, #2              @ As each entry is 4 bits, the opcode is multiplied by 4 for memory traversal
    ldr     r1, [r1, r0]        @ Loads the value at the address pointed to by r1 (jump table base) incremements by the value in r0 (opcode offset) into r1
    mov     pc, r1              @ Moves the address of the SVC subroutine in r1 to the programme counter, thereby branching to the subroutine
svc_done:
    pop     {pc}                @ Return to the main programme

@ First function of SVC subroutine - turn on the LED
svc_num0:
    movs    r1, #LED_VALUE_ON
    movs    r0, #LED_GPIO_PIN
    bl      asm_gpio_put
    b       svc_done            @ Branch back to the main ISR when done

@ Second function of SVC subroutine - turn off the LED
svc_num1:
    movs    r1, #LED_VALUE_OFF
    movs    r0, #LED_GPIO_PIN
    bl      asm_gpio_put
    b       svc_done            @ Branch back to the main ISR when done

@ SVC function entry jump table.
.align 2
svc_jmptbl:
    .word svc_num0              @ Entry zero goes to SVC function #0.
    .word svc_num1              @ Entry one goes to SVC function #1.
    .word 0                     @ Null termination of the jump table.

@ Set data alignment
.data
    .align 4