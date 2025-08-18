module vending_mealy(
    input  wire clk,
    input  wire rst,      // sync active-high
    input  wire [1:0] coin, // 01=5, 10=10, 00=idle
    output reg  dispense, // 1-cycle pulse
    output reg  chg5      // 1-cycle pulse
);

    // State encoding
    parameter idle=2'b00, five=2'b01, ten=2'b10, fifteen=2'b11;

    reg [1:0] state_present, state_next;

    // State register
    always @(posedge clk) begin
        if (rst)
            state_present <= idle;
        else
            state_present <= state_next;

        dispense <= 0; // Reset dispense signal
        chg5 <= 0;     // Reset change signal
        if(state_present==ten && coin==2'b10)begin
            dispense <= 1; // Dispense on 10+10
        end else if(state_present==fifteen && coin==2'b01) begin
            dispense <= 1; // Dispense on 15+5
        end else if(state_present==fifteen && coin==2'b10) begin
            dispense <= 1; // Dispense on 15+10
            chg5 <= 1;     // Change for 5
        end
    end

    // Next-state + Mealy outputs
    always @(*) begin
        // defaults
        state_next = state_present;
     

        case (state_present)
            idle: begin
                if (coin == 2'b01) state_next = five;
                else if (coin == 2'b10) state_next = ten;
            end

            five: begin
                if (coin == 2'b01) state_next = ten;
                else if (coin == 2'b10) state_next = fifteen;
            end

            ten: begin
                if (coin == 2'b01) state_next = fifteen;
                else if (coin == 2'b10) begin
                   
                    state_next = idle;
                end
            end

            fifteen: begin
                if (coin == 2'b01) begin
                    
                    state_next = idle;
                end
                else if (coin == 2'b10) begin
                   
                    state_next = idle;
                end
            end
        endcase
    end
endmodule
