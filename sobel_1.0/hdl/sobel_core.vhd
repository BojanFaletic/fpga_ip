LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

-- Edge mirroring is disabled to reduce LUT usage

ENTITY sobel_core IS
  GENERIC (
    C_DIN_WIDTH : INTEGER := 8;
    C_MAX_WIDTH : INTEGER := 640
  );
  PORT (
    clk, rst_n     : IN STD_LOGIC;
    data_in        : IN STD_LOGIC_VECTOR(C_DIN_WIDTH - 1 DOWNTO 0);
    data_in_valid  : IN STD_LOGIC;
    data_in_tlast  : IN STD_LOGIC;
    data_out       : OUT STD_LOGIC_VECTOR(C_DIN_WIDTH DOWNTO 0);
    data_out_valid : OUT STD_LOGIC;
    data_out_tlast : OUT STD_LOGIC;
    line_width     : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    line_height    : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END ENTITY sobel_core;

ARCHITECTURE Behavioral OF sobel_core IS
  SIGNAL l1, l2 : STD_LOGIC_VECTOR(C_DIN_WIDTH - 1 DOWNTO 0);
  SIGNAL l1_valid, l2_valid : STD_LOGIC;
  SIGNAL rst : STD_LOGIC;

  TYPE t_kernel IS ARRAY(0 TO 2, 0 TO 2) OF STD_LOGIC_VECTOR(C_DIN_WIDTH - 1 DOWNTO 0);
  SIGNAL kernel : t_kernel;

  CONSTANT C_WIDTH_BITS : INTEGER := INTEGER(log2(real(C_MAX_WIDTH))) + 1;
  SIGNAL cnt_x, cnt_y : unsigned(C_WIDTH_BITS - 1 DOWNTO 0);

  CONSTANT C_KERNEL_SIZE : INTEGER := 3;
  SIGNAL kernel_is_valid : STD_LOGIC;

  SIGNAL flatten_kernel : STD_LOGIC_VECTOR(9 * C_DIN_WIDTH - 1 DOWNTO 0);

  FUNCTION flatten(v : IN t_kernel) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v_vector : STD_LOGIC_VECTOR(9 * C_DIN_WIDTH - 1 DOWNTO 0);
  BEGIN
    FOR i IN 0 TO 2 LOOP
      FOR j IN 0 TO 2 LOOP
        v_vector((i * 3 + j + 1) * C_DIN_WIDTH - 1 DOWNTO (i * 3 + j) * C_DIN_WIDTH) := v(i, j);
      END LOOP;
    END LOOP;
    RETURN v_vector;
  END FUNCTION flatten;

  SIGNAL tlast_delay : STD_LOGIC;

BEGIN

  p_delay : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      tlast_delay <= data_in_tlast;
      data_out_tlast <= tlast_delay;
    END IF;
  END PROCESS p_delay;

  p_track_position : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rst_n = '0' THEN
        cnt_y <= (OTHERS => '0');
        cnt_x <= (OTHERS => '0');
        kernel_is_valid <= '0';
      ELSE

        -- track position
        IF data_in_valid = '1' THEN
          IF cnt_x = unsigned(line_width) - 1 THEN
            cnt_y <= cnt_y + 1;
            cnt_x <= (OTHERS => '0');
          ELSE
            cnt_x <= cnt_x + 1;
          END IF;
        END IF;
      END IF;

      -- detect valid region in image
      IF (cnt_x >= C_KERNEL_SIZE - 2 AND cnt_x <= unsigned(line_width) - (C_KERNEL_SIZE - 1)) AND
        (cnt_y >= C_KERNEL_SIZE - 1 AND cnt_y <= unsigned(line_height) - (C_KERNEL_SIZE - 2)) THEN
        kernel_is_valid <= '1';
      ELSE
        kernel_is_valid <= '0';
      END IF;

      -- assemble kernel
      kernel(0, 1) <= kernel(0, 0);
      kernel(0, 2) <= kernel(0, 1);

      kernel(1, 1) <= kernel(1, 0);
      kernel(1, 2) <= kernel(1, 1);

      kernel(2, 1) <= kernel(2, 0);
      kernel(2, 2) <= kernel(2, 1);

      -- reset at end of image
      IF data_in_tlast = '1' THEN
        cnt_x <= (OTHERS => '0');
        cnt_y <= (OTHERS => '0');
        rst <= '1';
      ELSE
        rst <= '0';
      END IF;

    END IF;
  END PROCESS p_track_position;

  -- input in kernel
  kernel(0, 0) <= l2;
  kernel(1, 0) <= l1;
  kernel(2, 0) <= data_in;

  flatten_kernel <= flatten(kernel);

  sobel_kernel : ENTITY work.sobel_kernel
    GENERIC MAP(DIN_WIDTH => C_DIN_WIDTH)
    PORT MAP(
      clk        => clk,
      din        => flatten_kernel,
      din_valid  => kernel_is_valid,
      dout       => data_out,
      dout_valid => data_out_valid);

  line_1 : ENTITY work.line_buffer
    GENERIC MAP(
      C_MAX_DEPTH => C_MAX_WIDTH,
      C_DIN_WIDTH => C_DIN_WIDTH)
    PORT MAP(
      clk        => clk,
      rst        => rst,
      din        => data_in,
      din_valid  => data_in_valid,
      dout       => l1,
      dout_valid => l1_valid,
      line_width => line_width
    );

  line_2 : ENTITY work.line_buffer
    GENERIC MAP(
      C_MAX_DEPTH => C_MAX_WIDTH,
      C_DIN_WIDTH => C_DIN_WIDTH)
    PORT MAP(
      clk        => clk,
      rst        => rst,
      din        => l1,
      din_valid  => l1_valid,
      dout       => l2,
      dout_valid => l2_valid,
      line_width => line_width
    );

END ARCHITECTURE Behavioral;