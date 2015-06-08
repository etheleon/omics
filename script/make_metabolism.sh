#!/usr/bin/env bash

targetdir=$HOME/db/neo4j
keggdump=$HOME/KEGG/KEGG_SEPT_2014
meta4jHome=$HOME/downloads/meta4j
cores="1"

#Initial processing
script/kegg/kegg.0100.ko_nodedetails.pl  $keggdump/genes/ko/ko > $targetdir/misc/ko_nodedetails
script/kegg/kegg.0200.cpd_nodedetails.pl  $keggdump/ligand/compound/compound $keggdump/ligand/glycan/glycan > $targetdir/misc/cpd_nodedetails
script/kegg/kegg.0300.import.r $keggdump $targetdir/misc $cores
cat $targetdir/misc/*_konodes > $targetdir/misc/combined_redundant_konodeslist

#################################################
#NODES
##################################################

#' #KOs
#' combines redundant ko entries into one with pathways as arrays 
rm $targetdir/out/nodes/newkonodes

for i in `perl -aln -F"\t" -e 'print $F[0]' $targetdir/misc/*_konodes | sort | uniq | head -n -1 `	#For each ko
do
grep $i $targetdir/misc/combined_redundant_konodeslist | perl -aln -F"\t" -e '$earlier=join("\t",@F[0..3]) if $.==1; push(@pathwayid, $F[4]); push(@pathwayname, $F[5]);END{print qq($earlier\t), join("|", @pathwayid),qq(\t), join("|", @pathwayname)}' >> $targetdir/out/nodes/newkonodes;
done;

perl -0777 -pi -E '@header = qw/ko:string:koid name definition l:label pathway:string_array pathway.name:string_array/; say(join("\t", @header))' $targetdir/out/nodes/newkonodes #prints the header
perl -pi -e 's/\"/\\"/g' $targetdir/out/nodes/newkonodes	#protects removes
echo -e 'ko:K00000\tUnassigned\tUnassigned\tko' >> $targetdir/out/nodes/newkonodes	#empty field

#Add in non-metabolic kos
./script/kegg/kegg.0400.non-metabolic.pl

#Prepare nodes (escape lucene (neo4j's query engine) metacharacters)
#shd do this for all but lets just let it be first
perl -pi -e 's/([\+\-\&\|\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\])/\\$1/ unless $. == 1' out/nodes/newkonodes
#perl -0777 -pi -e 'print qq(ko:string:koid\tname\tdefinition\tl:label\tpathway:string_array\tpathway.name:string_array\n)' nodes/newkonodes


#--CPD
rm $targetdir/misc/newcpdnodes
cat $targetdir/misc/*_cpdnodes |perl -ne 'print unless /cpd\:string\:cpdid/' | sort | uniq >> $targetdir/out/nodes/newcpdnodes	#removes redundancy
perl -0777 -pi -e 'print qq(cpd:string:cpdid\tname\tl:label\n)' $targetdir/out/nodes/newcpdnodes	
perl -pi -e 's/\"/\\"/g' $targetdir/out/nodes/newcpdnodes


#--Pathways
perl -aln -F"\t" -e 'print qq($F[4]\t$F[5]\tpathway) unless $.==1' $targetdir/misc/combined_redundant_konodeslist | sort | uniq > $targetdir/out/nodes/pathwaynodes
perl -0777 -pi -e 'print qq(pathway:string:pathwayid\tpathwayname\tl:label\n)' $targetdir/out/nodes/pathwaynodes

##################################################
#EDGES
##################################################

#-- ko2cpd, cpd2ko
perl -ne 'BEGIN{print qq(ko:string:koid\tcpd:string:cpdid\trelationship\trxnID\n)}print if !/^ko:string/' <(cat $targetdir/misc/*cpd.rels | sort | uniq) > $targetdir/out/rels/newcpdrels
perl -ne 'BEGIN{print qq(cpd:string:cpdid\tko:string:koid\trelationship\trxnID\n)}print if !/^cpd:string/' <(cat $targetdir/misc/*ko.rels | sort | uniq) > $targetdir/out/rels/newkorels

##-- pathway2KO
rm $targetdir/out/rels/ko2pathwayrels
for i in `perl -aln -F"\t" -e 'print $F[0]' $targetdir/misc/*_konodes | sort | uniq | head -n -1 `
do
grep $i $targetdir/misc/combined_redundant_konodeslist | perl -aln -F"\t" -e '$ko = $F[0] if $.==1; push(@pathwayid, $F[4]); END{foreach $e (@pathwayid){print qq($ko\t$e\tpathwayed)}}' >> $targetdir/out/rels/ko2pathwayrels;
done;
perl -0777 -pi -e 'print qq(ko:string:koid\tpathway:string:pathwayid\trelationship\n)' $targetdir/out/rels/ko2pathwayrels
