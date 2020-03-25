%% use this script to train an existing model on new data
% Polina Proutskova, March 2020

%% set script parameters
folder_xls = '/Volumes/Bees_Drive/Radar_data/'; % where the angles spreadsheet is
folder_data = '/Users/polina/RESEARCH/BeesRadars/Bees program/data/'; % where energy_peak .mat files are
folder_models = '/Users/polina/RESEARCH/BeesRadars/Bees program/MLmodels/'; % where the model will be saved
experiments = {'21','22','23', '25','26'}; %from which the data will be used for training
angles_threshold = [-6, 6]; % only use training data with angles within this interval
model_name = 'model6'; % choose the name for the new model

%% load experimental data and create table for machine learning
MLdata = prepare_ML_data(folder_xls, folder_data, experiments, angles_threshold);

%% train model
% this GPR model was optimised for exp 21,22,23,25,26 with angle limit [-6.6]
% you will now train it with your data
% you can choose to use other models or create a new one

[model, validationRMSE] = trainModel6(MLdata);

sprintf('model trained')
sprintf('validation root mean square error RMSE = %.4f degrees', validationRMSE)

% To make predictions on a new table, T: 
%  yfit = model.predictFcn(T) 
% T should be of the same form as MLdata with angles as the first column

% to create a new model optimised for your data, open Regression Learner,
% click "new session", choose MLdata for observations and 'angles' as
% responses. In the session, choose 'All GPR' as model type and click
% 'train'. You can export the best model and the code for training 

%% save model
if exist(folder_models, 'dir') == 0
    mkdir(folder_models)
end
save([folder_models, model_name,'.mat'], 'model', '-v7')
sprintf('%s saved in %s', model_name, folder_models)

