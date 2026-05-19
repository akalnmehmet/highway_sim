classdef ReplayBuffer < handle
    % =========================================================
    % DENEYİM TEKRAR HAFIZASI (Replay Buffer)
    % Makale: Albarella et al. 2023, Tablo 3
    %
    % Kapasite : 500.000
    % Mini-batch: 32
    %
    % Her deneyim tuple: (s, a, r, s', done)
    %   s     : durum vektörü      [19×1]
    %   a     : eylem indeksi      [1×1] (1..5)
    %   r     : ödül               [1×1]
    %   s_    : sonraki durum      [19×1]
    %   done  : episode bitti mi?  [1×1] (0/1)
    % =========================================================

    properties
        kapasite        % Maksimum kayıt sayısı
        boyut           % Durum vektörü boyutu
        sayac           % Toplam eklenen deneyim sayısı
        indeks          % Dairesel buffer yazma indeksi

        % Pre-allocated matrisler (hız için)
        S               % Durumlar      [boyut × kapasite]
        A               % Eylemler      [1 × kapasite]
        R               % Ödüller       [1 × kapasite]
        S_              % Sonraki durum [boyut × kapasite]
        Done            % Bitti mi?     [1 × kapasite]
    end

    methods
        function obj = ReplayBuffer(kapasite, boyut)
            obj.kapasite = kapasite;
            obj.boyut    = boyut;
            obj.sayac    = 0;
            obj.indeks   = 1;

            % Belleği baştan ayır (makale: 500.000 kapasite)
            obj.S    = zeros(boyut, kapasite, 'single');
            obj.A    = zeros(1,     kapasite, 'uint8');
            obj.R    = zeros(1,     kapasite, 'single');
            obj.S_   = zeros(boyut, kapasite, 'single');
            obj.Done = zeros(1,     kapasite, 'logical');
        end

        function ekle(obj, s, a, r, s_, done)
            % Yeni deneyim ekle (dairesel buffer)
            obj.S(:,    obj.indeks) = single(s);
            obj.A(obj.indeks)       = uint8(a);
            obj.R(obj.indeks)       = single(r);
            obj.S_(:,   obj.indeks) = single(s_);
            obj.Done(obj.indeks)    = logical(done);

            % Dairesel ilerleme
            obj.indeks = mod(obj.indeks, obj.kapasite) + 1;
            obj.sayac  = min(obj.sayac + 1, obj.kapasite);
        end

        function [s_b, a_b, r_b, s__b, done_b] = ornekle(obj, batch_boyut)
            % Rastgele mini-batch örnekle
            idx = randperm(obj.sayac, batch_boyut);

            s_b    = double(obj.S(:,  idx));
            a_b    = double(obj.A(idx));
            r_b    = double(obj.R(idx));
            s__b   = double(obj.S_(:, idx));
            done_b = double(obj.Done(idx));
        end

        function yeterli = hazir_mi(obj, batch_boyut)
            % Yeterli deneyim birikti mi?
            yeterli = (obj.sayac >= batch_boyut);
        end
    end
end
