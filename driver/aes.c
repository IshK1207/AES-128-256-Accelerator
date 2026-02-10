/***************************************************************************
* Project           		:  shakti devt board
* Name of the file	     	:  hello.c
* Brief Description of file     :  Does the printing of hello with the help of uart communication protocol.
* Name of Author    	        :  Sathya Narayanan N
* Email ID                      :  sathya281@gmail.com

 Copyright (C) 2019  IIT Madras. All rights reserved.

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.

***************************************************************************/
/**
@file hello.c
@brief Prints "Hello world !" in the uart terminal.
*/

#include "uart.h"

/** @fn void main()
 * @brief prints hello world
 */
/*void main()
{
	printf ("Hello World !\n");
	while(1);
}*/

#define AES_BASE 0x00044500

#include <stdint.h>

static uint32_t rng_state = 0x1A2B3C4D;   // any non-zero seed
uint32_t rand_u32(void)
{
uint32_t x = rng_state;
x ^= x << 13;
x ^= x >> 17;
x ^= x << 5;
rng_state = x;
return x;
}
					                           
static inline void flush_write(void)
{
    asm volatile ("fence ow, ow" ::: "memory");
}

static inline void flush_read(void)
{
    asm volatile ("fence ir, ir" ::: "memory");
}
static inline void Shakti_Out32(uint32_t addr, uint32_t value)
{
    *(volatile uint32_t *)addr = value;
//flush_write();
}

static inline uint32_t Shakti_In32(uint32_t addr)
{ //   flush_read();
    return *(volatile uint32_t *)addr;
}

static void AES_write_data(uint32_t data1,uint32_t data2,uint32_t data3,uint32_t data4){
Shakti_Out32(AES_BASE+0x24,data1);
Shakti_Out32(AES_BASE+0x28,data2);
Shakti_Out32(AES_BASE+0x2c,data3);
Shakti_Out32(AES_BASE+0x30,data4);
printf ("Data written %x%x%x%x !!\n\r",data1,data2,data3,data4);
}

static void AES_read_out(void){

uint32_t out1 = Shakti_In32(AES_BASE+0x34);
uint32_t out2 = Shakti_In32(AES_BASE+0x38);
uint32_t out3 = Shakti_In32(AES_BASE+0x3c);
uint32_t out4 = Shakti_In32(AES_BASE+0x40);
printf ("Cipher: %x%x%x%x !!\n\r",out1,out2,out3,out4);
}
static void AES_write_rand_data(void){
uint32_t data1 = rand_u32();
uint32_t data2 = rand_u32();
uint32_t data3 = rand_u32();
uint32_t data4 = rand_u32();


AES_write_data( data1, data2, data3, data4);
}

/*static void AES_write_string(const char* input_string) {
    uint8_t buffer[16] = {0};

    int len = strlen(input_string);
    if (len > 16) len = 16;
    memcpy(buffer, input_string, len);

    uint32_t* words = (uint32_t*)buffer;
    AES_write_data(words[0], words[1], words[2], words[3]);
}*/

