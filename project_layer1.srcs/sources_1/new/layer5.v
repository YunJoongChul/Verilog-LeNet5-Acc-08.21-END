`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/07 18:48:03
// Design Name: 
// Module Name: layer5
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


module layer5(clk, rst, start, dout_layer4, addr_layer4, addr_layer5, dout, done);
input clk, rst, start;
input  [6:0] addr_layer5;

input signed [21:0] dout_layer4;


output reg [8:0] addr_layer4;
output reg done;

wire signed [25:0] dout_b;


wire signed [15:0] dout_mul;
reg signed [15:0] sum_mul;

output signed [10:0] dout;
reg signed [10:0] din_layer5;
wire signed [10:0] din_truncate;

wire signed [6:0] dout_w;

reg [15:0] addr_w;
reg [6:0] addr_b;
reg [6:0] addr_layer5_reg;

reg [3:0] state; 
reg wea;
reg [15:0] cnt_addr_ctrl, cnt_weights_ctrl, cnt_400, cnt_entire, cnt_input_ctrl, cnt_weights_stride; 

layer5_w u0(.clka(clk), .addra(addr_w), .douta(dout_w));
layer5_b u1(.clka(clk), .addra(addr_b), .douta(dout_b));
mult_layer5 u2(.CLK(clk), .A(dout_layer4), .B(dout_w), .P(dout_mul));
layer5_o u3(.clka(clk) ,.wea(wea), .addra(addr_layer5_reg), .dina(din_layer5), .clkb(clk), .addrb(addr_layer5), .doutb(dout));
localparam IDLE = 4'd0, FC = 4'd1, DONE = 4'd2;


assign din_truncate = sum_mul[15:5] + dout_b[25:15];
always@(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
       case(state)
        IDLE : if(start) state <= FC ; else state <= IDLE;
        FC : if(addr_layer5_reg == 119&& cnt_addr_ctrl == 0) state <= DONE; else state <= FC;
        //DONE : if(addr_layer5 == 119) state <= IDLE; else state <= DONE; //good write?  confirm
        DONE : state <= IDLE;
        default state <= IDLE;
        endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_input_ctrl <= 16'd0;
    else
        case(state)
            FC : if(cnt_input_ctrl == 399) cnt_input_ctrl <= 0; else cnt_input_ctrl <= cnt_input_ctrl + 1'd1;
            default : cnt_input_ctrl <= 16'd0;
        endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_layer4 <= 9'd0;
    else
        case(state)
            FC : if(addr_layer4 == 399) addr_layer4 <= 9'd0; else addr_layer4 <= cnt_input_ctrl ;
            default : addr_layer4 <= 9'd0;
            endcase
end  
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_ctrl <= 16'd0;    
    else
        case(state)
            IDLE:  cnt_weights_ctrl<= 16'd0;
            default : if(cnt_weights_ctrl == 399) cnt_weights_ctrl <= 16'd0; else cnt_weights_ctrl <= cnt_weights_ctrl + 1'd1;
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
            default :if(cnt_weights_ctrl == 399) cnt_weights_stride <= cnt_weights_stride + 9'd400; 
                     else cnt_weights_stride <= cnt_weights_stride;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_400 <= 16'd0;
    else
        case(state)
            IDLE : cnt_400 <= 16'd0;
            default : if(cnt_400 == 16'd399) cnt_400 <= 0; else cnt_400 <= cnt_400 + 1'd1;
            endcase
end       
always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_w <= 16'd0;
    else
        case(state)
            FC : if(addr_w == cnt_weights_stride + 9'd399) addr_w <= cnt_weights_stride;  else addr_w <= cnt_weights_stride + cnt_400;
            default : addr_w <= 16'd0;
            endcase
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



always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_addr_ctrl <= 16'd0;
    else
        case(state)
            FC: if(cnt_entire < 7) cnt_addr_ctrl <= 16'd0; else if(cnt_addr_ctrl == 399) cnt_addr_ctrl <=16'd0; else cnt_addr_ctrl <= cnt_addr_ctrl + 1'd1;
            default : cnt_addr_ctrl <= 16'd0;
        endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        sum_mul <= 32'd0;
    else
        case(state)
           FC : if(cnt_entire < 6) sum_mul <= 0; 
                   else if(cnt_addr_ctrl == 399) sum_mul <= dout_mul; 
                   else sum_mul <= sum_mul + dout_mul;
           default : sum_mul <= 0;
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
            default :if(cnt_weights_ctrl == 399 && cnt_weights_stride != 16'd47600) addr_b <= addr_b + 1'd1; 
                     else addr_b <= addr_b;
            endcase
        end
end 



always@(posedge clk or posedge rst)
begin
    if(rst)
        din_layer5 <= 16'd0;
    else
        case(state)
            FC :if(cnt_addr_ctrl == 399) din_layer5 <= (din_truncate > 0) ? din_truncate : 0; else din_layer5 <= din_layer5;
            default : din_layer5 <= din_layer5;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
    addr_layer5_reg <= 0;
    else
    case(state)
    FC : if(cnt_addr_ctrl == 16'd0  && cnt_entire > 20 && addr_layer5_reg != 119) addr_layer5_reg <= addr_layer5_reg + 1'd1; 
            else if(addr_layer5_reg == 119 && cnt_addr_ctrl == 16'd0) addr_layer5_reg <= 0;
            else addr_layer5_reg <= addr_layer5_reg;
    default addr_layer5_reg <= addr_layer5_reg;
    endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        wea <= 1'd0;
    else
        case(state)
            FC : if(cnt_addr_ctrl == 399) wea <= 1'd1;  else wea <= 1'd0;
            default : wea <= 1'd0;
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
/*
always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_layer5 <= 7'd0;
    else
        case(state)
        DONE : addr_layer5 <= addr_layer5 + 1'd1;
        default : done <= 1'd0;
        endcase
end
*/
endmodule
