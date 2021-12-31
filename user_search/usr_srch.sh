#!/bin/bash

#Initializing Key
key=$(cat ../data_owner/config/my.key)

read -p  "Enter word for search:" word
key_word=$(echo -n "$word" | sha256sum | awk '{print $1}')
echo "Hash of Entered Keyword is:" $key_word
echo ""

#######################
#Starting Timer
start=`date +%s.%N`
#######################

################################# MySQL Connectivity ###################################

echo -e "\nConnecting to MySQL...\n"

####### MySql Connection Details #######
USER='owais'
PASS='pass123'
PORT=3306
HOST='localhost'
DB='cwdb'
########################################

mysql -u$USER -p$PASS -P$PORT -D$DB -se "USE cwdb"
mysql -u$USER -p$PASS -P$PORT -D$DB -se "SELECT * from sse_keywords" > data/sse_keywords.txt
#mysql -u$USER -p$PASS -P$PORT -D$DB -se "SELECT * from sse_csp_keywords" > data/sse_csp_keywords.txt
mysql -u$USER -p$PASS -P$PORT -D$DB -sNe "SELECT * from sse_keywords where sse_keyword like '%$key_word%'" > cache/search_sse.txt

########################################################################################

check=$(cat cache/search_sse.txt | wc -l)
#Testing
#echo "\nCheck Value:" $check

if [[ $check == '0' ]]
then
	echo "No Match Found"
	exit 1
fi

#Separating Identities
cp /dev/null data/sse_keywords_id.txt
cp /dev/null data/hash_keywords.txt
cp /dev/null data/num_files.txt
cp /dev/null data/num_search.txt
while IFS= read -r line
do
  	echo -n "$line" | awk '{print $1}' >> data/sse_keywords_id.txt
  	echo -n "$line" | awk '{print $2}' >> data/hash_keywords.txt
        echo -n "$line" | awk '{print $3}' >> data/num_files.txt
        echo -n "$line" | awk '{print $4}' >> data/num_search.txt
done < cache/search_sse.txt

#Testing
#echo -e "\nsearch_sse.txt"
#cat cache/search_sse.txt

###################################################
cp /dev/null cache/inc_num_search.txt
while IFS= read -r line
do
        inc=$(($line+1))
        echo "$inc" >> cache/inc_num_search.txt

done < data/num_search.txt

paste data/sse_keywords_id.txt data/hash_keywords.txt data/num_files.txt cache/inc_num_search.txt > cache/updated_sse_keywords.txt
#Making an update copy to send it to CSP or in ourcase to data_owner
cp cache/updated_sse_keywords.txt ../data_owner/data/updated_sse_keywords.txt
#Testing
#echo -e "\nupdated_sse_keywords.txt "
#cat cache/updated_sse_keywords.txt
#####################################################################

#####################################################################
#Calculating Kw=SHA256(keyword+numsearch)

#For Matching
paste data/hash_keywords.txt data/num_search.txt > data/keyword_numsearch.txt
cp /dev/null data/Kw.txt
while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}' >> data/Kw.txt

done < data/keyword_numsearch.txt
#Testing
#echo -e "\nKw.txt"
#cat data/Kw.txt

#For Updating
paste data/hash_keywords.txt cache/inc_num_search.txt > cache/keyword_inc_numsearch.txt
cp /dev/null cache/updt_Kw.txt
while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}' >> cache/updt_Kw.txt

done < cache/keyword_inc_numsearch.txt
#Testing
#echo -e "\nUpdated_Kw.txt"
#cat cache/updt_Kw.txt

#Calculating csp_keywords_address=SHA256(Kw+numfiles)

#For Searching
paste data/Kw.txt data/num_files.txt > data/Kw_numfiles.txt
cp /dev/null data/csp_keywords_address.txt
while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}' >> data/csp_keywords_address.txt
done < data/Kw_numfiles.txt
#Testing
#echo -e "\ncsp_keywords_address.txt"
#cat data/csp_keywords_address.txt


#For Updating
paste cache/updt_Kw.txt data/num_files.txt > cache/updt_Kw_numfiles.txt
cp /dev/null cache/updt_csp_keywords_address.txt
while IFS= read -r line
do
        echo -n "$line" | sha256sum | awk '{print $1}' >> cache/updt_csp_keywords_address.txt
