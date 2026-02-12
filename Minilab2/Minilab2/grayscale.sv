module grayscale(
    r,
    g,
    b,
    gray
);

input wire [11:0] r;
input wire [11:0] g;
input wire [11:0] b;
output wire [11:0] gray;    //width may have to be changed

reg [11:0]add_gb;
reg [11:0]add_rgb;

// assign output
assign gray = r[11:2] + b[11:2] + g[11:1];

endmodule