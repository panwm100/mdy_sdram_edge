module bus_conv_16_to_48(
        clk     ,
        clk_out ,
        rst_n   ,

        din     ,
        din_sop ,
        din_eop ,
        din_vld ,

        dout    ,
        dout_sop,
        dout_eop,
        dout_vld,
        dout_mty,

        b_rdy   ,
        flag_sw ,
        rd_usedw
    );

    //使用方法：
    //注意: 每帧的数据是 640*480 个 16bit
    //把16位的数据输入进来
    //在次级数据>=256（任意值）时 b_rdy = 1 发送数据
    //在收到一个完整的包文后 只有flag_sw = 1 才能写入新的包文

    //功能：
    //1、实现16位转48位
    //2、写入FIFO的数据必须是一个包文，即SOP开头，EOP结尾，写完后，直到 flag_sw = 1 才能再次写入新的包文
    //3、实现跨时钟域
    //4、输出当前FIFO内的数据的个数 rd_usedw

    //640 * 480 = 307200 的像素点总数 16bit  307200
    //307200 / 3 = 102400 个48bit 
    //parameter PIC_NUM = 102400; //48bit
    parameter PIC_NUM = 102400; //48bit
    


    //输入
    input                   clk     ;
    input                   clk_out ;
    input                   rst_n   ;

    input       [15:0]      din     ;
    input                   din_vld ;
    input                   din_sop ;
    input                   din_eop ;
    
    input                   b_rdy   ;
    input                   flag_sw ;

    //输出
    output      [47:0]      dout    ;
    output                  dout_vld;
    output                  dout_eop;   
    output                  dout_sop;
    output      [ 2:0]      dout_mty;
    output      [ 8:0]      rd_usedw;

    //输出 reg
    reg         [47:0]      dout    ;
    reg                     dout_vld;
    reg                     dout_eop;   
    reg                     dout_sop;
    reg         [ 2:0]      dout_mty;
    wire        [ 8:0]      rd_usedw;



    //中间信号
    wire                    add_cnt0;
    wire                    end_cnt0;
    reg         [ 2:0]      cnt0    ;

    wire                    add_cnt1;
    wire                    end_cnt1;
    reg         [18:0]      cnt1    ;

    reg                    wait_sw ;
    reg                     flag_add;

    reg                     wr_en   ;
    reg         [47:0]      din_ff0 ;
    reg                     din_sop_ff0;
    reg                     din_eop_ff0;
    reg         [ 2:0]      din_mty_ff0;     
    wire        [52:0]      wdata   ;

    wire        [52:0]      q       ;
    wire                    rd_empty;
    wire                    rd_en   ;
    wire                    dout_eop_tmp;
    wire                    dout_sop_tmp;
    wire        [ 2:0]      dout_mty_tmp;



    /**************************************************************/
    //写侧

    //把3个16位的数据合并成1个48位数据
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt0 <= 0;
        end
        else if(wait_sw == 1)begin
            cnt0 <= 0;
        end
        else if(add_cnt0)begin
            if(end_cnt0)
                cnt0 <= 0;
            else
                cnt0 <= cnt0 + 1;
        end
    end
//    assign add_cnt0 = wait_sw == 0 && din_vld && (flag_add || din_sop);//要加上din_sop 不然会丢失第一个数据
    assign add_cnt0 = din_vld && (flag_add || flag_add_stat); 
    
    assign end_cnt0 = add_cnt0 && (cnt0 == 3-1 || din_eop);
//    assign end_cnt0 = add_cnt0 && cnt0 == 3-1;
    
    //写入完成后等待切换 才能再次写入
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wait_sw <= 0;
        end
        else if(end_cnt1 && wait_sw == 0)begin
            wait_sw <= 1;
        end
        else if(flag_sw && wait_sw == 1)begin
            wait_sw <= 0;
        end
    end

    //计数写入FIFO的数据数量
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
    assign end_cnt1 = add_cnt1 && cnt1 == PIC_NUM - 1;


    
    //只在 SOP 的时候才开始计数
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_add <= 0;
        end
        else if(flag_add_stat)begin
            flag_add <= 1;
        end
        else if((din_vld && din_eop) || end_cnt1)begin
            flag_add <= 0;
        end
    end

    assign flag_add_stat = din_vld && din_sop && wait_sw == 0;


    //产生写入FIFO所需的信号


    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_en <= 0;
        end
        else begin
            wr_en <= end_cnt0;
        end
    end


    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_ff0 <= 0;
        end
        else if(add_cnt0)begin
            din_ff0[47 - 16*cnt0 -: 16] <= din;
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_sop_ff0 <= 0;
        end
        else if(add_cnt0 && cnt0 == 1-1)begin
            din_sop_ff0 <= din_sop;
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_eop_ff0 <= 0;
        end
        else if(end_cnt0)begin
            din_eop_ff0 <= din_eop;
        end
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            din_mty_ff0 <= 0;
        end
        else if(end_cnt0)begin
            din_mty_ff0[2:1] <= 2 - cnt0;//左移一位，起到*2 的效果
        end
    end

    assign wdata = {din_sop_ff0 , din_eop_ff0 , din_mty_ff0 , din_ff0};



    /**************************************************************/
    //FIFO
    my_fifo#(.DATA_W(53), .DEPT_W(512)) uuu_t(
	    .aclr           (~rst_n     ),

        .wrclk          (clk        ),
	    .data           (wdata      ),
        .wrreq          (wr_en      ),
        .wrempty        (           ),
	    .wrfull         (           ),
	    .wrusedw        (           ),

	    .rdclk          (clk_out    ),
        .q              (q          ),
	    .rdreq          (rd_en      ),
	    .rdempty        (rd_empty   ),
	    .rdfull         (           ),
	    .rdusedw        (rd_usedw   )
    );
    /**************************************************************/
    //读侧

    assign rd_en = b_rdy && rd_empty == 0;


    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 0;
        end
        else begin
            dout <= q[47:0];
        end
    end

    assign dout_sop_tmp = q[52];
    assign dout_eop_tmp = q[51];
    assign dout_mty_tmp = q[50:48];

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_sop <= 0;
        end
        else if(rd_en)begin
            dout_sop <= dout_sop_tmp;
        end
        else begin
            dout_sop <= 0;
        end
    end

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_eop <= 0;
        end
        else if(rd_en)begin
            dout_eop <= dout_eop_tmp;
        end
        else begin
            dout_eop <= 0;
        end
    end

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_mty <= 0;
        end
        else if(rd_en)begin
            dout_mty <= dout_mty_tmp;
        end
        else begin
            dout_mty <= 0;
        end
    end

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_vld <= 0;
        end
        else begin
            dout_vld <= rd_en;
        end
    end









endmodule // bus_conv_16_to_48