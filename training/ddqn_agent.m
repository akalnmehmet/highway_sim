% =========================================================
% FAZ 5: DDQN + NMPC TAM ENTEGRASYON
% Yol sonu tespiti eklendi (A+C cozumu)
% =========================================================
clear all; close all; clc;

warning('off', 'all');

global NMPC_TH NMPC_EYREF
NMPC_TH    = 1.5;
NMPC_EYREF = 0;

ROOT = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(ROOT, 'lib', 'pipeacosta-traci4matlab-245ddc7'));
addpath(fullfile(ROOT, 'training'));
addpath(fullfile(ROOT, 'env'));
addpath(fullfile(ROOT, 'nmpc'));
javaaddpath(fullfile(ROOT, 'lib', 'pipeacosta-traci4matlab-245ddc7', 'traci4matlab.jar'));
java.lang.System.setProperty('java.net.preferIPv4Stack', 'true');

% =========================================================
% HIPERPARAMETRELER
% =========================================================
N_EPISODE    = 4500;
N_ADIM       = 300;
GAMMA        = 0.99;
ETA          = 0.0005;
EPSILON_0    = 1.0;
EPSILON_SON  = 0.1;
E_DECAY      = 2.3026e-6;
N_UPDATE     = 20000;
BATCH        = 32;
BUF_KAP      = 500000;
KAYIT_SIKL   = 100;

LW           = 3.6;
DELTA_TH     = 0.1;
TH_MIN       = 0.1;
TH_MAX       = 3.0;
V_REF        = 33.0;
TTC_ESIK     = 2.0;
D0           = 3.0;
Ts           = 0.2;
NUM_SERIT    = 3;

% Yol sonu tespiti icin esik
YOL_SONU_ESIK = 480;  % 500 adimdan once bittiyse yol sonu

% =========================================================
% CHECKPOINT KONTROL
% =========================================================
kayit_klasoru = fullfile(ROOT, 'models');
if ~exist(kayit_klasoru, 'dir'), mkdir(kayit_klasoru); end

baslangic_episode  = 1;
episode_oduller    = zeros(1, N_EPISODE);
carpma_sayisi      = 0;
yol_sonu_sayisi    = 0;
toplam_adim        = 0;
ortalama_grad      = [];
ortalama_kare_grad = [];

checkpoint_listesi = dir(fullfile(kayit_klasoru, 'ddqn_ep*.mat'));

if ~isempty(checkpoint_listesi)
    ep_numaralari = zeros(1, length(checkpoint_listesi));
    for k = 1:length(checkpoint_listesi)
        sayi = regexp(checkpoint_listesi(k).name, '\d+', 'match');
        ep_numaralari(k) = str2double(sayi{1});
    end
    [son_ep, idx] = max(ep_numaralari);
    checkpoint_dosya = fullfile(kayit_klasoru, checkpoint_listesi(idx).name);
    fprintf('Checkpoint bulundu: %s\n', checkpoint_listesi(idx).name);
    fprintf('Devam etmek ister misin? (e/h): ');
    cevap = input('', 's');
    if strcmpi(cevap, 'e')
        kayit = load(checkpoint_dosya);
        primary_net        = kayit.primary_net;
        target_net         = kayit.target_net;
        epsilon            = kayit.epsilon;
        toplam_adim        = kayit.toplam_adim;
        carpma_sayisi      = kayit.carpma_sayisi;
        baslangic_episode  = son_ep + 1;
        episode_oduller(1:son_ep) = kayit.episode_oduller(1:son_ep);
        if isfield(kayit, 'yol_sonu_sayisi')
            yol_sonu_sayisi = kayit.yol_sonu_sayisi;
        end
        fprintf('Episode %d den devam | epsilon=%.4f\n\n', baslangic_episode, epsilon);
    else
        fprintf('Sifirdan baslanıyor...\n\n');
        primary_net = ddqn_create_network();
        target_net  = ddqn_create_network();
        epsilon     = EPSILON_0;
    end
