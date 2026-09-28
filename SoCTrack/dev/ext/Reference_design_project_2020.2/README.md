# Reference_design_project — portage Vivado / Vitis 2020.2

Portage du `Reference_design_project` (Vivado + Vitis **2022.2**) vers la chaîne
**2020.2** installée sur cette machine (`/tools/xilinx/Vivado/2020.2`,
`/tools/xilinx/Vitis/2020.2`). Le projet d'origine, dans le dossier frère
`Reference_design_project/`, n'a pas été modifié.

Design : Zynq-7000 Cora Z7-10, `xc7z010clg400-1` — PS7 (preset Cora Z7) +
AXI Interconnect + 2 × AXI GPIO 3 bits (LED RGB), pilotés depuis le PS.

## Pourquoi une reconstruction et non une conversion

Vivado ne sait pas rétrograder un projet : il refuse un `.xpr` produit par une
version postérieure, et les `.xci` / `.bd` de 2022.2 ne sont pas résolvables par
2020.2. Le design est donc **rejoué par script** en 2020.2. Idem pour le
workspace Vitis, recréé via XSCT à partir du nouveau XSA.

## Utilisation

```bash
./build_all.sh            # tout : projet Vivado, bitstream, XSA, simu, Vitis
./build_all.sh vivado     # projet Vivado seul
./build_all.sh hw         # synthèse + implémentation + bitstream + XSA
./build_all.sh sim        # banc système : Zynq PS7 + AXI4-Lite + GPIO
./build_all.sh sim-axis   # banc unitaire AXI4-Stream (driver + monitor bouclés)
./build_all.sh vitis      # workspace Vitis (nécessite le XSA)
```

Les scripts refusent d'écraser un `SoCora/` ou un `PSCora/` existant : supprimer
le répertoire concerné avant de relancer. Les logs vont dans `logs/`.

## Contenu

| Chemin | Rôle |
|---|---|
| `scripts/create_project.tcl` | crée le projet Vivado 2020.2, le block design `design_1`, le wrapper VHDL, les contraintes et le fileset de simulation |
| `scripts/build_hw.tcl` | synthèse, implémentation, bitstream, export `design_1_wrapper.xsa` |
| `scripts/run_sim.tcl` | lance la simulation du banc système (`tb_socora_gpio`) |
| `scripts/run_sim_axis.tcl` | lance le banc unitaire AXI4-Stream (`tb_environnement`) |
| `scripts/sim_common.tcl` | logique partagée des deux scripts de simulation |
| `src/sim/select_tb.tcl` | bascule entre les deux bancs **depuis le GUI** |
| `scripts/create_vitis_ws.tcl` | plateforme Vitis `SoCora` + les deux applications |
| `CoraZ7_PS_config.tcl` | preset PS7 Cora Z7, repris tel quel du projet d'origine |
| `src/constraints/`, `src/rtl/`, `src/sim/` | sources partagées |
| `src/sw/` | sources C des applications Vitis |
| `SoCora/`, `PSCora/` | générés par les scripts |

## Banc unitaire AXI4-Stream (`tb_environnement.vhd`)

Le projet contient **deux bancs de test**, indépendants l'un de l'autre, qui
cohabitent dans le fileset `sim_1` :

| Banc | Top | Lancement | Rôle |
|---|---|---|---|
| système | `tb_socora_gpio` (SystemVerilog) | `./build_all.sh sim` | Zynq PS7 VIP, AXI4-Lite, GPIO. Contrôle de non-régression du portage. |
| unitaire | `tb_environnement` (VHDL) | `./build_all.sh sim-axis` | AXI4-Stream : `axi4s_driver` → `axi4s_monitor`. Support de TP. |

Le second est destiné aux étudiants : il est **entièrement en VHDL**, aucune
connaissance du SystemVerilog n'est nécessaire, et `src/sim/tb_environnement.vhd`
est lui-même le top de simulation.

```
sample_in_gray.txt (640 × 480, décimal, tabulations — format ImageJ)
       |
       v
+----------------+   tvalid / tdata / tlast     +-----------------+
|  axi4s_driver  | ---------------------------> |  axi4s_monitor  |
+----------------+ <--------------------------- +-----------------+
                       tready                            |
                                                          v
                                          src/sim/output/stream_out_0.txt
```

Les deux instances sont reliées **directement** (boucle simple) : le fichier
produit doit donc être la copie conforme du fichier lu. C'est le critère de bon
fonctionnement :

```bash
./build_all.sh sim-axis
diff <(head -32 src/sim/sample_in_gray.txt) src/sim/output/stream_out_0.txt
```

