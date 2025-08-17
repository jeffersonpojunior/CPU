module LCD_INIT(
    input clk,           // Clock do sistema
    input rst,           // Reset assíncrono ativo em nível baixo
    input init_start,    // Sinal para iniciar a sequência de inicialização
    output reg [7:0] lcd_data,  // Barramento de dados para o LCD
    output reg lcd_rs,          // Registro/Comando
    output reg lcd_rw,          // Read/Write
    output reg lcd_e,           // Enable
    output reg done             // Indica que a sequência terminou
);

    // Inicialização das saídas do LCD
    initial begin
        lcd_data = 0;
        lcd_e = 0;   // Enable
        lcd_rw = 0;  // Read/Write
        lcd_rs = 0;  // Registro/Comando
        done = 0;    // Sequência ainda não concluída
    end

    // Contador para criar delays entre instruções
    reg [31:0] counter = 0;
    parameter MS = 50_000;         // Delay de exemplo (aprox 1ms com clock 50MHz)
    parameter WRITE = 0, WAIT = 1; // Estados da FSM
    reg [1:0] state = WRITE;

    // Contador de instruções
    reg [7:0] instructions = 0;

    // Sequência de escrita no LCD
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            counter <= 0;
            state <= WRITE;
            instructions <= 0;
            done <= 0;
        end else if (init_start) begin  // Só funciona se init_start estiver ativo
            case (state)
                WRITE: begin
                    if(counter == MS) begin
                        state <= WAIT;
                        counter <= 0;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                WAIT: begin
                    if(counter == MS - 1) begin
                        state <= WRITE;
                        counter <= 0;
                        if(instructions < 37) instructions <= instructions + 1;
                        else done <= 1;  // Sequência concluída
                    end else begin
                        counter <= counter + 1;
                    end
                end
                default: begin end
            endcase
        end else begin
            // Se init_start não estiver ativo, mantém tudo zerado
            lcd_data <= 0;
            lcd_rs <= 0;
            lcd_rw <= 0;
            lcd_e <= 0;
            done <= 0;
            counter <= 0;
            state <= WRITE;
            instructions <= 0;
        end
    end

    // Lógica combinacional para definir dados e sinais do LCD
    always @(*) begin
        // RW sempre em 0 para escrita
        lcd_rw = 0;

        // Pulso de enable: WRITE = 1, WAIT = 0
        case (state)
            WRITE: lcd_e = 1;
            WAIT: lcd_e = 0;
            default: lcd_e = lcd_e;
        endcase

        // Sequência de instruções e dados
        case (instructions)
            0: lcd_data = 8'h38; lcd_rs = 0;  // Habilita o modo de 8 bits, 2 linhas
            1: lcd_data = 8'h0E; lcd_rs = 0;  // Display ON, Cursor ON, Blink OFF
            2: lcd_data = 8'h01; lcd_rs = 0;  // Clear display
            3: lcd_data = 8'h02; lcd_rs = 0;  // Cursor Home
            4: lcd_data = 8'h06; lcd_rs = 0;  // Incrementa cursor

            // Primeira linha: "----    [- - - -]"
            5: lcd_data = 8'h2D; lcd_rs = 1;  // -
            6: lcd_data = 8'h2D; lcd_rs = 1;  // -
            7: lcd_data = 8'h2D; lcd_rs = 1;  // -
            8: lcd_data = 8'h2D; lcd_rs = 1;  // -
            9: lcd_data = 8'h20; lcd_rs = 1;  // Espaço
            10: lcd_data = 8'h20; lcd_rs = 1; // Espaço
            11: lcd_data = 8'h20; lcd_rs = 1; // Espaço
            12: lcd_data = 8'h20; lcd_rs = 1; // Espaço
            13: lcd_data = 8'h5B; lcd_rs = 1; // [
            14: lcd_data = 8'h2D; lcd_rs = 1; // -
            15: lcd_data = 8'h2D; lcd_rs = 1; // -
            16: lcd_data = 8'h2D; lcd_rs = 1; // -
            17: lcd_data = 8'h2D; lcd_rs = 1; // -
            18: lcd_data = 8'h5D; lcd_rs = 1; // ]

            // Segunda linha: move cursor e escreve "+00000"
            19: lcd_data = 8'hC0; lcd_rs = 0;  // Cursor para segunda linha
            20: lcd_data = 8'h2B; lcd_rs = 1; // +
            21: lcd_data = 8'h30; lcd_rs = 1; // 0
            22: lcd_data = 8'h30; lcd_rs = 1; // 0
            23: lcd_data = 8'h30; lcd_rs = 1; // 0
            24: lcd_data = 8'h30; lcd_rs = 1; // 0
            25: lcd_data = 8'h30; lcd_rs = 1; // 0

            default: begin
                lcd_data = 8'h02; lcd_rs = 0; // Default: cursor home
            end
        endcase
    end
endmodule
