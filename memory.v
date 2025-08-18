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
		
	// Inicializando o banco de registradores:
	initial begin
		register_bank[0] <= 16'b0;
		register_bank[1] <= 16'b0;
		register_bank[2] <= 16'b0;
		register_bank[3] <= 16'b0;
		register_bank[4] <= 16'b0;
		register_bank[5] <= 16'b0;
		register_bank[6] <= 16'b0;
		register_bank[7] <= 16'b0;
		register_bank[8] <= 16'b0;
		register_bank[9] <= 16'b0;
		register_bank[10] <= 16'b0;
		register_bank[11] <= 16'b0;
		register_bank[12] <= 16'b0;
		register_bank[13] <= 16'b0;
		register_bank[14] <= 16'b0;
		register_bank[15] <= 16'b0;
	 end
	
    // Lógica Síncrona para Escrita e reset
    always @(posedge clk) begin
        if (reset || clear) begin
            register_bank[0] <= 16'b0;
            register_bank[1] <= 16'b0;
            register_bank[2] <= 16'b0;
            register_bank[3] <= 16'b0;
            register_bank[4] <= 16'b0;
            register_bank[5] <= 16'b0;
            register_bank[6] <= 16'b0;
            register_bank[7] <= 16'b0;
            register_bank[8] <= 16'b0;
            register_bank[9] <= 16'b0;
            register_bank[10] <= 16'b0;
            register_bank[11] <= 16'b0;
            register_bank[12] <= 16'b0;
            register_bank[13] <= 16'b0;
            register_bank[14] <= 16'b0;
            register_bank[15] <= 16'b0;
        end
        else if (write_enable) begin
            register_bank[address_w] <= data_in_w;
        end
    end

    // Lógica Combinacional para as duas portas de leitura
    assign data_out_a = register_bank[address_a];
    assign data_out_b = register_bank[address_b];

endmodule