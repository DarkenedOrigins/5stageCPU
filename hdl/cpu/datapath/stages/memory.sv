import datapath_types::*;
module mem(
	//mem stuff
    input resp_b,
    //input [31:0] rdata_b,
    output logic read_b,
    output logic write,
    output logic [3:0] wmask,
    output logic [31:0] address_b,
    output logic [31:0] wdata,

	input exe_mem_block in_block,
//	output pcmux::pcmux_sel_t pcmux_sel_out,
	output mem_wb_block out_block,
	// forwarded data
	input [31:0] rs2

);

assign wdata = rs2 << (8 * in_block.alu_out_reg[1:0]);
//assign address_b = in_block.alu_out_reg;
assign address_b = {in_block.alu_out_reg[31:2], 2'b00};
//assign wmask = in_block.cw_reg.mem_byte_enable;
//assign out_block.read_data_reg = rdata_b;
//pass throughs
assign out_block.pc_reg = in_block.pc_reg;
assign out_block.imm_reg = in_block.imm_reg;
assign out_block.cw_reg = in_block.cw_reg;
assign out_block.br_en_reg = in_block.br_en_reg;
assign out_block.alu_out_reg = in_block.alu_out_reg;

always_comb begin
	read_b = in_block.cw_reg.mem_read;
	write = in_block.cw_reg.mem_write;
//	pcmux_sel_out = (in_block.cw_reg.is_branch)? pcmux::pcmux_sel_t'(in_block.cw_reg.pcmux_sel & {1'b0, {in_block.br_en_reg}}) : in_block.cw_reg.pcmux_sel;
	if (in_block.cw_reg.mem_byte_enable == 4'b1111)
		wmask = in_block.cw_reg.mem_byte_enable;
	else
		wmask = in_block.cw_reg.mem_byte_enable << in_block.alu_out_reg[1:0];
end

endmodule : mem
