/*********www.mdy-edu.com 明德扬科教 注释开始****************
明德扬专注FPGA培训和研究，并承接FPGA项目，本项目代码解释可在明德扬官方论坛学习（http://www.fpgabbs.cn/），明德扬掌握有PCIE，MIPI，视频拼接等技术，添加Q群97925396互相讨论学习
**********www.mdy-edu.com 明德扬科教 注释结束****************/

module gray_bit(
        clk         ,
        rst_n       ,
        value       ,
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
    input   [7:0]       value   ;
    input   [7:0]       din     ;
    input               din_vld ;
    input               din_sop ;
    input               din_eop ;

    output              dout    ;
    output              dout_vld;
    output              dout_sop;
    output              dout_eop;

    reg                 dout    ;
    reg                 dout_vld;
    reg                 dout_sop;
    reg                 dout_eop;

    //鍍忕礌鐐逛簩鍊煎寲
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 1'b0;
        end
        else if(din >= value)begin
            dout <= 1'b1;
        end
        else begin
            dout <= 1'b0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_vld <= 1'b0;
        end
        else begin
            dout_vld <= din_vld;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_sop <= 1'b0;
        end
        else begin
            dout_sop <= din_sop;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_eop <= 1'b0;
        end
        else begin
            dout_eop <= din_eop;
        end
    end
    
    


endmodule
