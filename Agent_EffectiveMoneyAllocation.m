function Agent = Agent_EffectiveMoneyAllocation(Agent, t, MarketLiquidity, GOV)
    % The effective money allocation is different from the expected one, since inflow
    % or outflow of money into the market shall be considered following
    % governemnt bond issuing and CB operations

    if Agent.ToInvest(t) > 0
        % Amount to keep as liquidity
        Agent.RemainingLiquidity(t) = Agent.ToInvest(t) ...
            / (1 + Agent.inv2m);
        % Once computed the effective liquid allocation, which is a binding
        % constraint, the agent computes the effective allocation on each
        % financial asset considering the relative weights.
        % First, see if there is something to add based on known policy
        primary_alloc = min(GOV.Bonds_financing(t,:) * Agent.ToInvest(t) ...
            / MarketLiquidity.TotalAgents, ...
            Agent.ToInvest(t) - Agent.RemainingLiquidity(t));
        % Computes allocation for the secondary market
        Agent.MoneyAllocation = Agent.AssetsWeights * max(Agent.ToInvest(t) ...
            - Agent.RemainingLiquidity(t) - sum(primary_alloc), 0);
        % Add to it allocation to the primary market
        ind = 1:size(primary_alloc, 2);
        Agent.MoneyAllocation(ind) = Agent.MoneyAllocation(ind) + primary_alloc;
    else
        Agent.RemainingLiquidity(t) = Agent.ToInvest(t);
        Agent.MoneyAllocation(1:size(Agent.AssetsHoldings, 2)) = 0;
    end