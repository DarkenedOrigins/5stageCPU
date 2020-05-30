module arbiter #(parameter  cwidth = 256, lwidth = 256)
(
	//i cache
	input logic iread, iresp_reg,
	input logic [31:0] iaddr,
	output logic [cwidth-1:0] irdata,
	output logic iresp,

	//dcache
	input logic dread, dresp_reg,
	input logic dwrite,
	input logic [31:0] daddr,
	input logic [cwidth-1 : 0] dwdata,
	output logic [cwidth-1:0] drdata,
	output logic dresp,

	//l2 cache
	input  logic [lwidth-1: 0] rdata,
	input logic resp,
	output logic read,
	output logic write,
	output logic [31:0] addr,
	output logic [lwidth-1:0] wdata
);

// just a bunch of muxy bois
//these need to be hard coded
always_comb begin
	//i cache
	irdata = (~iread & ~iresp_reg)? {cwidth{1'b0}} : rdata; 
	iresp = (iread & ~iresp_reg)? resp : 1'b0;
	//d cache 
	drdata = (iread & ~iresp_reg)? {cwidth{1'b0}} : rdata; 
	dresp = (~iread & ~iresp_reg)? resp : 1'b0;
	//to l2 cache
	read = (iread & ~iresp_reg)? iread : dread & ~dresp_reg;
	write = (iread & ~iresp_reg)? 1'b0 : dwrite & ~dresp_reg;
	addr = (iread & ~iresp_reg)? iaddr : daddr;
	wdata = dwdata;
end

endmodule : arbiter
