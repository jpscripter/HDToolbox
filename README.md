# HelpDeskHelper

## Summary
This tool is designed to be a flexible platform for support teams to organize their common tests and remediation scripts. 

## Usage


## Design

### Structure
1) HelpDeskHelper
    1) Main.ps1
        * this is script that will manage the UI and the contains the logic
    1) Setup/
        1) *.ps1 - This scripts returns a hashtable of parameters and their 
    1) Tests/
        1) *.ps1 - these scripts are specific to the organiation but should throw if the test fails
    1) Remediation/
        1) *.ps1 - Scripts that can be run to fix known problems
    1) Gather/
        1) *_Start.ps1
            * Runs when starting a 
        1) *.ps1 
            * all other scripts 
    1) Modules
        * Folder for all of the logic and modules used by the scripts