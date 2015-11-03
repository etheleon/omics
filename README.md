[![DOI](https://zenodo.org/badge/19045/etheleon/omics.svg)](https://zenodo.org/badge/latestdoi/19045/etheleon/omics)


## Installation

Clone the repository.

```
$ git clone --recursive git@github.com:etheleon/omics.git
```

Batch import data into single `<database.db>` file.

```
$ ./configure -d=contig -d=metabolism -d=taxonomy -t=10 -x=$HOME/db/taxonomy -j=$HOME/local/neo4j-community-2.2.2/bin/neo4j-import -c=$HOME/contigs -ftp --user=<keggFTP username> --password=<keggFTP password>
```

Edit `org.neo4j.server.database.location=/graph/db` to `org.neo4j.server.database.location=</path2/meta4j/out/database/database.db>` in `neo4j-server.properties`.

Start neo4j

```
$ neo4j start
```

## Dependencies

| Software | Version / Packages / etc                                                                             |
| ----     | ----                                                                                                 |
| Perl     | > 5.10                                                                                               |
| R        | > v3.1.2 is required and the following packages (dplyr igraph XML magrittr)                          |
| neo4j    | > 2.2 (JAVA; `JAVA_HOME` has to be defined in your `$HOME/.bashrc` else `NEO4J-import` will not work |

## How to install NEO4J

[brew](http://brew.sh/)

| OS    | Instructions                                                                                                    |
| ---   | ---                                                                                                             |
| OSX   | `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`                     |
| LINUX | [instructions](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-linuxbrew-on-a-linux-vps)|

neo4j

```
$ brew install neo4j
```

## External datasets

* NCBI taxonomy (download on your own)

## Graph Data Model

![workflow](./workflow.png)
