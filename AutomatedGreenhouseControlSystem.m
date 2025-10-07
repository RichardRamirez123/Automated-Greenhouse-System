function greenhouse_gui
clc;
clear;
close all;

%% Create the GUI
fig = uifigure('Name', 'Automated Greenhouse Control', 'Position', [100 100 600 500]);

% Heater Power Slider (range reduced)
uilabel(fig, 'Text', 'Heater Power (W)', 'Position', [50 400 120 20]);
heaterSlider = uislider(fig, 'Position', [180 410 300 3], 'Limits', [0 500]); % Range reduced to [0, 500]
heaterSlider.Value = 250;

% Fan Speed Slider (range reduced)
uilabel(fig, 'Text', 'Fan Speed (RPM)', 'Position', [50 350 120 20]);
fanSlider = uislider(fig, 'Position', [180 360 300 3], 'Limits', [0 1500]); % Range reduced to [0, 1500]
fanSlider.Value = 750;

% Water Flow Slider (range reduced)
uilabel(fig, 'Text', 'Water Flow (L/min)', 'Position', [50 300 120 20]);
waterSlider = uislider(fig, 'Position', [180 310 300 3], 'Limits', [0 10]); % Range reduced to [0, 10]
waterSlider.Value = 5;

% Start Simulation Button
startButton = uibutton(fig, 'Text', 'Start Simulation', 'Position', [250 250 100 30], ...
    'ButtonPushedFcn', @(btn,event) run_simulation(heaterSlider.Value, ...
    fanSlider.Value, waterSlider.Value));

end

%% Simulation Function
function run_simulation(heaterPower, fanSpeedRPM, waterFlowLmin)
clc;
close all;

% Convert Inputs
fanSpeed = rpm_to_rad_per_sec(fanSpeedRPM); % Convert RPM to rad/s
waterFlow = waterFlowLmin / 1000 / 60; % Convert L/min to m^3/s

%% Parameters
J = 0.01;    % Moment of inertia of fan (kg*m^2)
b = 0.1;     % Damping coefficient (N*m*s)
K_motor = 0.05; % Motor constant (N*m/A)

% Thermal System
m_air = 1.2;    % Mass of air in greenhouse (kg)
c_air = 1005;   % Specific heat of air (J/kg*K)

% Time Span
tspan = [0 300];

% Initial Conditions
omega_0 = 0; % Initial fan speed
T_0 = 20;    % Initial greenhouse temperature

% Run ODE Solver
[t, y] = ode45(@(t,y) model(t, y, heaterPower, fanSpeed, waterFlow), tspan, [omega_0, T_0]);

% Extract Results
omega = y(:,1); % Fan Speed
T = y(:,2);     % Greenhouse Temperature

% Plot Results
figure;
subplot(2,1,1);
plot(t, T, 'r', 'LineWidth', 1.5);
title('Greenhouse Temperature');
xlabel('Time (s)');
ylabel('Temperature (°C)');
grid on;

subplot(2,1,2);
plot(t, omega, 'b', 'LineWidth', 1.5);
title('Fan Speed');
xlabel('Time (s)');
ylabel('Speed (rad/s)');
grid on;

% Plant Growth Simulation (Amplified Sensitivity)
growth = plant_growth(T, waterFlow); % Amplified Growth Model
figure;
plot(t, growth, 'g', 'LineWidth', 1.5);
title('Plant Growth Over Time');
xlabel('Time (s)');
ylabel('Growth Factor');
grid on;

end

%% Fan Speed Conversion Function (RPM to rad/s)
function rad_per_sec = rpm_to_rad_per_sec(rpm)
    rad_per_sec = (rpm / 60) * (2*pi); % Convert RPM to rad/s
end

%% Plant Growth Model Function (with amplified sensitivity)
function growth = plant_growth(temperature, waterFlow)
    % Temperature range for optimal growth
    optimal_temp_range = [18, 30]; 
    max_growth_rate = 1.0; % Max growth rate in optimal conditions

    % Basic growth model based on temperature and water flow
    growth_rate = (temperature - optimal_temp_range(1)) / (optimal_temp_range(2) - optimal_temp_range(1));
    growth_rate(growth_rate < 0) = 0; % No growth below minimum temperature
    growth_rate(growth_rate > max_growth_rate) = max_growth_rate; % Cap growth at maximum rate

    % Amplified response for plant growth sensitivity
    growth = growth_rate .* (waterFlow * 100); % Increased sensitivity (multiplied by 100)
    growth(growth < 0) = 0; % No negative growth
end

%% Model Function (ODE system)
function dydt = model(t, y, heaterPower, fanSpeed, waterFlow)
omega = y(1);  % Fan speed (rad/s)
T = y(2);      % Temperature (°C)

% Heat Gain from Heater
heatGain = heaterPower;  % Heater power input (W)

% Heat Loss from Fan (Cooling)
heatLoss = fan_speed_heat_loss(fanSpeed); % Fan heat loss as a function of speed

% Heat Balance Equation
dT_dt = (heatGain - heatLoss) / (1.2 * 1005);  % Rate of change of temperature

% Fan Speed Behavior (motor dynamics)
domega_dt = (fanSpeed - omega) / 5;  % Rate of change of fan speed

dydt = [domega_dt; dT_dt];
end

%% Fan Speed Heat Loss Model (quadratic dependence on speed)
function heatLoss = fan_speed_heat_loss(fanSpeed)
    heatLoss = 0.1 * fanSpeed^2; % A simple quadratic model for heat loss
end