# BeesRadars
Matlab scripts for the BeesRadars project

## Processing: 
level offset, find and retain peaks, average for each sample and channel, calculate peak_energy (integral of peaks surface), normalise to max channel value per sample

`process.m` for static experiments and `process_rot.m` for rotating experiments
`peak_energy_norm` variables will be saved in folder `data`

you can set a path where the workspace will be saved, it is over 2GB, you will need the latest .mat files version enabled in Matlab

## Plot peak energy data: 
`plot_bee_angles_heights.m` 

You'll find the plots I produced in `peak energy plots`

## Construct data model (lookup or Gaussian) for a given experiment

`construct_lookup_model.m` for a lookup model and `construct_gauss_model.m` for a Guassian model

the models are saved in folder `models`

use cftool with my Gaussian function (custom equation) if you want to construct a Gaussian model for new data. 

## Test data models across experiments

use a model from one experiment to predict angles for another experiment and compare with factual angles

`fit_angles_lookup.m` for a lookup model and `fit_angles_gauss.m` for a Guassian

You'll find validation plots in folder `cross-modelling plots`

## Machine learning

Data must be in form of a table, with angles being the first column and peak_energy_norm columns 2-6. See `prepare_ML_data.m`. Other scripts use it to prepare data

training a model on the data from a set of experiments: `train_ML_model.m`

the model (GPR) was optimised for data from exp. 21-26. You can train it on a subset of experiments or on new data, varying the limit angle (limiting to -6,6 has given best results so far).

To optimise a new model to new data, use `Regression learner` Matlab tool 

model will be saved in folder `MLmodels`

You'll find model response plots in folder `ML plots`


validating a model: training on static data, predicting rotating data
`ML_predict_validate.m`


predicting angles for new data: `ML_predict.m`
