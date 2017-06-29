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

#define FILE_PATH "E:\\HEVC\\encoder\\ref_cache\\simvectors\\"


// Cache block order
// One block is 8x8
// LUMA CTU X0Y0 X0,Y0 X1,Y0 ... X_CTU-1,Y0
// LUMA CTU X0Y0 X0,Y1 ......... X_CTU-1,Y1 ...
// LUMA CTU X0Y0 X0,Y_CTU-1,.... X_CTU-1,Y_CTU-1 
// CB   CTU X0Y0 X0,Y0 X1,Y0 ... X_CTU-1,Y0 ...
// CB   CTU X0Y0 X0,Y_CTU-1,.... X_CTU-1,Y_CTU-1 
// CR   CTU X0Y0 X0,Y0 X1,Y0 ... X_CTU-1,Y0 ...
// CR   CTU X0Y0 X0,Y_CTU-1,.... X_CTU-1,Y_CTU-1 
// LUMA CTU X1Y0 X0,Y0 X1,Y0 ... X_CTU-1,Y0
// LUMA CTU X1Y0 X0,Y1 ......... X_CTU-1,Y1 ...
// LUMA CTU X1Y0 X0,Y_CTU-1,.... X_CTU-1,Y_CTU-1 
// CB   CTU X1Y0 X0,Y0 X1,Y0 ... X_CTU-1,Y0 ...
// CB   CTU X1Y0 X0,Y_CTU-1,.... X_CTU-1,Y_CTU-1 
// CR   CTU X1Y0 X0,Y0 X1,Y0 ... X_CTU-1,Y0 ...
// CR   CTU X1Y0 X0,Y_CTU-1,.... X_CTU-1,Y_CTU-1 ...
// LUMA CTU X_WID-1,Y_HIG-1 X0,Y0 X1,Y0 ... X_CTU-1,Y0
// LUMA CTU X_WID-1,Y_HIG-1 X0,Y1 ......... X_CTU-1,Y1 ...
// LUMA CTU X_WID-1,Y_HIG-1 X0,Y_CTU-1,.... X_CTU-1,Y_CTU-1 
// CB   CTU X_WID-1,Y_HIG-1 X0,Y0 X1,Y0 ... X_CTU-1,Y0 ...
// CB   CTU X_WID-1,Y_HIG-1 X0,Y_CTU-1,.... X_CTU-1,Y_CTU-1 
// CR   CTU X_WID-1,Y_HIG-1 X0,Y0 X1,Y0 ... X_CTU-1,Y0 ...
// CR   CTU X_WID-1,Y_HIG-1 X0,Y_CTU-1,.... X_CTU-1,Y_CTU-1 ...


// static memory_array* memBlock = (memory_array*)malloc(sizeof (memory_array));
FILE* DBP_frame;


static memory_array* memBlock ;
void memory_init(){
	if ((fopen_s(&DBP_frame, FILE_PATH "reconstructed_full.yuv", "rb")) != 0){
		printf("File was not opened\n");
		getchar();
	}
	 memBlock = new memory_array;
}

byte memory_read(int location){
	return memBlock->byte_elem[location];
}

void memory_write(int location, byte data){
	memBlock->byte_elem[location] = data;
}

