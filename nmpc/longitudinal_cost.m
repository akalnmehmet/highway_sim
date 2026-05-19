function J = longitudinal_cost(X, U, e, data)
% Makale OCP (24) — sabit parametreler
    q3=30; q4=30; q5=20; r2=1;
    d0    = 3.0;
    v_ref = 33.0;

    % TH global degiskenden al
    global NMPC_TH
    if isempty(NMPC_TH), NMPC_TH = 1.5; end
    TH = NMPC_TH;

    J = 0;
    p = data.PredictionHorizon;
    for k = 1:p+1
        d_k=X(k,1); dv_k=X(k,2); v_k=X(k,3); a_k=X(k,4);
        d_ref = d0 + TH * v_k;
        e2 = [d_k-d_ref; dv_k; v_k-v_ref];
        J = J + q3*e2(1)^2 + q4*e2(2)^2 + q5*e2(3)^2;
        if k <= p
            J = J + r2*a_k^2 + r2*U(k,1)^2;
        end
    end
end