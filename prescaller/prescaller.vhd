LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY prescaler IS
    GENERIC (
        CLK_FREQ : INTEGER := 50_000_000;
        OUT_FREQ : INTEGER := 1_000);
    PORT (
        clk, rst_n : IN std_logic;
        enable : OUT std_logic);
END ENTITY;

ARCHITECTURE Arch OF prescaler IS
    CONSTANT COUNT_TO : INTEGER := CLK_FREQ/OUT_FREQ;
    SIGNAL counter : INTEGER RANGE 0 TO COUNT_TO - 1 := 0;
BEGIN

    p_prescaler : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            enable <= '0';
            IF rst_n = '0' THEN
                counter <= 0;
            ELSE
                IF counter = COUNT_TO - 1 THEN
                    enable <= '1';
                    counter <= 0;
                ELSE
                    counter <= counter + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;