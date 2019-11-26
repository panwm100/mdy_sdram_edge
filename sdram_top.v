/*********www.mdy-edu.com ������ƽ� ע�Ϳ�ʼ****************
������רעFPGA��ѵ���о������н�FPGA��Ŀ������Ŀ������Ϳ���������ٷ���̳ѧϰ��http://www.fpgabbs.cn/����������������PCIE��MIPI����Ƶƴ�ӵȼ���������QȺ97925396��������ѧϰ
**********www.mdy-edu.com ������ƽ� ע�ͽ���****************/

module sdram_top(
        clk         ,
        clk_100M    ,
        rst_n       ,

        din_1       ,//彩色图像
        din_vld_1   ,
        din_sop_1   ,
        din_eop_1   ,

        din_2       ,//二值图像
        din_vld_2   ,
        din_sop_2   ,
        din_eop_2   ,

        dout_1      ,//彩色图像
        dout_vld_1  ,
        dout_sop_1  ,
        dout_eop_1  ,
        dout_usedw_1,
        b_rdy_1     ,

        dout_2      ,//二值图像
        dout_vld_2  ,
        dout_sop_2  ,
        dout_eop_2  ,
        dout_usedw_2,
        b_rdy_2     ,
        key_vld     ,

        //硬件接口
        sd_clk      ,
        cke         ,
        cs          ,
        ras         ,
        cas         ,
        we          ,
        dqm         ,
        sd_addr     ,
        sd_bank     ,

        dq_in       ,
        dq_out      ,
        dq_out_en   ,

        //测试接口，用后删除
        flag_sel    ,    
        end_cnt0    ,
        end_cnt1    ,
        add_cnt0    ,
        add_cnt1    ,

        
        wr_color_en ,
        wr_sobel_en ,
        rd_color_en ,
        rd_sobel_en ,

        rd_sobel_end,
        rd_color_end,
        wr_sobel_end,
        wr_color_end
    );
    //使用方法：
    //din_1（sop,eop,vld） 输入 16位的彩色数据流 ，图像固定为640*480！！！
    //din_2（sop,eop,vld） 输入 16位二值图像数据流 ，图像固定为640*480！！！

    //dout_1（sop,eop,vld） 输出 16位的彩色数据流 ，图像固定为640*480！！！
    //dout_2（sop,eop,vld） 输出 16位二值图像数据流 ，图像固定为640*480！！！
    //sop 指示第一幅图像的第一个数据
    //eop 指示第一副图像的最后一个数据
    //vld 指示有效数据

    //上电后，需要判断dout_usedw_1和dout_usedw_2大于200个之后，才能拉高b_rdy_1 ，b_rdy_2，请求输出数据
    // b_rdy_1 和 b_rdy_2 需要同时拉高 ，以确保同时结束！！！！


    //工作流程
    //1、输入的16位数据流进入“总线位宽转换模块”把16位数据转换成48位数据，
    //   并且进行“头判断”即收到sop才开始缓存数据直到eop,之后不再写入数据，直到接收“切换RAM”（flag_sw_ff3） 信号才能再次写入

    //2、判断“写入FIFO”里面的数量，如果>256（SDRAM一页的数据量）就读出数据并且写入SDRAM

    //3、4路FIFO的优先级是 wr_color > wr_sobel > rd_color > rd_sobel
    //   当写入或者读出完一页（256个数据）后再进行优先级判断
    //

    //4、当“读出FIFO”内的数据量  < 256（SDRAM一页的数据量） 就读出SDRAM的数据写入FIFO

    //5、输入的图像是30HZ，而输出的图像是60HZ
    //   当输入完成一副图像之后，就不再写入图像，等到读出完成一幅图像之后，进行切换RAM地址，才能再次写入，并且把刚才写入的图像输出

    //6、写入完成标志位，只能在切换RAM的使用清零，但是读出完成标志位，在下一次开始的时候清零（color_new_start） 或者 在切换RAM的时候清零（ping_pong_end）
    //   切换RAM的条件是 4个数据流都传输完成 ping_pong_end 


    //测试接口，用后删除
    output wr_color_en;
    output wr_sobel_en;
    output rd_color_en;
    output rd_sobel_en;

    output rd_sobel_end;
    output rd_color_end; 
    output wr_sobel_end;
    output wr_color_end;



    //定义4片内存块的地址 用来存放 “读”彩色和二值   和   “写”彩色和二值
    //进行乒乓操作
    //[13:12] = bank 地址
    //[11: 0] = 起始地址
    parameter BANK_1 = 14'b00_000000000000;//内存块 1
    parameter BANK_2 = 14'b01_000000000000;//内存块 2
    parameter BANK_3 = 14'b10_000000000000;//内存块 3
    parameter BANK_4 = 14'b11_000000000000;//内存块 4

    //每个画面有多少行
    //640*480*16bit / 256 / 48 
    parameter PIC_ROW = 400;//每幅画面 占SDRAM 400行（页）
    parameter SD_PAGE = 256;//SDRAM 一页是256个


    output      [ 1:0]          flag_sel    ;
    output                      end_cnt0    ;
    output                      end_cnt1    ;
    output                      add_cnt0    ;
    output                      add_cnt1    ;


    input                       clk         ;
    input                       clk_100M    ;
    input                       rst_n       ;
    input       [3:0]           key_vld     ;

    //硬件接口
    input       [47:0]          dq_in       ;

    output                      sd_clk      ;//SDRAM时钟  取反输入时钟得到
    output                      cke         ;
    output                      cs          ;
    output                      ras         ;
    output                      cas         ;
    output                      we          ;
    output      [ 5:0]          dqm         ;
    output      [11:0]          sd_addr     ;
    output      [ 1:0]          sd_bank     ;
    output      [47:0]          dq_out      ;//全部SDRAM都用上
    output                      dq_out_en   ;

    wire                        sd_clk      ;//SDRAM时钟  取反输入时钟得到
    wire                        cke         ;
    wire                        cs          ;
    wire                        ras         ;
    wire                        cas         ;
    wire                        we          ;
    wire        [ 5:0]          dqm         ;
    wire        [11:0]          sd_addr     ;
    wire        [ 1:0]          sd_bank     ;
    wire        [47:0]          dq_out      ;//全部SDRAM都用上
    wire                        dq_out_en   ;


    //数据输入接口
    input       [15:0]      din_1           ;//彩色图像
    input                   din_vld_1       ;
    input                   din_sop_1       ;
    input                   din_eop_1       ;

    input       [15:0]      din_2           ;//二值图像
    input                   din_vld_2       ;
    input                   din_sop_2       ;
    input                   din_eop_2       ;

    input                   b_rdy_1         ;
    input                   b_rdy_2         ;

    //数据输出接口
    output      [15:0]      dout_1          ;//彩色图像
    output                  dout_vld_1      ;
    output                  dout_sop_1      ;
    output                  dout_eop_1      ;
    output      [ 8:0]      dout_usedw_1    ;

    output      [15:0]      dout_2          ;//二值图像
    output                  dout_vld_2      ;
    output                  dout_sop_2      ;
    output                  dout_eop_2      ;
    output      [ 8:0]      dout_usedw_2    ;

    wire        [15:0]      dout_1          ;//彩色图像
    wire                    dout_vld_1      ;
    wire                    dout_sop_1      ;
    wire                    dout_eop_1      ;
    wire        [ 8:0]      dout_usedw_1    ;

    wire        [15:0]      dout_2          ;//二值图像
    wire                    dout_vld_2      ;
    wire                    dout_sop_2      ;
    wire                    dout_eop_2      ;
    wire        [ 8:0]      dout_usedw_2    ;

    //中间信号
    wire        [47:0]      color_in        ;
    wire                    color_in_sop    ;
    wire                    color_in_eop    ;
    wire                    color_in_vld    ;

    wire        [47:0]      sobel_in        ;
    wire                    sobel_in_sop    ;
    wire                    sobel_in_eop    ;
    wire                    sobel_in_vld    ;   

    wire        [ 8:0]      wr_usedw_color  ;
    wire        [ 8:0]      wr_usedw_sobel  ;
    wire        [ 8:0]      rd_usedw_color  ;
    wire        [ 8:0]      rd_usedw_sobel  ;

    
    reg                     wr_color_rdy_start;
    reg                     wr_sobel_rdy_start;
    wire                    wr_color_rdy    ;
    wire                    wr_sobel_rdy    ;
    wire                    rd_color_rdy    ;
    wire                    rd_sobel_rdy    ;

    reg         [ 1:0]      rw_bank         ;
    reg         [11:0]      rw_addr         ;
	 reg                     stop            ;

    wire        [47:0]      wdata           ; 
    wire                    wr_ack          ;
    reg                     wr_req          ;

    reg                     rd_req          ;
    wire                    rd_ack          ;
    wire        [47:0]      rdata           ;

    reg                     flag_sw_ff0     ;
    reg                     flag_sw_ff1     ;
    reg                     flag_sw_ff2     ;
    reg                     flag_sw_ff3     ;

    reg                     work_flag       ;
    reg         [ 1:0]      flag_sel        ;
    wire                    work_flag_start ;
    wire                    work_flag_stop  ;
    wire                    wr_color_en     ;
    wire                    wr_sobel_en     ;    
    wire                    rd_color_en     ;
    wire                    rd_sobel_en     ;

    wire                    ping_pong_end   ;
    reg                     rw_addr_sel     ;
    reg                     wr_color_end    ;
    reg                     wr_sobel_end    ;
    reg                     rd_color_end    ;
    reg                     rd_sobel_end    ;
    wire                    sobel_new_start ;
    wire                    color_new_start ;

    reg                     wr_flag         ;

    wire                    add_cnt0        ;
    wire                    end_cnt0        ;
    reg         [ 8:0]      cnt0            ;

    wire                    add_cnt1        ;
    wire                    end_cnt1        ;
    reg         [ 9:0]      cnt1            ;

    wire                    add_cnt2        ;
    wire                    end_cnt2        ;
    reg         [ 9:0]      cnt2            ;

    wire                    add_cnt3        ;
    wire                    end_cnt3        ;
    reg         [ 9:0]      cnt3            ;

    wire                    add_cnt4        ;
    wire                    end_cnt4        ;
    reg         [ 9:0]      cnt4            ;

    wire                    add_cnt5        ;
    wire                    end_cnt5        ;
    reg         [ 2:0]      cnt5            ;

    reg                     color_out_vld   ;
    reg                     color_out_sop   ;
    reg                     color_out_eop   ;

    reg                     sobel_out_vld   ;
    reg                     sobel_out_sop   ;
    reg                     sobel_out_eop   ;

    reg         [47:0]      color_out       ;
    reg         [47:0]      sobel_out       ;

    wire                    rd_vld          ;



    //彩色图像 
    bus_conv_16_to_48 color_in_fifo(
        .clk                (clk            ),
        .clk_out            (clk_100M       ),
        .rst_n              (rst_n          ),

        .din                (din_1          ),
        .din_sop            (din_sop_1      ),
        .din_eop            (din_eop_1      ),
        .din_vld            (din_vld_1      ),

        .dout               (color_in       ),
        .dout_sop           (color_in_sop   ),
        .dout_eop           (color_in_eop   ),
        .dout_vld           (color_in_vld   ),
        .dout_mty           (),

        .b_rdy              (wr_color_rdy   ),
        .rd_usedw           (wr_usedw_color ),
        .flag_sw            (flag_sw_ff3    )//25M  时钟域
    );


    bus_conv_16_to_48 sobel_in_fifo(
        .clk                (clk            ),
        .clk_out            (clk_100M       ),
        .rst_n              (rst_n          ),

        .din                (din_2          ),
        .din_sop            (din_sop_2      ),
        .din_eop            (din_eop_2      ),
        .din_vld            (din_vld_2      ),

        .dout               (sobel_in       ),
        .dout_sop           (sobel_in_sop   ),
        .dout_eop           (sobel_in_eop   ),
        .dout_vld           (sobel_in_vld   ),
        .dout_mty           (),

        .b_rdy              (wr_sobel_rdy   ),
        .rd_usedw           (wr_usedw_sobel ),
        .flag_sw            (flag_sw_ff3    )//25M  时钟域
    );

    bus_conv_48to_16 color_out_fifo(
        .clk                (clk_100M       ),
        .clk_out            (clk            ),
        .rst_n              (rst_n          ),

        .din                (color_out      ),
        .din_sop            (color_out_sop  ),
        .din_eop            (color_out_eop  ),
        .din_vld            (color_out_vld  ),
        .din_mty            (3'h0           ),
        .wr_usedw           (rd_usedw_color ),

        .dout               (dout_1         ),
        .dout_sop           (dout_sop_1     ),
        .dout_eop           (dout_eop_1     ),
        .dout_vld           (dout_vld_1     ),
        .dout_mty           (),
        .rd_usedw           (dout_usedw_1   ),
        .b_rdy              (b_rdy_1        )
    );

    bus_conv_48to_16 sobel_out_fifo(
        .clk                (clk_100M       ),
        .clk_out            (clk            ),
        .rst_n              (rst_n          ),

        .din                (sobel_out      ),
        .din_sop            (sobel_out_sop  ),
        .din_eop            (sobel_out_eop  ),
        .din_vld            (sobel_out_vld  ),
        .din_mty            (3'h0           ),

        .dout               (dout_2         ),
        .dout_sop           (dout_sop_2     ),
        .dout_eop           (dout_eop_2     ),
        .dout_vld           (dout_vld_2     ),
        .dout_mty           (),
        .rd_usedw           (dout_usedw_2   ),
        .b_rdy              (b_rdy_2        ),


        .wr_usedw           (rd_usedw_sobel )
    );


    sdram sdram_1(
        .clk                (clk_100M       ),
        .rst_n              (rst_n          ),

        .rw_addr            (rw_addr        ),//读写地址
        .rw_bank            (rw_bank        ),//读写的bank

        .wdata              (wdata          ),//写数据
        .wr_ack             (wr_ack         ),//写请求的应答
        .wr_req             (wr_req         ),//写请求

        .rd_vld             (rd_vld         ),//读有效
        .rdata              (rdata          ),//读数据
        .rd_ack             (rd_ack         ),//读请求得到应答
        .rd_req             (rd_req         ),//读请求
    
        .sd_clk             (sd_clk         ),
        .cke                (cke            ),
        .cs                 (cs             ),
        .ras                (ras            ),
        .cas                (cas            ),
        .we                 (we             ),
        .dqm                (dqm            ),
        .sd_addr            (sd_addr        ),
        .sd_bank            (sd_bank        ),
       // .key_vld            (key_vld        ),
        
        .dq_in              (dq_in          ),
        .dq_out             (dq_out         ),
        .dq_out_en          (dq_out_en      )
    );



    //flag_sw   跨时钟域处理 100M到25MHZ
    //方法：把 ping_pong_end 延长到8个时钟周期 然后那25M的去采样，并且打3拍防止亚稳态
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            cnt5 <= 0;
        end
        else if(add_cnt5)begin
            if(end_cnt5)
                cnt5 <= 0;
            else
                cnt5 <= cnt5 + 1;
        end
    end
    assign add_cnt5 = flag_sw_ff0;
    assign end_cnt5 = add_cnt5 && cnt5 == 8-1;
    
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_sw_ff0 <= 0;
        end
        else if(ping_pong_end)begin
            flag_sw_ff0 <= 1;
        end
        else if(end_cnt5)begin
            flag_sw_ff0 <= 0;
        end
    end
    
    //flag_sw_ff3 使用
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_sw_ff1 <= 0;
            flag_sw_ff2 <= 0;
            flag_sw_ff3 <= 0;
        end
        else begin
            flag_sw_ff1 <= flag_sw_ff0;
            flag_sw_ff2 <= flag_sw_ff1;
            flag_sw_ff3 <= flag_sw_ff2;
        end
    end
    
    

 


    //根据FIFO内剩余数据的数量来决定哪个FIFO写入或读出
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            work_flag <= 0;
        end
        else if(work_flag_start)begin
            work_flag <= 1;
        end
        else if(work_flag_stop)begin
            work_flag <= 0;
        end
    end

    assign work_flag_start = work_flag == 0 && (wr_color_en || wr_sobel_en || rd_color_en || rd_sobel_en);
    assign work_flag_stop =  work_flag == 1 && end_cnt0;

    //flag_sel 选择读或者写 4个内存块中的一个
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_sel <= 0;
        end
        else if(work_flag_start)begin
            //选择内存块的标志位
            if(wr_color_en)
                flag_sel <= 0;
            else if(wr_sobel_en)
                flag_sel <= 1;
            else if(rd_color_en)
                flag_sel <= 2;
            else if(rd_sobel_en)
                flag_sel <= 3;
        end
    end
    //写FIFO 大于256个数据就开始写入SDRAM
    assign wr_color_en = wr_usedw_color >= SD_PAGE && wr_color_end == 0;
    assign wr_sobel_en = (wr_usedw_sobel >= SD_PAGE && wr_sobel_end == 0) && wr_color_en == 0;


    //assign wr_sobel_en = wr_usedw_color < SD_PAGE && wr_usedw_sobel >= SD_PAGE && wr_sobel_end == 0;

    //读FIFO 小于256个数据就开始读取SDRAM
    //判断rd_usedw_color rd_usedw_sobel 需要减2 因为usedw 有延时，2是调出来的
    //assign rd_color_en = rd_usedw_color < SD_PAGE-2 && wr_usedw_color < SD_PAGE && wr_usedw_sobel < SD_PAGE;
    assign rd_color_en = (rd_usedw_color < SD_PAGE-2 && wr_color_en == 0) && wr_sobel_en == 0;



    //注意：这里 判断 输出 color FIFO数量要使用rd_usedw_color >= SD_PAGE 使用 >= !!!!
    //assign rd_sobel_en = rd_usedw_sobel < SD_PAGE-2 && rd_usedw_color >= SD_PAGE && wr_usedw_color < SD_PAGE && wr_usedw_sobel < SD_PAGE;
    assign rd_sobel_en = (rd_usedw_sobel < SD_PAGE-2) && rd_color_en == 0;



    //根据flag_sel 设置 读写的bank 地址
    //根据flag_sel 设置 读写的addr 地址
    //rw_addr_sel 切换 RAM地址
    always  @(*)begin
        if (rw_addr_sel) begin  //A  乒乓操作
            if(flag_sel == 0)begin
                rw_bank = BANK_1[13:12];
                rw_addr = BANK_1[11:0] + cnt1;
            end
            else if(flag_sel == 1)begin
                rw_bank = BANK_2[13:12];
                rw_addr = BANK_2[11:0] + cnt2;
            end
            else if(flag_sel == 2)begin
                rw_bank = BANK_3[13:12];
                rw_addr = BANK_3[11:0] + cnt3;
            end
            else begin
                rw_bank = BANK_4[13:12];
                rw_addr = BANK_4[11:0] + cnt4; 
            end       
        end 
        else begin              //B
            if(flag_sel == 0)begin
                rw_bank = BANK_3[13:12];
                rw_addr = BANK_3[11:0] + cnt1;
            end
            else if(flag_sel == 1)begin
                rw_bank = BANK_4[13:12];
                rw_addr = BANK_4[11:0] + cnt2;
            end
            else if(flag_sel == 2)begin
                rw_bank = BANK_1[13:12];
                rw_addr = BANK_1[11:0] + cnt3;
            end
            else begin
                rw_bank = BANK_2[13:12];   
                rw_addr = BANK_2[11:0] + cnt4;   
            end
        end
    end
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            stop <= 1;
        end
        else if(key_vld[2])begin
            stop <= 0;
        end
        else if(key_vld[3])begin
            stop <= 1;
        end
    end
    
    //切换RAM
    //乒乓操作
    //乒乓操作的结束条件：写入SDRAM完成，读出SDRAM完成
    //assign ping_pong_end = rd_sobel_end && rd_color_end && wr_sobel_end && wr_color_end;
	
    assign ping_pong_end = rd_color_end && wr_sobel_end && wr_color_end && stop;//修正二值图像偏移 修正图像偏移，可能有问题 ！！！！
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rw_addr_sel <= 0;
        end
        else if(ping_pong_end)begin
            rw_addr_sel <= ~rw_addr_sel;
        end
    end

/********************************************************************/
    //传输完成标志位
    //写入：
    //写入完成一帧图像之 等到 切换RAM之后才会继续写入数据
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_color_end <= 0;
        end
        else if(end_cnt1)begin
            wr_color_end <= 1;
        end
        else if(ping_pong_end)begin
            wr_color_end <= 0;
        end
    end
    
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_sobel_end <= 0;
        end
        else if(end_cnt2)begin
            wr_sobel_end <= 1;
        end
        else if(ping_pong_end)begin
            wr_sobel_end <= 0;
        end
    end


    //读出完成之后标志位 置一 如果 “全部” 写入完成 和 读出完成 则切换RAM ，否则在 下一次开始发送的时候清零 
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rd_color_end <= 0;
        end
        else if(end_cnt3)begin
            rd_color_end <= 1;
        end
        else if(ping_pong_end || color_new_start)begin
            rd_color_end <= 0;
        end
    end
    assign color_new_start = rd_color_end && work_flag && flag_sel == 2;

    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rd_sobel_end <= 0;
        end
        else if(end_cnt4)begin
            rd_sobel_end <= 1;
        end
        else if(ping_pong_end || sobel_new_start)begin
            rd_sobel_end <= 0;
        end
    end
    assign sobel_new_start = rd_sobel_end && work_flag && flag_sel == 3;

/********************************************************************/   
    //                                                   SDRAM 写入部分
    //wr_color_rdy  wr_color_rdy  上升沿和 wr_ack 上升沿对齐

    //注意：使用wr_color_rdy_start 使能计数器 对齐时序！！！！！
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_color_rdy_start <= 0;
        end
        else if(wr_color_rdy)begin
            wr_color_rdy_start <= 1;
        end
        else begin
            wr_color_rdy_start <= 0;
        end
    end
    
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_sobel_rdy_start <= 0;
        end
        else if(wr_sobel_rdy)begin
            wr_sobel_rdy_start <= 1;
        end
        else begin
            wr_sobel_rdy_start <= 0;
        end
    end
    assign wr_color_rdy = (wr_flag || wr_ack) && flag_sel == 0 && work_flag && end_cnt0 == 0;//请求读出FIFO内的 彩色图像 请求 
    assign wr_sobel_rdy = (wr_flag || wr_ack) && flag_sel == 1 && work_flag && end_cnt0 == 0;//请求读出FIFO内的 二值图像 请求

    assign wdata = (flag_sel == 0) ? color_in : sobel_in;//写入SDRAM的数通源选择

    //产生写请求
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_req <= 0;
        end
        else if(work_flag_start && (wr_color_en || wr_sobel_en))begin
            wr_req <= 1;
        end
        else if(wr_ack) 
            wr_req <= 0;
    end

    //收到SDRAM的 wr_ack 之后开始写入数据
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_flag <= 0;
        end
        else if(wr_ack && wr_flag == 0)begin
            wr_flag <= 1;
        end
        else if(end_cnt0 && wr_flag == 1)begin
            wr_flag <= 0;
        end
    end

    //读写 个数 计数器
    always @(posedge clk_100M or negedge rst_n)begin
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
    assign add_cnt0 = wr_color_rdy_start || wr_sobel_rdy_start || rd_color_rdy || rd_sobel_rdy;
    assign end_cnt0 = add_cnt0 && cnt0 == SD_PAGE -1;
    
    // always  @(posedge clk or negedge rst_n)begin
    //     if(rst_n==1'b0)begin
    //         flag_add <= 0;
    //     end
    //     else if(wr_color_busy || wr_sobel_busy || rd_color_busy || rd_sobel_busy)begin
    //         flag_add <= 1;
    //     end
    //     else if(end_cnt0)begin
    //         flag_add <= 0;
    //     end
    // end
    

    //写入 彩色图像 地址“行”地址计数器
    always @(posedge clk_100M or negedge rst_n)begin
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
    assign add_cnt1 = end_cnt0 && flag_sel == 0 && work_flag;
    assign end_cnt1 = add_cnt1 && cnt1 == PIC_ROW - 1;
    

    //写入 二值图像 地址“行”地址计数器
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            cnt2 <= 0;
        end
        else if(add_cnt2)begin
            if(end_cnt2)
                cnt2 <= 0;
            else
                cnt2 <= cnt2 + 1;
        end
    end
    assign add_cnt2 = end_cnt0 && flag_sel == 1 && work_flag;
    assign end_cnt2 = add_cnt2 && cnt2 == PIC_ROW - 1;
    
    //读出 彩色图像 地址“行”地址计数器
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            cnt3 <= 0;
        end
        else if(add_cnt3)begin
            if(end_cnt3)
                cnt3 <= 0;
            else
                cnt3 <= cnt3 + 1;
        end
    end
    assign add_cnt3 = end_cnt0 && flag_sel == 2 && work_flag;
    assign end_cnt3 = add_cnt3 && cnt3 == PIC_ROW - 1;
    
    //读出 二值图像 地址“行”地址计数器
    always @(posedge clk_100M or negedge rst_n)begin
        if(!rst_n)begin
            cnt4 <= 0;
        end
        else if(add_cnt4)begin
            if(end_cnt4)
                cnt4 <= 0;
            else
                cnt4 <= cnt4 + 1;
        end
    end
    assign add_cnt4 = end_cnt0 && flag_sel == 3 && work_flag;
    assign end_cnt4 = add_cnt4 && cnt4 == PIC_ROW - 1;
    
    
/********************************************************************/   
    //                                                   SDRAM 读取部分    
    //输出数据选择
    //注意：这里要使用时序逻辑，和VLD SOP EOP 对齐
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            color_out <= 0;
        end
        else begin
            color_out <= rdata;
        end
    end
    
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sobel_out <= 0;
        end
        else begin
            sobel_out <= rdata;
        end
    end


    //产生读请求
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rd_req <= 0;
        end
        else if(work_flag_start && (rd_color_en || rd_sobel_en))begin
            rd_req <= 1;
        end
        else if(rd_ack)begin
            rd_req <= 0;
        end
    end
    
    assign rd_color_rdy = rd_vld && flag_sel == 2 && work_flag;
    assign rd_sobel_rdy = rd_vld && flag_sel == 3 && work_flag;

    //                                              彩色图像输出信号
    //color_out_vld 
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            color_out_vld <= 0;
        end
        else if(add_cnt0 && flag_sel == 2)begin
            color_out_vld <= 1;
        end
        else begin
            color_out_vld <= 0;
        end
    end

    //color_out_sop
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            color_out_sop <= 0;
        end
        else if(add_cnt0 && cnt0 == 1-1 && cnt3 == 1-1 && flag_sel == 2)begin
            color_out_sop <= 1;
        end
        else begin
            color_out_sop <= 0;
        end
    end
    
    //color_out_eop
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            color_out_eop <= 0;
        end
        else if(end_cnt3)begin
            color_out_eop <= 1;
        end
        else begin
            color_out_eop <= 0;
        end
    end
    
    

    //                                              二值图像输出信号
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sobel_out_vld <= 0;
        end
        else if(add_cnt0 && flag_sel == 3)begin
            sobel_out_vld <= 1;
        end
        else begin
            sobel_out_vld <= 0;
        end
    end

    //sobel_out_sop
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sobel_out_sop <= 0;
        end
        else if(add_cnt0 && cnt0 == 1-1 && cnt4 == 1-1 && flag_sel == 3)begin
            sobel_out_sop <= 1;
        end
        else begin
            sobel_out_sop <= 0;
        end
    end
    
    //sobel_out_eop
    always  @(posedge clk_100M or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sobel_out_eop <= 0;
        end
        else if(end_cnt4)begin
            sobel_out_eop <= 1;
        end
        else begin
            sobel_out_eop <= 0;
        end
    end
    
    

endmodule
