module memory (
    input wire clk, input wire reset, input wire clear,
    input wire write_enable, input wire [3:0] address_w, input wire [15:0] data_in_w,
    input wire [3:0] address_a, output wire [15:0] data_out_a,
    input wire [3:0] address_b, output wire [15:0] data_out_b
);
    reg [15:0] register_bank[0:15];
    integer i;
    always @(posedge clk) begin
        if(reset || clear) for(i=0;i<16;i=i+1) register_bank[i]<=0;
        else if(write_enable) register_bank[address_w]<=data_in_w;
    end
    assign data_out_a=register_bank[address_a];
    assign data_out_b=register_bank[address_b];
endmodule