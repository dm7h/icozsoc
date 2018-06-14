module testbench;
	reg clk = 1;
	reg resetn = 0;

	always #5 clk = ~clk;
	initial begin
		$dumpfile("testbench.vcd");
		$dumpvars(0, testbench);
		repeat (25) @(posedge clk);
		resetn <= 1;
	end

	reg         ctrl_wr = 0;
	reg         ctrl_rd = 0;
	reg  [ 7:0] ctrl_addr;
	reg  [31:0] ctrl_wdat;
	wire [31:0] ctrl_rdat;
	wire        ctrl_done;

	reg cs, mosi, sclk;
	wire miso;
	//assign miso = ~mosi;

	task ctrl_write(input [7:0] addr, input [31:0] data); begin
		ctrl_wr <= 1;
		ctrl_rd <= 0;
		ctrl_addr <= addr;
		ctrl_wdat <= data;
		@(posedge clk);
		while (!ctrl_done) @(posedge clk);
		ctrl_wr <= 0;
	end endtask

	task ctrl_read(input [7:0] addr); begin
		ctrl_wr <= 0;
		ctrl_rd <= 1;
		ctrl_addr <= addr;
		@(posedge clk);
		while (!ctrl_done) @(posedge clk);
		ctrl_rd <= 0;
	end endtask

	task xfer_test; begin
		ctrl_write('h0000, 151);
		ctrl_read('h0000);

		$display("%b %x %x %s", cs, ctrl_wdat[7:0], ctrl_rdat[7:0], ctrl_wdat[7:0] === ~ctrl_rdat[7:0] ? "OK" : "NOK");

		repeat (10) @(posedge clk);

		ctrl_write('h0000, 42);
		ctrl_read('h0000);
		$display("%b %x %x %s", cs, ctrl_wdat[7:0], ctrl_rdat[7:0], ctrl_wdat[7:0] === ~ctrl_rdat[7:0] ? "OK" : "NOK");
	end endtask

	task spi_clk; begin
		sclk <= 0;
		repeat (10) @(posedge clk);
		sclk <= 1;	
		repeat (10) @(posedge clk);
	end endtask	

	/*
	task spi_in(input d_in[7:0]); begin

	end endtask
*/

	icosoc_mod_spi_slave uut (
		.clk      (clk      ),
		.resetn   (resetn   ),
		.ctrl_wr  (ctrl_wr  ),
		.ctrl_rd  (ctrl_rd  ),
		.ctrl_addr(ctrl_addr),
		.ctrl_wdat(ctrl_wdat),
		.ctrl_rdat(ctrl_rdat),
		.ctrl_done(ctrl_done),
		.cs       (cs       ),
		.mosi     (mosi     ),
		.miso     (miso     ),
		.sclk     (sclk     )
	);

	initial begin
		@(posedge resetn);
		cs <= 1;
		sclk <= 0;
		repeat (10) @(posedge clk);

		// 0x55 goes out (miso)
		ctrl_write('h0004, 8'h55);
		repeat (10) @(posedge clk);
		
		cs <= 0;
	
		// 0x00 goes in (mosi)
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		

		repeat (10) @(posedge clk);
		ctrl_read('h0004);
		$display("Byte 1 read: %b %x %x %s", cs, ctrl_wdat[7:0], ctrl_rdat[7:0], 'h00 === ctrl_rdat[7:0] ? "OK" : "NOK");
		ctrl_read('h00);
		$display("spi_status / read bits: %x", ctrl_rdat);
		
		cs <= 1;
		repeat(10) @(posedge clk);
		cs <= 0;
		
		// 0x88 goes out (miso)
		ctrl_write('h0004, 8'h88);
		repeat(10) @(posedge clk);

		// 0x55 goes in (mosi)
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b1;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b1;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b1;
		spi_clk();
		mosi <= 'b0;
		spi_clk();
		mosi <= 'b1;
		spi_clk();
		
		repeat (2) @(posedge clk);
		/*
		if (!ctrl_done) begin
			ctrl_wr <= 0;
			repeat (10) @(posedge clk);
			ctrl_read('h0000);
			$display("Byte 2 read: %b %x %x %s", cs, ctrl_wdat[7:0], ctrl_rdat[7:0], 'h55 === ctrl_rdat[7:0] ? "OK" : "NOK");
		end else begin
			$display("no ctrl_done received: NOK!");
		end
		*/
		cs  <= 1;

		$finish;
	end
endmodule
