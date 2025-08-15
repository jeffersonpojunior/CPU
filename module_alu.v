module alu ( // arithmetic logic unit
    input wire clk,
    input wire rst,
    input wire [2:0] opcode,        // código da operação
    input wire signed [15:0] a,     // operando A (registrador)
    input wire signed [15:0] b,     // operando B (registrador)
    input wire signed [15:0] imm,   // immediate
    output reg signed [15:0] result // resultado final
);

    // variável interna para cálculo combinacional
    reg signed [15:0] alu_out;

    // definição dos opcodes relevantes
    parameter ADD  = 3'b001,
              ADDI = 3'b010,
              SUB  = 3'b011,
              SUBI = 3'b100,
              MUL  = 3'b101;

    // parte combinacional: calcula resultado
    always @(*) begin
        case (opcode)
            ADD:     alu_out = a + b;
            ADDI:    alu_out = a + imm;
            SUB:     alu_out = a - b;
            SUBI:    alu_out = a - imm;
            MUL:     alu_out = a * imm;
            default: alu_out = 0; // outros opcodes não usados pela ALU
        endcase
    end

    // parte sequencial: registra resultado no clock
    always @(posedge clk or negedge rst) begin
        if (!rst)
            result <= 0;
        else
            result <= alu_out;
    end

endmodule