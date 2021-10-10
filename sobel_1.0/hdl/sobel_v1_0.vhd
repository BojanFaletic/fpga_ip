LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY sobel_v1_0 IS
	GENERIC (
		-- Users to add parameters here
		IMAGE_WIDTH : INTEGER := 640;
		IMAGE_HEIGHT : INTEGER := 480;
		DIN_WIDTH : INTEGER := 8
	);
	PORT (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line
		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk    : IN STD_LOGIC;
		s00_axis_aresetn : IN STD_LOGIC;
		s00_axis_tdata   : IN STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
		s00_axis_tlast   : IN STD_LOGIC;
		s00_axis_tvalid  : IN STD_LOGIC;

		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_tvalid : OUT STD_LOGIC;
		m00_axis_tdata  : OUT STD_LOGIC_VECTOR(DIN_WIDTH DOWNTO 0);
		m00_axis_tlast  : OUT STD_LOGIC
	);
END sobel_v1_0;

ARCHITECTURE arch_imp OF sobel_v1_0 IS
	CONSTANT line_width : STD_LOGIC_VECTOR(15 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(IMAGE_WIDTH, 16));
	CONSTANT line_height : STD_LOGIC_VECTOR(15 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(IMAGE_HEIGHT, 16));
BEGIN
	-- Add user logic here
	sobel_core_inst : ENTITY work.sobel_core
		GENERIC MAP(
			C_DIN_WIDTH => DIN_WIDTH,
			C_MAX_WIDTH => IMAGE_WIDTH
		)
		PORT MAP(
			clk            => s00_axis_aclk,
			rst_n          => s00_axis_aresetn,
			data_in        => s00_axis_tdata,
			data_in_valid  => s00_axis_tvalid,
			data_in_tlast  => s00_axis_tlast,
			data_out       => m00_axis_tdata,
			data_out_valid => m00_axis_tvalid,
			data_out_tlast => m00_axis_tlast,
			line_width     => line_width,
			line_height    => line_height
		);
	-- User logic ends

END arch_imp;