module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
  input logic clk,
  input logic [s_mask-1:0] addr, mem_byte_enable256,
  input logic [s_line-1:0] dataIn,
  input set_dirty, set_valid, clear_dirty, load_tag,
        read_data, load_data, set_last_used_c, set_lru,
        read_lru, set_last_used_m, pmem_write,
  output logic hit, miss, dirty_o,
  output logic [s_line-1:0] dataOut,
  output logic [s_mask-1:0] w_addr
);
//logic [1:0][23:0] tag_out;
logic [1:0][s_tag-1:0] tag_out;
logic [1:0] dirty_out, valid_out;
logic lru_out, lru_in;
logic [1:0][s_line-1:0] line_out;
logic [1:0][s_mask-1:0] mem_byte_enable25;
logic tagArray1hit, tagArray2hit;
logic [1:0] data_out_sel;
logic [1:0] load_valid, in_load_tag, load_dirty;
always_comb begin
  miss = ~hit;
  if ((tag_out[0] == addr[31:s_offset+s_index] && valid_out[0]))
		tagArray1hit = 1'b1;
  else tagArray1hit = 1'b0;
  if ((tag_out[1] == addr[31:s_offset+s_index] && valid_out[1]))
		tagArray2hit = 1'b1;
  else tagArray2hit = 1'b0;
  //tagArray1hit = tagArray1Out && addr[31:8];
  //tagArray2hit = tagArray2Out && addr[31:8];
  hit = (tagArray1hit) |
        (tagArray2hit);
  dirty_o = (~lru_out & dirty_out[0]) |
          (lru_out & dirty_out[1]);
  data_out_sel = {tagArray2hit  | (pmem_write && lru_out & miss), tagArray1hit  | (pmem_write && ~lru_out & miss)};
  unique case (data_out_sel)
    2'b01: w_addr = {tag_out[0], addr[s_offset+s_index-1:s_offset], 5'b0};
	 2'b10: w_addr = {tag_out[1], addr[s_offset+s_index-1:s_offset], 5'b0};
	 default: w_addr = 32'b0;
  endcase
  unique case (data_out_sel)
    2'b01: dataOut = line_out[0];
    2'b10: dataOut = line_out[1];
    default: dataOut = 256'b0;
  endcase
  unique case ({set_last_used_c, set_last_used_m})
    2'b10: lru_in = tagArray1hit;
    2'b01: lru_in = ~lru_out;
    default: lru_in = 1'b0;
  endcase
  case ({((lru_out & read_lru & miss) | tagArray2hit), load_data})
    2'b11: begin
      mem_byte_enable25[0] = 32'b0;
      mem_byte_enable25[1] = mem_byte_enable256;
    end
    2'b01: begin
      mem_byte_enable25[0] = mem_byte_enable256;
      mem_byte_enable25[1] = 32'b0;
    end
    default: begin
      mem_byte_enable25[0] = 32'b0;
      mem_byte_enable25[1] = 32'b0;
    end
  endcase
  load_valid[0] = (set_valid) & (data_out_sel[0]  | (~lru_out & read_lru  & miss));
  load_valid[1] = (set_valid) & (data_out_sel[1]  | (lru_out & read_lru & miss));
  in_load_tag[0] = load_tag & (~lru_out & read_lru & miss);
  in_load_tag[1] = load_tag & (lru_out & read_lru  & miss);
  load_dirty[0] = (set_dirty | clear_dirty) & (data_out_sel[0] | (~lru_out & read_lru & miss));
  load_dirty[1] = (set_dirty | clear_dirty) & (data_out_sel[1] | (lru_out & read_lru & miss));
end
data_array_p #(s_offset, s_index, s_mask, s_line) line[1:0](
  .clk(clk),
  .datain(dataIn),
  .dataout(line_out),
  .write_en(mem_byte_enable25),
  .read(read_data),
  .index(addr[s_offset+s_index-1:s_offset])
);
array_p #(s_index, 1) valid[1:0](
  .clk(clk),
  .datain(1'b1),
  .dataout(valid_out),
  .index(addr[s_offset+s_index-1:s_offset]),
  .read(read_data),
  .load(load_valid)
);
array_p #(s_index, 1) dirty[1:0](
  .clk(clk),
  .datain(set_dirty),
  .dataout(dirty_out),
  .index(addr[s_offset+s_index-1:s_offset]),
  .read(1'b1),
  .load(load_dirty)
);
array_p #(s_index,s_tag) tag[1:0](
  .clk(clk),
  .datain(addr[s_tag+s_index+s_offset-1:s_offset+s_index]),
  .dataout(tag_out),
  .index(addr[s_offset+s_index-1:s_offset]),
  .read(read_data),
  .load(in_load_tag)
);
/*data_array dataArray1(
  .clk(clk),
  .dataout(line_out[0]),
  .datain(dataIn),
  .write_en(mem_byte_enable256_1),
  .read(read_data),
  .index(addr[7:5])
);
data_array dataArray2(
  .clk(clk),
  .dataout(line_out[1]),
  .datain(dataIn),
  .write_en(mem_byte_enable256_2),
  .read(read_data),
  .index(addr[7:5])
);
array validArray1(
  .clk(clk),
  .datain(1'b1),
  .dataout(valid_out[0]),
  .index(addr[7:5]),
  .read(1'b1),
  .load((set_valid) & (data_out_sel[0]  | (lru_out & read_lru)))
);
array validArray2(
  .clk(clk),
  .datain(1'b1),
  .dataout(valid_out[1]),
  .index(addr[7:5]),
  .read(1'b1),
  .load((set_valid) & (data_out_sel[1] | (~lru_out & read_lru)))
);
array dirtyArray1(
  .clk(clk),
  .datain(set_dirty),
  .dataout(dirty_out[0]),
  .index(addr[7:5]),
  .read(1'b1),
  .load((set_dirty | clear_dirty) & (data_out_sel[0] | (lru_out & read_lru)))
);
array dirtyArray2(
  .clk(clk),
  .datain(set_dirty),
  .dataout(dirty_out[1]),
  .index(addr[7:5]),
  .read(1'b1),
  .load((set_dirty | clear_dirty) & (data_out_sel[1] | (~lru_out & read_lru)))
);
array #(3,24) tagArray1(
  .clk(clk),
  .datain(addr[31:8]),
  .dataout(tag_out[0]),
  .index(addr[7:5]),
  .read(read_data),
  .load(load_tag & (lru_out & read_lru))
);
array #(3,24) tagArray2(
  .clk(clk),
  .datain(addr[31:8]),
  .dataout(tag_out[1]),
  .index(addr[7:5]),
  .read(read_data),
  .load(load_tag & (~lru_out & read_lru))
);*/
array_p #(s_index, 1) LRUArray(
  .clk(clk),
  .datain(lru_in),
  .dataout(lru_out),
  .index(addr[s_offset+s_index-1:s_offset]),
  .read(read_lru),
  .load(set_lru)
);
endmodule : cache_datapath
