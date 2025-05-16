% Simplified Distillation Column Simulation

% Parameters
num_stages = 10;
feed_stage = 5;
alpha = 2.5; % Relative volatility
feed_rate = 100; % kmol/hr
feed_comp_A = 0.4;
feed_comp_B = 1 - feed_comp_A;
reflux_ratio = 2;
holdup_liquid = 10; % kmol per stage (constant)
holdup_reboiler = 20;
holdup_condenser = 15;

% Time settings
t_span = [0 5]; % Simulation time in hours
dt = 0.01;
t = t_span(1):dt:t_span(2);
num_t = length(t);

% Initialize concentration profiles (assuming initial steady state is reached quickly)
x_liquid = zeros(num_stages, num_t);
y_vapor = zeros(num_stages, num_t);
x_liquid(:, 1) = linspace(0.2, 0.8, num_stages)'; % Initial guess for liquid composition
for i = 1:num_stages
    y_vapor(i, 1) = alpha * x_liquid(i, 1) / (1 + (alpha - 1) * x_liquid(i, 1));
end

% Initialize reboiler and condenser compositions
x_reboiler = zeros(1, num_t);
x_condenser = zeros(1, num_t);
x_reboiler(1) = x_liquid(1, 1);
x_condenser(1) = x_liquid(num_stages, 1);

% Assume constant molar flow rates for simplicity (approximate)
V = 150; % Vapor flow rate
L = V + reflux_ratio * (feed_rate * feed_comp_A / x_condenser(1)); % Liquid flow rate (approximate)
D = feed_rate * feed_comp_A / x_condenser(1); % Distillate rate (approximate)
B = feed_rate * feed_comp_B / x_reboiler(1); % Bottoms rate (approximate)
L_ref = reflux_ratio * D;

% Simulation loop (simplified Euler method)
for i = 2:num_t
    for j = 1:num_stages
        if j == feed_stage
            dxdt_A = (L * x_liquid(j+1, i-1) + V * y_vapor(j-1, i-1) - L * x_liquid(j, i-1) - V * y_vapor(j, i-1) + feed_rate * feed_comp_A) / holdup_liquid;
        elseif j == 1 % Reboiler
            dxdt_A = (L * x_liquid(j+1, i-1) - V * y_vapor(j, i-1) - B * x_reboiler(i-1) + feed_rate * feed_comp_A * (j == feed_stage)) / holdup_reboiler;
            x_reboiler(i) = max(0, min(1, x_reboiler(i-1) + dt * dxdt_A));
            y_vapor(j, i) = alpha * x_reboiler(i) / (1 + (alpha - 1) * x_reboiler(i));
            continue;
        elseif j == num_stages % Condenser (top tray liquid composition)
            dxdt_A = (V * y_vapor(j-1, i-1) - L_ref * x_condenser(i-1) - D * x_condenser(i-1)) / holdup_condenser;
            x_condenser(i) = max(0, min(1, x_condenser(i-1) + dt * dxdt_A));
            x_liquid(j, i) = x_condenser(i); % Assume top stage liquid is similar to condenser composition
            y_vapor(j, i) = alpha * x_liquid(j, i) / (1 + (alpha - 1) * x_liquid(j, i));
            continue;
        else
            dxdt_A = (L * x_liquid(j+1, i-1) + V * y_vapor(j-1, i-1) - L * x_liquid(j, i-1) - V * y_vapor(j, i-1)) / holdup_liquid;
        end
        x_liquid(j, i) = max(0, min(1, x_liquid(j, i-1) + dt * dxdt_A));
        y_vapor(j, i) = alpha * x_liquid(j, i) / (1 + (alpha - 1) * x_liquid(j, i));
    end
end

% Plotting
figure;
subplot(2, 1, 1);
plot(t, x_liquid');
xlabel('Time (hours)');
ylabel('Liquid Mole Fraction of A');
title('Liquid Concentration Profiles on Different Stages');
legend(['Stage 1', 'Stage 2', 'Stage 3', 'Stage 4', 'Stage 5 (Feed)', 'Stage 6', 'Stage 7', 'Stage 8', 'Stage 9', 'Stage 10']);
grid on;

subplot(2, 1, 2);
plot(t, y_vapor');
xlabel('Time (hours)');
ylabel('Vapor Mole Fraction of A');
title('Vapor Concentration Profiles Entering Different Stages');
legend(['Stage 1', 'Stage 2', 'Stage 3', 'Stage 4', 'Stage 5', 'Stage 6', 'Stage 7', 'Stage 8', 'Stage 9', 'Stage 10']);
grid on;

figure;
plot(t, x_reboiler, 'b-', t, x_condenser, 'r--');
xlabel('Time (hours)');
ylabel('Mole Fraction of A');
title('Bottom (Reboiler) and Top (Condenser) Liquid Concentrations');
legend('Bottom (Reboiler)', 'Top (Condenser)');
grid on;
