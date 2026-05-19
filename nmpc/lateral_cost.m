function J = lateral_cost(X, U, e, data)
% Makale OCP (18) — eyref global degiskenden
    q1=50; q2=50; r1=10;

    global NMPC_EYREF
    if isempty(NMPC_EYREF), NMPC_EYREF = 0; end
    eyref = NMPC_EYREF;

    J = 0;
    p = data.PredictionHorizon;
    for k = 1:p+1
        ey_k=X(k,2); eps_k=X(k,4); dlt_k=X(k,5);
        e1 = [ey_k-eyref; eps_k];
        J = J + q1*e1(1)^2 + q2*e1(2)^2;
        if k <= p
            J = J + r1*dlt_k^2 + r1*U(k,1)^2;
        end
    end
end