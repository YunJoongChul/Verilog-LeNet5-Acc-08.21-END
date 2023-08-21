`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/04 14:18:26
// Design Name: 
// Module Name: layer2
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


module layer4(clk, rst, start, dout_layer3, addr_layer3, addr_layer4, dout, done);
input clk, rst, start;
input [8:0] addr_layer4;

input signed [21:0] dout_layer3;

output reg [9:0] addr_layer3;
output reg done;

output signed [10:0] dout;
reg signed [10:0] din_layer4;
reg signed [10:0] max_high, max_low;

reg [8:0] addr_layer4_reg;

reg wea ;
reg [3:0] state;
reg [15:0] cnt_col_stride, cnt_row_stride, cnt_module, cnt_max_ctrl;


layer4_o u0(.clka(clk) ,.wea(wea), .addra(addr_layer4_reg), .dina(din_layer4), .clkb(clk), .addrb(addr_layer4), .doutb(dout));


localparam IDLE = 3'd0, MAXPOOLING_HIGH = 3'd1, MAXPOOLING_LOW = 3'd2, DONE = 3'd3;



always@(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
        case(state)
        IDLE : if(start) state <= MAXPOOLING_HIGH ; else state <= IDLE;
        MAXPOOLING_HIGH : state <= MAXPOOLING_LOW;
        MAXPOOLING_LOW : if(addr_layer4_reg == 399 && cnt_max_ctrl == 1) state <=  DONE; else state <= MAXPOOLING_HIGH;
        //DONE : if(addr_layer4 == 399) state <= IDLE; else state <= DONE; //good write?  confirm
        DONE : state <= IDLE;
        default : state <= IDLE;
        endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_col_stride <= 16'd0;
    else
        case(state)
        MAXPOOLING_LOW : if(cnt_col_stride == 4) cnt_col_stride <= 0; else cnt_col_stride <= cnt_col_stride + 1'd1;
        default : cnt_col_stride <= cnt_col_stride;
        endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_row_stride <= 16'd0;
    else
        case(state)
        MAXPOOLING_LOW : if(cnt_col_stride == 4) cnt_row_stride <= cnt_row_stride + 6'd10; else cnt_row_stride <= cnt_row_stride;
        default : cnt_row_stride <= cnt_row_stride;
        endcase
end


always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_layer3 <= 13'd0;
    else
        case(state)
        MAXPOOLING_HIGH : addr_layer3 <=  cnt_col_stride + cnt_row_stride;
        MAXPOOLING_LOW : addr_layer3 <= 7'd5 + cnt_col_stride + cnt_row_stride;
        default : addr_layer3 <= addr_layer3;
        endcase
end
        

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_module <= 16'd0;
    else
        case(state)
            IDLE : cnt_module <= 16'd0;
            default cnt_module <= cnt_module + 1'd1;
            endcase
end
    
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_max_ctrl <= 16'd0;
    else if(cnt_module < 16'd2)
        cnt_max_ctrl <= 16'd0;
    else
        case(state)
            MAXPOOLING_HIGH : cnt_max_ctrl <= 1;
            MAXPOOLING_LOW :  cnt_max_ctrl <= 2;
            default : cnt_max_ctrl <= 0;           
            endcase
end
    
always@(posedge clk or posedge rst)
begin
    if(rst)
        max_high <= 32'd0;
    else
       case(cnt_max_ctrl)
       1: max_high <= (dout_layer3[21:11] > dout_layer3[10:0] ) ?  dout_layer3[21:11] : dout_layer3[10:0];
       default : max_high <= max_high;
       endcase
end        
        
always@(posedge clk or posedge rst)
begin
    if(rst)
        max_low <= 32'd0;
    else
       case(cnt_max_ctrl)
       2 : max_low <=(dout_layer3[21:11] > dout_layer3[10:0] ) ?  dout_layer3[21:11] : dout_layer3[10:0];
       default : max_low <= max_low;
       endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        din_layer4 <= 32'd0;
    else
        case(state)
        MAXPOOLING_LOW : din_layer4 <= (max_high > max_low) ? max_high : max_low;
        default : din_layer4 <= din_layer4;
        endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
         addr_layer4_reg <= 0;
    else if(cnt_module < 16'd5)
          addr_layer4_reg <= 16'd0;
    else
        case(state)
            MAXPOOLING_HIGH :if(cnt_max_ctrl == 2) addr_layer4_reg <= addr_layer4_reg + 1; else  addr_layer4_reg <= addr_layer4_reg;
            default : addr_layer4_reg <= addr_layer4_reg;         
            endcase
end

 always@(posedge clk or posedge rst)
begin
    if(rst)
        wea <= 0;
    else if(cnt_module < 16'd4)
             wea <= 0;
     else
        case(state)
        MAXPOOLING_LOW : if(cnt_max_ctrl ==1) wea <= 1; else wea <= 0;
        default : wea <=0;
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