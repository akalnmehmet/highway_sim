function s = get_state_vector()
% =========================================================
% FAZ 2: DURUM GÖZLEM FONKSİYONU
% Makale: Albarella et al. 2023, Tablo 1
%
% Durum vektörü s(t) ∈ R^19:
%   s(1)      : ego aracın hızı v(t)          [m/s]
%   s(2..7)   : s1j — 6 aracın boyuna mesafesi [m]
%   s(8..13)  : s2j — 6 aracın yatay mesafesi  [m]
%   s(14..19) : s3j — 6 aracın göreceli hızı   [m/s]
%
% 6 çevre aracının sırası (j=1..6):
%   j=1: Sol şerit,  önde
%   j=2: Ego şeridi, önde
%   j=3: Sağ şerit,  önde
%   j=4: Sol şerit,  arkada
%   j=5: Ego şeridi, arkada
%   j=6: Sağ şerit,  arkada
%
% Makale notu: Şerit yoksa veya araç algılanamazsa,
% sensör menzilini (100m) dummy değer olarak kullan.
% =========================================================

    % --- Sabitler ---
    SENSOR_RANGE     = 100;   % [m] — maksimum algılama menzili
    LANE_WIDTH       = 3.6;   % [m] — makale Tablo 2
    NUM_LANES        = 3;     % Toplam şerit sayısı (0, 1, 2)
    DUMMY_LONG_DIST  =  SENSOR_RANGE;  % Boş şerit için varsayılan boyuna mesafe
    DUMMY_LAT_DIST   =  LANE_WIDTH;    % Boş şerit için varsayılan yatay mesafe
    DUMMY_REL_VEL    =  0;             % Boş şerit için varsayılan göreceli hız

    % --- Ego bilgilerini al ---
    ego_hiz   = traci.vehicle.getSpeed('ego');
    ego_konum = traci.vehicle.getPosition('ego');
    ego_serit = traci.vehicle.getLaneIndex('ego');

    % --- Tüm araçların listesini al ---
    tum_araclar = traci.vehicle.getIDList();
    % Ego'yu listeden çıkar
    tum_araclar = tum_araclar(~strcmp(tum_araclar, 'ego'));

    % --- Her çevre aracının bilgisini topla ---
    % Yapı: arac_bilgi(i) = [boyuna_mesafe, yatay_mesafe, gorceli_hiz, serit_indeksi]
    arac_verileri = [];

    for k = 1:length(tum_araclar)
        arac_id   = tum_araclar{k};
        arac_konum = traci.vehicle.getPosition(arac_id);
        arac_hiz   = traci.vehicle.getSpeed(arac_id);
        arac_serit = traci.vehicle.getLaneIndex(arac_id);

        % Boyuna mesafe (X ekseni farkı — negatif=arkada, pozitif=önde)
        boyuna_mesafe = arac_konum(1) - ego_konum(1);

        % Yatay mesafe (Y ekseni farkı — şerit merkezleri arası)
        yatay_mesafe = arac_konum(2) - ego_konum(2);

        % Göreceli hız: Δv = v_araç - v_ego (pozitif=araç daha hızlı)
        goreceli_hiz = arac_hiz - ego_hiz;

        arac_verileri = [arac_verileri; ...
            boyuna_mesafe, yatay_mesafe, goreceli_hiz, arac_serit];
    end

    % --- 6 komşu aracı seç (j=1..6 sıralamasına göre) ---
    % Şerit kombinasyonları: [hedef_serit, on_mu_arka_mi]
    % on_mu: 1=önde (boyuna>0), 0=arkada (boyuna<0)
    serit_kombinasyonlari = [
        ego_serit - 1,  1;   % j=1: Sol şerit,  önde
        ego_serit,      1;   % j=2: Ego şeridi, önde
        ego_serit + 1,  1;   % j=3: Sağ şerit,  önde
        ego_serit - 1,  0;   % j=4: Sol şerit,  arkada
        ego_serit,      0;   % j=5: Ego şeridi, arkada
        ego_serit + 1,  0;   % j=6: Sağ şerit,  arkada
    ];

    % Sonuç dizileri (6 araç için)
    s1j = zeros(1, 6);  % Boyuna mesafeler
    s2j = zeros(1, 6);  % Yatay mesafeler
    s3j = zeros(1, 6);  % Göreceli hızlar

    for j = 1:6
        hedef_serit = serit_kombinasyonlari(j, 1);
        one_mi      = serit_kombinasyonlari(j, 2);   % 1=önde, 0=arkada

        % Geçersiz şerit kontrolü (0'dan küçük veya NUM_LANES-1'den büyük)
        if hedef_serit < 0 || hedef_serit >= NUM_LANES
            % Şerit yok — dummy değerler kullan (makale gereği)
            s1j(j) = DUMMY_LONG_DIST;
            s2j(j) = DUMMY_LAT_DIST;
            s3j(j) = DUMMY_REL_VEL;
            continue;
        end

        % Bu şeritteki araçları filtrele
        if isempty(arac_verileri)
            en_yakin_uzaklik = inf;
            en_yakin_idx     = [];
        else
            serit_maskesi = (arac_verileri(:, 4) == hedef_serit);

            if one_mi == 1
                % Önde olanlar: boyuna mesafe > 0
                yon_maskesi = (arac_verileri(:, 1) > 0);
            else
                % Arkada olanlar: boyuna mesafe <= 0
                yon_maskesi = (arac_verileri(:, 1) <= 0);
            end

            gecerli_maskesi = serit_maskesi & yon_maskesi;

            if ~any(gecerli_maskesi)
                en_yakin_idx = [];
            else
                gecerli_araclar = arac_verileri(gecerli_maskesi, :);
                % En yakın aracı bul (mutlak boyuna mesafe en küçük olan)
                [~, min_idx] = min(abs(gecerli_araclar(:, 1)));
                % Orijinal indekse geri dön
                gecerli_indeksler = find(gecerli_maskesi);
                en_yakin_idx = gecerli_indeksler(min_idx);
            end
        end

        if isempty(en_yakin_idx)
            s1j(j) = DUMMY_LONG_DIST;
            s2j(j) = DUMMY_LAT_DIST;
            s3j(j) = DUMMY_REL_VEL;
        else
            gercek_mesafe = abs(arac_verileri(en_yakin_idx, 1));
        
            % Sensör menzili dışındaysa dummy değer kullan
            if gercek_mesafe > SENSOR_RANGE
                s1j(j) = DUMMY_LONG_DIST;
                s2j(j) = DUMMY_LAT_DIST;
                s3j(j) = DUMMY_REL_VEL;
            else
                s1j(j) = gercek_mesafe;
                s2j(j) = abs(arac_verileri(en_yakin_idx, 2));
                s3j(j) = arac_verileri(en_yakin_idx, 3);
            end
        end
    end

    % --- 19 boyutlu durum vektörünü oluştur ---
    s = [ego_hiz, s1j, s2j, s3j];
    s = s(:);
    % s(1)     : ego hızı
    % s(2:7)   : 6 aracın boyuna mesafesi
    % s(8:13)  : 6 aracın yatay mesafesi
    % s(14:19) : 6 aracın göreceli hızı

end
