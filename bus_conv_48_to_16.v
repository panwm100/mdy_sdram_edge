module bus_conv_48to_16(
        clk     ,
        clk_out ,
        rst_n   ,

        din     ,
        din_sop ,
        din_eop ,
        din_vld ,
        din_mty ,
        wr_usedw,

        dout    ,
        dout_sop,
        dout_eop,
        dout_vld,
        dout_mty,
        rd_usedw,
        b_rdy
    );

    //输入
    input                   clk     ;
    input                   clk_out ;
    input                   rst_n   ;

    input       [47:0]      din     ;
    input                   din_vld ;
    input                   din_sop ;
    input                   din_eop ;
    input       [ 2:0]      din_mty ;
    
    input                   b_rdy   ;

    //输出
    output      [15:0]      dout    ;
    output                  dout_vld;
    output                  dout_eop;   
    output                  dout_sop;
    output                  dout_mty;
    output      [ 8:0]      rd_usedw;
    output      [ 8:0]      wr_usedw;

    //输出 reg
    reg         [15:0]      dout    ;
    reg                     dout_vld;
    reg                     dout_eop;   
    reg                     dout_sop;
    reg                     dout_mty;
    wire         [ 8:0]     rd_usedw;
    wire         [ 8:0]     wr_usedw;


    //中间信号
    wire                    wr_en   ;
    wire        [52:0]      wdata   ;

    wire                    wr_full ;


    wire                    add_cnt ;
    wire                    end_cnt ;
    reg         [ 2:0]      cnt     ;
    wire                    dout_eop_tmp;    
    wire                    dout_sop_tmp;
    wire        [ 2:0]      dout_mty_tmp;
    reg         [ 2:0]      x       ;
    wire        [52:0]      q       ;
    wire                    rd_en   ;
    wire                    rd_empty;


    /**************************************************************/
    //写侧
    assign wr_en = din_vld && wr_full == 0;

    assign wdata = {din_sop , din_eop , din_mty , din};


    /**************************************************************/
    //FIFO
    my_fifo#(.DATA_W(53), .DEPT_W(512)) uuu_t(
	    .aclr           (~rst_n     ),

        .wrclk          (clk        ),
	    .data           (wdata      ),
        .wrreq          (wr_en      ),
        .wrempty        (           ),
	    .wrfull         (wr_full    ),
	    .wrusedw        (wr_usedw   ),

	    .rdclk          (clk_out    ),
        .q              (q          ),
	    .rdreq          (rd_en      ),
	    .rdempty        (rd_empty   ),
	    .rdfull         (           ),
	    .rdusedw        (rd_usedw   )
    );


    /**************************************************************/
    //读侧
    always @(posedge clk_out or negedge rst_n)begin
        if(!rst_n)begin
            cnt <= 0;
        end
        else if(add_cnt)begin
            if(end_cnt)
                cnt <= 0;
            else
                cnt <= cnt + 1;
        end
    end
    assign add_cnt = b_rdy && rd_empty == 0;
    assign end_cnt = add_cnt && cnt == x - 1;

    assign dout_sop_tmp = q[52];
    assign dout_eop_tmp = q[51];
    assign dout_mty_tmp = q[50:48];

    always  @(*)begin
        if(dout_mty_tmp != 0)begin
            x = 3 - dout_mty_tmp;
        end
        else begin
            x = 3;
        end
    end

    assign rd_en = end_cnt;


    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 0;
        end
        else if(add_cnt)begin
            dout <= q[47 - cnt*16 -: 16];
        end
    end

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_sop <= 0;
        end
        else if(add_cnt && cnt == 1-1)begin
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
        else if(end_cnt)begin
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
        else if(end_cnt)begin
            dout_mty <= dout_mty_tmp[0];
        end
        else begin
            dout_mty <= 0;
        end
    end

    always  @(posedge clk_out or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_vld <= 0;
        end
        else if(add_cnt)begin
            dout_vld <= 1;
        end
        else begin
            dout_vld <= 0;
        end
    end




endmodule // bus_conv_48to_16