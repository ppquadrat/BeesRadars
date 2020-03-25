function load_exp_data(exp_num, folder_local, folder_root, folder_date, folder_expmnt, filename)
%% load experimental data
if isfile([folder_local, 'peak_energy_norm_exp',num2str(exp_num),'.mat'])
    sprintf('loading peak energy from experiment %d', exp_num)
    % load normalised peak energy data from local
    load([folder_local, 'data/peak_energy_norm_exp',num2str(exp_num),'.mat'], 'peak_energy_norm')
else
    sprintf('no file exists to load peak energy for experiment %d', exp_num)
    sprintf('loading all data for experiment %d ...', exp_num)
    % load all experimental data 
    fffolder_local = folder_local;
    folder_base = [folder_root,folder_date,' ',folder_expmnt,'/']
    cd(folder_base)
    load([folder_base,'proc_data_',folder_date,'_',folder_expmnt,'/',filename])
    folder_local = fffolder_local;
end
