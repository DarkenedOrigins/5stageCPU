`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath
(
    input clk,

	input load_pc,
    input load_mdr,
	input load_ir,
	input load_regfile,
	input load_mar,
	input load_data_out,
	
	input pcmux::pcmux_sel_t pcmux_sel,
	input alumux::alumux1_sel_t alumux1_sel,
	input alumux::alumux2_sel_t alumux2_sel,
	input regfilemux::regfilemux_sel_t regfilemux_sel,
	input marmux::marmux_sel_t marmux_sel,
	input cmpmux::cmpmux_sel_t cmpmux_sel,

	input alu_ops aluop,
	input branch_funct3_t cmpop,

    input rv32i_word mem_rdata,
	input [3:0] mem_byte_enable,
    
	output rv32i_word mem_wdata, // signal used by RVFI Monitor
	output rv32i_word mem_address,
	output rv32i_reg rs1,
	output rv32i_reg rs2,
	output rv32i_opcode opcode,
	output [2:0] funct3,
	output [6:0] funct7,
	output logic br_en
);

/******************* Signals Needed for RVFI Monitor *************************/

rv32i_word pcmux_out;
rv32i_word pc_out;
rv32i_word mdrreg_out;

//stuff that i added

// MAR stuff
rv32i_word marmux_out;
//rv32i_word mem_address;

//CMP stuff
rv32i_word cmpmux_out;

// regfile stuff
rv32i_word regfilemux_out;
rv32i_reg rd;
rv32i_word rs1_out, rs2_out;

//ALU stuff
rv32i_word alu_out;
rv32i_word alumux1_out, alumux2_out;

// IR stuff
rv32i_word i_imm, s_imm, b_imm, u_imm, j_imm;

// DATA STUFF
rv32i_word dat_out;

assign mem_wdata = dat_out << (8 * mem_address[1:0]);
/*****************************************************************************/
/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
	.clk(clk),
	.load(load_ir),
	.in(mdrreg_out),
	.funct3(funct3),
	.funct7(funct7),
	.opcode(opcode),
	.i_imm(i_imm),
	.s_imm(s_imm),
	.b_imm(b_imm),
	.u_imm(u_imm),
	.j_imm(j_imm),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd)
);

register MDR(
    .clk  (clk),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

pc_register PC(
    .clk  (clk),
    .load (load_pc),
    .in   (pcmux_out),
    .out  (pc_out)
);

register MAR(
	.clk(clk),
	.load(load_mar),
	.in(marmux_out),
	.out(mem_address)
);

register DATA_OUT(
	.clk(clk),
	.load(load_data_out),
	.in(rs2_out),
	.out(dat_out)
);

//dat_register DATA_OUT(
//	.clk(clk),
//	.load(load_data_out),
//	.byte_en(mem_byte_enable),
//	.in(rs2_out),
//	.out(mem_wdata)
//);

regfile regfile(
	.clk(clk),
	.load(load_regfile),
	.in(regfilemux_out),
	.src_a(rs1),
	.src_b(rs2),
	.dest(rd),
	.reg_a(rs1_out),
	.reg_b(rs2_out)
);

/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu ALU(
	.aluop(aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out)
);

cmp CMP(
	.cmpop(cmpop),
	.a(rs1_out),
	.b(cmpmux_out),
	.br_en(br_en)
);
/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog.  In this case, we actually use 
    // Offensive programming --- making simulation halt with a fatal message
    // warning when an unexpected mux select value occurs
    unique case (pcmux_sel)
        pcmux::pc_plus4:  pcmux_out = pc_out + 4;
		pcmux::alu_out:   pcmux_out = alu_out;
		pcmux::alu_mod2:  pcmux_out = {alu_out[31:1] ,1'b0};
        // etc.
        default: `BAD_MUX_SEL;
    endcase
	// MAR MUX
	unique case (marmux_sel)
		marmux::pc_out:   marmux_out = pc_out;
		marmux::alu_out:  marmux_out = alu_out;
	endcase
	// CMP MUX
	unique case (cmpmux_sel)
		cmpmux::rs2_out:  cmpmux_out = rs2_out;
		cmpmux::i_imm:	  cmpmux_out = i_imm;
	endcase
	// ALU MUX 1
	unique case (alumux1_sel)
		alumux::rs1_out:  alumux1_out = rs1_out;
		alumux::pc_out:   alumux1_out = pc_out;
	endcase
	//ALU MUX 2
	unique case (alumux2_sel)
		alumux::i_imm:   alumux2_out = i_imm;
		alumux::u_imm:   alumux2_out = u_imm;
		alumux::b_imm:   alumux2_out = b_imm;
		alumux::s_imm:   alumux2_out = s_imm;
		alumux::j_imm:   alumux2_out = j_imm;
		alumux::rs2_out: alumux2_out = rs2_out;
		default: `BAD_MUX_SEL;
	endcase
	//REGFILE MUX
	unique case (regfilemux_sel)
		regfilemux::alu_out:  regfilemux_out = alu_out;
		regfilemux::br_en:	  regfilemux_out = {31'd0, br_en};
		regfilemux::u_imm:	  regfilemux_out = u_imm;
		regfilemux::lw:	  	  regfilemux_out = mdrreg_out;
		regfilemux::pc_plus4: regfilemux_out = pc_out + 4;
		regfilemux::lb: begin
			case(mem_address[1:0])
				2'b00 : regfilemux_out = {{25{mdrreg_out[7]}},  mdrreg_out[6:0]};
				2'b01 : regfilemux_out = {{25{mdrreg_out[15]}},  mdrreg_out[14:8]};
				2'b10 : regfilemux_out = {{25{mdrreg_out[23]}},  mdrreg_out[22:16]};
				2'b11 : regfilemux_out = {{25{mdrreg_out[31]}},  mdrreg_out[30:24]};
			endcase
		end
		regfilemux::lbu: begin
			case(mem_address[1:0])
				2'b00 : regfilemux_out = {24'h000000,  mdrreg_out[7:0]};
				2'b01 : regfilemux_out = {24'h000000,  mdrreg_out[15:8]};
				2'b10 : regfilemux_out = {24'h000000,  mdrreg_out[23:16]};
				2'b11 : regfilemux_out = {24'h000000,  mdrreg_out[31:24]};
			endcase
		end
		regfilemux::lh:	begin
			case(mem_address[1:0])	  
				2'b00 : regfilemux_out = {{17{mdrreg_out[15]}} , mdrreg_out[14:0]};
				2'b01 : regfilemux_out = {{17{mdrreg_out[23]}} , mdrreg_out[22:8]};
				2'b10 : regfilemux_out = {{17{mdrreg_out[31]}} , mdrreg_out[30:16]};
				2'b11 : regfilemux_out = {24'h000000, mdrreg_out[31:24]};
			endcase
		end
		regfilemux::lhu: begin
			case(mem_address[1:0])	  
				2'b00 : regfilemux_out = {16'h0000 , mdrreg_out[15:0]};
				2'b01 : regfilemux_out = {16'h0000 , mdrreg_out[23:8]};
				2'b10 : regfilemux_out = {16'h0000 , mdrreg_out[31:16]};
				2'b11 : regfilemux_out = {24'h000000 , mdrreg_out[31:24]};
			endcase
		end
		default: `BAD_MUX_SEL;
	endcase
end
/*****************************************************************************/
endmodule : datapath
