// $Id: scct.v 2 2015-06-15 13:52:02Z fkluge $
// Simple Capture/Compare Timer
// Implementation assumed 32 bit platform

`include "scct_constants.v"

module scct (
	     clk,
	     rst,
	     address,
	     read,
	     readdata,
	     writedata,
	     write,
	     irq,
	     pins_i,
	     pins_o
	     );
   
   input clk;
   input rst;
   
   // Avalon interface
   input [4:0] address;
   input 			  read;   
   output [31:0] 		  readdata;
   input [31:0] 		  writedata;
   input 			  write;
   output 			  irq;
   
   // Conduit interface
   input [`SCCT_N_CHANNELS-1:0]   pins_i;
   output [`SCCT_N_CHANNELS-1:0]  pins_o;


   reg [31:0] 		  readdata;
   
   
   // internal counter interface
   // TODO: replace single-bit X_i, X_i_wen signals by a single signal
   wire [`SCCT_COUNTER_CTR_WIDTH-1:0] counter;
   reg 				      ctr_irq_enable_i;
   reg 				      ctr_irq_enable_i_wen;
   reg 				      ctr_irq_status_i;
   reg 				      ctr_irq_status_i_wen;
   reg [`SCCT_COUNTER_PSC_WIDTH-1:0]  ctr_prescaler_i;
   reg 				      ctr_prescaler_i_wen;
   wire 			      ctr_irq_enable_o;
   wire 			      ctr_irq_status_o;
   wire [`SCCT_COUNTER_PSC_WIDTH-1:0] ctr_prescaler_o;
   wire 			      ctr_counter_changed;
   
   
   // internal channels interface
   // TODO: replace single-bit X_i, X_i_wen signals by a single signal
   reg [`SCCT_N_CHANNELS-1:0] 	      ch_icoc_select_i;
   reg 				      ch_icoc_select_i_wen;
   reg [`SCCT_N_CHANNELS*2-1:0]       ch_icoc_action_i;
   reg 				      ch_icoc_action_i_wen;
   reg [`SCCT_COUNTER_CTR_WIDTH-1:0]  ch_i_cc_reg [0:`SCCT_N_CHANNELS-1];
   reg [`SCCT_N_CHANNELS-1:0] 	      ch_i_cc_reg_wen;
   reg [`SCCT_N_CHANNELS-1:0] 	      ch_irq_enable_i;
   reg 				      ch_irq_enable_i_wen;
   reg [`SCCT_N_CHANNELS-1:0] 	      ch_irq_status_i;
   reg 				      ch_irq_status_i_wen;
   reg [`SCCT_N_CHANNELS-1:0] 	      ch_force_oc_i;
   reg 				      ch_force_oc_i_wen;
   wire [`SCCT_N_CHANNELS-1:0] 	      ch_icoc_select_o;
   wire [`SCCT_N_CHANNELS*2-1:0]      ch_icoc_action_o;
   wire [`SCCT_COUNTER_CTR_WIDTH-1:0] ch_cc_reg_o [0:`SCCT_N_CHANNELS-1];
   wire [`SCCT_N_CHANNELS-1:0] 	      ch_irq_enable_o;
   wire [`SCCT_N_CHANNELS-1:0] 	      ch_irq_status_o;
   // pins through conduit interface
   reg 				      irq;
   
   //assign irq = ((ctr_irq_status_o == 0) && (ch_irq_status_o == `SCCT_N_CHANNELS'b00)) ? 0 : 1;
   //assign irq = ((ctr_irq_status_o == 1) || (ch_irq_status_o != 0)) ? 1 : 0;


   //assign irq = ( (ctr_irq_status_o == 1) || (ch_irq_status_o[1] == 1) ) ? 1 : 0;
   //assign irq = ( ctr_irq_status_o | ch_irq_status_o[0] | ch_irq_status_o[1] | ch_irq_status_o[2] | ch_irq_status_o[3] | ch_irq_status_o[4] | ch_irq_status_o[5] | ch_irq_status_o[6] | ch_irq_status_o[7] );
   //assign irq = (ch_irq_status_o === `SCCT_N_CHANNELS'b0) ? 0 : 1;
   //assign irq = ( ctr_irq_status_o || ch_irq_status_o[0] || ch_irq_status_o[1] || ch_irq_status_o[2] || ch_irq_status_o[3] || ch_irq_status_o[4] || ch_irq_status_o[5] || ch_irq_status_o[6] || ch_irq_status_o[7] );
   //assign irq = ( (ctr_irq_status_o == 1) | (ch_irq_status_o[0] == 1) | (ch_irq_status_o[1] == 1) | (ch_irq_status_o[2] == 1) | (ch_irq_status_o[3] == 1) | (ch_irq_status_o[4] == 1) | (ch_irq_status_o[5] == 1) | (ch_irq_status_o[6] == 1) | (ch_irq_status_o[7] == 1) );
   //assign irq = ch_irq_status_o[0];

   // assignment of irq wire results in 'x' once an irq is asserted,
   // so we have to do it this way...
   always @(ctr_irq_status_o or ch_irq_status_o)
     irq <= ((ctr_irq_status_o == 1) || (ch_irq_status_o != 0)) ? 1 : 0;
     //irq <= ( (ctr_irq_status_o == 1) | (ch_irq_status_o[0] == 1) | (ch_irq_status_o[1] == 1) | (ch_irq_status_o[2] == 1) | (ch_irq_status_o[3] == 1) | (ch_irq_status_o[4] == 1) | (ch_irq_status_o[5] == 1) | (ch_irq_status_o[6] == 1) | (ch_irq_status_o[7] == 1) );


   /*   
   always @ (ch_irq_status_o) begin
      $display("@%0d ch_irq_status %b, irq %b",$time,ch_irq_status_o, irq);
      #3 $display("@%0d ch_irq_status %b, irq %b",$time,ch_irq_status_o, irq);
   end
   */
   
   scct_counter my_counter(
			   .clk(clk),
			   .rst(rst),
			   .counter(counter),
			   .counter_changed(ctr_counter_changed),
			   .irq_enable_i(ctr_irq_enable_i),
			   .irq_enable_i_wen(ctr_irq_enable_i_wen),
			   .irq_status_i(ctr_irq_status_i),
			   .irq_status_i_wen(ctr_irq_status_i_wen),
			   .prescaler_i(ctr_prescaler_i),
			   .prescaler_i_wen(ctr_prescaler_i_wen),
			   .irq_enable_o(ctr_irq_enable_o),
			   .irq_status_o(ctr_irq_status_o),
			   .prescaler_o(ctr_prescaler_o)
			   );



   // Channel definitions were created with ./mkch.pl

   // Channel 0
   scct_channel channel0(
                    .clk(clk),
                    .rst(rst),
                    .counter(counter),
                    .counter_changed(ctr_counter_changed),
                    .icoc_select_i(ch_icoc_select_i[0]),
                    .icoc_select_i_wen(ch_icoc_select_i_wen),
                    .icoc_action_i(ch_icoc_action_i[1:0]),
                    .icoc_action_i_wen(ch_icoc_action_i_wen),
                    .i_cc_reg(ch_i_cc_reg[0]),
                    .i_cc_reg_wen(ch_i_cc_reg_wen[0]),
                    .irq_enable_i(ch_irq_enable_i[0]),
                    .irq_enable_i_wen(ch_irq_enable_i_wen),
                    .irq_status_i(ch_irq_status_i[0]),
                    .irq_status_i_wen(ch_irq_status_i_wen),
                    .force_oc_i(ch_force_oc_i[0]),
                    .force_oc_i_wen(ch_force_oc_i_wen),
                    .icoc_select_o(ch_icoc_select_o[0]),
                    .icoc_action_o(ch_icoc_action_o[1:0]),
                    .cc_reg_o(ch_cc_reg_o[0]),
                    .irq_enable_o(ch_irq_enable_o[0]),
                    .irq_status_o(ch_irq_status_o[0]),
                    .pin_i(pins_i[0]),
                    .pin_o(pins_o[0])
                    );

   // Channel 1
   scct_channel channel1(
                    .clk(clk),
                    .rst(rst),
                    .counter(counter),
                    .counter_changed(ctr_counter_changed),
                    .icoc_select_i(ch_icoc_select_i[1]),
                    .icoc_select_i_wen(ch_icoc_select_i_wen),
                    .icoc_action_i(ch_icoc_action_i[3:2]),
                    .icoc_action_i_wen(ch_icoc_action_i_wen),
                    .i_cc_reg(ch_i_cc_reg[1]),
                    .i_cc_reg_wen(ch_i_cc_reg_wen[1]),
                    .irq_enable_i(ch_irq_enable_i[1]),
                    .irq_enable_i_wen(ch_irq_enable_i_wen),
                    .irq_status_i(ch_irq_status_i[1]),
                    .irq_status_i_wen(ch_irq_status_i_wen),
                    .force_oc_i(ch_force_oc_i[1]),
                    .force_oc_i_wen(ch_force_oc_i_wen),
                    .icoc_select_o(ch_icoc_select_o[1]),
                    .icoc_action_o(ch_icoc_action_o[3:2]),
                    .cc_reg_o(ch_cc_reg_o[1]),
                    .irq_enable_o(ch_irq_enable_o[1]),
                    .irq_status_o(ch_irq_status_o[1]),
                    .pin_i(pins_i[1]),
                    .pin_o(pins_o[1])
                    );

   // Channel 2
   scct_channel channel2(
                    .clk(clk),
                    .rst(rst),
                    .counter(counter),
                    .counter_changed(ctr_counter_changed),
                    .icoc_select_i(ch_icoc_select_i[2]),
                    .icoc_select_i_wen(ch_icoc_select_i_wen),
                    .icoc_action_i(ch_icoc_action_i[5:4]),
                    .icoc_action_i_wen(ch_icoc_action_i_wen),
                    .i_cc_reg(ch_i_cc_reg[2]),
                    .i_cc_reg_wen(ch_i_cc_reg_wen[2]),
                    .irq_enable_i(ch_irq_enable_i[2]),
                    .irq_enable_i_wen(ch_irq_enable_i_wen),
                    .irq_status_i(ch_irq_status_i[2]),
                    .irq_status_i_wen(ch_irq_status_i_wen),
                    .force_oc_i(ch_force_oc_i[2]),
                    .force_oc_i_wen(ch_force_oc_i_wen),
                    .icoc_select_o(ch_icoc_select_o[2]),
                    .icoc_action_o(ch_icoc_action_o[5:4]),
                    .cc_reg_o(ch_cc_reg_o[2]),
                    .irq_enable_o(ch_irq_enable_o[2]),
                    .irq_status_o(ch_irq_status_o[2]),
                    .pin_i(pins_i[2]),
                    .pin_o(pins_o[2])
                    );

   // Channel 3
   scct_channel channel3(
                    .clk(clk),
                    .rst(rst),
                    .counter(counter),
                    .counter_changed(ctr_counter_changed),
                    .icoc_select_i(ch_icoc_select_i[3]),
                    .icoc_select_i_wen(ch_icoc_select_i_wen),
                    .icoc_action_i(ch_icoc_action_i[7:6]),
                    .icoc_action_i_wen(ch_icoc_action_i_wen),
                    .i_cc_reg(ch_i_cc_reg[3]),
                    .i_cc_reg_wen(ch_i_cc_reg_wen[3]),
                    .irq_enable_i(ch_irq_enable_i[3]),
                    .irq_enable_i_wen(ch_irq_enable_i_wen),
                    .irq_status_i(ch_irq_status_i[3]),
                    .irq_status_i_wen(ch_irq_status_i_wen),
                    .force_oc_i(ch_force_oc_i[3]),
                    .force_oc_i_wen(ch_force_oc_i_wen),
                    .icoc_select_o(ch_icoc_select_o[3]),
                    .icoc_action_o(ch_icoc_action_o[7:6]),
                    .cc_reg_o(ch_cc_reg_o[3]),
                    .irq_enable_o(ch_irq_enable_o[3]),
                    .irq_status_o(ch_irq_status_o[3]),
                    .pin_i(pins_i[3]),
                    .pin_o(pins_o[3])
                    );

   // Channel 4
   scct_channel channel4(
                    .clk(clk),
                    .rst(rst),
                    .counter(counter),
                    .counter_changed(ctr_counter_changed),
                    .icoc_select_i(ch_icoc_select_i[4]),
                    .icoc_select_i_wen(ch_icoc_select_i_wen),
                    .icoc_action_i(ch_icoc_action_i[9:8]),
                    .icoc_action_i_wen(ch_icoc_action_i_wen),
                    .i_cc_reg(ch_i_cc_reg[4]),
                    .i_cc_reg_wen(ch_i_cc_reg_wen[4]),
                    .irq_enable_i(ch_irq_enable_i[4]),
                    .irq_enable_i_wen(ch_irq_enable_i_wen),
                    .irq_status_i(ch_irq_status_i[4]),
                    .irq_status_i_wen(ch_irq_status_i_wen),
                    .force_oc_i(ch_force_oc_i[4]),
                    .force_oc_i_wen(ch_force_oc_i_wen),
                    .icoc_select_o(ch_icoc_select_o[4]),
                    .icoc_action_o(ch_icoc_action_o[9:8]),
                    .cc_reg_o(ch_cc_reg_o[4]),
                    .irq_enable_o(ch_irq_enable_o[4]),
                    .irq_status_o(ch_irq_status_o[4]),
                    .pin_i(pins_i[4]),
                    .pin_o(pins_o[4])
                    );

   // Channel 5
   scct_channel channel5(
                    .clk(clk),
                    .rst(rst),
                    .counter(counter),
                    .counter_changed(ctr_counter_changed),
                    .icoc_select_i(ch_icoc_select_i[5]),
                    .icoc_select_i_wen(ch_icoc_select_i_wen),
                    .icoc_action_i(ch_icoc_action_i[11:10]),
                    .icoc_action_i_wen(ch_icoc_action_i_wen),
                    .i_cc_reg(ch_i_cc_reg[5]),
                    .i_cc_reg_wen(ch_i_cc_reg_wen[5]),
                    .irq_enable_i(ch_irq_enable_i[5]),
                    .irq_enable_i_wen(ch_irq_enable_i_wen),
                    .irq_status_i(ch_irq_status_i[5]),
                    .irq_status_i_wen(ch_irq_status_i_wen),
                    .force_oc_i(ch_force_oc_i[5]),
                    .force_oc_i_wen(ch_force_oc_i_wen),
                    .icoc_select_o(ch_icoc_select_o[5]),
                    .icoc_action_o(ch_icoc_action_o[11:10]),
                    .cc_reg_o(ch_cc_reg_o[5]),
                    .irq_enable_o(ch_irq_enable_o[5]),
                    .irq_status_o(ch_irq_status_o[5]),
                    .pin_i(pins_i[5]),
                    .pin_o(pins_o[5])
                    );

   // Channel 6
   scct_channel channel6(
                    .clk(clk),
                    .rst(rst),
                    .counter(counter),
                    .counter_changed(ctr_counter_changed),
                    .icoc_select_i(ch_icoc_select_i[6]),
                    .icoc_select_i_wen(ch_icoc_select_i_wen),
                    .icoc_action_i(ch_icoc_action_i[13:12]),
                    .icoc_action_i_wen(ch_icoc_action_i_wen),
                    .i_cc_reg(ch_i_cc_reg[6]),
                    .i_cc_reg_wen(ch_i_cc_reg_wen[6]),
                    .irq_enable_i(ch_irq_enable_i[6]),
                    .irq_enable_i_wen(ch_irq_enable_i_wen),
                    .irq_status_i(ch_irq_status_i[6]),
                    .irq_status_i_wen(ch_irq_status_i_wen),
                    .force_oc_i(ch_force_oc_i[6]),
                    .force_oc_i_wen(ch_force_oc_i_wen),
                    .icoc_select_o(ch_icoc_select_o[6]),
                    .icoc_action_o(ch_icoc_action_o[13:12]),
                    .cc_reg_o(ch_cc_reg_o[6]),
                    .irq_enable_o(ch_irq_enable_o[6]),
                    .irq_status_o(ch_irq_status_o[6]),
                    .pin_i(pins_i[6]),
                    .pin_o(pins_o[6])
                    );

   // Channel 7
   scct_channel channel7(
                    .clk(clk),
                    .rst(rst),
                    .counter(counter),
                    .counter_changed(ctr_counter_changed),
                    .icoc_select_i(ch_icoc_select_i[7]),
                    .icoc_select_i_wen(ch_icoc_select_i_wen),
                    .icoc_action_i(ch_icoc_action_i[15:14]),
                    .icoc_action_i_wen(ch_icoc_action_i_wen),
                    .i_cc_reg(ch_i_cc_reg[7]),
                    .i_cc_reg_wen(ch_i_cc_reg_wen[7]),
                    .irq_enable_i(ch_irq_enable_i[7]),
                    .irq_enable_i_wen(ch_irq_enable_i_wen),
                    .irq_status_i(ch_irq_status_i[7]),
                    .irq_status_i_wen(ch_irq_status_i_wen),
                    .force_oc_i(ch_force_oc_i[7]),
                    .force_oc_i_wen(ch_force_oc_i_wen),
                    .icoc_select_o(ch_icoc_select_o[7]),
                    .icoc_action_o(ch_icoc_action_o[15:14]),
                    .cc_reg_o(ch_cc_reg_o[7]),
                    .irq_enable_o(ch_irq_enable_o[7]),
                    .irq_status_o(ch_irq_status_o[7]),
                    .pin_i(pins_i[7]),
                    .pin_o(pins_o[7])
                    );

   
   // read   
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  begin
	     readdata <= 0;
	  end
	else
	  begin
	     if (read)
	       begin
		  case (address)
		    `SCCT_CTR: readdata <= counter;
		    `SCCT_PSC: readdata <= ctr_prescaler_o;
		    `SCCT_CTR_IE: readdata <= ctr_irq_enable_o;
		    `SCCT_CTR_IS: readdata <= ctr_irq_status_o;
		    `SCCT_CH_MS: readdata <= {24'b0, ch_icoc_select_o};
		    `SCCT_CH_ACT: readdata <= {16'b0, ch_icoc_action_o};
		    `SCCT_CH_IE: readdata <= {24'b0, ch_irq_enable_o};
		    `SCCT_CH_IS: readdata <= {24'b0, ch_irq_status_o};
		    `SCCT_CH_OCF: readdata <= 32'b0;
		    `SCCT_CH_INP: readdata <= {24'b0, pins_i};
		    `SCCT_CH_OUT: readdata <= {24'b0, pins_o};
		    `SCCT_CH_CCR0: readdata <= ch_cc_reg_o[0];
		    `SCCT_CH_CCR1: readdata <= ch_cc_reg_o[1];
		    `SCCT_CH_CCR2: readdata <= ch_cc_reg_o[2];
		    `SCCT_CH_CCR3: readdata <= ch_cc_reg_o[3];
		    `SCCT_CH_CCR4: readdata <= ch_cc_reg_o[4];
		    `SCCT_CH_CCR5: readdata <= ch_cc_reg_o[5];
		    `SCCT_CH_CCR6: readdata <= ch_cc_reg_o[6];
		    `SCCT_CH_CCR7: readdata <= ch_cc_reg_o[7];
		    default:;
		  endcase // case (address)
	       end
	  end
     end

   
   // write
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  begin
	  end
	else
	  begin
	  end
     end

   // reset write_enable signals
   always @(posedge clk or posedge rst)
     begin
	if (rst)
	  begin
	     ctr_prescaler_i_wen <= 0;
	     ctr_irq_enable_i_wen <= 0;
	     ctr_irq_status_i_wen <= 0;
	     ch_icoc_select_i_wen <= 0;
	     ch_icoc_action_i_wen <= 0;
	     ch_irq_enable_i_wen <= 0;
	     ch_irq_status_i_wen <= 0;
	     ch_force_oc_i_wen <= 0;
	     ch_i_cc_reg_wen[0] <= 0;
	     ch_i_cc_reg_wen[1] <= 0;
	     ch_i_cc_reg_wen[2] <= 0;
	     ch_i_cc_reg_wen[3] <= 0;
	     ch_i_cc_reg_wen[4] <= 0;
	     ch_i_cc_reg_wen[5] <= 0;
	     ch_i_cc_reg_wen[6] <= 0;
	     ch_i_cc_reg_wen[7] <= 0;
	  end
	else
	  begin
	     if (write)
	       begin
		  case (address)
		    //`SCCT_COUNTER:;
		    `SCCT_PSC: begin
		       ctr_prescaler_i <= writedata;
		       ctr_prescaler_i_wen <= 1;
		    end
		    
		    `SCCT_CTR_IE: begin
		       ctr_irq_enable_i <= writedata;
		       ctr_irq_enable_i_wen <= 1;
		    end
		    
		    `SCCT_CTR_IS: begin
		       ctr_irq_status_i <= writedata;
		       ctr_irq_status_i_wen <= 1;
		    end
		    
		    `SCCT_CH_MS: begin
		       ch_icoc_select_i <= writedata[7:0];
		       ch_icoc_select_i_wen <= 1;
		    end
		    
		    `SCCT_CH_ACT: begin
		       ch_icoc_action_i <= writedata[15:0];
		       ch_icoc_action_i_wen <= 1;
		    end
		    
		    `SCCT_CH_IE: begin
		       ch_irq_enable_i <= writedata[7:0];
		       ch_irq_enable_i_wen <= 1;
		    end
		    
		    `SCCT_CH_IS: begin
		       ch_irq_status_i <= writedata[7:0];
		       ch_irq_status_i_wen <= 1;
		    end
		    
		    `SCCT_CH_OCF: begin
		       ch_force_oc_i <= writedata[7:0];
		       ch_force_oc_i_wen <= 1;
		    end
		    
		    `SCCT_CH_CCR0: begin
		       ch_i_cc_reg[0] <= writedata;
		       ch_i_cc_reg_wen[0] <= 1;
		    end
		    
		    `SCCT_CH_CCR1: begin
		       ch_i_cc_reg[1] <= writedata;
		       ch_i_cc_reg_wen[1] <= 1;
		    end
		    
		    `SCCT_CH_CCR2: begin
		       ch_i_cc_reg[2] <= writedata;
		       ch_i_cc_reg_wen[2] <= 1;
		    end
		    
		    `SCCT_CH_CCR3: begin
		       ch_i_cc_reg[3] <= writedata;
		       ch_i_cc_reg_wen[3] <= 1;
		    end
		    
		    `SCCT_CH_CCR4: begin
		       ch_i_cc_reg[4] <= writedata;
		       ch_i_cc_reg_wen[4] <= 1;
		    end
		    
		    `SCCT_CH_CCR5: begin
		       ch_i_cc_reg[5] <= writedata;
		       ch_i_cc_reg_wen[5] <= 1;
		    end
		    
		    `SCCT_CH_CCR6: begin
		       ch_i_cc_reg[6] <= writedata;
		       ch_i_cc_reg_wen[6] <= 1;
		    end
		    
		    `SCCT_CH_CCR7: begin
		       ch_i_cc_reg[7] <= writedata;
		       ch_i_cc_reg_wen[7] <= 1;
		    end
		    
		    default: begin
		    end
		    
		  endcase // case (address)
	       end // if (write)
	     else // !if (write)
	       begin
		  if (ctr_prescaler_i_wen) ctr_prescaler_i_wen <= 0;
		  if (ctr_irq_enable_i_wen) ctr_irq_enable_i_wen <= 0;
		  if (ctr_irq_status_i_wen) ctr_irq_status_i_wen <= 0;
		  if (ch_icoc_select_i_wen) ch_icoc_select_i_wen <= 0;
		  if (ch_icoc_action_i_wen) ch_icoc_action_i_wen <= 0;
		  if (ch_irq_enable_i_wen) ch_irq_enable_i_wen <= 0;
		  if (ch_irq_status_i_wen) ch_irq_status_i_wen <= 0;
		  if (ch_force_oc_i_wen) ch_force_oc_i_wen <= 0;
		  if (ch_i_cc_reg_wen[0]) ch_i_cc_reg_wen[0] <= 0;
		  if (ch_i_cc_reg_wen[1]) ch_i_cc_reg_wen[1] <= 0;
		  if (ch_i_cc_reg_wen[2]) ch_i_cc_reg_wen[2] <= 0;
		  if (ch_i_cc_reg_wen[3]) ch_i_cc_reg_wen[3] <= 0;
		  if (ch_i_cc_reg_wen[4]) ch_i_cc_reg_wen[4] <= 0;
		  if (ch_i_cc_reg_wen[5]) ch_i_cc_reg_wen[5] <= 0;
		  if (ch_i_cc_reg_wen[6]) ch_i_cc_reg_wen[6] <= 0;
		  if (ch_i_cc_reg_wen[7]) ch_i_cc_reg_wen[7] <= 0;
	       end // !if(write)
	  end // else: !if(rst)
     end // always @ (posedge clk or posedge rst)   
   
endmodule // cct
