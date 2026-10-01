#!/bin/sh
#
#!/usr/bin/bash
#
#!/usr/bin/env bash
#will find the first bash program listed in your path
#use whichever works for your setup

#run using: (assuming script is saved as redo-analysis-archive-run.sh)
#bash /path/to/scripts/redo-analysis-archive-run.sh

#When using VS Code: when used in Windows - will cause error when running on linux server, b/c inserts windows EOL character /r instead of /n - change in VS code settings
#set +H



#Variables:

#User is instructed in SOP to navigate to directory where RunID number is last part of the path (e.g. path/to/analysis/RunID#)
#Then they run the bash script: bash /path/to/scripts/redo-analysis-archive-run2.sh

#-----------------Store directory name (Sequencer Run ID part of path you're in)
DIRNAME1=${PWD##*/}
#Assumed directory structure is as illustrated in https://github.com/Kim-Macdonald/merge_ncov_qc_results
#or https://github.com/Kim-Macdonald/mergeQCresults_plusMissing

#tell the user the RunID where you'll be removing libraries (in case they navigated to the wrong path above)
echo $DIRNAME1

#-----------------store input file names etc:

#regex (regular expressions) used for file1b and AnalysisFile1 (parses out first part of file1's name to search for other directories and files)
# ## removes a prefix pattern. ##*/ Removes the prefix and any number of characters followed by /. e.g. fspec=/path/to/some/file.txt ; echo ${fspec##*/} outputs: file.txt
# %% removes as much as possible, % as little as possible. e.g. for t="hello.world.txt" # echo ${t%.*} will output: hello.world # echo ${t%%.*} will output: hello

#Look in current directory (./) (that SOP told user to navigate to and run script) for a file with the name specified in file1 line
for file1 in ./*_VoC_OrderedFinal.csv
do
    file1b=${file1##*/} #extract and store file name. Keep everything after the last path separator /. 
    AnalysisFile1=${file1b%%.*} #analysis file input has file1b text as first part of filename (%% keeps everything before the .; removes everything after the .)
done

