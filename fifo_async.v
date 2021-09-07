`include "dual_port_ram.v"
`timescale 1ns / 1ps

module fifo_async
    #(parameter DATA_WIDTH = 8,
      parameter ADDR_WIDTH = 4,
      parameter MEM_SIZE = 2**ADDR_WIDTH
    )
     (input wire clka,
      input wire clkb,
      input wire reset,
      input wire rd_en,
      input wire wr_en,
      input wire [DATA_WIDTH-1:0] wrdata,
      output wire [DATA_WIDTH-1:0] rdata,
      output reg empty,
      output reg full
    );

    // ram inputs //
    reg write;
    reg read;
    reg rd;
    reg [ADDR_WIDTH-1:0] waddr;
    reg [ADDR_WIDTH-1:0] raddr;
    reg [DATA_WIDTH-1:0] wdata;

    // top pointer in clock domain A and B //
    reg [ADDR_WIDTH-1:0] top_ptrA;
    wire [ADDR_WIDTH-1:0] top_grayA;
    reg [ADDR_WIDTH-1:0] top_grayA_tmp;
    reg [ADDR_WIDTH-1:0] top_grayB;

    // bottom pointer in clock domain B and A //
    reg [ADDR_WIDTH-1:0] bot_ptrB;
    wire [ADDR_WIDTH-1:0] bot_grayB;
    reg [ADDR_WIDTH-1:0] bot_grayB_tmp;
    reg [ADDR_WIDTH-1:0] bot_grayA;

    // used for full flag logic 
    reg [ADDR_WIDTH-1:0] top_ptr_minus_one;
    wire [ADDR_WIDTH-1:0] top_ptr_minus_one_grayA ;

    // dual port ram //
    dual_port_ram #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) 
    uut_ram (.clk(clka),.write, .read(rd), .raddr, .waddr, .wdata,.rdata);

    // converts binary to gray code //
    function automatic [ADDR_WIDTH-1:0] gray (input [ADDR_WIDTH-1:0] ptr);
        gray = (ptr >> 1) ^ ptr;
    endfunction


    // CLOCK A DOMAIN (WRITE) //

    reg [1:0] RESETA = 2'b00;
    reg [1:0] IDLEA = 2'b01;
    reg [1:0] WRITEA = 2'b11;
    reg [1:0] FULL = 2'b10;

    reg [1:0] state_a; 
    reg [1:0] next_a;

    // Current State Logic -- sequential logic //
    always @(posedge clka) 
    begin
        if (reset)
            state_a <= RESETA;
        else
            state_a <= next_a;
    end

    // next state logic //
    always@(*) 
    begin
        case(state_a)
            RESETA:
                next_a = IDLEA;
            IDLEA:
            begin
                if (wr_en) next_a = WRITEA;
                else next_a = IDLEA;
            end
            WRITEA:
            begin
                if (top_grayA == bot_grayA) 
                    next_a = FULL;
                else if (!write) 
                    next_a = IDLEA;
                else 
                    next_a = WRITEA;
            end
            FULL:
            begin
                if (top_ptr_minus_one_grayA != bot_grayA) 
                    next_a = IDLEA;  
                else 
                    next_a = FULL;  
            end
        endcase
    end

     // moore outputs logic //
    always@(*) 
    begin
        case(state_a)
            RESETA:
            begin
                write = 0;
                full = 0;
                wdata = 0;
            end
            IDLEA:
            begin
                write = 0;
                full  = 0;
            end
            WRITEA:
            begin
                write = wr_en;
                wdata = wrdata;
            end
            FULL:
            begin
                write = 0;   
                full  = 1;
            end
        endcase
    end

    // datapath //
    always @(*) 
    begin
        if (reset) 
        begin
            top_ptr_minus_one = 0;
            top_ptrA = 0;
            waddr = 0;
        end
        else if (write && !full) 
        begin
            top_ptr_minus_one = top_ptrA;
            top_ptrA = top_ptrA + 1;
            waddr = top_ptrA;
        end      
    end

    // convert top_ptrA to graycode //
    assign top_grayA = gray(top_ptrA);
    assign top_ptr_minus_one_grayA = gray(top_ptr_minus_one);

    // Double flop top_grayA to clock domain B //
    always @(posedge clkb) 
    begin
        top_grayA_tmp <= top_grayA;
        top_grayB <= top_grayA_tmp;
    end


    // CLOCK B DOMAIN (READ) //
    reg [1:0] RESETB = 2'b00;
    reg [1:0] IDLEB = 2'b01;
    reg [1:0] READB = 2'b11;
    reg [1:0] EMPTY = 2'b10;

    reg [1:0] state_b;
    reg [1:0] next_b;

    // current state logic //
    always@(posedge clkb) begin
        if (reset)
            state_b <= RESETB;
        else
            state_b <= next_b;
    end

    // next state logic //
    always@(*) begin
        case(state_b)
            RESETB:
                next_b = EMPTY;
            EMPTY:
            begin
                if (top_grayB != bot_grayB) 
                    next_b = IDLEB;
            end
            READB:
            begin
                if (top_grayB == bot_grayB) next_b = EMPTY;
                else next_b = IDLEB;
            end
            IDLEB:
            begin
                if (rd_en) next_b = READB;
            end
        endcase;   
    end

    // moore outpur logic //
    always@(*) begin
        case(state_b)
        RESETB:
        begin
            read  = 0;
            empty = 0;
        end
        EMPTY:
        begin
            read  = 0;
            empty = 1;
        end
        READB:
        begin
            read  = 1;
            empty = 0;
        end
        IDLEB:
        begin
            read  = 0;
            empty = 0;
        end
        endcase    
    end

    // Datapath //
    always@(*) 
    begin
        if (reset) 
        begin
            bot_ptrB = 0;
            raddr = 0;
        end
        else if (read && !empty) 
        begin
            bot_ptrB = bot_ptrB + 1;
            raddr = bot_ptrB;
        end
    end

    // convert bot_ptrB to gray code //
    assign bot_grayB = gray(bot_ptrB);

    // double flop to cross bot_grayB to clock domain A
    always @(posedge clka) 
    begin
        bot_grayB_tmp <= bot_grayB;
        bot_grayA <= bot_grayB_tmp;
        rd <= read;
    end    

endmodule