LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;

ENTITY uart IS
    GENERIC (
        RX_FIFO : INTEGER := 64;
        CLK_HZ : POSITIVE := 50_000_000;
        UART_BAUD : POSITIVE := 115200);
    PORT (
        clk, rst_n : IN std_logic;
        din : IN std_logic_vector(7 DOWNTO 0);
        dout : OUT std_logic_vector(7 DOWNTO 0);
        addr : IN std_logic_vector(7 DOWNTO 0);
        rd, wr : IN std_logic;
        TX : OUT std_logic := 'H';
        RX : IN std_logic := 'H'
    );
END uart;

ARCHITECTURE Behavioral OF uart IS
    TYPE t_machine_tx IS (idle_s, sending_s);
    TYPE t_sending IS (send_s, wait_s);
    TYPE t_receiving IS (wait_s, sampling_s);
    TYPE t_machine_rx IS (idle_s, receiving_s);

    SIGNAL tx_index, rx_index : INTEGER RANGE 0 TO 10;
    SIGNAL send_FSM : t_sending;
    SIGNAL TX_FSM : t_machine_tx;
    SIGNAL recv_FSM : t_receiving;
    SIGNAL RX_FSM : t_machine_RX;

    CONSTANT REG_CNT : INTEGER := 3;
    TYPE t_addr_space IS ARRAY(0 TO REG_CNT - 1) OF std_logic_vector(7 DOWNTO 0);
    SIGNAL ctrl_registers : t_addr_space := (OTHERS => (OTHERS => '0'));

    CONSTANT REG_SEND : INTEGER := 0;
    CONSTANT REG_READ : INTEGER := 1;
    CONSTANT REG_READ_CNT : INTEGER := 2;
    CONSTANT REG_TX_BUSY : INTEGER := 3;

    -- UART sending
    SIGNAL start_sending : std_logic := '0';
    SIGNAL send_buffer : std_logic_vector(7 + 2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL TX_busy : std_logic := '0';

    -- UART receive 
    SIGNAL recv_buffer_full : std_logic := '0';
    SIGNAL recv_byte : std_logic := '0';
    SIGNAL recv_buffer : std_logic_vector(7 + 1 DOWNTO 0) := (OTHERS => '0');

    -- RD fifo signals
    SIGNAL RX_FIFO_cnt : NATURAL := 0;
    SIGNAL RX_fifo_rd_data : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RX_read_req : std_logic := '0';
    SIGNAL RX_fifo_empty : std_logic := '0';

    -- clk divider signals
    CONSTANT COUNT_TO_HALF : INTEGER := CLK_HZ / (UART_BAUD * 2);
    SIGNAL tx_counter, rx_counter : NATURAL RANGE 0 TO COUNT_TO_HALF;
    SIGNAL tx_counter_ov, rx_counter_ov : std_logic := '0';
BEGIN

    p_tx_clk_div : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF TX_FSM = sending_s THEN
                tx_counter <= tx_counter + 1;
            ELSE
                tx_counter_ov <= '0';
            END IF;

            tx_counter_ov <= '0';
            IF tx_counter = COUNT_TO_HALF - 1 THEN
                tx_counter_ov <= '1';
                tx_counter <= 0;
            END IF;
        END IF;
    END PROCESS;

    p_rx_clk_div : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF RX_FSM = receiving_s THEN
                rx_counter <= rx_counter + 1;
            ELSE
                rx_counter <= 0;
            END IF;

            rx_counter_ov <= '0';
            IF rx_counter = COUNT_TO_HALF - 1 THEN
                rx_counter_ov <= '1';
                rx_counter <= 0;
            END IF;
        END IF;
    END PROCESS;

    p_reg_ctr : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            start_sending <= '0';
            CASE to_integer(unsigned(addr)) IS
                WHEN REG_SEND =>
                    IF (wr = '1') AND TX_busy /= '1' THEN
                        start_sending <= '1';
                        send_buffer(7 + 1 DOWNTO 0 + 1) <= din;
                    END IF;
                WHEN REG_READ =>
                    IF rd = '1' AND RX_fifo_empty /= '1' THEN
                        dout <= RX_fifo_rd_data;
                    END IF;
                WHEN REG_READ_CNT =>
                    IF rd = '1' THEN
                        dout <= std_logic_vector(to_unsigned(RX_FIFO_cnt, 8));
                    END IF;
                WHEN REG_TX_BUSY =>
                    IF rd = '1' THEN
                        dout <= b"0000000" & TX_busy;
                    END IF;
                WHEN OTHERS =>
                    ASSERT false REPORT "FSM is in undefined state";
            END CASE;
        END IF;
    END PROCESS;

    p_tx_uart : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst_n = '0' THEN
                tx_index <= 0;
                send_FSM <= send_s;
                TX_FSM <= idle_s;
                TX_busy <= '0';
            ELSE
                CASE TX_FSM IS
                    WHEN idle_s =>
                        IF start_sending = '1' THEN
                            tx_index <= 0;
                            TX_FSM <= sending_s;
                            TX_busy <= '1';
                        END IF;
                    WHEN sending_s =>
                        IF tx_counter_ov = '1' THEN
                            IF tx_index < 10 THEN
                                CASE send_FSM IS
                                    WHEN send_s =>
                                        TX <= send_buffer(tx_index);
                                        send_FSM <= wait_s;
                                    WHEN wait_s =>
                                        tx_index <= tx_index + 1;
                                        send_FSM <= send_s;
                                END CASE;
                            ELSE
                                TX <= 'H';
                                TX_FSM <= idle_s;
                                TX_busy <= '0';
                            END IF;
                        END IF;
                    WHEN OTHERS =>
                        ASSERT false REPORT "FSM is in undefined state";
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    p_rx_uart : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            recv_byte <= '0';

            IF rst_n = '0' THEN
                RX_FSM <= idle_s;
                rx_index <= 0;
                recv_FSM <= wait_s;
            ELSIF recv_buffer_full = '0' THEN
                CASE RX_FSM IS
                    WHEN idle_s =>
                        IF RX = '0' THEN
                            RX_FSM <= receiving_s;
                        END IF;
                    WHEN receiving_s =>
                        IF rx_counter_ov = '1' THEN
                            IF rx_index < 10 THEN
                                CASE recv_FSM IS
                                    WHEN wait_s => recv_FSM <= sampling_s;
                                    WHEN sampling_s =>
                                        IF rx_index < 9 THEN
                                            recv_buffer(rx_index) <= RX;
                                        END IF;
                                        rx_index <= rx_index + 1;
                                        recv_FSM <= wait_s;
                                    WHEN OTHERS =>
                                        ASSERT false REPORT "FSM is in undefined state";
                                END CASE;
                            END IF;
                            IF recv_FSM = sampling_s AND rx_index = 9 THEN
                                recv_byte <= '1';
                                rx_index <= 0;
                                RX_FSM <= idle_s;
                                recv_FSM <= wait_s;
                            END IF;
                        END IF;
                    WHEN OTHERS =>
                        ASSERT false REPORT "FSM is in undefined state";
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    RX_read_req <= '1' WHEN unsigned(addr) = REG_READ AND rd = '1' ELSE
        '0';
    RX_BUF : ENTITY work.fifo
        GENERIC MAP(DEPTH => RX_FIFO)
        PORT MAP(
            clk => clk,
            rst_n => rst_n,
            din => recv_buffer(7 DOWNTO 0),
            din_valid => recv_byte,
            rd => RX_read_req,
            dout => RX_fifo_rd_data,
            rd_cnt => RX_FIFO_cnt,
            empty => RX_fifo_empty,
            full => recv_buffer_full
        );

END Behavioral;