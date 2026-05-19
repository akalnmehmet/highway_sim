function [eyref, TH] = step_environment(a, eyref, TH, LW, DELTA_TH, TH_MIN, TH_MAX)
% =========================================================
% STEP ENVIRONMENT — Makale Algoritma 2
%
% DDQN'nin seçtiği eylemi referans sinyallerine çevirir.
%
% Eylemler:
%   a=1 : Sol şerit değişimi   → eyre f += Lw
%   a=2 : Şerit koruma         → eyre f değişmez
%   a=3 : Sağ şerit değişimi   → eyre f -= Lw
%   a=4 : Hızlanma             → TH -= ΔTH
%   a=5 : Frenleme             → TH += ΔTH
% =========================================================

switch a
    case 1
        eyref = eyref + LW;
    case 2
        % değişiklik yok
    case 3
        eyref = eyref - LW;
    case 4
        TH = max(TH_MIN, TH - DELTA_TH);
    case 5
        TH = min(TH_MAX, TH + DELTA_TH);
end

end
