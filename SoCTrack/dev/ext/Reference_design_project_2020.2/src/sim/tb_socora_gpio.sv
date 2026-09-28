//==============================================================================
// File: tb_socora_gpio.sv
//
// Top de simulation du projet SoCora (Vivado 2020.2, xc7z010clg400-1).
//
// Objet : emettre des transactions AXI4-Lite vers le bloc axi_gpio_0 via l'API
//         du Zynq-7000 PS7 VIP, et verifier que les ecritures se propagent
//         jusqu'aux sorties led_tri_o[2:0].
//
// Chemin AXI exerce :
//   VIP M_AXI_GP0 -> ps7_0_axi_periph (+ auto_pc AXI3->AXI4-Lite)
//                 -> axi_gpio_0/S_AXI -> gpio_io_o -> led_tri_o[2:0]
//
//------------------------------------------------------------------------------
// ORGANISATION EN DEUX COUCHES
//------------------------------------------------------------------------------
// Structure inspiree de base_system_design_testbench.sv / tb_general.vhd.
//
//   tb_socora_gpio (ce fichier, SystemVerilog, top)
//     +-- stim : tb_socora_gpio_stim (VHDL)   -- TOUS les stimuli
//     +-- DUT  : design_1_wrapper (VHDL genere par Vivado)
//           +-- design_1_i : design_1 (VHDL genere)
//                 +-- processing_system7_0 -> inst  (le PS7 VIP, Verilog)
//
// Repartition :
//   * tb_socora_gpio_stim.vhd : produit TOUTES les formes d'onde de stimuli
//                               (horloge PS_CLK, impulsion POR). Aucune
//                               verification, aucun acces AXI.
//   * ce fichier              : raccorde ces formes d'onde au DUT, puis emet
//                               les transactions AXI4-Lite et les verifie.
//
// Pour ajouter des stimuli (boutons, switches, modeles externes...) : ajouter
// un port `out` au .vhd, le process qui le pilote, et le cabler dans le port
// map du DUT ci-dessous. Le scenario de test n'a pas a etre touche.
//
// POURQUOI LE DUT EST-IL INSTANCIE ICI ET NON DANS LE .vhd ?
// C'etait l'intention de depart, et c'est ce que fait tb_general.vhd. Mais avec
// un PS Zynq-7000 c'est impossible sous xsim 2020.2 : les broches inout
// PS_CLK / PS_PORB / PS_SRSTB recoivent un pilote implicite 'U' des qu'elles
// sont traversees par une instanciation VHDL, et 'U' gagne dans la resolution
// std_logic. Le pave detaille, avec les mesures et les six montages testes, est
// en tete de tb_socora_gpio_stim.vhd. Consequence pratique : le raccordement
// des broches doit se faire par un `assign` Verilog, donc ici.
// (Ce piege n'existe pas sur Zynq UltraScale+ : le VIP MPSoC n'a pas ces broches.)
//
//------------------------------------------------------------------------------
// PRE-REQUIS : modele de simulation du PS
//------------------------------------------------------------------------------
// Aucune modification du block design n'est necessaire. Pour processing_system7
// en 2020.2, le modele de simulation "rtl" (valeur par defaut) EST deja le VIP.
// Verification depuis la console Tcl de Vivado :
//   get_property SELECTED_SIM_MODEL [get_bd_cells /processing_system7_0]
// Valeur attendue : "rtl" (ou vide). NE PAS basculer sur "tlm" : c'est le modele
// QEMU/DPI-C, qui n'expose PAS write_data/read_data -> erreur d'elaboration.
//
//------------------------------------------------------------------------------
// CASSE DES IDENTIFIANTS
//------------------------------------------------------------------------------
// Les references hierarchiques ci-dessous traversent deux niveaux VHDL. xsim
// normalise les identifiants VHDL en MINUSCULES alors que Verilog est sensible
// a la casse : l'etiquette "design_1_i" doit donc etre ecrite en minuscules.
// Les noms de SIGNAUX internes du BD gardent en revanche leur casse d'origine,
// d'ou processing_system7_0_FCLK_CLK0 en majuscules.
//
// ATTENTION xsim 2020.2 : ces references sont non seulement en LECTURE SEULE,
// mais elles ne declenchent PAS d'evenement cote SystemVerilog (cf. la note
// sur CLK_PERIOD plus bas). Toute synchronisation passe par le temps.
// Les references hierarchiques SV -> VHDL sont en LECTURE SEULE : xsim 2020.2
// refuse toute ecriture ("Write operation on Cross Language Hierarchical name
// is not supported yet"). C'est pour cela que les stimuli passent par des ports
// et non par des force.
//==============================================================================

