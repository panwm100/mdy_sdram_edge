/*********www.mdy-edu.com ������ƽ� ע�Ϳ�ʼ****************
������רעFPGA��ѵ���о������н�FPGA��Ŀ������Ŀ������Ϳ���������ٷ���̳ѧϰ��http://www.fpgabbs.cn/����������������PCIE��MIPI����Ƶƴ�ӵȼ��������QȺ97925396��������ѧϰ
**********www.mdy-edu.com ������ƽ� ע�ͽ���****************/

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


