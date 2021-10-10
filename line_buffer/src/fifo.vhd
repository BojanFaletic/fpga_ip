LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fifo IS
  GENERIC (
    DIN_WIDTH : INTEGER := 12*3;
    MAX_DEPTH : INTEGER := 1024);
  PORT (
    clk, rst_n  : IN STD_LOGIC;
    din         : IN STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
    rd, wr      : IN STD_LOGIC;
    dout        : OUT STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
    dout_valid  : OUT STD_LOGIC;
    empty, full : OUT STD_LOGIC
  );
END ENTITY fifo;

ARCHITECTURE Behavioral OF fifo IS
  TYPE t_memory IS ARRAY(0 TO MAX_DEPTH - 1) OF STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
  SIGNAL memory : t_memory;

  SIGNAL over : STD_LOGIC;

  SIGNAL read_ptr, write_ptr : INTEGER RANGE 0 TO MAX_DEPTH - 1;
BEGIN

  p_fifo : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rst_n = '0' THEN
        read_ptr <= 0;
        write_ptr <= 0;
        over <= '0';
      ELSE
        IF wr = '1' THEN
          -- writing
          memory(write_ptr) <= din;
          IF write_ptr = MAX_DEPTH - 1 THEN
            write_ptr <= 0;
            over <= '1';
          ELSE
            write_ptr <= write_ptr + 1;
          END IF;
        END IF;

        IF rd = '1' THEN
          -- reading
          dout <= memory(read_ptr);
          dout_valid <= '1';
          IF read_ptr = MAX_DEPTH - 1 THEN
            read_ptr <= 0;
            over <= '0';
          ELSE
            read_ptr <= read_ptr + 1;
          END IF;
        ELSE
          dout <= (OTHERS => '0');
          dout_valid <= '0';
        END IF;
      END IF;

      IF read_ptr = write_ptr THEN
        -- if writing and reading
        if rd = '1' and wr = '1' then
          dout <= din;
        end if;

        IF over = '0' THEN
          empty <= '1';
          full <= '0';
        ELSE
          full <= '1';
          empty <= '0';
        END IF;
      END IF;

    END IF;
  END PROCESS p_fifo;
END ARCHITECTURE Behavioral;