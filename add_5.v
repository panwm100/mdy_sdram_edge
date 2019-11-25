module add_5(
    clk    ,
    rst_n  ,
    din_vld,
   // dout_vld,
    //�����ź�,����dout
    dout
    );

    //��������
    parameter      DATA_W =         8;

    //�����źŶ���
    input               clk    ;
    input               rst_n  ;
    input               din_vld;

    //����źŶ���
  //  output              dout_vld;
    output[DATA_W-1:0]  dout   ;

    //����ź�reg����
    reg   [DATA_W-1:0]  dout   ;

 //   reg                 dout_vld;

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


