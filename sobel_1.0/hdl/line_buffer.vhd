LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

LIBRARY xpm;
USE xpm.vcomponents.ALL;

ENTITY line_buffer IS
  GENERIC (
    C_MAX_DEPTH : INTEGER := 640;
    C_DIN_WIDTH : INTEGER := 8);
  PORT (
    clk, rst   : IN STD_LOGIC;
    din        : IN STD_LOGIC_VECTOR(C_DIN_WIDTH - 1 DOWNTO 0);
    din_valid  : IN STD_LOGIC;
    dout       : OUT STD_LOGIC_VECTOR(C_DIN_WIDTH - 1 DOWNTO 0);
    dout_valid : OUT STD_LOGIC;
    line_width : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END ENTITY line_buffer;

ARCHITECTURE Behavioral OF line_buffer IS
  CONSTANT C_FIFO_MAX_DEPTH : INTEGER := 2 ** (INTEGER(log2(real(C_MAX_DEPTH))) + 1);
  SIGNAL rd_data_count : STD_LOGIC_VECTOR(10 DOWNTO 0);
  SIGNAL rd_en : STD_LOGIC;
BEGIN

  -- async FIFO
  rd_en <= din_valid WHEN unsigned(rd_data_count) >= unsigned(line_width) ELSE
    '0';
  dout_valid <= rd_en;

  xpm_fifo_sync_inst : xpm_fifo_sync
  GENERIC MAP(
    DOUT_RESET_VALUE => "0",
    ECC_MODE => "no_ecc",
    FIFO_MEMORY_TYPE => "auto",
    FIFO_READ_LATENCY => 0,
    FIFO_WRITE_DEPTH => C_FIFO_MAX_DEPTH,
    FULL_RESET_VALUE => 0,
    PROG_EMPTY_THRESH => 10,
    PROG_FULL_THRESH => 10,
    RD_DATA_COUNT_WIDTH => 11,
    READ_DATA_WIDTH => C_DIN_WIDTH,
    READ_MODE => "std",
    USE_ADV_FEATURES => "1707",
    WAKEUP_TIME => 0,
    WRITE_DATA_WIDTH => C_DIN_WIDTH,
    WR_DATA_COUNT_WIDTH => 1
  )
  PORT MAP(
    almost_empty  => OPEN,
    almost_full   => OPEN,
    data_valid    => open,
    dbiterr       => OPEN,
    dout          => dout,
    empty         => OPEN,
    full          => OPEN,
    overflow      => OPEN,
    prog_empty    => OPEN,
    prog_full     => OPEN,
    rd_data_count => rd_data_count,
    rd_rst_busy   => OPEN,
    sbiterr       => OPEN,
    underflow     => OPEN,
    wr_ack        => OPEN,
    wr_data_count => OPEN,
    wr_rst_busy   => OPEN,
    din           => din,
    injectdbiterr => '0',
    injectsbiterr => '0',
    rd_en         => rd_en,
    rst           => rst,
    sleep         => '0',
    wr_clk        => clk,
    wr_en         => din_valid
  );
END ARCHITECTURE Behavioral;