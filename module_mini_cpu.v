module module_mini_cpu(
    // Saídas para a interface inicial na placa(opcional)
    output reg LED_vermelho,
    output reg LED_verde,
    
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
    input [17:0] instruction_input,    // Entrada "ao vivo" dos switches
    input signed [15:0] alu_result      // Resultado vindo da ULA
);

    // --- Estados da FSM ---
    parameter State_off     = 4'b0000;
    parameter Init          = 4'b0001;
    parameter Fetch         = 4'b0010;
    parameter Decode        = 4'b0011;
    parameter Execute       = 4'b0100;
    parameter Writeback     = 4'b0101;
    parameter Special_Op    = 4'b0110;

    reg [3:0] estado_atual;

    // --- Lógica de Botão ---
    reg key_ligar_prev;
    reg key_enviar_prev;
    wire key_ligar_negedge = key_ligar_prev & ~key_ligar;
    wire key_enviar_negedge = key_enviar_prev & ~key_enviar;
    
    // --- Contador para Delays ---
    reg [15:0] counter;
    parameter DELAY = 50_000; // Aprox. 1ms com clock de 50MHz

    reg [17:0] current_instruction; // Registrador para a instrução atual

    // --- Decodificação da Instrução ---
    wire [2:0] opcode;
    wire [3:0] reg_dest_inst;
    wire [3:0] reg_src1_inst;
    wire [3:0] reg_src2_inst;
    wire [5:0] immediato;
    wire       immediato_sinal;

    // --- SINAIS INTERNOS DE CONTROLE PARA A MEMÓRIA ---
    reg         reg_write;
    reg [3:0]   reg_dest;
    reg [3:0]   reg_src1;
    reg [3:0]   reg_src2;
    reg signed [15:0] reg_data_in;
    reg         mem_clear; // Sinal para controlar a instrução CLEAR

    // --- FIOS DE LIGAÇÃO (WIRES) PARA A INSTÂNCIA DA MEMÓRIA ---
    wire signed [15:0] reg_data_out_a; // Dado vindo da porta A da memória
    wire signed [15:0] reg_data_out_b; // Dado vindo da porta B da memória

    // =================================================================
    // ===          INSTÂNCIA DO MÓDULO DE MEMÓRIA                 ===
    // =================================================================
    memory a_memoria (
        .clk(clk),
        .reset(reset),
        .clear(mem_clear), // Conectado ao nosso sinal de controle

        .write_enable(reg_write),
        .address_w(reg_dest),
        .data_in_w(reg_data_in),

        .address_a(reg_src1),
        .data_out_a(reg_data_out_a),

        .address_b(reg_src2),
        .data_out_b(reg_data_out_b)
    );
    // =================================================================


    // --- Lógica Sequencial (Transição de Estados) ---
    always @(posedge clk or negedge reset) begin
        if (!reset) begin // Assumindo reset ativo em baixo
            estado_atual <= State_off;
            key_ligar_prev <= 1'b0;
            key_enviar_prev <= 1'b0;
            counter <= 16'd0;
            current_instruction <= 18'b0;
        end
        else begin
            key_ligar_prev <= key_ligar;
            key_enviar_prev <= key_enviar;
            
            case (estado_atual)
                State_off: if (key_ligar_negedge) begin estado_atual <= Init; counter <= 16'd0; end
                           else estado_atual <= State_off; 
                Init: begin
                    if (counter >= DELAY) begin estado_atual <= Fetch; counter <= 16'd0; end
                    else begin estado_atual <= Init; counter <= counter + 1; end
                end
                Fetch: begin
                    if (key_ligar_negedge) estado_atual <= State_off;
                    else if (key_enviar_negedge) begin
                        current_instruction <= instruction_input;
                        estado_atual <= Decode;
                    end
                    else estado_atual <= Fetch;
                end
                Decode: begin
                    if (current_instruction[17:15] == 3'b000) begin estado_atual <= Writeback; end // LOAD
                    else if (current_instruction[17:15] == 3'b110 || current_instruction[17:15] == 3'b111) begin estado_atual <= Special_Op; counter <= 16'd0; end
                    else begin estado_atual <= Execute; end
                end
                Execute:   estado_atual <= Writeback;
                Writeback: estado_atual <= Fetch;
                Special_Op: begin
                    if (counter >= DELAY) begin estado_atual <= Fetch; counter <= 16'd0; end
                    else begin estado_atual <= Special_Op; counter <= counter + 1;  end
                end
                default: estado_atual <= State_off;
            endcase
        end
    end

    // --- Parte Combinacional: Lógica de Decodificação ---
    assign opcode = current_instruction[17:15];
    assign reg_dest_inst = (opcode == 3'b001 || opcode == 3'b011) ? current_instruction[11:8]  : // TIPO 1: ADD, SUB
                           (opcode == 3'b010 || opcode == 3'b100 || opcode == 3'b101) ? current_instruction[14:11] : // TIPO 2: ADDI, SUBI, MUL
                           (opcode == 3'b000)                                      ? current_instruction[10:7]  : // TIPO 3: LOAD
                           4'b0;
    assign reg_src1_inst = (opcode == 3'b001 || opcode == 3'b011) ? current_instruction[7:4]   : // TIPO 1
                           (opcode == 3'b010 || opcode == 3'b100 || opcode == 3'b101) ? current_instruction[10:7]  : // TIPO 2
                           (opcode == 3'b111)                                      ? current_instruction[3:0]   : // TIPO SPECIAL: DISPLAY
                           4'b0;
    assign reg_src2_inst = (opcode == 3'b001 || opcode == 3'b011) ? current_instruction[3:0] : 4'b0;
    assign immediato_sinal = (opcode == 3'b010 || opcode == 3'b100 || opcode == 3'b101) ? current_instruction[6] :
                             (opcode == 3'b000)                                      ? current_instruction[6] :
                             1'b0;
    assign immediato = (opcode == 3'b010 || opcode == 3'b100 || opcode == 3'b101) ? current_instruction[5:0] :
                       (opcode == 3'b000)                                      ? current_instruction[5:0] :
                       6'b0;

    // --- Lógica de Controle Principal (Saídas) ---
    always @(*) begin
        // Valores padrão
        LED_vermelho = 1'b0; LED_verde = 1'b0; reg_write = 1'b0; mem_clear = 1'b0;
        reg_dest = 4'b0; reg_src1 = 4'b0; reg_src2 = 4'b0;
        alu_op = 3'b000; alu_op_a = 16'b0; alu_op_b = 16'b0;
        reg_data_in = 16'b0; lcd_data_bus = 8'b0; lcd_rs = 1'b0;
        lcd_rw = 1'b0; lcd_e = 1'b0;

        case (estado_atual)
            State_off: LED_vermelho = 1'b1;
            Init:      LED_verde = 1'b1;
            Fetch:     LED_verde = 1'b1;
            Decode: begin
                // Comanda a memória para colocar os dados dos regs. de origem nas saídas
                reg_src1 = reg_src1_inst;
                reg_src2 = reg_src2_inst;
            end
            Execute: begin
                // A ULA recebe os dados que a memória forneceu (agora via fios internos)
                alu_op = opcode;
                alu_op_a = reg_data_out_a; // Operando A vem da porta A da memória
                if (opcode == 3'b001 || opcode == 3'b011) // ADD, SUB (Reg-Reg)
                    alu_op_b = reg_data_out_b; // Operando B vem da porta B da memória
                else // ADDI, SUBI, MUL (Reg-Imm)
                    alu_op_b = {{10{immediato_sinal}}, immediato};
            end
            Writeback: begin
                reg_write = 1'b1;
                reg_dest = reg_dest_inst;
                if (opcode == 3'b000) // LOAD
                    reg_data_in = {{10{immediato_sinal}}, immediato};
                else // Para as outras (ADD, SUB, ADDI, etc.)
                    reg_data_in = alu_result;
            end
            Special_Op: begin
                if (opcode == 3'b110) // Se for a instrução CLEAR
                    mem_clear = 1'b1; // Ativa o sinal para zerar a memória
                // A lógica para a instrução DISPLAY no LCD seria implementada aqui
            end
            default: LED_vermelho = 1'b1;
        endcase
    end
endmodule