module slave_fsm(
  input  wire clk,
  input  wire rst,
  input  wire req,
  input  wire [7:0] data_in,
  output reg  ack,
  output reg [7:0] last_byte
);

  reg prev_req;
  reg [1:0] ack_cnt;

  always @(posedge clk) begin
    if (rst) begin
      prev_req  <= 0;
      ack       <= 0;
      ack_cnt   <= 0;
      last_byte <= 0;
    end else begin
      prev_req <= req;

      // detect rising edge of req
      if (req && !prev_req) begin
        last_byte <= data_in;
        ack       <= 1;
        ack_cnt   <= 1;
      end
      else if (ack) begin
        if (ack_cnt < 2) ack_cnt <= ack_cnt + 1;
        if ((ack_cnt >= 2) && !req) begin
          ack     <= 0;
          ack_cnt <= 0;
        end
      end
    end
  end

endmodule
