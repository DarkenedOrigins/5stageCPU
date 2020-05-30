import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    input clk,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
	input logic mem_resp,
	input rv32i_word mem_address,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output branch_funct3_t cmpop,
	output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
	output logic mem_read,
	output logic mem_write,
	output logic [3:0] mem_byte_enable
);

/****************** USED BY RVFIMON --- DO NOT MODIFY ************************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check_do_not_modify
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011;
                lb, lbu: rmask = 4'b0001;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011;
                sb: wmask = 4'b0001;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
	fetch_1,
	fetch_2,
	fetch_3,
	decode,
	imm,
	sreg,
	lui,
	br,
	auipc,
	calc_addr,
	ld1,
	ld2,
	st1,
	st2,
	jal,
	jalr
} state, next_states;

pcmux::pcmux_sel_t br_sel;
assign br_sel = pcmux::pcmux_sel_t'({1'b0, br_en});

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
	load_pc = 1'b0;
	load_ir = 1'b0;
	load_regfile = 1'b0;
	load_mar = 1'b0;
	load_mdr = 1'b0;
	load_data_out = 1'b0;
	
	pcmux_sel = pcmux::pc_plus4;
	cmpop = branch_funct3_t'(funct3);
	alumux1_sel = alumux::rs1_out;
	alumux2_sel = alumux::i_imm;
	regfilemux_sel = regfilemux::alu_out;
	marmux_sel = marmux::pc_out;
	cmpmux_sel = cmpmux::rs2_out;
	aluop = alu_ops'(funct3);

	mem_read = 1'b0;
	mem_write = 1'b0;
	mem_byte_enable = 4'b0000;
	
//	rs1_addr = 5'b0;
//	rs2_addr = 5'b0;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
	load_regfile = 1'b1;
	regfilemux_sel = sel;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
	load_mar = 1'b1;
	marmux_sel = sel;
endfunction

function void loadMDR();
	load_mdr = 1'b1;
endfunction

function void loadDATA();
	load_data_out = 1'b1;
endfunction
/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
    /* Student code here */
	alumux1_sel = sel1;
	alumux2_sel = sel2;

    if (setop)
        aluop = op; // else default value
	else
		aluop = alu_ops'(funct3);
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
	cmpmux_sel = sel;
	cmpop = op;
endfunction

/*****************************************************************************/


