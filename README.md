# fmri-experiment-bundle

This fMRI experiment template is part of the guide ["How to plan and run an fMRI experiment"](https://edden-gerber.github.io/plan_and_run_fmri_exp/). It contains the following: 
* **Experiment checklist example**
* **Experiment protocol example**
* **Participant briefing checklist example**
* **Code for example visual fMRI experiment (with eye-tracking)**: Written in Matlab using PsychToolBox. You can modify this code to create your own experiment or better understand how to build one. Includes the following files:
  * _visual_fMRI_exp_with_EyeLink.m_: experiment code
  * _exp_codes.mat_: example experiment trial conditions data
  * _Generate_Trial_Lists.m_: code to generate _exp_codes_
  * _instructions_eng.txt_: experiment instructions text
  * _Stimuli_ folder: stimulus images used by the experiment.
  

The experiment itself is a visual fMRI experiment with eye-tracking. During each 34.5 second trial, an image of a face or a house appears for 9 or 15 seconds. Throughout the trial the participant should focus on a central fixation cross, which in rare occasions changes briefly from a '+' to a '|' (horizontal line disappears) - and in such cases the participant needs to press the response button. Yes, this experiment is excruciatingly boring. 

