%% construct a gaussian model from experiment data
%Polina Proutskova, Feb-Mar 2020

%% set experiment parameters
gmodel_exp = 26;
folder_local = '/Users/polina/RESEARCH/BeesRadars/Bees program/';
folder_root = '/Volumes/Bees_Drive/Radar_data/'; 
folder_date = '190513'; % Experiment date
folder_expmnt = ['E',int2str(gmodel_exp)]; 
filename_exp_data = 'proc_data_v5_2.mat';
status_expmnt = "HR"; % Static or rotating

%% load experimental data
if isfile([folder_local, 'data/peak_energy_norm_exp',num2str(gmodel_exp),'.mat'])
    sprintf('loading peak energy from experiment %d', gmodel_exp)
    % load normalised peak energy data from local
    load([folder_local, 'data/peak_energy_norm_exp',num2str(gmodel_exp),'.mat'], 'peak_energy_norm')
else
    sprintf('no file exists to load peak energy for experiment %d', gmodel_exp)
    sprintf('loading all data for experiment %d ...', gmodel_exp)
    % load all experimental data 
    fffolder_local = folder_local;
    folder_base = [folder_root,folder_date,' ',folder_expmnt,'/']
    cd(folder_base)
    load([folder_base,'proc_data_',folder_date,'_',folder_expmnt,'/',filename_exp_data])
    folder_local = fffolder_local;
    cd(folder_local)
    sprintf('done.')
end

%% import spreadsheet data
[samples, angles, heights] = import_spreadsheet(folder_root, gmodel_exp);

%% construct experiment data
channels = 1:5;

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
gm_angles = angles(angles<6 & angles > -6);
gm_pe_norm = peak_energy_norm(angles>-6 & angles<6, :);
% sort angles ascending and pe_norm accordingly
[gm_angles, sort_idx] = sort(gm_angles);
gm_pe_norm = gm_pe_norm(sort_idx, :);


%% fit experimental data to a gaussian function
if status_expmnt == "STATIC"
    fitresult = gmodel_fit(gmodel_exp, channels, gm_angles, gm_pe_norm);
else
    fitresult = gmodel_fit_rot(gmodel_exp, channels, gm_angles, gm_pe_norm);
end

%% construct model
equation = formula(fitresult);
coeff_names = coeffnames(fitresult);
coeff_values = coeffvalues(fitresult);
for n = 1:numcoeffs(fitresult)
    equation = strrep(equation,coeff_names{n},num2str(coeff_values(n)));
end
equation = strrep(equation,'y','a'); % 'a' will be treated as a dependent variable and will be estimated when the model is used

gmodel_ft = fittype(equation);
gmodel_opts = fitoptions('Method', 'NonlinearLeastSquares', 'Lower', -6, 'Upper', 6, 'Start', 0 );

%% save model
gmodel = {gmodel_ft, gmodel_opts};
save([folder_local, 'models/gauss_model_',num2str(gmodel_exp),'.mat'], 'gmodel', '-v7')

