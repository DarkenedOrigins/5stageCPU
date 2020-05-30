module cache_control (
  input logic hit, miss, read, write, dirty, pmem_resp, clk,
  output logic set_dirty, mem_resp, pmem_read, pmem_write, load_data, clear_dirty, read_data, read_lru,
  output logic set_last_used_c, set_last_used_m, load_tag, set_lru, set_valid
);
  //enum int unsigned{idle, hit_detect, store, load} state, next_state;
  enum int unsigned{hit_detect, store, load} state, next_state;

  function void set_defaults();
    set_dirty = 1'b0;
    read_data = 1'b0;
    clear_dirty = 1'b0;
    set_valid = 1'b0;
    read_lru = 1'b0;
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    load_data = 1'b0;
    set_last_used_c = 1'b0;
    set_last_used_m = 1'b0;
    load_tag = 1'b0;
    set_lru = 1'b0;
  endfunction
  always_comb begin
    set_defaults();
    unique case (state)
//      idle: if (read | write) begin
//			read_data = 1'b1;
//			read_lru = 1'b1;
//			end
      hit_detect: begin
		   if (read | write) begin
			  read_data = 1'b1;
			  read_lru = 1'b1;
			  unique case (hit)
				 1'b1: begin
					mem_resp = 1'b1;
					set_last_used_c = 1'b1;
					set_lru = 1'b1;
					//read_lru = 1'b1;
					 unique case ({read, write})
					  2'b01: begin
						 set_dirty = 1'b1;
						 load_data = 1'b1;
					  end
					  2'b10: read_data = 1'b1;
					  default: ;
					endcase
				 end
				 1'b0: begin
					//read_data = 1'b1;
					unique case (dirty)
					  1'b1: begin
						 pmem_write = 1'b1;    ///
						 if (read)             ///
							clear_dirty = 1'b1; ///
					  end
					  1'b0: begin
						 set_valid = 1'b1;
						 pmem_read = 1'b1;
					  end
					endcase
				 end
			  endcase
			end
      end
      store: begin
		  read_data = 1'b1;
		  read_lru = 1'b1;
        unique case (pmem_resp)
          1'b1: pmem_read = 1'b1;
          1'b0: pmem_write = 1'b1;
        endcase
      end
      load: begin
        unique case (pmem_resp)
          1'b1: begin
				read_data = 1'b1;
            set_lru = 1'b1;
				read_lru = 1'b1;
				set_valid = 1'b1;
            set_last_used_m = 1'b1;
            load_data = 1'b1;
            load_tag = 1'b1;
            //mem_resp = 1'b1;
          end
          default: pmem_read = 1'b1;
        endcase
      end
    endcase
  end

  always_comb begin
    next_state = state;
    unique case (state)
      //idle: if (write | read) next_state = hit_detect;
      hit_detect: begin
        case ({write|read,hit})
          2'b11: next_state = hit_detect;
          2'b10: begin
            if (dirty) next_state = store;
            else next_state = load;
          end
			 default: next_state = state;
        endcase
      end
      store: if (pmem_resp) next_state = load;
      load: if (pmem_resp) next_state = hit_detect;
      default: next_state = next_state;
    endcase
  end

  always @ (posedge clk) begin
    state <= next_state;
  end
endmodule : cache_control
