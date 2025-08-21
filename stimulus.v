`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/22 17:16:04
// Design Name: 
// Module Name: stimulus
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


module stimulus;
reg CLK,nRST,ENCDEC,START;
reg [127:0] TEXTIN,KEY;
wire [127:0] TEXTOUT;
wire DONE;

AES_128 aes(.clk(CLK),.nrst(nRST),.encdec(ENCDEC),.start(START),.done(DONE),.textin(TEXTIN),.textout(TEXTOUT),.key(KEY));

initial
begin
    CLK = 'b0;
    forever #5 CLK = ~CLK;
end

initial
begin
    nRST = 'b0;
    #20 nRST = 'b1;
end

initial
begin
    TEXTIN = 'b0;
    KEY = 'b0;   
    ENCDEC = 'b0;
    START = 'b0;
    #30 START = 'b1;
    TEXTIN = 'h00112233445566778899aabbccddeeff;
    KEY = 'h000102030405060708090a0b0c0d0e0f;
    #10 START = 'b0;
    TEXTIN = 'b0;
    KEY = 'b0;
    #10 START = 'b1;
    #10 START = 'b0;
    KEY = 'b0;
end 
initial
begin
    #160 START = 'b1;
    ENCDEC = 'b1;
    TEXTIN = 'h69c4e0d86a7b0430d8cdb78070b4c55a;
    KEY = 'h000102030405060708090a0b0c0d0e0f;
    #10 START = 'b0;
    ENCDEC = 'b0;
    TEXTIN = 'b0;
    KEY = 'b0;
end

initial
begin
    $monitor($time,"TEXTIN = %h KEY = %h",TEXTIN,KEY);
    $monitor($time,"TEXTOUT = %h",TEXTOUT);
    $monitor($time,"START = %b ENCDEC = %b",START,ENCDEC);
end

initial
    #400 $stop;
    
endmodule
