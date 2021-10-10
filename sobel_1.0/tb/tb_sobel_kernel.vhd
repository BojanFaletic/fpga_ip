LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
ENTITY tb_sobel_kernel IS
END ENTITY tb_sobel_kernel;

ARCHITECTURE Behav OF tb_sobel_kernel IS
  SIGNAL clk : STD_LOGIC := '1';
  SIGNAL din : STD_LOGIC_VECTOR(8 * 9 - 1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL din_valid : STD_LOGIC := '0';
BEGIN

  clk <= NOT clk AFTER 5 ns;

  p_test : PROCESS
  BEGIN
    WAIT FOR 100 ns;

    FOR i IN 0 TO 8 LOOP
      din(8 * (i + 1) - 1 DOWNTO 8 * i) <= STD_LOGIC_VECTOR(to_unsigned(0, 8));
    END LOOP;
    din(8 * (5 + 1) - 1 DOWNTO 8 * 5) <= STD_LOGIC_VECTOR(to_unsigned(255, 8));
    din_valid <= '1';

    WAIT FOR 10 ns;
    din_valid <= '0';
    din <= (OTHERS => '0');
    WAIT;
  END PROCESS p_test;

  sobel_core_test : ENTITY work.sobel_kernel
    PORT MAP(
      clk        => clk,
      din        => din,
      din_valid  => din_valid,
      dout       => OPEN,
      dout_valid => OPEN);

END ARCHITECTURE Behav;