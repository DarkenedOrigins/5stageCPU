import datapath_types::*;
import rv32i_types::*;
import rvfimon_types::*;

module cpu_datapath(
	input clk,

	// I-CACHE
    input resp_a,
    input [31:0] rdata_a,
    output logic read_a,
    output logic [31:0] address_a,

	// D-CACHE
	input resp_b,
	input [31:0] rdata_b,
	//input stall_b,
	output logic read_b,
	output logic write,
	output logic [3:0] wmask,
	output logic [31:0] address_b,

	output logic [31:0] wdata,
	// stall signals
	input logic stall,
	output logic out_stall,
	output logic ex_stall,
	output logic branch_was_taken
);

rvfimon_t fch_rvfi = '0, dec_rvfi = '0, exe_rvfi  = '0, mem_rvfi = '0, wb_rvfi = '0;
rvfimon_t fch_dec_rvfi_latch = '0, dec_exe_rvfi_latch = '0, exe_mem_rvfi_latch, mem_wb_rvfi_latch = '0;
logic [31:0] prev_i_addr;
logic [31:0] prev_d_addr;
logic [31:0] prev_wdata;
logic [3:0] prev_wmask;

/***********************Block Registers*************************/
fetch_decode_block in_fch_dec = '{default: '0}, data_fch_dec = '{default: '0}, out_fch_dec = '{default: '0};
decode_exe_block in_dec_exe = '{default: '0}, data_dec_exe = '{default: '0}, out_dec_exe = '{default: '0};
exe_mem_block in_exe_mem = '{default: '0}, data_exe_mem = '{default: '0}, out_exe_mem = '{default: '0};
mem_wb_block in_mem_wb = '{default: '0}, data_mem_wb = '{default: '0}, out_mem_wb = '{default: '0};
pcmux::pcmux_sel_t pcmux_sel;

logic exe_stall;
logic hazard_stall;

logic branch_taken;
logic correct_return;
logic correct_prediction, jump_miss, branch_mispredict, return_mispredict;
logic need_flush;
logic return_predict, return_flush;
/******************* FLUSH PIPELINE LOGIC *********************/

assign branch_taken  = (pcmux_sel != pcmux::pc_plus4) & ~hazard_stall & (out_dec_exe.cw_reg.opcode == op_br);
assign branch_mispredict  = (branch_taken != out_dec_exe.branch_guess) && (out_dec_exe.cw_reg.opcode == op_br) && (~hazard_stall);
assign jump_miss = (out_dec_exe.cw_reg.opcode == op_jal) && (~out_dec_exe.jump_det);
assign return_mispredict = (out_dec_exe.cw_reg.opcode == op_jalr) && ~correct_return;
assign need_flush = branch_mispredict | jump_miss | return_mispredict;
assign return_flush = return_predict && (in_dec_exe.cw_reg.opcode == op_jalr);
assign ex_stall = exe_stall;
/**************************************************************/
assign out_stall = hazard_stall | exe_stall;

always_ff @(posedge clk) begin
	if (stall & ~exe_stall) begin
		branch_was_taken <= need_flush | return_flush;
//		prev_i_addr <= address_a;
		prev_d_addr <= address_b;
//		prev_wdata <= wdata;
		if (hazard_stall) begin
			data_mem_wb <= in_mem_wb;
			data_exe_mem <= '0;
		end
		else begin
			data_fch_dec <= need_flush | return_flush ? '0 : in_fch_dec;
			data_dec_exe <= need_flush ? '0 : in_dec_exe;
			data_exe_mem <= in_exe_mem;
			data_mem_wb <= in_mem_wb;
			prev_i_addr <= address_a;
			//prev_d_addr <= address_b;
			prev_wdata <= wdata;
			prev_wmask <= wmask;
		end
	end
	// RVFI MONITOR BLOCKS
	if(stall & ~exe_stall) begin
		if(hazard_stall) begin
			exe_mem_rvfi_latch <= '0;
			mem_wb_rvfi_latch <= mem_rvfi;
		end
		else begin
			fch_dec_rvfi_latch <= need_flush | return_flush ? '0 : fch_rvfi;
			dec_exe_rvfi_latch <= need_flush ? '0 : dec_rvfi;
			exe_mem_rvfi_latch <= exe_rvfi;
			mem_wb_rvfi_latch <= mem_rvfi;
		end
	end
	
end

always_comb begin
	out_fch_dec = data_fch_dec;
	out_dec_exe = data_dec_exe;
	out_exe_mem = data_exe_mem;
	out_mem_wb = data_mem_wb;
end

/********************************************************/
logic [31:0] alu_out;
logic [31:0] alu_target;
// BRANCH PREDICTION
logic [31:0] branch_target;
logic guess_branch;
logic [4:0] branch_history;

branch_predictor Br_pred(
	.clk(clk),
	.PC_in(address_a),
	.exe_block_b(data_dec_exe),
	.branch_taken(branch_taken),
	.branch_target(alu_target),
	.pred_PC(branch_target),
	.guess_branch(guess_branch),
	.branch_history(branch_history)
);


logic load_reg;
logic [4:0] rd;
logic [31:0] regfile_wdata;

