%% use a lookup model to fit channel measurements and determine the bee angle for rotating experiments
%Polina Proutskova, Feb-Mar 2020
clearvars

%% set script parameters
exp_num = 23;
lookup_model_exp = 22; % which lookup model to load
folder_local = '/Users/polina/RESEARCH/BeesRadars/Bees program/';
folder_root = '/Volumes/Bees_Drive/Radar_data/'; 
folder_date = '190515'; % Experiment date
folder_expmnt = ['E',int2str(exp_num)]; % Experiment number
filename_exp_data = 'proc_data_v8_>38.mat';
angles_threshold = [-6, 6]; % only use test data with angles within this interval

%% load experimental data
if isfile([folder_local, 'data/peak_energy_norm_exp',num2str(exp_num),'.mat'])
    sprintf('loading peak energy from experiment %d', exp_num)
    % load normalised peak energy data from local
    load([folder_local, 'data/peak_energy_norm_exp',num2str(exp_num),'.mat'], 'peak_energy_norm')
else
    sprintf('no file exists to load peak energy for experiment %d', exp_num)
    sprintf('loading all data for experiment %d ...', exp_num)
    % load all experimental data 
    fffolder_local = folder_local;
    folder_base = [folder_root,folder_date,' ',folder_expmnt,'/'];
    cd(folder_base)
    load([folder_base,'proc_data_',folder_date,'_',folder_expmnt,'/',filename_exp_data])
    folder_local = fffolder_local;
    cd(folder_local)
    sprintf('done.')
end

%% load lookup model
sprintf('loading lookup model from experiment %d', lookup_model_exp)
load([folder_local, 'models/lookup_model_',num2str(lookup_model_exp),'.mat'])
lm_angles = lookup_model{1};
lm_pe_norm = lookup_model{2};

%%  import spreadsheet data
[samples, angles, heights] = import_spreadsheet(folder_root, exp_num);

%% limit angles and test data to the limit
angles_lim = angles(angles<angles_threshold(2) & angles > angles_threshold(1));
samples_lim = samples(angles<angles_threshold(2) & angles > angles_threshold(1));
pe_norm_lim = peak_energy_norm(angles<angles_threshold(2) & angles > angles_threshold(1), :);

%% test with test data
channels = 1:5;

fitted = zeros(size(angles_lim)); % will store the best fitting angles 
for sample = 1:length(samples_lim)
    % construct test data from the current experiment
    testz_norm = pe_norm_lim(sample,:)';
    % fit test data to the model
    comp = zeros(size(lm_pe_norm,1),1);
    for n=1:size(lm_pe_norm,1)
        diff = lm_pe_norm(n, :) - testz_norm';
        comp(n) = sum(diff.^2);
    end
    [temp, ind] = min(comp);
    fit_angle = lm_angles(ind)
    fitted(sample) = fit_angle;
end

%% plot
figure('name', ['fit_exp', num2str(exp_num), '_lookup_model_', num2str(lookup_model_exp)])
plot(samples_lim, angles_lim, samples_lim, fitted, '--')
ylabel('angle')
xlabel('sample')
ylim(angles_threshold)
legend(['original angles from exp ',num2str(exp_num)],'fitted angles')
title(['Modelling data from exp ', num2str(exp_num), ' with the lookup model from exp ', num2str(lookup_model_exp)])
