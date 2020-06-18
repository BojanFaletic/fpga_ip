LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY jitter IS
    GENERIC (FILTER_SIZE : INTEGER := 4);
    PORT (
        clk : IN std_logic;
        din : IN std_logic;
        dout : OUT std_logic := '0');
END jitter;
ARCHITECTURE Arch OF jitter IS
    SIGNAL latch : std_logic_vector(FILTER_SIZE - 1 DOWNTO 0) := (OTHERS => '0');
BEGIN

    p_filter : PROCESS (clk)
        VARIABLE v_all_and, v_all_or, S, R : std_Logic;
    BEGIN
        IF rising_edge(clk) THEN
            latch(0) <= din;

            v_all_and := latch(0);
            v_all_or := latch(0);

            FOR i IN FILTER_SIZE - 1 DOWNTO 1 LOOP
                v_all_and := v_all_and AND latch(i);
                v_all_or := v_all_or OR latch(i);
            END LOOP;

            FOR i IN FILTER_SIZE - 1 DOWNTO 1 LOOP
                latch(i) <= latch(i - 1);
            END LOOP;

            S := v_all_and;
            R := NOT v_all_or;

            -- SR latch
            IF S = '1' THEN
                dout <= '1';
            ELSIF R = '1' THEN
                dout <= '0';
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;