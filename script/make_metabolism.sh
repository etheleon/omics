#!/usr/bin/env bash

targetdir=$HOME/db/neo4j
keggdump=$HOME/KEGG/KEGG_SEPT_2014
meta4jHome=$HOME/downloads/meta4j #Weird
cores="1"

#Initial processing
echo "##    Processing ko nodes"
script/kegg/kegg.0100.ko_nodedetails.pl  $keggdump/genes/ko/ko > $targetdir/misc/ko_nodedetails

echo "##    Processing cpd nodes"
script/kegg/kegg.0200.cpd_nodedetails.pl  $keggdump/ligand/compound/compound $keggdump/ligand/glycan/glycan > $targetdir/misc/cpd_nodedetails

echo "##    Processing module nodes"
script/kegg/kegg.0600.modules.pl $keggdump/module/module $targetdir/out/nodes/modulesNodes $targetdir/out/rels/module2ko

echo "##    Importing"
script/kegg/kegg.0300.import.r $keggdump $targetdir/misc $cores

cat $targetdir/misc/*_konodes > $targetdir/misc/combined_redundant_konodeslist
#################################################
#NODES
##################################################

#' #KOs
#' combines redundant ko entries into one with pathways as arrays 
rm -f $targetdir/out/nodes/newkonodes

echo "## Processing Metabolic KOs"
for i in `perl -aln -F"\t" -e 'print $F[0] unless m/ko:ID/' $targetdir/misc/*_konodes | sort | uniq`
do
    grep $i $targetdir/misc/combined_redundant_konodeslist | perl -aln -F"\t" -e '$earlier=join("\t",@F[0..3]) if $.==1; push(@pathwayid, $F[4]); push(@pathwayname, $F[5]); END{print qq($earlier\t), join("|", @pathwayid),qq(\t), join("|", @pathwayname)}' >> $targetdir/out/nodes/newkonodes;
done;

perl -0777 -pi -E '@header = qw/ko:ID name definition l:label pathway pathway.name/; say(join("\t", @header))' $targetdir/out/nodes/newkonodes #prints the header
perl -pi -e 's/\"/\\"/g' $targetdir/out/nodes/newkonodes	#protects removes
echo "## Add ko:K00000" #need to add all non-metabolic KOs
echo -e 'ko:K00000\tUnassigned\tUnassigned\tko' >> $targetdir/out/nodes/newkonodes 

echo "## Processing Non-Metabolic KOs"
./script/kegg/kegg.0400.non-metabolic.pl $targetdir

#Prepare nodes (escape lucene (neo4j's query engine) metacharacters)
#shd do this for all but lets just let it be first
echo "## Clean for neo4j"
#perl -pi -e 's/([\+\-\&\|\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\])/\\$1/g unless $. == 1' $targetdir/out/nodes/newkonodes

#--CPD
rm -f $targetdir/misc/newcpdnodes
#cat $targetdir/misc/*_cpdnodes |perl -ne 'print unless /cpd\:ID/' | sort | uniq >> $targetdir/out/nodes/newcpdnodes	#removes redundancy
cp $misc/cpd_nodedetails $targetdir/out/nodes/newcpdnodes
perl -0777 -pi -e 'print qq(cpd:ID\tname\texactMass\tmolWeight\tl:label\n)' $targetdir/out/nodes/newcpdnodes
#perl -pi -e 's/([\+\-\&\|\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\])/\\$1/g unless $. == 1' $targetdir/out/nodes/newcpdnodes
#perl -pi -e 's/\"/\\"/g' $targetdir/out/nodes/newcpdnodes


#--Pathways
perl -aln -F"\t" -e 'print qq($F[4]\t$F[5]\tpathway) unless $.==1' $targetdir/misc/combined_redundant_konodeslist | sort | uniq > $targetdir/out/nodes/pathwaynodes
perl -0777 -pi -e 'print qq(pathway:ID\tpathwayname\tl:label\n)' $targetdir/out/nodes/pathwaynodes
#perl -pi -e 's/([\+\-\&\|\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\])/\\$1/g unless $. == 1' $targetdir/out/nodes/pathwaynodes

##################################################
#EDGES
##################################################

#-- ko2cpd, cpd2ko
echo "## ko2cpd cpd2ko"
perl -ne 'BEGIN{print qq(ko:START_ID\tcpd:END_ID\trxnID\trelationship:TYPE\n)}print if !/^ko:ID/' <(cat $targetdir/misc/*cpd.rels | sort | uniq) > $targetdir/out/rels/newcpdrels
#perl -pi -e 's/([\+\-\&\|\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\])/\\$1/g unless $. == 1' $targetdir/out/rels/newcpdrels
perl -ne 'BEGIN{print qq(cpd:START_ID\tko:END_ID\trxnID\trelationship:TYPE\n)}print if !/^cpd:ID/' <(cat $targetdir/misc/*ko.rels | sort | uniq) > $targetdir/out/rels/newkorels
#perl -pi -e 's/([\+\-\&\|\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\])/\\$1/g unless $. == 1' $targetdir/out/rels/newkorels

##-- pathway2KO
rm -f $targetdir/out/rels/ko2pathwayrels
for i in `perl -aln -F"\t" -e 'print $F[0] unless m/ko:ID/' $targetdir/misc/*_konodes | sort | uniq`
do
    grep $i $targetdir/misc/combined_redundant_konodeslist | perl -aln -F"\t" -e '$ko = $F[0] if $.==1; push(@pathwayid, $F[4]); END{foreach $e (@pathwayid){print qq($ko\t$e\tpathwayed)}}' >> $targetdir/out/rels/ko2pathwayrels;
done;

perl -0777 -pi -e 'print qq(ko:START_ID\tpathway:END_ID\trelationship:TYPE\n)' $targetdir/out/rels/ko2pathwayrels
#perl -pi -e 's/([\+\-\&\|\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\])/\\$1/g unless $. == 1' $targetdir/out/rels/ko2pathwayrels

script/kegg/kegg.0500.igraphMetabolism.r $targetdir/misc/
