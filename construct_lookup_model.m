%% construct a lookup model from experiment data
%Polina Proutskova, Feb-Mar 2020

%% set experiment parameters
lookup_model_exp = 26;
folder_local = '/Users/polina/RESEARCH/BeesRadars/Bees program/';
folder_root = '/Volumes/Bees_Drive/Radar_data/'; 
folder_date = '190513'; % Experiment date
folder_expmnt = ['E',int2str(lookup_model_exp)]; % Experiment number
filename_exp_data = 'proc_data_v5_2.mat';

%% load experimental data
if isfile([folder_local, 'data/peak_energy_norm_exp',num2str(lookup_model_exp),'.mat'])
    sprintf('loading peak energy from experiment %d', lookup_model_exp)
    % load normalised peak energy data from local
    load([folder_local, 'data/peak_energy_norm_exp',num2str(lookup_model_exp),'.mat'], 'peak_energy_norm')
else
    sprintf('no file exists to load peak energy for experiment %d', lookup_model_exp)
    sprintf('loading all data for experiment %d ...', lookup_model_exp)
    % load all experimental data 
    fffolder_local = folder_local;
    folder_base = [folder_root,folder_date,' ',folder_expmnt,'/']
    cd(folder_base)
    load([folder_base,'proc_data_',folder_date,'_',folder_expmnt,'/',filename_exp_data])
    folder_local = fffolder_local;
    cd(folder_local)
    sprintf('done.')
end

%%  import spreadsheet data
[samples, angles, heights] = import_spreadsheet(folder_root, lookup_model_exp);

%% construct experiment data

if length(angles)~=length(peak_energy_norm)
    %force dimensions to match
    peak_energy_norm = peak_energy_norm(1:end-1,:);
end

if length(angles)~=length(peak_energy_norm)
    %if there is still a mismatch something is wrong
    ME = MException('PP:dimensions', ...
        'dimensions do not match: angles %d != peak_energy %d',length(angles),length(peak_energy_norm));
    throw(ME)
end

% limit to angles between -6 and 6
lm_angles = angles(angles<6 & angles > -6);
lm_pe_norm = peak_energy_norm(angles>-6 & angles<6, :);
% sort angles ascending and pe_norm accordingly
[lm_angles, sort_idx] = sort(lm_angles);
lm_pe_norm = lm_pe_norm(sort_idx, :);

%% construct model
lookup_model = {lm_angles, lm_pe_norm};

%% save lookup model
save([folder_local, 'models/lookup_model_',num2str(lookup_model_exp),'.mat'], 'lookup_model', '-v7')