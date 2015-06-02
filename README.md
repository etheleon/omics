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

Publication:

Scripts are organised into 2 categories:

1. The generation of tables files `relationships` and `nodes` for batch insertion into Neo4j graph database.
2. Creation and starting of neo4j graph database.

**NOTE**: For accessing the database and functions used in the analytical pipeline use the `MetamapsDB` R package from `etheleon/metamaps`.

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

## Downloading latest database

`USAGE: download.pl`

## Usage

```
./configure.sh --neo4j=<path/to/neo4j-shell> --kegg=<path/to/keggDB/> --ncbiTaxonomy=<path/to/ncbi/taxonomy>
make.pl
```

## Prerequisites

### Abundance data
Users will have to run a blastx aligner (eg. [rapsearch2](omics.informatics.indiana.edu/mg/RAPSearch2/), [diamond](https://github.com/bbuchfink/diamond/)) 
against a protein sequence database for detecting remote homologies.

### Installation
Using `linuxbrew` is highly recommended for either rapsearch2 or diamond

If you’re building diamond on a older server please mail the author at wesley@bic.nus.edu.sg for the binary.

### Perl

Minimal v5.10 is required

# BUG

* pathways include node `pathway pathway.name    pathway` which isnt suppose to be inside
* non-metabolic pathways eg. 2-component system arent included. 



