module lcd_driver (
    input wire clk, input wire reset, input wire clear,
    input wire [7:0] data_in, input wire data_valid, input wire is_cmd,
    output reg lcd_rs, output reg lcd_e, output reg [3:0] lcd_data, output reg ready
);
    parameter IDLE=3'b000,SEND_HIGH=3'b001,PULSE_HIGH=3'b010,SEND_LOW=3'b011,PULSE_LOW=3'b100,WAIT=3'b101;
    reg [2:0] state,next_state;
    reg [7:0] data_reg;
    reg [15:0] counter; parameter DELAY=50000;
    always @(posedge clk or posedge reset) begin
        if(reset) begin state<=IDLE; counter<=0; lcd_e<=0; lcd_rs<=0; lcd_data<=0; ready<=1; end
        else begin state<=next_state;
            case(state)
                IDLE: begin lcd_e<=0; if(clear) begin data_reg<=8'h01; ready<=0; end else if(data_valid) begin data_reg<=data_in; ready<=0; end end
                SEND_HIGH: lcd_data<=data_reg[7:4];
                PULSE_HIGH: begin lcd_e<=1; lcd_rs<=~is_cmd; end
                SEND_LOW: lcd_data<=data_reg[3:0];
                PULSE_LOW: begin lcd_e<=1; lcd_rs<=~is_cmd; end
                WAIT: begin lcd_e<=0; counter<=counter+1; if(counter>=DELAY) begin counter<=0; ready<=1; end end
            endcase
        end
    end
    always @(*) begin
        next_state=state;
        case(state)
            IDLE: if(data_valid||clear) next_state=SEND_HIGH;
            SEND_HIGH: next_state=PULSE_HIGH;
            PULSE_HIGH: next_state=SEND_LOW;
            SEND_LOW: next_state=PULSE_LOW;
            PULSE_LOW: next_state=WAIT;
            WAIT: if(counter>=DELAY) next_state=IDLE;
            default: next_state=IDLE;
        endcase
    end
endmodule