module vga_config(
        clk         ,
        rst_n       ,
        din         ,
        din_vld     ,
        din_sop     ,
        din_eop     ,
        rd_addr     ,
        rd_en       ,
        rd_end      ,
        rd_addr_sel ,
        dout        ,
        wr_end           
    );

    input               clk         ;
    input               rst_n       ;
    input               din         ;
    input               din_vld     ;
    input               din_sop     ;
    input               din_eop     ;
    input   [15:0]      rd_addr     ;
    input               rd_en       ;
    input               rd_end      ;
    input               rd_addr_sel ;

    output              dout        ;
    output              wr_end      ;

    reg                 dout        ;
    reg                 wr_end      ;

    wire                add_cnt_col ;
    wire                end_cnt_col ;
    reg     [9:0]       cnt_col     ;

    wire                add_cnt_row ;
    wire                end_cnt_row ;
    reg     [9:0]       cnt_row     ;

    reg                 wr_flag     ;
    reg                 wr_addr_sel ;

    reg                 wr_data     ;
    reg     [15:0]      wr_addr     ;

    reg                 wr_en0      ;
    reg                 wr_en1      ;

    wire                q0          ;
    wire                q1          ;

    wire                display_area;

    reg                 rd_en0      ;
    reg                 rd_en1      ;

    my_ram_ipcore u0(
	    .clock      (clk       ),
	    .data       (wr_data   ),
	    .rdaddress  (rd_addr   ),
	    .rden       (rd_en0    ),
	    .wraddress  (wr_addr   ),
	    .wren       (wr_en0    ),
	    .q          (q0        ) 
    );

    my_ram_ipcore u1(
	    .clock      (clk       ),
	    .data       (wr_data   ),
	    .rdaddress  (rd_addr   ),
	    .rden       (rd_en1    ),
	    .wraddress  (wr_addr   ),
	    .wren       (wr_en1    ),
	    .q          (q1        ) 
    );

    //计数 X 轴数量
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt_col <= 0;
        end
        else if(add_cnt_col)begin
            if(end_cnt_col)
                cnt_col <= 0;
            else
                cnt_col <= cnt_col + 1;
        end
    end
    assign add_cnt_col = (wr_flag || (wr_end == 0 && din_sop)) && din_vld; //第一个输入也要计数，所以加上(wr_end == 0 && din_sop)
    assign end_cnt_col = add_cnt_col && cnt_col == 640 - 1;
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt_row <= 0;
        end
        else if(add_cnt_row)begin
            if(end_cnt_row)
                cnt_row <= 0;
            else
                cnt_row <= cnt_row + 1;
        end
    end
    assign add_cnt_row = end_cnt_col;
    assign end_cnt_row = add_cnt_row && cnt_row == 480 - 1;

    //计数Y轴数量
    //wr_end = 0 说明RAM的内容已被读出，可以写入
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_flag <= 1'b0;
        end
        else if(wr_end == 0 && din_sop)begin
            wr_flag <= 1'b1;
        end
        else if(end_cnt_row)begin
            wr_flag <= 1'b0;
        end
    end
    
    //wr_end 用来指示是否写入完成
    //用途：为切换RAM，判断是否能输入 的其中一个条件
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_end <= 1'b0;
        end
        else if(end_cnt_row)begin
            wr_end <= 1'b1;
        end
        else if(wr_end && rd_end)begin
            wr_end <= 1'b0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_data <= 1'b0;
        end
        else if(display_area)begin
            wr_data <= din;
        end
    end
    //向RAM写入数据，因为RAM大小有限，所以截取中间的像素写入
    assign display_area = cnt_col >= 160 && cnt_col <480 && cnt_row >=140 && cnt_row < 340;

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_addr <= 16'd0;
        end
        else if(display_area)begin
            wr_addr <= cnt_col - 160 + 320 * (cnt_row - 140);//减去偏移地址
        end
    end
    
    //写入完成，读出完成，切换RAM
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_addr_sel <= 1'b0;
        end
        else if(rd_end && wr_end)begin
            wr_addr_sel <= ~wr_addr_sel;
        end
    end
    
    //display_area 判断是否是需要写入的像素点
    //wr_addr_sel  写入RAM_0 还是RAM_1
    //din_vld      在输入数据有效的时候才写入
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_en0 <= 1'b0;
        end
        else if(display_area && wr_addr_sel == 0 && din_vld)begin
            wr_en0 <= 1'b1;
        end
        else begin
            wr_en0 <= 1'b0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_en1 <= 1'b0;
        end
        else if(display_area && wr_addr_sel == 1 && din_vld)begin
            wr_en1 <= 1'b1;
        end
        else begin
            wr_en1 <= 1'b0;
        end
    end
    
    //根据 输入信号 决定读取哪个RAM
    always  @(*)begin
        if(rd_en && rd_addr_sel == 0)begin
            rd_en0 = 1;
        end
        else begin
            rd_en0 = 0;
        end
    end
    
    always  @(*)begin
        if(rd_en && rd_addr_sel == 1)begin
            rd_en1 = 1;
        end
        else begin
            rd_en1 = 0;
        end
    end
    
    //根据输入信号选择的RAM 把对应的RAM输出接到dout
    always  @(*)begin
        if(rd_addr_sel == 0)begin
            dout = q0;
        end
        else if(rd_addr_sel == 1)begin
            dout = q1;
        end
        else begin
            dout = 0;
        end
    end
    
    

endmodule

