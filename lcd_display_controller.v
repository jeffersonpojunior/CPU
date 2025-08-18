module lcd_display_controller (
    input [2:0] last_oppcode_opperation,
    input on_off,
    input enviar,
    input clk,

    input sig,
    input [14:0] number,
    input [3:0] addr,

    output reg [7:0] data,
    output reg RW,
    output reg EN,
    output reg RS
);

// Contador de pulsos
integer count;
parameter ONE_MS = 50_000;
parameter TWO_MS = 100_000;

// Guarda o estado atual da FSM
reg [4:0] state;
parameter ON_OFF = 0, INITIALIZE = 1, WAIT_INFO = 2, STAGE_ONE = 3, STAGE_TWO = 4, WRITE_INFO = 5;

// Define qual caractere será printado no momento, na LCD
integer iteration;

// Checka se o botão foi pressionado
reg check_press_enviar;

// Checka se a inicialização foi concluída
reg init_done; 

// Guarda o atual estágio da sequência de prints de caractere (STAGE ONE or STAGE TWO)
reg[1:0] current_stage;

initial 
begin
    count = 0;
    state = ON_OFF; 
    iteration = 0;

    check_press_enviar = 0;
    init_done = 0; 

    RW = 0;
    EN = 0;
    RS = 0;
    current_stage = 0;
    data = 0;
end

always @(*) 
begin
    case (state)
        // Estado inicial (Tela desligada)
        ON_OFF: 
        begin
            EN = 1;
            RS = 0;
            RW = 0;
            data = 8'h08; // Desligar tela
        end
        // Inicialização (Diplay on + Splash Screen)
        INITIALIZE:
        begin
            EN = 1;
            case (iteration)
                0: begin data = 8'h38; RS = 0; end //Habilita o modo de 8 bits, adiciona a segunda linha
                1: begin data = 8'h0E; RS = 0; end //Display ON, Cursos ON, Blink OFF
                2: begin data = 8'h01; RS = 0; end //Clear
                3: begin data = 8'h02; RS = 0; end //Cursor Home
                4: begin data = 8'h06; RS = 0; end // Pula o cursor quando printa
                5: begin data = 8'h2d; RS = 1; end // -
                6: begin data = 8'h2d; RS = 1; end // -
                7: begin data = 8'h2d; RS = 1; end // -
                8: begin data = 8'h2d; RS = 1; end // -
                9: begin data = 8'h8A; RS = 0; end // Move cursor para posição 11 da linha 1
                10: begin data = 8'h7b; RS = 1; end // {
                11: begin data = 8'h2d; RS = 1; end // -
                12: begin data = 8'h2d; RS = 1; end // -
                13: begin data = 8'h2d; RS = 1; end // - 
                14: begin data = 8'h2d; RS = 1; end // -
                15: begin data = 8'h7d; RS = 1; end // }
                16: begin data = 8'hCA; RS = 0; end  // Move o cursor para a posição 11 da linha 2
                17: begin data = 8'h2b; RS = 1; end // +
                18: begin data = 8'h30; RS = 1; end // 0
                19: begin data = 8'h30; RS = 1; end // 0
                20: begin data = 8'h30; RS = 1; end // 0
                21: begin data = 8'h30; RS = 1; end // 0
                22: begin data = 8'h30; RS = 1; end // 0
            endcase
        
        end

        // Espera o usuário pressionar e soltar o botão de enviar
        WAIT_INFO:
        begin
            EN = 0;
            RS = 0;
            RW = 0;
        end

        // Printar o caractere da função na LCD, de acordo com a iteração
        STAGE_ONE: 
        begin
            EN = 1;
            case (last_oppcode_opperation)
            3'd0:
            begin
                case(iteration)
                0: begin data = 8'h01; RS = 0; end //CLEAR
                1: begin data = 8'h4c; RS = 1; end // L
                2: begin data = 8'h4f; RS = 1; end // O
                3: begin data = 8'h41; RS = 1; end // A
                4: begin data = 8'h44; RS = 1; end // D
                endcase
            end
            3'd1:
            begin
                case(iteration)
                0: begin data = 8'h01; RS = 0; end //CLEAR
                1: begin data = 8'h41; RS = 1; end // A
                2: begin data = 8'h44; RS = 1; end // D
                3: begin data = 8'h44; RS = 1; end // D
                endcase
            end
            3'd2:
            begin
                case(iteration)
                0: begin data = 8'h01; RS = 0; end //CLEAR
                1: begin data = 8'h41; RS = 1; end // A
                2: begin data = 8'h44; RS = 1; end // D
                3: begin data = 8'h44; RS = 1; end // D
                4: begin data = 8'h49; RS = 1; end // I
                endcase
            end
            3'd3:
            begin
                case(iteration)
                0: begin data = 8'h01; RS = 0; end //CLEAR
                1: begin data = 8'h53; RS = 1; end // S
                2: begin data = 8'h55; RS = 1; end // U
                3: begin data = 8'h42; RS = 1; end // B
                endcase
            end
            3'd4:
            begin
                case(iteration)
                0: begin data = 8'h01; RS = 0; end //CLEAR
                1: begin data = 8'h53; RS = 1; end // S
                2: begin data = 8'h55; RS = 1; end // U
                3: begin data = 8'h42; RS = 1; end // B
                4: begin data = 8'h49; RS = 1; end // I
                endcase
            end
            3'd5:
            begin
                case(iteration)
                0: begin data = 8'h01; RS = 0; end //CLEAR
                1: begin data = 8'h4d; RS = 1; end // M
                2: begin data = 8'h55; RS = 1; end // U
                3: begin data = 8'h4c; RS = 1; end // L
                endcase
            end
            3'd6:
            begin
                case(iteration)
                0: begin data = 8'h01; RS = 0; end //CLEAR
                1: begin data = 8'h43; RS = 1; end // C
                2: begin data = 8'h4c; RS = 1; end // L
                3: begin data = 8'h52; RS = 1; end // R
                endcase
            end
            3'd7:
            begin
                case(iteration)
                0: begin data = 8'h01; RS = 0; end //CLEAR
                1: begin data = 8'h44; RS = 1; end // D
                2: begin data = 8'h50; RS = 1; end // P
                3: begin data = 8'h4c; RS = 1; end // L
                endcase
            end
            endcase
        end
        // Printar o caractere do endereço da RAM/conteúdo da RAM na LCD, de acordo com a iteração
        STAGE_TWO:
        begin
            EN = 1;
            case(iteration)
            0: begin data = 8'h8A; RS = 0; end // Move cursor para posição 11 da linha 1
            1: begin data = 8'h7b; RS = 1; end // {
            2: begin data = 8'h30 + addr[3]; RS = 1; end // MSB
            3: begin data = 8'h30 + addr[2]; RS = 1; end
            4: begin data = 8'h30 + addr[1]; RS = 1; end 
            5: begin data = 8'h30 + addr[0]; RS = 1; end // LSB
            6: begin data = 8'h7d; RS = 1; end // }
            7: begin data = 8'hCA; RS = 0; end  // Move o cursor para a posição 11 da linha 2
            8: begin data = 8'h2b + (2 * sig); RS = 1; end // + ou -
            9: begin data = 8'h30 + ((number / 10_000) % 10); RS = 1; end // Quinto dígito
            10: begin data = 8'h30 + ((number / 1_000) % 10); RS = 1; end // Quarto dígito
            11: begin data = 8'h30 + ((number / 100) % 10); RS = 1; end // Terceiro dígito
            12: begin data = 8'h30 + ((number / 10) % 10); RS = 1; end // Segundo dígito
            13: begin data = 8'h30 + (number % 10); RS = 1; end // Primeiro dígito
            endcase
        end
        // Printa o caractere setado a ser printado
        WRITE_INFO:
        begin
            if (count >= ONE_MS)
            begin
                EN = 0;
            end
            else
            begin
                EN = 1;
            end
        end
    endcase
