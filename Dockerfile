#################################################################
# Dockerfile
#
# Version:          0.0.1
# Software:         omics
# Software Version: 0.0.1
# Description:      Dockerfile as a executable to generate 
# Website:          https://github.com/etheleon/pAss
# Tags:             Genomics Metagenomics
# Base Image:       ubuntu
#################################################################

# Build image with:  docker build -t etheleon/omics:0.1

FROM ubuntu

#Basic###############################
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential && \
    apt-get install -y libperlio-via-dynamic-perl && \
    apt-get install -y curl && \
    apt-get install -y make && \
    apt-get install -y git && \
    apt-get install -y libxml2-dev && \
    apt-get clean

#Java -NEO4J ###############################
RUN apt-get install -y  software-properties-common && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt-get clean

#OMICS
RUN git clone --recursive https://github.com/etheleon/omics.git /tmp/omics
WORKDIR /tmp/omics

RUN curl -L https://cpanmin.us | perl - App::cpanminus && \
    cpanm --installdeps .

RUN apt-get install -y r-base

RUN R -e 'install.packages("dplyr", repos="http://cran.bic.nus.edu.sg/")'
RUN R -e 'install.packages("igraph", repos="http://cran.bic.nus.edu.sg/")'
RUN R -e 'install.packages("XML", repos="http://cran.bic.nus.edu.sg/")'
VOLUME ["/data/contigs", "/data/output", "/data/taxonomy", "/data/kegg", "/data/neo4j", "/w"]
ENTRYPOINT ["/tmp/omics/.configure_prepack","-d=metabolism", "-d=taxonomy","-x=/data/taxonomy","--kegg=/data/kegg", "-j=/data/neo4j/bin/neo4j-import"]
CMD ["-d=contig", "--threads 1","-n=omics", "-c=/w/simulation_fr_the_beginning/reAssemble/everybodyelse/out/diamond/contigs"]

#################### INSTALLATION ENDS ##############################
MAINTAINER Wesley GOI <wesley@bic.nus.edu.sg>
