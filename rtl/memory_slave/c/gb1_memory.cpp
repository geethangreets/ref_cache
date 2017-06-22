#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <queue>

#include <svdpi.h>
typedef unsigned char byte;
#include "veriuser.h"
#include "dpiheader.h"


#include <math.h>
#include <algorithm>
#include <cstdlib>

#include <sys/types.h>
#include <errno.h>

#include "memory_include.h"
static memory_array *memBlock;

void memory_init(){

	 memBlock = new memory_array;
}

byte memory_read(int location){
	return memBlock->byte_elem[location];
}

void memory_write(int location, byte data){
	memBlock->byte_elem[location] = data;
}

//int main()
//{
//	printf("Cpp Memory model\n");
//	printf("--------------------------------- \n");
//
//	unsigned char value;
//	for (int i =0; i< 150000; i++)
//	{
//		value = (unsigned char) i;
//		memory_write(i,value);
//	}
//
//
//	return 0;
//}
