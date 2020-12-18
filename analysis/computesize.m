%Assume area of illumination = 1.4x FOC
A = pi * ((1.4 * 2048)/2 * 0.065e-6)^2; %m^2

%Compute energy per mol of photons
E = (6.67e-34 * 3e8)/440e-9;
Emol = E * 6.022e23;  %J/mol

%Convert to umol photons /s
I = (256e-3/Emol) * 1e6;  %100% of blue laser = 256 mW based on manual

%Divide by area to get umol photons/(m^2 s)
I = I / A

