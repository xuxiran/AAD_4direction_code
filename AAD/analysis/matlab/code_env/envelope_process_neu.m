clear;clc;

%sbnum = 16;


dim_tr =59;
% load('Envelope_all.mat');
load('./space_num.mat');
load('./space_envall.mat')
% space_env
att_rand = [1 1 1 1 1 1 1 1 1 1];%1是欢乐颂的包络，2是summer的
unatt_rand = [2 2 2 2 2 2 2 2 2 2];

Envelope_att = space_env(space_num(:,1),:);
% Envelope_unatt = peom_env(unatt_rand,:);

%计算250ms的解码器
if 1

    nowdir = cd;
    cd ..
    projectdir =  cd;
    DataDir = ['../../../preprocess_data/data_env/'];    

    cd (nowdir)    

    Lags = 0:32;
    dim = dim_tr*(length(Lags)+1);
    M = eye(dim,dim);

    sblist = dir(DataDir);
    %sblist(1:2) = [];
    sblist(1:2) = [];

    sbnum = size(sblist,1);
    decode_att = zeros(sbnum,40,dim);%2个被试，每个被试4*10条件
    decode_unatt = zeros(sbnum,40,dim);

    for sb = 1:sbnum
        sbname = sblist(sb).name;
        sbdir = [DataDir filesep sbname];

        for tr = 1:40 % 注意的试次；21-30&31-40
            

            disp(['  sb:' num2str(sb) '  tr:' num2str(tr)]);

            trdir = [sbdir filesep num2str(tr) '_cap.mat'];
            load(trdir);
            eeg = EEG_env.data(:,:);
            eeg(dim_tr+1:64,:) = [];
            eeg = eeg';
            eeg = zscore(eeg);
            
            env_att = Envelope_att(tr,:)';%%注意一下修改试次后这里也要修改
%             env_unatt = Envelope_unatt(tr-20,:)';%%注意一下修改试次后这里也要修改


            X = [ones(size(eeg)),lagGen(eeg,min(-Lags):max(-Lags))];

            XX = X'*X;
            XYatt = X'*env_att;
%             XYunatt = X'*env_unatt;
            %对注意音频的解码器
            d2_att = (XX+4096*M)\XYatt;
            %对非注意音频的解码器
            %d2_unatt = (XX+4096*M)\XYunatt;
            decode_att(sb,tr,:) = d2_att';%%注意一下修改试次后这里也要修改
            %decode_unatt(sb,tr-20,:) = d2_unatt';%%注意一下修改试次后这里也要修改
        end


    end
    save(['envelope_decoder_nue_05_16_59.mat'],'decode_att','decode_unatt');
end


%第二部分：试验解码结果（500ms）
if 1

    nowdir = cd;
    cd ..
    projectdir =  cd;
    DataDir = ['../../../preprocess_data/data_env/'];  

    cd (nowdir)
    

    Lags = 0:32;
    dim = dim_tr*(length(Lags)+1);
    M = eye(dim,dim);


    sblist = dir(DataDir);
    sblist(1:2) = [];

    res_raw =zeros(16,7);
    %两种解码器
    load('envelope_decoder_nue_05_16_59.mat');
    C_att_raw = zeros(sbnum,40);
    C_unatt_raw = zeros(sbnum,40);

    t = [60 30 20 10 5 2 1];
    for i= 1: length(t)
    ti = t(i);
    

    for sb = 1:sbnum
        sbname = sblist(sb).name;
        sbdir = [DataDir filesep sbname];

        for tr = 1:40
            disp(['  sb:' num2str(sb) '  tr:' num2str(tr)]);
            unattnum = space_num(tr,2:4);
            trdir = [sbdir filesep num2str(tr) '_cap.mat'];
            load(trdir);
            eeg = EEG_env.data(:,:);
            eeg(dim_tr+1:64,:) = [];
            eeg = eeg';
            eeg = zscore(eeg);

           
            env_att = Envelope_att(tr,:)';%%注意一下修改试次后这里也要修改
            env_unatt = space_env(unattnum,:)';%%注意一下修改试次后这里也要修改

            
            X = [ones(size(eeg)),lagGen(eeg,min(-Lags):max(-Lags))];

            decoder_raw = sum(squeeze(decode_att(sb,:,:)))' - squeeze(decode_att(sb,tr,:));
            pred_att_raw = X*decoder_raw;
            
           
                for t_n = 1:60/ti

                    C_att_raw(sb,tr,t_n) = corr(env_att(ti*64*(t_n-1)+1:ti*64*t_n,:),pred_att_raw(ti*64*(t_n-1)+1:ti*64*t_n,:));
                    C_unatt_raw(sb,tr,t_n) = max([corr(env_unatt(ti*64*(t_n-1)+1:ti*64*t_n,1),pred_att_raw(ti*64*(t_n-1)+1:ti*64*t_n,:)),corr(env_unatt(ti*64*(t_n-1)+1:ti*64*t_n,2),pred_att_raw(ti*64*(t_n-1)+1:ti*64*t_n,:)),corr(env_unatt(ti*64*(t_n-1)+1:ti*64*t_n,3),pred_att_raw(ti*64*(t_n-1)+1:ti*64*t_n,:))]);
                   
                
                end
            end


    end
     %检验最后结果
        de_raw = gt(C_att_raw,C_unatt_raw);
        
     res_raw(:,i) = mean(mean(de_raw,2),3);
     disp(i);
    end

    


end


%lagGen函数
function xLag = lagGen(x,lags)
xLag = zeros(size(x,1),size(x,2)*length(lags));

i = 1;
for j = 1:length(lags)
    if lags(j) < 0
        xLag(1:end+lags(j),i:i+size(x,2)-1) = x(-lags(j)+1:end,:);
    elseif lags(j) > 0
        xLag(lags(j)+1:end,i:i+size(x,2)-1) = x(1:end-lags(j),:);
    else
        xLag(:,i:i+size(x,2)-1) = x;
    end
    i = i+size(x,2);
end

end