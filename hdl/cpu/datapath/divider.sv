
module divider(
	input clk,
	input [31:0] a,b,
	output logic [31:0] quo, rem,
	//signals
	input start,
	output logic done
);

logic [31:0] quotient = '0;
logic [63:0] remainder = '0;
logic [63:0] divisor = '0;
logic [63:0] temp = '0;
logic [7:0] counter = '0;
logic [7:0] next_count;
enum int unsigned {standby, execute}state,next_state;

//division combo logic
always_comb begin
	temp = remainder - divisor;
	quo = quotient;
	rem = remainder[31:0];
end

//per clk reg updates
always_ff @(posedge clk) begin
	if(state == standby)begin
		remainder <= {32'd0,a};
		divisor <= {b,32'd0};
		quotient <= 32'd0;
	end
	else if(b == 32'd0)begin
		remainder <= remainder;
		divisor <= 64'd0;
		quotient <= 32'hFFFFFFFF;
	end
	else if( $signed(temp) >= $signed(64'd0) )begin
		remainder <= temp;
		divisor <= {1'b0, divisor[63:1]};
		quotient <= {quotient[30:0], 1'b1};
	end	else begin
		remainder <= remainder;
		divisor <= {1'b0, divisor[63:1]};
		quotient <= {quotient[30:0], 1'b0};
	end
end

//state signals 
always_comb begin
	done = 1'b0;
	case(state)
		standby: done = 1'b1;
		execute: done = 1'b0;
	endcase
end
//next state logic
always_comb begin
	next_state = state;	
	next_count = 8'd0;
	case (state)
		standby: begin
			next_state = (start)? execute : standby;
			next_count = 8'd0;
		end
		execute: begin
			if($signed({1'b0,divisor}) <= $signed({temp[63], temp}) || counter == 8'd32) next_state = standby;
			next_count = counter + 1;
		end
	endcase
end
//state and counter register
always_ff @(posedge clk) begin
	state <= next_state;	
	counter <= next_count;
end



endmodule : divider
