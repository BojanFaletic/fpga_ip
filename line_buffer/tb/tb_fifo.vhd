LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_fifo IS
END ENTITY tb_fifo;

ARCHITECTURE Behavioral OF tb_fifo IS

  COMPONENT fifo IS
    GENERIC (
      DIN_WIDTH : INTEGER := 8;
      MAX_DEPTH : INTEGER := 16);
    PORT (
      clk, rst_n  : IN STD_LOGIC;
      din         : IN STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
      rd, wr      : IN STD_LOGIC;
      dout        : OUT STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
      dout_valid  : OUT STD_LOGIC;
      empty, full : OUT STD_LOGIC
    );
  END COMPONENT fifo;

  SIGNAL clk : STD_LOGIC := '1';
  SIGNAL rst_n : STD_LOGIC := '0';

  SIGNAL din : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL rd, wr : STD_LOGIC;
BEGIN

  clk <= NOT clk AFTER 5 ns;

  p_stim : PROCESS
  BEGIN
    rd <= '0';
    wr <= '0';
    WAIT FOR 100 ns;
    rst_n <= '1';

    -- test writing
    for i in 0 to 15 loop
      din <= std_logic_vector(to_unsigned(i, 8));
      wr <= '1';
      wait for 10 ns;
    end loop;
    wr <= '0';
   
    -- test reading
    rd <= '1';
    wait for 10*16 ns;
    rd <= '0';

    wait for 200 ns;
    rst_n <= '0';
    wait for 10 ns;
    rst_n <= '1';

    -- test reading and writing
    for i in 0 to 63 loop
      wr <= '1';
      din <= std_logic_vector(to_unsigned(i, 8));
      rd <= '1';
      wait for 10 ns;
    end loop;

    rd <= '0';
    wr <= '0';

    WAIT;
  END PROCESS p_stim;

  fifo_DUT : fifo
  PORT MAP(
    clk        => clk,
    rst_n      => rst_n,
    din        => din,
    rd         => rd,
    wr         => wr,
    dout       => OPEN,
    dout_valid => OPEN,
    empty      => OPEN,
    full       => OPEN
  );

END ARCHITECTURE Behavioral;