done < cache/updt_Kw_numfiles.txt
#Making an update copy to transfer it to CSP or in our case to data_owner
#cp cache/updt_csp_keywords_address.txt ../data_owner/data/updt_csp_keywords_address.txt
#Testing
#echo -e "\nupdt_csp_keywords_address.txt"
#cat cache/updt_csp_keywords_address.txt
#####################################################################

cp ../data_owner/D184MB_E/*.aes D184MB_E/
cp ../data_owner/D184MB_IE/*.aes D184MB_E/

cp data/csp_keywords_address.txt cache/csp_keywords_address.txt.tmp
cat -n cache/csp_keywords_address.txt.tmp | sort -uk2 | sort -n | cut -f2- > cache/csp_keywords_address.txt.tmp.bak  && mv cache/csp_keywords_address.txt.tmp.bak cache/csp_keywords_address.txt.tmp

cp /dev/null cache/search_csp.txt
while IFS= read -r line
do
	mysql -u$USER -p$PASS -P$PORT -D$DB -sNe "Select * from sse_csp_keywords where csp_keywords_address like '%$line%'" >> cache/search_csp.txt

done < cache/csp_keywords_address.txt.tmp

#Separating csp_keywords_address identity as variable
#csp_keywords_address=$(sed '1q;d' data/csp_keywords_address.txt)
#Testing
#echo -e "\ncsp_keywords_address:" $csp_keywords_address
#Searching for csp_keywords_address in mysql sse_csp_keywords table
#mysql -u$USER -p$PASS -P$PORT -D$DB -sNe "Select * from sse_csp_keywords where csp_keywords_address like '%$csp_keywords_address%'" >cache/search_csp.txt
#Testing
#cat cache/search_csp.txt

cp /dev/null data/csp_keywords_id.txt
cp /dev/null data/csp_keywords_address.txt
cp /dev/null data/csp_keyvalue.txt
#Decoding File name from search_csp.txt
rm -r tmp/*.aes
while IFS= read -r line
do
	echo -n "$line" | awk '{print $1}' >> data/csp_keywords_id.txt
        echo -n "$line" | awk '{print $2}' >> data/csp_keywords_address.txt
        echo -n "$line" | awk '{print $3}' >> data/csp_keyvalue.txt

        count=$(cat cache/search_csp.txt | wc -l)
#	echo "Count:" $count #Debugging
        for ((i=1 ; i<=$count; i++))
        do
               sed "${i}q;d" cache/search_csp.txt | awk '{print $3}' > tmp/filename$i.aes
	       decode=$(openssl aes-256-ecb -d -in tmp/filename$i.aes -K $key -out tmp/filename$i.txt -p -a -nosalt)
#	       echo "Loop Counter:" $i  #Debugging
        done
done < cache/search_csp.txt

echo -e "\nCounting number of files in which Keyword is Present.."
count=$(ls tmp/filename*.aes | wc -l)
echo "Number of files in which keyword is Present: $count"

for ((i=1; i<=$count; i++))
do
	silent=$(cat tmp/filename$i.txt)
        sed -i -e 's/txt/aes/g' tmp/filename$i.txt
        name=$(sed "1q;d" tmp/filename$i.txt)
	ename=$(echo $name | sed -e 's#.aes##g')
        echo -e "\nFile to decrypt:" $name
        decrypt_file=$(openssl aes-256-ecb -d -in D184MB_E/$name -K $key -out D184MB/$ename.txt -p -a -nosalt)

done

cp /dev/null cache/sse_csp_keywords.txt
paste data/csp_keywords_id.txt cache/updt_csp_keywords_address.txt data/csp_keyvalue.txt > cache/update_sse_csp_keywords.txt
cp cache/update_sse_csp_keywords.txt ../data_owner/data/update_sse_csp_keywords.txt

echo -e "\nFiles with the keywords has been placed in D184MB/ folder." 

end=`date +%s.%N`
runtime=$( echo "$end - $start" | bc -l)
echo -e "\nRuntime of Program:"$runtime "seconds"
