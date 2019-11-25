module sccb(
        clk       ,
        rst_n     ,
        ren       ,
        wen       ,
        sub_addr  ,
        rdata     ,
        rdata_vld ,
        wdata     ,
        rdy       ,
        sio_c     ,
        sio_d_r   ,
        en_sio_d_w,
        sio_d_w         
    );

    //使用flag_sel做状态寄存的时候最好用parameter 定义 RD WR ,这样不会0，1搞错，且更直观
    //测试程序里面sub_addr wdata 数值只存在一个时钟周期，所以需要缓存，但是实际应用中 应该？ 是不需要缓存的


    //参数定义
    parameter      SIO_C  = 120 ; 
    parameter       WEN_SEL = 1;
    parameter       REN_SEL = 0;

    //输入信号定义
    input               clk             ;//25m
    input               rst_n           ;
    input               ren             ;
    input               wen             ;
    input   [7:0]       sub_addr        ;
    input   [7:0]       wdata           ;

    //输出信号定义
    output  [7:0]       rdata           ;
    output              rdata_vld       ;
    output              sio_c           ;//208kHz
    output              rdy             ;

    input               sio_d_r         ;
    output              en_sio_d_w      ;
    output              sio_d_w         ;

    reg                 en_sio_d_w      ;
    reg                 sio_d_w         ;



    reg     [7:0]       rdata           ;
    reg                 rdata_vld       ;
    reg                 sio_c           ;//208kHz
    reg                 rdy             ;


    wire                add_count_sck   ;
    wire                end_count_sck   ;
    reg     [7:0]       count_sck       ; 

    wire                add_count_bit   ;
    wire                end_count_bit   ;
    reg     [7:0]       count_bit       ; 

    wire                add_count_duan  ;
    wire                end_count_duan  ;
    reg     [7:0]       count_duan      ; 

    reg                 flag_add        ;
    reg                 flag_sel        ;

    reg     [5:0]       bit_num         ;
    reg     [1:0]       duan_num        ;

    wire                sio_c_h2l       ;
    wire                sio_c_l2h       ;

    reg     [29:0]      out_data        ;

    wire    [7:0]       rd_com          ;

    wire                en_sio_d_w_h2l  ;
    wire                en_sio_d_w_l2h  ;

    wire                out_data_time   ;

    wire                rdata_time      ;


    reg     [7:0]       wdata_fifo      ;
    reg     [7:0]       sub_addr_fifo   ;  


    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            count_sck <= 0;
        end
        else if(add_count_sck)begin
            if(end_count_sck)
                count_sck <= 0;
            else
                count_sck <= count_sck + 1;
        end
    end
    assign add_count_sck = flag_add;
    assign end_count_sck = add_count_sck && count_sck == SIO_C - 1;
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            count_bit <= 0;
        end
        else if(add_count_bit)begin
            if(end_count_bit)
                count_bit <= 0;
            else
                count_bit <= count_bit + 1;
        end
    end
    assign add_count_bit = end_count_sck;
    assign end_count_bit = add_count_bit && count_bit == bit_num + 2 - 1;
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            count_duan <= 0;
        end
        else if(add_count_duan)begin
            if(end_count_duan)
                count_duan <= 0;
            else
                count_duan <= count_duan + 1;
        end
    end
    assign add_count_duan = end_count_bit;
    assign end_count_duan = add_count_duan && count_duan == duan_num - 1;
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_add <= 1'b0;
        end
        else if(ren || wen)begin
            flag_add <= 1'b1;
        end
        else if(end_count_duan)begin
            flag_add<= 1'b0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_sel <= 1'b0;
        end
        else if(wen)begin
            flag_sel <= WEN_SEL;
        end
        else if(ren)begin
            flag_sel <= REN_SEL;
        end
    end
    

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sub_addr_fifo <= 8'd0;
        end
        else if(ren || wen)begin
            sub_addr_fifo <= sub_addr;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wdata_fifo <= 8'd0;
        end
        else if(wen)begin
            wdata_fifo <= wdata;
        end
    end


    //注意：分隔符是没有时钟的，所以不合并入数据位
    always  @(*)begin
        if(flag_sel == WEN_SEL)begin
            bit_num = 30;//起始位 + 指令位 + X + 地址位 + X + 数据位 + X + 结束位  = 30
            duan_num = 1;
        end
        else if(flag_sel == REN_SEL)begin
            bit_num = 21;//起始位 + 指令位 + X + 地址位 + X + 结束位 = 23
            duan_num = 2;//分 读段 和 写段
        end
        else begin
            bit_num = 1;
            duan_num = 1;
        end
    end
    
    //sio_c = SIO_SCK
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sio_c <= 1'b1;
        end
        else if(sio_c_h2l)begin
            sio_c <= 1'b0;
        end
        else if(sio_c_l2h)begin
            sio_c <= 1'b1;
        end
    end
    //SCK是先低后高
    //count_bit < bit_num - 2   -2是减去2个停止位
    assign sio_c_h2l = count_bit >= 0 && count_bit < (bit_num - 2) && add_count_sck && count_sck == SIO_C - 1;
    assign sio_c_l2h = count_bit >= 1 && count_bit < bit_num && add_count_sck && count_sck == SIO_C / 2 - 1;

    always  @(*)begin
        if(flag_sel == REN_SEL)begin
            //读
            //1'b0 ,   rd_com , 1'b1 , sub_addr_fifo , 1'b1 , 1'b0 , 1'b1 ,9'h0
            //起始位   指令位      X    地址位       X          结束位   对其补零
            out_data = {1'b0 , rd_com , 1'b1 , sub_addr_fifo , 1'b1 , 1'b0 , 1'b1 ,9'h0};
        end
        else if(flag_sel == WEN_SEL)begin
            //写
            //1'b0 , 8'h42 , 1'b1 , sub_addr_fifo , 1'b1 , wdata_fifo , 1'b1 , 1'b0 , 1'b1
            out_data = {1'b0 , 8'h42 , 1'b1 , sub_addr_fifo , 1'b1 , wdata_fifo , 1'b1 , 1'b0 , 1'b1};
        end
        else begin
            out_data = 0;
        end
    end
    //先写再读
    //这里分成2段，第一段是写，所以发0x42 第二段是读，所以发0x43
    assign rd_com = (flag_sel == REN_SEL && count_duan == 0) ? 8'h42 : 8'h43;//写是0x42 读是0x43


    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            en_sio_d_w <= 1'b0;
        end
        else if(ren || wen)begin//读和写开始的第一段都是 输出
            en_sio_d_w <= 1'b1;
        end
        else if(end_count_duan)begin//在第一，和 第二段结束的时候都设为 输入
            en_sio_d_w <= 1'b0;
        end
        else if(en_sio_d_w_h2l)begin//在读的第二段的时候要切换为输入 读模块的数据
            en_sio_d_w <= 1'b0;
        end
        else if(en_sio_d_w_l2h)begin//在读的第二段 读模块的数据 完成后切换为输出 ，输出停止位和间隔符
            en_sio_d_w <= 1'b1;
        end
    end
    //第一个读段 和 写段 都是输出 ，只有在第二个读段中的读8位数据才是输入   在计数器0点变化 ?
    //注意这里使用add_count_sck而非add_count_bit判断
    assign en_sio_d_w_h2l = flag_sel == REN_SEL && count_duan == 2-1  && count_bit == 11 - 1 && add_count_sck && count_sck == 1-1;
    assign en_sio_d_w_l2h = flag_sel == REN_SEL && count_duan == 2-1  && count_bit == 20 - 1 && add_count_sck && count_sck == 1-1;


    //sio_d_w= SIO_SDA
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sio_d_w <= 1'b1;
        end
        else if(out_data_time)begin
            sio_d_w <= out_data[30 - count_bit - 1];//高位先发
        end
    end
    //bit_num < count_bit  判断是否 不是 间隔符 ，在SCK低电平中点输出数据
    assign out_data_time = (count_bit < bit_num) && add_count_sck && count_sck == SIO_C/4 - 1;
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rdata <= 8'd0;
        end
        else if(rdata_time)begin
            rdata[17 -count_bit] <= sio_d_r;  // rdata[7~0] = (18 - 1) - count_bit((11-1) ~ (18 - 1)) = 17 
        end
    end
    //是否在“读” 
    //是否在“读的第二段” 
    //是否在“读的范围内”
    //注意这里使用add_count_sck而非add_count_bit判断
    assign rdata_time = flag_sel == REN_SEL && count_duan == 2-1 && (count_bit >= 11-1 && count_bit < 18) && add_count_sck &&count_sck == SIO_C/4*3 - 1;  
    

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rdata_vld <= 1'b0;
        end
        else if(flag_sel == REN_SEL && end_count_duan)begin//在读的时候，读段（读段 = 2）结束，
            rdata_vld <= 1'b1;
        end
        else begin
            rdata_vld <= 1'b0;
        end
    end
    
    //RDY是 空闲的时候=1 忙的时候 = 0
    always  @(*)begin
        if( ren || wen || flag_add)begin
            rdy = 1'b0;
        end
        else begin
            rdy = 1'b1;
        end
    end
    
    




endmodule