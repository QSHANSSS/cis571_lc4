/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
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

   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)

   // pc wires attached to the PC register's ports
   wire [15:0]   pc,next_pc;      // Current program counter (read out from pc_reg)
  // Next program counter (you compute this and feed it into next_pc)
   wire [15:0] pc_plus_one;
   wire [2:0] nzp_data, last_nzp,nzp_temp;
   wire [2:0] rs_sel,rd_sel,rt_sel; //decoder output
   wire [15:0] rs,rd,rt,out_alu,regfile_wr,temp1_regfile_wr,temp2_regfile_wr,temp3_regfile_wr; //for regfile
   wire r1re,r2re,regfile_we,nzp_we,select_pc_plus_one,is_load,is_store,is_branch,is_control_insn;//for decoder output
   wire pipeline_reg_enable;// enable reg in each stage
   
   assign pipeline_reg_enable = 1'b1;
   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b010) nzp_reg (.in(nzp_data), .out(last_nzp), .clk(clk), .we(nzp_we_w_reg), .gwe(gwe), .rst(rst));
 
   lc4_decoder insn_decoder(i_cur_insn,rs_sel, r1re,rt_sel,r2re,rd_sel,
   regfile_we,nzp_we,select_pc_plus_one,is_load,is_store,is_branch,is_control_insn);
  
   wire [15:0]  pc_d,pc_x,pc_m,pc_w;
   Nbit_reg #(16, 16'h8200) pc_reg_d (.in(pc), .out(pc_d), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) pc_reg_x (.in(pc_d), .out(pc_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) pc_reg_m (.in(pc_x), .out(pc_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'h8200) pc_reg_w (.in(pc_m), .out(pc_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] insn_d,insn_x,insn_m,insn_w;
   Nbit_reg #(16, 16'b0) insn_reg_d (.in(i_cur_insn), .out(insn_d), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_x (.in(insn_d), .out(insn_x), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_m (.in(insn_x), .out(insn_m), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) insn_reg_w (.in(insn_m), .out(insn_w), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   
   wire [2:0] rd_d,rd_x,rd_m,rd_w;
   Nbit_reg #(3, 3'b000) rd_reg_d (.in(rd_sel), .out(rd_d), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_x (.in(rd_d), .out(rd_x), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_m (.in(rd_x), .out(rd_m), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rd_reg_w (.in(rd_m), .out(rd_w), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   
   wire [2:0] rs_sel_x, rt_sel_x;
   wire r1re_x_reg,  r2re_x_reg;
   //Nbit_reg #(3, 3'b000) rs_reg_x_add (.in(rs_sel), .out(rs_sel_x), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
  
   //Nbit_reg #(3, 3'b000) rt_reg_x_add (.in( rt_sel), .out(rt_sel_x), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));

   wire [2:0] rs_sel_d_reg,rs_sel_x_reg,rs_sel_m_reg, rt_sel_d_reg,rt_sel_x_reg,rt_sel_m_reg, rd_d_reg;
   wire r1re_d_reg,  r2re_d_reg,  nzp_we_d_reg, nzp_we_x_reg,nzp_we_m_reg,nzp_we_w_reg;
   wire select_pc_plus_one_d_reg,  select_pc_plus_one_x_reg, select_pc_plus_one_m_reg, select_pc_plus_one_w_reg;
   wire is_load_d_reg, is_load_x_reg,is_load_m_reg,is_load_w_reg,is_store_d_reg, is_branch_d_reg, is_control_insn_d_reg;
   
   Nbit_reg #(3, 3'b000) rs_reg_d (.in( rs_sel), .out(rs_sel_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rs_reg_x (.in( rs_sel_d_reg), .out(rs_sel_x_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rs_reg_m (.in( rs_sel_x_reg), .out(rs_sel_m_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rs_reg_d_re (.in( r1re), .out(r1re_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rs_reg_x_re (.in(r1re_d_reg), .out(r1re_x_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));

   Nbit_reg #(3, 3'b000) rt_reg_d (.in( rt_sel), .out(rt_sel_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rt_reg_x (.in( rt_sel_d_reg), .out(rt_sel_x_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b000) rt_reg_m (.in( rt_sel_x_reg), .out(rt_sel_m_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rt_reg_d_re (.in( r2re), .out(r2re_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rt_reg_x_re (.in(r2re_d_reg), .out(r2re_x_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));

   Nbit_reg #(1, 1'b0) select_pc_plus_one_reg_d (.in( select_pc_plus_one), .out(select_pc_plus_one_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) select_pc_plus_one_reg_x (.in( select_pc_plus_one_d_reg), .out(select_pc_plus_one_x_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) select_pc_plus_one_reg_m (.in( select_pc_plus_one_x_reg), .out(select_pc_plus_one_m_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) select_pc_plus_one_reg_w (.in( select_pc_plus_one_m_reg), .out(select_pc_plus_one_w_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   
   Nbit_reg #(1, 1'b0) is_load_reg_d (.in( is_load), .out(is_load_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_x (.in( is_load_d_reg), .out(is_load_x_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_m (.in( is_load_x_reg), .out(is_load_m_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_load_reg_w (.in( is_load_m_reg), .out(is_load_w_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   
   Nbit_reg #(1, 1'b0) is_store_reg_d (.in( is_store), .out(is_store_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_branch_reg_d (.in( is_branch), .out(is_branch_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) is_control_insn_reg_d (.in( is_control_insn), .out(is_control_insn_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   
   Nbit_reg #(1, 1'b0) nzp_we_reg_d (.in(nzp_we), .out(nzp_we_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_x (.in(nzp_we_d_reg), .out(nzp_we_x_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_m (.in(nzp_we_x_reg), .out(nzp_we_m_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) nzp_we_reg_w (.in(nzp_we_m_reg), .out(nzp_we_w_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));

   wire regfile_we_d_reg,regfile_we_x_reg,regfile_we_m_reg,regfile_we_w_reg;
   Nbit_reg #(1, 1'b0) rd_reg_d_re (.in( regfile_we), .out(regfile_we_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rd_reg_x_re (.in( regfile_we_d_reg), .out(regfile_we_x_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rd_reg_m_re (.in( regfile_we_x_reg), .out(regfile_we_m_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(1, 1'b0) rd_reg_w_re (.in( regfile_we_m_reg), .out(regfile_we_w_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));


   cla16 c0(pc,16'b0,1'b1,pc_plus_one);
   
   lc4_regfile m0(clk,gwe,rst,rs_sel_d_reg,rs,rt_sel_d_reg,rt,rd_w,regfile_wr,regfile_we_w_reg);
   wire [15:0] regfile_wr_x, regfile_wr_m, regfile_wr_w;
   //Nbit_reg #(16, 16'b0) regfile_wr_reg_x (.in(regfile_wr), .out(regfile_wr_x), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   //Nbit_reg #(16, 16'b0) regfile_wr_reg_m (.in(regfile_wr_x), .out(regfile_wr_m), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   //Nbit_reg #(16, 16'b0) regfile_wr_reg_w (.in(regfile_wr_m), .out(regfile_wr_w), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
  
  /*...........bypass..............*/

   wire [15:0] rs_wd_x, rt_wd_x, rs_content_d,rt_content_d,rs_wd_d,rt_wd_d;
   Nbit_reg #(16, 16'b0) rs_reg_x_data (.in(rs_wd_d), .out(rs_wd_x), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) rt_reg_x_data (.in(rt_wd_d), .out(rt_wd_x), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   
   wire [15:0] rs_alu,rt_alu;
   wire [15:0] rs_content_wm,rt_content_wm;
   assign rs_content_wm = (rd_w==rs_sel_m_reg)? out_alu_w_reg:16'b0;//wm bypass
   assign rt_content_wm = (rd_w==rt_sel_m_reg)? out_alu_w_reg:16'b0;

   assign rs_alu= (rd_m==rs_sel_x_reg && regfile_we_m_reg && r1re_x_reg) ? out_alu_m_reg : ( rd_w==rs_sel_x_reg && regfile_we_w_reg )?  out_alu_w_reg : rs_wd_x ;
   assign rt_alu= (rd_m==rt_sel_x_reg && regfile_we_m_reg && r2re_x_reg) ? out_alu_m_reg : ( rd_w==rt_sel_x_reg && regfile_we_w_reg )?  out_alu_w_reg  : rt_wd_x;
   // mx or wx bypass
   assign rs_wd_d=(rd_w == rs_sel_d_reg && regfile_we_w_reg && r1re_d_reg)? out_alu_w_reg: rs;//wd bypass,(on d stage)
   assign rt_wd_d=(rd_w == rt_sel_d_reg && regfile_we_w_reg && r2re_d_reg)? out_alu_w_reg: rt;
  /*..............bypass_end...................*/


   lc4_alu m1(insn_x,pc_x,rs_alu,rt_alu, out_alu);

   wire [15:0] out_alu_m_reg,out_alu_w_reg;
   Nbit_reg #(16, 16'b0) alu_reg_m (.in(out_alu), .out(out_alu_m_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 16'b0) alu_reg_w (.in(out_alu_m_reg), .out(out_alu_w_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));

   wire [15:0] dmem_data_d_reg;
   Nbit_reg #(16, 16'b0) dmem_data_reg_d (.in(i_cur_dmem_data), .out(dmem_data_d_reg), .clk(clk), .we(pipeline_reg_enable), .gwe(gwe), .rst(rst));

   assign regfile_wr=(is_load_x_reg)? dmem_data_d_reg : ((select_pc_plus_one_w_reg)?pc_plus_one : out_alu_w_reg ); // in w stage?
   assign o_dmem_addr=(is_load_d_reg | is_store_d_reg )?out_alu_w_reg : 16'b0;
   assign o_dmem_towrite=(is_store_d_reg)? rt_alu : 16'b0;
   assign o_dmem_we=(is_store_d_reg);

   
   wire br_is_jump;
   assign br_is_jump=( (i_cur_insn[15:12]==4'b0000) & (last_nzp[2]&i_cur_insn[11] | (last_nzp[1]&i_cur_insn[10]) | last_nzp[0]&i_cur_insn[9]) );
   
   assign next_pc=(is_control_insn_d_reg |  (is_branch_d_reg & br_is_jump)  )? out_alu_w_reg : pc_plus_one;
   assign o_cur_pc=pc;
 
   assign nzp_data[2]= (regfile_wr[15]==1'b1) ; //n
   assign nzp_data[1]=(regfile_wr)? 1'b0 : 1'b1;     //z
   assign nzp_data[0]=( (regfile_wr[15]==0) & (regfile_wr!=0));//p

   assign test_stall = (insn_w == 16'b0)? 2'd2:2'd0;
   assign test_cur_pc=pc_w;
   assign test_cur_insn=insn_w;
   assign test_regfile_we=regfile_we_w_reg;
   assign test_regfile_wsel=rd_w;
   assign test_regfile_data=regfile_wr;
   assign test_nzp_we=nzp_we_w_reg;
   assign test_nzp_new_bits=( nzp_we_w_reg)? nzp_data: 3'b0;

   assign test_dmem_we=o_dmem_we; 
   assign test_dmem_addr=o_dmem_addr; 
   
   wire[15:0] dmem_out;//,dmem_in;
   assign dmem_out=(is_load_d_reg)?dmem_data_d_reg: 16'b0;
   assign test_dmem_data= o_dmem_towrite | dmem_out  ;
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
   if(pc <16'h8441) begin
      //$display("%h %d %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h", $time, pc-16'h8200,rs_alu,rt_alu,rs_sel_d_reg,rt_sel_d_reg,regfile_wr,test_regfile_wsel,rs, rt,rs_sel_x_reg, rd_w, rd_m,rt_sel_x_reg,out_alu,out_alu_w_reg,out_alu_m_reg,rs_content_wx,rs_content_mx,rt_content_mx,rt_content_wx,rs_wd_x);
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
