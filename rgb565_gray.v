module rgb565_gray(
        clk         ,
        rst_n       ,
        din         ,
        din_vld     ,
        din_sop     ,
        din_eop     ,
        dout        ,
        dout_vld    ,
        dout_sop    ,
        dout_eop     
    );

    input           clk         ;
    input           rst_n       ;
    input   [15:0]  din         ;
    input           din_vld     ;
    input           din_sop     ;
    input           din_eop     ;

    output  [7:0]   dout        ;
    output          dout_vld    ;
    output          dout_sop    ;
    output          dout_eop    ;

    reg     [7:0]   dout        ;
    reg             dout_vld    ;
    reg             dout_sop    ;
    reg             dout_eop    ;

    wire    [7:0]   red         ;
    wire    [7:0]   green       ;
    wire    [7:0]   bule        ;

    assign red   = {din[15:11] , din[13:11]};
    assign green = {din[10:5]  , din[6:5]  };
    assign bule  = {din[4:0]   , din[2:0]  };

    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 8'd0;
        end
        else if(din_vld)begin
            dout <= (red * 70 + green * 150 + bule *30) >> 8;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_vld <= 1'b0;
        end
        else begin
            dout_vld <= din_vld;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_sop <= 1'b0;
        end
        else begin
            dout_sop <= din_sop;
        end
    end
    
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout_eop <= 1'b0;
        end
        else begin
            dout_eop <= din_eop;
        end
    end

endmodule

