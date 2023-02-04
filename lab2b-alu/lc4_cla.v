/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);   

   assign gout=gin[3] | pin[3] & gin[2] | pin[3]&pin[2]&gin[1] | pin[3]&pin[2]&pin[1]&gin[0]; //G3-0 G7-4, G11-8.....
   assign pout=pin[3] & pin[2] & pin[1] & pin[0];//P3-0 , P7-4, P11-8,P15-12
   
   assign cout[0]=gin[0] | pin[0]&cin;   //c3 c2 c1; c7 c6 c5; c11 c10 c9; c15 c14 c13
   assign cout[1]=gin[1] | pin[1]&gin[0] | pin[1]&pin[0]&cin;
   assign cout[2]= gin[2] | (pin[2]&gin[1]) | (pin[2]&pin[1]&gin[0]) | (pin[2]&pin[1]&pin[0]&cin); //c1,c2,c3,c5,c6,c7,c9,c10,c11....
endmodule

/**
 * 16-bit Carry-Lookahead Adder

 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);
  wire [15:0] g;
  wire [15:0] p;
  wire [15:0] c;
  wire g_30,p_30; //G3-0, P3-0,G7-4, P7-4...
  wire g_74,p_74;
  wire g_118,p_118;
  wire g_1512,p_1512;
gp1 u1(a[0],b[0],g[0],p[0]); gp1 u2(a[1],b[1],g[1],p[1]); gp1 u3(a[2],b[2],g[2],p[2]); gp1 u4(a[3],b[3],g[3],p[3]);
gp1 u5(a[4],b[4],g[4],p[4]); gp1 u6(a[5],b[5],g[5],p[5]); gp1 u7(a[6],b[6],g[6],p[6]); gp1 u8(a[7],b[7],g[7],p[7]);
gp1 u9(a[8],b[8],g[8],p[8]); gp1 u10(a[9],b[9],g[9],p[9]); gp1 u11(a[10],b[10],g[10],p[10]); gp1 u12(a[11],b[11],g[11],p[11]);
gp1 u13(a[12],b[12],g[12],p[12]); gp1 u14(a[13],b[13],g[13],p[13]); gp1 u15(a[14],b[14],g[14],p[14]); gp1 u16(a[15],b[15],g[15],p[15]);

assign c[0]=cin;

gp4 m1(g[3:0],p[3:0],c[0],g_30,p_30,c[3:1]);
assign c[4]=g_30 | p_30 & cin;//c4

gp4 m2(g[7:4],p[7:4],c[4],g_74,p_74,c[7:5]);
assign c[8]=g_74 | (p_74 & g_30) | (p_74 & p_30 & cin);//c8

gp4 m3(g[11:8],p[11:8],c[8],g_118,p_118,c[11:9]);
assign c[12]=g_118 | (p_118 & g_74) | (p_118 & p_74 & g_30) | (p_118 & p_74 & p_30 & cin);//c12

gp4 m4(g[15:12],p[15:12],c[12],g_1512,p_1512,c[15:13]);
//assign c[16]=g_1512 | (p_1512 & g_118) | (p_1512 & p_118 & g_74) | (p_1512 & pwire [15:0] g;
  
assign sum= a ^ b ^ c[15:0]; 
endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module em   wire [15:0] g;
   wire [15:0] p;
 */
 
module gpn
 
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);
 parameter N = 4;
   wire [N:0] pp;
      wire  temp_gout;
      wire temp_pout;
      wire [N-2:0] temp_cout;
      genvar i;
      assign pp[N]=1'b1;
      assign temp_gout=gin[N-1];
      assign temp_pout=pin[N-1];
      for(i=N-1;i>0;i=i-1) begin
          assign pp[i]=pp[i+1] & pin[i];
          assign temp_gout=temp_gout |   pp[i] &gin[i-1] ;
          assign temp_pout=temp_pout & pin[i-1];
      end

      genvar j;
      assign temp_cout[0]=gin[0] | pin[0]*cin;
      for(j=1;j<=N-2;j=j+1) begin
          assign temp_cout[j]=gin[j] | pin[j]&temp_cout[j]; //CN=GN-1|PN-1&CN-1
      end
    assign gout=temp_gout;
    assign pout=temp_pout;
    assign cout=temp_cout;
endmodule
