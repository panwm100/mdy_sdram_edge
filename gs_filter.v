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



    //此模块主要理解移位IP核的工作原理即可
    my_shift_ram u1(
	    .clken      (din_vld    ),
	    .clock      (clk        ),
	    .shiftin    (din        ),
//	    .shiftout   (shiftout   ),
	    .taps0x     (taps0      ),
	    .taps1x     (taps1      ),
	    .taps2x     (taps2      ) 
    );

    //IP核出来的数据是3行并行的像素点，所以用2个FIFO缓存一下，就能得到3*3矩阵数据
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            taps0_fifo_0 <= 8'd0;
            taps0_fifo_1 <= 8'd0;

            taps1_fifo_0 <= 8'd0;
            taps1_fifo_1 <= 8'd0;

            taps2_fifo_0 <= 8'd0;
            taps2_fifo_1 <= 8'd0;
        end
        else if(din_vld_fifo_0)begin//第一个时钟周期是把数据存入IP核，所以读出是第二个时钟周期
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
    //延时4个时钟周期输出
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
    
    //滤波采用2级流水线的方式，提高运算频率
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gs_0 <= 16'd0;
        end
        else if(din_vld_fifo_1)begin//第三个时钟周期运算，第一级流水线
            gs_0 <= taps0_fifo_1 + 2*taps1_fifo_1 + taps2_fifo_1;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gs_1 <= 16'd0;
        end
        else if(din_vld_fifo_1)begin//第三个时钟周期运算，第一级流水线
            gs_1 <= 2*taps0_fifo_0 + 4*taps1_fifo_0 + 2*taps2_fifo_0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            gs_2 <= 16'd0;
        end
        else if(din_vld_fifo_1)begin//第三个时钟周期运算，第一级流水线
            gs_2 <= taps0 + 2*taps1 + taps2;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 8'd0;
        end
        else if(din_vld_fifo_2)begin//第四个时钟周期运算，第二级流水线
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
