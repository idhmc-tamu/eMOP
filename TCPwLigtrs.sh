#!/bin/sh

### tess-script #############################################
# 
# Written by Matt Christy 
# for The Early-Modern OCR Project 
#
# Copyright 2013 The Early-Modern OCR Project 
# 
#########################################################

clear

echo " "
echo " "
echo "### TCPwLigtrs ############################################"
echo "# "
echo "# A script to put ligatures and long-ses"
echo "# back into the TCP transcripts for "
echo "# The Early-Modern OCR Project (eMOP) "
echo "# "
echo "# Copyright 2013 - eMOP  "
echo "# "
echo "#######################################################"
echo " "
echo " "

#### ------------------mjc: 05212013----------------------------------------------------
# The script takes an input directory name and runs on all text files
# it finds replacing all given two-letter combos with equivalent ligatures. For the 
# first half of the text files present it also replaces all 's's with long-ses.

# For now (5/21/13) this only works on one dir input at a time, but may work for multiple
# dirs.

# 

# The command looks like this:
##		==============================================================================
## 		sh ./TCPwLigtrs.sh <inputdir(s)> 
##		==============================================================================

#### ------------------mjc: 052113----------------------------------------------------


#Loop through passed params and assign global var values
infile=($@)
len=${#infile[@]}

for ((i=0; i<=$len-1; i++))
do
	echo " "
	echo "#####################################"
	echo "processing ${infile[$i]}/"
	echo "#####################################"
	echo "create ${infile[$i]}-lig"
	echo "#####################################"
	mkdir ${infile[$i]}-lig
	cp ${infile[$i]}/*.txt ${infile[$i]}-lig/


	total=`ls ${infile[$i]}-lig | grep -c ""`
	echo "$total pages"
	echo "#####################################"
	
	#to count how many files we've changed
	cnt=0 

	for fname in `ls ${infile[$i]}-lig`
	do	
		echo "adding ligatures to $fname"
		sed -i '' 's/sh//g;s/st/ﬅ/g;s/si//g;s/ss//g;s/ssi//g;s/sst//g;s/ff/ﬀ/g;s/fi/ﬁ/g;s/fl/ﬂ/g;s/ffi/ﬃ/g;s/ct//g;s/ae/æ/g;' ${infile[$i]}-lig/$fname
		
		#add the long-s to only the first half of the page count
		if [ $cnt -lt $(($total/2)) ]
		then
			echo "adding long-s to $fname"
			sed -i '' 's/s/ſ/g' ${infile[$i]}-lig/$fname
		fi
		
		cnt=$((cnt+1))
		echo "#####################################"
	done
done