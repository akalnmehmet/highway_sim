function net = ddqn_create_network()
% =========================================================
% DDQN SİNİR AĞI MİMARİSİ
% Makale: Albarella et al. 2023, Tablo 3
%
% Mimari: 19 → Dense(128,ReLU) → Dense(128,ReLU) → 5
%
% Çıkış: dlnetwork objesi (primary ve target ağ için aynı
%         fonksiyon iki kez çağrılır)
% =========================================================

layers = [
    featureInputLayer(19, 'Name', 'input', ...
    'Normalization', 'none')

    fullyConnectedLayer(128, 'Name', 'fc1')
    reluLayer('Name', 'relu1')

    fullyConnectedLayer(128, 'Name', 'fc2')
    reluLayer('Name', 'relu2')

    fullyConnectedLayer(5, 'Name', 'output')
    % NOT: Çıkışta aktivasyon yok — Q değerleri doğrudan
    ];

net = dlnetwork(layers);

end
