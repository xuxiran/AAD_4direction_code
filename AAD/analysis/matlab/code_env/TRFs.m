%% TRF
clear
clc

EnvelopeDir = './';
load([EnvelopeDir 'space_envall.mat'],'space_env');
load([EnvelopeDir 'space_num.mat'],'space_num');
EEGDataDir = ['../../../preprocess_data\data_env/'];    
savepath = './PredictionData_-50_test/';
tauRange = [-50 450];
sblist = dir(EEGDataDir);
sblist(1:2) = [];

for i0=1:16
    disp(['---------Subject NO. ---------' num2str(i0)])
    subjectName = sblist(i0).name;
    subjectNameDir =[EEGDataDir filesep subjectName];
    DataSaveDir = [savepath subjectName];
    if exist(DataSaveDir,'dir')==0, mkdir(DataSaveDir); end
    
    % load EEG Data
    for EEGDataFileNo = 1:40
        EEGDataFileName = [subjectNameDir filesep num2str(EEGDataFileNo) '_cap.mat'];
        load(EEGDataFileName,'EEG_env');
        EEG = EEG_env;
        EEGdata = EEG.data; % channel by time
        fs1 = EEG.srate;
        EEGdata(60:64,:) = [];% delete EoG
        EEGdata_temp = mapminmax(double(EEGdata),-1,1);
        respSet{EEGDataFileNo} = EEGdata_temp';
        AudioIndex(EEGDataFileNo)  = EEGDataFileNo;
    end
    lambda_index = [1:2:20]';
    lambda = 2.^lambda_index;
    Envelope_att = space_env(space_num(:,1),:);
    Envelope_unatt = (space_env(space_num(:,2),:)+space_env(space_num(:,3),:)+space_env(space_num(:,4),:))/3;
    %Envelope_unatt = space_env(space_num(:,3),:);
    % choose corresponding Audio Envelopes

    Envelope_att = mapminmax(Envelope_att,-1,1);
    Envelope_unatt = mapminmax(Envelope_unatt,-1,1);
    
    % attended trf
    for i1=1:size(Envelope_att,1)
        stimSet{i1} = Envelope_att(i1,:)';
    end
    clear stimTrain stimTest respTrain respTest trfs con
    stimTrain = stimSet;
    respTrain = respSet;
    % train
    [r1,p1,MSE1,prediction,trfs,con] = mTRFcrossval(stimTrain,respTrain,fs1,1,tauRange(1),tauRange(2),lambda);
    save([DataSaveDir '/Variables_att.mat'],'trfs','r1','p1','MSE1','con')
    % unattended trf
    for i1=1:size(Envelope_att,1)
        stimSet{i1} = Envelope_unatt(i1,:)';
    end
    clear stimTrain stimTest respTrain respTest trfs con
    stimTrain = stimSet;
    respTrain = respSet;
    % train
    [r1,p1,MSE1,prediction,trfs,con] = mTRFcrossval(stimTrain,respTrain,fs1,1,tauRange(1),tauRange(2),lambda);
    save([DataSaveDir '/Variables_unatt.mat'],'trfs','r1','p1','MSE1','con');
end

%% Calculate best TRF
% calculate best trf and corresponding r value for Prediction
lambda_index = 4;% 2^7
map = 1;
fs1 = 64;
tmin = tauRange(1);
tmax = tauRange(2);
tmin = floor(tmin/1e3*fs1*map);
tmax = ceil(tmax/1e3*fs1*map);
t = (tmin:tmax)/fs1*1e3;

%figure

for i_cond = 1:1
    for i0=1:16
        subjectName = sblist(i0).name;
        subjectNameDir =[EEGDataDir filesep subjectName];
        DataSaveDir = [savepath subjectName];
        load([DataSaveDir '/Variables_att.mat']);
        best_trfs_att(:,:,i0) = squeeze(mean(trfs(:,lambda_index,:,:),1));
        best_cons_att(:,i0) = squeeze(mean(con(:,lambda_index,:),1));

        load([DataSaveDir '/Variables_unatt.mat']);
        best_trfs_unatt(:,:,i0) = squeeze(mean(trfs(:,lambda_index,:,:),1));
        best_cons_unatt(:,i0) = squeeze(mean(con(:,lambda_index,:),1));
        disp(['----Calculate Best TRFs---' num2str(i0)])

    end
    best_trf_att = mean(best_trfs_att,3);
    best_con_att = mean(best_cons_att,2);
    best_trf_unatt = mean(best_trfs_unatt,3);
    best_con_unatt = mean(best_cons_unatt,2);

    best_trfs = cat(3,best_trf_att,best_trf_unatt);
    best_cons = [best_con_att,best_con_unatt];
    
    for i0=1:16
        subjectName = sblist(i0).name;
        subjectNameDir =[EEGDataDir filesep subjectName];
        DataSaveDir = [savepath subjectName];
        save([DataSaveDir '/trf.mat'],'best_cons','best_trfs');
    end

end

