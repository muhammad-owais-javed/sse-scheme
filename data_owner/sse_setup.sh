#!/bin/bash

echo -e "Initializing SSE Script...\n"

################## Key Generation Part #####################
#Taking Decision for Generating New Key
read -p "Do you want to generate fresh key?[y/n]" decision

if [[ "${decision,,}" == "y"  ]]
then
        openssl enc -aes-256-cbc -k secret -P -md sha1 | grep 'key' | cut -d "=" -f2 > config/my.key
	
	#In real case, key will be secretly shared with the users
	cp config/my.key ../user_search/config/

	echo "Generated key is placed in config/my.key"
else
        echo "Proceeding with Old Key"
fi
#############################################################

#######################
#Starting Main Timer
start=`date +%s.%N`
#######################

#Initializing Key
key=$(cat config/my.key)
#Variables
ns_var=0

############################## Data Files Encryption ####################################

#File Encryption Timer
start_FE=`date +%s.%N`

#Counting Total Number Of Data Files
echo "Counting Total Number of Files..."
num_files=$(ls D184MB/*.txt | wc -l)
echo "Total Number of Files:" $((num_files))

#Computing csp_keyvalue=EncKske(filename+num_files)
cp /dev/null data/csp_keyvalue.txt
echo -e "\nEncrypting all Files..."
rm -r D184MB_E/* 
for filename in D184MB/*.txt
do
	#For Separating Filename
        name=$(echo ${filename} | sed -e 's#D184MB/##g' -e 's#.txt##g')
        #Encrypting all files and placing in D184MB_E folder
        aes_files=$(openssl aes-256-ecb -in ${filename} -K $key -out D184MB_E/$name.aes -p -a -nosalt)

        #Separating Filenames in a Separate File
        echo "$name.txt" > cache/tmp.txt
        #Encrypting Filenames
        name_aes=$(openssl aes-256-ecb -in cache/tmp.txt -K $key -out cache/tmp.aes -p -a -nosalt)

	#Creating Wordlist of Each File
        cp /dev/null cache/$name.wl.txt
        cat $filename | while read line
        do
                for word in $line
                do
                        echo $word >> cache/$name.wl.txt
                done
        done
        
	#Removing Punctuations from Each File Words List
        cat cache/$name.wl.txt | tr -d [:punct:] > cache/$name.tmp.txt
	#Removing Carriage Return from Each File Words List
        sed 's/\r$//' cache/$name.tmp.txt > cache/$name.tmp.txt.bak && mv cache/$name.tmp.txt.bak cache/$name.tmp.txt
        #Removing New Blank Line from Each File Words List
	awk 'NF' cache/$name.tmp.txt > cache/$name.tmp.txt.bak && mv cache/$name.tmp.txt.bak cache/$name.tmp.txt
	#Excluding Repetition of Words from Each File Words List
	cat -n cache/$name.tmp.txt | sort -uk2 | sort -n | cut -f2- > cache/$name.wl.txt #Line Added

	#Counting Number of Words Present in Each File Words List
        count=$(cat cache/$name.wl.txt | wc -l)
        #Printing for Testing Purpose
        echo "Total number of words in $name.wl.txt:"
        echo $count
        for ((j=1;j<=$count;j++))
        do
                cat cache/tmp.aes  >> data/csp_keyvalue.txt
        done

done
echo -e "Files Encrypted Succesfully!"

#In real case, Encrypted files will be present on Cloud
cp -r D184MB_E/*.aes ../user_search/D184MB_E/

end_FE=`date +%s.%N`
runtime_FE=$( echo "$end_FE - $start_FE" | bc -l)
echo "Runtime of Encrypting all Data Files:"$runtime_FE "seconds"

########################################################################################

########################################################################################

#Creating Combined Words Lists

#Words List Timer
start_wl=`date +%s.%N`

#Concatenating all Files Word Lists
echo -e "\nConcatenating all Files Words List..."
cp /dev/null cache/merged_files.txt
#cat D184MB/*.txt >> cache/merged_files.txt 
cat cache/*.wl.txt >> cache/merged_files.txt #Added
echo -e "Merged Successful!"
echo -e "\nReinitiating Words List Process..."
cp /dev/null cache/tmp.txt
cat cache/merged_files.txt | while read line
do 
	for word in $line
	do
		echo $word >> cache/tmp.txt 
	done
done
#Removing punctuations from words list
cp /dev/null cache/words_list.txt
cat cache/tmp.txt | tr -d [:punct:] > cache/words_list.txt
rm cache/tmp.txt
cp /dev/null cache/uniq_wl.txt
#cat cache/words_list.txt | uniq > cache/tmp.txt 
cat cache/words_list.txt > trash/tmp.txt
sed 's/\r$//' trash/tmp.txt > trash/tmp.txt.bak && mv trash/tmp.txt.bak trash/tmp.txt
awk 'NF' trash/tmp.txt > trash/tmp.txt.bak
#cat -n cache/tmp.txt.bak | sort -uk2 | sort -n | cut -f2- > cache/uniq_wl.txt 
cat trash/tmp.txt.bak > cache/uniq_wl.txt
rm trash/tmp.txt.bak
echo -e "Words List Created Succesful!\n"

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
cp /dev/null data/hash_wl.txt
cp /dev/null data/num_files.txt
cp /dev/null data/num_search.txt

#Timer for the Hashing Function
start_h=`date +%s.%N`

while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}'  >> data/hash_wl.txt
	echo "$line" | xargs grep -rw 'D184MB/' -e | wc -l >> data/num_files.txt
	echo "$ns_var" >>  data/num_search.txt	
done < cache/uniq_wl.txt

end_h=`date +%s.%N`
runtime_h=$( echo "$end_h - $start_h" | bc -l)
echo -e "\nRuntime of Hashing Algorithm:"$runtime_h "seconds"

########################################################################################
#Calculating number of occurence of word and files containg that particular keyword
#This loop will run for the total number of files present in D184MB folder
#for filename in D184MB/*.txt
#do
	#This while loop will run for the total number of uniq words that are present in uniq_wl.txt
#	echo ${filename}
#	name=$(echo ${filename} | sed -e 's#D184MB/##g')
#	cp /dev/null cache/$name.count
#	while IFS= read -r line
#	do
#		grep -o -i $line $filename | wc -l >> cache/$name.count 
#
#	done < cache/uniq_wl.txt
#done

########################################################################################

#Timer for Kw and CSP Function
start_m=`date +%s.%N`

#Calculating Kw=SHA256(keyword+numsearch)
paste data/hash_wl.txt data/num_search.txt > data/keyword_numsearch.txt
cp /dev/null data/Kw.txt
while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}' >> data/Kw.txt

done < data/keyword_numsearch.txt

#Computing csp_keywords_address=SHA256(Kw+numfiles)
paste data/Kw.txt data/num_files.txt > data/Kw_numfiles.txt
cp /dev/null data/csp_keywords_address.txt
while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}' >> data/csp_keywords_address.txt
done < data/Kw_numfiles.txt

paste data/hash_wl.txt data/num_files.txt data/num_search.txt > data/sse_keywords.txt

end_m=`date +%s.%N`
runtime_m=$( echo "$end_h - $start_h" | bc -l)
echo -e "\nRuntime of Kw and CSP Address Algorithm:"$runtime_m "seconds"

paste data/csp_keywords_address.txt data/csp_keyvalue.txt > data/sse_csp_keywords.txt

########################################################################################

#for filename in D184MB/*.txt
#do
#	echo ${filename}
#done

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

echo "Attempting to create entries in sse_keywords table..."

mysql -u$USER -p$PASS -P$PORT -D$DB -se "delete from sse_keywords"
mysql -u$USER -p$PASS -P$PORT -D$DB -se "ALTER TABLE sse_keywords AUTO_INCREMENT = 1"
#Make Sure to change path in case of different user or directory
mysql -u$USER -p$PASS -P$PORT -D$DB -se "LOAD DATA LOCAL INFILE 'data/sse_keywords.txt' REPLACE INTO TABLE sse_keywords FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' (sse_keyword,sse_keyword_numfiles,sse_keyword_numsearch) "

#echo "Uploading Done!"

echo "Attempting to create entries in sse_csp_keywords table.."

mysql -u$USER -p$PASS -P$PORT -D$DB -se "delete from sse_csp_keywords"
mysql -u$USER -p$PASS -P$PORT -D$DB -se "ALTER TABLE sse_csp_keywords AUTO_INCREMENT = 1"
#Make Sure to change path in case of different user or directory
mysql -u$USER -p$PASS -P$PORT -D$DB -se "LOAD DATA LOCAL INFILE 'data/sse_csp_keywords.txt' REPLACE INTO TABLE sse_csp_keywords FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' (csp_keywords_address,csp_keyvalue)"

#echo "Uploading Done!"

#mysql -u$USER -p$PASS -P$PORT -D$DB -se "Select * from sse_keywords; Select * from sse_csp_keywords"

########################################################################################

end=`date +%s.%N`
runtime=$( echo "$end - $start" | bc -l)
echo -e "\nTotal Runtime of Script:"$runtime "seconds"

