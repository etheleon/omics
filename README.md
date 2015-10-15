Meta4j
====

## Introduction 

**Meta4J** is a CLI tool for creation of a integrated `-omics` graph database used for microbial community centric analyses.

## Graph Data Model

![workflow](./workflow.png)

## Installation

```
git clone --recursive git@github.com:etheleon/omics.git
```


## Usage

```
./configure -d=contig -d=metabolism -d=taxonomy -t=10 -x=$HOME/db/taxonomy -j=$HOME/local/neo4j-community-2.2.2/bin/neo4j-import -c=$HOME/contigs -ftp --user=<keggFTP username> --password=<keggFTP password>
```

**NOTE**: For accessing the database and functions used in the analytical pipeline use the `MetamapsDB` R package from [MetamapsDB](https://github.com/etheleon/metamaps).

Edit `neo4j-server.properties` and point database to `<outputDIR/out/database/<database.db>`

## Components

- KEGG (Functional Database)
    * Compounds
    * Kegg Orthologs
    * Modules
    * Pathways

- NCBI’s Taxonomy database
- Relative abundance (gDNA and cDNA)
- CONTIG data (diversity sampling using *pAss*)

## Dependencies

### Submodules

[keggParser](https://github.com/etheleon/keggParser). 

### Software

| Software | Version / Packages / etc                                                                             |
| ----     | ----                                                                                                 |
| Perl     | > 5.10                                                                                               |
| R        | > v3.1.2 is required and the following packages (dplyr igraph XML magrittr)                          |
| NEO4J    | > 2.2 (JAVA; `JAVA_HOME` has to be defined in your `$HOME/.bashrc` else `NEO4J-import` will not work |

#### NEO4J Installation 

brew package manager

```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)”
```

**NOTE** use linuxbrew if using a linux machine

```
brew install neo4j
```

### External database

* NCBI taxonomy
