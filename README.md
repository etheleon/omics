
#iomics4j 

The following scripts are used to generate a the input tables required to populate the neo4j database

#taxonomy 
[script/make_taxonomy]
Builds taxonomy 
need to download latest script

##Relative abundance
[script/make_abundance]


this requires a prototype DB to be generated first, XC's taxon list doesnt have a taxid, I need to associate taxid with name.

redundancy in taxonomy, 
option to just include things in archaea and bacteria

#BUG
* pathways include node `pathway pathway.name    pathway` which isnt suppose to be inside
* non-metabolic pathways eg. 2-component system arent included. 
