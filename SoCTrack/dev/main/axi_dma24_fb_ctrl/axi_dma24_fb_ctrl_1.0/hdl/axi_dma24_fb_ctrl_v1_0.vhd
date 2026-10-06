library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_dma24_fb_ctrl_v1_0 is
  generic (
    -- Users to add parameters here

    -- User parameters ends
    -- Do not modify the parameters beyond this line

    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_DATA_WIDTH  : integer   := 32;
    C_S00_AXI_ADDR_WIDTH  : integer   := 5
  );
  port (
    -- Users to add ports here

    -- Interface to DMA24b.
    --
    -- Frame buffer definition.
    o_fb_width      : out std_logic_vector(11 downto 0);
    o_fb_height     : out std_logic_vector(11 downto 0);
    o_fb_addr       : out std_logic_vector(63 downto 0);
    -- Block Level Control Protocol.
    i_ap_done     : in std_logic;
    i_ap_idle     : in std_logic;
    i_ap_ready    : in std_logic;
    o_ap_start    : out std_logic;

    -- Status register.
    o_status      : out std_logic_vector(31 downto 0);

    -- User ports ends
    -- Do not modify the ports beyond this line


    -- Ports of Axi Slave Bus Interface S00_AXI
    s00_axi_aclk  : in std_logic;
    s00_axi_aresetn   : in std_logic;
    s00_axi_awaddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_awprot  : in std_logic_vector(2 downto 0);
    s00_axi_awvalid   : in std_logic;
    s00_axi_awready   : out std_logic;
    s00_axi_wdata   : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_wstrb   : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
    s00_axi_wvalid  : in std_logic;
    s00_axi_wready  : out std_logic;
    s00_axi_bresp   : out std_logic_vector(1 downto 0);
    s00_axi_bvalid  : out std_logic;
    s00_axi_bready  : in std_logic;
    s00_axi_araddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_arprot  : in std_logic_vector(2 downto 0);
    s00_axi_arvalid   : in std_logic;
    s00_axi_arready   : out std_logic;
    s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_rresp   : out std_logic_vector(1 downto 0);
    s00_axi_rvalid  : out std_logic;
    s00_axi_rready  : in std_logic
  );
end axi_dma24_fb_ctrl_v1_0;

architecture arch_imp of axi_dma24_fb_ctrl_v1_0 is

  -- AP Proocol metadata.
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_PARAMETER : string;
  -- ap_ctrl_hs interface
  attribute X_INTERFACE_INFO of o_ap_start : signal is
    "xilinx.com:interface:ap_ctrl_hs:1.0 ap_ctrl_start AP_START";
  attribute X_INTERFACE_INFO of i_ap_done : signal is
    "xilinx.com:interface:ap_ctrl_hs:1.0 ap_ctrl_done AP_DONE";
  attribute X_INTERFACE_INFO of i_ap_idle : signal is
    "xilinx.com:interface:ap_ctrl_hs:1.0 ap_ctrl_idle AP_IDLE";
  attribute X_INTERFACE_INFO of i_ap_ready : signal is
    "xilinx.com:interface:ap_ctrl_hs:1.0 ap_ctrl_ready AP_READY";

  -- component declaration
  component axi_dma24_fb_ctrl_v1_0_S00_AXI is
    generic (
    C_S_AXI_DATA_WIDTH  : integer   := 32;
    C_S_AXI_ADDR_WIDTH  : integer   := 5
    );
    port (
    S_AXI_ACLK  : in std_logic;
    S_AXI_ARESETN   : in std_logic;
    S_AXI_AWADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
    S_AXI_AWVALID   : in std_logic;
    S_AXI_AWREADY   : out std_logic;
    S_AXI_WDATA   : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB   : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID  : in std_logic;
    S_AXI_WREADY  : out std_logic;
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in std_logic;
    S_AXI_ARADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
    S_AXI_ARVALID   : in std_logic;
    S_AXI_ARREADY   : out std_logic;
    S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in std_logic;

    o_reg_status     : out std_logic_vector(31 downto 0);
    o_reg_width      : out std_logic_vector(31 downto 0);
    o_reg_height     : out std_logic_vector(31 downto 0);
    o_reg_addr_low   : out std_logic_vector(31 downto 0);
    o_reg_addr_high  : out std_logic_vector(31 downto 0)
    );
  end component axi_dma24_fb_ctrl_v1_0_S00_AXI;

  -- Memory mapped registers.
  signal w_reg_status     : std_logic_vector(31 downto 0);
  signal w_reg_width      : std_logic_vector(31 downto 0);
  signal w_reg_height     : std_logic_vector(31 downto 0);
  signal w_reg_addr_low   : std_logic_vector(31 downto 0);
  signal w_reg_addr_high  : std_logic_vector(31 downto 0);
  -- AXIS source selection mask (1-bit).
  signal w_axis_sel       : std_logic;

  constant CTRL_FB_SEL_TPG    : std_logic := '0';
  constant CTRL_FB_SEL_IMG    : std_logic := '1';

  type state_t is (S_IDLE, S_START, S_STREAM);

  signal r_state    : state_t;
  signal r_ap_start : std_logic;
