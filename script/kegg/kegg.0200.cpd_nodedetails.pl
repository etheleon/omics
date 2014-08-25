#!/usr/bin/env perl

use strict;
die "USAGE: $0 KEGGftp/ligand/compound/compound KEGGftp/ligand/glycan/glycan " unless $#ARGV == 1;

$/ = '///';

open COMPOUND, $ARGV[0] || die $!;
while(<COMPOUND>) { 
    my ($cpd) = $_ =~ /ENTRY\s+(C\d{5})/xsm;
    /NAME\s+(?<NAME> .*?)\n		#I'm just taking the first symbol name associated with this
	/xsm;
    print "cpd:$cpd\t$+{NAME}\n" unless (length($cpd) == 0)
}
close COMPOUND;

open GLYCAN, $ARGV[1] || die $!;
while(<GLYCAN>) { 
    my ($cpd) = $_ =~ /ENTRY\s+(G\d{5})/xsm;
    /NAME\s+(?<NAME> .*?)\n		#I'm just taking the first symbol name associated with this
	/xsm;
    print "gl:$cpd\t$+{NAME}\n" unless (length($cpd) == 0)
}
close GLYCAN;
