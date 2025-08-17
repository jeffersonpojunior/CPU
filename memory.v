module memory (
    input wire clk,
    input wire reset,
    input wire clear,

    // Porta de escrita W
    input wire          write_enable,  
    input wire [3:0]    address_w,      
    input wire [15:0]   data_in_w,      

    // --- Porta de Leitura A ---
    input wire [3:0]    address_a,      
    output wire [15:0]  data_out_a,   

    // --- Porta de Leitura B ---
    input wire [3:0]    address_b,   
    output wire [15:0]  data_out_b    
);

    // Banco de registradores 16x16 bits
    reg [15:0] register_bank [0:15];
    integer i;

    // Lógica Síncrona para Escrita e reset
    always @(posedge clk) begin
        if (reset || clear) begin 
            for (i = 0; i < 16; i = i + 1) begin
                register_bank[i] <= 16'b0;
            end
        end 
        else if (write_enable) begin
            register_bank[address_w] <= data_in_w;
        end
    end

    // Lógica Combinacional para as duas portas de leitura
    assign data_out_a = register_bank[address_a];
    assign data_out_b = register_bank[address_b];

endmodule