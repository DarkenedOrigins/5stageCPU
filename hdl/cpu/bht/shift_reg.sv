module shift_reg
(
	input clk,
	input logic read,
	input logic shift,
	input logic [3:0] rindex,
	input logic [3:0] windex,
	input logic shift_in,
	output logic [4:0] dataout
);

logic [4:0] data [15:0] /* synthesis ramstyle = "logic" */= '{default: '0};

always_comb
begin
	if (read)
		dataout = data[rindex];
	else
		dataout = '0;
end

always_ff @(posedge clk)
begin
	if(shift)
		data[windex] <= {data[windex][3:0], shift_in};
end

endmodule
