%% plot bee height and bee angle
% Polina Proutskova March 2020
clearvars
%% Set script parameters
folder_root = '/Volumes/Bees_Drive/Radar_data/'; 
folder_date = '190513'; % Experiment date
exp_num = 23;
folder_expmnt = ['E',int2str(exp_num)]; % Experiment number
status_expmnt = 'Static'; % Static or rotating
file_exp_data = '/proc_data_v5_2.mat'; % filename where processed experiment data was saved

%% load bee angles and bee heights
[samples, angles, heights] = import_spreadsheet(folder_root, exp_num);

%% Load experiment data
folder_base = [folder_root,folder_date,' ',folder_expmnt,'/'];
path = [folder_base,'proc_data_',folder_date,'_',folder_expmnt, file_exp_data];
sprintf('loading data for experiment %d from %s', exp_num, path)
cd(folder_base)
load(path)

%% make sure dimensions of angles and peak_energy match
channels = 1:5;
pe = peak_energy;
pe_norm = peak_energy_norm;

if length(angles)~=length(pe_norm)
    pe = pe(1:end-1,:);
    pe_norm = pe_norm(1:end-1,:);
end
if length(angles)~=length(pe_norm)
    %if there is still a mismatch something is wrong
    ME = MException('PP:dimensions', ...
        'dimensions do not match: angles %d != peak_energy %d',length(angles),length(peak_energy_norm));
    throw(ME)
end

%% plotting signal strength: channel number vs sample number
fig = figure
s2d = surf(peak_energy) ;
view([0 0 1])
shading interp
ylabel('Sample number')
xlabel('Channel number')
ylim([1 length(nSample)])
set(gca,'xtick',[1:5])
t2d = title('Peak energy at different channels for each sample');
set(gcf,'color','w')
pause(5)

%% order angles ascending and everything else accordingly
[angles,idx] = sort(angles);
heights = heights(idx);
samples = samples(idx);
pe = pe(idx, :);
pe_norm = pe_norm(idx, :);

%% plotting signal strength: channel number vs bee angle
fig = figure
s2d = surf(channels, angles, pe) ;
view([0 0 1])
%shading interp
ylabel('Bee angle')
xlabel('Channel number')
ylim([angles(1) angles(end)])
set(gca,'xtick',[1:5])
t2d = title('peak energy at different bee angles for each channel');
set(gcf,'color','w')
pause(5)


%% plotting signal strength: channel number vs bee height
fig = figure
s2d = surf(channels, heights, pe) ;
view([0 0 1])
%shading interp
ylabel('Bee elevation')
xlabel('Channel number')
ylim([heights(1) heights(end)])
set(gca,'xtick',[1:5])
t2d = title('peak energy at different bee heights for each channel');
set(gcf,'color','w')
pause(5)


%% normalised signal: channels vs bee angle
fig = figure
s2d = surf(channels, angles, pe_norm) ;
view([0 0 1])
%shading interp
ylabel('Bee angle')
xlabel('Channel number')
ylim([angles(1) angles(end)])
set(gca,'xtick',[1:5])
t2d = title('Normalised peak energy at different bee angles for each channel');
set(gcf,'color','w')
pause(5)
