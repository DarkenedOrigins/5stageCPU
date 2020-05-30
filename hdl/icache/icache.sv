module icache #(
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
    //input logic read_a,
    input logic clk,
    input logic stall,
    input logic hazard_stall,
    input logic [s_mask-1:0] address_a,
    input logic [s_line-1:0] mem_data_a,
    input logic mem_resp_a,
    input logic branch_was_taken,
    output logic mem_read_a,
    output logic [s_mask-1:0] mem_addr_a,
    output logic [s_mask-1:0] rdata_a,
    output logic resp_a
    //output logic stall
  );
  enum int unsigned{start_s, hit_s, miss_s} state, next_state;
  logic addr_muxsel;
//  logic start_stall , start_stall_reg;
/* the bug that needs to be fixed is that when a dcache read/write is called, the icache will move one cycle too far causing the wrong */
  logic [s_mask-1:0] prev_addr;
  logic [1:0] valid_out;
  logic [31:0] data_write [1:0];
  logic [s_line-1:0] data_out [1:0];
  logic [s_tag-1:0] tag_out [1:0];
  logic [s_mask-1:0] addr;
  logic lru_out, lru_in, hit, tagArray1hit, tagArray2hit, data_out_sel;
  always @ (posedge clk) begin
    prev_addr <= addr;
  end
  always_comb begin
    addr = (addr_muxsel) ? address_a : prev_addr;
	 tagArray1hit = valid_out[0] & (tag_out[0] == prev_addr[s_mask-1:s_mask-s_tag]);
    tagArray2hit = valid_out[1] & (tag_out[1] == prev_addr[s_mask-1:s_mask-s_tag]);
/*
    lru_in = ~(tagArray2hit) | (data_write[0][0]);
    rdata_a = (prev_hit) ? data_out[1][(32*prev_addr[4:2]) +: 32] : data_out[0][(32*prev_addr[4:2]) +: 32];
    tagArray1hit = valid_out[0] & (tag_out[0] == address_a[s_mask-1:s_mask-s_tag]);
    tagArray2hit = valid_out[1] & (tag_out[1] == address_a[s_mask-1:s_mask-s_tag]);
    hit = (tagArray1hit) | (tagArray2hit);
*/
	 hit = (tagArray1hit) | (tagArray2hit);
    lru_in = ~(tagArray2hit) | (~hit & ~lru_out);
    //rdata_a = branch_was_taken ? (32'h00000013): ((data_out_sel) ? (data_out[1][(32*prev_addr[4:2]) +: 32]) : (data_out[0][(32*prev_addr[4:2]) +: 32]));
    //if (branch_was_taken) rdata_a = 32'h00000013;
	 if (tagArray2hit) rdata_a = data_out[1][(32*prev_addr[4:2]) +: 32];
	 else rdata_a = data_out[0][(32*prev_addr[4:2]) +: 32];
	 // tagArray1hit = (tag_out[0] == address_a[s_mask-1:s_mask-s_tag]) ? 1'b1 : 1'b0;
    // tagArray2hit = (tag_out[1] == address_a[s_mask-1:s_mask-s_tag]) ? 1'b1 : 1'b0;
    data_write[0] = {32{~(hit | lru_out)}};
    data_write[1] = {32{~hit & lru_out}};
    data_out_sel = (tagArray2hit) | (data_write[1][0]);
    resp_a = hit | (state == start_s);
    mem_addr_a = addr;
    mem_read_a = ~hit;
  end
  always_comb begin
     unique case (state)
	     hit_s: begin
		    if (hit & (stall & ~hazard_stall) ) addr_muxsel = 1'b1;
			 else addr_muxsel = 1'b0;
			 end
		  miss_s: addr_muxsel = 1'b0;
		  start_s: begin
		     addr_muxsel = 1'b1;
			  end
	  endcase
  end
  always_comb begin
     next_state = start_s;
     unique case (state)
	    start_s: next_state = miss_s;
		  miss_s: next_state = (mem_resp_a) ? hit_s : miss_s;
		  hit_s: begin
		     if (hit) next_state = hit_s;
			  else next_state = miss_s;
			end
		  default: next_state = state;
	  endcase
  end
  always_ff @(posedge clk) begin
     state <= next_state;
  end
  data_array #(s_index, s_offset, s_mask, s_line, num_sets) line_cache[1:0] (
          .clk(clk),
          .read(1'b1),
          //.write(data_write),
          .write_en(data_write),
          .rindex(addr[s_index+s_offset-1:s_offset]),
          .windex(prev_addr[s_index+s_offset-1:s_offset]),
          .datain(mem_data_a),
          .dataout(data_out)
  );
  array #(s_index, 1, num_sets) valid[1:0] (
          .clk(clk),
          .read(1'b1),
          .load({mem_resp_a & lru_out, mem_resp_a & ~lru_out}),
          .rindex(addr[s_index+s_offset-1:s_offset]),
          .windex(prev_addr[s_index+s_offset-1:s_offset]),
          .datain(1'b1),
          .dataout(valid_out)
  );
  array #(s_index, s_tag, num_sets) tag[1:0] (
          .clk(clk),
          .read(1'b1),
          .load({mem_resp_a & lru_out, mem_resp_a & ~lru_out}),
          .rindex(addr[s_index+s_offset-1:s_offset]),
          .windex(prev_addr[s_index+s_offset-1:s_offset]),
          .datain(addr[s_mask-1:s_mask-s_tag]),
          .dataout(tag_out)
  );
  array #(s_index, 1, num_sets) lru(
          .clk(clk),
          .read(1'b1),
          .load(mem_resp_a | hit),
          .rindex(addr[s_index+s_offset-1:s_offset]),
          .windex(prev_addr[s_index+s_offset-1:s_offset]),
          .datain(lru_in),
          .dataout(lru_out)
  );


endmodule
