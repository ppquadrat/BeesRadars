%% this script validates model predictions of bee angles against original angle values
% Polina Proutskova, March 2020

%% set script parameters
folder_xls = '/Volumes/Bees_Drive/Radar_data/'; % where the angles spreadsheet is
folder_data = '/Users/polina/RESEARCH/BeesRadars/Bees program/data/'; % where energy_peak .mat files are
folder_models = '/Users/polina/RESEARCH/BeesRadars/Bees program/MLmodels/'; % where the model will be saved
model_name = 'model6_static+25'; 
experiments = {'26'}; %from which the data will be used for validation
angles_threshold = [-6, 6]; % only use test data with angles within this interval

%% load test data and create table for machine learning
MLdata = prepare_ML_data(folder_xls, folder_data, experiments, angles_threshold);

%% load ML model
sprintf('loading ML model %s from %s', model_name, folder_models)
load([folder_models, model_name,'.mat'])

%% predict with ML model
yfit = model.predictFcn(MLdata);

%% validate predictions
diff = yfit-MLdata.angles;
diffn = diff(~isnan(diff));
RMSE = sqrt(mean(diffn.^2));
sprintf('validation root mean square error RMSE = %.4f degrees', RMSE)
