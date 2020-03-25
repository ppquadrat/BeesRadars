%% Copyright NodeNs Medical Ltd. Author: Khalid Rajab, khalid@nodens.eu
%% Process bee data (Chittka group)
%% Processes a multiple files (multiple frames) and multiple samples (bee heights) for one experiment
%% For a stationary (non-rotating) experiment these should be the same.
%% For a rotating experiment there should be a peak at the bee location.

%% Update 08/01/2020: Faster processing; Peak finding
%% Update 08/01/2020: Output data_output{channel number, Sample number}(pulse number, peak_range)
%% Update 08/01/2020: Output data_mean{channel number, Sample number}(range index)
%% Update 15/01/2020: Accounts for noise

%% Select folder and files to explore
folder_root = '/Volumes/Bees_Drive/Radar_data/'; 
folder_date = '190513'; % Experiment date
exp_num = 21;
folder_expmnt = ['E',int2str(exp_num)]; % Experiment number
status_expmnt = 'Static'; % Static or rotating
folder_base = [folder_root,folder_date,' ',folder_expmnt,'/']
folder_local = '/Users/polina/WORK/BeesRadars/Bees program/';
nSample = []; % Experimental samples to analyse
ridx = [20:200]; % Range indices to analyse (this should be the signal location)

clear file folder

c = 3e8; % Speed of light
prf = 3000; % Pulse repetition frequency
Tpulse = 250e-9; % Pulse length
sampRate = 40e6; % ADC sampling rate
rangeRes = c/2/sampRate; % Range resolution
rangeRes = 3;
Nch = 5; % Number of channels
Nadc = 256; % Number of ADC samples
NDopp = 512; % Number of chirps (2^)

range = ridx*rangeRes;

%% determine the number of samples from the folder containing csv files
if isempty(nSample)
    x=dir([folder_base, '/csv']);
    for i = [1 : size(x,1)]
        name = x(i).name;
        if ~startsWith(name, ".")
            nSample = [nSample, str2num(name)];
        end
    end
end    


%% Load files
tic
for j = 1:length(nSample)
%for j = 44
    tic
    sprintf('j = %d', j)
    folder = [folder_base,'csv','/',num2str(nSample(j),'%03d'),'/'];
    k = 0;
    file = strcat(status_expmnt,'_20',folder_date,'_',num2str(nSample(j),'%03d'),'.',num2str(k),'.csv');
    chk = exist([folder file]);
    contents = dir(folder);

    for i = 1:5
        min_l(i) = 0;
        data{i,j} = zeros(100000,length(ridx));
    end
    while chk == 2
        tic
        raw_data = readmatrix([folder file]); % Read data
        j0(1:Nch) = 1; % Initialise pulse numbers
        tr(k+1) = toc;
        
        tic
        % Next bit assigns each row to the relevant channel
        for i = 1:5 % Sort per channel
            temp = raw_data(raw_data(:,5)==(i-1) , 5+ridx);
            offset = mean(temp(:,100:end),2); % mean of the tail
            temp=temp-offset;

            
            if k == 0
                data{i,j} = temp; % data at each channel (i) and sample (j)
            else
                %data{i,j} = [data{i,j}; raw_data(raw_data(:,5)==(i-1) , 5+ridx)];
                data{i,j}(min_l(i)+1:min_l(i)+size(temp,1),:) = temp; % Fill up data matrix with all pulses
            end
            min_l(i) = min_l(i) + size(temp,1);
        end
        t(k+1) = toc;
        
        
        k = k + 1;
        file = strcat(status_expmnt,'_20',folder_date,'_',num2str(nSample(j),'%03d'),'.',num2str(k),'.csv');
        chk = exist([folder file]);
    end
    
    % Make data lengths the same for each channel (cut off extra data)
    min_l = min(min_l);

    for i=1:5
        if size(data{i,j},1) > min_l
            data{i,j} = data{i,j}(1:min_l,:); % delete extra pulses
        end
        data_output{i,j}(min_l,1) = 0; % Create data_output matrix
        data_mean{i,j}(ridx) = 0; % Create data_mean vectors
    end
    

    % Search for peaks
    % Note: sum peaks first, to search for peaks across all channels
    temp = data{1,j};
    for i=2:5
        temp = temp + data{i,j};
    end
    
    tic
    for m = 1:min_l            
        [~, LOCS, WD] = findpeaks(temp(m,:), 'MinPeakProminence', 5*100, 'MinPeakHeight', 5*300, 'MinPeakWidth', 10);
        peak_range{m,j} = [];
        for n=1:length(LOCS)
            peaks(m,n) = LOCS(n);
            peak_range{m,j} = [peak_range{m,j}, ridx(1)-1 + LOCS(n) + (-3-ceil(WD/2):3+ceil(WD/2))];
        end
        if ~isempty(LOCS)
            for i = 1:5
                n = peak_range{m,j} - ridx(1)+1;
                data_output{i,j}(m,1:length(n)) = data{i,j}(m, n);
                data_mean{i,j}(n) = data_mean{i,j}(n) + data{i,j}(m, n);
            end
        end
    end
    for i = 1:5
        data_mean{i,j} = data_mean{i,j}./min_l;
        % Subtract out noise power
        if  ~isempty(peak_range{i,j})
            data_noise(i,j) = mean(data{i,j}(:, [1:peak_range{i,j}(1)-10, peak_range{i,j}(end)+10:end]), 'all');
            data_output{i,j} = data_output{i,j} - data_noise(i,j);
            data_output{i,j}(data_output{i,j}<0) = 0;
            data_mean{i,j} = data_mean{i,j} - data_noise(i,j);
            data_mean{i,j}(data_mean{i,j}<0) = 0;
        else
            data_noise(i,j) = 0;
        end

    end
    
    
    tp = toc;
    
    t2(j) = toc;
    sprintf('Processed: %d of %d files. %2.0f %% complete', j, nSample(end) - nSample(1) + 1, j/(nSample(end) - nSample(1) + 1)*100)
    sprintf('Approximately %3.1f minutes remaining', mean(t2)*(nSample(end)-nSample(1)+1 - j)/60)
