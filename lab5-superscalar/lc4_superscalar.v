
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
   
   assign led_data = switch_data;

   //brach misprediction
   
   wire [2:0] nzp_mispredict;
   Nbit_reg #(3, 3'b010) nzp_reg (.in((nzp_we_w_reg_B)?nzp_data_B:nzp_data_A), .out(last_nzp), .clk(clk), .we(nzp_we_w_reg_B | nzp_we_w_reg_A), .gwe(gwe), .rst(rst));
   
   wire br_taken_A,br_taken_B;
   assign nzp_mispredict=(nzp_we_m_reg_B)?  nzp_data_m_B : (nzp_we_m_reg_A)? nzp_data_m_A 
                        : (nzp_we_w_reg_B)? nzp_data_w_B:(nzp_we_w_reg_A)? nzp_data_w_A
                        : last_nzp ;
   assign br_taken_A=(nzp_mispredict[2]&insn_x_A[11]) | (nzp_mispredict[1]&insn_x_A[10]) | (nzp_mispredict[0]&insn_x_A[9]);
   assign br_taken_B=(nzp_mispredict[2]&insn_x_B[11]) | (nzp_mispredict[1]&insn_x_B[10]) | (nzp_mispredict[0]&insn_x_B[9]);

   wire br_is_jump_A,br_is_jump_B;
   assign br_is_jump_A=((is_branch_x_reg_A & br_taken_A ) | is_control_insn_x_reg_A );
   assign br_is_jump_B=((is_branch_x_reg_B & br_taken_B ) | is_control_insn_x_reg_B );
   

   //load-to-use-stall
   wire load_use_stall_A,load_use_stall_B,load_use_stall_A_rs,load_use_stall_A_rt;
   wire rs_XA_DA = ( r1re_d_reg_A && (rs_sel_d_A == rd_sel_x_A)   && regfile_we_x_reg_A);
   wire rs_XB_DA = ( r1re_d_reg_A && (rs_sel_d_A == rd_sel_x_B) && regfile_we_x_reg_B);
   wire rs_XA_DB = ( r1re_d_reg_B && (rs_sel_d_B == rd_sel_x_A)   && regfile_we_x_reg_A);
   wire rs_XB_DB = ( r1re_d_reg_B && (rs_sel_d_B == rd_sel_x_B) && regfile_we_x_reg_B);

   wire rt_XA_DA = ( r2re_d_reg_A && (rt_sel_d_A == rd_sel_x_A) && regfile_we_x_reg_A) && !is_store_d_reg_A;
   wire rt_XB_DA = ( r2re_d_reg_A && (rt_sel_d_A == rd_sel_x_B) && regfile_we_x_reg_B) && !is_store_d_reg_A;
   wire rt_XA_DB = ( r2re_d_reg_B && (rt_sel_d_B == rd_sel_x_A) && regfile_we_x_reg_A) && !is_store_d_reg_B;
   wire rt_XB_DB = ( r2re_d_reg_B && (rt_sel_d_B == rd_sel_x_B) && regfile_we_x_reg_B) && !is_store_d_reg_B;
   
   wire rs_XB_DB_taken = regfile_we_x_reg_B && rd_sel_x_B == rs_sel_d_B && r1re_d_reg_B;
   wire rt_XB_DB_taken = regfile_we_x_reg_B && rd_sel_x_B == rt_sel_d_B && r2re_d_reg_B;
   wire rs_XB_DA_taken = regfile_we_x_reg_B && rd_sel_x_B == rs_sel_d_A && r1re_d_reg_A;
   wire rt_XB_DA_taken = regfile_we_x_reg_B && rd_sel_x_B == rt_sel_d_A && r2re_d_reg_A;
    
   // is_load_to_use_only_A
   wire rs_XA_DA_load_to_use = is_load_x_reg_A && rs_XA_DA && !rs_XB_DA_taken;
   wire rt_XA_DA_load_to_use = is_load_x_reg_A && rt_XA_DA && !rt_XB_DA_taken;
   wire nzp_XA_DA_load_to_use = is_load_x_reg_A && is_branch_d_reg_A && ! nzp_we_x_reg_B;
   wire ltu_only_A = rs_XA_DA_load_to_use || rt_XA_DA_load_to_use || nzp_XA_DA_load_to_use;

   // is_load_to_use_XA_DB
   wire rs_XA_DB_load_to_use = is_load_x_reg_A && rs_XA_DB && ! rs_XB_DB_taken;
   wire rt_XA_DB_load_to_use = is_load_x_reg_A && rt_XA_DB && ! rt_XB_DB_taken;
   wire nzp_XA_DB_load_to_use = is_load_x_reg_A && is_branch_d_reg_B && ! nzp_we_d_reg_A && ! nzp_we_x_reg_B;
   wire ltu_XA_DB = rs_XA_DB_load_to_use || rt_XA_DB_load_to_use || nzp_XA_DB_load_to_use;

   // is_load_to_use_XB_DA
   wire rs_XB_DA_load_to_use = is_load_x_reg_B && rs_XB_DA;
   wire rt_XB_DA_load_to_use = is_load_x_reg_B && rt_XB_DA;
   wire nzp_XB_DA_load_to_use = is_load_x_reg_B && is_branch_d_reg_A;
   wire ltu_XB_DA = rs_XB_DA_load_to_use || rt_XB_DA_load_to_use || nzp_XB_DA_load_to_use;

    // is_only_load_to_use_B
   wire rs_XB_DB_load_to_use = is_load_x_reg_B && rs_XB_DB;
   wire rt_XB_DB_load_to_use = is_load_x_reg_B && rt_XB_DB;
   wire nzp_XB_DB_load_to_use = is_load_x_reg_B && is_branch_d_reg_B;
   wire ltu_only_B= rs_XB_DB_load_to_use || rt_XB_DB_load_to_use || nzp_XB_DB_load_to_use && !nzp_we_d_reg_A;

  
   assign load_use_stall_A=  is_load_x_reg_A  && (( (rs_sel_d_A == rd_sel_x_A) && r1re_d_reg_A ) || ((( rt_sel_d_A == rd_sel_x_A) && r2re_d_reg_A ) && (!is_store_d_reg_A)) | is_branch_d_reg_B);
   assign load_use_stall_B= is_load_x_reg_B  && (( (rs_sel_d_B == rd_sel_x_B) && r1re_d_reg_B ) || ((( rt_sel_d_B == rd_sel_x_B) && r2re_d_reg_B ) && (!is_store_d_reg_B)) | is_branch_d_reg_B);
  
   
   //stall reg
   wire [1:0] stall_f_A,stall_d_A,stall_d_temp_A,stall_x_A,stall_m_A,stall_w_A;
   wire [1:0] stall_f_B,stall_d_B,stall_d_temp_B,stall_x_B,stall_m_B,stall_w_B;   
   //nop/flush control signal
   assign stall_f_A=(br_is_jump_A | br_is_jump_B)?2'd2 : 2'b0;
   assign stall_d_temp_A=(br_is_jump_A | br_is_jump_B)? 2'd2 
                        : stall_A? stall_A
                        :  stall_d_A;

   Nbit_reg #(2, 2'b0) stall_reg_d (.in( stall_f_A), .out(stall_d_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) stall_reg_x (.in( stall_d_temp_A), .out(stall_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) stall_reg_m (.in( stall_x_A), .out(stall_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) stall_reg_w (.in( stall_m_A), .out(stall_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   

   assign stall_f_B=(br_is_jump_A | br_is_jump_B)?2'd2 : 2'b0;
   assign stall_d_temp_B= (br_is_jump_A | br_is_jump_B)? 2'd2 
                           : (stall_B)? stall_B
                           : stall_d_B ;
   wire [2:0] stall_x_B_temp;
   assign stall_x_B_temp=(br_is_jump_A)?2'd2:stall_x_B;
   Nbit_reg #(2, 2'b0) stall_reg_d_B (.in( stall_f_B), .out(stall_d_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) stall_reg_x_B (.in( stall_d_temp_B), .out(stall_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) stall_reg_m_B (.in( stall_x_B_temp), .out(stall_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) stall_reg_w_B (.in( stall_m_B), .out(stall_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //superscalar stall
   wire is_superscalar_stall;
   wire is_superscalar_stall_rs = r1re_d_reg_B & regfile_we_d_reg_A & (rs_sel_d_B == rd_sel_d_A); 
   wire is_superscalar_stall_rt = r2re_d_reg_B & regfile_we_d_reg_A & (rt_sel_d_B == rd_sel_d_A) & !is_store_d_reg_B; 
   wire is_superscalar_stall_branch = is_branch_d_reg_B && nzp_we_d_reg_A;
   wire is_superscalar_stall_both_mem=(is_load_d_reg_A|is_store_d_reg_A) && (is_load_d_reg_B|is_store_d_reg_B);
   assign is_superscalar_stall=is_superscalar_stall_branch | is_superscalar_stall_rs | is_superscalar_stall_rt | is_superscalar_stall_both_mem;
   
   //Stall for PIPE-A and PIPE-B
   wire [2:0]stall_A,stall_B;
   wire stall_B_only;
   assign stall_A= (ltu_only_A | ltu_XB_DA) ? 2'b11
                  :( br_is_jump_A | br_is_jump_B)? 2'b10 
                  : 2'b00;
   assign stall_B= ( stall_A== 2'b11 | is_superscalar_stall ) ? 2'd1
                  : (ltu_only_B | ltu_XA_DB) ? 2'd3 
                  : br_is_jump_A | br_is_jump_B ? 2'd2 
                  : 2'd0;
   assign stall_B_only= stall_B & !stall_A;

   //pc reg
   wire [15:0]   pc,next_pc;      // Current program counter (read out from pc_reg)
   wire [15:0]  pc_d_A,pc_d_B,pc_temp_A,pc_temp_B,pc_x_A,pc_x_B,pc_m_A,pc_m_B,pc_w_A,pc_w_B;

   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   assign next_pc= (br_is_jump_A)? out_alu_A
                  :(br_is_jump_B)? out_alu_B
                  : stall_A ? pc
                  : stall_B_only ? pc_plus_one
                  : pc_plus_two;
   
   assign o_cur_pc=pc;

   wire pipe_switch=load_use_stall_B | is_superscalar_stall; // pipeB needs data from pipeA in same stage
   assign pc_temp_A= stall_B_only? pc_d_B : pc;
   assign pc_temp_B= stall_B_only? pc : pc_plus_one;

   Nbit_reg #(16, 16'h0000) pc_reg_d (.in(pc_temp_A), .out(pc_d_A), .clk(clk), .we(!stall_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_x (.in(pc_d_A), .out(pc_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_m (.in(pc_x_A), .out(pc_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_w (.in(pc_m_A), .out(pc_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(16, 16'h0000) pc_reg_d_B (.in(pc_temp_B), .out(pc_d_B), .clk(clk), .we(!stall_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_x_B (.in(pc_d_B), .out(pc_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_m_B (.in(pc_x_B), .out(pc_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_w_B (.in(pc_m_B), .out(pc_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //insn reg
   wire [15:0] insn_f_A,insn_d_A,insn_x_A,insn_m_A,insn_w_A,insn_d_temp_A;
   wire [15:0] insn_f_B,insn_d_B,insn_x_B,insn_m_B,insn_w_B,insn_d_temp_B;
   assign insn_f_A= (br_is_jump_A | br_is_jump_B)?16'b0 
                     : stall_B_only ? insn_d_B 
                     : i_cur_insn_A;
   assign insn_f_B= (br_is_jump_B | br_is_jump_A)?16'b0 
                     : stall_B_only? i_cur_insn_A
                     : i_cur_insn_B;

   assign insn_d_temp_A= (stall_A)?16'b0 : insn_d_A;                     
   assign insn_d_temp_B= (stall_B)?16'b0 : insn_d_B;               
   wire we_f_insn=br_is_jump_A | br_is_jump_B | stall_A==0 ;

   Nbit_reg #(16, 16'b0) insn_reg_d (.in(insn_f_A), .out(insn_d_A), .clk(clk), .we(we_f_insn), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_x (.in(insn_d_temp_A), .out(insn_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_m (.in(insn_x_A), .out(insn_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_w (.in(insn_m_A), .out(insn_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire[15:0] insn_x_B_temp;
   assign insn_x_B_temp=(br_is_jump_A)?16'b0:insn_x_B;
   Nbit_reg #(16, 16'b0) insn_reg_d_B (.in(insn_f_B), .out(insn_d_B), .clk(clk), .we(we_f_insn), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_x_B (.in(insn_d_temp_B), .out(insn_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_m_B (.in(insn_x_B_temp), .out(insn_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_w_B (.in(insn_m_B), .out(insn_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //rd_sel_reg
   wire [2:0] rd_sel_d_A,rd_sel_x_A,rd_sel_m_A,rd_sel_w_A,rd_sel_d_A_temp;
   wire [2:0] rd_sel_d_B,rd_sel_x_B,rd_sel_m_B,rd_sel_w_B,rd_sel_d_B_temp;
   assign rd_sel_d_A_temp=stall_A? 0: rd_sel_d_A;
   assign rd_sel_d_B_temp=stall_B? 0: rd_sel_d_B;

   //Nbit_reg #(3, 3'b000) rd_reg_d (.in(rd_sel_A), .out(rd_sel_d_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_x (.in(rd_sel_d_A_temp), .out(rd_sel_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_m (.in(rd_sel_x_A), .out(rd_sel_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_w (.in(rd_sel_m_A), .out(rd_sel_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire [2:0]rd_sel_x_B_temp=(br_is_jump_A)?0:rd_sel_x_B;
   Nbit_reg #(3, 3'b000) rd_reg_x_B (.in(rd_sel_d_B_temp), .out(rd_sel_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_m_B (.in(rd_sel_x_B_temp), .out(rd_sel_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_w_B (.in(rd_sel_m_B), .out(rd_sel_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //rs_sel_reg
   wire [2:0] rs_sel_d_A,rs_sel_x_A,rs_sel_m_A,rt_sel_d_A,rt_sel_x_A,rt_sel_m_A,rt_sel_d_A_temp,rs_sel_d_A_temp;
   wire [2:0] rs_sel_d_B,rs_sel_x_B,rs_sel_m_B,rt_sel_d_B,rt_sel_x_B,rt_sel_m_B,rt_sel_d_B_temp,rs_sel_d_B_temp;
   
   Nbit_reg #(3, 3'b000) rs_reg_x (.in( (stall_A)?0:rs_sel_d_A), .out(rs_sel_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rs_reg_m (.in( rs_sel_x_A), .out(rs_sel_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
  
   wire [2:0]rs_sel_x_B_temp=(br_is_jump_A)?0:rs_sel_x_B; 
   Nbit_reg #(3, 3'b000) rs_reg_x_B (.in( (stall_B)?0:rs_sel_d_B), .out(rs_sel_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rs_reg_m_B (.in( rs_sel_x_B_temp), .out(rs_sel_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
  
   //rt_sel_reg
   //Nbit_reg #(3, 3'b000) rt_reg_d (.in( rt_sel_A), .out(rt_sel_d_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rt_reg_x (.in( (stall_A)?0:rt_sel_d_A), .out(rt_sel_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rt_reg_m (.in( rt_sel_x_A), .out(rt_sel_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire [2:0]rt_sel_x_B_temp=(br_is_jump_A)?0:rt_sel_x_B;
   Nbit_reg #(3, 3'b000) rt_reg_x_B (.in((stall_B)?0: rt_sel_d_B), .out(rt_sel_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rt_reg_m_B (.in( rt_sel_x_B_temp), .out(rt_sel_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //r1re_reg
   wire r1re_x_reg_A, r2re_x_reg_A,r1re_d_reg_A, r2re_d_reg_A,r1re_m_reg_A, r2re_m_reg_A;
   Nbit_reg #(1, 1'b0) rs_reg_x_re (.in((stall_A)?0:r1re_d_reg_A), .out(r1re_x_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rs_reg_m_re (.in(r1re_x_reg_A), .out(r1re_m_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire r1re_x_reg_B, r2re_x_reg_B,r1re_d_reg_B, r2re_d_reg_B,r1re_m_reg_B, r2re_m_reg_B;
   wire r1re_x_reg_B_temp=(br_is_jump_A)?0:r1re_x_reg_B;
   Nbit_reg #(1, 1'b0) rs_reg_x_re_B (.in((stall_B)?0:r1re_d_reg_B), .out(r1re_x_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rs_reg_m_re_B (.in(r1re_x_reg_B_temp), .out(r1re_m_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //r2re_reg
   Nbit_reg #(1, 1'b0) rt_reg_x_re (.in((stall_A)?0:r2re_d_reg_A), .out(r2re_x_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rt_reg_m_re (.in(r2re_x_reg_A), .out(r2re_m_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire r2re_x_reg_B_temp=(br_is_jump_A)?0:r2re_x_reg_B;
   Nbit_reg #(1, 1'b0) rt_reg_x_re_B (.in((stall_B)?0:(r2re_d_reg_B)), .out(r2re_x_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rt_reg_m_re_B (.in(r2re_x_reg_B_temp), .out(r2re_m_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //select_pc+1_reg
   wire select_pc_plus_one_d_reg_A,  select_pc_plus_one_x_reg_A, select_pc_plus_one_m_reg_A, select_pc_plus_one_w_reg_A;
   //Nbit_reg #(1, 1'b0) select_pc_d (.in( select_pc_plus_one_A), .out(select_pc_plus_one_d_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) select_pc_x (.in( (stall_A)?0:select_pc_plus_one_d_reg_A), .out(select_pc_plus_one_x_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire select_pc_plus_one_d_reg_B,  select_pc_plus_one_x_reg_B, select_pc_plus_one_m_reg_B, select_pc_plus_one_w_reg_B;
   wire select_pc_plus_one_reg_x_B_temp=(br_is_jump_A)?0:select_pc_plus_one_x_reg_B;
   Nbit_reg #(1, 1'b0) select_pc_x_B (.in( (stall_B)?0:select_pc_plus_one_d_reg_B), .out(select_pc_plus_one_x_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   
   //is_load_reg
   wire is_load_d_reg_A, is_load_x_reg_A,is_load_m_reg_A,is_load_w_reg_A;
   wire is_load_d_reg_B, is_load_x_reg_B,is_load_m_reg_B,is_load_w_reg_B;
   
   Nbit_reg #(1, 1'b0) is_load_reg_x (.in( (stall_A)?0:is_load_d_reg_A), .out(is_load_x_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_m (.in( is_load_x_reg_A), .out(is_load_m_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_w (.in( is_load_m_reg_A), .out(is_load_w_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire is_load_x_reg_B_temp=(br_is_jump_A)?0:is_load_x_reg_B;
   Nbit_reg #(1, 1'b0) is_load_reg_x_B (.in( (stall_B)?0:is_load_d_reg_B), .out(is_load_x_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_m_B (.in( is_load_x_reg_B_temp), .out(is_load_m_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_w_B (.in( is_load_m_reg_B), .out(is_load_w_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //is_store_reg
   wire is_store_d_reg_A, is_store_x_reg_A,is_store_m_reg_A,is_store_w_reg_A;
   wire is_store_d_reg_B, is_store_x_reg_B,is_store_m_reg_B,is_store_w_reg_B;
   Nbit_reg #(1, 1'b0) is_store_reg_x (.in( (stall_A)?0:is_store_d_reg_A), .out(is_store_x_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_store_reg_m (.in( is_store_x_reg_A), .out(is_store_m_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_store_reg_w (.in( is_store_m_reg_A), .out(is_store_w_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire is_store_x_reg_B_temp=(br_is_jump_A)?0:is_store_x_reg_B;
   Nbit_reg #(1, 1'b0) is_store_reg_x_B (.in( (stall_B)?0:is_store_d_reg_B), .out(is_store_x_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_store_reg_m_B (.in( is_store_x_reg_B_temp), .out(is_store_m_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_store_reg_w_B (.in( is_store_m_reg_B), .out(is_store_w_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //is_brach_reg
   wire is_branch_d_reg_A,is_branch_x_reg_A;
   //Nbit_reg #(1, 1'b0) is_branch_reg_d (.in( is_branch_A), .out(is_branch_d_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_branch_reg_x (.in((stall_A)?0: is_branch_d_reg_A), .out(is_branch_x_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire is_branch_d_reg_B,is_branch_x_reg_B;
   //Nbit_reg #(1, 1'b0) is_branch_reg_d_B (.in( is_branch_B), .out(is_branch_d_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_branch_reg_x_B (.in( (stall_B)?0:is_branch_d_reg_B), .out(is_branch_x_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //is_control reg
   wire is_control_insn_d_reg_A,is_control_insn_x_reg_A,is_control_insn_d_reg_B,is_control_insn_x_reg_B;
   Nbit_reg #(1, 1'b0) is_control_insn_reg_x (.in( (stall_A)?0:is_control_insn_d_reg_A), .out(is_control_insn_x_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_control_insn_reg_x_B (.in( (stall_B)?0:is_control_insn_d_reg_B), .out(is_control_insn_x_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //nzp_we_reg
   wire  nzp_we_d_reg_A, nzp_we_x_reg_A,nzp_we_m_reg_A,nzp_we_w_reg_A;
   wire  nzp_we_d_reg_B, nzp_we_x_reg_B,nzp_we_m_reg_B,nzp_we_w_reg_B;
   Nbit_reg #(1, 1'b0) nzp_we_reg_x (.in((stall_A)?0:nzp_we_d_reg_A), .out(nzp_we_x_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_m (.in(nzp_we_x_reg_A), .out(nzp_we_m_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_w (.in(nzp_we_m_reg_A), .out(nzp_we_w_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire nzp_we_x_reg_B_temp=(br_is_jump_A)?0:nzp_we_x_reg_B;
   Nbit_reg #(1, 1'b0) nzp_we_reg_x_B (.in((stall_B)?0:nzp_we_d_reg_B), .out(nzp_we_x_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_m_B(.in(nzp_we_x_reg_B_temp), .out(nzp_we_m_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_w_B (.in(nzp_we_m_reg_B), .out(nzp_we_w_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //regfile_we_reg
   wire regfile_we_d_reg_A,regfile_we_x_reg_A,regfile_we_m_reg_A,regfile_we_w_reg_A;
   wire regfile_we_d_reg_B,regfile_we_x_reg_B,regfile_we_m_reg_B,regfile_we_w_reg_B;
   //Nbit_reg #(1, 1'b0) reg_d_we (.in( regfile_we_A), .out(regfile_we_d_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) reg_x_we (.in((stall_A)?0:regfile_we_d_reg_A), .out(regfile_we_x_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) reg_m_we (.in( regfile_we_x_reg_A), .out(regfile_we_m_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) reg_w_we (.in( regfile_we_m_reg_A), .out(regfile_we_w_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire regfile_we_x_reg_B_temp=(br_is_jump_A)?0:regfile_we_x_reg_B;
   Nbit_reg #(1, 1'b0) reg_x_we_B (.in((stall_B)?0:regfile_we_d_reg_B), .out(regfile_we_x_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) reg_m_we_B (.in( regfile_we_x_reg_B_temp), .out(regfile_we_m_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) reg_w_we_B (.in( regfile_we_m_reg_B), .out(regfile_we_w_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   //Decoder A B
   lc4_decoder insn_decoder_A(insn_d_A,rs_sel_d_A, r1re_d_reg_A,rt_sel_d_A,r2re_d_reg_A,rd_sel_d_A,
   regfile_we_d_reg_A,nzp_we_d_reg_A,select_pc_plus_one_d_reg_A,is_load_d_reg_A,is_store_d_reg_A,is_branch_d_reg_A,is_control_insn_d_reg_A);

   lc4_decoder insn_decoder_B(insn_d_B,rs_sel_d_B, r1re_d_reg_B,rt_sel_d_B,r2re_d_reg_B,rd_sel_d_B,
   regfile_we_d_reg_B,nzp_we_d_reg_B,select_pc_plus_one_d_reg_B,is_load_d_reg_B,is_store_d_reg_B,is_branch_d_reg_B,is_control_insn_d_reg_B);

   //rs,rd  reg
   wire [15:0] rs_x_A, rt_x_A, rs_x_B, rt_x_B,regfile_wr_A,regfile_wr_B,rs_A,rt_A,rs_B,rt_B;
   lc4_regfile_ss m0(clk,gwe,rst,
                     rs_sel_d_A,rs_A,rt_sel_d_A,rt_A,
                     rs_sel_d_B,rs_B,rt_sel_d_B,rt_B,
                     rd_sel_w_A,regfile_wr_A,regfile_we_w_reg_A,
                     rd_sel_w_B,regfile_wr_B,regfile_we_w_reg_B);
   
   Nbit_reg #(16, 16'b0) rs_reg_x_data (.in((!r1re_d_reg_A)?16'b0:rs_A), .out(rs_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) rt_reg_x_data (.in((!r2re_d_reg_A)?16'b0:rt_A), .out(rt_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) rs_reg_x_data_B (.in((!r1re_d_reg_B)?16'b0:rs_B), .out(rs_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) rt_reg_x_data_B (.in((!r2re_d_reg_B)?16'b0:rt_B), .out(rt_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] rs_alu_A,rt_alu_A,rs_alu_B,rt_alu_B,rs_content_m_A,rt_content_m_A,rs_content_m_B,rt_content_m_B;

   /*...........bypass..............*/
   //mx wx bypass
   assign rs_alu_A= (rd_sel_m_B==rs_sel_x_A && regfile_we_m_reg_B) ? out_alu_m_reg_B 
                   :(rd_sel_m_A==rs_sel_x_A && regfile_we_m_reg_A) ? out_alu_m_reg_A 
                   :(rd_sel_w_B==rs_sel_x_A && regfile_we_w_reg_B )? regfile_wr_B 
                   :(rd_sel_w_A==rs_sel_x_A && regfile_we_w_reg_A )? regfile_wr_A
                   : rs_x_A ;
   
   assign rt_alu_A= (rd_sel_m_B==rt_sel_x_A && regfile_we_m_reg_B) ? out_alu_m_reg_B 
                  : (rd_sel_m_A==rt_sel_x_A && regfile_we_m_reg_A )? out_alu_m_reg_A
                  : (rd_sel_w_B==rt_sel_x_A && regfile_we_w_reg_B )? regfile_wr_B 
                  : (rd_sel_w_A==rt_sel_x_A && regfile_we_w_reg_A )? regfile_wr_A
                  : rt_x_A;

   assign rs_alu_B= (rd_sel_m_B==rs_sel_x_B && regfile_we_m_reg_B) ? out_alu_m_reg_B
                  : (rd_sel_m_A==rs_sel_x_B && regfile_we_m_reg_A) ? out_alu_m_reg_A
                  : (rd_sel_w_B==rs_sel_x_B && regfile_we_w_reg_B )?  regfile_wr_B 
                  : (rd_sel_w_A==rs_sel_x_B && regfile_we_w_reg_A )?  regfile_wr_A 
                  : rs_x_B ;

  assign rt_alu_B=  (rd_sel_m_B==rt_sel_x_B && regfile_we_m_reg_B) ? out_alu_m_reg_B
                  : (rd_sel_m_A==rt_sel_x_B && regfile_we_m_reg_A) ? out_alu_m_reg_A
                  : (rd_sel_w_B==rt_sel_x_B && regfile_we_w_reg_B )?  regfile_wr_B 
                  : (rd_sel_w_A==rt_sel_x_B && regfile_we_w_reg_A )?  regfile_wr_A 
                  : rt_x_B ;

   Nbit_reg #(16, 16'b0) rs_content_reg_m (.in(rs_alu_A), .out(rs_content_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) rt_content_reg_m (.in(rt_alu_A), .out(rt_content_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) rs_content_reg_m_B (.in(rs_alu_B), .out(rs_content_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) rt_content_reg_m_B (.in(rt_alu_B), .out(rt_content_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //wm bypass
   wire[15:0] rs_wm_m_A,rt_wm_m_A,rt_wm_w_A,rs_wm_m_B,rt_wm_m_B,rt_wm_w_B;
   assign rt_wm_m_A =(is_store_m_reg_A && regfile_we_w_reg_B && (rd_sel_w_B == rt_sel_m_A)) ? regfile_wr_B
                      : ((rd_sel_w_A==rt_sel_m_A) && is_store_m_reg_A && regfile_we_w_reg_A)? regfile_wr_A
                      : rt_content_m_A;
   assign rt_wm_m_B =(is_store_m_reg_B && (rt_sel_m_B == rd_sel_m_A) && regfile_we_m_reg_A) ?out_alu_m_reg_A
                     : ((rd_sel_w_B==rt_sel_m_B) && is_store_m_reg_B && regfile_we_w_reg_B)? regfile_wr_B
                     : (is_store_m_reg_B && regfile_we_w_reg_A && (rd_sel_w_A == rt_sel_m_B) ) ? regfile_wr_A
                     : rt_content_m_B;
   
   //Nbit_reg #(16, 16'b0) rt_reg_w_data (.in(rt_wm_m_A), .out(rt_wm_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
  /*..............bypass_end...................*/
   
   //PC PLUS ONE/TWO
   wire [15:0] pc_plus_one, pc_plus_two;
   cla16 adder_pc1(.a(pc), .b(16'd1), .cin(1'b0), .sum(pc_plus_one));
   cla16 adder_pc2(.a(pc), .b(16'd2), .cin(1'b0), .sum(pc_plus_two));
   
   wire [15:0] f_pc_plus_one_A = stall_B_only ? decode_pc_plus_one_B : pc_plus_one;
   wire [15:0] f_pc_plus_one_B = stall_B_only ? pc_plus_one : pc_plus_two;
   
   wire [15:0] decode_pc_plus_one_A, execute_pc_plus_one_A;
   Nbit_reg #(16,16'b0) decode_pc_plus_one_register_A(.in(f_pc_plus_one_A), .out(decode_pc_plus_one_A), .clk(clk), .we(!(stall_A)), .gwe(gwe), .rst(rst));
   Nbit_reg #(16,16'b0) execute_pc_plus_one_register_A(.in(decode_pc_plus_one_A), .out(execute_pc_plus_one_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] decode_pc_plus_one_B, execute_pc_plus_one_B;
   Nbit_reg #(16,16'b0) decode_pc_plus_one_register_B(.in(f_pc_plus_one_B), .out(decode_pc_plus_one_B), .clk(clk), .we(!(stall_A)), .gwe(gwe), .rst(rst));
   Nbit_reg #(16,16'b0) execute_pc_plus_one_register_B(.in(decode_pc_plus_one_B), .out(execute_pc_plus_one_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //ALU
   lc4_alu A_PIPE(insn_x_A,pc_x_A,rs_alu_A,rt_alu_A, out_alu_A); 
   lc4_alu B_PIPE(insn_x_B,pc_x_B,rs_alu_B,rt_alu_B, out_alu_B);

   //out_alu_reg
   wire [15:0] out_alu_A,out_alu_x_reg_A, out_alu_m_reg_A,out_alu_w_reg_A;
   wire [15:0] out_alu_B,out_alu_x_reg_B, out_alu_m_reg_B,out_alu_w_reg_B;
   assign out_alu_x_reg_A=(select_pc_plus_one_x_reg_A)? execute_pc_plus_one_A : out_alu_A;
   assign out_alu_x_reg_B=(select_pc_plus_one_x_reg_B)? execute_pc_plus_one_B : out_alu_B;

   Nbit_reg #(16, 16'b0) alu_reg_m (.in(out_alu_x_reg_A), .out(out_alu_m_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) alu_reg_w (.in(out_alu_m_reg_A), .out(out_alu_w_reg_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) alu_reg_m_B (.in(out_alu_x_reg_B), .out(out_alu_m_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) alu_reg_w_B (.in(out_alu_m_reg_B), .out(out_alu_w_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //dmem_data_reg
   //Nbit_reg #(16, 16'b0) dmem_data_reg_ww_B (.in(i_cur_dmem_data), .out(dmem_data_from_w_reg_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   //assign write_input_reg_B = ((is_load_w_reg_B ))? dmem_data_from_w_reg_B : out_alu_w_reg_B;

   wire [15:0] dmem_data_m_A,dmem_data_w_A,dmem_data_m_B,dmem_data_w_B;
   assign dmem_data_m_A=(is_load_m_reg_A)? i_cur_dmem_data :(is_store_m_reg_A)? rt_wm_m_A: 16'b0;
   assign dmem_data_m_B=(is_load_m_reg_B)? i_cur_dmem_data : (is_store_m_reg_B)? rt_wm_m_B:16'b0;

   Nbit_reg #(16, 16'b0) dmem_data_reg_w (.in(dmem_data_m_A), .out(dmem_data_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) dmem_data_reg_w_B (.in(dmem_data_m_B), .out(dmem_data_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //o_dmem_towrite reg
   assign o_dmem_towrite=(is_load_m_reg_B | is_store_m_reg_B )? dmem_data_m_B : dmem_data_m_A ;

   //regfile_write
   assign regfile_wr_A=(is_load_w_reg_A)? dmem_data_w_A : out_alu_w_reg_A ; 
   assign regfile_wr_B=(is_load_w_reg_B)? dmem_data_w_B : out_alu_w_reg_B ; 

   //dmem_addr reg
   wire [15:0] o_dmem_addr_m_A,o_dmem_addr_w_A,o_dmem_addr_m_B,o_dmem_addr_w_B;
   assign o_dmem_addr_m_A=(is_load_m_reg_A | is_store_m_reg_A )?out_alu_m_reg_A : 16'b0;
   assign o_dmem_addr_m_B=(is_load_m_reg_B | is_store_m_reg_B )?out_alu_m_reg_B : 16'b0;

   Nbit_reg #(16, 16'b0) o_dmem_reg_w (.in(o_dmem_addr_m_A), .out(o_dmem_addr_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) o_dmem_reg_w_B (.in(o_dmem_addr_m_B), .out(o_dmem_addr_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   assign o_dmem_addr  =(is_load_m_reg_B | is_store_m_reg_B )? o_dmem_addr_m_B : o_dmem_addr_m_A;

  
   // wire [15:0] o_dmem_towrite_m_A,o_dmem_towrite_w_A,o_dmem_towrite_m_B,o_dmem_towrite_w_B;
   // assign o_dmem_towrite_m_A=(is_load_m_reg_A)? i_cur_dmem_data : is_store_m_reg_A? rt_wm_m_A : 16'b0;  /*( is_store_m_reg ) ? ( ( regfile_we_w_reg && ( rd_w == rt_sel_m_reg ) ) ? regfile_wr: rt_content_m ) : 16'h0000;*/
   // assign o_dmem_towrite_m_B=(is_load_m_reg_B)? i_cur_dmem_data : is_store_m_reg_B? rt_wm_m_B : 16'b0; 
   // Nbit_reg #(16, 16'b0) o_dmem_towrite_reg_w (.in(o_dmem_towrite_m_A), .out(o_dmem_towrite_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   // Nbit_reg #(16, 16'b0) o_dmem_towrite_reg_w_B (.in(o_dmem_towrite_m_B), .out(o_dmem_towrite_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
 
   //o_dmem_we reg
   wire o_dmem_we_m,o_dmem_we_w;
   assign o_dmem_we_m=is_store_m_reg_A | is_store_m_reg_B;
   assign o_dmem_we=o_dmem_we_m;
   Nbit_reg #(1, 1'b0) o_dmem_we_reg_w (.in( o_dmem_we_m), .out(o_dmem_we_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   
   //nzp_reg
   wire [2:0] nzp_data_x_A,nzp_data_m_A,nzp_data_w_A;
   assign nzp_data_x_A[2]= out_alu_x_reg_A[15] ; //n
   assign nzp_data_x_A[1]=(out_alu_x_reg_A==16'b0);     //z
   assign nzp_data_x_A[0]= (!out_alu_x_reg_A[15]) & (!nzp_data_x_A[1]);//p

   wire [2:0] nzp_data_x_B,nzp_data_m_B,nzp_data_w_B;
   assign nzp_data_x_B[2]= out_alu_x_reg_B[15] ; //n
   assign nzp_data_x_B[1]=(out_alu_x_reg_B==16'b0);     //z
   assign nzp_data_x_B[0]= (!out_alu_x_reg_B[15]) & (!nzp_data_x_B[1]);//p

   Nbit_reg #(3, 3'b000) nzp_reg_m (.in(nzp_data_x_A), .out(nzp_data_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) nzp_reg_w (.in(nzp_data_m_A), .out(nzp_data_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) nzp_reg_m_B (.in(nzp_data_x_B), .out(nzp_data_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) nzp_reg_w_B (.in(nzp_data_m_B), .out(nzp_data_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] nzp_data_A, nzp_data_B,last_nzp,nzp_temp;
   assign nzp_data_A[2]= (regfile_wr_A[15]==1'b1) ; //n
   assign nzp_data_A[1]=(regfile_wr_A)? 1'b0 : 1'b1;     //z
   assign nzp_data_A[0]=( (regfile_wr_A[15]==0) & (regfile_wr_A!=0));//p

   assign nzp_data_B[2]= (regfile_wr_B[15]==1'b1) ; //n
   assign nzp_data_B[1]=(regfile_wr_B)? 1'b0 : 1'b1;     //z
   assign nzp_data_B[0]=( (regfile_wr_B[15]==0) & (regfile_wr_B!=0));//p

   //test signal
   assign test_stall_A =(pc==16'h8201 | pc==16'h8202 | pc==16'h8203 | pc==16'h8204 | pc==16'h8205 )?2'd2:stall_w_A;//(stall_d)?2'd3 : ((pc>16'h8203)? 2'd0:2'd2);
   assign test_stall_B =(pc==16'h8201 | pc==16'h8202 | pc==16'h8203 | pc==16'h8204 | pc==16'h8205)?2'd2:stall_w_B;
   assign test_cur_pc_A=pc_w_A;
   assign test_cur_pc_B=pc_w_B;
   assign test_cur_insn_A=insn_w_A;
   assign test_cur_insn_B=insn_w_B;
   assign test_regfile_we_A=regfile_we_w_reg_A;
   assign test_regfile_we_B=regfile_we_w_reg_B;
   assign test_regfile_wsel_A=rd_sel_w_A;
   assign test_regfile_wsel_B=rd_sel_w_B;
   assign test_regfile_data_A=regfile_wr_A;
   assign test_regfile_data_B=regfile_wr_B;
   assign test_nzp_we_A=nzp_we_w_reg_A;
   assign test_nzp_we_B=nzp_we_w_reg_B;
   assign test_nzp_new_bits_A=(nzp_we_w_reg_A)? nzp_data_A: 3'b0;
   assign test_nzp_new_bits_B=(nzp_we_w_reg_B)? nzp_data_B: 3'b0;
   assign test_dmem_we_A=is_store_w_reg_A; 
   assign test_dmem_we_B=is_store_w_reg_B; 
   assign test_dmem_addr_A=o_dmem_addr_w_A; 
   assign test_dmem_addr_B=o_dmem_addr_w_B; 
   assign test_dmem_data_A=  dmem_data_w_A ;
   assign test_dmem_data_B=  dmem_data_w_B  ;





   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */
   always @(posedge gwe) begin
   //if(pc<16'h8430)
      // $display("%d %h %h %h %h %h %h %h %h %h %h %h %h", $time, pc,out_alu_m_reg_A , rd_sel_m_A,rs_sel_x_B , regfile_we_m_reg_A,rs_x_A,rs_sel_x_B,rt_sel_x_A,rd_sel_x_A,rs_alu_A,out_alu_m_reg_A,out_alu_A);
      //$display("%d %h %h %h %h %h %h %h %h %h %h %h %h %h",pc_w_A-16'h8200,br_is_jump_A,is_branch_x_reg_A , br_taken_A , nzp_data_m_A, nzp_data_m_B , nzp_data_w_A,nzp_data_w_B , last_nzp , rd_sel_m_A ,rd_sel_x_A , ((rd_sel_w_A==rt_sel_m_B) && is_store_m_reg_B && regfile_we_w_reg_B) , (is_store_m_reg_B && regfile_we_w_reg_A && (rd_sel_w_A == rt_sel_m_B) ) , rt_content_m_B);
         // assign nzp_mispredict=(nzp_we_m_reg_B)?  nzp_data_m_B : (nzp_we_m_reg_A)? nzp_data_m_A 
         //                : (nzp_we_w_reg_B)? nzp_data_w_B:(nzp_we_w_reg_A)? nzp_data_w_A
         //                : last_nzp ;
      //$display("%d %h",pc_w_A-16'h8200,br_is_jump_A);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nanoseconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display();
   end
endmodule