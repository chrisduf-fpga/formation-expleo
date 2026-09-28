----------------------------------------------------------------------------------
-- File: tb_environnement.vhd
--
-- BANC DE TEST UNITAIRE AXI4-STREAM  (Vivado 2020.2 / xsim)
--
-- C'est LE fichier a editer. Il est entierement en VHDL : aucune connaissance
-- du SystemVerilog n'est necessaire, et il est lui-meme le top de simulation
-- (entite sans port).
--
-- Il met bout a bout les deux modeles de verification fournis :
--
--     sample_in_gray.txt
--            |
--            v
--     +----------------+   tvalid / tdata / tlast          +-----------------+
--     |  axi4s_driver  | --------------------------------> |  axi4s_monitor  |
--     |  (Axi4s_driver |                                   | (Axi4s_monitor  |
--     |      .vhd)     | <-------------------------------- |      .vhd)      |
--     +----------------+   tready                          +-----------------+
--                                                                   |
--                                                                   v
--                                                          stream_out_0.txt
--
-- Par defaut les deux instances sont reliees DIRECTEMENT (boucle simple) : le
-- fichier ecrit par le monitor doit donc etre la copie conforme du fichier lu
-- par le driver. C'est le point de depart : voir "INSERER VOTRE IP ICI"
-- plus bas pour intercaler votre propre module AXI4-Stream.
--
----------------------------------------------------------------------------------
-- CE BANC N'A RIEN A VOIR AVEC tb_socora_gpio.sv
----------------------------------------------------------------------------------
-- Le projet contient un SECOND banc, tb_socora_gpio.sv, qui exerce le Zynq PS7
-- et les GPIO par AXI4-Lite. Les deux bancs cohabitent dans le meme fileset
-- sim_1 mais ne partagent aucun signal, aucun fichier et aucune hierarchie :
--   * tb_socora_gpio  -> lancer avec  ./build_all.sh sim
--   * tb_environnement -> lancer avec ./build_all.sh sim-axis
-- Ici il n'y a ni Zynq, ni VIP, ni broche inout : la simulation est rapide et
-- entierement sous votre controle.
--
----------------------------------------------------------------------------------
-- ATTENTION AUX POINTS D'ARRET (bug xsim 2020.2)
----------------------------------------------------------------------------------
-- A partir de DEUX points d'arret dans un meme fichier VHDL, xsim 2020.2
-- concatene le chemin du fichier avec lui-meme et l'etape 'simulate' avorte
-- AVANT le run :
--   ERROR: [Simulator 45-7] No such file '<...>tb_environnement.vhd<...>
--          tb_environnement.vhd' in the design.
-- Vu de l'utilisateur : la simulation ne demarre pas, l'horloge parait "non
-- generee", la fenetre d'ondes reste vide, et aucun relancement ne passe.
-- Mesure : 1 point d'arret passe, 2 et 3 echouent.
--
-- Donc : un seul point d'arret a la fois dans ce fichier, ou aucun -- les
-- "report ... severity note" du process p_fin donnent deja le bilan.
--
-- Pour se debloquer quand plus rien ne demarre, dans la console Tcl de Vivado :
--   source <racine>/src/sim/select_tb.tcl
--   tb_clear_breakpoints
--
----------------------------------------------------------------------------------
-- LANCEMENT ET VERIFICATION
----------------------------------------------------------------------------------
--   ./build_all.sh sim-axis
--
-- Depuis le GUI Vivado, changer le top a la main ne suffit pas (la duree de run
-- et la vue d'ondes resteraient celles de l'autre banc). Console Tcl :
--   source <racine>/src/sim/select_tb.tcl
--   tb_axis
--   launch_simulation
--
--   diff <(head -32 src/sim/sample_in_gray.txt) src/sim/output/stream_out_0.txt
--
-- Tant que le driver et le monitor sont boucles directement, ce diff doit etre
-- VIDE (remplacer 32 par la valeur de C_IMG_HEIGHT ci-dessous). Des que vous
-- intercalez un traitement, le diff mesure ce que votre module a change.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_environnement is
    -- Top de simulation : aucun port.
