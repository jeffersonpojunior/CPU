module memory (
    input wire          clk,       
    input wire          reset,       
    input wire [3:0]    address,      // Endereço do registrador a ser acessado 
    input wire [15:0]   data_in,      // Dado a ser escrito na memória
    input wire          write_enable, // Sinal que habilita a operação de escrita (Store)

    output wire [15:0]  data_out      // Dado lido da memória (Fetch de Operando)
);

    //================================================================
    // ARRAY DE REGISTRADORES DE 16 BITS
    //================================================================
    reg [15:0] register_bank [0:15];


    //================================================================
    // LÓGICA DE ESCRITA (STORE) E RESET (SÍNCRONA)
    //================================================================
    always @(posedge clk or posedge reset) begin
        // Se o sinal de reset for ativado, zera todos os registradores. 
        if (reset) begin
            integer i; // Variável de laço para o for
            for (i = 0; i < 16; i = i + 1) begin
                register_bank[i] <= 16'b0;
            end
        end 
        // Se o reset não estiver ativo e a escrita estiver habilitada,
        // armazena o data_in no endereço especificado.
        else if (write_enable) begin
            register_bank[address] <= data_in;
        end
    end


    //================================================================
    // LÓGICA DE LEITURA (FETCH DE OPERANDO) (COMBINACIONAL)
    //================================================================
    assign data_out = register_bank[address];

endmodule