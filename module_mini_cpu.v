module module_mini_cpu (
    output reg LED_vermelho,
    output reg LED_verde,
    output reg [2:0] alu_op,
    output reg signed [15:0] alu_op_a,
    output reg signed [15:0] alu_op_b,
    output reg [7:0] lcd_data_bus,
    output reg lcd_rs,
    output reg lcd_rw,
    output reg lcd_e,
    input key_ligar,
    input key_enviar,
    input clk,
    input reset,
    input [17:0] instruction_input,
    input signed [15:0] alu_result
);

    parameter State_off=4'b0000, Init=4'b0001, Fetch=4'b0010, Decode=4'b0011,
              Execute=4'b0100, Writeback=4'b0101, Special_Op=4'b0110, LCD_Clear=4'b0111;

    reg [3:0] estado_atual;
    reg key_ligar_prev, key_enviar_prev;
    wire key_ligar_negedge = key_ligar_prev & ~key_ligar;
    wire key_enviar_negedge = key_enviar_prev & ~key_enviar;

    reg [15:0] counter;
    parameter DELAY=50000;

    reg [17:0] current_instruction;

    wire [2:0] opcode;
    wire [3:0] reg_dest_inst, reg_src1_inst, reg_src2_inst;
    wire [5:0] immediato;
    wire immediato_sinal;

    reg reg_write;
    reg [3:0] reg_dest, reg_src1, reg_src2;
    reg signed [15:0] reg_data_in;
    reg mem_clear;

    wire signed [15:0] reg_data_out_a, reg_data_out_b;

    memory a_memoria (
        .clk(clk), .reset(reset), .clear(mem_clear),
        .write_enable(reg_write), .address_w(reg_dest),
        .data_in_w(reg_data_in),
        .address_a(reg_src1), .data_out_a(reg_data_out_a),
        .address_b(reg_src2), .data_out_b(reg_data_out_b)
    );

    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            estado_atual<=State_off; key_ligar_prev<=0; key_enviar_prev<=0; counter<=0; current_instruction<=0;
        end else begin
            key_ligar_prev<=key_ligar; key_enviar_prev<=key_enviar;
            case(estado_atual)
                State_off: if(key_ligar_negedge) estado_atual<=Init;
                Init: begin counter<=counter+1; if(counter>=DELAY) begin estado_atual<=LCD_Clear; counter<=0; end end
                LCD_Clear: begin counter<=counter+1; if(counter>=DELAY) begin estado_atual<=Fetch; counter<=0; end end
                Fetch: begin
                    if(key_ligar_negedge) estado_atual<=State_off;
                    else if(key_enviar_negedge) begin current_instruction<=instruction_input; estado_atual<=Decode; end
                end
                Decode: begin
                    if(opcode==3'b000) estado_atual<=Writeback;
                    else if(opcode==3'b110 || opcode==3'b111) estado_atual<=Special_Op;
                    else estado_atual<=Execute;
                end
                Execute: estado_atual<=Writeback;
                Writeback: estado_atual<=Fetch;
                Special_Op: begin counter<=counter+1; if(counter>=DELAY) begin estado_atual<=Fetch; counter<=0; end end
                default: estado_atual<=State_off;
            endcase
        end
    end

    assign opcode = current_instruction[17:15];
    assign reg_dest_inst = (opcode==3'b001 || opcode==3'b011)? current_instruction[11:8]:
                           (opcode==3'b010 || opcode==3'b100 || opcode==3'b101)? current_instruction[14:11]:
                           (opcode==3'b000)? current_instruction[10:7]:4'b0;
    assign reg_src1_inst = (opcode==3'b001 || opcode==3'b011)? current_instruction[7:4]:
                           (opcode==3'b010 || opcode==3'b100 || opcode==3'b101)? current_instruction[10:7]:
                           (opcode==3'b111)? current_instruction[3:0]:4'b0;
    assign reg_src2_inst = (opcode==3'b001 || opcode==3'b011)? current_instruction[3:0]:4'b0;
    assign immediato_sinal = (opcode==3'b010 || opcode==3'b100 || opcode==3'b101 || opcode==3'b000)? current_instruction[6]:0;
    assign immediato = (opcode==3'b010 || opcode==3'b100 || opcode==3'b101 || opcode==3'b000)? current_instruction[5:0]:6'b0;

    always @(*) begin
        case(opcode)
            3'b001: alu_op=3'b001; 3'b011: alu_op=3'b011;
            3'b010: alu_op=3'b010; 3'b100: alu_op=3'b100; 3'b101: alu_op=3'b101;
            default: alu_op=3'b000;
        endcase
    end

    always @(*) begin
        LED_vermelho=0; LED_verde=0;
        reg_write=0; mem_clear=0; reg_dest=0; reg_src1=0; reg_src2=0; reg_data_in=0;
        alu_op_a=0; alu_op_b=0; lcd_data_bus=0; lcd_rs=0; lcd_rw=0; lcd_e=0;
        case(estado_atual)
            State_off: LED_vermelho=1;
            Init: LED_verde=1;
            LCD_Clear: begin lcd_data_bus=8'h01; lcd_rs=0; lcd_rw=0; lcd_e=1; end
            Fetch: LED_verde=1;
            Decode: begin reg_src1=reg_src1_inst; reg_src2=reg_src2_inst; end
            Execute: begin alu_op_a=reg_data_out_a; if(opcode==3'b001||opcode==3'b011) alu_op_b=reg_data_out_b; else if(opcode==3'b010||opcode==3'b100||opcode==3'b101) alu_op_b={{10{immediato_sinal}},immediato}; end
            Writeback: begin reg_write=1; reg_dest=reg_dest_inst; reg_data_in=(opcode==3'b000)?{{10{immediato_sinal}},immediato}:alu_result; lcd_data_bus=alu_result[7:0]; lcd_rs=1; lcd_rw=0; lcd_e=1; end
            Special_Op: begin if(opcode==3'b110) begin mem_clear=1; lcd_data_bus=8'h43; lcd_rs=1; lcd_rw=0; lcd_e=1; end else if(opcode==3'b111) begin reg_src1=reg_src1_inst; lcd_data_bus=reg_data_out_a[7:0]; lcd_rs=1; lcd_rw=0; lcd_e=1; end end
            default: LED_vermelho=1;
        endcase
    end

endmodule