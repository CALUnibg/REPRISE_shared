clc; clear;
addpath(genpath('..\..\Acquisition\'))
addpath(genpath('_utils\'))

fprintf('Loading data...');

%% Define data

% Data files to be loaded and to extract feature from
path = cell(1,1); 

% normal lubrication
% path{1} = '..\..\Phase_current\2017_04_18_60Row_300N\';
% path{2} = '..\..\Phase_current\2017_04_24_60Row_300N\';
% path{3} = '..\..\Phase_current\2017_05_23_60Row_300N\';
% path{4} = '..\..\Phase_current\2017_06_21_60Row_300N\';
% path{5} = '..\..\Phase_current\2017_07_31_60Row_300N_pre_anomaly\';

% normal lubrication + no antirotazione
path{1} = '..\..\Phase_current\2017_09_11_60Row_300N\';
path{2} = '..\..\Phase_current\2017_09_18_60Row_300N\';

% poor lubrication
path{3} = '..\..\Phase_current\2017_09_21_60Row_300N_poor_lubricant_4\';
path{4} = '..\..\Phase_current\2017_09_25_60Row_300N_poor_lubricant\';

% no lubrication
path{5} = '..\..\Phase_current\2017_10_02_60Row_300N_no_lubricant_2\';
path{6} = '..\..\Phase_current\2017_10_02_60Row_300N_no_lubricant_3\';
path{7} = '..\..\Phase_current\2017_10_03_60Row_300N_no_lubricant_4\';
path{8} = '..\..\Phase_current\2017_10_04_60Row_300N_no_lubricant_5\';
path{9} = '..\..\Phase_current\2017_10_09_60Row_300N_no_lubricant\';
path{10} = '..\..\Phase_current\2017_10_11_60Row_300N_no_lubricant\';
path{11} = '..\..\Phase_current\2017_10_12_60Row_300N_no_lubricant\';


%% Properties

offs = {'0mm'}; % offsets
amps = {'5mm', '10mm'}; % amplitudes
freq = {'0.1Hz','0.3Hz','0.5Hz','0.8Hz','0.9Hz','1Hz','1.5Hz','2Hz','2.5Hz','4Hz'};


used_offset = offs{1};
used_amp = amps{2};
used_freq = 6;
used_load = '300N';
ts = 1/1;

to_use = 95;

%% Load computed features

n_test = length(path);
features = cell(n_test, 1);

features_cum = nan(2,0);
sections = [];

for tt = 1 : 1 : n_test % loop over different time instants

    name = ['current_features_off_', used_offset,'_amp_', used_amp];
    load( [path{tt}, name,'.mat'], 'X' ); % load data
    
    features{tt} = X{used_freq}(:,1:to_use);

    features_cum = [ features_cum features{tt} ]; %#ok<AGROW>
    sections = [ sections length(features{tt}) ]; %#ok<AGROW>
    
end

used_freq = freq{used_freq};

sections = cumsum(sections);

time = ts*(0:size(features_cum,2)-1);

clear tt X to_use offs path amps freq name

fprintf('Done\n');