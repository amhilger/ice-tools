
function [pulse_compressed, unfocused_SAR, multi_looked] = ...
    pickSAR(rawIn, raw_pri, pick_pri, N_coherent, M_incoherent)


%%11/3 realized that this is not preserving location/pri of output, likely due to gaps
%%in pris (e.g., hardware failure). Need to reconfigure so that trace is
%%re-indexed for every single output point :(

%%10/25: removing moving window for coherent sum

%%rawIn is the raw data, and attributes is the structure containing the 11
%%attributes. These can be most easily acquired from the get_pri_range
%%function.

%%N_coherent and M_incoherent are parameters controlling the number of
%%coherent and incoherent sums, respectively. Both are optional. If
%%unspecified, N_coherent is calculated based on the average Fresnel zone
%%of the input data (based on average clearance and velocity, which are
%%recorded locally, and wavelength and trace interval, which do not change
%%over the survey. If unspecified, M_incoherent is set to a default value
%%(currently 20).

%%% initial radar parameters %%%
f_sample = 22; % MHz
[nsamples, n_traces] = size(rawIn); % number of samples in a trace
tmax = nsamples/f_sample; %time of last sample relative to pulse, us
bandwidth = 15; % MHz
chirp_length = 4; % us
window_length = 4; % us



%%% Create blackman filter %%%
fast_time = linspace(0,tmax,nsamples); %us 
ref_chirp_imag = -sin(2*pi*fast_time.*(-bandwidth/2+bandwidth/2/chirp_length.*fast_time)); %unwindowed chirp
ref_chirp_real = cos(2*pi*fast_time.*(-bandwidth/2+bandwidth/2/chirp_length.*fast_time));
b_window = ones(1,nsamples)*0.0; % initialize window
black = blackman(floor(window_length*f_sample)); % returns blackman filter
b_window(1:window_length*f_sample) = black; % sets beginning of window to filter coefficients
black_ref_real = ref_chirp_real.*b_window; % apply window to reference chirp
black_ref_imag = ref_chirp_imag.*b_window;  
deChirpTime = complex(black_ref_real,black_ref_imag).'; 
deChirpTime = circshift(deChirpTime,-chirp_length*f_sample/2,1); %center chirp to t = 0

%%% perform pulse compression %%%
pulse_compressed = rawIn*0.0; %initialize pulse_compressed traces
for n = 1:n_traces % for each trace
    %convolve raw traces with windowed reference chirp
    pulse_compressed(:,n) = ifft(fft(rawIn(:,n)).*conj(fft(deChirpTime)));
end

% Set window size for coherent summing
if ~exist('N_coherent','var')
    N = 70; %default coherent sum number
else 
    N = N_coherent; %Number of coherent summations
end
% Set window size for incoherent averaging
if ~exist('M_incoherent','var')
    M = 5; %default multilook number
else
    M = M_incoherent;
end


%Generate pris so that there are M coherent sums for each pick_pri to
%enable incoherent averaging
n_picks = length(pick_pri);
coherent_pris = repelem(pick_pri,M);
%offsets for centered moving average around the input pri. The window is
%from -floor(M/2) to floor(M/2) if M odd, or from -M/2 to M/2-1 if M even.
%The offsets are in increments of 50*N pris (b/c 50 pris per trace).
offset = ( (-N*50) * (floor(M/2)) ) : (N*50) : ( (N*50) * (M-floor(M/2)-1));
%The offset is repeated and applied to the M repetitions of each input pri
%in coherent pris
coherent_pris = coherent_pris+repmat(offset', n_picks, 1);



%%% perform unfocused SAR %%%
disp(['Coherently summing ' num2str(N) ' traces'])
unfocused_SAR = zeros(nsamples, length(coherent_pris)); % initialize array
for i = 1 : length(coherent_pris) % for each coherent pri i
    trace = find(raw_pri == coherent_pris(i)); %trace index of coherent pri i
    %trace to sum are a moving window centered at each pri in coherent pri
    trace_range = trace-floor(N/2) : trace+floor(N/2)+1;
    if i == 1 || i == length(coherent_pris)
       disp(['trace = ' num2str(trace)])
       disp(['trace_range = ' num2str(min(trace_range)) ' to ' num2str(max(trace_range))])
       disp(['pri = ' num2str(coherent_pris(i))])
    end
    unfocused_SAR(:,i) = sum(pulse_compressed(:,trace_range),2);
end

%%% perform incoherent averaging %%%
disp(['Incoherently averaging ' num2str(M) ' traces'])
multi_looked = zeros(nsamples, length(pick_pri));
for i = 1 : length(pick_pri) % for each pick, calculate a moving average
    trace_range = (i-1)*M+1 : M*i;
    multi_looked(:,i) = 1/M*sum(abs(unfocused_SAR(:,trace_range)).^2,2);
end
