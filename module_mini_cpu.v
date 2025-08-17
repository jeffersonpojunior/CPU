module control_unit(); // IMPLEMENTAÇÃO DO FETCH

// Estados da FSM do FETCH:
reg [1:0] state, next_state;
parameter S_IDLE    = 2'b00; // Estado inicial, esperando instrução
parameter S_FETCH   = 2'b01; // Estado para buscar operandos
parameter S_EXECUTE = 2'b10; // Estado para executar na ULA
parameter S_STORE   = 2'b11; // Estado para salvar o resultado

// Registrador para a instrução atual
// Latch da instrução dos switches
reg [17:0] current_instruction;

// --- Sinais para a Memória ---
wire [3:0] mem_address_a;
wire [3:0] mem_address_b;
wire [15:0] mem_data_out_a; // Fio vindo da memória
wire [15:0] mem_data_out_b; // Fio vindo da memória

// --- Sinais para a ULA ---
// Estes fios guardarão os operandos finais para a ULA
reg [15:0] alu_operand_a;
reg [15:0] alu_operand_b;


// Extrai os campos da instrução latched em 'current_instruction'
wire [2:0] opcode = current_instruction[14:12]; // Exemplo para Tipo 1

// Decodificação dos endereços dos registradores para instruções TIPO 1 (Reg-Reg)
wire [3:0] dest_addr_t1 = current_instruction[11:8];
wire [3:0] src1_addr_t1 = current_instruction[7:4];
wire [3:0] src2_addr_t1 = current_instruction[3:0];

// Decodificação para instruções TIPO 2 (Reg-Imm)
wire [3:0] dest_addr_t2 = current_instruction[14:11];
wire [3:0] src1_addr_t2 = current_instruction[10:7];
wire [15:0] imm_val_t2  = { {9{current_instruction[6]}}, current_instruction[6], current_instruction[5:0] }; // Extensão de sinal


//================================================================
// LÓGICA DE FETCH (Parte da Máquina de Estados)
//================================================================

assign mem_address_a = (opcode == 3'b001 || opcode == 3'b011) ? src1_addr_t1 : // Se for ADD/SUB, usa src1_t1
                       (opcode == 3'b010 || opcode == 3'b100 || opcode == 3'b101) ? src1_addr_t2 : // Se for ADDI/SUBI/MUL, usa src1_t2
                       4'b0; // Valor padrão

assign mem_address_b = (opcode == 3'b001 || opcode == 3'b011) ? src2_addr_t1 : // Se for ADD/SUB, usa src2_t1
                       4'b0;

// Preparação dos operandos para a ULA
always @(*) begin
    // Por padrão, o primeiro operando vem da memória
    alu_operand_a = mem_data_out_a; 

    // O segundo operando depende da instrução
    case (opcode)
        // Instruções Reg-Reg (ADD, SUB) usam a segunda saída da memória
        3'b001, 3'b011: begin
            alu_operand_b = mem_data_out_b;
        end
        // Instruções Reg-Imm (ADDI, SUBI, MUL) usam o valor imediato
        3'b010, 3'b100, 3'b101: begin
            alu_operand_b = imm_val_t2;
        end
        // Casos padrão
        default: begin
            alu_operand_b = 16'b0;
        end
    endcase
end

// Bloco sequencial para transição de estados
always @(posedge clk or posedge reset) begin
    if (reset)
        state <= S_IDLE;
    else
        state <= next_state;
end

// Bloco combinacional para lógica de próximo estado
always @(*) begin
    next_state = state;
    case (state)
        S_IDLE: begin
            if (send_button_pulse) begin
                current_instruction <= instruction_from_switches; // Latch da entrada
                next_state = S_FETCH;
            end
        end
        
        S_FETCH: begin
            next_state = S_EXECUTE;
        end

        S_EXECUTE: begin
            // ... lógica de execução ...
            next_state = S_STORE;
        end

        S_STORE: begin
            // ... lógica de armazenamento ...
            next_state = S_IDLE;
        end
    endcase
end