end

always @(posedge clk) 
begin
    case (state)
        // Estado inicial (Tela desligada)
        ON_OFF: 
        begin
            if (on_off == 1)
            begin
                state <= INITIALIZE;
                iteration <= 0; 
                init_done <= 0;
            end
            else if (count < TWO_MS)
            begin
                state <= WRITE_INFO;
            end
        end

        // Inicialização (Diplay on + Splash Screen)
        INITIALIZE: 
        begin
            state <= WRITE_INFO;
        end

        // Espera o usuário pressionar e soltar o botão de enviar
        WAIT_INFO:
        begin
            if (enviar == 0) 
            begin
                check_press_enviar <= 1;
            end
            
            if (check_press_enviar == 1 && enviar == 1) 
            begin
                check_press_enviar <= 0; 
                iteration <= 0;         
                state <= STAGE_ONE;
            end

            if (on_off == 0)
            begin
                count <= 0;
                state <= ON_OFF;
            end
        end

        // Printar o caractere da função na LCD, de acordo com a iteração
        STAGE_ONE: 
        begin
            state <= WRITE_INFO;
            current_stage <= 1;
        end

        // Printar o caractere do endereço da RAM/conteúdo da RAM na LCD, de acordo com a iteração
        STAGE_TWO:
        begin
            state <= WRITE_INFO;
            current_stage <= 2;
        end

        // Printa o caractere setado a ser printado
        WRITE_INFO:
            begin
                count <= count + 1;
                if (on_off == 0)
                begin
                    state <= ON_OFF;
                end
                else if (
                    //Condição para funções devagares (como home e clear)
                    ( 
                    ( (init_done && iteration == 0) || (!init_done && (iteration == 2 || iteration == 3)) ) && 
                    ( count >= TWO_MS ) 
                    ) 
                    ||
                    // Condição para funções rápidas
                    ( 
                    ( !((init_done && iteration == 0) || (!init_done && (iteration == 2 || iteration == 3))) ) &&
                    ( count >= ONE_MS ) 
                    )
                )
                begin
                    count <= 0;
                    iteration <= iteration + 1;

                    if (!init_done) 
                    begin
                        if (iteration >= 22) 
                        begin
                            iteration <= 0;
                            init_done <= 1;
                            state <= WAIT_INFO;
                        end 
                        else 
                        begin
                            state <= INITIALIZE;
                        end
                    end 
                    else if (current_stage == 1) 
                    begin
                        if ((last_oppcode_opperation == 3'd1 || last_oppcode_opperation == 3'd3 || last_oppcode_opperation == 3'd5|| last_oppcode_opperation == 3'd6 || last_oppcode_opperation == 3'd7) && (iteration >= 3)) 
                        begin
                            iteration <= 0;
                            if (last_oppcode_opperation == 3'd6) begin state <= WAIT_INFO; end 
                            else begin state <= STAGE_TWO; end;
                        end
                        else if ((last_oppcode_opperation == 3'd0 || last_oppcode_opperation == 3'd2 || last_oppcode_opperation == 3'd4) && (iteration >= 4)) 
                        begin
                            iteration <= 0;
                            state <= STAGE_TWO;
                        end
                        else 
                        begin
                            state <= STAGE_ONE;
                        end
                    end
                    else if (current_stage == 2)
                    begin
                        if (iteration >= 13)
                        begin
                            iteration <= 0;
                            state <= WAIT_INFO;
                        end
                        else
                        begin
                            state <= STAGE_TWO;
                        end
                    end
                end
            end
    endcase
end
 
endmodule