%% Plot att_TRF and unatt_TRF for certain electrodes


TRFFileName = '/trf.mat';
subjectName = sblist(1).name;
subjectNameDir =[EEGDataDir filesep subjectName];
DataSaveDir = [savepath subjectName];
load([DataSaveDir TRFFileName]);

figure
electrodesName = {'FC5', 'FC6', 'FZ', 'POZ'};
electrodes = [18 26 32 38];
linestyle = {'-',':'};
for i1 = 1:4
    elec = electrodes(i1);
    h(i1) = subplot(2,2,i1);
    hold on
    plot(t(5:end),best_trfs(5:end,elec,1), 'linewidth', 1.5, 'linestyle',linestyle{1});
    plot(t(5:end),best_trfs(5:end,elec,2), 'linewidth', 1.5, 'linestyle',linestyle{2});
    axis([0 300 -5e-3 5e-3])
    set(gca,'FontWeight', 'bold','fontsize',23,'FontName','Times New Roman','ytick',[], 'linewidth', 1, 'xtick',[0:100:300]);
    text(130, 5.5e-3, electrodesName{i1}, 'fontsize',23,'FontName','Times New Roman','FontWeight', 'bold');
    xlabel('Time lag (ms)');
    box off    
end
lg = legend('Attend','Unattend','Location','eastoutside');
set(lg, 'Position', [0.87 0.45 0.1 0.1])
set(lg, 'FontWeight', 'bold','fontsize',20, 'orientation', 'vertical', 'box', 'off','FontName','Times New Roman')

%% topoplot 78, 156, 188, 250 ms

trf_att_A = best_trfs(:,:,1);
trf_unatt_A = best_trfs(:,:,2);

colormapRange = [-0.006 0.006];% new

figure
subplot(2,4,1)
topoplotEEG(trf_att_A(10,:),'eloc64.txt','electrodes','off','style','straight');
title('78 ms','FontWeight', 'bold','FontName','Times New Roman','FontSize',25);set(gca,'Clim',colormapRange);colorbar off;
subplot(2,4,2)
topoplotEEG(trf_att_A(15,:),'eloc64.txt','electrodes','off','style','straight');
title('156 ms','FontWeight', 'bold','FontName','Times New Roman','FontSize',25);set(gca,'Clim',colormapRange);colorbar off;
subplot(2,4,3)
topoplotEEG(trf_att_A(17,:),'eloc64.txt','electrodes','off','style','straight');
title('188 ms','FontWeight', 'bold','FontName','Times New Roman','FontSize',25);set(gca,'Clim',colormapRange);colorbar off;
subplot(2,4,4)
topoplotEEG(trf_att_A(21,:),'eloc64.txt','electrodes','off','style','straight');
title('250 ms','FontWeight', 'bold','FontName','Times New Roman','FontSize',25);set(gca,'Clim',colormapRange);colorbar off;
subplot(2,4,5)
topoplotEEG(trf_unatt_A(10,:),'eloc64.txt','electrodes','off','style','straight');
title('78 ms','FontWeight', 'bold','FontName','Times New Roman','FontSize',25);set(gca,'Clim',colormapRange);colorbar off;
subplot(2,4,6)
topoplotEEG(trf_unatt_A(15,:),'eloc64.txt','electrodes','off','style','straight');
title('156 ms','FontWeight', 'bold','FontName','Times New Roman','FontSize',25);set(gca,'Clim',colormapRange);colorbar off;
subplot(2,4,7)
topoplotEEG(trf_unatt_A(17,:),'eloc64.txt','electrodes','off','style','straight');
title('188 ms','FontWeight', 'bold','FontName','Times New Roman','FontSize',25);set(gca,'Clim',colormapRange);colorbar off;
subplot(2,4,8)
topoplotEEG(trf_unatt_A(21,:),'eloc64.txt','electrodes','off','style','straight');
title('250 ms','FontWeight', 'bold','FontName','Times New Roman','FontSize',25);set(gca,'Clim',colormapRange);colorbar off;
% Add a colorbar to the figure
c = colorbar;
c.Position = [0.92 0.46 0.015 0.2]; % Adjust these values as needed
set(gca, 'Clim', colormapRange);
c.Ticks = [colormapRange(1), 0, colormapRange(2)];
c.TickLabels = {'Min', '0','Max'};
% Optional: If you want to set the colorbar's limits explicitly
c.Limits = colormapRange;
c.FontSize = 14;
c.FontName = 'Times New Roman';
c.FontWeight = ['bold'];
title(c,'amp(a.u.)','FontWeight', 'bold','Fontname','Times New Roman','Fontsize',14);


annotation('textbox', [0.02, 0.67, 0.1, 0.15], 'String', 'Attended', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle','FontWeight', 'bold','FontName','Times New Roman','FontSize', 25);


annotation('textbox', [0.02, 0.18, 0.1, 0.15], 'String', 'Unattended', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle','FontWeight', 'bold','FontName','Times New Roman', 'FontSize', 25);
