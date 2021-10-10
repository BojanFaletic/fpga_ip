LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE ieee.math_real.ALL;

ENTITY stack IS
  GENERIC (
    D_WIDTH : INTEGER := 12;
    MAX_DEPTH : INTEGER := 32;
    MAX_EXISTING_STACKS : INTEGER := 5
  );
  PORT (
    clk : IN std_logic;
    OP_CODE : IN INTEGER RANGE 0 TO 5;
    data_in : IN std_logic_vector(D_WIDTH - 1 DOWNTO 0);
    data_out : OUT std_logic_vector(D_WIDTH - 1 DOWNTO 0)
  );
END;

ARCHITECTURE Arch OF stack IS
  -- command nop
  CONSTANT C_CMD_NOP : INTEGER := 0;
  -- pop element from stack
  CONSTANT C_CMD_POP : INTEGER := 1;
  -- push element to stack
  CONSTANT C_CMD_PUSH : INTEGER := 2;
  -- insert element at begging of stack
  CONSTANT C_CMD_APPEND : INTEGER := 3;
  -- create start of stack
  CONSTANT C_CMD_CREATE_NEW_STACK : INTEGER := 4;
  -- destroy latest stack
  CONSTANT C_CMD_DESTROY_PREV_STACK : INTEGER := 5;

  TYPE t_memory IS ARRAY(0 TO MAX_DEPTH - 1) OF std_logic_vector(D_WIDTH - 1 DOWNTO 0);
  SIGNAL memory : t_memory := (OTHERS => (OTHERS => '0'));
  SIGNAL pointing_at : INTEGER RANGE 0 TO MAX_DEPTH - 1 := 1;

  TYPE t_stack_position IS ARRAY(0 TO MAX_EXISTING_STACKS - 1) OF INTEGER RANGE 0 TO MAX_DEPTH - 1;
  SIGNAL stack_position : t_stack_position;
  SIGNAL stack_counter : INTEGER RANGE 0 TO MAX_EXISTING_STACKS - 1 := 0;

  SIGNAL previous_begging_of_stack : INTEGER RANGE 0 TO MAX_DEPTH - 1 := 0;
BEGIN

  p_stack : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      CASE OP_CODE IS
        WHEN C_CMD_NOP =>
          NULL;
        WHEN C_CMD_PUSH =>
          IF pointing_at /= MAX_DEPTH - 1 THEN
            memory(pointing_at) <= data_in;
            pointing_at <= pointing_at + 1;
          END IF;
        WHEN C_CMD_POP =>
          IF pointing_at /= 0 THEN
            data_out <= memory(pointing_at);
            pointing_at <= pointing_at - 1;
          END IF;

        WHEN C_CMD_APPEND =>
          IF stack_counter /= 0 THEN
            memory(previous_begging_of_stack) <= data_in;
          END IF;

        WHEN C_CMD_CREATE_NEW_STACK =>
          IF stack_counter /= MAX_EXISTING_STACKS - 1 THEN
            stack_position(stack_counter) <= pointing_at;
            pointing_at <= pointing_at + 1;
            stack_counter <= stack_counter + 1;
          END IF;

        WHEN C_CMD_DESTROY_PREV_STACK =>
          IF stack_counter /= 0 THEN
            stack_counter <= stack_counter - 1;
          END IF;
        WHEN OTHERS =>
          NULL;
      END CASE;
      IF pointing_at /= 0 THEN
        previous_begging_of_stack <= stack_position(pointing_at - 1);
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;