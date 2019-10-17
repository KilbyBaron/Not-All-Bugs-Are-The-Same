#!/bin/bash


#This script executes the "git show --numstat" command for every hash target_bfcs.csv
#REQUIREMENTS: 
#   -each project must be cloned into this location: cloned_repos/$project
#   -This script must be run from the scripts directory
#
#OUTPUT:
#   -numstat info for every target hash located here:  intermediate_files/numstats/text_output/$project.txt

cd ../cloned_repos

awk -F "\"*,\"*" '{print}' ../intermediate_files/target_commits.csv | while read -r ROW
do

    proj=$(echo "$ROW" |cut -d ',' -f1 )
    proj=$(echo "$proj" | awk '{print tolower($0)}')
    hash=$(echo "$ROW" |cut -d ',' -f2 )
    
    if [ $proj != "project" ] #This check is only true for the first row, ie the header
    then
        cd $proj
        git show "$hash" --numstat >> "../../intermediate_files/numstats/all_github_commits/$proj.txt"
        cd ..
    fi
    
done


exit 0

