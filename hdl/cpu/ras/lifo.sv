module lifo #(
	parameter width = 32
)(
	input clk,
	input logic [width-1:0] datain,
	input logic push,
	input logic pop,
	output logic [width-1:0] peek,
	output logic empty
);

logic [width-1:0] stack [15:0] /* synthesis ramstyle = "logic" */= '{default: '0};

logic [4:0] top_ptr = '0;
logic [4:0] top_push_ptr, top_pop_ptr;

logic full;

assign empty = (top_ptr == 5'b00000);
assign full = (top_ptr[4]);
assign top_push_ptr = top_ptr+1;
assign top_pop_ptr = top_ptr-1;

always_ff @(posedge clk) begin
	if(push & ~full) begin
		stack[top_ptr[3:0]] <= datain;
		top_ptr <= top_push_ptr;
	end
	else if(pop & ~empty) begin
		stack[top_pop_ptr[3:0]] <= '0;
		top_ptr <= top_pop_ptr;
	end
end

always_comb begin
	if(~empty)
		peek = stack[top_pop_ptr[3:0]];
	else
		peek = '0;
end

endmodule
