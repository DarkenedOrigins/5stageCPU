module data_array_p #(
    parameter s_offset = 5,
    parameter s_index = 3,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask
)
(
    input clk,
    input read,
    input [s_mask-1:0] write_en,
    input [s_index-1:0] index,
    input [s_line-1:0] datain,
    output logic [s_line-1:0] dataout
);


localparam num_sets = 2**s_index;

logic [s_line-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */ = '{default: '0};
logic [s_line-1:0] _dataout;
//assign dataout = _dataout;

always_comb begin
  dataout = read ? data[index] : 1'b0;  
end
always_ff @(posedge clk)
begin
	 //if (read)
	//	  _dataout <= data[index];

    for (int i = 0; i < s_mask; i++)
    begin
		data[index][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] : data[index][8*i +: 8];
    end
end

endmodule : data_array_p
