

    parameter                           LUMA_DIM_WDTH		    	= 4;        // out block dimension  max 11
    parameter                           CHMA_DIM_WDTH               = 3;        // max 5 (2+3) / (4+3)
    parameter                           CHMA_DIM_HIGT               = 3;        // max 5 (2+3) / (4+3)
    
    parameter                           LUMA_REF_BLOCK_WIDTH        = 4'd11;
    parameter                           CHMA_REF_BLOCK_WIDTH        = (C_SUB_WIDTH  == 1) ? 3'd7: 3'd5;
    parameter                           CHMA_REF_BLOCK_HIGHT        = (C_SUB_HEIGHT == 1) ? 3'd7: 3'd5;
    

    parameter 						    BLOCK_NUMBER_WIDTH 			 = 6; // Since 32 elements can be occupied in hit fifo, if all of them come from single cache line block 6 bits needed to uniquely identify a block

