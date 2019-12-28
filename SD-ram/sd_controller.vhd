LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
-- input clk should be 100 MHz

ENTITY sd_controller IS
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
END ENTITY;

ARCHITECTURE Arch OF sd_controller IS
    -- SDram commands
    CONSTANT NOP_CMD : std_logic_vector(3 DOWNTO 0) := "0111";
    CONSTANT READ_CMD : std_logic_vector(3 DOWNTO 0) := "0101";
    CONSTANT WRITE_CMD : std_logic_vector(3 DOWNTO 0) := "0100";
    CONSTANT OPEN_ROW_CMD : std_logic_vector(3 DOWNTO 0) := "0011";
    CONSTANT PRECHARGE_ROW_CMD : std_logic_vector(3 DOWNTO 0) := "0010";
    CONSTANT AUTO_REFRESH_CMD : std_logic_vector(3 DOWNTO 0) := "0001";
    CONSTANT PROGRAM_CMD : std_logic_vector(3 DOWNTO 0) := "0000";
    SIGNAL ctrl_signal : std_logic_vector(3 DOWNTO 0);

    -- mode control settings
    CONSTANT PROGRAM_CFG_BA : std_logic_vector(1 DOWNTO 0) := "00";
    CONSTANT PROGRAM_CFG_ADDR : std_logic_vector(11 DOWNTO 0) := "000000100000";

    -- main state machine
    TYPE t_controller_FSM IS (start_s, program_s, program_nop_s, idle_s, active_w_s,
        active_nop_w_s, active_r_s, active_nop_r_s, read_s, write_s, close_s, close_nop_s, refresh_s, refresh_nop_s);
    SIGNAL controller_FSM : t_controller_FSM;

    -- auto refresh signals
    SIGNAL refresh_req, refresh_set, refresh_clear : BOOLEAN := false;
    CONSTANT NUM_OF_ROWS : INTEGER := 4096;
    CONSTANT CLK_FREQ : INTEGER := 100_000_000;
    CONSTANT REF_INTERVAL : INTEGER := 64;

    CONSTANT REFRESH_PERIOD : INTEGER := CLK_FREQ/((NUM_OF_ROWS/REF_INTERVAL) * 1000);
    SIGNAL refresh_counter : INTEGER RANGE 0 TO REFRESH_PERIOD - 1 := 0;

    -- misc signals
    -- row = addr 0 -> 11;
    -- column = addr 0 -> 7 @A10 = auto precharge flag
    CONSTANT ENABLE_AUTO_PRECHARGE : std_logic_vector(3 DOWNTO 0) := "0100";
    SIGNAL row_addr : std_logic_vector(11 DOWNTO 0);
    SIGNAL column_addr : std_logic_vector(7 DOWNTO 0);

    -- useful constants
    CONSTANT ZERO8 : std_logic_vector(7 DOWNTO 0) := x"00";
BEGIN

    bs <= b"00";
    cke <= '1';

    cs <= ctrl_signal(3);
    ras <= ctrl_signal(2);
    cas <= ctrl_signal(1);
    we <= ctrl_signal(0);

    row_addr <= address(19 DOWNTO 12);
    column_addr <= address(11 DOWNTO 0);

    p_controller : PROCESS (clk)
        VARIABLE delay : INTEGER RANGE 0 TO 100_000 := 0;
    BEGIN
        IF rising_edge(clk) THEN
            IF rst_n = '0' THEN
                controller_FSM <= start_s;
                delay := 0;
            ELSE
                CASE controller_FSM IS
                    WHEN start_s =>
                        -- wait for some time for power stabilization
                        ready <= '0';
                        IF delay < 100_000 THEN
                            delay := delay + 1;
                        ELSE
                            delay := 0;
                            controller_FSM <= program_s;
                        END IF;
                    WHEN program_s =>
                        ctrl_signal <= PROGRAM_CMD;
                        bs <= PROGRAM_CFG_BA;
                        addr <= PROGRAM_CFG_ADDR;
                        controller_FSM <= program_nop_s;
                    WHEN program_nop_s =>
                        ctrl_signal <= PROGRAM_NOP;
                        controller_FSM <= idle_s;

                    WHEN idle_s =>
                        -- ram is programmed waiting for rd/wr cmd
                        ready <= '1';
                        rd_valid <= '0';
                        ctrl_signal <= NOP_CMD;
                        IF refresh_set THEN
                            controller_FSM <= refresh_s;
                            refresh_clear <= true;
                            ready <= '0';
                        ELSIF wr = '1' THEN
                            ready <= '0';
                            controller_FSM <= active_w_s;
                        ELSIF rd = '1' THEN
                            ready <= '0';
                            controller_FSM <= active_r_s;
                        END IF;

                    WHEN active_w_s =>
                        -- open row
                        ctrl_signal <= PRECHARGE_ROW_CMD;
                        addr <= row_addr;
                        controller_FSM <= active_nop_w_s;
                    WHEN active_nop_w_s =>
                        ctrl_signal <= NOP_CMD;
                        controller_FSM <= write_s;
                    WHEN write_s =>
                        ctrl_signal <= WRITE_CMD;
                        addr <= ENABLE_AUTO_PRECHARGE & column_addr;
                        data <= wr_data;
                        controller_FSM <= close_s;

                    WHEN active_r_s =>
                        ctrl_signal <= PRECHARGE_ROW_CMD;
                        addr <= row_addr;
                        controller_FSM <= active_nop_r_s;
                    WHEN active_nop_r_s =>
                        ctrl_signal <= NOP_CMD;
                        controller_FSM <= read_s;
                    WHEN read_s =>
                        ctrl_signal <= READ_CMD;
                        addr <= ENABLE_AUTO_PRECHARGE & column_addr;
                        rd_data <= data;
                        rd_valid <= '1';
                        controller_FSM <= close_s;

                    WHEN close_s =>
                        rd_valid <= '0';
                        ctrl_signal <= NOP_CMD;
                        addr <= ENABLE_AUTO_PRECHARGE & ZERO8;
                        controller_FSM <= idle_s;

                    WHEN refresh_s =>
                        refresh_clear <= false;
                        ctrl_signal <= AUTO_REFRESH_CMD;
                        controller_FSM <= refresh_nop_s;
                    WHEN refresh_nop_s =>
                        ctrl_signal <= NOP_CMD;
                        controller_FSM <= idle_s;
                        ready <= '1';
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    p_refresh_controller : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF refresh_counter = REFRESH_PERIOD - 1 THEN
                refresh_req <= true;
                refresh_counter <= 0;
            ELSE
                refresh_req <= false;
                refresh_counter <= refresh_counter + 1;
            END IF;
        END IF;
    END PROCESS;

    p_refresh_ack : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF refresh_req THEN
                refresh_set <= true;
            END IF;
            IF refresh_clear THEN
                refresh_set <= false;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;