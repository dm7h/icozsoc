module testbench;
	reg clkdiv1 = 1, clkdiv2 = 1, clk = 1;
	reg clk_fast = 1;
	reg resetn = 0;
	integer n;

	always #5 clk_fast = ~clk_fast;
	always @(posedge clk_fast) clkdiv1 = ~clkdiv1;
	always @(posedge clkdiv1) clkdiv2 = ~clkdiv2;
	always @(posedge clkdiv2) clk = ~clk;

	initial begin
		$dumpfile("testbench.vcd");
		$dumpvars(0, testbench);
		
			
		for ( n = 0; n < 8; n = n +1) begin
			$dumpvars(1, uut.triggers[n]);
		end
		
		for ( n = 0; n < 8; n = n +1) begin
			$dumpvars(1, uut.events_fifo.memory[n]);
		end
		
		/*	
		for ( n = 0; n < 8; n = n +1) begin
			$dumpvars(1, uut.trig[n]);
		end
		*/

		/*
		for ( n = 0; n <= 1; n = n +1) begin
			$dumpvars(1, uut.io_in_buf[n]);
		end
		*/		
		repeat (25) @(posedge clk);
		resetn <= 1;
	end

	reg         ctrl_wr = 0;
	reg         ctrl_rd = 0;
	reg  [15:0] ctrl_addr;
	reg  [31:0] ctrl_wdat;
	wire [31:0] ctrl_rdat;
	wire        ctrl_done;

	reg [15:0] IO;

	task ctrl_write(input [15:0] addr, input [31:0] data); begin
		ctrl_wr <= 1;
		ctrl_rd <= 0;
		ctrl_addr <= addr;
		ctrl_wdat <= data;
		@(posedge clk);
		while (!ctrl_done) @(posedge clk);
		ctrl_wr <= 0;
	end endtask

	task ctrl_read(input [15:0] addr); begin
		ctrl_wr <= 0;
		ctrl_rd <= 1;
		ctrl_addr <= addr;
		@(posedge clk);
		while (!ctrl_done) @(posedge clk);
		ctrl_rd <= 0;
	end endtask
	
	task read_fifo; begin
		// read fifo out
		ctrl_read('hc);	
		ctrl_read('hc);	
		repeat (10) @(posedge clk);
	end endtask
	

	icosoc_mod_triggerrec uut (
		.clk      (clk      ),
		.clk_fast (clk_fast ),
		.resetn   (resetn   ),
		.ctrl_wr  (ctrl_wr  ),
		.ctrl_rd  (ctrl_rd  ),
		.ctrl_addr(ctrl_addr),
		.ctrl_wdat(ctrl_wdat),
		.ctrl_rdat(ctrl_rdat),
		.ctrl_done(ctrl_done),
		.IO       (IO       )

	);

	initial begin
		
		@(posedge resetn);
		IO <= 0;
		$readmemh("bram_F0s.hex", uut.triggers);
		
		repeat (10) @(posedge clk);
		$display("===\nChecking registers read/write:");


		// test write status 32 bit register (0x1: this will start the couter)
		ctrl_write('h4, 'h01); 
		repeat (2) @(posedge clk);
		
		// get test trigger
		ctrl_read('h4);	
		repeat (10) @(posedge clk);
		
		$display("Status: \t\t%s", (ctrl_rdat == 1)? "OK" : "NOK");	

		// stop counter
		ctrl_write('h4, 'h0); 

		// test write/reset 64 bit timestamp / counter
		ctrl_write('h8, 1); // upper bytes
		repeat (2) @(posedge clk);
		ctrl_write('h8, 2); // lower bytes
		repeat (2) @(posedge clk);
		
		// get counter
		ctrl_read('h8);	
		
		$display("Timestamp: \t%s (upper bytes)", (ctrl_rdat == 1)? "OK" : "NOK");	
		repeat (1) @(posedge clk);
		ctrl_read('h8);	
		
		$display("Timestamp: \t%s (lower bytes)", (ctrl_rdat == 2)? "OK" : "NOK");	
		repeat (10) @(posedge clk);

		// restart counter
		//ctrl_write('h4, 'h01); 
		//repeat (10) @(posedge clk);
	
			
		// check trigger registers
		for (n = 0; n <= 7; n = n+1) begin 
			
			// set test trigger
			ctrl_write('h100 + (n << 2), 'h00010000 + (n << 24)); // upper bytes
			repeat (2) @(posedge clk);
			ctrl_write('h100 + (n << 2), 'hEFFFFFFF); // lower bytes
			repeat (4) @(posedge clk);
		
			// get test trigger
			ctrl_read('h100 + (n << 2));	
			$display("Trigger[%02d]: \t%s : %x (upper bytes)", n, (ctrl_rdat == 'h00010000 + (n << 24))? "OK" : "NOK", ctrl_rdat);	
			repeat (4) @(posedge clk);
			ctrl_read('h100 + (n << 2));	
			$display("Trigger[%02d]: \t%s : %x (lower bytes)", n, (ctrl_rdat == 'hEFFFFFFF)? "OK" : "NOK", ctrl_rdat);	
			repeat (2) @(posedge clk);
		
		end
		

		// event 0
		ctrl_write('h100 + 0, 'h0003fffe); // upper bytes
		repeat (2) @(posedge clk);
		ctrl_write('h100 + 0, 'hfffeffff); // lower bytes
		repeat (4) @(posedge clk);

		// event 1
		ctrl_write('h100 + 1 << 2, 'h0101FFFe); // upper bytes
		repeat (2) @(posedge clk);
		ctrl_write('h100 + 1 << 2, 'hFFFfFFFe); // lower bytes
		repeat (4) @(posedge clk);	

		// event 2
		ctrl_write('h100 + 2 << 2, 'h0200fffc); // upper bytes
		repeat (2) @(posedge clk);
		ctrl_write('h100 + 2 << 2, 'hbfffdffff); // lower bytes
		repeat (4) @(posedge clk);	

		// event 3
		ctrl_write('h100 + 3 << 2, 'h0307fffa); // upper bytes
		repeat (2) @(posedge clk);
		ctrl_write('h100 + 3 << 2, 'hfffbffff); // lower bytes
		repeat (4) @(posedge clk);	

		// event 4
		ctrl_write('h100 + 4 << 2, 'h0401fffa); // upper bytes
		repeat (2) @(posedge clk);
		ctrl_write('h100 + 4 << 2, 'hfffffffb); // lower bytes
		repeat (4) @(posedge clk);	

		// event 5
		ctrl_write('h100 + 5 << 2, 'h0500fff0); // upper bytes
		repeat (2) @(posedge clk);
		ctrl_write('h100 + 5 << 2, 'hfffdfffe); // lower bytes
		repeat (4) @(posedge clk);	



		repeat (10) @(posedge clk);

		// test fifo in
		ctrl_write('hc, 'haaaaaaaa); // upper bytes
		repeat (2) @(posedge clk);
		ctrl_write('hc, 'h55555555); // lower bytes
		repeat (10) @(posedge clk);
	
		// test fifo out
		ctrl_read('hc);	
		repeat (2) @(posedge clk);
		ctrl_read('hc);	
		repeat (10) @(posedge clk);


		// simulate gpio pin change
		// this must work at clk frequency!	
		IO <= 'h7FA4; // x
		@(posedge clk);
		IO <= 'h7F01; // start
		@(posedge clk);		
		IO <= 'h0001; // x 
		repeat(20) @(posedge clk);
		IO <= 'h0003; // clk_up
		@(posedge clk);
		IO <= 'h0001; // clk_down
		repeat(20) @(posedge clk);
		
		IO <= 'hff01; // x
		@(posedge clk);
		IO <= 'h0005; // dump_begin
		@(posedge clk);
		IO <= 'hff05; // *
		@(posedge clk);		
		IO <= 'haa05; // * 
		repeat(20) @(posedge clk);
		IO <= 'h5505; // *
		@(posedge clk);
		IO <= 'h0001; // dump_end 
		repeat(20) @(posedge clk);
			
		IO <= 'hff01; // x
		@(posedge clk);
		IO <= 'h0000; // end
		@(posedge clk);
		IO <= 'hff00; // x
		@(posedge clk);		
		IO <= 0; // x		
		repeat (20) @(posedge clk);
		
		repeat (10) read_fifo();


		$finish;
	end
endmodule
