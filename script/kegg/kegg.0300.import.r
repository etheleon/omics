#!/usr/bin/env Rscript
library(dplyr)
library(magrittr)
library(XML)
library(parallel)
args=commandArgs(T)

#' #Metabolism

ftpAddress = 'ftp://ftp.bioinformatics.jp/kegg/'
#wget --user=username --password=password -P ~/KEGG/KEGG_JAN_2014 -m ftp://ftp.bioinformatics.jp/kegg/

#args=c(
#"~/KEGG/KEGG_SEPT_2014", #KEGG root FTP directory
#"~/db/neo4j/misc"        #cpd and node data directory
#)

#TODO: Adding optParse into the script

kegg.directory=args[1]
pathwayListing=sprintf("%s/xml/kgml/metabolic/ko/", kegg.directory) %>% list.files(full.names=T)


pathwayListing %>%
mclapply(function(listing){
        cat(listing); cat("\n")
        xml_data=xmlParse(listing) %>% xmlToList
        hasRxn = sum(names(xml_data) == 'reaction') > 0
        if(hasRxn){
            pathway.info =  data.frame(t(xml_data[length(xml_data)]$.attrs)) %>%
                            setNames(names(xml_data[length(xml_data)]$.attrs))
            #Removes the last row (w/c is the pathway information)
            xml_data     = xml_data[-length(xml_data)]

#' | Types in xml files: | Description |
#' | ortholog            |             |
#' | compound            |             |
#' | map                 |             |
#' | ECrel               |             |
#' | maplink             |             |
#' | reversible          |             |
#' | irreversible"       |             |

#' Orthologs (KOs) in same reaction

            ko2rxn=do.call(rbind,sapply(xml_data, function(x){
                #has reaction information
                isGraphics = "graphics" %in% names(x)
                if(isGraphics){
                    isOrtholog = x$.attrs[which(names(x$.attrs)=='type')]=='ortholog'
                    if(isOrtholog){
                        reactions  =  x$.attrs[names(x$.attrs) == 'reaction'] %>% strsplit(" ") %>% unlist
                        name       =  x$.attrs[names(x$.attrs) == 'name']     %>% strsplit(" ") %>% unlist
                        do.call(rbind,lapply(reactions, function(rxn) { 
                        do.call(rbind,lapply(name, function(naa){
                            data.frame(reaction=rxn,name=naa)
                        })) }))
                    }else{"not ortholog"}
                }else{warning("not graphic")}
            }))
            ko2rxn = ko2rxn[complete.cases(ko2rxn),]

#' ##EDGES
rxns = xml_data[which(names(xml_data) %in% "reaction")]
            edges = rxns %>%
            lapply(function(x){
                rxnID          = x$.attrs["name"] %>% strsplit(" ") %>% unlist # name
                rxnDIR = x$.attrs["type"]                                      # reaction type
                kos.in.pathway = ko2rxn %>% filter(reaction %in% rxnID) %$% as.character(name)
                isAReaction = sum(c("substrate", "product") %in% names(x)) == 2
                if(isAReaction){
                list(substrates = x[["substrate"]][["name"]] %>% strsplit(" ") %>% unlist,
                     products   = x[["product"]][["name"]] %>% strsplit(" ") %>% unlist
                     ) %>%
                lapply(function(cpdS){
                    lapply(cpdS, function(cpd){
                        lapply(kos.in.pathway, function (ko) data.frame(cpd, ko, rxnID, rxnDIR,stringsAsFactors=F)) %>%
                        do.call(rbind,.)
                    }) %>% do.call(rbind,.)
                })
                }else{warning(sprintf("%s has no valid reactions with substrates and products", listing)); NULL}
            })
            sub2ko = edges %>% lapply(function(reaction) reaction$substrates) %>% do.call(rbind,.)
            ko2pdt = edges %>% lapply(function(reaction) reaction$products) %>% do.call(rbind,.)
            if(length(sub2ko)+length(ko2pdt) > 0){  #some rxns do not have substrates and pdts eg. ko00270 (depreciated)
        #Substrate2KO
                rbind(
                        sub2ko %>% select(-rxnDIR),
                        ko2pdt %>% filter(rxnDIR == 'reversible') %>% select(-rxnDIR)) %>% 
                  mutate(relationship='substrateof') %>%
                  write.table(sprintf("%s/%s_cpd2ko.rels",args[2], pathway.info$name),
                              quote     = F,
                              row.names = F,
                              col.names = c("cpd:string:cpdid","ko:string:koid","rxnID","relationship"),
                              sep       = "\t"
                              )
        #KO2Pdt
                rbind(
                        ko2pdt %>% select(-rxnDIR),
                        sub2ko %>% filter(rxnDIR == 'reversible') %>% select(-rxnDIR)) %>% 
                  mutate(relationship='produces') %>% 
                  select(ko, cpd, rxnID, relationship) %>%
                  write.table(sprintf("%s/%s_ko2cpd.rels",args[2], pathway.info$name),
                              quote     = F,
                              row.names = F,
                              col.names = c("ko:string:koid","cpd:string:cpdid","rxnID","relationship"),
                              sep       = "\t"
                              )

#' ##NODES
#' Yet to do: Each pathway will have its own nodes file
#' ko_nodedetails is generated using a perl script

#' ###KO
                  sprintf("%s/ko_nodedetails",args[2])                                                            %>%
                  read.table(sep="\t",h=F,quote="")                                                               %>%
                  setNames(c("ko","name","definition"))                                                           %>%
                  filter(ko %in% unique(c(sub2ko$ko,ko2pdt$ko)))                                                  %>%
                  mutate(label='ko')                                                                              %>%
                  cbind(select(pathway.info, name,title))                                                         %>%
                  write.table(sprintf("%s/%s_konodes",args[2],pathway.info$name),
                              quote=F,
                              row.names=F,
                              col.names=c("ko:string:koid", "name","definition","l:label","pathway","pathway.name"),
                              sep="\t"
                              )

#TODO: Maybe the raw & c1.mean values 
#    ko:string:koid             name                                                                                definition l:label      pathway                 pathway.name
#    1        ko:K00001    E1.1.1.1, adh                                                        alcohol dehydrogenase [EC:1.1.1.1]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    2        ko:K00002    E1.1.1.2, adh                                                alcohol dehydrogenase (NADP+) [EC:1.1.1.2]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    16       ko:K00016         LDH, ldh                                                     L-lactate dehydrogenase [EC:1.1.1.27]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    109      ko:K00114         E1.1.2.8                                         alcohol dehydrogenase (cytochrome c) [EC:1.1.2.8]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    116      ko:K00121 frmA, ADH5, adhC S-(hydroxymethyl)glutathione dehydrogenase / alcohol dehydrogenase [EC:1.1.1.284 1.1.1.1]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    123      ko:K00128         E1.2.1.3                                                aldehyde dehydrogenase (NAD+) [EC:1.2.1.3]      ko path:ko00010 Glycolysis / Gluconeogenesis

#' ###Compound
                  sprintf("%s/cpd_nodedetails",args[2])                                 %>%
                  read.table(,skip=1, sep="\t",h=F,quote="")                            %>%
                  setNames(c("cpd","name"))                                             %>%
                  filter(cpd %in% unique(c(sub2ko$cpd,ko2pdt$cpd)))                     %>%
                  mutate(label='cpd')                                                   %>%
                  setNames(c("cpd:string:cpdid","name","l:label"))                      %>%
                  write.table(file=sprintf("%s/%s_cpdnodes",args[2],pathway.info$name),
                              sep="\t",
                              quote=F,
                              row.names=F
                              )
#   cpd:string:cpdid                 name l:label
#   22       cpd:C00022            Pyruvate;     cpd
#   24       cpd:C00024          Acetyl-CoA;     cpd
#   31       cpd:C00031           D-Glucose;     cpd
#   33       cpd:C00033             Acetate;     cpd
#   36       cpd:C00036        Oxaloacetate;     cpd
#   66       cpd:C00068 Thiamin diphosphate;     cpd
            }else{warning("No reactions")}
}else{
sprintf("%s does not contain reactions", listing) %>% warning()
        }
}, mc.cores=10)

#Batch import step

#-- Init: setting up .properties file #need to include
#-- Execution
#mvn clean compile exec:java -Dexec.mainClass="org.neo4j.batchimport.Importer" -Dexec.args="/export2/home/uesu/github/iomics4j/KEGG/batch1.properties /export2/home/uesu/github/iomics4j/KEGG/newgraph.db /export2/home/uesu/github/iomics4j/KEGG/nodes/newcpdnodes,/export2/home/uesu/github/iomics4j/KEGGfnodes/newkonodes /export2/home/uesu/github/iomics4j/KEGG/rels/newcpdrels,/export2/home/uesu/github/iomics4j/KEGG/rels/newkorels"
#Batch job
#perl -l -ne 'print qq(import.r ~/kegg_dump/xml/kgml/metabolic/ko $_ ~/github/iomics4j/KEGG)' <(ls ~/kegg_dump/xml/kgml/metabolic/ko) > batch
