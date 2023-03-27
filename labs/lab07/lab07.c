#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "pico/stdlib.h"
#include "pico/float.h"     // Required for using single-precision variables.
#include "pico/double.h"    // Required for using double-precision variables.
#include "hardware/timer.h"
#include "pico/multicore.h"

//function declarations
float wallis_float(float iter); 
double wallis_double(double iter);
//definition of correct value of pi
const double pi = 3.14159265359;

const int ITER_MAX = 100000; // iterations of wallis_product
uint32_t float_elapsed_time; // global variable for measuring elapsed time in core 1

// union variable necessary for casting the int return value from the FIFO buffer to a float variable
union {
  int integer;
  float floater;
} pi_float_un;

// Function to get the enable status of the XIP cache
bool get_xip_cache_en();

// Function to set the enable status of the XIP cache
bool set_xip_cache_en(bool cache_en);

void core1_entry() {
    while (1) {
        // 
        int32_t (*func)() = (int32_t(*)()) multicore_fifo_pop_blocking();
        int32_t p = multicore_fifo_pop_blocking();
        int32_t result = (*func)(p);
        multicore_fifo_push_blocking(result);
    }
}

int main() {

#ifndef WOKWI
    // Initialise the IO as we will be using the UART
    // Only required for hardware and not needed for Wokwi
    stdio_init_all();
#endif
multicore_launch_core1(core1_entry); // Launch core 1

    // SEQUENTIAL SOLUTION (with caching)

    set_xip_cache_en(1);

    uint32_t total_start_time = time_us_32(); // Start timer for both calculations of pi

    uint32_t float_start_time = time_us_32(); // Start timer for float calculation of pi
    float pi_float = 2*wallis_float(ITER_MAX); // Assign single-precision wallis product estimate to a double variable.
    uint32_t float_end_time = time_us_32(); // End timer for float calculation of pi
    
    uint32_t double_start_time = time_us_32(); // Start timer for double calculation of pi
    double pi_double = 2*wallis_double(ITER_MAX); // Assign double-precision wallis product estimate to a double variable.
    uint32_t double_end_time = time_us_32(); // End timer for double calculation of pi

    uint32_t total_end_time = time_us_32(); // End timer for both calculations of pi

    // Calculate elapsed time for various start/end times
    uint32_t double_elapsed_time = double_end_time - double_start_time;
    float_elapsed_time = float_end_time - float_start_time;
    uint32_t total_elapsed_time = total_end_time - total_start_time;
    

    //Calculate approximation error and assign to a double variable
    double pi_double_error = fabs(100*(pi_double - pi)/pi);
    //Calculate approximation error and assign to float variable
    float pi_float_error = fabs(100*(pi_float - pi)/pi);

    //Print results
    printf("\nSEQUENTIAL SOLUTION (with caching enabled): \n");
    printf("\nEstimate of PI using single-precision representation: %f \n", pi_float);
    printf("Approximation error: %lf%%\n", pi_float_error);
    printf("Elapsed time using single-precision: %i microseconds\n", float_elapsed_time);
    printf("\nEstimate of PI using double-precision representation: %lf \n", pi_double);
    printf("Approximation error: %lf%%\n", pi_double_error);
    printf("Elapsed time using double-precision: %i microseconds\n", double_elapsed_time);
    printf("\nTotal elapsed time: %i microseconds\n\n", total_elapsed_time);

    // SEQUENTIAL SOLUTION (without caching)

    set_xip_cache_en(0);
    pi_float = 0;
    pi_double = 0;

    total_start_time = time_us_32(); // Start timer for both calculations of pi

    float_start_time = time_us_32(); // Start timer for float calculation of pi
    pi_float = 2*wallis_float(ITER_MAX); // Assign single-precision wallis product estimate to a double variable.
    float_end_time = time_us_32(); // End timer for float calculation of pi
    
    double_start_time = time_us_32(); // Start timer for double calculation of pi
    pi_double = 2*wallis_double(ITER_MAX+1); // Iterate ITER_MAX by 1 to force the pico to call the function again, rather than simply passing back the value previously calculated
    double_end_time = time_us_32(); // End timer for double calculation of pi

    total_end_time = time_us_32(); // End timer for both calculations of pi

    // Calculate elapsed time for various start/end times
    double_elapsed_time = double_end_time - double_start_time;
    float_elapsed_time = float_end_time - float_start_time;
    total_elapsed_time = total_end_time - total_start_time;
    

    //Calculate approximation error and assign to a double variable
    pi_double_error = fabs(100*(pi_double - pi)/pi);
    //Calculate approximation error and assign to float variable
    pi_float_error = fabs(100*(pi_float - pi)/pi);

    //Print results
    printf("\nSEQUENTIAL SOLUTION (with caching disabled): \n");
    printf("\nEstimate of PI using single-precision representation: %f \n", pi_float);
    printf("Approximation error: %lf%%\n", pi_float_error);
    printf("Elapsed time using single-precision: %i microseconds\n", float_elapsed_time);
    printf("\nEstimate of PI using double-precision representation: %lf \n", pi_double);
    printf("Approximation error: %lf%%\n", pi_double_error);
    printf("Elapsed time using double-precision: %i microseconds\n", double_elapsed_time);
    printf("\nTotal elapsed time: %i microseconds\n\n", total_elapsed_time);

    // PARALLEL SOLUTION (with caching)

    set_xip_cache_en(1);

    total_start_time = time_us_32(); // Start timer for both calculations of pi
    multicore_fifo_push_blocking((uintptr_t)&wallis_float); // Launch "wallis_float" function on core 1
    multicore_fifo_push_blocking(ITER_MAX); // Pass ITER_MAX as a parameter

    double_start_time = time_us_32(); // Start timer for double calculation of pi
    //ITER_MAX+1 is passed as a parameter below to avoid the pico caching the value of wallis_double(ITER_MAX) from the function call in the sequential solution
    pi_double = 2*wallis_double(ITER_MAX+2); // Iterate ITER_MAX by 1 to force the pico to call the function again, rather than simply passing back the value previously calculated
    double_end_time = time_us_32(); // End timer for double calculation of pi

    pi_float_un.integer = multicore_fifo_pop_blocking(); // Return value from core 1
    total_end_time = time_us_32(); // End timer for both calculations of pi

    // Calculate elapsed time for various start/end times
    double_elapsed_time = double_end_time - double_start_time; 
    total_elapsed_time = total_end_time - total_start_time;

    pi_float = 2*pi_float_un.floater; // Assign float value in union variable to seperate float variable (and double it)

    //Calculate approximation error and assign to a double variable
    pi_double_error = fabs(100*(pi_double - pi)/pi);
    //Calculate approximation error and assign to double variable
    pi_float_error = fabs(100*(pi_float - pi)/pi);

    //Print results
    printf("\nPARELLEL SOLUTION (with caching enabled): \n");
    printf("\nEstimate of PI using single-precision representation: %f \n", pi_float);
    printf("Approximation error: %lf%%\n", pi_float_error);
    printf("Elapsed time using single-precision: %i microseconds\n", float_elapsed_time);
    printf("\nEstimate of PI using double-precision representation: %lf \n", pi_double);
    printf("Approximation error: %lf%%\n", pi_double_error);
    printf("Elapsed time using double-precision: %i microseconds\n", double_elapsed_time);
    printf("\nTotal elapsed time: %i microseconds\n", total_elapsed_time);

    // PARALLEL SOLUTION (without caching)

    set_xip_cache_en(0);

    total_start_time = time_us_32(); // Start timer for both calculations of pi
    multicore_fifo_push_blocking((uintptr_t)&wallis_float); // Launch "wallis_float" function on core 1
    multicore_fifo_push_blocking(ITER_MAX); // Pass ITER_MAX as a parameter

    double_start_time = time_us_32(); // Start timer for double calculation of pi
    //ITER_MAX+1 is passed as a parameter below to avoid the pico caching the value of wallis_double(ITER_MAX) from the function call in the sequential solution
    pi_double = 2*wallis_double(ITER_MAX+3); // Iterate ITER_MAX by 1 to force the pico to call the function again, rather than simply passing back the value previously calculated
    double_end_time = time_us_32(); // End timer for double calculation of pi

    pi_float_un.integer = multicore_fifo_pop_blocking(); // Return value from core 1
    total_end_time = time_us_32(); // End timer for both calculations of pi

    // Calculate elapsed time for various start/end times
    double_elapsed_time = double_end_time - double_start_time; 
    total_elapsed_time = total_end_time - total_start_time;

    pi_float = 2*pi_float_un.floater; // Assign float value in union variable to seperate float variable (and double it)

    //Calculate approximation error and assign to a double variable
    pi_double_error = fabs(100*(pi_double - pi)/pi);
    //Calculate approximation error and assign to double variable
    pi_float_error = fabs(100*(pi_float - pi)/pi);

    //Print results
    printf("\nPARELLEL SOLUTION (with caching disabled): \n");
    printf("\nEstimate of PI using single-precision representation: %f \n", pi_float);
    printf("Approximation error: %lf%%\n", pi_float_error);
    printf("Elapsed time using single-precision: %i microseconds\n", float_elapsed_time);
    printf("\nEstimate of PI using double-precision representation: %lf \n", pi_double);
    printf("Approximation error: %lf%%\n", pi_double_error);
    printf("Elapsed time using double-precision: %i microseconds\n", double_elapsed_time);
    printf("\nTotal elapsed time: %i microseconds\n", total_elapsed_time);

    // Returning zero indicates everything went okay.
    return 0;
}

