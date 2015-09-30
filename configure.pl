#!/usr/bin/env perl

#core module
use FindBin qw/$Bin/;
use POSIX;
use Pod::Usage;
use local::lib "$Bin/local";
use File::Path;
use File::Fetch;
use Carp;

if ($#ARGV == -1){pod2usage(
        -message=>"no arguments detected",
        -verbose=>2,
        -output=>\*STDOUT
    )}

#required use cpanfile
use Modern::Perl '2015';
use experimental qw/signatures postderef smartmatch/;
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
my $opt = Getopt::Lucid->getopt(
[
    Param  ("path|p")->default($ENV{"HOME"})->anycase(),
    Param  ("projectName|n")->default("meta4j")->anycase(),
    List   ("dataSets|d")->anycase(),
    Param  ("kegg|k")->default($ENV{"HOME"}."/meta4j")->needs("dataSets")->anycase(),
    Param  ("taxonomy|x")->needs("dataSets")->anycase(),
    Param  ("contig|c")->needs("dataSets")->anycase(),
    List   ("memory|m")->anycase(),
    Param  ("threads|t")->default(1)->anycase(),
    Switch ("ftp|f"),
    Param  ("user|u")->needs("ftp")->anycase(),
    Param  ("password|w")->needs("ftp")->anycase(),
    Switch ("help|h")->anycase()
]);

pod2usage(-verbose=>2) if $opt->get_help;

$opt->validate({ requires => ['dataSets'] });
my @datasets = $opt->get_dataSets;
my @validDatasets = qw/taxonomy contig metabolism/;

foreach (@datasets)
{
    lc $_ ~~ @validDatasets ? say "##\tincluding $_ dataset" : die "$_ is not a supported dataset\n";
}
@datasets = map {lc $_} @datasets;

##################################################
#Documentation
##################################################

=pod

=head1 NAME

 meta4j - constructing neo4j batch-import env

=head1 SYNOPSIS

 perl configure.pl [options...]

 example: configure.pl --dataSets=contig --dataSets=metabolism --dataSets=taxonomy --threads=10 --contig=/home/user/reDiamond/out/miscDB/ --kegg=/path/to/kegg/ftp --taxonomy=/path/to/db/taxonomy_12sept2014/

=head1 OPTIONS

=over 4

=item --projectName -n -N

name of the folder storing all projects

=item --path -p -P

root dir to place base import files (excluding the projectName). default path is set to the $home/meta4j

=item --threads -t

The number of threads to use when preparing the input files
default is 1;
Used for the KEGG parsing

=item --datasets -d -D (Compulsory)

list of datasets used for this graphdb. for multiple datasets:
eg. --datasets=taxonomy --datasets=readabundance (not ready) --dataset=metabolism --dataset=contig

=item --taxonomy -x -X

path pointing to NBCI taxonomy
uses to files: 1. nodes.dmp and 2. names.dmp

=item --contig -c -C

path to folder containing nodes and relationships for contigs
eg. contig2tax contig2ko

=item --kegg -k -K

path to download kegg files if not using FTP EG. if --path=/home/user --projectname=meta4j then --kegg=/home/user/meta4j

=item --ftp -f

Download neccessary kegg files

=item --user -u

username for keggFTP

=item --password -w

password for keggFTP

=item --help -h -H

help

=back

=head1 DESCRIPTION

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

# 1. Create directories
    my $installdir = join "/", $opt->get_path, $opt->get_projectName;
    #root directory
    mkpath($installdir);
    #sub directories
    mkpath("$installdir/$_") foreach qw/out\/nodes out\/rels out\/database misc scripts/;


# 2. Create batch.properties file

open my $config, ">", "$installdir/batch.properties";
&writeBatch(\@datasets);

# 3 configure makeXX.sh files
# metabolism
foreach my $dataset (@datasets)
{
    if($dataset =~ m/metabolism/i)
    {
        my $keggPath;
        if ($opt->get_ftp){
            my $username = $opt->get_user;
            my $password = $opt->get_password;

            #my $keggPath = $opt->get_kegg;
            $keggPath = $installdir;
            mkpath($keggPath);

            foreach (qw(genes/ko.tar.gz ligand/compound.tar.gz ligand/glycan.tar.gz xml/kgml/metabolic/ko.tar.gz)) {
                say "Downloading $_";
                `curl --create-dirs -o $keggPath/$_ ftp://$username:$password\@ftp.bioinformatics.jp/kegg/$_`;
            };
                `find $keggPath -name "*.tar.gz" -execdir tar zxf "{}" \\;`;
        }else{
            $keggPath = $opt->get_kegg;
        }

        &configureMetab($installdir, $keggPath);
        #Check if the files are ready if not ask user to download and come back again
        unless(-e "$keggPath/genes/ko/ko" & -e "$keggPath/ligand/compound/compound" & -e "$keggPath/ligand/glycan/glycan" & -e "$keggPath/xml/kgml/metabolic/ko.tar.gz")
        {
            croak "You do not have the necessary KEGG files";
        }
        system "bash $installdir/scripts/make_metabolism.sh";
    }
    if($dataset =~ m/contig/i)
    {
        my $contigPath = $opt->get_contig;
        system "cp $contigPath/nodes/* $installdir/out/nodes/";
        system "cp $contigPath/rels/* $installdir/out/rels/";
    }
    if($dataset =~ m/taxonomy/i)
    {
        my $taxonPath = $opt->get_taxonomy;
        &configureTaxonomy($installdir, $taxonPath);
        #Check if the files are ready if not ask user to download and come back again
        unless(-e "$taxonPath/taxdump.tar.gz")
        {
            croak "You do not have the necessary NCBI taxonomy files";
        }
        system "bash $installdir/scripts/make_taxonomy.sh";
    }
}

# 4 MAKE

# Batch-Import
# this step is very worrying
`curl -o $installdir/batch_importer_22.zip https://dl.dropboxusercontent.com/u/14493611/batch_importer_22.zip`;
`unzip -d $installdir $installdir/batch_importer_22.zip`;

make($installdir);

#Functions
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
    say $makeDB qq(./import.sh $output $allnodes $allrels);
}

sub configureTaxonomy($installDIR, $taxFTP){
    open my $makeTax    , "<" , "script/make_taxonomy.sh";
    open my $makeTaxNew , ">" , "$installDIR/scripts/make_taxonomy.sh";
    while(<$makeTax>){
        say $makeTaxNew "targetdir=$installDIR"           if /^targetdir=/;
        say $makeTaxNew "taxodump=$taxFTP"               if /^taxodump=/;
        print $makeTaxNew $_                              unless /(^targetdir)|(^taxodump)/;
    }
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
