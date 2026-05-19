% =========================================================
% FAZ 6: EHLİYET SINAVI (Ajanın Görsel Testi)
% =========================================================
clear all; close all; clc;
warning('off', 'all');

global NMPC_TH NMPC_EYREF
NMPC_TH    = 1.5;
NMPC_EYREF = 0;

% --- Yollar ve Java ---
ROOT = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(ROOT, 'lib', 'pipeacosta-traci4matlab-245ddc7'));
addpath(fullfile(ROOT, 'training'));
addpath(fullfile(ROOT, 'env'));
addpath(fullfile(ROOT, 'nmpc'));
javaaddpath(fullfile(ROOT, 'lib', 'pipeacosta-traci4matlab-245ddc7', 'traci4matlab.jar'));
java.lang.System.setProperty('java.net.preferIPv4Stack', 'true');

% --- Parametreler (Test için Adım sayısını uzattık) ---
N_ADIM       = 1000;
LW           = 3.6;
DELTA_TH     = 0.1;
TH_MIN       = 0.1;
TH_MAX       = 3.0;
Ts           = 0.2;
NUM_SERIT    = 3;

% =========================================================
% 1. EĞİTİLMİŞ MODELİ YÜKLE
% =========================================================
fprintf('Egitilmis DDQN modeli yukleniyor...\n');
load(fullfile(ROOT, 'models', 'ddqn_ep4400.mat'), 'primary_net');

fprintf('NMPC olusturuluyor...\n');
evalc('nlobj_b = nmpc_longitudinal_create();');
fprintf('Sistem Teste Hazir!\n');

% =========================================================
% 2. SUMO-GUI'Yİ BAŞLAT
% =========================================================
try; traci.close(); catch; end
system('taskkill /F /IM sumo.exe /T 2>nul 1>nul');
system('taskkill /F /IM sumo-gui.exe /T 2>nul 1>nul');
pause(1.5);

% DİKKAT: sumo yerine sumo-gui kullanıyoruz!
system(['start /B sumo-gui' ...
        ' -n "' fullfile(ROOT, 'sumo', 'highway.net.xml') '"' ...
        ' -r "' fullfile(ROOT, 'sumo', 'highway.rou.xml') '"' ...
        ' --remote-port 8813 --start' ...
        ' --no-step-log --no-warnings > nul 2>&1']);
pause(5);

traci.init(8813, 10, '10.169.174.61');

% Ego aracı bekle
ego_var = false;
for k = 1:20
    traci.simulationStep();
    if ismember('ego', traci.vehicle.getIDList())
        ego_var = true; break;
    end
end
if ~ego_var, error('Ego arac simulasyonda bulunamadi!'); end

% Başlangıç değerleri
ego_konum  = traci.vehicle.getPosition('ego');
ego_hiz    = traci.vehicle.getSpeed('ego');
if ego_hiz < 1, ego_hiz = 20; end
NMPC_EYREF = ego_konum(2);

x2 = [50; 0; ego_hiz; 0];
u2_onceki = 0;
s = get_state_vector();

fprintf('\nEHLIYET SINAVI BASLADI! (Lutfen SUMO penceresine gecin)\n');

% =========================================================
% 3. SÖMÜRÜ (EXPLOITATION) DÖNGÜSÜ
% =========================================================
for adim = 1:N_ADIM
    
    % RASTGELELİK YOK - Beyin en yüksek puanlı eylemi seçer
    s_dl  = dlarray(single(s), 'CB');
    q_val = predict(primary_net, s_dl);
    [~, a] = max(extractdata(q_val)); 
    
    [NMPC_EYREF, NMPC_TH] = step_environment(a, NMPC_EYREF, NMPC_TH, LW, DELTA_TH, TH_MIN, TH_MAX);
    
    try
        evalc('[u2, ~, info_b] = nlmpcmove(nlobj_b, x2, u2_onceki);');
        if info_b.ExitFlag < 0, u2 = u2_onceki * 0.9; end
    catch
        u2 = 0;
    end
    
    try
        ego_serit = traci.vehicle.getLaneIndex('ego');
        if a == 1 && ego_serit > 0
            traci.vehicle.changeLane('ego', ego_serit - 1, 3.0);
        elseif a == 3 && ego_serit < (NUM_SERIT - 1)
            traci.vehicle.changeLane('ego', ego_serit + 1, 3.0);
        end
    catch
    end
    
    v_yeni = max(0, min(35, x2(3) + u2 * Ts));
    try; traci.vehicle.setSpeed('ego', v_yeni); catch; end
    
    traci.simulationStep();
    
    if ~ismember('ego', traci.vehicle.getIDList())
        fprintf('Arac simulasyondan cikti veya kaza yapti (Adim: %d).\n', adim);
        break;
    end
    
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
    s = get_state_vector();
    
    % Gözümüzle takip edebilmek için simülasyonu hafif yavaşlatıyoruz
    pause(0.05); 
end

try; traci.close(); catch; end
fprintf('Test tamamlandi!\n');