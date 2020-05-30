
module array_same_c #(
	parameter s_index = 3,
	parameter width = 1,
	parameter num_sets = 2**s_index

)
(
    clk,
    read,
    load,
    rindex,
    windex,
    datain,
    dataout
);

input clk;
input read;
input load;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [width-1:0] datain;
output logic [width-1:0] dataout;

logic [width-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */= '{default: '0};
logic [width-1:0] _dataout;
assign dataout = _dataout;

always_comb
begin
	if (read)
		_dataout = (load & (rindex == windex)) ? datain : data[rindex];
	else
		_dataout = '0;
end

always_ff @(posedge clk)
begin
    if(load)
        data[windex] <= datain;
end

endmodule : array_same_c
