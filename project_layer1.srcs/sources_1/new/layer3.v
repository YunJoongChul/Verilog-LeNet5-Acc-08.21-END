`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/05 14:35:10
// Design Name: 
// Module Name: layer3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module layer3(clk, rst, start, dout_layer2, addr_layer2, addr_layer3, dout, done);
input clk, rst, start;
input [9:0] addr_layer3;
output reg [7:0] addr_layer2;

input [65:0] dout_layer2;

output reg done;
output signed [21:0] dout;

wire [95:0] dout_w;

wire signed [16:0] dout_b;

reg signed [15:0] sum_mul;

wire signed [15:0] dout_1f_mul, dout_2f_mul, dout_3f_mul, dout_4f_mul, dout_5f_mul, dout_6f_mul;



reg  signed [10:0] din_layer3;
wire signed [10:0] din_truncate;


reg [8:0] addr_w;
reg [10:0] addr_layer3_reg;
reg [9:0] addrb;
reg [3:0] addr_b;

reg [3:0] state;
reg wea;

reg [2:0] cnt_col, cnt_weight_6ch;
reg [15:0] cnt_stride_ctrl, cnt_col_stride, cnt_row_stride, cnt_ch,cnt_ch_ctrl, cnt_weights_ctrl, cnt_weights_stride, cnt_25, cnt_addr_ctrl;
reg [31:0] cnt_entire;

localparam IDLE = 4'd0, CONV1 = 4'd1, CONV2 = 4'd2, CONV3 = 4'd3, CONV4 = 4'd4, CONV5 = 4'd5,  DONE = 4'd6;

layer3_w u0(.clka(clk), .addra(addr_w), .douta(dout_w));
layer3_b u1(.clka(clk), .addra(addr_b), .douta(dout_b));
mult_layer3 x0(.CLK(clk), .A(dout_layer2[65:55]), .B(dout_w[86:80]), .P(dout_1f_mul));
mult_layer3 x1(.CLK(clk), .A(dout_layer2[54:44]), .B(dout_w[70:64]), .P(dout_2f_mul));
mult_layer3 x2(.CLK(clk), .A(dout_layer2[43:33]), .B(dout_w[54:48]), .P(dout_3f_mul));
mult_layer3 x3(.CLK(clk), .A(dout_layer2[32:22]), .B(dout_w[38:32]), .P(dout_4f_mul));
mult_layer3 x4(.CLK(clk), .A(dout_layer2[21:11]), .B(dout_w[22:16]), .P(dout_5f_mul));
mult_layer3 x5(.CLK(clk), .A(dout_layer2[10:0]), .B(dout_w[6:0]), .P(dout_6f_mul));
layer3_o u3(.clka(clk) ,.wea(wea), .addra(addr_layer3_reg), .dina(din_layer3), .clkb(clk), .addrb(addr_layer3), .doutb(dout));

assign din_truncate = sum_mul[15:5] + dout_b[16:6];

always@(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
        case(state)
             IDLE : if(start) state <= CONV1; else state <= IDLE;
             CONV1 : if(cnt_col == 4) state <= CONV2;   else state <= CONV1;
             CONV2 : if(cnt_col == 4) state <= CONV3; else if(addr_layer3_reg == 13'd1599 && cnt_addr_ctrl == 16'd0) state <= DONE; else state <= CONV2;
             CONV3 : if(cnt_col == 4) state <= CONV4; else state <= CONV3;
             CONV4 : if(cnt_col == 4) state <= CONV5; else state <= CONV4;
             CONV5 : if(cnt_col == 4) state <= CONV1;else state <= CONV5;
             //DONE : if(addrb == 799) state <= IDLE; else state <= DONE; //good write?  confirm
             DONE : state <= IDLE;  
             default : state <= IDLE;
             endcase
end



always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_col <= 16'd0;
    else
        case(state)
            CONV1 : if(cnt_col == 4) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            CONV2 : if(cnt_col == 4) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            CONV3 : if(cnt_col == 4) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            CONV4 : if(cnt_col == 4) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            CONV5 : if(cnt_col == 4) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            default : cnt_col <= 16'd0;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_stride_ctrl <= 16'd0;
    else
        case(state)
            CONV5 : if(cnt_stride_ctrl == 49) cnt_stride_ctrl <= 0; else cnt_stride_ctrl  <= cnt_stride_ctrl  + 1'd1; // 10*5
            default : cnt_stride_ctrl <= cnt_stride_ctrl;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_col_stride <= 16'd0;
    else if(cnt_weights_ctrl == 2499)
        cnt_col_stride <= 16'd0;
    else
        case(state)
            CONV5 : if(cnt_col == 4 && cnt_stride_ctrl != 49) cnt_col_stride <= cnt_col_stride + 1'd1; else if(cnt_col == 4 && cnt_stride_ctrl == 49) cnt_col_stride <= 0; else cnt_col_stride <= cnt_col_stride;
            default : cnt_col_stride <= cnt_col_stride;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_row_stride <= 16'd0;
    else if(cnt_weights_ctrl == 2499) 
        cnt_row_stride <= 16'd0;    
    else
        case(state)
            CONV5 : if(cnt_stride_ctrl == 49) cnt_row_stride <= cnt_row_stride + 16'd14; else cnt_row_stride <= cnt_row_stride;
            default : cnt_row_stride <= cnt_row_stride;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_layer2 <= 10'd0;
    else
        if(cnt_entire < 16'd40000)//5*5*16*10*10/6
        case(state)
            IDLE : addr_layer2 <= 10'd0;
            CONV1 : addr_layer2 <= 10'd0 + cnt_col + cnt_col_stride + cnt_row_stride;
            CONV2 : addr_layer2 <= 10'd14 + cnt_col + cnt_col_stride + cnt_row_stride;
            CONV3 : addr_layer2 <= 10'd28 + cnt_col + cnt_col_stride + cnt_row_stride;
            CONV4 : addr_layer2 <= 10'd42 + cnt_col + cnt_col_stride + cnt_row_stride;
            CONV5 : addr_layer2 <= 10'd56 + cnt_col + cnt_col_stride + cnt_row_stride;
           default : addr_layer2 <= addr_layer2;
           endcase
        else
            addr_layer2 <= 10'd0;
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_ctrl <= 16'd0;    
    else
        case(state)
            IDLE:  cnt_weights_ctrl<= 16'd0;
            default : if(cnt_weights_ctrl == 2499) cnt_weights_ctrl <= 0; else cnt_weights_ctrl <= cnt_weights_ctrl + 1'd1; // 5*5*10*10 = 2500
            endcase
end



always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_stride <= 16'd0;
    else
        case(state)
            IDLE : cnt_weights_stride <= 16'd0;
            DONE : cnt_weights_stride <= 16'd0;
            default :if(cnt_weights_ctrl == 2499) cnt_weights_stride <= cnt_weights_stride + 25; else cnt_weights_stride <= cnt_weights_stride;
       
            endcase
end 
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_25 <= 16'd0;
    else
        case(state)
            IDLE : cnt_25 <= 16'd0;
            default : if(cnt_25 == 24) cnt_25 <= 0; else cnt_25 <= cnt_25 + 1'd1;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_w <= 12'd0;
    else
        if(cnt_entire < 16'd40000)//5*5*16*10*10
        case(state)
            IDLE : addr_w <= 12'd0;
            default : if(addr_w == cnt_weights_stride + 24) addr_w <= cnt_weights_stride; else  addr_w <= cnt_weights_stride + cnt_25;
            endcase
        else
            addr_w <= 12'd0;
end      

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_entire <= 32'd0;
    else
        case(state)
            IDLE:  cnt_entire <= 32'd0;
            DONE:  cnt_entire <= 32'd0;
            default : cnt_entire <= cnt_entire + 1'd1;
            endcase
end

//why cnt_ram < 7? read 2, mult 3, sum 1 , delay
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_addr_ctrl <= 16'd0;
    else
        case(state)
            IDLE:  cnt_addr_ctrl <= 16'd0;
            CONV1 : if(cnt_entire < 6) cnt_addr_ctrl <= 16'd0;  else cnt_addr_ctrl <= cnt_addr_ctrl +1'd1;
            CONV2 : if(cnt_entire < 7) cnt_addr_ctrl <= 16'd0; 
                    else if(cnt_addr_ctrl == 24) cnt_addr_ctrl <= 16'd0;
                    else cnt_addr_ctrl <= cnt_addr_ctrl +1'd1;
            default : cnt_addr_ctrl <= cnt_addr_ctrl + 1'd1;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_b <= 3'd0;
    else
        begin
        case(state)
            IDLE : addr_b <= 3'd0;
            DONE : addr_b <= 3'd0;
            default :if(cnt_weights_ctrl == 2499 &&  cnt_weights_stride != 375) addr_b <= addr_b + 1'd1; else addr_b <= addr_b; //5*5*10*10
            endcase
        end
end 


//why cmt < 6 sum mul zero? read 2, mult 3 delay
always@(posedge clk or posedge rst)
begin
    if(rst)
        sum_mul <= 32'd0;
    else
        case(state)
           IDLE : sum_mul <= 0;
           CONV2 : if(cnt_entire < 6) sum_mul <= 0;
                   else if(cnt_addr_ctrl == 24) sum_mul <= dout_1f_mul + dout_2f_mul + dout_3f_mul + dout_4f_mul + dout_5f_mul+ dout_6f_mul;
                   else sum_mul <= sum_mul + dout_1f_mul + dout_2f_mul + dout_3f_mul + dout_4f_mul + dout_5f_mul+ dout_6f_mul;
           default : sum_mul <= sum_mul + dout_1f_mul + dout_2f_mul + dout_3f_mul + dout_4f_mul + dout_5f_mul+ dout_6f_mul;
           endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        din_layer3 <= 16'd0;
    else
        case(state)
            CONV2 :if(cnt_addr_ctrl == 5'd24) din_layer3 <= (din_truncate > 0) ? din_truncate : 0; else din_layer3 <= din_layer3;
            default : din_layer3 <= din_layer3;
            endcase
end


always@(posedge clk or posedge rst)
begin
    if(rst)
    addr_layer3_reg <= 0;
    else
    case(state)
    CONV2 : if(cnt_addr_ctrl == 16'd0  && cnt_entire > 30 && addr_layer3_reg != 11'd1599) addr_layer3_reg <= addr_layer3_reg + 1'd1; 
            else if(addr_layer3_reg == 11'd1599 && cnt_addr_ctrl == 16'd0) addr_layer3_reg <= 11'd0;  
            else addr_layer3_reg <= addr_layer3_reg;
    default addr_layer3_reg <= addr_layer3_reg;
    endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        wea <= 1'd0;
    else
        case(state)
            CONV2 : if(cnt_addr_ctrl == 24) wea <= 1'd1;  else wea <= 1'd0;
            default : wea <= 1'd0;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        addrb <= 10'd0;
    else
        case(state)
            DONE : addrb <= addrb + 1;
            default : addrb <= 0;
            endcase
end
always@(posedge clk or posedge rst)
begin
    if(rst)
        done <= 1'd0;
    else
        case(state)
        DONE : done <= 1'd1;
        default : done <= 1'd0;
        endcase
end
endmodule
