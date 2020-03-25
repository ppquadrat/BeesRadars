%% Copyright NodeNs Medical Ltd. Author: Khalid Rajab, khalid@nodens.eu
%% Process bee data (Chittka group)
%% Processes a multiple files (multiple frames) and multiple samples (bee heights) for one experiment
%% For a stationary (non-rotating) experiment these should be the same.
%% For a rotating experiment there should be a peak at the bee location.

%% Update 08/01/2020: Faster processing; Peak finding
%% Update 08/01/2020: Output data_output{channel number, Sample number}(pulse number, peak_range)
%% Update 08/01/2020: Output data_mean{channel number, Sample number}(range index)
%% Update 15/01/2020: Accounts for noise
%% Update 23/01/2020: rotating data:
%% i: channel, j: sample, k: peak number (as the radar keeps rotating around, it will detect multiple peaks), n: range index (keeps values only within the peak)
%% data_mean{channel,sample}(peak number,range index)
%% data_frame{i,j}(angle, frame, range index):the full 2D data at each frame. There are roughly 4000 measurements in each frame (full rotation), and I decimate (filter to reduce number of samples) down to around 400 for each revolution
%% peak_idx{j}(:,5): each row corresponds to a different peak. this has five columns:
%% 1) start pulse of a peak (a peak will show over multiple pulses)
%% 2) end pulse of a peak
%% 3) Frame number (each frame is a rotation)
%% 4) Range idx of peak
%% 5) Angle of peak (in degrees)
%% data{channel,sample}(pulse number, ADC sample)
%% Update 26/02/2020: 
%% peak_signal{sample}(peak_number, channel) - peak signal amplitudes


%% Select folder and files to explore
exp_num = 26; % experiment number
folder_expmnt = ['E',int2str(exp_num)];
folder_root = '/Volumes/Bees_Drive/Radar_data/';  
folder_date = '190515'; % Experiment date
status_expmnt = 'HR'; % Static or rotating
folder_base = [folder_root,folder_date,' ',folder_expmnt,'/']
folder_local = '/Users/polina/RESEARCH/BeesRadars/Bees program/';
nSample = []; % Experimental samples to analyse
ridx = [1:200]; % Range indices to analyse (this should be the signal location)

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
    base_csv_folder=dir([folder_base, '/csv']);
    for i = [1 : size(base_csv_folder,1)]
        sample_no = base_csv_folder(i).name;
        if ~startsWith(sample_no, ".") 
            sample_no_folder = dir([folder_base, '/csv/', sample_no]);
            % make sure there is data in the folder
            for i1 = [1:size(sample_no_folder, 1)]
                file = sample_no_folder(i1).name;
                if ~startsWith(file, ".") && sample_no_folder(i1).bytes > 0
                    nSample = [nSample, str2num(sample_no)];
                    break
                end
            end
        end
    end
end 

%clear base_csv_folder sample_no sample_no_folder file i i1

%% Load files
tic
warning('off', 'signal:findpeaks:largeMinPeakHeight')
for j = 1:length(nSample)
%for j = 1
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
        
        raw_data = readmatrix([folder file]); % Read data
        
        if ~isempty(raw_data)
            j0(1:Nch) = 1; % Initialise pulse numbers
            
            % Next bit assigns each row to the relevant channel
            for i = 1:5 % Sort per channel
                temp = raw_data(raw_data(:,5)==(i-1) , 5+ridx);
                offset = mean(temp(:,100:end),2);
                temp=temp-offset;
                if k == 0
                    data{i,j} = temp; % data at each channel (i) and sample (j)
                else
                    %data{i,j} = [data{i,j}; raw_data(raw_data(:,5)==(i-1) , 5+ridx)];
                    data{i,j}(min_l(i)+1:min_l(i)+size(temp,1),:) = temp; % Fill up data matrix with all pulses
                end
                min_l(i) = min_l(i) + size(temp,1);
            end
            
        else
            data{i,j} = [0];
        end
        
        
        k = k + 1;
        file = strcat(status_expmnt,'_20',folder_date,'_',num2str(nSample(j),'%03d'),'.',num2str(k),'.csv');
        chk = exist([folder file]);
    end
    
    % Make data lengths the same for each channel (cut off extra data)
    min_l = min(min_l); % Number of pulses

    for i=1:5
        if size(data{i,j},1) > min_l
            data{i,j} = data{i,j}(1:min_l,:); % delete extra pulses
        end
