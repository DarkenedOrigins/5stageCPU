import datapath_types::*;
import rv32i_types::*;

module writeback(
	input mem_wb_block in_block,
	input rv32i_word rdata,
	output logic [31:0] regfile_wdata
);


always_comb begin
	regfile_wdata = '0;
	unique case (in_block.cw_reg.regfilemux_sel)
		regfilemux::alu_out:  regfile_wdata = in_block.alu_out_reg;
		regfilemux::br_en:	  regfile_wdata = {31'd0, in_block.br_en_reg};
		regfilemux::u_imm:	  regfile_wdata = in_block.imm_reg.u_imm;
		regfilemux::lw:	  	  regfile_wdata = rdata;//in_block.read_data_reg;
		regfilemux::pc_plus4: regfile_wdata = in_block.pc_reg + 4;
		regfilemux::lb: begin
			case(in_block.alu_out_reg[1:0])
				2'b00 : regfile_wdata = {{25{rdata[7]}},  rdata[6:0]};
				2'b01 : regfile_wdata = {{25{rdata[15]}},  rdata[14:8]};
				2'b10 : regfile_wdata = {{25{rdata[23]}},  rdata[22:16]};
				2'b11 : regfile_wdata = {{25{rdata[31]}},  rdata[30:24]};
			endcase
		end
		regfilemux::lbu: begin
			case(in_block.alu_out_reg[1:0])
				2'b00 : regfile_wdata = {24'h000000,  rdata[7:0]};
				2'b01 : regfile_wdata = {24'h000000,  rdata[15:8]};
				2'b10 : regfile_wdata = {24'h000000,  rdata[23:16]};
				2'b11 : regfile_wdata = {24'h000000,  rdata[31:24]};
			endcase
		end
		regfilemux::lh:	begin
			case(in_block.alu_out_reg[1:0])	  
				2'b00 : regfile_wdata = {{17{rdata[15]}} , rdata[14:0]};
				2'b01 : regfile_wdata = {{17{rdata[23]}} , rdata[22:8]};
				2'b10 : regfile_wdata = {{17{rdata[31]}} , rdata[30:16]};
				2'b11 : regfile_wdata = {24'h000000, rdata[31:24]};
			endcase
		end
		regfilemux::lhu: begin
			case(in_block.alu_out_reg[1:0])	  
				2'b00 : regfile_wdata = {16'h0000 , rdata[15:0]};
				2'b01 : regfile_wdata = {16'h0000 , rdata[23:8]};
				2'b10 : regfile_wdata = {16'h0000 , rdata[31:16]};
				2'b11 : regfile_wdata = {24'h000000 , rdata[31:24]};
			endcase
		end
	endcase
end

endmodule : writeback
