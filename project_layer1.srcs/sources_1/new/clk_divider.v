`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/08 17:49:52
// Design Name: 
// Module Name: clk_divider
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


module clk_divider(clk, clk_out);

input clk;
output reg clk_out;
wire locked;
reg [24:0] cnt;
wire clk_out1;
clk_wiz_0 DUT(.clk_in1(clk), .locked(locked), .clk_out1(clk_out1));

always@(posedge clk_out1)
begin

    case(cnt)
   25'd500 : cnt <= 0;
   default : cnt <= cnt + 1;
   endcase
end

always@(posedge clk_out1)
begin

    case(cnt)
    25'd500 : clk_out <= ~clk_out;
    default : clk_out <= clk_out;
    endcase
end
endmodule
