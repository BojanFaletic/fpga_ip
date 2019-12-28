LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY seven_seg_tb IS
END ENTITY;

ARCHITECTURE Arch OF seven_seg_tb IS
    CONSTANT CLK_PERIOD : TIME := 10 ns;
    SIGNAL clk, rst_n : std_logic := '0';
    SIGNAL data : INTEGER := 0;
    SIGNAL data_valid : std_logic := '0';
BEGIN
    p_clk : PROCESS
    BEGIN
        clk <= '1';
        WAIT FOR CLK_PERIOD/2;
        clk <= '0';
        WAIT FOR CLK_PERIOD/2;
    END PROCESS;

    p_test : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD * 10;
        rst_n <= '1';
        data <= 1;
        data_valid <= '1';
        WAIT;
    END PROCESS;

    DUT : ENTITY work.seven_seg
        GENERIC MAP(
            NUM_OF_DIGIT => 2,
            CLK_FREQ => 100_000_000)
        PORT MAP(
            clk => clk, rst_n => rst_n,
            active_digit => OPEN,
            digit_data => OPEN,

            data => data,
            data_valid => data_valid
        );
END ARCHITECTURE;