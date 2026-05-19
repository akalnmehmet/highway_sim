% ddqn_ep4400 grafik analizi
clear; clc;

ROOT = fileparts(fileparts(mfilename('fullpath')));
kayit_klasoru = fullfile(ROOT, 'models');
kayit = load(fullfile(kayit_klasoru, 'ddqn_ep4400.mat'));

son_ep = 4400;
episode_oduller = kayit.episode_oduller(1:son_ep);
toplam_adim     = kayit.toplam_adim;
carpma_sayisi   = kayit.carpma_sayisi;
x = 1:son_ep;
idx_faz2 = 3000;

fprintf('========== EGITIM OZETI ==========\n');
fprintf('Toplam episode    : %d\n', son_ep);
fprintf('Toplam adim       : %d\n', toplam_adim);
fprintf('Son epsilon       : %.4f\n', kayit.epsilon);
fprintf('Carpma sayisi     : %d\n', carpma_sayisi);
fprintf('Ilk 100ep ort     : %.2f\n', mean(episode_oduller(1:100)));
fprintf('Son 100ep ort     : %.2f\n', mean(episode_oduller(son_ep-99:son_ep)));
fprintf('Odul artisi       : %.1f%%\n', ...
    (mean(episode_oduller(son_ep-99:son_ep)) - mean(episode_oduller(1:100))) / ...
    abs(mean(episode_oduller(1:100))) * 100);
fprintf('==================================\n');

figure('Position', [50 50 1400 900], 'Color', 'k');

% 1. Odul egrisi
subplot(2,2,1);
plot(x, episode_oduller, 'Color', [0 0.4 0.8 0.2], 'LineWidth', 0.5); hold on;
plot(x, movmean(episode_oduller, 50),  'r', 'LineWidth', 2);
plot(x, movmean(episode_oduller, 200), 'y', 'LineWidth', 2.5);
xline(idx_faz2, 'w--', 'Faz 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
xlabel('Episode'); ylabel('Toplam Ödül');
title('Ödül Eğrisi');
legend('Ham','50ep ort','200ep ort','Location','northwest');
grid on; set(gca,'Color','k','XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);

% 2. Ogrenme trendi
subplot(2,2,2);
trend20 = movmean(episode_oduller, 20);
plot(x, trend20, 'g', 'LineWidth', 1.5); hold on;
p = polyfit(x, trend20', 1);
plot(x, polyval(p,x), 'w--', 'LineWidth', 1.2);
xline(idx_faz2, 'w--', 'Faz 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
xlabel('Episode'); ylabel('Ödül (20ep ort)');
title('Öğrenme Trendi');
legend('20ep ort','Trend','Location','northwest');
grid on; set(gca,'Color','k','XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);

% 3. Epsilon azalisi
subplot(2,2,3);
E0 = 1.0; ED = 2.3026e-6;
N_ep = round(toplam_adim / son_ep);
ep_vals = zeros(1, son_ep);
eps_sim = E0;
for i = 1:son_ep
    ep_vals(i) = eps_sim;
    for j = 1:N_ep
        eps_sim = max(0.1, eps_sim*(1-ED));
    end
end
plot(x, ep_vals, 'm', 'LineWidth', 1.5);
xline(idx_faz2, 'w--', 'Faz 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
yline(0.1, 'w--', 'Min=0.1');
xlabel('Episode'); ylabel('Epsilon');
title('Keşif Oranı (Epsilon)');
grid on; set(gca,'Color','k','XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);

% 4. Carpma analizi
subplot(2,2,4);
on1 = mean(episode_oduller(1:idx_faz2));
st1 = std(episode_oduller(1:idx_faz2));
on2 = mean(episode_oduller(idx_faz2+1:son_ep));
st2 = std(episode_oduller(idx_faz2+1:son_ep));
norm_odul = zeros(1, son_ep);
norm_odul(1:idx_faz2) = (episode_oduller(1:idx_faz2)-on1)/(st1+1e-6);
norm_odul(idx_faz2+1:son_ep) = (episode_oduller(idx_faz2+1:son_ep)-on2)/(st2+1e-6);
proxy = double(norm_odul < -1.5);
pencere = 100;
kayan = zeros(1, son_ep);
for i = pencere:son_ep
    kayan(i) = mean(proxy(i-pencere+1:i))*100;
end
plot(x(pencere:end), kayan(pencere:end), 'r', 'LineWidth', 1.5); hold on;
xline(idx_faz2, 'w--', 'Faz 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
kum = carpma_sayisi/son_ep*100;
yline(kum, 'w--', sprintf('Kumulatif: %.1f%%', kum));
xlabel('Episode'); ylabel('Çarpma Oranı (%)');
title(sprintf('Çarpma Analizi (Kumulatif: %.1f%%)', kum));
grid on; set(gca,'Color','k','XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);

sgtitle('DDQN + NMPC Eğitim Analizi — Episode 1-4400', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');

% Kaydet
cikti = fullfile(ROOT, 'results', 'sekil7_egitim_analizi_4400.png');
saveas(gcf, cikti);
fprintf('\nGrafik kaydedildi: %s\n', cikti);