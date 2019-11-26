/*********www.mdy-edu.com Ã÷µÂÑï¿Æ½Ì ×¢ÊÍ¿ªÊ¼****************
Ã÷µÂÑï×¨×¢FPGAÅàÑµºÍÑĞ¾¿£¬²¢³Ğ½ÓFPGAÏîÄ¿£¬±¾ÏîÄ¿´úÂë½âÊÍ¿ÉÔÚÃ÷µÂÑï¹Ù·½ÂÛÌ³Ñ§Ï°£¨http://www.fpgabbs.cn/£©£¬Ã÷µÂÑïÕÆÎÕÓĞPCIE£¬MIPI£¬ÊÓÆµÆ´½ÓµÈ¼¼Êõ£¬Ìí¼ÓQÈº97925396»¥ÏàÌÖÂÛÑ§Ï°
**********www.mdy-edu.com Ã÷µÂÑï¿Æ½Ì ×¢ÊÍ½áÊø****************/

module sobel(
    clk         ,
    rst_n       ,
    din         ,
    din_vld     ,
    din_sop     ,
    din_eop     ,
    dout        ,
    dout_vld    ,
    dout_sop    ,
    dout_eop         
);

    input               clk             ;
    input               rst_n           ;
    input               din             ;
    input               din_vld         ;
    input               din_sop         ;
    input               din_eop         ;

    output              dout            ;
    output              dout_vld        ;
    output              dout_sop        ;
    output              dout_eop        ;

    reg                 dout            ;
    reg                 dout_vld        ;
    reg                 dout_sop        ;
    reg                 dout_eop        ;


    reg                 din_vld_fifo_0  ;
    reg                 din_vld_fifo_1  ;
    reg                 din_vld_fifo_2  ;
    reg                 din_vld_fifo_3  ;
    reg                 din_sop_fifo_0  ;
    reg                 din_sop_fifo_1  ;
    reg                 din_sop_fifo_2  ;
    reg                 din_sop_fifo_3  ;
    reg                 din_eop_fifo_0  ;
    reg                 din_eop_fifo_1  ;
    reg                 din_eop_fifo_2  ;
    reg                 din_eop_fifo_3  ;

    reg     [7:0]       taps0_fifo_0    ;
    reg     [7:0]       taps0_fifo_1    ;
    reg     [7:0]       taps1_fifo_0    ;
    reg     [7:0]       taps1_fifo_1    ;
    reg     [7:0]       taps2_fifo_0    ;
    reg     [7:0]       taps2_fifo_1    ;

    wire                taps0           ;
    wire                taps1           ;
    wire                taps2           ;

    reg     [7:0]       gx              ;
    reg     [7:0]       gx_0            ;
    reg     [7:0]       gx_2            ;

    reg     [7:0]       gy              ;
    reg     [7:0]       gy_0            ;
    reg     [7:0]       gy_2            ;

    reg     [7:0]       g               ;

    //è¿™ä¸ªæ¨¡å—çš„æ€è·¯å’Œé«˜æ–¯æ»¤æ³¢æ˜¯ä¸€æ ·çš„ï¼Œä½†æ˜¯è¿™é‡Œçš„ç®—æ³•ä¸æ˜¯å¾ˆæ˜ç™½
    my_shift_ram_1bit u1(
	    .clken      (din_vld    ),
	    .clock      (clk        ),
	    .shiftin    (din        ),
//	    .shiftout   (shiftout   ),
	    .taps0x     (taps0      ),
	    .taps1x     (taps1      ),
	    .taps2x     (taps2      ) 
    );

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_vld_fifo_0 <= 1'b0;
            din_vld_fifo_1 <= 1'b0;
            din_vld_fifo_2 <= 1'b0;
            din_vld_fifo_3 <= 1'b0;

            din_sop_fifo_0 <= 1'b0;
            din_sop_fifo_1 <= 1'b0;
            din_sop_fifo_2 <= 1'b0;
            din_sop_fifo_3 <= 1'b0;

            din_eop_fifo_0 <= 1'b0;
            din_eop_fifo_1 <= 1'b0;
            din_eop_fifo_2 <= 1'b0;
            din_eop_fifo_3 <= 1'b0;
        end
        else begin
            din_vld_fifo_0 <= din_vld;
            din_vld_fifo_1 <= din_vld_fifo_0;
            din_vld_fifo_2 <= din_vld_fifo_1;
            din_vld_fifo_3 <= din_vld_fifo_2;

            din_sop_fifo_0 <= din_sop;
            din_sop_fifo_1 <= din_sop_fifo_0;
            din_sop_fifo_2 <= din_sop_fifo_1;
            din_sop_fifo_3 <= din_sop_fifo_2;

            din_eop_fifo_0 <= din_eop;
            din_eop_fifo_1 <= din_eop_fifo_0;
            din_eop_fifo_2 <= din_eop_fifo_1;
            din_eop_fifo_3 <= din_eop_fifo_2;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            taps0_fifo_0 <= 8'd0;
            taps0_fifo_1 <= 8'd0;

            taps1_fifo_0 <= 8'd0;
            taps1_fifo_1 <= 8'd0;

            taps2_fifo_0 <= 8'd0;
            taps2_fifo_1 <= 8'd0;           
        end
        else if(din_vld_fifo_0)begin
            taps0_fifo_0 <= taps0;
            taps0_fifo_1 <= taps0_fifo_0;

            taps1_fifo_0 <= taps1;
            taps1_fifo_1 <= taps1_fifo_0;

            taps2_fifo_0 <= taps2;
            taps2_fifo_1 <= taps2_fifo_0;
        end
    end
    
    //gx_0ä»£è¡¨è´Ÿæ•°
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gx_0 <= 8'd0;
        end
        else if(din_vld_fifo_1)begin
            gx_0 <= taps0_fifo_1 + taps1_fifo_1*2 + taps2_fifo_1;
        end
    end
    
    //gx_2ä»£è¡¨æ­£æ•°
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gx_2 <= 8'd0;
        end
        else if(din_vld_fifo_1)begin
            gx_2 <= taps0 + taps1*2 + taps2;
        end
    end
    
    //gx_0ä»£è¡¨è´Ÿæ•°
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gy_0 <= 8'd0;
        end
        else if(din_vld_fifo_1)begin
            gy_0 <= taps0 + taps0_fifo_0*2 + taps0_fifo_1;
        end
    end
    
    //gx_2ä»£è¡¨æ­£æ•°
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gy_2 <= 8'd0;
        end
        else if(din_vld_fifo_1)begin
            gy_2 <= taps2 + taps0_fifo_1*2 + taps2_fifo_1;
        end
    end
    
    //å¦‚æœè´Ÿæ•°>æ­£æ•° è´Ÿæ•°-æ­£æ•° å¦åˆ™ æ­£æ•°-è´Ÿæ•°
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gx <= 8'd0;
        end
        else if(din_vld_fifo_2)begin
            gx <= (gx_0 > gx_2) ? (gx_0 - gx_2) : (gx_2 - gx_0);
        end
    end
    
    //å¦‚æœè´Ÿæ•°>æ­£æ•° è´Ÿæ•°-æ­£æ•° å¦åˆ™ æ­£æ•°-è´Ÿæ•°
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gy <= 8'd0;
        end
        else if(din_vld_fifo_2)begin
            gy <= (gy_0 > gy_2) ? (gy_0 - gy_2) : (gy_2 - gy_0);
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            g <= 8'd0;
        end
        else if(din_vld_fifo_3)begin
            g <= gx +gy;
        end
    end
    
    always  @(*)begin
        dout = (g>=1) ? 1 : 0;
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_vld <= 1'b0;
        end
        else if(din_vld_fifo_3)begin
            dout_vld <= 1'b1;
        end
        else begin
            dout_vld <= 1'b0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_sop <= 1'b0;
        end
        else if(din_sop_fifo_3)begin
            dout_sop <= 1'b1;
        end
        else begin
            dout_sop <= 1'b0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_eop <= 1'b0;
        end
        else if(din_eop_fifo_3)begin
            dout_eop <= 1'b1;
        end
        else begin
            dout_eop <= 1'b0;
        end
    end
    
    
    
    

endmodule
