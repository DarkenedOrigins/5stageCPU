import rv32i_types::*;

module mp3(
	input logic clk,

//	//I-CACHE
//	input logic resp_a,
//	input logic [31:0] rdata_a,
//	output logic read_a,
//	output logic [31:0] address_a,
//
//	//D-CACHE
//	input logic resp_b,
//	input logic [31:0] rdata_b,
//	output logic read_b,
//	output logic write,
//	output logic [3:0] wmask,
//	output logic [31:0] address_b,
//	output logic [31:0] wdata,

//	input logic stall

	input logic mem_resp,
	input logic [255:0] mem_rdata,
	output logic mem_read,
	output logic mem_write,
	output logic [255:0] mem_wdata,
	output logic [31:0] mem_addr
);

logic resp_a, read_a, mem_resp_a, mem_read_a;
logic [31:0] rdata_a, address_a, mem_addr_a, temp_rdata_a;
logic [255:0] mem_data_a;
//
logic resp_b[1:0], read_b[1:0], write[1:0], mem_resp_b[1:0], mem_read_b[1:0], mem_write_b[1:0], prev_read_b, new_read_stall;
logic [3:0] wmask [1:0];
logic [31:0] rdata_b [1:0], address_b [1:0], wdata [1:0], mem_addr_b [1:0], temp_rdata;
logic [255:0] mem_rdata_b [1:0];
logic [255:0] mem_wdata_b [1:0];
logic stall;
logic hazard_stall;
logic branch_was_taken;

logic l2_resp, l2_read, l2_write;
logic [255:0] l2_rdata, l2_wdata;
logic [31:0] l2_addr; 

logic mem_resp_a_reg, mem_read_a_reg, mem_write_a_reg;
logic [255:0] mem_data_a_reg, mem_wdata_a_reg;
logic [31:0] mem_addr_a_reg; 
logic arb_mem_resp_b_reg, arb_mem_read_b_reg, arb_mem_write_b_reg;
logic [255:0] arb_mem_rdata_b_reg, arb_mem_wdata_b_reg;
logic [31:0] arb_mem_addr_b_reg; 

logic [31:0] arb_rdata_b, arb_address_b, arb_wdata;
logic [3:0] arb_wmask;
logic arb_write, arb_read_b, arb_resp_b;
logic arb_mem_resp_b, arb_mem_write_b, arb_mem_read_b;
logic [255:0] arb_mem_rdata_b, arb_mem_wdata_b;
logic [31:0] arb_mem_addr_b;
logic ex_stall;

assign stall = ~ex_stall & resp_a & (arb_resp_b | ~prev_read_b);// | (~read_b & ~write));
always_ff @(posedge clk) begin
//	prev_read_b <= (resp_b) ? read_b | write : prev_read_b;
   prev_read_b <= (arb_resp_b) ? arb_read_b | arb_write : prev_read_b;
//	rdata_b <= stall ? temp_rdata : rdata_b;
	/**/
	mem_read_a_reg <= mem_read_a; 
	mem_resp_a_reg <= mem_resp_a; 
	mem_data_a_reg <= mem_data_a; 
	mem_addr_a_reg <= mem_addr_a; 
	arb_mem_read_b_reg <= arb_mem_read_b; 
	arb_mem_resp_b_reg <= arb_mem_resp_b; 
	arb_mem_write_b_reg <= arb_mem_write_b;
	arb_mem_rdata_b_reg <= arb_mem_rdata_b; 
	arb_mem_wdata_b_reg <= arb_mem_wdata_b;
	arb_mem_addr_b_reg <=  arb_mem_addr_b; 
	/**/
end
always_comb begin
	//mem_wdata = mem_wdata_reg;
	//mem_read = mem_read_reg;
	//mem_write = mem_write_reg;
	//mem_addr = mem_addr_reg;
end
always_comb begin
	// need to make an edge detector circuit
//	new_read_stall = (~prev_read_b & read_b);
	temp_rdata_a = branch_was_taken ? 32'h00000013 : rdata_a;
end

cpu_datapath cpu(
		.rdata_a(temp_rdata_a),
		.rdata_b(arb_rdata_b),
		.read_b(arb_read_b),
		.write(arb_write),
		.wmask(arb_wmask),
		.address_b(arb_address_b),
		.wdata(arb_wdata),
		.resp_b(arb_resp_b),
		.out_stall(hazard_stall),
		.*);

icache #(5,3) Icache (
		.mem_data_a(mem_data_a),
		.mem_resp_a(mem_resp_a),
		.*);  // need a stall for the icache
dcache #(5,3,1) Dcache [1:0] (
	 .resp_b(resp_b),
	 .*);
