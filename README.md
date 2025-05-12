IDMIM (Impaired Decision-Making In Mice)
###Overview###
IDMIM is a MATLAB pipeline for analysing behavioural data from rodent operant decision-making tasks using computational models. 
It implements hierarchical Gaussian filter (HGF) models and other reinforcement learning models to characterise learning 
parameters from choice data.

Prerequisites:
- MATLAB R2019b or newer
- TAPAS Toolbox for HGF models
- Input data from MED-PC in text format

Installation:
1) Clone or download this repository
2) Add the repository and its subfolders to your MATLAB path
3) Download and install the TAPAS toolbox

Data Organisation:
1) Create a data folder structure using the provided template:
/path/to/data/
├── raw/
│   ├── cohort1/
│   ├── cohort2/
│   └── cohort3/
├── cohort1/
├── cohort2/
└── cohort3/
2) Place your MED-PC text files in the appropriate raw/cohortX/ folder
3) Rename the cohort folders according to your experimental cohorts (e.g., "2023_UCMS", "2024_HGFPilot")


###Configuration###
Setting Up Cohort Details
1) Open setDatasetSpecifics.m
2) Edit the cohort-specific details for each of your cohorts:
    - Mouse IDs and group assignments
    - Task names and parameters
    - Conditions and task repetitions
    - File structure information

Configuring Analysis Options
1) Open runOptions.m and set the following:
    - Data paths: Specify where your data is stored
    - Model space: Choose which computational models to use
    - Analysis steps: Enable/disable different analysis components
    - File naming conventions: Set naming patterns for output files
2) Run the function to generate your optionsFile.mat


###Running the Analysis###
Full Pipeline
- Run the complete analysis pipeline for a specific cohort:
- runAnalysis(cohortNo)  % Where cohortNo is the cohort number (e.g., 1, 2, or 3)

Individual Components
You can run specific components of the pipeline separately:
- Extract data from MED-PC files
- getData(cohortNo)

Fit computational models to behavioural data:
fitModels(cohortNo)  % Where cohortNo is the cohort number (e.g., 1, 2, or 3)

Perform parameter recovery analysis:
parameterRecovery(cohortNo, subCohort, iTask, iCondition, iRep, nReps);

Perform Bayesian Model Selection:
performBMS(cohortNo, subCohort, iTask, iCondition, iRep)

Creating Summary Tables for Statistical Analysis


Model fit results (.mat files with model parameters)
Summary tables (.csv files for statistical analysis)
Diagnostic plots (parameter recovery, model comparison)


###Troubleshooting###
File not found errors: Make sure your path structure matches what's specified in optionsFile
Model fitting errors: Check your data format and ensure all required columns are present
Memory issues: For large datasets, consider processing cohorts individually

License:
This project is licensed under the GPL v3 License - see the LICENSE file for details