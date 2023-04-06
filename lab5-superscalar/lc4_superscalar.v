`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

   /***  YOUR CODE HERE ***/

   wire [1:0] stall_A;
   wire [1:0] stall_B;
/**********************************************FETCH STAGE**********************************************/   

   // Dispatch (Fetch/Decode)
   wire [15:0] F_pc_reg_out;
   wire [15:0] F_pc_A = (stall_B == 2'h1) ? D_IR_pc_B : F_pc_reg_out; // if B is stalled 
   wire [15:0] F_pc_B = F_pc_A + 16'h1; //PC of B will always be PC of A+1
   wire [15:0] F_next_pc = F_pc_A + 16'h2; //increment pc by 1 if only B stalls, else increment by 2

   wire F_we = 1'b1;

   Nbit_reg #(16, 16'h8200) pc_reg (.in(F_next_pc), .out(F_pc_reg_out), .clk(clk), .we(F_we), .gwe(gwe), .rst(rst)); //pc register

   wire [15:0] F_insn_A =  i_cur_insn_A;
   wire [15:0] F_insn_B =  i_cur_insn_B;

   assign o_cur_pc = F_pc_A;

/****Fetch-Decode Intermediate Register****/

    //FD_reg A output wires
    wire [15:0] D_IR_pc_A;
    wire [15:0] D_IR_insn_A;
    wire [1:0] D_IR_stall_A;
    //FD_reg A registers
    Nbit_reg #(16, 16'h0) FD_pc_A (.in(F_pc_A), .out(D_IR_pc_A), .clk(clk), .we(F_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) FD_insn_A (.in(F_insn_A), .out(D_IR_insn_A), .clk(clk), .we(F_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'h2) FD_stall_A (.in(2'h0), .out(D_IR_stall_A), .clk(clk), .we(F_we), .gwe(gwe), .rst(rst));


    //FD_reg B output wires
    wire [15:0] D_IR_pc_B;
    wire [15:0] D_IR_insn_B;
    wire [1:0] D_IR_stall_B;
    //FD_reg B registers
    Nbit_reg #(16, 16'h0) FD_pc_B (.in(F_pc_B), .out(D_IR_pc_B), .clk(clk), .we(F_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) FD_insn_B (.in(F_insn_B), .out(D_IR_insn_B), .clk(clk), .we(F_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'h2) FD_stall_B (.in(2'h0), .out(D_IR_stall_B), .clk(clk), .we(F_we), .gwe(gwe), .rst(rst));


