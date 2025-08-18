module master_fsm(
  input  wire clk,
  input  wire rst,
  input  wire ack,
  output reg  req,
  output reg [7:0] data,
  output reg  done
);

  parameter NUM_BYTES = 4;

  // Memory with 4 data bytes
  reg [7:0] mem [0:NUM_BYTES-1];
  initial begin
    mem[0] = 8'hA0;
    mem[1] = 8'hA1;
    mem[2] = 8'hA2;
    mem[3] = 8'hA3;
  end

  // State encoding (no typedef, only localparam)
  localparam IDLE        = 2'b00,
             WAIT_ACK    = 2'b01,
             WAIT_ACK_LOW= 2'b10,
             DONE_STATE  = 2'b11;

  reg [1:0] state_present, state_next;
  reg [1:0] idx_present, idx_next;

  // Sequential state update
  always @(posedge clk) begin
    if (rst) begin
      state_present <= IDLE;
      idx_present   <= 0;
      req     <= 0;
      data    <= 0;
      done    <= 0;
    end else begin
      state_present <= state_next;
      idx_present   <= idx_next;
    end
  end

  // Combinational next state logic
  always @(*) begin
    // defaults
    state_next = state_present;
    idx_next   = idx_present;
    req     = req;
    data    = data;
    done    = 0;

    case (state_present)

      IDLE: begin
        data    = mem[idx_present];
        req     = 1;
        state_next = WAIT_ACK;
      end

      WAIT_ACK: begin
        if (ack) begin
          req     = 0;
          state_next = WAIT_ACK_LOW;
        end
      end

      WAIT_ACK_LOW: begin
        if (!ack) begin
          if (idx_present == NUM_BYTES-1) begin
            done    = 1;
            state_next = DONE_STATE;
          end else begin
            idx_next   = idx_present + 1;
            data    = mem[idx_present+1];
            req     = 1;
            state_next = WAIT_ACK;
          end
        end
      end

      DONE_STATE: begin
        state_next = IDLE;
      end

    endcase
  end

endmodule
