import datapath_types::*;
import rv32i_types::*;

module jump_target_buffer(
	input clk,
	input rv32i_word PC_in,
	input decode_exe_block exe_block_j,
	input rv32i_word jump_target,
	output rv32i_word jump_PC,
	output logic jump_hit
);

decode_exe_block exe_block;
logic jump_res;
logic [31:0] target_out, known_PC;
logic is_valid;
// only stores unconditional JAL, won't cache JALR
assign jump_res = (exe_block.cw_reg.opcode == op_jal);
assign jump_hit = (known_PC == PC_in) & is_valid;
assign exe_block = exe_block_j;

array_same_c #(4, 32) target(
	.clk(clk),
	.read(1'b1),
	.load(jump_res),
	.rindex(PC_in[5:2]),
	.windex(exe_block.pc_reg[5:2]),
	.datain(jump_target),
	.dataout(target_out)
);

array_same_c #(4, 32) known_jump_pc(
	.clk(clk),
	.read(1'b1),
	.load(jump_res),
	.rindex(PC_in[5:2]),
	.windex(exe_block.pc_reg[5:2]),
	.datain(exe_block.pc_reg),
	.dataout(known_PC)
);

array_same_c #(4, 1) valid(
	.clk(clk),
	.read(1'b1),
	.load(jump_res),
	.rindex(PC_in[5:2]),
	.windex(exe_block.pc_reg[5:2]),
	.datain(1'b1),
	.dataout(is_valid)
);

always_comb
begin
	// DATAOUT MUX
	if (jump_hit)
		jump_PC = target_out;
	else
		jump_PC = 32'd0;
end

endmodule
