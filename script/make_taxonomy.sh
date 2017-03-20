#!/usr/bin/env bash

#Taxonomy
targetdir=$HOME/db/neo4j/out
taxodump=$HOME/db/taxonomy

if [ ! -f "$taxodump/nodes.dmp" ]
then
    echo "unzipping $taxodump/taxdump.tar.gz"
    tar -zvxf $taxodump/taxdump.tar.gz -C $taxodump
fi


#-- NODES
#indexing::::propertyname:fieldtype:indexName##########
#01::taxnodes##########################################
#taxid:int:ncbitaxid     name    l:label
#1       root    rank,no rank
#######################################################
#stores rank into hash table and save into file:tempfile
perl -aln -F"\\t\\|\\t" -e 'BEGIN{use Storable} $tax2rank{$F[0]}=$F[2]; END{ store(\%tax2rank,q(tempfile)) }' $taxodump/nodes.dmp

#reads the names
perl -aln -F"\\t\\|\\t" -e 'BEGIN{use Storable; %tax2rank=%{retrieve(q(tempfile))}; print qq(taxid:ID\tname\tl:label\t)} if (/scientific name/){$F[1] =~ s/[^a-zA-Z0-9 _-]//g;print qq($F[0]\t$F[1]\t$tax2rank{$F[0]}|Taxon)}' $taxodump/names.dmp > $targetdir/out/nodes/tax_nodes

echo -e '0\tUnclassified\tno rank|Taxon' >> $targetdir/out/nodes/tax_nodes  #this adds unclassified
#######################################################

#--
#Build SQL
#perl -nE 'BEGIN{say join "\t",qw/taxid name species/}; s/Taxon//; s/\|//; print $_ unless $. == 1'


# EDGES ---------------------------------------------------------#
#01::taxid2taxid##################################################
#taxid:START_ID     taxid:int:END_ID    relationship
#1       1       child.of
##################################################################
perl -E 'say qq(taxid:START_ID\ttaxid:END_ID\trelationship:TYPE\tstartend)' > $targetdir/out/rels/tax2tax.rel
perl -aln -F"\\t\\|\\t" -e 'print qq($F[0]\t$F[1]\tchildof\t$F[0]_$F[1]) unless $F[0] == $F[1]' $taxodump/nodes.dmp > $targetdir/out/rels/tax2tax.rel
##################################################################
