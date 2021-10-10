LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY tb_sobel_core IS
END ENTITY tb_sobel_core;

ARCHITECTURE Behavioral OF tb_sobel_core IS
  SIGNAL clk : STD_LOGIC := '1';
  SIGNAL rst_n : STD_LOGIC := '0';

  SIGNAL data_in : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"00";
  SIGNAL data_in_valid : STD_LOGIC := '0';
  SIGNAL data_out : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL data_out_valid : STD_LOGIC;
  SIGNAL line_width, line_height : STD_LOGIC_VECTOR(15 DOWNTO 0);
  signal data_in_tlast : std_logic;

  constant C_IMG_SIZE : integer := 4;

BEGIN

  clk <= NOT clk AFTER 5 ns;

  p_test : PROCESS
  BEGIN
    rst_n <= '0';
    data_in_tlast <= '0';
    WAIT FOR 100 ns;
    rst_n <= '1';
    line_width <= STD_LOGIC_VECTOR(to_unsigned(C_IMG_SIZE, 16));
    line_height <= STD_LOGIC_VECTOR(to_unsigned(C_IMG_SIZE, 16));

    -- send data
    FOR k IN 0 TO C_IMG_SIZE**2-1 LOOP
      IF k MOD C_IMG_SIZE = 0 THEN
        data_in <= (OTHERS => '0');
        data_in_valid <= '0';
        WAIT FOR 100 ns;
      END IF;
      if (k = C_IMG_SIZE**2-1) then
        data_in_tlast <= '1';
      end if;
      data_in <= STD_LOGIC_VECTOR(to_unsigned(k, 8));
      data_in_valid <= '1';
      WAIT FOR 10 ns;
    END LOOP;
    data_in_tlast <= '0';
    data_in <= (OTHERS => '0');
    data_in_valid <= '0';

    WAIT;

  END PROCESS p_test;

  test_sobel : ENTITY work.sobel_core
    GENERIC MAP(
      C_DIN_WIDTH => 8,
      C_MAX_WIDTH => 640
    )
    PORT MAP(
      clk            => clk,
      rst_n          => rst_n,
      data_in        => data_in,
      data_in_valid  => data_in_valid,
      data_in_tlast => data_in_tlast,
      data_out       => data_out,
      data_out_valid => data_out_valid,
      data_out_tlast => open,
      line_width     => line_width,
      line_height    => line_height
    );

END ARCHITECTURE Behavioral;