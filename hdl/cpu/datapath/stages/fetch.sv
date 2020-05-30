import datapath_types::*;

module fetch (
	input clk,

	//mem stuff
    input stall,
	 input logic branch_taken,
    output logic read_a,
    output logic [31:0] address_a,

	input pcmux::pcmux_sel_t pcmux_sel,
	input [31:0] alu_out,
	output fetch_decode_block out_block,

	// Branch Prediction
	input logic guess_branch,
	input logic [31:0] branch_target,
	input logic [4:0] branch_history,
	input logic misprediction,
	input logic [31:0] exe_pc,
	// jump prediction
	input logic jump_hit,
	input logic [31:0] jump_target,
	// return prediction
	input logic return_predict,
	input logic [31:0] return_target,
	// RVFI SIGNAL
	output logic [31:0] pc_in_val
);
logic [31:0] pc_in;
logic [31:0] pc_out;

assign address_a = pc_out;
assign out_block.pc_reg = pc_out;
assign out_block.branch_guess = guess_branch;
assign out_block.branch_history = branch_history;
assign out_block.jump_det = jump_hit;
assign pc_in_val = pc_in;
//assign out_block.instr_reg = rdata_a;

pc_register pc(
	.clk(clk),
	.load(stall),
	.in(pc_in),
	.out(pc_out)
);

always_comb begin
	case(pcmux_sel)
		pcmux::pc_plus4 : begin
			if(misprediction)
				pc_in = exe_pc+4;
			else begin
				if (guess_branch) 
					pc_in = branch_target;
				else if(jump_hit)
					pc_in = jump_target;
				else if(return_predict)
					pc_in = return_target;
				else
					pc_in = pc_out +4;
			end
		end
		pcmux::alu_out : begin
			if(misprediction)
				pc_in = alu_out;
			else begin
				if (guess_branch) 
					pc_in = branch_target;
				else if(jump_hit)
					pc_in = jump_target;
				else if(return_predict)
					pc_in = return_target;
				else
					pc_in = pc_out +4;
			end
		end
		pcmux::alu_mod2 : begin
			if(misprediction)
				pc_in = {alu_out[31:1], 1'b0};
			else begin
				if (guess_branch) 
					pc_in = branch_target;
				else if(jump_hit)
					pc_in = jump_target;
				else if(return_predict)
					pc_in = return_target;
				else
					pc_in = pc_out +4;
			end
		end
	endcase
	read_a = 1'b1; //LOL
//	if(resp_a)
//		read_a = 1'b0;
//	else
//		read_a = 1'b1;
end

endmodule : fetch
