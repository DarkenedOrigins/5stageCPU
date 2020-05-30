import datapath_types::*;
import rv32i_types::*;

module decode(
	input clk,
	input fetch_decode_block in_block,
	input logic load_reg,
	input rv32i_reg rd,
	input logic [31:0] regfile_wdata,
	input rv32i_word instr,
//	input branch_taken,
	input stall,
	output decode_exe_block out_block
);

assign out_block.pc_reg = in_block.pc_reg;
assign out_block.branch_guess = in_block.branch_guess;
assign out_block.branch_history = in_block.branch_history;
assign out_block.jump_det = in_block.jump_det;

/************************ MODULES *****************************/

rv32i_opcode opcode;
rv32i_reg rs1, rs2, reg_dest;

// REGISTER BOIS
regfile regfile(
	.clk(clk),
	.load(load_reg & stall),
	.in(regfile_wdata),
	.src_a(rs1),
	.src_b(rs2),
	.dest(rd),
	.reg_a(out_block.rs1_reg),
	.reg_b(out_block.rs2_reg)
);

// logic imm_star_t imm_star;
logic [2:0] funct3;
logic [6:0] funct7;
ir_decode IR(
	.in(instr),
	.funct3(funct3),
	.funct7(funct7),
	.opcode(opcode),
	.i_imm(out_block.imm_reg.i_imm),
	.s_imm(out_block.imm_reg.s_imm),
	.b_imm(out_block.imm_reg.b_imm),
	.u_imm(out_block.imm_reg.u_imm),
	.j_imm(out_block.imm_reg.j_imm),
	.rs1(rs1),
	.rs2(rs2),
	.rd(reg_dest)
);

control_word_logic cw_logic(
	.opcode(opcode),
	.funct3(funct3),
	.funct7(funct7),
	.rs1(rs1),
	.rs2(rs2),
	.rd(reg_dest),
	.control_word(out_block.cw_reg)
);

/**************************************************************/



endmodule : decode
