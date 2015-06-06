Meta4j
====

## Introduction 

**Meta4J** is a CLI tool for creation of a integrated `-OMICS` graph database used for data warehousing a integrated `-omics` microbial communities project.
It is designed to be modular, from simple projects involving only genomics data to multiple `-omics` datasets.

Meta4j was created to address issues surrounding the storage and integration of increasingly complexity in biological datasets of the following origins particularly in 
relation to metabolism:

* Genomics
* Transcriptomics
* Metabolomics
* Proteomics
* Lipidomics

Meta4j serves as a customized database for the series of analytic tools designed by Wesley **GOI**, Chao **XIE** and Peter *LITTLE*. 

## Publication:


## General 

Scripts are organised into 2 categories:

1. The generation of tables files `relationships` and `nodes` for batch insertion into Neo4j graph database.
2. Creation and starting of neo4j graph database.

**NOTE**: For accessing the database and functions used in the analytical pipeline use the `MetamapsDB` R package from `etheleon/metamaps`.

## NEO4J

Install [NEO4J](http://neo4j.com/download/)

[tarball for neo4j community OSX/linux](http://info.neotechnology.com/download-thanks.html?edition=community&release=2.3.0-M01&flavour=unix&_ga=1.119121161.1401797244.1431421615)

## Data Components

- KEGG (Functional Database)
- NCBI’s Taxonomy database
- Relative abundance (gDNA and cDNA)
- CONTIG data (diversity sampling using *pAss*)


### KEGG (Functional Database)

Generated from 3 files from the KEGG database:

```
$ curl --create-dirs -o kegg/genes/ko.tar.gz              "ftp://<user>:<password>@ftp.bioinformatics.jp/kegg/genes/ko.tar.gz"
$ curl --create-dirs -o kegg/ligand/compound.tar.gz       "ftp://<user>:<password>@ftp.bioinformatics.jp/kegg/ligand/compound.tar.gz"
$ curl --create-dirs -o kegg/xml/kgml/metabolic/ko.tar.gz "ftp://<user>:<password>@ftp.bioinformatics.jp/kegg/xml/kgml/metabolic/ko.tar.gz"
```

1. Ortholog details are retrieved by parsing `genes/ko/ko`.
2. Compound details are retrieved by parsing `ligand/compound/compound` and `ligand/glycan/glycan`.
3. Reaction details are retrieved by parsing `xml/kgml/metabolic/ko/<pathway>.xml` files

### Taxonomy

this requires a prototype DB to be generated first, XC's taxon list doesnt have a taxid, I need to associate taxid with name.

redundancy in taxonomy, 
option to just include things in archaea and bacteria


### Relative Abundance


### Contig Data

Requires the contigs to be provided in the following manner

#### Nodes

```
contig:string:contigid  cDNAFreq:double  cDNAFPKM:double    gDNAFreq:double  gDNAFPKM:double      l:label
K00001:contig00002      1                0.735646998316564  535              8.59366116025439     contigs
K00001:contig00004      1                0.847019850651342  66               1.22065378091888     contigs
K00001:contig00005      1                0.864235701274337  18               0.33967195012266     contigs
K00001:contig00007      1                1.00283954015796   33               0.722604007100565    contigs
K00001:contig00008      2                1.9869344160139    9                0.195232008715361    contigs
K00001:contig00010      2                2.22619876977473   105              2.5519855938535      contigs
K00001:contig00011      1                1.10156467623568   239              5.74861043048696     contigs
K00001:contig00014      2                2.08433316189693   45               1.02401102610508     contigs
K00001:contig00015      1                1.05248506194796   46               1.05713085467217     contigs
```

#### Edges

contig2ko
```
contig:string:contigid  ko:string:koid
K00001:contig00002      ko:K00001
K00001:contig00004      ko:K00001
K00001:contig00005      ko:K00001
K00001:contig00007      ko:K00001
K00001:contig00008      ko:K00001
K00001:contig00010      ko:K00001
K00001:contig00011      ko:K00001
K00001:contig00014      ko:K00001
K00001:contig00015      ko:K00001
```


## Downloading latest database

`USAGE: download.pl`

## Usage

```
$ ./configure.sh --kegg=<path/to/keggDB/> --ncbiTaxonomy=<path/to/ncbi/taxonomy>
make.pl

eg. 
$ ./configure.pl -d=taxonomy -d=contig -d=metabolism -kegg=/export2/home/uesu/KEGG/KEGG_SEPT_2014/ -c=out/miscDB
```

## Prerequisites

### Abundance data
Users will have to run a blastx aligner (eg. [rapsearch2](http://omics.informatics.indiana.edu/mg/RAPSearch2/), [diamond](https://github.com/bbuchfink/diamond/)) 
against a protein sequence database for detecting remote homologies.

### Installation`
Using `linuxbrew` is highly recommended for either rapsearch2 or diamond

If you’re building diamond on a older server please mail the author at wesley@bic.nus.edu.sg for the binary.

### Perl

1. v5.20.2 is required: 
   Please use [tokuhirom/plenv](https://github.com/tokuhirom/plenv) to install local perl 
   and **CPANMINUS**, a perl package manager with `curl -L https://cpanmin.us | perl - App::cpanminus` 

2. Install dependencies
    * Install Carton using `$ cpanm Carton`.
    * run `carton` in package’s root directory

### R

1. v3.1.1 is required

2. Install dependencies using 

# BUG
* pathways include node `pathway pathway.name    pathway` which isnt suppose to be inside
* non-metabolic pathways eg. 2-component system arent included. 
