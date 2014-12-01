#!/usr/bin/env perl

use strict;
use v5.10;
use autodie;

my %kohash;

open my $allkos, "<", "misc/ko_nodedetails";
while(my $entry = <$allkos>)
{
    my $ko = (split /\t/, $entry)[0];
    $kohash{$ko} = $entry;
}

open my $metabkos, "<", "out/nodes/newkonodes";
while(my $entry = <$metabkos>)
{
    unless($. == 1)
    {
        my $ko = (split /\t/, $entry)[0];
        delete $kohash{$ko};
    }
}
close $metabkos;

open my $final, ">>", "out/nodes/newkonodes";
print $final $kohash{$_} foreach (keys %kohash);


#allKOs  = read.table("misc/ko_nodedetails",sep="\t",comment.char="", h=F, fill=T)
#metabKO = read.table("out/nodes/newkonodes")
