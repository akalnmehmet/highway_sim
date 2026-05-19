function nlobj_yatay = nmpc_lateral_create()
    Ts = 0.2; p = 20; m = 20; nx = 5; nu = 1;
    nlobj_yatay = nlmpc(nx, nx, nu);
    nlobj_yatay.Ts                       = Ts;
    nlobj_yatay.PredictionHorizon        = p;
    nlobj_yatay.ControlHorizon           = m;
    nlobj_yatay.Model.StateFcn           = 'lateral_dynamics';
    nlobj_yatay.Model.IsContinuousTime   = true;
    nlobj_yatay.Optimization.CustomCostFcn       = 'lateral_cost';
    nlobj_yatay.Optimization.ReplaceStandardCost = true;
    nlobj_yatay.States(2).Min = -5.4;
    nlobj_yatay.States(2).Max =  5.4;
    nlobj_yatay.States(4).Min = -0.35;
    nlobj_yatay.States(4).Max =  0.35;
    nlobj_yatay.States(5).Min = -0.35;
    nlobj_yatay.States(5).Max =  0.35;
    nlobj_yatay.MV(1).Min = -0.035;
    nlobj_yatay.MV(1).Max =  0.035;
    % Uyariyi bastir, timeout ekle
    nlobj_yatay.Optimization.SolverOptions.MaxIterations     = 50;
    nlobj_yatay.Optimization.SolverOptions.FunctionTolerance = 1e-3;
    nlobj_yatay.Optimization.SolverOptions.Display           = 'off';
end