else
    fprintf('Checkpoint yok, sifirdan baslanıyor...\n\n');
    primary_net = ddqn_create_network();
    target_net  = ddqn_create_network();
    epsilon     = EPSILON_0;
end

% =========================================================
% NMPC
% =========================================================
fprintf('NMPC olusturuluyor...\n');
evalc('nlobj_b = nmpc_longitudinal_create();');
fprintf('NMPC hazir!\n\n');

buffer = ReplayBuffer(BUF_KAP, 19);

fprintf('========================================\n');
fprintf('  DDQN + NMPC EGITIMI BASLIYOR\n');
fprintf('  Toplam episode : %d\n', N_EPISODE);
fprintf('  Adim/episode   : %d\n', N_ADIM);
fprintf('  Baslangic ep   : %d\n', baslangic_episode);
fprintf('  Yol uzunlugu   : 50.000 m (guncellendi)\n');
fprintf('========================================\n\n');
fprintf('%-8s %-10s %-8s %-10s %-8s %-12s\n', ...
    'Episode', 'Ort.Odul', 'Epsilon', 'Carpma%', 'YolSonu%', 'Kalan Sure');
fprintf('%s\n', repmat('-', 1, 64));

egitim_baslangic = tic;

% =========================================================
% ANA EGITIM DONGUSU
% =========================================================
for episode = baslangic_episode:N_EPISODE

    try; traci.close(); catch; end
    system('taskkill /F /IM sumo.exe /T 2>nul 1>nul');
    system('taskkill /F /IM sumo-gui.exe /T 2>nul 1>nul');
    pause(1.5);

    system(['start /B sumo' ...
            ' -n "' fullfile(ROOT, 'sumo', 'highway.net.xml') '"' ...
            ' -r "' fullfile(ROOT, 'sumo', 'highway.rou.xml') '"' ...
            ' --remote-port 8813 --start' ...
            ' --no-step-log --no-warnings > nul 2>&1']);
    pause(3);

    try
        traci.init(8813, 10, '192.168.1.101');
    catch
        continue;
    end

    % Ego gorunene kadar bekle
    ego_var = false;
    for k = 1:20
        traci.simulationStep();
        if ismember('ego', traci.vehicle.getIDList())
            ego_var = true;
            break;
        end
    end

    if ~ego_var
        traci.close(); continue;
    end

    % Baslangic durumu
    ego_konum  = traci.vehicle.getPosition('ego');
    ego_hiz    = traci.vehicle.getSpeed('ego');
    NMPC_TH    = 1.5;
    NMPC_EYREF = ego_konum(2);

    lider_id = traci.vehicle.getLeader('ego', 150);
    if ~isempty(lider_id)
        lk = traci.vehicle.getPosition(lider_id);
        lv = traci.vehicle.getSpeed(lider_id);
        d_init  = max(2.1, abs(lk(1) - ego_konum(1)));
        dv_init = lv - ego_hiz;
    else
        d_init = 50; dv_init = 0;
    end

    if ego_hiz < 1, ego_hiz = 20; end

    x2 = [d_init; dv_init; ego_hiz; 0];
    u2_onceki = 0;
    s = get_state_vector();

    episode_odulu = 0;
    carpma_oldu   = false;
    yol_sonu_oldu = false;

    % --------------------------------------------------
    % ADIM DONGUSU
    % --------------------------------------------------
    for adim = 1:N_ADIM

        % 1. DDQN eylem sec
        if rand() <= epsilon
            a = randi(5);
        else
            s_dl  = dlarray(single(s), 'CB');
            q_val = predict(primary_net, s_dl);
            [~, a] = max(extractdata(q_val));
        end

        % 2. Referanslari guncelle
        [NMPC_EYREF, NMPC_TH] = step_environment(a, NMPC_EYREF, NMPC_TH, ...
                                                   LW, DELTA_TH, TH_MIN, TH_MAX);

        % 3. Boyuna NMPC
        try
            evalc('[u2, ~, info_b] = nlmpcmove(nlobj_b, x2, u2_onceki);');
            if info_b.ExitFlag < 0, u2 = u2_onceki * 0.9; end
        catch
            u2 = 0;
        end

        % 4. Serit degisimi
        try
            ego_serit = traci.vehicle.getLaneIndex('ego');
            if a == 1 && ego_serit > 0
                traci.vehicle.changeLane('ego', ego_serit - 1, 3.0);
            elseif a == 3 && ego_serit < (NUM_SERIT - 1)
                traci.vehicle.changeLane('ego', ego_serit + 1, 3.0);
            end
        catch
        end

        % 5. Hiz komutu
        v_yeni = max(0, min(35, x2(3) + u2 * Ts));
        try; traci.vehicle.setSpeed('ego', v_yeni); catch; end

        % 6. Simulasyon adimi
        traci.simulationStep();

        % 7. Yeni durum
        arac_listesi = traci.vehicle.getIDList();
        if ~ismember('ego', arac_listesi)
            % ================================================
            % YOL SONU / CARPMA AYRIMI (C cozumu)
            % ================================================
            if adim >= YOL_SONU_ESIK
                % 480+ adimda bitti = yol sonuna ulasti
                r             = episode_odulu / adim;  % Ortalama adim odulu
                done          = true;
                carpma_oldu   = false;
                yol_sonu_oldu = true;
            else
                % Erken bitti = gercek carpma
                r           = -10;
                done        = true;
                carpma_oldu = true;
            end
            s_yeni = s;
        else
            ego_k = traci.vehicle.getPosition('ego');
            ego_v = traci.vehicle.getSpeed('ego');
            ego_a = (ego_v - x2(3)) / Ts;

            lider_id = traci.vehicle.getLeader('ego', 150);
            if ~isempty(lider_id)
                lk   = traci.vehicle.getPosition(lider_id);
                lv   = traci.vehicle.getSpeed(lider_id);
                d_y  = max(0.1, abs(lk(1) - ego_k(1)));
                dv_y = lv - ego_v;
            else
                d_y = 100; dv_y = 0;
            end

            x2 = [d_y; dv_y; ego_v; ego_a];
            u2_onceki = u2;

            s_yeni = get_state_vector();
            [r, done, carpma_oldu] = compute_reward(s_yeni, a, V_REF, TTC_ESIK);
        end

        % 8. Buffer
        buffer.ekle(s, a, r, s_yeni, done);
        episode_odulu = episode_odulu + r;
        s = s_yeni;
        toplam_adim = toplam_adim + 1;

        % 9. Ag egitimi
        if buffer.hazir_mi(BATCH)
            [s_b, a_b, r_b, s__b, done_b] = buffer.ornekle(BATCH);
            s__dl = dlarray(single(s__b), 'CB');
            q_son_primary = extractdata(predict(primary_net, s__dl));
            [~, en_iyi] = max(q_son_primary, [], 1);
            q_son_target = extractdata(predict(target_net, s__dl));
            q_hedef_vals = zeros(1, BATCH);
            for bb = 1:BATCH
                q_hedef_vals(bb) = q_son_target(en_iyi(bb), bb);
            end
            y_t = r_b + GAMMA .* q_hedef_vals .* (1 - done_b);
            s_b_dl = dlarray(single(s_b), 'CB');
            [primary_net, ortalama_grad, ortalama_kare_grad] = ...
                update_network(primary_net, s_b_dl, a_b, y_t, ...
                            ETA, toplam_adim, ortalama_grad, ortalama_kare_grad);
        end

        % 10. Target ag
        if mod(toplam_adim, N_UPDATE) == 0
            target_net = primary_net;
            fprintf('  [TARGET AG GUNCELLENDI] Adim: %d\n', toplam_adim);
        end

        % 11. Epsilon
        epsilon = max(EPSILON_SON, epsilon * (1 - E_DECAY));

        if done, break; end
    end

    try; traci.close(); catch; end

    episode_oduller(episode) = episode_odulu;
    if carpma_oldu,   carpma_sayisi   = carpma_sayisi   + 1; end
    if yol_sonu_oldu, yol_sonu_sayisi = yol_sonu_sayisi + 1; end

    % Ilerleme raporu
    if mod(episode, 10) == 0
        gecen_sure   = toc(egitim_baslangic);
        sure_per_ep  = gecen_sure / max(1, episode - baslangic_episode + 1);
        kalan_sure   = (N_EPISODE - episode) * sure_per_ep;
        kalan_dk     = floor(kalan_sure / 60);
        kalan_sn     = mod(floor(kalan_sure), 60);
        son_10_ort   = mean(episode_oduller(max(1,episode-9):episode));
        carpma_orani = carpma_sayisi   / episode * 100;
        yolsonu_orani = yol_sonu_sayisi / episode * 100;
        fprintf('%-8d %-10.2f %-8.4f %-10.1f %-8.1f %d dk %d sn\n', ...
            episode, son_10_ort, epsilon, carpma_orani, yolsonu_orani, kalan_dk, kalan_sn);
    end

    if mod(episode, 100) == 0
        son_100_ort = mean(episode_oduller(max(1,episode-99):episode));
        fprintf('%s\n', repmat('=', 1, 64));
        fprintf('OZET %d | Ort.Odul: %.2f | Epsilon: %.4f | Carpma: %.1f%% | YolSonu: %.1f%%\n', ...
            episode, son_100_ort, epsilon, ...
            carpma_sayisi/episode*100, yol_sonu_sayisi/episode*100);
        fprintf('%s\n', repmat('=', 1, 64));
    end

    % Checkpoint kaydet
    if mod(episode, KAYIT_SIKL) == 0
        dosya = fullfile(kayit_klasoru, sprintf('ddqn_ep%d.mat', episode));
        save(dosya, 'primary_net', 'target_net', 'epsilon', ...
             'episode_oduller', 'toplam_adim', 'carpma_sayisi', 'yol_sonu_sayisi');
        fprintf('  [KAYIT] ddqn_ep%d.mat\n', episode);
    end

