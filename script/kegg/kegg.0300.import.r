#!/usr/bin/env Rscript
library(XML)
#library(multicore)
#args=commandArgs(T)

#ftp://ftp.bioinformatics.jp/kegg/	#Kegg FTP site

#args[1]	the input directory
#args[2]	cpd and node data directory

#args=c("~/downloads/kegg2014/xml/kgml/metabolic/ko", "ko00010.xml", "~/github/iomics4j/KEGG2014")
#args=c("~/KEGG/kegg_dump", "~/db/neo4j/misc")
args=c("~/KEGG/KEGG_SEPT_2014", "~/db/neo4j/misc")
#data=xmlParse("~/KEGG/kegg_dump/xml/kgml/metabolic/ko/ko00010.xml")  
#xml_data<-xmlToList(data)



#TODO: Adding optParse into the script

kegg.directory=args[1]
pathwaylisting=list.files(sprintf("%s/xml/kgml/metabolic/ko/", kegg.directory), full.names=T)

##################################################
#Metabolism
##################################################

#Multicore option
#mclapply(pathwaylisting, function(listing){
lapply(pathwaylisting, function(listing){ 
xml_data=xmlToList(xmlParse(listing))

if(sum(names(xml_data) == 'reaction')>0){	#Empty pathways
pathway.info=setNames(data.frame(t(xml_data[length(xml_data)]$.attrs)), names(xml_data[length(xml_data)]$.attrs))
xml_data=xml_data[-length(xml_data)]  #Removes the last row (w/c is the pathway information)

#Types in xml files: "ortholog"     "compound"     "map"          "ECrel"        "maplink"      "reversible"   "irreversible"

#--Orthologs KOs which work in the same reaction##########################
ko2rxn=do.call(rbind, sapply(xml_data, function(x) { 
 if("graphics" %in% names(x)) { 
     if(x$.attrs[which(names(x$.attrs)=='type')]=='ortholog'){ #there are graphics in the list 
         reaction=unlist(strsplit(x$.attrs[names(x$.attrs) == 'reaction']," "))
         name=unlist(strsplit(x$.attrs[names(x$.attrs) == 'name'], " "))
         do.call(rbind,lapply(reaction, function(rxn) { do.call(rbind,lapply(name, function(naa) {data.frame(reaction=rxn,name=naa) }))}))
}}}))
################################################## NOTE single KO can belong to multiple reactions, reactions may include multiple KOs

nodeindex=c("cpd:string:cpdid","ko:string:koid")
##################################################
#--EDGES
edges=do.call(c,
lapply(xml_data[which(names(xml_data) %in% "reaction")], function(x) { 
     rxnID=unlist(strsplit(x$.attrs[[2]], " ")) #name 
     rxnTYPE=x$.attrs[[3]] 	#reaction type
     kos.in.pathway=as.character(subset(ko2rxn, reaction %in% rxnID)$name) #This line hasnt been PUT USE which KOs are part of a bigger protein complex

     substrates=lapply(which(names(x) == 'substrate'), function(subs) { x[[subs]][[2]]})
     products=lapply(which(names(x) == 'product'), function(subs) { x[[subs]][[2]]})

     lapply(list(substrates, products), function(cpd) {  
            do.call(rbind,lapply(cpd, function(s) { 
                                 do.call(rbind,lapply(kos.in.pathway, function (k) {
                                                      setNames(data.frame(s,k, rxnID, rxnTYPE,stringsAsFactors=F), c("cpd", "ko","rxnID","rxnDIR"))
}))		}))		})
}))
sub2ko=unique(do.call(rbind,edges[names(edges)=='reaction1']))
ko2pdt=unique(do.call(rbind,edges[names(edges)=='reaction2']))

if(length(sub2ko)+length(ko2pdt) > 0) {  #some rxns do not have substrates and pdts eg. ko00270 (depreciated)

#--Output##################################################
write.table(	#Substrate2KO
x=cbind(rbind(sub2ko[,-4], subset(ko2pdt, rxnDIR == 'reversible')[,-4]), data.frame(relationship='substrateof'))[,c(1,2,4,3)],
file=sprintf("%s/%s_cpd2ko.rels",args[2], pathway.info$name),quote=F,row.names=F,sep="\t",col.names=c(nodeindex[[1]],nodeindex[[2]],"relationship","rxnID"))

write.table(	#KO2Pdt
x=cbind(rbind(ko2pdt[,c(2,1,3)], subset(sub2ko, rxnDIR == 'reversible')[,c(2,1,3)]), data.frame(relationship='produces'))[,c(1,2,4,3)],
file=sprintf("%s/%s_ko2cpd.rels",args[2],pathway.info$name),quote=F,row.names=F,sep="\t",col.names=c(nodeindex[[2]],nodeindex[[1]], "relationship","rxnID"))
#########################################################

#--NODES################################################# 
#Yet to do: Each pathway will have its own nodes file
#ko_nodedetails is generated using the perl script 

#---KO
nodes.details=setNames(read.table(file=sprintf("%s/ko_nodedetails",args[2] ),sep="\t",h=F,quote=""), c("ko","name","definition"))
konodes=setNames(
cbind(
    subset(nodes.details, ko %in% unique(c(sub2ko$ko,ko2pdt$ko))),
    data.frame('ko',pathway.info$name,pathway.info$title)
),
c(nodeindex[[2]], "name","definition","l:label","pathway","pathway.name"))
write.table(konodes, file=sprintf("%s/%s_konodes",args[2],pathway.info$name), sep="\t",quote=F,row.names=F)

#Maybe the raw & c1.mean values 
#    ko:string:koid             name                                                                                definition l:label      pathway                 pathway.name
#    1        ko:K00001    E1.1.1.1, adh                                                        alcohol dehydrogenase [EC:1.1.1.1]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    2        ko:K00002    E1.1.1.2, adh                                                alcohol dehydrogenase (NADP+) [EC:1.1.1.2]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    16       ko:K00016         LDH, ldh                                                     L-lactate dehydrogenase [EC:1.1.1.27]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    109      ko:K00114         E1.1.2.8                                         alcohol dehydrogenase (cytochrome c) [EC:1.1.2.8]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    116      ko:K00121 frmA, ADH5, adhC S-(hydroxymethyl)glutathione dehydrogenase / alcohol dehydrogenase [EC:1.1.1.284 1.1.1.1]      ko path:ko00010 Glycolysis / Gluconeogenesis
#    123      ko:K00128         E1.2.1.3                                                aldehyde dehydrogenase (NAD+) [EC:1.2.1.3]      ko path:ko00010 Glycolysis / Gluconeogenesis

#--Compound
#cpd_nodedetails from the cpd_nodedetails script

cpd_nodes.details=setNames(read.table(file=sprintf("%s/cpd_nodedetails",args[2]),skip=1, sep="\t",h=F,quote=""), c("cpd","name"))
cpdnodes=setNames(
	cbind(
    	    subset(cpd_nodes.details, cpd %in% unique(c(sub2ko$cpd,ko2pdt$cpd))),
    	    data.frame('cpd')
	    ), 
c(nodeindex[[1]], "name","l:label"))
write.table(cpdnodes, file=sprintf("%s/%s_cpdnodes",args[2],pathway.info$name), sep="\t",quote=F,row.names=F)
#   cpd:string:cpdid                 name l:label
#   22       cpd:C00022            Pyruvate;     cpd
#   24       cpd:C00024          Acetyl-CoA;     cpd
#   31       cpd:C00031           D-Glucose;     cpd
#   33       cpd:C00033             Acetate;     cpd
#   36       cpd:C00036        Oxaloacetate;     cpd
#   66       cpd:C00068 Thiamin diphosphate;     cpd
}
}
})
#Batch import step

#-- Init: setting up .properties file #need to include

#-- Execution
#mvn clean compile exec:java -Dexec.mainClass="org.neo4j.batchimport.Importer" -Dexec.args="/export2/home/uesu/github/iomics4j/KEGG/batch1.properties /export2/home/uesu/github/iomics4j/KEGG/newgraph.db /export2/home/uesu/github/iomics4j/KEGG/nodes/newcpdnodes,/export2/home/uesu/github/iomics4j/KEGGfnodes/newkonodes /export2/home/uesu/github/iomics4j/KEGG/rels/newcpdrels,/export2/home/uesu/github/iomics4j/KEGG/rels/newkorels"

#Batch job
#perl -l -ne 'print qq(import.r ~/kegg_dump/xml/kgml/metabolic/ko $_ ~/github/iomics4j/KEGG)' <(ls ~/kegg_dump/xml/kgml/metabolic/ko) > batch

#FTP download from KEGG
#wget --user=username --password=password -P ~/KEGG/KEGG_JAN_2014 -m ftp://ftp.bioinformatics.jp/kegg/
