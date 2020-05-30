module bank_arbiter #(
	 parameter address = 5,
    parameter lwidth = 32,
    parameter hwidth = 256
  )
  (
	 input logic clk,
	 input logic stall,
  //bank 1 to lower
    input logic b1_resp,
    input logic [lwidth-1:0] b1_rdata,
    output logic [31:0] b1_addr,
    output logic [lwidth-1:0] b1_wdata,
    output logic b1_write,
    output logic b1_read,
	 output logic [3:0] b1_wmask,

  // bank 1 from higher
    output logic b1_mem_resp,
    output logic [hwidth-1:0] b1_mem_rdata,
    input logic [hwidth-1:0] b1_mem_wdata,
    input logic [31:0] b1_mem_addr,
    input logic b1_mem_read,
    input logic b1_mem_write,

  // bank 2 to lower
    input logic b2_resp,
    input logic [lwidth-1:0] b2_rdata,
    output logic [31:0] b2_addr,
    output logic [lwidth-1:0] b2_wdata,
    output logic b2_write,
    output logic b2_read,
	 output logic [3:0] b2_wmask,

  // bank 2 from higher
    output logic b2_mem_resp,
    output logic [hwidth-1:0] b2_mem_rdata,
    input logic [hwidth-1:0] b2_mem_wdata,
    input logic [31:0] b2_mem_addr,
    input logic b2_mem_read,
    input logic b2_mem_write,

  // to higher memory
    input logic mem_resp,
    input logic [hwidth-1:0] mem_rdata,
    output logic [hwidth-1:0] mem_wdata,
    output logic [31:0] mem_addr,
    output logic mem_read,
    output logic mem_write,

  // to lower hierarchy
    output logic resp,
    output logic [lwidth-1:0] rdata,
    input logic [31:0] addr,
    input logic [lwidth-1:0] wdata,
    input logic read,
	 input logic [3:0] wmask,
    input logic write
  );
  logic next_choice, choice, copy;
  always_comb begin
    next_choice = addr[address];
    copy = choice;
    // responses
    resp = choice ? b2_resp : b1_resp;
    b1_mem_resp = choice ? '0 : mem_resp;
    b2_mem_resp = choice ? mem_resp : '0;
    // read datas
    rdata = choice ? b2_rdata : b1_rdata;
    b1_mem_rdata = choice ? '0 : mem_rdata;
    b2_mem_rdata = choice ? mem_rdata : '0;
    // wdatas
    mem_wdata = choice ? b2_mem_wdata : b1_mem_wdata;
    b1_wdata = addr[address] ? '0 : wdata;
    b2_wdata = addr[address] ? wdata : '0;
    //addresses
    mem_addr = choice ? b2_mem_addr : b1_mem_addr;
    b1_addr = addr;
    b2_addr = addr;
    // read signals
    mem_read = choice ? b2_mem_read : b1_mem_read;
    b1_read = addr[address] ? '0 : read;
    b2_read = addr[address] ? read : '0;
    // write signals
    mem_write = choice ? b2_mem_write : b1_mem_write;
    b1_write = addr[address] ? '0 : write;
    b2_write = addr[address] ? write : '0;
	 //wmask
	 b1_wmask = addr[address] ? '0 : wmask;
	 b2_wmask = addr[address] ? wmask : '0;
  end
  always_ff @ (posedge clk) begin
    choice <= b1_resp & b2_resp & stall ? next_choice : choice;
  end
endmodule //
