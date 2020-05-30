import datapath_types::*;

module execute(
	input clk, hazard_stall,
	input decode_exe_block in_block,
	input [31:0] rs1, rs2,
	output exe_mem_block out_block,
	output pcmux::pcmux_sel_t pcmux_sel_out,
	output logic [31:0] alu_out,
	output logic [31:0] alu_target,
	output logic stall
);

// BRANCH ENABLE
logic br_en;

//assigns
assign out_block.pc_reg = in_block.pc_reg;
assign out_block.imm_reg = in_block.imm_reg;
assign out_block.rs2_reg = rs2;
assign out_block.cw_reg = in_block.cw_reg;
assign out_block.br_en_reg = br_en;
assign out_block.alu_out_reg = alu_out;

/******MUXES*******/
logic [31:0] alumux1_out, alumux2_out, cmpmux_out;

always_comb begin
	// CMP MUX
	unique case ( in_block.cw_reg.cmpmux_sel )
		cmpmux::rs2_out:  cmpmux_out = rs2;
		cmpmux::i_imm:	  cmpmux_out = in_block.imm_reg.i_imm;
	endcase
	// ALU MUX 1
	unique case ( in_block.cw_reg.alumux1_sel )
		alumux::rs1_out:  alumux1_out = rs1;
		alumux::pc_out:   alumux1_out = in_block.pc_reg;
	endcase
	//ALU MUX 2
	unique case ( in_block.cw_reg.alumux2_sel )
		alumux::i_imm:   alumux2_out = in_block.imm_reg.i_imm;
		alumux::u_imm:   alumux2_out = in_block.imm_reg.u_imm;
		alumux::b_imm:   alumux2_out = in_block.imm_reg.b_imm;
		alumux::s_imm:   alumux2_out = in_block.imm_reg.s_imm;
		alumux::j_imm:   alumux2_out = in_block.imm_reg.j_imm;
		alumux::rs2_out: alumux2_out = rs2;
	endcase
	pcmux_sel_out = (in_block.cw_reg.is_branch)? pcmux::pcmux_sel_t'(in_block.cw_reg.pcmux_sel & {1'b0, {br_en}}) : in_block.cw_reg.pcmux_sel;
end
/******MUX DONE**********/
alu ALU(
	.clk(clk),
	.aluop(in_block.cw_reg.alu_op),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out),
	.alu_target(alu_target),
	.stall(stall),
	.hazard_stall(hazard_stall)
);

cmp CMP(
	.cmpop(in_block.cw_reg.cmp_op),
	.a(rs1),
	.b(cmpmux_out),
	.br_en(br_en)
);

endmodule : execute
