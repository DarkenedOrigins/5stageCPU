
module dcache #(
      parameter s_off    = 5,
      parameter s_index  = 3,
      parameter s_bank   = 0,
      parameter s_offset = s_off + s_bank,
      parameter s_tag    = 32 - s_offset - s_index,
      parameter s_mask   = 2**s_off,
      parameter s_line   = 8*s_mask,
      parameter num_sets = 2**s_index
  )
  (
  input logic clk,
  input logic stall, 
  input logic [s_line-1:0] mem_rdata_b,
  input logic mem_resp_b,
  input logic read_b,
  input logic write,
  input logic [3:0] wmask,
  input logic [s_mask-1:0] address_b,
  input logic [s_mask-1:0] wdata,
  output logic resp_b,
  output logic [s_mask-1:0] rdata_b,
  output logic mem_read_b,
  output logic mem_write_b,
  output logic [s_mask-1:0] mem_addr_b,
  output logic [s_line-1:0] mem_wdata_b
);
  enum int unsigned{start_s, miss_s, hit_s, write_back_s} state, next_state;
  logic [s_mask-1:0] prev_addr, prev_wdata, in_write_en;
  logic [s_mask-1:0] write_en [1:0];
  logic prev_write, prev_rw, read_lru;
  logic [3:0] prev_wmask;
  logic [s_mask-1:s_mask-s_tag] prev_tag;
  logic [1:0] valid_out, dirty_out;
  logic [s_line-1:0] data_write;
  logic [s_line-1:0] data_out [1:0];
  logic [s_line-1:0] in_wdata, data_o;
  logic [s_tag-1:0] tag_out [1:0];
  logic [s_mask-1:0] addr;
  logic [s_mask-1:0] temp_mem_addr;
  logic lru_out, lru_in, hit, tagArray1hit, tagArray2hit, data_out_sel, dirty, addrmux_sel;
  always @ (posedge clk) begin
    prev_addr <= (read_b | write) ? addr : prev_addr;
    prev_write <= (hit | state == start_s) & stall ? write : prev_write;
    prev_wdata <= (hit | state == start_s) & stall ? wdata : prev_wdata;
    prev_wmask <= (hit | state == start_s) & stall ? wmask : prev_wmask;
    prev_rw <= (hit | state == start_s) & stall ? read_b | write : prev_rw;
  end
  always_comb begin
    addr = (addrmux_sel) ? address_b : prev_addr;
	 tagArray1hit = valid_out[0] & (tag_out[0] == prev_addr[s_mask-1:s_mask-s_tag]);
    tagArray2hit = valid_out[1] & (tag_out[1] == prev_addr[s_mask-1:s_mask-s_tag]);
	 hit = ((tagArray1hit) | (tagArray2hit)) & (state != start_s);
    lru_in = ~(tagArray2hit ) | (~hit & ~lru_out);
    //rdata_b = (data_out_sel) ? data_out[1][(32*prev_addr[4:2]) +: 32] : data_out[0][(32*prev_addr[4:2]) +: 32];
    write_en[0] = (prev_write & tagArray1hit) ? in_write_en : {32{~(hit | lru_out) & next_state != write_back_s}};
    write_en[1] = (prev_write & tagArray2hit) ? in_write_en : {32{~hit & lru_out & next_state != write_back_s}};
    data_out_sel = (tagArray2hit) | (~((tagArray1hit) | (tagArray2hit)) & lru_out);
    resp_b = (state == start_s) | (state == hit_s & next_state == hit_s); //hit | (state == start_s);
    temp_mem_addr[s_mask-1:s_off] = data_out_sel ? {tag_out[1], prev_addr[s_offset+s_index-1:s_off]} : {tag_out[0], prev_addr[s_offset+s_index-1:s_off]};
    temp_mem_addr[s_off-1:0] = '0;
    mem_addr_b = (state == write_back_s) ? /* data_out_sel ? {tag_out[1], prev_addr[s_offset+s_index-1:s_offset],5'b0} :
				{tag_out[0], prev_addr[s_offset+s_index-1:s_offset],5'b0}*/ temp_mem_addr : addr;
    data_write = (state == miss_s) ? mem_rdata_b : in_wdata;
    dirty = (dirty_out[1] & lru_out) | (dirty_out[0] & ~lru_out);
    data_o = ((tagArray2hit) | (~((tagArray1hit) | (tagArray2hit)) & lru_out)) ? data_out[1] : data_out[0];
    mem_wdata_b = data_o;
	 read_lru = read_b | write;
	 prev_tag = prev_addr[s_mask-1:s_mask-s_tag];
  end
  data_array #(s_index, s_offset, s_mask, s_line, num_sets) data[1:0](
        .read(read_b | write | mem_resp_b),
        .clk(clk),
        .rindex(addr[s_index+s_offset-1:s_offset]),
        .windex(prev_addr[s_index+s_offset-1:s_offset]),
        .datain(data_write),
        .dataout(data_out),
        //.write(write),
        .write_en(write_en) // need to change this to include write_prev
  );
  array #(s_index, 1, num_sets) valid[1:0](
        .clk(clk),
        .rindex(addr[s_index+s_offset-1:s_offset]),
        .windex(prev_addr[s_index+s_offset-1:s_offset]),
        .read(read_b | write | (mem_resp_b & mem_read_b)),
        .load({mem_resp_b & mem_read_b & lru_out, mem_resp_b & mem_read_b & ~lru_out}),
        .datain(1'b1),
        .dataout(valid_out)
  );
  array #(s_index, 1, num_sets) _dirty[1:0](
        .clk(clk),
        .rindex(addr[s_index+s_offset-1:s_offset]),
        .windex(prev_addr[s_index+s_offset-1:s_offset]),
        .read(read_b | write),
        .load({(mem_resp_b & mem_read_b & lru_out) | (prev_write & tagArray2hit), (mem_resp_b & mem_read_b & ~lru_out) | (prev_write & tagArray1hit)}),
        .datain(prev_write),
        .dataout(dirty_out)
  );
  array #(s_index, s_tag, num_sets) tag[1:0](
        .clk(clk),
        .rindex(addr[s_index+s_offset-1:s_offset]),
        .windex(prev_addr[s_index+s_offset-1:s_offset]),
        .read(read_b | write | (mem_resp_b & mem_read_b)),
        .load({mem_resp_b & mem_read_b & lru_out, mem_resp_b & mem_read_b & ~lru_out}),
        .datain(prev_addr[s_mask-1:s_mask-s_tag]),
        .dataout(tag_out)
  );
  array #(s_index, 1, num_sets) lru(
        .clk(clk),
        .rindex(addr[s_index+s_offset-1:s_offset]),
        .windex(prev_addr[s_index+s_offset-1:s_offset]),
        .read(read_b | write),
        .load(hit|(mem_resp_b & mem_read_b)),
        .datain(lru_in),
        .dataout(lru_out)
  );
  line_adapter adapter(
        .mem_wdata256(in_wdata),
        .mem_rdata256(data_o),
        .mem_wdata(prev_wdata),
        .mem_rdata(rdata_b),
        .mem_byte_enable(prev_wmask),
        .mem_byte_enable256(in_write_en),
        .resp_address(prev_addr),
        .address(prev_addr)
  );
  always_comb begin
    mem_read_b = 1'b0;
    mem_write_b = 1'b0;
    case (state)
      start_s: addrmux_sel = 1'b1;
      hit_s: addrmux_sel = hit & stall ? 1'b1 : 1'b0;
      miss_s: begin
        addrmux_sel = 1'b0;
        mem_read_b = 1'b1;
      end
      write_back_s: begin
        addrmux_sel = 1'b0;
        mem_write_b = 1'b1;
      end
		//write_s: begin
		//  addrmux_sel = 1'b0;
		//end
      default: addrmux_sel = 1'b1;
    endcase
  end

  always_comb begin
    next_state = state;
    case (state)
      start_s: if (read_b | write) next_state = miss_s;
      miss_s: if (mem_resp_b) next_state = hit_s;
      hit_s: begin
		  if (prev_rw) begin
          case ({dirty, hit})
            2'b10: next_state = write_back_s;
            2'b00: next_state = miss_s;
            default: next_state = hit_s;
          endcase
		  end
      end
      write_back_s: if (mem_resp_b) next_state = miss_s;
		//write: next_state = hit_s;
      default: next_state = state;
    endcase
  end

  always @ (posedge clk) begin
    state <= next_state;
  end

endmodule : dcache
