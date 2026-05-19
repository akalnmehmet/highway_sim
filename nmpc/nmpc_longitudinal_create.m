function nlobj_boyuna = nmpc_longitudinal_create()
    Ts = 0.2; p = 5; m = 5; nx = 4; nu = 1;
    nlobj_boyuna = nlmpc(nx, nx, nu);
    nlobj_boyuna.Ts                       = Ts;
    nlobj_boyuna.PredictionHorizon        = p;
    nlobj_boyuna.ControlHorizon           = m;
    nlobj_boyuna.Model.StateFcn           = 'longitudinal_dynamics';
    nlobj_boyuna.Model.IsContinuousTime   = true;
    nlobj_boyuna.Optimization.CustomCostFcn       = 'longitudinal_cost';
    nlobj_boyuna.Optimization.ReplaceStandardCost = true;
    nlobj_boyuna.States(1).Min = 2;
    nlobj_boyuna.States(3).Max = 35;
    nlobj_boyuna.States(4).Min = -5;
    nlobj_boyuna.States(4).Max =  2.4;
    nlobj_boyuna.MV(1).Min = -5;
    nlobj_boyuna.MV(1).Max =  2.4;
    % Uyariyi bastir, timeout ekle
    nlobj_boyuna.Optimization.SolverOptions.MaxIterations     = 50;
    nlobj_boyuna.Optimization.SolverOptions.FunctionTolerance = 1e-3;
    nlobj_boyuna.Optimization.SolverOptions.Display           = 'off';
end