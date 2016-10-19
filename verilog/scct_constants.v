// $Id: scct_constants.v 2 2015-06-15 13:52:02Z fkluge $
// Constants for the Simple Capture/Compare Timer (SCCT)

`define SCCT_COUNTER_CTR_WIDTH 32
//`define SCCT_COUNTER_CTR_ACT_WIDTH `SCCT_COUNTER_CTR_WIDTH+1
//`define SCCT_COUNTER_CTR_MSB `SCCT_COUNTER_CTR_ACT_WIDTH-1
`define SCCT_COUNTER_CTR_OV_BIT `SCCT_COUNTER_CTR_WIDTH
`define SCCT_COUNTER_PSC_WIDTH 32

// Channel modes
`define SCCT_CH_MS_IC 1'b0
`define SCCT_CH_MS_OC 1'b1

// IC mode
`define SCCT_IC_NONE    2'b00
`define SCCT_IC_POSEDGE 2'b01
`define SCCT_IC_NEGEDGE 2'b10
`define SCCT_IC_ANYEDGE 2'b11
// IC mode bits (only internally used)
`define SCCT_IC_POSEDGE_BIT 0
`define SCCT_IC_NEGEDGE_BIT 1

// OC MODE
`define SCCT_OC_NONE    2'b00
`define SCCT_OC_HIGH    2'b01
`define SCCT_OC_LOW     2'b10
`define SCCT_OC_TOGGLE  2'b11

`define SCCT_N_CHANNELS 8

// Addresses
`define SCCT_CTR 5'h00
`define SCCT_PSC 5'h01
`define SCCT_CTR_IE 5'h02
`define SCCT_CTR_IS 5'h03

`define SCCT_CH_MS 5'h08
`define SCCT_CH_ACT 5'h09
`define SCCT_CH_IE 5'h0a
`define SCCT_CH_IS 5'h0b
`define SCCT_CH_OCF 5'h0c
`define SCCT_CH_INP 5'h0d
`define SCCT_CH_OUT 5'h0e

`define SCCT_CH_CCR0 5'h10
`define SCCT_CH_CCR1 5'h11
`define SCCT_CH_CCR2 5'h12
`define SCCT_CH_CCR3 5'h13
`define SCCT_CH_CCR4 5'h14
`define SCCT_CH_CCR5 5'h15
`define SCCT_CH_CCR6 5'h16
`define SCCT_CH_CCR7 5'h17


/*`define SCCT_
`define SCCT_
`define SCCT_
`define SCCT_
`define SCCT_
`define SCCT_
`define SCCT_*/
