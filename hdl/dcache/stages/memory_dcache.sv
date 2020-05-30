dcache_types::*;

module memory_dcache #(
      parameter s_offset = 5,
      parameter s_index  = 3,
      parameter s_tag    = 32 - s_offset - s_index,
      parameter s_mask   = 2**s_offset,
      parameter s_line   = 8*s_mask,
      parameter num_sets = 2**s_index
  )
  (
  input dcache_block inblock,
  input logic mem_resp_b,
  output logic mem_read_b,
  output logic mem_write_b,
  output logic [s_mask-1:0] mem_addr_b,
  output logic [s_mask-1:0] rdata_b,
  output logic stall_b,
  output logic resp_b
  );
logic [s_mask-1:0] write_en;
logic write [1:0];
logic [s_mask-1:0] in_write_en;
logic [s_line-1:0] in_wdata;
//logic [s_mask-1:0] read_addr;
//logic [s_mask-1:0] write_addr;
logic [s_line-1:0] wdata;
logic [s_line-1:0] data_o;
logic [s_line-1:0] data_out [1:0];
always_comb begin
    write_en = (mem_resp_b) ? 32'hffffffff : in_write_en;
    wdata = (mem_resp_b) ? mem_data : in_wdata;
    data_o = (inblock.tagArray2hit) ? data_out[1] : data_out[0];
    write[0] = (inblock.write & inblock.hit & ~inblock.tagArray2hit) | ~(inblock.hit & inblock.lru_in);
    write[1] = (inblock.write & inblock.hit & inblock.tagArray2hit) | (inblock.hit & inblock.lru_in);
    stall_b = inblock.hit; //not correct
end
data_array #(s_index, s_offset, s_mask, s_line, num_sets) data[1:0](
        .read(inblock.read),
        .clk(clk),
        .rindex(inblock.addr),
        .windex(inblock.addr),
        .datain(wdata),
        .dataout(data_out),
        .write(write),
        .write_en(write_en)
);
line_adapter adapter(
        .mem_wdata256(in_wdata),
        .mem_rdata256(data_o),
        .mem_wdata(inblock.wdata),
        .mem_rdata(rdata_b),
        .mem_byte_enable(inblock.write_en),
        .mem_byte_enable256(in_write_en),
        .resp_address(inblock.addr),
        .address(inblock.addr)
);
endmodule : memory_dcache
