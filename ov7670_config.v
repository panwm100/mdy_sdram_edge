/*********www.mdy-edu.com ������ƽ� ע�Ϳ�ʼ****************
������רעFPGA��ѵ���о������н�FPGA��Ŀ������Ŀ������Ϳ���������ٷ���̳ѧϰ��http://www.fpgabbs.cn/����������������PCIE��MIPI����Ƶƴ�ӵȼ���������QȺ97925396��������ѧϰ
**********www.mdy-edu.com ������ƽ� ע�ͽ���****************/

module ov7670_config(
        clk        ,
        rst_n      ,
        config_en  ,
        rdy        ,
        rdata      ,
        rdata_vld  ,
        wdata      ,
        addr       ,
        wr_en	   ,
        rd_en      ,
        cmos_en    , 
        pwdn         
    );

    //参数定义
    parameter               DATA_W = 8  ;
    parameter               wr_NUM = 2  ;
    parameter               REG_NUM =165;
    
    //输入信号定义
    input                   clk         ;   //50Mhz
    input                   rst_n       ;
    input                   config_en   ;
    input                   rdy         ;
    input   [DATA_W-1:0]    rdata       ;
    input                   rdata_vld   ;

    //输出信号定义
    output  [DATA_W-1:0]    wdata       ;
    output  [DATA_W-1:0]    addr        ;
    
    output                  cmos_en     ;
    output                  wr_en       ;
    output                  rd_en       ;
    output                  pwdn        ;

    reg     [DATA_W-1:0]    wdata       ;
    reg     [DATA_W-1:0]    addr        ;
    
    reg                     cmos_en     ;
    reg                     wr_en       ;
    reg                     rd_en       ;
    reg                     pwdn        ;


    wire                    add_wr_cnt  ;
    wire                    end_wr_cnt  ;
    reg     [1:0]           wr_cnt      ; 

    wire                    add_reg_cnt ;
    wire                    end_reg_cnt ;
    reg     [7:0]           reg_cnt     ;

    reg                     flag        ; 

    reg     [17:0]          add_wdata   ;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            wr_cnt <= 0;
        end
        else if(add_wr_cnt)begin
            if(end_wr_cnt)
                wr_cnt <= 0;
            else
                wr_cnt <= wr_cnt + 1;
        end
    end
    assign add_wr_cnt = flag && rdy;
    assign end_wr_cnt = add_wr_cnt && wr_cnt == wr_NUM - 1;
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            reg_cnt <= 0;
        end
        else if(add_reg_cnt)begin
            if(end_reg_cnt)
                reg_cnt <= 0;
            else
                reg_cnt <= reg_cnt + 1;
        end
    end
    assign add_reg_cnt = end_wr_cnt;
    assign end_reg_cnt = add_reg_cnt && reg_cnt == REG_NUM - 1;
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag <= 1'b0;
        end
        else if(config_en)begin
            flag <= 1'b1;            
        end
        else if(end_reg_cnt)begin
            flag <= 1'b0;            
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            cmos_en <= 1'b0;
        end
        else if(end_reg_cnt)begin
            cmos_en <= 1'b1;            
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            addr <= 8'd0;
        end
        else begin
            addr <= add_wdata[15:8];
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            pwdn <= 1'b0;
        end
        else begin
            pwdn <= 1'b0;
        end
    end


    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wdata <= 8'd0;
        end
        else begin
            wdata <= add_wdata[7:0];
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            wr_en <= 1'b0;
        end
        else if(add_wr_cnt && wr_cnt == 0 && add_wdata[16])begin
            wr_en <= 1'b1;
        end
        else begin
            wr_en <= 1'b0;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rd_en <= 1'b0;
        end
        else if(add_wr_cnt && wr_cnt == 1 && add_wdata[17])begin
            rd_en <= 1'b1;
        end
        else begin
            rd_en <= 1'b0;
        end
    end
    

    always@(*) begin
        case(reg_cnt)
            0   : add_wdata = {2'b11,16'h1204};	//复位，VGA，RGB565 (00:YUV,04:RGB)(8x全局复位)
            1   : add_wdata = {2'b11,16'h40d0};	//RGB565, 00-FF(d0)（YUV下要改01-FE(80))
            2   : add_wdata = {2'b11,16'h3a04};    //TSLB(TSLB[3], COM13[0])00:YUYV, 01:YVYU, 10:UYVY(CbYCrY), 11:VYUY
            3   : add_wdata = {2'b11,16'h3dc8};	//COM13(TSLB[3], COM13[0])00:YUYV, 01:YVYU, 10:UYVY(CbYCrY), 11:VYUY
            4   : add_wdata = {2'b11,16'h1e31};	//默认01，Bit[5]水平镜像，Bit[4]竖直镜像
            5   : add_wdata = {2'b11,16'h6b00};	//旁路PLL倍频；0x0A：关闭内部LDO；0x00：打开LDO
            6   : add_wdata = {2'b11,16'h32b6};	//HREF 控制(80)
            7   : add_wdata = {2'b11,16'h1713};	//HSTART 输出格式-行频开始高8位(11) 
            8   : add_wdata = {2'b11,16'h1801};	//HSTOP  输出格式-行频结束高8位(61)
            9   : add_wdata = {2'b11,16'h1902};	//VSTART 输出格式-场频开始高8位(03)
            10  : add_wdata = {2'b11,16'h1a7a};	//VSTOP  输出格式-场频结束高8位(7b)
            11  : add_wdata = {2'b11,16'h030a};	//VREF	 帧竖直方向控制(00)
            12  : add_wdata = {2'b11,16'h0c00};	//DCW使能 禁止(00)
            13  : add_wdata = {2'b11,16'h3e10};	//PCLK分频00 Normal，10（1分频）,11（2分频）,12（4分频）,13（8分频）14（16分频）
            14  : add_wdata = {2'b11,16'h7000};	//00:Normal, 80:移位1, 00:彩条, 80:渐变彩条
            15  : add_wdata = {2'b11,16'h7100};	//00:Normal, 00:移位1, 80:彩条, 80：渐变彩条
            16  : add_wdata = {2'b11,16'h7211};	//默认 水平，垂直8抽样(11)	        
            17  : add_wdata = {2'b11,16'h7300};	//DSP缩放时钟分频00 Normal，10（1分频）,11（2分频）,12（4分频）,13（8分频）14（16分频） 
            18  : add_wdata = {2'b11,16'ha202};	//默认 像素始终延迟	(02)
            19  : add_wdata = {2'b11,16'h1180};	//内部工作时钟设置，直接使用外部时钟源(80)
            20  : add_wdata = {2'b11,16'h7a20};
            21  : add_wdata = {2'b11,16'h7b1c};
            22  : add_wdata = {2'b11,16'h7c28};
            23  : add_wdata = {2'b11,16'h7d3c};
            24  : add_wdata = {2'b11,16'h7e55};
            25  : add_wdata = {2'b11,16'h7f68};
            26  : add_wdata = {2'b11,16'h8076};
            27  : add_wdata = {2'b11,16'h8180};
            28  : add_wdata = {2'b11,16'h8288};
            29  : add_wdata = {2'b11,16'h838f};
            30  : add_wdata = {2'b11,16'h8496};
            31  : add_wdata = {2'b11,16'h85a3};
            32  : add_wdata = {2'b11,16'h86af};
            33  : add_wdata = {2'b11,16'h87c4};
            34  : add_wdata = {2'b11,16'h88d7};
            35  : add_wdata = {2'b11,16'h89e8};
            36  : add_wdata = {2'b11,16'h13e0};
            37  : add_wdata = {2'b11,16'h0010};//
            38  : add_wdata = {2'b11,16'h1000};
            39  : add_wdata = {2'b11,16'h0d00};
            40  : add_wdata = {2'b11,16'h1428}; 
            41  : add_wdata = {2'b11,16'ha505};
            42  : add_wdata = {2'b11,16'hab07};
            43  : add_wdata = {2'b11,16'h2475};
            44  : add_wdata = {2'b11,16'h2563};
            45  : add_wdata = {2'b11,16'h26a5};
            46  : add_wdata = {2'b11,16'h9f78};
            47  : add_wdata = {2'b11,16'ha068};
            48  : add_wdata = {2'b11,16'ha103};
            49  : add_wdata = {2'b11,16'ha6df};
            50  : add_wdata = {2'b11,16'ha7df};
            51  : add_wdata = {2'b11,16'ha8f0};
            52  : add_wdata = {2'b11,16'ha990};
            53  : add_wdata = {2'b11,16'haa94};
            54  : add_wdata = {2'b11,16'h13ef};  
            55  : add_wdata = {2'b11,16'h0e61};
            56  : add_wdata = {2'b11,16'h0f4b};
            57  : add_wdata = {2'b11,16'h1602};
            58  : add_wdata = {2'b11,16'h2102};
            59  : add_wdata = {2'b11,16'h2291};
            60  : add_wdata = {2'b11,16'h2907};
            61  : add_wdata = {2'b11,16'h330b};
            62  : add_wdata = {2'b11,16'h350b};
            63  : add_wdata = {2'b11,16'h371d};
            64  : add_wdata = {2'b11,16'h3871};
            65  : add_wdata = {2'b11,16'h392a};
            66  : add_wdata = {2'b11,16'h3c78};
            67  : add_wdata = {2'b11,16'h4d40};
            68  : add_wdata = {2'b11,16'h4e20};
            69  : add_wdata = {2'b11,16'h6900};
            
            70  : add_wdata = {2'b11,16'h7419};
            71  : add_wdata = {2'b11,16'h8d4f};
            72  : add_wdata = {2'b11,16'h8e00};
            73  : add_wdata = {2'b11,16'h8f00};
            74  : add_wdata = {2'b11,16'h9000};
            75  : add_wdata = {2'b11,16'h9100};
            76  : add_wdata = {2'b11,16'h9200};
            77  : add_wdata = {2'b11,16'h9600};
            78  : add_wdata = {2'b11,16'h9a80};
            79  : add_wdata = {2'b11,16'hb084};
            80  : add_wdata = {2'b11,16'hb10c};
            81  : add_wdata = {2'b11,16'hb20e};
            82  : add_wdata = {2'b11,16'hb382};
            83  : add_wdata = {2'b11,16'hb80a};

            84  : add_wdata = {2'b11,16'h4314};
            85  : add_wdata = {2'b11,16'h44f0};
            86  : add_wdata = {2'b11,16'h4534};
            87  : add_wdata = {2'b11,16'h4658};
            88  : add_wdata = {2'b11,16'h4728};
            89  : add_wdata = {2'b11,16'h483a};
            90  : add_wdata = {2'b11,16'h5988};
            91  : add_wdata = {2'b11,16'h5a88};
            92  : add_wdata = {2'b11,16'h5b44};
            93  : add_wdata = {2'b11,16'h5c67};
            94  : add_wdata = {2'b11,16'h5d49};
            95  : add_wdata = {2'b11,16'h5e0e};
            96  : add_wdata = {2'b11,16'h6404};
            97  : add_wdata = {2'b11,16'h6520};
            98  : add_wdata = {2'b11,16'h6605};
            99  : add_wdata = {2'b11,16'h9404};
            100 : add_wdata = {2'b11,16'h9508};
            101 : add_wdata = {2'b11,16'h6c0a};
            102 : add_wdata = {2'b11,16'h6d55};
            103 : add_wdata = {2'b11,16'h6e11};
            104 : add_wdata = {2'b11,16'h6f9f};
            105 : add_wdata = {2'b11,16'h6a40};
            106 : add_wdata = {2'b11,16'h0140};
            107 : add_wdata = {2'b11,16'h0240};
            108 : add_wdata = {2'b11,16'h13e7};
            109 : add_wdata = {2'b11,16'h1500};
            
            110 : add_wdata = {2'b11,16'h4f80};
            111 : add_wdata = {2'b11,16'h5080};
            112 : add_wdata = {2'b11,16'h5100};
            113 : add_wdata = {2'b11,16'h5222};
            114 : add_wdata = {2'b11,16'h535e};
            115 : add_wdata = {2'b11,16'h5480};
            116 : add_wdata = {2'b11,16'h589e};
            
            117 : add_wdata = {2'b11,16'h4108};
            118 : add_wdata = {2'b11,16'h3f00};
            119 : add_wdata = {2'b11,16'h7505};
            120 : add_wdata = {2'b11,16'h76e1};
            121 : add_wdata = {2'b11,16'h4c00};
            122 : add_wdata = {2'b11,16'h7701};
            
            123 : add_wdata = {2'b11,16'h4b09};
            124 : add_wdata = {2'b11,16'hc9F0};//16'hc960;
            125 : add_wdata = {2'b11,16'h4138};
            126 : add_wdata = {2'b11,16'h5640};
            
            
            127 : add_wdata = {2'b11,16'h3411};
            128 : add_wdata = {2'b11,16'h3b02};
            129 : add_wdata = {2'b11,16'ha489};
            130 : add_wdata = {2'b11,16'h9600};
            131 : add_wdata = {2'b11,16'h9730};
            132 : add_wdata = {2'b11,16'h9820};
            133 : add_wdata = {2'b11,16'h9930};
            134 : add_wdata = {2'b11,16'h9a84};
            135 : add_wdata = {2'b11,16'h9b29};
            136 : add_wdata = {2'b11,16'h9c03};
            137 : add_wdata = {2'b11,16'h9d4c};
            138 : add_wdata = {2'b11,16'h9e3f};
            139 : add_wdata = {2'b11,16'h7804};
            
            
            140 :add_wdata =  {2'b11,16'h7901};
            141 :add_wdata =  {2'b11,16'hc8f0};
            142 :add_wdata =  {2'b11,16'h790f};
            143 :add_wdata =  {2'b11,16'hc800};
            144 :add_wdata =  {2'b11,16'h7910};
            145 :add_wdata =  {2'b11,16'hc87e};
            146 :add_wdata =  {2'b11,16'h790a};
            147 :add_wdata =  {2'b11,16'hc880};
            148 :add_wdata =  {2'b11,16'h790b};
            149 :add_wdata =  {2'b11,16'hc801};
            150 :add_wdata =  {2'b11,16'h790c};
            151 :add_wdata =  {2'b11,16'hc80f};
            152 :add_wdata =  {2'b11,16'h790d};
            153 :add_wdata =  {2'b11,16'hc820};
            154 :add_wdata =  {2'b11,16'h7909};
            155 :add_wdata =  {2'b11,16'hc880};
            156 :add_wdata =  {2'b11,16'h7902};
            157 :add_wdata =  {2'b11,16'hc8c0};
            158 :add_wdata =  {2'b11,16'h7903};
            159 :add_wdata =  {2'b11,16'hc840};
            160 :add_wdata =  {2'b11,16'h7905};
            161 :add_wdata =  {2'b11,16'hc830}; 
            162 :add_wdata =  {2'b11,16'h7926};
            
            163 : add_wdata = {2'b11,16'h0903};
            164 : add_wdata = {2'b11,16'h3b42};
        
            default : add_wdata = 0;
        endcase
    end


endmodule