int add_ref_DPB(int base_addr, int poc, int height, int width, int bit_depth, int SubWidthC, int SubHeightC){
	unsigned char pixel[2];
	int seek_num;
	int i, j, count = 0;
	pixel[0] = 0;
	pixel[1] = 0;
	int frame_offset = poc*height*width*(SubHeightC*SubWidthC + 2) / (SubHeightC*SubWidthC)*(bit_depth == 8 ? 1 : 2);

    int blk_x_stride    = REF_BLOCK_SIZE * (bit_depth == 8 ? 1 : 2);
    int blk_stride      = blk_x_stride * REF_BLOCK_SIZE;
    int ctu_x_stride    = blk_stride * CTU_SIZE/REF_BLOCK_SIZE;
    int ch_ctu_x_stride = blk_stride * CTU_SIZE/(REF_BLOCK_SIZE*SubWidthC);
    int lu_ctu_offset   = 0;
    int cb_ctu_offset   = ctu_x_stride * CTU_SIZE/REF_BLOCK_SIZE;
    int cr_ctu_offset   = cb_ctu_offset + cb_ctu_offset/(SubHeightC*SubWidthC);
    int ctu_stride      = cb_ctu_offset * (SubHeightC*SubWidthC + 2) / (SubHeightC*SubWidthC);
    int pic_x_stride    = ctu_stride * ((width/CTU_SIZE)+1);
    int ctu_x, ctu_y;
    int blk_x, blk_y;
    int inner_x, inner_y;
    int location;
    
    for (j = 0; j<height ; j++){
		ctu_y = j / CTU_SIZE;
		blk_y = j%CTU_SIZE;
		inner_y = blk_y%REF_BLOCK_SIZE;
		blk_y = blk_y / REF_BLOCK_SIZE;

		for (i = 0; i<width ; i++){
			seek_num = frame_offset + (count);
			count += (bit_depth == 8 ? 1 : 2);
			fseek(DBP_frame, seek_num, SEEK_SET);
			if (fread(&pixel, (bit_depth == 8 ? 1 : 2), 1, DBP_frame)){

			}
			else{
				printf("file position not available\n");
				return -1;
			}
			ctu_x = i / CTU_SIZE;
			blk_x = i%CTU_SIZE;
			inner_x = (blk_x%REF_BLOCK_SIZE) * (bit_depth == 8 ? 1 : 2);
			blk_x = blk_x / REF_BLOCK_SIZE;
            location = inner_x + inner_y * blk_x_stride + blk_x * blk_stride + blk_y * ctu_x_stride + lu_ctu_offset + ctu_x * ctu_stride + ctu_y * pic_x_stride;
            if (bit_depth == 8) {
                // if(memBlock->byte_elem[location] !=0){
                    // printf("problem");
                    // getchar();
                // }
                memBlock->byte_elem[location] = pixel[0];
            }
            else{
                memBlock->byte_elem[location+1] = pixel[1];
            }
		}
	}
    
	for (i = 0; i<height / SubHeightC; i++){
        ctu_x = i/(CTU_SIZE/SubWidthC);
        blk_x = i%(CTU_SIZE/SubWidthC);
        inner_x = (blk_x%REF_BLOCK_SIZE) * (bit_depth == 8 ? 1 : 2);
        blk_x = blk_x/REF_BLOCK_SIZE;        
		for (j = 0; j<width / SubWidthC; j++){
			seek_num = frame_offset + (count);
			count += (bit_depth == 8 ? 1 : 2);
			fseek(DBP_frame, seek_num, SEEK_SET);
			if (fread(&pixel, (bit_depth == 8 ? 1 : 2), 1, DBP_frame)){

			}
			else{
				printf("file position not available\n");
				return -1;
			}
            ctu_y = j/(CTU_SIZE/SubHeightC);
            blk_y = j%(CTU_SIZE/SubHeightC);
            inner_y = blk_y%REF_BLOCK_SIZE;
            blk_y = blk_y/REF_BLOCK_SIZE;
            location = inner_x + inner_y * blk_x_stride + blk_x * blk_stride + blk_y * ch_ctu_x_stride + cb_ctu_offset + ctu_x * ctu_stride + ctu_y * pic_x_stride;

            if (bit_depth == 8) {
                // if(memBlock->byte_elem[location] !=0){
                    // printf("problem");
                    // getchar();
                // }
                memBlock->byte_elem[location] = pixel[0];
            }
            else{
                memBlock->byte_elem[location+1] = pixel[1];
            }
		}
	}
	for (i = 0; i<height / SubHeightC; i++){
        ctu_x = i/(CTU_SIZE/SubWidthC);
        blk_x = i%(CTU_SIZE/SubWidthC);
        inner_x = (blk_x%REF_BLOCK_SIZE) * (bit_depth == 8 ? 1 : 2);
        blk_x = blk_x/REF_BLOCK_SIZE;        
		for (j = 0; j<width / SubWidthC; j++){
			seek_num = frame_offset + (count);
			count += (bit_depth == 8 ? 1 : 2);
			fseek(DBP_frame, seek_num, SEEK_SET);
			if (fread(&pixel, (bit_depth == 8 ? 1 : 2), 1, DBP_frame)){

			}
			else{
				printf("file position not available\n");
				return -1;
			}
            ctu_y = j/(CTU_SIZE/SubHeightC);
            blk_y = j%(CTU_SIZE/SubHeightC);
            inner_y = blk_y%REF_BLOCK_SIZE;
            blk_y = blk_y/REF_BLOCK_SIZE;
            location = inner_x + inner_y * blk_x_stride + blk_x * blk_stride + blk_y * ch_ctu_x_stride + cr_ctu_offset + ctu_x * ctu_stride + ctu_y * pic_x_stride;

            if (bit_depth == 8) {
                // if(memBlock->byte_elem[location] !=0){
                    // printf("problem");
                    // getchar();
                // }
                memBlock->byte_elem[location] = pixel[0];
            }
            else{
                memBlock->byte_elem[location+1] = pixel[1];
            }
		}
	}
	fclose(DBP_frame);
    return 0;
}

/* int main()
{
	printf("Cpp Memory model\n");
	printf("--------------------------------- \n");

	unsigned char value;
	// for (int i =0; i< 150000; i++)
	// {
		// value = (unsigned char) i;
		// memory_write(i,value);
	// }
	memory_init();
	for (int i =0; i< 1000000000; i++)
	{
		memory_write(i,0);
	}
    
    add_ref_DPB(0, 0, 1080, 1920, 8, 2, 2);


	return 0;
} 
*/