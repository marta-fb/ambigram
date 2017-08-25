#!/bin/bash

# A pipeline to check the EBRs by different reference
# (c) Jitendra Narayan

# We ASSUME both of the references had same species here. -- 11 here

# GENERAL location settings for ambigram
scriptBase=/home/jitendra/ETC/ambigram/scriptBase

ref1=chicken
snameRef1=gallus_gallus
coordinateFolder_ref1=/home/jitendra/ETC/ambigram/chicken-data

ref2=finch
snameRef2=taeniopygia_guttata
coordinateFolder_ref2=/home/jitendra/ETC/ambigram/finch-data

coordinateFolderOUT_ref1=/home/jitendra/ETC/ambigram/output_chicken
coordinateFolderOUT_ref2=/home/jitendra/ETC/ambigram/output_finch

class=classification.eba #Name of the classification file [we will access both with this name]

#Parameters
spsNum=11 #Number of species in BOTH analysis [tested with finch and chicken]
threshold=2 #score diff
len=0
extend=5000 #Extend the size of all breakspoints before checking
chekerExtend=100 # Extend the size of the breakpoints regions

# General thresholds and folders
outDir=/home/jitendra/ETC/ambigram/OutData
if [ -d "$outDir" ]; then rm -Rf $outDir; fi
mkdir $outDir
finalResult=/home/jitendra/ETC/ambigram/OutData

#------------------------------------------------------------------------------

perl $scriptBase/ReconstructTargetEBRs_Final.pl -f $coordinateFolder_ref1/final_classify.eba7 -a $coordinateFolder_ref1/all.hsb -t $threshold -l $len -s $coordinateFolder_ref1/sps.txt -r $ref1

perl $scriptBase/ReconstructTargetEBRs_Final.pl -f $coordinateFolder_ref2/final_classify.eba7 -a $coordinateFolder_ref2/all.hsb -t $threshold -l $len -s $coordinateFolder_ref2/sps.txt -r $ref2

#Store all the species name
#We dont need to extract all both as only reference is the diffrence.
spsData="$(xargs printf ',%s' < $coordinateFolder_ref2/sps.txt | cut -b 2-)"
echo $spsData

#unlink the files if exist
if [ -f "countSTAT_$ref1" ]; then rm -Rf "countSTAT_$ref1"; fi
if [ -f "countSTAT_$ref2" ]; then rm -Rf "countSTAT_$ref2"; fi

if [ -f "finalOut_$ref1" ]; then rm -Rf "finalOut_$ref1"; fi
if [ -f "finalOut_$ref2" ]; then rm -Rf "finalOut_$ref2"; fi

if [ -f "missedOut_$ref1" ]; then rm -Rf "missedOut_$ref1"; fi
if [ -f "missedOut_$ref2" ]; then rm -Rf "missedOut_$ref2"; fi

#unlink "countSTAT_$ref1";

for spsName in ${spsData//,/ }
do
    if [ $snameRef1 == $spsName ] || [ $snameRef2 == $spsName ]  # Excludes 
    then
           continue      # Skip rest of this particular loop iteration.
    else

    # call your procedure/other scripts here below
    #printf '%.0s-' {1..50}; echo
    echo "Working on species: $spsName"
    printf '%50s\n' | tr ' ' -
    # Lets cross compare
    inside=_brk_
    refName=$spsName$inside$ref1
    tarName=$spsName$inside$ref2

    # With REF1
    perl $scriptBase/checkOverlaps_TAR2TAR.Pl -r $coordinateFolderOUT_ref1/$refName.tar3 -t $coordinateFolderOUT_ref2/$tarName.tar3 -o $finalResult/OUT_$refName -n $spsName -c $spsNum -l $extend -a $coordinateFolder_ref1/all_all.eba00 -s $coordinateFolder_ref1/sps.txt -b $coordinateFolder_ref1/all.hsb -z aaaa -e $finalResult/STAT_$refName -i $spsName -d finalOut_$ref1 -m missedOut_$ref1 -g $coordinateFolder_ref2/$class -x $chekerExtend -f $coordinateFolder_ref1/final_classify.eba7 >> countSTAT_$ref1

    # With REF2
    perl $scriptBase/checkOverlaps_TAR2TAR.Pl -r $coordinateFolderOUT_ref2/$tarName.tar3 -t $coordinateFolderOUT_ref1/$refName.tar3 -o $finalResult/OUT_$tarName -n $spsName -c $spsNum -l $extend -a $coordinateFolder_ref2/all_all.eba00 -s $coordinateFolder_ref2/sps.txt -b $coordinateFolder_ref2/all.hsb -z aaaa -e $finalResult/STAT_$tarName -i $spsName -d finalOut_$ref2 -m missedOut_$ref2 -g $coordinateFolder_ref1/$class -x $chekerExtend -f $coordinateFolder_ref2/final_classify.eba7 >> countSTAT_$ref2

    fi
done


    #Create final table and plot
    perl $scriptBase/createResultTable.pl -s countSTAT_$ref1 -i finalOut_$ref1 -m missedOut_$ref1 > Result_$ref1
    perl $scriptBase/createResultTable.pl -s countSTAT_$ref2 -i finalOut_$ref2 -m missedOut_$ref2 > Result_$ref2

    perl $scriptBase/reformatTable.pl -i Result_$ref1 > barData_$ref1
    perl $scriptBase/reformatTable.pl -i Result_$ref2 > barData_$ref2

    Rscript $scriptBase/plotResult.R Result_$ref1 Result_$ref2 barData_$ref1 barData_$ref2




