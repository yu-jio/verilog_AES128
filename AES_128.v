`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/16 13:00:53
// Design Name: 
// Module Name: AES_128
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
module AES_128(
clk,nrst,encdec,start,key,textin,done,textout
    );
input clk,nrst,encdec,start;
input [127:0] key,textin;
output done;
output reg [127:0] textout;

parameter [4:0] Nr = 'd10,
                 Nk = 'd4,
                 Nb = 'd4;

parameter [3:0] s0 = 'd0,
                e1 = 'd1,
                e2 = 'd2,
                e3 = 'd3,
                d1 = 'd4,
                d2 = 'd5,
                d3 = 'd6,
                d4 = 'd7,
                fi = 'd8;
                            
reg [127:0] states [0:Nr+1];
reg [127:0] fullkeys [0:Nr+1];
reg [127:0] afterSubBytes;
reg [127:0] afterShiftRows;
reg [127:0] afterMixColumns;
reg [127:0] afterRoundKey;

reg [3:0] state;
reg [3:0] next_state;
reg done = 'b0;

integer round = 'd0;

always@(negedge nrst or posedge clk)
    if(!nrst)
        state <= s0;
    else
        state <= next_state;
            
always@(posedge clk)
begin
    if(state == e2 || state ==d1)
    begin
        round = round + 1;
    end
    else if(state == d3)
    begin
        round = round -1;
    end
end 

    
always@(state or round or start)
    case(state)
        s0:
        begin
            done='d0;
            textout='d0;
            round = 0;
            if(start)
            begin
            fullkeys[round] = key;
                if(encdec)
                begin
                    states[Nr+1]=textin; 
                    next_state = d1; 
                end                    
                else
                begin
                    states[round]=textin; 
                    next_state = e1;
                end
            end
            else
                next_state = s0;          
        end
        e1:
        begin
            states[round+1]=AddRoundKey(states[round],fullkeys[round]);
            fullkeys[round+1] = KeyExpension(fullkeys[round],round);
            round = 1;
            next_state = e2;
        end
        e2:
        begin
                afterSubBytes = SubBytes(states[round]);
		        afterShiftRows = ShiftRows(afterSubBytes);
		        afterMixColumns = MixColumns (afterShiftRows);
		        states[round+1] = AddRoundKey (afterMixColumns,fullkeys[round]);
		        fullkeys[round+1] = KeyExpension(fullkeys[round],round);
		    if(round == 9)
		      next_state = e3;
		end
		e3:
		begin
		   afterSubBytes = SubBytes(states[round]);
		   afterShiftRows = ShiftRows(afterSubBytes); 
		   states[round+1] = AddRoundKey (afterShiftRows,fullkeys[round]);
		   round=round+1;
		   next_state = fi;
		end
		d1:
		begin
		  fullkeys[round+1] = KeyExpension(fullkeys[round],round);
		  if(round == Nr)
		      next_state = d2;       
		end
		d2:
		begin
		  round = Nr;
		  states[round] = AddRoundKey(states[round+1],fullkeys[round]);
		  next_state = d3;    
		end
		d3:
		begin
		        afterShiftRows = InvShiftRows(states[round]);
		        afterSubBytes = InvSubBytes(afterShiftRows);
		        afterRoundKey = AddRoundKey (afterSubBytes,fullkeys[round-1]);
		        states[round-1] = InvMixColumns (afterRoundKey);
		        if(round == 2)
		          next_state = d4;
		end
		d4:
		begin
		  afterShiftRows = InvShiftRows(states[round]);
		  afterSubBytes = InvSubBytes(afterShiftRows);
		  states[round] = AddRoundKey (afterSubBytes,fullkeys[round-1]);
		  next_state=fi;
		end
		fi:
		begin
		  textout=states[round];
		  done='d1;
		  next_state=s0;
		end
		default:
		  next_state=s0;  
     endcase
    

function [127:0] KeyExpension;
    input [127:0] key; 
    input integer round;       
    reg [31:0] w [0:3];
    reg [31:0] r [0:3];       
    reg [31:0] temp;           
    reg [31:0] rot, sub, rcon; 
    integer i;

    begin
        for (i = 0; i < 4; i = i + 1) begin
            w[i] = key[127-i*32-:32]; 
        end
        temp = w[3];                    
        rot = rotword(temp);         
        sub = subwordx(rot);                  
        rcon = rconx(round+1);            
        r[0] = w[0] ^ (sub ^ rcon);     
        for (i = 1; i < 4; i = i + 1) begin
            r[i] = r[i - 1] ^ w[i];     
        end
        KeyExpension = {r[0], r[1], r[2], r[3]};
    end
endfunction

function [0:31] rotword;
    input [0:31] x;
begin
		rotword={x[8:31],x[0:7]};
end
endfunction

function [0:31] subwordx;
    input [0:31] a;
 
begin
    subwordx[0:7]=SBOX(a[0:7]);
    subwordx[8:15]=SBOX(a[8:15]);
    subwordx[16:23]=SBOX(a[16:23]);    
    subwordx[24:31]=SBOX(a[24:31]);
end
endfunction

function [127:0] SubBytes;
    input [127:0] in;
    integer i;
begin
for(i=0;i<128;i=i+8) 
	SubBytes[i+:8] = SBOX(in[i +:8]);
end
endfunction

function [127:0] InvSubBytes;
    input [127:0] in;
    integer i;
begin
for(i=0;i<128;i=i+8) 
	InvSubBytes[i+:8] = InvSBOX(in[i +:8]);
end
endfunction

function [127:0] ShiftRows;
    input [127:0] state_in;
    reg [31:0] temp;
    integer i;
begin
    for(i=0;i<Nk;i=i+1)
    begin
        temp = {state_in[127-(i*8)-:8],state_in[127-(i*8+32)-:8],state_in[127-(i*8+64)-:8],state_in[127-(i*8+96)-:8]};
        if(i>0)
            temp = (temp>>(32-(i*8))) | (temp << (i*8));
        
        ShiftRows[127-(i*8)-:8] = temp[31-:8];
        ShiftRows[127-(i*8+32)-:8] = temp[23-:8];
        ShiftRows[127-(i*8+64)-:8] = temp[15-:8];   
        ShiftRows[127-(i*8+96)-:8] = temp[7-:8];
    end
end
endfunction

function [127:0] InvShiftRows;
    input [127:0] state_in;
    reg [31:0] temp;
    integer i;
begin
    for(i=0;i<Nk;i=i+1)
    begin
        temp = {state_in[127-(i*8)-:8],state_in[127-(i*8+32)-:8],state_in[127-(i*8+64)-:8],state_in[127-(i*8+96)-:8]};
        if(i>0)
            temp = (temp>>(i*8)) | (temp << (32-(i*8)));
            InvShiftRows[127-(i*8)-:8] = temp[31-:8];
            InvShiftRows[127-(i*8+32)-:8] = temp[23-:8];
            InvShiftRows[127-(i*8+64)-:8] = temp[15-:8];   
            InvShiftRows[127-(i*8+96)-:8] = temp[7-:8];
    end
end
endfunction
  
function [127:0] AddRoundKey;
    input [127:0] data;
    input [127:0] key;
AddRoundKey = key ^ data;
endfunction

function [127:0] MixColumns;
    input [127:0] state_in;
    integer i;
begin
    for(i=0;i< 4;i=i+1)
    begin
        MixColumns[(i*32 + 24)+:8]= mb2(state_in[(i*32 + 24)+:8]) ^ mb3(state_in[(i*32 + 16)+:8]) ^ state_in[(i*32 + 8)+:8] ^ state_in[i*32+:8];
	    MixColumns[(i*32 + 16)+:8]= state_in[(i*32 + 24)+:8] ^ mb2(state_in[(i*32 + 16)+:8]) ^ mb3(state_in[(i*32 + 8)+:8]) ^ state_in[i*32+:8];
	    MixColumns[(i*32 + 8)+:8]= state_in[(i*32 + 24)+:8] ^ state_in[(i*32 + 16)+:8] ^ mb2(state_in[(i*32 + 8)+:8]) ^ mb3(state_in[i*32+:8]);
        MixColumns[i*32+:8]= mb3(state_in[(i*32 + 24)+:8]) ^ state_in[(i*32 + 16)+:8] ^ state_in[(i*32 + 8)+:8] ^ mb2(state_in[i*32+:8]);
    end
end
endfunction

function [127:0] InvMixColumns;
    input [127:0] state_in;
    integer i;
begin
    for(i=0;i< 4;i=i+1)
    begin
       InvMixColumns[(i*32 + 24)+:8]= mb0e(state_in[(i*32 + 24)+:8]) ^ mb0b(state_in[(i*32 + 16)+:8]) ^ mb0d(state_in[(i*32 + 8)+:8]) ^ mb09(state_in[i*32+:8]);
	   InvMixColumns[(i*32 + 16)+:8]= mb09(state_in[(i*32 + 24)+:8]) ^ mb0e(state_in[(i*32 + 16)+:8]) ^ mb0b(state_in[(i*32 + 8)+:8]) ^ mb0d(state_in[i*32+:8]);
	   InvMixColumns[(i*32 + 8)+:8]= mb0d(state_in[(i*32 + 24)+:8]) ^ mb09(state_in[(i*32 + 16)+:8]) ^ mb0e(state_in[(i*32 + 8)+:8]) ^ mb0b(state_in[i*32+:8]);
       InvMixColumns[i*32+:8]= mb0b(state_in[(i*32 + 24)+:8]) ^ mb0d(state_in[(i*32 + 16)+:8]) ^ mb09(state_in[(i*32 + 8)+:8]) ^ mb0e(state_in[i*32+:8]);
    end
end
endfunction


function[7:0] multiply;
    input [7:0] x;
    input integer n;
    integer i;
begin
	for(i=0;i<n;i=i+1)begin
		if(x[7] == 1) x = ((x << 1) ^ 8'h1b);
		else x = x << 1; 
	end
	multiply=x;
end
endfunction

function [7:0] mb0e;
    input [7:0] x;
begin
	mb0e=multiply(x,3) ^ multiply(x,2)^ multiply(x,1);
end
endfunction

function [7:0] mb0d; 
input [7:0] x;
begin
	mb0d=multiply(x,3) ^ multiply(x,2)^ x;
end
endfunction

function [7:0] mb0b;  
input [7:0] x;
begin
	mb0b=multiply(x,3) ^ multiply(x,1)^ x;
end
endfunction

function [7:0] mb09; //multiply by {09}
input [7:0] x;
begin
	mb09=multiply(x,3) ^  x;
end
endfunction

function [7:0] mb2; //multiply by 2
	input [7:0] x;
	begin 
		if(x[7] == 1) 
		  mb2 = ((x << 1) ^ 8'h1b);
		else mb2 = x << 1; 
	end 	
endfunction

function [7:0] mb3; //multiply by 3
	input [7:0] x;
	begin 
		mb3 = mb2(x) ^ x;
	end 
endfunction

function[0:31] rconx;
input integer r; 
begin
 case(r)
    4'd1: rconx=32'h01000000;
    4'd2: rconx=32'h02000000;
    4'd3: rconx=32'h04000000;
    4'd4: rconx=32'h08000000;
    4'd5: rconx=32'h10000000;
    4'd6: rconx=32'h20000000;
    4'd7: rconx=32'h40000000;
    4'd8: rconx=32'h80000000;
    4'd9: rconx=32'h1b000000;
    4'd10: rconx=32'h36000000;
    default: rconx=32'h00000000;
  endcase
  end
endfunction

function [7:0] SBOX;
    input  [7:0] in; 
    reg [7:0] c;
begin
    case (in)
       8'h00: c=8'h63;
	   8'h01: c=8'h7c;
	   8'h02: c=8'h77;
	   8'h03: c=8'h7b;
	   8'h04: c=8'hf2;
	   8'h05: c=8'h6b;
	   8'h06: c=8'h6f;
	   8'h07: c=8'hc5;
	   8'h08: c=8'h30;
	   8'h09: c=8'h01;
	   8'h0a: c=8'h67;
	   8'h0b: c=8'h2b;
	   8'h0c: c=8'hfe;
	   8'h0d: c=8'hd7;
	   8'h0e: c=8'hab;
	   8'h0f: c=8'h76;
	   8'h10: c=8'hca;
	   8'h11: c=8'h82;
	   8'h12: c=8'hc9;
	   8'h13: c=8'h7d;
	   8'h14: c=8'hfa;
	   8'h15: c=8'h59;
	   8'h16: c=8'h47;
	   8'h17: c=8'hf0;
	   8'h18: c=8'had;
	   8'h19: c=8'hd4;
	   8'h1a: c=8'ha2;
	   8'h1b: c=8'haf;
	   8'h1c: c=8'h9c;
	   8'h1d: c=8'ha4;
	   8'h1e: c=8'h72;
	   8'h1f: c=8'hc0;
	   8'h20: c=8'hb7;
	   8'h21: c=8'hfd;
	   8'h22: c=8'h93;
	   8'h23: c=8'h26;
	   8'h24: c=8'h36;
	   8'h25: c=8'h3f;
	   8'h26: c=8'hf7;
	   8'h27: c=8'hcc;
	   8'h28: c=8'h34;
	   8'h29: c=8'ha5;
	   8'h2a: c=8'he5;
	   8'h2b: c=8'hf1;
	   8'h2c: c=8'h71;
	   8'h2d: c=8'hd8;
	   8'h2e: c=8'h31;
	   8'h2f: c=8'h15;
	   8'h30: c=8'h04;
	   8'h31: c=8'hc7;
	   8'h32: c=8'h23;
	   8'h33: c=8'hc3;
	   8'h34: c=8'h18;
	   8'h35: c=8'h96;
	   8'h36: c=8'h05;
	   8'h37: c=8'h9a;
	   8'h38: c=8'h07;
	   8'h39: c=8'h12;
	   8'h3a: c=8'h80;
	   8'h3b: c=8'he2;
	   8'h3c: c=8'heb;
	   8'h3d: c=8'h27;
	   8'h3e: c=8'hb2;
	   8'h3f: c=8'h75;
	   8'h40: c=8'h09;
	   8'h41: c=8'h83;
	   8'h42: c=8'h2c;
	   8'h43: c=8'h1a;
	   8'h44: c=8'h1b;
	   8'h45: c=8'h6e;
	   8'h46: c=8'h5a;
	   8'h47: c=8'ha0;
	   8'h48: c=8'h52;
	   8'h49: c=8'h3b;
	   8'h4a: c=8'hd6;
	   8'h4b: c=8'hb3;
	   8'h4c: c=8'h29;
	   8'h4d: c=8'he3;
	   8'h4e: c=8'h2f;
	   8'h4f: c=8'h84;
	   8'h50: c=8'h53;
	   8'h51: c=8'hd1;
	   8'h52: c=8'h00;
	   8'h53: c=8'hed;
	   8'h54: c=8'h20;
	   8'h55: c=8'hfc;
	   8'h56: c=8'hb1;
	   8'h57: c=8'h5b;
	   8'h58: c=8'h6a;
	   8'h59: c=8'hcb;
	   8'h5a: c=8'hbe;
	   8'h5b: c=8'h39;
	   8'h5c: c=8'h4a;
	   8'h5d: c=8'h4c;
	   8'h5e: c=8'h58;
	   8'h5f: c=8'hcf;
	   8'h60: c=8'hd0;
	   8'h61: c=8'hef;
	   8'h62: c=8'haa;
	   8'h63: c=8'hfb;
	   8'h64: c=8'h43;
	   8'h65: c=8'h4d;
	   8'h66: c=8'h33;
	   8'h67: c=8'h85;
	   8'h68: c=8'h45;
	   8'h69: c=8'hf9;
	   8'h6a: c=8'h02;
	   8'h6b: c=8'h7f;
	   8'h6c: c=8'h50;
	   8'h6d: c=8'h3c;
	   8'h6e: c=8'h9f;
	   8'h6f: c=8'ha8;
	   8'h70: c=8'h51;
	   8'h71: c=8'ha3;
	   8'h72: c=8'h40;
	   8'h73: c=8'h8f;
	   8'h74: c=8'h92;
	   8'h75: c=8'h9d;
	   8'h76: c=8'h38;
	   8'h77: c=8'hf5;
	   8'h78: c=8'hbc;
	   8'h79: c=8'hb6;
	   8'h7a: c=8'hda;
	   8'h7b: c=8'h21;
	   8'h7c: c=8'h10;
	   8'h7d: c=8'hff;
	   8'h7e: c=8'hf3;
	   8'h7f: c=8'hd2;
	   8'h80: c=8'hcd;
	   8'h81: c=8'h0c;
	   8'h82: c=8'h13;
	   8'h83: c=8'hec;
	   8'h84: c=8'h5f;
	   8'h85: c=8'h97;
	   8'h86: c=8'h44;
	   8'h87: c=8'h17;
	   8'h88: c=8'hc4;
	   8'h89: c=8'ha7;
	   8'h8a: c=8'h7e;
	   8'h8b: c=8'h3d;
	   8'h8c: c=8'h64;
	   8'h8d: c=8'h5d;
	   8'h8e: c=8'h19;
	   8'h8f: c=8'h73;
	   8'h90: c=8'h60;
	   8'h91: c=8'h81;
	   8'h92: c=8'h4f;
	   8'h93: c=8'hdc;
	   8'h94: c=8'h22;
	   8'h95: c=8'h2a;
	   8'h96: c=8'h90;
	   8'h97: c=8'h88;
	   8'h98: c=8'h46;
	   8'h99: c=8'hee;
	   8'h9a: c=8'hb8;
	   8'h9b: c=8'h14;
	   8'h9c: c=8'hde;
	   8'h9d: c=8'h5e;
	   8'h9e: c=8'h0b;
	   8'h9f: c=8'hdb;
	   8'ha0: c=8'he0;
	   8'ha1: c=8'h32;
	   8'ha2: c=8'h3a;
	   8'ha3: c=8'h0a;
	   8'ha4: c=8'h49;
	   8'ha5: c=8'h06;
	   8'ha6: c=8'h24;
	   8'ha7: c=8'h5c;
	   8'ha8: c=8'hc2;
	   8'ha9: c=8'hd3;
	   8'haa: c=8'hac;
	   8'hab: c=8'h62;
	   8'hac: c=8'h91;
	   8'had: c=8'h95;
	   8'hae: c=8'he4;
	   8'haf: c=8'h79;
	   8'hb0: c=8'he7;
	   8'hb1: c=8'hc8;
	   8'hb2: c=8'h37;
	   8'hb3: c=8'h6d;
	   8'hb4: c=8'h8d;
	   8'hb5: c=8'hd5;
	   8'hb6: c=8'h4e;
	   8'hb7: c=8'ha9;
	   8'hb8: c=8'h6c;
	   8'hb9: c=8'h56;
	   8'hba: c=8'hf4;
	   8'hbb: c=8'hea;
	   8'hbc: c=8'h65;
	   8'hbd: c=8'h7a;
	   8'hbe: c=8'hae;
	   8'hbf: c=8'h08;
	   8'hc0: c=8'hba;
	   8'hc1: c=8'h78;
	   8'hc2: c=8'h25;
	   8'hc3: c=8'h2e;
	   8'hc4: c=8'h1c;
	   8'hc5: c=8'ha6;
	   8'hc6: c=8'hb4;
	   8'hc7: c=8'hc6;
	   8'hc8: c=8'he8;
	   8'hc9: c=8'hdd;
	   8'hca: c=8'h74;
	   8'hcb: c=8'h1f;
	   8'hcc: c=8'h4b;
	   8'hcd: c=8'hbd;
	   8'hce: c=8'h8b;
	   8'hcf: c=8'h8a;
	   8'hd0: c=8'h70;
	   8'hd1: c=8'h3e;
	   8'hd2: c=8'hb5;
	   8'hd3: c=8'h66;
	   8'hd4: c=8'h48;
	   8'hd5: c=8'h03;
	   8'hd6: c=8'hf6;
	   8'hd7: c=8'h0e;
	   8'hd8: c=8'h61;
	   8'hd9: c=8'h35;
	   8'hda: c=8'h57;
	   8'hdb: c=8'hb9;
	   8'hdc: c=8'h86;
	   8'hdd: c=8'hc1;
	   8'hde: c=8'h1d;
	   8'hdf: c=8'h9e;
	   8'he0: c=8'he1;
	   8'he1: c=8'hf8;
	   8'he2: c=8'h98;
	   8'he3: c=8'h11;
	   8'he4: c=8'h69;
	   8'he5: c=8'hd9;
	   8'he6: c=8'h8e;
	   8'he7: c=8'h94;
	   8'he8: c=8'h9b;
	   8'he9: c=8'h1e;
	   8'hea: c=8'h87;
	   8'heb: c=8'he9;
	   8'hec: c=8'hce;
	   8'hed: c=8'h55;
	   8'hee: c=8'h28;
	   8'hef: c=8'hdf;
	   8'hf0: c=8'h8c;
	   8'hf1: c=8'ha1;
	   8'hf2: c=8'h89;
	   8'hf3: c=8'h0d;
	   8'hf4: c=8'hbf;
	   8'hf5: c=8'he6;
	   8'hf6: c=8'h42;
	   8'hf7: c=8'h68;
	   8'hf8: c=8'h41;
	   8'hf9: c=8'h99;
	   8'hfa: c=8'h2d;
	   8'hfb: c=8'h0f;
	   8'hfc: c=8'hb0;
	   8'hfd: c=8'h54;
	   8'hfe: c=8'hbb;
	   8'hff: c=8'h16;
	endcase
	SBOX = c;
end
endfunction

function [7:0] InvSBOX;
    input  [7:0] in; 
    reg [7:0] c;
 begin  
    case(in)
				8'h00:c =8'h52;
				8'h01:c =8'h09;
				8'h02:c =8'h6a;
				8'h03:c =8'hd5;
				8'h04:c =8'h30;
				8'h05:c =8'h36;
				8'h06:c =8'ha5;
				8'h07:c =8'h38;
				8'h08:c =8'hbf;
				8'h09:c =8'h40;
				8'h0a:c =8'ha3;
				8'h0b:c =8'h9e;
				8'h0c:c =8'h81;
				8'h0d:c =8'hf3;
				8'h0e:c =8'hd7;
				8'h0f:c =8'hfb;
				8'h10:c =8'h7c;
				8'h11:c =8'he3;
				8'h12:c =8'h39;
				8'h13:c =8'h82;
				8'h14:c =8'h9b;
				8'h15:c =8'h2f;
				8'h16:c =8'hff;
				8'h17:c =8'h87;
				8'h18:c =8'h34;
				8'h19:c =8'h8e;
				8'h1a:c =8'h43;
				8'h1b:c =8'h44;
				8'h1c:c =8'hc4;
				8'h1d:c =8'hde;
				8'h1e:c =8'he9;
				8'h1f:c =8'hcb;
				8'h20:c =8'h54;
				8'h21:c =8'h7b;
				8'h22:c =8'h94;
				8'h23:c =8'h32;
				8'h24:c =8'ha6;
				8'h25:c =8'hc2;
				8'h26:c =8'h23;
				8'h27:c =8'h3d;
				8'h28:c =8'hee;
				8'h29:c =8'h4c;
				8'h2a:c =8'h95;
				8'h2b:c =8'h0b;
				8'h2c:c =8'h42;
				8'h2d:c =8'hfa;
				8'h2e:c =8'hc3;
				8'h2f:c =8'h4e;
				8'h30:c =8'h08;
				8'h31:c =8'h2e;
				8'h32:c =8'ha1;
				8'h33:c =8'h66;
				8'h34:c =8'h28;
				8'h35:c =8'hd9;
				8'h36:c =8'h24;
				8'h37:c =8'hb2;
				8'h38:c =8'h76;
				8'h39:c =8'h5b;
				8'h3a:c =8'ha2;
				8'h3b:c =8'h49;
				8'h3c:c =8'h6d;
				8'h3d:c =8'h8b;
				8'h3e:c =8'hd1;
				8'h3f:c =8'h25;
				8'h40:c =8'h72;
				8'h41:c =8'hf8;
				8'h42:c =8'hf6;
				8'h43:c =8'h64;
				8'h44:c =8'h86;
				8'h45:c =8'h68;
				8'h46:c =8'h98;
				8'h47:c =8'h16;
				8'h48:c =8'hd4;
				8'h49:c =8'ha4;
				8'h4a:c =8'h5c;
				8'h4b:c =8'hcc;
				8'h4c:c =8'h5d;
				8'h4d:c =8'h65;
				8'h4e:c =8'hb6;
				8'h4f:c =8'h92;
				8'h50:c =8'h6c;
				8'h51:c =8'h70;
				8'h52:c =8'h48;
				8'h53:c =8'h50;
				8'h54:c =8'hfd;
				8'h55:c =8'hed;
				8'h56:c =8'hb9;
				8'h57:c =8'hda;
				8'h58:c =8'h5e;
				8'h59:c =8'h15;
				8'h5a:c =8'h46;
				8'h5b:c =8'h57;
				8'h5c:c =8'ha7;
				8'h5d:c =8'h8d;
				8'h5e:c =8'h9d;
				8'h5f:c =8'h84;
				8'h60:c =8'h90;
				8'h61:c =8'hd8;
				8'h62:c =8'hab;
				8'h63:c =8'h00;
				8'h64:c =8'h8c;
				8'h65:c =8'hbc;
				8'h66:c =8'hd3;
				8'h67:c =8'h0a;
				8'h68:c =8'hf7;
				8'h69:c =8'he4;
				8'h6a:c =8'h58;
				8'h6b:c =8'h05;
				8'h6c:c =8'hb8;
				8'h6d:c =8'hb3;
				8'h6e:c =8'h45;
				8'h6f:c =8'h06;
				8'h70:c =8'hd0;
				8'h71:c =8'h2c;
				8'h72:c =8'h1e;
				8'h73:c =8'h8f;
				8'h74:c =8'hca;
				8'h75:c =8'h3f;
				8'h76:c =8'h0f;
				8'h77:c =8'h02;
				8'h78:c =8'hc1;
				8'h79:c =8'haf;
				8'h7a:c =8'hbd;
				8'h7b:c =8'h03;
				8'h7c:c =8'h01;
				8'h7d:c =8'h13;
				8'h7e:c =8'h8a;
				8'h7f:c =8'h6b;
				8'h80:c =8'h3a;
				8'h81:c =8'h91;
				8'h82:c =8'h11;
				8'h83:c =8'h41;
				8'h84:c =8'h4f;
				8'h85:c =8'h67;
				8'h86:c =8'hdc;
				8'h87:c =8'hea;
				8'h88:c =8'h97;
				8'h89:c =8'hf2;
				8'h8a:c =8'hcf;
				8'h8b:c =8'hce;
				8'h8c:c =8'hf0;
				8'h8d:c =8'hb4;
				8'h8e:c =8'he6;
				8'h8f:c =8'h73;
				8'h90:c =8'h96;
				8'h91:c =8'hac;
				8'h92:c =8'h74;
				8'h93:c =8'h22;
				8'h94:c =8'he7;
				8'h95:c =8'had;
				8'h96:c =8'h35;
				8'h97:c =8'h85;
				8'h98:c =8'he2;
				8'h99:c =8'hf9;
				8'h9a:c =8'h37;
				8'h9b:c =8'he8;
				8'h9c:c =8'h1c;
				8'h9d:c =8'h75;
				8'h9e:c =8'hdf;
				8'h9f:c =8'h6e;
				8'ha0:c =8'h47;
				8'ha1:c =8'hf1;
				8'ha2:c =8'h1a;
				8'ha3:c =8'h71;
				8'ha4:c =8'h1d;
				8'ha5:c =8'h29;
				8'ha6:c =8'hc5;
				8'ha7:c =8'h89;
				8'ha8:c =8'h6f;
				8'ha9:c =8'hb7;
				8'haa:c =8'h62;
				8'hab:c =8'h0e;
				8'hac:c =8'haa;
				8'had:c =8'h18;
				8'hae:c =8'hbe;
				8'haf:c =8'h1b;
				8'hb0:c =8'hfc;
				8'hb1:c =8'h56;
				8'hb2:c =8'h3e;
				8'hb3:c =8'h4b;
				8'hb4:c =8'hc6;
				8'hb5:c =8'hd2;
				8'hb6:c =8'h79;
				8'hb7:c =8'h20;
				8'hb8:c =8'h9a;
				8'hb9:c =8'hdb;
				8'hba:c =8'hc0;
				8'hbb:c =8'hfe;
				8'hbc:c =8'h78;
				8'hbd:c =8'hcd;
				8'hbe:c =8'h5a;
				8'hbf:c =8'hf4;
				8'hc0:c =8'h1f;
				8'hc1:c =8'hdd;
				8'hc2:c =8'ha8;
				8'hc3:c =8'h33;
				8'hc4:c =8'h88;
				8'hc5:c =8'h07;
				8'hc6:c =8'hc7;
				8'hc7:c =8'h31;
				8'hc8:c =8'hb1;
				8'hc9:c =8'h12;
				8'hca:c =8'h10;
				8'hcb:c =8'h59;
				8'hcc:c =8'h27;
				8'hcd:c =8'h80;
				8'hce:c =8'hec;
				8'hcf:c =8'h5f;
				8'hd0:c =8'h60;
				8'hd1:c =8'h51;
				8'hd2:c =8'h7f;
				8'hd3:c =8'ha9;
				8'hd4:c =8'h19;
				8'hd5:c =8'hb5;
				8'hd6:c =8'h4a;
				8'hd7:c =8'h0d;
				8'hd8:c =8'h2d;
				8'hd9:c =8'he5;
				8'hda:c =8'h7a;
				8'hdb:c =8'h9f;
				8'hdc:c =8'h93;
				8'hdd:c =8'hc9;
				8'hde:c =8'h9c;
				8'hdf:c =8'hef;
				8'he0:c =8'ha0;
				8'he1:c =8'he0;
				8'he2:c =8'h3b;
				8'he3:c =8'h4d;
				8'he4:c =8'hae;
				8'he5:c =8'h2a;
				8'he6:c =8'hf5;
				8'he7:c =8'hb0;
				8'he8:c =8'hc8;
				8'he9:c =8'heb;
				8'hea:c =8'hbb;
				8'heb:c =8'h3c;
				8'hec:c =8'h83;
				8'hed:c =8'h53;
				8'hee:c =8'h99;
				8'hef:c =8'h61;
				8'hf0:c =8'h17;
				8'hf1:c =8'h2b;
				8'hf2:c =8'h04;
				8'hf3:c =8'h7e;
				8'hf4:c =8'hba;
				8'hf5:c =8'h77;
				8'hf6:c =8'hd6;
				8'hf7:c =8'h26;
				8'hf8:c =8'he1;
				8'hf9:c =8'h69;
				8'hfa:c =8'h14;
				8'hfb:c =8'h63;
				8'hfc:c =8'h55;
				8'hfd:c =8'h21;
				8'hfe:c =8'h0c;
				8'hff:c =8'h7d;
				endcase
    InvSBOX=c;
end
endfunction

endmodule