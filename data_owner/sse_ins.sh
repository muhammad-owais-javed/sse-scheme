#!/bin/bash

echo -e "Initializing Script for Inserting New Files"

#######################
#Starting Timer
start=`date +%s.%N`
#######################

#Initializing Key
key=$(cat config/my.key)
#Variables
ns_var=0

############################## Data Files Encryption ####################################
#Counting number Of Files
echo "Counting Total Number of Data Files..."
num_files=$(ls D184MB/*.txt D184MB_I/*.txt | wc -l)
echo "Total Number of Data Files:" $((num_files))

#File Encryption Timer
start_FE=`date +%s.%N`

#Computing csp_keyvalue=EncKske(filename+num_files)
cp /dev/null data/ins.csp_keyvalue.txt
echo -e "\nEncrypting all Files..."
rm -r D184MB_IE/*
for filename in D184MB_I/*.txt
do
        #For Separating Filename
        name=$(echo ${filename} | sed -e 's#D184MB_I/##g' -e 's#.txt##g')
        #Encrypting all files and placing in D184MB_IE folder
        aes_files=$(openssl aes-256-ecb -in ${filename} -K $key -out D184MB_IE/$name.aes -p -a -nosalt)

        #Separating Filenames in a Separate File
        echo "$name.txt" > cache/ins.tmp.txt
        #Encrypting Filenames
        name_aes=$(openssl aes-256-ecb -in cache/ins.tmp.txt -K $key -out cache/ins.tmp.aes -p -a -nosalt)

        #Creating Wordlist of Each File
        cp /dev/null cache/$name.ins.wl.txt
        cat $filename | while read line

	do
                for word in $line
                do
                        echo $word >> cache/$name.ins.wl.txt
                done
        done

        #Removing Punctuations from Each File Words List
        cat cache/$name.ins.wl.txt | tr -d [:punct:] > cache/$name.ins.tmp.txt
        #Removing Carriage Return from Each File Words List
        sed 's/\r$//' cache/$name.ins.tmp.txt > cache/$name.ins.tmp.txt.bak && mv cache/$name.ins.tmp.txt.bak cache/$name.ins.tmp.txt
        #Removing New Blank Line from Each File Words List
        awk 'NF' cache/$name.ins.tmp.txt > cache/$name.ins.tmp.txt.bak && mv cache/$name.ins.tmp.txt.bak cache/$name.ins.tmp.txt
        #Excluding Repetition of Words from Each File Words List
        cat -n cache/$name.ins.tmp.txt | sort -uk2 | sort -n | cut -f2- > cache/$name.ins.wl.txt #Line Added

        #Counting Number of Words Present in Each File Words List
        count=$(cat cache/$name.ins.wl.txt | wc -l)
        #Printing for Testing Purpose
        echo "Total number of words in $name.ins.wl.txt:"
        echo $count
	for ((j=1;j<=$count;j++))
        do
                cat cache/ins.tmp.aes  >> data/ins.csp_keyvalue.txt
        done

done

cp D184MB_IE/*.aes ../user_search/D184MB_E/

echo -e "Files Encrypted Succesfully!"

end_FE=`date +%s.%N`
runtime_FE=$( echo "$end_FE - $start_FE" | bc -l)
echo "Runtime of Encrypting Updated Data Files:"$runtime_FE "seconds"

########################################################################################

########################################################################################
#Updating Combined Words Lists

#Words List Timer
start_wl=`date +%s.%N`

#Concatenating all Files Word Lists
echo -e "\nUpdating all Files Words List..."
cp /dev/null cache/ins_merged_files.txt
#cat D184MB/*.txt >> cache/merged_files.txt
cat cache/*.ins.wl.txt >> cache/ins_merged_files.txt #Added
echo -e "Updating Merged Successful!"
echo -e "\nReinitiating Words List Process..."
cp /dev/null cache/ins.tmp.txt
cat cache/ins_merged_files.txt | while read line
do
        for word in $line
        do
                echo $word >> cache/ins.tmp.txt
        done
done
#Removing punctuations from words list
cp /dev/null cache/ins.words_list.txt
cat cache/ins.tmp.txt | tr -d [:punct:] > cache/ins.words_list.txt
rm cache/ins.tmp.txt
cp /dev/null cache/ins.uniq_wl.txt
#cat cache/words_list.txt | uniq > cache/tmp.txt
cat cache/ins.words_list.txt > trash/ins.tmp.txt
sed 's/\r$//' trash/ins.tmp.txt > trash/ins.tmp.txt.bak && mv trash/ins.tmp.txt.bak trash/ins.tmp.txt
awk 'NF' trash/ins.tmp.txt > trash/ins.tmp.txt.bak
#cat -n cache/tmp.txt.bak | sort -uk2 | sort -n | cut -f2- > cache/uniq_wl.txt
cat trash/ins.tmp.txt.bak > cache/ins.uniq_wl.txt
rm trash/ins.tmp.txt.bak

cat cache/uniq_wl.txt cache/ins.uniq_wl.txt > cache/tmp.uniq_wl.txt && mv cache/tmp.uniq_wl.txt cache/uniq_wl.txt

echo -e "Updated Words List Created Succesful!\n"


#Encryption of Unique Words List File
echo "Encrypting Combined Words List File..."
aes_wordslist=$(openssl aes-256-ecb -in cache/uniq_wl.txt -K $key -out cache/uniq_wl.aes -p -a -nosalt)
echo -e "Encryption Complete!\n"

end_wl=`date +%s.%N`
runtime_wl=$( echo "$end_wl - $start_wl" | bc -l)
echo "Runtime of Combined Words List Process:"$runtime_wl "seconds"

########################################################################################

########################################################################################
#Calculating Hash of each word (i.e sse_keywords value) 
#Calculating number of files containing particular keyword
#Initializing Numsearch Value for Kewords
cp /dev/null data/ins.hash_wl.txt
cp /dev/null data/ins.num_files.txt
cp /dev/null data/ins.num_search.txt

cp D184MB_I/*.txt D184MB/
#Timer for the Hashing Function
start_h=`date +%s.%N`

while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}'  >> data/ins.hash_wl.txt
        echo "$line" | xargs grep -rw 'D184MB/' -e | wc -l >> data/ins.num_files.txt
        echo "$ns_var" >>  data/ins.num_search.txt
done < cache/ins.uniq_wl.txt

end_h=`date +%s.%N`
runtime_h=$( echo "$end_h - $start_h" | bc -l)
echo -e "\nRuntime of Hashing Algorithm:"$runtime_h "seconds"

########################################################################################

#Timer for Kw and CSP Function
start_m=`date +%s.%N`

#Calculating Kw=SHA256(keyword+numsearch)
paste data/ins.hash_wl.txt data/ins.num_search.txt > data/ins.keyword_numsearch.txt
cp /dev/null data/ins.Kw.txt
while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}' >> data/ins.Kw.txt

done < data/ins.keyword_numsearch.txt

#Computing csp_keywords_address=SHA256(Kw+numfiles)
paste data/ins.Kw.txt data/ins.num_files.txt > data/ins.Kw_numfiles.txt
cp /dev/null data/ins.csp_keywords_address.txt
while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}' >> data/ins.csp_keywords_address.txt
done < data/ins.Kw_numfiles.txt

paste data/ins.hash_wl.txt data/ins.num_files.txt data/ins.num_search.txt > data/ins.sse_keywords.txt

end_m=`date +%s.%N`
runtime_m=$( echo "$end_h - $start_h" | bc -l)
echo -e "\nRuntime of Kw and CSP Address Algorithm:"$runtime_m "seconds"

paste data/ins.csp_keywords_address.txt data/ins.csp_keyvalue.txt > data/ins.sse_csp_keywords.txt

########################################################################################


######################### MySQL Connectivity ##########################

echo -e "\nConnecting to MySQL..."

####### MySql Connection Details #######
USER='owais'
PASS='pass123'
PORT=3306
HOST='localhost'
DB='cwdb'
#A_PATH='/home/owais/COURSEWORKII/data_owner' #End Path without forward slash /
########################################

##### Absolute File path is used which needs to be change in case of different user #####
mysql -u$USER -p$PASS -P$PORT -D$DB -se "use cwdb"

echo "Attempting to add new entries in sse_keywords table..."

#mysql -u$USER -p$PASS -P$PORT -D$DB -se "delete from sse_keywords"
#mysql -u$USER -p$PASS -P$PORT -D$DB -se "ALTER TABLE sse_keywords AUTO_INCREMENT = 1"
#Make Sure to change path in case of different user or directory
mysql -u$USER -p$PASS -P$PORT -D$DB -se "LOAD DATA LOCAL INFILE 'data/ins.sse_keywords.txt' REPLACE INTO TABLE sse_keywords FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' (sse_keyword,sse_keyword_numfiles,sse_keyword_numsearch) "

#echo "Uploading Done!"

echo "Attempting to add new entries in sse_csp_keywords table.."

#mysql -u$USER -p$PASS -P$PORT -D$DB -se "delete from sse_csp_keywords"
#mysql -u$USER -p$PASS -P$PORT -D$DB -se "ALTER TABLE sse_csp_keywords AUTO_INCREMENT = 1"
#Make Sure to change path in case of different user or directory
mysql -u$USER -p$PASS -P$PORT -D$DB -se "LOAD DATA LOCAL INFILE 'data/ins.sse_csp_keywords.txt' REPLACE INTO TABLE sse_csp_keywords FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' (csp_keywords_address,csp_keyvalue)"

#echo "Uploading Done!"

#mysql -u$USER -p$PASS -P$PORT -D$DB -se "Select * from sse_keywords; Select * from sse_csp_keywords"

########################################################################################


end=`date +%s.%N`
runtime=$( echo "$end - $start" | bc -l)
echo "Total Runtime of Script:"$runtime "seconds"