Attendu dans `logs/run_sim_axis.log` : `lignes capturees : 32 (attendu 32)`,
`pixels captures : 20480 (attendu 20480)`, et un `diff` vide.

### Ce que les étudiants modifient

Un seul fichier, `src/sim/tb_environnement.vhd`, et principalement son bloc de
constantes en tête :

| Constante | Défaut | Rôle |
|---|---|---|
| `C_CLK_PERIOD` | `10 ns` | horloge du flux (100 MHz) |
| `C_DATA_WIDTH` | `8` | largeur de TDATA (le fichier va de 4 à 255) |
| `C_IMG_WIDTH` | `640` | colonnes de `sample_in_gray.txt` |
| `C_IMG_HEIGHT` | `32` | **lignes réellement capturées** — mettre 480 pour l'image complète |
| `C_IN_FILE` / `C_OUT_BASE` | chemins relatifs | fichiers lus et écrits |

`C_IMG_HEIGHT = 32` donne un run de ~205 µs simulés. L'image complète (480)
fait ~3 ms simulés. **Mesuré** sur ce projet : `./build_all.sh sim-axis` prend
~11 s avec 32 lignes et ~14 s avec 480 — l'essentiel est la compilation et
l'élaboration, la simulation elle-même est négligeable. Le défaut à 32 est donc
un confort, pas une nécessité : passer à 480 ne coûte que quelques secondes.
`run_sim_axis.tcl` porte le `xsim.simulate.runtime` à 20 ms le temps de son run,
les deux valeurs passent sans rien avoir à régler.

Le cartouche `INSÉRER VOTRE IP ICI`, au milieu du fichier, indique précisément
les quatre signaux à redéclarer et les deux `port map` à modifier pour intercaler
un module entre le driver et le monitor. Un module ajouté doit aussi être déclaré
dans `src/sim/add_sim.tcl` pour entrer dans le fileset `sim_1`.

`Axi4s_driver.vhd` et `Axi4s_monitor.vhd` ne sont **pas** à modifier (ils sont
partagés avec `../TestPatterns/`).

### Lancer ce banc depuis le GUI Vivado

Les deux bancs partagent le fileset `sim_1`, qui n'a qu'**un** `top`, qu'**une**
durée de run et qu'un jeu de vues d'ondes. Changer le top à la main dans le GUI
ne suffit donc pas. Dans la console Tcl de Vivado :

```tcl
source <racine>/src/sim/select_tb.tcl
tb_axis                 ;# ou tb_gpio
launch_simulation
```

`tb_axis` / `tb_gpio` posent ensemble le top, la durée de run et la vue d'ondes,
et nettoient les points d'arrêt enregistrés (voir ci-dessous). En ligne de
commande il n'y a rien à faire : `./build_all.sh sim` et `sim-axis` s'en
chargent, et **fixent eux-mêmes leur top** au lieu de se fier à celui qui traîne
dans le `.xpr` — sans quoi un top changé depuis le GUI ferait silencieusement
simuler l'autre banc.

### ⚠ Points d'arrêt : bug xsim 2020.2 sur les fichiers VHDL

**Symptôme** : la simulation ne démarre pas, l'horloge paraît « non générée », la
fenêtre d'ondes reste vide, et aucun relancement ne passe.

**Cause mesurée** : à partir de **deux points d'arrêt dans un même fichier
VHDL**, xsim 2020.2 concatène le chemin du fichier avec lui-même et l'étape
`simulate` avorte, *avant* le `run` :

```
ERROR: [Simulator 45-7] No such file
  '<...>/src/sim/tb_environnement.vhd<...>/src/sim/tb_environnement.vhd'
  in the design.
```

Mesures sur ce projet :

| Points d'arrêt | Fichier | Résultat |
|---|---|---|
| 1 | `tb_environnement.vhd` | fonctionne (`Stopped at time : 0 fs`) |
| 2 | `tb_environnement.vhd` | **échec**, chemin doublé |
| 3 | `tb_environnement.vhd` | **échec**, chemin doublé |
| 1 | `tb_socora_gpio.sv` | fonctionne |

**Contournements** : n'utiliser qu'**un seul** point d'arrêt à la fois dans un
fichier VHDL, ou s'en passer au profit des `report ... severity note` — le banc
en est déjà pourvu. Un point d'arrêt n'a de toute façon aucun sens en batch : le
run s'arrête dessus et rend la main sans rien avoir vérifié.

**Récupération** quand la simulation ne démarre plus (on ne peut alors même plus
ouvrir la fenêtre *Breakpoints* pour les retirer) :

