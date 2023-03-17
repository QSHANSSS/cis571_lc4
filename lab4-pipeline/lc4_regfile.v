
/* TODO: Names of all group members
 * TODO: PennKeys of all group members
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );
    wire [7:0] rd_select;
    wire [n-1:0] r0v, r1v, r2v, r3v,r4v, r5v, r6v, r7v;

    decoder_3_to_8 m0(i_rd,rd_select);
    Nbit_reg #(n) r0 (i_wdata , r0v, clk,  rd_select[0] & i_rd_we, gwe,rst);
    Nbit_reg #(n) r1 (i_wdata , r1v, clk,  rd_select[1] & i_rd_we, gwe,rst);
    Nbit_reg #(n) r2 (i_wdata,  r2v, clk,  rd_select[2] & i_rd_we, gwe,rst);
    Nbit_reg #(n) r3 (i_wdata,  r3v, clk,  rd_select[3] & i_rd_we, gwe,rst);
    Nbit_reg #(n) r4 (i_wdata,  r4v, clk,  rd_select[4] & i_rd_we, gwe,rst);
    Nbit_reg #(n) r5 (i_wdata,  r5v, clk,  rd_select[5] & i_rd_we, gwe,rst);
    Nbit_reg #(n) r6 (i_wdata,  r6v, clk,  rd_select[6] & i_rd_we, gwe,rst);
    Nbit_reg #(n) r7 (i_wdata,  r7v,  clk, rd_select[7] & i_rd_we, gwe,rst);
    MUX81  m1(r0v, r1v, r2v, r3v,r4v, r5v, r6v, r7v,i_rs,o_rs_data);
    MUX81  m2(r0v, r1v, r2v, r3v,r4v, r5v, r6v, r7v,i_rt,o_rt_data);
    
endmodule


module decoder_3_to_8 (binary_in, onehot_out);
    input wire [2:0] binary_in; 
    output wire [7:0] onehot_out;
        assign onehot_out[0] = (binary_in == 3'd0);
        assign onehot_out[1] = (binary_in == 3'd1);
        assign onehot_out[2] = (binary_in == 3'd2);
        assign onehot_out[3] = (binary_in == 3'd3);
        assign onehot_out[4] = (binary_in == 3'd4);
        assign onehot_out[5] = (binary_in == 3'd5);
        assign onehot_out[6] = (binary_in == 3'd6);
        assign onehot_out[7] = (binary_in == 3'd7);
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