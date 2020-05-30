import datapath_types::*;
import rv32i_types::*;

module branch_predictor(
	input clk,
	input rv32i_word PC_in,
	input decode_exe_block exe_block_b,
	input logic branch_taken,
	input rv32i_word branch_target,
	output rv32i_word pred_PC,
	output logic guess_branch,
	output logic [4:0] branch_history
);

decode_exe_block exe_block;
logic branch_res, branch_pred;
logic [31:0] target_out, known_PC;
logic is_valid, hit;
assign branch_res = (exe_block.cw_reg.opcode == op_br);
assign hit = (known_PC == PC_in) & is_valid;
assign guess_branch = branch_pred & hit;
assign exe_block = exe_block_b;

array_same_c #(4, 32) target(
	.clk(clk),
	.read(1'b1),
	.load(branch_res),
	.rindex(PC_in[5:2]),
	.windex(exe_block.pc_reg[5:2]),
	.datain(branch_target),
	.dataout(target_out)
);

array_same_c #(4, 32) known_branch(
	.clk(clk),
	.read(1'b1),
	.load(branch_res),
	.rindex(PC_in[5:2]),
	.windex(exe_block.pc_reg[5:2]),
	.datain(exe_block.pc_reg),
	.dataout(known_PC)
);

array_same_c #(4, 1) valid(
	.clk(clk),
	.read(1'b1),
	.load(branch_res),
	.rindex(PC_in[5:2]),
	.windex(exe_block.pc_reg[5:2]),
	.datain(1'b1),
	.dataout(is_valid)
);

shift_reg history(
	.clk(clk),
	.read(1'b1),
	.shift(branch_res),
	.rindex(PC_in[5:2]),
	.windex(exe_block.pc_reg[5:2]),
	.shift_in(branch_taken),
	.dataout(branch_history)
);

pred_counter  predictor(
	.clk(clk),
	.read(1'b1),
	.branch_res(branch_res),
	.rindex(branch_history),
	.windex(exe_block.branch_history),
	.branch_taken(branch_taken),
	.branch_pred(branch_pred)
);

always_comb
begin
	// DATAOUT MUX
	if (branch_pred)
		pred_PC = target_out;
	else
		pred_PC = PC_in +4;


end

endmodule
