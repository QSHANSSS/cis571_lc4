/* TODO: Lihong Zhao: lihzhao, Shuhan Qian: qiansh  (Name:Pennkey) */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      //wire [15:0] temp0_remainder;
      //wire [15:0] temp0_quotient;
      // wire [15:0] temp0_dividend;
      wire [15:0] temp1_remainder;
      wire [15:0] temp1_quotient;
      wire [15:0] temp1_dividend;
      wire [15:0] temp2_remainder;
      wire [15:0] temp2_quotient;
      wire [15:0] temp2_dividend;
      wire [15:0] temp3_remainder;
      wire [15:0] temp3_quotient;
      wire [15:0] temp3_dividend;
      wire [15:0] temp4_remainder;
      wire [15:0] temp4_quotient;
      wire [15:0] temp4_dividend;
      wire [15:0] temp5_remainder;
      wire [15:0] temp5_quotient;
      wire [15:0] temp5_dividend;
      wire [15:0] temp6_remainder;
      wire [15:0] temp6_quotient;
      wire [15:0] temp6_dividend;
      wire [15:0] temp7_remainder;
      wire [15:0] temp7_quotient;
      wire [15:0] temp7_dividend;
      wire [15:0] temp8_remainder;
      wire [15:0] temp8_quotient;
      wire [15:0] temp8_dividend;
      wire [15:0] temp9_remainder;
      wire [15:0] temp9_quotient;
      wire [15:0] temp9_dividend;
      wire [15:0] temp10_remainder;
      wire [15:0] temp10_quotient;
      wire [15:0] temp10_dividend;
      wire [15:0] temp11_remainder;
      wire [15:0] temp11_quotient;
      wire [15:0] temp11_dividend;
      wire [15:0] temp12_remainder;
      wire [15:0] temp12_quotient;
      wire [15:0] temp12_dividend;
      wire [15:0] temp13_remainder;
      wire [15:0] temp13_quotient;
      wire [15:0] temp13_dividend;
      wire [15:0] temp14_remainder;
      wire [15:0] temp14_quotient;
      wire [15:0] temp14_dividend;
      wire [15:0] temp15_remainder;
      wire [15:0] temp15_quotient;
      wire [15:0] temp15_dividend;
      wire [15:0] temp16_dividend;
      wire [15:0] temp16_remainder;
      wire [15:0] temp16_quotient;

      
      lc4_divider_one_iter m0(i_dividend[15:0],i_divisor[15:0],
                              16'b0,16'b0,temp1_dividend[15:0],
                              temp1_remainder[15:0],temp1_quotient[15:0] );                                 
      lc4_divider_one_iter m1(temp1_dividend[15:0],i_divisor[15:0],
                              temp1_remainder[15:0],temp1_quotient[15:0],temp2_dividend[15:0],
                              temp2_remainder[15:0],temp2_quotient[15:0] );   
      lc4_divider_one_iter m2(temp2_dividend[15:0],i_divisor[15:0],
                              temp2_remainder[15:0],temp2_quotient[15:0],temp3_dividend[15:0],
                              temp3_remainder[15:0],temp3_quotient[15:0] );                                  
      lc4_divider_one_iter m3(temp3_dividend[15:0],i_divisor[15:0],
                              temp3_remainder[15:0],temp3_quotient[15:0],temp4_dividend[15:0],
                              temp4_remainder[15:0],temp4_quotient[15:0] );                                                     
      lc4_divider_one_iter m4(temp4_dividend[15:0],i_divisor[15:0],
                              temp4_remainder[15:0],temp4_quotient[15:0],temp5_dividend[15:0],
                              temp5_remainder[15:0],temp5_quotient[15:0] );                                 
      lc4_divider_one_iter m5(temp5_dividend[15:0],i_divisor[15:0],
                              temp5_remainder[15:0],temp5_quotient[15:0],temp6_dividend[15:0],
                              temp6_remainder[15:0],temp6_quotient[15:0] );   
      lc4_divider_one_iter m6(temp6_dividend[15:0],i_divisor[15:0],
                              temp6_remainder[15:0],temp6_quotient[15:0],temp7_dividend[15:0],
                              temp7_remainder[15:0],temp7_quotient[15:0] );                                  
      lc4_divider_one_iter m7(temp7_dividend[15:0],i_divisor[15:0],
                              temp7_remainder[15:0],temp7_quotient[15:0],temp8_dividend[15:0],
                              temp8_remainder[15:0],temp8_quotient[15:0] );                           
      lc4_divider_one_iter m8(temp8_dividend[15:0],i_divisor[15:0],
                              temp8_remainder[15:0],temp8_quotient[15:0],temp9_dividend[15:0],
                              temp9_remainder[15:0],temp9_quotient[15:0] );                                 
      lc4_divider_one_iter m9(temp9_dividend[15:0],i_divisor[15:0],
                              temp9_remainder[15:0],temp9_quotient[15:0],temp10_dividend[15:0],
                              temp10_remainder[15:0],temp10_quotient[15:0] ); 
      lc4_divider_one_iter m10(temp10_dividend[15:0],i_divisor[15:0],
                              temp10_remainder[15:0],temp10_quotient[15:0],temp11_dividend[15:0],
                              temp11_remainder[15:0],temp11_quotient[15:0] );   
      lc4_divider_one_iter m11(temp11_dividend[15:0],i_divisor[15:0],
                              temp11_remainder[15:0],temp11_quotient[15:0],temp12_dividend[15:0],
                              temp12_remainder[15:0],temp12_quotient[15:0] );                                
      lc4_divider_one_iter m12(temp12_dividend[15:0],i_divisor[15:0],
                              temp12_remainder[15:0],temp12_quotient[15:0],temp13_dividend[15:0],
                              temp13_remainder[15:0],temp13_quotient[15:0] );                                                     
      lc4_divider_one_iter m13(temp13_dividend[15:0],i_divisor[15:0],
                              temp13_remainder[15:0],temp13_quotient[15:0],temp14_dividend[15:0],
                              temp14_remainder[15:0],temp14_quotient[15:0] );                                 
      lc4_divider_one_iter m14(temp14_dividend[15:0],i_divisor[15:0],
                              temp14_remainder[15:0],temp14_quotient[15:0],temp15_dividend[15:0],
                              temp15_remainder[15:0],temp15_quotient[15:0] );   
      lc4_divider_one_iter m15(temp15_dividend[15:0],i_divisor[15:0],
                              temp15_remainder[15:0],temp15_quotient[15:0],temp16_dividend[15:0],
                              temp16_remainder[15:0],temp16_quotient[15:0] );                                  
      assign o_quotient=(i_divisor)? temp16_quotient : 16'b0 ;
      assign o_remainder=(i_divisor)? temp16_remainder : 16'b0;

endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      wire [15:0] temp_remainder;
      assign temp_remainder= ( i_remainder << 1 ) | ( (i_dividend >> 4'b1111 ) &  1 );
      assign o_quotient=(i_divisor > temp_remainder) ? (i_quotient << 1) : ( (i_quotient << 1)| 1'b1 );
      assign o_remainder=(i_divisor > temp_remainder) ? (temp_remainder) : (temp_remainder-i_divisor);
      assign o_dividend=i_dividend << 1;
endmodule