`timescale 1ns / 1ps

// Handle du VIP PS7. Si le BD, le wrapper ou l'instance du PS sont renommes,
// c'est le SEUL endroit a modifier.
`define PS7      tb_socora_gpio.DUT.design_1_i.processing_system7_0.inst

// Sortie observee et nets internes du BD, utiles a la synchronisation.
`define LED      led
`define FCLK0    tb_socora_gpio.DUT.design_1_i.processing_system7_0_FCLK_CLK0
`define ARESETN  tb_socora_gpio.DUT.design_1_i.rst_ps7_0_50M_peripheral_aresetn

//------------------------------------------------------------------------------
// Carte memoire
//------------------------------------------------------------------------------
// Segment SEG_axi_gpio_0_Reg, offset 0x4120_0000, range 64K.
`define BAR_GPIO       32'h4120_0000
`define GPIO_DATA      32'h0000_0000   // registre de donnees
`define GPIO_TRI       32'h0000_0004   // registre de direction

module tb_socora_gpio;

  //----------------------------------------------------------------------------
  // Configuration du GPIO
  //----------------------------------------------------------------------------
  // design_1_axi_gpio_0_0 : C_GPIO_WIDTH = 3, C_ALL_OUTPUTS = 1, C_IS_DUAL = 0,
  //                         C_INTERRUPT_PRESENT = 0, C_DOUT_DEFAULT = 0x00000000
  localparam int        GPIO_WIDTH = 3;
  localparam bit [31:0] GPIO_MASK  = (32'h1 << GPIO_WIDTH) - 1;   // 0x0000_0007

  // Reponses AXI
  localparam bit [1:0] RESP_OKAY   = 2'b00;
  localparam bit [1:0] RESP_EXOKAY = 2'b01;
  localparam bit [1:0] RESP_SLVERR = 2'b10;
  localparam bit [1:0] RESP_DECERR = 2'b11;

  // Taille des acces, EN OCTETS (et non en beats). Toujours 4 pour de l'AXI4-Lite
  // 32 bits. Le VIP accepte jusqu'a max_transfer_bytes = 256.
  localparam int AXI_BYTES = 4;

  // Duree d'assertion des resets fabric. Au moins 16 cycles de FCLK_CLK0
  // (16 * 20 ns = 320 ns) pour satisfaire le checker XILINX_RESET_PULSE_WIDTH
  // du VIP. On prend 500 ns de marge.
  localparam time RESET_TIME  = 500ns;

  localparam time SIM_TIMEOUT = 500us;

  // Periode de FCLK_CLK0 (PCW_FPGA0_PERIPHERAL_FREQMHZ = 50 -> 20 ns).
  //
  // PORTAGE 2022.2 -> 2020.2 : sous xsim 2020.2, une reference hierarchique
  // SystemVerilog vers un signal VHDL est lisible mais N'EST PAS sensible aux
  // evenements : "wait (`ARESETN === 1'b1)" et "@(posedge `FCLK0)" ne se
  // reveillent jamais, meme quand le signal change reellement (verifie : a
  // 5 us peripheral_aresetn vaut bien 1 alors que le wait est toujours
  // bloque). xsim 2022.2 acceptait ces constructions.
  // On remplace donc la synchronisation par evenement par une temporisation
  // sur la periode connue de l'horloge, et l'attente du reset par un sondage
  // periodique de la valeur. Le sequencement AXI reste porte par le VIP, qui
  // gere lui-meme ses handshakes : ces attentes ne servent qu'a laisser les
  // sorties se stabiliser.
  localparam time CLK_PERIOD  = 20ns;

  // Garde-fou du sondage de reset (proc_sys_reset relache peripheral_aresetn
  // environ 2 us apres la deassertion de FCLK_RESET0_N).
  localparam int  ARESETN_POLL_MAX = 5000;

  int error_count = 0;
  int check_count = 0;

  //----------------------------------------------------------------------------
  // Couche de stimuli VHDL
  //----------------------------------------------------------------------------
  // Elle produit les formes d'onde ; ce fichier se contente de les raccorder au
  // DUT. Voir "ORGANISATION EN DEUX COUCHES" en tete de fichier pour la raison
  // pour laquelle le DUT est instancie ici et non dans le .vhd.
  wire ps_clk_w, ps_porb_w, ps_srstb_w;

  tb_socora_gpio_stim stim (
    .ps_clk_o   (ps_clk_w),
    .ps_porb_o  (ps_porb_w),
    .ps_srstb_o (ps_srstb_w)
  );

  // Le raccordement DOIT passer par un `assign` Verilog : c'est la seule facon
  // de piloter les broches inout du PS7 (cf. le pave dans le .vhd).
  wire ps_clk, ps_porb, ps_srstb;
  assign ps_clk   = ps_clk_w;
  assign ps_porb  = ps_porb_w;
  assign ps_srstb = ps_srstb_w;

  //----------------------------------------------------------------------------
  // DUT
  //----------------------------------------------------------------------------
  // Les ports DDR_* et FIXED_IO_mio / _ddr_vrn / _ddr_vrp ne sont pas utilises
  // par le VIP (pas de modele DDR fonctionnel) : laisses non connectes.
  wire [2:0] led;

  design_1_wrapper DUT (
    .FIXED_IO_ps_clk   (ps_clk),
    .FIXED_IO_ps_porb  (ps_porb),
    .FIXED_IO_ps_srstb (ps_srstb),
    .led_tri_o         (led)
  );

  //----------------------------------------------------------------------------
  // Utilitaires
  //----------------------------------------------------------------------------
  function automatic string resp2str(input bit [1:0] r);
    case (r)
      RESP_OKAY   : return "OKAY";
      RESP_EXOKAY : return "EXOKAY";
      RESP_SLVERR : return "SLVERR";
      RESP_DECERR : return "DECERR";
      default     : return "????";
    endcase
  endfunction

  task automatic pass(input string msg);
    check_count++;
    $display("[%0t] PASS : %0s", $time, msg);
  endtask

  task automatic fail(input string msg);
    check_count++;
    error_count++;
    $display("[%0t] FAIL : %0s", $time, msg);
  endtask

  //----------------------------------------------------------------------------
  // Reset du VIP
  //----------------------------------------------------------------------------
  // API disponible (verifiee dans processing_system7_vip_v1_0_10_apis.v) :
  //   set_debug_level_info, set_stop_on_error, fpga_soft_reset,
  //   write_data, read_data, write_mem, read_mem, pre_load_mem_from_file,
  //   write_from_file, read_to_file, wait_mem_update, read_interrupt, ...
  //
  // ATTENTION : la tache por_srstb_reset() vue dans beaucoup d'exemples est
  // COMMENTEE dans cette version du VIP (v1_0_10, vl_rfs.sv:4771 et apis.v:193).
  // L'appeler provoque une erreur d'elaboration.
  //
  // Semantique de fpga_soft_reset(reset_ctrl) : chaque bit a 1 ASSERTE le reset
  // correspondant (les sorties fclk_resetN_n sont actives basses).
  //   bit  0..3  -> FCLK_RESET0_N .. FCLK_RESET3_N
  //   bit 12/13  -> reset des interfaces M_AXI_GP0 / GP1
  //   bit 16/17  -> S_AXI_GP0 / GP1    bits 20..23 -> S_AXI_HP0..3   bit 24 -> ACP
  //
  // On asserte FCLK_RESET0_N (bit 0, il alimente rst_ps7_0_50M) ET le reset de
  // M_AXI_GP0 (bit 12). Le bit 12 est indispensable ici : sans lui, m_axi_gp0_rstn
  // n'est ecrit que par le front descendant du POR -- inoperant sous xsim (cf.
  // "PIEGE PS7 N.2") -- et resterait a X, ce qui declenche
  //   "ARESET_N can't be X/Z after 1 cycle of clock".
  //
  // L'appel doit avoir lieu a t=0, AVANT le premier front de FCLK_CLK0 (~10 ns),
  // faute de quoi X se propage dans le compteur interne de proc_sys_reset, qui
  // ne s'en remet jamais : peripheral_aresetn reste bloque a 0 pour toujours.
  //----------------------------------------------------------------------------
  // Temporisation en cycles de FCLK_CLK0
  //----------------------------------------------------------------------------
  // Remplace "repeat (n) @(posedge `FCLK0)" : voir la note CLK_PERIOD ci-dessus.
  task automatic wait_fclk(input int n);
    #(n * CLK_PERIOD);
  endtask

  task automatic ps7_reset();
    // Verbosite du VIP : 0 = silencieux, 1 = trace chaque transaction.
    `PS7.set_debug_level_info(0);
    // Arret immediat sur erreur interne du VIP (adresse hors plage maitre,
    // taille > 256 octets, adresse non alignee...).
    `PS7.set_stop_on_error(1);

    $display("[%0t] INFO : assertion de FCLK_RESET0_N", $time);
    `PS7.fpga_soft_reset(32'h0000_0001);
    #(RESET_TIME);
    `PS7.fpga_soft_reset(32'h0000_0000);

    // Laisser rst_ps7_0_50M (proc_sys_reset) relacher peripheral_aresetn.
    // Emettre une transaction avant cela bloque le VIP en attente d'AWREADY.
    begin : attente_aresetn
      int poll = 0;
      while (`ARESETN !== 1'b1 && poll < ARESETN_POLL_MAX) begin
        #(CLK_PERIOD);
        poll++;
      end
      if (`ARESETN !== 1'b1)
        fail($sformatf("peripheral_aresetn toujours a %0b apres %0t",
                       `ARESETN, poll * CLK_PERIOD));
    end
    wait_fclk(10);
    $display("[%0t] INFO : reset termine, peripheral_aresetn = 1", $time);
  endtask

  //----------------------------------------------------------------------------
  // Acces AXI4-Lite via le VIP
  //----------------------------------------------------------------------------
  // Signatures reelles (processing_system7_vip_v1_0_10_apis.v) :
  //   task automatic write_data;
  //     input  [31:0]   start_addr;
  //     input  [8:0]    wr_size;     // en OCTETS, <= 256
  //     input  [2047:0] w_data;      // max_transfer_bytes * 8
  //     output [1:0]    response;
  //   task automatic read_data;
  //     input  [31:0]   start_addr;
  //     input  [8:0]    rd_size;
  //     output [2047:0] rd_data;
  //     output [1:0]    response;
  //
  // -> la variable qui recoit rd_data DOIT etre large (bit [2047:0]).
  // -> l'adresse doit etre alignee sur 4 octets et appartenir a la plage du
  //    maitre (M_AXI_GP0 : 0x4000_0000 - 0x7FFF_FFFF), sinon le VIP affiche
  //    "Master Address ... is out of range" et n'emet rien.

  task automatic axi4l_write(input bit [31:0] addr, input bit [31:0] data);
    bit [2047:0] wdata;
    bit [1:0]    resp;
    begin
      wdata = {2016'b0, data};
      `PS7.write_data(addr, AXI_BYTES, wdata, resp);
      if (resp !== RESP_OKAY)
        fail($sformatf("WRITE @0x%08h = 0x%08h -> reponse %0s",
                       addr, data, resp2str(resp)));
      else
        $display("[%0t] INFO : WRITE @0x%08h = 0x%08h (OKAY)", $time, addr, data);
    end
  endtask

  task automatic axi4l_read(input bit [31:0] addr, output bit [31:0] data);
    bit [2047:0] rdata;
    bit [1:0]    resp;
    begin
      `PS7.read_data(addr, AXI_BYTES, rdata, resp);
      data = rdata[31:0];
      if (resp !== RESP_OKAY)
        fail($sformatf("READ  @0x%08h -> reponse %0s", addr, resp2str(resp)));
      else
        $display("[%0t] INFO : READ  @0x%08h = 0x%08h (OKAY)", $time, addr, data);
    end
  endtask

  //----------------------------------------------------------------------------
  // Verifications
  //----------------------------------------------------------------------------
  // Relecture d'un registre, comparee sous masque.
  task automatic check_reg(input bit [31:0] addr,
                           input bit [31:0] expected,
                           input bit [31:0] mask,
                           input string     ctx);
    bit [31:0] rd;
    begin
      axi4l_read(addr, rd);
      if ((rd & mask) !== (expected & mask))
        fail($sformatf("%0s : @0x%08h lu 0x%08h, attendu 0x%08h (masque 0x%08h)",
                       ctx, addr, rd, expected, mask));
      else
        pass($sformatf("%0s : @0x%08h = 0x%08h", ctx, addr, rd & mask));
    end
  endtask

  // Observation directe de la sortie du wrapper, lue dans la couche VHDL : c'est
  // le vrai critere, il ne depend pas du chemin de relecture AXI.
  task automatic check_led(input bit [2:0] expected, input string ctx);
    begin
      if (`LED !== expected)
        fail($sformatf("%0s : led_tri_o = 3'b%03b, attendu 3'b%03b",
                       ctx, `LED, expected));
      else
        pass($sformatf("%0s : led_tri_o = 3'b%03b", ctx, `LED));
    end
  endtask

  // Ecriture de GPIO_DATA + double verification (sortie physique et relecture).
  task automatic write_and_check(input bit [31:0] data);
    begin
      axi4l_write(`BAR_GPIO + `GPIO_DATA, data);
      // gpio_Data_Out est registre : laisser quelques cycles FCLK_CLK0 apres
      // l'acquittement BVALID avant d'echantillonner.
      wait_fclk(5);
      check_led(data[GPIO_WIDTH-1:0], $sformatf("ecriture 0x%08h", data));
      // En mode C_ALL_OUTPUTS = 1, la lecture de GPIO_DATA renvoie la valeur du
      // registre de sortie (generate ALLOUT0_ND_G1 dans axi_gpio_v2_0_vh_rfs.vhd) :
      // la relecture est donc un critere valide.
      check_reg(`BAR_GPIO + `GPIO_DATA, data, GPIO_MASK,
                $sformatf("relecture 0x%08h", data));
    end
  endtask

  //----------------------------------------------------------------------------
  // Scenario de test
  //----------------------------------------------------------------------------
  initial begin : main
    bit [31:0] rd;

    $display("==============================================================");
    $display(" tb_socora_gpio - acces AXI4-Lite au GPIO via le Zynq PS7 VIP");
    $display(" BAR_GPIO = 0x%08h  GPIO_WIDTH = %0d", `BAR_GPIO, GPIO_WIDTH);
    $display("==============================================================");

    //-- 1. Reset ------------------------------------------------------------
    ps7_reset();

    //-- 2. Valeur de reset --------------------------------------------------
    // C_DOUT_DEFAULT = 0x00000000
    check_led(3'b000, "valeur de reset");
    check_reg(`BAR_GPIO + `GPIO_DATA, 32'h0000_0000, GPIO_MASK,
              "GPIO_DATA au reset");

    //-- 3. Registre GPIO_TRI ------------------------------------------------
    // Exemple d'acces a un second offset du meme peripherique.
    // NOTE : avec C_ALL_OUTPUTS = 1 le registre de direction n'est PAS
    // implemente (PG144, et generate ALLOUT0_ND_G1 : reg2 <= (others => '1')).
    // L'ecriture est acquittee OKAY mais sans effet, et la relecture renvoie
    // tous les bits a 1. Ce n'est donc volontairement PAS un critere PASS/FAIL.
    axi4l_write(`BAR_GPIO + `GPIO_TRI, 32'h0000_0000);
    wait_fclk(5);
    axi4l_read(`BAR_GPIO + `GPIO_TRI, rd);
    $display("[%0t] INFO : GPIO_TRI relu = 0x%08h (non implemente en mode all-outputs, informatif)",
             $time, rd);

    //-- 4. Marche d'un 1 ----------------------------------------------------
    $display("\n--- Marche d'un 1 ---");
    for (int i = 0; i < GPIO_WIDTH; i++)
      write_and_check(32'h1 << i);

    //-- 5. Balayage exhaustif des 2^GPIO_WIDTH combinaisons -----------------
    $display("\n--- Balayage exhaustif ---");
    for (int v = 0; v < (1 << GPIO_WIDTH); v++)
      write_and_check(v[31:0]);

    //-- 6. Motifs ponctuels -------------------------------------------------
    $display("\n--- Motifs ponctuels ---");
    write_and_check(32'h0000_0005);   // rouge + bleu
    write_and_check(32'h0000_0002);   // vert
    write_and_check(32'h0000_0007);   // blanc
    write_and_check(32'h0000_0000);   // eteint

    //-- 7. Bits au-dela de C_GPIO_WIDTH -------------------------------------
    $display("\n--- Bits hors largeur ---");
    axi4l_write(`BAR_GPIO + `GPIO_DATA, 32'hFFFF_FFF8);
    wait_fclk(5);
    check_led(3'b000, "bits >= GPIO_WIDTH ignores");

    //-- 8. Optionnel : acces hors plage -> DECERR ---------------------------
    // Decommenter pour verifier le decodage d'adresse de l'interconnect.
    // Le segment fait 64K (0x4120_0000 - 0x4120_FFFF), 0x4121_0000 est hors
    // plage. A garder commente par defaut : selon la configuration de
    // l'interconnect, un acces non mappe peut ne jamais retourner de reponse
    // et faire expirer le watchdog. Penser aussi a set_stop_on_error(0) avant,
    // sinon le VIP fait $stop.
    //
    // begin
    //   bit [2047:0] rdata;
    //   bit [1:0]    resp;
    //   `PS7.set_stop_on_error(0);
    //   `PS7.read_data(32'h4121_0000, AXI_BYTES, rdata, resp);
    //   if (resp === RESP_DECERR) pass("acces hors plage -> DECERR");
    //   else fail($sformatf("acces hors plage -> %0s, attendu DECERR", resp2str(resp)));
    //   `PS7.set_stop_on_error(1);
    // end

    //-- Bilan ---------------------------------------------------------------
    wait_fclk(20);
    $display("\n==============================================================");
    $display(" Verifications executees : %0d", check_count);
    if (error_count == 0)
      $display(" === TEST PASSED ===");
    else
      $display(" === TEST FAILED : %0d erreur(s) ===", error_count);
    $display("==============================================================");
    $finish;
  end

  //----------------------------------------------------------------------------
  // Watchdog
  //----------------------------------------------------------------------------
  // Indispensable : si le reset est mal sequence, write_data() reste bloque
  // indefiniment en attente d'AWREADY et la simulation tourne dans le vide.
  initial begin : watchdog
    #SIM_TIMEOUT;
    $display("\n==============================================================");
    $display(" === TIMEOUT apres %0t : la simulation est bloquee ===", SIM_TIMEOUT);
    $display(" Pistes : peripheral_aresetn jamais relache (X propage dans");
    $display("          proc_sys_reset), FCLK_CLK0 absent, ou couche VHDL");
    $display("          absente du fileset sim_1.");
    $display("==============================================================");
    $fatal(1);
  end

endmodule
