module array_p #(
	parameter s_index = 3,
	parameter width = 1
)
(
    input clk,
		input read,
    input load,
    input [s_index-1:0] index,
    input [width-1:0] datain,
    output logic [width-1:0] dataout
);
localparam num_sets = 2**s_index;

logic [width-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */ = '{default: '0};
logic [width-1:0] _dataout, prev_data;
assign dataout = _dataout;

always_comb begin
//    if (read)
//	     _dataout = data[index];
//	else _dataout = 1'b0;
    _dataout = read ? data[index] : prev_data;
end
always_ff @(posedge clk)
begin
	 //if (read)
    //    _dataout <= data[index];
    prev_data <= _dataout;
    if(load)
        data[index] <= datain;
end

endmodule : array_p
