
/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);
      wire [15:0]  br1; 
      /*wire [15:0] add;wire [15:0] sub; */wire [15:0] mul;wire [15:0] div; //wire [15:0] add_imm;
      wire [15:0] cmp1,cmp2,cmp; wire [15:0] cmpu1,cmpu2,cmpu; wire [15:0] cmpi1,cmpi2,cmpi;wire [15:0] cmpiu1,cmpiu2,cmpiu;
      wire [15:0] and1;wire [15:0] not1; wire [15:0] or1;wire [15:0] xor1; wire [15:0] and_imm;
      wire [15:0] const1;
      wire [15:0] sll1;wire [15:0] sra1; wire [15:0] srl1;wire [15:0] mod1; 
      wire [15:0] hiconst1;
      wire [15:0] jmpr1;
      wire [15:0] jsrr; wire [15:0] jsr;
      wire [15:0] rti1;
      wire [15:0] trap1;
      
      wire [15:0] temp_remainder; wire [15:0] quotient;
      lc4_divider m1(i_r1data,i_r2data,temp_remainder,quotient);

      wire [15:0] cla_in1,cla_in2,br_1,br_2,add_1,add_2,sub_1,sub_2,add_imm_1,add_imm_2,mem_1,mem_2,jmp_1,jmp_2,cla_out,temp_cla,
      sub_cmp1,sub_cmp2;
      wire cin_br,cin_sub,cin_jmp,cin_cmp,cin; //3 inputs for cla

      // wire [10:0]   ext1; //imm5 for add_imm and and_imm
      // assign ext1=(i_insn[4]) ? 11'd2047: 11'b0 ;
      // wire [6:0]   ext2; //imm9 for const
      // assign ext2=(i_insn[8]) ? 7'd127: 7'b0 ;
      // wire [4:0]   ext3; //imm11 for jmp and jsr
      // assign ext3=(i_insn[10]) ? 5'd31: 5'b0 ;
      // wire [9:0]   ext4; //imm6 for add_imm and and_imm
      // assign ext4=(i_insn[5]) ? 10'd1023: 10'b0 ;
      // wire [8:0]   ext5; //imm7 for cmpiu
      // assign ext5=(i_insn[6]) ? 9'd511: 9'b0 ;


      //assign nop1=((i_insn[15:9]==7'b0) )? (i_pc + 1'b1) : 16'b0 ;
      //assign brp1=((i_insn[15:9]==7'b1) )? (i_pc+ {ext2,i_insn[8:0]}+1) : 16'b0 ;
      //assign br1=(i_insn[15:12]==4'b0 )? (i_pc+ {ext2,i_insn[8:0]}+1) : 16'b0 ;
      assign br_1=(i_insn[15:12]==4'b0 )? (i_pc) : 16'b0 ;
      assign br_2=(i_insn[15:12]==4'b0 )? ({{7{i_insn[8]}},i_insn[8:0]}) : 16'b0 ;
      assign cin_br=(i_insn[15:12]==4'b0 )? (1'b1) : 16'b0 ;

      assign add_1=((i_insn[15:12]==4'b0001) & (i_insn[5:3]==3'b000) )? (i_r1data) : 16'b0 ;
      assign add_2=((i_insn[15:12]==4'b0001) & (i_insn[5:3]==3'b000) )? (i_r2data) : 16'b0 ;
      assign mul=((i_insn[15:12]==4'b0001) & (i_insn[5:3]==3'b001) )? (i_r1data*i_r2data) : 16'b0 ;
      //assign sub=((i_insn[15:12]==4'b0001) & (i_insn[5:3]==3'b010) )? (sub_cla)  : 16'b0 ;
      assign sub_1=((i_insn[15:12]==4'b0001) & (i_insn[5:3]==3'b010) )? (i_r1data)  : 16'b0 ;
      assign sub_2=((i_insn[15:12]==4'b0001) & (i_insn[5:3]==3'b010) )? (~i_r2data)  : 16'b0 ;
      assign cin_sub=((i_insn[15:12]==4'b0001) & (i_insn[5:3]==3'b010) )? (1'b1)  : 16'b0 ;
      assign div=((i_insn[15:12]==4'b0001) & (i_insn[5:3]==3'b011) )? (quotient/*i_r1data/i_r2data*/) : 16'b0 ;
      //assign add_imm=((i_insn[15:12]==4'b0001) & (i_insn[5]==1) )? ((i_r1data)+ ( { ext1,i_insn[4:0]} )) : 16'b0 ;
      assign add_imm_1=((i_insn[15:12]==4'b0001) & (i_insn[5]==1) )? ((i_r1data) ) : 16'b0 ;
      assign add_imm_2=((i_insn[15:12]==4'b0001) & (i_insn[5]==1) )? (( { {11{i_insn[4]}},i_insn[4:0]} )) : 16'b0 ;

      assign cmp1=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b00) &  ($signed(i_r1data) >$signed(i_r2data) ))? 16'b1  : 16'b0 ;
      assign cmp2=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b00) &  ($signed(i_r1data) <$signed(i_r2data) ))? 16'd65535 : 16'b0 ;
      assign cmp=cmp1 | cmp2;
      //assign sub_cmp1=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b00) )? $signed(i_r1data)  : 16'b0 ;
      //assign sub_cmp2=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b00) )? $signed(i_r2data)  : 16'b0 ;
      //assign cin_cmp=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b00) )? 1'b1 : 1'b0 ;

      assign cmpu1=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b01) & ( i_r1data >i_r2data ))? 16'b1  : 16'b0 ;
      assign cmpu2=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b01) &  (i_r1data <i_r2data ))? 16'd65535 : 16'b0 ;
      assign cmpu=cmpu1 | cmpu2;
      //assign cmpu1=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b01) )? ( (i_r1data > i_r2data)? 1 : 16'd65535 ) : 16'b0 ;
      //assign cmpi1=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b10) )? (($signed(i_r1data) > $signed({ext5,i_insn[6:0]}) )? 16'b1 : 16'd65535 ) : 16'b0 ;
      assign cmpi1=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b10) & ( $signed(i_r1data) > $signed({{9{i_insn[6]}},i_insn[6:0]}) ))? 16'b1  : 16'b0 ;
      assign cmpi2=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b10) &  ($signed(i_r1data) < $signed({{9{i_insn[6]}},i_insn[6:0]}) ))? 16'd65535 : 16'b0 ;
      assign cmpi=cmpi1 | cmpi2;
      //assign cmpiu1=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b11) )? ((i_r1data > i_insn[6:0])? 16'b1 : 16'd65535 ) : 16'b0 ;
      assign cmpiu1=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b11) & ( i_r1data > i_insn[6:0] ))? 16'b1  : 16'b0 ;
      assign cmpiu2=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b11) &  (i_r1data < i_insn[6:0] ))? 16'd65535 : 16'b0 ;
      assign cmpiu=cmpiu1 | cmpiu2;

      assign and1=((i_insn[15:12]==4'b0101) & (i_insn[5:3]==3'b000) )? (i_r1data & i_r2data) : 16'b0 ;
      assign not1=((i_insn[15:12]==4'b0101) & (i_insn[5:3]==3'b001) )? (~i_r1data ) : 16'b0 ;
      assign or1=((i_insn[15:12]==4'b0101) & (i_insn[5:3]==3'b010) )? (i_r1data | i_r2data) : 16'b0 ;
      assign xor1=((i_insn[15:12]==4'b0101) & (i_insn[5:3]==3'b011) )? (i_r1data ^ i_r2data) : 16'b0 ;
      assign and_imm=((i_insn[15:12]==4'b0101) & (i_insn[5]==1'b1) )? (i_r1data) & {{11{i_insn[4]}},i_insn[4:0] }: 16'b0 ;

      // assign ldr1=((i_insn[15:12]==4'b0110)  )? (i_r1data +{ext4,i_insn[5:0]} ) : 16'b0 ;
      // assign str1=((i_insn[15:12]==4'b0111)  )? (i_r1data +{ext4,i_insn[5:0]}) : 16'b0 ;
      assign mem_1=((i_insn[15:12]==4'b0110) | (i_insn[15:12]==4'b0111)  )? (i_r1data ) : 16'b0 ;
      assign mem_2=((i_insn[15:12]==4'b0110) | (i_insn[15:12]==4'b0111)  )? ({{10{i_insn[5]}},i_insn[5:0]} ) : 16'b0 ;

      assign rti1=((i_insn[15:12]==4'b1000)  )? (i_r1data) : 16'b0 ;

      assign const1=((i_insn[15:12]==4'b1001) )? {{7{i_insn[8]}},i_insn[8:0] }: 16'b0 ;
      

      assign sll1=((i_insn[15:12]==4'b1010) & (i_insn[5:4]==2'b00) )? (i_r1data << i_insn[3:0] ): 16'b0 ;
      assign sra1=((i_insn[15:12]==4'b1010) & (i_insn[5:4]==2'b01) )? $signed( ( $signed(i_r1data) >>>i_insn[3:0] )) : 16'b0 ;
      assign srl1=((i_insn[15:12]==4'b1010) & (i_insn[5:4]==2'b10) )? (i_r1data >> i_insn[3:0]) : 16'b0 ;
      assign mod1=((i_insn[15:12]==4'b1010) & (i_insn[5:4]==2'b11) )? (i_r1data % i_r2data) : 16'b0 ;

      assign hiconst1=((i_insn[15:12]==4'b1101)  )? (i_r1data & 8'hff | i_insn[7:0] << 8) : 16'b0 ;
      
      assign jmpr1=((i_insn[15:11]==5'b11000)  )? (i_r1data) : 16'b0 ;
      // assign jmp1=((i_insn[15:11]==5'b11001)  )? (i_pc+1'b1+{ext3,i_insn[10:0] } ): 16'b0 ; 
      assign jmp_1=((i_insn[15:11]==5'b11001)  )? (i_pc ): 16'b0 ; 
      assign jmp_2=((i_insn[15:11]==5'b11001)  )? ({{5{i_insn[10]}},i_insn[10:0] } ): 16'b0 ; 
      assign cin_jmp=((i_insn[15:11]==5'b11001)  )? (1'b1  ): 16'b0 ; 

      assign jsrr=(i_insn[15:11]==5'b01000) ? (i_r1data ) : 16'b0;
      assign jsr=(i_insn[15:11]==5'b01001) ? (i_pc & 16'h8000 ) | ( i_insn[10:0] << 4  ) : 16'b0;

      assign trap1=((i_insn[15:12]==4'b1111)  )? (16'h8000 |( i_insn[7:0]) ) : 16'b0 ;

      assign cla_in1=br_1 | add_1 | sub_1 | add_imm_1 | mem_1 | jmp_1 ;//|sub_cmp1;
      assign cla_in2=br_2| add_2 | sub_2 | add_imm_2 | mem_2 | jmp_2 ;//|sub_cmp2;
      assign cin=cin_br |cin_sub | cin_jmp ;//| cin_cmp;

      cla16 m2(cla_in1,cla_in2,cin,temp_cla);

      assign cla_out=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b00) )?  16'b0: temp_cla;
      //assign cmp1=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b00)  & (temp_cla[15]==0) )? 16'b1 : 16'b0 ;
      //assign cmp2=((i_insn[15:12]==4'b0010) & (i_insn[8:7]==2'b00)  & (temp_cla[15]==1) )? 16'd65535: 16'b0 ;
      //assign cmp=cmp1|cmp2;

      assign o_result=cla_out| mul | div /*| sub | add_imm */| and1 | not1 | or1 | xor1| and_imm | const1 | sll1 | sra1 | srl1 | mod1 | hiconst1 
      |jmpr1 /*|jmp1*/ | jsrr | jsr /*| br1*/ | rti1 | trap1 /*|ldr1 | str1*/ | cmp | cmpu | cmpi | cmpiu;
endmodule