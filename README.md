# IDMIM

## check cohort specfici details
1) 'setDatasetSpecifics'

## organize data 
1) move 'dataFolderStructure' wherever you would like to save the data to. All data will be saved into that folderstructure.
2) move MEDPC txt files into 'dataFolderStructure/data/raw/'
3) rename subfolders in 'dataFolderStructure/data/' and 'dataFolderStructure/results/' using the names you use for your cohorts (mouse experiments/studies) and delete any unused template files


## get pipeline ready
1) open the runOptions.m function and specify your settings:
    * the MEDPC file settings should work as they are if they are built as instructed below (---TO ADD)
    * the path of your data folder in the paths section
    * the model space and everything that goes with that
    * the name endings you want to give your files

2) open setDatasetSpecifics.m and specify everything related to your cohort(s). Delete all lines containing cohorts you do not need. E.g. if you are processing 2 instead of 3 cohorts, fill in the info for the 2 cohorts and delete everything containing optionsFile.cohort(3)

3) specify what you want to run in runOptions. This can be changed at any time

4) run this function by entering runOptions into command line or pressing the green triangle play button when you open runOptions.m in MATLAB


## RUN analysis

use runAnalysis(1) in the command line to run the analysis pipeline with the steps you specified before for cohort 1.

all steps can be run seperately too, you will just need to specify the input arguments manually. 
For example: you can parameterRecovery(cohortNo,subCohort,iTask,iCondition,iRep,nReps) if you fill in the information for each one of these input arguments as you had specified them in the optionsfile. YOu can also read each functions descriptions if you are having trouble.


## CHANGING what to analyise etc
 
 if you want to change what you want to analyse (change the steps), or change settings in the options. Manually change that in the runOptions.m function and run the function again via commandline or by pressing the green triangle play button when you open runOptions.m in MATLAB
