module shadow_memory
(
    input clk,

    input imem_valid,
    input logic [31:0] imem_addr,
    input logic [31:0] imem_rdata,
    input dmem_valid,
    input logic [31:0] dmem_addr,
    input logic [31:0] dmem_rdata,
    input write,
    input logic [3:0] wmask,
    input logic [31:0] wdata,
    output logic error,
    output logic poison_inst
);

timeunit 1ns;
timeprecision 1ns;

logic [255:0] mem [2**(22)]; //only get fraction of 4GB addressable space due to modelsim limits
logic [21:0] i_internal_address;
logic [2:0] i_internal_offset;
logic [21:0] d_internal_address;
logic [2:0] d_internal_offset;
logic [31:0] i_spec_rdata;
logic [31:0] d_spec_rdata;

/* Initialize memory contents from memory.lst file */
initial
begin
    $readmemh("memory.lst", mem);
end

/* Calculate internal address */
assign i_internal_address = imem_addr[26:5];
assign i_internal_offset = imem_addr[4:2];
assign d_internal_address = dmem_addr[26:5];
assign d_internal_offset = dmem_addr[4:2];

/* Expected values to be read */
assign i_spec_rdata = mem[i_internal_address][(i_internal_offset*32) +: 32];
assign d_spec_rdata = mem[d_internal_address][(d_internal_offset*32) +: 32];
assign error =  dmem_valid & (d_spec_rdata != dmem_rdata);
assign poison_inst = imem_valid & (i_spec_rdata != imem_rdata);
/* Update */
always @(posedge clk)
begin : mem_write
    if (write) begin
        for (int i = 0; i < 4; i++) begin
            if (wmask[i]) begin
                mem[d_internal_address][((d_internal_offset*32) + (i*8)) +: 8] = wdata[(i*8) +: 8];
            end
        end
    end
    if (error) begin
        $display("@%0t Mismatch in DCACHE memory rdata at address %0h, CPU read: %0h, shadow mem read: %0h", $time, dmem_addr, dmem_rdata, d_spec_rdata);
    end
    if (poison_inst) begin
        $display("@%0t Mismatch in ICACHE memory rdata at address %0h, CPU read: %0h, shadow mem read: %0h", $time, imem_addr, imem_rdata, i_spec_rdata);
    end
end : mem_write

endmodule : shadow_memory
