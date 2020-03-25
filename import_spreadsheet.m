function [samples, angles, heights] = import_spreadsheet(folder_root, exp_num)
%%  import spreadsheet data

exp_data = readtable([folder_root, '190703 Radar height calibration data.xlsx'],...
    'Sheet', 'Data', 'Range', 'A3:Q1000', 'ReadVariableNames',false);

xls_table = exp_data(exp_data.Var1==exp_num,[6,16, 17]);

% sample number
xls_table.Properties.VariableNames{'Var6'} = 'SampleNo';
samples = xls_table.SampleNo;

% signal heights
xls_table.Properties.VariableNames{'Var17'} = 'BeeHeight';
heights = xls_table.BeeHeight;

% angles
xls_table.Properties.VariableNames{'Var16'} = 'BeeAngle';
angles = xls_table.BeeAngle;

clear exp_data