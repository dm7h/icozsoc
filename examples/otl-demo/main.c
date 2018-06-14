#include <stdio.h>
#include <stdint.h>
#include "icosoc.h"

int main()
{
	char buffer[100];
	int buffer_len;

	for (uint8_t i = 0;; i++)
	{
		icosoc_ssd0_set(i);
		printf("[%02x] Hello World!\n", i);

		buffer_len = snprintf(buffer, 100, "[%02x] Hello World!\r\n", i);
		icosoc_ser0_write(buffer, buffer_len);

		for (int i = 0; i < 100000; i++)
			asm volatile ("");
	}
}

