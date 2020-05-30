package datapath_types;

import rv32i_types::*;

// control logic struct
typedef struct packed{
	
	branch_funct3_t cmp_op;
	alu_ops alu_op;
	load_funct3_t ld_op;
	
	// mem control bits
	logic mem_read;
	logic mem_write;
	logic [3:0] mem_byte_enable;
	// mux selects
	pcmux::pcmux_sel_t pcmux_sel;
	alumux::alumux1_sel_t alumux1_sel;
	alumux::alumux2_sel_t alumux2_sel;
	regfilemux::regfilemux_sel_t regfilemux_sel;
	cmpmux::cmpmux_sel_t cmpmux_sel;

	//stuff needed for forwarding
	rv32i_reg rs1;
	rv32i_reg rs2;
	rv32i_opcode opcode;

	rv32i_reg rd;

	logic is_branch;
	logic load_pc; // might not need
	logic load_regfile;

}control_word_t;

// immediate value struct
typedef struct packed {
	logic [31:0] i_imm;
	logic [31:0] s_imm;
	logic [31:0] b_imm;
	logic [31:0] u_imm;
	logic [31:0] j_imm;

}imm_star_t;

/********************************* PIPELINE BLOCKS *************************/
// FETCH -> DECODE data
typedef struct packed{
	rv32i_word pc_reg;
	logic branch_guess;
	logic [4:0] branch_history;
	logic jump_det;
}fetch_decode_block;
// DECODE -> EXE data
typedef struct packed{
	rv32i_word pc_reg;
	imm_star_t imm_reg;
	rv32i_word rs1_reg, rs2_reg;
	control_word_t cw_reg;
	logic branch_guess;
	logic [4:0] branch_history;
	logic jump_det;
}decode_exe_block;
// EXE -> MEM data
typedef struct packed{
	rv32i_word pc_reg;
	imm_star_t imm_reg;
	rv32i_word rs2_reg;
	control_word_t cw_reg;
	logic br_en_reg;
	logic [31:0] alu_out_reg;
}exe_mem_block;
// MEM -> WB data
typedef struct packed{
	rv32i_word pc_reg;
	imm_star_t imm_reg;
	control_word_t cw_reg;
	logic br_en_reg;
	logic [31:0] alu_out_reg;
//	logic [31:0] read_data_reg;
}mem_wb_block;

/*******************************************************************/

endpackage : datapath_types
