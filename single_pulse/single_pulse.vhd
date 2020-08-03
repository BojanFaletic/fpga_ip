LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- edge = 1:generate output when din from low to high
-- edge = 0:generate output when din from high to low

-- set one clock long pulse at rising edge, with latency of 1 clk

ENTITY single_pulse IS
  GENERIC (edge_c : integer := 1);
  PORT (
    clk, rst_n : IN std_logic;
    din        : IN std_Logic;
    dout       : OUT std_logic);
END single_pulse;

ARCHITECTURE Behavioral OF single_pulse IS
  type edge_t is array(boolean) of std_logic;
  constant edge_s : edge_t := (true=>'1', false=>'0');

  CONSTANT prev_state_c : std_logic := not edge_s(edge_c = 1);
  CONSTANT din_c : std_logic := edge_s(edge_c = 1);

  SIGNAL previous_state : std_logic;
BEGIN

  single_pulse : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF (rst_n = '0') THEN
        previous_state <= '0';
        dout <= '0';
        ELSE
        previous_state <= din;
        IF (previous_state = prev_state_c AND din = din_c) THEN
          dout <= '1';
          ELSE
          dout <= '0';
        END IF;
      END IF;
    END IF;
  END PROCESS single_pulse;
END Behavioral;
