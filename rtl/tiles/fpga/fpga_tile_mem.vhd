-- Copyright (c) 2011-2021 Columbia University, System Level Design Group
-- SPDX-License-Identifier: Apache-2.0

-----------------------------------------------------------------------------
--  Memory interface tile
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.esp_global.all;
use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.devices.all;
use work.gencomp.all;
use work.leon3.all;
use work.misc.all;
-- pragma translate_off
use work.sim.all;
library unisim;
use unisim.all;
-- pragma translate_on
use work.monitor_pkg.all;
use work.esp_csr_pkg.all;
use work.jtag_pkg.all;
use work.sldacc.all;
use work.nocpackage.all;
use work.tile.all;
use work.cachepackage.all;
use work.coretypes.all;

use work.grlib_config.all;
use work.socmap.all;
use work.tiles_pkg.all;

entity fpga_tile_mem is
  generic (
    SIMULATION   : boolean              := false;
    ROUTER_PORTS : ports_vec            := "11111";
    HAS_SYNC     : integer range 0 to 1 := 1);
  port (
    raw_rstn           : in  std_ulogic;
    rst                : in  std_ulogic;
    refclk             : in  std_ulogic;
    clk                : in  std_ulogic;
    pllbypass          : in  std_ulogic;
    pllclk             : out std_ulogic;
    dco_clk            : out std_ulogic;
    -- DDR controller ports (this_has_ddr -> 1)
    dco_clk_div2       : out std_ulogic;
    dco_clk_div2_90    : out std_ulogic;
    ddr_ahbsi          : out ahb_slv_in_type;
    ddr_ahbso          : in  ahb_slv_out_type;
    ddr_cfg0           : out std_logic_vector(31 downto 0);
    ddr_cfg1           : out std_logic_vector(31 downto 0);
    ddr_cfg2           : out std_logic_vector(31 downto 0);
    mem_id             : out integer range 0 to CFG_NMEM_TILE + CFG_NSLM_TILE + CFG_NSLMDDR_TILE - 1;
    -- FPGA proxy memory link
    fpga_data_in       : in  std_logic_vector(ARCH_BITS - 1 downto 0);
    fpga_data_out      : out std_logic_vector(ARCH_BITS - 1 downto 0);
    fpga_oen           : out std_ulogic;
    fpga_valid_in      : in  std_ulogic;
    fpga_valid_out     : out std_ulogic;
    fpga_clk_in        : in  std_ulogic;
    fpga_clk_out       : out std_ulogic;
    fpga_credit_in     : in  std_ulogic;
    fpga_credit_out    : out std_ulogic;
    -- Test interface
    tdi                : in  std_logic;
    tdo                : out std_logic;
    tms                : in  std_logic;
    tclk               : in  std_logic;
    -- NOC
    sys_clk_int        : in  std_logic;
    noc1_data_n_in     : in  noc_flit_type;
    noc1_data_s_in     : in  noc_flit_type;
    noc1_data_w_in     : in  noc_flit_type;
    noc1_data_e_in     : in  noc_flit_type;
    noc1_data_void_in  : in  std_logic_vector(3 downto 0);
    noc1_stop_in       : in  std_logic_vector(3 downto 0);
    noc1_data_n_out    : out noc_flit_type;
    noc1_data_s_out    : out noc_flit_type;
    noc1_data_w_out    : out noc_flit_type;
    noc1_data_e_out    : out noc_flit_type;
    noc1_data_void_out : out std_logic_vector(3 downto 0);
    noc1_stop_out      : out std_logic_vector(3 downto 0);
    noc2_data_n_in     : in  noc_flit_type;
    noc2_data_s_in     : in  noc_flit_type;
    noc2_data_w_in     : in  noc_flit_type;
    noc2_data_e_in     : in  noc_flit_type;
    noc2_data_void_in  : in  std_logic_vector(3 downto 0);
    noc2_stop_in       : in  std_logic_vector(3 downto 0);
    noc2_data_n_out    : out noc_flit_type;
    noc2_data_s_out    : out noc_flit_type;
    noc2_data_w_out    : out noc_flit_type;
    noc2_data_e_out    : out noc_flit_type;
    noc2_data_void_out : out std_logic_vector(3 downto 0);
    noc2_stop_out      : out std_logic_vector(3 downto 0);
    noc3_data_n_in     : in  noc_flit_type;
    noc3_data_s_in     : in  noc_flit_type;
    noc3_data_w_in     : in  noc_flit_type;
    noc3_data_e_in     : in  noc_flit_type;
    noc3_data_void_in  : in  std_logic_vector(3 downto 0);
    noc3_stop_in       : in  std_logic_vector(3 downto 0);
    noc3_data_n_out    : out noc_flit_type;
    noc3_data_s_out    : out noc_flit_type;
    noc3_data_w_out    : out noc_flit_type;
    noc3_data_e_out    : out noc_flit_type;
    noc3_data_void_out : out std_logic_vector(3 downto 0);
    noc3_stop_out      : out std_logic_vector(3 downto 0);
    noc4_data_n_in     : in  noc_flit_type;
    noc4_data_s_in     : in  noc_flit_type;
    noc4_data_w_in     : in  noc_flit_type;
    noc4_data_e_in     : in  noc_flit_type;
    noc4_data_void_in  : in  std_logic_vector(3 downto 0);
    noc4_stop_in       : in  std_logic_vector(3 downto 0);
    noc4_data_n_out    : out noc_flit_type;
    noc4_data_s_out    : out noc_flit_type;
    noc4_data_w_out    : out noc_flit_type;
    noc4_data_e_out    : out noc_flit_type;
    noc4_data_void_out : out std_logic_vector(3 downto 0);
    noc4_stop_out      : out std_logic_vector(3 downto 0);
    noc5_data_n_in     : in  misc_noc_flit_type;
    noc5_data_s_in     : in  misc_noc_flit_type;
    noc5_data_w_in     : in  misc_noc_flit_type;
    noc5_data_e_in     : in  misc_noc_flit_type;
    noc5_data_void_in  : in  std_logic_vector(3 downto 0);
    noc5_stop_in       : in  std_logic_vector(3 downto 0);
    noc5_data_n_out    : out misc_noc_flit_type;
    noc5_data_s_out    : out misc_noc_flit_type;
    noc5_data_w_out    : out misc_noc_flit_type;
    noc5_data_e_out    : out misc_noc_flit_type;
    noc5_data_void_out : out std_logic_vector(3 downto 0);
    noc5_stop_out      : out std_logic_vector(3 downto 0);
    noc6_data_n_in     : in  noc_flit_type;
    noc6_data_s_in     : in  noc_flit_type;
    noc6_data_w_in     : in  noc_flit_type;
    noc6_data_e_in     : in  noc_flit_type;
    noc6_data_void_in  : in  std_logic_vector(3 downto 0);
    noc6_stop_in       : in  std_logic_vector(3 downto 0);
    noc6_data_n_out    : out noc_flit_type;
    noc6_data_s_out    : out noc_flit_type;
    noc6_data_w_out    : out noc_flit_type;
    noc6_data_e_out    : out noc_flit_type;
    noc6_data_void_out : out std_logic_vector(3 downto 0);
    noc6_stop_out      : out std_logic_vector(3 downto 0);
    noc1_mon_noc_vec   : out monitor_noc_type;
    noc2_mon_noc_vec   : out monitor_noc_type;
    noc3_mon_noc_vec   : out monitor_noc_type;
    noc4_mon_noc_vec   : out monitor_noc_type;
    noc5_mon_noc_vec   : out monitor_noc_type;
    noc6_mon_noc_vec   : out monitor_noc_type;
    mon_mem            : out monitor_mem_type;
    mon_cache          : out monitor_cache_type;
    mon_dvfs           : out monitor_dvfs_type
    );
