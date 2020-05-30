import rv32i_types::*;

module alu
(
	input clk,
	input hazard_stall,
    input alu_ops aluop,
    input [31:0] a, b,
    output logic [31:0] f,
	 output logic [31:0] alu_target,
	output logic stall
);

//muliply regs
logic [31:0] mula, mulb;
logic [63:0] mul_out, temp;
//div regs
logic [31:0] diva, divb, divq, divr;
logic div_start, div_done;
logic prev_mul, curr_mul;

always_comb
begin
	// stall = ~div_done;
	alu_target = a + b;
	//mul
	mula = 32'd0;
	mulb = 32'd0;
	temp = 64'd0;
	curr_mul = '0;
	//div
	diva = 32'd0;
	divb = 32'd0;
    unique case (aluop)
        alu_add:  f = alu_target;
        alu_sll:  f = a << b[4:0];
        alu_sra:  f = $signed(a) >>> b[4:0];
        alu_sub:  f = a - b;
        alu_xor:  f = a ^ b;
        alu_srl:  f = a >> b[4:0];
        alu_or:   f = a | b;
        alu_and:  f = a & b;
		//mul
		alu_mul: begin
			curr_mul = 1'b1;
			mula = (a[31])? (~a)+1 : a;
			mulb = (b[31])? (~b)+1 : b;
			if (a[31]&b[31]) begin
				f = mul_out[31:0];	
			end
			else if (a[31] | b[31]) begin
				temp = (~mul_out)+1;
				f = temp[31:0];
			end else begin
				f = mul_out[31:0];
			end
		end
		alu_mulhs: begin
			curr_mul = 1'b1;
			mula = (a[31])? (~a)+1 : a;
			mulb = (b[31])? (~b)+1 : b;
			if (a[31]&b[31]) begin
				f = mul_out[63:32];	
			end
			else if (a[31] | b[31]) begin
				temp = (~mul_out)+1;
				f = temp[63:32];
			end else begin
				f = mul_out[63:32];
			end
		end
		alu_mulhsu: begin
			curr_mul = 1'b1;
			mula = (a[31])? (~a)+1 : a;
			mulb = b;
			temp = (a[31])? ~mul_out+1 : mul_out;
			f = temp[63:32];
		end
		alu_mulhu: begin
			curr_mul = 1'b1;
			mula = a;
			mulb = b;
			f = mul_out[63:32];
		end
		//div
		alu_div: begin
			diva = (a[31])? (~a)+1 : a;
			divb = (b[31])? (~b)+1 : b;
			if (a[31]&b[31]) begin
				f = divq;
			end
			else if (a[31] | b[31]) begin
				f = (~divq)+1;
			end else begin
				f = divq;
			end
		end
		alu_divu: begin
			diva = a;
			divb = b;
			f = divq;
		end
		alu_rem: begin
			diva = (a[31])? (~a)+1 : a;
			divb = (b[31])? (~b)+1 : b;
			if (a[31]&b[31]) begin
				f = divr;
			end
			else if (a[31] | b[31]) begin
				f = (~divr)+1;
			end else begin
				f = divr;
			end
		end
		alu_remu: begin
			diva = a;
			divb = b;
			f = divr;
		end

    endcase	 
end
multiplier mul(.clk(clk), .a_t(mula), .b_t(mulb),.out(mul_out));


enum int unsigned {divS, divE} state, next_state;
always_comb begin
	case(state)
		divS: begin 
			div_start = (div_done && aluop[3:2] == 2'b11 )? 1'b1 : 1'b0;
			stall = (div_done && aluop[3:2] == 2'b11 )? 1'b1 : curr_mul & ~prev_mul & ~hazard_stall;
		end
		divE: begin
			div_start = 1'b0;
			stall = ~div_done;
		end
	endcase
	next_state = state;
	case(state)
		divS: if(div_start) next_state = divE;	
		divE: if(div_done) next_state = divS;
	endcase
end
always_ff @(posedge clk) begin
	state <= next_state;	
	prev_mul <= (hazard_stall) ? 1'b0 : curr_mul;
end

divider div(
//inputs
	.clk(clk), 
	.start(div_start), 
	.a(diva), 
	.b(divb), 
//outputs
	.quo(divq), 
	.rem(divr), 
	.done(div_done)
);

endmodule : alu
