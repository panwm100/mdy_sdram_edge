/*********www.mdy-edu.com 明德扬科教 注释开始****************
明德扬专注FPGA培训和研究，并承接FPGA项目，本项目代码解释可在明德扬官方论坛学习（http://www.fpgabbs.cn/），明德扬掌握有PCIE，MIPI，视频拼接等技术，添加Q群97925396互相讨论学习
**********www.mdy-edu.com 明德扬科教 注释结束****************/

module add_5(
    clk    ,
    rst_n  ,
    din_vld,
    dout
    );

    parameter      DATA_W =         8;

    input               clk    ;
    input               rst_n  ;
    input               din_vld;

    output[DATA_W-1:0]  dout   ;

    reg   [DATA_W-1:0]  dout   ;


    reg   [DATA_W-1:0]  cnt   ;
    wire                add_cnt,end_cnt;


    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt <= 0;
        end
        else if(add_cnt)begin
            if(end_cnt)
                cnt <= 0;
            else
                cnt <= cnt + 2;
        end
    end

    assign add_cnt =din_vld ;       
    assign end_cnt = add_cnt && cnt==200-1 ; 

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout<=0;
        end
        else begin
            dout<=cnt;
        end
    end

    endmodule


