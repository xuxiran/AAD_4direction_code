clear
clc
addpath(genpath('D:/bci/eeglab'));
rmpath(genpath('D:/bci/eeglab/plugins/Fieldtrip-lite20220630/external/signal/'));

Trial_num=40;
Trial_timelen=60;

%Down_Sample=64;

DataDir = '../rawdata/';
SaveDir = '../preprocess_data/';

sblist = dir(DataDir);
sblist(1:2) = [];
Subject_num = size(sblist,1);

for sb = 1:Subject_num
    %首先，记录地址，读取文件
    sbname = sblist(sb).name;
    eegbdfpath = [DataDir sbname filesep];

    savepath_env = [SaveDir filesep 'data_env' filesep sbname];
    savepath_space = [SaveDir filesep 'data_space' filesep sbname];
    
    if ~exist(savepath_env,'dir')
        mkdir(savepath_env)
    end

    if ~exist(savepath_space,'dir')
        mkdir(savepath_space)
    end
    
     EEG = pop_importNeuracle({'data.bdf','evt.bdf'}, eegbdfpath)
        
        
        EEG = eeg_checkset( EEG );

 

    
    trial_lag=0;

    % 这一块是trigger处理不用管
    k = [];
        for i = 1:length(EEG.event)-1;
            
            if EEG.event(i).type==EEG.event(i+1).type;

                if not(isempty(k))
                    if i-k(end)==1
                        k(end)=[];
                    end
                end
                k = [k,i];
            end
        end
        EEG.event = EEG.event(k);
    
   % 切割后进行基线校准、带通、降采样
   % 生成数据 
   EEG_64 = EEG;
   for eegcnt=1:40
        %脑电设备记录的是下降沿，也就是实验开始3s后的trigger。
        [EEG_trial_cap,indices] = pop_epoch( EEG_64, {  EEG.event(eegcnt).type  }, [0  Trial_timelen], 'newname', 'CNT file resampled epochs', 'epochinfo', 'yes','eventindices',eegcnt);
        EEG_trial_cap = eeg_checkset( EEG_trial_cap );

        
        EEG_env = EEG_trial_cap;
        EEG_space = EEG_trial_cap;
        
        % 包络的数据需要带通band-pass filtering, 2-8 Hz
        % 考虑到实时性，空间的数据使用IIR滤波器，在后续代码中再滤波
        [EEG_env,com,b] = pop_eegfiltnew(EEG_env,2,8,4096,0,[],0);
        
        % 用于包络重构的脑电数据基线校准
        % 考虑到实时性，空间的数据不使用基线校准
        EEG_env = pop_rmbase( EEG_env, []);

%             
        %分别降采样到 64以及128 Hz。
        EEG_env = pop_resample( EEG_env, 64);
        EEG_space = pop_resample( EEG_space, 128);

        save_envname=[savepath_env filesep  num2str((EEG.event(eegcnt).type)) '_cap'];
        save_spacename=[savepath_space filesep  num2str((EEG.event(eegcnt).type)) '_cap'];
        
        save([save_envname '.mat'],'EEG_env');
        save([save_spacename '.mat'],'EEG_space');
        
        disp(['preprocessing Done! You saved the ' save_envname ]);
        disp(['preprocessing Done! You saved the ' save_spacename ]);
        
    end
end
%Real_Num可以显示播放顺序