module Unidade_Controle(
    // Saídas para a interface inicial na placa(opcional)
    output reg LED_vermelho,
    output reg LED_verde,

    // Saidas para o Banco de Registradores (memoria.v)
    output reg reg_write,      // sinal de controle( habilita ou nao a escrita no banco de registradores  )
    output reg [3:0] reg_dest, // ira indicar em que local(indice) eu vou escrever o resultado final da minha operacao no banco de registradores
    output reg [3:0] reg_src1, //(se reg_src1 == 1100(no meu switch) -> eu irei ver o valor que esta armazenado na posicao 12 no meu banco de registradores de 16 bits)
    output reg [3:0] reg_src2, // tambem sera um dos operandos da minha ula 
    output reg signed [15:0] reg_data_in, // dado em 16 bits que sera escrito(especificado pelo registrador de destino) no campo de registradores(o conteudo que sera escrito posicao do red_dest)

    // Saidas para a nossa ULA (ULA.v)
    output reg [2:0] alu_op,
    output reg signed [15:0] alu_op_a,
    output reg signed [15:0] alu_op_b,
    
    // Saidas para o LCD
    output reg [7:0] lcd_data_bus,
    output reg lcd_rs,
    output reg lcd_rw,
    output reg lcd_e,

    // Entradas do meu modulo
    input key_ligar,
    input key_enviar,
    input clk,
    input reset,
    input [17:0] instruction_input,
    input signed [15:0] reg_data_out_a,
    input signed [15:0] reg_data_out_b,
    input signed [15:0] alu_result
);

    // Estados da minha Maquina de Estados Finitos:
    parameter State_off     = 4'b0000;
    parameter Init          = 4'b0001;
    parameter Fetch         = 4'b0010;
    parameter Decode        = 4'b0011;
    parameter Execute       = 4'b0100;
    parameter Writeback     = 4'b0101;
    parameter Special_Op    = 4'b0110;

    reg [3:0] estado_atual;

    // Logica para pressionar e soltar o botao
    reg key_ligar_prev;
    reg key_enviar_prev;
    wire key_ligar_negedge = key_ligar_prev & ~key_ligar;
    wire key_enviar_negedge = key_enviar_prev & ~key_enviar;
    
    // Contador de estados para operações multiciclo (LCD)
    reg [15:0] counter;
    parameter DELAY = 50_000;

    // Registradores para decodificação da instrucao (locais, não são saídas)
    reg [2:0] opcode;
    reg [3:0] reg_dest_inst;
    reg [3:0] reg_src1_inst;
    reg [3:0] reg_src2_inst;
    reg [5:0] immediato;
    reg immediato_sinal;

    // Wires para conectar o LCD_INIT
    wire lcd_done;

    // Parte Sequencial: Lógica de Transição de Estados/mantimento:
    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            estado_atual <= State_off;
            key_ligar_prev <= 1'b1;
            key_enviar_prev <= 1'b1;
            counter <= 16'd0;
        end
        else begin
            key_ligar_prev <= key_ligar;
            key_enviar_prev <= key_enviar;
            
            case (estado_atual)
                State_off: 
                    if (key_ligar_negedge) begin estado_atual <= Init; counter <= 16'd0; end
                    else estado_atual <= State_off; 

                Init: begin
                    // Aguarda a sequência do LCD terminar
                    if (lcd_done) begin estado_atual <= Fetch; counter <= 16'd0; end
                    else begin estado_atual <= Init; counter <= counter + 1; end
                end

                Fetch: begin
                    if (key_ligar_negedge) estado_atual <= State_off;
                    else if (key_enviar_negedge) estado_atual <= Decode;
                    else estado_atual <= Fetch;
                end

                Decode: begin
                    // Decodificacao da instrucao
                    opcode = instruction_input[17:15];

                    // Atribuições de campos da instrucao
                    // ADDI, SUBI, MUL
                    if (opcode == 3'b010 || opcode == 3'b100 || opcode == 3'b101) begin
                        reg_dest_inst = instruction_input[14:11];
                        reg_src1_inst = instruction_input[10:7];
                        immediato_sinal = instruction_input[6];
                        immediato = instruction_input[5:0];
                    // ADD, SUB
                    end else if (opcode == 3'b001 || opcode == 3'b011) begin
                        reg_dest_inst = instruction_input[14:11];
                        reg_src1_inst = instruction_input[10:7];
                        reg_src2_inst = instruction_input[6:3];
                    // LOAD
                    end else if (opcode == 3'b000) begin
                        reg_dest_inst = instruction_input[14:11];
                        immediato_sinal = instruction_input[10];
                        immediato = instruction_input[9:4];
                    // CLEAR, DISPLAY             
                    end else if (opcode == 3'b110 || opcode == 3'b111) begin
                        reg_src1_inst = instruction_input[14:11];
                    end

                    // Lógica de controle principal baseada no estado atual
                    if (opcode == 3'b000) estado_atual <= Writeback;   // LOAD -> pula Execute
                    else if (opcode == 3'b110 || opcode == 3'b111) begin
                        estado_atual <= Special_Op; counter <= 16'd0;  // lcd
                    end else estado_atual <= Execute; // Executa na ula
                end

                Execute: begin
                    reg_src1 = reg_src1_inst;
                    reg_src2 = reg_src2_inst;

                    alu_op = opcode;
                    alu_op_a = reg_data_out_a;
                    if (opcode == 3'b001 || opcode == 3'b011)
                        alu_op_b = reg_data_out_b;
                    else
                        alu_op_b = {10{immediato_sinal}, immediato};  // Extensão de sinal para 16 bits
                        
                    estado_atual <= Writeback; // sempre vai para o prox
                end

                Writeback: begin
                    reg_write = 1'b1;
                    reg_dest = reg_dest_inst;
                    if (opcode == 3'b000)
                        reg_data_in = {10{immediato_sinal}, immediato}; // Extensão de sinal para 16 bits
                    else
                        reg_data_in = alu_result;

                    estado_atual <= Fetch;  // sempre vai para o prox
                end

                Special_Op: begin
                    if (opcode == 3'b111) begin // DISPLAY
                        if (counter >= DELAY) begin
                            lcd_data_bus = reg_data_out_a[7:0]; // Exibe apenas os 8 bits menos significativos
                            lcd_rs = 1'b1;
                            lcd_e = 1'b1; // pulso único
                        end else begin
                            lcd_data_bus = 8'h0C;
                            lcd_e = 1'b1;
                        end
                    end else if (opcode == 3'b110) begin // CLEAR
                        reg_write = 1'b1;
                        reg_data_in = 16'h0000;
                    end

                    if (counter >= DELAY) counter <= 16'd0;
                    else counter <= counter + 1;
                end

                default: estado_atual <= State_off;
            endcase
        end
    end

    // Parte Combinacional: Logica das Saidas 
    always @(*) begin
        // Define um valor padrao (0) para todas as saidas, explicitamente.
        LED_vermelho = 1'b0;
        LED_verde = 1'b0;
        reg_write = 1'b0;
        reg_dest = 4'b0;
        reg_src1 = 4'b0;
        reg_src2 = 4'b0;
        alu_op = 3'b000;
        alu_op_a = 16'h0000;
        alu_op_b = 16'h0000;
        reg_data_in = 16'h0000;
        lcd_data_bus = lcd_data_bus; // agora controlado pelo LCD_INIT
        lcd_rs = lcd_rs;
        lcd_rw = 1'b0; // sempre escrita
        lcd_e = lcd_e;

        // Indicação de LEDs
        if (estado_atual == State_off) LED_vermelho = 1'b1;
        else if (estado_atual == Fetch) LED_verde = 1'b1;
    end
endmodule
