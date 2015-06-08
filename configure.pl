#!/usr/bin/env perl

#core module
use FindBin qw/$Bin/;
use POSIX;
use Pod::Usage;
use local::lib "$Bin/local";
use File::Path;
use File::Fetch;
use Carp;

#required use cpanfile
use Modern::Perl '2015';
use experimental qw/signatures postderef/;
use Getopt::Lucid qw( :all );
use autodie;

my $keyStore =
{
    taxonomy    => ["ncbitaxid"],
    metabolism  => ["koid","cpdid","pathwayid"],
    contig      => ["contigid"]
};

##################################################
#Arguments
##################################################

my @specs = (
    Param  ("path|P|p")->default($ENV{"HOME"}),
    Param  ("projectName|N|n")->default("meta4j"),
    List   ("dataSets|d|D"),
    Param  ("kegg|K|k")->needs("dataSets"),
    Param  ("contig|c|C")->needs("dataSets"),
    List   ("memory|M|m"),
    Param  ("threads|T|t")->default(1),
    Switch ("help|H|h")
);

my $opt = Getopt::Lucid->getopt( \@specs );
pod2usage(-verbose=>2) if $opt->get_help;

$opt->validate({ requires => ['dataSets'] });

##################################################
#Documentation
##################################################

=pod

=head1 name

 meta4j - constructing neo4j batch-import env

=head1 synopsis

 perl configure.pl [options...]

=head1 options

=over 8

=item b<--path -p -P>
root dir to place base import files. default path is set to the $home/meta4j

=item b<--datasets -d -D>
list of datasets used for this graphdb. for multiple datasets:
eg. --datasets=taxonomy --datasets=readabundance --dataset=metabolism|<path to root dir of kegg>

=item b<--projectName -n -N>
name of the folder storing all projects

=item b<--neo4j -j -J>
path to neo4j's batch importer

=item b<--kegg -k -K>
path to the kegg FTP

=item b<--contig -c -C>
path to folder containing nodes and relationships for contigs
eg. contig2tax contig2ko

=item b<--help -h -H>
help

=back

=head1 description

b<configure> sets up folder structure for use by makexx.sh files
for data warehousing and analysis of meta-omics datasets
together with in meta4j's analytics pipeline <r package metacom>.

later requires following r packages from github:
- 'etheleon/metamaps'.

=head1 author

Wesley GOI
--
please report bugs to:
wesley@bic.nus.edu.sg

=head1 version

1.00

=cut



# 1. create directories
my $installdir = join "/", $opt->get_path, $opt->get_projectName;
    #root directory
    mkpath($installdir);
    #sub directories
    map { mkpath("$installdir/$_") } qw/out\/nodes out\/rels out\/database misc scripts/;

# 2. create batch.properties file
my @datasets = $opt->get_dataSets;
open my $config, ">", "$installdir/batch.properties";
&writeBatch(\@datasets);

# 3 configure makeXX.sh files
# metabolism
foreach my $dataset (@datasets)
{
    if($dataset =~ m/metabolism/)
    {
        my $keggftp = $opt->get_kegg;
        &configureMetab($installdir, $keggftp);
        #Check if the files are ready if not ask user to download and come back again
        unless(-e "$keggftp/genes/ko/ko" & -e "$keggftp/ligand/compound/compound" & -e "$keggftp/ligand/glycan/glycan" & -e "$keggftp/xml/kgml/metabolic/ko.tar.gz")
        {
            croak "You do not have the necessary KEGG files";
        }
        system "bash $installdir/scripts/make_metabolism.sh";
    }
    if($dataset =~ m/contig/)
    {
        my $contigPath = $opt->get_contig;
        system "cp $contigPath/nodes/* $installdir/out/nodes/";
        system "cp $contigPath/rels/* $installdir/out/rels/";
    }
}

# 4 MAKE

# Batch-Import
system "curl -o $installdir/batch_importer_22.zip https://dl.dropboxusercontent.com/u/14493611/batch_importer_22.zip";
system "unzip -d $installdir $installdir/batch_importer_22.zip";


make($installdir);

sub make($installDIR)
{
    open my $makeDB, ">", "$installDIR/makeDB";
    my $time = strftime("%d%b%Y-%H%M", localtime);
    my $output          = "$installDIR/out/database/$time"."_altimit.db";
    my $allnodes        = join ",",<$installDIR/out/nodes/*>;
    my $allrels         = join ",",<$installDIR/out/rels/*>;
    #Not using the mvn
#    say $makeDB qq(mvn clean compile exec:java -Dexec.mainClass="org.neo4j.batchimport.Importer" -Dexec.args="'$batchproperties' '$output' '$allnodes' '$allrels'");
#    #Binary
    say $makeDB qq(import.sh $output $allnodes $allrels);
}


sub configureMetab($installDIR, $keggFTP){
    open my $makeMetab, "<", "script/make_metabolism.sh";
    open my $makeMetabNew, ">", "$installDIR/scripts/make_metabolism.sh";
    while(<$makeMetab>){
        say $makeMetabNew "targetdir=$installDIR"           if /^targetdir=/;
        say $makeMetabNew "keggdump=$keggFTP"               if /^keggdump=/;
        say $makeMetabNew "meta4jHome=$keggFTP"             if /^meta4jHome=/;
        say $makeMetabNew "cores=1"                         if /^cores=/;
        print $makeMetabNew $_                              unless /(^targetdir)|(^keggdump)|(^meta4jHome)|(^cores)/;
    }
}

#Functions
sub writeBatch($dataSets, @pro)
{
    #Write Index
    foreach my $dataset ($dataSets->@*)
    {
        $dataset = (split /\|/, $dataset)[0];
        my $isSpecified = exists $keyStore->{$dataset};
        if($isSpecified)
        {
            say $config "batch_import.node_index.$_=exact" for $keyStore->{$dataset}->@*
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

#Indexes - Full list
# batch_import.node_index.koid                       = exact
# batch_import.node_index.cpdid                      = exact
# batch_import.node_index.pathwayid                  = exact
# batch_import.node_index.ncbitaxid                  = exact
# batch_import.node_index.readID                     = exact
# batch_import.node_index.contigid                   = exact

#Total memory ~ this configuration can proivde more 1Gb
neostore.propertystore.db.index.keys.mapped_memory = 5M
neostore.propertystore.db.index.mapped_memory      = 5M
neostore.propertystore.db.mapped_memory            = 200M
neostore.propertystore.db.strings.mapped_memory    = 200M

neostore.nodestore.db.mapped_memory                = 200M
neostore.relationshipstore.db.mapped_memory        = 500M

batch_array_separator                              = \\|