end

% Son kayit
dosya_son = fullfile(kayit_klasoru, 'ddqn_final.mat');
save(dosya_son, 'primary_net', 'target_net', 'epsilon', ...
     'episode_oduller', 'toplam_adim', 'carpma_sayisi', 'yol_sonu_sayisi');

toplam_sure = toc(egitim_baslangic);
fprintf('\n========================================\n');
fprintf('  EGITIM TAMAMLANDI!\n');
fprintf('  Toplam sure    : %.1f dakika\n', toplam_sure/60);
fprintf('  Gercek carpma  : %d / %d = %.1f%%\n', ...
    carpma_sayisi, N_EPISODE, carpma_sayisi/N_EPISODE*100);
fprintf('  Yol sonu       : %d / %d = %.1f%%\n', ...
    yol_sonu_sayisi, N_EPISODE, yol_sonu_sayisi/N_EPISODE*100);
fprintf('  Son model      : ddqn_final.mat\n');
fprintf('========================================\n');

% Grafik
figure;
gecerli  = episode_oduller(1:N_EPISODE);
ort_odul = movmean(gecerli, 100);
plot(ort_odul, 'r', 'LineWidth', 2); hold on;
plot(gecerli, 'Color', [0 0 1 0.15]);
xlabel('Episode'); ylabel('Normalize odul');
title('DDQN + NMPC Egitim Sonucu');
legend('Ortalama (100 ep)', 'Ham odul');
grid on;