LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY line_buffer IS
  GENERIC (
    DIN_WIDTH : INTEGER := 8;
    MAX_DEPTH : INTEGER := 16);
  PORT (
    clk, rst_n : IN STD_LOGIC;
    set_depth  : IN unsigned(15 DOWNTO 0);
    din        : IN STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
    rd, wr  : IN STD_LOGIC;
    dout       : OUT STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
    dout_valid : OUT STD_LOGIC
  );
END ENTITY line_buffer;

ARCHITECTURE Behavioral OF line_buffer IS

  TYPE t_memory IS ARRAY(0 TO MAX_DEPTH - 1) OF STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
  SIGNAL memory : t_memory;

  SIGNAL read_ptr, write_ptr : INTEGER RANGE 0 TO MAX_DEPTH - 1;
BEGIN

  p_fifo : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rst_n = '0' THEN
        read_ptr <= 0;
        write_ptr <= 0;
      ELSE
        if wr = '1' THEN
          -- writing
          memory(write_ptr) <= din;
          if write_ptr = set_depth then
            write_ptr <= 0;
          else
            write_ptr <= write_ptr + 1;
          end if;
        elsif rd = '1' THEN
          dout <= memory(read_ptr);
          
          
          if read_ptr = set_depth then
            read_ptr <= 0;
          else
            read_ptr <= read_ptr + 1;
          end if;
        end if;
      END IF;
    END IF;
  END PROCESS p_fifo;
END ARCHITECTURE Behavioral;