%         data_output{i,j}(min_l,1) = 0; % Create data_output matrix
        %data_mean{i,j}(ridx) = 0; % Create data_mean vectors
    end
    

    % Search for peaks
    % Note: sum peaks first, to search for peaks across all channels
    temp = data{1,j};
    for i=2:5
        temp = temp + data{i,j};
    end
    
    % Find peaks for each pulse at each channel
    % Note: should we subtract noise before doing the peak search?
    
    peaks0{j} = [];
    for m = 1:min_l  %pulse number
        peak_range{m,j} = [];
        if max(temp(m,:))>5*300    
            [~, LOCS, WD] = findpeaks(temp(m,:), 'MinPeakProminence', 5*50, 'MinPeakHeight', 5*300, 'MinPeakWidth', 10);
            for n=1:length(LOCS) %peak number
                peaks0{j}(m,n) = LOCS(n);
                peak_range{m,j} = [peak_range{m,j}, ridx(1)-1 + LOCS(n) + (-3-ceil(WD/2):3+ceil(WD/2))];
            end
            k = m; 
        end
    end
    min_l = k;
    
    if ~isempty(peaks0{j})
        
        peak_here{j} = 1:length(peaks0{j});
        %peak_here{j}(peaks0{j} == 0) = [];
        peak_here{j}(peaks0{j} == 0 | peaks0{j} < 38) = [];
        % the second condition filters out peaks from the barns retaining
        % peaks from the pole which are around 35
        
        if ~isempty(peak_here{j})
            for i = 1:5
                data_mean{i,j}(length(peak_here{j}),ridx) = 0; % Create data_mean vectors
            end
            k = 1; % Index of peak
            peak_idx{j}(k,1) = peak_here{j}(1);
            peak_idx{j}(k,2) = peak_here{j}(1);
            n = peak_range{peak_here{j}(1),j} - ridx(1)+1;
            % Mean power for each detection
            data_mean{i,j}(k,n) = data_mean{i,j}(k,n) + data{i,j}(peak_here{j}(1), n);
            
            for m = 2:length(peak_here{j})
                if peak_here{j}(m) - peak_idx{j}(k,2) < 4
                    peak_idx{j}(k,2) = peak_here{j}(m);
                    for i = 1:5
                        data_mean{i,j}(k,n) = data_mean{i,j}(k,n) + data{i,j}(peak_here{j}(m), n);
                    end
                else
                    k = k+1;
                    peak_idx{j}(k,1) = peak_here{j}(m);
                    peak_idx{j}(k,2) = peak_here{j}(m);
                    for i = 1:5
                        data_mean{i,j}(k,n) = data_mean{i,j}(k,n) + data{i,j}(peak_here{j}(m), n);
                    end
                end
            end
            
            for i = 1:5
                data_mean{i,j}(k+1:end,:) = [];
                for k = 1:k
                    data_mean{i,j}(k,:) = data_mean{i,j}(k,:)/(peak_idx{j}(k,2) - peak_idx{j}(k,1) + 1);
                end
            end
        else
            data_mean{i,j} = 0;
        end
        
    else
        data_mean{i,j} = 0;
    end
    
    % calculate peak signal strength
    for m = 1:length(peak_here{j}) %peak number
        for i = 1:5 % channel
            peak_signal{j}(m, i) = data{i,j}(peak_here{j}(m), peaks0{j}(peak_here{j}(m)));
        end
    end
    
%     % Normalise to background noise
%     % Search for background level (away from peak) at each pulse
%     
%     for i = 1:5
%         for m = 1:min_l
%             
%             % Find mean noise for each channel and pulse
%             if ~isempty(peak_range{m,j})
%                 data_noise(i,m) = mean(data{i,j}(m, [1:peak_range{m,j}(1)-10-ridx(1)+1, peak_range{m,j}(end)+10-ridx(1)+1:end]));
%             else
%                 data_noise(i,m) = mean(data{i,j}(m,:));
%             end            
%         end
%         %data_output{i,j} = data_output{i,j} - mean(data_noise(i,:));
%         %data_output{i,j}(data_output{i,j}<0) = 0;  
%         data_mean{i,j} = data_mean{i,j} - mean(data_noise(i,:));
%     end

    
    t2(j) = toc;
sprintf('Processed: %d of %d files. %2.0f %% complete', j, length(nSample), j/(length(nSample))*100)
sprintf('Approximately %3.1f minutes remaining', mean(t2)*(length(nSample) - j)/60)
end
toc

%% peak energy
% data_mean{channel,sample}(peak number,range index)
%peak_energy = zeros(length(nSample),5, size(data_mean{i,j},1));
for i = 1:5
    for j = 1:length(nSample)
        peak_energy(j,i)=sum(sum(data_mean{i,j}));    
    end
end

% normalise each row by the maximum value in this row
peak_energy_norm = zeros(size(peak_energy));
for j=1:size(peak_energy,1)
    peak_energy_norm(j,:) = peak_energy(j,:)/max(abs(peak_energy(j,:)));
end


%% Save processed data
% peak_energy_norm
if exists([folder_local, 'data/']) == 0
    mkdir([folder_local, 'data/'])
end
save([folder_local, 'data/peak_energy_norm', num2str(exp_num),'.mat', 'peak_energy_norm', '-v7'])

% all averaged data
% this produced more than 2GB data
% it only works if saving in the latest version of .mat files is enabled
% (version > 7). It results in loading and saving files take quite long, up
% to several minutes
if exist([folder_base,'proc_data_',folder_date,'_',folder_expmnt]) == 0
    mkdir([folder_base,'proc_data_',folder_date,'_',folder_expmnt])
end
clear ans chk i j jc k raw_data temp temp2 data
save([folder_base,'proc_data_',folder_date,'_',folder_expmnt,'/proc_data_v8_>38.mat'])
