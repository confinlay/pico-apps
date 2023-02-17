#include "pico/stdlib.h"

/**
 * @brief EXAMPLE - BLINK_C
 *        Simple example to initialise the built-in LED on
 *        the Raspberry Pi Pico and then flash it forever.
 *
 * @return int  Application return code (zero for success).
 */

void toggleon(int pin, int delay);
void toggleoff(int pin, int delay);

int main() {
    // Specify the PIN number and sleep delay
    const uint LED_PIN   =  25;
    const uint LED_DELAY = 500;

    // Setup the LED pin as an output.
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);

    // Do forever...
    while (true) {
        //Call toggle functions
        toggleon(LED_PIN, LED_DELAY);
        toggleoff(LED_PIN, LED_DELAY);
    }

    // Should never get here due to infinite while-loop.
    return 0;

}

//Function to toggle the LED on, taking LED pin and delay as parameters
void toggleon(int pin, int delay){
    // Toggle the LED on and then sleep for delay period
    gpio_put(pin, 1);
    sleep_ms(delay);
}

//Function to toggle the LED off, taking LED pin and delay as parameters
void toggleoff(int pin, int delay){
    // Toggle the LED off and then sleep for delay period
    gpio_put(pin, 0);
    sleep_ms(delay);
}