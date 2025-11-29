module mux (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [7:0] c,
    input  wire [7:0] d,
    input  wire [1:0] select, // 00 - a, 01 - b, 10 - c, 11 - d
    output wire [7:0] out
);

    assign out = (select == 2'b00) ? a :
                 (select == 2'b01) ? b :
                 (select == 2'b10) ? c :
                                     d;

endmodule