function dxdt = lateral_dynamics(x, u)
% Makale Denklem (8-12)
    lf=1.2; lr=1.6; rho=0.0;
    ey=x(2); v=x(3); epsi=x(4); dlt=x(5); u1=u(1);
    denom = 1 - rho*ey;
    if abs(denom) < 1e-6, denom = 1e-6; end
    dxdt = zeros(5,1);
    dxdt(1) = v*cos(epsi)/denom;
    dxdt(2) = v*sin(epsi);
    dxdt(3) = 0;
    dxdt(4) = v*(tan(dlt)/(lf+lr) - rho*cos(epsi)/denom);
    dxdt(5) = u1;
end