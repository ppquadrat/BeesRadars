function [MLdata] = prepare_ML_data(folder_xls, folder_data, experiments, angles_threshold)
%% this function prepares experiment data for machine learning training or validation
% Polina Proutskova, March 2020

%% load experimental data and create table for machine learning
mldata = zeros(6); % will hold training data from all experiments
mldata_len = 0;
for idx = 1:length(experiments)
    exp_num = experiments{idx};
    pe_file = [folder_data, 'peak_energy_norm_exp',exp_num,'.mat'];
    if ~isfile(pe_file)
        sprintf('no file found: %s', pe_file)
    else
        sprintf('loading peak energy from experiment %s', exp_num)
        % load normalised peak energy data from local
        load(pe_file, 'peak_energy_norm')
        
        % import spreadsheet data
        [samples, angles, heights] = import_spreadsheet(folder_xls, str2num(exp_num));
        
        % make sure dimensions of angles and peak_energy match
        if length(angles)~=length(peak_energy_norm)           
            peak_energy_norm = peak_energy_norm(1:end-1,:);
        end        
        if length(angles)~=length(peak_energy_norm)
            %if there is still a mismatch something is wrong
            ME = MException('PP:dimensions', ...
                'dimensions do not match: angles %d != peak_energy %d',length(angles),length(peak_energy_norm));
            throw(ME)
        end
        
        % limit to angles angles_threshold
        sprintf('limit angles to: %d to %d', angles_threshold(1), angles_threshold(2))
        pe_norm_lim = peak_energy_norm(angles>angles_threshold(1) & angles<angles_threshold(2), :);
        angles_lim = angles(angles>angles_threshold(1) & angles<angles_threshold(2));
        
        
        % construct matrix with angles in first column and pe_norm data in
        % col 2-6
        temp = [angles_lim, pe_norm_lim];
        % append the matrix to the bottom of mldata matrix
        mldata(mldata_len+1:mldata_len+length(angles_lim),:) = temp;
        mldata_len = mldata_len + length(temp);
    end
end

% create table from mldata matrix with column names
MLdata = array2table(mldata);
MLdata.Properties.VariableNames = {'angles','ch1','ch2','ch3','ch4','ch5'};
