LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ram is
  PORT (
    clk : IN std_logic;
    data_in : IN std_logic_vector(11 DOWNTO 0);
    data_out : OUT std_logic_vector(11 DOWNTO 0);
    address : IN INTEGER RANGE 0 TO 255 := 0;
    read_valid : IN std_logic;
    write_valid : IN std_logic
  );
END ram;

ARCHITECTURE Arch OF ram IS
  TYPE t_ram IS ARRAY(0 TO 255) OF std_logic_vector(11 DOWNTO 0);
  SIGNAL ram : t_ram := (others => (others => '0'));
BEGIN

  p_ram : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF write_valid = '1' AND read_valid = '0' THEN
        ram(address) <= data_in;
      ELSIF write_valid = '0' AND read_valid = '1' THEN
        data_out <= ram(address);
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;