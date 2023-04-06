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


/**********************************************DECODE STAGE**********************************************/

/****Stall Logic****/
    wire [2:0] D_stall_r1_A;
    wire [2:0] D_stall_r2_A;
    wire [2:0] D_stall_rd_A;
    wire D_stall_r1re_A;
    wire D_stall_r2re_A;
    wire D_stall_is_store_A;
    wire D_stall_is_branch_A;
    wire D_stall_regfile_we_A;


    wire [2:0] D_stall_r1_B;
    wire [2:0] D_stall_r2_B;
    wire [2:0] D_stall_rd_B;
    wire D_stall_r1re_B;
    wire D_stall_r2re_B;
    wire D_stall_is_store_B;
    wire D_stall_is_branch_B;
    wire D_stall_regfile_we_B;

    //Use parallel decoder to detect stalls because other decoder will be flushed with NOP when a stall is needed. Can't decode stall logic and flush the same decoder in 1 cycle
    lc4_decoder stall_decoder_A(.insn(D_IR_insn_A), .r1sel(D_stall_r1_A), .r1re(D_stall_r1re_A), .r2sel(D_stall_r2_A), .r2re(D_stall_r2re_A), .wsel(D_stall_rd_A), 
    .regfile_we(D_stall_regfile_we_A), .nzp_we(), .select_pc_plus_one(), .is_load(), .is_store(D_stall_is_store_A), .is_branch(D_stall_is_branch_A), .is_control_insn());

    lc4_decoder stall_decoder_B(.insn(D_IR_insn_B), .r1sel(D_stall_r1_B), .r1re(D_stall_r1re_B), .r2sel(D_stall_r2_B), .r2re(D_stall_r2re_B), .wsel(D_stall_rd_B),
    .regfile_we(D_stall_regfile_we_B), .nzp_we(), .select_pc_plus_one(), .is_load(), .is_store(D_stall_is_store_B), .is_branch(D_stall_is_branch_B), .is_control_insn());

    //ONLY SUPPORTS SUPERSCALAR STALL (EXCLUDING MEMORY)
    assign stall_A = 2'h0;
    assign stall_B =    (   ((D_stall_rd_A == D_stall_r1_B) & D_stall_r1re_B)       | 
                            ((D_stall_rd_A == D_stall_r2_B) & D_stall_r2re_B)   )   &
                            D_stall_regfile_we_A ? 2'h1 : 2'h0; // check the dependencies between A and B

    wire [1:0] D_stall_A = D_IR_stall_A;
    wire [1:0] D_stall_B = (stall_B != 3'h0) ? stall_B : D_IR_stall_B;

    //decoder A outputs
    wire [2:0] D_r1_A;
    wire [2:0] D_r2_A;
    wire [2:0] D_rd_A;
    wire D_r1re_A;
    wire D_r2re_A;
    wire D_select_pc_plus_one_A;
    wire D_is_load_A;
    wire D_is_store_A;
    wire D_is_branch_A;
    wire D_is_control_insn_A;
    wire D_regfile_we_A;
    wire D_nzp_we_A;

    //decoder B outputs
    wire [2:0] D_r1_B;
    wire [2:0] D_r2_B;
    wire [2:0] D_rd_B;
    wire D_r1re_B;
    wire D_r2re_B;
    wire D_select_pc_plus_one_B;
    wire D_is_load_B;
    wire D_is_store_B;
    wire D_is_branch_B;
    wire D_is_control_insn_B;
    wire D_regfile_we_B;
    wire D_nzp_we_B;

    wire [15:0] D_insn_A = D_IR_insn_A; //change to support load-to-use stall and flush on branch
    wire [15:0] D_insn_B = (stall_B == 2'h1) ? 16'h0 : D_IR_insn_B; //change to support load-to-use stall and flush on branch

    //decoder A
    lc4_decoder decoder_A (.insn(D_insn_A), .r1sel(D_r1_A), .r1re(D_r1re_A), .r2sel(D_r2_A), .r2re(D_r2re_A), .wsel(D_rd_A), .regfile_we(D_regfile_we_A), .nzp_we(D_nzp_we_A), .select_pc_plus_one(D_select_pc_plus_one_A),
                            .is_load(D_is_load_A), .is_store(D_is_store_A), .is_branch(D_is_branch_A), .is_control_insn(D_is_control_insn_A));

    //decoder B
    lc4_decoder decoder_B (.insn(D_insn_B), .r1sel(D_r1_B), .r1re(D_r1re_B), .r2sel(D_r2_B), .r2re(D_r2re_B), .wsel(D_rd_B), .regfile_we(D_regfile_we_B), .nzp_we(D_nzp_we_B), .select_pc_plus_one(D_select_pc_plus_one_B),
                            .is_load(D_is_load_B), .is_store(D_is_store_B), .is_branch(D_is_branch_B), .is_control_insn(D_is_control_insn_B));

    wire [15:0] D_r1_data_A, D_r2_data_A, D_r1_data_B, D_r2_data_B; //regfile output wires
    lc4_regfile_ss regfile(.i_rs_A(D_r1_A), .i_rt_A(D_r2_A), .i_rd_A(W_IR_rd_A), .i_rd_we_A(W_IR_regfile_we_A), .i_wdata_A(W_rd_data_A), .o_rs_data_A(D_r1_data_A), .o_rt_data_A(D_r2_data_A),
                            .i_rs_B(D_r1_B), .i_rt_B(D_r2_B), .i_rd_B(W_IR_rd_B), .i_rd_we_B(W_IR_regfile_we_B), .i_wdata_B(W_rd_data_B), .o_rs_data_B(D_r1_data_B), .o_rt_data_B(D_r2_data_B),
                            .clk(clk) , .gwe(gwe), .rst(rst)); //2-pipe regfile

/****Decode-Execute Intermediate Register****/

    //DX_reg A output wires
    wire [15:0] X_IR_r1_data_A;
    wire [15:0] X_IR_r2_data_A;
    wire [2:0] X_IR_r1_A;
    wire [2:0] X_IR_r2_A;
    wire [2:0] X_IR_rd_A;
    wire X_IR_r1re_A;
    wire X_IR_r2re_A;
    wire X_IR_select_pc_plus_one_A;
    wire X_IR_is_load_A;
    wire X_IR_is_store_A;
    wire X_IR_is_branch_A;
    wire X_IR_is_control_insn_A;
    wire X_IR_regfile_we_A;
    wire X_IR_nzp_we_A;
    wire [1:0] X_IR_stall_A;
    //End new outputs
    wire [15:0] X_IR_pc_A;
    wire [15:0] X_IR_insn_A;

    //DX_reg B output wires
    wire [15:0] X_IR_r1_data_B;
    wire [15:0] X_IR_r2_data_B;
    wire [2:0] X_IR_r1_B;
    wire [2:0] X_IR_r2_B;
    wire [2:0] X_IR_rd_B;
    wire X_IR_r1re_B;
    wire X_IR_r2re_B;
    wire X_IR_select_pc_plus_one_B;
    wire X_IR_is_load_B;
    wire X_IR_is_store_B;
    wire X_IR_is_branch_B;
    wire X_IR_is_control_insn_B;
    wire X_IR_regfile_we_B;
    wire X_IR_nzp_we_B;
    wire [1:0] X_IR_stall_B;
    //End new outputs
    wire [15:0] X_IR_pc_B;
    wire [15:0] X_IR_insn_B;

    //DX_reg A registers
    Nbit_reg #(16, 16'h0) DX_r1_data_A (.in(D_r1_data_A), .out(X_IR_r1_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) DX_r2_data_A (.in(D_r2_data_A), .out(X_IR_r2_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) DX_r1_A (.in(D_r1_A), .out(X_IR_r1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) DX_r2_A (.in(D_r2_A), .out(X_IR_r2_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) DX_rd_A (.in(D_rd_A), .out(X_IR_rd_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_r1re_A (.in(D_r1re_A), .out(X_IR_r1re_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_r2re_A (.in(D_r2re_A), .out(X_IR_r2re_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_select_pc_plus_one_A (.in(D_select_pc_plus_one_A), .out(X_IR_select_pc_plus_one_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_is_load_A (.in(D_is_load_A), .out(X_IR_is_load_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_is_store_A (.in(D_is_store_A), .out(X_IR_is_store_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_is_branch_A (.in(D_is_branch_A), .out(X_IR_is_branch_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_is_control_insn_A (.in(D_is_control_insn_A), .out(X_IR_is_control_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_regfile_we_A (.in(D_regfile_we_A), .out(X_IR_regfile_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_nzp_we_A (.in(D_nzp_we_A), .out(X_IR_nzp_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    //End new registers
    Nbit_reg #(16, 16'h0) DX_pc_A (.in(D_IR_pc_A), .out(X_IR_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) DX_insn_A (.in(D_insn_A), .out(X_IR_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'h2) DX_stall_A (.in(D_stall_A), .out(X_IR_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    //DX_reg B registers
    Nbit_reg #(16, 16'h0) DX_r1_data_B (.in(D_r1_data_B), .out(X_IR_r1_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) DX_r2_data_B (.in(D_r2_data_B), .out(X_IR_r2_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) DX_r1_B (.in(D_r1_B), .out(X_IR_r1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) DX_r2_B (.in(D_r2_B), .out(X_IR_r2_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0) DX_rd_B (.in(D_rd_B), .out(X_IR_rd_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_r1re_B (.in(D_r1re_B), .out(X_IR_r1re_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_r2re_B (.in(D_r2re_B), .out(X_IR_r2re_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_select_pc_plus_one_B (.in(D_select_pc_plus_one_B), .out(X_IR_select_pc_plus_one_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_is_load_B (.in(D_is_load_B), .out(X_IR_is_load_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_is_store_B (.in(D_is_store_B), .out(X_IR_is_store_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_is_branch_B (.in(D_is_branch_B), .out(X_IR_is_branch_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_is_control_insn_B (.in(D_is_control_insn_B), .out(X_IR_is_control_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_regfile_we_B (.in(D_regfile_we_B), .out(X_IR_regfile_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 1'h0) DX_nzp_we_B (.in(D_nzp_we_B), .out(X_IR_nzp_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    //End new registers
    Nbit_reg #(16, 16'h0) DX_pc_B (.in(D_IR_pc_B), .out(X_IR_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h0) DX_insn_B (.in(D_insn_B), .out(X_IR_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'h2) DX_stall_B (.in(D_stall_B), .out(X_IR_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));