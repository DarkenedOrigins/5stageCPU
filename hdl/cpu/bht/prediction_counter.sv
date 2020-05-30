module pred_counter#(
	parameter s_index = 5,
	parameter num_sets = 2**s_index
)
(
	input clk,
	input logic read,
	input logic branch_res,
	input logic [s_index-1:0] rindex,
	input logic [s_index-1:0] windex,
	input logic branch_taken,
	output logic branch_pred
);

logic [1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */= '{default: 2'b01};

always_comb
begin
	branch_pred = 1'b0;
	if (read) begin
		unique case(data[rindex])
			2'b00 : branch_pred = 1'b0;
			2'b01 : branch_pred = 1'b0;
			2'b10 : branch_pred = 1'b1;
			2'b11 : branch_pred = 1'b1;
		endcase
	end
end

always_ff @(posedge clk)
begin
	if(branch_res) begin
		unique case(data[windex])
		2'b00 : data[windex] <= (branch_taken) ? 2'b01 : 2'b00;
		2'b01,2'b10 : data[windex] <= (branch_taken) ? data[windex]+1 : data[windex]-1;
		2'b11 : data[windex] <= (branch_taken) ? 2'b11 : 2'b10;
		endcase
	end
end

endmodule
