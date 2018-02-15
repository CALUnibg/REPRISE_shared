
clc; clear;
addpath(genpath('..\utils\LoadData\Load with tdms format\'))
addpath(genpath('..\utils\LoadData\TDMS Utilities\'))

%% Define data

% Data files to be loaded and to extract feature from
path = cell(1,1); save_path = cell(1,1);

% normal lubrication
path{1} = '2017_04_18_60Row_300N\';
path{2} = '2017_04_24_60Row_300N\';
path{3} = '2017_05_23_60Row_300N\';
path{4} = '2017_06_21_60Row_300N\';
path{5} = '2017_07_31_60Row_300N_pre_anomaly\';

% normal lubrication + no antirotation
path{6} = '2017_09_11_60Row_300N\';
path{7} = '2017_09_18_60Row_300N\';

% poor lubrication
path{8} = '2017_09_21_60Row_300N_poor_lubricant_4\';
path{9} = '2017_09_25_60Row_300N_poor_lubricant\';


% no lubrication
path{10} = '2017_10_02_60Row_300N_no_lubricant_2\';
path{11} = '2017_10_02_60Row_300N_no_lubricant_3\';
path{12} = '2017_10_03_60Row_300N_no_lubricant_4\';
path{13} = '2017_10_04_60Row_300N_no_lubricant_5\';
path{14} = '2017_10_09_60Row_300N_no_lubricant\';
path{15} = '2017_10_11_60Row_300N_no_lubricant\';
path{16} = '2017_10_12_60Row_300N_no_lubricant\';


%% Properties

offs = {'0mm'}; % offsets
amps = {'5mm', '10mm'}; % amplitudes
force = '300N'; % load
freq = {'0.1Hz','0.3Hz','0.5Hz','0.8Hz','0.9Hz','1Hz','1.5Hz','2Hz','2.5Hz','4Hz'};


%% Load computed features

tests_cell = cell(length(path), length(offs), length(amps));

for tt = 1 : length(path) % loop over different time instants
    
    fprintf('\n');
    fprintf('\n');
    fprintf('[Test = %s]', mat2str(tt));
    fprintf('\n');
    
    
    for oo = 1 : length(offs) % loop over different offsets
        
        off = offs{oo}; % actual offset
        fprintf('[Offset = %s]', off);
        fprintf('\n');
        
        for aa = 1 : length(amps) % loop over different amplitudes
            
            amp = amps{aa}; % actual amplitude
            fprintf('[Amplitude = %s]', amp);
            fprintf('\n');
            
            name = ['current_features_off_', off,'_amp_', amp];
            tests_cell{tt, oo, aa} = load( [path{tt}, name,'.mat'] ); % load data
            
        end
        
    end
end

%% GENERATE PLOTS

features_names = {'C', 'R'};
features_title = {'CREST FACTOR', 'RMS'};
ylabels = { 'Crest factor', 'RMS value [A]'};

for fn = 1 : length(features_names)
    
    fprintf('\n');
    fprintf('\n');
    fprintf('[Features = %s]', features_names{fn});
    fprintf('\n');
    
    for oo = 1 : length(offs) % loop over different offsets
        
        off = offs{oo}; % actual offset
        
        for aa = 1 : length(amps) % loop over different amplitudes
            
            figure
            data_to_plot = [];
            freq_box = [];
            time_box = [];
            
            for i = 1 : length(tests_cell)
                eval(['freq_box = [freq_box tests_cell{',num2str(i),', oo, aa}.g ];'])
                eval(['time_box = [time_box ', num2str(i),'*ones(size(tests_cell{',num2str(i),', oo, aa}.g)) ];'])
                eval(['data_to_plot = [data_to_plot tests_cell{',num2str(i),', oo, aa}.',features_names{fn},'];'])
            end
            
            boxplot(data_to_plot, {freq_box, time_box}, 'Whisker', 1.5,...
                'colors', repmat('bbbbbmmrrkkkkkkk', 1, size(freq_box,2)), 'Whisker', 1.5,...
                'factorgap', [8 1], 'labelverbosity', 'minor', 'FactorSeparator', 'auto');
            h=findobj(gca,'tag','Outliers'); delete(h); % delete outliers
            grid on;
            xlim([-10, 310])
            title([features_title{fn}, ' - Offset: ', cell2mat(offs(oo)),' - Amplitude: ', cell2mat(amps(aa)),' - Load: 300N']);
            set(findobj(gca,'type','line'),'linew',2)
            xlabel('Frequency [Hz]'); ylabel(ylabels{fn});
            
        end
    end
end