load_data; % scripts that loads the computed features

%% Change detection parameters

% parameters
alpha = 0.5; % hyperparameter of the method
fold = 5; % number of cross validation folds
sigma = []; % vector for specifying hyperparameters
lambda = []; % vector for specifying hyperparameters

autoCV = 1; % choose to perform or not cross validation

%% policy - always healthy

fprintf('Policy always healthy...');

score_AH = nan(n_test,1); % init score

for tt = 2 : 1 : n_test
    exp_1 = features{1}; % features from experiment 1
    exp_2 = features{tt}; % features from experiment tt
    
    % Compute score in both direction
    s1 = RelULSIF( exp_1, exp_2, [], [], alpha, fold, sigma, lambda, autoCV);
    s2 = RelULSIF( exp_2, exp_1, [], [], alpha, fold, sigma, lambda, autoCV);

    score_AH(tt) = s1 + s2; % sum the two scores to obtain the final one
    
    if score_AH(tt) <= 0 % set to zero negative results
        score_AH(tt) = 0;
    end
end
fprintf('Done!\n');

%% policy - always previous

fprintf('Policy always previous...');

score_AP = nan(n_test,1);

for tt = 2 : 1 : n_test
    exp_1 = features{tt};
    exp_2 = features{tt-1};
    
    s1 = RelULSIF( exp_1, exp_2, [], [], alpha, fold, sigma, lambda, autoCV);
    s2 = RelULSIF( exp_2, exp_1, [], [], alpha, fold, sigma, lambda, autoCV);
    
    score_AP(tt) = s1 + s2;
    
    if score_AP(tt) <= 0
        score_AP(tt) = 0;
    end
end

fprintf('Done!\n');

%% policy - always last change

fprintf('Policy always last change...');

score_LC = nan(n_test,1);
cum_LC = zeros(n_test,1);

thr = 0.81;
exp_to_compare = features{1};

for tt = 2 : 1 : n_test
    exp_2 = features{tt};
    
    s1 = RelULSIF( exp_to_compare, exp_2, [], [], alpha, fold, sigma, lambda, autoCV);
    s2 = RelULSIF( exp_2, exp_to_compare, [], [], alpha, fold, sigma, lambda, autoCV);

    score_LC(tt) = s1 + s2;
    
    if score_LC(tt) <= 0
        score_LC(tt) = 0;
    end
    
    if score_LC(tt) > thr
        exp_to_compare = features{tt};
        cum_LC(tt) = 1;
    end
end

cum_LC = cumsum(cum_LC);

fprintf('Done!\n');

%% Info plot

CF = features_cum(1,:);
RMS = features_cum(2,:);

s = [ 0 sections ];
pos_results = (s(1:end-1) + s(2:end))/2;

figure('pos',[0 0 750 550])

%% Plot CF

% info
m = min(CF);
M = max(CF);
d = M-m;

bot = m - d*0.2;
top = M + d*0.2;

% plot
subplot(5,1,1); hold on;

ylim([bot top]);
xlim([time(1) time(end)]);
ylabel('CF');

for ii = 1 : 1 : n_test
    line([sections(ii) sections(ii)], [bot top], 'LineWidth', 2, 'LineStyle',':', 'Color', [0.4 0.4 0.4]);
end

plot(time,CF);
xticks([0 sections])
box on

%% Plot RMS

% info
m = min(RMS);
M = max(RMS);
d = M-m;

bot = m - d*0.2;
top = M + d*0.2;

% plot
subplot(5,1,2); hold on;

ylim([bot top]);
xlim([time(1) time(end)]);
ylabel('RMS [A]');

for ii = 1 : 1 : n_test
    line([sections(ii) sections(ii)], [bot top], 'LineWidth', 2, 'LineStyle',':', 'Color', [0.4 0.4 0.4]);
end

plot(time,RMS);

xticks([0 sections])
box on

%% Plot AH

% info
m = min(score_AH);
M = max(score_AH);
d = M-m;

bot = 0;
top = M + d*0.2;

% plot
subplot(5,1,3); hold on;

ylim([bot top]);
xlim([time(1) time(end)]);
ylabel('AH');

for ii = 1 : 1 : n_test
    line([sections(ii) sections(ii)], [bot top], 'LineWidth', 2, 'LineStyle',':', 'Color', [0.4 0.4 0.4]);
end
plot(pos_results, score_AH,'mo-','LineWidth',2,...
        'MarkerEdgeColor','k','MarkerFaceColor',[0.49 1 0.63], 'MarkerSize',10)

xticks([0 sections])
box on

%% Plot AP

% info
m = min(score_AP);
M = max(score_AP);
d = M-m;

bot = 0;
top = M + d*0.2;

% plot
subplot(5,1,4); hold on;

ylim([bot top]);
xlim([time(1) time(end)]);
ylabel('AP');

for ii = 1 : 1 : n_test
    line([sections(ii) sections(ii)], [bot top], 'LineWidth', 2, 'LineStyle',':', 'Color', [0.4 0.4 0.4]);
end

plot(pos_results, score_AP,'mo-','LineWidth',2,...
        'MarkerEdgeColor','k','MarkerFaceColor',[0.49 1 0.63], 'MarkerSize',10)

xticks([0 sections])
box on

%% Plot LC

% info
m = min(score_LC);
M = max(score_LC);
d = M-m;

bot = 0;
top = M + d*0.2;

% plot
subplot(5,1,5); hold on;

ylim([bot top]);
xlim([time(1) time(end)]);
ylabel('LC');

for ii = 1 : 1 : n_test
    line([sections(ii) sections(ii)], [bot top], 'LineWidth', 2, 'LineStyle',':', 'Color', [0.4 0.4 0.4]);
end
yyaxis left
plot(pos_results, score_LC,'-m','LineWidth',2)

plot(pos_results(score_LC>=thr), score_LC(score_LC>=thr),'o','LineWidth',2,...
        'MarkerEdgeColor','k','MarkerFaceColor',[0.49 1 0.63], 'MarkerSize',10)
    
plot(pos_results(score_LC<thr), score_LC(score_LC<thr),'o','LineWidth',2,...
        'MarkerEdgeColor','k','MarkerFaceColor',[1 0.49 0.63], 'MarkerSize',10)

line([0 time(end)], [thr thr], 'LineWidth', 2.5, 'LineStyle','--', 'Color', 'k');

yyaxis right
plot(pos_results, cum_LC,'bd:', 'linewidth',2,'MarkerEdgeColor','k','MarkerFaceColor',[0.63 0.49 1], 'MarkerSize',7);
ylabel('Score');

xticks([0 sections])
box on

xlabel('Time [s]');













