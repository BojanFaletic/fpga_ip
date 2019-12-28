LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fifo IS
    GENERIC (DEPTH : INTEGER := 64);
    PORT (
        clk, rst_n : IN std_logic;
        din : IN std_logic_vector(7 DOWNTO 0);
        din_valid, rd : IN std_logic;
        dout : OUT std_logic_vector(7 DOWNTO 0);
        rd_cnt : OUT NATURAL;
        empty, full : OUT std_logic
    );
END ENTITY;

ARCHITECTURE Behav OF fifo IS
    TYPE t_memory IS ARRAY(0 TO DEPTH - 1) OF std_logic_vector(7 DOWNTO 0);
BEGIN

    p_fifo : PROCESS (clk, rd)
        VARIABLE memory : t_memory;

        VARIABLE read_ptr, write_ptr : NATURAL RANGE 0 TO DEPTH := 0;

        VARIABLE s_empty, s_full : BOOLEAN := false;
    BEGIN
        s_empty := read_ptr = write_ptr;
        s_full := read_ptr = write_ptr + 1 OR
            (write_ptr = DEPTH - 1 AND read_ptr = 0);

        IF s_empty THEN
            empty <= '1';
        ELSE
            empty <= '0';
        END IF;
        IF s_full THEN
            full <= '1';
        ELSE
            full <= '0';
        END IF;
        IF rising_edge(clk) THEN
            IF rst_n = '0' THEN
                read_ptr := 0;
                write_ptr := 0;
            ELSE
                -- read num of written words in FIFO
                rd_cnt <= write_ptr - read_ptr;
                IF s_empty THEN
                    IF din_valid = '1' THEN
                        memory(write_ptr) := din;
                        IF write_ptr = DEPTH - 1 THEN
                            write_ptr := 0;
                        ELSE
                            write_ptr := write_ptr + 1;
                        END IF;
                    END IF;
                ELSIF s_full THEN
                    IF rd = '1' THEN
                        IF read_ptr = DEPTH - 1 THEN
                            read_ptr := 0;
                        ELSE
                            read_ptr := read_ptr + 1;
                        END IF;
                    END IF;
                ELSE
                    IF din_valid = '1' THEN
                        memory(write_ptr) := din;
                        IF write_ptr = DEPTH - 1 THEN
                            write_ptr := 0;
                        ELSE
                            write_ptr := write_ptr + 1;
                        END IF;
                    END IF;
                    IF rd = '1' THEN
                        IF read_ptr = DEPTH - 1 THEN
                            read_ptr := 0;
                        ELSE
                            read_ptr := read_ptr + 1;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
        IF rd = '1' THEN
            dout <= memory(read_ptr);
        END IF;
    END PROCESS;

END ARCHITECTURE;