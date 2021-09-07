`timescale 1ns / 1ps

module dual_port_ram
    #(parameter DATA_WIDTH = 8,
      parameter ADDR_WIDTH = 3,
      parameter MEM_SIZE = 2**ADDR_WIDTH
    )
    (input wire clk,
    input wire write,
    input wire read,
    input wire  [ADDR_WIDTH-1:0] raddr,
    input wire  [ADDR_WIDTH-1:0] waddr,
    input wire  [DATA_WIDTH-1:0] wdata,
    output wire [DATA_WIDTH-1:0] rdata
    );

    reg [DATA_WIDTH-1:0] mem [MEM_SIZE-1:0];

    always @(posedge clk) 
    begin
        if (write) 
            mem[waddr] = wdata;
        else 
            mem[waddr] = mem[waddr];
    end

    assign rdata = (read)? mem[raddr] : {(DATA_WIDTH){1'bz}};

endmodule