import datapath_types::*;
import rv32i_types::*;

module forward_logic (
	input clk,
	// data from execute stage
	input decode_exe_block exe_block,
	// data from memory stage
	input exe_mem_block mem_block,
	// data from writeback stage
	input rv32i_word rdata,
	input mem_wb_block wb_block,

	// outgoing register data
	output rv32i_word rs1_out,
	output rv32i_word rs2_out,
	output rv32i_word wdata,
	// stall signal
	output logic hazard_stall
);

mem_wb_block prev_wb;
logic [31:0] prev_rdata;

always_ff @(posedge clk) begin
	if(hazard_stall) begin
		prev_wb <= wb_block;
		prev_rdata <= rdata;
	end
	else begin
		prev_wb <= '0;
		prev_rdata <= '0;
	end
end

always_comb begin
	// by default, pass the 'normal' data through
	rs1_out = exe_block.rs1_reg;
	rs2_out = exe_block.rs2_reg;
	hazard_stall = 1'b0;
	// Some very very edge case, if there was just a data hazard, we need to grab
	//		the previously shifted-out writeback block
	if(prev_wb.cw_reg.load_regfile) begin
		// check RS1
		if( (exe_block.cw_reg.rs1 ==  prev_wb.cw_reg.rd) && (exe_block.cw_reg.rs1 != 5'd0) )  begin
			// we need to check where the data is, depending on what should
			// be loaded into the register
			case(wb_block.cw_reg.regfilemux_sel)
				regfilemux::alu_out : rs1_out = prev_wb.alu_out_reg;
				regfilemux::br_en :	rs1_out = {31'd0, prev_wb.br_en_reg};
				regfilemux::u_imm : rs1_out = prev_wb.imm_reg.u_imm;
				regfilemux::lw : rs1_out = prev_rdata;
				regfilemux::lb : begin
					case(prev_wb.alu_out_reg[1:0])
						2'b00 : rs1_out = {{25{prev_rdata[7]}}, prev_rdata[6:0]};
						2'b01 : rs1_out = {{25{prev_rdata[15]}}, prev_rdata[14:8]};
						2'b10 : rs1_out = {{25{prev_rdata[23]}}, prev_rdata[22:16]};
						2'b11 : rs1_out = {{25{prev_rdata[31]}}, prev_rdata[30:24]};
					endcase
				end 
				regfilemux::lbu : begin
					case(prev_wb.alu_out_reg[1:0])
						2'b00 : rs1_out = {24'd0, prev_rdata[7:0]};
						2'b01 : rs1_out = {24'd0, prev_rdata[15:8]};
						2'b10 : rs1_out = {24'd0, prev_rdata[23:16]};
						2'b11 : rs1_out = {24'd0, prev_rdata[31:24]};
					endcase
				end
				regfilemux::lh : begin
					case(prev_wb.alu_out_reg[1:0])
						2'b00 : rs1_out = {{17{prev_rdata[15]}}, prev_rdata[14:0]};
						2'b01 : rs1_out = {{17{prev_rdata[23]}}, prev_rdata[22:8]};
						2'b10 : rs1_out = {{17{prev_rdata[31]}}, prev_rdata[30:16]};
						2'b11 : rs1_out = {24'd0, prev_rdata[31:24]};
					endcase
				end
				regfilemux::lhu : begin
					case(prev_wb.alu_out_reg[1:0])
						2'b00 : rs1_out = {16'd0, prev_rdata[15:0]};
						2'b01 : rs1_out = {16'd0, prev_rdata[23:8]};
						2'b10 : rs1_out = {16'd0, prev_rdata[31:16]};
						2'b11 : rs1_out = {24'd0, prev_rdata[31:24]};
					endcase
				end
				regfilemux::pc_plus4 : rs1_out = prev_wb.pc_reg+4;
			endcase
		end
		// check RS2
		if( (exe_block.cw_reg.rs2 ==  prev_wb.cw_reg.rd) && (exe_block.cw_reg.rs2 != 5'd0) )  begin
			// we need to check where the data is, depending on what should
			// be loaded into the register
			case(wb_block.cw_reg.regfilemux_sel)
				regfilemux::alu_out : rs2_out = prev_wb.alu_out_reg;
				regfilemux::br_en :	rs2_out = {31'd0, prev_wb.br_en_reg};
				regfilemux::u_imm : rs2_out = prev_wb.imm_reg.u_imm;
				regfilemux::lw : rs2_out = prev_rdata;
				regfilemux::lb : begin
					case(prev_wb.alu_out_reg[1:0])
						2'b00 : rs2_out = {{25{prev_rdata[7]}}, prev_rdata[6:0]};
						2'b01 : rs2_out = {{25{prev_rdata[15]}}, prev_rdata[14:8]};
						2'b10 : rs2_out = {{25{prev_rdata[23]}}, prev_rdata[22:16]};
						2'b11 : rs2_out = {{25{prev_rdata[31]}}, prev_rdata[30:24]};
					endcase
				end 
				regfilemux::lbu : begin
					case(prev_wb.alu_out_reg[1:0])
						2'b00 : rs2_out = {24'd0, prev_rdata[7:0]};
						2'b01 : rs2_out = {24'd0, prev_rdata[15:8]};
						2'b10 : rs2_out = {24'd0, prev_rdata[23:16]};
						2'b11 : rs2_out = {24'd0, prev_rdata[31:24]};
					endcase
				end
				regfilemux::lh : begin
					case(prev_wb.alu_out_reg[1:0])
						2'b00 : rs2_out = {{17{prev_rdata[15]}}, prev_rdata[14:0]};
						2'b01 : rs2_out = {{17{prev_rdata[23]}}, prev_rdata[22:8]};
						2'b10 : rs2_out = {{17{prev_rdata[31]}}, prev_rdata[30:16]};
						2'b11 : rs2_out = {24'd0, prev_rdata[31:24]};
					endcase
				end
				regfilemux::lhu : begin
					case(prev_wb.alu_out_reg[1:0])
						2'b00 : rs2_out = {16'd0, prev_rdata[15:0]};
						2'b01 : rs2_out = {16'd0, prev_rdata[23:8]};
						2'b10 : rs2_out = {16'd0, prev_rdata[31:16]};
						2'b11 : rs2_out = {24'd0, prev_rdata[31:24]};
					endcase
				end
				regfilemux::pc_plus4 : rs2_out = prev_wb.pc_reg+4;
			endcase
		end
	end
	// check if 2 instructions before has the data we need
	if(wb_block.cw_reg.load_regfile) begin
		if( (exe_block.cw_reg.rs1 ==  wb_block.cw_reg.rd) && (exe_block.cw_reg.rs1 != 5'd0) )  begin
			// we need to check where the data is, depending on what should
			// be loaded into the register
			case(wb_block.cw_reg.regfilemux_sel)
				regfilemux::alu_out : rs1_out = wb_block.alu_out_reg;
				regfilemux::br_en :	rs1_out = {31'd0, wb_block.br_en_reg};
				regfilemux::u_imm : rs1_out = wb_block.imm_reg.u_imm;
				regfilemux::lw : rs1_out = rdata;
				regfilemux::lb : begin
					case(wb_block.alu_out_reg[1:0])
						2'b00 : rs1_out = {{25{rdata[7]}}, rdata[6:0]};
						2'b01 : rs1_out = {{25{rdata[15]}}, rdata[14:8]};
						2'b10 : rs1_out = {{25{rdata[23]}}, rdata[22:16]};
						2'b11 : rs1_out = {{25{rdata[31]}}, rdata[30:24]};
					endcase
				end 
				regfilemux::lbu : begin
					case(wb_block.alu_out_reg[1:0])
						2'b00 : rs1_out = {24'd0, rdata[7:0]};
						2'b01 : rs1_out = {24'd0, rdata[15:8]};
						2'b10 : rs1_out = {24'd0, rdata[23:16]};
						2'b11 : rs1_out = {24'd0, rdata[31:24]};
					endcase
				end
				regfilemux::lh : begin
					case(wb_block.alu_out_reg[1:0])
						2'b00 : rs1_out = {{17{rdata[15]}}, rdata[14:0]};
						2'b01 : rs1_out = {{17{rdata[23]}}, rdata[22:8]};
						2'b10 : rs1_out = {{17{rdata[31]}}, rdata[30:16]};
						2'b11 : rs1_out = {24'd0, rdata[31:24]};
					endcase
				end
				regfilemux::lhu : begin
					case(wb_block.alu_out_reg[1:0])
						2'b00 : rs1_out = {16'd0, rdata[15:0]};
						2'b01 : rs1_out = {16'd0, rdata[23:8]};
						2'b10 : rs1_out = {16'd0, rdata[31:16]};
						2'b11 : rs1_out = {24'd0, rdata[31:24]};
					endcase
				end
				regfilemux::pc_plus4 : rs1_out = wb_block.pc_reg+4;
			endcase
		end
		
		if( (exe_block.cw_reg.rs2 ==  wb_block.cw_reg.rd) && (exe_block.cw_reg.rs2 != 5'd0) )  begin
			// we need to check where the data is, depending on what should
			// be loaded into the register
			case(wb_block.cw_reg.regfilemux_sel)
				regfilemux::alu_out : rs2_out = wb_block.alu_out_reg;
				regfilemux::br_en :	rs2_out = {31'd0, wb_block.br_en_reg};
				regfilemux::u_imm : rs2_out = wb_block.imm_reg.u_imm;
				regfilemux::lw : rs2_out = rdata;
				regfilemux::lb : begin
					case(wb_block.alu_out_reg[1:0])
						2'b00 : rs2_out = {{25{rdata[7]}}, rdata[6:0]};
						2'b01 : rs2_out = {{25{rdata[15]}}, rdata[14:8]};
						2'b10 : rs2_out = {{25{rdata[23]}}, rdata[22:16]};
						2'b11 : rs2_out = {{25{rdata[31]}}, rdata[30:24]};
					endcase
				end 
				regfilemux::lbu : begin
					case(wb_block.alu_out_reg[1:0])
						2'b00 : rs2_out = {24'd0, rdata[7:0]};
						2'b01 : rs2_out = {24'd0, rdata[15:8]};
						2'b10 : rs2_out = {24'd0, rdata[23:16]};
						2'b11 : rs2_out = {24'd0, rdata[31:24]};
					endcase
				end
				regfilemux::lh : begin
					case(wb_block.alu_out_reg[1:0])
						2'b00 : rs2_out = {{17{rdata[15]}}, rdata[14:0]};
						2'b01 : rs2_out = {{17{rdata[23]}}, rdata[22:8]};
						2'b10 : rs2_out = {{17{rdata[31]}}, rdata[30:16]};
						2'b11 : rs2_out = {24'd0, rdata[31:24]};
					endcase
				end
				regfilemux::lhu : begin
					case(wb_block.alu_out_reg[1:0])
						2'b00 : rs2_out = {16'd0, rdata[15:0]};
						2'b01 : rs2_out = {16'd0, rdata[23:8]};
						2'b10 : rs2_out = {16'd0, rdata[31:16]};
						2'b11 : rs2_out = {24'd0, rdata[31:24]};
					endcase
				end
				regfilemux::pc_plus4 : rs2_out = wb_block.pc_reg+4;
			endcase
		end
	end
	// check if 1 instruction prior has data we need
	if(mem_block.cw_reg.load_regfile) begin
		// RS1 check, we will not stall for register X0
		if( (exe_block.cw_reg.rs1 == mem_block.cw_reg.rd) && (exe_block.cw_reg.rs1 != 5'd0) ) begin
			// we need to check where the data is, depending on what should
			// be loaded into the register
			case(mem_block.cw_reg.regfilemux_sel)
				regfilemux::alu_out : rs1_out = mem_block.alu_out_reg;
				regfilemux::br_en :	rs1_out = {31'd0, mem_block.br_en_reg};
				regfilemux::u_imm : rs1_out = mem_block.imm_reg.u_imm;
				regfilemux::lw, // 
				regfilemux::lb, 
				regfilemux::lbu, 
				regfilemux::lh,
				regfilemux::lhu : begin
				// check if we actually SHOULD stall. This could be false alarm if rs1 isn't acutally used...
					case(exe_block.cw_reg.opcode)
						op_auipc, op_lui, op_jal : hazard_stall = 1'b0; //these instructions don't use rs1
						default : hazard_stall = 1'b1; // all other instructions will use rs1
					endcase
				end
				regfilemux::pc_plus4 : rs1_out = mem_block.pc_reg+4;
			endcase
		end
		// RS2 check, we will not stall for register X0
		if( (exe_block.cw_reg.rs2 == mem_block.cw_reg.rd) && (exe_block.cw_reg.rs2 != 5'd0) ) begin
			// we need to check where the data is, depending on what should
			// be loaded into the register
			case(mem_block.cw_reg.regfilemux_sel)
				regfilemux::alu_out : rs2_out = mem_block.alu_out_reg;
				regfilemux::br_en :	rs2_out = {31'd0, mem_block.br_en_reg};
				regfilemux::u_imm : rs2_out = mem_block.imm_reg.u_imm;
				regfilemux::lw,
				regfilemux::lb, 
				regfilemux::lbu, 
				regfilemux::lh,
				regfilemux::lhu : begin
				// check if we actually SHOULD stall. This could be false alarm if rs2 isn't acutally used...
					case(exe_block.cw_reg.opcode)
						op_auipc, op_lui, op_jal,
						op_jalr, op_load, op_imm : hazard_stall = 1'b0; //these instructions don't use rs2
						default : hazard_stall = 1'b1; // all other instructions will use rs2;
					endcase
				end
				regfilemux::pc_plus4 : rs2_out = mem_block.pc_reg+4;
			endcase
		end
	end
end

always_comb begin
	wdata = mem_block.rs2_reg;
//	if( mem_block.cw_reg.mem_write && (mem_block.cw_reg.rs2 == wb_block.cw_reg.rd))
//		wdata = rdata;
//	if((mem_block.cw_reg.rs2 == 5'd0))
//		wdata = 32'd0;
end
endmodule : forward_logic
