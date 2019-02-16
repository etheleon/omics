[![DOI](https://zenodo.org/badge/19045/etheleon/omics.svg)](https://zenodo.org/badge/latestdoi/19045/etheleon/omics)
[![](https://images.microbadger.com/badges/image/etheleon/metaomicsgraphdb.svg)](https://microbadger.com/images/etheleon/metaomicsgraphdb "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/etheleon/metaomicsgraphdb.svg)](https://microbadger.com/images/etheleon/metaomicsgraphdb "Get your own version badge on microbadger.com")

## Graph Data Model

![workflow](newGraphDB.png)

<!-- vim-markdown-toc GFM -->

* [Create omics DB](#create-omics-db)
* [Dependencies](#dependencies)
  * [External datasets](#external-datasets)
* [Reading and serving an existing Omics DB (with Docker)](#reading-and-serving-an-existing-omics-db-with-docker)
  * [(Optional) Downloading DB](#optional-downloading-db)
    * [Download S3 CLI tool](#download-s3-cli-tool)
    * [Authenticate](#authenticate)
    * [Run the Docker container](#run-the-docker-container)
  * [Running wo Docker](#running-wo-docker)

<!-- vim-markdown-toc -->


## Create omics DB

Clone the repository.

```
$ git clone --recursive git@github.com:etheleon/omics.git
```

Batch import data into single `<database.db>` file.

```
$ ./configure -d=contig -d=metabolism -d=taxonomy -t=10 \
    -x=$HOME/db/taxonomy \
    -j=$HOME/local/neo4j-community-2.2.2/bin/neo4j-import \
    -c=$HOME/contigs \
    -ftp --user=<keggFTP username> --password=<keggFTP password>
```

## Dependencies

| Software | Version / Packages / etc                                                                             |
| ----     | ----                                                                                                 |
| Perl     | > 5.10                                                                                               |
| R        | > v3.1.2 is required and the following packages (dplyr igraph XML magrittr)                          |
| neo4j    | 2.2.3 (JAVA; `JAVA_HOME` has to be defined in your `$HOME/.bashrc` else `NEO4J-import` will not work |
| [Docker](https://docs.docker.com/engine/installation/)| any version |

### External datasets

* NCBI taxonomy (download on your own)
* KEGG FTP (optional)

## Reading and serving an existing Omics DB (with Docker)

The following highlights how you will set up MetamapsDB using Docker.

### (Optional) Downloading DB

The following details how to download and run a specific omicsDB mentioned in my thesis.

- [ ] Database created by the `.confgiure` script
- [ ] [s3cmd](https://github.com/s3tools/s3cmd) - for downloading the DB from DigitalOcean

> The files are stored in `digitalocean spaces`.

#### Download S3 CLI tool

```bash
pip install -y s3cmd
```

#### Authenticate

(contact author, myself, for ACCESS_KEY and SECRET)

```bash
s3cmd --configure

# namespace
# sgp1.digitaloceanspaces.com

# URL template
# %(bucket)s.nyc3.digitaloceanspaces.com
```

Refer to the [docs](https://www.digitalocean.com/docs/spaces/resources/s3cmd/) for more about using `s3cmd`

```bash
ROOTDIR=$HOME/metamapsdb
mkdir $ROOTDIR
BUCKET=metamaps
KEY=neo4j/allKOS_fullnr.tar.gz.gpg
PATH=s3://${BUCKET}/${KEY}
s3cmd get $PATH $ROOTDIR
```

Because it's encrypted, we have to decrypt before decompressing

```bash
# password is found in chapter1's .lyx file
FILE=allKOS_fullnr.tar.gz
gpg --output $FILE --decrypt ${FILE}.gpg


tar zvxf $FILE
```

#### Run the Docker container

```bash
# Set location to where you've downloaded the
# metamaps database
DATA=$HOME/metamapsdb/allKOS_fullnr/

# Start NEO4J
docker run \
    --name omics \
    --publish=7474:7474 --publish=7687:7687 \
    --volume=$DATA:/data \
    etheleon/omics-neo4j-container
```

Database needs to be mounted, make sure you have the following folder structure. where graph.db is the output

```
/DATA
└── graph.db
    ├── bad.log
    ├── index
    ├── messages.log
    ├── neostore
    ├── neostore.counts.db.a
    ├── neostore.counts.db.b
    ├── neostore.id
    ├── neostore.labeltokenstore.db
    ├── neostore.labeltokenstore.db.id
    ├── neostore.labeltokenstore.db.names
    ├── neostore.labeltokenstore.db.names.id
    ├── neostore.nodestore.db
    ├── neostore.nodestore.db.id
    ├── neostore.nodestore.db.labels
    ├── neostore.nodestore.db.labels.id
    ├── neostore.propertystore.db
    ├── neostore.propertystore.db.arrays
    ├── neostore.propertystore.db.arrays.id
    ├── neostore.propertystore.db.id
    ├── neostore.propertystore.db.index
    ├── neostore.propertystore.db.index.id
    ├── neostore.propertystore.db.index.keys
    ├── neostore.propertystore.db.index.keys.id
    ├── neostore.propertystore.db.strings
    ├── neostore.propertystore.db.strings.id
    ├── neostore.relationshipgroupstore.db
    ├── neostore.relationshipgroupstore.db.id
    ├── neostore.relationshipstore.db
    ├── neostore.relationshipstore.db.id
    ├── neostore.relationshiptypestore.db
    ├── neostore.relationshiptypestore.db.id
    ├── neostore.relationshiptypestore.db.names
    ├── neostore.relationshiptypestore.db.names.id
    ├── neostore.schemastore.db
    ├── neostore.schemastore.db.id
    ├── neostore.transaction.db.21
    ├── neostore.transaction.db.22
    ├── neostore.transaction.db.23
    ├── neostore.transaction.db.24
    ├── neostore.transaction.db.25
    ├── neostore.transaction.db.26
    ├── neostore.transaction.db.27
    ├── rrd
    ├── schema
    └── store_lock
```

After starting the container navigate to `127.0.0.1:7474` on your machine's browser

### Running wo Docker

You'll need to edit config to point to the location of the database:

For example, change the path in the settings file `neo4j-server.properties` from `org.neo4j.server.database.location=/graph/db` to `org.neo4j.server.database.location=</path2/meta4j/out/database/database.db>` in .


![login](./login.png)
![in](./check.png)
