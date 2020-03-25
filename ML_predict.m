%% use this script to predict bee angles for a new set of data using existing trained model
% Polina Proutskova, March 2020

%% set script parameters
folder_data = '/Users/polina/RESEARCH/BeesRadars/Bees program/data/'; % where data .mat files are
file_data = 'peak_energy_norm_exp26.mat'; % normalised peak energy data for which angles will be predicted
folder_models = '/Users/polina/RESEARCH/BeesRadars/Bees program/MLmodels/'; % where the model will be saved
exp_num = '26'; % for which angles will be predicted
model_name = 'model6_static+25'; 

%% load new data and create table for machine learning
pe_file = [folder_data, file_data];
if ~isfile(pe_file)
    sprintf('no file found: %s', pe_file)
else
    sprintf('loading peak energy from experiment %s', exp_num)
    % load normalised peak energy data from local
    load(pe_file, 'peak_energy_norm')
end
% create table from matrix with column names
MLdata = array2table(peak_energy_norm);
MLdata.Properties.VariableNames = {'ch1','ch2','ch3','ch4','ch5'};

%% load ML model
sprintf('loading ML model %s from %s', model_name, folder_models)
load([folder_models, model_name,'.mat'])

%% predict with ML model
yfit = model.predictFcn(MLdata)
