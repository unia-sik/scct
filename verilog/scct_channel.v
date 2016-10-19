// $Id: scct_channel.v 2 2015-06-15 13:52:02Z fkluge $
// Simple timer channel

`include "scct_constants.v"

module scct_channel (
		 clk, rst, counter, counter_changed,
		 icoc_select_i, icoc_select_i_wen,
		 icoc_action_i, icoc_action_i_wen,
		 i_cc_reg, i_cc_reg_wen,
		 irq_enable_i, irq_enable_i_wen,
		 irq_status_i, irq_status_i_wen,
		 force_oc_i, force_oc_i_wen,
		 icoc_select_o, icoc_action_o, cc_reg_o, irq_enable_o, irq_status_o,
		 pin_i, pin_o
		 );
   
   input 			     clk;
   input 			     rst;
   input [`SCCT_COUNTER_CTR_WIDTH-1:0] counter;
   input 			       counter_changed;

   // TODO: replace single-bit X_i, X_i_wen signals by a single signal
   input 			       icoc_select_i;
   input 			       icoc_select_i_wen;
   input [1:0] 			       icoc_action_i;
   input 			       icoc_action_i_wen;
   input [`SCCT_COUNTER_CTR_WIDTH-1:0] i_cc_reg;
   input 			       i_cc_reg_wen;
   input 			       irq_enable_i;
   input 			       irq_enable_i_wen;
   input 			       irq_status_i; // write 1 to clear flag
   input 			       irq_status_i_wen;
   input 			       force_oc_i;
   input 			       force_oc_i_wen;
   
   output 			       icoc_select_o;
   output [1:0] 		       icoc_action_o;
   output [`SCCT_COUNTER_CTR_WIDTH-1:0] cc_reg_o;
   output 				irq_enable_o;
   output 				irq_status_o;
   input 				pin_i;
   output 				pin_o;

   reg 					outval;
   reg 					icoc_select;
   reg [1:0] 				icoc_action;
   reg 					irq_enable;
   reg 					irq_status;
   
   reg 					icirq; // set when IC detects an edge that is interesting according to icoc_action
   reg 					ocirq; // set when counter matches cc_reg
   wire 				intistat;
   
   // Capture/Compare Register
   reg [`SCCT_COUNTER_CTR_WIDTH-1:0] 	cc_reg;
   wire 				oc_match;

   reg 					last_input_state;
 					
   
   
   
   assign icoc_select_o = icoc_select;
   assign icoc_action_o = icoc_action;
   assign cc_reg_o = cc_reg;
   assign irq_enable_o = irq_enable;
   assign irq_status_o = irq_status;
  

   //assign pin = (icoc_select == `SCCT_CH_MS_IC) ? 1'bz : outval;
   assign pin_o = outval;
   
   
   
   assign intistat = (icoc_select == `SCCT_CH_MS_IC) ? icirq : ocirq;
   
   assign oc_match = (cc_reg == counter) && counter_changed;
   
   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  begin
	     cc_reg <= `SCCT_COUNTER_CTR_WIDTH'b0;
	     icoc_select <= `SCCT_CH_MS_IC;
	     icoc_action <= `SCCT_IC_NONE;
	     irq_enable <= 1'b0;
	     icirq <= 1'b0;
	     ocirq <= 1'b0;
	     irq_status <= 1'b0;
	     outval <= 1'b0;
	     last_input_state <= 1'b0;	     
	  end
	else
	  begin
	     // write
	     if (icoc_select_i_wen)
	       begin
		  icoc_select <= icoc_select_i;
		  // reset old irq states
		  case (icoc_select_i)
		    `SCCT_CH_MS_IC: icirq <= 0;
		    `SCCT_CH_MS_OC: ocirq <= 0;
		  endcase // case (icoc_select_i)
	       end
	     if (icoc_action_i_wen)
	       icoc_action <= icoc_action_i;
	     if (i_cc_reg_wen)
	       cc_reg <= i_cc_reg;
	     if (irq_enable_i_wen)
	       irq_enable <= irq_enable_i;
	     if ( (irq_status_i_wen) && (irq_status_i == 1) )
	       begin
		  icirq <= 0;
		  ocirq <= 0;
		  irq_status <= 0;
	       end
	     else
 	       irq_status <= irq_enable ? intistat : 0;

	     //if (force_oc_i_wen)
	       //outval <= force_oc_i;
	     
	     if (icoc_select == `SCCT_CH_MS_OC)
	       begin
		  if ( oc_match || (force_oc_i_wen && force_oc_i) )
		    begin
		       case (icoc_action)
			 `SCCT_OC_HIGH: outval = 1;
			 `SCCT_OC_LOW: outval = 0;
			 `SCCT_OC_TOGGLE: outval = !outval;
		       endcase
		       if (oc_match) ocirq <= 1;
		    end
	       end // if (icoc_select == `SCCT_CH_MS_OC)
	     else if (icoc_select == `SCCT_CH_MS_IC)
	       begin
		  if ( (icoc_action[`SCCT_IC_POSEDGE_BIT] == 1) && (last_input_state == 0) && (pin_i == 1) )
		    begin
		       cc_reg <= counter;
		       icirq <= 1;
		    end
		  else if ( (icoc_action[`SCCT_IC_NEGEDGE_BIT] == 1) && (last_input_state == 1) && (pin_i == 0) )
		    begin
		       cc_reg <= counter;
		       icirq <= 1;
		       
		    end
	       end
	     last_input_state = pin_i;
	  end
	
     end


endmodule // channel


