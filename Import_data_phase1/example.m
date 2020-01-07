clc
clear

%% Load data 

load('data.mat');


data_table.getDataTypes
data_table.getForces
data_table.getOffsets
data_table.getAmplitudes
data_table.getfrequencies


%% Get data
% retrieve phase C current data
phase_C = data_table.get('phase_C', '300N', '0mm', '5mm', '0.5Hz');


%% Plot data
figure
plot(phase_C)