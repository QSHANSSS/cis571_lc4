
/* Group Name: Shuhan Qian Pennkey:qiansh   
   Group Name: Lihong Zhao Pennkey:lihzhao 
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // Testbench signals are used by the testbench to verify the correctness of your datapath.
    // Many of these signals simply export internal processor state for verification (such as the PC).
    // Some signals are duplicate output signals for clarity of purpose.
    //
    // Don't forget to include these in your schematic!

    output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
    );

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
   assign test_stall = 2'b0; 

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)
   wire [15:0] pc_plus_one;
   wire [2:0] nzp_data, last_nzp,nzp_temp;
   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3, 3'b010) nzp_reg (.in(nzp_data), .out(last_nzp), .clk(clk), .we(nzp_we), .gwe(gwe), .rst(rst));
   /* END DO NOT MODIFY THIS CODE */


   /*******************************
    * TODO: INSERT YOUR CODE HERE *
    *******************************/
    wire [2:0] rs_sel,rd_sel,rt_sel;
    wire [15:0] rs,rd,rt,out_alu,regfile_wr,temp1_regfile_wr,temp2_regfile_wr,temp3_regfile_wr;
    wire r1re,r2re,regfile_we,nzp_we,select_pc_plus_one,is_load,is_store,is_branch,is_control_insn;
   
   lc4_decoder insn_decoder(i_cur_insn,rs_sel, r1re,rt_sel,r2re,rd_sel,
   regfile_we,nzp_we,select_pc_plus_one,is_load,is_store,is_branch,is_control_insn);
  
   cla16 c0(pc,16'b0,1'b1,pc_plus_one);
   
   lc4_regfile m0(clk,gwe,rst,rs_sel,rs,rt_sel,rt,rd_sel,regfile_wr,regfile_we);
  
   lc4_alu m1(i_cur_insn,pc,(r1re)?rs:16'b0,(r2re)?rt:16'b0,out_alu);

   assign regfile_wr=(is_load)? i_cur_dmem_data : ((select_pc_plus_one)?pc_plus_one : out_alu );
  
   assign o_dmem_addr=(is_load | is_store )?out_alu : 16'b0;
   assign o_dmem_towrite=(is_store)? rt : 16'b0;
   assign o_dmem_we=(is_store);

   
   wire br_is_jump;
   assign br_is_jump=( (i_cur_insn[15:12]==4'b0000) & (last_nzp[2]&i_cur_insn[11] | (last_nzp[1]&i_cur_insn[10]) | last_nzp[0]&i_cur_insn[9]) );
   
   assign next_pc=(is_control_insn |  (is_branch & br_is_jump)  )? out_alu : pc_plus_one;
   assign o_cur_pc=pc;
 
   assign nzp_data[2]= (regfile_wr[15]==1'b1) ; //n
   assign nzp_data[1]=(regfile_wr)? 1'b0 : 1'b1;     //z
   assign nzp_data[0]=( (regfile_wr[15]==0) & (regfile_wr!=0));//p

   assign test_cur_pc=pc;
   assign test_cur_insn=i_cur_insn;
   assign test_regfile_we=regfile_we;
   assign test_regfile_wsel=rd_sel;
   assign test_regfile_data=regfile_wr;
   assign test_nzp_we=nzp_we;
   assign test_nzp_new_bits=( nzp_we)? nzp_data: 3'b0;

   assign test_dmem_we=o_dmem_we; 
   assign test_dmem_addr=o_dmem_addr; 
   
   wire[15:0] dmem_out;//,dmem_in;
   //assign dmem_in=(is_store)?rt: 16'b0;
   assign dmem_out=(is_load)?i_cur_dmem_data: 16'b0;
   assign test_dmem_data= o_dmem_towrite | dmem_out  ;
     
     
      /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    * 
    * To disable the entire block add the statement
    * `define NDEBUG
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
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
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      // $display();
   end
`endif
endmodule
