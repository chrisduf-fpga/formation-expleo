----------------------------------------------------------------------------------
-- File: tb_socora_gpio_stim.vhd
--
-- Couche de STIMULI du banc de test SoCora (Vivado 2020.2, xc7z010clg400-1).
--
-- Ce fichier produit TOUS les stimuli du banc de test. Il ne contient aucune
-- verification et aucun acces AXI : ceux-ci sont dans tb_socora_gpio.sv.
--
-- Hierarchie :
--   tb_socora_gpio (SystemVerilog, top)
--     +-- stim : tb_socora_gpio_stim (VHDL, ce fichier)  -- les stimuli
--     +-- DUT  : design_1_wrapper    (VHDL genere)       -- le design
--           +-- design_1_i : design_1 (VHDL genere)
--                 +-- processing_system7_0 -> inst  (le PS7 VIP, Verilog)
--
----------------------------------------------------------------------------------
-- POURQUOI CE FICHIER N'INSTANCIE-T-IL PAS LE DUT ?
----------------------------------------------------------------------------------
-- C'etait l'intention de depart, et c'est ce que fait la reference
-- tb_general.vhd. Mais avec un PS Zynq-7000 c'est IMPOSSIBLE sous xsim 2020.2.
-- Ne pas essayer de "reparer" : la question a ete tranchee par mesure.
--
-- Cause. Les broches PS_CLK / PS_PORB / PS_SRSTB du PS7 sont de mode `inout`
-- sur toute la hierarchie generee. Or xsim cree un PILOTE IMPLICITE sur tout
-- port `inout` traverse par une instanciation VHDL. Mesure par report_drivers :
--
--   Drivers for /tb/stim/ps_porb
--     U : Driver Implicit process at .../design_1.vhd:600      <-- xsim
--       : Driver /tb/stim/por_proc  at ...                     <-- nous
--
-- Ce pilote vaut 'U' en permanence, et dans la table de resolution std_logic
-- 'U' l'emporte sur TOUT : resolved('U','1') = 'U'. Aucun pilote VHDL
-- concurrent ne peut gagner.
--
-- Consequences, toutes observees :
--   * ps_clk reste bloque a 'U' : not('U') = 'U', l'horloge ne demarre jamais ;
--   * le VIP ne voit jamais le front descendant du POR, donc
--       always@(posedge m_axi_gp0_clk or negedge (por_rst_n & sys_rst_n))
--     ne se declenche pas et m_axi_gp0_rstn reste a X -> l'AXI ne demarre pas ;
--   * X se propage dans le compteur interne de proc_sys_reset, qui ne s'en
--     remet jamais : peripheral_aresetn reste a 0 pour toujours ;
--   * le garde-fou $finish du VIP sur PS_PORB ne se declenche PAS non plus, car
--     en Verilog (x != 1'b0) vaut x : l'echec est totalement SILENCIEUX.
--
-- Montages testes :
--   DUT instancie en SystemVerilog + assign Verilog ....... ps_porb = 1  OK
--   DUT instancie en VHDL, netlist du BD en VHDL ......... ps_porb = U  KO
--   DUT instancie en VHDL, netlist du BD en Verilog ...... ps_porb = U  KO
--   broches remontees en ports inout vers le .sv ......... ps_porb = U  KO
--   `<= force` (VHDL-2008) .............. xsim : "not supported yet" + crash
--   force/ecriture SV -> objet VHDL ..... xsim : "not supported yet"
--
-- Autrement dit, seul un net Verilog resout correctement ces broches. Le DUT
-- est donc instancie dans le .sv, et ce fichier lui fournit les formes d'onde
-- par des ports `out`.
--
-- Ce piege n'existe pas sur Zynq UltraScale+ (cf. la reference
-- base_system_design_testbench.sv) : le VIP MPSoC n'expose aucune broche
-- PS_PORB / PS_SRSTB, il n'y a donc aucun `inout` a piloter.
--
----------------------------------------------------------------------------------
-- COMMENT ETENDRE CE TEMPLATE
----------------------------------------------------------------------------------
-- Dans ce design, le seul port non-`inout` du wrapper est led_tri_o, et c'est
-- une SORTIE : il n'y a aucune entree fonctionnelle a stimuler. L'horloge de la
-- PL (FCLK_CLK0, 50 MHz) et le reset (FCLK_RESET0_N) sont generes A L'INTERIEUR
-- du VIP. Les seuls stimuli reels sont donc les trois broches PS.
--
-- Pour un design ou la PL a ses propres entrees (boutons, switches, liaison
-- serie, modeles de composants externes...) :
--   1. ajouter les ports `out` correspondants a l'entite ci-dessous ;
--   2. ajouter les process qui les pilotent ;
--   3. les cabler dans le port map du DUT, dans tb_socora_gpio.sv.
-- Le scenario de test du .sv n'a pas a etre touche.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_socora_gpio_stim is
    port (
        -- Broches PS. Valeurs initiales OBLIGATOIRES : sans elles ces ports
        -- valent 'U' a t=0, ce qui suffit a declencher le checker de protocole
        -- AXI du VIP au premier front d'horloge (~10 ns).
        ps_clk_o   : out std_logic := '0';
        ps_porb_o  : out std_logic := '1';
        ps_srstb_o : out std_logic := '1'

        -- Ajouter ici les stimuli fonctionnels du design (boutons, switches...).
    );
