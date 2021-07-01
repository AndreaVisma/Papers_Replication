function Agent = Agent_ExpectedMoneyAllocation(Agent, t, Assets, Parameters)
    % Define the time window that will be used by the agent
    win_t = max(1, t - Agent.FinMemory):t;

    % Calculation of fundamental asset prices based on discounted expected cash
    % flows expected cash flows are computed as average of latest
    % Agent.FinMemory cash flows
    for a = 1:Assets.size
        % Computation of D1 of the Gordon formula
        CashFlowNextStep_exp = mean(Assets.CashFlows{win_t, a});
        nrCashFlows = numel(Assets.CashFlows{win_t, a});
        % Computation of g of the Gordon formula
        if ismember(a, Assets.Eq) && (nrCashFlows > 1) ...
            && (CashFlowNextStep_exp > 0)
            CashFlowGrowthRate_exp = zdiv(regress(...
                Assets.CashFlows{win_t, a}, (1:nrCashFlows)'), ...
                CashFlowNextStep_exp);
        else
            CashFlowGrowthRate_exp = 0;
        end

        % Computation of r-g of the Gordon formula
        r_g_Gordon = max(Assets.DiscountFactor{t, a} ...
            - Parameters.Gordon.CashFlowGrowthRate_exp_share ...
            * CashFlowGrowthRate_exp, Parameters.Gordon.r_g_min);
        % Note: in case of bonds, r_g_Gordon rduces to the DiscountFactor since
        % CashFlowGrowthRate_exp is set to zero
        Agent.fundamentals{t, a} = CashFlowNextStep_exp / r_g_Gordon;
        % We assume that, in the case of equity shares, the fundamental cannot
        % go below half of its nominal value given by the book value of equity
        if ismember(a, Assets.Eq)
            Agent.fundamentals{t, a} = max(Agent.fundamentals{t, a}, ...
                Assets.NominalValue{t, a} / 2);
        end

        clear CashFlowNextStep_exp CashFlowGrowthRate_exp
        clear DiscountFactor r_g_Gordon
    end

    % Calculation of weights based on the ratios of fundamentals to the total
    % market capitalization based on fundamental prices
    Agent.AssetsWeights = zdiv(Agent.fundamentals{t,:} ...
        .* Assets.NrTradable{t - 1,:}, dot(Agent.fundamentals{t,:}, ...
        Assets.NrTradable{t - 1,:})) ...
        + Parameters.weights_volatility * randn(1, Assets.size);

    % Adjust if needed (possible overshoot from the added random variables)
    total_weights = sum(Agent.AssetsWeights);
    if total_weights ~= 1
        Agent.AssetsWeights = Agent.AssetsWeights / total_weights;
    end
    % After computing AssetWeights (e.g. based on the fundamental value and the
    % capitalization method), the trader agent computes the amount of money
    % he/she would be willing to allocate to each asset, given the present
    % financial wealth (given by the sum of assets market values + liquidity).
    Agent.ToInvest(t) = Agent.M(t - 1) ...
        + dot(Assets.Prices{t - 1, Assets.Bo}, ...
            Agent.AssetsHoldings{t - 1, Assets.Bo}) ...
        + Parameters.with_equity_trading * dot(Assets.Prices{t - 1, Assets.Eq}, ...
            Agent.AssetsHoldings{t - 1, Assets.Eq});
