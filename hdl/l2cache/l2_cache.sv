import rv32i_types::*;

module l2cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
  input clk,
  input pmem_resp,
  input [255:0] pmem_rdata,
  input logic mem_read,
  input logic mem_write,
  //input logic [3:0] mem_byte_enable,
  input rv32i_word mem_address,
  input [255:0] mem_wdata,
  output logic pmem_read,
  output logic pmem_write,
  output rv32i_word pmem_address,
  output logic [255:0] pmem_wdata,
  output logic mem_resp,
  output logic [255:0] mem_rdata

);
//logic [255:0] mem_wdata256, mem_rdata256;
logic [255:0] dataIn;
//logic [3:0] mem_byte_enable;
logic [31:0] mem_byte_enable256, w_addr;
logic hit, miss, dirty; // pmem_resp;
logic set_dirty, load_data, read_data, read_lru, set_valid, clear_dirty;
logic set_last_used_c, set_last_used_m, load_tag, set_lru;
//assign pmem_address = mem_address;
always_comb begin
	case (pmem_write)
		1'b0: pmem_address = mem_address;
		1'b1: pmem_address = w_addr;
	endcase
	case (pmem_resp)
		1'b0: dataIn = mem_wdata;
		1'b1: dataIn = pmem_rdata;
	endcase
	mem_byte_enable256 = 32'hffffffff;
	case (pmem_resp)
		1'b0: mem_rdata = pmem_wdata;
		1'b1: mem_rdata = pmem_rdata;
	endcase
end
l2_cache_control control
(
  .pmem_read(pmem_read),
  .pmem_write(pmem_write),
  .read(mem_read),
  .write(mem_write),
  .*
);

l2_cache_datapath #(s_offset, s_index) datapath
(
  .addr(mem_address),
  //.dataIn(mem_wdata256),
  .dataOut(pmem_wdata),
  .dirty_o(dirty),
  .*
);

endmodule : l2cache