end tb_socora_gpio_stim;

architecture Behavioral of tb_socora_gpio_stim is

    ------------------------------------------------------------------
    -- Timing
    ------------------------------------------------------------------
    -- Horloge d'entree du PS sur la Cora Z7 : 33.333 MHz.
    constant PS_CLK_PERIOD : time := 30 ns;

    -- Instant du front descendant du POR. Doit survenir AVANT le premier front
    -- de FCLK_CLK0 (~10 ns). Sinon m_axi_gp0_rstn, qui n'est resolu qu'a ce
    -- premier front, vaut encore X et le VIP emet
    --   "ARESET_N can't be X/Z after 1 cycle of clock".
    constant POR_EDGE_TIME : time := 1 ns;

    -- Maintien du POR actif. Au moins 16 cycles de l'horloge AXI la plus lente
    -- (UG1037), soit 16 * 20 ns = 320 ns a 50 MHz. En dessous, le VIP emet
    --   "XILINX_RESET_PULSE_WIDTH: Holding AXI ARESETN asserted for 16 cycles
    --    of the slowest AXI clock is generally a sufficient reset pulse width".
    -- On prend 500 ns de marge.
    constant POR_LOW_TIME  : time := 500 ns;

    -- Copie interne de l'horloge : un port de mode `out` ne peut pas etre relu
    -- en VHDL-93, donc `ps_clk_o <= not ps_clk_o` serait illegal.
    signal ps_clk_i : std_logic := '0';

begin

    ------------------------------------------------------------------
    -- Horloge PS_CLK
    ------------------------------------------------------------------
    -- Le module gen_clock du VIP declare le port ps_clk mais ne s'en sert pas :
    -- FCLK_CLK0 est derive en interne des parametres de l'IP. On la genere quand
    -- meme pour rester fidele au systeme reel et eviter un 'U' sur la broche.
    ps_clk_i <= not ps_clk_i after PS_CLK_PERIOD / 2;
    ps_clk_o <= ps_clk_i;

    ------------------------------------------------------------------
    -- Impulsion POR
    ------------------------------------------------------------------
    -- C'est le seul stimulus fonctionnellement indispensable de ce banc.
    --
    -- Il faut une vraie impulsion 1 -> 0 -> 1, pas un simple maintien a 1 :
    -- c'est le FRONT DESCENDANT qui initialise les resets fabric du VIP :
    --     always@(negedge por_rst_n or negedge sys_rst_n)
    --         fabric_rst_n = 32'h01f3_300f;
    -- (ipshared/ee60/hdl/processing_system7_vip_v1_0_vl_rfs.sv:4779)
    --
    -- Le VIP verifie d'ailleurs explicitement que ces broches sont pilotees :
    --     if ((por_rst_n != 1'b0) && (por_rst_n != 1'b1) && ...) begin
    --        $display(" Error: ... PS_PORB and PS_SRSTB must be driven ...");
    --        $finish();
    --     end
    por_proc : process
    begin
        ps_porb_o  <= '1';
        ps_srstb_o <= '1';

        wait for POR_EDGE_TIME;
        ps_porb_o  <= '0';
        ps_srstb_o <= '0';

        wait for POR_LOW_TIME;
        ps_porb_o  <= '1';
        ps_srstb_o <= '1';

        -- Plus aucun stimulus a produire : le process s'endort definitivement.
        -- C'est ici qu'on ajouterait les stimuli applicatifs d'un design plus
        -- riche (voir "COMMENT ETENDRE CE TEMPLATE" en tete de fichier).
        wait;
    end process por_proc;

end Behavioral;
