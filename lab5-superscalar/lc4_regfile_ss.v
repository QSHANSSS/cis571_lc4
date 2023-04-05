`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter REG_WIDTH = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [REG_WIDTH-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [REG_WIDTH-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [REG_WIDTH-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [REG_WIDTH-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [REG_WIDTH-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [REG_WIDTH-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   
   parameter REG_NUM=8;
   /*** TODO: Your Code Here ***/
   wire [REG_WIDTH-1:0] rd_write_data[REG_NUM];
   //wire [7:0] rd_select_A.rd_select_B;
   wire [REG_WIDTH-1:0] r0v, r1v, r2v, r3v,r4v, r5v, r6v, r7v,o_rs_data_A_temp,o_rs_data_B_temp,o_rt_data_A_temp,o_rt_data_B_temp;
   wire i_rd_we[REG_NUM] ;

   //decoder_3_to_8 m0(i_rd_A,rd_select_A);
   //decoder_3_to_8 m1(i_rd_B,rd_select_B);
   
   //for(genvar i=0;i<REG_NUM;i=i+1)begin
   assign rd_write_data[0]=(i_rd_B==3'b000 & i_rd_we_B )?i_wdata_B : (i_rd_A==3'b000 & i_rd_we_A)? i_wdata_A : 3'b000 ; 
   assign rd_write_data[1]=(i_rd_B==3'b001 & i_rd_we_B )?i_wdata_B : (i_rd_A==3'b001 & i_rd_we_A)? i_wdata_A : 3'b001 ; 
   assign rd_write_data[2]=(i_rd_B==3'b010 & i_rd_we_B )?i_wdata_B : (i_rd_A==3'b010 & i_rd_we_A)? i_wdata_A : 3'b010 ; 
   assign rd_write_data[3]=(i_rd_B==3'b011 & i_rd_we_B )?i_wdata_B : (i_rd_A==3'b011 & i_rd_we_A)? i_wdata_A : 3'b011 ; 
   assign rd_write_data[4]=(i_rd_B==3'b100 & i_rd_we_B )?i_wdata_B : (i_rd_A==3'b100 & i_rd_we_A)? i_wdata_A : 3'b100 ; 
   assign rd_write_data[5]=(i_rd_B==3'b101 & i_rd_we_B )?i_wdata_B : (i_rd_A==3'b101 & i_rd_we_A)? i_wdata_A : 3'b101 ; 
   assign rd_write_data[6]=(i_rd_B==3'b110 & i_rd_we_B )?i_wdata_B : (i_rd_A==3'b110 & i_rd_we_A)? i_wdata_A : 3'b110 ; 
   assign rd_write_data[7]=(i_rd_B==3'b111 & i_rd_we_B )?i_wdata_B : (i_rd_A==3'b111 & i_rd_we_A)? i_wdata_A : 3'b111 ; 
   
   assign i_rd_we[0]= (i_rd_B==3'b000 & i_rd_we_B ) | (i_rd_A==3'b000 & i_rd_we_A);
   assign i_rd_we[1]= (i_rd_B==3'b001 & i_rd_we_B ) | (i_rd_A==3'b001 & i_rd_we_A);
   assign i_rd_we[2]= (i_rd_B==3'b010 & i_rd_we_B ) | (i_rd_A==3'b010 & i_rd_we_A);
   assign i_rd_we[3]= (i_rd_B==3'b011 & i_rd_we_B ) | (i_rd_A==3'b011 & i_rd_we_A);
   assign i_rd_we[4]= (i_rd_B==3'b100 & i_rd_we_B ) | (i_rd_A==3'b100 & i_rd_we_A);
   assign i_rd_we[5]= (i_rd_B==3'b101 & i_rd_we_B ) | (i_rd_A==3'b101 & i_rd_we_A); 
   assign i_rd_we[6]= (i_rd_B==3'b110 & i_rd_we_B ) | (i_rd_A==3'b110 & i_rd_we_A); 
   assign i_rd_we[7]= (i_rd_B==3'b111 & i_rd_we_B ) | (i_rd_A==3'b111 & i_rd_we_A);
  

   Nbit_reg #(REG_WIDTH) r0 (rd_write_data[0] , r0v, clk,  i_rd_we[0], gwe,rst);
   Nbit_reg #(REG_WIDTH) r1 (rd_write_data[1] , r1v, clk,  i_rd_we[1], gwe,rst);
   Nbit_reg #(REG_WIDTH) r2 (rd_write_data[2] , r2v, clk,  i_rd_we[2], gwe,rst);
   Nbit_reg #(REG_WIDTH) r3 (rd_write_data[3],  r3v, clk,  i_rd_we[3], gwe,rst);
   Nbit_reg #(REG_WIDTH) r4 (rd_write_data[4],  r4v, clk,  i_rd_we[4], gwe,rst);
   Nbit_reg #(REG_WIDTH) r5 (rd_write_data[5],  r5v, clk,  i_rd_we[5], gwe,rst);
   Nbit_reg #(REG_WIDTH) r6 (rd_write_data[6],  r6v, clk,  i_rd_we[6], gwe,rst);
   Nbit_reg #(REG_WIDTH) r7 (rd_write_data[7],  r7v, clk,  i_rd_we[7], gwe,rst);

   MUX81  m2(r0v, r1v, r2v, r3v,r4v, r5v, r6v, r7v,i_rs_A,o_rs_data_A_temp);
   MUX81  m3(r0v, r1v, r2v, r3v,r4v, r5v, r6v, r7v,i_rt_A,o_rt_data_A_temp);
   MUX81  m4(r0v, r1v, r2v, r3v,r4v, r5v, r6v, r7v,i_rs_B,o_rs_data_B_temp);
   MUX81  m5(r0v, r1v, r2v, r3v,r4v, r5v, r6v, r7v,i_rt_B,o_rt_data_B_temp);

   assign o_rs_data_A=(i_rd_B==i_rs_A & i_rd_we_B) ? i_wdata_B : (i_rd_A==i_rs_A & i_rd_we_A) ? i_wdata_A : o_rs_data_A_temp;
   assign o_rs_data_B=(i_rd_B==i_rs_B & i_rd_we_B) ? i_wdata_B : (i_rd_A==i_rs_B & i_rd_we_A) ? i_wdata_A : o_rs_data_B_temp;
   assign o_rt_data_A=(i_rd_B==i_rt_A & i_rd_we_B) ? i_wdata_B : (i_rd_A==i_rt_A & i_rd_we_A) ? i_wdata_A : o_rt_data_A_temp;
   assign o_rt_data_B=(i_rd_B==i_rt_B & i_rd_we_B) ? i_wdata_B : (i_rd_A==i_rt_B & i_rd_we_A) ? i_wdata_A : o_rt_data_B_temp;

endmodule


module MUX81
(
	input wire [15:0]	a,b,c,d,e,f,g,h,
	input wire [2:0]	sel,
	output  wire [15:0]	out
);
    wire [15:0] out0,out1,out2,out3,out4,out5,out6,out7;

	assign out0=(sel==3'b000)? a: 0;
    assign out1=(sel==3'b001)? b: 0;
    assign out2=(sel==3'b010)? c: 0;
    assign out3=(sel==3'b011)? d: 0;
    assign out4=(sel==3'b100)? e: 0;
    assign out5=(sel==3'b101)? f: 0;
    assign out6=(sel==3'b110)? g: 0;
    assign out7=(sel==3'b111)? h: 0;

    assign out=out0 | out1| out0 | out2| out3 | out4| out5 | out6| out7 ; 



endmodule
