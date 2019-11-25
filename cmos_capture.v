module cmos_capture(
        clk         ,
        rst_n       ,
        en_capture  ,
        vsync       ,
        href        ,
        din         ,
        dout        ,
        dout_vld    ,
        dout_sop    ,
        dout_eop     

    );

    parameter           COL = 640       ;
    parameter           ROW = 480       ;

    input               clk             ; 
    input               rst_n           ;
    input               en_capture      ;//采集使能信号
    input               vsync           ;//场同步信号
    input               href            ;//行同步信号
    input  [7:0]        din             ;//输入数据

    output [15:0]       dout            ;//把输入的8位数据组合成1个16位的数据输出
    output              dout_vld        ;
    output              dout_sop        ;
    output              dout_eop        ;

    reg    [15:0]       dout            ;//把输入的8位数据组合成1个16位的数据输出
    reg                 dout_vld        ;
    reg                 dout_sop        ;
    reg                 dout_eop        ;

    wire                add_cnt_x       ;
    wire                end_cnt_x       ;
    reg     [10:0]      cnt_x           ; 

    wire                add_cnt_y       ;
    wire                end_cnt_y       ;
    reg     [10:0]      cnt_y           ; 

    reg                 flag_add        ;
    reg                 vsync_ff        ;

    wire                vsync_l2h       ;

    reg [ 1:0]          cnt0            ;
    wire                add_cnt0        ;
    wire                end_cnt0        ;
    reg [ 9:0]          cnt1            ;
    wire                add_cnt1        ;
    wire                end_cnt1        ;
    reg [ 9:0]          cnt2            ;
    wire                add_cnt2        ;
    wire                end_cnt2        ;


    always @(posedge clk or negedge rst_n) begin 
        if (rst_n==0) begin
            cnt0 <= 0; 
        end
        else if(add_cnt0) begin
            if(end_cnt0)
                cnt0 <= 0; 
            else
                cnt0 <= cnt0+1 ;
       end
    end
    assign add_cnt0 = flag_add && href ;
    assign end_cnt0 = add_cnt0  && cnt0 == 2-1 ;
    
    
    always @(posedge clk or negedge rst_n) begin 
        if (rst_n==0) begin
            cnt1 <= 0; 
        end
        else if(add_cnt1) begin
            if(end_cnt1)
                cnt1 <= 0; 
            else
                cnt1 <= cnt1+1 ;
       end
    end
    assign add_cnt1 = end_cnt0;
    assign end_cnt1 = add_cnt1  && cnt1 == COL-1 ;
    
    
    always @(posedge clk or negedge rst_n) begin 
        if (rst_n==0) begin
            cnt2 <= 0; 
        end
        else if(add_cnt2) begin
            if(end_cnt2)
                cnt2 <= 0; 
            else
                cnt2 <= cnt2+1 ;
       end
    end
    assign add_cnt2 = end_cnt1;
    assign end_cnt2 = add_cnt2  && cnt2 == ROW-1 ;
    

    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_add <= 1'b0;
        end
        else if(flag_add == 0 && vsync_l2h && en_capture)begin
            flag_add <= 1'b1;
        end
        else if(end_cnt_y)begin
            flag_add <= 1'b0;
        end
    end
    assign vsync_l2h = vsync_ff   == 0 && vsync == 1; 
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            vsync_ff   <= 1'b0;
        end
        else begin
            vsync_ff   <= vsync;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 16'd0;
        end
        else if(add_cnt0)begin 
            dout[15-8*cnt0 -:8] <= din ;
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_vld <= 1'b0;
        end
        else if(end_cnt0)begin
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
        else if(add_cnt1 && cnt1==1-1 && cnt2==0)begin
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
        else if(end_cnt2)begin
            dout_eop <= 1'b1;
        end
        else begin
            dout_eop <= 1'b0;
        end
    end
    


endmodule


