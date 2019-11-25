module control(
    clk          ,
    rst_n        ,
    din          ,
    din_vld      ,
    config_en    ,
    radius       ,
    gray_value 
);

input            clk         ;
input            rst_n       ;
input     [7:0]  din         ;
input            din_vld     ;

output           config_en   ;
output    [7:0]  gray_value  ;
output    [7:0]  radius      ;

reg       [1:0]  cnt         ;
reg       [7:0]  address     ;
reg       [7:0]  data        ;
reg              config_en   ;
reg       [7:0]  gray_value  ;
reg       [7:0]  radius      ;
wire             add_cnt     ;
wire             end_cnt     ;
wire      [7:0]  din         ;
wire             din_vld     ;




always @(posedge clk or negedge rst_n)begin
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

assign add_cnt = din_vld;       
assign end_cnt = add_cnt && cnt== 2-1;   
reg     config_en_vld;
reg [4:0] cnt0;
wire      add_cnt0;
wire      end_cnt0;
reg       flag;
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

assign add_cnt0 = config_en_vld&&flag==0;       
assign end_cnt0 = add_cnt0 && cnt0== 10-1;   
always  @(posedge clk or negedge rst_n)begin
if(rst_n==0)begin
flag <= 0;
end
else if(end_cnt0)begin
flag <= 1;
end
end
always  @(posedge clk or negedge rst_n)begin
if(rst_n==0)begin
config_en <= 0;
end
else if(end_cnt0)begin
config_en <= 1;
end
else begin
config_en <= 0;
end
end

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        address <= 0;
    end
    else if(add_cnt&&cnt==1-1)begin
        address <= din;
    end
end

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        data <= 0;
    end
    else if(add_cnt&&cnt==2-1)begin
        data <= din;
    end
end

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        config_en_vld <= 0;
    end
    else if(address==8'h01&&data==8'h01)begin
        config_en_vld <= 1;
    end
    else begin
        config_en_vld <= 0;
    end
end

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        gray_value <= 0;
    end
    else if(address==8'h02)begin
        gray_value <= data;
    end
end
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        radius <= 0;
    end
    else if(address==8'h03)begin
        radius <= data;
    end
end










endmodule