end;


architecture rtl of fpga_tile_mem is

  -- Tile parameters
  signal this_local_y : local_yx;
  signal this_local_x : local_yx;

  -- DCO reset -> keeping the logic compliant with the asic flow
  signal dco_rstn : std_ulogic;

  -- Tile parameters
  signal tile_config : std_logic_vector(ESP_CSR_WIDTH - 1 downto 0);

  -- DCO
  signal dco_en       : std_ulogic;
  signal dco_clk_sel  : std_ulogic;
  signal dco_cc_sel   : std_logic_vector(5 downto 0);
  signal dco_fc_sel   : std_logic_vector(5 downto 0);
  signal dco_div_sel  : std_logic_vector(2 downto 0);
  signal dco_freq_sel : std_logic_vector(1 downto 0);

  -- Tile NoC interface
  signal test1_output_port_s   : noc_flit_type;
  signal test1_data_void_out_s : std_ulogic;
  signal test1_stop_in_s       : std_ulogic;
  signal test2_output_port_s   : noc_flit_type;
  signal test2_data_void_out_s : std_ulogic;
  signal test2_stop_in_s       : std_ulogic;
  signal test3_output_port_s   : noc_flit_type;
  signal test3_data_void_out_s : std_ulogic;
  signal test3_stop_in_s       : std_ulogic;
  signal test4_output_port_s   : noc_flit_type;
  signal test4_data_void_out_s : std_ulogic;
  signal test4_stop_in_s       : std_ulogic;
  signal test5_output_port_s   : misc_noc_flit_type;
  signal test5_data_void_out_s : std_ulogic;
  signal test5_stop_in_s       : std_ulogic;
  signal test6_output_port_s   : noc_flit_type;
  signal test6_data_void_out_s : std_ulogic;
  signal test6_stop_in_s       : std_ulogic;
  signal test1_input_port_s    : noc_flit_type;
  signal test1_data_void_in_s  : std_ulogic;
  signal test1_stop_out_s      : std_ulogic;
  signal test2_input_port_s    : noc_flit_type;
  signal test2_data_void_in_s  : std_ulogic;
  signal test2_stop_out_s      : std_ulogic;
  signal test3_input_port_s    : noc_flit_type;
  signal test3_data_void_in_s  : std_ulogic;
  signal test3_stop_out_s      : std_ulogic;
  signal test4_input_port_s    : noc_flit_type;
  signal test4_data_void_in_s  : std_ulogic;
  signal test4_stop_out_s      : std_ulogic;
  signal test5_input_port_s    : misc_noc_flit_type;
  signal test5_data_void_in_s  : std_ulogic;
  signal test5_stop_out_s      : std_ulogic;
  signal test6_input_port_s    : noc_flit_type;
  signal test6_data_void_in_s  : std_ulogic;
  signal test6_stop_out_s      : std_ulogic;

  -- Noc signals
  signal noc1_stop_in_tile       : std_ulogic;
  signal noc1_stop_out_tile      : std_ulogic;
  signal noc1_data_void_in_tile  : std_ulogic;
  signal noc1_data_void_out_tile : std_ulogic;
  signal noc2_stop_in_tile       : std_ulogic;
  signal noc2_stop_out_tile      : std_ulogic;
  signal noc2_data_void_in_tile  : std_ulogic;
  signal noc2_data_void_out_tile : std_ulogic;
  signal noc3_stop_in_tile       : std_ulogic;
  signal noc3_stop_out_tile      : std_ulogic;
  signal noc3_data_void_in_tile  : std_ulogic;
  signal noc3_data_void_out_tile : std_ulogic;
  signal noc4_stop_in_tile       : std_ulogic;
  signal noc4_stop_out_tile      : std_ulogic;
  signal noc4_data_void_in_tile  : std_ulogic;
  signal noc4_data_void_out_tile : std_ulogic;
  signal noc5_stop_in_tile       : std_ulogic;
  signal noc5_stop_out_tile      : std_ulogic;
  signal noc5_data_void_in_tile  : std_ulogic;
  signal noc5_data_void_out_tile : std_ulogic;
  signal noc6_stop_in_tile       : std_ulogic;
  signal noc6_stop_out_tile      : std_ulogic;
  signal noc6_data_void_in_tile  : std_ulogic;
  signal noc6_data_void_out_tile : std_ulogic;
  signal noc1_input_port_tile    : noc_flit_type;
  signal noc2_input_port_tile    : noc_flit_type;
  signal noc3_input_port_tile    : noc_flit_type;
  signal noc4_input_port_tile    : noc_flit_type;
  signal noc5_input_port_tile    : misc_noc_flit_type;
  signal noc6_input_port_tile    : noc_flit_type;
  signal noc1_output_port_tile   : noc_flit_type;
  signal noc2_output_port_tile   : noc_flit_type;
  signal noc3_output_port_tile   : noc_flit_type;
  signal noc4_output_port_tile   : noc_flit_type;
  signal noc5_output_port_tile   : misc_noc_flit_type;
  signal noc6_output_port_tile   : noc_flit_type;

  -- NoC monitors
  signal noc1_mon_noc_vec_int : monitor_noc_type;
  signal noc2_mon_noc_vec_int : monitor_noc_type;
  signal noc3_mon_noc_vec_int : monitor_noc_type;
  signal noc4_mon_noc_vec_int : monitor_noc_type;
  signal noc5_mon_noc_vec_int : monitor_noc_type;
  signal noc6_mon_noc_vec_int : monitor_noc_type;

