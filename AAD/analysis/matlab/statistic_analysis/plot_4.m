clear
CNN_baseline = [43.33
64.63
48.71
55.04
65.63
68.79
61.96
70
57.5
50.46
70.38
88.38
77
45.63
62.17
60.38
];


CNN_3D = [60.13
84.58
79.88
85.58
83.21
94.88
79.79
90.88
88.92
73.83
94.92
93.5
86.46
81.88
87.17
91.21
];

DenseNet_37_3D = [60.5
99.38
88.42
86.38
87.04
97.75
93.33
91.25
91.71
63.92
97.13
95.08
87.83
93.71
91.88
93.67
];

DenseNet_37_I3D = [95.67 
98.83 
92.79 
91.92 
90.63 
97.96 
95.29 
95.54 
90.63 
92.17 
99.83 
96.04 
92.67 
92.50 
98.17 
94.50 
];


[h1, p1, ci1, stats1] = ttest(CNN_3D,CNN_baseline);
[h2, p2, ci2, stats2] = ttest(DenseNet_37_3D,CNN_3D);
[h3, p3, ci3, stats3] = ttest(DenseNet_37_I3D,DenseNet_37_3D);

data = [CNN_baseline CNN_3D DenseNet_37_3D DenseNet_37_I3D];
mean_data = mean(data, 1);

% 绘制每个被试的表现
set(groot, 'defaultAxesFontName','Times New Roman');
set(groot, 'defaultTextFontName','Times New Roman');
set(groot, 'defaultAxesFontSize', 14);
set(groot, 'defaultTextFontSize', 14);

figure
xlim([0.5, 4.5])
ylim([40, 104])
set(gca, 'FontWeight', 'bold');
hold on
box on;
load("col.mat")
% 绘制每个被试的表现并设置线的透明度为0.6和虚线样式
for i = 1:size(data, 1)
    line_color = col(:,i)';
    plot(data(i, :), 'Color', line_color, 'LineStyle', '--', 'LineWidth', 1.5, 'Marker', 'o', 'MarkerSize', 3, 'MarkerFaceColor', line_color, 'Color', [line_color,0.6])
end

% 绘制每种条件下的均值
plot(mean_data, '-o', 'LineWidth', 1.8, 'MarkerSize', 6, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'Color', 'k')

% 绘制标准误差
sem_data = std(data)/sqrt(size(data,1));
errorbar(mean_data, sem_data, 'LineStyle', 'none', 'LineWidth', 1.5, 'Color', 'k')

sd_data = std(data);


% 设置横轴标签和标题
set(gca, 'XTick', 1:4)
set(gca, 'XTickLabel', {'CNN-baseline','CNN-3D', 'DenseNet-3D', 'DenseNet-3D'})
xlabel('Model')
ylabel('Decoding accuracy(%)')
title('')

