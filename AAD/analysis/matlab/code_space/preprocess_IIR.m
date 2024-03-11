
format long
% add your eeglab address,or you can add the path to dir
% addpath(genpath('D:\eeglab_current\eeglab2022.0'));
% produce 2*2*2=8 data
data_types = {'1D','2D'};


trnum = 40;

dataset = 'AAD_4_direction';

data1D_name = [dataset '_1D.mat'];
data2D_name = [dataset '_2D.mat'];



rawdir=['../../../preprocess_data/data_space'];
sblist = dir(rawdir);
sblist(1:2) = [];
sbnum = size(sblist,1);

fs = 128; % sampling rate
paralen = 60*fs;
chnum = 64;

EEG = zeros(sbnum,trnum,paralen,chnum);
ENV = zeros(sbnum,trnum,paralen,1);

Wn = [14 31]/(fs/2);
order = 8;
[b,a] = butter(order,Wn,'bandpass');


%% 

for sb = 1:sbnum
    sbname = sblist(sb).name;
    sbdir = [rawdir filesep sbname];
    % 采用了拉丁方+内部随机实验设计，但是这里的1-40对应试次标签
    % 每个被试的实验顺序都不同，但是1-40对应的音频一定是一一对应的
    load(['./sb_dir/1.mat']);
    sb_direction = dire;
    for tr = 1:trnum
        tr_direction = sb_direction(tr);
        disp(['preprocess_data      subject:' num2str(sb) '   trial:' num2str(tr)]);
        load([sbdir filesep num2str(tr) '_cap.mat']);

        tmp = EEG_space.data;
%         tmp = tmp';

        eegtrain = tmp';
        
%         ch_remove = [17 19 60 62 64];
%         eegtrain(ch_remove,:) = [];

%         eegtrain_new = zeros(size(eegtrain));
%         % We use 8-order IIR filter this time, and all the later result is
%         % same
        for ch = 1:64
            x = eegtrain(ch,:);
            y = filter(b,a,x);
            eegtrain_new(ch,:) = y;
        end
%         eegtrain = eegtrain_new';
%         EEG_trial = pop_importdata('dataformat','array','nbchan',0,'data','eegtrain_new','srate',fs,'pnts',0,'xmin',0);

%         [EEG_trial,com,b] = pop_eegfiltnew(EEG_trial, 14,31,512,0,[],0);

        % verify the filter
        % [Pxx, F] = spectopo(EEG_trial.data, 0, 128, 'freqrange', [] );
%         eegtrain = EEG_trial.data';
%         eegtrain = eegtrain';
        % mean and std
        % 1e-12: avoid dividing zero
        eegtrain = (eegtrain-mean(eegtrain,2))./(std(eegtrain,0,2)+1e-12);
        
        % give label
        labeltrain = ones(paralen,1)*(tr_direction-1);
        
        EEG(sb,tr,:,:) = eegtrain;
        ENV(sb,tr,:,:) = labeltrain;
    end

end

save(data1D_name,'EEG','ENV');
save(['../../python/' data1D_name],'EEG','ENV');


% expand 1d to 2d

load([data1D_name]);
eeglen = size(ENV,2);
EEG_2D = zeros(sbnum,trnum,paralen,9,9);


[~,map,~] = xlsread(['EEG_2D.xlsx']); % the channel position
load('EEGMAP.mat') % the channel order
axis = zeros(chnum,2);
for cha = 1:chnum-5
    for w = 1:9
        for h = 1:9
            if strcmp(EEGMAP{cha},map{w,h})==1
                axis(cha,1) = w;
                axis(cha,2) = h;
            end
        end
    end
end

for cha = 1:chnum
    if axis(cha,1)==0
        continue
    end
    EEG_2D(:,:,:,axis(cha,1),axis(cha,2)) = EEG(:,:,:,cha);
end
EEG = EEG_2D;
save([data2D_name],'EEG','ENV');
save(['../../python/' data2D_name],'EEG','ENV');
