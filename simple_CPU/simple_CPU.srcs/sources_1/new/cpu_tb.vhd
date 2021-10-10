LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY cpu_tb IS
END ENTITY;

ARCHITECTURE arch OF cpu_tb IS
  SIGNAL clk : std_logic;

  CONSTANT C_CLK_PERIOD : TIME := 10 ns;
BEGIN

  p_clk : PROCESS
  BEGIN
    clk <= '1';
    WAIT FOR C_CLK_PERIOD/2;
    clk <= '0';
    WAIT FOR C_CLK_PERIOD/2;
  END PROCESS;

  inst_cpu : ENTITY work.cpu
    PORT MAP(
      clk => clk,
      IO_IN => (OTHERS => '0'),
      IO_OUT => OPEN,
      IO_ADDR => OPEN,
      IO_RD_VALID => OPEN,
      IO_WR_VALID => OPEN
    );

END arch; -- arch