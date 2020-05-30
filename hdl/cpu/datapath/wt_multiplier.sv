// //macros to make my life easier (didnt want to make madules)
// //half adder sum
// `define ha_sum(A,B) ``A``^``B``
// //half adder carry
// `define ha_c(A,B) ``A``&``B``
// //full adder sum
// `define fa_sum(A,B,C) ``A``^``B``^``C``
// //full adder carry
// `define fa_c(A,B,C) ((``A``^``B``)&``C``)|(``A``&``B``)

module CSA (
	input logic [63:0] x,y,z,
	output logic [63:0] c, s
);

always_comb begin
	for (int i = 0; i<64; i++) begin
		// s[i] = fa_sum(x[i], y[i], z[i]);
		s[i] = ((x[i]^y[i])^z[i]);
	end
	for (int i = 0; i<63; i++) begin
		// c[i+1] = fa_c(x[i], y[i], z[i]);
		c[i+1] = ( (x[i]&y[i]) | ( (x[i]^y[i])&z[i] ) );
	end
	c[0]=1'b0;
end
endmodule

module multiplier(
	input clk,
	input [31:0] a_t,b_t,
	output logic [63:0] out
);
logic [31:0] a, b;
logic [63:0] pp_row[32];
logic [63:0] c[30];	//carry arrays
logic [63:0] s[30];	//sum array

always_ff @(posedge clk) begin
	a <= a_t;
	b <= b_t;
end
//STAGE 1 PARTIAL PRODUCTS
always_comb begin
	//for (int i = 0; i<32; i++) begin
		//pp_row[i] = { {(32-i){1'b0}}, {a&{32{b[i]}}}, {(i){1'b0}} };
	//end
	pp_row[0] = { {32{1'b0}}, {a&{32{b[0]}}}, {0{1'b0}} };
	pp_row[1] = { {31{1'b0}}, {a&{32{b[1]}}}, {1{1'b0}} };
	pp_row[2] = { {30{1'b0}}, {a&{32{b[2]}}}, {2{1'b0}} };
	pp_row[3] = { {29{1'b0}}, {a&{32{b[3]}}}, {3{1'b0}} };
	pp_row[4] = { {28{1'b0}}, {a&{32{b[4]}}}, {4{1'b0}} };
	pp_row[5] = { {27{1'b0}}, {a&{32{b[5]}}}, {5{1'b0}} };
	pp_row[6] = { {26{1'b0}}, {a&{32{b[6]}}}, {6{1'b0}} };
	pp_row[7] = { {25{1'b0}}, {a&{32{b[7]}}}, {7{1'b0}} };
	pp_row[8] = { {24{1'b0}}, {a&{32{b[8]}}}, {8{1'b0}} };
	pp_row[9] = { {23{1'b0}}, {a&{32{b[9]}}}, {9{1'b0}} };
	pp_row[10] = { {22{1'b0}}, {a&{32{b[10]}}}, {10{1'b0}} };
	pp_row[11] = { {21{1'b0}}, {a&{32{b[11]}}}, {11{1'b0}} };
	pp_row[12] = { {20{1'b0}}, {a&{32{b[12]}}}, {12{1'b0}} };
	pp_row[13] = { {19{1'b0}}, {a&{32{b[13]}}}, {13{1'b0}} };
	pp_row[14] = { {18{1'b0}}, {a&{32{b[14]}}}, {14{1'b0}} };
	pp_row[15] = { {17{1'b0}}, {a&{32{b[15]}}}, {15{1'b0}} };
	pp_row[16] = { {16{1'b0}}, {a&{32{b[16]}}}, {16{1'b0}} };
	pp_row[17] = { {15{1'b0}}, {a&{32{b[17]}}}, {17{1'b0}} };
	pp_row[18] = { {14{1'b0}}, {a&{32{b[18]}}}, {18{1'b0}} };
	pp_row[19] = { {13{1'b0}}, {a&{32{b[19]}}}, {19{1'b0}} };
	pp_row[20] = { {12{1'b0}}, {a&{32{b[20]}}}, {20{1'b0}} };
	pp_row[21] = { {11{1'b0}}, {a&{32{b[21]}}}, {21{1'b0}} };
	pp_row[22] = { {10{1'b0}}, {a&{32{b[22]}}}, {22{1'b0}} };
	pp_row[23] = { {9{1'b0}}, {a&{32{b[23]}}}, {23{1'b0}} };
	pp_row[24] = { {8{1'b0}}, {a&{32{b[24]}}}, {24{1'b0}} };
	pp_row[25] = { {7{1'b0}}, {a&{32{b[25]}}}, {25{1'b0}} };
	pp_row[26] = { {6{1'b0}}, {a&{32{b[26]}}}, {26{1'b0}} };
	pp_row[27] = { {5{1'b0}}, {a&{32{b[27]}}}, {27{1'b0}} };
	pp_row[28] = { {4{1'b0}}, {a&{32{b[28]}}}, {28{1'b0}} };
	pp_row[29] = { {3{1'b0}}, {a&{32{b[29]}}}, {29{1'b0}} };
	pp_row[30] = { {2{1'b0}}, {a&{32{b[30]}}}, {30{1'b0}} };
	pp_row[31] = { {1{1'b0}}, {a&{32{b[31]}}}, {31{1'b0}} };


	out = c[29] + s[29];
