
clc; clear;
addpath(genpath('..\..\Acquisition\'))


%% Define data

% Data files to be loaded and to extract feature from
path = cell(1,1); save_path = cell(1,1);

% normal lubrication
path{1} = 'P:\Funded\REPRISE\Acquisitions\2017_04_18_60Row_300N\';
path{2} = 'P:\Funded\REPRISE\Acquisitions\2017_04_24_60Row_300N\';
path{3} = 'P:\Funded\REPRISE\Acquisitions\2017_05_23_60Row_300N\';
path{4} = 'P:\Funded\REPRISE\Acquisitions\2017_06_21_60Row_300N\';
path{5} = 'P:\Funded\REPRISE\Acquisitions\2017_07_31_60Row_300N_pre_anomaly\';


% % ------------------------   TWO CURRENTS COMPUTATIONS BEGIN
% % normal lubrication + no antirotazione
path{6} = 'P:\Funded\Reprise\Acquisitions\2017_09_11_60Row_300N\';
path{7} = 'P:\Funded\Reprise\Acquisitions\2017_09_18_60Row_300N\';

% poor lubrication
path{8} = 'P:\Funded\Reprise\Acquisitions\2017_09_21_60Row_300N_poor_lubricant_4\';
path{9} = 'P:\Funded\Reprise\Acquisitions\2017_09_25_60Row_300N_poor_lubricant\';

% % ------------------------   TWO CURRENTS COMPUTATIONS END

% no lubrication
path{10} = 'P:\Funded\Reprise\Acquisitions\2017_10_02_60Row_300N_no_lubricant_2\';
path{11} = 'P:\Funded\Reprise\Acquisitions\2017_10_02_60Row_300N_no_lubricant_3\';
path{12} = 'P:\Funded\Reprise\Acquisitions\2017_10_03_60Row_300N_no_lubricant_4\';
path{13} = 'P:\Funded\Reprise\Acquisitions\2017_10_04_60Row_300N_no_lubricant_5\';
path{14} = 'P:\Funded\Reprise\Acquisitions\2017_10_09_60Row_300N_no_lubricant\';
path{15} = 'P:\Funded\Reprise\Acquisitions\2017_10_11_60Row_300N_no_lubricant\';
path{16} = 'P:\Funded\Reprise\Acquisitions\2017_10_12_60Row_300N_no_lubricant\';


% Save on local disk in the same directory name
save_path{1} = path{1}(32:end);
save_path{2} = path{2}(32:end);
save_path{3} = path{3}(32:end);
save_path{4} = path{4}(32:end);
save_path{5} = path{5}(32:end);
save_path{6} = path{6}(32:end);
save_path{7} = path{7}(32:end);
save_path{8} = path{8}(32:end);
save_path{9} = path{9}(32:end);
save_path{10} = path{10}(32:end);
save_path{11} = path{11}(32:end);
save_path{12} = path{12}(32:end);
save_path{13} = path{13}(32:end);
save_path{14} = path{14}(32:end);
save_path{15} = path{15}(32:end);
save_path{16} = path{16}(32:end);



% Boolean vector which tells what tests have the phaseA sensor broken, and computes
% the features with only phaseB and phaseC currents
% two_currents = [zeros(1, 5) ones(1, 4) zeros(1, 7)];
two_currents = [ones(1, 4) zeros(1, 1)];

%% Properties

name = 'data'; % name of the data variable
offs = {'0mm'}; % offsets
amps = {'5mm', '10mm'}; % amplitudes
force = '300N'; % load
freq = {'0.1Hz','0.3Hz','0.5Hz','0.8Hz','0.9Hz','1Hz','1.5Hz','2Hz','2.5Hz','4Hz'}; % frequencies


%% Load and extract features


for tt = 1 : length(path) % loop over different time instants
    
    load([path{tt}, name,'.mat']); % load data
    X = cell(1,1); % initialize feature matrix
    
    fprintf('\n');
    fprintf('\n');
    fprintf('[Test = %s]', mat2str(tt));
    fprintf('\n');fprintf('\n');
    fprintf('[Two currents = %s]', num2str(two_currents(tt)));
    fprintf('\n');
    
    
    for oo = 1 : length(offs) % loop over different offsets
        
        off = offs{oo}; % actual offset
        fprintf('[Offset = %s]', off);
        fprintf('\n');
        
        for aa = 1 : length(amps) % loop over different amplitudes
            
            amp = amps{aa}; % actual amplitude
            fprintf('[Amplitude = %s]', amp);
            fprintf('\n');
            
            for ff = 1 : length(freq) % loop over different frequencies
                
                fprintf('[Freq = %s]', freq{ff});
                fprintf('\n');
                
                phase_A = data_table.get('phase_A', force ,off, amp, freq{ff});
                phase_B = data_table.get('phase_B', force, off, amp, freq{ff});
                phase_C = data_table.get('phase_C', force, off, amp, freq{ff});
                EMA_Position_reference_cDAQ = data_table.get('EMA_Position_reference_cDAQ', force, off, amp, freq{ff});
                EMA_position_reference_cRIO  = data_table.get('EMA_position_reference_cRIO', force, off, amp, freq{ff});
                EMA_LVDT_Position = data_table.get('EMA_LVDT_position', force, off, amp, freq{ff});
                relative_encoder_biss = data_table.get('relative_encoder_biss', force, off, amp, freq{ff});
                
                
                %% Resampling in order to synchronize data from cDAQ and cRIO
                f_cDAQ_ME = round(1/mean(diff(EMA_Position_reference_cDAQ.Time)));
                f_cDAQ_EL = round(1/mean(diff(phase_A.Time)));
                time_cRIO = EMA_position_reference_cRIO.Time;
                time_cRIO(time_cRIO == 0) = []; 
                f_cRIO = round(1/mean(diff(time_cRIO)));
                f_res = f_cDAQ_ME;
                
                % Resample cRIO
                EMA_position_reference_cRIO_res = resample(EMA_position_reference_cRIO.Data, f_res, f_cRIO);
                EMA_LVDT_Position_res = resample(EMA_LVDT_Position.Data, f_res, f_cRIO);
                
                % Resample cDAQ
                EMA_Position_reference_cDAQ_res = resample(EMA_Position_reference_cDAQ.Data, f_res, f_cDAQ_ME);
                
                % Make data same length
                t_res = 0:1/f_res:min(length(EMA_position_reference_cRIO_res), ...
                    length(EMA_Position_reference_cDAQ_res))/f_res - 1/f_res;
                EMA_position_reference_cRIO_res = EMA_position_reference_cRIO_res(1:length(t_res));
                EMA_LVDT_Position_res = EMA_LVDT_Position_res(1:length(t_res));
                
                
                % Filtered measure for zero crossing
                [b, a] = butter(5, str2double(freq{ff}(1:end-2))/100);
                EMA_LVDT_Position_res = filtfilt(b, a, EMA_LVDT_Position_res);
                EMA_LVDT_Position_res(EMA_position_reference_cRIO_res == 0) = 0; % where ref = 0, even misura = 0
                
                % Compute correlation in order to synchronize cRIO and cDAQ
                % measured data
                [b, a] = butter(5, 0.9);
                EMA_Position_reference_cDAQ_filt = filtfilt(b, a, EMA_Position_reference_cDAQ_res)';
                start_corr = find(t_res>15, 1);
                stop_corr = find(t_res>30, 1);
                ts1 = EMA_position_reference_cRIO_res(start_corr:stop_corr);
                ts2 = EMA_Position_reference_cDAQ_filt(start_corr:stop_corr);
                [corr, lag] = xcorr(ts1,ts2,'coeff');
                corr = corr/max(corr); [~, icor] = max(corr);
                shift = lag(icor); % found lag between cRIO and cDAQ
                
                % Shift the signals to align them
                if (shift>0)
                    EMA_position_reference_cRIO_res = EMA_position_reference_cRIO_res(shift+1:end);
                    EMA_LVDT_Position_res = EMA_LVDT_Position_res(shift+1:end);
                    EMA_Position_reference_cDAQ_res = EMA_Position_reference_cDAQ_res(1:end-shift);
                    t_res = t_res(shift+1:end);
                    t_res = t_res - t_res(1);
                else
                    shift = abs(shift);
                    EMA_position_reference_cRIO_res(shift+1:end) = EMA_position_reference_cRIO_res(1:end-shift);
                    EMA_position_reference_cRIO_res(1:shift) = zeros(1,shift);
                    EMA_LVDT_Position_res(shift+1:end) = EMA_LVDT_Position_res(1:end-shift);
                    EMA_LVDT_Position_res(1:shift) = zeros(1,shift);
                end
                
                % to manage the tests were the load cell stops after 8 minutes
                if(strcmp(freq{ff}, '0.1Hz') && max(phase_A.Time)>250) 
                    stop_el = find(phase_A.Time>250, 1);
                    phase_A = timeseries(phase_A.Data(1:stop_el), phase_A.Time(1:stop_el));
                    phase_B = timeseries(phase_B.Data(1:stop_el), phase_A.Time(1:stop_el));
                    phase_C = timeseries(phase_C.Data(1:stop_el), phase_A.Time(1:stop_el));
                    stop_vel = find(t_res>250, 1);
                    EMA_LVDT_Position_res = EMA_LVDT_Position_res(1:stop_vel);
                    EMA_position_reference_cRIO_res = EMA_position_reference_cRIO_res(1:stop_vel);
                    EMA_Position_reference_cDAQ_res = EMA_Position_reference_cDAQ_res(1:stop_vel);
                    t_res = t_res(1:stop_vel);
                end
                
                %% Zero crossing
                zci = @(v) find(v(:).*circshift(v(:), [-1 0]) <= 0);
                zx = zci(EMA_LVDT_Position_res)';
                zx = zx(1:end-1); % remove final zero crosses
                t_zero = find(EMA_LVDT_Position_res == 0);
                zx = setdiff(zx, t_zero); % remove zero cross where the methor is not started
                zx = zx(1:2:end); % takes the periods of the sinusoid
                
                ss = size(EMA_Position_reference_cDAQ_res);
                
                % Figure to see if the synchronization is ok
                %         figure
                %         plot(phase_A, 'b', 'linewidth', 1); hold on;
                %         plot(t_res, EMA_Position_reference_cDAQ_res * 5, 'k--', 'linewidth', 2);
                %         plot(t_res, EMA_position_reference_cRIO_res, 'r--', 'linewidth', 2);
                %         plot(t_res, EMA_LVDT_Position_res, 'g', 'linewidth', 2);
                %         plot(t_res(zx), EMA_LVDT_Position_res(zx), 'kp', 'markersize',10, 'linewidth',2)
                %         legend('Current Phase A','Position reference cDAQ','Position reference cRIO','Position Measure','Zeros');
                %         xlim([8.6,22.6])
                
                
                %% FEATURE COMPUTATIONS
                num_features = 2; % number of computed features
                features_A = zeros(num_features, length(zx)-1); % initilize vectors
                features_B = zeros(num_features, length(zx)-1);
                features_C = zeros(num_features, length(zx)-1);
                features = zeros(num_features, length(zx)-1);
                
                for i=1:length(zx)-1
                    t_feat_1 = find(phase_A.Time>t_res(zx(i)), 1); % index of zero crossing
                    
                    %% CREST FACTOR
                    features_A(1,i) = peak2rms(phase_A.Data(t_feat_1:t_feat_2));
                    features_B(1,i) = peak2rms(phase_B.Data(t_feat_1:t_feat_2));
                    features_C(1,i) = peak2rms(phase_C.Data(t_feat_1:t_feat_2));
                    
                    if two_currents(tt) == 1
                        features(1,i) = (features_B(1,i) + features_C(1,i))/2;
                    else
                        features(1,i) = (features_A(1,i) + features_B(1,i) + features_C(1,i))/3;
                    end
                    
                    
                    %% RMS
                    features_A(2,i) = rms(phase_A.Data(t_feat_1:t_feat_2));
                    features_B(2,i) = rms(phase_B.Data(t_feat_1:t_feat_2));
                    features_C(2,i) = rms(phase_C.Data(t_feat_1:t_feat_2));
                    
                    if two_currents(tt) == 1
                        features(2,i) = (features_B(2,i) + features_C(2,i) )/2;
                    else
                        features(2,i) = (features_A(2,i) + features_B(2,i) + features_C(2,i))/3;
                    end
                    
                    
                end
                
                X{ff} = features;
            end
            
            % Vector of labels, to do the boxplots
            g = [repmat(freq(1),1,size(X{1}(1,:),2))  repmat(freq(2),1,size(X{2}(1,:),2))...
                repmat(freq(3),1,size(X{3}(1,:),2))  repmat(freq(4),1,size(X{4}(1,:),2))...
                repmat(freq(5),1,size(X{5}(1,:),2))  repmat(freq(6),1,size(X{6}(1,:),2))...
                repmat(freq(7),1,size(X{7}(1,:),2))  repmat(freq(8),1,size(X{8}(1,:),2))...
                repmat(freq(9),1,size(X{9}(1,:),2)) repmat(freq(10),1,size(X{10}(1,:),2))];
            
            % Vector of CREST FACTORS
            C = [X{1}(1,:) X{2}(1,:) X{3}(1,:) X{4}(1,:) X{5}(1,:) X{6}(1,:)...
                X{7}(1,:) X{8}(1,:) X{9}(1,:) X{10}(1,:)];
            
            % Vector of RMS values
            R = [X{1}(2,:) X{2}(2,:) X{3}(2,:) X{4}(2,:) X{5}(2,:) X{6}(2,:)...
                X{7}(2,:) X{8}(2,:) X{9}(2,:) X{10}(2,:)];
                 
            % check if folder exists, otherwise create and then save
            if ( exist(save_path{tt}, 'dir') == 0 )
                mkdir(save_path{tt})
            end
            
            save([save_path{tt}, 'current_features','_off_',off,'_amp_',amp,'.mat'], 'C', 'R', 'X', 'amp', 'g', 'off');
        end
        
    end
end