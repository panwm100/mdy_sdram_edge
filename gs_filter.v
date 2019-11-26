/*********www.mdy-edu.com Ã÷µÂÑï¿Æ½Ì ×¢ÊÍ¿ªÊ¼****************
Ã÷µÂÑï×¨×¢FPGAÅàÑµºÍÑĞ¾¿£¬²¢³Ğ½ÓFPGAÏîÄ¿£¬±¾ÏîÄ¿´úÂë½âÊÍ¿ÉÔÚÃ÷µÂÑï¹Ù·½ÂÛÌ³Ñ§Ï°£¨http://www.fpgabbs.cn/£©£¬Ã÷µÂÑïÕÆÎÕÓĞPCIE£¬MIPI£¬ÊÓÆµÆ´½ÓµÈ¼¼Êõ£¬Ìí¼ÓQÈº97925396»¥ÏàÌÖÂÛÑ§Ï°
**********www.mdy-edu.com Ã÷µÂÑï¿Æ½Ì ×¢ÊÍ½áÊø****************/

module gs_filter(
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

    input               clk     ;
    input               rst_n   ;
    input   [7:0]       din     ;
    input               din_vld ;
    input               din_sop ;
    input               din_eop ;

    output  [7:0]       dout    ;
    output              dout_vld;
    output              dout_sop;
    output              dout_eop;

    reg     [7:0]       dout    ;
    reg                 dout_vld;
    reg                 dout_sop;
    reg                 dout_eop;

    reg     [7:0]       taps0_fifo_0    ;
    reg     [7:0]       taps0_fifo_1    ;
    reg     [7:0]       taps1_fifo_0    ;
    reg     [7:0]       taps1_fifo_1    ;
    reg     [7:0]       taps2_fifo_0    ;
    reg     [7:0]       taps2_fifo_1    ;

    reg                 din_vld_fifo_0  ;
    reg                 din_vld_fifo_1  ;
    reg                 din_vld_fifo_2  ;
    reg                 din_sop_fifo_0  ;
    reg                 din_sop_fifo_1  ;
    reg                 din_sop_fifo_2  ;
    reg                 din_eop_fifo_0  ;
    reg                 din_eop_fifo_1  ;
    reg                 din_eop_fifo_2  ;

    reg     [15:0]      gs_0            ;
    reg     [15:0]      gs_1            ;
    reg     [15:0]      gs_2            ;

    wire    [7:0]       taps0           ;
    wire    [7:0]       taps1           ;
    wire    [7:0]       taps2           ;



    //æ­¤æ¨¡å—ä¸»è¦ç†è§£ç§»ä½IPæ ¸çš„å·¥ä½œåŸç†å³å¯
    my_shift_ram u1(
	    .clken      (din_vld    ),
	    .clock      (clk        ),
	    .shiftin    (din        ),
//	    .shiftout   (shiftout   ),
	    .taps0x     (taps0      ),
	    .taps1x     (taps1      ),
	    .taps2x     (taps2      ) 
    );

    //IPæ ¸å‡ºæ¥çš„æ•°æ®æ˜¯3è¡Œå¹¶è¡Œçš„åƒç´ ç‚¹ï¼Œæ‰€ä»¥ç”¨2ä¸ªFIFOç¼“å­˜ä¸€ä¸‹ï¼Œå°±èƒ½å¾—åˆ°3*3çŸ©é˜µæ•°æ®
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            taps0_fifo_0 <= 8'd0;
            taps0_fifo_1 <= 8'd0;

            taps1_fifo_0 <= 8'd0;
            taps1_fifo_1 <= 8'd0;

            taps2_fifo_0 <= 8'd0;
            taps2_fifo_1 <= 8'd0;
        end
        else if(din_vld_fifo_0)begin//ç¬¬ä¸€ä¸ªæ—¶é’Ÿå‘¨æœŸæ˜¯æŠŠæ•°æ®å­˜å…¥IPæ ¸ï¼Œæ‰€ä»¥è¯»å‡ºæ˜¯ç¬¬äºŒä¸ªæ—¶é’Ÿå‘¨æœŸ
            taps0_fifo_0 <= taps0;
            taps0_fifo_1 <= taps0_fifo_0;

            taps1_fifo_0 <= taps1;
            taps1_fifo_1 <= taps1_fifo_0;

            taps2_fifo_0 <= taps2;
            taps2_fifo_1 <= taps2_fifo_0;            
        end
    end
    
    //din_vld
    //din_sop
    //din_sop
    //å»¶æ—¶4ä¸ªæ—¶é’Ÿå‘¨æœŸè¾“å‡º
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_vld_fifo_0 <= 1'b0;
            din_vld_fifo_1 <= 1'b0;
            din_vld_fifo_2 <= 1'b0;

            din_sop_fifo_0 <= 1'b0;
            din_sop_fifo_1 <= 1'b0;
            din_sop_fifo_2 <= 1'b0;     

            din_eop_fifo_0 <= 1'b0;
            din_eop_fifo_1 <= 1'b0;
            din_eop_fifo_2 <= 1'b0;      
        end
        else begin
            din_vld_fifo_0 <= din_vld;
            din_vld_fifo_1 <= din_vld_fifo_0;
            din_vld_fifo_2 <= din_vld_fifo_1;

            din_sop_fifo_0 <= din_sop;
            din_sop_fifo_1 <= din_sop_fifo_0;
            din_sop_fifo_2 <= din_sop_fifo_1;     

            din_eop_fifo_0 <= din_eop;
            din_eop_fifo_1 <= din_eop_fifo_0;
            din_eop_fifo_2 <= din_eop_fifo_1;      
        end
    end
    
    //æ»¤æ³¢é‡‡ç”¨2çº§æµæ°´çº¿çš„æ–¹å¼ï¼Œæé«˜è¿ç®—é¢‘ç‡
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gs_0 <= 16'd0;
        end
        else if(din_vld_fifo_1)begin//ç¬¬ä¸‰ä¸ªæ—¶é’Ÿå‘¨æœŸè¿ç®—ï¼Œç¬¬ä¸€çº§æµæ°´çº¿
            gs_0 <= taps0_fifo_1 + 2*taps1_fifo_1 + taps2_fifo_1;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gs_1 <= 16'd0;
        end
        else if(din_vld_fifo_1)begin//ç¬¬ä¸‰ä¸ªæ—¶é’Ÿå‘¨æœŸè¿ç®—ï¼Œç¬¬ä¸€çº§æµæ°´çº¿
            gs_1 <= 2*taps0_fifo_0 + 4*taps1_fifo_0 + 2*taps2_fifo_0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gs_2 <= 16'd0;
        end
        else if(din_vld_fifo_1)begin//ç¬¬ä¸‰ä¸ªæ—¶é’Ÿå‘¨æœŸè¿ç®—ï¼Œç¬¬ä¸€çº§æµæ°´çº¿
            gs_2 <= taps0 + 2*taps1 + taps2;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 8'd0;
        end
        else if(din_vld_fifo_2)begin//ç¬¬å››ä¸ªæ—¶é’Ÿå‘¨æœŸè¿ç®—ï¼Œç¬¬äºŒçº§æµæ°´çº¿
            dout <= (gs_0 + gs_1 + gs_2) >> 4;
        end
    end
    
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        dout_vld <= 1'b0;
    end
    else if(din_vld_fifo_2)begin
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
    else if(din_sop_fifo_2)begin
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
    else if(din_eop_fifo_2)begin
        dout_eop <= 1'b1;
    end
    else begin
        dout_eop <= 1'b0;
    end
end


    
    


endmodule