```tcl
source <racine>/src/sim/select_tb.tcl
tb_clear_breakpoints
```

Les points d'arrêt sont stockés hors du `.xpr`, dans
`SoCora/SoCora.sim/sim_1/behav/xsim/xsim.dir/<top>_behav/TempBreakPointFile.txt` ;
la procédure en garde une copie `.bak`. Les deux scripts batch appellent ce
nettoyage automatiquement.

### Chemins relatifs : pourquoi cinq `../`

Le répertoire de travail de xsim est
`SoCora/SoCora.sim/sim_1/behav/xsim`, soit cinq niveaux sous la racine du
projet — d'où `"../../../../../src/sim/sample_in_gray.txt"`. C'est le même
nombre de `../` que celui qu'on lit dans les `.prj` générés par Vivado dans ce
répertoire. Un nom de fichier nu serait cherché, et le résultat écrit, au milieu
des fichiers générés, effacés à chaque reconstruction du projet.

Le répertoire `src/sim/output/` doit exister avant le run (`file_open` en
`WRITE_MODE` échoue sinon) : `add_sim.tcl` et `run_sim_axis.tcl` le recréent
systématiquement, car un répertoire vide disparaît d'une archive ou d'un clone.

### Arrêt de la simulation, en VHDL-93

`tb_environnement` n'utilise ni `assert ... severity failure` (qui signalerait
une erreur alors que tout s'est bien passé) ni `std.env.stop` (VHDL-2008, non
activé sur ce projet). L'horloge est écrite en boucle explicite, gardée par un
signal `sim_running` : quand celui-ci retombe, plus aucun front n'est programmé,
tous les process restent bloqués sur leur `wait until rising_edge(clk)`, la file
d'événements se vide et xsim rend la main immédiatement.

Corollaire à connaître : `sim_running` est un `boolean`, donc un type **non
résolu**. Il n'admet qu'une seule source — c'est pourquoi le garde-fou de durée
est le `for C_TIMEOUT` de l'attente de `p_fin`, et non un process séparé.

### Cohabitation des deux bancs dans `sim_1`

Le fileset n'a qu'un `top`, qu'une durée de run et qu'un jeu de vues d'ondes.
`run_sim_axis.tcl` les bascule le temps de son exécution puis **restaure** l'état
initial, y compris en cas d'échec : `sim_1` repart toujours sur `tb_socora_gpio`.

Deux pièges rencontrés, corrigés dans le script :

- `launch_simulation` ne se contente pas de la propriété `xsim.view` : il passe à
  xsim **un `-view` par fichier `.wcfg` actif du fileset**. Les deux vues sont
  volontairement laissées **actives** : cela produit une douzaine de
  `Simulation object ... was not found in the design` purement cosmétiques, mais
  garantit qu'un utilisateur du GUI qui bascule le top à la main voie quand même
  ses signaux. Les désactiver donnerait un log propre et une **fenêtre d'ondes
  vide** — le piège exact qui fait croire que l'horloge n'est pas générée. Les
  scripts batch désactivent celle de l'autre banc pendant leur seul run.
- Il reste un avertissement inévitable,
  `Couldn't load one or more protocol instances from protoinst file ... There are
  no instances of module "design_1" in the design` : Vivado ajoute d'office le
  `protoinst` du block design à tout run du projet. Sans conséquence pour ce banc,
  qui ne contient pas de block design.

## Conformité au design d'origine — ce qui a été vérifié

- **Wrapper VHDL identique octet pour octet** (`design_1_wrapper.vhd`).
- **Block design** : mêmes cellules et mêmes VLNV, mêmes noms de nets, mêmes
  ports externes (`led`, `led2`, `DDR`, `FIXED_IO`), mêmes adresses
  (`0x41200000` / `0x41210000`, 64K).
- **PS7** : les 325 paramètres `PCW_*` sont identiques à ceux du `.bd` 2022.2.
  Le preset `CoraZ7_PS_config.tcl` en est un sur-ensemble strict, il suffit
  donc à reproduire la configuration exacte.
- **Timing** : WNS 12,034 ns / WHS 0,024 ns (contre 12,987 / 0,069 en 2022.2),
  même nombre d'endpoints (1632), toutes contraintes tenues.
- **Simulation** : `=== TEST PASSED ===` et **33 vérifications**, comme attendu.
  L'ajout du banc AXI4-Stream ne change rien à ce résultat : les deux bancs
  partagent le fileset mais aucun signal ni aucune hiérarchie.
