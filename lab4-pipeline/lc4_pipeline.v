
/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire  [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire  [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/
   
   assign led_data = switch_data;
   wire [1:0] stall_f,stall_d,stall_d_temp,stall_x,stall_m,stall_w;
   //load-to-use-stall
   wire load_use_stall;
   assign load_use_stall=  is_load_x_reg  && (( (rs_sel_d_reg == rd_x) && r1re_d_reg ) || ((( rt_sel_d_reg == rd_x) && r2re_d_reg ) && (!is_store_d_reg)) | is_branch_d_reg);

   //brach misprediction
   wire br_is_jump;
   wire [2:0] nzp_mispredict;
   Nbit_reg #(3, 3'b010) nzp_reg (.in(nzp_data), .out(last_nzp), .clk(clk), .we(nzp_we_w_reg), .gwe(gwe), .rst(rst));
   
   wire nzp_match;
   assign nzp_mispredict=(nzp_we_m_reg)?nzp_data_m : (nzp_we_w_reg)? nzp_data_w : last_nzp ;
   assign nzp_match=(nzp_mispredict[2]&insn_x[11]) | (nzp_mispredict[1]&insn_x[10]) | (nzp_mispredict[0]&insn_x[9]);
   assign br_is_jump=((is_branch_x_reg & nzp_match ) | is_control_insn_x_reg );
   
   //decoder
   lc4_decoder insn_decoder(insn_f,rs_sel, r1re,rt_sel,r2re,rd_sel,
   regfile_we,nzp_we,select_pc_plus_one,is_load,is_store,is_branch,is_control_insn);
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)

   // pc wires attached to the PC register's ports
   wire [15:0]   pc,next_pc;      // Current program counter (read out from pc_reg)
  // Next program counter (you compute this and feed it into next_pc)
   wire [2:0] nzp_data, last_nzp,nzp_temp;
   wire [2:0] rs_sel,rd_sel,rt_sel; //decoder output
   wire [15:0] rs,rd,rt,out_alu,regfile_wr,temp1_regfile_wr,temp2_regfile_wr,temp3_regfile_wr; //for regfile
   wire r1re,r2re,regfile_we,nzp_we,select_pc_plus_one,is_load,is_store,is_branch,is_control_insn;//for decoder output
   wire reg_enable;// enable reg in each stage/ flush because of mis-prediction
   
   //nop/flush control signal
   //assign br_is_jump=1'b0;
   assign stall_f=(br_is_jump)?2'd2 : 2'b0;
   assign stall_d_temp=(load_use_stall)?2'd3 : (br_is_jump)? 2'd2 : stall_d;
   //assign reg_enable = (load_use_stall)?1'b0:1'b1;

   //stall reg
   Nbit_reg #(2, 2'b0) stall_reg_d (.in( stall_f), .out(stall_d), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) stall_reg_x (.in( stall_d_temp), .out(stall_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) stall_reg_m (.in( stall_x), .out(stall_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'b0) stall_reg_w (.in( stall_m), .out(stall_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   // Program counter register, starts at 8200h at bootup
   //pc reg
   wire [15:0]  pc_d,pc_temp,pc_x,pc_m,pc_w;
   assign next_pc= (br_is_jump )? out_alu: pc_temp+1;
   assign pc_temp=(load_use_stall || br_is_jump)? pc_d : pc;

   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_d (.in(pc_temp), .out(pc_d), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_x (.in(pc_d), .out(pc_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_m (.in(pc_x), .out(pc_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h0000) pc_reg_w (.in(pc_m), .out(pc_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //insn reg
   wire [15:0] insn_f,insn_d,insn_x,insn_m,insn_w,insn_d_temp;
   assign insn_f= (br_is_jump)?16'b0 : i_cur_insn;
   assign insn_d_temp= (load_use_stall | br_is_jump)?16'b0:insn_d;

   Nbit_reg #(16, 16'b0) insn_reg_d (.in(insn_f), .out(insn_d), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_x (.in(insn_d_temp), .out(insn_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_m (.in(insn_x), .out(insn_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_w (.in(insn_m), .out(insn_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //rd_sel_reg
   wire [2:0] rd_d,rd_x,rd_m,rd_w;
   Nbit_reg #(3, 3'b000) rd_reg_d (.in(rd_sel), .out(rd_d), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_x (.in((load_use_stall | br_is_jump)?3'b0:rd_d), .out(rd_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_m (.in(rd_x), .out(rd_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_w (.in(rd_m), .out(rd_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire r1re_x_reg, r2re_x_reg,r1re_d_reg, r2re_d_reg,r1re_m_reg, r2re_m_reg;
   wire [2:0] rs_sel_d_reg,rs_sel_x_reg,rs_sel_m_reg, rt_sel_d_reg,rt_sel_x_reg,rt_sel_m_reg, rd_d_reg;
   wire  nzp_we_d_reg, nzp_we_x_reg,nzp_we_m_reg,nzp_we_w_reg;
   wire select_pc_plus_one_d_reg,  select_pc_plus_one_x_reg, select_pc_plus_one_m_reg, select_pc_plus_one_w_reg;
   wire is_load_d_reg, is_load_x_reg,is_load_m_reg,is_load_w_reg;
   wire is_store_d_reg, is_store_x_reg,is_store_m_reg,is_store_w_reg;
   wire is_branch_d_reg,is_branch_x_reg;
   wire is_control_insn_d_reg,is_control_insn_x_reg,is_control_insn_m_reg,is_control_insn_w_reg;
   
   //rs_sel_reg
   Nbit_reg #(3, 3'b000) rs_reg_d (.in( rs_sel), .out(rs_sel_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rs_reg_x (.in( (load_use_stall | br_is_jump)?3'b0:rs_sel_d_reg), .out(rs_sel_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rs_reg_m (.in( rs_sel_x_reg), .out(rs_sel_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //r1re_reg
   Nbit_reg #(1, 1'b0) rs_reg_d_re (.in( r1re), .out(r1re_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rs_reg_x_re (.in((load_use_stall | br_is_jump)?1'b0:r1re_d_reg), .out(r1re_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rs_reg_m_re (.in(r1re_x_reg), .out(r1re_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //rt_sel_reg
   Nbit_reg #(3, 3'b000) rt_reg_d (.in( rt_sel), .out(rt_sel_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rt_reg_x (.in( (load_use_stall | br_is_jump)?3'b0:rt_sel_d_reg), .out(rt_sel_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rt_reg_m (.in( rt_sel_x_reg), .out(rt_sel_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //r2re_reg
   Nbit_reg #(1, 1'b0) rt_reg_d_re (.in( r2re), .out(r2re_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rt_reg_x_re (.in((load_use_stall | br_is_jump)?1'b0:r2re_d_reg), .out(r2re_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rt_reg_m_re (.in(r2re_x_reg), .out(r2re_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //select_pc+1_reg
   Nbit_reg #(1, 1'b0) select_pc_plus_one_reg_d (.in( select_pc_plus_one), .out(select_pc_plus_one_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) select_pc_plus_one_reg_x (.in( (load_use_stall|br_is_jump)?1'b0:select_pc_plus_one_d_reg), .out(select_pc_plus_one_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) select_pc_plus_one_reg_m (.in( select_pc_plus_one_x_reg), .out(select_pc_plus_one_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) select_pc_plus_one_reg_w (.in( select_pc_plus_one_m_reg), .out(select_pc_plus_one_w_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //is_load_reg
   Nbit_reg #(1, 1'b0) is_load_reg_d (.in( is_load), .out(is_load_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_x (.in( (load_use_stall | br_is_jump)?1'b0:is_load_d_reg), .out(is_load_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_m (.in( is_load_x_reg), .out(is_load_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_w (.in( is_load_m_reg), .out(is_load_w_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //is_store_reg
   Nbit_reg #(1, 1'b0) is_store_reg_d (.in( is_store), .out(is_store_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_store_reg_x (.in( (load_use_stall|br_is_jump)?1'b0:is_store_d_reg), .out(is_store_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_store_reg_m (.in( is_store_x_reg), .out(is_store_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_store_reg_w (.in( is_store_m_reg), .out(is_store_w_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //is_brach_reg
   Nbit_reg #(1, 1'b0) is_branch_reg_d (.in( is_branch), .out(is_branch_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_branch_reg_x (.in( (load_use_stall|br_is_jump)?1'b0:is_branch_d_reg), .out(is_branch_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 
   //is_control reg
   Nbit_reg #(1, 1'b0) is_control_insn_reg_d (.in( is_control_insn), .out(is_control_insn_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_control_insn_reg_x (.in( (load_use_stall|br_is_jump)?1'b0:is_control_insn_d_reg), .out(is_control_insn_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_control_insn_reg_m (.in( is_control_insn_x_reg), .out(is_control_insn_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_control_insn_reg_w (.in( is_control_insn_m_reg), .out(is_control_insn_w_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //nzp_we_reg
   Nbit_reg #(1, 1'b0) nzp_we_reg_d (.in(nzp_we), .out(nzp_we_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_x (.in((load_use_stall|br_is_jump)?1'b0:nzp_we_d_reg), .out(nzp_we_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_m (.in(nzp_we_x_reg), .out(nzp_we_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_w (.in(nzp_we_m_reg), .out(nzp_we_w_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //regfile_we_reg
   wire regfile_we_d_reg,regfile_we_x_reg,regfile_we_m_reg,regfile_we_w_reg;
   Nbit_reg #(1, 1'b0) regfile_d_we (.in( regfile_we), .out(regfile_we_d_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) reg_x_we (.in((load_use_stall|br_is_jump)?1'b0:regfile_we_d_reg), .out(regfile_we_x_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) reg_m_we (.in( regfile_we_x_reg), .out(regfile_we_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) reg_w_we (.in( regfile_we_m_reg), .out(regfile_we_w_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //regfile
   wire [15:0] rs_regfile_out,rt_regfile_out;
   lc4_regfile m0(clk,gwe,rst,rs_sel_d_reg,rs,rt_sel_d_reg,rt,rd_w,regfile_wr,regfile_we_w_reg);
   
  //rs_wd reg
   wire [15:0] rs_wd_x, rt_wd_x, rs_content_d,rt_content_d,rs_wd_d,rt_wd_d,rs_wm_m,rt_wm_m,rt_wm_w;
   Nbit_reg #(16, 16'b0) rs_reg_x_data (.in(rs_wd_d), .out(rs_wd_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) rt_reg_x_data (.in(rt_wd_d), .out(rt_wd_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] rs_alu,rt_alu,rs_content_m,rt_content_m;

   /*...........bypass..............*/
   //mx wx bypass
   assign rs_alu= (rd_m==rs_sel_x_reg && regfile_we_m_reg ) ? out_alu_m_reg : ( rd_w==rs_sel_x_reg && regfile_we_w_reg )?  regfile_wr : rs_wd_x ;
   assign rt_alu= (rd_m==rt_sel_x_reg && regfile_we_m_reg) ? out_alu_m_reg : ( rd_w==rt_sel_x_reg && regfile_we_w_reg )?  regfile_wr : rt_wd_x;
   Nbit_reg #(16, 16'b0) rs_content_reg_m (.in(rs_alu), .out(rs_content_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) rt_content_reg_m (.in(rt_alu), .out(rt_content_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   // wd bypass
   assign rs_wd_d=(rd_w == rs_sel_d_reg && regfile_we_w_reg )? regfile_wr: rs;//wd bypass,(on d stage)
   assign rt_wd_d=(rd_w == rt_sel_d_reg && regfile_we_w_reg )? regfile_wr: rt;

   //wm bypass
   assign rt_wm_m =((rd_w==rt_sel_m_reg) && is_store_m_reg && regfile_we_w_reg)? regfile_wr:rt_content_m;
   Nbit_reg #(16, 16'b0) rt_reg_w_data (.in(rt_wm_m), .out(rt_wm_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
  /*..............bypass_end...................*/
   
   wire [15:0] pc_plus_one_x;
   cla16 c0(pc_x,16'b0,1'b1,pc_plus_one_x); //pc+1
   
   lc4_alu m1(insn_x,pc_x,rs_alu,rt_alu, out_alu); //alu

   //out_alu_reg
   wire [15:0] out_alu_x_reg, out_alu_m_reg,out_alu_w_reg;
   assign out_alu_x_reg=(select_pc_plus_one_x_reg)? pc_x+1 : out_alu;
   Nbit_reg #(16, 16'b0) alu_reg_m (.in(out_alu_x_reg), .out(out_alu_m_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) alu_reg_w (.in(out_alu_m_reg), .out(out_alu_w_reg), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   //dmem_data_reg
   wire [15:0] dmem_data_m,dmem_data_w;
   assign dmem_data_m=(is_load_m_reg)? i_cur_dmem_data : 16'b0;
   Nbit_reg #(16, 16'b0) dmem_data_reg_w (.in(dmem_data_m), .out(dmem_data_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //regfile_write
   assign regfile_wr=(is_load_w_reg)? dmem_data_w : out_alu_w_reg ; 
   
   //dmem_addr reg
   wire [15:0] o_dmem_addr_m,o_dmem_addr_w;
   assign o_dmem_addr_m=(is_load_m_reg | is_store_m_reg )?out_alu_m_reg : 16'b0;
   assign o_dmem_addr=o_dmem_addr_m;
   Nbit_reg #(16, 16'b0) o_dmem_reg_w (.in(o_dmem_addr_m), .out(o_dmem_addr_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
  
  //o_dmem_towrite reg
   wire [15:0] o_dmem_towrite_m,o_dmem_towrite_w;
   assign o_dmem_towrite_m=(is_store_m_reg)? rt_wm_m : 16'b0;  /*( is_store_m_reg ) ? ( ( regfile_we_w_reg && ( rd_w == rt_sel_m_reg ) ) ? regfile_wr: rt_content_m ) : 16'h0000;*/
   assign o_dmem_towrite=o_dmem_towrite_m;
   Nbit_reg #(16, 16'b0) o_dmem_towrite_reg_w (.in(o_dmem_towrite_m), .out(o_dmem_towrite_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //o_dmem_we reg
   wire o_dmem_we_m,o_dmem_we_w;
   assign o_dmem_we_m=is_store_m_reg;
   assign o_dmem_we=o_dmem_we_m;
   Nbit_reg #(1, 1'b0) o_dmem_we_reg_w (.in( o_dmem_we_m), .out(o_dmem_we_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   assign o_cur_pc=pc_temp;
   
   //nzp_reg
   wire [2:0] nzp_data_x,nzp_data_m,nzp_data_w;
   assign nzp_data_x[2]= out_alu_x_reg[15] ; //n
   assign nzp_data_x[1]=(out_alu_x_reg==16'b0);     //z
   assign nzp_data_x[0]= (!out_alu_x_reg[15]) & (!nzp_data_x[1]/*out_alu_x_reg!=0*/);//p
   Nbit_reg #(3, 3'b000) nzp_reg_m (.in(nzp_data_x), .out(nzp_data_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) nzp_reg_w (.in(nzp_data_m), .out(nzp_data_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   assign nzp_data[2]= (regfile_wr[15]==1'b1) ; //n
   assign nzp_data[1]=(regfile_wr)? 1'b0 : 1'b1;     //z
   assign nzp_data[0]=( (regfile_wr[15]==0) & (regfile_wr!=0));//p

   //test signal
   assign test_stall =(pc==16'h8201 | pc==16'h8202 | pc==16'h8203 )?2'd2:stall_w;//(stall_d)?2'd3 : ((pc>16'h8203)? 2'd0:2'd2);
   assign test_cur_pc=pc_w;
   assign test_cur_insn=insn_w;
   assign test_regfile_we=regfile_we_w_reg;
   assign test_regfile_wsel=rd_w;
   assign test_regfile_data=regfile_wr;
   assign test_nzp_we=nzp_we_w_reg;
   assign test_nzp_new_bits=(nzp_we_w_reg)? nzp_data: 3'b0;
   assign test_dmem_we=o_dmem_we_w; 
   assign test_dmem_addr=o_dmem_addr_w; 
   assign test_dmem_data=  dmem_data_w | o_dmem_towrite_w ;
   
  
   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
   if(pc <16'h8230) begin
      //$display("%h %d stall_w:%h load_use_stall:%h rs_sel_x:%h rt_sel_x:%h rd_sel_x:%h rd_x:%h regfile_wr:%h i_cur_dmem_data:%h test_regfile_wsel:%h rs:%h rt:%h rs_sel_m_reg:%h rt_wm_m:%h rt_wm_w:%h rd_w:%h rs_content_m:%h rt_content_m:%h rd_m:%h  out_alu:%h out_alu_w_reg:%h out_alu_m_reg:%h o_dmem_towrite_w:%h o_dmem_addr_m:%h", $time, pc-16'h8200,stall_w,load_use_stall,rs_sel_x_reg,rt_sel_x_reg,rd_x,rd_x,regfile_wr,i_cur_dmem_data,test_regfile_wsel,rs, rt,rs_sel_m_reg,rt_wm_m,rt_wm_w,rd_w,rs_content_m,rt_content_m, rd_m,out_alu,out_alu_w_reg,out_alu_m_reg,o_dmem_towrite_w,o_dmem_addr_m);
      //$display("%d o_dmem_towrite_w:%h o_dmem_addr_m:%h o_dmem_towrite_m:%h regfile_wr:%h,rt_content_m:%h,dmem_data_w:%h,out_alu_m:%h,rd_sel_w:%h i_cur_dmem_data:%h ", pc-16'h8200,o_dmem_towrite_w, o_dmem_addr_m,o_dmem_towrite_m,regfile_wr,rt_content_m,dmem_data_w,out_alu_m_reg,rd_w,i_cur_dmem_data);
      //$display("%d dmem_addr:%h data_input:%h data_output:%h i_cur_dmem_data:%h r%h:%h r%h insn_w:%b rt_wm_m:%h regfile_wr:%h %h %h %h",pc-16'h8200,o_dmem_addr_m,o_dmem_towrite,dmem_data_m,i_cur_dmem_data,rt_sel_d_reg,rt,rs_sel_x_reg,insn_w[15:12],rt_wm_m,regfile_wr,rd_w==rt_sel_m_reg , is_store_m_reg , regfile_we_m_reg);
      //$display("%h %h %h %h %h %h %h %h %h %h %h",pc,nzp_data_x,out_alu,br_is_jump,i_cur_insn,insn_x,nzp_mispredict,insn_x[11:9],is_branch_x_reg,nzp_match,is_control_insn_x_reg);
      //is_load_x_reg  && (( (rs_sel_d_reg == rd_x) && r1re_d_reg ) || ((( rt_sel_d_reg == rd_x) && r2re_d_reg ) && (!is_store_d_reg))
      //$display("%h %h %h %h %h %h %h %h %h",pc_x,stall_d_temp,stall_w,br_is_jump,load_use_stall,rs_sel_d_reg, rd_x,r1re_d_reg,is_load_x_reg);
   end
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
      // run it for that many nano-seconds, then set
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
`endif
endmodule