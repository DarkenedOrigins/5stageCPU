package dcache_types;

typedef struct packed{
    logic read;
    logic write;
    logic [3:0] write_en;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic dirty;
    logic lru_in;
    logic hit;
    logic tagArray2hit;
} dcache_block;

endpackage : dcache_types
