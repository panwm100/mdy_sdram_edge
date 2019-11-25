module sdram(
        clk    ,
        rst_n  ,

        rw_addr ,//��д��ַ
        rw_bank ,//��д��bank

        wdata   ,//д����
        wr_ack  ,//д������Ӧ��
        wr_req  ,//д����

        rd_vld  ,//����Ч
        rdata   ,//������
        rd_ack  ,//�������õ�Ӧ��
        rd_req  ,//������
 
        sd_clk  ,
        cke     ,
        cs      ,
        ras     ,
        cas     ,
        we      ,
        dqm     ,
        sd_addr ,
        sd_bank ,
        
        dq_in   ,
        dq_out  ,
        dq_out_en
    );
    
    //ʹ�÷�����
    //д��
    //д�� ��ַ��rw_addr 0-4095 ҳ��ַ��  д��bank(rw_bank)  ��Ϊ��ҳģʽ����ֻ��ҳ��ַû���е�ַ��ÿ�ζ�����д��256������
    //���wr_req
    //���յ�wr_ackʱ��ʱ���߼��������wr_req��ʱ���߼��������ҿ�ʼд��256�����ݣ�wdata��

    //��ȡ
    //д����ȡ��ַ��rw_addr 0-4095 ҳ��ַ��  д��bank(rw_bank)  ��Ϊ��ҳģʽ����ֻ��ҳ��ַû���е�ַ��ÿ�ζ�������ȡ256������
    //���rd_req
    //���յ�rd_ackʱ��ʱ���߼��������rd_req��ʱ���߼���
    //��rd_vld = 1 ʱ��ȡ���ݣ�ʱ���߼���




    //ÿҳ������256
    //ÿ�ι̶���дһҳ
    //���ȼ� ���Զ�ˢ�¡� > ����� > ��д��

    //ÿ1562��ʱ�ӱ��뷢��һ�� ���Զ�ˢ�¡� ���� PRECHARGE_CMD ������������
    //ÿ1300 �����ڷ���һ�� ���Զ�ˢ�¡� ���� PRECHARGE_CMD ������������ 1300 + 256 = 1556  < 1562

    /*
    ��ʼ�����̣��ֲ�35ҳ����
    1���ȴ�100us

    2��Ԥ���� 
        PRECHARGE_CMD
        CKE = 1         //����������ʲô�ã���߾���
        ALL_BANK
        delay(TIME_TRP)

    3���Զ����� ��һ��
        AUTOREREF_CMD
        delay(TIME_TRC)

    4���Զ����� �ڶ���
        AUTOREREF_CMD
        delay(TIME_TRC)

    5������ģʽ
        MODE_CMD
        CODE        //����ģʽ
        delay(TIME_TMRD)
    ��ʼ������
    */

    /*
    ͻ��ģʽд��һҳ ����д��256������
    1������
        ACTIVE_CMD
        sd_addr <= rw_addr //ѡ���е�ַ��0-4095��
        sd_bank <= rw_bank //ѡ��bank��0-3��
        delay(TIME_TRCD)

    2��д�� �ĵ�һ��ʱ������
        WRITE_CMD
        sd_addr <= 0 //ҳģʽ �е�ַ����Ϊ 0
        sd_bank <= rw_bank //ѡ��bank��0-3�� �����ͼ�����bank��ͬ

    3�����д��ʣ����255������

    4���ض����� �� ���³���
        PRECHARGE_CMD
        ALL_BANK
        delay(TIME_TRP)
    д����
    */

    /*
    ͻ��ģʽ���һҳ �������256������
    ��Ϊѡ������ʱ2��ʱ�����ڣ����ԣ�����������2��֮�����յ����ݣ�������Ԥ���硱���������ݣ���Ч����һ��Ҳ����Ч��
    1������
        ACTIVE_CMD
        sd_addr <= rw_addr //ѡ���е�ַ��0-4095��
        sd_bank <= rw_bank //ѡ��bank��0-3��
        delay(TIME_TRCD)

    2��д�� ��Ҫ������е�ַ
        READ_CMD
        sd_addr <= 0 //ҳģʽ �е�ַ����Ϊ 0
        sd_bank <= rw_bank //ѡ��bank��0-3�� �����ͼ�����bank��ͬ
        delay(2 clk) //��ʱ2��ʱ�� ����ʱ�� ������ģʽ�� ��������


    3��������256������

    4���ض����� �� ���³���
        PRECHARGE_CMD
        ALL_BANK
        delay(TIME_TRP)
    �����
    */

    /*
    ��ʱˢ��
    1������ָ��
        AUTOREREF_CMD
        delay(TIME_TRC)
    */



    //ʱ�� 100MHZ ÿ��ʱ��10ns
    //
    parameter TIME_100US    = 10_000    ;   // > 100us
    parameter TIME_TRP      = 3         ;   // > 20ns
    parameter TIME_TRC      = 7         ;   // > 63ns
    parameter TIME_TMRD     = 2         ;   // = 2��ʱ��
    parameter TIME_TRCD     = 3         ;   //������ʱ
    parameter TIME_1300     = 780       ;   //�Զ�ˢ������
    parameter TIMER_PAGE    = 256       ;   //ÿҳ�Ĵ�С

    //�ֲ���7ҳ
    //����ָ��
    parameter NOP_CMD       = 4'b1000   ;//NOP
    parameter PRECHARGE_CMD = 4'b0010   ;//Ԥ����
    parameter AUTOREREF_CMD = 4'b0001   ;//�Զ�����
    parameter MODE_CMD      = 4'b0000   ;//д��ģʽ
    parameter ACTIVE_CMD    = 4'b0011   ;//ѡ�񲢼��� ���С�
    parameter WRITE_CMD     = 4'b0100   ;//ѡ�����С�����ʼͻ��д������
    parameter READ_CMD      = 4'b0101   ;//ѡ�����С�����ʼͻ����ȡ����

    //ָ��
    parameter  ALL_BANK     = 12'b01_0_00_000_0_000;
    parameter  CODE         = 12'b00_0_00_010_0_111;


    //״̬���ı���
    parameter   INIT_NOP    = 4'd0      ;//�ϵ����ȴ�100us
    parameter   INIT_CHARGE = 4'd1      ;//Ԥ����
    parameter   INIT_REF1   = 4'd2      ;//�Զ�ˢ�� ��һ��
    parameter   INIT_REF2   = 4'd3      ;//�Զ�ˢ�� �ڶ���
    parameter   INIT_MODE   = 4'd4      ;//����ģʽ�Ĵ���
    parameter   ST_IDLE     = 4'd5      ;//��ʼ�����ɺ󣬿���״̬
    parameter   ST_REF      = 4'd6      ;//�Զ�ˢ��
    parameter   WR_ACTIVE   = 4'd7      ; 
    parameter   WR_WRITE    = 4'd8      ; 
    parameter   WR_CHARGE   = 4'd9      ;
    parameter   RD_ACTIVE   = 4'd10     ; 
    parameter   RD_READ     = 4'd11     ; 
    parameter   RD_CHARGE   = 4'd12     ;


    //�����źŶ���
    input                       clk     ;
    input                       rst_n   ;
    input       [11:0]          rw_addr ;//ȫҳģʽ��ֻ��д�е�ַ0-4095
    input       [47:0]          wdata   ;
    input       [47:0]          dq_in   ;//ȫ��SDRAM������

    input                       rd_req  ;
    input                       wr_req  ;
    input       [1:0]           rw_bank ;
 


    //�����źŶ���
    output                      sd_clk  ;//SDRAMʱ��  ȡ������ʱ�ӵõ�
    output      [47:0]          dq_out  ;//ȫ��SDRAM������
    output                      dq_out_en;
    output                      cke     ;
    output                      cs      ;
    output                      ras     ;
    output                      cas     ;
    output                      we      ;
    output      [5:0]           dqm     ;
    output      [11:0]          sd_addr ;
    output      [1:0]           sd_bank ;

    output                      wr_ack  ;
    output                      rd_ack  ;
    output      [47:0]          rdata   ;
    output                      rd_vld  ;

    //�����ź�reg����
    reg                         sd_clk  ;//SDRAMʱ��  ȡ������ʱ�ӵõ�
    reg         [47:0]          dq_out  ;//ȫ��SDRAM������
    reg                         dq_out_en;
    reg                         cke     ;
    reg                         cs      ;
    reg                         ras     ;
    reg                         cas     ;
    reg                         we      ;
    reg         [5:0]           dqm     ;
    reg         [11:0]          sd_addr ;
    reg         [1:0]           sd_bank ;

    reg                         wr_ack  ;
    reg                         rd_ack  ;
    reg         [47:0]          rdata   ;
    reg                         rd_vld  ;





    wire    nop_2_charge_start          ;
    wire    charge_2_ref0_start         ;
    wire    ref1_2_ref2_start           ;
    wire    ref2_2_mode_start           ;
    wire    mode_2_idle_start           ;
    wire    idle_2_ref_start            ;
    wire    ref_2_idle_start            ;
    wire    idle_2_wr_active_start      ;
    wire    wr_active_2_wr_write_start  ;
    wire    wr_write_2_wr_charge_start  ;
    wire    wr_charge_2_idle_start      ;

    wire   idle_2_rd_active_start       ;
    wire   rd_active_2_rd_read_start    ;
    wire   rd_read_2_rd_charge_start    ;
    wire   rd_charge_2_idle_start       ;
    

    //�м��ź�
    reg         [3:0]       state_c     ;
    reg         [3:0]       state_n     ;

    wire                    add_cnt0    ;
    wire                    end_cnt0    ;
    reg         [13:0]      cnt0        ;

    wire                    add_cnt1    ;
    wire                    end_cnt1    ;
    reg         [13:0]      cnt1        ;

    reg         [13:0]      x           ;

    reg                     rd_vld_ff0  ;
    reg                     rd_vld_ff1  ;
    reg                     rd_vld_ff2  ;   

    wire                    wdata_en    ;

    wire                    wait_ref    ;

    wire                    init_state  ;

    reg         [3:0]       command     ;



    //SDRAM ʱ��
    always  @(*)begin
        //��������ȡ��������ʱ��Լ��
        sd_clk = ~clk;//SDRAMʱ�ӣ���λƫ��180��
    end



    //�Ķ�ʽ״̬��
    //��һ�Σ�ͬ��ʱ��alwaysģ�飬��ʽ��������̬�Ĵ���Ǩ�Ƶ���̬�Ĵ���(�������ģ�
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            state_c <= INIT_NOP;
        end
        else begin
            state_c <= state_n;
        end
    end

    //�ڶ��Σ������߼�alwaysģ�飬����״̬ת�������ж�
    always@(*)begin
        case(state_c)
            /***************************  ��ʼ�� ********************************/
            INIT_NOP:begin
                if(nop_2_charge_start)begin //�ϵ����ȴ�100us
                    state_n = INIT_CHARGE;
                end
                else begin
                    state_n = state_c;
                end
            end

            INIT_CHARGE:begin //Ԥ����
                if(charge_2_ref0_start)begin
                    state_n = INIT_REF1;
                end
                else begin
                    state_n = state_c;
                end
            end

            INIT_REF1:begin //�Զ�ˢ�� ��һ��
                if(ref1_2_ref2_start)begin
                    state_n = INIT_REF2;
                end
                else begin
                    state_n = state_c;
                end
            end

            INIT_REF2:begin //�Զ�ˢ�� �ڶ���
                if(ref2_2_mode_start)begin
                    state_n = INIT_MODE;
                end
                else begin
                    state_n = state_c;
                end
            end

            INIT_MODE:begin //����ģʽ�Ĵ���
                if(mode_2_idle_start)begin
                    state_n = ST_IDLE;
                end
                else begin
                    state_n = state_c;
                end
            end

            /***************************  ����״̬ ********************************/
            ST_IDLE:begin //��ʼ�����ɺ󣬿���״̬
                if(idle_2_ref_start)begin //ת���� ���Զ�ˢ�¡�
                    state_n = ST_REF;
                end
                else if (idle_2_rd_active_start) begin //ת���� ����_���
                    state_n = RD_ACTIVE;
                end
                else if (idle_2_wr_active_start) begin //ת���� ��д_���
                    state_n = WR_ACTIVE;
                end

                else begin
                    state_n = state_c;
                end
            end

            /***************************  �Զ�ˢ�� ********************************/
            ST_REF:begin //�Զ�ˢ��
                if(ref_2_idle_start)begin
                    state_n = ST_IDLE;
                end
                else begin
                    state_n = state_c;
                end
            end

            /***************************  д���� ********************************/
            WR_ACTIVE:begin //д_���� ����ʼ��
                if(wr_active_2_wr_write_start)begin
                    state_n = WR_WRITE;
                end
                else begin
                    state_n = state_c;
                end
            end

            WR_WRITE:begin //д_����
                if(wr_write_2_wr_charge_start)begin
                    state_n = WR_CHARGE;
                end
                else begin
                    state_n = state_c;
                end
            end
            
            WR_CHARGE:begin //д_���� ��������
                if(wr_charge_2_idle_start)begin
                    state_n = ST_IDLE;
                end
                else begin
                    state_n = state_c;
                end
            end
            
            /***************************  ������ ********************************/
            RD_ACTIVE:begin //��_���� ����ʼ��
                if(rd_active_2_rd_read_start)begin
                    state_n = RD_READ;
                end
                else begin
                    state_n = state_c;
                end
            end

            RD_READ:begin //��_����
                if(rd_read_2_rd_charge_start)begin
                    state_n = RD_CHARGE;
                end
                else begin
                    state_n = state_c;
                end
            end

            RD_CHARGE:begin //��_���� ��������
                if(rd_charge_2_idle_start)begin
                    state_n = ST_IDLE;
                end
                else begin
                    state_n = state_c;
                end
            end



            default:begin
                state_n = INIT_NOP;
            end
        endcase
    end
    //�����Σ�����ת������
    /***************************  ��ʼ�� ********************************/
    assign nop_2_charge_start           = state_c==INIT_NOP     && end_cnt0;//�ϵ����ȴ�100us
    assign charge_2_ref0_start          = state_c==INIT_CHARGE  && end_cnt0;//Ԥ����
    assign ref1_2_ref2_start            = state_c==INIT_REF1    && end_cnt0;//�Զ�ˢ�� ��һ��
    assign ref2_2_mode_start            = state_c==INIT_REF2    && end_cnt0;//�Զ�ˢ�� �ڶ���
    assign mode_2_idle_start            = state_c==INIT_MODE    && end_cnt0;//����ģʽ�Ĵ���

    /***************************  ����״̬ ********************************/
    assign idle_2_ref_start             = state_c==ST_IDLE      && end_cnt1;//��ʼ�����ɺ󣬿���״̬ ת���� �Զ�ˢ��
    assign idle_2_wr_active_start       = state_c==ST_IDLE      && wr_req  ;//��ʼ�����ɺ󣬿���״̬ ת���� ����д��
    assign idle_2_rd_active_start       = state_c == ST_IDLE    && rd_req  ;//��ʼ�����ɺ󣬿���״̬ ת���� ������ȡ

    /***************************  �Զ�ˢ�� ********************************/
    assign ref_2_idle_start             = state_c==ST_REF       && end_cnt0;//�Զ�ˢ��

    /***************************  д���� ********************************/
    assign wr_active_2_wr_write_start   = state_c == WR_ACTIVE  && end_cnt0;//
    assign wr_write_2_wr_charge_start   = state_c == WR_WRITE   && end_cnt0;
    assign wr_charge_2_idle_start       = state_c == WR_CHARGE  && end_cnt0;

    /***************************  ������ ********************************/
    assign rd_active_2_rd_read_start    = state_c == RD_ACTIVE  && end_cnt0;
    assign rd_read_2_rd_charge_start    = state_c == RD_READ    && end_cnt0;
    assign rd_charge_2_idle_start       = state_c == RD_CHARGE  && end_cnt0;

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
    assign add_cnt0 = state_c != ST_IDLE;
    assign end_cnt0 = add_cnt0 && cnt0 == x - 1;

    //�������� ����ֵ
    always  @(*)begin
        /***************************  ��ʼ�� ********************************/
        if(state_c == INIT_NOP)begin
            x = TIME_100US;
        end
        else if(state_c == INIT_CHARGE)begin
            x = TIME_TRP;
        end
        else if(state_c == INIT_REF1)begin
            x = TIME_TRC;
        end
        else if(state_c == INIT_REF2)begin
            x = TIME_TRC;
        end
        else if(state_c == INIT_MODE)begin
            x = TIME_TMRD;
        end


        /***************************  �Զ�ˢ�� ********************************/
        else if(state_c == ST_REF)begin
            x = TIME_TRC;
        end

         /***************************  д���� ********************************/
        else if(state_c == WR_ACTIVE)begin
            x = TIME_TRCD;
        end
        else if(state_c == WR_WRITE)begin
            x = TIMER_PAGE;//����256������
        end
        else if(state_c == WR_CHARGE)begin
            x = TIME_TRP;
        end

        /***************************  ������ ********************************/
        else if(state_c == RD_ACTIVE)begin
            x = TIME_TRCD;
        end
        else if(state_c == RD_READ)begin
            x = TIMER_PAGE;//����256������
        end
        else if(state_c == RD_CHARGE)begin
            x = TIME_TRP;
        end

        else begin
            x = 0;
        end
    end
    

    //�Զ�ˢ�� ������
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt1 <= 0;
        end
        else if(wait_ref)begin//�ڷ��͵�ʱ���������������������򱣳�����״̬�����ټ���
            cnt1 <= cnt1;
        end
        else if(add_cnt1)begin
            if(end_cnt1)
                cnt1 <= 0;
            else
                cnt1 <= cnt1 + 1;
        end
    end
    assign add_cnt1 = !init_state;//��ʼ�����ɺ���ʼ����
    assign end_cnt1 = add_cnt1 && cnt1 == TIME_1300 - 1;
    //������������ʱ������д���ݣ���ô���� end_cnt  ֱ��������� 
    assign wait_ref = state_c != ST_IDLE && cnt1 == TIME_1300 - 1;
    
    //��ʼ����־λ
    assign init_state = state_c==INIT_NOP || state_c==INIT_CHARGE || state_c==INIT_REF1 || state_c==INIT_REF2 || state_c==INIT_MODE;


    //��Чʹ���ź�cke
    //�ϵ�100us������
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            cke <= 1'b0;
        end
        else if(nop_2_charge_start)begin
            cke <= 1'b1;
        end
    end


    //CS RAS CAS WE 4���ź�
    always  @(*)begin
        {cs , ras , cas , we} = command;
    end

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            command <= NOP_CMD;
        end
        /***************************  ��ʼ�� ********************************/
        else if(nop_2_charge_start)begin
            command <= PRECHARGE_CMD;//Ԥ����
        end
        else if(charge_2_ref0_start || ref1_2_ref2_start)begin
            command <= AUTOREREF_CMD;//�Զ�ˢ��
        end
        else if(ref2_2_mode_start)begin
            command <= MODE_CMD;//д��ģʽ����
        end

        /***************************  ��ʱˢ�� ********************************/
        else if(idle_2_ref_start)begin
            command <= AUTOREREF_CMD;//�Զ�ˢ��
        end

        /***************************  д������ ********************************/
        else if(idle_2_wr_active_start)begin
            command <= ACTIVE_CMD;//д�� ����
        end
        else if(wr_active_2_wr_write_start)begin
            command <= WRITE_CMD;//д�� ����
        end
        else if(wr_write_2_wr_charge_start)begin
            command <= PRECHARGE_CMD;//д�� ���� //�ض��������ݣ�����ʼԤ����
        end

        /***************************  ��ȡ���� ********************************/
        else if(idle_2_rd_active_start)begin
            command <= ACTIVE_CMD;//��ȡ ����
        end
        else if(rd_active_2_rd_read_start)begin
            command <= READ_CMD;//��ȡ ����
        end
        else if(rd_read_2_rd_charge_start)begin
            command <= PRECHARGE_CMD;//��ȡ ���� //�ض϶�ȡ���ݣ�����ʼԤ����
        end


        else begin
            command <= NOP_CMD;
        end
    end
    
    //dqm = {LDQM , UDQM}
    //dqm ������������źţ��ߵ�ƽ��ʾ��Σ����ܲ������ߣ��͵�ƽ��ʾ���Բ�������
    //��ʼ�������У��������
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dqm <= 0;
        end
        else if(init_state)begin
            dqm <= 6'b111111;
        end
        else begin
            dqm <= 6'b000000;
        end
    end


    //���� ģʽ
    //�ֲ�35ҳ
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sd_addr <= 0;
        end
        else if(nop_2_charge_start || wr_write_2_wr_charge_start || rd_read_2_rd_charge_start)begin
            sd_addr <= ALL_BANK;//A10==1 ѡ��ȫbank��ͬʱbank��ַ��������
        end
        else if(ref2_2_mode_start)begin
            sd_addr <= CODE;//CODE==000_0_00_010_0_111������ģʽ�Ĵ�����ѡ��ȫҳburst��дģʽ��Latancy=2
            //00    ����
            //1     ��һ����λ��
            //00    ��׼����
            //010   ������ʱ2��ʱ������
            //0     ͻ������--���
            //111   ��ҳ
        end
        else if (idle_2_wr_active_start || idle_2_rd_active_start) begin
            sd_addr <= rw_addr;//�м�����ַ 1��bank�� 0- 4096
        end 
        else begin
            sd_addr <= 0;//��Ϊʹ����ҳ��ȡģʽ�������е�ַ�̶�Ϊ0 ����ʱ��Ҳ��0
        end
    end

    //�� ����
    //������ ��д��ʱ�� ����Ҫ����BANK
    //������ �����ʱ�� ����Ҫ����BANK
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            sd_bank <= 0;
        end
        else if(idle_2_wr_active_start || idle_2_rd_active_start || wr_active_2_wr_write_start || rd_active_2_rd_read_start)begin
            sd_bank <= rw_bank;
        end
        else
            sd_bank = 2'b00;
    end



    //wr_ack
    always  @(*)begin
        wr_ack = wr_active_2_wr_write_start;
    end

    //rd_ack
    always  @(*)begin
        rd_ack = rd_active_2_rd_read_start;
    end

    
    //rd_data
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rdata <= 0;
        end
        else begin
            rdata <= dq_in;
        end
    end
    
    //rd_vld
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rd_vld_ff0 <= 0;
        end
        else if(rd_active_2_rd_read_start)begin
            rd_vld_ff0 <= 1;
        end
        else if(rd_read_2_rd_charge_start)begin
            rd_vld_ff0 <= 0;
        end
    end
    
    //rdata_vld ��3��
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            rd_vld_ff1 <= 0;
            rd_vld_ff2 <= 0;
            rd_vld     <= 0;
        end
        else begin
            rd_vld_ff1 <= rd_vld_ff0;
            rd_vld_ff2 <= rd_vld_ff1;
            rd_vld     <= rd_vld_ff2;
        end
    end
    
    //dq_out
    always  @(*)begin
        dq_out = wdata;
    end
    
    //ע������
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dq_out_en <= 0;
        end
        else if(wr_active_2_wr_write_start)begin
            dq_out_en <= 1;
        end
        else if(wr_write_2_wr_charge_start)begin
            dq_out_en <= 0;
        end
    end


endmodule // sdram_init
