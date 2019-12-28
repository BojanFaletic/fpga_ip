LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY seven_seg IS
    GENERIC (
        NUM_OF_DIGIT : INTEGER := 4;
        CLK_FREQ : INTEGER := 50_000_000);
    PORT (
        clk, rst_n : IN std_logic;
        active_digit : OUT std_logic_vector(NUM_OF_DIGIT - 1 DOWNTO 0);
        digit_data : OUT std_logic_vector(7 DOWNTO 0);

        data : IN INTEGER RANGE 0 TO 10 ** NUM_OF_DIGIT - 1;
        data_valid : IN std_logic
    );
END ENTITY;

ARCHITECTURE Arch OF seven_seg IS
    CONSTANT SEG_FREQ_HZ : INTEGER := 200;
    CONSTANT DECIMAL_DIGITS : INTEGER := INTEGER(ceil(log2(real(10 ** 4 - 1))));

    COMPONENT prescaler
        GENERIC (
            CLK_FREQ : INTEGER := 50_000_000;
            OUT_FREQ : INTEGER := 1_000);
        PORT (
            clk, rst_n : IN std_logic;
            enable : OUT std_logic
        );
    END COMPONENT;

    COMPONENT binary_to_BCD
        GENERIC (
            g_INPUT_WIDTH : IN POSITIVE;
            g_DECIMAL_DIGITS : IN POSITIVE
        );
        PORT (
            i_Clock : IN std_logic;
            i_Start : IN std_logic;
            i_Binary : IN std_logic_vector(g_INPUT_WIDTH - 1 DOWNTO 0);

            o_BCD : OUT std_logic_vector(g_DECIMAL_DIGITS * 4 - 1 DOWNTO 0);
            o_DV : OUT std_logic
        );
    END COMPONENT;

    SIGNAL prescaler_enable : std_logic;
    SIGNAL enable_digit : INTEGER RANGE 0 TO NUM_OF_DIGIT - 1 := 0;

    SIGNAL binary_data : std_logic_vector(DECIMAL_DIGITS - 1 DOWNTO 0);

    SIGNAL conversion_done : std_logic;
    SIGNAL bcd_data : std_logic_vector(DECIMAL_DIGITS * 4 - 1 DOWNTO 0);
    SIGNAL bcd_digit : std_logic_vector(3 DOWNTO 0);
BEGIN

    binary_data <= std_logic_vector(to_unsigned(data, DECIMAL_DIGITS));

    p_sel_display : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst_n = '0' THEN
                enable_digit <= 0;
            ELSE
                IF prescaler_enable = '1' THEN
                    IF enable_digit /= NUM_OF_DIGIT - 1 THEN
                        enable_digit <= enable_digit + 1;
                    ELSE
                        enable_digit <= 0;
                    END IF;
                END IF;
            END IF;
            active_digit <= (OTHERS => '1');
            active_digit(enable_digit) <= '0';
            digit_data <= bcd_data(4 * (enable_digit + 1) - 1 DOWNTO 4 * enable_digit);
        END IF;
    END PROCESS;

    p_sel_digit : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            -- decimal point is zero
            digit_data(7) <= '1';
            CASE bcd_digit IS
                WHEN "0000" => digit_data(6 DOWNTO 0) <= NOT "0000001"; -- "0"     
                WHEN "0001" => digit_data(6 DOWNTO 0) <= NOT "1001111"; -- "1" 
                WHEN "0010" => digit_data(6 DOWNTO 0) <= NOT "0010010"; -- "2" 
                WHEN "0011" => digit_data(6 DOWNTO 0) <= NOT "0000110"; -- "3" 
                WHEN "0100" => digit_data(6 DOWNTO 0) <= NOT "1001100"; -- "4" 
                WHEN "0101" => digit_data(6 DOWNTO 0) <= NOT "0100100"; -- "5" 
                WHEN "0110" => digit_data(6 DOWNTO 0) <= NOT "0100000"; -- "6" 
                WHEN "0111" => digit_data(6 DOWNTO 0) <= NOT "0001111"; -- "7" 
                WHEN "1000" => digit_data(6 DOWNTO 0) <= NOT "0000000"; -- "8"     
                WHEN OTHERS => digit_data(6 DOWNTO 0) <= NOT "0000100"; -- "9" 
            END CASE;
        END IF;
    END PROCESS;

    U_CLK_DIV : prescaler
    GENERIC MAP(
        CLK_FREQ => CLK_FREQ,
        OUT_FREQ => SEG_FREQ_HZ)
    PORT MAP(
        clk => clk, rst_n => rst_n,
        enable => prescaler_enable
    );

    U_DEC_TO_BCD : binary_to_BCD
    GENERIC MAP(
        g_INPUT_WIDTH => DECIMAL_DIGITS,
        g_DECIMAL_DIGITS => NUM_OF_DIGIT)
    PORT MAP(
        i_Clock => clk,
        i_Start => data_valid,
        i_Binary => binary_data,

        o_BCD => bcd_data,
        o_DV => conversion_done
    );

END ARCHITECTURE;