- **BSP Vitis** : `XPAR_GPIO_0_BASEADDR = 0x41200000`,
  `XPAR_GPIO_1_BASEADDR = 0x41210000` ; mêmes domaines (`zynq_fsbl`,
  `standalone_domain` sur `ps7_cortexa9_0`).

## Écarts 2022.2 → 2020.2

### 1. Banc de test : synchronisation (seule modification fonctionnelle)

**C'est le seul point qui a demandé une adaptation du code.**

Sous **xsim 2020.2**, une référence hiérarchique SystemVerilog vers un signal
VHDL est *lisible* mais **ne déclenche pas d'événement** côté SystemVerilog.
Les constructions du banc d'origine

```systemverilog
wait (`ARESETN === 1'b1);        // `ARESETN = design_1_i.rst_ps7_0_50M_peripheral_aresetn
repeat (N) @(posedge `FCLK0);    // `FCLK0   = design_1_i.processing_system7_0_FCLK_CLK0
```

ne se réveillent jamais et la simulation reste bloquée jusqu'au timeout — alors
que le signal change bel et bien (sondé sous xsim : `peripheral_aresetn` vaut 1
dès ~2 µs). xsim 2022.2 acceptait ces constructions.

`src/sim/tb_socora_gpio.sv` a donc été adapté :

- `wait (...)` → boucle de sondage bornée (`ARESETN_POLL_MAX`), qui échoue
  proprement avec un message au lieu de figer la simulation ;
- `repeat (N) @(posedge \`FCLK0)` → `wait_fclk(N)`, temporisation sur la période
  connue de FCLK_CLK0 (`CLK_PERIOD = 20 ns`, soit 50 MHz).

Le séquencement AXI reste porté par le VIP, qui gère ses propres handshakes :
ces attentes ne servent qu'à laisser les sorties se stabiliser. Le scénario, les
adresses et les 33 vérifications sont inchangés.

### 2. Version du VIP PS7

`processing_system7_vip` passe de **v1_0_15** à **v1_0_10**. Les tâches
utilisées par le banc (`write_data`, `read_data`, `fpga_soft_reset`,
`set_debug_level_info`, `set_stop_on_error`) ont des signatures **identiques**,
et `por_srstb_reset` y est commentée de la même façon. Les commentaires du banc
ont été mis à jour en conséquence.

### 3. Format des fichiers `.xci`

2020.2 écrit les `.xci` en **XML** (`spirit:`), 2022.2 en **JSON**. Sans effet
sur le design, mais tout script maison qui parserait un `.xci` en JSON doit être
adapté.

### 4. Chemins

Le `.xpr` d'origine porte un chemin Windows
(`C:/Users/.../MyProject/SoCora/SoCora.xpr`). Ici tout est relatif à ce dossier.

### Points **sans** écart, contrairement à ce qu'on pourrait craindre

- Toutes les IP du block design existent en 2020.2 aux mêmes versions majeures :
  `processing_system7:5.5`, `axi_gpio:2.0`, `proc_sys_reset:5.0`,
  `axi_interconnect:2.1`. Aucune IP verrouillée après recréation.
- L'arborescence de projet est la même (`SoCora.gen/`, `SoCora.srcs/`,
  `SoCora.runs/`) : le répertoire `.gen` existe déjà en 2020.2.
- Projet *part-based* (`BoardPart` vide) : aucun board file Digilent requis.
- `xc7z010` est un device WebPACK : build sans licence.

## Attention si vous modifiez le block design

Le banc de test référence **en dur** des noms internes du block design. Si vous
renommez une cellule ou un net, la simulation cassera. À conserver tels quels :

- cellules : `processing_system7_0`, `axi_gpio_0`, `axi_gpio_1`,
  `rst_ps7_0_50M`, `ps7_0_axi_periph` ;
- nets : `processing_system7_0_FCLK_CLK0`, `processing_system7_0_FCLK_RESET0_N`,
  `rst_ps7_0_50M_peripheral_aresetn` (forcés par `connect_bd_net -net ...`) ;
- ports externes : `led`, `led2`, `DDR`, `FIXED_IO` (forcés par
  `make_bd_intf_pins_external -name ...` ; sans cela Vivado nommerait `GPIO_0`,
  `DDR_0`… et le fichier de contraintes ne s'appliquerait plus) ;
- adresses : `0x41200000` et `0x41210000`.

Le fichier de contraintes contient par ailleurs des `set_property` actifs sur
des ports absents du design (`Vp_Vn_0_v_p`, `Vaux*`) : ils produisent un
avertissement `get_ports` vide, sans effet — comportement identique à 2022.2,
le fichier n'a pas été touché.
