function [r, done, carpma] = compute_reward(s, a, v_ref, ttc_esik)
% =========================================================
% ODUL FONKSIYONU — Makale Denklem (7) — Guclendirilmis Versiyon
%
% r_t = r_v - r_lc - r_ttc - r_coll
%
% s vektoru yapisi:
%   s(1)     : ego hizi
%   s(2:7)   : boyuna mesafeler (j=1..6)
%   s(8:13)  : yatay mesafeler
%   s(14:19) : goreceli hizlar
% =========================================================

    v      = s(1);
    done   = false;
    carpma = false;

    % --- r_v: Hiz odulu ---
    r_v = 1 - abs(v_ref - v) / v_ref;
    r_v = max(0, r_v);

    % --- r_lc: Gereksiz serit degisimi cezasi ---
    if a == 1 || a == 3
        r_lc = 1;
    else
        r_lc = 0;
    end

    % --- r_ttc ve r_coll ---
    % Ego seridindeki onde araç (j=2) → s(3), s(15)
    d_on  = s(3);    % boyuna mesafe [m]
    dv_on = s(15);   % goreceli hiz [m/s]

    r_ttc  = 0;
    r_coll = 0;

    if d_on < 100
        yaklasma_hizi = -dv_on;

        % TTC cezasi — guclendirildi: 5 → 20
        if yaklasma_hizi > 0.1
            ttc = d_on / yaklasma_hizi;
            if ttc < ttc_esik
                r_ttc = 20;   % Onceki: 5
            end
        end

        % Carpma cezasi — guclendirildi: 10 → 100
        if d_on < 2.0
            r_coll = 100;   % Onceki: 10
            done   = true;
            carpma = true;
        end

        % Ek: Cok yakin yaklasma erken uyari (yeni)
        % 5m altina dusunce hafif ceza
        if d_on < 5.0 && ~carpma
            r_ttc = r_ttc + 5;
        end
    end

    % --- Toplam odul ---
    r = r_v - r_lc - r_ttc - r_coll;

end