end
toc

%% peak energy
peak_energy = zeros(length(nSample),5);
for i = 1:5
    for j = 1:length(nSample)
    %for j = 17
        peak_energy(j,i) = sum(data_mean{i,j});
        %peak_energy(i,j) = sum(data_mean(j,i,:));
    end
end

% normalise each row by the maximum value in this row
peak_energy_norm = zeros(size(peak_energy));
for n=1:size(peak_energy,1)
    peak_energy_norm(n,:) = peak_energy(n,:)/abs(max(peak_energy(n,:)));
end

%% Save processed data
% if exist([pwd,'\proc_data\',folder_date,'_',folder_expmnt]) == 0
%     mkdir([pwd,'\proc_data\',folder_date,'_',folder_expmnt])
% end
clear ans chk i j jc k raw_data temp temp2 data
save([folder_base,'proc_data_',folder_date,'_',folder_expmnt,'/proc_data_v5_4.mat'])



%% Read and reformat channel data
i = 1; % Channel number to plot (when only plotting one)

[RCx, RCy] = meshgrid(range, 1:5);
[RPx, RPy] = meshgrid(range, 1:size(data_target,1));

fig = figure
s1 = surf(RCx, RCy, squeeze(data_mean(1,:,:)));
view([0,0,1])
shading interp
xlim([range(1) range(end)])
ylim([1 5])
xlabel('Range (m)')
ylabel('Channel number')
caxis([0 3e5])
t1 = title(sprintf('Sample 1. Signal strength as dish angle is changed.'));
set(gca,'ytick',[1:5])
set(gcf,'color','w')
pause(3)
F(1) = getframe(fig);

for j = 2:(nSample(end)-nSample(1)+1)
    s1.ZData = squeeze(data_mean(j,:,:));
    t1.String = sprintf('Sample %d. Signal strength as dish angle is changed.', j);
    set(gcf,'color','w')
    F(j) = getframe(fig);
    pause(0.01)
end

fig = figure

subplot(221)
s2a = surf(squeeze(abs(data(i,:,:))));
view([0 0 1])
shading interp
xlim([1 Nadc])
ylim([1 NDopp])
xlabel('Range index')
ylabel('Pulse number')
t2a = title(sprintf('Step 1: Channel %d - Pre-processed data', i));

subplot(222)
s2b = surf(squeeze(abs(data_cube(i,:,:))));
view([0 0 1])
shading interp
xlim([1 Nadc])
ylim([1 NDopp])
xlabel('Range index')
ylabel('Doppler index (centre corresponds to 0 speed)')
t2b = title(sprintf('Step 2: - Channel %d: Range vs Speed (Doppler)', i));
caxis([0 2e3])

subplot(223)
s2c = surf(RPx, RPy, squeeze(abs(data_target(:,i,:))));
view([0 0 1])
shading interp
xlim([range(1) range(end)])
ylim([1 size(data_target,1)])
xlabel('Range (m)')
ylabel('Pulse number')
t2c = title(sprintf('Step 3 - Channel %d: Range vs Pulse', i));

subplot(224)
s2d = surf(squeeze(data_mean(:,:,5)));
view([0 0 1])
shading interp
ylabel('Sample number')
xlabel('Channel number')
ylim([1 nSample(end)-nSample(1)+1])
set(gca,'xtick',[1:5])

t2d = title('Step 4 - Signal strengths at different channels for each sample');

set(gcf,'color','w')
pause(5)

for i = 2:5
    s2a.ZData = squeeze(abs(data(i,:,:)));
    s2b.ZData = squeeze(abs(data_cube(i,:,:)));
    s2c.ZData = squeeze(abs(data_target(:,i,:)));
    s2d.ZData = squeeze(data_mean(:,:,5));
    t2a.String = sprintf('Step 1: Channel %d - Pre-processed data', i);
    t2b.String = sprintf('Step 2: - Channel %d: Range vs Speed (Doppler)', i);
    t2c.String = sprintf('Step 3 - Channel %d: Range vs Pulse', i);
    pause(5)
end