float wallis_float(float iter){
  uint32_t float_start_time = time_us_32(); // Start timer for float calculation of pi
  float x = 1.0; // Initialise x to 1 as function is multiplicative
  // Calculate wallis product for ITER_MAX iterations
  for(float n = 1; n <= 10000; n+=1.0){
    x = x*(4*n*n)/(4*n*n-1);
  }
  uint32_t float_end_time = time_us_32(); // End timer for float calculation of pi
  float_elapsed_time = float_end_time - float_start_time; // Calculate elapsed time
  return x; // Return wallis product
}

double wallis_double(double iter){
  double x = 1.0; // Initialise x to 1 as function is multiplicative
  // Calculate wallis product for ITER_MAX iterations
  for(double n = 1; n <= iter; n+=1.0){
    x = x*(4*n*n)/(4*n*n-1);
  }
  return x; // Return wallis produc
}

// function to return the value contained in bit 0 of the XIP_CTRL_BASE address (no offset is needed)
bool get_xip_cache_en(){
    uint32_t enabled;
    enabled = *(volatile uint32_t *)(XIP_CTRL_BASE) & 0x00000001; // enabled will be 1 if caching is enabled, and 0 if it is disabled
    return(enabled > 0); // return whether caching is enabled
}

// function to set the appropriate bit in the value located at XIP_CTRL_BASE in order to turn caching on/off
bool set_xip_cache_en(bool cache_en){
    if(cache_en)
        *(volatile uint32_t *)(XIP_CTRL_BASE)|= 0x00000001; // Set bit 0 to 1 if parameter indicates that caching should be enabled
    else
        *(volatile uint32_t *)(XIP_CTRL_BASE) &= 0xFFFFFFFE; // Set bit 0 to 0 if parameter indicates that caching should be disabled
}