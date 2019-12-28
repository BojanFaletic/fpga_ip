LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-------------------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
-------------------------------------------------------------------------------

ENTITY binary_to_BCD IS
    GENERIC (
        g_INPUT_WIDTH : IN POSITIVE;
        g_DECIMAL_DIGITS : IN POSITIVE
    );
    PORT (
        i_Clock : IN std_logic;
        i_Start : IN std_logic;
        i_Binary : IN std_logic_vector(g_INPUT_WIDTH - 1 DOWNTO 0);

        o_BCD : OUT std_logic_vector(g_DECIMAL_DIGITS * 4 - 1 DOWNTO 0);
        o_DV : OUT std_logic
    );
END ENTITY binary_to_BCD;

ARCHITECTURE rtl OF binary_to_BCD IS

    TYPE t_BCD_State IS (s_IDLE, s_SHIFT, s_CHECK_SHIFT_INDEX, s_ADD,
        s_CHECK_DIGIT_INDEX, s_BCD_DONE);
    SIGNAL r_SM_Main : t_BCD_State := s_IDLE;
    SIGNAL r_BCD : std_logic_vector(g_DECIMAL_DIGITS * 4 - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL r_Binary : std_logic_vector(g_INPUT_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL r_Digit_Index : NATURAL RANGE 0 TO g_DECIMAL_DIGITS - 1 := 0;
    SIGNAL r_Loop_Count : NATURAL RANGE 0 TO g_INPUT_WIDTH - 1 := 0;

BEGIN
    Double_Dabble : PROCESS (i_Clock)
        VARIABLE v_Upper : NATURAL;
        VARIABLE v_Lower : NATURAL;
        VARIABLE v_BCD_Digit : unsigned(3 DOWNTO 0);
    BEGIN
        IF rising_edge(i_Clock) THEN
            CASE r_SM_Main IS
                WHEN s_IDLE =>
                    IF i_Start = '1' THEN
                        r_BCD <= (OTHERS => '0');
                        r_Binary <= i_Binary;
                        r_SM_Main <= s_SHIFT;
                    ELSE
                        r_SM_Main <= s_IDLE;
                    END IF;
                WHEN s_SHIFT =>
                    r_BCD <= r_BCD(r_BCD'left - 1 DOWNTO 0) & r_Binary(r_Binary'left);
                    r_Binary <= r_Binary(r_Binary'left - 1 DOWNTO 0) & '0';
                    r_SM_Main <= s_CHECK_SHIFT_INDEX;
                WHEN s_CHECK_SHIFT_INDEX =>
                    IF r_Loop_Count = g_INPUT_WIDTH - 1 THEN
                        r_Loop_Count <= 0;
                        r_SM_Main <= s_BCD_DONE;
                    ELSE
                        r_Loop_Count <= r_Loop_Count + 1;
                        r_SM_Main <= s_ADD;
                    END IF;

                WHEN s_ADD =>
                    v_Upper := r_Digit_Index * 4 + 3;
                    v_Lower := r_Digit_Index * 4;
                    v_BCD_Digit := unsigned(r_BCD(v_Upper DOWNTO v_Lower));

                    IF v_BCD_Digit > 4 THEN
                        v_BCD_Digit := v_BCD_Digit + 3;
                    END IF;

                    r_BCD(v_Upper DOWNTO v_Lower) <= std_logic_vector(v_BCD_Digit);
                    r_SM_Main <= s_CHECK_DIGIT_INDEX;
                WHEN s_CHECK_DIGIT_INDEX =>
                    IF r_Digit_Index = g_DECIMAL_DIGITS - 1 THEN
                        r_Digit_Index <= 0;
                        r_SM_Main <= s_SHIFT;
                    ELSE
                        r_Digit_Index <= r_Digit_Index + 1;
                        r_SM_Main <= s_ADD;
                    END IF;
                WHEN s_BCD_DONE =>
                    r_SM_Main <= s_IDLE;
                WHEN OTHERS =>
                    r_SM_Main <= s_IDLE;

            END CASE;
        END IF;
    END PROCESS Double_Dabble;

    o_DV <= '1' WHEN r_SM_Main = s_BCD_DONE ELSE
        '0';
    o_BCD <= r_BCD;

END ARCHITECTURE rtl;