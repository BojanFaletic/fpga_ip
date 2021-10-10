LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY sobel_kernel IS
  GENERIC (DIN_WIDTH : INTEGER := 8);
  PORT (
    clk        : IN STD_LOGIC;
    din        : IN STD_LOGIC_VECTOR(9 * DIN_WIDTH - 1 DOWNTO 0);
    din_valid  : IN STD_LOGIC;
    dout       : OUT STD_LOGIC_VECTOR(DIN_WIDTH DOWNTO 0);
    dout_valid : OUT STD_LOGIC);
END ENTITY sobel_kernel;

ARCHITECTURE Behav OF sobel_kernel IS
  -- sobel has 8*-1
  -- division by 8
  CONSTANT EXPAND_COEFF_SIZE : INTEGER := 3;
  TYPE t_matrix IS ARRAY(0 TO 2, 0 TO 2) OF unsigned(DIN_WIDTH - 1 DOWNTO 0);

  -- format input vector to 3x3 kernel
  FUNCTION split_to_kernel(v : IN STD_LOGIC_VECTOR) RETURN t_matrix IS
    VARIABLE v_kernel : t_matrix;
    VARIABLE v_coeff : STD_LOGIC_VECTOR(DIN_WIDTH - 1 DOWNTO 0);
  BEGIN
    FOR i IN 0 TO 2 LOOP
      FOR j IN 0 TO 2 LOOP
        v_coeff := v((i * 3 + j + 1) * DIN_WIDTH - 1 DOWNTO (i * 3 + j) * DIN_WIDTH);
        v_kernel(i, j) := unsigned(v_coeff);
      END LOOP;
    END LOOP;
    RETURN v_kernel;
  END FUNCTION split_to_kernel;

  SIGNAL kernel : t_matrix;
  SIGNAL acc_8_coeff : signed(DIN_WIDTH + EXPAND_COEFF_SIZE DOWNTO 0);
  SIGNAL mult_by_8 : signed(DIN_WIDTH + EXPAND_COEFF_SIZE DOWNTO 0);

  SIGNAL final_operator : signed(DIN_WIDTH + EXPAND_COEFF_SIZE DOWNTO 0);
  SIGNAL din_valid_r : STD_LOGIC_VECTOR(1 DOWNTO 0);
BEGIN

  kernel <= split_to_kernel(din);

  p_sobel : PROCESS (clk)
    VARIABLE v_accumulate_8 : signed(DIN_WIDTH + EXPAND_COEFF_SIZE DOWNTO 0);
  BEGIN
    IF rising_edge(clk) THEN
      -- first add 8 coefficients

      v_accumulate_8 := (OTHERS => '0');
      FOR i IN 0 TO 2 LOOP
        FOR j IN 0 TO 2 LOOP
          IF (i = 1) AND (j = 1) THEN
            NEXT;
          END IF;
          v_accumulate_8 := v_accumulate_8 + signed(resize(kernel(i, j), DIN_WIDTH + EXPAND_COEFF_SIZE + 1));
        END LOOP;
      END LOOP;
      acc_8_coeff <= v_accumulate_8;

      -- multiply middle by 8
      mult_by_8 <= shift_left(signed(resize(kernel(1, 1), DIN_WIDTH + EXPAND_COEFF_SIZE+1)), EXPAND_COEFF_SIZE);

      din_valid_r(0) <= din_valid;

      -- final stage
      final_operator <= mult_by_8 - acc_8_coeff;
      din_valid_r(1) <= din_valid_r(0);
    END IF;
  END PROCESS p_sobel;

  dout <= STD_LOGIC_VECTOR(resize(final_operator, DIN_WIDTH+1));
  dout_valid <= din_valid_r(1);

END ARCHITECTURE Behav;