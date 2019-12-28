LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY uart_tb IS
END ENTITY;

ARCHITECTURE Behav OF uart_tb IS
    CONSTANT CLK_PERIOD : TIME := 20 ns;
    SIGNAL clk, rst_n : std_logic := '0';
    SIGNAL RX, TX : std_logic := '0';
    SIGNAL din, dout, addr : std_logic_vector(7 DOWNTO 0) := x"00";
    SIGNAL rd, wr : std_logic := '0';
BEGIN

    p_clk : PROCESS
    BEGIN
        clk <= '1';
        WAIT FOR CLK_PERIOD /2;
        clk <= '0';
        WAIT FOR CLK_PERIOD /2;
    END PROCESS;

    p_sim : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD * 10;
        rst_n <= '1';
        WAIT FOR CLK_PERIOD * 10;

        din <= x"02";
        wr <= '1';
        WAIT FOR CLK_PERIOD;
        wr <= '0';

        WAIT FOR CLK_PERIOD * 25;
        din <= x"ff";
        wr <= '1';
        WAIT FOR CLK_PERIOD;
        wr <= '0';

        WAIT FOR CLK_PERIOD * 25;
        addr <= x"02";
        rd <= '1';
        WAIT FOR CLK_PERIOD;
        addr <= x"01";
        WAIT FOR CLK_PERIOD;
        rd <= '0';

        wait for CLK_PERIOD;
        rd <= '1';
        addr <= x"02";
        wait for CLK_PERIOD *10;

        rd <= '1';
        WAIT FOR CLK_PERIOD;
        addr <= x"01";
        WAIT FOR CLK_PERIOD;
        rd <= '0';

        WAIT;
    END PROCESS;
    -- connect RX to TX to test receiving part
    RX <= TX;
    DUT : ENTITY work.UART
        PORT MAP(
            clk => clk,
            rst_n => rst_n,
            din => din,
            dout => dout,
            addr => addr,
            rd => rd,
            wr => wr,
            TX => TX,
            RX => RX
        );

END ARCHITECTURE;