bank_arbiter #(5, 32, 256) bArbiter(
	 .clk(clk),
	 .stall(stall),
	 .b1_resp(resp_b[0]),
    .b1_rdata(rdata_b[0]),
    .b1_addr(address_b[0]),
    .b1_wdata(wdata[0]),
    .b1_write(write[0]),
    .b1_read(read_b[0]),
	 .b1_wmask(wmask[0]),

  // bank 1 from higher
    .b1_mem_resp(mem_resp_b[0]),
    .b1_mem_rdata(mem_rdata_b[0]),
    .b1_mem_wdata(mem_wdata_b[0]),
    .b1_mem_addr(mem_addr_b[0]),
    .b1_mem_read(mem_read_b[0]),
    .b1_mem_write(mem_write_b[0]),

  // bank 2 to lower
    .b2_resp(resp_b[1]),
    .b2_rdata(rdata_b[1]),
    .b2_addr(address_b[1]),
    .b2_wdata(wdata[1]),
    .b2_write(write[1]),
    .b2_read(read_b[1]),
	 .b2_wmask(wmask[1]),

  // bank 2 from higher
    .b2_mem_resp(mem_resp_b[1]),
    .b2_mem_rdata(mem_rdata_b[1]),
    .b2_mem_wdata(mem_wdata_b[1]),
    .b2_mem_addr(mem_addr_b[1]),
    .b2_mem_read(mem_read_b[1]),
    .b2_mem_write(mem_write_b[1]),

  // to higher memory
    .mem_resp(arb_mem_resp_b),
    .mem_rdata(arb_mem_rdata_b),
    .mem_wdata(arb_mem_wdata_b),
    .mem_addr(arb_mem_addr_b),
    .mem_read(arb_mem_read_b),
    .mem_write(arb_mem_write_b),

  // to lower hierarchy
    .resp(arb_resp_b),
    .rdata(arb_rdata_b),
    .addr(arb_address_b),
    .wdata(arb_wdata),
    .read(arb_read_b),
	 .wmask(arb_wmask),
    .write(arb_write)
	);
/*
cache #(5,3) Dcache (
		.clk(clk),
		.pmem_resp(mem_resp_b),
		.pmem_rdata(mem_data_b),
		.mem_read(read_b),
		.mem_write(write),
		.mem_byte_enable(wmask),
		.mem_address(rv32i_word'(address_b)),
		.mem_wdata(rv32i_word'(wdata)),
		.pmem_read(mem_read_b),
		.pmem_write(mem_write_b),
		.pmem_address(mem_addr_b),
		.pmem_wdata(mem_wdata_b),
		.mem_resp(resp_b),
		.mem_rdata(temp_rdata)
);
*/

/**/
l2cache #(5,5) L2 (
		.clk(clk),
		.pmem_resp(mem_resp),
		.pmem_rdata(mem_rdata),
		.mem_read( /*l2_resp_reg ? 1'b0 : */l2_read),
		.mem_write(/*l2_resp_reg ? 1'b0 :*/ l2_write),
		//.mem_byte_enable(32'hffffffff),
		.mem_address(l2_addr),
		.mem_wdata(l2_wdata),
		.pmem_read(mem_read),
		.pmem_write(mem_write),
		.pmem_address(mem_addr),
		.pmem_wdata(mem_wdata),
		.mem_resp(l2_resp),
		.mem_rdata(l2_rdata));

/**/

arbiter Arbiter(
		/*.iread(mem_read_a),
		.iaddr(mem_addr_a),
	   .irdata(mem_data_a),
	   .iresp(mem_resp_a),
	   .dread(arb_mem_read_b),
	   .dwrite(arb_mem_write_b),
	   .daddr(arb_mem_addr_b),
	   .dwdata(arb_mem_wdata_b),
	   .drdata(arb_mem_rdata_b),
	   .dresp(arb_mem_resp_b),/**/
		
		/**/.iread(mem_read_a_reg),
		.iaddr(mem_addr_a_reg),
	   .irdata(mem_data_a),
	   .iresp(mem_resp_a),
	   .dread(arb_mem_read_b_reg),
	   .dwrite(arb_mem_write_b_reg),
	   .daddr(arb_mem_addr_b_reg),
	   .dwdata(arb_mem_wdata_b_reg),
	   .drdata(arb_mem_rdata_b),
	   .dresp(arb_mem_resp_b),
		.dresp_reg(arb_mem_resp_b_reg),
		.iresp_reg(mem_resp_a_reg),/**/


	//l2 cache
	   /*.rdata(mem_rdata),
	   .resp(mem_resp),
	   .read(mem_read),
	   .write(mem_write),
	   .addr(mem_addr),
	   .wdata(mem_wdata)/**/
/**	.rdata(l2_rdata_reg),
		.resp(l2_resp_reg),
		.read(l2_read),
		.write(l2_write),
		.addr(l2_addr),
		.wdata(l2_wdata) /**/
/**/	.rdata(l2_rdata),
		.resp(l2_resp),
		.read(l2_read),
		.write(l2_write),
		.addr(l2_addr),
		.wdata(l2_wdata)
/**/
		);


endmodule : mp3
