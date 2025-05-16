# IDMIM (Impaired Decision-Making In Mice)

IDMIM is a MATLAB pipeline for analysing rodent operant decision-making data using computational models. This framework implements hierarchical Gaussian filter (HGF) models and Rescorla-Wagner reinforcement learning models to characterise learning and volatility parameters from behavioural choice data.

## Features
- Extraction and processing of experimental data from MED-PC files
- Fitting of multiple computational models:
    - 3-level Hierarchical Gaussian Filter (HGF)
    - 2-level Hierarchical Gaussian Filter
    - Rescorla-Wagner (RW) model
- Model comparison using Bayesian Model Selection
- Parameter recovery analysis for model validation
- Automated creation of analysis tables for statistical testing
- Comprehensive visualisation of model fits and parameters

## Prerequisites
- MATLAB R2019b or newer
- TAPAS Toolbox (for HGF models)
- SPM12 Toolbox (for Bayesian Model Selection)
- Input data from MedAssociates MED-PC in text format

## Installation
1. Clone or download this repository
2. Add the repository and its subfolders to your MATLAB path
3. Download and install the required toolboxes:
    1. TAPAS Toolbox
    2. SPM12

## Getting Started
### Data Organisation
1. Create the data folder structure:
    > /path/to/data/
    >  ├── raw/
    > │   ├── 2023_UCMS/
    > │   ├── 2024_HGFPilot/
    > │   └── 5HT/
    > ├── 2023_UCMS/
    > ├── 2024_HGFPilot/
    > └── 5HT/
2. Place your MED-PC text files in the appropriate raw/[cohort_name]/ folder
3. Rename the cohort folders according to your experimental cohorts

### Configuration
1. Set Data Paths:
    1. Open runOptions.m
    2. Set `optionsFile.paths.saveDir` to your data directory path
2. Configure Cohort Details:
    - Edit setDatasetSpecifics.m to specify:
        1. Mouse IDs and group assignments (treatment/control)
        2. Task names and parameters
        3. Conditions and task repetitions
        4. Exclusion criteria
3. Select Analysis Steps:
- In `runOptions.m`, enable/disable steps by setting to 1 (run) or 0 (skip):

      optionsFile.doOptions = 1;           % Generate option file

      optionsFile.doGetData = 1;           % Extract data from MED-PC files

      optionsFile.doSimulations = 1;       % Run model simulations

      optionsFile.doModelInversion = 1;    % Fit models to data

      optionsFile.doBMS = 1;               % Perform Bayesian Model Selection

4. Generate Options File:
    - Run `runOptions` in MATLAB to create optionsFile.mat

## Running the Analysis

### Full Pipeline

Run the complete analysis pipeline for a specific cohort:

```matlab
runAnalysis(cohortNo)  % Where cohortNo is the cohort index (e.g., 1, 2, or 3)
```

### Individual Components

You can also run specific components separately:
```matlab
    % Extract data from MED-PC files
    getData(cohortNo);
   
    % Fit models to behavioural data
    fitModels(cohortNo);
    
    % Parameter recovery analysis
    parameterRecovery(cohortNo, subCohort, iTask, iCondition, iRep, nReps);

    % Bayesian Model Selection 
    performBMS(cohortNo, subCohort, iTask, iCondition, iRep);

    % Generate analysis tables for specific hypotheses
    createHypothesis1_2_Table();  % Treatment vs. control learning parameters
    createHypothesis2_2_Table();  % Learning parameter changes across repetitions
    createHypothesis3_2_Table();  % Drug treatment effects on volatility parameters
```

## Output Files
The pipeline produces several types of output files:
- Processed data files (`.mat`): Contains trial-by-trial behavioral data
- Model fit results (`.mat`): Individual model parameters for each mouse
- Analysis tables (`.csv`): Summary tables for statistical analysis
- Diagnostic plots (`.png`/`.fig`): Parameter recovery, model comparison, and trajectory plots

## Troubleshooting
- File not found errors: Verify your path structure matches what's specified in `optionsFile`
- Model fitting errors: Check your data format and ensure all required columns are present
- Memory issues: For large datasets, consider processing cohorts individually

## License
This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## Citation
If you use this pipeline in your research, please cite:
[Citation information to be added upon publication]
