
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY tb_SPI_master IS
END tb_SPI_master;

ARCHITECTURE Behavioral OF tb_SPI_master IS
  SIGNAL clk, rst_n : std_logic := '0';
  SIGNAL select_slave : std_logic := '0';
  SIGNAL write_data, read_data : std_logic_vector(7 DOWNTO 0) := X"00";
  SIGNAL start_write, done_write : std_logic := '0';

  SIGNAL SS, SCK, MOSI, MISO : std_logic := 'Z';
  COMPONENT SPI_master IS
    GENERIC (
      clk_hz_c : INTEGER := 50_000_000;
      spi_hz_c : INTEGER := 100_000;
      spi_word_len_c : INTEGER := 8);
    PORT (
      rst_n, clk : IN std_logic;
      -- user interface
      select_slave : IN std_logic;
      write_data   : IN std_logic_vector(spi_word_len_c - 1 DOWNTO 0);
      start_write  : IN std_logic;
      read_data    : OUT std_logic_vector(spi_word_len_c - 1 DOWNTO 0);
      done_write   : OUT std_logic;

      -- SPI master port
      SS   : OUT std_logic;
      SCK  : OUT std_logic;
      MOSI : OUT std_logic;
      MISO : IN std_logic
    );
  END COMPONENT SPI_master;
BEGIN

  clk_process : PROCESS
  BEGIN
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
  END PROCESS clk_process;


  stim_process : process
  begin
    wait for 100 ns;

    rst_n <= '1';

    wait for 100 ns;

    -- test writing
    write_data <= x"03";
    start_write <= '1';
    wait for 10 ns;
    start_write <= '0';

    wait for 500*500 ns;

    -- test writing 2 byte
    write_data <= x"5a";
    start_write <= '1';
    wait for 10 ns;
    start_write <= '0';

    wait for 500*500 ns;


    wait;

  end process;

  -- test connect miso to and mosi
  MISO <= MOSI;


  DUT : SPI_master
  GENERIC map (
    clk_hz_c => 50_000_000,
    spi_hz_c => 100_000,
    spi_word_len_c => 8)
  PORT MAP(
    rst_n => rst_n, clk => clk, select_slave => select_slave,
    write_data => write_data, start_write => start_write, read_data => read_data, done_write => done_write,
    SS => SS, SCK => SCK, MOSI => MOSI, MISO => MISO);
END Behavioral;