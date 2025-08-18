module top (
    input  wire clk,
    input  wire reset,
    input  wire key_ligar,
    input  wire key_enviar,
    input  wire [17:0] instruction_input,

    output wire lcd_rs,
    output wire lcd_rw,
    output wire lcd_e,
    output wire [3:0] lcd_data,
    output wire LED_verde,
    output wire LED_vermelho
);

    wire [2:0] alu_op;
    wire signed [15:0] alu_op_a, alu_op_b;
    wire signed [15:0] alu_result;
    wire [7:0] lcd_data_bus;
    wire lcd_rs_wire, lcd_e_wire;

    mini_cpu_final cpu (
        .LED_verde(LED_verde),
        .LED_vermelho(LED_vermelho),
        .alu_op(alu_op),
        .alu_op_a(alu_op_a),
        .alu_op_b(alu_op_b),
        .lcd_data_bus(lcd_data_bus),
        .lcd_rs(lcd_rs_wire),
        .lcd_rw(lcd_rw),
        .lcd_e(lcd_e_wire),
        .key_ligar(key_ligar),
        .key_enviar(key_enviar),
        .clk(clk),
        .reset(reset),
        .instruction_input(instruction_input),
        .alu_result(alu_result)
    );

    alu u_alu (
        .clk(clk),
        .rst(reset),
        .opcode(alu_op),
        .a(alu_op_a),
        .b(alu_op_b),
        .result(alu_result)
    );

    lcd_driver u_lcd (
        .clk(clk),
        .reset(reset),
        .clear(1'b0),
        .data_in(lcd_data_bus),
        .data_valid(1'b1),
        .is_cmd(~lcd_rs_wire),
        .lcd_rs(lcd_rs),
        .lcd_e(lcd_e),
        .lcd_data(lcd_data),
        .ready()
    );

    assign lcd_rw = 1'b0;

endmodule