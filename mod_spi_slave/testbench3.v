module testbench;
	reg clk = 1;
	reg resetn = 0;

	always #5 clk = ~clk;
	initial begin
		$dumpfile("testbench_fifo.vcd");
		$dumpvars(0, testbench);
		repeat (100) @(posedge clk);
		resetn <= 1;
	end

	// registers for the event fifo
	reg [3:0] data_in;
	wire [3:0] data_out;
	reg shift_in;
	reg pop_out;
	wire nempty_in; 
	wire nempty_out;
	reg full_in; 
	wire full_out;

	icosoc_crossclkfifo #(
		.WIDTH(4),
		.DEPTH(128)
	) uut (
		.in_clk(clk),
		.in_shift(shift_in),
		.in_data(data_in),
		.in_nempty(nempty_in),

		.out_clk(clk),
		.out_pop(pop_out),
		.out_data(data_out),
		.out_nempty(nempty_out)
	);

	initial begin
		@(posedge resetn);
		shift_in <= 0;
		pop_out <= 0;
		repeat (10) @(posedge clk);
		
		data_in <= 4'b1111;
		shift_in <= 1;
		@(posedge clk);
		shift_in <= 0;
		@(posedge clk);

	
		data_in <= 4'b1100;
		shift_in <= 1;
		@(posedge clk);
		shift_in <= 0;
		@(posedge clk);

	
		data_in <= 4'b0011;
		shift_in <= 1;
		@(posedge clk);
		shift_in <= 0;
		@(posedge clk);

		repeat (10) @(posedge clk);
		
		pop_out <= 1;
		@(posedge clk);
		pop_out <= 0;
		@(posedge clk);

	
		data_in <= 4'b0100;
		shift_in <= 1;
		@(posedge clk);
		shift_in <= 0;
		@(posedge clk);
	
		pop_out <= 1;
		@(posedge clk);
		pop_out <= 0;
		@(posedge clk);

	
		pop_out <= 1;
		@(posedge clk);
		pop_out <= 0;
		@(posedge clk);
	
		pop_out <= 1;
		@(posedge clk);
		pop_out <= 0;
		@(posedge clk);
		
		repeat (10) @(posedge clk);

	
		pop_out <= 1;
		@(posedge clk);
		pop_out <= 0;
		@(posedge clk);

			
		repeat (100) @(posedge clk);

		$finish;
	end
endmodule