end

//STAGE 2 
//iter 1
CSA csa0(.x(pp_row[0]), .y(pp_row[1]), .z(pp_row[2]), .c(c[0]), .s(s[0]));
CSA csa1(.x(pp_row[3]), .y(pp_row[4]), .z(pp_row[5]), .c(c[1]), .s(s[1]));
CSA csa2(.x(pp_row[6]), .y(pp_row[7]), .z(pp_row[8]), .c(c[2]), .s(s[2]));
CSA csa3(.x(pp_row[9]), .y(pp_row[10]), .z(pp_row[11]), .c(c[3]), .s(s[3]));
CSA csa4(.x(pp_row[12]), .y(pp_row[13]), .z(pp_row[14]), .c(c[4]), .s(s[4]));
CSA csa5(.x(pp_row[15]), .y(pp_row[16]), .z(pp_row[17]), .c(c[5]), .s(s[5]));
CSA csa6(.x(pp_row[18]), .y(pp_row[19]), .z(pp_row[20]), .c(c[6]), .s(s[6]));
CSA csa7(.x(pp_row[21]), .y(pp_row[22]), .z(pp_row[23]), .c(c[7]), .s(s[7]));
CSA csa8(.x(pp_row[24]), .y(pp_row[25]), .z(pp_row[26]), .c(c[8]), .s(s[8]));
CSA csa9(.x(pp_row[27]), .y(pp_row[28]), .z(pp_row[29]), .c(c[9]), .s(s[9]));
//pp_row[30] and pp_row[31] still here

//iter 2
CSA csa10( .x( c[0] ), .y( s[0] ), .z( c[1] ),			.c(c[10]), .s(s[10]) );
CSA csa11( .x( s[1] ), .y( c[2] ), .z( s[2] ),			.c(c[11]), .s(s[11]) );
CSA csa12( .x( c[3] ), .y( s[3] ), .z( c[4] ), 			.c(c[12]), .s(s[12]) );
CSA csa13( .x( s[4] ), .y( c[5] ), .z( s[5] ), 			.c(c[13]), .s(s[13]) );
CSA csa14( .x( c[6] ), .y( s[6] ), .z( c[7] ), 			.c(c[14]), .s(s[14]) );
CSA csa15( .x( s[7] ), .y( c[8] ), .z( s[8] ), 			.c(c[15]), .s(s[15]) );
CSA csa16( .x( c[9] ), .y( s[9] ), .z( pp_row[30] ), 	.c(c[16]), .s(s[16]) );
//pp_row[31] still here

//iter 3
CSA csa17( .x( c[10] ), .y( s[10] ), .z( c[11] ), 		.c(c[17]), .s(s[17]) );
CSA csa18( .x( s[11] ), .y( c[12] ), .z( s[12] ), 		.c(c[18]), .s(s[18]) );
CSA csa19( .x( c[13] ), .y( s[13] ), .z( c[14] ), 		.c(c[19]), .s(s[19]) );
CSA csa20( .x( s[14] ), .y( c[15] ), .z( s[15] ), 		.c(c[20]), .s(s[20]) );
CSA csa21( .x( c[16] ), .y( s[16] ), .z( pp_row[31] ), 	.c(c[21]), .s(s[21]) );

//iter 4
CSA csa22( .x( c[17] ), .y( s[17] ), .z( c[18] ), 		.c(c[22]), .s(s[22]) );
CSA csa23( .x( s[18] ), .y( c[19] ), .z( s[19] ), 		.c(c[23]), .s(s[23]) );
CSA csa24( .x( c[20] ), .y( s[20] ), .z( c[21] ), 		.c(c[24]), .s(s[24]) );
//s[21] still here

//iter 5
CSA csa25( .x( c[22] ), .y( s[22] ), .z( c[23] ), 		.c(c[25]), .s(s[25]) );
CSA csa26( .x( s[23] ), .y( c[24] ), .z( s[24] ), 		.c(c[26]), .s(s[26]) );
//s[21] still here

//iter 6
CSA csa27( .x( c[25] ), .y( s[25] ), .z( c[26] ), 		.c(c[27]), .s(s[27]) );
//s[21] and s[26]

//iter 7
CSA csa28( .x( c[27] ), .y( s[27] ), .z( s[21] ), 		.c(c[28]), .s(s[28]) );
//s[26] still here

//iter 8
CSA csa29( .x( c[28] ), .y( s[28] ), .z( s[26] ), 		.c(c[29]), .s(s[29]) );

endmodule : multiplier
