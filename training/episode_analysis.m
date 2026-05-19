% Faz 2 sonunu goster (episode 1-3900)
ROOT = fileparts(fileparts(mfilename('fullpath')));
kayit = load(fullfile(ROOT, 'models', 'ddqn_ep3900.mat'));

son_ep = 3900;
episode_oduller = kayit.episode_oduller(1:son_ep);
epsilon = kayit.epsilon;
toplam_adim = kayit.toplam_adim;
carpma_sayisi = kayit.carpma_sayisi;

figure('Position', [100 100 1200 800]);

% 1. Odul egrisi
subplot(2,2,1);
x = 1:son_ep;
plot(x, episode_oduller, 'Color', [0 0.4 0.8 0.25], 'LineWidth', 0.5); hold on;
plot(x, movmean(episode_oduller, 50), 'r', 'LineWidth', 2);
plot(x, movmean(episode_oduller, 200), 'y', 'LineWidth', 2.5);
xlabel('Episode'); ylabel('Toplam Odul');
title('Odul Egrisi — Faz 1 + Faz 2');
legend('Ham odul','50ep ort','200ep ort','Location','northwest');
xline(3000, 'w--', 'Faz 2 Baslangic', 'LabelVerticalAlignment', 'bottom');
grid on;

% 2. Ogrenme trendi
subplot(2,2,2);
plot(x, movmean(episode_oduller, 20), 'g', 'LineWidth', 1.5);
p = polyfit(x, movmean(episode_oduller, 20)', 1);
hold on;
plot(x, polyval(p, x), 'w--', 'LineWidth', 1);
xline(3000, 'w--');
xlabel('Episode'); ylabel('Odul (20ep ort)');
title('Ogrenme Trendi');
legend('20ep ort','Trend','Location','northwest');
grid on;

% 3. Epsilon
subplot(2,2,3);
EPSILON_0 = 1.0; E_DECAY = 2.3026e-6;
N_ADIM_EP = round(toplam_adim / son_ep);
ep_per_ep = zeros(1, son_ep);
eps_sim = EPSILON_0;
for i = 1:son_ep
    ep_per_ep(i) = eps_sim;
    for j = 1:N_ADIM_EP
        eps_sim = max(0.1, eps_sim * (1 - E_DECAY));
    end
end
plot(x, ep_per_ep, 'm', 'LineWidth', 1.5);
xline(3000, 'w--', 'Faz 2');
yline(0.1, 'w--', 'Min=0.1');
xlabel('Episode'); ylabel('Epsilon');
title('Kesif Orani');
grid on;

% 4. Carpma
subplot(2,2,4);
odul_norm = zeros(1, son_ep);
idx_gecis = 3000;
ort1 = mean(episode_oduller(1:idx_gecis));
std1 = std(episode_oduller(1:idx_gecis));
odul_norm(1:idx_gecis) = (episode_oduller(1:idx_gecis)-ort1)/(std1+1e-6);
ort2 = mean(episode_oduller(idx_gecis+1:son_ep));
std2 = std(episode_oduller(idx_gecis+1:son_ep));
odul_norm(idx_gecis+1:son_ep) = (episode_oduller(idx_gecis+1:son_ep)-ort2)/(std2+1e-6);
carpma_proxy = double(odul_norm < -1.5);
pencere = 100;
carpma_kayan = zeros(1, son_ep);
for i = pencere:son_ep
    carpma_kayan(i) = mean(carpma_proxy(i-pencere+1:i)) * 100;
end
plot(x(pencere:end), carpma_kayan(pencere:end), 'r', 'LineWidth', 1.5);
hold on;
xline(3000, 'w--', 'Faz 2');
kumulatif = carpma_sayisi/son_ep*100;
yline(kumulatif, 'w--', sprintf('Kumulatif: %.1f%%', kumulatif));
xlabel('Episode'); ylabel('Carpma Orani (%)');
title('Carpma Analizi');
grid on;

sgtitle('DDQN Egitim Analizi — Faz 1 + Faz 2 (Episode 1-3900)', ...
    'FontSize', 14, 'FontWeight', 'bold');

% Kaydet
saveas(gcf, 'C:\Users\mehme\Desktop\highway_sim\egitim_analizi_faz2.png')