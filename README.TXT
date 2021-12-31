#README FIRST FOR SYMMETRIC SEARCHABLE ENCRYPTION (SSE) SCHEME IMPLEMENTATION

#REQUIREMENT:
-LINUX OS (Tested on Kali Linux)
-MySQL MariaDB 10.x (Tested on MySQL Ver 15.1 Distrib 10.3.20-MariaDB)

If "bc" line calculator is not found which has been used in time calculation then it can be install with command

apt-get install bc

#MYSQL SERVICE MUST NEED TO BE IN RUNNING STATE

service mysql status
service mysql restart

#CORRESPONDING USER SHOULD HAVE SUFFICIENT PERMISSION TO ACCESS DATABASE
#NEW USER CAN BE CREATE AS WELL FOR DATABASE ACCESS AND USER SHOULD HAVE PRIVILEGES TO MAKE CHANGES ON DATABASE

CREATE USER 'owais’@'localhost' IDENTIFIED BY 'pass123';
GRANT ALL PRIVILEGES ON `cwdb`.*  TO 'owais'@'localhost';


#Directories and Files Info:
There are three main folders for this scheme
D184MB/ "Directory which contains all the sample text files"
data_owner/ "Directory from where all the critical operations regarding to creating of dictionary, encrypting files, building encrypted indexes, numsearch value update, addition of new files are done"
user_search/ "Directory from where user can search for keywords"

"\Data distribution is adjusted according to local system. For Cloud Environment, keys or files transferring or distribution of database will be different\"

Directory "data_owner/" and "user_search/" contains a script called "./clean.sh" which can be refresh to clear all cache files


#For Testing of Script
Transfer selected dataset files from D184MB/ directory to data_owner/D184MB/ so that processing can be done on those text files
"\For Example\"
cd D184MB/
cp 2.txt 3.txt 4.txt ../data_owner/D184MB/
(For Testing purpose, less files will take less time for e.g: 4 or 5 files will take approx 2 or 3 mins  )

Once dataset files are transferred, change directory for data_owner folder and then run sse_setup.sh
cd ../data_owner/
./sse_setup.sh

"./sse_setup.ssh" file should need to be run first in order to setup everything.
It will create dictionary of keywords, encrypt all files, create updated indexes
In our case, I have transferred key and encrypted files to user_search folder as we dont have TA or CSP environment
(Suppose that if you wish to run "sse_setup.sh" script again, then it is recommend to run "./clean.sh" first)

Now as everything is setup, script from user_search can be run to search for keyword and find corresponding file
cd ../user_search
./usr_srch.sh
Once script is run, it will ask for the keyword, entering any keyword will find corresponding file in which that keyword will be present
All the decrypted files will be placed in "D184MB/" folder after that


As user has searched for particular keyword, therefore number of search value needs to be increment.
In our case, I have kept the script separate however in Cloud Environment, it will be update without human intervention
For updating numsearch value, another script needs to be run
cd ../data_owner
./sse_update.sh
It will update the numsearch value and corresponding values which are dependent on it

User can search for another keyword again however it is good practice to run "./clean.sh" script in user_search folder before searching

Last but not the least, Add Files option. For adding any new file in the existing encrypted clutch and dictionary.
Files which owner wants to add must be place in "D184MB_I/" folder

cd ../D184MB/
cp 5.txt 7.txt ../data_owner/D184MB_I/

Once new files are moved, another script needs to be run
cd ../data_owner/
./sse_ins.sh

This script will make additional entries in Database and make incremental changes.
(Files must need to present in "D184MB_I" which will automatically be moved to "D184MB_E/" after encryption

If anything misshappens, then make sure to run ./clean.sh in both of the folders.
