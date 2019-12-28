LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY sd_controller_tb IS
END ENTITY;

ARCHITECTURE arch OF sd_controller_tb IS

    SIGNAL clk, rst_n : std_logic := '0';
    SIGNAL rd, wr : std_logic := '0';
    SIGNAL address : std_logic_vector(19 DOWNTO 0) := (OTHERS => '0');
    SIGNAL wr_data, rd_data : std_logic_vector(15 DOWNTO 0) := x"0000";

    COMPONENT sd_controller IS
        GENERIC (INIT_SETUP : INTEGER := 50_000);
        PORT (
            clk, rst_n : IN std_logic;
            bs : OUT std_logic_vector(1 DOWNTO 0) := "00";
            cke, cs, ras, cas, we : OUT std_logic := '1';
            data : INOUT std_logic_vector(15 DOWNTO 0);
            addr : OUT std_logic_vector(11 DOWNTO 0);
            -- user control bus
            rd, wr : IN std_logic;
            -- for now ram support only one bank
            address : IN std_logic_vector(19 DOWNTO 0);
            rd_data : OUT std_logic_vector(15 DOWNTO 0);
            wr_data : IN std_logic_vector(15 DOWNTO 0);
            rd_valid : OUT std_logic;
            ready : OUT std_logic
        );
    END COMPONENT;

    SIGNAL sd_data : std_logic_vector(15 DOWNTO 0);

    CONSTANT CLK_PERIOD : TIME := 10 ns;
BEGIN

    p_clk : PROCESS
    BEGIN
        clk <= '1';
        WAIT FOR CLK_PERIOD/2;
        clk <= '0';
        WAIT FOR CLK_PERIOD/2;
    END PROCESS;

    p_stimulate : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD * 10;
        rst_n <= '1';
        WAIT FOR 1 us;
        -- ram is now ready
        address <= std_logic_vector(to_unsigned(1, 20));
        wr_data <= x"1234";
        wr <= '1';
        WAIT FOR CLK_PERIOD;
        wr <= '0';
        WAIT FOR 500 ns;
        rd <= '1';
        WAIT FOR CLK_PERIOD;
        rd <= '0';
    
        WAIT;
    END PROCESS;

    DUT : sd_controller
    GENERIC MAP(INIT_SETUP => 50)
    PORT MAP(
        clk => clk,
        rst_n => rst_n,
        bs => OPEN,
        cke => OPEN,
        cs => OPEN,
        ras => OPEN,
        cas => OPEN,
        we => OPEN,
        data => sd_data,
        addr => OPEN,
        -- user control bus
        rd => rd,
        wr => wr,
        -- for now ram support only one bank
        address => address,
        rd_data => rd_data,
        wr_data => wr_data,
        rd_valid => OPEN,
        ready => OPEN
    );

END arch; -- arch