begin

-- Instantiation of Axi Bus Interface S00_AXI
axi_dma24_fb_ctrl_v1_0_S00_AXI_inst : axi_dma24_fb_ctrl_v1_0_S00_AXI
  generic map (
    C_S_AXI_DATA_WIDTH  => C_S00_AXI_DATA_WIDTH,
    C_S_AXI_ADDR_WIDTH  => C_S00_AXI_ADDR_WIDTH
  )
  port map (
    S_AXI_ACLK  => s00_axi_aclk,
    S_AXI_ARESETN   => s00_axi_aresetn,
    S_AXI_AWADDR  => s00_axi_awaddr,
    S_AXI_AWPROT  => s00_axi_awprot,
    S_AXI_AWVALID   => s00_axi_awvalid,
    S_AXI_AWREADY   => s00_axi_awready,
    S_AXI_WDATA   => s00_axi_wdata,
    S_AXI_WSTRB   => s00_axi_wstrb,
    S_AXI_WVALID  => s00_axi_wvalid,
    S_AXI_WREADY  => s00_axi_wready,
    S_AXI_BRESP   => s00_axi_bresp,
    S_AXI_BVALID  => s00_axi_bvalid,
    S_AXI_BREADY  => s00_axi_bready,
    S_AXI_ARADDR  => s00_axi_araddr,
    S_AXI_ARPROT  => s00_axi_arprot,
    S_AXI_ARVALID   => s00_axi_arvalid,
    S_AXI_ARREADY   => s00_axi_arready,
    S_AXI_RDATA   => s00_axi_rdata,
    S_AXI_RRESP   => s00_axi_rresp,
    S_AXI_RVALID  => s00_axi_rvalid,
    S_AXI_RREADY  => s00_axi_rready,

    o_reg_status      => w_reg_status,
    o_reg_width       => w_reg_width,
    o_reg_height      => w_reg_height,
    o_reg_addr_low    => w_reg_addr_low,
    o_reg_addr_high  => w_reg_addr_high

  );

  -- Add user logic here

  o_status      <= w_reg_status;
  w_axis_sel    <= w_reg_status(0);

  o_ap_start    <= r_ap_start;
  o_fb_width    <= w_reg_width(11 downto 0);
  o_fb_height   <= w_reg_height(11 downto 0);
  o_fb_addr     <= w_reg_addr_high(31 downto 0) & w_reg_addr_low(31 downto 0);


rtl: process(s00_axi_aclk)
begin
  if rising_edge(s00_axi_aclk) then
    if (s00_axi_aresetn = '0') then
      r_ap_start  <= '0';
      r_state     <= S_IDLE;
    else
        -- Block level control FSM.
        -- UG1399:
        -- 1) The block waits for ap_start to go High before it begins operation.
        -- 2) Output ap_idle goes Low immediately to indicate the design is no longer idle.
        -- 3) The ap_start signal must remain High until ap_ready goes High.
        --      . If ap_start remains High the design will start the next transaction.
        --      . If ap_start is taken Low, the design will complete the current transaction
        --        and halt operation.
        -- 4) Data can be read on the input ports. Data can be written to the output ports.
        -- 5) Output ap_done goes High when the block completes operation.
        -- 6) When the design is ready to accept new inputs, the ap_ready signal is pulsed High
        --    for one clock cycle.
        --      . In non-pipelined designs, the ap_ready signal is asserted at the same time as ap_done.
        --      . In pipelined designs, the ap_ready signal might go High at any cycle after ap_start
        --        is sampled High.
        --      . If ap_start remains high after ap_ready goes high, the next transaction starts immediately.
        --      . When ap_start goes low right after ap_ready goes high, the design keeps executing
        --        until ap_done is high and then stops operation, unless ap_start goes high again in the meantime,
        --        which starts a new transaction.
        -- 7) The ap_idle signal indicates when the design is idle and not operating.
        --      . If the ap_start signal is Low when ap_ready is High, the design stops operation,
        --        and the ap_idle signal goes High one cycle after ap_done.
        --      . If the ap_start signal is High when ap_ready is High, the design continues to operate,
        --        and the ap_idle signal remains Low.

        case r_state is
          when S_IDLE =>
            if (w_axis_sel = CTRL_FB_SEL_IMG) then
              r_state <= S_START;
            end if;

          when S_START =>
            if (i_ap_idle = '1') then
              r_ap_start  <= '1';
              r_state     <= S_STREAM;
            end if;

          when S_STREAM =>
            if (i_ap_done = '1') and (i_ap_ready = '1') then
              if (w_axis_sel = CTRL_FB_SEL_IMG) then
                -- Start next transaction.
                r_ap_start  <= '1';
                r_state     <= S_STREAM;
              else
                -- Suspend stream.
                r_ap_start  <= '0';
                r_state     <= S_IDLE;
              end if;
            end if;

        end case;

    end if;
  end if;

end process;

	-- User logic ends

end arch_imp;
