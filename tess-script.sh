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
echo "### tess-script ############################################"
echo "# "
echo "# An tesseract training utiility for "
echo "# The Early-Modern OCR Project (eMOP) "
echo "# "
echo "# Copyright 2013 - eMOP  "
echo "# "
echo "#######################################################"
echo " "
echo " "

#### ------------------mjc: 05022013----------------------------------------------------
# The script takes an input file name (without an extension, so something like "emop.mfle.exp18") and running all the necessary commands to build the training files.

# 

# The command looks like this:
##		==============================================================================
## 		sh ./tess-script.sh <inputfile(s)> 
##		==============================================================================

# Where:
#		<inputfile(s)>: input file(s) with path  --(relative from the folder where your XSLT is running)
#		NOTE: the input file is the common prefix of the name of a set of tiff/box file pairs. i.e. leave off the .tif/.box

#### ------------------mjc: 050213----------------------------------------------------


#Loop through passed params and assign global var values
infile=($@)
len=${#infile[@]}

for ((i=0; i<=$len-1; i++))
do
	echo " "
	echo "#####################################"
	echo "tesseract ${infile[$i]}.tif ${infile[$i]} nobatch box.train"
	echo "#####################################"
	#run tesseract on the passed in tifs to create training files for each
	tesseract ${infile[$i]}.tif ${infile[$i]} nobatch box.train
	#rename the passed in files to have the '.tr' extension
	#infile[$i]=${infile[$i]}.tr
done

#create the training file name for the whole set of passed in files by taking a prefix that doesn't include the exp #, the append a '.tr' extension.
outlen=${#infile[0]}-2
outfile=${infile[0]:0:$outlen}.tr

#concat all created training files into one
echo " "
echo "#####################################"
echo "concat all training files into one"
for ((i=0; i<=$len-1; i++))
do 
	trin[$i]=${infile[$i]}.tr
done
echo "cat ${trin[@]} > $outfile"
echo "#####################################"
cat ${trin[@]} > $outfile
	
	
#extract unicharset from all related box files
echo " "
echo "#####################################"
echo "extract unicharset from all related box files"
for ((i=0; i<=$len-1; i++))
do 
	boxin[$i]=${infile[$i]}.box
done
echo "unicharset_extractor ${boxin[@]}"
echo "#####################################"
unicharset_extractor ${boxin[@]}


echo " "
echo "#####################################"
echo "shapeclustering -F emop.font_properties -U unicharset $outfile"
echo "#####################################"
shapeclustering -F emop.font_properties -U unicharset $outfile


echo " "
echo "#####################################"
echo "mftraining -F emop.font_properties -U unicharset -O emop.unicharset $outfile"
echo "#####################################"
mftraining -F emop.font_properties -U unicharset -O emop.unicharset $outfile


echo " "
echo "#####################################"
echo "cntraining $outfile"
echo "#####################################"
cntraining $outfile


echo " "
echo "#####################################"
echo "change output filenames"
echo "mv inttemp emop.inttemp"
echo "mv normproto emop.normproto"
echo "mv pffmtable emop.pffmtable"
echo "mv shapetable emop.shapetable"
echo "#####################################"
mv inttemp emop.inttemp
mv normproto emop.normproto
mv pffmtable emop.pffmtable
mv shapetable emop.shapetable


echo " "
echo "#####################################"
echo "Create DAWG files using unicharset from training files"
echo "wordlist2dawg frequent-words-list.txt emop.freq-dawg emop.unicharset"
wordlist2dawg frequent-words-list.txt emop.freq-dawg emop.unicharset
echo "#####################################"
echo "wordlist2dawg frequent-words-list.txt emop.freq-dawg emop.unicharset"
echo "#####################################"
wordlist2dawg words-list.txt emop.word-dawg emop.unicharset


echo " "
echo "#####################################"
echo "combine_tessdata emop."
echo "#####################################"
combine_tessdata emop.


echo " "
echo "#####################################"
echo "cp emop.traineddata /Users/matthewchristy/tesseract-ocr/tessdata"
echo "#####################################"

cp emop.traineddata /Users/matthewchristy/tesseract-ocr/tessdata

#tesseract emop.mfle.exp17.tif out.a4.m94-17.mfle17 -l emop <path>config.txt