for file2 in ./*_PlusVoCcalls_AnalysisTimes.csv
do
    file2b=$(basename -- "$file2") #removes the filepath from path and filename, and just keeps the filename (e.g. file.txt)
    AnalysisFile2=${file2b%%.*} #removes everything after the . (keeps 1st part of filename. e.g. for file.txt -> keeps "file" (removes .txt))
done


#Commands:


#-----------------Rename 2 analysis csv files from Kims scripts:

echo "Renaming the original analysis csv files to _v0.csv" #&&    #&& lets you do something based on whether the previous command completed successfully. I played around with adding this, and it didn't work as I wanted, so I commented them out. 

#test first:
#echo "$AnalysisFile1" &&
#echo "$AnalysisFile2" &&

mv ./$AnalysisFile1.csv ./${AnalysisFile1}_v0.csv #&& #renames files to have _v0 at end (to save a backup of the original first, and change name so that the scripts that process analysis results files, don't use the old file (so we change it's name, so it uses the new file, which will have the name the old file had first (the name we changed - without the _v0))
mv ./$AnalysisFile2.csv ./${AnalysisFile2}_v0.csv #&&



#-----------------Copy the Run directory to archived_analysis:
echo "copying $DIRNAME1 directory to archived_analyses"
cd /path/to/analysis_by_run

if [[ $? = 0 ]] # if the previous commands were successful/finished, then run the following lines (tells the user what it's doing - copying files to archive). Otherwise print the failed statement and exit. $? is the exit status of the most recently-executed command; by convention, 0 means success and anything else indicates failure. 
then
echo "cp -r $DIRNAME1/ /path/to/archived_analyses/"
cp -r $DIRNAME1/ /path/to/archived_analyses/
else
echo "Failed navigating to archive for copy"
(echo -e "Hello,\n\nNavigating to archive failed for $DIRNAME1 (if this is not a runID you may have run the script in the wrong directory) on Sabin\n\n`pwd`\n\n" | mail -s "Re-analysis for $DIRNAME1 FAILED on Sabin" -r `whoami`@serverAddress.ca kim@email.ca,mini.mouse@email.ca,mickey.mouse@email.ca)
exit 1
fi

#Replace email addresses, server names (e.g. Sabin) above with your own

#/n is newline character - creates a new line (used with -e for echo to print a newline) and \n\n creates 2 newlines (and the next line of text is on the 2nd line) e.g:
#Hello,
#
#Navigating to archive failed for ....

#----------------Delete old analysis:

if [[ $? = 0 ]] #if prior command successful, tell user you're going back to analysis directory and then actually go back to that directory. If prior command failed, print error to screen and email users to notify what stage failed.
then
echo "navigating back to analysis directory: /path/to/analysis_by_run/$DIRNAME1"
cd /path/to/analysis_by_run/$DIRNAME1
else
echo "Failed copying to archive"
(echo -e "Hello,\n\nCopying to archive failed for $DIRNAME1 (if this is not a runID you may have run the script in the wrong directory) on Sabin\n\n`pwd`\n\n" | mail -s "Re-analysis for $DIRNAME1 FAILED on Sabin" -r `whoami`@serverAddress.ca kim@email.ca,mini.mouse@email.ca,mickey.mouse@email.ca)
exit 1
fi

if [[ $? = 0 ]] #if prior command successful, tell user you're deleting old analysis files, and delete them. If prior command failed, print error to screen and email users to notify what stage failed.
then
echo "deleting old analysis with: rm -r ncov2019-artic-nf-v1.3-output"
rm -r ncov2019-artic-nf-v1.3-output
else
echo "Failed navigating back to RunID directory"
(echo -e "Hello,\n\nNavigating back to RunID directory failed for $DIRNAME1 (if this is not a runID you may have run the script in the wrong directory) on Sabin\n\n`pwd`\n\n" | mail -s "Re-analysis for $DIRNAME1 FAILED on Sabin" -r `whoami`@serverAddress.ca kim@email.ca,mini.mouse@email.ca,mickey.mouse@email.ca)
exit 1
fi

#Replace email addresses, server names (e.g. Sabin) above with your own

#-----------------Re-run metadata script:

if [[ $? = 0 ]] #if prior command successful, tell user you're running metadata script and run it. If prior command failed, print error to screen and email users to notify what stage failed.
then
echo "Running metadata script"
#conda activate pandas; python3 /path/to/scripts/CleanMetadata_CreateMetadataTsvFileForRun_v0.py; conda deactivate
#Change to archaic method or get error when activate conda envs within bash script.
source activate pandas; python3 /path/to/scripts/CleanMetadata_CreateMetadataTsvFileForRun_v0.py; deactivate
else
echo "Failed deleting old analysis ncov2019-artic-nf-v1.3-output"
(echo -e "Hello,\n\nDeleting old analysis ncov2019-artic-nf-v1.3-output failed for $DIRNAME1 (if this is not a runID you may have run the script in the wrong directory) on Sabin\n\n`pwd`\n\n" | mail -s "Re-analysis for $DIRNAME1 FAILED on Sabin" -r `whoami`@serverAddress.ca kim@email.ca,mini.mouse@email.ca,mickey.mouse@email.ca)
exit 1
fi

#Replace email addresses, server names (e.g. Sabin) above with your own


#-----------------Re-run artic:

if [[ $? = 0 ]] #if prior command successful, tell user you're running artic analysis and run it. If prior command failed, print error to screen and email users to notify what stage failed.
then
echo "Running artic now..."
echo "export ANALYST_NAME=”KimM”; export ANALYST_EMAIL=kim@email.ca; run-ncov2019-artic-nf"
export ANALYST_NAME=”KimM”; export ANALYST_EMAIL=kim@email.ca; run-ncov2019-artic-nf
else
echo "Failed running metadata script"
(echo -e "Hello,\n\nRunning metadata script failed for $DIRNAME1 (if this is not a runID you may have run the script in the wrong directory) on Sabin\n\n`pwd`\n\n" | mail -s "Re-analysis for $DIRNAME1 FAILED on Sabin" -r `whoami`@serverAddress.ca kim@email.ca,mini.mouse@email.ca,mickey.mouse@email.ca)
exit 1
fi

#Replace email addresses, server names (e.g. Sabin) above with your own

#wait

#-----------------wait until artic is done, then Re-run ncov-tools with metadata AND pangolin (can run in parallel):

if [[ $? = 0 ]] #if prior command successful, tell user you're running ncovtools and pangolin and run it. If prior command failed, print error to screen and email users to notify what stage failed.
then
echo "Running ncov-tools and pangolin now: run-ncov-tools-nf & run-pangolin-nf"
run-ncov-tools-nf &
run-pangolin-nf &
wait
else
echo "Failed running artic"
(echo -e "Hello,\n\nRunning artic failed for $DIRNAME1 (if this is not a runID you may have run the script in the wrong directory) on Sabin\n\n`pwd`\n\n" | mail -s "Re-analysis for $DIRNAME1 FAILED on Sabin" -r `whoami`@serverAddress.ca kim@email.ca,mini.mouse@email.ca,mickey.mouse@email.ca)
exit 1
fi

#Replace email addresses, server names (e.g. Sabin) above with your own

if [[ $? = 0 ]]
then
echo "Done. Now run your other scripts as usual"
(echo -e "Hello,\n\nRe-analysis is complete for $DIRNAME1 on Sabin\n\n`pwd`\n\n" | mail -s "Re-analysis for $DIRNAME1 is complete on Sabin" -r `whoami`@serverAddress.ca kim@email.ca,mini.mouse@email.ca,mickey.mouse@email.ca)
else
echo "Failed running ncov-tools and/or pangolin"
(echo -e "Hello,\n\nRunning ncov-tools or pangolin failed for $DIRNAME1 (if this is not a runID you may have run the script in the wrong directory) on Sabin\n\n`pwd`\n\n" | mail -s "Re-analysis for $DIRNAME1 FAILED on Sabin" -r `whoami`@serverAddress.ca kim@email.ca,mini.mouse@email.ca,mickey.mouse@email.ca)
exit 1
fi
#Replace email addresses, server names (e.g. Sabin) above with your own
#pwd = present/current working directory
#make the script executable (+x adds executability) by changing permissions (in terminal) with:
#chmod +x /path/to/scripts/redo-analysis-archive-run.sh

#run screen before running this
#bash /path/to/scripts/redo-analysis-archive-run.sh
