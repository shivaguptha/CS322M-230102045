module seq_detect_mealy(
    input wire clk,
    input wire rst,        // sync active-high
    input wire din,        // serial input bit per clock
    output reg y           // 1-cycle pulse when pattern ...1101 seen
);

    // Abstract state encoding
    
        parameter init   = 2'b00, // No match
         one   = 2'b01, // Seen '1'
         two  = 2'b10, // Seen '11'
         three = 2'b11;  // Seen '110'
    

    reg [1:0] state_present, state_next;

    // State register
    always @(posedge clk) begin
        if (rst)
            state_present <= init;
        else
            state_present <= state_next;
        
        y<=0;
        if(state_present==three && din==1)begin
            y<=1;
        end
    end

    // Next state & output logic
    always @(*) begin
        state_next = state_present; // default stay

        case (state_present)
            init: begin
                if (din)
                    state_next = one;
                else
                    state_next = init;
            end

            one: begin
                if (din)
                    state_next = two;
                else
                    state_next = init;
            end

            two: begin
                if (din)
                    state_next = two;
                else
                    state_next = three;
            end

            three: begin
                if (din) begin
                   
                    state_next = one; // Overlap handling
                end else
                    state_next = init;
            end

            default: state_next = init;
        endcase
    end

endmodule
