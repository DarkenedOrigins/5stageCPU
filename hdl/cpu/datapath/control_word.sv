import datapath_types::*;
import rv32i_types::*;

module control_word_logic(
	input rv32i_opcode opcode,
	input [2:0] funct3,
	input [6:0] funct7,
	input rv32i_reg rd,
	input rv32i_reg rs1,
	input rv32i_reg rs2,
	output control_word_t control_word
);

/********** FUNCTIONS ***************************************/

function void set_defaults();
	control_word = '0;
	control_word.rd = rd;
	control_word.rs1 = rs1;
	control_word.rs2 = rs2;
	control_word.opcode = opcode;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
	control_word.load_regfile = 1'b1;
	control_word.regfilemux_sel = sel;
endfunction

function void loadPC(pcmux::pcmux_sel_t sel);
	control_word.load_pc = 1'b1;
	control_word.pcmux_sel = sel;
endfunction

function void setALU(alumux::alumux1_sel_t sel1, 
					 alumux::alumux2_sel_t sel2, 
					 alu_ops op);

	control_word.alumux1_sel = sel1;
	control_word.alumux2_sel = sel2;
	control_word.alu_op = op;
endfunction

function void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
	control_word.cmpmux_sel = sel;
	control_word.cmp_op = op;
endfunction


/**********************************************************/

always_comb begin
	set_defaults();
	case(opcode)
		// LUI
		op_lui : begin
			loadRegfile(regfilemux::u_imm);
			loadPC(pcmux::pc_plus4);
		end
		// AUIPC
		op_auipc : begin
			loadRegfile(regfilemux::alu_out);
			loadPC(pcmux::pc_plus4);
			setALU(alumux::pc_out, alumux::u_imm, alu_add);
		end
		// JAL
		op_jal : begin
			loadRegfile(regfilemux::pc_plus4);
			setALU(alumux::pc_out, alumux::j_imm, alu_add);
			loadPC(pcmux::alu_out);
		end
		// JALR
		op_jalr : begin
			loadRegfile(regfilemux::pc_plus4);
			setALU(alumux::rs1_out, alumux::i_imm, alu_add);
			loadPC(pcmux::alu_mod2);
		end
		// BRANCH
		op_br : begin
			setCMP(cmpmux::rs2_out, branch_funct3_t'(funct3));
			loadPC(pcmux::alu_out);
			control_word.is_branch = 1'b1;
			control_word.rd = 5'd0;
			setALU(alumux::pc_out, alumux::b_imm, alu_add);
		end
		// LOAD
		op_load : begin
			setALU(alumux::rs1_out, alumux::i_imm, alu_add);
			control_word.mem_read = 1'b1;
			case (funct3)
				lb : begin
					loadRegfile(regfilemux::lb);
					loadPC(pcmux::pc_plus4);
					control_word.mem_byte_enable = 4'b0001;
				end
				lh : begin
					loadRegfile(regfilemux::lh);
					loadPC(pcmux::pc_plus4);
					control_word.mem_byte_enable = 4'b0011;
				end
				lw : begin
					loadRegfile(regfilemux::lw);
					loadPC(pcmux::pc_plus4);
					control_word.mem_byte_enable = 4'b1111;
				end
				lbu : begin
					loadRegfile(regfilemux::lbu);
					loadPC(pcmux::pc_plus4);
					control_word.mem_byte_enable = 4'b0001;
				end
				lhu : begin
					loadRegfile(regfilemux::lhu);
					loadPC(pcmux::pc_plus4);
					control_word.mem_byte_enable = 4'b0011;
				end
				default : ;
			endcase
		end
		// STORE
		op_store : begin
			setALU(alumux::rs1_out, alumux::s_imm, alu_add);
			control_word.mem_write = 1'b1;
			control_word.rd = 5'd0;
			case (funct3)
				sb : control_word.mem_byte_enable = 4'b0001;
				sh : control_word.mem_byte_enable = 4'b0011;
				sw : control_word.mem_byte_enable = 4'b1111;
				default: control_word.mem_byte_enable = 4'b0000;
			endcase
			loadPC(pcmux::pc_plus4);
		end
		// IMMEDIATE
		op_imm : begin
			loadRegfile(regfilemux::alu_out);
			loadPC(pcmux::pc_plus4);
			case (funct3)
				slt : begin
					setCMP(cmpmux::i_imm, blt);
					loadRegfile(regfilemux::br_en);
				end
				sltu : begin
					setCMP(cmpmux::i_imm, bltu);
					loadRegfile(regfilemux::br_en);
				end
				sr : begin
					if (funct7[5])
						setALU(alumux::rs1_out, alumux::i_imm, alu_sra);
					else
						setALU(alumux::rs1_out, alumux::i_imm, alu_srl);
				end
				default : setALU(alumux::rs1_out, alumux::i_imm, alu_ops'(funct3));
			endcase
		end
		// REGISTER
		op_reg : begin
			loadRegfile(regfilemux::alu_out);
			loadPC(pcmux::pc_plus4);
			if (funct7[0] == 1'b1) begin
				//this is a multiply/division/rem op lolz
				setALU(alumux::rs1_out, alumux::rs2_out, alu_ops'({1'b1, funct3}));		
			end else begin
				case (funct3)
					slt : begin
						setCMP(cmpmux::rs2_out, blt);
						loadRegfile(regfilemux::br_en);
					end
					sltu : begin
						setCMP(cmpmux::rs2_out, bltu);
						loadRegfile(regfilemux::br_en);
					end
					sr : begin
						if (funct7[5])
							setALU(alumux::rs1_out, alumux::rs2_out, alu_sra);
						else
							setALU(alumux::rs1_out, alumux::rs2_out, alu_srl);
					end
					add : begin
						if (funct7[5])
							setALU(alumux::rs1_out, alumux::rs2_out, alu_sub);
						else
							setALU(alumux::rs1_out, alumux::rs2_out, alu_add);
					end
					default : setALU(alumux::rs1_out, alumux::rs2_out, alu_ops'(funct3));
				endcase
			end
		end
		// LOL?
		op_csr : begin

		end
		default : ;
	endcase
end

endmodule : control_word_logic
