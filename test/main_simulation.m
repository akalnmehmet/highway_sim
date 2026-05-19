clear all; close all; clc;

ROOT = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(ROOT, 'lib', 'pipeacosta-traci4matlab-245ddc7'));
javaaddpath(fullfile(ROOT, 'lib', 'pipeacosta-traci4matlab-245ddc7', 'traci4matlab.jar'));
java.lang.System.setProperty('java.net.preferIPv4Stack', 'true');

system('taskkill /F /IM sumo-gui.exe /T 2>nul');
system('taskkill /F /IM sumo.exe /T 2>nul');
pause(2);

system(['start sumo-gui -n "' fullfile(ROOT, 'sumo', 'highway.net.xml') '" -r "' fullfile(ROOT, 'sumo', 'highway.rou.xml') '" --remote-port 8813 --start']);
pause(8);

traci.init(8813, 10, '192.168.1.101');
disp('BAŞARILI!');

for i = 1:100
    traci.simulationStep();
    arac_listesi = traci.vehicle.getIDList();

    if ismember('ego', arac_listesi)
        ego_hiz   = traci.vehicle.getSpeed('ego');
        ego_konum = traci.vehicle.getPosition('ego');
        ego_serit = traci.vehicle.getLaneIndex('ego');

        lider_id = traci.vehicle.getLeader('ego', 100);

        if ~isempty(lider_id)
            % Mesafeyi konumlardan hesapla
            lider_konum = traci.vehicle.getPosition(lider_id);
            mesafe = sqrt((lider_konum(1)-ego_konum(1))^2 + ...
                          (lider_konum(2)-ego_konum(2))^2);
            lider_hiz = traci.vehicle.getSpeed(lider_id);

            fprintf('Adım: %d | EGO: %.1f m/s | Öndeki: %s | Mesafe: %.1f m | Hız: %.1f m/s\n', ...
                i, ego_hiz, lider_id, mesafe, lider_hiz);
        else
            fprintf('Adım: %d | EGO: %.1f m/s | Önü BOŞ\n', i, ego_hiz);
        end
    end

    pause(0.1);
end

traci.close();
disp('Simülasyon tamamlandı.');
