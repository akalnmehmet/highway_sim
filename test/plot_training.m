% En son checkpoint'i yukle
ROOT = fileparts(fileparts(mfilename('fullpath')));
kayit = load(fullfile(ROOT, 'models', 'ddqn_ep4100.mat'));
% Eger 4500 yoksa en yuksek numarayi kullan
son_ep = 4100;
episode_oduller = kayit.episode_oduller(1:son_ep);
toplam_adim = kayit.toplam_adim;
carpma_sayisi = kayit.carpma_sayisi;
x = 1:son_ep;

figure('Position', [100 100 1400 900]);

% 1. Odul egrisi
subplot(2,2,1);
plot(x, episode_oduller, 'Color', [0 0.4 0.8 0.2]); hold on;
plot(x, movmean(episode_oduller, 50), 'r', 'LineWidth', 2);
plot(x, movmean(episode_oduller, 200), 'y', 'LineWidth', 2.5);
xline(3000, 'w--', 'Faz 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
xlabel('Episode'); ylabel('Toplam Ödül');
title('Ödül Eğrisi');
legend('Ham','50ep ort','200ep ort','Location','northwest');
grid on;

% 2. Ogrenme trendi
subplot(2,2,2);
trend = movmean(episode_oduller, 20);
plot(x, trend, 'g', 'LineWidth', 1.5); hold on;
p = polyfit(x, trend', 1);
plot(x, polyval(p,x), 'w--', 'LineWidth', 1.2);
xline(3000, 'w--', 'Faz 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
xlabel('Episode'); ylabel('Ödül (20ep ort)');
title('Öğrenme Trendi');
legend('20ep ort','Trend','Location','northwest');
grid on;

% 3. Epsilon azalisi
subplot(2,2,3);
E0 = 1.0; ED = 2.3026e-6;
N_ep = round(toplam_adim / son_ep);
ep_vals = zeros(1, son_ep);
eps = E0;
for i = 1:son_ep
    ep_vals(i) = eps;
    for j = 1:N_ep
        eps = max(0.1, eps*(1-ED));
    end
end
plot(x, ep_vals, 'm', 'LineWidth', 1.5);
xline(3000, 'w--', 'Faz 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
yline(0.1, 'w--', 'Min=0.1');
xlabel('Episode'); ylabel('Epsilon');
title('Keşif Oranı (Epsilon)');
grid on;

% 4. Carpma analizi
subplot(2,2,4);
% Iki bolumu ayri normalize et
idx = 3000;
on1 = mean(episode_oduller(1:idx));
st1 = std(episode_oduller(1:idx));
on2 = mean(episode_oduller(idx+1:son_ep));
st2 = std(episode_oduller(idx+1:son_ep));
norm = zeros(1,son_ep);
norm(1:idx) = (episode_oduller(1:idx)-on1)/(st1+1e-6);
norm(idx+1:son_ep) = (episode_oduller(idx+1:son_ep)-on2)/(st2+1e-6);
proxy = double(norm < -1.5);
pencere = 100;
kayan = zeros(1,son_ep);
for i = pencere:son_ep
    kayan(i) = mean(proxy(i-pencere+1:i))*100;
end
plot(x(pencere:end), kayan(pencere:end), 'r', 'LineWidth', 1.5); hold on;
xline(3000, 'w--', 'Faz 2', 'LabelVerticalAlignment','bottom','LineWidth',1.5);
kum = carpma_sayisi/son_ep*100;
yline(kum, 'w--', sprintf('Kumulatif: %.1f%%',kum));
xlabel('Episode'); ylabel('Çarpma Oranı (%)');
title(sprintf('Çarpma Analizi (Kumulatif: %.1f%%)', kum));
grid on;

sgtitle('DDQN + NMPC Eğitim Analizi — Episode 1-4500', 'FontSize', 14, 'FontWeight', 'bold');

saveas(gcf, fullfile(ROOT, 'results', 'sekil7_egitim_analizi.png'))