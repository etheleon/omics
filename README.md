Meta4j
====

## Introduction 

**Meta4J** is a CLI tool for creation of a integrated `-omics` graph database used for microbial community centric analyses.

## Installation

```
git clone --recursive git@github.com:etheleon/omics.git
```

## Usage

### 1 Create DB
```
./configure -d=contig -d=metabolism -d=taxonomy -t=10 -x=$HOME/db/taxonomy -j=$HOME/local/neo4j-community-2.2.2/bin/neo4j-import -c=$HOME/contigs -ftp --user=<keggFTP username> --password=<keggFTP password>
```


### 2 Point to DB

edit the following line in `neo4j-server.properties` to point to database `org.neo4j.server.database.location=</path2/meta4j/out/database/database.db>`

### 3 Start neo4j

```
neo4j start
```

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

### Git Submodules

[keggParser](https://github.com/etheleon/keggParser)

### Software

| Software | Version / Packages / etc                                                                             |
| ----     | ----                                                                                                 |
| Perl     | > 5.10                                                                                               |
| R        | > v3.1.2 is required and the following packages (dplyr igraph XML magrittr)                          |
| NEO4J    | > 2.2 (JAVA; `JAVA_HOME` has to be defined in your `$HOME/.bashrc` else `NEO4J-import` will not work |

#### NEO4J Installation 

##### Install brew

[brew package manager](http://brew.sh/)

| OS    | Instructions                                                                                                            |
| ---   | ---                                                                                                                     |
| OSX   | `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`                             |
| LINUX | [instructions](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-linuxbrew-on-a-linux-vps) |

##### Install neo4j 

```
$ brew install neo4j
```

### External database

* NCBI taxonomy (download on your own)

## Graph Data Model

![workflow](./workflow.png)
