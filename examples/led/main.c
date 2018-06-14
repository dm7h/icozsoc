#include <stdio.h>
#include <stdint.h>
#include "icosoc.h"


static int console_getc()
{
	while (1) {
		int c = *(volatile uint32_t*)0x30000000;
		if (c >= 0) return c;
	}
}

int main()
{

	for (uint8_t i = 0;; i++)
	{
		icosoc_leds(i);
		
		char ch = console_getc();
		printf("[%02x][%c] Hello World!\r\n", i, ch);

		for (int i = 0; i < 100000; i++)
			asm volatile ("");

	}
}

