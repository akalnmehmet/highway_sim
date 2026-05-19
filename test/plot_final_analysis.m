% DDQN training analysis — episode 1-4400
clear; clc;

ROOT        = fileparts(fileparts(mfilename('fullpath')));
data        = load(fullfile(ROOT, 'models', 'ddqn_ep4400.mat'));
last_ep     = 4400;
rewards     = data.episode_oduller(1:last_ep);
total_steps = data.toplam_adim;
n_collision = data.carpma_sayisi;
x           = 1:last_ep;
phase2_ep   = 3000;

fprintf('========== TRAINING SUMMARY ==========\n');
fprintf('Total episodes    : %d\n',   last_ep);
fprintf('Total steps       : %d\n',   total_steps);
fprintf('Final epsilon     : %.4f\n', data.epsilon);
fprintf('Collisions        : %d\n',   n_collision);
fprintf('First 100ep mean  : %.2f\n', mean(rewards(1:100)));
fprintf('Last  100ep mean  : %.2f\n', mean(rewards(last_ep-99:last_ep)));
fprintf('Reward improvement: %.1f%%\n', ...
    (mean(rewards(last_ep-99:last_ep)) - mean(rewards(1:100))) / ...
    abs(mean(rewards(1:100))) * 100);
fprintf('======================================\n');

figure('Position', [50 50 1400 900], 'Color', 'k');

% 1. Reward curve
subplot(2,2,1);
plot(x, rewards, 'Color', [0 0.4 0.8 0.2], 'LineWidth', 0.5); hold on;
plot(x, movmean(rewards,  50), 'r', 'LineWidth', 2);
plot(x, movmean(rewards, 200), 'y', 'LineWidth', 2.5);
xline(phase2_ep, 'w--', 'Phase 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
xlabel('Episode'); ylabel('Total Reward');
title('Reward Curve');
legend('Raw','50-ep avg','200-ep avg','Location','northwest');
grid on; set(gca,'Color','k','XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);

% 2. Learning trend
subplot(2,2,2);
trend20 = movmean(rewards, 20);
plot(x, trend20, 'g', 'LineWidth', 1.5); hold on;
p = polyfit(x, trend20', 1);
plot(x, polyval(p,x), 'w--', 'LineWidth', 1.2);
xline(phase2_ep, 'w--', 'Phase 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
xlabel('Episode'); ylabel('Reward (20-ep avg)');
title('Learning Trend');
legend('20-ep avg','Linear fit','Location','northwest');
grid on; set(gca,'Color','k','XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);

% 3. Epsilon decay
subplot(2,2,3);
E0 = 1.0; ED = 2.3026e-6;
steps_per_ep = round(total_steps / last_ep);
ep_vals = zeros(1, last_ep);
eps_sim = E0;
for i = 1:last_ep
    ep_vals(i) = eps_sim;
    for j = 1:steps_per_ep
        eps_sim = max(0.1, eps_sim*(1-ED));
    end
end
plot(x, ep_vals, 'm', 'LineWidth', 1.5);
xline(phase2_ep, 'w--', 'Phase 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
yline(0.1, 'w--', 'Min=0.1');
xlabel('Episode'); ylabel('Epsilon');
title('Exploration Rate (Epsilon Decay)');
grid on; set(gca,'Color','k','XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);

% 4. Collision analysis
subplot(2,2,4);
mu1 = mean(rewards(1:phase2_ep));          sd1 = std(rewards(1:phase2_ep));
mu2 = mean(rewards(phase2_ep+1:last_ep));  sd2 = std(rewards(phase2_ep+1:last_ep));
norm_r = zeros(1, last_ep);
norm_r(1:phase2_ep)          = (rewards(1:phase2_ep)         - mu1) / (sd1+1e-6);
norm_r(phase2_ep+1:last_ep)  = (rewards(phase2_ep+1:last_ep) - mu2) / (sd2+1e-6);
proxy  = double(norm_r < -1.5);
window = 100;
rolling = zeros(1, last_ep);
for i = window:last_ep
    rolling(i) = mean(proxy(i-window+1:i)) * 100;
end
plot(x(window:end), rolling(window:end), 'r', 'LineWidth', 1.5); hold on;
xline(phase2_ep, 'w--', 'Phase 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
cumulative_rate = n_collision / last_ep * 100;
yline(cumulative_rate, 'w--', sprintf('Cumulative: %.1f%%', cumulative_rate));
xlabel('Episode'); ylabel('Collision Rate (%)');
title(sprintf('Collision Analysis (Cumulative: %.1f%%)', cumulative_rate));
grid on; set(gca,'Color','k','XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);

sgtitle('DDQN + NMPC Training Analysis — Episodes 1–4400', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');

out_path = fullfile(ROOT, 'results', 'training_results.png');
saveas(gcf, out_path);
fprintf('\nFigure saved: %s\n', out_path);