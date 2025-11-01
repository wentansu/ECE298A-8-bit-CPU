module mux (
    input  wire [7:0] a,
    input  wire [3:0] b,
    input  wire       select,
    output wire [7:0] out
);

    assign out = select ? {4'b0000, b} : a;

endmodule