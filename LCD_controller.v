module LCD_INIT(
 output reg[7:0] data,
 output reg EN, RW, RS,
 
 input clk
);

initial begin
 data = 0;
 EN = 0; //Enable
 RW = 0; //Read/Write
 RS = 0;//
end

reg [31:0] counter = 0;
parameter MS = 50_000;
parameter WRITE = 0, WAIT = 1; // estados da fsm
reg [3:0] state = WRITE;

reg [7:0] instructions = 0;

always @(posedge clk, negedge rst) begin
 case (state)
  WRITE: begin
   if(counter == MS) begin
    state = WAIT;
    counter = 0;
   end else begin
    counter = counter + 1;
   end
  end
  WAIT: begin
   if(counter == MS - 1) begin
    state = WRITE;
    counter = 0;
    if(instructions < 38) instructions = instructions + 1;
   end else begin
    counter = counter + 1;
   end
 
  end
  default : begin end
 endcase
end



always @(*) begin
 case (state)
  WRITE: EN <= 1;
  WAIT: EN <= 0;
  default: EN <= EN;
 endcase
 
 case (instructions)
  0: begin data <= 8'h38; RS <= 0; end //Habilita o modo de 8 bits, adiciona a segunda linha
  1: begin data <= 8'h0E; RS <= 0; end //Display ON, Cursos ON, Blink OFF
  2: begin data <= 8'h01; RS <= 0; end //Clear
  3: begin data <= 8'h02; RS <= 0; end //Cursor Home // POSSO MUDAR A ODEM DO 06 E 02
  4: begin data <= 8'h06; RS <= 0; end // Pula o cursor quando printa
 
  5: begin data <= 8'h2D; RS <= 1; end //-
  6: begin data <= 8'h2D; RS <= 1; end //-
  7: begin data <= 8'h2D; RS <= 1; end //-
  8: begin data <= 8'h2D; RS <= 1; end //-



  9: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  10:begin data <= 8'h20; RS <= 1; end //ESPAÇO
  11: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  12: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  13: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  14: begin data <= 8'h20; RS <= 1; end //ESPAÇO

  15: begin data <= 8'h5B; RS <= 1; end // [
  16: begin data <= 8'h2D; RS <= 1; end //-
  17: begin data <= 8'h2D; RS <= 1; end //-
  18: begin data <= 8'h2D; RS <= 1; end //-
  19: begin data <= 8'h2D; RS <= 1; end //-
  20 : begin data <= 8'h5D; RS <= 1; end //]

  21: begin data <= 8'hC0; RS <= 0; end // PASSA O CURSOR PARA SEGUNDA LINHA
  22: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  23: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  24: begin data <= 8'h20; RS <= 1; end //ESPAÇO 
  25: begin data <= 8'h20; RS <= 1; end //ESPAÇO 
  26: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  27: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  28: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  29: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  30: begin data <= 8'h20; RS <= 1; end //ESPAÇO 
  31: begin data <= 8'h20; RS <= 1; end //ESPAÇO
  
  32: begin data <= 8'h2B; RS <= 1; end //+
  33 : begin data <= 8'h30; RS <= 1; end //0
  34: begin data <= 8'h30; RS <= 1; end //0
  35: begin data <= 8'h30; RS <= 1; end //0
  36: begin data <= 8'h30; RS <= 1; end //0
  37: begin data <= 8'h30; RS <= 1; end //0
  
   
   


 
  default: begin data <= 8'h02; RS <= 0; end
 endcase
end
 
endmodule