end entity tb_environnement;

architecture Behavioral of tb_environnement is

    ------------------------------------------------------------------------------
    -- REGLAGES DU BANC  --  c'est ici, et nulle part ailleurs, que l'on touche.
    ------------------------------------------------------------------------------

    -- Horloge du flux AXI4-Stream. 10 ns = 100 MHz.
    -- Rien ne l'impose : le flux ne traverse aucune horloge materielle, cette
    -- valeur ne fixe que la duree simulee.
    constant C_CLK_PERIOD : time := 10 ns;

    -- Duree de maintien du reset (actif HAUT, cf. les deux modeles qui demarrent
    -- sur "wait until rising_edge(clk_i) and rst_i = '0'").
    constant C_RST_TIME : time := 10 * C_CLK_PERIOD;

    -- Largeur de TDATA. sample_in_gray.txt contient des niveaux de gris de 4 a
    -- 255 : 8 bits suffisent. Passer a 16 ou 32 si vous changez de fichier.
    constant C_DATA_WIDTH : integer := 8;

    -- Geometrie de l'image. sample_in_gray.txt fait 640 colonnes x 480 lignes.
    constant C_IMG_WIDTH : integer := 640;

    -- Nombre de lignes REELLEMENT capturees par le monitor. C'est ce compteur
    -- qui met fin a la simulation.
    --   32  -> ~205 us simules  (./build_all.sh sim-axis : ~11 s au total)
    --   480 -> image complete, ~3 ms simules            (~14 s au total)
    -- L'ecart est faible : l'essentiel du temps est la compilation et
    -- l'elaboration, pas la simulation. Passer a 480 ne coute presque rien.
    constant C_IMG_HEIGHT : integer := 32;

    -- Nombre d'images a capturer. Le driver ne relit le fichier qu'une fois
    -- (G_LOOP_COUNT => 1), donc au-dela de 1 il n'y aurait plus rien a capturer.
    constant C_NB_IMAGES : integer := 1;

    ------------------------------------------------------------------------------
    -- CHEMINS DES FICHIERS  --  RELATIFS, ne pas mettre de chemin absolu.
    ------------------------------------------------------------------------------
    -- Le repertoire de travail de xsim est
    --     <racine du projet>/SoCora/SoCora.sim/sim_1/behav/xsim
    -- soit CINQ niveaux sous la racine : d'ou les cinq "../".
    -- (Verifiable dans les .prj generes par Vivado dans ce meme repertoire, qui
    --  atteignent les sources du projet avec le meme nombre de "../".)
    --
    -- Un nom de fichier nu ("sample_in_gray.txt") serait cherche, et le resultat
    -- ecrit, dans ce repertoire de travail -- c'est-a-dire au milieu des fichiers
    -- generes par Vivado, effaces a chaque reconstruction du projet.
    constant C_IN_FILE  : string := "../../../../../src/sim/sample_in_gray.txt";

    -- Le monitor ajoute lui-meme "_<indice>.txt" : ce prefixe produit
    -- src/sim/output/stream_out_0.txt
    constant C_OUT_BASE : string := "../../../../../src/sim/output/stream_out";

    ------------------------------------------------------------------------------
    -- Garde-fou : duree maximale de la simulation.
    ------------------------------------------------------------------------------
    -- Large marge sur la duree attendue (C_IMG_WIDTH * C_IMG_HEIGHT cycles).
    -- Sans cela, une erreur de cablage laisserait la simulation tourner a vide
    -- jusqu'a la fin du run sans le moindre message.
    constant C_TIMEOUT : time :=
        4 * C_IMG_WIDTH * C_IMG_HEIGHT * C_CLK_PERIOD + C_RST_TIME + 1 us;

    ------------------------------------------------------------------------------
    -- Horloge et reset
    ------------------------------------------------------------------------------
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';   -- actif HAUT

    -- Passe a false pour arreter la simulation : voir p_clk / p_fin plus bas.
    signal sim_running : boolean := true;

    ------------------------------------------------------------------------------
    -- Le lien AXI4-Stream entre le driver et le monitor
    ------------------------------------------------------------------------------
    signal axis_tvalid : std_logic;
    signal axis_tdata  : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal axis_tlast  : std_logic;
    signal axis_tready : std_logic;

    ------------------------------------------------------------------------------
    -- Observation (visibles dans le chronogramme, utilises par le bilan)
    ------------------------------------------------------------------------------
    signal drv_done      : std_logic;
    signal drv_frame_cnt : integer;
    signal drv_pixel_cnt : integer;

    signal mon_done      : std_logic;
    signal mon_img_cnt   : integer;
    signal mon_line_cnt  : integer;
    signal mon_pixel_cnt : integer;

    ------------------------------------------------------------------------------
    -- Declaration des deux modeles de verification
    ------------------------------------------------------------------------------
    -- Ces deux entites sont fournies, elles ne sont PAS a modifier :
    --   src/sim/Axi4s_driver.vhd   et   src/sim/Axi4s_monitor.vhd
    ------------------------------------------------------------------------------
    component axi4s_driver is
        generic (
            G_FILE_PATH         : string;
            G_DATA_WIDTH        : integer;
            G_INIT_DELAY        : integer;
            G_TLAST_END_OF_LINE : boolean;
            G_LOOP_COUNT        : integer
        );
        port (
            clk_i       : in  std_logic;
            rst_i       : in  std_logic;
            m_tvalid    : out std_logic;
            m_tdata     : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
            m_tlast     : out std_logic;
            m_tready    : in  std_logic;
            done_o      : out std_logic;
            frame_cnt_o : out integer;
            pixel_cnt_o : out integer
        );
    end component axi4s_driver;

    component axi4s_monitor is
        generic (
            G_FILE_BASENAME : string;
            G_DATA_WIDTH    : integer;
            G_IMG_WIDTH     : integer;
            G_IMG_HEIGHT    : integer;
            G_NB_IMAGES     : integer;
            G_TIMEOUT_CY    : integer;
            G_SYNC_ON_SOF   : boolean
        );
        port (
            clk_i       : in  std_logic;
            rst_i       : in  std_logic;
            s_tvalid    : in  std_logic;
            s_tdata     : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
            s_tlast     : in  std_logic;
            s_tuser     : in  std_logic;
            s_tready    : out std_logic;
            done_o      : out std_logic;
            img_cnt_o   : out integer;
            line_cnt_o  : out integer;
            pixel_cnt_o : out integer
        );
    end component axi4s_monitor;

