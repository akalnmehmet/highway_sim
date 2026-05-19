function dxdt = longitudinal_dynamics(x, u)
% Makale Denklem (13-16)
% x = [d; dv; v; a], u = [u2]
    tau = 5.0;
    dxdt = [x(2); -x(4); x(4); (-x(4) + u(1)) / tau];
end