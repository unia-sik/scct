// $Id: scct_counter.v 2 2015-06-15 13:52:02Z fkluge $
// simple counter

`include "scct_constants.v"

module scct_counter (
		     clk,
		     rst,
		     counter,
		     counter_changed,
		     irq_enable_i, irq_enable_i_wen,
		     irq_status_i, irq_status_i_wen,
		     prescaler_i, prescaler_i_wen,
		     irq_enable_o,
		     irq_status_o,
		     prescaler_o
		     );
   
   input 	 clk;
   input 	 rst;
   output [`SCCT_COUNTER_CTR_WIDTH-1:0] counter;
   // TODO: replace single-bit X_i, X_i_wen signals by a single signal
   input 				irq_enable_i;
   input 				irq_enable_i_wen;
   input 				irq_status_i;
   input 				irq_status_i_wen;
   input [`SCCT_COUNTER_PSC_WIDTH-1:0] 	prescaler_i;
   input 				prescaler_i_wen;
   output 				irq_enable_o;
   output 				irq_status_o;
   output [`SCCT_COUNTER_PSC_WIDTH-1:0] prescaler_o;
   output 				counter_changed;
   
      
   // The actual counter register is 1 bit wider to account for overflows
   reg [`SCCT_COUNTER_CTR_WIDTH:0] 	my_counter;
   // this signals is set to 1 when the counter value has changed. After one cycle it is reset to 0
   reg 					counter_changed;
   
   reg [`SCCT_COUNTER_PSC_WIDTH-1:0] 	prescaler;
   reg [`SCCT_COUNTER_PSC_WIDTH-1:0] 	prescaler_shadow; // used for actual prescaling
   reg [`SCCT_COUNTER_PSC_WIDTH-1:0] 	prescaler_count;
   reg 					irq_enable;
   reg 					irq_status;
   
   wire 				prescaler_match;
   wire 				counter_overflow;
   

   assign prescaler_match = (prescaler_count == prescaler_shadow);
   assign counter[`SCCT_COUNTER_CTR_WIDTH-1:0] = my_counter[`SCCT_COUNTER_CTR_WIDTH-1:0];
   assign counter_overflow = my_counter[`SCCT_COUNTER_CTR_OV_BIT];
   assign prescaler_o = prescaler;
   //assign irq_status_o = irq_enable ? irq_status : 0;
   assign irq_status_o = irq_status;
   
   // writing to registers
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  begin
	  end
	else
	  begin
	  end // else: !if(rst)
     end // always @ (posedge clock or psedge reset_n)

   
   // counter operation
   always @(posedge clk or posedge rst)
     begin
	if(rst)
	  begin
	     prescaler_shadow <= `SCCT_COUNTER_PSC_WIDTH'b0;
	     prescaler_count <= `SCCT_COUNTER_PSC_WIDTH'b0;
	     my_counter <= 0;
	     irq_status <= 0;
	     prescaler <= `SCCT_COUNTER_PSC_WIDTH'b0;
	     irq_enable <= 0;
	     counter_changed <= 0;
	  end // if (rst)
	else
	  begin
	     prescaler_count <= prescaler_count + 1;
	     
	     if (prescaler_match)
	       begin
		  my_counter <= my_counter + 1;
		  prescaler_count <= `SCCT_COUNTER_PSC_WIDTH'b0;
		  prescaler_shadow <= prescaler;
		  counter_changed <= 1;
	       end
	     else
	       begin
		  counter_changed <= 0;
	       end // else: !if(prescaler_match)
	     

	     if (counter_overflow)
	       begin
		  my_counter[`SCCT_COUNTER_CTR_OV_BIT] <= 0;
		  irq_status <= irq_enable ? 1 : 0;
	       end
	     // write requests
	     if (irq_enable_i_wen)
	       irq_enable <= irq_enable_i;

	     // if an overflow occurs in the same cycle as the reset request
	     // for irq_status, ignore the reset.
	     if ( (irq_status_i_wen) && (irq_status_i == 1) && (!counter_overflow))
	       begin
		  irq_status <= 0;
	       end
	     if (prescaler_i_wen)
	       prescaler <= prescaler_i;
	  end // else: !if(rst)
     end // always @ (posedge clk or posedge rst)
   
endmodule // counter