begin

    ------------------------------------------------------------------------------
    -- Horloge
    ------------------------------------------------------------------------------
    -- Ecrite en boucle explicite, et NON en "clk <= not clk after C_CLK_PERIOD/2".
    -- La difference compte : cette forme permet d'ARRETER l'horloge. Quand
    -- sim_running retombe, plus aucun front n'est programme, tous les process
    -- restent bloques sur leur "wait until rising_edge(clk)", la file
    -- d'evenements se vide et xsim rend la main immediatement -- sans recourir a
    -- un "assert ... severity failure" (qui afficherait une erreur alors que tout
    -- s'est bien passe) ni a std.env.stop (VHDL-2008, non active sur ce projet).
    p_clk : process
    begin
        while sim_running loop
            clk <= '0';
            wait for C_CLK_PERIOD / 2;
            clk <= '1';
            wait for C_CLK_PERIOD / 2;
        end loop;
        wait;
    end process p_clk;

    ------------------------------------------------------------------------------
    -- Reset (actif HAUT)
    ------------------------------------------------------------------------------
    p_rst : process
    begin
        rst <= '1';
        wait for C_RST_TIME;
        rst <= '0';
        wait;
    end process p_rst;

    ------------------------------------------------------------------------------
    -- Source du flux : lecture de sample_in_gray.txt
    ------------------------------------------------------------------------------
    -- Format attendu (celui d'un export ImageJ) : valeurs decimales separees par
    -- des tabulations, une ligne d'image par ligne de fichier, pas d'en-tete.
    -- TLAST est produit automatiquement sur le dernier pixel de chaque ligne.
    u_driver : axi4s_driver
        generic map (
            G_FILE_PATH         => C_IN_FILE,
            G_DATA_WIDTH        => C_DATA_WIDTH,
            G_INIT_DELAY        => 10,     -- cycles d'attente apres le reset
            G_TLAST_END_OF_LINE => true,
            G_LOOP_COUNT        => 1       -- 1 seule lecture du fichier (0 = infini)
        )
        port map (
            clk_i       => clk,
            rst_i       => rst,

            -- ---- sortie AXI4-Stream du driver ----
            m_tvalid    => axis_tvalid,
            m_tdata     => axis_tdata,
            m_tlast     => axis_tlast,
            m_tready    => axis_tready,

            done_o      => drv_done,
            frame_cnt_o => drv_frame_cnt,
            pixel_cnt_o => drv_pixel_cnt
        );

    --============================================================================
    -- INSERER VOTRE IP ICI
    --============================================================================
    -- Pour l'instant les quatre signaux axis_* vont directement du driver au
    -- monitor : c'est la "boucle simple". Pour tester votre propre module :
    --
    --   1. declarer un second jeu de signaux, par exemple :
    --        signal out_tvalid : std_logic;
    --        signal out_tdata  : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    --        signal out_tlast  : std_logic;
    --        signal out_tready : std_logic;
    --
    --   2. instancier votre module entre les deux :
    --        u_dut : mon_module
    --            port map (
    --                clk       => clk,
    --                rst       => rst,
    --                s_tvalid  => axis_tvalid,   -- entree  <- driver
    --                s_tdata   => axis_tdata,
    --                s_tlast   => axis_tlast,
    --                s_tready  => axis_tready,
    --                m_tvalid  => out_tvalid,    -- sortie  -> monitor
    --                m_tdata   => out_tdata,
    --                m_tlast   => out_tlast,
    --                m_tready  => out_tready
    --            );
    --
    --   3. dans le port map du monitor ci-dessous, remplacer les quatre axis_*
    --      par les out_* correspondants.
    --
    --   4. ajouter le fichier source de votre module au fileset sim_1 (le plus
    --      simple : l'ajouter a la liste en tete de src/sim/add_sim.tcl).
    --
    -- Attention au sens de TREADY : il remonte du monitor vers le driver, c'est
    -- le seul signal qui circule a contre-courant.
    --============================================================================

    ------------------------------------------------------------------------------
    -- Puits du flux : ecriture de stream_out_0.txt
    ------------------------------------------------------------------------------
    -- Le monitor maintient TREADY a '1' en permanence : il ne modelise aucune
    -- contre-pression. Il decoupe les lignes par comptage (G_IMG_WIDTH) et arrete
    -- la capture apres G_IMG_HEIGHT lignes, ce qui met fin a la simulation.
    u_monitor : axi4s_monitor
        generic map (
            G_FILE_BASENAME => C_OUT_BASE,
            G_DATA_WIDTH    => C_DATA_WIDTH,
            G_IMG_WIDTH     => C_IMG_WIDTH,    -- 0 => decoupage sur TLAST
            G_IMG_HEIGHT    => C_IMG_HEIGHT,
            G_NB_IMAGES     => C_NB_IMAGES,
            G_TIMEOUT_CY    => 1000,           -- cycles sans transaction tolerees
            G_SYNC_ON_SOF   => false           -- le driver n'emet pas de TUSER/SOF
        )
        port map (
            clk_i       => clk,
            rst_i       => rst,

            -- ---- entree AXI4-Stream du monitor ----
            s_tvalid    => axis_tvalid,
            s_tdata     => axis_tdata,
            s_tlast     => axis_tlast,
            s_tuser     => '0',            -- pas de SOF dans ce banc
            s_tready    => axis_tready,

            done_o      => mon_done,
            img_cnt_o   => mon_img_cnt,
            line_cnt_o  => mon_line_cnt,
            pixel_cnt_o => mon_pixel_cnt
        );

    ------------------------------------------------------------------------------
    -- Fin de simulation, bilan et garde-fou
    ------------------------------------------------------------------------------
    -- Le driver, lui, continuerait a derouler les 480 lignes du fichier : c'est
    -- bien le monitor qui donne le signal de fin, une fois ses C_IMG_HEIGHT
    -- lignes ecrites et le fichier referme.
    --
    -- Un seul process pilote sim_running : "boolean" est un type NON RESOLU, il
    -- n'admet donc qu'une seule source. C'est pour cela que le garde-fou de duree
    -- est ici, sous la forme du "for C_TIMEOUT" de l'attente, et non dans un
    -- process separe.
    p_fin : process
        constant C_PIXELS_ATTENDUS : integer := C_IMG_WIDTH * C_IMG_HEIGHT;
    begin
        -- Attente de la fin de capture, bornee dans le temps.
        wait until mon_done = '1' for C_TIMEOUT;

        if mon_done /= '1' then

            ----------------------------------------------------------------------
            -- Garde-fou : le monitor n'a jamais termine sa capture.
            ----------------------------------------------------------------------
            -- Sans cette borne, un flux mal cable ou un chemin de fichier faux
            -- laisserait la simulation tourner a vide jusqu'a la fin du run, sans
            -- le moindre message.
            report LF
                & "==============================================================" & LF
                & " tb_environnement : TIMEOUT" & LF
                & "   Le monitor n'a pas termine sa capture." & LF
                & "   lignes capturees : " & integer'image(mon_line_cnt)
                    & " / " & integer'image(C_IMG_HEIGHT) & LF
                & "   pixels captures  : " & integer'image(mon_pixel_cnt) & LF
                & "   pixels emis      : " & integer'image(drv_pixel_cnt) & LF
                & " Pistes : chemin de " & C_IN_FILE & " incorrect" & LF
                & "          (le repertoire de travail de xsim est"     & LF
                & "           SoCora/SoCora.sim/sim_1/behav/xsim),"     & LF
                & "          repertoire src/sim/output absent,"         & LF
                & "          ou flux AXI4-Stream mal cable."            & LF
                & "=============================================================="
                severity error;

        else

            ----------------------------------------------------------------------
            -- Bilan
            ----------------------------------------------------------------------
            -- Quelques cycles de marge pour laisser les compteurs se stabiliser.
            wait for 20 * C_CLK_PERIOD;

            report LF
                & "==============================================================" & LF
                & " tb_environnement -- banc unitaire AXI4-Stream" & LF
                & "   images capturees : " & integer'image(C_NB_IMAGES) & LF
                & "   lignes capturees : " & integer'image(mon_line_cnt)
                    & " (attendu " & integer'image(C_IMG_HEIGHT) & ")" & LF
                & "   pixels captures  : " & integer'image(mon_pixel_cnt)
                    & " (attendu " & integer'image(C_PIXELS_ATTENDUS) & ")" & LF
                & "   pixels emis      : " & integer'image(drv_pixel_cnt) & LF
                & "   fichier ecrit    : " & C_OUT_BASE & "_0.txt" & LF
                & " Verification (le diff doit etre VIDE en boucle simple) :" & LF
                & "   diff <(head -" & integer'image(C_IMG_HEIGHT)
                    & " src/sim/sample_in_gray.txt) src/sim/output/stream_out_0.txt" & LF
                & "=============================================================="
                severity note;

            assert mon_pixel_cnt = C_PIXELS_ATTENDUS
                report "tb_environnement : " & integer'image(mon_pixel_cnt)
                     & " pixels captures au lieu de "
                     & integer'image(C_PIXELS_ATTENDUS)
                     & " -- capture incomplete (timeout interne du monitor ?)."
                severity error;

            assert mon_line_cnt = C_IMG_HEIGHT
                report "tb_environnement : " & integer'image(mon_line_cnt)
                     & " lignes capturees au lieu de "
                     & integer'image(C_IMG_HEIGHT) & "."
                severity error;

        end if;

        -- Arret propre : l'horloge s'eteint, la simulation se termine.
        sim_running <= true;
        wait;
    end process p_fin;

end architecture Behavioral;
