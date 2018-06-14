module icosoc_mod_spi_slave #(
	parameter integer CLOCK_FREQ_HZ = 0
) (
	input clk,
	input resetn,
	
	input clk_in,

	input ctrl_wr,
	input ctrl_rd,
	input [ 7:0] ctrl_addr,
	input [31:0] ctrl_wdat,
	output reg [31:0] ctrl_rdat,
	output reg ctrl_done,

	input cs, sclk, mosi,
	output miso,

	output debug_pin_4, debug_pin_3, debug_pin_2, debug_pin_1
);
	wire spi_mosi, spi_sclk, spi_cs;
	reg spi_miso;

	reg debug_1,debug_2, debug_3, debug_4 = 0;

	reg [1:0] mosi_reg;
	reg [1:0] ctrlwr_reg;
	reg [2:0] sclk_reg, cs_reg;
	
	wire ctrlwr_start = !ctrlwr_reg[1] && ctrlwr_reg[0];
	wire mosi_sync = mosi_reg[1];
	wire sclk_rising = !sclk_reg[2] && sclk_reg[1];
		//sclk_reg[2:1] == 2'b01; // sclk rising edge
	wire sclk_falling = sclk_reg[2:1] == 2'b10; // sclk falling edge
	wire cs_active = ~cs_reg[1]; // CS active
	wire cs_start = cs_reg[2] && !cs_reg[1]; // CS falling edge (start of SPI message)
	wire cs_end = !cs_reg[2] && cs_reg[1];  // CS rising edge (end of SPI message)
	
	reg [31:0] spi_data_out;
	reg [31:0] spi_data_in;
	reg [5:0] spi_state;

	
	reg [3:0] clk_div;
	wire clk_slow = &clk_div;


	SB_IO #(
		.PIN_TYPE(6'b 0110_00),
		.PULLUP(1'b 0)
	) io_miso (
		.PACKAGE_PIN(miso),
		.D_OUT_0(spi_miso)
	);

	SB_IO #(
		.PIN_TYPE(6'b 0110_00),
		.PULLUP(1'b 0)
	) io_dclk2 (
		.PACKAGE_PIN(debug_pin_2),
		.D_OUT_0(debug_2)
	);
	SB_IO #(
		.PIN_TYPE(6'b 0110_00),
		.PULLUP(1'b 0)
	) io_dclk (
		.PACKAGE_PIN(debug_pin_1),
		.D_OUT_0(debug_1)
	);

	SB_IO #(
		.PIN_TYPE(6'b 0110_00),
		.PULLUP(1'b 0)
	) io_dclk3 (
		.PACKAGE_PIN(debug_pin_3),
		.D_OUT_0(debug_3)
	);
	SB_IO #(
		.PIN_TYPE(6'b 0110_00),
		.PULLUP(1'b 0)
	) io_dclk4 (
		.PACKAGE_PIN(debug_pin_4),
		.D_OUT_0(debug_4)
	);



	SB_IO #(
		.PIN_TYPE(6'b 0000_01),
		.PULLUP(1'b 0)
	) io_mosi (
		.PACKAGE_PIN(mosi),
		.D_IN_0(spi_mosi)
	);

	SB_IO #(
		.PIN_TYPE(6'b 0000_01),
		.PULLUP(1'b 0)
	) io_sclk (
		.PACKAGE_PIN(sclk),
		.D_IN_0(spi_sclk)
	);

	SB_IO #(
		.PIN_TYPE(6'b 0000_01),
		.PULLUP(1'b 0)
	) io_cs (
		.PACKAGE_PIN(cs),
		.D_IN_0(spi_cs)
	);
	
	
	always @(posedge clk) begin
		ctrl_rdat <= 'bx;
		ctrl_done <= 0;
				
		sclk_reg <= { sclk_reg[1:0], spi_sclk };
		cs_reg <= { cs_reg[1:0], spi_cs };
		mosi_reg <= { mosi_reg[0], spi_mosi };
		ctrlwr_reg <= { ctrlwr_reg[0], ctrl_wr };

		if (!resetn) begin
			spi_miso <= 0;
			spi_state <= 33;
			spi_data_out <= 0;
			spi_data_in <= 0;

		end else
		if (!ctrl_done) begin
			if (ctrl_wr) begin
				if (ctrl_addr == 'h04) begin
					if (ctrlwr_start) begin
						spi_data_out <= ctrl_wdat;
						spi_data_in <= 0;
						spi_miso <= 0;
						spi_state <= 33;
					end
					else if (cs_end) begin
						spi_state <= 33;
						spi_miso <= 0;
					end	
					else if ((spi_state == 33) && cs_start) begin
						spi_state = 0; 
						spi_miso <= spi_data_out[31];
					end
					else if (spi_state == 32) begin
						ctrl_done <= 1;
						spi_state <= spi_state + 1;
					end
					else if (sclk_rising && cs_active) begin
						spi_miso <= spi_data_out[31 - spi_state];
						spi_data_in[31 - spi_state] = spi_mosi;
						spi_state <= spi_state + 1;
					end
				end
			end
			if (ctrl_rd) begin
				ctrl_done <= 1; 
				if (ctrl_addr == 'h00) ctrl_rdat <= spi_state;
				if (ctrl_addr == 'h04) ctrl_rdat <= spi_data_out;
				if (ctrl_addr == 'h08) ctrl_rdat <= spi_data_in;
			end

		end else



		debug_1 <= cs_start;
		debug_3 <= cs_end;
		debug_2 <= 0;
		debug_4 <= 0;

	end
endmodule

