`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/11 16:46:40
// Design Name: 
// Module Name: layer1_reg5
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


module layer1_reg5(clk, rst, start, addr_layer1, dout, done);
input clk, rst, start;
input [11:0] addr_layer1;
output signed [43:0] dout;
output reg done;
wire signed [10:0] dout_in, dout_w;
wire signed [21:0] dout_mul;
reg [12:0] addr_layer1_reg;
reg wea; 
reg signed [21:0] din_layer1;
wire signed [21:0] dout_b;
reg [9:0] addr_in;
reg [7:0] addr_w;
reg [2:0] addr_b;
reg [3:0] state;
reg [2:0] cnt_col;
reg [15:0] cnt_stride_ctrl, cnt_col_stride, cnt_row_stride, cnt_weights_ctrl, cnt_weights_stride, cnt_24,  cnt_addr_ctrl,cnt_input_reg, cnt_weights_col;
reg [31:0] cnt_entire;
reg signed [21:0] sum_mul;

layer1_in u0(.clka(clk), .addra(addr_in), .douta(dout_in));
layer1_w u1(.clka(clk), .addra(addr_w), .douta(dout_w));
layer1_b u2(.clka(clk), .addra(addr_b), .douta(dout_b));
mult u3(.CLK(clk), .A(dout_in), .B(dout_w), .P(dout_mul));
layer1_o u4(.clka(clk) ,.wea(wea), .addra(addr_layer1_reg), .dina(din_layer1), .clkb(clk), .addrb(addr_layer1), .doutb(dout));

localparam IDLE = 4'd0, CONV1 = 4'd1, CONV2 = 4'd2, CONV3 = 4'd3, CONV4 = 4'd4, CONV5 = 4'd5,  DONE = 4'd6;
localparam F_SIZE = 3'd5, NUM_1F_PARAM = 15'd19600, NUM_FULL_PARAM = 17'd117600, NUM_COL_SLIDE = 8'd140, NUM_F_SIZE = 6'd25, OUT_SIZE = 16'd4704;
//                                      (28*28*5*5)                  (28*28*5*5*6)              (5*28)                (5*5)             (28*28*6)


always@(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
        case(state)
             IDLE : if(start) state <= CONV1; else state <= IDLE;
             CONV1 : state <= CONV2; 
             CONV2 :  state <= CONV3;       
             CONV3 :  state <= CONV4;
             CONV4 :  state <= CONV5; 
             CONV5 :  state <= CONV1;
            // DONE : if(addr_layer1_reg == 2351) state <= IDLE; else state <= DONE; //good write?  confirm
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
            CONV5 : if(cnt_col == 31) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            default : cnt_col <= cnt_col;
            endcase
end
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_col <= 16'd0;
    else
        case(state)
            CONV5 : if(cnt_weights_col == F_SIZE - 1'd1) cnt_weights_col <= 16'd0; else cnt_weights_col <= cnt_weights_col + 1'd1;
            default : cnt_weights_col <= cnt_weights_col;
            endcase
end
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_stride_ctrl <= 16'd0;
    else
        case(state)
            CONV5 : if(cnt_stride_ctrl == NUM_COL_SLIDE - 1'd1) cnt_stride_ctrl <= 16'd0; else cnt_stride_ctrl <= cnt_stride_ctrl  + 1'd1; 
            default : cnt_stride_ctrl <= cnt_stride_ctrl;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_ctrl <= 16'd0;    
    else
        case(state)
            IDLE:  cnt_weights_ctrl<= 16'd0;
            default : if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1) cnt_weights_ctrl <= 16'd0; else cnt_weights_ctrl <= cnt_weights_ctrl + 1'd1;
            endcase
end


always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_col_stride <= 16'd0;
    else if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1)
        cnt_col_stride <= 16'd0;
    else
        case(state)
            CONV5 :  if(cnt_col == F_SIZE - 1'd1 && cnt_stride_ctrl != NUM_COL_SLIDE - 1'd1) cnt_col_stride <= cnt_col_stride + 1'd1;
                     else if(cnt_col == F_SIZE - 1'd1 && cnt_stride_ctrl == NUM_COL_SLIDE - 1'd1) cnt_col_stride <= 0; 
                     else cnt_col_stride <= cnt_col_stride;
            default : cnt_col_stride <= cnt_col_stride;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_row_stride <= 16'd0;
    else if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1) 
        cnt_row_stride <= 16'd0;    
    else
        case(state)
            CONV5 : if(cnt_stride_ctrl == NUM_COL_SLIDE - 1'd1) cnt_row_stride <= cnt_row_stride + 16'd32; else cnt_row_stride <= cnt_row_stride;
            default : cnt_row_stride <= cnt_row_stride;
            endcase
end 


always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_in <= 10'd0;
    else
        if(cnt_entire < NUM_FULL_PARAM)
        case(state)
            IDLE : addr_in <= 10'd0;
            CONV1 : addr_in <= 10'd0 + cnt_col +   cnt_row_stride;
            CONV2 : addr_in <= 10'd32 + cnt_col + cnt_row_stride;
            CONV3 : addr_in <= 10'd64 + cnt_col + cnt_row_stride;
            CONV4 : addr_in <= 10'd96 + cnt_col + cnt_row_stride;
            CONV5 : addr_in <= 10'd128 + cnt_col + cnt_row_stride;
           default : addr_in <= addr_in;
           endcase
         else
            addr_in <= 0;
end
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_ctrl <= 16'd0;    
    else
        case(state)
            IDLE:  cnt_weights_ctrl<= 16'd0;
            default : if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1) cnt_weights_ctrl <= 16'd0; else cnt_weights_ctrl <= cnt_weights_ctrl + 1'd1;
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
            default :if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1) cnt_weights_stride <= cnt_weights_stride + 6'd25; 
                     else cnt_weights_stride <= cnt_weights_stride;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_24 <= 16'd0;
    else
        case(state)
            IDLE : cnt_24 <= 16'd0;
            default : if(cnt_24 == 16'd24) cnt_24 <= 0; else cnt_24 <= cnt_24 + 1'd1;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_w <= 5'd0;
    else
        if(cnt_entire < NUM_FULL_PARAM)
        case(state)
            CONV1: addr_w <= 6'd0 + cnt_weights_col + cnt_weights_stride;
            CONV2: addr_w <= 6'd5 + cnt_weights_col + cnt_weights_stride;
            CONV3: addr_w <= 6'd10 + cnt_weights_col + cnt_weights_stride;
            CONV4: addr_w <= 6'd15 + cnt_weights_col + cnt_weights_stride;
            CONV5: addr_w <= 6'd20 + cnt_weights_col + cnt_weights_stride;
            default : addr_w <= addr_w;
            endcase
        else
            addr_w <= 5'd0;
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

endmodule
