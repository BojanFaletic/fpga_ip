LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.instruction_set.ALL;

ENTITY cpu IS
  PORT (
    clk : IN std_logic;
    IO_IN : IN std_logic_vector(7 DOWNTO 0);
    IO_OUT : OUT std_logic_vector(7 DOWNTO 0);
    IO_ADDR : OUT std_logic_vector(7 DOWNTO 0);
    IO_RD_VALID : OUT std_logic;
    IO_WR_VALID : OUT std_logic
  );
END cpu;

ARCHITECTURE Behavioral OF cpu IS
  CONSTANT CPU_WIDTH : POSITIVE := 12;

  SIGNAL PC : INTEGER RANGE 0 TO 255 := 0;
  SIGNAL rom_PC : INTEGER RANGE 0 TO 255 := 0;

  SIGNAL data_bus : std_logic_vector(11 DOWNTO 0);
  SIGNAL address_bus : std_logic_vector(11 DOWNTO 0);

  SIGNAL memory_w_data : std_logic_vector(11 DOWNTO 0);
  SIGNAL memory_r_data : std_logic_vector(11 DOWNTO 0);
  SIGNAL memory_address : INTEGER RANGE 0 TO 255 := 0;
  SIGNAL memory_write_flag : std_logic;
  SIGNAL memory_read_flag : std_logic;

  TYPE t_machine IS (fetch_s, wait_s, execute_s);
  SIGNAL cpu_stage : t_machine;

  SIGNAL accumulator : INTEGER RANGE 0 TO 2 ** 12 - 1 := 0;

  SIGNAL jmp_active_flag : std_logic := '0';
  SIGNAL jmp_inst_addr : INTEGER RANGE 0 TO 255;

  SIGNAL cpu_pause_flag : std_logic := '0';

  SIGNAL lda_load_flag : std_logic := '0';
BEGIN
  p_main : PROCESS (clk)
  BEGIN

    IF rising_edge(clk) THEN
      CASE cpu_stage IS
        WHEN fetch_s =>
          -- fetch data from external module
          IF jmp_active_flag = '1' THEN
            jmp_active_flag <= '0';
            rom_PC <= jmp_inst_addr;
          ELSE
            -- if prev cmd was not jmp then increment pc  
            IF rom_PC = 255 THEN
              rom_PC <= 0;
            ELSE
              rom_PC <= rom_PC + 1;
            END IF;

          END IF;
          cpu_stage <= wait_s;

        WHEN wait_s =>
          cpu_stage <= execute_s;
          -- execute instruction 
          CASE (data_bus(11 DOWNTO 8)) IS
            WHEN INST_ADD =>
              IF accumulator /= 255 THEN
                accumulator <= accumulator + 1;
              END IF;

            WHEN INST_SUB =>
              IF accumulator /= 0 THEN
                accumulator <= accumulator - 1;
              END IF;

            WHEN INST_LDA =>
              lda_load_flag <= '1';
              memory_address <= to_integer(unsigned(data_bus(7 DOWNTO 0)));
              memory_read_flag <= '1';

            WHEN INST_STA =>
              memory_w_data <= std_logic_vector(to_unsigned(accumulator, 12));
              memory_address <= to_integer(unsigned(data_bus(7 DOWNTO 0)));
              memory_write_flag <= '1';

            WHEN INST_JMP =>
              IF accumulator /= 0 THEN
                jmp_inst_addr <= to_integer(unsigned(data_bus(7 DOWNTO 0)));
                jmp_active_flag <= '1';
              END IF;

            WHEN INST_JMP_ZERO =>
              IF accumulator = 0 THEN
                jmp_inst_addr <= to_integer(unsigned(data_bus(7 DOWNTO 0)));
                jmp_active_flag <= '1';
              END IF;
            WHEN OTHERS =>
              NULL;
          END CASE;
        WHEN execute_s =>
          -- load data to accumulator
          memory_write_flag <= '0';
          IF lda_load_flag = '1' THEN
            lda_load_flag <= '0';
            accumulator <= to_integer(unsigned(memory_r_data));
            memory_read_flag <= '0';
          END IF;

          -- wait until previous command has executed
          IF cpu_pause_flag = '0' THEN
            cpu_stage <= fetch_s;
          END IF;
        WHEN OTHERS =>
          NULL;
      END CASE;

    END IF;
  END PROCESS;

  -- external components
  inst_ROM : ENTITY work.rom
    PORT MAP(
      clk => clk,
      address => rom_PC,
      data => data_bus
    );

  inst_RAM : ENTITY work.ram
    PORT MAP(

      clk => clk,
      data_in => memory_w_data,
      data_out => memory_r_data,
      address => memory_address,
      read_valid => memory_read_flag,
      write_valid => memory_write_flag
    );
END Behavioral;