`include "fifo_async.v"
`timescale 1ns / 1ps

module fifo_async_tb;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 8;   
    localparam Ta = 10;
    localparam Tb = 20;

    reg clka = 0;
    reg clkb = 0;
    reg reset;
    reg rd_en;
    reg wr_en;
    reg [DATA_WIDTH-1:0] wrdata;
    wire [DATA_WIDTH-1:0] rdata;
    wire empty;
    wire full;

    fifo_async uut_fifo(.*);

    initial
    begin
        $dumpfile("waveform.vcd");
        $dumpvars();
    end

    always #(Ta/2) 
        clka = ~clka;
    always #(Tb/2) 
        clkb = ~clkb;

    initial 
    begin
        rd_en = 0;
        wr_en = 0;
        wrdata = 0;
        reset = 1;
        #40;
        reset = 0;
        #15;
        #10;
        rd_en = 1;
        #50;   
        rd_en = 0;
        
        repeat(18) 
        begin
            wr_en = 1;
            wrdata = wrdata + 1;
            #(Ta/2);
            wr_en = 0;
            #(Ta/2);
        end 

        $stop;
    end

endmodule