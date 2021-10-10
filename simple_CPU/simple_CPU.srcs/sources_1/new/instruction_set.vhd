LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE instruction_set IS
  -- No instruction [0][000][0x00]
  CONSTANT INST_NOP : std_logic_vector(3 DOWNTO 0) := "0000";
  -- increment value in accumulator by 1 [0][000][0x01] 
  CONSTANT INST_INC : std_logic_vector(3 DOWNTO 0) := "0001";
  -- decrement value in accumulator by 1 [0][000][0x02]
  CONSTANT INST_DEC : std_logic_vector(3 DOWNTO 0) := "0010";
  -- add value in accumulator by value in memory location [1][000][0x00]
  CONSTANT INST_ADD : std_logic_vector(3 DOWNTO 0) := "0011";
  -- subtract value in accumulator by value in memory location [1][001][0x00]
  CONSTANT INST_SUB : std_logic_vector(3 DOWNTO 0) := "0100";
  -- read from IO and store to accumulator [1][010][0x00]
  CONSTANT INST_READ : std_logic_vector(3 DOWNTO 0) := "0101";
  -- write value from accumulator to IO [1][011][0x00]
  CONSTANT INST_WRITE : std_logic_vector(3 DOWNTO 0) := "0110";
  -- perform logic AND in accumulator and memory location [1][100][0x00]
  CONSTANT INST_AND : std_logic_vector(3 DOWNTO 0) := "0111";
  -- perform logic OR in accumulator and memory location [1][101][0x00]
  CONSTANT INST_OR : std_logic_vector(3 DOWNTO 0) := "1000";
  -- perform tree way comparison between value in accumulator and memory address [1][110][0x00]
  CONSTANT INST_CMP : std_logic_vector(3 downto 0);
  -- jumps to address if accumulator is positive [0][000][0x00]
  CONSTANT INST_JMP : std_logic_vector(3 DOWNTO 0) := "1001";
  -- jumps to address if accumulator is zero
  CONSTANT INST_JMP_ZERO : std_logic_vector(3 DOWNTO 0) := "1010";
  -- jump to subroutine
  CONSTANT INST_BRANCH : std_logic_vector(3 DOWNTO 0) := "1011";
  -- return from subroutine return value will be in accumulator
  CONSTANT INST_RETURN : std_logic_vector(3 DOWNTO 0) := "1100";
  -- load value from memory in accumulator
  CONSTANT INST_LDA : std_logic_vector(3 DOWNTO 0) := "1101";
  -- store value from accumulator into memory
  CONSTANT INST_STA : std_logic_vector(3 DOWNTO 0) := "1110";
  -- jump if value in accumulator is same as value in memory 
  CONSTANT INST_CMP_EQ : std_logic_vector(3 DOWNTO 0) := "1111";

  --  12 bit = [1b USE_ADDR][3b CMD][8b ADDR]
  --

END instruction_set;