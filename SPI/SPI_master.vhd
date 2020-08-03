LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
-- clk_hz_c = input clock frequency
-- spi_hz_c = SPI clock frequency
-- spi_word_len_c = size of word, default to 8b

-- select_slave = is slave selected
-- start_write = data is ready to send
-- done_write = write is done, data can be read
-- write_data = register data to write 
-- read_data = register data to read
ENTITY SPI_master IS
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
END SPI_master;

ARCHITECTURE Behavioral OF SPI_master IS
  CONSTANT prescaller_max_counter_c : INTEGER := clk_hz_c/spi_hz_c/4 - 1;
  SIGNAL prescaller_counter : INTEGER RANGE 0 TO prescaller_max_counter_c;
  SIGNAL prescaller_en : BOOLEAN;

  SIGNAL write_data_r, read_data_r : std_logic_vector(spi_word_len_c - 1 DOWNTO 0);
  SIGNAL master_is_busy : BOOLEAN;
  SIGNAL bit_cnt : INTEGER RANGE 0 TO spi_word_len_c - 1;
  SIGNAL pos_in_bit : INTEGER RANGE 0 TO 3;

  SIGNAL sck_r : std_logic;

  PROCEDURE process_one_bit (SIGNAL write_register, read_register : INOUT std_logic_vector(spi_word_len_c - 1 DOWNTO 0);
  SIGNAL bit_cnt, pos_in_bit : INOUT INTEGER;
  SIGNAL MISO : IN std_logic;
  SIGNAL MOSI, SCK : OUT std_logic) IS
BEGIN
  IF (pos_in_bit = 0) THEN
    pos_in_bit <= 1;
    MOSI <= write_register(spi_word_len_c - 1);

    -- shift left
    write_register <= write_register(spi_word_len_c - 2 DOWNTO 0) & '0';

    SCK <= '0';
    ELSIF (pos_in_bit = 1) THEN
    pos_in_bit <= 2;
    SCK <= '1';
    ELSIF (pos_in_bit = 2) THEN
    pos_in_bit <= 3;
    MOSI <= 'Z';

    -- right shift
    read_register <= read_register(spi_word_len_c - 2 DOWNTO 0) & MISO;

    ELSE
    bit_cnt <= bit_cnt + 1;
    pos_in_bit <= 0;
    SCK <= '0';
  END IF;
END PROCEDURE process_one_bit;
BEGIN

master_spi : PROCESS (clk)
BEGIN
  IF rising_edge(clk) THEN
    IF rst_n = '0' THEN
      master_is_busy <= false;
      bit_cnt <= 0;
      pos_in_bit <= 0;
      ELSE
      SS <= NOT select_slave;

      -- fast IO interface
      IF (NOT master_is_busy) THEN
        -- start write process  
        IF (start_write = '1') THEN
          write_data_r <= write_data;
          master_is_busy <= true;
          done_write <= '0';
        END IF;
        -- main SPI logic
        ELSIF (prescaller_en) THEN
        IF (bit_cnt /= spi_word_len_c) THEN
          process_one_bit(write_data_r, read_data_r, bit_cnt, pos_in_bit,
          MISO, MOSI, SCK);
          ELSE
          bit_cnt <= 0;
          master_is_busy <= false;
          done_write <= '1';
        END IF;
      END IF;
    END IF;
  END IF;
END PROCESS master_spi;

read_data <= read_data_r;

prescaller : PROCESS (clk)
BEGIN
  IF rising_edge(clk) THEN
    IF rst_n = '0' THEN
      prescaller_counter <= 0;
      prescaller_en <= false;
      ELSE
      IF (prescaller_counter = prescaller_max_counter_c) THEN
        prescaller_en <= true;
        prescaller_counter <= 0;
        ELSE
        prescaller_en <= false;
        prescaller_counter <= prescaller_counter + 1;
      END IF;
    END IF;
  END IF;
END PROCESS prescaller;
END Behavioral;