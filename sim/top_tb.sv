`timescale 1ns/1ps
`define CLK_CYCLE 6.4

reg sys_clkp;

initial begin


  srio_example_top_srio_gen2_0
 //// NOTE: uncomment these lines to simulate packet transfer
 // #(
 //    .SIM_ONLY                (SIM_ONLY            ),//(0), // mirror object handles reporting
 //    .VALIDATION_FEATURES     (VALIDATION_FEATURES ),//(1),
 //    .QUICK_STARTUP           (QUICK_STARTUP       ),//(1),
 //    .USE_CHIPSCOPE           (USE_CHIPSCOPE       ),//(0),
 //    .STATISTICS_GATHERING    (STATISTICS_GATHERING) //(1)
 //   )
   srio_example_top_primary
     (.sys_clkp                (sys_clkp),
      .sys_clkn                (sys_clkn),

      .sys_rst                 (sys_rst),

      .srio_rxn0               (srio_rxn0),
      .srio_rxp0               (srio_rxp0),

      .srio_txn0               (srio_txn0),
      .srio_txp0               (srio_txp0),

      .sim_train_en            (1'b1),
      .led0                    (led0_primary)

     );