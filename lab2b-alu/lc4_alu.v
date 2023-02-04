/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);

      // wire [15:0]  nop1; 
      wire [15:0]  br1;

      wire [15:0] add; wire [15:0] sub; wire [15:0] mul;wire [15:0] div; wire [15:0] add_imm;

      wire [15:0] cmp1, cmp2, cmp; wire [15:0] cmpu1, cmpu2, cmpu; wire [15:0] cmpi1, cmpi2, cmpi; wire [15:0] cmpiu1, cmpiu2, cmpiu;

      wire [15:0] jsrr; wire [15:0] jsr;
      
      wire [15:0] and1; wire [15:0] not1; wire [15:0] or1; wire [15:0] xor1; wire [15:0] and_imm;

      wire [15:0] ldr1; wire [15:0] str1;

      wire [15:0] rti1;

      wire [15:0] const1;

      wire [15:0] sll1; wire [15:0] sra1; wire [15:0] srl1; wire [15:0] mod1;

      wire [15:0] jmpr1; wire [15:0] jmp1;

      wire [15:0] hiconst1;

      wire [15:0] trap1;
      
      
      wire [15:0] temp_remainder; wire [15:0] quotient;
      lc4_divider m1(i_r1data, i_r2data, temp_remainder, quotient);
      
      wire [15:0] add_cla;
      wire cin; assign cin = 0;
      cla16 m2(i_r1data, i_r2data, cin, add_cla);

      wire [10:0]  sext1; //sign extension for IMM5 for add_imm and and_imm
      assign sext1 = (i_insn[4]) ? 11'd4095 : 11'b0 ;
      wire [6:0]   sext2; //sign extension for IMM9 
      assign sext2 = (i_insn[8]) ? 7'd255 : 7'b0 ; //判断第九位是0还是1
      wire [4:0]   sext3; //sign extension for IMM11 for jmp and jsr
      assign sext3 = (i_insn[10]) ? 5'd255 : 5'b0 ;
      wire [9:0]   sext4; //sign extension for IMM6 for add_imm and and_imm
      assign sext4 = (i_insn[5]) ? 10'd2047 : 10'b0 ;
      wire [8:0]   sext5; //sign extension for IMM7 for cmpiu
      assign sext5 = (i_insn[6]) ? 9'd1023 : 9'b0 ;

      // ？前是select，？后面就是两个输入，: 前是满足条件的结果，: 后是不满足条件的结果
      assign br1 = (i_insn[15:12] == 4'b0 ) ? (i_pc + {sext2, i_insn[8:0]} + 1) : 16'b0 ;

      assign add = ((i_insn[15:12] == 4'b0001) & (i_insn[5:3] == 3'b000) ) ? (add_cla) : 16'b0 ;
      assign mul = ((i_insn[15:12] == 4'b0001) & (i_insn[5:3] == 3'b001) ) ? (i_r1data * i_r2data) : 16'b0 ;
      assign sub = ((i_insn[15:12] == 4'b0001) & (i_insn[5:3] == 3'b010) ) ? (i_r1data - i_r2data) : 16'b0 ; // 不允许用减号
      assign div = ((i_insn[15:12] == 4'b0001) & (i_insn[5:3] == 3'b011) ) ? (quotient) : 16'b0 ;
      assign add_imm = ((i_insn[15:12] == 4'b0001) & (i_insn[5] == 1) ) ? ((i_r1data) + ( {sext1, i_insn[4:0]} )) : 16'b0 ; //调用cla

      //怎样包含等于的情况不会出错
      assign cmp1   = ((i_insn[15:12] == 4'b0010) & (i_insn[8:7] == 2'b00) & ($signed(i_r1data) > $signed(i_r2data) )) ? 16'b1  : 16'b0 ;
      assign cmp2   = ((i_insn[15:12] == 4'b0010) & (i_insn[8:7] == 2'b00) & ($signed(i_r1data) < $signed(i_r2data) )) ? 16'd65535 : 16'b0 ;
      assign cmp    = cmp1 | cmp2;    
      assign cmpu1  = ((i_insn[15:12] == 4'b0010) & (i_insn[8:7] == 2'b01) & ( i_r1data > i_r2data )) ? 16'b1  : 16'b0 ;
      assign cmpu2  = ((i_insn[15:12] == 4'b0010) & (i_insn[8:7] == 2'b01) &  (i_r1data < i_r2data )) ? 16'd65535 : 16'b0 ;
      assign cmpu   = cmpu1 | cmpu2;     
      assign cmpi1  = ((i_insn[15:12] == 4'b0010) & (i_insn[8:7] == 2'b10) & ( $signed(i_r1data) > $signed({sext5,i_insn[6:0]}) )) ? 16'b1  : 16'b0 ;
      assign cmpi2  = ((i_insn[15:12] == 4'b0010) & (i_insn[8:7] == 2'b10) &  ($signed(i_r1data) < $signed({sext5,i_insn[6:0]}) )) ? 16'd65535 : 16'b0 ;
      assign cmpi   = cmpi1 | cmpi2;     
      assign cmpiu1 = ((i_insn[15:12] == 4'b0010) & (i_insn[8:7] == 2'b11) & ( i_r1data > i_insn[6:0] )) ? 16'b1  : 16'b0 ;
      assign cmpiu2 = ((i_insn[15:12] == 4'b0010) & (i_insn[8:7] == 2'b11) &  (i_r1data < i_insn[6:0] )) ? 16'd65535 : 16'b0 ;
      assign cmpiu  = cmpiu1 | cmpiu2;

      assign jsrr = (i_insn[15:11] == 5'b01000) ? (i_r1data) : 16'b0;
      assign jsr  = (i_insn[15:11] == 5'b01001) ? (i_pc & 16'h8000) | (i_insn[10:0] << 4) : 16'b0;

      assign and1 = ((i_insn[15:12]==4'b0101) & (i_insn[5:3]==3'b000)) ? (i_r1data & i_r2data) : 16'b0 ;
      assign not1 = ((i_insn[15:12]==4'b0101) & (i_insn[5:3]==3'b001)) ? (~i_r1data) : 16'b0 ;
      assign or1  = ((i_insn[15:12]==4'b0101) & (i_insn[5:3]==3'b010)) ? (i_r1data | i_r2data) : 16'b0 ;
      assign xor1 = ((i_insn[15:12]==4'b0101) & (i_insn[5:3]==3'b011)) ? (i_r1data ^ i_r2data) : 16'b0 ;
      assign and_imm = ((i_insn[15:12]==4'b0101) & (i_insn[5]==1'b1)) ? (i_r1data) & {sext1, i_insn[4:0]}: 16'b0 ;

      assign ldr1 = ((i_insn[15:12] == 4'b0110)) ? (i_r1data + {sext4, i_insn[5:0]}) : 16'b0 ;  //Rd =  //call cla
      assign str1 = ((i_insn[15:12] == 4'b0111)) ? (i_r1data + {sext4, i_insn[5:0]}) : 16'b0 ;  //call cla

      assign rti1 = ((i_insn[15:12] == 4'b1000)) ? (i_r1data) : 16'b0 ;

      assign const1 = ((i_insn[15:12] == 4'b1001)) ? {sext2,i_insn[8:0] } : 16'b0 ;

      assign sll1 = ((i_insn[15:12] == 4'b1010) & (i_insn[5:4]==2'b00) ) ? (i_r1data << i_insn[3:0] ): 16'b0 ;
      assign sra1 = ((i_insn[15:12] == 4'b1010) & (i_insn[5:4]==2'b01) ) ? $signed($signed(i_r1data) >>> i_insn[3:0]) : 16'b0 ;
      assign srl1 = ((i_insn[15:12] == 4'b1010) & (i_insn[5:4]==2'b10) ) ? (i_r1data >> i_insn[3:0]) : 16'b0 ;
      assign mod1 = ((i_insn[15:12] == 4'b1010) & (i_insn[5:4]==2'b11) ) ? (i_r1data % i_r2data) : 16'b0 ;  //use divider

      assign jmpr1 = ((i_insn[15:11]==5'b11000)) ? (i_r1data) : 16'b0 ;
      assign jmp1  = ((i_insn[15:11]==5'b11001)) ? (i_pc+1'b1+{sext3,i_insn[10:0] } ): 16'b0 ; 

      assign hiconst1 = ((i_insn[15:12]==4'b1101)) ? (i_r1data & 8'hff | i_insn[7:0] << 8) : 16'b0 ;
      
      assign trap1=((i_insn[15:12]==4'b1111)  )? (16'h8000 |( i_insn[7:0]) ) : 16'b0 ;

      assign o_result = br1 | add | mul | sub | div | add_imm
                        | cmp | cmpu | cmpi | cmpiu
                        | jsrr | jsr
                        | and1 | not1 | or1 | xor1| and_imm
                        | ldr1 | str1
                        | rti1
                        | const1 
                        | sll1 | sra1 | srl1 | mod1 
                        | jmpr1 |jmp1 
                        | hiconst1 
                        | trap1  ;

endmodule

