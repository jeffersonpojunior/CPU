module module_alu (
    input wire clk, input wire rst,
    input wire [2:0] opcode,
    input wire signed [15:0] a, input wire signed [15:0] b,
    output reg signed [15:0] result
);
    reg signed [15:0] alu_out;
    parameter ADD=3'b001, ADDI=3'b010, SUB=3'b011, SUBI=3'b100, MUL=3'b101;

    always @(*) begin
        case(opcode)
            ADD,ADDI: alu_out=a+b;
            SUB,SUBI: alu_out=a-b;
            MUL: alu_out=a*b;
            default: alu_out=0;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if(!rst) result<=0;
        else result<=alu_out;
    end
endmodule