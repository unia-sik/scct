#!/usr/bin/perl
# $Id: mkch.pl 2 2015-06-15 13:52:02Z fkluge $
# Create channel declarations

use strict;
use warnings;


my ($nChannels) = @ARGV;

if (not defined $nChannels) {
    die "Need number of channels to create!\n";
}

if (!($nChannels =~ /^\d+$/)) {
    die "Script needs a positive integer\n";
}

print "   // Channel definitions were created with $0\n";

my @channel = <DATA>;

for (my $i = 0; $i < $nChannels; $i++) {
    print "\n   // Channel $i\n";
    my $N = $i;
    my $TN = $i * 2;
    my $TNPO = $TN + 1;
    foreach my $line (@channel) {
	my $out = $line;
	$out =~ s/(\$\w+(?:::\w+)*)/"defined $1 ? $1 : ''"/gee;
	print $out;
    }
}


__DATA__
   scct_channel channel$N(
		    .clk(clk),
		    .rst(rst),
		    .counter(counter),
                    .counter_changed(ctr_counter_changed),
		    .icoc_select_i(ch_icoc_select_i[$N]),
		    .icoc_select_i_wen(ch_icoc_select_i_wen),
		    .icoc_action_i(ch_icoc_action_i[$TNPO:$TN]),
		    .icoc_action_i_wen(ch_icoc_action_i_wen),
		    .i_cc_reg(ch_i_cc_reg[$N]),
		    .i_cc_reg_wen(ch_i_cc_reg_wen[$N]),
		    .irq_enable_i(ch_irq_enable_i[$N]),
		    .irq_enable_i_wen(ch_irq_enable_i_wen),
		    .irq_status_i(ch_irq_status_i[$N]),
		    .irq_status_i_wen(ch_irq_status_i_wen),
		    .force_oc_i(ch_force_oc_i[$N]),
		    .force_oc_i_wen(ch_force_oc_i_wen),
		    .icoc_select_o(ch_icoc_select_o[$N]),
		    .icoc_action_o(ch_icoc_action_o[$TNPO:$TN]),
		    .cc_reg_o(ch_cc_reg_o[$N]),
		    .irq_enable_o(ch_irq_enable_o[$N]),
		    .irq_status_o(ch_irq_status_o[$N]),
		    .pin_i(pins_i[$N]),
		    .pin_o(pins_o[$N])
		    );
