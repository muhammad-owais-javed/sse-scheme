#!/bin/bash

echo -e "\nUpdating..."

#######################
#Starting Main Timer
start=`date +%s.%N`
#######################

######################### MySQL Connectivity ##########################

echo -e "\nConnecting to MySQL...\n"

####### MySql Connection Details #######
USER='owais'
PASS='pass123'
PORT=3306
HOST='localhost'
DB='cwdb'
#A_PATH='/home/owais/COURSEWORKII/data_owner' #End Path without forward slash /
########################################################################

#Separating Identities
cp /dev/null cache/updt_sse_keywords_id.txt
cp /dev/null cache/updt_hash_keywords.txt
cp /dev/null cache/updt_num_files.txt
cp /dev/null cache/updt_num_search.txt
while IFS= read -r line
do
	u_id=$(echo -n "$line" | awk '{print $1}') #>> cache/updt_sse_keywords_id.txt
	u_hash=$(echo -n "$line" | awk '{print $2}') #>> cache/updt_hash_keywords.txt
	u_numfile=$(echo -n "$line" | awk '{print $3}') #>> cache/updt_num_files.txt
	u_numsrch=$(echo -n "$line" | awk '{print $4}') #>> cache/updt_num_search.txt

mysql -u$USER -p$PASS -P$PORT -D$DB -sNe "UPDATE sse_keywords SET sse_keyword_numsearch =$u_numsrch WHERE sse_keywords_id=$u_id"
mysql -u$USER -p$PASS -P$PORT -D$DB -sNe "SELECT sse_keywords_id,sse_keyword,sse_keyword_numfiles,sse_keyword_numsearch FROM sse_keywords WHERE sse_keywords_id =$u_id"
done < data/updated_sse_keywords.txt

echo -e "\n"

#Separating Identities for csp
cp /dev/null cache/updt_csp_keywords_id.txt
cp /dev/null cache/updt_csp_keywords_address.txt
cp /dev/null cache/updt_csp_keyvalue.txt

while IFS= read -r line
do
        ucsp_id=$(echo -n "$line" | awk '{print $1}') 
        ucsp_keyaddr=$(echo -n "$line" | awk '{print $2}') 
        ucsp_keyvalue=$(echo -n "$line" | awk '{print $3}')

mysql -u$USER -p$PASS -P$PORT -D$DB -sNe "UPDATE sse_csp_keywords SET csp_keywords_address='$ucsp_keyaddr' WHERE csp_keywords_id=$ucsp_id"
mysql -u$USER -p$PASS -P$PORT -D$DB -sNe "SELECT csp_keywords_id,csp_keywords_address,csp_keyvalue FROM sse_csp_keywords WHERE csp_keywords_id =$ucsp_id"
done < data/update_sse_csp_keywords.txt

end=`date +%s.%N`
runtime=$( echo "$end - $start" | bc -l)
echo -e "\nTotal Runtime of Updating Script:"$runtime "seconds"

