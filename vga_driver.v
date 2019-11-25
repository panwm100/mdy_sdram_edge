module vga_driver(
        clk         ,
        rst_n       ,
        radius      ,

        din_1       ,//彩色图像
        din_vld_1   ,
        din_sop_1   ,
        din_eop_1   ,
        dout_usedw_1,
        b_rdy_1     ,

        din_2       ,//二值图像
        din_vld_2   ,
        din_sop_2   ,
        din_eop_2   ,
        dout_usedw_2,
        b_rdy_2     ,
        

        vga_hys     ,
        vga_vys     ,
        vga_rgb     ,

        cnt2,
        add_cnt2
    );
    //功能，如果不在圆的范围内，显示彩色图像（din_1） 否则显示 二值图像（din_2）

    //程序流程：
    //上电后，等待2个FIFO都有数据之后才使能显示
    //在“显示区域”的行坐标前一拍，使能 b_rdy_1 b_rdy_2 让din_vld在“显示区域内使能”，注意：b_rdy_1 b_rdy_2也需要提前关闭
    //圆 公式
    //r² = （x - a）² + （y - b）²
    //r = 圆的半径   单位：像素点
    //a = 圆的X坐标
    //b = 圆的Y坐标
    //x = 行计数器的值 注意要 - 144
    //y = 垂直计数器的值 注意要 -35
    //如果计数出来的值 > r² 则显示彩色图像 ， 否则显示二值图像
    
    //通过提前读取二值图像来修正偏移，但是也会导致数据错位（人眼看不出）




    //测试接口，用后删除
    output      [18:0]      cnt2            ;
    output                  add_cnt2        ;


    //圆心坐标
    parameter       CIRCLE_X    = 320;//X坐标 行坐标
    parameter       CIRCLE_Y    = 240;//Y坐标 列坐标
    parameter       CIRCLE_R2   = 22500;//半径的平方  圆半径100 像素点



    // 分辨率 640*480  频率25MHZ
    parameter       TIME_HYS    = 800;//行 脉冲数
    parameter       TIME_VYS    = 525;//垂直 脉冲数


    //数据输入接口
    input                   clk             ;
    input                   rst_n           ;
    input   [7:0]           radius          ;


    input       [15:0]      din_1           ;//彩色图像
    input                   din_vld_1       ;
    input                   din_sop_1       ;
    input                   din_eop_1       ;
    input       [ 8:0]      dout_usedw_1    ;


    input       [15:0]      din_2           ;//二值图像
    input                   din_vld_2       ;
    input                   din_sop_2       ;
    input                   din_eop_2       ;
    input       [ 8:0]      dout_usedw_2    ;

    output                  vga_hys         ;
    output                  vga_vys         ;
    output      [15:0]      vga_rgb         ;

    output                  b_rdy_1         ;
    output                  b_rdy_2         ;

    reg                     vga_hys         ;
    reg                     vga_vys         ;
    reg         [15:0]      vga_rgb         ;
	 reg         [15:0]      din_2_ff0       ;
	 reg         [15:0]      din_1_ff0       ;
           
    wire                    b_rdy_1         ;
    wire                    b_rdy_2         ;
    reg         [16:0]      rr              ;
    reg         [16:0]      distance        ;/*synthesis keep */


    reg                     flag_add        ;

    wire                    add_cnt0        ;
    wire                    end_cnt0        ;
    reg         [ 9:0]      cnt0            ;

    wire                    add_cnt1        ;
    wire                    end_cnt1        ;
    reg         [ 9:0]      cnt1            ;

    wire                    display_area    ;/*synthesis keep */
	 reg                    display_area_ff0;
    reg                     data_sw         ;
    wire        [ 15:0]      circle_x_tmp    ;
    wire        [ 15:0]      circle_y_tmp    ;



    //一上电的时候等到 2个输出FIFO都有数据之后 才开始输出VGA信号
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_add <= 0;
        end
        else if(dout_usedw_1 > 200 && dout_usedw_2 >200)begin
            flag_add <= 1;
        end
    end

    //行计数器
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
    assign add_cnt0 = flag_add;
 //   assign add_cnt0 = 1;
    assign end_cnt0 = add_cnt0 && cnt0 == TIME_HYS-1;//行同步
    
    //垂直计数器
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
    assign end_cnt1 = add_cnt1 && cnt1 == TIME_VYS-1;//垂直同步


    //行同步脉冲
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            vga_hys <= 1'b0;
        end
        else if(add_cnt0 && cnt0 == 96-1)begin
            vga_hys <= 1'b1;
        end
        else if(end_cnt0)begin
            vga_hys <= 1'b0;
        end
    end
    
    //垂直同步脉冲
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            vga_vys <= 1'b0;
        end
        else if(add_cnt1 && cnt1 == 2-1)begin
            vga_vys <= 1'b1;
        end
        else if(end_cnt1)begin
            vga_vys <= 1'b0;
        end
    end
   

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            vga_rgb <= 16'd0;
        end
        else if(display_area)begin
            if(data_sw == 0)begin
                    vga_rgb <= din_2;
            end
            else begin
                    vga_rgb <= din_1;
            end
        end
        else begin
            vga_rgb <= 0;
        end
    end

    //多一个��?1”是因为要使din_vld对齐 
    //注意：只需要在开始的时候多一个��?1��?
    //注意：��?2”是修正2次高斯滤波的偏移
assign b_rdy_1 = add_cnt0 && (cnt0>=(144-1-1) && cnt0<(144+640-1-1)) && (cnt1>=(35-1) && cnt1<(35+480-1));

    assign b_rdy_2 = add_cnt0 && (cnt0>=(144-1-1-2) && cnt0<(144+640-1-1-2)) && (cnt1>=(35-1-2) && cnt1<(35+480-1-2));//修正图像偏移，可能有问题 ！！！！
    //assign b_rdy_2 = add_cnt0 && (cnt0>=(144-1-1) && cnt0<(144+640-1-1)) && (cnt1>=(35-1) && cnt1<(35+480-1));


    assign display_area = add_cnt0 && (cnt0>=(144-1) && cnt0<(144+640-1)) && (cnt1>=(35-1) && cnt1<(35+480-1));




	 always  @(posedge clk or negedge rst_n)begin
	 if (rst_n==0) begin
	 rr <= 0;
	 end
	 else begin
	 rr <= radius * radius;
	 end
	 end


    reg data_sw_ff0;
    reg data_sw_ff1;
always  @(*)begin
        //判断是否在显示区域内
		  data_sw = rr < (cnt0-144+1 - CIRCLE_X) * (cnt0-144+1 - CIRCLE_X)+(cnt1-35+1 - CIRCLE_Y)  * (cnt1-35+1 - CIRCLE_Y) ;
;
    end



    //VGA显示区域
    //144     784
    //
    //35      515



    //测试程序
    wire        add_cnt2;
    wire        end_cnt2;
    reg [18:0]  cnt2    ;

    reg         flag    ;

    always @(posedge clk or negedge rst_n)begin
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
    assign add_cnt2 = din_vld_1 && (flag || din_sop_1);
    assign end_cnt2 = add_cnt2 && cnt2 == 307200 - 1;
    
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag <= 0;
        end
        else if(din_vld_1 && din_sop_1)begin
            flag <= 1;
        end
        else if(din_vld_1 && din_eop_1)begin
            flag <= 0;
        end
    end
    
    







endmodule

