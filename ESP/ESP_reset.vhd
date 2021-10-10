LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
ENTITY ESP_reset IS
    GENERIC (
        CLK_F : INTEGER := 50_000_000;
        BAUD_RATE : INTEGER := 115_200);

    PORT (
        RX : IN std_logic;
        clk : IN std_logic;

        ESP_reset_req : OUT std_logic);
END ESP_reset;

ARCHITECTURE Behavioral OF ESP_reset IS
    CONSTANT C_BAUD_TOLERANCE : real := 0.1;
    CONSTANT C_RST_SEQUENCE_LENGTH : INTEGER := 20;

    CONSTANT C_CLK_PER_BAUD : INTEGER := CLK_F / BAUD_RATE;
    CONSTANT C_CLK_PER_BAUD_HIGH : INTEGER := INTEGER(real(C_CLK_PER_BAUD) * (1.0 + C_BAUD_TOLERANCE));

    TYPE t_machine IS (s0, s1);
    SIGNAL machine : t_machine;

    SIGNAL counter : INTEGER RANGE 0 TO C_CLK_PER_BAUD_HIGH - 1;

    SIGNAL rst_phases : INTEGER RANGE 0 TO C_RST_SEQUENCE_LENGTH * 2 := 0;
    SIGNAL expecting_edge : std_logic := '0';
	 
BEGIN

    p_reset_detector : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            -- measure time in this state
            counter <= counter + 1;

            -- one baud has passed, reset counter
            IF counter > C_CLK_PER_BAUD_HIGH THEN
                rst_phases <= 0;
                counter <= 0;

                -- reset expecting edge to falling, because falling starts transitions
                expecting_edge <= '0';

                -- reset phases
                rst_phases <= 0;
            END IF;

            -- input level has changed
            IF RX = expecting_edge THEN
                -- negate expecting edge
                expecting_edge <= NOT expecting_edge;

                -- set timer as correct
                counter <= 0;
                rst_phases <= rst_phases + 1;
            END IF;

            -- ESP is in programming mode
            IF rst_phases = C_RST_SEQUENCE_LENGTH THEN
                ESP_reset_req <= '1';
                rst_phases <= 0;
            ELSE
                ESP_reset_req <= '0';
            END IF;
        END IF;
    END PROCESS;
END Behavioral;