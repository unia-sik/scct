// $Id: test_channel.v 2 2015-06-15 13:52:02Z fkluge $
// Test bed for counter and channels

`include "scct_constants.v"

module test_ctr_ch;
   
   /* Make a reset that pulses once. */
   reg rst = 0;
   //wire rst_n;

   //reg iSig=0;

   reg inp = 0;
   
   wire iSig;
   assign iSig = inp ? 1 : 0;
   wire oSig;

   wire ctr_ch;
   
   
   //assign pin = (msi == `SCCT_CH_MS_IC) ? iSig : oSig;
   assign pin_i = iSig;
   assign pin_o = oSig;
   

   reg 	ct_ieni = 0;
   reg 	ct_ieni_wen = 0;
   reg 	ct_istati = 0;
   reg 	ct_istati_wen = 0;
   reg [`SCCT_COUNTER_PSC_WIDTH-1:0] ct_psci = 0;
   reg 				     ct_psci_wen = 0;
   wire 			     ct_ien;
   wire 			     ct_istat;
   wire [`SCCT_COUNTER_PSC_WIDTH-1:0] ct_psc;
   
   
   reg        msi, msiw;
   reg [1:0]  mi;
   reg        miw;
   reg [`SCCT_COUNTER_CTR_WIDTH-1:0] ccri;
   reg 			      ccriw;
   reg 			      ieni;
   reg 			      ieniw;
   reg 			      isi = 1;
   reg 			      isiw;
   reg 			      fo = 0;
   reg 			      fow = 0;
   wire 			      ms;
   wire [1:0] 			      m;
   wire [`SCCT_COUNTER_CTR_WIDTH-1:0] ccr;
   wire 			      ien;
   wire 			      is;
   wire 			      pin_i;
   wire 			      pin_o;
   
   

   initial
     begin
	$dumpfile("test.lxt2");
	$dumpvars;
	
	//$dumpvars(0,clk);
	//$dumpvars(0,ctr);
	//$dumpvars(0,reset_n);
     end

   
   initial
     begin
	# 0 rst = 1;
	# 0 msi = 0;
	# 0 miw = 0;
	# 0 msiw = 0;
	# 0 ccriw = 0;
	# 0 ieniw = 0;
	# 0 isiw = 0;
	# 0 fow = 0;
	
	# 1 rst = 0;

	# 1 ieni = 1;
	ieniw = 1;
	# 1 ieniw = 0;

	//ct_psci = 1;
	//ct_psci_wen = 1;
	ct_ieni = 1;
	ct_ieni_wen = 1;
	
	# 2 //ct_psci_wen = 0;
	ct_ieni_wen = 0;
	


	// Test input capture
	# 2 msi = `SCCT_CH_MS_IC;
	msiw = 1;
	# 1 msiw = 0;

	# 2 mi = `SCCT_IC_ANYEDGE;
	miw = 1;
	# 1 miw = 0;
	
	# 2 inp = 1;

	# 5 isiw = 1;
	# 2 isiw = 0;
	
	# 4 inp = 0;

	# 4 isiw = 1;
	# 2 isiw = 0;

	// now do output compare
	# 5 msi = `SCCT_CH_MS_OC;
	msiw = 1;
	# 2 msiw = 0;

	# 1 mi = `SCCT_OC_HIGH;
	miw = 1;
	# 2 miw = 0;
	
	# 1 fo = 1;
	fow = 1;
	# 2 fow = 0;

	# 1 mi = `SCCT_OC_TOGGLE;
	miw = 1;
	# 2 miw = 0;

	# 1 ccri = `SCCT_COUNTER_CTR_WIDTH'd15;
	ccriw = 1;
	# 2 ccriw = 0;

	# 60 isiw = 1;
	# 2 isiw = 0;
	
	# 54 isiw = 1;
	# 2 isiw = 0;
	/*
	// Test output compare
	# 8 msi = `SCCT_CH_MS_OC;
	# 8 msiw = 1;
	# 10 msiw = 0;

	# 11 mi = `SCCT_OC_TOGGLE;
	# 11 miw = 1;
	# 13 miw = 0;

	
	# 15 ccri = `SCCT_COUNTER_CTR_WIDTH'd15;
	# 15 ccriw = 1;
	# 17 ccriw = 0;

	# 13 fo = 0;
	# 13 fow = 1;
	# 14 fow = 0;

	# 19 isiw = 1;
	# 21 isiw = 0;
	
	# 55 isiw = 1;
	# 57 isiw = 0;
	 */
	
	# 100 $stop;
	//# 132000 $stop;
     end
   
   
   
   assign reset_n = !reset;
   
   
   /* Make a regular pulsing clock. */
   reg clk = 1;
   always #1 clk = !clk;
   
   wire [`SCCT_COUNTER_CTR_WIDTH-1:0] ctr;
   wire        irq;
   reg [15:0]  expire = 5;

   
   scct_counter ctr1 (clk, rst, ctr, ctr_ch,
		      ct_ieni, ct_ieni_wen, ct_istati, ct_istati_wen, ct_psci, ct_psci_wen, ct_ien, ct_istat, ct_psc);

   scct_channel ch1(clk, rst, ctr, ctr_ch,
		 msi, msiw, mi, miw, ccri, ccriw, ieni, ieniw, isi, isiw, fo, fow,
		 ms, m, ccr, ien, is, pin_i, pin_o);
   
     
   initial
     $monitor("At time %t, counter = %0d reset = %h, irq = %h",
	      $time, ctr, rst, irq);
endmodule // test
