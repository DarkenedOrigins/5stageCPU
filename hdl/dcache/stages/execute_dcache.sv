import dcache_types::*;

module execute_dcache #(
      parameter s_offset = 5,
      parameter s_index  = 3,
      parameter s_tag    = 32 - s_offset - s_index,
      parameter s_mask   = 2**s_offset,
      parameter s_line   = 8*s_mask,
      parameter num_sets = 2**s_index
  )
  (
  input logic clk,
  input logic [s_mask:0] address_b,
  input logic [s_mask:0] wdata_b,
  input logic mem_resp_b,
  input logic prev_addr,
  input logic read,
  output dcache_block outblock
  );
  logic valid_out [1:0], dirty_out [1:0];
  logic [s_tag-1:0] tag_out [1:0];
  logic lru_out, tagArray1hit;
  always_comb begin
    outblock.addr = address_b;
    outblock.read = read;
    outblock.write = wdata_b;
    outblock.write_en = write_en;
    outblock.wdata = mem;
    outblock.lru_in = (tagArray2hit) | ~(hit | lru_out);
    outblock.dirty = (~lru_out & dirty_out[0]) |
            (lru_out & dirty_out[1]);
    tagArray1hit = (tag_out[0] == address_a[31:s_tag-1]) ? 1'b1 : 1'b0;
    outblock.tagArray2hit = (tag_out[1] == address_a[31:s_tag-1]) ? 1'b1 : 1'b0;
    outblock.hit = (tagArray1hit & valid_out[0]) | (tagArray2hit & valid_out[1]);
  end
  array #(s_index, 1, num_sets) valid[1:0](
        .clk(clk)
        .rindex(address_b),
        .windex(prev_addr),
        .read(1'b1),
        .write(mem_resp),
        .din(1'b1),
        .dataout(valid_out)
  );
  array #(s_index, 1, num_sets) dirty[1:0](
        .clk(clk)
        .rindex(address_b),
        .windex(prev_addr),
        .read(1'b1),
        .write(mem_resp),
        .datain(write),
        .dataout(dirty_out)
  );
  array #(s_index, s_tag, num_sets) tag[1:0](
        .clk(clk)
        .rindex(address_b),
        .windex(prev_addr),
        .read(1'b1),
        .write(mem_resp),
        .din(1'b1),
        .dataout(tag_out)
  );
  array #(s_index, 1, num_sets) lru(
        .clk(clk)
        .rindex(address_b),
        .windex(prev_addr),
        .read(1'b1),
        .write(hit|mem_resp),
        .din(outblock.lru_in),
        .dataout(lru_out)
  );

endmodule : execute_dcache
