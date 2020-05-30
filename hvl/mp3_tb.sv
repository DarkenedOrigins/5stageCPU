module mp3_tb;

timeunit 100ps;
timeprecision 100ps;

/***************** DECLARATIONS **************************************/
logic commit;
//assign commit = dut.cpu.commit;
logic [63:0] order;
initial order = 0;
tb_itf itf();
always @(posedge itf.clk iff commit) order <= order+1;
int timeout = 100000000; //change timeout
assign itf.registers = dut.cpu.decode.regfile.data;
// need to set this later...
assign itf.halt =  (dut.cpu.execute.in_block.cw_reg.is_branch || dut.cpu.execute.in_block.cw_reg.opcode == 7'b1101111) & (dut.cpu.execute.alu_out == dut.cpu.execute.in_block.pc_reg);
//assign itf.halt = 1'b0;


/************************ PERFORMANCE COUNTERS *** ********************/
int total_branches = 0;
int correct_branch_predictions = 0;
int total_unconditional_jumps = 0;
int correct_jump_predictions = 0;
int total_jalr = 0;
int correct_return_predictions = 0;
always @(posedge itf.clk) begin
	if( (~itf.halt) && (dut.stall) && (dut.cpu.execute.in_block.cw_reg.opcode == 7'b1100011) ) begin // if branch opcode detected
		total_branches <= total_branches+1;
		if(~dut.cpu.branch_mispredict)
			correct_branch_predictions <= correct_branch_predictions+1;
	end
	if( (dut.stall) && (dut.cpu.execute.in_block.cw_reg.opcode == 7'b1101111) ) begin
		total_unconditional_jumps <= total_unconditional_jumps+1;
		if(~dut.cpu.jump_miss)
			correct_jump_predictions <= correct_jump_predictions+1;
	end
	if( (dut.stall) && (dut.cpu.execute.in_block.cw_reg.opcode == 7'b1100111) ) begin
		total_jalr <= total_jalr + 1;
		if(~dut.cpu.return_mispredict)
			correct_return_predictions <= correct_return_predictions+1;
	end
	// debugging legacy, uncomment at your own risc
	// get it?
//	if(dut.cpu.execute.in_block.pc_reg == 32'h000001C0) begin
//		$display("Branch at 0x1C0 reached! at time %0t", $time);
//		$display("X14 value: %x", dut.cpu.rs1_for);
//		$display("X15 value: %x", dut.cpu.rs2_for);
//	end
//	if(dut.cpu.address_b == 32'h00001418) begin
//		$display("Address x1418 used at time %0t", $time);
//		if(dut.cpu.write)
//			$display("wdata: %x", dut.cpu.wdata);
//	end
end
/**********************************************************************/
//always_comb begin
//	if( (dut.cpu.wb_rvfi.mem_addr == 32'h00000980) && dut.cpu.wb_rvfi.mem_wmask) begin
//		repeat (30) @ (posedge itf.clk);
//		$display("writing to 0x980 detected!");
//		$finish;
//	end
//end

/************************ ERROR HALTING CONDITIONS ********************/
always @(itf.errcode iff (itf.errcode !=0)) begin
	repeat (30) @(posedge itf.clk);
	$display("Halting on nonzero Errorcode");
	$finish;
end

// Stop simulation on a HALT
always @(posedge itf.clk) begin
	if ( (itf.halt)  ) begin
		repeat (50) @(posedge itf.clk);
		$finish;
	end
	if (timeout == 0) begin
		$display("simulation has timed out");
		$finish;
	end
	// This just checks to see if you're ever accidentally writing into PC values
	// If this seems to break simulation later, feel free to remove all this...
	if ( (dut.cpu.wb_rvfi.mem_addr < 32'h00000c00) && (dut.cpu.wb_rvfi.mem_addr > 32'h000008a4) && (dut.cpu.wb_rvfi.mem_wmask) ) begin
		$display("write to instruction memory %0h detected with wmask %0h", dut.cpu.wb_rvfi.mem_addr, dut.cpu.wb_rvfi.mem_wmask);
		$finish;
	end
	timeout <= timeout -1;
end

always @(posedge itf.clk iff (itf.mem_read && itf.mem_write))
	$error("@%0t Simultaneous D-cache read and write detected", $time);

/**********************************************************************/
// // STALL
// // stall for roughly 10 cycles on a write to simulate a cache miss
// always_comb begin
// 	itf.stall = 1'b1;
// end
// // old mp3 with magic memory
// mp3 dut(
// 	.clk(itf.clk),
// 	.resp_a(itf.i_resp),
// 	.rdata_a(itf.i_rdata),
// 	.read_a(itf.i_read),
// 	.address_a(itf.i_address),
// 	.resp_b(itf.d_resp),
// 	.rdata_b(itf.d_rdata),
// 	.read_b(itf.d_read),
// 	.write(itf.d_write),
// 	.wmask(itf.d_wmask),
// 	.address_b(itf.d_address),
// 	.wdata(itf.d_wdata),
// 	.stall(itf.stall)
// );

// //riscv_formal_monitor_rv32i monitor(
// //	.clk(itf.clk),
// //	.reset(itf.mon_rst),
// //	
// //);


// // FAKE MEMORY,
// magic_memory_dp memory(
// 	.clk(itf.clk),
// 	.read_a(itf.i_read),
// 	.address_a(itf.i_address),
// 	.resp_a(itf.i_resp),
// 	.rdata_a(itf.i_rdata),
// 	.read_b(itf.d_read),
// 	.write(itf.d_write),
// 	.wmask(itf.d_wmask),
// 	.address_b(itf.d_address),
// 	.wdata(itf.d_wdata),
// 	.resp_b(itf.d_resp),
// 	.rdata_b(itf.d_rdata)
// );

// new mp3 with caches and arbiter
mp3 dut(
	.clk(itf.clk),
	.mem_resp(itf.mem_resp),
	.mem_rdata(itf.mem_rdata),
	.mem_read(itf.mem_read),
	.mem_write(itf.mem_write),
	.mem_addr(itf.mem_address),
	.mem_wdata(itf.mem_wdata)
);

// PHYSICAL MEMORY, NEEDS TO BE USED WITH CACHES AND ARBITER
physical_memory #(100) memory(
	.clk(itf.clk),
	.read(itf.mem_read),
	.write(itf.mem_write),
	.address(itf.mem_address),
	.wdata(itf.mem_wdata),
	.resp(itf.mem_resp),
	.rdata(itf.mem_rdata),
	.error(itf.pm_error)
);

//shadow_memory sm(
//	.clk(itf.clk),
//	.imem_valid(dut.resp_a),
//	.imem_addr(dut.Icache.prev_addr),
//	.imem_rdata(dut.rdata_a),
//	.dmem_valid(dut.bArbiter.choice ? (dut.arb_resp_b & ~dut.Dcache[1].prev_write & dut.Dcache[1].prev_rw) : (dut.arb_resp_b & ~dut.Dcache[0].prev_write & dut.Dcache[0].prev_rw)),
//	.dmem_addr(dut.bArbiter.choice ? dut.Dcache[1].prev_addr : dut.Dcache[0].prev_addr),
//	.dmem_rdata(dut.arb_rdata_b),
//	.write(dut.bArbiter.choice ? dut.Dcache[1].prev_write : dut.Dcache[0].prev_write),
//	.wmask(dut.bArbiter.choice ? dut.Dcache[1].prev_wmask : dut.Dcache[0].prev_wmask),
//	.wdata(dut.bArbiter.choice ? dut.Dcache[1].prev_wdata : dut.Dcache[0].prev_wdata),
//	.error(itf.sm_derror),
//	.poison_inst(itf.sm_ierror)
//);


shadow_memory sm(
	.clk(itf.clk),
	.imem_valid(dut.resp_a),
	.imem_addr(dut.cpu.prev_i_addr),
	.imem_rdata(dut.rdata_a),
	.dmem_valid(dut.cpu.resp_b & dut.cpu.out_mem_wb.cw_reg.mem_read),
	.dmem_addr(dut.cpu.prev_d_addr),
	.dmem_rdata(dut.cpu.rdata_b),
	.write(dut.cpu.out_mem_wb.cw_reg.mem_write),
	.wmask(dut.cpu.prev_wmask),
	.wdata(dut.cpu.prev_wdata),
	.error(itf.sm_derror),
	.poison_inst(itf.sm_ierror)
);

riscv_formal_monitor_rv32i monitor(
	.clock(itf.clk),
	.reset(itf.mon_rst),
	.rvfi_valid(dut.cpu.wb_rvfi.valid),
	.rvfi_order(dut.cpu.wb_rvfi.order),
	.rvfi_insn(dut.cpu.wb_rvfi.insn),
	.rvfi_trap(dut.cpu.wb_rvfi.trap),
	.rvfi_halt(itf.halt),
	.rvfi_intr(1'b0),
	.rvfi_mode(2'b00),
	.rvfi_rs1_addr(dut.cpu.wb_rvfi.rs1_addr),
	.rvfi_rs2_addr(dut.cpu.wb_rvfi.rs2_addr),
	.rvfi_rs1_rdata(dut.cpu.wb_rvfi.rs1_addr ? dut.cpu.wb_rvfi.rs1_rdata : 0),
	.rvfi_rs2_rdata(dut.cpu.wb_rvfi.rs2_addr ? dut.cpu.wb_rvfi.rs2_rdata : 0),
	.rvfi_rd_addr(dut.cpu.wb_rvfi.rd_addr),
	.rvfi_rd_wdata(dut.cpu.wb_rvfi.rd_addr ? dut.cpu.wb_rvfi.rd_wdata : 0),
	.rvfi_pc_rdata(dut.cpu.wb_rvfi.pc_rdata),
	.rvfi_pc_wdata(dut.cpu.wb_rvfi.pc_wdata),
	.rvfi_mem_addr(dut.cpu.wb_rvfi.mem_addr),
	.rvfi_mem_rmask(dut.cpu.wb_rvfi.mem_rmask),
	.rvfi_mem_wmask(dut.cpu.wb_rvfi.mem_wmask),
	.rvfi_mem_rdata(dut.cpu.wb_rvfi.mem_rdata),
	.rvfi_mem_wdata(dut.cpu.wb_rvfi.mem_wdata),
	.rvfi_mem_extamo(1'b0),
	.errcode(itf.errcode)

);

endmodule : mp3_tb
