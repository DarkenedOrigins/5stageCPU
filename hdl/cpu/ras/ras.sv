import datapath_types::*;
import rv32i_types::*;

module return_address_stack(
	input clk,
	input decode_exe_block exe_block_r,
	input [31:0] jump_target,
	input decode_exe_block decode_out_r,
	output logic return_predict,
	output logic [31:0] return_target,
	output logic correct_return,
	input logic stall
);

decode_exe_block exe_block;
decode_exe_block decode_out;
logic push, pop, empty;
logic target_match, jal_push, jalr_push, jalr_pop;
logic rd_link_e, rs1_link_e;
logic rd_link_d, rs1_link_d;

assign exe_block = exe_block_r;
assign decode_out = decode_out_r;

/****************************************************/
//stack management logic
// Folllowing RISCV calling conventions, only push/pop on x1/x5
assign rd_link_e = (exe_block.cw_reg.rd == 5'd5) || (exe_block.cw_reg.rd == 5'd1);
assign rs1_link_e = (exe_block.cw_reg.rs1 == 5'd5) || (exe_block.cw_reg.rs1 == 5'd1);
assign jal_push = (exe_block.cw_reg.opcode == op_jal) && rd_link_e;
assign jalr_push = (exe_block.cw_reg.opcode == op_jalr) && rd_link_e; //&& ~rs1_link_e;
assign jalr_pop = (exe_block.cw_reg.opcode == op_jalr) && ~rd_link_e && rs1_link_e;

assign rd_link_d = (decode_out.cw_reg.rd == 5'd5) || (decode_out.cw_reg.rd == 5'd1);
assign rs1_link_d = (decode_out.cw_reg.rs1 == 5'd5) || (decode_out.cw_reg.rs1 == 5'd1);

assign push = (jal_push ||  jalr_push) & stall;
assign pop = jalr_pop & ~empty;

/****************************************************/
assign correct_return = (jump_target == return_target);

lifo return_address(
	.clk(clk),
	.datain(exe_block.pc_reg+4),
	.push(push),
	.pop(pop),
	.peek(return_target),
	.empty(empty)
);

always_comb begin
	return_predict = 1'b0;
	if ( (decode_out.cw_reg.opcode == op_jalr) && ~rd_link_d && rs1_link_d && ~empty )
		return_predict = 1'b1;
end

endmodule
