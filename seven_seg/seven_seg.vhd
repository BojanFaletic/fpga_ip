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
    CONSTANT DECIMAL_DIGITS : INTEGER := INTEGER(ceil(log2(real(10 ** NUM_OF_DIGIT - 1))));

    SIGNAL prescaler_enable : std_logic := '1';
    SIGNAL enable_digit : INTEGER RANGE 0 TO NUM_OF_DIGIT - 1 := 0;

    SIGNAL binary_data : std_logic_vector(DECIMAL_DIGITS - 1 DOWNTO 0);

    SIGNAL conversion_busy : std_logic;
    SIGNAL bcd_data, bcd_data_buffered : std_logic_vector(NUM_OF_DIGIT * 4 - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL bcd_digit : std_logic_vector(3 DOWNTO 0) := (OTHERS => '0');
BEGIN

    binary_data <= std_logic_vector(to_unsigned(data, DECIMAL_DIGITS));
    p_hold_data : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF conversion_busy = '0' THEN
                bcd_data_buffered <= bcd_data;
            END IF;
        END IF;
    END PROCESS;

    gen_if_multiple : IF NUM_OF_DIGIT > 1 GENERATE
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
                bcd_digit <= bcd_data_buffered(4 * (enable_digit + 1) - 1 DOWNTO 4 * enable_digit);
            END IF;
        END PROCESS;
    END GENERATE;
    gen_if_one_digit : IF NUM_OF_DIGIT = 1 GENERATE
        active_digit(0) <= '0';
        bcd_digit <= bcd_data_buffered(4 - 1 DOWNTO 0);
    END GENERATE;

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

    gen_if_multiple_digits : IF NUM_OF_DIGIT > 1 GENERATE
        U_CLK_DIV : ENTITY work.prescaler
            GENERIC MAP(
                CLK_FREQ => CLK_FREQ,
                OUT_FREQ => SEG_FREQ_HZ)
            PORT MAP(
                clk => clk, rst_n => rst_n,
                enable => prescaler_enable
            );
    END GENERATE;

    U_DEC_TO_BCD : ENTITY work.binary_to_BCD
        GENERIC MAP(
            bits => DECIMAL_DIGITS,
            digits => NUM_OF_DIGIT)
        PORT MAP(
            clk => clk,
            reset_n => rst_n,
            ena => data_valid,
            binary => binary_data,
            busy => conversion_busy,
            bcd => bcd_data
        );

END ARCHITECTURE;