begin

  noc1_mon_noc_vec <= noc1_mon_noc_vec_int;
  noc2_mon_noc_vec <= noc2_mon_noc_vec_int;
  noc3_mon_noc_vec <= noc3_mon_noc_vec_int;
  noc4_mon_noc_vec <= noc4_mon_noc_vec_int;
  noc5_mon_noc_vec <= noc5_mon_noc_vec_int;
  noc6_mon_noc_vec <= noc6_mon_noc_vec_int;

  -----------------------------------------------------------------------------
  -- JTAG for single tile testing / bypass when test_if_en = 0
  -----------------------------------------------------------------------------
  jtag_test_i : jtag_test
    generic map (
      test_if_en => 0)
    port map (
      rst                 => rst,
      refclk              => clk,
      tile_rst            => dco_rstn,
      tdi                 => tdi,
      tdo                 => tdo,
      tms                 => tms,
      tclk                => tclk,
      noc1_output_port    => noc1_output_port_tile,
      noc1_data_void_out  => noc1_data_void_out_tile,
      noc1_stop_in        => noc1_stop_in_tile,
      noc2_output_port    => noc2_output_port_tile,
      noc2_data_void_out  => noc2_data_void_out_tile,
      noc2_stop_in        => noc2_stop_in_tile,
      noc3_output_port    => noc3_output_port_tile,
      noc3_data_void_out  => noc3_data_void_out_tile,
      noc3_stop_in        => noc3_stop_in_tile,
      noc4_output_port    => noc4_output_port_tile,
      noc4_data_void_out  => noc4_data_void_out_tile,
      noc4_stop_in        => noc4_stop_in_tile,
      noc5_output_port    => noc5_output_port_tile,
      noc5_data_void_out  => noc5_data_void_out_tile,
      noc5_stop_in        => noc5_stop_in_tile,
      noc6_output_port    => noc6_output_port_tile,
      noc6_data_void_out  => noc6_data_void_out_tile,
      noc6_stop_in        => noc6_stop_in_tile,
      test1_output_port   => test1_output_port_s,
      test1_data_void_out => test1_data_void_out_s,
      test1_stop_in       => test1_stop_in_s,
      test2_output_port   => test2_output_port_s,
      test2_data_void_out => test2_data_void_out_s,
      test2_stop_in       => test2_stop_in_s,
      test3_output_port   => test3_output_port_s,
      test3_data_void_out => test3_data_void_out_s,
      test3_stop_in       => test3_stop_in_s,
      test4_output_port   => test4_output_port_s,
      test4_data_void_out => test4_data_void_out_s,
      test4_stop_in       => test4_stop_in_s,
      test5_output_port   => test5_output_port_s,
      test5_data_void_out => test5_data_void_out_s,
      test5_stop_in       => test5_stop_in_s,
      test6_output_port   => test6_output_port_s,
      test6_data_void_out => test6_data_void_out_s,
      test6_stop_in       => test6_stop_in_s,
      test1_input_port    => test1_input_port_s,
      test1_data_void_in  => test1_data_void_in_s,
      test1_stop_out      => test1_stop_out_s,
      test2_input_port    => test2_input_port_s,
      test2_data_void_in  => test2_data_void_in_s,
      test2_stop_out      => test2_stop_out_s,
      test3_input_port    => test3_input_port_s,
      test3_data_void_in  => test3_data_void_in_s,
      test3_stop_out      => test3_stop_out_s,
      test4_input_port    => test4_input_port_s,
      test4_data_void_in  => test4_data_void_in_s,
      test4_stop_out      => test4_stop_out_s,
      test5_input_port    => test5_input_port_s,
      test5_data_void_in  => test5_data_void_in_s,
      test5_stop_out      => test5_stop_out_s,
      test6_input_port    => test6_input_port_s,
      test6_data_void_in  => test6_data_void_in_s,
      test6_stop_out      => test6_stop_out_s,
      noc1_input_port     => noc1_input_port_tile,
      noc1_data_void_in   => noc1_data_void_in_tile,
      noc1_stop_out       => noc1_stop_out_tile,
      noc2_input_port     => noc2_input_port_tile,
      noc2_data_void_in   => noc2_data_void_in_tile,
      noc2_stop_out       => noc2_stop_out_tile,
      noc3_input_port     => noc3_input_port_tile,
      noc3_data_void_in   => noc3_data_void_in_tile,
      noc3_stop_out       => noc3_stop_out_tile,
      noc4_input_port     => noc4_input_port_tile,
      noc4_data_void_in   => noc4_data_void_in_tile,
      noc4_stop_out       => noc4_stop_out_tile,
      noc5_input_port     => noc5_input_port_tile,
      noc5_data_void_in   => noc5_data_void_in_tile,
      noc5_stop_out       => noc5_stop_out_tile,
      noc6_input_port     => noc6_input_port_tile,
      noc6_data_void_in   => noc6_data_void_in_tile,
      noc6_stop_out       => noc6_stop_out_tile);

  tile_mem_1 : tile_mem
    generic map (
      SIMULATION   => SIMULATION,
      this_has_dco => 0,
      this_has_ddr => 1,
      dco_rst_cfg  => (others => '0'))
    port map (
      raw_rstn            => raw_rstn,
      tile_rst            => rst,
      refclk              => refclk,
      clk                 => clk,
      pllbypass           => pllbypass,
      pllclk              => pllclk,
      dco_clk             => dco_clk,
      dco_clk_div2        => dco_clk_div2,
      dco_clk_div2_90     => dco_clk_div2_90,
      dco_rstn            => dco_rstn,
      phy_rstn            => open,
      dco_freq_sel        => dco_freq_sel,
      dco_div_sel         => dco_div_sel,
      dco_fc_sel          => dco_fc_sel,
      dco_cc_sel          => dco_cc_sel,
      dco_clk_sel         => dco_clk_sel,
      dco_en              => dco_en,
      dco_clk_delay_sel   => (others => '0'),
      ddr_ahbsi           => ddr_ahbsi,
      ddr_ahbso           => ddr_ahbso,
      fpga_data_in        => fpga_data_in,
      fpga_data_out       => fpga_data_out,
      fpga_oen            => fpga_oen,
      fpga_valid_in       => fpga_valid_in,
      fpga_valid_out      => fpga_valid_out,
      fpga_clk_in         => fpga_clk_in,
      fpga_clk_out        => fpga_clk_out,
      fpga_credit_in      => fpga_credit_in,
      fpga_credit_out     => fpga_credit_out,
      test1_output_port   => test1_output_port_s,
      test1_data_void_out => test1_data_void_out_s,
      test1_stop_in       => test1_stop_out_s,
      test1_input_port    => test1_input_port_s,
      test1_data_void_in  => test1_data_void_in_s,
      test1_stop_out      => test1_stop_in_s,
      test2_output_port   => test2_output_port_s,
      test2_data_void_out => test2_data_void_out_s,
      test2_stop_in       => test2_stop_out_s,
      test2_input_port    => test2_input_port_s,
      test2_data_void_in  => test2_data_void_in_s,
      test2_stop_out      => test2_stop_in_s,
      test3_output_port   => test3_output_port_s,
      test3_data_void_out => test3_data_void_out_s,
      test3_stop_in       => test3_stop_out_s,
      test3_input_port    => test3_input_port_s,
      test3_data_void_in  => test3_data_void_in_s,
      test3_stop_out      => test3_stop_in_s,
      test4_output_port   => test4_output_port_s,
      test4_data_void_out => test4_data_void_out_s,
      test4_stop_in       => test4_stop_out_s,
      test4_input_port    => test4_input_port_s,
      test4_data_void_in  => test4_data_void_in_s,
      test4_stop_out      => test4_stop_in_s,
      test5_output_port   => test5_output_port_s,
      test5_data_void_out => test5_data_void_out_s,
      test5_stop_in       => test5_stop_out_s,
      test5_input_port    => test5_input_port_s,
      test5_data_void_in  => test5_data_void_in_s,
      test5_stop_out      => test5_stop_in_s,
      test6_output_port   => test6_output_port_s,
      test6_data_void_out => test6_data_void_out_s,
      test6_stop_in       => test6_stop_out_s,
      test6_input_port    => test6_input_port_s,
      test6_data_void_in  => test6_data_void_in_s,
      test6_stop_out      => test6_stop_in_s,
      mon_mem             => mon_mem,
      mon_cache           => mon_cache,
      mon_dvfs            => mon_dvfs);

  noc_domain_socket_i : noc_domain_socket
    generic map (
      this_has_token_pm => 0,
      is_tile_io        => false,
      SIMULATION        => SIMULATION,
      ROUTER_PORTS      => ROUTER_PORTS,
      HAS_SYNC          => HAS_SYNC)
    port map (
      raw_rstn                => raw_rstn,
      noc_rstn                => rst,
      dco_rstn                => dco_rstn,
      sys_clk                 => sys_clk_int,
      dco_clk                 => clk,
      acc_clk                 => open,
      refclk                  => clk,
      -- CSRs
      tile_config             => open,
      -- DCO config
      dco_freq_sel            => dco_freq_sel,
      dco_div_sel             => dco_div_sel,
      dco_fc_sel              => dco_fc_sel,
      dco_cc_sel              => dco_cc_sel,
      dco_clk_sel             => dco_clk_sel,
      dco_en                  => dco_en,
      dco_clk_delay_sel       => open,
      ext_dco_cc_sel          => (others => '0'),
      ext_ldo_res_sel         => (others => '0'),
      -- pad config
      pad_cfg                 => open,
      -- NoC
      noc1_data_n_in          => noc1_data_n_in,
      noc1_data_s_in          => noc1_data_s_in,
      noc1_data_w_in          => noc1_data_w_in,
      noc1_data_e_in          => noc1_data_e_in,
      noc1_data_void_in       => noc1_data_void_in,
      noc1_stop_in            => noc1_stop_in,
      noc1_data_n_out         => noc1_data_n_out,
      noc1_data_s_out         => noc1_data_s_out,
      noc1_data_w_out         => noc1_data_w_out,
      noc1_data_e_out         => noc1_data_e_out,
      noc1_data_void_out      => noc1_data_void_out,
      noc1_stop_out           => noc1_stop_out,
      noc2_data_n_in          => noc2_data_n_in,
      noc2_data_s_in          => noc2_data_s_in,
      noc2_data_w_in          => noc2_data_w_in,
      noc2_data_e_in          => noc2_data_e_in,
      noc2_data_void_in       => noc2_data_void_in,
      noc2_stop_in            => noc2_stop_in,
      noc2_data_n_out         => noc2_data_n_out,
      noc2_data_s_out         => noc2_data_s_out,
      noc2_data_w_out         => noc2_data_w_out,
      noc2_data_e_out         => noc2_data_e_out,
      noc2_data_void_out      => noc2_data_void_out,
      noc2_stop_out           => noc2_stop_out,
      noc3_data_n_in          => noc3_data_n_in,
      noc3_data_s_in          => noc3_data_s_in,
      noc3_data_w_in          => noc3_data_w_in,
      noc3_data_e_in          => noc3_data_e_in,
      noc3_data_void_in       => noc3_data_void_in,
      noc3_stop_in            => noc3_stop_in,
      noc3_data_n_out         => noc3_data_n_out,
      noc3_data_s_out         => noc3_data_s_out,
      noc3_data_w_out         => noc3_data_w_out,
      noc3_data_e_out         => noc3_data_e_out,
      noc3_data_void_out      => noc3_data_void_out,
      noc3_stop_out           => noc3_stop_out,
      noc4_data_n_in          => noc4_data_n_in,
      noc4_data_s_in          => noc4_data_s_in,
      noc4_data_w_in          => noc4_data_w_in,
      noc4_data_e_in          => noc4_data_e_in,
      noc4_data_void_in       => noc4_data_void_in,
      noc4_stop_in            => noc4_stop_in,
      noc4_data_n_out         => noc4_data_n_out,
      noc4_data_s_out         => noc4_data_s_out,
      noc4_data_w_out         => noc4_data_w_out,
      noc4_data_e_out         => noc4_data_e_out,
      noc4_data_void_out      => noc4_data_void_out,
      noc4_stop_out           => noc4_stop_out,
      noc5_data_n_in          => noc5_data_n_in,
      noc5_data_s_in          => noc5_data_s_in,
      noc5_data_w_in          => noc5_data_w_in,
      noc5_data_e_in          => noc5_data_e_in,
      noc5_data_void_in       => noc5_data_void_in,
      noc5_stop_in            => noc5_stop_in,
      noc5_data_n_out         => noc5_data_n_out,
      noc5_data_s_out         => noc5_data_s_out,
      noc5_data_w_out         => noc5_data_w_out,
      noc5_data_e_out         => noc5_data_e_out,
      noc5_data_void_out      => noc5_data_void_out,
      noc5_stop_out           => noc5_stop_out,
      noc6_data_n_in          => noc6_data_n_in,
      noc6_data_s_in          => noc6_data_s_in,
      noc6_data_w_in          => noc6_data_w_in,
      noc6_data_e_in          => noc6_data_e_in,
      noc6_data_void_in       => noc6_data_void_in,
      noc6_stop_in            => noc6_stop_in,
      noc6_data_n_out         => noc6_data_n_out,
      noc6_data_s_out         => noc6_data_s_out,
      noc6_data_w_out         => noc6_data_w_out,
      noc6_data_e_out         => noc6_data_e_out,
      noc6_data_void_out      => noc6_data_void_out,
      noc6_stop_out           => noc6_stop_out,
      -- monitors
      noc1_mon_noc_vec        => noc1_mon_noc_vec_int,
      noc2_mon_noc_vec        => noc2_mon_noc_vec_int,
      noc3_mon_noc_vec        => noc3_mon_noc_vec_int,
      noc4_mon_noc_vec        => noc4_mon_noc_vec_int,
      noc5_mon_noc_vec        => noc5_mon_noc_vec_int,
      noc6_mon_noc_vec        => noc6_mon_noc_vec_int,
      -- synchronizers out to tile
      noc1_output_port_tile   => noc1_output_port_tile,
      noc1_data_void_out_tile => noc1_data_void_out_tile,
      noc1_stop_in_tile       => noc1_stop_in_tile,
      noc2_output_port_tile   => noc2_output_port_tile,
      noc2_data_void_out_tile => noc2_data_void_out_tile,
      noc2_stop_in_tile       => noc2_stop_in_tile,
      noc3_output_port_tile   => noc3_output_port_tile,
      noc3_data_void_out_tile => noc3_data_void_out_tile,
      noc3_stop_in_tile       => noc3_stop_in_tile,
      noc4_output_port_tile   => noc4_output_port_tile,
      noc4_data_void_out_tile => noc4_data_void_out_tile,
      noc4_stop_in_tile       => noc4_stop_in_tile,
      noc5_output_port_tile   => noc5_output_port_tile,
      noc5_data_void_out_tile => noc5_data_void_out_tile,
      noc5_stop_in_tile       => noc5_stop_in_tile,
      noc6_output_port_tile   => noc6_output_port_tile,
      noc6_data_void_out_tile => noc6_data_void_out_tile,
      noc6_stop_in_tile       => noc6_stop_in_tile,
      -- tile to synchronizers in
      noc1_input_port_tile    => noc1_input_port_tile,
      noc1_data_void_in_tile  => noc1_data_void_in_tile,
      noc1_stop_out_tile      => noc1_stop_out_tile,
      noc2_input_port_tile    => noc2_input_port_tile,
      noc2_data_void_in_tile  => noc2_data_void_in_tile,
      noc2_stop_out_tile      => noc2_stop_out_tile,
      noc3_input_port_tile    => noc3_input_port_tile,
      noc3_data_void_in_tile  => noc3_data_void_in_tile,
      noc3_stop_out_tile      => noc3_stop_out_tile,
      noc4_input_port_tile    => noc4_input_port_tile,
      noc4_data_void_in_tile  => noc4_data_void_in_tile,
      noc4_stop_out_tile      => noc4_stop_out_tile,
      noc5_input_port_tile    => noc5_input_port_tile,
      noc5_data_void_in_tile  => noc5_data_void_in_tile,
      noc5_stop_out_tile      => noc5_stop_out_tile,
      noc6_input_port_tile    => noc6_input_port_tile,
      noc6_data_void_in_tile  => noc6_data_void_in_tile,
      noc6_stop_out_tile      => noc6_stop_out_tile);

end;