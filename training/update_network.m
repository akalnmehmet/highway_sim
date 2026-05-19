function [net, avg_grad, avg_sq_grad] = update_network(net, s_b, a_b, y_t, ...
    lr, adim, avg_grad, avg_sq_grad)
% =========================================================
% AĞ GÜNCELLEME — Makale Denklem (5)
% Loss: L(θ) = E[(y_t - Q(s,a;θ))²]
% Optimizer: Adam, lr=0.0005
% =========================================================

[~, gradyanlar] = dlfeval(@compute_loss, net, s_b, a_b, y_t);

[net, avg_grad, avg_sq_grad] = adamupdate(net, gradyanlar, ...
    avg_grad, avg_sq_grad, adim, lr);

end

% -------------------------

function [loss, gradyanlar] = compute_loss(net, s_b, a_b, y_t)

q_tum       = forward(net, s_b);       % [5 × batch]
batch_boyut = size(s_b, 2);
q_secilen   = zeros(1, batch_boyut, 'like', q_tum);

for b = 1:batch_boyut
    q_secilen(b) = q_tum(a_b(b), b);
end

y_t_dl = dlarray(single(y_t), 'CB');
loss   = mean((y_t_dl - q_secilen).^2);
gradyanlar = dlgradient(loss, net.Learnables);

end
