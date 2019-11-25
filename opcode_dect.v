module opcode_dect(
    clk         ,
    rst_n       ,
    din         ,
    din_vld     ,

    dout_vld    ,
    dout
    );

    //参数定义
    parameter      DOUT_W =         8;
    parameter      DIN_W  =         4;

    //输入信号定义
    input               clk     ;
    input               rst_n   ;
    input[DIN_W-1:0]    din     ;
    input               din_vld ;

    wire [DIN_W-1:0]    din     ;
    wire                din_vld ;
    //输出信号定义
    output[DOUT_W-1:0]  dout    ;
    output              dout_vld;

    //输出信号reg定义
    reg   [DOUT_W-1:0]  dout    ;
    reg                 dout_vld;

    //中间信号定义
    reg      [2-1:0]           cnt0;
    wire                   add_cnt0;
    wire                   end_cnt0;

    reg      [2-1:0]           cnt1;
    wire                   add_cnt1;
    wire                   end_cnt1;

    reg      [11:0]         din_tmp;
    wire     [15:0]         din_top;
    reg                       flag ;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt0 <= 0;
        end
        else if(add_cnt0)begin
            if(end_cnt0)
                cnt0 <= 0;
            else
                cnt0 <= cnt0 + 1;
        end
    end

    assign add_cnt0 = flag&&din_vld;
    assign end_cnt0 = add_cnt0 && cnt0== 2-1;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt1 <= 0;
        end
        else if(add_cnt1)begin
            if(end_cnt1)
                cnt1 <= 0;
            else
                cnt1 <= cnt1 + 1;
        end
    end

    assign add_cnt1 = end_cnt0;
    assign end_cnt1 = add_cnt1 && cnt1== 2-1;
    
    assign din_top = {din_tmp[11:0],din}==16'h55d5;    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag <= 0;
        end
        else if(din_vld&&flag==0&&din_top)begin
            flag <= 1;
        end
        else if(end_cnt1)begin
            flag <= 0;
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_tmp <= 0;
        end
        else if(din_vld&&flag==0)begin
            din_tmp <= {din_tmp[7:0],din};
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 0;
        end
        else if(din_vld)begin
            dout <= {dout[3:0],din};
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
endmodule