/*static void AES_write_string(const char* input_string) {
    uint32_t data1, data2, data3, data4;
    uint8_t buffer[16] = {0};

    int len = strlen(input_string);
    if (len > 16) len = 16;
    memcpy(buffer, input_string, len);

    // Little-endian packing (reverse byte order within each 32-bit word)
    //data1 = ((uint32_t)buffer[3]  << 24) | ((uint32_t)buffer[2]  << 16) |
      //      ((uint32_t)buffer[1]  << 8)  | ((uint32_t)buffer[0]);
    data1 = ((uint32_t)buffer[0]) | ((uint32_t)buffer[1]  << 8) |
            ((uint32_t)buffer[2]  << 16)  | ((uint32_t)buffer[3] << 24);
    data2 = ((uint32_t)buffer[7]  << 24) | ((uint32_t)buffer[6]  << 16) |
            ((uint32_t)buffer[5]  << 8)  | ((uint32_t)buffer[4]);
    data3 = ((uint32_t)buffer[11] << 24) | ((uint32_t)buffer[10] << 16) |
            ((uint32_t)buffer[9]  << 8)  | ((uint32_t)buffer[8]);
    data4 = ((uint32_t)buffer[15] << 24) | ((uint32_t)buffer[14] << 16) |
            ((uint32_t)buffer[13] << 8)  | ((uint32_t)buffer[12]);

    AES_write_data(data1, data2, data3, data4);
}*/
static void AES_write_string(const char* input_string) {
    uint32_t data1, data2, data3, data4;
    uint8_t buffer[16] = {0};

    int len = strlen(input_string);
    if (len > 16) len = 16;
    memcpy(buffer, input_string, len);

    // Big-endian packing (most significant byte first)
    data1 = ((uint32_t)buffer[0]  << 24) | ((uint32_t)buffer[1]  << 16) |
            ((uint32_t)buffer[2]  << 8)  | ((uint32_t)buffer[3]);
    data2 = ((uint32_t)buffer[4]  << 24) | ((uint32_t)buffer[5]  << 16) |
            ((uint32_t)buffer[6]  << 8)  | ((uint32_t)buffer[7]);
    data3 = ((uint32_t)buffer[8]  << 24) | ((uint32_t)buffer[9]  << 16) |
            ((uint32_t)buffer[10] << 8)  | ((uint32_t)buffer[11]);
    data4 = ((uint32_t)buffer[12] << 24) | ((uint32_t)buffer[13] << 16) |
            ((uint32_t)buffer[14] << 8)  | ((uint32_t)buffer[15]);

    AES_write_data(data1, data2, data3, data4);
}

static void conf_128(void){
Shakti_Out32(AES_BASE,4);
Shakti_Out32(AES_BASE,12);
printf ("Configured  !!\n\r");
}
static void conf_256(void){
Shakti_Out32(AES_BASE,6);
Shakti_Out32(AES_BASE,14);
printf ("Configured  !!\n\r");
}

static void AES_write_key1(uint32_t key1,uint32_t key2,uint32_t key3,uint32_t key4){
Shakti_Out32(AES_BASE+0x4,key1);
Shakti_Out32(AES_BASE+0x8,key2);
Shakti_Out32(AES_BASE+0xc,key3);
Shakti_Out32(AES_BASE+0x10,key4);
}
static void AES_write_key2(uint32_t key1,uint32_t key2,uint32_t key3,uint32_t key4){
Shakti_Out32(AES_BASE+0x14,key1);
Shakti_Out32(AES_BASE+0x18,key2);
Shakti_Out32(AES_BASE+0x1c,key3);
Shakti_Out32(AES_BASE+0x20,key4);
printf ("Key2 written %x%x%x%x !!\n\r",key1,key2,key3,key4);
}
static void write_key_256(uint32_t key1,uint32_t key2,uint32_t key3,uint32_t key4,uint32_t key5,uint32_t key6,uint32_t key7,uint32_t key8){
AES_write_key1(  key1,  key2,  key3,  key4);
AES_write_key2(  key5,  key6,  key7,  key8);
printf ("Key 256-bit written %x%x%x%x%x%x%x%x !!\n\r",key1,key2,key3,key4,key5,  key6,  key7,  key8);
}
static void write_key_128(uint32_t key1,uint32_t key2,uint32_t key3,uint32_t key4){
AES_write_key1(  key1,  key2,  key3,  key4);
printf ("Key 128-bit written %x%x%x%x !!\n\r",key1,key2,key3,key4);}
void main(void)
{
   printf ("Hello AES !\n\r");

uint32_t key1 = 0x99999999; 
uint32_t key2 = 0xaaaaaaaa;
uint32_t key3 = 0xbbbbbbbb;
uint32_t key4 = 0xcccccccc;   // Key for AES-128 is 0x99999999aaaaaaaabbbbbbbbcccccccc
uint32_t key5 = 0x11111111;
uint32_t key6 = 0x22222222;
uint32_t key7 = 0x33333333;  // Key for AES-256 is 99999999aaaaaaaabbbbbbbbccccccc11111111222222223333333344444444
uint32_t key8 = 0x44444444; 


printf("AES-128 \n\r ");
write_key_128(key1,key2,key3,key4);
AES_write_string("Hello World!1234");
conf_128();
AES_read_out();

printf("\n\rAES-256 \n\r");
write_key_256(key1,key2,key3,key4,key5,key6,key7,key8);
AES_write_string("Hello World!1234");
conf_256();
AES_read_out();

while(1);


}
