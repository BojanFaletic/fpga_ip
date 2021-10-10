LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.instruction_set.ALL;

ENTITY rom IS
  PORT (
    clk : IN std_logic;
    address : IN INTEGER RANGE 0 TO 255;
    data : OUT std_logic_vector(11 DOWNTO 0)
  );
END rom;
ARCHITECTURE arch OF rom IS
  TYPE t_rom IS ARRAY(0 TO 255) OF std_logic_vector(11 DOWNTO 0);
  SIGNAL m_rom : t_rom :=
  (
  0 => (INST_ADD & x"00"),
  1 => (INST_SUB & x"00"),
  2 => (INST_ADD & x"00"),
  3 => (INST_LDA & x"00"),
  4 => (INST_ADD & x"00"),
  5 => (INST_STA & x"00"), 
  6 => (INST_JMP & x"00"),

  OTHERS => (OTHERS => '0')
  );

BEGIN

  p_memory : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      data <= m_rom(address);
    END IF;
  END PROCESS;

END ARCHITECTURE;