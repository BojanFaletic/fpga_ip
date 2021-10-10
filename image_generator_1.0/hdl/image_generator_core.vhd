library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ALL;

Library xpm;
use xpm.vcomponents.all;

-- load package constants, they are generated with python gen_memory.py
use work.image_generator_pkg.all;

entity image_generator_core is
  generic(can_synthesize : boolean := False);
  port (
    clk : in std_logic
  );
end image_generator_core;


architecture Behavioral of image_generator_core is
  constant C_ROM_SIZE  : integer := C_LINE_WIDTH * C_LINE_HEIGHT * 8;

  signal rom_rd_ptr : integer;

begin


   xpm_memory_sprom_inst : xpm_memory_sprom
   generic map (
      ADDR_WIDTH_A => 32,
      AUTO_SLEEP_TIME => 0,
      ECC_MODE => "no_ecc",           -- String
      MEMORY_INIT_FILE => "none",     -- String
      MEMORY_INIT_PARAM => "0",       -- String
      MEMORY_OPTIMIZATION => "true",  -- String
      MEMORY_PRIMITIVE => "auto",     -- String
      MEMORY_SIZE => 2048,            -- DECIMAL
      MESSAGE_CONTROL => 0,           -- DECIMAL
      READ_DATA_WIDTH_A => 32,        -- DECIMAL
      READ_LATENCY_A => 2,            -- DECIMAL
      READ_RESET_VALUE_A => "0",      -- String
      USE_MEM_INIT => 1,              -- DECIMAL
      WAKEUP_TIME => "disable_sleep"  -- String
   )
   port map (
      dbiterra => dbiterra,             -- 1-bit output: Leave open.
      douta => douta,                   -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      sbiterra => sbiterra,             -- 1-bit output: Leave open.
      addra => addra,                   -- ADDR_WIDTH_A-bit input: Address for port A read operations.
      clka => clka,                     -- 1-bit input: Clock signal for port A.
      ena => ena,                       -- 1-bit input: Memory enable signal for port A. Must be high on clock
                                        -- cycles when read operations are initiated. Pipelined internally.

      injectdbiterra => injectdbiterra, -- 1-bit input: Do not change from the provided value.
      injectsbiterra => injectsbiterra, -- 1-bit input: Do not change from the provided value.
      regcea => regcea,                 -- 1-bit input: Do not change from the provided value.
      rsta => rsta,                     -- 1-bit input: Reset signal for the final port A output register
                                        -- stage. Synchronously resets output port douta to the value specified
                                        -- by parameter READ_RESET_VALUE_A.

      sleep => sleep                    -- 1-bit input: sleep signal to enable the dynamic power saving feature.
   );


end architecture Behavioral;