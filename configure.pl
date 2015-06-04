#!/usr/bin/env perl

use Modern::Perl '2015';
use experimental qw/signatures postderef/;
use Pod::Usage;
use File::Path;
use autodie;
use Getopt::Lucid qw( :all );

my @specs = (
    Param  ("path|P|p")->default($ENV{"HOME"}),
    Param  ("projectName|N|n")->default("meta4j"),
    List   ("dataSets|d|D"),
    List   ("memory|M"),
    Switch ("help|h")
);

my $keyStore = {
            taxonomy    => ["ncbitaxid"],
            metabolism  => ["koid","cpdid","pathwayid"],
            contig      => ["contigid"]
        };

my $opt = Getopt::Lucid->getopt( \@specs );
pod2usage(-verbose=>2) if $opt->get_help;
$opt->validate({ requires => ['dataSets'] });

=pod

=head1 NAME

 Meta4j - Constructing NEO4J batch-import ENV

=head1 SYNOPSIS

 perl configure.pl [options...]

=head1 OPTIONS

=over 8

=item B<-path -P -p>
root dir to place base import files. Default path is set to the $HOME/meta4j

=item B<-dataSets -D -d>
list of datasets used for this graphDB. For multiple datasets:
eg. --dataSets=taxonomy --dataSets=readAbundance

=item B<-help -H -h>

=back

=head1 DESCRIPTION

B<Configure> Sets up folder structure for use by makeXX.sh files
for data warehousing and analysis of Meta-omics datasets
together with in Meta4j's analytics pipeline <R package MetaCom>.

Later requires following R packages from github:
- 'etheleon/metamaps'.

=head1 AUTHOR

Wesley GOI
--
wesley@bic.nus.edu.sg

=head1 VERSION

1.00

=cut

# 1. Create directories
my $installDIR = join "/", $opt->get_path, $opt->get_projectName;
    #Root Directory
    mkpath($installDIR);
    #Sub Directories
    map { mkpath("$installDIR/$_") } qw/nodes rels database misc config/;

# 2. Create batch.properties files
my @dataSets = $opt->get_dataSets;
open my $config, ">", $installDIR."/config/batch.properties";
writeBatch(\@dataSets);

sub writeBatch($dataSets, @pro)
{
    #Write Index
    foreach my $dataset ($dataSets->@*)
    {
        my $isSpecified = exists $keyStore->{$dataset};
        if($isSpecified)
        {
            say $config "batch_import.node_index.$_" for $keyStore->{$dataset}->@*
        }
    }
    #Wite others
    while(<DATA>){print $config $_ if !/^\#/}
}

__DATA__
#Basic configurations

#Print out the effective Neo4j configuration after startup
dump_configuration                                 = false

#The type of cache to use for nodes and relationships, one of [weak, soft, none]
#See documentation for further details:
#   http://neo4j.com/docs/stable/configuration-caches.html#_object_cache
cache_type                                         = none
use_memory_mapped_buffers                          = true

#Indexes
#batch_import.node_index.koid                       = exact
#batch_import.node_index.cpdid                      = exact
#batch_import.node_index.pathwayid                  = exact
#batch_import.node_index.ncbitaxid                  = exact
#batch_import.node_index.readID                     = exact
#batch_import.node_index.contigid                   = exact

#Total memory ~ this configuration can proivde more 1Gb
neostore.propertystore.db.index.keys.mapped_memory = 5M
neostore.propertystore.db.index.mapped_memory      = 5M
neostore.propertystore.db.mapped_memory            = 200M
neostore.propertystore.db.strings.mapped_memory    = 200M

neostore.nodestore.db.mapped_memory                = 200M
neostore.relationshipstore.db.mapped_memory        = 500M

batch_array_separator                              = \\|