always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
	unique case(state)
		fetch_1 : loadMAR(marmux::pc_out);
		fetch_2 : begin
			loadMDR();
			mem_read = 1'b1;
		end
		fetch_3 : load_ir = 1'b1;
		decode : ;
		imm : begin
			loadRegfile(regfilemux::alu_out);
			loadPC(pcmux::pc_plus4);
			case (funct3)
				slt  : begin
					setCMP(cmpmux::i_imm, blt);
					loadRegfile(regfilemux::br_en);
				end
				sltu : begin
				setCMP(cmpmux::i_imm, bltu);
				loadRegfile(regfilemux::br_en);
				end
				sr   : begin
					if (funct7[5])
						setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
					else
						setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
				end
				default : setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(funct3) );
			endcase
		end
		sreg : begin
			loadRegfile(regfilemux::alu_out);
			loadPC(pcmux::pc_plus4);
			case (funct3)
				slt  : begin
					setCMP(cmpmux::rs2_out, blt);
					loadRegfile(regfilemux::br_en);
				end
				sltu : begin
				setCMP(cmpmux::rs2_out, bltu);
				loadRegfile(regfilemux::br_en);
				end
				sr   : begin
					if (funct7[5])
						setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
					else
						setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
				end
				add : begin
					if (funct7[5])
						setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
					else
						setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);
				end
				default : setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(funct3) );
			endcase
		end
		lui : begin
			loadRegfile(regfilemux::u_imm);
			loadPC(pcmux::pc_plus4);
		end
		br : begin
			setCMP(cmpmux::rs2_out, branch_funct3_t'(funct3));
			loadPC(br_sel);
			setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
		end
		auipc : begin
			loadRegfile(regfilemux::alu_out);
			loadPC(pcmux::pc_plus4);
			setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
		end
		calc_addr : begin
			case (opcode)
				op_load : begin
					setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
					loadMAR(marmux::alu_out);
				end
				op_store : begin
					setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
					loadMAR(marmux::alu_out);
					loadDATA();
				end
				default : $fatal("incorrect calc_addr opcode");
			endcase
		end
		ld1 : begin
			loadMDR();
			mem_read = 1'b1;
		end
		ld2 : begin
			case(funct3)
				lb : begin
					loadRegfile(regfilemux::lb);
					loadPC(pcmux::pc_plus4);
	//				mem_byte_enable = 4'b0001 << mem_address[1:0];
				end
				lh : begin
					loadRegfile(regfilemux::lh);
					loadPC(pcmux::pc_plus4);
	//				mem_byte_enable = 4'b0011 << mem_address[1:0];
				end
				lw : begin
					loadRegfile(regfilemux::lw);
					loadPC(pcmux::pc_plus4);
				end
				lbu : begin
					loadRegfile(regfilemux::lbu);
					loadPC(pcmux::pc_plus4);
	//				mem_byte_enable = 4'b0001 << mem_address[1:0];
				end
				lhu : begin
					loadRegfile(regfilemux::lhu);
					loadPC(pcmux::pc_plus4);
		//			mem_byte_enable = 4'b0011 << mem_address[1:0];
				end
			endcase
		end
		st1 : begin
			mem_write = 1'b1;
			case(funct3)
				sb : mem_byte_enable = 4'b0001 << mem_address[1:0];
				sh : mem_byte_enable = 4'b0011 << mem_address[1:0];
				sw : mem_byte_enable = 4'b1111;
			endcase
		end
		st2 : begin
			loadPC(pcmux::pc_plus4);
			case(funct3)
				sb : mem_byte_enable = 4'b0001 << mem_address[1:0];
				sh : mem_byte_enable = 4'b0011 << mem_address[1:0];
				sw : mem_byte_enable = 4'b1111;
			endcase 
		end
		jal : begin
			loadRegfile(regfilemux::pc_plus4);
			setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
			loadPC(pcmux::alu_out);
		end
		jalr : begin
			loadRegfile(regfilemux::pc_plus4);
			setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
			loadPC(pcmux::alu_mod2);
		end
		
	endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	next_states = state;
	unique case (state)	
		fetch_1 : next_states = fetch_2;
		fetch_2 : begin
			if (mem_resp == 1'b1)
				next_states = fetch_3;
		end
		fetch_3 : next_states = decode;
		decode : begin
			case (opcode)
				op_lui : next_states = lui;
				op_auipc : next_states = auipc;
				op_jal : next_states = jal;
				op_jalr : next_states = jalr;
				op_br : next_states = br;
				op_load : next_states = calc_addr;
				op_store : next_states = calc_addr;
				op_imm : next_states = imm;
				op_reg : next_states = sreg;
				op_csr : $fatal("csr not implemented");
				default : $fatal("Illegal opcode detected");
			endcase
		end
		imm : next_states = fetch_1;
		sreg : next_states = fetch_1;
		lui : next_states = fetch_1;
		br : next_states = fetch_1;
		auipc : next_states = fetch_1;
		calc_addr : begin
			case (opcode)
				op_load : next_states = ld1;
				op_store : next_states = st1;
				default : $fatal("Incorrect Opcode at calc_addr");
			endcase
		end
		ld1 : begin	
			if( mem_resp == 1'b1)
				next_states = ld2;
		end
		ld2 : next_states = fetch_1;
		st1 : begin
			if( mem_resp == 1'b1)
				next_states = st2;
		end
		st2 : next_states = fetch_1;
		jal : next_states = fetch_1;
		jalr : next_states = fetch_1;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	state <= next_states;
end

endmodule : control