// JUMP TARGET BUFFER & RETURN ADDRESS STACK
logic [31:0] jump_target;
logic jump_hit;
logic [31:0] return_target;


jump_target_buffer Jtb(
	.clk(clk),
	.PC_in(address_a),
	.exe_block_j(data_dec_exe),
	.jump_target(alu_target),
	.jump_PC(jump_target),
	.jump_hit(jump_hit)
);

return_address_stack Ras(
	.clk(clk),
	.exe_block_r(data_dec_exe),
	.jump_target(alu_target),
	.decode_out_r(in_dec_exe),
	.return_predict(return_predict),
	.return_target(return_target),
	.correct_return(correct_return),
	.stall(stall & ~hazard_stall & ~exe_stall)
);

// FORWARDING
logic [31:0] rs1_for, rs2_for;
logic [31:0] wdata_for;

forward_logic Forward_logic(
	.clk(clk),
	.exe_block(data_dec_exe),
	.mem_block(data_exe_mem),
	.wb_block(data_mem_wb),
	.rdata(regfile_wdata),
	.rs1_out(rs1_for),
	.rs2_out(rs2_for),
	.wdata(wdata_for),
	.hazard_stall(hazard_stall)
);

logic [31:0] pc_in_val;
//RVFI MONITOR FCH BLOCK
always_comb begin
	fch_rvfi = '0;
	fch_rvfi.valid = 1'b1;
	fch_rvfi.pc_rdata = address_a;
	fch_rvfi.pc_wdata = pc_in_val;
end

fetch fetch(
	.clk(clk), 
	.alu_out(alu_target), 
	.out_block(in_fch_dec), 
	.stall(stall & ~hazard_stall & ~exe_stall), 
	.misprediction(need_flush), 
	.exe_pc(data_dec_exe.pc_reg),
	.*
);
// RVFI MONITOR DEC BLOCK
always_comb begin
	dec_rvfi = fch_dec_rvfi_latch;
	dec_rvfi.insn = rdata_a;
	dec_rvfi.rs1_addr = in_dec_exe.cw_reg.rs1;
	dec_rvfi.rs2_addr = in_dec_exe.cw_reg.rs2;
	dec_rvfi.rd_addr = in_dec_exe.cw_reg.rd;
	dec_rvfi.mem_rmask = {4{in_dec_exe.cw_reg.mem_read}};
	dec_rvfi.mem_wmask = in_dec_exe.cw_reg.mem_byte_enable;
	case(in_dec_exe.cw_reg.opcode)
		op_lui,op_auipc,op_jal,op_jalr,op_br,op_load,op_store,op_imm,op_reg: ;
		default : dec_rvfi.trap = 1'b1;

	endcase
end

decode decode(
	.clk(clk),
	.in_block(out_fch_dec),
	.load_reg(out_mem_wb.cw_reg.load_regfile),
	.rd(out_mem_wb.cw_reg.rd),
	.regfile_wdata(regfile_wdata),
	.instr(rdata_a),
//	.branch_taken(branch_taken),
	.stall(stall),
	.out_block(in_dec_exe)
);
// RVFI MONITOR EXE BLOCK
always_comb begin
	exe_rvfi = dec_exe_rvfi_latch;
	exe_rvfi.rs1_rdata = rs1_for;
	exe_rvfi.rs2_rdata = rs2_for;
	case (pcmux_sel)
		pcmux::pc_plus4 : exe_rvfi.pc_wdata = exe_rvfi.pc_rdata+4;
		pcmux::alu_out : exe_rvfi.pc_wdata = alu_out;
		pcmux::alu_mod2 : exe_rvfi.pc_wdata = {alu_out[31:1], 1'b0};
	endcase
end

execute execute(
	.clk(clk),
	.in_block(out_dec_exe), 
	.pcmux_sel_out(pcmux_sel), 
	.out_block(in_exe_mem), 
	.alu_out(alu_out),
	.alu_target(alu_target),
	.rs1(rs1_for),
	.rs2(rs2_for),
	.stall(exe_stall),
	.hazard_stall(hazard_stall)
);
// RVFI MONITOR MEM BLOCK
always_comb begin
	mem_rvfi = exe_mem_rvfi_latch;
	mem_rvfi.mem_wmask = wmask & {4{write}};
	mem_rvfi.mem_rmask = (in_mem_wb.cw_reg.mem_byte_enable & {4{read_b}}) << out_exe_mem.alu_out_reg[1:0];
	mem_rvfi.mem_wdata = wdata & {32{write}};
	mem_rvfi.mem_addr = address_b;
end

mem Memory(.in_block(out_exe_mem), .out_block(in_mem_wb),.rs2(wdata_for), .*);
// RVFI MONITOR WB BLOCK
always_comb begin
	wb_rvfi = mem_wb_rvfi_latch;
	wb_rvfi.rd_wdata = regfile_wdata;
	wb_rvfi.mem_rdata = rdata_b;
end

writeback writeback(.in_block(out_mem_wb), .rdata(rdata_b), .regfile_wdata(regfile_wdata) );


endmodule : cpu_datapath
